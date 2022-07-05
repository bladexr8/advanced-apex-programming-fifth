@istest

public with sharing class TestAutoProgressStage {
    
    @TestSetup
    static void makeData(){
        List<Opportunity> newops = new List<Opportunity>();

        for (Integer x=0; x<10; x++) {
            newops.add(
                new Opportunity(CloseDate = Date.Today().addDays(5),
                    Name = 'optest_' + String.valueOf(x),
                    StageName = 'Prospecting')
            );
        }
        insert newops;
    }

    @istest
    static void TestAutoProgression() {
        List<Opportunity> ops = [SELECT Id, StageName FROM Opportunity];

        Test.startTest();
        System.Debug('Starting TestAutoProgression Test...');

        // update opportunity amount
        Double currentAmount = 40000;
        for (Opportunity op: ops) {
            op.Amount = currentAmount;
            currentAmount += 10000;
        }
        update ops;
        Test.stopTest();

        // check if stage has been progressed correctly
        List<Opportunity> opsResults = [SELECT Id, Amount, StageName FROM Opportunity];

        for (Opportunity op: opsResults) {
            System.assertEquals((op.Amount < 50000) ? 'Prospecting' : 'Qualification', op.StageName);
        }


    }

}
