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
private class ChatterAuditBatchUpdateSchTest {

    static testMethod void test_ChatterAuditBatchUpdateSch() {
        // TO DO: implement unit test
		ChatterAuditTestEnvironment.generateConfig();   
		//create a group			
		ChatterAuditSettings__c c = ChatterAuditSettings__c.getValues(ChatterAuditConstants.CUSTOM_SETTING_NAME);
		c.Active__c = true;
		upsert c; 
			
		Test.startTest();	

		//we will lounch process again only            
        ChatterAuditBatchUpdateSch s = new ChatterAuditBatchUpdateSch();
        //get form the custom setting when does the next job has to run
        String nextFireTime = ChatterAuditUtils.getBatchNextExecutionTime();
        Datetime nextFireDtTime = ChatterAuditUtils.getBatchNextExecutionDtTime();
	    String jobId = System.schedule('TEST ChatterAudit UpdateJob Started At ' + String.valueOf(Datetime.now()), nextFireTime, s);

		Test.stopTest();
		CronTrigger ct = [	SELECT id, CronExpression, TimesTriggered,NextFireTime
         					FROM CronTrigger WHERE id = :jobId];
         					
		//asserts will be made over cron job not over the batch execution
		// Verify the expressions are the same      
		System.assertEquals(nextFireTime,  ct.CronExpression);
		// Verify the job has not run  
		System.assertEquals(0, ct.TimesTriggered);
		// Verify the next time the job will run  	 	
		System.assertEquals(String.valueOf(nextFireDtTime), String.valueOf(ct.NextFireTime));	
	
 
       
    }
}