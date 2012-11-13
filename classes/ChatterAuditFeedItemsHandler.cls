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
public with sharing class ChatterAuditFeedItemsHandler {

	/**
	 * Update all ArchivedFeedItem__c to isDeleted = true
	 *
	 * @param idsToUpdate		Set of id's to update
 	 */
	public static void updateItemsAsDeleted(Set<id> idsToUpdate){
		List<Id> feedItemIds = new List<Id>();
		List<ArchivedFeedItem__c> lArch = [Select a.Id,a.isDeleted__c ,a.FeedItemId__c
											From ArchivedFeedItem__c a
											where a.isDeleted__c = false and a.FeedItemId__c in: idsToUpdate
											limit :ChatterAuditConstants.MAX_DML_ROWS];
		for(ArchivedFeedItem__c  a : lArch ){
			a.isDeleted__c = true;
			feedItemIds.add(a.FeedItemId__c);
		}
		if (!lArch.isEmpty()){
			upsert lArch;
			//send Update message to ArchivedFeedComments
			ChatterAuditFeedCommentsHandler.updateItemsAsDeletedByFeedItemId( feedItemIds );
		}
		if (lArch.size()==ChatterAuditConstants.MAX_DML_ROWS){ updateItemsAsDeleted(idsToUpdate); }
	}


	public static void updateCommentCount(Map<Id,Integer> itemsMap, Boolean add){
	
		List<ArchivedFeedItem__c> itemsToUpdate = [	SELECT a.Id, a.FeedItemId__c , a.CommentCount__c
										FROM ArchivedFeedItem__c a
										WHERE a.FeedItemId__c IN : itemsMap.keySet()];

		for(ArchivedFeedItem__c aF :	itemsToUpdate){
			// increment comments count for related post
			if (add){			
				aF.CommentCount__c = aF.CommentCount__c + itemsMap.get(aF.FeedItemId__c);
			}else{
				aF.CommentCount__c = aF.CommentCount__c - itemsMap.get(aF.FeedItemId__c);
			}
		}
		
		if (!itemsToUpdate.isEmpty()){
			ChatterAuditUtils.setEditAllowedForPosts(true);
			upsert itemsToUpdate;
		
		}			
	
	}
	
	 /**
     * Get archived feed items Ids by Feed Id
     *
     * @param idMap     a Map with Feed Items ids
     * @return          a Map with updated data
     */
    public static map<Id,Id> getArchivedFeedItemsIdByFeedId( map<Id,Id> idMap ){
        set<Id> fI              = idMap.keySet();
        set<Id> originalIds     = idMap.keySet();
        map<Id,Id> theReturn = new map<Id,Id>();

        list<ArchivedFeedItem__c> tmp = new list<ArchivedFeedItem__c>();

        tmp = [SELECT a.Id, a.FeedItemId__c
                FROM ArchivedFeedItem__c a
                WHERE a.FeedItemId__c IN :fI];
        for (Integer i=0; i<tmp.size(); i++){
            theReturn.put( tmp[i].FeedItemId__c , tmp[i].Id );
            originalIds.remove(tmp[i].FeedItemId__c );
            idMap.remove(tmp[i].FeedItemId__c );
        }
        if (!idMap.isEmpty()){
            //the remaining Items on originalIds are missing ArchivedFeedItems, lets bring them back to life
            Map<String,List<Id>> commentByParentType = ChatterAuditFeedItemsHandler.classifyCommentsByParentType(idMap);

            List<ArchivedFeedItem__c> totalNewItems = new List<ArchivedFeedItem__c>();

            for(String objType :commentByParentType.keySet() ){
                totalNewItems.addAll(ChatterAuditFeedItemsHandler.loadArchivedFeedItemsbyFeedItemsIds(objType, commentByParentType.get(objType)));
            }
            // query ArchivedFeedItem__c table to get entities Ids
            Set<Id> lentityIds = new Set<Id>();
            for(ArchivedFeedItem__c itm : totalNewItems){
            //to keep track of entity
                lentityIds.add(itm.ParentId__c);
            }
            Map<Id,Id> entitiesIds = ChatterAuditEntityFeedHandler.addEntities(lentityIds);
             for (ArchivedFeedItem__c af : totalNewItems){
                Id tmpId = af.ParentId__c;
                if (entitiesIds.containsKey(tmpId)){
                    af.ArchivedEntityFeed__c  =  entitiesIds.get(af.ParentId__c);
                }
            }
            if (!totalNewItems.isEmpty()){
                upsert totalNewItems;
            }
            for(ArchivedFeedItem__c itm : totalNewItems){
                theReturn.put(itm.FeedItemId__c , itm.Id );
            }
        }
        return theReturn.size() > 0 ? theReturn : null;
    }

    /**
     * Classifies comments by parent type
     *
     * @param idMap     a Map (FeedId, ParentId)
     * @return          a Map (Type, list<Ids>)
     */
    private static Map<String,List<Id>> classifyCommentsByParentType(map<Id,Id> idMap){
        //set<Id> idList
        Map<String,List<Id>> result = new Map<String,List<Id>>();
        String itemType = '';
        List<Id> tmp;
        Id tmpID;
        for(Id  itemId : idMap.keySet() ){
            tmpID = idMap.get(itemId);
            itemType = ChatterAuditUtils.getObjectType(tmpID);
            if (result.containsKey(itemType)){
                tmp = result.get(itemType); tmp.add(itemId); result.put(itemType,tmp);
            }else{
                tmp = new List<Id>{itemId};
                result.put(itemType,tmp);
            }
        }
        return result;
    }

    /**
     * Archived feed items by Feed Items Id
     *
     * @param objectName        Object Name
     * @param idsToCheck        list of Id's to check
     * @return                  a list of ArchivedFeedItem__c's
     */
    public static List<ArchivedFeedItem__c> loadArchivedFeedItemsbyFeedItemsIds(String objectName, list<Id> idsToCheck){

        List<ArchivedFeedItem__c> lres = new List<ArchivedFeedItem__c>();
        String uAdmId = ChatterAuditSettingsHandler.getChatterLogsOwnerId();
        String originalObjectName = objectName;

        if (objectName.endsWith('__c')){
            //if it's a custom object associated Feed Object will be named OBJECTNAME__Feed
            objectName = objectName.substring(0,(objectName.length() -1 ));
        }
        String feedObjName = objectName+'Feed';
        ArchivedFeedItem__c tmp;
        if (ChatterAuditUtils.validFeedObject(feedObjName) && !idsToCheck.isEmpty()){
            String allIds = '';
            for(Id i : idsToCheck){
                allIds =allIds +',\''+i+ '\'';
            }
            allIds = allIds.substring(1);
            String query =  'Select RelatedRecordId, Id, Type, CreatedDate, CreatedById, CreatedBy.FirstName, CreatedBy.LastName,'+
                            '       ParentId, Body, Title, LinkUrl,'+
                            '       ContentDescription,ContentType,ContentSize, ContentData, ContentFileName,  '+
                            '       CommentCount, InsertedById'+
                            ' From '+feedObjName+' n where n.Id in ('+allIds+')';
            Set<Id> lentityIds = new Set<Id>();
            String tmpType;
            for(sObject obj : Database.Query(query)){
                tmpType = String.valueOf(obj.get('Type'));

                tmp = new ArchivedFeedItem__c();
                 tmp.Type__c        = tmpType;
                //Feed Item title
                if (tmpType == 'LinkPost' ||tmpType == 'ContentPost'  ){
                    tmp.Title__c    = String.valueOf(obj.get('Title'));
                    tmp.LinkUrl__c  = String.valueOf(obj.get('LinkUrl'));
                }
                if (tmpType == 'ContentPost'   ){
                	if (obj.get('RelatedRecordId') != null){
	                    tmp.ContentType__c		= String.valueOf(obj.get('ContentType'));
	                    tmp.ContentSize__c		= decimal.valueOf(String.valueOf(obj.get('ContentSize')));
	                    tmp.ContentDescription__c   = String.valueOf(obj.get('ContentDescription'));
	                    tmp.ContentFileName__c      = String.valueOf(obj.get('ContentFileName')); 	
                    }else{
                        tmp.ContentType__c  	= null;
	                    tmp.ContentSize__c  	= null;
	                    tmp.ContentDescription__c   = null;
	                    tmp.ContentFileName__c      = null; 
                    }
                   
                }
                tmp.FullArchivedCommentList__c = (Integer.valueOf(obj.get('CommentCount')) <= 1);
                tmp.Body__c                 = String.valueOf(obj.get('Body'));
                tmp.Inserted_By__c          = (String.valueOf(obj.get('InsertedById') )!= null) ? String.valueOf(obj.get('InsertedById')) : String.valueOf(obj.get('CreatedById')) ;
                tmp.ParentId__c             = String.valueOf(obj.get('ParentId'));
                tmp.ParentObjectType__c     = originalObjectName;
                tmp.RelatedRecordId__c      = String.valueOf(obj.get('RelatedRecordId'));
                tmp.FeedItemId__c   = String.valueOf(obj.get('Id'));
                tmp.Created_By__c          = String.valueOf(obj.get('CreatedById'));
                tmp.CreatedDate__c          = Datetime.valueOf(obj.get('CreatedDate'));
                tmp.OwnerId                 = uAdmId;
                tmp.CommentCount__c         = Integer.valueOf(obj.get('CommentCount')) -1 ;//because we will always add 1 in the update method
             
                //to keep track of entity
                lentityIds.add(String.valueOf(obj.get('ParentId')));
                lres.add(tmp);               
            }
        }
        return lres;
    }

	
	/**
	 * delete  ArchivedFeedItem__c
	 *
	 * @param idsToDelete		Set Id's to delete
 	 */
	public static void deleteItems(Set<id> idsToDelete){
		List<ArchivedFeedItem__c> lArch = [Select a.Id
											From ArchivedFeedItem__c a
											where a.Id in: idsToDelete
											limit :ChatterAuditConstants.MAX_DML_ROWS];
		if (!lArch.isEmpty()){
			//delete comments
			ChatterAuditFeedCommentsHandler.deleteItemsByArchivedPostId(idsToDelete);
			delete lArch;
			if (lArch.size()== ChatterAuditConstants.MAX_DML_ROWS ){
				ChatterAuditFeedItemsHandler.deleteItems(idsToDelete);
			}
			
		}
		
	}
	
	/**
	 * delete  ArchivedFeedItem__c
	 *
	 * @param idsToDelete		Set Id's to delete
 	 */
	public static void deleteItemsAfterPurge(Set<id> idsToDelete){
		map<Id,ArchivedFeedItem__c> lArchivedItems = new map<Id,ArchivedFeedItem__c>( [Select a.Id
																																							From ArchivedFeedItem__c a
																																							where a.Id in: idsToDelete
																																							and a.retentionBit__c = false
																																							limit :ChatterAuditConstants.MAX_DML_ROWS ]);
		
		
		List<ArchivedFeedItem__c> lArch = lArchivedItems.values();
		if (!lArch.isEmpty()){
			//delete comments
			ChatterAuditFeedCommentsHandler.deleteItemsByArchivedPostId( lArchivedItems.keySet() );
			delete lArch;
			if (lArch.size()== ChatterAuditConstants.MAX_DML_ROWS ){
				ChatterAuditFeedItemsHandler.deleteItems(idsToDelete);
			}			
		}		
	}
	/* ***************************************************************************************************************
		SEARCH METHODS
		@parameters  :
						itemInsertedById
						startD
						endD;
						itemBody
						groupName

			  options:
					    s1opt1 : Person Created the Post/comment (default on)
    					s1opt2 : Posts to person's wall by others
    					s1opt3 : Posts and Comments on groups person belongs to
    					s1opt4 : Posts and Comments on profiles of people person is following
	*************************************************************************************************************** */

	private static String defaultQueryFields	= ' Created_By__r.Name, Created_By__c, Id, CreatedDate__c, Body__c , Type__c, ParentId__c, ParentObjectType__c, GroupName__c,isParentDeleted__c, isDeleted__c, Title__c , ContentFileName__c, ContentDescription__c, LinkUrl__c, FeedItemId__c';
	private static String candidateGroups 		= '';


	/**
	 * Sets the group Id
	 *
	 * @param c		String containing the Id of the selected group
 	 */
	public static void setCandidateGroups(String c){
		ChatterAuditFeedItemsHandler.candidateGroups  = c;
	}

	/**
	 * Get Search Results
	 *
	 * @return      a List of DTO's (SearchItem)
 	 */
	public static List<ChatterAuditSearchController.SearchItem> getSearchResults(){
	
	
		List<ChatterAuditSearchController.SearchItem> res = new List<ChatterAuditSearchController.SearchItem>();
		String sql;
		String itemBody			= '';
		Boolean filteredByBody	= false;
		String limit_str =  (ChatterAuditConstants.MAXIMUM_POST_RESULT > 0 ) ? ' limit '+ChatterAuditConstants.MAXIMUM_POST_RESULT : '';
		
	
		if (ChatterAuditUtils.isValidString(ChatterAuditSearchController.searchParamsGlobal.get('itemBody') ) ){
			filteredByBody	= true;
			itemBody 		= ChatterAuditSearchController.searchParamsGlobal.get('itemBody');
		}
		List<ArchivedFeedItem__c> tmpResults = new List<ArchivedFeedItem__c>();
		
		//List<ArchivedFeedItem__c> retList = new List<ArchivedFeedItem__c>();

		if (filteredByBody && (itemBody.length()>0) ){
			sql = getSOSLQueryString(itemBody);
			List<List<SObject>>searchList=search.query(sql);
			tmpResults =  ((List<ArchivedFeedItem__c>)searchList[0]);
		}else{
			sql = getSOQLQueryString();
			// process in chunks of 200 records
			for(List <ArchivedFeedItem__c> l : Database.query(sql + limit_str )){
				tmpResults.addAll(l);
			}
			
		}
		ArchivedFeedItem__c  eachElement;	
		ChatterAuditSearchController.SearchItem sItem;
		String orgUrl = ChatterAuditUtils.getOrgUrl();
        for(Integer h = 0; h < tmpResults.size(); ){
        	eachElement = tmpResults.get(h);
        	
			if (math.mod(h, 25) == 0 ){
				 if ( !ChatterAuditUtils.controlLimits() ){
				 	 ChatterAuditSearchController.MORE_RECORDS_TO_SHOW = true;				 	 
				 	 return res;
				 }				 
			}
			sItem = new ChatterAuditSearchController.SearchItem(eachElement,orgUrl);
			if ( ( filteredByBody && validateTextResult(sItem,itemBody))
						|| !filteredByBody ){
					res.add(sItem);
			}
			tmpResults.remove(0);
		}
		
		ChatterAuditSearchController.MORE_RECORDS_TO_SHOW = false;
		return res;
	}
	
	

	/**
	 * get default query string
	 *
	 * @return		String with default query string
 	 */
	private static String getDefaultQueryString(){
		return ' SELECT '+defaultQueryFields +' From ArchivedFeedItem__c';
	}


	/**
	 * Validate text result
	 *
	 * @param element			An archivedFeedItem__c to validate with given String
	 * @param strToSearch		String to search for
	 * @return      			element contains strToSearch = true; else = false;
 	 */
	public static Boolean validateTextResult( ChatterAuditSearchController.SearchItem element, string strToSearch){
		Boolean ret =  true;
		String upperSearchStr = strToSearch.toUpperCase();
		ret  =  (	(element.body != null )		&&( String.escapeSingleQuotes( (element.body).toUpperCase() ) ).contains(upperSearchStr)  ||
					(element.title != null )	&&((element.title).toUpperCase()).contains(upperSearchStr) ||
					(element.linkUrl != null )	&&((element.linkUrl).toUpperCase()).contains(upperSearchStr) ||
					(element.contentFileName != null )&&((element.contentFileName).toUpperCase()).contains(upperSearchStr) ||
					(element.contentDescription != null )&&((element.contentDescription).toUpperCase()).contains(upperSearchStr));
		return ret;
	}

	/**
	 * get SoSL query string
	 *
	 * @param searchStr			String to search for
	 * @return      			String with SoSL query
 	 */
	private static String getSOSLQueryString(String searchStr){
		String soslQuery;
		searchStr = searchStr+'* or *'+searchStr;
		soslQuery = 'FIND \''+searchStr+'\' IN ALL FIELDS RETURNING '+
							+ChatterAuditUtils.getNamespace()+'ArchivedFeedItem__c ( '+defaultQueryFields+' '+getFilterQueryString()+')';
		return soslQuery;
	}

	/**
	 * get SOQL query string
	 *
	 * @return      			String with SOQL query
 	 */
	private static String getSOQLQueryString(){
		return getDefaultQueryString() + getFilterQueryString() ;
	}

	/**
	 * get filter query string, adds general filters to a query
	 *
	 * @return      			String with query
 	 */
	private static String getFilterQueryString(){
		String soql				= '';
		String soql_DATES		= getDatesQueryString();
		String soql_CONDITIONAL	= getSceneryQueryString();
		if (soql_DATES != ''){
			soql += ' where '+soql_DATES ;
		}
		if (soql_CONDITIONAL != ''){
			if( !soql.contains(' where ')){
				soql += ' where ';
			}else{
				soql +=' and ';
			}
			soql += soql_CONDITIONAL ;
		}
		return soql;
	}

	/**
	 * get scene query string
	 *
	 * @return      			String with query
 	 */
	private static String getSceneryQueryString(){
		String result = '';
		String scenario		= ChatterAuditSearchController.searchParamsGlobal.get('scenario');
		if (ChatterAuditUtils.isValidString(scenario))
			scenario = String.escapeSingleQuotes(scenario);
		if (scenario =='s1'){
			result = getOneUserQueryString();
		}else{
			result = getGroupQueryString();
		}
		return result;
	}

	/**
	 * get Group Query String
	 *
	 * @return      			String with query
 	 */
	private static String getGroupQueryString(){
		String soql 		= '';
		if (ChatterAuditUtils.isValidString(candidateGroups) ){
				soql =	soql +' ( ParentId__c in  '+candidateGroups +'  ) ';
		}
		return soql;
	}

	/**
	 * adds Date to a given query String
	 *
	 * @return      			String with date filter added
 	 */
	private static String getDatesQueryString(){
		String soql 		= '';
		String startD  		= ChatterAuditSearchController.searchParamsGlobal.get('startD');
		if (ChatterAuditUtils.isValidString(startD)){
			startD = String.escapeSingleQuotes(startD);
		}
		String endD  		=  ChatterAuditSearchController.searchParamsGlobal.get('endD');
		if (ChatterAuditUtils.isValidString(endD)){
			endD = String.escapeSingleQuotes(endD);
		}
		//FILTER BY : CreatedDate  - before
		if (ChatterAuditUtils.isValidString(startD)){
			soql =	soql +' CreatedDate__c >= ' + startD  ;
		}
		//FILTER BY : CreatedDate  - after
		if ( ChatterAuditUtils.isValidString(endD)){
			
			if( soql!=''){
				soql += ' and ';
			}
			soql += ' CreatedDate__c <= '+ endD +'  ';
		}
		return soql;
	}

	/**
		this method will build the WHERE part of the query string

					itemInsertedById
					startD
					endD;
					itemBody
					groupName

					options:
						    opt1 : Person Created the Post/comment (default on)
    						opt2 : Posts to person's wall by others
    						opt3 : Posts and Comments on groups person belongs to
    						opt4 : Posts and Comments on profiles of people person is following
	*/
	private static String getOneUserQueryString(){
		String soql 		= '';
		String user1soql 	= '';
		String userId1  	= ChatterAuditSearchController.searchParamsGlobal.get('userId1');

		String opt1  		= ChatterAuditSearchController.searchParamsGlobal.get('s1opt1');
		String opt2  		= ChatterAuditSearchController.searchParamsGlobal.get('s1opt2');
		String opt3  		= ChatterAuditSearchController.searchParamsGlobal.get('s1opt3');
		String opt4  		= ChatterAuditSearchController.searchParamsGlobal.get('s1opt4');

		// FILTER BY opt1..4
		if (ChatterAuditUtils.isValidString(userId1) ){
			userId1 = String.escapeSingleQuotes(userId1);
			String userId1inStr = '(\''+userId1+'\')';
			//opt1: Person Created the Post/comment (default on)
			if (ChatterAuditUtils.isValidString(opt1) && opt1=='true' ){
				user1soql += '( Created_By__c = \''+userId1 +'\' ) or ';
			}
			//opt2 : Posts to person's wall by others
			if (ChatterAuditUtils.isValidString(opt2) && opt2=='true'){
				user1soql += '( ( ParentId__c = \''+userId1 +'\' ) AND ( Created_By__c <> \''+userId1 +'\' ) ) or  ';
			}
			//opt3: Posts and Comments on groups person belongs to
			if (ChatterAuditUtils.isValidString(opt3) && opt3=='true' ){
				String groupUserBelongsTo = ChatterAuditChatterUtilities.getUserGroupsById(userId1inStr);
				if (groupUserBelongsTo != ''){
					user1soql += '( ParentId__c in  '+groupUserBelongsTo +') or';
				}else{
					user1soql += '( ParentId__c = \''+ChatterAuditConstants.dummyId +'\' ) or';
				}
			}
			//opt4 : Posts and Comments on profiles of people person is following
			//			person following could be the author or the parent of the feedItem
			if (ChatterAuditUtils.isValidString(opt4) && opt4=='true'){
				String followingUserIDList = ChatterAuditChatterUtilities.getUsersFollowedById(userId1inStr);
				if (followingUserIDList != ''){
					user1soql += ' ( ParentId__c in  '+followingUserIDList +' ) or  ( Created_By__c in  '+followingUserIDList +') or';
				}else{
					user1soql += ' ( ParentId__c = \''+ChatterAuditConstants.dummyId+'\' ) or ';
				}
			}
			//remove last ' or ';
		 	if (user1soql.lastIndexOf('or') != -1){
		    	user1soql = user1soql.substring(0,user1soql.lastIndexOf('or'));
		    }
			if (user1soql != '') {
				soql += '('+user1soql+')';
				soql += 'and';
			}
		}
	 	//remove last ' and ';
	 	if (soql.lastIndexOf('and') != -1){
	    	soql = soql.substring(0,soql.lastIndexOf('and'));
	    }
	    return soql;
	}
	
	/**
	 * Returns true if query.results.contains( one version at least sent via parameter )
	 *
	 * @param versions : set<Id> with versions to look for
	 * @return boolean
	 **/
	public static boolean existsArchivedFeedItemsWithContentVersion( set<Id> versions ){
		list<ArchivedFeedItem__c> aFI = [Select c.Id
										from ArchivedFeedItem__c c
										where c.RelatedRecordId__c IN :versions
										limit 1];
		return aFi.size() > 0;	
	}
	
	/**
	 * Returns true if query.results.contains( one version at least sent via parameter )
	 *
	 * @param versions : set<Id> with versions to look for
	 * @return boolean
	 **/
	public static boolean existsArchivedFeedCommentsWithContentVersion( set<Id> versions ){
		list<ArchivedFeedComment__c> aFI = [Select c.Id
										from ArchivedFeedComment__c c
										where c.RelatedRecordId__c IN :versions
										limit 1];
		return aFi.size() > 0;	
	}
	
}