/**
* @description   Controller class for handling treatment date calculations.
*                Calculates target dates based on provided intervals and
*                manages related tasks, SMS, and email notifications.
* History
* Version	Author			Date		Detail		Description
* 1.0		Niyas		24-07-2024		Created		Refactored Version
*/
public with sharing class BI_PSPB_TreatmentDateCalculatorCtrl {
/**
 * @description  Calculates target dates based on provided intervals.
 * @param intervals The ID of the record related to the treatment reminders.
 * @return A list of BI_PSPB_Treatment_Reminder__c objects that match the criteria.
 */
public static Set<Date> calculateTargetDates(Integer[] intervals) {
	Set<Date> targetDates = new Set<Date>();
	for (Integer interval : intervals) {
		targetDates.add(Date.today().addDays(interval));
	}
	return targetDates;
}
}