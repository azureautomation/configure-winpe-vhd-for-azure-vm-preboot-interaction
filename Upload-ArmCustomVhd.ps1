#requires -modules Hyper-V

<#
    .SYNOPSIS
        Uploads a custom VHD containing WinPE and OSDisk partitions to a blob service in Azure.

    .PARAMETER RemoveVHD
        A switch that will delete an existing VHD.
    
    .PARAMETER LocalVhdPath
        Path to the VHD on the local workstation.

    .PARAMETER SubscriptionId
        Azure Subscription ID to connect.

    .PARAMETER StorageAccountName
        Name of the Azure storage account to connect.

    .PARAMETER VhdPath
        Desired path of the VHD on the Azure blob service.

    .PARAMETER VhdSize
        Size of the fixed VHD.

    .PARAMETER WinPePartitionSize
        Size of the WinPE partition on the VHD.

    .PARAMETER WinPeFsLabel
        Drive label for the WinPE partition.

    .PARAMETER MdtDrive
        Label of the MDT drive to mount.  Requires the MDT snapin.

    .PARAMETER DeploymentShare
        Path to the local MDT Deployment Share

    .PARAMETER MediaName
        Name of the MDT Media that contains the appropriate Deployment Share contents.

    .EXAMPLE
        .\Upload-ArmCustomVhd.ps1 -RemoveVHD -LocalVhdPath "C:\VHDs\winpetesting.vhd" -SubscriptionId "65213276-e312-4beb-9ee5-aa0b5196e748" `
        -StorageAccountName "imgpoc9159" -VhdPath "vhds/winpe-final.vhd" -VhdSize 21GB -WinPePartitionSize 7GB -WinPeFsLabel "winPE" `
        -MdtDrive "DS001" -DeploymentShare "C:\DeploymentShare" -MediaName "Media001"
#>
param(
    [switch]
    $RemoveVHD = $true,

    $LocalVhdPath,

    $SubscriptionId,

    $StorageAccountName,

    $VhdPath,

    $VhdSize,

    $WinPePartitionSize,

    $MdtDrive,

    $WinPeFsLabel,

    $DeploymentShare,

    $MediaName
)

Import-Module -Name Hyper-V
Add-PSSnapin -Name Microsoft.BDD.PSSnapIn
#Check for MDT Drive and mount if not
if (!(Test-Path "$($MdtDrive):"))
{
    New-PSDrive -Name $MdtDrive -PSProvider MDTProvider -Root $DeploymentShare
}

#region mount VHD and copy MDT media to WinPE partition
#region remove VHD if exists then create VHD
if ($RemoveVHD)
{
    if (Test-Path $LocalVhdPath)
    {
        Dismount-DiskImage $LocalVhdPath -ErrorAction Ignore
        Remove-Item $LocalVhdPath -Confirm
    }

    New-VHD -Path $LocalVhdPath -SizeBytes $VhdSize -Fixed
    
    Mount-DiskImage -ImagePath $LocalVhdPath

    $mountedDisk = Get-DiskImage -ImagePath $LocalVhdPath

    Initialize-Disk -Number $mountedDisk.Number -PartitionStyle MBR

    New-Partition -DiskNumber $mountedDisk.Number -Size $WinPePartitionSize -AssignDriveLetter -IsActive | Format-Volume -FileSystem NTFS -NewFileSystemLabel $WinPeFsLabel -confirm:$false

    New-Partition -DiskNumber $mountedDisk.Number -UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemLabel "OSDisk" -confirm:$false
}
#endregion

#region Mount and update VHD with MDT Media
Write-Output "Updating MDT Media"
$mdtMediaPath = "$($MdtDrive):\Media\$MediaName"
Update-MDTMedia -Path $mdtMediaPath

Mount-DiskImage $LocalVhdPath -ErrorAction Ignore
$mountedDisk = Get-DiskImage -ImagePath $LocalVhdPath
$winPePartition = Get-Volume -FileSystemLabel $WinPeFsLabel
$driveLetter = $winPePartition.DriveLetter
$tsMediaContentPath = "C:\Media\Content"
Write-Output "Copying updated content to VHD"
Copy-Item $tsMediaContentPath\* "$($driveLetter):\" -Recurse -Force
Dismount-DiskImage $LocalVhdPath
#endregion

#region Create a copy to confirm successful deployment locally
Write-Output "Copying VHD"
Copy-Item $LocalVhdPath $LocalVhdPath.Replace("winpetesting.vhd","winpetestingcopy.vhd")
#endregion

if (!($login))
{
    $login = Login-AzureRmAccount -SubscriptionId $SubscriptionId
    $storageAccount = Get-AzureRmStorageAccount | Where-Object StorageAccountName -EQ $StorageAccountName
    $resourceGroupName = $storageAccount.ResourceGroupName
}

Add-AzureRmVhd -Destination "https://$StorageAccountName.blob.core.windows.net/$VhdPath" -LocalFilePath $LocalVhdPath -ResourceGroupName $resourceGroupName -OverWrite
