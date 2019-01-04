/// Created using the page template: Default
Class PivotSubscriptions.UI.Dialog.EditSubscription Extends %DeepSee.UI.Dialog.standardDialog
{

/// Class name of application this page belongs to.
Parameter APPLICATION;

/// Displayed name of this page.
Parameter PAGENAME;

/// Domain used for localization.
Parameter DOMAIN;

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
<radioSet id="Frequency" label="Frequency" displayList="Daily,Weekly" valueList="1,7" value="1"/>
<radioSet id="Format" label="Format" displayList="Excel,PDF" valueList="Excel,PDF" value="Excel"/>
<textarea id="Emails" label="Email Addresses" hint="Comma separated list of email addresses. '@intersystems.com' appended if no domain supplied."/>
</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit "Add Alert"
}

Method %OnAfterCreatePage() As %Status
{
	If ..SubscriptionId'=0 {
		Set tSubscription=##class(PivotSubscriptions.Subscription).%OpenId(..SubscriptionId)
		Set ..%GetComponentById("SubscriptionId").value=..SubscriptionId
		Set ..%GetComponentById("Frequency").value=tSubscription.Frequency
		Set ..%GetComponentById("Format").value=tSubscription.Format
		Set ..%GetComponentById("Emails").value=tSubscription.Emails
	}

	Set tLabel = ..%GetComponentById("Label")
	Set tLabel.label="Add alert for """_$ZCONVERT(..pivotName,"I","HTML")_""

	Set tOK = ..%GetComponentById("btnOK")
	Set tOK.caption="Add Alert"

	Quit $$$OK
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		
		var subscriptionid=zen('SubscriptionId').getValue();
		var frequency=zen('Frequency').getValue();
		var format=zen('Format').getValue();
		var emails=zen('Emails').getValue();
		var pivot=this.pivotName;
		
		var status=zenPage.AddAlert(subscriptionid,pivot,frequency,emails,format);
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

Method AddAlert(pSubscriptionId,pPivot, pFrequency, pEmails, pFormat) As %Status [ ZenMethod ]
{
	If pSubscriptionId'=0 {
		Set tAlert=##class(PivotSubscriptions.Subscription).%OpenId(pSubscriptionId)
	} Else {
		Set tAlert=##class(PivotSubscriptions.Subscription).%New()
		Set tAlert.CreatedBy=$username
		Set tAlert.Pivot=pPivot
	}
	Set tAlert.Frequency=pFrequency
	Set tAlert.Format=pFormat
	Set tAlert.Emails=pEmails
	Quit tAlert.%Save()
}

}