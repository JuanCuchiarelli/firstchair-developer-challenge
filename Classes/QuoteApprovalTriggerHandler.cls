public class QuoteApprovalTriggerHandler {
    
    public static void updateOpportunityAmounts(List<Quote> newQuotes, Map<Id, Quote> oldQuoteMap, Boolean isInsert) {
        Set<Id> opportunityIds = collectOpportunityIds(newQuotes, oldQuoteMap, isInsert);
        
        if (opportunityIds.isEmpty()) {
            return;
        }
        findApprovedQuoteAndUpdateOpportunities(opportunityIds);
    }
    
    private static Set<Id> collectOpportunityIds(List<Quote> newQuotes, Map<Id, Quote> oldQuoteMap, Boolean isInsert) {
        Set<Id> opportunityIds = new Set<Id>();
        
        for (Quote q : newQuotes) {            
            if (q.OpportunityId == null) {
                continue;
            }            
            
            if (isInsert && q.Approval_Status__c == 'Approved') {
                opportunityIds.add(q.OpportunityId);
            }            
          
            if (!isInsert && oldQuoteMap != null) {
                Quote oldQuote = oldQuoteMap.get(q.Id);
                if (q.Approval_Status__c == 'Approved' && 
                    oldQuote.Approval_Status__c != 'Approved') {
                    opportunityIds.add(q.OpportunityId);
                }
            }
        }        
        return opportunityIds;
    }
    
    /**
     * Queries and returns the most recently approved Quote per Opportunity
     * 
     * @param approvedOpportunityIds - Set of Opportunity Ids to query
     * @return void - Updates Opportunities directly
     */
    private static void findApprovedQuoteAndUpdateOpportunities(Set<Id> approvedOpportunityIds) {
        List<Quote> approvedQuotes = [
            SELECT Id, OpportunityId, Total_Amount__c, LastModifiedDate
            FROM Quote
            WHERE OpportunityId IN :approvedOpportunityIds
            AND Approval_Status__c = 'Approved'
            ORDER BY Approved_DateTime__c DESC
        ];
        
        Set<Id> mostRecentOpportunityIds = new Set<Id>();
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        
        for (Quote q : approvedQuotes) {
            if (!mostRecentOpportunityIds.contains(q.OpportunityId)) {
                mostRecentOpportunityIds.add(q.OpportunityId);
                Opportunity opp = new Opportunity(Id = q.OpportunityId, Amount = q.Total_Amount__c);
                opportunitiesToUpdate.add(opp);
            }
        }
        
        if (!opportunitiesToUpdate.isEmpty()) {
            update opportunitiesToUpdate;
        }
    }
}
