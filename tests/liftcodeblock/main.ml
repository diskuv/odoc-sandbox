open Tezt
open Tezt.Base

let tags = []

let register ~title = Test.register ~__FILE__ ~tags ~title

(* ------------------- last_word ----------------------- *)

let () =
  register ~title:"GIVEN empty string WHEN last_word" @@ fun () ->
  Check.((Liftcodeblock.last_word "" = "") string)
    ~error_msg:{|THEN = %R, but got %L|};
  unit

let () =
  register ~title:"GIVEN one word WHEN last_word" @@ fun () ->
  Check.((Liftcodeblock.last_word "hello" = "hello") string)
    ~error_msg:{|THEN = %R, but got %L|};
  unit

let () =
  register ~title:"GIVEN two words WHEN last_word" @@ fun () ->
  Check.((Liftcodeblock.last_word "hello there" = "there") string)
    ~error_msg:{|THEN = %R, but got %L|};
  unit

let () =
  register ~title:"GIVEN two words with trailing spaces WHEN last_word"
  @@ fun () ->
  Check.((Liftcodeblock.last_word "hello there    " = "there") string)
    ~error_msg:{|THEN = %R, but got %L|};
  unit

(* ------------------- lookahead ----------------------- *)

let () =
  register ~title:"GIVEN empty list WHEN lookahead" @@ fun () ->
  Check.(
    (Liftcodeblock.lookahead [] = []) (list (tuple2 string (option string))))
    ~error_msg:{|THEN = %R, but got %L|};
  unit

let () =
  register ~title:"GIVEN some list WHEN lookahead" @@ fun () ->
  Check.(
    (Liftcodeblock.lookahead [ "a"; "b"; "c"; "d" ]
    = [ ("a", Some "b"); ("b", Some "c"); ("c", Some "d"); ("d", None) ])
      (list (tuple2 string (option string))))
    ~error_msg:{|THEN = %R, but got %L|};
  unit

(* ----------------- contents_to_lines ----------------- *)

let () =
  register ~title:"GIVEN empty string WHEN contents_to_lines" @@ fun () ->
  Check.((Liftcodeblock.contents_to_lines "" = []) (list string))
    ~error_msg:{|THEN contents_to_lines "" = %R, but got %L|};
  unit

let () =
  register ~title:"GIVEN lines WHEN contents_to_lines" @@ fun () ->
  Check.(
    (Liftcodeblock.contents_to_lines "hi\nthere\nworld\n"
    = [ "hi"; "there"; "world" ])
      (list string))
    ~error_msg:{|THEN = %R, but got %L|};
  unit

let () =
  register ~title:"GIVEN 3 carriage-return ended lines WHEN contents_to_lines"
  @@ fun () ->
  Check.(
    (Liftcodeblock.contents_to_lines "hi\r\nthere\r\nworld\r\n"
    = [ "hi"; "there"; "world" ])
      (list string))
    ~error_msg:{|THEN = %R, but got %L|};
  unit

let () =
  register ~title:"GIVEN lines without closing newline WHEN contents_to_lines"
  @@ fun () ->
  Check.(
    (Liftcodeblock.contents_to_lines "hi\nthere\nworld"
    = [ "hi"; "there"; "world" ])
      (list string))
    ~error_msg:{|THEN = %R, but got %L|};
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

--------

The contents of the following code block ARE indented
because the ::code-block:: python is aligned to the left
of the contents.

```
::code-block:: console

  $ echo "Hi"
  # ls -lh
  % ls -lh
  > ls -lh
```

--------

The contents of the following code block are not indented
because the ::code-block:: python is aligned with the
contents.

```
  ::code-block:: python

  from a import b
  c = "string"
```
|})
  in
  Check.(
    (stringify_lines_with_state ans
    = [
        "Outside";
        "Start_backticks ```";
        "Directive(indent=0, code-block(python)) ::code-block:: python";
        "Codeblock(dedent=0)";
        "Codeblock(dedent=0) from a import b";
        "Codeblock(dedent=0) c = \"string\"";
        "End_backticks ```";
        "Outside";
        "Outside --------";
        "Outside";
        "Outside The contents of the following code block ARE indented";
        "Outside because the ::code-block:: python is aligned to the left";
        "Outside of the contents.";
        "Outside";
        "Start_backticks ```";
        "Directive(indent=0, code-block(console)) ::code-block:: console";
        "Codeblock(dedent=0)";
        "Codeblock(dedent=0)   $ echo \"Hi\"";
        "Codeblock(dedent=0)   # ls -lh";
        "Codeblock(dedent=0)   % ls -lh";
        "Codeblock(dedent=0)   > ls -lh";
        "End_backticks ```";
        "Outside";
        "Outside --------";
        "Outside";
        "Outside The contents of the following code block are not indented";
        "Outside because the ::code-block:: python is aligned with the";
        "Outside contents.";
        "Outside";
        "Start_backticks ```";
        "Directive(indent=2, code-block(python))   ::code-block:: python";
        "Codeblock(dedent=2)";
        "Codeblock(dedent=2)   from a import b";
        "Codeblock(dedent=2)   c = \"string\"";
        "End_backticks ```";
      ])
      (list string))
    ~error_msg:{|THEN = %R, but got %L|};
  unit

(* --------------- run --------------- *)

let () = Test.run ()
