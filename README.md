# firstchair-developer-challenge

## Part 1: Declarative Automation (Flow)

**Files**
- QuoteApprovalFlow.flow-meta.xml - Record-Triggered Flow for Quote approval process

I implemented a Record-Triggered Flow as specified in the challenge to handle the Quote approval threshold logic. Flow was chosen because it provides a declarative solution for business rules like discount thresholds and email notifications. The flow triggers when a Quote is created or updated, checks if the Discount__c is 15% or greater, updates the Approval_Status__c to "Pending Approval," and sends an email alert to the Manager. 

## Part 2: Apex Trigger

**Files**
- QuoteApprovalTrigger.trigger - Main trigger on Quote object
- QuoteApprovalTrigger.trigger-meta.xml - Trigger metadata
- QuoteApprovalTriggerHandler.cls - Handler class with business logic
- QuoteApprovalTriggerHandler.cls-meta.xml - Handler metadata
- QuoteApprovalTriggerHandlerTest.cls - Test class (96% coverage)
- QuoteApprovalTriggerHandlerTest.cls-meta.xml - Test class metadata

I implemented a handler pattern to separate concerns and improve testability. The trigger fires on after insert and after update, but only processes Quotes where Approval_Status__c changed to "Approved." To handle bulkification, I used set-based processing: collecting affected Opportunity IDs in a Set, performing a single SOQL query ordered by Approved_DateTime__c DESC, and using a Set to ensure only the most recently approved Quote updates each Opportunity. This approach handles up to 200 Quotes in a single transaction without hitting governor limits.

## Part 3: Lightning Web Component

- pendingQuoteApproval.html - Component template
- pendingQuoteApproval.js - Component JavaScript controller
- pendingQuoteApproval.js-meta.xml - Component metadata
- PendingQuoteController.cls - Apex controller
- PendingQuoteController.cls-meta.xml - Controller metadata
- PendingQuoteControllerTest.cls - Test class (100% coverage)
- PendingQuoteControllerTest.cls-meta.xml - Test class metadata

I created an LWC that displays all pending Quotes in a table. The component uses @wire to automatically refresh data and NavigationMixin for record navigation. When a manager clicks "Approve," it updates the Quote's Approval_Status__c and Approved_DateTime__c, triggering the Part 2 Apex trigger to update the Opportunity Amount. The component is designed to be deployed as an App Page tab in the Sales app, visible only to Sales Managers.
