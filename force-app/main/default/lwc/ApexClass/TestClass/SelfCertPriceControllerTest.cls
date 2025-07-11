/*
**********************************************************************************************************************
Apex Test Class Name : SelfCertPriceControllerTest

Created Date         : July 11, 2025

@author              : Gowthaman

Description          : 
This test class validates the behavior of SelfCertPriceController,
ensuring the PricingWrapper correctly returns country and pricing data
based on the User's Country and Certification_Price__mdt records.

Note: Uses @SeeAllData=true because Custom Metadata cannot be inserted via DML.
**********************************************************************************************************************
*/

@isTest(SeeAllData=true)
public class SelfCertPriceControllerTest {

    /**
     * @description
     * Tests getPricingDataByUserCountry() when a matching price metadata record exists.
     */
    @isTest
    static void testGetPricingDataWithPrice() {
        // IMPORTANT: You must have Certification_Price__mdt with Country__c = 'TestCountry' in your org
        User testUser = new User(
            Alias = 'testuser',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/New_York',
            Username = 'testuser.' + DateTime.now().getTime() + '@example.com',
            Country = 'TestCountry'
        );
        insert testUser;

        System.runAs(testUser) {
            Test.startTest();
            SelfCertPriceController.PricingWrapper result = SelfCertPriceController.getPricingDataByUserCountry();
            Test.stopTest();

            System.assertNotEquals(null, result, 'Expected a PricingWrapper result');
            System.assertEquals('TestCountry', result.country, 'Expected country to match');
            System.assertNotEquals(null, result.price, 'Expected price from metadata');
            System.debug('PricingWrapper returned: Country=' + result.country + ', Price=' + result.price);
        }
    }

    /**
     * @description
     * Tests getPricingDataByUserCountry() when the user has no country.
     */
    @isTest
    static void testGetPricingDataWithoutUserCountry() {
        User testUser = new User(
            Alias = 'nocontryuser',
            Email = 'nocontryuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'No Country User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/New_York',
            Username = 'nocontryuser.' + DateTime.now().getTime() + '@example.com'
        );
        insert testUser;

        System.runAs(testUser) {
            Test.startTest();
            SelfCertPriceController.PricingWrapper result = SelfCertPriceController.getPricingDataByUserCountry();
            Test.stopTest();

            System.assertNotEquals(null, result, 'Expected a PricingWrapper result');
            System.assertEquals(null, result.country, 'Expected country to be null');
            System.assertEquals(null, result.price, 'Expected price to be null when no country is set');
            System.debug('PricingWrapper returned: Country=' + result.country + ', Price=' + result.price);
        }
    }
}
