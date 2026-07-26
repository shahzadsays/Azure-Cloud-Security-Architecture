# Cloud Architecture & Cybersecurity Deployment Labs

Welcome to my deployment lab repository. This space serves as a centralized portfolio of hands-on Proof of Concept (PoC) architectures, demonstrating practical implementations across modern cloud and hybrid environments.

## 🎯 Repository Scope

The projects within this repository are isolated, functional deployment labs built to validate and document complex enterprise security configurations. Key focus areas include:

*   **Network Architecture:** Hub-and-spoke virtual network designs, advanced routing, micro-segmentation, and secure hybrid connectivity.
*   **Identity & Governance:** Zero Trust architecture, Conditional Access policies, Attribute-Based Access Control (ABAC) models, and Just-In-Time (JIT) access.
*   **Threat Detection & Response:** Automated incident remediation, SIEM/SOAR playbooks, and threat intelligence filtering.

---

## 🗂️ Lab Portfolio Directory

Each folder below represents a standalone PoC. Click on any project to view the detailed architecture diagrams, configuration steps, and validation results.

### 🛡️ Network Security & Routing
*   **[Enterprise Azure Application Gateway WAF v2 Architecture](./Enterprise%20Azure%20Application%20Gateway%20WAF%20v2)** 
    *   *Features: DMZ/WEB subnet isolation, Path-based routing, Zero Trust NSGs.*
*   **[Hub-and-Spoke Virtual Network Security](./Hub-and-Spoke%20Virtual%20Network%20Security)**
    *   *Features: Forced tunneling, Azure Firewall Premium, Deep Packet Inspection.*
*   **[Azure ExpressRoute Provider Connectivity](./Azure%20ExpressRoute)**
    *   *Features: BGP Private Peering, ExpressRoute Gateways, Hybrid routing.*
*   **[End-to-End Security Engineering]
    *    *Features: Hub-and-spoke Azure security design, Azure firewall forced egress control,private endpoints and private DNS, managed identity-based secret retrieval.
      
### 🔒 Data Protection & Isolation
*   **[Azure SQL Private Endpoint Isolation](./Azure%20SQL%20Private%20Endpoint%20Isolation)**
    *   *Features: Data exfiltration prevention, Private DNS zones, Public access disabled.*

### 🚨 Threat Detection & SIEM
*   **[Microsoft Sentinel SOAR: SSH Brute Force Detection](./Sentinel-SOAR-SSH-Brute-Force)**
    *   *Features: KQL Analytic Rules, Azure Logic Apps, Automated incident response.*

### 👤 Identity & Zero Trust
*   **[Zero Trust Conditional Access](./ZeroTrust-Conditional-Access)**
    *   *Features: Device compliance, MFA enforcement, Location-based access.*
*   **[Attribute-Based Access Control (ABAC)](./Attribute-Based%20Access%20Control)**
    *   *Features: Dynamic access conditions, Tag-based resource governance.*
*   **[Just-In-Time Access & Governance (PIM)](./Just-In-Time%20Access%20&%20Governance%20(PIM))**
    *   *Features: Time-bound role activations, Approval workflows, Entra ID PIM.*

### 🏢 Enterprise Blueprints
*   **[Azure Enterprise Architecture](./Azure%20Enterprise%20Architecture)**
    *   *Features: Comprehensive, multi-layered enterprise deployment methodologies.*

---

## 🛠️ Structure & Methodology

Inside each directory, you will find a dedicated `README.md` that acts as the primary documentation for that specific lab. These write-ups are structured to include:
1.  **High-Level Design:** The architectural intent and theoretical flow.
2.  **Prerequisites & IP Planning:** The baseline requirements and address spacing.
3.  **Step-by-Step Implementation:** Exact deployment procedures and configurations.
4.  **Validation:** The testing methodology used to prove the security controls are functioning as intended.
