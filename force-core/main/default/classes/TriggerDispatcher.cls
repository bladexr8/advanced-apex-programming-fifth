public Inherited sharing class TriggerDispatcher {
    
    public static void handleTrigger(String objectType,
        TriggerOperation triggerType,
        List<SObject> newList,
        Map<Id, SObject> newMap,
        List<SObject> oldList,
        Map<Id, SObject> oldMap) {
            
        // get the list of trigger handlers to be executed    
        List<TriggerAPI.ITriggerHandler> handlers = getTriggerHandlers(objectType, triggerType);

        // execute the HandleTrigger method for each trigger handler
        for (TriggerAPI.ITriggerHandler handler: handlers) {
            handler.HandleTrigger(triggerType, newList, newMap, oldList, oldMap);
        }
        
        
    }

    // return a list of ITrigger handler objects - trigger handlers that
    // have registered themselves to handle a particular trigger
    private static List<TriggerAPI.ITriggerHandler> getTriggerHandlers(String objectType, 
        TriggerOperation triggerType) {

        String operationType = triggerType.name();

        // query custom metadata for trigger handler objects and prepare an array
        // to hold the results. Note ORDER BY field needs to be included in query, 
        // even if it is unused
        List<Trigger_Handler__mdt> handlers = [SELECT Apex_Class__c, Priority__c
                                                FROM Trigger_Handler__mdt
                                                WHERE Object_Type__c = :objectType 
                                                AND Trigger_Type__c = :operationType
                                                AND Active__c = true 
                                                ORDER BY Priority__c ASC];
        
        // Validate the classes
        List<TriggerAPI.ITriggerHandler> results = new List<TriggerAPI.ITriggerHandler>();
        for (Trigger_Handler__mdt handler: handlers) {
            // create System.Type variable for the trigger handler class
            System.Type theType = Type.forName(handler.Apex_Class__c);
            // try resolving local class
            if (theType == null) theType = Type.forName('', handler.Apex_Class__c);
            // create a new instance of he class using the Type.newInstance() method
            // and check to make sure the object implements the ITriggerHandler
            // interface using the instanceOf operator. When the check is passed,
            // cast the object to ITriggerHandler which allows the rest of the code to
            // treat it as an ITriggerHandler object
            if (theType != null) {
                // create an instance of the trigger handler class
                // and add to results list
                Object theClass = theType.newInstance();
                if (theClass instanceOf TriggerAPI.ITriggerHandler) {
                    results.add((TriggerAPI.ITriggerHandler) theClass);
                }
            }
        }
        return results;
    }


}