trigger QuoteApprovalTrigger on Quote (after insert, after update) {
    
    if(Trigger.isUpdate || Trigger.isInsert) {
        QuoteApprovalTriggerHandler.updateOpportunityAmounts(Trigger.new, Trigger.oldMap, Trigger.isInsert);
    }
}
