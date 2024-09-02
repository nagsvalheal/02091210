/**
* @description Controller for updating the status of Tasks based on 
*              notifications. Handles marking tasks as read or completed.
* History
* Version	Author			Date		Detail		Description
* 1.0		Ragavi		24-07-2024		Created		Refactored Version
*/
public without sharing class BI_PSPB_NotificationStatusCtrl {
/**
 * @description Updating the task status as Read.
 * @param taskId Id of the Task to be updated.
 * @return Returning the task marked as read.
 */
@AuraEnabled
public static List<Task> markTaskRead(String taskId) {
List<Task> listOfTasks = new List<Task>();
List<Id> taskIdList = new List<Id>();
try {
     taskIdList.add(taskId);
	listOfTasks = updateTaskStatus(
		taskIdList,
		BI_PSPB_NotificationConstantsCtrl.actionTypeRead
	);
	if (!listOfTasks.isEmpty()) {
		BI_PSP_DatabaseOperationsUtility.updateOperation(
			listOfTasks,
			BI_PSPB_NotificationStatusCtrl.class.toString(),
			false
		);
	}
} catch (Exception ex) {
	BI_PSP_LogMessagesUtility.exceptionLogMessage(
		ex.getMessage(),
		BI_PSPB_NotificationStatusCtrl.class.getName(),
		ex
	);
}
return listOfTasks;
}
/**
 * @description Updating the task status as Completed.
 * @param taskId Id of the Task to be updated.
 * @return Returning the task marked as read.
 */
@AuraEnabled
public static List<Task> markTaskCompleted(String taskId) {
List<Task> updateTasks = new List<Task>();
try {
    String fields =
			'Id, WhatId, ' +
			'Status, BI_PSP_Category__c, ' + 
			'Subject, BI_PSPB_Treatment_Type__c, BI_PSP_Notification_Type__c';
    String conditions = 'Id = \'' + taskId + '\'';
    List<Task> task = BI_PSP_CommonQueryUtility.executeQuery(
			'Task',
			fields,
			conditions,
			false
		);
    system.debug('task'+task);
    String whatId = task[0].WhatId;
    String status = task[0].Status;
    String category = task[0].BI_PSP_Category__c;
    String treatmentType = task[0].BI_PSPB_Treatment_Type__c;
    String notificationType = task[0].BI_PSP_Notification_Type__c;
	String fieldsOfRelatedTasks =
			'Id, WhatId, ' +
			'Status, BI_PSP_Category__c, ' +
			'Subject, BI_PSPB_Treatment_Type__c, BI_PSP_Notification_Type__c';
    String conditionsOfRelatedTasks = 'WhatId = \'' + whatId + '\' ' +
				'AND Status = \'' + status + '\' ' +
				'AND BI_PSP_Category__c = \'' + category + '\' ' +
        		'AND BI_PSP_Notification_Type__c = \'' + notificationType + '\' ';
    if (treatmentType != null) {
   		conditionsOfRelatedTasks += 'AND BI_PSPB_Treatment_Type__c = \'' + treatmentType + '\' ';
	}
    system.debug('conditionsOfRelatedTasks'+conditionsOfRelatedTasks);
    system.debug('fieldsOfRelatedTasks'+fieldsOfRelatedTasks);
    List<Task> relatedTasks = BI_PSP_CommonQueryUtility.executeQuery(
			'Task',
			fieldsOfRelatedTasks,
			conditionsOfRelatedTasks,
			false
		);
    system.debug('relatedTasks'+relatedTasks);
    system.debug('size'+relatedTasks.size());
    List<Id> taskIds = new List<Id>();
    for (Task t : relatedTasks) {
    	taskIds.add(t.Id);
	}
    system.debug('taskIds'+taskIds);
	updateTasks = updateTaskStatus(
			taskIds,
		BI_PSPB_NotificationConstantsCtrl.notificationStatusComplete
	 );
	if (!updateTasks.isEmpty()) {
		BI_PSP_DatabaseOperationsUtility.updateOperation(
			updateTasks,
			BI_PSPB_NotificationStatusCtrl.class.toString(),
			false
		);
	}	
} catch (Exception ex) {
	BI_PSP_LogMessagesUtility.exceptionLogMessage(
		ex.getMessage(),
		BI_PSPB_NotificationStatusCtrl.class.getName(),
		ex
	);
}
return updateTasks;
}
/**
 * @description Updating the task status as mentioned.
 * @param taskId Id of the Task to be updated.
 * @param newStatus Status of the Task to be updated.
 * @return Returning the task updated.
 */
private static List<Task> updateTaskStatus(
List<Id> taskId,
String newStatus
) {
List<SObject> tasksToUpdate = new List<SObject>();
List<Task> updatedTasks = new List<Task>();
try {
	if (!taskId.isEmpty()) {
		BI_PSP_LogMessagesUtility.logError(
			BI_PSPB_NotificationConstantsCtrl.errorMsgRecordNotFound,
			BI_PSPB_NotificationStatusCtrl.class.toString(),
			false,
			BI_PSPB_NotificationConstantsCtrl.severityError
		);
	}
	tasksToUpdate = BI_PSPB_InsiteTaskQueryctrl.fetchTasks(taskId);
	if (tasksToUpdate.isEmpty()) {
		BI_PSP_LogMessagesUtility.logError(
			BI_PSPB_NotificationConstantsCtrl.errorMsgRecordNotFound,
			BI_PSPB_NotificationStatusCtrl.class.toString(),
			false,
			BI_PSPB_NotificationConstantsCtrl.severityError
		);
	}

	updatedTasks = BI_PSPB_InsiteTaskUpdater.updateTaskStatus(
		tasksToUpdate,
		newStatus
	);
	if (!updatedTasks.isEmpty()) {
		BI_PSP_DatabaseOperationsUtility.updateOperation(
			updatedTasks,
			BI_PSPB_NotificationStatusCtrl.class.toString(),
			false
		);
	}
} catch (System.DmlException ex) {
	BI_PSP_LogMessagesUtility.exceptionLogMessage(
		ex.getMessage(),
		BI_PSPB_NotificationStatusCtrl.class.getName(),
		ex
	);
}
return updatedTasks;
}
	/**
 * @description Updating the task status as mentioned.
 * @param taskId Id of the Task to be updated.
 * @param newStatus Status of the Task to be updated.
 * @return Returning the task updated.
 */
public static void updateTaskStatusSetting(String userType) {
try {
    String whatId;
    String actionRequired = BI_PSPB_NotificationConstantsCtrl.taskStatusAction;
    String category = 'Notification Setting';
    String action = BI_PSPB_NotificationConstantsCtrl.actionTypeAction;
    if(userType == 'Patient'){
		whatId = BI_PSP_CurrentUser.getEnrolleeRecords()[0].id;
    } else {
        whatId = BI_PSP_CurrentUser.returnTheAccounts()[0].id;
    }
    String fields =
			'Id, WhatId, ' +
			'Status, BI_PSP_Category__c, ' +
			'Subject, BI_PSPB_Treatment_Type__c, BI_PSP_Notification_Type__c';
    String conditions = 'WhatId = \'' + whatId + '\' ' +
				'AND Status = \'' + actionRequired + '\' ' +
				'AND BI_PSP_Category__c = \'' + category + '\' ' +
        		'AND BI_PSP_Notification_Type__c = \'' + action + '\' ';
    List<Task> relatedTasks = BI_PSP_CommonQueryUtility.executeQuery(
			'Task',
			fields,
			conditions,
			false
		);
	List<Task> tasks = new List<Task>();
    for (Task t : relatedTasks) {
		t.Status = BI_PSPB_NotificationConstantsCtrl.notificationStatusComplete;
        tasks.add(t);
	}
    BI_PSP_DatabaseOperationsUtility.updateOperation(
		tasks,
		BI_PSPB_ActionNotificationStatusCtrl.class.toString(),
		false
	);
    
} catch (System.DmlException ex) {
	BI_PSP_LogMessagesUtility.exceptionLogMessage(
		ex.getMessage(),
		BI_PSPB_NotificationStatusCtrl.class.getName(),
		ex
	);
}
}
}