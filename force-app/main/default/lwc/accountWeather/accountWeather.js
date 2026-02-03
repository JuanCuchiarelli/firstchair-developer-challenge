import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getWeather from '@salesforce/apex/WeatherController.getWeather';

// Import Account fields
import BILLING_CITY_FIELD from '@salesforce/schema/Account.BillingCity';

export default class AccountWeather extends LightningElement {

    @api recordId;

    weather;
    errorMessage;
    isLoading = false;
    billingCity;

    @wire(getRecord, { 
        recordId: '$recordId', 
        fields: [BILLING_CITY_FIELD] 
    })
    wiredAccount({ error, data }) {
        if (data) {
            this.billingCity = getFieldValue(data, BILLING_CITY_FIELD);
            
            if (this.billingCity) {
                this.fetchWeather();
            } else {
                this.errorMessage = 'No billing city configured for this account. Please update the account\'s billing address.';
                this.weather = null;
            }
        } else if (error) {
            this.errorMessage = 'Unable to load account information: ' + this.reduceErrors(error);
            this.weather = null;
        }
    }

    get hasWeatherData() {
        return !this.isLoading && !this.errorMessage && this.weather;
    }

    get showRefreshButton() {
        return this.billingCity && this.errorMessage;
    }

    fetchWeather() {
        this.isLoading = true;
        this.errorMessage = null;
        this.weather = null;

        getWeather({ city: this.billingCity })
            .then(result => {
                if (result.iconUrl && !result.iconUrl.startsWith('http')) {
                    result.iconUrl = 'https:' + result.iconUrl;
                }
                
                this.weather = result;
                this.errorMessage = null;
               
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Weather data loaded for ' + result.city,
                        variant: 'success'
                    })
                );
            })
            .catch(error => {
                this.weather = null;
                this.errorMessage = this.reduceErrors(error);
                
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error loading weather',
                        message: this.errorMessage,
                        variant: 'error',
                        mode: 'sticky'
                    })
                );
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleRefresh() {
        if (this.billingCity) {
            this.fetchWeather();
        } else {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Cannot Refresh',
                    message: 'No billing city configured for this account',
                    variant: 'warning'
                })
            );
        }
    }

    reduceErrors(error) {
        if (!error) {
            return 'Unknown error';
        }

        if (error.body && typeof error.body.message === 'string') {
            return error.body.message;
        }

        if (Array.isArray(error.body)) {
            return error.body.map(e => e.message).join(', ');
        }

        if (typeof error.message === 'string') {
            return error.message;
        }

        return JSON.stringify(error);
    }
}