@istest
public class TestDetectMissingPrimaryContacts {

    @TestSetup
    static void makeData(){
        List<Opportunity> newops = new List<Opportunity>();

        for(Integer x=0; x<10; x++)
        {
            newops.add(
                new Opportunity(CloseDate = Date.Today().addDays(5), 
                        Name = 'optest_' + String.valueOf(x), 
                        StageName = 'Prospecting' ));	
        }
        insert newops;
    }

    @istest
    static void TestTaskCreation()
    {
        List<Opportunity> ops = [Select ID, StageName from Opportunity];
        Test.startTest();
        system.debug('Starting test');

        for(Opportunity op: ops)
        {
            op.StageName = 'Qualification';
        }
        update ops;
        Test.stopTest();
        // Why include where term? More robust in case someone else creates code to create tasks during stage update ...
        List<Task> tasks = [Select ID from Task where OwnerID = :UserInfo.getUserId() And Type='Other' And Subject = 'Assign Primary Contact'];
        System.assertEquals(ops.size(), tasks.size());
    }



}
