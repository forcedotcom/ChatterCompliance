public with sharing class ChatterAuditProxyController {



	public string action;
	public string result = '';
	
	public ChatterAuditProxyController() {	
		action = ApexPages.currentPage().getParameters().get('a');		
	}

	public string getResult() {return this.result;}

	public void JSONResponse() {
		
		if (action != null && action != ''){
	
			//search on post&comments
			if (action =='search')
				this.result = getChatterAuditData();  	
			
			//export full archived list
			if (action ==ChatterAuditConstants.csvUIFull)
				this.result = exportFullResult();
				
			//export quick view	  
			if (action ==ChatterAuditConstants.csvUIQuick)
				this.result = exportQuickResult();	
	
			//purge result list	  
			if (action =='getPurgeList')
				this.result = displayRecords4Purge();	
	
			//purge records
			if (action == 'purgeRecords')
				this.result = purgeRecords();
				
				
			//fetch lookUp 
			if (action =='lookUp')
				getLookUpItemsList();	
			
		}else{
	
			this.result = JSON.serialize(new responseWrapper( 'INVALID JSON OPERATION',false));
	
		}
	}


	public String getChatterAuditData(){		
		if (Apexpages.currentPage().getParameters().get('scenario')== null){
			Apexpages.currentPage().getParameters().put('scenario','s0');
		}		
		ChatterAuditSearchController ctr = new ChatterAuditSearchController();
		ctr.runSearch();
		list<ChatterAuditSearchController.SearchItem> l2 = ctr.getItems ();
		return  JSON.serialize(ctr.getResponse());		
	}
	
	
	public String exportFullResult (){
		
		responseWrapper res = new responseWrapper();
		
		res.success = true;
 		//check if we get Id set
		if (Apexpages.currentPage().getParameters().get('idSet') != null){
			try{		
				String tmpIds = Apexpages.currentPage().getParameters().get('idSet') ;
				set<id> exportIDs = new set<id>();
				List<Id> ltmp =tmpIds.split(',');
				exportIDs.addAll(ltmp); 
				ChatterAuditExportUtilities.exportFull(ChatterAuditConstants.csvUIFull,exportIDs);
				res.msg = Label.ChatterAudit_searchExportedText ;	
				if (exportIDs.size() >= ChatterAuditConstants.MAXIMUM_LIST_RESULTS){
					res.msg +=  Label.ChatterAudit_searchExportedMaxNumber ;
					res.msgType = 'warning';
				}else{
					res.msgType = 'info';
				}
			
			}catch(Exception e){
				res.success = false;
				res.msg = e.getMessage();
				res.msgType = 'error';
			}
	
		}else{
			res.success = false;
			res.msg = 'INVALID PARAMETERS';
			res.msgType = 'error';
		}
		return JSON.serialize(res);
	
	}
	
	public String exportQuickResult (){
		responseWrapper res = new responseWrapper();
		Boolean success = true;
		String msg ='';
		
		//check if we get Id set
		if ( Apexpages.currentPage().getParameters().get('idSet') != null ){
			try{
				
				List<String> p = ChatterAuditSearchController.serializeParameters(Apexpages.currentPage().getParameters());
				//
				ChatterAuditExportUtilities.exportQuick(ChatterAuditConstants.csvUIQuick,p);
				res.msg  =Label.ChatterAudit_searchExportedText;	
				res.msgType = 'info';
			
			}catch(Exception e){
				res.success = false;
				res.msg  = e.getMessage();
				res.msgType = 'error';
			}
			
		}else{
			res.success = false;
			res.msg  = 'INVALID PARAMETERS';
			res.msgType = 'error';
		}

	
		return JSON.serialize(res);
	}	
	
	
	public String displayRecords4Purge(){
		
		String res;
		
		if (ChatterAuditUtils.isValidString(Apexpages.currentPage().getParameters().get('startDate')) && 
			ChatterAuditUtils.isValidString(Apexpages.currentPage().getParameters().get('endDate')) &&
			ChatterAuditUtils.isValidDateSimple(Apexpages.currentPage().getParameters().get('startDate')) && 
				ChatterAuditUtils.isValidDateSimple(Apexpages.currentPage().getParameters().get('endDate'))){
				
			String startD = String.escapeSingleQuotes(Apexpages.currentPage().getParameters().get('startDate'));
			String endD = String.escapeSingleQuotes(Apexpages.currentPage().getParameters().get('endDate'));

			list<ChatterAuditPurgeController.purgeItem>  l2 = ChatterAuditPurgeController.getRecordsToPurge(startD,endD);
			res = JSON.serialize(new responseWrapper('' , l2,true));
	
		}else{
			res = JSON.serialize(new responseWrapper('ERROR',false));
		}

		return  res;
	}
	
	
	public String purgeRecords (){
	
		
		responseWrapper resp = new responseWrapper();
		
		resp.success = true;
		
		//check if we get Id set
		if (ChatterAuditUtils.isValidString(Apexpages.currentPage().getParameters().get('startDate')) && 
				ChatterAuditUtils.isValidString(Apexpages.currentPage().getParameters().get('endDate')) && 
				ChatterAuditUtils.isValidDateSimple(Apexpages.currentPage().getParameters().get('startDate')) && 
				ChatterAuditUtils.isValidDateSimple(Apexpages.currentPage().getParameters().get('endDate'))){
				
				String startD = String.escapeSingleQuotes(Apexpages.currentPage().getParameters().get('startDate'));
				String endD = String.escapeSingleQuotes(Apexpages.currentPage().getParameters().get('endDate'));
				String scenario = (Apexpages.currentPage().getParameters().get('searchType') != null) ? String.escapeSingleQuotes(Apexpages.currentPage().getParameters().get('searchType')) : 'public';
			try{		
				
				if ( scenario == 'private' ){
					ChatterAuditExportUtilities.PurgePrivateMessages(startD,endD);
				}else{
					ChatterAuditExportUtilities.Purge(startD,endD);	
				}
				resp.msgType = 'info';
				resp.msg =Label.ChatterAudit_MAIL_TEXT_purge_part1 +'<br/>'+Label.ChatterAudit_aboutPage_Label87;	
			
			}catch(Exception e){
				resp.success = false;
				resp.msg = e.getMessage();
			}
	
		}else{
			resp.success = false;
			resp.msg = 'INVALID PARAMETERS';
			resp.msgType = 'error';
		}
		return JSON.serialize(resp);
	
	
	
	}
	
	public void getLookUpItemsList(){
	
		String type = '1';
		if (ChatterAuditUtils.isValidString(System.currentPageReference().getParameters().get( 'type' ))){
			type  = 	String.escapeSingleQuotes( System.currentPageReference().getParameters().get( 'type' ));
		}
		
		if (type == '1' || type == '2')
			this.result = getUserList();	
			
		if (type == '3')
			this.result = getGroupList();	
		
	}
	
	
	
	public String getUserList () {
	
		String itemName = '';
		Boolean success = true;
		String msg ='';
		list<ChatterAuditLookUpController.Item> l;

		try{		
		
			if (ChatterAuditUtils.isValidString(System.currentPageReference().getParameters().get( 'uName' ))){
				itemName  = 	String.escapeSingleQuotes(System.currentPageReference().getParameters().get( 'uName' ));
			}
			l = ChatterAuditUtils.getUserDetailsByName(itemName);
		
		}catch(Exception e){
			success = false;
			msg = e.getMessage();
		}
		
		return  JSON.serialize(new responseWrapper(msg, l,success));
	
	}
	
	/**
		returns JSON encoded result list
	
	**/
	public String getGroupList() {
	
		String itemName = '';
		Boolean success = true;
		String msg ='';
		list<ChatterAuditLookUpController.Item> l;
		
		try{ 
			if (ChatterAuditUtils.isValidString(System.currentPageReference().getParameters().get( 'uName' ))){
				itemName  = 	String.escapeSingleQuotes(System.currentPageReference().getParameters().get( 'uName' ));
			}			
			l = ChatterAuditLookUpController.getGroupsList(itemName);
		
		}catch(Exception e){
			success = false;
			msg = e.getMessage();
		}
		return  JSON.serialize(new responseWrapper(msg, l,success));
	
	}
	
	public class responseWrapper{
	
		public String	requestUrl	{get; set;}
		public String	msg			{get; set;}
		public String	msgType		{get; set;}
		public Boolean	success		{get; set;}
		public list<ChatterAuditSearchController.SearchItem>	searchData	{get;set;}
		public list<ChatterAuditPurgeController.purgeItem>		purgeData	{get;set;}
		public list<ChatterAuditLookUpController.Item>			lkUpData	{get;set;}
		
		public responseWrapper( ){
		}
		
		public responseWrapper( String oMsg, Boolean oSuccess){
			this.msg = oMsg;
			this.success = oSuccess;
		}
		
		public responseWrapper(String oMsg, list<ChatterAuditSearchController.SearchItem> olitems, Boolean oSuccess){
			this.msg = oMsg;
			this.searchData = olitems;
			this.success = oSuccess;
		}

		public responseWrapper(String oMsg, list<ChatterAuditPurgeController.purgeItem> plitems, Boolean oSuccess){
			this.msg = oMsg;
			this.purgeData = plitems;
			this.success = oSuccess;
		}
		
		public responseWrapper(String oMsg, list<ChatterAuditLookUpController.Item> ljpLitems, Boolean oSuccess){
			this.msg = oMsg;
			this.lkUpData = ljpLitems;
			this.success = oSuccess;
		}
		
	} 



}