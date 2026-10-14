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

;; Install use-package and have it use straight.el by default
(straight-use-package 'use-package)

(use-package straight
  :custom
  (straight-use-package-by-default t))

;;; Environment

;; Emacs launched from the Dock gets a bare PATH; import the login shell's so
;; Nix-installed tools such as LSP servers are found.
(use-package exec-path-from-shell
  :config
  (when (or (daemonp) (memq window-system '(mac ns x)))
    (exec-path-from-shell-initialize)))

;;; Emacs Settings

(use-package emacs
  :init
  (setq initial-scratch-message ""
        inhibit-startup-message t)
  :bind ("M-_" . undo-redo)
  :config
  (tool-bar-mode -1)
  ;; Keep backups, auto-saves and lock files out of project directories.
  (let ((cache (expand-file-name "~/.cache/emacs/")))
    (dolist (dir '("backups" "auto-saves" "lock"))
      (make-directory (expand-file-name dir cache) t))
    (setq backup-directory-alist         `(("." . ,(expand-file-name "backups/" cache)))
          auto-save-file-name-transforms `((".*" ,(expand-file-name "auto-saves/" cache) t))
          lock-file-name-transforms      `((".*" ,(expand-file-name "lock/" cache) t))))
  :custom
  ;; Command is Meta; Option is left for typing special characters.
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
         ;; Replaces query-replace with a project-wide search.
         ("M-%" . ag-project))
  :config
  (setq ag-highlight-search t))

(use-package smartparens
  :hook (prog-mode vue-mode)
  :config
  (require 'smartparens-config))

(use-package corfu
  :init
  (global-corfu-mode))

;; corfu's popup is a child frame, which a terminal can't draw.
(use-package corfu-terminal
  :after corfu
  :config
  (corfu-terminal-mode +1))

(use-package magit
  :bind ("C-x g" . magit-status)
  :custom
  (magit-diff-refine-hunk t)
  :custom-face
  ;; spacemacs-dark leaves these colorless in a terminal; color the text instead.
  (magit-diff-added             ((t (:foreground "#67b11d"))))
  (magit-diff-added-highlight   ((t (:foreground "#67b11d"))))
  (magit-diff-removed           ((t (:foreground "#f2241f"))))
  (magit-diff-removed-highlight ((t (:foreground "#f2241f")))))

;;; LSP

;; Global, so non-LSP buffers get whatever checkers are on PATH.
(use-package flycheck
  :init (global-flycheck-mode))

;; Bundled with Emacs 30; powers lsp-mode's "C-c l" menu.
(use-package which-key
  :straight nil
  :config (which-key-mode))

(use-package lsp-mode
  :init
  ;; The default "s-l" prefix is unreachable with Command as Meta.
  (setq lsp-keymap-prefix "C-c l")
  ;; LSP servers send large JSON payloads.
  (setq gc-cons-threshold (* 100 1024 1024)
        read-process-output-max (* 1024 1024))
  :commands (lsp lsp-deferred)
  :hook (lsp-mode . lsp-enable-which-key-integration)
  :custom
  (lsp-completion-provider :none) ; complete via completion-at-point (corfu)
  (lsp-diagnostics-provider :flycheck)
  (lsp-idle-delay 0.5)
  (lsp-headerline-breadcrumb-enable t))

(use-package lsp-ui
  :after lsp-mode
  :commands lsp-ui-mode
  :custom
  ;; The doc popup needs child frames; rely on eldoc and the sideline.
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

;;;; Lean 4

;; `data' holds the Lean input method's abbreviations (\alpha -> α).
;; No :mode needed; the package registers .lean itself.
(use-package lean4-mode
  :straight (lean4-mode
             :host github
             :repo "leanprover-community/lean4-mode"
             :files ("*.el" "data"))
  :commands lean4-mode
  :hook (lean4-mode . lsp))

;; Lean's server sends workspace/inlayHint/refresh, which lsp-mode answers
;; correctly but warns about every time, freezing the frame. Mute that warning.
(defun my/lsp-mute-inlay-hint-refresh-warning (fn message &rest args)
  (unless (string-match-p "workspace/inlayHint/refresh"
                          (apply #'format-message message args))
    (apply fn message args)))

(advice-add 'lsp-warn :around #'my/lsp-mute-inlay-hint-refresh-warning)

;;;; Haskell

(use-package haskell-mode
  :mode ("\\.hs\\'" . haskell-mode)
  :custom
  (haskell-indentation-layout-offset 2)
  (haskell-indentation-starter-offset 2))

;; Loaded after haskell-mode, not lsp-mode, so it also works when a .hs file
;; is the first LSP buffer opened.
(use-package lsp-haskell
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

;; Built-in python.el, not the much heavier python-mode.el package.
(use-package python
  :straight nil
  :mode ("\\.py\\'" . python-mode)
  :hook (python-mode . lsp))

;;;; C / C++

(use-package cc-mode
  :straight nil
  :hook (((c-mode c++-mode) . lsp)
         (c-mode-common . (lambda () (setq indent-tabs-mode nil tab-width 4))))
  :custom
  (c-default-style "bsd")
  (c-basic-offset 4))

;;;; CMake

(use-package cmake-mode
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
  :mode (("\\.js\\'" . js2-mode)
         ("\\.mjs\\'" . js2-mode))
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

;;;; Deno

;; lsp-mode always prefers ts-ls over deno-ls, so restrict buffers in a project
;; with deno.json(c) to deno-ls. Depth -90 runs this before the `lsp' hook.
(defun my/lsp-prefer-deno-in-deno-projects ()
  (when (locate-dominating-file
         default-directory
         (lambda (dir)
           (or (file-exists-p (expand-file-name "deno.json" dir))
               (file-exists-p (expand-file-name "deno.jsonc" dir)))))
    (setq-local lsp-enabled-clients '(deno-ls))))

(dolist (hook '(typescript-mode-hook js-mode-hook js2-mode-hook))
  (add-hook hook #'my/lsp-prefer-deno-in-deno-projects -90))

;;;; Svelte

(use-package svelte-mode
  :mode ("\\.svelte\\'" . svelte-mode)
  :hook (svelte-mode . lsp)
  :config
  ;; Use the Nix-installed server, which nixpkgs names `svelteserver'.
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
  :mode ("\\.proto\\'" . protobuf-mode)
  :hook (protobuf-mode . (lambda () (setq c-basic-offset 2))))

;;;; Dotenv

(use-package dotenv-mode
  :mode "\\.env\\(?:\\..*\\)?\\'")
