;;; post-init.el --- User Packages -*- no-byte-compile: t; lexical-binding: t; -*-

;; -----------------------------------------------------------------------------
;; Localization Variables
;; -----------------------------------------------------------------------------
;; External file for local settings
(add-to-list 'load-path "~/.emacs.d/site-lisp/")
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
  ;; These are added because there are several Lisp files in the Emacs
  ;; installation that does not have a compiled version, and compile-angel
  ;; will dutifully try to compile it into the installation location which
  ;; causes permission errors in Windows.
  (push "/subdirs.el" compile-angel-excluded-files)
  (push "/modus-vivendi-theme.el" compile-angel-excluded-files)
  (push "/modus-themes.el" compile-angel-excluded-files)

  ;; A local mode that compiles .el files whenever the user saves them.
  ;; (add-hook 'emacs-lisp-mode-hook #'compile-angel-on-save-local-mode)

  ;; A global mode that compiles .el files before they are loaded.
  (compile-angel-on-load-mode))

;; -----------------------------------------------------------------------------
;; Generalized Settings: Recent Files, History, Revert, Autosave, Misc
;; -----------------------------------------------------------------------------
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
;;(add-hook 'kill-emacs-hook #'recentf-cleanup)
(setq recentf-max-menu-items 25)
(setq recentf-max-saved-items 25)
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

(setq auto-save-interval 300)
(setq auto-save-timeout 30)

;; Miscellaneous Settings
(setq-default
 inhibit-startup-screen t               ;; Just go directly to initial buffer
 column-number-mode t                   ;; Shows row and column on the modeline
 delete-by-moving-to-trash t            ;; Deletes files to OS trash
 indent-tabs-mode nil                   ;; Tab inserts spaces instead of tabs
 display-time-day-and-date t            ;; For display-time-mode, also show the day.
 tab-width 4                            ;; Tab spacing defined to 4 spaces
 ring-bell-function 'ignore             ;; No bell
 use-short-answers t                    ;; Permit 'y' or 'n' instead of 'yes' or 'no'
 fill-column 80                         ;; Autowrap functions to column 80
 dired-dwim-target t                    ;; Prefers dired in another window
 help-window-select t                   ;; I think this auto selects pop up windows.
 read-process-output-max (* 1024 1024)) ;; Increase read size for data chunks.

(put 'downcase-region 'disabled nil) ;; Eliminates irritating warning message
(put 'upcase-region 'disabled nil)   ;; Eliminates irritating warning message
(set-default-coding-systems 'utf-8)

;; Dired Settings - Permits use of 'a' in dired.
(put 'dired-find-alternate-file 'disabled nil)
(setq dired-listing-switches "-aBhl --group-directories-first")

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
(add-hook 'elpaca--post-queues-hook #'(lambda()
                                        (load-theme local-preferred-theme :noconfirm)))

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
  :defer t)
(use-package nerd-icons-dired
  :ensure t
  :defer t
  :hook ((dired-mode . nerd-icons-dired-mode))
  :config
  (add-to-list 'nerd-icons-extension-icon-alist
               '("m" nerd-icons-mdicon "nf-md-alpha_m" :face nerd-icons-red)))

;; Display the time in the modeline
(add-hook 'after-init-hook #'display-time-mode)

;; Track changes in the window configuration allowing undoing actions
;; such as closing windows.
(add-hook 'after-init-hook #'winner-mode)

;; Ensures buffer names are unique
(use-package uniquify
  :ensure nil
  :custom
  (uniquify-buffer-name-style 'reverse)
  (uniquify-separator "•")
  (uniquify-after-kill-buffer-p t)
  (uniquify-ignore-buffers-re "^\\*"))

;; -----------------------------------------------------------------------------
;; Org Mode
;; -----------------------------------------------------------------------------
(use-package org
  :ensure (:host "git.savannah.gnu.org" :repo "git/emacs/org-mode")
  :defer t
  :commands (org-mode org-version)
  :mode
  ("\\.org\\'" . org-mode)
  :custom
  (org-hide-leading-stars t)
  (org-startup-indented t)
  (org-adapt-indentation nil)
  (org-edit-src-content-indentation 0)
  (org-startup-truncated nil)
  (org-fontify-done-headline t)
  (org-fontify-todo-headline t)
  (org-fontify-whole-heading-line t)
  (org-fontify-quote-and-verse-blocks t))

;; -----------------------------------------------------------------------------
;; Code Completion Packages
;; -----------------------------------------------------------------------------
(use-package corfu
  :ensure t
  :defer t
  :commands (corfu-mode global-corfu-mode)
  :hook ((prog-mode . corfu-mode)
         (shell-mode . corfu-mode)
         (eshell-mode . corfu-mode))
  :custom
  ;; Hide commands in M-x which do not apply to the current mode.
  (read-extended-command-predicate #'command-completion-default-include-p)
  ;; Disable Ispell completion function. As an alternative try `cape-dict'.
  (text-mode-ispell-word-completion nil)
  (tab-always-indent 'complete)
  (corfu-cycle t)                ;; Enable cycling for `corfu-next/previous'
  (corfu-auto t)                 ;; Enable auto completion
  (corfu-separator ?\s)          ;; Orderless field separator
  (corfu-quit-at-boundary nil)   ;; Never quit at completion boundary
  (corfu-quit-no-match t)        ;; Never quit, even if there is no match
  (corfu-preview-current nil)    ;; Disable current candidate preview
  (corfu-preselect 'prompt)      ;; Preselect the prompt
  (corfu-on-exact-match nil)     ;; Configure handling of exact matches
  (corfu-scroll-margin 5)        ;; Use scroll margin
  ;; Enable Corfu
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
  :commands vertico-mode
  :hook (after-init . vertico-mode)
  :custom
  (vertico-resize t)
  (vertico-cycle t)
  (vertico-sort-function 'vertico-sort-history-alpha))

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
  :hook
  (embark-collect-mode . consult-preview-at-point-mode))

(use-package consult
  :ensure t
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
;; MoveText - Permits M-<up>/<down> on lines or regions to easily move... text
(use-package move-text
  :ensure t
  :defer t
  :config
  (move-text-default-bindings))

;; Whole Line or Region DWIM
(use-package whole-line-or-region
  :ensure t
  :defer t
  :config
  (whole-line-or-region-global-mode))

(use-package ace-window
  :ensure t
  :defer t
  :bind (("M-o" . ace-window)))

;; The undo-fu package is a lightweight wrapper around Emacs' built-in undo
;; system, providing more convenient undo/redo functionality.
(use-package undo-fu
  :defer t
  :commands (undo-fu-only-undo
             undo-fu-only-redo
             undo-fu-only-redo-all
             undo-fu-disable-checkpoint)
  :config
  (global-unset-key (kbd "C-z"))
  (global-set-key (kbd "C-z") 'undo-fu-only-undo)
  (global-set-key (kbd "C-S-z") 'undo-fu-only-redo))

;; The undo-fu-session package complements undo-fu by enabling the saving
;; and restoration of undo history across Emacs sessions, even after restarting.
(use-package undo-fu-session
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
;; Programming Related Packages
;; -----------------------------------------------------------------------------
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

;; Colorizes matching pairs of delimeters
(use-package rainbow-delimiters
  :ensure t
  :defer t
  :commands (rainbow-delimiters-mode)
  :hook (prog-mode . rainbow-delimiters-mode))

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
  :bind (("<f9>" . symbol-overlay-put))
  :hook ((prog-mode . symbol-overlay-mode)))

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

;; -----------------------------------------------------------------------------
;; Preferred Keybindings
;; -----------------------------------------------------------------------------
(global-set-key (kbd "C-x C-r") 'recentf-open-files)
(global-set-key (kbd "C-s") 'isearch-forward-regexp)
(global-set-key (kbd "C-r") 'isearch-backward-regexp)
(global-set-key (kbd "C-M-s") 'isearch-forward-symbol-at-point)
;; Unbinding the mouse scroll wheel text adjust.
;; Remember C-x C-M-0 for global text scale adjust!!!
(global-unset-key (kbd "C-<wheel-up>"))
(global-unset-key (kbd "C-<wheel-down>"))
;; I never use the brief list directory and I always mistype for dired
(global-set-key (kbd "C-x C-d") 'dired)

