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
public with sharing class ChatterAuditChatterUtilities {

	/**
	 * Get all group the given User is a member
	 *
	 * @param queryIds   		String with Id's to query
	 * @return					String with Id's of Groups
 	 */
	public static String getUserGroupsById(String queryIds){
		String itemsToQuery='';
		set<Id> itemsToReturn = new set<Id>();
		String sqlQ =	'	SELECT  c.CollaborationGroupId'+
						'	FROM CollaborationGroupMember c'+
						'	WHERE  c.MemberId in '+queryIds+'';
		for (CollaborationGroupMember  obj :Database.query(sqlQ)) {
			if (!itemsToReturn.contains(obj.CollaborationGroupId)){
				itemsToQuery += ',\''+obj.CollaborationGroupId +'\'';
			}
			itemsToReturn.add(obj.CollaborationGroupId);
		}
		//remove first ,
		if (itemsToQuery != ''){
			itemsToQuery =  '('+itemsToQuery.substring(1)+')' ;
		}
		return itemsToQuery;
	}

	/**
	 * Get Users Followed By Id
	 *
	 * @param queryIds   		String with Id's to query
	 * @return					String with Id's of Users following given Ids
 	 */
	public static String getUsersFollowedById(String queryIds){
		String q ='';
		String followingUserIDList='';
		if (queryIds != ''){
			q = 	' SELECT id, ParentId, subscriberid'+
					' FROM EntitySubscription '+
					' WHERE subscriberid in '+queryIds;
			for(EntitySubscription f  : Database.query(q)){
				if (ChatterAuditUtils.getObjectType(f.ParentId) == 'User'){
					followingUserIDList += ',\'' + f.ParentId + '\'';
				}
			}
			//remove first ,
			if (followingUserIDList != ''){
				followingUserIDList =  '('+followingUserIDList.substring(1)+')' ;
			}
		}
		return followingUserIDList;
	}

	/**
	 * Get Collaboration Group List by name
	 *
	 * @param s			   		String with Name to search
	 * @return					Item with query results
 	 */
	public static List<ChatterAuditLookUpController.Item> getCollaborationGroupListByName(String s ){
		String itemsToQuery='';
		String q = 	' SELECT  Id, Name '+
						' FROM CollaborationGroup '+
						' WHERE Name LIKE '+s ;

		List<ChatterAuditLookUpController.Item> ret = new List<ChatterAuditLookUpController.Item>();
   		set<String> alreadyIn = new set<String>();
   		//store Ids to return
		String tmpId;
		String tmpName;
		if (Schema.sObjectType.CollaborationGroup.fields.Id.isAccessible() &&
			Schema.sObjectType.CollaborationGroup.fields.Name.isAccessible()){
			for (SObject  obj :Database.query(q)) {
				tmpId 	= String.valueOf(obj.get('Id'));
				tmpName = String.valueOf(obj.get('Name'));
				if (!alreadyIn.contains(tmpId+'-'+tmpName)){
					ret.add(new ChatterAuditLookUpController.Item(tmpId,tmpName));
					alreadyIn.add(tmpId+'-'+tmpName);
				}
			}		
		}

		return ret;
	}	
}