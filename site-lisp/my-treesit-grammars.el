;;; my-treesit-grammars.el --- Tree-sitter grammar management -*- no-byte-compile: t; lexical-binding: t; -*-

;; Author: Mark Norton
;; URL: https://github.com/remillard/minimal-emacs.d
;; Package-Requires: ((emacs "29.1"))

;;; Commentary:
;; Installs tree-sitter grammars into var/tree-sitter/ two ways:
;;
;; - `my-treesit-update-grammars': prebuilt Windows DLLs from
;;   emacs-tree-sitter/tree-sitter-langs.
;; - `my-treesit-build-grammar' / `my-treesit-build-all-grammars': build from
;;   source on any OS for languages in `my-treesit-grammar-recipes' (or any
;;   `treesit-language-source-alist' entry), using the tree-sitter CLI at
;;   `local-tree-sitter-cli'.  Source-built languages are never overwritten by
;;   the prebuilt download.
;;
;; Windows toolchain setup: docs/tree-sitter-grammars.md.
;;
;; Emacs links a tree-sitter runtime with a fixed maximum grammar ABI version
;; (check via (treesit-library-abi-version); Emacs 30.1 => 14).  Swapping the
;; runtime DLL does NOT raise this -- the ceiling is compiled into Emacs.
;; tree-sitter-langs 0.13.x ships ABI-15 grammars, which fail to load on such
;; Emacsen with "version-mismatch 15", hence `my-treesit-langs-release' is
;; pinned to the last ABI<=14 release.  Source builds avoid the problem by
;; regenerating parser.c at the ABI this Emacs supports.

;;; Code:

(require 'treesit)
(require 'cl-lib)
(require 'seq)

;; Defined in pre-early-init.el and by url-http respectively.
(defvar user-emacs-orig-dir)
(defvar url-http-end-of-headers)

(defvar my-treesit-grammar-recipes nil
  "Grammars built from source with `my-treesit-build-grammar'.
Same format as `treesit-language-source-alist':
  (LANG URL [REVISION SOURCE-DIR])
REVISION may be a branch, tag, or commit hash.  SOURCE-DIR defaults to
\"src\" (use e.g. \"typescript/src\" for multi-grammar repositories).
Merged into `treesit-language-source-alist' by
`my-treesit-grammars-register' and skipped by `my-treesit-update-grammars'
so source builds are never overwritten by prebuilt DLLs.")

(defvar my-treesit-langs-release "0.12.329"
  "tree-sitter-langs release tag to install, or nil for the latest.
Pinned because Emacs 30.1 supports grammar ABI <= 14, while
tree-sitter-langs 0.13.x ships ABI-15 grammars that will not load.")

(defun my-treesit-update-grammars ()
  "Download and install Windows tree-sitter grammar DLLs.
Fetches the `my-treesit-langs-release' release of
emacs-tree-sitter/tree-sitter-langs (or the latest when that variable is
nil), downloads the Windows tar.gz to `temporary-file-directory', extracts
via tar.exe (built-in on Windows 10+), renames each DLL by adding the \"lib\"
prefix required by Emacs built-in treesit, copies to var/tree-sitter/,
then cleans up.  Emacs will block during the download (~14 MB)."
  (interactive)
  (unless (eq system-type 'windows-nt)
    (user-error "Windows only — use treesit-install-language-grammar on macOS/Linux"))
  (require 'url)
  (let* ((api-url  (if my-treesit-langs-release
                       (format "https://api.github.com/repos/emacs-tree-sitter/tree-sitter-langs/releases/tags/%s"
                               my-treesit-langs-release)
                     "https://api.github.com/repos/emacs-tree-sitter/tree-sitter-langs/releases/latest"))
         (dest-dir (expand-file-name "var/tree-sitter/" user-emacs-orig-dir))
         (temp-tgz (expand-file-name "ts-grammars-windows.tar.gz" temporary-file-directory))
         (temp-dir (expand-file-name "ts-grammars-extract" temporary-file-directory)))

    ;; Step 1: fetch release metadata
    (message "my-treesit-update-grammars: querying GitHub API...")
    (let* ((buf   (url-retrieve-synchronously api-url t nil 15))
           (json  (with-current-buffer buf
                    (goto-char url-http-end-of-headers)
                    (json-parse-buffer :object-type 'alist :array-type 'list)))
           (_     (kill-buffer buf))
           (tag   (cdr (assq 'tag_name json)))
           (asset (seq-find (lambda (a)
                              (string-match-p "tree-sitter-grammars-windows"
                                              (cdr (assq 'name a))))
                            (cdr (assq 'assets json))))
           (url   (cdr (assq 'browser_download_url asset))))
      (unless url
        (error "Cannot find Windows grammar archive in release %s" tag))

      ;; Step 2: download
      (message "my-treesit-update-grammars: downloading release %s (~14 MB)..." tag)
      (url-copy-file url temp-tgz t)

      ;; Step 3: extract (tar.exe is built-in on Windows 10+)
      (when (file-directory-p temp-dir)
        (delete-directory temp-dir t))
      (make-directory temp-dir t)
      (message "my-treesit-update-grammars: extracting...")
      (unless (zerop (call-process "tar" nil nil nil
                                   "-xzf" (expand-file-name temp-tgz)
                                   "-C"   (expand-file-name temp-dir)))
        (delete-file temp-tgz)
        (error "tar extraction failed; is tar.exe on PATH?"))

      ;; Step 4: copy with canonical rename to libtree-sitter-LANG.dll
      ;; Source files are named LANG.dll (bare language name).
      ;; Built-in treesit requires: libtree-sitter-LANG.dll.
      ;; Normalize defensively: strip any existing tree-sitter- or
      ;; libtree-sitter- prefix so the result is always correct.
      ;; Languages in `my-treesit-grammar-recipes' are built from source and
      ;; must not be clobbered.
      (unless (file-directory-p dest-dir)
        (make-directory dest-dir t))
      (let ((count 0))
        (dolist (file (directory-files-recursively temp-dir "\\.dll\\'"))
          (let* ((base      (file-name-nondirectory file))
                 (stem      (file-name-sans-extension base))
                 (lang      (cond
                             ((string-prefix-p "libtree-sitter-" stem)
                              (substring stem (length "libtree-sitter-")))
                             ((string-prefix-p "tree-sitter-" stem)
                              (substring stem (length "tree-sitter-")))
                             (t stem)))
                 (dest-base (format "libtree-sitter-%s.dll" lang))
                 (dest      (expand-file-name dest-base dest-dir)))
            (unless (assq (intern lang) my-treesit-grammar-recipes)
              (copy-file file dest t)
              (cl-incf count))))

        ;; Step 5: cleanup
        (delete-file temp-tgz)
        (delete-directory temp-dir t)
        (message "my-treesit-update-grammars: installed %d DLLs from release %s → %s"
                 count tag dest-dir)))))

;; Building grammars from source (any OS).  Pipeline per language:
;;   1. git clone (shallow unless REVISION is a commit hash)
;;   2. If src/parser.c is missing or its ABI exceeds what this Emacs can load,
;;      regenerate it with `tree-sitter generate --abi N' (needs Node; runs
;;      `npm install' first when grammar.js requires other grammars).
;;   3. `tree-sitter build' compiles parser.c + scanner.c into a shared
;;      library; on Windows the CLI locates MSVC itself, no vcvars needed.
;;   4. Install as libtree-sitter-LANG.<suffix> into var/tree-sitter/.
;; Runs asynchronously; progress is logged to `my-treesit-build-buffer'.
;; The CLI path comes from `local-tree-sitter-cli' (local-settings.el).

(defvar my-treesit-build-buffer "*treesit-build*"
  "Buffer logging `my-treesit-build-grammar' output.")

(defun my-treesit--cli ()
  "Return the absolute path of the tree-sitter CLI, or nil."
  (let ((cli (or (bound-and-true-p local-tree-sitter-cli)
                 (executable-find "tree-sitter"))))
    (when cli
      (setq cli (expand-file-name cli))
      (and (file-executable-p cli) cli))))

(defun my-treesit--log (fmt &rest args)
  "Append FMT formatted with ARGS to the build log buffer."
  (with-current-buffer (get-buffer-create my-treesit-build-buffer)
    (goto-char (point-max))
    (insert (apply #'format fmt args) "\n")))

(defun my-treesit--run (dir command on-success on-failure)
  "Run COMMAND (a list) asynchronously in DIR, logging output.
Call ON-SUCCESS with no arguments on exit status 0, otherwise ON-FAILURE
with an error string."
  (let ((default-directory (file-name-as-directory dir)))
    (my-treesit--log "$ %s" (mapconcat #'identity command " "))
    (make-process
     :name "treesit-build"
     :buffer (get-buffer-create my-treesit-build-buffer)
     :command command
     :connection-type 'pipe
     :sentinel (lambda (proc _event)
                 (when (memq (process-status proc) '(exit signal))
                   (if (zerop (process-exit-status proc))
                       (funcall on-success)
                     (funcall on-failure
                              (format "`%s' exited with status %d"
                                      (car command)
                                      (process-exit-status proc)))))))))

(defun my-treesit--chain (dir steps on-success on-failure)
  "Run STEPS sequentially in DIR, stopping at the first failure.
Each step is either a command list or a function of no arguments that
returns a command list (or nil to skip the step).  A command list of the
form (:in SUBDIR . COMMAND) runs COMMAND in SUBDIR instead of DIR."
  (if (null steps)
      (funcall on-success)
    (let ((cmd (condition-case err
                   (let ((step (car steps)))
                     (list :ok (if (functionp step) (funcall step) step)))
                 (error (list :error (error-message-string err))))))
      (pcase cmd
        (`(:error ,msg) (funcall on-failure msg))
        (`(:ok nil)
         (my-treesit--chain dir (cdr steps) on-success on-failure))
        (`(:ok (:in ,subdir . ,command))
         (my-treesit--run subdir command
                          (lambda ()
                            (my-treesit--chain dir (cdr steps)
                                               on-success on-failure))
                          on-failure))
        (`(:ok ,command)
         (my-treesit--run dir command
                          (lambda ()
                            (my-treesit--chain dir (cdr steps)
                                               on-success on-failure))
                          on-failure))))))

(defun my-treesit--parser-abi (src-dir)
  "Return the LANGUAGE_VERSION of SRC-DIR/parser.c, or nil if absent."
  (let ((parser (expand-file-name "parser.c" src-dir)))
    (when (file-exists-p parser)
      (with-temp-buffer
        (insert-file-contents parser nil 0 8192)
        (when (re-search-forward
               "^#define LANGUAGE_VERSION \\([0-9]+\\)" nil t)
          (string-to-number (match-string 1)))))))

(defun my-treesit--needs-npm-p (grammar-dir)
  "Return non-nil if GRAMMAR-DIR/grammar.js requires another grammar package."
  (let ((grammar-js (expand-file-name "grammar.js" grammar-dir)))
    (and (file-exists-p grammar-js)
         (with-temp-buffer
           (insert-file-contents grammar-js)
           (re-search-forward
            "require\\s-*(\\s-*['\"]tree-sitter-" nil t)))))

(defun my-treesit--build (lang done)
  "Build grammar LANG from its `treesit-language-source-alist' recipe.
Call DONE with nil on success or an error string on failure."
  (let* ((recipe  (or (alist-get lang treesit-language-source-alist)
                      (error "No recipe for %s in treesit-language-source-alist"
                             lang)))
         (url     (nth 0 recipe))
         (rev     (nth 1 recipe))
         (src-rel (or (nth 2 recipe) "src"))
         (cli     (my-treesit--cli))
         (max-abi (treesit-library-abi-version))
         (work    (make-temp-file (format "ts-build-%s-" lang) t))
         (repo    (expand-file-name "repo" work))
         (src-dir (expand-file-name src-rel repo))
         (gdir    (file-name-directory (directory-file-name src-dir)))
         (lib     (format "libtree-sitter-%s%s" lang
                          (car dynamic-library-suffixes)))
         (built   (expand-file-name lib work))
         (dest    (expand-file-name
                   lib (expand-file-name "var/tree-sitter/" user-emacs-orig-dir)))
         (sha-p   (and rev (string-match-p "\\`[0-9a-f]\\{7,40\\}\\'" rev)))
         (fail    (lambda (msg)
                    (my-treesit--log "FAILED %s: %s (work dir kept: %s)"
                                     lang msg work)
                    (funcall done msg))))
    (my-treesit--log "\n==== Building %s from %s%s ====" lang url
                     (if rev (format " @ %s" rev) ""))
    (my-treesit--chain
     work
     (list
      ;; 1. Clone
      (cond (sha-p (list "git" "clone" "--quiet" url repo))
            (rev   (list "git" "clone" "--quiet" "--depth" "1"
                         "--branch" rev url repo))
            (t     (list "git" "clone" "--quiet" "--depth" "1" url repo)))
      (lambda ()
        (when sha-p
          (list "git" "-C" repo "checkout" "--quiet" rev)))
      ;; 2. npm dependencies, only when regeneration will be required
      (lambda ()
        (let ((abi (my-treesit--parser-abi src-dir)))
          (when (and (or (null abi) (> abi max-abi))
                     (my-treesit--needs-npm-p gdir))
            (let ((npm (or (executable-find "npm")
                           (error "npm not found; required to regenerate %s"
                                  lang))))
              (list :in (or (locate-dominating-file gdir "package.json") gdir)
                    npm "install" "--ignore-scripts" "--no-audit" "--no-fund")))))
      ;; 3. Regenerate parser.c at a loadable ABI
      (lambda ()
        (let ((abi (my-treesit--parser-abi src-dir)))
          (my-treesit--log "parser.c ABI: %s, Emacs max ABI: %d"
                           (or abi "absent") max-abi)
          (when (or (null abi) (> abi max-abi))
            (unless (executable-find "node")
              (error "Node.js not found; required to regenerate %s" lang))
            (list :in gdir cli "generate" "--abi" (number-to-string max-abi)))))
      ;; 4. Compile
      (lambda ()
        (let ((abi (my-treesit--parser-abi src-dir)))
          (unless (and abi (<= abi max-abi))
            (error "parser.c ABI %s still exceeds %d after generate"
                   abi max-abi)))
        (list :in gdir cli "build" "--output" built)))
     ;; 5. Install
     (lambda ()
       (condition-case err
           (progn
             (make-directory (file-name-directory dest) t)
             (copy-file built dest t)
             (delete-directory work t)
             (my-treesit--log "Installed %s" dest)
             (funcall done nil))
         (file-error
          (funcall fail
                   (format "%s (if %s is already loaded, restart Emacs and rebuild)"
                           (error-message-string err) lang)))))
     fail)))

(defun my-treesit-build-grammar (lang)
  "Build tree-sitter grammar LANG from source and install it.
LANG's recipe comes from `treesit-language-source-alist'.  Uses the
tree-sitter CLI (`local-tree-sitter-cli') to regenerate the parser when
its ABI is too new for this Emacs and to compile it.  Without the CLI,
falls back to `treesit-install-language-grammar' (non-Windows only)."
  (interactive
   (list (intern
          (completing-read
           "Build grammar: "
           (mapcar (lambda (r) (symbol-name (car r)))
                   treesit-language-source-alist)
           nil t nil nil
           (when my-treesit-grammar-recipes
             (symbol-name (caar my-treesit-grammar-recipes)))))))
  (cond
   ((my-treesit--cli)
    (display-buffer (get-buffer-create my-treesit-build-buffer))
    (my-treesit--build
     lang
     (lambda (err)
       (if err
           (message "my-treesit-build-grammar: %s failed: %s" lang err)
         (message "my-treesit-build-grammar: %s installed%s" lang
                  (if (treesit-language-available-p lang)
                      " (restart Emacs if it was already loaded)"
                    ""))))))
   ((eq system-type 'windows-nt)
    (user-error "tree-sitter CLI not found; set `local-tree-sitter-cli'"))
   (t (treesit-install-language-grammar lang))))

(defun my-treesit-build-all-grammars ()
  "Build every grammar in `my-treesit-grammar-recipes', one after another."
  (interactive)
  (unless (my-treesit--cli)
    (user-error "tree-sitter CLI not found; set `local-tree-sitter-cli'"))
  (display-buffer (get-buffer-create my-treesit-build-buffer))
  (let ((failed nil))
    (cl-labels ((next (langs)
                  (if (null langs)
                      (message "my-treesit-build-all-grammars: done%s"
                               (if failed
                                   (format ", FAILED: %s"
                                           (mapconcat #'symbol-name
                                                      (nreverse failed) " "))
                                 ""))
                    (my-treesit--build
                     (car langs)
                     (lambda (err)
                       (when err (push (car langs) failed))
                       (next (cdr langs)))))))
      (next (mapcar #'car my-treesit-grammar-recipes)))))

(defun my-treesit-grammars-register ()
  "Merge grammar recipes into `treesit-language-source-alist'.
Machine-local `local-treesit-language-source-alist' entries come first;
`my-treesit-grammar-recipes' entries are added for any language not
already defined."
  (when (bound-and-true-p local-treesit-language-source-alist)
    (setq treesit-language-source-alist local-treesit-language-source-alist))
  (dolist (recipe my-treesit-grammar-recipes)
    (unless (assq (car recipe) treesit-language-source-alist)
      (push recipe treesit-language-source-alist))))

(provide 'my-treesit-grammars)

;;; my-treesit-grammars.el ends here
