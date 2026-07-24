;;; Bootstrap

;; Install straight.el
(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el" user-emacs-directory))
      (bootstrap-version 6))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

;; Install use-package
(straight-use-package 'use-package)

;; Configure use-package to use straight.el by default
(use-package straight
  :custom
  (straight-use-package-by-default t))

;;; System Stuff

;; Load ~/.zshrc env variables on MacOS
(use-package exec-path-from-shell
  :ensure t
  :config
  ;; launchd starts the Emacs daemon with a bare PATH (/usr/bin:/bin:...), so it
  ;; can't see Nix-installed LSP servers. `window-system' is nil in a daemon, so
  ;; the old graphical-only guard skipped this and every server went unfound.
  ;; Import the login shell's PATH whenever we're a daemon or a GUI frame.
  (when (or (daemonp) (memq window-system '(mac ns x)))
    (exec-path-from-shell-initialize)))

;;; Emacs Settings

(use-package emacs
  :init
  ;; Open empty file on startup
  (setq initial-scratch-message "")
  (setq inhibit-startup-message t)
  :bind
  ;; Bind redo to M-_
  ("M-_" . 'undo-redo)
  :config
  ;; Hide toolbar
  (tool-bar-mode -1)
  ;; Keep backups, auto-saves, and lock files out of project directories
  (let ((cache (expand-file-name "~/.cache/emacs/")))
    (make-directory (expand-file-name "backups"    cache) t)
    (make-directory (expand-file-name "auto-saves" cache) t)
    (make-directory (expand-file-name "lock"       cache) t)
    (setq backup-directory-alist         `(("." . ,(expand-file-name "backups/" cache)))
          auto-save-file-name-transforms `((".*" ,(expand-file-name "auto-saves/" cache) t))
          lock-file-name-transforms      `((".*" ,(expand-file-name "lock/" cache) t))))
  :custom
  ;; Enable fullscreen mode on macOS
  (ns-use-native-fullscreen nil)
  ;; Use Command as Meta instead of Option on macOS
  (ns-command-modifier 'meta)
  (ns-option-modifier 'none))

;;; UI & Appearance

(use-package dashboard
  :config
  (setq dashboard-items '((recents . 5)))
  (setq dashboard-startupify-list '(dashboard-insert-banner
                                    dashboard-insert-newline
                                    dashboard-insert-items))
  (dashboard-setup-startup-hook))

(use-package mood-line
  :config
  (mood-line-mode))

(use-package spacemacs-theme
  :defer t
  :init (load-theme 'spacemacs-dark t))

;;; Tools

(use-package helm
  :bind (("M-x" . helm-M-x)
         ("C-x b" . helm-mini)
         ("C-x C-f" . helm-find-files))
  :config
  (helm-mode 1))

(use-package ag
  :bind (("C-c s" . ag-project)
         ;; Command+Shift+% (Meta-%) runs a project-wide search
         ("M-%" . ag-project))
  :config
  (setq ag-highlight-search t))

(use-package smartparens
  :ensure smartparens
  :hook (prog-mode rust-mode js2-mode json-mode typescript-mode vue-mode graphql-mode)
  :config
  (require 'smartparens-config))

(use-package corfu
  :hook
  ((prog-mode . corfu-mode)
   (shell-mode . corfu-mode)
   (eshell-mode . corfu-mode))
  :init
  (global-corfu-mode))

;; corfu's popup is a child frame, which emacs-nox (terminal-only) can't draw, so
;; completions would be invisible over emacsclient. corfu-terminal is frame-aware
;; — it renders in the TTY and no-ops in GUI frames — so always enable it.
(use-package corfu-terminal
  :after corfu
  :config
  (corfu-terminal-mode +1))

;; Full git UI. magit is TTY-capable, so magit-status works over emacsclient in
;; the terminal daemon; straight pulls its deps (transient, with-editor, ...).
;; Commit buffers open back in this same Emacs via with-editor, so no EDITOR
;; wiring is needed.
(use-package magit
  :bind ("C-x g" . magit-status)
  :custom
  ;; Refine changed lines to the word, so the diff shows exactly what moved.
  (magit-diff-refine-hunk t)
  :custom-face
  ;; spacemacs-dark doesn't theme magit's added/removed faces, and it flattens
  ;; its 256-color diff backgrounds to gray — so over emacsclient (emacs-nox)
  ;; magit's background-based diffs render colorless. Color the +/- lines by
  ;; foreground instead (the theme's own green/red), the git-diff look that reads
  ;; reliably in a terminal.
  (magit-diff-added             ((t (:foreground "#67b11d"))))
  (magit-diff-added-highlight   ((t (:foreground "#67b11d"))))
  (magit-diff-removed           ((t (:foreground "#f2241f"))))
  (magit-diff-removed-highlight ((t (:foreground "#f2241f")))))

;;; LSP

;; Flycheck backs lsp-mode's in-buffer diagnostics. Global so non-LSP buffers
;; (nix, shell, ...) get linting from whatever checkers are on PATH too.
(use-package flycheck
  :init (global-flycheck-mode))

;; which-key ships with Emacs 30, so use the bundled copy (no straight fetch). It
;; powers the discoverable "C-c l ..." menu that lsp-mode registers below.
(use-package which-key
  :straight nil
  :config (which-key-mode))

(use-package lsp-mode
  :init
  ;; ns-command-modifier is 'meta and there is no super key here, so lsp's default
  ;; "s-l" prefix is unreachable — bind the command menu under Control instead.
  (setq lsp-keymap-prefix "C-c l")
  ;; LSP servers stream large JSON payloads over a pipe; raise the read size and
  ;; GC threshold so they don't stall or thrash.
  (setq gc-cons-threshold (* 100 1024 1024)
        read-process-output-max (* 1024 1024))
  :commands (lsp lsp-deferred)
  :hook (lsp-mode . lsp-enable-which-key-integration)
  :custom
  ;; Hand completion to completion-at-point (corfu), not company — any other
  ;; value targets company and completions never reach corfu.
  (lsp-completion-provider :none)
  (lsp-diagnostics-provider :flycheck)
  (lsp-idle-delay 0.5)
  (lsp-headerline-breadcrumb-enable t))

(use-package lsp-ui
  :after lsp-mode
  :commands lsp-ui-mode
  :custom
  ;; lsp-ui-doc is child-frame based (a no-op under emacs-nox); rely on eldoc in
  ;; the echo area for hover, and keep the TTY-friendly sideline.
  (lsp-ui-doc-enable nil)
  (lsp-ui-sideline-enable t)
  (lsp-ui-sideline-show-diagnostics t)
  (lsp-ui-sideline-show-code-actions t)
  (lsp-ui-sideline-show-hover nil))

;;; Language Support

;;;; Nix

(use-package nix-mode
  :mode ("\\.nix\\'" . nix-mode))

;;;; Dhall

(use-package dhall-mode
  :mode ("\\.dhall\\'" . dhall-mode)
  :hook (dhall-mode . lsp))

;;;; Idris

(use-package idris2-mode
  :straight (idris2-mode
             :host github
             :repo "idris-community/idris2-mode")
  :mode (("\\.idr\\'" . idris2-mode)
	 ("\\.ipkg\\'" . idris2-mode))
  :hook (idris2-mode . lsp))

;;;; Haskell

(use-package haskell-mode
  :mode ("\\.hs\\'" . haskell-mode)
  :custom
  (haskell-indentation-layout-offset 2)
  (haskell-indentation-starter-offset 2))

(use-package lsp-haskell
  ;; `:after haskell-mode' installs the hook as soon as haskell-mode loads; the
  ;; hooked autoload then pulls in lsp-haskell (registering its client) and
  ;; lsp-mode. Don't gate on lsp-mode here — with no eager lsp-mode load, that
  ;; nesting never fires when a .hs buffer is the first LSP file opened.
  :after haskell-mode
  :hook (haskell-mode . lsp-deferred)
  :custom
  (lsp-haskell-server-path "haskell-language-server-wrapper")
  (lsp-haskell-formatting-provider "fourmolu"))

;;;; PureScript

(use-package purescript-mode
  :mode ("\\.purs\\'" . purescript-mode)
  :hook (purescript-mode . lsp))

;;;; Mojo

(use-package mojo
  :straight (:host github :repo "andcarnivorous/mojo-hl")
  :commands (mojo-mode mojo-compile)
  :mode ("\\.mojo\\'" . mojo-mode))

;;;; Python

(use-package python-mode
  :mode ("\\.py\\'" . python-mode)
  :hook (python-mode . lsp))

;;;; C++

(use-package cc-mode
  :ensure nil
  :hook ((c++-mode . lsp)
         (c-mode . lsp))
  :config
  (setq c-basic-offset 4
        tab-width 4
        indent-tabs-mode nil
        c-default-style "bsd")
  ;; Use 'clangd' for LSP
  (with-eval-after-load 'lsp-mode
    (setq lsp-clients-clangd-executable "clangd")))

;;;; CMake

(use-package cmake-mode
  :ensure t
  :mode ("CMakeLists\\.txt\\'" "\\.cmake\\'")
  :hook (cmake-mode . lsp))

;;;; Yacc/Bison

(use-package bison-mode
  :straight (:host github :repo "wilfred/bison-mode")
  :mode (("\\.y\\'" . bison-mode)
         ("\\.yy\\'" . bison-mode)))

;;;; Rust

(use-package rust-mode
  :mode ("\\.rs\\'" . rust-mode)
  :hook (rust-mode . lsp))

;;;; Slint

(use-package slint-mode
  :mode ("\\.slint\\'" . slint-mode)
  :hook (slint-mode . lsp))

;;;; PHP

(use-package php-mode
  :mode ("\\.php\\'" . php-mode)
  :hook (php-mode . lsp))

;;;; JavaScript

(use-package js2-mode
  :mode ("\\.js\\'" . js-mode)
  :mode ("\\.mjs\\'" . js2-mode)
  :hook (js2-mode . lsp)
  :config
  (setq js2-basic-offset 2))

;;;; JSON

(use-package json-mode
  :mode ("\\.json\\'" . json-mode)
  :hook (json-mode . lsp)
  :config
  (setq js-indent-level 2))

;;;; TypeScript

(use-package typescript-mode
  :mode (("\\.ts\\'"  . typescript-mode)
         ("\\.tsx\\'" . typescript-mode)
         ("\\.mts\\'" . typescript-mode)
         ("\\.cts\\'" . typescript-mode))
  :hook (typescript-mode . lsp)
  :config
  (setq typescript-indent-level 2))

;;;; Svelte

(use-package svelte-mode
  :mode ("\\.svelte\\'" . svelte-mode)
  :hook (svelte-mode . lsp)
  :config
  ;; lsp-mode's svelte client defaults to an npm-managed server it installs into
  ;; its own cache. Repoint it at the Nix binary — nixpkgs installs the server as
  ;; `svelteserver', not `svelte-language-server'. Its bundled typescript-svelte
  ;; plugin (on by default) is what makes SvelteKit's cross-file $types resolve.
  (with-eval-after-load 'lsp-svelte
    (lsp-dependency 'svelte-language-server '(:system "svelteserver"))))

;;;; Vue

(use-package vue-mode
  :hook (vue-mode . lsp)
  :mode ("\\.vue\\'" . vue-mode)
  :config
  (setq mmm-submode-decoration-level 0))

;;;; GraphQL

(use-package graphql-mode
  :hook (graphql-mode . lsp)
  :mode ("\\.graphql\\'" . graphql-mode))

;;;; CSV

(use-package csv-mode
  :mode ("\\.csv\\'" . csv-mode))

;;;; YAML

(use-package yaml-mode
  :hook (yaml-mode . lsp)
  :mode (("\\.yml\\'" . yaml-mode)
         ("\\.yaml\\'" . yaml-mode))
  :config
  (setq yaml-indent-offset 2))

;;;; Protobuf

(use-package protobuf-mode
  ; :hook (protobuf-mode . lsp)
  :mode ("\\.proto\\'" . protobuf-mode)
  :config
  (setq c-basic-offset 2))

;;;; Dotenv

(use-package dotenv-mode
  :ensure t
  :mode "\\.env\\(?:\\..*\\)?\\'")
