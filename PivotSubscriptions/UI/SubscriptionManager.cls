Include %DeepSee

Class PivotSubscriptions.UI.SubscriptionManager Extends PivotSubscriptions.UI.Template
{

/// Displayed name of this page.
Parameter PAGENAME = "Subscription Manager";

/// This XML block defines the contents of this pane.
XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<hgroup valign="top" >
<spacer width="20" />
<vgroup valign="top" >
<spacer height="20" />
<tableNavigatorBar id="tableNavigator" tablePaneId="table" showPageSize="true" />
<tablePane id="table"
	tableName="PivotSubscriptions.Subscription"
    cellSpacing="2"
	fixedHeaders="false"
	useSnapshot="true"
	showQuery="false"
	showZebra="true"
	showRowNumbers="false"
	pageSize="100" 
	maxRows="1000"
	valueColumn="ID"
	>
	<column colName="ID" header="Subscription ID" hidden="true" />
	<column id="Pivot" colName="Pivot" header="Pivot" link="./_DeepSee.UserPortal.Analyzer.zen?PIVOT=#(%query.Pivot)#" filterType="text" filterOp="UP[" />
	<column id="Emails" colName="Emails" header="Emails" filterType="text" filterOp="UP[" />
	<column onclick="zenPage.editSubscription(#(%query.ID)#,'#(%query.Pivot)#')" linkCaption="Edit" link="#"/>
	<column onclick="return zenPage.deleteSubscription('#(%query.ID)#');" linkCaption="Delete" link="#" />
</tablePane>
</vgroup>
</hgroup>
</pane>
}

/// Get the (localized) title string for the page.
Method %OnGetTitle() As %String [ Internal ]
{
	Quit $$$Text("Subscription Manager","PivotSubscriptions")
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String [ Internal ]
{
	Quit $$$Text("Subscription Manager","PivotSubscriptions")
}

/// Get the product name for the page.
Method %OnGetProductName() As %String [ Internal ]
{
	Quit "DeepSee"
}

/// This client event is fired when a popup page launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Internal, Language = javascript ]
{
	switch(popupName) {
		case 'switchNamespace':
			var homeurl = zenLink("/csp/sys/%25CSP.Portal.Home.zen");
			var url = zenPage.GetNewURL(value,"PivotSubscriptions.UI.SubscriptionManager.cls");
			if (url == "" || value == "%SYS") url = homeurl;
			self.document.location = url;
			break;
		case 'PivotSubscriptions':
			if (action=="okay") {
				try {
					self.document.location = zenLink('PivotSubscriptions.UI.SubscriptionManager.cls');
				}
				catch(ex) {
				}
			}
			break;
	}
}

/// Creates edit popup.
ClientMethod editSubscription(subscriptionId, pivotName) [ Internal, Language = javascript ]
{
	var parms = {
			MODE:"models",
	};
	
	zenLaunchPopupWindow('PivotSubscriptions.UI.Dialog.EditSubscription.cls?SUBSCRIPTIONID='+subscriptionId+'&PIVOTNAME='+pivotName,'PivotSubscriptions','status,resizable=yes,width=750,height=500',parms);
}

/// Delete the selected subscription.
ClientMethod deleteSubscription(pID) [ Language = javascript ]
{
	if (pID!="") {
		if (confirm($$$Text('Do you really wish to delete this subscription?'))) {
			this.Delete(pID)
			try {
				self.document.location = zenLink('PivotSubscriptions.UI.SubscriptionManager.cls');
			}
			catch(ex) {
			}
		}
	}
}

/// Delete a subscription.
Method Delete(pID As %Integer) As %String [ ZenMethod ]
{
	Set tMsg = "Subscription Deleted."
	
	Set tSC=##class(PivotSubscriptions.Subscription).%DeleteId(pID)
	If $$$ISERR(tSC) {
		Set tMsg = $System.Status.GetErrorText(tSC)
	}
	
	Quit tMsg
}
}
