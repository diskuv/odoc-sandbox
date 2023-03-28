<div class="odoc-preamble">

# Module `Feature_codeblock`

Here, we test the proposed code blocks.

</div>

- [Code Blocks](#code-blocks)

<div class="odoc-content">

## <a href="#code-blocks" class="anchor"></a>Code Blocks

Here is some Python code:

```python
        from a import b
        c = "string"
```

and here is a shell session:

```console
$ echo "Hi"
# ls -lh
% ls -lh
> ls -lh
```

We also have a regular odoc code block, which defaults to OCaml syntax:

```
     let foo = ()
     (** There are some nested comments in here, but an unpaired comment
         terminator would terminate the whole doc surrounding comment. It's
         best to keep code blocks no wider than 72 characters. *)
     
     let bar =
       ignore foo
```

Make sure to **compare the original .mli** by pressing "View document
source" below if you see the syntax highlighted code above!

</div>
