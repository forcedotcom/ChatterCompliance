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
private class ChatterAuditSettingsHandlerTest {

    static testMethod void test_getChatterLogsOwnerId() {
        // test : public static string getChatterLogsOwnerId()
        ChatterAuditTestEnvironment.generateConfig();
        test.startTest();
        String ownId = ChatterAuditSettingsHandler.getChatterLogsOwnerId();
        test.stopTest();
        system.assertEquals(ChatterAuditTestEnvironment.AppConfig.ChatterAuditOwnerId__c, ownId);
    }

    static testMethod void test_getChatterUpdateFequency() {
        // test : public static String getChatterUpdateFequency()
		ChatterAuditTestEnvironment.generateConfig();
        test.startTest();
        String freq = ChatterAuditSettingsHandler.getChatterUpdateFequency();
        
        String result = String.valueOf(ChatterAuditTestEnvironment.AppConfig.ChatterAuditUpdateFequency__c);
		List<String> tmp = result.split('.0');
		result = tmp.get(0);
        
        test.stopTest();
        system.assertEquals(result, freq);
    }

    static testMethod void test_getIsBatchExecuting() {
        // test : public static Boolean getIsBatchExecuting()
		ChatterAuditTestEnvironment.generateConfig();
        test.startTest();
        Boolean isExec = ChatterAuditSettingsHandler.getIsBatchExecuting();
        test.stopTest();
        system.assertEquals(ChatterAuditTestEnvironment.AppConfig.Active__c, isExec);

    }   
    
    
    static testMethod void test_getNewCustomSetting() {
        
        ChatterAuditSettings__c apC = ChatterAuditSettings__c.getValues(ChatterAuditConstants.CUSTOM_SETTING_NAME);
		//if (apC != null) {
			//delete apC;
		//}
        
		ChatterAuditTestEnvironment.generateConfig();
        test.startTest();
        String oId = ChatterAuditSettingsHandler.getChatterLogsOwnerId();
        test.stopTest();
        system.assertEquals(ChatterAuditTestEnvironment.AppConfig.ChatterAuditOwnerId__c, oId);

    }

    
    static testMethod void test_getExportForlderId() {
        // test : public static String getExportForlderId()
       
        
		ChatterAuditTestEnvironment.generateConfig();
        test.startTest();
        String idInitial = ChatterAuditSettingsHandler.getExportForlderId();
               
        test.stopTest();
        system.assertNotEquals(idInitial,null);

    }
}