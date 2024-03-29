Include %DeepSee

/// Configuration page that lets users of Pivot Subscriptions to set the default admin's email for table errors and instant emails (sendNow feature), as well as set the generated link to match the application's namespace, webserver/port, and application name.
Class PivotSubscriptions.UI.ConfigurationPage Extends PivotSubscriptions.UI.Template
{

/// Displayed name of this page.
Parameter PAGENAME = "Configuration Page";

/// This XML block defines the contents of this pane.
XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<hgroup valign="top" >
	<spacer width="20" />
	<vgroup cellStyle="padding:2px 0px 6px 2px" enclosingStyle="padding-left:10px;padding-top:20px;" labelPosition="left">
			<text id="AdminEmailText" label="Send error email notification to" size="25" />
			<text id="EmailDomain" label="Email Domain" size="25" />
			<label label="Server Link Configuration" labelClass="sectionCaption" containerStyle="padding-top:5px;padding-bottom:5px;" />
			<radioSet id="HTTPButton" label="HTTP or HTTPS?" displayList="HTTP, HTTPs" valueList="http://,https://" />
			<text id="ServerText" label="Server" size="25" />
			<text id="PortText" label="Port Number" size="25" />
			<label label="No Data Settings" labelClass="sectionCaption" containerStyle="padding-top:5px;padding-bottom:5px;" />
			<radioSet id="NoDataEmail" label="Send No Data Email" displayList="Yes,No" valueList="1,0" value="1"/>
			<textarea id="NoDataMessage" label="No Data Message" cols="50" rows="3" value="No data for requested pivot."/>
			<label label="Custom Emails" labelClass="sectionCaption" containerStyle="padding-top:5px;padding-bottom:5px;" />
			<radioSet id="CustomFooter" label="Custom Footer" displayList="Yes,No" valueList="1,0" value="0"/>
			<textarea id="CustomFooterMessage" label="Custom Footer Message" cols="50" rows="3" value="PivotSubcriptions for InterSystems IRIS Business Intelligence" />
			<label label="Error Emails" labelClass="sectionCaption" containerStyle="padding-top:5px;padding-bottom:5px;" />
			<radioSet id="ChangesOnly" label="New Errors Only" displayList="Yes,No" valueList="1,0" value="0"/>
			<multiSelectSet id="ErrorTypes" label="Optional Error Emails:" layout="horizontal" displayList="No Data,Too Large" valueList="0,1" value="0,1"/>
	</vgroup>
</hgroup>
<hgroup>
	<spacer width="30" />
	<button id="SaveButton" caption="Save" onclick="zenPage.ButtonClick();" />
</hgroup>
</pane>
}

/// Get the (localized) title string for the page.
Method %OnGetTitle() As %String [ Internal ]
{
	Quit $$$Text("Configuration Page","PivotSubscriptions")
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String [ Internal ]
{
	Quit $$$Text("Configuration Page","PivotSubscriptions")
}

/// Get the product name for the page.
Method %OnGetProductName() As %String [ Internal ]
{
	Quit "DeepSee"
}

Method %OnAfterCreatePage() As %Status
{
	// check if each global is instantiated and set only if they aren't empty or nonexsistent
	If ##class(PivotSubscriptions.Utils).GetSettings("AdminEmail")'="" {
		Set ..%GetComponentById("AdminEmailText").value=##class(PivotSubscriptions.Utils).GetSettings("AdminEmail")
	}
	If ##class(PivotSubscriptions.Utils).GetSettings("Http")'="" {
		Set ..%GetComponentById("HTTPButton").value=##class(PivotSubscriptions.Utils).GetSettings("Http")
	}
	If ##class(PivotSubscriptions.Utils).GetSettings("Server")'="" {
		Set ..%GetComponentById("ServerText").value=##class(PivotSubscriptions.Utils).GetSettings("Server")
	}
	If ##class(PivotSubscriptions.Utils).GetSettings("Port")'="" {
		Set ..%GetComponentById("PortText").value=##class(PivotSubscriptions.Utils).GetSettings("Port")
	}
	If ##class(PivotSubscriptions.Utils).GetSettings("SendNoData")'="" {
		Set ..%GetComponentById("NoDataEmail").value=##class(PivotSubscriptions.Utils).GetSettings("SendNoData")
	}
	If ##class(PivotSubscriptions.Utils).GetSettings("NoDataMessage")'="" {
		Set ..%GetComponentById("NoDataMessage").value=##class(PivotSubscriptions.Utils).GetSettings("NoDataMessage")
	}
	If $G(^PivotSubscriptions.Settings("CustomFooter"))'="" {
		Set ..%GetComponentById("CustomFooter").value=^PivotSubscriptions.Settings("CustomFooter")
	}
	If $G(^PivotSubscriptions.Settings("CustomFooterMessage"))'="" {
		Set ..%GetComponentById("CustomFooterMessage").value=^PivotSubscriptions.Settings("CustomFooterMessage")
	}
	If $G(^PivotSubscriptions.Settings("ChangesOnly"))'="" {
		Set ..%GetComponentById("ChangesOnly").value=^PivotSubscriptions.Settings("ChangesOnly")
	}
	If $G(^PivotSubscriptions.Settings("ErrorTypes"))'="" {
		Set ..%GetComponentById("ErrorTypes").value=^PivotSubscriptions.Settings("ErrorTypes")
	}
	If $G(^PivotSubscriptions.Settings("EmailDomain"))'="" {
		Set ..%GetComponentById("EmailDomain").value=^PivotSubscriptions.Settings("EmailDomain")
	}
	
	
	Quit $$$OK
}

ClientMethod ButtonClick() [ Language = javascript ]
{
   	try {
		var adminemail=zen('AdminEmailText').getValue();
		var http=zen('HTTPButton').getValue();
		var server=zen('ServerText').getValue();
		var port=zen('PortText').getValue();
		var nodataemail=zen('NoDataEmail').getValue();
		var nodatamessage=zen('NoDataMessage').getValue();
		var customfooter=zen('CustomFooter').getValue();
		var customfootermessage=zen('CustomFooterMessage').getValue();
		var changesonly=zen('ChangesOnly').getValue();
		var errortypes=zen('ErrorTypes').getValue();
		var emaildomain=zen('EmailDomain').getValue();
		
		var status=zenPage.SaveConfiguration(adminemail,http,server,port,nodataemail,nodatamessage,customfooter,customfootermessage,changesonly,errortypes,emaildomain);
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
}

Method SaveConfiguration(pAdminEmail, pHttp, pServer, pPort, pNoDataEmail, pNoDataMessage, pCustomFooter, pCustomFooterMessage, pChangesOnly, pErrorTypes, pEmailDomain) As %Status [ ZenMethod ]
{
	Set tSC=$$$OK
	
	Set tSC = ##class(PivotSubscriptions.Utils).ConfigureSettings(pAdminEmail, pHttp, pServer, pPort, pNoDataEmail, pNoDataMessage, pCustomFooter, pCustomFooterMessage, pChangesOnly, pErrorTypes, pEmailDomain)
	
	Quit tSC
}

}
