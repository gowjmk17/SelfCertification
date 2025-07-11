/*

**********************************************************************************************************************

Apex Class Name    : SelfCertEmailReminderBatch

Created Date       : July 11, 2025

@author            : Gowthaman

Modification Log:

Ver       Date                      Author                               Modification
1.0       July 11, 2025            Gowthaman                            Initial Version

**********************************************************************************************************************

*/

/**
* @description
* This Schedulable Apex class is responsible for sending reminder emails about
* pricing certifications that are either overdue or approaching their due date.
* 
* Logic:
* - If the certification is overdue (Next_Due_Date__c = Today - 1), an email is sent to the manager.
* - If the certification is upcoming (Next_Due_Date__c = Today + 30, +15, or +7), an email is sent to the user.
* - Emails include record links for easy access.
*/
global class SelfCertEmailReminderBatch implements Schedulable {

    /**
    * @description
    * Executes the scheduled job, querying certifications matching the target dates
    * and sending notifications to users and managers as appropriate.
    *
    * @param sc The SchedulableContext provided by the system when the job is invoked.
    */
    global void execute(SchedulableContext sc) {
        Date today = Date.today();

        // Fetch certifications matching any of the relevant dates
        List<Self_Certification__c> certs = [
            SELECT Id, Name, Country__c, Certified_By__c, Certified_By__r.Email,
                   Certified_By__r.Manager.Email, Next_Due_Date__c
            FROM Self_Certification__c
            WHERE Status__c = 'Approved'
            AND Next_Due_Date__c IN :new List<Date>{
                today + 30, today + 15, today + 7, today - 1
            }
        ];

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (Self_Certification__c cert : certs) {
            Date dueDate = cert.Next_Due_Date__c;
            Boolean isOverdue = dueDate == today.addDays(-1);
            Boolean isUpcoming = (dueDate == today + 30 || dueDate == today + 15 || dueDate == today + 7);

            if (isOverdue && cert.Certified_By__r.Manager != null && cert.Certified_By__r.Manager.Email != null) {
                // Overdue notification to manager
                Messaging.SingleEmailMessage mgrEmail = new Messaging.SingleEmailMessage();
                mgrEmail.setToAddresses(new List<String>{ cert.Certified_By__r.Manager.Email });
                mgrEmail.setSubject('OVERDUE: Pricing Certification – ' + cert.Country__c);
                mgrEmail.setPlainTextBody(
                    'Hello Manager,\n\n' +
                    'The pricing certification for ' + cert.Country__c +
                    ' assigned to your team member is overdue as of yesterday (' +
                    dueDate.format() + ').\n\n' +
                    'Review here: ' + System.URL.getOrgDomainUrl().toExternalForm() + '/' + cert.Id +
                    '\n\nThank you.'
                );
                emails.add(mgrEmail);
            }

            if (isUpcoming && cert.Certified_By__r.Email != null) {
                // Upcoming notification to user
                Messaging.SingleEmailMessage userEmail = new Messaging.SingleEmailMessage();
                userEmail.setToAddresses(new List<String>{ cert.Certified_By__r.Email });
                userEmail.setSubject('Action Required: Pricing Certification Due – ' + cert.Country__c);
                userEmail.setPlainTextBody(
                    'Hello,\n\n' +
                    'Your pricing certification for ' + cert.Country__c +
                    ' is due on ' + dueDate.format() + '.\n\n' +
                    'Please review and complete it here: ' + System.URL.getOrgDomainUrl().toExternalForm() + '/' + cert.Id +
                    '\n\nThank you.'
                );
                emails.add(userEmail);
            }
        }

        // Send all emails in one call
        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails, false);
        }
    }

    /**
    * @description
    * Schedules this job to run daily at 11:00 AM.
    */
    public static void scheduleDailyJob() {
        String cron = '0 0 11 * * ?'; // Every day at 11 AM
        SelfCertEmailReminderBatch job = new SelfCertEmailReminderBatch();
        System.schedule('Daily Self Cert Email Reminder', cron, job);
    }
}
