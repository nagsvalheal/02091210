/**
 * @description Service controller class for managing community post reminders. 
 *              It handles the processing of pending community post tasks and 
 *              triggers email notifications to community users upon task completion
 * History
 * Version	Author			Date		Detail		Description
 * 1.0		Niyas		24-07-2024		Created		Refactored Version
 */
public with sharing class BI_PSPB_CommunityPostServiceCtrl {
	/**
	 * @description Processes pending community post tasks. 
	 *              It updates the task status and sends notifications to community users.
	 */
	public static void processCommunityPostReminders() {
		try {
			List<Task> taskRecords = BI_PSPB_CommunityTaskQueryCtrl.fetchPendingCommunityPosts();

			if (taskRecords.isEmpty()) {
				BI_PSP_LogMessagesUtility.logError(
					BI_PSPB_NotificationConstantsCtrl.errorMsgRecordNotFound,
					BI_PSPB_CommunityPostServiceCtrl.class.toString(),
					true,
					BI_PSPB_NotificationConstantsCtrl.severityError
				);
			} else {
				List<Id> taskIds = new List<Id>();
				List<Task> newTaskList = new List<Task>();
				List<String> communityUserNames = new List<String>();

				for (Task taskToUpdate : taskRecords) {
					Task newTask = createUpdatedTask(taskToUpdate);
					taskIds.add(taskToUpdate.WhatId);
					communityUserNames.add(
						taskToUpdate.BI_PSP_CommunityUserName__c
					);
					newTaskList.add(newTask);
				}

				if (!newTaskList.isEmpty()) {
					BI_PSP_DatabaseOperationsUtility.updateOperation(
						newTaskList,
						BI_PSPB_CommunityPostServiceCtrl.class.toString(),
						false
					);
				}

				if (!taskIds.isEmpty()) {
					BI_PSPB_NotificationSender.sendNotifications(
						taskIds,
						BI_PSPB_NotificationConstantsCtrl.generalCreatePost,
						communityUserNames
					);
				}
			}
		} catch (Exception ex) {
			BI_PSP_LogMessagesUtility.logError(
          		ex.getMessage(),
          		BI_PSPB_CommunityPostServiceCtrl.class.toString()
				,false
				,BI_PSPB_NotificationConstantsCtrl.severityError
        	);
		}
	}
	/**
	* @description Creates an updated task by modifying the task status to indicate completion.
	* @param taskToUpdate Task that is to be updated.
	* @return Returning the task that is updated.
	*/
	public static Task createUpdatedTask(Task taskToUpdate) {
		Task newTask = new Task();
		try {
			if (taskToUpdate == null) {
				BI_PSP_LogMessagesUtility.logError(
					BI_PSPB_NotificationConstantsCtrl.errorMsgRecordNotFound,
					BI_PSPB_CommunityPostServiceCtrl.class.toString(),
					true,
					BI_PSPB_NotificationConstantsCtrl.severityError
				);
			} else {
				newTask.Id = taskToUpdate.Id;
				newTask.BI_PSP_CommunityPostStatus__c = BI_PSPB_NotificationConstantsCtrl.notificationStatusComplete;
			}
		} catch (Exception ex) {
			BI_PSP_LogMessagesUtility.logError(
          		ex.getMessage(),
          		BI_PSPB_CommunityPostServiceCtrl.class.toString()
				,true
				,BI_PSPB_NotificationConstantsCtrl.severityError
        	);
		}
		return newTask;
	}
}