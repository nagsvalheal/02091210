/**
 * @description Handles the creation of tasks when a video is uploaded and sends SMS
 * and email notifications. This class processes reminders and manages
 * associated tasks and notifications..
 * History
 * Version	Author			Date		Detail		Description
 * 1.0		Niyas		24-07-2024		Created		Refactored Version
 */
public with sharing class BI_PSPB_TreatmentPastDueActionCtrl {
	/**
	 * @description  Processes past due reminders by calculating target dates, retrieving
	 * treatment reminders, creating tasks, and sending notifications.
	 */
	public static void processPastDueReminders() {
		try {
			Integer[] intervals = new List<Integer>{ 0, -1, -3 };
			Set<Date> targetDates = calculateTargetDates(intervals);
			Map<Date, List<BI_PSPB_Treatment_Reminder__c>> remindersByDate = getTreatmentRecords(
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
				BI_PSPB_TreatmentPastDueServiceCtrl.class.toString(),
				true,
				BI_PSPB_NotificationConstantsCtrl.severityError
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
		Date today = Date.today();
		String formattedDate;
		Datetime treatmentDate;
		for (BI_PSPB_Treatment_Reminder__c reminder : reminders) {
			treatmentDate = reminder.BI_PSPB_Date_of_Treatment__c;
			formattedDate = treatmentDate.format('MM/dd/yyyy');
			context.treatmentDate = formattedDate;
            String patientName = reminder.BI_PSPB_Care_Program_Enrollee__r.Account.Name;
			Integer age = calculateAge(
				reminder.BI_PSPB_Care_Program_Enrollee__r.Account.BI_PSP_Birthdate__c,
				today
			);
			Id enrolleeId = reminder.BI_PSPB_Care_Program_Enrollee__c;
			Id caregiverId = fetchCaregiverId(enrolleeId);
			BI_PSPB_TaskCreationParams params = new BI_PSPB_TaskCreationParams(
				reminder,
				context.pastDueDays
			);
			if (age > 18 && caregiverId == null) {
				Task newTask = createPatientTask(
					targetDate,
					context.enrolleeRecIds,
					context.enrolleePastOne,
					context.enrolleePastThree,
					params,
                    'Patient',
                    caregiverId
				);

				if (newTask != null) {
					context.newTaskList.add(newTask);
				}
			} else { 
                if (age > 18) {
                Task newTask = createPatientTask(
					targetDate,
					context.enrolleeRecIds,
					context.enrolleePastOne,
					context.enrolleePastThree,
					params,
                    'Patient',
                    caregiverId
				);

				if (newTask != null) {
					context.newTaskList.add(newTask);
				}
                }
				Task newTask1 = createCaregiverTask(
					targetDate,
					context.enrolleeRecIds,
					context.enrolleePastOne,
					context.enrolleePastThree,
					params,
                    'Caregiver',
                    caregiverId,
                    patientName
				);

				if (newTask1 != null) {
					context.newTaskList.add(newTask1);
				}
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
			sendNotifications1(
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
	public static Set<Date> calculateTargetDates(Integer[] intervals) {
		Set<Date> targetDates = new Set<Date>();
		for (Integer interval : intervals) {
			targetDates.add(Date.today().addDays(interval));
		}
		return targetDates;
	}

	public static Map<Date, List<BI_PSPB_Treatment_Reminder__c>> getTreatmentRecords(
		Set<Date> targetDates
	) {
		Map<Date, List<BI_PSPB_Treatment_Reminder__c>> remindersByDate = new Map<Date, List<BI_PSPB_Treatment_Reminder__c>>();
		try {
			// Null check for targetDates
			if (targetDates == null) {
				BI_PSP_LogMessagesUtility.logError(
					BI_PSPB_NotificationConstantsCtrl.errorMsgRecordNotFound,
					BI_PSPB_TreatmentRecordQueryCtrl.class.toString(),
					true,
					BI_PSPB_NotificationConstantsCtrl.severityError
				);
				return remindersByDate;
			}
			// Convert Set<Date> to a List<Date>
			List<Date> targetDatesList = new List<Date>(targetDates);

			/// Convert List<Date> to a comma-separated string in 'YYYY-MM-DD' format
			List<String> formattedDates = new List<String>();
			for (Date targetDate : targetDatesList) {
				DateTime dt = DateTime.newInstance(
					targetDate,
					Time.newInstance(0, 0, 0, 0)
				);
				formattedDates.add(dt.format('yyyy-MM-dd'));
			}
			String fields = 'BI_PSPB_Care_Program_Enrollee__c, BI_PSPB_Reminder_Type__c, BI_PSPB_Date_of_Treatment__c, BI_PSPB_Care_Program_Enrollee__r.Account.BI_PSP_Birthdate__c,BI_PSPB_Care_Program_Enrollee__r.Account.Name';
			// Convert List<Id> to a comma-separated string for the query
			String conditionIds = '(' + String.join(formattedDates, ', ') + ')';
			String conditions =
				'BI_PSPB_Date_of_Treatment__c IN ' +
				conditionIds +
				' ' +
				'AND BI_PSPB_Reminder_Type__c = \'' +
				'Date of Treatment' +
				'\' ' +
				'AND BI_PSPB_Status__c = \'' +
				BI_PSPB_NotificationConstantsCtrl.actionTypeActive +
				'\' ';

			// Execute the query using the BI_PSP_CommonQueryUtility class
			List<SObject> records = BI_PSP_CommonQueryUtility.executeQuery(
				'BI_PSPB_Treatment_Reminder__c',
				fields,
				conditions,
				false
			);

			// Null check for the records list
			if (records.isEmpty()) {
				BI_PSP_LogMessagesUtility.logError(
					BI_PSPB_NotificationConstantsCtrl.errorMsgRecordNotFound,
					BI_PSPB_TreatmentRecordQueryCtrl.class.toString(),
					true,
					BI_PSPB_NotificationConstantsCtrl.severityError
				);
				return remindersByDate;
			}

			for (SObject record : records) {
				BI_PSPB_Treatment_Reminder__c treatmentReminder = (BI_PSPB_Treatment_Reminder__c) record;
				Date treatmentDate = treatmentReminder.BI_PSPB_Date_of_Treatment__c;

				if (!remindersByDate.containsKey(treatmentDate)) {
					remindersByDate.put(
						treatmentDate,
						new List<BI_PSPB_Treatment_Reminder__c>()
					);
				}
				remindersByDate.get(treatmentDate).add(treatmentReminder);
			}
		} catch (Exception ex) {
			BI_PSP_LogMessagesUtility.logError(
				ex.getMessage(),
				BI_PSPB_TreatmentRecordQueryCtrl.class.toString(),
				true,
				BI_PSPB_NotificationConstantsCtrl.severityError
			);
		}
		return remindersByDate;
	}

	public static void sendNotifications1(
		List<Id> enrolleeRecIds,
		List<Id> enrolleePastOne,
		List<Id> enrolleePastThree,
		BI_PSPB_TreatmentReminderDaysCtrl pastDueDays,
		String treatmentDate
	) {
		try {
			if (!enrolleeRecIds.isEmpty()) {
			BI_PSPB_SmsEmailSenderCtrl.handleTrigger(
				enrolleeRecIds,
				BI_PSPB_NotificationConstantsCtrl.pastDueDateZero,
				new List<String>{''},
				''
			);
		}
		if (!enrolleePastOne.isEmpty()) {
			BI_PSPB_SmsEmailSenderCtrl.handleTrigger(
				enrolleePastOne,
				BI_PSPB_NotificationConstantsCtrl.pastDueDateOne,
				new List<String>{''},
				''
			);
		}
		if (!enrolleePastThree.isEmpty()) {
			BI_PSPB_SmsEmailSenderCtrl.handleTrigger(
				enrolleePastThree,
				BI_PSPB_NotificationConstantsCtrl.pastDueDateThree,
				new List<String>{''},
				treatmentDate
			);
		}
		} catch (System.DmlException ex) {
			BI_PSP_LogMessagesUtility.catchSystemException(
				BI_PSPB_CommunityConstantCtrl.errorWhileDeleting,
				BI_PSPB_FeedItemCtrl.class.toString(),
				ex
			);
		}
	}
    	public static Task createPatientTask(
		Date targetDate,
		List<Id> enrolleeRecIds,
		List<Id> enrolleePastOne,
		List<Id> enrolleePastThree,
		BI_PSPB_TaskCreationParams params,
        String userType,
        Id caregiverId
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
				enrolleeRecIds.add(
					params.reminder.BI_PSPB_Care_Program_Enrollee__c
				);
				subject = BI_PSPB_NotificationConstantsCtrl.actionTreatmentDate;
				treatmentType = BI_PSPB_NotificationConstantsCtrl.dayOfTreatment;
			} else if (daysDifference == params.pastDueDays.pastdue24hrCount) {
				enrolleePastOne.add(
					params.reminder.BI_PSPB_Care_Program_Enrollee__c
				);
				subject = BI_PSPB_NotificationConstantsCtrl.actionTreatmentDueTwentyFour;
				treatmentType = BI_PSPB_NotificationConstantsCtrl.pastDueDate;
			} else if (daysDifference == params.pastDueDays.pastdue72hrCount) {
				treatmentDate = params.reminder.BI_PSPB_Date_of_Treatment__c;
				formattedDate = treatmentDate.format('MM/dd/yyyy');
				enrolleePastThree.add(
					params.reminder.BI_PSPB_Care_Program_Enrollee__c
				);
				subject =
					BI_PSPB_NotificationConstantsCtrl.actionTreatmentDueSeventyTwo +
					' ' +
					formattedDate +
					' ' +
					BI_PSPB_NotificationConstantsCtrl.pastTwentySubject;
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

			tasks = createTasks(new List<Id>{ params.reminder.Id }, taskParams, userType, caregiverId);
		} catch (Exception ex) {
			BI_PSP_LogMessagesUtility.exceptionLogMessage(
				ex.getMessage(),
				BI_PSPB_PastDueTaskCreatorCtrl.class.getName(),
				ex
			);
		}
		// Return the first task from the list or null if the list is empty
		return tasks.isEmpty() ? null : tasks[0];
	}
	public static Task createCaregiverTask(
		Date targetDate,
		List<Id> enrolleeRecIds,
		List<Id> enrolleePastOne,
		List<Id> enrolleePastThree,
		BI_PSPB_TaskCreationParams params,
        String userType,
        Id caregiverId,
        String patientName
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
				enrolleeRecIds.add(
					params.reminder.BI_PSPB_Care_Program_Enrollee__c
				);
				subject = BI_PSPB_NotificationConstantsCtrl.dateTreatCaregiverOne + ' ' +
                    patientName + ' ' + BI_PSPB_NotificationConstantsCtrl.dateTreatCaregiverTwo;
				treatmentType = BI_PSPB_NotificationConstantsCtrl.dayOfTreatment;
			} else if (daysDifference == params.pastDueDays.pastdue24hrCount) {
				enrolleePastOne.add(
					params.reminder.BI_PSPB_Care_Program_Enrollee__c
				);
				subject = BI_PSPB_NotificationConstantsCtrl.twentyFourCaregiverOne + ' ' + patientName
                    + ' ' + BI_PSPB_NotificationConstantsCtrl.twentyFourCaregiverTwo;
				treatmentType = BI_PSPB_NotificationConstantsCtrl.pastDueDate;
			} else if (daysDifference == params.pastDueDays.pastdue72hrCount) {
				treatmentDate = params.reminder.BI_PSPB_Date_of_Treatment__c;
				formattedDate = treatmentDate.format('MM/dd/yyyy');
				enrolleePastThree.add(
					params.reminder.BI_PSPB_Care_Program_Enrollee__c
				);
				subject =
					BI_PSPB_NotificationConstantsCtrl.twentyFourCaregiverOne + ' '
                    + patientName + ' ' + BI_PSPB_NotificationConstantsCtrl.seventyTwoCaregiverTwo +
					' ' +
					formattedDate +
					BI_PSPB_NotificationConstantsCtrl.pastTwentySubject;
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

			tasks = createTasks(new List<Id>{ params.reminder.Id }, taskParams, userType, caregiverId);
		} catch (Exception ex) {
			BI_PSP_LogMessagesUtility.exceptionLogMessage(
				ex.getMessage(),
				BI_PSPB_PastDueTaskCreatorCtrl.class.getName(),
				ex
			);
		}
		// Return the first task from the list or null if the list is empty
		return tasks.isEmpty() ? null : tasks[0];
	}
	public static List<Task> createTasks(
		List<Id> enrollees,
		BI_PSPB_TaskParameters taskParams,
        String userType,
        Id caregiverId
	) {
		List<Task> tasks = new List<Task>();
		try {
			for (Id enrollee : enrollees) {
				Task task = new Task();
				task.Subject = taskParams.subject;
				task.BI_PSP_Notification_Type__c = taskParams.notificationType;
				task.BI_PSP_Category__c = taskParams.category;
				task.BI_PSPB_Treatment_Type__c = taskParams.treatmentType;
				task.Status = taskParams.status;
				task.WhatId = enrollee;
                task.BI_PSPB_Notification_User_Type__c = userType;
                if (userType == 'Patient' && caregiverId != null) {
					task.BI_PSPB_Caregiver__c = caregiverId;
				} else if (userType == 'Caregiver') {
					task.BI_PSPB_Caregiver__c = caregiverId;
				}
				tasks.add(task);
			}
		} catch (Exception ex) {
			BI_PSP_LogMessagesUtility.exceptionLogMessage(
				ex.getMessage(),
				BI_PSPB_TaskCreationCtrl.class.getName(),
				ex
			);
		}
		return tasks;
	}

	private static Integer calculateAge(Date birthDate, Date today) {
		Integer age = today.year() - birthDate.year();
		if (today < birthDate.addYears(age)) {
			age--;
		}
		return age;
	}
	private static Id fetchCaregiverId(Id enrolleeId) {
		// Query to find the active caregiver associated with the enrollee
		List<BI_PSPB_Enrollee_Caregiver__c> enrolleeCaregiverList = [
			SELECT BI_PSPB_Caregiver__r.Id
			FROM BI_PSPB_Enrollee_Caregiver__c
			WHERE
				BI_PSPB_Care_Program_Enrollee__c = :enrolleeId
				AND BI_PSPB_Status__c = 'Active'
			LIMIT 1
		];

		// Check if any records are returned and return the caregiver ID or null
		if (!enrolleeCaregiverList.isEmpty()) {
			return enrolleeCaregiverList[0].BI_PSPB_Caregiver__r.Id;
		} else {
			return null;
		}
	}
}