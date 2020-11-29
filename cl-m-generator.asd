(asdf:defsystem cl-m-generator
    :version "0"
    :description "Emit Matlab/Octave code"
    :maintainer " <kielhorn.martin@gmail.com>"
    :author " <kielhorn.martin@gmail.com>"
    :licence "GPL"
    :depends-on ("alexandria")
    :serial t
    :components ((:file "package")
		 (:file "m")) )
