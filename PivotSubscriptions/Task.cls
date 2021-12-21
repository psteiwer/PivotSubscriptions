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
	
	If ##class(PivotSubscriptions.Utils).GetSettings("TestEnv",0) {
		// Ignore minute for testing purposes
		// This will allow the task to be run on demand and send emails immediately
		// Leaving DayOfWeek and Hour so the scheduled task does not spam emails
		Set tRS=##class(%SQL.Statement).%ExecDirect(,"SELECT ID,Emails,Name,Pivot,Format,DayOfWeek,""Hour"",""Minute"",RunOnce FROM PivotSubscriptions.Subscription WHERE DayOfWeek[? AND ""Hour""=?",tDayOfWeek,tHour)
	} Else {
		Set tRS=##class(%SQL.Statement).%ExecDirect(,"SELECT ID,Emails,Name,Pivot,Format,DayOfWeek,""Hour"",""Minute"",RunOnce FROM PivotSubscriptions.Subscription WHERE DayOfWeek[? AND ""Hour""=? AND ""Minute""=?",tDayOfWeek,tHour,tMinute)
	}
	
	// Loop through Subscription results and send emails.
	While tRS.%Next() {
		Set tID=tRS.%Get("ID")
		Set tEmails=tRS.%Get("Emails")
		Set tPivot=tRS.%Get("Pivot")
		Set tFormat=tRS.%Get("Format")
		Set tDayOfWeek=tRS.%Get("DayOfWeek")
        Set tHour=tRS.%Get("Hour")
        Set tMinute=tRS.%Get("Minute")
        Set tName=tRS.%Get("Name")
        Set tRunOnce=tRS.%Get("RunOnce")
		
		Set tSC = ##class(PivotSubscriptions.Task).SendSubscription(tID,0,tPivot,tEmails,tFormat,tDayOfWeek,tHour,tMinute,tName)
	
		If tRunOnce {
			Set tSC=##class(PivotSubscriptions.EventLog).CreateEvent("delete",tID,$username,tPivot,tDayOfWeek,tHour,tMinute,tFormat,tEmails,tName,tRunOnce,.tDeleteEvent)
            Set tSC=##class(PivotSubscriptions.Subscription).%DeleteId(tID)
            Do tDeleteEvent.UpdateStatus(tSC)
		}
	}
	
	Quit tSC
}

ClassMethod SendSubscription(pID, pSendNow As %Boolean = 0, pPivot As %String, pEmails As %String, pFormat As %String, pDayOfWeek, pHour, pMinute, pName) As %Status
{
	Set tSC=$$$OK
	
	If pName="" {
		Set pName=$E(pPivot,1,*-6)
	}
	
	Try {
		Set tSC=##class(PivotSubscriptions.Task).SendEmail(pID,pSendNow,pPivot,pEmails,pFormat,pName)
	} Catch ex {
		Set tSC=ex.AsStatus()
	}
	
	Quit tSC
}

ClassMethod SendEmail(pID, pSendNow As %Boolean = 0, pPivot As %String, pEmails As %String, pFormat As %String, pName As %String) As %Status
{
	Set tSC=$$$OK
	Set tFilename=""

	Set tEventType=$Select(pSendNow:"sendNow",1:"sendSubscription")
	
	Set mdx=##class(%DeepSee.Utils).%GetMDXFromPivot(pPivot,.tSC,0)
	Set tSubscription=##class(PivotSubscriptions.Subscription).%OpenId(pID)
	
	Set tErrorTypes=##class(PivotSubscriptions.Utils).GetSettings("ErrorTypes")
	
	// Iterate through all subscribers and send emails to each individually
	For tCount=1:1:$l(pEmails,",") {
		Set tEmail=$p(pEmails,",",tCount)

		Set tSC=##class(PivotSubscriptions.EventLog).CreateEvent(tEventType,pID,$username,pPivot,tSubscription.DayOfWeek,tSubscription.Hour,tSubscription.Minute,tSubscription.Format,tEmail,pName,tSubscription.RunOnce,.pEvent)
		If $$$ISERR(tSC) Quit

		Try {
			Set tHasResults=0

			Set tCustomFilter=tSubscription.CustomFilters.GetAt(tEmail)
			Set tSC=##class(PivotSubscriptions.Utils).ExecuteForSubscription(mdx,tCustomFilter,.tHasResults)
			If $$$ISERR(tSC) Quit
			
			If tHasResults {
				// Only generate file if requested pivot has results
				Set tSC=##class(PivotSubscriptions.Utils).GenerateFileForSubscription("Excel",mdx,tCustomFilter,pName,pPivot,.tFilename)
				If $$$ISERR(tSC) Quit
			}

			// Generate email
			// check whether the table generated is too wide/truncated AND whether the table has data
			Set tableStatus=##class(PivotSubscriptions.Utils).CheckTable(pName)
		
			Set server=##class(%Net.SMTP).%New()
			Set server.smtpserver=##class(%SYS.Task.Config).GetData("MailServer")
			Set msg=##class(%Net.MailMessage).%New()
			Set msg.From="PivotSubscriptions"
			Do msg.To.SetAt(tEmail,1)
			
			Set validAdminEmail=##class(PivotSubscriptions.Utils).CheckConfigurationGlobal("AdminEmail")
			
			If validAdminEmail {
				Set msg.ReplyTo=##class(PivotSubscriptions.Utils).GetSettings("AdminEmail")
			}
			
			// Remove ".pivot" extension for subject
			Set msg.Subject=pName
			Set msg.IsBinary=0
			Set msg.IsHTML=1 // Set IsHTML to 1 if email uses HTML

			Set tUnsubscribeList=$LB(tSubscription.%Id(),tEmail,pEvent.GUID)
			
			If tHasResults {
				// Add attachment
				Do ##class(PivotSubscriptions.Utils).WriteEmail(tSubscription,msg,tableStatus,tUnsubscribeList)

				// if table is too large, then just attach Excel instead
				If ((pFormat = "PDF") && (tableStatus)) {
					Set tSC=##class(PivotSubscriptions.Utils).GenerateFileForSubscription("PDF",mdx,tCustomFilter,pName,pPivot,.tFilename)
					If $$$ISERR(tSC) Quit
				} ElseIf 'tableStatus {
					// Check if both configuration settings for admin email is valid before sending error message
					If validAdminEmail {
						Set tReason="TooLarge"
						Do:tErrorTypes[1 ##class(PivotSubscriptions.Utils).TableErrorMessage(tSubscription,tEmail,pName,tReason,mdx,tCustomFilter)
						Set pEvent.TableError=$$$ERROR($$$GeneralError,tReason)
					}
				}
				
				Set tSC=msg.AttachFile("",tFilename)
				If $$$ISERR(tSC) Quit
			} Else {
				Do ##class(PivotSubscriptions.Utils).WriteEmailHeader(msg)
				Do msg.TextData.WriteLine(##class(PivotSubscriptions.Utils).GetSettings("NoDataMessage","No data for requested pivot."))
				Do ##class(PivotSubscriptions.Utils).WriteUnsubscribe(msg,tUnsubscribeList)
				Do ##class(PivotSubscriptions.Utils).WriteEmailFooter(msg)

				If validAdminEmail {
					Set tReason="NoResults"
					Do:tErrorTypes[0 ##class(PivotSubscriptions.Utils).TableErrorMessage(tSubscription,tEmail,pName,tReason,mdx,tCustomFilter)
					Set pEvent.TableError=$$$ERROR($$$GeneralError,tReason)
				}
			}
			
			// Send email
			If tHasResults||##class(PivotSubscriptions.Utils).GetSettings("SendNoData",1) {
				Set tSC=server.Send(msg)
				If $$$ISERR(tSC) Quit
			}
		} Catch ex {
			Set tSC=ex.AsStatus()
		}
		
		Set tSC=pEvent.UpdateStatus(tSC)
			
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
