

import java.time.LocalDateTime
import java.time.Year
import java.time.temporal.ChronoUnit

class MissionEvent {

    private String name
    private LocalDateTime startTime
    private LocalDateTime endTime
    private Long telemetryRate

    String getName() {
        return name
    }

    LocalDateTime getStartTime() {
        return startTime
    }

    LocalDateTime getEndTime() {
        return endTime
    }

    Long getTelemetryRate() {
        return telemetryRate
    }

    String toClipsFact() {

        def fact = StringBuilder.newInstance()
        fact << "(event (name $name) (start-time $startTime) (end-time $endTime))"

        return fact
    }

    MissionEvent(String name, String startTime, String endTime, Long telemetryRate = 0) {

        this.name = name
        this.startTime = LocalDateTime.parse(startTime)
        this.endTime = LocalDateTime.parse(endTime)
        this.telemetryRate = telemetryRate
    }

    MissionEvent(String name, String startDoyTime, Long duration, Long telemetryRate = 0) {

        String doy = startDoyTime.split("T")[0]
        String timeZ = startDoyTime.split("T")[1]
        String time = timeZ.substring(0,timeZ.length()-1)

        String date = Year.of(Integer.parseInt(doy.split("-")[0])).atDay(Integer.parseInt(doy.split("-")[1]))

        this.name = name
        this.startTime = LocalDateTime.parse(date + "T" + time)
        this.endTime = this.startTime.plus(duration, ChronoUnit.SECONDS)
        this.telemetryRate = telemetryRate
    }
}
