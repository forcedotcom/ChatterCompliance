/*
Copyright (c) 2011, salesforce.com, Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, 
are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, 
    this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, 
    this list of conditions and the following disclaimer in the documentation 
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
public with sharing class ChatterAuditEntityFeedHandler {

	/**
	 * create  ArchivedEntityFeed__c
	 *
	 * @param entitiesList		a set that contains entities Ids
 	 * @return            		a Map<Id,Id> filtered
 	 */
	public static Map<Id,Id> addEntities(Set<id> entitiesList){
		

		Map<Id,Id> entitiesIds = new Map<Id,Id>();
		//filter and only add entity feeds for objects not already registered
		for (ArchivedEntityFeed__c eIn : [Select a.entityId__c , a.Id
								From ArchivedEntityFeed__c a
								where  a.entityId__c in: entitiesList
								limit :ChatterAuditConstants.MAX_DML_ROWS ]){

				entitiesIds.put(eIn.entityId__c,eIn.Id);
				entitiesList.remove(eIn.entityId__c);
		}
		List<ArchivedEntityFeed__c> lItms = new List<ArchivedEntityFeed__c>();
		for(Id  i : entitiesList ){
			lItms.add(new ArchivedEntityFeed__c(entityId__c = i, isDeleted__c = false , entityObjectType__c = ChatterAuditUtils.getObjectType(String.valueOf(i)), OwnerId = ChatterAuditSettingsHandler.getChatterLogsOwnerId()));
		}
		if (!lItms.isEmpty()){
			upsert lItms;
		}
		//
				updateEntityFeedNames(entitiesList);
		//
		
		for(ArchivedEntityFeed__c  i : lItms ){
			entitiesIds.put(i.entityId__c,i.Id);
		}
		
		return entitiesIds;
	}

	/**
	 * Update all ArchivedEntityFeed__c to isDeleted = true
	 *
	 * @param idsToUpdate		a set that contains the Id's to be updated
	 * @param isDeleted 		TRUE to set as deleted "idsToUpdate", FALSE the opposite
 	 */
	public static void updateItemsDeletedStatus(Set<id> idsToUpdate, boolean isDeleted){
		
		ChatterAuditUtils.setEditAllowedForPosts(true);
		
		List<ArchivedEntityFeed__c> lArch = [Select a.Id,a.isDeleted__c ,a.entityId__c
											From ArchivedEntityFeed__c a
											where a.isDeleted__c =: !isDeleted and a.entityId__c in: idsToUpdate
											limit :ChatterAuditConstants.MAX_DML_ROWS];

		for(ArchivedEntityFeed__c  a : lArch ){
			a.isDeleted__c = isDeleted;
		}
		if (!lArch.isEmpty()){
			upsert lArch;
		}
		if (lArch.size()==999){
			ChatterAuditEntityFeedHandler.updateItemsDeletedStatus(idsToUpdate,isDeleted);
		}
	}

	/**
	 * Delegation to ChatterAuditEntityFeedHandler.updateItemsDeletedStatus
	 *
	 * @param idsToUpdate		a set that contains the Id's to be updated
	 * @param isDeleted 		TRUE to set as deleted "idsToUpdate", FALSE the opposite
 	 */
	public static void updateItemsDeletedStatusFuture(Set<id> idsToUpdate, boolean isDeleted){
		ChatterAuditEntityFeedHandler.updateItemsDeletedStatus( idsToUpdate, isDeleted);
	}

	/**
	 * Updates entities feed names of a given set of id's
	 *
	 * @param entitiesList		a set that contains the Id's to be updated
	 */
	public static void updateEntityFeedNames(Set<Id> entitiesList){

		//Only for collaboration group , keep adding if necesary
		list<Id> entitiesIds = new list<Id>();

		for(Id  i : entitiesList ){
			String aux = ChatterAuditUtils.getObjectType(i);
			//Only for collaboration group , keep adding if necesary
			/*if ( aux == 'CollaborationGroup' )*/ entitiesIds.add(i);
		}

		if(entitiesIds.size() > 0){
			updateEntityFeedNamesByKey(entitiesIds, ChatterAuditUtils.getObjectType(entitiesIds[0]));
		}
	}

	/**
	 * Updates entities feed names of a given set of id's by Key
	 *
	 * @param entitiesList		a list that contains the Id's to be updated
	 * @param tableName			String with name of table to query for the list of id's given
	 */
	public static void updateEntityFeedNamesByKey(list<Id> entitiesList, String tableName){

		String entitiesListString = '';
		for(Integer i=0;i<entitiesList.size();i++){
			entitiesListString += '\''+entitiesList[i]+'\'';
			entitiesListString += (i == (entitiesList.size() - 1) ) ? '' : ',';
		}

		String fieldName = '';
		
		if ( tableName == 'Case' ) fieldName = 'CaseNumber';
        if ( tableName == 'Dashboard' ) fieldName = 'Title';
        if ( tableName == 'ContentDocument' ) fieldName = 'Title';
        if ( tableName == 'Contract' ) fieldName = 'ContractNumber';
        if ( tableName == 'Task' ) fieldName = 'Subject';
        if ( tableName == 'Solution' ) fieldName = 'SolutionNumber';
        if ( tableName == 'Event' ) fieldName = 'Subject';
        if ( tableName != 'Case' && tableName != 'Dashboard' && tableName != 'ContentDocument' && tableName != 'Contract' && tableName != 'Task' && tableName != 'Solution' && tableName != 'Event') fieldName = 'Name';
		 
		String query = 	'Select '+ fieldName +', Id'+ 
						' From '+tableName+' Where Id in ('+entitiesListString+') limit '+ChatterAuditConstants.MAX_DML_ROWS;
		list<sObject> entities; 

		try{
			entities = Database.query(query);
		   }catch(Exception e){ ChatterAuditUtils.mailException(e.getMessage(), 'updateEntityFeedNamesByKey'); }

		list<ArchivedEntityFeed__c> archivedEntities        = new list<ArchivedEntityFeed__c>();
		list<ArchivedEntityFeed__c> archivedEntitiesChanged = new list<ArchivedEntityFeed__c>();

		if( entities != null){

			archivedEntities = [Select Name, Id, entityId__c From ArchivedEntityFeed__c where entityId__c IN :entitiesList];

			//Saving script statements , putting all archived entities in a map
			map<Id,ArchivedEntityFeed__c> archivedEntitiesMap = new map<Id,ArchivedEntityFeed__c>();

			for (integer i=0;i<archivedEntities.size();i++){
				archivedEntitiesMap.put(archivedEntities[i].entityId__c,archivedEntities[i]);
			}

			for (integer i=0; i<entities.size();i++){

				Id		entityId	= String.valueOf(entities[i].get('Id'));
				String 	entityName 	= '';
				
				 if ( tableName == 'Case' ) {
                            entityName = String.valueOf(entities[i].get('CaseNumber'));
                        }else if ( tableName == 'Dashboard' || tableName == 'ContentDocument'){
                            entityName = String.valueOf(entities[i].get('Title'));
                        }else if ( tableName == 'Task' || tableName == 'Event'){
                            entityName = String.valueOf(entities[i].get('Subject'));
                        }else if ( tableName == 'Contract'){
                            entityName = String.valueOf(entities[i].get('ContractNumber'));
                        }else if ( tableName == 'Solution'){
                            entityName = String.valueOf(entities[i].get('SolutionNumber'));
                        }else{
                            entityName = String.valueOf(entities[i].get('Name'));
                        }		
				
				ArchivedEntityFeed__c archivedEntity = archivedEntitiesMap.get(entityId);

				if( archivedEntitiesMap.containsKey(entityId) &&
					archivedEntity.Name != null &&
					archivedEntity.Name != entityName){

						//If here means Ids are equals but name has been changed, therefore we need an update
						archivedEntity.Name = entityName;
						archivedEntitiesChanged.add(archivedEntity);
				}
			}
		}
		if (archivedEntitiesChanged.size() > 0) upsert archivedEntitiesChanged;
	}

	/**
	 * Search for group names that match with the given parameter
	 *
	 * @param s					String with the name of the group/s to search
	 * @return            		a List of Items that matches with the given parameter
	 */
	public static List<ChatterAuditLookUpController.Item> getGroupListByName(String s ){

		String itemsToQuery='';
		String q = 	' SELECT  Id, entityId__c, Name '+
						' FROM ArchivedEntityFeed__c '+
						' WHERE entityObjectType__c = \''+ChatterAuditConstants.ChatterGroup+'\' and Name LIKE '+s ;
		List<ChatterAuditLookUpController.Item> ret = new List<ChatterAuditLookUpController.Item>();
   		set<String> alreadyIn = new set<String>();

   		//store Ids to return
		String tmpId;
		String tmpName;
		String entityId_api_name		= Schema.SObjectType.ArchivedEntityFeed__c.fields.entityId__c.getName();
		String name_api_name	= Schema.SObjectType.ArchivedEntityFeed__c.fields.Name.getName();
		
		//check fls		
		if (Schema.sObjectType.ArchivedEntityFeed__c.fields.Id.isAccessible() &&
			Schema.sObjectType.ArchivedEntityFeed__c.fields.Name.isAccessible() ){
			for (SObject  obj :Database.query(q)) {
				tmpId 	= String.valueOf(obj.get(entityId_api_name));
				tmpName = String.valueOf(obj.get(name_api_name));
				if (!alreadyIn.contains(tmpId+'-'+tmpName)){
					ret.add(new ChatterAuditLookUpController.Item(tmpId,tmpName));
					alreadyIn.add(tmpId+'-'+tmpName);
				}
			}
		}		
				

		return ret;
	}
	
	public static Boolean isEmptyEntitiesTable(){
	
		list<ArchivedEntityFeed__c> l = [Select Id from ArchivedEntityFeed__c limit 1];
		
		return (l.isEmpty());
		
	}
}