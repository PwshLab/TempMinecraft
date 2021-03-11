function Invoke-Minecraft {
    [CmdletBinding()]
	Param(
		[Parameter(Mandatory = $false, Position = 0)]
		[String]
		$ServerURL = "https://launcher.mojang.com/v1/objects/1b557e7b033b583cd9f66746b7a9ab1ec1673ced/server.jar",
        [Parameter(Mandatory = $false, Position = 1)]
		[String]
		$ClientURL = "https://launcher.mojang.com/download/MinecraftInstaller.msi"
	)

    $tmp = $env:TEMP
    $MCPath = Join-Path -Path $tmp -ChildPath "/MC"
    $ServerPath = Join-Path -Path $MCPath -ChildPath "/Server"
    $ServerFilePath = Join-Path -Path $ServerPath -ChildPath "/server.jar"
    $ClientPath = Join-Path -Path $MCPath -ChildPath "/Client"
    $ClientInstallPath = Join-Path -Path $ClientPath -ChildPath "/MinecraftInstaller.msi"
    $ClientFilePath = Join-Path -Path $ClientPath -ChildPath "/Launcher.exe"

    New-Item -Path $tmp -Name MC -ItemType Directory
    New-Item -Path $MCPath -Name Server -ItemType Directory
    New-Item -Path $MCPath -Name Client -ItemType Directory

    $Downloader = New-Object Net.WebClient
    $ServerTask = $Downloader.DownloadFileTaskAsync($ServerURL, $ServerFilePath)
    $ClientTask = $Downloader.DownloadFileTaskAsync($ClientURL, $ClientInstallPath)

    Start-Process msiexec "/i $ClientFilePath /qn" -Wait
    Copy-Item -Path "C:\Program Files (x86)\Minecraft Launcher\MinecraftLauncher.exe" -Destination $ClientFilePath
    Remove-Item -Path "C:\Program Files (x86)\Minecraft Launcher"

    
}