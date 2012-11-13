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
private class ChatterAuditBatchUpdateTest {

    static testMethod void test_ChatterAuditBatchUpdate() {
        // TO DO: implement unit test
        ChatterAuditTestEnvironment.generateConfig();
        ChatterAuditBatchUpdate bc = new ChatterAuditBatchUpdate();
		//create a group
		
		List<User> cGrp = new List<User>();
		cGrp.add(ChatterAuditTestEnvironment.getGenerateUser('User A','Chatter Free User'));
		cGrp.add(ChatterAuditTestEnvironment.getGenerateUser('User B','Chatter Free User'));
		
		
		Id grpId = cGrp.get(0).Id;
		ChatterAuditTestEnvironment.initPostListForObject(10,grpId);
		
		ArchivedEntityFeed__c groupStatus0 = [	Select  a.Id, a.isDeleted__c
														From ArchivedEntityFeed__c a
														where a.entityId__c =: grpId
														limit 1 ];		
		Id entityRecordId = groupStatus0.Id;														
		//all Archived post related to the group should have isParentDeleted = false
		List<ArchivedFeedItem__c> lArchItemsInitial = [	Select  a.Id
											From ArchivedFeedItem__c a
											where 		a.ParentId__c =: grpId
													and a.ArchivedEntityFeed__c =: entityRecordId 
													and a.isParentDeleted__c = 'false'
													and a.isDeleted__c = false limit 9999 ];	
		
		ChatterAuditTestEnvironment.initPostListForObject(10,cGrp.get(1).Id);		
		
		 ArchivedEntityFeed__c  groupStatus1 = [	Select  a.Id, a.isDeleted__c
														From ArchivedEntityFeed__c a
														where a.entityId__c =: grpId
														limit 1 ];
		
		Test.startTest();
		ID batchID = Database.executeBatch(bc, 200);
		Test.stopTest();
		
		AsyncApexJob a = [Select Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email from AsyncApexJob where Id = :batchId];
		System.AssertEquals('Completed', a.status);
		System.AssertEquals(0, a.NumberOfErrors);
		//check that the corresponding entity is updated as deleted
		ArchivedEntityFeed__c  groupStatus2 = [	Select  a.Id, a.isDeleted__c
														From ArchivedEntityFeed__c a
														where a.entityId__c =: grpId
														limit 1 ];
        System.assert(!groupStatus0.isDeleted__c);//initially the entity has isDeleted__c= false
        System.assert(!groupStatus1.isDeleted__c);// after deleting the Group initially the entity has isDeleted__c= false
        System.assert(!groupStatus2.isDeleted__c);//after running the batch process the entity should be updated
        
        // all Archived post related to the group should have isParentDeleted = true
   		List<ArchivedFeedItem__c> lArchItemsFinal = [	Select  a.Id
										From ArchivedFeedItem__c a
										where 		a.ParentId__c =: grpId
												and a.ArchivedEntityFeed__c =: entityRecordId 
												and a.isParentDeleted__c = 'false'
												and a.isDeleted__c = false limit 9999 ]; 
       System.AssertEquals(10,lArchItemsInitial.size());
       System.AssertEquals(10,lArchItemsFinal.size()); 
    }
}