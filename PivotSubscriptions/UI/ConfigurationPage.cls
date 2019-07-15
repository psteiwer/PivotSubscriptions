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

<spacer height="10" />

<label id="WebServerPortLabel" label="Web Server/Port" />
<text id="WebServerPortText" value="" />

<spacer height="10" />

<label id="NamespaceLabel" label="Application Namespace" />
<text id="NamespaceText" value="" />

<spacer height="10" />

<label id="ApplicationNameLabel" label="Application Name" />
<text id="ApplicationNameText" value="" />


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


}