Class PivotSubscriptions.UI.Template Extends %DeepSee.UI.standardPage
{

Parameter DOMAIN = "PivotSubscriptions";

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay=1
	Set pSearchBox=0
	Set pRibbonTitle=$$$Text(..#PAGENAME)

	Set pCommands($I(pCommands))=$LB("newSubscription",$$$Text("New Subscription"),$$$Text("Create new subscription"),"zenPage.newSubscription();")
	Set pCommands($I(pCommands))=$LB("subscriptionManager",$$$Text("Subscription Manager"),$$$Text("Manage Pivot Subscriptions"),"zenPage.navigate('subscriptionManager');")
	// Check for additional permissions?
	Set pCommands($I(pCommands))=$LB("configurationPage",$$$Text("Configuration Page"),$$$Text("Configure Settings"),"zenPage.navigate('configurationPage');")
	Set pCommands($I(pCommands))=$LB("eventLogViewer",$$$Text("Event Log Viewer"),$$$Text("Event Log Viewer"),"zenPage.navigate('eventLogViewer');")

	Quit $$$OK
}

ClientMethod navigate(pageName) [ Language = javascript ]
{
	var location=""
	if (pageName=='subscriptionManager') {
		location="./PivotSubscriptions.UI.SubscriptionManager.zen"
	} else if (pageName=='pivotList') {
		location="./PivotSubscriptions.UI.PivotList.zen"
	} else if (pageName=='configurationPage') {
		location="./PivotSubscriptions.UI.ConfigurationPage.zen"
	} else if (pageName='eventLogViewer') {
		location="./PivotSubscriptions.UI.EventLogViewer.zen"
	} else {
		// Invalid page name
	}
	
	if (location!="") {
		window.location.href=location;
	}
}

/// Creates edit popup.
ClientMethod newSubscription() [ Internal, Language = javascript ]
{
	var parms = {
		MODE:"models",
	};
	
	zenLaunchPopupWindow('PivotSubscriptions.UI.Dialog.EditSubscription.cls','PivotSubscriptions','status,resizable=yes,width=700,height=610',parms);
}

}
