//=====================================================================================================================================
//	ProjectsFPulse.ipf	for   FPulse
//		Procedures to  Backup  the current  development version,  to deinstall it  and to  create a  release version for the user.
//=====================================================================================================================================
//
//	THIS FILE IS FOR THE DEVELOPER ONLY.  IT IS NOT TO BE DISTRIBUTED TO THE USER !
//
//	!!!	Uses and requires files from   UserIgor:Commons  
//	The link to the directory of this file (UserIgor:Commons) must always stay active.
// 	This does not lead to linker errors (function exists already) when User releases are installed because the User Commons function are auto-renamed to avoid naming conflicts

//	This program  makes a Release Version of  FPulse. The programmer must have set the constant  ksVERSION in FPulse.ipf
//	InnoSetup is used to create the Release version of FPulse as an self-extracting  EXE file.

//	Cave:
//	In the user version  the links point to the release directory   UserIgor:FPulse   instead of the develop directory  UserIgor:FPulse_
//	For this reason one MUST deinstall  'FPulse/FEval'   when switching from a development version  to an InnoSetup-created Release version.
//	See  SwitchFPulseVersions.txt  for a more detailed description.
//	OR (easier)
//		install Release verssion on a different computer

//	Cave:
//	The name pf this function must NOT start with   'UF...'   or  'F...'   as these function groups are those released to the user....

//	 Before Releasing  make sure that ...
// 		-  that the 5  XOPs  are also compiled in the  'Release'  mode. ( 'FP*.xop' )
//		-  FPulse  is started at least once after help file changes so that the Help files are compiled
//
//
//	Cave:
// 		We must ensure that when creating and deleting a link file the naming is the same in Igor-Development/Debug mode and in InnoSetup-Release mode
//			The convention is to keep the original extension and appending  '.lnk'  e.g.  'UFCom_Utils.xop.lnk'  or  'FPulse.ipf.lnk'

//	Rev Hist
//		 07 Jan-Feb   revamped completely 

#pragma rtGlobals=1						// Use modern global access method.
#pragma IgorVersion=5.02					// GetFileFolderInfo

#include "UFCom_Constants"

#include "ProjectsCommons"		


//=====================================================================================================================================
//	 MAIN MENU ENTRY

// 2010-02-13	convert multiple  'Project-AppX'  main menu entries to multiple submenus in one main menu 'Project'  entry.
//Menu   "Projects-FPulse", dynamic
Menu   "Projects", dynamic
	Submenu   "FPulse3"
		// Disable menu items not applicable when the developer is in Release mode for testing.  The user will never get this menu anyway.
		SelectString( FP3_IsReleas()  ||  ! FP3_IsLoaded() , "" , "(" ) +"Backup this FPulse3  " 				+ SelectString( FP3_IsLoaded() , "[not loaded]" , "" ) ,	BackupFPulse()				// 
													"Backup this FPulse3 and then deinstall it   " ,			DeInstallFPulse()			
		"-------------------------------------------------------------"
		SelectString( FP3_IsReleas()  ||  ! FP3_IsLoaded() , "" , "(" ) +"Check release settings   "			 	+ SelectString( FP3_IsLoaded() , "[not loaded]" , "" ),	CheckEditReleaseSetting_FPulse()
		SelectString( FP3_IsReleas()  ||  ! FP3_IsLoaded() , "" , "(" ) +"Backup this FPulse3 and  create Release   "+ SelectString( FP3_IsLoaded() , "[not loaded]" , "" ),	CreateRelease_FPulse()
		"-------------------------------------------------------------"
													"Revert to previous FPulse3 development version ",				InstallFPulse()				
		"-------------------------------------------------------------"
													"Delete any Xop junk [obj, res, pch, ncb..]"	,				DeleteXopJunk()
	End
End

// The automatic enabling and disabling of menu items is very nice but slows down the machine, as the menus are rebuilr by Igor quite often
 Function		FP3_IsReleas()								// cannot be static
	string  	sPossibleFuncPath	=  FunctionPath( "UFp1_pd" )	// !!! Assumption  'UFp1_'
	variable	bIsRelease		=  strlen( sPossibleFuncPath ) > 1// when not found (in Debug mode)  the function path may be empty ''  or may be a single colon ':'
	// printf "\t\tFP3_IsReleas()   \tFunctionPath(\t'UFp1_pd'\t\t): -> Is Release:\t%d \t'%s'   (strlen > 1) \r",  bIsRelease, sPossibleFuncPath
	return 	bIsRelease 								// path may be empty or ':'  if not found.  Only  if the function  'UFp1_pd()'  exists we are in Release mode.  In Debug mode its name is  'UFCom_pd()'
End

 Function		FP3_IsLoaded()								// cannot be static
	string  	sPossibleFuncPath	=  FunctionPath( "FPulse" )		// !!! Assumption  function name = application name
	variable	bIsLoaded			=  strlen( sPossibleFuncPath ) > 1// when not found (in Debug mode)  the function path may be empty ''  or may be a single colon ':'
	// printf "\t\tFP3_IsLoaded()\tFunctionPath(\t'FPulse'  \t\t): -> Is Loaded:\t%d \t'%s'   (strlen > 1) \r",   bIsLoaded, sPossibleFuncPath
	return 	bIsLoaded 								// path may be empty or ':'  if not found.  Only  if the function  'FPulse()'  exists have started the application
End


//=====================================================================================================================================
//	FPulseE  APPLICATION SPECIFIC  CONSTANTS
//
//  	The files defined by these constants are required for building a release version  with InnoSetup.  The creation and removal of links during (de)installation is also controlled by these definitions.

static strconstant	ksAPPNAME			= "FPulse"								// Name of THIS_APPLICATION.  Is used  throughout the program as a base name for files and directories.
static strconstant	ksVERSION_MARKER	= "ksFP3_VERSION"						// this string is searched  LITERALLY  in FPulse.ipf to retrieve the version.  In this way we can process the application even if it is not loaded.

static strconstant	ksAPPL_SUBDIR		= "Scripts:DemoScripts" 					// applies to both source and target  e.g. 'C:UserIgor:FPulse_:DemoScripts'  ->   'F:UserIgor:FPulse:DemoScripts'   
static strconstant	ksALLUSERS_SUBDIR	= ""									// applies to both source and target: this subdirectory in 'All Users' on the development machine will be installed in 'All Users' in the target machine

// weg....
static strconstant	ksSOMECOM_DIR		= ""						// Special directory common to some but not all projects (e.g. only to FPulse and FEval) .  Can be empty.
static strconstant	klstMORE_BACKUPS	= "*.ipf;*.dll;"
static strconstant	klstUSER_FILES		= "UF*.ipf;FP*.ipf;F*.ihf;*.xop;F*.txt;*.rtf;*.bmp;"		// List of file groups to be distributed to the user.  Watch out not to distribute 'Projectxxx.ipf' .  Files are backed up.
static strconstant	klstHELP_FILES		= "FP*.ihf;"							// List of Help files distributed to the user and  linked to 'Igor Help files'.  Files are backed up. 
static strconstant	klstDLL_FILES			= "Cfs32.dll;Use1432.dll;1432ui.dll;AxMultiClampMsg.dll;"// List of DLLs distributed to the user.   Files are backed up.  Do not use *.dll as attributes are set for all these files in  Windows\System32

static strconstant	ksPF_IPF_ALLCOM		= "UFCom_;UFfp_;^"						// Prefixes for groups of IPF files common to this project. The second prefix replaces the first during releasing. 

//=====================================================================================================================================
//  XOP PROCESSING
//
//	The C sources for the Xops are  backed up and compiled ,  but  C_Common  is only backed up but not compiled separately
//	Neither the names nor the number of Xops have to be listed here.   ALL  Xops in a subdirectory are processed.
//	The Prefix of the Subdirectories is important, it determines HOW the  Xop is processed.  
//	UFCom_ : Xops applies to all Igor procedures,  UFP_: Xop applies only to FPulse.    
// 	XOP  files which are common to multiple projects are automatically 'project-renamed' when building a user release version.  These files AND links to these files are created and removed (only when a RELEASE is (de)installed)...
// 	Adding a new Xops requires no entry here, it is sufficient to place the Xop sources in the right subdirectory.
//	Assumptions:   The directory name is the same as the XOP name.

static strconstant	ksPF_XOP_COM		= "UFCom_;UFfp_;^"					// Prefixes for groups of C/XOP files for this project. The second prefix replaces the first during releasing. 
//static strconstant	ksPF_XOP			= "FP_;^"							// Prefixes for a group of C/XOP files specific to THIS_APPLICATION.  Can be empty.
static strconstant	ksPF_XOP			= "FP;^"							// Prefixes for a group of C/XOP files specific to THIS_APPLICATION.  Can be empty.


//=====================================================================================================================================
//	BACKUP   of the Development version

Function		BackupFPulse()
	string  	lstPrefixXops	= ksPF_XOP_COM + ksPF_XOP				
	UFProj_Backup( ksAPPNAME, ksVERSION_MARKER, lstPrefixXops, ksSOMECOM_DIR, klstUSER_FILES, klstMORE_BACKUPS )
End
	

//=====================================================================================================================================
//	DEINSTALLATION    of the Development version

Function		DeInstallFPulse()
	string  	lstPrefixXops	= ksPF_XOP_COM + ksPF_XOP		// e.g. 'UFCom_;UFp1_;'	
	UFProj_DeInstall( ksAPPNAME, ksVERSION_MARKER, lstPrefixXops, ksSOMECOM_DIR, klstUSER_FILES, klstMORE_BACKUPS, klstHELP_FILES, ksPF_XOP )
End


//=====================================================================================================================================
//	INSTALLATION   of the Development version

Function		InstallFPulse()
	string  	lstPrefixXops	= ksPF_XOP_COM + ksPF_XOP		// e.g. 'UFCom_;UFp1_;'		
	UFProj_Install( ksAPPNAME, klstDLL_FILES, lstPrefixXops, klstHELP_FILES  )
End


//=====================================================================================================================================
//	 RELEASING

Function		CreateRelease_FPulse()
	string  	lstPrefixXops	= ksPF_XOP_COM  + ksPF_XOP
	string  	lstPrefixIpfs	= ksPF_IPF_ALLCOM 				// double list of original and rename prefixes for Igor procedure files 
	UFProj_CreateRelease( ksAPPNAME, ksVERSION_MARKER, lstPrefixXops, lstPrefixIpfs, ksSOMECOM_DIR, klstDLL_FILES, klstUSER_FILES, klstMORE_BACKUPS, ksAPPL_SUBDIR, ksALLUSERS_SUBDIR )
End


Function		CheckEditReleaseSetting_FPulse()
	CheckEditReleaseSetting( ksAPPNAME, ksVERSION_MARKER )
End

//==============================================================================================================================

