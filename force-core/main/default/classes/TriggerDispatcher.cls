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
    private static List<TriggerAPI.ITriggerHandler> getTriggerHandlers(String objectType, TriggerOperation triggerType) {



    }
}
