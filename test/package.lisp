(in-package :cl-user)

(defpackage :expansion-handlers-test
  (:use :cl :expansion-handlers :stefil)
  (:export
   #:test-all))

(in-package :expansion-handlers-test)

(defparameter *system-directory* expansion-handlers::*system-directory*)
