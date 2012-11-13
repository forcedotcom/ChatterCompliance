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
public with sharing class ChatterAuditConstants {
	
	
	public static final Integer MAX_BATCH_SIZE	= 150;
	
	/**
	* list page size
	*/
    // max amount of records to retrieve when exporting posts ( all related comments will be brought)
	public static final Integer MAXIMUM_LIST_RESULTS 	= 1500;
	public static final Integer MAXIMUM_POST_RESULT 	= 2000;
	public static final Integer MAXIMUM_COMMENT_RESULT 	= 2000;
	
	public static final Integer MAXIMUM_RECORDS_2_PROCESS = 3500;//2000
	 
	public static final Integer MAXIMUM_POST_4_EXPORT 	 = 3000;
	public static final Integer MAXIMUM_COMMENT_4_EXPORT = 3000;
	
	/**
	* file names for exporting   : EXPORT_FILE_NAME +TIMESTAMP+.file_format
	*/
	public static final String EXPORT_FILE_NAME	= 'ChatterAudit';
	public static final String PURGE_FILE_NAME	= 'ChatterAuditDump';
	public static final String EXPORT_FOLDER_NAME	= 'ChatterAuditEXPORT';
	/**
	* collaborationGroup object name
	*/
	public static final String ChatterGroup	= 'CollaborationGroup';

	/**
	* dummy ID
	*/
	public static final String dummyId	= '000000000000000000';

	/**
	* separator for strings
	*/
	public static final String separator	= '!#!';
	/**
	* default type names
	*/
	public static final String postTypeName			= 'Post';
	public static final String commentTypeName		= 'Comment';
	public static final String userStatusTypeName	= 'UserStatus';
	/**
	* contentTypes and extensions for exported files
	*/
	public static final String csvUIFull		= 'csvFull';
	public static final String csvUIQuick		= 'csvQuick';
	public static final String csvContenType	= 'application/vnd.ms-excel';//'application/vnd.ms-excel'
	public static final String csvExtension		= 'txt';//'csv';
	public static final String semiColonScape	= ';';
	public static final String lineBreakScape   = ' ';
	public static final String csvSeparator   	= ',';

	/**
	* limits grace
	*/
	public static final Integer HEAP_GRACE			= 1000;
	public static final Integer STATEMENTS_GRACE	= 200;
	/**
	* Max DML Rows
	*/
	public static final Integer MAX_DML_ROWS             = 999;
	public static final Integer MAX_COMMENT_ROWS     = 5000;
	public static final Integer MAX_DML_ROWS_BATCH = 49990; 
	/**
	* Default name for the custom setting
	*/
	public static final String CUSTOM_SETTING_NAME	= 'default';

	/**
	* Default chatter url to view userprofile FeedItems
	*/
	public static final String USER_PROFILE_VIEW_LINK	= '_ui/core/userprofile/UserProfilePage?u=USERID&ChatterFeedItemId=FEEDITEMID';
	public static final String ENTITY_VIEW_LINK			= 'ENTITYID?ChatterFeedItemId=FEEDITEMID';
	
	/*
	 * Default className for preloading post/comments
	 */
	public static final String BATCH_LOADER_CLASS_NAME		= 'ChatterAuditBatchLoader';	
}