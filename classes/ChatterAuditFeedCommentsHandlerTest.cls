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
private class ChatterAuditFeedCommentsHandlerTest {

	static private Integer max_posts = 10;
	static private Integer max_comments = 5;
	
    static testMethod void myUnitTest() {
		ChatterAuditTestEnvironment.generateConfig();
        Test.startTest();

        ChatterAuditTestEnvironment.initParentObjects();

  		FeedItem fi = new FeedItem(Body = 'Hello World', ParentId =ChatterAuditTestEnvironment.chattUser.Id);
		insert fi;

		list<FeedComment> lFC = new list<FeedComment>();
		FeedComment cOne;
		String createdById = Userinfo.getUserId();


		//Create over 1000 feedComments to test handler dealing with governor limits
		for (integer i=0; i< max_comments*2; i++){
			cOne = new FeedComment();
        	cOne.CommentBody = 'Goodbye World';
        	cOne.CreatedById = createdById;
        	cOne.CreatedDate = Datetime.now();
        	cOne.FeedItemId = fi.Id;

        	//Add it to the list
        	lFC.add( cOne );
		}

		upsert lFC;

		//Test all its upserted -- "before deleting"
		system.assertEquals(max_comments*2, [SELECT count()
									FROM ArchivedFeedComment__c f
        							WHERE f.FeedItemId__c = :fi.Id
        							AND f.isDeleted__c = false]);

		//"After Delete" Test
		//Test "individual" feedCommentDeletion
		list<Id> feedCommentsIds = new list<Id>();
		for (integer i=0; i<max_comments;i++){
			feedCommentsIds.add( lFC[i].Id );
		}
		ChatterAuditUtils.setEditAllowedForPosts(true);
		ChatterAuditFeedCommentsHandler.updateItemsAsDeletedByFeedCommentId(feedCommentsIds);

		system.assertEquals(max_comments, [SELECT count()
									FROM ArchivedFeedComment__c f
        							WHERE f.FeedItemId__c = :fi.Id
        							AND f.isDeleted__c = true]);



		//Test "Groupal" feedCommentDeletion
		list<Id> feedItemIds = new list<Id>();
		feedItemIds.add( fi.Id );
		ChatterAuditFeedCommentsHandler.updateItemsAsDeletedByFeedItemId( feedItemIds );

		system.assertEquals(max_comments*2, [SELECT count()
									FROM ArchivedFeedComment__c f
        							WHERE f.FeedItemId__c = :fi.Id
        							AND f.isDeleted__c = true]);

        test.stopTest();
    }
    
    static testMethod void test_ControlArchivedFeedItems() {
        // Check : trigger ControlArchivedFeedItems on ArchivedFeedItem__c (before delete)
    		
  		ChatterAuditTestEnvironment.generateConfig();
  		ChatterAuditTestEnvironment.AppConfig.ChatterAuditOwnerId__c = UserInfo.getUserId();
  		ChatterAuditTestEnvironment.initParentObjects();
  		
  		Test.startTest();
		
		FeedItem fi = new FeedItem(Body = 'Hello CHECK', ParentId =ChatterAuditTestEnvironment.chattUser.Id);
		insert fi;

		//Create over 5 feedComments related to the post
		list<FeedComment> lFC = new list<FeedComment>();
		FeedComment cOne;
		for (integer i=0; i< max_comments; i++){
			cOne = new FeedComment();
        	cOne.CommentBody = 'CHECK ';
        	cOne.CreatedById = Userinfo.getUserId();
        	cOne.CreatedDate = Datetime.now();
        	cOne.FeedItemId = fi.Id;
        	//Add it to the list
        	lFC.add( cOne );
		}

		upsert lFC;
		
		List<ArchivedFeedComment__c> lArchItemsInitial = [	SELECT  a.Id
															FROM ArchivedFeedComment__c a
															WHERE 		a.ParentId__c =: ChatterAuditTestEnvironment.chattUser.Id
																AND a.FeedItemId__c = :fi.Id
        														AND a.isDeleted__c = false limit 9999 ];
		system.assertEquals(lArchItemsInitial.size(), max_comments);
		//by default : allowDelete is set to true
		try{	
			delete lArchItemsInitial;
		}catch(Dmlexception e){
			//assert
			System.assert(e.getMessage().contains(Label.ChatterAudit_ExceptionMessage_manual_delete_forbidden));
		}									
		
		try{	
			ArchivedFeedComment__c itmL  = lArchItemsInitial.get(0);
			itmL.CommentBody__c = '==';
			upsert itmL;
		}catch(Dmlexception e){
			//assert
			System.assert(e.getMessage().contains(Label.ChatterAudit_ExceptionMessage_manual_delete_forbidden));
		}	
		
		//now we enable deletion
		ChatterAuditUtils.setDeleteAllowedForPosts(true);
		delete lArchItemsInitial;
		List<ArchivedFeedComment__c> lArchItemsFinal = [	SELECT  a.Id
															FROM ArchivedFeedComment__c a
															WHERE 		a.ParentId__c =: ChatterAuditTestEnvironment.chattUser.Id
																AND a.FeedItemId__c = :fi.Id
        														AND a.isDeleted__c = true limit 9999 ];		
		
		Test.stopTest();	
		
		system.assertEquals( 0, lArchItemsFinal.size());		
		   
    }    
    
    
    static testMethod void test_CommentCount_creation() {
        // Check : test_CommentCount on ArchivedFeedItem__c 
    		
  		ChatterAuditTestEnvironment.generateConfig();
  		ChatterAuditTestEnvironment.AppConfig.ChatterAuditOwnerId__c = UserInfo.getUserId();
  		ChatterAuditTestEnvironment.initParentObjects();
  		
  		Test.startTest();
		
		FeedItem fi = new FeedItem(Body = 'Hello CHECK', ParentId =ChatterAuditTestEnvironment.chattUser.Id);
		insert fi;

		List<ArchivedFeedItem__c> lArchItemsInitial = [	SELECT  a.Id, a.CommentCount__c
															FROM ArchivedFeedItem__c a
															WHERE 		a.ParentId__c =: ChatterAuditTestEnvironment.chattUser.Id
																AND a.FeedItemId__c = :fi.Id
        														AND a.isDeleted__c = false limit 9999 ];
		//Initially it'll have 0 comments
		system.assertEquals( 1, lArchItemsInitial.size() );
		system.assertEquals( 0, lArchItemsInitial.get(0).CommentCount__c);
		
		//Create over 5 feedComments related to the post
		list<FeedComment> lFC = new list<FeedComment>();
		FeedComment cOne;
		for (integer i=0; i< max_comments; i++){
			cOne = new FeedComment();
        	cOne.CommentBody = 'CHECK ';
        	cOne.CreatedById = Userinfo.getUserId();
        	cOne.CreatedDate = Datetime.now();
        	cOne.FeedItemId = fi.Id;
        	//Add it to the list
        	lFC.add( cOne );
		}

		upsert lFC;
		Test.stopTest();
		lArchItemsInitial = [	SELECT  a.Id, a.CommentCount__c
															FROM ArchivedFeedItem__c a
															WHERE 		a.ParentId__c =: ChatterAuditTestEnvironment.chattUser.Id
																AND a.FeedItemId__c = :fi.Id
        														AND a.isDeleted__c = false limit 9999 ];
		//after adding comments it'll have 5 comments
		system.assertEquals( 1, lArchItemsInitial.size());
		system.assertEquals( max_comments,lArchItemsInitial.get(0).CommentCount__c);
		

				
		   
    }    
    
    
     static testMethod void test_CommentCount_Update() {
        // Check : test_CommentCount on ArchivedFeedItem__c 
    		
  		ChatterAuditTestEnvironment.generateConfig();
  		ChatterAuditTestEnvironment.AppConfig.ChatterAuditOwnerId__c = UserInfo.getUserId();
  		ChatterAuditTestEnvironment.initParentObjects();
  		
  		Test.startTest();
		
		FeedItem fi = new FeedItem(Body = 'Hello CHECK', ParentId =ChatterAuditTestEnvironment.chattUser.Id);
		insert fi;

		List<ArchivedFeedItem__c> lArchItemsInitial = [	SELECT  a.Id, a.CommentCount__c
															FROM ArchivedFeedItem__c a
															WHERE 		a.ParentId__c =: ChatterAuditTestEnvironment.chattUser.Id
																AND a.FeedItemId__c = :fi.Id
        														AND a.isDeleted__c = false limit 9999 ];
		//Initially it'll have 0 comments
		system.assertEquals( 1, lArchItemsInitial.size() );
		system.assertEquals( 0, lArchItemsInitial.get(0).CommentCount__c);
		
		//Create over 5 feedComments related to the post
		list<FeedComment> lFC = new list<FeedComment>();
		FeedComment cOne;
		for (integer i=0; i< max_comments; i++){
			cOne = new FeedComment();
        	cOne.CommentBody = 'CHECK ';
        	cOne.CreatedById = Userinfo.getUserId();
        	cOne.CreatedDate = Datetime.now();
        	cOne.FeedItemId = fi.Id;
        	//Add it to the list
        	lFC.add( cOne );
		}

		upsert lFC;		
		
		
		//after deleting one comment
		delete lFC.get(0);
		Test.stopTest();
		lArchItemsInitial = [	SELECT  a.Id, a.CommentCount__c
															FROM ArchivedFeedItem__c a
															WHERE 		a.ParentId__c =: ChatterAuditTestEnvironment.chattUser.Id
																AND a.FeedItemId__c = :fi.Id
        														AND a.isDeleted__c = false limit 9999 ];
		//after adding comments it'll have 4 comments
		system.assertEquals( 1, lArchItemsInitial.size());
		system.assertEquals( max_comments -1, lArchItemsInitial.get(0).CommentCount__c);	
		
			
		
		
		List<ArchivedFeedComment__c>lArchCommentsInitial = [	SELECT  a.Id
															FROM ArchivedFeedComment__c a
															WHERE 		a.ParentId__c =: ChatterAuditTestEnvironment.chattUser.Id
																AND a.FeedItemId__c = :fi.Id
        														AND a.isDeleted__c = true limit 9999 ];
		system.assertEquals( 1, lArchCommentsInitial.size());	
				
				
		delete [Select id from FeedComment where ParentId =: ChatterAuditTestEnvironment.chattUser.Id];
		lArchItemsInitial = [	SELECT  a.Id, a.CommentCount__c
															FROM ArchivedFeedItem__c a
															WHERE 		a.ParentId__c =: ChatterAuditTestEnvironment.chattUser.Id
																AND a.FeedItemId__c = :fi.Id
        														AND a.isDeleted__c = false limit 9999 ];
		//after deleting all  comments it'll have 0 comments
		system.assertEquals( 1,lArchItemsInitial.size());
		system.assertEquals( 0, lArchItemsInitial.get(0).CommentCount__c);			
				
		   
    }    
    
}