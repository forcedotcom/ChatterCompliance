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
private class ChatterAuditProxyControllerTest {

    static testMethod void getResult_getChatterAuditData() {
        // TO DO: implement unit test
        Apexpages.currentPage().getParameters().put('a','search');
        ChatterAuditProxyController ctr = new ChatterAuditProxyController();
        ctr.JSONResponse();
        system.assertNotEquals('',ctr.getResult());
    }
  
    //
    static testMethod void getResult_exportFullResult() {
        // TO DO: implement unit test
        Apexpages.currentPage().getParameters().put('a',ChatterAuditConstants.csvUIFull);
        ChatterAuditProxyController ctr = new ChatterAuditProxyController();
		ctr.JSONResponse();
        system.assertNotEquals('',ctr.getResult());
    }

	static testMethod void getResult_exportQuickResult() {
        // TO DO: implement unit test
        Apexpages.currentPage().getParameters().put('a',ChatterAuditConstants.csvUIQuick);
        ChatterAuditProxyController ctr = new ChatterAuditProxyController();
		ctr.JSONResponse();
        system.assertNotEquals('',ctr.getResult());
    }
    
	static testMethod void getResult_displayRecords4Purge() {
        Apexpages.currentPage().getParameters().put('a','getPurgeList');
        ChatterAuditProxyController ctr = new ChatterAuditProxyController();
		ctr.JSONResponse();
        system.assertNotEquals('',ctr.getResult());
        
        String nowStr = Datetime.now().formatGmt('yyyy-MM-dd');
        Apexpages.currentPage().getParameters().put('startDate',nowStr);
    	Apexpages.currentPage().getParameters().put('endDate',nowStr);
		ctr.JSONResponse();
		system.assertNotEquals('',ctr.getResult());
        
    }

	static testMethod void getResult_purgeRecords() {
        // TO DO: implement unit test
        Apexpages.currentPage().getParameters().put('a','purgeRecords');
        ChatterAuditProxyController ctr = new ChatterAuditProxyController();
		ctr.JSONResponse();
        system.assertNotEquals('',ctr.getResult());
        
        String nowStr = Datetime.now().formatGmt('yyyy-MM-dd');
        Apexpages.currentPage().getParameters().put('startDate',nowStr);
    	Apexpages.currentPage().getParameters().put('endDate',nowStr);
		ctr.JSONResponse();
		system.assertNotEquals('',ctr.getResult());
    }

	static testMethod void getResult_getLookUpItemsList() {
        // TO DO: implement unit test
        Apexpages.currentPage().getParameters().put('a','lookUp');
        Apexpages.currentPage().getParameters().put('type','1');
        ChatterAuditProxyController ctr = new ChatterAuditProxyController();
		ctr.JSONResponse();
        system.assertNotEquals('',ctr.getResult());

        Apexpages.currentPage().getParameters().put('type','2');
		ctr.JSONResponse();
        system.assertNotEquals('',ctr.getResult());
        
        Apexpages.currentPage().getParameters().put('type','3');
		ctr.JSONResponse();
        system.assertNotEquals('',ctr.getResult());
    }
       
    
}