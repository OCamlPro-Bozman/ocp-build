
#if OCAML_VERSION < "4.03"
module String403 = struct
  include String
  let lowercase_ascii = lowercase
  let uppercase_ascii = uppercase
  let capitalize_ascii = capitalize
end

module Char = struct
  include Char
  let uppercase_ascii = uppercase
  let lowercase_ascii = lowercase
end
#else
module String403 = struct
  include String
  let lowercase = lowercase_ascii
  let uppercase = uppercase_ascii
  let capitalize = capitalize_ascii
end
module Char = struct
  include Char
  let uppercase = uppercase_ascii
  let lowercase = lowercase_ascii
end
#endif

#if OCAML_VERSION < "4.02"

type bytes = string

module Bytes = struct
  include String403
  let to_string t = String.copy t
  let of_string t = String.copy t
  let unsafe_to_string t = t
  let unsafe_of_string t = t
  let sub_string = String.sub
  let blit_string = String.blit
 end

module Buffer = struct
  include Buffer
  let to_bytes b = contents b
  let add_subbytes = add_substring
end

module Marshal = struct
  include Marshal
  let from_bytes = from_string
end

module String = String403

let print_bytes = print_string
let prerr_bytes = prerr_string
let output_bytes = output_string
let output_substring = output
let really_input_string ic len =
  let s = String.create len in
  really_input ic s 0 len;
  s

#else

module Bytes = Bytes
module Buffer = Buffer

module String = struct
  include String403
  let set = Bytes.set
end

#endif

module StringSet = Set.Make(String)

module StringMap = struct
  module M = Map.Make(String)
  include M
  let of_list list =
    let map = ref empty in
    List.iter (fun (x,y) -> map := add x y !map) list;
    !map

  let to_list map =
    let list = ref [] in
    iter (fun x y -> list := (x,y) :: !list) map;
    List.rev !list

  let to_list_of_keys map =
    let list = ref [] in
    iter (fun x y -> list := x :: !list) map;
    List.rev !list
end
