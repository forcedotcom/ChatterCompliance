global class ChatterAuditDeleteItemsByPostIdBatch implements Database.Batchable<SObject>, Database.Stateful{	
	
	/**
	 * Batch Start Method
	 *
	 * @param ctx
	 * @return				String with query
 	 */
    global Database.queryLocator start(Database.BatchableContext ctx){
       // Will use a.ArchivedFeedItem__c = null as this field is a lookup, and this batch executes after deletion of parent record
        return Database.getQueryLocator( [Select a.Id
											From ArchivedFeedComment__c a
											where a.ArchivedFeedItem__c = null
											limit :ChatterAuditConstants.MAX_DML_ROWS_BATCH] );
    }
    
    /**
	 * Batch execute Method
	 *
	 * @param ctx
	 * @param data		List of Sobject
 	 */
    global void execute(Database.BatchableContext ctx, List<Sobject> results){
       this.deleteComments(results);
    }
    
    /**
	 * Batch Finish Method
	 *
	 * @param ctx
 	 */
    global void finish(Database.BatchableContext ctx){    	
    }
	
	/**
	 * Delete comments
	 * @param results -- list<Sobject>
	 **/
	public void deleteComments(List<Sobject> results){
		ChatterAuditUtils.setDeleteAllowedForPosts(true);
		delete results;
		ChatterAuditUtils.setDeleteAllowedForPosts(false);
	}	
}