function Start-Minecraft {
    [CmdletBinding()]
	Param(
		[Parameter(Mandatory = $false, Position = 0)]
		[String]
		$ServerURL = "https://launcher.mojang.com/v1/objects/c8f83c5655308435b3dcf03c06d9fe8740a77469/server.jar",
        [Parameter(Mandatory = $false, Position = 1)]
		[String]
		$ClientURL = "https://launcher.mojang.com/download/Minecraft.exe",
        [Parameter(Mandatory = $false, Position = 2)]
		[String]
		$ConfURL = "https://github.com/PwshLab/Invoke-Minecraft/blob/288287cdb038f147742836bfb56ca4c1ab9eb441/Conf.zip",
        [Parameter(Mandatory = $false, Position = 3)]
		[String]
		$JDKURL = "https://download.java.net/java/GA/jdk17.0.2/dfd4a8d0985749f896bed50d7138ee7f/8/GPL/openjdk-17.0.2_windows-x64_bin.zip",
        [Parameter(Mandatory = $false, Position = 4)]
		[Switch]
        $Clean,
        [Parameter(Mandatory = $false)]
		[String]
        $ProxyHost = "192.240.46.126",
        [Parameter(Mandatory = $false)]
		[String]
        $ProxyPort = 80,
        [Parameter(Mandatory = $false)]
		[Switch]
        $UseProxy
    )

    $tmp = $env:TEMP
    $MCPath = Join-Path -Path $tmp -ChildPath "/MC"
    $ServerPath = Join-Path -Path $MCPath -ChildPath "/Server"
    $ServerFilePath = Join-Path -Path $ServerPath -ChildPath "/server.jar"
    $ClientPath = Join-Path -Path $MCPath -ChildPath "/Client"
    $ClientFilePath = Join-Path -Path $ClientPath -ChildPath "/bin/Minecraft.exe"
    $ConfTmpPath = Join-Path -Path $ClientPath -ChildPath "/Conf.zip"
    $ConfFilePath = Join-Path -Path $ClientPath -ChildPath "/data/.minecraft/"
    $JDKPath = Join-Path -Path $MCPath -ChildPath "/jdk-17.0.2"
    $JDKTempPath = Join-Path -Path $MCPath -ChildPath "/jdk.zip"
    $JDKJavaPath = Join-Path -Path $JDKPath -ChildPath "/bin/java.exe"


    if ($Clean) { Remove-Item $MCPath -Recurse -Force -ErrorAction SilentlyContinue }

    New-Item -Path $tmp -Name MC -ItemType Directory
    New-Item -Path $MCPath -Name Server -ItemType Directory
    New-Item -Path $MCPath -Name Client -ItemType Directory
    New-Item -Path $ClientPath -Name "bin" -ItemType Directory
    New-Item -Path $ClientPath -Name "data" -ItemType Directory

    $ServerTask = (New-Object Net.WebClient).DownloadFileTaskAsync($ServerURL, $ServerFilePath)
    $ClientTask = (New-Object Net.WebClient).DownloadFileTaskAsync($ClientURL, $ClientFilePath)
    $ConfTask = (New-Object Net.WebClient).DownloadFileTaskAsync($ConfURL, $ConfTmpPath)
    $JDKTask = (New-Object Net.WebClient).DownloadFileTaskAsync($JDKURL, $JDKTempPath)

    New-Item -Path $ServerPath -Name "eula.txt" -ItemType File -Value "eula=true"
    #New-Item -Path $ServerPath -Name "Server.bat" -ItemType File -Value "java.exe -Xmx1024M -Xms1024M -jar $ServerPath\server.jar nogui"
    New-Item -Path $ServerPath -Name "Server.bat" -ItemType File -Value "$JDKJavaPath -Xmx1024M -Xms1024M -jar $ServerPath\server.jar nogui"
    if (!$UseProxy -or !($ProxyHost -and $ProxyPort))
    {
        New-Item -Path $ClientPath -Name "Client.bat" -ItemType File -Value "$ClientPath\bin\Minecraft.exe --workDir $ClientPath\data\.minecraft"
    }
    else
    {
        New-Item -Path $ClientPath -Name "Client.bat" -ItemType File -Value "$ClientPath\bin\Minecraft.exe --workDir $ClientPath\data\.minecraft --proxyHost $ProxyHost --proxyPort $ProxyPort"
    }
    New-Item -Path (Join-Path -Path $ClientPath -ChildPath "/data") -Name ".minecraft" -ItemType Directory

    while (-not ($ServerTask.IsCompleted -and $ClientTask.IsCompleted -and $ConfTask.IsCompleted -and $JDKTask.IsCompleted) ) { Start-Sleep -Milliseconds 500 }

    Expand-Archive -Path $ConfTmpPath -DestinationPath $ConfFilePath -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $ConfTmpPath -Force -ErrorAction SilentlyContinue

    Expand-Archive $JDKTempPath -DestinationPath $MCPath -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $JDKTempPath -Force -ErrorAction SilentlyContinue

    Start-Process (Join-Path -Path $ServerPath -ChildPath "Server.bat") -WorkingDirectory $ServerPath -WindowStyle Minimized
    Start-Process (Join-Path -Path $ClientPath -ChildPath "Client.bat") -WorkingDirectory $ClientPath -WindowStyle Hidden
}
