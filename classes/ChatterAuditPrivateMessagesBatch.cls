global class ChatterAuditPrivateMessagesBatch implements Database.Batchable<SObject>, Database.Stateful{	
	
	private ChatterAuditSettings__c cSetting;
	private Datetime dateFilter;
	private boolean reschedule;
	
	/**
	 * Batch Constructor
	 * @param d -- Datetime with the date to use as filter in query (can be null, which equals get all p.messages)
	 * @param reschedule -- True if this batch should be rescheduled
	 **/
	 global ChatterAuditPrivateMessagesBatch( Datetime d, boolean reschedule ){
	 	this.cSetting = ChatterAuditSettings__c.getValues(ChatterAuditConstants.CUSTOM_SETTING_NAME);
	 	this.dateFilter = d;
	 	this.reschedule = reschedule;
	 }
	 
	 global ChatterAuditPrivateMessagesBatch( Datetime d ){
	 	this.cSetting = ChatterAuditSettings__c.getValues(ChatterAuditConstants.CUSTOM_SETTING_NAME);
	 	this.dateFilter = d;
	 	this.reschedule = false;
	 }  
	 
	 
	/**
	 * Batch Start Method
	 *
	 * @param ctx
	 * @return				String with query
 	 */
    global Database.queryLocator start(Database.BatchableContext ctx){
        return Database.getQueryLocator( this.getQuery() );
    }
    
    /**
	 * Batch execute Method
	 *
	 * @param ctx
	 * @param data		List of Sobject
 	 */
    global void execute(Database.BatchableContext ctx, List<Sobject> results){
       this.archiveMessages(results);
    }
    
    /**
	 * Batch Finish Method
	 *
	 * @param ctx
 	 */
    global void finish(Database.BatchableContext ctx){
    	if ( this.reschedule ){
    		 ChatterAuditUtils.privateMessagesScheduler();
    		 System.abortJob( this.cSetting.ArchivedPMessagesJobId__c );
    	}
    }
	
	/**
	 * Archiving private messages in custom object ArchivedChatterMessage
	 * @param results -- list<Sobject>
	 **/
	public void archiveMessages(List<Sobject> results){
		list<ArchivedChatterMessage__c> elms = new list<ArchivedChatterMessage__c>();
		for ( sObject obj : results ){
			ChatterMessage aux = (ChatterMessage) obj;
			ArchivedChatterMessage__c elm = new ArchivedChatterMessage__c();
			elm.Body__c = aux.Body;
			elm.ConversationId__c = aux.ConversationId;
			elm.CreatedById__c = aux.CreatedById;
			elm.SenderId__c = aux.SenderId;
			elm.SentDate__c = aux.SentDate;
			elm.ChatterMessageId__c = aux.Id; 
			elms.add(elm);
		}
		upsert elms;
	}
	
	/**
	 * Returns query for ChatterMessages
	 * @return String
	 **/
	public String getQuery(){
		String theDateFormated = (this.dateFilter != null) ? (this.dateFilter.formatGmt('yyyy-MM-dd HH:mm:ss')).replace(' ','T')+'.000Z' : '';
		String add = (this.dateFilter != null) ? 'where c.SentDate > '+theDateFormated : '';
		return 'Select c.SentDate, c.SenderId, c.Id, c.CreatedById, c.ConversationId, c.Body From ChatterMessage c '+add;
	} 
	
}