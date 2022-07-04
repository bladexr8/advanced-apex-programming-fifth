public inherited sharing class DetectMissingPrimaryContacts implements TriggerAPI.ITriggerHandler {
    
    // If changing stages and no primary contact exists, create a new task to create one
    public void HandleTrigger(TriggerOperation TrigType, List<SObject> newSObjectList, Map<Id, SObject> newSObjectMap, 
    List<SObject> oldSObjectList, Map<ID, SObject> oldSObjectMap)
    {
        // Cast to the correct type
        List<Opportunity> newList = (List<Opportunity>)newSObjectList;
        Map<ID, Opportunity> oldMap = (Map<ID, Opportunity>)oldSObjectMap;

		Map<ID, Opportunity> opportunityIDsWithStagenameChanges = new Map<ID, Opportunity>();
		
		// Get OpportunityContactRoles
		for(Opportunity op: newList)
		{
			if(op.StageName != oldMap.get(op.id).StageName) 
				opportunityIDsWithStagenameChanges.put(op.id, op);
		}
		
		// Quick exit if no processing required
		if(opportunityIDsWithStagenameChanges.size()==0) return;	
			
		// Query for all related OpportunityContactRole
		List<OpportunityContactRole> ocrs = 
			[Select ID, ContactID, IsPrimary, OpportunityID 
			from OpportunityContactRole 
			where OpportunityID in :opportunityIDsWithStagenameChanges.keyset() And IsPrimary = True];

		// Remove the opportunities with primary contacts from the list
		for(OpportunityContactRole ocr: ocrs)
		{
            // Note - because our query only captures primary contact roles, and there can only be one primary contact role
            // on an opportunity, this will never try to remove the same opportunity twice
			if(ocr.IsPrimary) opportunityIDsWithStagenameChanges.remove(ocr.OpportunityID);
		}

		// If no opportunities are left, exit right away
		if(opportunityIDsWithStagenameChanges.size()==0) return;

        // Find out which ones have existing tasks
        List<Task> tasks = 
            [SELECT ID, OwnerID, WhatID, Status, Subject, Type 
            from Task 
            where Type='Other' 
            And WhatID in :opportunityIDsWithStagenameChanges.keyset() 
            And IsClosed = False 
            And Subject = 'Assign Primary Contact'   ];

        // Loop through tasks to build set of opportunity IDs with tasks
        Set<ID> opsWithTasks = new Set<ID>();
        for(Task t: tasks)
        {
            // Get the opportunity
            Opportunity op = opportunityIDsWithStagenameChanges.get(t.WhatID);	
            // Make sure it's assigned to the right person
            if(t.OwnerID == op.OwnerID) opsWithTasks.add(op.ID);	
        }
        // Now create new tasks
        List<Task> newTasks = new List<Task>();
        for(Opportunity op: opportunityIDsWithStagenameChanges.values())
        {
            if(!opsWithTasks.contains(op.id))
            {
                newTasks.add(
                    new Task(OwnerID = op.OwnerID, Type='Other', 
                    WhatID = op.ID, Subject = 'Assign Primary Contact', 
                    ActivityDate = Date.Today().AddDays(3) ));
            }				
        }
        if(newTasks.size()>0) insert newTasks;
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
