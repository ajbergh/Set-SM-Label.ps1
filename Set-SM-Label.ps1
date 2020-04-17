<# 
   .SYNOPSIS
   Sets the Snapmirror Label on all "Veeam" snapshots to "Veeam" in a specified SVM 
   .DESCRIPTION
   This script finds all snapshots with the keyword "Veeam" in them and sets all of their SnapMirror-Label to "Veeam"
   .PARAMETER PrimaryCluster
   With this parameter you specify the source NetApp ONTAP cluster.
   .PARAMETER PrimarySVM
   With this parameter you specify the source NetApp SVM, where the snapshots arelocated.
   .PARAMETER ClusterUser
   This parameter is the login username for the ONTAP Cluster
   .PARAMETER ClusterPass
   This parameter is a filename of a saved credentials file for source cluster.
   .PARAMETER PassKey
   This parameter is the AES.key for password decryption
   .PARAMETER LogFile
   You can set your own path for log file from this script. Default filename is "C:\scripts\SM-label.log"

   .INPUTS
   None. You cannot pipe any objects to this script.

   .Example
   .\Set-SM-Label.ps1 -PrimaryCluster 192.168.1.220 -PrimarySVM "vmware_svm" -ClusterUser admin -ClusterPass "C:\scripts\password.txt" -PassKey "c:\scripts\AES.key"


   .Notes 
   Version:        1.0
   Author:         Adam Bergh (adam.bergh@veeam.com)
   Author:         Marco Horstmann (marco.horstmann@veeam.com)
 #>

 [CmdletBinding(DefaultParameterSetName="__AllParameterSets")]
Param(

   [Parameter(Mandatory=$True)]
   [string]$PrimaryCluster,

   [Parameter(Mandatory=$True)]
   [string]$PrimarySVM,

   [Parameter(Mandatory=$True)]
   [string]$ClusterUser, 
   
   [Parameter(Mandatory=$True)]
   [string]$ClusterPass,   

   [Parameter(Mandatory=$True)]
   [string]$PassKey,   

   [Parameter(Mandatory=$False)]
   [string]$LogFile="C:\scripts\SM-Label.log"

)


PROCESS {



 # This function is used to log status to console and also the given logfilename.
  # Usage: Write-Log -Status [Info, Status, Warning, Error] -Info "This is the text which will be logged"
  function Write-Log($Info, $Status)
  {
    switch($Status)
    {
        Info    {Write-Host $Info -ForegroundColor Green  ; $Info | Out-File -FilePath $LogFile -Append}
        Status  {Write-Host $Info -ForegroundColor Yellow ; $Info | Out-File -FilePath $LogFile -Append}
        Warning {Write-Host $Info -ForegroundColor Yellow ; $Info | Out-File -FilePath $LogFile -Append}
        Error   {Write-Host $Info -ForegroundColor Red -BackgroundColor White; $Info | Out-File -FilePath $LogFile -Append}
        default {Write-Host $Info -ForegroundColor white $Info | Out-File -FilePath $LogFile -Append}
    }
  } #end function 








# This function will load the NetApp Powershell Module.
  function Load-NetAppModule
  {
    Write-Log -Info "Trying to load NetApp Powershell module" -Status Info
    try {
        Import-Module DataONTAP
        Write-Log -Info "Loaded NetApp Powershell module sucessfully" -Status Info
    } catch  {
        Write-Log -Info "$_" -Status Error
        Write-Log -Info "Loading NetApp Powershell module failed" -Status Error
        exit 99
    }
  }









# This function is used to connect to a specfix NetApp SVM
  function Connect-NetAppSystem($clusterName, $svmName, $username, $password, $keyfile)
  {
    Write-Log -Info "Trying to connect to SVM $svmName on cluster $clusterName " -Status Info
    #Write-Log -Info $password -Status Info

    
    
    try {
        $User = "admin"
        #$user = $username
        $PasswordFile = $password
        #$KeyFile = "c:\scripts\AES.key"
        $key = Get-Content $keyfile
        $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, (Get-Content $PasswordFile | ConvertTo-SecureString -Key $key)
        
        
        
        $ControllerSession = Connect-NcController -name $clusterName -Vserver $svmName -Credential $Credential -HTTPS -ErrorAction Stop
        Write-Log -Info "Connection established to $svmName on cluster $clusterName" -Status Info
    } catch {
        # Error handling if connection fails  
        Write-Log -Info "$_" -Status Error
        exit 1
    }
    return $controllersession
  }





#
  # Main Code starts
  #
  # Load the NetApp Modules
  Load-NetAppModule
  # Connect to the source NetApp system
  $PrimaryClusterSession = Connect-NetAppSystem -clusterName $PrimaryCluster -svmName $PrimarySVM -username $ClusterUser -password $ClusterPass -keyfile $PassKey
  
  Get-NcSnapshot -SnapName *Veeam* | Set-NcSnapshot -SnapmirrorLabel Veeam
  
} # END Process
