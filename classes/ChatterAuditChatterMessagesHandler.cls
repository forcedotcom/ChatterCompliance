public with sharing class ChatterAuditChatterMessagesHandler {
	
	private static String defaultQueryFields	= ' Id, Body__c, ConversationId__c, CreatedById__c, SenderId__c, SentDate__c, SenderId__r.Name';
	
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
		List<ArchivedChatterMessage__c> tmpResults = new List<ArchivedChatterMessage__c>();
		
		if (filteredByBody && (itemBody.length()>0) ){
			sql = getSOSLQueryString(itemBody);
			List<List<SObject>>searchList=search.query(sql);
			tmpResults =  ((List<ArchivedChatterMessage__c>)searchList[0]);			
		}else{
			sql = getSOQLQueryString();
			for(List <ArchivedChatterMessage__c> l : Database.query(sql + limit_str )){
				tmpResults.addAll(l);
			}						
		}
		ArchivedChatterMessage__c  eachElement;	
		ChatterAuditSearchController.SearchItem sItem;
        for(Integer h = 0; h < tmpResults.size(); ){
        	eachElement = tmpResults.get(h);
        	
			if (math.mod(h, 20) == 0 ) ChatterAuditUtils.controlLimits();
			sItem = new ChatterAuditSearchController.SearchItem(eachElement);
			if ( ( filteredByBody && validateTextResult(sItem,itemBody))
						|| !filteredByBody ){ 
					res.add(sItem);
			}
			tmpResults.remove(0);
		}
		
		return res;
	}
	
	private static list<ArchivedChatterMessage__c> resolveScenario( list<ArchivedChatterMessage__c> l ){
		//Resolve if its a search that involves two users, otherwise just return the same list
		list<ArchivedChatterMessage__c> ret = new list<ArchivedChatterMessage__c>();		
		return ret;		
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
	 * get SoSL query string
	 *
	 * @param searchStr			String to search for
	 * @return      			String with SoSL query
 	 */
	private static String getSOSLQueryString(String searchStr){
		String soslQuery;
		searchStr = searchStr+'* or *'+searchStr;
		soslQuery = 'FIND \''+searchStr+'\' IN ALL FIELDS RETURNING '+
							+ChatterAuditUtils.getNamespace()+'ArchivedChatterMessage__c ( '+defaultQueryFields+' '+getFilterQueryString()+')';
		return soslQuery;
	}
	
	/**
	 * get default query string
	 *
	 * @return		String with default query string
 	 */
	private static String getDefaultQueryString(){
		return ' SELECT '+defaultQueryFields +' From ArchivedChatterMessage__c';
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
	 * Validate text result
	 *
	 * @param element			A chatterAuditChatterMessage__c to validate with given String
	 * @param strToSearch		String to search for
	 * @return      			element contains strToSearch = true; else = false;
 	 */
	public static Boolean validateTextResult( ChatterAuditSearchController.SearchItem element, string strToSearch){
		Boolean ret =  true;
		String upperSearchStr = strToSearch.toUpperCase();
		ret  =  ( (element.body != null ) && ( String.escapeSingleQuotes( (element.body).toUpperCase() ) ).contains(upperSearchStr) );
		return ret;
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
			String s = String.escapeSingleQuotes(startD);
			soql =	soql +' SentDate__c >= ' + s  ;
		}
		//FILTER BY : CreatedDate  - after
		if ( ChatterAuditUtils.isValidString(endD)){
			String d = String.escapeSingleQuotes(endD);
			if( soql!=''){
				soql += ' and ';
			}
			soql += ' SentDate__c <= '+ d +'  ';
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
		result = getUsersQueryString();
		return result;
	}
	
	/**
		this method will build the WHERE part of the query string
	*/
	private static String getUsersQueryString(){
		
		String soql 		= '';
		String userId1  	= ChatterAuditSearchController.searchParamsGlobal.get('userId1');
		String userId2		= ChatterAuditSearchController.searchParamsGlobal.get('userId2');
		
		if (ChatterAuditUtils.isValidString(userId1) && ChatterAuditUtils.isValidString(userId2)){
			
			userId1 = String.escapeSingleQuotes(userId1);
			userId2 = String.escapeSingleQuotes(userId2);
			soql += '\''+userId1+'\',\''+userId2+'\'';			
			
			//in case same users selected, is not necesary to do all the filters
			if ( userId1 == userId2 ){
				soql = 'SenderId__c in (\''+userId1+'\')'; return soql;
			}
			
			//getting user1 conversations
			list<ChatterConversationMember> user1Conversations = [Select Id, ConversationId 
																	from ChatterConversationMember 
																	where MemberId = :userId1 limit 9999];
			//building set
			set<Id> user1ConversationsSet = new set<Id>();
			for ( ChatterConversationMember elm : user1Conversations ){
				user1ConversationsSet.add( elm.ConversationId );
			}
			
			//getting user2 conversations in common with user1
			list<ChatterConversationMember> user2Conversations = [Select Id, ConversationId 
																	from ChatterConversationMember 
																	where MemberId = :userId2 and 
																	ConversationId in :user1ConversationsSet limit 9999];
																	
			soql = 'SenderId__c in ('+soql+') and ConversationId__c in ( ';			
			for ( Integer i=0; i<user2Conversations.size();i++ ){
				ChatterConversationMember elm = user2Conversations.get(i);
				soql += '\''+elm.ConversationId+'\'';
				soql += ( i != user2Conversations.size()-1 ) ? ',' : '';
			}			
			soql = user2Conversations.size() > 0 ? soql+')' : soql+'\'000000000000000\')';			
		
		}else if ( ChatterAuditUtils.isValidString(userId1) && !ChatterAuditUtils.isValidString(userId2) ){
			soql = 'SenderId__c in (\''+userId1+'\')';
		}else if ( ChatterAuditUtils.isValidString(userId2) && !ChatterAuditUtils.isValidString(userId1) ){
			soql = 'SenderId__c in (\''+userId2+'\')';
		} 
		return soql;		
	}
	
	/**
	 * delete  ArchivedChatterMessage__c
	 *
	 * @param idsToDelete		Set Id's to delete
 	 */
	public static void deleteItems(Set<id> idsToDelete){
		List<ArchivedChatterMessage__c> lArch = [Select a.Id
											From ArchivedChatterMessage__c a
											where a.Id in: idsToDelete
											limit :ChatterAuditConstants.MAX_DML_ROWS];
		if (!lArch.isEmpty()){
			delete lArch;
			if (lArch.size()== ChatterAuditConstants.MAX_DML_ROWS ){
				ChatterAuditChatterMessagesHandler.deleteItems(idsToDelete);
			}			
		}		
	}
	
	/**
	 * delete  ArchivedChatterMessage__c
	 *
	 * @param idsToDelete		Set Id's to delete
 	 */
	public static void deleteItemsAfterPurge(Set<id> idsToDelete){
		List<ArchivedChatterMessage__c> lArch = [Select a.Id
											From ArchivedChatterMessage__c a
											where a.Id in: idsToDelete
											and a.retentionBit__c = false
											limit :ChatterAuditConstants.MAX_DML_ROWS];
		if (!lArch.isEmpty()){
			delete lArch;
			if (lArch.size()== ChatterAuditConstants.MAX_DML_ROWS ){
				ChatterAuditChatterMessagesHandler.deleteItems(idsToDelete);
			}			
		}		
	}

}