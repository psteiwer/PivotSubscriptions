Class PivotSubscriptions.Subscription Extends %Persistent
{

Property CreatedBy As %String;

Property Pivot As %String;

Property DayOfWeek As List Of %Integer (DISPLAYLIST = ",Sunday,Monday,Tuesday,Wednesday,Thursday,Friday,Saturday", VALUELIST=",0,1,2,3,4,5,6");

Property Hour As %Integer(MINVAL=0, MAXVAL=23);

Property Minute As %Integer (VALUELIST=",0,15,30,45");

Property Format As %String(VALUELIST = ",Excel,PDF");

Property Emails As %String;

Storage Default
{
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
</Data>
<DataLocation>^PivotSubscript8A5.SubscriptionD</DataLocation>
<DefaultData>SubscriptionDefaultData</DefaultData>
<IdLocation>^PivotSubscript8A5.SubscriptionD</IdLocation>
<IndexLocation>^PivotSubscript8A5.SubscriptionI</IndexLocation>
<StreamLocation>^PivotSubscript8A5.SubscriptionS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
