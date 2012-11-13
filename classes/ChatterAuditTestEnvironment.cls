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
/*
This class will generate the test environment used for test methods
*/
public with sharing class ChatterAuditTestEnvironment {
//Boolean Flag to determine if execution environment corresponds to a TestEnvironment.
	public static boolean isTest = false;

	//Application Configuration
	public static ChatterAuditSettings__c AppConfig;


	public static FeedItem fItem= new FeedItem();
	public static List<FeedItem> fItemsList= new List<FeedItem>();
	public static User chattUser;
	

	public static void generateConfig() {

		
			AppConfig = ChatterAuditSettings__c.getValues(ChatterAuditConstants.CUSTOM_SETTING_NAME);
			if (AppConfig == null) {
				AppConfig = new ChatterAuditSettings__c();
			}
		
			AppConfig.name 							= ChatterAuditConstants.CUSTOM_SETTING_NAME;
			AppConfig.ChatterAuditOwnerId__c		= Userinfo.getUserId();//ChatterAuditUtils.getAdmin().Id;
			AppConfig.ChatterAuditUpdateFequency__c	= 12;
			AppConfig.Active__c						= false;
			
			upsert AppConfig;
		
	}


	public static void initParentObjects(){
			chattUser = ChatterAuditTestEnvironment.getGenerateUser('User A','Chatter Free User'); 
	}

	public static String getRandomString(){

		String rnd = String.valueOf(Math.floor(( Math.random() * 1000)));
	    String randomName = string.valueof(Datetime.now()).replace('-','').replace(':','').replace(' ','');

		return randomName+rnd;
	}

	public static void initPostWithComments(ID parentId, Integer cantPosts, Integer cantComments ){

		List<FeedItem> lIt = new List<FeedItem>();
		List<FeedItem> lTotal = new List<FeedItem>();
		String postBody = 'Hello World';
		//'Starting with the Winter ’12 release, Apex includes native support for JavaScript Object Notation (JSON). Using Apex JSON classes, your Apex code can now parse JSON content and serialize Apex objects into the JSON format. The addition of native JSON support provides many benefits for Apex development, including efficient processing of JSON for HTML5 apps.'; 
		//'The Liberty Head nickel was an American five-cent piece. It was struck for circulation from 1883 until 1912, with at least five pieces being surreptitiously struck dated 1913. The original copper–nickel five-cent piece, the Shield nickel, had longstanding production problems, and in the early 1880s, the United States Mint was looking to replace it. Mint Chief Engraver Charles Barber was instructed to prepare designs for proposed one-, three-, and five-cent pieces, which were to bear similar designs. Only the new five-cent piece was approved, and went into production in 1883. For almost thirty years large quantities of coin of this design were produced to meet commercial demand, especially as coin-operated machines became increasingly popular. Beginning in 1911, the Mint began work to replace the Liberty head design, and a new design, which became known as the Buffalo nickel, went into production in February 1913.';
		String commentBody = 'Comment Hello World';
		//'For this third developer challenge, build a demo app that leverages Apex JSON and then write an article that explains its source code. The winning entry receives a US$1000 gift card and gets their work published on Developer Force.';
		//'Although no 1913 Liberty head nickels were officially struck, five are known to exist. While it is uncertain how these pieces originated, they have come to be among the most expensive coins in the world, with one selling in 2010 for $3,737,500.';
		for( Integer i=0; i<cantPosts; i++ ){
  			lIt.add(new FeedItem(Body = postBody, ParentId = parentId));
			if ( i == (cantPosts-1) || lIt.size() >= 9999 ){
  				upsert lIt;
				lTotal.addAll(lIt);
  				lIt = new List<FeedItem>();
  			}
  		}

  		List<FeedComment> lItC = new List<FeedComment>();
  		for(FeedItem f : lTotal){
  			for( integer i=0; i<cantComments; i++ ){
  				lItC.add(new FeedComment(CommentBody = commentBody, FeedItemId =f.Id, CreatedDate = Datetime.now() ));
			}
  		}
  		List<FeedComment> lUpsert = new List<FeedComment>();
  		for(FeedComment f : lItC){
  			lUpsert.add(f);
  			if (lUpsert.size()== 999 || lUpsert.size()== lItC.size()){
  				upsert lUpsert;
  				lUpsert = new List<FeedComment>();
  			}
  		}
  		if (!lUpsert.isEmpty()){
  				upsert lUpsert;
  		}
	}

	public static void initPostListForObject(Integer cant,ID parentID){

		List<FeedItem> lIt = new List<FeedItem>();
  		for( integer i=0; i<cant; i++ )
  			lIt.add(new FeedItem(Body = 'Hello World', ParentId =parentID));
		upsert lIt;

	}

	public static void initCommentListForPost(Integer cant,ID feedPostID){

		List<FeedComment> lIt = new List<FeedComment>();
  		for( integer i=0; i<cant; i++ ){
  			lIt.add(new FeedComment(CommentBody = 'Comment Hello World', FeedItemId =feedPostID, CreatedDate = Datetime.now() ));
		}
		upsert lIt;
	}

	
	public static User getGenerateUser(String lName,String pName){
		
		Profile p = [select id from profile   where Name =: pName limit 1];
		String rnd = String.valueOf(Math.floor(( Math.random() * 1000)));
	    String randomName = string.valueof(Datetime.now()).replace('-','').replace(':','').replace(' ','');

        User aUser = new User(alias = 'std'+rnd, email='standarduser'+rnd+'@testorg.com',
        FirstName='CHAUDIT '+lName,  UserName=randomName+rnd+'@testorg.com', lastname='CHAUDIT',
            emailencodingkey='UTF-8', timezonesidkey='America/Los_Angeles', CurrentStatus ='some sort of status',
            languagelocalekey='en_US', localesidkey='en_US', profileid = p.Id);


		insert aUser;
	
		return aUser;
	
	}
	
	public static Id generateContentVersionFile(){
		ContentVersion cont = new ContentVersion();
		
		cont.Title = 'Title for this contentVersion';
		cont.PathOnClient = 'file_'+Datetime.now().getTime()+'.txt';
		cont.versionData = Blob.valueOf('My Content in file_'+Datetime.now().getTime()+'.txt');
		cont.Origin = 'H';
		
		upsert cont;
		return cont.Id;
	}
	
	public static Id generatePostWithRelatedDocument(Id contentVersionId){		
		FeedItem elm = new FeedItem(Body = 'Post with related document body', ParentId = ChatterAuditUtils.getAdmin().Id , RelatedRecordId = contentVersionId, Type = 'ContentPost');
		upsert elm;	
		return elm.Id;	
	}
	
	public static void generateCommentWithRelatedDocument(Id parent, Id contentVersionId){
		FeedComment elm = new FeedComment(CommentBody = 'Comment!!!', FeedItemId =parent, CreatedDate = Datetime.now(), RelatedRecordId = contentVersionId);
		upsert elm;
	}
	
	public static void riseException(){
		throw new ChatterAuditException('TEST ERROR HANDLER');
	}
	
}