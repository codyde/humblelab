## Humblelab Core ESX 
## NSX Build Script 
## By Cody De Arkland
## CodyDe@thehumblelab.com 

## Description - Used to build the "Core" NSX environments ESG's and DLR's. Completes all uplinks to physical infrastructure, enables OSPF, sets areas, and creates the "automation" network as an interface off of the ESG


#Define Variables and Stage 

$tz = get-nsxtransportzone -name Hl-Core-TZ
New-NsxLogicalSwitch -TransportZone $tz -Name 'Automation-10.20.254.0/24'
$autopg = Get-nsxlogicalswitch -name 'Automation-10.20.254.0/24'
$automationInterface = New-NSXEdgeInterfaceSpec -index 2 -name 'Automation-10.20.254.0/24' -type 'Internal' -connectedto $autopg -PrimaryAddress '10.20.254.1' -subnetprefixlength 24 -mtu 1500
$uplinkpg = Get-VirtualPortGroup -Name 'Core_NSX_Uplink_650'
$datastore = Get-DataStore -name 'SynologyStore'
$uplinkinterface = New-NSXEdgeInterfaceSpec -index 0 -name 'ESG_Physical_Uplink_VLAN650' -type 'uplink' -connectedto $uplinkpg -PrimaryAddress '172.26.11.2' -subnetprefixlength 30 -mtu 1500
$cluster = Get-Cluster -name 'HL-Core'

# Create the NSX Edge 

new-nsxedge -name hlcoreesg01 -cluster $cluster -datastore $datastore -username 'admin' -password 'EnterNewEdgePassword' -fwenabled:$False -interface $uplinkinterface,$automationInterface 

# Disable Edge Firewall
# ** Depreciated **
# Left in to Remember Syntax 


#$edge = get-nsxedge -name 'hlcoreesg01'
#$edge.features.firewall.enabled = "false"
#$edge | set-nsxedge

# Enable OSPF

get-nsxedge -name hlcoreesg01 | get-nsxedgerouting | set-nsxedgerouting -enableospf -routerid '172.26.11.2' -confirm:$false 

Get-NsxEdge | Get-NsxEdgeRouting | Set-NsxEdgeRouting -DefaultGatewayVnic 0 -DefaultGatewayAddress 172.26.11.1 -DefaultGatewayMTU 1500 -DefaultGatewayDescription 'Uplink Default Gateway' -Confirm:$false 

# Kill Area 51

Get-NsxEdge -Name hlcoreesg01 | Get-NsxEdgeRouting | Get-NsxEdgeOspfArea -AreaId 51 | Remove-NsxEdgeOspfArea -Confirm:$false

# Create New Area 

Get-NsxEdge -Name hlcoreesg01 | Get-NsxEdgeRouting | New-NsxEdgeOspfArea -areaid 22 -Confirm:$false

# Add Area 

Get-NsxEdge -Name hlcoreesg01 | Get-NsxEdgeRouting | New-NsxEdgeOspfInterface -Vnic 0 -AreaId 22 -Confirm:$false

# Enable Route Redistribution 

$edgerouting = get-nsxedge -name hlcoreesg01 | Get-NsxEdgeRouting
New-NsxEdgeRedistributionRule -EdgeRouting $edgerouting -FromConnected -Learner ospf -confirm:$false

get-nsxedge -name hlcoreesg01 | Get-NsxEdgeRouting | Set-NsxEdgeRouting -EnableOspfRouteRedistribution -confirm:$false

