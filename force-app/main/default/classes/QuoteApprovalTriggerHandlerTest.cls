@isTest
private class QuoteApprovalTriggerHandlerTest {

    @testSetup
    static void setupData() {
        insert new Account(Name = 'Test Account');
    }

    private static Opportunity createOpportunity() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity ' + DateTime.now(),
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Amount = 10000
        );
        insert opp;
        return opp;
    }

    @isTest
    static void testQuoteApprovedOnInsert() {
        Opportunity opp = createOpportunity();

        Test.startTest();
        insert new Quote(
            Name = 'Approved Insert',
            OpportunityId = opp.Id,
            Approval_Status__c = 'Approved',
            Approved_DateTime__c = DateTime.now(),
            Total_Amount__c = 15000
        );
        Test.stopTest();

        Opportunity updatedOpp =
            [SELECT Amount FROM Opportunity WHERE Id = :opp.Id];

        System.assertEquals(15000, updatedOpp.Amount);
    }

    @isTest
    static void testQuoteApprovedOnUpdate() {
        Opportunity opp = createOpportunity();

        Quote q = new Quote(
            Name = 'Pending Quote',
            OpportunityId = opp.Id,
            Approval_Status__c = 'Pending Approval',
            Total_Amount__c = 20000
        );
        insert q;

        Test.startTest();
        q.Approval_Status__c = 'Approved';
        q.Approved_DateTime__c = DateTime.now();
        update q;
        Test.stopTest();

        Opportunity updatedOpp =
            [SELECT Amount FROM Opportunity WHERE Id = :opp.Id];

        System.assertEquals(20000, updatedOpp.Amount);
    }

    @isTest
    static void testNonApprovedQuoteDoesNotUpdate() {
        Opportunity opp = createOpportunity();
        Decimal originalAmount = opp.Amount;

        Test.startTest();
        insert new Quote(
            Name = 'Pending Quote',
            OpportunityId = opp.Id,
            Approval_Status__c = 'Pending Approval',
            Total_Amount__c = 30000
        );
        Test.stopTest();

        Opportunity updatedOpp =
            [SELECT Amount FROM Opportunity WHERE Id = :opp.Id];

        System.assertEquals(originalAmount, updatedOpp.Amount);
    }


    @isTest
    static void testMostRecentApprovedQuoteWins() {
        Opportunity opp = createOpportunity();
        Decimal originalAmount = opp.Amount;
        
        // Create TWO Quotes, both initially Pending Approval
        Quote quote1 = new Quote(
            Name = 'Quote 1',
            OpportunityId = opp.Id,
            Approval_Status__c = 'Pending Approval',
            Total_Amount__c = 30000
        );
        
        Quote quote2 = new Quote(
            Name = 'Quote 2',
            OpportunityId = opp.Id,
            Approval_Status__c = 'Pending Approval',
            Total_Amount__c = 50000
        );
        
        // Insert both Quotes
        insert new List<Quote>{quote1, quote2};
        
        // Opportunity should still have original amount (no Quotes approved yet)
        Opportunity oppAfterInsert = [SELECT Amount FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(originalAmount, oppAfterInsert.Amount, 
            'Opportunity should not change when Quotes are Pending Approval');
        
        // Approve Quote 1 first
        quote1.Approval_Status__c = 'Approved';
        quote1.Approved_DateTime__c = DateTime.now().addMinutes(-10);
        update quote1;
        
        // Opportunity should now have Quote 1's amount
        Opportunity oppAfterQuote1 = [SELECT Amount FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(30000, oppAfterQuote1.Amount, 
            'Opportunity should be updated with Quote 1 amount');
        
        // Now approve Quote 2 (which was modified/approved more recently)
        quote2.Approval_Status__c = 'Approved';
        quote2.Approved_DateTime__c = DateTime.now();
        
        Test.startTest();
        update quote2;
        Test.stopTest();
        
        // Query the Opportunity - should have Quote 2's amount
        // because Quote 2 was approved AFTER Quote 1
        Opportunity finalOpp = [SELECT Amount FROM Opportunity WHERE Id = :opp.Id];
        
        System.assertEquals(50000, finalOpp.Amount, 
            'Opportunity should have Quote 2 amount because it was approved more recently');
    }
    @isTest
    static void testBulkQuoteApproval() {
        Opportunity opp = createOpportunity();

        List<Quote> quotes = new List<Quote>();
        for (Integer i = 0; i < 50; i++) {
            quotes.add(new Quote(
                Name = 'Bulk ' + i,
                OpportunityId = opp.Id,
                Approval_Status__c = 'Pending Approval',
                Total_Amount__c = 5000 + i
            ));
        }
        insert quotes;

        for (Quote q : quotes) {
            q.Approval_Status__c = 'Approved';
            q.Approved_DateTime__c = DateTime.now();
        }

        Test.startTest();
        update quotes;
        Test.stopTest();

        Opportunity updatedOpp =
            [SELECT Amount FROM Opportunity WHERE Id = :opp.Id];

        System.assertNotEquals(10000, updatedOpp.Amount);
    }

    @isTest
    static void testOldApprovedQuoteDoesNotOverwriteNewer() {
        Opportunity opp = createOpportunity();

        insert new Quote(
            Name = 'Newer Quote',
            OpportunityId = opp.Id,
            Approval_Status__c = 'Approved',
            Approved_DateTime__c = DateTime.now(),
            Total_Amount__c = 90000
        );

        Test.startTest();
        insert new Quote(
            Name = 'Older Quote',
            OpportunityId = opp.Id,
            Approval_Status__c = 'Approved',
            Approved_DateTime__c = DateTime.now(),
            Total_Amount__c = 40000
        );
        Test.stopTest();

        Opportunity finalOpp =
            [SELECT Amount FROM Opportunity WHERE Id = :opp.Id];

        System.assertEquals(90000, finalOpp.Amount);
    }

    @isTest
    static void testAlreadyApprovedQuoteUpdateDoesNotReapply() {
        Opportunity opp = createOpportunity();

        Quote q = new Quote(
            Name = 'Approved Quote',
            OpportunityId = opp.Id,
            Approval_Status__c = 'Approved',
            Approved_DateTime__c = DateTime.now(),
            Total_Amount__c = 40000
        );
        insert q;

        q.Total_Amount__c = 45000;

        Test.startTest();
        update q;
        Test.stopTest();

        Opportunity finalOpp =
            [SELECT Amount FROM Opportunity WHERE Id = :opp.Id];

        System.assertEquals(40000, finalOpp.Amount);
    }
}
