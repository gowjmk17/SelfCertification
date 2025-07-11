/*
**********************************************************************************************************************
Apex Test Class Name : SelfCertificationDataTableControllerTest

Created Date         : July 11, 2025

@author              : Gowthaman

Description          : 
This test class validates the behavior of SelfCertificationDataTableController,
ensuring that records are correctly retrieved.

**********************************************************************************************************************
*/

@isTest
public class SelfCertificationDataTableControllerTest {

    /**
     * @description
     * Creates test data needed for the controller queries.
     */
    static void createTestData() {
        // Create a User to associate as Certified_By__c
        User u = new User(
            Alias = 'testuser',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/New_York',
            Username = 'testuser.' + DateTime.now().getTime() + '@example.com'
        );
        insert u;

        // Create test Self Certification records (no Next_Due_Date__c)
        List<Self_Certification__c> certs = new List<Self_Certification__c>{
            new Self_Certification__c(
                Country__c = 'India',
                Certification_Date__c = Date.today(),
                Status__c = 'Approved',
                Certified_By__c = u.Id
            ),
            new Self_Certification__c(
                Country__c = 'USA',
                Certification_Date__c = Date.today(),
                Status__c = 'Submitted',
                Certified_By__c = u.Id
            )
        };
        insert certs;
    }

    /**
     * @description
     * Tests getCertifications() method to verify all records are returned.
     */
    @isTest
    static void testGetCertifications() {
        createTestData();

        Test.startTest();
        List<Self_Certification__c> results = SelfCertificationDataTableController.getCertifications();
        Test.stopTest();

        System.assertNotEquals(0, results.size(), 'Expected at least 1 certification record returned');
        System.debug('Retrieved ' + results.size() + ' certification records.');
    }
}
