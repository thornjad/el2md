# el2md - Convert commentary section of elisp files to markdown

_Author:_ Jade Michael Thornton<br>
_Version:_ 1.0.1<br>
_URL:_ [https://gitlab.com/thornjad/el2md](https://gitlab.com/thornjad/el2md)<br>

This package converts the _Commentary_ section in an Elisp module to text
files in the Markdown language. It supports most of Markdown, including some
headings, code blocks, text styles, lists, etc.

## What is converted

Everything between the `Commentary:` and `Code:` markers are included in the
generated text. In addition, the title and _some_ metadata is also included.

## How to write comments

The general rule of thumb is that the Elisp module should be written
using plain text, as they always have been written. However, some things are
recognized. A single line ending with a colon is considered a _heading_. If
this line is at the start of a comment block, it is considered a main (level
2) heading. Otherwise it is considered a (level 3) subheading. Note that if
the line precedes a bullet list or code, it will not be treated as a
subheading.

### Use Markdown formatting

It is possible to use markdown syntax in the text, like _this_, and **this**.

### Conventions

The following conventions are used when converting Elisp comments to
Markdown:

* Code blocks using either the Markdown convention by indenting the block
  with four extra spaces, or by starting a paragraph with a `(`.
* In Elisp comments, a reference to `code` (backquote - quote) will be
  converted to Markdown (backquote - backquote).
* In Elisp comments, bullets in lists are typically separated by empty lines.
  In the converted text, the empty lines are removed, as required by
  Markdown.


## Example

    ;; This is a heading:
    ;;
    ;; Bla bla bla ...

    ;; This is another heading:
    ;;
    ;; This is a paragraph!
    ;;
    ;; A subheading:
    ;;
    ;; Another paragraph.
    ;;
    ;; This line is _not_ as a subheading:
    ;;
    ;; * A bullet in a list
    ;;
    ;; * Another bullet.

## Usage

To generate the markdown representation of the current buffer to a temporary
buffer, use:

    M-x el2md-view-buffer RET

To write the markdown representation of the current buffer to a file, use:

    M-x el2md-write-file RET name-of-file RET

In sites like GitLab, if a file named readme.md exists in the root directory
of an repository, it is displayed when viewing the repository. To generate a
readme.md file, in the same directory as the current buffer, use:

    M-x el2md-write-readme RET

## Post processing

To post-process the output, add a function to `el2md-post-convert-hook`. The
functions in the hook should accept one argument, the output stream
(typically the destination buffer). When the hook is run current buffer is
the source buffer.

## Batch mode

You can run el2md in batch mode. The function `el2md-write-readme` can be
called directly using the `-f` option. The others can be accessed with the
`--eval` form.

For example,

    emacs -batch -l el2md.el my-file.el -f el2md-write-readme

## Known problems

- The end of the _Commentary_ section includes the first comment in the code
  if there's no empty line before the _Code_ comment.

## License

`el2md` was originally forked from `el2markdown` by Anders Lindgren. It has
since been improved, but carries the same license as the original work.

Copyright (c) 2020 Jade Michael Thornton
Copyright (c) 2013 Anders Lindgren

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, version 3. This program is distributed in the hope that it will
be useful, but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose. See the GNU General
Public License for more details.


---
Converted from `el2md.el` by [_el2md_](https://gitlab.com/thornjad/el2md).
