﻿;;; imface.el --- Faces And Encoding, ETC.
;;; Commentary:

;;; Code:


;;; Windows

(env-windows

 (defun im/win-font (&optional font-size)
   (interactive (list (string-to-number (read-from-minibuffer "font size: " "1"))))

   (let* ((size (or font-size 14)) (en "Consolas") (zh "微软雅黑 light") (tz "楷体"))

     (set-frame-font (font-spec :name (im/find-ft en) :size size) t)
     (set-fontset-font "fontset-default" 'unicode (font-spec :name (im/find-ft zh)))
     (set-face-attribute 'mode-line nil :height 110)
     (add-to-list 'face-font-rescale-alist '(("Consolas"  1)))
     (create-fontset-from-fontset-spec (format "-*-%s-normal-r-normal-*-%d-*-*-*-c-*-fontset-table,
                                        unicode:-*-%s-normal-r-normal-*-%d-*-*-*-c-*-iso8859-1"
                                               en (pcase font-size (14 13) (30 33) (_ size))
                                               tz (pcase font-size (14 14) (30 35) (_ (* size 1.2)))))))
 (setq default-frame-alist
       '((title . "νερό")
         (top . 30) (left . 640)
         (width . 85) (height . 40)
         ;; (line-spacing . 0.11)
         (tool-bar-lines . 0)
         (scroll-bar . nil)
         (vertical-scroll-bars . nil)
         (cursor-type  . box)
         (cursor-color . "red")
         (alpha . 92)))

 (menu-bar-mode -1)
 (setq mouse-wheel-scroll-amount '(1 ((control) . 5)))
 (global-set-key [C-wheel-up]   'text-scale-increase)
 (global-set-key [C-wheel-down] 'text-scale-decrease))

(env-classroom
 (setf (alist-get 'height default-frame-alist) '35)
 (setf (alist-get 'width default-frame-alist)  '70)
 (setf (alist-get 'left default-frame-alist)   '850)
 (add-hook 'focus-in-hook (lambda () (im/win-font 24))))

(env-out-classroom
 (load-theme 'atom-dark t)
 (add-hook 'focus-in-hook 'im/win-font))


;;; Linux

(env-linux
 (menu-bar-mode 0))

(env-linux-ng
 (load-theme 'origin t)
 (xterm-mouse-mode)
 (global-set-key [mouse-4] (lambdai (scroll-down 1)))
 (global-set-key [mouse-5] (lambdai (scroll-up 1))))

(env-linux-g
 (tool-bar-mode 0)
 (scroll-bar-mode 0)
 (setq mouse-wheel-scroll-amount '(1 ((control) . 5)))
 (set-face-attribute 'default nil :height 110)
 (global-set-key [C-mouse-4] 'text-scale-increase)
 (global-set-key [C-mouse-5] 'text-scale-decrease))


;;; Encoding

(set-locale-environment   "utf-8")
(prefer-coding-system     'gb2312)
(prefer-coding-system     'cp936)
(prefer-coding-system     'utf-16)
(prefer-coding-system     'utf-8-unix)

(env-windows
 (defun im/cp936-encoding ()
   (set-buffer-file-coding-system 'gbk)
   (set-buffer-process-coding-system 'gbk 'gbk))

 (set-language-environment "chinese-gbk")
 (prefer-coding-system 'utf-8)

 (setq file-name-coding-system 'gbk)
 (set-terminal-coding-system 'gbk)
 (modify-coding-system-alist 'process "*" 'gbk)

 (add-hook 'shell-mode-hook 'im/cp936-encoding))


;;; Miscellaneous

(setq sentence-end-double-space nil)
(setq sentence-end "\\([。！？]\\|……\\|[.?!][]\"')}]*\\($\\|[ \t]\\)\\)[ \t\n]*")
(mapc (lambda (c) (modify-syntax-entry c "." (standard-syntax-table)))
      '( ?， ?。 ?！ ?； ?？ ?： ?/ ))


(provide 'imface)

;;; imface.el ends here
