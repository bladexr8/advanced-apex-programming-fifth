@istest
public class TestMarkCloseDateOnPrimaryContacts {
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
				new Opportunity(AccountID = testact.id, CloseDate = Date.Today().addDays(x-5), 
						Name = 'optest_' + String.valueOf(x), 
						StageName = 'Prospecting',
                        Amount = 10000 ));	
		}

		insert newOpportunities;

    }


    // Note here the challenge of testing the insertion condition in this case 

    @istest
    static void TestUpdateCloseDatesSingle()
    {

        List<Opportunity> ops = [Select ID, Amount, CloseDate, StageName from Opportunity];
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
            op.CloseDate = op.CloseDate.addDays(1);
        }
        update ops;
        Test.stopTest();

        List<Contact> contactResults = [Select ID, Last_Close_Date__c from Contact where ID in :cts];

        for(Contact ct: contactResults) system.assert(ct.Last_Close_Date__c != null);
    }

    @istest
    static void TestUpdateCloseDatesMultiple()
    {

        List<Opportunity> ops = [Select ID, Amount, CloseDate, StageName from Opportunity];
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
            op.CloseDate = op.CloseDate.addDays(1);
        }
        update ops;
        Test.stopTest();

        List<Contact> contactResults = [Select ID, Last_Close_Date__c from Contact where ID in :cts];

        for(Contact ct: contactResults) 
        {
            if(ct.id == cts[0].id) 
            {
                System.assertEquals(ops[4].CloseDate, ct.Last_Close_Date__c);
            }
            else {
                System.assertEquals(ops[9].CloseDate, ct.Last_Close_Date__c);
            }

        }
    }
}
