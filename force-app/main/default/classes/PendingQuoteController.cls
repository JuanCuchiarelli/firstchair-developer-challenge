public without sharing class PendingQuoteController {

    @AuraEnabled(cacheable=true)
    public static List<Quote> getPendingQuotes() {
        try {
            return [
                SELECT Id, 
                       Name, 
                       OpportunityId,
                       Opportunity.Name,
                       Discount__c, 
                       Total_Amount__c,
                       Approval_Status__c
                FROM Quote
                WHERE Approval_Status__c = 'Pending Approval'
                ORDER BY CreatedDate DESC
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving pending quotes: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String approveQuote(Id quoteId) {
        try {
            Quote quoteToApprove = new Quote(
                Id = quoteId,
                Approval_Status__c = 'Approved',
                Approved_DateTime__c = DateTime.now()
            );

            update quoteToApprove;

            return 'Quote approved successfully';
        } catch (Exception e) {
            throw new AuraHandledException(
                'Error approving quote: ' + e.getMessage()
            );
        }
    }
}