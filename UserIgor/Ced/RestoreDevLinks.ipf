//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//   RestoreDevLinks.ipf	04Dez01
//
// After an USER installation (with InnoSetup) the links point to \UserIgor\FPulse\ipf,ihf,xop  and any changes from then on are made in these files. 
// To avoid confusion (and to avoid inadvertently overwriting existing files) these links are reset to the development state, e.g. \UserIgor\Ced

// In the user version  the links point to the release directory   UserIgor:FPulse:xxx   instead of the develop directory  UserIgor:Ced:xxx...
// ...so that all further editing effects the release files which is dangerous as the next  Release  overwrites the changes.
// For this reason it is strongly recommended to execute  'FPulseRestoreDevelopLinks()'  before further editing  (must also be typed into the command line) .

// Code taken from  'FPRelease.ipf'  .  This must be a separate file as  FPRelease.ipf  cannot be called stand-alone.

#pragma rtGlobals=1						// Use modern global access method.
#pragma IgorVersion=5.02					// GetFileFolderInfo

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

static strconstant	ksVERSION			= "259T"						// is defined in FPulse.ipf
static strconstant	ksDIRSEP				= ":"
static strconstant	ksSCRIPTS_DRIVE		= "C:"						// is defined in FPConstants.ipf
static strconstant	ksAPP_NAME			= "FPulse"						// is defined in FPConstants.ipf
static strconstant	ksMYPRG_DIR			= "UserIgor:Ced"				// where my sources are , 	must be the  SAME  in  FPRelease.ipf  in  FPulseCed.c

static strconstant	ksFPULSE_EXE_DIR	= "UserIgor:FPulseSetupExe"		// where InnoSetup puts  'FPulse xxx Setup.exe'  on my hard disk
static strconstant	ksRELEASE_SRC_DIR	= "UserIgor:FPulseTmp"			// temporary directory where InnoSetup  looks for it's source files on my hard disk, will be automatically deleted after finishing  'FPulseRelease()' 
static strconstant	ksINSTALLATION_DIR	= "UserIgor:FPulse"				// where InnoSetup will  unpack and install   FPulse on the user's hard disk

static strconstant	ksUSER_FILES_LIST	= "FP*.ipf;*.ihf;*.xop;*.rtf;FE*.ipf"		// List of file groups to be distributed to the user
static strconstant	ksPROC_FILES_LIST	= "FP*.ipf;FE*.ipf"				// (is LIST can have more items.) List of links to be copied into 'User Procedures' . The link from 'FPulse.ipf' is included but not needed here, it must go into  'Igor Procedures' .
static strconstant	ksHELP_FILES_LIST		= "FP*.ihf"						// is LIST, can have more items e.g. FP*.ihf;Ced*.ihf"

static strconstant	ksDEMOSCRIPTS_LIST	= "Demo*.txt;AP*.*;Sine*.ibw"		// 

static strconstant	ksPRG_START_LNK		= ":Igor Procedures"
static strconstant	ksUSERPROC_LNK		= ":User Procedures"
static strconstant	ksHELP_LNK			= ":Igor Help Files"

static strconstant	ksPRGXOP_LIST		= "FP*.xop"
static strconstant	ksXOP_LNK			= ":Igor Extensions"

static strconstant	ksDEMO_DIR			= ":DemoScripts"				// do not change to ensure compatibility
static strconstant	ksDLL_DIR			= ":Dll"						// do not change to ensure compatibility

static strconstant	ksDLL_FILES_LIST		= "Use1432.dll;1432ui.dll;Cfs32.dll;AxMultiClampMsg.dll;"	// do not use *.dll as attributes are set for all these files in  Windows\System32

static strconstant	ksCSOURCE_DIR_LIST	= "C_FPulseCed;C_FPMc700Tg;C_FPMc700;C_Common"	// same order in  ksCSOURCE_DIR_LIST and  ksXOP_LIST, but here more files 
static strconstant	ksXOP_LIST			= "FPulseCed;FP_Mc700Tg;FP_Mc700"					// same order in  ksCSOURCE_DIR_LIST and  ksXOP_LIST, but here less files
static strconstant	ksCSOURCE_FILES		= "*.c;*.h;*.hpp;*.rc;*.dsp;*.dsw;*.bmp"


static constant		FALSE		= 0
static constant		TRUE		= 1 
static constant		NOTFOUND	= -1 

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function		FPulseRestoreDevLinks()
// After an installation the links point to \UserIgor\FPulse\ipf,ihf,xop  and any changes from then on are made in these files. 
// To avoid confusion (and to avoid inadvertently overwriting existing files) these links are reset to the development state, e.g. \UserIgor\Ced
// NOTE: In a user installation this file must be opened as  'FPRelease()'  is an empty wrapper. 
// NOTE: Also the Debug version of   'FPulseCed.XOP'  must be loaded  rather than the  release version. ( Just recompile manually F7)
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

static Function		CreateLinks( sSrcDir, sMatch, sTgtDir )
// e.g. 		CreateLinks(  "D:UserIgor:Ced"  ,  "FP*.ipf" , "D:....:Igor Pro Folder:User Procedures"  ) . Wildcard *   is only allowed in filebase,   * is NOT allowed in the file extension.
	string  	sSrcDir, sMatch, sTgtDir
	string  	lstMatched	= ListOfMatchingFiles( sSrcDir, sMatch, FALSE )
	variable	n, nCnt		= ItemsInList( lstMatched )
	//printf "\tCreateLinks(  Matched \t%s,\t%s   \t->\t%s  ) \t: %2d\tfiles  %s \r",  sSrcDir, sMatch, sTgtDir, nCnt, lstMatched[0, 300]
	for ( n = 0; n < nCnt; n += 1 )
		string  	sSrc	= sSrcDir + ":" + StringFromList( n, lstMatched )
		string  	sTgt	= sTgtDir + ":" + StringFromList( n, lstMatched ) + ".lnk"
		CreateAlias( sSrc, sTgt )
	endfor  
End

// 040831 no longer static, should be in misc ...
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
	if ( V_Flag == 0 )										// make sure the folder exists
		lstFilesInDir = IndexedFile( SymbDir, -1, "????" )
		//printf "\tListFiles  All   \t( '%s' \t'%s'  \tuip:%d ) ->\t%s \r",  sSrcDir, sMatch,  lstFilesInDir[0, 300]
		lstMatched = ListMatch( lstFilesInDir, sMatch )
		//printf "\tListFiles Matched\t( '%s' \t'%s'   \tuip:%d ) ->\t%s \r",  sSrcDir, sMatch,  lstMatched[0, 300]
		KillPath 	/Z	SymbDir
	endif
	return	lstMatched
End


//------ File handling for 1 file --------------------------------------------------------------------------------------------------------------------------------------

static Function		CreateAlias( sFromPathFile, sToLinkFile )
	string  	sFromPathFile, sToLinkFile
	CreateAliasShortcut /O  /P=Igor		sFromPathFile		as	sToLinkFile
	if ( V_flag )
		printf "++++Error: Could not create link \t'%s' \tfrom\t'%s'  \r", sToLinkFile, sFromPathFile
	else
		//printf "\t\t\t\tCreated link \t%s\tfrom\t  '%s' \r", pd( sToLinkFile,36), sFromPathFile
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
	//print Secs2Time( V_modificationDate, 3 )
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

//========================================================================================================================

static strconstant	ksMATCH	= "CommentTes*.ipp"


Function		Read()
	string  	sSrcDir	=  ksSCRIPTS_DRIVE + ksMYPRG_DIR 
	string  	sTgtDir	=  ksSCRIPTS_DRIVE + ksRELEASE_SRC_DIR 
	CopyStripComments( sSrcDir, ksPROC_FILES_LIST, sTgtDir, ksMATCH )
End

static  Function		CopyStripComments( sSrcDir, lstFiles, sTgtDir, sMatch )
// Read  'lstFiles' , strips comments and writes...
	string  	sSrcDir, lstFiles, sTgtDir, sMatch
	string  	lstMatched	= ListOfMatchingFiles( sSrcDir, sMatch, FALSE )
	variable	n, nCnt		= ItemsInList( lstMatched )
	//printf "\tCopyStripComments(  Matched \t%s,\t%s   \t->\t%s  ) \t: %2d\tfiles  %s \r",  sSrcDir, sMatch, sTgtDir, nCnt, lstMatched[0, 300]
	for ( n = 0; n < nCnt; n += 1 )
		string  	sSrc	= sSrcDir + ":" + StringFromList( n, lstMatched )
		string  	sTgt	= sTgtDir + ":" + StringFromList( n, lstMatched )
		//printf "\tCopyStripComments( '%s' ) \tSrc: %s  \tTgt: %s   \r", lstFiles, pd(sSrc,28),  pd( sTgt, 28)
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


				//printf "\tCopyStripComments1File() \tInPic:%d \t%s ",  bIsInPicture, sLine
				if ( ! bIsInPicture )
					sLine = RemoveLineEnd( sLine,  "//", 0 )	// remove all comments  starting with ' // ' 
				endif
				
				// Remove all empty lines
				string  	sCompactedLine	= RemoveWhiteSpace( sLine )
				if ( strlen( sCompactedLine ) == 1 )
					continue
				endif


				fprintf  nRefNumTgt, "%s\n" , sLine			// \n appends 0A . In can be omitted but is included here as the ipf source file also contains it.
				//printf "\tCopyStripComments1File() \t\t%s ", sLine

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
	//printf "\t\t\tFirstWord()  \t%s\r", sWord
	return	sWord
End	

Function	/S	SecondWord( sLine )
	string  	sLine
	string  	sWord1, sWord2
	sscanf sLine, "%s %s" , sWord1, sWord2
	//printf "\t\t\tSecondWord(() \t'%s' , '%s'  %d  %d \r", sWord1, sWord2, cmpstr( sWord1, "STATIC" ),   cmpstr( sWord2 , "PICTURE" )
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
	//printf "\tRemoveLineEnd() \tStartPos:%2d \tComPos:%2d \tDblQPos:%d \r", nStartPos, nCommentPos, nDblQuotePos

	if ( nCommentPos != NOTFOUND )									// line  with comment ...
		if ( nDblQuotePos == NOTFOUND )								// 	... but  without quotes :  simple case
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



