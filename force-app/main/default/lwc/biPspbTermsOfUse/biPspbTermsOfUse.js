// This lighting web component outlines the terms and conditions that users must agree to when accessing and using the website.
// To import Libraries
import { LightningElement } from 'lwc';
import { resources } from 'c/biPspLabelAndResourceGeneral';

export default class BiPspbTermsOfUse extends LightningElement {
    publicTermsOfUse = resources.PUBLIC_TERMS_OF_USE;
    termsOfUse = resources.TERMS_LOGIN;
    finalPartOfUrl;
    urlq;

    //To get site url
	handleUrlChange(event) {
		// Access the value from the event detail
        let globalThis = window;
		this.urlq = event.detail.value;
        const CURRENT_TAB_NAME = globalThis.location?.pathname.split('/').pop();
        this.finalPartOfUrl = (CURRENT_TAB_NAME === this.publicTermsOfUse) ? this.publicTermsOfUse :
            (CURRENT_TAB_NAME === this.termsOfUse) ? this.termsOfUse :
            null;
	}
 }