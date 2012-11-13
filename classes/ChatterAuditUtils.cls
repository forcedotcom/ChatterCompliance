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
public with sharing class ChatterAuditUtils { 

    private static Boolean allowDelete  = false;
    private static Boolean allowEdit    = false;
    private static String PRIVATE_MESSAGES_JOB_NAME = 'Chatter Compliance Private Messages Audit';
    
    private static final String[] JS_DECODED = new String[] { '\\', '\'', '\n', '\r', '"', '!--', '/', '<', '>' };
    private static final String[] JS_ENCODED = new String[] { '\\\\', '\\\'', '\\n', '\\r', '\\"', '\\!--', '\\/', '\\u003C', '\\u003E' };

    public static Boolean getIsDeleteAllowedForPosts(){
        return ChatterAuditUtils.allowDelete ;
    }
    public static void setDeleteAllowedForPosts(Boolean v){
        ChatterAuditUtils.allowDelete  = v;
    }
    
    public static Boolean getIsEditAllowedForPosts(){
        return ChatterAuditUtils.allowEdit ;
    }
    public static void setEditAllowedForPosts(Boolean v){
        ChatterAuditUtils.allowEdit  = v;
    }
    
    public static boolean getIsContentDocumentDeleteAllowed(){      
        ChatterAuditSettings__c cnf = ChatterAuditSettings__c.getValues(ChatterAuditConstants.CUSTOM_SETTING_NAME);
        if (cnf == null) return true;
        return !cnf.ContentVersionDeleteBlocker__c;
    }
    
    
    private static Map<String, String> keyPrefixMap = new Map<String, String>{};
    private static User admin;

   /**
    * load Key prefix Map
    */
    public static void loadKeyPrefixMap(){
        //get all of the objects from your org
        Map<String,Schema.SObjectType> gd = Schema.getGlobalDescribe();
        //get the prefix of the objects in Ids
        Set<String> keyPrefixSet = gd.keySet();
        for(String sObj : keyPrefixSet){
            Schema.DescribeSObjectResult r =  gd.get(sObj).getDescribe();
            String tempName = r.getName();
            String tempPrefix = r.getKeyPrefix();
         //in this map, all the Objects with their prefixes will be stored
            keyPrefixMap.put(tempPrefix,tempName);
        }
    }

   /**
    * get admin
    *
    * @return User      User admin
    */
    public static User getAdmin(){
        Profile adminPr;
        User sysAdm;

        if ( admin == null ){
            adminPr = [ Select p.Id From Profile p where Name = 'System Administrator' and UserType='Standard'  ];
            sysAdm = [ Select Id from User where profile.Id = :adminPr.Id and IsActive = true limit 1];
            //Asign it to private static var
            admin = sysAdm;
        }
        return admin;
    }

   /**
    * get objectType
    *
    * @param objId      String with object Id
    *
    * @return String    String with object Type
    */
    public static String getObjectType(String objId){

        if (keyPrefixMap.size() == 0){
            ChatterAuditUtils.loadKeyPrefixMap();
        }
        String tPrefix = objId;
        tPrefix = tPrefix.subString(0,3);
        //get the type of your specified object
        String objectType = keyPrefixMap.get(tPrefix);

        return objectType;
    }

   /**
    * Valid Feed Object
    *   Check if the Sobjects name exists on the schema
    *
    * @param testName   String with name to test
    *
    * @return boolean   boolean
    */
    private static Map<String, Schema.SObjectType> gd;
    public static Boolean validFeedObject(String testName){

        if (gd== null){
            gd = Schema.getGlobalDescribe();
        }
        return gd.containsKey(testName);
    }

   /**
    * Is valid number
    *
    * @param testStr    String to test
    *
    * @return boolean   boolean
    */
    public static boolean isValidNumber(String testStr){
        String numb = '([0-9]+)';
        Pattern MyPattern = Pattern.compile(numb);
        Matcher MyMatcher = MyPattern.matcher(testStr);
        return MyMatcher.matches();
    }


   /**
    * get batch next execution time
    *
    * @return Datetime          Datetime with the next batch execution time
    */
    public static Datetime getBatchNextExecutionDtTime(){
        String hoursFreq = ChatterAuditSettingsHandler.getChatterUpdateFequency();
        Datetime rightNow = Datetime.now();
        Datetime nextFireTime = rightNow.addHours(Integer.valueOf(hoursFreq));
        return nextFireTime;
    } 

   /**
    * get batch next execution time
    *
    * @return String            String with next fire time
    */
    public static string getBatchNextExecutionTime(){
        Datetime nextFireTime = ChatterAuditUtils.getBatchNextExecutionDtTime();
        String hour =String.valueOf(nextFireTime.Hour());
        String min = String.valueOf(nextFireTime.minute());
        String ss = String.valueOf(nextFireTime.second());
        String day = String.valueOf(nextFireTime.day());
        String month = String.valueOf(nextFireTime.month());
        String year = String.valueOf(nextFireTime.year());
        String nextFireTimeStr = ss + ' ' + min + ' ' + hour + ' ' + day + ' ' + month + ' ? ' + year;
        return nextFireTimeStr;
    }
    
    /**
    * get batch next execution time
    *
    * @return Datetime          Datetime with the next batch execution time
    */
    public static Datetime getPmBatchNextExecutionDtTime(){
        String hoursFreq = ChatterAuditSettingsHandler.getPmChatterUpdateFequency();
        Datetime rightNow = Datetime.now();
        Datetime nextFireTime = rightNow.addHours(Integer.valueOf(hoursFreq));
        return nextFireTime;
    } 

   /**
    * get batch next execution time
    *
    * @return String            String with next fire time
    */
    public static string getPmBatchNextExecutionTime(){
        Datetime nextFireTime = ChatterAuditUtils.getPmBatchNextExecutionDtTime();
        String hour =String.valueOf(nextFireTime.Hour());
        String min = String.valueOf(nextFireTime.minute());
        String ss = String.valueOf(nextFireTime.second());
        String day = String.valueOf(nextFireTime.day());
        String month = String.valueOf(nextFireTime.month());
        String year = String.valueOf(nextFireTime.year());
        String nextFireTimeStr = ss + ' ' + min + ' ' + hour + ' ' + day + ' ' + month + ' ? ' + year;
        return nextFireTimeStr;
    }

   /**
    * Is valid String
    *
    * @param testStr    String to test
    *
    * @return boolean   boolean
    */
    public static boolean isValidString(String testStr){
        return (testStr != null && testStr != '' && testStr !='null');
    }

   /**
    * Is valid Date (full date with hours:minutes included)
    *
    * @param InputString    Date to test
    *
    * @return boolean   boolean
    */
    public static boolean isValidDate(String dateFull){
        boolean ret = true;
        Datetime theDate = null;
        try{
                String[] dateVector = dateFull.split('_');
                String[] dateOnly = dateVector[0].split('-');
                String[] timeOnly = dateVector[1].split(':');
                if ( dateOnly.size() != 3 || timeOnly.size() != 2 ) return false;
                theDate = datetime.newInstance( Integer.valueOf(dateOnly[0]), Integer.valueOf(dateOnly[1]), Integer.valueOf(dateOnly[2]), Integer.valueOf(timeOnly[0]), Integer.valueOf(timeOnly[1]), 0 );  
        }catch(Exception e){            
            ret = false;
        }
        return ret; 
    }
    
    /**
    * Is valid Date (yyyy-mm-dd)
    *
    * @param InputString    Date to test
    *
    * @return boolean   boolean
    */
    public static boolean isValidDateSimple(String dateFull){
        boolean ret = true;
        Datetime theDate = null;
        try{
                String[] dateOnly = dateFull.split('-');
                if ( dateOnly.size() != 3 ) return false;
                theDate = datetime.newInstance( Integer.valueOf(dateOnly[0]), Integer.valueOf(dateOnly[1]), Integer.valueOf(dateOnly[2]), 0, 0, 0 );  
        }catch(Exception e){            
            ret = false;
        }
        return ret; 
    }

   /**
    * sanitize
    *  Method used for sanatizing input for SQL
    *
    * @param value  String to test
    *
    * @return String    String sanitized
    */
    public static String sanitize( String value ){
        String clean_value  = '';
        //
        clean_value = value.replaceAll('\\_','\\\\_');
        return clean_value;
    }

   /**
    * get User Details by Name
    *
    * @param filterName     String with name to filter
    *
    * @return List<item>    list<item>
    */
    public static List<ChatterAuditLookUpController.Item> getUserDetailsByName(String filterName){
        List<ChatterAuditLookUpController.Item> ret = new List<ChatterAuditLookUpController.Item>();
        String q =  ' SELECT  Id, Name, Email, Title '+
                    ' FROM User ';
        if (isValidString(filterName)){
            filterName = '\'%'+ChatterAuditUtils.sanitize(String.escapeSingleQuotes(filterName )) +'%\'' ;
            q += ' WHERE Name LIKE  '+filterName ;
        }
            q += ' ORDER BY  Name asc  Limit '+ChatterAuditConstants.MAX_DML_ROWS ;

        //check fls
        if (User.Id.getDescribe().isAccessible() &&  User.Name.getDescribe().isAccessible() &&
            User.Title.getDescribe().isAccessible() &&  User.Email.getDescribe().isAccessible() ){
            for(User u : Database.query(q)){
                ret.add(new ChatterAuditLookUpController.Item(u.Id,u.Name,u.Title,u.Email,'n/a'));
            }
        }

        
        return ret;//
    }

   /**
    * get Org Url
    *
    * @return String    String with org url
    */
    public static string getOrgUrl(){
        string retUrl= URL.getSalesforceBaseUrl().toExternalForm();
        if (retUrl.contains('http:')){
            retUrl = retUrl.replace('http:','https:');  
        }
        return retUrl;      
    }

    /**  MAILING FUNCTIONS **/

    /**
    * mail Benchmark
    *
    * @param methodName         String
    */
    public static void mailBenchmark(String methodName){
        String subject = Label.ChatterAudit_MAIL_TEXT_subject + ' ['+Userinfo.getOrganizationName()+']'+Datetime.now().format('yyyy-MM-dd_HH:mm:ss');
        String body =   '\n Report for : '  +   Userinfo.getOrganizationName()+'-- org id: '+Userinfo.getOrganizationId() +'\n\n'+
                        '\n============================================================================================\n'   +
                            methodName +
                        '\n============================================================================================\n\n'   +
                        '\n Number of SOQL queries: '   +   Limits.getQueries()+'/'+Limits.getLimitQueries() +
                        '\n Number of query rows: '     +   Limits.getQueryRows()+'/'+Limits.getLimitQueryRows()+
                        '\n Number of SOSL queries: '   +   Limits.getSoslQueries()+'/'+Limits.getLimitSoslQueries()+
                        '\n Number of DML statements: ' +   Limits.getDmlStatements()+'/'+Limits.getLimitDmlStatements()+
                        '\n Number of DML rows:'        +   Limits.getDMLRows()+'/'+Limits.getLimitDMLRows ()+
                        '\n Number of script statements: '+ Limits.getScriptStatements()+'/'+Limits.getLimitScriptStatements()+
                        '\n Maximum heap size: '        +   Limits.getHeapSize()+'/'+Limits.getLimitHeapSize();

        ChatterAuditUtils.sendMail('', subject, body);
    }

   /**
    * mail exception
    *
    * @param errorMsg           String
    * @param methodName         String
    */
    public static void mailException(String errorMsg,String methodName){
        String subject  =   Label.ChatterAudit_MAIL_TEXT_subject_exception + ' ' + Userinfo.getOrganizationName();
        String body     =   Label.ChatterAudit_MAIL_TEXT_exception_part1  +
                            '\n' + Label.ChatterAudit_MAIL_TEXT_exception_part2  +
                            '\n' + Label.ChatterAudit_MAIL_TEXT_exception_part3  +
                            '\n' + Label.ChatterAudit_MAIL_TEXT_exception_part4    ;
        ChatterAuditUtils.sendMail('', subject, body+'\n\r'+errorMsg);
    }

   /**
    * mail export completed
    *
    * @param fileId         file Id
    */
    public static void mailExportCompleted(ID fileId, String msg){
        String subject  =   Label.ChatterAudit_MAIL_TEXT_subject + ' ' + Userinfo.getOrganizationName();
        String body     =   Label.ChatterAudit_MAIL_TEXT_export_part1  +
                            '\n============================================================================================\n'   +
                           +  ChatterAuditUtils.getOrgUrl()+'/'+fileId +
                            '\n============================================================================================\n\n'   +
                            '\n Date : '   +   Datetime.now().format('yyyy-MM-dd_HH:mm:ss') +'\n'+
                            '\n============================================================================================\n\n' +
                            msg ;
        ChatterAuditUtils.sendMail('', subject, body);
    }

   /**
    * mail purge is completed
    *
    * @param fileId             file Id
    */
    public static Boolean  mailPurgeCompleted(ID fileId){
        String subject  =   Label.ChatterAudit_MAIL_TEXT_subject + ' ' + Userinfo.getOrganizationName();
        String body     =   Label.ChatterAudit_MAIL_TEXT_purge_part1  +
                            '\n============================================================================================\n'   +
                            +  ChatterAuditUtils.getOrgUrl()+'/'+fileId +
                            '\n============================================================================================\n\n'   +
                            '\n Date : '   +   Datetime.now().format('yyyy-MM-dd_HH:mm:ss') +'\n';
        Boolean res = ChatterAuditUtils.sendMail('', subject, body);
        return res;
    }

   /**
    * Send Mail
    *
    * @param mailTo         String
    * @param subject        String
    * @param body           String
    *
    * @return Boolean       True if email sent, otherwise False
    */
    public static Boolean sendMail(String mailTo,String subject, String body){
        Boolean success = true;
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        List<User> u                        = [select u.email from User u where u.id=:Userinfo.getUserId() limit 1];
        string senderEmail                  = u[0].Email;
        String[] toAddresses = new String[] { senderEmail};
        if (mailTo!= ''){
            toAddresses.add(mailTo);
        }
        mail.setToAddresses(toAddresses);
        mail.setSubject(subject);
        mail.setPlainTextBody(body);
        List<Messaging.SendEmailResult> results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        for (Integer i=0; i<results.size() && success ; i++){
            success = results.get(0).isSuccess();
        }
        return success;
    }
    
    /**
    * Method to avoid hitting governor limits will throw an exception whenever the actual usage is near the limit
    */
    public static boolean controlLimits(){

        if (Limits.getHeapSize() > ( Limits.getLimitHeapSize() -  ChatterAuditConstants.HEAP_GRACE ) ) {
            return false;
            //throw new ChatterAuditException(Label.ChatterAudit_ExceptionMessages_governorLimit_Heap);
        }

        if (Limits.getScriptStatements() > ( Limits.getLimitScriptStatements() -  ChatterAuditConstants.STATEMENTS_GRACE ) ) {
            return false;
            //throw new ChatterAuditException(Label.ChatterAudit_ExceptionMessages_governorLimit_Scripts);
        }
        return true;
    }
    
    /**
    * This method checks if the custom setting is well configured, if it's not it stores the proper value
    */
    public static void checkCustomSetting(){

        ChatterAuditSettings__c cnf = ChatterAuditSettings__c.getValues(ChatterAuditConstants.CUSTOM_SETTING_NAME);
        if (cnf == null) {
            
            cnf = new ChatterAuditSettings__c();
            cnf.name                        	= ChatterAuditConstants.CUSTOM_SETTING_NAME;
            cnf.ChatterAuditOwnerId__c      	= Userinfo.getUserId();
            cnf.ChatterAuditUpdateFequency__c   = 12;
            cnf.Active__c                       = false;
            cnf.ContentVersionDeleteBlocker__c  = true;
            cnf.ArchivedPMessagesUpdateFreq__c 	= 12; //Default hours
            cnf.PreviousChatterDataLoaded__c	= false;
            
            //checking for user permissions in his/her profile
            if ( !hasPermissions(Userinfo.getUserId() ) ) return;
                        
            upsert cnf;
        }
        
        if ( cnf.ArchivedPMessagesJobId__c == null && hasPermissions(cnf.ChatterAuditOwnerId__c) ){
             cnf.ArchivedPMessagesJobId__c = 'Pending';
             upsert cnf;
             privateMessagesScheduler();
        }
        
        if ( !cnf.PreviousChatterDataLoaded__c && hasPermissions(cnf.ChatterAuditOwnerId__c) ){
        	Database.executeBatch(new ChatterAuditBatchLoader() , ChatterAuditConstants.MAX_BATCH_SIZE);
        	database.executebatch(new ChatterAuditPrivateMessagesBatch(null,false) );
        	cnf.PreviousChatterDataLoaded__c = true;
		   	upsert cnf;
        }        
    } 
    
    /*
     *@author Timbasoftware 
     *@description return if user has enough privileges to manage chatterMessages
     *
     *@param userId - String with User Id
     *@return boolean
     */
    public static boolean hasPermissions(String userId){
    	list<User> u = [Select u.Profile.PermissionsManageChatterMessages, u.ProfileId From User u where u.Id = :userId limit 1];
    	return u.size() > 0 ? u[0].Profile.PermissionsManageChatterMessages : false;
    }
    
    /*
     * Schedule for batch that handles Private Messages Archiving
     */
    public static void privateMessagesScheduler(){       
        try{ 
        	System.schedule(PRIVATE_MESSAGES_JOB_NAME+' -- '+Datetime.now(), getPmBatchNextExecutionTime(), new ChatterAuditPrivateMessagesSch());
        }catch(Exception e){}                          
    }
    
    /**
    * This method checks if the custom setting is well configured, if it's not it send an email to the sys admin
    */
    public static Boolean controlCustomSetting(){
        
        ChatterAuditSettings__c cnf = ChatterAuditSettings__c.getValues(ChatterAuditConstants.CUSTOM_SETTING_NAME);
        
        if (cnf == null) {
            String subject  =   Label.ChatterAudit_ERROR_TEXT_CUSTOM_SETTING_NOT_CONFIGURED_SUBJECT + ' ' + Userinfo.getOrganizationName();
            String body     =   '\n============================================================================================\n'   +
                                +   Label.ChatterAudit_ERROR_TEXT_CUSTOM_SETTING_NOT_CONFIGURED_1  +'\n'+
                                    Label.ChatterAudit_ERROR_TEXT_CUSTOM_SETTING_NOT_CONFIGURED_2 +'\n\n'+
                                    Label.ChatterAudit_ChatterAudit_ERROR_TEXT_CUSTOM_SETTING_NOT_CONFIGURED_3.replace('[name]','"'+ChatterAuditConstants.CUSTOM_SETTING_NAME+'"') +'\n\n'+
                                    Label.ChatterAudit_OrganizationId +': '+UserInfo.getOrganizationId()+'\n'+
                                    Label.ChatterAudit_OrganizationName +': '+UserInfo.getOrganizationName()+'\n'+
                                '\n============================================================================================\n\n';
                            
            Boolean res = ChatterAuditUtils.sendMail('', subject, body);
            return false;            
        }
        
        if ( !hasPermissions(cnf.ChatterAuditOwnerId__c) ){
        	String subject  =   Label.ChatterAudit_ERROR_TEXT_CUSTOM_SETTING_NOT_CONFIGURED_SUBJECT + ' ' + Userinfo.getOrganizationName();
            String body     =   '\n============================================================================================\n'   +
                                +   Label.ChatterAudit_ERROR_TEXT_CUSTOM_SETTING_NOT_CONFIGURED_1  +'\n'+
                                    Label.ChatterAudit_ERROR_TEXT_CUSTOM_SETTING_NOT_CONFIGURED_2 +'\n\n'+
                                    Label.ChatterAudit_ChatterAudit_ERROR_TEXT_CUSTOM_SETTING_NOT_CONFIGURED_4 +'\n'+
                                    Label.ChatterAudit_ChatterAudit_ERROR_TEXT_CUSTOM_SETTING_NOT_CONFIGURED_5 +'\n\n'+
                                    Label.ChatterAudit_OrganizationId +': '+UserInfo.getOrganizationId()+'\n'+
                                    Label.ChatterAudit_OrganizationName +': '+UserInfo.getOrganizationName()+'\n'+
                                '\n============================================================================================\n\n';
                            
            Boolean res = ChatterAuditUtils.sendMail('', subject, body); 
            return false;
        }
        return true;        
    }
    
    public static String getNamespace() {
        String tmp = '';
        
        String fullName = Schema.SObjectType.ArchivedEntityFeed__c.fields.entityId__c.getName();
        String[] pageNameParts = fullName.replaceAll('__c','').split('__');
        tmp =  (pageNameParts.size() > 1) ? pageNameParts[0]+'__' : '';
        
        return tmp;
    }
    
    
    private static Map<String, Boolean> keyAccesibilityFeedItemMap;
    private static Map<String, Boolean> keyAccesibilityFeedCommentMap;
    
   /**
    * load Key Accesibility Map
    */
    public static void loadKeyAccesibilityMap(){
        
        keyAccesibilityFeedItemMap      = new Map<String, Boolean>{};
        keyAccesibilityFeedCommentMap   = new Map<String, Boolean>{};
        
        String nmSpace = getNamespace().toLowerCase();
        //load ArchivedFeedComments accesibility settings 
        Map<String, Schema.SObjectField> M = Schema.SObjectType.ArchivedFeedComment__c.fields.getMap();
        Schema.DescribeFieldResult F;
        for(String s : M.keySet()){
            F = M.get(s).getDescribe();
            keyAccesibilityFeedCommentMap.put(F.getName().toLowerCase().replaceAll(nmSpace,''),F.isAccessible());
        }
        //load ArchivedFeedItems accesibility settings 
        M = Schema.SObjectType.ArchivedFeedItem__c.fields.getMap();
        
        for(String s : M.keySet()){
            F = M.get(s).getDescribe();
            keyAccesibilityFeedItemMap.put(F.getName().toLowerCase().replaceAll(nmSpace,''),F.isAccessible());
        }
        
    }
    
    /**
    * get object Accesibility
    *
    * @param objId      String with object Id
    * @param fieldName  String with fieldName Name
    * @return Boolean   String with object Type
    */
    //Schema.sObjectType.ArchivedFeedComment__c.fields.ParentObjectType__c.isAccessible())
    
    public static Boolean getAccesibility(String objName,String fieldName){
        Boolean res = null;
        if (    keyAccesibilityFeedItemMap == null || 
                keyAccesibilityFeedCommentMap == null){
            loadKeyAccesibilityMap();
        }       
        
        if (objName == 'ArchivedFeedComment__c'){
            res = keyAccesibilityFeedCommentMap.get(fieldName.toLowerCase());
        }else{
            res = keyAccesibilityFeedItemMap.get(fieldName.toLowerCase());
        
        }
        return res;
    }
    
    
    
    public static Boolean okFlsOnCustomObjects(){
        Boolean res = true;
    
        //controls over Archived FeedItem
        res =           ChatterAuditUtils.getAccesibility('ArchivedFeedItem__c','Id')
                    &&  ChatterAuditUtils.getAccesibility('ArchivedFeedItem__c','Id')
                    &&  ChatterAuditUtils.getAccesibility('ArchivedFeedItem__c','Body__c')
                    &&  ChatterAuditUtils.getAccesibility('ArchivedFeedItem__c','Id')
                    &&  ChatterAuditUtils.getAccesibility('ArchivedFeedItem__c','Created_By__c')
                    &&  ChatterAuditUtils.getAccesibility('ArchivedFeedItem__c','Id')
                    &&  ChatterAuditUtils.getAccesibility('ArchivedFeedItem__c','Type__c')
                    &&  ChatterAuditUtils.getAccesibility('ArchivedFeedItem__c','IsParentDeleted__c')
                    &&  ChatterAuditUtils.getAccesibility('ArchivedFeedItem__c','IsDeleted__c')
                    &&  ChatterAuditUtils.getAccesibility('ArchivedFeedItem__c','ParentId__c')
                    &&  ChatterAuditUtils.getAccesibility('ArchivedFeedItem__c','GroupName__c') 
                    &&  ChatterAuditUtils.getAccesibility('ArchivedFeedItem__c','ParentObjectType__c')
                    &&  ChatterAuditUtils.getAccesibility('ArchivedFeedItem__c','FeedItemId__c')
                    &&  ChatterAuditUtils.getAccesibility('ArchivedFeedItem__c','Title__c')
                    &&  ChatterAuditUtils.getAccesibility('ArchivedFeedItem__c','LinkUrl__c')
                    && ChatterAuditUtils.getAccesibility('ArchivedFeedItem__c','ContentFileName__c')
                    &&  ChatterAuditUtils.getAccesibility('ArchivedFeedItem__c','ContentDescription__c') ;
                    
        //controls over Arhived Comments
        res = res   &&  ChatterAuditUtils.getAccesibility('ArchivedFeedComment__c','ArchivedFeedItem__c')
                    &&  ChatterAuditUtils.getAccesibility('ArchivedFeedComment__c','Id')
                    &&  ChatterAuditUtils.getAccesibility('ArchivedFeedComment__c','CommentBody__c')
                    &&  ChatterAuditUtils.getAccesibility('ArchivedFeedComment__c','CreatedDate__c')
                    &&  ChatterAuditUtils.getAccesibility('ArchivedFeedComment__c','Created_By__c')
                    &&  ChatterAuditUtils.getAccesibility('ArchivedFeedComment__c','Id')
                    &&  ChatterAuditUtils.getAccesibility('ArchivedFeedComment__c','IsParentDeleted__c')
                    &&  ChatterAuditUtils.getAccesibility('ArchivedFeedComment__c','IsDeleted__c')
                    &&  ChatterAuditUtils.getAccesibility('ArchivedFeedComment__c','ParentId__c')
                    &&  ChatterAuditUtils.getAccesibility('ArchivedFeedComment__c','CommentBody__c')
                    &&  ChatterAuditUtils.getAccesibility('ArchivedFeedComment__c','ParentName__c') 
                    &&  ChatterAuditUtils.getAccesibility('ArchivedFeedComment__c','ParentObjectType__c')
                    &&  ChatterAuditUtils.getAccesibility('ArchivedFeedComment__c','FeedItemId__c') ;
    
        return res;
    
    }
    
    public static String encodeHtml(String word) {
        if (word == null) {
           return word;
        }
        return word
            .replace('&', '&amp;')
            .replace('<', '&lt;')
            .replace('>', '&gt;')
            .replace('\'', '&#39;')
            .replace('"', '&quot;');
    }
    
    public static String SFDC_JSENCODE(String input) {
        return ENCODE(input, JS_DECODED, JS_ENCODED);
    }

    private static String ENCODE(String input, String[] fromArr, String[] toArr) {
        if (input == null || input.length() == 0)
            return input;

        for (Integer i = 0; i < fromArr.size(); ++i) {
            input = input.replace(fromArr[i], toArr[i]);
        }
        
        return input;
    } 
    
}