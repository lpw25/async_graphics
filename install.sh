#!/bin/sh

# Build
ocamlbuild -use-ocamlfind -tag thread async_graphics.cma async_graphics.cmxa

# Install
ocamlfind install async_graphics META async_graphics.mli _build/async_graphics.cmi _build/async_graphics.cma _build/async_graphics.cmxa _build/async_graphics.cmx _build/async_graphics.a
