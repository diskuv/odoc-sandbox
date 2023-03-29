<div class="odoc-preamble">

# Module `Markup`

Here, we test the rendering of comment markup.

</div>

- [Sections](#sections)
  - [Subsection headings](#subsection-headings)
    - [Sub-subsection headings](#sub-subsection-headings)
    - [Anchors](#anchors)
      - [Paragraph](#paragraph)
        - [Subparagraph](#subparagraph)
- [Styling](#styling)
- [Links and references](#links-and-references)
- [Preformatted text](#preformatted-text)
- [Lists](#lists)
- [Unicode](#unicode)
- [Raw HTML](#raw-html)
- [Math](#math)
- [Modules](#modules)
- [Tags](#tags)

<div class="odoc-content">

## <a href="#sections" class="anchor"></a>Sections

Let's get these done first, because sections will be used to break up
the rest of this test.

Besides the section heading above, there are also

### <a href="#subsection-headings" class="anchor"></a>Subsection headings

and

#### <a href="#sub-subsection-headings" class="anchor"></a>Sub-subsection headings

but odoc has banned deeper headings. There are also title headings, but
they are only allowed in mld files.

#### <a href="#anchors" class="anchor"></a>Anchors

Sections can have attached [Anchors](#anchors), and it is possible to
[link](#anchors) to them. Links to section headers should not be set in
source code style.

##### <a href="#paragraph" class="anchor"></a>Paragraph

Individual paragraphs can have a heading.

###### <a href="#subparagraph" class="anchor"></a> Subparagraph

Parts of a longer paragraph that can be considered alone can also have
headings.

## <a href="#styling" class="anchor"></a>Styling

This paragraph has some styled elements: **bold** and *italic* , ***bold
italic***, *emphasis*, **emphasis* within emphasis*, ***bold italic***,
super<sup>script</sup>, sub<sub>script</sub> . The line spacing should
be enough for superscripts and subscripts not to look odd.

Note: *In italics *emphasis* is rendered as normal text while *emphasis
*in* emphasis* is rendered in italics.* *It also work the same in [links
in italics with *emphasis *in* emphasis*.](#)*

`code` is a different kind of markup that doesn't allow nested markup.

It's possible for two markup elements to appear **next** *to* each other
and have a space, and appear **next***to* each other with no space. It
doesn't matter **how** *much* space it was in the source: in this
sentence, it was two space characters. And in this one, there is **a**
*newline*.

This is also true between *non-*`code` markup *and* `code`.

Code can appear **inside `other` markup**. Its display shouldn't be
affected.

## <a href="#links-and-references" class="anchor"></a>Links and references

This is a [link](#). It sends you to the top of this page. Links can
have markup inside them: [**bold**](#) , [*italics*](#), [*emphasis*](#)
, [super<sup>script</sup>](#), [sub<sub>script</sub>](#), and
[`code`](#). Links can also be nested *[inside](#)* markup. Links cannot
be nested inside each other. This link has no replacement text: [\#](#)
. The text is filled in by odoc. This is a shorthand link: [\#](#). The
text is also filled in by odoc in this case.

This is a reference to [`foo`](#val-foo). References can have
replacement text: [the value foo](#val-foo). Except for the special
lookup support, references are pretty much just like links. The
replacement text can have nested styles: [**bold**](#val-foo),
[*italic*](#val-foo), [*emphasis*](#val-foo),
[super<sup>script</sup>](#val-foo), [sub<sub>script</sub>](#val-foo),
and [`code`](#val-foo). It's also possible to surround a reference in a
style: **[`foo`](#val-foo)** . References can't be nested inside
references, and links and references can't be nested inside each other.

## <a href="#preformatted-text" class="anchor"></a>Preformatted text

This is a code block:

``` language-ocaml
    
     let foo = ()
     (** There are some nested comments in here, but an unpaired comment
         terminator would terminate the whole doc surrounding comment. It's
         best to keep code blocks no wider than 72 characters. *)
     
     let bar =
       ignore foo
    
   
```

There are also verbatim blocks:

    The main difference is these don't get syntax highlighting.

## <a href="#lists" class="anchor"></a>Lists

- This is a
- shorthand bulleted list,
- and the paragraphs in each list item support *styling*.

1.  This is a
2.  shorthand numbered list.

- Shorthand list items can span multiple lines, however trying to put
  two paragraphs into a shorthand list item using a double line break

just creates a paragraph outside the list.

- Similarly, inserting a blank line between two list items

<!-- -->

- creates two separate lists.

<!-- -->

- To get around this limitation, one

  can use explicitly-delimited lists.

- This one is bulleted,

1.  but there is also the numbered variant.

- - lists
  - can be nested
  - and can include references
  - [`foo`](#val-foo)

## <a href="#unicode" class="anchor"></a>Unicode

The parser supports any ASCII-compatible encoding, in particuλar UTF-8.

## <a href="#raw-html" class="anchor"></a>Raw HTML

Raw HTML can be as inline elements into sentences.

> If the raw HTML is the only thing in a paragraph, it is treated as a
> block element, and won't be wrapped in paragraph tags by the HTML
> generator.

## <a href="#math" class="anchor"></a>Math

Math elements can be inline: `\int_{-\infty}^\infty`, or blocks:

<div>

``` odoc-katex-math
         % \f is defined as #1f(#2) using the macro
         \newcommand{\f}[2]{#1f(#2)}
         \f\relax{x} = \int_{-\infty}^\infty
         \f\hat\xi\,e^{2 \pi i \xi x}
         \,d\xi
         
    
```

</div>

## <a href="#modules" class="anchor"></a>Modules

- [`X`](Markup-X.html)

<!-- -->

- [`X`](Markup-X.html)
- [`Y`](Markup-Y.html)

## <a href="#tags" class="anchor"></a>Tags

Each comment can end with zero or more tags. Here are some examples:

- <span class="at-tag">author</span> antron

<!-- -->

- <span class="at-tag">deprecated</span>

  a *long* time ago

<!-- -->

- <span class="at-tag">parameter</span> <span class="value">foo</span>

  unused

<!-- -->

- <span class="at-tag">raises</span> <span class="value">Failure</span>

  always

<!-- -->

- <span class="at-tag">returns</span>

  never

<!-- -->

- <span class="at-tag">see</span> <a href="#" class="value">#</a>

  this url

<!-- -->

- <span class="at-tag">see</span> `foo.ml`

  this file

<!-- -->

- <span class="at-tag">see</span> <span class="value">Foo</span>

  this document

<!-- -->

- <span class="at-tag">since</span> 0

<!-- -->

- <span class="at-tag">before</span> <span class="value">1.0</span>

  it was in b<sup>e</sup>t<sub>a</sub>

<!-- -->

- <span class="at-tag">version</span> -1

<div class="odoc-spec">

<div id="val-foo" class="spec value anchored">

<a href="#val-foo" class="anchor"></a> <span
class="keyword">`val`</span>` foo : unit`

</div>

<div class="spec-doc">

Comments in structure items **support** *markup*, t
<sup>o</sup><sub>o</sub>.

</div>

</div>

Some modules to support references.

<div class="odoc-spec">

<div id="module-X" class="spec module anchored">

<a href="#module-X" class="anchor"></a> ` `<span
class="keyword">`module`</span>` `[`X`](Markup-X.html)` `` `` : `<span
class="keyword">`sig`</span>` ... `<span
class="keyword">`end`</span>` `` `

</div>

</div>

<div class="odoc-spec">

<div id="module-Y" class="spec module anchored">

<a href="#module-Y" class="anchor"></a> ` `<span
class="keyword">`module`</span>` `[`Y`](Markup-Y.html)` `` `` : `<span
class="keyword">`sig`</span>` ... `<span
class="keyword">`end`</span>` `` `

</div>

</div>

</div>
