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

(deftemplate observation
        (slot start-time)
        (slot end-time)
        (slot obsname)
        (slot experiment)
        (slot module)
        (slot instance-id))
                        
(deftemplate time-overlapping
		(slot instance-1)
		(slot instance-2))
		
(deftemplate too-close
         (slot instance-1)
         (slot instance-2))
		
(deftemplate same-module-time-overlapping
		(slot module-name)
		(slot instance-1)
		(slot instance-2))		

(deftemplate incompat-observations-time-overlapping
		(slot instance-1)
		(slot instance-2))
				
(deftemplate restriction
         (slot name)
         (multislot incompat-observations)
         (slot delta))	
         				
(deffunction overlap-condition (?ti1 ?tf1 ?ti2 ?tf2)
         (or (and (>= ?ti1 ?ti2) (< ?ti1 ?tf2))
             (and (> ?tf1 ?ti2) (<= ?tf1 ?tf2))
             (and (> ?ti1 ?ti2) (< ?tf1 ?tf2))
             (and (< ?ti1 ?ti2) (> ?tf1 ?tf2))))
 
(deffunction too-close-condition (?ti1 ?tf1 ?ti2 ?tf2 ?delta)
		(or (and (>= (+ ?tf1 ?delta) ?ti2) (<= (+ ?tf1 ?delta) ?tf2))
		    (and (>= (+ ?tf2 ?delta) ?ti1) (<= (+ ?tf2 ?delta) ?tf1))))            
             	
(deffacts datos
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
		
(defrule init 
		=> 
		(assert (start-calculation)))
		
(defrule time-overlap-rule
		?start <- (start-calculation)
		(observation (start-time ?st1) (end-time ?et1) (instance-id ?id1))
		(observation (start-time ?st2) (end-time ?et2&:(overlap-condition ?st1 ?et1 ?st2 ?et2)) (instance-id ?id2&~?id1))
		(not (time-overlapping (instance-1 ?id2) (instance-2 ?id1)))
		=>
		(assert (time-overlapping (instance-1 ?id1) (instance-2 ?id2))))

(defrule too-close-rule
        (restriction (name too-close) (incompat-observations ?o1 ?o2) (delta ?d)) 
		(observation (obsname ?o1) (start-time ?st1) (end-time ?et1) (instance-id ?id1))
		(observation (obsname ?o2) (start-time ?st2) (end-time ?et2&:(too-close-condition ?st1 ?et1 ?st2 ?et2 ?d)) (instance-id ?id2&~?id1))
		(not (too-close (instance-1 ?id2) (instance-2 ?id1)))
		=>
		(assert (too-close (instance-1 ?id1) (instance-2 ?id2))))
	
(defrule same-module-time-overlap-rule
		?tover <- (time-overlapping (instance-1 ?id1) (instance-2 ?id2))
		(observation (module ?n) (instance-id ?id1))
		(observation (module ?n) (instance-id ?id2))
		=>
		(assert (same-module-time-overlapping (module-name ?n) (instance-1 ?id1) (instance-2 ?id2))))

(defrule incompat-observations-time-overlap-rule
		?tover <- (time-overlapping (instance-1 ?id1) (instance-2 ?id2))
		?o1 <- (observation (obsname ?n1) (instance-id ?id1))
		?o2 <- (observation (obsname ?n2) (instance-id ?id2))
		(restriction (name cant-overlap-observations) (incompat-observations ?n1 ?n2))
		=>
		(assert (incompat-observations-time-overlapping (instance-1 ?id1) (instance-2 ?id2))))        

		 		
