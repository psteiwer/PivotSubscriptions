Include %DeepSee

Class PivotSubscriptions.UI.PivotList Extends PivotSubscriptions.UI.Template
{

/// Displayed name of this page.
Parameter PAGENAME = "Pivot List";

/// This XML block defines the contents of this pane.
XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<hgroup valign="top" >
<spacer width="20" />
<vgroup valign="top" >
<spacer height="20" />
<tableNavigatorBar id="tableNavigator" tablePaneId="tablePane" showPageSize="true" />
<tablePane id="tablePane" 
    cellSpacing="2"
	fixedHeaders="false" 
	queryClass="PivotSubscriptions.UI.PivotList" 
	queryName="GetPivots" 
	useSnapshot="true" 
	showQuery="false"
	showZebra="true"
	showRowNumbers="false"
	pageSize="100" 
	maxRows="1000" 
	OnExecuteResultSet="ExecuteRS"
	>
<column id="Owner" header="Owner" colName="POwner" filterType="text"/>
<column id="Name" header="Name" colName="PName" filterType="text" link="./_DeepSee.UserPortal.Analyzer.zen?PIVOT=#(%query.PName)#"/>
<column id="Subscription" header="Add Subscription" colName="PSubscription" OnDrawCell="DrawAddSubscriptionLink"/>
</tablePane>
</vgroup>
</hgroup>
</pane>
}

/// Get the (localized) title string for the page.
Method %OnGetTitle() As %String [ Internal ]
{
	Quit $$$Text("Pivot List","PivotSubscriptions")
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String [ Internal ]
{
	Quit $$$Text("Pivot List","PivotSubscriptions")
}

Method ExecuteRS(pRS As %ResultSet, Output pSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %Boolean
{
	Quit pRS.%Execute($G(pInfo.filters("POwner")),$G(pInfo.filters("PName")))
}

ClientMethod launchAddSubscription(pivotName) [ Language = javascript ]
{
	var url=zenLink('PivotSubscriptions.UI.Dialog.EditSubscription.zen')+'?SUBSCRIPTIONID=0&PIVOTNAME='+encodeURIComponent(pivotName);
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
	Set tSC=$$$OK
	
	Set tSC=##class(%DeepSee.UserPortal.Utils).%GetFolderItemsForUser(.tItems,,,1,1)
	
	If $$$ISERR(tSC) Quit tSC
	
	Set tItem=$O(tItems(""))
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
		Set tItem=$O(tItems(tItem))
	}
	
	Merge ^||PivotSubscriptions.getPivotExecute=tPivots
    Set qHandle=""
    Quit $$$OK
}

ClassMethod GetPivotsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = GetPivotsExecute ]
{
    Set qHandle=$O(^||PivotSubscriptions.getPivotExecute(qHandle))
    If qHandle="" {
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
