ECHO OFF
REM
REM FPulse Installer
REM    installs FPulse 3.45 on IgorPro 6
REM

REM Copyright (C) 2021 Alois Schlögl, IST Austria

REM make install run as admin
REM https://developpaper.com/how-to-make-bat-batch-run-with-administrators-permission/
REM    4. Automatically run batch (BAT) files as Administrator

PUSHD %~DP0 & cd /d "%~dp0"
%1 %2
mshta vbscript:createobject("shell.application").shellexecute("%~s0","goto :runas","","runas",1)(window.close)&goto :eof
:runas

::

REM source directory of FPulse
set SRCDIR="%~dp0"
REM installation directory of FPulse
set DESTDIR=C:\UserIgor\FPulse

REM Directory to Igor Pro User files - here are some examples
SET IPUF=%UserProfile%"\Documents\WaveMetrics\Igor Pro 6 User Files\"
SET IPUF="C:\Program Files (x86)\WaveMetrics\Igor Pro Folder\"
if not exist %IPUF% (
	echo ERROR: Igor-pro-user-files-folder not found
	exit /B
)

if [%0]==[uninstall.bat] GOTO UNINSTALL0
if [%1]==[-u]            GOTO UNINSTALL
GOTO INSTALL

:UNINSTALL0
	cd \
:UNINSTALL
	ECHO === Uninstall Igor links %IPUF% ===
	del /Q %IPUF%"Igor Extensions\"FP_Mc700Tg.xop
	del /Q %IPUF%"Igor Extensions\"FPulseCed.xop
	del /Q %IPUF%"Igor Help Files\"FPulse.ihf
	del /Q %IPUF%"Igor Procedures\"FPulse.ipf
	rmdir %IPUF%"User Procedures\"FPulse
	ECHO === Remove DLL's from CED and MultiClamp (need elevated permissions) ===
	del /Q C:\Windows\SysWOW64\Use1432.dll
	del /Q C:\Windows\SysWOW64\CFS32.dll
	del /Q C:\Windows\SysWOW64\AxMultiClampMsg.dll
	ECHO === Uninstall %DESTDIR% ===
	rmdir /S /Q %DESTDIR%
	GOTO END

:INSTALL
	ECHO === Copying Files into %DESTDIR% ===
	xcopy %SRCDIR%UserIgor\FPulse               %DESTDIR% /E /I /Q
	copy  %SRCDIR%\install.bat  %DESTDIR%\uninstall.bat
	mkdir %DESTDIR%\XOPs
	copy  %SRCDIR%\UserIgor\XOP_Axon\FP_Mc700Tg\VC2015\FP_Mc700Tg.xop  %DESTDIR%\XOPs\
	copy  %SRCDIR%\UserIgor\XOP_Ced\FPulseCed\VC2015\FPulseCed.xop     %DESTDIR%\XOPs\

	ECHO === Install DLLs and remove CFS32.dll, (need elevated permissions) ===
	del /Q C:\Windows\SysWOW64\CFS32.dll
	del /Q C:\Windows\SysWOW64\Use1432.dll
	REM copy  %SRCDIR%UserIgor\XOP_Dll\Use1432.dll 	C:\Windows\SysWOW64\
	copy  %SRCDIR%UserIgor\XOP_Dll\AxMultiClampMsg.dll 	C:\Windows\SysWOW64\

	ECHO === Create Links for Igor ===
	mklink %IPUF%"Igor Extensions\"FP_Mc700Tg.xop %DESTDIR%\XOPs\FP_Mc700Tg.xop
	mklink %IPUF%"Igor Extensions\"FPulseCed.xop  %DESTDIR%\XOPs\FPulseCed.xop
	mklink %IPUF%"Igor Help Files\"FPulse.ihf     %DESTDIR%\FPulse.ihf
	mklink %IPUF%"Igor Procedures\"FPulse.ipf     %DESTDIR%\FPulse.ipf
	mklink /D %IPUF%"User Procedures\"FPulse      %DESTDIR%
	GOTO END

:END

Echo execution completed, any key to exit

pause >nul


