Class PivotSubscriptions.UI.Unsubscribe Extends %CSP.REST
{

Parameter HandleCorsRequest = 1;

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
    <Route Url="/unsubscribe/:subscriptionid/:email/:guid" Method="GET" Call="Unsubscribe" />
</Routes>
}

ClassMethod Unsubscribe(pEmail, pGUID) As %Status
{
    Set tSC=$$$OK
    Set tResult={}

    If ##class(PivotSubscriptions.Utils).CheckUnsubscribe(pSubscriptionId,pEmail,pGUID) {
        Set tSubscription=##class(PivotSubscriptions.Subscription).%OpenId(pSubscriptionId)
        // Remove email from subscription
        // Delete subscription if it is the only email?

        Do tResult.%Set("Status",pEmail_" unsubscribed from "_tSubscription.Name)
    }

    Write tResult.%ToJSON()
    Quit tSC
}

}
