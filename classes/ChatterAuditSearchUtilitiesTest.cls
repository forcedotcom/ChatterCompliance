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
private class ChatterAuditSearchUtilitiesTest {

    static testMethod void conversation_test() {
    	
    	PageReference pageRef = Page.ChatterAuditSearch;
        Test.setCurrentPage(pageRef);
        Test.startTest();

        ChatterAuditTestEnvironment.generateConfig();
  		ChatterAuditTestEnvironment.initParentObjects();
  		//First User
  		User actorAUser = ChatterAuditTestEnvironment.getGenerateUser('User A','Chatter Free User');
  		//Second User
  		User actorBUser = ChatterAuditTestEnvironment.getGenerateUser('User B','Chatter Free User');

  		//set scenario for search request
  		ChatterAuditSearchController.searchParamsGlobal = new Map<String,String>();
		ChatterAuditSearchController.searchParamsGlobal.put('scenario','s2');
		ChatterAuditSearchController.searchParamsGlobal.put('userId1',actorAUser.Id);
		ChatterAuditSearchController.searchParamsGlobal.put('userId2',actorBUser.Id);

  		//Creating post for z User
  		FeedItem fi;

  		FeedItem fiZ= new FeedItem(Body = 'Post by Z', ParentId = ChatterAuditTestEnvironment.chattUser.Id);
  		insert fiZ;

  		FeedComment fC;
  		FeedItem fiActorA;
  		FeedItem fiActorB;

  		//create posts/comments
  		System.runAs(actorAUser) {

  			//Creating a post
  			fiActorA = new FeedItem(Body = 'Post by A', ParentId = ChatterAuditTestEnvironment.chattUser.Id);
  			insert fiActorA;

  			//Posting in B's Wall
  			fi = new FeedItem(Body = 'Post in B\'s wall', ParentId = actorBUser.Id);
			insert fi;

			//Commenting in B's Wall
			fC = new FeedComment(CommentBody = 'Comment in B\'s wall', FeedItemId =fi.Id, CreatedDate = Datetime.now() );
			insert fC;

			//Commenting in Z's Wall
			fC = new FeedComment(CommentBody = 'Im A user in Z\'s post', FeedItemId =fiZ.Id, CreatedDate = Datetime.now() );
			insert fC;
  		}

  		System.runAs(actorBUser) {

			//Posting in A's Wall
  			fi = new FeedItem(Body = 'Post in As wall', ParentId = actorAUser.Id);
			insert fi;

			//Commenting in A's Wall
			fC = new FeedComment(CommentBody = 'Comment in A\'s wall', FeedItemId =fi.Id, CreatedDate = Datetime.now() );
  			insert fC;

  			//Commenting in A's Post
			fC = new FeedComment(CommentBody = 'Comment in A\'s post', FeedItemId =fiActorA.Id, CreatedDate = Datetime.now() );
  			insert fC;

  			//Commenting in Z's Wall
			fC = new FeedComment(CommentBody = 'Im B user in Zs post', FeedItemId =fiZ.Id, CreatedDate = Datetime.now() );
			insert fC;
  		}

  		Set<Id> usersIds = new Set<Id>();
  		usersIds.add(actorAUser.Id);
  		usersIds.add(actorBUser.Id);

		map<Id,ArchivedFeedComment__c> elmFC = new map<Id,ArchivedFeedComment__c>([Select aF.Id from ArchivedFeedComment__c aF where aF.Created_By__c in :usersIds]);
		map<Id,ArchivedFeedItem__c> elmFI = new map<Id,ArchivedFeedItem__c>([Select aF.Id from ArchivedFeedItem__c aF where aF.Created_By__c in :usersIds]);

		Set<Id> totalIds = new Set<Id>();
		totalIds.addAll( elmFC.keySet() );
		totalIds.addAll( elmFI.keySet() );

		Id[] idsArray = new Id[totalIds.size()];

		for ( Id i : totalIds ){
			idsArray.add(i);
		}

    	Test.setFixedSearchResults( idsArray );

  		/* 2 Users Scenario
	  	 * s2opt1 : Posts made by person 1 on person 2's profile and vice versa (default on)
	  	 */
  		ChatterAuditSearchController.searchParamsGlobal.put('s2opt1','true');
  		List<ChatterAuditSearchController.SearchItem> l = ChatterAuditSearchUtilities.runSearch();
  		system.assertEquals(2, l.size());

  		ChatterAuditSearchController.searchParamsGlobal.put('itemBody','Post in As wall');
  		l = ChatterAuditSearchUtilities.runSearch();
  		system.assertEquals(1, l.size());



		/* 2 Users Scenario
		 * s2opt2 :  Posts where person 1 and person 2 have interacted
		 */
		ChatterAuditSearchController.searchParamsGlobal.put('itemBody','');
  		ChatterAuditSearchController.searchParamsGlobal.put('s2opt1','');
  		ChatterAuditSearchController.searchParamsGlobal.put('s2opt2','true');
  		l = ChatterAuditSearchUtilities.runSearch();
  		system.assertEquals(3, l.size());

  		String nowStr = Datetime.now().formatGmt('yyyy-MM-dd');

  		ChatterAuditSearchController.searchParamsGlobal.put('itemBody','');
  		ChatterAuditSearchController.searchParamsGlobal.put('startD','2000-01-01');
		ChatterAuditSearchController.searchParamsGlobal.put('endD',nowStr);
  		ChatterAuditSearchController.searchParamsGlobal.put('s2opt2','true');
  		l = ChatterAuditSearchUtilities.runSearch();
 
  		system.assertEquals(3, l.size());

  		ChatterAuditSearchController.searchParamsGlobal.put('itemBody','Im B user in Zs post');
  		ChatterAuditSearchController.searchParamsGlobal.put('startD','');
		ChatterAuditSearchController.searchParamsGlobal.put('endD','');

  		l = ChatterAuditSearchUtilities.runSearch();
  		system.assertEquals(1, l.size());

		test.stopTest();
    }
}