# Azure SQL Private Endpoint Isolation Lab

This repository contains a step-by-step implementation guide for deploying an isolated Azure SQL Database architecture inside a multi-VNet corporate network environment. This lab enforces data exfiltration prevention by disabling public cloud entry points and routing app-to-database traffic completely over private Microsoft backbone infrastructure.

## 🗺️ Lab Architecture Overview

*   **VNet 1 (`vnet-org-app`):** Simulates the application/DMZ layer. Hosts client compute resources (e.g., Linux VMs).
*   **VNet 2 (`vnet-org-data`):** Simulates the secure data layer. Houses Private Endpoints and managed database services.
*   **VNet Peering:** Interconnects the two virtual networks to facilitate private transit routing.
*   **Private Endpoint:** Maps a private internal IP address from the data subnet directly to the Azure SQL Server.
*   **Private DNS Zone:** Authoritatively overwrites the server's public DNS string to point to the local private IP layout.

---

## 🛠️ Step-by-Step Implementation Guide

### Step 1: Provisions Virtual Networks (VNets)
1. Log into the **Azure Portal**.
2. Deploy the Application Network:
   * **Name:** `vnet-org-app`
   * **Address Space:** `10.0.0.0/16`
   * **Subnet Name:** `App-Subnet` | **Subnet Range:** `10.0.0.0/24`
3. Deploy the Data Network:
   * **Name:** `vnet-org-data`
   * **Address Space:** `10.1.0.0/16` *(Ensure no address space overlaps exist)*
   * **Subnet Name:** `PrivateEndpoint-Subnet` | **Subnet Range:** `10.1.0.0/24`

### Step 2: Establish VNet Peering
1. Navigate to the `vnet-org-app` resource page.
2. Select **Peerings** from the left sidebar and click **+ Add**.
3. Configure the bi-directional peering topology:
   * **This Virtual Network Link Name:** `app-to-data`
   * **Remote Virtual Network Link Name:** `data-to-app`
   * **Remote Virtual Network:** Select `vnet-org-data`
4. Leave traffic settings as default (*Allow*) and click **Add**.

### Step 3: Enforce Network Security Groups (NSGs)
1. Create two standard Network Security Groups named `nsg-org-app` and `nsg-org-data`.
2. Open `nsg-org-data`, click **Inbound security rules**, and select **+ Add**:
   * **Source:** `IP Addresses`
   * **Source IP / CIDR:** `10.0.0.0/16` *(Restricts traffic strictly to the application network)*
   * **Destination Port Ranges:** `1433` *(Default TDS SQL Server traffic port)*
   * **Protocol:** `TCP`
   * **Action:** `Allow`
   * **Priority:** `100`
   * **Rule Name:** `Allow_SQL_Traffic_From_AppVNet`
3. Bind the NSGs to their respective subnets via the **Subnets -> Associate** side menu:
   * Link `nsg-org-app` to `vnet-org-app / App-Subnet`.
   * Link `nsg-org-data` to `vnet-org-data / PrivateEndpoint-Subnet`.

### Step 4: Provision Isolated SQL Infrastructure
1. Go to **SQL Servers** in the Azure Marketplace and click **Create**.
2. Under the **Basics** tab, name your server (e.g., `sql-org-labserver`) and pair it to your matching lab deployment region.
3. For **Authentication**, select **Use both SQL and Microsoft Entra authentication** to enable both administrative paradigms. Define your secure credentials.
4. Under the **Networking** tab, toggle **Connectivity method** to **Disable public access**. This closes all exterior access pathways.
5. Finish creation, navigate to the newly built server resource, click **Create database**, and provision a database named `sqldb-orgdata`.

### Step 5: Configure the Private Endpoint
1. Open your **SQL Server** resource page.
2. On the left sidebar menu under *Security*, select **Networking**.
3. Select the **Private access** tab at the top and click **+ Private endpoint**.
4. Configure the following parameters:
   * **Basics Name:** `pe-sql-orglab`
   * **Resource Target Subresource:** `sqlServer`
   * **Virtual Network:** `vnet-org-data`
   * **Subnet:** `PrivateEndpoint-Subnet (10.1.0.0/24)`
5. Under the **Configuration** tab, ensure **Integrate with private DNS zone** is toggled to **Yes**. This instantiates the core `privatelink.database.windows.net` zone footprint.

### Step 6: Link Private DNS Zones to VNets
1. Search for **Private DNS zones** in your portal search bar and open `privatelink.database.windows.net`.
2. Click **Virtual network links** from the left-hand navigation window and select **+ Add**.
3. Create a link named `link-to-app-vnet` targeted at **`vnet-org-app`**.
4. Click **+ Add** a second time and create a link named `link-to-data-vnet` targeted at **`vnet-org-data`**.

---

## 🔬 Network Validation & Connection Verification

Standard ICMP ping executions fail in this architecture due to automated Azure gateway dropped packets. Connectivity testing must target the layer-4 TCP listening socket.

### Linux Client Verification (Ubuntu/Debian)
From a client virtual machine deployed on `vnet-org-app`, invoke the `netcat` utility to run an assertive connectivity probe:

```bash
# If netcat-openbsd is missing on your Linux client instance, install it via:
# sudo apt update && sudo apt install netcat-openbsd -y

nc -zv sql-org-labserver.database.windows.net 1433
```

#### Expected Output Trace (Success)
```text
Connection to sql-org-labserver.database.windows.net 1433 port [tcp/ms-sql-s] succeeded!
```

### Windows Client Verification (PowerShell Alternate)
If testing connectivity from a Windows client running inside the app subnet network boundaries, execute this native cmdlet:

```powershell
Test-NetConnection sql-org-labserver.database.windows.net -Port 1433
```
Ensure that the return mapping yields a clear value of `TcpTestSucceeded : True`.
