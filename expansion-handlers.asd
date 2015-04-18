;;;; expansion-handlers.asd

(defpackage :expansion-handlers-system
  (:use :cl :asdf))
(in-package :expansion-handlers-system)

(defsystem :expansion-handlers
  :name "expansion-handlers"
  :serial t
  :components
  ((:static-file "expansion-handlers.asd")
   (:module :src
            :components ((:file "package")
                         (:file "expansion-handlers"))
            :serial t))
  :depends-on (:alexandria))

(defsystem :expansion-handlers-test
  :name "expansion-handlers-test"
  :serial t
  :components
  ((:module :test
            :components ((:file "package")
                         (:file "expansion-handlers-test"))))
  :depends-on (:expansion-handlers :stefil))
