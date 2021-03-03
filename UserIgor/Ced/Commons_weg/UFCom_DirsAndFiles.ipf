#pragma IndependentModule= UFCom_
#pragma IndependentModule= UFCom_
// search 0608 for changes which must be transfered to any newer version
//  UFCom_DirsAndFiles.ipf 
// 
#pragma rtGlobals=1							// Use modern global access method.

#pragma IndependentModule=UFCom_ 
#include "UFCom_Constants"


//#include <File Name Utilities>					// needed for 'ParentFolder()...

// !!! also used elsewhere
constant			kSEARCH_EXISTING	= 0, kSEARCH_FREE = 1

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	AUTOMATIC  FILE NAME  GENERATION

Function	UFCom_PossiblyCreatePath( sPath )
// builds the directory or subdirectory 'sPath' .  Builds a  nested directory including all needed intermediary directories in 1 call to this function. First param must be drive.
// Example : PossiblyCreatePath( "C:kiki:koko" )  first builds 'C:kiki'  then C:kiki:koko'  .  The symbolic path is stored in 'SymbPath1'  which could be but is currently not used.

// todo: extra parameter sSymbolicPathnPhysicalMemorynPhysicalMemorynPhysicalMemory
	string 	sPath
	string 	sPathCopy	, sMsg
	variable	r, n, nDirLevel	= ItemsInList( sPath, ksDIRSEP ) 
	variable	nRemove	= 1
	for ( nRemove = nDirLevel - 1; nRemove >= 0; nRemove -= 1 )				// start at the drive and then add 1 dir at a time, ...
		sPathCopy		= sPath										// .. assign it an (unused) symbolic path. 
		sPathCopy		= UFCom_RemoveLastListItems( nRemove, sPathCopy, ksDIRSEP )	// ..This  CREATES the directory on the disk
		NewPath /C /O /Q /Z SymbPath1,  sPathCopy	
		if ( V_Flag == 0 )
			 printf "\tPossiblyCreatePath( '%s' )  Removing:%2d of %2d  \t'%s' exists or has been created (V_Flag:%d) \r", sPath, nRemove, nDirLevel, sPathCopy, v_Flag
		else
			sprintf sMsg, "While attempting to create path '%s'  \t'%s' \tcould not be created.", sPath, sPathCopy
			UFCom_Alert( kERR_SEVERE, sMsg )
			return	kNOTFOUND	// 0608
		endif
	endfor
	 printf "\tPossiblyCreatePath( '%s' )  \t'%s' exists or has been created (V_Flag:%d) \r", sPath, sPathCopy, v_Flag
	return	kOK		// 0608
End

Function  		UFCom_FPDirectoryExists( sPath )
	string 	sPath
	GetFileFolderInfo /Q	/Z	sPath
	variable	bDirExists	= (  V_Flag == 0   &&   V_IsFolder == 1 )
	// print "\tFPDirectoryExists", sPath, V_Flag, V_IsFolder, "returning: ", bDirExists
	return	bDirExists
End


Function  		UFCom_FileExists( sPathFile )
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

Function		UFCom_PathAndFileExists( sPath, sFile )
// the symbolic path cannot be directly passed but must be passed as a string  and  then catenated with the filename
	string 	sPath, sFile
	variable	nRefNum
	Open	/Z=1 /R 	nRefNum  as sPath + sFile	//   /Z = 1:	does nothing if file is missing
	if  ( V_flag )								// could not open
		// printf "\t\tPathAndFileExists()  returns FALSE as %s does NOT exist \r", sPath + sFile 
		return FALSE
	else										// could open and did it so we must close it again...
		// printf "\t\tPathAndFileExists()  returns  TRUE  as %s does exist  \r", sPath + sFile 
		Close nRefNum
		return TRUE
	endif
End

Function   /S	UFCom_ExtractTrailingCharacters( sPathAndFile, cnt )
// extracts the last 'cnt'  characters from a file name ignoring the extension 
	string 	sPathAndFile
	variable	cnt
	variable	nPos	= strsearch( sPathAndFile,  "." ,  0 )
	if ( nPos == kNOTFOUND )						// if file name contains no dot, no extension: return last 'cnt' characters
		nPos = strlen( sPathAndFile )		
	endif										// if file name contains dot: return last 'cnt' characters before dot
	// printf "\tExtractTrailingCharacters( %s, cnt:%d ) : extracts '%s'   \tat pos:%d \r", sPathAndFile, cnt, sPathAndFile[ nPos-2, nPos-1 ] , pos
	return	sPathAndFile[ nPos-cnt, nPos-1 ]			
End


Function	/S	UFCom_ListOfMatchingFiles( sSrcDir, sMatch, bUseIgorPath )
// Allows file selection using wildcards. Returns list of matching files. Usage : ListFiles(  "C:foo2:foo1"  ,  "foo*.i*"  )
	string  	sSrcDir, sMatch
	variable	bUseIgorPath 
	string  	lstFilesInDir, lstMatched = ""
//	string  	sBase, sExt
//	variable	nMatchParts	= ItemsInList( sMatch, "." )			// could be more than 1 dot  (e.g. if it is an alias) 
//	sExt		=  "." + StringFromList( nMatchParts-1, sMatch, "." )	// Hack out everything after   the LAST dot. The dot must exist.
//	sBase	= RemoveListItem( nMatchParts - 1 , sMatch, "." )	// Hack out everything before the LAST dot. The dot must exist. 
//	sBase	= RemoveEnding( sBase )						// truncate dot

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

// obsolete , use ParseFilePath()
Function	/S 	UFCom_Path2Win( sMacPath )
// Convert Mac path to Windows path convention
	string  	sMacPath									// complete path including drive letter e.g. 'C:UserIgor:Ced:'
	string  	sWinPath	= ""								// path converted to windows convention
	if ( cmpstr( sMacPath[ 1, 1 ] ,  ":" )  == 0 )					// e.g. 'C:UserIgor:Ced:'
		sWinPath	= sMacPath[ 0, 1 ]						// e.g. 'C:'
	endif
	sWinPath	+= ReplaceString( ":", sMacPath[ 1, inf ], "\\" )		// e.g. 'C:' + '\\UserIgor\\Ced\\' 
	return	sWinPath									// e.g. 'C:\\UserIgor\\Ced\\' 
End


///////////////////////////////////////////////////////////////////////////////////////////////
//      060811   NEW.............. AUTOMATIC  NAMING  MODES

//constant			kONELETTER = 0,  kDIGITLETTER = 1,  kTWOLETTER = 2				// automatic naming of  files   !!!elsewhere also

static strconstant	lstMODES					= "1 Letter;1 Digit or Letter;2 Letters;"
static strconstant	lstNCHARACTERS			= "1;1;2;"								// a...z;  0,1...8,9,a,b,...x,y,z;  26*26 
static strconstant	lstMAXINDICES				= "26;36;676;"							// a...z;  0,1...8,9,a,b,...x,y,z;  26*26 
static strconstant	klstONELETTER			= "a;b;c;d;e;f;g;h;i;j;k;l;m;n;o;p;q;r;s;t;u;v;w;x;y;z;"
static strconstant	klstDIGITLETTER			= "0;1;2;3;4;5;6;7;8;9;a;b;c;d;e;f;g;h;i;j;k;l;m;n;o;p;q;r;s;t;u;v;w;x;y;z;"

static Function	LettersToIdx( sLetters, NamingMode )
// extract  index  from  1 or 2  characters and return it
	string 	sLetters
	variable	NamingMode
	variable	idx
	if ( NamingMode == kONELETTER )							// computes index of 1 letter, 	e.g.	a=0 , b=1, ...z=25
		idx	= WhichListItem( LowerStr( sLetters ), klstONELETTER )	// could alternatively be computed using char2num()  and num2char() 
	elseif ( NamingMode == kDIGITLETTER )						// computes index of character, 	e.g.  0, 1...8, 9, a=10, b=11 .... z=36
		idx	= WhichListItem( LowerStr( sLetters ), klstDIGITLETTER )	// could alternatively be computed using char2num()  and num2char() 
	elseif ( NamingMode == kTWOLETTER )						// computes index of 2-letter-combination, e.g.  AA=0 , AB=1, ...ZZ=575
		//idx	= 26 * ( char2num( sLetters[ 0, 0 ] ) - char2num( "A" ) )    +     char2num( sLetters[ 1, 1 ] ) - char2num( "A" ) 
		idx	= 26 * ( char2num( UpperStr( sLetters[ 0, 0 ] ) ) - char2num( "A" ) ) + char2num( UpperStr( sLetters[ 1, 1 ] ) ) - char2num( "A" ) // file names must be case-insensitive
	endif
	 printf "\tLettersToIdx(  '%s', mode:%d )  \t->\t%d\t \r", sLetters, NamingMode, idx
	return idx
End

static Function  /S	IdxToLetters( nIndex, NamingMode )	
// convert  index  into a one character   or  into a  two-letter-combination and return it
	variable	nIndex
	variable	NamingMode
	string  	sLetters	= ""
	if ( NamingMode == kONELETTER )							// convert  index (allowed range 0..25) into 1 letter
		sLetters	= StringFromList( nIndex, klstONELETTER ) 
	elseif ( NamingMode == kDIGITLETTER )						// convert  index (allowed range 0..35) into 1 character (digit or letter) and return it
		sLetters	= StringFromList( nIndex, klstDIGITLETTER ) 
	elseif ( NamingMode == kTWOLETTER )						// convert  index (allowed range 0..26x26-1) into a two letter combination and return it
		if ( nIndex == -1 )
			return "__"
		endif
		string 	sChars	= "A;B;C;D;E;F;G;H;I;J;K;L;M;N;O;P;Q;R;S;T;U;V;W;X;Y;Z"
		variable	nDigits	= ItemsInList( sChars )
		variable	nHiIndex	= trunc(	nIndex / nDigits )			// 0=AA, 1=AB, ...25=AZ, 26=BA, 27=BB,...
		variable	nLoIndex	= mod(	nIndex, nDigits )
		sLetters	= StringFromList( nHiIndex, sChars ) +  StringFromList( nLoIndex, sChars )
	endif
	return	sLetters
End

static Function   /S	BuildNextPathFile( sPathAndFileOld, nIndex, NamingMode )
// builds the path and file of the next file. Starts with  sPathAndFile  and replaces the 2-letter-combination by  new 2 letters given by nIndex
	string 	sPathAndFileOld
	variable	nIndex
	variable	NamingMode
	string  	sPathAndFile	= sPathAndFileOld
	variable	nPos	= strsearch( sPathAndFileOld,  "." ,  0 )
	if ( nPos == kNOTFOUND )										// if file name contains no dot, no extension: we use the  last 2 characters
		nPos		= strlen( sPathAndFileOld )		
	endif														// if file name contains a dot: we use the last 2 characters before dot
	variable	nCharacters	= str2num( StringFromList( NamingMode, lstNCHARACTERS ) )
	sPathAndFile[ nPos-nCharacters, nPos-1 ]  = IdxToLetters( nIndex, NamingMode )	// replace the 2 characters found by the letters given by the new index
	 printf "\t\tBuildNextPathFile(  '%s'  , nIndex:%d,  mode:%d ) -> '%s' \r" , sPathAndFileOld, nIndex, NamingMode, sPathAndFile			
	return	sPathAndFile			
End


// should replace FPulse /FEval  GetNextFileNm()
Function   /S	UFCom_GetNextFileNm_( sFo, sPathAndFile, bSearchNextFree, step, NamingMode )
// gets the next  EXISTING  file starting at  'sPathAndFile'.  Search direction is given by  'step'.
// old version, for a better code see    GetNextFileNm___()    below. 
// Possible flaws in this version : Processing might be confused  1. mixing naming modes in 1 directory and  2. by mixing small and capital letter file names (user may have renamed the files..) 
	string 	sFo	// is always ksEVAL
	string 	sPathAndFile			// start with this file
	variable	bSearchNextFree		// TRUE: search unused file, FALSE: search existing file
	variable	step					// +1  or  -1 :  search going forward or backward
	variable	NamingMode			//  1 letter, 1 DigitLetter  or  2 letters
	string 		errbf, sNextUsedFile 
	variable	nIndex
	if ( strlen( sPathAndFile ) == 0 )
		UFCom_InternalError( "Cannot find another file before / after unspecified file '" + sPathAndFile + "' . " )
		return	""
	endif

	// start at nIndex given by 'sPathAndFile'  and  (depending on 'step')  increment or decrement index skipping all non-existing files, return index of  first used file found
	variable	nCharacters	= str2num( StringFromList( NamingMode, lstNCHARACTERS ) )
	variable	nMaxIndex	= str2num( StringFromList( NamingMode, lstMAXINDICES ) )

	nIndex = LettersToIdx( UFCom_ExtractTrailingCharacters( sPathAndFile, nCharacters ), NamingMode )
	do
		nIndex	+= step
		if ( nIndex == -1  ||  nIndex == nMaxIndex )
			//? very peculiar behaviour: the following warning is sometimes output much too late (one cyle later, and then twice.......)
			sprintf errbf, "Cannot find another file with matching base name and cell number %s '%s' . ", SelectString( step>0, "before", "after" ), sPathAndFile
			UFCom_FoAlert( sFo, kERR_LESS_IMPORTANT,  errbf )
			return	sPathAndFile						// return unchanged file
		endif
		sNextUsedFile = BuildNextPathFile( sPathAndFile, nIndex, NamingMode ) 
	while ( UFCom_FileExists( sNextUsedFile ) == bSearchNextFree ) 		// TRUE: search unused file, FALSE: search existing file

	 printf "\t\tGetNextFileNm_( '%s'  searches next '%s' file   going '%s', step:%d,  mode:'%s' )   -> %s   \r", sPathAndFile,  SelectString( bSearchNextFree==kSEARCH_FREE, "used ", "free"),  SelectString( step==-1, "up    ", "down"), step, StringFromList( NamingMode, lstMODES ), sNextUsedFile
	return	sNextUsedFile 
End


Function   /S	UFCom_GetNextFileNm__( sDir, sFileBase, sExt, NamingMode )
// gets the next  free/unused  file  above the highest used file in directory 'sDir'  starting with  'sFileBase' and having the appropriate number (or none) of postfix characters.  
// As we are processing files the processing must be and is case-insensitive, although (for historical reasons)  the appended postfixes are small or capiatal letters..
	string 	sDir
	string 	sFileBase					// use this file base, look for appended letter(s)   and append letters
	string  	sExt
	variable	NamingMode				// 1 letter, 1 DigitLetter  or  2 letters
	string 	sNextUsedFile 
	variable	nCharacters	= str2num( StringFromList( NamingMode, lstNCHARACTERS ) )	// we must only process files which have a matching number of 'NamingMode' characters (=1 or 2)...
	variable	nMatchLen	= strlen( sFileBase + sExt ) + nCharacters					// ...or the code gets confused e.g. when there is TSTa, TSTb and we try to continue with  TSTAA...
	variable	nIndex, nMaxIndex
	string  	sMatch	= sFileBase + "*"		
	string  	lstOfFiles	= UFCom_ListOfMatchingFiles( sDir, sMatch, FALSE )
	variable	n, nFiles	= ItemsInList( lstOfFiles ) 
	// We must discriminate between the naming modes to avoid erroneous program behavior if 1- and 2-character mode files are mixed in the same directory.
	for ( n = nFiles-1 ; n >= 0;  n -= 1 )
		if ( strlen( StringFromList( n, lstOfFiles ) ) != nMatchLen )
			lstOfFiles	= RemoveListItem( n, lstOfFiles ) 	
		endif 
	endfor
	nFiles	= ItemsInList( lstOfFiles ) 											// number may have changed
	string  	sHighestFile
	if ( nFiles == 0 )
		sNextUsedFile	= sFileBase + IdxToLetters( 0, NamingMode ) + sExt				// create the first file by appending 'a', '0' or 'AA'
	else
		lstOfFiles		= SortList( lstOfFiles, ";" ,  4 ) 	// we MUST sort case-insensitive (4), but we cannot sort alpha-numerical (16)  as a..z  would  be ordered in front of 0..9  but  we require a..z to come after 0..9
		sHighestFile	= StringFromList( nFiles - 1, lstOfFiles )
		nIndex 		= LettersToIdx( UFCom_ExtractTrailingCharacters( sHighestFile, nCharacters ), NamingMode ) + 1
		nMaxIndex	= str2num( StringFromList( NamingMode, lstMAXINDICES ) )
		if ( nIndex	== nMaxIndex - 1 )
			UFCom_Alert1( kERR_IMPORTANT, "You are now using the highest possible auto-assigned index.\rBefore the next time you  must change the base name or data will be lost.\r\r" + sHighestFile )
		elseif ( nIndex	>= nMaxIndex )
			UFCom_Alert1( kERR_FATAL, "You are now overwriting the highest possible auto-assigned index.\r\r" + sHighestFile )
		endif
		sNextUsedFile 	= BuildNextPathFile( sHighestFile, nIndex, NamingMode ) 
	endif
	 printf "\t\tGetNextFileNm__( '%s'  '%s' has %d files.  Mode:'%s' )   -> %s   \r", sDir, sFileBase, nFiles,  StringFromList( NamingMode, lstMODES ), sNextUsedFile
	return	sNextUsedFile 
End



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//   060911    OBSOLETE......... Functions  used  when  reading  CFS  files  ( NOT  relying on  globals, which are valid and used only during acquisition)

		Function   /S	UFCom_GetNextFileNm( sFo, sPathAndFile, bSearchNextFree, step, NamingMode )
		// gets the next  EXISTING  file starting at  'sPathAndFile'.  Search direction is given by  'step'.
			string 	sFo	// is always ksEVAL
			string 	sPathAndFile			// start with this file
			variable	bSearchNextFree		// TRUE: search unused file, FALSE: search existing file
			variable	step					// search going forward or backward
			variable	NamingMode			// DigitLetter for evaluation results  or  2 letters for Cfs files 
			string 		errbf, sNextUsedFile 
			variable	nIndex
			if ( strlen( sPathAndFile ) == 0 )
				UFCom_InternalError( "Cannot find another file before / after unspecified file '" + sPathAndFile + "' . " )
				return	""
			endif
		
			// start at nIndex given by 'sPathAndFile'  and  (depending on 'step')  increment or decrement index skipping all non-existing files, return index of  first used file found
		
			if ( NamingMode == kTWOLETTER )
				nIndex = UFCom_TwoLettersToIdx( UFCom_ExtractTrailingCharacters( sPathAndFile, 2 ) )
				do
					nIndex	+= step
					if ( nIndex == -1  ||  nIndex == kMAXINDEX_2LETTERS )
						//? very peculiar behaviour: the following warning is sometimes output much too late (one cyle later, and then twice.......)
						sprintf errbf, "Cannot find another file with matching base name and cell number %s '%s' . ", SelectString( step>0, "before", "after" ), sPathAndFile
						UFCom_FoAlert( sFo, kERR_LESS_IMPORTANT,  errbf )
						return	sPathAndFile						// return unchanged file
					endif
					sNextUsedFile = BuildNextPathFileTwoLetters( sPathAndFile, nIndex ) 
				while ( UFCom_FileExists( sNextUsedFile ) == bSearchNextFree ) 		// TRUE: search unused file, FALSE: search existing file
				//while ( !FileExists( sNextUsedFile )   ) 
			endif
		
			if ( NamingMode == kDIGITLETTER )
				nIndex = UFCom_DigitLetterToIdx( UFCom_ExtractTrailingCharacters( sPathAndFile, 1 ) )
				do
					nIndex	+= step
					if ( nIndex == -1  ||  nIndex == kMAXINDEX_2LETTERS )
						//? very peculiar behaviour: the following warning is sometimes output much too late (one cyle later, and then twice.......)
						sprintf errbf, "Cannot find another file with matching base name and cell number %s '%s' . ", SelectString( step>0, "before", "after" ), sPathAndFile
						UFCom_FoAlert( sFo, kERR_LESS_IMPORTANT,  errbf )
						return	sPathAndFile						// return unchanged file
					endif
					sNextUsedFile = BuildNextPathFileDigitLetter( sPathAndFile, nIndex ) 
				while ( UFCom_FileExists( sNextUsedFile ) == bSearchNextFree ) 		// TRUE: search unused file, FALSE: search existing file
				//while ( !FileExists( sNextUsedFile )   ) 
			endif
		
			 printf "\t\tGetNextFileNm( '%s'  searches next '%s' file   going '%s' step:%d  '%s' )   -> %s   \r", sPathAndFile,  SelectString( bSearchNextFree==kSEARCH_FREE, "used ", "free"),  SelectString( step==-1, "up    ", "down"), step, SelectString( NamingMode==kDIGITLETTER, "TwoLetter", "Digit or Letter" ), sNextUsedFile
			return	sNextUsedFile 
		End
		
		///////////////////////////////////////////////////////////////////////////////////////////////
		//  060911    OBSOLETE......... NAMING MODE for CFS files  		:	TWO LETTERS		(2 characters)
		
		Function		UFCom_TwoLettersToIdx( sTwoLetters )
		// computes index of 2-letter-combination, e.g.  AA=0 , AB=1, ...ZZ=575
			string 	sTwoLetters
			return	26 * ( char2num( sTwoLetters[ 0, 0 ] ) - char2num( "A" ) )    +     char2num( sTwoLetters[ 1, 1 ] ) - char2num( "A" ) 
		End
		
		Function  /S	UFCom_IdxToTwoLetters( nIndex )	
		// convert  index (allowed range 0..26x26-1) into a two letter combination and return it
			variable	nIndex
			if ( nIndex == -1 )
				return "__"
			endif
			string 	sChars	= "A;B;C;D;E;F;G;H;I;J;K;L;M;N;O;P;Q;R;S;T;U;V;W;X;Y;Z"
			variable	nDigits	= ItemsInList( sChars )
			variable	nHiIndex	= trunc(	nIndex / nDigits )	// 0=AA, 1=AB, ...25=AZ, 26=BA, 27=BB,...
			variable	nLoIndex	= mod(	nIndex, nDigits )
			return	StringFromList( nHiIndex, sChars ) +  StringFromList( nLoIndex, sChars )
		End
		
		static Function   /S	BuildNextPathFileTwoLetters( sPathAndFile, nIndex )
		// builds the path and file of the next file. Starts with  sPathAndFile  and replaces the 2-letter-combination by  new 2 letters given by nIndex
			string 	sPathAndFile
			variable	nIndex
			variable	nPos	= strsearch( sPathAndFile,  "." ,  0 )
			if ( nPos == kNOTFOUND )								// if file name contains no dot, no extension: we use the  last 2 characters
				nPos		= strlen( sPathAndFile )		
			endif												// if file name contains a dot: we use the last 2 characters before dot
			sPathAndFile[ nPos - 2, nPos - 1 ]  =  UFCom_IdxToTwoLetters( nIndex )	// replace the 2 characters found by the letters given by the new index
			// print "\tBuildNextPathFileTwoLetters()" , nIndex, sPathAndFile			
			return	sPathAndFile			
		End
		
		
		
		///////////////////////////////////////////////////////////////////////////////////////////////
		//  060911    OBSOLETE......... NAMING  MODE  for  RESULT (=AVG,TBL)   FILES  :  DIGIT/LETTER 	( 1 character)
		
		Function		UFCom_DigitLetterToIdx( sChar )
		// computes index of character, e.g.  0,1...8,9,a,b...x.y.z
			string 		sChar
			// print "\tDigitLetterToIdx() ",  sChar, "->",  WhichListItem( sChar, klstDIGITLETTER )		
			return	WhichListItem( LowerStr( sChar ), klstDIGITLETTER )				// could alternatively be computed using char2num()  and num2char() 
		End
		
		Function  /S	UFCom_IdxToDigitLetter( nIndex )	
		// convert  index (allowed range 0..35) into 1 character (digit or letter) and return it
			variable	nIndex
			return	StringFromList( nIndex, klstDIGITLETTER ) 
		End
		
		static  Function   /S	BuildNextPathFileDigitLetter( sPathAndFile, nIndex )
		// builds the path and file of the next file. Starts with  sPathAndFile  and replaces the last character  by  a  new characters given by nIndex
			string 	sPathAndFile
			variable	nIndex
			variable	nPos	= strsearch( sPathAndFile,  "." ,  0 )
			if ( nPos == kNOTFOUND )								// if file name contains no dot, no extension: we use the  last  character
				nPos		= strlen( sPathAndFile )		
			endif												// if file name contains a dot: we use the last character before dot
			sPathAndFile[ nPos - 1, nPos - 1 ]  =  UFCom_IdxToDigitLetter( nIndex )		// replace the 1 character found by the new character given by the new index
			// print "\tBuildNextPathFileDigitLetters()" , nIndex, sPathAndFile			
			return	sPathAndFile			
		End
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		

Function	/S	UFCom_TimeStamp()
	// a new time stamp is generated  every second . Format : yymmdd_hhmmss
	string 	sDateTime	= Secs2Date( DateTime, -1 ) + Time()
	//string 	sTimeStamp	= sDateTime[ 8,9 ] + sDateTime[ 3,4 ] + sDateTime[ 0,1 ] + "_" + num2str( str2num(sDateTime[ 14,15 ] )*4 + str2num(sDateTime[ 17 ])) 	//  mmdd_nn : a new time stamp is generated  every 10 minutes 
	string 	sTimeStamp	= sDateTime[ 8,9 ] + sDateTime[ 3,4 ] + sDateTime[ 0,1 ] + "_" + sDateTime[ 14,15 ] + sDateTime[ 17,18 ]  + sDateTime[ 20,21 ]  	// yymmdd_hhmmss : a new time stamp is generated  every second
	// print "\t\tTimeStamp()", Date(), Time(), Secs2Date( DateTime, -1 ), sDateTime, sTimeStamp
	return	sTimeStamp
End

Function	/S	UFCom_TimeStamp1sec()
	// a new time stamp is generated  every second . Format : yymmdd_hhmmss
	string 	sDateTime	= Secs2Date( DateTime, -1 ) + Time()
	string 	sTimeStamp	= sDateTime[ 8,9 ] + sDateTime[ 3,4 ] + sDateTime[ 0,1 ] + "_" + sDateTime[ 14,15 ] + sDateTime[ 17,18 ]  + sDateTime[ 20,21 ]  	// yymmdd_hhmmss : a new time stamp is generated  every second
	// print "\t\tTimeStamp()", Date(), Time(), Secs2Date( DateTime, -1 ), sDateTime, sTimeStamp
	return	sTimeStamp
End

Function	/S	UFCom_TimeStamp1Min()
	// a new time stamp is generated every minute. Format : yymmdd_hhmm
 	string 	sDateTime    = Secs2Date( DateTime, -1 ) + Time()
	string 	sTimeStamp = sDateTime[ 8,9 ] + sDateTime[ 3,4 ] + sDateTime[ 0,1 ] + "_" + sDateTime[ 14,15 ] + sDateTime[ 17,18 ]   		// yymmdd_hhmm : a new file name every minute 
	return	sTimeStamp
End

Function	/S	UFCom_TimeStamp10Min()
	// a new time stamp is generated every 10 minutes. Format : mmdd_nn
 	string 	sDateTime    = Secs2Date( DateTime, -1 ) + Time()
	string 	sTimeStamp = sDateTime[ 3,4 ] + sDateTime[ 0,1 ] + "_" + num2str( str2num(sDateTime[ 14,15 ] )*4 + str2num(sDateTime[ 17 ])) //  mmdd_nn : a new file name every 10 minutes 
	return	sTimeStamp
End

Function	/S	UFCom_TimeStamp1Day()
	// a new time stamp is generated every day. Format : yymmdd
	string 	sDateTime		= Secs2Date( DateTime, -1 ) 
	string 	sTimeStamp	= sDateTime[ 8,9 ] + sDateTime[ 3,4 ] + sDateTime[ 0,1 ] 
	return	sTimeStamp
End




Function  /S  	UFCom_GetFileNameFromDialog( sFileNameOrEmpty )
// Displays FileOpen Dialog if parameter  'sFileNameOrEmpty'  is empty string ...
// changes the symbolic path
// returns selected  valid  filename or empty string  if user clicked  CANCEL
	string 	sFileNameOrEmpty					
	variable	nRefNum

	if ( strlen( sFileNameOrEmpty ) == 0 )							// user must choose file: present File Open Dialog but do not open
		Open /R /D /P=symbPath nRefNum as sFileNameOrEmpty
		// PathInfo /S symbPath;  printf "\t\t\tGetFileNameFromDialog( with dialog ): Receives FilePath:'%s' , Symbolic path '%s' does %s exist. -> returns '%s'  \r", sFileNameOrEmpty , S_path, SelectString( v_Flag,  "NOT", "" ), s_fileName

		if ( strlen( S_fileName ) )								// used selected a file (did not click Cancel)
			string 	sNewPath = S_fileName
			sNewPath		= UFCom_StripFileAndExtension( sNewPath )
			NewPath /O /Q	symbPath,  sNewPath
			// PathInfo /S symbPath;  printf "\t\t\tGetFileNameFromDialog() \tAttempted to change Symb path to '%s'   ->   New Symbolic (script) path is '%s'  (does %s exist). \r", sNewPath, S_path, SelectString( v_Flag,  "NOT", "" )
		endif
		return S_fileName									// can also be empty if user clicked Cancel
	else
		// printf "\t\t\tGetFileNameFromDialog(without dialog):  receives and returns  FilePath:'%s'  \r", sFileNameOrEmpty 	
		return sFileNameOrEmpty
	endif	
End


Function  /S  	UFCom_GetFileNameFromDialog_1( sSymbPath, sExt )
// Displays  FileOpen Dialog.    The initial directory is that of the symbolic path 'sSymbPath'  .  The symbolic path will be changed if the user navigates and selects another directory.
// Displays only files with an extension matching 'sExt'  e.g.  '.txt'  or  '.dab'
// Return string path:  Returns the selected  valid  file path				including	filename.ext   or   returns empty string  if user clicked  CANCEL
// Symbolic path :	    Sets  symbolic path to the selected valid  directory	without	filename.ext   or   leaves symbolic path unchanged  if user clicked  CANCEL (a symbolic path can never include the file name)
	string 	sSymbPath, sExt
	string  	sFileNameOrEmpty	= ""					
	variable	nRefNum

	Open /R /D /P=$sSymbPath 	/T=sExt	nRefNum as sFileNameOrEmpty	// user must choose file: present File Open Dialog but do not open
	sFileNameOrEmpty	= S_fileName
	 PathInfo /S $sSymbPath;  printf "\t\t\tGetFileNameFromDialog_1( after dialog ):\tSymbolic path  '%s'  does %s exist. -> returns  '%s'  \r",  S_path, SelectString( v_Flag,  "NOT", "" ), sFileNameOrEmpty

	if ( strlen( sFileNameOrEmpty ) )									// used selected a file (did not click Cancel)
		string  sNewPath = sFileNameOrEmpty
		sNewPath		  = UFCom_StripFileAndExtension( sNewPath )				// only drive and directory is left...
		NewPath /O /Q	$sSymbPath,  sNewPath						//...as a symbolic path can never include the file name
		 PathInfo /S $sSymbPath;  printf "\t\t\tGetFileNameFromDialog_1( on returning): \tSymbolic path  '%s'  does %s exist. -> returns  '%s'  [sNewPath: '%s'] \r", S_path, SelectString( v_Flag,  "NOT", "" ),  sFileNameOrEmpty, sNewPath
	endif
	return sFileNameOrEmpty										// can also be empty if user clicked Cancel
End


Function  /S  	UFCom_GetFileNameFromDialogStay( sSymbPath, sExt, sErrTxt )
// Displays  FileOpen Dialog.    The user is forced to stay in the initial directory which is that of the symbolic path 'sSymbPath'  . 
// Displays only files with an extension matching 'sExt'  e.g.  '.txt'  or  '.dab'
// Return string path:  Returns the selected  valid  file path				including	filename.ext   or   returns empty string  if user clicked  CANCEL
// Symbolic path :	    Sets  symbolic path to the selected valid  directory	without	filename.ext   or   leaves symbolic path unchanged  if user clicked  CANCEL (a symbolic path can never include the file name)
	string 	sSymbPath, sExt, sErrTxt
	string  	sFileNameOrEmpty	= ""					
	variable	nRefNum
	PathInfo /S $sSymbPath
	//  printf "\t\t\tGetFileNameFromDialogStay( initially ):\tSymbolic path  '%s'  does %s exist. \r",  S_path, SelectString( v_Flag,  "NOT", "" )
	string  sInitialPath	= S_path
	
	do 
		sFileNameOrEmpty	= ""					
		Open /R /D /P=$sSymbPath 	/T=sExt	nRefNum as sFileNameOrEmpty	// user must choose file: present File Open Dialog but do not open
		sFileNameOrEmpty	= S_fileName
		// PathInfo /S $sSymbPath;  printf "\t\t\tGetFileNameFromDialogStay( after dialog ):\tSymbolic path  '%s'  does %s exist. -> returns  '%s'  \r",  S_path, SelectString( v_Flag,  "NOT", "" ), sFileNameOrEmpty
	
		if ( strlen( sFileNameOrEmpty ) )									// used selected a file (did not click Cancel)
			string  sNewPath = sFileNameOrEmpty
			sNewPath		  = UFCom_StripFileAndExtension( sNewPath )				// only drive and directory is left...
			variable  	nCode = cmpstr( sInitialPath, sNewPath )
			if ( nCode == 0 )											// user has not changed the directory : OK
				NewPath /O /Q	$sSymbPath,  sNewPath					//...as a symbolic path can never include the file name
				// PathInfo /S $sSymbPath;  printf "\t\t\tGetFileNameFromDialogStay( on returning ):\tSymbolic path  '%s'  does %s exist. -> returns  '%s'  [sNewPath: '%s'] \r", S_path, SelectString( v_Flag,  "NOT", "" ),  sFileNameOrEmpty, sNewPath
			else
				UFCom_Alert1( kERR_IMPORTANT, sErrTxt )
				DoAlert 0, sErrTxt
				Beep
				NewPath /O /Q	$sSymbPath,  sInitialPath					//  a symbolic path can never include the file name
			endif
		endif
	while ( nCode != 0  &&  strlen( sFileNameOrEmpty ) > 0  )		// escape from the loop either by staying in the initial directory  or  by leaving the file dialog with 'Cancel'

	return sFileNameOrEmpty										// can also be empty if user clicked Cancel
End


//////////////////////////////////////////////////////////////////////////////////////////////////
//  PATH  PROCESSING   partly rendered obsolete by  'ParseFilePath()'

Function /S	UFCom_StripExtension( sPathAndFileAndExt )
// Remove extension (=everything after the dot) . The dot is kept. If there was no dot the string is returned unchanged.
	string 	sPathAndFileAndExt
	return	RemoveListItem( 1, sPathAndFileAndExt, "." )			// remove extension (=everything after dot)
End	

Function /S	UFCom_StripExtensionAndDot( sPathAndFileAndExt )
// Remove extension and dot . If there was no dot the string is returned unchanged.
	string 	sPathAndFileAndExt
	string 	sBase	= RemoveListItem( 1, sPathAndFileAndExt, "." )	// remove extension (=everything after dot)
	return	RemoveEnding( sBase, "." )						// remove the dot
End	

Function /S	UFCom_StripFileAndExtension( sPathAndFileAndExt )
	string 	sPathAndFileAndExt
// Converts  'C:dir1:dir2:file.ext'   or   'C:dir1:dir2:file.'  or  'C:dir1:dir2:file'	->  'C:dir1:dir2:'     

// 030624
// Flaw1: also strips last  dir  if file and colon	 is missing:	'C:dir1:dir2'		->  'C:dir1:'     (one could check whether dir2 is a file or a dir, but this could be very slow...)
// Flaw2: also strips last  dir  if file		is missing:	'C:dir1:dir2:'	->  'C:dir1:'     
// Flaw3: not tested , will  probably not work with ksDIRSEP = "\\"
//	variable	nDirsAndDrives	= ItemsInList( sPathAndFileAndExt, ksDIRSEP )		// number of items separated by ksDIRSEP (=:)
//	return	RemoveListItem( nDirsAndDrives - 1, sPathAndFileAndExt, ksDIRSEP )	// remove file and extension

// 030624
// WM's  function is better : it handles  both  '\'  and  ':'  , it handles server names, it converts 	'C:dir1:dir2:' ->  'C:dir1:dir2:'  correctly , but still suffers from...
// Flaw1: also strips last  dir  if file and colon	 is missing:	'C:dir1:dir2'		->  'C:dir1:'     (one could check whether dir2 is a file or a dir, but this could be very slow...)
	return	FilePathOnly( sPathAndFileAndExt )

End	

//Function /S	StripPathAndExtension( sPathAndFileAndExt )
////  'C:dir1:dir2:file.ext'  ->  'file'
//// 060821 use Igors FileNameOnly()  which handles Mac  AND  Windows file naming syntax  
//	string 	sPathAndFileAndExt
//	return	FileNameOnly( sPathAndFileAndExt )
//End	

Function /S	UFCom_StripPathAndExtension( sPathAndFileAndExt )
//  Extracts  file name  from  Mac  or  Win style   path  e.g.   'C:dir1:dir2:file.ext'  or  'C:\dir1\dir2\file.ext'  ->  'file'		
	string 	sPathAndFileAndExt
// 060710 handles only MAC style
//	string 	sFileAndExt	= GetLastItemInList( sPathAndFileAndExt, ksDIRSEP )	// remove path (only Mac style) and..
	string 	sFileAndExt	= RemoveFilePath( sPathAndFileAndExt )			// remove path (Mac and Win style) and..
	return 	StringFromList( 0, sFileAndExt, "." )							// ..return remainder in front of the "." [could also use Igors FileNameOnly() ]
End	

Function /S	UFCom_GetLastItemInList( sList, sSep )
	string 	sList, sSep							
	return	StringFromList( ItemsInList( sList, sSep ) - 1, sList, sSep )			//  n-1 because indexing starts at 0
End


Function /S	UFCom_GetFileExtension( sFileNameExt )
	string 		sFileNameExt							
	return	UFCom_GetLastItemInList( sFileNameExt, "." )	// the last entry after the dot is the extension..
End

Function		UFCom_FileHasExtension( sFileNameExt, sExt )
	string 	sFileNameExt, sExt							
	sExt = SelectString( char2num( sExt[ 0, 0 ] ) == char2num( "." ) , sExt, sExt[ 1, Inf ] )	// possibly remove a leading dot
	if ( cmpstr( sExt,  UFCom_GetLastItemInList( sFileNameExt, "."  ) ) == 0 )					// the last entry after the dot is the extension..
		return	TRUE
	endif
	return	FALSE
End

//=========================================================================================================================================

//
// FileExtension returns ".ext" from something like "thepathandFile.ext"
//
Function/S FileExtension(fileNameAndExt)
	String fileNameAndExt

	Variable dotPos= searchBackwards(fileNameAndExt,".")
	if (dotPos < 0 )
		return ""	// no extension found
	endif
	return fileNameAndExt[dotPos,inf]
End

//
// FileNameOnly returns "theFile" from something like "HD:folder:subfolder:theFile.ext"
//
Function/S FileNameOnly(filePath)
	String filePath

	String fileNameAndExt= RemoveFilePath(filePath)
	Variable dotPos= searchBackwards(fileNameAndExt,".")
	if (dotPos < 0 )
		dotPos = strlen(fileNameAndExt)
	endif
	return fileNameAndExt[0,dotPos-1]
End

//
// RemoveFilePath returns "theFile.ext" from something like "HD:folder:subfolder:theFile.ext"
//
// Note: this has nothing to do with symbolic path names.
//
Function/S RemoveFilePath(filePath)
	String filePath
	Variable len= strlen(FilePathOnly(filePath))
	return filePath[len,inf]
End

//
// FilePathOnly returns "HD:folder:subfolder:" from something like "HD:folder:subfolder:theFile.ext"
//
//	If filePath is something like  "\\\\Server\\Volume", then "\\\\Server\\" is returned.
//
// Note: this has nothing to do with symbolic path names.
//
Function/S FilePathOnly(filePath)	// "HD:folder1:file.ext", or "C:\folder2\file.ext"
	String filePath					//  or "\\\\Server\\Volume:dir:file.ext" or "\\\\Server\\Volume:file.ext"

	Variable slashPos= searchBackwards(filePath,"\\")	// windows folder or Server-Volume separator
	Variable colonPos= searchBackwards(filePath,":")	// Mac or lone drive letter ("C:")
	Variable pathPos= max(slashPos,colonPos)	// Choose separator closest to the end, could be -1.
	filePath= filePath[0,pathPos]			// retains last separator, removes file.ext.
	return filePath							//  If no path separator, returns "", which RemoveFilePath() relies on.
End

////
//// FolderFromPath returns "subfolder" from something like "HD:folder:subfolder:theFile.ext"
////
//// Note: this has nothing to do with symbolic path names.
////
//Function/S FolderFromPath(filePath)
//	String filePath
//	
//	Variable slashPos= searchBackwards(filePath,"\\")	// windows folder or Server-Volume separator
//	Variable colonPos= searchBackwards(filePath,":")	// Mac or lone drive letter ("C:")
//	Variable pathPos= max(slashPos,colonPos)	// Choose separator closest to the end, could be -1.
//	filePath= filePath[0,pathPos-1]			// removes last separator and file.ext.
//	return FileNameOnly(filePath)				// treats folder name as file, returns folder name.
//End


// ParentFolder returns "HD:folder:" from something like "HD:folder:subfolder:theFile.ext"
//
//	If filePath is something like  "HD:theFile.ext" or "\\\\Server\\file.ext" (there is no parent folder), then "" is returned.
//	If filePath is something like  "\\\\Server\\Volume:theFile.ext", then "\\\\Server\\" is returned.

Function/S ParentFolder(filePath)	// "HD:folder1:file.ext", or "D:\folder2\file.ext"
	String filePath					//  or "\\\\Server\\Volume:dir:file.ext" or "\\\\Server\\Volume:file.ext"
	
	filePath= FilePathOnly(filePath)
	Variable len= strlen(filePath)
	if( len > 0 )
		if( (CmpStr(filePath[len-3],"\\") == 0) %& (CmpStr(filePath[len-2],"\\") == 0) )
			len -= 1
		endif
		filePath= FilePathOnly(filePath[0,len-2])	// remove trailing ":", "\\", or "\\\\" to force next level up
		len= strlen(filePath)
		if( len > 0 )
			filePath= FilePathOnly(filePath)
			Variable lastChar= strlen(filePath)-1
			if( (lastChar >= 0) %& (CmpStr(filePath[lastChar],":") != 0) %& (CmpStr(filePath[lastChar],"\\") != 0) )
				filePath= ""
			endif
		endif
	endif
	return filePath
End

Function searchBackwards(str,key)
	String str,key

	Variable pos= -1, lastPos
	do
		lastPos= pos
		pos= strsearch(str,key,lastPos+1)
	while (pos >= 0 )
	return lastPos
End

//// Returns the full path to the directory if it exists or "" if it does not exist.
//Function/S WMDirectoryExists(pathName)
//	String pathName
//
//	PathInfo $pathName
//	String pathValue= S_path // there is a path value
//	if( strlen(pathValue) )
//		String pn= UniqueName("WMpath",12,0)
//		NewPath/Q/O/Z $pn pathValue // checks the directory's actual existence
//		PathInfo $pn
//		pathValue= S_path // there still is a path value
//		KillPath/Z $pn
//	endif
//	return pathValue
//End
//
////	Returns 1 if the file exists, 0 if not. The file is NOT open upon return.
//Function WMFileExists(filePath)
//	String filePath	// not a symbolic path, something like: "MyDisk:subfolder:file.txt" or "C:\\MyFolder\\
//
//	if( strlen(filePath) == 0 )
//		return 0
//	endif
//	Variable fileNo
//	Open/R/Z fileNo filePath
//	if( V_Flag == 0 )	// file exists
//		Close fileNo
//		return 1
//	else
//		return 0
//	endif
//End


//	Deletes the file, if it exists. The file is presumed not open for read.
//	Returns 1 if the file existed, 0 if not.
Function WMDeleteFile(filePathWithExtension)
	String filePathWithExtension

	// DoWindow can delete only notebook files, so we open the file as a Notebook!
	String name= UniqueName("doomed",10,0)	// notebook name
	OpenNotebook/N=$name/V=0/Z filePathWithExtension	//  open invisibly
	Variable existed= V_Flag == 0 
	if( existed ) // file exists
		DoWindow/D/K $name
	endif
	return existed	// 1 if file existed, 0 if not.
End
