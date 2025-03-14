/**

*@description       This Method  is used to get URL for the Google Calender.
* History
 * Version  Author      Date            Detail      Description
 * 1.0      Anand S     30-Dec-2024     Created     This was an intial development.
 * 1.1      Rajaa       06-Apr-2024     Updated     Code Review Changes.
 * 1.2      Rajaa       23-July-2024    Update      Code Refactor .
 */ 
public with sharing class BI_PSPB_GoogleCalendarCtrl {
	/**

*@description       This Method  is used to get URL for the Google Calender.
*@param             eventDate  The Event Date for the patient.On the date of treatment.
*@return            googleCalendarURL return the Url of Google Calender.
*                   Returned in the LWC Component biPspbReminderSetup

**/
	@AuraEnabled(cacheable=true)
	public static String generateGoogleCalendarUrl(Date eventDate) {
		String googleCalendarUrl;
		try {
			if (eventDate == null) {
				BI_PSP_LogMessagesUtility.logError(BI_PSPB_TreatmentConstantsClassCtrl.parameterError,BI_PSPB_GoogleCalendarCtrl.class.toString(),false,BI_PSPB_TreatmentConstantsClassCtrl.logError);
			} 

			BI_PSPB_Notification__mdt notificationMetadata = BI_PSPB_Notification__mdt.getInstance(  
				BI_PSPB_TreatmentConstantsClassCtrl.dateOfTreatmentMetaData
			);          
			String title = notificationMetadata.BI_PSPB_CalenderTitle__c;
			String detail = notificationMetadata.BI_PSPB_CalenderDescription__c;   
			Time startTime = Time.newInstance(8, 0, 0, 0); 
			Time endTime = startTime.addHours(12); // 12 hours later, which will be 8:00 PM
			DateTime startDateTime = DateTime.newInstance(eventDate, startTime);
			DateTime endDateTime = DateTime.newInstance(eventDate, endTime);
			String startDateTimeString = startDateTime.formatGmt(BI_PSPB_TreatmentConstantsClassCtrl.timeFormate);
			String endDateTimeString = endDateTime.formatGmt(BI_PSPB_TreatmentConstantsClassCtrl.timeFormate);
			 googleCalendarUrl = createGoogleCalendarUrl(title, startDateTimeString, endDateTimeString, detail);

			if (String.isBlank(googleCalendarUrl)) {               
				BI_PSP_LogMessagesUtility.logError(BI_PSPB_TreatmentConstantsClassCtrl.googleUrlError,BI_PSPB_GoogleCalendarCtrl.class.toString(),false,BI_PSPB_TreatmentConstantsClassCtrl.logError);
			}

		} catch (Exception ex) {
			BI_PSP_LogMessagesUtility.exceptionLogMessage( 
                ex.getMessage(),
                BI_PSPB_GoogleCalendarCtrl.class.toString(),
                ex
            );
		}
		return googleCalendarUrl;
		
	} 

	private static String createGoogleCalendarUrl(String title, String startDateTimeString, String endDateTimeString, String detail) {
		return BI_PSPB_TreatmentConstantsClassCtrl.googleCalendar +
			   '&text=' + EncodingUtil.urlEncode(title, 'UTF-8') +
			   '&dates=' + startDateTimeString + '/' + endDateTimeString +
			   '&details=' + EncodingUtil.urlEncode(detail, 'UTF-8') +
			   '&trp=true';
	}
}