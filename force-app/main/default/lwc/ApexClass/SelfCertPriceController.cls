/*

**********************************************************************************************************************

Apex Class Name    : SelfCertPriceController

Created Date       : July 11, 2025

@author            : Gowthaman

Modification Log:

Ver       Date                      Author                               Modification
1.0       July 11, 2025            Gowthaman                            Initial Version

**********************************************************************************************************************

*/

/**
* @description
* This Apex class is responsible for retrieving certification pricing information 
* based on the logged-in user's country. The pricing data is stored in the custom 
* metadata type Certification_Price__mdt. It exposes a method for Lightning components 
* to fetch the pricing dynamically.
*/

public class SelfCertPriceController {

    /**
    * @description
    * PricingWrapper is a data transfer object (DTO) used to return the user's country 
    * and the corresponding certification price.
    *
    * @properties
    *   - country: The country name.
    *   - price: The certification price.
    */
    public class PricingWrapper {
        @AuraEnabled public String country;
        @AuraEnabled public Decimal price;

        /**
        * @description Default constructor.
        */
        public PricingWrapper() {}

        /**
        * @description
        * Parameterized constructor to initialize PricingWrapper with values.
        *
        * @param country The country name.
        * @param price   The certification price.
        */
        public PricingWrapper(String country, Decimal price) {
            this.country = country;
            this.price = price;
        }
    }

    /**
    * @description
    * Retrieves the certification pricing data for the logged-in user's country.
    * If the user's country is blank or no pricing record exists for that country,
    * the price is returned as null.
    *
    * @return
    *   A PricingWrapper containing:
    *   - country: The user's country.
    *   - price: The certification price or null if unavailable.
    */
    @AuraEnabled(cacheable=true)
    public static PricingWrapper getPricingDataByUserCountry() {
        // Query User Country
        User currentUser = [
            SELECT Country
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];

        String userCountry = currentUser.Country;

        PricingWrapper result = new PricingWrapper();
        result.country = userCountry;

        if (String.isBlank(userCountry)) {
            // No country, return null price
            result.price = null;
            return result;
        }

        // Query Custom Metadata for the pricing
        List<Certification_Price__mdt> pricingRecords = [
            SELECT Country__c, Prices__c
            FROM Certification_Price__mdt
            WHERE Country__c = :userCountry
            LIMIT 1
        ];

        if (pricingRecords.isEmpty()) {
            // No pricing found
            result.price = null;
        } else {
            result.price = pricingRecords[0].Prices__c;
        }

        return result;
    }
}
