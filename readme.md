# el2md - Convert commentary section of elisp files to markdown

*Author:* Jade Michael Thornton<br>
*Version:* 1.0.0<br>
*URL:* [https://gitlab.com/thornjad/el2md](https://gitlab.com/thornjad/el2md)<br>

This package converts *Commentary* section in Emacs Lisp modules to text
files in Markdown format, a format supporting headings, code blocks, basic
text styles, bullet lists etc.

The Markdown is used by many web sites as an alternative to plain texts. For
example, it is used by sites like StackOverflow, GitLab and GitHub.

## What is converted

Everything between the `Commentary:` and `Code:` markers are included in the
generated text. In addition, the title and *some* metadata are also included.

## How to write comments

The general rule of thumb is that the Emacs Lisp module should be written
using plain text, as they always have been written.

However, some things are recognized. A single line ending with a colon is
considered a *heading*. If this line is at the start of a comment block, it
is considered a main (level 2) heading. Otherwise it is considered a (level
3) subheading. Note that the line precedes a bullet list or code, it will not
be treated as a subheading.

### Use Markdown formatting

It is possible to use markdown syntax in the text, like *this*, and **this**.

### Conventions

The following conventions are used when converting elisp comments to
Markdown:

* Code blocks using either the Markdown convention by indenting the block
  with four extra spaces, or by starting a paragraph with a `(`.
* In elisp comments, a reference to `code` (backquote - quote), they will be
  converted to Markdown style (backquote - backquote).
* In elisp comments, bullets in lists are typically separated by empty lines.
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
    ;; This line is *not* as a subheading:
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
of an archive, it is displayed when viewing the archive. To generate a
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


---
Converted from `el2md.el` by [*el2md*](https://gitlab.com/thornjad/el2md).
