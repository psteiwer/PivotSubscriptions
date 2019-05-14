Class PivotSubscriptions.UI.Template Extends %DeepSee.UI.standardPage
{

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = $$$Text(..#PAGENAME)

	Set pCommands($I(pCommands)) = $LB("subscriptionManager",$$$Text("Subscription Manager"),$$$Text("Manage Pivot Subscriptions"),"zenPage.navigate('subscriptionManager');")
	Set pCommands($I(pCommands)) = $LB("pivotList",$$$Text("Pivot List"),$$$Text("View All Pivot Tables"),"zenPage.navigate('pivotList');")
	
	Quit $$$OK
}

ClientMethod navigate(pageName) [ Language = javascript ]
{
	var location=""
	if (pageName=='subscriptionManager') {
		location="./PivotSubscriptions.UI.SubscriptionManager.zen"
	} else if (pageName=='pivotList') {
		location="./PivotSubscriptions.UI.PivotList.zen"
	} else {
		// Invalid page name
	}
	
	if (location!="") {
		window.location.href=location;
	}
}

}
