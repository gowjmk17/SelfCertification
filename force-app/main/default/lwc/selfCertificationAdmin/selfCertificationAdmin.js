import { LightningElement, wire, track } from 'lwc';

import getCertifications from '@salesforce/apex/SelfCertificationDataTableController.getCertifications';

const columns = [
    { label: 'Country', fieldName: 'Country__c' },
    { label: 'Certification Date', fieldName: 'Certification_Date__c', type: 'date' },
    { label: 'Certified By', fieldName: 'Certified_By_Name', type: 'text' },
    { label: 'Status', fieldName: 'Status__c' }
];

export default class SelfCertificationAdmin extends LightningElement {
    @track certColumns = columns;
    @track certifications = [];
    @track paginatedData = [];
    @track initialRecords = [];
    @track searchText = '';
    @track error;
    @track selectedRows = [];

    @track pageSize = '10';
    @track currentPage = 1;
    totalPages = 0;

    @wire(getCertifications)
    wiredCertifications({ error, data }) {
        if (data) {
            const decorated = this.decorateData(data);
            this.certifications = decorated;
            this.initialRecords = decorated;
            this.totalPages = Math.ceil(this.certifications.length / parseInt(this.pageSize, 10));
            this.currentPage = 1;
            this.paginatedData = this.certifications.slice(0, parseInt(this.pageSize, 10));
//            this.updatePaginatedData();
            
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.certifications = [];
            this.paginatedData = [];
            this.initialRecords = [];
        }
    }

    decorateData(records) {
        return records.map(rec => ({
            ...rec,
            Certified_By_Name: rec.Certified_By__r ? rec.Certified_By__r.Name : ''
        }));
    }

    handleSearch(event) {
        const searchKey = event.target.value ? event.target.value.toLowerCase() : '';

        if (!this.initialRecords) {
            this.certifications = [];
            this.paginatedData = [];
            return;
        }

        if (searchKey) {
            this.certifications = this.initialRecords.filter(record => {
                return Object.values(record).some(val => {
                    const strVal = String(val);
                    return strVal && strVal.toLowerCase().includes(searchKey);
                });
            });
        } else {
            this.certifications = this.initialRecords;
        }

        this.totalPages = Math.ceil(this.certifications.length / parseInt(this.pageSize, 10));
        this.currentPage = 1;
        this.updatePaginatedData();
    }

    get pageSizeOptions() {
        return [
            { label: '10', value: '10' },
            { label: '20', value: '20' },
            { label: '30', value: '30' },
            { label: '40', value: '40' },
            { label: '50', value: '50' }
        ];
    }

    get selectedCount() {
            return this.selectedRows ? this.selectedRows.length : 0;
        }

    get totalCount() {
            return this.paginatedData ? this.paginatedData.length : 0;
        }

        handleRowSelection(event) {
            this.selectedRows = event.detail.selectedRows;
            console.log('Selected Rows:', JSON.parse(JSON.stringify(this.selectedRows)));
        }

    handlePageSizeChange(event) {
        this.pageSize = event.detail.value;
        this.totalPages = Math.ceil(this.certifications.length / parseInt(this.pageSize, 10));
        this.currentPage = 1;
        this.updatePaginatedData();
    }

    updatePaginatedData() {
    if (!this.certifications || this.certifications.length === 0) {
        this.paginatedData = [];
        this.totalPages = 0;
        return;
    }
    const start = (this.currentPage - 1) * parseInt(this.pageSize, 10);
    const end = start + parseInt(this.pageSize, 10);
    this.paginatedData = this.certifications.slice(start, end);

}

    handlePrevious() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.updatePaginatedData();
        }
    }

    handleNext() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.updatePaginatedData();
        }
    }

    get isPreviousDisabled() {
        return this.currentPage === 1;
    }

    get isNextDisabled() {
        return this.currentPage === this.totalPages;
    }

handleTestExport() {
    const data = this.selectedRows;
     const cleanData = JSON.parse(JSON.stringify(data));
    console.log('Selected Rows:', cleanData);    

        if (!data || data.length === 0) {
        alert('No records selected.');
        return;
    }

    let csv = 'Country,Certification Date,Certified By,Status\n';
   cleanData.forEach(row => {
        const country = row.Country__c || '';
        const date = row.Certification_Date__c
            ? new Date(row.Certification_Date__c).toISOString().split('T')[0]
            : '';
        const certifiedBy = row.Certified_By_Name || '';
        const status = row.Status__c || '';

        // Join cells as comma-separated values without surrounding quotes
        csv += `${country},${date},${certifiedBy},${status}\n`;
    });

    const encodedUri = 'data:text/csv;charset=utf-8,' + encodeURIComponent(csv);
    const link = document.createElement('a');
    link.setAttribute('href', encodedUri);
    link.setAttribute('download', 'TestExport.csv');
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
}
    handleRefresh() {

    }
}


