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
/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 **
 */
@isTest(onInstall=false)
private class ChatterAuditFeedCommentTest {

    static testMethod void triggersTestForFeedComments() {

  		ChatterAuditTestEnvironment.generateConfig();
        ChatterAuditTestEnvironment.initParentObjects();

  		Test.startTest();
  		FeedItem fi = new FeedItem(Body = 'Hello World', ParentId =ChatterAuditTestEnvironment.chattUser.Id);
		insert fi;

		FeedComment cOne = new FeedComment();
        cOne.CommentBody = 'Goodbye World';
        cOne.CreatedById = Userinfo.getUserId();
        cOne.CreatedDate = Datetime.now();
        cOne.FeedItemId = fi.Id;

        insert cOne;

        //test trigger for after insert
        list<ArchivedFeedComment__c> lFC = [Select f.CommentBody__c, f.isDeleted__c
        									FROM  ArchivedFeedComment__c f
        									WHERE f.FeedItemId__c = :cOne.FeedItemId
        									limit 999];

        //Asserts
        system.assertEquals( cOne.CommentBody , lFC[0].CommentBody__c );
        system.assertEquals( false, lFC[0].isDeleted__c );

        //test trigger for after delete
        String feedItemId    = cOne.FeedItemId;
        String textToCompare = cOne.CommentBody;
        delete cOne;

        lFC = [Select f.CommentBody__c, f.isDeleted__c
        	   FROM  ArchivedFeedComment__c f
        	   WHERE f.FeedItemId__c = :feedItemId
        	   limit 999];

		//Asserts
		system.assertEquals( textToCompare, lFC[0].CommentBody__c );
		system.assertEquals( true, lFC[0].isDeleted__c );

        Test.stopTest();
    }

    @isTest(SeeAllData=true)
    static void triggersTestForOrphanFeedComment() {

  		ChatterAuditTestEnvironment.generateConfig();
        ChatterAuditTestEnvironment.initParentObjects();
        ChatterAuditUtils.setDeleteAllowedForPosts(true);
        String originalType = '';
 		Datetime originalCreatedDate ;

  		Test.startTest();
  		FeedItem fi = new FeedItem(Body = 'Hello World', ParentId =ChatterAuditTestEnvironment.chattUser.Id);
		insert fi;

		//Creating a comment

		FeedComment cOne = new FeedComment();
        cOne.CommentBody = 'Goodbye World';
        cOne.CreatedById = Userinfo.getUserId();
        cOne.CreatedDate = Datetime.now();
        cOne.FeedItemId = fi.Id;

        insert cOne;

        //Find and delete the archivedFeedItem , so next feedComment will be an orphan child
        list<ArchivedFeedItem__c> aFI = new list<ArchivedFeedItem__c>();
        aFI = [Select f.Id , f.Type__c, f.ParentId__c, f.ParentObjectType__c, f.CreatedDate__c
        		FROM  ArchivedFeedItem__c f
        	  	WHERE f.ParentId__c = :ChatterAuditTestEnvironment.chattUser.Id
        	  	limit 1];

        if ( aFI.size() > 0 ){
        	 originalType 			= aFI[0].Type__c;
        	 originalCreatedDate	= aFI[0].CreatedDate__c;
        	 delete aFI;
        }


        //Creating an orphan comment

        FeedComment cTwo = new FeedComment();
        cTwo.CommentBody = 'Goodbye Orphan World';
        cTwo.CreatedById = Userinfo.getUserId();
        cTwo.CreatedDate = Datetime.now();
        cTwo.FeedItemId = fi.Id;

        insert cTwo;

        //If everything worked fine , cOneArchived.ArchivedFeedItem__c <> cTwoArchived.ArchivedFeedItem__c
        //  as father for first one has been deleted and second one recreated it but with different
         // Id 

        //Getting corresponding ArchivedFeedComments
        list<ArchivedFeedComment__c> lAF = new list<ArchivedFeedComment__c>();
        lAF= [Select f.ArchivedFeedItem__c , f.CommentBody__c
        		FROM  ArchivedFeedComment__c f
        		WHERE f.FeedItemId__c = :fi.Id ];

        ArchivedFeedComment__c cOneArchived = lAF[0];
        ArchivedFeedComment__c cTwoArchived = lAF[1];

        system.assertNotEquals( cOneArchived.ArchivedFeedItem__c , cTwoArchived.ArchivedFeedItem__c );

        //Find and check new Archived has the same type as the original one
        list<ArchivedFeedItem__c> aFIClone = new list<ArchivedFeedItem__c>();
        aFIClone = [Select f.Id , f.Type__c, f.ParentId__c, f.ParentObjectType__c, f.CreatedDate__c
        			FROM  ArchivedFeedItem__c f
        	  		WHERE f.ParentId__c = :ChatterAuditTestEnvironment.chattUser.Id
        	  		limit 1];

        if ( aFIClone.size() > 0 ){
        	 system.assertEquals( originalType , 		aFIClone[0].Type__c );
        	 system.assertEquals( originalCreatedDate.format('yyyy-MM-dd'), aFIClone[0].CreatedDate__c.format('yyyy-MM-dd') );
        	 
        }

        Test.stopTest();

    }

    @isTest(SeeAllData=true)
    static void triggersTestForOrphanFeedCommentLinkPost() {

  		ChatterAuditTestEnvironment.generateConfig();
        ChatterAuditTestEnvironment.initParentObjects();
        ChatterAuditUtils.setDeleteAllowedForPosts(true);
        String originalType = '';
        Datetime originalCreatedDate ;

  		Test.startTest();

    	FeedItem fi = new FeedItem(Body = 'Hello World', ParentId = Userinfo.getUserId(),LinkUrl='http://www.foo.foo');
    	insert fi;

    	//Getting the corresponding archived item of fi var
    	List<ArchivedFeedItem__c> lArch = [Select a.FeedItemId__c, a.isDeleted__c,a.Id,a.Type__c,
									a.ParentObjectType__c, a.ParentId__c , a.Body__c , a.LinkUrl__c , a.CreatedDate__c
									From ArchivedFeedItem__c a where a.ParentId__c =: Userinfo.getUserId()
									and a.FeedItemId__c =:fi.Id limit 1];

		//Saving original type to compare later with recreated archived item
		if ( lArch.size() > 0 ) {
			originalType 		= lArch[0].Type__c;
			originalCreatedDate	= lArch[0].CreatedDate__c;
		}

		//now lets delete archived feedItem and post a comment in corresponding fi to get an orphan child
		delete lArch;

		FeedComment cOne = new FeedComment();
        cOne.CommentBody = 'Foo';
        cOne.CreatedById = Userinfo.getUserId();
        cOne.CreatedDate = Datetime.now();
        cOne.FeedItemId = fi.Id;
        insert cOne;

        //Getting the recreated archived item and comparing types with the original one

         lArch = [Select a.FeedItemId__c, a.isDeleted__c,a.Id,a.Type__c,a.CreatedDate__c,
									a.ParentObjectType__c, a.ParentId__c , a.Body__c , a.LinkUrl__c
									From ArchivedFeedItem__c a where a.ParentId__c =: Userinfo.getUserId()
									and a.FeedItemId__c =:fi.Id limit 1];


        system.assertEquals( originalType, lArch[0].Type__c );
 		system.assertEquals( originalCreatedDate.format('yyyy-MM-dd'), lArch[0].CreatedDate__c.format('yyyy-MM-dd') );
    	test.stopTest();
    }

    @isTest(SeeAllData=true)
    static void triggersTestForOrphanFeedCommentContentPost() {

  		ChatterAuditTestEnvironment.generateConfig();
        ChatterAuditTestEnvironment.initParentObjects();
        ChatterAuditUtils.setDeleteAllowedForPosts(true);
        String originalType = '';
        Datetime originalCreatedDate ;

  		Test.startTest();

    	FeedItem fi = new FeedItem(Body = 'Hello World', ParentId =ChatterAuditTestEnvironment.chattUser.Id);
  		fi.ContentData 			= Blob.valueOf('BIG FILE');
  		fi.ContentDescription 	= 'a test file';
  		fi.ContentFileName		= 'fooFile.txt';
		insert fi;

    	//Getting the corresponding archived item of fi var
    	List<ArchivedFeedItem__c> lArch = [Select a.FeedItemId__c,a.Id,a.Type__c, a.ParentObjectType__c,
										   a.ParentId__c , a.Body__c, a.ContentFileName__c, a.CreatedDate__c
											From ArchivedFeedItem__c a
											where a.ParentId__c =: ChatterAuditTestEnvironment.chattUser.Id
											limit 1];

		//Saving original type to compare later with recreated archived item
		if ( lArch.size() > 0 ) {
				originalType 		= lArch[0].Type__c;
				originalCreatedDate	= lArch[0].CreatedDate__c;	
		}

		//now lets delete archived feedItem and post a comment in corresponding fi to get an orphan child
		delete lArch;

		FeedComment cOne = new FeedComment();
        cOne.CommentBody = 'Foo';
        cOne.CreatedById = Userinfo.getUserId();
        cOne.CreatedDate = Datetime.now();
        cOne.FeedItemId = fi.Id;
        insert cOne;

        //Getting the recreated archived item and comparing types with the original one

         lArch = [Select a.FeedItemId__c,a.Id,a.Type__c, a.ParentObjectType__c,
		    	  a.ParentId__c , a.Body__c, a.ContentFileName__c,  a.CreatedDate__c
				    From ArchivedFeedItem__c a
					where a.ParentId__c =: ChatterAuditTestEnvironment.chattUser.Id limit 1];

        system.assertEquals( originalType, lArch[0].Type__c );
        system.assertEquals( originalCreatedDate.format('yyyy-MM-dd'), lArch[0].CreatedDate__c.format('yyyy-MM-dd') );

    	test.stopTest();
    }

    static testMethod void triggersTestForOrphanFeedCommentUserStatus() {

  		ChatterAuditTestEnvironment.generateConfig();
        ChatterAuditTestEnvironment.initParentObjects();
        ChatterAuditUtils.setDeleteAllowedForPosts(true);
        String originalType = '';
		Datetime originalCreatedDate ;

  		Test.startTest();

    	User user = [select id, CurrentStatus from User where id =: UserInfo.getUserId()];
		user.CurrentStatus = 'my new status message';
		update user;


    	//Getting the corresponding archived item of fi var
    	List<ArchivedFeedItem__c> lArch = [Select a.FeedItemId__c, a.isDeleted__c,a.Id,a.Type__c,a.CreatedDate__c,
											a.ParentObjectType__c, a.ParentId__c , a.Body__c , a.LinkUrl__c
											From ArchivedFeedItem__c a
											where a.ParentId__c =: Userinfo.getUserId()
											ORDER BY CreatedDate DESC LIMIT 1];

		//Saving original type to compare later with recreated archived item
		if ( lArch.size() > 0 ){
			originalType 		= lArch[0].Type__c;
			originalCreatedDate	= lArch[0].CreatedDate__c;
		}

		//now lets delete archived feedItem and post a comment in corresponding fi to get an orphan child
		delete lArch;

		user.CurrentStatus = 'my new NEW status message';
		update user;

		//Getting the recreated archived item and comparing types with the original one

         lArch = [Select a.FeedItemId__c, a.isDeleted__c,a.Id,a.Type__c,a.CreatedDate__c,
											a.ParentObjectType__c, a.ParentId__c , a.Body__c , a.LinkUrl__c
											From ArchivedFeedItem__c a
											where a.ParentId__c =: Userinfo.getUserId()
											ORDER BY CreatedDate DESC LIMIT 1];

        system.assertEquals( originalType, lArch[0].Type__c );
		system.assertEquals( originalCreatedDate.format('yyyy-MM-dd'), lArch[0].CreatedDate__c.format('yyyy-MM-dd') );
		
    	test.stopTest();
    }
    
     static testMethod void test_lazyloadWithNoComments() {

  		ChatterAuditTestEnvironment.generateConfig();
        ChatterAuditTestEnvironment.initParentObjects();
        ChatterAuditUtils.setDeleteAllowedForPosts(true);
        String originalType = '';
 		Datetime originalCreatedDate ;
 		Boolean originalFlagValue;
 		Decimal originalCommentcount = 0;

  		Test.startTest();
  		FeedItem fi = new FeedItem(Body = 'Hello World', ParentId =ChatterAuditTestEnvironment.chattUser.Id);
		insert fi;

        //Find and delete the archivedFeedItem , so next feedComment will be an orphan child
        list<ArchivedFeedItem__c> aFI = new list<ArchivedFeedItem__c>();
        aFI = [Select 	f.Id , f.Type__c, f.ParentId__c, f.ParentObjectType__c, f.CreatedDate__c , 
        				f.FullArchivedCommentList__c, f.CommentCount__c
        		FROM  ArchivedFeedItem__c f
        	  	WHERE f.FeedItemId__c = :fi.Id
        	  	limit 1];

        if ( aFI.size() > 0 ){
        	 originalType 			= aFI[0].Type__c;
        	 originalCreatedDate	= aFI[0].CreatedDate__c;
        	 originalFlagValue		= aFI[0].FullArchivedCommentList__c;
        	 originalCommentcount	= aFI[0].CommentCount__c;
        	 delete aFI;
        }


        //Creating an comment

        FeedComment c = new FeedComment();
        c.CommentBody = 'Goodbye Orphan World';
        c.CreatedById = Userinfo.getUserId();
        c.CreatedDate = Datetime.now();
        c.FeedItemId = fi.Id;

        insert c;

        //Find and check new Archived has the same type as the original one
        list<ArchivedFeedItem__c> aFIClone = new list<ArchivedFeedItem__c>();
        aFIClone = [Select f.Id , f.Type__c, f.ParentId__c, f.ParentObjectType__c, f.CreatedDate__c, 
        				f.FullArchivedCommentList__c , f.CommentCount__c
        			FROM  ArchivedFeedItem__c f
        	  		WHERE f.FeedItemId__c = :fi.Id
        	  		limit 1];

        if ( aFIClone.size() > 0 ){
        	 system.assertEquals(  originalType , 			aFIClone[0].Type__c );
        	 system.assertEquals( (originalCommentcount + 1 ), 	aFIClone[0].CommentCount__c );
        	 system.assertEquals(  originalCreatedDate.format('yyyy-MM-dd'), aFIClone[0].CreatedDate__c.format('yyyy-MM-dd') );
        	 //initially there where no comments, so we didn't miss any
        	 system.assert( originalFlagValue );
        	 //after Archiving again there are no missing comments, so we didn't miss any
        	 system.assert( aFIClone[0].FullArchivedCommentList__c);
        }

        Test.stopTest();

    }
    
     static testMethod void test_lazyloadWithPreviousComments() {

  		ChatterAuditTestEnvironment.generateConfig();
        ChatterAuditTestEnvironment.initParentObjects();
        ChatterAuditUtils.setDeleteAllowedForPosts(true);
        String originalType = '';
        Decimal originalCommentcount = 0;
 		Datetime originalCreatedDate ;
 		Boolean originalFlagValue;

  		Test.startTest();
  		FeedItem fi = new FeedItem(Body = 'Hello World', ParentId =ChatterAuditTestEnvironment.chattUser.Id);
		insert fi;


 		//Creating an comment
        FeedComment bc = new FeedComment();
        bc.CommentBody = 'Goodbye Orphan World';
        bc.CreatedById = Userinfo.getUserId();
        bc.CreatedDate = Datetime.now();
        bc.FeedItemId = fi.Id;

        insert bc;
        //check that the comment was inserted
		system.assertEquals(1, [SELECT count()
									FROM ArchivedFeedComment__c f
        							WHERE f.FeedCommentId__c = :bc.Id
        							AND f.isDeleted__c = false]);

        //Find and delete the archivedFeedItem , so next feedComment will be an orphan child
        list<ArchivedFeedItem__c> aFI = new list<ArchivedFeedItem__c>();
        aFI = [Select f.Id , f.Type__c, f.ParentId__c, f.ParentObjectType__c, f.CreatedDate__c , 
        				f.FullArchivedCommentList__c , f.CommentCount__c
        		FROM  ArchivedFeedItem__c f
        	  	WHERE f.FeedItemId__c = :fi.Id
        	  	limit 1];

        if ( aFI.size() > 0 ){
        	 originalType 			= aFI[0].Type__c;
        	 originalCreatedDate	= aFI[0].CreatedDate__c;
        	 originalFlagValue		= aFI[0].FullArchivedCommentList__c;
        	 originalCommentcount	= aFI[0].CommentCount__c;
        	 delete aFI;
        }


        //Creating an comment

        FeedComment c = new FeedComment();
        c.CommentBody = 'Goodbye Orphan World';
        c.CreatedById = Userinfo.getUserId();
        c.CreatedDate = Datetime.now();
        c.FeedItemId = fi.Id;

        insert c;

        //Find and check new Archived has the same type as the original one
        list<ArchivedFeedItem__c> aFIClone = new list<ArchivedFeedItem__c>();
        aFIClone = [Select f.Id , f.Type__c, f.ParentId__c, f.ParentObjectType__c, f.CreatedDate__c, 
        					f.FullArchivedCommentList__c , f.CommentCount__c
        			FROM  ArchivedFeedItem__c f
        	  		WHERE f.FeedItemId__c = :fi.Id
        	  		limit 1];

        if ( aFIClone.size() > 0 ){
        	 system.assertEquals( originalType , 				aFIClone[0].Type__c );
        	 system.assertEquals( (originalCommentcount + 1 ), 	aFIClone[0].CommentCount__c );
        	 system.assertEquals( originalCreatedDate.format('yyyy-MM-dd'), aFIClone[0].CreatedDate__c.format('yyyy-MM-dd') );
        	 //initially there where no comments, so we didn't miss any
        	 system.assert( originalFlagValue );
        	 //after Archiving again there are was one missing comment
        	 system.assert( !aFIClone[0].FullArchivedCommentList__c);
        }

        Test.stopTest();

    }    
    @isTest(SeeAllData=true)
    static  void test_lazyloadWithNoCommentsUserStatus() {

  		ChatterAuditTestEnvironment.generateConfig();
  		ChatterAuditTestEnvironment.initParentObjects();
  		ChatterAuditUtils.setDeleteAllowedForPosts(true);
		String originalType = '';		
        Decimal originalCommentcount = 0;
 		Datetime originalCreatedDate ;
 		Boolean originalFlagValue;
		Test.startTest();
		//create a UserStatus post by changing it's current status text
		User chattUser = ChatterAuditTestEnvironment.getGenerateUser('Test User','Chatter Free User');
		System.runAs(chattUser) {
			chattUser.CurrentStatus = 'hello world!';
			update chattUser;
		}

  		List<ArchivedFeedItem__c> aFI = [	Select  a.Id, a.Type__c, a.ParentId__c, a.FeedItemId__c,
  													a.ParentObjectType__c, a.CreatedDate__c , 
  													a.FullArchivedCommentList__c , a.CommentCount__c
											From ArchivedFeedItem__c a
											where 		a.ParentId__c =: chattUser.Id
													and a.isDeleted__c = false limit 1 ];
  		ID fiId = aFI.get(0).FeedItemId__c;
 		

        //Find and delete the archivedFeedItem , so next feedComment will be an orphan child
      
        if ( aFI.size() > 0 ){
        	 originalType 			= aFI[0].Type__c;
        	 originalCreatedDate	= aFI[0].CreatedDate__c;
        	 originalFlagValue		= aFI[0].FullArchivedCommentList__c;
        	 originalCommentcount	= aFI[0].CommentCount__c;
        	 delete aFI;
        }


        //Creating an comment
        FeedComment c = new FeedComment();
        c.CommentBody = 'Goodbye Orphan World';
        c.CreatedById = Userinfo.getUserId();
        c.CreatedDate = Datetime.now();
        c.FeedItemId = fiId;

        insert c;

        //Find and check new Archived has the same type as the original one
        list<ArchivedFeedItem__c> aFIClone = new list<ArchivedFeedItem__c>();
        aFIClone = [Select f.Id , f.Type__c, f.ParentId__c, f.ParentObjectType__c, f.CreatedDate__c, 
        					f.FullArchivedCommentList__c , f.CommentCount__c
        			FROM  ArchivedFeedItem__c f
        	  		WHERE f.FeedItemId__c = :fiId
        	  		limit 1];

        if ( aFIClone.size() > 0 ){
        	 system.assertEquals( originalType , 				aFIClone[0].Type__c );
        	 system.assertEquals( (originalCommentcount+1) , 	aFIClone[0].CommentCount__c );
        	 system.assertEquals( originalCreatedDate.format('yyyy-MM-dd'), aFIClone[0].CreatedDate__c.format('yyyy-MM-dd') );
        	 //initially there where no comments, so we didn't miss any
        	 system.assert( originalFlagValue );
        	 //after Archiving again there are no missing comments
        	 system.assert( aFIClone[0].FullArchivedCommentList__c);
        }

        Test.stopTest();


    }
    
 	@isTest(SeeAllData=true)
     static  void test_lazyloadWithPreviousCommentsUserStatus() {

		ChatterAuditTestEnvironment.generateConfig();
  		ChatterAuditTestEnvironment.initParentObjects();
  		ChatterAuditUtils.setDeleteAllowedForPosts(true);
		String originalType = '';
        Decimal originalCommentcount = 0;
 		Datetime originalCreatedDate ;
 		Boolean originalFlagValue;
		Test.startTest();
		//create a UserStatus post by changing it's current status text
		User chattUser = ChatterAuditTestEnvironment.getGenerateUser('Test User','Chatter Free User');
		System.runAs(chattUser) {
			chattUser.CurrentStatus = 'hello world!';
			update chattUser;
		}
  		List<ArchivedFeedItem__c> aFI = [	Select  a.Id, a.Type__c, a.ParentId__c,  a.FeedItemId__c,
  													a.ParentObjectType__c, a.CreatedDate__c , 
  													a.FullArchivedCommentList__c , a.CommentCount__c
											From ArchivedFeedItem__c a
													where 		a.ParentId__c =: chattUser.Id
															and a.isDeleted__c = false limit 1 ];
  		ID fiId = aFI.get(0).FeedItemId__c;
 		//Creating an comment
        FeedComment bc = new FeedComment();
        bc.CommentBody = 'Goodbye Orphan World';
        bc.CreatedById = Userinfo.getUserId();
        bc.CreatedDate = Datetime.now();
        bc.FeedItemId = fiId;

        insert bc;
        //check that the comment was inserted
		system.assertEquals(1, [SELECT count()
									FROM ArchivedFeedComment__c f
        							WHERE f.FeedCommentId__c = :bc.Id
        							AND f.isDeleted__c = false]);

        //Find and delete the archivedFeedItem , so next feedComment will be an orphan child
      	aFI = [	Select  a.Id, a.Type__c, a.ParentId__c,  a.FeedItemId__c,
  								a.ParentObjectType__c, a.CreatedDate__c , 
  								a.FullArchivedCommentList__c , a.CommentCount__c
				From ArchivedFeedItem__c a
				where 		a.ParentId__c =: chattUser.Id
				and a.isDeleted__c = false limit 1 ];
      
      
      
        if ( aFI.size() > 0 ){
        	 originalType 			= aFI[0].Type__c;
        	 originalCreatedDate	= aFI[0].CreatedDate__c;
        	 originalFlagValue		= aFI[0].FullArchivedCommentList__c;        	 
        	 originalCommentcount	= aFI[0].CommentCount__c;
        	 delete aFI;
        }


        //Creating an comment

        FeedComment c = new FeedComment();
        c.CommentBody = 'Goodbye Orphan World';
        c.CreatedById = Userinfo.getUserId();
        c.CreatedDate = Datetime.now();
        c.FeedItemId = fiId;

        insert c;

        //Find and check new Archived has the same type as the original one
        list<ArchivedFeedItem__c> aFIClone = new list<ArchivedFeedItem__c>();
        aFIClone = [Select f.Id , f.Type__c, f.ParentId__c, f.ParentObjectType__c, f.CreatedDate__c, 
        					f.FullArchivedCommentList__c, f.CommentCount__c
        			FROM  ArchivedFeedItem__c f
        	  		WHERE f.FeedItemId__c = :fiId
        	  		limit 1];

        if ( aFIClone.size() > 0 ){
        	 system.assertEquals( originalType , 		aFIClone[0].Type__c );        	 
        	 system.assertEquals( (originalCommentcount+1) , 	aFIClone[0].CommentCount__c );
        	 system.assertEquals( originalCreatedDate.format('yyyy-MM-dd'), aFIClone[0].CreatedDate__c.format('yyyy-MM-dd') );
        	 //initially there where no comments, so we didn't miss any
        	 system.assert( originalFlagValue );
        	 //after Archiving again there are was one missing comment
        	 system.assert( !aFIClone[0].FullArchivedCommentList__c);
        }

        Test.stopTest();

    }    
    
    //
    static testMethod void triggersTestForFeedCommentsAndContents() {

  		ChatterAuditTestEnvironment.generateConfig();
        ChatterAuditTestEnvironment.initParentObjects();

  		Test.startTest();
  		FeedItem fi = new FeedItem(Body = 'Hello World', ParentId =ChatterAuditTestEnvironment.chattUser.Id);
		insert fi;

		//create content
		Id cntId = ChatterAuditTestEnvironment.generateContentVersionFile();
		FeedComment cOne = new FeedComment();
        cOne.CommentBody = 'Goodbye World';
        cOne.CreatedById = Userinfo.getUserId();
        cOne.CreatedDate = Datetime.now();
        cOne.FeedItemId = fi.Id;
		cOne.RelatedRecordId = cntId;
		
        insert cOne;

        //test trigger for after insert
        list<ArchivedFeedComment__c> lFC = [Select f.CommentBody__c, f.isDeleted__c
        									FROM  ArchivedFeedComment__c f
        									WHERE f.FeedItemId__c = :cOne.FeedItemId
        									limit 999];

        //Asserts
        system.assertEquals( cOne.CommentBody , lFC[0].CommentBody__c );
        system.assertEquals( false, lFC[0].isDeleted__c );

        //test trigger for after delete
        String feedItemId    = cOne.FeedItemId;
        String textToCompare = cOne.CommentBody;
        delete cOne;

        lFC = [Select f.CommentBody__c, f.isDeleted__c,f.RelatedRecordId__c
        	   FROM  ArchivedFeedComment__c f
        	   WHERE f.FeedItemId__c = :feedItemId
        	   limit 999];

		//Asserts
		system.assertEquals( textToCompare, lFC[0].CommentBody__c );
		system.assertEquals( cntId, lFC[0].RelatedRecordId__c );
		system.assertEquals( true, lFC[0].isDeleted__c );

        Test.stopTest();
    }
    
    
}