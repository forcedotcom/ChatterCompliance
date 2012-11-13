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
public with sharing class ChatterAuditFeedCommentsHandler {

	/**
	 * sets ArchivedFeedComment__c's to deleted = true
	 *
	 * @param feedCommentsIds		a list of ArchivedFeedComment__c Id's
 	 */
	public static void updateItemsAsDeletedByFeedCommentId( list<Id> feedCommentsIds ){

		list<ArchivedFeedComment__c> FeedCommentsToDelete = new list<ArchivedFeedComment__c>();		
		Map<Id,ArchivedFeedItem__c> FeedItemsToUpdate = new Map<Id,ArchivedFeedItem__c>();
		set<Id> oldComments = new set<Id>();
		ArchivedFeedItem__c tmp ;
		
		oldComments.addAll(feedCommentsIds);
		
		if ( feedCommentsIds.size() > 0 ){

			FeedCommentsToDelete = [Select e.Id , e.IsDeleted__c , e.ArchivedFeedItem__r.CommentCount__c, 
											e.ArchivedFeedItem__c, e.FeedCommentId__c
			  						 FROM  ArchivedFeedComment__c e
			  						 WHERE e.FeedCommentId__c IN :feedCommentsIds
			  						 AND   e.isDeleted__c = false
			  						 limit :ChatterAuditConstants.MAX_DML_ROWS];
			for(integer i=0;i<FeedCommentsToDelete.size();i++){
				//remove processed commentId
				oldComments.remove(FeedCommentsToDelete[i].FeedCommentId__c);
				
				FeedCommentsToDelete[i].isDeleted__c = true;
				tmp = FeedCommentsToDelete[i].ArchivedFeedItem__r;
				tmp.CommentCount__c = (FeedCommentsToDelete[i].ArchivedFeedItem__r.CommentCount__c -1 );
								
				FeedItemsToUpdate.put(tmp.Id,tmp);				
			}
			
			if ( FeedCommentsToDelete.size() > 0 ) {
					upsert FeedCommentsToDelete;
					upsert FeedItemsToUpdate.values();					
			}
			//Recursive call in case results are > MAX_DML_ROWS
			if ( FeedCommentsToDelete.size() > ChatterAuditConstants.MAX_DML_ROWS ) {
				updateItemsAsDeletedByFeedCommentId( feedCommentsIds );
			}else{
				
				/*
					this code was used to update the Archived FeedItem comment count after the comments were purged  
					and the archived feed item was lazy loaded back

				if(!oldComments.isEmpty()){
					ChatterAuditFeedCommentsHandler.updateCommentCountNonArchived(oldComments);
					
				}
				*/
			
			}
		}
	}
	
	private  static void updateCommentCountNonArchived (set<Id> oldComments){
	
		//oldComments
		Integer tmpCount;
		Map<Id,Integer> itemsMap = new Map<Id,Integer>();	
		for (FeedComment fC : [	Select Id , FeedItemId
								FROM  FeedComment 
								WHERE Id IN :oldComments
								limit :ChatterAuditConstants.MAX_DML_ROWS]){
			tmpCount = 0;
			if (itemsMap.containsKey(fc.FeedItemId)){
				tmpCount = itemsMap.get(fc.FeedItemId);
			}
			tmpCount ++;
			
			itemsMap.put(fc.FeedItemId,tmpCount);
		}
	
		//this remaining commentId belog to comments that are no longer in the archived model
		// but they still exist on chatter 
		//Invoke method that will update
		ChatterAuditFeedItemsHandler.updateCommentCount(itemsMap, false);
	}

	/**
	 * sets ArchivedFeedComment__c's to deleted = true
	 *
	 * @param feedItemIds		a list of ArchivedFeedItem__c Id's
 	 */
	public static void updateItemsAsDeletedByFeedItemId( list<Id> feedItemIds ){
		list<ArchivedFeedComment__c> l = new list<ArchivedFeedComment__c>();
		l = [Select f.Id
			  FROM ArchivedFeedComment__c f
			  WHERE f.FeedItemId__c IN :feedItemIds
			  AND   f.isDeleted__c = false
			  limit :ChatterAuditConstants.MAX_DML_ROWS];

		for ( integer i=0; i<l.size(); i++){
			l[i].isDeleted__c = true;
		}
		if ( l.size() > 0 ) upsert l;
		//Recursive call in case results are > MAX_DML_ROWS
		if ( l.size() == ChatterAuditConstants.MAX_DML_ROWS ) updateItemsAsDeletedByFeedItemId( feedItemIds );
	}

	/**
	 * Delete 1..n ArchivedFeedComment__c's
	 *
	 * @param idsToDelete		a Set of ArchivedFeedComment__c Id's to be deleted
 	 */
	public static void deleteItemsByArchivedPostId(Set<id> idsToDelete){
		database.executebatch(  new ChatterAuditDeleteItemsByPostIdBatch() );
	}

	//________________________________________SEARCH______________________________________________

	private static String defaultQueryFields = ' Created_By__r.Name, CreatedDate__c, CommentBody__c, ArchivedFeedItem__c,ParentId__c,ParentObjectType__c, ParentName__c , isParentDeleted__c, isDeleted__c ,FeedItemId__c  ';

	/**
	 * Gets default Query String
 	 */
	private static String getDefaultQueryString(){
		return ' SELECT '+defaultQueryFields +' From ArchivedFeedComment__c';
	}

	private static String candidateGroups 		= '';

	/**
	 * Sets the group Id
	 *
	 * @param c		String containing the Id of the selected group
 	 */
	public static void setCandidateGroups(String c){
		ChatterAuditFeedCommentsHandler.candidateGroups  = c;
	}

	/**
	 * Get Search Results
	 *
	 * @return      a List of DTO's (SearchItem)
 	 */
	public static list<ChatterAuditSearchController.SearchItem> getSearchResults( Integer newLimit){
		String sql;
		String itemBody	=	'' ;
		String userId1	= 	'';
		if (newLimit == 0 ) {
			newLimit = ChatterAuditConstants.MAXIMUM_COMMENT_RESULT;
		}
		String limit_str =  (newLimit > 0 ) ? ' limit '+newLimit : '';
		List<ArchivedFeedComment__c> res = new list<ArchivedFeedComment__c>();
		//get and validate parameters
		if (ChatterAuditUtils.isValidString(ChatterAuditSearchController.searchParamsGlobal.get('itemBody') ) )
			itemBody = ChatterAuditSearchController.searchParamsGlobal.get('itemBody');
		if (ChatterAuditUtils.isValidString(ChatterAuditSearchController.searchParamsGlobal.get('userId1') ) )
			userId1 = String.escapeSingleQuotes(ChatterAuditSearchController.searchParamsGlobal.get('userId1'));
		if (ChatterAuditUtils.isValidString(itemBody ) && (itemBody.length()>0) ){
			sql = getSOSLQueryString(itemBody);
			List<List<SObject>>searchList=search.query(sql);
			res = ((List<ArchivedFeedComment__c>)searchList[0]);
			
		}else{
			sql = getSOQLQueryString();
			//res = Database.query(sql);
			// process in chunks of 200 records
			for(List <ArchivedFeedComment__c> l : Database.query(sql + limit_str )){
				res.addAll(l);
			}
			
		}
		//Sanitize Comment list and create list of returning items (SearchItem obj)
		return generateDTOs(res, itemBody);
	}
	
	
	/**
	 * Generate the Search Items (Data Transfer Objects) and returns it
	 *
	 * @param l		List of ArchivedFeedComment__c's to be encapsulated in the DTO
	 * @return      a List of DTO's containing inside the items sent via parameter
 	 */
	
	
	private static list<ChatterAuditSearchController.SearchItem> generateDTOs(list<ArchivedFeedComment__c> l, String strToSearch){
		
		list<ChatterAuditSearchController.SearchItem> ret = new list<ChatterAuditSearchController.SearchItem>();
		Boolean validSearchStr = ChatterAuditUtils.isValidString(strToSearch );
		String orgUrl = ChatterAuditUtils.getOrgUrl();
		String upperSearchStr = strToSearch.toUpperCase();
		ArchivedFeedComment__c eachElement = null;
		for(Integer j = 0; j < l.size(); ){
			if (math.mod(j, 25) == 0 ){
				 if ( !ChatterAuditUtils.controlLimits() ){
				 	 ChatterAuditSearchController.MORE_RECORDS_TO_SHOW = true;
				 	 return ret;
				 }
			}
			eachElement = l.get(j);
			if ( ( validSearchStr &&
				  	( String.escapeSingleQuotes( (eachElement.CommentBody__c).toUpperCase() ) ).contains(upperSearchStr)  )
					|| !validSearchStr ){
				ret.add( new ChatterAuditSearchController.SearchItem(eachElement,orgUrl) );
			}
			l.remove(0);
		}
		ChatterAuditSearchController.MORE_RECORDS_TO_SHOW = false;
		return ret;
	}
	

	/**
	 * Generates String for SoSL QUERY
	 *
	 * @param searchStr		String to find
	 * @return      		String with the SoSL Query
 	 */
	private static String getSOSLQueryString(String searchStr){

		String soslQuery;
		searchStr = searchStr+'* or *'+searchStr;
		soslQuery = 'FIND \''+searchStr+'\' IN ALL FIELDS RETURNING '+
							+ChatterAuditUtils.getNamespace()+'ArchivedFeedComment__c( '+defaultQueryFields+' '+getFilterQueryString()+')';
		return soslQuery;
	}


	/**
	 * getSOQLQueryString
	 *
	 * @return      		String with defaultQueryString + FilterQueryString
 	 */
	private static String getSOQLQueryString(){
		return getDefaultQueryString() + getFilterQueryString() ;
	}

	/**
	 * Generates String Filters for query
	 *
	 * @return      		String with filtered Query
 	 */
	private static String getFilterQueryString(){
		String soql				= '';
		String soql_DATES		= getDatesQueryString();
		String soql_CONDITIONAL	= getSceneryQueryString();

		if (soql_DATES != ''){
			soql += ' where '+soql_DATES  ;
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
	 * According to scenery generates different query String
	 *
	 * @return      		String with Query filtered by scene
 	 */
	private static String getSceneryQueryString(){
		String scenario		= ChatterAuditSearchController.searchParamsGlobal.get('scenario');
		String result = '';
		if (scenario =='s1'){
			result = getOneUserQueryString();
		}else{
			result = getGroupQueryString();
		}
		return result;
	}

	/**
	 * Generate group query String
	 *
	 * @return      		String with Query for group
 	 */
	private static String getGroupQueryString(){
		String soql 		= '';
		if (ChatterAuditUtils.isValidString(candidateGroups) ){
				soql =	soql +' ( ParentId__c in  '+candidateGroups +'  ) ';
		}
		return soql;
	}

	/**
	 * Generates part of the query including Date filter
	 *
	 * @return      		String Query with Date filter
 	 */
	private static String getDatesQueryString(){
		String soql 		= '';
		String startD  		= ChatterAuditSearchController.searchParamsGlobal.get('startD');
		String endD  		= ChatterAuditSearchController.searchParamsGlobal.get('endD');

		//FILTER BY : CreatedDate  - before
		if (ChatterAuditUtils.isValidString(startD)){
			String s = String.escapeSingleQuotes(startD);
			soql =	soql +' CreatedDate__c >= ' + s  ;
		}
		//FILTER BY : CreatedDate  - after
		if ( ChatterAuditUtils.isValidString(endD)){
			String d = String.escapeSingleQuotes(endD);
			if( soql!=''){
				soql += ' and ';
			}
			soql += ' CreatedDate__c <= '+ d +'  ';
		}
		return soql;
	}

	/**
	 * Generates query for one user selected
	 *
	 * @return      		String with Query
 	 */
	private static String getOneUserQueryString(){
		String soql 		='';
		String user1soql 	= '';
		String userId1  	= ChatterAuditSearchController.searchParamsGlobal.get('userId1');
		String opt1  		= ChatterAuditSearchController.searchParamsGlobal.get('s1opt1');
		String opt2  		= ChatterAuditSearchController.searchParamsGlobal.get('s1opt2');
		String opt3  		= ChatterAuditSearchController.searchParamsGlobal.get('s1opt3');
		String opt4  		= ChatterAuditSearchController.searchParamsGlobal.get('s1opt4');

		String userId1inStr = '(\''+userId1+'\')';

		// FILTER BY opt1..4
		if (ChatterAuditUtils.isValidString(userId1) ){
			userId1 = String.escapeSingleQuotes(userId1);
			//opt1: Person Created the Post/comment (default on)
			if (ChatterAuditUtils.isValidString(opt1) && opt1=='true' ){
				user1soql += ' Created_By__c = \''+userId1 +'\' or ';
			}
			//opt2 : Posts to person's wall by others
			if (ChatterAuditUtils.isValidString(opt2)  && opt2=='true' ){
				user1soql += '( ( ParentId__c = \''+userId1 +'\' ) AND ( Created_By__c <> \''+userId1 +'\' ) ) or  ';
			}
			//opt3: Posts and Comments on groups person belongs to
			if (ChatterAuditUtils.isValidString(opt3)  && opt3=='true' ){
				String groupUserBelongsTo = ChatterAuditChatterUtilities.getUserGroupsById(userId1inStr);
				if (groupUserBelongsTo != ''){
					user1soql += ' ParentId__c in  '+groupUserBelongsTo +' or' ;
				}else{
					user1soql += '( ParentId__c = \''+ChatterAuditConstants.dummyId +'\' ) or';
				}
			}
			//opt4 : Posts and Comments on profiles of people person is following
			//			person following could be the author or the parent of the feedComment
			if (ChatterAuditUtils.isValidString(opt4)  && opt4=='true' ){
				String followingUserIDList = ChatterAuditChatterUtilities.getUsersFollowedById(userId1inStr);
				if (followingUserIDList != ''){
					user1soql += '( ParentId__c in  '+followingUserIDList +' or Created_By__c in  '+followingUserIDList +') or';
				}else{
					user1soql += ' ParentId__c = \''+ChatterAuditConstants.dummyId+'\' or';
				}
			}
			if (user1soql.lastIndexOf('or') != -1){
		    	user1soql = user1soql.substring(0,user1soql.lastIndexOf('or'));
		    }
			if (user1soql != '') {
				soql += '('+user1soql+')';
				soql += 'and';
			}
		}
	 	if (soql.lastIndexOf('and') != -1){
	    	soql = soql.substring(0,soql.lastIndexOf('and'));
	    }
		return soql;
	}

	/**
	 * Generates a list of ArchivedFeedComment__c's containing the search String
	 *
	 * @param elements		List ArchivedFeedComment__c
	 * @param strToSearch	String with the filter
	 * @return      		A list of ArchivedFeedComment__c's containing the search String
 	 */
	public static list<ArchivedFeedComment__c> sanitizeCommentsList( list<ArchivedFeedComment__c> elements, String strToSearch){
		list<ArchivedFeedComment__c> ret = new list<ArchivedFeedComment__c>();
		Boolean validSearchStr = ChatterAuditUtils.isValidString(strToSearch );
		String upperSearchStr = strToSearch.toUpperCase();
			for (ArchivedFeedComment__c eachElement :elements) {
				if ( ( validSearchStr &&
					  	( String.escapeSingleQuotes( (eachElement.CommentBody__c).toUpperCase() ) ).contains(upperSearchStr)  )
						|| !validSearchStr ){
							ret.add( eachElement );
					}
			}
		return ret;
	}

	/**
	 * Escape the single quotes in a given String
	 *
	 * @param str			String to be sanitized
	 * @return      		String with single quotes escaped
 	 */
	public static String sanitizeStr( String str ){
		String ret = '';

		if ( str != null && str.trim() != '' ){
			str = String.escapeSingleQuotes(str);
			ret = str;
		}
		return str;
	}
}