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
private class ChatterAuditFeedItemTest {


	//test : 
	//	when ever a FeedItem of type textpost is inserted 
	//	the corresponding ArchivedFeedItem is inserted as well
  	static testMethod void test_TextPost() {

  		ChatterAuditTestEnvironment.generateConfig();
  		ChatterAuditTestEnvironment.initParentObjects();
  		Test.startTest();
  		FeedItem fi = new FeedItem(Body = 'Hello World', ParentId =ChatterAuditTestEnvironment.chattUser.Id);
		insert fi;
		Test.stopTest();
		//check if there's an ArchivedFeedItem  for the inserted FeedItem
		List<ArchivedFeedItem__c> lArch = [Select a.FeedItemId__c, a.isDeleted__c,a.Id,a.Type__c,
									a.ParentObjectType__c, a.ParentId__c , a.Body__c
										From ArchivedFeedItem__c a where a.ParentId__c =: ChatterAuditTestEnvironment.chattUser.Id];

		//asserts to check that the archived item contains the original FeedItem values
		system.assertEquals('TextPost',lArch.get(0).Type__c);
		system.assertEquals('User',lArch.get(0).ParentObjectType__c);
		system.assertEquals('Hello World',lArch.get(0).Body__c);
		system.assertEquals(false,lArch.get(0).isDeleted__c);
	}

	static testMethod void test_deleteTextPost() {

  		ChatterAuditTestEnvironment.generateConfig();
  		ChatterAuditTestEnvironment.initParentObjects();

  		Test.startTest();
  		FeedItem fi = new FeedItem(Body = 'Hello World', ParentId =ChatterAuditTestEnvironment.chattUser.Id);
		insert fi;
		//delete
		delete fi;
		Test.stopTest();
		//check if there's an ArchivedFeedItem  for the inserted FeedItem
		List<ArchivedFeedItem__c> lArch = [Select a.FeedItemId__c,a.Id,a.Type__c, a.ParentObjectType__c,
											a.ParentId__c , a.Body__c, a.isDeleted__c
										From ArchivedFeedItem__c a where a.ParentId__c =: ChatterAuditTestEnvironment.chattUser.Id];

		//asserts
		system.assertEquals('TextPost',lArch.get(0).Type__c);
		system.assertEquals('User',lArch.get(0).ParentObjectType__c);
		system.assertEquals('Hello World',lArch.get(0).Body__c);
		system.assertEquals(true,lArch.get(0).isDeleted__c);
	}


   static testMethod void test_testContentPost() {

  		ChatterAuditTestEnvironment.generateConfig();
  		ChatterAuditTestEnvironment.initParentObjects();

  		Test.startTest();
  		FeedItem fi = new FeedItem(Body = 'Hello World', ParentId =ChatterAuditTestEnvironment.chattUser.Id);
  		fi.ContentData 			= Blob.valueOf('BIG FILE');
  		fi.ContentDescription 	= 'a test file';
  		fi.ContentFileName		= 'fooFile.txt';
		insert fi;
		Test.stopTest();
		
		//check if there's an Account Feed for the corresponding AccountFeed
		List<ArchivedFeedItem__c> lArch = [Select a.FeedItemId__c,a.Id,a.Type__c, a.ParentObjectType__c,
											a.ParentId__c , a.Body__c, a.ContentFileName__c
										From ArchivedFeedItem__c a where a.ParentId__c =: ChatterAuditTestEnvironment.chattUser.Id];

		system.assertEquals('ContentPost',lArch.get(0).Type__c);
		system.assertEquals('User',lArch.get(0).ParentObjectType__c);
		system.assertEquals('Hello World',lArch.get(0).Body__c);
		system.assertEquals('fooFile.txt',lArch.get(0).ContentFileName__c);

  }

	static testMethod void test_UserPost() {

  		ChatterAuditTestEnvironment.generateConfig();
  		Test.startTest();
	  	User user = [select id, CurrentStatus from User where id =: UserInfo.getUserId()];
		user.CurrentStatus = 'my new status message';
		update user;		
		Test.stopTest();
		
		//check if there's an ArchivedFeedItem  for the inserted FeedItem
		List<ArchivedFeedItem__c> lArch = [Select a.FeedItemId__c, a.isDeleted__c,a.Id,a.Type__c,
									a.ParentObjectType__c, a.ParentId__c , a.Body__c , a.LinkUrl__c
										From ArchivedFeedItem__c a where a.ParentId__c =: Userinfo.getUserId() ORDER BY CreatedDate DESC LIMIT 1	];


		system.assertEquals('UserStatus',lArch.get(0).Type__c);
		system.assertEquals('User',lArch.get(0).ParentObjectType__c);
		system.assertEquals('my new status message',lArch.get(0).Body__c);
		system.assertEquals(false,lArch.get(0).isDeleted__c);
  }

	static testMethod void test_LinkPost() {

  		ChatterAuditTestEnvironment.generateConfig();
  		ChatterAuditTestEnvironment.initParentObjects();

  		Test.startTest();
  		FeedItem fi = new FeedItem(Body = 'Hello World', ParentId = Userinfo.getUserId(),LinkUrl='http://www.foo.foo');
		insert fi;
		Test.stopTest();
		
		//check if there's an Account Feed for the corresponding AccountFeed
		List<ArchivedFeedItem__c> lArch = [Select a.FeedItemId__c, a.isDeleted__c,a.Id,a.Type__c,
									a.ParentObjectType__c, a.ParentId__c , a.Body__c , a.LinkUrl__c
										From ArchivedFeedItem__c a where a.ParentId__c =: Userinfo.getUserId()
											and a.FeedItemId__c =:fi.Id ];


		system.assertEquals('LinkPost',lArch.get(0).Type__c);
		system.assertEquals('User',lArch.get(0).ParentObjectType__c);
		system.assertEquals('Hello World',lArch.get(0).Body__c);
		system.assertEquals(false,lArch.get(0).isDeleted__c);
  }

}