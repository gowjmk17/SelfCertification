import { LightningElement, wire, track } from 'lwc';

import getCertifications from '@salesforce/apex/SelfCertificationDataTableController.getCertifications';

const columns = [
    { label: 'Country', fieldName: 'Country__c', sortable: "true"},
    { label: 'Certification Date', fieldName: 'Certification_Date__c', type: 'date',
        typeAttributes: {
            day: '2-digit',  month: 'short', year: 'numeric'}, sortable: "true"
        },
    { label: 'Next Due Date', fieldName: 'Next_Due_Date__c', type: 'date',
        typeAttributes: {
            day: '2-digit',  month: 'short', year: 'numeric'}, 
        sortable: "true"},
    { label: 'Certified By', fieldName: 'Certified_By_Name', type: 'text', sortable: "true" },
    { label: 'Status', fieldName: 'Status__c', sortable: "true"}
];

export default class SelfCertificationAdmin extends LightningElement {
    @track certColumns = columns;
    @track certifications = [];
    @track paginatedData = [];
    @track initialRecords = [];
    
    @track error;
    
    @track searchText = '';
    @track noResults = false;
    
    @track selectedRows = [];
    @track pageSize = '10';
    @track currentPage = 1;
    totalPages = 0;
    
    @track sortBy;
    @track sortDirection;

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
            return (
                (record.Country__c && record.Country__c.toLowerCase().includes(searchKey)) ||
                (record.Certified_By_Name && record.Certified_By_Name.toLowerCase().includes(searchKey)) ||
                (record.Status__c && record.Status__c.toLowerCase().includes(searchKey))
            );
        });
    } else {
        this.certifications = this.initialRecords;
    }
    this.noResults = this.certifications.length === 0 && searchKey.trim().length > 0;
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
            { label: '50', value: '50' },
            { label: 'All', value: 'all' }
        ];
    }

    get selectedCount() {
            return this.selectedRows ? this.selectedRows.length : 0;
        }

    get totalCount() {
            return this.paginatedData ? this.paginatedData.length : 0;
        }

  

   handlePageSizeChange(event) {
    this.pageSize = event.detail.value;
    if (this.pageSize === 'all') {
        this.totalPages = 1;
        this.currentPage = 1;
    } else {
        this.totalPages = Math.ceil(this.certifications.length / parseInt(this.pageSize, 10));
        this.currentPage = 1;
    }
    this.updatePaginatedData();
}

  updatePaginatedData() {
    if (!this.certifications || this.certifications.length === 0) {
        this.paginatedData = [];
        this.totalPages = 0;
        return;
    }

    if (this.pageSize === 'all') {
        this.paginatedData = this.certifications;
        this.totalPages = 1;
    } else {
        const start = (this.currentPage - 1) * parseInt(this.pageSize, 10);
        const end = start + parseInt(this.pageSize, 10);
        this.paginatedData = this.certifications.slice(start, end);
        this.totalPages = Math.ceil(this.certifications.length / parseInt(this.pageSize, 10));
    }
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


          handleRowSelection(event) {
          const selected = event.detail.selectedRows;
    this.selectedRows = selected.map(row => row.Id); // only Ids
    this.selectedRowData = selected;                 // full rows
    console.log('Selected Row IDs:', this.selectedRows);
    console.log('Selected Rows Data:', this.selectedRowData);
        }

handleTestExport() {
    const cleanData = this.selectedRowData;

    if (!cleanData || cleanData.length === 0) {
        alert('No records selected.');
        return;
    }

    let csv = 'Country,Certification Date,Certified By,Next Due Date,Status\n';
    cleanData.forEach(row => {
        const country = row.Country__c || '';
        const date = row.Certification_Date__c
            ? new Date(row.Certification_Date__c).toISOString().split('T')[0]
            : '';
        const certifiedBy = row.Certified_By_Name || '';
        const nextDueDate = row.Next_Due_Date__c || '';
        const status = row.Status__c || '';
        csv += `${country},${date},${certifiedBy},${nextDueDate},${status}\n`;
    });

    const encodedUri = 'data:text/csv;charset=utf-8,' + encodeURIComponent(csv);
    const link = document.createElement('a');
    link.setAttribute('href', encodedUri);
    link.setAttribute('download', 'TestExport.csv');
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);

    // Clear selection visually
    this.selectedRows = [];
    this.selectedRowData = [];

    // Force refresh if needed
    const tempData = this.paginatedData;
    this.paginatedData = [];
    Promise.resolve().then(() => {
        this.paginatedData = tempData;
    });
    
}
    

doSorting(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(this.sortBy, this.sortDirection);
    }

      sortData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.paginatedData));
        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
        };
        // cheking reverse direction
        let isReverse = direction === 'asc' ? 1: -1;
        // sorting data
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : ''; // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });
        this.paginatedData = parseData;
    }    

handleRefresh() {
        window.location.reload();
    }
}