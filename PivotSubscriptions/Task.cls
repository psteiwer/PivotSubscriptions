Class PivotSubscriptions.Task Extends %SYS.Task.Definition
{

Parameter TaskName = "Pivot Subscriptions Task";

Method OnTask() As %Status
{
	Set tSC=$$$OK
	
	// Construct current day and time for query
	Set tDayOfWeek=$ZDATE($HOROLOG,10)
	Set tHour=$PIECE($ZTIME($PIECE($HOROLOG,",",2),2),":",1)
	Set tMinute=$PIECE($ZTIME($PIECE($HOROLOG,",",2),2),":",2)
	
	If $G(^PivotSubscriptions.Settings("TestEnv")) {
		// Ignore minute for testing purposes
		// This will allow the task to be run on demand and send emails immediately
		// Leaving DayOfWeek and Hour so the scheduled task does not spam emails
		Set tRS=##class(%SQL.Statement).%ExecDirect(,"SELECT Emails,Name,Pivot,Format,DayOfWeek,""Hour"",""Minute"" FROM PivotSubscriptions.Subscription WHERE DayOfWeek[? AND ""Hour""=?",tDayOfWeek,tHour)
	} Else {
		Set tRS=##class(%SQL.Statement).%ExecDirect(,"SELECT Emails,Name,Pivot,Format,DayOfWeek,""Hour"",""Minute"" FROM PivotSubscriptions.Subscription WHERE DayOfWeek[? AND ""Hour""=? AND ""Minute""=?",tDayOfWeek,tHour,tMinute)
	}
	
	// Loop through Subscription results and send emails.
	While tRS.%Next() {
		Set tEmails=tRS.%Get("Emails")
		Set tPivot=tRS.%Get("Pivot")
		Set tFormat=tRS.%Get("Format")
		Set tDayOfWeek=tRS.%Get("DayOfWeek")
        Set tHour=tRS.%Get("Hour")
        Set tMinute=tRS.%Get("Minute")
        Set tName=tRS.%Get("Name")
		
		Set tSC = ##class(PivotSubscriptions.Task).SendSubscription(tPivot,tEmails,tFormat,tDayOfWeek,tHour,tMinute,tName)
	}
	
	Quit tSC
}

ClassMethod SendSubscription(pPivot As %String, pEmails As %String, pFormat As %String, pDayOfWeek, pHour, pMinute, pName) As %Status
{
	Set tSC=$$$OK

	Set tSC=##class(PivotSubscriptions.EventLog).LogEvent("sendSubscription", $username, pPivot, pDayOfWeek, pHour, pMinute, pFormat, pEmails, pName, .pEvent)
	If $$$ISERR(tSC) Quit tSC
	
	If pName="" {
		Set pName=$E(pPivot,1,*-6)
	}
	
	Try {
		Set tSC=##class(PivotSubscriptions.Task).SendEmail(pPivot,pEmails,pFormat,pName)
	} Catch ex {
		Set tSC=ex.AsStatus()
	}
	// Update send event with status and end time
	Set tSC=pEvent.LogUpdate(tSC)
	If $$$ISERR(tSC) Quit tSC
	
	If '(##class(PivotSubscriptions.Utility).CheckTable(pName)) {
		Set tSC=##class(PivotSubscriptions.EventLog).LogEvent("tableError", $username, pPivot, pDayOfWeek, pHour, pMinute, pFormat, pEmails, pName)
		If $$$ISERR(tSC) Quit tSC
	}
	
	Quit tSC
}

ClassMethod SendEmail(pPivot As %String, pEmails As %String, pFormat As %String, pName As %String) As %Status
{
	Set tSC=$$$OK
	Set tFilename=""
	
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
		Set pParms("TITLE")=pName
		Set pParms("SUBTITLE")=$E(pPivot,1,*-6)_". Report generated on "_$zd($h,6)
		Set pParms("MDX")=mdx
		
		Set tFilename=$replace($zstrip(pName,"*PC'W",,"/")_" - "_$zd($h,6),"/","-")_".xls"
		Set tSC=##class(%DeepSee.Utils).%ExportExcelToFile(tFilename,.pParms)
	}
	If $$$ISERR(tSC) Quit tSC

	// Generate email
	If tSC {
		// check whether the table generated is too wide/truncated AND whether the table has data
		Set tableStatus=##class(PivotSubscriptions.Utility).CheckTable(pName)
	
		Set server=##class(%Net.SMTP).%New()
		Set server.smtpserver=##class(%SYS.Task.Config).GetData("MailServer")
		Set msg=##class(%Net.MailMessage).%New()
		Set msg.From="PivotSubscriptions"
		
		Set validAdminEmail=##class(PivotSubscriptions.Utility).CheckConfigurationGlobal("AdminEmail")
		
		If validAdminEmail {
			Set msg.ReplyTo=^PivotSubscriptions.Settings("AdminEmail")
		}
		
		// Remove ".pivot" extension for subject
		Set msg.Subject=pName
		Set msg.IsBinary=0
		Set msg.IsHTML=1 // Set IsHTML to 1 if email uses HTML
		
		If tHasResults {
			
			// Add attachment
			Do ##class(PivotSubscriptions.Utility).WriteEmail(pName, msg, tableStatus)

			// if table is too large, then just attach Excel instead
			If ((pFormat = "PDF") && (tableStatus)) {
				Set tFilename = $EXTRACT(tFilename,1,$LENGTH(tFilename)-3) _ "pdf"
				Do ##class(%DeepSee.Utils).%ExportPDFToFile(tFilename,.pParms)
			} ElseIf 'tableStatus {
				// Check if both configuration settings for admin email is valid before sending error message
				If validAdminEmail {
					Do ##class(PivotSubscriptions.Utility).SendErrorMessage(pPivot,^PivotSubscriptions.Settings("AdminEmail"),pName)
				}
			}
			
			Set status=msg.AttachFile("",tFilename)

			If $$$ISERR(status) {
				Do $System.Status.DisplayError(status)
				Quit $$$ERROR()
			}
		} Else {
			Do ##class(PivotSubscriptions.Utility).WriteEmailHeader(msg)
			Do msg.TextData.WriteLine("No data for requested pivot.")
			Do ##class(PivotSubscriptions.Utility).WriteEmailFooter(msg)
		}

		// iterate through all subscribers and send emails to each individually
		For count=1:1:$l(pEmails,",") {
			Set tEmail=$p(pEmails,",",count)
			Do msg.To.SetAt(tEmail,1)
			
			// Send email
			Set tSC=server.Send(msg)
		}
		
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
		
	Set tSC=tTask.%Save()
	Quit tSC
}

}
