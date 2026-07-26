# Azure ExpressRoute Lab

A real Azure ExpressRoute lab that demonstrates provider-based private connectivity between on-premises and Azure using private peering, an ExpressRoute virtual network gateway, and a workload VNet.

This project is designed for cloud and network engineers who want a practical, production-style ExpressRoute setup for portfolio and interview use.

---

## Lab Scope

This lab covers:

- Creating an ExpressRoute circuit.
- Configuring private peering.
- Deploying an ExpressRoute virtual network gateway.
- Linking a VNet to the ExpressRoute circuit.
- Validating private connectivity from on-premises to Azure.

Azure documentation confirms that private peering requires a provisioned circuit and that a virtual network gateway is created after peering is configured.

---

## Prerequisites

Before starting, make sure you have:

- An Azure subscription with Owner or Contributor permissions.
- A connectivity provider that supports ExpressRoute, or ExpressRoute Direct.
- Access to an on-premises router capable of BGP configuration, or a provider that handles routing for you.
- A supported Azure region for ExpressRoute resources.

---

## Architecture Overview

```text
On-premises network
        |
        | ExpressRoute private peering
        v
ExpressRoute Circuit
        |
        v
ExpressRoute Virtual Network Gateway
        |
        v
VNet: vnet-hub-er (10.20.0.0/16)
        |
        v
Workload subnet: 10.20.1.0/24
```

---

## Resource Group

### Create the resource group

- **Name:** `rg-expressroute-lab`
- **Region:** choose an ExpressRoute-supported region, such as East US

---

## Virtual Network

### Create the VNet

- **Name:** `vnet-hub-er`
- **Address space:** `10.20.0.0/16`

### Subnet

- **Name:** `Workload-Subnet`
- **Address range:** `10.20.1.0/24`

---

## Gateway Subnet

ExpressRoute virtual network gateways require a dedicated gateway subnet, and Microsoft’s guidance for ExpressRoute virtual network gateways should be followed when sizing and configuring it. 

### Create the gateway subnet

- **Name:** `GatewaySubnet`
- **Address range:** `10.20.0.0/27`

> Use `/27` or larger for the gateway subnet.

Leave the NSG and route table as **None**.

---

## ExpressRoute Circuit

### Create the circuit

- **Name:** `er-circuit-lab`
- **Resource group:** `rg-expressroute-lab`
- **Port type:** Provider
- **Provider:** your chosen ExpressRoute provider
- **Peering location:** nearest supported location
- **Bandwidth:** choose based on your budget
- **SKU tier:** Standard
- **SKU family:** MeteredData or UnlimitedData

#### Microsoft documents that the circuit must be provisioned by the connectivity provider before private peering and gateway connection can be completed.

### Service key

After the circuit is created, copy the **Service key** from the overview blade and send it to your connectivity provider.

---

## Private Peering

### Configure private peering

- **Peering type:** Azure private
- **Primary subnet:** `192.168.10.0/30`
- **Secondary subnet:** `192.168.10.4/30`
- **VLAN ID:** `200`
- **Peer ASN:** your on-prem ASN, for example `65010`

Azure’s private peering guidance requires a provisioned circuit, matching VLAN and BGP parameters, and on-premises route advertisement over BGP. 

### Provider-side configuration

Your provider or on-prem router must match:

- VLAN ID
- Primary and secondary peering subnets
- BGP ASN
- Route advertisement for on-prem prefixes

---

## ExpressRoute Virtual Network Gateway

### Create the gateway

- **Name:** `gw-er-hub`
- **Gateway type:** `ExpressRoute`
- **SKU:** `ErGw2AZ` or `ErGw3AZ`
- **Virtual network:** `vnet-hub-er`

Microsoft’s ExpressRoute gateway documentation covers supported SKUs and gateway behavior for private connectivity. 

### Provisioning

Wait until the gateway provisioning state shows **Succeeded**.

---

## VNet Connection

### Link the VNet to the circuit

- **Connection name:** `er-hub-connection`
- **Virtual network gateway:** `gw-er-hub`

Once the connection is created, wait for the status to show **Connected** or **Succeeded**.

Azure’s ExpressRoute private peering workflow ends with creating the gateway and linking it to the circuit. 

---

## Test VM

### Deploy a test VM

- **Name:** `vm-er-test`
- **Resource group:** `rg-expressroute-lab`
- **Virtual network:** `vnet-hub-er`
- **Subnet:** `Workload-Subnet`

Use an internal-only VM if you want a pure ExpressRoute validation test.

---

## Validation

### From on-premises

Test reachability to the VM private IP:

- Ping, RDP, or SSH to `10.20.1.x`

### In Azure

Check effective routes on the VM NIC and confirm that on-prem prefixes are learned through ExpressRoute.

Microsoft’s ExpressRoute documentation notes that route exchange occurs through private peering and the linked gateway. 

---

## Additional VNets

Standard ExpressRoute supports a limited number of linked VNets, while Premium supports more and cross-region connectivity. Microsoft documents gateway and circuit behavior by SKU and connectivity scope. 

For each additional VNet:

- Create the VNet.
- Create an ExpressRoute gateway.
- Add a new connection to the same circuit.

---

## What This Lab Demonstrates

- Real ExpressRoute provider-based connectivity
- Private peering configuration
- ExpressRoute gateway deployment
- Private routing between on-premises and Azure
- Workload access over private connectivity only

---

## Repository Structure

```text
azure-expressroute-lab/
├── architecture/
├── networking/
├── expressroute/
├── vm/
└── README.md
```

---

## Notes

- This is a real ExpressRoute lab, not a VPN simulation.
- Provider provisioning must complete before peering and routing can succeed.
- Route advertisement and BGP settings must match on both sides.
- Use a supported Azure region and verify provider availability before deployment.

---

## License

For educational and portfolio use.
