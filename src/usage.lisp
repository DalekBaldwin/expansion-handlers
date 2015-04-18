(in-package :expansion-handlers)

(define-symbol-macro accumulate (gensym))
(define-symbol-macro iter-block (gensym))

(define-condition accumulate-target () ((name :initarg :name :reader name)))

(defmacro while (condition)
  `(unless ,condition
     (return-from iter-block
       (nreverse accumulate))))

(defmacro collect (thing &key into &environment env)
  (if into
      (expansion-signal 'accumulate-target env :name into)
      `(push ,thing accumulate)))

(defmacro iter (&body body &environment env)
  (alexandria:with-gensyms (start)
    (let ((accum (gensym)))
      (expansion-handler-case
       `(symbol-macrolet ((iter-block (gensym)))
          (block iter-block
            (let ((,accum nil))
              (tagbody
                 ,start
                 ,@body
                 (go ,start)))))
       env
       ;; handler
       (accumulate-target (c)
                          (let ((accum (name c)))
                            `(symbol-macrolet ((accumulate ',accum)
                                               (iter-block (gensym)))
                               (block ,iter-block
                                 (let ((,accum nil))
                                   (macrolet ((collect (thing &key into)
                                                `(push ,thing ,',accum)))
                                     (tagbody
                                        ,start
                                        ,@body
                                        (go ,start))))))))))))

(let ((stuff (list (list (list 'accumulate-target 'barf)))))
  (find-if #'identity (first stuff) :key #'rest))



(defmacro iter (&body body &environment env)
  (alexandria:with-gensyms (start)
    (let ((accum (gensym)))
      (multiple-value-bind (expansion expanded-p)
          (macroexpand-1 'handlers env)
        `(symbol-macrolet ((handlers
                            ,(if expanded-p
                                 (append (list (list (list 'accumulate-target))) expansion)
                                 (list (list (list 'accumulate-target))))))
           (flet ((candidate-expansion ()
                    (block iter-block
                      (let ((,accum nil))
                        (tagbody
                           ,start
                           ,@body
                           (go ,start))))))
             (macrolet ((handle-signals (&environment env)
                          (multiple-value-bind (expansion expanded-p)
                              (macroexpand-1 'handlers env)
                            (declare (ignorable expanded-p))
                            (let ((signalled
                                   (find-if #'identity (first expansion) :key #'rest)))
                              (format t "~&~A~%" expansion)
                              (if signalled
                                  (handler-case (apply #'signal
                                                       (first signalled)
                                                       (second signalled))
                                    (accumulate-target (c)
                                      (format t "signal: ~&~A ~A~%" c (name c))
                                      (let ((accum (name c)))
                                        `(symbol-macrolet ((accumulate ,accum)
                                                           ;;(iter-block (gensym))
                                                           )
                                           (block iter-block
                                             (let ((,accum nil))
                                               (macrolet ((collect (thing &key into)
                                                            (declare (ignorable into))
                                                            `(push ,thing ,',accum)))
                                                 (tagbody
                                                    ,',start
                                                    ,@',body
                                                    (go ,',start)))))))))
                                  `(candidate-expansion))))))
               (handle-signals))))))))

(defmacro iter (&body body &environment env)
  (alexandria:with-gensyms (start accum)
    (expansion-handler-case
     `(block iter-block
        (let ((,accum nil))
          (tagbody
             ,start
             ,@body
             (go ,start))))
     env
     (accumulate-target (c)
                        (let ((accm (name c)))
                          (format t "~&~A~%" c)
                          `(symbol-macrolet ((accumulate ,accm)
                                             ;;(iter-block (gensym))
                                             )
                             (block iter-block
                               (let ((,accm nil))
                                 (macrolet ((collect (thing &key into)
                                              `(push ,thing ,',accm)))
                                   (tagbody
                                      ,start
                                      ,@body
                                      (go ,start)))))))))))

(defun do-iter (i)
  (iter (while (< i 5))
        (incf i)
        (print acc)
        (collect (+ 3 (* 4 i)) :into acc)))

#+nil
(defun do-iter (i)
  (iter (while (< i 5))
        (incf i)
        (print acc)
        (macrolet ((my-collect (&rest args)
                     `(collect ,@args)))
          (my-collect (+ 3 (* 4 i)) :into acc))))

#+nil
(do-iter 0)
