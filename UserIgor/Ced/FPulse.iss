;
; --------------------------------  Anleitung zur Compilierung von FPulse  -------------------------------------------
;
;  1) Quelldaten bereitstellen
;
;  Die Dateien der neuen Version in ein Verzeichnis kopieren 							e.G. "F:\FPulse"
;  Es werden nur Dateien mit folgenden Endungen kopiert :
;  *.ipf,*.ihf,*.xop,*.rtf
;
;  Die benötigten DLLs in ein Unterverzeichnis Namens \DLL kopieren    					e.G. "F:\FPulse\Dll"
;  Die DLLs werden in das auf dem Zielsystem befindliche Systemverzeichnis kopiert
;
;  Die DemoScripts in das Unterverzeichnis \DemoScripts kopieren 						e.G. "F:\FPulse\DemoScripts"
;  Es werden nur Dateien nach folgenden Kriterien kopiert :
;  AP*.* ; Demo*.txt ; Sine*.ibw
;
;  2) Compilieren
;
;  Im Inno Setup Pack ist ein zusätzlicher "Inno Setup Command Line Compiler" welcher als ISCC.EXE im
;  Stammverzeichniss von Inno Setup liegt. Um diesen auszuführen gilt als Beispiel ein Aufruf aus dem Root Verzeichnis
;
;  C:\Programme\Inno Setup 4\ISCC.EXE "C:\FPulseInstall\FPulse.iss" /dVarName1=Value /dVarName2=Value
;
;  Der erste Pfad gibt an wo sich die ISCC.EXE befindet. Die Angabe in Klammern ist der vollständige Pfad zum
;  Inno Setup Script welches compiliert werden soll. Danach folgen die einzustellenden Parameter.
;  Bei der FPulse Compilierung MÜSSEN diese Parameter übergeben werden :
;
;  /dAppNm=FPulse				- Applikationsname, welcher sowohl in der generierten Setup.exe als auch nach
;								  nach der Installation unter "Einstellungen/Systemsteuerung/Software" zu finden ist.
;
;  /dVers=1.1 					- Versionsnummer, welche sowohl in dem generierten Setup File als auch nach der
;								  installation unter "Einstellungen/Systemsteuerung/Software" zu finden ist.
;
;  /dBirth=Crypt2754.exe		- Hier wird der Name der Datei angegeben, welche auch im Quellordner sein muss !
;  								  Diese Datei wird ins aktuelle Systemverzeichnis des OS kopiert und als
;  								  Systemdatei deklariert sowie als versteckte Datei gekennzeichnet.
;  								  Ziel und Quellname sind hier identisch.
;
;  /dSrc=F:\FPulse				- Verzeichnis, in das die Installationsdateien unter Punkt 1 kopiert wurden.
;
;
;  /dMsk=F:\FPulse\*.*			- Verzeichnis MUSS mit dem in /dSOURCE angegebenen übereinstimmen (Wildcard nicht vergessen)
;
;
;  /dODir=F:\FPulse				- Verzeichniss in dem die fertig compilierte Setupdatei abgelegt wird. Der Name
;								  der Datei wird aus dem AppNm und der Versionsnummer erstellt. Eine Änderung dessen
;  								  ist nach dem compilieren nur noch durch Umbenennen möglich
;
;  /dDDir=C:\UserIgor\FPulse	- Verzeichnis, in das FPulse beim Kunden installiert wird, wenn keine
;								  vorhergehende Installation gefunden wurde und der Kunde dieses Verzeichnis
;								  nicht selbst während der Installation ändert
;
;
;
;
; ------------------------------------------  PreProcessor   -----------------------------------------------

;	Der PreProcessor überprüft ob alle Parameter verwendet wurden und gibt eine Fehlermeldung aus falls dies so nicht so ist


	#ifndef AppNm
	#error Parameter 'Application Name' not defined. e.g. "/dAppNm=FPulse"
	#endif

	#ifndef Vers
	#error Parameter 'Version' not defined. e.g. "/dVers=1.20c"
	#endif

; 2009-10-22 no longer required
;	#ifndef Birth
;	#error Parameter 'BirthdayFile' not defined. e.g. "/dBirth=cryptbitl.dll"
;	#endif

	#ifndef Src
	#error Parameter 'Source' not defined. e.g. "/dSrc=D:\FPulse"
	#endif

	#ifndef Msk
	#error Parameter 'Mask' not defined. e.g. "/dMsk=D:\FPulse\*.*"
	#endif

	#ifndef ODir
	#error Parameter 'OutputDir' not defined. e.g. "/dODir=D:\FPulse\Release"
	#endif

	#ifndef DDir
	#error Parameter 'DefaultDir' not defined. e.g. "/dDDir=C:\UserIgor\FPulse"
	#endif

; 	Der PreProcessor bearbeitet nun untenstehende Definitionen
;
;
;   WICHTIG : 	Bei der Verzeichnisangabe MUSS ein Backslash auch nach dem Ordnernamen angefügt werden
;             	z.B. "\Igor Help Files\"
;
	#define IHF 		"\Igor Help Files\"		; Standardpfad der *.ihf Dateien
	#define XOP 		"\Igor Extensions\"		; Standardpfad der *.xop Dateien
	#define UP  		"\User Procedures\"		; Standardpfad der *.ipf Dateien
	#define IPF			"\Igor Procedures\"		; Standardpfad der FPulse.ipf
;
;   WICHTIG : 	NIEMALS ändern, es führt zu Mehrfachinstallation und Dateileichen !! ,
;				da unter dieser ID das Programm in der Registry registriert wird.
;
	#define AppIdent 	"FPulse_FEval"		; SAME IN  FPULSE.ISS  and in  FPulseCed.C
;
;   Hier sind die Informationen des Publishers einzustellen. Sie werden wärend der Installation unter der Hilfe
;   angezeigt. Üblicherweise kommen sie jedoch nicht zum tragen.
;
	#define Pub			"Physiologie I, Universität Freiburg"  		;Name des Publishers
	#define PubURL		"http://jonas2.physiol.uni-freiburg.de/"	;Die Homepage des Publishers
	#define CopRight	"Copyright © 2004-2006 Dr. U. Fröbe"		;Copyright
;
;  	HINWEIS : Um ein schnelleres Compilieren zu ermöglichen kann die Kompression ausgeschaltet werden.
;
;  	WICHTIG : Falls keine Kompression verwendet wird entspricht die Dateigröße NICHT der endgültigen größe
;            der Setupdatei.
;
    #define Comp		"true"   				; Setzt die Kompression ein/aus ( aus: Schnellere Verarbeitung, große Dateien )
;

; ---------------------------- Kosmetische Veränderungen am Installer --------------------------------

[Setup]

; Dateiname des verwendeten Bildes bei der Installation, max 314 y * 164 x pixel ( Wenn auskommentiert wird das Standardbild verwendet )

WizardImageFile=FPulseLogo.bmp

; Verhindert, dass das bei Installation verwendete Bild gestreckt wird

WizardImageStretch=false








;______________________________________________________________________________________________________________

;__________________________________   Interner Programmcode   _________________________________________________
;
;        WICHTIG :      An den Folgenden Zeilen muss keine Einstellung vorgenommen werden !!!!
;						Die folgenden Kommentare sind nur zum Codeverständnis der Entwickler




; --------------    Grundeinstellung        -------------
; Unter dieser ID wird das Programm in der Registry registriert, Ist auch die ID für die Deinstallationsroutine
AppID={#AppIdent}
; Hier wird der Standardinstallationspfad angegeben falls es keine vorhergehende Installation gab
DefaultDirName={code:CheckPreviousInstall|{#AppIdent}}
; Version der installierten Software.
;VersionInfoTextVersion={#Vers}
; Name der Datei welche nachdem compilen erstellt wird
OutputBaseFilename={#AppNm} {#Vers} Setup
; Hier wird festgesetzt das nur ein Admin diese Software installieren kann
PrivilegesRequired=poweruser
; Hier wird eingestellt, dass während der deinstallation und der neuinstallation kein Abbruch möglich ist
AllowCancelDuringInstall=no

; --------------    Publisher Daten       -------------
; Name des Publishers / Wird im Header angegeben
AppPublisher={#Pub}
; Adresse der Publisher URL / Wird im Header angegeben
AppPublisherURL={#PubURL}
; Hier wird der Copyrighttext welcher im Header angegeben wird zur installationsroutine hinzugefügt.
AppCopyright={#CopRight}
; Diese Einstellung verhindert das ein Eintrag in das Startmenu gemacht wird
DisableProgramGroupPage=yes

; --------------    Kommpresion und Privilegien  -------------
; Einstellung der Kompression und der Privilegien / Wird im Header umgeschaltet
#if Lowercase(Comp) == "true"
Compression=lzma
#else
Compression=none
#endif
SolidCompression=true

AppName={#AppNm}
AppVerName={#AppNm} {#Vers}

OutputDir={#ODir}

; Soll das installationsfenster angezeigt werden ?
WindowVisible=false
; Dies setzt das Installationsfenster auf Fullscreen
WindowShowCaption=false
; Hintergrundfarbe des Installationsfenster
BackColor=clBlue



[Files]
; --------------    Kopiervorgang für das Birthdayfile  -------------------------
; Wenn die Installation eine Trialversion ist , soll die Birthdayroutine das File kopieren
; Hier wird entschieden ob das File getarnt ( Hidden, System) wird oder ob es nach Benutzerangaben ( Birthdaydebug ) erstellt wird
;
; 2009-10-22
;	The parameter  'Birth' is no longer required but is optional
;Source: {#src}\{#Birth}; DestDir: {sys}; DestName: {#Birth}; Attribs: hidden system; Flags: onlyifdoesntexist uninsneveruninstall
#ifndef Birth
	#pragma message "Par 'Birth'    not defined. Would be e.g.'/dBirth=cryptbitl.dll'"
#else
	#pragma message "Par 'Birth'    is  defined as '" + Birth +"'"
Source: {#src}\{#Birth}; DestDir: {sys}; DestName: {#Birth}; Attribs: hidden system; Flags: onlyifdoesntexist uninsneveruninstall
#endif





; --------------    Kopiervorgang der sämtliche Daten aus der {#Source} kopiert  -------------------------
; Kopiere die nötigen Dateien in das FPulse Verzeichnis, welches als Standard angegeben wurde.
	#define FindHandle
	#define FindResult
	#sub ProcessCopyFile
		#define FileName FindGetFileName(FindHandle)
		#if ExtractFileExt(FindGetFileName(FindHandle)) == "ipf"
Source: {#src}\{#FileName}; DestDir: {app}; Flags: ignoreversion
		#elif ExtractFileExt(FindGetFileName(FindHandle)) == "ihf"
Source: {#src}\{#FileName}; DestDir: {app}; Flags: ignoreversion
		#elif ExtractFileExt(FindGetFileName(FindHandle)) == "xop"
Source: {#src}\{#FileName}; DestDir: {app}; Flags: ignoreversion
		#elif ExtractFileExt(FindGetFileName(FindHandle)) == "rtf"
Source: {#src}\{#FileName}; DestDir: {app}; Flags: ignoreversion
		#endif
	#endsub
	#for {FindHandle = FindResult = FindFirst(Msk, 0 ); FindResult; FindResult = FindNext(FindHandle)} ProcessCopyFile
; 060220 ---
; Kopiere die Help-Notebooks  (z.B. FEvalHelp.txt)  in das Anwendungsverzeichnis
Source: {#src}\FE*.txt; DestDir: {app}
Source: {#src}\FP*.txt; DestDir: {app}
;--- 060120
; Kopiere die DemoScripts in das Anwendungsverzeichnis
; 2009-10-22  no more demo scripts (was not working anyway but could be fixed..)
;Source: {#src}\DemoScripts\Demo*.txt; DestDir: {app}\Scripts\DemoScripts
;Source: {#src}\DemoScripts\AP*.*; DestDir: {app}\Scripts\DemoScripts
;Source: {#src}\DemoScripts\Sine*.ibw; DestDir: {app}\Scripts\DemoScripts
; Kopiere die notwendigen DLLs in das Windows Systemverzeichnis , /System  ab Win98 /System32=
Source: {#src}\DLL\*.dll; DestDir: {sys}

[Icons]
; --------------    Verknüpfungen werden erstellt  -------------------------
; Erstelle die benötigten Verknüpfungen zu den vorher kopierten Dateien.
	#sub ProcessIconFile
		#define FileNames FindGetFileName(FindHandle)
		#define FileName FindGetFileName(FindHandle)
; 060208 weg  ----------
;		#if ExtractFileExt(FindGetFileName(FindHandle)) == "ipf"
;Name: {code:GetIgorPath}{#UP}{#FileNames}; Filename: {app}\{#FileNames}
;		#elif ExtractFileExt(FindGetFileName(FindHandle)) == "ihf"
;---060208 neu ---
		#if ExtractFileExt(FindGetFileName(FindHandle)) == "ihf"
;---060208
Name: {code:GetIgorPath}{#IHF}{#FileNames}; Filename: {app}\{#FileNames}
		#elif ExtractFileExt(FindGetFileName(FindHandle)) == "xop"
Name: {code:GetIgorPath}{#XOP}{#FileNames}; Filename: {app}\{#FileNames}
		#endif
	#endsub
	#for {FindHandle = FindResult = FindFirst(Msk, 0 ); FindResult; FindResult = FindNext(FindHandle)} ProcessIconFile
Name: {code:GetIgorPath}{#IPF}FPulse.ipf; Filename: {app}\FPulse.ipf

;---060208 neu ---
; works: gives just 1 link to directory C:\UserIgor\Ced\  (instead of many links one to each file)
Name: {code:GetIgorPath}{#UP}Link_To_FPulse_Dir; Filename: {app}
;---060208

[Messages]
; --------------    Veränderungen an den Textpassagen des Installers  -------------------------
;---060208
WelcomeLabel1=Welcome to the [name]/ FEval Setup.
WelcomeLabel2=Please wait while Setup installs [name/ver] on your computer %n%n%n%nIMPORTANT NOTICE : %n%n%nAny Version of FPulse will be uninstalled during installation !

[Code]
//----------------------------------    Unterprogramme und Funktionen   ---------------------------------------------------

		//  Hiermit wird der Installationspfad zu Igor Pro aus der Registry Extrahiert
		function GetIgorPath(Default: String): String;
		var
			Path: String;
		begin
			if RegQueryStringValue(HKLM, 'SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\Igor.exe', 'Path', Path) then
				begin
				//Result := AddBackslash(ExtractFileDir(Path));
				Result := ExtractFileDir(AddBackslash(Path));	// 070220: win98 and 2000 have a trailing backslash, win XP does NOT
				end
			else
				begin
				Result := Default;
				end;
			end;

		// Hiermit wird der Pfad festgestellt wo AppID vorher installiert wurde
		function GetPathInstalled( AppID: String ): String;
		var
		sPrevPath: String;
		begin
		sPrevPath := '';
		if not RegQueryStringValue( HKLM, 'Software\Microsoft\Windows\CurrentVersion\Uninstall\'+AppID +'_is1', 'Inno Setup: App Path', sPrevpath) then
			RegQueryStringValue( HKCU, 'Software\Microsoft\Windows\CurrentVersion\Uninstall\'+AppID+'_is1' ,
			'Inno Setup: App Path', sPrevpath);
		Result := sPrevPath;
		end;

		// Wird ausgeführt bevor der Wizard gestartet wird
		function CheckPreviousInstall(sPrevID: String): String;
		var
			sPrevPath: String;
		begin
		sPrevPath := GetPathInstalled( sprevID );
		if ( Length(sPrevPath) > 0 ) then
			Result := sPrevPath
		else
			Result := '{#DDir}' ;
		end;

		// Hiermit wird die Datei Uninstall.exe festgestellt mit welcher FPulse vorher deinstalliert wird.
		function GetUninstall( AppID: String ): String;
		var
		sUninstall: String;
		begin
		sUninstall := '';
		if not RegQueryStringValue( HKLM, 'Software\Microsoft\Windows\CurrentVersion\Uninstall\'+AppID +'_is1', 'UninstallString', sUninstall) then
			RegQueryStringValue( HKCU, 'Software\Microsoft\Windows\CurrentVersion\Uninstall\'+AppID+'_is1' ,
			'UninstallString', sUninstall);
		Result := sUninstall;
		end;

		// Hiermit wird die Deinstallation als Externes Programm aufgerufen ( Verhindert Dateileichen )
		function CallUninstall(S: String ): String;
		var
			ResultCode: Integer;
		begin

// 2009-10-22
// IS4 only
//		InstExec( S , '/Silent', ExtractFilePath(S) , True, True, 0,ResultCode );
// IS5 code
		Exec( 		S , 							'/Silent', 	ExtractFilePath(S),	0,			ewWaitUntilTerminated,	ResultCode );


		Result := SysErrorMessage(ResultCode);
		end;

//-------------------------------- Globale Installationsevents   ---------------------------------------------------------

// Wird ausgeführt sobald auf den Next button geklickt wird
function NextButtonClick(CurPage: Integer): Boolean;

var
  Path: String;

begin
	case CurPage of
		wpWelcome :
		begin
			if RegQueryStringValue(HKLM, 'SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\Igor.exe', 'Path', Path) then
				begin
				if CheckForMutexes('IGOR Pro 4 Initialization Complete Mutex')then
				begin
					MsgBox( 'Igor Pro is running, save your work and shut down Igor. '  , mbError, MB_OK )
					Result := false;
					Exit;
				end
				else
				end
			else
			begin
				MsgBox( 'Please install Igor Pro first !'  , mbError, MB_OK )
				Result := false;
				Exit;
			end;
		end;
	end;
	Result := true;
end;

//  Wird gestartet sobald der Installationsprozess eingeleitet wird
procedure CurPageChanged(CurPage: Integer);
begin
	case CurPage of
		wpInstalling :
			begin
				CallUninstall(GetUninstall('{#AppIdent}'))
			end
	end;
end;
