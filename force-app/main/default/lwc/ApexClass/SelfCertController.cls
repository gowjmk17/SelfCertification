/*

**********************************************************************************************************************

Apex Class Name    : SelfCertController

Created Date       : July 11, 2025

@author            : Gowthaman

Modification Log:

Ver       Date                      Author                               Modification
1.0       July 11, 2025            Gowthaman                            Initial Version

**********************************************************************************************************************

*/

/**
* @description
* This Apex class handles operations related to self-certification records, including:
* - Retrieving user information for display in Lightning components.
* - Creating self-certification records along with optional file attachments.
*/

public without sharing class SelfCertController {

    /**
    * @description
    * UserInfoWrapper is a data transfer object (DTO) used to return user-related information.
    *
    * @properties
    *   - userName: The user's full name.
    *   - country: The user's country or role if country is not populated.
    */
    public class UserInfoWrapper {
        @AuraEnabled public String userName;
        @AuraEnabled public String country;
    }

    /**
    * @description
    * Retrieves the current user's name and country (or role name if country is not set).
    *
    * @return
    *   A UserInfoWrapper containing:
    *   - userName: The user's full name.
    *   - country: The user's country or role name, or 'N/A' if neither is available.
    */
    @AuraEnabled(cacheable=true)
    public static UserInfoWrapper getUserInfo() {
        User u = [
            SELECT Id, Name, UserRole.Name, Country
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];
        UserInfoWrapper info = new UserInfoWrapper();
        info.userName = u.Name;
        info.country = (u.Country != null)
            ? u.Country
            : (u.UserRole != null ? u.UserRole.Name : 'N/A');
        return info;
    }

    /**
    * @description
    * Creates a new Self Certification record and optionally links an uploaded file to the record.
    *
    * @param country              The country selected by the user.
    * @param certificationPeriod  The certification period (e.g., annual, bi-annual).
    * @param certificationDate    The date of certification.
    * @param comments             Any comments provided by the user.
    * @param confirmation         Indicates if the user confirmed the certification.
    * @param eSignature           Indicates if the user provided an electronic signature.
    * @param contentDocumentId    The Id of the uploaded file to link to the certification (optional).
    *
    * @return
    *   The Id of the newly created Self_Certification__c record.
    */
    @AuraEnabled
    public static Id createSelfCertification(
        String country,
        String certificationPeriod,
        Date certificationDate,
        String comments,
        Boolean confirmation,
        Boolean eSignature,
        String contentDocumentId
    ) {
        // 1) Create the Self Certification record
        Self_Certification__c rec = new Self_Certification__c();
        rec.Country__c = country;
        rec.Comments__c = comments;
        rec.Confirmation__c = confirmation;
        rec.E_signature__c = eSignature;
        rec.Certification_Period__c = certificationPeriod;
        rec.Certification_Date__c = certificationDate;
        rec.Certified_By__c = UserInfo.getUserId();
        rec.Status__c = 'Submitted';
        insert rec;

        // 2) Link the file to the record if a file was uploaded
        if (contentDocumentId != null) {
            insert new ContentDocumentLink(
                ContentDocumentId = contentDocumentId,
                LinkedEntityId = rec.Id,
                ShareType = 'V'
            );
        }

        return rec.Id;
    }
}
