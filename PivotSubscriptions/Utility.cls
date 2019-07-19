Class PivotSubscriptions.Utility
{

/// Utility method for saving and updating global variables
ClassMethod ConfigureSettings(pAdminEmail, pHttp, pServer, pPort) {
	Set ^PivotSubscriptions.Settings("AdminEmail") = pAdminEmail
	Set ^PivotSubscriptions.Settings("Http") = pHttp
	Set ^PivotSubscriptions.Settings("Server") = pServer
	Set ^PivotSubscriptions.Settings("Port") = pPort
	
	Quit $$$OK
}

ClassMethod CheckConfigurationGlobal(pConfigurationOptionName As %String)
{
	If (pConfigurationOptionName '= "") {
		If (^PivotSubscriptions.Settings(pConfigurationOptionName) '= "") {
			Quit 1
		}
	}

	Quit 0
}

ClassMethod GenerateLink(ByRef link As %String) As %Status 
{
	
	Set tSC=$$$OK
	Set tSC=##class(%Library.RoutineMgr).GetWebServerPort(.p, .h, .up, .url)
	
	If (..CheckConfigurationGlobal("Http")) {
		Set tWebServerPortUrl = ^PivotSubscriptions.Settings("Http")
	} Else {
		Set tWebServerPortUrl = "http://"
	}
	
	If (..CheckConfigurationGlobal("Server")) {
		Set tWebServerPortUrl = tWebServerPortUrl_^PivotSubscriptions.Settings("Server")
	} Else {
		Set tWebServerPortUrl = tWebServerPortUrl_h
	}
	
	If (..CheckConfigurationGlobal("Port")) {
		Set tWebServerPortUrl = tWebServerPortUrl_":"_^PivotSubscriptions.Settings("Port")
	} Else {
		If '(..CheckConfigurationGlobal("Server")) {
			Set tWebServerPortUrl = tWebServerPortUrl_":"_p
		}
	}

	Set tNamespace = $System.CSP.GetDefaultApp($Namespace)
	Set tApplicationName = "/PivotSubscriptions.UI.SubscriptionManager.zen"
	
	Set link = tWebServerPortUrl_tNamespace_tApplicationName
	
	Quit tSC
}

ClassMethod CheckTable(pPivot As %String)
{
	Set tFilename=$replace($zstrip($E(pPivot,1,*-6),"*PC'W",,"/")_" - "_$zd($h,6),"/","-")_".xls"

	// embed pivot table as HTML table to email
	Set tStream=##class(%Stream.FileCharacter).%New()
	Set tSC=tStream.LinkToFile(tFilename)
	
	// check that file is valid file
	If $$$ISERR(tSC) {
		Quit tSC
	}
	
	Set tTableStatus=0
	Set headerCount=0
	// iterate through stream to check that table has actual data
	While 'tStream.AtEnd {
		
		Set line = tStream.ReadLine()
		
		If $Find(line, "<th") {
			Set headerCount = headerCount + 1
		}
		
		If $Find(line, "<td") {
			Set tTableStatus = 1
			// parameterize headerCount
			If (headerCount > 20) {
				Set tTableStatus = 0
			}
			Quit
		}
	}
	
	Quit tTableStatus
}

/// Write header for any email, including styling
ClassMethod WriteEmailHeader(pMsg As %Net.MailMessage) {
	Do pMsg.TextData.WriteLine("<html><head><style>.tab { margin-left: 5%; } .body {font-family: Verdana,sans-serif;font-size: 0.9em;}table.center {width:70%; margin-left:15%; margin-right:15%;}")
	Do pMsg.TextData.WriteLine("table.data {width: 100%;border:0;cellspacing:0;cellpadding:0} center {text-align:center;}")
	Do pMsg.TextData.WriteLine("table.border{font-family: Trebuchet MS, sans-serif;color: white;background-color: #3eb2b4;width:100%;}</style></head>")
	Do pMsg.TextData.WriteLine("<body><table class='center'><tr><td><table class='border'><tr><td>&nbsp;</td></tr></table></tr></td>")
	Do pMsg.TextData.WriteLine("<tr><td><p class='center'>")
}

/// Write footer for any email, including link generation
ClassMethod WriteEmailFooter(pMsg As %Net.MailMessage) {
	Do ##class(PivotSubscriptions.Utility).GenerateLink(.link)

	Do pMsg.TextData.WriteLine("</p></td></tr>")
	Do pMsg.TextData.WriteLine("<tr><td><table><tr><td>&nbsp;</td></tr>")
	Do pMsg.TextData.WriteLine("<tr><td>&nbsp;</td></tr><tr><td>You can manage your subscriptions <i><a href='"_link_"'>here</a></i>.</td></tr><tr><td><i>You can edit days of the week/time/format/recipients and delete in the Subscriptions Manager portal</i>.</td></tr><tr><td>&nbsp;</td></tr></table></td></tr><tr><td>")
	Do pMsg.TextData.WriteLine("<table class='border'><tr><td>&nbsp;</td></tr><tr><td><p class='tab'><i>Pivot Subscriptions</i> by DeepSee</p></td></tr>")
	Do pMsg.TextData.WriteLine("<tr><td><p class='tab'>2019&nbsp;<b>Intersystems Corporation</p></b></td></tr><tr><td><p class='tab'>One Memorial Drive, Cambridge, MA 02142</p></td></tr><tr><td>&nbsp;</td></tr></table></td></tr></table></body></html>")
}

/// Write improved email format for subscription, including embeded pivot table
ClassMethod WriteEmail(pPivot As %String, pMsg As %Net.MailMessage, pTableStatus) {
	Do ##class(PivotSubscriptions.Utility).WriteEmailHeader(pMsg)
	
	Set tFilename=$replace($zstrip($E(pPivot,1,*-6),"*PC'W",,"/")_" - "_$zd($h,6),"/","-")_".xls"

	// embed pivot table as HTML table to email
	Set tStream=##class(%Stream.FileCharacter).%New()
	Set tSC=tStream.LinkToFile(tFilename)
		
	// check subscription to see if its table has error status 
	If pTableStatus {
		// .xls to String stream that is read by line and then written to the email (as HTML) by line	
		While 'tStream.AtEnd {
			Set line=tStream.ReadLine()
	
			// properly center and format table to match the rest of the style of the email
			If line = "<table border=""0"">" {
				Do pMsg.TextData.WriteLine("<table style='width:70%; margin-left:15%; margin-right:15%;'>")
			} ElseIf line = "<table border=""1"">" {
				Do pMsg.TextData.WriteLine("<table border='1' style='width:100%'")
			} ElseIf (	($Find(line, "<x"))
			 			|| ($Find(line, "</x"))
			 			|| ($Find(line, "<body>"))
			 			|| ($Find(line, "<html>"))
						|| (line = "</html>") 
						) {
				Continue
			} Else {
				Do pMsg.TextData.WriteLine(line)
			}
		}
	} Else {
		// custom error message
		Do pMsg.TextData.WriteLine("Pivot table is unpopulated or too big. Please see Excel table.")
	}


	Do ##class(PivotSubscriptions.Utility).WriteEmailFooter(pMsg)
}

ClassMethod SendErrorMessage(pPivot As %String, pEmail As %String) As %Status
{
	Set tLog = ##class(PivotSubscriptions.EventLog).LogEvent("send", $username, pPivot, $ZDATE($HOROLOG,10), $PIECE($ZTIME($PIECE($HOROLOG,",",2),2),":",1), $PIECE($ZTIME($PIECE($HOROLOG,",",2),2),":",2), "", pEmail)
	
	// more meaningful error handling
	If $$$ISERR(tLog) { Quit tLog }
	
	// Generate email
	Set server=##class(%Net.SMTP).%New()
	Set server.smtpserver = ##class(%SYS.Task.Config).GetData("MailServer")
	Set msg=##class(%Net.MailMessage).%New()
	Set msg.From="PivotSubscriptions"
	Set msg.ReplyTo=^PivotSubscriptions.Settings("AdminEmail") // replace with admin email

	// Remove ".pivot" extension for subject
	Set msg.Subject="Table Error detected for "_$E(pPivot,1,*-6)
	Set msg.IsBinary=0
	Set msg.IsHTML=1 // Set IsHTML to 1 if email uses HTML
	
	Do ##class(PivotSubscriptions.Utility).WriteEmailHeader(msg)
	Do msg.TextData.WriteLine("There was an table error detected for <b>"_$E(pPivot,1,*-6)_"</b>, either there being no data populated in the table or the pivot table being too large to be embedded or truncated in the PDF.<br><br>Please check the <i>Subscription Manager</i>.")
	Do ##class(PivotSubscriptions.Utility).WriteEmailFooter(msg)

	// Set recipient of email
	Do msg.To.SetAt(pEmail,1)
			
	// Send email
	Set tSC=server.Send(msg)
}

}
