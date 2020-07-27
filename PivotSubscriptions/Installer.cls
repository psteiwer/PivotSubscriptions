Class PivotSubscriptions.Installer
{

ClassMethod RunInstaller(pRootDir = "")
{
	Set tSC=$$$OK
	
	If pRootDir'="" {
		Do $system.OBJ.LoadDir(pRootDir_"/PivotSubscriptions","ck",,1)
		Set tSC=..ImportImage(pRootDir_"/Assets/PivotSubscriptions_BookCover.png")
		If $$$ISERR(tSC) Quit
	}
	
	Set tItem=##class(%DeepSee.UserLibrary.Link).%New()
	Set tItem.fullName="Pivot Subscriptions"
	Set tPage="PivotSubscriptions.UI.SubscriptionManager.zen"
	Set tItem.href=$system.CSP.GetPortalApp($namespace,tPage)_tPage
	Set tItem.title="Pivot Subscriptions"
	Set tItem.bookCover="{background: {style:'background:white;',src:'covers/PivotSubscriptions_Cover.png'},header: {text:'$type',style:'display: none;'},title: {text:'$title',style:'display: none;'},image: {style:'display: none;',src:'deepsee/ds2_globe_44.png',imageStyle:'width:64px;height:64px;'},subtitle: {text:'"_##class(PivotSubscriptions.Utils).GetVersion()_"',style:'font-size:9px;top:179px;'},footer: {text:'$owner',style:'display: none;'}}"
	Set tSC=tItem.%Save()
	If $$$ISERR(tSC) Quit tSC
	
	Set tSC=##class(PivotSubscriptions.Task).ConfigureTask()
	If $$$ISERR(tSC) Quit tSC

	Set tSC=##class(PivotSubscriptions.Installer).ConfigureUnsubscribeWebApp()
	If $$$ISERR(tSC) Quit tSC
	
	Quit tSC
}

/// Import Cover, code taken from %DeepSee.UI.Dialog.ImageUpload:%OnSubmit
ClassMethod ImportImage(pDir) As %Status
{
	Set tSC=$$$OK
	Set tStream=##class(%Stream.FileBinary).%New()
	Set tSC=tStream.LinkToFile(pDir)
	If $$$ISERR(tSC) Quit
	Set tName="PivotSubscriptions_Cover.png"

	If $IsObject(tStream)&&(tName'="") {
		Set tFileName=##class(%File).NormalizeDirectory(tName,##class(%DeepSee.UI.Dialog.ImageUpload).%GetImageDirectory())
		Set tLocalFile=##class(%File).%New(tFileName)
		Set tSC=tLocalFile.Open("WSN")
		If $$$ISERR(tSC) Quit
		
		Set tSC=tLocalFile.CopyFrom(tStream)
		If $$$ISERR(tSC) Quit

		Do tLocalFile.Close()
	}
	
	Quit tSC
}

ClassMethod ConfigureUnsubscribeWebApp() As %Status
{
	Set tSC=$$$OK

	Set tNamespace=$Namespace
	ZN "%SYS"
	
	Try {
		If '##class(Security.Applications).Exists("/api/pivotsubscriptionsunsubscribe") {
			Set tWebApp=##class(Security.Applications).%New()
			Set tWebApp.Name="/api/pivotsubscriptionsunsubscribe"
			Set tWebApp.NameSpace=tNamespace
			Set tWebApp.DispatchClass="PivotSubscriptions.UI.Unsubscribe"
			Set tWebApp.AutheEnabled=64
			Set tSC=tWebApp.%Save()
		}
	} Catch ex {
		Set tSC=ex.AsStatus()
	}

	ZN tNamespace

	Quit tSC
}

}
