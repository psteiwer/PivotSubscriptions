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
	
	// Set tNamespace=##class(%Library.RoutineMgr).NamespaceGet()
	
	Set url=url_"/csp/"_$Namespace_"/"_"PivotSubscriptions.UI.SubscriptionManager.zen"
	
	Set link = url
	
	Quit tSC
}

ClassMethod SendEmail(pPivot As %String, pEmails As %String, pFormat As %String) As %Status
{
	Set tSC=$$$OK
	Set tFilename = ""
	Set tTitle = ""
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
		Set tTitle = $E(pPivot,1,*-6)
		Set pParms("TITLE")=tTitle
		Set pParms("SUBTITLE")="Report generated on "_$zd($h,6)
		Set pParms("MDX")=mdx
		
		// if based on if pdf or excel is selected, change filename accordingly
		
		If (pFormat = "Excel") {
			Set tFilename=$replace($zstrip($E(pPivot,1,*-6),"*PC'W",,"/")_" - "_$zd($h,6),"/","-")_".xls"
			Set tSC=##class(%DeepSee.Utils).%ExportExcelToFile(tFilename,.pParms)
		} Else {
			Set tFilename = $replace($zstrip($E(pPivot,1,*-6),"*PC'W",,"/")_" - "_$zd($h,6),"/","-")_".pdf"
			Set tsc=##class(%DeepSee.Utils).%ExportPDFToFile(tFilename,.pParms)
		}
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
		
			Do ##class(PivotSubscriptions.Task).GenerateLink(.link)
			
			Do msg.TextData.WriteLine("Attached is the requested pivot table and link is here: "_link)
			
			// Add attachment
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
