@echo off
setlocal enabledelayedexpansion

set server1=214.63.24.4
set server2=214.63.24.5

set server1_username=server1
set server2_username=server2

set server1_password=fearlessatom
set server2_password=fearlessatom

set server1_is_available=false
set server2_is_available=false

set disk_letter=Z
set folder_name=Folder

set shared_folder_remark=Student's folder
set shared_folder_path=C:\Users\fearlessatom\Desktop
set shared_folder_name=student
set shared_name=SharedFolder

echo [INFO] Username: %username%
echo [INFO] Computer name: %computername%
echo [INFO] OS Version:
ver
echo [INFO] Network configuration:
ipconfig | findstr /C:"IPv4" /C:"Subnet" /C:"Gateway"
echo [INFO] System information:
systeminfo | findstr /C:"OS Name" /C:"OS Version" /C:"System Boot Time"

echo [INFO] Checking Server 1 (%server1%) availability...

ping %server1% -n 2 >nul 2>&1

if !errorLevel! == 0 (
   	echo [SUCCESS] Server %server1% is ONLINE

   	set server1_is_available=true
) else (
   	echo [ERROR] Server %server1% did not respond! (Error: !errorLevel!)
)

echo [INFO] Checking Server 2 (%server2%) availability...

ping %server2% -n 2 >nul 2>&1

if !errorLevel! == 0 (
   	echo [SUCCESS] Server %server2% is ONLINE

   	set server2_is_available=true
) else (
   	echo [ERROR] Server %server2% did not respond! (Error: !errorLevel!)
)

echo [INFO] Availability summary:
echo [INFO] Server 1: !server1_is_available!
echo [INFO] Server 2: !server2_is_available!

if "!server1_is_available!" == "true" (
   	echo [INFO] Adding static ARP entry for Server 1...

   	for /f "tokens=2" %%i in ('arp -a %server1% 2^>nul ^| findstr "%server1%"') do (
       		echo [INFO] Found MAC address: %%i

       		arp -s %server1% %%i >nul 2>&1

		if !errorlevel! neq 0 (
            		echo [ERROR] Failed to add static ARP entry for Server 2. Error code: !errorlevel!
		)
	)
)

if "!server2_is_available!" == "true" (
	echo [INFO] Adding static ARP entry for Server 2...

	for /f "tokens=2" %%i in ('arp -a %server2% 2^>nul ^| findstr "%server2%"') do (
		echo [INFO] Found MAC address: %%i

		arp -s %server2% %%i >nul 2>&1
	)
)

echo [INFO] Clearing existing network connections...
net use * /delete /y >nul 2>&1

if !errorLevel! == 0 (
   	echo [SUCCESS] All network resources deleted
) else (
   	echo [INFO] No network resources to delete or already cleared
)

if "!server1_is_available!" == "true" (
   	echo [INFO] Connecting to Server 1...

   	net use \\%server1% /user:%server1_username% %server1_password% >nul 2>&1
   	set net_use_error=!errorlevel!

    
   	if !net_use_error! == 0 (
       		echo [SUCCESS] Connected to Server 1 successfully
        
       		echo [INFO] Synchronizing time with Server 1...
       		net time \\%server1% /set /yes >nul 2>&1
		set net_time_error=!errorlevel!
	)
        
        if !net_time_error! == 0 (
		echo [SUCCESS] Time synchronized with Server 1
        ) else (
		echo [ERROR] Time synchronization failed (Error: !net_time_error!)
        )

	echo [INFO] Mapping network drive %disk_letter%: from Server 1...
        net use %disk_letter%: \\%server1%\%folder_name% /user:%server1_username% %server1_password% /persistent:yes >nul 2>&1
        set net_drive_error=!errorlevel!
        
        if !net_drive_error! == 0 (
        	echo [SUCCESS] Network drive %disk_letter%: mapped successfully to \\%server1%\%folder_name%
        ) else (
        	echo [ERROR] Failed to map network drive (Error: !net_drive_error!)
        )
)

mkdir %shared_folder_path%\%shared_folder_name%
echo "student's file" > %shared_folder_path%\%shared_folder_name%\file.txt

net share %shared_name%="%shared_folder_path%\%shared_folder_name%" /remark:"%shared_folder_remark%"

if !errorlevel! == 0 (
	echo [SUCCESS] Network share created: \\%computername%\%shared_folder_name%

	echo [INFO] Share path: \\%computername%\%shared_folder_name%
) else (
	echo [ERROR] Failed to create share
)

if !server1_is_available! == true (
	copy \\214.63.24.4\Folder\some_file.txt %shared_folder_path%\%shared_folder_name% >nul 2>&1

	if !errorlevel! == 0 (
		echo [SUCCESS] File copied successfully from Server 1
	) else (
		echo [ERROR] Failed to copy file from Server 1 (Error: !errorlevel!)
	)
)
