/**
 *@description This class is responsible for creating tasks when a video is
 *             uploaded, as well as triggering methods to send SMS and
 *             email notifications.
 *History
 *Version    Author      Date       Detail      Description
 *1.0        Niyas       24-07-2024 Created     Refactored Version
 */
public with sharing class BI_PSPB_TreatmentReminderActionCtrl {
	/**
	 *@description Processes treatment reminders, creating tasks based on
	 *             uploaded videos and sending SMS and email notifications.
	 */
	public static void processReminders() {
		try {
			Date today = Date.today();
			List<BI_PSPB_Treatment_Reminder__c> reminders = getActiveReminders(
				today
			);

			if (reminders.isEmpty()) {
				BI_PSP_LogMessagesUtility.logError(
					BI_PSPB_NotificationConstantsCtrl.errorMsgRecordNotFound,
					BI_PSPB_TreatmentReminderServiceCtrl.class.toString(),
					true,
					BI_PSPB_NotificationConstantsCtrl.severityError
				);
			} else {
				BI_PSPB_TreatmentReminderDaysCtrl daysCount = new BI_PSPB_TreatmentReminderDaysCtrl();
				List<Task> newTaskList = new List<Task>();
				Map<String, Id> createdTaskIdentifiers = new Map<String, Id>();

				for (BI_PSPB_Treatment_Reminder__c reminder : reminders) {
					Integer age = calculateAge(
						reminder.BI_PSPB_Care_Program_Enrollee__r.Account.BI_PSP_Birthdate__c,
						today
					);
					Id enrolleeId = reminder.BI_PSPB_Care_Program_Enrollee__c;
					Id caregiverId = fetchCaregiverId(enrolleeId);
					Integer daysDifference = reminder.BI_PSPB_Reminder_Date__c.daysBetween(
						reminder.BI_PSPB_Date_of_Treatment__c
					);

					// Generate a unique identifier for the task
					String taskIdentifier = reminder.Id + '-' + daysDifference;

					// Create tasks based on age and caregiver presence
					if (age > 18 && caregiverId == null) {
						// Under 18, create only enrollee task
						if (!createdTaskIdentifiers.containsKey(taskIdentifier + '-Patient')) {
							Task enrolleeTask = createPatientTask(
								reminder,
								daysDifference,
								daysCount,
								'Patient'
							);
							if (enrolleeTask != null) {
								newTaskList.add(enrolleeTask);
								createdTaskIdentifiers.put(taskIdentifier + '-Patient', enrolleeTask.Id);
							}
						}
					} else {
						if (!createdTaskIdentifiers.containsKey(taskIdentifier + '-Patient') && age > 18) {
							Task enrolleeTask = createPatientTask(
								reminder,
								daysDifference,
								daysCount,
								'Patient'
							);
							if (enrolleeTask != null) {
								newTaskList.add(enrolleeTask);
								createdTaskIdentifiers.put(taskIdentifier + '-Patient', enrolleeTask.Id);
							}
						}

						if (caregiverId != null && !createdTaskIdentifiers.containsKey(taskIdentifier + '-Caregiver')) {
							Task caregiverTask = createCaregiverTask(
								reminder,
								daysDifference,
								daysCount,
								'Caregiver'
							);
							if (caregiverTask != null) {
								newTaskList.add(caregiverTask);
								createdTaskIdentifiers.put(taskIdentifier + '-Caregiver',caregiverTask.Id);
							}
						}
					}
				}

				if (!newTaskList.isEmpty()) {
					// Batch insert to avoid hitting limits
					BI_PSP_DatabaseOperationsUtility.insertOperation(
						newTaskList,
						BI_PSPB_TreatmentReminderServiceCtrl.class.toString(),
						false
					);
				}

				sendNotifications(reminders, daysCount);
			}
		} catch (Exception ex) {
			BI_PSP_LogMessagesUtility.logError(
				ex.getMessage(),
				BI_PSPB_TreatmentReminderServiceCtrl.class.toString(),
				true,
				BI_PSPB_NotificationConstantsCtrl.severityError
			);
		}
	}

	private static Boolean taskExists(
		BI_PSPB_Treatment_Reminder__c reminder,
		Integer daysDifference,
		BI_PSPB_TreatmentReminderDaysCtrl daysCount
	) {
		String subject;
		if (daysDifference == daysCount.before1Day) {
			subject = BI_PSPB_NotificationConstantsCtrl.oneDayBeforeSubject;
		} else if (daysDifference == daysCount.before3Day) {
			subject = BI_PSPB_NotificationConstantsCtrl.threeDayBeforeSubject;
		} else if (daysDifference == daysCount.before7Day) {
			subject = BI_PSPB_NotificationConstantsCtrl.sevenDayBeforeSubject;
		} else if (daysDifference == daysCount.before10Day) {
			subject = BI_PSPB_NotificationConstantsCtrl.tenDayBeforeSubject;
		} else if (daysDifference == daysCount.before14Day) {
			subject = BI_PSPB_NotificationConstantsCtrl.fourteenDayBeforeSubject;
		} else {
			return false; // No task to create
		}

		// Query existing tasks to see if one with the same subject and reminder ID exists
		List<Task> existingTasks = [
			SELECT Id
			FROM Task
			WHERE Subject = :subject AND WhatId = :reminder.Id
			LIMIT 1
		];

		return !existingTasks.isEmpty();
	}

	private static Integer calculateAge(Date birthDate, Date today) {
		Integer age = today.year() - birthDate.year();
		if (today < birthDate.addYears(age)) {
			age--;
		}
		return age;
	}

	private static Id fetchCaregiverId(Id enrolleeId) {
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

	/**
	 * @description Retrieves active treatment reminders based on the given date.
	 * @param today The date for which active reminders are retrieved.
	 * @return A list of BI_PSPB_Treatment_Reminder__c objects that match the criteria.
	 */
	private static List<BI_PSPB_Treatment_Reminder__c> getActiveReminders(
		Date today
	) {
		String formattedDate = DateTime.newInstance(
				today,
				Time.newInstance(0, 0, 0, 0)
			)
			.format('yyyy-MM-dd');
		String fields = 'BI_PSPB_Care_Program_Enrollee__c, BI_PSPB_Care_Program_Enrollee__r.AccountId, BI_PSPB_Reminder_Date__c, BI_PSPB_Date_of_Treatment__c, BI_PSPB_Care_Program_Enrollee__r.Account.BI_PSP_Birthdate__c, BI_PSPB_Care_Program_Enrollee__r.Account.Name';
		String conditions =
			'BI_PSPB_Reminder_Date__c = ' +
			formattedDate +
			' ' +
			'AND BI_PSPB_Status__c = \'' +
			BI_PSPB_NotificationConstantsCtrl.actionTypeActive +
			'\' ' +
			'AND (BI_PSPB_Reminder_Type__c = \'' +
			BI_PSPB_NotificationConstantsCtrl.actionTypeTreatment +
			'\' ' +
			'OR BI_PSPB_Reminder_Type__c = \'' +
			BI_PSPB_NotificationConstantsCtrl.actionTypePrescription +
			'\' )';
		List<SObject> results = BI_PSP_CommonQueryUtility.executeQuery(
			'BI_PSPB_Treatment_Reminder__c',
			fields,
			conditions,
			false
		);
		return (List<BI_PSPB_Treatment_Reminder__c>) results;
	}

	public static Task createPatientTask(
		BI_PSPB_Treatment_Reminder__c reminder,
		Integer daysDifference,
		BI_PSPB_TreatmentReminderDaysCtrl daysCount,
		String userType
	) {
		String subject;
		String category;
		String notificationType;
		String status;
		String formattedDate;
		Datetime treatmentDate;

		if (daysDifference == daysCount.before1Day) {
			treatmentDate = reminder.BI_PSPB_Date_of_Treatment__c;
			formattedDate = treatmentDate.format('MM/dd/yyyy');
			subject =
				BI_PSPB_NotificationConstantsCtrl.oneDayBeforeSubject +
				' ' +
				formattedDate + '.' ;
			notificationType = BI_PSPB_NotificationConstantsCtrl.actionTypeGeneral;
			status = BI_PSPB_NotificationConstantsCtrl.actionTypeUnRead;
			category = BI_PSPB_NotificationConstantsCtrl.actionTypeTreatment;
		} else if (daysDifference == daysCount.before3Day) {
			treatmentDate = reminder.BI_PSPB_Date_of_Treatment__c;
			formattedDate = treatmentDate.format('MM/dd/yyyy');
			subject =
				BI_PSPB_NotificationConstantsCtrl.threeDayBeforeSubject +
				' ' +
				formattedDate + '.';
			notificationType = BI_PSPB_NotificationConstantsCtrl.actionTypeGeneral;
			status = BI_PSPB_NotificationConstantsCtrl.actionTypeUnRead;
			category = BI_PSPB_NotificationConstantsCtrl.actionTypeTreatment;
		} else if (daysDifference == daysCount.before7Day) {
			subject = BI_PSPB_NotificationConstantsCtrl.sevenDayBeforeSubject;
			notificationType = BI_PSPB_NotificationConstantsCtrl.actionTypeAction;
			status = BI_PSPB_NotificationConstantsCtrl.actionTypeNotificatonTypeAction;
			category = BI_PSPB_NotificationConstantsCtrl.actionTypePrescription;
		} else if (daysDifference == daysCount.before10Day) {
			subject = BI_PSPB_NotificationConstantsCtrl.tenDayBeforeSubject;
			notificationType = BI_PSPB_NotificationConstantsCtrl.actionTypeAction;
			status = BI_PSPB_NotificationConstantsCtrl.actionTypeNotificatonTypeAction;
			category = BI_PSPB_NotificationConstantsCtrl.actionTypePrescription;
		} else if (daysDifference == daysCount.before14Day) {
			subject = BI_PSPB_NotificationConstantsCtrl.fourteenDayBeforeSubject;
			notificationType = BI_PSPB_NotificationConstantsCtrl.actionTypeAction;
			status = BI_PSPB_NotificationConstantsCtrl.actionTypeNotificatonTypeAction;
			category = BI_PSPB_NotificationConstantsCtrl.actionTypePrescription;
		} else {
			return null;
		}

		// Create a new Task record
		Task newTask = new Task();
		newTask.Subject = subject;
		newTask.Status = status;
        newTask.BI_PSP_Notification_Type__c = notificationType;
		newTask.BI_PSP_Category__c = category; // Custom field for category
		newTask.WhatId = reminder.Id; // Link task to the reminder record
		newTask.BI_PSPB_Notification_User_Type__c = 'Patient';
         Id caregiverId = fetchCaregiverId(
				reminder.BI_PSPB_Care_Program_Enrollee__c
			);
        if (userType == 'Patient' && caregiverId != null) {
            newTask.BI_PSPB_Caregiver__c = caregiverId;
        }
        

		return newTask;
	}
    public static Task createCaregiverTask(
		BI_PSPB_Treatment_Reminder__c reminder,
		Integer daysDifference,
		BI_PSPB_TreatmentReminderDaysCtrl daysCount,
		String userType
	) {
		String subject;
		String category;
		String notificationType;
		String status;
		String formattedDate;
		Datetime treatmentDate;
        String patientName = reminder.BI_PSPB_Care_Program_Enrollee__r.Account.Name; 

		if (daysDifference == daysCount.before1Day) {
			treatmentDate = reminder.BI_PSPB_Date_of_Treatment__c;
			formattedDate = treatmentDate.format('MM/dd/yyyy');
			subject = BI_PSPB_NotificationConstantsCtrl.ensure + ' ' +
                patientName + ' ' +
				BI_PSPB_NotificationConstantsCtrl.treatmentOneDayCaregiver +
				' ' +
				formattedDate + '.' ;
			notificationType = BI_PSPB_NotificationConstantsCtrl.actionTypeGeneral;
			status = BI_PSPB_NotificationConstantsCtrl.actionTypeUnRead;
			category = BI_PSPB_NotificationConstantsCtrl.actionTypeTreatment;
		} else if (daysDifference == daysCount.before3Day) {
			treatmentDate = reminder.BI_PSPB_Date_of_Treatment__c;
			formattedDate = treatmentDate.format('MM/dd/yyyy');
			subject = BI_PSPB_NotificationConstantsCtrl.pleaseEnsure + ' ' + 
                patientName + ' ' +
				BI_PSPB_NotificationConstantsCtrl.treatmentThreeCaregiver +
				' ' +
				formattedDate + '.' ;
			notificationType = BI_PSPB_NotificationConstantsCtrl.actionTypeGeneral;
			status = BI_PSPB_NotificationConstantsCtrl.actionTypeUnRead;
			category = BI_PSPB_NotificationConstantsCtrl.actionTypeTreatment;
		} else if (daysDifference == daysCount.before7Day) {
			subject = BI_PSPB_NotificationConstantsCtrl.recieved + ' ' +
                patientName +
                BI_PSPB_NotificationConstantsCtrl.sevenDayCaregiver;
			notificationType = BI_PSPB_NotificationConstantsCtrl.actionTypeAction;
			status = BI_PSPB_NotificationConstantsCtrl.actionTypeNotificatonTypeAction;
			category = BI_PSPB_NotificationConstantsCtrl.actionTypePrescription;
		} else if (daysDifference == daysCount.before10Day) {
			subject = BI_PSPB_NotificationConstantsCtrl.recieved + ' '
                + patientName + BI_PSPB_NotificationConstantsCtrl.tenDayCaregiver;
			notificationType = BI_PSPB_NotificationConstantsCtrl.actionTypeAction;
			status = BI_PSPB_NotificationConstantsCtrl.actionTypeNotificatonTypeAction;
			category = BI_PSPB_NotificationConstantsCtrl.actionTypePrescription;
		} else if (daysDifference == daysCount.before14Day) {
			subject = BI_PSPB_NotificationConstantsCtrl.recieved + ' ' +
                patientName + BI_PSPB_NotificationConstantsCtrl.fourteenDayCaregiver;
			notificationType = BI_PSPB_NotificationConstantsCtrl.actionTypeAction;
			status = BI_PSPB_NotificationConstantsCtrl.actionTypeNotificatonTypeAction;
			category = BI_PSPB_NotificationConstantsCtrl.actionTypePrescription;
		} else {
			return null;
		}

		// Create a new Task record
		Task newTask = new Task();
		newTask.Subject = subject;
		newTask.Status = status;
		newTask.BI_PSP_Category__c = category;
		newTask.WhatId = reminder.Id;
        newTask.BI_PSP_Notification_Type__c = notificationType;
        Id caregiverId = fetchCaregiverId(
				reminder.BI_PSPB_Care_Program_Enrollee__c
			);
        newTask.BI_PSPB_Caregiver__c = caregiverId;
		newTask.BI_PSPB_Notification_User_Type__c = 'Caregiver';
		return newTask;
	}

public static void sendNotifications(
	List<BI_PSPB_Treatment_Reminder__c> reminders,
	BI_PSPB_TreatmentReminderDaysCtrl daysCount
) {
	try {
		if (reminders.isEmpty() || daysCount == null) {
			BI_PSP_LogMessagesUtility.logError(
				BI_PSPB_NotificationConstantsCtrl.errorMsgRecordNotFound,
				BI_PSPB_NotificationServiceCtrl.class.toString(),
				false,
				BI_PSPB_NotificationConstantsCtrl.severityError
			);
			return;
		}
		Map<Integer, List<Id>> enrolleeIdMap = new Map<Integer, List<Id>>{
			daysCount.before1Day => new List<Id>(),
			daysCount.before3Day => new List<Id>(),
			daysCount.before7Day => new List<Id>(),
			daysCount.before10Day => new List<Id>(),
			daysCount.before14Day => new List<Id>()
		};
        String formattedDate;
		Datetime treatmentDate;
		for (BI_PSPB_Treatment_Reminder__c reminder : reminders) {
			Integer daysDifference = reminder.BI_PSPB_Reminder_Date__c.daysBetween(
				reminder.BI_PSPB_Date_of_Treatment__c
			);
			if (enrolleeIdMap.containsKey(daysDifference)) {
                treatmentDate = reminder.BI_PSPB_Date_of_Treatment__c;
				formattedDate = treatmentDate.format('MM/dd/yyyy');
				enrolleeIdMap.get(daysDifference)
					.add(reminder.BI_PSPB_Care_Program_Enrollee__c);
			}
		}

		handleTriggers(enrolleeIdMap, daysCount, formattedDate);
	} catch (Exception ex) {
		BI_PSP_LogMessagesUtility.exceptionLogMessage(
		ex.getMessage(),
		BI_PSPB_NotificationServiceCtrl.class.toString(),
		ex
	);
	}
}
/**
 * @description Triggering another method for each dates.
 * @param enrolleeIdMap Map of dates and enrollee ids.
 * @param daysCount Count of days to send notifications.
 * @param formattedDate Date to be sent for notification.
 */
public static void handleTriggers(
	Map<Integer, List<Id>> enrolleeIdMap,
	BI_PSPB_TreatmentReminderDaysCtrl daysCount,
    String formattedDate
) {
	try {
		if (enrolleeIdMap == null || daysCount == null) {
			BI_PSP_LogMessagesUtility.logError(
				BI_PSPB_NotificationConstantsCtrl.errorMsgRecordNotFound,
				BI_PSPB_NotificationServiceCtrl.class.toString(),
				true,
				BI_PSPB_NotificationConstantsCtrl.severityError
			);
			return;
		}
		triggerNotification(
			enrolleeIdMap.get(daysCount.before1Day),
			BI_PSPB_NotificationConstantsCtrl.treatmentOne,
            formattedDate
		);
		triggerNotification(
			enrolleeIdMap.get(daysCount.before3Day),
			BI_PSPB_NotificationConstantsCtrl.treatmentThree,
            formattedDate
		);
		triggerNotification(
			enrolleeIdMap.get(daysCount.before7Day),
			BI_PSPB_NotificationConstantsCtrl.treatmentSeven,
            ''
		);
		triggerNotification(
			enrolleeIdMap.get(daysCount.before10Day),
			BI_PSPB_NotificationConstantsCtrl.treatmentTen,
            ''
		);
		triggerNotification(
			enrolleeIdMap.get(daysCount.before14Day),
			BI_PSPB_NotificationConstantsCtrl.treatmentFourteen,
            ''
		);
	} catch (Exception ex) {
		BI_PSP_LogMessagesUtility.exceptionLogMessage(
			ex.getMessage(),
			BI_PSPB_NotificationServiceCtrl.class.getName(),
			ex
		);
	}
}
/**
* @description Triggers methods for each notification based on days count.
* @param enrolleeIds Enrollee Ids to send notifications.
* @param treatmentType Type of the treatment to trigger.
* @param formattedDate Date to be sent for notification.
*/
public static void triggerNotification(
	List<Id> enrolleeIds,
	String treatmentType,
    String formattedDate
) {
	try {
		if (!enrolleeIds.isEmpty()) {
			BI_PSPB_SmsAndEmailSenderCtrl.handleTrigger(
				enrolleeIds,
				treatmentType,
				new List<String>{''},
				formattedDate
			);
			return;
		}
	} catch (Exception ex) {
		BI_PSP_LogMessagesUtility.exceptionLogMessage(
			ex.getMessage(),
			BI_PSPB_NotificationServiceCtrl.class.getName(),
			ex
		);
	}
}
}