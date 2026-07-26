# LAB: Detect & Respond to SSH Brute Force Attacks Using Microsoft Sentinel + SOAR

## 1. Lab Overview
In this lab, you will:
* Deploy a Linux VM
* Simulate SSH brute-force attacks
* Detect the attack using a Sentinel analytic rule
* Trigger an automation rule
* Execute a Logic App playbook
* Send an automated email notification

This lab demonstrates SIEM + SOAR capabilities in Microsoft Sentinel.

## 2. Prerequisites
* Azure subscription
* Microsoft Sentinel workspace
* Log Analytics agent connected to the VM
* Linux VM with SSH enabled
* NSG allowing inbound port 22

## 3. Create the Playbook (Logic App)

### 3.1 Navigate to Sentinel
**Microsoft Sentinel → Your Workspace → Automation**

### 3.2 Create a playbook
Click: **Create → Playbook with alert trigger**

### 3.3 Name the playbook
`pbk-ssh-bruteforce-response`

### 3.4 Add the trigger
It should already be present:
`Microsoft Sentinel – When an alert is created (V2)`

### 3.5 Add an action
Click **Add an action → Outlook → Send an email (V2)**

Configure:
* **To:** your email
* **Subject:** `SSH Brute Force Alert - @{triggerBody()?['Essentials']?['AlertDisplayName']}`
* **Body:** (temporary placeholder — will update later)

### 3.6 Save & Publish
Click **Save → Run Trigger → Publish**
Your playbook is now active.

## 4. Verify Playbook is Active
Go to: **Sentinel → Automation → Playbooks → Active Playbooks**

You should see:
`pbk-ssh-bruteforce-response`
* **Status:** Enabled 
* **Trigger kind:** Microsoft Sentinel

This confirms the playbook is valid.

## 5. Configure Sentinel Permissions (CRITICAL)
Go to: **Sentinel → Automation → scroll down → Configure permissions**

Click **Fix** for each item:
* Sentinel needs permission to run playbooks
* Logic App needs permission
* Managed Identity needs permission

All items must show green checkmarks. 
*Without this step, the playbook will NOT appear in automation rules.*

## 6. Create the Automation Rule
Go to: **Sentinel → Automation → Automation Rules → Create**

### 6.1 Rule name
`SSH Brute Force – Auto Playbook Trigger`

### 6.2 Trigger
When alert is created

### 6.3 Condition
* **Property:** Analytic rule name
* **Operator:** Equals
* **Value:** `SSH Brute Force with TI Enrichment`

### 6.4 Action
* **Run playbook**
* **Select:** `pbk-ssh-bruteforce-response`

### 6.5 Save
Click **Create**. 
Automation rule is now active.

## 7. Simulate SSH Brute Force Attack

### 7.1 Ensure NSG allows SSH
Inbound rule:
* **Port:** 22
* **Protocol:** TCP
* **Source:** Any
* **Action:** Allow

### 7.2 Clear old SSH host key
```bash
ssh-keygen -R <VM_PUBLIC_IP>

Muhammad — absolutely.
Here is the full, clean, complete, production ready lab for:
⭐ SSH Brute Force Detection + Sentinel + SOAR Automated Response
(Updated for the 2026 Microsoft Defender/Sentinel UI)
This is the final version, including every correction, every updated UI change, and every fix we applied together.
You can save this as your official lab document.
________________________________________
🧩 LAB: Detect & Respond to SSH Brute Force Attacks Using Microsoft Sentinel + SOAR
________________________________________
🟦 1. Lab Overview
In this lab, you will:
•	Deploy a Linux VM
•	Simulate SSH brute-force attacks
•	Detect the attack using a Sentinel analytic rule
•	Trigger an automation rule
•	Execute a Logic App playbook
•	Send an automated email notification
This lab demonstrates SIEM + SOAR capabilities in Microsoft Sentinel.
________________________________________
🟦 2. Prerequisites
•	Azure subscription
•	Microsoft Sentinel workspace
•	Log Analytics agent connected to the VM
•	Linux VM with SSH enabled
•	NSG allowing inbound port 22
________________________________________
🟦 3. Create the Playbook (Logic App)
3.1 Navigate to Sentinel
Microsoft Sentinel → Your Workspace → Automation
3.2 Create a playbook
Click:
Create → Playbook with alert trigger
3.3 Name the playbook
pbk-ssh-bruteforce-response
3.4 Add the trigger
It should already be present:
Microsoft Sentinel – When an alert is created (V2)
3.5 Add an action
Click Add an action → Outlook → Send an email (V2)
Configure:
•	To: your email
•	Subject: 
SSH Brute Force Alert - @{triggerBody()?['Essentials']?['AlertDisplayName']}
•	Body: (temporary placeholder — will update later)
3.6 Save & Publish
Click Save → Run Trigger → Publish
Your playbook is now active.
________________________________________
🟦 4. Verify Playbook is Active
Go to:
Sentinel → Automation → Playbooks → Active Playbooks
You should see:
pbk-ssh-bruteforce-response 
Status: Enabled 
Trigger kind: Microsoft Sentinel
This confirms the playbook is valid.
________________________________________
🟦 5. Configure Sentinel Permissions (CRITICAL)
Go to:
Sentinel → Automation → scroll down → Configure permissions
Click Fix for each item:
•	Sentinel needs permission to run playbooks
•	Logic App needs permission
•	Managed Identity needs permission
All items must show green checkmarks.
Without this step, the playbook will NOT appear in automation rules.
________________________________________
🟦 6. Create the Automation Rule
Go to:
Sentinel → Automation → Automation Rules → Create
6.1 Rule name
SSH Brute Force – Auto Playbook Trigger
6.2 Trigger
When alert is created
6.3 Condition
•	Property: Analytic rule name
•	Operator: Equals
•	Value: SSH Brute Force with TI Enrichment
6.4 Action
•	Run playbook
•	Select: pbk-ssh-bruteforce-response
6.5 Save
Click Create
Automation rule is now active.
________________________________________
🟦 7. Simulate SSH Brute Force Attack
7.1 Ensure NSG allows SSH
Inbound rule:
•	Port: 22
•	Protocol: TCP
•	Source: Any
•	Action: Allow
7.2 Clear old SSH host key
ssh-keygen -R <VM_PUBLIC_IP>
7.3 Run brute-force attempts
1..20 | ForEach-Object { ssh azureuser@<VM_PUBLIC_IP> -o StrictHostKeyChecking=no -o BatchMode=yes }
Correct output:
Permission denied (publickey,password)
This means the VM is logging failed SSH attempts.
________________________________________
🟦 8. Sentinel Detection Pipeline
Within 2–5 minutes, Sentinel will:
1.	Detect the brute-force attempts
2.	Fire the analytic rule
3.	Create an alert
4.	Create an incident
5.	Trigger the automation rule
6.	Run the playbook
7.	Send the email
This confirms SIEM + SOAR is working.
________________________________________
🟦 9. Validate Playbook Execution
Go to:
Sentinel → Automation → Playbooks → pbk-ssh-bruteforce-response → Run history
You should see:
•	1 successful run
•	Timestamp matching your attack
________________________________________
🟦 10. Fixing Email Body (Optional Enhancement)
Your email may show empty fields if the JSON paths differ.
10.1 Open the incident
Sentinel → Incidents → Your SSH Brute Force incident
10.2 Open “Raw event” or “Entities”
Copy the JSON structure.
10.3 Update email body fields
Example:
Alert Name: @{triggerBody()?['Essentials']?['AlertDisplayName']}
Severity: @{triggerBody()?['Essentials']?['Severity']}
Source IP: @{triggerBody()?['Entities']?[2]?['Address']}
Target Host: @{triggerBody()?['Entities']?[1]?['HostName']}
Account: @{triggerBody()?['Entities']?[0]?['Name']}
(Indexes depend on your alert JSON.)
10.4 Save the playbook
________________________________________
🟦 11. Final Expected Output
You receive an email containing:
•	Alert name
•	Severity
•	Source IP
•	Target host
•	Username
•	TI match (if applicable)
•	Timestamp
This completes the lab.
________________________________________
⭐ LAB STATUS: 100% COMPLETE
You have successfully built a full SIEM + SOAR pipeline in Microsoft Sentinel.
________________________________________
If you want, I can now generate:
•	A CV ready project write up
•	A diagram of the entire workflow
•	The next Sentinel lab
Just choose one.

1..20 | ForEach-Object { ssh azureuser@<VM_PUBLIC_IP> -o StrictHostKeyChecking=no -o BatchMode=yes }

Correct output:
Permission denied (publickey,password)
This means the VM is logging failed SSH attempts.

8. Sentinel Detection Pipeline
Within 2–5 minutes, Sentinel will:

Detect the brute-force attempts

Fire the analytic rule

Create an alert

Create an incident

Trigger the automation rule

Run the playbook

Send the email

This confirms SIEM + SOAR is working.

9. Validate Playbook Execution
Go to: Sentinel → Automation → Playbooks → pbk-ssh-bruteforce-response → Run history

You should see:

1 successful run

Timestamp matching your attack

10. Fixing Email Body (Optional Enhancement)
Your email may show empty fields if the JSON paths differ.

10.1 Open the incident
Sentinel → Incidents → Your SSH Brute Force incident

10.2 Open “Raw event” or “Entities”
Copy the JSON structure.

10.3 Update email body fields
Example:

Alert Name: @{triggerBody()?['Essentials']?['AlertDisplayName']}
Severity: @{triggerBody()?['Essentials']?['Severity']}
Source IP: @{triggerBody()?['Entities']?[2]?['Address']}
Target Host: @{triggerBody()?['Entities']?[1]?['HostName']}
Account: @{triggerBody()?['Entities']?[0]?['Name']}
