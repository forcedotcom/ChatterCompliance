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
private class ChatterAuditEntityFeedsTest {

	// Test methods for Account Feeds *********************************************************************************************** //
	static private Integer max_posts = 10;
	static private Integer max_comments = 5;
	static testMethod void test_createAccountPostAndComments() {
		Test.startTest();
  		//create the account
  		ChatterAuditTestEnvironment.generateConfig();
  		ChatterAuditTestEnvironment.initParentObjects();
  		User uOne = ChatterAuditTestEnvironment.getGenerateUser('User A','Chatter Free User'); 
		ChatterAuditTestEnvironment.initPostWithComments(uOne.Id,max_posts,max_comments);
		//query initial collection of non deleted feedItems associated with the Account
		Test.stopTest();

		List<ArchivedEntityFeed__c> lArchEntitiesInitial = [	Select  a.Id
											From ArchivedEntityFeed__c a
											where 		a.entityId__c =: uOne.Id
													and a.isDeleted__c = false limit 9999 ];
		Id entityId = lArchEntitiesInitial.get(0).Id;
		//check that Archived FeedItems are also related to the entity created for the account
		List<ArchivedFeedItem__c> lArchItemsInitial = [	Select  a.Id
											From ArchivedFeedItem__c a
											where 		a.ParentId__c =: uOne.Id
													and a.ArchivedEntityFeed__c =: entityId
													and a.isDeleted__c = false limit 9999 ];
		//query initial collection of non deleted feedComments associated with the feedItem
		list<ArchivedFeedComment__c> lCommentARch  = [Select e.Id , e.IsDeleted__c, e.ArchivedFeedItem__c
								  						 FROM  ArchivedFeedComment__c e
								  						 WHERE e.ParentId__c =: uOne.Id
								  						 AND   e.isDeleted__c = false limit 9999 ];
		//check that ArchivedFeedComments are being related to ArchivedFeedItems
		Map<Id,Integer> totals = new Map<Id,Integer>();
		Integer tmp;
		for(ArchivedFeedComment__c aC : lCommentARch ){
			if (totals.containsKey(aC.ArchivedFeedItem__c)){
				tmp = totals.get(aC.ArchivedFeedItem__c);
				tmp ++;
				totals.put(aC.ArchivedFeedItem__c,tmp);
			}else{
				totals.put(aC.ArchivedFeedItem__c,1);
			}
		}
		Boolean okTotals = true;
		for(Integer i : totals.values() ){
			if (i != max_comments ){
				okTotals = false;
			}
		}

		//asserts
		system.assertEquals(1,lArchEntitiesInitial.size());
		system.assertEquals(max_posts,lArchItemsInitial.size());
		system.assertEquals(max_posts*max_comments,lCommentARch.size());
		system.assert(okTotals);
	}


	

	// Test methods for User Feeds *********************************************************************************************** //
	@isTest(SeeAllData=true)
	static  void test_createUserPostAndComments() {

		Test.startTest();
  		//create the User
  		ChatterAuditTestEnvironment.generateConfig();
  		ChatterAuditTestEnvironment.initParentObjects();
		//create a UserStatus post by changing it's current status text
		User chattUser = ChatterAuditTestEnvironment.getGenerateUser('Test User','Chatter Free User');
		System.runAs(chattUser) {
			chattUser.CurrentStatus = 'hello world!';
			update chattUser;
		 }
		//query initial collection of non deleted feedItems associated with the User
		Test.stopTest();

		List<ArchivedEntityFeed__c> lArchEntitiesInitial = [	Select  a.Id
											From ArchivedEntityFeed__c a
											where 		a.entityId__c =: chattUser.Id
													and a.isDeleted__c = false limit 9999 ];
		List<ArchivedFeedItem__c> lArchItemsInitial = [	Select  a.Id , a.FeedItemId__c
											From ArchivedFeedItem__c a
											where 		a.ParentId__c =: chattUser.Id
													and a.isDeleted__c = false limit 9999 ];
		//query initial collection of non deleted feedComments associated with the feedItem
		ChatterAuditTestEnvironment.initCommentListForPost(max_posts,lArchItemsInitial.get(0).FeedItemId__c);
		list<ArchivedFeedComment__c> lCommentARch  = [Select e.Id , e.IsDeleted__c
								  						 FROM  ArchivedFeedComment__c e
								  						 WHERE e.ParentId__c =: chattUser.Id
								  						 AND   e.isDeleted__c = false limit 9999 ];

		//asserts
		system.assertEquals(1,lArchEntitiesInitial.size());
		system.assertEquals(1,lArchItemsInitial.size());
		system.assertEquals(max_posts,lCommentARch.size());
	}

	static testMethod void test_createUserPostAndClearStatus() {

		Test.startTest();
  		//create the User
  		ChatterAuditTestEnvironment.generateConfig();
  		ChatterAuditTestEnvironment.initParentObjects();
		//create a UserStatus post by changing it's current status text
		User chattUser = ChatterAuditTestEnvironment.getGenerateUser('Test User','Chatter Free User');
		System.runAs(chattUser) {
			chattUser.CurrentStatus = null;
			update chattUser;
		}
		Test.stopTest();

		List<ArchivedEntityFeed__c> lArchEntitiesInitial = [	Select  a.Id
											From ArchivedEntityFeed__c a
											where 		a.entityId__c =: chattUser.Id
													and a.isDeleted__c = false limit 9999 ];
		List<ArchivedFeedItem__c> lArchItemsInitial = [	Select  a.Id , a.FeedItemId__c
											From ArchivedFeedItem__c a
											where 		a.ParentId__c =: chattUser.Id
													and a.isDeleted__c = false limit 9999 ];


		//asserts
		system.assertEquals(0,lArchEntitiesInitial.size());//no entity was created  when users clears his status
		system.assertEquals(0,lArchItemsInitial.size());//no Archived post was created when users clears his status
	}
}