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
    }
}
