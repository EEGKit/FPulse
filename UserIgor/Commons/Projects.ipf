// 2007-0207 must be overwhauled e.g.  'UserIgor:Ced'  is no longer valid............

//=====================================================================================================================================
//	Projects.ipf	061026
//		Procedures possibly required prior to creating  a clean release version of various projects.
//=====================================================================================================================================
//
//	THIS FILE IS FOR THE DEVELOPER ONLY.  IT IS NOT TO BE DISTRIBUTED TO THE USER !
//
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

//	Problems with 	Conditional Compile   (which in principle works)
//	1.	The project to be conditionally compiled must be unloaded: there must be no open file.  
//		When reloading the conditionally compiled project and there is a Compile error (e.g. a commented out function which is required)  then Igor must be quit , then restarted, then 'Project -> Revive again..' must be executed, then the error must be corrected, which is very TEDIOUS.
//
//	How it should work:
//		If the debug options are just disabled in the release version (but the code is still there) , then it would be sufficient  to simply skip the debug lines in the panel  with a simple 'if kDEBUG  - endif - construct) as it is done in the FPulse 4xx panel.  No conditional compile would be needed.
//		If all debug code is to be deleted in the release version , then during development it should be possible to switch between the  Debug and the Release mode at any time.  If errors occur one should be able to correct them immediately (without having to restart IGOR!)



#pragma rtGlobals=1						// Use modern global access method.

static constant		FALSE = 0, TRUE = 1,  OFF = 0,  ON = 1, kOK = 0
static constant		kNOTFOUND	= -1

// Constants for Conditional Compile : To avoid problems do not change these constants... 
 strconstant		kCC_sMARKER_CONDCOMPILE_BEG	= "// #if_defined DEBUG"
 strconstant		kCC_sMARKER_CONDCOMPILE_END	= "// #endif_defined DEBUG"
static strconstant	kCC_PREFIX_CONDCOMPILE			= "//_cc_ "
 constant			kCC_COMMENT_OUT	= 0, 	kCC_REVIVE_AGAIN	= 1


strconstant  	ksMatch		= "UFST_*.ipf"
strconstant  	klstSrcDirs		= "C:UserIgor:SecuCheck;" 	
//strconstant  	klstSrcDirs		= "C:UserIgor:Commons;C:UserIgor:SecuCheck;C:UserIgor:Ced;"
strconstant  	ksSubDirBak	= "Bak_ConditionalCompile" 
strconstant  	ksSubDir		= "" 					


// Version4 :   New main menu  with new entries.  A shortcut to  THIS  file  and a shortcut to  THIS  directory is required.
Menu "Projects"
//	"Backup FPulse",								BackupFPulse()					// DeInstallFPulse()  and  InstallFPulse()  are companions!
//	"Backup and deinstall FPulse",						DeInstallFPulse()				// DeInstallFPulse()  and  InstallFPulse()  are companions!
//	"-------------------------------------------------------------",				UFMacroDummy()
	"Independent Module Dev = 0  Off",					Execute "SetIgorOption IndependentModuleDev=0"		// hide  Independent Modules
	"Independent Module Dev = 1  On",					Execute "SetIgorOption IndependentModuleDev=1"		// show Independent Modules	
	"Unload FPulse - FEval procedures only" , 				Execute/P "DELETEINCLUDE \"UF_PulseMain\"";  	Execute/P "DELETEINCLUDE \"UF_Evalmain\"";  Execute/P "COMPILEPROCEDURES ";
	"Replace - Disable Independent Modules 1", 			DisableIndependentModules()	
	"Replace - Add UFCom prefix to some constants", 		Add_UF_Com_Prefix_To_Constants()	
	"-------------  Conditional Compile  -------------",				UFMacroDummy()
	"Unload SecuCheck procedures only" , 				Execute/P "DELETEINCLUDE \"UFST_SecuMain\"";  Execute/P "COMPILEPROCEDURES ";
// Problem / Flaw / Todo / Requirement :  'SecuTest.ipf'  must unfortunately be open.....  Better : check existence of function  '	UnloadSecuCheck() '  before  calling it....
//	"Unload SecuCheck: procs, waves, tables, folders.." , 		UnloadSecuCheck() 
//	"Comment out Conditional Compiles SecuMain", 			CommentOutCondCompiles_Secu()
//	"Revive again Conditional Compiles SecuMain", 			ReviveAgainCondCompiles_Secu()
	"-------------------------------------------------------------",				UFMacroDummy()
End


static Function		UFMacroDummy()
End


//=====================================================================================================================================

Function		DisableIndependentModules()
// Igor does not allows to overwrite a currently open IPF file) so we need a temporary target directory from which we manually have to copy back to the source after Igor has been quit
// Cave: The  replacement ins NOT case-sensitive  nor can it replace  'Whole words only'  which would be much better.....->   GREP  ( the underscore should - in contrast to Igors behavior - NOT delimit a word!) 
// ToDo:  Process (as an option) not all files in directories, but rather all open Igor files.  This limits the replacements to the actual projects and would not include any unconnected utilities in the same directory 

	// Version1 : 	Remove 2 instances of the pragma 
	string  	sMatch		= "*.ipf"
	string  	sSubDirBak	= "Bak_IndepModules" 
	string  	lstSrcDirs		= "C:UserIgor:Commons;C:UserIgor:SecuCheck;C:UserIgor:FPulse;C:UserIgor:FEval;" ;	Prompt 	lstSrcDirs,		 "from directories: "
	string  	sSubDir		= "No_IndepModules" ;									Prompt 	sSubDir,		 "into subdirectory: "

	// Cave, cave, cave:   The semicolons are vital.  One more or less will ruin all the files! 
	string  	sText		= "#pragma IndependentModule;//#pragma IndependentModule;" ;	Prompt 	sText, 		"Converting1: "
	string  	sText1		= "UFCom_#;UFCom_;"  ;									Prompt 	sText1, 		"Converting2: "
	string  	lstTexts		= sText + sText1		// Cave, cave, cave:   The semicolons are vital.  One more or less will ruin all the files! 
	DoPrompt "Will replace...", sText , sText1,  lstSrcDirs , sSubDir

	variable	nFlag		= V_flag
	// Pass 1 :  Display files which will be processed.  The user may still cancel.
	ReplaceStringsInFilesInDirs( sMatch, lstSrcDirs, sSubDir, sSubDirBak, lstTexts, OFF )

	if ( nFlag == 0 )				// user did not cancel
		// Pass 2 :  Now do the replacements
		ReplaceStringsInFilesInDirs( sMatch, lstSrcDirs, sSubDir, sSubDirBak, lstTexts,  ON )
	endif
End

Function		Add_UF_Com_Prefix_To_Constants()
// Igor does not allows to overwrite a currently open IPF file) so we need a temporary target directory from which we manually have to copy back to the source after Igor has been quit
// Cave: The  replacement ins NOT case-sensitive  nor can it replace  'Whole words only'  which would be much better.....->   GREP  ( the underscore should - in contrast to Igors behavior - NOT delimit a word!) 
// ToDo:  Process (as an option) not all files in directories, but rather all open Igor files.  This limits the replacements to the actual projects and would not include any unconnected utilities in the same directory 

// Cave, cave, cave:   The semicolons are vital.  One more or less will ruin all the files! 
	string  	sMatch		= "*.ipf"
	string  	sSubDirBak	= "Bak_AddPrefix" 
	string  	lstSrcDirs		= "C:UserIgor:Commons;C:UserIgor:SecuCheck;C:UserIgor:FPulse;C:UserIgor:FEval;" ;	Prompt 	lstSrcDirs,		 "from directories: "
	string  	sSubDir		= "Out_AddPrefix" ;										Prompt 	sSubDir,		 "into subdirectory: "

// Cave, cave, cave:   The semicolons are vital.  One more or less will ruin all the files! 

// Version2a : 	Rename 2 constants
//	string  	sText		= "kPANEL_;UFCom_kPANEL_;"  ;							Prompt 	sText, 		"Converting1: "
//	string  	sText1		= "ksSEP_;UFCom_ksSEP_;" ;								Prompt 	sText1, 		"Converting2: "
//	string  	lstTexts		= sText + sText1	// Cave, cave, cave:   The semicolons are vital.  One more or less will ruin all the files! 
//	DoPrompt "Will replace...", sText , sText1,  lstSrcDirs , sSubDir

// Version2b : 	Rename 4 other constants
	string  	sText		= "kIGOR_;UFCom_kIGOR_;"  ;								Prompt 	sText, 		"Converting1: "
	string  	sText1		= "kSORT;UFCom_kSORT;" ;								Prompt 	sText1, 		"Converting2: "
	string  	sText2		= "kNOTFOUND;UFCom_kNOTFOUND;"  ;					Prompt 	sText2, 		"Converting3: "
	string  	sText3		= "kNUMTYPE_NAN;UFCom_kNUMTYPE_NAN;"  ;				Prompt 	sText3, 		"Converting4: "
	string  	lstTexts		= sText + sText1+ sText2+ sText3		// Cave, cave, cave:   The semicolons are vital.  One more or less will ruin all the files! 
	DoPrompt "Will replace...", sText , sText1, sText2, sText3,  lstSrcDirs , sSubDir

	variable	nFlag		= V_flag
	// Pass 1 :  Display files which will be processed.  The user may still cancel.
	ReplaceStringsInFilesInDirs( sMatch, lstSrcDirs, sSubDir, sSubDirBak, lstTexts, OFF )

	if ( nFlag == 0 )				// user did not cancel
		// Pass 2 :  Now do the replacements
		ReplaceStringsInFilesInDirs( sMatch, lstSrcDirs, sSubDir, sSubDirBak, lstTexts,  ON )
	endif
End

// 2007-0220
//	Function		CommentOutCondCompiles_Secu()
//		printf	"\tCommentOutCondCompiles_Secu() \t  \r"
//	
//		UnloadSecuCheck() 										// Kills waves, tables, folders and the main panel.  Removes _included_ SecuCheck procedures, but procedure windows which were opened by double-clicking on the file remain open.
//	
//	////	Execute/P "DELETEINCLUDE \"UFST_SecuMain\"";  Execute/P "COMPILEPROCEDURES ";	// Unload SecuCheck procedures.  However, procedure windows opened by double-clicking on the file remain open.
//	//	Execute/P "DELETEINCLUDE \"UFST_SecuMain\""
//	//
//	//	string  	lstProcWins	= WinList( "UFST_*", ";", "WIN:128"  )	// will list open procedure windows no matter if they were opened by #include  or by double-clicking on the file
//	//	//string	lstProcWins	= WinList( "UFST_*", ";", "INCLUDE:7"  )	// will only list those windows opened by #include and still open, will NOT list IPF-windows opened directly by double-clicking on the file 
//	//	string  	sProc, sCmd
//	//	variable	n, nWins	= ItemsInList( lstProcWins )
//	//	for ( n = 0; n < nWins; n += 1 )
//	//		sProc	= StringFromList( n, lstProcWins )
//	//		sCmd	= "CloseProc /Save  /Name = \"" + sProc + "\""
//	//		Execute /P /Q /Z	sCmd
//	//	endfor
//	
//		Execute /P "COMPILEPROCEDURES ";						// 
//	
//		Execute /P "ProcessConditCompInFilesInDirs( ksMatch, klstSrcDirs, ksSubDir, ksSubDirBak, kCC_sMARKER_CONDCOMPILE_BEG, kCC_sMARKER_CONDCOMPILE_END, 1, kCC_COMMENT_OUT )"
//	
//		Execute /P "COMPILEPROCEDURES ";						// Compile  SecuCheck  to detect  any programming errors possibly introduced by the automatic insertion of the DEBUG code
//	
//	
//	//	string  	sMatch		= "UFST_*.ipf"
//	//	string  	sSubDirBak	= "Bak_ConditionalCompile" 
//	////	string  	lstSrcDirs		= "C:UserIgor:Commons;C:UserIgor:SecuCheck;C:UserIgor:Ced;" ;	Prompt 	lstSrcDirs,		 "from directories: "
//	//	string  	lstSrcDirs		= "C:UserIgor:SecuCheck;" ;								Prompt 	lstSrcDirs,		 "from directories: "
//	////	string  	sSubDir		= "No_ConditionalCompile" ;								Prompt 	sSubDir,		 "into subdirectory: "
//	//	string  	sSubDir		= "" ;													Prompt 	sSubDir,		 "into subdirectory: "
//	//
//	//	string  	sText		= kCC_sMARKER_CONDCOMPILE_BEG ;						Prompt 	sText, 		"Begin: "
//	//	string  	sText1		= kCC_sMARKER_CONDCOMPILE_END  ;					Prompt 	sText1, 		"End : "
//	//	string  	lstTexts		= sText + sText1	
//	//	DoPrompt "Will comment between...", sText , sText1,  lstSrcDirs , sSubDir
//	//
//	//	variable	nFlag		= V_flag
//	//	// Pass 1 :  Display files which will be processed.  The user may still cancel.
//	//	ProcessConditCompInFilesInDirs( sMatch, lstSrcDirs, sSubDir, sSubDirBak, sText, sText1, OFF, kCC_COMMENT_OUT )
//	//
//	//	if ( nFlag == 0 )				// user did not cancel
//	//		// Pass 2 :  Now do the replacements
//	//		ProcessConditCompInFilesInDirs( sMatch, lstSrcDirs, sSubDir, sSubDirBak, sText, sText1, ON, kCC_COMMENT_OUT )
//	//	endif
//	
//		Execute/P "COMPILEPROCEDURES ";	// Compile  SecuCheck  to detect  any programming errors possibly introduced by the automatic deletion of the DEBUG code
//		
//	End
//	
//	
//	
//	Function		ReviveAgainCondCompiles_Secu()
//	
//		printf	"\tReviveAgainCondCompiles_Secu() \t  \r"
//	
//		UnloadSecuCheck() 									// Kills waves, tables, folders and the main panel.  Removes _included_ SecuCheck procedures, but procedure windows which were opened by double-clicking on the file remain open.
//	
//	////	Execute/P "DELETEINCLUDE \"UFST_SecuMain\"";  Execute/P "COMPILEPROCEDURES ";	// Unload SecuCheck procedures.  However, procedure windows opened by double-clicking on the file remain open.
//	//	Execute/P "DELETEINCLUDE \"UFST_SecuMain\""
//	//
//	//	string  	lstProcWins	= WinList( "UFST_*", ";", "WIN:128"  )	// will list open procedure windows no matter if they were opened by #include  or by double-clicking on the file
//	//	//string	lstProcWins	= WinList( "UFST_*", ";", "INCLUDE:7"  )	// will only list those windows opened by #include and still open, will NOT list IPF-windows opened directly by double-clicking on the file 
//	//	string  	sProc, sCmd
//	//	variable	n, nWins	= ItemsInList( lstProcWins )
//	//	for ( n = 0; n < nWins; n += 1 )
//	//		sProc	= StringFromList( n, lstProcWins )
//	//		sCmd	= "CloseProc /Save  /Name = \"" + sProc + "\""
//	//		Execute /P /Q /Z 	sCmd
//	//	endfor
//	
//		Execute /P "COMPILEPROCEDURES ";						// 
//	
//		Execute /P "ProcessConditCompInFilesInDirs( ksMatch, klstSrcDirs, ksSubDir, ksSubDir, kCC_sMARKER_CONDCOMPILE_BEG, kCC_sMARKER_CONDCOMPILE_END, 1, kCC_REVIVE_AGAIN )"
//	
//		Execute /P "COMPILEPROCEDURES ";						// Compile  SecuCheck  to detect  any programming errors possibly introduced by the automatic deletion of the DEBUG code
//	End
//	
//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

static Function		ReplaceStringsInFilesInDirs( sMatch, lstSrcDirs, sSubDir, sSubDirBak, lstTexts, bDoIt )
// Loops through  'lstSrcDirs',  then loops in each dir through all files matching  'sMatch' , then in each file loop through  'lstTexts'  and replace the even entries (=0,2,4...) by the odd entries (=1,3,5...) 
// Store the replaced files in  'lstSrcDirs's  subdirectory  'sSubDir'  and  store a backup of the original file in subdirectory 'sSubDirBak'.   
// The original files in  'lstSrcDirs'  are not automatically overwritten.  This must be done in an extra manual step  or  ( only if Igor allows to do so ) it could be done automatically.
	string  	sMatch, lstSrcDirs, sSubDir, sSubDirBak, lstTexts
	variable	bDoIt								// FALSE will only display all files which would be processed if TRUE was passed, which will actually do the  replacements
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
			 printf "\t\t\tReplaceStringsInFilesInDirs( \t%s\tDir: %2d/%2d\t%s\tFile: %2d/%2d\t%s\t->\t%s\t%s\t->\t%s\t... \r",  sMatch, d, nDirs, pd( sDir,19),  n, nFiles, pd( sSrcFile,32),  pd( sTgtFile, 32) , StringFromList(0,lstTexts), StringFromList(1,lstTexts)
			if ( bDoIt )
				ReplaceStringsInFile( lstTexts, sSrcFile, sTgtFile ) 	
			endif
		endfor	

// Version without BAK file
//		for ( n = 0; n < nFiles; n += 1 )
//			string  	sSrcFile		= RemoveEnding( sDir, ":" ) +  ":" + StringFromList( n, lstMatchedFiles )
//			string  	sTgtFile		= RemoveEnding( sDir, ":" ) +  ":" + RemoveEnding( sSubDir, ":" ) +  ":" + StringFromList( n, lstMatchedFiles )
//			 printf "\t\t\tDisableIndependentModules_( \t%s\tDir: %2d/%2d\t%s\tFile: %2d/%2d\t%s\t->\t%s\t%s\t->\t%s\t... \r",  sMatch, d, nDirs, pd( sDir,19),  n, nFiles, pd( sSrcFile,32),  pd( sTgtFile, 32) , StringFromList(0,lstTexts), StringFromList(1,lstTexts)
//			if ( bDoReplace )
//				ReplaceStringsInFile( lstTexts, sSrcFile, sTgtFile ) 
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

			// printf "\tReplaceStringInFile() \tInPic:%d \t%s ",  bIsInPicture, sLine
			if ( ! bIsInPicture )
				variable	r, nReplace = ItemsInList( lstTexts ) / 2
				for ( r = 0; r < nReplace; r += 1 )
					sSrcTxt		= StringFromList( r * 2,		lstTexts )	// the even entries
					sReplaceTxt	= StringFromList( r * 2 + 1,	lstTexts )	// the odd entries
					sLine 		= ReplaceString( sSrcTxt, sLine,  sReplaceTxt )	
				endfor
			endif		
			sAllText	+=	sLine + "\n" 			// \n appends 0A . In can be omitted but is included here as the ipf source file also contains it.
			// printf "\t\tReplaceStringInFile() \t\t%s ", sLine

			nLine += 1
		while ( TRUE )     								//...is not yet end of file EOF
		Close nRefNum									// Close the input file
	else
		printf "++++Error: Could not open input file '%s' . (ReplaceStringInFile) \r", sSrcPath
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
		printf "++++Error: Could not open output file '%s' . (ReplaceStringInFile) \r", sTgtPath
	endif
	//printf "\tReplaceStringInFile() \t%s\t ->\t%s\t (Lines: %d)  \r", pd(sSrcPath,33) ,  pd(sTgtPath, 33), nLine
	return	0
End

//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//static Function		ProcessConditCompInFilesInDirs( sMatch, lstSrcDirs, sSubDir, sSubDirBak, sCondCompMarkBeg, sCondCompMarkEnd, bDoIt, bCommentOrRevive )
 Function		ProcessConditCompInFilesInDirs( sMatch, lstSrcDirs, sSubDir, sSubDirBak, sCondCompMarkBeg, sCondCompMarkEnd, bDoIt, bCommentOrRevive )
// Loops through  'lstSrcDirs',  then loops in each dir through all files matching  'sMatch' , then in each file comment out all lines between Conditional Compile directives.
// Store the replaced files in  'lstSrcDirs's  subdirectory  'sSubDir'  and  store a backup of the original file in subdirectory 'sSubDirBak'.   
// The original files in  'lstSrcDirs'  are not automatically overwritten.  This must be done in an extra manual step  or  ( only if Igor allows to do so ) it could be done automatically.
	string  	sMatch, lstSrcDirs, sSubDir, sSubDirBak, sCondCompMarkBeg, sCondCompMarkEnd
	variable	bDoIt								// FALSE will only display all files which would be processed if TRUE was passed, which will actually do the  replacements
	variable	bCommentOrRevive
	// Loop through all directories
	variable	d, nDirs	= ItemsInList( lstSrcDirs )
	for ( d = 0; d < nDirs; d += 1 )
		string  	sDir	= StringFromList( d, lstSrcDirs )
		// Loop through all files
		string  	lstMatchedFiles	= ListOfMatchingFiles( sDir, sMatch, FALSE )
		variable	n, nFiles		= ItemsInList( lstMatchedFiles )
if ( strlen( sSubDir ) )
		PossiblyCreatePath( RemoveEnding( sDir, ":" ) +  ":" + sSubDir )
		sSubDir	= sSubDir + ":"
endif
if ( strlen( sSubDirBak ) )
		PossiblyCreatePath( RemoveEnding( sDir, ":" ) +  ":" + sSubDirBak )
		sSubDirBak	= sSubDirBak + ":"
endif
		for ( n = 0; n < nFiles; n += 1 )
			string  	sSrcFile		= RemoveEnding( sDir, ":" ) +  ":" + StringFromList( n, lstMatchedFiles )
			string  	sTgtFile		= RemoveEnding( sDir, ":" ) +  ":" + sSubDir	+ StringFromList( n, lstMatchedFiles )
if ( strlen( sSubDirBak ) )
			string  	sTgtFileBak	= RemoveEnding( sDir, ":" ) +  ":" + sSubDirBak	+ StringFromList( n, lstMatchedFiles )
			Copy1File( sSrcFile, sTgtFileBak )
endif							
			// printf "\t\tProcessConditCompInFilesInDirs( %s\tDir: %2d/%2d\t%s\tFile: %2d/%2d\t%s\t->\t%s\t%s\t->\t%s\t... \r",  sMatch, d, nDirs, pd( sDir,19),  n, nFiles, pd( sSrcFile,40),  pd( sTgtFile, 40) , sCondCompMarkBeg, sCondCompMarkEnd
			if ( bDoIt )
				ProcessConditionalCompile( sCondCompMarkBeg, sCondCompMarkEnd, sSrcFile, sTgtFile, bCommentOrRevive ) 	
			endif
		endfor	
	endfor	

End


static Function		ProcessConditionalCompile( sCondCompMarkBeg, sCondCompMarkEnd, sSrcPath, sTgtPath, bCommentOrRevive ) 
// Read  file  'sSrcPath' , comment out all lines between Conditional Compile directives.   'sSrcPath'  and  'sTgtPath'  may be the same,  unless IGOR prevents writing (which it will do if the source=target is an open IPF procedure file).   
	string  	sCondCompMarkBeg, sCondCompMarkEnd
	string		sSrcPath, sTgtPath								// can be empty ...
	variable	bCommentOrRevive
	string  	sSrcTxt, sReplaceTxt
	variable	nRefNum, nRefNumTgt, nLine = 0
	string		sAllText = "", sLine		= ""
	variable	bIsInConditionalCompile	= FALSE
	variable	nActions	= 0
	
	// Read source file
	Open /Z=2 /R	nRefNum  	   as	sSrcPath					// /Z = 2: opens dialog box  if file is missing,  /Z = 1: no dialog / does nothing if file is missing
	if ( nRefNum != 0 )									// file could be missing  or  user cancelled file open dialog
		do 											// ..if  ReadPath was not an empty string
			FReadLine nRefNum, sLine
			if ( strlen( sLine ) == 0 )						// Only at file end the line length is 0 . Empty lines have line length 1 due to the CR
				break
			endif

			if ( cmpstr( sLine[ 0, strlen( sCondCompMarkEnd ) -1 ], sCondCompMarkEnd ) == 0  ) 	// Conditional Compile marker must start at line beginning. Thus there will never be a conflict with a picture. 
				bIsInConditionalCompile  = FALSE
			endif

			if ( bIsInConditionalCompile )
				sLine		=  SelectString( bCommentOrRevive,  PrependOnce( kCC_PREFIX_CONDCOMPILE, sLine),  RemoveBeginning( kCC_PREFIX_CONDCOMPILE, sLine ) )	// when commenting then prepend 3 characters , when reviving then remove them again  e.g. '// '		e.g. '// '
				nActions	+= 1
				// printf "\t\t\tProcessConditionalCompile() \t%s\tbIsInCoCo:%d \t%s ",  pd( SelectString( bCommentOrRevive, "Commenting..." , "Reviving..." ),11), bIsInConditionalCompile, sLine
			endif

			if ( cmpstr( sLine[ 0, strlen( sCondCompMarkBeg ) - 1 ], sCondCompMarkBeg ) == 0  ) 	// Conditional Compile marker must start at line beginning. Thus there will never be a conflict with a picture. 
				bIsInConditionalCompile  = TRUE
			endif


			sAllText	+=	sLine + "\n" 					// \n appends 0A . In can be omitted but is included here as the ipf source file also contains it.

			nLine += 1
		while ( TRUE )     								//...is not yet end of file EOF
		Close nRefNum									// Close the input file
	else
		printf "++++Error: Could not open input file '%s' . (ProcessConditionalCompile() \r", sSrcPath
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
		printf "++++Error: Could not open output file '%s' . (ProcessConditionalCompile() \r", sTgtPath
	endif
	 printf "\t\tProcessConditionalCompile() \t%s\t ->\t%s\t %s lines: %d / %d \r", pd(sSrcPath,40) ,  pd(sTgtPath, 40), SelectString( bCommentOrRevive, "Commented out " , "Revived " ), nActions, nLine
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

static Function		CopyFiles( sSrcDir, sMatch, sTgtDir )
// old version , Install.ipf ( was FPulse_Install.pxp)  has  a newer, more versatile one
// e.g. 		CopyFiles(  "D:UserIgor:FPulse"  ,  "FP*.ipf" , "C:UserIgor:FPulseV235"  ) .  Wildcards  *  are allowed .
	string  	sSrcDir, sMatch, sTgtDir
	string  	lstMatched	= ListOfMatchingFiles( sSrcDir, sMatch, FALSE )
	variable	n, nCnt		= ItemsInList( lstMatched )
	for ( n = 0; n < nCnt; n += 1 )
		string  	sSrc	= sSrcDir + ":" + StringFromList( n, lstMatched )
		string  	sTgt	= sTgtDir + ":" + StringFromList( n, lstMatched )
		Copy1File( sSrc, sTgt )
	endfor
End

static Function		Copy1File( sSrc, sTgt )		
	string  	sSrc, sTgt 		
	CopyFile	/O /Z=1	sSrc	as	sTgt		// Z=1 : do not abort on error
	if ( V_flag )
		printf "++++Error: Could not copy file  '%s' \tto\t'%s'  \r", sSrc, sTgt
	else
		// printf "\t\t\tCopied  \t\t%s\tto  \t  '%s' \r", pd(sSrc,35), sTgt
	endif
End	

static Function	PossiblyCreatePath( sPath )
// builds the directory or subdirectory 'sPath' .  Builds a  nested directory including all needed intermediary directories in 1 call to this function. First param must be drive.
// Example : PossiblyCreatePath( "C:kiki:koko" )  first builds 'C:kiki'  then C:kiki:koko'  .  The symbolic path is stored in 'SymbPath1'  which could be but is currently not used.

// todo: extra parameter sSymbolicPath
	string 	sPath
	string 	sPathCopy	, sMsg
	sPath	= ParseFilePath( 5, sPath, ":", 0, 0 ) 						// 2006-1114  return Mac-style path e.g. 'C:UserIgor:FPulse:'
	variable	r, n, nDirLevel	= ItemsInList( sPath, ":" ) 
	variable	nRemove	= 1
	for ( nRemove = nDirLevel - 1; nRemove >= 0; nRemove -= 1 )			// start at the drive and then add 1 dir at a time, ...
		sPathCopy		= sPath									// .. assign it an (unused) symbolic path. 
		sPathCopy		= RemoveLastListItems( nRemove, sPathCopy, ":" )	// ..This  CREATES the directory on the disk
		NewPath /C /O /Q /Z SymbPath1,  sPathCopy	
		if ( V_Flag == 0 )
			// printf "\tPossiblyCreatePath( '%s' )  Removing:%2d of %2d  \t'%s' exists or has been created (V_Flag:%d) \r", sPath, nRemove, nDirLevel, sPathCopy, v_Flag
		else
			sprintf sMsg, "While attempting to create path '%s'  \t'%s' \tcould not be created.", sPath, sPathCopy
			printf "Error:  %s \r", sMsg;    Beep	
			return	kNOTFOUND	// 2006-08
		endif
	endfor
	// printf "\tPossiblyCreatePath( '%s' )  \t'%s' exists or has been created (V_Flag:%d) \r", sPath, sPathCopy, v_Flag
	return	kOK		// 2006-08
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


static  Function    /S	PrependOnce( sPrefix, sString )
	string 	sPrefix, sString
	variable	len	= strlen( sPrefix ) 
	if ( cmpstr( sString[ 0, len - 1 ] , sPrefix ) == 0 )			// sString starts already with sPrefix...
		return   sString								//...so we do  NOT  prepend the prefix a second time
	else
		return   sPrefix + sString
	endif
End


static  Function    /S	RemoveBeginning( sPrefix, sString )
	string 	sPrefix, sString
	variable	len	= strlen( sPrefix ) 
	if ( cmpstr( sString[ 0, len - 1 ] , sPrefix ) == 0 )			// sString starts with sPrefix...
		return   sString[ len, inf ]						//...so we remove sPrefix
	else
		return   sString
	endif
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

