;; Ejemplo. 
;; TODO List
;;     - Arreglar overlap-condition (DONE)
;;     - Incluir nueva regla/restriccion para observaciones demasiado cercanas aunque no solapen (DONE)
;;     - Hacer uso de los modulos para organizar la ejecucion de las distintas reglas (DONE)
;;     - Volcar las violaciones de las restricciones a un fichero de salida (DONE)
;;     - Restricciones que impliquen un orden entre eventos o/y observaciones (puerta abierta, remote sensing window,...) (DONE)
;;     - Restricciones basadas en un criterio de distancia (p.e. distancia al sol) (DONE)
;;     - Implementar restricciones para la transición entre observaciones (en verdad, aplican sobre los modos pero para el caso es lo mismo)
;;     - Máximo valor representable con un tipo? (p.e. Integer) 
;;     - No me gusta el hecho 'restriction' tal y como está. No entiendo muy bien por qué lo hice así...Revisar
;;     - Limitar el cálculo de restricciones a un periodo de tiempo dado
;;     - Restricciones en el uso de recursos (power & bandwidth)
;;     - Testing con cientos o miles de observaciones. Escribir un generador.

(defglobal
  ?*counter* = 0)

(defmodule MAIN
  (export deftemplate ?ALL)
  (export deffunction ?ALL))

;; Observation class. Auto-explainable
(deftemplate MAIN::observation
        (slot start-time)
        (slot end-time)
        (slot obsname)
        (slot experiment)
        (slot module)
        (slot instance-id))

;; Event class. Auto-explainable
(deftemplate MAIN::event
  (slot start-time)
  (slot end-time)
  (slot eventname)
  (slot occurrence)
  (slot instance-id))

;; Class for representing two overlapping observations without any consideration
(deftemplate MAIN::time-overlapping
		(slot instance-1)
		(slot instance-2))

;; Class for representing detected observations that are too-close according to
;; a given threshold
(deftemplate MAIN::too-close
  (slot observation-1)
  (slot observation-2)
  (slot instance-1)
  (slot instance-2))

;; Class for representing detected overlapping observation instances
;; that shouldn´t overlap because there exists a
;; same-module-restriction between them
(deftemplate MAIN::same-module-time-overlapping
        (slot experiment)
	(slot module-name)
	(slot instance-1)
	(slot instance-2))		

;; Class for representing detected overlapping observations instances
;; that shouldn't overlap because there exists a name-restriction between them 
(deftemplate MAIN::incompat-observations-time-overlapping
        (slot observation-1)
        (slot observation-2)
        (slot instance-1)
	(slot instance-2))

;; Class for representing that an observation should be contained within a specific
;; event window and is not
(deftemplate MAIN::observation-out-of-window
  (slot observation-1)
  (slot instance-obs)
  (slot event-1))

(deftemplate MAIN::observation-out-of-distance-range
  (slot observation)
  (slot instance-1))

;; Class for specifying the different type of restrictions among observations
(deftemplate MAIN::restriction-obs-obs
         (slot restriction-name (type SYMBOL))
         (multislot incompat-observations (type SYMBOL) (cardinality 2 2))
         (slot delta (type NUMBER)))	

;; Class for specifying constraints between events and observations
(deftemplate MAIN::restriction-event-obs
  (slot restriction-name (type SYMBOL) (default ?NONE))
  (slot event (type SYMBOL) (default ?DERIVE))
  (slot observation (type SYMBOL) (default ?DERIVE)))

;; Classes for specifying constraints based on distance-to-sun for
;; events or observations. distance-range sets the range out of which
;; the event or obs is not valid
;; This feature could also be implemented using the range attribute
;; with the start-time and end-time slots in the event or observation
;; template and, therefore, forbidding the loading of the fact
;; instances out of the range
;;
;; I use two separated classes because, right now, I don't know how
;; to force having the observation or event slot present but not both
(deftemplate MAIN::restriction-obs-distance-to-sun
  (slot restriction-name (type SYMBOL) (default ?NONE))
  (slot observation (type SYMBOL) (default ?NONE))
  (multislot distance-range (type INTEGER) (cardinality 2 2)))

(deftemplate MAIN::restriction-ev-distance-to-sun
  (slot restriction-name (type SYMBOL) (default ?NONE))
  (slot event (type SYMBOL) (default ?NONE))
  (multislot distance-range (type INTEGER) (cardinality 2 2)))

;; Auxiliary functions for defining basic conditions among
;; observations and/or events
(deffunction MAIN::overlap-condition (?ti1 ?tf1 ?ti2 ?tf2)
         (or (and (>= ?ti1 ?ti2) (< ?ti1 ?tf2))
             (and (> ?tf1 ?ti2) (<= ?tf1 ?tf2))
             (and (> ?ti1 ?ti2) (< ?tf1 ?tf2))
             (and (< ?ti1 ?ti2) (> ?tf1 ?tf2))))

;; The first pair of values is contained within the second one

(deffunction MAIN::containing-condition (?ti1 ?tf1 ?ti2 ?tf2)
  (and (>= ?ti1 ?ti2) (< ?ti1 ?tf2) (<= ?tf1 ?tf2) (> ?tf1 ?ti2)))

(deffunction MAIN::too-close-condition (?ti1 ?tf1 ?ti2 ?tf2 ?delta)
		(or (and (>= (+ ?tf1 ?delta) ?ti2) (<= (+ ?tf1 ?delta) ?tf2))
		    (and (>= (+ ?tf2 ?delta) ?ti1) (<= (+ ?tf2 ?delta) ?tf1))))            

;; Fake function to provide the distance to Sun depending on
;; the time value. In a real implementation this should rely on the SPICE
;; toolkit to provide the real distance.
;; Let's assume the time value is in the [0,3000] range for this PoC
;; The output is in the range [0,10000)

(deffunction MAIN::distance-to-sun (?time)
  (* 10000 (sin (/ ?time 2000.0))))

(deffunction MAIN::printout-violation (?output ?factId)
             (printout ?output "==>   Constraint Violation # " ?*counter* crlf)
             (ppfact ?factId ?output crlf)
             (printout ?output "" crlf)
	     (bind ?*counter* (+ ?*counter* 1)))  

;; ###########################
;; The Facts
;; ###########################

;; Non-business-logic facts for controlling the execution
(deffacts MAIN::control-information
  (phase-sequence OBS_CONSTRAINTS EVENT_CONSTRAINTS END))

;; Global restriction facts. Eventually they will  be moved out to an external file
(deffacts MAIN::data
        (max-power-allowed 200)
        (max-bandwidth-allowed 2000))

;; Load the business logic facts
(defrule MAIN::preload-facts-and-start
  =>
;;  (load "/Users/ffelix/Workspaces/CLIPS/ConstraintsChecking/src/resources/event_facts.clp")
  (load "/Users/ffelix/Workspaces/CLIPS/ConstraintsChecking/src/resources/observation_event_facts.clp")
  (open "/tmp/violations.txt" outputFile "w")
  (reset))

;; ##########################
;; Execution control
;; ##########################

(defrule MAIN::change-phase
  ?list <- (phase-sequence ?next-phase $?other-phases)
  =>
 (retract ?list)
 (assert (phase-sequence ?other-phases))
 (focus ?next-phase))

;; ##############################
;; Module: OBS_CONSTRAINTS
;; ##############################

(defmodule OBS_CONSTRAINTS (import MAIN deftemplate observation time-overlapping same-module-time-overlapping 
				   too-close observation-out-of-distance-range
				   restriction-event-obs
				   incompat-observations-time-overlapping
				   restriction-obs-obs restriction-obs-distance-to-sun)
	(import MAIN deffunction ?ALL))

(defrule OBS_CONSTRAINTS::time-overlap-rule
	(observation (start-time ?st1) (end-time ?et1) (instance-id ?id1))
	(observation (start-time ?st2) (end-time ?et2&:(overlap-condition ?st1 ?et1 ?st2 ?et2)) (instance-id ?id2&~?id1))
	(not (time-overlapping (instance-1 ?id2) (instance-2 ?id1)))
	=>
	(assert (time-overlapping (instance-1 ?id1) (instance-2 ?id2))))

(defrule OBS_CONSTRAINTS::too-close-rule
        (restriction-obs-obs (restriction-name too-close) (incompat-observations ?o1 ?o2) (delta ?d))
	(observation (obsname ?o1) (start-time ?st1) (end-time ?et1) (instance-id ?id1))
	(observation (obsname ?o2) (start-time ?st2) (end-time ?et2&:(too-close-condition ?st1 ?et1 ?st2 ?et2 ?d)) (instance-id ?id2&~?id1))
	(not (too-close (instance-1 ?id2) (instance-2 ?id1)))
	=>
	(assert (too-close (observation-1 ?o1) (instance-1 ?id1)
			   (observation-2 ?o2) (instance-2 ?id2))))

(defrule OBS_CONSTRAINTS::same-module-time-overlap-rule
	(time-overlapping (instance-1 ?id1) (instance-2 ?id2))
	(observation (experiment ?e) (module ?n) (instance-id ?id1))
	(observation (experiment ?o) (module ?n) (instance-id ?id2))
	=>
	(assert (same-module-time-overlapping (experiment ?e) (module-name ?n) (instance-1 ?id1) (instance-2 ?id2))))
	
(defrule OBS_CONSTRAINTS::incompat-observations-time-overlap-rule
	(time-overlapping (instance-1 ?id1) (instance-2 ?id2))
	(observation (obsname ?n1) (instance-id ?id1))
	(observation (obsname ?n2) (instance-id ?id2))
	(restriction-obs-obs (restriction-name cant-overlap-observations) (incompat-observations ?n1 ?n2))
	=>
	(assert (incompat-observations-time-overlapping
		 (observation-1 ?n1) (instance-1 ?id1)
		 (observation-2 ?n2) (instance-2 ?id2))))

(defrule OBS_CONSTRAINTS::distance-to-sun-rule
  (observation (obsname ?n1) (start-time ?st1) (end-time ?et1) (instance-id ?id1))
  (restriction-obs-distance-to-sun (restriction-name observation-out-of-distance-range)
				   (observation ?n1)
				   (distance-range ?b ?u&:(not(containing-condition (distance-to-sun ?st1) (distance-to-sun ?et1) ?b ?u))))
  =>
  (assert (observation-out-of-distance-range (observation ?n1) (instance-1 ?id1))))  
				  

(defrule OBS_CONSTRAINTS::dump-obs-constraints-violations-rule
  (declare (salience -1))
  (not (dump-obs-constraints-run-once))
   (or (same-module-time-overlapping)
       (too-close)
       (incompat-observations-time-overlapping))
   =>
   (assert (dump-obs-constraints-run-once))
   (do-for-all-facts ((?violation same-module-time-overlapping
				  too-close
				  incompat-observations-time-overlapping
				  observation-out-of-distance-range))
                     TRUE
                     (printout-violation outputFile ?violation)))
   

;; ##############################
;; Module: EVENT_CONSTRAINTS
;; ##############################

(defmodule EVENT_CONSTRAINTS (import MAIN deftemplate observation
				     event restriction-event-obs observation-out-of-window restriction-ev-distance-to-sun)
				(import MAIN deffunction ?ALL))

(defrule EVENT_CONSTRAINTS::observations-out-of-event-window
  (observation (obsname ?o1) (instance-id ?id1) (start-time ?st1) (end-time ?et1))
  (not (event (eventname ?ev1) (instance-id ?id2) (start-time ?st2) (end-time ?et2&:(containing-condition ?st1 ?et1 ?st2 ?et2))))
  (restriction-event-obs (restriction-name obs-in-event-window) (event ?ev1) (observation ?o1)) 
  =>
  (assert (observation-out-of-window (observation-1 ?o1) (instance-obs ?id1) (event-1 ?ev1))))

(defrule EVENT_CONSTRAINTS::dump-event-constraints-violations-rule
  (declare (salience -1))
  (observation-out-of-window)
  =>
  (do-for-all-facts ((?violation observation-out-of-window))
                    TRUE
                    (printout-violation outputFile ?violation)))

;; ##############################
;; Module: END
;; ##############################

(defmodule END)
(defrule END::computation-finished-rule 
  =>
  (close outputFile)
  (halt))
