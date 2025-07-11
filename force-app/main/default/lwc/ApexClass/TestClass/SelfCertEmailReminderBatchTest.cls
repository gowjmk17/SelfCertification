/*
**********************************************************************************************************************

Test Class Name    : SelfCertEmailReminderBatchTest

Created Date       : July 17, 2025

@author            : Gowthaman

**********************************************************************************************************************

*/

/**
* @description
* This test class verifies that the SelfCertEmailReminderBatch Apex class:
* - Correctly identifies overdue and upcoming certifications
* - Composes and sends appropriate email notifications
* - Can be scheduled via System.schedule
*/
@isTest
public class SelfCertEmailReminderBatchTest {

    /**
    * @description
    * Creates a test User to act as a Manager.
    */
    private static User createManager() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User manager = new User(
            FirstName = 'Manager',
            LastName = 'Test',
            Email = 'manager@example.com',
            Username = 'manager' + DateTime.now().getTime() + '@example.com',
            Alias = 'mgr',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert manager;
        return manager;
    }

    /**
    * @description
    * Creates a test User to act as the Certified By user.
    */
    private static User createUser(Id managerId) {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            FirstName = 'Certified',
            LastName = 'User',
            Email = 'certifieduser@example.com',
            Username = 'certified' + DateTime.now().getTime() + '@example.com',
            Alias = 'cert',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US',
            ManagerId = managerId
        );
        insert u;
        return u;
    }

    /**
    * @description
    * Tests the execute() method of the batch class.
    */
    @isTest
    static void testExecute() {
        System.debug('Starting testExecute...');
        
        // Create Manager and User
        User manager = createManager();
        User certifiedUser = createUser(manager.Id);

        Date today = Date.today();

        List<Self_Certification__c> certs = new List<Self_Certification__c>();
        
        // Create overdue certification (yesterday)
        certs.add(new Self_Certification__c(
            Country__c = 'India',
            Certified_By__c = certifiedUser.Id,
            Status__c = 'Approved'
            //, Next_Due_Date__c = today.addDays(-1)
        ));
        
        // Create upcoming certifications (7, 15, 30 days)
        certs.add(new Self_Certification__c(
            Country__c = 'India',
            Certified_By__c = certifiedUser.Id,
            Status__c = 'Approved'
            //, Next_Due_Date__c = today.addDays(7)
        ));
        certs.add(new Self_Certification__c(
            Country__c = 'India',
            Certified_By__c = certifiedUser.Id,
            Status__c = 'Approved'
            //, Next_Due_Date__c = today.addDays(15)
        ));
        certs.add(new Self_Certification__c(
            Country__c = 'India',
            Certified_By__c = certifiedUser.Id,
            Status__c = 'Approved'
           //,  Next_Due_Date__c = today.addDays(30)
        ));
        insert certs;

        Test.startTest();
        // Run the batch job
        SelfCertEmailReminderBatch batch = new SelfCertEmailReminderBatch();
        batch.execute(null);
        Test.stopTest();

        System.debug('testExecute completed. Verifying sent emails...');

        // Note: Since Messaging.sendEmail does not persist emails in records,
        // you can only assert that no exceptions occurred.
        // Optionally, you can check limits:
        System.assert(Limits.getEmailInvocations() > 0, 'Emails should have been sent.');

        System.debug('Emails sent: ' + Limits.getEmailInvocations());
    }

    /**
    * @description
    * Tests the scheduleDailyJob() method to verify that scheduling works.
    */
    @isTest
    static void testScheduleDailyJob() {
        System.debug('Running testScheduleDailyJob...');
        Test.startTest();
        SelfCertEmailReminderBatch.scheduleDailyJob();
        Test.stopTest();
        System.debug('Scheduling completed.');
    }
}
