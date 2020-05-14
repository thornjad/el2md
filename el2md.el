;;; el2md.el --- Convert commentary section of elisp files to markdown. -*- lexical-binding:t -*-

;; Author: Jade Michael Thornton
;; Version: 1.0.1
;; URL: https://gitlab.com/thornjad/el2md

;;; Commentary:

;; This package converts the _Commentary_ section in an Elisp module to text
;; files in the Markdown language. It supports most of Markdown, including some
;; headings, code blocks, text styles, lists, etc.

;; What is converted:
;;
;; Everything between the `Commentary:' and `Code:' markers are included in the
;; generated text. In addition, the title and _some_ metadata is also included.

;; How to write comments:
;;
;; The general rule of thumb is that the Elisp module should be written
;; using plain text, as they always have been written. However, some things are
;; recognized. A single line ending with a colon is considered a _heading_. If
;; this line is at the start of a comment block, it is considered a main (level
;; 2) heading. Otherwise it is considered a (level 3) subheading. Note that if
;; the line precedes a bullet list or code, it will not be treated as a
;; subheading.
;;
;; Use Markdown formatting:
;;
;; It is possible to use markdown syntax in the text, like _this_, and **this**.
;;
;; Conventions:
;;
;; The following conventions are used when converting Elisp comments to
;; Markdown:
;;
;; * Code blocks using either the Markdown convention by indenting the block
;;   with four extra spaces, or by starting a paragraph with a `('.
;;
;; * In Elisp comments, a reference to `code' (backquote - quote) will be
;;   converted to Markdown (backquote - backquote).
;;
;; * In Elisp comments, bullets in lists are typically separated by empty lines.
;;   In the converted text, the empty lines are removed, as required by
;;   Markdown.
;;

;; Example:
;;
;;
;;     ;; This is a heading:
;;     ;;
;;     ;; Bla bla bla ...
;;
;;     ;; This is another heading:
;;     ;;
;;     ;; This is a paragraph!
;;     ;;
;;     ;; A subheading:
;;     ;;
;;     ;; Another paragraph.
;;     ;;
;;     ;; This line is _not_ as a subheading:
;;     ;;
;;     ;; * A bullet in a list
;;     ;;
;;     ;; * Another bullet.

;; Usage:
;;
;; To generate the markdown representation of the current buffer to a temporary
;; buffer, use:
;;
;;     M-x el2md-view-buffer RET
;;
;; To write the markdown representation of the current buffer to a file, use:
;;
;;     M-x el2md-write-file RET name-of-file RET
;;
;; In sites like GitLab, if a file named readme.md exists in the root directory
;; of an repository, it is displayed when viewing the repository. To generate a
;; readme.md file, in the same directory as the current buffer, use:
;;
;;     M-x el2md-write-readme RET

;; Post processing:
;;
;; To post-process the output, add a function to `el2md-post-convert-hook'. The
;; functions in the hook should accept one argument, the output stream
;; (typically the destination buffer). When the hook is run current buffer is
;; the source buffer.

;; Batch mode:
;;
;; You can run el2md in batch mode. The function `el2md-write-readme' can be
;; called directly using the `-f' option. The others can be accessed with the
;; `--eval' form.
;;
;; For example,
;;
;;     emacs -batch -l el2md.el my-file.el -f el2md-write-readme

;; Known problems:
;;
;; - The end of the _Commentary_ section includes the first comment in the code
;;   if there's no empty line before the _Code_ comment.

;; License:
;;
;; `el2md' was originally forked from `el2markdown' by Anders Lindgren. It has
;; since been improved, but carries the same license as the original work.
;;
;; Copyright (c) 2020 Jade Michael Thornton
;; Copyright (c) 2013 Anders Lindgren
;;
;; This program is free software: you can redistribute it and/or modify it under
;; the terms of the GNU General Public License as published by the Free Software
;; Foundation, version 3. This program is distributed in the hope that it will
;; be useful, but without any warranty; without even the implied warranty of
;; merchantability or fitness for a particular purpose. See the GNU General
;; Public License for more details.

;;; Code:

;; The `{{{' and `}}}' and sequences are used by the package
;; `folding.el'.
(defvar el2md-empty-comment "^;;+ *\\(\\({{{\\|}}}\\).*\\)?$"
  "Regexp of lines that should be considered empty.")

(defvar el2md-translate-keys-within-markdown-quotes nil
  "When non-nil, match key sequences found between backquotes.

By default, this package only converts things quoted using
backquote and quote, which is the standard elisp way to quote
things in comments.")

(defvar el2md-keys '("RET" "TAB")
  "List of keys that sould be translated to <key>...</key>.")

(defvar el2md-post-convert-hook nil
  "Hook that is run after a buffer has been converted to Markdown.

The functions in the hook should accept one argument, the output
stream (typically the destination buffer). When the hook is run
current buffer is the source buffer.")

(defun el2md-convert ()
  "Print comments section of current buffer as Markdown.

After conversion, `el2md-post-convert-hook' is called. The
functions in the hook should accept one argument, the output
stream (typically the destination buffer). When the hook is run
current buffer is the source buffer."
  (save-excursion
    (goto-char (point-min))
    (el2md-convert-title)
    (el2md-convert-formal-information)
    (el2md-skip-to-commentary)
    (while
        (el2md-convert-section))
    (terpri)
    (princ "---")
    (terpri)
    (let ((file-name (buffer-file-name))
          (from ""))
      (if file-name
          (setq from (concat " from `"
                             (file-name-nondirectory file-name)
                             "`")))
      (princ (concat
              "Converted" from
              " by "
              "[*el2md*](https://gitlab.com/thornjad/el2md)."))
      (terpri))
    (run-hook-with-args 'el2md-post-convert-hook standard-output)))

(defun el2md-skip-empty-lines ()
  (while (and (bolp) (eolp) (not (eobp)))
    (forward-line)))

;; Some packages place lincense blocks in the commentary section,
;; ignore them.
(defun el2md-skip-license ()
  "Skip license blocks."
  (when (looking-at  "^;;; License:[ \t]*$")
    (forward-line)
    (while (not (or (eobp)
                    (looking-at "^;;;")))
      (forward-line))))

(defun el2md-translate-string (string)
  (let ((res "")
        (end-quote (if el2md-translate-keys-within-markdown-quotes
                       "[`']"
                     "'")))
    (while (string-match (concat "`\\([^`']*\\)" end-quote) string)
      (setq res (concat res (substring string 0 (match-beginning 0))))
      (let ((content (match-string 1 string))
            (beg "`")
            (end "`"))
        (setq string (substring string (match-end 0)))
        (when (save-match-data
                (let ((case-fold-search nil))
                  (string-match (concat "^\\([SCM]-[^`']+\\|"
                                        (regexp-opt el2md-keys)
                                        "\\)$") content)))
          (setq beg "<kbd>")
          (setq end "</kbd>"))
        (setq res (concat res beg content end))))
    (concat res string)))

(defun el2md-convert-title ()
  (when (looking-at ";;+ \\(.*\\)\\.el --+ \\(.*\\)$")
    (let ((package-name (match-string-no-properties 1))
          (title        (match-string-no-properties 2)))
      (when (string-match " *-\\*-.*-\\*-" title)
        (setq title (replace-match "" nil nil title)))
      (el2md-emit-header 1 (concat package-name " - " title))
      (forward-line))))

(defun el2md-convert-formal-information ()
  (save-excursion
    (goto-char (point-min))
    (let ((limit (save-excursion
                   (re-search-forward "^;;; Commentary:$" nil t))))
      (when limit
        (el2md-convert-formal-information-item "Author")
        (el2md-convert-formal-information-item "Version")
        (el2md-convert-formal-information-item "URL" 'link)
        (terpri)))))

(defun el2md-convert-formal-information-item (item &optional link)
  (when (re-search-forward (concat "^;;+ " item ": *\\(.*\\)") nil t)
    (let ((s (match-string-no-properties 1)))
      (if link
          (setq s (concat "[" s "](" s ")")))
      (princ (concat "*" item ":* " s "<br>"))
      (terpri))))

(defun el2md-skip-to-commentary ()
  (if (re-search-forward ";;; Commentary:$" nil t)
      (forward-line)))

(defun el2md-convert-section ()
  (el2md-skip-empty-lines)
  (el2md-skip-license)
  (if (or (looking-at  "^;;; Code:$")
          (eobp))
      nil
    (let ((p (point)))
      (el2md-emit-rest-of-comment)
      (not (eq p (point))))))

(defun el2md-emit-header (count title)
  (princ (make-string count ?#))
  (princ " ")
  ;; Strip trailing ".".
  (let ((len nil))
    (while (progn
             (setq len (length title))
             (and (not (equal len 0))
                  (eq (elt title (- len 1)) ?.)))
      (setq title (substring title 0 (- len 1)))))
  (princ (el2md-translate-string title))
  (terpri)
  (terpri))

(defun el2md-is-at-bullet-list ()
  "Non-nil when next non-empty comment line is a bullet list."
  (save-excursion
    (while (looking-at "^;;$")
      (forward-line))
    ;; When more then 4 spaces, the line is a code block.
    (looking-at ";;+ \\{0,4\\}[-*]")))

(defun el2md-emit-rest-of-comment ()
  (let ((first t))
    (while (looking-at "^;;")
      ;; Skip empty lines.
      (while (looking-at el2md-empty-comment)
        (forward-line))
      (if (and (looking-at ";;+ \\(.*\\):$")
               (save-excursion
                 (save-match-data
                   (forward-line)
                   (looking-at el2md-empty-comment)))
               ;; When preceding code or bullet list, don't treat as
               ;; sub-header.
               (or first
                   (not (save-excursion
                          (save-match-data
                            (forward-line)
                            (while (looking-at el2md-empty-comment)
                              (forward-line))
                            (or (el2md-is-at-bullet-list)
                                (looking-at ";;+ *(")
                                (looking-at ";;+     ")))))))
          ;; Header
          (progn
            (el2md-emit-header (if first 2 3)
                               (match-string-no-properties 1))
            (forward-line 2))
        ;; Section of text. (Things starting with a parenthesis is
        ;; assumes to be code.)
        (let ((is-code (looking-at ";;+ *("))
              (is-bullet (el2md-is-at-bullet-list)))
          (while (looking-at ";;+ ?\\(.+\\)$")
            (if is-code
                (princ "    "))
            (princ (el2md-translate-string
                    (match-string-no-properties 1)))
            (terpri)
            (forward-line))
          ;; Insert empty line between sections of code (unless
          ;; between bullet lists.)
          (if (and is-bullet
                   (el2md-is-at-bullet-list))
              nil
            (terpri))))
      (setq first nil))))

;;;###autoload
(defun el2md-view-buffer ()
  "Convert comment section to markdown and display in temporary buffer."
  (interactive)
  (with-output-to-temp-buffer "*el2md*"
    (el2md-convert)))

;;;###autoload
(defun el2md-write-file (&optional file-name overwrite-without-confirm)
  "Convert comment section to markdown and write to FILE-NAME."
  (interactive
   (let ((suggested-name (and (buffer-file-name)
                              (concat (file-name-sans-extension
                                       (buffer-file-name))
                                      ".md"))))
     (list (read-file-name "Write markdown file: "
                           default-directory
                           suggested-name
                           nil
                           (file-name-nondirectory suggested-name)))))
  (unless file-name
    (setq file-name (concat (buffer-file-name) ".md")))
  (let ((buffer (current-buffer))
        (orig-buffer-file-coding-system buffer-file-coding-system))
    (with-temp-buffer
      ;; Inherit the file coding from the buffer being converted.
      (setq buffer-file-coding-system orig-buffer-file-coding-system)
      (let ((standard-output (current-buffer)))
        (with-current-buffer buffer
          (el2md-convert))
        ;; Note: Must set `require-final-newline' inside
        ;; `with-temp-buffer', otherwise the value will be overridden by
        ;; the buffers local value.
        (let ((require-final-newline nil))
          (write-file file-name (not overwrite-without-confirm)))))))

;;;###autoload
(defun el2md-write-readme ()
  "Generate readme.md, designed to be used in batch mode."
  (interactive)
  (el2md-write-file "readme.md" noninteractive))

(provide 'el2md)

;;; el2md.el ends here
