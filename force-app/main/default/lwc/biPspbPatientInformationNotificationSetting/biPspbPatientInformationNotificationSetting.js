import { LightningElement } from 'lwc';
// Import Apex Classes
import PROFILE_DETAILS from '@salesforce/apex/BI_PSP_CurrentUser.getCurrentUser';
// Importing all the resources used here from the file biPspbReminderNotificationSettResources.js.
import {resources} from 'c/biPspbNotificationReminderResources';
export default class BiPspbPatientInformationNotificationSetting extends LightningElement {
        // Variable declaration and assigning values to it.
        question = resources.QUESTION;
        boxedIcon = resources.YELLOW_ICON;
        preferredWay = resources.PREFERRED_WAY;
        notificationSettings = resources.NOTIFICATION_SETTINGS;
        userId = resources.ID;
        caregiverNotificationUrl = resources.CAREGIVER_NOTIFICATION_URL;
        patientNotificationUrl = resources.PATIENT_NOTIFICATION_URL;
        systemAdmininstrator = resources.SYSTEM_ADMIN_PROFILE;
        patientProfile = resources.PATIENT_PROFILES;
        caregiverProfile = resources.CAREGIVER_PROFILES;
        siteUrlBranded = resources.BRANDED_URL;
        alternateForBackground = resources.ALTERNATE_BACKGROUND;
        baseUrl;
        notificationSettingsUrl;
        profileName;
        // To check on the page URLs while loading the page.
        connectedCallback() {
            try {
                this.setCurrentPageUrl();
                this.parseUrlSegments();	
                this.fetchProfileDetails();
                const globalThis = window;
			const CURRENT_URL = globalThis.location.href;
			const URL_OBJECT = new URL(CURRENT_URL); // Get the PATH
			const PATH = URL_OBJECT.pathname; // Split the PATH using '/' as a separator
			const PATH_COMPONENTS = PATH.split('/'); // Find the component you need (in this case, 'Branded')
			const DESIRED_COMPONENTS = PATH_COMPONENTS.find((component) =>
				[resources.BRANDED_URL.toLowerCase(), resources.UNASSIGNED_URL.toLowerCase()].includes(
					component.toLowerCase()
				)
			);


			if (DESIRED_COMPONENTS.toLowerCase() === resources.BRANDED_URL.toLowerCase()) {
				this.urlq = resources.BRANDED_SITE_URL;
			} else {
				this.urlq = resources.UNASSIGNED_SITE_URL;
			}
            } catch (error) {
                this.handleError(resources.ERROR_FOR_PROFILE);
                let globalThis=window;
			this.error=resources.RECORD_NOT_FOUND;
        globalThis.location.href = resources.ERROR_PAGE;        
        globalThis.sessionStorage.setItem('errorMessage', this.error);
            }
        }
        // To get the url of the current page.
        setCurrentPageUrl() {
            let globalThis = window;
            this.currentPageUrl = globalThis.location.href;
        }
        // To split the url based on protocol and host.
        parseUrlSegments() {
            let url = new URL(this.currentPageUrl);
            this.baseUrl = `${url.protocol}//${url.host}`;
        }
        // To fetch whether the user is a patient or a caregiver.
        fetchProfileDetails() {
            PROFILE_DETAILS()
                .then(result => {
                    this.profileName = result.Profile.Name;
                })
                .catch((error) => {
                    this.handleError(error.body.message);
                });
        }
        // Redirects users to their notification settings based on their profile (patient or caregiver).
        openNotificationSettings() 
        {	
            if (this.profileName === this.patientProfile) 
                {
                const MERGED_URL =  this.urlq  + this.patientNotificationUrl;
                window.location.assign(MERGED_URL);
                } 
            else if (this.profileName === this.caregiverProfile) 
                {
                const MERGED_URL =  this.urlq  + this.caregiverNotificationUrl;
                window.location.assign(MERGED_URL);
                }
        }
        handleError(error){
            let globalThis=window;
            globalThis.location.href = resources.ERROR_PAGE;
            globalThis.sessionStorage.setItem('errorMessage', error);
        }
    
    
    
    }