(in-package :expansion-handlers)

(defmacro expansion-handler-case (form env &rest cases)
  (let ((typespecs
         (list (loop for (typespec vars body) in cases
                  collect (list typespec)))))
    (multiple-value-bind (expansion expanded-p)
        (macroexpand-1 'handlers env)
      `(symbol-macrolet ((handlers
                          ,(if expanded-p
                               (append typespecs expansion)
                               typespecs)))
         (flet ((candidate-expansion ()
                  ,form))
           (macrolet ((handle-signals (&environment env)
                        (multiple-value-bind (expansion expanded-p)
                            (macroexpand-1 'handlers env)
                          (when expanded-p
                            (let ((signalled
                                   (find-if #'identity (first expansion) :key #'rest)))
                              (if signalled
                                  (handler-case (apply #'signal signalled)
                                    ,@cases)
                                  `(candidate-expansion)))))))
             (handle-signals)))))))

(defmacro expansion-handler-case (form env &rest cases)
  (let ((typespecs
         `(list (list ,@(loop for (typespec vars body) in cases
                           collect `(list ',typespec))))))
    `(multiple-value-bind (expansion expanded-p)
         (macroexpand-1 'handlers ,env)
       `(symbol-macrolet ((handlers
                           ,(if expanded-p
                                (append ,typespecs expansion)
                                ,typespecs)))
          (flet ((candidate-expansion ()
                   ,,form))
            
            (macrolet ((handle-signals (&environment env )
                         (multiple-value-bind (expansion expanded-p)
                             (macroexpand-1 'handlers env)
                           (declare (ignorable expanded-p))
                           (let ((signalled
                                  (find-if #'identity (first expansion) :key #'rest)))
                             (if signalled
                                 (handler-case (apply #'signal
                                                      (first signalled) ;; condition type
                                                      (second signalled) ;; first arg set
                                                      )
                                   ,@',cases
                                   )
                                 `(candidate-expansion))))))
              (handle-signals)))))))



(defun expansion-signal (datum env &rest arguments)
  (multiple-value-bind (expansion expanded-p)
      (macroexpand-1 'handlers env)
    (declare (ignorable expanded-p))
    (flet ((find-case (layer) (find datum layer :key #'first)))
      (let ((matching-layer
             (find-if (lambda (layer) (find-case layer)) expansion)))
        (when matching-layer
          (let ((matching-case (find-case matching-layer)))
            (setf (rest matching-case)
                  (append (list arguments) (rest matching-case))))))))
  nil)
