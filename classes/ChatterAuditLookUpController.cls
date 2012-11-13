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
public with sharing class ChatterAuditLookUpController {
	
	
	
	/**
	 * search Group Items
	 *
	 * @param uName				String name to search for
	 * @return					a Item List
 	 */
	public static List<Item> getGroupsList(String uName){

		Map<String,set<String>> lres = new Map<String,set<String>>(); 
		List<Item> itmList = new List<Item>();
		List<Item> tmpList = new List<Item>();
		set<string> tmp;
		set<Id> groupIds = new set<Id>();
		if(ChatterAuditUtils.isValidString(uName)){
			uName = String.escapeSingleQuotes(uName );
		}
		uName = '\'%'+ChatterAuditUtils.sanitize(uName) +'%\'' ;
		//search matching groupNames on entityFeeds
		tmpList.addAll(ChatterAuditEntityFeedHandler.getGroupListByName(uName));
		//search on existing groups
		tmpList.addAll(ChatterAuditChatterUtilities.getCollaborationGroupListByName(uName));
		// go over tmpList and merge authorId and stored groupNames
		for(Item  obj  : tmpList){
			if (!lres.containsKey(obj.Id)){
				tmp  = new set<string>();
			}else{
				tmp  = lres.get(obj.Id);
			}
			tmp.add(obj.col1);
			lres.put(obj.Id,tmp);
			groupIds.add(obj.Id);
		}
		Map<Id,CollaborationGroup> users = new Map<Id,CollaborationGroup>([Select Id, Name, Description, Owner.Name  from CollaborationGroup where id in :groupIds ]);
		String allNames = '';
		String initialName;
		CollaborationGroup aux;
		for(String st : lres.KeySet()){
			tmp  = lres.get(st);
			allNames = '';
			initialName= '';
			for(String name : tmp){
				if (initialName==''){
					initialName = name;
				}
				allNames +=','+name;
			}
			if (allNames.length()>0){
				allNames = allNames.substring(1);
			}
			if ( users.containsKey(st)){
				aux = users.get(st);
				itmList.add(new Item(st,aux.Name,aux.Description,aux.Owner.Name,allNames));
			}else{
				//if the group was deleted
				itmList.add(new Item(st,allNames,'deleted','N/A','' ));
			}
		}
		
		return itmList;
	}


	public List<Item> getUserList(String uName){

		List<Item> res = ChatterAuditUtils.getUserDetailsByName(String.escapeSingleQuotes(uName ));
		
		return res;
	}



	/**
	 * INNER CLASS ITEM
 	 */
	public class Item{

		    public String id 			{get; set;}
		    public String col1 			{get; set;}
		    public String col2			{get; set;}
		    public String col3			{get; set;}
		    public String col4		 	{get; set;}


		    public Item( String id,String c1, String c2, String c3, String c4){
		        this.id			= ChatterAuditUtils.encodeHtml(id);
		        this.col1		= ChatterAuditUtils.SFDC_JSENCODE(ChatterAuditUtils.encodeHtml(c1));
		        this.col2		= ChatterAuditUtils.encodeHtml(c2);
		        this.col3		= ChatterAuditUtils.encodeHtml(c3);
		        this.col4		= ChatterAuditUtils.encodeHtml(c4);
		    }

		    public Item( String id,String c1){
		        this.id			= ChatterAuditUtils.encodeHtml(id);
		        this.col1		= ChatterAuditUtils.SFDC_JSENCODE(ChatterAuditUtils.encodeHtml(c1));
		    }
		}

}