(in-package :cl-user)

(defpackage :expansion-handlers
  (:use :cl))

(in-package :expansion-handlers)

(defparameter *system-directory*
  (make-pathname
   :directory
   (pathname-directory
    (asdf:system-definition-pathname "expansion-handlers"))))
