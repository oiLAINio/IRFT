
# IRFT v1.3 oiLAINio
# A tool to automate data collection that would be used for investigation and troubleshooting

# This saves the drive letter of the USB to a file on the C drive. I did this because once powershell runs as admin, it runs command through C

#Gets the location that the script was ran from and adds a suffix to make it look like a drive location
$CUD = (get-location).Drive.Name
$CUD2 = "DriveL = " + $CUD + ":\"
#Defines document prop to recover USB letter
$ThisScript = $CUD + ":\conf.txt"
$UName = $env:UserName
$DrDaLoc = "C:\Users\" + $UName + "\IRFT.txt"

# Saves the file but not if the drive letter is C. This is because this whole script is ran again when it hits the "Run as admin" section
# And we dont want the file to be overwritten with the letter C
if ($CUD -eq "C"){

}
else{
 New-Item $DrDaLoc
 echo $CUD > $DrDaLoc
}

#Runs the script as admin
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }

$Devhos = hostname
$Devdat = date
$MemDumpLoc = 'C:\Windows\memory.dmp'
$ErrCount = 0 # keeps count of errors
$console = $host.ui.rawui
$console.backgroundcolor = "DarkMagenta"
$console.foregroundcolor = "white"
$Drivep = Get-Content $DrDaLoc
$RootPath = $Drivep + ":\"
[uint16]$NetCapRunTime = 10 #A var that is used to define how long netcap runs for
$BadIn = 0 # keeps count of invalid user input
$SS = Get-Random -Maximum 3 # This will handle the Logo random logo




#make a new dir for the device
function Build-Path {
	Write-Output "Building paths"
	New-Item -ItemType directory -Path $RootPath$Devhos
    New-Item -ItemType directory -Path $RootPath$Devhos -Name "Network"
    New-Item -ItemType directory -Path $RootPath$Devhos -Name "Info"
    New-Item -ItemType directory -Path $RootPath$Devhos -Name "Process"
    New-Item -ItemType directory -Path $RootPath$Devhos -Name "Files"
    New-Item -ItemType directory -Path $RootPath$Devhos -Name "Logs"
    New-Item -ItemType directory -Path $RootPath$Devhos -Name "MemoryDump"
	Write-Output "Done!"
	Write-Output " "
}




#------------------------------------------------
#Think of these as plugins for different settings
#------------------------------------------------

#make a txt document with basic info of the device
function Write-IP {
	Write-Output "Getting Device Info"
	echo SystemInfo >> $RootPath$Devhos\Info\Device_Info.txt
	echo ======================================================================= >> $RootPath$Devhos\Info\Device_Info.txt
	date >> $RootPath$Devhos\Info\Device_Info.txt
	hostname >> $RootPath$Devhos\Info\Device_Info.txt
	host >> $RootPath$Devhos\Info\Device_Info.txt

	echo =========== NetworkInfo ================================ >> $RootPath$Devhos\Info\Device_Info.txt
	ipconfig >> $RootPath$Devhos\Info\Device_Info.txt
	Write-Output "Done!"
}

#Check for a memory dump and copy it to a memory dump file if found. Else make a .txt to inform user that no file was found 
Function Mem-Dump{
	Write-Output "Building memory dump path"
	Write-Output "Done!"
	Write-Output " "
	Write-Output "Looking for memory dumps"
	if ( Test-Path -Path $MemDumpLoc -PathType Leaf) {
		Write-Output "Memory dump found! copying now"
		Write-Output "memory dump found at C:\Windows" >> $RootPath$Devhos\MemoryDump\FILE_FOUND.TXT
		Copy-Item -Path $MemDumpLoc -Destination $RootPath$Devhos\MemoryDump
		Write-Output "Done!"
		Write-Output " "
	}
	else {
		Write-Output "Memory dump cannot be found! moving on"
		Write-Output "No memory dump found at location C:\Windows" >> $RootPath$Devhos\MemoryDump\FILE_NOT_FOUND.TXT
		Write-Output " "
	}
}

#Makes an excel document of all running processes
Function Get-PId {
	Write-Host "Getting PID" -ForegroundColor Cyan
	wmic process get Caption,ParentProcessId,ProcessId >> $RootPath$Devhos\Process\Active_Process.csv
	Write-Host "Done!" -ForegroundColor Green
	Write-Host " "
}

#outputs the netstat command to excel
function Get-NetStat {
	Write-Host "Getting Netstat" -ForegroundColor Cyan
	netstat -o -a >>$RootPath$Devhos\Network\Active_Connections.csv
	Write-Host "Done!" -ForegroundColor Green
	Write-Host " "
}

#catalogs software on the device
function Get-softwarelist {
	Write-Host "Getting software list" -ForegroundColor Cyan
	Get-WmiObject -Class Win32_Product | select Name, Version, InstallDate >> $RootPath$Devhos\Files\Software_Catalog.csv
	Write-Host "Done!" -ForegroundColor Green
	Write-Host " "
}

#Saves the hash of all items in the users downloads to excel
function Get-DownloadHash {
	Write-Host "Getting file hash from Downloads" -ForegroundColor Cyan
	ls C:\Users\$env:UserName\Downloads | Get-FileHash >> $RootPath$Devhos\Files\Downloads_Hash.csv
	Write-Host "Done!" -ForegroundColor Green
	Write-Host " "
}

#Saves the hash of all items on the C drive to excel
function Get-CHash {
	Write-Host "Getting file hash from Downloads" -ForegroundColor Cyan
	Get-ChildItem -Path "C:\" -Recurse | Get-FileHash >> $RootPath$Devhos\Files\Cdrive_Hash.csv
	Write-Host "Done!" -ForegroundColor Green
	Write-Host " "
}

#Saves the event logs
Function GEt-Event {
    Write-Host "Making a copy of the event logs" -ForegroundColor Cyan
	Get-EventLog -LogName System >> $RootPath$Devhos\Logs\System_Events.csv
	Get-EventLog -LogName Application >> $RootPath$Devhos\Logs\Application_Events.csv
    Write-Host "Done!" -ForegroundColor Green
	Write-Host " "
    
} 

#Saves the DNS output from IPconfig to excel
function GEt-DNs {
    Write-Host "Getting DNS" -ForegroundColor Cyan
	ipconfig /displaydns >> $RootPath$Devhos\Network\DNS.csv
    Write-Host "Done!" -ForegroundColor Green
	Write-Host " "
}

#Saves the DNS cache to excel
Function Get-DNS-Cache {
    Write-Host "Copying DNS cache" -ForegroundColor Cyan
    GEt-DNsClientCache >> $RootPath$Devhos\Network\DNS_cache.csv
    Write-Host "Done!" -ForegroundColor Green
	Write-Host " "
}

#Resize the window. imma be honest... this is just so the logo looks good ¯\_(ツ)_/¯. 
function RSZwindow {
    $pshost = get-host
    $pswindow = $pshost.ui.rawui
    $newsize = $pswindow.buffersize
    $newsize.height = 3000
    $newsize.width = 150
    $pswindow.buffersize = $newsize
}

#Clean up files made by this script
Function CocoMelon {
    echo " Cleaning Up "
    Remove-Item $DrDaLoc
    echo " "
    echo " Done !"
}

#Give the user the option to return to the home page
function JobDone {
    $console.backgroundcolor = "DarkGreen"
    $mode = Read-Host "Job Done. Enter (E) to exit or any other key to go back home"
    $console.backgroundcolor = "DarkMagenta"
    switch ( $SS )
    {
    	'E'
    	{
    	
	    }
	    Default 
        {
        HomeB
        }
    } 
}







#used when the user selects the settings option
function SSEtting {
    clear-host
    se1
    echo " "
    echo " " 
    write-host "NetCap run time = " -foreground Blue -nonewline
    write-host $NetCapRunTime -foreground Yellow
    echo " " 
    echo "1) Change NetCap run Time "
    echo "9) Go Back"
    $SSEt = Read-Host "Please select"
    switch ( $SSEt )
    {
    	'1'
    	{
    	echo " "
        echo " "
        [uint16]$NetCapRunTime = Read-Host "Please select NetCap Run Time"
        SSEtting
	    }
        '9'
        {
        HomeB
        }
	    Default 
        {
        SSetting
        echo "That was not a valid option"
        }
    } 
}

#-----------------------------------
#Logos used as random Menu image
#-----------------------------------

# 1
function SS1 {
	$console.backgroundcolor = "DarkMagenta"
	$console.foregroundcolor = "white"
	echo "          _____                    _____                    _____                _____          "
	echo "         /\    \                  /\    \                  /\    \              /\    \         "
	echo "        /::\    \                /::\    \                /::\    \            /::\    \        "
	echo "        \:::\    \              /::::\    \              /::::\    \           \:::\    \       "
	echo "         \:::\    \            /::::::\    \            /::::::\    \           \:::\    \      "
	$console.foregroundcolor = "Yellow"
	echo "          \:::\    \          /:::/\:::\    \          /:::/\:::\    \           \:::\    \     "
	echo "           \:::\    \        /:::/__\:::\    \        /:::/__\:::\    \           \:::\    \    "
	echo "           /::::\    \      /::::\   \:::\    \      /::::\   \:::\    \          /::::\    \   "
	echo "  ____    /::::::\    \    /::::::\   \:::\    \    /::::::\   \:::\    \        /::::::\    \  "
	$console.foregroundcolor = "Cyan"
	echo " /\   \  /:::/\:::\    \  /:::/\:::\   \:::\____\  /:::/\:::\   \:::\    \      /:::/\:::\    \ "
	echo "/::\   \/:::/  \:::\____\/:::/  \:::\   \:::|    |/:::/  \:::\   \:::\____\    /:::/  \:::\____\"
	echo "\:::\  /:::/    \::/    /\::/   |::::\  /:::|____|\::/    \:::\   \::/    /   /:::/    \::/    /"
	echo " \:::\/:::/    / \/____/  \/____|:::::\/:::/    /  \/____/ \:::\   \/____/   /:::/    / \/____/ "
	echo "  \::::::/    /                 |:::::::::/    /            \:::\    \      /:::/    /  V1.3    "
	$console.foregroundcolor = "Blue"
	echo "   \::::/____/                  |::|\::::/    /              \:::\____\    /:::/    /           "
	echo "    \:::\    \                  |::| \::/____/                \::/    /    \::/    /            "
	echo "     \:::\    \                 |::|  ~|                       \/____/      \/____/             "
	echo "      \:::\    \                |::|   |                                                        "
	echo "       \:::\____\               \::|   |                                                        "
	echo "        \::/    /                \:|   |                                                        "
	echo "         \/____/                  \|___|                                                        "
	echo " "                                                                                                
	echo " "
	
}
# 2
function SS2 {
	echo " .----------------.  .----------------.  .----------------.  .----------------. "
	echo "| .--------------. || .--------------. || .--------------. || .--------------. |"
	echo "| |     _____    | || |  _______     | || |  _________   | || |  _________   | |"
	echo "| |    |_   _|   | || | |_   __ \    | || | |_   ___  |  | || | |  _   _  |  | |"
	echo "| |      | |     | || |   | |__) |   | || |   | |_  \_|  | || | |_/ | | \_|  | |"
	echo "| |      | |     | || |   |  __ /    | || |   |  _|      | || |     | |      | |"
	echo "| |     _| |_    | || |  _| |  \ \_  | || |  _| |_       | || |    _| |_     | |"
	echo "| |    |_____|   | || | |____| |___| | || | |_____|      | || |   |_____|    | |"
	echo "| |              | || |              | || |              | || |              | |"
	echo "| '--------------' || '--------------' || '--------------' || '--------------' |"
	echo " '----------------'  '----------------'  '----------------'  '----------------'  V1.3"
	echo " "                                                                                                
	echo " "
	
}
# 3
function SS3 {
    $console.foregroundcolor = "White"
	$console.backgroundcolor = "Black"
	echo "  /\\\\\\\\\\\_        ____/\\\\\\\\\_____        __/\\\\\\\\\\\\\\\_        __/\\\\\\\\\\\\\\\_        "
	echo " _\/////\\\///__        __/\\\///////\\\___        _\/\\\///////////__        _\///////\\\/////__       "
	$console.backgroundcolor = "DarkBlue"
	echo "  _____\/\\\_____        _\/\\\_____\/\\\___        _\/\\\_____________        _______\/\\\_______  V1.3"
	echo "   _____\/\\\_____        _\/\\\\\\\\\\\/____        _\/\\\\\\\\\\\_____        _______\/\\\_______     "
	$console.backgroundcolor = "DarkGreen"
	echo "    _____\/\\\_____        _\/\\\//////\\\____        _\/\\\///////______        _______\/\\\_______    "
	echo "     _____\/\\\_____        _\/\\\____\//\\\___        _\/\\\_____________        _______\/\\\_______   "
	$console.backgroundcolor = "DarkCyan"
	echo "      _____\/\\\_____        _\/\\\_____\//\\\__        _\/\\\_____________        _______\/\\\_______  "
	echo "       __/\\\\\\\\\\\_        _\/\\\______\//\\\_        _\/\\\_____________        _______\/\\\_______ "
	$console.backgroundcolor = "DarkMagenta"
	echo "        _\///////////__        _\///________\///__        _\///______________        _______\///________"
	echo " "                                                                                                
	echo " "
	
}
# 4 used after
function lg1 {
    write-host "    ____           _     __           __  "-foreground Blue -nonewline  
    write-host "____                                      "-foreground Green -nonewline 
    write-host "  ______                           _     "-foreground Cyan -nonewline 
    write-host " ______            __"-foreground red
    write-host "   /  _/___  _____(_)___/ /__  ____  / /_"-foreground Blue -nonewline  
    write-host "/ __ \___  _________  ____  ____  ________ "-foreground Green -nonewline 
    write-host " / ____/___  ________  ____  _____(_)____"-foreground Cyan -nonewline 
    write-host "/_  __/___  ____  / /"-foreground red
    write-host "   / // __ \/ ___/ / __  / _ \/ __ \/ __/"-foreground Blue -nonewline  
    write-host " /_/ / _ \/ ___/ __ \/ __ \/ __ \/ ___/ _ \"-foreground Green -nonewline 
    write-host "/ /_  / __ \/ ___/ _ \/ __ \/ ___/ / ___/"-foreground Cyan -nonewline 
    write-host " / / / __ \/ __ \/ / "-foreground red
    write-host " _/ // / / / /__/ / /_/ /  __/ / / / /_"-foreground Blue -nonewline  
    write-host "/ _, _/  __(__  ) /_/ / /_/ / / / (__  )  __/"-foreground Green -nonewline 
    write-host " __/ / /_/ / /  /  __/ / / (__  ) / /__  "-foreground Cyan -nonewline 
    write-host "/ / / /_/ / /_/ / /  "-foreground red
    write-host "/___/_/ /_/\___/_/\__,_/\___/_/ /_/\__/"-foreground Blue -nonewline  
    write-host "_/ |_|\___/____/ .___/\____/_/ /_/____/\___/"-foreground Green -nonewline 
    write-host "_/    \____/_/   \___/_/ /_/____/_/\___/ "-foreground Cyan -nonewline 
    write-host "/_/  \____/\____/_/   "-foreground red
    write-host "                                       "-foreground Blue -nonewline  
    write-host "              /_/                           "-foreground Green -nonewline 
    write-host "                                         "-foreground Cyan -nonewline 
    write-host "                      "-foreground red


}
function se1 {
    echo " _______  _______ ___________________________ _        _______  _______ "
    echo "(  ____ \(  ____ \\__   __/\__   __/\__   __/( (    /|(  ____ \(  ____ \"
    echo "| (    \/| (    \/   ) (      ) (      ) (   |  \  ( || (    \/| (    \/"
    echo "| (_____ | (__       | |      | |      | |   |   \ | || |      | (_____ "
    echo "(_____  )|  __)      | |      | |      | |   | (\ \) || | ____ (_____  )"
    echo "      ) || (         | |      | |      | |   | | \   || | \_  )      ) |"
    echo "/\____) || (____/\   | |      | |   ___) (___| )  \  || (___) |/\____) |"
    echo "\_______)(_______/   )_(      )_(   \_______/|/    )_)(_______)\_______)"
    echo "                                                                        "
}
function he1{
    echo "          _______  _        _______ "
    echo "|\     /|(  ____ \( \      (  ____ )"
    echo "| )   ( || (    \/| (      | (    )|"
    echo "| (___) || (__    | |      | (____)|"
    echo "|  ___  ||  __)   | |      |  _____)"
    echo "| (   ) || (      | |      | (      "
    echo "| )   ( || (____/\| (____/\| )      "
    echo "|/     \|(_______/(_______/|/       "
    echo "                                    "


}








# Option list shown at home screen
function Options {
	$console.foregroundcolor = "White"
	echo "                              Incident Response Forensic Tool version 1.3"
	echo " "
	echo "      Please select Forensic mode"
	echo " "
	write-host " (L)ite" -foreground Cyan -nonewline
	write-host " - Fast but gathers little data" -foreground Yellow
	write-host " (B)asic" -foreground Cyan -nonewline
	write-host " - Slower but gets more data" -foreground Yellow
	write-host " (F)ull" -foreground Cyan -nonewline
	write-host " - Slowest but includes everything you need for investigation" -foreground Yellow
	write-host " (H)ash" -foreground Cyan -nonewline
	write-host " Grabs the hash of all files on the C drive. this will take some time" -foreground Yellow
	echo "  --------------------------------------------------------------"
	write-host " (S)ettings" -foreground Green -nonewline
	write-host " - Change Setings" -foreground Yellow
    write-host " (H)elp" -foreground Green -nonewline
	write-host " - List the difference between the 3 modes"-foreground Yellow
	echo "  --------------------------------------------------------------"
	write-host " (Q)uit" -foreground Red
	write-host -foreground White
	echo " "
    
}
function HElp{
    clear-host
    he1
    echo " "
    echo " "
    write-host " (L)ite" -foreground Cyan
    echo "> Saves IP"
    echo "> Saves PID"
    echo " "
    write-host " (B)asic" -foreground Cyan
    echo "> Saves IP"
    echo "> Saves PID"
    echo "> Saves NetStat"
    echo "> Saves DNS info"
    echo " "
    write-host " (F)ull" -foreground Cyan
    echo "> Saves IP"
    echo "> Saves PID"
    echo "> Saves NetStat"
    echo "> Saves DNS info"
    echo "> Saves A list of software"
    echo "> Saves The file hash of recent downloads"
    echo "> Saves Events/Logs"
    echo "> Runs A packet capture"
    echo " "
    $HElpm = Read-Host "Press any key to go home or Q to quit"
    switch ( $HElpm )
    {
        'Q'
        {
    	
	    }
	    Default 
        {
        HomeB
        }

    }
}

# home Handles printing the home screen and input in relation to what functions to run
function HomeB {
    clear-host 
    #Logo select
    switch ( $SS )
    {
    	'0'
    	{
    	SS1
    	Options
	    }
	    '1'
	    {
	    SS2
        Options
	    }
	    '2'
	    {
	    SS3
	    Options
	    }
    }
    if ($BadIn -eq "1"){
    write-host "That was not a valid option" -foreground Red -nonewline
    }
    else{

    }

    $mode = Read-Host "Select forensic mode (L)(B)(F)(S)(Q)(H)" #user input

    switch ( $mode ) # This takes that input and runs the functions inside
    {
        'L'
        {
        $BadIn = 0
        clear-host
        lg1
        Build-Path
        Write-IP
        Get-PId
        CocoMelon
        JobDone 
        }
        'B'
        {
        $BadIn = 0
        clear-host
        lg1
        Build-Path
        Write-IP
        Get-PId
        GEt-DNs
        Get-NetStat
        CocoMelon
        JobDone
        Read-Host -Prompt "Job finished. You can press any key to close this window" 
        }
        'F'
        {
        $BadIn = 0
        clear-host
        lg1
        Build-Path
        echo "Building path for NetCap"
        echo " "
        New-Item -ItemType directory -Path $RootPath$Devhos -Name "NetCap"
        echo " Done! "
        netsh trace start capture=yes tracefile=$RootPath$Devhos\NetCap\NetCapture.etl
        Write-IP
        Mem-Dump
        Get-PId
        GEt-DNs
        Get-NetStat
        Get-softwarelist
        Get-DownloadHash
        GEt-Event
        Get-DNS-Cache
        Get-CHash
        echo "Waiting for NetCap timeout"
        Start-Sleep -s $NetCapRunTime
        echo "Stopping Net capture"
        echo " "
        netsh trace stop
        CocoMelon
        JobDone
        }
	'H'
	{
	$BadIn = 0
        clear-host
        lg1
        Build-Path
	Get-CHash
	CocoMelon
        JobDone
	}
        'S'
        {
        $BadIn = 0
        SSEtting
        }
        'Q'
        {
        $BadIn = 0
        CocoMelon
        }
        'H'
        {
        $BadIn = 0
        HElp
        }
        Default 
        {
        $BadIn = 1
        HomeB
        }
    }
}
RSZwindow
HomeB
