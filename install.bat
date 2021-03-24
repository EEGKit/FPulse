REM
REM FPulse Installer
REM    installs FPulse 3.43 on IgorPro 6 
REM 

REM Copyright (C) 2021 Alois Schlögl, IST Austria



REM make install run as admin
REM https://developpaper.com/how-to-make-bat-batch-run-with-administrators-permission/
REM mshta vbscript:CreateObject("Shell.Application").ShellExecute("cmd.exe","/c %~s0 ::","","runas",1)(window.close)&&exit /B


REM directory of FPulse 
set SRCDIR="%~dp0"

REM Directory to Igor Pro User files - here are some examples
REM Windows10 
SET IPUF=%UserProfile%"\Documents\WaveMetrics\Igor Pro 6 User Files\"
REM https://superuser.com/questions/253935/what-is-the-difference-between-symbolic-link-and-shortcut
if not exist %IPUF% ( 
	REM WinXP
	SET IPUF="C:\Program Files (x86)\WaveMetrics\Igor Pro Folder\"
)

if not exist %IPUF% ( 
	echo ERROR: Igor-pro-user-files-folder not found
	exit /B
)

REM === UNINSTALL ===
if [%1]==[-u] (
	del /Q %SRCDIR%UserIgor\FPulse_  
	del /Q %IPUF%"Igor Extensions\"FP_Mc700Tg.xop 
	del /Q %IPUF%"Igor Extensions\"FPulseCed.xop  
	del /Q %IPUF%"Igor Help Files\"FPulse.ihf 
	del /Q %IPUF%"Igor Procedures\"FPulse.ipf 
	del /Q %IPUF%"User Procedures\"FPulse_
	del /Q C:\windows\SysWOW64\Use1432.dll
	del /Q C:\windows\SysWOW64\CFS32.dll
	del /Q C:\windows\SysWOW64\AxMultiClampMsg.dll
	exit /B	
)

REM === COPYING THE FILES ===

copy  %SRCDIR%UserIgor\XOP_Dll\Use1432.dll 	c:\windows\SysWOW64\
copy  %SRCDIR%UserIgor\XOP_Dll\CFS32.dll 	c:\windows\SysWOW64\
copy  %SRCDIR%UserIgor\XOP_Dll\AxMultiClampMsg.dll 	c:\windows\SysWOW64\
copy  %SRCDIR%UserIgor\FPulse                   %SRCDIR%UserIgor\FPulse_
 
mkdir %SRCDIR%UserIgor\FPulse_\XOPs
copy  %SRCDIR%UserIgor\XOP_Axon\FP_Mc700Tg\VC2015\FP_Mc700Tg.xop  %SRCDIR%UserIgor\FPulse_\XOPs\
copy  %SRCDIR%UserIgor\XOP_Ced\FPulseCed\VC2015\FPulseCed.xop     %SRCDIR%UserIgor\FPulse_\XOPs\


REM === CREATING THE REQUIRED LINKS === 
mklink %IPUF%"Igor Extensions\"FP_Mc700Tg.xop %SRCDIR%"UserIgor\FPulse_\XOPs\FP_Mc700Tg.xop"
mklink %IPUF%"Igor Extensions\"FPulseCed.xop  %SRCDIR%"UserIgor\FPulse_\XOPs\FPulseCed.xop"
mklink %IPUF%"Igor Help Files\"FPulse.ihf     %SRCDIR%"UserIgor\FPulse_\FPulse.ihf"
mklink %IPUF%"Igor Procedures\"FPulse.ipf     %SRCDIR%"UserIgor\FPulse_\FPulse.ipf"
mklink /D %IPUF%"User Procedures\"FPulse_     %SRCDIR%"UserIgor\FPulse_"         


REM === START IgorPro ===
ECHO start Igor.exe


