/*
Copyright (c) 2011, salesforce.com, Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, 
are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, 
    this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, 
    this list of conditions and the following disclaimer in the documentation 
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
public with sharing class ChatterAuditConfigController {
	public ChatterAuditSettings__c settings {get; set;}
	private boolean isError;
	private Boolean initialbatchStatus;
	
	
	public ChatterAuditConfigController(){ 
		this.isError            = false;
		this.settings 			= ChatterAuditSettings__c.getValues(ChatterAuditConstants.CUSTOM_SETTING_NAME);
		checkCustomSetting();//checking custom settings		
		this.initialbatchStatus = ChatterAuditSettingsHandler.getIsBatchExecuting();
	}

	public Pagereference checkSetting(){	
		ChatterAuditUtils.checkCustomSetting();
		return null;
	}

	/**
	 * Get batch Status
	 *
	 * @return					Boolean , batch is/is not executing
 	 */
	public Boolean getBatchStatus(){
		return ChatterAuditSettingsHandler.getIsBatchExecuting();
	}

	/**
	 * launchBatch
	 *
	 * @return					Pagereference null
 	 */
	public PageReference launchBatch(){
		this.settings.Active__c = true;
		if ( !this.initialbatchStatus ){
			String nextFireTime = ChatterAuditUtils.getBatchNextExecutionTime();
			ChatterAuditBatchUpdateSch s = new ChatterAuditBatchUpdateSch();
    		System.schedule('ChatterAudit UpdateJob ReStarted At ' + String.valueOf(Datetime.now()), nextFireTime, s);
		}
		upsert this.settings;
		return null;
	}

	/**
	 * updateSettings
	 * control if we have to stop/start batch proccess
	 * case 1 - batch is not running already and we have to launch it
	 *
	 * @return					Pagereference chatterAuditConfig
 	 */
	public PageReference updateSettings(){
		if ( !this.initialbatchStatus && this.settings.Active__c){
			String nextFireTime = ChatterAuditUtils.getBatchNextExecutionTime();
			ChatterAuditBatchUpdateSch s = new ChatterAuditBatchUpdateSch();
    		System.schedule('ChatterAudit UpdateJob ReStarted At ' + String.valueOf(Datetime.now()), nextFireTime, s);
		}
		upsert this.settings;
		return Page.ChatterAuditConfig;
	}

	/**
	 * get Is Error
	 *
	 * @return					boolean
 	 */
	public boolean getIsError(){
		return this.isError;
	}

	/**
	 * checkCustomSetting
 	 */
	private void checkCustomSetting(){
		if( this.settings == null || this.settings.ChatterAuditUpdateFequency__c == null
					|| this.settings.ChatterAuditOwnerId__c == null
					|| this.settings.ArchivedPMessagesUpdateFreq__c == null){
			try{
				throw new ChatterAuditException('Custom settings are not properly configurated.');
			}catch (ChatterAuditException e){
				//Create error message and set error bool var
				ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, e.getMessage());
    			Apexpages.addMessage(myMsg);
    			isError = true;
			}
		}else{
			isError = false;
		}		
	}
	
	/*
	*@author Timba
	*@description - Reset custom setting value lastExecutionDate
	*
	*@return void
	*/
	public void resetLastExecution(){
		if ( this.settings == null ) return;
		this.settings.ArchivedPMessagesUpdateLastExecution__c = null;
		upsert this.settings;		
	}
	
	public void startStopBatch(){
		if ( this.settings == null ) return;
		String opt	= Apexpages.currentPage().getParameters().get('startORstop');
		if ( opt == 'Start' ){
			launchBatch();
		}else if ( opt == 'Stop' ){
			this.settings.Active__c = false;
			upsert this.settings;
		}
	}
	
	/*
	*@author Timba
	*@description - Apply Changes in custom setting
	*
	*@param - prevChatterDataLoaded (by CurrentPage.getParameters)
	*@param - contentBlocker (by CurrentPage.getParameters)
	*@param - pmFreq (by CurrentPage.getParameters)	
	*@return void
	*/
	public void doChanges(){
		if ( this.settings == null ) return;
		this.settings.PreviousChatterDataLoaded__c 		= Boolean.valueOf(Apexpages.currentPage().getParameters().get('prevChatterDataLoaded'));
		this.settings.ContentVersionDeleteBlocker__c 	= Boolean.valueOf(Apexpages.currentPage().getParameters().get('contentBlocker'));
		this.settings.ArchivedPMessagesUpdateFreq__c 	= Integer.valueOf(Apexpages.currentPage().getParameters().get('pmFreq'));
		this.settings.ChatterAuditUpdateFequency__c		= Integer.valueOf(Apexpages.currentPage().getParameters().get('batchFreq'));
		upsert this.settings;
	}
	
	public String getownerId(){
		if ( this.settings == null ) return 'Custom settings are not properly configured.';
		list<User> u = [Select u.Username From User u where u.Id = :this.settings.ChatterAuditOwnerId__c];
		return u.size() > 0 ? u[0].Username : 'Custom settings are not properly configured.';
	}
	
	public String getprevChatterDataLoaded(){
		if ( this.settings == null ) return 'false';
		return this.settings.PreviousChatterDataLoaded__c ? 'true' : 'false';
	}
	
	public String getcontentBlocker(){
		if ( this.settings == null ) return 'false';
		return this.settings.ContentVersionDeleteBlocker__c ? 'true' : 'false';
	}
	
	public String getbatchIsActive(){
		if ( this.settings == null ) return 'false';
		return this.getBatchStatus() ? 'true' : 'false';
	}
	
	public String getpmFreq(){
		if ( this.settings == null ) return '0';
		return String.valueOf(this.settings.ArchivedPMessagesUpdateFreq__c);
	}
	
	public String getbatchFreq(){
		if ( this.settings == null ) return '0';
		return String.valueOf(this.settings.ChatterAuditUpdateFequency__c);
	}	
}