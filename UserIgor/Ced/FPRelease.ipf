//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//   FPRelease.ipf	04Sept01
//
// This program  makes a Release Version of  FPulse  and  FEval. The programmer must have set the constants  ksVERSION (-> FPulseCed.h)  and  kbIS_RELEASE (-> FPulse.ipf)
// The Release version of FPulse   and  FEval  are created  in any  drive  in ksRELEASE_SRC_DIR  = "FPulse"  (containing subdirectories). 
// 
// This directory  'FPulse'  and  additionally the files  'FPulse_Install.rtf'  and   ....  must be  zipped  with  'Inno-Setup'  into  1 executable ...
// ...which is supplied to the user   by  CD-ROM,  Internet or EMail attachment

// The Release procedure is started with a button from the Release panel which is opened by typing 'PnRelease()  in the command line , then 'FPulseRelease()' is called.

// NO.......................
// The Release procedure is started with  'FPulseRelease()' . This must be typed in the command line, there can be no button for it as this 'Release' file is not
// supplied to the user, so no function can be accessed from the user code .  FPulseRelease() could be called from FPTest , however, as FPTest is also not supplied to the user.
// NO.......................
// CAUTION:
// In the user version  the links point to the release directory   UserIgor:FPulse:xxx   instead of the develop directory  UserIgor:Ced:xxx...
// ...so that all further editing effects the release files which is dangerous as the next  Release  overwrites the changes.
// For this reason it is strongly recommended to execute  'FPulseRestoreDevelopLinks()'  before further editing  (must also be typed into the command line) .

// Before executing  'FPulseRelease()  make sure that ...
//	-  kbIS_RELEASE is set to 1  (see FPulse.ipf )
// 	-  that the three XOPs  are also compiled in the  'Release'  mode. ( 'FP*.xop' )
//	-  FPulse is started at least once after help file changes so that the Help files are compiled

// 040901	Also releases  'FEval' . Removed  'GetInputState'
// 041005	three XOPs  ( 'FP*.xop' )
// 041101	Using  'InnoSetup'  rather than   'FPulse_Install.pxp' which is to be discarded.
// 041109	Check that the three XOPs  are compiled in the  'Release'  mode. ( 'FP*.xop' )
// 041110	Copy the 4 C sources directories  C_FPulseCed, C_FPMc700,  C_FPMc700Tg  and  C_Common

#pragma rtGlobals=1						// Use modern global access method.
#pragma IgorVersion=5.02					// GetFileFolderInfo

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

// Cave 1: ----------- ALL  THESE  CONSTANTS  MUST  BE  THE  SAME  IN FPRELEASE:IPF  AND  IN  PROCEDURE  OF  FPULSE_INSTALL.PXP  --------------
// Cave 2: ----------- ksINSTALLATION_DIR	= "X:UserIgor:FPulse" must be distinct  from  DevelopDir = "C:UserIgor:Ced"   must be distinct  from  ksRELEASE_SRC_DIR = "Y:FPulse"		
// Cave 3: ----------- THE  SCRIPTS  PATH  SHOULD NOT BE CHANGED  TO ENSURE  COMPATIBILITY  WITH  PREVIOUS  INSTALLATIONS

//				ksSCRIPTS_DRIVE		= "C:"								is defined in FP_FPulseConstants.ipf
//				ksAPP_NAME			= "FPulse"								is defined in FP_FPulseConstants
static strconstant	ksMYPRG_DIR			= "UserIgor:Ced"						// where my sources are , 	must be the  SAME  in  FPRelease.ipf  in  FPulseCed.c

static strconstant	ksFPULSE_EXE_DIR	= "UserIgor:FPulseSetupExe"				// where InnoSetup puts  'FPulse xxx Setup.exe'  on my hard disk
static strconstant	ksRELEASE_SRC_DIR	= "UserIgor:FPulseTmp"					// temporary directory where InnoSetup  looks for it's source files on my hard disk, will be automatically deleted after finishing  'FPulseRelease()' 
static strconstant	ksINSTALLATION_DIR	= "UserIgor:FPulse"						// where InnoSetup will  unpack and install   FPulse on the user's hard disk

static strconstant	ksUSER_FILES_LIST	= "FP*.ipf;FP*.txt;*.ihf;*.xop;*.rtf;FE*.ipf;FE*.txt"	// List of file groups to be distributed to the user
static strconstant	ksPROC_FILES_LIST	= "FP*.ipf;FE*.ipf"						// (is LIST can have more items.) List of links to be copied into 'User Procedures' . The link from 'FPulse.ipf' is included but not needed here, it must go into  'Igor Procedures' .
static strconstant	ksHELP_FILES_LIST		= "FP*.ihf"								// is LIST, can have more items e.g. FP*.ihf;Ced*.ihf"

static strconstant	ksDEMOSCRIPTS_LIST	= "Demo*.txt;AP*.*;Sine*.ibw"				// 

static strconstant	ksPRG_START_LNK		= ":Igor Procedures"
static strconstant	ksUSERPROC_LNK		= ":User Procedures"
static strconstant	ksHELP_LNK			= ":Igor Help Files"

static strconstant	ksPRGXOP_LIST		= "FP*.xop"
static strconstant	ksXOP_LNK			= ":Igor Extensions"

static strconstant	ksDEMO_DIR			= ":DemoScripts"						// do not change to ensure compatibility
static strconstant	ksDLL_DIR			= ":Dll"								// do not change to ensure compatibility

static strconstant	ksDLL_FILES_LIST		= "Use1432.dll;1432ui.dll;Cfs32.dll;AxMultiClampMsg.dll;"	// do not use *.dll as attributes are set for all these files in  Windows\System32

//static strconstant	ksCSOURCE_DIR_LIST	= "C_FPulseCed;C_FPMc700;C_FPMc700Tg;C_Common"	// same order in  ksCSOURCE_DIR_LIST and  ksXOP_LIST, but here more files 
//static strconstant	ksXOP_LIST			= "FPulseCed;FP_Mc700;FP_Mc700Tg"					// same order in  ksCSOURCE_DIR_LIST and  ksXOP_LIST, but here less files
static strconstant	ksCSOURCE_DIR_LIST	= "C_FPulseCed;C_FPMc700Tg;C_FPMc700;C_Common"	// same order in  ksCSOURCE_DIR_LIST and  ksXOP_LIST, but here more files 
static strconstant	ksXOP_LIST			= "FPulseCed;FP_Mc700Tg;FP_Mc700"					// same order in  ksCSOURCE_DIR_LIST and  ksXOP_LIST, but here less files
static strconstant	ksCSOURCE_FILES		= "*.c;*.h;*.hpp;*.rc;*.dsp;*.dsw;*.bmp"


static constant		FALSE	= 0
static constant		TRUE	= 1 

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function		FPulseRelease()
	// FPulseRelease() must be executed by the programmer when a new  FPulse  version  is to be released
	string 	sDateTime	= Secs2Date( DateTime, -1 ) 
	string 	sDate	= sDateTime[ 8,9 ] + sDateTime[ 3,4 ] + sDateTime[ 0,1 ] 
	string	  	sHoursMins= Secs2Time( DateTime, 2 )
	string  	sTime	= "_"+ sHoursMins[ 0, 1 ] + sHoursMins[ 3, 4 ] 			// e.g.   '_1307'   <-   '13:07' 
	string  	sSrcDir	= ksSCRIPTS_DRIVE + ksMYPRG_DIR				// e.g. 'C:UserIgor:Ced'
	// print "FPulseRelease()", Date(), Time(), Secs2Date( DateTime, -1 ), sDateTime, sDate, sHoursMins, sTime, sSrcDir

	//  STEP 1 : Make sure that the user never gets a  DEBUG  version which would reveal the code of the trial time limit  and of the test functions.
	if ( kbIS_RELEASE == FALSE )
		printf  "\r++++ Error:  kbIS_RELEASE must be set to 1 \r\r"
		OfferForEdit( ksAPP_NAME + ".ipf" )			// display the procedure window containing the version and bring it to the front
		Beep
		return 0
	endif

	DoAlert 0, "Make sure that the following 3 compilation steps give no errors. \rCheck the DOS box which will be created. " 


	//  STEP 2 : For every version create an  ARCHIVE  subdirectory    e.g.  "C:UseIgor:Ced040315V235"    for the  Igor  and  C  source  files  on the hard disk and copy files into it.
	variable	nVersion	= str2num( ksVERSION ) 	//	knVERSION

//	string  	sReleaseDir	= ksSCRIPTS_DRIVE + ksMYPRG_DIR + sDate + sTime  + "V" + num2str( nVERSION )
//	printf  "----- FPulseRelease() -----  will  build  release version %g  ( %.2lf ) \r", nVERSION/100, Date()

	string  	sReleaseDir	= ksSCRIPTS_DRIVE + ksMYPRG_DIR + sDate + sTime  + "V" + ksVERSION
	printf  "----- FPulseRelease() -----  will  build  release version %s  ( %s ) \r", ksVERSION, Date()
	printf  "\tCreating directory '%s'  and copying files %s \r", sReleaseDir, ksUSER_FILES_LIST
	PossiblyCreatePath( sReleaseDir )												// Create  directory	e.g.	"C:UseIgor:Ced040315V235" 
	CopyFilesFromList( sSrcDir, ksUSER_FILES_LIST, sReleaseDir )							// Copy the current User files (e.g. ipf, ihf, xop..) into it
	CopyFilesFromList( sSrcDir, ksDLL_FILES_LIST, 	 sReleaseDir )							// Copy the 4 DLLs into the  Release directory 
  	string  	sInstalledPrgChkFile	= sReleaseDir + ":" + ksAPP_NAME + ".ipf"				// it is sufficient for only 1 file loose its  true time...

	ModifyFileTime( sInstalledPrgChkFile, nVersion, FALSE )								// ...the hour:minute will be the version
  	//ModifyFileTimeFromList( sReleaseDir, ksUSER_FILES_LIST, knVERSION, FALSE )			// not good: ALL files in my Backup dir loose their true time: the hour:minute will be the version

	// Complile the XOPS in the RELEASE mode and copy then into the release Dir (this overwrites DEBUG XOPS which have been unnecessarily (in ksUSER_FILES_LIST!) copied there a moment ago)
	CallXOPCompiler( sReleaseDir )	// calling  it automatically per command line ensures that  the  XOP distributed to the user is compiled in  RELEASE  mode 

	//  Copy the 4 C sources directories  C_FPulseCed, C_FPMc700,  C_FPMc700Tg  and  C_Common
	variable	n_C_Dir, n_C_DirCnt	= ItemsInList( ksCSOURCE_DIR_LIST )
	for ( n_C_Dir = 0; n_C_Dir < n_C_DirCnt; n_C_Dir += 1 )
		string  	sSource_C_Dir	= StringFromList( n_C_Dir, ksCSOURCE_DIR_LIST ) 			// e.g.  C_FPulsedCed  or  C_FPMc700
		string  	sRelease_C_Dir	= sReleaseDir + ":" + sSource_C_Dir
		printf  "\tCreating directory '%s'  and copying files %s \r", sRelease_C_Dir, ksCSOURCE_FILES
		PossiblyCreatePath( sRelease_C_Dir )											// Create  directory	e.g.	"C:UseIgor:Ced040315V235:C_FPulseCed" 
		CopyFilesFromList( sSrcDir + ":" + sSource_C_Dir, ksCSOURCE_FILES, sRelease_C_Dir  )	// Copy the C sources for the XOP (e.g. c, h, rc..) into the  C-archive dir
	endfor

	//  STEP 3 : Create  the  RELEASE / INSTALLATION  directory  from which Inno-Setup takes the files to build  'FPulse xxx Setup.exe'  which is distributed to the user
	//  We need an extra (temporary) directory as 1. InnoSetup cannot access 'This' (currently executing) file in the working dir  and as  2. FPRelease.ipf  and  FPTest.ipf  must be replaced by wrappers   

	string  	sTmpDrive = ksSCRIPTS_DRIVE
//
//	string  	sTmpDrive	= LastDrive( "C:" )	// Look for all writable disks starting at C: . Here it is intended to find the CD ROM burner. 
//	//  Automatically finding the CD-R/W drive does not work reliably : 1.) there may be USB sticks 2.)  or an intermediate DVD e.g.  a:  b:  c:  DVD=d:  CDRW=e: -> e is not found ....
//	//  ...so we allow changing the found drive
//	printf	"\tAll files to be distributed in the user version are copied into the following directory.\r\tInno-Setup takes the files from there to build  'Setup.exe'  which is distributed to the user.\r"
//	Prompt sTmpDrive, 	"Select drive (possibly insert a formatted  FPulse R/W-CD ) :", popup,  "C:;D:;E:;F:;G:;H:;I:;"
//	DoPrompt  "  Create an FPulse R/W-CD ? ", sTmpDrive
//
//	if ( V_Flag == 0 )		// did not press Cancel
//
		// Copy from the newly created archive to the release CD-ROM  or  release HD directory
		string  	sTmpDir	= sTmpDrive + ksRELEASE_SRC_DIR
		printf  "\tCreating temporary directory  '%s'  and copying files  %s  .  InnoSetup will get it's files from there. \r", sTmpDir, ksUSER_FILES_LIST
		PossiblyCreatePath( sTmpDir )													// Create  directory	e.g.	"E:FPulse" 
		DeleteFiles( sTmpDir, "*.*" )													// Clean it
		CopyFilesFromList( sReleaseDir, ksUSER_FILES_LIST, sTmpDir )							// Copy the current User files (e.g. ipf, xop..) to the temporary dir
  		ModifyFileTimeFromList( sTmpDir, ksUSER_FILES_LIST, nVersion, FALSE )					// OK : ALL files in the release dir loose their true time: the hour:minute will be the version

// 041204	
		CopyStripComments( sReleaseDir, ksPROC_FILES_LIST, sTmpDir, "F*.ipf" )




		PossiblyCreatePath( sTmpDir + ksDLL_DIR  )										// Create  directory	e.g.	"E:FPulse:Dll" 
		DeleteFiles( sTmpDir + ksDLL_DIR, "*.*" )											// Clean it
		CopyFilesFromList( sReleaseDir,	 ksDLL_FILES_LIST, sTmpDir + ksDLL_DIR )				// Copy the 4 DLLs to the temporary dir

		PossiblyCreatePath( sTmpDir+ ksDEMO_DIR  )										// Create  directory	e.g.	"E:FPulse:DemoScripts" 
		DeleteFiles( sTmpDir + ksDEMO_DIR, "*.*" )											// Clean it
		CopyFilesFromList( ksSCRIPTS_DRIVE + ksSCRIPTS_DIR, ksDEMOSCRIPTS_LIST, sTmpDir + ksDEMO_DIR )// Copy some DemoScripts
  		ModifyFileTimeFromList( sTmpDir + ksDEMO_DIR, ksDEMOSCRIPTS_LIST, nVersion, FALSE )	// OK : ALL files in the release dir loose their true time: the hour:minute will be the version
																				// !!! the time is modified again in FPulse_Install.pxp, one modification would be sufficient (here already the release directory is affected)
		// Copy an empty wrapper file to the user CD-ROM  rather than the real files  in those cases where the real files are not to be distributed. Workaround as Igor does not allow conditional compilation.
		Copy1File( sReleaseDir + ":" + "FPWrapper.ipf", sTmpDir +  ":" + "FPTest.ipf" )
		Copy1File( sReleaseDir + ":" + "FPWrapper.ipf", sTmpDir +  ":" + "FPRelease.ipf" )
		DeleteFiles( sTmpDir, "FPWrapper.ipf" )

		// Create the trial time file and copy it to the release HD directory
// 2009-10-22 modify for Igor6    remove birthday
//		xUtilBdMake( days, ksVERSION, sTmpDir )

		CallInno()
//
//	endif
//
		string  	sReleaseExeForUser	= ksSCRIPTS_DRIVE + ksFPULSE_EXE_DIR + ":" + ksAPP_NAME + " " + ksVERSION +  " Setup.exe"
		printf "Finished.:\tCreated source files archive \t'%s'  \r\t\t\tCreated release version \t\t'%s' \r ", sReleaseDir, sReleaseExeForUser

End



Function		FPulseRestoreDevelopLinks()
// After an installation the links point to \UserIgor\FPulse\ipf,ihf,xop  and any changes from then on are made in these files. 
// To avoid confusion (and to avoid inadvertently overwriting existing files) these links are reset to the development state, e.g. \UserIgor\Ced
// NOTE: In a user installation this file is an empty wrapper.   Open / load   'RestoreDevLinks()'   instead and call    'FPulseRestoreDevLinks()'
	string  	sInstallDriveDir	= ksSCRIPTS_DRIVE + ksMYPRG_DIR
	variable	nVersion	= str2num( ksVERSION ) 	//	knVERSION
	CreateLinkFiles( sInstallDriveDir, nVersion )									// here :  'C:UserIgor:Ced' 		
	Beep
	printf "\rFPulse links have been reset to the state suitable for program development   '%s'  (V%s)\r", sInstallDriveDir, ksVERSION
	printf "You must   EXIT  and  RESTART  IGOR   to make the changed links effective !  \r"
End

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  Big Helpers ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

static Function		CreateLinkFiles( sInstallDriveDir, nVersion )
	// Create  links. Currently used only to restore links to the development mode (=C:UserIgor:Ced)  after they have been set to 'C:UserIgor:FPulse'   by InnoSetup  
	string  	sInstallDriveDir													// here :  'C:UserIgor:Ced' 
	variable	nVersion
	string  	sPrgPath, sHelpPath, sXopPath//, sGISPath
	string  	sPrgLink,  sHelpLink, sXopLink//,  sGISLink
	sPrgPath		= sInstallDriveDir		+ ":"	+ ksAPP_NAME + ".ipf" 				// e.g.  "C:UserIgor:FPulse.ipf"
	sPrgLink		= ksPRG_START_LNK 	+ ":"	+ ksAPP_NAME + ".ipf" 		+ ".lnk"	// e.g.  ":Igor Procedures:FPulse.ipf.lnk"
	CreateAlias( sPrgPath, sPrgLink )
	ModifyFileTime( sPrgLink, nVersion, TRUE )

	CreateLinksFromList( sInstallDriveDir, ksHELP_FILES_LIST, ksHELP_LNK )				// e.g. 'C:UserIgor:FPulse:FPulse.ihf , FPulseCed.ihf' ->  'Igor Help Files:FPulse.ihf.lnk , FPulseCed.ihf.lnk'
	ModifyLinkTimeFromList( ksHELP_LNK,  ksHELP_FILES_LIST,  nVersion, TRUE )

	CreateLinksFromList( sInstallDriveDir, ksPRGXOP_LIST, ksXOP_LNK )					// e.g.  'C:UserIgor:FPulseCed.xop'
	ModifyLinkTimeFromList( ksXOP_LNK,  ksPRGXOP_LIST,  nVersion, TRUE )			// e.g.  ":Igor Extensions:FPulseCed.xop.lnk"
 
	CreateLinksFromList( sInstallDriveDir, ksPROC_FILES_LIST, ksUSERPROC_LNK )		// e.g. 'C:UserIgor:Ced:FPulse.ipf , FPDisp.ipf...' 	->  'User Procedures:FPulse.ipf.lnk , FPDisp.ipf.lnk...'
	ModifyLinkTimeFromList( ksUSERPROC_LNK, ksPROC_FILES_LIST, nVersion, TRUE )
End


//------ File handling for a list of groups of files  --------------------------------------------------------------------------------------------------------------------------------------

static Function		CopyFilesFromList( sSrcDir, lstFileGroups, sTargetDir )
// old version , Install.ipf ( was FPulse_Install.pxp)  has  a newer, more versatile one
	string  	sSrcDir, lstFileGroups, sTargetDir 
	variable	n, nCnt	= ItemsInList( lstFileGroups )
	string  	sFileGroup	
	for ( n = 0; n < nCnt; n += 1 )
	  	sFileGroup		= StringFromList( n, lstFileGroups )
		CopyFiles( sSrcDir, sFileGroup, sTargetDir ) 						// Copy the current User files (e.g. ipf, xop..) into it
	endfor
End

static Function		ModifyFileTimeFromList( sDir, lstFileGroups, Version, bUseIgorPath )
// the hour:minute will be the version
	string  	sDir, lstFileGroups
	variable	Version, bUseIgorPath
	variable	n, nCnt	= ItemsInList( lstFileGroups )
	string  	sFileGroup	
	for ( n = 0; n < nCnt; n += 1 )
	  	sFileGroup		= StringFromList( n, lstFileGroups )
		ModifyFileTimes( sDir, sFileGroup, Version, bUseIgorPath ) 						// the hour:minute will be the version
	endfor
End
	
static Function		ModifyLinkTimeFromList( sDir, lstFileGroups, Version, bUseIgorPath )
// the hour:minute will be the version
	string  	sDir, lstFileGroups
	variable	Version, bUseIgorPath
	variable	n, nCnt	= ItemsInList( lstFileGroups )
	string  	sFileGroup	
	for ( n = 0; n < nCnt; n += 1 )
	  	sFileGroup		= StringFromList( n, lstFileGroups ) + ".lnk"
		ModifyFileTimes( sDir, sFileGroup, Version, bUseIgorPath ) 						// the hour:minute will be the version
	endfor
End
	
static Function		CreateLinksFromList( sSrcDir, lstFileGroups, sTgtDir )
// old version , FPulse_Install.pxp has  a newer one
	string  	sSrcDir, lstFileGroups, sTgtDir
	variable	n, nCnt	= ItemsInList( lstFileGroups )
	string  	sFileGroup	
	for ( n = 0; n < nCnt; n += 1 )
	  	sFileGroup		= StringFromList( n, lstFileGroups )// + ".lnk"			// links have the extension '.lnk'  appended to the original extension (=2 dots!)
		CreateLinks( sSrcDir, sFileGroup, sTgtDir ) 					
	endfor
End


//------ File handling for 1 group of files --------------------------------------------------------------------------------------------------------------------------------------

static Function		CopyFiles( sSrcDir, sMatch, sTgtDir )
// old version , Install.ipf ( was FPulse_Install.pxp)  has  a newer, more versatile one
// e.g. 		CopyFiles(  "D:UserIgor:Ced"  ,  "FP*.ipf" , "C:UserIgor:CedV235"  ) .  Wildcards  *  are allowed .
	string  	sSrcDir, sMatch, sTgtDir
	string  	lstMatched	= ListOfMatchingFiles( sSrcDir, sMatch, FALSE )
	variable	n, nCnt		= ItemsInList( lstMatched )
	for ( n = 0; n < nCnt; n += 1 )
		string  	sSrc	= sSrcDir + ":" + StringFromList( n, lstMatched )
		string  	sTgt	= sTgtDir + ":" + StringFromList( n, lstMatched )
		Copy1File( sSrc, sTgt )
	endfor
End


static Function		ModifyFileTimes( sDir, sMatch, Version, bUseIgorPath )
// e.g. 		ModifyFileTimes(  "D:UserIgor:Ced"  ,  "FP*.ipf"  ) . . Wildcard *   is only allowed in filebase,   * is NOT allowed in the file extension.
	string  	sDir, sMatch
	variable	Version, bUseIgorPath
	
	string  	lstMatched	= ListOfMatchingFiles( sDir, sMatch, bUseIgorPath )
	variable	n, nCnt		= ItemsInList( lstMatched )
	 printf "\t\t\tModifyFileTimes( Matched\t%s,\t%s   \t%g\t ) \t: %2d\tfiles  %s \r",  sDir, sMatch, Version, nCnt, lstMatched[0, 300]
	for ( n = 0; n < nCnt; n += 1 )
		string  	sPath	= sDir + ":" + StringFromList( n, lstMatched )
		ModifyFileTime( sPath, Version, bUseIgorPath )
	endfor
End


static Function		DeleteFiles( sSrcDir, sMatch )
// e.g. 		DeleteFiles(  "D:UserIgor:Ced"  ,  "FP*.ipf"  ) . Wildcards  *  are allowed .
	string  	sSrcDir, sMatch
	string  	lstMatched	= ListOfMatchingFiles( sSrcDir, sMatch, FALSE )
	variable	n, nCnt		= ItemsInList( lstMatched )
	// printf "\tDeleteFiles( Matched\t%s,\t%s   \t ) \t: %2d\tfiles  %s \r",  sSrcDir, sMatch, nCnt, lstMatched[0, 300]
	for ( n = 0; n < nCnt; n += 1 )
		string  	sSrc	= sSrcDir + ":" + StringFromList( n, lstMatched )
		DeleteFile		/Z=1	  	sSrc
		if ( V_flag )
			printf "++++Error: Could not delete file \t'%s'  \r", sSrc
		else
			printf "\t\t\t\tDeleted  \t'%s'  \r", sSrc
		endif
	endfor
End


Function		CreateLinks( sSrcDir, sMatch, sTgtDir )
// e.g. 		CreateLinks(  "D:UserIgor:Ced"  ,  "FP*.ipf" , "D:....:Igor Pro Folder:User Procedures"  ) . Wildcard *   is only allowed in filebase,   * is NOT allowed in the file extension.
	string  	sSrcDir, sMatch, sTgtDir
	string  	lstMatched	= ListOfMatchingFiles( sSrcDir, sMatch, FALSE )
	variable	n, nCnt		= ItemsInList( lstMatched )
	// printf "\tCreateLinks(  Matched \t%s,\t%s   \t->\t%s  ) \t: %2d\tfiles  %s \r",  sSrcDir, sMatch, sTgtDir, nCnt, lstMatched[0, 300]
	for ( n = 0; n < nCnt; n += 1 )
		string  	sSrc	= sSrcDir + ":" + StringFromList( n, lstMatched )
		string  	sTgt	= sTgtDir + ":" + StringFromList( n, lstMatched ) + ".lnk"
		CreateAlias( sSrc, sTgt )
	endfor  
End

// 040831 no longer static, should be in misc ...
//static Function	/S	ListOfMatchingFiles( sSrcDir, sMatch, bUseIgorPath )
//------ File handling for 1 file --------------------------------------------------------------------------------------------------------------------------------------

static Function		Copy1File( sSrc, sTgt )		
	string  	sSrc, sTgt 		
	CopyFile	/O	sSrc	as	sTgt	
	if ( V_flag )
		printf "++++Error: Could not copy file  '%s' \tto\t'%s'  \r", sSrc, sTgt
	else
		printf "\t\t\tCopied  \t\t%s\tto  \t  '%s' \r", pd(sSrc,35), sTgt
	endif
End	


static Function		CreateAlias( sFromPathFile, sToLinkFile )
	string  	sFromPathFile, sToLinkFile
	CreateAliasShortcut /O  /P=Igor		sFromPathFile		as	sToLinkFile
	if ( V_flag )
		printf "++++Error: Could not create link \t'%s' \tfrom\t'%s'  \r", sToLinkFile, sFromPathFile
	else
		// printf "\t\t\t\tCreated link \t%s\tfrom\t  '%s' \r", pd( sToLinkFile,36), sFromPathFile
	endif
End


static Function		ModifyFileTime( sPath, nVersion, bUseIgorPath )
// Modify the File Date/Time to reflect the program version. The version 1234 is converted to 12:34 .
// This must be done with care to avoid inadvertently overwriting a truely newer file with an older version whose date/time has been set to newer.
	string  	sPath
	variable	nVersion, bUseIgorPath
	variable	VersionSeconds			= trunc( nVersion / 100 )  * 3600 + mod( nVersion, 100 ) * 60
	variable	AdjustedDateTimeSeconds

	if ( bUseIgorPath )
		GetFileFolderInfo /Q 	/P=IGOR 	/Z	sPath
	else
		GetFileFolderInfo /Q 			/Z	sPath
	endif
	//variable	Seconds			= V_modificationDate + 3600 
	string  	sThisDayTime		= Secs2Time( V_modificationDate, 3 )
	variable	OldSecondsThisDay	= 3600 * str2num( sThisDayTime[0,1] ) + 60 * str2num( sThisDayTime[3,4] ) +  str2num( sThisDayTime[6,7] )
	AdjustedDateTimeSeconds	= V_modificationDate - OldSecondsThisDay + VersionSeconds
	printf "\t\t\t\tModifyFileTi(\t%s\t, V%d,\tuip:%d )    -> %s  %s (time was %s) \r", pd( sPath, 32) , nVersion, bUseIgorPath, Secs2Date( AdjustedDateTimeSeconds, -1 ), Secs2Time( AdjustedDateTimeSeconds, 3 ),  Secs2Time( V_modificationDate, 3 )
	
	if ( bUseIgorPath )
		SetFileFolderInfo  	/P=IGOR 	/MDAT= (AdjustedDateTimeSeconds) sPath
	else
		SetFileFolderInfo  			/MDAT= (AdjustedDateTimeSeconds) sPath
	endif
	//GetFileFolderInfo sPath
	// print Secs2Time( V_modificationDate, 3 )
End

//Function		GetVersionFromFileTime( sPath )
//// Get the File Date/Time  reflecting  the program version. The time 12:34 is returneds as converted to 1234 .
//	string  	sPath
//	GetFileFolderInfo /Q /Z	sPath
//	variable	Seconds	= V_modificationDate + 3600 
//	string  	sThisDayTime	= Secs2Time( V_modificationDate, 3 )
//	variable	nVersion		= 100 * str2num( sThisDayTime[0,1] ) + str2num( sThisDayTime[3,4] ) 
//	printf "\t\tGetVersionFromFileTime( '%s' ) returns  V%d  \r", sPath, nVersion
//	return	nVersion
//End

//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

static Function	/S	LastDrive( sDrive )
// Returns the drive letter of the last R/W drive starting at sDrive (usually C:) . Any writable disk above C: is included e.g. a CD ROM burner. This is not intended but does not hurt.
	string  	sDrive
	do
		GetFileFolderInfo  /Z	/Q	sDrive
		if (  V_Flag  ||  ! V_isFolder  ||   V_isReadOnly )		// root directory NOT found
			return	DecrementDrive( sDrive )
		endif
		// printf "\t\t\tLastDrive() \t\tFolder  '%s'  exists \r", sDrive
		sDrive	= IncrementDrive( sDrive )
	while ( 1 )
	return	""
End
	
static Function	/S	IncrementDrive( sDrive )	
	string  	sDrive
	return ( num2char( char2num( sDrive[ 0, 0 ] ) + 1 ) + sDrive[ 1, Inf ] )
End

static Function	/S	DecrementDrive( sDrive )	
	string  	sDrive
	return ( num2char( char2num( sDrive[ 0, 0 ] ) - 1 )  + sDrive[ 1, Inf ] )
End

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	CODE copied from FP_Misc.ipf  and made static

static Function	PossiblyCreatePath( sPath )
// builds the directory or subdirectory 'sPath' .  Builds a  nested directory including all needed intermediary directories in 1 call to this function. First param must be disk.
// Example : PossiblyCreatePath( "C:kiki:koko" )  first builds 'C:kiki'  then C:kiki:koko'  .  The symbolic path is stored in 'SymbPath1'  which could be but is currently not used.
	string 	sPath
	string 	sPathCopy	, sMsg
	variable	r, n, nDirLevel	= ItemsInList( sPath, ksDIRSEP ) 
	variable	nRemove	= 1
	for ( nRemove = nDirLevel - 1; nRemove >= 0; nRemove -= 1 )				// start at the drive and then add 1 dir at a time, ...
		sPathCopy		= sPath										// .. assign it an (unused) symbolic path. 
		sPathCopy		= RemoveLastListItems( nRemove, sPathCopy, ksDIRSEP )	// ..This  CREATES the directory on the disk
		NewPath /C /O /Q /Z SymbPath1,  sPathCopy	
		if ( V_Flag == 0 )
			// printf "\tPossiblyCreatePath( '%s' )  Removing:%2d of %2d  \t'%s' exists or has been created (V_Flag:%d) \r", sPath, nRemove, nDirLevel, sPathCopy, v_Flag
		else
			sprintf sMsg, "While attempting to create path '%s'  \t'%s' \tcould not be created.", sPath, sPathCopy
			print sMsg //Alert( kERR_SEVERE, sMsg )
		endif
	endfor
	// printf "\tPossiblyCreatePath( '%s' )  \t'%s' exists or has been created (V_Flag:%d) \r", sPath, sPathCopy, v_Flag
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
	// print str, FontSizeStringWidth( "default", 10, 0, str ), FontSizeStringWidth( "default", 10, 0, "0123456789" ), FontSizeStringWidth( "default", 10, 0, "abcdefghij" ), FontSizeStringWidth( "default", 10, 0, "ABCDEFGHIJ" )
	variable	nStringPixel		= FontSizeStringWidth( "default", nFontSize, 0, str )
	variable	nRequestedPixel	= len * cTYPICALCHARPIXEL
	variable	nDiffPixel			= nRequestedPixel - nStringPixel
	variable	OldLen = strlen( str )
	if ( nDiffPixel >= 0 )
		// printf  "Pd( '%s' , %2d ) has pixel:%d \trequested pixel:%2d \tnDiffPixel:%d  padding spaces to len :%d ->'%s' \r", str, len, nStringPixel, nRequestedPixel,nDiffPixel, oldLen+nDiffPixel / cSPACEPIXEL, PadString( str, oldlen + nDiffPixel / cSPACEPIXEL,  0x20 ) 	
		return	"'" + str + "'" + PadString( str, OldLen + nDiffPixel / cSPACEPIXEL,  0x20 )[ strlen( str ), Inf ]
	endif	
	if ( nDiffPixel < 0 )
		// printf  "Pd( '%s' , %2d ) has pixel:%d \trequested pixel:%2d \tnDiffPixel:%d  truncating chars:%d  ->'%s' \r", str, len, nStringPixel, nRequestedPixel,nDiffPixel,   ceil( nDiffPixel / cTYPICALCHARPIXEL ),str[ 0,OldLen - 1 + ceil( nDiffPixel / cTYPICALCHARPIXEL ) ] 
		return	"'" + str[ 0, OldLen - 1 +  nDiffPixel / cTYPICALCHARPIXEL ] + "'"
		//return	"'" + str[ 0, len ] + "'"		// is not better
	endif
End

//==================================================================================================================
//  Building the Trial Time file name (TTF)



//==================================================================================================================

// 2009-10-22 modify for Igor6    remove birthday
//
//strconstant	ksCRYPT_BASE	= "cryptbd"		// must be the  SAME  in  FPRelease.ipf  in  FPulseCed.c
//strconstant	ksCRYPT_EXT		= ".dll"			// must be the  SAME  in  FPRelease.ipf  in  FPulseCed.c
//
//static  Function	/S	BuildTTFileNm( sVersion )
//	string  	sVersion
//	string  	sScrambled  =  ScrambleLetterDigit( sVersion ) 
//	string  	sNm	= ksCRYPT_BASE + sScrambled + ksCRYPT_EXT
//	printf "\t\tBuildTTFileNm( %s ) -> '%s'  -> '%s' --> '%s' \r", sVersion, sScrambled, ScrambleLetterDigit( sScrambled ), sNm
//	return	sNm
//End
//
//static  Function	/S	ScrambleLetterDigit( sString )
//// Codes version string  e.g.  241c   very simply so that it is not immediately recognised as such. Coding and decoding is symmetrical  ( uses same function )
//	string  	sString
//	variable 	n, len	= strlen( sString )
//	string  	sResult	= ""
//	for ( n = len - 1 ; n >= 0; n -= 1 )
//		sResult += Scramble1( sString[ n, n ] )		// reverse string
//	endfor
//	printf "\t\tScrambleLetterDigit( %s ) -> '%s'  \r", sString, sResult
//	return	sResult
//End
//	
//static  Function	/S		Scramble1( sChar )
//// Only letters and digits are allowed, but no underscore
//	string  	sChar
//	variable	nOrg	= char2num( sChar )
//	nOrg	= ( char2num( "0" ) <= nOrg  &&  	nOrg	<= char2num( "9" )  )	?  nOrg - char2num( "0" ) 		:  nOrg	// map '0'...'9'  to number  0..9
//	nOrg	= ( char2num( "a" ) <= nOrg  &&  	nOrg	<= char2num( "z" )  )	?  nOrg - char2num( "a" ) + 10	:  nOrg	// map 'a'...'z'  to number 10..36
//	nOrg	= ( char2num( "A" ) <= nOrg  &&	nOrg	<= char2num( "Z" )  )	?  nOrg - char2num( "A" ) + 10	:  nOrg	// map 'A'...'Z'  to number 10..36
//	// Add 18 and compute the remainder when dividing by 36
//	nOrg	+= 18					// must be half of 36
//	nOrg	= mod( nOrg, 36 )
//	if ( nOrg < 10 )
//		return	num2str( nOrg )
//	else
//		return	num2char( nOrg - 10 + char2num( "a" ) )
//	endif 
//End

//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Call  INNO setup to build the exe file distributed to the user

static  Function	CallXOPCompiler( sReleaseDir )
	string  	sReleaseDir
	string  	sSrcDir	= ksSCRIPTS_DRIVE + ksMYPRG_DIR
	string  	sCmd	= "msdev.exe  "			
	string  	sMyPrgDir	= ReplaceString(  ":" , ksMYPRG_DIR, "\\" )
	
	variable	nXop, nXopCnt	= ItemsInList( ksXOP_LIST )

	for ( nXop = 0; nXop < nXopCnt; nXop += 1 )

		string  	sSource_C_Dir	= StringFromList( nXop, ksCSOURCE_DIR_LIST ) 		// e.g.  C_FPulsedCed  or  C_FPMc700
		string  	sXop			= StringFromList( nXop, ksXOP_LIST ) 				// e.g.  FPulsedCed  or  FPMc700

		string  	sProject	= ksSCRIPTS_DRIVE + "\\" + sMyPrgDir + "\\" + sSource_C_Dir + "\\" + sXop + ".dsp /MAKE "
		string  	sNameCfg	= "\"" + sXop + " - Win32 Release\"" + " /REBUILD"
	
		string  	sStr 		= sCmd + " " + sProject + " " + sNameCfg
		printf  "\tCompiling XOP \t'%s'   \tin\t'%s' \t-> \t'%s' \r", sXop, sSource_C_Dir, sStr
		ExecuteScriptText  /W=30		sStr	// wait 30 secs (twice the empirical value for the compile and link time) . If we do not wait Igor continues immediately before compiling the XOP has been finished

		CopyFilesFromList( sSrcDir + ":" + sSource_C_Dir, "*.xop", sReleaseDir )			// Copy the RELEASE XOPS into the release Dir (this overwrites DEBUG XOPS which have been unnecessarily copied there a moment ago)
	endfor
End


static  Function	CallInno()
	//  Cave: 1: Must be modified for Win 98 or other Windows versions  ('cmd.exe'  may change)
	//  Cave: 2. The  keywords  'Vers, ODir, Birth, Src, Msk'  must be the same as in  'FPulse.iss'  !
	//  Cave: 3: Inno's  default installation path must be changed so that it does not contain spaces ('Inno Setup 4' -> 'InnoSetup4' , or even 'Inno4' to save some bytes)
	//  Cave: 4: The workaround using an explicit call to  'cmd.exe  /K '  is needed so that the DOS window possibly containing error messages is not immediately closed.

	// string  	sCmd 	= "D:\\Programme\\InnoSetup4\\iscc.exe"					// works but closes DOS window immediately  so that errorr messages cannot be read
// 2009-10-22 modify for Igor6   
//	string  	sCmd 	= "cmd.exe  /K  "  +  "D:\\Programme\\InnoSetup4\\iscc.exe" + " "	
	string  	sCmd 	= "cmd.exe  /K  "  +	"\" "  +  "\"C:\\Program files\\Inno Setup 5\\iscc.exe\"" + " "	// special syntax ! e.g.  [ cmd /c " "c:\path with\spaces\binary" "arg" " ]

	string  	sMyPrgDir	= ReplaceString(  ":" , ksMYPRG_DIR, "\\" )
	string  	sIssScript 	= ksSCRIPTS_DRIVE + "\\" + sMyPrgDir + "\\FPulse.iss"		// the path to the InnoSetup script , e.g. 'C:\UserIgor\Ced\FPulse.iss'
	
	string  	sAppNm	= "\"/dAppNm=" 	+ ksAPP_NAME + "\""	
	
	string  	sVers	= ksVERSION		
	string  	sVersion	= "\"/dVers=" 		+ sVers + "\""	
	
// 2009-10-22 modify for Igor6    remove birthday
//	string  	sBirthFile	= "\"/dBirth=" 		+ BuildTTFileNm( sVers ) + "\""	
	string  	sBirthFile	= ""
	
	string  	sTmpDir	= ReplaceString(  ":" , ksRELEASE_SRC_DIR, "\\" )			// where InnoSetup gets the FPulse source files
	string  	sSrc		= ksSCRIPTS_DRIVE + "\\" + sTmpDir					// where InnoSetup gets the FPulse source files , e.g. 'C:\UserIgor\FPulseTmp' . CANNOT be the working dir 'C:\UserIgor\Ced' !
	string  	sSource	= "\"/dSrc=" 		+ sSrc + "\""	
	
	string  	sMask	= "\"/dMsk=" 		+ sSrc + "\\*.*"	 + "\""
	
	string  	sOut		= ksSCRIPTS_DRIVE  + "\\" + ReplaceString(  ":" , ksFPULSE_EXE_DIR, "\\" )	//  where InnoSetup puts  'FPulse xxx Setup.exe' , e.g. 'C:\UserIgor\Ced\FPulseSetupExe'
	string  	sOutputDir	= "\"/dODir=" 		+ sOut + "\""		
	
	string  	sDDir	= ksSCRIPTS_DRIVE  + "\\" + ReplaceString(  ":" , ksINSTALLATION_DIR, "\\" )//  where InnoSetup will  unpack and install   FPulse , e.g. 'C:\UserIgor\FPulse
	string  	sDefaultDir= "\"/dDDir=" 		+ sDDir + "\""		
	
	string  	sStr 		= sCmd + " " + sIssScript + " " + sAppNm + " " + sVersion + " " + sBirthFile + " " + sSource + " " + sMask + " " + sOutputDir + " " + sDefaultDir 
	printf "\t%s   \r", sStr
	ExecuteScriptText  sStr
End

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//    RELEASE PANEL

Function		PnRelease()	
//	string  	sFolder	= ksACOld						// requires that  'Acq'  is running
//	InitPanelRelease( sFolder, ":dlg:tPnRelease" )			// constructs the text wave  'root:uf:aco:dlg:tPnPref'  defining the panel controls
//	ConstructOrDisplayPanel(  "PanelRel", "Release", sFolder, ":dlg:tPnRelease",  100, 98 )
	string  	sFolder	= ""			
	InitPanelRelease( sFolder, "dlg:tPnRelease" )			// constructs the text wave  'root:uf:dlg:tPnPref'  defining the panel controls
	ConstructOrDisplayPanel(  "PanelRel", "Release", sFolder, "dlg:tPnRelease",  100, 98 )
End

static  Function		InitPanelRelease( sFolder, sPnOptions )
	string  	sFolder, sPnOptions
//	string		sPanelWvNm = "root:uf:" + sFolder + sPnOptions				// requires that  'Acq'  is running
	string		sPanelWvNm = "root:uf:" + sPnOptions
	variable	n = -1, nItems = 30
	make /O /T /N=(nItems)	$sPanelWvNm
	wave  /T	tPn	=		$sPanelWvNm
	n += 1;	tPn[ n ] =	"PN_BUTTON;	buCheckReleaseSetting				;Check release settings "
// 2009-10-22 modify for Igor6    remove birthday
//	n += 1;	tPn[ n ] =	"PN_BUTTON;	buRemainingTrialTime				;Remaining Trial time"
	n += 1;	tPn[ n ] =	"PN_BUTTON;	buCreateRelease					;Create Release "
	redimension  /N = (n+1)	tPn 
End


Function		buCheckReleaseSetting( ctrlName ) : ButtonControl
	string 	ctrlName		
	CheckReleaseSetting()
	OfferForEdit( ksAPP_NAME + ".ipf" )			// display the procedure window containing the version and bring it to the front
End

static  Function	OfferForEdit( sProcFileName )	
	// display a procedure window and bring it to the front
	string  	sProcFileName
	string  	sPath	= ksSCRIPTS_DRIVE + ksMYPRG_DIR + ":" + sProcFileName
	Execute /P "OpenProc    \"" + sPath + "\""								// display a procedure window...
	MoveWindow  /P=$ksAPP_NAME + ".ipf" 1,1,1,1							// ...and bring it to the front
End

static  Function	CheckReleaseSetting()
	string  	sCompileMode	= SelectString( kbIS_RELEASE, "DEBUG   ?!?!?", "Release \t  = \tOK" )
	printf  "\r\tCurrent settings: \r\t\tMode : \t\t%s\r\t\tVersion :  \t%s\r", sCompileMode, ksVERSION
End


// 2009-10-22 modify for Igor6    remove birthday
//Function		buRemainingTrialTime( ctrlName ) : ButtonControl
//	string 	ctrlName		
//	xUtilRemaining( 2 )
//End


Function		buCreateRelease( ctrlName ) : ButtonControl
	string 	ctrlName		
	FPulseRelease()
End

//==============================================================================================================================

// 041204	
static  Function		CopyStripComments( sSrcDir, lstFiles, sTgtDir, sMatch )
// Read  'lstFiles' , strips comments and writes...
	string  	sSrcDir, lstFiles, sTgtDir, sMatch
	string  	lstMatched	= ListOfMatchingFiles( sSrcDir, sMatch, FALSE )
	variable	n, nCnt		= ItemsInList( lstMatched )
	// printf "\tCopyStripComments(  Matched \t%s,\t%s   \t->\t%s  ) \t: %2d\tfiles  %s \r",  sSrcDir, sMatch, sTgtDir, nCnt, lstMatched[0, 300]
	for ( n = 0; n < nCnt; n += 1 )
		string  	sSrc	= sSrcDir + ":" + StringFromList( n, lstMatched )
		string  	sTgt	= sTgtDir + ":" + StringFromList( n, lstMatched )
		// printf "\tCopyStripComments( '%s' ) \tSrc: %s  \tTgt: %s   \r", lstFiles, pd(sSrc,28),  pd( sTgt, 28)
		CopyStripComments1File( sSrc, sTgt )

	endfor
End


static Function		CopyStripComments1File( sFilePath, sTgtPath )
// Reads  procedure  file  xxx.ipf.   Data must be delimited by CR, LF or both.  Removes comments starting with  // 
// Does  NOT remove  after // when in  Picture  or in  " string " 
	string		sFilePath, sTgtPath								// can be empty ...
	variable	nRefNum, nRefNumTgt, nLine = 0
	string		sLine			= ""
	variable	bIsInPicture	= FALSE
	
	Open /Z=2 /R	nRefNum  	   as	sFilePath					// /Z = 2: opens dialog box  if file is missing,  /Z = 1: no dialog / does nothing if file is missing
	Open /Z=2 	nRefNumTgt as sTgtPath					//
	if ( nRefNum != 0 )									// file could be missing  or  user cancelled file open dialog
		if ( nRefNumTgt != 0 )								
			do 										// ..if  ReadPath was not an empty string
				FReadLine nRefNum, sLine
				if ( strlen( sLine ) == 0 )					// Only at file end the line length is 0 . Empty lines have line length 1 due to the CR
					break
				endif

				// Do  NOT  remove  characters after  '//'  if we are within a picture 
				if ( ! bIsInPicture )
					if ( ( cmpstr( FirstWord( sLine ), "PICTURE" ) == 0  )  ||  ( cmpstr( FirstWord( sLine ), "STATIC" ) == 0  &&  cmpstr( SecondWord( sLine ), "PICTURE" ) == 0   ) )				
						bIsInPicture = TRUE
					endif
				endif
				if ( bIsInPicture )
					if ( ( cmpstr( FirstWord( sLine ), "END" ) == 0  ) )
						bIsInPicture	= FALSE
					endif
				endif


				// printf "\tCopyStripComments1File() \tInPic:%d \t%s ",  bIsInPicture, sLine
				if ( ! bIsInPicture )
					sLine = RemoveLineEnd( sLine,  "//", 0 )	// remove all comments  starting with ' // ' 
// 051006
sLine = RemoveDebugPrintLine( sLine )	// a Debug print line is a line starting with  at least 1 Tab, then any number of tabs (and possibly spaces) up to  'Tab Blank printf" Blank Tab...' 
				endif
				
				// Remove all empty lines
				string  	sCompactedLine	= RemoveWhiteSpace( sLine )
				if ( strlen( sCompactedLine ) == 1 )
					continue
				endif


				fprintf  nRefNumTgt, "%s\n" , sLine			// \n appends 0A . In can be omitted but is included here as the ipf source file also contains it.
				// printf "\tCopyStripComments1File() \t\t%s ", sLine

				nLine += 1
			while ( TRUE )     							//...is not yet end of file EOF
			Close nRefNumTgt							// Close the output file
		else
			printf "++++Error: Could not open output file '%s' . (CopyStripComments1File) \r", sTgtPath
		endif
		Close nRefNum									// Close the input file
	else
		printf "++++Error: Could not open input file '%s' . (CopyStripComments1File) \r", sFilePath
	endif
	printf "\t\tCopyStripComments1File() \t%s\t ->\t%s\t (Lines: %d)  \r", pd(sFilePath,33) ,  pd(sTgtPath, 33), nLine
	return	0
End

Function	/S	FirstWord( sLine )
	string  	sLine
	string  	sWord
	sscanf sLine, "%s" , sWord
	// printf "\t\t\tFirstWord()  \t%s\r", sWord
	return	sWord
End	

Function	/S	SecondWord( sLine )
	string  	sLine
	string  	sWord1, sWord2
	sscanf sLine, "%s %s" , sWord1, sWord2
	// printf "\t\t\tSecondWord(() \t'%s' , '%s'  %d  %d \r", sWord1, sWord2, cmpstr( sWord1, "STATIC" ),   cmpstr( sWord2 , "PICTURE" )
	return	sWord2
End	

static Function /S RemoveLineEnd( sLine, sComment, nStartPos )
// Deletes everything (including sComment) till end of line  but do  NOT  remove  characters after  '//'  if we are within a  string   Keeps the CR .
	variable	nStartPos
	string 	sLine, sComment
	string  	sDblQuote	= "\""

	variable	nCommentPos	= strsearch( sLine, sComment, nStartPos )
	variable	nDblQuotePos	= strsearch( sLine, sDblQuote, nStartPos )
	variable	nClosingQuotePos
	// printf "\tRemoveLineEnd() \tStartPos:%2d \tComPos:%2d \tDblQPos:%d \r", nStartPos, nCommentPos, nDblQuotePos

	if ( nCommentPos != kNOTFOUND )									// line  with comment ...
		if ( nDblQuotePos == kNOTFOUND )								// 	... but  without quotes :  simple case
			sLine = sLine[ 0, nCommentPos - 1 ]  + "\r"						//		...clear  '//'  and behind
			return 	sLine
		else														// 	... and  with quotes : it matters which is first
			if ( nCommentPos < nDblQuotePos )							//		...comment is first
				sLine = sLine[ 0, nCommentPos - 1 ]  + "\r"					//			...clear  '//'  and behind
				return 	sLine
			else													// 		...quotes are first
				nClosingQuotePos = strsearch( sLine, sDblQuote, nDblQuotePos+1 )	//			...skip until string is finished
				sLine	= RemoveLineEnd( sLine, sComment, nClosingQuotePos+1 )	// RECURSION
			endif
		endif
	endif

	return sLine
End

static Function /S RemoveWhiteSpace( sLine )
//? should replace 0x09-0x0d and 0x20  ( to be same as C compiler isspace() )
	string 	sLine
	sLine = ReplaceString( " ", sLine,  "" )
//	sLine = ReplaceString( "\r", sLine, "" )
//	sLine = ReplaceString( "\n", sLine, "" )
	sLine = ReplaceString( "\t", sLine, "" )
	return sLine
End


static strconstant	ksDPMARKER1 = "\t "
static strconstant	ksDPMARKER2 = "printf \"\\t\\t"

static Function /S RemoveDebugPrintLine( sLine )
// a Debug print line is a line starting with  at least 1 Tab, then any number of tabs (and possibly spaces) up to  'Tab Blank printf" Blank Tab...'  (=sDPMarker)
// the criterion after which is decided whether a line should be removed or not  is the  SPACE right before  the PRINTF"
	string  	sLine
	string  	sSaveLine		= sLine
	string		sDPMarker	= ksDPMARKER1 + ksDPMARKER2
	variable	len2			= strlen( ksDPMARKER2 )
	variable	nBeg
	if ( cmpstr( sLine[ 0, 0 ] , "\t" ) == 0 )						// Line starts wit a tab
		nBeg = strsearch( sLine, sDPMarker, 0 )				// finds the Debug print marker anywhere in the line (possibly after valid code, not only at the beginning in which we are interested)
		if ( nBeg != kNOTFOUND )
			sLine	= RemoveLeadingWhiteSpace( sLine )
			if ( cmpstr( sLine[ 0, len2 - 1 ], ksDPMARKER2 ) == 0 )	// finds the Debug print marker only when it is at the beginning 
				sLine		= RemoveEnding( sLine, "\r" )
				printf"\t\t\tRemoving '%s...'\r", sLine[0, 200]		
				return	""							// it was a Debug print line: remove it 
			endif
		endif
	endif
	return	sSaveLine									// it was a normal line : keep it
End

