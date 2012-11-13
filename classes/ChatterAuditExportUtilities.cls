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
public with sharing class ChatterAuditExportUtilities {
 
	private static List<ArchivedFeedItem__c> fullItems;
	private static Map<Id,List<ArchivedFeedComment__c>> fullComments;
	private static List<ChatterAuditSearchController.SearchItem> quickItems;
	public static Boolean isExport = false;
	


	/**
	 * sets the content of fullItems querying the ArchivedFeedItems with id list
	 *
	 * @param idList		list of Archived FeedItems to export
	 * @param fileformat	the format for the file we will create
 	 */
	@future
	public static void exportFull(String fileformat, set<Id> idList){

		String fName	=	ChatterAuditConstants.EXPORT_FILE_NAME+'#TYPE#'+Datetime.now().format('yyyy-MM-dd_HH:mm:ss');

		try{
			isExport = true;
			//use idList to query feedItems with their comments
			fullItems = obtainItemsList(idList);
			fullComments = obtainItemsCommentsList(idList);

			// once we obtain data, build the content of the file and store it
			generateExport(fName,fileformat);
        }catch( ChatterAuditException cAE){
			String exBody = cAE.getMessage()+'\n'+cAE.getCause()+'\n'+cAE.getStackTraceString();
			ChatterAuditUtils.mailException(exBody,'ChatterAuditExportUtilities.exportFull as '+fileformat);
		}catch( DMLException dmlEx){
			String exBody = dmlEx.getMessage();
			if (exBody.contains('MAXIMUM_SIZE_OF_DOCUMENT')){
				exBody = Label.ChatterAudit_FileSizeErrorEmailMessage ;
			}else{
				exBody +=  '\n'+dmlEx.getCause()+'\n'+dmlEx.getStackTraceString();
			}
			ChatterAuditUtils.mailException(exBody,'ChatterAuditExportUtilities.exportFull as '+fileformat);
		} catch( Exception e){
        	String exBody = e.getMessage()+'\n'+e.getCause()+'\n'+e.getStackTraceString();
			ChatterAuditUtils.mailException(exBody,'ChatterAuditExportUtilities.exportFull as '+fileformat);
		}
	}


	
	/**
	 * sets the results of  quickItems results of a search
	 *
	 * @param paramaters		parameters to run search query again
	 * @param fileformat		the format for the file we will create
 	 */
	@future
	public static void exportQuick(String fileformat, List<String> parameters){

		String fName = ChatterAuditConstants.EXPORT_FILE_NAME+'#TYPE#'+Datetime.now().format('yyyy-MM-dd_HH:mm:ss');

		try{
			isExport = true;
			ChatterAuditSearchController aux = new ChatterAuditSearchController();
			/* user paramaters to run search  */
			aux.runAsyncSearch(parameters);
			quickItems = aux.items;
			/* once we obtain data, build the content of the file and store it  */
			generateExport(fName,fileformat);
        }catch( ChatterAuditException cAE){
			String exBody = cAE.getMessage()+'\n'+cAE.getCause()+'\n'+cAE.getStackTraceString();
			ChatterAuditUtils.mailException(exBody,'ChatterAuditExportUtilities.exportQuick as '+fileformat);
		} catch( Exception e){
        	String exBody = e.getMessage()+'\n'+e.getCause()+'\n'+e.getStackTraceString();
			ChatterAuditUtils.mailException(exBody,'ChatterAuditExportUtilities.exportQuick as '+fileformat);
		}
	}
	
	
	/**
	*	this sets the content of : fullItems querying the ArchivedFeedItems with id list
	* @param startD/endD : Start Date / End Date
	* @param idList list of Archived FeedItems to export
	*
	**/
	public static void Purge(String startD, String endD){
		try{
			//use idList to query feedItems with their comments
			Map<id,ArchivedFeedItem__c> mapItms = obtainItemsList(startD,endD);
			fullItems	= mapItms.values();
			set<Id> idList 	= mapItms.keySet();
			
			//purge logic
	    	ChatterAuditUtils.setDeleteAllowedForPosts(true);
			//delete the ArchivedFeedItems and their comments
			if (!idList.isEmpty()){
				ChatterAuditFeedItemsHandler.deleteItemsAfterPurge(idList);
			}
			ChatterAuditUtils.setDeleteAllowedForPosts(false);
        }catch( ChatterAuditException cAE){
			String exBody = cAE.getMessage()+'\n'+cAE.getCause()+'\n'+cAE.getStackTraceString();
			ChatterAuditUtils.mailException(exBody,'ChatterAuditExportUtilities.Purge');
		} catch( Exception e){
        	String exBody = e.getMessage()+'\n'+e.getCause()+'\n'+e.getStackTraceString();
			ChatterAuditUtils.mailException(exBody,'ChatterAuditExportUtilities.Purge');
		}
	}
	
	/**
	*	this sets the content of : fullItems querying the ArchivedChatterMessages with id list
	* @param startD/endD : Start Date / End Date
	* @param idList list of Archived FeedItems to export
	*
	**/
	public static void PurgePrivateMessages(String startD, String endD){
		try{
			//use idList to query feedItems with their comments
			Map<id,ArchivedChatterMessage__c> mapItms = obtainPrivateItemsList(startD,endD);
			
			list<ChatterAuditSearchController.SearchItem> items = new list<ChatterAuditSearchController.SearchItem>();
			for ( ArchivedChatterMessage__c elm : mapItms.values() ){
				items.add(new ChatterAuditSearchController.SearchItem(elm) );				
			}
			quickItems	= items;
			set<Id> idList 	= mapItms.keySet();
			
			//purge logic
	    	ChatterAuditUtils.setDeleteAllowedForPosts(true);
			//delete the ArchivedFeedItems and their comments
			if (!idList.isEmpty()){
				ChatterAuditChatterMessagesHandler.deleteItemsAfterPurge(idList);
			}
			ChatterAuditUtils.setDeleteAllowedForPosts(false);

        }catch( ChatterAuditException cAE){
			String exBody = cAE.getMessage()+'\n'+cAE.getCause()+'\n'+cAE.getStackTraceString();
			ChatterAuditUtils.mailException(exBody,'ChatterAuditExportUtilities.PurgePrivateMessages');
		} catch( Exception e){
        	String exBody = e.getMessage()+'\n'+e.getCause()+'\n'+e.getStackTraceString();
			ChatterAuditUtils.mailException(exBody,'ChatterAuditExportUtilities.PurgePrivateMessages');
		}
	}
	
	
	/**
	* returns list of ArchivedFeedItem__c objects
	*
	* @param idList	set of Ids
	* @return List<ArchivedFeedItem__c>
	*/
	private static  List<ArchivedFeedItem__c> obtainItemsList(set<Id> idList) {

         List<ArchivedFeedItem__c> items;
         if (!idList.isEmpty()){
			items = [SELECT isParentDeleted__c, isDeleted__c, Type__c,
						Title__c, RelatedRecordId__c, ParentObjectType__c,
						ParentId__c, FeedItemId__c, LinkUrl__c,
						IsDeleted, Inserted_By__r.Name, Inserted_By__c,
						FullArchivedCommentList__c, CreatedDate__c, Created_By__c , Created_By__r.Name,
						ContentType__c, ContentSize__c, ContentFileName__c, 
						ContentDescription__c, Body__c,GroupName__c
					FROM ArchivedFeedItem__c
					where id in: idList
					order by CreatedDate__c desc
					limit :ChatterAuditConstants.MAXIMUM_LIST_RESULTS ];
         }
        return items;
	}
	
	/**
	* returns list of ArchivedFeedComment__c objects
	*
	* @param idList	set of Ids
	* @return List<ArchivedFeedComment__c>
	*/
	public static  Map<Id,List<ArchivedFeedComment__c>> obtainItemsCommentsList(set<Id> idList) {

         Map<Id,List<ArchivedFeedComment__c>> commentData = new Map<Id,List<ArchivedFeedComment__c>>();
         List<ArchivedFeedComment__c> tmp;
         if (!idList.isEmpty()){

			for(ArchivedFeedComment__c c :  [Select CommentBody__c, FeedItemId__c, Inserted_By__c, Inserted_By__r.Name,
						FeedCommentId__c, isDeleted__c, CreatedDate__c, RelatedRecordId__c  
					FROM ArchivedFeedComment__c
					where ArchivedFeedItem__c in: idList ]){
				if (!commentData.containsKey(c.FeedItemId__c)){
					tmp = new List<ArchivedFeedComment__c>();
				}else{
					tmp = commentData.get(c.FeedItemId__c);
				}	
				tmp.add(c);
				commentData.put(c.FeedItemId__c, tmp);
			}
         }

        return commentData;
	}	
	
	
	/**
	* returns list of ArchivedFeedItem__c objects
	*
	* @param startD	startDate
	* @param endD	endDate
	* @return List<ArchivedFeedItem__c>
	*/
	private static  Map<id,ArchivedFeedItem__c> obtainItemsList(String startD, String endD) {

         Map<id,ArchivedFeedItem__c> mapItms;
         String query = 	'	SELECT isParentDeleted__c, isDeleted__c, Type__c,' +
							'	Title__c, RelatedRecordId__c, ParentObjectType__c, ' +
							'	ParentId__c, FeedItemId__c, LinkUrl__c,' +
							'	IsDeleted, Inserted_By__r.Name, Inserted_By__c,' +
							'	FullArchivedCommentList__c, CreatedDate__c, Created_By__c , Created_By__r.Name,' +
							'	ContentType__c, ContentSize__c, ContentFileName__c, '+
							'	ContentDescription__c, Body__c,GroupName__c '+	
							'	FROM ArchivedFeedItem__c ' ;
			//FILTER BY : CreatedDate  - before & after
			if (ChatterAuditUtils.isValidString(startD) && ChatterAuditUtils.isValidString(endD) ){

					String s = String.escapeSingleQuotes(startD+'T00:00:00.000Z');
					query += '	WHERE  CreatedDate__c >= ' + s + ' and ';
					String d = String.escapeSingleQuotes(endD+'T23:59:59.000Z');
					query += '	CreatedDate__c <= '+ d +'  ';
	
				query +=	'	order by CreatedDate__c Limit '+ChatterAuditConstants.MAXIMUM_LIST_RESULTS;
				//Typecasting it to map

				mapItms = new Map<id,ArchivedFeedItem__c>((List<ArchivedFeedItem__c>)Database.query(query));
				
         	}
        return mapItms;
	}
	
	/**
	* returns list of ArchivedChatterMessage__c objects
	*
	* @param startD	startDate
	* @param endD	endDate
	* @return List<ArchivedChatterMessage__c>
	*/
	private static  Map<id,ArchivedChatterMessage__c> obtainPrivateItemsList(String startD, String endD) {

         Map<id,ArchivedChatterMessage__c> mapItms;
         String query = 	'	SELECT Id, Body__c, ConversationId__c, CreatedById__c, SenderId__c, SentDate__c, SenderId__r.Name from ArchivedChatterMessage__c  ' ;
			//FILTER BY : CreatedDate  - before & after
			if (ChatterAuditUtils.isValidString(startD) && ChatterAuditUtils.isValidString(endD) ){

					String s = String.escapeSingleQuotes(startD+'T00:00:00.000Z');
					query += '	WHERE  SentDate__c >= ' + s + ' and ';
					String d = String.escapeSingleQuotes(endD+'T23:59:59.000Z');
					query += '	SentDate__c <= '+ d +'  ';
	
				query +=	'	order by SentDate__c Limit '+ChatterAuditConstants.MAXIMUM_LIST_RESULTS;
				//Typecasting it to map

				mapItms = new Map<id,ArchivedChatterMessage__c>((List<ArchivedChatterMessage__c>)Database.query(query));
				
         	}
        return mapItms;
	}	
		
	/**
	*	this method builds the xml content of the file and stores a Document
	*
	* @param fName	name of the file
	* @param fileformat	: the format for the file we will create
	**/
	public static void  generateExport(String fName,String fileformat) {

		String ctype	= '';
		Id documentId;
		String res = '';
		String msg = '';

		if (ChatterAuditUtils.isValidString(fileformat)){
			ctype	= ChatterAuditConstants.csvContenType;
			if (fileformat == ChatterAuditConstants.csvUIQuick){
				fName = fName.replace('#TYPE#','QuickView')+'.'+ChatterAuditConstants.csvExtension;
				res = buildCSVString(false);
			}else if (fileformat == ChatterAuditConstants.csvUIFull){
				if (fullItems.size() >= ChatterAuditConstants.MAXIMUM_LIST_RESULTS ){
					msg = 'The generated file contains part of the result';
				}
				fName = fName.replace('#TYPE#','CompleteView')+'.'+ChatterAuditConstants.csvExtension;
				res = buildCSVString(true);
			}

			documentId = exportDocument(fName,ctype, res);
			ChatterAuditUtils.mailExportCompleted(documentId,msg);
		}else{
			throw new ChatterAuditException('INVALID EXPORT FORMAT');
		}
	}

	
	
	 /**
    * Creates a document using the parameters for specification and stores it on a folder
    * @param docName
    * @param cntType
    * @param docContent
    */
	private static Id  exportDocument(String docName,String cntType,String docContent){

		Document doc		=	new Document();
		doc.body 			=	Blob.valueOf( docContent ) ;
		doc.ContentType 	=	cntType;
		doc.name 			=	docName;
		doc.FolderId 		=	ChatterAuditSettingsHandler.getExportForlderId();

		insert doc;
		return doc.Id;
	}
	
	
/*EXTRA CODE FOR CSV*/

 /**
    * returns string containing xml version for export
    *
    * @param isComplete true means the xml must contain posts and all their comments
    * @return string
    */
    private static String buildCSVString(Boolean isComplete){

    	String res = '';

        if (!isComplete){
            res = writeCSVQuickViewList();
        }else{
            res = writeCSVcompleteViewList();
        }
        return res;
    }

    /**
    * this method write the xml for the complete view
    *   @returns string
    *
    */
    private static String writeCSVcompleteViewList(){

        String res  = '';
        list<String> extendedColumns = new list<String>{Label.ChatterAudit_ExportedFile_row_Id,Label.ChatterAudit_ExportedFile_row_Body,Label.ChatterAudit_ExportedFile_row_Type,Label.ChatterAudit_ExportedFile_row_ParentId,Label.ChatterAudit_ExportedFile_row_ParentObjectType,Label.ChatterAudit_ExportedFile_row_ParentObjectName,Label.ChatterAudit_ExportedFile_row_LinkUrl,Label.ChatterAudit_ExportedFile_row_isDeleted,Label.ChatterAudit_ExportedFile_row_insertedByName,Label.ChatterAudit_ExportedFile_row_insertedById,Label.ChatterAudit_ExportedFile_row_fullArchivedCommentList,Label.ChatterAudit_ExportedFile_row_FileTitle,Label.ChatterAudit_ExportedFile_row_RelatedRecordID,Label.ChatterAudit_ExportedFile_row_contentType,Label.ChatterAudit_ExportedFile_row_contentSize,Label.ChatterAudit_ExportedFile_row_contentFileName,Label.ChatterAudit_ExportedFile_row_contentDescription,Label.ChatterAudit_ExportedFile_row_CreatedDate,Label.ChatterAudit_ExportedFile_row_CreatedById,Label.ChatterAudit_ExportedFile_row_CommentID,Label.ChatterAudit_ExportedFile_row_commentBody,Label.ChatterAudit_ExportedFile_row_RelatedRecordID,Label.ChatterAudit_ExportedFile_row_InsertedById,Label.ChatterAudit_ExportedFile_row_InsertedByName,Label.ChatterAudit_ExportedFile_row_isDeleted,Label.ChatterAudit_ExportedFile_row_createdDate};

        //header ROWs
        for(String str : extendedColumns){
	          res += ChatterAuditConstants.csvSeparator+str+'';
        }
        res = res.substring(1,res.length());
		res += '\n';
        //Data ROWs
        ArchivedFeedItem__c i;
        ArchivedFeedComment__c c;
        String auxBody = '';
        if (fullItems != null){
            for(Integer h = 0; h < fullItems.size(); ){
                ChatterAuditUtils.controlLimits();
                i = fullItems.get(h);

                List<ArchivedFeedComment__c> lc = fullComments.get(i.FeedItemId__c);
                //fullComments

                if(lc != null && ! lc.isEmpty()){

                    for(Integer j = 0; j < lc.size(); ){
                        ChatterAuditUtils.controlLimits();
                        c = lc.get(j);
                        res += ''+i.FeedItemId__c;
                        auxBody = semiColonEscape(i.body__c);
                        res += ChatterAuditConstants.csvSeparator+auxBody;
                        res += ChatterAuditConstants.csvSeparator+i.Type__c;
                        res += ChatterAuditConstants.csvSeparator+i.ParentId__c;
                        res += ChatterAuditConstants.csvSeparator+i.ParentObjectType__c;
                        res += ChatterAuditConstants.csvSeparator+i.GroupName__c;
                        res += ChatterAuditConstants.csvSeparator+semiColonEscape(i.LinkUrl__c);
                        res += ChatterAuditConstants.csvSeparator+i.isDeleted__c;
                        res += ChatterAuditConstants.csvSeparator+semiColonEscape(i.Inserted_By__r.Name) ;
                        res += ChatterAuditConstants.csvSeparator+i.Inserted_By__c ;
                        res += ChatterAuditConstants.csvSeparator+i.FullArchivedCommentList__c ;
                        res += ChatterAuditConstants.csvSeparator+i.Title__c ;
                        res += ChatterAuditConstants.csvSeparator+i.RelatedRecordId__c ;
                        res += ChatterAuditConstants.csvSeparator+i.ContentType__c ;
                        res += ChatterAuditConstants.csvSeparator+i.ContentSize__c ;
                        res += ChatterAuditConstants.csvSeparator+semiColonEscape(i.ContentFileName__c) ;
                        res += ChatterAuditConstants.csvSeparator+semiColonEscape(i.ContentDescription__c) ;
                        res += ChatterAuditConstants.csvSeparator+i.CreatedDate__c;
                        res += ChatterAuditConstants.csvSeparator+i.Created_By__c;
                        //comment details
                        res += ChatterAuditConstants.csvSeparator+c.FeedCommentId__c ;
                        auxBody = semiColonEscape(c.CommentBody__c);
                        res += ChatterAuditConstants.csvSeparator+auxBody;
                        res += ChatterAuditConstants.csvSeparator+c.RelatedRecordId__c ;
                        res += ChatterAuditConstants.csvSeparator+c.Inserted_By__c ;
                        res += ChatterAuditConstants.csvSeparator+semiColonEscape(c.Inserted_By__r.Name);
                        res += ChatterAuditConstants.csvSeparator+c.isDeleted__c;
                        res += ChatterAuditConstants.csvSeparator  +c.CreatedDate__c;
                        lc.remove(0);
            			res += '\r';
                    }
               }else{
                        res += ''+i.FeedItemId__c;
                        auxBody = semiColonEscape(i.body__c);
                        res += ChatterAuditConstants.csvSeparator+auxBody;
                        res += ChatterAuditConstants.csvSeparator+i.Type__c;
                        res += ChatterAuditConstants.csvSeparator+i.ParentId__c;
                        res += ChatterAuditConstants.csvSeparator+i.ParentObjectType__c;
                        res += ChatterAuditConstants.csvSeparator+i.GroupName__c;
                        res += ChatterAuditConstants.csvSeparator+semiColonEscape(i.LinkUrl__c);
                        res += ChatterAuditConstants.csvSeparator+i.isDeleted__c;
                        res += ChatterAuditConstants.csvSeparator+semiColonEscape(i.Inserted_By__r.Name) ;
                        res += ChatterAuditConstants.csvSeparator+i.Inserted_By__c ;
                        res += ChatterAuditConstants.csvSeparator+i.FullArchivedCommentList__c ;
                        res += ChatterAuditConstants.csvSeparator+i.Title__c ;
                        res += ChatterAuditConstants.csvSeparator+i.RelatedRecordId__c ;
                        res += ChatterAuditConstants.csvSeparator+i.ContentType__c ;
                        res += ChatterAuditConstants.csvSeparator+i.ContentSize__c ;
                        res += ChatterAuditConstants.csvSeparator+semiColonEscape(i.ContentFileName__c) ;
                        res += ChatterAuditConstants.csvSeparator+semiColonEscape(i.ContentDescription__c) ;
                        res += ChatterAuditConstants.csvSeparator+i.CreatedDate__c;
                        res += ChatterAuditConstants.csvSeparator+i.Created_By__c;
            res += ',,,,,,';
            res += '\r';
                }
                fullItems.remove(0);//reduce heap usage
        }
    }
        return res;
    }

    /**
    *   this method write the xml for the quick  view
    *   Rows: 'ItemId','Type','Body','CreatedDate','InsertedByName','detailPage (link)'
    **/
    private static String writeCSVQuickViewList(){

    String res  = '';
        list<String> reducedColumns = new list<String>{Label.ChatterAudit_ExportedFile_row_ItemId,Label.ChatterAudit_ExportedFile_row_Type,Label.ChatterAudit_ExportedFile_row_ParentObjectName,Label.ChatterAudit_ExportedFile_row_Body,Label.ChatterAudit_ExportedFile_row_CreatedDate,Label.ChatterAudit_ExportedFile_row_InsertedByName,Label.ChatterAudit_ExportedFile_row_detailPage};

        //header ROWs

        for(String str : reducedColumns){
             res += ChatterAuditConstants.csvSeparator+str+'';
        }
        res = res.substring(1,res.length());
		res += '\r';

        //Data ROW
        String url;
        String auxBody;
        if (quickItems != null){
            ChatterAuditSearchController.SearchItem i;
            for(Integer h = 0; h < quickItems.size(); ){
                ChatterAuditUtils.controlLimits();
                i = quickItems.get(h);
                url = ChatterAuditUtils.getOrgUrl()+'/'+i.id;
                res += ''+i.id;
                res += ChatterAuditConstants.csvSeparator+i.Type;
                auxBody = semiColonEscape(i.parentType.name);
                res += ChatterAuditConstants.csvSeparator+auxBody;
                auxBody = semiColonEscape(i.body);
                res += ChatterAuditConstants.csvSeparator+auxBody;
                res += ChatterAuditConstants.csvSeparator+i.CreatedDate;
                res += ChatterAuditConstants.csvSeparator+i.Author.name;
                res += ChatterAuditConstants.csvSeparator+url+'';
                quickItems.remove(0);
                res += '\r';
            }
        }
       return res;
    }

    public static String semiColonEscape(String s){
    	if ( !chatterauditutils.isValidString(s) ) return '';

    	s = s.replace(ChatterAuditConstants.csvSeparator,ChatterAuditConstants.semiColonScape);
    	s = s.replace('\n',ChatterAuditConstants.lineBreakScape);
    	s = s.replace('\n\r',ChatterAuditConstants.lineBreakScape);
    	s = s.replace('\r',ChatterAuditConstants.lineBreakScape);
    	
    	return s;
    }




}