;;; icod-dotnet.el --- .Net -*- lexical-binding: t -*-

;; Plans:
;;
;;  1. omnisharp-emacs (deprecated)
;;  2. LSP/Eglot + omnisharp
;;
;;  yay -S omnisharp-roslyn-bin

;;; Code:

(x csharp-mode
   :ref ("babel: samwdp/ob-csharp"
         "Server: https://github.com/OmniSharp/omnisharp-roslyn/releases")
   :init
   (defun:hook csharp-mode-hook()
     (electric-pair-local-mode 1)
     (local-set-key (kbd "C-c C-c") 'recompile))
   :defer-config
   (setq lsp-csharp-server-path (executable-find "omnisharp"))
   (eglot-set-server csharp-mode "omnisharp" "-lsp"))

(x fsharp-mode
   :defer-config
   (when (executable-find "dotnet")
     (setq inferior-fsharp-program "dotnet fsi --readline-")))

(x sharper
   :commands (sharper-main-transient)
   :ref "sebasmonia/sharper")

(defun im/csharp-repl ()
  "Switch to the CSharpRepl buffer, creating it if necessary."
  (interactive)
  (if-let ((buf (get-buffer "*CSharpRepl*")))
      (pop-to-buffer buf)
    (when-let ((b (make-comint "CSharpRepl" "csharp")))
      (switch-to-buffer-other-window b))))

(transient-define-prefix imtt/transient-csharp-mode ()
  [ ("m" "Csharp Repl" im/csharp-repl) ]
  (interactive)
  (if (eq major-mode 'csharp-mode)
      (transient-setup 'imtt/transient-csharp-mode)
    (user-error "Sorry, but this is not csharp-mode")))

(provide 'icod-dotnet)

;;; icod-dotnet.el ends here
