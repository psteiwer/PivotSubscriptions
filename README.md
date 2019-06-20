# PivotSubscriptions

Intern Project: Hee-Sung

PivotSubsctions allows users to subscribe to a pivot table and recieve a scheduled email containing the specified pivot table. 

## Installation
1. Use the Download ZIP option for this project
2. Extract the files and copy path
	* This is the path to the directory that contains README.md and LICENSE
3. Open terminal and ZN to desired namespace
4. Run the following commands:
```
	set path="<PATH FROM STEP 2>"
	do $system.OBJ.LoadDir(path_"/PivotSubscriptions/","ck",,1)
```
5. Follow the Configuration steps

## Configuration steps
### Configure Task Manager Email Settings
Subscriptions are delivered by Email. The Task Manager Email must be configured to allow alerts to be delivered by Email. At a minimum, the SMTP Server must be assigned in the Task Manager Email Settings (Management Portal -> System Administration -> Configuration -> Additional Settings -> Task Manager Email). For more information, please see the <a href="http://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=RACS_Category_TaskManagerEmail">documentation</a>.
