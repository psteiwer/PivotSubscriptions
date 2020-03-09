Class PivotSubscriptions.UI.Dialog.EditSubscription Extends %DeepSee.UI.Dialog.standardDialog
{

/// Class name of application this page belongs to.
Parameter APPLICATION;

/// Displayed name of this page.
Parameter PAGENAME;

Parameter DOMAIN = "PivotSubscriptions";

Property pivotName As %ZEN.Datatype.string(ZENURL = "PIVOTNAME");

Property SubscriptionId As %ZEN.Datatype.integer(ZENURL = "SUBSCRIPTIONID");

Property SelectedEmail As %String;

Property CustomFilters As array Of %String;

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
<label id="PivotTable" label="Subscription source: "/>
<text id="SubscriptionId" value="0" hidden="true"/>
<label id="Name" label="Subscription name: "/>
<text id="SubscriptionName" size="40"/>
<radioSet id="RunOnce" label="Run Once?" displayList="No,Yes" valueList="0,1" value="0"/>
<select id="Preset" label="Preset Schedules" displayList="Weekdays,Weekends,Twice Weekly,Three Times Weekly" valueList="0,1,2,3" onchange="zenPage.updateSchedule();"/>
<multiSelectSet id="DayOfWeek" label="Day(s) Of Week" layout="horizontal" displayList="Sunday,Monday,Tuesday,Wednesday,Thursday,Friday,Saturday" valueList="0,1,2,3,4,5,6"/>
<hgroup>
	<select id="Hour" label="Hour" displayList="00,01,02,03,04,05,06,07,08,09,10,11,12,13,14,15,16,17,18,19,20,21,22,23" valueList="0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23"/>
	<select id="Minute" label="Minute" displayList="00,15,30,45" valueList="0,15,30,45"/>
</hgroup>
<radioSet id="Format" label="Format" displayList="Excel,PDF" valueList="Excel,PDF" value="Excel"/>
<textarea id="Emails" label="Email Addresses (Comma separated list)" cols="50" rows="2" onchange="zenPage.populateEmailList();"/>
<spacer height="5px"/>
<hgroup>
	<listBox id="EmailList" listWidth="410px"/>
	<vgroup valign="top">
		<image src="deepsee/close_a_16.png" width="16" height="16" title="Remove the selected email address" onclick="zenPage.removeEmail();"/>
		<image src="deepsee/ds2_magnify_18.png" width="16" height="16" title="Add custom filter" onclick="zenPage.customFilter();"/>
	</vgroup>
</hgroup>
<expando caption="Custom Email" expanded="false">
	<textarea id="CustomEmailText" label="Custom Email Text. Included before Pivot Table in Email." cols="50" rows="5"/>
</expando>
</pane>
}

/// Get the (localized) title string for the dialog.
Method %OnGetTitle() As %String
{
	Quit "Edit Subscription"
}

Method %OnGetSubtitle() As %String
{
	Quit ""
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
		Set ..%GetComponentById("SubscriptionName").value=tSubscription.Name
		Set ..%GetComponentById("CustomEmailText").value=tSubscription.CustomEmailText
		Set ..%GetComponentById("RunOnce").value=tSubscription.RunOnce

		// Populate CustomFilters
		Set tKey=""
		Set tVal=tSubscription.CustomFilters.GetNext(.tKey)
		While tKey'="" {
			// TODO: Check return status
			Do ..CustomFilters.SetAt(tVal,tKey)
			Set tVal=tSubscription.CustomFilters.GetNext(.tKey)
		}
	}

	Set tTable=..%GetComponentById("PivotTable")
	Set tTable.label="Subscription source: """_$ZCONVERT(..pivotName,"I","HTML")_""""

	Set tOK=..%GetComponentById("btnOK")
	Set tOK.caption="Save"
	
	// Populate Email List
	Set tEmails=..%GetComponentById("Emails")
	Set tEmailList=..%GetComponentById("EmailList")
	For emailCount=1:1:$Length(tEmails.value,",") {
		Set tOption=##class(%ZEN.Auxiliary.option).%New()
		Set tOption.value=$Piece(tEmails.value,",",emailCount)
		Set tOption.text=$Piece(tEmails.value,",",emailCount)
		If ..CustomFilters.GetAt(tOption.value)'="" {
			Set tOption.text=tOption.text_" (custom filter)"
		}
		Do tEmailList.options.Insert(tOption)
		Do ..%AddComponent(tOption)
	}

	// Populate Preset Selection Dropdown
	Set tPreset=..%GetComponentById("Preset")
	Set tDayOfWeek=..%GetComponentById("DayOfWeek")
	If tDayOfWeek.value="1,2,3,4,5" {
		Set tPreset.value=0
	} ElseIf tDayOfWeek.value="0,6" {
		Set tPreset.value=1
	} ElseIf tDayOfWeek.value="2,4" {
		Set tPreset.value=2
	} ElseIf tDayOfWeek.value="1,3,5" {
		Set tPreset.value=3
	}	

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
		var name=zen('SubscriptionName').getValue();
		var pivot=this.pivotName;
		var emailtext=zen('CustomEmailText').getValue();
		var runonce=zen('RunOnce').getValue();
		
		var status=zenPage.EditSubscription(subscriptionid,pivot,dayofweek,hour,minute,emails,format,name,emailtext,runonce);

		if (status!=1) {
			alert("Error during save, see Event Log for more details.");
		}
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

Method EditSubscription(pSubscriptionId, pPivot, pDayOfWeek, pHour, pMinute, pEmails, pFormat, pName, pEmailText, pRunOnce) As %Status [ ZenMethod ]
{
	Set tSC=$$$OK
  
	Set tEventType=""
	If pSubscriptionId'=0 {
		Set tSubscription=##class(PivotSubscriptions.Subscription).%OpenId(pSubscriptionId)
		Set tEventType="update"
	} Else {
		Set tSubscription=##class(PivotSubscriptions.Subscription).%New()
		Set tSubscription.CreatedBy=$username
		Set tSubscription.Pivot=pPivot
		Set tEventType="create"
	}
	
	Set tSC=##class(PivotSubscriptions.EventLog).CreateEvent(tEventType,pSubscriptionId,$username,tSubscription.Pivot,tSubscription.DayOfWeek,tSubscription.Hour,tSubscription.Minute,tSubscription.Format,tSubscription.Emails,tSubscription.Name,.tEvent)
	
	Set tSubscription.DayOfWeek=pDayOfWeek
	Set tSubscription.Hour=pHour
	Set tSubscription.Minute=pMinute
	Set tSubscription.Format=pFormat
	Set tSubscription.Emails=pEmails
	Set tSubscription.Name=pName
	Set tSubscription.CustomEmailText=pEmailText
	Set tSubscription.RunOnce=pRunOnce

	// Get Custom Filter info
	Set tKey=""
	Set tVal=..CustomFilters.GetNext(.tKey)
	While tKey'="" {
		// TODO: Check return status
		Do tSubscription.CustomFilters.SetAt(tVal,tKey)
		Set tVal=..CustomFilters.GetNext(.tKey)
	}

	Set tSC=tSubscription.%Save()
	Do tEvent.UpdateStatus(tSC)
	If tSC {
		Do tEvent.UpdateEvent(pDayOfWeek,pHour,pMinute,pFormat,pEmails,pName)
	}

	Quit tSC
}

Method ValidateEmails() As %Status [ ZenMethod ]
{
	Set tSC=$$$OK

	Set tEmails=..%GetComponentById("Emails")
	Set tEmails.value=$zstrip(tEmails.value,"*WC")
	Do {
		Set tUpdated=0
		If $e(tEmails.value,1)="," {
			Set tEmails.value=$e(tEmails.value,2,*)
			Set tUpdated=1
		}
		If $e(tEmails.value,*)="," {
			Set tEmails.value=$e(tEmails.value,1,*-1)
			Set tUpdated=1
		}
	} While tUpdated

	Quit tSC
}

ClientMethod populateEmailList() [ Language = javascript ]
{
	zenPage.ValidateEmails();
	var emailList=zen('EmailList');
	emailList.resetOptions();
	
	var emailText=zen('Emails');
	var emailsString=emailText.value;
	var emailsArray=emailsString.split(",")
	for (i=0;i<emailsArray.length;i++) {
		var email=emailsArray[i];
		var custom="";
		if (zenPage.GetCustomFilter(email)!='') {
			custom=" (custom filter)";
		}
		emailList.appendOption(email,email+custom);
	}
}

/// User clicked the Remove image. Remove the field from Field List box.
ClientMethod removeEmail() [ Language = javascript ]
{
	var emailList=zen('EmailList');
	var emailText=zen('Emails');
	var count=emailList.getOptionCount();
	if (count==0) return;
	var pos=emailList.getProperty("selectedIndex");
	if (pos<0) {
		alert($$$Text("Please select the field you want to remove and try again."));
		return;
	}
	
	var removeValue=emailList.getOptionValue(pos);
	var emailTextValue=emailText.value;
	
	if (pos==0) {
		emailTextValue=emailTextValue.substring(removeValue.length+1,emailTextValue.length);
	} else {
		var removePos=emailTextValue.indexOf(","+removeValue);
		emailTextValue=emailTextValue.substring(0,removePos)+emailTextValue.substring(removeValue.length+removePos+1,emailTextValue.length);
	}
	
	emailText.setValue(emailTextValue);
	emailList.removeOption(pos);
	emailList.setProperty("selectedIndex",-1);
}

ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	switch(popupName) {
	case 'CustomFilter':
		if ((action='ok')||(action='apply')) {
			zenPage.SetCustomFilter(value);
			this.populateEmailList();
		}
		break;
	}
}

Method SetCustomFilter(pExpression) As %Status [ ZenMethod ]
{
	Set tSC=$$$OK

	If pExpression'="" {
		Set tSC=..CustomFilters.SetAt(pExpression,..SelectedEmail)
	}

	Quit tSC
}

Method GetCustomFilter(pEmail) As %String [ ZenMethod ]
{
	Set tFilter=""
	
	// Look for filter in local CustomFilters, this will be populated with saved Subscription Custom Filters when loaded
	Set tFilter=..CustomFilters.GetAt(pEmail)
	
	Quit tFilter
}

ClientMethod updateSchedule() [ Language = javascript ]
{
	var schedule=zen('Preset');
	var dayofweek=zen('DayOfWeek');

	switch(parseInt(schedule.value)) {
		case 0:
			dayofweek.setProperty("value","1,2,3,4,5")
			break;
		case 1:
			dayofweek.setProperty("value","0,6")
			break;
		case 2:
			dayofweek.setProperty("value","2,4")
			break;
		case 3:
			dayofweek.setProperty("value","1,3,5")
			break;
		default:
			break;
	}
	dayofweek.updateValue();
}

ClientMethod customFilter() [ Language = javascript ]
{
	var emailList=zen('EmailList');
	var count=emailList.getOptionCount();
	if (count==0) return;
	var pos=emailList.getProperty("selectedIndex");
	if (pos<0) {
		alert($$$Text("Please select the email you want to add a custom filter for and try again."));
		return;
	}

	// Get Email and store the value
	var emailValue=emailList.getOptionValue(pos);
	this.SelectedEmail=emailValue;

	// Get Cube Name for pivot
	var cubeName=zenPage.GetPivotCube(this.pivotName)

	// Get any existing custom filters
	var expression=zenPage.GetCustomFilter(emailValue);

	// Use AdvancedFilter to allow custom filter to be added
	var parms = {
		CUBE:cubeName,
		EXPRESSION:expression
	};
	// Can I hide the Apply button?
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.AdvancedFilter.zen','CustomFilter','status=no,scrollbars,resizable=yes,width=900,height=600',parms,this);
}

Method GetPivotCube(pPivot) As %String [ ZenMethod ]
{
	Set tCube=""

	// Add error handling?
	Do ##class(%DeepSee.Utils).%GetMDXFromPivot(pPivot,.tSC,0,,.tRS)
	Set tCube=tRS.%GetCubeName()

	Quit tCube
}

}
