Class PivotSubscriptions.UI.Dialog.EditSubscription Extends %DeepSee.UI.Dialog.standardDialog
{

/// Class name of application this page belongs to.
Parameter APPLICATION;

/// Displayed name of this page.
Parameter PAGENAME;

Parameter DOMAIN = "PivotSubscriptions";

Property pivotName As %ZEN.Datatype.string(ZENURL = "PIVOTNAME");

Property SubscriptionId As %ZEN.Datatype.integer(ZENURL = "SUBSCRIPTIONID");

Parameter APPLYBUTTON = 0;

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
</style>
}

/// This XML block defines the contents of this page.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" title="">
<label id="Label" label="Edit subscription for "/>
<text id="SubscriptionId" value="0" hidden="true"/>
<multiSelectSet id="DayOfWeek" label="Day(s) Of Week" layout="horizontal" displayList="Sunday,Monday,Tuesday,Wednesday,Thursday,Friday,Saturday" valueList="0,1,2,3,4,5,6"/>
<hgroup>
	<select id="Hour" label="Hour" displayList="00,01,02,03,04,05,06,07,08,09,10,11,12,13,14,15,16,17,18,19,20,21,22,23" valueList="0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23"/>
	<select id="Minute" label="Minute" displayList="00,15,30,45" valueList="0,15,30,45"/>
</hgroup>
<radioSet id="Format" label="Format" displayList="Excel,PDF" valueList="Excel,PDF" value="Excel"/>
<textarea id="Emails" label="Email Addresses" hint="Comma separated list of email addresses."/>
</pane>
}

/// Get the (localized) title string for the dialog.
Method %OnGetTitle() As %String
{
	Quit "Edit Subscription"
}

Method %OnAfterCreatePage() As %Status
{
	If ..SubscriptionId'=0 {
		Set tSubscription=##class(PivotSubscriptions.Subscription).%OpenId(..SubscriptionId)
		Set ..%GetComponentById("SubscriptionId").value=..SubscriptionId
		Set ..%GetComponentById("DayOfWeek").value=tSubscription.DayOfWeek
		Set ..%GetComponentById("Hour").value=tSubscription.Hour
		Set ..%GetComponentById("Minute").value=tSubscription.Minute
		Set ..%GetComponentById("Format").value=tSubscription.Format
		Set ..%GetComponentById("Emails").value=tSubscription.Emails
	}

	Set tLabel = ..%GetComponentById("Label")
	Set tLabel.label="Edit subscription for """_$ZCONVERT(..pivotName,"I","HTML")_""""

	Set tOK = ..%GetComponentById("btnOK")
	Set tOK.caption="Save"

	Quit $$$OK
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		
		var subscriptionid=zen('SubscriptionId').getValue();
		var dayofweek=zen('DayOfWeek').getValue();
		var hour=zen('Hour').getValue();
		var minute=zen('Minute').getValue();
		var format=zen('Format').getValue();
		var emails=zen('Emails').getValue();
		var pivot=this.pivotName;
		
		var status=zenPage.EditSubscription(subscriptionid,pivot,dayofweek,hour,minute,emails,format);
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return '';
}

Method EditSubscription(pSubscriptionId, pPivot, pDayOfWeek, pHour, pMinute, pEmails, pFormat) As %Status [ ZenMethod ]
{
	Set tSC=$$$OK
	Set tLog = 1
	
	If pSubscriptionId'=0 {
		Set tSubscription=##class(PivotSubscriptions.Subscription).%OpenId(pSubscriptionId)
		Set tLog = ##class(PivotSubscriptions.EventLog).LogEvent("update", $username, tSubscription.Pivot, tSubscription.DayOfWeek, tSubscription.Hour, tSubscription.Minute, tSubscription.Format, tSubscription.Emails)
	} Else {
		Set tSubscription=##class(PivotSubscriptions.Subscription).%New()
		Set tSubscription.CreatedBy=$username
		Set tSubscription.Pivot=pPivot
	}
		
	Set tSubscription.DayOfWeek=pDayOfWeek
	Set tSubscription.Hour=pHour
	Set tSubscription.Minute=pMinute
	Set tSubscription.Format=pFormat
	Set tSubscription.Emails=pEmails
	Set tSC=tSubscription.%Save()
	
	// If tLog is still the empty string, then a new subscription was created as tLog would have been initalized if 
	If tLog '= $$$OK {
		Set tLog = ##class(PivotSubscriptions.EventLog).LogEvent("creation", $username, tSubscription.Pivot, tSubscription.DayOfWeek, tSubscription.Hour, tSubscription.Minute, tSubscription.Format, tSubscription.Emails)
	}
	
	Quit tSC
}

}
