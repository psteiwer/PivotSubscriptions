Include %DeepSee

/// DeepSee CSV Import page.
/// This page lets you import data from a CSV file into DeepSee.
Class PivotSubscriptions.UI.PivotList Extends %DeepSee.UI.standardPage [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "PivotSubscriptions Pivot List";

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
<column id="Name" header="Name" colName="PName" width="50%" filterType="text" />
<column id="View" header="View in Analyzer" colName="PView" width="30%" link="./_DeepSee.UserPortal.Analyzer.zen?PIVOT=#(%query.PView)#"/>
<column OnDrawCell="DrawAddAlertLink"/>
</tablePane>
</pane>
}

Method ExecuteRS(pRS As %ResultSet, Output pSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %Boolean
{
	set ^pfs($i(^pfs),"executers")=1
	quit pRS.%Execute($G(pInfo.filters("POwner")),$G(pInfo.filters("PName")))
}

ClientMethod launchAddSubscription(pivotName) [ Language = javascript ]
{
	var url = zenLink('PivotSubscriptions.UI.Dialog.EditSubscription.zen')+'?SUBSCRIPTIONID=0&PIVOTNAME='+encodeURIComponent(pivotName);
	zenPage.launchPopupWindow(url,'Add Subscription','status,scrollbars,resizable,width=500,height=500');
}

ClassMethod DrawAddAlertLink(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status [ Internal ]
{
	set ^pfs($i(^pfs),"draw add link")=1
	&html<<a href="#" onclick="zenPage.launchAddSubscription('#(%query("PName"))#');return false;">#("Add Subscription")#</a>>

	Quit $$$OK
}

Query GetPivots(pOwner As %String = "", pName As %String = "") As %Query(ROWSPEC = "POwner:%String,PName:%String,PView:%String,PAlert:%String")
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
	
	Merge ^||DSII.getPivotExecute=tPivots
    set qHandle=""
    Quit $$$OK
}

ClassMethod GetPivotsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = GetPivotsExecute ]
{
    set qHandle=$O(^||DSII.getPivotExecute(qHandle))
    if qHandle="" {
	    Set AtEnd=1
	    Quit $$$OK
    }
	
	Set Row=$lb($LG(^||DSII.getPivotExecute(qHandle),10),$LG(^||DSII.getPivotExecute(qHandle),1),$ZCONVERT($LG(^||DSII.getPivotExecute(qHandle),1),"O","HTML"),"Alert")
    Set AtEnd=0
    
    Quit $$$OK
}

ClassMethod GetPivotsClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = GetPivotsFetch ]
{
        Set qHandle=""
        Quit $$$OK
}

}