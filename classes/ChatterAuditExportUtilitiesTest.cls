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
@isTest(OnInstall=false)
private class ChatterAuditExportUtilitiesTest {

	static private Integer max_posts = 10;
	static private Integer max_comments = 5;
    
	static testMethod void test_exportFullCSV() {
    	//public static void exportFull(String fileformat, List<String> idList)
		
  		User uOne = ChatterAuditTestEnvironment.getGenerateUser('User A','Chatter Free User'); 
  		ChatterAuditTestEnvironment.generateConfig();
  		ChatterAuditTestEnvironment.initParentObjects();
		ChatterAuditTestEnvironment.initPostWithComments(uOne.Id,max_posts,max_comments);
		ChatterAuditTestEnvironment.initPostWithComments(uOne.Id,max_posts,0);
		//query initial collection of non deleted feedItems associated with the Account
		List<String> allIds = new List<String>();
		Map<Id,ArchivedFeedItem__c> m = new Map<Id,ArchivedFeedItem__c>([SELECT Id	
										FROM ArchivedFeedItem__c  	
										where 		ParentId__c =: uOne.Id
										limit 999 ]);
		Test.startTest();
		ChatterAuditExportUtilities.exportFull(ChatterAuditConstants.csvUIFull, m.keySet());
		Test.stopTest();
		//
		Document d = [	Select  Id , ContentType, name, body
						from Document 
						where folderId =: ChatterAuditSettingsHandler.getExportForlderId()
						order by CreatedDate desc limit 1];
		
		system.assertEquals(d.ContentType, ChatterAuditConstants.csvContenType);
		system.assert(d.Name.contains( ChatterAuditConstants.csvExtension));
		
	}    

	static testMethod void test_exportQuickCSV() {		
  		User uOne = ChatterAuditTestEnvironment.getGenerateUser('User A','Chatter Free User'); 
  		ChatterAuditTestEnvironment.generateConfig();
  		ChatterAuditTestEnvironment.initParentObjects();
		ChatterAuditTestEnvironment.initPostWithComments(uOne.Id,max_posts,1);
		//query initial collection of non deleted feedItems associated with the Account
		Map<String,String> data = new Map<String,String>();
		String nowStr = Datetime.now().formatGmt('yyyy-MM-dd');
		data.put('startD',nowStr);
		data.put('endD',nowStr);
		data.put('scenario','s0');
		List<String> paramsList = ChatterAuditSearchController.serializeParameters(data);		
					
		Test.startTest();		
		ChatterAuditExportUtilities.exportQuick(ChatterAuditConstants.csvUIQuick, paramsList);
		Test.stopTest();
		//
		Document d = [	Select  Id , ContentType, name, body
						from Document 
						where folderId =: ChatterAuditSettingsHandler.getExportForlderId()
						order by CreatedDate desc limit 1];
		
		system.assertEquals(d.ContentType, ChatterAuditConstants.csvContenType);
		system.assert(d.Name.contains( ChatterAuditConstants.csvExtension));
		
		
		//exceptions : sent mail
		ChatterAuditExportUtilities.exportQuick('csv', null);
		//invoke with no file format
		ChatterAuditExportUtilities.exportQuick(null, new List<String>());
		
    }    
 

	static testMethod void test_exportAndPurge() {
    	//public static void test_exportAndPurge(String fileformat, List<String> idList)
		
  		User uOne = ChatterAuditTestEnvironment.getGenerateUser('User A','Chatter Free User'); 
  		ChatterAuditTestEnvironment.generateConfig();
  		ChatterAuditTestEnvironment.initParentObjects();
		ChatterAuditTestEnvironment.initPostWithComments(uOne.Id,max_posts,1);
		//query initial collection of non deleted feedItems associated with the Account
		Map<Id,ArchivedFeedItem__c> m = new Map<Id,ArchivedFeedItem__c>([SELECT Id	
										FROM ArchivedFeedItem__c  	
										where 		ParentId__c =: uOne.Id
										limit 999 ]);
		Test.startTest();
		String nowStr = Datetime.now().formatGmt('yyyy-MM-dd');
		ChatterAuditExportUtilities.Purge(nowStr,nowStr);
		Test.stopTest();
		
		List<ArchivedFeedItem__c> l = [SELECT Id	
										FROM ArchivedFeedItem__c  	
										where 		ParentId__c =: uOne.Id
										limit 999 ];
		system.assertEquals(0, l.size());	
		
		
				
		//exceptions
		ChatterAuditExportUtilities.Purge( nowStr,nowStr);
		//invoke with no file format
		ChatterAuditExportUtilities.Purge(null,null);		
													
    }
    
    static testMethod void test_exportAndPurgeRetentionBit(){
    	
    	//Retention Bit
		User uOne = ChatterAuditTestEnvironment.getGenerateUser('User A','Chatter Free User'); 
		Integer countBeforePurge = max_posts;
		ChatterAuditTestEnvironment.generateConfig();
  		ChatterAuditTestEnvironment.initParentObjects();
		ChatterAuditTestEnvironment.initPostWithComments(uOne.Id,max_posts,1);
		list<ArchivedFeedItem__c> elms = [SELECT Id, retentionBit__c	
										FROM ArchivedFeedItem__c  	
										where 		ParentId__c =: uOne.Id
										limit 999 ];
										
		system.assertEquals(countBeforePurge, elms.size());
		
		for ( ArchivedFeedItem__c obj : elms ){
			obj.retentionBit__c = true;
		}
		upsert elms;
		
		Test.startTest();
			String nowStr = Datetime.now().formatGmt('yyyy-MM-dd');
			ChatterAuditExportUtilities.Purge(nowStr,nowStr);
		Test.stopTest();
		
		list<ArchivedFeedItem__c> elms2 = [SELECT Id, retentionBit__c	
										FROM ArchivedFeedItem__c  	
										where 		ParentId__c =: uOne.Id
										limit 999 ];
										
		system.assertEquals(countBeforePurge, elms2.size());
    }
}