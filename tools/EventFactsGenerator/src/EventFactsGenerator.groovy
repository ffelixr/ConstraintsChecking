class EventFactsGenerator {

    static String inputFileName
    static String outputFileName = "stdout"

    static void main(String[] args) {

        if (!argumentValidation(args)) {

            usage()
            return
        }

        List<MissionEvent> missionEvents = processInputXmlFile(inputFileName)
        outputFacts(missionEvents)

    }

    static private void outputFacts(List<MissionEvent> mEvents) {

        try {
            def output = System.out
            if (!outputFileName.contains("stdout")) {
                output = new PrintStream(new FileOutputStream(outputFileName))
                System.setOut(output)
            }

            output.println("(deffacts MAIN::events")

            mEvents.forEach() {
                mEvent -> output.println(mEvent.toClipsFact())
            }

            output.append(";; End of deffacts\n)")

        } catch(Exception) {
            println("Execution error. Cannot dump data to output file!")
            System.exit(-1)
        }
    }

    static private List<MissionEvent> processInputXmlFile(String inputFileName) {

        List<MissionEvent> result = new ArrayList<>()
        try {

            def xmlFile = new File(inputFileName)
            def rootNode = new XmlSlurper().parse(xmlFile)
            def eventsNode = rootNode.childNodes().findAll()[1]

            eventsNode.childNodes().findAll().forEach() {

                event -> MissionEvent me = parseEventLine(event); result.add(me)
            }

        } catch (FileNotFoundException fnf) {
            println("Execution error. Input file not found: " + inputFileName)
            System.exit(-1)
        }

        return result
    }

    static private MissionEvent parseEventLine(line) {

        Long duration = 0
        if (line.attributes.size() > 1) {
            duration = Long.parseLong(line.attributes["duration"])
        }

        return new MissionEvent(line.name(), line.attributes["time"], duration);
    }

    static private boolean argumentValidation(String[] arguments) {

        if (arguments.length != 1 && arguments.length != 3)
            return false

        if (arguments[0].contentEquals("-o"))
            return false
        else
            this.inputFileName = arguments[0]

        if (arguments.length == 3 && arguments[1].contentEquals("-o"))
            this.outputFileName = arguments[2]
        else
            return false

        return true
    }

    static private void usage() {

        def usageString = '''
Usage: 
      
      EventFactsGenerator <xml-input-file> [-o <output-file-name>]

      EventFactsGenerator expects an E-FECS xml file as input and generates a deffacts clause for Clips 
      containing the list of events. If the output file name is not specified, the output is shown
      on the standard output
      '''

        println usageString
    }
}
