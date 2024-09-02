public class BI_PSP_UserEmailUsernameSyncScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        updateMismatchedUsernames();
    }

    @future
    public static void updateMismatchedUsernames() {
        List<User> usersToUpdate = new List<User>();
       List<Profile> profiles = [SELECT Id FROM Profile WHERE Name IN ('BI_PSP_Patient Profile', 'BI_PSP_Caregiver Profile')];
        
        // Extract the Profile Ids into a Set for easy filtering
        Set<Id> profileIds = new Set<Id>();
        for (Profile p : profiles) {
            profileIds.add(p.Id);
        }

        
        // Query for all Users
        List<User> users = [
            SELECT Id, Username, Email 
            FROM User where ProfileId = :profileIds
        ];
        
        // Prepare the list of users to update
        for (User u : users) {
            if (u.Username != u.Email) {
                u.Email = u.Username;
                usersToUpdate.add(u);
            }
        }
        
        // Perform the update if there are mismatches
        if (!usersToUpdate.isEmpty()) {
            BI_PSP_DatabaseOperationsUtility.updateOperation(
            usersToUpdate, 
            BI_PSP_UserEmailUsernameSyncScheduler.class.getName(), 
            false
        );
        }
    }
}