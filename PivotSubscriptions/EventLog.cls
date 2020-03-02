/// Event Log is a log for every action performed by Pivot Subscriptions, covering five event types: creation, update, deletion, sent email subscriptions by Task, and immediately sent emails.
Class PivotSubscriptions.EventLog Extends %Persistent
{

/// Event Type covers: create, update, delete, sendSubscription, and tableError
Property EventType As %String(VALUELIST = ",create,update,delete,sendSubscription,tableError");

Property StartTime As %TimeStamp [ InitialExpression = {$zdt($h, 3, 1)} ];

Property EndTime As %TimeStamp;

Property UserName As %String(MAXLEN = 128) [ InitialExpression = {$username} ];

Property Pivot As %String(MAXLEN = 512);

Property DayOfWeek As %String;

Property Hour As %Integer(MAXVAL = 23, MINVAL = 0);

Property Minute As %Integer(MAXVAL = 59, MINVAL = 0);

Property Format As %String(VALUELIST = ",Excel,PDF");

Property Emails As %String(MAXLEN = "");

Property Name As %String(MAXLEN = 100);

Property Status As %Status;

Property Subscription As PivotSubscriptions.Subscription;

Property GUID As %String [ InitialExpression = {$System.Util.CreateGUID()} ];

/// Takes in info about an Alert Task and logs the information to the TaskLog
ClassMethod CreateEvent(pType, pUser, pPivot, pDayOfWeek, pHour, pMinute, pFormat, pEmails, pName, ByRef pEvent) As %Status
{
	Set tSC=$$$OK
	
	Set tEventLog=##class(PivotSubscriptions.EventLog).%New()
	Set tEventLog.EventType=pType
	Set tEventLog.UserName=pUser
	Set tEventLog.Pivot=pPivot
	Set tEventLog.Name=pName

	Set tEventLog.DayOfWeek=pDayOfWeek
	Set tEventLog.Hour=pHour
	Set tEventLog.Minute=pMinute
	
	Set tEventLog.Format=pFormat
	Set tEventLog.Emails=pEmails

	Set tSC=tEventLog.%Save()
	Set pEvent=tEventLog
	
	Quit tSC
}

Method UpdateStatus(pStatus) As %Status
{
	Set tSC=$$$OK

	Set ..EndTime=$zdt($h,3,1)
	Set ..Status=pStatus
	Set tSC=..%Save()

	Quit tSC
}

Method UpdateEvent(pDayOfWeek, pHour, pMinute, pFormat, pEmails, pName) As %Status
{
	Set tSC=$$$OK

	Set ..DayOfWeek=pDayOfWeek
	Set ..Hour=pHour
	Set ..Minute=pMinute
	Set ..Format=pFormat
	Set ..Emails=pEmails
	Set ..Name=pName

	Set tSC=..%Save()

	Quit tSC
}

ClassMethod DayOfWeekDisplay(pDayOfWeek) As %String [ SqlProc ]
{
	Set pDayOfWeek=$Replace(pDayOfWeek,0,"Sunday")
	Set pDayOfWeek=$Replace(pDayOfWeek,1,"Monday")
	Set pDayOfWeek=$Replace(pDayOfWeek,2,"Tuesday")
	Set pDayOfWeek=$Replace(pDayOfWeek,3,"Wednesday")
	Set pDayOfWeek=$Replace(pDayOfWeek,4,"Thursday")
	Set pDayOfWeek=$Replace(pDayOfWeek,5,"Friday")
	Set pDayOfWeek=$Replace(pDayOfWeek,6,"Saturday")
	Quit pDayOfWeek
}

Query GetEventsForUI() As %SQLQuery
{
    SELECT ID As Details,StartTime,EndTime,EventType,Name,Emails,Status
    FROM PivotSubscriptions.EventLog 
    ORDER BY ID DESC
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
<Value>StartTime</Value>
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
<Value name="12">
<Value>Name</Value>
</Value>
<Value name="13">
<Value>EndTime</Value>
</Value>
<Value name="14">
<Value>Status</Value>
</Value>
<Value name="15">
<Value>Subscription</Value>
</Value>
<Value name="16">
<Value>GUID</Value>
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
