// This LWC is used to create case records for Type - Medical Information Enquiry
// To import Libraries
import { LightningElement, api,track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { loadStyle } from 'lightning/platformResourceLoader';
// To import Apex Classes
import INSERT_UPDATE_LEAD_CONSENT from '@salesforce/apex/BI_PSPB_CreateSupportCaseCtrl.createCase';
import UPDATE_CASE from '@salesforce/apex/BI_PSPB_SupportCenterCtrl.updateCase';
import UPDATE_DRAFT from '@salesforce/apex/BI_PSPB_SupportCenterCtrl.updateDraft';
import CASE_DRAFT from '@salesforce/apex/BI_PSPB_CreateSupportCaseCtrl.caseDraft';
import CASE_RECORDS_GET from '@salesforce/apex/BI_PSPB_DraftSupportCtrl.getPSPCaseRecordsMedical';
import ENROLLE_GET from '@salesforce/apex/BI_PSP_ChallengeEnrolleCtrl.getEnrolle';
import getSavedImageUrls from '@salesforce/apex/BI_PSPB_PatientCasesFilesCtrl.getSavedImageUrls';
import saveFilesToCase from '@salesforce/apex/BI_PSPB_PatientCasesFilesCtrl.saveFilesToCase';
import deleteFile from '@salesforce/apex/BI_PSPB_PatientCasesFilesCtrl.deleteFile';
import{support} from 'c/biPspbSupportCaseResources';
export default class BiPspbMedicalInformationEnquiry extends NavigationMixin(LightningElement)
{
	//Proper naming conventions with camel case for all the variable will be followed in the future releases
	// Declaration of variables with @api
	
	@api acceptedFormats = '.jpg,.jpeg,.png,.pdf'; // Set the accepted file formats
	@api recordId; // Pass the record ID if applicable
	@track fileSizes = []; // Track file sizes
	@track imageUrls = [];
    @track previewUrls = [];
    @track isLimitReached = false;
	@track fileUploads = [];
	InputOne = true;
	InputTwo = false;
	sizeOfFiles;
	sizeOfMb;
	symptomCompleteTick = support.ARROW_IMG;
	isLimitReached = false;
	maximumLimit = false;
	// Declaration of variables with @track
	showSpinner = true;
	casePopup = false;
	draftPopup = false;
	medicalInfoHead = support.MEDICAL_HEAD;
	backValue = support.BACK;
	createCase = support.CREATE_CASE;
	createDraft = support.CREATE_DRAFT;
	maxLimit =support.MAX_LIMIT;
	browesAndUpload = support.BROWS_AND_UPLOAD;
	fiveMb = support.FIVEMB;
	attachment = support.ATTACHMENT;
	descriptionValue = support.DESCRIPTION;
	selectType = support.SELECT_TYPE;
	successMsg = support.SUCCESS_MSG;
	successMessage  = support.SUCCESS_MESSAGE;
	// to invoke CSS '' are useed
	back = false;
	classOne = 'buttonbox';
	classTwo = 'buttonbox';
	classThree = 'buttonbox';
	classFour = 'buttonbox';
	classFive = 'desc';
	classSix = 'desc';
	classSeven = 'desc';
	urlq;
	contact = true;
	showCollectButton = true;
	caseType;
	selectedOption;
	userId = support.ID;
	accName;
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
	caseRecord;
	caseMedicalId = null;
	medicalSubType;
	medicalDescription;
	dataValue;
	selectedOptionValues;
	description = '';
	medicalDataGet;
	descriptionLengthError = false;
	browserName = true;
	fileName;
	fileNames;
	showFileNames = false;
	radioBtnColorChange = '';
	faultValue = false;
	filess = [];
	fileDetails = [];
	errorMessage;
	caseSubType;
	caseDescription;
	isReadOnly = false;
	medStatus;
	selectedItemId;
	// Declaration of variables
	rightImg = support.TIC;
	iconWarning = support.WARNING;
	buttonImage = support.IMG;
	backArrow = support.ARROW;
	phnImg = support.PHN_IMG;
	emailImg = support.EMAIL_IMG;
	subType = ''; // Initialize with an empty string
	caseRecordId;
	checkCaseRadiBtn = '';
	isButtonDisabled = false;
	isSubmitButtonDisabled;
	pdfImg = false;
	pdfFile = support.PDF_IMG;
	// used in HTML file
	subTypeErr=support.SUBTYPE_ERROR;
	descriptionErr = support.DESCRIPTION_ERROR;
	descritionErrChar = support.DESCRIPTION_ERROR_CHAR;

	subTypeOptions = [
		{ label: support.PRODUCT, value: support.PRODUCT },
		{ label: support.TREATMENT, value: support.TREATMENT }
	];

	connectedCallback() {
		try {
			this.handleSessionStorage();
			this.addEventListeners();
			this.loadCaseRecords();
			this.loadStyles();
			this.handleEnrollment();
			this.determineDesiredComponent();
		} catch (error) {
			this.navigateToAnotherPage(error.message);
		}
	}
	
	handleSessionStorage() {
		let globalThis = window;
		if (typeof globalThis !== support.UNDIFINED) {
			this.selectedItemId = globalThis.sessionStorage.getItem("caseRecordId");
			
		}
	}
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
			// Base64 string length can be approximated
			// Length in bytes = (Base64 length / 4) * 3 - padding
			return total + (file.fileData.length * 3 / 4) - (file.fileData.endsWith('==') ? 2 : (file.fileData.endsWith('=') ? 1 : 0));
		}, 0);
	}
	
	
removeImage(event) {
    const index = parseInt(event.target.dataset.index, 10);

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




	
	ClosePopup(){
		this.casePopup = false;
		this.draftPopup = false;
		this.isButtonDisabled = false;
		this.isSubmitButtonDisabled = false;
	}
	addEventListeners() {
		let globalThis = window;
		globalThis?.addEventListener('beforeunload', this.handlePageRefresh);
	}
	
	loadStyles() {
		loadStyle(this, support.CASE_RADIO_BTN);
		loadStyle(this, support.RADIO_BTN_COLOR_CHNAGE);
	}
	
	handleEnrollment() {
		ENROLLE_GET()
			.then((result) => {
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
			.catch((error) => {
				this.navigateToAnotherPage(support.ENROLL_NOT_GET,error.message);
			});
	}
	
	determineDesiredComponent() {
		let globalThis = window;
		const CURRENT_URL = globalThis.location?.href;
		const URL_OBJECT = new URL(CURRENT_URL);
		const PATH = URL_OBJECT.pathname;
		const PATH_COMPONENTS = PATH.split('/');
		const DESIRED_COMPONENT = PATH_COMPONENTS.find((component) =>
			[support.BRANDED_URL.toLowerCase(), support.UNASSIGNED_URL.toLowerCase()].includes(
				component.toLowerCase()
			)
		);
	
		if (DESIRED_COMPONENT.toLowerCase() === support.BRANDED_URL.toLowerCase()) {
			this.urlq = support.BRANDED_URL_NAVI;
		} else {
			this.urlq = support.UNASSIGNED_URL_NAVI;
		}
	}
	
	handlePageRefresh() {
		let globalThis = window;
		globalThis.sessionStorage?.clear();

	}

	handleclose() {
		this.showDivSubmit = false;
		this.showDivDraft = false;
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

	updateRecordAfterImageRemoval(urlToRemove) {
		// Implement logic to update the backend record, removing the reference to the deleted image
		// Example Apex method might be: deleteImageFromRecord({ caseId: this.caseMedicalId, imageUrl: urlToRemove });
	
		deleteImageFromRecord({ caseId: this.caseMedicalId, imageUrl: urlToRemove })
			.then(() => {

				// Optionally, you may want to reload images to ensure the display is updated
				this.loadSavedImageUrls();
			})
			.catch(error => {
				console.error('Error removing image from record:', error);
				// Optionally handle errors or provide feedback to the user
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

	getmedicalinformation(event) {
		this.medicalDataGet = event.target.value;
	}
	handleRadioChange(event) {
		this.selectedOption = event.target.value;
		this.subTypError = false;
		this.radioBtnColorChange = 'chnageradiobtn1'; // invoked in CSS file
	}
	handledescription(event) {
		this.description = event.target.value;
		if (this.description) {
			this.descriptionError = false;
			// Double quotes can't be avoided since it's invoked from CSS
			this.Description();
			this.descriptionLengthError = false;
			if (typeof window !== 'undefined') {
			const errorEvent = new CustomEvent('descriptionerror', {
				detail: { error: this.descriptionError }
			});
			this.dispatchEvent(errorEvent);
		}
		}
		if (this.description && this.description.length > 1000) {
			this.descriptionError = false;
			// Double quotes can't be avoided since it's invoked from CSS
			this.descriptionErr();
			this.descriptionLengthError = true;
		}
		
		this.descriptionError = false;
	}
	Description(){
		this.template.querySelector("label[data-field='Description']").className =
				'input-error';
			this.classFive = 'desc';
	}
	DescriptionErr(){
		this.template.querySelector("label[data-field='Description']").className =
				'input-error-label';
			this.classFive = 'change'; 
	}
	handleUploadFinished(event) {
		const UPLOADED_FILES = event.detail.files;
		this.files = UPLOADED_FILES;

		this.fileNames = this.files.map((file) => {
			
			const MAX_LENGTH = 24; // Maximum length of displayed filename
			return file.name.length > MAX_LENGTH
				? file.name.substring(0, MAX_LENGTH) + '...'
				: file.name;
		});

		this.showFileNames = true;
		this.browserName = false;
	}
	handleInsertUpdate(event) {
    let globalThis = window;
    this.caseType = event.currentTarget.dataset.value;
    const FILE_IDS = this.files.map((file) => file.documentId);

    const PARAMETERS = {
        accountId: this.accName,
        type: this.caseType,
        subType: this.selectedOption,
        description: this.description
    };

    if (!this.validateInputs()) {
        return;
    }

   
    if (this.caseMedicalId === null) {
        this.insertCase(PARAMETERS, FILE_IDS, globalThis);
    } else {
        this.updateCase(PARAMETERS, FILE_IDS, globalThis);
    }
}

validateInputs() {
    const validationType = this.getValidationType();
    const MAX_LENGTH = 1000;
    let isValid = true;

    // Check if the description exceeds the maximum length
    if (this.description.length > MAX_LENGTH) {
        this.handleDescriptionLengthError();
        isValid = false;
    }

    // Check for missing option and description
    if (validationType === support.OPTION_AND_DESC) {
        this.handleMissingOptionAndDescription();
        isValid = false;
    }

    // Check for missing description only
    if (validationType === support.MISS_DESCRIPTION) {
        this.handleMissingDescription();
        isValid = false;
    }

    // Check for missing option only
    if (validationType === support.MISS_OPTION) {
        this.handleMissingOption();
        isValid = false;
    }
	if (typeof window !== 'undefined') {
	const errorEvent = new CustomEvent('descriptionerror', {
        detail: { error: this.descriptionError }
    });
    this.dispatchEvent(errorEvent);
}
  
    // Return the final validation result
    return isValid;
}






getValidationType() {
    if (!this.selectedOption && !this.description) {
        return support.OPTION_AND_DESC;
    } else if (this.selectedOption && !this.description) {
        return support.MISS_DESCRIPTION;
    } else if (!this.selectedOption && this.description) {
        return support.MISS_OPTION;
    }
        return support.VALID;
}

handleMissingOptionAndDescription() {
    this.changeRadioBtnColor();
    this.descriptionLengthError = false;
    this.descriptionError = true;
    this.DescriptionErr();
    this.faultValue = true;
}

handleMissingDescription() {
    this.DescriptionErr();
    this.descriptionError = true;
    this.descriptionLengthError = false;
    this.faultValue = true;
}

handleMissingOption() {
    this.changeRadioBtnColor();
    this.descriptionError = false;

    this.faultValue = true;
}

handleDescriptionLengthError() {
    this.descriptionError = false;
    this.descriptionLengthError = true;
    this.DescriptionErr();
    this.faultValue = true;
}
navigateToAnotherPage(errorMessage){
	let global = window;
	global.location?.assign(this.urlq + support.ERROR_PAGE);
	global.sessionStorage.setItem('errorMessage', errorMessage);
}

insertCase(PARAMETERS, FILE_IDS, globalThis) {
    try {
        INSERT_UPDATE_LEAD_CONSENT({ wrapper: PARAMETERS, fileIds: FILE_IDS })
		.then(result => {
			saveFilesToCase({ fileUploads: this.fileUploads, caseId: result })
    .then(() => {
        // Handle success
		this.showDivSubmit = true;
        this.showDivDraft = false;
        globalThis?.scrollTo({ top: 0, behavior: 'smooth' });
        this.makeEmptyField();
		this.casePopup = true;
		this.maximumLimit = false;
		this.isLimitReached = false;
		this.InputOne = true;
		this.InputTwo = false;
		this.fileUploads = [];  // Clear fileUploads array
        this.previewUrls = '';  // Clear preview URLs
        if (fileInput) {
            fileInput.value = null;  // Reset file input
        }

       
		if (typeof window !== 'undefined') {
			const errorEvent = new CustomEvent('casepopup', {
				detail: { error: this.casePopup }
			});
			this.dispatchEvent(errorEvent);
		}
        this.dispatchEvent(new CustomEvent('filesuploaded', {
            detail: { caseId: result },
        }));
    })
    .catch(error => {
        console.error('Error uploading files:', error);      
    });
			// Handle successful operation
			
		})
		
    } catch (error) {
		this.navigateToAnotherPage(support.CASE_NOT_INSERT, error.message);
    }
}

updateCase(PARAMETERS, FILE_IDS, globalThis) {
    try {
        UPDATE_CASE({
            recId: this.caseMedicalId,
            //type: this.caseType,
			type:this.selectedOption,
            description: this.description,
            fileIds: FILE_IDS
        })
		.then(result => {
			saveFilesToCase({ fileUploads: this.fileUploads, caseId: result })
    .then(() => {
        // Handle success
		this.showDivSubmit = true;
        this.showDivDraft = false;
        globalThis?.scrollTo({ top: 0, behavior: 'smooth' });
        this.makeEmptyField();
        this.isReadOnly = false;
		this.casePopup = true;
		this.maximumLimit = false;
		this.isLimitReached = false;
		this.InputOne = true;
		this.InputTwo = false;
		this.fileUploads = [];  // Clear fileUploads array
        this.previewUrls = '';  // Clear preview URLs
        if (fileInput) {
            fileInput.value = null;  // Reset file input
        }
    })
    .catch(error => {
        console.error('Error uploading files:', error);      
    });
			// Handle successful operation
			
		})
        
    } catch (error) {
        this.navigateToAnotherPage(support.CASE_NOT_UPDATE, error.message);
    }
}

handleInsertDraft(event) {
	
    this.caseType = event.currentTarget.dataset.value;

    const FILE_IDS = this.files.map((file) => file.documentId);
    const PARAMETERS = this.createParameters();
	

    if (!this.validateInputs()) {
        return;
    }
    if (this.caseMedicalId === null) {
        this.insertDraftCase(PARAMETERS, FILE_IDS);
    } else {
        this.updateDraftCase(PARAMETERS, FILE_IDS);
    }
}

createParameters() {
    return {
        accountId: this.accName,
        type: this.caseType,
        subType: this.selectedOption,
        description: this.description
    };
}


insertDraftCase(PARAMETERS, FILE_IDS) {
	
    let globalThis = window;
    const button = this.template.querySelector('.button2');
    this.dataValue = button.getAttribute('data-value');
    this.callfunction();
    try {
        this.isButtonDisabled = true;
        CASE_DRAFT({ wrapper: PARAMETERS, fileIds: FILE_IDS })
		.then(result => {
			saveFilesToCase({ fileUploads: this.fileUploads, caseId: result })
    .then(() => {
		this.showDivDraft = true;
        this.showDivSubmit = false;
        globalThis?.scrollTo({ top: 0, behavior: 'smooth' });
        this.errorMessage = '';
        this.classFive = 'desc';
        this.makeEmptyField();
        this.loadCaseRecords();
		this.draftPopup = true;
		this.maximumLimit = false;
		this.isLimitReached = false;
		this.InputOne = true;
		this.InputTwo = false;
		this.fileUploads = [];  // Clear fileUploads array
        this.previewUrls = [];  // Clear preview URLs
        if (fileInput) {
            fileInput.value = null;  // Reset file input
        }

   

        this.dispatchEvent(new CustomEvent('filesuploaded', {
            detail: { caseId: result },
        }));
    })
    .catch(error => {
        console.error('Error uploading files:', error);      
    });
			// Handle successful operation
			
		})
       
    } catch (error) {
		this.navigateToAnotherPage(support.DRAFT_NOT_INSERT, error.message);
    }
}

updateDraftCase(PARAMETERS, FILE_IDS) {
    let globalThis = window;

    try {
        UPDATE_DRAFT({
            recId: this.caseMedicalId,
           // type: this.caseType,
		type: this.selectedOption,
            description: this.description,
            fileIds: FILE_IDS
        })
		.then(result => {
			saveFilesToCase({ fileUploads: this.fileUploads, caseId: result })
    .then(() => {
        // Handle success
		this.showDivDraft = true;
        this.showDivSubmit = false;
        globalThis?.scrollTo({ top: 0, behavior: 'smooth' });
        this.makeEmptyField();
        this.isReadOnly = false;
		this.draftPopup = true;
		this.maximumLimit = false;
		this.isLimitReached = false;
		this.InputOne = true;
		this.InputTwo = false;
		this.fileUploads = [];  // Clear fileUploads array
        this.previewUrls = '';  // Clear preview URLs
        if (fileInput) {
            fileInput.value = null;  // Reset file input
        }
    })
    .catch(error => {
        console.error('Error uploading files:', error);      
    });
			// Handle successful operation
			
		})
    } catch (error) {
        this.navigateToAnotherPage(support.DRAFT_NOT_UPDATE, error.message);
    }
    this.callfunction();
}



makeEmptyField(){
	this.descriptionLengthError = false;
						this.caseType = '';
						this.selectedOption = '';
						this.description = '';
						this.fileNames = '';
						this.browserName = true;
}
changeRadioBtnColor(){
	this.radioBtnColorChange = 'chnageradiobtn'; 
			this.subTypError = true;
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

}