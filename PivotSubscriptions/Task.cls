Class PivotSubscriptions.Task Extends %SYS.Task.Definition
{

Parameter TaskName = "Pivot Subscriptions Task";

Method OnTask() As %Status
{
	Set tSC=$$$OK
	
	// Construct current day and time for query
	Set tDayOfWeek=$zd($h,10)
	Set tHour=$p($zt($piece($h,",",2),2),":",1)
	Set tMinute=$p($zt($piece($h,",",2),2),":",2)
	
	If $G(^PivotSubscriptions.Settings("TestEnv")) {
		// Ignore minute for testing purposes
		// This will allow the task to be run on demand and send emails immediately
		// Leaving DayOfWeek and Hour so the scheduled task does not spam emails
		Set tRS=##class(%SQL.Statement).%ExecDirect(,"SELECT Emails,Pivot,Format FROM PivotSubscriptions.Subscription WHERE DayOfWeek[? AND ""Hour""=?",tDayOfWeek,tHour)
	} Else {
		Set tRS=##class(%SQL.Statement).%ExecDirect(,"SELECT Emails,Pivot,Format FROM PivotSubscriptions.Subscription WHERE DayOfWeek[? AND ""Hour""=? AND ""Minute""=?",tDayOfWeek,tHour,tMinute)
	}
	
	// Loop through Subscription results and send emails.
	While tRS.%Next() {
		Set tEmails=tRS.%Get("Emails")
		Set tPivot=tRS.%Get("Pivot")
		Set tFormat=tRS.%Get("Format")
		
		Do ..SendEmail(tPivot,tEmails,tFormat)
	}
	
	Quit tSC
}

// Write improved email format for subscription, including embeded pivot table
ClassMethod WriteEmail(pMsg As %Net.MailMessage, pFilename As %String) {
	Do ##class(PivotSubscriptions.Task).GenerateLink(.link)

	Do pMsg.TextData.WriteLine("<html><head><style>body {font-family: Verdana,sans-serif;font-size: 0.9em;}table.center {width:70%; margin-left:15%; margin-right:15%;}")
	Do pMsg.TextData.WriteLine("table.data {width: 100%;border:0;cellspacing:0;cellpadding:0} table.cell {text-align:center}")
	Do pMsg.TextData.WriteLine("table.border{font-family: Trebuchet MS, sans-serif;color: white;background-color: #3eb2b4;width:100%;}</style></head>")
	Do pMsg.TextData.WriteLine("<body><table class='center'><tr><td><table class='border'><tr><td>&nbsp;</td></tr></table></tr></td>")
	Do pMsg.TextData.WriteLine("<tr><td><table class='table.data'><tr><td>&nbsp;</td></tr><tr><td class='table.cell'>")

	// embed pivot table as HTML table to email
	Set tStream=##class(%Stream.FileCharacter).%New()
	Set tSC=tStream.LinkToFile(pFilename)
	
	// check that file is valid file
	If $$$ISERR(tSC) {
		Do $System.Status.DisplayError(status)
		Quit $$$ERROR()
	}
	
	Set tPopulateStatus=-1
	
	// iterate through stream to check that table has actual data
	While 'tStream.AtEnd {
		Set line = tStream.ReadLine()
		
		If $Find(line, "<td") {
			Set tPopulateStatus = 1
			Quit
		}
	}
	
	// if the pivot table has actual values in the table, print the table
	If tPopulateStatus {
		
		// rewind stream back to start to re-parse table
		Do tStream.MoveTo(1)
		
		// .xls to String stream that is read by line and then written to the email (as HTML) by line	
		While 'tStream.AtEnd {
			Set line=tStream.ReadLine()
	
			// properly center and format table to match the rest of the style of the email
			If line = "<table border=""0"">" {
				Do pMsg.TextData.WriteLine("<table style='width:70%; margin-left:15%; margin-right:15%;'>")
			} ElseIf line = "<table border=""1"">" {
				Do pMsg.TextData.WriteLine("<table border='1' style='width:100%'")
			} ElseIf (	(line = "<x:Name>Results</x:Name>") 
						|| (line = "<x:DoNotDisplayGridlines>False</x:DoNotDisplayGridlines>") 
						|| (line = "<html xmlns:x=3D""urn:schemas-microsoft-com:office:excel"">")
						|| (line = "</html>") 
						) {
				Continue
			} Else {
				Do pMsg.TextData.WriteLine(line)
			}
		}
	} Else {
		Do pMsg.TextData.WriteLine("Pivot table is unpopulated.")
	}

	Do pMsg.TextData.WriteLine("</td></tr></table></td></tr>")
	Do pMsg.TextData.WriteLine("<tr><td><table><tr><td>&nbsp;</td></tr>")
	Do pMsg.TextData.WriteLine("<tr><td>&nbsp;</td></tr><tr><td>You can manage your subscriptions <i><a href='"_link_"'>here</a></i>.</td></tr><tr><td><i>You can edit days of the week/time/format/recipients and delete in the Subscriptions Manager portal</i>.</td></tr><tr><td>&nbsp;</td></tr></table></td></tr><tr><td>")
	Do pMsg.TextData.WriteLine("<table class='border'><tr><td>&nbsp;</td></tr><tr><td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<i>Pivot Subscriptions</i> by DeepSee</td></tr><tr><td>&nbsp;</td></tr>")
	Do pMsg.TextData.WriteLine("<tr><td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&copy;&nbsp;2019&nbsp;<b>Intersystems Corporation</b></td></tr><tr><td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;One Memorial Drive, Cambridge, MA 02142</td></tr><tr><td>&nbsp;</td></tr></table></td></tr></table></body></html>")
}

ClassMethod GenerateLink(ByRef link As %String) As %Status 
{
	
	Set tSC=$$$OK
	
	Set tSC=##class(%Library.RoutineMgr).GetWebServerPort(.p, .h, .up, .url)
	
	If $E(url,$L(url))="/" {
		Set url=$E(url,1,$L(url)-1)
	}
	
	If ($$$ISERR(tSC)) || ($G(url)="") {
		Set url="http://127.0.0.1:57772"
	}
	
	Set url = url_$System.CSP.GetDefaultApp($Namespace)
	
	Set link = url_"/PivotSubscriptions.UI.SubscriptionManager.zen"
	
	Quit tSC
}

ClassMethod SendEmail(pPivot As %String, pEmails As %String, pFormat As %String) As %Status
{
	Set tSC=$$$OK
	Set tFilename = ""
	
	Set mdx=##class(%DeepSee.Utils).%GetMDXFromPivot(pPivot,.tSC,0)
	
	// Execute MDX to see if there are results
	Set tHasResults=0
	Set tRS=##class(%DeepSee.ResultSet).%New()
	Do tRS.%PrepareMDX(mdx)
	Do tRS.%Execute()
	If tRS.%Query.queryType="DRILLTHROUGH" {
		If tRS.listingRows>0 {
			Set tHasResults=1
		}
	} Else {
		If tRS.%GetGrandTotal()'=0 {
			Set tHasResults=1
		}
	}
	
	// Only generate file if requested pivot has results
	If tHasResults {
		Set pParms("TITLE")=$E(pPivot,1,*-6)
		Set pParms("SUBTITLE")="Report generated on "_$zd($h,6)
		Set pParms("MDX")=mdx
		
		Set tFilename=$replace($zstrip($E(pPivot,1,*-6),"*PC'W",,"/")_" - "_$zd($h,6),"/","-")_".xls"
		Set tSC=##class(%DeepSee.Utils).%ExportExcelToFile(tFilename,.pParms)
	}

	// Generate email
	If tSC {
		Set server=##class(%Net.SMTP).%New()
		Set server.smtpserver = ##class(%SYS.Task.Config).GetData("MailServer")
		Set msg=##class(%Net.MailMessage).%New()
		Set msg.From="PivotSubscriptions"
		Set msg.ReplyTo="psteiwer@intersystems.com"
		For count=1:1:$l(pEmails,",") {
			Set tEmail=$p(pEmails,",",count)
			Do msg.To.Insert(tEmail)
		}
		
		// Remove ".pivot" extension for subject
		Set msg.Subject=$E(pPivot,1,*-6)
		Set msg.IsBinary=0
		Set msg.IsHTML=1 // Set IsHTML to 1 if email uses HTML
		
		If tHasResults {
			
			// Add attachment
			Do ##class(PivotSubscriptions.Task).WriteEmail(msg, tFilename)

			If (pFormat = "PDF") {
				Set tFilename = $EXTRACT(tFilename,1,$LENGTH(tFilename)-3) _ "pdf"
				Do ##class(%DeepSee.Utils).%ExportPDFToFile(tFilename,.pParms)
			}
			
			Set status=msg.AttachFile("",tFilename)

			If $$$ISERR(status) 
			{
				Do $System.Status.DisplayError(status)
				Quit $$$ERROR()
			}
		} Else {
			Do msg.TextData.WriteLine("No data for requested pivot.")
		}

		// Send email
		Set tSC=server.Send(msg)
		
		If tHasResults {
			// Delete file
			Do ##class(%File).Delete(tFilename)
		}
	}
	
	Quit tSC
}

/// This method is called each time a new subscription is created. It will create or update the task as needed
ClassMethod ConfigureTask() As %Status
{
	Set tSC=$$$OK
	//Does task exist? If so, update. Else, create
	Set tFullName=..#TaskName_" - "_$NAMESPACE
	Set tTaskID=##class(%SYS.Task).FindId(tFullName)
	If tTaskID="" {
		// Task is not present, need to create one
		Set tTask=##class(%SYS.Task).%New()
		Set tTask.Name=tFullName
		Set tTask.NameSpace=$NAMESPACE
	} Else {
		// Task has already been defined
		Quit tSC
	}
	
	Set tTask.TaskClass="PivotSubscriptions.Task"
	Set tTask.RunAsUser="_SYSTEM"
	Set tTask.Description="Executes PivotSubscriptions Task"
	
	// Set schedule according to passed in parameters
	Set tTask.TimePeriod=0			
	Set tTask.TimePeriodEvery=1 	
	Set tTask.TimePeriodDay=""
	
	// Build runs at most once every day
	Set tTask.DailyFrequency=1
	Set tTask.DailyFrequencyTime=0
	Set tTask.DailyIncrement=15
	Set tTask.DailyStartTime=0
	Set tTask.DailyEndTime=0
	
	// The task should be operational at the next available build time
	Set tSC=tTask.StartDateSet(+$h)
	If $$$ISERR(tSC) Quit
		
	Set tSC=tTask.%Save()
	Quit tSC
}

}
