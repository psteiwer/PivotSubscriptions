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
	queryClass="PivotSubscriptions.UI.EventLogViewer"
	queryName="GetEvents"
	useSnapshot="true"
	showQuery="false"
	showZebra="true"
	showRowNumbers="false"
	pageSize="100"
	maxRows="1000"
	>
</tablePane>
</vgroup>
</hgroup>
</pane>
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

Query GetEvents() As %SQLQuery
{
    SELECT StartTime,EndTime,EventType,Name,Pivot,UserName,DayOfWeek,Format,"Hour","Minute",Emails,Status
    FROM PivotSubscriptions.EventLog 
    ORDER BY ID DESC
}

}
