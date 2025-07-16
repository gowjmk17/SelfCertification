import { LightningElement, track, wire } from 'lwc';
import getUserInfo from '@salesforce/apex/SelfCertController.getUserInfo';
import createSelfCertification from '@salesforce/apex/SelfCertController.createSelfCertification';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPricingDataByUserCountry from '@salesforce/apex/SelfCertPriceController.getPricingDataByUserCountry';

export default class SelfCertificationUser extends LightningElement {
    @track showForm = true;
    @track submittedRecord = null;
    @track submit = true;
    @track userName = '';
    @track country = '';
    @track price = 'N/A';
    certificationPeriod = '6 month';
    certificationDate = new Date().toISOString().split('T')[0];
    @track comments = '';
    @track confirmation = false;
    @track eSignature = false;
    @track recordId;
    uploadedFileId;          // store ContentDocumentId
    uploadedFileUrl;         // store the file URL
    isUploadDisabled = true;

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

    connectedCallback() {
        getPricingDataByUserCountry()
            .then(result => {
                this.country = result.country;
                this.price = result.price !== null ? result.price.toFixed(2) : 'N/A';
            })
            .catch(error => {
                console.error('Error:', error);
                this.country = 'N/A';
                this.price = 'N/A';
            });
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

    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        if (uploadedFiles && uploadedFiles.length > 0) {
            const file = uploadedFiles[0];
            this.uploadedFileId = file.documentId;
            this.uploadedFileUrl = `/sfc/servlet.shepherd/document/download/${file.documentId}`;
            console.log('Uploaded file:', file);
            console.log('File URL:', this.uploadedFileUrl);

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'File Upload',
                    message: 'File uploaded successfully.',
                    variant: 'success'
                })
            );

            // Enable submit button if you want
            this.isUploadDisabled = false;
        }
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

        if (!this.uploadedFileUrl) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please upload a PDF before submitting.',
                    variant: 'error'
                })
            );
            return;
        }

        createSelfCertification({
            certificationPeriod: this.certificationPeriod,
            certificationDate: this.certificationDate,
            country: this.country,
            comments: this.comments,
            confirmation: this.confirmation,
            eSignature: this.eSignature,
            contentDocumentId: this.uploadedFileId     // Pass the file link
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
       this.showForm = false;     
       this.submittedRecord = {
            userName: this.userName,
            country: this.country,
            certificationPeriod: this.certificationPeriod,
            certificationDate: this.certificationDate,
            comments: this.comments,
            confirmation: this.confirmation,
            eSignature: this.eSignature
        };

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

    handleBack() {
            this.showForm = true;
            this.submittedRecord = null;
            
            // Reset form fields
            this.comments = '';
            this.confirmation = false;
            this.eSignature = false;
            this.uploadedFileId = null;
            this.uploadedFileUrl = null;
            this.isUploadDisabled = true;
            this.recordId = null;

            

    }
    

}