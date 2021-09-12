function Invoke-Minecraft {
    [CmdletBinding()]
	Param(
		[Parameter(Mandatory = $false, Position = 0)]
		[String]
		$ServerURL = "https://launcher.mojang.com/v1/objects/1b557e7b033b583cd9f66746b7a9ab1ec1673ced/server.jar",
        [Parameter(Mandatory = $false, Position = 1)]
		[String]
		$ClientURL = "https://launcher.mojang.com/download/Minecraft.exe",
        [Parameter(Mandatory = $false, Position = 2)]
		[String]
		$ConfURL = "https://github.com/PwshLab/Invoke-Minecraft/blob/288287cdb038f147742836bfb56ca4c1ab9eb441/Conf.zip",
        [Parameter(Mandatory = $false, Position = 3)]
		[Switch]
        $Clean
	)

    $tmp = $env:TEMP
    $MCPath = Join-Path -Path $tmp -ChildPath "/MC"
    $ServerPath = Join-Path -Path $MCPath -ChildPath "/Server"
    $ServerFilePath = Join-Path -Path $ServerPath -ChildPath "/server.jar"
    $ClientPath = Join-Path -Path $MCPath -ChildPath "/Client"
    $ClientFilePath = Join-Path -Path $ClientPath -ChildPath "/bin/Minecraft.exe"
    $ConfTmpPath = Join-Path -Path $ClientPath -ChildPath "/Conf.zip"
    $ConfFilePath = Join-Path -Path $ClientPath -ChildPath "/data/.minecraft/"

    if ($Clean) { Remove-Item $MCPath -Recurse -Force -ErrorAction SilentlyContinue }

    New-Item -Path $tmp -Name MC -ItemType Directory
    New-Item -Path $MCPath -Name Server -ItemType Directory
    New-Item -Path $MCPath -Name Client -ItemType Directory
    New-Item -Path $ClientPath -Name "bin" -ItemType Directory
    New-Item -Path $ClientPath -Name "data" -ItemType Directory

    $ServerTask = (New-Object Net.WebClient).DownloadFileTaskAsync($ServerURL, $ServerFilePath)
    $ClientTask = (New-Object Net.WebClient).DownloadFileTaskAsync($ClientURL, $ClientFilePath)
    $ConfTask = (New-Object Net.WebClient).DownloadFileTaskAsync($ConfURL, $ConfTmpPath)

    New-Item -Path $ServerPath -Name "eula.txt" -ItemType File -Value "eula=true"
    New-Item -Path $ServerPath -Name "Server.bat" -ItemType File -Value "java.exe -Xmx1024M -Xms1024M -jar $ServerPath\server.jar nogui"
    New-Item -Path $ClientPath -Name "Client.bat" -ItemType File -Value "$ClientPath\bin\Minecraft.exe --workDir $ClientPath\data\.minecraft"
    New-Item -Path (Join-Path -Path $ClientPath -ChildPath "/data") -Name ".minecraft" -ItemType Directory

    while (-not ($ServerTask.IsCompleted -and $ClientTask.IsCompleted -and $ConfTask.IsCompleted) ) { Start-Sleep -Milliseconds 500 }

    Expand-Archive -Path $ConfTmpPath -DestinationPath $ConfFilePath -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $ConfTmpPath -Force -ErrorAction SilentlyContinue

    Start-Process (Join-Path -Path $ServerPath -ChildPath "Server.bat") -WorkingDirectory $ServerPath -WindowStyle Minimized
    Start-Process (Join-Path -Path $ClientPath -ChildPath "Client.bat") -WorkingDirectory $ClientPath -WindowStyle Hidden
}
