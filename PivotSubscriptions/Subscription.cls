Class PivotSubscriptions.Subscription Extends %Persistent
{

Parameter DEFAULTGLOBAL = "^PivotSubscriptions.Sub";

Property CreatedBy As %String;

Property Pivot As %String(MAXLEN="");

Property DayOfWeek As %String;

Property Hour As %Integer(MINVAL=0, MAXVAL=23);

Property Minute As %Integer(VALUELIST=",0,15,30,45");

Property Format As %String(VALUELIST = ",Excel,PDF");

Property Emails As %String(MAXLEN="");

Property Version As %String [ InitialExpression = {##class(PivotSubscriptions.Utility).GetVersion()} ];

Property Name As %String;

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
<Value name="9">
<Value>Version</Value>
</Value>
<Value name="10">
<Value>Name</Value>
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
