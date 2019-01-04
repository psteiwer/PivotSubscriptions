Class PivotSubscriptions.Subscription Extends %Persistent
{

Property CreatedBy As %String;

Property Pivot As %String;

Property Frequency As %Integer(DISPLAYLIST = ",Daily,Weekly", VALUELIST = ",1,7");

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
<Value>Frequency</Value>
</Value>
<Value name="5">
<Value>Format</Value>
</Value>
<Value name="6">
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
