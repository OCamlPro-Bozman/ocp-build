(**************************************************************************)
(*                                                                        *)
(*                              OCamlPro TypeRex                          *)
(*                                                                        *)
(*   Copyright OCamlPro 2011-2016. All rights reserved.                   *)
(*   This file is distributed under the terms of the GPL v3.0             *)
(*      (GNU Public Licence version 3.0).                                 *)
(*                                                                        *)
(*     Contact: <typerex@ocamlpro.com> (http://www.ocamlpro.com/)         *)
(*                                                                        *)
(*  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,       *)
(*  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES       *)
(*  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND              *)
(*  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS   *)
(*  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN    *)
(*  ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN     *)
(*  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE      *)
(*  SOFTWARE.                                                             *)
(**************************************************************************)


open StringCompat


let verbose = ref false

let log key fmt =
  let fn str =
    if !verbose then
      let date = Date.string_of_iso8601 (Date.iso8601 ()) in
      Printf.printf "[%s] %-10s %s\n%!" date key str in
  Printf.kprintf fn fmt

let set_quiet () = verbose := false
let set_verbose () = verbose := true

(* Tifn: I'm mixing my debug here (we shall merge this some day)
   because I don't want to choose another module name, and those are
   related things anyway. *)

open Format

module type S = sig

  val debug : ('a, out_channel, unit) format -> 'a
  val debugln : ('a, out_channel, unit) format -> 'a
  val fdebug : ('a, Format.formatter, unit, unit) format4 -> 'a
  val fdebugln : ('a, Format.formatter, unit, unit) format4 -> 'a
  val debug_formatter : Format.formatter

end

module Make (X : sig

  val debug_channel : unit -> out_channel option
  val prefix : unit -> string option

end) : S = struct

  let debug_formatter =
    Format.make_formatter
      (fun buf start len ->
        match X.debug_channel () with
          | Some c -> output_substring c buf start len
          | None -> ())
      (fun () ->
        match X.debug_channel () with
          | Some c -> flush c
          | None -> ())

  let debug f =
    match X.debug_channel () with
      | Some c ->
        Option.iter (Printf.fprintf c "%s") (X.prefix ());
        Printf.kfprintf flush c f
      | None -> Printf.ifprintf stderr f

  let debugln f =
    match X.debug_channel () with
      | Some c ->
        Option.iter (Printf.fprintf c "%s") (X.prefix ());
        Printf.kfprintf (function c -> Printf.fprintf c "\n%!") c f
      | None -> Printf.ifprintf stderr f

  let fdebug f =
    match X.debug_channel () with
      | Some c ->
        Option.iter (pp_print_string debug_formatter) (X.prefix ());
        kfprintf (fun fmt -> pp_print_flush fmt ()) debug_formatter f
      | None -> Format.ifprintf Format.err_formatter f

  let fdebugln f =
    match X.debug_channel () with
      | Some c ->
        Option.iter (pp_print_string debug_formatter) (X.prefix ());
        kfprintf (fun fmt -> pp_print_newline fmt () ; pp_print_flush fmt ())
          debug_formatter f
      | None -> Format.ifprintf Format.err_formatter f

end

let debug_channel = ref stderr

let append_log_to f =
  let flags = [ Open_append; Open_creat ]
  and perm = 0o640 in
  debug_channel := open_out_gen flags perm f

let tags = ref []
let all_tags () = !tags

module Tag(X : sig
  val tag : string
end) = Make
(struct

  let verbose = ref false

  let () =
    if List.mem_assoc X.tag !tags then
      invalid_arg ("Multiple debug tags " ^ X.tag)
    else
      tags := (X.tag, verbose) :: !tags

  let debug_channel () =
    if !verbose then
      Some !debug_channel
    else
      None

  let prefix () = Some (X.tag ^ ": ")

end)

let set_verbose_tag tag v =
  try
    List.assoc tag !tags := v
  with
      Not_found ->
        invalid_arg ("Undefined debug tag " ^ tag)

let set_verbose_all v =
  List.iter (function _, t -> t := v) !tags

include Make(struct
  let debug_channel () =
    if !verbose then
      Some !debug_channel
    else
      None
  let prefix () = None
end)
