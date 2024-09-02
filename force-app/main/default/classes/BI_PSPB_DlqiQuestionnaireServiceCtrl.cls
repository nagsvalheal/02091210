/** 
* @description  This class provides methods to handle DLQI (Daily Living
* Questionnaire Index) related operations. It processes questionnaires
* when videos are uploaded, creates tasks, and sends notifications (SMS and
* email) as needed.
* History
* Version	Author			Date		Detail		Description
* 1.0		Niyas		24-07-2024		Created		Refactored Version
*/
public with sharing class BI_PSPB_DlqiQuestionnaireServiceCtrl {
/**
* @description  Processes WPai questionnaires by creating tasks for due 
* assessments when a video is uploaded. It also sends notifications (SMS 
* and email) to the relevant parties.
*/ 
public static void processWpaiQuestionnaires() {
try {
	List<Task> newTaskList = new List<Task>();
	List<Id> enrolleeSendIds = new List<Id>();

    Set<Id> enrolleeIds = BI_PSPB_EnrolleeQueryCtrl.fetchEnrolleeIds();

	if (!enrolleeIds.isEmpty()) {
		Integer dlqiCount = BI_PSPB_QuestionsDaysCountQueryCtrl.fetchDlqiCount();
		List<Id> enrolleeRecIds = BI_PSPB_QuestionsSymptomProcessor.processSymptomTrackers(enrolleeIds, dlqiCount);

		if (!enrolleeRecIds.isEmpty()) {
			enrolleeSendIds = BI_PSPB_AssessmentHelperCtrl.fetchDueAssessments(enrolleeRecIds, BI_PSPB_NotificationConstantsCtrl.dlqiQuestionName);
			BI_PSPB_TaskParameters params = new BI_PSPB_TaskParameters(
				BI_PSPB_NotificationConstantsCtrl.dlqiQuestionSubject,
				BI_PSPB_NotificationConstantsCtrl.actionTypeAction,
				BI_PSPB_NotificationConstantsCtrl.dlqi,
				'',
				BI_PSPB_NotificationConstantsCtrl.actionTypeNotificatonTypeAction
			);
			
				newTaskList = BI_PSPB_TaskCreationCtrl.createTasks(
					enrolleeSendIds,
					params
				);
			BI_PSP_DatabaseOperationsUtility.insertOperation(
				newTaskList,
				BI_PSPB_DlqiQuestionnaireServiceCtrl.class.toString(),
				false
			);
			BI_PSPB_NotificationSender.sendNotifications(enrolleeSendIds, BI_PSPB_NotificationConstantsCtrl.dlqi, new List<String>{''});
		}
	} else {
		BI_PSP_LogMessagesUtility.logError(
			BI_PSPB_NotificationConstantsCtrl.errorMsgRecordNotFound,
			BI_PSPB_DlqiQuestionnaireServiceCtrl.class.toString(),
			true,
			BI_PSPB_NotificationConstantsCtrl.severityError
		);
	}
} catch (Exception ex) {
	BI_PSP_LogMessagesUtility.logError(
		ex.getMessage(),
		BI_PSPB_DlqiQuestionnaireServiceCtrl.class.toString()
		,true
		,BI_PSPB_NotificationConstantsCtrl.severityError
	);
}
}
}