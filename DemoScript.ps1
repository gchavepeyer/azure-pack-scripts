### @Author Geoffrey Chavepeyer
###
### How-to start with Azure Powershel CLI.
###

# Make sure you have imported the Azure Module. You can install those via Web Platform Installer 
# Available here : https://www.microsoft.com/web/downloads/platform.aspx
Import-Module -Name "Azure"

# Add your Proximus Azure pack 
# First, download your .publishsettings file by surfing to https://portal.wap.proximus.cloud/publishsettings
Add-WAPackEnvironment -Name "PROXICLOUD" -PublishSettingsFileUrl "https://portal.wap.proximus.cloud/publishsettings" -ServiceEndpoint "https://api.wap.proximus.cloud"

# Import your certificate File in your local environment
$publishfilepath = 'C:\Users\id092096\Desktop\PROXICLOUD FUT-5Nine-PROXICLOUD_Testing-6-20-2016-credentials.publishsettings'
Import-WAPackPublishSettingsFile $publishfilepath -Environment 'PROXICLOUD'

# Don't forget to select the correct subscription
$subscription = Get-WAPackSubscription -SubscriptionName "PROXICLOUD_Testing"
Select-WAPackSubscription -SubscriptionName $subscription.SubscriptionName 

# Create a Credential Object. This will be used later when inserting the root password in our VM's
$secpasswd = ConvertTo-SecureString “MyNotSoSecurePassword123!” -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential (“root”, $secpasswd)

# Get the template object
$CentosSmallTemplate = Get-WAPackVMTemplate -Name "CentOS 7 - Small"
$WindowsSmallTemplate = Get-WAPackVMTemplate -Name "WS 2012 R2 Datacenter GUI - Small"

# Before being able to create a VM, we need to be able to attach it to a network.

# Let's start by acquiring the LogicalNetwork. Currently there is only one provider by Proximus : "LN_PA_Network_IPv4" 
$logicalNet = Get-WAPackLogicalNetwork -Name "LN_PA_Network_IPv4"

# Now let's create the actual Network on top of that virtualized Network
$network = New-WAPackVNet -Name "API-Net" -LogicalNetwork $logicalNet
$network = Get-WAPackVNet -Name "API-Net"

# Now that a network exist, we need to assign a subnet to this VMNetwork
$vmsubnet = New-WAPackVMSubnet -VNet $network -Subnet "192.168.1.0/24" -Name "Subnet"
$vmsubnet = Get-WAPackVMSubnet -Name "Subnet" -VNet $network

# As we wan't that the VM automatically get a Ip assigned, We also need to define a static IP pool for that subnet
$IpPool = New-WAPackStaticIPAddressPool -IPAddressRangeEnd 192.168.1.250 -IPAddressRangeStart 192.168.1.2 -Name Subnet -VMSubnet $vmsubnet
$IpPool = Get-WAPackStaticIPAddressPool -VMSubnet $vmsubnet

# Now let's create some actual virtual machines
$NumberOfVM = 2
$VMName = "API-VM"

$virtualMachines = @{}
for($i=1; $i -le $NumberOfVM; $i++){
    Write-Output $VMName$i
    $vm = New-WAPackVM -Name $VMName$i -Template $CentosSmallTemplate -VNet $network -VMCredential $mycreds -Linux -Verbose
    $virtualMachines.Add("$VMName$i", $vm)
}

foreach ($vm in $virtualMachines.Keys) {
    Write-Output $vm
    Start-WAPackVM -VM $virtualMachines.Get_Item($vm)
}
Get-WAPackVM -Name “APIVM” | Start-WAPackVM
