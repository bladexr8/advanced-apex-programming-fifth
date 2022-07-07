public without sharing class QueueableApex implements Queueable, Database.AllowsCallouts, Finalizer {
    
    @testvisible
    private static Boolean fakeException = false;
    @testvisible
    private static Boolean errorsProcessed = false;

    private ID currentAsyncRequestId;

    // executed when queuable apex runs
    public void execute(QueueableContext context) {
        
        // On/Off switch
        if (!AppCustomSetting.appEnabled) return;

        // set up finalizer to run once completed
        QueueableApex finalizer = new QueueableApex();
        System.attachFinalizer(finalizer);

        // pick up pending requests that haven't errored
        // from the current user context
        // lock the request record to prevent it
        // being processed multiple times
        List<AsyncRequest__c> requests;
        try {
            requests = [SELECT Id, AsyncType__c, Params__c
                        FROM AsyncRequest__c
                        WHERE Error__c = false 
                        AND CreatedById = :UserInfo.getUserID() 
                        LIMIT 1 FOR UPDATE];
        } catch (Exception ex) {
            return;
        }

        if (requests.size() == 0) {
            return;
        }

        AsyncRequest__c currentRequest = requests[0];
        finalizer.currentAsyncRequestId = currentRequest.id;

        Boolean success = true;

        try {

            // examine AsyncRquest__c field and send processing to appropriate
            // function
            if (currentRequest.AsyncType__c == 'Translate Work Order') {
                success = translate(currentRequest);
            }

            // Add more job types here

            
            // if successful, delete the AsyncRequest__c record
            if (success) {

                // The following will prevent delete errors
                List<AsyncRequest__c> relockRequests = [SELECT Id, AsyncType__c, Params__c
                                                        FROM AsyncRequest__c
                                                        WHERE Error__c = false
                                                        AND Id = :currentRequest.id FOR UPDATE];

                // record not found
                if (relockRequests.size() == 0) {
                    // may need extra error processing here
                    return;
                }

                // remove record as no longer required
                delete currentRequest;

                // optional - immediately empty from recycle bin
                database.emptyRecycleBin(new List<Id>{currentRequest.id});

            }
        } catch (Exception ex) {
            // something went wrong, mark current request record in error
            currentRequest.Error__c = true;
            currentRequest.Error_Message__c = ex.getMessage();
            update currentRequest;
        }

        // for testing
        if (fakeException) {
            Integer x = 0;
            Integer y = 5/x;
        }

        // if another request pending for the user, chain it to
        // current request
        if (!isAsyncRequestPending(currentRequest.id)) return;

        try {
            StartQueueable(context.getJobId());
        } catch (Exception ex) {
            tryToQueue();
        }
    }


    // Determine if another asynch request is pending - which means we should chain
    private static Boolean isAsyncRequestPending(ID currentRequestId)
    {
        
    	List<AsyncRequest__c> moreRequests = [Select ID, AsyncType__c, Params__c 
    		from AsyncRequest__c 
    		where Error__c = false 
    		and ID <> :currentRequestId 
    		and	CreatedById = :UserInfo.getUserId() 
    		Limit 1 ];
        return (moreRequests.size()>0);
        
    }

    // backup mechanism to enqueue request.
    // Note is a future call which is permitted
    // from queuable Apex
    @future
    private static void tryToQueue()
    {
        if(!AppCustomSetting.appEnabled) return; // On/off switch
        try {
            StartQueueable(null);
        }
        catch(Exception ex)
        {
            // Wait for someone else to make a request...
            // Or maybe use scheduled Apex?
        }
    } 


    // check if we can start a queuable job, i.e. limits
    // haven't been reached
    // NOTE: in a multi-project environment this may need to be throttled
    //       through a Custom Setting
    // ensure that we don't add a new queueable job if one already exists
    // for that class and user. This is ok as the chainiing functionality
    // in the "execute" method will pick up pending requests for the user
    public static Id StartQueueable(Id currentJobId) {

        // check on/off switch
        if (!AppCustomSetting.appEnabled) return null;

        List<AsyncApexJob> jobs = [SELECT Id, Status, ExtendedStatus FROM AsyncApexJob
                                    WHERE JobType = 'Queuable' AND (Status='Queued' OR Status='Holding')
                                    AND CreatedById = :userInfo.getUserID() AND 
                                    ApexClass.Name='QueueableApex'];

        // Already have one queued by this user - don't need another
        if (jobs.size()>= 1 || (jobs.size()==1 && jobs[0].id != currentJobId)) return null;

        if (Limits.GetLimitQueueableJobs() - Limits.GetQueueableJobs() > 0) {
            return System.EnqueueJob(new QueueableApex());
        } else {
            return null;
        }
    }



    // iterate over Work Orders, looking at all WO on insert, and those where Description
    // has changed on update.Build a list of Id's and join into a comma separated string, 
    // also breaking into groups of 100 which is current callout limit
    public static void handleTriggerWithQueueable(List<WorkOrder> workOrderList,
            Map<ID, WorkOrder> newMap, Map<ID, WorkOrder> oldMap, TriggerOperation operation) 
    {
        List<AsyncRequest__c> newAsyncRequests = new List<AsyncRequest__c>();
        List<String> textChangedIds = new List<Id>();
        Integer maxIdsPerRequest = 100;

        for (WorkOrder wo : workOrderList) {
            if (operation == TriggerOperation.AFTER_INSERT || wo.Description!= oldMap.get(wo.id).Description)
            {
                textChangedIds.add(wo.id);
            }
            
            // if we have reached callout limit create
            // async request object and restart id list
            if (textChangedIds.size() > maxIdsPerRequest)
            {
                newAsyncRequests.add(
                    new AsyncRequest__c(AsyncType__c = 'Translate Work Order', 
                            Params__c= String.Join(textChangedIds, ','))
                );
                textChangedIds.clear();
            }
        }

        // create a new async request object
        // will either be all WO, or remaining WO
        // from callout limit
        if (textChangedIds.size() > 0) {
            newAsyncRequests.add(
                new AsyncRequest__c(AsyncType__c = 'Translate Work Order', 
                            Params__c= String.Join(textChangedIds, ','))
            );
        }

        if (newAsyncRequests.size() > 0) {
            insert newAsyncRequests;
        }

    }


    // perform the translation
    // note no error handling so exceptions are caught in
    // the calling function
    public Boolean translate(AsyncRequest__c request)
    {
    	Integer allowedCallouts = Limits.getLimitCallouts() - Limits.getCallouts();
		if(allowedCallouts<=0) return false;
		
		List<ID> idsAfterSplit = request.Params__c.split(',');
		
		List<WorkOrder> workOrdersToUpdate = 
			[SELECT ID, Description, DescriptionSpanish__c 
			from WorkOrder 
			where ID in :idsAfterSplit 
			LIMIT :allowedCallouts];
		for(WorkOrder wo: workOrdersToUpdate)
		{
			wo.DescriptionSpanish__c = 
				SimulatedTranslator.translate(wo.Description);
			wo.TranslationPending__c = false;
		}
		update workOrdersToUpdate;
        return true;
    }


    // finalizer fired after every request
    // regardless of result
    public void execute(FinalizerContext ctx)
    {
        System.ParentJobResult result = ctx.getResult();
        if(result== ParentJobResult.UNHANDLED_EXCEPTION)
        {
            Exception ex = ctx.getException();
            system.debug(ex.getTypeName());
            system.debug(ex.getMessage());
            system.debug(currentAsyncRequestId);    // Think about what you can do with this!
            errorsProcessed = true;

            // You can create a queueable here as well! - So if any requests are pending, you can process them
        }
    }

}
