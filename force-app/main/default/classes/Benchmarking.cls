@istest
public with sharing class Benchmarking {
    
    private static Integer referenceStartTime;
    private static Integer referenceEndTime;

    private static Integer targetStartTime;
    private static Integer targetEndTime;

    private static void markReferenceStartTime() {
        referenceStartTime = Limits.getCpuTime();
    }

    private static void markReferenceEndTime() {
        referenceEndTime = Limits.getCpuTime();
    }

    private static void markTargetStartTime() {
        targetStartTime = Limits.getCpuTime();
    }

    private static void markTargetEndTime() {
        targetEndTime = Limits.getCpuTime();
    }

    private static void ReportResults(Integer loops) {
        if (targetEndTime == null) markTargetEndTime();

        Integer referenceDuration = referenceEndTime - referenceStartTime;

        Integer targetDuration = targetEndTime - targetStartTime;

        Integer benchmarkResults = targetDuration - referenceDuration;

        // Time in microseconds is duration * 1000 / loops
        Decimal eachItem = benchmarkResults * 1000;
        eachItem /= loops;
        eachItem.setScale(2);

        System.debug(LoggingLevel.ERROR, 'Reference Duration: ' + referenceDuration 
            + ' Target Duration: ' + targetDuration 
            + ' Benchmark Results: ' + benchmarkResults 
            + ' ms or ' + eachItem + ' us per operation');
    }

    @istest
    public static void primitiveTests() {
        Integer v = 0;
        
        // reference loop
        markReferenceStartTime();
        for(Integer x = 0; x < 1000000; x++) {}
        markReferenceEndTime();

        // target timing loop
        markTargetStartTime();
        for (Integer x = 0; x < 1000000; x++) {
            v += 5;
        }

        // report the results
        ReportResults(1000000);
    }

    
}
