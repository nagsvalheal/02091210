/**
* @description Handles the creation of tasks upon video upload and 
* initiates methods for sending SMS and email notifications.
* History
* Version	Author			Date		Detail		Description
* 1.0		Niyas		24-07-2024		Created		Refactored Version
*/
public with sharing class BI_PSPB_EnrolleeQueryCtrl {
/**
 * @description  Fetches a set of Enrollee IDs from the CareProgramEnrollee 
 * records that match the specified criteria.
 * @return A list of Enrollee objects that match the criteria.
 */
public static Set<Id> fetchEnrolleeIds() {
	Set<Id> enrolleeIds = new Set<Id>();
		List<SObject> enrolleeRecords = BI_PSP_CommonQueryUtility.executeQuery(
			'CareProgramEnrollee',
			'Id',
			null,
			false
		);
		for (SObject cpe : enrolleeRecords) {
			enrolleeIds.add(cpe.Id);
		}
	return enrolleeIds;
}
}