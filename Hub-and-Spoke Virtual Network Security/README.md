# Hub-and-Spoke Virtual Network Security, Azure Firewall Premium Inspection, and Microsoft Sentinel SIEM Lab

This repository contains a granular, step-by-step portfolio guide for building an isolated, production-grade cloud enterprise network topology[cite: 5]. All cross-network traffic is intercepted and deep-packet inspected by a centralized Azure Firewall Premium utilizing User-Defined Routes (UDRs), with full operational audit tracking managed via Microsoft Sentinel[cite: 5].

## 🗺️ Lab Architecture Map & IP Plan
* **Resource Group:** Create a single group named `rg-dmz-fw-lab` for all resources[cite: 5].
* **Hub VNet (`vnet-hub-dmz`):** `10.0.0.0/16`[cite: 5]
  * `AzureFirewallSubnet` ── `10.0.1.0/24` (Reserved for Azure Firewall)[cite: 5]
  * `AzureBastionSubnet` ── `10.0.2.0/27` (Reserved for Azure Bastion)[cite: 5]
  * `DMZ-Subnet` ────────── `10.0.3.0/24` (Hosts the management jump host VM)[cite: 5]
  * `Logging-Subnet` ────── `10.0.4.0/24` (Reserved for diagnostic integrations)[cite: 5]
* **App Spoke VNet (`vnet-spoke-app`):** `10.1.0.0/16`[cite: 5]
  * `App-Subnet` ────────── `10.1.1.0/24` (Hosts the application compute VM)[cite: 5]
* **Data Spoke VNet (`vnet-spoke-data`):** `10.2.0.0/16`[cite: 5]
  * `Data-Subnet` ───────── `10.2.1.0/24` (Hosts backend storage/database nodes)[cite: 5]
  * `PrivateEndpoint-Subnet` `10.2.2.0/24` (Hosts the database private network interface)[cite: 5]

---

## 🛠️ Step-by-Step Implementation Guide

### Step 1: Create the Virtual Networks (VNets)
We must first build our three distinct network rooms and carve out their required subnets[cite: 5].

**A. Create the Hub Network**
* Log into the Azure Portal[cite: 5].
* Search for Virtual networks in the top search bar and click **Create**[cite: 5].
* **Basics Tab:** Resource Group: Click **Create new** and type `rg-dmz-fw-lab`[cite: 5]. Name: `vnet-hub-dmz`[cite: 5]. Region: East US (or your preferred deployment region)[cite: 5].
* **IP Addresses Tab:** Change the starting IPv4 address space to `10.0.0.0/16`[cite: 5]. Click **+ Add subnet** to build the following four subnets sequentially[cite: 5]:
  * Subnet 1 Name: `AzureFirewallSubnet` | Range: `10.0.1.0/24` (Must use this exact name)[cite: 5]
  * Subnet 2 Name: `AzureBastionSubnet` | Range: `10.0.2.0/27` (Must use this exact name)[cite: 5]
  * Subnet 3 Name: `DMZ-Subnet` | Range: `10.0.3.0/24`[cite: 5]
  * Subnet 4 Name: `Logging-Subnet` | Range: `10.0.4.0/24`[cite: 5]
* Click **Review + create**, then click **Create**[cite: 5].

**B. Create the App Spoke Network**
* Go back to Virtual networks, click **Create**[cite: 5].
* **Basics Tab:** Select resource group `rg-dmz-fw-lab` and name the network `vnet-spoke-app`[cite: 5].
* **IP Addresses Tab:** Change the IPv4 address space to `10.1.0.0/16`[cite: 5]. Click **+ Add subnet** -> Name it `App-Subnet` | Range: `10.1.1.0/24`[cite: 5].
* Click **Review + create**, then click **Create**[cite: 5].

**C. Create the Data Spoke Network**
* Go back to Virtual networks, click **Create**[cite: 5].
* **Basics Tab:** Select resource group `rg-dmz-fw-lab` and name the network `vnet-spoke-data`[cite: 5].
* **IP Addresses Tab:** Change the IPv4 address space to `10.2.0.0/16`[cite: 5].
  * Click **+ Add subnet** -> Name it `Data-Subnet` | Range: `10.2.1.0/24`[cite: 5].
  * Click **+ Add subnet** again -> Name it `PrivateEndpoint-Subnet` | Range: `10.2.2.0/24`[cite: 5].
* Click **Review + create**, then click **Create**[cite: 5].

### Step 2: Establish Hub-and-Spoke Transits (VNet Peering)
To force traffic through our firewall later, spokes must peer with the Hub VNet[cite: 5]. Do not peer the App Spoke directly to the Data Spoke[cite: 5].

* Open your `vnet-hub-dmz` network resource page in the portal[cite: 5].
* On the left sidebar menu under Settings, click **Peerings**, then click **+ Add**[cite: 5].
* Configure the Hub-to-App peering connection link[cite: 5]:
  * This virtual network -> Peering link name: `hub-to-app`[cite: 5]
  * Remote virtual network -> Peering link name: `app-to-hub`[cite: 5]
  * Remote virtual network: Select `vnet-spoke-app` from the dropdown list[cite: 5].
  * Under the Traffic forwarded from remote virtual network setting, ensure **Allow (default)** is checked[cite: 5].
  * Click **Add**[cite: 5].
* Click **+ Add** a second time to connect the Hub-to-Data path[cite: 5]:
  * This virtual network -> Peering link name: `hub-to-data`[cite: 5]
  * Remote virtual network -> Peering link name: `data-to-hub`[cite: 5]
  * Remote virtual network: Select `vnet-spoke-data` from the dropdown list[cite: 5].
  * Under Traffic forwarded from remote virtual network, ensure **Allow (default)** is checked[cite: 5].
  * Click **Add**[cite: 5].

### Step 3: Deploy Azure Firewall Premium
* Search for **Firewalls** in the top search bar and click **Create**[cite: 5].
* **Basics Tab:**
  * Resource Group: `rg-dmz-fw-lab`[cite: 5]
  * Name: `afw-premium-hub`[cite: 5]
  * SKU Tier: Select **Premium**[cite: 5].
  * Firewall Policy: Click **Create new** -> Name it `afwp-dmz-hub` -> Set the Policy tier to **Premium** to match[cite: 5]. Click **OK**[cite: 5].
  * Choose a virtual network: Select **Use existing** and choose `vnet-hub-dmz`[cite: 5]. *(Azure will automatically pick up your AzureFirewallSubnet)*[cite: 5].
  * Public IP address: Click **Create new** -> Name it `pip-afw-premium-hub`[cite: 5].
* Click **Review + create**, then click **Create**[cite: 5]. *(This deployment can take 5 to 10 minutes)*[cite: 5].
* Once deployment completes, click **Go to resource**[cite: 5]. From the Overview dashboard, copy down the Firewall private IP (it will typically be `10.0.1.4`)[cite: 5]. You will need this for the next step[cite: 5].

### Step 4: Enforce Routing Override Tables (Forced Tunneling)
By default, Azure allows networks to talk directly if peered[cite: 5]. We must break this behavior by deploying User-Defined Routes (UDRs) that force all traffic through our firewall's private IP[cite: 5].

**A. App Spoke Route Table**
* Search for **Route tables** in the top search bar and click **Create**[cite: 5].
* **Basics Tab:** Select resource group `rg-dmz-fw-lab`, name it `rt-app-spoke`, and click **Review + create** -> **Create**[cite: 5].
* Open your newly created `rt-app-spoke` resource page[cite: 5].
* On the left sidebar menu, click **Routes**, then click **+ Add**[cite: 5]:
  * Route name: `default-to-fw`[cite: 5]
  * Destination type: IP Addresses[cite: 5]
  * Destination IP addresses/CIDR ranges: `0.0.0.0/0` *(This catches all outbound and cross-network traffic)*[cite: 5]
  * Next hop type: Select **Virtual appliance**[cite: 5].
  * Next hop address: Type your Firewall private IP (e.g., `10.0.1.4`)[cite: 5].
  * Click **Add**[cite: 5].
* On the left sidebar menu, click **Subnets**, click **Associate**[cite: 5]:
  * Virtual network: Select `vnet-spoke-app`[cite: 5].
  * Subnet: Select `App-Subnet`[cite: 5]. Click **OK**[cite: 5].

**B. Data Spoke Route Table**
* Go back to Route tables, click **Create**[cite: 5].
* **Basics Tab:** Select resource group `rg-dmz-fw-lab`, name it `rt-data-spoke`, and click **Review + create** -> **Create**[cite: 5].
* Open your `rt-data-spoke` resource page, click **Routes** -> **+ Add**[cite: 5]:
  * Route name: `default-to-fw`[cite: 5]
  * Destination type: IP Addresses | Range: `0.0.0.0/0`[cite: 5]
  * Next hop type: Virtual appliance | Next hop address: Type your Firewall private IP (`10.0.1.4`)[cite: 5].
  * Click **Add**[cite: 5].
* Click **Subnets** on the left menu, then click **Associate**[cite: 5]:
  * Virtual network: Select `vnet-spoke-data`[cite: 5].
  * Subnet: Select `Data-Subnet`[cite: 5]. Click **OK**[cite: 5].
> ⚠️ **Important Security Note:** Do not associate this route table with your `PrivateEndpoint-Subnet`[cite: 5]. Azure Private Endpoints require default network system paths to operate properly without running into asymmetric routing locks[cite: 5].

### Step 5: Provision Core Compute and Bastion Host
We need a management stepping stone (Jump Host) in the Hub and an application server machine in the App Spoke[cite: 5].

**A. Set up Azure Bastion**
* Open your `vnet-hub-dmz` network page[cite: 5].
* On the left menu under Automation/Monitoring, click **Bastion**, then click **Configure manually**[cite: 5].
* **Settings:** Name it `bastion-hub`[cite: 5]. Ensure it selects your `AzureBastionSubnet`[cite: 5]. Under Public IP, create a new resource named `pip-bastion-hub`[cite: 5].
* Click **Create** and wait for deployment[cite: 5].

**B. Create the DMZ Jump Host VM**
* Search for Virtual machines and click **Create** -> **Azure virtual machine**[cite: 5].
* **Basics:** Name it `vm-dmz-jump`, choose an Ubuntu or Windows Server OS, and configure local administrator login details[cite: 5].
* **Networking Tab:**
  * Virtual network: Select `vnet-hub-dmz`[cite: 5].
  * Subnet: Select `DMZ-Subnet`[cite: 5].
  * Public IP: Select **None**[cite: 5].
* Click **Review + create** -> **Create**[cite: 5].

**C. Create the App Spoke VM**
* Go back to Virtual machines, click **Create** -> **Azure virtual machine**[cite: 5].
* **Basics:** Name it `vm-app-01`, select an Ubuntu Server OS edition, and create your credentials[cite: 5].
* **Networking Tab:**
  * Virtual network: Select `vnet-spoke-app`[cite: 5].
  * Subnet: Select `App-Subnet`[cite: 5].
  * Public IP: Select **None**[cite: 5].
* Click **Review + create** -> **Create**[cite: 5].

### Step 6: Create the Isolated SQL Server & Private Endpoint
Now we construct our cloud database server, shut down its public internet paths entirely, and give it a secure internal network adapter[cite: 5].

**A. Build the SQL Server & Database**
* Search for **SQL servers** in the top search bar and click **Create**[cite: 5].
* **Basics Tab:** Select your resource group, name it `sql-srv-dmzlab`, and select your primary region[cite: 5].
* **Authentication:** Select Use both SQL and Microsoft Entra authentication[cite: 5]. Define your master administrator user details and password[cite: 5].
* **Networking Tab:** Connectivity method: Select **Disable public access**[cite: 5].
* Click **Review + create** -> **Create**[cite: 5].
* Once deployed, navigate to the server's resource page, click **Create database** from the top command menu, name it `sqldb-appdata`, and finish database creation[cite: 5].

**B. Connect the Private Endpoint**
* Open your SQL Server resource page (`sql-srv-dmzlab`)[cite: 5].
* On the left menu under Security, click **Networking**[cite: 5].
* Click the **Private access** tab at the top of the workspace, then click **+ Private endpoint**[cite: 5].
* **Basics Tab:** Name the endpoint interface link `pe-sql-dmzlab`[cite: 5]. Click **Next**[cite: 5].
* **Resource Tab:** Verify the tracking type matches `Microsoft.Sql/servers` and set Target sub-resource explicitly to `sqlServer`[cite: 5]. Click **Next**[cite: 5].
* **Virtual Network Tab:**
  * Virtual network: Select `vnet-spoke-data`[cite: 5].
  * Subnet: Select `PrivateEndpoint-Subnet` (`10.2.2.0/24`)[cite: 5]. Click **Next**[cite: 5].
* **Configuration Tab:**
  * Integrate with private DNS zone: Ensure this is checked **Yes** and registers a zone profile called `privatelink.database.windows.net`[cite: 5].
* Click **Review + create**, then click **Create**[cite: 5].

**C. Link Private DNS to All Networks**
* Because our compute workloads are running inside isolated VNets, we must grant them access to read the custom private DNS zone[cite: 5].
* Search for **Private DNS zones** in the top portal search bar and click on `privatelink.database.windows.net`[cite: 5].
* On the left navigation menu under Settings, click **Virtual network links**, then click **+ Add**[cite: 5].
* **Add App VNet:** Name the link `link-to-app-vnet`, choose virtual network `vnet-spoke-app`, and click **OK**[cite: 5].
* Click **+ Add** a second time:
  * **Add Data VNet:** Name the link `link-to-data-vnet`, choose virtual network `vnet-spoke-data`, and click **OK**[cite: 5].

### Step 7: Enforce Firewall Premium Zero-Trust Routing Rules
With traffic redirected to our firewall, we must define strict rules to allow authorized application connections while dropping everything else[cite: 5].

* Search for **Firewall Policies** in the top search bar and select `afwp-dmz-hub`[cite: 5].

**Set Up Network Rules (Layer 4 Paths):**
* On the left sidebar, click **Network rules**, then click **+ Add rule collection**[cite: 5].
* Collection Name: `rc-net-core` | Type: Network | Priority: 100 | Action: Allow[cite: 5].
* Fill out the target table row parameters below[cite: 5]:
  * **Rule 1 Name:** `app-to-sql-pe` | Source Type: IP Addresses | Source: `10.1.1.0/24` | Protocol: TCP | Destination Ports: 1433 | Destination Type: IP Addresses | Destination: `10.2.2.0/24`[cite: 5]
  * **Rule 2 Name:** `dmz-to-app-ssh` | Source Type: IP Addresses | Source: `10.0.3.0/24` | Protocol: TCP | Destination Ports: 22 | Destination Type: IP Addresses | Destination: `10.1.1.0/24`[cite: 5]
* Click **Add**[cite: 5].

**Set Up Application Rules (Layer 7 URL Paths):**
* On the left sidebar, click **Application rules**, then click **+ Add rule collection**[cite: 5].
* Collection Name: `rc-app-web` | Type: Application | Priority: 200 | Action: Allow[cite: 5].
* Fill out the target application profile parameter[cite: 5]:
  * **Rule Name:** `app-secure-egress` | Source Type: IP Addresses | Source: `10.1.1.0/24` | Protocol:Port: `http:80,https:443` | Target FQDNs: `*.ubuntu.com`, `://ubuntu.com`[cite: 5]
* Click **Add**[cite: 5].

**Activate Threat Intelligence Engine:**
* On the left menu under Settings, click **Threat intelligence**[cite: 5].
* Change operation mode from Alert only to **Alert and deny**, then click **Save**[cite: 5].

### Step 8: Build Subnet Layer-4 Security Armor (Network Security Groups)
We add Network Security Groups (NSGs) to provide micro-segmentation and defense directly on our subnets[cite: 5].

**A. nsg-dmz (Attached to DMZ-Subnet)**
* Allows Azure Bastion to safely handle your jump host[cite: 5].
* Inbound Rule: Name = `Allow_Bastion_Inbound` | Source = `10.0.2.0/27` | Destination Port = 22 | Protocol = TCP | Action = Allow | Priority = 100[cite: 5].
* Inbound Rule: Name = `Deny_All_Other_Inbound` | Source = Any | Destination Port = * | Protocol = * | Action = Deny | Priority = 900[cite: 5].
* Association: Link to `vnet-hub-dmz` / `DMZ-Subnet`[cite: 5].

**B. nsg-app (Attached to App-Subnet)**
* Ensures the workload VM only accepts management traffic from the jump host[cite: 5].
* Inbound Rule: Name = `Allow_SSH_From_DMZ` | Source = `10.0.3.0/24` | Destination Port = 22 | Protocol = TCP | Action = Allow | Priority = 110[cite: 5].
* Inbound Rule: Name = `Deny_Lateral_Movement` | Source = `10.0.0.0/8` | Destination Port = * | Protocol = * | Action = Deny | Priority = 900[cite: 5].
* Association: Link to `vnet-spoke-app` / `App-Subnet`[cite: 5].

**C. nsg-data (Attached to Data-Subnet)**
* Blocks any direct network access attempts to internal data spoke VM workloads[cite: 5].
* Inbound Rule: Name = `Allow_From_PE_Subnet` | Source = `10.2.2.0/24` | Destination Port = * | Protocol = * | Action = Allow | Priority = 100[cite: 5].
* Inbound Rule: Name = `Deny_All_Direct_Access` | Source = Any | Destination Port = * | Protocol = * | Action = Deny | Priority = 950[cite: 5].
* Association: Link to `vnet-spoke-data` / `Data-Subnet`[cite: 5].

### Step 9: Initialize Sentinel Monitoring and Workspace Ingestion
* Search for **Log Analytics workspaces** and click **Create**[cite: 5]. Assign it to resource group `rg-dmz-fw-lab` and name it `law-dmz-fw-lab`[cite: 5].
* Search for **Microsoft Sentinel** in the top search bar, click **+ Add**, select your workspace `law-dmz-fw-lab`, and select **Add Microsoft Sentinel**[cite: 5].

**Forward Firewall Security Logs:**
* Go to your `afw-premium-hub` firewall page, click **Diagnostic settings** -> **+ Add diagnostic setting**[cite: 5].
* Check the boxes for `AZFWNetworkRule`, `AZFWApplicationRule`, and `AZFWThreatIntel`[cite: 5].
* Destination: Check **Send to Log Analytics workspace** and map it to `law-dmz-fw-lab`[cite: 5]. Click **Save**[cite: 5].

**Forward SQL Audit Logs:**
* Go to your `sql-srv-dmzlab` database server page, navigate to **Security** -> **Auditing**[cite: 5].
* Turn Auditing **ON**, check the Log Analytics destination checkbox, and choose your `law-dmz-fw-lab` workspace[cite: 5]. Click **Save**[cite: 5].

---

## 🔬 Network Validation Tests (How to Prove it Works)
Log into your Azure Portal and connect to your `vm-dmz-jump` VM using Azure Bastion[cite: 5]. From there, SSH into your internal app server: `ssh azureuser@10.1.1.4`[cite: 5]. Once inside your application instance terminal, run these verification checks[cite: 5]:

**Test A: DNS Resolution Check**
* Run an address tracking query against your logical server URL: `getent hosts sql-srv-dmzlab.database.windows.net`[cite: 5].
* **Expected Result:** The configuration maps directly to `sql-srv-dmzlab.privatelink.database.windows.net` and resolves exclusively to an internal private IP within your PE subnet (e.g., `10.2.2.4`), proving the Private DNS link works[cite: 5].

**Test B: Intercepted Port Validation Check**
* Verify your database connection path on port 1433 using the native shell interface proxy: `cat < /dev/tcp/sql-srv-dmzlab.database.windows.net/1433`[cite: 5].
* **Expected Result:** The console returns a `Connection reset by peer` message instantly[cite: 5]. This means your packet traveled through the Azure Firewall Premium rules successfully, hit the backend database endpoint, and was reset by the server due to an empty payload[cite: 5]. If the firewall blocked it, the command would hang and time out[cite: 5].

**Test C: Lateral Movement Blocking Check**
* Attempt to pass a manual connection scan straight to any address inside the backend data spoke subnet: `ping -c 1 10.2.1.4`[cite: 5].
* **Expected Result:** The request will fail[cite: 5]. Because you did not create a direct peering link between the two spoke networks, and the central firewall has no rule allowing this, unauthorized lateral network movement is completely blocked[cite: 5].

**Test D: Layer-7 Outbound Web Filter Check**
* Test the internet egress boundary by trying to browse an unauthorized website: `curl -I https://google.com`[cite: 5].
* **Expected Result:** The connection is dropped/denied by the firewall policy proxy engine[cite: 5].
* Next, try running an update command against a whitelisted address: `curl -I https://ubuntu.com`[cite: 5]. This request will return an HTTP 200 OK code, proving that your Layer-7 proxy configuration accurately filters outbound web traffic[cite: 5].

![Validation Results](Test%20Results%20successful.jpg)

## 📊 Microsoft Sentinel Validation Logs

![Sentinel Logging Verification](Micrsoft%20Sentinel%20Logs.jpg)
