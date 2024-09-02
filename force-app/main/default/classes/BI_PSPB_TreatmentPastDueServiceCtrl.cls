/**
* @description Handles the creation of tasks when a video is uploaded and sends SMS 
* and email notifications. This class processes reminders and manages 
* associated tasks and notifications..
* History
* Version	Author			Date		Detail		Description
* 1.0		Niyas		24-07-2024		Created		Refactored Version
*/
public with sharing class BI_PSPB_TreatmentPastDueServiceCtrl {
/**
* @description  Processes past due reminders by calculating target dates, retrieving 
* treatment reminders, creating tasks, and sending notifications.
*/
public static void processPastDueReminders() {
	try {
		Integer[] intervals = new List<Integer>{ 0, -1, -3 };
		Set<Date> targetDates = BI_PSPB_TreatmentDateCalculatorCtrl.calculateTargetDates(
			intervals
		);
		Map<Date, List<BI_PSPB_Treatment_Reminder__c>> remindersByDate = BI_PSPB_TreatmentRecordQueryCtrl.getTreatmentRecords(
			targetDates
		);

		ReminderProcessingContext context = new ReminderProcessingContext();
		processReminders(remindersByDate, targetDates, context);
		handleTasks(context.newTaskList);
		sendNotifications(
			context.enrolleeRecIds,
			context.enrolleePastOne,
			context.enrolleePastThree,
			context.pastDueDays,
            context.treatmentDate
		);
	} catch (System.DmlException ex) {
		BI_PSP_LogMessagesUtility.logError(
			ex.getMessage(),
			BI_PSPB_TreatmentPastDueServiceCtrl.class.toString()
			,true
			,BI_PSPB_NotificationConstantsCtrl.severityError
		);
	}
}
/**
 * @description  Processes reminders by iterating through target dates and handling 
 * each list of reminders for those dates.
 * @param remindersByDate The ID of the record related to the treatment reminders.
 * @param targetDates The type of reminder to filter by.
 * @param context The type of reminder to filter by.
 */
private static void processReminders(
	Map<Date, List<BI_PSPB_Treatment_Reminder__c>> remindersByDate,
	Set<Date> targetDates,
	ReminderProcessingContext context
) {
	for (Date targetDate : targetDates) {
		if (remindersByDate.containsKey(targetDate)) {
			processReminderList(
				remindersByDate.get(targetDate),
				targetDate,
				context
			);
		}
	}
}

/**
 * @description   Processes a list of reminders for a specific target date, creating tasks 
 * as necessary and adding them to the context.
 * @param reminders The ID of the record related to the treatment reminders.
 * @param targetDate The type of reminder to filter by.
 * @param context The type of reminder to filter by.
 */
private static void processReminderList(
	List<BI_PSPB_Treatment_Reminder__c> reminders,
	Date targetDate,
	ReminderProcessingContext context
) {
    String formattedDate;
	Datetime treatmentDate;
	for (BI_PSPB_Treatment_Reminder__c reminder : reminders) {
        treatmentDate = reminder.BI_PSPB_Date_of_Treatment__c;
		formattedDate = treatmentDate.format('MM/dd/yyyy');
        context.treatmentDate = formattedDate;
		BI_PSPB_TaskCreationParams params = new BI_PSPB_TaskCreationParams(
			reminder,
			context.pastDueDays
		);
		Task newTask = BI_PSPB_PastDueTaskCreatorCtrl.createTask(
			targetDate,
			context.enrolleeRecIds,
			context.enrolleePastOne,
			context.enrolleePastThree,
			params
		);

		if (newTask != null) {
			context.newTaskList.add(newTask);
		}
	}
}
/**
 * @description Handles the insertion of newly created tasks into the database.
 * @param newTaskList The ID of the record related to the treatment reminders.
 */
public static void handleTasks(List<Task> newTaskList) {
	try {
		// Null check for the newTaskList parameter
		if (newTaskList.isEmpty()) {
			BI_PSP_LogMessagesUtility.logError(
				BI_PSPB_NotificationConstantsCtrl.errorMsgRecordNotFound,
				BI_PSPB_TreatmentPastDueServiceCtrl.class.toString(),
				false,
				BI_PSPB_NotificationConstantsCtrl.severityError
			);
			return;
		}
		BI_PSP_DatabaseOperationsUtility.insertOperation(
			newTaskList,
			BI_PSPB_TreatmentPastDueServiceCtrl.class.toString(),
			false
		);
	} catch (System.DmlException ex) {
		BI_PSP_LogMessagesUtility.exceptionLogMessage(
			ex.getMessage(),
			BI_PSPB_TreatmentPastDueServiceCtrl.class.getName(),
			ex
		);
	}
}
/**
 * @description   Sends notifications (SMS and email) based on the list of enrollee IDs 
 * and the reminder days.
 * @param enrolleeRecIds The ID of the record related to the treatment reminders.
 * @param enrolleePastOne The type of reminder to filter by.
 * @param enrolleePastThree The ID of the record related to the treatment reminders.
 * @param pastDueDays The type of reminder to filter by.
 * @param treatmentDate Date to be sent for notification.
 */
private static void sendNotifications(
	List<Id> enrolleeRecIds,
	List<Id> enrolleePastOne,
	List<Id> enrolleePastThree,
	BI_PSPB_TreatmentReminderDaysCtrl pastDueDays,
    String treatmentDate
) {
	try {
		BI_PSPB_PastDueNotificationSender.sendNotifications(
			enrolleeRecIds,
			enrolleePastOne,
			enrolleePastThree,
			pastDueDays,
            treatmentDate
		);
	} catch (Exception ex) {
		BI_PSP_LogMessagesUtility.exceptionLogMessage(
			ex.getMessage(),
			BI_PSPB_TreatmentPastDueServiceCtrl.class.getName(),
			ex
		);
	}
}
/**
 * @description  Context class for storing details related to reminder processing, 
 * including enrollee IDs, past due reminders, and newly created tasks.
 * @param enrolleeRecIds The ID of the record related to the treatment reminders.
 * @param enrolleePastOne The type of reminder to filter by.
 * @param enrolleePastThree The ID of the record related to the treatment reminders.
 * @param pastDueDays The type of reminder to filter by.
 * @param newTaskList The type of reminder to filter by.
 */
public class ReminderProcessingContext {
	public List<Id> enrolleeRecIds = new List<Id>();
	public List<Id> enrolleePastOne = new List<Id>();
	public List<Id> enrolleePastThree = new List<Id>();
	public BI_PSPB_TreatmentReminderDaysCtrl pastDueDays = new BI_PSPB_TreatmentReminderDaysCtrl();
	public List<Task> newTaskList = new List<Task>();
    public String treatmentDate;
}
}