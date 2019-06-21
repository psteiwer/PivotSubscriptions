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
	Set tRS=##class(%SQL.Statement).%ExecDirect(,"SELECT Emails,Pivot,Format FROM PivotSubscriptions.Subscription WHERE DayOfWeek[? AND ""Hour""=? AND ""Minute""=?",tDayOfWeek,tHour,tMinute)
	
	// Loop through Subscription results and send emails.
	While tRS.%Next() {
		Set tEmails=tRS.%Get("Emails")
		Set tPivot=tRS.%Get("Pivot")
		Set tFormat=tRS.%Get("Format")
		
		Do ..SendEmail(tPivot,tEmails,tFormat)
	}
	
	Quit tSC
}

// unit test manager
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
			Do msg.TextData.WriteLine("Attached is the requested Pivot.")
			
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

/*
 * Modify print method of DeepSee to output to String instead of console
*/
Method %PrintString(Output pStats, pShowNodeNo As %Boolean = 0, pMaxRows As %Integer = 0) As %Status
{
	Set tSC = $$$OK
	Try {
		If ((%DeepSee.ResultSet.%Query.queryType = "CREATE")||(%DeepSee.ResultSet.queryType = "DROP")) {
			Quit
		}

		// wait a small time in case a background has not yet reported a error
		Hang 0.01

		Set pMaxRows = $S(pMaxRows>10:pMaxRows-10,1:0)

		Set tError = $G($$$DeepSeeResultsGLVN(%DeepSee.ResultSet.%CubeKey,%DeepSee.ResultSet.%QueryKey,"error"))
		If (tError'="") {
			Set tSC = tError
		}

		If $$$ISERR(tSC) {
			Do $System.Status.DisplayError(tSC)
			W !
			Set tSC = $$$OK
			Quit
		}

		Set tStatus = %DeepSee.ResultSet.%GetQueryStatus(%DeepSee.ResultSet.%Cube,%DeepSee.ResultSet.%QueryKey)
		If (tStatus < 100) {
			Write $$$Text("Result has errors or is not ready to be printed. Status: ","%DeepSee"),tStatus,!
			Quit
		}
		Set tAxisCount = ..%GetAxisCount()
		Set tShowNodeNums = pShowNodeNo

		If (%DeepSee.ResultSet.%Query.queryType = "DRILLTHROUGH") {
			Do %DeepSee.ResultSet.%PrintListing()
			If (%DeepSee.ResultSet.%Query.showPlan) {
				Do ..%ShowPlan()
			}
			Quit
		}

		// test for default format
		Set tDefFormat = $G($$$DeepSeeResultsGLVN(..%CubeKey,..%QueryKey,"format"))

		If (tAxisCount=0) {
			// single value answer
			Set tValue = ..%GetValue()
			Set tCellWidth = 20
			Write $$$Text("Result","%DeepSee"),":"
			// JMD1412
			If ((tValue'="")&&(tDefFormat'="")) {
				Write $J(%DeepSee.ResultSet.%FormatNumber(tValue,tDefFormat),tCellWidth),!
			}
			Else {
				Write $J($S(tValue="":"*",tValue'=+tValue:tValue,1:$FN(tValue,",")),tCellWidth),!
			}
			If (%DeepSee.ResultSet.%Query.showPlan) {
				Do %DeepSee.ResultSet.%ShowPlan()
			}
			Quit
		}

		For a = 1:1:tAxisCount {
			Set tAxisSize(a) = %DeepSee.ResultSet.%GetAxisSize(a)
			Set tAxisIsSearch(a) = %DeepSee.ResultSet.Query.axes.GetAt(a).%IsSearch()		// DTB141
		}

		Set tVolume = %DeepSee.ResultSet.%GetCellCount(..%CubeKey,..%QueryKey,.tSC)
		If $$$ISERR(tSC) {
			Do $System.Status.DisplayError(tSC)
			Quit
		}

		// Get row and column info
		Set tStart = $ZH
		Set tColCount = +$G(tAxisSize(1))

		If ((tVolume = 0)||(tColCount=0)) {
			Write $$$Text("ResultSet has found no results","%DeepSee"),!
			// Write "Volume: ",tVolume,?20,"Columns: ",tColCount,!
			If (%DeepSee.ResultSet.%Query.showPlan) {
				Do %DeepSee.ResultSet.%ShowPlan()
			}
			Quit
		}

		// JMD1406: if we have a 3rd axis, pick up its format
		Set tZCount = +$G(tAxisSize(3))
		If (tZCount>0) {
			Set z = ..%GetOrdinalLabel(.tZNames,3,1,.tZFormat,.tZSolveOrder)
			Set tDefFormat = tZFormat
		}

		// column headers
		For c=1:1:$G(tAxisSize(1)) {
			Set tLabelCount = ..%GetOrdinalLabel(.tNames,1,c,.tFormat,.tSolveOrder)
			Set tName = $G(tNames(1))
			Set:tFormat'="" tColFormat(c) = tFormat
			Set:tSolveOrder>0 tColSolveOrder(c) = tSolveOrder
			If (tShowNodeNums) {
				Set tColNodes(c) = $G($$$DeepSeeResultsGLVN(..%CubeKey,..%QueryKey,"leaf",1,c))
			}
			Set tColNames(c) = tName
		}

		Set tHasRows = 1
		Set tRowCount = +$G(tAxisSize(2))
		If (tRowCount < 1) {
			Set tHasRows = 0
			Set tRowCount = 1
		}

		Set tLblWidth = 18
		Set tTotal = 0
		Set tCells = 0
		Set tEmptyCells = 0

		Set tHasOverride = ..%HasCellFormatOverride()

		// print
		Set tDisplayedColCount = tColCount
		Set tTruncated = 0
		If (tDisplayedColCount > 6) {
			Set tDisplayedColCount = 6
			Set tTruncated = 1
		}
		If (tDisplayedColCount = 1) {
			Set tLblWidth = 24
		}
		Set tCellWidth = (80 \ (tDisplayedColCount + 1)) - 4
		Set:tCellWidth>18 tCellWidth = 18 
		For c = 1:1:tDisplayedColCount {
			Set tName = $E(tColNames(c),1,tCellWidth-$S(tShowNodeNums:4,1:0)) _ $S(tShowNodeNums:"["_tColNodes(c)_"]",1:"")
			Write ?(c-1)*(tCellWidth+3)+tLblWidth,$J(tName,tCellWidth)
		}
		Write:tTruncated ?76,"..."
		Write !

		// how many digits are needed for row #
		Set tRowDigits = 0
		If (tRowCount>1) {
			Set tRowDigits = (1+$ZLOG(tRowCount))\1
			Set tLblWidth = tLblWidth - tRowDigits
		}

		Set tRowsSkipped = 0
		For r = 1:1:tRowCount {
			Set tRowSolveOrder = 0
			Set tName = ""		// DTB141
			If (tHasRows) {
				Set tLabelCount = ..%GetOrdinalLabel(.tLabels,2,r,.tRowFormat,.tRowSolveOrder)
				For n=tLabelCount:-1:1 {
					Set tName = tName _ $S(tName="":"",1:"->")_ tLabels(n)
				}
			}
			ElseIf tAxisIsSearch(1) {		// DTB141
				Set tName = $$$Text("Results","%DeepSee")
			}
			
			Set tCells = tCells + tColCount
			If (pMaxRows>0) {
				If ((r > pMaxRows)&&('tRowsSkipped)) {
					Write ".......","rows not displayed",".......",!
					Set tRowsSkipped = 1
					Continue
				}
				ElseIf ((r > pMaxRows)&&(r < (tRowCount-10))) {
					// show last 10 rows
					Continue
				}
			}

			Set tName = $E(tName,1,$S(tShowNodeNums:tLblWidth-4,1:tLblWidth))
			If (tShowNodeNums) {
				Set tName = tName _ "[" _ $G($$$DeepSeeResultsGLVN(..%CubeKey,..%QueryKey,"leaf",2,r)) _ "]"
			}
			// Show row # as well
			Write:tRowDigits>0 $J(r,tRowDigits)," "
			Write tName
			For c = 1:1:tDisplayedColCount {
				Set tValue = $Case(tAxisCount,
					1:..%GetOrdinalValue(c),
					:..%GetOrdinalValue(c,r))

				If (+$G(tColSolveOrder(c))>=+tRowSolveOrder) {
					Set tFormat = $S($G(tColFormat(c))'="":tColFormat(c),$G(tRowFormat)'="":tRowFormat,1:tDefFormat)
				}
				Else {
					Set tFormat = $S($G(tRowFormat)'="":tRowFormat,$G(tColFormat(c))'="":tColFormat(c),1:tDefFormat)
				}

				// JMD988 Test for format override
				If ((tAxisCount>1) && tHasOverride) {
					Set tFO = ..%GetCellFormatOverride(c,r)
					Set:tFO'="" tFormat = tFO
				}

				Set tTotal = tTotal + tValue
				Set:tValue="" tEmptyCells = tEmptyCells + 1

				If (tFormat'="") {
					Write ?(c-1)*(tCellWidth+3)+tLblWidth+tRowDigits+1,$J($S(tValue="":"*",tValue'=+tValue:tValue,1:..%FormatNumber(tValue,tFormat)),tCellWidth)
				}
				Else {
					Write ?(c-1)*(tCellWidth+3)+tLblWidth+tRowDigits+1,$J($S(tValue="":"*",tValue'=+tValue:tValue,tValue'=(tValue\1):$FN(tValue,",",2),1:$FN(tValue,",")),tCellWidth)
				}
			}
			Write:tTruncated ?76,"..."
			Write !
		}

		Set pStats("cells") = tCells
		Set pStats("empty") = tEmptyCells
		Set pStats("total") = tTotal
		Set %DeepSee.ResultSet.%Statistics("Cells") = tCells
		Set %DeepSee.ResultSet.%Statistics("Print") = $ZH - tStart

		If (%DeepSee.ResultSet.%Query.showPlan) {
			Do %DeepSee.ResultSet.%ShowPlan()
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	If $$$ISERR(tSC) {
		Do $System.Status.DisplayError(tSC)
	}
	Quit tSC
}



}
