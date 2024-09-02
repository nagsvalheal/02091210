/**
* @description This class is responsible for checking the days to send 
* notifications and calling another method to create tasks based on the 
* due dates.
* History
* Version	Author			Date		Detail		Description
* 1.0		Niyas		24-07-2024		Created		Refactored Version 
*/
public with sharing class BI_PSPB_PastDueTaskCreatorCtrl {
	/**
	 * @description Creates a task based on the given reminder and past due days.
	 * This method checks the target date against the current date to determine
	 * if a task should be created for enrollees. Tasks are created for the
	 * day of treatment, 24 hours past due, and 72 hours past due.
	 * @param targetDate - The target date for the task.
	 * @param enrolleeRecIds - The list to store enrollees for today.
	 * @param enrolleePastOne - The list to store enrollees past due by 24 hours.
	 * @param enrolleePastThree - The list to store enrollees past due by 72 hours.
	 * @param params - The list to store enrollees past due by 72 hours.
	 * @return - The created Task record or null if no task is created.
	 */
	public static Task createTask(
	Date targetDate,
	List<Id> enrolleeRecIds,
	List<Id> enrolleePastOne,
	List<Id> enrolleePastThree,
	BI_PSPB_TaskCreationParams params
	) {
	List<Task> tasks = new List<Task>();
	try {
		Integer daysDifference = targetDate.daysBetween(Date.today());
		String subject;
		String category = BI_PSPB_NotificationConstantsCtrl.statusDateOfTreatment;
		String treatmentType;
		String formattedDate;
		Datetime treatmentDate;
	
		if (daysDifference == 0) {
		enrolleeRecIds.add(params.reminder.BI_PSPB_Care_Program_Enrollee__c);
		subject = BI_PSPB_NotificationConstantsCtrl.actionTreatmentDate;
		treatmentType = BI_PSPB_NotificationConstantsCtrl.dayOfTreatment;
		} else if (daysDifference == params.pastDueDays.pastdue24hrCount) {
		enrolleePastOne.add(params.reminder.BI_PSPB_Care_Program_Enrollee__c);
		subject = BI_PSPB_NotificationConstantsCtrl.actionTreatmentDueTwentyFour;
		treatmentType = BI_PSPB_NotificationConstantsCtrl.pastDueDate;
		} else if (daysDifference == params.pastDueDays.pastdue72hrCount) {
		treatmentDate = params.reminder.BI_PSPB_Date_of_Treatment__c;
		formattedDate = treatmentDate.format('MM/dd/yyyy');
		enrolleePastThree.add(params.reminder.BI_PSPB_Care_Program_Enrollee__c);
		subject = BI_PSPB_NotificationConstantsCtrl.actionTreatmentDueSeventyTwo +
					' ' +
					formattedDate + ' ' + BI_PSPB_NotificationConstantsCtrl.pastTwentySubject;
		treatmentType = BI_PSPB_NotificationConstantsCtrl.pastDueDateTwo;
		} else {
		return null;
		}
	
		BI_PSPB_TaskParameters taskParams = new BI_PSPB_TaskParameters(
		subject,
		BI_PSPB_NotificationConstantsCtrl.actionTypeAction,
		category,
		treatmentType,
		BI_PSPB_NotificationConstantsCtrl.actionTypeNotificatonTypeAction
		);
	
		tasks = BI_PSPB_TaskCreationCtrl.createTasks(
		new List<Id>{ params.reminder.Id },
		taskParams
		);
	} catch (Exception ex) {
		BI_PSP_LogMessagesUtility.exceptionLogMessage(
		ex.getMessage(),BI_PSPB_PastDueTaskCreatorCtrl.class.getName(),ex
		);
	}
	// Return the first task from the list or null if the list is empty
	return tasks.isEmpty() ? null : tasks[0];
	}
	}