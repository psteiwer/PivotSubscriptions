Class PivotSubscriptions.UI.EventLogViewer Extends PivotSubscriptions.UI.Template
{

/// Displayed name of this page.
Parameter PAGENAME = "Event Log Viewer";

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
	tableName="PivotSubscriptions.EventLog"
	orderByClause="ID DESC"
	useSnapshot="true"
	showQuery="false"
	showZebra="true"
	showRowNumbers="false"
	pageSize="50"
	maxRows="1000"
	>
	<column colName="ID" header="Details" onclick="zenPage.viewDetails(#(%query.ID)#)" linkCaption="Details" link="#"/>
	<column colName="StartTime" filterType="text" filterOp="UP["/>
	<column colName="EndTime" filterType="text" filterOp="UP["/>
	<column colName="EventType" filterType="text" filterOp="UP["/>
	<column colName="UserName" filterType="text" filterOp="UP["/>
	<column colName="Name" filterType="text" filterOp="UP["/>
	<column colName="Emails" filterType="text" filterOp="UP["/>
	<column colName="Status" filterType="text" filterOp="UP[" OnDrawCell="FormatStatus"/>
</tablePane>
</vgroup>
</hgroup>
</pane>
}

/// Creates edit popup.
ClientMethod viewDetails(pId, pPivot) [ Internal, Language = javascript ]
{
	zenLaunchPopupWindow('PivotSubscriptions.UI.Dialog.EventDetails.cls?EVENTID='+pId,'EventDetails','status,resizable=yes,width=700,height=575');
}

/// Get the (localized) title string for the page.
Method %OnGetTitle() As %String [ Internal ]
{
	Quit $$$Text("Event Log Viewer","PivotSubscriptions")
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String [ Internal ]
{
	Quit $$$Text("Event Log Viewer","PivotSubscriptions")
}

Method FormatStatus(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	Write $System.Status.GetErrorText(%query(pName))
	Quit $$$OK
}

}
