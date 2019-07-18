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
<vgroup valign="top" >
<spacer height="20" />

<label id="AdminEmailLabel" label="Admin Email" />
<text id="AdminEmailText" clientType = "string" />

<spacer height="16" />

<listBox id="HTTPList" label="HTTP or HTTPs?" listWidth="20%"
         value="http://">
  <option value="http://" text="HTTP" />
  <option value="https://" text="HTTPs" />
</listBox>

<spacer height="16" />

<label id="ServerLabel" label="Server" />
<text id="ServerText" clientType = "string" />

<spacer height="16" />

<label id="PortLabel" label="Port Number" />
<text id="PortText" clientType = "string" />

<spacer height="16" />

<button id="SaveButton" caption="Save" onclick="zenPage.ButtonClick();" />

</vgroup>
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
	If $G(^PivotSubscriptions.Settings("AdminEmail")) '= "" {
		Set ..%GetComponentById("AdminEmailText").value = ^PivotSubscriptions.Settings("AdminEmail")
	}
	If $G(^PivotSubscriptions.Settings("Http")) '= "" {
		Set ..%GetComponentById("HTTPList").value = ^PivotSubscriptions.Settings("Http")
	}
	If $G(^PivotSubscriptions.Settings("Server")) '= "" {
		Set ..%GetComponentById("ServerText").value = ^PivotSubscriptions.Settings("Server")
	}
	If $G(^PivotSubscriptions.Settings("Port")) '= "" {
		Set ..%GetComponentById("PortText").value = ^PivotSubscriptions.Settings("Port")
	}
	
	Quit $$$OK
}

ClientMethod ButtonClick() [ Language = javascript ]
{
   	try {
		var adminemail=zen('AdminEmailText').getValue();
		var http=zen('HTTPList').getValue();
		var server=zen('ServerText').getValue();
		var port=zen('PortText').getValue();
		
		var status=zenPage.SaveConfiguration(adminemail,http,server,port);
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
}

Method SaveConfiguration(pAdminEmail, pHttp, pServer, pPort) As %Status [ ZenMethod ]
{
	Set tSC=$$$OK
	
	Set tSC = ##class(PivotSubscriptions.Utility).ConfigureSettings(pAdminEmail, pHttp, pServer, pPort)
	
	Quit tSC
}

}