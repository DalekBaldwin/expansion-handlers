(in-package :expansion-handlers)

(eval-when (:compile-toplevel :load-toplevel :execute)
  (define-symbol-macro accumulate (gensym))
  (define-symbol-macro iter-block (gensym))

  (define-condition accumulate-target () ((name :initarg :name :reader name))))

(defmacro while (condition)
  `(unless ,condition
     (return-from iter-block
       (nreverse accumulate))))

(defmacro collect (thing &key into &environment env)
  (if into
      (expansion-signal 'accumulate-target env :name into)
      `(push ,thing accumulate)))

#+nil
(let ((stuff (list (list (list 'accumulate-target 'barf)))))
  (find-if #'identity (first stuff) :key #'rest))

;; what we want expansion-handler-case to expand into as a helper macro
#+nil
(defmacro iter (&body body &environment env)
  (alexandria:with-gensyms (start accum)
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
             (handle-signals)))))))

;; what I really WANT expansion-handler-case to look like
#+nil
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

;; unfortunately I can't figure out how to avoid having to lift
;; each case up into an extra quasiquote
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
     `(accumulate-target (c)
                         (let ((accm (name c)))
                           `(symbol-macrolet ((accumulate ,accm))
                              (block iter-block
                                (let ((,accm nil))
                                  (macrolet ((collect (thing &key into)
                                               (declare (ignorable into))
                                               `(push ,thing ,',accm)))
                                    (tagbody
                                       ,',start
                                       ,@',body
                                       (go ,',start)))))))))))

#+nil
(defun do-iter (i)
  (iter (while (< i 5))
        (incf i)
        (print acc)
        (collect (+ 3 (* 4 i)) :into acc)))

(defun do-iter (i)
  (iter (while (< i 5))
        (incf i)
        (print acc)
        
        ;; we can do this too
        (macrolet ((my-collect (&rest args)
                     `(collect ,@args)))
          (my-collect (+ 3 (* 4 i)) :into acc))))

;; since the first candidate expansion must be expanded to extract
;; the info we need, we see its warnings:

; 
; caught WARNING:
;   undefined variable: ACC
; 
; compilation unit finished
;   Undefined variable:
;     ACC
;   caught 1 WARNING condition

#+nil
(do-iter 0)

;; output:
;; NIL 
;; (7) 
;; (11 7) 
;; (15 11 7) 
;; (19 15 11 7)

;; result: (7 11 15 19 23)
