# Attribute-Based Access Control (ABAC) in Azure Storage

## Executive Summary

* **Scenario:** GlobalCorp manages hundreds of cloud storage resources across expanding project teams. Traditional Role-Based Access Control (RBAC) required creating dedicated security groups for every single project and container combination, causing severe administrative bloat and "permission creep."
* **Objective:** Implement Attribute-Based Access Control (ABAC) using Microsoft Entra ID Custom Security Attributes and Azure Storage Blob Index Tags.
* **Zero Trust Principle:** Least Privilege & Dynamic Authorization. Access is not static; it is evaluated in real-time based on the condition: `Allow Access IF Principal.Project == Resource.Project`.

![ABAC Architecture Diagram](Attribute-Based-Access-Control-ABAC.jpg)

---

## Prerequisites

* **Test Account:** Non-Owner user (e.g., `ZerotTrustTestUser@yourtenant.onmicrosoft.com`).
> ⚠️ **Crucial Note:** Never test ABAC using an account with Subscription Owner or Contributor rights. Azure permissions are additive; Owner rights grant full data plane access and will silently bypass ABAC restrictions!
* **Directory Roles:** Your admin account must have the **Attribute Assignment Administrator** role to create and assign custom attributes in Entra ID.

---

## Step-by-Step Implementation Guide

### Phase 1: Define & Assign Identity Attributes (Microsoft Entra ID)

1. **Create the Custom Attribute Schema:**
   * Go to **Entra ID > Custom security attributes**.
   * Click **Add attribute set** → Name: `Engineering`.
   * Open `Engineering`, click **Add attribute** → Name: `Project` (Data type: `String`, Multiple values: `No`).

2. **Assign Attributes to the Developer Account:**
   * Go to **Entra ID > Users > ZerotTrustTestUser**.
   * Select **Custom security attributes** from the left menu.
   * Click **Add assignment** → Attribute set: `Engineering` | Attribute: `Project` | Value: `Phoenix`.
   * Click **Save**.

![Custom Security Attribute Assignment](Custom-security-attribute.jpg)

---

### Phase 2: Deploy & Tag Infrastructure (Azure Storage)

1. **Provision Container & Sample Data:**
   * Open your Storage Account (e.g., `msapoclabstorageaccount`).
   * Create a new private container named `confidential-data`.
   * Upload sample text files: `phoenix-blueprint.txt`, `apollo-blueprint.txt`, and `moon-blueprint.txt`.

2. **Apply Blob Index Tags:**
   * Click `phoenix-blueprint.txt` > Go to **Blob index tags**:
     * **Key:** `Project` | **Value:** `Phoenix`
   * Click `apollo-blueprint.txt` / `moon-blueprint.txt` > Go to **Blob index tags**:
     * **Key:** `Project` | **Value:** `Apollo` / `moon`

![Blob Index Tag Phoenix](tag1.jpg)
![Blob Index Tag Moon](tag2.jpg)

---

### Phase 3: Configure Azure IAM Roles (Control Plane vs. Data Plane)

To allow the user to view the storage account in the portal GUI without granting unrestricted data permissions, management and data permissions must be split.

#### Step 3A: Grant Management Plane Visibility (Control Plane)
1. In your Storage Account, go to **Access Control (IAM) > Add role assignment**.
2. Select the standard **Reader** role *(Do NOT add any ABAC conditions to this role)*.
3. Assign it to `ZerotTrustTestUser`.
> **Why this step exists:** The Reader role lets the user browse to the storage account and container inside the Azure Portal GUI.

#### Step 3B: Configure ABAC Data Plane Role Assignment
1. Click **Add role assignment** again.
2. Select **Storage Blob Data Reader** and click **Next**.
3. **Members** → Select `ZerotTrustTestUser`.
4. **Conditions** → Click **Add condition**:
   * **Action:** Check *Read a blob* (`Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read`).
   * **Build Expression:**
     * **Attribute Source:** `Principal`
     * **Attribute:** `Engineering_Project`
     * **Operator:** `StringEqualsIgnoreCase`
     * **Attribute Source (Right side):** `Resource`
     * **Attribute:** `Blob index tags [Values in key]`
     * **Key:** `Project`
5. Click **Save**, then **Review + assign**.

---

## Phase 4: Validation & Testing

1. Open a fresh Incognito / Private Browser Window.
2. Log into `portal.azure.com` as `ZerotTrustTestUser`.
3. Navigate to **Storage accounts > msapoclabstorageaccount > Containers > confidential-data**.
4. **Verification Step:** Look at the top banner. Ensure Authentication method is toggled to **Switch to Microsoft Entra user account** (NOT Access Key).

| Test Target | User Attribute | Resource Tag | Expected Result | Technical Reason |
| :--- | :--- | :--- | :--- | :--- |
| `phoenix-blueprint.txt` | Phoenix | Phoenix | **SUCCESS** (Download OK) | `Principal.Project` matches `Resource.Project` |
| `apollo-blueprint.txt` | Phoenix | Apollo / Moon | **BLOCKED** (403 Error) | Attribute mismatch intercepted by ABAC policy |

### Verification Screenshots

#### Successful Access (Matching Tag: Phoenix)
![Access Granted](Result-You-have-access-to-see-and-download.jpg)

#### Access Denied (Mismatched Tag: Apollo/Moon)
![Access Denied](Result-You-don't-have-access.jpg)

---

## Key Architectural Takeaways

* **Management Plane vs. Data Plane Separation:**
  The Reader role grants visibility into the Azure Resource Manager (Control Plane). The Storage Blob Data Reader role with ABAC conditions controls access to the actual file contents (Data Plane). Combining both delivers a smooth portal experience without compromising Zero Trust principles.
* **Additive Permission Awareness:**
  Azure IAM evaluates permissions additively across all assigned roles. High-level permissions (like Subscription Owner) bypass Data Plane ABAC constraints entirely. Testing must always be validated against standard, unprivileged user identities.
* **Operational Efficiency at Scale:**
  Rather than managing hundreds of explicit IAM role assignments or Entra ID security groups across changing project scopes, ABAC reduces overhead to a single dynamic policy statement. Changing a single attribute on a user's profile automatically reshapes their data access footprint across the entire cloud estate.

---

## Technical Interview Q&A

### Q1: What is the primary operational advantage of implementing ABAC over traditional RBAC when managing access to cloud storage at scale?
> **Answer:** Traditional RBAC creates severe administrative bloat. As the number of projects and storage accounts grows, you end up creating hundreds of specific groups or IAM role assignments—leading to 'permission creep' and heavy maintenance overhead.
> 
> With ABAC, we write a single dynamic policy statement: *"Allow access if User.Project equals Resource.Project."* Access scales automatically without creating new groups or adding individual role assignments. When an employee switches teams, updating a single attribute on their Entra ID account instantly updates their access scope across all infrastructure resources globally.

### Q2: In Azure Storage, if a user has the Storage Blob Data Reader role assigned with an ABAC condition, but they attempt to access a blob using Access Keys, will the ABAC policy still enforce access control?
> **Answer:** No. ABAC conditions attached to Azure IAM roles only evaluate requests authenticated via Microsoft Entra ID (OAuth 2.0) tokens. Account Access Keys bypass Entra ID identity entirely and grant full control to the data plane.
> 
> To maintain a true Zero Trust posture, we must disable Account Key authentication at the storage account setting level (`allowSharedKeyAccess: false`), forcing all data plane access to pass through Entra ID authentication where our ABAC conditions and Conditional Access policies are evaluated.****
