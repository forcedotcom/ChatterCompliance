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
public with sharing class ChatterAuditSearchUtilities {


	  /**
	  * runSearch
	  * Scenario 2 - search by 2 Users
	  * all pieces togheter
	  *
	  * @return List<SearchItem>			A list of ChatterAUditSearchController.SearchItem with results
	  */
	  public static List<ChatterAuditSearchController.SearchItem> runSearch(){

	  	List<ChatterAuditSearchController.SearchItem> ret = new List<ChatterAuditSearchController.SearchItem>();
		String sql;
		String itemBody	= ( ChatterAuditUtils.isValidString( ChatterAuditSearchController.searchParamsGlobal.get('itemBody') ) ) ?
							String.escapeSingleQuotes(ChatterAuditSearchController.searchParamsGlobal.get('itemBody'))
							: null;
		Boolean filteredByBody = ChatterAuditUtils.isValidString(itemBody );
	  	String userId1 = ( ChatterAuditUtils.isValidString( ChatterAuditSearchController.searchParamsGlobal.get('userId1') ) ) ?
							String.escapeSingleQuotes(ChatterAuditSearchController.searchParamsGlobal.get('userId1'))
							: null;
	  	String userId2 = ( ChatterAuditUtils.isValidString( ChatterAuditSearchController.searchParamsGlobal.get('userId2') ) ) ?
							String.escapeSingleQuotes(ChatterAuditSearchController.searchParamsGlobal.get('userId2'))
							: null;
	  	if (ChatterAuditUtils.isValidString(userId1) && ChatterAuditUtils.isValidString(userId2 )){
			//Check if we have a duplicated actors (conversation with him/herself is not allowed)
			if ( userId1.equals( userId2 ) ) throw new ChatterAuditException(Label.ChatterAudit_conversationErrorA);
			//as we add results we will filter duplicated items
			set<String> ids = new set<String>();
			ArchivedFeedItem__c tmp;
			Boolean matchBody = true;
			// s2opt1 : Posts made by person 1 on person 2's profile and vice versa (default on)
			for( ChatterAuditSearchController.SearchItem i : getCommentsBetweenActors(userId1, userId2) ){
				if (filteredByBody){
					if (i.Type==ChatterAuditConstants.postTypeName){
						matchBody = ChatterAuditFeedItemsHandler.validateTextResult(i,itemBody);
					}
				}else{
					matchBody = true;
				}
				if( matchBody && !ids.contains( i.id ) ){
					ids.add( i.recordId );
					ret.add(i);
				}
			}
			matchBody = true;
			// s2opt2 :  Posts where person 1 and person 2 have interacted ( except in threads)
			for( ChatterAuditSearchController.SearchItem i : getInteractionBetweenActors(userId1, userId2) ){
					if (filteredByBody){
					if (i.Type==ChatterAuditConstants.postTypeName){
						//This part will only return comments
					}else{
						matchBody = (i.body).toUpperCase().contains(itemBody.toUpperCase()) ;
					}
				}else{
					matchBody = true;
				}
				if( matchBody && !ids.contains( i.recordId ) ){
					ids.add( i.recordId );
					ret.add(i);
				}
			}
			matchBody = true;
			// s2opt2 :  Posts where person 1 and person 2 have interacted  ( only in threads)
			for( ChatterAuditSearchController.SearchItem i : getThreadInteractionBetweenActors(userId1, userId2) ){
					if (filteredByBody){
					if (i.Type ==ChatterAuditConstants.postTypeName){
						//This part will only return comments
					}else{
						matchBody = (i.Body).toUpperCase().contains(itemBody.toUpperCase());
					}
				}else{
					matchBody = true;
				}
				
				if( matchBody && !ids.contains( i.recordId ) ){
					ids.add( i.recordId );
					ret.add(i);
				}
			}
		}
		return ret;
	  }

	 /**
	 * get Interaction between Actors
	 * 2 Users Scenario
	 *  s2opt2 :  Posts where person 1 and person 2 have interacted
	 *   a) Person 1 posts, person 2 comments or Person 2 posts, person 1 comments
	 *
	 * @param actorA					String with actor A Id
	 * @param actorB					String with actor B Id
	 *
	 * @return List<SearchItem>			A list of ChatterAUditSearchController.SearchItem with results
	 */
	 public static list<ChatterAuditSearchController.SearchItem> getInteractionBetweenActors(String actorA, String actorB){
		String itemBody = ( ChatterAuditUtils.isValidString( ChatterAuditSearchController.searchParamsGlobal.get('itemBody') ) ) ?
						  String.escapeSingleQuotes(ChatterAuditSearchController.searchParamsGlobal.get('itemBody'))
						  : null;
	 	String s2opt2 =	( ChatterAuditUtils.isValidString( ChatterAuditSearchController.searchParamsGlobal.get('s2opt2') ) ) ?
							String.escapeSingleQuotes(ChatterAuditSearchController.searchParamsGlobal.get('s2opt2'))
							: null;
	 	List<ArchivedFeedComment__c> res = new list<ArchivedFeedComment__c>();
		Boolean filteredByBody = ChatterAuditUtils.isValidString(itemBody );
		if (ChatterAuditUtils.isValidString(s2opt2) && s2opt2 =='true' ){
			string soql = '';
			//a) Person 1 posts, person 2 comments or  Person 2 posts, person 1 comments
			String 	soql_CONDITIONAL  = ' ( ( Created_By__c =\''+actorA+'\' and ArchivedFeedItem__r.Created_By__c = \''+actorB+'\' ) ';
					soql_CONDITIONAL += ' OR ( Created_By__c =\''+actorB+'\' and ArchivedFeedItem__r.Created_By__c = \''+actorA+'\' ) )';
			String soql_DATES		= getDatesQueryString() ;
			if (soql_DATES != ''){
				soql += ' where '+soql_DATES + 'and ';
			}
			if (soql_CONDITIONAL != ''){
				if( !soql.contains(' where ')){
					soql += ' where ';
				}
				soql += soql_CONDITIONAL ;
			}
			if (filteredByBody && (itemBody.length()>0) ){
				soql = getSOSLCommentsQueryString(itemBody,soql);//	getSOSLQueryString(itemBody,soql);
				List<List<SObject>>searchList=search.query(soql);
				res =  ((List<ArchivedFeedComment__c>)searchList[0]);
			}else{
				soql = getSOQLCommentsQueryString(soql);//getSOQLQueryString();
				res = Database.query(soql );
			}
		}
	 	return buildList(res);
	 }

	 /**
	 * get thread interaction between actors
	 * 2 Users Scenario
	 *  s2opt2 :  Posts where person 1 and person 2 have interacted
	 *   b) Person 1 and person 2 comment on the same post created by another user
	 *
	 * @param actorA					String with actor A Id
	 * @param actorB					String with actor B Id
	 *
	 * @return List<SearchItem>			A list of ChatterAUditSearchController.SearchItem with results
	 */
	 public static list<ChatterAuditSearchController.SearchItem> getThreadInteractionBetweenActors(String actorA, String actorB){
		String itemBody = ( ChatterAuditUtils.isValidString( ChatterAuditSearchController.searchParamsGlobal.get('itemBody') ) ) ?
						  String.escapeSingleQuotes(ChatterAuditSearchController.searchParamsGlobal.get('itemBody'))
						  : null;
	 	String s2opt2 =	( ChatterAuditUtils.isValidString( ChatterAuditSearchController.searchParamsGlobal.get('s2opt2') ) ) ?
							String.escapeSingleQuotes(ChatterAuditSearchController.searchParamsGlobal.get('s2opt2'))
							: null;
		List<ArchivedFeedComment__c> res = new list<ArchivedFeedComment__c>();
		Boolean filteredByBody = ChatterAuditUtils.isValidString(itemBody );
		if (ChatterAuditUtils.isValidString(s2opt2)  && s2opt2 =='true' ){
			string soql = '';
			String 	soql_CONDITIONAL  = '' ;
			String idList = ChatterAuditSearchUtilities.getPostIdsWithThreadsInvolvingUsers(actorA,actorB);
			if (idList != ''){
				soql_CONDITIONAL  = ' ( FeedItemId__c in  ('+idList+') AND (Created_By__c in (\''+actorA+'\',\''+actorB+'\')))';
			}else{
				soql_CONDITIONAL  = ' ( FeedItemId__c in  (\''+ChatterAuditConstants.dummyId+'\' ) )';
			}
			String soql_DATES		= getDatesQueryString() ;
			if (soql_DATES != ''){
				soql += ' where '+soql_DATES + 'and ';
			}
			if (soql_CONDITIONAL != ''){
				if( !soql.contains(' where ')){
					soql += ' where ';
				}
				soql += soql_CONDITIONAL ;
			}
			if (filteredByBody && (itemBody.length()>0) ){
				soql = getSOSLCommentsQueryString(itemBody,soql);//	getSOSLQueryString(itemBody,soql);
				List<List<SObject>>searchList=search.query(soql);
				res =  ((List<ArchivedFeedComment__c>)searchList[0]);
			}else{
				soql = getSOQLCommentsQueryString(soql);//getSOQLQueryString();
				res = Database.query(soql );
			}
		}
	 	return buildList(res);
	 }

	/**
	 * get post ids with threads involving users
	 *
	 * @param actorA					String with actor A Id
	 * @param actorB					String with actor B Id
	 *
	 * @return String					String with posts ids that involves actor A and B
	 */
	private static String getPostIdsWithThreadsInvolvingUsers(String actorA,String actorB){
		set<Id> threadIDs = new set<Id>();
		set<Id> aThreadIDs = ChatterAuditSearchUtilities.getPostIdsWithThreadsInvolvingUser(actorA);
		set<Id> bThreadIDs = ChatterAuditSearchUtilities.getPostIdsWithThreadsInvolvingUser(actorB);
		String  threadIDsStr = '';
		if (aThreadIDs.size() > bThreadIDs.size()){
			for(Id i : aThreadIDs){
				if (bThreadIDs.contains(i)){
					threadIDs.add(i);
				}
			}
		}else{
			for(Id i : bThreadIDs){
				if (aThreadIDs.contains(i)){
					threadIDs.add(i);
				}
			}
		}
		if (!threadIDs.isempty()){
			for (Id i : threadIDs){
				threadIDsStr +=',\''+i+'\'';
			}
			threadIDsStr = threadIDsStr.substring(1);
		}
		return threadIDsStr;
	}

	/**
	 * get post ids with threads involving user
	 *
	 * @param uId						String with Id
	 *
	 * @return set<Id>					set<Id> with posts ids involving user id given by parameter
	 */
	private static set<Id> getPostIdsWithThreadsInvolvingUser(String uId){
   		set<Id> result = new set<Id>();

   		String q = 	'Select FeedItemId__c, Created_By__c '+
					' From ArchivedFeedComment__c   '+
					' WHERE Created_By__c = \''+uId +'\''+
					' GROUP BY FeedItemId__c, Created_By__c'  ;
		//store Ids to return
		String tmpId;
		String feedItemId_api_name 	= Schema.SObjectType.ArchivedFeedComment__c.fields.FeedItemId__c.getName();		
				
		for (SObject  obj :Database.query(q)) {
			tmpId 	= String.valueOf(obj.get(feedItemId_api_name));
				result.add(tmpId);
		}
		return result;
	}

	  /**
	  * get comments between actors
	  * 2 Users Scenario
	  *  s2opt1 : Posts made by person 1 on person 2's profile and vice versa (default on)
	  *
	  * @param actorA					String with actor A Id
	  * @param actorB					String with actor B Id
	  *
	  * @return List<SearchItem>		A list of ChatterAUditSearchController.SearchItem with results
	  */
	  public static list<ChatterAuditSearchController.SearchItem> getCommentsBetweenActors(String actorA, String actorB){
		String itemBody = ( ChatterAuditUtils.isValidString( ChatterAuditSearchController.searchParamsGlobal.get('itemBody') ) ) ?
						  String.escapeSingleQuotes(ChatterAuditSearchController.searchParamsGlobal.get('itemBody'))
						  : null;
	 	String s2opt1 =	( ChatterAuditUtils.isValidString( ChatterAuditSearchController.searchParamsGlobal.get('s2opt1') ) ) ?
							String.escapeSingleQuotes(ChatterAuditSearchController.searchParamsGlobal.get('s2opt1'))
							: null;
		List<ArchivedFeedItem__c> res = new list<ArchivedFeedItem__c>();
		Boolean filteredByBody = ChatterAuditUtils.isValidString(itemBody );
		if (ChatterAuditUtils.isValidString(s2opt1)  && s2opt1 =='true'  ){
			string soql = '';
			String 	soql_CONDITIONAL  = ' ( ( ParentId__c =\''+actorA+'\' and Created_By__c = \''+actorB+'\' ) ';
					soql_CONDITIONAL += ' OR ( ParentId__c =\''+actorB+'\' and Created_By__c = \''+actorA+'\' ) )';
			String soql_DATES		= getDatesQueryString() ;
			if (soql_DATES != ''){
				soql += ' where '+soql_DATES + 'and ';
			}
			if (soql_CONDITIONAL != ''){
				if( !soql.contains(' where ')){
					soql += ' where ';
				}
				soql += soql_CONDITIONAL ;
			}
			if (filteredByBody && (itemBody.length()>0) ){
				soql = getSOSLPostsQueryString(itemBody,soql);//	getSOSLQueryString(itemBody,soql);
				List<List<SObject>>searchList=search.query(soql);
				res =  ((List<ArchivedFeedItem__c>)searchList[0]);
			}else{
				soql = getSOQLPostsQueryString(soql);//getSOQLQueryString();
				res = Database.query(soql );
			}
		}
		return buildList(res);
	  }

	/**
	  * build list
	  *  Utility method to build result list
	  *
	  * @param l						list<ArchivedFeedComment__c>
	  *
	  * @return List<SearchItem>		A list of ChatterAUditSearchController.SearchItem with results
	  */
	private static list<ChatterAuditSearchController.SearchItem> buildList( list<ArchivedFeedComment__c> l ){
		list<ChatterAuditSearchController.SearchItem> ret = new list<ChatterAuditSearchController.SearchItem>();
		for ( ArchivedFeedComment__c elm : l ){
			ret.add( new ChatterAuditSearchController.SearchItem(elm) );
		}
		return ret;
	}

	/**
	  * build list
	  *  Utility method to build result list
	  *
	  * @param l						list<ArchivedFeedItem__c>
	  *
	  * @return List<SearchItem>		A list of ChatterAUditSearchController.SearchItem with results
	  */
	private static list<ChatterAuditSearchController.SearchItem> buildList( list<ArchivedFeedItem__c> l ){
		list<ChatterAuditSearchController.SearchItem> ret = new list<ChatterAuditSearchController.SearchItem>();
		for ( ArchivedFeedItem__c elm : l ){
			ret.add( new ChatterAuditSearchController.SearchItem(elm) );
		}
		return ret;
	}



	/**
	  *
	  * UTILITY METHODS TO BUILD QUERY STRINGs
	  *
	  */
	private static String defaultQueryPostFields	= ' Id, Created_By__r.Name, Created_By__c, CreatedDate__c, Body__c ,Type__c, ParentId__c, ParentObjectType__c,GroupName__c ,isParentDeleted__c, isDeleted__c, Title__c , ContentFileName__c, ContentDescription__c, LinkUrl__c, FeedItemId__c';
	private static String defaultQueryCommentFields = ' Id, Created_By__r.Name, CreatedDate__c, CommentBody__c,ParentId__c, ParentObjectType__c,isParentDeleted__c, isDeleted__c, ParentName__c, ArchivedFeedItem__c ,FeedItemId__c ';
	private static String getDefaultCommentQueryString(){
		return ' SELECT '+defaultQueryCommentFields +' From ArchivedFeedComment__c ';
	}
	private static String getDefaultPostQueryString(){
		return ' SELECT '+defaultQueryPostFields +' From ArchivedFeedItem__c ';
	}
	private static String getSOSLPostsQueryString(String searchStr,String filterQueryString){
		String soslQuery;
		searchStr = searchStr+'* or *'+searchStr;
		soslQuery = 'FIND \''+String.escapeSingleQuotes(searchStr)+'\' IN ALL FIELDS RETURNING '+
								+ChatterAuditUtils.getNamespace()+'ArchivedFeedItem__c ( '+defaultQueryPostFields+' '+filterQueryString+')';
		return soslQuery;
	}
	private static String getSOSLCommentsQueryString(String searchStr, String filterQueryString){

		String soslQuery;
		searchStr = searchStr+'* or *'+searchStr;
		soslQuery = 'FIND \''+String.escapeSingleQuotes(searchStr)+'\' IN ALL FIELDS RETURNING '+
								+ChatterAuditUtils.getNamespace()+'ArchivedFeedComment__c ( '+defaultQueryCommentFields+' '+filterQueryString+')';
		return soslQuery;
	}
	private static String getSOQLPostsQueryString(String filterQueryString){
		return getDefaultPostQueryString() + filterQueryString ;
	}
	private static String getSOQLCommentsQueryString(String filterQueryString){
		return getDefaultCommentQueryString() + filterQueryString ;
	}
	private static String getDatesQueryString(){
		String soql 		= '';
		String startD = ( ChatterAuditUtils.isValidString( ChatterAuditSearchController.searchParamsGlobal.get('startD') ) ) ?
						  String.escapeSingleQuotes(ChatterAuditSearchController.searchParamsGlobal.get('startD'))
						  : null;
		String endD = ( ChatterAuditUtils.isValidString( ChatterAuditSearchController.searchParamsGlobal.get('endD') ) ) ?
						  String.escapeSingleQuotes(ChatterAuditSearchController.searchParamsGlobal.get('endD'))
						  : null;
		//FILTER BY : CreatedDate  - before
		if (ChatterAuditUtils.isValidString(startD) && ChatterAuditUtils.isValidDate(startD)){
			String s = ChatterAuditSearchController.buildDateForQuery(startD);
			soql =	soql +' CreatedDate__c >= ' + s  ;
		}
		//FILTER BY : CreatedDate  - after
		if ( ChatterAuditUtils.isValidString(endD) && ChatterAuditUtils.isValidDate(endD)){
			String d = ChatterAuditSearchController.buildDateForQuery(endD);
			if( soql!=''){
				soql += ' and ';
			}
			soql += ' CreatedDate__c <= '+ d +'  ';
		}
		return soql;
	}

}