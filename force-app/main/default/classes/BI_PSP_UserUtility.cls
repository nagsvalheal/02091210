public without sharing class BI_PSP_UserUtility {
    @future
    public static void updateUserEmailsAndUsernames(Map<Id, String> accountEmailMap) {
        // Query the Users associated with the updated Accounts
        List<User> usersToUpdate = [SELECT Id, Email, Username, AccountId FROM User WHERE AccountId IN :accountEmailMap.keySet()];
        
        for (User user : usersToUpdate) {
            // Update the User's Username to match the Account's new Email
            String newEmail = accountEmailMap.get(user.AccountId);
            user.Username = newEmail;
        }
        
        if (!usersToUpdate.isEmpty()) {
            try {
                // Perform the update
            BI_PSP_DatabaseOperationsUtility.updateOperation(
            usersToUpdate, 
            BI_PSP_UserUtility.class.getName(), 
            false
        );
            } catch (DmlException ex) {
               BI_PSP_LogMessagesUtility.exceptionLogMessage(
			ex.getMessage(),
				BI_PSP_UserUtility.class.getName(),
				ex
			); 
            }
        }
        
    }
}