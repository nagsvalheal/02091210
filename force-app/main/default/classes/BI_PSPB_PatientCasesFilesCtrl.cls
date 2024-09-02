public with sharing class BI_PSPB_PatientCasesFilesCtrl {
	//Store the error message custom labels
	private static String errorMsg = '';
	/**
* @description		Method to create ContentDocumentLinks for uploading files related to a case record
* @param			fileIds (List<String>)-  this string store the file ids. 
* @param			caseId (Id) this string store the related account ids.
This method used in BI_PSPB_InsertCaserecordforUpdateRx apex.
*/
	public static void getContentDocumentLinks(
		List<String> fileIds,
		string caseId
	) {
		// List to hold ContentDocumentLink records to be inserted.
		List<ContentDocumentLink> fileLinks = new List<ContentDocumentLink>();
		try {
			// The values in the fileIds can be null.Hence null check is not done.
			if (String.isNotBlank(caseId)) {
				// Loop through the list of fileIds provided.
				for (String fileId : fileIds) {
					// Create a ContentDocumentLink record for each fileId.
					ContentDocumentLink link = new ContentDocumentLink(
						ContentDocumentId = fileId,
						LinkedEntityId = caseId,
						ShareType = BI_PSPB_PrescriptionConstantCtrl.shareType // 'V' for sharing the file with the record.
					);
					fileLinks.add(link); // Add the ContentDocumentLink record to the list.
				}
				// Check if there are ContentDocumentLink records to be inserted.
			if(!fileLinks.isEmpty()){
				BI_PSP_DatabaseOperationsUtility.insertOperation(
					fileLinks,
					BI_PSPB_PatientCasesFilesCtrl.class.toString(),
					true
				);
				}
			}
		} catch (Exception ex) {
			BI_PSP_LogMessagesUtility.exceptionLogMessage(
				BI_PSPB_PrescriptionConstantCtrl.errorForInsert,
				BI_PSPB_PatientCasesFilesCtrl.class.toString(),
				ex
			);
		}
	}
	@AuraEnabled
public static void saveFilesToCase(List<FileUploadWrapper> fileUploads, Id caseId) {
    // Verify that the caseId is provided
    if (String.isBlank(caseId)) {
        throw new AuraHandledException('Case ID is required.');
    }

    List<ContentVersion> contentVersions = new List<ContentVersion>();
    List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();

    // Collect file names to check for duplicates
    Set<String> fileNames = new Set<String>();

    for (FileUploadWrapper fileUpload : fileUploads) {
        // Skip file if its name already exists
        if (fileNames.contains(fileUpload.fileName)) {
            continue;
        }
        fileNames.add(fileUpload.fileName);
        // Create a new ContentVersion record
        Blob fileBlob = EncodingUtil.base64Decode(fileUpload.fileData);
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = fileUpload.fileName;
        contentVersion.PathOnClient = '/' + fileUpload.fileName;
        contentVersion.VersionData = fileBlob;
        contentVersion.FirstPublishLocationId = caseId; // Associate file with the Case record
        contentVersions.add(contentVersion);
    }

    if (!contentVersions.isEmpty()) {
        insert contentVersions;

        // Create ContentDocumentLinks to associate the files with the Case record
        // Query existing ContentDocumentLinks to avoid duplicates
        Map<Id, Id> existingLinks = new Map<Id, Id>();
        for (ContentDocumentLink link : [
            SELECT ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :caseId
        ]) {
            existingLinks.put(link.ContentDocumentId, link.LinkedEntityId);
        }

        for (ContentVersion cv : contentVersions) {
            ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
            Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1].ContentDocumentId;
            
            // Check if link already exists
            if (!existingLinks.containsKey(contentDocumentId)) {
                contentDocumentLink.ContentDocumentId = contentDocumentId;
                contentDocumentLink.LinkedEntityId = caseId; // Associate file with the Case record
                contentDocumentLink.ShareType = 'V'; // View permission
                contentDocumentLinks.add(contentDocumentLink);
                existingLinks.put(contentDocumentId, caseId); // Add to existing links map
            }
        }

        if (!contentDocumentLinks.isEmpty()) {
            insert contentDocumentLinks;
        }
    }
}
/*@AuraEnabled(cacheable=true)
public static List<String> getSavedImageUrls(String caseId) {
    List<String> imageUrls = new List<String>();
    List<ContentDocumentLink> docLinks = [SELECT ContentDocumentId, ContentDocument.LatestPublishedVersion.ContentUrl
                                          FROM ContentDocumentLink
                                          WHERE LinkedEntityId = :caseId];
    for (ContentDocumentLink docLink : docLinks) {
        imageUrls.add('/sfc/servlet.shepherd/version/download/' + docLink.ContentDocument.LatestPublishedVersion.Id);
    }
    return imageUrls;
	
}*/
@AuraEnabled(cacheable=true)
public static List<Map<String, String>> getSavedImageUrls(String caseId) {
    List<Map<String, String>> imageUrls = new List<Map<String, String>>();
    
    // Query to get ContentDocumentLink and related ContentVersion details
    List<ContentDocumentLink> docLinks = [
        SELECT ContentDocumentId, 
               ContentDocument.LatestPublishedVersion.ContentUrl, 
               ContentDocument.LatestPublishedVersion.Id, 
               ContentDocument.LatestPublishedVersion.ContentSize,
               ContentDocument.LatestPublishedVersion.FileType  // Add FileType field
        FROM ContentDocumentLink
        WHERE LinkedEntityId = :caseId
    ];
    
    for (ContentDocumentLink docLink : docLinks) {
        Map<String, String> imageInfo = new Map<String, String>();
        imageInfo.put('id', docLink.ContentDocumentId);
        imageInfo.put('url', '/sfc/servlet.shepherd/version/download/' + docLink.ContentDocument.LatestPublishedVersion.Id);
        
        // Convert file size from bytes to kilobytes for readability
        Long fileSizeInBytes = docLink.ContentDocument.LatestPublishedVersion.ContentSize;
        Double fileSizeInMB = fileSizeInBytes / (1024.0 * 1024.0);
        imageInfo.put('size', String.valueOf(fileSizeInMB));
        
        // Include file length in the response
        imageInfo.put('length', String.valueOf(fileSizeInBytes));
        
        // Include file type in the response
        imageInfo.put('type', docLink.ContentDocument.LatestPublishedVersion.FileType);
        
        imageUrls.add(imageInfo);
    }
    
    return imageUrls;
}

// @AuraEnabled
// public static void deleteFile(Id caseId) {
//     try {
//         // Check if the caseId is valid
//         if (caseId == null) {
//             throw new AuraHandledException('Invalid Case ID');
//         }
        
//         // Query ContentDocumentLink to find related records
//         List<ContentDocumentLink> linksToDelete = [
//             SELECT Id 
//             FROM ContentDocumentLink 
//             WHERE LinkedEntityId = :caseId
//         ];
        
//         // Ensure that there are links to delete
//         if (linksToDelete.isEmpty()) {
//             throw new AuraHandledException('No files found to delete for Case ID: ' + caseId);
//         }
        
//         // Delete documents
//         delete linksToDelete;

//         System.debug('File deleted successfully');
//     } catch (Exception e) {
//         System.debug('Error deleting file: ' + e.getMessage());
//         throw new AuraHandledException('Error deleting file: ' + e.getMessage());
//     }
// }
@AuraEnabled
public static void deleteFile(Id caseId, Id fileId) {
    try {
        // Check if the parameters are valid
        if (caseId == null || fileId == null) {
            throw new AuraHandledException('Invalid Case ID or File ID');
        }

        // Query ContentDocumentLink to find the specific record
        List<ContentDocumentLink> linksToDelete = [
            SELECT Id 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :caseId
              AND ContentDocumentId = :fileId
        ];
        
        // Ensure that there are links to delete
        if (linksToDelete.isEmpty()) {
            throw new AuraHandledException('No files found to delete for Case ID: ' + caseId + ' and File ID: ' + fileId);
        }
        
        // Delete documents
        delete linksToDelete;

        System.debug('File deleted successfully');
    } catch (Exception e) {
        System.debug('Error deleting file: ' + e.getMessage());
        throw new AuraHandledException('Error deleting file: ' + e.getMessage());
    }
}


// Wrapper class to handle file data from LWC
public class FileUploadWrapper {
    @AuraEnabled
    public String fileName { get; set; }
    @AuraEnabled
    public String fileData { get; set; } // Base64 encoded file data
}
}