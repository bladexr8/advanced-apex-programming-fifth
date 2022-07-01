public Inherited sharing class TriggerDispatcher {

    // static reference to currently executing trigger
    public static TriggerAPI.ITriggerHandler currentHandler {
        public get;
        private set;
    }
    
    public static void handleTrigger(String objectType,
        TriggerOperation triggerType,
        List<SObject> newList,
        Map<Id, SObject> newMap,
        List<SObject> oldList,
        Map<Id, SObject> oldMap) 
    {
            
        System.Debug(LoggingLevel.Debug, 'handleTrigger -> ' + objectType + ' -> ' + triggerType);
        
        // get the list of trigger handlers to be executed    
        System.Debug(LoggingLevel.Debug, 'Retrieving Trigger Handlers...');
        List<TriggerAPI.ITriggerHandler> handlers = getTriggerHandlers(objectType, triggerType);

        // trigger handlers retrieved
        for (TriggerAPI.ITriggerHandler hnd : handlers) {
            System.Debug(LoggingLevel.Debug, 'Retrieved Handler:' + hnd);
        }

        // execute the HandleTrigger method for each trigger handler
        // note that trigger handler classes are run synchronously in
        // order retrieved
        System.Debug(LoggingLevel.Debug, '***Executing Trigger Handler Classes...');
        for (TriggerAPI.ITriggerHandler handler: handlers) {

            System.Debug(LoggingLevel.Debug, '***Executing Trigger Handler -> ' + handler + ' ***');

            // keep track of previous trigger fired
            System.Debug(LoggingLevel.Debug, '***Setting previousHandler...');
            TriggerAPI.ITriggerHandler previousHandler = currentHandler;
            System.Debug(LoggingLevel.Debug, 'previousHandler = ' + previousHandler );
            System.Debug(LoggingLevel.Debug, 'currentHandler = ' + currentHandler );

            // set the static class property of current trigger
            System.Debug(LoggingLevel.Debug, '***Setting currentHandler...');
            currentHandler = handler;
            System.Debug(LoggingLevel.Debug, 'previousHandler = ' + previousHandler );
            System.Debug(LoggingLevel.Debug, 'currentHandler = ' + currentHandler );

            // execute the current trigger
            System.Debug(LoggingLevel.Debug,'Invoking ' + handler);
            handler.HandleTrigger(triggerType, newList, newMap, oldList, oldMap);

            System.Debug(LoggingLevel.Debug, '***Setting currentHandler...');
            currentHandler = previousHandler;
            System.Debug(LoggingLevel.Debug, 'previousHandler = ' + previousHandler );
            System.Debug(LoggingLevel.Debug, 'currentHandler = ' + currentHandler );

            System.Debug(LoggingLevel.Debug, '***FINISHED Executing Trigger Handler -> ' + handler + ' ***');
        }
        System.Debug(LoggingLevel.Debug, '***FINISHED Executing Trigger Handler Classes...');
        
        
    }

    // return a list of ITrigger handler objects - trigger handlers that
    // have registered themselves to handle a particular trigger
    private static List<TriggerAPI.ITriggerHandler> getTriggerHandlers(String objectType, 
        TriggerOperation triggerType) {

        String operationType = triggerType.name();

        System.Debug(LoggingLevel.Debug, 'Selecting Active Trigger Handlers for'
            + objectType + ' -> ' + operationType);

        // query custom metadata for trigger handler objects and prepare an array
        // to hold the results. Note ORDER BY field needs to be included in query, 
        // even if it is unused
        List<Trigger_Handler__mdt> handlers = [SELECT Apex_Class__c, Priority__c
                                                FROM Trigger_Handler__mdt
                                                WHERE Object_Type__c = :objectType 
                                                AND Trigger_Type__c = :operationType
                                                AND Active__c = true 
                                                ORDER BY Priority__c ASC];

        System.Debug(LoggingLevel.Debug, 'Found ' + handlers.size() + ' Trigger Handlers...');
        System.Debug(LoggingLevel.Debug, handlers);
        
        // Validate the classes
        System.Debug(LoggingLevel.Debug, 'Creating Trigger Handler Classes...');
        List<TriggerAPI.ITriggerHandler> results = new List<TriggerAPI.ITriggerHandler>();
        for (Trigger_Handler__mdt handler: handlers) {
            System.Debug(LoggingLevel.Debug, 'Creating Trigger Handler Class for ' + handler.Apex_Class__c);
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
        System.Debug(LoggingLevel.Debug, 'Finished Creating Trigger Handler Classes...');
        return results;
    }


}
