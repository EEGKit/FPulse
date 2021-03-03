//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//   UFCom_Projects.ipf	061017

#pragma rtGlobals=1						// Use modern global access method.
//#pragma IgorVersion=5.02					// GetFileFolderInfo

//#pragma IndependentModule=UFCom_
#include "UFCom_Constants"
#include "UFCom_DirsAndFiles"
#include "UFCom_ReleaseComments"


Function		DisableIndependentModules_()
// Igor does not allows to overwrite a currently open IPF file) so we need a temporary target directory from which we manually have to copy back to the source after Igor has been quit

//	string  	sAppliance = "" 
//	Prompt 	sAppliance, 	"Existing Appliance:", popup, lstAppliances

	// Cave, cave, cave:   The semicolons are vital.  One more or less will ruin all the files! 

// Version1 : 	remove the pragma
//	string  	sText		= "#pragma IndependentModule;//pragma IndependentModule;" ;	Prompt 	sText, 		"Converting1: "
//	string  	sText1		= "UFCom_#;UFCom_;"  ;									Prompt 	sText1, 		"Converting2: "
// Version2 : 	remove error in the pragma
//	string  	sText		= "//pragma IndependentModule;//#pragma IndependentModule;" ;	Prompt 	sText, 		"Converting1: "
//	string  	sText1		= "kPANEL_;UFCom_kPANEL_;"  ;							Prompt 	sText1, 		"Converting2: "
// Version3 : 	rename constants
	string  	sText		= "UFCom_ksSEP_;UFCom_UFCom_ksSEP_;" ;								Prompt 	sText, 		"Converting1: "
	string  	sText1		= "UFCom_kY_MISSING_;UFCom_UFCom_kY_MISSING_;"  ;					Prompt 	sText1, 		"Converting2: "

	string  	sMatch		= "*.ipf"
	string  	sSubDirBak	= "Bak_IndepModules" 
	string  	lstSrcDirs		= "C:UserIgor:Commons;C:UserIgor:SecuTest;C:UserIgor:Ced;" ;		Prompt 	lstSrcDirs,		 "from directories: "
	string  	sSubDir		= "No_IndepModules" ;									Prompt 	sSubDir,		 "into subdirectory: "

	DoPrompt "Will disable...", sText , sText1,  lstSrcDirs , sSubDir
	variable	nFlag		= V_flag
	string  	lstTexts		= sText + sText1		// Cave, cave, cave:   The semicolons are vital.  One more or less will ruin all the files! 
	// Pass 1 :  Display files which will be processed.  The user may still cancel.
	PossiblyDisableIndepModules( sMatch, lstSrcDirs, sSubDir, sSubDirBak, lstTexts, OFF )

	if ( nFlag == 0 )				// user did not cancel
		// Pass 2 :  Now do the replacements
		PossiblyDisableIndepModules( sMatch, lstSrcDirs, sSubDir, sSubDirBak, lstTexts,  ON )
	endif
End

Function		PossiblyDisableIndepModules( sMatch, lstSrcDirs, sSubDir, sSubDirBak, lstTexts, bDoReplace )
	string  	sMatch, lstSrcDirs, sSubDir, sSubDirBak, lstTexts
	variable	bDoReplace
	// Loop through all directories
	variable	d, nDirs	= ItemsInList( lstSrcDirs )
	for ( d = 0; d < nDirs; d += 1 )
		string  	sDir	= StringFromList( d, lstSrcDirs )
		// Loop through all files
		string  	lstMatchedFiles	= UFCom_ListOfMatchingFiles( sDir, sMatch, FALSE )
		variable	n, nFiles		= ItemsInList( lstMatchedFiles )
		UFCom_PossiblyCreatePath( RemoveEnding( sDir, ":" ) +  ":" + sSubDir )
		UFCom_PossiblyCreatePath( RemoveEnding( sDir, ":" ) +  ":" + sSubDirBak )

		for ( n = 0; n < nFiles; n += 1 )
			string  	sSrcFile		= RemoveEnding( sDir, ":" ) +  ":" + StringFromList( n, lstMatchedFiles )
			string  	sTgtFile		= RemoveEnding( sDir, ":" ) +  ":" + RemoveEnding( sSubDir, 	":" ) +  ":" + StringFromList( n, lstMatchedFiles )
			string  	sTgtFileBak	= RemoveEnding( sDir, ":" ) +  ":" + RemoveEnding( sSubDirBak,	":" ) +  ":" + StringFromList( n, lstMatchedFiles )
			Copy1File( sSrcFile, sTgtFileBak )							
			 printf "\t\t\tDisableIndependentModules_( \t%s\tDir: %2d/%2d\t%s\tFile: %2d/%2d\t%s\t->\t%s\t%s\t->\t%s\t... \r",  sMatch, d, nDirs, UFCom_pd( sDir,19),  n, nFiles, UFCom_pd( sSrcFile,32),  UFCom_pd( sTgtFile, 32) , StringFromList(0,lstTexts), StringFromList(1,lstTexts)
			if ( bDoReplace )
				UFCom_ReplaceStringsInFile( lstTexts, sSrcFile, sTgtFile ) 	
			endif
		endfor	

//		for ( n = 0; n < nFiles; n += 1 )
//			string  	sSrcFile		= RemoveEnding( sDir, ":" ) +  ":" + StringFromList( n, lstMatchedFiles )
//			string  	sTgtFile		= RemoveEnding( sDir, ":" ) +  ":" + RemoveEnding( sSubDir, ":" ) +  ":" + StringFromList( n, lstMatchedFiles )
//			 printf "\t\t\tDisableIndependentModules_( \t%s\tDir: %2d/%2d\t%s\tFile: %2d/%2d\t%s\t->\t%s\t%s\t->\t%s\t... \r",  sMatch, d, nDirs, UFCom_pd( sDir,19),  n, nFiles, UFCom_pd( sSrcFile,32),  UFCom_pd( sTgtFile, 32) , StringFromList(0,lstTexts), StringFromList(1,lstTexts)
//			if ( bDoReplace )
//				UFCom_ReplaceStringsInFile( lstTexts, sSrcFile, sTgtFile ) 
//			endif
//		endfor	


	endfor	

End


static Function		Copy1File( sSrc, sTgt )		
	string  	sSrc, sTgt 		
	CopyFile	/O	sSrc	as	sTgt	
	if ( V_flag )
		printf "++++Error: Could not copy file  '%s' \tto\t'%s'  \r", sSrc, sTgt
	else
		printf "\t\t\tCopied  \t\t%s\tto  \t  '%s' \r", UFCom_pd(sSrc,35), sTgt
	endif
End	


//static Function	/S	ListOfMatchingFiles( sSrcDir, sMatch, bUseIgorPath )
//// Allows file selection using wildcards. Returns list of matching files. Usage : ListFiles(  "C:foo2:foo1"  ,  "foo*.i*"  )
//	string  	sSrcDir, sMatch
//	variable	bUseIgorPath 
//	string  	lstFilesInDir, lstMatched = ""
////	string  	sBase, sExt
////	variable	nMatchParts	= ItemsInList( sMatch, "." )			// could be more than 1 dot  (e.g. if it is an alias) 
////	sExt		=  "." + StringFromList( nMatchParts-1, sMatch, "." )	// Hack out everything after   the LAST dot. The dot must exist.
////	sBase	= RemoveListItem( nMatchParts - 1 , sMatch, "." )	// Hack out everything before the LAST dot. The dot must exist. 
////	sBase	= RemoveEnding( sBase )						// truncate dot
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

//static Function		UFCom_ReplaceStringInFile( sSrcTxt, sReplaceTxt, sSrcPath, sTgtPath ) 
//// Read  file  'sSrcPath' ,  replace  'sSrcTxt'  by  'sReplaceTxt'   and  store in file  'sTgtPath' .   'sSrcPath'  and  'sTgtPath'  may be the same.   
//	string  	sSrcTxt, sReplaceTxt
//	string		sSrcPath, sTgtPath								// can be empty ...
//	variable	nRefNum, nRefNumTgt, nLine = 0
//	string		sLine			= ""
//	variable	bIsInPicture	= FALSE
//	
//	Open /Z=2 /R	nRefNum  	   as	sSrcPath						// /Z = 2: opens dialog box  if file is missing,  /Z = 1: no dialog / does nothing if file is missing
//	Open /Z=2 	nRefNumTgt as sTgtPath						//
//	if ( nRefNum != 0 )										// file could be missing  or  user cancelled file open dialog
//		if ( nRefNumTgt != 0 )								
//			do 											// ..if  ReadPath was not an empty string
//				FReadLine nRefNum, sLine
//				if ( strlen( sLine ) == 0 )						// Only at file end the line length is 0 . Empty lines have line length 1 due to the CR
//					break
//				endif
//
//				// Do  NOT  replace characters if we are within a picture 
//				if ( ! bIsInPicture )
//					if ( ( cmpstr( FirstWord( sLine ), "PICTURE" ) == 0  )  ||  ( cmpstr( FirstWord( sLine ), "STATIC" ) == 0  &&  cmpstr( SecondWord( sLine ), "PICTURE" ) == 0   ) )				
//						bIsInPicture = TRUE
//					endif
//				endif
//				if ( bIsInPicture )
//					if ( ( cmpstr( FirstWord( sLine ), "END" ) == 0  ) )
//						bIsInPicture	= FALSE
//					endif
//				endif
//
//				// printf "\tReplaceIndependentModule() \tInPic:%d \t%s ",  bIsInPicture, sLine
//				if ( ! bIsInPicture )
//					sLine = ReplaceString( sSrcTxt, sLine,  sReplaceTxt )	
//				endif
//				
//				fprintf  nRefNumTgt, "%s\n" , sLine			// \n appends 0A . In can be omitted but is included here as the ipf source file also contains it.
//				// printf "\t\tReplaceIndependentModules() \t\t%s ", sLine
//
//				nLine += 1
//			while ( TRUE )     							//...is not yet end of file EOF
//			Close nRefNumTgt							// Close the output file
//		else
//			printf "++++Error: Could not open output file '%s' . (UFCom_ReplaceStringInFile) \r", sTgtPath
//		endif
//		Close nRefNum									// Close the input file
//	else
//		printf "++++Error: Could not open input file '%s' . (UFCom_ReplaceStringInFile) \r", sSrcPath
//	endif
//	//printf "\tReplaceIndependentModules() \t%s\t ->\t%s\t (Lines: %d)  \r", UFCom_pd(sSrcPath,33) ,  UFCom_pd(sTgtPath, 33), nLine
//	return	0
//End




//===============================================================================================================================================
//  GENERIC  PROCEDURES 

//
//Function		UFCom_OfferForEdit_( sDrive, sPrgDir, sProcFileName )	
//	// display a procedure window and bring it to the front
//	string  	sDrive, sPrgDir, sProcFileName
//	string  	sPath	= sDrive + sPrgDir + ":" + sProcFileName
//	Execute /P "OpenProc    \"" + sPath + "\""								// display a procedure window...
//	MoveWindow  /P=$sProcFileName	 1,1,1,1							// ...and bring it to the front
//End
//
//
////------ File handling for a list of groups of files  --------------------------------------------------------------------------------------------------------------------------------------
//
//Function		UFCom_CopyFilesFromList( sSrcDir, lstFileGroups, sTargetDir )
//// old version , Install.ipf ( was FPulse_Install.pxp)  has  a newer, more versatile one
//	string  	sSrcDir, lstFileGroups, sTargetDir 
//	variable	n, nCnt	= ItemsInList( lstFileGroups )
//	string  	sFileGroup	
//	for ( n = 0; n < nCnt; n += 1 )
//	  	sFileGroup		= StringFromList( n, lstFileGroups )
//		CopyFiles( sSrcDir, sFileGroup, sTargetDir ) 						// Copy the current User files (e.g. ipf, xop..) into it
//	endfor
//End
//
//Function		UFCom_ModifyFileTimeFromList( sDir, lstFileGroups, Version, bUseIgorPath )
//// the hour:minute will be the version
//	string  	sDir, lstFileGroups
//	variable	Version, bUseIgorPath
//	variable	n, nCnt	= ItemsInList( lstFileGroups )
//	string  	sFileGroup	
//	for ( n = 0; n < nCnt; n += 1 )
//	  	sFileGroup		= StringFromList( n, lstFileGroups )
//		ModifyFileTimes( sDir, sFileGroup, Version, bUseIgorPath ) 						// the hour:minute will be the version
//	endfor
//End
//	
//static Function		ModifyLinkTimeFromList( sDir, lstFileGroups, Version, bUseIgorPath )
//// the hour:minute will be the version
//	string  	sDir, lstFileGroups
//	variable	Version, bUseIgorPath
//	variable	n, nCnt	= ItemsInList( lstFileGroups )
//	string  	sFileGroup	
//	for ( n = 0; n < nCnt; n += 1 )
//	  	sFileGroup		= StringFromList( n, lstFileGroups ) + ".lnk"
//		ModifyFileTimes( sDir, sFileGroup, Version, bUseIgorPath ) 						// the hour:minute will be the version
//	endfor
//End
//	
//static Function		CreateLinksFromList( sSrcDir, lstFileGroups, sTgtDir )
//// old version , FPulse_Install.pxp has  a newer one
//	string  	sSrcDir, lstFileGroups, sTgtDir
//	variable	n, nCnt	= ItemsInList( lstFileGroups )
//	string  	sFileGroup	
//	for ( n = 0; n < nCnt; n += 1 )
//	  	sFileGroup		= StringFromList( n, lstFileGroups )// + ".lnk"			// links have the extension '.lnk'  appended to the original extension (=2 dots!)
//		UFCom_CreateLinks( sSrcDir, sFileGroup, sTgtDir ) 					
//	endfor
//End
//
//
////------ File handling for 1 group of files --------------------------------------------------------------------------------------------------------------------------------------
//
//static Function		CopyFiles( sSrcDir, sMatch, sTgtDir )
//// old version , Install.ipf ( was FPulse_Install.pxp)  has  a newer, more versatile one
//// e.g. 		CopyFiles(  "D:UserIgor:Ced"  ,  "FP*.ipf" , "C:UserIgor:CedV235"  ) .  Wildcards  *  are allowed .
//	string  	sSrcDir, sMatch, sTgtDir
//	string  	lstMatched	= UFCom_ListOfMatchingFiles( sSrcDir, sMatch, FALSE )
//	variable	n, nCnt		= ItemsInList( lstMatched )
//	for ( n = 0; n < nCnt; n += 1 )
//		string  	sSrc	= sSrcDir + ":" + StringFromList( n, lstMatched )
//		string  	sTgt	= sTgtDir + ":" + StringFromList( n, lstMatched )
//		Copy1File( sSrc, sTgt )
//	endfor
//End
//
//
//static Function		ModifyFileTimes( sDir, sMatch, Version, bUseIgorPath )
//// e.g. 		ModifyFileTimes(  "D:UserIgor:Ced"  ,  "FP*.ipf"  ) . . Wildcard *   is only allowed in filebase,   * is NOT allowed in the file extension.
//	string  	sDir, sMatch
//	variable	Version, bUseIgorPath
//	
//	string  	lstMatched	= UFCom_ListOfMatchingFiles( sDir, sMatch, bUseIgorPath )
//	variable	n, nCnt		= ItemsInList( lstMatched )
//	 printf "\t\t\tModifyFileTimes( Matched\t%s,\t%s   \t%g\t ) \t: %2d\tfiles  %s \r",  sDir, sMatch, Version, nCnt, lstMatched[0, 300]
//	for ( n = 0; n < nCnt; n += 1 )
//		string  	sPath	= sDir + ":" + StringFromList( n, lstMatched )
//		UFCom_ModifyFileTime( sPath, Version, bUseIgorPath )
//	endfor
//End
//
//
//Function		UFCom_DeleteFiles( sSrcDir, sMatch )
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
//			printf "\t\t\t\tDeleted  \t'%s'  \r", sSrc
//		endif
//	endfor
//End
//
//
//Function		UFCom_CreateLinks( sSrcDir, sMatch, sTgtDir )
//// e.g. 		CreateLinks(  "D:UserIgor:Ced"  ,  "FP*.ipf" , "D:....:Igor Pro Folder:User Procedures"  ) . Wildcard *   is only allowed in filebase,   * is NOT allowed in the file extension.
//	string  	sSrcDir, sMatch, sTgtDir
//	string  	lstMatched	= UFCom_ListOfMatchingFiles( sSrcDir, sMatch, FALSE )
//	variable	n, nCnt		= ItemsInList( lstMatched )
//	// printf "\tCreateLinks(  Matched \t%s,\t%s   \t->\t%s  ) \t: %2d\tfiles  %s \r",  sSrcDir, sMatch, sTgtDir, nCnt, lstMatched[0, 300]
//	for ( n = 0; n < nCnt; n += 1 )
//		string  	sSrc	= sSrcDir + ":" + StringFromList( n, lstMatched )
//		string  	sTgt	= sTgtDir + ":" + StringFromList( n, lstMatched ) + ".lnk"
//		CreateAlias( sSrc, sTgt )
//	endfor  
//End
//
//// 040831 no longer static, should be in misc ...
////static Function	/S	ListOfMatchingFiles( sSrcDir, sMatch, bUseIgorPath )
////------ File handling for 1 file --------------------------------------------------------------------------------------------------------------------------------------
//
//static Function		Copy1File( sSrc, sTgt )		
//	string  	sSrc, sTgt 		
//	CopyFile	/O	sSrc	as	sTgt	
//	if ( V_flag )
//		printf "++++Error: Could not copy file  '%s' \tto\t'%s'  \r", sSrc, sTgt
//	else
//		printf "\t\t\tCopied  \t\t%s\tto  \t  '%s' \r", UFCom_pd(sSrc,35), sTgt
//	endif
//End	
//
//
//static Function		CreateAlias( sFromPathFile, sToLinkFile )
//	string  	sFromPathFile, sToLinkFile
//	CreateAliasShortcut /O  /P=Igor		sFromPathFile		as	sToLinkFile
//	if ( V_flag )
//		printf "++++Error: Could not create link \t'%s' \tfrom\t'%s'  \r", sToLinkFile, sFromPathFile
//	else
//		// printf "\t\t\t\tCreated link \t%s\tfrom\t  '%s' \r", UFCom_pd( sToLinkFile,36), sFromPathFile
//	endif
//End
//
//
//Function		UFCom_ModifyFileTime( sPath, nVersion, bUseIgorPath )
//// Modify the File Date/Time to reflect the program version. The version 1234 is converted to 12:34 .
//// This must be done with care to avoid inadvertently overwriting a truely newer file with an older version whose date/time has been set to newer.
//	string  	sPath
//	variable	nVersion, bUseIgorPath
//	variable	VersionSeconds			= trunc( nVersion / 100 )  * 3600 + mod( nVersion, 100 ) * 60
//	variable	AdjustedDateTimeSeconds
//
//	if ( bUseIgorPath )
//		GetFileFolderInfo /Q 	/P=IGOR 	/Z	sPath
//	else
//		GetFileFolderInfo /Q 			/Z	sPath
//	endif
//	//variable	Seconds			= V_modificationDate + 3600 
//	string  	sThisDayTime		= Secs2Time( V_modificationDate, 3 )
//	variable	OldSecondsThisDay	= 3600 * str2num( sThisDayTime[0,1] ) + 60 * str2num( sThisDayTime[3,4] ) +  str2num( sThisDayTime[6,7] )
//	AdjustedDateTimeSeconds	= V_modificationDate - OldSecondsThisDay + VersionSeconds
//	printf "\t\t\t\tModifyFileTi(\t%s\t, V%d,\tuip:%d )    -> %s  %s (time was %s) \r", UFCom_pd( sPath, 32) , nVersion, bUseIgorPath, Secs2Date( AdjustedDateTimeSeconds, -1 ), Secs2Time( AdjustedDateTimeSeconds, 3 ),  Secs2Time( V_modificationDate, 3 )
//	
//	if ( bUseIgorPath )
//		SetFileFolderInfo  	/P=IGOR 	/MDAT= (AdjustedDateTimeSeconds) sPath
//	else
//		SetFileFolderInfo  			/MDAT= (AdjustedDateTimeSeconds) sPath
//	endif
//	//GetFileFolderInfo sPath
//	// print Secs2Time( V_modificationDate, 3 )
//End
//
////Function		GetVersionFromFileTime( sPath )
////// Get the File Date/Time  reflecting  the program version. The time 12:34 is returneds as converted to 1234 .
////	string  	sPath
////	GetFileFolderInfo /Q /Z	sPath
////	variable	Seconds	= V_modificationDate + 3600 
////	string  	sThisDayTime	= Secs2Time( V_modificationDate, 3 )
////	variable	nVersion		= 100 * str2num( sThisDayTime[0,1] ) + str2num( sThisDayTime[3,4] ) 
////	printf "\t\tGetVersionFromFileTime( '%s' ) returns  V%d  \r", sPath, nVersion
////	return	nVersion
////End
//
////---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//
//static Function	/S	LastDrive( sDrive )
//// Returns the drive letter of the last R/W drive starting at sDrive (usually C:) . Any writable disk above C: is included e.g. a CD ROM burner. This is not intended but does not hurt.
//	string  	sDrive
//	do
//		GetFileFolderInfo  /Z	/Q	sDrive
//		if (  V_Flag  ||  ! V_isFolder  ||   V_isReadOnly )		// root directory NOT found
//			return	DecrementDrive( sDrive )
//		endif
//		// printf "\t\t\tLastDrive() \t\tFolder  '%s'  exists \r", sDrive
//		sDrive	= IncrementDrive( sDrive )
//	while ( 1 )
//	return	""
//End
//	
//static Function	/S	IncrementDrive( sDrive )	
//	string  	sDrive
//	return ( num2char( char2num( sDrive[ 0, 0 ] ) + 1 ) + sDrive[ 1, Inf ] )
//End
//
//static Function	/S	DecrementDrive( sDrive )	
//	string  	sDrive
//	return ( num2char( char2num( sDrive[ 0, 0 ] ) - 1 )  + sDrive[ 1, Inf ] )
//End
//
//
//// 041204	
//  Function		UFCom_CopyStripComments( sSrcDir, lstFiles, sTgtDir, sMatch ) 
//// Read  'lstFiles' , strips comments and writes...
//	string  	sSrcDir, lstFiles, sTgtDir, sMatch
//	string  	lstMatched	= UFCom_ListOfMatchingFiles( sSrcDir, sMatch, FALSE )
//	variable	n, nCnt		= ItemsInList( lstMatched )
//	 printf "\tCopyStripComments(  Matched \t%s,\t%s   \t->\t%s  ) \t: %2d\tfiles  %s \r",  sSrcDir, sMatch, sTgtDir, nCnt, lstMatched[0, 300]
//	for ( n = 0; n < nCnt; n += 1 )
//		string  	sSrc	= sSrcDir + ":" + StringFromList( n, lstMatched )
//		string  	sTgt	= sTgtDir + ":" + StringFromList( n, lstMatched )
//		// printf "\tCopyStripComments( '%s' ) \tSrc: %s  \tTgt: %s   \r", lstFiles, UFCom_pd(sSrc,28),  UFCom_pd( sTgt, 28)
//		CopyStripComments1File( sSrc, sTgt )
//
//	endfor
//End
//
//
//static Function		CopyStripComments1File( sFilePath, sTgtPath )
//// Reads  procedure  file  xxx.ipf.   Data must be delimited by CR, LF or both.  Removes comments starting with  // 
//// Does  NOT remove  after // when in  Picture  or in  " string " 
//	string		sFilePath, sTgtPath								// can be empty ...
//	variable	nRefNum, nRefNumTgt, nLine = 0
//	string		sLine			= ""
//	variable	bIsInPicture	= FALSE
//	
//	Open /Z=2 /R	nRefNum  	   as	sFilePath						// /Z = 2: opens dialog box  if file is missing,  /Z = 1: no dialog / does nothing if file is missing
//	Open /Z=2 	nRefNumTgt as sTgtPath						//
//	if ( nRefNum != 0 )										// file could be missing  or  user cancelled file open dialog
//		if ( nRefNumTgt != 0 )								
//			do 											// ..if  ReadPath was not an empty string
//				FReadLine nRefNum, sLine
//				if ( strlen( sLine ) == 0 )						// Only at file end the line length is 0 . Empty lines have line length 1 due to the CR
//					break
//				endif
//
//				// Do  NOT  remove  characters after  '//'  if we are within a picture 
//				if ( ! bIsInPicture )
//					if ( ( cmpstr( FirstWord( sLine ), "PICTURE" ) == 0  )  ||  ( cmpstr( FirstWord( sLine ), "STATIC" ) == 0  &&  cmpstr( SecondWord( sLine ), "PICTURE" ) == 0   ) )				
//						bIsInPicture = TRUE
//					endif
//				endif
//				if ( bIsInPicture )
//					if ( ( cmpstr( FirstWord( sLine ), "END" ) == 0  ) )
//						bIsInPicture	= FALSE
//					endif
//				endif
//
//
//				// printf "\tCopyStripComments1File() \tInPic:%d \t%s ",  bIsInPicture, sLine
//				if ( ! bIsInPicture )
//					sLine = RemoveLineEnd( sLine,  "//", 0 )	// remove all comments  starting with ' // ' 
//// 051006
//sLine = RemoveDebugPrintLine( sLine )	// a Debug print line is a line starting with  at least 1 Tab, then any number of tabs (and possibly spaces) up to  'Tab Blank printf" Blank Tab...' 
//				endif
//				
//				// Remove all empty lines
//				string  	sCompactedLine	= RemoveWhiteSpace( sLine )
//				if ( strlen( sCompactedLine ) == 1 )
//					continue
//				endif
//
//
//				fprintf  nRefNumTgt, "%s\n" , sLine			// \n appends 0A . In can be omitted but is included here as the ipf source file also contains it.
//				// printf "\tCopyStripComments1File() \t\t%s ", sLine
//
//				nLine += 1
//			while ( TRUE )     							//...is not yet end of file EOF
//			Close nRefNumTgt							// Close the output file
//		else
//			printf "++++Error: Could not open output file '%s' . (CopyStripComments1File) \r", sTgtPath
//		endif
//		Close nRefNum									// Close the input file
//	else
//		printf "++++Error: Could not open input file '%s' . (CopyStripComments1File) \r", sFilePath
//	endif
//	printf "\t\tCopyStripComments1File() \t%s\t ->\t%s\t (Lines: %d)  \r", UFCom_pd(sFilePath,33) ,  UFCom_pd(sTgtPath, 33), nLine
//	return	0
//End
//
//static Function	/S	FirstWord( sLine )
//	string  	sLine
//	string  	sWord
//	sscanf sLine, "%s" , sWord
//	// printf "\t\t\tFirstWord()  \t%s\r", sWord
//	return	sWord
//End	
//
//static Function	/S	SecondWord( sLine )
//	string  	sLine
//	string  	sWord1, sWord2
//	sscanf sLine, "%s %s" , sWord1, sWord2
//	// printf "\t\t\tSecondWord(() \t'%s' , '%s'  %d  %d \r", sWord1, sWord2, cmpstr( sWord1, "STATIC" ),   cmpstr( sWord2 , "PICTURE" )
//	return	sWord2
//End	
//
//static Function /S RemoveLineEnd( sLine, sComment, nStartPos )
//// Deletes everything (including sComment) till end of line  but do  NOT  remove  characters after  '//'  if we are within a  string   Keeps the CR .
//	variable	nStartPos
//	string 	sLine, sComment
//	string  	sDblQuote	= "\""
//
//	variable	nCommentPos	= strsearch( sLine, sComment, nStartPos )
//	variable	nDblQuotePos	= strsearch( sLine, sDblQuote, nStartPos )
//	variable	nClosingQuotePos
//	// printf "\tRemoveLineEnd() \tStartPos:%2d \tComPos:%2d \tDblQPos:%d \r", nStartPos, nCommentPos, nDblQuotePos
//
//	if ( nCommentPos != kNOTFOUND )									// line  with comment ...
//		if ( nDblQuotePos == kNOTFOUND )								// 	... but  without quotes :  simple case
//			sLine = sLine[ 0, nCommentPos - 1 ]  + "\r"						//		...clear  '//'  and behind
//			return 	sLine
//		else														// 	... and  with quotes : it matters which is first
//			if ( nCommentPos < nDblQuotePos )							//		...comment is first
//				sLine = sLine[ 0, nCommentPos - 1 ]  + "\r"					//			...clear  '//'  and behind
//				return 	sLine
//			else													// 		...quotes are first
//				nClosingQuotePos = strsearch( sLine, sDblQuote, nDblQuotePos+1 )	//			...skip until string is finished
//				sLine	= RemoveLineEnd( sLine, sComment, nClosingQuotePos+1 )	// RECURSION
//			endif
//		endif
//	endif
//
//	return sLine
//End
//
//static Function /S RemoveWhiteSpace( sLine )
////? should replace 0x09-0x0d and 0x20  ( to be same as C compiler isspace() )
//	string 	sLine
//	sLine = ReplaceString( " ", sLine,  "" )
////	sLine = ReplaceString( "\r", sLine, "" )
////	sLine = ReplaceString( "\n", sLine, "" )
//	sLine = ReplaceString( "\t", sLine, "" )
//	return sLine
//End
//
//
//static strconstant	ksDPMARKER1 = "\t "
//static strconstant	ksDPMARKER2 = "printf \"\\t\\t"
//
//static Function /S	RemoveDebugPrintLine( sLine )
//// a Debug print line is a line starting with  at least 1 Tab, then any number of tabs (and possibly spaces) up to  'Tab Blank printf" Blank Tab...'  (=sDPMarker)
//// the criterion after which is decided whether a line should be removed or not  is the  SPACE right before  the PRINTF"
//	string  	sLine
//	string  	sSaveLine		= sLine
//	string		sDPMarker	= ksDPMARKER1 + ksDPMARKER2
//	variable	len2			= strlen( ksDPMARKER2 )
//	variable	nBeg
//	if ( cmpstr( sLine[ 0, 0 ] , "\t" ) == 0 )						// Line starts wit a tab
//		nBeg = strsearch( sLine, sDPMarker, 0 )				// finds the Debug print marker anywhere in the line (possibly after valid code, not only at the beginning in which we are interested)
//		if ( nBeg != kNOTFOUND )
//			sLine	= UFCom_RemoveLeadingWhiteSpace( sLine )
//			if ( cmpstr( sLine[ 0, len2 - 1 ], ksDPMARKER2 ) == 0 )	// finds the Debug print marker only when it is at the beginning 
//				sLine		= RemoveEnding( sLine, "\r" )
//				printf"\t\t\tRemoving '%s...'\r", sLine[0, 200]		
//				return	""							// it was a Debug print line: remove it 
//			endif
//		endif
//	endif
//	return	sSaveLine									// it was a normal line : keep it
//End
//
//
////  Version 061017-19   user has  only 1 common dir   for all projects
////Function	CallInno_( sVers, sDrive, sPrgDir, sAppName, sReleaseSrcDir, sSetupExeDir, sInstallationDir, sScrDirCommons, sInstDirCommons, sDaBDir )
////	string  	sVers, sDrive, sPrgDir, sAppName, sReleaseSrcDir, sSetupExeDir, sInstallationDir, sScrDirCommons, sInstDirCommons, sDaBDir  
////	//  Cave: 1: Must be modified for Win 98 or other Windows versions  ('cmd.exe'  may change)
////	//  Cave: 2. The  keywords  'Vers, Birth, Src, Msk, ODir, DDir, CDir'  must be the same as in  'sAPPNAME.iss'  !
////	//  Cave: 3: Inno's  default installation path must be changed so that it does not contain spaces ('Inno Setup 4' -> 'InnoSetup4' , or even 'Inno4' to save some bytes)
////	//  Cave: 4: The workaround using an explicit call to  'cmd.exe  /K '  is needed so that the DOS window possibly containing error messages is not immediately closed.
////
////	// string  	sCmd 	= "D:\\Programme\\InnoSetup4\\iscc.exe"				// works but closes DOS window immediately  so that errorr messages cannot be read
////	string  	sCmd 	= "cmd.exe  /K  "  +  "D:\\Programme\\InnoSetup4\\iscc.exe" + " "	
////
////	string  	sMyPrgDir	= ReplaceString(  ":" , sPrgDir, "\\" )
//////	string  	sIssScript 	= sDrive + "\\" + sMyPrgDir + "\\FPulse.iss"			// the path to the InnoSetup script , e.g. 'C:\UserIgor\Ced\FPulse.iss'
////	string  	sIssScript 	= sDrive + "\\" + sMyPrgDir + "\\" + sAppName + ".iss"	// the path to the InnoSetup script , e.g. 'C:\UserIgor\Ced\SecuTest.iss'
////	
////	string  	sAppNm	= "\"/dAppNm=" 	+ sAppName + "\""	
////	
////	string  	sVersion	= "\"/dVers=" 		+ sVers + "\""	
////
////// 	'FPulse.iss'  has Birth and DemoScripts,   'SecuTest.iss'   has NOT   -> try to make them compatible.....
////	//string  	sBirthFile	= "\"/dBirth=" 		+ BuildTTFileNm( sVers ) 		+ "\""	
////	//string  	sBirthFile	= "\"/dBirth=" 		+ "SecuDummy" + sVers + ".tst"	+ "\""	
////	
////	string  	sTmpDir	= ReplaceString(  ":" , sReleaseSrcDir, "\\" )			// where InnoSetup gets the application specific  source files
////	string  	sSrc		= sDrive + "\\" + sTmpDir							// where InnoSetup gets the application specific  source files , e.g. 'C:\UserIgor\FPulseTmp' . CANNOT be the working dir 'C:\UserIgor\Ced' !
////	string  	sSource	= "\"/dSrc=" 		+ sSrc + "\""	
////	
////	string  	sMask	= "\"/dMsk=" 		+ sSrc + "\\*.*"	 + "\""
////	
////	string  	sOut		= sDrive  + "\\" + ReplaceString(  ":" , sSetupExeDir, "\\" )	//  where InnoSetup puts  'FPulse xxx Setup.exe' , e.g. 'C:\UserIgor\Ced\FPulseSetupExe'
////	string  	sOutputDir	= "\"/dODir=" 		+ sOut + "\""		
////	
////	string  	sDDir	= sDrive  + "\\" + ReplaceString(  ":" , sInstallationDir, "\\" )	//  where InnoSetup will  unpack the specific application files , e.g. 'C:\IgorProcs\FPulse'  or  'C:\IgorProcs\SecuTest'
////	string  	sDefaultDir= "\"/dDDir=" 		+ sDDir + "\""		
////	
////	string  	sSrcCoDir	= sDrive  + "\\" + ReplaceString(  ":" , sScrDirCommons, "\\" )// where InnoSetup gets the application specific  source files, e.g. 'C:\UserIgor\Commons' 
////	string  	sSrcCommonDir= "\"/dCSrc="	+ sSrcCoDir + "\""		
////	
////	string  	sCDir		= sDrive  + "\\" + ReplaceString(  ":" , sInstDirCommons, "\\" )//  where InnoSetup will  unpack the files common to all applications , e.g. 'C:\IgorProcs\Commons' 
////	string  	sCommonDir= "\"/dCDir=" 		+ sCDir + "\""		
////	
////	string  	sDBDir	= "\"/dDBDir=" 		+ sDaBDir + "\""				//  the SUBdirectory where InnoSetup will  read and unpack the public data base files , e.g. 'PublicDB' 
////	
//////	string  	sStr 		= sCmd + " " + sIssScript + " " + sAppNm + " " + sVersion + " "	+ sSource + " " + sMask + " " + sOutputDir + " " + sDefaultDir + " " + sBirthFile 
////	string  	sStr 		= sCmd + " " + sIssScript + " " + sAppNm + " " + sVersion + " " 	+ sSource + " " + sMask + " " + sOutputDir + " " + sDefaultDir + " " + sSrcCommonDir + " " + sCommonDir + " " + sDBDir 
////	printf "\t%s   \r", sStr
////	ExecuteScriptText  sStr
////End
//
//Function		UFCom_CallInno_( sVers, sDrive, sPrgDir, sAppName, sReleaseSrcDir, sSetupExeDir, sInstallationDir, sDaBDir )
//	string  	sVers, sDrive, sPrgDir, sAppName, sReleaseSrcDir, sSetupExeDir, sInstallationDir, sDaBDir  
//	//  Cave: 1: Must be modified for Win 98 or other Windows versions  ('cmd.exe'  may change)
//	//  Cave: 2. The  keywords  'Vers, Birth, Src, Msk, ODir, DDir, CDir'  must be the same as in  'sAPPNAME.iss'  !
//	//  Cave: 3: Inno's  default installation path must be changed so that it does not contain spaces ('Inno Setup 4' -> 'InnoSetup4' , or even 'Inno4' to save some bytes)
//	//  Cave: 4: The workaround using an explicit call to  'cmd.exe  /K '  is needed so that the DOS window possibly containing error messages is not immediately closed.
//
//	// string  	sCmd 	= "D:\\Programme\\InnoSetup4\\iscc.exe"				// works but closes DOS window immediately  so that errorr messages cannot be read
//	string  	sCmd 	= "cmd.exe  /K  "  +  "D:\\Programme\\InnoSetup4\\iscc.exe" + " "	
//
//	string  	sMyPrgDir	= ReplaceString(  ":" , sPrgDir, "\\" )
////	string  	sIssScript 	= sDrive + "\\" + sMyPrgDir + "\\FPulse.iss"			// the path to the InnoSetup script , e.g. 'C:\UserIgor\Ced\FPulse.iss'
//	string  	sIssScript 	= sDrive + "\\" + sMyPrgDir + "\\" + sAppName + ".iss"	// the path to the InnoSetup script , e.g. 'C:\UserIgor\Ced\SecuTest.iss'
//	
//	string  	sAppNm	= "\"/dAppNm=" 	+ sAppName + "\""	
//	
//	string  	sVersion	= "\"/dVers=" 		+ sVers + "\""	
//
//// 	'FPulse.iss'  has Birth and DemoScripts,   'SecuTest.iss'   has NOT   -> try to make them compatible.....
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
//	string  	sDDir	= sDrive  + "\\" + ReplaceString(  ":" , sInstallationDir, "\\" )	//  where InnoSetup will  unpack the specific application files , e.g. 'C:\IgorProcs\FPulse'  or  'C:\IgorProcs\SecuTest'
//	string  	sDefaultDir= "\"/dDDir=" 		+ sDDir + "\""		
//	
//	string  	sDBDir	= "\"/dDBDir=" 		+ sDaBDir + "\""				//  the SUBdirectory where InnoSetup will  read and unpack the public data base files , e.g. 'PublicDB' 
//	
////	string  	sStr 		= sCmd + " " + sIssScript + " " + sAppNm + " " + sVersion + " "	+ sSource + " " + sMask + " " + sOutputDir + " " + sDefaultDir + " " + sBirthFile 
//	string  	sStr 		= sCmd + " " + sIssScript + " " + sAppNm + " " + sVersion + " " 	+ sSource + " " + sMask + " " + sOutputDir + " " + sDefaultDir + " " + sDBDir 
//	printf "\t%s   \r", sStr
//	ExecuteScriptText  sStr
//End
//
// 
////===========================================================================================================================================
//
//
//// Test
//Function		UFCom_RIM()
//	UFCom_ReplaceModuleNames( "UFCom_",  "UFSec_",  "c:UserIgor:Commons:test", "c:UserIgor:Commons:Sec", "UFCom_*.*" ) 
//	UFCom_ReplaceModuleNames( "UFCom_",  "UFSec_",  "c:UserIgor:ReleaseTmp:Commons", "c:UserIgor:Commons:Sec", "FP_D*.*" ) 
//End
//
//Function		UFCom_RIM_Back()
//	UFCom_ReplaceModuleNames( "UFSec_",  "UFCom_",  "c:UserIgor:Commons:Sec", "c:UserIgor:Commons:test", "UFSecu_*.*" ) 
//End
////---test
//
//Function		UFCom_ReplaceModuleNames( sSrcTxt, sReplaceTxt, sSrcDir, sTgtDir, sMatch ) 
//// Copy all files which match  'sMatch' (e.g. '*.ipf')  from  'sSrcDir'  into  'sTgtDir'   after having  replaced  'sSrcTxt'  (e.g. 'UFCom_')  by  'sReplaceTxt'  (e.g. 'UFSec_'  or  'UFFPu_') .  This is for COMMON and specific files.
//// If the file name starts with 'sSrcTxt'  (e.g. 'UFCom_')  then also rename the file by replacing 'sSrcTxt'  by  'sReplaceTxt'  (e.g. 'UFSec_'  or  'UFFPu_') .  This is for  COMMON  files.
//	string  	sSrcTxt, sReplaceTxt, sSrcDir, sTgtDir, sMatch
//	string  	lstMatched	= UFCom_ListOfMatchingFiles( sSrcDir, sMatch, FALSE )
//	variable	n, nCnt		= ItemsInList( lstMatched )
//	 printf "\tReplaceIndependentModules(  \t\tReplace  '%s'  by  '%s'  Matched \t%s,\t%s      \t: %2d\tfiles  %s \r",  sSrcTxt, sReplaceTxt, sSrcDir, sMatch, nCnt, lstMatched[0, 300]
//	for ( n = 0; n < nCnt; n += 1 )
//		string  	sFile	=  StringFromList( n, lstMatched )
//		string  	sSrc	= sSrcDir + ":" + sFile
//		string  	sTgt	= sTgtDir + ":" + ReplaceString( sSrcTxt, sFile, sReplaceTxt )	// toImprove: replace only at beginning of name
//		 printf "\tReplaceIndependentModules(  \t%2d/%2d\tReplace \t%s\tby\t%s\tfiles  %s \r",  n, nCnt, UFCom_pd(sSrc,37) , UFCom_pd(sTgt,37), lstMatched[0, 300]
//		UFCom_ReplaceStringInFile( sSrcTxt, sReplaceTxt, sSrc, sTgt ) 
//	endfor  
//End
//
//
//Function		UFCom_ReplaceStringInFile( sSrcTxt, sReplaceTxt, sSrcPath, sTgtPath ) 
//// Copy file  'sSrcPath'  into  'sTgtPath'   after having  replaced  'sSrcTxt'  by  'sReplaceTxt'
//	string  	sSrcTxt, sReplaceTxt
//	string		sSrcPath, sTgtPath								// can be empty ...
//	variable	nRefNum, nRefNumTgt, nLine = 0
//	string		sLine			= ""
//	variable	bIsInPicture	= FALSE
//	
//	Open /Z=2 /R	nRefNum  	   as	sSrcPath						// /Z = 2: opens dialog box  if file is missing,  /Z = 1: no dialog / does nothing if file is missing
//	Open /Z=2 	nRefNumTgt as sTgtPath						//
//	if ( nRefNum != 0 )										// file could be missing  or  user cancelled file open dialog
//		if ( nRefNumTgt != 0 )								
//			do 											// ..if  ReadPath was not an empty string
//				FReadLine nRefNum, sLine
//				if ( strlen( sLine ) == 0 )						// Only at file end the line length is 0 . Empty lines have line length 1 due to the CR
//					break
//				endif
//
//				// Do  NOT  replace characters if we are within a picture 
//				if ( ! bIsInPicture )
//					if ( ( cmpstr( FirstWord( sLine ), "PICTURE" ) == 0  )  ||  ( cmpstr( FirstWord( sLine ), "STATIC" ) == 0  &&  cmpstr( SecondWord( sLine ), "PICTURE" ) == 0   ) )				
//						bIsInPicture = TRUE
//					endif
//				endif
//				if ( bIsInPicture )
//					if ( ( cmpstr( FirstWord( sLine ), "END" ) == 0  ) )
//						bIsInPicture	= FALSE
//					endif
//				endif
//
//				// printf "\tReplaceIndependentModule() \tInPic:%d \t%s ",  bIsInPicture, sLine
//				if ( ! bIsInPicture )
//					sLine = ReplaceString( sSrcTxt, sLine,  sReplaceTxt )	
//				endif
//				
//				fprintf  nRefNumTgt, "%s\n" , sLine			// \n appends 0A . In can be omitted but is included here as the ipf source file also contains it.
//				// printf "\t\tReplaceIndependentModules() \t\t%s ", sLine
//
//				nLine += 1
//			while ( TRUE )     							//...is not yet end of file EOF
//			Close nRefNumTgt							// Close the output file
//		else
//			printf "++++Error: Could not open output file '%s' . (CopyStripComments1File) \r", sTgtPath
//		endif
//		Close nRefNum									// Close the input file
//	else
//		printf "++++Error: Could not open input file '%s' . (CopyStripComments1File) \r", sSrcPath
//	endif
//	//printf "\tReplaceIndependentModules() \t%s\t ->\t%s\t (Lines: %d)  \r", UFCom_pd(sSrcPath,33) ,  UFCom_pd(sTgtPath, 33), nLine
//	return	0
//End
//
//
//
