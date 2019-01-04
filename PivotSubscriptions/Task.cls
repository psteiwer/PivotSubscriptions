Class PivotSubscriptions.Task Extends %SYS.Task.Definition
{

Parameter TaskName = "Pivot Subscriptions Task";

Method OnTask() As %Status
{
	Set tSC=$$$OK
	
	// Default frequency to daily
	Set tFrequency=1
	Set tDayOfWeek=$zd($h,10)
	If tDayOfWeek=5 {
		// Weekly run day is Friday
		// If today is our "Weekly" run day, set tFrequency to "" to get all
		Set tFrequency=""
	}
	Set tRS=##class(%SQL.Statement).%ExecDirect(,"SELECT Emails,Frequency,Pivot FROM PivotSubscriptions.Subscription WHERE Frequency=? OR ? is null",tFrequency,tFrequency)
	
	// Loop through Subscription results for given frequency and send emails.
	While tRS.%Next() {
		Set tEmails=tRS.%Get("Emails")
		Set tPivot=tRS.%Get("Pivot")
		Set tFreq=tRS.%Get("Frequency")
		
		Do ..SendEmail(tPivot,tEmails,tFreq)
	}
	
	Quit tSC
}

ClassMethod SendEmail(pPivot As %String, pEmails As %String, pFrequency As %Integer) As %Status
{
	Set tSC=$$$OK
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
		Set filename=$replace($E(pPivot,1,*-6)_" - "_$zd($h,6),"/","-")_".xls"
	
		Set tSC=##class(%DeepSee.Utils).%ExportExcelToFile(filename,.pParms)
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
		Set msg.IsHTML=0
		
		If tHasResults {
			Do msg.TextData.WriteLine("Attached is the requested Pivot.")

			// Add attachment
			Set status=msg.AttachFile("",filename)
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
			Do ##class(%File).Delete(filename)
		}
	}
	
	Quit tSC
}

}
