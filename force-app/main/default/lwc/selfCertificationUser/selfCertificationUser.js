import { LightningElement, track, wire } from 'lwc';
import getUserInfo from '@salesforce/apex/SelfCertificationController.getUserInfo';
import createSelfCertification from '@salesforce/apex/SelfCertificationController.createSelfCertification';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class SelfCertificationUser extends LightningElement {
    @track userName = '';
    @track country = '';
    certificationPeriod = new Date().getFullYear();
    @track comments = '';
    @track confirmation = false;
    @track eSignature = false;
    @track recordId;

    

    // Fetch user info
    @wire(getUserInfo)
    wiredUser({ error, data }) {
        if (data) {
            this.userName = data.userName;
            this.country = data.country;
        } else if (error) {
            console.error(error);
        }
    }

    handleCommentsChange(event) {
        this.comments = event.target.value;
    }

    handleConfirmationChange(event) {
        this.confirmation = event.target.checked;
    }

    handleESignatureChange(event) {
        this.eSignature = event.target.checked;
    }

    handleSubmit() {
        if (!this.confirmation || !this.eSignature) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please check confirmation and e-signature boxes.',
                    variant: 'error'
                })
            );
            return;
        }

        createSelfCertification({
            country: this.country,
            comments: this.comments,
            confirmation: this.confirmation,
            eSignature: this.eSignature
        })
        .then(result => {
            this.recordId = result;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Certification submitted successfully.',
                    variant: 'success'
                })
            );
        })
        .catch(error => {
            console.error(error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Error submitting certification.',
                    variant: 'error'
                })
            );
        });
    }

    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        console.log('Uploaded Files:', uploadedFiles);
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'File Upload',
                message: 'File uploaded successfully.',
                variant: 'success'
            })
        );
    }
}
