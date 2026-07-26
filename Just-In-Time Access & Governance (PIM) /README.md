# Just-In-Time Access & Governance (PIM)[cite: 2]

## Executive Summary
* **Scenario:** GlobalCorp's database administrators hold permanent, 24/7 "Global Admin" privileges[cite: 2]. If an admin's laptop is compromised off-hours, the blast radius is catastrophic[cite: 2].
* **Objective:** Enforce the principle of Least Privilege by removing standing access[cite: 2]. Implement Privileged Identity Management (PIM) for Just-In-Time (JIT) access, and automate quarterly Access Reviews to prevent permission creep[cite: 2].
* **Zero Trust Principle:** Assume Breach & Least Privilege[cite: 2]. Privileged roles should only exist when actively required, justified, and explicitly approved[cite: 2].

---

## Phase 1: Prerequisites & User Creation (Stripping Standing Access)

To interact with PIM and Access Reviews, the test user must have an Entra ID Premium P2 license assigned[cite: 2].

### 1. Create the User & Assign License
* Navigate to the Microsoft 365 Admin Center (`admin.microsoft.com`)[cite: 2].
* Go to **Users > Active users > Add a user**[cite: 2].
* Name the user `DBAdmin-Test` (e.g., `DBAdmin-Test@msapoclab.onmicrosoft.com`)[cite: 2].
* Under Product licenses, select **Microsoft Entra ID P2**[cite: 2].
* Finish creating the user and copy the password[cite: 2].
* **Validation:** This user now has exactly zero standing administrative permissions in Azure[cite: 2].

### 2. Bypass Conflicting Conditional Access (From Lab 1)
*Context: A new user will be forced to register for MFA, but Lab 1 requires a FIDO2 key, which will cause a BadRequest login loop[cite: 2].*
* Navigate to the **Microsoft Entra admin center > Protection > Conditional Access > Policies**[cite: 2].
* Open the Lab 1 policy (*Enforce Phishing-Resistant MFA*)[cite: 2].
* Under **Users > Exclude**, explicitly add `DBAdmin-Test` and click **Save**[cite: 2].

---

## Phase 2: Configure Privileged Identity Management (Admin Side)

We will configure the Global Administrator role to require Just-In-Time activation with strict manager oversight[cite: 2].

### 1. Configure Role Settings & Approvers
* Log into the Azure Portal with your primary Admin account[cite: 2].
* Search for and open **Privileged Identity Management**[cite: 2].
* Under Manage, click **Microsoft Entra roles > Roles**[cite: 2].
* Search for **Global Administrator** and select it[cite: 2].
* Click **Settings** (gear icon at the top) > **Edit**[cite: 2].
* Set **Activation maximum duration** to 2 hours[cite: 2].
* Check **Require justification** and **Require ticket information**[cite: 2].
* Check **Require approval to activate**[cite: 2].
* **Crucial Step:** Click **Select approvers** and explicitly select your primary Admin account[cite: 2]. If you leave this blank, the request goes into a black hole[cite: 2].
* Click **Update**[cite: 2].

### 2. Assign Eligible Access
* Still on the Global Administrator role page, click **Add assignments**[cite: 2].
* Select `DBAdmin-Test` as the member[cite: 2].
* Ensure the Assignment type is **Eligible** (not Active) and click **Assign**[cite: 2].

---

## Phase 3: The Just-In-Time Activation (End-User Side)

### Request the Role
* Open a fresh Incognito / Private Browser Window[cite: 2].
* Log into `portal.azure.com` as `DBAdmin-Test`[cite: 2]. *(You will see an empty dashboard stating you have no subscriptions—this is expected for a standard user[cite: 2]).*
* Search for and open **Privileged Identity Management**[cite: 2].
* Click **My roles > Microsoft Entra roles**[cite: 2].
* Under Eligible assignments, locate **Global Administrator** and click **Activate**[cite: 2].
* Enter a justification (e.g., "Emergency database patch") and a ticket number (e.g., "INC-9942")[cite: 2].
* Click **Activate**[cite: 2]. The status will change to *Pending approval*[cite: 2].

![DBAdmin Requesting Approval](DBAdmin%20Requesting%20for%20apprval.jpg)

---

## Phase 4: Manager Approval & Token Refresh

### 1. Approve the Request
* Switch back to your primary Admin browser window[cite: 2].
* Go to **Privileged Identity Management > Approve requests** (under Tasks)[cite: 2].
* Click the **Microsoft Entra roles** tab[cite: 2].
* Select the pending request from `DBAdmin-Test`, click **Approve**, enter a justification, and confirm[cite: 2].

![Admin Approving Request](Admin%20Request%20for%20approval.jpg)

### 2. Refresh the Authentication Token
* Switch back to the `DBAdmin-Test` Incognito window[cite: 2].
* **Crucial Step:** The user must explicitly Sign Out and Sign Back In[cite: 2]. Azure issues RBAC tokens at login; the user must re-authenticate to receive the newly approved Global Admin token[cite: 2].
* Once logged back in, go to **PIM > My roles > Active assignments**[cite: 2].
* The Global Administrator role will be listed as **Active** with a 2-hour countdown timer[cite: 2].

---

## Phase 5: Continuous Governance (Access Reviews)

To complete the governance lifecycle, automate the cleanup of standing groups[cite: 2].

### 1. Create the Target Group
* In the Entra admin center, create a new Security Group named `Finance System Access` and add `DBAdmin-Test` to it[cite: 2].

### 2. Deploy the Review Campaign
* Navigate to **Identity Governance > Access Reviews > New access review**[cite: 2].
* **Scope:** Teams + Groups > Select `Finance System Access` > All users[cite: 2].
* **Reviewers:** Users review their own access[cite: 2].
* **Recurrence:** Quarterly with a duration of 14 days[cite: 2].
* **Upon completion settings:** Check **Auto apply results to resource**[cite: 2].
* **If reviewers don't respond:** Set to **Remove access**[cite: 2].
* **Save and Create**[cite: 2].

**Outcome:** Every quarter, members will receive an automated email asking them to justify their continued access[cite: 2]. If they ignore it, Entra ID automatically strips their membership, ensuring your environment remains mathematically true to Least Privilege over time[cite: 2].
