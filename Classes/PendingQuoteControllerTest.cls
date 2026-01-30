@isTest
private class PendingQuoteControllerTest {
    
    @testSetup
    static void setupTestData() {

        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Amount = 10000
        );
        insert testOpp;

        List<Quote> quotes = new List<Quote>();
        for (Integer i = 0; i < 3; i++) {
            quotes.add(new Quote(
                Name = 'Pending Quote ' + i,
                OpportunityId = testOpp.Id,
                Approval_Status__c = 'Pending Approval',
                Discount__c = 10 + i,  
                Total_Amount__c = 20000 + (i * 5000),
                Manager__c = currentUser.Id
            ));
        }
        insert quotes;
        
        Quote approvedQuote = new Quote(
            Name = 'Approved Quote',
            OpportunityId = testOpp.Id,
            Approval_Status__c = 'Approved',
            Approved_DateTime__c = DateTime.now(),
            Discount__c = 10,  
            Total_Amount__c = 50000,
            Manager__c = currentUser.Id
        );
        insert approvedQuote;
    }
    
    @isTest
    static void testGetPendingQuotes() {
        Test.startTest();
        List<Quote> pendingQuotes = PendingQuoteController.getPendingQuotes();
        Test.stopTest();

        System.assertEquals(3, pendingQuotes.size(), 
            'Should return only pending approval Quotes');

        for (Quote q : pendingQuotes) {
            System.assertEquals('Pending Approval', q.Approval_Status__c,
                'All Quotes should have Pending Approval status');
            System.assertNotEquals(null, q.Opportunity.Name,
                'Opportunity Name should be populated');
        }
    }

    @isTest
    static void testGetPendingQuotesEmpty() {

        List<Quote> allQuotes = [SELECT Id FROM Quote WHERE Approval_Status__c = 'Pending Approval'];
        for (Quote q : allQuotes) {
            q.Approval_Status__c = 'Approved';
            q.Approved_DateTime__c = DateTime.now();
        }
        update allQuotes;
        
        Test.startTest();
        List<Quote> pendingQuotes = PendingQuoteController.getPendingQuotes();
        Test.stopTest();
        
        System.assertEquals(0, pendingQuotes.size(),
            'Should return empty list when no pending Quotes');
    }
    
    @isTest
    static void testApproveQuote() {
        Quote pendingQuote = [
            SELECT Id, Approval_Status__c 
            FROM Quote 
            WHERE Approval_Status__c = 'Pending Approval' 
            LIMIT 1
        ];
        
        System.assertEquals('Pending Approval', pendingQuote.Approval_Status__c);
        
        Test.startTest();
        String result = PendingQuoteController.approveQuote(pendingQuote.Id);
        Test.stopTest();

        System.assertEquals('Quote approved successfully', result);

        Quote approvedQuote = [
            SELECT Id, Approval_Status__c, Approved_DateTime__c 
            FROM Quote 
            WHERE Id = :pendingQuote.Id
        ];
        
        System.assertEquals('Approved', approvedQuote.Approval_Status__c,
            'Quote status should be Approved');
        System.assertNotEquals(null, approvedQuote.Approved_DateTime__c,
            'Approved datetime should be set');
    }

    @isTest
    static void testApproveQuoteTriggersFires() {
        Opportunity opp = [SELECT Id, Amount FROM Opportunity LIMIT 1];
        Decimal originalAmount = opp.Amount;
        
        Quote pendingQuote = [
            SELECT Id, Total_Amount__c 
            FROM Quote 
            WHERE Approval_Status__c = 'Pending Approval' 
            LIMIT 1
        ];
        
        Test.startTest();
        PendingQuoteController.approveQuote(pendingQuote.Id);
        Test.stopTest();
        
        Opportunity updatedOpp = [SELECT Amount FROM Opportunity WHERE Id = :opp.Id];
        
        System.assertEquals(pendingQuote.Total_Amount__c, updatedOpp.Amount,
            'Opportunity Amount should be updated by trigger when Quote is approved');
    }
    
}