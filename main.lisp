#!/usr/bin/sbcl --script
(require "asdf")

(defvar *help-string*
  "rmbin <filepath> - remove a file~%rmbin --restore <filename> - restore a file~%rmbin --clean - clean all deleted files~%rmbin --list - list all deleted files~%")


(defun get-argv ()
  "Return a list of command line arguments."
  (or
   #+CLISP *args*
   #+SBCL (cdr *posix-argv*)
   #+LISPWORKS system:*line-arguments-list*
   #+CMU extensions:*command-line-words*
   nil))

(defun get-cmd-output (cmd)
  "Returns output of shell command as a string."
  (let ((fstr (make-array '(0) :element-type 'base-char
                               :fill-pointer 0 :adjustable t)))
    (with-output-to-string (s fstr)
      (uiop:run-program cmd :output s))
    fstr))

(defun run-cmd (cmd)
  (uiop:run-program cmd))

(defun run-cmd-with-output (cmd)
  (uiop:run-program cmd :output t))

(defun join-strings (data &key (separator " "))
  "Convert a list of strings into a single string."
  (if (cdr data)
      (concatenate 'string (car data) separator (join-strings (cdr data) :separator separator))
      (car data)))

(defun init-rmbin ()
  (handler-case
      (progn
        (run-cmd "mkdir -p ~/.rmbin")
        t)
    (error (c)
      (format t "E: failed to create ~/.rmbin/")
      nil)))

(defun eval-call ()
  (if (get-argv)
      (let* ((args (car (list (get-argv))))
             (firstarg (car args))
             (restargs
               (if (> (length args) 1)
                   (join-strings (cdr args) " ")
                   "")))
        (cond ((string= firstarg "--restore") (handler-case
                                                  (run-cmd (concatenate 'string "mv ~/.rmbin/\"" restargs "\" ./"))
                                                (error (c)
                                                  (format t "E: unable to restore file~%"))))
              ((string= firstarg "--clean") (run-cmd "rm -rf ~/.rmbin/*"))
              ((string= firstarg "--list") (run-cmd-with-output "ls ~/.rmbin/"))
              ((string= firstarg "--help") (format t *help-string*))
              (t (handler-case
                     (run-cmd (concatenate 'string "mv \"" firstarg "\" ~/.rmbin/"))
                   (error (c)
                     (format t "E: unable to remove file~%"))))))
      (format t "E: no arguments specified, see --help for help~%")))

(when (init-rmbin)
  (eval-call))
