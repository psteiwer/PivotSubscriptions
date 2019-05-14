Include %DeepSee

/// DeepSee CSV Import page.
/// This page lets you import data from a CSV file into DeepSee.
Class PivotSubscriptions.UI.PivotList Extends PivotSubscriptions.UI.Template [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Pivot List";

/// This XML block defines the contents of this pane.
XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<tableNavigatorBar id="tableNavigator" tablePaneId="tablePane" showPageSize="true" />
<tablePane id="tablePane" 
	fixedHeaders="true" 
	dataSource="columns" 
	pageSize="100" 
	maxRows="1000" 
	useSnapshot="true" 
	queryClass="PivotSubscriptions.UI.PivotList" 
	queryName="GetPivots" 
	OnExecuteResultSet="ExecuteRS"
	>
<column id="Owner" header="Owner" colName="POwner" width="10%" filterType="text"/>
<column id="Name" header="Name" colName="PName" width="30%" filterType="text" link="./_DeepSee.UserPortal.Analyzer.zen?PIVOT=#(%query.PName)#"/>
<column OnDrawCell="DrawAddSubscriptionLink"/>
</tablePane>
</pane>
}

Method ExecuteRS(pRS As %ResultSet, Output pSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %Boolean
{
	quit pRS.%Execute($G(pInfo.filters("POwner")),$G(pInfo.filters("PName")))
}

ClientMethod launchAddSubscription(pivotName) [ Language = javascript ]
{
	var url = zenLink('PivotSubscriptions.UI.Dialog.EditSubscription.zen')+'?SUBSCRIPTIONID=0&PIVOTNAME='+encodeURIComponent(pivotName);
	zenPage.launchPopupWindow(url,'Add Subscription','status,scrollbars,resizable,width=750,height=500');
}

ClassMethod DrawAddSubscriptionLink(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status [ Internal ]
{
	&html<<a href="#" onclick="zenPage.launchAddSubscription('#(%query("PName"))#');return false;">#("Add Subscription")#</a>>

	Quit $$$OK
}

Query GetPivots(pOwner As %String = "", pName As %String = "") As %Query(ROWSPEC = "POwner:%String,PName:%String,PSubscription:%String")
{
}

ClassMethod GetPivotsExecute(ByRef qHandle As %Binary, pOwner As %String = "", pName As %String = "") As %Status
{
	Set tSC = $$$OK
	
	Set tSC = ##class(%DeepSee.UserPortal.Utils).%GetFolderItemsForUser(.tItems,,,1,1)
	
	Set tItem = $O(tItems(""))
	While tItem'="" {
		If $LG(tItems(tItem),2)="Pivot" {
			Set tTemp=tItems(tItem)
			If (pOwner'="")&&($$$UPPER($LG(tTemp,10))'[$$$UPPER(pOwner)) {
				Set tTemp=""
			}
			If (pName'="")&&($$$UPPER($LG(tTemp,1))'[$$$UPPER(pName)) {
				Set tTemp=""
			}
			Set:tTemp'="" tPivots($I(tPivots))=tTemp  // Sort by pivot ID
			//Set:tTemp'="" tPivots($LG(tTemp,1))=tTemp  // Sort by pivot name
		}
		Set tItem = $O(tItems(tItem))
	}
	
	Merge ^||PivotSubscriptions.getPivotExecute=tPivots
    set qHandle=""
    Quit $$$OK
}

ClassMethod GetPivotsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = GetPivotsExecute ]
{
    set qHandle=$O(^||PivotSubscriptions.getPivotExecute(qHandle))
    if qHandle="" {
	    Set AtEnd=1
	    Quit $$$OK
    }
	
	Set Row=$lb($LG(^||PivotSubscriptions.getPivotExecute(qHandle),10),$LG(^||PivotSubscriptions.getPivotExecute(qHandle),1),"Subscription")
    Set AtEnd=0
    
    Quit $$$OK
}

ClassMethod GetPivotsClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = GetPivotsFetch ]
{
        Set qHandle=""
        Quit $$$OK
}

}
