//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//   UFCom_ReleaseComments.ipf	061017
//

#pragma rtGlobals=1						// Use modern global access method.
#pragma IgorVersion=5.02					// GetFileFolderInfo

//#pragma IndependentModule=UFCom_
#include "UFCom_Constants"
#include "UFCom_LineProcessing"
#include "UFCom_DirsAndFiles"		



//===============================================================================================================================================
//  GENERIC  PROCEDURES 

Function		UFCom_OfferForEdit( sDrivePrgDir, sProcFileName )	
	// display a procedure window and bring it to the front
	string  	sDrivePrgDir, sProcFileName
	string  	sPath	= sDrivePrgDir + ":" + sProcFileName
	Execute /P "OpenProc    \"" + sPath + "\""							// display a procedure window...
	MoveWindow  /P=$sProcFileName	 1,1,1,1							// ...and bring it to the front
End


//------ File handling for a list of groups of files  --------------------------------------------------------------------------------------------------------------------------------------

Function		UFCom_CopyFilesFromList( sSrcDir, lstFileGroups, sTargetDir )
// old version , Install.ipf ( was FPulse_Install.pxp)  has  a newer, more versatile one
	string  	sSrcDir, lstFileGroups, sTargetDir 
	variable	n, nCnt	= ItemsInList( lstFileGroups )
	string  	sFileGroup	
	for ( n = 0; n < nCnt; n += 1 )
	  	sFileGroup		= StringFromList( n, lstFileGroups )
		CopyFiles( sSrcDir, sFileGroup, sTargetDir ) 						// Copy the current User files (e.g. ipf, xop..) into it
	endfor
End

Function		UFCom_ModifyFileTimeFromList( sDir, lstFileGroups, Version, bUseIgorPath )
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
	
Function		UFCom_ModifyLinkTimeFromList( sDir, lstFileGroups, Version, bUseIgorPath )
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
	
Function		UFCom_CreateLinksFromList( sSrcDir, lstFileGroups, sTgtDir )
// old version , FPulse_Install.pxp has  a newer one
	string  	sSrcDir, lstFileGroups, sTgtDir
	variable	n, nCnt	= ItemsInList( lstFileGroups )
	string  	sFileGroup	
	for ( n = 0; n < nCnt; n += 1 )
	  	sFileGroup		= StringFromList( n, lstFileGroups )// + ".lnk"			// links have the extension '.lnk'  appended to the original extension (=2 dots!)
		UFCom_CreateLinks( sSrcDir, sFileGroup, sTgtDir ) 					
	endfor
End

Function		UFCom_DeleteLinksFromList( sSrcDir, lstFileGroups, sExt )
	string  	sSrcDir, lstFileGroups, sExt
	variable	n, nCnt	= ItemsInList( lstFileGroups )
	string  	sFileGroup	
	for ( n = 0; n < nCnt; n += 1 )
	  	sFileGroup		= StringFromList( n, lstFileGroups ) + sExt
		UFCom_DeleteLinks( sSrcDir, sFileGroup ) 
	endfor
End

Function		UFCom_DeleteFilesFromList( sSrcDir, lstFileGroups )
// old version , Install.ipf ( was FPulse_Install.pxp)  has  a newer, more versatile one ???
	string  	sSrcDir, lstFileGroups
	variable	n, nCnt	= ItemsInList( lstFileGroups )
	printf "\t\t\tUFCom_DeleteFilesFromList( \t\t\tSrcD:\t%s\tDeletes %d filegroups:\t'%s'  \r", UFCom_pd(sSrcDir,32),  nCnt, lstFileGroups
	string  	sFileGroup	
	for ( n = 0; n < nCnt; n += 1 )
	  	sFileGroup		= StringFromList( n, lstFileGroups )
		// printf "\t\t\tDeleteFilesFromList( \tn: %d/%d\tsrcDir:\t%s\tDeletes filegroup:\t'%s'  \r", n, nCnt, UFCom_pd(sSrcDir,32),  sFileGroup
		UFCom_DeleteFiles( sSrcDir, sFileGroup ) 
	endfor
End


//------ File handling for 1 group of files --------------------------------------------------------------------------------------------------------------------------------------

static Function		CopyFiles( sSrcDir, sMatch, sTgtDir )
// old version , Install.ipf ( was FPulse_Install.pxp)  has  a newer, more versatile one
// e.g. 		CopyFiles(  "D:UserIgor:FPulse"  ,  "FP*.ipf" , "C:UserIgor:FPulseV235"  ) .  Wildcards  *  are allowed .
	string  	sSrcDir, sMatch, sTgtDir
	string  	lstMatched	= UFCom_ListOfMatchingFiles( sSrcDir, sMatch, UFCom_FALSE )
	variable	n, nCnt		= ItemsInList( lstMatched )
	for ( n = 0; n < nCnt; n += 1 )
		string  	sSrc	= sSrcDir + ":" + StringFromList( n, lstMatched )
		string  	sTgt	= sTgtDir + ":" + StringFromList( n, lstMatched )
		UFCom_Copy1File( sSrc, sTgt )
	endfor
End


 Function		UFCom_CreateLinks( sSrcDir, sMatch, sTgtDir )
// e.g. 		CreateLinks(  "D:UserIgor:FPulse"  ,  "FP*.ipf" , "D:....:Igor Pro Folder:User Procedures"  ) . Wildcard *   is only allowed in filebase,   * is NOT allowed in the file extension.
	string  	sSrcDir, sMatch, sTgtDir
	string  	lstMatched	= UFCom_ListOfMatchingFiles( sSrcDir, sMatch, UFCom_FALSE )
	variable	n, nCnt		= ItemsInList( lstMatched )
	// printf "\tCreateLinks(  Matched \t%s,\t%s   \t->\t%s  ) \t: %2d\tfiles  %s \r",  sSrcDir, sMatch, sTgtDir, nCnt, lstMatched[0, 300]
	for ( n = 0; n < nCnt; n += 1 )
		string  	sSrc	= sSrcDir + ":" + StringFromList( n, lstMatched )
		string  	sTgt	= sTgtDir + ":" + StringFromList( n, lstMatched ) + ".lnk"
		UFCom_CreateAlias( sSrc, sTgt )
	endfor  
End

static Function		ModifyFileTimes( sDir, sMatch, Version, bUseIgorPath )
// e.g. 		ModifyFileTimes(  "D:UserIgor:FPulse"  ,  "FP*.ipf"  ) . . Wildcard *   is only allowed in filebase,   * is NOT allowed in the file extension.
	string  	sDir, sMatch
	variable	Version, bUseIgorPath
	
	string  	lstMatched	= UFCom_ListOfMatchingFiles( sDir, sMatch, bUseIgorPath )
	variable	n, nCnt		= ItemsInList( lstMatched )
	 printf "\t\t\tModifyFileTimes( Matched\t%s,\t%s   \t%g\t ) \t: %2d\tfiles  %s \r",  UFCom_pd(sDir,20), UFCom_pd(sMatch,10),  Version, nCnt, lstMatched[0, 300]
	for ( n = 0; n < nCnt; n += 1 )
		string  	sPath	= sDir + ":" + StringFromList( n, lstMatched )
		UFCom_ModifyFileTime( sPath, Version, bUseIgorPath )
	endfor
End

Function		UFCom_DeleteLinks( sSrcDir, sMatch )
//static Function		DeleteLinks( sSrcDir, sMatch )
// e.g. 		DeleteLinks(  "Igor help Files:"  ,  "FP*.ihf"  ) . Wildcards  *  are allowed .
	string  	sSrcDir, sMatch
	string  	lstMatched	= UFCom_ListOfMatchingFiles( sSrcDir, sMatch, 0 )
	variable	n, nCnt		= ItemsInList( lstMatched )
	// printf "\tDeleteLinks( Matched\t%s,\t%s   \t ) \t: %2d\tfiles  %s \r",  sSrcDir, sMatch, nCnt, lstMatched[0, 300]
	for ( n = 0; n < nCnt; n += 1 )
		string  	sSrc	= sSrcDir + ":" + StringFromList( n, lstMatched )
		DeleteFile		/P=IGOR   /Z=1	  	sSrc						// Set base path automatically to  ....:WaveMetrics.Igor Pro Folder:
		if ( V_flag )
			printf "++++Error: Could not delete file \t'%s'  \r", sSrc
		else
			printf "\t\t\t\tDeleted link\t'%s'  \r", sSrc
		endif
	endfor
	return	V_flag 
End



Function		UFCom_DeleteFiles( sSrcDir, sMatch )
// e.g. 		DeleteFiles(  "D:UserIgor:FPulse"  ,  "FP*.ipf"  ) . Wildcards  *  are allowed .
	string  	sSrcDir, sMatch
	string  	lstMatched	= UFCom_ListOfMatchingFiles( sSrcDir, sMatch, UFCom_FALSE )
	variable	n, nCnt		= ItemsInList( lstMatched )
	// printf "\tDeleteFiles( Matched\t%s,\t%s   \t ) \t: %2d\tfiles  %s \r",  sSrcDir, sMatch, nCnt, lstMatched[0, 300]
	for ( n = 0; n < nCnt; n += 1 )
		string  	sSrc	= sSrcDir + ":" + StringFromList( n, lstMatched )
		DeleteFile		/Z=1	  	sSrc
		if ( V_flag )
			printf "++++Error: Could not delete file \t'%s'  \r", sSrc
		else
			// printf "\t\t\t\tDeleted  \t'%s'  \r", sSrc
		endif
	endfor
End


//static Function	/S	ListOfMatchingFiles( sSrcDir, sMatch, bUseIgorPath )
//------ File handling for 1 file --------------------------------------------------------------------------------------------------------------------------------------

Function		UFCom_Copy1File( sSrc, sTgt )		
	string  	sSrc, sTgt 		
	CopyFile	/O /Z=1	sSrc	as	sTgt		// Z=1 : do not abort on error !
	if ( V_flag )
		printf "++++Error: Could not copy file  '%s' \tto\t'%s'  \r", sSrc, sTgt
	else
		// printf "\t\t\tCopied  \t\t%s\tto  \t  '%s' \r", UFCom_pd(sSrc,35), sTgt
	endif
End	


Function		UFCom_CreateAlias( sFromPathFile, sToLinkFile )
	string  	sFromPathFile, sToLinkFile
	CreateAliasShortcut /O  /P=Igor		sFromPathFile		as	sToLinkFile
	if ( V_flag )
		printf "++++Error: Could not create link \t'%s' \tfrom\t'%s'  \r", sToLinkFile, sFromPathFile
	else
		 printf "\t\t\t\tCreated link \t%s\tfrom\t  '%s' \r", UFCom_pd( sToLinkFile,36), sFromPathFile
	endif
End


Function		UFCom_ModifyFileTime( sPath, nVersion, bUseIgorPath )
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
	// printf "\t\t\t\tModifyFileTi(\t%s\t, V%d,\tuip:%d )    -> %s  %s (time was %s) \r", UFCom_pd( sPath, 32) , nVersion, bUseIgorPath, Secs2Date( AdjustedDateTimeSeconds, -1 ), Secs2Time( AdjustedDateTimeSeconds, 3 ),  Secs2Time( V_modificationDate, 3 )
	
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


// 2007-0214
Function		UFCom_CopyStripComments_( sDir, sMatch ) 
// Read  'lstFiles' , strips comments and writes...
	string  	sDir, sMatch
	string  	sTmpDir	= sDir + ":UF_Tmp"
	UFCom_PossiblyCreatePath( sTmpDir )
	string  	lstMatched	= UFCom_ListOfMatchingFiles( sDir, sMatch, UFCom_FALSE )
	variable	n, nCnt		= ItemsInList( lstMatched )
	 printf "\tUFCom_CopyStripComments_(  Matched \t%s,\t%s  %2d\tfiles  %s \r",  sDir, sMatch, nCnt, lstMatched[0, 300]
	for ( n = 0; n < nCnt; n += 1 )
		string  	sSrc			= sDir	+ ":" + StringFromList( n, lstMatched )
		string  	sTgt			= sTmpDir	+ ":" + StringFromList( n, lstMatched )
		variable	nRemovedDbg	= CopyStripComments1File( sSrc, sTgt )
		// printf "\tUFCom_CopyStripComments_() \tSrc:\t%s\thas removed \t%4d\tdebug print lines   \r", UFCom_pd(sSrc,49), nRemovedDbg
		UFCom_Copy1File( sTgt, sSrc )			// copy back into the original file
		DeleteFile		/Z=1	  	sTgt
	endfor
	DeleteFolder /Z sTmpDir
End


static Function		CopyStripComments1File( sFilePath, sTgtPath )
// Reads  procedure  file  xxx.ipf.   Data must be delimited by CR, LF or both.  Removes comments starting with  // 
// Does  NOT remove  after // when in  Picture  or in  " string " 
// Returns number of removed 'debug print lines'
	string		sFilePath, sTgtPath								// can be empty ...
	variable	nRefNum, nRefNumTgt, nLine = 0
	string		sLine			= ""
	variable	bIsInPicture	= UFCom_FALSE
	variable	nRemovedDbg	= 0
	
	Open /Z=2 /R	nRefNum  	   as	sFilePath						// /Z = 2: opens dialog box  if file is missing,  /Z = 1: no dialog / does nothing if file is missing
	Open /Z=2 	nRefNumTgt as sTgtPath						//
	if ( nRefNum != 0 )										// file could be missing  or  user cancelled file open dialog
		if ( nRefNumTgt != 0 )								
			do 											// ..if  ReadPath was not an empty string
				FReadLine nRefNum, sLine
				if ( strlen( sLine ) == 0 )						// Only at file end the line length is 0 . Empty lines have line length 1 due to the CR
					break
				endif

				// Do  NOT  remove  characters after  '//'  if we are within a picture 
				if ( ! bIsInPicture )
					if ( ( cmpstr( FirstWord( sLine ), "PICTURE" ) == 0  )  ||  ( cmpstr( FirstWord( sLine ), "STATIC" ) == 0  &&  cmpstr( SecondWord( sLine ), "PICTURE" ) == 0   ) )				
						bIsInPicture = UFCom_TRUE
					endif
				endif
				if ( bIsInPicture )
					if ( ( cmpstr( FirstWord( sLine ), "END" ) == 0  ) )
						bIsInPicture	= UFCom_FALSE
					endif
				endif


				// printf "\tCopyStripComments1File() \tInPic:%d \t%s ",  bIsInPicture, sLine
				if ( ! bIsInPicture )
					sLine 		 =  RemoveLineEnd( sLine,  "//", 0 )	// remove all comments  starting with ' // ' 
					sLine 		 =  RemoveDebugPrintLine( sLine )	// a Debug print line is a line starting with  at least 1 Tab, then any number of tabs (and possibly spaces) up to  'Tab Blank printf" Blank Tab...' 
					nRemovedDbg	+= strlen( sLine ) == 0
				endif
				

				// 2007-1004		automatically comment  line   '#define dDEBUG'  AFTER all other comment lines have been removed  OR  remove it entirely
				string  	sDefineDebug
				sscanf sLine, "#define %s", sDefineDebug
				if ( V_Flag == 1 )
					printf "\t\tCopyStripComments1File() \tSrc:\t%s\t ->\t%s\tFound line   '#define dDEBUG'  [%s]\r", UFCom_pd(sFilePath,49) ,  UFCom_pd(sTgtPath,54), sDefineDebug
					// sLine    = "//" + sLine    	// Version1: Comment out sLine	: even the occasional user will easily recognise this one-and-only commented line and may be tempted to uncomment it giving access to the debug functions...
					sLine	    = ""			// Version2: there will be no immediate clue on how to access the debug functions
				endif



				// Remove all empty lines
				string  	sCompactedLine	= RemoveWhiteSpace( sLine )
				if ( strlen( sCompactedLine ) == 1 )
					continue
				endif


				fprintf  nRefNumTgt, "%s\n" , sLine			// \n appends 0A . In can be omitted but is included here as the ipf source file also contains it.
				// printf "\tCopyStripComments1File() \t\t%s ", sLine

				nLine += 1
			while ( UFCom_TRUE )     							//...is not yet end of file EOF
			Close nRefNumTgt							// Close the output file
		else
			printf "++++Error: Could not open output file '%s' . (CopyStripComments1File) \r", sTgtPath
		endif
		Close nRefNum									// Close the input file
	else
		printf "++++Error: Could not open input file '%s' . (CopyStripComments1File) \r", sFilePath
	endif
	 printf "\t\tCopyStripComments1File() \tSrc:\t%s\t ->\t%s\t (Lines:%5d) .\tHas removed\t%4d\tdebug print lines \r", UFCom_pd(sFilePath,49) ,  UFCom_pd(sTgtPath,54), nLine, nRemovedDbg
	return	nRemovedDbg
End

static Function	/S	FirstWord( sLine )
	string  	sLine
	string  	sWord
	sscanf sLine, "%s" , sWord
	// printf "\t\t\tFirstWord()  \t%s\r", sWord
	return	sWord
End	

static Function	/S	SecondWord( sLine )
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

	if ( nCommentPos != UFCom_kNOTFOUND )									// line  with comment ...
		if ( nDblQuotePos == UFCom_kNOTFOUND )								// 	... but  without quotes :  simple case
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


static strconstant	ksDEBUG_PRINT_MARKER1 = "\t "
static strconstant	ksDEBUG_PRINT_MARKER2 = "printf \"\\t\\t"

static Function /S	RemoveDebugPrintLine( sLine )
// a Debug print line is a line starting with  at least 1 Tab, then any number of tabs (and possibly spaces) up to  'Tab Blank printf" Blank Tab...'  (=sDPMarker)
// the criterion after which is decided whether a line should be removed or not  is the  SPACE right before  the PRINTF"
	string  	sLine
	string  	sSaveLine		= sLine
	string		sDPMarker	= ksDEBUG_PRINT_MARKER1 + ksDEBUG_PRINT_MARKER2
	variable	len2			= strlen( ksDEBUG_PRINT_MARKER2 )
	variable	nBeg
	if ( cmpstr( sLine[ 0, 0 ] , "\t" ) == 0 )								// Line starts wit a tab
		nBeg = strsearch( sLine, sDPMarker, 0 )						// finds the Debug print marker anywhere in the line (possibly after valid code, not only at the beginning in which we are interested)
		if ( nBeg != UFCom_kNOTFOUND )
			sLine	= UFCom_RemoveLeadingWhiteSpace( sLine )
			if ( cmpstr( sLine[ 0, len2 - 1 ], ksDEBUG_PRINT_MARKER2 ) == 0 )	// finds the Debug print marker only when it is at the beginning 
				sLine		= RemoveEnding( sLine, "\r" )
				// printf"\t\t\tRemoveDebugPrintLine()F: Remove '%s...'\r", sLine[0, 300]		
				return	""									// it was a Debug print line: remove it 
			endif
		endif
	endif
	return	sSaveLine											// it was a normal line : keep it
End


// 2007-0218 should be generic but not UFCom_   better in  ProjectsCommons.ipf !!!
// 2007-0822 REMOVED  seems not to be used anywhere
//Function		UFCom_CallInno_( sVers, sDrive, sPrgDir, sAppNm, sReleaseSrcDir, sSetupExeDir, sInstallationDir, sDaBDir )
//	string  	sVers, sDrive, sPrgDir, sAppNm, sReleaseSrcDir, sSetupExeDir, sInstallationDir, sDaBDir  
//	//  Cave: 1: Must be modified for Win 98 or other Windows versions  ('cmd.exe'  may change)
//	//  Cave: 2. The  keywords  'Vers, Birth, Src, Msk, ODir, DDir, CDir'  must be the same as in  'sAPPNAME.iss'  !
//	//  Cave: 3: Inno's  default installation path must be changed so that it does not contain spaces ('Inno Setup 4' -> 'InnoSetup4' , or even 'Inno4' to save some bytes)
//	//  Cave: 4: The workaround using an explicit call to  'cmd.exe  /K '  is needed so that the DOS window possibly containing error messages is not immediately closed.
//
////	string  	sCmd 	= "cmd.exe /K " + "D:\\Programme\\InnoSetup4\\iscc.exe" + " "// also works without 'cmd.exe /K'  but then closes DOS window immediately  so that errorr messages cannot be read	
//// innosetup5 mutters about fpulse.iss line 359 Instexec not known
//	string  	sCmd 	= "cmd.exe  /K  "  +  "D:\\Programme\\InnoSetup5\\iscc.exe" + " "	
//
//	string  	sMyPrgDir	= ReplaceString(  ":" , sPrgDir, "\\" )
//	string  	sIssScript 	= sDrive + "\\" + sMyPrgDir + "\\" + sAppNm + ".iss"		// the path to the InnoSetup script , e.g.  'C:\UserIgor\Ced\FPulse.iss' or 'C:\UserIgor\Ced\SecuCheck.iss'
//	
//	string  	sAppNam	= "\"/dAppNm=" 	+ sAppNm + "\""	
//	
//	string  	sVersion	= "\"/dVers=" 		+ sVers + "\""	
//
//// 	'FPulse.iss'  has Birth and DemoScripts,   'SecuCheck.iss'   has NOT   -> try to make them compatible.....
//	//string  	sBirthFile	= "\"/dBirth=" 		+ BuildTTFileNm( sVers ) 		+ "\""	
//	//string  	sBirthFile	= "\"/dBirth=" 		+ "SecuDummy" + sVers + ".tst"	+ "\""	
//	
//	string  	sTmpDir	= ReplaceString(  ":" , sReleaseSrcDir, "\\" )			// where InnoSetup gets the application specific  source files
//	string  	sSrc		= sDrive + "\\" + sTmpDir							// where InnoSetup gets the application specific  source files , e.g. 'C:\UserIgor\FPulseTmp' . CANNOT be the working dir 'C:\UserIgor\Ced' !
//	string  	sSource	= "\"/dSrc=" 		+ sSrc + "\""	
//	
//	string  	sMask	= "\"/dMsk=" 		+ sSrc + "\\*.*"	 + "\""
//	
//	string  	sOut		= sDrive  + "\\" + ReplaceString(  ":" , sSetupExeDir, "\\" )	//  where InnoSetup puts  'FPulse xxx Setup.exe' , e.g. 'C:\UserIgor\Ced\FPulseSetupExe'
//	string  	sOutputDir	= "\"/dODir=" 		+ sOut + "\""		
//	
//	string  	sDDir	= sDrive  + "\\" + ReplaceString(  ":" , sInstallationDir, "\\" )	//  where InnoSetup will  unpack the specific application files , e.g. 'C:\IgorProcs\FPulse'  or  'C:\IgorProcs\SecuCheck'
//	string  	sDefaultDir= "\"/dDDir=" 		+ sDDir + "\""		
//	
//	string  	sDBDir	= "\"/dDBDir=" 		+ sDaBDir + "\""				//  the SUBdirectory where InnoSetup will  read and unpack the public data base files , e.g. 'ECheckPublicDB' 
//	
////	string  	sStr 		= sCmd + " " + sIssScript + " " + sAppNam + " " + sVersion + " "	+ sSource + " " + sMask + " " + sOutputDir + " " + sDefaultDir + " " + sBirthFile 
//	string  	sStr 		= sCmd + " " + sIssScript + " " + sAppNam + " " + sVersion + " " 	+ sSource + " " + sMask + " " + sOutputDir + " " + sDefaultDir + " " + sDBDir 
//	printf "\t%s   \r", sStr
//	ExecuteScriptText  sStr
//End

 
//===========================================================================================================================================


// Test
Function		UFCom_RIM()
//	UFCom_ReplaceModuleNames( "UFCom_",  "UFSec_",  "c:UserIgor:Commons:test", "c:UserIgor:Commons:Sec", "UFCom_*.*" ) 
//	UFCom_ReplaceModuleNames( "UFCom_",  "UFSec_",  "c:UserIgor:ReleaseTmp:Commons", "c:UserIgor:Commons:Sec", "FP_D*.*" ) 
	UFCom_ReplaceModuleNames_( "UFCom_",  "UFSec_",  "c:UserIgor:Commons:test", 	 	    "UFCom_*.*" ) 
	UFCom_ReplaceModuleNames_( "UFCom_",  "UFSec_",  "c:UserIgor:ReleaseTmp:Commons", "FP_D*.*" ) 
End

Function		UFCom_RIM_Back()
//	UFCom_ReplaceModuleNames( "UFSec_",  "UFCom_",  "c:UserIgor:Commons:Sec", "c:UserIgor:Commons:test", "UFSecu_*.*" ) 
	UFCom_ReplaceModuleNames_( "UFSec_",  "UFCom_",  "c:UserIgor:Commons:Sec", "UFSecu_*.*" ) 
End
//---test


// 2007-0214  must first copy from sSrcDir into sTgtDir

Function		UFCom_ReplaceModuleNamesFromLst( sSrcTxt, sReplaceTxt, sSrcDir, sTgtDir, lstMatch ) 
// Loops through list  'lstMatch'  and extracts  'sMatch' .   Then for all  'sMatch' ...
// ...Copy all files which match  'sMatch' (e.g. '*.ipf')  from  'sSrcDir'  into  'sTgtDir'   after having  replaced  'sSrcTxt'  (e.g. 'UFCom_')  by  'sReplaceTxt'  (e.g. 'UFSec_'  or  'UFFPu_') .  This is for COMMON and specific files.
// If the file name starts with 'sSrcTxt'  (e.g. 'UFCom_')  then also rename the file by replacing 'sSrcTxt'  by  'sReplaceTxt'  (e.g. 'UFSec_'  or  'UFFPu_') .  This is for  COMMON  files.
	string  	sSrcTxt, sReplaceTxt, sSrcDir, sTgtDir, lstMatch
	// UFCom_PossiblyCreatePath( sTgtDir )
	variable	n, nItems	= ItemsInlist( lstMatch )
	for ( n = 0; n < nitems; n += 1 )
		string  sMatch	= StringFromList( n, lstMatch )
		UFCom_ReplaceModuleNames( sSrcTxt, sReplaceTxt, sSrcDir, sTgtDir, sMatch ) 
	endfor
End

// 2007-0214 obsolete but no need to  first copy from sSrcDir into sTgtDir
static Function		UFCom_ReplaceModuleNames( sSrcTxt, sReplaceTxt, sSrcDir, sTgtDir, sMatch ) 
// Copy all files which match  'sMatch' (e.g. '*.ipf')  from  'sSrcDir'  into  'sTgtDir'   after having  replaced  'sSrcTxt'  (e.g. 'UFCom_')  by  'sReplaceTxt'  (e.g. 'UFSec_'  or  'UFFPu_') .  This is for COMMON and specific files.
// If the file name starts with 'sSrcTxt'  (e.g. 'UFCom_')  then also rename the file by replacing 'sSrcTxt'  by  'sReplaceTxt'  (e.g. 'UFSec_'  or  'UFFPu_') .  This is for  COMMON  files.
	string  	sSrcTxt, sReplaceTxt, sSrcDir, sTgtDir, sMatch
	string  	lstMatched	= UFCom_ListOfMatchingFiles( sSrcDir, sMatch, 0 )
	variable	n, nCnt		= ItemsInList( lstMatched )
	if ( nCnt )
		UFCom_PossiblyCreatePath( sTgtDir )					// Design issue: do not create directory if there are no replacements to make  
		 printf "\t\tReplaceModuleNames(  \t\t\tReplace \t%s\tby\t%s\tMatched \t%s\t%s\t: %2d\tfiles '%s'...\r", UFCom_pd(sSrcTxt,14), UFCom_pd(sReplaceTxt,14), UFCom_pd(sSrcDir,24),  UFCom_pd(sMatch,9) , nCnt, lstMatched[0, 190]
	endif
	for ( n = 0; n < nCnt; n += 1 )
		string  	sFile	=  StringFromList( n, lstMatched )
		string  	sSrc	= sSrcDir + ":" + sFile
		string  	sTgt	= sTgtDir + ":" + ReplaceString( sSrcTxt, sFile, sReplaceTxt )	// toImprove: replace only at beginning of name
		// printf "\t\t\tReplaceIndependentModules(  \t%2d/%2d\tReplace \t%s\tby\t%s\tfiles  %s \r",  n, nCnt, pd(sSrc,37) , pd(sTgt,37), lstMatched[0, 250]
		UFCom_ReplaceStringInFile( sSrcTxt, sReplaceTxt, sSrc, sTgt ) 
	endfor  
End

// 2007-0214 better but must first copy from sSrcDir into sTgtDir
Function		UFCom_ReplaceModuleNames_( sSrcTxt, sReplaceTxt, sDir, sMatch ) 
// Replaces in all files in 'sDir' which match  'sMatch' (e.g. '*.ipf')   'sSrcTxt'  (e.g. 'UFCom_')  by  'sReplaceTxt'  (e.g. 'UFSec_'  or  'UFFPu_') .  This is for all files : for COMMON and specific files.
// If the file name starts with 'sSrcTxt'  (e.g. 'UFCom_')  then also the file is renamed by replacing 'sSrcTxt'  by  'sReplaceTxt'  (e.g. 'UFSec_'  or  'UFFPu_') .  This is only for  COMMON  files.
	string  	sSrcTxt, sReplaceTxt, sDir, sMatch
	string  	sTmpDir		= sDir + ":UF_Tmp"
	string  	lstMatched	= UFCom_ListOfMatchingFiles( sDir, sMatch, UFCom_FALSE )
	variable	n, nCnt		= ItemsInList( lstMatched )
	UFCom_PossiblyCreatePath( sTmpDir )
	 printf "\t\tReplaceModuleNames(  \t\t\tReplace \t%s\tby\t%s\tMatched \t%s\t%s\t: %2d\tfiles '%s'...\r", UFCom_pd(sSrcTxt,14), UFCom_pd(sReplaceTxt,14), UFCom_pd(sDir,24),  UFCom_pd(sMatch,9) , nCnt, lstMatched[0, 220]
	for ( n = 0; n < nCnt; n += 1 )
		string  	sFile			=  StringFromList( n, lstMatched )
		string  	sSrc			= sDir 	+ ":" + sFile
		string  	sRenamedFile	= ReplaceString( sSrcTxt, sFile, sReplaceTxt )	// toImprove: replace only at beginning of name
		string  	sTgt			= sTmpDir + ":" + sRenamedFile
		// printf "\t\t\tUFCom_ReplaceModuleNames(  \t%2d/%2d\tReplace \t%s\tby\t%s\tfiles  %s \r",  n, nCnt, UFCom_pd(sSrc,37) , UFCom_pd(sTgt,37), lstMatched[0, 300]
		UFCom_ReplaceStringInFile( sSrcTxt, sReplaceTxt, sSrc, sTgt ) 
		DeleteFile		/Z=1	  	sSrc							// we must delete the source file BEFORE copying   in case the name of src and tgt is the same (no file renaming, only replacing within file)
		UFCom_Copy1File( sTgt, sDir + ":" + sRenamedFile )			// !!! copy back the possibly renamed file into the original directory
		DeleteFile		/Z=1	  	sTgt							// could also let DleteFolder below do the job...
	endfor
	DeleteFolder /Z sTmpDir
End


// similar...............
Function		UFCom_ReplaceStringInFile( sSrcTxt, sReplaceTxt, sSrcPath, sTgtPath ) 
// Read  file  'sSrcPath' ,  replace  'sSrcTxt'  by  'sReplaceTxt'   and  store in file  'sTgtPath' .   'sSrcPath'  and  'sTgtPath'  may be the same.   
	string  	sSrcTxt, sReplaceTxt
	string		sSrcPath, sTgtPath								// can be empty ...
	variable	nRefNum, nRefNumTgt, nLine = 0
	string		sAllText = "", sLine			= ""
	variable	bIsInPicture	= UFCom_FALSE
	
	// Read source file
	Open /Z=2 /R	nRefNum  	   as	sSrcPath					// /Z = 2: opens dialog box  if file is missing,  /Z = 1: no dialog / does nothing if file is missing
	if ( nRefNum != 0 )									// file could be missing  or  user cancelled file open dialog
		do 											// ..if  ReadPath was not an empty string
			FReadLine nRefNum, sLine
			if ( strlen( sLine ) == 0 )						// Only at file end the line length is 0 . Empty lines have line length 1 due to the CR
				break
			endif

			// Do  NOT  replace characters if we are within a picture 
			if ( ! bIsInPicture )
				if ( ( cmpstr( FirstWord( sLine ), "PICTURE" ) == 0  )  ||  ( cmpstr( FirstWord( sLine ), "STATIC" ) == 0  &&  cmpstr( SecondWord( sLine ), "PICTURE" ) == 0   ) )				
					bIsInPicture = UFCom_TRUE
				endif
			endif
			if ( bIsInPicture )
				if ( ( cmpstr( FirstWord( sLine ), "END" ) == 0  ) )
					bIsInPicture	= UFCom_FALSE
				endif
			endif

			// printf "\tUFCom_ReplaceStringInFile() \tInPic:%d \t%s ",  bIsInPicture, sLine
			if ( ! bIsInPicture )
				sLine = ReplaceString( sSrcTxt, sLine,  sReplaceTxt )	
			endif		
			sAllText	+=	sLine + "\n" 			// \n appends 0A . In can be omitted but is included here as the ipf source file also contains it.
			// printf "\t\tUFCom_ReplaceStringInFile() \t\t%s ", sLine

			nLine += 1
		while ( UFCom_TRUE )     								//...is not yet end of file EOF
		Close nRefNum									// Close the input file
	else
		printf "++++Error: Could not open input file '%s' . (UFCom_ReplaceStringInFile) \r", sSrcPath
	endif
	
	// Write target file.  By separating  read and write we can directly overwrite the source file.  (As long as Igor allows it - for example we cannot overwrite a currently open IPF file) 
	Open /Z=2 	nRefNumTgt as sTgtPath						//
	if ( nRefNumTgt != 0 )								
		variable	n, nLines = ItemsInList( sAllText, "\n" )
		for ( n = 0; n < nLines; n += 1 )
			sLine		= StringFromList( n, sAllText, "\n" )
			fprintf  nRefNumTgt, "%s\n" , sLine			// \n appends 0A . In can be omitted but is included here as the ipf source file also contains it.
		endfor
		Close nRefNumTgt							// Close the output file
	else
		printf "++++Error: Could not open output file '%s' . (UFCom_ReplaceStringInFile) \r", sTgtPath
	endif
	//printf "\tUFCom_ReplaceStringInFile() \t%s\t ->\t%s\t (Lines: %d)  \r", UFCom_pd(sSrcPath,33) ,  UFCom_pd(sTgtPath, 33), nLine
	return	0
End


// similar...............

