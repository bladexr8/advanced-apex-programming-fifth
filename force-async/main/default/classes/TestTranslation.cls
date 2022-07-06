@isTest
public class TestTranslation {
    
    @isTest
    public static void TestTranslation() {
        Test.startTest();

        Test.setMock(HttpCalloutMock.class, new SimulatedTranslator.MockTranslator());

        String result = SimulatedTranslator.translate('Hello');

        Test.stopTest();

        System.AssertEquals('Hello in Spanish', result);
    }

}
