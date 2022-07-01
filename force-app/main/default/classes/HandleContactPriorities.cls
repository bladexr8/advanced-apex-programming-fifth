// Handles opportunity after-update and opportunity after-insert

public inherited sharing class HandleContactPriorities implements TriggerAPI.ITriggerHandler {

    public static void handleTrigger(TriggerOperation TrigType, List<SObject> newSObjectList, Map<Id, SObject> newSObjectMap, 
    List<SObject> oldSObjectList, Map<ID, SObject> oldSObjectMap)
    {
        // Cast to the correct type
        List<Contact> newList = (List<Contact>)newSObjectList;
        Map<ID, Contact> oldMap = (Map<ID, Contact>)oldSObjectMap;
        Map<ID, Contact> newMap = (Map<ID, Contact>)newSObjectMap;

        // Look for change in contact priority
        List<Contact> ContactsWithChangedPriority5 = new List<Contact>();
        for(Contact ct: newList)
        {
            if(ct.Contact_Priority__c != oldMap.get(ct.id).Contact_Priority__c && ct.Contact_Priority__c > 5)
            {
                ContactsWithChangedPriority5.add(ct);
            }
        }
        // Grab the contact roles if any
        List<OpportunityContactRole> ocrs = [Select Id, ContactID, OpportunityID from OpportunityContactRole where ContactId in :ContactsWithChangedPriority5 And IsPrimary= True];

        // Now get the Opportunities
        // Remeber, there can be more than one opportunity for a contact
        Map<ID, ID> OpportunityIdsToPrimaryContactIds = new Map<ID, ID>();
        for(OpportunityContactRole ocr: ocrs) OpportunityIdsToPrimaryContactIds.put(ocr.OpportunityID, ocr.ContactID);

        // Get the opportunities
        List<Opportunity> ops = [Select ID, Contact_Priority__c from Opportunity where ID in :OpportunityIdsToPrimaryContactIds.keyset()];

        // Build list of ops to update
        List<Opportunity> opsToUpdate = new List<Opportunity>();

        // Build list of new tasks
        List<Task> newTasks = new List<Task>();

        // Update the priorities
        for(Opportunity op: ops)
        {
            Contact theContact = newMap.get(OpportunityIdsToPrimaryContactIds.get(op.id));
            Decimal newPriority = theContact.Contact_Priority__c;
            if(op.Contact_Priority__c == null || op.Contact_Priority__c < theContact.Contact_Priority__c)
            {
                op.Contact_Priority__c = newPriority;
                opsToUpdate.add(op);
                newTasks.add(
                    new Task(OwnerID = theContact.OwnerID, Type='Other', 
                    WhatID = op.ID, Subject = 'Hot Opportunity!', 
                    WhoID = TheContact.id,
                    ActivityDate = Date.Today().AddDays(1) ));
            }
        }

        if(newTasks.size()>0) insert newTasks;

        if(opsToUpdate.size()>0) update opsToUpdate;

    }

    public Boolean CaptureInternalDMLTriggers() { return false; }

    public Boolean HandleAllTriggers() { return false; }

    public Boolean IgnoreApplicationTriggers() { return false; }

    public void InternalTrigger(String objectType, TriggerOperation triggerType, List<SObject> newList, Map<Id, SObject> newMap, 
        List<SObject> oldList, Map<ID, SObject> oldMap) {}
    
}