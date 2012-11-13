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
public with sharing class ChatterAuditSettingsHandler {

	/**
	  * get chatter logs owner Id
	  *
	  * @return String			String with chatter logs owner Id
	  */
	public static string getChatterLogsOwnerId() {
		String result = '';
		ChatterAuditSettings__c c = ChatterAuditSettings__c.getValues(ChatterAuditConstants.CUSTOM_SETTING_NAME);
		if (c != null) {
			result = c.ChatterAuditOwnerId__c;
		}
		return result;
	}
 
	/**
	  * get chatter update frequency
	  *
	  * @return String			String with chatter update frequency
	  */
	public static String getChatterUpdateFequency(){
	String result = '';
		ChatterAuditSettings__c c = ChatterAuditSettings__c.getValues(ChatterAuditConstants.CUSTOM_SETTING_NAME);
		if (c != null) {
			result = String.valueOf(c.ChatterAuditUpdateFequency__c);
			List<String> tmp = result.split('.0');
			result = tmp.get(0);
		}
		return result;
	}
	
	/**
	  * get chatter pm update frequency
	  *
	  * @return String			String with chatter update frequency
	  */
	public static String getPmChatterUpdateFequency(){
	String result = '';
		ChatterAuditSettings__c c = ChatterAuditSettings__c.getValues(ChatterAuditConstants.CUSTOM_SETTING_NAME);
		if (c != null) {
			result = String.valueOf(c.ArchivedPMessagesUpdateFreq__c);
			List<String> tmp = result.split('.0');
			result = tmp.get(0);
		}
		return result;
	}

	/**
	  * get is batch executing
	  *
	  * @return Boolean			Boolean batch is or not executing
	  */
	public static Boolean getIsBatchExecuting(){
		Boolean result = false;
		ChatterAuditSettings__c c = ChatterAuditSettings__c.getValues(ChatterAuditConstants.CUSTOM_SETTING_NAME);
		if (c != null) {
			result = c.Active__c;
		}
		return result;
	}

	/**
	  * get export folder Id
	  *
	  * @return String			String with export folder Id
	  */
	public static String getExportForlderId(){
		String fId = null;
		List<folder> destinationFolder = [select id
									from folder
									where Name =: ChatterAuditConstants.EXPORT_FOLDER_NAME
									limit 1];
		if (!destinationFolder.isEmpty()){
			fId = destinationFolder.get(0).Id;
		}
		return fId;
	}
	
	
	/*
	 * Returns if preloading batch is running or not
	 *
	 * @return boolean
	 */
	public static boolean isPreloadingActive(){
		
		String className = ChatterAuditConstants.BATCH_LOADER_CLASS_NAME; 
		 
		Map<Id,ApexClass> batchClasses = new Map<Id,ApexClass>([Select a.Name, a.Id From ApexClass a where a.Name = :className limit 1]); 
		
		list<AsyncApexJob> apexJobs = [ Select a.Id 
										from AsyncApexJob a 
										where a.Status != 'Completed'
										AND a.Status != 'Failed'
										AND a.Status != 'Aborted'
										AND a.ApexClassId IN :batchClasses.keySet() 
										limit 1];		
		return apexJobs.size() > 0;
	} 
}