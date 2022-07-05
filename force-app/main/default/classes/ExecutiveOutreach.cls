public inherited sharing class ExecutiveOutreach implements TriggerAPI.ITriggerHandler {

    private static Set<Id> executedOnce = new Set<Id>();

    public static void handleTrigger(TriggerOperation TrigType, List<SObject> newSObjectList, Map<Id, SObject> newSObjectMap, 
    List<SObject> oldSObjectList, Map<ID, SObject> oldSObjectMap)
    {
        //Set<ID> executedOnce = LocalStatics.executedOnce;
        

        // Cast to the correct type
        List<Contact> newList = (List<Contact>)newSObjectList;
        Map<ID, Contact> oldMap = (Map<ID, Contact>)oldSObjectMap;

        // Look for change in contact priority
        List<Contact> ContactsWithChangedHighValue = new List<Contact>();
        for(Contact ct: newList)
        {
            if(ct.High_Value_Opportunities__c != oldMap.get(ct.id).High_Value_Opportunities__c && ct.High_Value_Opportunities__c >= 2 
                // && ct.Admin_Automation_Update__c == oldMap.get(ct.id).Admin_Automation_Update__c
                )
            {
                ContactsWithChangedHighValue.add(ct);
            }
        }
        if(ContactsWithChangedHighValue.size()==0) return;

        // Build list of new tasks
        List<Task> newTasks = new List<Task>();

        // Update the priorities
        for(Contact ct: ContactsWithChangedHighValue)
        {
            // only add a new task if the contact hasn't
            // already been processed in this context
            if(executedOnce.contains(ct.id)) continue;
            executedOnce.add(ct.id);
            
            newTasks.add(
                new Task(OwnerID = ct.OwnerID, Type='Other', 
                    Subject = 'Executive outreach!', 
                    WhoID = ct.id,
                    ActivityDate = Date.Today().AddDays(1) ));

        }

        //LocalStatics.executedOnce = executedOnce;   // Update the static list

        insert newTasks;
    }

    public Boolean CaptureInternalDMLTriggers() { return false; }

    public Boolean HandleAllTriggers() { return false; }

    public Boolean IgnoreApplicationTriggers() { return false; }

    public void InternalTrigger(String objectType, TriggerOperation triggerType,
            List<SObject> newList,
            Map<Id, SObject> newMap,
            List<SObject> oldList,
            Map<Id, SObject> oldMap) {}
}
