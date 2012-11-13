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
public with sharing class ChatterAuditSearchController { 

	public static boolean MORE_RECORDS_TO_SHOW {get; set;}
	
	public List<ChatterAuditSearchController.SearchItem> items {get;set;}
    public  String totalItemsBySearch{ get; set; }
    public static boolean customSOk {get;set;}
    
    private Map<String,String> searchParamsLocal;
    public static Map<String,String> searchParamsGlobal = new Map<String,String>();

    private set<Id> postIds ;//to send to future method on export
    public  String searchStr {get;set;}//to highlight
    private Boolean preLoadingStarted; 
    private ChatterAuditProxyController.responseWrapper response;
    
    public boolean getIsPreloadingActive(){
    	return ChatterAuditSettingsHandler.isPreloadingActive();	
    } 
    
    // sort direction. defaults to asc
    public String sortDir {
        get  { if (sortDir == null) {  sortDir = 'asc'; } return sortDir;  }
        set;
    }

    // sort by part of the query, defaults to CreatedDate__c
    public String sortField {
        get  { if (sortField == null) {sortField = 'CreatedDate'; } return sortField;  }
        set;
    }

	
	public ChatterAuditSearchController() {        
        this.response = new ChatterAuditProxyController.responseWrapper();
        this.searchParamsLocal = new Map<String,String>();
        sortDir = sortDir.equals('asc') ? 'desc' : 'asc';
		MORE_RECORDS_TO_SHOW = false;
        this.preLoadingStarted = false;      
    }

    public Pagereference checkSetting(){    
        ChatterAuditUtils.checkCustomSetting();
        ChatterAuditSettings__c cnf = ChatterAuditSettings__c.getValues(ChatterAuditConstants.CUSTOM_SETTING_NAME);
    	if ( cnf == null || !ChatterAuditUtils.hasPermissions( cnf.ChatterAuditOwnerId__c ) ){
    		customSOk = false;
    	}else{
    		customSOk = true;
    	}
        return null;
    }

    /**
     * Run Search
     */
    public void runSearch() {
        
        this.searchParamsLocal = backupUrlParameters();
        ChatterAuditSearchController.searchParamsGlobal = this.searchParamsLocal;
        
        if ( this.searchParamsLocal.get('searchType') == null ){
            executeSearch();    
        }else if ( this.searchParamsLocal.get('searchType') == 'private' ){
            executePrivateSearch();
        }else{
            executeSearch();
        }              
    }

    /**
     * Run Async Search
     *
     * @param data                  List of Strings
     */
    public void runAsyncSearch(List<String> data) {
        ChatterAuditSearchController.searchParamsGlobal = unSerializeParameters(data);
        if ( ChatterAuditSearchController.searchParamsGlobal.get('searchType') == null ){
            executeSearch();    
        }else if ( ChatterAuditSearchController.searchParamsGlobal.get('searchType') == 'private' ){
            executePrivateSearch();
        }else{
            executeSearch();
        }               
    }
    
    /**
     * Execute Private Search
     */
     private void executePrivateSearch(){
        this.items = new list<ChatterAuditSearchController.SearchItem>();
        list<ChatterAuditSearchController.SearchItem> aux = ChatterAuditChatterMessagesHandler.getSearchResults();
        this.items = aux;
     }

    /**
     * Execute Search
     */
    private void executeSearch() {
        String parentIdFilter = '';
        try {
            searchStr = '';
    
            String groupName    = ChatterAuditSearchController.searchParamsGlobal.get('groupName');
            String scenario     = ChatterAuditSearchController.searchParamsGlobal.get('scenario');

            this.items = new List<ChatterAuditSearchController.SearchItem>();
            this.response.success = true;
            if (ChatterAuditUtils.okFlsOnCustomObjects()){

                if (ChatterAuditUtils.isValidString(scenario)){
                    if (scenario == 's2'){
                        List<ChatterAuditSearchController.SearchItem> set1 = ChatterAuditSearchUtilities.runSearch();
                        this.items.addAll(set1);
                    }else
                        if (scenario == 's3' || scenario == 's1' || scenario == 's0'){
                            //search on Archived FeedItems
                            storeFilterByGroups(groupName);
                            this.items.addAll(ChatterAuditFeedItemsHandler.getSearchResults());
                            
                            Integer newLimit4Comments = ChatterAuditConstants.MAXIMUM_RECORDS_2_PROCESS - this.items.size();
                            //query to ChatterAuditFeedCommentsHandler
                            this.items.addAll(ChatterAuditFeedCommentsHandler.getSearchResults(newLimit4Comments));
                        }
                }

            }
        } catch (Exception e) { 
            this.response.success = false;
            this.items = new List<ChatterAuditSearchController.SearchItem>(); 
            String msg = Label.ChatterAudit_errorMessage+e.getMessage();
            this.response.msg = msg;
            this.response.msgType = 'error';
            if (!ChatterAuditExportUtilities.isExport){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, msg));
            }else{
                ChatterAuditUtils.mailException(msg,'ChatterAuditExport exception');
            }
        }
    }


    public list<ChatterAuditSearchController.SearchItem> getItems (){

        this.TotalItemsBySearch = String.valueOf(this.items.size());
        return this.items;
    
    }


    public ChatterAuditProxyController.responseWrapper getResponse(){

        this.TotalItemsBySearch = String.valueOf(this.items.size());
       if ( MORE_RECORDS_TO_SHOW ){
            	String   aux = Label.ChatterAudit_searchReachedMaxRecords ; 
                this.response.msg = aux.replace('MAXIMUM_POST_4_EXPORT', String.valueOf(ChatterAuditConstants.MAXIMUM_RECORDS_2_PROCESS));
                this.response.msgType = 'warning';
        } 
        
        this.response.searchData = this.items;
        
        return this.response;
    
    }

    private void checkResultSetSize(){
        List<ChatterAuditSearchController.SearchItem> ltmp = new List<ChatterAuditSearchController.SearchItem>();
        if (this.items.size() > ChatterAuditConstants.MAXIMUM_LIST_RESULTS){
            Integer j = 0;
            while (j < ChatterAuditConstants.MAXIMUM_LIST_RESULTS ){
                ltmp.add(this.items[j++]);
            }   
            this.items.clear();
            this.items = ltmp;
            //ltmp.clear();
            String msg = Label.ChatterAudit_ErrorMessages_resultSetSize;
            msg = msg.replace ('MAX_RECORDS',String.valueOf(ChatterAuditConstants.MAXIMUM_LIST_RESULTS));
            if (!ChatterAuditExportUtilities.isExport){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, msg ));
            }else{
                ChatterAuditUtils.mailException(msg,'ChatterAuditExport exception');
            }
        } 
    }


    /**
     * startLoading
     * redirectes to page that implements export
     *
     * @return PageReference            PageReference null
     */
    public PageReference startLoading(){
        
        this.preLoadingStarted = true;
        Database.executeBatch(new   ChatterAuditBatchLoader(), ChatterAuditConstants.MAX_BATCH_SIZE );
        return null;
    }
    
    /**
     * Store Filter by groups
     *
     * @param groupName         String group name to filter
     */
    public static void storeFilterByGroups(String groupName){
        String idList ='';
        if (ChatterAuditUtils.isValidString(groupName) ){
            //group name filter
            idList = ' (\''+groupName+'\') ';
            if (idList == ''){
                idList = ' (\''+ChatterAuditConstants.dummyId+'\') ';
            }
        }
        ChatterAuditFeedItemsHandler.setCandidateGroups (idList);
        ChatterAuditFeedCommentsHandler.setCandidateGroups (idList);
    }

    /**
     * backup URL parameters
     *
     * @return Map              Map<String,String> with url parameters
     */
    private static Map<String,String> backupUrlParameters(){
            Map<String,String> tmp = new Map<String,String>();
            if (ChatterAuditUtils.isValidString(Apexpages.currentPage().getParameters().get('typeOfSearch')))
            tmp.put('searchType', String.escapeSingleQuotes(Apexpages.currentPage().getParameters().get('typeOfSearch')));
            if (ChatterAuditUtils.isValidString(Apexpages.currentPage().getParameters().get('itemBody')))
                tmp.put('itemBody', String.escapeSingleQuotes(Apexpages.currentPage().getParameters().get('itemBody')));
            if (ChatterAuditUtils.isValidString(Apexpages.currentPage().getParameters().get('userId1')))
                tmp.put('userId1',  String.escapeSingleQuotes(Apexpages.currentPage().getParameters().get('userId1')));
            if (ChatterAuditUtils.isValidString(Apexpages.currentPage().getParameters().get('userId2')))
                tmp.put('userId2',  String.escapeSingleQuotes(Apexpages.currentPage().getParameters().get('userId2')));
            if (ChatterAuditUtils.isValidString(Apexpages.currentPage().getParameters().get('groupName')))
                tmp.put('groupName',String.escapeSingleQuotes(Apexpages.currentPage().getParameters().get('groupName')));
            tmp.put('scenario', Apexpages.currentPage().getParameters().get('scenario'));
            tmp.put('s1opt1',   Apexpages.currentPage().getParameters().get('s1opt1'));
            tmp.put('s1opt2',   Apexpages.currentPage().getParameters().get('s1opt2'));
            tmp.put('s1opt3',   Apexpages.currentPage().getParameters().get('s1opt3'));
            tmp.put('s1opt4',   Apexpages.currentPage().getParameters().get('s1opt4'));
            tmp.put('s2opt1',   Apexpages.currentPage().getParameters().get('s2opt1'));
            tmp.put('s2opt2',   Apexpages.currentPage().getParameters().get('s2opt2'));
            
            if (ChatterAuditUtils.isValidString(Apexpages.currentPage().getParameters().get('startD')) &&
                ChatterAuditUtils.isValidDate(Apexpages.currentPage().getParameters().get('startD')) )
                tmp.put('startD',   buildDateForQuery(Apexpages.currentPage().getParameters().get('startD')));
                
            if (ChatterAuditUtils.isValidString(Apexpages.currentPage().getParameters().get('endD')) &&
                ChatterAuditUtils.isValidDate(Apexpages.currentPage().getParameters().get('endD')) )
                tmp.put('endD', buildDateForQuery(Apexpages.currentPage().getParameters().get('endD')) );
                
            return tmp;
    }
    
    
    /**
      * Parses a String coming from the page to a valid date String to use in soql query
      *
      * @param dateNoFormat     String
      * 
      * @return String // Formated properly for soql query
      */
    public static String buildDateForQuery(String dateNoFormat){
        String ret = '';
        Datetime theDate = null;
        try{
                String[] dateVector = dateNoFormat.split('_');
                String[] dateOnly = dateVector[0].split('-');
                String[] timeOnly = dateVector[1].split(':');
                theDate = datetime.newInstance( Integer.valueOf(dateOnly[0]), Integer.valueOf(dateOnly[1]), Integer.valueOf(dateOnly[2]), Integer.valueOf(timeOnly[0]), Integer.valueOf(timeOnly[1]), 0 );  
                ret = theDate.FormatGmt('yyyy-MM-dd HH:mm').replace(' ','T')+':00.000Z';
        }catch(Exception e){            
            ret = '';
        }
        return ret;         
    }

    /**
     * Serialize parameters
     *
     * @param data                      A Map<String,String> with parameters
     *
     * @return List<String>             List<String> with paramList
     */
    public static List<String> serializeParameters(Map<String,String> data){
        List<String> paramsList = new List<String>();
        for(String k : data.keySet()){
            paramsList.add(k+ChatterAuditConstants.separator+data.get(k));
        }
        return paramsList;
    }

    /**
     * Unserialize parameters
     *
     * @param data                      List<String> with paramList
     *
     * @return Map<String,String>       A Map<String,String> with parameters
     */
    private static Map<String,String> unSerializeParameters(List<String> data){
        List<String> parts;
        Map<String,String> searchParamstmp = new Map<String,String>();
        if (!data.isEmpty()){
            for(String k : data){
                if (k.contains(ChatterAuditConstants.separator)){
                    parts = k.split(ChatterAuditConstants.separator);
                    if (parts!= null && parts.size() ==2){
                        searchParamstmp.put(parts[0], parts[1]);
                    }
                }
            }
        }
        
        //Hotfix for dates
        if (ChatterAuditUtils.isValidString(searchParamstmp.get('startD')) &&
                ChatterAuditUtils.isValidDate(searchParamstmp.get('startD')) )
                searchParamstmp.put('startD',   buildDateForQuery(searchparamstmp.get('startD')));
                
            if (ChatterAuditUtils.isValidString(searchParamstmp.get('endD')) &&
                ChatterAuditUtils.isValidDate(searchParamstmp.get('endD')) )
                searchParamstmp.put('endD', buildDateForQuery(searchParamstmp.get('endD')) );
        
        return searchParamstmp;
    }

    /**
     * Search Item
     * class to wrap search results from Posts and Comments
     */
     
    public class objectWrapper{
    
        public Id       id {get; set;}
        public String   name {get; set;}
        public String   url {get; set;}
        
        public objectWrapper(String oId, String oName, String oUrl){
            this.id = oId;
            this.name = oName;
            this.url = oUrl;
        }
    } 
     
    public class SearchItem {


        public Id       		id 						{get; set;}
        public String   		Type 					{get; set;}
        public String   		body 					{get; set;}
        public String   		createdDate 			{get; set;}
        public objectWrapper    author 					{get; set;}
        public String   		recordId 				{get; set;}
        public String   		chatterType 			{get; set;}
        public Boolean  		isParentDeleted 		{get; set;}
        public Boolean  		isDeleted 				{get; set;}
        public String   		parentId				{get; set;}
        public objectWrapper    parentType 				{get; set;}
        public objectWrapper    chatterLink 			{get; set;}
        public String 			title             	    {get; set;}
        public String 			linkUrl         		{get; set;}
        public String 			ContentFileName      	{get; set;}
        public String 			ContentDescription   	{get; set;}
        
                
        public SearchItem( ArchivedFeedItem__c aPost ){

            this.id = aPost.Id;
            this.Type =  ChatterAuditConstants.postTypeName;
            this.body =  (aPost.body__c != null && aPost.body__c.length()>83) ? aPost.body__c.substring(0,80)+'...' : aPost.body__c;
            this.body =  ChatterAuditUtils.encodeHtml(this.body);
            this.createdDate = apost.CreatedDate__c.format('MM-dd-yyyy H:mm:ss');
            this.author =  new objectWrapper (apost.Created_By__r.Id,ChatterAuditUtils.encodeHtml(apost.Created_By__r.Name),ChatterAuditUtils.getOrgUrl()+'/'+apost.Created_By__r.Id);
            this.recordId =  apost.Id;
            this.isParentDeleted =  ( apost.isParentDeleted__c == 'true' );
            this.isDeleted = apost.isDeleted__c;
            this.parentId = apost.ParentId__c;
            this.parentType =  new objectWrapper (EncodingUtil.urlEncode(apost.ParentId__c,'UTF-8'),ChatterAuditUtils.encodeHtml(apost.GroupName__c) +'('+ChatterAuditUtils.encodeHtml(apost.ParentObjectType__c)+')',ChatterAuditUtils.getOrgUrl()+'/'+EncodingUtil.urlEncode(apost.ParentId__c,'UTF-8'));

            String res = '';
            if (apost.isParentDeleted__c !='true'){
                if (apost.ParentObjectType__c == ChatterAuditConstants.userStatusTypeName){
                    res = ChatterAuditUtils.getOrgUrl()+'/'+ChatterAuditConstants.USER_PROFILE_VIEW_LINK.replace('USERID',EncodingUtil.urlEncode(apost.ParentId__c,'UTF-8')).replace('FEEDITEMID',apost.FeedItemId__c);
                }else{
                    res = ChatterAuditUtils.getOrgUrl()+'/'+ChatterAuditConstants.ENTITY_VIEW_LINK.replace('ENTITYID',EncodingUtil.urlEncode(apost.ParentId__c,'UTF-8')).replace('FEEDITEMID',EncodingUtil.urlEncode(apost.FeedItemId__c,'UTF-8'));
                }
            }   
    
            this.chatterLink = new objectWrapper (ChatterAuditUtils.encodeHtml(apost.FeedItemId__c),'Chatter Link',res);
            this.title = apost.Title__c;
            this.linkUrl = apost.LinkUrl__c;
            this.ContentFileName = apost.ContentFileName__c;
            this.ContentDescription = apost.ContentDescription__c;
            
        }

        public SearchItem( ArchivedFeedComment__c aComment ){

            this.id =  aComment.ArchivedFeedItem__c;
            this.Type = ChatterAuditConstants.commentTypeName;
            this.createdDate = acomment.CreatedDate__c.format('MM-dd-yyyy H:mm:ss');
            this.author = new objectWrapper (acomment.Created_By__r.Id,ChatterAuditUtils.encodeHtml(acomment.Created_By__r.Name),ChatterAuditUtils.getOrgUrl()+'/'+acomment.Created_By__r.Id);
            this.recordId =  acomment.Id;
            this.isParentDeleted =   (acomment.isParentDeleted__c =='true');
            this.isDeleted = acomment.isDeleted__c;
            this.parentId = acomment.ParentId__c;
            this.body =  (acomment.CommentBody__c != null && acomment.CommentBody__c.length()>83) ? acomment.CommentBody__c.substring(0,80)+'...' : acomment.CommentBody__c;
            this.body = ChatterAuditUtils.encodeHtml(this.body);
            this.parentType =  new objectWrapper (EncodingUtil.urlEncode(acomment.ParentId__c,'UTF-8'),ChatterAuditUtils.encodeHtml(acomment.ParentName__c) +'('+ChatterAuditUtils.encodeHtml(acomment.ParentObjectType__c)+')','../'+EncodingUtil.urlEncode(acomment.ParentId__c,'UTF8'));

            String res  ='';
            if (acomment.isParentDeleted__c !='true'){
                //return this.post.Id;
                if (acomment.ParentObjectType__c == ChatterAuditConstants.userStatusTypeName){
                    res = ChatterAuditUtils.getOrgUrl()+'/'+ChatterAuditConstants.USER_PROFILE_VIEW_LINK.replace('USERID',EncodingUtil.urlEncode(acomment.ParentId__c,'UTF-8')).replace('FEEDITEMID',EncodingUtil.urlEncode(acomment.FeedItemId__c,'UTF-8'));
                }else{
                    res = ChatterAuditUtils.getOrgUrl()+'/'+ChatterAuditConstants.ENTITY_VIEW_LINK.replace('ENTITYID',EncodingUtil.urlEncode(acomment.ParentId__c,'UTF-8')).replace('FEEDITEMID',EncodingUtil.urlEncode(acomment.FeedItemId__c,'UTF-8'));
                }
            }   

            this.chatterLink = new objectWrapper (ChatterAuditUtils.encodeHtml(acomment.FeedItemId__c),'Chatter Link',res);
            
        }
        
        public SearchItem ( ArchivedChatterMessage__c aPrivateMessage ){
            this.id = aPrivateMessage.Id;
            this.Type = 'Private Message';
            this.createdDate = aPrivateMessage.SentDate__c.format('MM-dd-yyyy H:mm:ss');
            this.author = new objectWrapper ( aPrivateMessage.SenderId__c, ChatterAuditUtils.encodeHtml(aPrivateMessage.SenderId__r.Name), ChatterAuditUtils.getOrgUrl()+'/'+aPrivateMessage.SenderId__c );
            this.recordId = aPrivateMessage.Id;
            this.isParentDeleted = false;
            this.isDeleted = false;
            this.parentId = aPrivateMessage.Id;
            this.body = aPrivateMessage.body__c;
            this.body = ChatterAuditUtils.encodeHtml(this.body);
            this.parentType = new objectWrapper ('000000000000000000','N/A','N/A');
            this.chatterLink = new objectWrapper (ChatterAuditUtils.encodeHtml(aPrivateMessage.Id),'Chatter Link',ChatterAuditUtils.getOrgUrl()+'/'+Encodingutil.urlEncode(aPrivateMessage.Id,'UTF-8'));
        }
        
        public SearchItem( ArchivedFeedItem__c aPost , String orgUrl){

            this.id = aPost.Id;
            this.Type =  ChatterAuditConstants.postTypeName;
            this.body =  (aPost.body__c != null && aPost.body__c.length()>83) ? aPost.body__c.substring(0,80)+'...' : aPost.body__c;
            this.body = ChatterAuditUtils.encodeHtml(this.body);
            this.createdDate = apost.CreatedDate__c.format('MM-dd-yyyy H:mm:ss');
            this.author =  new objectWrapper (apost.Created_By__r.Id,ChatterAuditUtils.encodeHtml(apost.Created_By__r.Name),orgUrl+'/'+apost.Created_By__r.Id);
            this.recordId =  apost.Id;
            this.isParentDeleted =  ( apost.isParentDeleted__c == 'true' );
            this.isDeleted = apost.isDeleted__c;
            this.parentId = apost.ParentId__c;
            this.parentType =  new objectWrapper (EncodingUtil.urlEncode(apost.ParentId__c,'UTF-8'),ChatterAuditUtils.encodeHtml(apost.GroupName__c) +'('+ChatterAuditUtils.encodeHtml(apost.ParentObjectType__c)+')',orgUrl+'/'+EncodingUtil.urlEncode(apost.ParentId__c,'UTF-8'));

            String res = '';
            if (apost.isParentDeleted__c !='true'){
                //return this.post.Id;
                if (apost.ParentObjectType__c == ChatterAuditConstants.userStatusTypeName){
                    res = orgUrl+'/'+ChatterAuditConstants.USER_PROFILE_VIEW_LINK.replace('USERID',EncodingUtil.urlEncode(apost.ParentId__c,'UTF-8')).replace('FEEDITEMID',EncodingUtil.urlEncode(apost.FeedItemId__c,'UTF-8'));
                }else{
                    res = orgUrl+'/'+ChatterAuditConstants.ENTITY_VIEW_LINK.replace('ENTITYID',EncodingUtil.urlEncode(apost.ParentId__c,'UTF-8')).replace('FEEDITEMID',EncodingUtil.urlEncode(apost.FeedItemId__c,'UTF-8'));
                }
            }   
    
            this.chatterLink = new objectWrapper (ChatterAuditUtils.encodeHtml(apost.FeedItemId__c),'Chatter Link',res);
            this.title = apost.Title__c;
            this.linkUrl = apost.LinkUrl__c;
            this.ContentFileName = apost.ContentFileName__c;
            this.ContentDescription = apost.ContentDescription__c;
            
        }

        public SearchItem( ArchivedFeedComment__c aComment , String orgUrl){

            this.id =  aComment.ArchivedFeedItem__c;
            this.Type = ChatterAuditConstants.commentTypeName;
            this.createdDate = acomment.CreatedDate__c.format('MM-dd-yyyy H:mm:ss');
            this.author = new objectWrapper (acomment.Created_By__r.Id,ChatterAuditUtils.encodeHtml(acomment.Created_By__r.Name),orgUrl+'/'+acomment.Created_By__r.Id);
            this.recordId =  acomment.Id;
            this.isParentDeleted =   (acomment.isParentDeleted__c =='true');
            this.isDeleted = acomment.isDeleted__c;
            this.parentId = acomment.ParentId__c;
            this.body =  (acomment.CommentBody__c != null && acomment.CommentBody__c.length()>83) ? acomment.CommentBody__c.substring(0,80)+'...' : acomment.CommentBody__c;
            this.body = ChatterAuditUtils.encodeHtml(this.body);
            this.parentType =  new objectWrapper (EncodingUtil.urlEncode(acomment.ParentId__c,'UTF-8'),ChatterAuditUtils.encodeHtml(acomment.ParentName__c) +'('+ChatterAuditUtils.encodeHtml(acomment.ParentObjectType__c)+')','../'+EncodingUtil.urlEncode(acomment.ParentId__c,'UTF-8'));

            String res  ='';
            if (acomment.isParentDeleted__c !='true'){
                //return this.post.Id;
                if (acomment.ParentObjectType__c == ChatterAuditConstants.userStatusTypeName){
                    res = orgUrl+'/'+ChatterAuditConstants.USER_PROFILE_VIEW_LINK.replace('USERID',EncodingUtil.urlEncode(acomment.ParentId__c,'UTF-8')).replace('FEEDITEMID',EncodingUtil.urlEncode(acomment.FeedItemId__c,'UTF-8'));
                }else{
                    res = orgUrl+'/'+ChatterAuditConstants.ENTITY_VIEW_LINK.replace('ENTITYID',EncodingUtil.urlEncode(acomment.ParentId__c,'UTF-8')).replace('FEEDITEMID',EncodingUtil.urlEncode(acomment.FeedItemId__c,'UTF-8'));
                }
            }   

            this.chatterLink = new objectWrapper (ChatterAuditUtils.encodeHtml(acomment.FeedItemId__c),'Chatter Link',res);
        
        }
        
        public SearchItem ( ArchivedChatterMessage__c aPrivateMessage , String orgUrl){
            this.id = aPrivateMessage.Id;
            this.Type = 'Private Message';
            this.createdDate = aPrivateMessage.SentDate__c.format('MM-dd-yyyy H:mm:ss');
            this.author = new objectWrapper ( aPrivateMessage.SenderId__c, ChatterAuditUtils.encodeHtml(aPrivateMessage.SenderId__r.Name), orgUrl+'/'+aPrivateMessage.SenderId__c );
            this.recordId = aPrivateMessage.Id;
            this.isParentDeleted = false;
            this.isDeleted = false;
            this.parentId = aPrivateMessage.Id;
            this.body = aPrivateMessage.body__c;
            this.body = ChatterAuditUtils.encodeHtml(this.body);
            this.parentType = new objectWrapper ('000000000000000000','N/A','N/A');
            this.chatterLink = new objectWrapper (ChatterAuditUtils.encodeHtml(aPrivateMessage.Id),'Chatter Link',orgUrl+'/'+EncodingUtil.urlEncode(aPrivateMessage.Id,'UTF-8'));
        }       
    }
}