trigger ChatterAuditFeedItem on FeedItem (after insert, after delete) {
	/**
	* only execute the logic id the custom setting is correctly setted
	*/
	if (ChatterAuditUtils.controlCustomSetting()){
		List<ArchivedFeedItem__c> li = new List<ArchivedFeedItem__c>();
		String uAdmId = ChatterAuditSettingsHandler.getChatterLogsOwnerId();
		List<Id> lUsers = new List<Id>();
		Set<Id> lentityIds = new Set<Id>();
		if (trigger.isInsert){
	
			ArchivedFeedItem__c tmp;
		     for (FeedItem f : trigger.new){
		        tmp = new ArchivedFeedItem__c();
		         tmp.Type__c					= f.Type;
		        //Feed Item title
		        if (f.Type == 'LinkPost' ||f.Type == 'ContentPost'  ){
		        	tmp.Title__c	= f.Title;
		        	tmp.LinkUrl__c	= f.LinkUrl;     
		        } 
		        if (f.Type == 'ContentPost'  ){
		        	tmp.ContentType__c	= f.ContentType;
		        	tmp.ContentSize__c	= f.ContentSize;  	        	
		        	tmp.ContentDescription__c	= f.ContentDescription;
		        	tmp.ContentFileName__c		= f.ContentFileName;   
		        } 
		        //ContentSize__c
		        tmp.FullArchivedCommentList__c = (f.CommentCount == 0);
		        tmp.Body__c					= f.Body;	 
	      		
	      		tmp.Created_By__c 			= f.CreatedById;
	      		tmp.Inserted_By__c 			= (f.InsertedById != null) ? f.InsertedById : f.CreatedById ;
	      		
	      		tmp.CreatedDate__c			= f.CreatedDate;
		        tmp.ParentId__c				= f.ParentId;
		        tmp.ParentObjectType__c		= ChatterAuditUtils.getObjectType(String.valueOf(f.ParentId));
		        tmp.RelatedRecordId__c		= f.RelatedRecordId;
		        tmp.FeedItemId__c	= f.Id;
		        tmp.OwnerId 				= uAdmId;
		        tmp.CommentCount__c			= f.CommentCount ;
		        li.add(tmp);
		        //to keep track of entity
		        lentityIds.add(f.ParentId);	         
		    }
			// Store Feed Entities
		    Map<Id,Id> entitiesIds = ChatterAuditEntityFeedHandler.addEntities(lentityIds);
		    // Retrive 
		    
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
	
		if (trigger.isDelete){
			set<Id> oldIDs = new set<Id>();
			
		    for (FeedItem f : trigger.old){
				oldIDs.add(f.Id);
			}				
			ChatterAuditUtils.setEditAllowedForPosts(true);
			ChatterAuditFeedItemsHandler.updateItemsAsDeleted(oldIDs);
			
		}
	}
}