
open Core.Std
open Async.Std

include Graphics

(* Setup the event pipe *)

let event_reader = ref None

let rec event_loop wr = 
  let status = 
    wait_next_event [Button_down; Button_up; Key_pressed; Mouse_motion] 
  in
    Thread_safe_pipe.write wr status;
    if not (is_closed wr) then event_loop wr

let event_reader () = 
  match !event_reader with
    Some rd -> rd
  | None ->
      let (rd, wr) = Thread_safe_pipe.create () in
        In_thread.run (fun () -> event_loop wr);
        event_reader := Some rd;
        rd

let close_event_reader () =
  match !event_reader with
    None -> ()
  | Some rd ->
      Deferred.dont_wait_for (Reader.close rd);
      event_reader := None

(* Event handlers *)

type handler = 
  { f: status -> unit;
    stop: unit Deferred.t; }

let click_handlers = ref []

let mousedown_handlers = ref []

let mouseup_handlers = ref []

let mousemove_handlers = ref []

let keypress_handlers = ref []

let run_handlers handlers_ref status = 
  let rec loop handlers acc =
    match rest with
      {f; stop} as handler :: rest ->
        if Deferred.is_determined stop then
          loop rest acc
        else begin
          f status;
          loop rest (handler :: acc)
          end
    | [] -> acc
  in
    handlers_ref := loop (List.rev !handlers_ref) []

let previous_status =  
  ref { mouse_x = -1; 
        mouse_y = -1; 
        button = false; 
        keypressed = false; 
        key = Char.min_value }

let click_status = ref None

let handle_event status =
  let prev = !previous_status in
    if (not prev.button) && status.button then begin
       run_handlers !mousedown_handlers status;
      click_status := Some status
    end;
    if prev.button && (not status.button) then begin
       run_handlers !mouseup_handlers status;
      match click_status with
         Some {mouse_x; mouse_y} ->  
           if status.mouse_x = mouse_x && status.mouse_y = mouse_y then
             run_handlers !click_handlers status;
           else
             click_status := None
       | None -> 
    end;
    if (prev.mouse_x <> status.mouse_x) || (prev.mouse_y <> status.mouse_y) then begin
      run_handlers !mousemove_handlers status;
      click_status := None
    end;
    if status.keypressed then
      run_handlers !keypress_handlers status;
    previous_status := status

let event_handling_started = ref false

let start_event_handling () =
  if not !event_handling_started then begin
    let event_reader = event_reader () in
    let rec loop () = 
      event_reader >>= (fun status ->
      handle_event status;
      loop ())
    in
      loop ()
  end

let on_click ?start ?stop f = 
  start >>> (fun () -> 
    start_event_handling ();
    click_handlers := {f; stop} :: !click_handlers)

let on_mousedown ?start ?stop f = 
  start >>> (fun () -> 
    start_event_handling ();
    mousedown_handlers := {f; stop} :: !mousedown_handlers)

let on_mouseup ?start ?stop f = 
  start >>> (fun () -> 
    start_event_handling ();
    mouseup_handlers := {f; stop} :: !mouseup_handlers)

let on_mousemove ?start ?stop f = 
  start >>> (fun () -> 
    start_event_handling ();
    mousemove_handlers := {f; stop} :: !mousemove_handlers)

let on_keypress ?start ?stop f = 
  start >>> (fun () -> 
    start_event_handling ();
    keypress_handlers := {f; stop} :: !keypress_handlers)
