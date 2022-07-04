public Inherited sharing class TriggerAPI {
    public interface ITriggerHandler {
        
        // common interface that can be used by every
        // trigger handler

        // method to handle trigger processing
        void HandleTrigger(TriggerOperation triggerType,
            List<SObject> newList,
            Map<Id, SObject> newMap,
            List<SObject> oldList,
            Map<Id, SObject> oldMap);


        // RECOMMENDED Default is for each handler to receive all triggers
        // that result from DML operations that it performs 
        // (CaptureInternalDMLTriggers = true)
        
        // This is due to the fact there is no predicting what triggers 
        // may fire due to other handlers, automation, or code outside
        // of the application, which may have a cascading effect and call
        // more handlers, etc.

        // If by default, every handler receives all triggers that occur during
        // it's own DML Operations, and by default ignores those triggers, this will
        // eliminate most potential side effects - i.e. the default mode for each
        // handler becomes shutting down everything else in the application while it
        // is performing a DML Operation, reducing the risk of reentrancy, chance
        // of side effects and improves performance

        // Individual Handlers can then be enabled based on the needs of the business,
        // by specifying that they should be invoked by all triggers, or by having
        // handlers dispatch directly to each other

        
        // called by the dispatcher to determine if the handler
        // wants to receive all triggers that occur while it is
        // processing. If the handler returns true to this function,
        // and performs a DML operation, all trigger operations will
        // be sent back to the handler's InternalTrigger method - no
        // other handlers will be called
        Boolean CaptureInternalDMLTriggers();

        // called by the dispatcher to determine if a handler wants to
        // receive all triggers even if a handler specifies it wants to
        // capture all triggers by returning true to CaptureInternalDMLTriggers
        Boolean HandleAllTriggers();

        // called by handler if application wants to ignore application sourced
        // triggers even if they are not being captured by another handler
        Boolean IgnoreApplicationTriggers();

        // called by triggers that are captured by a handler when 
        // CaptureInternalDMLTriggers is specified. Unlike HandleTrigger,
        // this includes an objectType parameter because it is invoked
        // for all triggers that occur during the DML Operation, not just
        // those that this handler is configured to process by custom
        // metadata
        void InternalTrigger(String objectType, TriggerOperation triggerType,
            List<SObject> newList,
            Map<Id, SObject> newMap,
            List<SObject> oldList,
            Map<Id, SObject> oldMap);
    }
}
