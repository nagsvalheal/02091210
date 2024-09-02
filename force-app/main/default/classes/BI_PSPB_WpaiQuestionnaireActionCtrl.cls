/**
* @description  This class handles the creation of tasks when a video 
*                is uploaded. It processes questionnaires, creates tasks,
*                sends notifications, and logs errors if necessary.
* History
* Version	Author			Date		Detail		Description
* 1.0		Niyas		24-07-2024		Created		Refactored Version
*/
public with sharing class BI_PSPB_WpaiQuestionnaireActionCtrl {
/**
* @description  Processes WPai questionnaires by creating tasks for 
*               enrollees, sending notifications via SMS and email, 
*               and logging errors if any occur.
*/
public static void processWpaiQuestionnaires() {
	try {
        Date today = Date.today();
		List<Task> newTaskList = new List<Task>();
        List<Id> patientEnrolleeIds = new List<Id>();
    	List<Id> caregiverEnrolleeIds = new List<Id>();
		List<Id> enrolleeSendIds = new List<Id>();
        List<Id> caregiverSendIds = new List<Id>();

		Set<Id> enrolleeIds = fetchEnrolleeIds();
		if (!enrolleeIds.isEmpty()) {
			Integer wpaiCount = BI_PSPB_QuestionsDaysCountQueryCtrl.fetchWpaiCount();
			List<Id> enrolleeRecIds = processSymptomTrackers(enrolleeIds, wpaiCount);	
			if (!enrolleeRecIds.isEmpty()) {
                List<CareProgramEnrollee> enrolleeRecords = [
                    SELECT Id, Name, Account.BI_PSP_Birthdate__c,Account.Name
                    FROM CareProgramEnrollee
                    WHERE Id IN :enrolleeRecIds
                ];
                for (CareProgramEnrollee enrollee : enrolleeRecords) {
                    Integer age = calculateAge(enrollee.Account.BI_PSP_Birthdate__c, today);
                    Id enrolleeId = enrollee.Id;
                    String patientName = enrollee.Account.Name;
                    Id caregiverId = fetchCaregiverId(enrolleeId);
                    
                    if (age > 18 && caregiverId == null) {
                        patientEnrolleeIds = new List<Id>{enrolleeId};
                        enrolleeSendIds = fetchDueAssessments(patientEnrolleeIds, BI_PSPB_NotificationConstantsCtrl.wpaiQuestionName);
						BI_PSPB_TaskParameters params = new BI_PSPB_TaskParameters(
							BI_PSPB_NotificationConstantsCtrl.wpaiQuestionSubject,
							BI_PSPB_NotificationConstantsCtrl.actionTypeAction,
							BI_PSPB_NotificationConstantsCtrl.wpai,
							'',
							BI_PSPB_NotificationConstantsCtrl.actionTypeNotificatonTypeAction
						);					
						newTaskList.addAll(createPatientTasks(
							enrolleeSendIds,
							params,
                            'Patient', caregiverId
						));
                     } else { 
                        caregiverEnrolleeIds = new List<Id>{enrolleeId};
                        caregiverSendIds = fetchDueAssessments(caregiverEnrolleeIds, BI_PSPB_NotificationConstantsCtrl.wpaiQuestionName);
                        if (age > 18) {
                            BI_PSPB_TaskParameters params = new BI_PSPB_TaskParameters(
							BI_PSPB_NotificationConstantsCtrl.wpaiQuestionSubject,
							BI_PSPB_NotificationConstantsCtrl.actionTypeAction,
							BI_PSPB_NotificationConstantsCtrl.wpai,
							'',
							BI_PSPB_NotificationConstantsCtrl.actionTypeNotificatonTypeAction
						);					
						newTaskList.addAll(createPatientTasks(
							caregiverSendIds,
							params,
                            'Patient', caregiverId
						));
                        }
                         BI_PSPB_TaskParameters params = new BI_PSPB_TaskParameters(
							BI_PSPB_NotificationConstantsCtrl.wpaiCaregiverOne + ' ' +
                             patientName + ' ' + BI_PSPB_NotificationConstantsCtrl.wpaiCaregiverTwo,
							BI_PSPB_NotificationConstantsCtrl.actionTypeAction,
							BI_PSPB_NotificationConstantsCtrl.wpai,
							'',
							BI_PSPB_NotificationConstantsCtrl.actionTypeNotificatonTypeAction
						);					
						newTaskList.addAll(createCaregiverTasks(
							caregiverSendIds,
							params,
                            'Caregiver', caregiverId
						));
                     }
                }
				
					BI_PSP_DatabaseOperationsUtility.insertOperation(
						newTaskList,
						BI_PSPB_WpaiQuestionnaireServiceCtrl.class.toString(),
						false
					);
				sendNotifications(enrolleeSendIds, BI_PSPB_NotificationConstantsCtrl.wpai, new List<String>{''});
                sendNotifications(caregiverSendIds, BI_PSPB_NotificationConstantsCtrl.wpai, new List<String>{''});
			}
		} else {
			BI_PSP_LogMessagesUtility.logError(
				BI_PSPB_NotificationConstantsCtrl.errorMsgRecordNotFound,
				BI_PSPB_WpaiQuestionnaireServiceCtrl.class.toString(),
				true,
				BI_PSPB_NotificationConstantsCtrl.severityError
			);
		}
	} catch (Exception ex) {
		BI_PSP_LogMessagesUtility.logError(
			ex.getMessage(),
			BI_PSPB_WpaiQuestionnaireServiceCtrl.class.toString()
			,true
			,BI_PSPB_NotificationConstantsCtrl.severityError
		);
	}
}
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
    public static List<Id> processSymptomTrackers( 
	Set<Id> enrolleeIds,
	Integer wpaiCount
) {
	List<Id> enrolleeRecIds = new List<Id>();
	try {
		List<BI_PSP_Symptom_Tracker__c> symptomTrackers = getEnrolleeQuery(
			enrolleeIds
		);
		if (symptomTrackers.isEmpty()) {
			logRecordNotFound();
			return enrolleeRecIds;
		}

		Map<Id, BI_PSP_Symptom_Tracker__c> latestSymptomMap = buildLatestSymptomMap(
			symptomTrackers
		);
		addRecentEnrolleeRecords(
			enrolleeRecIds,
			latestSymptomMap,
			wpaiCount
		);
	} catch (Exception ex) {
		logException(ex);
	}
	return enrolleeRecIds;
}
/**
 * @description  Builds a map of the latest symptom tracker records based on 
 *              the provided list of symptom trackers.
 * @param symptomTrackers The ID of the record related to the treatment reminders.
 * @return A list of BI_PSPB_Treatment_Reminder__c objects that match the criteria.
 */
private static Map<Id, BI_PSP_Symptom_Tracker__c> buildLatestSymptomMap(
	List<BI_PSP_Symptom_Tracker__c> symptomTrackers
) {
	Map<Id, BI_PSP_Symptom_Tracker__c> latestSymptomMap = new Map<Id, BI_PSP_Symptom_Tracker__c>();
	for (BI_PSP_Symptom_Tracker__c symptom : symptomTrackers) {
		latestSymptomMap.put(
			symptom.BI_PSP_Care_Program_Enrollee__c,
			symptom
		);
	}
	return latestSymptomMap;
}
/**
 * @description  Adds recent enrollee records to the list based on the 
 *              provided symptom tracker map and WPAI count.
 * @param enrolleeRecIds The ID of the record related to the treatment reminders.
 * @param latestSymptomMap The ID of the record related to the treatment reminders.
 * @param wpaiCount The ID of the record related to the treatment reminders.
 */
private static void addRecentEnrolleeRecords(
	List<Id> enrolleeRecIds,
	Map<Id, BI_PSP_Symptom_Tracker__c> latestSymptomMap,
	Integer wpaiCount
) {
	for (
		BI_PSP_Symptom_Tracker__c latestSymptom : latestSymptomMap.values()
	) {
		if (isRecordWithinDays(latestSymptom, wpaiCount)) {
			enrolleeRecIds.add(
				latestSymptom.BI_PSP_Care_Program_Enrollee__c
			);
		}
	}
}
/**
 * @description  Checks if the symptom tracker record was created within the 
 *              specified number of days.
 * @param latestSymptom The ID of the record related to the treatment reminders.
 * @param wpaiCount The type of reminder to filter by.
 * @return A list of BI_PSPB_Treatment_Reminder__c objects that match the criteria.
 */
private static boolean isRecordWithinDays(
	BI_PSP_Symptom_Tracker__c latestSymptom,
	Integer wpaiCount
) {
	if (latestSymptom.CreatedDate == null) {
		return false;
	}

	Date sevenDaysLaterDate = latestSymptom.CreatedDate.addDays(wpaiCount)
		.date();
	return Date.today() == sevenDaysLaterDate;
}
/**
 * @description Logs an error message when no records are found during 
 *              processing.
 */
private static void logRecordNotFound() {
	BI_PSP_LogMessagesUtility.logError(
		BI_PSPB_NotificationConstantsCtrl.errorMsgRecordNotFound,
		BI_PSPB_QuestionsSymptomProcessor.class.toString(),
		false,
		BI_PSPB_NotificationConstantsCtrl.severityError
	);
}
/**
 * @description  Logs an exception encountered during the processing of 
 *              symptom trackers.
 * @param ex The ID of the record related to the treatment reminders.
 */
private static void logException(Exception ex) {
	BI_PSP_LogMessagesUtility.exceptionLogMessage(
		ex.getMessage(),
		BI_PSPB_QuestionsSymptomProcessor.class.getName(),
		ex
	);
}

/**
 * @description  Retrieves symptom tracker records based on the provided 
 *              enrollee IDs.
 * @param enrolleeIds The ID of the record related to the treatment reminders.
 * @return A list of BI_PSPB_Treatment_Reminder__c objects that match the criteria.
 */
public static List<BI_PSP_Symptom_Tracker__c> getEnrolleeQuery(
	Set<Id> enrolleeIds
) {
	List<String> enrolleeIdStrings = new List<String>();
	for (Id id : enrolleeIds) {
		enrolleeIdStrings.add(id.toString());
	}
	String conditionIds =
		'(\'' +
		String.join(enrolleeIdStrings, '\', \'') +
		'\')';
	String fields = 'Id, BI_PSP_Care_Program_Enrollee__c, CreatedDate';
	String conditions =
		'BI_PSP_Care_Program_Enrollee__c IN ' +
		conditionIds +
		' ORDER BY CreatedDate DESC';
	List<SObject> results = BI_PSP_CommonQueryUtility.executeQuery(
		'BI_PSP_Symptom_Tracker__c',
		fields,
		conditions,
		false
	);
	return (List<BI_PSP_Symptom_Tracker__c>) results;
}
    public static List<Id> fetchDueAssessments(
	List<Id> enrolleeRecIds,
	String questionName
) {
	List<Id> enrolleeSendIds = new List<Id>();
	try {
		// Get assessments based on enrolleeRecIds and questionName
		List<Assessment> assessmentRecords = getAssessmentQuery(
			enrolleeRecIds,
			questionName
		);
		// Add enrollee IDs for assessments that are in progress
		for (Assessment assessment : assessmentRecords) {
			if (
				assessment.AssessmentStatus ==
				BI_PSPB_NotificationConstantsCtrl.inProgressType
			) {
				enrolleeSendIds.add(
					assessment.BI_PSP_CareProgramEnrollee__c
				);
			}
		}

		// Map to store assessments per CareProgramEnrollee
		Map<Id, List<Assessment>> parentChildMap = new Map<Id, List<Assessment>>();

		// Get parent records (CareProgramEnrollee)
		List<CareProgramEnrollee> parentRecords = getEnrolleeQuery(
			enrolleeRecIds
		);
		for (CareProgramEnrollee parent : parentRecords) {
			parentChildMap.put(parent.Id, new List<Assessment>());
		}

		// Get child assessments
		List<Assessment> assessmentChildRecords = getAssessmentChildQuery(
			new List<Id>(parentChildMap.keySet()),
			questionName
		);
		for (Assessment child : assessmentChildRecords) {
			if (
				parentChildMap.containsKey(
					child.BI_PSP_CareProgramEnrollee__c
				)
			) {
				parentChildMap.get(child.BI_PSP_CareProgramEnrollee__c)
					.add(child);
			}
		}

		// Add parent records to enrolleeSendIds if they have no child assessments
		for (CareProgramEnrollee parent : parentRecords) {
			if (parentChildMap.get(parent.Id).isEmpty()) {
				enrolleeSendIds.add(parent.Id);
			}
		}
	} catch (Exception ex) {
		BI_PSP_LogMessagesUtility.exceptionLogMessage(
			BI_PSPB_NotificationConstantsCtrl.recordNotFound,
			BI_PSPB_AssessmentHelperCtrl.class.toString(),
			ex
		);
	}
	return enrolleeSendIds;
}

/**
 * @description  Retrieves assessments based on the provided enrollee IDs 
 * and question name.
 * @param assessmentIdList The ID of the record related to the treatment reminders.
 * @param questionName The type of reminder to filter by.
 * @return A list of BI_PSPB_Treatment_Reminder__c objects that match the criteria.
 */
public static List<Assessment> getAssessmentQuery(
	List<Id> assessmentIdList,
	String questionName
) {
	String conditionIds =
		'(\'' +
		String.join(assessmentIdList, '\', \'') +
		'\')';
	String fields = 'Id, Name, BI_PSP_CareProgramEnrollee__c, AssessmentStatus, AssessmentRating';
	String conditions =
		'BI_PSP_CareProgramEnrollee__c IN ' +
		conditionIds +
		' ' +
		'AND Name = \'' +
		questionName +
		'\' ';
	List<SObject> results = BI_PSP_CommonQueryUtility.executeQuery(
		'Assessment',
		fields,
		conditions,
		false
	);
	return results;
}
/**
 * @description  Retrieves child assessments based on the provided enrollee 
 * IDs and question name.
 * @param assessmentIdList The ID of the record related to the treatment reminders.
 * @param questionName The type of reminder to filter by.
 * @return A list of BI_PSPB_Treatment_Reminder__c objects that match the criteria.
 */
public static List<Assessment> getAssessmentChildQuery(
	List<Id> assessmentIdList,
	String questionName
) {
	String conditionIds =
		'(\'' +
		String.join(assessmentIdList, '\', \'') +
		'\')';
	String fields = 'Id, Name, BI_PSP_CareProgramEnrollee__c, AssessmentStatus, AssessmentRating';
	String conditions =
		'BI_PSP_CareProgramEnrollee__c IN ' +
		conditionIds +
		' ' +
		'AND Name = \'' +
		questionName +
		'\' ';
	List<SObject> results = BI_PSP_CommonQueryUtility.executeQuery(
		'Assessment',
		fields,
		conditions,
		false
	);
	return results;
}
/**
 * @description  Retrieves enrollee records based on the provided enrollee 
 * IDs.
 * @param enrolleeList The ID of the record related to the treatment reminders.
 * @return A list of BI_PSPB_Treatment_Reminder__c objects that match the criteria.
 */
public static List<CareProgramEnrollee> getEnrolleeQuery(
	List<Id> enrolleeList
) {
	String conditionIds =
		'(\'' +
		String.join(enrolleeList, '\', \'') +
		'\')';
	String fields = 'Id, BI_PSPB_FirstLoginDate__c';
	String conditions = 'Id IN ' + conditionIds + ' ';
	List<SObject> results = BI_PSP_CommonQueryUtility.executeQuery(
		'CareProgramEnrollee',
		fields,
		conditions,
		false
	);
	return results;
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