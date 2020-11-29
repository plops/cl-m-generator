(eval-when (:compile-toplevel :execute :load-toplevel)
  (ql:quickload "cl-m-generator")
  (ql:quickload "alexandria"))
(in-package :cl-m-generator)



(progn
  (defparameter *path* "/home/martin/stage/cl-m-generator/example/01_simple")
  (defparameter *code-file* "run_00_start")
  (defparameter *source* (format nil "~a/source/~a" *path* *code-file*))
  
  (defparameter *day-names*
    '("Monday" "Tuesday" "Wednesday"
      "Thursday" "Friday" "Saturday"
      "Sunday"))

     
  (let* (
	 
	 (code
	  `(do0
	    (do0 
		 (setf
	       _code_git_version
		  (string ,(let ((str (with-output-to-string (s)
					(sb-ext:run-program "/usr/bin/git" (list "rev-parse" "HEAD") :output s))))
			     (subseq str 0 (1- (length str)))))
		  _code_repository (string ,(format nil "https://github.com/plops/cl-m-generator/tree/master/example/01_simple/source/run_00_start.m")
					   )

		  _code_generation_time
		  (string ,(multiple-value-bind
				 (second minute hour date month year day-of-week dst-p tz)
			       (get-decoded-time)
			     (declare (ignorable dst-p))
		      (format nil "~2,'0d:~2,'0d:~2,'0d of ~a, ~d-~2,'0d-~2,'0d (GMT~@d)"
			      hour
			      minute
			      second
			      (nth day-of-week *day-names*)
			      year
			      month
			      date
			      (- tz)))))
		 )

	    (do0
	     (setf x (+ 1 (* 2 3)))
	     (space format short)
	     (setf y (+ (/ 1 (+ 2 (^ 3 2)))
			(* (/ 4 5)
			   (/ 6 7))))
	     (space format long)
	     y
	     clear
	     who
	     )

	    (do_
	     (setf x (+ 1 (* 2 3)))
	     (space format short)
	     (setf y (+ (/ 1 (+ 2 (^ 3 2)))
			(* (/ 4 5)
			   (/ 6 7))))
	     (space format long)
	     y
	     clear
	     who
	     )

	    (do0
	     (setf x (list 1 2 3 4 5 6)
		   y (list 3 -1 2 4 5 1))
	     (plot x y))

	     (do0
	     (setf x (slice 0 (/ pi 100) (* 2 pi))
		   y (sin x))
	     (plot x y)))
 	   ))
    (write-source (format nil "~a/source/~a" *path* *code-file*) code)))

