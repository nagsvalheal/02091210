//This lighting web component is used in "Contact Us" section, redirecting users to the Boehringer Ingelheim portal.
// To import Libraries
import { LightningElement } from 'lwc';
import { resources } from 'c/biPspLabelAndResourceGeneral';

export default class BiPspbContactUs extends LightningElement {
    contactUs = resources.CONTACT_US_LABEL;
    redirectionLabel = resources.REDIRECTION_LABEL;
    publicContactUs = resources.PUBLIC_CONTACT_US;
    contactUsLogin = resources.CONTACT_US_LOGIN;
    finalPartOfUrl;
    urlq;

    //To get site url
	handleUrlChange(event) {
		// Access the value from the event detail
        let globalThis = window;
		this.urlq = event.detail.value;
        const CURRENT_TAB_NAME = globalThis.location?.pathname.split('/').pop();
        this.finalPartOfUrl = (CURRENT_TAB_NAME === this.publicContactUs) ? this.publicContactUs :
            (CURRENT_TAB_NAME === this.contactUsLogin) ? this.contactUsLogin :
            null;
	}
 }