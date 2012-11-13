trigger ChatterAuditFeedComment on FeedComment (before delete, after insert) {

	/**
	* only execute the logic id the custom setting is correctly setted
	*/
	if (ChatterAuditUtils.controlCustomSetting()){
		list<ArchivedFeedComment__c> l = new list<ArchivedFeedComment__c>();
		ArchivedFeedComment__c unC;
		//Getting an Owner Id with enough privileges to do the tasks
		String uAdmId = ChatterAuditSettingsHandler.getChatterLogsOwnerId();

		map<Id,Id> parentsIdsList = new map<Id,Id>();
		Map<Id,Integer> itemsMap  = new Map<Id,Integer>();
		map<Id,Id> ArchivedFeedItemParents;

		if ( trigger.isInsert ){

			for ( FeedComment f : trigger.new ){
				unC = new ArchivedFeedComment__c();
				unC.CommentBody__c				= f.CommentBody;
				unC.CreatedDate__c				= f.CreatedDate;
				unC.FeedItemId__c				= f.FeedItemId;
				unC.ParentId__c					= f.ParentId;
				unC.IsDeleted__c				= f.IsDeleted;
				unC.FeedCommentId__c			= f.Id;				
				unC.Created_By__c				= f.CreatedById;
	      		unC.Inserted_By__c				= (f.InsertedById != null) ? f.InsertedById : f.CreatedById ;
				
				unC.RelatedRecordId__c			= f.RelatedRecordId;
				
				unC.ParentObjectType__c         = ChatterAuditUtils.getObjectType( unC.ParentId__c );
				//Add admin owner Id
				uNC.OwnerId                   = uAdmId;
				//Add to parentsIdsList for further use (for query to get ArchivedFeedItem corresponding Id)
				parentsIdsList.put( unC.FeedItemId__c , f.ParentId);
				//update itemsMap
				Integer tmpC = 0;
				if (itemsMap.containsKey(f.FeedItemId)){
					tmpC = itemsMap.get(f.FeedItemId);					
				}				
				tmpC++;
				itemsMap.put(f.FeedItemId,tmpC);
				
				
			l.add(unC);
			}
			ChatterAuditUtils.setEditAllowedForPosts(true);
			ArchivedFeedItemParents = ChatterAuditFeedItemsHandler.getArchivedFeedItemsIdByFeedId( parentsIdsList );

			if ( ArchivedFeedItemParents != null ){
				for ( integer i=0; i<l.size(); i++ ){
					//Set lookUp field to complete objs info
					l[i].ArchivedFeedItem__c = ArchivedFeedItemParents.get( l[i].FeedItemId__c );
				}
				//with all info complete , upsert the list
				upsert l;
    		}
    		
    			//update the corresponding ArchivedFeedItems Comment CountField
    			ChatterAuditFeedItemsHandler.updateCommentCount(itemsMap,true);
    		
		}

		if ( trigger.isDelete ){
			list<Id> lDeleted = new list<Id>();

			for ( FeedComment f : trigger.old ){
				lDeleted.add( f.Id );
			}
			ChatterAuditUtils.setEditAllowedForPosts(true);
			ChatterAuditFeedCommentsHandler.updateItemsAsDeletedByFeedCommentId( lDeleted );
  		}
	}
}