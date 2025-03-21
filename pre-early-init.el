;;; pre-early-init.el --- DESCRIPTION -*- no-byte-compile: t; lexical-binding: t; -*-

;; -----------------------------------------------------------------------------
;; Debug
;; -----------------------------------------------------------------------------
;; During development of the init files, this should aid in debugging the results
(setq debug-on-error t)

;; -----------------------------------------------------------------------------
;; Emacs file clutter
;; -----------------------------------------------------------------------------
;; Reducing clutter in ~/.emacs.d by redirecting files to ~/emacs.d/var/
;; IMPORTANT: This part should be in the pre-early-init.el file
(setq minimal-emacs-var-dir (expand-file-name "var/" minimal-emacs-user-directory))
(setq package-user-dir (expand-file-name "elpa" minimal-emacs-var-dir))
(setq user-emacs-directory minimal-emacs-var-dir)

;; During development of the init files, this should aid in debugging the results
(setq debug-on-error t)

;; By default, minimal-emacs-package-initialize-and-refresh is set to t, which
;; makes minimal-emacs.d call the built-in package manager. Since Elpaca will
;; replace the package manager, there is no need to call it.
(setq minimal-emacs-package-initialize-and-refresh nil)
