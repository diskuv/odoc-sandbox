(** [contents_to_lines s] converts a string [s] with either DOS (CRLF) or Unix (LF)
    line terminators to a list of lines. The lines will not contain the CRLF or LF
    terminators. *)
let contents_to_lines s : string list =
  let buf = Buffer.create 10240 in
  let rec helper pos acc : string list =
    if pos = String.length s then acc
    else
      match s.[pos] with
      | '\r' when s.[pos + 1] = '\n' && pos + 1 < String.length s ->
          helper (pos + 1) acc
      | '\n' ->
          let line = Bytes.to_string (Buffer.to_bytes buf) in
          Buffer.clear buf;
          helper (pos + 1) (line :: acc)
      | c ->
          Buffer.add_char buf c;
          helper (pos + 1) acc
  in
  let all_but_last_line = List.rev (helper 0 []) in
  if Buffer.length buf > 0 then
    List.append all_but_last_line [ Bytes.to_string (Buffer.to_bytes buf) ]
  else all_but_last_line

type directive =
  | Directive_code_block of { language : string }
  | Other of string

let directive_to_string = function
  | Directive_code_block { language } ->
      Printf.sprintf "code-block(%s)" language
  | Other s -> Printf.sprintf "other(%s)" s

(** The type of the state of the codeblock processing.

    Each line can be in one, and only one, of the states.

  {v

                        # STATE = Outside
```                     # STATE = Start_backticks
::code-block:: console  # STATE = Directive
                        # STATE = Codeblock
  $ echo "Hi"           # STATE = Codeblock
  # ls -lh              # STATE = Codeblock
  % ls -lh              # STATE = Codeblock
  > ls -lh              # STATE = Codeblock
```                     # STATE = End_backticks
                        # STATE = Outside
  v}

*)
type codeblock_state =
  | Outside
  | Start_backticks of { language_opt : string option }
  | Directive of { indent : int; directive : directive }
  | Codeblock of { dedent : int }
  | End_backticks

let starts_with ~prefix s =
  let ls = String.length s and lp = String.length prefix in
  if lp > ls then false else String.equal prefix (String.sub s 0 lp)

let last_word s =
  let s = String.trim s in
  match String.rindex_opt s ' ' with
  | None -> s
  | Some i when i = String.length s - 1 ->
      (* impossible b/c trimmed, but keep for safety of last match clause's String.sub *)
      ""
  | Some i -> String.sub s (i + 1) (String.length s - i - 1)

exception IndentFound of int

let visit_lines_with_codeblocks ?debug (lines : string list) :
    (codeblock_state * string) list =
  ignore debug;
  let is_backticks line = String.(equal (trim line) "```") in
  let is_codeblock_directive line =
    starts_with ~prefix:"::code-block::" (String.trim line)
  in
  let get_indent line =
    try
      for i = 0 to String.length line - 1 do
        if line.[i] <> ' ' then raise (IndentFound i)
      done;
      String.length line
    with IndentFound found_i -> found_i
  in
  let rec helper state remaining_lines acc =
    match (state, remaining_lines) with
    | _, [] -> acc
    | Outside, line :: rest when is_backticks line ->
        let newstate = Start_backticks { language_opt = None } in
        helper newstate rest ((newstate, line) :: acc)
    | Start_backticks { language_opt = _ }, line :: rest
      when is_codeblock_directive line ->
        let language = last_word line in
        let directive =
          Directive
            {
              indent = get_indent line;
              directive = Directive_code_block { language };
            }
        in
        helper directive rest ((directive, line) :: acc)
    | ( ( Start_backticks { language_opt = _ }
        | Directive { indent = _; directive = _ }
        | Codeblock { dedent = _ } ),
        line :: rest )
      when is_backticks line ->
        helper End_backticks rest ((End_backticks, line) :: acc)
    | Start_backticks { language_opt = _ }, line :: rest ->
        let codeblock = Codeblock { dedent = 0 } in
        helper codeblock rest ((codeblock, line) :: acc)
    | Directive { indent; directive = _ }, line :: rest ->
        let codeblock = Codeblock { dedent = indent } in
        helper codeblock rest ((codeblock, line) :: acc)
    | End_backticks, line :: rest -> helper Outside rest ((Outside, line) :: acc)
    | previous_state, line :: rest ->
        helper previous_state rest ((previous_state, line) :: acc)
  in
  let value = helper Outside lines [] in
  List.rev value

let prefix_of_state = function
  | Outside -> "[outside]      "
  | Start_backticks { language_opt = _ } -> "[start]        "
  | Directive { indent; directive = _ } ->
      Printf.sprintf "[directive %2d] " indent
  | Codeblock { dedent } -> Printf.sprintf "[codeblock %2d] " dedent
  | End_backticks -> "[end]          "

let state_to_string = function
  | Outside -> "Outside"
  | Start_backticks { language_opt } -> (
      match language_opt with
      | None -> "Start_backticks"
      | Some language -> Printf.sprintf "Start_backticks(%s)" language)
  | Directive { indent; directive } ->
      Printf.sprintf "Directive(indent=%d, %s)" indent
        (directive_to_string directive)
  | Codeblock { dedent } -> Printf.sprintf "Codeblock(dedent=%d)" dedent
  | End_backticks -> "End_backticks"

let print_codeblock_lines lines_with_state =
  List.iter
    (fun (state, s) -> print_endline (prefix_of_state state ^ s))
    lines_with_state

let lookahead lst =
  let rec helper remaining previous_opt acc =
    match (previous_opt, remaining) with
    | Some previous, [] -> (previous, None) :: acc
    | Some previous, hd :: tl -> helper tl (Some hd) ((previous, Some hd) :: acc)
    | None, [] -> acc
    | None, hd :: tl -> helper tl (Some hd) acc
  in
  List.rev (helper lst None [])
