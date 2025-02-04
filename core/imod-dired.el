;;; imod-dired.el --- Dired -*- lexical-binding: t -*-

;;; Code:

(require 'wdired)
(require 'im-dired-plus)
(require 'dired-collapse)

(x dired
   "Maybe should add this to .bashrc:
   "
   "  export LC_COLLATE=C
   "
   :bind
   ((dired-mode-map
     ( "6" . dired-up-directory )
     ( "^" . im/dired-up-directory-follow-symlink )
     ( "e" . wdired-change-to-wdired-mode )
     ( "z" . idp/dired-du-size )
     ( "Y" . idp/dired-rsync )
     ( "," . im-dired--toggle-collapse )
     ( "C-c m" . imtt/transient-dired)))
   :config
   (setq wgrep-enable-key "e")
   (setq dired-dwim-target t)

   (require 'ls-lisp)
   (setq dired-listing-switches "-alh"
         ls-lisp-use-insert-directory-program nil
         ls-lisp-dirs-first t
         ls-lisp-use-string-collate nil
         ls-lisp-UCA-like-collation nil
         ls-lisp-use-localized-time-format t
         ls-lisp-format-time-list '("%Y/%m/%d %H:%M" "%Y/%m/%d %H:%M"))
   (defvar ls-lisp-xid-shorten-threshold (if IS-WIN 8)
     "Shorten display the Uid/Gid column, eg, Administrators is toooooo long.")
   (defun:before ls-lisp-format$shorten (_fn file-attr _fs _sw _ti)
     (when ls-lisp-xid-shorten-threshold
       (cl-labels ((norm (file n &optional
                               (threshold ls-lisp-xid-shorten-threshold)
                               (len (- ls-lisp-xid-shorten-threshold 3)))
                     (let ((item (nth n file)))
                       (when (and (stringp item) (> (length item) threshold))
                         (setf (nth n file)
                               (propertize (format "%s~" (upcase (cl-subseq item 0 len)))
                                           'help-echo item))))))
         (norm file-attr 2)
         (norm file-attr 3)))))

(x dired-collapse
   :init
   (defvar ic/dired-collapse-enable t)
   (defun:hook dired-mode-hook/collapse ()
     (dired-collapse-mode (if ic/dired-collapse-enable 1 -1)))
   (defun im-dired--toggle-collapse (&optional arg)
     "Toggle collapse, with `C-u' then futrue will effact future dired buffer."
     (interactive "P")
     (let (current-prefix-arg)
       (call-interactively 'dired-collapse-mode))
     (when arg
       (setq ic/dired-collapse-enable dired-collapse-mode)
       (message "Global dired-collapse mode: %s" ic/dired-collapse-enable))))

(defun im/dired-up-directory-follow-symlink (&optional arg)
  (interactive "P")
  (let ((dir (directory-file-name (dired-current-directory))))
    (if (f-symlink-p dir)
        (cl-letf* (((symbol-function #'dired-current-directory)
                    (lambda (&optional _) (file-truename dir))))
          (dired-up-directory arg))
      (dired-up-directory arg))))



(x ztree
   "Use `ztree-diff' to diff directories."
   :ref "fourier/ztree"
   :defer-config
   (setq ztree-draw-unicode-lines t)
   (setq ztree-diff-additional-options nil) ; '("-w" "-i")
   (add-to-list 'ztree-diff-filter-list "^~"))



(transient-define-prefix imtt/transient-dired ()
  :transient-non-suffix 'transient--do-exit
  [["Dired"
    ("o" (lambda () (!tdesc "o^ovWj " "Open...")) dired-find-file-other-window :format " %d")
    ("D" (lambda () (!tdesc "RCDSHc " "Move/Copy/Del/SLink/HLink/Comp")) dired-do-delete :format " %d")
    ("G" (lambda () (!tdesc "GMOT   " "Chg Group/Mode/Owner/Touch")) dired-do-chgrp :format " %d")
    ("L" (lambda () (!tdesc "LB!&   " "Load/Compile/ShellCmd/AsyncCmd")) dired-do-load :format " %d")
    ]
   ["Mark & Flag"
    ("m " (lambda () (!tdesc "muUt  " "Mark..")) dired-mark :format " %d")
    ("**" (lambda () (!tdesc "* *@/ " "Mark Some")) dired-mark-executables :format " %d")
    ("%m" (lambda () (!tdesc "% mg  " "Mark More")) dired-mark-files-regexp :format " %d")
    ("A"  (lambda () (!tdesc "AQY   " "Find/Replace/RsyncTo")) dired-do-find-regexp :format " %d")
    ("d " (lambda () (!tdesc "d~# kx" "Flag and X")) dired-flag-file-deletion :format " %d")
    ]
   ["View"
    ("g" (lambda () (!tdesc "gl " "Refresh")) revert-buffer :format " %d")
    ""
    ("y" (lambda () (!tdesc "yz " "Filetype/Size")) dired-show-file-type :format " %d")
    ("i" (lambda () (!tdesc "i$ " "Insert/Hide Subdir")) dired-maybe-insert-subdir :format " %d")
    ("," (lambda () (!tdesc ",( " "Toggle Detail/Collapse")) dired-collapse-mode :format " %d")
    ]
   ]
  [["Others"
    ("/ d" "dotnet-cli" sharper-main-transient)
    ]
   ]
  (interactive)
  (if (eq major-mode 'dired-mode)
      (progn
        (transient-setup 'imtt/transient-dired)
        (message "[C-t] for image-display, [:] for epa-actions"))
    (user-error "Should be used in Dired.")))

(transient-define-prefix imtt/transient-dired-sort ()
  [[("n" "By Name" (lambda () (interactive) (dired-quick-sort :name)) :transient t)
    ("t" "By Time" (lambda () (interactive) (dired-quick-sort :time)) :transient t)
    ]
   [("s" "By Size" (lambda () (interactive) (dired-quick-sort :size)) :transient t)
    ("e" "By Ext"  (lambda () (interactive) (dired-quick-sort :ext))  :transient t)
    ]
   [("r" "Revert dired buffer" (lambda () (interactive) (ignore-error (find-alternate-file default-directory))) :transient t)
    ("g"
     (lambda () (format "Group Dirs [%s]" (if (cl-plusp dired-quick-sort-group-dir) "X" " ")))
     (lambda () (interactive) (dired-quick-sort nil (* -1 dired-quick-sort-group-dir)))
     :transient t)
    ]
   ]
  (interactive)
  (if (eq major-mode 'dired-mode)
      (transient-setup 'imtt/transient-dired-sort)
    (user-error "Should be used in Dired.")))

(provide 'imod-dired)

;;; imod-dired.el ends here
