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

### Initialize or Update Task in IRIS
In order for the Task of sending scheduled emails to be initalized or updated, the user must call the ConfigureTask() method in Terminal. 
1. Open terminal and ZN to desired namespace
	* You can use the IRIS Launcher (system icon on bottom right in Windows) by right-clicking the icon and selecting "Terminal". 
2. Run the following command:
```
	set status = ##class(PivotSubscriptions.Task).ConfigureTask()
```
3. Optionally, you can write the status to Terminal output to verify the task was initalized. Note, if the task was already initalized and the command was run again to cause the Task to update, the status will return 1 regardless of whether the update failed or succeeded. 
```
	write status
```
