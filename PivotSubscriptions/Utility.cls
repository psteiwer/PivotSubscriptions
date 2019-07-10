Class PivotSubscriptions.Utility
{

ClassMethod CheckTable(pPivot As %String) {
	Set tFilename=$replace($zstrip($E(pPivot,1,*-6),"*PC'W",,"/")_" - "_$zd($h,6),"/","-")_".xls"

	// embed pivot table as HTML table to email
	Set tStream=##class(%Stream.FileCharacter).%New()
	Set tSC=tStream.LinkToFile(tFilename)
	
	// check that file is valid file
	If $$$ISERR(tSC) {
		Do $System.Status.DisplayError(status)
		Quit $$$ERROR()
	}
	
	Set tTableStatus=0
	
	// iterate through stream to check that table has actual data
	While 'tStream.AtEnd {
		Set line = tStream.ReadLine()
		Set headerCount = 0
		
		If $Find(line, "<th") {
			Set headerCount = headerCount + 1
		}
		
		If $Find(line, "<td") {
			Set tTableStatus = 1
			If (headerCount > 10) {
				Set tTableStatus = 0
			}
			Quit
		}
	}
	
	Quit tTableStatus
}

}