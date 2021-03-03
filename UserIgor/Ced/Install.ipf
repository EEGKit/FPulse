//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//   Install.ipf
//   FPulse_Install.pxp  : the one and only file needed for  FPULSE and  FEVAL  INSTALLATION  04Sept01
//
//  This  installation routine is superseded  by  'Inno-Setup'  .   The code is kept as it contains better versions of some functions e.g.  CopyFilesFromList()  than in FPRelease.ipf.
//
// This installation program  allows installation of  FPulse  and  FEval  in any drive. The folders are fixed but could easily be changed.
// If  working version of FPulse  or  previous versions are detected, this drive is used for installation (no user choice).
// If in this case the user wanted to install on another drive he/she would have to rename or delete ALL current and previous versions so that they are no longer detected by the installation program.
// The directory and program names must be matched to those in  FPulseRelease.ipf .
//  To de-install FPulse completely 2 steps are needed no matter whether  FPulse is running or not.
//  The first step is to delete all FPulse link files (e.g. FPulse.ipf.lnk, FPulse.ihf.lnk, FPulseCed.xop.lnk ...' which are loaded whenever Igor is started.
//  Even after deleting these files the links are still active which prevents deletion or changing of the source files. These active links can only be cleared by exiting and restarting Igor.
//  In a second step (after Igor has been restarted without the links) the source file can be deleted or replaced by another version.
 
 // When saving a changed   'FPulse_Install.pxp'  experiment then make sure that...
 //...that there is no working FPulse installed (remove FPulse first)
 //...this procedure window is closed
 //...there is no  FP*.*  window open (see  -> Windows -> Other windows )
 //...there is no  FP*.*  panel  displayed
 //...the Pulse installation panel is located in the upper left and the history window just below
 //...the Pulse installation and the history window together are so small that they fit on a 1024x768 screen (the command line should be visible on this screen size)
 
 // CAUTION:
// After executing 'FPulseRelease()'  the links point to the release directory   UserIgor:FPulse:xxx   instead of the develop directory  UserIgor:Ced:xxx...
// ...so if you have inadvertently deleted the Release directory you have to reset the links by calling  'FPulseRestoreDevelopLinks()'   by command line.
 
 // 040901	Also releases  'FEval' . Removed  'GetInputState'
 // 041005	Takes into account the 3 new XOPs
 
#pragma rtGlobals=1							// Use modern global access method.
#pragma IgorVersion=5.02						// for GetFileFolderInfo

FPCreateFPulseInstallPanel()					// This is executed when the experiment is loaded

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

// Cave 1: ----------- ALL  THESE  CONSTANTS  MUST  BE  THE  SAME  IN FPRELEASE:IPF  AND  IN  PROCEDURE  OF  FPULSE_INSTALL.PXP  --------------
// Cave 2: ----------- ksINSTALLATION_DIR	= "X:UserIgor:FPulse" must be distinct  from  DevelopDir = "C:UserIgor:Ced"   must be distinct  from  ksRELEASE_SRC_DIR = "Y:FPulse"		
// Cave 3: ----------- THE  SCRIPTS  PATH  SHOULD NOT BE CHANGED  TO ENSURE  COMPATIBILITY  WITH  PREVIOUS  INSTALLATIONS

static strconstant	ksMYPRG_DIR			= "UserIgor:Ced"
static strconstant	ksPRG_NAME			= "FPulse.ipf"					// must be the same in  FPulse.ipf  and  in  Procedure  of FPulse_Install.pxp

static strconstant	ksRELEASE_SRC_DIR	= "FPulse"						// must be the same in  FPRelease.ipf  and  in  Procedure  of FPulse_Install.pxp

// 040901
//static strconstant	ksUSER_FILES_LIST	= "FP*.ipf;*.ihf;*.xop;*.rtf;"			// must be the same in  FPRelease.ipf  and  in  Procedure  of  FPulse_Install.pxp
//static strconstant	ksPROC_FILES_LIST	= "FP*.ipf"						// is LIST can have more items. List of links to be copied into 'User Procedures' . The link from 'FPulse.ipf' is included but not needed here, it must go into  'Igor Procedures' .
//static strconstant	ksHELP_FILES_LIST		= "FP*.ihf"						// is LIST, can have more items e.g. FP*.ihf;Ced*.ihf"
static strconstant	ksUSER_FILES_LIST	= "FP*.ipf;*.ihf;*.xop;*.rtf;FE*.ipf"		// must be the same in  FPRelease.ipf  and  in  Procedure  of  FPulse_Install.pxp
static strconstant	ksPROC_FILES_LIST	= "FP*.ipf;FE*.ipf"				// (is LIST can have more items.) List of links to be copied into 'User Procedures' . The link from 'FPulse.ipf' is included but not needed here, it must go into  'Igor Procedures' .
static strconstant	ksHELP_FILES_LIST		= "FP*.ihf"						// is LIST, can have more items e.g. FP*.ihf;Ced*.ihf"

static strconstant	ksDEMOSCRIPTS_LIST	= "Demo*.txt;AP*.*;Sine*.ibw"		// 

static strconstant	ksPRG_START_LNK		= ":Igor Procedures"
static strconstant	ksUSERPROC_LNK		= ":User Procedures"
static strconstant	ksHELP_LNK			= ":Igor Help Files"
 // 041005
 //static strconstant	ksPRGXOP_NAME		= "FPulseCed"
static strconstant	ksPRGXOP_LIST		= "FP*.xop"
static strconstant	ksXOP_LNK			= ":Igor Extensions"

// 040901
//static strconstant	ksGETINPUTSTT_DIR	= ":More Extensions:Utilities"
//static strconstant	ksGETINPUTSTT_NAME 	= "GetInputState" 

static strconstant	ksSCRIPTS_DRIVE		= "C:"						// should be  C:  to ensure compatibility
static strconstant	ksSCRIPTS_DIROLD	= "UserIgor:Ced:Scripts"			// do not change to ensure compatibility
static strconstant	ksSCRIPTS_DIR		= "UserIgor:Scripts"				// do not change to ensure compatibility
static strconstant	ksTMP_DIR			= ":Tmp"						// do not change to ensure compatibility
static strconstant	ksDEMO_DIR			= ":DemoScripts"				// do not change to ensure compatibility
static strconstant	ksDLL_DIR			= ":Dll"						// do not change to ensure compatibility

static strconstant	ksINSTALLATION_DRIVE	= "C:"						// user can change this only if no previous installation directory is found
static strconstant	ksINSTALLATION_DIR	= "UserIgor:FPulse"				// must be at least 2 levels 

static strconstant	ksWINDOWS_DLL_DIR	= "Windows:System32"
static strconstant	ksWINNT_DLL_DIR		= "WinNT:System32"
 // 041005	Takes into account the 3 new XOPs
static strconstant	ksDLL_FILES_LIST		= "Use1432.dll;1432ui.dll;Cfs32.dll;AxMultiClampMsg.dll;"	// do not use *.dll as attributes are set for all these files in  Windows\System32


static constant		kPnL			= 10, 	kPnR	= 490				// Panel position fixes size
static constant		kXTEXT		= 20,		kYTEXT	=   10				// Position of the text box
static constant		kYD			= 25									// height of 1 panel entry
static constant		kY1			= 10									// height of 1 panel entry
static constant		kTEXTLINES	= 5

static strconstant	ksMSGALERT	= "If you continue the (de)installation Igor will have to be exited. \rYou will have to restart  FPulse_Install.pxp to finish the (de)installation." 

static strconstant	sDIRSEP 		= ":"									// IGOR prefers MacIntosh style separator for file paths 
static constant		FALSE		= 0
static constant		TRUE		= 1

static constant		kKEEPTIME		= -1							// -1 : do NOT modify the file to reflect the version number 
static	 constant		kKEEP_READFLAG	= 0,	kCLR_READONLY	= 1		// reset the ReadOnly flag to R/W again. This is required when installing from a CD-ROM.
static constant		kFULLPATH		= 0,	kIGORPATH		= 1		// 0 : path starts from the root directory, 1: path starts from the 'Igor Pro Folder'
 

Function 	BeforeExperimentSaveHook( RefNum, sFileName, sPath, sType, sCreator, kind )
	variable	RefNum, kind
	string  	sFileName, sPath, sType, sCreator
	string  	sText	= ".\r"			// knTEXTLINES : clear the text window within the panel before saving the experiment so that there is an empty window when loading the experiment
	FPPrintPnLine( "FPulseInstallPn", kXTEXT, kYTEXT, sText )
	KillPath /A /Z						// kill all unused pathsbefore saving the experiment as they might cause trouble when loading the experiment 
End

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  The control panel  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Function		FPCreateFPulseInstallPanel()

	string			savDF			= GetDataFolder( 1 )				// Save current DF for restore.
	NewDataFolder  /O  /S root:FPInstall								// make a new data folder and use as CDF,  clear everything
	string	 	/G	root:FPInstall:gsInstallDrive		= ""					// will be changed automatically 
	string		/G	root:FPInstall:gsInstallDir		= ksINSTALLATION_DIR
	variable	/G	root:FPInstall:gbInstalledDirFound
	variable	/G	root:FPInstall:gbInstalledPrgFound
	variable	/G	root:FPInstall:gbInstalledLnkFound
	variable	/G	root:FPInstall:gVersion
	SetDataFolder 	savDF										// Restore current DF.

	svar		gsInstallDrive		= root:FPInstall:gsInstallDrive
	svar		gsInstallDir			= root:FPInstall:gsInstallDir
	nvar		gVersion			= root:FPInstall:gVersion

	PathInfo 	Home												// gives the path to THIS experiment
	string  	sPrgSourcePath		=  S_Path
	string  	sPrgSourceDrive	=  sPrgSourcePath[ 0, 1 ]
  	string  	sInstalledPrgChkFile	= ksRELEASE_SRC_DIR + ":" + ksPRG_NAME	// we check just 1 file time stamp (all files have the same)
  	gVersion	= GetVersionFromFileTime( sPrgSourceDrive + sInstalledPrgChkFile )	// e.g.  E:UserIgor:FPulse:FPulse.ipf has time 02:37 -> version 237
	if ( gVersion == - 1 )
		printf "\r++++ Error: Could not find required installation file  '%s' . Aborting...\r", sPrgSourceDrive + sInstalledPrgChkFile 
		return -1
	endif

	printf  "\r--------- FPulse Installation V%.2lf  --------- \r", gVersion/100
	printf "\t\tInstalling from drive  '%s'   ( '%s' ) \r",  UpperStr( sPrgSourceDrive ), sPrgSourcePath


	DoWindow	/K 		FPulseInstallPn
	NewPanel    	/W=(   kPnL,  55,  kPnR,  320 - 25 ) 	/K=1 as "FPulse Installation  " + FPVersionString()
	DoWindow	/C 		FPulseInstallPn
	ModifyPanel	/W	=	FPulseInstallPn 	fixedSize=1

	PopupMenu	poInstallDrive,	win = FPulseInstallPn, pos={  60, kY1 + 5 * kYD},	 bodywidth=50,	title="  Installation Drive: ",	disable = 1, mode=1,	proc = FPInstallDriveProc, value = ListOfInstallDrives()
//	SetVariable	svInstallDrive,	win = FPulseInstallPn, pos={  20, kY1 + 5 * kYD},	size={ 120, 15 },	title="  Installation Path:    ",disable = 1, noedit=1,	proc = FPInstallDriveProc, value = gsInstallDrive // just display the drive but do not allow change
	SetVariable	svInstallDir,	win = FPulseInstallPn, pos={150, kY1 + 5 * kYD},	size={ 120, 15 },	title=" ",				disable = 1, noedit=1,  					value = gsInstallDir// just display the drive but do not allow change

	PopupMenu 	poVersion,		win = FPulseInstallPn, pos={220, kY1 + 6 * kYD}, bodywidth= 120,title="Select previous Version:", disable = 1, mode=1,	proc = FPInstallVersionProc,value= SearchDrivesForListOfPrevVersns()

	Button	  	buContinue, 	win = FPulseInstallPn, pos={  20, kY1 + 7 * kYD},	size={ 120, 20 },	title="Install latest version",		disable = 1,		proc	= FPInstallLatestProc			// 1 = hide
	Button	  	buRevert,      	win = FPulseInstallPn, pos={150, kY1 + 7 * kYD},	size={ 120, 20 },	title="Revert to previous",		disable = 1	,		proc	= FPInstallRevertProc			// 1 = hide
	Button	  	buRemove,      	win = FPulseInstallPn, pos={280, kY1 + 7 * kYD},	size={ 120, 20 },	title="Remove FPulse",		disable = 1	,		proc	= FPInstallRemoveProc		// 1 = hide
	
	Button	  	buCancel,      	win = FPulseInstallPn, pos={ 20,  kY1 + 8 * kYD},	size={ 120, 20 },	title="Cancel",				disable = 0	,		proc	= FPInstallCancelProc		// 0 = active
	Button	  	buFinishExit,      	win = FPulseInstallPn, pos={280, kY1 + 8 * kYD},	size={ 120, 20 },	title="Finish + Exit Igor",		disable = 1	,		proc	= FPInstallFinishExitProc		// 1 = hide 

	Button	  	buContinue1, 	win = FPulseInstallPn, pos={ 150, kY1 + 8 * kYD},size={ 250, 20 }, title="Install latest / Revert to previous / Remove",disable = 1,proc = FPInstallContinue1Proc	// 1 = hide  

	FPInstallStart() 

End


Function		FPInstallStart() 
	svar		gsInstallDrive		= root:FPInstall:gsInstallDrive
	svar		gsInstallDir	 		= root:FPInstall:gsInstallDir
	nvar		gbInstalledPrgFound	= root:FPInstall:gbInstalledPrgFound
	nvar		gbInstalledLnkFound	= root:FPInstall:gbInstalledLnkFound
	string  	sText = "", sTextPrgLnk = "", sTextPrevVersions = "", sTextAlert = ""
	string		sInstalledPrgChkFile
	variable	nVersion
	variable	nStep	= 0
	
	// Check if  there is an  FPulse directory ( can be empty,  can contain the working version,  can contain previous versions)
	//printf  "\t\tFPInstallStart() \r"
  	sInstalledPrgChkFile	= ksINSTALLATION_DIR + ":" + ksPRG_NAME
	gsInstallDrive		= FPulsePrgDrive( sInstalledPrgChkFile )
	gbInstalledPrgFound	= strlen( gsInstallDrive )										// Check if  FPulse  files are found in the  'Working'  directory
	gbInstalledLnkFound	= FPulseLnkFound()											// Check if  FPulse  links are found in the Igor Pro Folder

	// Check if  a  WORKING  FPulse  version  is installed  in the  'Working'  directory
	if (   	     gbInstalledPrgFound   &&    gbInstalledLnkFound )								// found 	a working  installation 
		nStep	= 1
		DoWindow /T  FPulseInstallPn	"FPulse Installation  " + FPVersionString() + " :   Step " + num2str( nStep )	// change the panel title
		nVersion	= GetVersionFromFileTime( gsInstallDrive + sInstalledPrgChkFile )
		Button	  	buContinue1,     win = FPulseInstallPn, disable  = 0						// enable  Continue1	button
		Button	  	buContinue, 	win = FPulseInstallPn, disable  = 1						// hide	Continue	button
		sTextAlert = "\r" + ksMSGALERT 												// inform the user about the necessary  exit and restart of  Igor and  FPulse_Install.pxp
		//sprintf sTextPrgLnk, "Found  FPulse version  V%.2lf  in '%s' .", nVersion/100, gsInstallDrive + gsInstallDir 
		sprintf sTextPrgLnk, "FPulse currently installed : Working version V%.2lf  in '%s' .", nVersion/100, gsInstallDrive + gsInstallDir 

	elseif (   gbInstalledPrgFound   &&  ! gbInstalledLnkFound )									// state after step1 : links are already deleted but program files still exist 
		nStep	= 2
		nVersion	= GetVersionFromFileTime( gsInstallDrive + sInstalledPrgChkFile )
		Button		buRemove,      	win = FPulseInstallPn, disable  = 0						// enable  Remove  button
		Button	  	buContinue1,     win = FPulseInstallPn, disable  = 1						// hide	Continue1	button
		Button	  	buContinue, 	win = FPulseInstallPn, disable  = 0						// enable  Continue	button
		//(sprintf  sTextPrgLnk, "Found incomplete  FPulse version  V%.2lf on drive %s . ", nVersion/100, gsInstallDrive
		sprintf  sTextPrgLnk, "FPulse currently installed : Incomplete version  V%.2lf on drive %s . ", nVersion/100, gsInstallDrive

	elseif ( ! gbInstalledPrgFound   &&   gbInstalledLnkFound )									// should not happen: there are existing links without  program files
		nStep	= 1
		Button		buContinue1,   	win = FPulseInstallPn, disable = 0						// enable  Continue1  button
		Button	  	buContinue, 	win = FPulseInstallPn, disable = 1						// hide	Continue	button
		sTextAlert = "\r" + ksMSGALERT 												// inform the user about the necessay  exit and restart of  Igor and  FPulse_Install.pxp
		//sprintf  sTextPrgLnk, "Found defective  FPulse . ( Misleading links ) "
		sprintf  sTextPrgLnk, "FPulse currently installed : Defective version  ( misleading links ) . "

	elseif ( ! gbInstalledPrgFound   &&  ! gbInstalledLnkFound )									// found no previous installation
		nStep	= 2
		DoWindow	/T  FPulseInstallPn	"FPulse Installation  " + FPVersionString() + " :   Step " + num2str( nStep )
		Button	  	buContinue1,     win = FPulseInstallPn, disable = 1						// hide	Continue1	button
		Button	  	buContinue, 	win = FPulseInstallPn, disable = 0						// enable  Continue	button
		//sprintf  sTextPrgLnk, "FPulse not found. "
		sprintf  sTextPrgLnk, "FPulse currently installed : None "
	endif

	// Check if  PREVIOUS  FPulse  versions  are found   in  'UserIgor'
	string  	lstPrevVersions	= SearchDrivesForListOfPrevVersns()					// possibly changes gsInstallDrive
	PopupMenu poVersion,	win = FPulseInstallPn, disable = 1					// 0 = enable, 1 = hide, 2 = grey
	if ( strlen( lstPrevVersions ) )
		//sprintf  sTextPrevVersions, "Found previous FPulse versions  on drive %s :\r\t%s ...", gsInstallDrive,  lstPrevVersions[ 0, 4 * 11 ]	//  11 is length of 1 item  'FPulseV234;'
		sprintf  sTextPrevVersions, "Previous FPulse versions : \r\t%s ... on drive %s .",  lstPrevVersions[ 0, 4 * 11 ], gsInstallDrive		//  11 is length of 1 item  'FPulseV234;'
	else
		//sprintf  sTextPrevVersions, "Found no previous FPulse versions."
		sprintf  sTextPrevVersions, "Previous FPulse versions : None found."
	endif	
	if ( strlen( lstPrevVersions )  &&  nStep == 2 )
		PopupMenu poVersion,	win = FPulseInstallPn, disable = 0			// 0 = enable, 1 = hide, 2 = grey
	endif
	sText	= sTextPrgLnk + "\r" + sTextPrevVersions  + "\r" + sTextAlert  
	FPPrintPnLine( "FPulseInstallPn", kXTEXT, kYTEXT, sText )

	// Offer the  'Drive Select'  control  only if  neither a working  nor  previous  FPulse version  have been detected
	if ( strlen( gsInstallDrive ) == 0 )
		gsInstallDrive	= "C:"			// default if the user makes no selection
		PopupMenu	poInstallDrive,	win = FPulseInstallPn, disable = 0		// 0 = enable, 1 = hide, 2 = grey
	endif

End

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  Action procedures ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Function		FPInstallContinue1Proc( ctrlName ) : ButtonControl
	string		ctrlName

	Button	  	buContinue1,    	win = FPulseInstallPn, disable  = 1			// hide	Continue1	button
	Button	  	buContinue,      	win = FPulseInstallPn, disable  = 1			// hide  	Continue	button
	Button	  	buRevert,      	win = FPulseInstallPn, disable  = 1			// hide 	Revert	button
	Button	  	buRemove,      	win = FPulseInstallPn, disable  = 1			// hide 	Remove	button
	Button	  	buCancel,      	win = FPulseInstallPn, disable  = 1			// hide  	Cancel	button
	Button	  	buFinishExit,      	win = FPulseInstallPn, disable  = 0			// enable  	FinishExit	button

	FPDeleteAllLinkFiles()		// removing all links is required before any  user files can be changed or deleted.................
End


Function		FPInstallCancelProc( ctrlName ) : ButtonControl
	string		ctrlName
	printf "\tAborting  FPulse Installation \r"
	DoWindow	/K 		FPulseInstallPn
End


Function		FPulseRemove()
	svar		gsInstallDrive		= root:FPInstall:gsInstallDrive
	svar		gsInstallDir	 		= root:FPInstall:gsInstallDir
	nvar		gbInstalledPrgFound	= root:FPInstall:gbInstalledPrgFound
	nvar		gbInstalledLnkFound	= root:FPInstall:gbInstalledLnkFound
	string  	sText, sText1

	Button	  	buContinue1,    	win = FPulseInstallPn, disable  = 1			// hide	Continue1	button
	Button	  	buContinue,      	win = FPulseInstallPn, disable  = 1			// hide	Continue	button
	Button	  	buRevert,      	win = FPulseInstallPn, disable  = 1			// hide	Revert	button
	Button	  	buRemove,      	win = FPulseInstallPn, disable  = 1			// hide	Remove	button
	Button	  	buCancel,      	win = FPulseInstallPn, disable  = 1			// hide	Cancel	button
	Button	  	buFinishExit,      	win = FPulseInstallPn, Title = "OK", disable  = 0	// enable  FinishExit	button
	PopupMenu 	poVersion,		win = FPulseInstallPn,  disable = 1			// hide

	DeleteFilesFromList( gsInstallDrive + gsInstallDir, ksUSER_FILES_LIST )				// only when there are no links we can delete  FPulse.ipf, FPulse.ihf, FPulseCed.xop ...
	sprintf  sText, "Removing procedures files from  '%s'  ",  gsInstallDrive + gsInstallDir

// Unfortunately for this to work, the user must first enable 'Misc->Misc->Misc->DeleteFolder'  which is very cumbersome so we rather not rely on it...
//	DeleteFolder	/Z gsInstallDrive + gsInstallDir
//	if ( V_Flag )
//		sprintf  sText1, "++++Warning: Could not remove (empty) folder  '%s'  ",  gsInstallDrive + gsInstallDir
//	endif

	sprintf  sText1, "FPulse has been removed. \rYou may want to remove the empty directory '%s' manually.",  gsInstallDrive + gsInstallDir
	FPPrintPnLine( "FPulseInstallPn", kXTEXT, kYTEXT, sText + "\r" + sText1 )
End


Function		FPInstallLatestProc( ctrlName ) : ButtonControl
	string		ctrlName
	svar		gsInstallDrive		= root:FPInstall:gsInstallDrive
	svar		gsInstallDir	 		= root:FPInstall:gsInstallDir
	nvar		gbInstalledPrgFound	= root:FPInstall:gbInstalledPrgFound
	nvar		gbInstalledLnkFound	= root:FPInstall:gbInstalledLnkFound
	string  	sText
	string		sWantedDrive		= gsInstallDrive[ 0, 1 ]
	//printf "\tButton Install Latest \tgsInstallDrive: '%s' \r", gsInstallDrive

//	Button	  	buFinishExit,      	win = FPulseInstallPn, Title = "OK", disable  = 0	// enable  FinishExit	button
	Button	  	buRemove,      	win = FPulseInstallPn, disable  = 1			// hide	Remove	button
	Button	  	buCancel,      	win = FPulseInstallPn, disable  = 1			// hide	Cancel	button
	Button	  	buRevert,      	win = FPulseInstallPn, disable  = 1			// hide	Revert	button
	Button	  	buContinue1,    	win = FPulseInstallPn, disable  = 1			// hide	Continue	button
	Button	  	buContinue,      	win = FPulseInstallPn, disable  = 1			// hide	Continue	button
	PopupMenu	poInstallDrive,	win = FPulseInstallPn, disable  = 1			// 0 = active, 1 = hide, 2 = greyed.  Valid installation drive has been selected : hide it as it can no longer be changed
	FPulseInstall( gsInstallDrive, gsInstallDir )
	Button	  	buFinishExit,      	win = FPulseInstallPn, Title = "OK", disable  = 0	// enable  FinishExit	button  AFTER  installation
End


Function		FPInstallRevertProc( ctrlName ) : ButtonControl
	string		ctrlName
	//printf "\tButton Revert \r"

	svar		gsInstallDrive		= root:FPInstall:gsInstallDrive
	svar		gsInstallDir	 		= root:FPInstall:gsInstallDir
	nvar		gbInstalledPrgFound	= root:FPInstall:gbInstalledPrgFound
	nvar		gbInstalledLnkFound	= root:FPInstall:gbInstalledLnkFound
	nvar		gVersion			= root:FPInstall:gVersion
	string  	sText,  sInstallBaseDir, sRevertDir	= ""

	Button	  	buFinishExit,      	win = FPulseInstallPn, disable  = 0			// enable  FinishExit	button
	Button	  	buCancel,    	win = FPulseInstallPn, disable  = 1			// hide	Cancel	button
	Button	  	buRevert,    	win = FPulseInstallPn, disable  = 1			// hide	Revert	button
	Button	  	buContinue1,    	win = FPulseInstallPn, disable  = 1			// hide	Continue1	button
	Button	  	buContinue,      	win = FPulseInstallPn, disable  = 1			// hide	Continue	button
	PopupMenu	poInstallDrive,	win = FPulseInstallPn, disable  = 1			// 0 = active, 1 = hide, 2 = greyed.  Valid installation drive has been selected : hide it as it can no longer be changed
	PopupMenu 	poVersion,		win = FPulseInstallPn,  disable = 1			//  0 = active, 1 = hide, 2 = greyed. Hide	Version		popupmenu

	ControlInfo		/W = FPulseInstallPn  poVersion
	if ( V_Flag == 3 )	  					// 3 : it is an active popupmenu
		sRevertDir = s_Value
	endif 
	variable	nInstallDirLevels	= ItemsInList( ksINSTALLATION_DIR, sDIRSEP )	// better ParseFilePath ???
	if ( nInstallDirLevels < 2 )
		printf "++++Error: Installation directory must have at least 2 levels,  but  '%s'  has only %d .\r", ksINSTALLATION_DIR, nInstallDirLevels
	else
		sInstallBaseDir	= RemoveListItem( nInstallDirLevels - 1, ksINSTALLATION_DIR, sDIRSEP )	// 'UserIgor:FPulse' 	-> 'UserIgor:' 
		PossiblyCreatePath( gsInstallDrive + gsInstallDir )
		DeleteFilesFromList( gsInstallDrive + gsInstallDir, ksUSER_FILES_LIST )						// does not remove file if it has a link to Igor, e.g. will not delete  FPulse.ipf, FPulse.ihf, FPulseCed.xop if  FPulse  is installed. 
		CopyFilesFromList( gsInstallDrive + sInstallBaseDir + sRevertDir, ksUSER_FILES_LIST, 	gsInstallDrive + gsInstallDir, kKEEPTIME, kKEEP_READFLAG )	// Copy the reverted User files (e.g. ipf, ihf, xop..) into the working directory

		CreateLinkFiles( gsInstallDrive + gsInstallDir, gVersion )														// Create the required link files (e.g. ipf, ihf, xop..) in the Igor Pro Folder..

		sprintf sText, "FPulse has been reverted to Version '%s'.  \rYou must restart  Igor and  FPulse....." , sRevertDir
	endif
	FPPrintPnLine( "FPulseInstallPn", kXTEXT, kYTEXT, sText )
End


Function		FPInstallRemoveProc( ctrlName ) : ButtonControl
	string		ctrlName
	FPulseRemove()
End


Function		FPInstallFinishExitProc( ctrlName ) : ButtonControl
	string		ctrlName
	//printf "\tButton Finish and Exit \r"
	DoWindow	/K 		FPulseInstallPn
	Execute /P /Q /Z "Quit /N "	// don't ask for saving the experiment
End


//Function		FPInstallDriveProc( ctrlName, varNum, varStr, varName ) : SetVariableControl
//	string		ctrlName, varStr, varName
//	variable	varNum
//	Button	buRevert,      	win = FPulseInstallPn, disable = 2, title = "Revert to previous version"	// remove previous selection and grey the button
//	ControlUpdate/W = FPulseInstallPn  poVersion
//End

Function		FPInstallDriveProc( ctrlName, popNum, popStr ) : PopupMenuControl
	string		ctrlName,  popStr
	variable	popNum
	svar		gsInstallDrive		= root:FPInstall:gsInstallDrive
	gsInstallDrive		= popStr
	printf "\tFPInstallDriveProc( '%s' , %d , '%s' )  setting  gsInstallDrive:%s \r", ctrlName, popNum, popStr , gsInstallDrive
End


Function 		FPInstallVersionProc( ctrlName, popNum, popStr ) : PopupMenuControl
	string 	ctrlName, popStr
	variable 	popNum
	printf "\tFPInstallVersionProc( '%s' , %d , '%s' ) \r", ctrlName, popNum, popStr 
	Button	buRevert,      	win = FPulseInstallPn, disable = 0, title = "Revert to " + popStr		// Only after the user has selected a previous installation enable the 'Revert' button. The selected value will be extracted only later when it is actually needed (->ControlInfo)
End

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  Big Helpers ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Function		FPulseInstall( sInstallDrive, sInstallDir )
	string	  	sInstallDrive, sInstallDir 

	string  	sInstallDriveDir		= sInstallDrive + sInstallDir 
	string  	sLastDrive			= LastRWDrive( "C:" )								// Look for all hard disks starting at C:  ( any R/W disk above C: is included e.g. a CD ROM burner. This is not intended but does not hurt.
	string  	sWindowsDLLDrive	= SearchDirInDrives( "C:", sLastDrive, ksWINDOWS_DLL_DIR ) 	// Look for a drive within the given range that contains the Win98  system directory, usually   \Windows\System32 
	string  	sWinNTDLLDrive	= SearchDirInDrives( "C:", sLastDrive, ksWINNT_DLL_DIR ) 	// Look for a drive within the given range that contains the Win2000/XP system directory, usually   \WinNT\System32 
	string  	sText
	nvar		gVersion			= root:FPInstall:gVersion

	// Create  directory	"Epc:Data" : this is not required during installation as this directory is created during run-time (see sEVALCFG_DIR) 
	// static strconstant	ksDATA_DRIVE		= "C:"
	// static strconstant	ksDATA_DIR			= "Epc:Data"
	// PossiblyCreatePath( ksDATA_DRIVE	+ ksDATA_DIR )						// should not be changed to ensure compatibility


	// IF  THERE  IS AN  OLD  INSTALLATION  THERE  ARE OLD LINKS which should be removed.
	// Remove  'FpMenu.ipf.ln´k'  and  'Ced1401.xop.lnk'  ( or  'Verknüpfung mit ... )
	PathInfo	Igor
	// As s_Path  and  the Igor folder both contain a colon one colon is removed by  ksXXX_LNK[1,inf],
	DeleteLinksFromList( s_Path + ksPRG_START_LNK[1,inf], 	"*FPMenu.ipf" )				// e.g.  ':Igor Procedures:Verknüpfung mit FPMenu.ipf.lnk' 
	DeleteLinksFromList( s_Path + ksXOP_LNK[1,inf], 		"*Ced1401.xop" )			// e.g.  ':Igor Extensions:Verkn.. mit Ced1401.xop.lnk'  
	

 	string		sScriptPath	=  ksSCRIPTS_DRIVE + ksSCRIPTS_DIR					// e.g. 'C:UserIgor:Scripts'

	// IF  THERE  IS AN  OLD  INSTALLATION  BUT  NOT  YET  THE  NEW  INSTALLATION: 
	//  MOVE  the SCRIPTS directory back 1 level  (eliminate the directory level 'Ced 'from 'UserIgor:Ced:Scripts'
	// Check if there is a Scripts directory with the old path  'UserIgor:Ced:Scripts'
	//  The /O =overwrite flags unfortunately work only if the user has explicitly enabled their function (Misc->Misc Settings->Misc) which is cumbersome...
	//...so we must do it without overwriting. Therefore we must check the non-existence of the new directory before we attempt to copy the folder.
	// ToDo: delete the old folder (this is OK as we have a renamed copy)
	string  	sScriptPathOld	=  ksSCRIPTS_DRIVE + ksSCRIPTS_DIROLD 			// e.g. 'C:UserIgor:Ced:Scripts' 
	string  	sScriptPathBak	=  ksSCRIPTS_DRIVE + ksSCRIPTS_DIROLD + "_Bak"	// e.g. 'C:UserIgor:Ced:Scripts_Bak' 
	variable	bFoundOld	= SearchDir( sScriptPathOld )
	variable	bFoundBak	= SearchDir( sScriptPathBak )
	variable	bFoundNew	= SearchDir( sScriptPath )
	if ( bFoundOld  )
		if ( ! bFoundNew )
			CopyFolder	/Z  sScriptPathOld as sScriptPath						// Copies 'UserIgor:Ced:Scripts'  to  'UserIgor:Scripts'  including the 'Tmp'  and all user-created subdirectories
			printf "\t\t\tCopying folder '%s' to '%s' %s.\r", sScriptPathOld, sScriptPath, SelectString( V_Flag, "was successful", "failed" )
			if ( V_Flag )													// report only errors
				printf "++++Error: Copying folder '%s' to '%s' failed. Close all other programs and repeat installation.\r", sScriptPathOld, sScriptPath
			endif
		else
			printf "Warning( Copying scripts ) : Source '%s and target '%s' both exist, which is not expected. You must copy manually.\r",  sScriptPathOld, sScriptPath	
		endif
		if ( ! bFoundBak )
			MoveFolder	/Z  sScriptPathOld as sScriptPathBak				// Copies 'UserIgor:Ced:Scripts'  to  'UserIgor:Ced:Scripts_Bak'  including the 'Tmp'  and all user-created subdirectories
			printf "\t\t\tMoving folder '%s' to '%s' %s.\r", sScriptPathOld, sScriptPathBak, SelectString( V_Flag, "was successful", "failed" )
			if ( V_Flag )													// report only errors
				printf "++++Error: Moving folder '%s' to '%s' failed. Close all other programs and repeat installation.\r", sScriptPathOld, sScriptPathBak
			endif
		else
			printf "Warning( Moving scripts ) : Source '%s and target '%s' both exist, which is not expected. You must copy manually.\r",  sScriptPathOld, sScriptPathBak	
		endif
	endif
	
	// if ( bFoundBak )
	//	printf "As there is already a scripts backup directory, script files and script subdirectories are neither moved nor copied. \r"
	// endif


	// IF  THERE  IS NO  OLD  INSTALLATION  OR  ALREADY  A  NEW  INSTALLATION:  we don't care about details but create the required directories
	// Create  directory	'UserIgor:Scripts:Tmp'  (on drive C:)   if it does not yet exist
	string  	sScriptTmpPath	=  ksSCRIPTS_DRIVE + ksSCRIPTS_DIR + ksTMP_DIR		// e.g. 'UserIgor:Scripts:Tmp'  (the new 'Tmp' path) 
	PossiblyCreatePath( sScriptTmpPath )											// automatically creates  'UserIgor:Scripts'		
	string  	sScriptDemoPath =  ksSCRIPTS_DRIVE + ksSCRIPTS_DIR + ksDEMO_DIR	// e.g. 'C:UserIgor:Scripts:DemoScript'
	PossiblyCreatePath( sScriptDemoPath )										// e.g. 'C:UserIgor:Scripts:DemoScript'		


	
	// Copy the Igor procedure files
	string  	sPrgSourceDrive
	PathInfo	Home												// THIS experiment  and the  ksRELEASE_SRC_DIR folder (='FPulse')  must be ion the same drive's root
	sPrgSourceDrive	=  S_Path[ 0, 1 ]
	printf "\t\tInstalling from drive  '%s'   ( '%s' ) \r",  UpperStr( sPrgSourceDrive ), S_Path
	PossiblyCreatePath( sInstallDriveDir )

	//sprintf  sText,	"Installing  FPulse  from   %s   into   %s  .... ", sPrgSourceDrive, sInstallDriveDir
	//FPPrintPnLine( "FPulseInstallPn", kXTEXT, kYTEXT, sText )

	nvar		gVersion		= root:FPInstall:gVersion
	string  	sInstallDirBak	= PreviousVersionDirName( sInstallDriveDir , gVersion )
	
	PossiblyCreatePath( sInstallDirBak )																// Build a Backup directory  for  procedures, help files, Xops to allow reverting to previous versions

	// Copy  files ( procedures, help files, Xops ) into Backup directory to allow reverting to previous versions ,  modify the file time to reflect the version  and   clear the Read-only attribute which is set when installing from a CD-ROM drive.
	CopyFilesFromList( sPrgSourceDrive + ksRELEASE_SRC_DIR, ksUSER_FILES_LIST, 	sInstallDirBak, gVersion, kCLR_READONLY )				// Copy the current User files (e.g. ipf, xop..) into a VERSION directory so that previous versions can be restored
	
	// Copy  files ( procedures, help files, Xops ) into working directory ,  modify the file time to reflect the version  and   clear the Read-only attribute which is set when installing from a CD-ROM drive.
	CopyFilesFromList( sPrgSourceDrive + ksRELEASE_SRC_DIR, ksUSER_FILES_LIST, 	sInstallDriveDir, gVersion, kCLR_READONLY )			// Copy the current User files (e.g. ipf, ihf, xop..) into it

	// Copy  some demo scripts into 'UserIgor:Scripts:Demo' directory ,  modify the file time to reflect the version  and   clear the Read-only attribute which is set when installing from a CD-ROM drive.
	CopyFilesFromList( sPrgSourceDrive + ksRELEASE_SRC_DIR + ksDEMO_DIR, ksDEMOSCRIPTS_LIST, sScriptDemoPath, gVersion, kCLR_READONLY )	// Copy the...

	// Copy  Ced1401 libraries	 and   clear the Read-only attribute which is set when installing from a CD-ROM drive.
	if ( strlen( sWindowsDLLDrive ) )			// found a directory System32 on a  Win98 machine 
		CopyFilesFromList( sPrgSourceDrive + ksRELEASE_SRC_DIR + ksDLL_DIR, ksDLL_FILES_LIST, sWindowsDLLDrive + ksWINDOWS_DLL_DIR, kKEEPTIME, kCLR_READONLY )	// e.g. 'C:UserIgor:Ced:Cfs32.dll, 1432ui.dll, Use1432.dll' -> C:Windows:System32 
	endif
	if ( strlen( sWinNTDLLDrive ) )			// found a directory System32 on a  Win2000 or XP  machine 
		CopyFilesFromList( sPrgSourceDrive + ksRELEASE_SRC_DIR + ksDLL_DIR, ksDLL_FILES_LIST, sWinNTDLLDrive + ksWINNT_DLL_DIR, kKEEPTIME, kCLR_READONLY )		// e.g. 'C:UserIgor:Ced:Cfs32.dll, 1432ui.dll, Use1432.dll' -> C:WinNT:System32 
	endif

	CreateLinkFiles( sInstallDriveDir , gVersion )															// Create the required link files (e.g. ipf, ihf, xop..) in the Igor Pro Folder..

	Button	  	buCancel,    	win = FPulseInstallPn, disable  = 1			// hide	Cancel	button
	Button	  	buContinue,      	win = FPulseInstallPn, disable  = 1			// hide	Continue	button
	Button	  	buFinishExit,      	win = FPulseInstallPn, disable  = 0			// enable  FinishExit	button

	//SetVariable	svInstallDir,  	win = FPulseInstallPn,  disable = 1			// hide	............do not allow changing the directory, just display it
	SetVariable	svInstallDir,  	win = FPulseInstallPn,  noedit = 1			// do not allow changing the directory, just display it
	PopupMenu 	poVersion,		win = FPulseInstallPn,  disable = 1			// hide

	sprintf  sText,	"Copying files from   %s   to  %s ...\r\rFPulse has been installed on drive %s . \rThe changes will come into effect when you exit and restart Igor. ", sPrgSourceDrive + ksRELEASE_SRC_DIR, sInstallDriveDir, sInstallDriveDir[ 0, 1 ]  
	FPPrintPnLine( "FPulseInstallPn", kXTEXT, kYTEXT, sText )
End


static Function		CreateLinkFiles( sInstallDriveDir, nVersion )
	// Create  links
	string  	sInstallDriveDir													// here :  'C:UserIgor:FPulse'  or   'D:UserIgor:FPulse' 
	variable	nVersion
	//string  	sGISPath, sGISLink

	CreateLinksFromList( sInstallDriveDir, ksPRG_NAME, 		ksPRG_START_LNK, nVersion )// e.g. 'C:UserIgor:FPulse:FPulse.ipf' ->  'Igor Procedures:FPulse.ipf.lnk'

	CreateLinksFromList( sInstallDriveDir, ksHELP_FILES_LIST, ksHELP_LNK, 		nVersion )	// e.g. 'C:UserIgor:FPulse:FPulse.ihf , FPulseCed.ihf' ->  'Igor Help Files:FPulse.ihf.lnk , FPulseCed.ihf.lnk'

	CreateLinksFromList( sInstallDriveDir, ksPROC_FILES_LIST, ksUSERPROC_LNK, nVersion )	// e.g. 'C:UserIgor:FPulse:FPulse.ipf , FPDisp.ipf...' 	->  'User Procedures:FPulse.ipf.lnk , FPDisp.ipf.lnk...'

	// 041005
	//CreateLinksFromList( sInstallDriveDir,  ksPRGXOP_NAME + ".xop", ksXOP_LNK, nVersion )	// e.g. 'C:UserIgor:FPulse:FPulseCed.xop' ->  'Igor Extensions:FPulseCed.xop.lnk'
	CreateLinksFromList( sInstallDriveDir,  ksPRGXOP_LIST,		 ksXOP_LNK, nVersion )	// e.g. 'C:UserIgor:FPulse:FPulseCed.xop' ->  'Igor Extensions:FPulseCed.xop.lnk'
 
 	// 040901
	//sGISPath		= ksGETINPUTSTT_DIR + ":" + ksGETINPUTSTT_NAME+  ".xop"		// e.g.  ":More Extensions:Utilities:GetInputState.xop"
	//sGISLink		= 		ksXOP_LNK    + ":" + ksGETINPUTSTT_NAME+  ".xop" + ".lnk"	// e.g.  ":Igor Extensions:GetInputState.xop.lnk"
	//CreateLink( sGISPath, sGISLink )
	//SetAttr1File( sGISLink, nVersion, kIGORPATH )
End


Function	/S	FPulsePrgDrive( sInstalledPrgChkFile )
// Checks if the  procedure file  which starts  FPulse  exists  on the HD.  Returns  TRUE  or  FALSE
	string  	sInstalledPrgChkFile 
	string  	sLastDrive			= LastRWDrive( "C:" )								// Look for all hard disks starting at C:  ( any R/W disk above C: is included e.g. a CD ROM burner. This is not intended but does not hurt.
	string  	sInstalledPrgDrive	= SearchFileInDrives( "C:", sLastDrive, sInstalledPrgChkFile ) 	// e.g '?:UserIgor:FPulse:FPulse.ipf'
	if ( strlen( sInstalledPrgDrive )  == 0 )
		return    ""
	else
		return   sInstalledPrgDrive
	endif
End


Function		FPulseLnkFound()
// Checks if the  LINK to the procedure file  which starts  FPulse  exists  on the HD.  Returns  TRUE  or  FALSE
	PathInfo	Igor
	// As s_Path  and  the Igor folder both contain a colon one colon is removed by  ksXXX_LNK[1,inf],
	string  	sFullPath	= s_Path + ksPRG_START_LNK[1,inf] + ":" + ksPRG_NAME  + ".lnk" 	// e.g.  "xxxxxx:Igor Procedures:FPulse:FPulse.ipf.lnk"
	//printf "\t\t\tFPulseLnkFound( '%s' ) returns %d \r",  sFullPath, FileExists( sFullPath )
	return	FileExists( sFullPath )
End

Function	/S	ListOfInstallDrives() 
// Look for R/W drives which are suitabe for installing  FPulse (Hard disks or  R/W-CDs .  If found return that list,  else return empty string.
	return	FirstToLastDriveList( "C:" )
End


Function	/S	SearchDrivesForListOfPrevVersns() 
// Look for a  previous  FPulse  versions. If found return that list  and set global  'gsInstallDrive'  , else return empty string.

	// Design issue: If we have found a working FPulse directory  we look only on this drive for previous FPulse versions. We ignore possibly FPulse versions on other drives.
	string  	lstPrevVersions	= ""
	svar		gsInstallDrive	= root:FPInstall:gsInstallDrive
	if ( strlen( gsInstallDrive ) )				

		lstPrevVersions	= ListOfPreviousFPulseVersions( gsInstallDrive )	// may find previous versions or not (then returning empty string)
		return	lstPrevVersions
	
	else													// as we did  not find a working FPulse directory (the user may have removed it completely) ...
		string  	sDrive	= "C:"							//...we search for previous FPulse versions on all drives.
		string  	sLastDrive	= LastRWDrive( "C:" )
		do
			lstPrevVersions	= ListOfPreviousFPulseVersions( sDrive )
			if ( strlen( lstPrevVersions ) )									// We found previous FPulse versions on 'sDrive'...
				gsInstallDrive	= sDrive								 // ...so we will use this drive for installation (Otherwise we will let the user select a drive.
				//printf "\t\t\tSearchDrivesForListOfPrevVersns() \tfound on  '%s'   '%s' . Will install on '%s' . \r", sDrive, lstPrevVersions, gsInstallDrive
				return	lstPrevVersions
			endif
			sDrive	= IncrementDrive( sDrive )
		while ( cmpstr( sDrive[ 0, 1 ] , sLastDrive ) <= 0 )	// normally check within given range, but also avoid endless loop if  'sDir'  was above  'sLastDrive'  form the beginning
	 	//printf "\t\t\t\t\t\tSearchDrivesForListOfPrevVersns() \tnot found in drives  '%s'  ...  '%s'  . \r", "C:", sLastDrive
		return	""
	endif
End

Function	/S	ListOfPreviousFPulseVersions( sPrevVersionsDrive )
	string  	sPrevVersionsDrive
	string  	sInstallBaseDir	= GoBack1Dir( ksINSTALLATION_DIR )						// e.g. 'UserIgor:FPulse' 	-> 'UserIgor' 
	variable	nDirLevels		= ItemsInList( ksINSTALLATION_DIR, sDIRSEP )				// The previous installation directories are in parallel to the working directory, so we must go back 1 level from the wd to access them
	string  	sInstallLastDir	= StringFromList( nDirLevels - 1, ksINSTALLATION_DIR, sDIRSEP )	// e.g. 'UserIgor:FPulse' 	-> 'FPulse' 
	string  	sInstallMatchDir	= PreviousVersionDirNameBase( sInstallLastDir ) + "*"				// e.g. 'FPulse' 		-> 'FPulseV*' 
	string  	lstPrevVersions	= FindMatchingDirs( sPrevVersionsDrive + sInstallBaseDir, sInstallMatchDir )
	return	lstPrevVersions
End


Function	/S	GoBack1Dir( sDir )
	string  	sDir
	// better ParseFilePath ???
	variable	nDirLevels	= ItemsInList( sDir, sDIRSEP )		// The previous installation directories are in parallel to the working directory, so we must go back 1 level from the wd to accesss them
	if ( nDirLevels < 2 )
		printf "++++Error: Installation directory must have at least 2 levels,  but  '%s'  has only %d .\r", sDir, nDirLevels
		return ""
	endif
	sDir	= RemoveListItem( nDirLevels - 1, sDir, sDIRSEP )	// e.g. 'UserIgor:FPulse' 	-> 'UserIgor:' 
	sDir	= RemoveEnding( sDir )						// e.g. 'UserIgor:' 		-> 'UserIgor' 
	return	sDir
End


Function	/S	FindMatchingDirs( sSrcDir, sMatch )
// e.g. 		FindMatchingDirs(  "D:UserIgor"  ,  "FPulseV*" )   will  return  'FPulseV339;FPulseV2a;...'  .  Wildcard *   is allowed .
	string  	sSrcDir, sMatch
	variable	n, nCnt
	string  	lstDirsInDir, lstMatched	= ""
	NewPath  /Z /O/Q	SymbCedPrgDir , sSrcDir 
	if ( V_Flag == 0 )
		lstDirsInDir	= IndexedDir( SymbCedPrgDir, -1, 0 )
		nCnt		= ItemsInList( lstDirsInDir )
		// printf "\t\t\tFindMatchingDirs(  All \t \t%s,\t%s    ) \t: %2d\tdirs   %s \r",  sSrcDir, sMatch, nCnt, lstDirsInDir[0, 200]
		lstMatched= ListMatch( lstDirsInDir, sMatch )
		nCnt		= ItemsInList( lstMatched )
		//printf "\t\t\tFindMatchingDirs(  Matched \t%s,\t%s    ) \t: %2d\tdirs   %s \r",  sSrcDir, sMatch, nCnt, lstMatched[0, 200]
		KillPath 	/Z	SymbCedPrgDir
	endif
	return	lstMatched
End

Function	/S	PreviousVersionDirNameBase( sInstallDir )
// defines the nomenclature for directories containing previous FPulse versions
	string  	sInstallDir
	return	sInstallDir + "V"
End

Function	/S	PreviousVersionDirName( sInstallDir, nVersion )
// defines the nomenclature for directories containing previous FPulse versions
	string  	sInstallDir
	variable	nVersion
	return	PreviousVersionDirNameBase( sInstallDir  ) + num2str( nVersion )
End




//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function		FPDeleteAllLinkFiles()
	// Delete all the links
	// 041005
	//DeleteFile	/Z=1	  /P=Igor		ksXOP_LNK 		+ ":" + ksPRGXOP_NAME		+ ".xop" 	+ ".lnk"	// e.g.  ":Igor Extensions:FPulseCed.xop.lnk"
	//DeleteFile		/Z=1	  /P=Igor		ksXOP_LNK 		+ ":" + ksPRGXOP_LIST	 			+ ".lnk"	// e.g.  ":Igor Extensions:FPulseCed.xop.lnk"

	//DeleteFile	/Z=1	  /P=Igor		ksXOP_LNK		+ ":" + ksGETINPUTSTT_NAME+ ".xop"	+ ".lnk"	// e.g.  ":Igor Extensions:GetInputState.xop.lnk"
	PathInfo	Igor
	// As s_Path  and  the Igor folder both contain a colon one colon is removed by  ksXXX_LNK[1,inf],
	DeleteLinksFromList( s_Path + ksXOP_LNK[1,inf], 		ksPRGXOP_LIST )			// e.g.  ':Igor Procedures:FPulseCed.xop.lnk'
	DeleteLinksFromList( s_Path + ksPRG_START_LNK[1,inf], 	ksPRG_NAME	   )  			// e.g.  ':Igor Procedures:FPulse.ipf.lnk'
	DeleteLinksFromList( s_Path + ksUSERPROC_LNK[1,inf], 	ksPROC_FILES_LIST )		// e.g.  ':User Procedures:FP*.ipf.lnk'  (the above link to FPulse is unnecessarily included)
	DeleteLinksFromList( s_Path + ksHELP_LNK[1,inf], 		ksHELP_FILES_LIST	  )		// e.g.  ':Igor Help Files:FP*.ihf.lnk'
End


//------ File handling for a list of groups of files  --------------------------------------------------------------------------------------------------------------------------------------

static Function		CopyFilesFromList( sSrcDir, lstFileGroups, sTargetDir, nVersion, bClearReadOnlyFlag )
	string  	sSrcDir, lstFileGroups, sTargetDir 
	variable	nVersion, bClearReadOnlyFlag
	variable	n, nCnt	= ItemsInList( lstFileGroups )
	string  	sFileGroup	
	for ( n = 0; n < nCnt; n += 1 )
	  	sFileGroup		= StringFromList( n, lstFileGroups )
		CopyFiles( sSrcDir, sFileGroup, sTargetDir, nVersion, bClearReadOnlyFlag ) 						// Copy the current User files (e.g. ipf, xop..) into it
	endfor
End


static Function		CreateLinksFromList( sSrcDir, lstFileGroups, sTgtDir, nVersion )
	string  	sSrcDir, lstFileGroups, sTgtDir
	variable	nVersion
	variable	n, nCnt	= ItemsInList( lstFileGroups )
	string  	sFileGroup	
	for ( n = 0; n < nCnt; n += 1 )
	  	sFileGroup		= StringFromList( n, lstFileGroups )	
		CreateLinks( sSrcDir, sFileGroup, sTgtDir, nVersion ) 					
		//SetAttrFiles( sTgtDir, sFileGroup + ".lnk",  nVersion, kIGORPATH ) 	// The hour:minute will be the version. Links have the extension '.lnk'  appended to the original extension (=2 dots!)
	endfor
End

	
static Function		DeleteFilesFromList( sSrcDir, lstFileGroups )
	string  	sSrcDir, lstFileGroups
	variable	n, nCnt	= ItemsInList( lstFileGroups )
	string  	sFileGroup	
	for ( n = 0; n < nCnt; n += 1 )
	  	sFileGroup		= StringFromList( n, lstFileGroups )
		DeleteFiles( sSrcDir, sFileGroup ) 							// Delete...
	endfor
End

static Function		DeleteLinksFromList( sSrcDir, lstFileGroups )
	string  	sSrcDir, lstFileGroups
	variable	n, nCnt	= ItemsInList( lstFileGroups )
	string  	sFileGroup	
	for ( n = 0; n < nCnt; n += 1 )
	  	sFileGroup		= StringFromList( n, lstFileGroups ) + ".lnk"			// links have the extension '.lnk'  appended to the original extension (=2 dots!)
		DeleteFiles( sSrcDir, sFileGroup ) 					
	endfor
End

	
//------ File handling for 1 group of files --------------------------------------------------------------------------------------------------------------------------------------

static Function		CopyFiles( sSrcDir, sMatch, sTgtDir , nVersion, bClearReadOnlyFlag )
// e.g. 		CopyFiles(  "D:UserIgor:Ced"  ,  "FP*.ipf" , "C:UserIgor:CedV235"  ) .  Wildcards  *  are allowed .
	string  	sSrcDir, sMatch, sTgtDir
	variable	nVersion, bClearReadOnlyFlag 
	string  	lstMatched	= ListOfMatchingFiles( sSrcDir, sMatch, FALSE )
	variable	n, nCnt		= ItemsInList( lstMatched )
	printf "\t\t\tCopyFiles( \t%s\t%s\t%s\t%d\t)%3d\tfile(s): %s...\r",  pd(sSrcDir,21), pd(sMatch,12), pd(sTgtDir,25), nVersion, nCnt, lstMatched[0, 200]
	for ( n = 0; n < nCnt; n += 1 )
		string  	sSrc	= sSrcDir + ":" + StringFromList( n, lstMatched )
		string  	sTgt	= sTgtDir + ":" + StringFromList( n, lstMatched )
		Copy1File( sSrc, sTgt )
		if ( nVersion != kKEEPTIME  ||  bClearReadOnlyFlag )  
			SetAttr1File( sTgt, nVersion, kFULLPATH )
		endif		
	endfor
End


static Function		CreateLinks( sSrcDir, sMatch, sTgtDir, nVersion )
// e.g. 		CreateLinks(  "D:UserIgor:Ced"  ,  "FP*.ipf" , "D:....:Igor Pro Folder:User Procedures"  ) . Wildcard *   is allowed.
	string  	sSrcDir, sMatch, sTgtDir
	variable	nVersion
	string  	lstMatched	= ListOfMatchingFiles( sSrcDir, sMatch, FALSE )
	variable	n, nCnt		= ItemsInList( lstMatched )
	printf "\t\t\tCreateLinks(\t%s\t%s\t%s\t%d\t)%3d\tfile(s): %s..\r",  pd(sSrcDir,21),  pd(sMatch,12), pd(sTgtDir,25), nVersion, nCnt, lstMatched[0, 200]
	for ( n = 0; n < nCnt; n += 1 )
		string  	sSrc	= sSrcDir + ":" + StringFromList( n, lstMatched )
		string  	sTgt	= sTgtDir + ":" + StringFromList( n, lstMatched ) + ".lnk"
		CreateLink( sSrc, sTgt  )
		SetAttr1File( sTgt, nVersion, kIGORPATH )
	endfor
End

//static Function		SetAttrFiles( sDir, sMatch, Version, bUseIgorPath )
//// e.g. 		DeleteFiles(  "D:UserIgor:Ced"  ,  "FP*.ipf" , TRUE ) . Wildcard *  is allowed.
//	string  	sDir, sMatch
//	variable	Version, bUseIgorPath
//	string  	lstMatched	= ListOfMatchingFiles( sDir, sMatch, bUseIgorPath  )
//	variable	n, nCnt		= ItemsInList( lstMatched )
//	 printf "\t\t\tSetAttrFiles(\t%s\t%s\t%g\t)%3d\tfiles  %s \r",  pd(sDir,25), pd(sMatch,12), Version, nCnt, lstMatched[0, 200]
//	for ( n = 0; n < nCnt; n += 1 )
//		string  	sPath	= sDir + ":" + StringFromList( n, lstMatched )
//		SetAttr1File( sPath, Version, bUseIgorPath )
//	endfor
//End


static Function		DeleteFiles( sSrcDir, sMatch )
// e.g. 		DeleteFiles(  "D:UserIgor:Ced"  ,  "FP*.ipf"  ) . Wildcard  *  is allowed .
	string  	sSrcDir, sMatch
	string  	lstMatched	= ListOfMatchingFiles( sSrcDir, sMatch, FALSE )
	variable	n, nCnt		= ItemsInList( lstMatched )
	 printf "\t\t\tDeleteFiles( %s\t%s\t)%3d\tfile(s): %s..\r",  pd(sSrcDir,48), pd(sMatch,15), nCnt, lstMatched[0, 200]
	for ( n = 0; n < nCnt; n += 1 )
		string  	sSrc	= sSrcDir + ":" + StringFromList( n, lstMatched )
		DeleteFile		/Z=1	  	sSrc
		if ( V_flag )
			printf "++++Error: Could not delete file \t'%s'  \r", sSrc
		else
			//printf "\t\t\t\tDeleted  \t'%s'  \r", sSrc
		endif
	endfor
End


static Function	/S	ListOfMatchingFiles( sSrcDir, sMatch, bUseIgorPath )
// Allows file selection using wildcards. Returns list of matching files. Usage : ListFiles(  "C:foo2:foo1"  ,  "foo*.i*"  )
	string  	sSrcDir, sMatch
	variable	bUseIgorPath 
	string  	lstFilesInDir, lstMatched = ""
	if ( bUseIgorPath )
		PathInfo	Igor
		sSrcDir	= S_Path + sSrcDir[ 1, inf ]					// complete the Igorpath  (eliminate the second colon)
	endif
	NewPath  /Z/O/Q	SymbDir , sSrcDir 
	if ( V_Flag == 0 )								// make sure the folder exists
		lstFilesInDir = IndexedFile( SymbDir, -1, "????" )
		//printf "\tListFiles  All   \t( '%s' \t'%s'  \tuip:%d ) ->\t%s \r",  sSrcDir, sMatch,  lstFilesInDir[0, 200]
		lstMatched = ListMatch( lstFilesInDir, sMatch )
		//printf "\tListFiles Matched\t( '%s' \t'%s'   \tuip:%d ) ->\t%s \r",  sSrcDir, sMatch,  lstMatched[0, 200]
		KillPath 	/Z	SymbDir
	endif
	return	lstMatched
End


//------ File handling for 1 file --------------------------------------------------------------------------------------------------------------------------------------

static Function		Copy1File( sSrc, sTgt )		
	string  	sSrc, sTgt 		
	CopyFile	/O	sSrc	as	sTgt	
	if ( V_flag )
		printf "++++Error: Could not copy file  '%s' \tto\t'%s'  \r", sSrc, sTgt
	else
		//printf "\t\t\t\tCopied  \t\t%s\tto  \t  '%s' \r", pd(sSrc,35), sTgt
	endif
End	

static Function		Move1File( sSrc, sTgt )		
	string  	sSrc, sTgt 		
	CopyFile	/O	sSrc	as	sTgt									// Copy and...
	if ( V_flag )
		printf "++++Error: Could not copy file \t'%s' \tto\t'%s'  \r", sSrc, sTgt
	else
		//printf "\t\t\t\tMoved  \t%s\tto\t'%s' \r", pd(sSrc,36),  sTgt
		DeleteFile		/Z=1	  	sSrc								// ...then delete the source file
	endif
End	

static Function		CreateLink( sFromPathFile, sToLinkFile )
	string  	sFromPathFile, sToLinkFile
	CreateAliasShortcut /O  /P=Igor		sFromPathFile		as	sToLinkFile
	if ( V_flag )
		printf "++++Error: Could not create link \t'%s' \tfrom\t'%s'  \r", sToLinkFile, sFromPathFile
	else
		//printf "\t\t\t\tCreated link \t%s\tfrom\t  '%s' \r", pd( sToLinkFile,36), sFromPathFile
	endif
End


static Function		SetAttr1File( sPath, nVersion, bUseIgorPath )
// Modify the File Date/Time to reflect the program version. The version 1234 is converted to 12:34 .
// This must be done with care to avoid inadvertently overwriting a truely newer file with an older version whose date/time has been set to newer.
	string  	sPath
	variable	nVersion			// version number 0...959 converted to time stamp 00:00...09.59,   -1 means do not modify file time ( e.g. DLLs )
	variable	bUseIgorPath		// 0 for full path, 1 for path starting at the Igor Pro Folder, e.g. User Procedures  or  Igor Extensions 
	variable	VersionSeconds		= trunc( nVersion / 100 )  * 3600 + mod( nVersion, 100 ) * 60
	variable	AdjustedDateTimeSeconds

	if ( bUseIgorPath )
		GetFileFolderInfo /Q 	/P=IGOR 	/Z	sPath
	else
		GetFileFolderInfo /Q 			/Z	sPath
	endif
	string  	sThisDayTime		= Secs2Time( V_modificationDate, 3 )
	variable	OldSecondsThisDay	= 3600 * str2num( sThisDayTime[0,1] ) + 60 * str2num( sThisDayTime[3,4] ) +  str2num( sThisDayTime[6,7] )
	AdjustedDateTimeSeconds	= V_modificationDate - OldSecondsThisDay + VersionSeconds
	//printf "\t\t\t\tSetAttr1File(\t%s\t, V%d )    -> %s  %s (time was %s) \r", pd( sPath, 32) , nVersion, Secs2Date( AdjustedDateTimeSeconds, -1 ), Secs2Time( AdjustedDateTimeSeconds, 3 ),  Secs2Time( V_modificationDate, 3 )
	
	if ( bUseIgorPath )
		if ( nVersion == kKEEPTIME )
			SetFileFolderInfo /Q 	/P=IGOR 	/RO= 0								sPath	// RO : set attribute to R/W (otherwise it is set to read-Only wheninstalling from a CD-ROM)
		else
			SetFileFolderInfo /Q	/P=IGOR 	/RO= 0   /MDAT= (AdjustedDateTimeSeconds)	sPath
		endif
	else
		if ( nVersion == kKEEPTIME )
			SetFileFolderInfo /Q 	 		/RO= 0   								sPath	// RO : set attribute to R/W (otherwise it is set to read-Only wheninstalling from a CD-ROM)
		else
			SetFileFolderInfo /Q 	 		/RO= 0   /MDAT= (AdjustedDateTimeSeconds)	sPath
		endif
	endif
	if ( V_Flag )
		printf "++++Error: SetFileFolderInfo could not set '%s' \r", sPath
	endif
End

Function		GetVersionFromFileTime( sPath )
// Get the File Date/Time  reflecting  the program version. The time 12:34 is converted and returned as 1234 .
	string  	sPath
	variable	nVersion	= -1			// error indicator
	GetFileFolderInfo /Q /Z	sPath
	if ( V_Flag )
		printf "++++Error: GetVersionFromFileTime( '%s' )  failed and returns  %d  \r", sPath, nVersion
		return	-1				// an error occured
	endif
	string sThisDayTime	= Secs2Time( V_modificationDate, 3 )
	nVersion			= 100 * str2num( sThisDayTime[0,1] ) + str2num( sThisDayTime[3,4] ) 
	//printf "\t\t\tGetVersionFromFileTime( '%s' ) returns  V%d  \r", sPath, nVersion
	return	nVersion
End

//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function	/S	FirstToLastDriveList( sDrive )
// Returns a list of drive letters starting at sDrive (usually C:)  up to  of the last R/W drive. 
	string  	sDrive
	string  	sLastDrive	= LastRWDrive( sDrive )
	string  	sDriveList	= ""
	do
		sDriveList	+= sDrive + ";"
		sDrive	= IncrementDrive( sDrive )
	while ( cmpstr( sDrive, sLastDrive ) <= 0 )
	//printf	"\t\t\tFirstToLastDriveList( + %s ) found  R/W drives suitable for FPulse installation :'%s' \r", sDrive, sDriveList
	return	sDriveList
End
	
Function	/S	LastRWDrive( sFirstDrive )
// Returns the drive letter of the last R/W drive starting at sDrive (usually C:) .
// Unfortunately we cannot use 'GetFileFolderInfo' to find the R/W drive as a CD ROM burner would be recognized as writable even if it contains a read-only CD-ROM.
// Instead we try to write a dummy file. If it could be written we have found  a  R/W drive.
	string  	sFirstDrive
	variable	RefNum
	string  	sFilePath
	do
		sFilePath	= sFirstDrive + "FPulseDummy"
		Open 	/Z=1 RefNum	as	sFilePath
		if (  V_Flag )										// could not open
			return	DecrementDrive( sFirstDrive )
		endif
		//printf "\t\t\tLastRWDrive() \t\tFolder  '%s'  exists  (%s) \r", sFirstDrive, S_FileName
		Close	RefNum
		DeleteFile	sFilePath
		sFirstDrive	= IncrementDrive( sFirstDrive )
	while ( 1 )
	return	""
End
	
	
Function	/S	IncrementDrive( sDrive )	
	string  	sDrive
	return ( num2char( char2num( sDrive[ 0, 0 ] ) + 1 ) + sDrive[ 1, Inf ] )
End

Function	/S	DecrementDrive( sDrive )	
	string  	sDrive
	return ( num2char( char2num( sDrive[ 0, 0 ] ) - 1 )  + sDrive[ 1, Inf ] )
End

Function	/S	SearchDirInDrives( sFirstDrive, sLastDrive, sDir ) 
// Look for a drive within the given range that contains 'sDir' . If found return that drive, else return empty string.
	string  	sFirstDrive, sLastDrive, sDir 
	string  	sPath	= sFirstDrive + sDir
	do
		variable	bFound	= SearchDir( sPath ) 
		if ( bFound ) 
			return	sPath[ 0, 1 ]							// return only the 'drive:' , truncate the directory	
		endif
		sPath	= IncrementDrive( sPath )
	while ( cmpstr( sPath[ 0, 1 ] , sLastDrive ) <= 0 )	// normally check within given range, but also avoid endless loop if  'sDir'  was above  'sLastDrive'  form the beginning
 	//printf "\t\t\tSearchDirInDrives() \tFolder  '%s'  does not exist in drives  '%s'  ...  '%s'  . \r", sDir, sFirstDrive, sLastDrive
	return	""
End

Function		SearchDir( sPath ) 
// Look if  'sPath'   (including drive)  is an existing directory.  Return  TRUE  or  FALSE.
	string  	sPath
	variable	bFound 	= 0
	GetFileFolderInfo  /Z	/Q	sPath
	if (  ! V_Flag  &&  V_isFolder  &&  ! V_isReadOnly )				//  V_isFolder : directory  found
		bFound	= TRUE
		//printf "\t\t\tSearchDir( %s ) does %s exist. \r", sPath, SelectString( bFound, "Not" , "" )
	endif
	return	bFound
End

Function	/S	SearchFileInDrives( sFirstDrive, sLastDrive, sDirAndFile ) 
// Look for a drive within the given range that contains 'sDirAndFile' . If found return that drive, else return empty string.
	string  	sFirstDrive, sLastDrive, sDirAndFile 
	string  	sPath	= sFirstDrive + sDirAndFile
	do
		GetFileFolderInfo  /Z	/Q	sPath
		// if (  ! V_Flag  &&  V_isFile  &&  ! V_isReadOnly )				//  V_isFile : file  found
		if (  V_isFile    )										//  V_isFile : file  found
			//printf "\t\t\tSearchFileInDrives() \tFolder  '%s'  exists. Returning  '%s' . \r", sPath, sPath[ 0, 1 ]
			return	sPath[ 0, 1 ]							// return only the 'drive:' , truncate the directory	
		endif
		sPath	= IncrementDrive( sPath )
	while ( cmpstr( sPath[ 0, 1 ] , sLastDrive  ) <= 0 )	// normally check within given range, but also avoid endless loop if  'sDirAndFile'  was above  'sLastDrive'  form the beginning
 	//printf "\t\t\tSearchFileInDrives() \tFolder  '%s'  does not exist in drives  '%s'  ...  '%s'  . \r", sDirAndFile, sFirstDrive, sLastDrive
	return	""
End

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

static Function	/S	FPVersionString()
	nvar		gVersion	= 	root:FPInstall:gVersion
	return	"V" + num2str( trunc( gVersion / 100 ) ) + "." +  num2str( mod ( gVersion, 100 ) )
End

static Function		FPPrintPnLine(  sPanel, x, y, sText )
	string  	sPanel, sText
	variable	x, y
	DrawRect	/W = $sPanel	x ,	y , 		x + ( kPnR - kPnL - 2 * x ), y -8+kTEXTLINES*kYD	// clear the box
	variable	n, nLines	= ItemsInList( sText, "\r" ) 
	for ( n = 0; n < nLines; n += 1 )
		DrawText 	/W = $sPanel	x+5,	y +15+ n*(kYD-7), StringFromList( n, sText, "\r" )			// the offset constants are chosen so the text is placed neatly in respect to the buttons
		printf "\t%s\r",  StringFromList( n, sText, "\r" )	//sText															// Also print in the history window
	endfor
End

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	CODE copied from FPMisc.ipf  and made static

static Function  		FileExists( sPathFile )
// could be coded using  GetFileFolderInfo
// version  with  or  without  symbolic path...
	string 	sPathFile
	variable	nRefNum
	// Open	/Z=1 /R /P=symbPath	nRefNum  as sPathFile	// with	symbolic path.../Z = 1:	does nothing if file is missing
	Open	/Z=1 /R 				nRefNum  as sPathFile	// without symbolic path.../Z = 1:	does nothing if file is missing
	if  ( V_flag )			// could not open
		// printf "\t\tFileExists()  returns FALSE as %s does NOT exist \r", sPathFile 
		return FALSE
	else					// could open and did it so we must close it again...
		// printf "\t\tFileExists()  returns  TRUE  as %s does exist  \r", sPathFile 
		Close nRefNum
		return TRUE
	endif
End


static Function	PossiblyCreatePath( sPath )
// builds the directory or subdirectory 'sPath' .  Builds a  nested directory including all needed intermediary directories in 1 call to this function. First param must be disk.
// Example : PossiblyCreatePath( "C:kiki:koko" )  first builds 'C:kiki'  then C:kiki:koko'  .  The symbolic path is stored in 'SymbPath1'  which could be but is currently not used.
	string 	sPath
	string 	sPathCopy	, sMsg
	variable	r, n, nDirLevel	= ItemsInList( sPath, sDIRSEP ) 
	variable	nRemove	= 1
	for ( nRemove = nDirLevel - 1; nRemove >= 0; nRemove -= 1 )				// start at the drive and then add 1 dir at a time, ...
		sPathCopy		= sPath										// .. assign it an (unused) symbolic path. 
		sPathCopy		= RemoveLastListItems( nRemove, sPathCopy, sDIRSEP )	// ..This  CREATES the directory on the disk
		NewPath /C /O /Q /Z SymbPath1,  sPathCopy	
		if ( V_Flag == 0 )
			//printf "\tPossiblyCreatePath( '%s' )  Removing:%2d of %2d  \t'%s' exists or has been created (V_Flag:%d) \r", sPath, nRemove, nDirLevel, sPathCopy, v_Flag
		else
			sprintf sMsg, "While attempting to create path '%s'  \t'%s' \tcould not be created.", sPath, sPathCopy
			print sMsg //Alert( cSEVERE, sMsg )
		endif
	endfor
	//printf "\tPossiblyCreatePath( '%s' )  \t'%s' exists or has been created (V_Flag:%d) \r", sPath, sPathCopy, v_Flag
End

static Function	/S	RemoveLastListItems( cnt, sList, sSep )
// removes  'cnt'  trailing items from list 
	variable	cnt
	string 	sList, sSep 
	variable	n, nItems
	for ( n = 0; n < cnt; n += 1 )
		nItems	= ItemsInList( sList, sSep ) 				// while the list is getting shorter....
		sList		= RemoveListItem( nItems-1, sList, sSep )	//..always remove the last item
	endfor
	return	sList
End


static constant  cSPACEPIXEL = 3,  cTYPICALCHARPIXEL = 6

static Function  /S  pd( str, len )
// returns string  padded with spaces or truncated so that 'len' (in chars) is approximately achieved
// IGOR4 crashes:	print str,  GetDefaultFontSize( "", "" ),   Tabs are counted  8 pixels by IGOR which is obviously NOT what the user expects...
// empirical: a space is 2 pixels wide for font size 8, 3 pixels wide  for font size 9..12, 4 pixels wide for font size 13
// 161002 automatically encloses str  ->  'str'
	string 	str
	variable	len
	variable	nFontSize		= 10
	//print str, FontSizeStringWidth( "default", 10, 0, str ), FontSizeStringWidth( "default", 10, 0, "0123456789" ), FontSizeStringWidth( "default", 10, 0, "abcdefghij" ), FontSizeStringWidth( "default", 10, 0, "ABCDEFGHIJ" )
	variable	nStringPixel		= FontSizeStringWidth( "default", nFontSize, 0, str )
	variable	nRequestedPixel	= len * cTYPICALCHARPIXEL
	variable	nDiffPixel			= nRequestedPixel - nStringPixel
	variable	OldLen = strlen( str )
	if ( nDiffPixel >= 0 )
		//printf  "Pd( '%s' , %2d ) has pixel:%d \trequested pixel:%2d \tnDiffPixel:%d  padding spaces to len :%d ->'%s' \r", str, len, nStringPixel, nRequestedPixel,nDiffPixel, oldLen+nDiffPixel / cSPACEPIXEL, PadString( str, oldlen + nDiffPixel / cSPACEPIXEL,  0x20 ) 	
		return	"'" + str + "'" + PadString( str, OldLen + nDiffPixel / cSPACEPIXEL,  0x20 )[ strlen( str ), Inf ]
	endif	
	if ( nDiffPixel < 0 )
		//printf  "Pd( '%s' , %2d ) has pixel:%d \trequested pixel:%2d \tnDiffPixel:%d  truncating chars:%d  ->'%s' \r", str, len, nStringPixel, nRequestedPixel,nDiffPixel,   ceil( nDiffPixel / cTYPICALCHARPIXEL ),str[ 0,OldLen - 1 + ceil( nDiffPixel / cTYPICALCHARPIXEL ) ] 
		return	"'" + str[ 0, OldLen - 1 +  nDiffPixel / cTYPICALCHARPIXEL ] + "'"
		//return	"'" + str[ 0, len ] + "'"		// is not better
	endif
End

//-------------------------------------------------------------------------------------------------------------------------------------------

Function		FPulseRestoreDevelopLinks()
// After an installation the links point to \UserIgor\FPulse\ipf,ihf,xop  and any changes from then on are made in these files. 
// To avoid confusion (and to avoid inadvertently overwriting existing files) these links are reset to the development state, e.g. \UserIgor\Ced
	variable	knVERSION	= 0	// indicator for wrong version, only when called from this FPulse_Install . It should be called from  FPulse ! 
	string  	sInstallDriveDir	= ksSCRIPTS_DRIVE + ksMYPRG_DIR
	CreateLinkFiles( sInstallDriveDir, knVERSION )										// here :  'C:UserIgor:Ced' 		
	Beep
	printf "\r\rFPulse links have been reset to the state suitable for program development   '%s' ...\rbut the version %.2lf is not OK (as this procedure should be called from FPulse.)\r", sInstallDriveDir, knVERSION/100
	printf "You must   EXIT  and  RESTART  IGOR   to make the changed links effective !  \r"
End
	
