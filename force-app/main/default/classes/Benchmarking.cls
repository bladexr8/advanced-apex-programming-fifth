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

    private static void ReportResults(String operation, Integer loops) {
        if (targetEndTime == null) markTargetEndTime();

        Integer referenceDuration = referenceEndTime - referenceStartTime;

        Integer targetDuration = targetEndTime - targetStartTime;

        Integer benchmarkResults = targetDuration - referenceDuration;

        // Time in microseconds is duration * 1000 / loops
        Decimal eachItem = benchmarkResults * 1000;
        eachItem /= loops;
        eachItem.setScale(2);

        System.debug(LoggingLevel.ERROR, 'Operation: ' + operation 
            + ' Reference Duration: ' + referenceDuration 
            + ' Target Duration: ' + targetDuration 
            + ' Benchmark Results: ' + benchmarkResults 
            + ' ms or ' + eachItem + ' us per operation');
    }

    /**
     * integer addition in a loop
     */
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
        markTargetEndTime();

        // report the results
        ReportResults('primitiveTests', 1000000);
    }

    /**
     * list memory allocation
     */
     @istest
     public static void testNewAllocate() {
        List<List<Integer>> numbers = new List<List<Integer>>();
        List<Integer> emptyLst = new List<Integer>();

        markReferenceStartTime();

        for (Integer x = 0; x < 1000000; x++) {
            numbers.add(emptyLst);
        }

        markReferenceEndTime();

        markTargetStartTime();

        for (Integer x = 0; x < 1000000; x++) {
            numbers.add(new List<Integer>{x});  // Add a New List
        }

        markTargetEndTime();

        ReportResults('testNewAllocate', 1000000);


     }

     // Benchmark getGlobalDescribe first operation and cached operations
     @istest
     public static void testGlobalDescribe() {
        markReferenceStartTime();
        for(Integer x = 0; x < 1; x++) {
            Map<String, Schema.SObjectType> describeInfo = Schema.getGlobalDescribe();
        }
        markReferenceEndTime();

        // Because it was called once, the following will measure internal caching
        markTargetStartTime();
        for(Integer x = 0; x < 1000; x++) {
            Map<String, Schema.SObjectType> describeInfo = Schema.getGlobalDescribe();
        }
        markTargetEndTime();

        ReportResults('testGlobalDescribe', 1000);
     }

    
}
