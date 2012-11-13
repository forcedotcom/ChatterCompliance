/*
Copyright (c) 2011, salesforce.com, Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, 
are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, 
    this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, 
    this list of condit
    and/or other materials provided with the distribution.
    * Neither the name of the salesforce.com, Inc. nor the names of its contributors 
    may be used to endorse or promote products derived from this software 
    without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE 
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED 
OF THE POSSIBILITY OF SUCH DAMAGE.

*/
public with sharing class ChatterAuditBatchLoaderUtils { 


	/**
	* Max DML Rows on Batch
	*/
	public static final Integer MAX_DML_ROWS_BATCH	= 49900;
	/**
	 * Get Select Query
	 *
	 * @return		returns the string query to retrieve MAX_DML_ROWS_BATCH FeedItems and their Comments
 	*/
	public string getSelectQuery(){
		
		String lDate = null;
		String 	query  =' Select Id, Type, Title, LinkUrl, ContentType, ContentSize, ContentDescription, ContentFileName, CommentCount, Body, CreatedById, CreatedDate, ParentId, RelatedRecordId, InsertedById  '+
						' , (Select Id, FeedItemId, ParentId, CreatedById, CreatedDate, CommentBody, IsDeleted, InsertedById From FeedComments) ' +
						' From FeedItem where type != \'TrackedChange\' ';

				query += (lDate != null) ? ' and  CreatedDate >= '+lDate: ''  ;									
				query +=' Order by CreatedDate asc Limit ';
				if (ChatterAuditTestEnvironment.isTest){
					query +=' 200 ';
				}else{
					query +=  MAX_DML_ROWS_BATCH;
				}	
		
		return query;
	}

 
	/**
	 * load chatter records
	 *
	 * @param itemsToProcess	List of Sobjects to process
	 * @return					returns how many items has been updated
 	 */
	public Integer loadChatterRecords(list<sObject> itemsToProcess){
		
		string debugStr = '';		
		String uAdmId = ChatterAuditSettingsHandler.getChatterLogsOwnerId();
		//Auxiliar variables for archiving feed entities
		Set<Id> lentityIds	= new Set<Id>();
				
		//Auxiliar variables for archiving FeedItems		
		Map<Id,FeedItem> postById 		= new Map<Id,FeedItem>();
		list<ArchivedFeedItem__c> li	= new list<ArchivedFeedItem__c>();
		
		//auxiliar variables for loading FeedComment
		Map<Id,list<FeedComment>> 	commentByPostId	= new Map<Id,list<FeedComment>>();
		list<FeedComment> lFc = null;
		
		list<ArchivedFeedComment__c> l = new list<ArchivedFeedComment__c>();
		ArchivedFeedComment__c unC;
		ArchivedFeedItem__c tmp;
		map<Id,Id> parentsIdsList = new map<Id,Id>();
		map<Id,Id> ArchivedFeedItemParents;
		
		// Go over the sObjects list we received on the execute batch
		// convert each sObject into FeedItems and populate maps
		for(sObject  obj : itemsToProcess ){
			FeedItem  f = (FeedItem)obj;
			postById.put(f.Id,f);
			lFc = f.FeedComments;
			commentByPostId.put(f.Id,lFc);	
			debugStr +='#'+f.Id;
		}
				 	
		// iterate over the postById and buil each ArchivedFeed Post

		//the logic below is basically the same that is performed on the FeedItems afterInsert Trigger
		for (FeedItem f : postById.values()){ 
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
	    
		// load all Feed Entitites mentioned in the FeedItems
	    Map<Id,Id> entitiesIds = loadeAddEntities(lentityIds);
		// update the relation between ArchivedFeedItem and ArchivedFeedEntities
		for (ArchivedFeedItem__c af : li){
	    	Id tmpId = af.ParentId__c;
	    	if (entitiesIds.containsKey(tmpId)){
	    		af.ArchivedEntityFeed__c  =  entitiesIds.get(af.ParentId__c);	    	
	    	}
	    }
	    if (!li.isEmpty()){
	    	Schema.SObjectField fNItem = ArchivedFeedItem__c.Fields.FeedItemId__c;	    	
	    	List<Database.upsertResult> uResults = Database.Upsert(li,fNItem, false);
	    	
	    }
		//now load all related comments
		for (ArchivedFeedItem__c af : li){			
			
			if (commentByPostId.containsKey(af.FeedItemId__c)){

				lFc = commentByPostId.get(af.FeedItemId__c);
				for (FeedComment c : lFc){					
					unC = new ArchivedFeedComment__c();
					unC.CommentBody__c 		      = c.CommentBody;
					
					unC.CreatedDate__c			  = c.CreatedDate;
					unC.FeedItemId__c  			  = c.FeedItemId;
					unC.ParentId__c    			  = c.ParentId;
					unC.IsDeleted__c				= c.IsDeleted;
					unC.FeedCommentId__c			= c.Id;
					
					unC.Created_By__c 			= c.CreatedById;
	      			unC.Inserted_By__c 			= (c.InsertedbyId != null) ? c.InsertedById : c.CreatedById ;
										
					unC.ParentObjectType__c         = ChatterAuditUtils.getObjectType( unC.ParentId__c );
					//Add admin owner Id
					uNC.OwnerId                   = uAdmId;
					//Add to parentsIdsList for further use (for query to get ArchivedFeedItem corresponding Id)
					unC.ArchivedFeedItem__c		= af.Id;					
					l.add(unC);
				}
			}

	    }
	    if (!l.isEmpty()){
    		Schema.SObjectField fNComment = ArchivedFeedComment__c.Fields.FeedCommentId__c;
    		Database.Upsert(l,fNComment, false);
	    }		
		
		
		return 	li.size();
	}

	/**
	 * checkImportIsComplete
	 * returns true if all registers were copied. 	 
 	 * @return            		
 	 */
	public static  Boolean checkImportIsComplete(){
		DateTime maxLoadedDate = null;
		Id maxLoadedId = null;
		Id maxStoredId = null;
		List<ArchivedFeedItem__c> l = [	Select Id, CreatedDate__c, FeedItemId__c
										from ArchivedFeedItem__c 
										order by CreatedDate__c desc, FeedItemId__c desc
										limit 1 ];
		if (!l.isEmpty()){
			maxLoadedDate = l.get(0).CreatedDate__c;
			maxLoadedId = l.get(0).FeedItemId__c;
		}								

		List<FeedItem> lF = [	Select Id, CreatedDate
								from FeedItem 
								where	type != 'TrackedChange'
									order by CreatedDate desc, Id desc
									limit 1 ];
		if (!lF.isEmpty()){
			maxStoredId = lF.get(0).Id;
		}
	  
		return (maxLoadedId == maxStoredId);
	}


	/**
	 * create  ArchivedEntityFeed__c
	 * this method will create/update the corresponding ArchivedEntityFeed__c for each entry in the
	 * @param entitiesList		a set that contains entities Ids
 	 * @return            		a Map<Id,Id> filtered
 	 */
	public static Map<Id,Id> loadeAddEntities(Set<id> entitiesList){

		// update Entities names		
		loaderUpdateEntityFeedNames(entitiesList);

		Map<Id,Id> entitiesIds = new Map<Id,Id>();
		//filter and only add entity feeds for objects not already registered
		for (ArchivedEntityFeed__c eIn : [Select a.entityId__c , a.Id
								From ArchivedEntityFeed__c a
								where  a.entityId__c in: entitiesList
								limit : MAX_DML_ROWS_BATCH ]){

				entitiesIds.put(eIn.entityId__c,eIn.Id);
				entitiesList.remove(eIn.entityId__c);
		}
		
		list<ArchivedEntityFeed__c> lItms = new list<ArchivedEntityFeed__c>();
		for(Id  i : entitiesList ){
			lItms.add(new ArchivedEntityFeed__c(entityId__c = i, isDeleted__c = false , entityObjectType__c = ChatterAuditUtils.getObjectType(String.valueOf(i)), OwnerId = ChatterAuditSettingsHandler.getChatterLogsOwnerId()));
		}
		if (!lItms.isEmpty()){
			upsert lItms;
		}
		//
		for(ArchivedEntityFeed__c  i : lItms ){
			entitiesIds.put(i.entityId__c,i.Id);
		}		
		
		return entitiesIds;
	}

	/**
	 * Updates entities feed names of a given set of id's
	 *
	 * @param entitiesList		a set that contains the Id's to be updated
	 */
	
	public static void loaderUpdateEntityFeedNames(Set<Id> entitiesList){ 
		//Only for collaboration group , keep adding if necesary
		Map<String, list<Id>> mapTypeId = new Map<String, list<Id>>();
		list<Id> entitiesIds = null;

		for(Id  i : entitiesList ){
			String aux = ChatterAuditUtils.getObjectType(i);
			if (mapTypeId.containsKey(aux)){
				entitiesIds = mapTypeId.get(aux);
			}else{
				entitiesIds = new list<Id>();
			}			
			entitiesIds.add(i);
			mapTypeId.put(aux,entitiesIds);
		}
		for(String s: mapTypeId.keySet()){
			entitiesIds = mapTypeId.get(s);						
			if(entitiesIds.size() > 0){				
				LoaderInsertEntityFeedNamesByKey(entitiesIds, s);
			}
			
		}
	}

	/**
	 * Updates entities feed names of a given set of id's by Key
	 *
	 * @param entitiesList		a list that contains the Id's to be updated
	 * @param tableName			String with name of table to query for the list of id's given
	 */
	public static void LoaderInsertEntityFeedNamesByKey(list<Id> entitiesList, String tableName){

		String entitiesListString = '';
		for(Integer i=0;i<entitiesList.size();i++){
			entitiesListString += '\''+entitiesList[i]+'\'';
			entitiesListString += (i == (entitiesList.size() - 1) ) ? '' : ',';
		}

		String fieldName = '';
		
		if ( tableName == 'Case' ) fieldName = 'CaseNumber';
		if ( tableName == 'Dashboard' ) fieldName = 'Title';
		if ( tableName != 'Case' && tableName != 'Dashboard') fieldName = 'Name';

		String query = 	'Select '+ fieldName +', Id'+
						' From '+tableName+' Where Id in ('+entitiesListString+') limit '+ MAX_DML_ROWS_BATCH;
		list<sObject> entities;
		try{
			entities = Database.query(query);
	   }catch(Exception e){ 
		   	ChatterAuditUtils.mailException(e.getMessage(), 'updateEntityFeedNamesByKey'); 
	   	}

		list<ArchivedEntityFeed__c> archivedEntities        = new list<ArchivedEntityFeed__c>();
		list<ArchivedEntityFeed__c> archivedEntitiesChanged = new list<ArchivedEntityFeed__c>();

		if( entities != null){

			archivedEntities = [Select Name, Id, entityId__c From ArchivedEntityFeed__c where entityId__c IN :entitiesList];

			//Saving script statements , putting all archived entities in a map
			map<Id,ArchivedEntityFeed__c> archivedEntitiesMap = new map<Id,ArchivedEntityFeed__c>();

			for (integer i=0;i<archivedEntities.size();i++){
				archivedEntitiesMap.put(archivedEntities[i].entityId__c,archivedEntities[i]);
			}
			ArchivedEntityFeed__c archivedEntity = null;
			for (integer i=0; i<entities.size();i++){

				Id		entityId		= String.valueOf(entities[i].get('Id'));
				
				String 	entityName	= '';				
		
				if ( tableName == 'Case' ) entityName = String.valueOf(entities[i].get('CaseNumber'));
				if ( tableName == 'Dashboard' ) entityName = String.valueOf(entities[i].get('Title'));
				if ( tableName != 'Case' && tableName != 'Dashboard') entityName = String.valueOf(entities[i].get('Name'));
				
				if (archivedEntitiesMap.containsKey(entityId)){
					archivedEntity = archivedEntitiesMap.get(entityId);
				}else{
					archivedEntity = new ArchivedEntityFeed__c(entityId__c = entityId, isDeleted__c = false , entityObjectType__c =tableName, OwnerId = ChatterAuditSettingsHandler.getChatterLogsOwnerId());
				}
				
				//If here means Ids are equals but name has been changed, therefore we need an update
				archivedEntity.Name = entityName;
				archivedEntitiesChanged.add(archivedEntity);
				
			}
		}
		if (archivedEntitiesChanged.size() > 0) upsert archivedEntitiesChanged;
		
	}

	/**
	* get batch next execution time
	*
	* @return String			String with next fire time
	*/
	public static string getBatchNextExecutionTime(){
		
		Integer minutesFreq = 1;
		Datetime rightNow = Datetime.now();
		Datetime nextFireTime = rightNow.addMinutes(minutesFreq);
		
		String hour =String.valueOf(nextFireTime.Hour());
        String min = String.valueOf(nextFireTime.minute());
        String ss = String.valueOf(nextFireTime.second());
        String day = String.valueOf(nextFireTime.day());
        String month = String.valueOf(nextFireTime.month());
        String year = String.valueOf(nextFireTime.year());
		String nextFireTimeStr = ss + ' ' + min + ' ' + hour + ' ' + day + ' ' + month + ' ? ' + year;
        return nextFireTimeStr;
	}

}