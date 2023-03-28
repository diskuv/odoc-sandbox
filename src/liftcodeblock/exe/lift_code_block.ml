let usage =
  {|usage: liftcodeblock INPUT.md > OUTPUT.md

The transformed Markdown will be available on the standard output.
It will have LF endings, regardless of the CRLF / LF endings of INPUT.md.
|}

let () =
  (* Command line parsing *)
  let input = ref "" in
  let anon s = input := s in
  Arg.parse [] anon usage;
  if String.equal !input "" then
    failwith @@ Printf.sprintf "Missing INPUT.md\n%s" usage;
  (* Read. On Windows it is fine to read CRLF in binary;
     we need binary to read accurate file sizes. *)
  let ch_in = open_in_bin !input in
  Fun.protect
    ~finally:(fun () -> close_in_noerr ch_in)
    (fun () ->
      let sz = in_channel_length ch_in in
      let s = really_input_string ch_in sz in
      print_string (Liftcodeblock.lift s))
