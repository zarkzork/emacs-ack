;;
;; M-x ack
;;
;; Command for using ack on current project. Project asumed to be
;; current git repo. Arguments to M-x ack is passed directly to ack.
;;
;;
;; Mit licensed © Vladimir Terekhov

(defconst git-dir ".git")
(defconst ack-buffer-name "*ack*")

;; Customizible variables
(defvar ack-command "ack-grep" 
  "*Ack command name. Defaults to `ack` on mac and `ack-grep` on
   debian and ubuntu distros. Default value `ack-grep`.")

(defvar ack-highlight-in-buffer t
  "*if not nil result will be highlighted with highlight-regexp when
   oppened in buffer")

(defvar ack-search-pattern nil "Pattern that was used on ack command.")
(defvar ack-mode-hook nil)
(defvar ack-mode-map
  (let ((map (make-keymap)))
    (define-key map (kbd "C-o") 'ack-open-file-other-window)
    (define-key map (kbd "RET") 'ack-open-file)
    (define-key map (kbd "C-j") 'ack-open-file)
    map))

(defun ack-open-file-other-window ()
  "When cursor is under ack match opens file on matched line in other window."
  (interactive)
  (let ((file-and-line (ack-get-file-and-line)))
    (find-file-other-window (car file-and-line))
    (goto-line (cadr file-and-line))
    (ack-higlight-result)
    (select-window (previous-window))))

(defun ack-open-file ()
  "When cursor is under ack match opens file on matched line."
  (interactive)
  (let ((file-and-line (ack-get-file-and-line)))
    (find-file (car file-and-line))
    (goto-line (cadr file-and-line))
    (ack-higlight-result)))

(defun ack-get-file-and-line ()
  "returns list of file num and line number on line under point."
  (let ((line (thing-at-point 'line)))
      (string-match "^\\([^:]+\\):\\([0-9]+\\):" line)
      (list (match-string 1 line) ;; file-name
            (string-to-number (match-string 2 line))))) ;; file-number

(defun ack-higlight-result ()
  (if ack-highlight-in-buffer
      (progn
        (hi-lock-mode -1)
        (highlight-regexp ack-search-pattern))))

(defun ack-search-pattern-token (bounds)
  (re-search-forward ack-search-pattern bounds))
        
(defun ack-mode ()
  "Mode for working with ack search results."
  (interactive)
  (kill-all-local-variables)
  (setq major-mode 'ack-mode)
  (setq mode-name "ack") 
  (use-local-map ack-mode-map)
  (setq font-lock-defaults 
        '((("\\(^[/a-zA-Z_.]+/\\)" (0
                                    (prog1 ()
                                      (compose-region (match-beginning 1)
                                                      (match-end 1)
                                                      ?…))

                                    t))
           (".*:[0-9]+:" . font-lock-variable-name-face)
           (ack-search-pattern-token . font-lock-warning-face))
          t)) ;; no default tokens highlighting
  (toggle-read-only t)
  (toggle-truncate-lines t)
  (run-hooks 'ack-mode-hook))

(defun find-git-root-dir (current-dir)
  "Finds directory containing .git in pwd"
  (let (dir) 
    (mapc
     (lambda (item) 
       (when (string= item git-dir) (setq dir current-dir)))
     (directory-files current-dir))
    (cond
     (dir dir)
     ((string= current-dir "/") nil)
     (t (find-git-root-dir (expand-file-name ".." current-dir))))))

(defun ack-buffer ()
  (save-excursion
    (when (get-buffer ack-buffer-name)
      (kill-buffer ack-buffer-name))
    (let ((buffer (get-buffer-create ack-buffer-name)))
      (set-buffer buffer)
      (toggle-read-only -1)
      (delete-region (point-min) (point-max))
      (ack-mode)
      buffer)))

(defun get-query-from-ack-args (ack-arg)
  (string-match 
   "\\('\\([^']+\\)'\\|\"\\([^\"]+\\)\"\\|\\(\\<[^ ]+\\>\\)\\) *$"
   ack-args)
  (or (match-string 2 ack-args)
      (match-string 3 ack-args)
      (match-string 4 ack-args)))

(defun ack (ack-args) 
  "Run ack with args in current git project."
  (interactive "sack ")
  (setq ack-search-pattern (get-query-from-ack-args ack-args))
  (let ((git-root (find-git-root-dir "."))
        (args (list ack-command nil (list ack-buffer-name t) nil ack-args))
        (buffer (ack-buffer)))
    (when git-root (setq args (append args (list git-root))))
    (apply 'call-process-shell-command args)
    (switch-to-buffer buffer)
    (goto-char (point-min))))

(provide 'ack)
