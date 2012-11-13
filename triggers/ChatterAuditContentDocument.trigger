trigger ChatterAuditContentDocument on ContentDocument (before delete) {
	
	//Check if Deletion is allowed
	if ( ChatterAuditUtils.getIsContentDocumentDeleteAllowed() ) return;
	
	set<Id> documentsIds = Trigger.oldMap.keySet();
	
    //Getting first versions grouped by ContentDocument
	Map<Id, ContentVersion> documentVersions = new Map<Id, ContentVersion>([ Select c.Id
                            from ContentVersion c 
                            where c.ContentDocumentId IN :documentsIds
                            and c.VersionNumber = '1' 
                            limit 9999]);
    
    set<Id> versions = documentVersions.KeySet();
											
	boolean itemsFound = false;
	
	//Having the versions lets figure it out if document belong to any post/comment related with chatter
	itemsFound = ChatterAuditFeedItemsHandler.existsArchivedFeedItemsWithContentVersion(versions);
	
											
	//Continue with archived feed comments
	if ( !itemsFound ){
		itemsFound = ChatterAuditFeedItemsHandler.existsArchivedFeedCommentsWithContentVersion(versions);
	}
	
	if ( itemsFound ){
		for (Integer i = 0; i < trigger.old.size(); i++){
			trigger.old[i].addError(Label.ChatterAudit_deleteBlock);
		}				
	}
}