//====================================================================================================================================
//	ProjectsCommonsFP.ipf	070117
//		Allows installation of any FPuls development version found  in  'UserIgor:Archive_FP' .  
//		Release version are not installed this way. they are installed by extracting the EXE created by InnoSetup.
//		The deinstallation procedure required prior to installation is DeInstallFPulse()  [ in ProjectsReleaseFP.ipf ] 
//=====================================================================================================================================
//
//	THIS FILE IS FOR THE DEVELOPER ONLY.  IT IS NOT TO BE DISTRIBUTED TO THE USER !
//	This file and the link to this file and the link to the directory of this file (UserIgor:Commons) must always stay active.
//	They must never be removed,  neither by the deinstallation procedure nor by the release procedure. 
// 	This does not lead to linker errors (function exists already) when User releases are installed because the User Commons function are auto-renamed to avoid naming conflicts
//
//	RevHist
// 	070822	removed Trial time (as it can easily be overcome 1.using a virtual machine and 2.simply loading an experiment rather than starting FPuls by selecting a menu item)...
//			...but  keep  an empty string  'sBirthFile->sBirthFile_Unused'  as a dummy parameter to  'CallInno -> Execute ISCC.exe'...   which can be used should need arise to introduce another optional InnoSetup parameter

// Possible improvement:  rename links  e.g. '.lnk'  ->  '.lnn'    rather than  deleting and recreating them ???


#pragma rtGlobals=1							// Use modern global access method.

#include "UFCom_ReleaseComments"			// for all UFCom_Xxx
#include "UFCom_DirsAndFiles"					// for   UFCom_AllUsersDirPath()

//=====================================================================================================================================
//	Switch  FPuls / FEval Version
//
//	DeInstallFPuls()  and  InstallFPuls()  are companions!
// 	Cave 1:  All these file and dir constants must be the same in    ProjectsRelease.ipf     and in    ProjectsCommonsFP.ipf   and in   UFPE_PulseConstants.ipf
// 	Cave 2:  Will only work if the link file names are supplied by InstallFPuls().  Any other link file names as supplied by  TotalCommander or  Windows must be renamed to this convention or deleted.
// 	Cave 3:  Will only work if these constants are the same in  Projects.ipf / ProjectsCommons.ipf / UF_Release.ipf   ( and  FPulseCed.c )

static constant		FALSE = 0, TRUE = 1,  OFF = 0,  ON = 1, kOK = 0

// copied from UFPE_PulseConstants.ipf
static strconstant	ksMY_DRIVE				= "D:"								// where my sources are , ................	must be the  SAME  as UFPE_ksSCRIPTS_DRIVE
static strconstant	ksLINK2DIR				= "Link2Dir_"							// Base name (FPuls or FEval will be appended!) of link of working directory (the specific IPFs) in 'User procedures' .  
																			// If this base name is changed the existing link must be renamed accordingly for the (De)Installation to work properly!
static strconstant	ksIGORPROC_LNK			= ":Igor Procedures"
static strconstant	ksUSERPROC_LNK			= ":User Procedures"
static strconstant	ksHELP_LNK				= ":Igor Help Files"
static strconstant	ksXOP_LNK				= ":Igor Extensions"

static strconstant	ksDLL_DIR				= ":Dll"								// do not change to ensure compatibility

static strconstant	ksXOP_SOURCE_FILES		= "*.c;*.h;*.hpp;*.rc;*.dsp;*.dsw;*.bmp;"
static strconstant	ksXOP_DELETE_FILES		= "*.ilk;*.opt;*.plg;*.exp;*.idb;*.obj;*.pch;*.res;"	// unnecessary temporary files created during compiling and linking
static strconstant	ksXOP_LIB_FILES			= "*.lib;"								//1. include for backup to be self-contained  2. deleted only in subdirectories /Debug and /Release



//  XOP PROCESSING : Neither the names nor the number of Xops have to be listed here.   ALL  Xops in a subdirectory are processed.

static strconstant	ksXOP_DIR				= "UserIgor:Xops"						// ....  are  backed up and compiled ,  but  C_Common  is only backed up but not compiled separately
//static strconstant	ksXOP_SUBDIR_			= "Debugs:"							// ....  are  backed up and compiled ,  but  C_Common  is only backed up but not compiled separately

strconstant		ksXOPSEP				= "^"									// separates the above prefixes

 constant			kRLXP_COPY = 0,   kRLXP_RENAME = 1,   kRLXP_COMPILE = 2,   kRLXP_CREATELINK = 3,   kRLXP_REMOVELINK = 4,   kRLXP_DELETE = 5    
static strconstant	ksRLXP_NAMES = "Copy;Rename;Compile;Create link;Remove link;Delete;"

//=====================================================================================================================================
//	 Switch  FPuls / FEval Version :  DIRECTORY NAMING CONVENTIONS
//=====================================================================================================================================

Function	/S	DllDrvDir()
	string  	sAppNm
	return	ksMY_DRIVE + UFCom_ksUSERIGOR_DIR+  ":Dll" 			// e.g. 'C:UserIgor'
End

Function	/S	SourcesDrvDir( sAppNm )								
	string  	sAppNm											// same as ksSOURCES_DRV_DIR  in   FPulse -> UFP_Ced -> XopMain.h   or in  FEval -> UFE_Ttf -> XopMain.h   (but note Mac/Win style)  
	return	ksMY_DRIVE + SourcesDir( sAppNm )					// return my working directory  e.g. 'C:UserIgor:FPulse_'  or  'C:UserIgor:FEval_'
End
		
Function	/S	SourcesDir( sAppNm )		
// Cave : must be the  SAME  as   ksSOURCES_DRV_DIR  in   FPulse -> UFP_Ced -> XopMain.h   or in  FEval -> UFE_Ttf -> XopMain.h   (add Drive, and note Mac/Win style)
	string  	sAppNm											// return my working directory  e.g. 'UserIgor:FPulse_'  or  'UserIgor:FEval_'
	return	UFCom_ksUSERIGOR_DIR  + ":" + sAppNm + "_"	 		// !!!  requires  '_.lnk'  at some places...   
End
		
Function	/S	InstallDir( sAppNm )		
	string  	sAppNm											// return directory where InnoSetup will  unpack and install   FPulse or FEval on the user's hard disk
	return	UFCom_ksUSERIGOR_DIR + ":" + sAppNm				// e.g. 'UserIgor:FPulse'  or  'UserIgor:FEval'
End
		
Function	/S	ReleaseOutDir( sAppNm )		
	string  	sAppNm											// return directory where InnoSetup finds all filles to be distributed to the user
// 2009-05-06	moved all archive and setup files  fron UserIgor to UserIgorArchive  to keep  UserIgor (=the working directory)  small  (which speeds up the daily backup process) 
//	return	UFCom_ksUSERIGOR_DIR 		+ ":" + sAppNm + "_Out"			// e.g. 'UserIgor:FPulse_Out'  or  'UserIgor:FEval_Out'
	return	UFCom_ksUSERIGOR_ARCHIV_DIR + ":" + sAppNm + "_Out"			// e.g. 'UserIgor:FPulse_Out'  or  'UserIgor:FEval_Out'
End
		
Function	/S	ReleaseExeDir( sAppNm )		
	string  	sAppNm											// return directory where InnoSetup puts  'FEval xxx Setup.exe'  on my hard disk
// 2009-05-06	moved all archive and setup files  fron UserIgor to UserIgorArchive  to keep  UserIgor (=the working directory)  small  (which speeds up the daily backup process) 
//	return	UFCom_ksUSERIGOR_DIR 		+ ":" + sAppNm + "_SetupExe"		// e.g. 'UserIgor:FPulse_SetupExe'  or  'UserIgor:FEval_SetupExe'
	return	UFCom_ksUSERIGOR_ARCHIV_DIR + ":" + sAppNm + "_SetupExe"		// e.g. 'UserIgor:FPulse_SetupExe'  or  'UserIgor:FEval_SetupExe'
End
		
Function	/S	ArchiveBaseDrvDir( sAppNm )
	string  	sAppNm											// where the backups of the current version (before releasing switching)   are saved
// 2009-05-06	moved all archive and setup files  fron UserIgor to UserIgorArchive  to keep  UserIgor (=the working directory)  small  (which speeds up the daily backup process) 
//	return	ksMY_DRIVE + UFCom_ksUSERIGOR_DIR 		+ ":" + sAppNm + "_Archive"	// e.g. 'C:UserIgor:FPulse_Archive'  or   'C:UserIgor:FEval'_Archive
	return	ksMY_DRIVE + UFCom_ksUSERIGOR_ARCHIV_DIR + ":" + sAppNm + "_Archive"	// e.g. 'C:UserIgor:FPulse_Archive'  or   'C:UserIgor:FEval'_Archive
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
//	 BACKUP
//=====================================================================================================================================

Function		UFProj_Backup( sAppNm, sMarker, lstPrefixXops, sSomeComDir, lstUserFiles, lstMoreBackups )
	string  	sAppNm, sMarker, lstPrefixXops,  sSomeComDir, lstUserFiles
	string  	lstMoreBackups		

	string  	sSourcesDrvDir	= SourcesDrvDir( sAppNm )
	string  	sVersion		= RetrieveVersion( sSourcesDrvDir + ":" + sAppNm + ".ipf", sMarker )	//  e.g. 'ksEV_VERSION'
	string  	sArchiveDir	= ArchiveDrvDir( sAppNm, sVersion )
	string  	sReleaseOutDir	= ReleaseOutDir( sAppNm )								// e.g. 'UserIgor:FEvalOut'
	UFProj_BackupWorkingDir( sAppNm, sVersion, sArchiveDir, sSourcesDrvDir, sSomeComDir, lstUserFiles )
	PossiblyProcessXops( kRLXP_COPY, ksXOP_DIR, lstPrefixXops,  sArchiveDir, sReleaseOutDir ) 
	UFProj_BackupAllTheRest( sAppNm, sVersion, sArchiveDir, sSourcesDrvDir, lstMoreBackups )	// Backup files (e.g. bmp, iss, ttf ) into the which are  NOT to be distributed to the user.
End


Function	/S	UFProj_BackupWorkingDir( sAppNm, sVersion, sArchiveDir, sSourcesDrvDir, sSomeComDir, lstUserFiles )
// For every version create an  ARCHIVE  subdirectory  e.g. 'C:UserIgor:FEval_Archive:FEval040315_1200V235'  for the Igor files (and possibly Xop C source  files)  on the hard disk and copy files into it.
	string  	sAppNm, sVersion
	string  	sArchiveDir
	string  	sSourcesDrvDir														// e.g. 'C:UserIgor:FPulse_'
	string  	sSomeComDir														// for half-generic commons e.g.  'UFPE_'  which are common to FPulse and FEval  but not to SecuCheck and not to Recipes
	string  	lstUserFiles
	string  	sCedComSrcDir	= ksMY_DRIVE + UFCom_ksUSERIGOR_DIR + ":" + sSomeComDir			// e.g  'C:UserIgor:CommonsFpFe'			
	string  	sComSrcDir	= ksMY_DRIVE + UFCom_ksUSERIGOR_DIR + ":" + UFCom_ksDIR_COMMONS	// e.g. 'C:UserIgor:Commons'
	string  	sArchiveSubDir

	// Copy  FPulse_  or  FEval_  files  from  development directory  into a separate Archive directory
	UFCom_PossiblyCreatePath( sArchiveDir )											// Create  directory	e.g.	'C:UserIgor:SecuTest040315V235:FPulse_" 
	UFCom_CopyFilesFromList( sSourcesDrvDir, lstUserFiles,	sArchiveDir )					// Copy the current User files (e.g. ipf, ihf, xop..) into the archive

	// Copy CedCommon files  from  'UserIgor:CommonsFpFe' development directory into separate Archive-CommonsFpFe subdirectory
if ( strlen( sSomeComDir ) )
	sArchiveSubDir	= sArchiveDir + ":" + sSomeComDir	 							// e.g. 'C:UserIgor:FEval_Archive:FEval040315V235:CommonsFpFe'	 	
	UFCom_PossiblyCreatePath( sArchiveSubDir )										// Create  directory	
	UFCom_CopyFilesFromList( sCedComSrcDir,  "*.ipf;" , sArchiveSubDir )						// Copy the current User files ( only  ipf ) into the archive
endif
	// Copy Common files  from  'UserIgor:Commons' development directory into separate Archive-Commons subdirectory
	sArchiveSubDir	= sArchiveDir + ":" + UFCom_ksDIR_COMMONS			 				// e.g. 'C:UserIgor:FPulse_Archive:FPulse040315V235:Commons'	 	
	UFCom_PossiblyCreatePath( sArchiveSubDir )										// Create  directory	
	UFCom_CopyFilesFromList( sComSrcDir,  "*.ipf;" , sArchiveSubDir )						// Copy the current User files ( only  ipf ) into the archive

	return	sArchiveDir														// e.g. 'C:UserIgor:SecuTest040315V235'	
End


Function	/S	UFProj_BackupAllTheRest( sAppNm, sVersion, sArchiveDir, sSourcesDrvDir, lstMoreBackups )
// Copy  more  files from development directory into archive, which are NOT distributed to the user
	string  	sAppNm, sVersion, sArchiveDir, sSourcesDrvDir 
	string  	lstMoreBackups								// e.g.	= "*.iss;*.bmp;*.ttf;"
	UFCom_CopyFilesFromList( sSourcesDrvDir, lstMoreBackups, sArchiveDir )							// Copy the current User files (e.g. ipf, ihf, xop..) into it
	string  	lstCopied		= UFCom_ListOfMatchingFiles( sArchiveDir, lstMoreBackups, UFCom_FALSE )	// False: don't use IgorPath
	printf  "\tBackupRest()  \tBacking up '%s' Version %s   (%d files, %s)   from  '%s'   to  '%s'     [ %s.....]\r", sAppNm, sVersion,  ItemsInList( lstCopied ), lstMoreBackups, sSourcesDrvDir, sArchiveDir,  lstCopied[0,100]
End


//=====================================================================================================================================
//	 DEINSTALLATION
//=====================================================================================================================================

Function		UFProj_DeInstall( sAppNm, sMarker, lstPrefixXops, sSomeComDir, lstUserFiles, lstMoreBackups, lstHelpFiles, lstPrefixDelLink )
	string  	sAppNm, sMarker, lstPrefixXops,  sSomeComDir, lstUserFiles
	string  	lstMoreBackups, lstHelpFiles, lstPrefixDelLink

	string  	sSourcesDrvDir	= SourcesDrvDir( sAppNm )
	string  	sVersion		= RetrieveVersion( sSourcesDrvDir + ":" + sAppNm + ".ipf", sMarker )	// e.g. 'ksEV_VERSION'
	string  	sArchiveDir	= ArchiveDrvDir( sAppNm, sVersion )
	string  	sReleaseOutDir	= ReleaseOutDir( sAppNm )								// e.g. 'UserIgor:FPulse_Out'
	UFProj_Backup( sAppNm, sMarker, lstPrefixXops, sSomeComDir, lstUserFiles, lstMoreBackups )
	DeInstallLinks( sAppNm, sVersion, sArchiveDir, lstPrefixDelLink, sSourcesDrvDir, lstHelpFiles, sReleaseOutDir  )
End

static Function		DeInstallLinks( sAppNm, sVersion, sArchiveDir, lstPrefixDelLink, sSourcesDrvDir, lstHelpFiles, sReleaseOutDir )
	string  	sAppNm, sVersion, sArchiveDir, lstPrefixDelLink, sSourcesDrvDir
	string  	lstHelpFiles
	string  	sReleaseOutDir	
	
	// Delete all links.  This is required before the file deletion can take place ( after restarting Igor ) .
	// Cave / Flaw / Todo  : does not recognise renamed links  e.g.  'Verknüpfung mit.....'
	UFCom_DeleteLinks( ksIGORPROC_LNK, 	sAppNm + ".ipf"		+ ".lnk" )		// 'FPulse.ipf'  or  'FEval.ipf'
	UFCom_DeleteLinksFromList(   ksHELP_LNK, 	lstHelpFiles	, ".lnk" )		// '.lnk' is a separate parameter as an extension can only be appended to links, not to a list 	

	PossiblyProcessXops( kRLXP_REMOVELINK, ksXOP_DIR, lstPrefixDelLink, "" , sReleaseOutDir) 

	UFCom_DeleteLinks( ksUSERPROC_LNK,	ksLINK2DIR+sAppNm+"_.lnk")		// link to directory  UserIgor:Eval_  or  UserIgor:FPulse_ 
	printf  "\tDeInstallLinks() \tDeleting links for '%s'...\r", sAppNm

	DoAlert 0,  "You must  quit and restart Igor and then execute : \rfor development 'Install"+sAppNm+"'  -> 'Install "+sAppNm+" any version'  \ror for Release any '"+sAppNm+" nnn Setup.exe' (from InnoSetup)"
End


//=====================================================================================================================================
//	 INSTALLATION 
//=====================================================================================================================================

Function		UFProj_Install( sAppNm, lstDLLFiles, lstPrefixXops, lstHelpFiles )
	string  	sAppNm, lstDLLFiles, lstPrefixXops, lstHelpFiles
	string  	sSourcesDrvDir	= SourcesDrvDir( sAppNm )
	InstallProject( sAppNm, sSourcesDrvDir, lstDLLFiles, lstPrefixXops, lstHelpFiles  )
End

static Function		InstallProject( sAppNm, sSourcesDrvDir, lstDllFiles, lstPrefixXops, lstHelpFiles )
// Installs any FPulse version found in   C:UserIgor:Archive .   Will not and should not be used to install  InnoSetup-Release version.  Use  InnoSetup for this purpose (after deinstalling the development version)
// Requirement:  Any links from  the previous FPulse version must already have been deleted : This is done in 'Projects'  -> 'DeInstall FPulse'   and Igor must have been restarted.
// Only if those conditions are fulfilled we can delete all files in the development directory (and copy the new ones)
// ToThink: Should the 3 C_xxx directories also be copied?  They contain about 20MB data which are changed very seldomly so at the moment they are just kept.....

	string  	sAppNm, sSourcesDrvDir, lstDllFiles, lstPrefixXops  
	string  	lstHelpFiles

	// Check that all links have been deleted.  Will recognise only 'non-renamed' links, will fail with renamed links!
//must be unique to FPulse/Feval	string  	sIgorProc_Projects_Link	= ksIGORPROC_LNK + ":" + "Projects.ipf" 	+ ".lnk"
	string  	sIgorProc_AppName_Link	= ksIGORPROC_LNK  + ":" + sAppNm + ".ipf" + ".lnk"  
	string  	sUserProc_AppDir_Link	= ksUSERPROC_LNK + ":" + ksLINK2DIR+sAppNm + "_.lnk"
	variable	bLinkExists	= UFCom_FileExistsIgorPath( sIgorProc_AppName_Link )  ||  UFCom_FileExistsIgorPath( sUserProc_AppDir_Link ) 
	if ( bLinkExists ) 
		DoAlert 0 , "There are still links [  " + sUserProc_AppDir_Link +  "  or  " + sIgorProc_AppName_Link +  "]  which prevent installation. \rFor removing Development version: 'Projects'  > 'DeInstall "+sAppNm+"' \rFor Release: 'Systemsteuerung' >'Software' > 'Remove "+sAppNm+" Vxx' "
		return 0
	endif
	
	// Get  a list of previous versions for the user to choose from
	string  	lstDirs= UFCom_ListOfMatchingDirs( ArchiveBaseDrvDir( sAppNm ), "*", FALSE )	// *.* : list all dirs ,  False: supply only partial path
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
	//  Better  solution? : InnoSetup's Flag: uninsneveruninstall 
	string  sWindowsPath = UFCom_Util_GetSystemDirectory()												// e.g.  'C:\Windows\system32'  
	sWindowsPath		= UFCom_Path2Mac( sWindowsPath )										// e.g.  'C:\Windows\system32'  ->  'C:Windows:system32' 
	sWindowsPath		= RemoveEnding( UFCom_RemoveLastListItems( 1, sWindowsPath, ":" ) , ":" )			// e.g.  'C:Windows:system32' 	->  'C:Windows' 

	if ( ! UFCom_FileExists( sWindowsPath + ":" + StringFromList( 0, lstDllFiles ) ) )
		UFCom_CopyFilesFromList( ArchiveBaseDrvDir( sAppNm ) + ":" + sRestoreDir, lstDllFiles, sWindowsPath )	// e.g. 'C:UserIgor:Ced:Cfs32.dll, 1432ui.dll, Use1432.dll' -> D:WinNT 
	endif


	// Delete all files in development directory
	UFCom_DeleteFiles( sSourcesDrvDir, "*.*" )			

	// Copy  files from selected archive into development directory
	UFCom_CopyFilesFromList( ArchiveBaseDrvDir( sAppNm ) + ":" + sRestoreDir , 	 "*.*", sSourcesDrvDir )	// Copy the current User files (e.g. ipf, ihf, xop..) into it

	// Recreate the links
	UFCom_CreateLinks( "C:UserIgor:Commons",  "Projects.ipf", 	ksIGORPROC_LNK )
	UFCom_CreateLinks( sSourcesDrvDir,		   sAppNm + ".ipf", 	ksIGORPROC_LNK )
	UFCom_CreateLinksFromList( sSourcesDrvDir,  lstHelpFiles, 		ksHELP_LNK )					// 

	string  	sReleaseOutDir	= ReleaseOutDir( sAppNm )					// e.g. 'UserIgor:FPulseOut'
	PossiblyProcessXops( kRLXP_CREATELINK, ksXOP_DIR, lstPrefixXops, "", sReleaseOutDir ) 

	UFCom_CreateAlias( sSourcesDrvDir, ksUSERPROC_LNK + ":" + ksLINK2DIR+sAppNm + "_.lnk" )	// is link to directory  , but could perhaps also use  CreateLinks()...

	string  	sVersion	= sRestoreDir[ strsearch( sRestoreDir, "V", 0, 2 ) + 1, inf ]	// 2 : ignore case
	DoAlert 0,  "You must  quit and restart Igor now to activate  " + sAppNm + "V"  + sVersion + " . "
End


//=====================================================================================================================================
//	 RELEASING
//=====================================================================================================================================

Function		UFProj_CreateRelease( sAppNm, sMarker, lstPrefixXops, lstPrefixIpfs, sSomeComDir, lstDLLFiles, lstUserFiles, lstMoreBackups, sApplSubDir, sAllUsersSubDir )
	string  	sAppNm, sMarker, lstPrefixXops, lstPrefixIpfs, sSomeComDir, lstDLLFiles, lstUserFiles, sAllUsersSubDir
	string  	lstMoreBackups
	string  	sApplSubDir

	string  	sSourcesDrvDir	= SourcesDrvDir( sAppNm )
	string  	sVersion		= RetrieveVersion( sSourcesDrvDir + ":" + sAppNm + ".ipf", sMarker )	// e.g.  'ksFP_VERSION'
	string  	sArchiveDir	= ArchiveDrvDir( sAppNm, sVersion )
	string  	sExeDir		= ReleaseExeDir( sAppNm )								// e.g. 'UserIgor:FPulse_SetupExe'
	string  	sReleaseOutDir	= ReleaseOutDir( sAppNm )								// e.g. 'UserIgor:FPulseOut'
	string  	sInstallDir		= InstallDir(  sAppNm )									// e.g. 'UserIgor:FPulse'
	string  	sDllDrvDir		= DllDrvDir()											// e.g. 'C:UserIgor:Dll'
	UFProj_BackupWorkingDir( sAppNm, sVersion, sArchiveDir, sSourcesDrvDir, sSomeComDir, lstUserFiles )
	PossiblyProcessXops( kRLXP_COPY, ksXOP_DIR, lstPrefixXops,  sArchiveDir, sReleaseOutDir ) // copies the XOP sources into the newly created archive subdirectory e.g. into '...Archive...:UFCom_Utils'
	UFProj_ProjectRelease( sAppNm, sVersion, sArchiveDir, lstPrefixXops, lstPrefixIpfs, sDllDrvDir, sSourcesDrvDir, sSomeComDir, sExeDir, sReleaseOutDir, sInstallDir, lstDLLFiles, lstUserFiles, sApplSubDir, sAllUsersSubDir ) 
	UFProj_BackupAllTheRest( sAppNm, sVersion, sArchiveDir, sSourcesDrvDir, lstMoreBackups )	// Backup files (e.g. bmp, iss, ttf ) into the which are  NOT to be distributed to the user.
End


Function		UFProj_ProjectRelease( sAppNm, sVersion, sArchiveDir, lstPrefixXops, lstPrefixIpfs, sDllDrvDir, sSourcesDrvDir, sSomeComDir, sExeDir, sReleaseOutDir, sInstallDir, lstDllFiles, lstUserFiles, sApplSubDir, sAllUsersSubDir )
// ProjectRelease() must be executed by the programmer when a new  FPulse  version  is to be released
	string  	sAppNm, sVersion, sArchiveDir
	string  	lstPrefixXops									// double list of original and rename prefixes for XOP files and theirr C sourc files files 
	string  	lstPrefixIpfs									// double list of original and rename prefixes for Igor procedure files 
	string  	sDllDrvDir										// e.g. 'C:UserIgor:Dll'
	string  	sSourcesDrvDir
	string  	sSomeComDir									// for half-generic commons e.g.  'UFPE_'  which are common to FPulse and FEval  but not to SecuCheck and not to Recipes
	string  	sExeDir, sReleaseOutDir, sInstallDir
	string  	lstDllFiles 
	string  	lstUserFiles
	string  	sApplSubDir, sAllUsersSubDir
	
	string  	sSep		= ksXOPSEP
	variable	nXops	= ItemsInList( lstPrefixXops, sSep ) 
	if ( nXops )	// there may actually be more than nXops compilations, e.g. 5 compilations when nXops=3 
		DoAlert 0, "Make sure that the following XOP compilations give no errors. \rCheck the DOS boxes which will be created.\rSome warnings in xxxWinCustom.rc (Can not find file name) seem not to hurt.\r" 
	endif

	//  STEP 2 : For every version create an  ARCHIVE  subdirectory    e.g.  "C:UseIgor:Ced040315V235"    for the  Igor  and  C  source  files  on the hard disk and copy files into it.
	variable	nVersion			= str2num( sVersion ) 

	printf  "----- %s - Release() -----  will  build  release version %s  ( %s , %s ) \r", sAppNm, sVersion, Date(), Time()
	printf  "\tCreating directory '%s'  and copying files %s \r", sArchiveDir, lstUserFiles

	string  	sArchiveAllCommDir	= sArchiveDir + ":" + UFCom_ksDIR_COMMONS 	// has already been created and filled by BackupWorkingDir() ,  e.g. 'C:UserIgor:SecuTest040315V235:Commons'	 	
	string  	sArchiveSomeComDir	= sArchiveDir + ":" + sSomeComDir	 		// has already been created and filled by BackupWorkingDir() ,  e.g. 'C:UserIgor:SecuTest040315V235:CommonsFpFe'	 	

	// Copy specific application files from specific development directory into archive
	//UFCom_CopyFilesFromList( sSrcDir, lstUserFiles, sArchiveDir )					// Copy the current User files (e.g. ipf, ihf, xop..) into it
if ( strlen( lstDllFiles ) )
	UFCom_CopyFilesFromList( sDllDrvDir, lstDllFiles, 	sArchiveDir )					// Copy the 4 DLLs from 'C:UserIgor:Ced'  into the  Archive-Release directory 
endif
  	string  	sInstalledPrgChkFile	= sArchiveDir + ":" + sAppNm + ".ipf"				// it is sufficient for only 1 file (e.g. 'FPulse.ipf' or 'FEval.ipf') to loose its  true time...
	UFCom_ModifyFileTime( sInstalledPrgChkFile, nVersion, UFCom_FALSE )			// ...the hour:minute will be the version


	//  STEP 3 : Create  the  RELEASE / INSTALLATION  directory  e.g. 'FPulseOut'  or  'FEvalOut'  from which Inno-Setup takes the files to build  'FPulse / FEval xxx Setup.exe'  which is distributed to the user. 
	//  We need an extra (temporary) directory as 1. InnoSetup cannot access 'This' (currently executing) file in the working dir  and as  2.  UF_Test.ipf  must be replaced by  a  wrapper file   
	// Copy from the newly created archive to the release HD directory (or to a CD-Rom)
	string  	sTmpDrive 	= ksMY_DRIVE
	string  	sOutDir		= sTmpDrive + sReleaseOutDir
	printf  "\tCreating temporary directory  '%s'  and copying files  %s  .  InnoSetup will get its files from there. \r", sOutDir, lstUserFiles

	// First clean the temporary folder
if ( strlen( sOutDir ) )	// 2009-03-17
	DeleteFolder  /Z  sOutDir												// Clean the directory e.g. 'C:UserIgor:FPulseOut' .  THIS ALSO REMOVES SUBDIRECTORIES e.g. DLL. DemoScripts (which is desired)
	if ( V_Flag )
		printf "++++Error: Could not Delete Folder\tTo enable DeleteFolder, open the Miscellaneous Settings Dialog's Misc category \r\t\tand check the 'Enable DeleteFolder, CopyFolder/O and MoveFolder/O  commands'  checkbox.  Or select: 'Always give permission' \r"
	endif
	UFCom_PossiblyCreatePath( sOutDir )										// Create  directory	e.g.	 'C:UserIgor:FPulseOut'	 
endif

	// Complile   the XOPS in the RELEASE mode and copy then into the release Dir (this overwrites DEBUG XOPS which have been unnecessarily (in lstUserFiles!) copied there a moment ago)
	// Compiling the XOP  automatically per command  ensures that  the  XOP distributed to the user is compiled in  RELEASE  mode 
	PossiblyProcessXops( kRLXP_DELETE,  ksXOP_DIR, lstPrefixXops, "", sReleaseOutDir ) // Delete the archive subdirectory containing the XOP sources e.g.  'C:UserIgor:Xops:UFe1_Utils'  or  'C:UserIgor:Xops:UFp2_Cfs'  
	PossiblyProcessXops( kRLXP_RENAME, ksXOP_DIR, lstPrefixXops, "", sReleaseOutDir ) // Copy and rename the 'Common' sources from e.g. 'C:UserIgor:Xops:UFPE_Cfs:'  into  'C:UserIgor:Xops:UFp2_Cfs:'  
	PossiblyProcessXops( kRLXP_COMPILE, ksXOP_DIR, lstPrefixXops, "", sReleaseOutDir ) // Compile ALWAYS in RELEASE mode and copy the xop into e.g. 'C:UserIgor:FPulseOut'


	// Process specific application files ( e.g.  ipf, ihf, xop, txt  from   UserIgor:FPulse_ )
	UFCom_CopyFilesFromList(    sArchiveDir, 		   lstUserFiles, sOutDir )					// Copy the current User files (e.g. ipf, xop..)  from the msin archive folder into the one-and-only release output dir. Do NOT copy .iss, .bmp
	if ( strlen( sSomeComDir ) )														// FPulse and FEval have files in the common, but SecuCheck has none
		UFCom_CopyFilesFromList(    sArchiveSomeComDir, lstUserFiles, sOutDir )				// Copy the current User files (e.g. ipf, xop..)  from the  archive subfolder  into the one-and-only release output dir. Do NOT copy .iss, .bmp
	endif
	UFCom_CopyFilesFromList(    sArchiveAllCommDir,  lstUserFiles, sOutDir )					// Copy the current User files (e.g. ipf, xop..)  from the  archive subfolder  into the one-and-only release output dir. Do NOT copy .iss, .bmp

	// Process Ced-Common files  from   'UserIgor:CommonsFpFe' . The User  will get  copies of  'Commons'  and  'Ced-Commons'  files for each  project in his project directory (no subdirectories).  
	// All comments and debug print statements are removed from the Igor procedure files
	UFCom_CopyStripComments_( sOutDir, "UF*.ipf" )									// Only copy and strip comments from files like UF*.ipf,  do NOT process any other files like 'FP*.ipf. Project*.ipf...

	// The Igor procedure file names and the functions inside are renamed so that different projects may coexist 
	variable	d, nDirs	= ItemsInList( lstPrefixIpfs, sSep )
	for ( d = 0; d < nDirs; d += 1 )
		string  	lstDirPreFixes	= StringFromList( d,  lstPrefixIpfs, sSep )					// e.g. 'UFPE_;UFp2_'
		string  	sDirPreFixOrg	= StringFromList( 0,  lstDirPrefixes )						// e.g. 'UFPE_'
		string  	sDirPreFixRenm	= StringFromList( 1,  lstDirPrefixes )						// e.g. 'UFp2_'   or  '' (empty )
		if ( strlen( sDirPreFixRenm ) )
			UFCom_ReplaceModuleNames_( sDirPreFixOrg,  sDirPreFixRenm, sOutDir, "*.ipf" ) 	// ...but once in the temporary directory we can rename ALL files and copy them to 'sOutDir' e.g. 'UserIgor:FPulseOut' 
		endif
	endfor

	// Process specific application files and  common files.
	UFCom_ModifyFileTimeFromList( sOutDir, lstUserFiles, nVersion, UFCom_FALSE )				// OK : ALL files in the temporary release dir loose their true time: the hour:minute will be the version  

	// Process DLLs
	if ( strlen( lstDllFiles ) )
		UFCom_PossiblyCreatePath( sOutDir + ksDLL_DIR  )								// Create  directory e.g. 'C:Userigor:FEval_Out:Dll' . Do  NOT clear it (has been done above) as clearing an empty subdir would clear the 'sOutDir'
		UFCom_CopyFilesFromList( sArchiveDir,	 lstDllFiles, sOutDir + ksDLL_DIR )			// Copy the 4 DLLs to the temporary dir
	endif
	
	// Process subdirectories in the application directory.  Writing files there requires administrative privileges during run-time .  Files could be e.g. DemoScripts or Databases
	if ( strlen( sApplSubDir ) )
		UFCom_PossiblyCreatePath( sOutDir + ":" + sApplSubDir  )							// Create  directory e.g. 'C:UI:FPulse_Out:DemoScripts' . Do  NOT clear it (has been done above) as clearing an empty subdir would clear the 'sOutDir'
		UFCom_CopyFilesFromList( ksMY_DRIVE + SourcesDir( sAppNm ) + ":" + sApplSubDir, "*.*", sOutDir + ":" + sApplSubDir )	// e.g. copy some DemoScripts in FPulse
	endif

	// Process subdirectories in the 'All Users' directory.  Any non-privileged user may writing files there during run-time .  Files could be e.g. DemoScripts or Databases
	if ( strlen( sAllUsersSubDir ) )
		UFCom_PossiblyCreatePath( sOutDir + ":" + sAllUsersSubDir  )						// Create  directory e.g. 'C:UI:FPulse_Out:DemoScripts' . Do  NOT clear it (has been done above) as clearing an empty subdir would clear the 'sOutDir'
		UFCom_CopyFilesFromList( UFCom_AllUsersDirPath() + ":" + sAllUsersSubDir, "*.*", sOutDir + ":" + sAllUsersSubDir )	// e.g. copy the publich database in SecuTest
	endif

// 2009-10-29 b
//	// Copy an empty wrapper file to the user release rather than the real files  in those cases where the real files are not to be distributed. Workaround as Igor does not allow conditional compilation.
//	// if ( UFCom_FileExists( sArchiveDir + ":" + "UF_Wrapper.ipf" ) )
//// 2009-10-29 a
////		UFCom_Copy1File( sArchiveDir + ":" + "UF_Wrapper.ipf", sOutDir +  ":" + "UF_AcqTest3.ipf" )
//		UFCom_DeleteFiles( sOutDir, "UF_Wrapper.ipf" )
//	// endif


// 2007-0822 remove TT  but  keep  an empty string  'sBirthFile->sBirthFile_Unused'  as a dummy parameter to  'CallInno -> Execute ISCC.exe'...   which can be used should need arise to introduce another optional InnoSetup parameter
	string  	sBirthFile_Unused = ""

	string  	sReleaseExeForUser	= ksMY_DRIVE + sExeDir  + ":" + sAppNm + " " + sVersion +  " Setup.exe"	// !!! must be same file path as InnoSetup constructs it
	string  	sSourcesDir		= SourcesDir( sAppNm )

	CallInno( sVersion, ksMY_DRIVE, sSourcesDir, sAppNm, sReleaseOutDir, sExeDir, sInstallDir, sBirthFile_Unused, sApplSubDir, sAllUsersSubDir, lstDLLFiles, lstUserFiles )	// will build a 'Release' version no matter which version is defined in Igor

	printf "Finished :\tCreated source files archive \t'%s'  \r\t\tCreated release version \t\t'%s'  \r ", sArchiveDir, sReleaseExeForUser

End


//==================================================================================================================
// 		 BIG  HELPERS
//==================================================================================================================

Function		PossiblyProcessXops( nAction, sSourceDir, lstPrefixXops, sArchiveDir, sReleaseOutDir ) 
//  ALL XOP PROCESSING in 1 function: Neither the names nor the number of Xops have to be listed here.   ALL  Xops in a subdirectory are processed.
// Possible improvement: defining 'nAction' as a bit pattern would allow to execute multiple actions with 1 call...
	variable	nAction							// e.g. Copy  Rename  Compile  Create link  Remove link  Delete	
	string  	sSourceDir						// e.g. 'UserIgor:Xops'		
	string  	lstPrefixXops						// e.g. 'UFCom_;UFp1_^UFPE_;UFp2_^UFP_'	
	string  	sArchiveDir						// e.g. 'C:UserIgor:ArchiveFPulse:FPulse070315_1200v401'
	string  	sReleaseOutDir						// e.g. 'UserIgor:FPulseOut'  or  'UserIgor:FEvalOut'
	string  	sSep		= ksXOPSEP				// e.g. '^'
	string  	sText	= UFCom_pd( StringFromList( nAction, ksRLXP_NAMES ), 10 )			// e.g. 'Copy',   'Rename'  ...
	variable	d, nDirs	= ItemsInList( lstPrefixXops, sSep )
	for ( d = 0; d < nDirs; d += 1 )
		string  	lstDirPreFixes	= StringFromList( d,  lstPrefixXops, sSep )					// e.g. 'UFPE_;UFp2_'
		string  	sDirPreFixOrg	= StringFromList( 0,  lstDirPrefixes )						// e.g. 'UFPE_'
		string  	sDirPreFixRenm	= StringFromList( 1,  lstDirPrefixes )						// e.g. 'UFp2_'   or  '' (empty )
		string  	sDriveSrcDir	= ksMY_DRIVE + sSourceDir
		string 	lstDirs		= UFCom_ListOfMatchingDirs( sDriveSrcDir, sDirPreFixOrg + "*", 0 )// e.g. 'UFP_Ced;UFP_Mc700'
		variable	n
		for ( n = 0; n < ItemsInList( lstDirs ); n +=1 )	
			string  	sDir	= StringFromList( n, lstDirs )									// e.g. 'UFP_Ced'  or  'UFP_Mc700'
			string  	sXopSrcDir	= sDriveSrcDir + ":" + sDir 							// e.g. 'C:UserIgor:Xops:UFP_Ced'  
			string  	sXopXopPath	= sDriveSrcDir + ":" + sDir + ":Debug" + ":" + sDir + ".xop"	// where Visual C puts the Xop be default e.g. 'C:UserIgor:Xops:UFP_Ced:Debug:UFP_Ced.xop'
			string  	sXopRenmDir	= SelectString( strlen( sDirPreFixRenm ) ,  "" , ReplaceString(  sDirPreFixOrg, sXopSrcDir, sDirPreFixRenm ) )
			string  	sInfo
			sprintf sInfo, "\tPossiblyProcessXops(\t%s )\tDir:%d/%d\tn:%d\tDir: %s\tOrg:\t%s\tRen:\t%s\tSrcD:\t%s\tXop:\t%s\tRnD:\t%s\tArD:\t'%s' ", sText, d, nDirs, n, UFCom_pd(sDir,13),  UFCom_pd(sDirPreFixOrg,7),  UFCom_pd(sDirPreFixRenm,7),  UFCom_pd( sXopSrcDir,24),  UFCom_pd(sXopXopPath, 36),  UFCom_pd(sXopRenmDir, 24), sArchiveDir
			printf "%s\r", sInfo[0,396]
			switch( nAction )
				case	kRLXP_COPY:
					string  sArchiveSubDir = sArchiveDir + ":" + sDir
					UFCom_PossiblyCreatePath( sArchiveSubDir )							// Create  subdirectory within archive	e.g.	'C:UseIgor:ArchiveFPulse:FPulse040315V235:UFCom_Utils'
					UFCom_CopyFilesFromList( sXopSrcDir, ksXOP_SOURCE_FILES + ksXOP_LIB_FILES, sArchiveSubDir )	// Copy the RELEASE XOP sources into the archive subdirectory 
					break
				case	kRLXP_RENAME:
					if ( strlen( sDirPreFixRenm ) )										// only common funstions must be renamed, specific application functions keep their name
						UFCom_ReplaceModuleNamesFromLst(  sDirPreFixOrg, sDirPreFixRenm, sXopSrcDir, sXopRenmDir, ksXOP_SOURCE_FILES ) 
						UFCom_CopyFilesFromList( sXopSrcDir, ksXOP_LIB_FILES, sXopRenmDir )	// Copy the library files (e.g. 'Cfs32.lib'  the renamed Xop sources subdirectory, as the compiler expects them there. We can NOT 'Rename' the library binary file! 
					endif
					break
				case	kRLXP_COMPILE:
					string  	sCompileDir	= SelectString( strlen( sDirPreFixRenm ) , sXopSrcDir, sXopRenmDir )
					CallXOPCompiler_( sCompileDir )
// 2008-07-01
//					UFCom_CopyFilesFromList( sCompileDir + ":Release", "*.xop", "C:" + sReleaseOutDir )// Copy the RELEASE XOP into the release Dir 
//if ( n==0|| n==2||n==4)
//					UFCom_CopyFilesFromList( sCompileDir + ":Release", "*.xop", "C:" + sReleaseOutDir )// Copy the RELEASE XOP into the release Dir 
//else
					UFCom_CopyFilesFromList( sCompileDir + ":Release", "*.xop", ksMY_DRIVE + sReleaseOutDir )// Copy the RELEASE XOP into the release Dir 
//endif
					break
				case kRLXP_CREATELINK:
					UFCom_CreateAlias( sXopXopPath,  ksXOP_LNK + ":" + sDir + ".xop" + ".lnk" )	// We must keep the  '.xop'  in the link file name to stay compatible with the InnoSetup naming
					break
				case	kRLXP_REMOVELINK:
					UFCom_DeleteLinks( ksXOP_LNK,  sDir + ".xop" + ".lnk" )	
					break
				case	kRLXP_DELETE: 
if ( strlen( sXopRenmDir ) )	// 2009-03-17
					DeleteFolder  /Z  sXopRenmDir										// Remove the renamed XOP dir  e.g. 'C:UserIgor:Xops:UFe1_Utils'  or  'C:UserIgor:Xops:UFp2_Cfs'  
					if ( V_Flag )
						printf "++++Error: Could not Delete Folder '%s' \tTo enable DeleteFolder, open the Miscellaneous Settings Dialog's Misc category \r\t\tand check the 'Enable DeleteFolder, CopyFolder/O and MoveFolder/O  commands'  checkbox.  Or select: 'Always give permission' \r", sXopRenmDir
					endif
endif
   					break
				default:
					printf "Error: PossiblyProcessXops(\tIllegal action %d . Allowed are 0...%d  [%s] \r", nAction, ItemsInList( ksRLXP_NAMES ) - 1, ksRLXP_NAMES
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
// 2007-0224 do not delete LIB files.  We need  UFBd_LibBd.lib ! )	
//	UFCom_DeleteFilesFromList( sXopRenmDir + ":Debug",	ksXOP_DELETE_FILES + ksXOP_LIB_FILES )	// Delete  OBJ,  PCH,  PDB.... + LIB.
//	UFCom_DeleteFilesFromList( sXopRenmDir + ":Release",	ksXOP_DELETE_FILES + ksXOP_LIB_FILES )	// Delete  OBJ,  PCH,  PDB...  + LIB
	UFCom_DeleteFilesFromList( sXopRenmDir + ":Debug",	ksXOP_DELETE_FILES ) 	// Delete  OBJ,  PCH,  PDB....
	UFCom_DeleteFilesFromList( sXopRenmDir + ":Release",	ksXOP_DELETE_FILES ) 	// Delete  OBJ,  PCH,  PDB... 
End

//----------------------------------------------------------------------------
Function		DeleteXopJunk()
	DelXJ( ksMY_DRIVE, ksXOP_DIR, ksXOP_DELETE_FILES )	// will delete any garbage files e.g. in 'C:UserIgor:Xops'  and in all subdirectories ( 1 level  + another level 'Debug' and 'Release')
//	DelXJ( ksMY_DRIVE, ksXOP_DIR + ":c_ok_or_old_or_gn", ksXOP_DELETE_FILES )	// will delete any garbage files e.g. in 'C:UserIgor:Xops'  and in all subdirectories ( 1 level  + another level 'Debug' and 'Release')
End

Function		DelXJ( sDrive, sDir, lstDelFiles )	
// will delete any garbage files e.g. in 'C:UserIgor:Xops'  and in all subdirectories ( 1 level  + another level 'Debug' and 'Release')
	string  	sDrive, sDir, lstDelFiles
	string  	lstDirs	= UFCom_ListOfMatchingDirs( sDrive + sDir, "*", FALSE )	// *.* : list all dirs ,  False: supply only partial path
	variable	n, nDirs	= ItemsInList( lstDirs )
	for ( n = 0; n < nDirs; n += 1 )
		string  sXopSubDir	= StringFromList( n, lstDirs )
		string	  sXopPath	= sDrive + sDir + ":" + sXopSubDir
		printf "\t\tDelXJ( %s %s ) will delete %s in \t%s\t (and in Debug + Release) \r",  sDrive, sDir, lstDelFiles, UFCom_pd( sXopPath, 31)
		UFCom_DeleteFilesFromList( sXopPath, 			ksXOP_DELETE_FILES + "*.ncb;*.aps;" )	// Delete  OBJ,  PCH,  ...
		UFCom_DeleteFilesFromList( sXopPath + ":Debug",	ksXOP_DELETE_FILES + "*.pdb;"	 ) 	// Delete  OBJ,  PCH,  ....
		UFCom_DeleteFilesFromList( sXopPath + ":Release",	ksXOP_DELETE_FILES + "*.pdb;"	 ) 	// Delete  OBJ,  PCH,  ... 
	endfor
End	
//----------------------------------------------------------------------------


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

Function	CheckEditReleaseSetting( sAppNm, sMarkerFlag )
	string  	sAppNm
	string  	sMarkerFlag								// e.g.  'ksFP_VERSION'  or  'ksEV_VERSION'
	string  	sSrcDir	= SourcesDrvDir( sAppNm )			// e.g. 'C:UserIgor:FPulse_'
	string  	sVersion	= RetrieveVersion( sSrcDir  + ":" + sAppNm + ".ipf", sMarkerFlag)	
	CheckReleaseSetting( sAppNm, sVersion )
	UFCom_OfferForEdit( sSrcDir, 	sAppNm + ".ipf" )			// display the procedure window containing the version and bring it to the front, so the version can be incremented before releasing
End

Function	CheckReleaseSetting( sAppNm, sVersion )
	string  	sAppNm, sVersion
	printf  "\r\tCurrent settings for  '%s' :   Version %s\r", sAppNm, sVersion
End


//==================================================================================================================
// Call  INNO setup to build the exe file distributed to the user
//==================================================================================================================

// 2008-07-01 THIS OLD VERSION DOES NOT ALLOW SPACES   like in 'Program files'  or in 'Inno Setup 5'
//
//static  Function		CallInno( sVers, sDrive, sPrgDir, sAppNm, sReleaseSrcDir, sSetupExeDir, sInstallationDir, sBirthFile, sApplSubDir, sAllUsersSubDir, lstDLLFiles, lstUserFiles )
//	string  	sVers, sDrive, sPrgDir, sAppNm, sReleaseSrcDir, sSetupExeDir, sInstallationDir, sBirthFile, sApplSubDir, sAllUsersSubDir, lstDLLFiles, lstUserFiles
//
//	//  Cave: 1: Must be modified for Win 98 or other Windows versions  ('cmd.exe'  may change)
//	//  Cave: 2. The  keywords  'Vers, ODir, Birth, Src, Msk'  must be the same as in  'FPulse.iss'  !
//	//  Cave: 3: Inno's  default installation path must be changed so that it does not contain spaces ('Inno Setup 4' -> 'InnoSetup4' , or even 'Inno4' to save some bytes)
//	//  Cave: 4: The workaround using an explicit call to  'cmd.exe  /K '  is needed so that the DOS window possibly containing error messages is not immediately closed.
//
//// 2007-0212a	 Innosetup5 mutters about fpulse.iss line 359 Instexec not known
////	string  	sCmd 	= "cmd.exe /K " + "D:\\Programme\\InnoSetup4\\iscc.exe" + " "// also works without 'cmd.exe /K'  but then closes DOS window immediately  so that errorr messages cannot be read	
//
//string  	sCmd 	= "cmd.exe  /K  "  +  "C:\\InnoSetup5\\iscc.exe" + " "	
//	//   cmd /c " "c:\path with\spaces\binary" "arg" "  works but  /dAppnm=... gives Error
//
//
//	string  	sMyPrgDir	= ReplaceString(  ":" , sPrgDir, "\\" )
// 	string  	sIssScript 	= sDrive + "\\" + UFCom_ksUSERIGOR_DIR + "\\" +UFCom_ksDIR_COMMONS+ "\\" + "Generic.iss"	// e.g.  'C:\UserIgor\Commons\Generic.iss'
//	
//	string  	sAppNam	= "\"/dAppNm=" 	+ sAppNm + "\""	
//
//	string  	sVersion	= "\"/dVers=" 		+ sVers 	+ "\""	
//
//	string  	sOutDir	= ReplaceString(  ":" , sReleaseSrcDir, "\\" )				// where InnoSetup gets the FPulse source files
//	string  	sSrc		= sDrive + "\\" + sOutDir								// where InnoSetup gets the FPulse source files , e.g. 'C:\UserIgor\FPulseOut' . CANNOT be the working dir 'C:\UserIgor\Ced' !
//	string  	sSource	= "\"/dSrc=" 		+ sSrc 		+ "\""	
//	
//	string  	sMask	= "\"/dMsk=" 		+ sSrc 		+ "\\*.*"	 + "\""
//	
//	string  	sOut		= sDrive  + "\\" + ReplaceString(  ":" , sSetupExeDir, "\\" )		//  Convert to Win style. Where InnoSetup puts  'FPulse xxx Setup.exe' , e.g. 'C:\UserIgor\Ced\FPulseSetupExe'
//	string  	sOutputDir	= "\"/dODir=" 		+ sOut 		+ "\""		
//	
//	string  	sDDir	= sDrive  + "\\" + ReplaceString(  ":" , sInstallationDir, "\\" )		//  Convert to Win style. Where InnoSetup will  unpack and install   FPulse , e.g. 'C:\UserIgor\FPulse
//	string  	sDefaultDir= "\"/dDDir=" 		+ sDDir 		+ "\""		
//
//	string  	sBirth	= SelectString( strlen(sBirthFile),  "",  "\"/dBirth=" + sBirthFile + "\"" )// If birthfile is empty (=unlimited version)  then omit the parameter '/dBirth=' on the command line altogether	
//
//	string  	sApSubDir	= SelectString( strlen(sApplSubDir),  "",     "\"/dApSubDir=" 	+ ReplaceString(":",sApplSubDir,"\\")    + 	"\"" )// If 'sApplSubDir' is empty then omit the parameter '/dApSubDir=' completely.
//
//	string  	sAUSubDir= SelectString( strlen(sAllUsersSubDir), "", "\"/dAUSubDir="	+ ReplaceString(":",sAllUsersSubDir,"\\") +	"\"" )// If 'sAllUsersSubDir' is empty then omit the parameter '/dAUSubDir=' completely.
//
//	string  	sDLLs	= SelectString( strlen(lstDLLFiles), "", "\"/dDLLs=" + "*.dll" + "\"" )// If list of DLLs is empty then omit the parameter '/dDLLs=' completely. 
//
//	// Check if there are fonts to be distributed : check if 'lstUserFiles' contains the entry '.ttf'  (or prehaps more stringent '*.ttf;')  .
//	// Better:  Check if there are actually fonts in  the Out-directory.  'lstUserFiles' might contain '*.ttf'  while actually there are no fonts (this is not detected earlier...???) 
//	string  	sFonts	= SelectString( strsearch( lstUserFiles, ".ttf", 0 ) >= 0  , "",  "\"/dFonts=" + "*.ttf" + "\"" )	// If there are no fonts then omit the parameter '/dFonts=' completely. 
//	
//	string  	sLink2Dir	= "\"/dLinkToDir=" 	+ ksLINK2DIR 	+ "\""				//  the prefix which InnoSetup prepends the link to a directory
//
//	string  	sStr 		= sCmd  + sIssScript + " " + sAppNam + " " + sVersion + " " + sSource + " " + sMask + " " + sOutputDir + " " + sDefaultDir + " " + sBirth + " " + sApSubDir + " " + sAUSubDir + " " + sDLLs + " " + sFonts + " " + sLink2Dir 
//	printf "\t%s   \r", sStr
//	ExecuteScriptText  sStr
//End


// 2008-07-01 THIS NEW VERSION ALLOWS  SPACES   like in 'Program files'  or in 'Inno Setup 5'
static  Function		CallInno( sVers, sDrive, sPrgDir, sAppNm, sReleaseSrcDir, sSetupExeDir, sInstallationDir, sBirthFile, sApplSubDir, sAllUsersSubDir, lstDLLFiles, lstUserFiles )
	string  	sVers, sDrive, sPrgDir, sAppNm, sReleaseSrcDir, sSetupExeDir, sInstallationDir, sBirthFile, sApplSubDir, sAllUsersSubDir, lstDLLFiles, lstUserFiles

	//  Cave: 1: Must be modified for Win 98 or other Windows versions  ('cmd.exe'  may change)
	//  Cave: 2. The  keywords  'Vers, ODir, Birth, Src, Msk'  must be the same as in  'FPulse.iss'  !
	//  Cave: 3: Inno's  default installation path must be changed so that it does not contain spaces ('Inno Setup 4' -> 'InnoSetup4' , or even 'Inno4' to save some bytes)
	//  Cave: 4: The workaround using an explicit call to  'cmd.exe  /K '  is needed so that the DOS window possibly containing error messages is not immediately closed.

	// also works without 'cmd.exe /K'  but then closes DOS window immediately  so that error messages cannot be read	

	string  	sCmd 	= "cmd.exe  /K  "  +	"\" "  +  "\"C:\\Program files\\Inno Setup 5\\iscc.exe\"" + " "	// special syntax ! e.g.  [ cmd /c " "c:\path with\spaces\binary" "arg" " ]
	
	string  	sMyPrgDir	= ReplaceString(  ":" , sPrgDir, "\\" )

 	string  	sIssScript 	= "\"" + sDrive + "\\" + UFCom_ksUSERIGOR_DIR + "\\" +UFCom_ksDIR_COMMONS+ "\\" + "Generic.iss\""	// e.g.  'C:\UserIgor\Commons\Generic.iss'
	
	string  	sAppNam	= "\"/dAppNm=" 	+ sAppNm + "\""	
	
	string  	sVersion	= "\"/dVers=" 		+ sVers 	+ "\""	

	string  	sOutDir	= ReplaceString(  ":" , sReleaseSrcDir, "\\" )				// where InnoSetup gets the FPulse source files
	string  	sSrc		= sDrive + "\\" + sOutDir								// where InnoSetup gets the FPulse source files , e.g. 'C:\UserIgor\FPulseOut' . CANNOT be the working dir 'C:\UserIgor\Ced' !
	string  	sSource	= "\"/dSrc=" 		+ sSrc 		+ "\""	
	
	string  	sMask	= "\"/dMsk=" 		+ sSrc 		+ "\\*.*"	 + "\""
	
	string  	sOut		= sDrive  + "\\" + ReplaceString(  ":" , sSetupExeDir, "\\" )		//  Convert to Win style. Where InnoSetup puts  'FPulse xxx Setup.exe' , e.g. 'C:\UserIgor\Ced\FPulseSetupExe'
	string  	sOutputDir	= "\"/dODir=" 		+ sOut 		+ "\""		
	
	string  	sDDir	= sDrive  + "\\" + ReplaceString(  ":" , sInstallationDir, "\\" )		//  Convert to Win style. Where InnoSetup will  unpack and install   FPulse , e.g. 'C:\UserIgor\FPuls
	string  	sDefaultDir= "\"/dDDir=" 		+ sDDir 		+ "\""		

	string  	sBirth	= SelectString( strlen(sBirthFile),  "",  "\"/dBirth=" + sBirthFile + "\"" )// If birthfile is empty (=unlimited version)  then omit the parameter '/dBirth=' on the command line altogether	

	string  	sApSubDir	= SelectString( strlen(sApplSubDir),  "",     "\"/dApSubDir=" 	+ ReplaceString(":",sApplSubDir,"\\")    + 	"\"" )// If 'sApplSubDir' is empty then omit the parameter '/dApSubDir=' completely.

	string  	sAUSubDir= SelectString( strlen(sAllUsersSubDir), "", "\"/dAUSubDir="	+ ReplaceString(":",sAllUsersSubDir,"\\") +	"\"" )// If 'sAllUsersSubDir' is empty then omit the parameter '/dAUSubDir=' completely.

	string  	sDLLs	= SelectString( strlen(lstDLLFiles), "", "\"/dDLLs=" + "*.dll" + "\"" )// If list of DLLs is empty then omit the parameter '/dDLLs=' completely. 

	// Check if there are fonts to be distributed : check if 'lstUserFiles' contains the entry '.ttf'  (or prehaps more stringent '*.ttf;')  .
	// Better:  Check if there are actually fonts in  the Out-directory.  'lstUserFiles' might contain '*.ttf'  while actually there are no fonts (this is not detected earlier...???) 
	string  	sFonts	= SelectString( strsearch( lstUserFiles, ".ttf", 0 ) >= 0  , "",  "\"/dFonts=" + "*.ttf" + "\"" )	// If there are no fonts then omit the parameter '/dFonts=' completely. 
	
	string  	sLink2Dir	= "\"/dLinkToDir=" 	+ ksLINK2DIR 	+ "\""				//  the prefix which InnoSetup prepends the link to a directory

	string  	sStr 		= sCmd + sIssScript + " " + sAppNam + " " + sVersion + " " + sSource + " " + sMask + " " + sOutputDir + " " + sDefaultDir + " " + sBirth + " " + sApSubDir + " " + sAUSubDir + " " + sDLLs + " " + sFonts + " " + sLink2Dir + " \""
	printf "\t%s   \r", sStr
	printf "CLOSE  THE DOS BOX AFTER INNOSETUP HAS FINISHED (only this will return to Igor) !\r"
	ExecuteScriptText  sStr
End

