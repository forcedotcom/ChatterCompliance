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
private class ChatterAuditBatchLoaderTest { 

	static private Integer max_posts = 10;
	static private Integer max_comments = 5;
	
    static testMethod void test_ChatterAuditBatchLoader() {
       	// TO DO: implement unit test
       	ChatterAuditTestEnvironment.generateConfig();
       	
       	ChatterAuditBatchLoader bl = new ChatterAuditBatchLoader();
       	ChatterAuditBatchLoaderUtils utils = new ChatterAuditBatchLoaderUtils();
        
       	User userAccount = ChatterAuditTestEnvironment.getGenerateUser('User A','Chatter Free User'); 
       	
       	ChatterAuditTestEnvironment.initPostWithComments(userAccount.Id,max_posts,max_comments);
       	
       	Datetime dt = System.now();
       
       	String query = utils.getSelectQuery();
		ChatterAuditTestEnvironment.isTest = true;
		Test.startTest();
		ID batchId = Database.executeBatch(bl, 200);
		Test.stopTest();
		
		AsyncApexJob a = [Select Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email from AsyncApexJob where Id = :batchId];
		System.AssertEquals('Completed', a.status);
		System.AssertEquals(0, a.NumberOfErrors);
		
				
		List<FeedItem> fi = [Select  a.Id, a.CreatedDate
								From FeedItem a
								where a.ParentId =: userAccount.id
								limit 9999 ];
		
		List<ArchivedFeedItem__c> lArchItems = [	Select  a.Id
											From ArchivedFeedItem__c a
											where  a.ArchivedEntityFeed__c =: userAccount.id limit 9999 ];
       	
       	for(ArchivedFeedItem__c afi: lArchItems)
       	{
       		System.assertEquals(afi.ArchivedEntityFeed__c, userAccount.id);
       		
       	}
		
    }

 static testMethod void test_getBatchNextExecutionTime() {
       	// TO DO: implement unit test
       	ChatterAuditTestEnvironment.generateConfig();
       

		ChatterAuditTestEnvironment.isTest = true;
		Test.startTest();
		String str = ChatterAuditBatchLoaderUtils.getBatchNextExecutionTime();
		Test.stopTest();
		
		System.AssertNotEquals(str, '' );

		
    }

  static testMethod void test_ChatterAuditBatchLoaderOneItem() {
       	// TO DO: implement unit test
       	ChatterAuditTestEnvironment.generateConfig();       	
  		ChatterAuditTestEnvironment.initParentObjects();
       	User actorAUser = ChatterAuditTestEnvironment.getGenerateUser('User A','Chatter Free User');
       	User actorBUser = ChatterAuditTestEnvironment.getGenerateUser('User B','Chatter Free User');      	      
       	
       	System.runAs(actorAUser) {
	       	//create one text post
	       	list<FeedItem> lFitem = new list<FeedItem>();
	       	ChatterAuditTestEnvironment.initPostWithComments(actorBUser.Id,1,max_comments);
	       	//create one link post
	       	lFitem.add( new FeedItem(Body = 'Hello World', ParentId = actorBUser.Id,LinkUrl='http://www.foo.foo'));
	
			//create ContentPost
			FeedItem fi = new FeedItem(Body = 'Hello World', ParentId =actorBUser.Id);
	  		fi.ContentData 			= Blob.valueOf('BIG FILE');
	  		fi.ContentDescription 	= 'a test file';
	  		fi.ContentFileName		= 'fooFile.txt';
			lFitem.add( fi);		
			
			upsert lFitem;
			
	       	//user Post
	       	User user = [select id, CurrentStatus from User where id =: actorAUser.Id];
			user.CurrentStatus = 'my new status message';
			update user;
	       	
       	}
       	
       	List<ArchivedFeedItem__c> lArchItemsInitial = [	Select  a.Id
														From ArchivedFeedItem__c a											
											 			limit 9999 ];	

		ChatterAuditUtils.setDeleteAllowedForPosts(true);
		delete lArchItemsInitial;
		
		list<Id> lentities = new list<Id>{actorAUser.Id,actorBUser.Id};
      	ChatterAuditTestEnvironment.isTest = true;														
		Test.startTest();
		ID batchId = Database.executeBatch(new ChatterAuditBatchLoader(), 200);
		Test.stopTest();
		
		AsyncApexJob a = [Select Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email from AsyncApexJob where Id = :batchId];
		System.AssertEquals('Completed', a.status);
		System.AssertEquals(0, a.NumberOfErrors);
						
		
		Map<Id,Id> entMaps= new Map<Id,Id>();
		for(ArchivedEntityFeed__c aE : [	Select  a.Id, a.isDeleted__c, a.entityId__c
											From ArchivedEntityFeed__c a
											where a.entityId__c in: lentities ]){
														
						entMaps.put(aE.entityId__c,aE.Id);								
		}
		Map<String,ArchivedFeedItem__c> archivedItems= new Map<String,ArchivedFeedItem__c>();
		for ( ArchivedFeedItem__c afi : [	Select  a.Id, a.FeedItemId__c, a.Type__c , a.Title__c , a.LinkUrl__c , a.ContentType__c ,a.ArchivedEntityFeed__c,  a.ContentSize__c , a.ContentDescription__c , a.ContentFileName__c ,  a.Body__c , a.Created_By__c , a.CreatedDate__c , a.ParentId__c , a.RelatedRecordId__c , a.Inserted_By__c  
											From ArchivedFeedItem__c a
											where  a.ParentId__c in: lentities  ]){
											
				archivedItems.put(afi.FeedItemId__c,afi);							
		}
		//go over feeItems and check that every post made is been loaded
		FeedItem fItm = null;
		for (FeedItem fi : [Select  Id, Type, Title, LinkUrl, ContentType, ContentSize, ContentDescription, ContentFileName, CommentCount, Body, CreatedById, CreatedDate, ParentId, RelatedRecordId, InsertedById 
								From FeedItem 
								where InsertedById in: lentities ]){
		
			//check parentId field
			if (archivedItems.containsKey(fi.Id)){
				
				System.assertEquals(fi.ParentId, archivedItems.get(fi.Id).ParentId__c);	
			
				System.assertEquals(fi.Id, 				archivedItems.get(fi.Id).FeedItemId__c);
				System.assertEquals(fi.Type, 			archivedItems.get(fi.Id).Type__c);
		       	System.assertEquals(fi.Title, 			archivedItems.get(fi.Id).Title__c);
		       	System.assertEquals(fi.LinkUrl, 		archivedItems.get(fi.Id).LinkUrl__c);
		       	System.assertEquals(fi.ContentType, 	archivedItems.get(fi.Id).ContentType__c);
		       	if (fi.Type =='ContentPost'){
		       		System.assertEquals(fi.ContentSize, 		archivedItems.get(fi.Id).ContentSize__c);
		       	}else{
		       		System.assertEquals(fi.ContentSize, 		0);
		       	}
		       	
		       	System.assertEquals(fi.ContentDescription, archivedItems.get(fi.Id).ContentDescription__c);
		       	System.assertEquals(fi.ContentFileName, 	archivedItems.get(fi.Id).ContentFileName__c);
		       	System.assertEquals(fi.Body, 				archivedItems.get(fi.Id).Body__c);
		       	System.assertEquals(fi.CreatedById, 		archivedItems.get(fi.Id).Created_By__c);
		       	System.assertEquals(fi.CreatedDate, 		archivedItems.get(fi.Id).CreatedDate__c);
		       	System.assertEquals(fi.ParentId, 			archivedItems.get(fi.Id).ParentId__c);
		       	System.assertEquals(fi.RelatedRecordId, 	archivedItems.get(fi.Id).RelatedRecordId__c);
		       	System.assertEquals(fi.InsertedById, 		archivedItems.get(fi.Id).Inserted_By__c);
		       	
		       	System.assertEquals(archivedItems.get(fi.Id).ArchivedEntityFeed__c, entMaps.get(fi.ParentId));				
			}
										
		}
		

   		
          	
      
    }

}