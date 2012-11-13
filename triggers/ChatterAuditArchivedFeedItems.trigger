trigger ChatterAuditArchivedFeedItems on ArchivedFeedItem__c (before delete, before update) {

		if ( trigger.isDelete && !ChatterAuditUtils.getIsDeleteAllowedForPosts() ){
			for( ArchivedFeedItem__c a : trigger.old ){			
					a.addError(Label.ChatterAudit_ExceptionMessage_manual_delete_forbidden);
			}	        	
		}
		if (trigger.isUpdate && !ChatterAuditUtils.getIsEditAllowedForPosts()){
			for( ArchivedFeedItem__c a : trigger.new ){			
					a.addError(Label.ChatterAudit_ExceptionMessage_manual_delete_forbidden);
			}	        	
		}		

}