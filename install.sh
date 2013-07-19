#!/bin/sh

# Build
ocamlbuild -use-ocamlfind async_graphics.cma
ocamlbuild -use-ocamlfind async_graphics.cmxa

# Install
ocamlfind install async_graphics META async_graphics.mli _build/async_graphics.cmi _build/async_graphics.cma _build/async_graphics.cmxa