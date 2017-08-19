;;;==============================
;;;   functions
;;;==============================


;;;
;;; i want to sing, i want to fly, some helper macros
;;;
(defmacro aif (test then &optional else)
  (declare (indent defun))
  `(let ((it ,test)) (if it ,then ,else)))

(defmacro awhen (test &rest rest)
  (declare (indent defun))
  `(aif ,test (progn ,@rest)))

(defmacro ilambda (&rest body)
  `(lambda () (interactive) ,@body))

(defmacro add-hook-lambda (hook &rest body)
  (declare (indent defun))
  `(add-hook ',hook (lambda () ,@body)))

(defmacro pm (expr)
  `(pp (macroexpand-1 ',expr)))
;;;
;;; global macros end



;;;
;;; useful functions
;;;
(cl-defun im/el-autocompile (&optional (dir "~/.emacs.d/core/"))
  "compile current to .elc"
  (save-window-excursion
    (when (and (eq major-mode 'emacs-lisp-mode)
               (file-exists-p (concat dir (buffer-name))))
      (byte-compile-file (buffer-file-name)))))


(defun im/view-url-cursor ()
  "Open a new buffer containing the contents of URL."
  (interactive)
  (let* ((default (thing-at-point-url-at-point))
         (url (read-from-minibuffer "URL: " default)))
    (switch-to-buffer (url-retrieve-synchronously url))
    (rename-buffer url t)
    (goto-char (point-min))
    (re-search-forward "^$")
    (delete-region (point-min) (1+ (point)))
    (replace-string "><" ">\n<") (delete-blank-lines)
    (set-auto-mode)))


(defun grep-cursor (word)
  "grep the current word in the files"
  (interactive (list (if (use-region-p)
                         (buffer-substring (region-beginning region-end))
                       (current-word))))
  (if (or (not word) (< (length word) 3))
      (message "word not available")
    (let* ((oldcmd grep-find-command)
           (ext (aif (file-name-extension (buffer-name))
                  (concat "." it) ""))
           (newcmd (format "find . -maxdepth 1 -type f -name '*%s' -exec grep -nH -e '%s' {} + " ext word)))
      (unwind-protect
          (progn
            (grep-apply-setting 'grep-find-command newcmd)
            (call-interactively 'grep-find))
        (grep-apply-setting 'grep-find-command oldcmd)))))


(defun tiny-code (a z)
  "indent codes according mode"
  (interactive "r")
  (cond ((use-region-p) (indent-region a z))
        ((string-match-p ")\\|}" (char-to-string (preceding-char)))
         (let ((point-ori (point)))
           (backward-sexp 1)
           (indent-region (point) point-ori)
           (forward-sexp 1)))
        (t (indent-according-to-mode))))


(defun wy-go-to-char (n char)
  "`f' in vim"
  (interactive "p\ncGo to char:")
  (search-forward (string char) nil nil n)
  (while (char-equal (read-char)
                     char)
    (search-forward (string char) nil nil n))
  (setq unread-command-events (list last-input-event)))


(defun his-match-paren (arg)
  "`%' in vim"
  (interactive "p")
  (let ((prev-char (char-to-string (preceding-char)))
        (next-char (char-to-string (following-char))))
    (cond ((string-match "[[{(]" next-char) (forward-sexp 1))
          ((string-match "[\]})]" prev-char) (backward-sexp 1))
          (t (self-insert-command (or arg 1))))))


(defun im/count-words (beg end)
  "Count Chinese and English words in marked region."
  (interactive "r")
  (let ((cn-word 0)
        (en-word 0)
        (total-word 0)
        (total-byte 0))
    (setq cn-word (count-matches "\\cc" beg end)
          en-word (count-matches "\\w+\\W" beg end)
          total-word (+ cn-word en-word)
          total-byte (+ cn-word (abs (- beg end))))
    (message (format "Count Result: %d words(cn: %d, en: %d), %d bytes."
                     total-word cn-word en-word total-byte))))


(defun ascii-table-show ()
  "Print the ascii table"
  (interactive)
  (with-current-buffer
      (switch-to-buffer "*ASCII table*")
    (setq buffer-read-only nil)
    (erase-buffer)
    (let ((i 0) (tmp 0))
      (insert (propertize
               "                         [ASCII table]\n\n"
               'face font-lock-comment-face))
      (while (< i 32)
        (dolist (tmp (list i (+ 32 i) (+ 64 i) (+ 96 i)))
          (insert (concat
                   (propertize (format "%3d " tmp)
                               'face font-lock-function-name-face)
                   (propertize (format "[%2x]" tmp)
                               'face font-lock-constant-face)
                   " "
                   (propertize (format "%3s" (single-key-description tmp))
                               'face font-lock-string-face)
                   (unless (= tmp (+ 96 i))
                     (propertize "  |  " 'face font-lock-variable-name-face)))))
        (newline)
        (setq i (+ i 1)))
      (goto-char (point-min)))
    (local-set-key "q" 'bury-buffer)
    (local-set-key "Q" 'kill-this-buffer)
    (read-only-mode 1)))


(defun resume-scratch ()
  "this sends you to the *Scratch* buffer"
  (interactive)
  (let ((eme-scratch-buffer (get-buffer-create "*scratch*")))
    (switch-to-buffer eme-scratch-buffer)
    (funcall initial-major-mode)))


(defun im/toggle-dedicated ()
  "whether the current active window is dedicated or not"
  (interactive)
  (face-remap-add-relative
   'mode-line-buffer-id
   (if (let ((window (get-buffer-window (current-buffer))))
         (set-window-dedicated-p
          window 
          (not (window-dedicated-p window))))
       '(:foreground "red")
     '(:foreground "black")))
  (current-buffer))


(defun im/trans-word (word)
  "translate with YouDao online"
  (interactive (list
                (let ((w (if (use-region-p)
                             (buffer-substring-no-properties (region-beginning) (region-end))
                           (current-word))))
                  (if current-prefix-arg
                      (read-string "Word to translate: " w)
                    w))))
  (defvar im/trans-limit 5)
  (message "Translating \"%s\"..." word)
  (if (or (not word) (< (length word) 2)
          (string-match-p "[a-z] +[a-z]+" word))
      (error "Invalid input, long or short?"))
  (let ((link "http://m.youdao.com/dict?le=eng&q=")
        (url-request-extra-headers
         '(("Content-Type" . "text/html;charset=utf-8"))))
    (url-retrieve
     (concat link (url-encode-url word))
     (lambda (status word)
       (if (plist-get status :error)
           (error (plist-get status :error)))
       (let* ((num -1)
              (regstr "<[^>]*>\\(.+?\\)</.+>")
              (pnetic (progn
                        (unless (re-search-forward
                                 "#\\(ce\\)\\|\\(ec\\)\"" nil t)
                          (error "No Such Word Found [%s]" word))
                        (re-search-forward
                         "=\"phonetic\">\\(.+\\)</span>" nil t 2)
                        (string-as-multibyte
                         (or (match-string 1) ""))))
              (pnetic (propertize pnetic 'face 'font-lock-string-face))
              (apoint (re-search-forward "<ul>" nil t))
              (zpoint (re-search-forward "</ul>" nil t))
              (str (propertize word 'face '(:foreground "red")))
              (res (list (concat str " " pnetic))))
         (goto-char apoint)
         (while (and (< (incf num) im/trans-limit)
                     (re-search-forward regstr zpoint t))
           (setq str (string-as-multibyte
                      (or (replace-regexp-in-string
                           "<.+?>" ""
                           (match-string-no-properties 1)) "")))
           (string-match "^\\([a-z.]*\\)\\(.*\\)" str)
           (setq str (concat " "
                             (propertize (match-string 1 str) 'face '(:foreground "blue"))
                             (match-string 2 str)))
           (add-to-list 'res str t))
         (message (mapconcat #'identity res "\n"))
         (kill-buffer)))
     (list word) t t)))


(defun try-expand-slime (old)
  "hippie expand word forslime"
  (when (not old)
    (he-init-string (slime-symbol-start-pos) (slime-symbol-end-pos))
    (setq he-expand-list
          (or (equal he-search-string "")
              (sort (slime-simple-completions he-search-string) #'string-lessp))))
  (if (null he-expand-list)
      (progn (if old (he-reset-string)) ())
    (he-substitute-string (car he-expand-list))
    (setq he-tried-table (cons (car he-expand-list) (cdr he-tried-table)))
    (setq he-expand-list (cdr he-expand-list))
    (message "Slime Expand") t))


(defun im/copy-current-line ()
  "copy-current-line or region"
  (interactive)
  (if (use-region-p)
      (call-interactively 'kill-ring-save)
    (copy-region-as-kill (line-beginning-position) (line-end-position))
    (message "Copied")))


(defun im/copy-lines (&optional d)
  "copy lines down/up, like in eclipse"
  (interactive)
  (if (use-region-p)
      (let ((a (region-beginning))
            (z (region-end)))
        (goto-char a)
        (setq a (line-beginning-position))
        (goto-char z)
        (goto-char (setq z (line-end-position)))
        (kill-ring-save a z)
        (newline)
        (yank)
        (if d (goto-char z)))
    (kill-ring-save (line-beginning-position)
                    (line-end-position))
    (end-of-line)
    (newline)
    (yank)
    (if d (previous-line))))


(defun im/kill-lines ()
  "fast move/del like in eclipse"
  (interactive)
  (if (use-region-p)
      (let ((a (region-beginning))
            (z (region-end)))
        (goto-char a)
        (setq a (line-beginning-position))
        (goto-char z)
        (goto-char (setq z (line-end-position)))
        (kill-region a z))
    (kill-whole-line)))


(defmacro defkey (&rest alists)
  " define a list of keys. Usage: (defkey ( \"key\" 'function mode ) ... )"
  (declare (indent defun))
  (let ((default-mode
          (if (typep (first alists) 'symbol)
              (pop alists)
            '(current-global-map))))
    `(progn ,@(mapcar
               (lambda (x)
                 (let ((key (first x)) (fun (second x)))
                   (list 'define-key
                         (or (third x) default-mode)
                         (if (stringp key) `(kbd ,key) key)
                         (if (typep fun 'symbol) `',fun fun))))
               alists))))


(cl-defun im/find-ft (&rest names)
  "find the proper font in the names"
  (cl-flet ((find--ft (name &optional (filter "8859-1"))
                      (let* ((fs (sort (x-list-fonts name) 'string-greaterp)))
                        (find-if (lambda (f) (string-match-p (format ".*%s.*" filter) f)) fs))))
    (dolist (name names)
      (let ((full-name (find--ft name)))
        (if full-name (return full-name))))))


(defun im/start-server()
  (setq server-auth-dir "~/.emacs.d/.cache/server/")
  (unless (server-running-p)
    (ignore-errors (delete-file (concat server-auth-dir "server")))
    (server-start)))

(defun im/pp (list)
  "loop princ a list"
  (dolist (l list t) (princ l) (terpri)))





(provide 'imutil)

;;; imutil.el ends here
