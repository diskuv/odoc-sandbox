let input1 =
  {|
```
::code-block:: python

from a import b
c = "string"
```

```
::code-block:: console

  $ echo "Hi"
  # ls -lh
  % ls -lh
  > ls -lh
```
|}

let output1 =
  {|
```python
from a import b
c = "string"
```

```console
$ echo "Hi"
# ls -lh
% ls -lh
> ls -lh
```
|}

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
          let line = String.of_bytes (Buffer.to_bytes buf) in
          Buffer.clear buf;
          helper (pos + 1) (line :: acc)
      | c ->
          Buffer.add_char buf c;
          helper (pos + 1) acc
  in
  let all_but_last_line = List.rev (helper 0 []) in
  if Buffer.length buf > 0 then
    List.append all_but_last_line [ String.of_bytes (Buffer.to_bytes buf) ]
  else all_but_last_line

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
  | Start_backticks
  | Directive
  | Codeblock
  | End_backticks

let visit_lines_with_codeblocks ?debug (lines : string list) :
    (codeblock_state * string) list =
  ignore debug;
  let is_backticks line = String.(equal (trim line) "```") in
  let is_codeblock_directive line =
    String.(starts_with ~prefix:"::code-block::" (trim line))
  in
  let rec helper state remaining_lines acc =
    match (state, remaining_lines) with
    | _, [] -> acc
    | Outside, line :: rest when is_backticks line ->
        helper Start_backticks rest ((Start_backticks, line) :: acc)
    | Start_backticks, line :: rest when is_codeblock_directive line ->
        helper Directive rest ((Directive, line) :: acc)
    | (Start_backticks | Directive | Codeblock), line :: rest
      when is_backticks line ->
        helper End_backticks rest ((End_backticks, line) :: acc)
    | (Start_backticks | Directive), line :: rest ->
        helper Codeblock rest ((Codeblock, line) :: acc)
    | End_backticks, line :: rest -> helper Outside rest ((Outside, line) :: acc)
    | previous_state, line :: rest ->
        helper previous_state rest ((previous_state, line) :: acc)
  in
  let value = helper Outside lines [] in
  List.rev value

let print_codeblock_lines lines_with_state =
  List.iter
    (fun (state, s) ->
      let prefix =
        match state with
        | Outside -> "[outside]   "
        | Start_backticks -> "[start]     "
        | Directive -> "[directive] "
        | Codeblock -> "[codeblock] "
        | End_backticks -> "[end]       "
      in
      print_endline (prefix ^ s))
    lines_with_state

(** {1 Poor man's test cases}
    If these get numerous, use a real test apparatus like Alcotest *)

let () = assert ([] = contents_to_lines "")

let () =
  assert ([ "hi"; "there"; "world" ] = contents_to_lines "hi\nthere\nworld\n")

let () =
  assert (
    [ "hi"; "there"; "world" ] = contents_to_lines "hi\r\nthere\r\nworld\r\n")

let () =
  assert ([ "hi"; "there"; "world" ] = contents_to_lines "hi\nthere\nworld")
