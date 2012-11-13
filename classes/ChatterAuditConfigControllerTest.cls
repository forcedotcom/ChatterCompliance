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
private class ChatterAuditConfigControllerTest {

    static testMethod void test_ChatterAuditConfigController() {
        // test : public ChatterAuditConfigController()
        ChatterAuditTestEnvironment.generateConfig();
        test.startTest();
        ChatterAuditConfigController ctr = new ChatterAuditConfigController();
        test.stopTest();

        String result = String.valueOf(ctr.settings.ChatterAuditUpdateFequency__c);
		List<String> tmp = result.split('.0');
		result = tmp.get(0);

        system.assertEquals(result,										ChatterAuditSettingsHandler.getChatterUpdateFequency());
        system.assertEquals(ctr.settings.name,							ChatterAuditConstants.CUSTOM_SETTING_NAME);
        system.assertEquals(ctr.settings.ChatterAuditOwnerId__c,		ChatterAuditSettingsHandler.getChatterLogsOwnerId());
        system.assertEquals(ctr.settings.Active__c,						ChatterAuditSettingsHandler.getIsBatchExecuting());
    }

 	static testMethod void test_getBatchStatus() {
        // test :Boolean getBatchStatus()
        ChatterAuditTestEnvironment.generateConfig();
        test.startTest();
		ChatterAuditConfigController ctr = new ChatterAuditConfigController();
		Boolean res = ctr.getBatchStatus();
        test.stopTest();
        system.assertEquals(res,ChatterAuditSettingsHandler.getIsBatchExecuting());
    }

 	static testMethod void test_launchBatch() {
        // test : PageReference launchBatch()
        ChatterAuditTestEnvironment.generateConfig();
        Boolean initialStatus = ChatterAuditSettingsHandler.getIsBatchExecuting();
        test.startTest();
        ChatterAuditConfigController ctr = new ChatterAuditConfigController();
        ctr.settings.Active__c = true;
        PageReference p = ctr.launchBatch();
        test.stopTest();
         ctr.checkSetting();
		system.assertEquals(ChatterAuditSettingsHandler.getIsBatchExecuting(),		!initialStatus);
       
    }

	static testMethod void test_updateSettings() {
        // test : PageReference updateSettings()
        ChatterAuditTestEnvironment.generateConfig();
        Boolean initialStatus = ChatterAuditSettingsHandler.getIsBatchExecuting();
        test.startTest();
        ChatterAuditConfigController ctr = new ChatterAuditConfigController();
        ctr.settings.Active__c = true;
        PageReference p = ctr.updateSettings();
        test.stopTest();
		system.assertEquals(ChatterAuditSettingsHandler.getIsBatchExecuting(),		!initialStatus);
       
    }

    static testMethod void test_WrongSettings() {
        //ChatterAuditTestEnvironment.generateConfig();
        //Lets delete all settings
        Boolean initialStatus = ChatterAuditSettingsHandler.getIsBatchExecuting();
        test.startTest();
        delete [Select Id FROM ChatterAuditSettings__c];
        ChatterAuditConfigController ctr = new ChatterAuditConfigController();
        test.stopTest();
		//As we do not set up properly the custom setting , error should be setted up to true
		system.assertEquals( ctr.getIsError(), true );
    }



}