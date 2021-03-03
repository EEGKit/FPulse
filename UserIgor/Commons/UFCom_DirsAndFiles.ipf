// search 0608 for changes which must be transfered to any newer version
//  UFCom_DirsAndFiles.ipf 
// 
#pragma rtGlobals=1							// Use modern global access method.

//#pragma IndependentModule=UFCom_ 
#include "UFCom_Constants"
#include "UFCom_Errors"
#include "UFCom_ListProcessing"
#include "UFCom_DebugPrint" 		// UFCom_DebugVar
#include "UFCom_Timers" 			// UFCom_Delay

constant			UFCom_kSEARCH_EXISTING	= 0, UFCom_kSEARCH_FREE = 1

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	AUTOMATIC  FILE NAME  GENERATION

Function		UFCom_PossiblyCreatePath( sPath )
// builds the directory or subdirectory 'sPath' .  Builds a  nested directory including all needed intermediary directories in 1 call to this function. First param must be drive.
// Example : PossiblyCreatePath( "C:kiki:koko" )  first builds 'C:kiki'  then C:kiki:koko'  .  The symbolic path is stored in 'SymbPath1'  which could be but is currently not used.

// todo: extra parameter sSymbolicPath  ( only required if the symbolic path is to be used )
	string 	sPath
	string 	sPathCopy	, sMsg
	sPath	= UFCom_Path2Mac( sPath )		// 2006-1114
	variable	r, n, nDirLevel	= ItemsInList( sPath, ":" ) 
	variable	nRemove	= 1
	for ( nRemove = nDirLevel - 1; nRemove >= 0; nRemove -= 1 )				// start at the drive and then add 1 dir at a time, ...
		sPathCopy		= sPath										// .. assign it an (unused) symbolic path. 
		sPathCopy		= UFCom_RemoveLastListItems( nRemove, sPathCopy, ":" )	// ..This  CREATES the directory on the disk
		NewPath /C /O /Q /Z SymbPath1,  sPathCopy	
		if ( V_Flag == 0 )
			// printf "\tUFCom_PossiblyCreatePath( '%s' )  Removing:%2d of %2d  \t'%s' exists or has been created (V_Flag:%d) \r", sPath, nRemove, nDirLevel, sPathCopy, v_Flag
		else
			sprintf sMsg, "While attempting to create path '%s'  \t'%s' \tcould not be created. [UFCom_PossiblyCreatePath()]", sPath, sPathCopy
			UFCom_Alert( UFCom_kERR_SEVERE, sMsg )
			return	UFCom_kNOTFOUND	// 2006-08
		endif
	endfor
	// printf "\tUFCom_PossiblyCreatePath( '%s' )  \t'%s' exists or has been created (V_Flag:%d) \r", sPath, sPathCopy, v_Flag
	return	UFCom_kOK		// 2006-08
End

Function		UFCom_SearchDir( sPath ) 
// Look if  'sPath'   (including drive)  is an existing directory.  Return  TRUE  or  FALSE.
	string  	sPath
	variable	bFound 	= 0
	GetFileFolderInfo  /Z	/Q	sPath
	if (  ! V_Flag  &&  V_isFolder  &&  ! V_isReadOnly )				//  V_isFolder : directory  found
		bFound	= UFCom_TRUE
		//printf "\t\t\tSearchDir( %s ) does %s exist. \r", sPath, SelectString( bFound, "Not" , "" )
	endif
	return	bFound
End

Function  		UFCom_DirectoryExists( sPath )
	string 	sPath
	GetFileFolderInfo /Q	/Z	sPath
	variable	bDirExists	= (  V_Flag == 0   &&   V_IsFolder == 1 )
	// print "\tFPDirectoryExists", sPath, V_Flag, V_IsFolder, "returning: ", bDirExists
	return	bDirExists
End


Function  		UFCom_FileExists( sPathFile )
	string 	sPathFile
	variable	nRefNum
	Open	/Z=1 /R 				nRefNum  as sPathFile	// without symbolic path.../Z = 1:	does nothing if file is missing
	if  ( V_flag )			// could not open
		// printf "\t\tFileExists()  returns UFCom_FALSE as %s does NOT exist \r", sPathFile 
		return UFCom_FALSE
	else					// could open and did it so we must close it again...
		// printf "\t\tFileExists()  returns  UFCom_TRUE  as %s does exist  \r", sPathFile 
		Close nRefNum
		return UFCom_TRUE
	endif
End

 Function  		UFCom_FileExistsIgorPath( sPathFile )
	string 	sPathFile
	variable	nRefNum
	Open	/Z=1 /R 	/P=Igor		nRefNum  as sPathFile	// with symbolic Igor path.../Z = 1:	does nothing if file is missing
	if  ( V_flag )			// could not open
		// printf "\t\tFileExistsIgorPath()  returns UFCom_FALSE as %s does NOT exist \r", sPathFile 
		return UFCom_FALSE
	else					// could open and did it so we must close it again...
		// printf "\t\tFileExistsIgorPath()  returns  UFCom_TRUE  as %s does exist  \r", sPathFile 
		Close nRefNum
		return UFCom_TRUE
	endif
End


Function		UFCom_PathAndFileExists( sPath, sFile )
// the symbolic path cannot be directly passed but must be passed as a string  and  then catenated with the filename
	string 	sPath, sFile
	variable	nRefNum
	Open	/Z=1 /R 	nRefNum  as sPath + sFile	//   /Z = 1:	does nothing if file is missing
	if  ( V_flag )								// could not open
		// printf "\t\tPathAndFileExists()  returns UFCom_FALSE as %s does NOT exist \r", sPath + sFile 
		return UFCom_FALSE
	else										// could open and did it so we must close it again...
		// printf "\t\tPathAndFileExists()  returns  UFCom_TRUE  as %s does exist  \r", sPath + sFile 
		Close nRefNum
		return UFCom_TRUE
	endif
End

Function   /S	UFCom_ExtractTrailingCharacters( sPathAndFile, cnt )
// extracts the last 'cnt'  characters from a file name ignoring the extension 
	string 	sPathAndFile
	variable	cnt
	variable	nPos	= strsearch( sPathAndFile,  "." ,  0 )
	if ( nPos == UFCom_kNOTFOUND )						// if file name contains no dot, no extension: return last 'cnt' characters
		nPos = strlen( sPathAndFile )		
	endif										// if file name contains dot: return last 'cnt' characters before dot
	// printf "\tExtractTrailingCharacters( %s, cnt:%d ) : extracts '%s'   \tat pos:%d \r", sPathAndFile, cnt, sPathAndFile[ nPos-2, nPos-1 ] , pos
	return	sPathAndFile[ nPos-cnt, nPos-1 ]			
End


Function	/S	UFCom_ListOfMatchingDirs( sSrcDir, sMatch, bFullPath )
// Allows directory selection using wildcards. Returns list of matching dirs. Usage : UFCom_ListOfMatchingDirs(  "C:foo2:foo1"  ,  "foo*.i*",  0  )
	string  	sSrcDir, sMatch
	variable	bFullPath 
	string  	lstDirsInDir, lstMatched = ""

	NewPath  /Z/O/Q	SymbDir , sSrcDir 
	if ( V_Flag == 0 )										// make sure the folder exists
		lstDirsInDir	 = IndexedDir( SymbDir, -1, bFullPath )
		// printf "\tUFCom_ListOfMatchingDirs()\t( '%s' \t'%s'  \tuip:%d ) ->\t%s \r",  sSrcDir, sMatch,  lstDirsInDir[0, 300]
		lstMatched = ListMatch( lstDirsInDir, sMatch )
		// printf "\tUFCom_ListOfMatchingDirs()\tMatched\t( '%s' \t'%s'   \tuip:%d ) ->\t%s \r",  sSrcDir, sMatch,  lstMatched[0, 300]
		KillPath 	/Z	SymbDir
	endif
	return	lstMatched
End

Function	/S	UFCom_ListOfMatchingFiles( sSrcDir, sMatch, bUseIgorPath )
// Allows file selection using wildcards. Returns list of matching files. Usage : UFCom_ListOfMatchingFiles(  "C:foo2:foo1"  ,  "foo*.i*",  0  )
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

Function	/S 	UFCom_Path2Win( sMacPath )
// Convert Mac path to Windows path convention
	string  	sMacPath									// complete path including drive letter e.g. 'C:UserIgor:FPuls'
	return	ParseFilePath( 5, sMacPath, "\\", 0, 0 ) 			// return Win-style path e.g. 'C:\\UserIgor\\FPuls\\' 
End

Function	/S 	UFCom_Path2Mac( sWinPath )
// Convert Mac path to Windows path convention
	string  	sWinPath									// complete path including drive letter e.g. 'C:\\UserIgor\\FPuls\\' 
	return	ParseFilePath( 5, sWinPath, ":", 0, 0 ) 				// return Mac-style path e.g. 'C:UserIgor:FPuls:'
End

///////////////////////////////////////////////////////////////////////////////////////////////
// 2006-08-11   NEW.............. AUTOMATIC  NAMING  MODES

//constant			UFCom_kANM_ONELETTER = 0,  UFCom_kANM_DIGITLETTER = 1,  UFCom_kANM_TWOLETTER = 2				// automatic naming of  files   !!!elsewhere also

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
	if ( NamingMode == UFCom_kANM_ONELETTER )					// computes index of 1 letter, 	e.g.	a=0 , b=1, ...z=25
		idx	= WhichListItem( LowerStr( sLetters ), klstONELETTER )		// could alternatively be computed using char2num()  and num2char() 
	elseif ( NamingMode == UFCom_kANM_DIGITLETTER )				// computes index of character, 	e.g.  0, 1...8, 9, a=10, b=11 .... z=36
		idx	= WhichListItem( LowerStr( sLetters ), klstDIGITLETTER )		// could alternatively be computed using char2num()  and num2char() 
	elseif ( NamingMode == UFCom_kANM_TWOLETTER )				// computes index of 2-letter-combination, e.g.  AA=0 , AB=1, ...ZZ=575
		//idx	= 26 * ( char2num( sLetters[ 0, 0 ] ) - char2num( "A" ) )    +     char2num( sLetters[ 1, 1 ] ) - char2num( "A" ) 
		idx	= 26 * ( char2num( UpperStr( sLetters[ 0, 0 ] ) ) - char2num( "A" ) ) + char2num( UpperStr( sLetters[ 1, 1 ] ) ) - char2num( "A" ) // file names must be case-insensitive
	endif
	// printf "\tLettersToIdx(  '%s', mode:%d )  \t->\t%d\t \r", sLetters, NamingMode, idx
	return idx
End

static Function  /S	IdxToLetters( nIndex, NamingMode )	
// convert  index  into a one character   or  into a  two-letter-combination and return it
	variable	nIndex
	variable	NamingMode
	string  	sLetters	= ""
	if ( NamingMode == UFCom_kANM_ONELETTER )							// convert  index (allowed range 0..25) into 1 letter
		sLetters	= StringFromList( nIndex, klstONELETTER ) 
	elseif ( NamingMode == UFCom_kANM_DIGITLETTER )						// convert  index (allowed range 0..35) into 1 character (digit or letter) and return it
		sLetters	= StringFromList( nIndex, klstDIGITLETTER ) 
	elseif ( NamingMode == UFCom_kANM_TWOLETTER )						// convert  index (allowed range 0..26x26-1) into a two letter combination and return it
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
	if ( nPos == UFCom_kNOTFOUND )										// if file name contains no dot, no extension: we use the  last 2 characters
		nPos		= strlen( sPathAndFileOld )		
	endif														// if file name contains a dot: we use the last 2 characters before dot
	variable	nCharacters	= str2num( StringFromList( NamingMode, lstNCHARACTERS ) )
	sPathAndFile[ nPos-nCharacters, nPos-1 ]  = IdxToLetters( nIndex, NamingMode )	// replace the 2 characters found by the letters given by the new index
	if ( UFCom_DebugVar( "com", "Filename" ) )
		 printf "\t\tBuildNextPathFile   '%s'  , nIndex:%d,  mode:%d   -> '%s' \r" , sPathAndFileOld, nIndex, NamingMode, sPathAndFile			
	endif
	return	sPathAndFile			
End


// should replace FPuls /FEval  GetNextFileNm()
Function   /S	UFCom_GetNextFileNm_( sPathAndFile, bSearchNextFree, step, NamingMode )
// gets the next  EXISTING  file starting at  'sPathAndFile'.  Search direction is given by  'step'.
// old version, for a better code see    GetNextFileNm___()    below. 
// Possible flaws in this version : Processing might be confused  1. mixing naming modes in 1 directory and  2. by mixing small and capital letter file names (user may have renamed the files..) 
	string 	sPathAndFile			// start with this file
	variable	bSearchNextFree		// UFCom_TRUE: search unused file, UFCom_FALSE: search existing file
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
			UFCom_Alert( UFCom_kERR_LESS_IMPORTANT,  errbf )
			return	sPathAndFile						// return unchanged file
		endif
		sNextUsedFile = BuildNextPathFile( sPathAndFile, nIndex, NamingMode ) 
	while ( UFCom_FileExists( sNextUsedFile ) == bSearchNextFree ) 		// UFCom_TRUE: search unused file, UFCom_FALSE: search existing file

	// printf "\t\tUFCom_GetNextFileNm_  '%s'  searches next '%s' file   going '%s', step:%d,  mode:'%s' )   -> %s   \r", sPathAndFile,  SelectString( bSearchNextFree==UFCom_kSEARCH_FREE, "used ", "free"),  SelectString( step==-1, "up    ", "down"), step, StringFromList( NamingMode, lstMODES ), sNextUsedFile
	return	sNextUsedFile 
End


Function   /S	UFCom_GetNextFileNm__( sDir, sFileBase, sExt, NamingMode )
// gets the next  free/unused  file  above the highest used file in directory 'sDir'  starting with  'sFileBase' and having the appropriate number (or none) of postfix characters.  
// As we are processing files the processing must be and is case-insensitive, although (for historical reasons)  the appended postfixes are small or capital letters..
	string 	sDir
	string 	sFileBase					// use this file base, look for appended letter(s)   and append letters
	string  	sExt
	variable	NamingMode				// 1 letter, 1 DigitLetter  or  2 letters
	string 	sNextUsedFile 
	variable	nCharacters	= str2num( StringFromList( NamingMode, lstNCHARACTERS ) )	// we must only process files which have a matching number of 'NamingMode' characters (=1 or 2)...
	variable	nMatchLen	= strlen( sFileBase + sExt ) + nCharacters					// ...or the code gets confused e.g. when there is TSTa, TSTb and we try to continue with  TSTAA...
	variable	nIndex, nMaxIndex
	string  	sMatch	= sFileBase + "*"		
	string  	lstOfFiles	= UFCom_ListOfMatchingFiles( sDir, sMatch, UFCom_FALSE )
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
			UFCom_Alert1( UFCom_kERR_IMPORTANT, "You are now using the highest possible auto-assigned index.\rBefore the next time you  must change the base name or data will be lost.\r\r" + sHighestFile )
		elseif ( nIndex	>= nMaxIndex )
			UFCom_Alert1( UFCom_kERR_FATAL, "You are now overwriting the highest possible auto-assigned index.\r\r" + sHighestFile )
		endif
		sNextUsedFile 	= BuildNextPathFile( sHighestFile, nIndex, NamingMode ) 
	endif
	if ( UFCom_DebugVar( "com", "Filename" ) )
		 printf "\t\tGetNextFileNm__  '%s'  '%s' has %d files.  Mode:'%s'     -> %s   \r", sDir, sFileBase, nFiles,  StringFromList( NamingMode, lstMODES ), sNextUsedFile
	endif
	return	sNextUsedFile 
End



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// 2006-0911    OBSOLETE......... Functions  used  when  reading  CFS  files  ( NOT  relying on  globals, which are valid and used only during acquisition)

		Function   /S	UFCom_GetNextFileNm( sPathAndFile, bSearchNextFree, step, NamingMode )
		// gets the next  EXISTING  file starting at  'sPathAndFile'.  Search direction is given by  'step'.
			string 	sPathAndFile			// start with this file
			variable	bSearchNextFree		// UFCom_TRUE: search unused file, UFCom_FALSE: search existing file
			variable	step					// search going forward or backward
			variable	NamingMode			// DigitLetter for evaluation results  or  2 letters for Cfs files 
			string 		errbf, sNextUsedFile 
			variable	nIndex
			if ( strlen( sPathAndFile ) == 0 )
				UFCom_InternalError( "Cannot find another file before / after unspecified file '" + sPathAndFile + "' . " )
				return	""
			endif
		
			// start at nIndex given by 'sPathAndFile'  and  (depending on 'step')  increment or decrement index skipping all non-existing files, return index of  first used file found
		
			if ( NamingMode == UFCom_kANM_TWOLETTER )
				nIndex = UFCom_TwoLettersToIdx( UFCom_ExtractTrailingCharacters( sPathAndFile, 2 ) )
				do
					nIndex	+= step
					if ( nIndex == -1  ||  nIndex == UFCom_kANM_MAX_2LETTERS )
						//? very peculiar behaviour: the following warning is sometimes output much too late (one cyle later, and then twice.......)
						sprintf errbf, "Cannot find another file with matching base name and cell number %s '%s' . ", SelectString( step>0, "before", "after" ), sPathAndFile
						UFCom_Alert( UFCom_kERR_LESS_IMPORTANT,  errbf )
						return	sPathAndFile						// return unchanged file
					endif
					sNextUsedFile = BuildNextPathFileTwoLetters( sPathAndFile, nIndex ) 
				while ( UFCom_FileExists( sNextUsedFile ) == bSearchNextFree ) 		// UFCom_TRUE: search unused file, UFCom_FALSE: search existing file
				//while ( !FileExists( sNextUsedFile )   ) 
			endif
		
			if ( NamingMode == UFCom_kANM_DIGITLETTER )
				nIndex = UFCom_DigitLetterToIdx( UFCom_ExtractTrailingCharacters( sPathAndFile, 1 ) )
				do
					nIndex	+= step
					if ( nIndex == -1  ||  nIndex == UFCom_kANM_MAX_2LETTERS )
						//? very peculiar behaviour: the following warning is sometimes output much too late (one cyle later, and then twice.......)
						sprintf errbf, "Cannot find another file with matching base name and cell number %s '%s' . ", SelectString( step>0, "before", "after" ), sPathAndFile
						UFCom_Alert( UFCom_kERR_LESS_IMPORTANT,  errbf )
						return	sPathAndFile						// return unchanged file
					endif
					sNextUsedFile = BuildNextPathFileDigitLetter( sPathAndFile, nIndex ) 
				while ( UFCom_FileExists( sNextUsedFile ) == bSearchNextFree ) 		// UFCom_TRUE: search unused file, UFCom_FALSE: search existing file
				//while ( !FileExists( sNextUsedFile )   ) 
			endif
		
			// printf "\t\tGetNextFileNm  '%s'  searches next '%s' file   going '%s' step:%d  '%s'     -> %s   \r", sPathAndFile,  SelectString( bSearchNextFree==UFCom_kSEARCH_FREE, "used ", "free"),  SelectString( step==-1, "up    ", "down"), step, SelectString( NamingMode==UFCom_kANM_DIGITLETTER, "TwoLetter", "Digit or Letter" ), sNextUsedFile
			return	sNextUsedFile 
		End
		
		///////////////////////////////////////////////////////////////////////////////////////////////
		// 2006-09-11    OBSOLETE......... NAMING MODE for CFS files  		:	TWO LETTERS		(2 characters)
		
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
			if ( nPos == UFCom_kNOTFOUND )								// if file name contains no dot, no extension: we use the  last 2 characters
				nPos		= strlen( sPathAndFile )		
			endif												// if file name contains a dot: we use the last 2 characters before dot
			sPathAndFile[ nPos - 2, nPos - 1 ]  = UFCom_IdxToTwoLetters( nIndex )	// replace the 2 characters found by the letters given by the new index
			// print "\tBuildNextPathFileTwoLetters()" , nIndex, sPathAndFile			
			return	sPathAndFile			
		End
		
		
		
		///////////////////////////////////////////////////////////////////////////////////////////////
		// 2006-09-11    OBSOLETE......... NAMING  MODE  for  RESULT (=AVG,TBL)   FILES  :  DIGIT/LETTER 	( 1 character)
		
		static  Function   /S	BuildNextPathFileDigitLetter( sPathAndFile, nIndex )
		// builds the path and file of the next file. Starts with  sPathAndFile  and replaces the last character  by  a  new characters given by nIndex
			string 	sPathAndFile
			variable	nIndex
			variable	nPos	= strsearch( sPathAndFile,  "." ,  0 )
			if ( nPos == UFCom_kNOTFOUND )								// if file name contains no dot, no extension: we use the  last  character
				nPos		= strlen( sPathAndFile )		
			endif												// if file name contains a dot: we use the last character before dot
			sPathAndFile[ nPos - 1, nPos - 1 ]  = UFCom_IdxToDigitLetter( nIndex )		// replace the 1 character found by the new character given by the new index
			// print "\tBuildNextPathFileDigitLetters()" , nIndex, sPathAndFile			
			return	sPathAndFile			
		End

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// 2007-1203  NOT obsolete,  DebugPrint  and  LACharger  use this code  for  building  multiple similar panel lines		
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


//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function	/S	UFCom_GermanDate2Iso( sDate )
// converts  e.g.   15.3.1952   ->  1952-03-15
	string  	sDate
	variable	day, month, year
	sscanf	sDate, "%d.%d.%d", day, month, year
	sprintf 	sDate, "%4d-%02d-%02d",  year, month, day
	return	sDate
End
	

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


//Function  /S  	UFCom_GetFileNameFromDialog(  sSymPath, sFileNameOrEmpty )
//// Displays FileOpen Dialog  if parameter  'sFileNameOrEmpty'  is empty string ...
//// Changes the symbolic path  'sSymPath'
//// Returns selected  valid  filename or empty string  if user clicked  CANCEL
//	string 	 sSymPath, sFileNameOrEmpty					
//	variable	nRefNum
//
//	if ( strlen( sFileNameOrEmpty ) == 0 )								// user must choose file: present File Open Dialog but do not open
//
//		Open /R /D /P = $sSymPath  nRefNum as sFileNameOrEmpty
//		PathInfo /S $sSymPath;  printf "\t\t\tGetFileNameFromDialog( with dialog b): Receives FilePath:'%s' , Symbolic path '%s' does %s exist. -> returns '%s'  \r", sFileNameOrEmpty , S_path, SelectString( v_Flag,  "NOT", "" ), s_fileName
//
//		if ( strlen( S_fileName ) )									// used selected a file (did not click Cancel)
//			string 	sNewPath = S_fileName
//			sNewPath		= UFCom_StripFileAndExtension( sNewPath )	// only drive and directory is left...
//			NewPath /O /Q	$sSymPath,  sNewPath					//...as a symbolic path can never include the file name
//			// PathInfo /S $sSymPath;  printf "\t\t\tGetFileNameFromDialog() \tAttempted to change Symb path to '%s'   ->   New Symbolic (script) path is '%s'  (does %s exist). \r", sNewPath, S_path, SelectString( v_Flag,  "NOT", "" )
//		endif
//		return S_fileName								 		// can also be empty if user clicked Cancel
//	else
//		// printf "\t\t\tGetFileNameFromDialog(without dialog):  receives and returns  FilePath:'%s'  \r", sFileNameOrEmpty 	
//		return sFileNameOrEmpty
//	endif	
//End


Function  /S  	UFCom_GetFileNameFromDialog(  sSymPath, sFileNameOrEmpty )
// Displays FileOpen Dialog  if parameter  'sFileNameOrEmpty'  is empty string ...
// Changes the symbolic path  'sSymPath'
// Returns selected  valid  filename or empty string  if user clicked  CANCEL
	string 	 sSymPath, sFileNameOrEmpty					
	variable	nRefNum
	string  	sNewPath	= "C:UserIgor"		// C: or C:UserIgor are both bad.... This is offered to user when there is neither a path to file (par 2="" which is OK)   nor a symbolic path (which is not OK but happens e.g. when a floppy was used the last time but  is missing now)

	if ( strlen( sFileNameOrEmpty ) == 0 )								// user must choose file: present File Open Dialog but do not open
		PathInfo /S $sSymPath
		 printf "\t\t\tGetFileNameFromDialog( with dialog a): Receives FilePath:'%s' , Symbolic path '%s' does %s exist. '  \r", sFileNameOrEmpty , S_path, SelectString( v_Flag,  "NOT", "" )

		if ( v_Flag == 0 )											// the symbolic path is (also) missing...
			NewPath /O /Q	$sSymPath,  sNewPath					//...so  we use a fixed drive C: (which MUST be there = BAD ASSUMPTION)
		endif

		//??Open /R /D /P = $sSymPath  nRefNum as sFileNameOrEmpty
		Open /R /D /P = $sSymPath  nRefNum
		PathInfo /S $sSymPath;  printf "\t\t\tGetFileNameFromDialog( with dialog b): Receives FilePath:'%s' , Symbolic path '%s' does %s exist. -> returns '%s'  \r", sFileNameOrEmpty , S_path, SelectString( v_Flag,  "NOT", "" ), s_fileName

		if ( strlen( S_fileName ) )									// used selected a file (did not click Cancel)
			sNewPath = S_fileName
			sNewPath	= UFCom_StripFileAndExtension( sNewPath )		// only drive and directory is left...
			NewPath /O /Q	$sSymPath,  sNewPath					//...as a symbolic path can never include the file name
			// PathInfo /S $sSymPath;  printf "\t\t\tGetFileNameFromDialog() \tAttempted to change Symb path to '%s'   ->   New Symbolic (script) path is '%s'  (does %s exist). \r", sNewPath, S_path, SelectString( v_Flag,  "NOT", "" )
		endif
		return S_fileName										// can also be empty if user clicked Cancel
	else
		// printf "\t\t\tGetFileNameFromDialog(without dialog):  receives and returns  FilePath:'%s'  \r", sFileNameOrEmpty 	
		return sFileNameOrEmpty
	endif	
End



Function  /S  	UFCom_GetFileNameFromDialog_2(  sSymPath, sFileNameOrEmpty )
// Displays FileOpen Dialog  if parameter  'sFileNameOrEmpty'  is empty string ...
// Changes the symbolic path  'sSymPath'.   Does not rely on  'C:UserIgor:'  or  'C:userIgor:'  but uses the 'Documents and Settings' path of the current user (which is guranteed to exist and to have write permission) as a start for browsing if  'sFileNameOrEmpty'  is empty string ...
// Returns selected  valid  filename or empty string  if user clicked  CANCEL
	string 	 sSymPath, sFileNameOrEmpty					
	variable	nRefNum
	string  	sNewPath	= SpecialDirPath( "Documents", 0, 0, 0 )			// This is offered to user when there is neither a path to file (par 2="" which is OK)   nor a symbolic path (which is not OK but happens e.g. when a floppy was used the last time but  is missing now)
	if ( strlen( sNewPath ) <= 0 )
		printf "\t\t\tGetFileNameFromDialog_2( with dialog a): Receives FilePath:'%s'  .    Error  getting  SpecialDirPath( 'Documents' )  \r", sFileNameOrEmpty 
		return ""
	endif

	if ( strlen( sFileNameOrEmpty ) == 0 )								// user must choose file: present File Open Dialog but do not open
		PathInfo /S $sSymPath
		 printf "\t\t\tGetFileNameFromDialog_2( with dialog a): Receives FilePath:'%s' , Symbolic path '%s' does %s exist. '  \r", sFileNameOrEmpty , S_path, SelectString( v_Flag,  "NOT", "" )

		if ( v_Flag == 0 )											// the symbolic path is (also) missing...
			NewPath /O /Q	$sSymPath,  sNewPath					//...so  we use a fixed drive C: (which MUST be there = BAD ASSUMPTION)
		endif

		//??Open /R /D /P = $sSymPath  nRefNum as sFileNameOrEmpty
		Open /R /D /P = $sSymPath  nRefNum
		PathInfo /S $sSymPath;  printf "\t\t\tGetFileNameFromDialog_2( with dialog b): Receives FilePath:'%s' , Symbolic path '%s' does %s exist. -> returns '%s'  \r", sFileNameOrEmpty , S_path, SelectString( v_Flag,  "NOT", "" ), s_fileName

		if ( strlen( S_fileName ) )									// used selected a file (did not click Cancel)
			sNewPath = S_fileName
			sNewPath	= UFCom_StripFileAndExtension( sNewPath )		// only drive and directory is left...
			NewPath /O /Q	$sSymPath,  sNewPath					//...as a symbolic path can never include the file name
			// PathInfo /S $sSymPath;  printf "\t\t\tGetFileNameFromDialog() \tAttempted to change Symb path to '%s'   ->   New Symbolic (script) path is '%s'  (does %s exist). \r", sNewPath, S_path, SelectString( v_Flag,  "NOT", "" )
		endif
		return S_fileName										// can also be empty if user clicked Cancel
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
		sNewPath		  = UFCom_StripFileAndExtension( sNewPath )		// only drive and directory is left...
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
				UFCom_Alert1( UFCom_kERR_IMPORTANT, sErrTxt )
				DoAlert 0, sErrTxt
				Beep
				NewPath /O /Q	$sSymbPath,  sInitialPath					//  a symbolic path can never include the file name
			endif
		endif
	while ( nCode != 0  &&  strlen( sFileNameOrEmpty ) > 0  )		// escape from the loop either by staying in the initial directory  or  by leaving the file dialog with 'Cancel'

	return sFileNameOrEmpty										// can also be empty if user clicked Cancel
End

//=================================================================================================================================
// Open multiple files: requires Igor 6
// Note: For some unknown reason the file order is only as expected if 1. they are added by CTRL-Clicking in the right order but starting with the second file (the first file  must be clicked last)  OR  by  clicking the LAST file and the shift-clicking the first file.
Function	/S 	UFCom_OpenMultiFileDialog( sDirectory, llstFileFilters )
	string  	&sDirectory	
	string  	llstFileFilters
	variable	refNum
	string 	sPath = "",  sFile = "",  lstOutputPaths = "",  lstFiles = ""
	string 	sMessage	  = "Select one or more files"

	NewPath /O /Q	FBrainDataPath,  sDirectory					//...so  we use a fixed drive C: (which MUST be there = BAD ASSUMPTION)

	Open /D /R /MULT=1 /F=llstFileFilters  /M=sMessage  /P=FBrainDataPath   refNum
	lstOutputPaths = S_fileName
	
	if ( strlen( lstOutputPaths ) == 0 )
		print "Cancelled"
	else
		variable i, numFilesSelected = ItemsInList( lstOutputPaths, "\r" )
		for ( i = 0; i < numFilesSelected;  i+= 1 )
			sPath	 =  StringFromList( i, lstOutputPaths, "\r" )
			sFile		 =  UFCom_LastListItems( 1, sPath, ":" )
			lstFiles	+= sFile + ";"
			//printf "\t\tDoOpenMultiFileDialog  \t%d / %d\t%s\t%s\t     %s \r", i, numFilesSelected, UFCom_pd(sPath,36),  UFCom_pd(sFile,16),  lstFiles[0,200]	
		endfor
		sDirectory	= RemoveEnding( UFCom_RemoveLastListItems( 1, sPath, ":" ) , ":" )
	endif
	//lstOutputPaths	= ReplaceString( "\r", lstOutputPaths, ";" )		// will not work on MAC because ';' is allowed in path name in MAC  but  for FBrain  we use the customary separator ';'
	return	lstFiles		// Will be empty if user canceled
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

// 2003-0624
// Flaw1: also strips last  dir  if file and colon	 is missing:	'C:dir1:dir2'		->  'C:dir1:'     (one could check whether dir2 is a file or a dir, but this could be very slow...)
// Flaw2: also strips last  dir  if file		is missing:	'C:dir1:dir2:'	->  'C:dir1:'     
// Flaw3: not tested , will  probably not work with ":" = "\\"
//	variable	nDirsAndDrives	= ItemsInList( sPathAndFileAndExt, ":" )		// number of items separated by ":" (=:)
//	return	RemoveListItem( nDirsAndDrives - 1, sPathAndFileAndExt, ":" )	// remove file and extension

// 2003-0624
// WM's  function is better : it handles  both  '\'  and  ':'  , it handles server names, it converts 	'C:dir1:dir2:' ->  'C:dir1:dir2:'  correctly , but still suffers from...
// Flaw1: also strips last  dir  if file and colon	 is missing:	'C:dir1:dir2'		->  'C:dir1:'     (one could check whether dir2 is a file or a dir, but this could be very slow...)
	return	UFCom_FilePathOnly( sPathAndFileAndExt )

End	

//Function /S	StripPathAndExtension( sPathAndFileAndExt )
////  'C:dir1:dir2:file.ext'  ->  'file'
//// 2006-0821 use Igors FileNameOnly()  which handles Mac  AND  Windows file naming syntax  
//	string 	sPathAndFileAndExt
//	return	FileNameOnly( sPathAndFileAndExt )
//End	

Function /S	UFCom_StripPathAndExtension( sPathAndFileAndExt )
//  Extracts  file name  from  Mac  or  Win style   path  e.g.   'C:dir1:dir2:file.ext'  or  'C:\dir1\dir2\file.ext'  ->  'file'		
	string 	sPathAndFileAndExt
// 2006-0710 handles only MAC style
//	string 	sFileAndExt	= GetLastItemInList( sPathAndFileAndExt, ":" )	// remove path (only Mac style) and..
	string 	sFileAndExt	= UFCom_RemoveFilePath( sPathAndFileAndExt )			// remove path (Mac and Win style) and..
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
		return	UFCom_TRUE
	endif
	return	UFCom_FALSE
End

//=========================================================================================================================================

//
// FileExtension returns ".ext" from something like "thepathandFile.ext"
//
Function/S 	UFCom_FileExtension(fileNameAndExt)
	String fileNameAndExt

	Variable dotPos= UFCom_SearchBackwards(fileNameAndExt,".")
	if (dotPos < 0 )
		return ""	// no extension found
	endif
	return fileNameAndExt[dotPos,inf]
End

//
// FileNameOnly returns "theFile" from something like "HD:folder:subfolder:theFile.ext"
//
Function/S 	UFCom_FileNameOnly(filePath)
	String filePath

	String fileNameAndExt	= UFCom_RemoveFilePath(filePath)
	Variable dotPos= UFCom_SearchBackwards(fileNameAndExt,".")
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
Function	/S 	UFCom_RemoveFilePath( filePath )
	string 	filePath
	variable 	len	= strlen( UFCom_FilePathOnly( filePath ))
	return 	filePath[len,inf]
End

//
// FilePathOnly returns "HD:folder:subfolder:" from something like "HD:folder:subfolder:theFile.ext"
//
//	If filePath is something like  "\\\\Server\\Volume", then "\\\\Server\\" is returned.
//
// Note: this has nothing to do with symbolic path names.
//
Function	/S 	UFCom_FilePathOnly( filePath )		// "HD:folder1:file.ext", or "C:\folder2\file.ext"
	String filePath							//  or "\\\\Server\\Volume:dir:file.ext" or "\\\\Server\\Volume:file.ext"

	Variable slashPos= UFCom_SearchBackwards(filePath,"\\")	// windows folder or Server-Volume separator
	Variable colonPos= UFCom_SearchBackwards(filePath,":")	// Mac or lone drive letter ("C:")
	Variable pathPos= max(slashPos,colonPos)		// Choose separator closest to the end, could be -1.
	filePath= filePath[0,pathPos]				// retains last separator, removes file.ext.
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
//	Variable pathPos= max(slashPos,colonPos)			// Choose separator closest to the end, could be -1.
//	filePath= filePath[0,pathPos-1]					// removes last separator and file.ext.
//	return FileNameOnly(filePath)					// treats folder name as file, returns folder name.
//End


// ParentFolder returns "HD:folder:" from something like "HD:folder:subfolder:theFile.ext"
//
//	If filePath is something like  "HD:theFile.ext" or "\\\\Server\\file.ext" (there is no parent folder), then "" is returned.
//	If filePath is something like  "\\\\Server\\Volume:theFile.ext", then "\\\\Server\\" is returned.

Function	/S 	UFCom_ParentFolder( filePath )	// "HD:folder1:file.ext", or "D:\folder2\file.ext"
	string  	filePath					//  or "\\\\Server\\Volume:dir:file.ext" or "\\\\Server\\Volume:file.ext"
	
	filePath= UFCom_FilePathOnly(filePath)
	Variable len= strlen(filePath)
	if( len > 0 )
		if( (CmpStr(filePath[len-3],"\\") == 0) %& (CmpStr(filePath[len-2],"\\") == 0) )
			len -= 1
		endif
		filePath=UFCom_FilePathOnly(filePath[0,len-2])	// remove trailing ":", "\\", or "\\\\" to force next level up
		len= strlen(filePath)
		if( len > 0 )
			filePath= UFCom_FilePathOnly(filePath)
			Variable lastChar= strlen(filePath)-1
			if( (lastChar >= 0) %& (CmpStr(filePath[lastChar],":") != 0) %& (CmpStr(filePath[lastChar],"\\") != 0) )
				filePath= ""
			endif
		endif
	endif
	return filePath
End

Function 		UFCom_SearchBackwards( str, key )
	string  	str, key

	variable	pos= -1, lastPos
	do
		lastPos= pos
		pos= strsearch(str,key,lastPos+1)
	while ( pos >= 0 )
	return	lastPos
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


// Use  DeleteFile  instead
////	Deletes the file, if it exists. The file is presumed not open for read.
////	Returns 1 if the file existed, 0 if not.
//Function 	UFCom_WMDeleteFile(filePathWithExtension)
//	String filePathWithExtension
//
//	// DoWindow can delete only notebook files, so we open the file as a Notebook!
//	String name= UniqueName("doomed",10,0)	// notebook name
//	OpenNotebook/N=$name/V=0/Z filePathWithExtension	//  open invisibly
//	Variable existed= V_Flag == 0 
//	if( existed ) // file exists
//		DoWindow/D/K $name
//	endif
//	return existed	// 1 if file existed, 0 if not.
//End


Function	/S	UFCom_AllUsersDirPath()
// Returns  path to subdirecory 'All Users',  e.g.  'D:Dokumente und Einstellungen:All Users:' .  Path ends with colon.
// Alternate approach: use  'UFCom_UtilGetAllUsersDirectory()'  (after copying the code into UFCom_xxx. Cave: Path is Win-style and uses '\' as separator).  Disadvantage: Secutest would need an Xop....
	string  	sPathTo_User_EigeneDateien	= SpecialDirPath( "Documents", 0, 0, 0 )		// path ends with colon, e.g. 'D:Dokumente und Einstellungen:Administrator:EigeneDateien:'
	variable	n, nItems					= ItemsInList( sPathTo_User_EigeneDateien, ":" )
	string  	sPathTo_AllUsers			= RemoveListItem( nItems-2, RemoveListItem( nItems-1, sPathTo_User_EigeneDateien, ":" ) , ":" ) + "All Users" + ":"  
	return	sPathTo_AllUsers												// path ends with colon, e.g. 'D:Dokumente und Einstellungen:All Users:'
End


Function	/S	UFCom_ReadTxtFile( sPathFile )	
// could pass line separator
	string  	sPathFile
	variable	nRefNum, len
	string  	sLine, sAllLines	= ""
	Open /Z=2 /R    			nRefNum  as sPathFile	// /Z = 2:	opens dialog box  if file is missing,  /Z = 1:does nothing if file is missing
	if ( nRefNum != 0 )											//  3 failure modes:  file missing, .............settings file containing script file is missing, user cancelled file open dialog
		do 														
			FReadLine  nRefNum, sLine
			len = strlen( sLine )	
			if ( len == 0 )										// only last line has length 0 which ends the reading loop,...
				break										//...empty lines contain CR or LF and have a length  > 0...
			endif	
			//sLine		= RemoveTrailingSpaceOrTab( sLine )				// keep CR as separator
			sAllLines	+= sLine
			// printf "\t\t%s", sLine
		while ( UFCom_TRUE )     										//...is not yet end of file EOF
		Close nRefNum
	else
		printf "++++Error: Could not open '%s' \r", sPathFile
	endif
	return	sAllLines											// empty string in case of error
End


Function		UFCom_WriteTxtFile( sOutPath, sText )
	string  	sOutPath, sText 
	UFCom_WriteTxtFile_( sOutPath, sText, 0 )
End

// 2009-01-27 not good and no longer used ,   could also remove  'delaySecs'  below....
//Function		UFCom_WriteTxtFileDelayed( sOutPath, sText )
//	string  	sOutPath, sText 
//	variable	delaySecs	= .1								// bad workaround to delay flushing the data to disk. Would be nice to avoid the settings file much too often when a window is moved or resized 
//	UFCom_WriteTxtFile_( sOutPath, sText, delaySecs )
//End

Function		UFCom_WriteTxtFile_( sOutPath, sText, delaySecs )
	string  	sOutPath, sText 
	variable	delaySecs
	variable	nRefNum
	string  	sSepCR	= "\r"
	string  	sLine		= ""
	variable	n,  nLines	= ItemsInList( sText, "\r" )
	variable	maxlen = 960									// !!! ass Igors max printf length (could be ~1000 but certainly less than 1100)
	variable	len, chunk, nChunks, rest
	if ( delaySecs )
		UFCom_delay( delaySecs )							// bad workaround to delay flushing the data to disk. Would be nice to avoid the settings file much too often when a window is moved or resized 
	endif
	Open	nRefNum	as sOutPath
	if ( strlen( S_filename ) )
		for ( n = 0; n < nLines; n += 1 )
			sSepCR	= SelectString( n == nLines - 1  &&   ! UFCom_LineEndsWith( sText, "\r" ) , "\r", "" )  // the last line of 'sText' may or may not contain a CR: the Outfile should be the same...
			sLine		= StringFromList( n, sText, "\r" )

// 2008-08-13
			// Overcome IGORs printf limit (appr. 1000 characters...)
			len		= strlen( sLine )
			nChunks	= trunc( ( len - 1 ) / maxlen ) 		// number of complete chunks ( 0 for most lines = 0 for all lines shorter than 'maxlen'  )
			for ( chunk = 0; chunk < nChunks; chunk += 1 )
				fprintf nRefNum, "%s", sLine[ chunk * maxlen, ( chunk+1 ) * maxlen - 1 ]
 			endfor			
			fprintf nRefNum, "%s%s", sLine[ nChunks * maxlen , inf ], sSepCR
			
			//printf "\t\t\tUFCom_WriteTxtFile_( '%s' ) \tline.\t%4d\t/%4d\tlen:\t%3d\t'%s' \r",  sOutPath, n, nLines, strlen( sLine), sLine[0,200]

		endfor
		Close nRefNum
	else
		printf "Error writing '%s'  (%s....) \r", sOutPath, sText[0, 150 ]
	endif
End


// 2009-04-24  moved to COMMONS from UFST_EData
Function 	/S	UFCom_SymbPath2Dir( sSymbPath )
// Returns directory when symbolic path is passed.  Path is Mac-Style and contains trailing colon, e.g. 'C:EPC:Data:'
	string		sSymbPath
	PathInfo	/S 	$sSymbPath
	return	s_path	
End



Function		UFCom_GetFileSize( sPath )
	string  	sPath
	variable	nRefNum
	variable	nFileSize	= 0
	Open 	/Z /R nRefNum  as sPath
	if ( V_Flag == 0 )
		FStatus	nRefNum
		if ( V_Flag )
			nFileSize	= V_logEOF
		else
			printf "Warning: Could not get status of  '%s' in UFCom_GetFileSize() )\r", sPath
		endif	
		Close	nRefNum
	else
		printf "Warning: Could not open for reading  '%s' in UFCom_GetFileSize() )\r", sPath
	endif
	return	nFileSize
End	
	
	