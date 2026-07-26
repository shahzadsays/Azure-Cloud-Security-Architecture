# Azure Enterprise Architecture POC (Part 1 — Core Platform)

A cost-optimized, enterprise-style Azure landing zone proof of concept built for AZ-305, AZ-700, SC-100, and AZ-500.  
This lab demonstrates a **cheap & effective** hub-and-spoke design using Developer and B-tier services while still applying Zero Trust principles, centralized firewall egress control, private endpoints, and API Management injection.

---

## Objectives

- Build a resilient hub-and-spoke network foundation.
- Centralize outbound inspection and control through Azure Firewall Premium.
- Use private endpoints and private DNS to remove public exposure from core services.
- Deploy API Management in an internal VNet-injected model.
- Enforce routing so spoke-to-spoke traffic flows through the hub only.
- Prepare a real-world portfolio project for cloud and security interviews.

---

## Architecture Overview

### Logical Topology

```text
Azure Front Door Premium
        |
        | Private Link Service
        v
Hub-VNet (10.0.0.0/16)
        |
        +-------------------+-------------------+-------------------+
        |                   |                   |                   |
 APIM-Spoke            App-Spoke            Data-Spoke
 (10.3.0.0/16)         (10.1.0.0/16)         (10.2.0.0/16)
```

### Design Principles

- Hub-and-spoke connectivity with no direct spoke-to-spoke peering.
- Centralized security inspection through the hub.
- Private access for backend services.
- Cost-conscious SKUs where possible.
- Controlled exceptions for platform services and management flows.

---

## Virtual Networks

### Hub-VNet
**Address space:** `10.0.0.0/16`

| Subnet | Address Space | Purpose |
|---|---:|---|
| AzureFirewallSubnet | `10.0.1.0/24` | Azure Firewall Premium |
| AzureBastionSubnet | `10.0.2.0/24` | Azure Bastion |
| AppGatewaySubnet | `10.0.3.0/24` | Application Gateway |

> `AzureFirewallSubnet` must use the exact subnet name.  
> `AppGatewaySubnet` should **not** be named `GatewaySubnet`.

### APIM-Spoke
**Address space:** `10.3.0.0/16`

| Subnet | Address Space | Purpose |
|---|---:|---|
| APIM-Injection-Subnet | `10.3.1.0/24` | Internal APIM deployment |

### App-Spoke
**Address space:** `10.1.0.0/16`

| Subnet | Address Space | Purpose |
|---|---:|---|
| App-Compute-Subnet | `10.1.1.0/24` | App workloads, VNet integration |

### Data-Spoke
**Address space:** `10.2.0.0/16`

| Subnet | Address Space | Purpose |
|---|---:|---|
| Private-Endpoint-Subnet | `10.2.1.0/24` | Private endpoints |
| SQL-DB-Subnet | `10.2.2.0/24` | Optional data segmentation |

---

## Peering Model

- Peer `Hub-VNet ↔ APIM-Spoke`
- Peer `Hub-VNet ↔ App-Spoke`
- Peer `Hub-VNet ↔ Data-Spoke`
- Enable **Allow forwarded traffic** on both sides.

> Do not peer spokes to each other. All cross-spoke communication should traverse the hub.

---

## Azure Firewall Premium

Azure Firewall Premium is used for centralized egress control, DNS proxy, and TLS inspection. Microsoft documents TLS inspection as a Premium capability, and Firewall Premium policy-based deployments are the correct model for this design. [web:31][web:35]

### Public IP
- **Name:** `pip-hub-firewall-prod-01`
- **SKU:** Standard
- **Tier:** Regional

### Firewall
- **Tier:** Premium
- **Policy:** `afwp-hub-core-policy`
- **VNet:** `Hub-VNet`

### Firewall Policy Settings
- Enable **DNS Proxy**.
- Enable **TLS inspection**.
- Import the required intermediate CA certificate for TLS inspection.

### Network Rules
**Collection:** `Allow-Infrastructure-Egress`
- Source: `10.3.1.0/24`
- Protocol: `TCP`
- Destination ports: `80,443`
- Destination: `AzureCloud`

### Application Rules
**Collection:** `Allow-Core-Endpoints`

| Rule Name | Source | Protocol | Target FQDN |
|---|---|---|---|
| Allow-Data-Spoke | `10.1.1.0/24` | `https:443` | `*.database.windows.net` |
| Allow-Vault-Spoke | `10.1.1.0/24` | `https:443` | `*.vault.azure.net` |
| Allow-APIM-Spoke | `10.1.1.0/24` | `https:443` | `*.azure-api.net` |

---

## APIM Subnet Security

Azure API Management supports VNet injection in Developer and Premium tiers, and Microsoft documents network requirements for APIM virtual network injection. [web:52]

### Service Endpoints
Enable these on `APIM-Injection-Subnet`:
- `Microsoft.KeyVault`
- `Microsoft.Storage`
- `Microsoft.Sql`

### APIM NSG
**Name:** `nsg-apim-spoke`

#### Inbound Rules
- Allow `ApiManagement` → TCP `3443`
- Allow `AzureLoadBalancer` → TCP `6390`

#### Outbound Rules
- Allow `Storage` → TCP `443`
- Allow `KeyVault` → TCP `443`

---

## Route Tables

### rt-spoke-to-firewall
Used by App-Spoke for forced tunneling.

#### Routes
- `Default-Forced-Tunnel`
  - Destination: `0.0.0.0/0`
  - Next hop: Virtual appliance
  - Next hop IP: Firewall private IP

- `Bypass-APIM-ControlPlane`
  - Destination: Service Tag `ApiManagement`
  - Next hop: Internet

### rt-appgateway
Used by the hub application gateway subnet.

#### Routes
- `Direct-Internet-Return`
  - Destination: `0.0.0.0/0`
  - Next hop: Internet

- `To-Internal-APIM`
  - Destination: `10.3.1.0/24`
  - Next hop: Virtual appliance
  - Next hop IP: Firewall private IP

### rt-private-endpoints
Used by the private endpoint subnet.

#### Routes
- `Back-To-Compute`
  - Destination: `10.1.1.0/24`
  - Next hop: Virtual appliance
  - Next hop IP: Firewall private IP

---

## Private DNS Zones

Private DNS zones are used so private endpoint-enabled services resolve correctly inside the hub-and-spoke architecture. Azure documentation supports linking private DNS zones to VNets for private endpoint name resolution. [web:51][web:56]

### Zones
- `privatelink.database.windows.net`
- `privatelink.vaultcore.azure.net`
- `privatelink.azure-api.net`
- `privatelink.blob.core.windows.net`

### VNet Links
Link each private DNS zone to:
- `Hub-VNet`
- `App-Spoke`
- `Data-Spoke`
- `APIM-Spoke`

> Leave **auto-registration disabled**.

### Custom DNS
Set DNS servers on:
- `APIM-Spoke`
- `App-Spoke`
- `Data-Spoke`

Use the **Azure Firewall private IP** as the custom DNS server.

---

## API Management Deployment

Deploy API Management in **Developer** tier to keep the lab cost-effective while still supporting VNet injection. Azure’s APIM documentation confirms this is a valid deployment model for virtual network injection scenarios. [web:52]

### APIM Settings
- **Tier:** Developer
- **Network mode:** Internal
- **VNet:** `APIM-Spoke`
- **Subnet:** `APIM-Injection-Subnet`

### Private IP
After deployment, copy the gateway private IP from the APIM resource properties.

### Private DNS Record Sets
In `privatelink.azure-api.net`, create:
- `api` → APIM gateway private IP
- `management` → APIM gateway private IP
- `portal` → APIM gateway private IP

---

## Private Backend Services

### App Service
- **Plan:** Basic B1
- Enable VNet integration with `App-Spoke / App-Compute-Subnet`
- Disable public inbound access
- Create an inbound private endpoint in `Data-Spoke / Private-Endpoint-Subnet`

### Storage Account and Key Vault
- Use Standard LRS for Storage
- Use standard Key Vault with Azure RBAC
- Disable public network access or restrict to selected networks
- Create private endpoints in `Data-Spoke / Private-Endpoint-Subnet`
- Link each service to the correct Private DNS zone

---

## SQL Data Layer

Azure SQL Database can be used in a cost-optimized configuration such as Basic or Serverless depending on the lab goal. Private endpoints and private DNS are the correct approach for keeping the data tier off the public internet. [web:51][web:56]

### SQL Configuration
- Provision SQL logical server and database.
- Set public network access to **Disabled**.
- Create a private endpoint in `Data-Spoke / Private-Endpoint-Subnet`.
- Link it to `privatelink.database.windows.net`.

---

## Global Ingress Layer

### Application Gateway
- **Tier:** WAF v2
- **Instance count:** 1
- **VNet:** `Hub-VNet`
- **Subnet:** `AppGatewaySubnet`
- **Frontend:** Private IP

### Backend Pool
- Target the internal APIM gateway private IP.

> Azure Application Gateway WAF v2 is a valid ingress layer for controlled internal/private routing scenarios, and private deployment options are supported in Microsoft guidance. [web:27][web:26]

---

## Monitoring and Governance

### Log Analytics
Create a Log Analytics Workspace and connect diagnostic settings for:
- Azure Firewall
- API Management
- SQL Logical Server

### Microsoft Sentinel
Enable Microsoft Sentinel on the workspace for centralized threat detection and SIEM correlation.

---

## Verification Queries

Use the following KQL query in Microsoft Sentinel to validate Azure Firewall application-rule traffic to core private services:

```kql
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.NETWORK" and Category == "AZFWApplicationRule"
| extend Action = extract(@"Action: ([a-zA-Z]+)\.", 1, msg_s),
         FQDN = extract(@"To: ([a-zA-Z0-9\-\.\*]+):", 1, msg_s)
| where FQDN has_any ("database.windows.net", "vault.azure.net", "azure-api.net")
| project TimeGenerated, Action, FQDN, Protocol=extract(@"with ([A-Z]+)", 1, msg_s), SourceIP=extract(@"From: ([0-9\.]+):", 1, msg_s), msg_s
| order by TimeGenerated desc
```

---

## Skills Demonstrated

- Azure Virtual Networks
- Hub-and-spoke design
- Azure Firewall Premium
- NSG and UDR design
- Private endpoints and Private DNS
- API Management VNet injection
- Azure Bastion
- Application Gateway WAF v2
- Log Analytics and Microsoft Sentinel
- Zero Trust enterprise architecture

---

## Why This Lab Matters

This project demonstrates practical enterprise architecture knowledge with a strong balance of security, cost control, and implementation realism. It is especially useful for interviews and portfolio review because it shows that you can design a secure landing zone, not just deploy isolated services.

---

## Repository Structure

```text
azure-enterprise-poc/
├── architecture/
├── firewall/
├── networking/
├── apim/
├── app/
├── data/
├── monitoring/
└── README.md
```

---

## License

For portfolio and educational use.
