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
@isTest(onInstall=false)
private class ChatterAuditFeedItemsHandlerTest {

 
    static testMethod void test_updateItemsAsDeleted() {

  		ChatterAuditTestEnvironment.generateConfig();
  		ChatterAuditTestEnvironment.AppConfig.ChatterAuditOwnerId__c = UserInfo.getUserId();
  		ChatterAuditTestEnvironment.initParentObjects();

		FeedItem fi = new FeedItem(Body = 'Hello World', ParentId =ChatterAuditTestEnvironment.chattUser.Id);
		insert fi;

		list<FeedComment> lFC = new list<FeedComment>();
		FeedComment cOne;
		String createdById = Userinfo.getUserId();

		//Create over 1000 feedComments to test handler dealing with governor limits
		for (integer i=0; i< 20; i++){
			cOne = new FeedComment();
        	cOne.CommentBody = 'Goodbye World';
        	cOne.CreatedById = createdById;
        	cOne.CreatedDate = Datetime.now();
        	cOne.FeedItemId = fi.Id;

        	//Add it to the list
        	lFC.add( cOne );
		}

		upsert lFC;

		//query initial collection of non deleted feedItems associated with the Contact

		Test.startTest();
		List<ArchivedFeedItem__c> lArchItemsInitial = [	SELECT  a.Id
														FROM ArchivedFeedItem__c a
														WHERE 		a.ParentId__c =: ChatterAuditTestEnvironment.chattUser.Id
																AND a.isParentDeleted__c = 'false'
																AND a.isDeleted__c = false limit 9999 ];
		Integer initialSize = lArchItemsInitial.size();
		delete fi;
		Test.stopTest();
		List<ArchivedFeedItem__c> lArchItemsFinal = [	SELECT  a.Id
														FROM ArchivedFeedItem__c a
														WHERE 		a.ParentId__c =: ChatterAuditTestEnvironment.chattUser.Id
																AND a.isParentDeleted__c = 'false'
																AND a.isDeleted__c = true limit 9999 ];

		//query initial collection of non deleted feedComments associated with the feedItem
		list<ArchivedFeedComment__c> lCommentARch  = [	SELECT e.Id , e.IsDeleted__c , e.ArchivedFeedItem__c
								  						FROM  ArchivedFeedComment__c e
								  						WHERE e.ParentId__c =: ChatterAuditTestEnvironment.chattUser.Id
								  							 AND e.isParentDeleted__c = 'false'
								  						 	AND   e.isDeleted__c = true limit 9999 ];


		//asserts
		system.assertEquals(1,lArchItemsInitial.size());
		system.assertEquals(1,lArchItemsFinal.size());
		system.assertEquals(20,lCommentARch.size());

    }

    static testMethod void test_ControlArchivedFeedItems() {
        // Check : trigger ControlArchivedFeedItems on ArchivedFeedItem__c (before delete)

  		ChatterAuditTestEnvironment.generateConfig();
  		ChatterAuditTestEnvironment.AppConfig.ChatterAuditOwnerId__c = UserInfo.getUserId();
  		ChatterAuditTestEnvironment.initParentObjects();

		FeedItem fi = new FeedItem(Body = 'Hello World', ParentId =ChatterAuditTestEnvironment.chattUser.Id);
		insert fi;


		//query initial collection of non deleted feedItems associated with the Contact

		Test.startTest();
		List<ArchivedFeedItem__c> lArchItemsInitial = [	SELECT  a.Id
														FROM ArchivedFeedItem__c a
														WHERE 		a.ParentId__c =: ChatterAuditTestEnvironment.chattUser.Id
																AND a.isParentDeleted__c = 'false'
																AND a.isDeleted__c = false limit 9999 ];
		//by default : allowDelete is set to true
		try{
			delete lArchItemsInitial;
		}catch(Dmlexception e){
			//asserts
			System.assert(e.getMessage().contains(Label.ChatterAudit_ExceptionMessage_manual_delete_forbidden));
		}

		try{	
			ArchivedFeedItem__c itmL  = lArchItemsInitial.get(0);
			itmL.Body__c = '==';
			upsert itmL;
		}catch(Dmlexception e){
			//assert
			System.assert(e.getMessage().contains(Label.ChatterAudit_ExceptionMessage_manual_delete_forbidden));
		}
		

		//now we enable deletion
		ChatterAuditUtils.setDeleteAllowedForPosts(true);
		delete lArchItemsInitial;
		List<ArchivedFeedItem__c> lArchItemsFinal = [	SELECT  a.Id
														FROM ArchivedFeedItem__c a
														WHERE 		a.ParentId__c =: ChatterAuditTestEnvironment.chattUser.Id
																AND a.isParentDeleted__c = 'false'
																AND a.isDeleted__c = false limit 9999 ];

		Test.stopTest();
		system.assertEquals(lArchItemsInitial.size(), 1);
		system.assertEquals(lArchItemsFinal.size(), 0);

    }
    
    static testMethod void testContentDocumentTrigger(){
    	
    	test.startTest();
    	ChatterAuditTestEnvironment.generateConfig();
  		ChatterAuditTestEnvironment.AppConfig.ChatterAuditOwnerId__c = UserInfo.getUserId();
  		ChatterAuditTestEnvironment.initParentObjects();

		
		Id postContentVersionCreatedId = ChatterAuditTestEnvironment.generateContentVersionFile();
		ContentVersion postContentVersionDocument = [Select ContentDocumentId from ContentVersion where id = :postContentVersionCreatedId];
		ContentDocument postTheDocument = [ Select Id from ContentDocument where Id = :postContentVersionDocument.ContentDocumentId ];
		
		Id commentContentVersionCreatedId = ChatterAuditTestEnvironment.generateContentVersionFile();
		ContentVersion commentContentVersionDocument = [Select ContentDocumentId from ContentVersion where id = :commentContentVersionCreatedId];
		ContentDocument commentTheDocument = [ Select Id from ContentDocument where Id = :commentContentVersionDocument.ContentDocumentId ];
		
		//Now lets try adding it to a feedItem post
		Id postId = ChatterAuditTestEnvironment.generatePostWithRelatedDocument(postContentVersionCreatedId);
		ChatterAuditTestEnvironment.generateCommentWithRelatedDocument(postId, commentContentVersionCreatedId);
		test.stopTest();
		
		//Now lets try to delete the post document
		boolean exceptionHappened = false;
		try{
			delete postTheDocument;	
		}catch(DmlException e){
			exceptionHappened = true;
		}
		//If this is true, it means trigger didn't allowed the deletion of the contentDocument
		System.assertEquals(true, exceptionHappened);
		
		//And now lets try to delete the comment document
		exceptionHappened = false;
		try{
			delete commentTheDocument;
		}catch(DmlException e){
			exceptionHappened = true;
		}
		//If this is true, it means trigger didn't allowed the deletion of the contentDocument
		System.assertEquals(true, exceptionHappened);				    	
    }
}