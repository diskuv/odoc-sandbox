(** Here, we test the proposed code blocks. *)

(** {1 Code Blocks}

    Here is some Python code:

{v
::code-block:: python

from a import b
c = "string"
v}

    and here is a shell session:

{v
::code-block:: console

$ echo "Hi"
# ls -lh
% ls -lh
> ls -lh
v}
    
    We also have a regular odoc code block, which defaults to OCaml syntax:

    {[
let foo = ()
(** There are some nested comments in here, but an unpaired comment
    terminator would terminate the whole doc surrounding comment. It's
    best to keep code blocks no wider than 72 characters. *)

let bar =
  ignore foo
    ]}

    Make sure to {b compare the original .mli} by pressing "View document source"
    below if you see the syntax highlighted code above!
*)