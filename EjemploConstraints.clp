;; Ejemplo. Calculo de solapamiento entre observaciones
;; TODO List
;;     - Arreglar overlap-condition (DONE)
;;     - Incluir nueva regla/restriccion para observaciones demasiado
;;     cercanas aunque no solapen (DONE)
;;     - Restricciones en el uso de recursos (power & bandwidth)
;;     - Hacer uso de los modulos para organizar la ejecucion de las
;;       distintas reglas
;;     - No me gusta el hecho 'restriction' tal y como está. No generaliza muy bien...
;;     - Limitar el cálculo de restricciones a un periodo de tiempo dado
;;     - Implementar restricciones para la transición entre observaciones (en verdad, aplican sobre los modos pero para el caso es lo mismo)
;;     - Testing con cientos o miles de observaciones. Escribir un generador.

(defmodule MAIN
  (export deftemplate initial-fact
	  observation event time-overlapping
	  too-close restriction same-module-time-overlapping
	  incompat-observations-time-overlapping)
	  (export deffunction ?ALL))
	  
(deftemplate MAIN::observation
        (slot start-time)
        (slot end-time)
        (slot obsname)
        (slot experiment)
        (slot module)
        (slot instance-id))

(deftemplate MAIN::event
  (slot start-time)
  (slot end-time)
  (slot eventname)
  (slot occurrence))
                        
(deftemplate MAIN::time-overlapping
		(slot instance-1)
		(slot instance-2))
		
(deftemplate MAIN::too-close
         (slot instance-1)
         (slot instance-2))
		
(deftemplate MAIN::same-module-time-overlapping
		(slot module-name)
		(slot instance-1)
		(slot instance-2))		

(deftemplate MAIN::incompat-observations-time-overlapping
		(slot instance-1)
		(slot instance-2))
				
(deftemplate MAIN::restriction
         (slot name)
         (multislot incompat-observations (type SYMBOL) (cardinality 2 2))
         (slot delta (type NUMBER)))	
         				
(deffunction MAIN::overlap-condition (?ti1 ?tf1 ?ti2 ?tf2)
         (or (and (>= ?ti1 ?ti2) (< ?ti1 ?tf2))
             (and (> ?tf1 ?ti2) (<= ?tf1 ?tf2))
             (and (> ?ti1 ?ti2) (< ?tf1 ?tf2))
             (and (< ?ti1 ?ti2) (> ?tf1 ?tf2))))
 
(deffunction MAIN::too-close-condition (?ti1 ?tf1 ?ti2 ?tf2 ?delta)
		(or (and (>= (+ ?tf1 ?delta) ?ti2) (<= (+ ?tf1 ?delta) ?tf2))
		    (and (>= (+ ?tf2 ?delta) ?ti1) (<= (+ ?tf2 ?delta) ?tf1))))            
             	
(deffacts MAIN::datos
        (observation (start-time 10) (end-time 20) (obsname EUI_FLUSH) (experiment EUI) (module FLUSH) (instance-id 1))
        (observation (start-time 30) (end-time 40) (obsname EUI_FLUSH) (experiment EUI) (module FLUSH) (instance-id 2))
        (observation (start-time 35) (end-time 39) (obsname EUI_FLUSH) (experiment EUI) (module FLUSH) (instance-id 3))
        (observation (start-time 100) (end-time 200) (obsname EUI_FLUSH) (experiment EUI) (module FLUSH) (instance-id 4))
        (observation (start-time 135) (end-time 142) (obsname MAG_EQUAL8) (experiment MAG) (module DEFAULT) (instance-id 5))
        (observation (start-time 100) (end-time 198) (obsname MAG_NORMAL) (experiment MAG) (module DEFAULT) (instance-id 6))
        (observation (start-time 135) (end-time 141) (obsname MAG_LOW) (experiment MAG) (module DEFAULT) (instance-id 7))
        (observation (start-time 30) (end-time 40) (obsname MAG_LOW) (experiment MAG) (module DEFAULT) (instance-id 8))
        (observation (start-time 50) (end-time 60) (obsname MAG_HIGH) (experiment MAG) (module DEFAULT) (instance-id 9))
        (restriction (name cant-overlap-observations) (incompat-observations MAG_EQUAL8 EUI_FLUSH))
        (restriction (name too-close) (incompat-observations MAG_HIGH EUI_FLUSH) (delta 10))
        (max-power-allowed 200)
        (max-bandwidth-allowed 2000)
        (start-calculation))

(deffacts MAIN::control-information
  (phase-sequence OBS_CONSTRAINTS EVENT_CONSTRAINTS))

(defrule MAIN::change-phase
  ?list <- (phase-sequence ?next-phase $?other-phases)
  =>
 (focus ?next-phase)
 (retract ?list)
 (assert (phase-sequence ?other-phases)))

;; ##############################
;; Module: OBS_CONSTRAINTS
;; ##############################

(defmodule OBS_CONSTRAINTS 
                    (import MAIN deftemplate observation time-overlapping same-module-time-overlapping 
                                 too-close restriction incompat-observations-time-overlapping initial-fact)
				   (import MAIN deffunction ?ALL))

(defrule OBS_CONSTRAINTS::time-overlap-rule
		(observation (start-time ?st1) (end-time ?et1) (instance-id ?id1))
		(observation (start-time ?st2) (end-time ?et2&:(overlap-condition ?st1 ?et1 ?st2 ?et2)) (instance-id ?id2&~?id1))
		(not (time-overlapping (instance-1 ?id2) (instance-2 ?id1)))
		=>
		(assert (time-overlapping (instance-1 ?id1) (instance-2 ?id2))))

(defrule OBS_CONSTRAINTS::same-module-time-overlap-rule
		?tover <- (time-overlapping (instance-1 ?id1) (instance-2 ?id2))
		(observation (module ?n) (instance-id ?id1))
		(observation (module ?n) (instance-id ?id2))
		=>
		(assert (same-module-time-overlapping (module-name ?n) (instance-1 ?id1) (instance-2 ?id2))))

(defrule OBS_CONSTRAINTS::too-close-rule
        (restriction (name too-close) (incompat-observations ?o1 ?o2) (delta ?d)) 
		(observation (obsname ?o1) (start-time ?st1) (end-time ?et1) (instance-id ?id1))
		(observation (obsname ?o2) (start-time ?st2) (end-time ?et2&:(too-close-condition ?st1 ?et1 ?st2 ?et2 ?d)) (instance-id ?id2&~?id1))
		(not (too-close (instance-1 ?id2) (instance-2 ?id1)))
		=>
		(assert (too-close (instance-1 ?id1) (instance-2 ?id2))))
	
(defrule OBS_CONSTRAINTS::incompat-observations-time-overlap-rule
		?tover <- (time-overlapping (instance-1 ?id1) (instance-2 ?id2))
		?o1 <- (observation (obsname ?n1) (instance-id ?id1))
		?o2 <- (observation (obsname ?n2) (instance-id ?id2))
		(restriction (name cant-overlap-observations) (incompat-observations ?n1 ?n2))
		=>
		(assert (incompat-observations-time-overlapping (instance-1 ?id1) (instance-2 ?id2))))        


;; ##############################
;; Module: EVENT_CONSTRAINTS
;; ##############################

(defmodule EVENT_CONSTRAINTS (import MAIN deftemplate observation event restriction))
