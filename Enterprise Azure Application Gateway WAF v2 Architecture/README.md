# Azure WAF v2 DMZ → WEB Architecture Lab

A production-style Azure Application Gateway WAF v2 lab that demonstrates secure inbound web traffic inspection, subnet segmentation, path-based routing, and Bastion-only administration.

This lab is designed for AZ-104, AZ-305, AZ-500, SC-100, and SC-200 readiness and is also suitable as a GitHub portfolio project for cloud and security roles.

---

## Architecture Overview

### High-Level Design

```text
Internet
   |
   v
Azure Application Gateway WAF v2
(DMZ Subnet: 10.0.1.0/24)
   |
   v
WEB Subnet: 10.0.2.0/24
   |-----------------------------|
   |                             |
VM1: Amazon Prime Server     VM2: Netflix Server
(/prime)                     (/netflix)
```

### Subnets

| Subnet | Address Space | Purpose |
|---|---:|---|
| DMZ Subnet | 10.0.1.0/24 | Hosts Azure Application Gateway WAF v2 |
| WEB Subnet | 10.0.2.0/24 | Hosts backend Nginx virtual machines |

---

## Security Design

### Zero Trust Principles

- No public IPs are assigned to backend VMs.
- Administrative access is provided only through Azure Bastion.
- Traffic is segmented between DMZ and WEB layers.
- Backend access is restricted with NSGs.
- Application traffic is inspected through WAF v2 before reaching servers. Application Gateway v2 supports WAF and URL path-based routing. [web:27][web:21]

### Network Security Groups

#### DMZ-NSG
Attached to the DMZ subnet hosting Application Gateway WAF v2.

**Inbound**
- Allow Internet → 80
- Allow Internet → 443
- Allow GatewayManager → 65200-65535
- Allow AzureLoadBalancer → required platform traffic

**Outbound**
- Allow to WEB subnet → 80
- Allow to WEB subnet → 443
- Allow Azure services for platform connectivity

> Note: Application Gateway v2 subnets require special NSG handling, including Azure infrastructure-related ports and service tags. [web:23][web:24]

#### WEB-NSG
Attached to the WEB subnet hosting backend VMs.

**Inbound**
- Allow from DMZ subnet → 80
- Allow from DMZ subnet → 443
- Allow from Azure Bastion subnet → 22

**Outbound**
- Allow Azure services
- Temporary allow Internet → 80/443 for package updates during build

---

## Backend Servers

### VM1 — Amazon Prime Server

```bash
sudo apt update -y
sudo apt install nginx -y
sudo mkdir -p /var/www/html/prime
echo 'This is Amazon Prime Server' | sudo tee /var/www/html/prime/index.html > /dev/null
```

### VM2 — Netflix Server

```bash
sudo apt update -y
sudo apt install nginx -y
sudo mkdir -p /var/www/html/netflix
echo 'This is Netflix Server' | sudo tee /var/www/html/netflix/index.html > /dev/null
```

### Nginx Content Paths

- `/prime` serves content from VM1.
- `/netflix` serves content from VM2.

---

## Application Gateway WAF v2 Configuration

### Frontend

- Public IP attached to Azure Application Gateway.
- Listener configured for HTTP or HTTPS.

### Backend Pool

- VM1 private IP
- VM2 private IP

### Health Probes

- `/prime`
- `/netflix`

### Path-Based Routing

| Path | Backend Target |
|---|---|
| `/prime/*` | VM1 |
| `/netflix/*` | VM2 |

Application Gateway supports URL path-based routing for directing traffic to different backend pools based on the request path. [web:21][web:27]

---

## Testing

### Backend Validation

From VM1:
```bash
curl http://10.0.2.X/netflix
```

From VM2:
```bash
curl http://10.0.2.Y/prime
```

### Through WAF

```text
http://<WAF-Public-IP>/prime
http://<WAF-Public-IP>/netflix
```

### Expected Output

- Prime path: `This is Amazon Prime Server`
- Netflix path: `This is Netflix Server`

---

## Folder Structure

```text
azure-waf-lab/
├── architecture/
│   ├── waf-architecture-diagram.png
│   ├── subnet-layout.png
│   └── nsg-flow.png
├── nsg/
│   ├── dmz-nsg-rules.md
│   └── web-nsg-rules.md
├── backend/
│   ├── vm1-prime-setup.sh
│   ├── vm2-netflix-setup.sh
│   └── nginx-folder-structure.png
├── waf/
│   ├── backend-pool-config.md
│   ├── health-probe-config.md
│   ├── routing-rules.md
│   └── listener-config.md
└── README.md
```

---

## Skills Demonstrated

- Azure Virtual Networks
- Subnet isolation for DMZ and WEB tiers
- Network Security Group design
- Azure Application Gateway WAF v2
- URL path-based routing
- Linux Nginx backend configuration
- Azure Bastion secure administration
- Cloud security architecture

---

## Lab Outcome

This lab demonstrates a secure inbound web architecture that is aligned with production networking concepts and cloud security controls. It is ideal for showcasing practical Azure design, implementation, and troubleshooting skills in a portfolio or interview setting.

---

## Notes

- Application Gateway v2 requires careful NSG configuration on its subnet. 
- Path-based routing is best used when different URLs should be served by different backend pools.
- Backend VMs should remain private and reachable only through the WAF and administrative access paths. 
