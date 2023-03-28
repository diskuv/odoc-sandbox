(** {1 String Utilities} *)

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

let get_indent line =
  try
    for i = 0 to String.length line - 1 do
      if line.[i] <> ' ' then raise (IndentFound i)
    done;
    String.length line
  with IndentFound found_i -> found_i

let indent_line ~indent s =
  let prefix = String.make indent ' ' in
  prefix ^ s

let dedent_line ~dedent s =
  let existing_indent = get_indent s in
  if existing_indent < dedent then
    (* The line is not sufficiently indented. We could error, or gracefully fix the problem.
       We choose to fix the problem by trimming all the spaces from the left. *)
    String.sub s existing_indent (String.length s - existing_indent)
  else
    (* Remove the first N spaces *)
    String.sub s dedent (String.length s - dedent)

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

(** {1 Operations} *)

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
  | Start_backticks of { indent : int; language_opt : string option }
  | Directive of { indent : int; directive : directive }
  | Codeblock of { dedent : int }
  | End_backticks

let visit_lines_with_codeblocks ?debug (lines : string list) :
    (codeblock_state * string) list =
  ignore debug;
  let is_backticks line = String.(equal (trim line) "```") in
  let is_codeblock_directive line =
    starts_with ~prefix:"::code-block::" (String.trim line)
  in
  let rec helper state remaining_lines acc =
    match (state, remaining_lines) with
    | _, [] -> acc
    | Outside, line :: rest when is_backticks line ->
        let newstate =
          Start_backticks { language_opt = None; indent = get_indent line }
        in
        helper newstate rest ((newstate, line) :: acc)
    | Start_backticks _, line :: rest when is_codeblock_directive line ->
        let language = last_word line in
        let directive =
          Directive
            {
              indent = get_indent line;
              directive = Directive_code_block { language };
            }
        in
        helper directive rest ((directive, line) :: acc)
    | (Start_backticks _ | Directive _ | Codeblock _), line :: rest
      when is_backticks line ->
        helper End_backticks rest ((End_backticks, line) :: acc)
    | Start_backticks _, line :: rest ->
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
  | Start_backticks _ -> "[start]        "
  | Directive { indent; _ } -> Printf.sprintf "[directive %2d] " indent
  | Codeblock { dedent } -> Printf.sprintf "[codeblock %2d] " dedent
  | End_backticks -> "[end]          "

let description_of_state = function
  | Outside -> "Outside"
  | Start_backticks { indent; language_opt } -> (
      match language_opt with
      | None -> Printf.sprintf "Start_backticks(indent=%d)" indent
      | Some language ->
          Printf.sprintf "Start_backticks(indent=%d,%s)" indent language)
  | Directive { indent; directive } ->
      Printf.sprintf "Directive(indent=%d, %s)" indent
        (directive_to_string directive)
  | Codeblock { dedent } -> Printf.sprintf "Codeblock(dedent=%d)" dedent
  | End_backticks -> "End_backticks"

let string_of_line_with_state = function
  | Outside, line -> line
  | Start_backticks { indent; language_opt }, _ -> (
      match language_opt with
      | None -> indent_line ~indent "```"
      | Some language -> indent_line ~indent (Printf.sprintf "```%s" language))
  | Directive _, line | Codeblock _, line | End_backticks, line -> line

let lookahead lst =
  let rec helper remaining previous_opt acc =
    match (previous_opt, remaining) with
    | Some previous, [] -> (previous, None) :: acc
    | Some previous, hd :: tl -> helper tl (Some hd) ((previous, Some hd) :: acc)
    | None, [] -> acc
    | None, hd :: tl -> helper tl (Some hd) acc
  in
  List.rev (helper lst None [])

type normalize_phase =
  | Standard
  | Remove_directive_code_block
  | Remove_leading_blank_lines

(** Perform the LIFT of ::code-block:: onto triple backquotes if needed *)
let normalize_codeblock_lines1 lines_with_state =
  let rec helper acc phase
      (line_and_maybe_next_lst :
        ((codeblock_state * string) * (codeblock_state * string) option) list) =
    match line_and_maybe_next_lst with
    | [] -> acc
    | ( (Start_backticks { indent = indent_backticks; _ }, line),
        Some
          ( Directive
              { indent = _; directive = Directive_code_block { language } },
            _ ) )
      :: tl ->
        (* LIFT
           from
              ```
              ::code-block:: <language>
           to
              ```<language>
           using the indentation of the original "```".
        *)
        let new_acc =
          ( Start_backticks
              { indent = indent_backticks; language_opt = Some language },
            line )
          :: acc
        in
        helper new_acc Remove_directive_code_block tl
    | ((Directive { indent = _; directive = Directive_code_block _ }, _), _)
      :: tl
      when phase = Remove_directive_code_block ->
        (* SQUELCH ::code-block:: <language> if we just did a LIFT *)
        helper acc Standard tl
    | ((Codeblock { dedent }, line), _) :: tl ->
        (* DEDENT the code block *)
        let new_acc =
          (Codeblock { dedent = 0 }, dedent_line ~dedent line) :: acc
        in
        helper new_acc Standard tl
    | (current, _) :: tl ->
        (* Base case: Keep the line unmodified *)
        let new_acc = current :: acc in
        helper new_acc Standard tl
  in
  List.rev @@ helper [] Standard (lookahead lines_with_state)

(** Removes a leading blank line if there are no directives in a code block,
    and adds the ocaml language code to triple quotes if a language
    has not already been lifted. *)
let normalize_codeblock_lines2 lines_with_state =
  let rec helper acc phase
      (line_and_maybe_next_lst : (codeblock_state * string) list) =
    match line_and_maybe_next_lst with
    | [] -> acc
    | (Start_backticks { language_opt; indent }, line) :: tl ->
        (* REMOVE_LEADING_BLANK_LINES
           from
              ```<language>
              {blank}
           to
              ```<language>

           and ADD_OCAML_LANGUAGE_IF_NO_LANGUAGE
           from
               ```
           to
               ```ocaml
        *)
        let new_language = Option.value ~default:"ocaml" language_opt in
        let new_acc =
          (Start_backticks { language_opt = Some new_language; indent }, line)
          :: acc
        in
        helper new_acc Remove_leading_blank_lines tl
    | (Codeblock _, line) :: tl
      when phase = Remove_leading_blank_lines
           && String.equal "" (String.trim line) ->
        (* SQUELCH line if we are still in REMOVE_LEADING_BLANK_LINES *)
        helper acc Remove_leading_blank_lines tl
    | current :: tl ->
        (* Base case: Keep the line unmodified *)
        let new_acc = current :: acc in
        helper new_acc Standard tl
  in
  List.rev @@ helper [] Standard lines_with_state

(** Lifts the code-block directive onto the backticks, performs
    dedentation, and removes leading blank lines if there are no
    directives. *)
let normalize_codeblock_lines lines_with_state =
  (* We normalize twice ... the first to perform the LIFT if needed (which deletes
     a directive), and the second to SQUELCH leading blank lines in code blocks without
     any directives.
  *)
  normalize_codeblock_lines2 (normalize_codeblock_lines1 lines_with_state)

let lift s =
  let lines =
    normalize_codeblock_lines
      (visit_lines_with_codeblocks (contents_to_lines s))
  in
  List.map string_of_line_with_state lines
  |> List.map (fun s -> s ^ "\n")
  |> String.concat ""
