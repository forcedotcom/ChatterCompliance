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
public with sharing class ChatterAuditBatchUpdateUtils {

	/**
	 * Get Select Query
	 *
	 * @return		returns the string query to retrieve all non Deleted Archived Feed Itms
 	 */
	public string getSelectQuery(){

		String query  = ' Select a.isDeleted__c, a.entityObjectType__c, a.entityId__c, a.Id '+
						' From ArchivedEntityFeed__c a where a.isDeleted__c = false ';
		return query;
	}


	/**
	 * Update missing records
	 *
	 * @param itemsToProcess	List of Sobjects to process
	 * @return					returns how many items has been updated
 	 */
	public Integer UpdateMissingRecords(List<sObject> itemsToProcess){
		//Build a Map with entity Type and entities Id list
		Map<String,List<Id>> np = new Map<String,List<Id>>();
		Map<Id,ArchivedEntityFeed__c> itemsById = new Map<Id,ArchivedEntityFeed__c>();
		List<Id> tmp;
		//build list to query eacht type of entity.
		//classify all entities in their corresponding Map key
		for(sObject  obj : itemsToProcess ){
			ArchivedEntityFeed__c  a = (ArchivedEntityFeed__c)obj;
			itemsById.put(a.entityId__c,a);
			if (np.containsKey(a.entityObjectType__c)){
				tmp = np.get(a.entityObjectType__c);
				tmp.add(a.entityId__c);
				np.put(a.entityObjectType__c,tmp);
			}else{
				tmp = new List<Id>{a.entityId__c};
				np.put(a.entityObjectType__c,tmp);
			}
		}
		//check for each type of entity if the entityItems are still alive
		set<Id> totalEntityIds = new set<Id>();
		for(String s : np.keySet()){
			totalEntityIds.addAll(this.checkAgainstEntityTable(s, np.get(s)));
		}
		//execute each query and if the record is missing update as deleted
		List<ArchivedEntityFeed__c> itmsToUPdate = new List<ArchivedEntityFeed__c>();
		ArchivedEntityFeed__c auxItm;
		for(String fId : totalEntityIds){
			if (itemsById.containsKey(fId)){
				auxItm = itemsById.get(fId);
				auxItm.isDeleted__c = true;
				itmsToUPdate.add(auxItm);
			}
		}
		if(!itmsToUPdate.isEmpty()){
			upsert itmsToUPdate;
		}
		return 	itmsToUPdate.size();
	}

	/**
	 * Check against entity table
	 *
	 * @param objectName	Object Name to search in db
	 * @param idsToCheck	List of Id's to search in Object Name given parameter
	 * @return				A set of id's not found in query
 	 */
	private set<Id> checkAgainstEntityTable(String objectName, List<Id> idsToCheck){

		set<Id> lres = new set<Id>();

		if (ChatterAuditUtils.validFeedObject(objectName) && !idsToCheck.isEmpty()){
			lres.addAll(idsToCheck);
			String allIds = '';
			for(Id i : idsToCheck){
				allIds =allIds +',\''+i+ '\'';
			}
			allIds = allIds.substring(1);
			String query = 'Select  a.Id From '+objectName+' a where  a.Id  in ('+allIds+')';
			for(SObject obj : Database.Query(query)){
				lres.remove(obj.Id);
			}
		}
		return lres;
	}
}