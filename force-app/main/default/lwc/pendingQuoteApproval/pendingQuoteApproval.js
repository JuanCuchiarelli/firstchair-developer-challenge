import { LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import getPendingQuotes from '@salesforce/apex/PendingQuoteController.getPendingQuotes';
import approveQuote from '@salesforce/apex/PendingQuoteController.approveQuote';

export default class PendingQuoteApproval extends NavigationMixin(LightningElement) {
    @track quotes = [];
    @track error;
    @track isLoading = false;
    wiredQuotesResult;

    @wire(getPendingQuotes)
    wiredQuotes(result) {
        this.wiredQuotesResult = result;
        
        if (result.data) {
            this.quotes = result.data;
            this.error = undefined;
        } else if (result.error) {
            this.error = 'Error loading quotes: ' + this.reduceErrors(result.error);
            this.quotes = [];
        }
    }

    get hasQuotes() {
        return this.quotes && this.quotes.length > 0;
    }

    get noQuotes() {
        return !this.isLoading && !this.error && this.quotes && this.quotes.length === 0;
    }

    handleNavigateToQuote(event) {
        const recordId = event.target.dataset.recordId;
        
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: 'Quote',
                actionName: 'view'
            }
        });
    }


    handleNavigateToOpportunity(event) {
        const recordId = event.target.dataset.recordId;
        
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: 'Opportunity',
                actionName: 'view'
            }
        });
    }

    handleApprove(event) {
        const quoteId = event.target.dataset.id;
        
        this.isLoading = true;

        approveQuote({ quoteId: quoteId })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Quote approved successfully. Opportunity has been updated.',
                        variant: 'success'
                    })
                );

                return refreshApex(this.wiredQuotesResult);
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error approving quote',
                        message: this.reduceErrors(error),
                        variant: 'error'
                    })
                );
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    reduceErrors(error) {
        if (!error) {
            return 'Unknown error';
        }

        if (Array.isArray(error.body)) {
            return error.body.map(e => e.message).join(', ');
        } else if (typeof error.body.message === 'string') {
            return error.body.message;
        } else if (typeof error.message === 'string') {
            return error.message;
        }

        return JSON.stringify(error);
    }
}