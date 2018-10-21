;; Ejemplo. Calculo de solapamiento entre observaciones
;; TODO List
;;     - No me gusta el hecho 'restriction' tal y como está. No generaliza muy bien...
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
		
(deftemplate module-time-overlapping
		(slot module)
		(slot instance-1)
		(slot instance-2))		

(deftemplate experiment-name-time-overlapping
		(slot restriction-name)
		(slot instance-1)
		(slot instance-2))
				
(deftemplate restriction
         (slot name)
         (multislot incompat-observations))				
		
(deffunction overlap-condition (?ti1 ?tf1 ?ti2 ?tf2)
         (or (and (> ?ti1 ?ti2) (< ?ti1 ?tf2))
             (and (> ?tf1 ?ti2) (< ?tf1 ?tf2))
             (and (> ?ti1 ?ti2) (< ?tf1 ?tf2))
             (and (< ?ti1 ?ti2) (> ?tf1 ?tf2))))		
(deffacts datos
        (observation (start-time 10) (end-time 20) (obsname EUI_FLUSH) (experiment EUI) (module FLUSH) (instance-id 1))
        (observation (start-time 30) (end-time 40) (obsname EUI_FLUSH) (experiment EUI) (module FLUSH) (instance-id 2))
        (observation (start-time 35) (end-time 39) (obsname EUI_FLUSH) (experiment EUI) (module FLUSH) (instance-id 3))
        (observation (start-time 100) (end-time 200) (obsname EUI_FLUSH) (experiment EUI) (module FLUSH) (instance-id 4))
        (observation (start-time 135) (end-time 142) (obsname MAG_EQUAL8) (experiment MAG) (module DEFAULT) (instance-id 5))
        (observation (start-time 100) (end-time 198) (obsname MAG_NORMAL) (experiment MAG) (module DEFAULT) (instance-id 6))
        (observation (start-time 135) (end-time 141) (obsname MAG_LOW) (experiment MAG) (module DEFAULT) (instance-id 7))
        (restriction (name incompatible-observations) (incompat-observations MAG_EQUAL8 EUI_FLUSH))
        (start-calculation))
		
(defrule init 
		=> 
		(assert (start-calculation)))
		
(defrule time-overlap-condition
		?start <- (start-calculation)
		(observation (start-time ?st1) (end-time ?et1) (instance-id ?id1))
		(observation (start-time ?st2) (end-time ?et2&:(overlap-condition ?st1 ?et1 ?st2 ?et2)) (instance-id ?id2&~?id1))
		(not (time-overlapping (instance-1 ?id2) (instance-2 ?id1)))
		=>
		(assert (time-overlapping (instance-1 ?id1) (instance-2 ?id2))))
	
(defrule module-time-overlap-condition
		?tover <- (time-overlapping (instance-1 ?id1) (instance-2 ?id2))
		(observation (module ?n) (instance-id ?id1))
		(observation (module ?n) (instance-id ?id2))
		=>
		(assert (module-time-overlapping (module ?n) (instance-1 ?id1) (instance-2 ?id2))))

(defrule experiment-name-time-overlap-condition
		?tover <- (time-overlapping (instance-1 ?id1) (instance-2 ?id2))
		?o1 <- (observation (obsname ?n1) (instance-id ?id1))
		?o2 <- (observation (obsname ?n2) (instance-id ?id2))
		(restriction (name ?rn) (incompat-observations ?n1 ?n2))
		=>
		(assert (experiment-name-time-overlapping (restriction-name ?rn) (instance-1 ?id1) (instance-2 ?id2))))        		 		