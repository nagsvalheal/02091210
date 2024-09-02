// This LWC is used to create case record for Type - PSP Platform
// To import Libraries
import { LightningElement,api,track } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import { NavigationMixin } from 'lightning/navigation';
// To import Apex Classes
import INSERT_UPDATE_LEAD_CONSENT from '@salesforce/apex/BI_PSPB_CreateSupportCaseCtrl.createCase';
import UPDATE_CASE from '@salesforce/apex/BI_PSPB_SupportCenterCtrl.updateCase';
import UPDATE_DRAFT from '@salesforce/apex/BI_PSPB_SupportCenterCtrl.updateDraft';
import CASE_DRAFT from '@salesforce/apex/BI_PSPB_CreateSupportCaseCtrl.caseDraft';
import CASE_RECORDS_GET from '@salesforce/apex/BI_PSPB_DraftSupportCtrl.getPSPCaseRecordsPlatformSupport';
import ENROLLE_GET from '@salesforce/apex/BI_PSP_ChallengeEnrolleCtrl.getEnrolle';
import{support} from 'c/biPspbSupportCaseResources';
import getSavedImageUrls from '@salesforce/apex/BI_PSPB_PatientCasesFilesCtrl.getSavedImageUrls';
import saveFilesToCase from '@salesforce/apex/BI_PSPB_PatientCasesFilesCtrl.saveFilesToCase';
import deleteFile from '@salesforce/apex/BI_PSPB_PatientCasesFilesCtrl.deleteFile';
export default class BiPspbPlatformSupport extends NavigationMixin(LightningElement)
{
	//Proper naming conventions with camel case for all the variable will be followed in the future releases
	// Declaration of variables with @api
	
	@api recordId; // Pass the record ID if applicable
	@api caseId; // Expose caseId as a public property
    @track fileSizes = []; // Track file sizes
	@track imageUrls = [];
    @track previewUrls = [];
    @track isLimitReached = false;
	@track fileUploads = [];
	InputOne = true;
	InputTwo = false;
	sizeOfFiles;

	sizeOfMb;
	maximumLimit = false;
	// Declaration of variables with @track
	uploadDisable = false;
	symptomCompleteTick = support.ARROW_IMG;
	showSpinner = true;
	casePopup = false;
	draftPopup = false;
	platformSuppport = support.PLATFORM_HEAD;
	descriptionErr = support.DESCRIPTION_ERROR;
	descritionErrChar = support.DESCRIPTION_ERROR_CHAR;
	backValue = support.BACK;
	createCase = support.CREATE_CASE;
	createDraft = support.CREATE_DRAFT;
	maxLimit =support.MAX_LIMIT;
	browesAndUpload = support.BROWS_AND_UPLOAD;
	fiveMb = support.FIVEMB;
	attachment = support.ATTACHMENT;
	descriptionValue = support.DESCRIPTION;
	successMsg = support.SUCCESS_MSG;
	successMessage  = support.SUCCESS_MESSAGE;
	urlq;
	showDivSubmit = false;
	showDivDraft = false;
	fileIcon = support.MY_ICON;
	isFormVisible = false;
	isFormVisibleOne = false;
	isFormVisibleTwo = false;
	isFormVisibleThree = false;
	fieldOne = '';
	fieldTwo = '';
	subTypError = false;
	descriptionError = false;
	files = [];
	back = false;
	// to invoke CSS '' are useed
	classFive = 'desc';
	contact = true;
	selectedOption;
	userId = support.ID;
	accName;
	fileName;
	caseRecord;
	caseMedicalId = null;
	caseType;
	medicalSubType;
	medicalDescription;
	selectedOptionValues;
	description = '';
	medicalDataGet;
	descriptionLengthError = false;
	browserName = true;
	fileNames;
	showFileNames = false;
	radioBtnColorChange = ''
	caseSubType;
	dataValue;
	caseDescription;
	selectedItemId;
	// Declaration of variables
	rightImg = support.TIC;
	iconWarning = support.WARNING;
	buttonImage = support.IMG;
	backArrow = support.ARROW;
	parametershnImg = support.PHN_IMG;
	emailImg = support.EMAIL_IMG;
	pdfFile = support.PDF_IMG;
	subType = ''; // Initialize with an empty string
	caseRecordId;
	isButtonDisabled = false;
	isSubmitButtonDisabled;

	handleFileInputChange(event) {
		const files = event.target.files;
		let totalSize = 0;

		// Calculate the total size of all selected files
		for (let i = 0; i < files.length; i++) {
			totalSize += files[i].size;
		}
		// Get current total size of existing files
		const currentTotalSize = this.getCurrentTotalSize(); 
		
	
		// Check if file limit is reached
		if (files.length + this.fileUploads.length > 3) {
			this.isLimitReached = true;
			console.warn('File upload limit reached. Maximum of 3 files allowed.');
			event.target.value = null; // Reset the file input
			return;
		}
	
		// Check if total size exceeds 5 MB (5 * 1024 * 1024 bytes)
		if (totalSize + currentTotalSize > 5 * 1024 * 1024) {
			this.maximumLimit = true;
			console.error('Total file size exceeds 5 MB limit.');
			event.target.value = null; // Reset the file input
			return;
		}
		
		this.isLimitReached = false;
		this.maximumLimit = false;
	
		const promises = [];
	
		// Process each file
		for (let i = 0; i < files.length; i++) {
			const file = files[i];
	
			// Check if the file type is PDF
			if (file.type === 'application/pdf') {
				this.pdfImg = true;
			}
			else{
				this.pdfImg = false;
			}
			// Convert the file to base64
			promises.push(this.readFileAsBase64(file));
		}
	
		// Once all files are processed
		Promise.all(promises)
			.then(results => {
				// Validate results and update preview URLs and file uploads
				const validResults = results.filter(result => result && result.base64Data && result.fileName);
	
				// Update previews and files
				validResults.forEach(result => {
					// Add file to previewUrls
					this.previewUrls = [...this.previewUrls, result.dataUrl];
	
					// Add file to fileUploads
					this.fileUploads = [...this.fileUploads, {
						fileData: result.base64Data,
						fileName: result.fileName
					}];
				});
			})
			.catch(error => {
				console.error('Error reading files:', error);
			});
			
		
	}
	handleFileInputPre(event) {
		const files = event.target.files;
		let totalSize = 0;
		// Calculate the total size of all selected files
		for (let i = 0; i < files.length; i++) {
			const fileSizeInMB = files[i].size / (1024 * 1024); // Convert file size to MB
			if (fileSizeInMB > 5) { // Check if any individual file exceeds 5 MB
				console.error(`File "${files[i].name}" exceeds the 5 MB limit.`);
				event.target.value = null; // Reset the file input
				return;
			}
			totalSize += files[i].size;
		}
	
		// Get the current total size of existing files
		const currentTotalSize = this.getCurrentTotalSize();
		const currentTotalFilesCount = this.fileUploads.length + this.sizeOfFiles.length;
	
		// Check if the file limit is reached
		if (files.length + currentTotalFilesCount > 3) {
			this.isLimitReached = true;
			console.warn('File upload limit reached. Maximum of 3 files allowed.');
			event.target.value = null; // Reset the file input
			return;
		}
	
		// Check if the total size exceeds 5 MB (5 * 1024 * 1024 bytes)
		if (totalSize + currentTotalSize > 5 * 1024 * 1024) {
			this.maximumLimit = true;
			console.error('Total file size exceeds 5 MB limit.');
			event.target.value = null; // Reset the file input
			return;
		}
	
		this.isLimitReached = false;
		this.maximumLimit = false;
	
		const promises = [];
	
		// Process each file
		for (let i = 0; i < files.length; i++) {
			const file = files[i];
	
			// Check if the file type is PDF
			if (file.type === 'application/pdf') {
				this.pdfImg = true;
			}
			else{
				this.pdfImg = false;
			}
	
			// Convert the file to base64
			promises.push(this.readFileAsBase64(file));
		}
	
		// Once all files are processed
		Promise.all(promises)
			.then(results => {
				// Validate results and update preview URLs and file uploads
				const validResults = results.filter(result => result && result.base64Data && result.fileName);
	
				// Update previews and files
				validResults.forEach(result => {
					// Add file to previewUrls
					this.previewUrls = [...this.previewUrls, result.dataUrl];
	
					// Add file to fileUploads
					this.fileUploads = [...this.fileUploads, {
						fileData: result.base64Data,
						fileName: result.fileName
					}];
				});
			})
			.catch(error => {
				console.error('Error reading files:', error);
			});
	}
	
	// Function to read file as base64
	readFileAsBase64(file) {
		return new Promise((resolve, reject) => {
			const reader = new FileReader();
			reader.onload = () => {
				resolve({
					base64Data: reader.result.split(',')[1],
					dataUrl: reader.result,
					fileName: file.name
				});
			};
			reader.onerror = reject;
			reader.readAsDataURL(file); // Read file as data URL
		});
	}
	
	// Function to get the current total size of uploaded files
	getCurrentTotalSize() {
		// Calculate total size of fileUploads array assuming base64 encoded files
		return this.fileUploads.reduce((total, file) => {
			
			return total + (file.fileData.length * 3 / 4) - (file.fileData.endsWith('==') ? 2 : (file.fileData.endsWith('=') ? 1 : 0));
		}, 0);
	}
	
	


removeImage(event) {
    const index = parseInt(event.target.dataset.index, 10);
	this.isLimitReached = false;
    // Check if the index is within bounds of the local file uploads list
    if (index >= 0 && index < this.fileUploads.length) {
        // Handle deletion for newly uploaded files
        this.fileUploads = this.fileUploads.filter((_, i) => i !== index);
        this.previewUrls = this.previewUrls.filter((_, i) => i !== index);
        // Dispatch an event to notify that a file was deleted
        this.dispatchEvent(new CustomEvent('filedeleted', {
            detail: { index, type: 'uploaded' },
        }));
    } 
    // Adjust index for prepopulated images
    else {
        const adjustedIndex = index - this.fileUploads.length;

        if (adjustedIndex >= 0 && adjustedIndex < this.imageData.length) {
            // Retrieve the image data to be removed
            const fileIdToRemove = this.imageData[adjustedIndex].id;

            // Call deleteFile method with the correct fileId
            deleteFile({ caseId: this.caseMedicalId, fileId: fileIdToRemove })
                .then(() => {

                    // Update the image lists after successful deletion
                    this.imageUrls = this.imageUrls.filter((_, i) => i !== adjustedIndex);
                    this.previewUrls = this.previewUrls.filter((_, i) => i !== adjustedIndex);
                    this.imageData = this.imageData.filter((_, i) => i !== adjustedIndex);

                    // Dispatch an event to notify that a file was deleted
                    this.dispatchEvent(new CustomEvent('filedeleted', {
                        detail: { index: adjustedIndex, type: 'prepopulated' },
                    }));
                })
                .catch(error => {
                    console.error('Error deleting file:', error);
                });
        } else {
            console.error('Invalid index:', index);
        }
    }
}






	
	connectedCallback() {
		let globalThis = window;
		this.selectedItemId = globalThis.sessionStorage.getItem(
			"caseRecordId"
		);
		
		globalThis?.addEventListener('beforeunload', this.handlePageRefresh);

		this.loadCaseRecords();
		loadStyle(this, support.CASE_RADIO_BTN);
		try {
			this.detectBrandedOrUnassigned();

			ENROLLE_GET({ userId: this.userId })
				.then(result => {

					if (result !== null) {

						if (result[0].patientEnrolle !== null) {
							this.accName = result[0].patientEnrolle.Id;
						} else if (result[0].error !== null) {
							this.showError = true;
							this.errorMessage = result[0].error;
						}
						this.showSpinner = false;
					}
				})
				// Null data is checked and AuraHandledException is thrown from the Apex
				.catch(error => {
					this.navigateToAnotherPage(support.ENROLL_NOT_GET,error.message);
				})
		} catch (error) {
			this.navigateToAnotherPage(error.message);
		}
	}
	handlePageRefresh() {
		let globalThis = window;
		globalThis.sessionStorage?.clear();

	}
	ClosePopup(){
		this.casePopup = false;
		this.draftPopup = false;
		this.isButtonDisabled = false;
		this.isSubmitButtonDisabled = false;
	}
	loadCaseRecords() {
		const promise = CASE_RECORDS_GET({ accountId: this.selectedItemId });
	
		// Manually resolve the promise
		promise.then(data => {
			if (data && data.length > 0) {
				this.caseRecord = data[0];
				this.caseMedicalId = data[0].Id;
				this.caseType = data[0].Type;
				this.description1 = data[0].Description;
				this.selectedOptionValues = data[0].BI_PSPB_Sub_Type__c;
				this.selectedOption = this.selectedOptionValues;
				this.description = this.description1;
				this.medStatus = data[0].Status;
	
				if (this.medStatus === support.NEED_MORE_INFO) {
					this.isReadOnly = true;
				}
				this.loadSavedImageUrls();
			}

		});
	}



	loadSavedImageUrls() {
		getSavedImageUrls({ caseId: this.caseMedicalId })
			.then(result => {
	
	
				if (Array.isArray(result) && result.length > 0) {
					this.InputOne = false;
					this.InputTwo = true;
					
					// Store image data with URLs, IDs, sizes, lengths, and types
					this.imageData = result;
	
					// Create URLs array for preview and handle file type
					this.imageUrls = this.imageData.map(item => {
						if (item.type === 'PDF') {
							// Replace URL with static image URL for PDFs
							return support.PDF_IMG;
						}
						return item.url;
					});
		
	
					// Extract IDs, sizes, and lengths
					this.imageIds = this.imageData.map(item => {
		
						return item.id;
					});
	
					// Handle sizes and lengths
					this.sizeOfMb = this.imageData.map(item => item.size); // in MB
					this.sizeOfFiles = this.imageData.map(item => item.length);
	
	
					// Convert image URLs to data URLs
					const promises = this.imageUrls.map(url => this.convertToDataURL(url));
	
					Promise.all(promises)
						.then(dataUrls => {
							this.previewUrls = dataUrls;
						})
						.catch(error => {
							console.error('Error converting image URLs to data URLs:', error);
						});
				} else {
					console.error('Result is not an array or is empty:', result);
				}
			})
			.catch(error => {
				console.error('Error fetching image URLs:', error);
			});
	}

	convertToDataURL(url) {
		return new Promise((resolve, reject) => {
			fetch(url)
				.then(response => response.blob())
				.then(blob => {
					const reader = new FileReader();
					reader.onloadend = () => {
						resolve(reader.result);
					};
					reader.onerror = reject;
					reader.readAsDataURL(blob);
				})
				.catch(reject);
		});
	}
handleRadioChange(event) {
		this.selectedOption = event.target.value;
		this.subTypError = false;
}
handleDescriptionErr(){
	this.classFive = 'change';
	this.template.querySelector("div[data-field='desc']").className = 'input-error-label';
}
handleDescription(){
	this.classFive = 'desc';
	this.template.querySelector("div[data-field='desc']").className = 'input-label';
}
	handledescription(event) {
		this.description = event.target.value;
		if (this.description === '') {
			this.descriptionError = true;
			this.descriptionLengthError = false;
			// Double quotes can't be avoided since it's invoked from CSS
			this.handleDescriptionErr();
		}
		else {
			this.descriptionError = false;
			this.handleDescription();
			this.descriptionLengthError = false;
			// Double quotes can't be avoided since it's invoked from CSS
			
		}
	}

	handleUploadFinished(event) {
		const UPLOADED_FILES = event.detail.files;
		this.files = UPLOADED_FILES;
		this.fileNames = this.files.map(file => {
			const MAX_LENGTH = 24; // Maximum length of displayed filename
			return file.name.length > MAX_LENGTH ? file.name.substring(0, MAX_LENGTH) + '...' : file.name;
		});
		this.showFileNames = true;
		this.browserName = false;

	}

	handleInsertUpdate(event) {
		
		this.caseType = event.currentTarget.dataset.value;
		const FILE_IDS = this.files.map(file => file.documentId);
		const PARAMETERS = {
			accountId: this.accName,
			type: this.caseType,
			subType: this.selectedOption,
			description: this.description
		};
		if (!this.validateDescription()) {
			return;
		}
		this.processOperation(PARAMETERS, FILE_IDS);
    
	}

	validateDescription() {
		if (!this.description) {
			this.descriptionError = true;
			this.descriptionLengthError = false;
			this.handleDescriptionErr();
			return false;
		}
		else if (this.description.length > 1000) {
			this.descriptionError = false;
			this.descriptionLengthError = true;
			this.handleDescriptionErr();
			return false;
		}
		this.descriptionError = false;
		this.descriptionLengthError = false;
		this.handleDescription();
		return true;
	}
	processOperation(PARAMETERS, FILE_IDS) {
		const globalThis = window;
		if (this.caseMedicalId === null) {
			this.insertOrUpdateLeadConsent(PARAMETERS, FILE_IDS, globalThis);
		} else {
			this.updateCase(FILE_IDS, globalThis);
		}
}
	insertOrUpdateLeadConsent(parameters, fileIds, globalThis) {
	try{
		INSERT_UPDATE_LEAD_CONSENT({ wrapper: parameters, fileIds })
		.then(result => {
			saveFilesToCase({ fileUploads: this.fileUploads, caseId: result })
    .then(() => {
        // Handle success
		this.showDivSubmit = true;
		this.showDivDraft = false;
		globalThis?.scrollTo({ top: 0, behavior: 'smooth' });
		this.resetFormState();
		this.casePopup = true;
		this.maximumLimit = false;
		this.isLimitReached = false;
		this.InputOne = true;
		this.InputTwo = false;
		const fileInput = this.template.querySelector('input[type="file"]');
        if (fileInput) {
            fileInput.value = null;  // Reset file input
        }

        this.fileUploads = [];  // Clear fileUploads array
        this.previewUrls = [];  // Clear preview URLs

        this.dispatchEvent(new CustomEvent('filesuploaded', {
            detail: { caseId: result },
        }));
    })
    .catch(error => {
        console.error('Error uploading files:', error);      
    });
			// Handle successful operation
			
		})
	}
	catch(error){
		this.navigateToAnotherPage(support.CASE_NOT_INSERT, error.message);
	}
		} 
		

	updateCase(FILE_IDS, globalThis) {
			try{
				UPDATE_CASE({ recId: this.caseMedicalId, description: this.description,fileIds: FILE_IDS })
				.then(result => {
					saveFilesToCase({ fileUploads: this.fileUploads, caseId: result })
				.then(() => {
				// Handle success
				this.resetFormState();	
				this.casePopup = true;	
				this.maximumLimit = false;
				this.InputOne = true;
				this.InputTwo = false;
		this.isLimitReached = false;		
				globalThis?.scrollTo({ top: 0, behavior: 'smooth' });
				const fileInput = this.template.querySelector('input[type="file"]');
				if (fileInput) {
					fileInput.value = null;  // Reset file input
				}
				this.fileUploads = [];  // Clear fileUploads array
				this.previewUrls = [];  // Clear preview URLs
		
				this.dispatchEvent(new CustomEvent('filesuploaded', {
					detail: { caseId: result },
				}));
			})
			.catch(error => {
				console.error('Error uploading files:', error);      
			});
					// Handle successful operation
				})
				
		}catch(error){
			this.navigateToAnotherPage(support.CASE_NOT_UPDATE, error.message);
		}
		
	}
	resetFormState() {
		this.description = '';
		this.fileNames = '';
		this.browserName = true;
		this.descriptionLengthError = false;
		this.handleDescription();
	}
					
	handleInsertDraft(event) {
		this.caseType = event.currentTarget.dataset.value;
		const FILE_IDS = this.files.map(file => file.documentId);
		const PARAMETERS = {
			accountId: this.accName,
			type: this.caseType,
			subType: this.selectedOption,
			description: this.description
		};
	
		if (!this.validateDescription()) {
			return;
		}
	
		this.processDraftOperation(PARAMETERS, FILE_IDS);
	}
	processDraftOperation(PARAMETERS, FILE_IDS) {
		const globalThis = window;

		if (this.caseMedicalId === null) {
			this.insertDraft(PARAMETERS, FILE_IDS, globalThis);
		} else {
			this.updateDraft(FILE_IDS, globalThis);
		}
	}
	insertDraft(parameters, fileIds, globalThis) {
		this.isButtonDisabled = true;
		this.isSubmitButtonDisabled = true;
	
		try{
			const button = this.template.querySelector('.button2');
			this.dataValue = button.getAttribute('data-value');
			this.callfunction();
			CASE_DRAFT({ wrapper: parameters, fileIds })
			.then(result => {
				saveFilesToCase({ fileUploads: this.fileUploads, caseId: result })
			.then(() => {
			// Handle success
			this.loadCaseRecords();
			this.updateUIAfterInsertDraft(globalThis);
			this.draftPopup = true;
			this.maximumLimit = false;
		this.isLimitReached = false;
		this.InputOne = true;
		this.InputTwo = false;
			const fileInput = this.template.querySelector('input[type="file"]');
			if (fileInput) {
				fileInput.value = null;  // Reset file input
			}
	
			this.fileUploads = [];  // Clear fileUploads array
			this.previewUrls = [];  // Clear preview URLs
	
			this.dispatchEvent(new CustomEvent('filesuploaded', {
				detail: { caseId: result },
			}));
		})
		.catch(error => {
			console.error('Error uploading files:', error);      
		});
				// Handle successful operation
				
			})
			
			
		}
		catch(error){
			this.navigateToAnotherPage(support.DRAFT_NOT_INSERT, error.message);
		}
		
	}
	updateDraft(FILE_IDS, globalThis) {
		try{
			
			UPDATE_DRAFT({
				recId: this.caseMedicalId,
				type: this.selectedOption,
				description: this.description,
				fileIds: FILE_IDS
			})
		.then(result => {
				saveFilesToCase({ fileUploads: this.fileUploads, caseId: result })
		.then(() => {
			// Handle success
			this.updateUIAfterInsertDraft(globalThis);
			this.draftPopup = true;
			this.maximumLimit = false;
		this.isLimitReached = false;
		this.InputOne = true;
		this.InputTwo = false;
			const fileInput = this.template.querySelector('input[type="file"]');
			if (fileInput) {
				fileInput.value = null;  // Reset file input
			}
			this.fileUploads = [];  // Clear fileUploads array
			this.previewUrls = [];  // Clear preview URLs
	
			this.dispatchEvent(new CustomEvent('filesuploaded', {
				detail: { caseId: result },
			}));
		})
		.catch(error => {
			console.error('Error uploading files:', error);      
		});
				// Handle successful operation
				
			})
		
		}catch(error){
			this.navigateToAnotherPage(support.DRAFT_NOT_UPDATE, error.message);
		}
			
	}
	updateUIAfterInsertDraft(globalThis) {
		this.showDivDraft = true;
		this.showDivSubmit = false;
		globalThis?.scrollTo({ top: 0, behavior: 'smooth' });
		this.resetFormState();
	}
			
	callfunction() {
		if (this.showDivDraft === true || this.dataValue) {
			this.isSubmitButtonDisabled = true;
		}
		else {
			this.isSubmitButtonDisabled = false;
		}
	}

	handleBack() {
		let globalThis = window;
		globalThis.location?.assign(this.urlq + support.SUPPORT_PAGE_URL);
	}
	handleclose() {
		this.showDivSubmit = false;
		this.showDivDraft = false;
		this.isButtonDisabled = false;
		this.isSubmitButtonDisabled = false;
	}
	detectBrandedOrUnassigned() {
		let globalThis = window;
		const CURRENT_URL = globalThis.location?.href;
		const URL_OBJECT = new URL(CURRENT_URL);
		const PATH = URL_OBJECT.pathname;
		const PATH_COMPONENTS = PATH.split('/');
		const DESIRED_COMPONENT = PATH_COMPONENTS.find(component =>
			[support.BRANDED_URL.toLowerCase(), support.UNASSIGNED_URL.toLowerCase()].includes(component.toLowerCase())
		);
		//set the url and navigations are done within branded site 
		if (DESIRED_COMPONENT && DESIRED_COMPONENT.toLowerCase() === support.BRANDED_URL.toLowerCase()) {
			this.urlq = support.BRANDED_URL_NAVI;
		}
		//set the url and navigations are done within unassigned site 
		else {
			this.urlq = support.UNASSIGNED_URL_NAVI;
		}
	}
	navigateToAnotherPage(errorMessage){
		let global = window;
		global.location?.assign(this.urlq + support.ERROR_PAGE);
		global.sessionStorage.setItem('errorMessage', errorMessage);
	}

}