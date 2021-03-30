REM
REM FPulse Installer
REM    installs FPulse 3.43 on IgorPro 6 
REM 

REM Copyright (C) 2021 Alois Schlögl, IST Austria

REM make install run as admin
REM https://developpaper.com/how-to-make-bat-batch-run-with-administrators-permission/
ECHO OFF

REM source directory of FPulse 
set SRCDIR="%~dp0"
REM installation directory of FPulse
set DESTDIR=C:\FPulse

REM Directory to Igor Pro User files - here are some examples
REM Windows10 
SET IPUF=%UserProfile%"\Documents\WaveMetrics\Igor Pro 6 User Files\"
SET IPUF="C:\Program Files (x86)\WaveMetrics\Igor Pro Folder\"
if not exist %IPUF% ( 
	echo ERROR: Igor-pro-user-files-folder not found
	exit /B
)

REM === UNINSTALL ===
if [%1]==[-u] (
	del /Q %IPUF%"Igor Extensions\"FP_Mc700Tg.xop 
	del /Q %IPUF%"Igor Extensions\"FPulseCed.xop  
	del /Q %IPUF%"Igor Help Files\"FPulse.ihf 
	del /Q %IPUF%"Igor Procedures\"FPulse.ipf 
	rmdir %IPUF%"User Procedures\"FPulse
	rmdir %IPUF%"User Procedures\"FPulse_
	rmdir /S /Q %DESTDIR%
	REM --- FIXME: need elevated permissions ---
	del /Q C:\windows\SysWOW64\Use1432.dll
	del /Q C:\windows\SysWOW64\CFS32.dll
	del /Q C:\windows\SysWOW64\AxMultiClampMsg.dll
	exit /B	
)

REM === COPYING THE FILES ===

xcopy %SRCDIR%UserIgor\FPulse               %DESTDIR% /E /I
mkdir %DESTDIR%\XOPs
copy  %SRCDIR%\UserIgor\XOP_Axon\FP_Mc700Tg\VC2015\FP_Mc700Tg.xop  %DESTDIR%\XOPs\
copy  %SRCDIR%\UserIgor\XOP_Ced\FPulseCed\VC2015\FPulseCed.xop     %DESTDIR%\XOPs\
REM --- FIXME: need elevated permissions ---
copy  %SRCDIR%UserIgor\XOP_Dll\Use1432.dll 	c:\windows\SysWOW64\
copy  %SRCDIR%UserIgor\XOP_Dll\CFS32.dll 	c:\windows\SysWOW64\
copy  %SRCDIR%UserIgor\XOP_Dll\AxMultiClampMsg.dll 	c:\windows\SysWOW64\


REM === CREATING THE REQUIRED LINKS === 
mklink %IPUF%"Igor Extensions\"FP_Mc700Tg.xop %DESTDIR%\XOPs\FP_Mc700Tg.xop
mklink %IPUF%"Igor Extensions\"FPulseCed.xop  %DESTDIR%\XOPs\FPulseCed.xop
mklink %IPUF%"Igor Help Files\"FPulse.ihf     %DESTDIR%\FPulse.ihf
mklink %IPUF%"Igor Procedures\"FPulse.ipf     %DESTDIR%\FPulse.ipf
mklink /D %IPUF%"User Procedures\"FPulse      %DESTDIR%

REM === START IgorPro ===
ECHO start Igor.exe

Echo execution completed, any key to exit
exit /B

