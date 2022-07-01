// Handles opportunity after-update and opportunity after-insert
public inherited sharing class FlagHighValueOpportunities implements TriggerAPI.ITriggerHandler {
    
    public void HandleTrigger(TriggerOperation TrigType, List<SObject> newSObjectList, Map<Id, SObject> newSObjectMap, 
    List<SObject> oldSObjectList, Map<ID, SObject> oldSObjectMap)
    {
        // Cast to the correct type
        List<Opportunity> newList = (List<Opportunity>) newSObjectList;
        Map<Id, Opportunity> oldMap = (Map<Id, Opportunity>) oldSObjectMap;

        Set<Id> OpsThatMayNeedContactUpdate = new Set<Id>();

        for (Opportunity op: newList) {
            If ((TrigType == TriggerOperation.AFTER_INSERT || 
                    (oldMap.get(op.id).Amount < 50000) && op.Amount >= 50000))
            {
                OpsThatMayNeedContactUpdate.add(op.id);
            }
        }

        // Get the contacts for these opportunities
        List<OpportunityContactRole> thesePrimaries = [Select ID, ContactID from OpportunityContactRole where OpportunityID in :OpsThatMayNeedContactUpdate And IsPrimary = True];

        // Set the # of opportunities for each contact
        Map<Id, Integer> contactToOps = new Map<Id, Integer>();
        for (OpportunityContactRole ocr: thesePrimaries) {
            Id contactID = ocr.ContactId;
            contactToOps.put(contactID, (contactToOps.containsKey(contactID) ? contactToOps.get(contactID) + 1 : 1));
        }

        // Prepare the update list
        List<Contact> contactsToUpdate = new List<Contact>();
        for (Id contactID: contactToOps.keySet()) {
           contactsToUpdate.add(new Contact(ID = contactID, High_Value_Opportunities__c = contactToOps.get(contactID))); 
        }

        update contactsToUpdate;
    }

}
