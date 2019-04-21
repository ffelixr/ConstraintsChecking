(deffacts MAIN::observations
        (observation (start-time 10) (end-time 20) (obsname EUI_FLUSH) (experiment EUI) (module FLUSH) (instance-id 1))
        (observation (start-time 30) (end-time 40) (obsname EUI_FLUSH) (experiment EUI) (module FLUSH) (instance-id 2))
        (observation (start-time 35) (end-time 39) (obsname EUI_FLUSH) (experiment EUI) (module FLUSH) (instance-id 3))
        (observation (start-time 100) (end-time 200) (obsname EUI_FLUSH) (experiment EUI) (module FLUSH) (instance-id 4))
        (observation (start-time 135) (end-time 142) (obsname MAG_EQUAL8) (experiment MAG) (module DEFAULT) (instance-id 5))
        (observation (start-time 100) (end-time 198) (obsname MAG_NORMAL) (experiment MAG) (module DEFAULT) (instance-id 6))
        (observation (start-time 135) (end-time 141) (obsname MAG_LOW) (experiment MAG) (module DEFAULT) (instance-id 7))
        (observation (start-time 30) (end-time 40) (obsname MAG_LOW) (experiment MAG) (module DEFAULT) (instance-id 8))
        (observation (start-time 50) (end-time 60) (obsname MAG_HIGH) (experiment MAG) (module DEFAULT) (instance-id 9))
        (restriction-obs-obs (restriction-name cant-overlap-observations) (incompat-observations MAG_EQUAL8 EUI_FLUSH))
        (restriction-obs-obs (restriction-name too-close) (incompat-observations MAG_HIGH EUI_FLUSH) (delta 10))
	;;
	;; Observations that need to be included in an Event window (RSW) to be valid
	;; There should be three additional violations with these observations and current events
	;;
	(observation (start-time 190) (end-time 250) (obsname PHI_RSOBS) (experiment PHI) (module DEFAULT) (instance-id 10))
	(observation (start-time 250) (end-time 350) (obsname PHI_RSOBS) (experiment PHI) (module DEFAULT) (instance-id 11))
	(observation (start-time 350) (end-time 450) (obsname PHI_RSOBS) (experiment PHI) (module DEFAULT) (instance-id 12))
	(observation (start-time 590) (end-time 650) (obsname PHI_RSOBS) (experiment PHI) (module DEFAULT) (instance-id 13))
	(observation (start-time 650) (end-time 750) (obsname PHI_RSOBS) (experiment PHI) (module DEFAULT) (instance-id 14))
	(observation (start-time 750) (end-time 850) (obsname PHI_RSOBS) (experiment PHI) (module DEFAULT) (instance-id 15))

;; Observations that must be performed within a distance range
;; For new violations are expected here

(observation (start-time 800) (end-time 890) (obsname MET_INVENT1) (experiment MET) (module DEFAULT) (instance-id 16))
(observation (start-time 890) (end-time 920) (obsname MET_INVENT1) (experiment MET) (module DEFAULT) (instance-id 17))
(observation (start-time 930) (end-time 1000) (obsname MET_INVENT1) (experiment MET) (module DEFAULT) (instance-id 18))
(observation (start-time 1050) (end-time 1120) (obsname MET_INVENT1) (experiment MET) (module DEFAULT) (instance-id 19))
(observation (start-time 1200) (end-time 1250) (obsname MET_INVENT1) (experiment MET) (module DEFAULT) (instance-id 20))
(restriction-obs-distance-to-sun (restriction-name observation-out-of-distance-range) (observation MET_INVENT1) (distance-range 4350 5227))


;; Observations that cannot be started before being at a specific distance to the sun
;; Two additional violations are expected from this

(observation (start-time 1200) (end-time 1290) (obsname MET_INVENT2) (experiment MET) (module DEFAULT) (instance-id 21))
(observation (start-time 1450) (end-time 1520) (obsname MET_INVENT2) (experiment MET) (module DEFAULT) (instance-id 22))
(observation (start-time 1500) (end-time 1590) (obsname MET_INVENT2) (experiment MET) (module DEFAULT) (instance-id 23))
(restriction-obs-distance-to-sun (restriction-name observation-out-of-distance-range) (observation MET_INVENT2) (distance-range 6816 1000000)))

(deffacts MAIN::events
  (event (eventname RS_WINDOW) (start-time 200) (end-time 400) (occurrence 1) (instance-id 201))
  (event (eventname RS_WINDOW) (start-time 580) (end-time 750) (occurrence 2) (instance-id 202))
  (event (eventname RS_WINDOW) (start-time 1200) (end-time 1350) (occurrence 3) (instance-id 203))
  (event (eventname RS_WINDOW) (start-time 1510) (end-time 1650) (occurrence 4) (instance-id 204))
  (restriction-event-obs (restriction-name obs-in-event-window) (event RS_WINDOW) (observation PHI_RSOBS)))