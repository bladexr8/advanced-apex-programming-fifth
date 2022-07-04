@istest
public class TestExecutiveOutreach {
    
    @TestSetup
	public static void initTestObjects()
    {
		Account testact = new Account(Name = 'testaccount');
		insert testact;

		List<Contact>cts = new List<Contact>();    
		for(Integer x=0;x<10;x++)    
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

    }


    // Note here the challenge of testing the insertion condition in this case 

    @istest
    static void TestUpdateHighValueOpsSingle()
    {

        List<Opportunity> ops = [Select ID, Amount, StageName from Opportunity];
        List<Contact> cts = [Select ID from Contact];

        // Add one contact role for each opportunity
        List<OpportunityContactRole> ocrs = new List<OpportunityContactRole>();
        for(Integer x= 0; x<10; x++)
        {
            ocrs.add(new OpportunityContactRole(ContactID = cts[x].id, OpportunityID = ops[x].id, IsPrimary = true));
        }
        insert ocrs;

        Test.startTest();
        system.debug('Starting test');

        for(Opportunity op: ops)
        {
            op.Amount = 50000;
        }
        update ops;
        Test.stopTest();

        List<Task> tasks = [Select ID from Task where OwnerID = :UserInfo.getUserId() And Type='Other' And Subject = 'Executive outreach!'];

        System.assertEquals(0, tasks.size());

    }

    @istest
    static void TestUpdateHighValueOpsMultiple()
    {

        List<Opportunity> ops = [Select ID, Amount, StageName from Opportunity];
        List<Contact> cts = [Select ID from Contact Limit 2];

        // Add one contact role for each opportunity - 5 opportunities on each contact
        List<OpportunityContactRole> ocrs = new List<OpportunityContactRole>();
        for(Integer x= 0; x<10; x++)
        {
            ocrs.add(new OpportunityContactRole(ContactID = cts[(x<5)? 0: 1].id, OpportunityID = ops[x].id, IsPrimary = true));
        }
        insert ocrs;

        Test.startTest();
        system.debug('Starting test');

        for(Opportunity op: ops)
        {
            op.Amount = 50000;
        }
        update ops;
        Test.stopTest();

        List<Task> tasks = [Select ID from Task where OwnerID = :UserInfo.getUserId() And Type='Other' And Subject = 'Executive outreach!'];

        System.assertEquals(2, tasks.size());

    }

    /*@istest
    public static void TestHighValuesOnly()
    {
        List<Contact> cts = [Select ID from Contact];
        
        Test.startTest();
        System.debug('Starting test');
        for(Contact ct: cts) ct.High_Value_Opportunities__c = 5;
        List<Database.SaveResult> results = Database.update(cts, false);
        Test.stopTest();

        // Count successes
        Integer successes = 0;
        for(Database.SaveResult sr: results) if( sr.isSuccess()) successes+=1;

        List<Task> tasks = [Select ID from Task where OwnerID = :UserInfo.getUserId() And Type='Other' And Subject = 'Executive outreach!'];

        System.assertEquals(successes, tasks.size());

    }*/

}