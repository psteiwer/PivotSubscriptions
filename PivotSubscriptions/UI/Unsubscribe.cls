Class PivotSubscriptions.UI.Unsubscribe Extends %CSP.REST
{

Parameter HandleCorsRequest = 1;

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
    <Route Url="/unsubscribe/:subscriptionid/:email/:guid" Method="GET" Call="Unsubscribe" />
</Routes>
}

ClassMethod Unsubscribe(pSubscriptionId, pEmail, pGUID) As %Status
{
    Set tSC=$$$OK
    Set tResult={}
    Do tResult.%Set("Status",$$$ERROR($$$GeneralError,"Invalid Request"))

    If ##class(PivotSubscriptions.Utils).CheckUnsubscribe(pSubscriptionId,pEmail,pGUID) {
        Set tSubscription=##class(PivotSubscriptions.Subscription).%OpenId(pSubscriptionId)
        Set tSC=tSubscription.Unsubscribe(pEmail)
        If $$$ISERR(tSC) {
            Do tResult.%Set("Status",$SYSTEM.Status.GetErrorText(tSC))
        } Else {
            Do tResult.%Set("Status",pEmail_" unsubscribed from "_tSubscription.Name)
        }
    }

    Write tResult.%ToJSON()
    Quit tSC
}

}
