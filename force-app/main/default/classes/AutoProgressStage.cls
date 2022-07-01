public inherited sharing class AutoProgressStage implements TriggerAPI.ITriggerHandler {
    
    // main trigger handle method
    public void HandleTrigger (TriggerOperation TrigType, List<SObject> newSObjectList,
                                Map<Id, SObject> newSObjectMap, List<SObject> oldSObjectList,
                                Map<Id, SObject> oldSObjectMap)
    {
        System.Debug(LoggingLevel.Debug, '***Executing AutoProgressStage->HandleTrigger...');
        
        // Cast to the correct type
        List<Opportunity> newList = (List<Opportunity>) newSObjectList;
        Map<Id, Opportunity> oldMap = (Map<Id, Opportunity>) oldSObjectMap;

        // Progress Opp Stage if criteria fulfilled
        for (Opportunity op: newList) {
            if ((TrigType == TriggerOperation.BEFORE_INSERT || op.Amount != oldMap.get(op.id).Amount)
                && op.Amount >= 50000 && op.StageName == 'Prospecting') {
                    op.StageName = 'Qualification';
                }
        }

        System.Debug(LoggingLevel.Debug, '***FINISHED Executing AutoProgressStage->HandleTrigger...');
    }

}
