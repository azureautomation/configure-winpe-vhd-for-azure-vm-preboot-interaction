Configure WinPE VHD for Azure VM Pre-boot Interaction
=====================================================

            

Have you ever wanted to boot to WinPE in Azure and select an MDT Task Sequence?  This script resource automates an automation framework to build and upload a custom VHD that allows for interacting with pre-boot environments in Azure.


Using the Microsoft Deployment Toolkit (MDT), Windows Assessment and Deployment Kit (WADK) for Windows 10, Microsoft Diagnostics and Recovery Toolset (DaRT) 10, and Azure & Hyper-V PowerShell modules, an administrator can successfully configure
 a custom VHD image that will boot to WinPE in an Azure VM to allow for MDT deployment options selection while still in the pre-boot environment.  A VM deployed in Azure using this customized VHD allows for remote interaction with the WinPE console using
 DaRT to select deployment options.


This script requires the Hyper-V and AzureRM modules, MDT snapin, and elevated permissions.  The script begins by mounting an MDT deployment share as a PowerShell drive and updating the MDT media contents folder.  Next, the VHD is created
 and configured with two partitions - one each for WinPE and the OS.  The script then copies the MDT Media contents into the WinPE partition and uploads it to an Azure storage service.


 


This is a single script resource used as part of a [Cloud OSD](https://blogs.technet.microsoft.com/heyscriptingguy/2017/02/09/cloud-operating-system-deployment-winpe-in-azure/) process.

 

        
    
TechNet gallery is retiring! This script was migrated from TechNet script center to GitHub by Microsoft Azure Automation product group. All the Script Center fields like Rating, RatingCount and DownloadCount have been carried over to Github as-is for the migrated scripts only. Note : The Script Center fields will not be applicable for the new repositories created in Github & hence those fields will not show up for new Github repositories.
