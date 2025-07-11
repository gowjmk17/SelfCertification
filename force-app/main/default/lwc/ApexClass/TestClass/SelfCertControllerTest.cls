/*

**********************************************************************************************************************

Test Class Name    : SelfCertControllerTest

Created Date       : July 17, 2025

@author            : Gowthaman

**********************************************************************************************************************

*/

/**
* @description
* This test class validates the functionality of SelfCertController methods:
* - getUserInfo()
* - createSelfCertification()
*
* It covers scenarios with and without file attachments.
*/
@isTest
public class SelfCertControllerTest {
    
    /**
* @description
* Creates a dummy User with a Role and Country for testing.
*/
    private static User createTestUser() {
        UserRole role = new UserRole(
            Name = 'Test Role',
            DeveloperName = 'Test_Role'
        );
        insert role;
        
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        
        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US',
            Country = 'India',
            UserRoleId = role.Id
        );
        return u;
    }
    
    /**
* @description
* Tests the getUserInfo() method to verify that it returns correct User information.
*/
    @isTest
    static void testGetUserInfo() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            System.debug('Running testGetUserInfo...');
            SelfCertController.UserInfoWrapper info = SelfCertController.getUserInfo();
            System.assertNotEquals(null, info, 'UserInfoWrapper should not be null');
            System.assertEquals(testUser.Name, info.userName, 'User name should match');
            System.assertEquals(testUser.Country, info.country, 'Country should match');
            System.debug('testGetUserInfo PASSED: ' + JSON.serialize(info));
        }
    }
    
    /**
* @description
* Tests createSelfCertification() without ContentDocumentId.
*/
    @isTest
    static void testCreateSelfCertificationWithoutAttachment() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            System.debug('Running testCreateSelfCertificationWithoutAttachment...');
            Date certDate = Date.today();
            Id recId = SelfCertController.createSelfCertification(
                'India',
                '2025',
                certDate,
                'Test comments',
                true,
                true,
                null
            );
            
            System.assertNotEquals(null, recId, 'Returned Id should not be null');
            
            Self_Certification__c cert = [SELECT Id, Country__c, Certification_Period__c, Certification_Date__c, Comments__c, Confirmation__c, E_signature__c, Status__c
                                          FROM Self_Certification__c
                                          WHERE Id = :recId];
            
            System.assertEquals('India', cert.Country__c);
            System.assertEquals('2025', cert.Certification_Period__c);
            System.assertEquals(certDate, cert.Certification_Date__c);
            System.assertEquals('Test comments', cert.Comments__c);
            System.assertEquals(true, cert.Confirmation__c);
            System.assertEquals(true, cert.E_signature__c);
            System.assertEquals('Submitted', cert.Status__c);
            System.debug('testCreateSelfCertificationWithoutAttachment PASSED: record Id = ' + recId);
        }
    }
    
    /**
* @description
* Tests createSelfCertification() with ContentDocumentId.
*/
    @isTest
    static void testCreateSelfCertificationWithAttachment() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            System.debug('Running testCreateSelfCertificationWithAttachment...');
            // Create ContentDocument
            ContentVersion version = new ContentVersion(
                Title = 'TestFile',
                PathOnClient = 'TestFile.txt',
                VersionData = Blob.valueOf('Test Content')
            );
            insert version;
            
            Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :version.Id].ContentDocumentId;
            
            Date certDate = Date.today();
            Id recId = SelfCertController.createSelfCertification(
                'India',
                '2025',
                certDate,
                'Test comments with file',
                true,
                true,
                contentDocumentId
            );
            
            System.assertNotEquals(null, recId, 'Returned Id should not be null');
            
            // Verify Self Certification record
            Self_Certification__c cert = [SELECT Id FROM Self_Certification__c WHERE Id = :recId];
            System.assertNotEquals(null, cert, 'Certification record should exist');
            
            // Verify ContentDocumentLink
            ContentDocumentLink link = [SELECT Id, ContentDocumentId, LinkedEntityId
                                        FROM ContentDocumentLink
                                        WHERE LinkedEntityId = :recId
                                        LIMIT 1];
            
            System.assertEquals(contentDocumentId, link.ContentDocumentId, 'ContentDocumentId should match');
            System.debug('testCreateSelfCertificationWithAttachment PASSED: record Id = ' + recId + ', ContentDocumentId = ' + contentDocumentId);
        }
    }
}
