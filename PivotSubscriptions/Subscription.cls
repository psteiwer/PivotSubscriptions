Class PivotSubscriptions.Subscription Extends %Persistent
{

Parameter DEFAULTGLOBAL = "^PivotSubscriptions.Sub";

Property CreatedBy As %String;

Property Pivot As %String(MAXLEN = "") [ Required ];

Property DayOfWeek As %String [ Required ];

Property Hour As %Integer(MAXVAL = 23, MINVAL = 0) [ Required ];

Property Minute As %Integer(VALUELIST = ",0,15,30,45") [ Required ];

Property Format As %String(VALUELIST = ",Excel,PDF");

Property Emails As %String(MAXLEN = "") [ Required ];

Property Version As %String [ InitialExpression = {##class(PivotSubscriptions.Utils).GetVersion()} ];

Property Name As %String(MAXLEN = 100) [ Required ];

Property CustomFilters As array Of %String(MAXLEN = "");

Property CustomEmailText As %String(MAXLEN = "");

Property RunOnce As %Boolean [ InitialExpression = 0 ];

Method Unsubscribe(pEmail) As %Status
{
    Set tSC=$$$OK

    Set tSC=##class(PivotSubscriptions.EventLog).CreateEvent("unsubscribe",..%Id(),$username,..Pivot,..DayOfWeek,..Hour,..Minute,..Format,pEmail,..Name,..RunOnce,.tEvent)

    Set tEmailList=$LFS(..Emails,",")

    If $LL(tEmailList)=1 {
        If ..Emails=pEmail {
            // This is the only Email for the subscription, delete subscription
            Set tSC=##class(PivotSubscriptions.EventLog).CreateEvent("delete",..%Id(),$username,..Pivot,..DayOfWeek,..Hour,..Minute,..Format,..Emails,..Name,..RunOnce,.tDeleteEvent)
            Set tSC=##class(PivotSubscriptions.Subscription).%DeleteId(..%Id())
            Do tDeleteEvent.UpdateStatus(tSC)
            Do tEvent.UpdateStatus(tSC)
            Return tSC
        }
    }

    Set tPosition=$Listfind(tEmailList,pEmail)
    If tPosition=0 {
        Set tSC=$$$ERROR($$$GeneralError,"Not subscribed")
    } ElseIf tPosition=1 {
        Set tEmailList=$List(tEmailList,2,*)
    } ElseIf tPosition=$LL(tEmailList) {
        Set tEmailList=$List(tEmailList,1,*-1)    
    } Else {
        Set tEmailList=$List(tEmailList,1,tPosition-1)_$List(tEmailList,tPosition+1,*)
    }

    If tPosition'=0 {
        Set ..Emails=$LTS(tEmailList,",")
        Set tSC=..%Save()
    }

    Do tEvent.UpdateStatus(tSC)

    Quit tSC
}

ClassMethod GetScheduleDisplay(pID = "") As %String [ SqlProc ]
{
	Set tDisplay=""
	Quit:pID="" tDisplay
	
	Set tSubscription=##class(PivotSubscriptions.Subscription).%OpenId(pID)
    Quit:'$ISOBJECT(tSubscription) tDisplay

    Set tDisplay=##class(PivotSubscriptions.EventLog).DayOfWeekDisplay(tSubscription.DayOfWeek)_"@"_tSubscription.Hour_":"_$REPLACE($JUSTIFY(tSubscription.Minute,2)," ",0)

	Quit tDisplay
}

Storage Default
{
<Data name="CustomFilters">
<Attribute>CustomFilters</Attribute>
<Structure>subnode</Structure>
<Subscript>"CustomFilters"</Subscript>
</Data>
<Data name="SubscriptionDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>CreatedBy</Value>
</Value>
<Value name="3">
<Value>Pivot</Value>
</Value>
<Value name="4">
<Value>DayOfWeek</Value>
</Value>
<Value name="5">
<Value>Hour</Value>
</Value>
<Value name="6">
<Value>Minute</Value>
</Value>
<Value name="7">
<Value>Format</Value>
</Value>
<Value name="8">
<Value>Emails</Value>
</Value>
<Value name="9">
<Value>Version</Value>
</Value>
<Value name="10">
<Value>Name</Value>
</Value>
<Value name="11">
<Value>CustomEmailText</Value>
</Value>
<Value name="12">
<Value>RunOnce</Value>
</Value>
</Data>
<DataLocation>^PivotSubscriptions.SubD</DataLocation>
<DefaultData>SubscriptionDefaultData</DefaultData>
<IdLocation>^PivotSubscriptions.SubD</IdLocation>
<IndexLocation>^PivotSubscriptions.SubI</IndexLocation>
<StreamLocation>^PivotSubscriptions.SubS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
