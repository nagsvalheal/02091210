public with sharing class BI_PSPB_SymptomActionNotificationCtrl {

    public static void processSymptomNotifications() {
        try {
            List<SObject> enrolleeIds = fetchEnrolleeIds();
            
            if (!enrolleeIds.isEmpty()) {
                List<BI_PSP_Symptom_Tracker__c> symptomTrackers = BI_PSPB_SymptomTrackerQuery.fetchSymptomTrackers(enrolleeIds);
                
                if (!symptomTrackers.isEmpty()) {
                    processAndCreateTasks(symptomTrackers);
                } else {
                    logRecordNotFoundError();
                }
            } else {
                logRecordNotFoundError();
            }
        } catch (Exception ex) {
            logException(ex);
        }
    }

    private static List<SObject> fetchEnrolleeIds() {
        return BI_PSP_CommonQueryUtility.executeQuery(
            'CareProgramEnrollee',
            'Id',
            null,
            false
        );
    }

    private static void processAndCreateTasks(List<BI_PSP_Symptom_Tracker__c> symptomTrackers) {
    Date today = Date.today();
    Map<Id, Id> enrolleeToCaregiverMap = new Map<Id, Id>(); // Correct mapping of Enrollee ID to Caregiver ID
    Set<Id> under18EnrolleeIds = new Set<Id>();
    Set<Id> enrolleeIdsWithCaregivers = new Set<Id>();
        String subjectForCaregiver;
        String subjectForPatient;

    for (BI_PSP_Symptom_Tracker__c tracker : symptomTrackers) {
        Integer age = calculateAge(tracker.BI_PSP_Care_Program_Enrollee__r.Account.BI_PSP_Birthdate__c, today);
        Id enrolleeId = tracker.BI_PSP_Care_Program_Enrollee__c;
        Id caregiverId = fetchCaregiverId(enrolleeId);
        String patientName =  tracker.BI_PSP_Care_Program_Enrollee__r.Account.Name;
        system.debug('patietname'+patientName);
		subjectForCaregiver = BI_PSPB_NotificationConstantsCtrl.actionSymptomCaregiver +
                        ' ' + patientName + BI_PSPB_NotificationConstantsCtrl.actionSymptomCaregiverTwo;
        subjectForPatient = BI_PSPB_NotificationConstantsCtrl.symptomTrackerActionSubject;
        if (age > 18) {
            // Enrollee is under 18
            under18EnrolleeIds.add(enrolleeId);
        }

        if (caregiverId != null) {
            enrolleeToCaregiverMap.put(enrolleeId, caregiverId);
            enrolleeIdsWithCaregivers.add(enrolleeId);
        }
    }

    // Create and insert tasks for under-18 enrollees
    List<Id> under18CaregiverIds = new List<Id>();
    for (Id enrolleeId : under18EnrolleeIds) {
        under18CaregiverIds.add(enrolleeToCaregiverMap.containsKey(enrolleeId) ? enrolleeToCaregiverMap.get(enrolleeId) : null);
    }
    createAndInsertTasks(new List<Id>(under18EnrolleeIds), under18CaregiverIds, 'Patient',subjectForPatient);

    // Create and insert tasks for enrollees with caregivers
    createAndInsertTasks(new List<Id>(enrolleeIdsWithCaregivers), new List<Id>(enrolleeToCaregiverMap.values()), 'Caregiver',subjectForCaregiver);

    // Create and insert tasks for enrollees without caregivers
    Set<Id> enrolleesWithoutCaregivers = new Set<Id>(under18EnrolleeIds);
    enrolleesWithoutCaregivers.removeAll(enrolleeIdsWithCaregivers);
    //createAndInsertTasks(new List<Id>(enrolleesWithoutCaregivers), null, 'Patient');
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
            WHERE BI_PSPB_Care_Program_Enrollee__c = :enrolleeId
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

    private static void createAndInsertTasks(List<Id> enrolleeIds, List<Id> caregiverIds, String userType, String patientName) {
        if (!enrolleeIds.isEmpty()) {
            List<Task> newTaskList = createTasks(
                enrolleeIds,
                caregiverIds,
                BI_PSPB_NotificationConstantsCtrl.actionTypeAction,
                BI_PSPB_NotificationConstantsCtrl.actionTypeSymptomTracker,
                '',
                BI_PSPB_NotificationConstantsCtrl.actionTypeNotificatonTypeAction,
                userType,
                patientName
            );
            system.debug('newTaskList'+newTaskList);
            //BI_PSP_DatabaseOperationsUtility.insertOperation(
              //  newTaskList,
               // BI_PSPB_SymptomActionNotification.class.toString(),
                //false
            //);
        }
    }

    public static List<Task> createTasks(
        List<Id> enrollees,
        List<Id> caregiverIds,
        String notificationType,
        String category,
        String treatmentType,
        String status,
        String userType,
        String subject
    ) {
        List<Task> tasks = new List<Task>();
        try {
            for (Integer i = 0; i < enrollees.size(); i++) {
                Task task = new Task();
                task.BI_PSP_Notification_Type__c = notificationType;
                task.BI_PSP_Category__c = category;
                task.BI_PSPB_Treatment_Type__c = treatmentType;
                task.Status = status;
                task.Subject = subject;
                task.WhatId = enrollees[i];
                task.BI_PSPB_Notification_User_Type__c = userType;

                if (caregiverIds != null && i < caregiverIds.size()) {
                    task.BI_PSPB_Caregiver__c = caregiverIds[i];
                }

                tasks.add(task);
                system.debug('tasks'+tasks);
            }
        } catch (Exception ex) {
            BI_PSP_LogMessagesUtility.exceptionLogMessage(
                ex.getMessage(),
                BI_PSPB_TaskCreationCtrlM.class.getName(),
                ex
            );
        }
        return tasks;
    }

    private static void logRecordNotFoundError() {
        BI_PSP_LogMessagesUtility.logError(
            BI_PSPB_NotificationConstantsCtrl.errorMsgRecordNotFound,
            BI_PSPB_SymptomActionNotification.class.toString(),
            true,
            BI_PSPB_NotificationConstantsCtrl.severityError
        );
    }

    private static void logException(Exception ex) {
        BI_PSP_LogMessagesUtility.logError(
            ex.getMessage(),
            BI_PSPB_SymptomActionNotification.class.toString(),
            true,
            BI_PSPB_NotificationConstantsCtrl.severityError
        );
    }
}