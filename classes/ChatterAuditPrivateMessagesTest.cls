/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class ChatterAuditPrivateMessagesTest {
	
	/*
	 * Only covering lines, as SF doesn't allow Create in ChatterMessage object
	 */
    static testMethod void batchTest() {
        test.startTest();
        
        ChatterAuditSettings__c cnf = new ChatterAuditSettings__c();
			cnf.name							= ChatterAuditConstants.CUSTOM_SETTING_NAME;
			cnf.ChatterAuditOwnerId__c			= Userinfo.getUserId();
			cnf.ChatterAuditUpdateFequency__c	= 12;
			cnf.Active__c						= false;
			cnf.ContentVersionDeleteBlocker__c  = true;
			cnf.ArchivedPMessagesUpdateFreq__c 	= 12; 
						
		upsert cnf;
        
        System.schedule('TEST JOB NAME', '0 0 0/'+Integer.valueOf(cnf.ArchivedPMessagesUpdateFreq__c)+' * * ?', new ChatterAuditPrivateMessagesSch());
        
        ChatterAuditPrivateMessagesBatch dummyBatch = new ChatterAuditPrivateMessagesBatch( Datetime.now() , false);
        dummyBatch.getQuery();
        
        boolean exThrown = false;
        
        try{
	        ChatterMessage chtMsg = new ChatterMessage();
	        list<ChatterMessage> l = new list<ChatterMessage>(); l.add(chtMsg);
	        dummyBatch.archiveMessages(l);
        }catch(Exception e){
        	exThrown = true;
        }
        
        System.assertEquals( exThrown, true );
        
        test.stopTest();
        
    }
}