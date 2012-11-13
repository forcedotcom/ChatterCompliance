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
public with sharing class ChatterAuditPurgeController {


	public ChatterAuditPurgeController() {
		
  	}

	public Pagereference checkSetting(){
	
		ChatterAuditUtils.checkCustomSetting();
		return null;
	}


	public static List<purgeItem> getRecordsToPurge(String startD, String endD){
		
		String scenario = Apexpages.currentPage().getParameters().get('screen') != null ? String.escapeSingleQuotes(Apexpages.currentPage().getParameters().get('screen')) : 'public';
		
		
		List<purgeItem> listItems = new List<purgeItem>();
		String query;
		
		if ( scenario == 'public' ){
				query = 	'	SELECT Id, isParentDeleted__c, isDeleted__c, Type__c, ' +
							'	ParentObjectType__c, ' +
							'	ParentId__c, FeedItemId__c,  ' +
							'	IsDeleted,  Body__c ,' +
							'	 CreatedDate__c, Created_By__c,Created_By__r.Name , CreatedDate, retentionBit__c ' +
							'	FROM ArchivedFeedItem__c ' ;
							
				//FILTER BY : CreatedDate  - before & after
				if (ChatterAuditUtils.isValidString(startD) && ChatterAuditUtils.isValidString(endD) ){
					try {
						String s = String.escapeSingleQuotes(startD+'T00:00:00.000Z');
						query += '	WHERE  CreatedDate__c >= ' + s + ' and ';
						String d = String.escapeSingleQuotes(endD+'T23:59:59.000Z');
						query += '	CreatedDate__c <= '+ d +'  ';
						query +=	'	order by CreatedDate__c Limit '+ChatterAuditConstants.MAXIMUM_LIST_RESULTS;
						//Typecasting it to map
						for(ArchivedFeedItem__c aItm : Database.query(query)){
							listItems.add(new purgeItem(aItm));
						}				    
					}catch (Exception e) { ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.ChatterAudit_errorMessage+e.getMessage()));}		  		
				}										
		}else{
				query = 	'	Select Id, Body__c, ConversationId__c, CreatedById__c, SenderId__c, SentDate__c, SenderId__r.Name, CreatedDate, retentionBit__c '+
								' 	FROM ArchivedChatterMessage__c ';
								
				//FILTER BY : CreatedDate  - before & after
				if (ChatterAuditUtils.isValidString(startD) && ChatterAuditUtils.isValidString(endD) ){
					try {
						String s = String.escapeSingleQuotes(startD+'T00:00:00.000Z');
						query += '	WHERE  SentDate__c >= ' + s + ' and ';
						String d = String.escapeSingleQuotes(endD+'T23:59:59.000Z');
						query += '	SentDate__c <= '+ d +'  ';
						query +=	'	order by SentDate__c Limit '+ChatterAuditConstants.MAXIMUM_LIST_RESULTS;
						//Typecasting it to map
						for(ArchivedChatterMessage__c aItm : Database.query(query)){
							listItems.add(new purgeItem(aItm));
						}				    
					}catch (Exception e) { ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.ChatterAudit_errorMessage+e.getMessage()));}		  		
				}		
		}		
		return listItems;	
	}
	
	/*
	  * Retention Bit Feature
	  *   @Id - element Id (via getparamters)
	  *   @retention - boolean true/false (via getparameters)
	  */
	
	public void retBitActionFunction(){
		String elmId = Apexpages.currentPage().getParameters().get('elmId');
		boolean forRetention = Boolean.valueOf(Apexpages.currentPage().getParameters().get('retention'));
		
		list<ArchivedFeedItem__c> lF = [Select Id, retentionBit__c from ArchivedFeedItem__c where id = :elmId];
		
		if ( lF.size() < 1 ){
			list<ArchivedChatterMessage__c> lC = [Select Id, retentionBit__c from ArchivedChatterMessage__c where id = :elmId];
			if ( lC.size() > 0 ){
				lC[0].retentionBit__c = forRetention;
				upsert lC;
			}
		}else{
			ChatterAuditUtils.setEditAllowedForPosts(true);
			lF[0].retentionBit__c = forRetention;
			upsert lF;
			ChatterAuditUtils.setEditAllowedForPosts(false);
		}		
	}


	
public class purgeItem {


		public Id 		id {get; set;}
		public String 	Type {get; set;}
		public String  	body {get; set;}
		public String createdDate {get; set;}
		public String archivedDate {get; set;}
		public String 	author {get; set;}
		public boolean retention {get;set;}			
			
			public purgeItem( ArchivedFeedItem__c aPost ){
				this.retention = aPost.retentionBit__c;
			if (  ChatterAuditUtils.getAccesibility('ArchivedFeedItem__c','Id')){
					this.id = aPost.Id;
				}
				
			if ( ChatterAuditUtils.getAccesibility('ArchivedFeedItem__c','Type__c')){
					this.Type =  apost.Type__c;
			}		
			if (ChatterAuditUtils.getAccesibility('ArchivedFeedItem__c','Body__c')){
					this.body =  ChatterAuditUtils.encodeHtml(aPost.body__c);
				}	
			if (ChatterAuditUtils.getAccesibility('ArchivedFeedItem__c','Id')){
					this.createdDate = apost.CreatedDate__c.format('MM-dd-yyyy hh:mm a');
				}	
			if ( ChatterAuditUtils.getAccesibility('ArchivedFeedItem__c','Created_By__c')){
					this.author =  ChatterAuditUtils.encodeHtml(apost.Created_By__r.Name);
				}	
			if ( ChatterAuditUtils.getAccesibility('ArchivedFeedItem__c','CreatedDate')){
					this.archivedDate =  apost.CreatedDate.format('MM-dd-yyyy hh:mm a');
			}	
			
		}
		
		public purgeItem( ArchivedChatterMessage__c aMessage ){
			this.id = aMessage.Id;
			this.type = 'Private Message';
			this.body = ChatterAuditUtils.encodeHtml(aMessage.body__c);
			this.createdDate = aMessage.SentDate__c.format('MM-dd-yyyy hh:mm a');
			this.archivedDate = aMessage.CreatedDate.format('MM-dd-yyyy hh:mm a');
			this.author = ChatterAuditUtils.encodeHtml(aMessage.SenderId__r.Name);
			this.retention = aMessage.retentionBit__c;
		}
				
	}

}