open Tezt
open Tezt.Base

let tags = []

let register ~title = Test.register ~__FILE__ ~tags ~title

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

let () = Test.run ()
