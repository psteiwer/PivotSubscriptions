Include %DeepSee

Class PivotSubscriptions.UI.SubscriptionManager Extends %DeepSee.UI.standardPage [ System = 4 ]
{

Parameter DOMAIN = "PivotSubscriptions";

Parameter Version = 1;

/// Displayed name of this page.
Parameter PAGENAME = "Pivot Subscriptions Manager";

/// If this page has multiple views, this is its initial display mode.
Parameter DEFAULTVIEWMODE;

Parameter DOCBOOKID;

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<hgroup valign="top" >
<spacer width="20" />
<vgroup valign="top" >
<spacer height="20" />
<tablePane id="table"
    cellSpacing="2"
	fixedHeaders="false"	
	queryClass="PivotSubscriptions.UI.SubscriptionManager"
	queryName="GetSubscriptionsForDisplay"
	useSnapshot="true"
	showQuery="false"
	showZebra="true"
	showRowNumbers="false"
	maxRows="5000"
	valueColumn="ID"
	>
<column colName="ID" header="Subscription ID" />
<column id="Pivot" header="Pivot" colName="Pivot" width="30%" link="./_DeepSee.UserPortal.Analyzer.zen?PIVOT=#(%query.Pivot)#"/>
<column colName="Emails" header="Emails" />
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
	Quit $$$Text("Pivot Subscriptions Manager","PivotSubscriptions")
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String [ Internal ]
{
	Quit $$$Text("Pivot Subscriptions Manager","PivotSubscriptions")
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
ClientMethod editSubscription(subscriptionId,pivotName) [ Internal, Language = javascript ]
{
	var parms = {
			MODE:"models",
	};
	
	zenLaunchPopupWindow('PivotSubscriptions.UI.Dialog.EditSubscription.cls?SUBSCRIPTIONID='+subscriptionId+'&PIVOTNAME='+pivotName,'PivotSubscriptions','status,resizable=yes,width=900,height=700',parms);
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

/// Query to get subscriptions for Subscription Manager display table.
Query GetSubscriptionsForDisplay() As %SQLQuery
{
	SELECT ID,Pivot,Emails FROM PivotSubscriptions.Subscription
}

}
