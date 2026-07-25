Implementing Zero Trust & Conditional Access in Microsoft Entra ID

Implementing this lab in an Azure Pay-As-You-Go account means working within Microsoft Entra ID (formerly Azure AD), which acts as your Central Identity Provider. Because you are using a Pay-As-You-Go subscription, your default directory is on the Entra ID Free tier. The core feature of this lab—Conditional Access—requires a Premium license. We will start by activating a free trial so you don't incur extra costs.

## Prerequisite: Activate Premium Trial & Protect Yourself
Conditional Access policies are powerful; a misconfiguration can lock you out of your entire Azure account.

### 1. Activate Entra ID Premium P2 Trial
* Log in to the Microsoft Entra admin center using your Azure account credentials.
* In the left menu, expand **Identity > Overview**.
* Look for the **Manage tenant** or **Licenses** section. Click on **Get a free Premium trial**.
* Select **Microsoft Entra ID P2** and activate the free 30-day trial.
* Sign out and sign back in to ensure the Premium features load in your portal.

### 2. Create a "Break-Glass" (Emergency) Admin Account
*Never apply experimental Conditional Access policies to your primary Global Administrator account without an excluded backup.*
* Go to **Identity > Users > All users > New user > Create new user**.
* Name it `EmergencyAdmin@yourtenant.onmicrosoft.com`.
* Assign a highly complex password (save this offline in a secure vault).
* Assign the **Global Administrator** role to this user.
* **CRITICAL:** We will explicitly exclude this account from our policies later.

---

## Phase 1: Create the Test Environment
We need a test user and a group to safely apply our Zero Trust policy.

1. Navigate to **Identity > Users > All users > New user**.
2. Create a user named `ZeroTrustTestUser`. Write down the generated password.
3. Navigate to **Identity > Groups > All groups > New group**.
4. Group type: **Security**. Name it `ZT-Pilot-Group`.
5. Under Members, click **No members selected**, search for `ZeroTrustTestUser`, select them, and click **Create**.

*(Image: Zero Trust Test User Profile)*
![Zero Trust Test User](ZeroTrustTestUser.jpg)

---

## Phase 2: Enable Phishing-Resistant Methods & Onboarding
To enforce Zero Trust, we must allow users to register secure credentials (like a FIDO2 hardware key or Windows Hello) without relying on a password. We do this by issuing a Temporary Access Pass (TAP).

### 1. Enable Temporary Access Pass (TAP)
* Go to **Protection > Authentication methods > Policies**.
* Click on **Temporary Access Pass**.
* Toggle **Enable** to **Yes**.
* Target: Select **All users** (or limit it to `ZT-Pilot-Group`). Click **Save**.

### 2. Enable FIDO2 Security Keys
> **Note:** Microsoft defines "Phishing-Resistant" strictly as FIDO2 keys, Windows Hello for Business, or Certificate-Based Authentication. Standard authenticator app push notifications do not meet this strict criteria.
* Still in Authentication methods, click **FIDO2 security key**.
* Toggle **Enable** to **Yes**.
* Target: Select **All users** (or `ZT-Pilot-Group`). Click **Save**.

### 3. Issue the TAP to your Test User
* Go to **Identity > Users**, search for `ZeroTrustTestUser` and click their profile.
* In the left menu for that user, click **Authentication methods**.
* Click **Add authentication method > Choose Temporary Access Pass**.
* Set the duration (e.g., 1 hour) and click **Add**.
* Copy the TAP value displayed. You will only see this once.

---

## Phase 3: Register the Phishing-Resistant Credential
Now, you will act as the employee setting up their device securely.

1. Open a new Private/Incognito browser window.
2. Go to `mysignins.microsoft.com/security-info`.
3. Enter the `ZeroTrustTestUser` email address.
4. When prompted, enter the Temporary Access Pass instead of a password.
5. Once logged in, click **Add sign-in method**.
6. Choose **Security key** (if you have a physical YubiKey/FIDO2 key) or follow prompts for Windows Hello.
7. Follow your browser's prompts to touch your hardware key or register your biometric data.

---

## Phase 4: Build the Context-Aware Conditional Access Policy
This is the core of Lab 1. We will build a policy that says: *"If the pilot group tries to access our apps, they MUST use a phishing-resistant credential. A password is not enough."*

1. Close the Incognito window and return to your admin session in the Entra admin center.
2. Navigate to **Protection > Conditional Access > Policies**.
3. Click **New policy**.
4. Name: `Enforce Phishing-Resistant MFA for Pilot Group`.

*(Image: Conditional Access Policy Settings)*
![Conditional Access Settings](Conditional_Access_Policy_settings.jpg)

### Assignments:
* **Users:** Click **Include** -> Select users and groups -> Check `ZT-Pilot-Group`. Click **Exclude** -> Select users and groups -> Check your `EmergencyAdmin` account (and your primary admin account just to be safe).
* **Target resources:** Click **Include** -> Select **All cloud apps**.
* **Conditions > Locations (Optional Context Rule):** Configure: Yes. Include: Any location. Exclude: All trusted networks.

### Access controls:
* **Grant:** Select **Grant access**.
* Check **Require authentication strength**.
* From the dropdown, select **Phishing-resistant MFA strength** (If you do not have a FIDO2 key to test with, select *Multifactor authentication strength* instead so you can test using the Microsoft Authenticator app).
* Click **Select**.

### Enable Policy:
* Under Enable policy, select **On** (Normally you select Report-Only for a few days in production, but for this lab, we want immediate enforcement).
* Click **Create**.

---

## Phase 5: Test and Verify the Zero Trust Perimeter

1. Open a fresh Private/Incognito window.
2. Go to the Azure Portal (`portal.azure.com`) or any Office 365 app.
3. Enter the `ZeroTrustTestUser` email address.
4. Try to log in with the user's standard password.

**The Result:** Entra ID will accept the password, but the Conditional Access policy will intercept the session. It will evaluate the user's context, see that they are required to use Phishing-Resistant MFA, and block access until the user inserts their FIDO2 key or uses Windows Hello.

*(Image: Phishing-Resistant MFA Conditional Policy Applied)*
![Policy Applied](Phishing_Resiting_MFA_Conditional_Policy_Applied.jpg)

**Conclusion:** You have successfully detached trust from the network (the internet) and attached it to the context of the identity (requiring hardware-backed MFA).
