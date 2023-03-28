open Tezt
open Tezt.Base

let tags = []

let register ~title = Test.register ~__FILE__ ~tags ~title

(* ----------------- contents_to_lines ----------------- *)

let () =
  register ~title:"GIVEN empty string WHEN contents_to_lines" @@ fun () ->
  Check.((Liftcodeblock.contents_to_lines "" = []) (list string))
    ~error_msg:{|THEN contents_to_lines "" = %R, got %L|};
  unit

let () =
  register ~title:"GIVEN lines WHEN contents_to_lines" @@ fun () ->
  Check.(
    (Liftcodeblock.contents_to_lines "hi\nthere\nworld\n"
    = [ "hi"; "there"; "world" ])
      (list string))
    ~error_msg:{|THEN = %R, got %L|};
  unit

let () =
  register ~title:"GIVEN 3 carriage-return ended lines WHEN contents_to_lines"
  @@ fun () ->
  Check.(
    (Liftcodeblock.contents_to_lines "hi\r\nthere\r\nworld\r\n"
    = [ "hi"; "there"; "world" ])
      (list string))
    ~error_msg:{|THEN = %R, got %L|};
  unit

let () =
  register ~title:"GIVEN lines without closing newline WHEN contents_to_lines"
  @@ fun () ->
  Check.(
    (Liftcodeblock.contents_to_lines "hi\nthere\nworld"
    = [ "hi"; "there"; "world" ])
      (list string))
    ~error_msg:{|THEN = %R, got %L|};
  unit

(* ----------------- visit_lines_with_codeblocks ----------------- *)

let stringify_lines_with_state :
    (Liftcodeblock.codeblock_state * string) list -> string list =
  List.map (fun (codeblock_state, line) ->
      Liftcodeblock.state_to_string codeblock_state
      ^ if String.equal "" line then "" else " " ^ line)

let () =
  register
    ~title:
      "GIVEN different indented python and console code blocks WHEN \
       visit_lines_with_codeblocks"
  @@ fun () ->
  let ans =
    let open Liftcodeblock in
    visit_lines_with_codeblocks
      (contents_to_lines
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
|})
  in
  Check.(
    (stringify_lines_with_state ans
    = [
        "Outside";
        "Start_backticks ```";
        "Directive ::code-block:: python";
        "Codeblock";
        "Codeblock from a import b";
        "Codeblock c = \"string\"";
        "End_backticks ```";
        "Outside";
        "Start_backticks ```";
        "Directive ::code-block:: console";
        "Codeblock";
        "Codeblock   $ echo \"Hi\"";
        "Codeblock   # ls -lh";
        "Codeblock   % ls -lh";
        "Codeblock   > ls -lh";
        "End_backticks ```";
      ])
      (list string))
    ~error_msg:{|THEN = %R, got %L|};
  unit

(* --------------- run --------------- *)

let () = Test.run ()
