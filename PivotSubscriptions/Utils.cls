Class PivotSubscriptions.Utils
{

ClassMethod GetVersion() As %String
{
	Quit "v1.7.0"
}

/// Utility method for saving and updating global variables
ClassMethod ConfigureSettings(pAdminEmail, pHttp, pServer, pPort, pNoDataEmail, pNoDataMessage, pCustomFooter, pCustomFooterMessage, pChangesOnly, pErrorTypes, pEmailDomain)
{
	Set ^PivotSubscriptions.Settings("AdminEmail")=pAdminEmail
	Set ^PivotSubscriptions.Settings("Http")=pHttp
	Set ^PivotSubscriptions.Settings("Server")=pServer
	Set ^PivotSubscriptions.Settings("Port")=pPort
	Set ^PivotSubscriptions.Settings("SendNoData")=pNoDataEmail
	Set ^PivotSubscriptions.Settings("NoDataMessage")=pNoDataMessage
	Set ^PivotSubscriptions.Settings("CustomFooter")=pCustomFooter
	Set ^PivotSubscriptions.Settings("CustomFooterMessage")=pCustomFooterMessage
	Set ^PivotSubscriptions.Settings("ChangesOnly")=pChangesOnly
	Set ^PivotSubscriptions.Settings("ErrorTypes")=pErrorTypes
	Set ^PivotSubscriptions.Settings("EmailDomain")=pEmailDomain
	
	Quit $$$OK
}

ClassMethod CheckConfigurationGlobal(pConfigurationOptionName As %String)
{
	If ((pConfigurationOptionName'="") && $DATA(^PivotSubscriptions.Settings(pConfigurationOptionName))) {
		If ##class(PivotSubscriptions.Utils).GetSettings(pConfigurationOptionName)'="" {
			Quit 1
		}
	}

	Quit 0
}

ClassMethod GetSettings(pSetting As %String, pDefaultValue As %String = "") As %String
{
	Quit $G(^PivotSubscriptions.Settings(pSetting),pDefaultValue)
}

ClassMethod GenerateLink(ByRef pLink As %String = "") As %Status
{
	Set tSC=$$$OK
	
	Set tSC=##class(%Library.RoutineMgr).GetWebServerPort(.p,.h,.up,.url)
	If $$$ISERR(tSC) Quit tSC
	
	If ..CheckConfigurationGlobal("Http") {
		Set pLink=##class(PivotSubscriptions.Utils).GetSettings("Http")
	} Else {
		Set pLink="http://"
	}
	
	If ..CheckConfigurationGlobal("Server") {
		Set pLink=pLink_##class(PivotSubscriptions.Utils).GetSettings("Server")
	} Else {
		Set pLink=pLink_h
	}
	
	If ..CheckConfigurationGlobal("Port") {
		Set pLink=pLink_":"_##class(PivotSubscriptions.Utils).GetSettings("Port")
	} Else {
		If '..CheckConfigurationGlobal("Server") {
			Set pLink=pLink_":"_p
		}
	}
	
	Quit tSC
}

ClassMethod CheckTable(pName As %String, pFilename As %String) As %Status
{
	If pFilename="" {
		Quit 0
	}
	// embed pivot table as HTML table to email
	Set tStream=##class(%Stream.FileCharacter).%New()
	Set tSC=tStream.LinkToFile(pFilename)
	
	// check that file is valid file
	If $$$ISERR(tSC) Quit tSC
	
	Set tTableStatus=0
	Set tHeaderCount=0

	If $e(pFilename,*-2,*)="csv" {
		Set tLineCount=0
		While 'tStream.AtEnd {
			Set tLine=tStream.ReadLine()
			Set tLineCount=$I(tLineCount)
			
			If tLineCount=4 {
				Set tHeaderCount=$L(tLine,",")
			}
		}

		If (tHeaderCount<15) && (tLineCount<50) {
			Set tTableStatus=1
		}
	} Else {
		// iterate through stream to check that table has actual data
		While 'tStream.AtEnd {
			Set tLine=tStream.ReadLine()
			
			If $Find(tLine,"<th") {
				Set tHeaderCount=tHeaderCount+1
			}
			
			If $Find(tLine,"<td") {
				Set tTableStatus=1
				// parameterize headerCount
				If (tHeaderCount > 20) {
					Set tTableStatus=0
				}
				Quit
			}
		}
	}
	
	Quit tTableStatus
}

/// Write header for any email, including styling
ClassMethod WriteEmailHeader(pMsg As %Net.MailMessage)
{
	Do pMsg.TextData.WriteLine("<html><head><style>.tab { margin-left: 5%; } .body {font-family: Verdana,sans-serif;font-size: 0.9em;}table.center {width:70%; margin-left:15%; margin-right:15%;}")
	Do pMsg.TextData.WriteLine("table.data {width: 100%;border:0;cellspacing:0;cellpadding:0} center {text-align:center;}")
	Do pMsg.TextData.WriteLine("table.border{font-family: Trebuchet MS, sans-serif;color: white;background-color: #3eb2b4;width:100%;}</style></head>")
	Do pMsg.TextData.WriteLine("<body><table class='center'><tr><td><table class='border'><tr><td>&nbsp;</td></tr></table></tr></td>")
	Do pMsg.TextData.WriteLine("<tr><td><p class='center'>")
}

ClassMethod WriteUnsubscribe(pMsg As %Net.MailMessage, pUnsubscribeList)
{
	Do ##class(PivotSubscriptions.Utils).GenerateLink(.tLink)
	Set tLink=tLink_"/api/pivotsubscriptionsunsubscribe/unsubscribe/"
	Set tLink=tLink_$LTS(pUnsubscribeList,"/")
	
	Do pMsg.TextData.WriteLine("</p></td></tr>")
	Do pMsg.TextData.WriteLine("<tr><td><table><tr><td>&nbsp;</td></tr>")
	Do pMsg.TextData.WriteLine("<tr><td>&nbsp;</td></tr><tr><td>To Unsubscribe, <i><a href='"_tLink_"'>click here</a></i>.</td></tr><tr><td><i>You can edit days of the week/time/format/recipients and delete in the Subscriptions Manager portal</i>.</td></tr><tr><td>&nbsp;</td></tr></table></td></tr><tr><td>")
}

/// Write footer for any email, including link generation
ClassMethod WriteEmailFooter(pMsg As %Net.MailMessage)
{
	Do pMsg.TextData.WriteLine("<table class='border'><tr><td>&nbsp;</td></tr><tr><td><p class='tab'>")
	If ^PivotSubscriptions.Settings("CustomFooter") {
		Do pMsg.TextData.WriteLine(^PivotSubscriptions.Settings("CustomFooterMessage"))
	} Else {
		Do pMsg.TextData.WriteLine("PivotSubcriptions for InterSystems IRIS Business Intelligence")
	}
	Do pMsg.TextData.WriteLine("</td></tr><tr><td>&nbsp;</td></tr></table></td></tr></table></body></html>")
}

/// Write improved email format for subscription, including embeded pivot table
ClassMethod WriteEmail(pSubscription As PivotSubscriptions.Subscription, pMsg As %Net.MailMessage, pTableStatus, pUnsubscribeList, pFilename)
{
	Do ##class(PivotSubscriptions.Utils).WriteEmailHeader(pMsg)

	Set tName=pSubscription.Name
	If tName="" {
		Set tName=$E(pSubscription.Pivot,1,*-6)
	}

	// embed pivot table as HTML table to email
	Set tStream=##class(%Stream.FileCharacter).%New()
	Set tSC=tStream.LinkToFile(pFilename)
	If $$$ISERR(tSC) Quit tSC
		
	// check subscription to see if its table has error status 
	If pTableStatus {
		// Include link to view in Analyzer
		Set tSC=##class(PivotSubscriptions.Utils).GenerateLink(.tAnalyzerURL)
		If $$$ISERR(tSC) Quit
		Set tAnalyzerURL=tAnalyzerURL_$system.CSP.GetDefaultApp($namespace)_"/_DeepSee.UI.Analyzer.zen?PIVOT="_pSubscription.Pivot
		Do pMsg.TextData.WriteLine("<a href='"_tAnalyzerURL_"'>Click Here</a> to view the pivot table in your browser.")

		// Include Subscription's custom email text
		If pSubscription.CustomEmailText'="" {
			Do pMsg.TextData.WriteLine(pSubscription.CustomEmailText)
		}

		If $p(pFilename,".",*)="csv" {
			Do pMsg.TextData.WriteLine("<p>")
			While 'tStream.AtEnd {
				Set tLine=tStream.ReadLine()
				Do pMsg.TextData.WriteLine(tLine)
				Do pMsg.TextData.WriteLine("</br>")
			}
			Do pMsg.TextData.WriteLine("</p>")
		} Else {
			// .xls to String stream that is read by line and then written to the email (as HTML) by line	
			While 'tStream.AtEnd {
				Set tLine=tStream.ReadLine()
		
				// properly center and format table to match the rest of the style of the email
				If tLine="<table border=""0"">" {
					Do pMsg.TextData.WriteLine("<table style='width:70%; margin-left:15%; margin-right:15%;'>")
				} ElseIf tLine="<table border=""1"">" {
					Do pMsg.TextData.WriteLine("<table border='1' style='width:100%'")
				} ElseIf (($Find(tLine,"<x"))||($Find(tLine,"</x"))||($Find(tLine,"<body>"))||($Find(tLine,"<html>"))||(tLine="</html>")) {
					Continue
				} Else {
					// If 'Short Date' exists, the time value has been changed to excel format
					If ($Find(tLine,"'Short Date'")) {
						Set tTimeStartPos=$Find(tLine,"'Short Date'")+2
						Set tTimeEndPos=$Find(tLine,"<",tTimeStartPos)-2
						Set tTime=$E(tLine,tTimeStartPos,tTimeEndPos)
						Set tTime=tTime+$ZDateH("12/30/1899")
						// Insert the new date display, using the default DeepSee date display option
						Set tLine=$E(tLine,1,tTimeStartPos-1)_$ZDate(tTime,6)_$E(tLine,tTimeEndPos+1,*)
					}
					Do pMsg.TextData.WriteLine(tLine)
				}
			}
		}
	} Else {
		// custom error message
		Do pMsg.TextData.WriteLine("Pivot table is too big to be embedded. Please see attachment.")
	}

	Do ##class(PivotSubscriptions.Utils).WriteUnsubscribe(pMsg,pUnsubscribeList)
	Do ##class(PivotSubscriptions.Utils).WriteEmailFooter(pMsg)
}

ClassMethod TableErrorMessage(pSubscription As PivotSubscriptions.Subscription, pEmail As %String, pName As %String, pReason As %String, pMDX As %String, pCustomFilter As %String = "") As %Status
{
	Set tSC=$$$OK

	Set tAdminEmail=##class(PivotSubscriptions.Utils).GetSettings("AdminEmail")
	Set tLog=##class(PivotSubscriptions.EventLog).CreateEvent("tableError",pSubscription.%Id(),$username,pSubscription.Pivot,pSubscription.DayOfWeek,pSubscription.Hour,pSubscription.Minute,pSubscription.Format,tAdminEmail,pName,pSubscription.RunOnce,.pEvent)

	If $$$ISERR(tLog) Quit tLog

	Set tSC=##class(PivotSubscriptions.Utils).LastSubscriptionStatus(.tLastStatus,pName,pEmail)
	If $$$ISERR(tSC) Quit tSC
	If ##class(PivotSubscriptions.Utils).GetSettings("ChangesOnly") && $$$ISERR(tLastStatus) {
		Set tSC=pEvent.UpdateStatus($$$ERROR($$$GeneralError,"StatusNotChanged"))
		Quit tSC
	}
	
	// Generate email
	Set tServer=##class(%Net.SMTP).%New()
	Set tServer.smtpserver = ##class(%SYS.Task.Config).GetData("MailServer")
	Set tMsg=##class(%Net.MailMessage).%New()
	Set tMsg.From="PivotSubscriptions"
	Set tMsg.ReplyTo=tAdminEmail // replace with admin email

	// Remove ".pivot" extension for subject
	Set tMsg.Subject="Table Error detected for "_pName
	Set tMsg.IsBinary=0
	Set tMsg.IsHTML=1 // Set IsHTML to 1 if email uses HTML
	
	Do ##class(PivotSubscriptions.Utils).WriteEmailHeader(tMsg)
	Do tMsg.TextData.WriteLine("There was an table error detected for <b>"_pName_"</b> based on <b>"_$E(pSubscription.Pivot,1,*-6)_"</b>.")
	If pReason="NoResults" {
		Do tMsg.TextData.WriteLine("No data populated for table/filters.<br>")
	} ElseIf pReason="TooLarge" {
		Do tMsg.TextData.WriteLine("The pivot table is too large to be embedded.<br>")
	}
	
	// Generate Event Log Viewer URL
	Set tSC=##class(PivotSubscriptions.Utils).GenerateLink(.tEventLogURL)
	If $$$ISERR(tSC) Quit
	Set tEventLogURL=tEventLogURL_$system.CSP.GetDefaultApp($namespace)_"/PivotSubscriptions.UI.EventLogViewer.zen"
	
	Do tMsg.TextData.WriteLine("<br>Please check the <a href='"_tEventLogURL_"'>Event Log Viewer</a>.")
	Do tMsg.TextData.WriteLine("<br/><br/>MDX Executed:")
	Do tMsg.TextData.WriteLine(pMDX)
	If pCustomFilter'="" {
		Do tMsg.TextData.WriteLine("<br/><br/>Custom Filter:")
		Do tMsg.TextData.WriteLine(pCustomFilter)
	}
	Do ##class(PivotSubscriptions.Utils).WriteEmailFooter(tMsg)

	// Set recipient of email
	Do tMsg.To.SetAt(tAdminEmail,1)
	
	// Send email
	Set tSC=tServer.Send(tMsg)
	Set tSC=pEvent.UpdateStatus($$$ERROR($$$GeneralError,pReason))
	
	Quit tSC
}

ClassMethod ActionCommand(ByRef pContext As %ZEN.proxyObject) As %String
{
	Set tCommand=""
	If pContext.dataSource'="" {
		Set tCommand="popup:PivotSubscriptions.UI.Dialog.EditSubscription.cls?SUBSCRIPTIONID=0&PIVOTNAME="_$zconvert(pContext.dataSource,"O","URL")
	}

	Quit tCommand
}

ClassMethod LastSubscriptionStatus(ByRef pLastStatus, pName, pEmail) As %Status
{
	Set tSC=$$$OK
	Set pLastStatus=$$$OK

	Set tSQL="SELECT TableError From PivotSubscriptions.EventLog WHERE Name=? AND Emails=? AND ((EventType='sendSubscription') OR (EventType='sendNow')) ORDER BY ID Desc"
	Set tSQLRS=##class(%SQL.Statement).%ExecDirect(,tSQL,pName,pEmail)
	Do tSQLRS.%Next()
	Do tSQLRS.%Next()
	Set pLastStatus=tSQLRS.TableError

	Quit tSC
}

ClassMethod ExecuteForSubscription(pMDX, pCustomFilter = "", ByRef pHasResults = 0) As %Status
{
	Set tSC=$$$OK

	If pCustomFilter'="" {
		Set pMDX=pMDX_" %FILTER "_pCustomFilter
	}

	// Execute MDX to see if there are results
	Set pHasResults=0
	Set tRS=##class(%DeepSee.ResultSet).%New()
	Do tRS.%PrepareMDX(pMDX)
	Do tRS.%Execute()
	If tRS.%Query.queryType="DRILLTHROUGH" {
		If tRS.listingRows>0 {
			Set pHasResults=1
		}
	} Else {
		If tRS.%GetGrandTotal()'=0 {
			Set pHasResults=1
		}
	}

	Quit tSC
}

ClassMethod GenerateFileForSubscription(pType = "Excel", pMDX, pCustomFilter, pName, pPivot, ByRef pFilename = "") As %Status
{
	Set tSC=$$$OK

	If pCustomFilter'="" {
		Set pMDX=pMDX_" %FILTER "_pCustomFilter
	}

	Set pParms("TITLE")=pName
	Set pParms("SUBTITLE")=$E(pPivot,1,*-6)_". Report generated on "_$zd($h,6)
	Set pParms("MDX")=pMDX
	
	If pType="Excel" {
		Set pFilename=$replace($zstrip(pName,"*PC'W",,"/")_" - "_$zd($h,6),"/","-")_".xls"
		Set tSC=##class(%DeepSee.Utils).%ExportExcelToFile(pFilename,.pParms)
	} ElseIf pType="CSV" {
		Set pFilename=$replace($zstrip(pName,"*PC'W",,"/")_" - "_$zd($h,6),"/","-")_".csv"
		Set tSC=##class(%DeepSee.Utils).%ExportCSVToFile(pFilename,.pParms,.tFilename)
		Set pFilename=tFilename
	} Else {
		Set pFilename = $EXTRACT(pFilename,1,$LENGTH(pFilename)-3) _ "pdf"
		Do ##class(%DeepSee.Utils).%ExportPDFToFile(pFilename,.pParms)
	}
	
	Quit tSC
}

ClassMethod CheckUnsubscribe(pSubscriptionId, pEmail, pGUID) As %Boolean
{
	Set tConfirmed=0

	Set tSQL="SELECT ID FROM PivotSubscriptions.EventLog WHERE Subscription=? AND Emails=? AND GUID=?"
	Set tSQLRS=##class(%SQL.Statement).%ExecDirect(,tSQL,pSubscriptionId,pEmail,pGUID)
	Set tConfirmed=tSQLRS.%Next()

	Quit tConfirmed
}

}
