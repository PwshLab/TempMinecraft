function Invoke-Minecraft {
    [CmdletBinding()]
	Param(
		[Parameter(Mandatory = $false, Position = 0)]
		[String]
		$ServerURL = "https://launcher.mojang.com/v1/objects/1b557e7b033b583cd9f66746b7a9ab1ec1673ced/server.jar",
        [Parameter(Mandatory = $false, Position = 1)]
		[String]
		$ClientURL = "https://launcher.mojang.com/download/MinecraftInstaller.msi",
        [Parameter(Mandatory = $false, Position = 2)]
		[String]
		$ConfURL = "https://raw.github.com/mo-tec/Invoke-Minecraft/main/Conf.zip",
        [Parameter(Mandatory = $false, Position = 3)]
		[Switch]
        $Clean
	)

    $tmp = $env:TEMP
    $MCPath = Join-Path -Path $tmp -ChildPath "/MC"
    $ServerPath = Join-Path -Path $MCPath -ChildPath "/Server"
    $ServerFilePath = Join-Path -Path $ServerPath -ChildPath "/server.jar"
    $ClientPath = Join-Path -Path $MCPath -ChildPath "/Client"
    $ClientInstallPath = Join-Path -Path $ClientPath -ChildPath "/MinecraftInstaller.msi"
    $ClientFilePath = Join-Path -Path $ClientPath -ChildPath "/bin/Launcher.exe"
    $ConfTmpPath = Join-Path -Path $ClientPath -ChildPath "/Conf.zip"
    $ConfFilePath = Join-Path -Path $ClientPath -ChildPath "/data/.minecraft/Conf.zip"

    if ($Clean) { Remove-Item $MCPath -Recurse -Force -Confirm -ErrorAction SilentlyContinue }

    New-Item -Path $tmp -Name MC -ItemType Directory
    New-Item -Path $MCPath -Name Server -ItemType Directory
    New-Item -Path $MCPath -Name Client -ItemType Directory

    $Downloader = New-Object Net.WebClient
    $ServerTask = $Downloader.DownloadFile($ServerURL, $ServerFilePath)
    $ClientTask = $Downloader.DownloadFile($ClientURL, $ClientInstallPath)
    $ConfTask = $Downloader.DownloadFile($ConfURL, $ConfTmpPath)

    New-Item -Path $ServerPath -Name "eula.txt" -ItemType File -Value "eula=true"
    New-Item -Path $ServerPath -Name "Server.bat" -ItemType File -Value "java -Xmx1024M -Xms1024M -jar server.jar nogui"
    New-Item -Path $ClientPath -Name "bin" -ItemType Directory
    New-Item -Path $ClientPath -Name "data" -ItemType Directory
    New-Item -Path $ClientPath -Name "Client.bat" -ItemType File -Value '"%cd%\bin\Launcher.exe" --workDir "%cd%\data\.minecraft"'
    New-Item -Path (Join-Path -Path $ClientPath -ChildPath "/data") -Name ".minecraft" -ItemType Directory

    Start-Process msiexec "/i $ClientFilePath /qn" -Wait
    Copy-Item -Path "C:\Program Files (x86)\Minecraft Launcher\MinecraftLauncher.exe" -Destination $ClientFilePath
    Remove-Item -Path "C:\Program Files (x86)\Minecraft Launcher" -Recurse -Force -Confirm -ErrorAction SilentlyContinue
    Copy-Item -Path $ConfTmpPath -Destination $ConfFilePath
    Expand-Archive -Path $ConfFilePath -Confirm -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $ConfFilePath -Force -Confirm -ErrorAction SilentlyContinue

    Start-Process (Join-Path -Path $ServerPath -ChildPath "Server.bat") -NoNewWindow
    Start-Process (Join-Path -Path $ClientPath -ChildPath "Client.bat") -NoNewWindow
}