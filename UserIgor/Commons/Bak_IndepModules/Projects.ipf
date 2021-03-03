//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	Projects.ipf	061026
//
//	Procedures required to create a clean release version of various projects
//	The IPF sources are automatically changed, so use this carefully!
//	We can only change IPF sources programmatically if they are not currently open, so there are functions to close the projects.
//	THIS file  'Projects.ipf'  must be the only open procedure file, so it must be self-contained, so it contains all required helper function as 'static'  and without any prefix 'UFCom'
//
//		Can append    prefixes  to functions and constants so that they are unique to the project  e.g.  'pad()' 		-> 'UFCom_pad()'  , 	'kNOTFOUND' 			-> 'UFCom_kNOTFOUND'
//		Can exchange prefixes of functions and constants so that they are unique to the project  e.g.  'UFCom_pad()' 	-> 'UFSec_pad()'  , 	'UFCom_kNOTFOUND' 	-> 'UFFPu_kNOTFOUND'
//		Can exchange some of the syntax required to turn  IndependentModules  on and off	 e.g.	'UFCom_#'	-> 'UFCom_'
//
//		Can append prefixes to functions and constants so that they are unique to the project  e.g.  'pad()' -> 'UF name
//		Can exchange prefixes of functions and constants so that the 

#pragma rtGlobals=1						// Use modern global access method.

static constant		FALSE = 0, TRUE = 1,  OFF = 0,  ON = 1, kOK = 0
static constant		kNOTFOUND	= -1
static strconstant	ksDIRSEP	= ":"


// Version4 :   New main menu  with new entries.  A shortcut to  THIS  file  and a shortcut to  THIS  directory is required.
Menu "Projects"
	"Independent Module Dev = 0  Off",				Execute "SetIgorOption IndependentModuleDev=0"		// hide  Independent Modules
	"Independent Module Dev = 1  On",				Execute "SetIgorOption IndependentModuleDev=1"		// show Independent Modules	
	"Disable Independent Modules 1", 	     			DisableIndependentModules_()	
	"Unload SecuTest: procs, waves, tables, folders.." , 	UnloadSecuTest_() 
	"Unload SecuTest procedures only" , 				Execute/P "DELETEINCLUDE \"UFST_SecuMain\"";  Execute/P "COMPILEPROCEDURES ";
	"Unload FPulse - FEval procedures only" , 			Execute/P "DELETEINCLUDE \"FPulseMain\"";  	Execute/P "DELETEINCLUDE \"FEvalMain\"";  Execute/P "COMPILEPROCEDURES ";
	"Add Prefix: multi dir, e.g for constants", 	     		AddPrefix()
End



Function		AddPrefix()
	print	"AddPrefix"
End


Function		DisableIndependentModules_()
// Igor does not allows to overwrite a currently open IPF file) so we need a temporary target directory from which we manually have to copy back to the source after Igor has been quit

//	string  	sAppliance = "" 
//	Prompt 	sAppliance, 	"Existing Appliance:", popup, lstAppliances

	string  	sMatch		= "*.ipf"
	string  	sSubDirBak	= "Bak_IndepModules" 
	string  	lstSrcDirs		= "C:UserIgor:Commons;C:UserIgor:SecuTest;C:UserIgor:Ced;" ;		Prompt 	lstSrcDirs,		 "from directories: "
	string  	sSubDir		= "No_IndepModules" ;									Prompt 	sSubDir,		 "into subdirectory: "

// Cave, cave, cave:   The semicolons are vital.  One more or less will ruin all the files! 

// Version1 : 	Remove 2 instances of the pragma 
//	string  	sText		= "#pragma IndependentModule;//#pragma IndependentModule;" ;	Prompt 	sText, 		"Converting1: "
//	string  	sText1		= "UFCom_#;UFCom_;"  ;									Prompt 	sText1, 		"Converting2: "
//	string  	lstTexts		= sText + sText1		// Cave, cave, cave:   The semicolons are vital.  One more or less will ruin all the files! 
//	DoPrompt "Will disable...", sText , sText1,  lstSrcDirs , sSubDir

// Version2a : 	Rename 3 constants
//	string  	sText		= "kPANEL_;UFCom_kPANEL_;"  ;							Prompt 	sText, 		"Converting1: "
//	string  	sText1		= "ksSEP_;UFCom_ksSEP_;" ;								Prompt 	sText1, 		"Converting2: "
//	string  	sText2		= "kY_MISSING_;UFCom_kY_MISSING_;"  ;					Prompt 	sText2, 		"Converting3: "
//	string  	lstTexts		= sText + sText1+ sText2		// Cave, cave, cave:   The semicolons are vital.  One more or less will ruin all the files! 
//	DoPrompt "Will disable...", sText , sText1, sText2,  lstSrcDirs , sSubDir

// Version2b : 	Rename 4 other constants
//	string  	sText		= "ksTILDE_SEP;UFCom_ksSEP_TILDE;"  ;					Prompt 	sText, 		"Converting1: "
//	string  	sText1		= "kXMARGIN;UFCom_kPANEL_kXMARGIN;" ;					Prompt 	sText1, 		"Converting2: "
//	string  	sText2		= "kYHEIGHT;UFCom_kPANEL_kYHEIGHT;"  ;					Prompt 	sText2, 		"Converting3: "
//	string  	sText3		= "kYLINEHEIGHT;UFCom_kPANEL_kYLINEHEIGHT;"  ;			Prompt 	sText3, 		"Converting4: "
//	string  	lstTexts		= sText + sText1+ sText2+ sText3		// Cave, cave, cave:   The semicolons are vital.  One more or less will ruin all the files! 
//	DoPrompt "Will disable...", sText , sText1, sText2, sText3,  lstSrcDirs , sSubDir

// Version2b : 	Rename 4 other constants
	string  	sText		= "kIGOR_;UFCom_kIGOR_;"  ;								Prompt 	sText, 		"Converting1: "
	string  	sText1		= "kSORT;UFCom_kSORT;" ;								Prompt 	sText1, 		"Converting2: "
	string  	sText2		= "kNOTFOUND;UFCom_kNOTFOUND;"  ;					Prompt 	sText2, 		"Converting3: "
	string  	sText3		= "kNUMTYPE_NAN;UFCom_kNUMTYPE_NAN;"  ;				Prompt 	sText3, 		"Converting4: "
	string  	lstTexts		= sText + sText1+ sText2+ sText3		// Cave, cave, cave:   The semicolons are vital.  One more or less will ruin all the files! 
	DoPrompt "Will disable...", sText , sText1, sText2, sText3,  lstSrcDirs , sSubDir


	variable	nFlag		= V_flag
	// Pass 1 :  Display files which will be processed.  The user may still cancel.
	PossiblyDisableIndepModules( sMatch, lstSrcDirs, sSubDir, sSubDirBak, lstTexts, OFF )

	if ( nFlag == 0 )				// user did not cancel
		// Pass 2 :  Now do the replacements
		PossiblyDisableIndepModules( sMatch, lstSrcDirs, sSubDir, sSubDirBak, lstTexts,  ON )
	endif
End

static Function		PossiblyDisableIndepModules( sMatch, lstSrcDirs, sSubDir, sSubDirBak, lstTexts, bDoReplace )
	string  	sMatch, lstSrcDirs, sSubDir, sSubDirBak, lstTexts
	variable	bDoReplace
	// Loop through all directories
	variable	d, nDirs	= ItemsInList( lstSrcDirs )
	for ( d = 0; d < nDirs; d += 1 )
		string  	sDir	= StringFromList( d, lstSrcDirs )
		// Loop through all files
		string  	lstMatchedFiles	= ListOfMatchingFiles( sDir, sMatch, FALSE )
		variable	n, nFiles		= ItemsInList( lstMatchedFiles )
		PossiblyCreatePath( RemoveEnding( sDir, ":" ) +  ":" + sSubDir )
		PossiblyCreatePath( RemoveEnding( sDir, ":" ) +  ":" + sSubDirBak )

		for ( n = 0; n < nFiles; n += 1 )
			string  	sSrcFile		= RemoveEnding( sDir, ":" ) +  ":" + StringFromList( n, lstMatchedFiles )
			string  	sTgtFile		= RemoveEnding( sDir, ":" ) +  ":" + RemoveEnding( sSubDir, 	":" ) +  ":" + StringFromList( n, lstMatchedFiles )
			string  	sTgtFileBak	= RemoveEnding( sDir, ":" ) +  ":" + RemoveEnding( sSubDirBak,	":" ) +  ":" + StringFromList( n, lstMatchedFiles )
			Copy1File( sSrcFile, sTgtFileBak )							
			 printf "\t\t\tDisableIndependentModules_( \t%s\tDir: %2d/%2d\t%s\tFile: %2d/%2d\t%s\t->\t%s\t%s\t->\t%s\t... \r",  sMatch, d, nDirs, pd( sDir,19),  n, nFiles, pd( sSrcFile,32),  pd( sTgtFile, 32) , StringFromList(0,lstTexts), StringFromList(1,lstTexts)
			if ( bDoReplace )
				ReplaceStringsInFile( lstTexts, sSrcFile, sTgtFile ) 	
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



static Function		ReplaceStringsInFile( lstTexts, sSrcPath, sTgtPath ) 
// Read  file  'sSrcPath' ,  replace multiple strings (=the even entries in 'lstTexts' )  by multiple strings  (the odd entries in 'lstTexts' ) .   'sSrcPath'  and  'sTgtPath'  may be the same.   
	string  	lstTexts
	string		sSrcPath, sTgtPath								// can be empty ...
	string  	sSrcTxt, sReplaceTxt
	variable	nRefNum, nRefNumTgt, nLine = 0
	string		sAllText = "", sLine			= ""
	variable	bIsInPicture	= FALSE
	
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
					bIsInPicture = TRUE
				endif
			endif
			if ( bIsInPicture )
				if ( ( cmpstr( FirstWord( sLine ), "END" ) == 0  ) )
					bIsInPicture	= FALSE
				endif
			endif

			// printf "\tUFCom_ReplaceStringInFile() \tInPic:%d \t%s ",  bIsInPicture, sLine
			if ( ! bIsInPicture )
				variable	r, nReplace = ItemsInList( lstTexts ) / 2
				for ( r = 0; r < nReplace; r += 1 )
					sSrcTxt		= StringFromList( r * 2,		lstTexts )	// the even entries
					sReplaceTxt	= StringFromList( r * 2 + 1,	lstTexts )	// the odd entries
					sLine = ReplaceString( sSrcTxt, sLine,  sReplaceTxt )	
				endfor
			endif		
			sAllText	+=	sLine + "\n" 			// \n appends 0A . In can be omitted but is included here as the ipf source file also contains it.
			// printf "\t\tUFCom_ReplaceStringInFile() \t\t%s ", sLine

			nLine += 1
		while ( TRUE )     								//...is not yet end of file EOF
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

//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

static Function		Copy1File( sSrc, sTgt )		
	string  	sSrc, sTgt 		
	CopyFile	/O	sSrc	as	sTgt	
	if ( V_flag )
		printf "++++Error: Could not copy file  '%s' \tto\t'%s'  \r", sSrc, sTgt
	else
		printf "\t\t\tCopied  \t\t%s\tto  \t  '%s' \r", pd(sSrc,35), sTgt
	endif
End	

static Function	PossiblyCreatePath( sPath )
// builds the directory or subdirectory 'sPath' .  Builds a  nested directory including all needed intermediary directories in 1 call to this function. First param must be drive.
// Example : PossiblyCreatePath( "C:kiki:koko" )  first builds 'C:kiki'  then C:kiki:koko'  .  The symbolic path is stored in 'SymbPath1'  which could be but is currently not used.

// todo: extra parameter sSymbolicPath
	string 	sPath
	string 	sPathCopy	, sMsg
	variable	r, n, nDirLevel	= ItemsInList( sPath, ksDIRSEP ) 
	variable	nRemove	= 1
	for ( nRemove = nDirLevel - 1; nRemove >= 0; nRemove -= 1 )				// start at the drive and then add 1 dir at a time, ...
		sPathCopy		= sPath										// .. assign it an (unused) symbolic path. 
		sPathCopy		= RemoveLastListItems( nRemove, sPathCopy, ksDIRSEP )	// ..This  CREATES the directory on the disk
		NewPath /C /O /Q /Z SymbPath1,  sPathCopy	
		if ( V_Flag == 0 )
			 printf "\tPossiblyCreatePath( '%s' )  Removing:%2d of %2d  \t'%s' exists or has been created (V_Flag:%d) \r", sPath, nRemove, nDirLevel, sPathCopy, v_Flag
		else
			sprintf sMsg, "While attempting to create path '%s'  \t'%s' \tcould not be created.", sPath, sPathCopy
			printf "Error:  %s \r", sMsg;    Beep	//UFCom_Alert( kERR_SEVERE, sMsg )
			//UFCom_Alert( kERR_SEVERE, sMsg )
			return	kNOTFOUND	// 0608
		endif
	endfor
	 printf "\tPossiblyCreatePath( '%s' )  \t'%s' exists or has been created (V_Flag:%d) \r", sPath, sPathCopy, v_Flag
	return	kOK		// 0608
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
		// printf "\tListFiles  All   \t( '%s' \t'%s'  \tuip:%d ) ->\t%s \r",  sSrcDir, sMatch,  lstFilesInDir[0, 300]
		lstMatched = ListMatch( lstFilesInDir, sMatch )
		// printf "\tListFiles Matched\t( '%s' \t'%s'   \tuip:%d ) ->\t%s \r",  sSrcDir, sMatch,  lstMatched[0, 300]
		KillPath 	/Z	SymbDir
	endif
	return	lstMatched
End


static constant  cSPACEPIXEL = 3,  cTYPICALCHARPIXEL = 6

static Function  /S  pd( str, len )
	string 	str
	variable	len

	str		= ReplaceString( "\t", str, "" )		// !!! 060106
	variable	nFontSize			= 10
	string  	sFont			= "default"		// GetDefaultFont( "" )
	variable	nStringPixel		= FontSizeStringWidth( sFont, nFontSize, 0, str )
	variable	nRequestedPixel	= len * cTYPICALCHARPIXEL
	variable	nDiffPixel			= nRequestedPixel - nStringPixel
	variable	OldLen 			= strlen( str )
	
	if ( nDiffPixel >= 0 )						// string is too short and must be padded
		return	"'" + str + "'" + PadString( str, OldLen + nDiffPixel / cSPACEPIXEL,  0x20 )[ OldLen, Inf ]
	endif	

	if ( nDiffPixel < 0 )						// string is too long and must be truncated
		string  	strTrunc 
		variable	nTrunc	= min( OldLen, ceil( len*1.3 ) ) + 1	// empirical: start truncation at a string length 30% longer than expected...
		do
			nTrunc	-= 1
			strTrunc	 = str[ 0, nTrunc ]
		while (  nTrunc > 0  &&  FontSizeStringWidth( sFont, nFontSize, 0, strTrunc ) > nRequestedPixel ) 	
		return	"'" + strTrunc + "'"	
	endif
End


