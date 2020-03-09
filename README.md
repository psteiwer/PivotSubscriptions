# PivotSubscriptions

PivotSubsctions allows users to subscribe to a pivot table and recieve a scheduled email containing the specified pivot table. 

## Accessing
Once installation is complete, a new "Pivot Subscriptions" Link will be added to the InterSystems IRIS Business Intelligence User Portal. The User Portal can be found at the Management Portal -> Analytics -> User Portal.

## Installation
1. Use the Download ZIP option for this project
2. Extract the files and copy path
	* This is the path to the directory that contains README.md and LICENSE
3. Open terminal and ZN to desired namespace
4. Run the following commands:
```
	set path="<PATH FROM STEP 2>"
	do $system.OBJ.Load(path_"/PivotSubscriptions/Installer.cls","ck",,1)
	do ##class(PivotSubscriptions.Installer).RunInstaller(path)
```
5. Follow the Configuration steps

## Configuration steps
### Configure Task Manager Email Settings
Subscriptions are delivered by Email. The Task Manager Email must be configured to allow alerts to be delivered by Email. At a minimum, the SMTP Server must be assigned in the Task Manager Email Settings (Management Portal -> System Administration -> Configuration -> Additional Settings -> Task Manager Email). For more information, please see the <a href="http://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=RACS_Category_TaskManagerEmail">documentation</a>.

### Unsubscribe Web Application
A new Web Application is created to allow users to manually unsubscribe to subscriptions by clicking on the unsubscribe link include in the subscription email. This new Web Application is "/api/pivotsubscriptionsunsubscribe". It allows unauthenticated access to a REST API that only allows users to unsubscribe if they have the specific URL. Depending on security settings, it may be necessary to give the application additional permissions. This can be accomplished in The Management Portal -> System Administration -> Security -> Applications -> Web Applications -> /api/pivotsubscriptionsunsubscribe -> Application Roles Tab.
These additional permissions include:
1) The Database Resource for the Database that contains the PivotSubscriptions Code 
2) The Database Resource for the Database that contains the PivotSubscriptions Data
3) The Database Resource for the NameSpace's Default Globals Database where PivotSubscriptions is installed

Depending on your security settings and mapping configuration, this may be between 0 and 3 resources that are needed.

### Optional: Custom Action
The Piovt List page gives access to a list of Pivot Tables available to the user. From there, a Pivot Subscription can be added. However, if you would like to add a Pivot Subscription directly from Analyzer or from a Dashboard, you will need to configure a new Custom Action. In order to add the Custom Action, an Action Class is first needed. For more information, please see the <a href="http://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=D2IMP_ch_action">documentation</a> for defining custom actions. In your Action KPI, define the new action as:
```
<action name="AddPivotSubscription" displayName="AddPivotSubscription"/>
```
Additionally in your Action KPI, define the new condition in %OnDashboardAction as:
```
If (pAction="AddPivotSubscription") {
	Set pContext.command = ##class(PivotSubscriptions.Utils).ActionCommand(.pContext)
}
```

The ActionCommand Method will generate a command that will allow for the creation of the Pivot Subscription
