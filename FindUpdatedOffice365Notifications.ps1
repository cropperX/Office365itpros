# Find Updated Service Notifications - FindUpdatedOffice365Notifications.ps1

$AppId = "d716b32c-0edb-48be-9385-30a9cfd96155"
$TenantId = "b662313f-14fc-43a2-9a7a-d2e27f4f3478"
$AppSecret = 's_rkvIn1oZ1cNceUBvJ2or1lrrIsb*:='

$body = @{grant_type="client_credentials";resource="https://manage.office.com";client_id=$AppId;client_secret=$AppSecret }
$oauth = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$($tenantId)/oauth2/token?api-version=1.0" -Body $body
$token = @{'Authorization' = "$($oauth.token_type) $($oauth.access_token)" }

$StartTime = (Get-Date).AddDays(-60)
$StartTime = (Get-Date $StartTime -format u)
$EndTime = Get-Date
$EndTime = (Get-Date $EndTime -format u)


$Uri = "https://manage.office.com/api/v1.0/b662313f-14fc-43a2-9a7a-d2e27f4f3478/ServiceComms/Messages?`$filter=MessageType eq 'MessageCenter' & starttime $StartTime &endtime $EndTime `$top=999"
$Messages = Invoke-RestMethod -Uri $uri -Headers $token -Method Get

$Report = [System.Collections.Generic.List[Object]]::new()
ForEach ($M in $Messages.Value) {

If ($M.LastUpdateTime -eq $Null) {
   $LastUpdate = "None" }
   Else { $LastUpdate = et-Date ($M.LastUpdateTime) -format g }

# Set flags to indicate affected workloads
$Dynamics = $False; $Exchange = $False; $EOP = $False; $Forms = $False; $Intune = $False; $Lync = $False; $ATP = $False; $Flow = $False; $Teams = $False
$PowerApps = $False; $OfficeOnline = $False; $OneDrive = $False; $Platform = $False; $Client = $False; $Planner = $False; $SharePoint = $False
$Stream = $False; $Yammer = $False; $Office365 = $False
Foreach ($Wl in $M.AffectedWorkloadnames) {
  Switch ($Wl) {
    "DynamicsCRM"             { $Dynamics = $True }
    "Exchange"                { $Exchange = $True }
    "Fope"                    { $EOP = $True }
    "Forms"                   { $Forms = $True }
    "Intune"                  { $Intune = $True }
    "Lync"                    { $Lync = $True }
    "MDATP"                   { $ATP = $True }
    "MicrosoftFlow"           { $Flow = $True }
    "MicrosoftFlowM365"       { $Flow = $True}
    "MicrosoftTeams"          { $Teams = $True }
    "MobileDeviceManagement"  { $Intune = $True }
    "PowerApps"               { $PowerApps = $True }
    "PowerAppsM365"           { $PowerApps = $True }
    "OfficeOnline"            { $OfficeOnline = $True }
    "OneDriveForBusiness"     { $OneDrive = $True }
    "OrgLiveId"               { $Platform = $True }
    "OSDPPlatform"            { $Platform = $True }
    "O365Client"              { $Client = $True }
    "Planner"                 { $Planner = $True }
    "SharePoint"              { $SharePoint = $True }  
    "Stream"                  { $Stream = $True }  
    "Yammer"                  { $Yammer = $True }
     default                  { $Office365 = $True }
  } #End Switch
} #End Foreach

# For notifications issued as updates, grab the update date from the text of the notification; otherwise just get the first 200 characters of the text
If ($M.Messages.MessageText -Like "Updated*") { 
     $UpdateText = $M.Messages.MessageText.SubString(0,200)
     $UpdateDate = $UpdateText.Substring(0,$Updatetext.IndexOf(":")) 
     $UpdateDate = $UpdateDate.SubString(8,($UpdateDate.length-8))
     [datetime]$StartPeriod = $M.StartTime
     [datetime]$EndPeriod   = $UpdateDate
     $DaysUpdate = (New-TimeSpan -Start $StartPeriod -End $EndPeriod).Days  }
  Else {
     $UpdateText = $M.Messages.MessageText.SubString(3,203) 
     $UpdateDate = $Null 
     $DaysUpdate = "N/A" }
    

[DateTime]$MStartDate = Get-Date($M.StartTime)
If ($MStartDate -gt $StartDate) {
    $ReportLine = [PSCustomObject]@{  
     Id           = $M.Id
     Title        = $M.Title
     Category     = $M.Category
     ActionType   = $M.ActionType
     Text         = $UpdateText
     Updated      = $UpdateDate
     DaysUpdate   = $DaysUpdate
     Link         = $M.ExternalLink
     HelpLink     = $M.HelpLink
     Workloads    = $M.AffectedWorkloadDisplayNames
     StartDate    = Get-Date ($M.StartTime) -format g
     LastUpdate   = $LastUpdate
     EndDate      = Get-Date($M.Endtime) -format g
     Dynamics     = $Dynamics
     Exchange     = $Exchange
     EOP          = $EOP
     Forms        = $Forms
     Intune       = $Intune
     Lync         = $Lync
     ATP          = $ATP
     Flow         = $Flow
     Teams        = $Teams
     PowerApps    = $PowerApps
     OfficeOnline = $OfficeOnline
     OneDrive     = $OneDrive
     Platform     = $Platform
     Client       = $Client
     Planner      = $Planner
     SharePoint   = $SharePoint
     Stream       = $Stream
     Yammer       = $Yammer
     Office365    = $Office365  
    }
  $Report.Add($ReportLine) }

} # End ForEach

[array]$Updates = $Report | ?{$_.Title -Like "*(Updated)*"}

