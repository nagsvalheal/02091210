// This consolidated component is used to show avatar , message and selecting an avatar whenever user wants to change
// To import Libraries
import { LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// To import Custom Labels
import { label } from 'c/biPspbAvatarResources';
import GET_USER_ACCOUNT_ID from '@salesforce/apex/BI_PSP_CurrentUser.returnTheAccounts';
import { resources } from 'c/biPspbResourceProfileManager';
export default class BiPspbCgSelectAvatarParent extends LightningElement {
	//this method is used to navigating a user unassigned and branded
	notificationSetting = resources.Patient_Notification;
	selectAvatar = resources.SELECT_AVATAR;
	patientInfo = resources.PATIENT_INFO;
	myProfile = resources.MY_PROFILE;
	Adult = false;
	renderedCallback() {
		try {
			const CURRENT_URL = window.location.href;
			// Create a URL object
			const URL_OBJECT = new URL(CURRENT_URL);        // Get the PATH
			const PATH = URL_OBJECT.pathname;        // Split the PATH using '/' as a separator
			const PATH_COMPONENTS = PATH.split('/');        // Find the component you need (in this case, 'Branded')
			const DESIRED_COMPONENTS = PATH_COMPONENTS.find(component =>
				[label.BRANDED_URL.toLowerCase(), label.UNASSIGNED_URL.toLowerCase()].includes(component.toLowerCase())
			);


			if (DESIRED_COMPONENTS.toLowerCase() === label.BRANDED_URL.toLowerCase()) {
				this.urlq = label.BRANDED_SITEURL;
			}
			else {
				this.urlq = label.UNASSIGNED_SITE_URL;
			}
		} catch (error) {
			let globalThis = window;
			this.error = resources.RECORD_NOT_FOUND;
			globalThis.location.href = resources.ERROR_PAGE;
			globalThis.sessionStorage.setItem('errorMessage', this.error);
		}
	}
	@wire(GET_USER_ACCOUNT_ID)
	wiredAccId({ data, error }) {
		try {
			if (data) {

				// Check if the age is 18 or older
				if (data[0].BI_PSP_Age__c >= resources.MINOR_AGE) {
					this.Adult = true;
				}
			} else if (error) {

				// Handle the error case
				let globalThis = window;
				this.error = 'Record Not Found'; // Example error message
				globalThis.sessionStorage.setItem('errorMessage', this.error);
				globalThis.location.href = 'errorPage.html'; // Example error page
			}
		} catch (err) {


			// Handle the exception
			let globalThis = window;
			this.error = 'Record Not Found'; // Example error message
			globalThis.sessionStorage.setItem('errorMessage', this.error);
			globalThis.location.href = 'errorPage.html'; // Example error page
		}
	}
	// navigation for caregiver

	openCarMyCaregiver() {
		window.location.assign(label.CAREGIVER_PATIENT_URL);
	}
	openCarSelectAvatar() {
		window.location.assign(label.CAREGIVER_SELECT_URL);
	}
	openCarNotSettings() {
		window.location.assign(resources.CAREGIVER_NOTIFICATIONS);
	}
	showToast(title, message, variant) {
		const EVENT = new ShowToastEvent({
			title: title,
			message: message,
			variant: variant
		});
		this.dispatchEvent(EVENT);
	}
}