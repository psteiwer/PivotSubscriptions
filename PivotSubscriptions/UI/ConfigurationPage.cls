Include %DeepSee

/// Configuration page that lets users of Pivot Subscriptions to set the default manager's email for table errors and instant emails (sendNow feature), as well as set the generated link to match the application's namespace, webserver/port, and application name.
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

<label id="ManagerEmailLabel" label="Manager Email" />
<text id="ManagerEmailText" value="" />

<spacer height="8" />

<checkbox id ="TableErrorCheckbox" caption="Send Table Error Messages?" value="" />

<spacer height="16" />

<label id="WebServerPortLabel" label="Web Server/Port" />
<text id="WebServerPortText" value="" />

<spacer height="16" />

<label id="NamespaceLabel" label="Application Namespace" />
<text id="NamespaceText" value="" />

<spacer height="16" />

<label id="ApplicationNameLabel" label="Application Name" />
<text id="ApplicationNameText" value="" />

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
	
	If $G(^PivotSubscriptions.Settings("ManagerEmail")) {
		Set ..%GetComponentById("ManagerEmailText").value=^PivotSubscriptions.Settings("ManagerEmail")
	}
	If $G(^PivotSubscriptions.Settings("WebServerPort")) {
		Set ..%GetComponentById("WebServerPortText").value=^PivotSubscriptions.Settings("WebServerPort")
	}
	If $G(^PivotSubscriptions.Settings("Namespace")) {
		Set ..%GetComponentById("NamespaceText").value=^PivotSubscriptions.Settings("Namespace")
	}
	If $G(^PivotSubscriptions.Settings("ApplicationName")) {
		Set ..%GetComponentById("ApplicationNameText").value=^PivotSubscriptions.Settings("ApplicationName")
	}
	If $G(^PivotSubscriptions.Settings("TableError")) {
		Set ..%GetComponentById("TableErrorCheckbox").value=^PivotSubscriptions.Settings("TableError")
	}
	
	Quit $$$OK
}

ClientMethod ButtonClick() [ Language = javascript ]
{
   	try {
		var manageremail=zen('ManagerEmailText').getValue();
		var tableerror=zen('TableErrorCheckbox').getValue();
		var webserverport=zen('WebServerPortText').getValue();
		var namespace=zen('NamespaceText').getValue();
		var application=zen('ApplicationNameText').getValue();
		
		var status=zenPage.SaveConfiguration(manageremail,tableerror,webserverport,namespace,application);
	}
	
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
}

Method SaveConfiguration(pManagerEmail, pTableError, pAppName, pNamespace, pWebPort) As %Status [ ZenMethod ]
{
	Set tSC=$$$OK
	
	Set tSC = ##class(PivotSubscriptions.Utility).ConfigureSettings()
	
	Quit tSC
}

}