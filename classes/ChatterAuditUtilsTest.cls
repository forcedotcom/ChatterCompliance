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
private class ChatterAuditUtilsTest {

	static testMethod void test_allowDeleteForItems() {
        //unit test for allowDelete = false;
        //									public static Boolean getIsDeleteAllowedForPosts()
        //									public static void setDeleteAllowedForPosts(Boolean v)
        
  		ChatterAuditTestEnvironment.generateConfig();
  		Test.startTest();
        Boolean original = ChatterAuditUtils.getIsDeleteAllowedForPosts();
        ChatterAuditUtils.setDeleteAllowedForPosts(!original);
        Test.stopTest();
        system.assertEquals(original,!ChatterAuditUtils.getIsDeleteAllowedForPosts());
        
	}  
		
	static testMethod void test_validFeedObject() {
        //unit test for public static Boolean validFeedObject(String testName);
        
        system.assertEquals(true,ChatterAuditUtils.validFeedObject('AccountFeed'));
        system.assertEquals(false,ChatterAuditUtils.validFeedObject('AccountATFeed'));
        
	} 

     static testMethod void test_isValidString() {
        //unit test for public static Boolean isValidString(String testName);
        
        system.assertEquals(true,ChatterAuditUtils.isValidString('valid'));
        system.assertEquals(false,ChatterAuditUtils.isValidString('null'));
        system.assertEquals(false,ChatterAuditUtils.isValidString(''));
		system.assertEquals(false,ChatterAuditUtils.isValidString(null));        
	}

     static testMethod void test_isValidDate() {
        //unit test for public static Boolean isValidDate(String testName);
        
        system.assertEquals(true,ChatterAuditUtils.isValidDate('2011-01-01_18:35'));
        system.assertEquals(false,ChatterAuditUtils.isValidDate('yyyy-mm-dd'));
        system.assertEquals(false,ChatterAuditUtils.isValidDate('2011-31-01'));
        system.assertEquals(false,ChatterAuditUtils.isValidDate('2011-01-32'));
        system.assertEquals(false,ChatterAuditUtils.isValidDate('OTHER THING'));
        system.assertEquals(false,ChatterAuditUtils.isValidDate(''));
		system.assertEquals(false,ChatterAuditUtils.isValidDate(null));        
	}
	
     static testMethod void test_isValidNumber() {
        //unit test for public static boolean isValidNumber(String testStr)
        
        system.assertEquals(true,ChatterAuditUtils.isValidNumber('23'));
        system.assertEquals(false,ChatterAuditUtils.isValidNumber('a'));
        system.assertEquals(false,ChatterAuditUtils.isValidNumber('a23'));      
	}	
     static testMethod void test_mailException() {
	//public static void mailException(String errorMsg,String methodName)
	     Test.startTest();
	     ChatterAuditUtils.mailBenchmark('TEST THIS');
	     ChatterAuditUtils.mailException('TEST THIS','idem');
	     Boolean res  = ChatterAuditUtils.mailPurgeCompleted(ChatterAuditConstants.dummyId);
	     Test.stopTest();
	     system.assert(res);
     }	
	
	static testMethod void test_ChatterAuditException() {

        
  		ChatterAuditTestEnvironment.generateConfig();
  		Test.startTest();
		String res = '';
		try{
			ChatterAuditTestEnvironment.riseException();
		}catch( ChatterAuditException e ){
			res =e.getMessage();			
		}       
        Test.stopTest();
       system.assertEquals('TEST ERROR HANDLER',res);
        
	}



}