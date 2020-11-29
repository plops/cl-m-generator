(in-package #:cl-m-generator)
(setf (readtable-case *readtable*) :invert)

(defparameter *file-hashes* (make-hash-table))


(defun write-source (name code &optional (dir (user-homedir-pathname)))
  (let* ((fn (merge-pathnames (format nil "~a.m" name)
			      dir))
	(code-str (emit-m
		   :clear-env t
		   :code code))
	(fn-hash (sxhash fn))
	 (code-hash (sxhash code-str)))
    (multiple-value-bind (old-code-hash exists) (gethash fn-hash *file-hashes*)
     (when (or (not exists) (/= code-hash old-code-hash))
       ;; store the sxhash of the c source in the hash table
       ;; *file-hashes* with the key formed by the sxhash of the full
       ;; pathname
       (setf (gethash fn-hash *file-hashes*) code-hash)
       (with-open-file (s fn
			  :direction :output
			  :if-exists :supersede
			  :if-does-not-exist :create)
	 (write-sequence code-str s))
       ;(sb-ext:run-program "/usr/bin/js-beautify" (list "-r" (namestring fn)))
       ))))

#+nil
(defun beautify-source (code)
  (let* ((code-str (emit-m
		   :clear-env t
		   :code code)))
    (with-input-from-string (s code-str)
      (with-output-to-string (o)
	(sb-ext:run-program "/usr/bin/js-beautify" (list "-i") :input s :output o :wait t)
	))))

#+nil
(beautify-source '(setf a 3))

(defun print-sufficient-digits-f32 (f)
  "print a single floating point number as a string with a given nr. of                                                                                                                                             
  digits. parse it again and increase nr. of digits until the same bit                                                                                                                                              
  pattern."
    (let* ((a f)
           (digits 1)
           (b (- a 1)))
      (unless (= a 0)
	(loop while (and (< 1e-6 (/ (abs (- a b))
				    (abs a)))
			 (< digits 30))
           do
             (setf b (read-from-string (format nil "~,v,,,,,'eG"
					;"~,vG"
					       digits a
					       )))
             (incf digits)))
					;(format nil "~,vG" digits a)
      ;(format nil "~,v,,,,,'eGf" digits a)
      (let ((str
	     (format nil "~,v,,,,,'eG" digits a)))
	(format nil "~af" (string-trim '(#\Space) str))
	#+nil
	(if (find #\e str)
	    str
	    (format nil "~af" (string-trim '(#\Space) str))))))

(defun print-sufficient-digits-f64 (f)
  "print a double floating point number as a string with a given nr. of                                                                                                                                             
  digits. parse it again and increase nr. of digits until the same bit                                                                                                                                              
  pattern."

  (let* ((a f)
         (digits 1)
         (b (- a 1)))
    (unless (= a 0)
      (loop while (and (< 1d-12
			  (/ (abs (- a b))
			     (abs a))
			  )
		       (< digits 30)) do
           (setf b (read-from-string (format nil "~,vG" digits a)))
	   (incf digits)))
    ;(format t "~,v,,,,,'eG~%" digits a)
    (format nil "~,v,,,,,'eG" digits a)
    ;(substitute #\e #\d (format nil "~,vG" digits a))
    ))
#+nil
(defun print-sufficient-digits-f64 (f)
  "print a double floating point number as a string with a given nr. of
  digits. parse it again and increase nr. of digits until the same bit
  pattern."
  (let* ((ff (coerce f 'double-float))
	 (s (format nil "~E" ff)))
    #+nil (assert (= 0d0 (- ff
			    (read-from-string s))))
    (assert (< (abs (- ff
		       (read-from-string s)))
	       1d-12))
   (substitute #\e #\d s)))

;(print-sufficient-digits-f64 1d0)


(defparameter *env-functions* nil)
(defparameter *env-macros* nil)



(defun emit-m (&key code (str nil) (clear-env nil) (level 0))
					;(format t "emit ~a ~a~%" level code)
  (when clear-env
    (setf *env-functions* nil
	  *env-macros* nil))
  (flet ((emit (code &optional (dl 0))
	   (emit-m :code code :clear-env nil :level (+ dl level))))
    (if code
	(if (listp code)
	    (case (car code)
	      (paren (let ((args (cdr code)))
		       (format nil "(~{~a~^, ~})" (mapcar #'emit args))))
	      (list (let ((args (cdr code)))
		      (format nil "[~{~a~^, ~}]" (mapcar #'emit args))))
              (dict (let* ((args (cdr code)))
		      (let ((str (with-output-to-string (s)
				   (loop for (e f) in args
				      do
					(format s "~a:(~a)," (emit e) (emit f))))))
			(format nil "{~a}" ;; remove trailing comma
				(subseq str 0 (- (length str) 1))))))
	      (space
		   ;; space {args}*
		   (let ((args (cdr code)))
		     (format nil "~{~a~^ ~}" (mapcar #'emit args))))
	      (indent (format nil "~{~a~}~a"
			      (loop for i below level collect "    ")
			      (emit (cadr code))))
	      (statement (with-output-to-string (s)
			   (format s "~{~a;~%~}" (mapcar #'(lambda (x) (emit `(indent ,x))) (cdr code)))))
	      
	      (do (with-output-to-string (s)
		    (format s "~{~a~}" (mapcar #'(lambda (x) (emit `(statement ,x) 1)) (cdr code)))))
	      (progn (with-output-to-string (s)
			   ;; progn {form}*
			   ;; like do but surrounds forms with braces.
			   (format s "{~{~&~a~}~&}" (mapcar #'(lambda (x) (emit `(indent (do0 ,x)) 1)) (cdr code)))))
	      (do0 (with-output-to-string (s)
		     (format s "~a~%~{~a~%~}"
			     (emit (cadr code))
			     (mapcar #'(lambda (x) (emit `(indent ,x) 0)) (cddr code)))))
	      (lambda (format nil "~a" (emit `(defun "" ,@(cdr code)))))
	      
	      (defun (destructuring-bind (name lambda-list &rest body) (cdr code)
		     (multiple-value-bind (req-param opt-param res-param
						     key-param other-key-p aux-param key-exist-p)
			 (parse-ordinary-lambda-list lambda-list)
		       (declare (ignorable req-param opt-param res-param
					   key-param other-key-p aux-param key-exist-p))
		       (with-output-to-string (s)
			 ;; function bla (para) {
			 ;; function bla (para, ...rest) {
			 ;; function bla ({ from = 0, to = this.length } = {}) {
			 (format s "function ~a~a"
				 name
				 (emit `(paren ,@(append req-param
							 (when key-param
							   `((setf (dict
								    ,@(loop for e in key-param collect
									   (destructuring-bind ((keyword-name name) init suppliedp)
									       e
									     (declare (ignorable keyword-name suppliedp))
									     `(,name ,init))))
								   "{}")))
							 (when res-param
							   (list (format nil "...~a" res-param)))))))
			 (format s "{~a}" (emit `(do ,@body)))))))
	      #+nil (defclass (let ((args (cdr code)))
				;; classdef <name>
				;; properties (Access=private, Constant)
				;; bla = 'fub';
				;; end
				;; methods (Static = true)
				;; functin bla(a,b)
				(destructuring-bind (name &rest rest) args
				  (emit `(space ,(format nil "class ~a" name)
						(progn ,@rest))))))
	      (defmethod (destructuring-bind (name lambda-list &rest body) (cdr code)
		     (multiple-value-bind (req-param opt-param res-param
						     key-param other-key-p aux-param key-exist-p)
			 (parse-ordinary-lambda-list lambda-list)
		       (declare (ignorable req-param opt-param res-param
					   key-param other-key-p aux-param key-exist-p))
		       (with-output-to-string (s)
			 ;; function add (a, b)
			 ;;   expression;
			 ;; end
			 ;; function res = add(a,b)
			 ;; function [c,d] = add(a,b)
			 
			 (format s "function ~a~a"
				 name
				 (emit `(paren ,@(append req-param
							 (when key-param
							   `((setf (dict
								    ,@(loop for e in key-param collect
									   (destructuring-bind ((keyword-name name) init suppliedp)
									       e
									     (declare (ignorable keyword-name suppliedp))
									     `(,name ,init))))
								   "{}")))
							 (when res-param
							   (list (format nil "...~a" res-param)))))))
			 (format s "~a" (emit `(do ,@body)))
			 (format s "end")))))
	   
	      (= (destructuring-bind (a b) (cdr code)
		   (format nil "~a=~a" (emit a) (emit b))))
	      (incf (destructuring-bind (a b) (cdr code)
		   (format nil "~a+=~a" (emit a) (emit b))))
	      (setf (let ((args (cdr code)))
		      (format nil "~a"
			      (emit `(,(if (eq (length args) 2)
					   `do0
					   `statement)
				       ,@(loop for i below (length args) by 2 collect
					      (let ((a (elt args i))
						    (b (elt args (+ 1 i))))
						`(= ,a ,b))))))))
	   
	   
	      (aref (destructuring-bind (name &rest indices) (cdr code)
		      (format nil "~a(~{~a~^,~})" (emit name) (mapcar #'emit indices))))
	      (slice (let ((args (cdr code)))
		       (if (null args)
			   (format nil ":")
			   (format nil "~{~a~^:~}" (mapcar #'emit args)))))
	      (dot (let ((args (cdr code)))
		     (format nil "~{~a~^.~}" (mapcar #'emit args))))
	      (+ (let ((args (cdr code)))
		   (format nil "(~{(~a)~^+~})" (mapcar #'emit args))))
	      (- (let ((args (cdr code)))
		   (format nil "(~{(~a)~^-~})" (mapcar #'emit args))))
	      (* (let ((args (cdr code)))
		   (format nil "(~{(~a)~^*~})" (mapcar #'emit args))))
	      (== (let ((args (cdr code)))
		    (format nil "(~{(~a)~^==~})" (mapcar #'emit args))))
	      (=== (let ((args (cdr code)))
		     (format nil "(~{(~a)~^===~})" (mapcar #'emit args))))
	      (!= (let ((args (cdr code)))
		    (format nil "(~{(~a)~^!=~})" (mapcar #'emit args))))
	      (< (let ((args (cdr code)))
		   (format nil "(~{(~a)~^<~})" (mapcar #'emit args))))
	      (<= (let ((args (cdr code)))
		    (format nil "(~{(~a)~^<=~})" (mapcar #'emit args))))
	      (/ (let ((args (cdr code)))
		   (format nil "((~a)/(~a))"
			   (emit (first args))
			   (emit (second args)))))
	      (^ (let ((args (cdr code)))
		    (format nil "((~a)^(~a))"
			    (emit (first args))
			    (emit (second args)))))
	      (// (let ((args (cdr code)))
		    (format nil "((~a)//(~a))"
			    (emit (first args))
			    (emit (second args)))))
	      (% (let ((args (cdr code)))
		   (format nil "((~a)%(~a))"
			   (emit (first args))
			   (emit (second args)))))
	      (and (let ((args (cdr code)))
		     (format nil "(~{(~a)~^ && ~})" (mapcar #'emit args))))
	      (or (let ((args (cdr code)))
		    (format nil "(~{(~a)~^ || ~})" (mapcar #'emit
							   args))))
	      (not (let ((args (cdr code)))
		    (format nil "(~~(~a))" (emit (car args)))))
	      (string (format nil "\"~a\"" (cadr code)))
	      (return_ (format nil "return ~a" (emit (caadr code))))
	      (return (let ((args (cdr code)))
			(format nil "~a" (emit `(return_ ,args)))))
	      (for (destructuring-bind ((start end iter) &rest body) (cdr code)

		     ;;  for(count = 0; count < 10; count++){
		     (with-output-to-string (s)
		       (format s "for(~a ; ~a; ~a){~%"
			       (emit start)
			       (emit end)
			       (emit iter))
		       (format s "~a}" (emit `(do ,@body))))))
	      (dotimes (destructuring-bind ((start end) &rest body) (cdr code)
			 ;;  for(count = 0; count < 10; count++){
			 (with-output-to-string (s)
			   (format s "~a"
				   (emit `(for ((setf ,start 0) (< ,start ,end) (setf start (+ 1 start)))
					       ,@body))))))
	      (for-in (destructuring-bind ((vs ls) &rest body) (cdr code)
			;; for (var property1 in object1) {
			(with-output-to-string (s)
			  (format s "for (var ~a in ~a){~%"
				  (emit vs)
				  (emit ls))
			  (format s "~a}" (emit `(do ,@body))))))
	      (for-of (destructuring-bind ((vs ls) &rest body) (cdr code)
			;; for (let o of foo) {
			(with-output-to-string (s)
			  (format s "for (let ~a of ~a){~%"
				  (emit vs)
				  (emit ls))
			  (format s "~a}" (emit `(do ,@body))))))

	      (if (destructuring-bind (condition true-statement &optional false-statement) (cdr code)
		    ;; if <condition>
		    ;;   true;
		    ;; else
		    ;;   false;
		    ;; end
		    (with-output-to-string (s)
		      (format s "if  ~a ~%~a"
			      (emit condition)
			      (emit `(do ,true-statement)))
		      (when false-statement
			(format s "~a~%~a"
				(emit `(indent "else"))
				(emit `(do ,false-statement))))
		      (format s "end~%"))))
	      (when (destructuring-bind (condition &rest forms) (cdr code)
			  (emit `(if ,condition
				     (do0
				      ,@forms)))))

	      (comments (let ((args (cdr code)))
			  (format nil "~{% ~a~%~}" args)))
	      (cell (let ((args (cdr code)))
			  (format nil "~{%% ~a~%~}" args)))
	      (t (destructuring-bind (name &rest args) code
		   (let* ((positional (loop for i below (length args) until (keywordp (elt args i)) collect
					   (elt args i)))
			  (plist (subseq args (length positional)))
			  (props (loop for e in plist by #'cddr collect e)))
		     (format nil "~a~a" (if (listp name) (emit name)
					    name)
			     (if (and (listp props) (< 0 (length props)))
			      (emit `(paren ,@(append
					       positional
					       (list `(dict
						       ,@(loop for e in props collect
							      `(,(format
								  nil "~a" e) ,(getf plist e))))))))
			      (emit `(paren ,@positional))))))))
	    (cond
	      ((or (symbolp code)
		   (stringp code)) ;; print variable
	       (format nil "~a" code))
	      ((numberp code) ;; print constants
	       (cond ((integerp code) (format str "~a" code))
		     ((floatp code)
		      (format str "(~a)" (print-sufficient-digits-f64 code)))
		     ((complexp code)
		      (format str "((~a) + 1j * (~a))"
			      (print-sufficient-digits-f64 (realpart code))
			      (print-sufficient-digits-f64 (imagpart code))))))))
	"")))


