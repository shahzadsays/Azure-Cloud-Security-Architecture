# AZ-500 End-to-End Security Engineering Lab

A security-focused Azure lab that demonstrates a Zero-Trust hub-and-spoke architecture with Azure Firewall, private endpoints, managed identity, Azure Key Vault RBAC, and Microsoft Sentinel monitoring.

This project is designed as an AZ-500 portfolio lab and includes a full troubleshooting ledger to show real-world deployment, error handling, and remediation.

Azure documentation confirms the use of Key Vault RBAC for secrets access, private endpoints for restricted access, and Azure Firewall forced tunneling / UDR patterns for controlled egress. [web:118][web:133][web:135]

---

## Lab Goal

The goal of this lab is to build an isolated application workload that can retrieve a secret from Azure Key Vault over private connectivity only, while all audit activity is captured in Microsoft Sentinel.

---

## Architecture Overview

```text
SecureHubVNet (10.0.0.0/16)
├── AzureFirewallSubnet (10.0.1.0/24)
└── AzureBastionSubnet (10.0.2.0/24)

AppSpokeVNet (172.16.0.0/16)
└── ComputeSubnet (172.16.1.0/24)
```

### Design Summary

- Hub VNet contains Azure Firewall and Azure Bastion.
- Spoke VNet contains the application VM.
- Outbound traffic from the spoke is forced through Azure Firewall.
- Key Vault access is restricted to private network paths.
- Managed identity is used to access secrets.
- Diagnostic logs are sent to Log Analytics and Microsoft Sentinel.

Azure guidance supports RBAC-based Key Vault access, private access controls, and logging integration for security operations. [web:118][web:119][web:133][web:134]

---

## Network Design

### Hub VNet

| Subnet | Address Space | Purpose |
|---|---:|---|
| AzureFirewallSubnet | `10.0.1.0/24` | Azure Firewall |
| AzureBastionSubnet | `10.0.2.0/24` | Azure Bastion |

### Spoke VNet

| Subnet | Address Space | Purpose |
|---|---:|---|
| ComputeSubnet | `172.16.1.0/24` | Application VM |

---

## Deployment Phases

### Phase 1: Network Foundation

1. Create `SecureHubVNet` with `10.0.0.0/16`.
2. Create `AppSpokeVNet` with `172.16.0.0/16`.
3. Peer the two VNets.
4. Deploy Azure Firewall in `AzureFirewallSubnet`.
5. Create a UDR on `ComputeSubnet` pointing `0.0.0.0/0` to the firewall private IP.

Azure Firewall forced tunneling and UDR-based routing are standard mechanisms for controlling outbound traffic in secure designs. [web:135]

### Phase 2: Secure Compute

1. Deploy `AppControllerVM` in `ComputeSubnet`.
2. Remove public IP access.
3. Apply a deny-by-default NSG to the subnet.
4. Enable the system-assigned managed identity on the VM.

### Phase 3: SQL Private Access

1. Deploy Azure SQL Database.
2. Disable public access.
3. Create a private endpoint in the spoke network.
4. Enable private DNS integration for `privatelink.database.windows.net`.

### Phase 4: Key Vault Hardening

1. Create Key Vault `ent-kv-poc-2026`.
2. Use Azure RBAC permission model.
3. Restrict public access.
4. Bind the vault to the spoke subnet or equivalent private access path.

### Phase 5: Monitoring and SIEM

1. Create Log Analytics workspace `soc-workspace`.
2. Enable Microsoft Sentinel.
3. Send Key Vault audit logs to the workspace.

---

## Key Vault Access Model

This lab uses Azure RBAC instead of legacy access policies. The VM’s managed identity must be granted a data-plane role such as **Key Vault Secrets User** to read secrets. Azure documents RBAC as the recommended way to manage Key Vault permissions centrally. [web:118]

### Common Roles Used

- Key Vault Secrets Officer
- Key Vault Secrets User

---

## Validation Workflow

### 1. Managed Identity Token Test

Use the VM’s system-assigned identity to request an access token from IMDS.

### 2. Secret Retrieval Test

Use the token to query the Key Vault secret over the private endpoint path.

### 3. Log Verification

Confirm the secret access operation appears in Microsoft Sentinel / Log Analytics with a successful result.

Azure Key Vault diagnostics can be routed to Log Analytics for auditing and incident investigation. [web:134]

---

## RCA Ledger

This lab intentionally captured several real deployment issues and their fixes.

### Network Access Blocked

**Symptom:**  
“Firewall is turned on and your client IP address is not authorized...”

**Root Cause:**  
Key Vault public access was disabled and the vault was restricted to private network paths.

**Fix:**  
Temporarily added the current client IP for portal-based management.

### RBAC Denied

**Symptom:**  
“The operation is not allowed by RBAC...”

**Root Cause:**  
The user had control-plane permissions but no data-plane secret access role.

**Fix:**  
Assigned **Key Vault Secrets Officer**.

### Package Download Failure

**Symptom:**  
`HTTP Status Code 470`

**Root Cause:**  
Forced tunneling sent outbound traffic through Azure Firewall, which blocked unapproved internet access.

**Fix:**  
Avoided unnecessary package installs and used native runtime tooling.

### IMDS / Token Fetch Error

**Symptom:**  
`HTTP Error 400: Bad Request`

**Root Cause:**  
Malformed request payload due to paste/line-break corruption.

**Fix:**  
Moved the test into a local script file.

### Managed Identity Missing

**Symptom:**  
`HTTP Error 400` after rebuild.

**Root Cause:**  
The VM was recreated and its managed identity had to be re-enabled.

**Fix:**  
Turned system-assigned identity back on.

### Key Vault Forbidden

**Symptom:**  
`HTTP Error 403: Forbidden`

**Root Cause:**  
The VM identity was valid, but it did not yet have a Key Vault data-plane role.

**Fix:**  
Assigned **Key Vault Secrets User** to the VM identity.

---

## Sample Validation Script

```bash
cat << 'EOF' > test_kv.py
import urllib.request, json

try:
    req = urllib.request.Request("http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net")
    req.add_header("Metadata", "true")
    token = json.loads(urllib.request.urlopen(req).read().decode())["access_token"]

    req2 = urllib.request.Request("https://ent-kv-poc-2026.vault.azure.net/secrets/DbConnectionString/?api-version=7.4")
    req2.add_header("Authorization", f"Bearer {token}")
    secret_value = json.loads(urllib.request.urlopen(req2).read().decode())["value"]

    print(f"\n✅ SUCCESS! Secret Value: {secret_value}\n")

except Exception as e:
    print(f"\n❌ ERROR: {e}\n")
EOF

python3 test_kv.py
```

---

## Sentinel Query

```kql
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.KEYVAULT"
| where OperationName == "SecretGet"
| project TimeGenerated, Resource, OperationName, ResultType, CallerIPAddress, requestUri_s
| sort by TimeGenerated desc
```

This query helps confirm secret retrieval activity and audit visibility in the SOC pipeline. Azure supports forwarding Key Vault diagnostics into Log Analytics for this type of monitoring. [web:134]

---

## What This Lab Demonstrates

- Hub-and-spoke Azure security design
- Azure Firewall forced egress control
- Private endpoints and private DNS
- Managed identity-based secret retrieval
- Azure Key Vault RBAC
- Microsoft Sentinel logging and validation
- Practical troubleshooting and RCA documentation

---

## Repository Structure

```text
az500-security-lab/
├── network/
├── compute/
├── keyvault/
├── sql/
├── sentinel/
├── scripts/
└── README.md
```

---

## Notes

- This lab is designed to keep the compute workload credential-less.
- Public exposure is intentionally minimized.
- Managed identity and RBAC are central to the design.
- The RCA ledger is included to show real engineering problem-solving.

---

## License

For educational and portfolio use.
