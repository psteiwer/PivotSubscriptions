Class PivotSubscriptions.UI.Dialog.EventDetails Extends %DeepSee.UI.Dialog.standardDialog
{

/// Class name of application this page belongs to.
Parameter APPLICATION;

/// Displayed name of this page.
Parameter PAGENAME;

Parameter DOMAIN = "PivotSubscriptions";

Property EventId As %ZEN.Datatype.integer(ZENURL = "EVENTID");

Parameter APPLYBUTTON = 0;

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
</style>
}

/// This XML block defines the contents of this page.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" title="">
<html label="Event Details:" OnDrawContent="DrawDetails" seed="#(%page.EventId)#"/>
</pane>
}

/// Get the (localized) title string for the dialog.
Method %OnGetTitle() As %String
{
	Quit "Event Details"
}

Method %OnGetSubtitle() As %String
{
	Quit ""
}

ClassMethod DrawDetails(pEventId) As %Status
{
    Set tSC=$$$OK

    Set tEvent=##class(PivotSubscriptions.EventLog).%OpenId(pEventId)
    &html<
        <table border="1" cellpadding="2" cellspacing="2">
            <tr>
                <td>ID</td>
                <td>#(pEventId)#</td>
            </tr>
            <tr>
                <td>GUID</td>
                <td>#(tEvent.GUID)#</td>
            </tr>
            <tr>
                <td>Type</td>
                <td>#(tEvent.EventType)#</td>
            </tr>
            <tr>
                <td>Start Time</td>
                <td>#(tEvent.StartTime)#</td>
            </tr>
            <tr>
                <td>End Time</td>
                <td>#(tEvent.EndTime)#</td>
            </tr>
            <tr>
                <td>Name</td>
                <td>#(tEvent.Name)#</td>
            </tr>
            <tr>
                <td>Pivot</td>
                <td>#(tEvent.Pivot)#</td>
            </tr>
            <tr>
                <td>UserName</td>
                <td>#(tEvent.UserName)#</td>
            </tr>
            <tr>
                <td>Format</td>
                <td>#(tEvent.Format)#</td>
            </tr>
            <tr>
                <td>DayOfWeek</td>
                <td>#(##class(PivotSubscriptions.EventLog).DayOfWeekDisplay(tEvent.DayOfWeek))#</td>
            </tr>
            <tr>
                <td>Time</td>
                <td>#(tEvent.Hour)#:#($replace($j(tEvent.Minute,2)," ",0))#</td>
            </tr>
            <tr>
                <td>Email</td>
                <td>#(tEvent.Emails)#</td>
            </tr>
            <tr>
                <td>Run Once</td>
                <td>#(tEvent.RunOnce)#</td>
            </tr>
            <tr>
                <td>Table Error</td>
                <td>#(tEvent.TableError)#</td>
            </tr>
            <tr>
                <td>Status</td>
                <td>#($Select(tEvent.Status:"OK",1:$system.Status.GetErrorText(tEvent.Status)))#</td>
            </tr>
        </table>
    >

    Quit tSC
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return '';
}

}
