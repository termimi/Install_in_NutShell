# Parameter help description
param(
    [Parameter(Mandatory=$false, HelpMessage="Put `$false if you do not want to install MS teams & VSCode")]
    [bool]$CompleteInstall = $true,
    [Parameter(Mandatory=$false, HelpMessage="Indicate which user to add to the docker group")]
    [string]$UserToAdd,
    [Parameter(Mandatory=$false, HelpMessage="Indicate where to install")]
    [string]$InstallPath = $(Get-Location).Path
)
function CheckPsVersion {
    return $PSVersionTable.PSVersion
}
function AskUserToAdd {
    $userToAdd = Read-Host "Please enter the user to add to the docker group"
    return $userToAdd
}

function InstallTeams {
    $downloadLink = "https://go.microsoft.com/fwlink/?linkid=2281613&clcid=0x40c&culture=fr-fr&country=fr"
    try {
        # Téléchargement de l'installer
        Write-Host "Downloading Microsoft Teams installer..."
        Invoke-WebRequest -Uri $downloadLink -OutFile $InstallPath -UseBasicParsing
        Write-Host "Teams installer downloaded to: $InstallPath"

        Write-Host "Installing Microsoft Teams..."
        Start-Process -FilePath "$InstallPath\MSTeamsSetup.exe"
        Write-Host "Microsoft Teams has been installed successfully"
        
        # todo: supprimé le msTeamssetup une fois installé
        #Remove-Item -Path "$InstallPath\MSTeamsSetup.exe" -Force
    }
    catch {
        Write-Error ("An error has been encountered: " + $_.Exception.Message)
    }
}
function InstallVsCode {
    $downloadLink = "https://vscode.download.prss.microsoft.com/dbazure/download/stable/f1a4fb101478ce6ec82fe9627c43efbf9e98c813/VSCodeUserSetup-x64-1.95.3.exe"

    try {
        Write-Host "Downloading Visual Studio Code installer..."
        Invoke-WebRequest -Uri $downloadLink -OutFile $InstallPath -UseBasicParsing
        Write-Host "Visual Studio Code installer downloaded to: $InstallPath"
        Write-Host "Installing VSCode"
        #TODO: Faire en sorte de ne pas utiliser le nom de l'installer en harde code mais de le récupérer dans un tableau
        Start-Process -FilePath "$InstallPath\VSCodeUserSetup-x64-1.95.3.exe"
        Write-Host "VSCode has been installed successfully"
    }
    catch {
        Write-Error ("An error has been encountered: " + $_.Exception.Message)
    }
}
function InstallDocker {
    $installerName = "Docker Desktop Installer.exe"
    $installerPath = Join-Path $InstallPath $installerName
    if(Test-Path $installerPath){
        Write-Host "Docker Desktop installer already exists at: $installerPath"
    }
    else{
        $downloadLink = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe?utm_source=docker&utm_medium=webreferral&utm_campaign=dd-smartbutton&utm_location=module&_gl=1*1mq0u4u*_gcl_au*NjY4NTY5NTgwLjE3MzMzODI3NDg.*_ga*MTgyMDcxMzA3MC4xNzMzMzgyNzQ4*_ga_XJWPQMJYHQ*MTczMzM4Mjc0OC4xLjEuMTczMzM4Mjc3NS4zMy4wLjA."

        try {
            Write-Host "Downloading docker desktop installer..."
            Invoke-WebRequest -Uri $downloadLink -OutFile $InstallPath -UseBasicParsing
            Write-Host "docker desktop installer downloaded to: $InstallPath"
            Write-Host "Installing docker desktop"
    
            #TODO: Faire en sorte de ne pas utiliser le nom de l'installer en harde code mais de le récupérer dans un tableau
            Start-Process -FilePath "$InstallPath\Docker Desktop Installer.exe"
            Write-Host "Docker Desktop has been installed successfully"
        }
        catch {
            Write-Error ("An error has been encountered: " + $_.Exception.Message)
        }
    }
}
function CheckForDocker {
    $isDockergroupHere = Get-LocalGroup | Where-Object {$_.Name -like "*docker*"} 
    if($null -ne $isDockergroupHere){
        return $true
    }
    else{
        return $false
    }
}
function AddUserToGroup {
    param (
        $UserToAddtoDocker
    )
    try {
        $result = (net localgroup docker-users $UserToAddtoDocker /ADD > $result | Out-String).Trim()
    }
    catch {
        Write-Error ("An error has been encountered: " + $_.Exception.Message)
    }
}
$PowershellVersion = CheckPsVersion
$currentuser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$principalUser = New-Object System.Security.Principal.WindowsPrincipal($currentuser)

if (($PowershellVersion.Major -lt 5) -or ($PowershellVersion.Major -lt 7) ) {
    Write-Error "Your version of powershell is to old to execute this script"
}
if($CompleteInstall){
    InstallTeams
    InstallVsCode
}
if ($principalUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){
    try {
        $isDockerHere = CheckForDocker
        if($isDockerHere){
            if($null -eq $UserToAdd){
                $userToAdd = AskUserToAdd
            }
            Write-Host "Adding user to docker group"
            AddUserToGroup -UserToAddtoDocker $UserToAdd
            Write-Host "Your user has been added to the docker-users group"
        }
        else {
            InstallDocker
        }
    }
    catch {
        Write-Error ("An error has been encountered: " + $_.Exception.Message)
    }
}
else {
    Write-Host "Script not used with administrator rights - docker cannot be installed or used"
}
