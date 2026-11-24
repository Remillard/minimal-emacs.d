;;; verilog-mode-config.el --- Verilog/SystemVerilog configuration -*- no-byte-compile: t; lexical-binding: t; -*-

;; Author: Mark Norton
;; URL: https://github.com/remillard/minimal-emacs.d
;; Package-Requires: ((emacs "29.1"))

;;; Commentary:
;; Everything Verilog/SystemVerilog, required from `post-init.el':
;;
;; - verilog-mode (built-in) settings.
;; - verilog-ts-mode (tree-sitter), used in place of verilog-mode when the
;;   systemverilog grammar is installed (see docs/tree-sitter-grammars.md).
;; - verilog-ext features.
;; - Eglot with the Verible language server.  Settings live in files next to
;;   the code, each found by searching upward from the file being edited:
;;     .rules.verible_lint  lint rules (Verible's --rules_config_search)
;;     .verible_format      formatter flags, one per line (passed as --flagfile;
;;                          must not contain --inplace, which the server rejects)
;;     verible.filelist     project file list for cross-file navigation
;; - Eldoc: the full declaration of the symbol at point (prototype, port,
;;   variable, parameter), or of the task/function whose argument list point
;;   is in.  Found through the server's go-to-definition, so it works across
;;   files listed in verible.filelist.  (Verible's own hover only gives
;;   kind/type and does not advertise itself, so it is left off.)
;; - imenu/which-func name always/initial/final blocks by their label.

;;; Code:

(require 'seq)

;;;; Packages

(use-package verilog-mode
  :ensure nil
  :defer t
  :custom
  (verilog-indent-level 4)
  (verilog-indent-level-module 4)
  (verilog-indent-level-declaration 4)
  (verilog-indent-level-behavioral 4)
  (verilog-indent-level-directive 0)
  (verilog-cexp-indent 2)
  (verilog-case-indent 2)
  (verilog-indent-begin-after-if nil)
  (verilog-indent-class-inside-pkg t)
  (verilog-indent-declaration-macros nil)
  (verilog-indent-lists nil)
  (verilog-align-ifelse t)
  (verilog-align-decl-expr-comments t)
  (verilog-align-comment-distance 1)
  (verilog-align-assign-expr t)
  (verilog-highlight-grouping-keywords t)
  (verilog-highlight-modules t)
  (verilog-highlight-includes t)
  (verilog-auto-lineup 'all)
  (verilog-auto-newline nil)
  :config
  ;; Free M-? for the global xref-find-references (verilog-mode binds it to
  ;; completion help); verilog-ts-mode inherits this keymap.
  (keymap-unset verilog-mode-map "M-?" t)
  (setq verilog-align-typedef-regexp
        (concat "\\<" verilog-identifier-re "_\\(t\\)\\>")))

;; Derived from verilog-mode, so AUTOs and verilog-mode-hook (verilog-ext,
;; eglot) still apply.  Indentation uses its own tree-sitter rules, not the
;; verilog-indent-* settings above.
(use-package verilog-ts-mode
  :ensure t
  :defer t
  :custom
  (verilog-ts-indent-level 4)
  ;; imenu grouped by kind: Functions, Tasks, Always, Instances, ...
  (verilog-ts-imenu-style 'tree-group)
  ;; begin/end/this default to font-lock-misc-punctuation-face, which most
  ;; themes leave unstyled; reuse verilog-mode's grouping keyword face.
  :custom-face
  (verilog-ts-font-lock-grouping-keywords-face
   ((t (:inherit verilog-font-lock-grouping-keywords-face))))
  :init
  (when (treesit-language-available-p 'systemverilog)
    (setf (alist-get 'verilog-mode major-mode-remap-alist) 'verilog-ts-mode))
  :config
  (advice-add 'verilog-ts--node-identifier-name :around
              #'my-verilog--node-identifier-name))

;; xref and capf are left to eglot.  imenu is omitted because it would
;; replace verilog-ts-mode's tree-sitter index; block-end-comments and
;; time-stamp because they rewrite the buffer on save.
(use-package verilog-ext
  :ensure t
  :defer t
  :hook (verilog-mode . verilog-ext-mode)
  :init
  (setq verilog-ext-feature-list
        '(beautify
          hierarchy
          navigation
          which-func
          hideshow
          ports
          typedefs))
  :config
  (verilog-ext-mode-setup))

;;;; Eglot / Verible

(defvar eglot-stay-out-of)
(defvar eglot-server-programs)
(declare-function eglot-current-server "eglot")
(declare-function eglot-uri-to-path "eglot")
(declare-function eglot--TextDocumentPositionParams "eglot")
(declare-function jsonrpc-async-request "jsonrpc")

(defun my-verible-ls-contact (&rest _)
  "Return the verible-verilog-ls command line for the current buffer."
  (let ((dir (locate-dominating-file default-directory ".verible_format")))
    `("verible-verilog-ls" "--rules_config_search"
      ,@(when dir
          (list (concat "--flagfile="
                        (expand-file-name ".verible_format" dir)))))))

(defun my-verible-eglot-setup ()
  "Start eglot for a Verilog buffer.
imenu is left to the major mode: Verible's document symbols list only
declarations, while the major mode's index lists blocks."
  (require 'eglot)
  (setq-local eglot-stay-out-of (cons 'imenu eglot-stay-out-of))
  (add-hook 'eldoc-documentation-functions #'my-verilog-eldoc-declaration nil t)
  (eglot-ensure))

(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '((verilog-mode verilog-ts-mode) . my-verible-ls-contact)))

;; verilog-ts-mode derives from verilog-mode, so this covers both.
(add-hook 'verilog-mode-hook #'my-verible-eglot-setup)

;;;; Eldoc: declaration of the symbol at point

(defconst my-verilog--declaration-re
  (regexp-opt '("function_declaration" "task_declaration"
                "function_prototype" "task_prototype"
                "class_constructor_declaration"
                "module_declaration" "interface_declaration"
                "program_declaration" "package_declaration" "class_declaration"
                "data_declaration" "net_declaration" "type_declaration"
                "ansi_port_declaration" "tf_port_item" "struct_union_member"
                "parameter_declaration" "local_parameter_declaration"
                "parameter_port_declaration")
              'symbols)
  "Node types whose text is shown as a declaration.")

(defun my-verilog--eldoc-target ()
  "Return the position to look up for eldoc, or nil.
Inside a task/function call's argument list this is the callee's name, so
its prototype stays visible while typing arguments."
  (when (treesit-parser-list)
    (let* ((node (treesit-node-at (point)))
           (call (treesit-parent-until
                  node (lambda (n) (equal (treesit-node-type n) "tf_call")) t)))
      (cond (call (treesit-node-start call))
            ((equal (treesit-node-type node) "simple_identifier")
             (treesit-node-start node))))))

(defun my-verilog--declaration-text (file line col)
  "Return the declaration text at LINE/COL (0-based) in FILE, or nil."
  (let ((buf (find-buffer-visiting file)))
    (with-temp-buffer
      (if buf
          (insert-buffer-substring-no-properties buf)
        (insert-file-contents file))
      (treesit-parser-create 'systemverilog)
      (goto-char (point-min))
      (forward-line line)
      (forward-char (min col (- (line-end-position) (point))))
      (when-let* ((decl (treesit-parent-until
                         (treesit-node-at (point))
                         (lambda (n) (string-match-p my-verilog--declaration-re
                                                     (treesit-node-type n)))
                         t))
                  (text (treesit-node-text decl t)))
        (when (string-match ";" text)
          (setq text (substring text 0 (match-end 0))))
        (string-trim
         (replace-regexp-in-string
          "[ \t\n]+" " "
          (replace-regexp-in-string "//[^\n]*" "" text)))))))

(defun my-verilog-eldoc-declaration (callback &rest _)
  "Eldoc function showing the declaration of the symbol at point.
Asks the language server for the definition and shows the declaration
there (prototype, port, variable, module header), so it works across
files listed in verible.filelist.  Calls CALLBACK asynchronously."
  (when-let* ((server (eglot-current-server))
              (pos (my-verilog--eldoc-target)))
    (let ((buf (current-buffer)))
      (jsonrpc-async-request
       server :textDocument/definition
       (save-excursion (goto-char pos) (eglot--TextDocumentPositionParams))
       :success-fn
       (lambda (locs)
         (let* ((loc (if (vectorp locs) (and (> (length locs) 0) (aref locs 0)) locs))
                (uri (or (plist-get loc :uri) (plist-get loc :targetUri)))
                (start (plist-get (or (plist-get loc :range)
                                      (plist-get loc :targetSelectionRange))
                                  :start))
                (file (and uri (eglot-uri-to-path uri)))
                (text (and file start (file-readable-p file)
                           (my-verilog--declaration-text
                            file (plist-get start :line)
                            (plist-get start :character)))))
           (when (buffer-live-p buf)
             (with-current-buffer buf
               ;; Show nothing when point is on the declared name itself.
               (funcall callback
                        (unless (and file (buffer-file-name)
                                     (file-equal-p file (buffer-file-name))
                                     (save-excursion
                                       (goto-char pos)
                                       (and (= (1- (line-number-at-pos))
                                               (plist-get start :line))
                                            (= (current-column)
                                               (plist-get start :character)))))
                          text)
                        :thing (and text (thing-at-point 'symbol t))
                        :face 'font-lock-function-name-face)))))
       :error-fn (lambda (&rest _) (funcall callback nil))))
    t))

;;;; imenu / which-func: block labels

(defconst my-verilog--process-path-types
  '("statement" "statement_item" "procedural_timing_control_statement"
    "statement_or_null" "seq_block" "par_block")
  "Node types followed from a process node down to its outer block.")

(defun my-verilog-process-label (node)
  "Return the label of the outer block of process NODE, or nil.
Recognizes `begin : NAME' and `NAME : begin'; labels on nested blocks
\(e.g. inside an if) are ignored."
  (let (label)
    (while (and node (not label))
      (let* ((type (treesit-node-type node))
             (kids (treesit-node-children node t))
             (first (car kids)))
        (setq label
              (cond ((equal type "statement")
                     (treesit-node-text
                      (treesit-node-child-by-field-name node "block_name") t))
                    ((and (member type '("seq_block" "par_block"))
                          (equal (treesit-node-type first) "simple_identifier"))
                     (treesit-node-text first t))))
        ;; Stop at the first block; don't descend into its body.
        (setq node (unless (member type '("seq_block" "par_block"))
                     (seq-find (lambda (k)
                                 (member (treesit-node-type k)
                                         my-verilog--process-path-types))
                               kids)))))
    label))

(defun my-verilog--node-identifier-name (orig node)
  "Prefer a block label for process NODE; otherwise call ORIG.
Advice for `verilog-ts--node-identifier-name', which otherwise names
processes by their first identifier (usually the clock)."
  (or (and node
           (member (treesit-node-type node)
                   '("always_construct" "initial_construct" "final_construct"))
           (my-verilog-process-label node))
      (funcall orig node)))

(provide 'verilog-mode-config)
;;; verilog-mode-config.el ends here
