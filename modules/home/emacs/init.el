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
  (when (memq window-system '(mac ns x))
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

;;; Language Support

;;;; Nix

(use-package nix-mode
  :mode ("\\.nix\\'" . nix-mode))

;;;; Dhall

(use-package dhall-mode
  :mode ("\\.dhall\\'" . dhall-mode))

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
  :hook (haskell-mode . flycheck-mode)
  :config
  (setq haskell-stylish-on-save t
	haskell-indent-spaces 2
	flycheck-haskell-ghc-checker-executable "hlint"
	flycheck-check-syntax-automatically '(mode-enabled save new-line)))

(use-package lsp-haskell
  :after haskell-mode
  :hook (haskell-mode . lsp)
  :config
  (setq lsp-haskell-server-path "haskell-language-server-wrapper"))

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
  :hook (svelte-mode . lsp)
  :mode ("\\.svelte\\'" . svelte-mode))

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
