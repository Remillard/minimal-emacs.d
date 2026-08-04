;;; post-init.el --- User Packages -*- no-byte-compile: t; lexical-binding: t; -*-

;; -----------------------------------------------------------------------------
;; Localization Variables
;; -----------------------------------------------------------------------------
;; External file for local settings
(message "---- Localization Variables ----")
(add-to-list 'load-path user-site-lisp-dir)
(add-to-list 'load-path (expand-file-name "sysinfo" user-site-lisp-dir))
(require 'sysinfo)
(require 'local-settings)
(setq user-full-name local-full-name)
(setq user-mail-address local-user-mail-address)
(setq temporary-file-directory local-temp-file-dir)

;; -----------------------------------------------------------------------------
;; Anti custom.el
;; -----------------------------------------------------------------------------
(setq custom-file null-device)

;; -----------------------------------------------------------------------------
;; Compile Angel
;; -----------------------------------------------------------------------------
;; Ensure adding the following compile-angel code at the very beginning
;; of your `~/.emacs.d/post-init.el` file, before all other packages.
(message "---- Compile Angel ----")
(use-package compile-angel
  :ensure t
  :demand t
  :custom
  ;; Set `compile-angel-verbose` to nil to suppress output from compile-angel.
  ;; Drawback: The minibuffer will not display compile-angel's actions.
  (compile-angel-verbose t)

  :config
  ;; The following directive prevents compile-angel from compiling your init
  ;; files. If you choose to remove this push to `compile-angel-excluded-files'
  ;; and compile your pre/post-init files, ensure you understand the
  ;; implications and thoroughly test your code. For example, if you're using
  ;; `use-package', you'll need to explicitly add `(require 'use-package)` at
  ;; the top of your init file.
  (push "/pre-init.el" compile-angel-excluded-files)
  (push "/post-init.el" compile-angel-excluded-files)
  (push "/pre-early-init.el" compile-angel-excluded-files)
  (push "/post-early-init.el" compile-angel-excluded-files)

  ;; A local mode that compiles .el files whenever the user saves them.
  ;; (add-hook 'emacs-lisp-mode-hook #'compile-angel-on-save-local-mode)

  ;; A global mode that compiles .el files before they are loaded.
  (compile-angel-on-load-mode))

;; -----------------------------------------------------------------------------
;; Generalized Settings: Recent Files, History, Revert, Autosave, Misc
;; -----------------------------------------------------------------------------
;; Setting it so it asks before closing because I keep accidentally killing the
;; whole damn thing.
(message "---- General Settings ----")
(setq confirm-kill-emacs 'yes-or-no-p)

;; Auto-revert in Emacs is a feature that automatically updates the
;; contents of a buffer to reflect changes made to the underlying file
;; on disk.
(add-hook 'after-init-hook #'global-auto-revert-mode)

;; recentf is an Emacs package that maintains a list of recently
;; accessed files, making it easier to reopen files you have worked on
;; recently.
(add-hook 'after-init-hook #'(lambda()
                               (let ((inhibit-message t))
                                 (recentf-mode 1))))
(add-hook 'kill-emacs-hook #'recentf-cleanup)
(setq recentf-max-menu-items 25)
(setq recentf-max-saved-items 300)
(add-hook 'after-init-hook #'(lambda()
                               (run-at-time nil (* 5 60) 'recentf-save-list)))

;; savehist is an Emacs feature that preserves the minibuffer history between
;; sessions. It saves the history of inputs in the minibuffer, such as commands,
;; search strings, and other prompts, to a file. This allows users to retain
;; their minibuffer history across Emacs restarts.
(add-hook 'after-init-hook #'savehist-mode)

;; save-place-mode enables Emacs to remember the last location within a file
;; upon reopening. This feature is particularly beneficial for resuming work at
;; the precise point where you previously left off.
(add-hook 'after-init-hook #'save-place-mode)

;; Enable `auto-save-mode' to prevent data loss. Use `recover-file' or
;; `recover-session' to restore unsaved changes.
(setq auto-save-default t)

(setq auto-save-interval 300)  ;; keystrokes between auto-saves
(setq auto-save-timeout 30)    ;; seconds of idle before auto-save

;; Miscellaneous Settings (global variables)
(setq inhibit-startup-screen t                 ;; Just go directly to initial buffer
      column-number-mode t                     ;; Shows row and column on the modeline
      delete-by-moving-to-trash t              ;; Deletes files to OS trash
      display-time-day-and-date t              ;; For display-time-mode, also show the day.
      ring-bell-function 'ignore               ;; No bell
      use-short-answers t                      ;; Permit 'y' or 'n' instead of 'yes' or 'no'
      dired-dwim-target t                      ;; Prefers dired in another window
      help-window-select t                     ;; Auto selects pop up windows.
      read-process-output-max (* 2 1024 1024)) ;; Increase read size for data chunks.

;; Buffer-local defaults
(setq-default indent-tabs-mode nil           ;; Tab inserts spaces instead of tabs
              tab-width 4                    ;; Tab spacing defined to 4 spaces
              fill-column 80)                ;; Autowrap functions to column 80

(put 'downcase-region 'disabled nil) ;; Eliminates irritating warning message
(put 'upcase-region 'disabled nil)   ;; Eliminates irritating warning message
(set-default-coding-systems 'utf-8)

;; Dired Settings - Permits use of 'a' in dired.
(put 'dired-find-alternate-file 'disabled nil)
(setq dired-listing-switches "-aBhl")
(setq ls-lisp-dirs-first t)

;; Unbind suspend-frame command
(global-unset-key (kbd "C-x C-z"))

;; Enabled backups save your changes to a file intermittently
(setq make-backup-files t)
(setq vc-make-backup-files t)
(setq kept-old-versions 10)
(setq kept-new-versions 10)


;; -----------------------------------------------------------------------------
;; Appearance
;; -----------------------------------------------------------------------------
(message "---- Appearance ----")
;;
;; Font(s)  Selection made in local-settings.el
;;
(setq text-scale-mode-step 1.00)
(set-frame-font local-preferred-font-name nil t)

;;
;; Frame position and size
;;
(if local-starting-frame-max
    (add-to-list 'default-frame-alist '(fullscreen . maximized))
  (add-to-list 'default-frame-alist '(left . 150))
  (add-to-list 'default-frame-alist '(top . 50))
  (add-to-list 'default-frame-alist '(height . 35))
  (add-to-list 'default-frame-alist '(width . 132)))

;;
;; Theme.  Several packages are installed.  Local information
;; selects one of the themes.
;;
(use-package ef-themes
  :ensure t
  :demand t)
(use-package vscode-dark-plus-theme
  :ensure t
  :demand t)
(use-package doom-themes
  :ensure t
  :demand t
  :config
  (setq doom-themes-enable-bold t
        doom-themes-enable-italic t)
  (doom-themes-visual-bell-config)
  (doom-themes-org-config))

;; Hooks the load until the entire Elpaca queue is
;; cleared.
(add-hook 'elpaca-after-init-hook #'(lambda()
                                      (load-theme local-preferred-theme :noconfirm)))

;; Doom Modeline
(use-package doom-modeline
  :ensure t
  :demand t
  :init (doom-modeline-mode 1))

;;
;; Line numbers
;;
(add-hook 'conf-mode-hook #'display-line-numbers-mode)
(add-hook 'prog-mode-hook #'display-line-numbers-mode)
(add-hook 'text-mode-hook #'display-line-numbers-mode)
(add-hook 'vhdl-mode-hook #'display-line-numbers-mode)
;; Enable the following if the relative line numbers
;; are desired.
;; (setq-default
;;  display-line-numbers-grow-only t
;;  display-line-numbers-type 'relative
;;  display-line-numbers-width 2)

;; Nerd Icons
(use-package nerd-icons
  :ensure t
  :defer t
  :config
  (add-to-list 'nerd-icons-extension-icon-alist
               '("m" nerd-icons-mdicon "nf-md-alpha_m" :face nerd-icons-red))
  (add-to-list 'nerd-icons-extension-icon-alist
               '("vhd" nerd-icons-octicon "nf-oct-cpu" :face nerd-icons-blue))
  (add-to-list 'nerd-icons-extension-icon-alist
               '("vhdl" nerd-icons-octicon "nf-oct-cpu" :face nerd-icons-blue))
  (add-to-list 'nerd-icons-mode-icon-alist
               '(matlab-mode nerd-icons-mdicon "nf-md-alpha_m" :face nerd-icons-red)))

;; Picking up the font defined from local-settings.
(setopt nerd-icons-font-family local-nerd-icons-font-family)

;; (use-package nerd-icons-dired
;;   :ensure t
;;   :defer t
;;   :hook ((dired-mode . nerd-icons-dired-mode)))

;; Display the time in the modeline
(add-hook 'after-init-hook #'display-time-mode)


;; Ensures buffer names are unique
(use-package uniquify
  :ensure nil
  :defer t
  :custom
  (uniquify-buffer-name-style 'reverse)
  (uniquify-separator "•")
  (uniquify-after-kill-buffer-p t)
  (uniquify-ignore-buffers-re "^\\*"))

;; Dashboard
(use-package dashboard
  :ensure t
  :defer t
  :custom
  (dashboard-projects-backend 'project-el)
  (dashboard-agenda-sort-strategy '(time-up))
  (dashboard-items '((agenda . 5)
                     (bookmarks . 5)
                     (projects . 5)
                     (recents . 5)))
  (dashboard-icon-type 'nerd-icons)
  :config
  ;; initial-buffer-choice references dashboard-buffer-name so stays in :config
  (setq initial-buffer-choice (lambda () (get-buffer-create dashboard-buffer-name))))

(add-hook 'elpaca-after-init-hook #'(lambda()
                                      (dashboard-open)))
;; Redefining the action taken when a project is selected in dashboard.
;; Previously it would do a find file in the project.  However this
;; will simply open dired at the base directory which is a lot more
;; useful to start.  
(eval-after-load "dashboard"
  '(defun dashboard-projects-backend-switch-function ()
     "Return the function to switch to a project.
Custom variable `dashboard-projects-switch-function' variable takes preference
over custom backends."
     (or dashboard-projects-switch-function
         (cl-case dashboard-projects-backend
           (`projectile 'projectile-switch-project-by-name)
           (`project-el
            (lambda (project)
              "This function is used to switch to `PROJECT'."
              (let ((default-directory project))
                (dired default-directory))))
           (t
            (display-warning '(dashboard)
                             "Invalid value for `dashboard-projects-backend'"
                             :error))))))

;; -----------------------------------------------------------------------------
;; Magit
;; -----------------------------------------------------------------------------
(message "---- Magit ----")
;; Forcing transient to be newer due to Magit requirements.
(use-package transient
  :ensure (:host github :repo "magit/transient")
  :demand t)

(use-package magit
  :ensure t
  :after transient
  :bind
  ("C-x g" . magit-status))

(use-package git-gutter
  :ensure t
  :demand t
  :hook (prog-mode text-mode)
  :config
  (setq git-gutter:update-interval 1))

(use-package git-gutter-fringe
  :ensure t
  :demand t
  :config
  (define-fringe-bitmap 'git-gutter-fr:added [224] nil nil '(center repeated))
  (define-fringe-bitmap 'git-gutter-fr:modified [224] nil nil '(center repeated))
  (define-fringe-bitmap 'git-gutter-fr:deleted [128 192 224 240] nil nil '(center repeated)))

(use-package git-modes
  :ensure t
  :defer t)

;; -----------------------------------------------------------------------------
;; Org Mode
;; -----------------------------------------------------------------------------
(message "---- Org Mode ----")
(use-package org
  ;;:ensure (:host "git.savannah.gnu.org" :repo "git/emacs/org-mode")
  :ensure (:host "github.com" :repo "emacs-straight/org-mode")
  :demand t
  :commands (org-mode org-version)
  :bind (("C-c c" . org-capture)
         ("C-c l" . org-store-link)
         ("C-c O" . org-mark-ring-goto)
         :map org-mode-map
         ("C-c <up>" . org-table-insert-row)
         ("C-c <down>" . org-table-insert-hline)
         ("C-c <right>" . org-table-insert-column)
         ("C-C <left>" . org-table-delete-column))
  :mode ("\\.org\\'" . org-mode)
  :custom
  (org-startup-truncated nil)
  (org-startup-indented t)
  (org-startup-with-inline-images t)
  (org-startup-with-latex-preview nil)
  (org-hide-emphasis-markers t)
  (org-hide-leading-stars t)
  (org-adapt-indentation nil)
  (org-edit-src-content-indentation 0)
  (org-image-actual-width '(450))
  (org-fold-catch-invisible-edits 'error)
  (org-fontify-done-headline t)
  (org-fontify-todo-headline t)
  (org-fontify-whole-heading-line t)
  (org-fontify-quote-and-verse-blocks t)
  (org-pretty-entities t)
  (org-use-sub-superscripts "{}")
  (org-id-link-to-org-use-id t)
  (org-default-notes-file local-notes-file)
  (org-capture-bookmark nil)
  (org-log-done 'time)
  :config
  (setq org-agenda-files (list local-notes-file))
  (setq org-capture-templates
        '(("f" "Fleeting note" item
           (file+headline org-default-notes-file "Notes")
           "- %?")
          ("p" "Permanent note" plain
           (file denote-last-path)
           #'denote-org-capture
           :no-save t
           :immediate-finish nil
           :kill-buffer t
           :jump-to-captured t)
          ("t" "New task" entry
           (file+headline org-default-notes-file "Tasks")
           "* TODO %i%?")
          ("a" "Appointment" entry
           (file+headline org-default-notes-file "Appointments")
           "* %i%?"))))

;; TODO Translate original calendar settings from original custom.el.
(setq calendar-week-start-day 1)

(use-package org-appear
  :ensure t
  :defer t
  :after org
  :hook org-mode
  :custom
  (org-appear-autoemphasis t)
  (org-appear-autolinks t)
  (org-appear-autosubmarkers t)
  (org-appear-autoentities nil)
  (org-appear-autokeywords nil)
  (org-appear-inside-latex nil)
  (org-appear-trigger 'always))

(use-package denote
  :ensure t
  :demand t
  :after org
  :bind (("C-c n n" . denote-create-note)
         ("C-c n l" . denote-link)
         ("C-c n d" . denote-date))
  :hook (text-mode . denote-fontify-links-mode-maybe)
  :config
  (setq denote-directory (expand-file-name local-notes-dir))
  (setq denote-known-keywords '("emacs" "python" "vhdl" "verilog" "books" "life" "work" "politics" "warcraft" "WoW"))
  (setq denote-infer-keywords t)
  (setq denote-sort-keywords t)
  (setq denote-file-type nil)
  (setq denote-prompts '(title keywords))
  (setq denote-excluded-directories-regexp nil)
  (setq denote-excluded-keywords-regexp nil)
  (setq denote-date-prompt-use-org-read-date t)
  (setq denote-backlinks-show-context t))

;; -----------------------------------------------------------------------------
;; Completion Packages
;; -----------------------------------------------------------------------------
(message "---- Completion Packages ----")
(use-package corfu
  :ensure t
  :demand t
  :custom
  (corfu-cycle t)                ;; Enable cycling for `corfu-next/previous'
  (corfu-auto t)                 ;; Enable auto completion
  (corfu-separator ?\s)          ;; Orderless field separator
  (corfu-quit-at-boundary nil)   ;; Never quit at completion boundary
  (corfu-quit-no-match t)        ;; Quit when there is no match
  (corfu-preview-current nil)    ;; Disable current candidate preview
  (corfu-preselect 'prompt)      ;; Preselect the prompt
  (corfu-on-exact-match nil)     ;; Configure handling of exact matches
  (corfu-scroll-margin 5)        ;; Use scroll margin
  :config
  (global-corfu-mode))

(use-package cape
  :ensure t
  :defer t
  :commands (cape-dabbrev cape-file cape-elisp-block)
  :bind ("C-c p" . cape-prefix-map)
  :init
  ;; Add to the global default value of `completion-at-point-functions' which is
  ;; used by `completion-at-point'.
  (add-hook 'completion-at-point-functions #'cape-dabbrev)
  (add-hook 'completion-at-point-functions #'cape-file)
  (add-hook 'completion-at-point-functions #'cape-elisp-block)
  (add-hook 'completion-at-point-functions #'cape-history))

(use-package vertico
  ;; (Note: It is recommended to also enable the savehist package.)
  :ensure t
  :defer t
  :hook (elpaca-after-init . vertico-mode)
  :custom
  (vertico-resize t)
  (vertico-cycle t)
  (vertico-sort-function 'vertico-sort-history-alpha))

;; A few more useful configurations for Vertico
;; Emacs built-in settings that complement corfu and vertico
(use-package emacs
  :ensure nil
  :custom
  ;; Enable indentation+completion using the TAB key.
  (tab-always-indent 'complete)
  ;; Emacs 30 and newer: Disable Ispell completion function.
  (text-mode-ispell-word-completion nil)
  ;; Hide commands in M-x which do not apply to the current mode.
  (read-extended-command-predicate #'command-completion-default-include-p)
  ;; Support opening new minibuffers from inside existing minibuffers.
  (enable-recursive-minibuffers t)
  :init
  ;; Add prompt indicator to `completing-read-multiple'.
  ;; We display [CRM<separator>], e.g., [CRM,] if the separator is a comma.
  (defun crm-indicator (args)
    (cons (format "[CRM%s] %s"
                  (replace-regexp-in-string
                   "\\`\\[.*?]\\*\\|\\[.*?]\\*\\'" ""
                   crm-separator)
                  (car args))
          (cdr args)))
  (advice-add #'completing-read-multiple :filter-args #'crm-indicator)
  ;; Do not allow the cursor in the minibuffer prompt
  (setq minibuffer-prompt-properties
        '(read-only t cursor-intangible t face minibuffer-prompt))
  (add-hook 'minibuffer-setup-hook #'cursor-intangible-mode))

;; Turning off fido-vertical mode and icomplete-vertical mode because
;; they interfere with Vertico.
(fido-mode -1)
(fido-vertical-mode -1)
(icomplete-mode -1)
(icomplete-vertical-mode -1)

(use-package orderless
  ;; Vertico leverages Orderless' flexible matching capabilities, allowing users
  ;; to input multiple patterns separated by spaces, which Orderless then
  ;; matches in any order against the candidates.
  :ensure t
  :defer t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles partial-completion)))))

(use-package marginalia
  ;; Marginalia allows Embark to offer you preconfigured actions in more contexts.
  ;; In addition to that, Marginalia also enhances Vertico by adding rich
  ;; annotations to the completion candidates displayed in Vertico's interface.
  :ensure t
  :defer t
  :commands (marginalia-mode marginalia-cycle)
  :hook (after-init . marginalia-mode)
  ;; Bind `marginalia-cycle' locally in the minibuffer.  To make the binding
  ;; available in the *Completions* buffer, add it to the
  ;; `completion-list-mode-map'.
  :bind (:map minibuffer-local-map
              ("M-A" . marginalia-cycle))
  :custom
  (marginalia-max-relative-age 0)
  (marginalia-align 'right))

(use-package embark
  ;; Embark is an Emacs package that acts like a context menu, allowing
  ;; users to perform context-sensitive actions on selected items
  ;; directly from the completion interface.
  :ensure t
  :defer t
  :commands (embark-act
             embark-dwim
             embark-export
             embark-collect
             embark-bindings
             embark-prefix-help-command)
  :bind
  (("C-." . embark-act)         ;; pick some comfortable binding
   ("C-;" . embark-dwim)        ;; good alternative: M-.
   ("C-h B" . embark-bindings)) ;; alternative for `describe-bindings'

  :init
  (setq prefix-help-command #'embark-prefix-help-command)

  :config
  ;; Hide the mode line of the Embark live/completions buffers
  (add-to-list 'display-buffer-alist
               '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
                 nil
                 (window-parameters (mode-line-format . none)))))

(use-package embark-consult
  :ensure t
  :defer t
  :hook
  (embark-collect-mode . consult-preview-at-point-mode))

(use-package consult
  :ensure t
  :defer t
  :bind (;; C-c bindings in `mode-specific-map'
         ("C-c M-x" . consult-mode-command)
         ("C-c h" . consult-history)
         ("C-c k" . consult-kmacro)
         ("C-c m" . consult-man)
         ("C-c i" . consult-info)
         ([remap Info-search] . consult-info)
         ;; C-x bindings in `ctl-x-map'
         ("C-x M-:" . consult-complex-command)
         ("C-x b" . consult-buffer)
         ("C-x 4 b" . consult-buffer-other-window)
         ("C-x 5 b" . consult-buffer-other-frame)
         ("C-x t b" . consult-buffer-other-tab)
         ("C-x r b" . consult-bookmark)
         ("C-x p b" . consult-project-buffer)
         ;; Custom M-# bindings for fast register access
         ("M-#" . consult-register-load)
         ("M-'" . consult-register-store)
         ("C-M-#" . consult-register)
         ;; Other custom bindings
         ("M-y" . consult-yank-pop)
         ;; M-g bindings in `goto-map'
         ("M-g e" . consult-compile-error)
         ("M-g f" . consult-flymake)
         ("M-g g" . consult-goto-line)
         ("M-g M-g" . consult-goto-line)
         ("M-g o" . consult-outline)
         ("M-g m" . consult-mark)
         ("M-g k" . consult-global-mark)
         ("M-g i" . consult-imenu)
         ("M-g I" . consult-imenu-multi)
         ;; M-s bindings in `search-map'
         ("M-s d" . consult-find)
         ("M-s c" . consult-locate)
         ("M-s g" . consult-grep)
         ("M-s G" . consult-git-grep)
         ("M-s r" . consult-ripgrep)
         ("M-s l" . consult-line)
         ("M-s L" . consult-line-multi)
         ("M-s k" . consult-keep-lines)
         ("M-s u" . consult-focus-lines)
         ;; Isearch integration
         ("M-s e" . consult-isearch-history)
         :map isearch-mode-map
         ("M-e" . consult-isearch-history)
         ("M-s e" . consult-isearch-history)
         ("M-s l" . consult-line)
         ("M-s L" . consult-line-multi)
         ;; Minibuffer history
         :map minibuffer-local-map
         ("M-s" . consult-history)
         ("M-r" . consult-history))

  ;; Enable automatic preview at point in the *Completions* buffer.
  :hook (completion-list-mode . consult-preview-at-point-mode)

  :init
  ;; Optionally configure the register formatting. This improves the register
  (setq register-preview-delay 0.5
        register-preview-function #'consult-register-format)

  ;; Optionally tweak the register preview window.
  (advice-add #'register-preview :override #'consult-register-window)

  ;; Use Consult to select xref locations with preview
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref)

  :config
  (consult-customize
   consult-theme :preview-key '(:debounce 0.2 any)
   consult-ripgrep consult-git-grep consult-grep
   consult-bookmark consult-recent-file consult-xref
   consult--source-bookmark consult--source-file-register
   consult--source-recent-file consult--source-project-recent-file
   ;; :preview-key "M-."
   :preview-key '(:debounce 0.4 any))
  (setq consult-narrow-key "<"))

;; -----------------------------------------------------------------------------
;; Editing General
;; -----------------------------------------------------------------------------
(message "---- General Editing ----")
;; MoveText - Permits M-<up>/<down> on lines or regions to easily move... text
(use-package move-text
  :ensure t
  :defer t
  :hook (elpaca-after-init . move-text-default-bindings))

;; Whole Line or Region DWIM
(use-package whole-line-or-region
  :ensure t
  :defer t
  :hook (elpaca-after-init . whole-line-or-region-global-mode))

;; Multiple Cursors
(use-package multiple-cursors
  :ensure t
  :defer t
  :bind (("<C-M-down>" . mc/mark-next-like-this)
         ("<C-M-up>" . mc/mark-previous-like-this)
         ("C-M-<mouse-1>" . mc/add-cursor-on-click)))

;; Snippet of code that links ace-window and dired
;;
;; Source - https://stackoverflow.com/a/47624310
;; Posted by Wolfgang
;; Retrieved 2026-03-25, License - CC BY-SA 3.0
(use-package ace-window
  :ensure t
  :bind (("M-o" . ace-window))
  :config
  (defun find-file-ace-window ()
    "Use ace window to select a window for opening a file from dired."
    (interactive)
    (let ((file (dired-get-file-for-visit)))
      (if (> (length (aw-window-list)) 1)
          (aw-select "" (lambda (window)
                          (aw-switch-to-window window)
                          (find-file file)))
        (find-file-other-window file))))
  (define-key dired-mode-map "o" 'find-file-ace-window))

;;
;; dired subtree
;;
(use-package dired-subtree
  :ensure t
  :config
  (bind-keys :map dired-mode-map
             ("i" . dired-subtree-insert)
             (";" . dired-subtree-remove)))

;; Additional window control
;; Activities for saving window configurations
;; (use-package activities
;;   :init
;;   (activities-mode)
;;   (activities-tabs-mode)
;;   ;; Prevent `edebug' default bindings from interfering.
;;   (setq edebug-inhibit-emacs-lisp-mode-bindings t)
;;
;;   :bind
;;   (("C-x C-a C-n" . activities-new)
;;    ("C-x C-a C-d" . activities-define)
;;    ("C-x C-a C-a" . activities-resume)
;;    ("C-x C-a C-s" . activities-suspend)
;;    ("C-x C-a C-k" . activities-kill)
;;    ("C-x C-a RET" . activities-switch)
;;    ("C-x C-a b" . activities-switch-buffer)
;;    ("C-x C-a g" . activities-revert)
;;    ("C-x C-a l" . activities-list)))

;;(define-key ibuffer-mode-map (kbd "M-o") nil)

;; Adds a function to make C-x 1 enbiggen a window, then
;; use it again to restore the original layout.
(winner-mode +1)

;; (defun toggle-delete-other-windows ()
;;   "Delete other windows in frame if any, or restore previous window config."
;;   (interactive)
;;   (if (and winner-mode
;;            (equal (selected-window) (next-window)))
;;       (winner-undo)
;;     (delete-other-windows)))
;; 
;; (global-set-key (kbd "C-x 1") #'toggle-delete-other-windows)


;; The undo-fu package is a lightweight wrapper around Emacs' built-in undo
;; system, providing more convenient undo/redo functionality.
(use-package undo-fu
  :ensure t
  :defer t
  :commands (undo-fu-only-undo
             undo-fu-only-redo
             undo-fu-only-redo-all
             undo-fu-disable-checkpoint)
  :bind (("C-z"   . undo-fu-only-undo)
         ("C-S-z" . undo-fu-only-redo)))

;; The undo-fu-session package complements undo-fu by enabling the saving
;; and restoration of undo history across Emacs sessions, even after restarting.
(use-package undo-fu-session
  :ensure t
  :defer t
  :commands undo-fu-session-global-mode
  :hook (after-init . undo-fu-session-global-mode))

;; Enables `pixel-scroll-precision-mode' on all operating systems and Emacs
;; versions, except for emacs-mac.
;;
;; Enabling `pixel-scroll-precision-mode' is unnecessary with emacs-mac, as
;; this version of Emacs natively supports smooth scrolling.
;; https://bitbucket.org/mituharu/emacs-mac/commits/65c6c96f27afa446df6f9d8eff63f9cc012cc738
(unless (and (eq window-system 'mac)
             (bound-and-true-p mac-carbon-version-string))
  (setq pixel-scroll-precision-use-momentum nil) ; Precise/smoother scrolling
  (pixel-scroll-precision-mode 1))

;; -----------------------------------------------------------------------------
;; Better Help
;; -----------------------------------------------------------------------------
(use-package helpful
  :ensure t
  :defer t
  :commands (helpful-callable
             helpful-variable
             helpful-key
             helpful-command
             helpful-at-point
             helpful-function)
  :bind
  ([remap describe-command] . helpful-command)
  ([remap describe-function] . helpful-callable)
  ([remap describe-key] . helpful-key)
  ([remap describe-symbol] . helpful-symbol)
  ([remap describe-variable] . helpful-variable)
  :custom
  (helpful-max-buffers 7))

;; Configuring the now built-in which-key
(use-package which-key
  :ensure nil ; builtin
  :defer t
  :commands which-key-mode
  :hook (after-init . which-key-mode)
  :custom
  (which-key-idle-delay 1.5)
  (which-key-idle-secondary-delay 0.25)
  (which-key-add-column-padding 1)
  (which-key-max-description-length 40))

;; -----------------------------------------------------------------------------
;; Programming Packages and Settings
;; -----------------------------------------------------------------------------
(message "---- Programming ----")
;;
;; General
;; This is set in the local settings file.
(setq explicit-shell-file-name local-shell-file-name)

;; Colorizes matching pairs of delimeters
(use-package rainbow-delimiters
  :ensure t
  :defer t
  :commands (rainbow-delimiters-mode)
  :hook (prog-mode))

;; Smart handling of delimeters
(use-package smartparens
  :ensure t
  :defer t
  :hook (prog-mode text-mode markdown-mode)
  :config
  (require 'smartparens-config))

;; Symbol overlay is a package that helps manipulate symbols under the point.
(use-package symbol-overlay
  :ensure t
  :defer t
  :bind (("<f9>"  . symbol-overlay-put)
         ("<f10>" . symbol-overlay-remove-all))
  :hook ((prog-mode . symbol-overlay-mode)))

;; Hexl Inspect is a minor mode to Hexl that provides inspection data at the
;; point
(use-package hexl-inspect
  :ensure (:host github :repo "Remillard/hexl-inspect")
  :defer t
  :hook (hexl-mode . (lambda () (define-key hexl-mode-map (kbd "C-c i") 'hexl-inspect-mode))))

;; Gentle handling of white space, only making sure edited lines are
;; trimmed.
(use-package ws-butler
  :ensure t
  :defer t
  :hook (prog-mode . ws-butler-mode))

;; Indent bars stipple
(use-package indent-bars
  :ensure t
  :defer t
  :hook ((prog-mode) . indent-bars-mode))

;;
;; Emacs Lisp
;;
;; Enables automatic indentation of code while typing
(use-package aggressive-indent
  :ensure t
  :defer t
  :commands aggressive-indent-mode
  :hook
  (emacs-lisp-mode . aggressive-indent-mode))

;; Highlights function and variable definitions in Emacs Lisp mode
(use-package highlight-defined
  :ensure t
  :defer t
  :commands highlight-defined-mode
  :hook (emacs-lisp-mode . highlight-defined-mode))

;; Displays visible indicators for page breaks
(use-package page-break-lines
  :ensure t
  :defer t
  :commands (page-break-lines-mode
             global-page-break-lines-mode)
  :hook
  (emacs-lisp-mode . page-break-lines-mode))

;; Provides functions to find references to functions, macros, variables,
;; special forms, and symbols in Emacs Lisp
(use-package elisp-refs
  :ensure t
  :defer t
  :commands (elisp-refs-function
             elisp-refs-macro
             elisp-refs-variable
             elisp-refs-special
             elisp-refs-symbol))

;; Provides a number of language snippet templates
(add-to-list 'load-path (expand-file-name "yasnippet" user-site-lisp-dir))
(add-to-list 'load-path (expand-file-name "yasnippet-snippets" user-site-lisp-dir))
(require 'yasnippet)
(require 'yasnippet-snippets)
(yas-global-mode 1)
(global-set-key (kbd "C-<tab>") 'yas-expand)

;; Treesitter Programming Language Grammars -- In Windows, these are best
;; downloaded as precompiled libraries and this function
;; my-treesit-update-grammars function will grab the latest binaries and put
;; into var/tree-sitter/. For macOS and Linux, the grammars are built from
;; scratch.
(defun my-treesit-update-grammars ()
  "Download and install the latest Windows tree-sitter grammar DLLs.
Queries GitHub for the latest emacs-tree-sitter/tree-sitter-langs release,
downloads the Windows tar.gz to `temporary-file-directory', extracts via
tar.exe (built-in on Windows 10+), renames each DLL by adding the 'lib'
prefix required by Emacs built-in treesit, copies to var/tree-sitter/,
then cleans up.  Emacs will block during the download (~14 MB)."
  (interactive)
  (unless (eq system-type 'windows-nt)
    (user-error "Windows only — use treesit-install-language-grammar on macOS/Linux"))
  (require 'url)
  (let* ((api-url  "https://api.github.com/repos/emacs-tree-sitter/tree-sitter-langs/releases/latest")
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
            (copy-file file dest t)
            (cl-incf count)))

        ;; Step 5: cleanup
        (delete-file temp-tgz)
        (delete-directory temp-dir t)
        (message "my-treesit-update-grammars: installed %d DLLs from release %s → %s"
                 count tag dest-dir)))))

;; Populate treesit-language-source-alist for M-x treesit-install-language-grammar.
;; Primarily useful on macOS/Linux; Windows uses my-treesit-update-grammars instead.
(when local-treesit-language-source-alist
  (setq treesit-language-source-alist local-treesit-language-source-alist))

;; Remap classic major modes to their tree-sitter variants where Emacs provides
;; a built-in ts-mode.  VHDL and Verilog/SV are intentionally excluded.
(setq major-mode-remap-alist
      '((python-mode     . python-ts-mode)
        (c-mode          . c-ts-mode)
        (c++-mode        . c++-ts-mode)
        (sh-mode         . bash-ts-mode)
        (json-mode       . json-ts-mode)
        (yaml-mode       . yaml-ts-mode)
        (cmake-mode      . cmake-ts-mode)
        (dockerfile-mode . dockerfile-ts-mode)
        (toml-mode       . toml-ts-mode)))

(setq treesit-font-lock-level 4)

;;
;; VHDL
;;
;; Load separate VHDL settings file here as it just gets too much otherwise.
(require 'vhdl-mode-config)

;;
;; Verilog (built-in)
;;
(use-package verilog-mode
  :ensure nil
  :defer nil
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
  (setq verilog-align-typedef-regexp (concat "\\<" verilog-identifier-re "_\\(t\\)\\>")))
;;(setopt verilog-align-typedef-regexp (concat "\\<" verilog-identifier-re "_\\(t\\)\\>"))
;; Additional Verilog/SystemVerilog capabilities
(use-package verilog-ext
  :ensure t
  :defer t
  :hook (verilog-mode . verilog-ext-mode)
  :init
  ;; Can also be set through `M-x RET customize-group RET verilog-ext':
  ;; Comment out/remove the ones you do not need
  (setq verilog-ext-feature-list
        '(beautify
          imenu))
  :config
  (verilog-ext-mode-setup))

;;
;; Tcl
;;
(setq auto-mode-alist
      (append
       ;; Quartus Settings File is type Tcl
       '(("\\.qsf\\'" . tcl-mode)
         ;; Xilinx Constraints File (*.xdc) is type Tcl
         ("\\.xdc\\'" . tcl-mode)
         ;; Riviera-Pro/Modelsim Macro Files are type Tcl
         ("\\.do\\'" . tcl-mode)
         ;; Timing constrains are type Tcl
         ("\\.sdc\\'" . tcl-mode))
       auto-mode-alist))

;;
;; MATLAB
;;
(add-to-list 'load-path (expand-file-name "Emacs-MATLAB-Mode" user-site-lisp-dir))
(load-library "matlab-autoload")

;;
;; Python
;;
(use-package blacken
  :ensure t
  :defer t)

(use-package eglot
  :ensure nil ; built-in
  :defer t
  :commands (eglot
             eglot-ensure
             eglot-rename
             eglot-format-buffer)
  :hook ((python-mode . eglot-ensure))
  :config
  (add-to-list 'eglot-server-programs '(python-mode . ("pylsp")))
  (setq-default eglot-workspace-configuration
                '((:pylsp . (:plugins (:isort (:enabled t)
                                              :autopep8 (:enabled nil)
                                              :yapf (:enabled :json-false)
                                              :pycodestyle (:enabled t)
                                              :pyflakes (:enabled t)
                                              :pydocstyle (:enabled t)
                                              :mccabe (:enabled t)))))))

;;
;; Powershell
;;
(use-package powershell
  :ensure t)

;;
;; Github Enterprise Copilot
;;
;; (add-to-list 'load-path "~/.emacs.d/site-lisp/vscode-cp-proxy/")
;; (use-package gptel
;;   :ensure t
;;   :defer f
;;   :config
;;   (add-hook 'gptel-post-stream-hook 'gptel-auto-scroll)
;;   (add-hook 'gptel-post-response-functions 'gptel-end-of-response)
;;   (setq gptel-default-mode 'markdown-mode)
;;   (require 'vscode-cp-proxy)
;;   (gptel-make-preset 'cs45-fpga-hdl
;;   :description "A preset optimized for FPGA HDL coding tasks."
;;   :backend "gptel-vscode-cp-proxy"
;;   :model 'claude-sonnet-4.5
;;   :system "You are a seasoned professional electrical engineer specializing in FPGA
;; design with HDL languages of VHDL and SystemVerilog, both in the design
;; space and verification space. Provide assistance with a direct, concise,
;; and authoritative voice, however some conversational habits may be
;; acceptable. Produce logical segmentation of your response with headings,
;; steps, and lists where appropriate. You will prioritize signal over
;; style. Each paragraph advances understanding. You will speak as a peer,
;; not an explainer. Responses should be medium depth by default unless
;; otherwise specified (code examples may exceed this limit). You will
;; identify the current state explicitly, and define the target state
;; clearly. Break any solution into discrete, ordered actions, identifying
;; preconditions for each action and defining the effects of each action.
;; You will estimate the cost of action for time, complexity, and risk to
;; each action. Evaluate multiple solution paths and optimize for the
;; lowest cost path that satisfies all preconditions, identifying critical
;; dependencies and bottlenecks. After solving, identify what worked and
;; what didn't, then extract reusable patterns for similar problems.
;; Combine structured logic with adaptive pattern recognition, and show you
;; work. Make reasoning steps explicit. Prefer reversible decisions early,
;; commit decisively later. When stuck, reframe the goal or reassess the
;; state. The primary languages are VHDL and SystemVerilog, however
;; scripting languages such as Tcl, Powershell, Makefiles, elisp and more
;; are well known and understood. Provide concrete, actionable guidance and
;; use examples where helpful. Avoid over-explanation of basics unless
;; explicitly asked for confirmation."
;;   :tools 'nil
;;   :stream t
;;   :temperature 1.0
;;   :max-tokens nil
;;   :use-context 'system
;;   :track-media nil
;;   :include-reasoning t))

;; -----------------------------------------------------------------------------
;; Preferred Keybindings where not specified elsewhere
;; -----------------------------------------------------------------------------
(message "---- Keybindings and Buffers ----")
(global-set-key (kbd "C-x C-r") 'recentf-open-files)
(global-set-key (kbd "C-s") 'isearch-forward-regexp)
(global-set-key (kbd "C-r") 'isearch-backward-regexp)
(global-set-key (kbd "C-M-s") 'isearch-forward-symbol-at-point)
(global-set-key (kbd "<f5>") 'revert-buffer-quick)

;; Unbinding the mouse scroll wheel text adjust.
;; Remember C-x C-M-0 for global text scale adjust!!!
(global-unset-key (kbd "C-<wheel-up>"))
(global-unset-key (kbd "C-<wheel-down>"))

;; I never use the brief list directory and I always mistype for dired
(global-set-key (kbd "C-x C-d") 'dired)

;; There is no keybinding for removing an inserted subdirectory standard. If `i'
;; works for dired-maybe-insert-subdir, then `r' is for `remove'
;; dired-kill-subdir.
(require 'dired)
(define-key dired-mode-map "r" 'dired-kill-subdir)

;; Prefer ibuffer and bufler in general
;; When preferring ibuffer to list-buffers
;;(global-set-key (kbd "C-x C-b") 'ibuffer)
;;Remove the M-o from ibuffer as it interferes with
;;ace-window
;;(define-key ibuffer-mode-map (kbd "M-o") nil)

;; Bufler replacement for buffer management
(use-package bufler
 :ensure t
 :defer nil
 :hook (bufler-list-mode . (lambda () (setq-local font-lock-unfontify-region-function #'ignore)))
 :bind (("C-x C-b" . bufler-list)
        :map bufler-list-mode-map
        ("RET" . bufler-list-buffer-switch-ace-window))
 :config
 (defun bufler-list-buffer-switch-ace-window ()
   "Switch to the Bufler buffer at point using ace-window to select target window.
On a buffer line: if multiple windows exist, invoke ace-window selection;
otherwise fall back to the standard `bufler-list-switch-buffer-action'.
On a group header line: toggle section visibility (fold/unfold)."
   (interactive)
   (require 'ace-window)
   (let* ((section (magit-current-section))
          (value   (oref section value)))
     (if (bufferp value)
         ;; Buffer line: ace-window pick or fallback
         (if (> (length (aw-window-list)) 1)
             (aw-select "" (lambda (window)
                             (aw-switch-to-window window)
                             (switch-to-buffer value)))
           (pop-to-buffer value bufler-list-switch-buffer-action))
       ;; Group header line: toggle fold
       (magit-section-toggle section)))))

;; Shortcuts for dealing with compilation.
(global-set-key (kbd "<f1>") 'next-error)
(defun move-to-compilation-and-kill-buffer ()
  "Move to the Compilation window and kill its buffer.
If the Compilation window does not exist, do nothing.
Moves back to the original window."
  (interactive)
  (let ((compilation-window (get-buffer-window "*compilation*"))
        (original-window (selected-window)))
    (when compilation-window
      (select-window compilation-window)
      (kill-buffer "*compilation*")
      (delete-window compilation-window)
      (select-window original-window))))
(global-set-key (kbd "<f2>") 'move-to-compilation-and-kill-buffer)

;; Shortcut to post-init.el
(defun find-config ()
  "Edit post-init.el"
  (interactive)
  (find-file (expand-file-name "post-init.el" user-emacs-orig-dir)))
(global-set-key (kbd "C-c I") 'find-config)

;; Insert a time stamp in buffers that don't support C-c . like org.
(defun insert-time-stamp ()
  "Insert a timestamp at point, format: Weekday Mon Day YYYY HH:MM:SS."
  (interactive)
  (insert (format-time-string "%a %b %e %Y %H:%M:%S")))
