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
<column id="Name" colName="Name" header="Name" filterType="text" filterOp="UP[" />
<column id="Pivot" colName="Pivot" header="Pivot" link="./_DeepSee.UserPortal.Analyzer.zen?PIVOT=#(%query.Pivot)#" filterType="text" filterOp="UP[" />
<column id="Emails" colName="Emails" header="Emails" filterType="text" filterOp="UP[" />
<column onclick="zenPage.editSubscription(#(%query.ID)#,'#(%query.Pivot)#')" linkCaption="Edit" link="#"/>
<column onclick="return zenPage.deleteSubscription('#(%query.ID)#');" linkCaption="Delete" link="#" />
<column onclick="return zenPage.sendSubscriptionNow('#(%query.ID)#','#(%query.Pivot)#');" linkCaption="Send Now" link="#" />
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
			var homeurl=zenLink("/csp/sys/%25CSP.Portal.Home.zen");
			var url=zenPage.GetNewURL(value,"PivotSubscriptions.UI.SubscriptionManager.cls");
			if ((url=="") || (value=="%SYS")) {
				url=homeurl;
			}
			self.document.location=url;
			break;
		case 'PivotSubscriptions':
			if (action=="okay") {
				try {
					self.document.location=zenLink('PivotSubscriptions.UI.SubscriptionManager.cls');
				} catch(ex) {
				}
			}
			var table=zenPage.getComponentById('table');
			//refresh data in contact table
			table.executeQuery();
			break;
	}
}

/// Creates edit popup.
ClientMethod editSubscription(pId, pPivot) [ Internal, Language = javascript ]
{
	var parms = {
			MODE:"models",
	};
	
	zenLaunchPopupWindow('PivotSubscriptions.UI.Dialog.EditSubscription.cls?SUBSCRIPTIONID='+pId+'&PIVOTNAME='+pPivot,'PivotSubscriptions','status,resizable=yes,width=700,height=575',parms);
}

/// Delete the selected subscription.
ClientMethod deleteSubscription(pId) [ Language = javascript ]
{
	if (pId!="") {
		if (confirm($$$Text('Do you really wish to delete this subscription?'))) {
			this.Delete(pId)
			try {
				self.document.location=zenLink('PivotSubscriptions.UI.SubscriptionManager.cls');
			} catch(ex) {
			}
		}
	}
}

/// Send the selected subscription now.
ClientMethod sendSubscriptionNow(pId, pPivot) [ Language = javascript ]
{
	if (pId!="") {
		// todo; parameterize default email
		var email=prompt("Do you really wish to send this subscription to this email?", this.GetManagerEmail());
		
		if ((email!=null) && (email!="")) {
			this.SendNow(pId,pPivot,email)
			try {
				self.document.location=zenLink('PivotSubscriptions.UI.SubscriptionManager.cls');
			} catch(ex) {
			}
		}
		
	}
}

/// Delete a subscription.
Method Delete(pId As %Integer) As %String [ ZenMethod ]
{
	Set tSC=$$$OK
	Set tMsg="Subscription Deleted."
	
	Set tSubscription=##class(PivotSubscriptions.Subscription).%OpenId(pId)
	Set tSC=##class(PivotSubscriptions.EventLog).CreateEvent("delete",$username,tSubscription.Pivot,tSubscription.DayOfWeek,tSubscription.Hour,tSubscription.Minute,tSubscription.Format,tSubscription.Emails,tSubscription.Name,.tEvent)
	
	If $$$ISERR(tSC) Quit tSC
	
	Set tSC=##class(PivotSubscriptions.Subscription).%DeleteId(pId)
	If $$$ISERR(tSC) {
		Set tMsg=$System.Status.GetErrorText(tSC)
	}
	Set tSC=tEvent.UpdateStatus(tSC)
	
	Quit tMsg
}

/// Send the selected subscription by calling the SendEmail Class Method of Task
Method SendNow(pId, pPivot, pEmail As %String) As %String [ ZenMethod ]
{
	Set tMsg="Subscription Sent."
	
	If pId'=0 {
		Set tSubscription=##class(PivotSubscriptions.Subscription).%OpenId(pId)
		Set tSC=##class(PivotSubscriptions.Task).SendSubscription(pId, pPivot, pEmail, tSubscription.Format,tSubscription.DayOfWeek,tSubscription.Hour,tSubscription.Minute,tSubscription.Name)
	
		If $$$ISERR(tSC) {
			Set tMsg=$System.Status.GetErrorText(tSC)
		}
	}

	Quit tMsg
}

Method GetManagerEmail() As %String [ ZenMethod ]
{
	Quit ##class(PivotSubscriptions.Utils).GetSettings("AdminEmail")
}

/// Query to get subscriptions for Subscription Manager display table.
Query GetSubscriptionsForDisplay() As %SQLQuery
{
	SELECT ID,Name,Pivot,Emails FROM PivotSubscriptions.Subscription
}

}
