//====================================================================================================================================
//	ProjectsInstallFP.ipf	070117
//		Allows installation of any FPulse development version found  in  'UserIgor:Archive_FP' .  
//		Release version are not installed this way. they are installed by extracting the EXE created by InnoSetup.
//		The deinstallation procedure required prior to installation is DeInstallFPulse()  [ in ProjectsReleaseFP.ipf ] 
//=====================================================================================================================================
//
//	THIS FILE IS FOR THE DEVELOPER ONLY.  IT IS NOT TO BE DISTRIBUTED TO THE USER !
//	This file and the link to this file and the link to the directory of this file (UserIgor:Commons) must always stay active.
//	They must never be removed,  neither by the deinstallation procedure nor by the release procedure. 
// 	This does not lead to linker errors (function exists already) when User releases are installed because the User Commons function are auto-renamed to avoid naming conficts
//
// Possible improvement:  rename links  e.g. '.lnk'  ->  '.lnn'    rather than  deleting and recreating them ???


#pragma rtGlobals=1							// Use modern global access method.

#include "UFCom_ReleaseComments"			// for all UFCom_Xxx

//=====================================================================================================================================
//	Switch  FPulse / FEval Version
//
//	DeInstallFPulse()  and  InstallFPulse()  are companions!
// 	Cave 1:  All these file and dir constants must be the same in    ProjectsRelease.ipf     and in    ProjectsInstallFP.ipf   and in   UFPE_PulseConstants.ipf
// 	Cave 2:  Will only work if the link file names are supplied by InstallFPulse().  Any other link file names as supplied by  TotalCommander or  Windows must be renamed to this convention or deleted.
// 	Cave 3:  Will only work if these constants are the same in  Projects.ipf / ProjectsInstall.ipf / UF_Release.ipf   ( and  FPulseCed.c )

static constant		FALSE = 0, TRUE = 1,  OFF = 0,  ON = 1, kOK = 0

// copied from UFPE_PulseConstants.ipf
static strconstant	ksMY_DRIVE				= "C:"								// where my sources are , ................	must be the  SAME  as ksSCRIPTS_DRIVE
//static strconstant	ksDIR_CEDCOM			= "CedCommons"
static strconstant	ksDIR_CEDCOM			= "CommonsFpFe"
static strconstant	ksUSERIGOR_CED			= "Link2Dir_"							// Base name (FPulse or FEval will be appended!) of link of working directory (the specific IPFs) in 'User procedures' .  
																			// If this base name is changed the existing link must be renamed accordingly for the (De)Installation to work properly!
static strconstant	ksUSERIGOR_DIR			= "UserIgor"							// base directory for all  (e.g. FPulse or FEval)

static strconstant	ksIGORPROC_LNK			= ":Igor Procedures"
static strconstant	ksUSERPROC_LNK			= ":User Procedures"
static strconstant	ksHELP_LNK				= ":Igor Help Files"
static strconstant	ksXOP_LNK				= ":Igor Extensions"

static strconstant	ksUSER_FILES				= "UF*.ipf;F*.ipf;*.ihf;*.xop;*.txt;*.rtf"			// List of file groups to be distributed to the user. Avoid distributing 'Projectxxx.ipf'
static strconstant	ksDLL_DIR				= ":Dll"								// do not change to ensure compatibility

static strconstant	ksHELP_FILES				= "F*.ihf;"								// is LIST, can have more items e.g. FP*.ihf;Ced*.ihf"

static strconstant	ksXOP_SOURCE_FILES		= "*.c;*.h;*.hpp;*.rc;*.dsp;*.dsw;*.bmp;"
static strconstant	ksXOP_DELETE_FILES		= "*.ilk;*.opt;*.plg;*.exp;*.idb;*.obj;*.pch;*.res;"	// unnecessary temporary files created during compiling and linking
static strconstant	ksXOP_LIB_FILES			= "*.lib;"								//1. include for backup to be self-contained  2. deleted only in subdirectories /Debug and /Release



//  XOP PROCESSING : Neither the names nor the number of Xops have to be listed here.   ALL  Xops in a subdirectory are processed.

static strconstant	ksXOP_DIR				= "UserIgor:Xops"						// ....  are  backed up and compiled ,  but  C_Common  is only backed up but not compiled separately
static strconstant	ksXOP_SUBDIR_			= "Debugs:"							// ....  are  backed up and compiled ,  but  C_Common  is only backed up but not compiled separately

strconstant		ksXOPSEP				= "^"									// separates the above prefixes

 constant			kRLXP_COPY = 0,   kRLXP_RENAME = 1,   kRLXP_COMPILE = 2,   kRLXP_CREATELINK = 3,   kRLXP_REMOVELINK = 4,   kRLXP_DELETE = 5    
static strconstant	ksRLXP_NAMES = "Copy;Rename;Compile;Create link;Remove link;Delete;"

//=====================================================================================================================================
//	 Switch  FPulse / FEval Version :  DIRECTORY NAMING CONVENTIONS
//=====================================================================================================================================

Function	/S	DllDrvDir()
	string  	sAppNm
	return	ksMY_DRIVE + ksUSERIGOR_DIR+  ":Dll" 		// e.g. 'C:UserIgor'
End

Function	/S	SourcesDrvDir( sAppNm )		
	string  	sAppNm									// return my working directory  e.g. 'C:UserIgor:FPulse_'  or  'C:UserIgor:FEval_'
	return	ksMY_DRIVE + SourcesDir( sAppNm )	
End
		
Function	/S	SourcesDir( sAppNm )		
// Cave : must be the  SAME  here in  SourcesDir()/ProjectsInstall.ipf  in  UFP_Ced.c 
	string  	sAppNm									// return my working directory  e.g. 'UserIgor:FPulse_'  or  'UserIgor:FEval_'
	return	ksUSERIGOR_DIR  + ":" + sAppNm + "_"	 		// !!!  requires  '_.lnk'  at some places...   
End
		
Function	/S	InstallDir( sAppNm )		
	string  	sAppNm									// return directory where InnoSetup will  unpack and install   FPulse or FEval on the user's hard disk
	return	ksUSERIGOR_DIR + ":" + sAppNm				// e.g. 'UserIgor:FPulse'  or  'UserIgor:FEval'
End
		
Function	/S	ReleaseOutDir( sAppNm )		
	string  	sAppNm									// return directory where InnoSetup finds all filles to be distributed to the user
	return	ksUSERIGOR_DIR + ":" + sAppNm + "_Out"		// e.g. 'UserIgor:FPulseOut'  or  'UserIgor:FEvalOut'
End
		
Function	/S	ReleaseExeDir( sAppNm )		
	string  	sAppNm									// return directory where InnoSetup puts  'FEval xxx Setup.exe'  on my hard disk
	return	ksUSERIGOR_DIR + ":" + sAppNm + "_SetupExe"	// e.g. 'UserIgor:FPulse_SetupExe'  or  'UserIgor:FEval_SetupExe'
End
		
Function	/S	ArchiveBaseDrvDir( sAppNm )
	string  	sAppNm												// where the backups of the current version (before releasing switching)   are saved
	return	ksMY_DRIVE + ksUSERIGOR_DIR + ":" + sAppNm + "_Archive"	// e.g. 'C:UserIgor:FPulse_Archive'  or   'C:UserIgor:FEval'_Archive
End

Function	/S	ArchiveDrvDir( sAppNm, sVersion )
// For every version create an  ARCHIVE  subdirectory  e.g. 'C:UserIgor:FPulse_Archive:FPulse040315_1200v235'  for the  Igor and  C  source  files  where the backups of the current version (before releasing switching)   are saved
	string  	sAppNm, sVersion
	string 	sDateTime		= Secs2Date( DateTime, -1 ) 
	string 	sDate		= sDateTime[ 8,9 ] + sDateTime[ 3,4 ] + sDateTime[ 0,1 ] 
	string	  	sHoursMins	= Secs2Time( DateTime, 2 )
	string  	sTime		= "_"+ sHoursMins[ 0, 1 ] + sHoursMins[ 3, 4 ] 				// e.g.   '_1307'   <-   '13:07' 
	return	ArchiveBaseDrvDir( sAppNm ) + ":" + sAppNm + sDate + sTime  + "v" + sVersion	// e.g. 'C:UserIgor:ArchiveFPulse:FPulse070315_1200v400'
End



//=====================================================================================================================================
//	 Switch  FPulse / FEval Version :  BACKUP
//=====================================================================================================================================

Function	/S	BackupWorkingDir( sAppNm, sVersion, sArchiveDir, sSourcesDrvDir )
	string  	sAppNm, sVersion
	string  	sArchiveDir
	string  	sSourcesDrvDir															// e.g. 'C:UserIgor:FPulse_'
	string  	lstUserFiles	= ksUSER_FILES
	string  	sCedComSrcDir	= ksMY_DRIVE + ksUSERIGOR_DIR + ":" + ksDIR_CEDCOM	// e.g  'C:UserIgor:CommonsFpFe'									// e.g. 'C:UserIgor:CommonsFpFe'
	string  	sComSrcDir	= ksMY_DRIVE + ksUSERIGOR_DIR + ":" + UFCom_ksDIR_COMMONS	// e.g. 'C:UserIgor:Commons'
	string  	sArchiveSubDir

	// For every version create an  ARCHIVE  subdirectory    e.g.  "C:UseIgor:Archive:Ced040315_1200V235"    for the  Igor  [...no...and  C]  source  files  on the hard disk and copy files into it.
	// Small  'v'  indicates  that this is a backup created when switching versions or when the user executed 'Backup' 
	UFCom_PossiblyCreatePath( sArchiveDir )											// Create  directory	e.g.	"C:UseIgor:Ced040315V235" 

	// Copy  FPulse_  or  FEval_  files  from  development directory  into a separate Archive directory
	UFCom_PossiblyCreatePath( sArchiveDir )											// Create  directory	e.g.	'C:UserIgor:SecuTest040315V235:FPulse_" 
	//UFCom_CopyFilesFromList( sCedFPFESrcDir,  "*.ipf;" , sArchiveDir )						// Copy the current User files ( only  ipf ) into  the archive
	UFCom_CopyFilesFromList( sSourcesDrvDir, lstUserFiles,	sArchiveDir )					// Copy the current User files (e.g. ipf, ihf, xop..) into the archive

	// Copy CedCommon files  from  'UserIgor:CommonsFpFe' development directory into separate Archive-CommonsFpFe subdirectory
	sArchiveSubDir	= sArchiveDir + ":" + ksDIR_CEDCOM	 						// e.g. 'C:UserIgor:SecuTest040315V235:CommonsFpFe'	 	
	UFCom_PossiblyCreatePath( sArchiveSubDir )										// Create  directory	e.g.	'C:UserIgor:SecuTest040315V235:CommonsFpFe" 
	UFCom_CopyFilesFromList( sCedComSrcDir,  "*.ipf;" , sArchiveSubDir )						// Copy the current User files ( only  ipf ) into the archive

	// Copy Common files  from  'UserIgor:Commons' development directory into separate Archive-Commons subdirectory
	sArchiveSubDir	= sArchiveDir + ":" + UFCom_ksDIR_COMMONS			 				// e.g. 'C:UserIgor:SecuTest040315V235:Commons'	 	
	UFCom_PossiblyCreatePath( sArchiveSubDir )										// Create  directory	e.g.	'C:UserIgor:SecuTest040315V235:Commons" 
	UFCom_CopyFilesFromList( sComSrcDir,  "*.ipf;" , sArchiveSubDir )						// Copy the current User files ( only  ipf ) into the archive

	return	sArchiveDir														// e.g. 'C:UserIgor:SecuTest040315V235'	
End


Function	/S	BackupAllTheRest( sAppNm, sVersion, sArchiveDir, sSourcesDrvDir )
// Copy  ALL files from development directory into archive
	string  	sAppNm, sVersion, sArchiveDir, sSourcesDrvDir 
	string  	lstMatch		= "*.iss;*.bmp;"//"*.*"
	UFCom_CopyFilesFromList( sSourcesDrvDir, "*.*", sArchiveDir )							// Copy the current User files (e.g. ipf, ihf, xop..) into it
	string  	lstCopied		= UFCom_ListOfMatchingFiles( sArchiveDir, lstMatch, UFCom_FALSE )	// False: don't use IgorPath
	printf  "\tBackupRest()  \tBacking up '%s' Version %s   (%d files, %s)   from  '%s'   to  '%s'     [ %s.....]\r", sAppNm, sVersion,  ItemsInList( lstCopied ), lstMatch, sSourcesDrvDir, sArchiveDir,  lstCopied[0,100]
End


//=====================================================================================================================================
//	 Switch  FPulse / FEval Version :  DEINSTALLATION
//=====================================================================================================================================

Function		DeInstallFPFE( sAppNm, sVersion, sArchiveDir, lstlstPrefixesDelLink, sSourcesDrvDir, lstlstPrefixesCopy )
	string  	sAppNm, sVersion, sArchiveDir, lstlstPrefixesDelLink, sSourcesDrvDir, lstlstPrefixesCopy

	string  	lstHelpFiles	= ksHELP_FILES
	string  	lstUserFiles	= ksUSER_FILES
	string  	sReleaseOutDir	= ReleaseOutDir( sAppNm )				// e.g. 'UserIgor:FPulseOut'
	BackupWorkingDir( sAppNm, sVersion, sArchiveDir, sSourcesDrvDir )
	ProcessXOPs( kRLXP_COPY, ksXOP_DIR, ksXOP_SUBDIR_, lstlstPrefixesCopy, ksXOPSEP,  sArchiveDir, sReleaseOutDir ) 
	BackupAllTheRest( sAppNm, sVersion, sArchiveDir, sSourcesDrvDir )

	// Delete all links.  This is required before the file deletion can take place ( after restarting Igor ) .
	// Cave / Flaw / Todo  : does not recognise renamed links  e.g.  'Verknüpfung mit.....'
	UFCom_DeleteLinks( ksIGORPROC_LNK, 	sAppNm + ".ipf"			+ ".lnk" )	// 'FPulse.ipf'  or  'FEval.ipf'
	UFCom_DeleteLinksFromList(   ksHELP_LNK, 	lstHelpFiles			, ".lnk" )	// '.lnk' is a separate parameter as an extension can only be appended to links, not to a list 	

	ProcessXOPs( kRLXP_REMOVELINK, ksXOP_DIR, ksXOP_SUBDIR_, lstlstPrefixesDelLink, ksXOPSEP, "" , sReleaseOutDir) 

	UFCom_DeleteLinks( ksUSERPROC_LNK,	ksUSERIGOR_CED+sAppNm+"_.lnk")	// link to directory  UserIgor:Eval_  or  UserIgor:FPulse_ 
	printf  "\tDeInstallFPFE() \tDeleting links for '%s'...\r", sAppNm

	DoAlert 0,  "You must  quit and restart Igor and then execute : \rfor development 'Install"+sAppNm+"'  -> 'Install "+sAppNm+" any version'  \ror for Release any '"+sAppNm+" nnn Setup.exe' (from InnoSetup)"
End


//=====================================================================================================================================
//	 Switch  FPulse / FEval Version :  INSTALLATION 
//=====================================================================================================================================

Function		InstallFPFE( sAppNm, sSourcesDrvDir, lstDllFiles, lstlstPrefixes_OrgRen )
// Installs any FPulse version found in   C:UserIgor:Archive .   Will not and should not be used to install  InnoSetup-Release version.  Use  InnoSetup for this purpose (after deinstalling the development version)
// Requirement:  Any links from  the previous FPulse version must already have been deleted : This is done in 'Projects'  -> 'DeInstall FPulse'   and Igor must have been restarted.
// Only if those conditions are fulfilled we can delete all files in the development directory (and copy the new ones)
// ToThink: Should the 3 C_xxx directories also be copied?  They contain about 20MB data which are changed very seldomly so at the moment they are just kept.....

	string  	sAppNm, sSourcesDrvDir, lstDllFiles, lstlstPrefixes_OrgRen  

	string  	lstHelpFiles		= ksHELP_FILES

	// Check that all links have been deleted.  Will recognise only 'non-renamed' links, will fail with renamed links!
//must be unique to FPulse/Feval	string  	sIgorProc_Projects_Link	= ksIGORPROC_LNK + ":" + "Projects.ipf" 	+ ".lnk"
	string  	sIgorProc_AppName_Link	= ksIGORPROC_LNK  + ":" + sAppNm + ".ipf" + ".lnk"  
	string  	sUserProc_AppDir_Link	= ksUSERPROC_LNK + ":" + ksUSERIGOR_CED+sAppNm + "_.lnk"
	variable	bLinkExists	= UFCom_FileExistsIgorPath( sIgorProc_AppName_Link )  ||  UFCom_FileExistsIgorPath( sUserProc_AppDir_Link ) 
	if ( bLinkExists ) 
		DoAlert 0 , "There are still links [  " + sUserProc_AppDir_Link +  "  or  " + sIgorProc_AppName_Link +  "]  which prevent installation. \rFor removing Development version: 'Projects'  > 'DeInstall "+sAppNm+"' \rFor Release: 'Systemsteuerung' >'Software' > 'Remove "+sAppNm+" Vxx' "
		return 0
	endif
	
	// Get  a list of previous versions for the user to choose from
	string  	lstDirs=  UFCom_ListOfMatchingDirs( ArchiveBaseDrvDir( sAppNm ), "*", FALSE )	// *.* : list all dirs ,  False: supply only partial path
	lstDirs		= SortList( lstDirs )
	variable	nDir	= ItemsInList( lstDirs )													// offer the most recent directory (Prompt is one-based)
	Prompt	nDir, "Select directory / version: ", popup lstDirs		
	DoPrompt	"Switch  " + sAppNm + " version", nDir
	if ( V_Flag )
		return	0																// user cancelled
	endif
	string  	sRestoreDir	= StringFromList( nDir-1, lstDirs )

//	// Version 1 : Copy the required DLLs into the Windows directory  or  into  the Windows System directory.
//	//  When switching between archive versions this is not required but after a TRUE-Release-InnoSetup version has been installed then the InnoSetup deinstallation unfortunately removes the DLLs from the system directory
//	//  Elaborate code taken from 'Install.ipf'  :  Here we copy  the DLLs into the same directory as where InnoSetup puts them: into the Windows System directory.
//	string  	sLastDrive			=  LastRWDrive( sFirstDrive )
//	string  	sWindowsDLLDrive	= SearchDirInDrives( "C:", sLastDrive, ksWINDOWS_DLL_DIR ) 	// Look for a drive within the given range that contains the Win98  system directory, usually   \Windows\System32 
//	string  	sWinNTDLLDrive	= SearchDirInDrives( "C:", sLastDrive, ksWINNT_DLL_DIR ) 	// Look for a drive within the given range that contains the Win2000/XP system directory, usually   \WinNT\System32 
//
//	// Copy  Ced1401 libraries	 and   clear the Read-only attribute which is set when installing from a CD-ROM drive.
//	if ( strlen( sWindowsDLLDrive ) )			// found a directory System32 on a  Win98 machine 
//		CopyFilesFromList( sPrgSourceDrive + ksFP_RELEASE_OUT_DIR + ksDLL_DIR, ksFP_DLL_FILES, sWindowsDLLDrive + ksWINDOWS_DLL_DIR, kKEEPTIME, kCLR_READONLY )	// e.g. 'C:UserIgor:Ced:Cfs32.dll, 1432ui.dll, Use1432.dll' -> C:Windows:System32 
//	endif
//	if ( strlen( sWinNTDLLDrive ) )			// found a directory System32 on a  Win2000 or XP  machine 
//		CopyFilesFromList( sPrgSourceDrive + ksFP_RELEASE_OUT_DIR + ksDLL_DIR, ksFP_DLL_FILES, sWinNTDLLDrive + ksWINNT_DLL_DIR, kKEEPTIME, kCLR_READONLY )		// e.g. 'C:UserIgor:Ced:Cfs32.dll, 1432ui.dll, Use1432.dll' -> C:WinNT:System32 
//	endif

	// Version 2: Copy the required DLLs into the Windows directory  or  into  the Windows System directory.
	//  Problem: After a TRUE-Release-InnoSetup version has been installed then the InnoSetup deinstallation unfortunately removes the DLLs from the system directory.
	//  Simple solution:   To avoid any conflicts WE copy  the DLLs into the Windows directory  whereas InnoSetup puts them into the Windows System directory.  Drawback: the 4 DLLs are possibly stored twice...
	// Bad code.....
	//.. better solution: (as long as there is no such Igor function) : Use UFCom_UtilGetSystemDirectory(), but for this to work  there must be a permanent XOP 'MYUFCom_Utils.xop' only on MY computer containing this function which means splitting FPulseCed.xop.........
	string  	sWindowsPath = ""
	if ( 	UFCom_SearchDir(   	  "C:WinNT:System32" ) )
		sWindowsPath = "C:WinNT" 
	elseif ( UFCom_SearchDir( 	  "D:WinNT:System32" ) )	
		sWindowsPath = "D:WinNT" 
	elseif ( UFCom_SearchDir(    "C:Windows:System32" ) )
		sWindowsPath = "C:Windows" 
	elseif ( UFCom_SearchDir( 	  "D:Windows:System32" ) )	
		sWindowsPath = "D:Windows" 
	endif


	if ( ! UFCom_FileExists( sWindowsPath + ":" + StringFromList( 0, lstDllFiles ) ) )
		UFCom_CopyFilesFromList( ArchiveBaseDrvDir( sAppNm ) + ":" + sRestoreDir, lstDllFiles, sWindowsPath )	// e.g. 'C:UserIgor:Ced:Cfs32.dll, 1432ui.dll, Use1432.dll' -> D:WinNT 
	endif


	// Delete all files in development directory
	UFCom_DeleteFiles( sSourcesDrvDir, "*.*" )			

	// Copy  files from selected archive into development directory
	UFCom_CopyFilesFromList( ArchiveBaseDrvDir( sAppNm ) + ":" + sRestoreDir , 	 "*.*", sSourcesDrvDir )	// Copy the current User files (e.g. ipf, ihf, xop..) into it

	// Recreate the links
	UFCom_CreateLinks( "C:UserIgor:Commons", 	   "Projects.ipf", 		ksIGORPROC_LNK )
	UFCom_CreateLinks( sSourcesDrvDir,		   sAppNm + ".ipf", 	ksIGORPROC_LNK )
	UFCom_CreateLinksFromList( sSourcesDrvDir,  lstHelpFiles, 		ksHELP_LNK )					// 

	string  	sReleaseOutDir	= ReleaseOutDir( sAppNm )					// e.g. 'UserIgor:FPulseOut'
	ProcessXOPs( kRLXP_CREATELINK, ksXOP_DIR, ksXOP_SUBDIR_, lstlstPrefixes_OrgRen, ksXOPSEP, "", sReleaseOutDir ) 

	UFCom_CreateAlias( sSourcesDrvDir, ksUSERPROC_LNK + ":" + ksUSERIGOR_CED+sAppNm + "_.lnk" )	// is link to directory  , but could perhaps also use  CreateLinks()...

	string  	sVersion	= sRestoreDir[ strsearch( sRestoreDir, "V", 0 ) + 1, inf ]
	DoAlert 0,  "You must  quit and restart Igor now to activate  " + sAppNm + "V"  + sVersion + " . "
End


//=====================================================================================================================================
//	 Switch  FPulse / FEval Version :  RELEASING
//=====================================================================================================================================

 Function		ProjectRelease( days, sAppNm, sVersion, lstlstPrefixes_OrgRen, sDllDrvDir, sSourcesDrvDir, sExeDir, sReleaseOutDir, sInstallDir, sScriptDir, sDemoScriptDir, lstDemoScripts, lstDllFiles )
// ProjectRelease() must be executed by the programmer when a new  FPulse  version  is to be released

// TOTEST
// 070218 0 days = unlimited used to mean : build birthday file but allow 20 years or similar.   // 0 days now means: build no birthday file at all

	variable	days											// trial time, 0 means  unlimited version  
	string  	sAppNm, sVersion, lstlstPrefixes_OrgRen
	string  	sDllDrvDir										// e.g. 'C:UserIgor:Dll'
	string  	sSourcesDrvDir, sExeDir, sReleaseOutDir, sInstallDir, sScriptDir, sDemoScriptDir, lstDemoScripts, lstDllFiles 

	string  	lstUserFiles		= ksUSER_FILES
	string  	sXopSourceDir		= ksXOP_DIR
	string  	sXopSourceSubDir_	= ksXOP_SUBDIR_
	string  	sSep				= "^"

	DoAlert 0, "Make sure that the following compilation steps give no errors. \rCheck the DOS boxes which will be created. " 

	//  STEP 2 : For every version create an  ARCHIVE  subdirectory    e.g.  "C:UseIgor:Ced040315V235"    for the  Igor  and  C  source  files  on the hard disk and copy files into it.
	variable	nVersion			= str2num( sVersion ) 

	string  	sArchiveDir		= ArchiveDrvDir( sAppNm, sVersion )
	printf  "----- %s - Release() -----  will  build  release version %s  ( %s , %s ) \r", sAppNm, sVersion, Date(), Time()
	printf  "\tCreating directory '%s'  and copying files %s \r", sArchiveDir, lstUserFiles

	BackupWorkingDir( sAppNm, sVersion, sArchiveDir, sSourcesDrvDir )
	ProcessXOPs( kRLXP_COPY, ksXOP_DIR, ksXOP_SUBDIR_, lstlstPrefixes_OrgRen, ksXOPSEP,  sArchiveDir, sReleaseOutDir ) // copies the XOP sources into the newly created archive subdirectory e.g. into '...Archive...:UFCom_Utils'
	// Do NOT 'BackupAllTheRest()' here as this would distribute files to the user which are not meant for him e.g. *.iss, *.bmp
	
	string  	sArchiveCommDir	= sArchiveDir + ":" + UFCom_ksDIR_COMMONS 	// has already been created and filled by BackupWorkingDir() ,  e.g. 'C:UserIgor:SecuTest040315V235:Commons'	 	
	string  	sArchiveCedComDir	= sArchiveDir + ":" + ksDIR_CEDCOM	 		// has already been created and filled by BackupWorkingDir() ,  e.g. 'C:UserIgor:SecuTest040315V235:CommonsFpFe'	 	

	// Copy specific application files from specific development directory into archive
	//UFCom_CopyFilesFromList( sSrcDir, lstUserFiles, sArchiveDir )					// Copy the current User files (e.g. ipf, ihf, xop..) into it
	UFCom_CopyFilesFromList( sDllDrvDir, lstDllFiles, 	sArchiveDir )					// Copy the 4 DLLs from 'C:UserIgor:Ced'  into the  Archive-Release directory 

  	string  	sInstalledPrgChkFile	= sArchiveDir + ":" + sAppNm + ".ipf"				// it is sufficient for only 1 file (e.g. 'FPulse.ipf' or 'FEval.ipf') to loose its  true time...
	UFCom_ModifyFileTime( sInstalledPrgChkFile, nVersion, UFCom_FALSE )			// ...the hour:minute will be the version


	//  STEP 3 : Create  the  RELEASE / INSTALLATION  directory  e.g. 'FPulseOut'  or  'FEvalOut'  from which Inno-Setup takes the files to build  'FPulse / FEval xxx Setup.exe'  which is distributed to the user. 
	//  We need an extra (temporary) directory as 1. InnoSetup cannot access 'This' (currently executing) file in the working dir  and as  2.  UF_Test.ipf  must be replaced by  a  wrapper file   
	// Copy from the newly created archive to the release HD directory (or to a CD-Rom)
	string  	sTmpDrive 	= ksMY_DRIVE
	string  	sOutDir		= sTmpDrive + sReleaseOutDir
	printf  "\tCreating temporary directory  '%s'  and copying files  %s  .  InnoSetup will get its files from there. \r", sOutDir, lstUserFiles

	// First clean the temporary folder
	DeleteFolder  /Z  sOutDir												// Clean the directory e.g. 'C:UserIgor:FPulseOut' .  THIS ALSO REMOVES SUBDIRECTORIES e.g. DLL. DemoScripts (which is desired)
	if ( V_Flag )
		printf "Error: Could not DeleteFolder\tTo enable DeleteFolder, open the Miscellaneous Settings Dialog's Misc category \rand check the 'Enable DeleteFolder, CopyFolder/O and MoveFolder/O  commands'  checkbox.\r"
	endif
	UFCom_PossiblyCreatePath( sOutDir )										// Create  directory	e.g.	 'C:UserIgor:FPulseOut'	 


	// Complile   the XOPS in the RELEASE mode and copy then into the release Dir (this overwrites DEBUG XOPS which have been unnecessarily (in lstUserFiles!) copied there a moment ago)
	// Compiling the XOP  automatically per command  ensures that  the  XOP distributed to the user is compiled in  RELEASE  mode 
	ProcessXOPs( kRLXP_DELETE,  sXopSourceDir, sXopSourceSubDir_, lstlstPrefixes_OrgRen, sSep, "", sReleaseOutDir ) // Delete the archive subdirectory containing the XOP sources e.g.  'C:UserIgor:Xops:UFe1_Utils'  or  'C:UserIgor:Xops:UFp2_Cfs'  
	ProcessXOPs( kRLXP_RENAME, sXopSourceDir, sXopSourceSubDir_, lstlstPrefixes_OrgRen, sSep, "", sReleaseOutDir ) // Copy and rename the 'Common' sources from e.g. 'C:UserIgor:Xops:UFPE_Cfs:'  into  'C:UserIgor:Xops:UFp2_Cfs:'  
	ProcessXOPs( kRLXP_COMPILE, sXopSourceDir, sXopSourceSubDir_, lstlstPrefixes_OrgRen, sSep, "", sReleaseOutDir ) // Compile ALWAYS in RELEASE mode and copy the xop into e.g. 'C:UserIgor:FPulseOut'


	// Process specific application files ( e.g.  ipf, ihf, xop, txt  from   UserIgor:FPulse_ )
	UFCom_CopyFilesFromList(    sArchiveDir, 		lstUserFiles, sOutDir )					// Copy the current User files (e.g. ipf, xop..)  from the msin archive folder into the one-and-only release output dir. Do NOT copy .iss, .bmp
	UFCom_CopyFilesFromList(    sArchiveCedComDir, lstUserFiles, sOutDir )				// Copy the current User files (e.g. ipf, xop..)  from the  archive subfolder  into the one-and-only release output dir. Do NOT copy .iss, .bmp
	UFCom_CopyFilesFromList(    sArchiveCommDir, 	lstUserFiles, sOutDir )					// Copy the current User files (e.g. ipf, xop..)  from the  archive subfolder  into the one-and-only release output dir. Do NOT copy .iss, .bmp

	// Process Ced-Common files  from   'UserIgor:CommonsFpFe' . The User  will get  copies of  'Commons'  and  'Ced-Commons'  files for each  project in his project directory (no subdirectories).  
	// The file names and functions are renamed 
	UFCom_CopyStripComments_( sOutDir, "UF*.ipf" )								// Only copy and strip comments from files like UF*.ipf,  do NOT process any other files like 'FP*.ipf. Project*.ipf...

	variable	d, nDirs	= ItemsInList( lstlstPrefixes_OrgRen, sSep )
	for ( d = 0; d < nDirs; d += 1 )
		string  	lstDirPreFixes	= StringFromList( d,  lstlstPrefixes_OrgRen, sSep )			// e.g. 'UFPE_;UFp2_'
		string  	sDirPreFixOrg	= StringFromList( 0,  lstDirPrefixes )					// e.g. 'UFPE_'
		string  	sDirPreFixRenm	= StringFromList( 1,  lstDirPrefixes )					// e.g. 'UFp2_'   or  '' (empty )
		if ( strlen( sDirPreFixRenm ) )
			UFCom_ReplaceModuleNames_( sDirPreFixOrg,  sDirPreFixRenm, sOutDir, "*.ipf" ) // ...but once in the temporary directory we can rename ALL files and copy them to 'sOutDir' e.g. 'UserIgor:FPulseOut' 
		endif
	endfor

	// Process specific application files and  common files.
	UFCom_ModifyFileTimeFromList( sOutDir, lstUserFiles, nVersion, UFCom_FALSE )			// OK : ALL files in the temporary release dir loose their true time: the hour:minute will be the version  

// 070212??? weg
	// Process DLLs
	UFCom_PossiblyCreatePath( sOutDir + ksDLL_DIR  )								// Create  directory e.g. 'C:Userigor:FEvalOut:Dll' . Do  NOT clear it (has been done above) as clearing an empty subdir would clear the 'sOutDir'
	UFCom_CopyFilesFromList( sArchiveDir,	 lstDllFiles, sOutDir + ksDLL_DIR )			// Copy the 4 DLLs to the temporary dir

	// Process DemoScripts
	UFCom_PossiblyCreatePath( sOutDir + sDemoScriptDir  )							// Create  directory e.g. 'C:UI:FPulseOut:DemoScripts' . Do  NOT clear it (has been done above) as clearing an empty subdir would clear the 'sOutDir'
	UFCom_CopyFilesFromList( ksMY_DRIVE + sScriptDir, lstDemoScripts, sOutDir + sDemoScriptDir )	// Copy some DemoScripts

  	UFCom_DeleteFiles( sOutDir + sDemoScriptDir, lstDemoScripts )						// OK : ALL files in the release dir loose their true time: the hour:minute will be the version

	// Copy an empty wrapper file to the user release rather than the real files  in those cases where the real files are not to be distributed. Workaround as Igor does not allow conditional compilation.
	UFCom_Copy1File( sArchiveDir + ":" + "UF_Wrapper.ipf", sOutDir +  ":" + "UF_Test.ipf" )
	UFCom_DeleteFiles( sOutDir, "UF_Wrapper.ipf" )


// TOTEST
// 070218 0 days = unlimited used to mean : build birthday file but allow 20 years or similar.   // 0 days now means: build no birthday file at all
	string  	sBirthFile			= ""
	if ( days > 0  )
		// Create the trial time file and copy it to the release HD directory
		// 070215 Igor6 #define...   only FPulse release
		// UFP_CedUtilBdMake( days, sVersion, sOutDir )				// creates bd file e.g. 'cryptbdiml.dll'  which is required by InnoSetup if /dBirth is specified (as it is in FPulse, not in FEval)
		// should pass sAppNm.....
		UFBd_ProjectsBdMake( days, sVersion, sOutDir )					// creates bd file e.g. 'cryptbdiml.dll'  which is required by InnoSetup if /dBirth is specified (as it is in FPulse, not in FEval)
		sBirthFile			= BuildTTFileNm( sVersion ) 
	endif


	string  	sReleaseExeForUser	= ksMY_DRIVE + sExeDir  + ":" + sAppNm + " " + sVersion +  " Setup.exe"	// !!! must be same file path as InnoSetup constructs it
	string  	sSourcesDir		= SourcesDir( sAppNm )

	CallInno(  sVersion, ksMY_DRIVE, sSourcesDir, sAppNm, sReleaseOutDir, sExeDir, sInstallDir, sBirthFile )	// will build a 'Release' version no matter which version is defined in Igor

	string  	sLimit	= "trial version limited to " + num2str( days ) + " days"
	sLimit	= SelectString( days == 0 , sLimit,  "unlimited version" )
	printf "Finished :\tCreated source files archive \t'%s'  \r\t\tCreated release version \t\t'%s' , (%s) \r ", sArchiveDir, sReleaseExeForUser, sLimit

	// 070119
	// Last step:  Copy ALL files from development directory into archive.  This adds e.g.  ISS, BMP, RTF, TXT  which are  NOT to be distributed to the user.
	//  As these files change seldomly they are doubles in most archives.  For this reason  'UserIgor:FPulse_'  or  'UserIgor:FEval_'  should contain no junk but only a few important files.	
	BackupAllTheRest( sAppNm, sVersion, sArchiveDir, sSourcesDrvDir )		// Copy the current User files (e.g. ipf, ihf, xop..) into the archive
End


//==================================================================================================================
// 		 BIG  HELPERS
//==================================================================================================================

Function		ProcessXOPs( nAction, sSourceDir, sSourceSubDir_, lstlstPrefixes_OrgRen, sSep, sArchiveDir, sReleaseOutDir ) 
//  ALL XOP PROCESSING in 1 function: Neither the names nor the number of Xops have to be listed here.   ALL  Xops in a subdirectory are processed.
// Possible improvement: defining 'nAction' as a bit pattern would allow to execute multiple actions with 1 call...
	variable	nAction						// e.g. Copy  Rename  Compile  Create link  Remove link  Delete	
	string  	sSourceDir					// e.g. 'UserIgor:Xops'		
	string  	sSourceSubDir_					// e.g. 'Debug:'
	string  	lstlstPrefixes_OrgRen				// e.g. 'UFCom_;UFp1_^UFPE_;UFp2_^UFP_'	
	string  	sSep							// e.g. '^'
	string  	sArchiveDir					// e.g. 'C:UserIgor:ArchiveFPulse:FPulse070315_1200v401'
	string  	sReleaseOutDir					// e.g. 'UserIgor:FPulseOut'  or  'UserIgor:FEvalOut'
	string  	sText	= UFCom_pd( StringFromList( nAction, ksRLXP_NAMES ), 10 )		// e.g. 'Copy',   'Rename'  ...
	variable	d, nDirs	= ItemsInList( lstlstPrefixes_OrgRen, sSep )
	for ( d = 0; d < nDirs; d += 1 )
		string  	lstDirPreFixes	= StringFromList( d,  lstlstPrefixes_OrgRen, sSep )		// e.g. 'UFPE_;UFp2_'
		string  	sDirPreFixOrg	= StringFromList( 0,  lstDirPrefixes )					// e.g. 'UFPE_'
		string  	sDirPreFixRenm	= StringFromList( 1,  lstDirPrefixes )					// e.g. 'UFp2_'   or  '' (empty )
		string  	sDriveSrcDir	= ksMY_DRIVE + sSourceDir
		string 	lstDirs		= UFCom_ListOfMatchingDirs( sDriveSrcDir, sDirPreFixOrg + "*", 0 )		// e.g. 'UFP_Ced;UFP_Mc700'
		variable	n
		for ( n = 0; n < ItemsInList( lstDirs ); n +=1 )	
			string  	sDir	= StringFromList( n, lstDirs )									// e.g. 'UFP_Ced'  or  'UFP_Mc700'
			string  	sXopSrcDir	= sDriveSrcDir + ":" + sDir 							// e.g. 'C:UserIgor:Xops:UFP_Ced'  
			string  	sXopExePath	= sDriveSrcDir + ":" + sSourceSubDir_ +  sDir + ".xop"		// e.g. 'C:UserIgor:Xops:Debugs:UFP_Ced.xop'
			string  	sXopRenmDir	= SelectString( strlen( sDirPreFixRenm ) ,  "" , ReplaceString(  sDirPreFixOrg, sXopSrcDir, sDirPreFixRenm ) )
			string  	sInfo
			sprintf sInfo, "\tProcessXOPs(\t%s )\tDir:%d/%d\tn:%d\tDir: %s\tOrg:\t%s\tRen:\t%s\tSrcD:\t%s\tXop:\t%s\tRnD:\t%s\tArD:\t'%s' ", sText, d, nDirs, n, UFCom_pd(sDir,13),  UFCom_pd(sDirPreFixOrg,7),  UFCom_pd(sDirPreFixRenm,7),  UFCom_pd( sXopSrcDir,24),  UFCom_pd(sXopExePath, 36),  UFCom_pd(sXopRenmDir, 24), sArchiveDir
			printf "%s\r", sInfo[0,396]
			switch( nAction )
				case	kRLXP_COPY:
					string  sArchiveSubDir = sArchiveDir + ":" + sDir
					UFCom_PossiblyCreatePath( sArchiveSubDir )						// Create  subdirectory within archive	e.g.	'C:UseIgor:ArchiveFPulse:FPulse040315V235:UFCom_Utils'
					UFCom_CopyFilesFromList( sXopSrcDir, ksXOP_SOURCE_FILES + ksXOP_LIB_FILES, sArchiveSubDir )	// Copy the RELEASE XOP sources into the archive subdirectory 
					break
				case	kRLXP_RENAME:
					if ( strlen( sDirPreFixRenm ) )							// only common funstions must be renamed, specific application functions keep their name
						UFCom_ReplaceModuleNamesFromLst(  sDirPreFixOrg, sDirPreFixRenm, sXopSrcDir, sXopRenmDir, ksXOP_SOURCE_FILES ) 
						UFCom_CopyFilesFromList( sXopSrcDir, ksXOP_LIB_FILES, sXopRenmDir )	// Copy the library files (e.g. 'Cfs32.lib'  the renamed Xop sources subdirectory, as the compiler expects them there. We can NOT 'Rename' the library binary file! 
					endif
					break
				case	kRLXP_COMPILE:
					string  	sCompileDir	= SelectString( strlen( sDirPreFixRenm ) , sXopSrcDir, sXopRenmDir )
					CallXOPCompiler_( sCompileDir )
					UFCom_CopyFilesFromList( sCompileDir + ":Release", "*.xop", "C:" + sReleaseOutDir )// Copy the RELEASE XOP into the release Dir 
					break
				case kRLXP_CREATELINK:
					UFCom_CreateAlias( sXopExePath, 	 ksXOP_LNK + ":" + sDir + ".xop" + ".lnk" )		// We must keep the  '.xop'  in the link file name to stay compatible with the InnoSetup naming
					break
				case	kRLXP_REMOVELINK:
					UFCom_DeleteLinks( ksXOP_LNK, 	sDir + ".xop" + ".lnk" )	
					break
				case	kRLXP_DELETE: 
					DeleteFolder  /Z  sXopRenmDir									// Remove the renamed XOP dir  e.g. 'C:UserIgor:Xops:UFe1_Utils'  or  'C:UserIgor:Xops:UFp2_Cfs'  
					if ( V_Flag )
						printf "++++Error: Could not DeleteFolder '%s' \tTo enable DeleteFolder, open the Miscellaneous Settings Dialog's Misc category \rand check the 'Enable DeleteFolder, CopyFolder/O and MoveFolder/O  commands'  checkbox.\r", sXopRenmDir
					endif
   					break
				default:
					printf "Error: ProcessXOPs(\tIllegal action %d . Allowed are 0...%d  [%s] \r", nAction, ItemsInList( ksRLXP_NAMES ) - 1, ksRLXP_NAMES
			endswitch

		endfor
	endfor
End	 

static   Function	CallXOPCompiler_( sXopRenmDir )
// Will compile a 'Release' version no matter which version is defined in Igor  so that the trial time code is never distributed to the user
	string  	sXopRenmDir								// e.g. 'C:UserIgor:Xops:UFp1_Utils'        

	string  	sCmd	= "msdev.exe  "			
	string  	sXop		= StringFromList( ItemsInList( sXopRenmDir, ":" ) - 1, sXopRenmDir, ":" ) 	// extract  Directory name = Xop name   e.g. 'C:UserIgor:Xops:UFp1_Utils'  ->  'UFp1_Utils'         
	string  	sProject	= ParseFilePath( 5, sXopRenmDir + ":" + sXop , "\\", 0, 0 ) + ".dsp /MAKE " 	// Mac to windows style
	string  	sNameCfg	= "\"" + sXop + " - Win32 Release\"" + " /REBUILD"
	string  	sStr 		= sCmd + " " + sProject + " " + sNameCfg

	printf  "\t\tCompiling XOP \t%s\tin\t'%s' \t-> \t'%s' \r",  UFCom_pd( sXop,14), sXopRenmDir, sStr
	ExecuteScriptText  /W=30		sStr	// wait 30 secs (twice the empirical value for the compile and link time) . If we do not wait Igor continues immediately before compiling the XOP has been finished

	UFCom_DeleteFilesFromList( sXopRenmDir, 			ksXOP_DELETE_FILES )					// Delete  OBJ,  PCH,  PDB...
	UFCom_DeleteFilesFromList( sXopRenmDir + ":Debug",	ksXOP_DELETE_FILES + ksXOP_LIB_FILES )	// Delete  OBJ,  PCH,  PDB.... + LIB.
	UFCom_DeleteFilesFromList( sXopRenmDir + ":Release",	ksXOP_DELETE_FILES + ksXOP_LIB_FILES )	// Delete  OBJ,  PCH,  PDB...  + LIB
End


// possibly not necessary 070124?
Function	/S	RetrieveVersion( sSrcPath, sKeyword )
// Retrieve the current FPulse version not from the string constant (which may be unaccessible when FPulse is closed) but from the file 'sSrcPath' e.g. 'C:UserIgor:FPulse:FPulse.ipf'
	string  	sSrcPath, sKeyword 
	string  	sLine, sVersion	= ""
	variable	nRefNum, pos
	// Read source file
	Open /Z=2 /R	nRefNum  	   as	sSrcPath					// /Z = 2: opens dialog box  if file is missing,  /Z = 1: no dialog / does nothing if file is missing
	if ( nRefNum != 0 )									// file could be missing  or  user cancelled file open dialog
		do 											// ..if  ReadPath was not an empty string
			FReadLine nRefNum, sLine
			if ( strlen( sLine ) == 0 )						// Only at file end the line length is 0 . Empty lines have line length 1 due to the CR
				break
			endif
			sLine	 	= ReplaceString( " ", sLine, "" )
			sLine	 	= ReplaceString( "\t", sLine, "" )
			string  	sMatchString	= "strconstant" + sKeyword + "=\""
			if ( cmpstr( sMatchString, sLine[0, strlen( sMatchString )-1 ] )  == 0 )
				sVersion	= sLine[ strlen( sMatchString ), inf ]	// e.g. strconstantksVERSION="402"//Use3or4digits;or..  ->  402"//Use3or4digits;or..
				 pos		= strsearch( sVersion, "\"", 0 )
				sVersion	= sVersion[0, pos-1 ]
				printf "\tRetrieveVersion( '%s' , '%s' )  retrieves '%s' \r", sSrcPath, sKeyword , sVersion
				break
			endif
		while ( UFCom_TRUE )     								//...is not yet end of file EOF
		Close nRefNum									// Close the input file
	else
		printf "++++Error: Could not open input file '%s' . (RetrieveVersion) \r", sSrcPath
	endif
	return	sVersion
End

Function	CheckEditReleaseSetting( sAppNm, bIsRelease, TTd, sMarkerFlag )
	string  	sAppNm
	string  	sMarkerFlag								// e.g.  'ksFP_VERSION'  or  'ksEV_VERSION'
	variable	bIsRelease, TTd
	string  	sSrcDir	= SourcesDrvDir( sAppNm )			// e.g. 'C:UserIgor:FPulse_'
	string  	sVersion	= RetrieveVersion( sSrcDir  + ":" + sAppNm + ".ipf", sMarkerFlag)	
	CheckReleaseSetting( sAppNm, sVersion, bIsRelease, TTd )
	UFCom_OfferForEdit( sSrcDir, 	sAppNm + ".ipf" )			// display the procedure window containing the version and bring it to the front, so the version can be incremented before releasing
End

Function	CheckReleaseSetting( sAppNm, sVersion, bIsRelease, TTd )
	string  	sAppNm, sVersion
	variable	bIsRelease, TTd
	string  	sCompileMode	= SelectString( bIsRelease, "DEBUG   ?!?!?", "Release \t  = \tOK" )
	string  	sLimit		= "trial version limited to " + num2str( TTd ) + " days    (" + num2str( TTd * 86400 ) + " seconds)"
	sLimit	= SelectString( TTd == 0 , sLimit,  "unlimited version" )
	printf  "\r\tCurrent settings for '%s' : \r\t\tMode : \t\t%s\r\t\tVersion :  \t%s\r\t\tTrial time :\t%s \r", sAppNm, sCompileMode, sVersion, sLimit
End


//==================================================================================================================
// Call  INNO setup to build the exe file distributed to the user
//==================================================================================================================

static  Function		CallInno( sVers, sDrive, sPrgDir, sAppNm, sReleaseSrcDir, sSetupExeDir, sInstallationDir, sBirthFile )
	string  	sVers, sDrive, sPrgDir, sAppNm, sReleaseSrcDir, sSetupExeDir, sInstallationDir, sBirthFile//, sDaBDir

	//  Cave: 1: Must be modified for Win 98 or other Windows versions  ('cmd.exe'  may change)
	//  Cave: 2. The  keywords  'Vers, ODir, Birth, Src, Msk'  must be the same as in  'FPulse.iss'  !
	//  Cave: 3: Inno's  default installation path must be changed so that it does not contain spaces ('Inno Setup 4' -> 'InnoSetup4' , or even 'Inno4' to save some bytes)
	//  Cave: 4: The workaround using an explicit call to  'cmd.exe  /K '  is needed so that the DOS window possibly containing error messages is not immediately closed.

// 070212a
	string  	sCmd 	= "cmd.exe /K " + "D:\\Programme\\InnoSetup4\\iscc.exe" + " "// also works without 'cmd.exe /K'  but then closes DOS window immediately  so that errorr messages cannot be read	
// innosetup5 mutters about fpulse.iss line 359 Instexec not known
//	string  	sCmd 	= "cmd.exe  /K  "  +  "D:\\Programme\\InnoSetup5\\iscc.exe" + " "	


	string  	sMyPrgDir	= ReplaceString(  ":" , sPrgDir, "\\" )
// 070212a
//	string  	sIssScript 	= sDrive + "\\" + sMyPrgDir + "\\FPulse.iss"			// the path to the InnoSetup script , e.g. 'C:\UserIgor\Ced\FPulse.iss'
	string  	sIssScript 	= sDrive + "\\" + sMyPrgDir + "\\" +sAppNm + ".iss"		// the path to the InnoSetup script , e.g. 'C:\UserIgor\Ced\FPulse.iss'  or  'C:\UserIgor\Ced\FEval.iss'
	
	string  	sAppNam	= "\"/dAppNm=" 	+ sAppNm + "\""	
	
	string  	sVersion	= "\"/dVers=" 		+ sVers + "\""	

	string  	sBirth	= "\"/dBirth=" 		+ sBirthFile + "\""	



	
	string  	sOutDir	= ReplaceString(  ":" , sReleaseSrcDir, "\\" )			// where InnoSetup gets the FPulse source files
	string  	sSrc		= sDrive + "\\" + sOutDir							// where InnoSetup gets the FPulse source files , e.g. 'C:\UserIgor\FPulseOut' . CANNOT be the working dir 'C:\UserIgor\Ced' !
	string  	sSource	= "\"/dSrc=" 		+ sSrc + "\""	
	
	string  	sMask	= "\"/dMsk=" 		+ sSrc + "\\*.*"	 + "\""
	
	string  	sOut		= sDrive  + "\\" + ReplaceString(  ":" , sSetupExeDir, "\\" )	//  where InnoSetup puts  'FPulse xxx Setup.exe' , e.g. 'C:\UserIgor\Ced\FPulseSetupExe'
	string  	sOutputDir	= "\"/dODir=" 		+ sOut + "\""		
	
	string  	sDDir	= sDrive  + "\\" + ReplaceString(  ":" , sInstallationDir, "\\" )	//  where InnoSetup will  unpack and install   FPulse , e.g. 'C:\UserIgor\FPulse
	string  	sDefaultDir= "\"/dDDir=" 		+ sDDir + "\""		

//	string  	sDBDir	= "\"/dDBDir=" 		+ sDaBDir + "\""				//  the SUBdirectory where InnoSetup will  read and unpack the public data base files , e.g. 'PublicDB'  or Recipes

	string  	sStr 		= sCmd + " " + sIssScript + " " + sAppNam + " " + sVersion + " " + sBirth + " " + sSource + " " + sMask + " " + sOutputDir + " " + sDefaultDir //+ " " + sDBDir 
	printf "\t%s   \r", sStr
	ExecuteScriptText  sStr
End


//==================================================================================================================
//  Building the Trial Time file name (TTF)
//==================================================================================================================

static strconstant	ksCRYPT_BASE	= "cryptbd"		// must be the  SAME  here in  ProjectsInstall.ipf  and  in  UFP_Ced.c
static strconstant	ksCRYPT_EXT		= ".dll"			// must be the  SAME  here in  ProjectsInstall.ipf  and  in  UFP_Ced.c

static  Function	/S	BuildTTFileNm( sVersion )
	string  	sVersion
	string  	sScrambled  =  ScrambleLetterDigit( sVersion ) 
	string  	sNm	= ksCRYPT_BASE + sScrambled + ksCRYPT_EXT
	printf "\t\tBuildTTFileNm( %s ) -> '%s'  -> '%s' --> '%s' \r", sVersion, sScrambled, ScrambleLetterDigit( sScrambled ), sNm
	return	sNm
End

static  Function	/S	ScrambleLetterDigit( sString )
// Codes version string  e.g.  241c   very simply so that it is not immediately recognised as such. Coding and decoding is symmetrical  ( uses same function )
	string  	sString
	variable 	n, len	= strlen( sString )
	string  	sResult	= ""
	for ( n = len - 1 ; n >= 0; n -= 1 )
		sResult += Scramble1( sString[ n, n ] )		// reverse string
	endfor
	printf "\t\tScrambleLetterDigit( %s ) -> '%s'  \r", sString, sResult
	return	sResult
End
	
static  Function	/S		Scramble1( sChar )
// Only letters and digits are allowed, but no underscore
	string  	sChar
	variable	nOrg	= char2num( sChar )
	nOrg	= ( char2num( "0" ) <= nOrg  &&  	nOrg	<= char2num( "9" )  )	?  nOrg - char2num( "0" ) 		:  nOrg	// map '0'...'9'  to number  0..9
	nOrg	= ( char2num( "a" ) <= nOrg  &&  	nOrg	<= char2num( "z" )  )	?  nOrg - char2num( "a" ) + 10	:  nOrg	// map 'a'...'z'  to number 10..36
	nOrg	= ( char2num( "A" ) <= nOrg  &&	nOrg	<= char2num( "Z" )  )	?  nOrg - char2num( "A" ) + 10	:  nOrg	// map 'A'...'Z'  to number 10..36
	// Add 18 and compute the remainder when dividing by 36
	nOrg	+= 18					// must be half of 36
	nOrg	= mod( nOrg, 36 )
	if ( nOrg < 10 )
		return	num2str( nOrg )
	else
		return	num2char( nOrg - 10 + char2num( "a" ) )
	endif 
End



//==================================================================================================================


//static strconstant	ksMY_WINNT_DLL_DIR	= "D:WinNT"							// where this installation puts the DLLs (which avoids conflicts when InnoSetup possibly removes them)


//	// Version 1 : Copy the required DLLs into the Windows directory  or  into  the Windows System directory.
//	//  When switching between archive versions this is not required but after a TRUE-Release-InnoSetup version has been installed then the InnoSetup deinstallation unfortunately removes the DLLs from the system directory
// Elaborate code taken from 'Install.ipf'
//
// static strconstant	ksWINNT_DLL_DIR		= "WinNT:System32"		// where InnoSetup puts the DLLs 
//
// 	
//Function	/S	IncrementDrive( sDrive )	
//	string  	sDrive
//	return ( num2char( char2num( sDrive[ 0, 0 ] ) + 1 ) + sDrive[ 1, Inf ] )
//End
//
//Function	/S	DecrementDrive( sDrive )	
//	string  	sDrive
//	return ( num2char( char2num( sDrive[ 0, 0 ] ) - 1 )  + sDrive[ 1, Inf ] )
//End
//
//Function	/S	SearchDirInDrives( sFirstDrive, sLastDrive, sDir ) 
//// Look for a drive within the given range that contains 'sDir' . If found return that drive, else return empty string.
//	string  	sFirstDrive, sLastDrive, sDir 
//	string  	sPath	= sFirstDrive + sDir
//	do
//		variable	bFound	= SearchDir( sPath ) 
//		if ( bFound ) 
//			return	sPath[ 0, 1 ]							// return only the 'drive:' , truncate the directory	
//		endif
//		sPath	= IncrementDrive( sPath )
//	while ( cmpstr( sPath[ 0, 1 ] , sLastDrive ) <= 0 )	// normally check within given range, but also avoid endless loop if  'sDir'  was above  'sLastDrive'  form the beginning
// 	//printf "\t\t\tSearchDirInDrives() \tFolder  '%s'  does not exist in drives  '%s'  ...  '%s'  . \r", sDir, sFirstDrive, sLastDrive
//	return	""
//End

//=====================================================================================================================================

//static Function		UFCom_SearchDir( sPath ) 
//// Look if  'sPath'   (including drive)  is an existing directory.  Return  TRUE  or  FALSE.
//	string  	sPath
//	variable	bFound 	= 0
//	GetFileFolderInfo  /Z	/Q	sPath
//	if (  ! V_Flag  &&  V_isFolder  &&  ! V_isReadOnly )				//  V_isFolder : directory  found
//		bFound	= TRUE
//		//printf "\t\t\tSearchDir( %s ) does %s exist. \r", sPath, SelectString( bFound, "Not" , "" )
//	endif
//	return	bFound
//End

//static Function  		UFCom_FileExistsIgorPath( sPathFile )
//	string 	sPathFile
//	variable	nRefNum
//	Open	/Z=1 /R 	/P=Igor			nRefNum  as sPathFile	// with symbolic Igor path.../Z = 1:	does nothing if file is missing
//	if  ( V_flag )			// could not open
//		// printf "\t\tFileExistsIgorPath()  returns FALSE as %s does NOT exist \r", sPathFile 
//		return 	FALSE
//	else					// could open and did it so we must close it again...
//		// printf "\t\tFileExistsIgorPath()  returns  TRUE  as %s does exist  \r", sPathFile 
//		Close nRefNum
//		return 	TRUE
//	endif
//End
//
//static Function  		UFCom_FileExists( sPathFile )
//	string 	sPathFile
//	variable	nRefNum
//	Open	/Z=1 /R 				nRefNum  as sPathFile	// without symbolic path.../Z = 1:	does nothing if file is missing
//	if  ( V_flag )			// could not open
//		// printf "\t\tFileExists()  returns FALSE as %s does NOT exist \r", sPathFile 
//		return FALSE
//	else					// could open and did it so we must close it again...
//		// printf "\t\tFileExists()  returns  TRUE  as %s does exist  \r", sPathFile 
//		Close nRefNum
//		return TRUE
//	endif
//End
//
//
//static Function	/S	UFCom_ListOfMatchingDirs( sSrcDir, sMatch, bFullPath )
//// Allows directory selection using wildcards. Returns list of matching dirs. Usage : ListOfMatchingDirs(  "C:foo2:foo1"  ,  "foo*",  0  )
//	string  	sSrcDir, sMatch
//	variable	bFullPath 					// 0 will return Dir name, 1 will return full Dir path
//	string  	lstDirsInDir, lstMatched = ""
//
//	NewPath  /Z/O/Q	SymbDir , sSrcDir 
//	if ( V_Flag == 0 )										// make sure the folder exists
//		lstDirsInDir	 = IndexedDir( SymbDir, -1, bFullPath )
//		// printf "\tListOfMatchingDirs()\t( '%s' \t'%s'  \tuip:%d ) ->\t%s \r",  sSrcDir, sMatch,  lstDirsInDir[0, 300]
//		lstMatched = ListMatch( lstDirsInDir, sMatch )
//		// printf "\tListOfMatchingDirs()\tMatched\t( '%s' \t'%s'   \tuip:%d ) ->\t%s \r",  sSrcDir, sMatch,  lstMatched[0, 300]
//		KillPath 	/Z	SymbDir
//	endif
//	return	lstMatched
//End
//
//static Function	/S	UFCom_ListOfMatchingFiles( sSrcDir, sMatch, bUseIgorPath )
//// Allows file selection using wildcards. Returns list of matching files. Usage : ListFiles(  "C:foo2:foo1"  ,  "foo*.i*"  )
//	string  	sSrcDir, sMatch
//	variable	bUseIgorPath 
//	string  	lstFilesInDir, lstMatched = ""
//
//	if ( bUseIgorPath )
//		PathInfo	Igor
//		sSrcDir	= S_Path + sSrcDir[ 1, inf ]					// complete the Igorpath  (eliminate the second colon)
//	endif
//	NewPath  /Z/O/Q	SymbDir , sSrcDir 
//	if ( V_Flag == 0 )										// make sure the folder exists
//		lstFilesInDir = IndexedFile( SymbDir, -1, "????" )
//		// printf "\tListFiles  All   \t( '%s' \t'%s'  \tuip:%d ) ->\t%s \r",  sSrcDir, sMatch,  lstFilesInDir[0, 300]
//		lstMatched = ListMatch( lstFilesInDir, sMatch )
//		// printf "\tListFiles Matched\t( '%s' \t'%s'   \tuip:%d ) ->\t%s \r",  sSrcDir, sMatch,  lstMatched[0, 300]
//		KillPath 	/Z	SymbDir
//	endif
//	return	lstMatched
//End
//
//
//
//static Function		UFCom_CopyFilesFromList( sSrcDir, lstFileGroups, sTargetDir )
//// old version , Install.ipf ( was FPulse_Install.pxp)  has  a newer, more versatile one
//	string  	sSrcDir, lstFileGroups, sTargetDir 
//	variable	n, nCnt	= ItemsInList( lstFileGroups )
//	string  	sFileGroup	
//	for ( n = 0; n < nCnt; n += 1 )
//	  	sFileGroup		= StringFromList( n, lstFileGroups )
//		UFCom_CopyFiles( sSrcDir, sFileGroup, sTargetDir ) 						// Copy the current User files (e.g. ipf, xop..) into it
//	endfor
//End
//
//static Function		UFCom_CopyFiles( sSrcDir, sMatch, sTgtDir )
//// old version , Install.ipf ( was FPulse_Install.pxp)  has  a newer, more versatile one
//// e.g. 		CopyFiles(  "D:UserIgor:Ced"  ,  "FP*.ipf" , "C:UserIgor:CedV235"  ) .  Wildcards  *  are allowed .
//	string  	sSrcDir, sMatch, sTgtDir
//	string  	lstMatched	= UFCom_ListOfMatchingFiles( sSrcDir, sMatch, FALSE )
//	variable	n, nCnt		= ItemsInList( lstMatched )
//	for ( n = 0; n < nCnt; n += 1 )
//		string  	sSrc	= sSrcDir + ":" + StringFromList( n, lstMatched )
//		string  	sTgt	= sTgtDir + ":" + StringFromList( n, lstMatched )
//		UFCom_Copy1File( sSrc, sTgt )
//	endfor
//End
//
//static Function		UFCom_Copy1File( sSrc, sTgt )		
//	string  	sSrc, sTgt 		
//// 070217
////	CopyFile	/O		sSrc	as	sTgt	
//	CopyFile	/O /Z=1	sSrc	as	sTgt		// Z=1 do not stop on error.  Happens for 'ProjectReleaseXX.ipf'  because the links keep them open premanently open.
//	if ( V_flag )
//		printf "++++Error: Could not  copy  file  '%s' \tto\t'%s'  \r", sSrc, sTgt
//	else
//		// printf "\t\t\tCopied  \t\t%s\tto  \t  '%s' \r", pd(sSrc,35), sTgt
//	endif
//End	
//
//
//
//static Function		UFCom_DeleteFilesFromList( sSrcDir, lstFileGroups )
//// old version , Install.ipf ( was FPulse_Install.pxp)  has  a newer, more versatile one ???
//	string  	sSrcDir, lstFileGroups
//	variable	n, nCnt	= ItemsInList( lstFileGroups )
//	string  	sFileGroup	
//	printf "\t\t\tDeleteFilesFromList( \t\t\tSrcD:\t%s\tDeletes %d filegroups:\t'%s'  \r", pd(sSrcDir,32),  nCnt, lstFileGroups
//	for ( n = 0; n < nCnt; n += 1 )
//	  	sFileGroup		= StringFromList( n, lstFileGroups )
//		// printf "\t\t\tDeleteFilesFromList( \tn: %d/%d\tsrcDir:\t%s\tDeletes filegroup:\t'%s'  \r", n, nCnt, pd(sSrcDir,32),  sFileGroup
//		UFCom_DeleteFiles( sSrcDir, sFileGroup ) 
//	endfor
//End
//
//static Function		UFCom_DeleteFiles( sSrcDir, sMatch )
//// e.g. 		DeleteFiles(  "D:UserIgor:Ced"  ,  "FP*.ipf"  ) . Wildcards  *  are allowed .
//	string  	sSrcDir, sMatch
//	string  	lstMatched	= UFCom_ListOfMatchingFiles( sSrcDir, sMatch, FALSE )
//	variable	n, nCnt		= ItemsInList( lstMatched )
//	// printf "\tDeleteFiles( Matched\t%s,\t%s   \t ) \t: %2d\tfiles  %s \r",  sSrcDir, sMatch, nCnt, lstMatched[0, 300]
//	for ( n = 0; n < nCnt; n += 1 )
//		string  	sSrc	= sSrcDir + ":" + StringFromList( n, lstMatched )
//		DeleteFile		/Z=1	  	sSrc
//		if ( V_flag )
//			printf "++++Error: Could not delete file \t'%s'  \r", sSrc
//		else
//			//printf "\t\t\t\tDeleted file\t'%s'  \r", sSrc
//		endif
//	endfor
//End
//
//
//
//static Function		UFCom_CreateLinksFromList( sSrcDir, lstFileGroups, sTgtDir )
//// old version , FPulse_Install.pxp has  a newer one
//	string  	sSrcDir, lstFileGroups, sTgtDir
//	variable	n, nCnt	= ItemsInList( lstFileGroups )
//	string  	sFileGroup	
//	for ( n = 0; n < nCnt; n += 1 )
//	  	sFileGroup		= StringFromList( n, lstFileGroups )
//		UFCom_CreateLinks( sSrcDir, sFileGroup, sTgtDir ) 					
//	endfor
//End
//
//static Function		UFCom_CreateLinks( sSrcDir, sMatch, sTgtDir )
//// e.g. 		CreateLinks(  "D:UserIgor:Ced"  ,  "FP*.ipf" , "D:....:Igor Pro Folder:User Procedures"  ) . Wildcard *   is only allowed in filebase,   * is NOT allowed in the file extension.
//	string  	sSrcDir, sMatch, sTgtDir
//	string  	lstMatched	= UFCom_ListOfMatchingFiles( sSrcDir, sMatch, FALSE )
//	variable	n, nCnt		= ItemsInList( lstMatched )
//	// printf "\tCreateLinks(  Matched \t%s,\t%s   \t->\t%s  ) \t: %2d\tfiles  %s \r",  sSrcDir, sMatch, sTgtDir, nCnt, lstMatched[0, 300]
//	for ( n = 0; n < nCnt; n += 1 )
//		string  	sSrc	= sSrcDir + ":" + StringFromList( n, lstMatched )
//		string  	sTgt	= sTgtDir + ":" + StringFromList( n, lstMatched ) + ".lnk"
//		UFCom_CreateAlias( sSrc, sTgt )
//	endfor  
//End
//
//static Function		UFCom_CreateAlias( sFromPathFile, sToLinkFile )
//	string  	sFromPathFile, sToLinkFile
//	CreateAliasShortcut /O  /P=Igor		sFromPathFile		as	sToLinkFile
//	if ( V_flag )
//		printf "++++Error: Could not create link from\t'%s' \tto\t'%s'  [S_Path: '%s' ] \r", pd( sFromPathFile, 40 ), sToLinkFile, S_Path
//	else
//		 printf "\t\t\t\tCreated link from\t%s\tto\t  '%s' \r", pd( sFromPathFile,36), S_Path
//	endif
//End


//
//static constant  cSPACEPIXEL = 3,  cTYPICALCHARPIXEL = 6
//
//static Function  /S  pd( str, len )
//	string 	str
//	variable	len
//
//	str		= ReplaceString( "\t", str, "" )		// !!! 060106
//	variable	nFontSize			= 10
//	string  	sFont			= "default"		// GetDefaultFont( "" )
//	variable	nStringPixel		= FontSizeStringWidth( sFont, nFontSize, 0, str )
//	variable	nRequestedPixel	= len * cTYPICALCHARPIXEL
//	variable	nDiffPixel			= nRequestedPixel - nStringPixel
//	variable	OldLen 			= strlen( str )
//	
//	if ( nDiffPixel >= 0 )						// string is too short and must be padded
//		return	"'" + str + "'" + PadString( str, OldLen + nDiffPixel / cSPACEPIXEL,  0x20 )[ OldLen, Inf ]
//	endif	
//
//	if ( nDiffPixel < 0 )						// string is too long and must be truncated
//		string  	strTrunc 
//		variable	nTrunc	= min( OldLen, ceil( len*1.3 ) ) + 1	// empirical: start truncation at a string length 30% longer than expected...
//		do
//			nTrunc	-= 1
//			strTrunc	 = str[ 0, nTrunc ]
//		while (  nTrunc > 0  &&  FontSizeStringWidth( sFont, nFontSize, 0, strTrunc ) > nRequestedPixel ) 	
//		return	"'" + strTrunc + "'"	
//	endif
//End
//
//=====================================================================================================================================

//// 070213........................
//static Function		UFCom_PossiblyCreatePath( sPath )
//	string 	sPath
//	string 	sPathCopy	, sMsg
//	sPath	= ParseFilePath( 5, sPath, ":", 0, 0 ) 		// return Mac-style path  containing colons  e.g. 'C:UserIgor:Ced'
//	variable	r, n, nDirLevel	= ItemsInList( sPath, ":" ) 
//	variable	nRemove	= 1
//	for ( nRemove = nDirLevel - 1; nRemove >= 0; nRemove -= 1 )				// start at the drive and then add 1 dir at a time, ...
//		sPathCopy		= sPath										// .. assign it an (unused) symbolic path. 
//		sPathCopy		= UFCom_RemoveLastListItems( nRemove, sPathCopy, ":" )	// ..This  CREATES the directory on the disk
//		NewPath /C /O /Q /Z SymbPath1,  sPathCopy	
//		if ( V_Flag == 0 )
//			// printf "\tUFCom_PossiblyCreatePath( '%s' )  Removing:%2d of %2d  \t'%s' exists or has been created (V_Flag:%d) \r", sPath, nRemove, nDirLevel, sPathCopy, v_Flag
//		else
//			sprintf sMsg, "While attempting to create path '%s'  \t'%s' \tcould not be created. [UFCom_PossiblyCreatePath()]", sPath, sPathCopy
//			DoAlert 0, sMsg
//			//UFCom_Alert( UFCom_kERR_SEVERE, sMsg )
//			return	-1
//		endif
//	endfor
//	// printf "\tPossiblyCreatePath( '%s' )  \t'%s' exists or has been created (V_Flag:%d) \r", sPath, sPathCopy, v_Flag
//	return	1
//End
//
//static Function	/S	UFCom_RemoveLastListItems( cnt, sList, sSep ) 
//// removes  'cnt'  trailing items from list 
//	variable	cnt
//	string 	sList, sSep 
//	variable	n, nItems
//	for ( n = 0; n < cnt; n += 1 )
//		nItems	= ItemsInList( sList, sSep ) 				// while the list is getting shorter....
//		sList		= RemoveListItem( nItems-1, sList, sSep )	//..always remove the last item
//	endfor
//	return	sList
//End

//static Function		UFCom_ReplaceModuleNamesFromLst( sSrcTxt, sReplaceTxt, sSrcDir, sTgtDir, lstMatch ) 
//// Loops through list  'lstMatch'  and extracts  'sMatch' .   Then for all  'sMatch' ...
//// ...Copy all files which match  'sMatch' (e.g. '*.ipf')  from  'sSrcDir'  into  'sTgtDir'   after having  replaced  'sSrcTxt'  (e.g. 'UFCom_')  by  'sReplaceTxt'  (e.g. 'UFSec_'  or  'UFFPu_') .  This is for COMMON and specific files.
//// If the file name starts with 'sSrcTxt'  (e.g. 'UFCom_')  then also rename the file by replacing 'sSrcTxt'  by  'sReplaceTxt'  (e.g. 'UFSec_'  or  'UFFPu_') .  This is for  COMMON  files.
//	string  	sSrcTxt, sReplaceTxt, sSrcDir, sTgtDir, lstMatch
//	// UFCom_PossiblyCreatePath( sTgtDir )
//	variable	n, nItems	= ItemsInlist( lstMatch )
//	for ( n = 0; n < nitems; n += 1 )
//		string  sMatch	= StringFromList( n, lstMatch )
//		UFCom_ReplaceModuleNames( sSrcTxt, sReplaceTxt, sSrcDir, sTgtDir, sMatch ) 
//	endfor
//End

//static Function		UFCom_ReplaceModuleNames( sSrcTxt, sReplaceTxt, sSrcDir, sTgtDir, sMatch ) 
//// Copy all files which match  'sMatch' (e.g. '*.ipf')  from  'sSrcDir'  into  'sTgtDir'   after having  replaced  'sSrcTxt'  (e.g. 'UFCom_')  by  'sReplaceTxt'  (e.g. 'UFSec_'  or  'UFFPu_') .  This is for COMMON and specific files.
//// If the file name starts with 'sSrcTxt'  (e.g. 'UFCom_')  then also rename the file by replacing 'sSrcTxt'  by  'sReplaceTxt'  (e.g. 'UFSec_'  or  'UFFPu_') .  This is for  COMMON  files.
//	string  	sSrcTxt, sReplaceTxt, sSrcDir, sTgtDir, sMatch
//	string  	lstMatched	= UFCom_ListOfMatchingFiles( sSrcDir, sMatch, 0 )
//	variable	n, nCnt		= ItemsInList( lstMatched )
//	if ( nCnt )
//		UFCom_PossiblyCreatePath( sTgtDir )					// Design issue: do not create directory if there are no replacements to make  
//		 printf "\t\tReplaceModuleNames(  \t\t\tReplace \t%s\tby\t%s\tMatched \t%s\t%s\t: %2d\tfiles '%s'...\r", pd(sSrcTxt,14), pd(sReplaceTxt,14), pd(sSrcDir,24),  pd(sMatch,9) , nCnt, lstMatched[0, 220]
//	endif
//	for ( n = 0; n < nCnt; n += 1 )
//		string  	sFile	=  StringFromList( n, lstMatched )
//		string  	sSrc	= sSrcDir + ":" + sFile
//		string  	sTgt	= sTgtDir + ":" + ReplaceString( sSrcTxt, sFile, sReplaceTxt )	// toImprove: replace only at beginning of name
//		// printf "\t\t\tReplaceIndependentModules(  \t%2d/%2d\tReplace \t%s\tby\t%s\tfiles  %s \r",  n, nCnt, pd(sSrc,37) , pd(sTgt,37), lstMatched[0, 250]
//		UFCom_ReplaceStringInFile( sSrcTxt, sReplaceTxt, sSrc, sTgt ) 
//	endfor  
//End
//
//static Function		UFCom_ReplaceStringInFile( sSrcTxt, sReplaceTxt, sSrcPath, sTgtPath ) 
//// Read  file  'sSrcPath' ,  replace  'sSrcTxt'  by  'sReplaceTxt'   and  store in file  'sTgtPath' .   'sSrcPath'  and  'sTgtPath'  may be the same.   
//	string  	sSrcTxt, sReplaceTxt
//	string		sSrcPath, sTgtPath							// can be empty ...
//	variable	nRefNum, nRefNumTgt, nLine = 0
//	string		sAllText = "", sLine			= ""
//	variable	bIsInPicture	= 0
//	
//	// Read source file
//	Open /Z=2 /R	nRefNum  	   as	sSrcPath					// /Z = 2: opens dialog box  if file is missing,  /Z = 1: no dialog / does nothing if file is missing
//	if ( nRefNum != 0 )									// file could be missing  or  user cancelled file open dialog
//		do 											// ..if  ReadPath was not an empty string
//			FReadLine nRefNum, sLine
//			if ( strlen( sLine ) == 0 )						// Only at file end the line length is 0 . Empty lines have line length 1 due to the CR
//				break
//			endif
//
//			// Do  NOT  replace characters if we are within a picture 
//			if ( ! bIsInPicture )
//				if ( ( cmpstr( UFCom_FirstWord( sLine ), "PICTURE" ) == 0  )  ||  ( cmpstr( UFCom_FirstWord( sLine ), "STATIC" ) == 0  &&  cmpstr( UFCom_SecondWord( sLine ), "PICTURE" ) == 0   ) )				
//					bIsInPicture = TRUE
//				endif
//			endif
//			if ( bIsInPicture )
//				if ( ( cmpstr( UFCom_FirstWord( sLine ), "END" ) == 0  ) )
//					bIsInPicture	= FALSE
//				endif
//			endif
//
//			// printf "\tUFCom_ReplaceStringInFile() \tInPic:%d \t%s ",  bIsInPicture, sLine
//			if ( ! bIsInPicture )
//				sLine = ReplaceString( sSrcTxt, sLine,  sReplaceTxt )	
//			endif		
//			sAllText	+=	sLine + "\n" 			// \n appends 0A . In can be omitted but is included here as the ipf source file also contains it.
//			// printf "\t\tUFCom_ReplaceStringInFile() \t\t%s ", sLine
//
//			nLine += 1
//		while ( TRUE )     								//...is not yet end of file EOF
//		Close nRefNum									// Close the input file
//	else
//		printf "++++Error: Could not open input file '%s' . (ReplaceStringInFile) \r", sSrcPath
//	endif
//	
//	// Write target file.  By separating  read and write we can directly overwrite the source file.  (As long as Igor allows it - for example we cannot overwrite a currently open IPF file) 
//	Open /Z=2 	nRefNumTgt as sTgtPath						//
//	if ( nRefNumTgt != 0 )								
//		variable	n, nLines = ItemsInList( sAllText, "\n" )
//		for ( n = 0; n < nLines; n += 1 )
//			sLine		= StringFromList( n, sAllText, "\n" )
//			fprintf  nRefNumTgt, "%s\n" , sLine			// \n appends 0A . In can be omitted but is included here as the ipf source file also contains it.
//		endfor
//		Close nRefNumTgt							// Close the output file
//	else
//		printf "++++Error: Could not open output file '%s' . (ReplaceStringInFile) \r", sTgtPath
//	endif
//	//printf "\tUFCom_ReplaceStringInFile() \t%s\t ->\t%s\t (Lines: %d)  \r", UFCom_pd(sSrcPath,33) ,  UFCom_pd(sTgtPath, 33), nLine
//	return	0
//End
//
//
//static Function	/S	UFCom_FirstWord( sLine )
//	string  	sLine
//	string  	sWord
//	sscanf sLine, "%s" , sWord
//	// printf "\t\t\tFirstWord()  \t%s\r", sWord
//	return	sWord
//End	
//
//static Function	/S	UFCom_SecondWord( sLine )
//	string  	sLine
//	string  	sWord1, sWord2
//	sscanf sLine, "%s %s" , sWord1, sWord2
//	// printf "\t\t\tSecondWord(() \t'%s' , '%s'  %d  %d \r", sWord1, sWord2, cmpstr( sWord1, "STATIC" ),   cmpstr( sWord2 , "PICTURE" )
//	return	sWord2
//End	
//
