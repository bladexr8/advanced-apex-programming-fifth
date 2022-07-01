@istest
public class TestHandleContactPriorities {
    
    @TestSetup
	public static void initTestObjects()
    {
		Account testact = new Account(Name = 'testaccount');
		insert testact;

		List<Contact>cts = new List<Contact>();    
		for(Integer x=0;x<5;x++)    
		{      
			cts.add(new Contact(AccountID = testact.id, LastName = 'cttest_' + String.valueOf(x)));
		}
		
		insert cts;

		List<Opportunity> newOpportunities = new List<Opportunity>();

		for(Integer x=0; x<10; x++)
		{
			newOpportunities.add(
				new Opportunity(AccountID = testact.id, CloseDate = Date.Today().addDays(5), 
						Name = 'optest_' + String.valueOf(x), 
						StageName = 'Prospecting',
                        Amount = 10000 ));	
		}

		insert newOpportunities;

        List<OpportunityContactRole> ocrs = new List<OpportunityContactRole>();
        for(Integer x=0; x<10; x++)
        {
            ocrs.add(New OpportunityContactRole(OpportunityID = newOpportunities[x].id, ContactID = cts[(Integer)(x/2)].id, IsPrimary = true ));
        }
        insert ocrs;

    }


    // Note here the challenge of testing the insertion condition in this case 

    @istest
    static void TestAddPriority()
    {

        List<Contact> cts = [Select ID from Contact];

        Test.startTest();
        system.debug('Starting test');

        for(Contact ct: cts) ct.Contact_Priority__c = 6;

        update cts;

        Test.stopTest();

        List<Contact> contactResults = [Select ID, Contact_Priority__c from Contact where ID in :cts];
        List<Opportunity> opportunityResults = [Select ID, Contact_Priority__c from Opportunity];

        List<Task> tasks = [Select ID from Task where OwnerID = :UserInfo.getUserId() And Type='Other' And Subject = 'Hot Opportunity!'];

        System.assertEquals(opportunityResults.size(), tasks.size());
        for(Opportunity op: opportunityResults) system.assertEquals(6, op.Contact_Priority__c);
    }
}