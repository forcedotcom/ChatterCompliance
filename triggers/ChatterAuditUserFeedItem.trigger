trigger ChatterAuditUserFeedItem on User (after update) {
	/**
	* only execute the logic id the custom setting is correctly setted
	*/
	if (ChatterAuditUtils.controlCustomSetting()){
	 	String uAdmId = ChatterAuditSettingsHandler.getChatterLogsOwnerId();
	 
	 	List<ArchivedFeedItem__c> li = new List<ArchivedFeedItem__c>();
	 	Map<Id,ArchivedFeedItem__c> mpFeeds = new Map<Id,ArchivedFeedItem__c>();
	 	Set<Id> lentityIds = new Set<Id>();
	 	Set<Id> inactivatedUsers = new Set<Id>();
	 	Set<Id> reactivatedUsers = new Set<Id>();
	 	ArchivedFeedItem__c tmp;
	    //We will build a map [UserId, ArchivedFeedItem__c]
	    Id theId ;
	    for (Integer i = 0; i < trigger.new.size(); i++)
	    {
	        if (trigger.new[i].CurrentStatus != null && trigger.old[i].CurrentStatus!= trigger.new[i].CurrentStatus)
	        {	
	        	
	        	tmp = new ArchivedFeedItem__c();
		        tmp.Body__c		= trigger.new[i].CurrentStatus ; 	        
		        tmp.CreatedDate__c			= trigger.new[i].LastModifiedDate;	        
		        tmp.ParentId__c				= trigger.new[i].Id;
		        tmp.FullArchivedCommentList__c = true;
		        tmp.ParentObjectType__c		= ChatterAuditUtils.getObjectType(String.valueOf(trigger.new[i].Id));
		       	tmp.OwnerId 				= uAdmId;
		        tmp.Type__c					= 'UserStatus';
		        tmp.CommentCount__c			= 0 ;
		        tmp.Created_By__c 			= trigger.new[i].LastModifiedById;
	      		tmp.Inserted_By__c 			= trigger.new[i].LastModifiedById;
	      		 
		        li.add(tmp);
		        mpFeeds.put(trigger.new[i].Id,tmp);	   
		        //to keep track of entity
		        lentityIds.add(trigger.new[i].Id);	  
	        }
	        
	        	  //capture user deactivation or reactivation
		    if ( trigger.old[i].IsActive != trigger.new[i].IsActive  ){
		    	 //to keep track of entity
		    	 if (trigger.new[i].IsActive){
		    	 	reactivatedUsers.add(trigger.new[i].Id);
		    	 }else {
		    	 	inactivatedUsers.add(trigger.new[i].Id);
		    	 }	        	  
		    }
	        
	    }             

		//for each object ArchivedFeedItem__c we need to update the FeedItemId 
		// Query FeedItem table and retrieve UserStatus post created around now 
		List<FeedItem> lFi = [	Select Id , Body, CreatedById 
								from FeedItem 
								where 		Type ='UserStatus' 
										and CreatedDate = TODAY 
										and CreatedById in: mpFeeds.keySet()   
								ORDER BY CreatedDate DESC];
			
		set<Id> processedIds = new set<Id>();
		//go over the list and update the FeedItemId__c field with the Id of the corresponding FeedItem
		for(FeedItem c : lFi){
			
			if (mpFeeds.containsKey(c.CreatedById) && !processedIds.contains(c.CreatedById)){
				processedIds.add(c.CreatedById);				
   				tmp = mpFeeds.get(c.CreatedById);
   				tmp.FeedItemId__c = c.Id;
   				mpFeeds.put(c.CreatedById,tmp);
   			} 			
		}
        li =  mpFeeds.values();
		Map<Id,Id> entitiesIds = ChatterAuditEntityFeedHandler.addEntities(lentityIds);

	     for (ArchivedFeedItem__c af : li){
	    	Id tmpId = af.ParentId__c;
	    	if (entitiesIds.containsKey(tmpId)){
	    		af.ArchivedEntityFeed__c  =  entitiesIds.get(af.ParentId__c);	    	
	    	}
	    }
	    if (!li.isEmpty()){
	    	upsert li;
	    }	    
	}
}