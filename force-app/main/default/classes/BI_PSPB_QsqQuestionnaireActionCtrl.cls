/**
 * @description  This class handles the creation of tasks when a video is uploaded.
 * It also includes methods for sending SMS and email notifications.
 * History
 * Version	Author			Date		Detail		Description
 * 1.0		Niyas		24-07-2024		Created		Refactored Version
 */
public with sharing class BI_PSPB_QsqQuestionnaireActionCtrl {
	/**
	 * @description  Processes the creation of tasks for enrollees when questionnaires
	 * are uploaded. It also handles the invocation of methods to send SMS and email
	 * notifications based on the processed questionnaire data.
	 */
	public static void processQsqQuestionnaires() {
		try {
			Integer qsqCount = BI_PSPB_QuestionsDaysCountQueryCtrl.fetchQsqCount();
			Integer qsqTwoCount = BI_PSPB_QuestionsDaysCountQueryCtrl.fetchQsqTwoCount();
			List<Id> enrolleeQsqOneIds = processEnrollees(
				qsqCount
			);
			if (!enrolleeQsqOneIds.isEmpty()) {
				processQsq(
					enrolleeQsqOneIds,
					BI_PSPB_NotificationConstantsCtrl.qsqQuestionName,
					BI_PSPB_NotificationConstantsCtrl.qsq,
					BI_PSPB_NotificationConstantsCtrl.actionTypeNotificatonTypeAction
				);
			}
			List<Id> enrolleeQsqTwoIds = processEnrollees(
				qsqTwoCount
			);

			if (!enrolleeQsqTwoIds.isEmpty()) {
				processQsq(
					enrolleeQsqTwoIds, BI_PSPB_NotificationConstantsCtrl.qsqQuestionName,
                    BI_PSPB_NotificationConstantsCtrl.qsq,
					BI_PSPB_NotificationConstantsCtrl.actionTypeNotificatonTypeAction
				);
			}
		} catch (Exception ex) {
			BI_PSP_LogMessagesUtility.logError(
				ex.getMessage(),
				BI_PSPB_QsqQuestionnaireServiceCtrl.class.toString(),
				true,
				BI_PSPB_NotificationConstantsCtrl.severityError
			);
		}
	}

	/**
	 * @description    Creates tasks for the provided list of enrollee IDs and initiates
	 * methods to send SMS and email notifications. Handles the creation of tasks and
	 * logging if no records are found or if an error occurs.
	 * @param enrolleeQsqIds A list of enrollee IDs that need to be processed. This list should not be null or empty.
	 * @param questionName The name of the question related to the assessment. This is used for fetching due assessments.
	 * @param actionLabel The label for the action to be taken. This will be used when creating tasks.
	 * @param notificationType The type of notification to be sent (e.g., SMS, email). This determines the type of notification that will be sent.
	 * @param actionType The type of action being performed. This is used to categorize or specify the nature of the action.
	 */
	public static void processQsq(
		List<Id> enrolleeQsqIds,
		String questionName,
		String notificationType,
		String actionType
	) {
		try {
            Date today = Date.today();
            List<Task> newTaskList = new List<Task>();
            List<Id> patientEnrolleeIds = new List<Id>();
    		List<Id> caregiverEnrolleeIds = new List<Id>();
            List<Id> enrolleeSendQsqIds = new List<Id>();
            List<Id> caregiverSendIds = new List<Id>();
			if (!enrolleeQsqIds.isEmpty()) {
                List<CareProgramEnrollee> enrolleeRecords = [
                    SELECT Id, Name, Account.BI_PSP_Birthdate__c,Account.Name
                    FROM CareProgramEnrollee
                    WHERE Id IN :enrolleeQsqIds
                ];
                for (CareProgramEnrollee enrollee : enrolleeRecords) {
                    Integer age = calculateAge(enrollee.Account.BI_PSP_Birthdate__c, today);
                    Id enrolleeId = enrollee.Id;
                    Id caregiverId = fetchCaregiverId(enrolleeId);
					String patientName = enrollee.Account.Name;
                    
                    if (age > 18 && caregiverId == null) {
                        patientEnrolleeIds = new List<Id>{enrolleeId};
                        enrolleeSendQsqIds = BI_PSPB_AssessmentHelperCtrl.fetchDueAssessments(
							patientEnrolleeIds,
							questionName
						);
                        BI_PSPB_TaskParameters params = new BI_PSPB_TaskParameters(
							BI_PSPB_NotificationConstantsCtrl.qsqQuestionSubject,
							BI_PSPB_NotificationConstantsCtrl.actionTypeAction,
							BI_PSPB_NotificationConstantsCtrl.qsq,
							'',
							actionType
						);

						newTaskList.addAll(createPatientTasks(
							enrolleeSendQsqIds,
							params,
                            'Patient',
                            caregiverId
						));
                    } else {
                        caregiverEnrolleeIds = new List<Id>{enrolleeId};
                        caregiverSendIds = BI_PSPB_AssessmentHelperCtrl.fetchDueAssessments(
							caregiverEnrolleeIds,
							questionName
						);
                        if (age > 18) {
                            BI_PSPB_TaskParameters params = new BI_PSPB_TaskParameters(
							BI_PSPB_NotificationConstantsCtrl.qsqQuestionSubject,
							BI_PSPB_NotificationConstantsCtrl.actionTypeAction,
							BI_PSPB_NotificationConstantsCtrl.qsq,
							'',
							actionType
						);

						newTaskList.addAll(createPatientTasks(
							caregiverSendIds,
							params,
                            'Patient',
                            caregiverId
						));
                    }
                            BI_PSPB_TaskParameters params = new BI_PSPB_TaskParameters(
							BI_PSPB_NotificationConstantsCtrl.qsqCaregiverOne + ' ' + patientName + 
							BI_PSPB_NotificationConstantsCtrl.qsqCaregiverTwo,
							BI_PSPB_NotificationConstantsCtrl.actionTypeAction,
							BI_PSPB_NotificationConstantsCtrl.qsq,
							'',
							actionType
						);

						newTaskList.addAll(createCaregiverTasks(
							caregiverSendIds,
							params,
                            'Caregiver',
                            caregiverId
						));
                        
                }
                }
				
				
				BI_PSP_DatabaseOperationsUtility.insertOperation(
					newTaskList,
					BI_PSPB_QsqQuestionnaireServiceCtrl.class.toString(),
					false
				);
				sendNotifications(
					enrolleeSendQsqIds,
					notificationType,
					new List<String>{ '' }
				);
                sendNotifications(
					caregiverSendIds,
					notificationType,
					new List<String>{ '' }
				);
			} else {
				BI_PSP_LogMessagesUtility.logError(
					BI_PSPB_NotificationConstantsCtrl.errorMsgRecordNotFound,BI_PSPB_QsqQuestionnaireServiceCtrl.class.toString(),
					true, BI_PSPB_NotificationConstantsCtrl.severityError
				);
			}
		} catch (Exception ex) {
			BI_PSP_LogMessagesUtility.logError(
				ex.getMessage(),
				BI_PSPB_QsqQuestionnaireServiceCtrl.class.toString(),
				true,
				BI_PSPB_NotificationConstantsCtrl.severityError
			);
		}
	}
    public static List<Id> processEnrollees(Integer qsqCount) {
	List<Id> enrolleeRecIds = new List<Id>();
		// Fetch CareProgramEnrollee objects
		List<CareProgramEnrollee> enrollees = fetchEnrollees();
		for (CareProgramEnrollee enrollee : enrollees) {
			Date enrolleeCreatedDate = enrollee.BI_PSPB_FirstLoginDate__c;
			if (enrolleeCreatedDate == System.today().addDays(-qsqCount)) {
				enrolleeRecIds.add(enrollee.Id);
			}
		}
	return enrolleeRecIds;
}
    
    public static List<Task> createPatientTasks(List<Id> enrollees, BI_PSPB_TaskParameters taskParams, String userType, Id caregiverId) {
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
			}
			tasks.add(task);
		}
	} catch (Exception ex) {
		BI_PSP_LogMessagesUtility.exceptionLogMessage(
			ex.getMessage(), BI_PSPB_TaskCreationCtrl.class.getName(), ex
		);
	}
	return tasks;
}public static List<Task> createCaregiverTasks(List<Id> enrollees, BI_PSPB_TaskParameters taskParams, String userType, Id caregiverId) {
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
			task.BI_PSPB_Caregiver__c = caregiverId;
			tasks.add(task);
		}
	} catch (Exception ex) {
		BI_PSP_LogMessagesUtility.exceptionLogMessage(
			ex.getMessage(), BI_PSPB_TaskCreationCtrl.class.getName(), ex
		);
	}
	return tasks;
}

/**
 * @description  Fetches CareProgramEnrollee records from the database. 
 * @return A list of CareProgramEnrollee objects.
 */
public static List<CareProgramEnrollee> fetchEnrollees() {
	List<CareProgramEnrollee> enrolleeRecords = new List<CareProgramEnrollee>();
		// Query CareProgramEnrollee objects
		String fields = 'Id, BI_PSPB_FirstLoginDate__c';
		enrolleeRecords = BI_PSP_CommonQueryUtility.executeQuery(
		'CareProgramEnrollee',
		fields,
		null,
		false
	);
	return enrolleeRecords;
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
     public static void sendNotifications(
    List<Id> enrolleeIds,
    String notificationType, 
    List<String> communityUserNames
) {
    try {
        // Check if enrolleeIds is not empty and notificationType is not blank
        if (!enrolleeIds.isEmpty() && !String.isBlank(notificationType)) {
            BI_PSPB_SmsEmailSenderCtrl.handleTrigger(
                enrolleeIds,
                notificationType,
                communityUserNames,
                ''
            );
        } else {
            BI_PSP_LogMessagesUtility.logError(
                BI_PSPB_NotificationConstantsCtrl.errorMsgRecordNotFound,
                BI_PSPB_NotificationSender.class.toString(),
                true,
                BI_PSPB_NotificationConstantsCtrl.severityError
            );
        }
    } catch (Exception ex) {
        BI_PSP_LogMessagesUtility.exceptionLogMessage(
            ex.getMessage(),
            BI_PSPB_NotificationSetting.class.getName(),
            ex
        );
    }
}
}