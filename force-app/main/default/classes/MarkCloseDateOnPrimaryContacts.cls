// Handles opportunity after-update and opportunity after-insert
public inherited sharing class MarkCloseDateOnPrimaryContacts implements TriggerAPI.ITriggerHandler {
    
    public void HandleTrigger(TriggerOperation TrigType, List<SObject> newSObjectList, Map<Id, SObject> newSObjectMap, 
    List<SObject> oldSObjectList, Map<ID, SObject> oldSObjectMap)
    {
        System.Debug(LoggingLevel.Debug, '***Executing MarkCloseDateOnPrimaryContacts->HandleTrigger...');
        
        // Cast to the correct type
        List<Opportunity> newList = (List<Opportunity>)newSObjectList;
        Map<ID, Opportunity> oldMap = (Map<ID, Opportunity>)oldSObjectMap;

        Set<Id> OpsThatMayNeedContactUpdate = new Set<Id>();
        for (Opportunity op: newList) {
            if (TrigType == TriggerOperation.AFTER_INSERT || 
                op.CloseDate != oldMap.get(op.id).CloseDate) {
                    OpsThatMayNeedContactUpdate.add(op.id);
                }
        }

        // get the contacts for these opportunities
        List<OpportunityContactRole> thesePrimaries = [Select ID, ContactID, Opportunity.CloseDate from OpportunityContactRole where OpportunityID in :OpsThatMayNeedContactUpdate And IsPrimary = True];

        // set the last op close date for each contact
        Map<Id, Date> contactToCloseDates = new Map<Id, Date>();
        for (OpportunityContactRole ocr: thesePrimaries) {
            Id contactId = ocr.ContactId;
            if(!contactToCloseDates.containsKey(contactID) || contactToCloseDates.get(contactID) < ocr.Opportunity.CloseDate)
                contactToCloseDates.put(contactID, ocr.Opportunity.CloseDate);
        }

        // Prepare the update list
        // Prepare update list
        List<Contact> contactsToUpdate = new List<Contact>();
        for(ID contactID: contactToCloseDates.keyset()) contactsToUpdate.add(new Contact(ID = contactID, Last_Close_Date__c = contactToCloseDates.get(contactID)));

        update contactsToUpdate;

        System.Debug(LoggingLevel.Debug, '***FINISHED Executing MarkCloseDateOnPrimaryContacts->HandleTrigger...');

    }

}
