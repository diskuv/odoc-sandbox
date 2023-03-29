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
      Liftcodeblock.description_of_state codeblock_state
      ^ if String.equal "" line then "" else " " ^ line)

let () =
  register
    ~title:
      "GIVEN differently fenced and indented python, java and console code \
       blocks WHEN visit_lines_with_codeblocks"
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

```java
public class A {
}
```

```language-java
public class B {
}
```

--------

The inner code block IS indented
because the ::code-block:: python is aligned to the left
of the text.

```
::code-block:: console

  $ echo "Hi"
  # ls -lh
  % ls -lh
  > ls -lh
```

--------

The inner code block is not indented because
the ::code-block:: is aligned with its
text.

```
  ::code-block:: python

  from a import b
  c = "string"
```

--------

The inner code block is not indented
because the ::code-block:: python is aligned with the
contents. However, the outer fenced block is indented, so
the final rendering should align the code block with the
outer fenced block.

* Here it is:

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
        "Start_backticks(indent=0) ```";
        "Directive(indent=0, backticks_indent=0, code-block(python)) \
         ::code-block:: python";
        "Codeblock(dedent=0)";
        "Codeblock(dedent=0) from a import b";
        "Codeblock(dedent=0) c = \"string\"";
        "End_backticks ```";
        "Outside";
        "Start_backticks(indent=0,java) ```java";
        "Codeblock(dedent=0) public class A {";
        "Codeblock(dedent=0) }";
        "End_backticks ```";
        "Outside";
        "Start_backticks(indent=0,java) ```language-java";
        "Codeblock(dedent=0) public class B {";
        "Codeblock(dedent=0) }";
        "End_backticks ```";
        "Outside";
        "Outside --------";
        "Outside";
        "Outside The inner code block IS indented";
        "Outside because the ::code-block:: python is aligned to the left";
        "Outside of the text.";
        "Outside";
        "Start_backticks(indent=0) ```";
        "Directive(indent=0, backticks_indent=0, code-block(console)) \
         ::code-block:: console";
        "Codeblock(dedent=0)";
        "Codeblock(dedent=0)   $ echo \"Hi\"";
        "Codeblock(dedent=0)   # ls -lh";
        "Codeblock(dedent=0)   % ls -lh";
        "Codeblock(dedent=0)   > ls -lh";
        "End_backticks ```";
        "Outside";
        "Outside --------";
        "Outside";
        "Outside The inner code block is not indented because";
        "Outside the ::code-block:: is aligned with its";
        "Outside text.";
        "Outside";
        "Start_backticks(indent=0) ```";
        "Directive(indent=2, backticks_indent=0, code-block(python))   \
         ::code-block:: python";
        "Codeblock(dedent=2)";
        "Codeblock(dedent=2)   from a import b";
        "Codeblock(dedent=2)   c = \"string\"";
        "End_backticks ```";
        "Outside";
        "Outside --------";
        "Outside";
        "Outside The inner code block is not indented";
        "Outside because the ::code-block:: python is aligned with the";
        "Outside contents. However, the outer fenced block is indented, so";
        "Outside the final rendering should align the code block with the";
        "Outside outer fenced block.";
        "Outside";
        "Outside * Here it is:";
        "Outside";
        "Start_backticks(indent=2)   ```";
        "Directive(indent=4, backticks_indent=2, code-block(python))     \
         ::code-block:: python";
        "Codeblock(dedent=2)";
        "Codeblock(dedent=2)     from a import b";
        "Codeblock(dedent=2)     c = \"string\"";
        "End_backticks   ```";
      ])
      (list string))
    ~error_msg:{|THEN = %R, but got %L|};
  unit

(* --------------- normalize_codeblock_lines1 --------------- *)

let () =
  register ~title:"GIVEN code blocks WHEN normalize_codeblock_lines1"
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

* Indented fenced block with an
  indented code-block:

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

```
  ::code-block:: python

  from a import b
  c = "string"
```
|})
  in
  Check.(
    (stringify_lines_with_state (Liftcodeblock.normalize_codeblock_lines1 ans)
    = [
        "Outside";
        "Start_backticks(indent=0,python) ```";
        "Codeblock(dedent=0)";
        "Codeblock(dedent=0) from a import b";
        "Codeblock(dedent=0) c = \"string\"";
        "End_backticks ```";
        "Outside";
        "Outside * Indented fenced block with an";
        "Outside   indented code-block:";
        "Outside";
        "Start_backticks(indent=2,python)   ```";
        "Codeblock(dedent=0)";
        "Codeblock(dedent=0)   from a import b";
        "Codeblock(dedent=0)   c = \"string\"";
        "End_backticks   ```";
        "Outside";
        "Start_backticks(indent=0,console) ```";
        "Codeblock(dedent=0)";
        "Codeblock(dedent=0)   $ echo \"Hi\"";
        "Codeblock(dedent=0)   # ls -lh";
        "Codeblock(dedent=0)   % ls -lh";
        "Codeblock(dedent=0)   > ls -lh";
        "End_backticks ```";
        "Outside";
        "Start_backticks(indent=0,python) ```";
        "Codeblock(dedent=0)";
        "Codeblock(dedent=0) from a import b";
        "Codeblock(dedent=0) c = \"string\"";
        "End_backticks ```";
      ])
      (list string))
    ~error_msg:{|THEN = %R, but got %L|};
  unit

(* -------- normalize_codeblock_lines1 + normalize_codeblock_lines2 -------- *)

let () =
  register
    ~title:
      "GIVEN code blocks WHEN normalize_codeblock_lines1 WHEN \
       normalize_codeblock_lines2"
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
let () = print_endline "This is OCaml"
```

```
::code-block:: console

  $ echo "Hi"
  # ls -lh
  % ls -lh
  > ls -lh
```

```
  ::code-block:: python

  from a import b
  c = "string"
```
|})
  in
  Check.(
    (stringify_lines_with_state
       (Liftcodeblock.normalize_codeblock_lines2
          (Liftcodeblock.normalize_codeblock_lines1 ans))
    = [
        "Outside";
        "Start_backticks(indent=0,python) ```";
        "Codeblock(dedent=0) from a import b";
        "Codeblock(dedent=0) c = \"string\"";
        "End_backticks ```";
        "Outside";
        "Start_backticks(indent=0,ocaml) ```";
        "Codeblock(dedent=0) let () = print_endline \"This is OCaml\"";
        "End_backticks ```";
        "Outside";
        "Start_backticks(indent=0,console) ```";
        "Codeblock(dedent=0)   $ echo \"Hi\"";
        "Codeblock(dedent=0)   # ls -lh";
        "Codeblock(dedent=0)   % ls -lh";
        "Codeblock(dedent=0)   > ls -lh";
        "End_backticks ```";
        "Outside";
        "Start_backticks(indent=0,python) ```";
        "Codeblock(dedent=0) from a import b";
        "Codeblock(dedent=0) c = \"string\"";
        "End_backticks ```";
      ])
      (list string))
    ~error_msg:{|THEN = %R, but got %L|};
  unit

(* --------------- lift --------------- *)

let () =
  register ~title:"GIVEN code blocks WHEN lift" @@ fun () ->
  Check.(
    (Liftcodeblock.lift
       {|
```
::code-block:: python




from a import b
c = "string"
```

```
let () = print_endline "This is OCaml"
```

```
::code-block:: console

  $ echo "Hi"
  # ls -lh
  % ls -lh
  > ls -lh
```

```
  ::code-block:: python

  from a import b
  c = "string"
```
|}
    = {|
```python
from a import b
c = "string"
```

```ocaml
let () = print_endline "This is OCaml"
```

```console
  $ echo "Hi"
  # ls -lh
  % ls -lh
  > ls -lh
```

```python
from a import b
c = "string"
```
|}
    )
      string)
    ~error_msg:{|THEN = %R, but got %L|};
  unit

let () =
  register
    ~title:
      "GIVEN indented outer fenced block and indented inner code block WHEN \
       lift"
  @@ fun () ->
  Check.(
    (Liftcodeblock.lift
       {|
  ```
       ::code-block:: tcshcon

       utop #> 3.5 +. 6. ;;
       > - : float = 9.5
       utop #> 30_000_000 / 300_000 ;;
       > - : int = 100
       utop #> let square x = x * x ;;
       > val square : int -> int = <fun>
       utop #> square 2 ;;
       > - : int = 4
       utop #> square (square 2) ;;
       > - : int = 16
  ```
|}
    = {|
  ```tcshcon
  utop #> 3.5 +. 6. ;;
  > - : float = 9.5
  utop #> 30_000_000 / 300_000 ;;
  > - : int = 100
  utop #> let square x = x * x ;;
  > val square : int -> int = <fun>
  utop #> square 2 ;;
  > - : int = 4
  utop #> square (square 2) ;;
  > - : int = 16
  ```
|}
    )
      string)
    ~error_msg:{|THEN = %R, but got %L|};
  unit

(* --------------- run --------------- *)

let () = Test.run ()
