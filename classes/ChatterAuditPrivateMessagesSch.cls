global class ChatterAuditPrivateMessagesSch implements Schedulable{
	
	/*
	 * Updating custom setting with job id and last executed time and call batch process
	 */
	global void execute(SchedulableContext sc) {
		ChatterAuditSettings__c cnf = ChatterAuditSettings__c.getValues(ChatterAuditConstants.CUSTOM_SETTING_NAME);
		Datetime dateToSend = cnf.ArchivedPMessagesUpdateLastExecution__c;
		cnf.ArchivedPMessagesUpdateLastExecution__c = Datetime.now();
		cnf.ArchivedPMessagesJobId__c = sc.getTriggerId();		
		upsert cnf;
		database.executebatch(  new ChatterAuditPrivateMessagesBatch(dateToSend,true) );		
   	} 
	
}