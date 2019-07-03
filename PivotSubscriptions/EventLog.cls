/// Event Log is a log for every action performed by Pivot Subscriptions, covering five event types: creation, update, deletion, sent email subscriptions by Task, and immediately sent emails.
Class PivotSubscriptions.EventLog Extends %Persistent
{

/// Event Type covers: creation, update, deletion and sent email subscriptions
/* 
 * Only possible values are creation, update, deletion, and send
 */
Property EventType As %String (VALUELIST="creation,update,deletion,send");

Property TimeStamp As %TimeStamp [ Initialexpression = {$zdt($h,3)} ];

Property UserName As %String(MAXLEN = 128) [ InitialExpression = {$username} ];

Property Pivot As %String;

Property DayOfWeek As %String;

Property Hour As %Integer(MINVAL=0, MAXVAL=23);

Property Minute As %Integer (VALUELIST=",0,15,30,45");

Property Format As %String(VALUELIST = ",Excel,PDF");

Property Emails As %String;

/// Takes in info about an Alert Task and logs the information to the TaskLog
ClassMethod LogEvent(pEvent, pUser, pPivot, pDayOfWeek, pHour, pMinute, pFormat, pEmails) As %Status
{
	Set tSC = $$$OK
	
	Set tEventLog = ##class(PivotSubscriptions.EventLog).%New()
	Set tEventLog.EventType = pEvent
	Set tEventLog.TimeStamp = %Library.Utility.DateTime(7)
	Set tEventLog.UserName = pUser
	Set tEventLog.Pivot = pPivot

	Set tEventLog.DayOfWeek = pDayOfWeek
	Set tEventLog.Hour = pHour
	Set tEventLog.Minute = pMinute
	
	Set tEventLog.Format = pFormat
	Set tEventLog.Emails = pEmails

	Set tSC = tEventLog.%Save()
	
	Quit tSC
}

Storage Default
{
<Data name="EventLogDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>EventType</Value>
</Value>
<Value name="3">
<Value>TimeStamp</Value>
</Value>
<Value name="4">
<Value>UserName</Value>
</Value>
<Value name="5">
<Value>Pivot</Value>
</Value>
<Value name="6">
<Value>SubscriptionId</Value>
</Value>
<Value name="7">
<Value>DayOfWeek</Value>
</Value>
<Value name="8">
<Value>Hour</Value>
</Value>
<Value name="9">
<Value>Minute</Value>
</Value>
<Value name="10">
<Value>Format</Value>
</Value>
<Value name="11">
<Value>Emails</Value>
</Value>
</Data>
<DataLocation>^PivotSubscriptions.EventLogD</DataLocation>
<DefaultData>EventLogDefaultData</DefaultData>
<IdLocation>^PivotSubscriptions.EventLogD</IdLocation>
<IndexLocation>^PivotSubscriptions.EventLogI</IndexLocation>
<StreamLocation>^PivotSubscriptions.EventLogS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}