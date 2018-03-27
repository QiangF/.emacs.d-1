;;; cust.el --- Packages Initialize And Basic Configurations
;;; Commentary:

;;; Code:


;;; Initialization

(defun im/refresh-package (packages-required &optional block)
  (setq package-enable-at-startup nil
        package-user-dir "~/.emacs.d/packages"
        package-archives
        `(("melpa" . ,(if block "http://elpa.emacs-china.org/melpa/"
                        "http://melpa.org/packages/"))
          ("org"   . "http://elpa.emacs-china.org/org/")
          ("gnu"   . "http://elpa.emacs-china.org/gnu/")
          ))
  (package-initialize)
  (unless package-archive-contents (package-refresh-contents))
  (mapc 'package-install (seq-remove 'package-installed-p packages-required)))

(im/refresh-package
 '(use-package
    ;; basic
    bind-key diminish

    ;; looking
    atom-dark-theme rainbow-delimiters beacon page-break-lines ivy-pages rcirc-styles

    ;; edit
    iedit multiple-cursors

    ;; search
    ag wgrep-ag anzu

    ;; utils
    exec-path-from-shell session graphviz-dot-mode magit neotree

    ;; org-mode
    org-download ob-restclient ox-reveal

    ;; fronts
    web-mode emmet-mode yaml-mode sass-mode impatient-mode js2-mode tide htmlize web-beautify

    ;; backends
    slime php-mode intero robe elpy c-eldoc erlang lua-mode go-mode kotlin-mode scala-mode clojure-mode groovy-mode

    ;; lsp
    lsp-mode lsp-ui company-lsp cquery

    ;; projects
    counsel-projectile yasnippet company

    ;; companies
    company-ghc company-php

    ))


;;; Load-Path/Theme-Path

(dolist (dir (directory-files "~/.emacs.d/ext" t))
  (if (and (not (eq (file-name-extension dir) ""))
           (file-directory-p dir))
      (add-to-list 'load-path dir)))

(add-to-list 'custom-theme-load-path "~/.emacs.d/ext/themes")


;;; Basic Variables

(setq default-directory        "~/"
      user-full-name           "imfine"
      user-mail-address        "lorniu@gmail.com"
      custom-file              "~/.emacs.d/core/cust.el"
      eshell-aliases-file      "~/.emacs.d/ass/eshell-alias"
      _CACHE_                  "~/.emacs.d/.cache/"
      bbdb-file                (concat _CACHE_ "_bbdb")
      diary-file               (concat _CACHE_ "_diary")
      bookmark-default-file    (concat _CACHE_ "_bookmark")
      abbrev-file-name         (concat _CACHE_ "_abbrevs")
      recentf-save-file        (concat _CACHE_ "_recentf")
      eshell-directory-name    (concat _CACHE_ "eshell")
      org-publish-timestamp-directory (concat _CACHE_ ".timestamps/")

      auto-save-interval 0
      auto-save-list-file-prefix nil
      backup-directory-alist `((".*" . ,temporary-file-directory))
      auto-save-file-name-transforms `((".*" ,temporary-file-directory t))

      inhibit-startup-message  t
      gnus-inhibit-startup-message t
      track-eol                t
      visible-bell             nil
      ring-bell-function       'ignore

      scroll-step              1
      scroll-margin            0
      hscroll-step             1
      hscroll-margin           1
      scroll-conservatively    101

      resize-mini-windows      t
      enable-recursive-minibuffers t
      column-number-mode       1
      fringes-outside-margins  t

      enable-local-variables   :all
      enable-local-eval        t

      kill-ring-max            200
      select-enable-clipboard  t
      help-window-select       t
      man-notify-method        'pushy
      woman-use-own-frame      nil)

(setq-default tab-width        4
              truncate-lines   t
              indent-tabs-mode nil
              show-trailing-whitespace nil)

(setenv "TZ" "PRC")
(fset 'yes-or-no-p 'y-or-n-p)

(mapc (lambda (x) (put x 'disabled nil))
      '(narrow-to-region narrow-to-page downcase-region upcase-region set-goal-column erase-buffer))


;;; Use-Package

(defvar im/need-idle-loads nil)
(mapc 'require '(use-package diminish bind-key))

(defmacro x (NAME &rest args)
  " e:demand w:wait else:defer v:dim x:disabled "
  (let* ((name-arr (split-string (symbol-name NAME) "/"))
         (name (intern (car name-arr)))
         (flag (cadr name-arr)) x-options)
    (push (if (seq-contains flag ?e) ':demand ':defer) x-options) ;
    (if (seq-contains flag ?x) (push ':disabled x-options))
    (if (seq-contains flag ?v) (push ':diminish x-options))
    `(progn
       ,(if (seq-contains flag ?w) `(add-to-list 'im/need-idle-loads ',name))
       (use-package ,name ,@x-options ,@args))))


;;; Custom-Set

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
(defun package--save-selected-packages (&rest opt) nil)


(provide 'cust)

;;; cust.el ends here
