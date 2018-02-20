(global-set-key "\C-cgo" 'guardian-on)
(global-set-key "\C-cgO" 'guardian-off)

(defun guardian-on ()
 ""
 (interactive)
 (kmax-check-mode 'shell-mode)
 (end-of-buffer)
 (insert "guard_on")
 (comint-send-input))

(defun guardian-off ()
 ""
 (interactive)
 (kmax-check-mode 'shell-mode)
 (end-of-buffer)
 (insert "guard_off")
 (comint-send-input))
