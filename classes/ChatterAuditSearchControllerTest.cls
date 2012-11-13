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
private class ChatterAuditSearchControllerTest {

	/**
		test search using scenario 1 - option 1

	**/

	static testMethod void test_controller() {
    	PageReference pageRef = Page.ChatterAuditSearch;
        Test.setCurrentPage(pageRef);
  		Test.startTest();
  		//create the account
  		ChatterAuditTestEnvironment.generateConfig();
  		ChatterAuditTestEnvironment.initParentObjects();
  		User chattUser = ChatterAuditTestEnvironment.getGenerateUser('Test User','Chatter Free User');

  		//create posts/comments
  		System.runAs(chattUser) {
			ChatterAuditTestEnvironment.initPostWithComments(ChatterAuditTestEnvironment.chattUser.Id,2,5);
  		}
		//set scenario for search request
		Apexpages.currentPage().getParameters().put('scenario','s1');
		Apexpages.currentPage().getParameters().put('s1opt1','true');
		Apexpages.currentPage().getParameters().put('userId1',chattUser.Id);
		ChatterAuditSearchController ctr = new ChatterAuditSearchController();
		ctr.runSearch();

		system.assertEquals(12,ctr.getItems().size());

		Test.stopTest();

		List<ArchivedEntityFeed__c> lArchEntitiesInitial = [	Select  a.Id
											From ArchivedEntityFeed__c a
											where 		a.entityId__c =: ChatterAuditTestEnvironment.chattUser.Id
													and a.isDeleted__c = false limit 9999 ];
		Id entityId = lArchEntitiesInitial.get(0).Id;
		//check that Archived FeedItems are also related to the entity created for the account
		List<ArchivedFeedItem__c> lArchItemsInitial = [	Select  a.Id
											From ArchivedFeedItem__c a
											where 		a.ParentId__c =: ChatterAuditTestEnvironment.chattUser.Id
													and a.ArchivedEntityFeed__c =: entityId
													and a.isDeleted__c = false limit 9999 ];
		//asserts
		system.assertEquals(1,lArchEntitiesInitial.size());
		system.assertEquals(2,lArchItemsInitial.size());
    }


	/* 	Search By UserId  on Post/Comments

		opt1 : Person Created the Post/comment (default on)

		in this test method we will:
			0) set up environment with : entity objects, custom setting
			1) create user 	chattUser
			2) make this user add post and a comment with author chattUser
			3) update chattUser's name
			4) add a post and a comment with author chattUser
			5) run a search to obtain all posts	& Comments
			6) update search criteria to get posts created tomorrow ( will return zero)
	*/


	static testMethod void test_searchByAuthor() {
    	PageReference pageRef = Page.ChatterAuditSearch;
        Test.setCurrentPage(pageRef);
  		Test.startTest();
  		//set up environment
  		ChatterAuditTestEnvironment.generateConfig();
  		ChatterAuditTestEnvironment.initParentObjects();

  		//step 1 - create a user
  		User chattUser = ChatterAuditTestEnvironment.getGenerateUser('Test User','Chatter Free User');

  		//step 2 - create a post whose AuthorName is the initial name of ChatterAuditTestEnvironment.chattUser
  		System.runAs(chattUser) {
			ChatterAuditTestEnvironment.initPostWithComments(ChatterAuditTestEnvironment.chattUser.Id,1,1);
		}

		//step 3 - update usersName
		chattUser.FirstName ='NOW UPDATED';
		update chattUser;

  		//step 4 - create another post whose AuthorName is the new name of chattUser
  		System.runAs(chattUser) {
			ChatterAuditTestEnvironment.initPostWithComments(ChatterAuditTestEnvironment.chattUser.Id,1,1);
		}

		//step 5 -  prepare search options
		//set scenario for search request
		String nowStr = Datetime.now().formatGmt('yyyy-MM-dd');
		Apexpages.currentPage().getParameters().put('startD',nowStr);
		Apexpages.currentPage().getParameters().put('endD',nowStr);
		Apexpages.currentPage().getParameters().put('scenario','s1');
		Apexpages.currentPage().getParameters().put('s1opt1','true');
		Apexpages.currentPage().getParameters().put('userId1',chattUser.Id);

		ChatterAuditSearchController ctr = new ChatterAuditSearchController();
		ctr.runSearch();
		Test.stopTest();

		system.assertEquals(4,ctr.getItems().size());

		//step 6 - update search criteria to get posts created 4 days after now ( will return zero)
		nowStr = (Datetime.now().addDays(4)).format('yyyy-MM-dd HH:mm').replace(' ','_');
		Apexpages.currentPage().getParameters().put('startD',nowStr);
		Apexpages.currentPage().getParameters().put('endD',nowStr);
		ctr.runSearch();
		system.assertEquals(0,ctr.getItems().size());

    }

   	/* 	Search By UserId  on Post/Comments

		opt1 : Person Created the Post/comment (default on)

		in this test method we will:
			0) set up environment with : entity objects, custom setting
			1) create user 	chattUser
			2) make this user add post and a comment with author chattUser
			3) update chattUser's name
			4) add a post and a comment with author chattUser
			5) run a search to obtain all posts	& Comments
			6) update search criteria to get posts created tomorrow ( will return zero)
	*/


	static testMethod void test_searchByAuthor_AND_keyword() {
    	PageReference pageRef = Page.ChatterAuditSearch;
        Test.setCurrentPage(pageRef);
  		Test.startTest();
  		//set up environment
  		ChatterAuditTestEnvironment.generateConfig();

  		String needle = 'EVIL WORD YEAH'+ChatterAuditTestEnvironment.getRandomString();

  		//step 1 - create a user
  		User chattUser = ChatterAuditTestEnvironment.getGenerateUser('Test User','Standard User');

  		//step 2 - create a post whose AuthorName is the initial name of ChatterAuditTestEnvironment.chattUser
  		System.runAs(chattUser) {

  			ChatterAuditTestEnvironment.initParentObjects();

			FeedItem fi = new FeedItem(Body = needle, ParentId = ChatterAuditTestEnvironment.chattUser.Id );
			insert fi;
			//step2 -
			FeedComment cOne = new FeedComment();
	    	cOne.CommentBody = needle + 'the said';
	    	cOne.FeedItemId = fi.Id;
			insert cOne;
		}
		Test.stopTest();

		List<ArchivedFeedItem__c> lA = [SELECT  a.Id
														FROM ArchivedFeedItem__c a
														WHERE 		a.ParentId__c =: ChatterAuditTestEnvironment.chattUser.Id
																AND a.isParentDeleted__c = 'false'
																AND a.isDeleted__c = false limit 9999 ] ;
		Id[] l = new Id[1];
		l.add(lA.get(0).Id);
    	Test.setFixedSearchResults(l);


		//step 5 -  prepare search options
		//set scenario for search request
		String nowStr = Datetime.now().formatGmt('yyyy-MM-dd');
		Apexpages.currentPage().getParameters().put('startD',nowStr);
		Apexpages.currentPage().getParameters().put('endD',nowStr);
		Apexpages.currentPage().getParameters().put('itemBody',needle);
		Apexpages.currentPage().getParameters().put('scenario','s1');
		Apexpages.currentPage().getParameters().put('s1opt1','true');
		Apexpages.currentPage().getParameters().put('userId1',chattUser.Id);

		ChatterAuditSearchController ctr = new ChatterAuditSearchController();
		ctr.runSearch();


		system.assertEquals(1,ctr.getItems().size());
    }

    /**
    	Search By UserId  on Post/Comments

		opt2 :  Posts to person's wall by others

		in this test method we will:
			0) set up environment with : entity objects, custom setting
			1) create users 	chattUser and chattUser2
			2) make this chattUser2  add posts and comments to  chattUser's wall
			3) make the current user add posts and comments to  chattUser's wall
			4) run a search to obtain all posts	& Comments
			5) update search criteria to get posts created tomorrow ( will return zero)

	*/
	static testMethod void test_searchWallPosts() {
		//set up environment
     	PageReference pageRef = Page.ChatterAuditSearch;
        Test.setCurrentPage(pageRef);
  		ChatterAuditTestEnvironment.generateConfig();
  		ChatterAuditTestEnvironment.initParentObjects();

  		//step 1 - create users
  		User chattUser = ChatterAuditTestEnvironment.getGenerateUser('Test User','Chatter Free User');
  		User chattUser2 = ChatterAuditTestEnvironment.getGenerateUser('Test2 User2','Chatter Free User');

		//step 2 - make this chattUser2  add posts and a comments to  chattUser's wall
  		System.runAs(chattUser2) {
			//create a post whose Author is  chattUser
			ChatterAuditTestEnvironment.initPostWithComments(chattUser.Id,1,1);
		}

		//step 3 : make the current user add posts and a comments to  chattUser's wall
		ChatterAuditTestEnvironment.initPostWithComments(chattUser.Id,1,1);

		Test.startTest();
		//step 4 - run a search to obtain all posts	& Comments
		//set scenario for search request
		String nowStr = Datetime.now().formatGmt('yyyy-MM-dd');
		Apexpages.currentPage().getParameters().put('startD',nowStr);
		Apexpages.currentPage().getParameters().put('endD',nowStr);
		Apexpages.currentPage().getParameters().put('scenario','s1');
		Apexpages.currentPage().getParameters().put('s1opt2','true');
		Apexpages.currentPage().getParameters().put('userId1',chattUser.Id);
		ChatterAuditSearchController ctr = new ChatterAuditSearchController();

		ctr.runSearch();

		Test.stopTest();
		system.assertEquals(4,ctr.getItems().size());

		//step 5 - update search criteria to get posts created 4 days after today ( will return zero)
		nowStr = (Datetime.now().addDays(4)).format('yyyy-MM-dd HH:mm').replace(' ','_');
		Apexpages.currentPage().getParameters().put('startD',nowStr);
		Apexpages.currentPage().getParameters().put('endD',nowStr);
		ctr.runSearch();
		system.assertEquals(0,ctr.getItems().size());

    }

    
   /**
    	Search By UserId  on Post/Comments

		opt4 : Posts and Comments on profiles of people person is following

		in this test method we will:
			0) set up environment with : entity objects, custom setting
			1) create users chattUser(userId1) , chattUser2 and  chattUser3
			2) make chattUser3 add post and comments
			3) make chattUser2 add post and comments
			4) run a search to obtain all posts	& Comments >> should be 0
			5) make chattUser follow chattUser2	and chattUser3
			6) run a search to obtain all posts	& Comments
			7) make chattUser not to follow chattUser2
			8) run a search to obtain all posts	& Comments
			9) update search criteria to get posts created tomorrow ( will return zero)
	*/


	static testMethod void test_searchUserFollowingPosts() {
		//set up environment
      	PageReference pageRef = Page.ChatterAuditSearch;
        Test.setCurrentPage(pageRef);
  		ChatterAuditTestEnvironment.generateConfig();
  		ChatterAuditTestEnvironment.initParentObjects();
  		Test.startTest();
  		//step 1 - create users chattUser(userId1) , chattUser2 and  chattUser3
  		User chattUser = ChatterAuditTestEnvironment.getGenerateUser('Test User','Chatter Free User');
  		User chattUser2 = ChatterAuditTestEnvironment.getGenerateUser('Test2 User2','Chatter Free User');
  		User chattUser3 = ChatterAuditTestEnvironment.getGenerateUser('Test3 User3','Chatter Free User');

		//step 2 - make chattUser add post and comments
  		System.runAs(chattUser3) {
			ChatterAuditTestEnvironment.initPostWithComments(chattUser.Id,5,10); 	//user3 : autor of 55 post/commenst
		}
		//step 3 - make chattUser2 add post and comments
  		System.runAs(chattUser2) {
			ChatterAuditTestEnvironment.initPostWithComments(chattUser.Id,3,2);		//user2 : autor of 9 post/commenst
		}

		//step 4 - run a search to obtain all posts	& Comments  >> 0 expected
		//set scenario for search request
		String nowStr = Datetime.now().formatGmt('yyyy-MM-dd');
		Apexpages.currentPage().getParameters().put('startD',nowStr);
		Apexpages.currentPage().getParameters().put('endD',nowStr);
		Apexpages.currentPage().getParameters().put('scenario','s1');
		Apexpages.currentPage().getParameters().put('s1opt4','true');
		Apexpages.currentPage().getParameters().put('userId1',chattUser.Id);
		ChatterAuditSearchController ctr = new ChatterAuditSearchController();
		ctr.runSearch();
		system.assertEquals(0,ctr.getItems().size());


		//step 5 - make chattUser follow chattUser2	and chattUser3
		List<EntitySubscription> e = new List<EntitySubscription> ();
		e.add(new EntitySubscription (ParentId = chattUser2.Id ,subscriberid = chattUser.Id) );
		e.add(new EntitySubscription (ParentId = chattUser3.Id ,subscriberid = chattUser.Id) );
		insert e;
		Test.stopTest();

		//step 6 - run a search to obtain all posts	& Comments
		ctr.runSearch();
		system.assertEquals(64,ctr.getItems().size());

		//step 7 - make chattUser not to follow chattUser2
		delete [select Id from EntitySubscription where subscriberid =: chattUser.Id  and ParentId =: chattUser3.Id];

		//step 8 - run a search to obtain all posts	& Comments
		ctr.runSearch();
		system.assertEquals(9,ctr.getItems().size());

		//step 9 - update search criteria to get posts created 4 days after now ( will return zero)
		nowStr = (Datetime.now().addDays(4)).format('yyyy-MM-dd HH:mm').replace(' ','_');
		Apexpages.currentPage().getParameters().put('startD',nowStr);
		Apexpages.currentPage().getParameters().put('endD',nowStr);
		ctr.runSearch();
		system.assertEquals(0,ctr.getItems().size());

    }


   	static testMethod void test_searchByTwoAuthors() {
    	PageReference pageRef = Page.ChatterAuditSearch;
        Test.setCurrentPage(pageRef);
  		Test.startTest();
  		//set up environment
  		ChatterAuditTestEnvironment.generateConfig();
  		ChatterAuditTestEnvironment.initParentObjects();

  		//step 1 - create a two users
  		User chattUser = ChatterAuditTestEnvironment.getGenerateUser('Test User','Chatter Free User');
		User chattUser2 = ChatterAuditTestEnvironment.getGenerateUser('Test User2','Chatter Free User');

		//step 5 -  prepare search options
		//set scenario for search request
		String nowStr = Datetime.now().formatGmt('yyyy-MM-dd');
		Apexpages.currentPage().getParameters().put('startD',nowStr);
		Apexpages.currentPage().getParameters().put('endD',nowStr);
		Apexpages.currentPage().getParameters().put('scenario','s2');
		Apexpages.currentPage().getParameters().put('s2opt1','true');
		Apexpages.currentPage().getParameters().put('userId1',chattUser.Id);
		Apexpages.currentPage().getParameters().put('userId2',chattUser2.Id);

		ChatterAuditSearchController ctr = new ChatterAuditSearchController();
		ctr.runSearch();
		ctr.sortField = 'AuthorName';
		Test.stopTest();
		system.assertEquals(0,ctr.getItems().size());
    }



}