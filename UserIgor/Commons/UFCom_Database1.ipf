//

// 060826      was 119260 10.05 10.58

//  UFCom_Database.ipf 

// Usage:
// How to insert or delete a column:
//	1. Save recipe database (emergency backup)
//	2. Mark column header in front of which a new column is to be inserted (this will take some time as it will sort the column)
//	3. Let Igor insert/delete the column:  'Data' , 'Insert/delete points'.   The columns will change and the header will now be wrong, so look for the data (and ignore the header) when selecting the insertion column.
//	4. Insert/delete the column programmatically: Change all appropriate lines below e.g.  kR_TITLE=0,  kR_PR=1, lstREC_COLNAME, 	lstREC_COLWIDTH, 	lstKEYS_HEAD, lstKEYS_HEAD_VIEW	
//	5. Save database 
//	6. Save experiment (or at least this file), quit Igor and restart Igor. Open the database table and check the changes.
  
  
#pragma rtGlobals=1							// Use modern global access method.

#include "UFCom_Constants"


//061030 strconstant	ksDBMARKER_CREATE	= "_create_"


strconstant	kTBL_FONT			=  "MS Sans Serif"	// 
constant		kTBL_FONTSZ			=  9				// 
static constant	kTBL_ROWHEIGHT		= 18				// Unfortunately this depends on screen resolution and table font size, empirical values are 20 for 1280x1024, 22 for 1600x1200 (fsize10) and 18 for a fontsize of 8 or 9)  . 
												// Perhaps it can be retrieved somehow.



Function		UFCom_GetTableRowCol( s, r, c )
// Computes from MOUSE position and table coordinates which cell has been CLICKED. The  'TableInfo' string returns directly the selected cell but only if it is a true inner table cell. 
// Drawback 1: The  'TableInfo' string does not return info about outer cells ('Row' column and the 2 headlines) which we are especially interested in...
// Drawback 2: The  'TableInfo' string  for any row or column -1  when the cursor keys are used  -> This case must be trapped and  'TableRowColFromArrowKeys()'  must be used .
// Drawback 3: does not react on right mouse clicks
	struct	WMWinHookStruct &s
	variable	&r, &c

//	print  	TableInfo( s.WinName, -2 ) ; print "\r"
//	print  	TableInfo( s.WinName, -1 );  print "\r"
//	print  	TableInfo( s.WinName, 0 );   print "\r"
//	print  	TableInfo( s.WinName, 1 );   print "\r"
	string  	sTblInfo	= TableInfo( s.WinName, -2 )
	variable	nFirstRow	= str2num( StringFromList( 0, StringByKey( "FIRSTCELL" , sTblInfo ) , "," ) )	
	variable	nFirstCol	= str2num( StringFromList( 1, StringByKey( "FIRSTCELL" , sTblInfo ) , "," ) )	
	variable	nTgtRow	= str2num( StringFromList( 0, StringByKey( "TARGETCELL" , sTblInfo ) , "," ) )	
	variable	nTgtCol	= str2num( StringFromList( 1, StringByKey( "TARGETCELL" , sTblInfo ) , "," ) )	
	variable	xp 	 	= NumberByKey( "WIDTH" , 	TableInfo( s.WinName, -1 ) )				// the width of the 1. column (= the 'row' column having the index -1 )
	variable	nCols	= NumberByKey( "COLUMNS" ,	TableInfo( s.WinName,  0 ) )	
	variable	nRows	= NumberByKey( "ROWS" ,	TableInfo( s.WinName, -2 ) )	
	string  	sColOutOfRange = "", sRowOutOfRange = ""

	//GetSelection table, $s.WinName, 1				//Gets the selection I made on this table               
	//variable PointLocation = V_startRow			//record the cell of interest.
	// print "GetTableRowCol() row from tableinfo ", nTgtRow, "   and from GetSelection : ", V_startRow, "   and from s.row : " // , s.row
	// print s

// 060920  rounding errors lead to false high columns...
//	if (  s.mouseLoc.h <= xp * screenresolution / UFCom_kIGOR_POINTS72  )//||  c >= nCols )
//		c	= -1
//		sColOutOfRange	= "> C: 'Row'\t"
//	else
//		c 	= nFirstCol
//		do
//			// Cave: Although multiple unused right columns are drawn by Igor they cannot get selected. Igor allows only to select the first unused column.
//			xp 	+=   NumberByKey( "WIDTH" , 	TableInfo( s.WinName, c ) )	
//			if ( s.mouseLoc.h <= xp * screenresolution / UFCom_kIGOR_POINTS72  ||  c >=  nCols )		//  allow and monitor clicking into unused right columns 
//				sColOutOfRange	= SelectString( c >= nCols , " \t\t" , "> C: unused" )
//				break
//			endif
//			c	+= 1
//		while ( UFCom_TRUE )
//	endif

	variable	sc_p	= screenresolution / UFCom_kIGOR_POINTS72 
	if (  s.mouseLoc.h <= xp * sc_p  )//||  c >= nCols )
		c	= -1
		sColOutOfRange	= "> C: 'Row'\t"
	else
		c 	= nTgtCol
		sColOutOfRange	= SelectString( c >= nCols , " \t\t" , "> C: unused" )
	endif

	if ( nTgtRow == 0 )									// this can be the true row 0 or one of the 2 header lines
		r	= trunc( s.mouseLoc.v / kTBL_ROWHEIGHT ) - 3	// Inspite of the uncertainty in  kTBL_ROWHEIGHT it is precise enough to discriminate between the 3 lines on top
		sRowOutOfRange	= "> R: Header\t"
	else
		r	= nTgtRow								// ??? TARGETROW is computed delayed when the window is entered. Incorrect at the 1., works only at the 2. mouse action
		sRowOutOfRange	=  " \t \t"
		variable rowByMouse = trunc( s.mouseLoc.v / kTBL_ROWHEIGHT ) - 3 + nFirstRow
	endif
	
	string  	sEvTxt = UFCom_pad( s.eventName, 8 )
	// printf "\t\tGTRC xp:%4d\txSc:%4d\t >? xmo:%4d\tnCols:%3d\tc1:%d\tc:%3d\t[=%2d]\t%s\tyMouse:%4d\tnRows:%4d \tr1: %3d\tr:%3d\t[=%2d]\tOldRbM:%4d\t[trh:%3d]\t%s\tE:%2d\t%s\tMod:%4d\tkey:%4d \r", xp, xp * sc_p, s.mouseLoc.h, nCols, nFirstCol, c, nTgtCol, sColOutOfRange,s.MouseLoc.v,nRows,nFirstRow,r,nTgtRow,rowByMouse,kTBL_ROWHEIGHT,sRowOutOfRange,s.eventCode,sEvTxt,s.eventMod,s.keycode
End
	

Function		UFCom_TableRowColFromArrowKeys( s, r, c )
// Computes which cell has been navigated to by ARROW keys.
	struct	WMWinHookStruct &s
	variable	&r, &c

	// print  	TableInfo( s.WinName, -2 ) ; print "\r"
	string  	sTblInfo	= TableInfo( s.WinName, -2 )
	r	= str2num( StringFromList( 0, StringByKey( "TARGETCELL" , sTblInfo ) , "," ) )	
	c	= str2num( StringFromList( 1, StringByKey( "TARGETCELL" , sTblInfo ) , "," ) )	
End


Function	/S	UFCom_KeyText( nKeyCode )
	variable  	nKeyCode
	return	StringFromList( nKeyCode, UFCom_COD_lstKEYS )
End

//==============================================================================================
//  LOADING  THE  RECIPE  DATA BASE   AS  A  WAVE  FROM  A  FILE

Function		UFCom_LoadDatabaseMulti1Dim_( sDir, sFileNm, sBaseF, sF, lstWantWavesNm, lstWantWavesTyp )
// Read  multiple 1dim text or number waves = 1 data base  from disk.  Strategy is to keep existing waves and to automatically integrate waves which may be added during development 
	string  	sDir, sFileNm, sBaseF, sF, lstWantWavesNm, lstWantWavesTyp
	string 	sFile				= sDir + sFileNm		
	string 	sTxt
	string 	sWantWave, sWantType, lstWavesInFile = ""
	variable	n, nWantWaves	= ItemsInList( lstWantWavesNm )
	variable	nMissing			= 0

	LoadWave /O /T /A  /Q 	sFile												//  load the file containing the data base ( e.g. Zutaten )   from disk
	if ( V_flag )											 					// is  'Null'  if there are no files : change to  "" (=empty string)
	 	lstWavesInFile 	=  S_waveNames
	endif

	for ( n = 0; n < nWantWaves; n += 1 )
		sWantWave	= StringFromList( n, lstWantWavesNm )
		sWantType	= StringFromList( n, lstWantWavesTyp )
		if ( n == 0 )
			wave  /Z	/T wtMain	= $sWantWave 								// Still in root!  The wave at the first position (=first column) determines the length of all others
			variable	nPnts	= waveExists( wtMain )   ?  numPnts( wtMain )   :   0 		
		endif
	
		if ( WhichListItem( sWantWave, lstWavesInFile ) == UFCom_kNOTFOUND )				// ...now check each of the wave names
			sprintf sTxt, "Expected wave\t'%s'\tnot found in file  '%s'  . This file contains only wave(s)  '%s' . Creating missing wave with %d pts...", sWantWave, sFile, lstWavesInFile, nPnts
			UFCom_Alert1( UFCom_kERR_IMPORTANT, sTxt )
			if ( cmpstr( sWantType, "Text" ) == 0 )
				make  /O /T /N= (nPnts)   $(sBaseF + sF + sWantWave ) = ""	// create the missing   text     wave : OK   is in file another column parallel to wtMain (e.g.=wtZut )...	
			else				// "Number"
				make  /O  	   /N= (nPnts)   $(sBaseF + sF + sWantWave ) =  0	// create the missing number wave : Flaw is not in parallel to existing number waves (e.g. wEuros) but rows are added (at least once???)
			endif
			nMissing	+= 1
		else
			duplicate	/O 	$sWantWave   $( sBaseF + sF + sWantWave )	// the waves are loaded in the root so we move them..
			killWaves	$sWantWave											// ..into a folder
		endif
	endfor	

	if ( nMissing )															// only if waves have been added then...
		UFCom_SaveDataBase( sDir, sFileNm, sBaseF, sF, lstWantWavesNm )								// ...save the old and the newly created missing wave(s) which are still empty
	endif
End


Function		UFCom_LoadDatabaseOne2Dim_EMPTY( sDir, sFileNm, sBaseF, sF, sWantWave,  lstWaveCols )
// 061130 also accept a symbolic path for 'sDir' .  It is automatically detected whether 'sDir' is a symbolic path or not.
	string  	sDir, sFileNm, sBaseF, sF, sWantWave, lstWaveCols
	variable	nInitialRows = 0								// 'nInitialRows' = 0 : creates no row (as in SecuCheck, disadvantage: when the first data are entered the 2! rows[also the col nr row] are added  

	string 	sPathFile = ""
	variable	bIsSymbolicPath	= UFCom_IsSymbolicPath( sDir )
	if ( bIsSymbolicPath )
		PathInfo	/S 	$sDir;  	sDir	= S_Path// + sFileNm		// only for debug print below 
	endif

	UFCom_LoadDatabaseOne2Dim_NRows( sDir, sFileNm, sBaseF, sF, sWantWave,  lstWaveCols, nInitialRows )
End


Function		UFCom_LoadDatabaseOne2Dim_( sDir, sFileNm, sBaseF, sF, sWantWave,  lstWaveCols  )
	string  	sDir, sFileNm, sBaseF, sF, sWantWave, lstWaveCols
	variable	nInitialRows	= 1							// 'nInitialRows' = 1 : creates an empty row (as in Recipes)
	UFCom_LoadDatabaseOne2Dim_NRows( sDir, sFileNm, sBaseF, sF, sWantWave,  lstWaveCols, nInitialRows )
End


Function		UFCom_LoadDatabaseOne2Dim_NRows( sDir, sFileNm, sBaseF, sF, sWantWave,  lstWaveCols, nInitialRows )
// Read  any  2dim text wave = 1 data base  from disk.  Strategy is to keep existing  columns and to automatically fill in missing columns if during development columns are added.
// Limitations: 1. Only 1 main wave is allowed if there are subwaves (=-REC)    2. If there are subwaves then all must have same type ("Text"  OR  "Number" ). 
// Cave1: The current data folder must not be  'sBaseF + sF'  (e.g. must not be 'UFCom_ksROOT_UF_ + ksF_REC_ ')   because  'duplicate'  below will fail
// Cave2: The data base must NOT have  0 rows. With 0 rows the number of columns is ignored and also set to 0 in 'SaveDataBase' : All redimensioning is useless...
	string  	sDir, sFileNm, sBaseF, sF, sWantWave, lstWaveCols
	variable	nInitialRows								// 'nInitialRows' can be 0 : creates no row (as in SecuCheck, disadvantage: when the first data are entered the 2! rows[also the col nr row] are added  
	variable	c, nWantWvCols	= ItemsInList( lstWaveCols )	// 'nInitialRows' can be 1 : creates an empty row (as in Recipes)

	string 	sFile				= sDir + sFileNm		
	string 	sTxt
	
// 060828
	variable	nCode
	string  	sFolderWave	= sBaseF + sF + sWantWave

	UFCom_PossiblyCreatePath( sDir )
	
	if ( ! UFCom_FileExists( sFile ) )										// The data base wave is missing : create it
		sprintf sTxt, "Could not load wave '%s' from file '%s' . Missing wave(s) will be created...", sWantWave, sFile 	
		UFCom_Alert1( UFCom_kERR_IMPORTANT, sTxt )		
		// print "\t\tLoadDatabaseOne2Dim", "\t", sWantWave, "\t", "\tSubWaves:", lstWaveCols, nWantWvCols 
		make  /O  /T  /N= ( nInitialRows, nWantWvCols )  	$sFolderWave = ""	// nInitialRows can be 0 or 1. If rows are 0 then the column dimensioning fails as Igor sets the column number also to 0  (bad behaviour!)
		wave	/T	WantWave	= 		$sFolderWave				// create the missing wave in the folder...
		UFCom_SaveDataBase( sDir, sFileNm, sBaseF, sF, sWantWave )			//...and save the newly created missing wave (still empty)
		nCode	= 0
	else															// the wave has been loaded  so now we must check if no columns are missing... 
		LoadWave /O /T /A  /Q 	sFile									//  load the file containing the  stored data base from disk
		wave	/T	WantWave	= 	$sWantWave	
		variable	nRows	= DimSize( WantWave, 0 )
		variable	nColumns	= DimSize( WantWave, 1 )						// ...now check each of the columns 
		// Cave: Works only if there is at least 1 row....
		if ( nWantWvCols >  nColumns )
			sprintf sTxt, "Expecting 2 dimensional text wave '%s'  having  %d columns. Found %d columns (and %d rows). Redimensioning...", sWantWave, nWantWvCols, nColumns, nRows
			UFCom_Alert1( UFCom_kERR_IMPORTANT, sTxt )		
			Redimension /N=( nRows, nWantWvCols )	WantWave
			duplicate	/O 	WantWave	$sFolderWave					// ...but the wave is loaded into the Current data folder so we move it into a folder..
			killWaves		WantWave								// ...and we delete the temporary wave in the root
			// printf "\t\t\tLoadDatabaseOne2Dim_NRows() now has %d columns and %d rows \r", DimSize( $sFolderWave, 1 ), DimSize( $sFolderWave, 0 ) 
			UFCom_SaveDataBase( sDir, sFileNm, sBaseF, sF, sWantWave )		// ...and save the wave with old and the newly created columns (still empty)
		else														// Normal case: The wave loaded from file has the expected dimensions... 
			duplicate	/O 	WantWave	$sFolderWave					// ...but the wave is loaded into the Current data folder so we move it into a folder..
			killWaves		WantWave								// ...and we delete the temporary wave in the Current data folder
		endif
		nCode	= 1
	endif

	return 	nCode
End


// not yet used 060904
//Function		UFCom_InitDatabaseOne2Dim_( sDir, sFileNm, sBaseF, sF, sWantWave,  lstInitEntries )
//// Initialise an existing but completely empty data base (= 0 rows)  with  'lstInitEntries'  in row 0.  On exit the data base will then contain 1 row.
//	string  	sDir, sFileNm, sBaseF, sF, sWantWave, lstInitEntries
//	wave	/T			wv	= $sBaseF + sF + sWantWave
//	redimension  /N=( 1, -1 )	wv
//	variable  	c, nCols	= DimSize( wv, 1 )
//	for ( c = 0; c < nCols; c += 1 )
//		//printf "\t\tInitDatabaseOne2Dim_()   \tcol:%2d/%2d\tInitEntry: '%s' \r", c, nCols, StringFromList( c, lstInitEntries ) 
//		wv[ 0 ][ c ] 	= StringFromList( c, lstInitEntries ) 
//	endfor
//	SaveDataBase( sDir, sFileNm, sBaseF, sF, sWantWave )			// ...and save the wave with old and the newly created columns (still empty)
//End


Function	/S	UFCom_NewDatabaseOne2Dim_NRows( sDir, sFileNm, sBaseF, sF, sWantWave,  lstWaveCols, nInitialRows )
// Create a new empty data base file  'sDir + sFileNm'  from the wave  'sBaseF + sF + sWantWave'   having  the title 'lstWaveCols'   ..... nInitialRows
// Returns  full file path   or   empty string if user clicked  Cancel . 
	string  	sDir, sFileNm, sBaseF, sF, sWantWave, lstWaveCols
	variable	nInitialRows							// 'nInitialRows' can be 0 : creates no row (as in SecuCheck, disadvantage: when the first data are entered the 2! rows[also the col nr row] are added  
	variable	c, nWantWvCols= ItemsInList( lstWaveCols )	// 'nInitialRows' can be 1 : creates an empty row (as in Recipes)

	string 	sFile			= sDir + sFileNm		
	string 	sTxt
	string  	sFolderWave	= sBaseF + sF + sWantWave

	UFCom_PossiblyCreatePath( sDir )
	
	if ( ! UFCom_FileExists( sFile ) )												// The data base wave is missing : create it
		printf "\t\tNewDatabaseOne2Dim_NRows(), \tCreating wave '%s' with %d rows and %d columns  and storing it in file '%s' . \r", sWantWave, nInitialRows, nWantWvCols, sFile 	
		make  /O  /T  /N= ( nInitialRows, nWantWvCols )  	$sFolderWave = ""	// nInitialRows can be 0 or 1
		wave	/T	WantWave	= 		$sFolderWave				// create the missing wave in the folder...
		UFCom_SaveDataBase( sDir, sFileNm, sBaseF, sF, sWantWave )							//...and save the newly created missing wave (still empty)
	else															// the wave has been loaded  so now we must check if no columns are missing... 
		sprintf   sTxt, "File '%s' exists already. \rDo you really want to overwrite the existing file?", sFile 	
		printf "Warning: %s \r", sTxt
		DoAlert 2, sTxt				// 2 : Yes, No, Cancel
		if ( V_flag == 1 )				// 1 : yes
			printf "answer was YES\r"
		else
			printf "answer was No or Cancel \r"
			sFile	= ""
		endif
	endif
	return	sFile
End

//==============================================================================================
//  GENERIC  DATABASE  FUNCTIONS  FOR  2DIM  TEXT WAVE

Function		UFCom_NumEntries( wDB )
	wave  /T	wDB
	variable	nRows	= DimSize( wDB, 0 )
	return	nRows
End


Function		UFCom_NumCols( wDB )
	wave  /T	wDB
	variable	nCols	= DimSize( wDB, 1 )
	return	nCols
End


Function	/T	UFCom_EntireLine( wDB, row, sSep )
	wave  /T	wDB
	variable	row
	string  	sSep
	variable	c, nCols	= UFCom_NumCols( wDB )
	string  	sEntireLine= ""
	for ( c = 0; c < nCols; c += 1 )
		sEntireLine += wDB[ row ][ c ] + sSep
	endfor
	return	sEntireLine
End


Function		UFCom_DataSetExists( sExistingData, sNewData )
	string  	sExistingData, sNewData
	return	! cmpstr( sExistingData, sNewData ) 
End


Function		UFCom_RemoveIfMissing( wDB, nColumn, sTxtDBNm, sTxtCol, bAskBeforeRemoving )
// CAUTION : Only to be used in Debug mode!  Deletes every data set of  'wDB'  which has no  entry  in  'nColumn'

	wave 	/T	wDB
	variable	nColumn	
	string  	sTxtDBNm, sTxtCol
	variable	bAskBeforeRemoving 
	variable	n, nRows		= UFCom_NumEntries( wDB )
	variable	nRemoved	= 0
	string  	sID
	
	for ( n = 0; n < nRows; n += 1 )
		sID	= UFCom_RemoveTrailingWhiteSpace(  UFCom_RemoveLeadingWhiteSpace( wDB[ n ][ nColumn ] ) )
		if ( strlen( sID ) == 0 )
 			// printf "\t\tUFCom_RemoveIfMissing()\t\t%3d /%4d\t%s\t%s\t%s \r", n+1, nItems, pad( wDB[ n ][ 0 ] , 15 ) , wDB[ n ][ 1 ]  , wDB[ n ][ 2 ]  
			nRemoved	+= 1
		endif
	endfor

	if ( nRemoved ) 
		if ( bAskBeforeRemoving )
			DoAlert 1, "Do you really want to remove " + num2str( nRemoved ) + " data sets ( from " + num2str( nRows ) + " )  because of their missing ID? \rIf you choose 'No' the data sets are kept but you must fill in the ID manually."
		endif
		if ( ! bAskBeforeRemoving  ||  V_Flag == 1 )
			for ( n = 0; n < nRows; n += 1 )
				sID	= UFCom_RemoveTrailingWhiteSpace(  UFCom_RemoveLeadingWhiteSpace( wDB[ n ][ nColumn ] ) )
				if ( strlen( sID ) == 0 )
		 			// printf "\t\tUFCom_RemoveIfMissing()\t\t%3d /%4d\t%s\t%s\t%s \r", n+1, nItems, pad( wDB[ n ][ 0 ] , 15 ) , wDB[ n ][ 1 ]  , wDB[ n ][ 2 ]  
					DeletePoints n , 1 , wDB 
					n		-= 1
					nRows	-= 1
				endif
			endfor
	
			printf "\t\tUFCom_RemoveIfMissing( %s)\thas removed %d data sets ( from %d )  whose  %s  is missing. Total number of data sets now: %d  .\r",  UFCom_Pd( sTxtDBNm, 7 ), nRemoved, nRows + nRemoved, sTxtCol, nRows

		else
			printf "\t\tUFCom_RemoveIfMissing( %s )\twould have (but has not) removed %d data sets ( from %d )  whose  %s  is missing. \r",  UFCom_Pd( sTxtDBNm, 7 ), nRemoved, nRows, sTxtCol
			nRemoved 	= 0
		endif
	else
		printf "\t\tUFCom_RemoveIfMissing( %s )\tNo data sets found  with missing %s.  Total number of data sets: %d \r", UFCom_Pd( sTxtDBNm, 7 ), sTxtCol, nRows
	endif
	return	nRemoved
End


// 061214  UNUSED  if this is reactivated it should be similar to the code  'UFCom_RemoveSimilarDtaSetsAsk() ' below  ( and should include it  by passing an empty dummy wrapper function for 'fBuildDataSetString()' ) !
Function		UFCom_RemoveSimilarDataSetsAsk_( wDB, fBuildDataSetString, nPrimaryColumn )
// Compares each data set against each other data set  and  urges the user to select 1 of the similar data sets.  The other similar data sets are discarded. 
// Two data sets are considered similar if their entries in  'nPrimaryColumn'   and  the strings returned by  'fBuildDataSetString()'   are identical.
// Entries in other columns are ignored so inspite that they may differ the data sets are considered  similar  and will be removed except for 1 data set.
// Which of the similar data sets is to be kept must be decided by the user, who is offered all similar data sets in a popupmenu.
//	Note:  All data sets identical in ALL columns should have been removed beforehand as the popupmenu list would be confusing and  unnecessarily long.  This is safe and simple and is assumed to have already been done.

// In a first step the data sets to be removed are stored in a list.  In a second step they are actually removed from the data base.
// To make the code succinct the  data set construction function  'fBuildDataSetString()'   (which constructs only the important parts of the data set required for comparing different data sets, not all parts)  is passed  as parameter!

	wave   /T	wDB	
	FUNCREF	UFCom_ProtoBuildDataSetString		fBuildDataSetString		// NOT USED !!!!!!!!!!!
	variable	nPrimaryColumn
	//  ......................
End

Function		UFCom_RemoveSimilarDataSetsAsk( wDB, nPrimaryColumn )
// Compares each data set against each other data set  and  urges the user to select 1 of the similar data sets.  The other similar data sets are discarded. 
// Two data sets are considered similar if their entries in  'nPrimaryColumn'  are identical.
// Entries in other columns are ignored so inspite that they may differ the data sets are considered  similar  and will be removed except for 1 data set.
// Which of the similar data sets is to be kept must be decided by the user, who is offered all similar data sets in a popupmenu.
//	Note:  All data sets identical in ALL columns should have been removed beforehand as the popupmenu list would be confusing and  unnecessarily long.  This is safe and simple and is assumed to have already been done.

// In a first step the data sets to be removed are stored in a list.  In a second step they are actually removed from the data base.
// To make the code succinct the  data set construction function  'fBuildDataSetString()'   (which constructs only the important parts of the data set required for comparing different data sets, not all parts)  is passed  as parameter!

	wave   /T	wDB	
	variable	nPrimaryColumn
	string  	lstDeleteRows	= "" 
	string  	lstSortCols		= num2str( nPrimaryColumn ) + ";" 
	string  	sRowSep		= ";" 						// must be semicolon as this is the default for separating rows in the popupmenu
	string  	sColSep		= "´"						// also  '°'  or  ':'  or  '^' .  Any character except  ';'  but this character cannot be used by the user. 
	string  	sPrimaryEntry	= "" ,  sNewPrimaryEntry	= "" ,  lstRowsInGroup = "" 

	//  All data sets must be ordered according to 'nPrimaryColumn' .  This simplifies the following code for searching similar data sets considerably.
	UFCom_SortByColumnList( wDB, lstSortCols, UFCom_kSORTACTION_UP, UFCom_kSORT_ALPHA_NUM_CASE_I )	// 'lstSortCols' is only the primary column, but (??? to think) we could sort also by additional columns

	variable	r, nRows		= UFCom_NumEntries( wDB )
	variable	n, nEntriesInGroup

	// Step 1: Loop through all rows, combine entries with same ID to a group, let the user select just 1 entry of each group for keeping  and store the remaining row numbers of the items to be discarded in a list  
	for ( r = 0; r < nRows; r += 1 )
		sNewPrimaryEntry	= UFCom_RemoveOuterWhiteSpace( wDB[ r ][ nPrimaryColumn ] )
		if ( cmpstr( sNewPrimaryEntry, sPrimaryEntry ) )						// entry in primary column has changed : start new 'nPrimaryColumn' group  in which similar entries will be searched. 
			if ( r > 0 )
				// This row 'r' will start a new group so we have to finish the previous group ( up to row 'r-1' ) now.
				// Remove data sets which are identical in ALL columns which would make the popupmenu list confusing and  unnecessarily long.   Sorting is required for 'UFCom_RemoveDoubleEntries()' ...???
				nEntriesInGroup = ItemsInList( lstRowsInGroup ) 

				// Now that data sets which are identical in ALL columns are removed we can search for similar data sets.  These are offered to the user and the user must decide which one to keep and which to discard.

				if ( nEntriesInGroup > 1 ) 
					variable	nOption		= 0			// default value if user cancelled
					string  	sRowMarker 	= "row:" 				 
					string		lstAllEntries	= ""
					for ( n = 0;  n < nEntriesInGroup;  n += 1 )
						variable	nRowInGroup	= str2num( StringFromList( n, lstRowsInGroup ) )
						string  	sEntryInGroup	= UFCom_pad( sRowMarker + num2str( nRowInGroup ),  8 )  + sColSep +  UFCom_FormatLine( wDB, nRowInGroup, sColSep ) 
						// printf "\t\t\tRemIdDS(4) \tr:%4d\t%4d\t%s\tn:%4d\t/%4d:\t%s\tnRowInGroup: %d \r", r, nRows, sPrimaryEntry, n, nEntriesInGroup, sEntryInGroup, nRowInGroup 
						lstAllEntries += sEntryInGroup + sRowSep
					endfor

					string  	sPopupEntry	= ""
					Prompt	sPopupEntry,	"Appliance: ", popup, lstAllEntries
					DoPrompt	"Select the description for Appliance '" + UFCom_RemoveOuterWhiteSpace( StringFromList( 1, lstAllEntries, sColSep ) ) + "'  ( Cancel will select the first item.) :", sPopupEntry 
					// The user MUST make up his mind and make a choice, if he cancels the first item is selected.
					if ( V_flag != 1 )
						nOption	= WhichListItem( sPopupEntry, lstAllEntries, sRowSep )		// user pressed 'Continue'
					endif
					variable	nSelectedRow	= str2num( ReplaceString( sRowMarker, UFCom_RemoveWhiteSpace( StringFromList( 0, StringFromList( nOption, lstAllEntries, sRowSep ) , sColSep ) ), "" ) )
					 printf "\t\tUFCom_RemoveSimilarDataSetsAsk()\tOption: %d   <=>  selected row : %d \r",  nOption , nSelectedRow

					// Now that the user has selected to keep row 'nSelectedRow'  we go on and delete all others
					for ( n = 0;  n < nEntriesInGroup;  n += 1 )
						nRowInGroup	= str2num( StringFromList( n, lstRowsInGroup ) )
						if ( nRowInGroup != nSelectedRow ) 
							lstDeleteRows += num2str( nRowInGroup ) + ";"
						endif
					endfor
				endif
			endif  

			sPrimaryEntry 	= UFCom_RemoveOuterWhiteSpace( wDB[ r ][ nPrimaryColumn ] )
			lstRowsInGroup	= ""
		endif
		// Add data base row to group
		lstRowsInGroup	+= num2str( r ) + ";"
	endfor

	// Step 2: Loop backwards through all rows and delete the rows which have been stored in a list during the previous step  
	variable	nDeleted	= ItemsInList( lstDeleteRows )
	 printf "\t\tUFCom_RemoveSimilarDataSetsAsk()\twill discard %d rows '%s...' \r", nDeleted, lstDeleteRows[0,200]
	for ( n = nDeleted - 1;  n >= 0;  n -= 1 )								// delete higher rows first so not to disturb the data base order while deleting
		nRowInGroup	= str2num( StringFromList( n, lstDeleteRows ) )
		UFCom_DeleteDatabaseEntry( wDB, nRowInGroup )
	endfor
	 printf "\t\tUFCom_RemoveSimilarDataSetsAsk()\thas discarded %d (=?= %d ) rows from %d  . Data base now has %d rows. \r", nDeleted,  nRows - UFCom_NumEntries( wDB ), nRows, UFCom_NumEntries( wDB )
End


Function	/T	UFCom_FormatLine( wDB, row, sSep )
	wave  /T	wDB
	variable	row
	string  	sSep
	variable	nDefaultWidth	= 6
	variable	c, nCols		= UFCom_NumCols( wDB )
	string  	sEntireLine	= ""
	for ( c = 0; c < nCols; c += 1 )
		sEntireLine += UFCom_pad( wDB[ row ][ c ] , nDefaultWidth ) + sSep
	endfor
	return	sEntireLine
End



Function 	/S	UFCom_ProtoBuildDataSetString( wDB, row )
// Dummy function prototype 
	wave  /T	wDB
	variable	row
	print "in UFCom_ProtofBuildDataSetString with row= ", row
End


Function	/S	UFCom_FindIdenticalDatasets( wDB, fBuildDataSetString, bDoDisplay )
// Compares each data set against each other data set and stores the indices of identical sets (doublettes)  in a list in a first step..
// To make the code succinct the  data set construction function  'fBuildDataSetString()'   (which constructs only the important parts of the data set required for comparing different data sets, not all parts)  is passed !
// In a second step the doublettes are removed.   May take very, very long,  as the time increases ~nRows*nRows.   
// This may be acceptable as this command is seldom used (actually only after the user inadvertently appended existing data  in spite of the fact that he has been warned not to do so.

	wave   /T	wDB	
	Funcref	UFCom_ProtoBuildDataSetString		fBuildDataSetString		
	variable	bDoDisplay
	
	variable	r, nRows		= UFCom_NumEntries( wDB )
	string  	sDoublette, lstDoublettes	= ""
	variable	nDoub
	
	string  	sExistingData, sFurtherData
	for ( r = 0; r < nRows; r += 1 )								// loop through ALL rows
		sExistingData	= fBuildDataSetString( wDB, r )
		for ( nDoub = r + 1; nDoub < nRows; nDoub += 1 )			// loop only through all following rows
			sFurtherData	= fBuildDataSetString( wDB, nDoub )
			if ( UFCom_DataSetExists( sExistingData, sFurtherData ) )
				// printf "\t\tUFCom_RemoveIdenticalDatasets(1) \tDBRows:%3d\tRow\t%4d\thas a copy in row\t%4d\t'%s'...   \r", nRows, r, nDoub, sExistingData[0,200]
				sDoublette	 	= num2str( nDoub )
				lstDoublettes	= UFCom_PossiblyAddListItem( sDoublette, lstDoublettes )	// add only once 
				if ( bDoDisplay )
			 		printf "\t\tUFCom_FindIdenticalDatasets(2) \tRow\t%4d\t/ %4d\t\thas copy in \trow\t%3d\t'%s'\t ->\tDoublettes:%d    '%s'   \r", r, nRows, nDoub, sExistingData[0,200], ItemsInList( lstDoublettes ), lstDoublettes[0,300]
				endif
			endif
		endfor
	endfor
	return	lstDoublettes
End

Function		UFCom_RemoveIdenticalDatasets( wDB, fBuildDataSetString )
// Compares each data set against each other data set and stores the indices of identical sets (doublettes)  in a list in a first step..
// To make the code succinct the  data set construction function  'fBuildDataSetString()'   (which constructs only the important parts of the data set required for comparing different data sets, not all parts)  is passed !
// In a second step the doublettes are removed.   May take very, very long,  as the time increases ~nRows*nRows.   
// This may be acceptable as this command is seldom used (actually only after the user inadvertently appended existing data  in spite of the fact that he has been warned not to do so.

	wave   /T	wDB	
	Funcref	UFCom_ProtoBuildDataSetString		fBuildDataSetString		
	variable	nDoub
	
// 071015 removed
//	variable	r, nRows		= UFCom_NumEntries( wDB )
//	string  	sDoublette, lstDoublettes	= ""
//	
//	string  	sExistingData, sFurtherData
//	for ( r = 0; r < nRows; r += 1 )								// loop through ALL rows
//		sExistingData	= fBuildDataSetString( wDB, r )
//		for ( nDoub = r + 1; nDoub < nRows; nDoub += 1 )			// loop only through all following rows
//			sFurtherData	= fBuildDataSetString( wDB, nDoub )
//			if ( UFCom_DataSetExists( sExistingData, sFurtherData ) )
//				// printf "\t\tUFCom_RemoveIdenticalDatasets(1) \tDBRows:%3d\tRow\t%4d\thas a copy in row\t%4d\t'%s'...   \r", nRows, r, nDoub, sExistingData[0,200]
//				sDoublette	 	= num2str( nDoub )
//				lstDoublettes	= UFCom_PossiblyAddListItem( sDoublette, lstDoublettes )	// add only once 
//			 	 printf "\t\tUFCom_RemoveIdenticalDatasets(2) \tRow\t%4d\t/ %4d\t\thas copy in \trow\t%3d\t'%s'\t ->\tDoublettes:%d    '%s'   \r", r, nRows, nDoub, sExistingData[0,200], ItemsInList( lstDoublettes ), lstDoublettes[0,300]
//			endif
//		endfor
//	endfor

	string  lstDoublettes	= UFCom_FindIdenticalDatasets( wDB, fBuildDataSetString, 0 )		// Param 3:  Display identical data sets  or  not		

	// Sort list so that  higher rows appear first in list. This order is required for the deletion process.
	lstDoublettes	= SortList( lstDoublettes, ";", UFCom_kSORTDESCENDING | UFCom_kSORTNUMERICAL )
	// Now remove the doublettes starting at the end going backwards 
	variable	n, nDoublettes	= ItemsInList( lstDoublettes )
	for ( n = 0; n < nDoublettes;  n += 1 )
		nDoub	= str2num( StringFromList( n, lstDoublettes ) )
		DeletePoints  /M=0	nDoub, 1,  wDB
	 	// printf "\t\tUFCom_RemoveIdenticalDatasets(3) \tRemoving doublette\t%4d\t/ %4d\t ~\trow\t%3d\t ->\tData base rows left: %d   \r", n, nDoublettes, nDoub, UFCom_NumEntries( wDB )
	endfor
	// printf "\t\tUFCom_RemoveIdenticalDatasets(4)  Entries were %d  ->  %d  now. \r", nRows, UFCom_NumEntries( wDB )
End


//070403 should be renamed: UFCom_PossiblyDeleteDataset( wDB, fBuildDataSetString, nRow )
Function		UFCom_PossiblyAddDataset( wDB, fBuildDataSetString, nRow )
// Compares data set  'nRow' against each preceding data set ( 0...nRow-1)  and removes  data set 'nRow'  if it exists already
// To make the code succinct the  data set construction function  'fBuildDataSetString()'   (which constructs only the important parts of the data set required for comparing different data sets, not all parts)  is passed !

	wave   /T	wDB	
	FUNCREF	UFCom_ProtoBuildDataSetString		fBuildDataSetString		
	variable	nRow
	
	variable	nDoub, r
	
	string  	sExistingData, sFurtherData = fBuildDataSetString( wDB, nRow )

	for ( r = 0; r < nRow; r += 1 )
		sExistingData	= fBuildDataSetString( wDB, r )
		if ( UFCom_DataSetExists( sExistingData, sFurtherData ) )
			DeletePoints  /M=0	nRow, 1,  wDB
			// printf "\t\tUFCom_PossiblyAddDataset(1) \tDBRows:%3d\tRow\t%4d\thas a copy in row\t%4d\t'%s'...   \r", nRows, r, nDoub, sExistingData[0,200]
			break
		endif
	endfor
End


//070403 
Function		UFCom_DatasetMustBeAdded( wDB, fBuildDataSetString, sFurtherData )
// Compares data set 'sFurtherData' against each existing data set ( 0...nRows-1)  and returns truth if  'sFurtherData'  is a new dataset and should be added.
// To make the code succinct the  data set construction function  'fBuildDataSetString()'   (which constructs only the important parts of the data set required for comparing different data sets, not all parts)  is passed !

	wave   /T	wDB	
	FUNCREF	UFCom_ProtoBuildDataSetString		fBuildDataSetString		
	string  	sFurtherData
	
	variable	nDoub, r, nRows		= UFCom_NumEntries( wDB )
	
	for ( r = 0; r < nRows; r += 1 )
		string   sExistingData	= fBuildDataSetString( wDB, r )
		if ( UFCom_DataSetExists( sExistingData, sFurtherData ) )
			// printf "\t\tUFCom_PossiblyAddDataset(1)_\treturns: %d \tDBRows:%3d\tRow\t%4d\thas a copy in row\t%4d\t'%s'...   \r", nRows, r, nDoub, sExistingData[0,200]
			return 	UFCom_FALSE
			break
		endif
	endfor
	// printf "\t\tUFCom_PossiblyAddDataset(2)_\treturns: %d \tDBRows:%3d\tRow\t%4d\thas a copy in row\t%4d\t'%s'...   \r", nRows, r, nDoub, sExistingData[0,200]
	return 	UFCom_TRUE
End

//==============================================================================================

Function		UFCom_CountMissing( wDB, nColumn )
// Count empty entries in column 'nColumn' .   Useful for checking the integrity of the primary key e.g.  ID  or  BestellNr
	wave   /T	wDB	
	variable	nColumn
	variable	nMissing	= 0
	variable	n, nRows	= UFCom_NumEntries( wDB )
	for ( n = 0; n < nRows; n += 1 )
		string    sCell	 = UFCom_RemoveLeadingWhiteSpace(  UFCom_RemoveTrailingWhiteSpace( wDB[ n ][ nColumn ] ) )
		if ( strlen( sCell ) == 0 )
			nMissing	+= 1
			if ( UFCom_DebugVar( "DB_Integrity" ) )
				 printf "\t\t\tDataIntegrityReport()  \tCountMissing()\tSearching for missing Data columns (usually the primary key)  \trow:\t%5d\t/%5d\t  Missing:\t%4d\tColumn: %d\t%s\t  \r",  n, nRows, nMissing,  nColumn,  UFCom_pd( sCell,11)
			endif
		endif
	endfor
	return	nMissing
End

Function	/S 	UFCom_ListOfUnique( wDB, nColumn )
// Return list of unique entries in column 'nColumn'
	wave   /T	wDB	
	variable	nColumn
	string  	lstUnique	= ""
	string  	lstAll		= ""
	variable	n, nRows	= UFCom_NumEntries( wDB )
	for ( n = 0; n < nRows; n += 1 )
		string   sCell	 =  wDB[ n ][ nColumn ]			
		lstAll	+= sCell + ";"
		if ( WhichListItem( sCell, lstUnique ) == UFCom_kNOTFOUND )
			lstUnique += sCell + ";"
		endif
	endfor
	return	lstUnique
End

//==============================================================================================

Function		UFCom_GetTableHeight( wDB ) 
// todo: take into account that from Igor6 on some of header lines may be turned off.....
	wave  /T	wDB
	variable	nRows		= DimSize( wDB, 0 )
	variable	TblHeightPts	= -6 + ( nRows + 5 ) * kTBL_ROWHEIGHT / screenresolution * UFCom_kIGOR_POINTS72	// 6 = Title  +  Table edit line   +  Column names   +   Column numbers  +   Data rows  +  Empty line for new entry   +   Bottom scroll bar
	// printf "\t\t\t\tGetTableHeight() -> nRows:%d  -> returns %d \r", nRows, TblHeightPts
	return	TblHeightPts
End


Function	/S	UFCom_GetColumnWidthList( sTableNm ) 
	string  	sTableNm
	string 	lstColWidth= ""
	string  	sTblInfo	= TableInfo( sTableNm, -2 )
	variable	c, nCols	= NumberByKey( "COLUMNS" ,	TableInfo( sTableNm,  0 ) )	

	for ( c = -1; c < nCols; c += 1 )							// the 1. column (= the 'row' column has the index -1 )
		lstColWidth	+= 	 StringByKey( "WIDTH" , 	TableInfo( sTableNm, c ) ) + ";"		
	endfor
	// printf "\t\t\t\tUFCom_GetColumnWidthList( %s ) returns '%s'   [Row column + %d  data columns] \r", sTableNm, lstColWidth, ItemsInList( lstColWidth ) -1   // -1 for not counting row columnb
	return	lstColWidth
End

Function		UFCom_TotalWidth( lstWidths )
// Sum up and return all widths as given in 'lstWidths'
	string  	lstWidths
	variable	nTotalWidth	= 0
	variable	n, nItems	= ItemsInList( lstWidths )
	for ( n = 0; n < nItems; n += 1 )
		nTotalWidth += str2num( StringFromList( n, lstWidths ) )
	endfor
	return	nTotalWidth
End

Function		UFCom_GetInitialTableWidth( sTableNm, nWidthCol0, lstColWidth ) 
// the point column width is NOT included in the list 'lstColWidth'  but is passed separately
	string  	sTableNm, lstColWidth
	variable	nWidthCol0 
	variable	c, nCols	= ItemsInList( lstColWidth )
	variable	nColWidth	= nWidthCol0
	for ( c = 0; c < nCols; c += 1 )
		nColWidth	+= str2num( UFCom_RemoveWhiteSpace( StringFromList( c, lstColWidth ) ) ) 
	endfor
	// printf "\t\t\t\tGetInitialTableWidth( %s, %d, %s ) returns %d \r", sTableNm, nWidthCol0, lstColWidth, nColWidth
	return	nColWidth
End


Function		UFCom_GetTableWidthInclPointCol( lstColWidth ) 
// the point column width is included in the list 'lstColWidth'  so  nCols is 1 larger than expected
	string  	lstColWidth
	variable	c, nCols	= ItemsInList( lstColWidth )
	variable	nColWidth	= 0
	for ( c = 0; c < nCols; c += 1 )
		nColWidth	+= str2num( UFCom_RemoveWhiteSpace( StringFromList( c, lstColWidth ) ) ) 
	endfor
	// printf "\t\t\t\tUFCom_GetTableWidthInclPointCol( %s ) has %d  columns (including point column!) and returns %d \r", lstColWidth, ItemsInList( lstColWidth ), nColWidth
	return	nColWidth
End


Function		UFCom_AdjustTableWindow( sTableNm )
	string  	sTableNm
	string  	lstColWidth 	= UFCom_GetColumnWidthList( sTableNm )							// includes the point column having the index  -1)
	variable	nTotalColWidth	= UFCom_GetTableWidthInclPointCol( lstColWidth ) 
	GetWindow 	    $sTableNm	wSize												// Get the existing table window's location...
	MoveWindow /W=$sTableNm 	V_left, V_top, V_left + nTotalColWidth + kTBL_MARGINX, V_bottom	//..and adjust the right border
End


// 070806 wDB numerical
Function		UFCom_ModifyTableColumnWidth1Nu( wDB, sTableNm, lstColWidth ) 
	wave 	wDB
	string  	sTableNm, lstColWidth
	UFCom_ModifyTableColumnWidth( wDB, sTableNm, lstColWidth, kWIDTHCOL0 ) 
End

Function		UFCom_ModifyTableColumnWidthNum( wDB, sTableNm, lstColWidth, nWidthCol0 ) 
	wave 	wDB
	string  	sTableNm, lstColWidth
	variable	nWidthCol0 
	variable	c, nCols	= ItemsInList( lstColWidth )
	nCols	= min( nCols, DimSize( wDB, 1 ) )					// prevent Igor from complaining when there are not as many wave columns as width columns
	ModifyTable /W = $sTableNm  width[ 0 ] = nWidthCol0
	for ( c = 0; c < nCols; c += 1 )
		variable	nColWidth	= str2num( UFCom_RemoveWhiteSpace( StringFromList( c, lstColWidth ) ) ) 
		ModifyTable /W = $sTableNm  width[ c + 1 ] = nColWidth		
	endfor
End

Function		UFCom_ModifyTableColumnWidth1( wDB, sTableNm, lstColWidth ) 
	wave 	/T  wDB
	string  	sTableNm, lstColWidth
	UFCom_ModifyTableColumnWidth( wDB, sTableNm, lstColWidth, kWIDTHCOL0 ) 
End

Function		UFCom_ModifyTableColumnWidth( wDB, sTableNm, lstColWidth, nWidthCol0 ) 
	wave 	/T  wDB
	string  	sTableNm, lstColWidth
	variable	nWidthCol0 
	variable	c, nCols	= ItemsInList( lstColWidth )
	nCols	= min( nCols, DimSize( wDB, 1 ) )					// prevent Igor from complaining when there are not as many wave columns as width columns
	ModifyTable /W = $sTableNm  width[ 0 ] = nWidthCol0
	for ( c = 0; c < nCols; c += 1 )
		ModifyTable /W = $sTableNm  width[ c + 1 ] = str2num( UFCom_RemoveWhiteSpace( StringFromList( c, lstColWidth ) ) ) 		
	endfor
End





Function		UFCom_ModifyTableColumnTitles( wDB, sTableNm, lstColTitles ) 
	wave 	/T  wDB
	string  	sTableNm, lstColTitles
	variable	c, nCols	= ItemsInList( lstColTitles )
	nCols	= min( nCols, DimSize( wDB, 1 ) )					// prevent Igor from complaining when there are not as many wave columns as title columns
	for ( c = 0; c < nCols; c += 1 )
		ModifyTable /W = $sTableNm  title[ c + 1 ]		= StringFromList( c, lstColTitles ) 
		ModifyTable /W = $sTableNm  alignment[ c + 1 ]	= 0 		// 0 starts entry at left border 
	endfor
End


Function		UFCom_ModifyTableColumnShading( wDB, sTableNm, lstColShades ) 
	wave 	/T  wDB
	string  	sTableNm, lstColShades
	variable	c, nCols	= ItemsInList( lstColShades )
	nCols	= min( nCols, DimSize( wDB, 1 ) )					// prevent Igor from complaining when there are not as many wave columns as width columns
	for ( c = 0; c < nCols; c += 1 )
		variable	nColShade  = str2num( UFCom_RemoveWhiteSpace( StringFromList( c, lstColShades ) ) ) 
		if ( nColShade )
			ModifyTable /W = $sTableNm  rgb[ c + 1 ] = ( 0, 0, 65535 )
		endif
	endfor
End


Function		UFCom_FindRow( wDB, sFind, nColFind )
// Returns  row  in which   'sFind'  is found in column  'nColFind'  or  'UFCom_kNOTFOUND' = -1
	wave 	/T	wDB
	string  	sFind
	variable	nColFind
	variable	code		= UFCom_kNOTFOUND
	variable	n , nRows	= DimSize( wDB, 0 )
	for ( n = 0; n < nRows; n += 1 )
		if ( cmpstr( wDB[ n ][ nColFind ], sFind ) == 0 )
			code = n
			break														// 'sFind' exists already in row 'n'		
		endif
	endfor
	// printf "\t\tUFCom_FindRow(\tsFind:\t%s\t)\thas been found in column %3d in row:  %d \r", UFCom_pd( sFind, 19),  nColFind, code
	return	code
End

Function		UFCom_MarkRow( wDB, nRow, sTableNm, nMarkColumn, sMarker )
// Marks  'nRow'   in table 'sTableNm'  by filling 'nMarkColumn'  with 'sMarker' .  Disadvantage: An extra  column just for the marker must be introduced.
// !!! 061221 Could not be made to work without this extra marker column : The code [ DoWindow /F $sTableNm;  ModifyTable/W = $sTableNm	selection = ( nRow,  0,  nRow,  0,  nRow, 0 )  does NOT work...
// ...because activating this table (required for 'selection' to work)  swallows the 'MouseDown' event  in  the hook function of the calling table (e.g. 'tbSecu')  IF this 'sTableNm' OVERLAPS the calling table (e.g. 'tbSecu') !!!
	wave 	/T	wDB
	variable	nRow, nMarkColumn
	string  	sTableNm, sMarker
	variable	nCols	= DimSize( wDB, 1 )

	// Unfortunately the following code does NOT work:
	//DoWindow /F $sTableNm										 // must first be brought to front for the following 'ModifyTable selection' to work BUT with this the hook function of the calling table FAILS !
	// ModifyTable	/W = $sTableNm  selection = ( nRow, 0, nRow, nCols-1,nRow, 0 ) // inverts entire row to black
	// ModifyTable	/W = $sTableNm  selection = ( nRow, 0, nRow, 0,  	  nRow, 0 ) // marks only cell in column 0 

	wDB[  	 ][ nMarkColumn ]  = ""									 // clear the entire column								
	wDB[nRow][ nMarkColumn ]  = sMarker
	ModifyTable	/W = $sTableNm	TopLeftCell = ( nRow,  0 )  				// scroll table contents so that the selected row is the top visible row
	// printf "\t\tUFCom_MarkRow(\tTable:\t%s\t)\tSelecting row %3d ( cols: %d ) \r", UFCom_pd( sTableNm, 19),  nRow, nCols
End


Function		UFCom_MarkRowNoScroll( wDB, nRow, sTableNm, nMarkColumn, sMarker )
// Marks  'nRow'   in table 'sTableNm'  by filling 'nMarkColumn'  with 'sMarker' .  Disadvantage: An extra  column just for the marker must be introduced.
// !!! 061221 Could not be made to work without this extra marker column : The code [ DoWindow /F $sTableNm;  ModifyTable/W = $sTableNm	selection = ( nRow,  0,  nRow,  0,  nRow, 0 )  does NOT work...
// ...because activating this table (required for 'selection' to work)  swallows the 'MouseDown' event  in  the hook function of the calling table (e.g. 'tbSecu')  IF this 'sTableNm' OVERLAPS the calling table (e.g. 'tbSecu') !!!
	wave 	/T	wDB
	variable	nRow, nMarkColumn
	string  	sTableNm, sMarker
	variable	nCols	= DimSize( wDB, 1 )

	// Unfortunately the following code does NOT work:
	//DoWindow /F $sTableNm										 // must first be brought to front for the following 'ModifyTable selection' to work BUT with this the hook function of the calling table FAILS !
	// ModifyTable	/W = $sTableNm  selection = ( nRow, 0, nRow, nCols-1,nRow, 0 ) // inverts entire row to black
	// ModifyTable	/W = $sTableNm  selection = ( nRow, 0, nRow, 0,  	  nRow, 0 ) // marks only cell in column 0 

	wDB[  	 ][ nMarkColumn ]  = ""									 // clear the entire column								
	wDB[nRow][ nMarkColumn ]  = sMarker
//	ModifyTable	/W = $sTableNm	TopLeftCell = ( nRow,  0 )  				// scroll table contents so that the selected row is the top visible row
	// printf "\t\tUFCom_MarkRowNoScroll(\tTable:\t%s\t)\tSelecting row %3d ( cols: %d ) \r", UFCom_pd( sTableNm, 19),  nRow, nCols
End


Function		UFCom_MarkRowViewPreceding( wDB, nRow, sTableNm, nMarkColumn, sMarker, nTopRows )
// Marks  'nRow'   in table 'sTableNm'  by filling 'nMarkColumn'  with 'sMarker' .  Disadvantage: An extra  column just for the marker must be introduced.
// !!! 061221 Could not be made to work without this extra marker column : The code [ DoWindow /F $sTableNm;  ModifyTable/W = $sTableNm	selection = ( nRow,  0,  nRow,  0,  nRow, 0 )  does NOT work...
// ...because activating this table (required for 'selection' to work)  swallows the 'MouseDown' event  in  the hook function of the calling table (e.g. 'tbSecu')  IF this 'sTableNm' OVERLAPS the calling table (e.g. 'tbSecu') !!!
	wave 	/T	wDB
	variable	nRow, nMarkColumn, nTopRows
	string  	sTableNm, sMarker
	variable	nCols	= DimSize( wDB, 1 )
	wDB[  	 ][ nMarkColumn ]  = ""									 // clear the entire column								
	wDB[nRow][ nMarkColumn ]  = sMarker
	ModifyTable	/W = $sTableNm	TopLeftCell = ( max( 0, nRow - nTopRows),  0 )  	// scroll table contents so that there are 'nTopRows' visible above the selected row 
	// printf "\t\tUFCom_MarkRowViewPreceding((\tTable:\t%s\t)\tSelecting row %3d ( cols: %d ) \r", UFCom_pd( sTableNm, 19),  nRow, nCols
End


Function		UFCom_MarkRowNum( wDB, nRow, sTableNm, nMarkColumn, nMarker )
// Marks  'nRow'   in table 'sTableNm'  by filling 'nMarkColumn'  with 'sMarker' .  Disadvantage: An extra  column just for the marker must be introduced.
// !!! 061221 Could not be made to work without this extra marker column : The code [ DoWindow /F $sTableNm;  ModifyTable/W = $sTableNm	selection = ( nRow,  0,  nRow,  0,  nRow, 0 )  does NOT work...
// ...because activating this table (required for 'selection' to work)  swallows the 'MouseDown' event  in  the hook function of the calling table (e.g. 'tbSecu')  IF this 'sTableNm' OVERLAPS the calling table (e.g. 'tbSecu') !!!
	wave 	wDB
	variable	nRow, nMarkColumn
	string  	sTableNm
	variable	nMarker
	variable	nCols	= DimSize( wDB, 1 )
	wDB[  	 ][ nMarkColumn ]  = 0									 // clear the entire column								
	wDB[nRow][ nMarkColumn ]  = nMarker
	ModifyTable	/W = $sTableNm	TopLeftCell = ( nRow,  0 )  				// scroll table contents so that the selected row is the top visible row
	// printf "\t\tUFCom_MarkRow(\tTable:\t%s\t)\tSelecting row %3d ( cols: %d ) \r", UFCom_pd( sTableNm, 19),  nRow, nCols
End


Function		UFCom_MarkRowNoScrollNum( wDB, nRow, sTableNm, nMarkColumn, nMarker )
// Marks  'nRow'   in table 'sTableNm'  by filling 'nMarkColumn'  with 'sMarker' .  Disadvantage: An extra  column just for the marker must be introduced.
// !!! 061221 Could not be made to work without this extra marker column : The code [ DoWindow /F $sTableNm;  ModifyTable/W = $sTableNm	selection = ( nRow,  0,  nRow,  0,  nRow, 0 )  does NOT work...
// ...because activating this table (required for 'selection' to work)  swallows the 'MouseDown' event  in  the hook function of the calling table (e.g. 'tbSecu')  IF this 'sTableNm' OVERLAPS the calling table (e.g. 'tbSecu') !!!
	wave 	wDB
	variable	nRow, nMarkColumn
	string  	sTableNm
	variable	nMarker
	variable	nCols	= DimSize( wDB, 1 )
	wDB[  	 ][ nMarkColumn ]  = 0									 // clear the entire column								
	wDB[nRow][ nMarkColumn ]  = nMarker
//	ModifyTable	/W = $sTableNm	TopLeftCell = ( nRow,  0 )  				// scroll table contents so that the selected row is the top visible row
	// printf "\t\tUFCom_MarkRowNoScroll(\tTable:\t%s\t)\tSelecting row %3d ( cols: %d ) \r", UFCom_pd( sTableNm, 19),  nRow, nCols
End


Function		UFCom_MarkRowViewPrecedingNum( wDB, nRow, sTableNm, nMarkColumn, nMarker, nTopRows )
// Marks  'nRow'   in table 'sTableNm'  by filling 'nMarkColumn'  with 'sMarker' .  Disadvantage: An extra  column just for the marker must be introduced.
// !!! 061221 Could not be made to work without this extra marker column : The code [ DoWindow /F $sTableNm;  ModifyTable/W = $sTableNm	selection = ( nRow,  0,  nRow,  0,  nRow, 0 )  does NOT work...
// ...because activating this table (required for 'selection' to work)  swallows the 'MouseDown' event  in  the hook function of the calling table (e.g. 'tbSecu')  IF this 'sTableNm' OVERLAPS the calling table (e.g. 'tbSecu') !!!
	wave 	wDB
	variable	nRow, nMarkColumn, nTopRows
	string  	sTableNm
	variable	nMarker
	variable	nCols	= DimSize( wDB, 1 )
	wDB[  	 ][ nMarkColumn ]  = 0									 // clear the entire column								
	wDB[nRow][ nMarkColumn ]  = nMarker
	ModifyTable	/W = $sTableNm	TopLeftCell = ( max( 0, nRow - nTopRows),  0 )  	// scroll table contents so that there are 'nTopRows' visible above the selected row 
	// printf "\t\tUFCom_MarkRowViewPreceding((\tTable:\t%s\t)\tSelecting row %3d ( cols: %d ) \r", UFCom_pd( sTableNm, 19),  nRow, nCols
End


Function		UFCom_JumpRowViewPreceding( wDB, nRow, sTableNm, nTopRows )
	wave 	wDB
	variable	nRow, nTopRows
	string  	sTableNm
	variable	nCols	= DimSize( wDB, 1 )
	ModifyTable	/W = $sTableNm	TopLeftCell = ( max( 0, nRow - nTopRows),  0 )  	// scroll table contents so that there are 'nTopRows' visible above the selected row 
	// printf "\t\tUFCom_JumpRowViewPreceding((\tTable:\t%s\t)\tSelecting row %3d ( cols: %d ) \r", UFCom_pd( sTableNm, 19),  nRow, nCols
End







Function		UFCom_SortDatabase( sFolder, sDBNm, nPrimSortCol, nOrder )
// Sort the data base  'sDBNm'   according to 'PrimSortCol' .  If not primarily sorting column 0  then column 0 is used as a secondary sorting index.
	string  	sFolder, sDBNm
	variable	nPrimSortCol, nOrder
	wave 	/T  wt  = $UFCom_ksROOT_UF_ + sFolder + sDBNm
	string  	lstColumns	 = SelectString( 	nPrimSortCol == 0 ,  num2str( nPrimSortCol ) + ";0;" ,  num2str( nPrimSortCol ) 	) //  If not primarily sorting column 0  then column 0 is used as a secondary sorting index.
	UFCom_SortByColumnList( wt, lstColumns, nOrder, UFCom_kSORTNORMAL )
End	


Function		UFCom_SortDatabaseAlphaNum( sFolder, sDBNm, nPrimSortCol, nOrder )
// Sort the data base  'sDBNm'   according to 'PrimSortCol' .  If not primarily sorting column 0  then column 0 is used as a secondary sorting index.
	string  	sFolder, sDBNm
	variable	nPrimSortCol, nOrder
	wave 	/T  wt  = $UFCom_ksROOT_UF_ + sFolder + sDBNm
	string  	lstColumns	 = SelectString( 	nPrimSortCol == 0 ,  num2str( nPrimSortCol ) + ";0;" ,  num2str( nPrimSortCol ) 	) //  If not primarily sorting column 0  then column 0 is used as a secondary sorting index.
	UFCom_SortByColumnList( wt, lstColumns, nOrder, UFCom_kSORT_ALPHA_NUM_CASE_I )
End	


// 070806 wDB numerical
Function		UFCom_SortByColumnListNumerical( wt, lstColumns, nOrder )
// Sort   2dim  numerical wave  by any number of arbitrary columns.
	wave  	wt
	string  	lstColumns										// after which will be sorted		
	variable	nOrder										// +1 : fixed order ascending,   -1: fixed order descending,   0 : toggle = invert order

	lstColumns	= UFCom_RemoveDoubleEntries( lstColumns, ";" )		// Remove identical columns in 'lstColumns'  (e.g. '2;2;7;' )  as  Execute below will fail. 
	variable	SortColIdx, nSortColumns	= ItemsInList( lstColumns )

	// Igor cannot reasonably sort the 2dim wave, so we....
	variable	n, nRows	= DimSize( wt, 0 )
	variable	c, nCols	= DimSize( wt, 1 )

	Make   /O /I /U   /N = (nRows)   wSortIndx						// wSortIndx should be unsigned long for 'FindValue' below

	// ...split it into multiple 1dim waves, 1 for each column, 
	for ( c = 0; c < nCols; c += 1 )
		Make /O   /N = (nRows)	$("wTmp" + num2str( c ) )
		wave	wTmp	= 	$("wTmp" + num2str( c ) )
		wTmp	= wt[ p ][ c ]						

		// ...the column after which will be sorted has a special name and must be an extra wave, not only a reference... 
		//... because we want the umlaut replacements Ae Oe Ue  only temporarily as a sorting index but we don't want to change the data base with the umlaut replacements . 
		SortColIdx	= WhichListItem( num2str( c ), lstColumns )					// e.g. lstColumns = "7;4;"  -> 'wSort0' contains data of column 7   and  'wSort1' contains data of column 4
		if ( SortColIdx != UFCom_kNOTFOUND )
			Make /O   /N = (nRows)    $("wSort" + num2str( SortColIdx ) )
			wave		wSort   =	$("wSort" + num2str( SortColIdx ) )
// 070806 wDB numerical    SIMPLIFY???
			wSort	= wTmp
		endif
	endfor

	if ( nOrder == UFCom_kSORTACTION_TOGGLE )						// toggle = invert  the current sorting order
		wave		wSort	= $("wSort0" )							// !!! use primary sorting column for determination of sorting order
//		string  	lstDummy		= wSort[ 0 ] + ";" + wSort[ nRows - 1] + ";"		// create a list consisting only of the first and last item of the column to be sorted....
//		string		lstDummyAlNum	= SortList( lstDummy, ";",  nMode )			//...and sort this list according to 'nMode' which can be normal or alphanumerical....
//		variable	nOrderByLst	= cmpstr( lstDummy, 	lstDummyAlNum )		// A simple string compare 'cmpstr'  which does not take the alphanumerical sorting order into account will produce wrong results!
//		nOrder =  -1 + 2 * nOrderByLst* nOrderByLst 						// empirical 'nOrder'  gives the correct sorting also for alpanumerical sorting : nOrderByLst +1 or -1  -> nOrder= +1,  nOrderByLst 0  -> nOrder = -1   
//		//printf "\t\t\tPrimSC:%d\tRows:%d\tw[0]:\t%s\tw[last]:\t%s\t-> \tSimple non-AN cmpstr gives Order: %d\t  OrderByLst:%d\t->AN-Order: %d\tDuOrg: %s\t ->\tDuAN: %s \r", StringFromList(0, lstColumns), nRows,  UFCom_pd(wSort[ 0 ],11) ,  UFCom_pd(wSort[ nRows - 1],11) , cmpstr( wSort[ 0 ] , wSort[ nRows - 1] ) , nOrderByLst, nOrder,  UFCom_pd(lstDummy,13),  lstDummyAlNum

		variable nOrderByWave  = -1 + 2 * (wSort[ 0 ] < wSort[ nRows - 1]) 		// crompare the first and last item of the column to be sorted ( gives  -1  or +1 )....
		nOrder 	= ( ( nOrder == 0 )  ?  -1  :  nOrder  ) *  nOrderByWave
		//printf "\t\t\tPrimSC:%s\tRows:%d\tw[0]:\tnOrder:%d  [nOrderByWave:%d]\r", StringFromList(0, lstColumns), nRows,  nOrder, nOrderByWave
	endif

	// ...create the index wave after which will be sorted						 < 1us
	string  	sCmd, sFlags, sWaves	= "{"
	
	for ( c = 0;  c < nSortColumns;  c += 1 )
		sWaves 	+=  "wSort" + num2str( c ) + ","
	endfor
	sWaves	= RemoveEnding( sWaves, "," )  + "},"						// e.g. ' {wSort0,wSort1},  '

// 070806 wDB numerical   
//	if ( nMode == UFCom_kSORT_ALPHA_NUM_CASE_I )	
//		sFlags	= SelectString( nOrder >= 0, "/A/R", "/A" ) 					// alphanumerical sort, possibly reversed
//	else
		sFlags	= SelectString( nOrder >= 0, "/R", 	"" ) 					// default sort,  		possibly reversed
//	endif

	sCmd	= "MakeIndex  " + sFlags + sWaves + "wSortIndx"
	Execute sCmd
	// printf "\t\tUFCom_SortByColumnList(i)\t nOrder:%2d\tlstColumns:%2d\t'%s'\tRows:%d\tsCmd:\t'%s' \twSortIndex: %d [%s]   %d [%s]   %d  %d  %d   %d   %d   %d\r", nOrder, nSortColumns, lstColumns, nRows,  sCmd,  wSortIndx[0], w0[ wSortIndx[0] ], wSortIndx[1], w0[ wSortIndx[1] ], wSortIndx[2], wSortIndx[3],  wSortIndx[4], wSortIndx[5], wSortIndx[6], wSortIndx[7]

	// MilliSeconds = stopMSTimer( nTimer) / 1000;   Print "Sum till now \t", MilliSeconds, "\t  ms needed for SortByColumn()   rows:", nRows, MilliSeconds/nRows, "ms needed for SortByColumn() per row"; nTimer	= StartMSTimer

	//  Version 1
	// ...sort each column = each of the multiple 1dim waves
	for ( c = 0; c < nCols; c += 1 )
		wave		wTmp	= $("wTmp" + num2str( c ) ) 			
		IndexSort	wSortIndx, wTmp							// ~16 us
	endfor

	// ...and finally build together the 2dim wave from the sorted 1dim waves. Voila.
	for ( c = 0; c < nCols; c += 1 )
		// print "Sortcolumn()", c, nCols	
		wave		wTmp	= $("wTmp" + num2str( c ) )
		wt[ ][ c ]	= wTmp[ p ]								// ~35 200 us	2-dim wave arithmetics is in this case  NOT  faster than a  2-dim loop!  Store into all rows, column c
		killWaves	wTmp
	endfor

	for ( c = 0;  c < nSortColumns;  c += 1 )
		//wave	 /Z /T wSort	= $("wSort" + num2str( c ) )
		//killWaves /Z wSort									// /Z to avoid error when there are identical sorting columns (should be caught earlier...)
		wave		wSort	= $("wSort" + num2str( c ) )
		killWaves		wSort									// there must be no identical sorting columns
	endfor

End


Function		UFCom_SortByColumnList( wt, lstColumns, nOrder, nMode )
// Sort   2dim  text wave  by any number of arbitrary columns.
// Includes  Umlaut sorting which slows down the sorting a bit but not much.  Todo:  make Umlaut sorting optional.
// The sorting process may extremely slow down  if any of the columns contains a large string (10...30kB) . For this case the times given are per row for 1.6GHz,  20 columns, 900 rows -> yielding  ~40 seconds!     
// If the column with the large string is deleted (and 19 columns with small strings, each ~20 bytes are left over) the sorting speed increases by about a factor of 10...50 !

// todo: Check that there are no identical columns in 'lstColumns'   (e.g. '2;2;7;'  or  '2;7;2;' is forbidden)  as  Execute below will fail..... [Do not change order of entries]
	wave  /T	wt
	string  	lstColumns										// after which will be sorted		
	variable	nOrder										// +1 : fixed order ascending,   -1: fixed order descending,   0 : toggle = invert order
	variable	nMode

	lstColumns	= UFCom_RemoveDoubleEntries( lstColumns, ";" )		// Remove identical columns in 'lstColumns'  (e.g. '2;2;7;' )  as  Execute below will fail. 
	variable	SortColIdx, nSortColumns	= ItemsInList( lstColumns )

	// Igor cannot reasonably sort the 2dim wave, so we....
	variable	n, nRows	= DimSize( wt, 0 )
	variable	c, nCols	= DimSize( wt, 1 )
	// variable	nTimer, MilliSeconds = stopMSTimer( nTimer) / 1000;   Print "Start   ", MilliSeconds, "\t  ms needed for SortByColumn()   rows:", nRows, MilliSeconds/nRows, "ms needed for SortByColumn() per row"; nTimer	= StartMSTimer

	//Make   /O      	     /N = (nRows)   wSortIndx
	Make   /O /I /U   /N = (nRows)   wSortIndx						// wSortIndx should be unsigned long for 'FindValue' below

	// ...split it into multiple 1dim waves, 1 for each column, 
	for ( c = 0; c < nCols; c += 1 )
		Make /O /T  /N = (nRows)    $("wTmp" + num2str( c ) )
		wave	/T	wTmp	= $("wTmp" + num2str( c ) )
		wTmp	= wt[ p ][ c ]								// ~700 us     2-dim wave arithmetics is in this case  NOT  faster than  2-dim loop : for(n=0;n<nRows;n+=1)    wTmp[n]=wt[n][c]    endfor

		// ...the column after which will be sorted has a special name and must be an extra wave, not only a reference... 
		//... because we want the umlaut replacements Ae Oe Ue  only temporarily as a sorting index but we don't want to change the data base with the umlaut replacements . 
		SortColIdx	= WhichListItem( num2str( c ), lstColumns )					// e.g. lstColumns = "7;4;"  -> 'wSort0' contains data of column 7   and  'wSort1' contains data of column 4
		if ( SortColIdx != UFCom_kNOTFOUND )
			Make /O /T  /N = (nRows)    $("wSort" + num2str( SortColIdx ) )
			wave	/T	wSort	= $("wSort" + num2str( SortColIdx ) )

			UFCom_ConvertUmlauteWv( wTmp, wSort )
			ConvertGermanDateWv( wSort, wSort )

//			ConvertGermanDateWv( wTmp, wSort )
//			UFCom_ConvertUmlauteWv( wSort, wSort )

		endif
	endfor

	// wave	/T	w0	= wSort0
	// if ( nSortColumns > 1 )
	// wave	/T	w1	= wSort1
	// printf "\t\tUFCom_SortByColumnList(c)\t nOrder:%2d\tlstColumns:%2d\t'%s'\tRows:%d\twSort0: %s  %s  %s  %s  \twSort1: %s  %s  %s  %s  \r", nOrder, nSortColumns, lstColumns, nRows,  w0[0], w0[1], w0[2], w0[3],  w1[0], w1[1], w1[2], w1[3]
	// else
	// printf "\t\tUFCom_SortByColumnList(d)\t nOrder:%2d\tlstColumns:%2d\t'%s'\tRows:%d\twSort0: %s  %s  %s  %s  %s  %s  %s  %s  \r", nOrder, nSortColumns, lstColumns, nRows,  w0[0], w0[1], w0[2], w0[3],  w0[4], w0[5], w0[6], w0[7]
	// endif
	
	if ( nOrder == UFCom_kSORTACTION_TOGGLE )						// toggle = invert  the current sorting order
		wave	/T	wSort	= $("wSort0" )							// !!! use primary sorting column for determination of sorting order
		// nOrder	= cmpstr( wSort[ 0 ] , wSort[ nRows - 1] ) 				// old non-alpha-numerical sort is WRONG.  Is it currently sorted up or down?
		string  	lstDummy		= wSort[ 0 ] + ";" + wSort[ nRows - 1] + ";"		// create a list consisting only of the first and last item of the column to be sorted....
		string		lstDummyAlNum	= SortList( lstDummy, ";",  nMode )			//...and sort this list according to 'nMode' which can be normal or alphanumerical....
		variable	nOrderByLst	= cmpstr( lstDummy, 	lstDummyAlNum )		// A simple string compare 'cmpstr'  which does not take the alphanumerical sorting order into account will produce wrong results!
		nOrder =  -1 + 2 * nOrderByLst* nOrderByLst 						// empirical 'nOrder'  gives the correct sorting also for alpanumerical sorting : nOrderByLst +1 or -1  -> nOrder= +1,  nOrderByLst 0  -> nOrder = -1   
		printf "\t\t\tPrimSC:%d\tRows:%d\tw[0]:\t%s\tw[last]:\t%s\t-> \tSimple non-AN cmpstr gives Order: %d\t  OrderByLst:%d\t->AN-Order: %d\tDuOrg: %s\t ->\tDuAN: %s \r", StringFromList(0, lstColumns), nRows,  UFCom_pd(wSort[ 0 ],11) ,  UFCom_pd(wSort[ nRows - 1],11) , cmpstr( wSort[ 0 ] , wSort[ nRows - 1] ) , nOrderByLst, nOrder,  UFCom_pd(lstDummy,13),  lstDummyAlNum
	endif

	// ...create the index wave after which will be sorted						 < 1us
	string  	sCmd, sFlags, sWaves	= "{"
	
	for ( c = 0;  c < nSortColumns;  c += 1 )
		sWaves 	+=  "wSort" + num2str( c ) + ","
	endfor
	sWaves	= RemoveEnding( sWaves, "," )  + "},"						// e.g. ' {wSort0,wSort1},  '

	if ( nMode == UFCom_kSORT_ALPHA_NUM_CASE_I )	
		sFlags	= SelectString( nOrder >= 0, "/A/R", "/A" ) 					// alphanumerical sort, possibly reversed
	else
		sFlags	= SelectString( nOrder >= 0, "/R", 	"" ) 					// default sort,  		possibly reversed
	endif

	sCmd	= "MakeIndex  " + sFlags + sWaves + "wSortIndx"
	Execute sCmd
	// printf "\t\tUFCom_SortByColumnList(i)\t nOrder:%2d\tlstColumns:%2d\t'%s'\tRows:%d\tsCmd:\t'%s' \twSortIndex: %d [%s]   %d [%s]   %d  %d  %d   %d   %d   %d\r", nOrder, nSortColumns, lstColumns, nRows,  sCmd,  wSortIndx[0], w0[ wSortIndx[0] ], wSortIndx[1], w0[ wSortIndx[1] ], wSortIndx[2], wSortIndx[3],  wSortIndx[4], wSortIndx[5], wSortIndx[6], wSortIndx[7]

	// MilliSeconds = stopMSTimer( nTimer) / 1000;   Print "Sum till now \t", MilliSeconds, "\t  ms needed for SortByColumn()   rows:", nRows, MilliSeconds/nRows, "ms needed for SortByColumn() per row"; nTimer	= StartMSTimer

	//  Version 1
	// ...sort each column = each of the multiple 1dim waves
	for ( c = 0; c < nCols; c += 1 )
		wave	/T	wTmp	= $("wTmp" + num2str( c ) ) 			
		IndexSort	wSortIndx, wTmp							// ~16 us
	endfor

	// ...and finally build together the 2dim wave from the sorted 1dim waves. Voila.
	for ( c = 0; c < nCols; c += 1 )
		// print "Sortcolumn()", c, nCols	
		wave	/T	wTmp	= $("wTmp" + num2str( c ) )
		wt[ ][ c ]	= wTmp[ p ]								// ~35 200 us	2-dim wave arithmetics is in this case  NOT  faster than a  2-dim loop!  Store into all rows, column c
		killWaves	wTmp
	endfor

	for ( c = 0;  c < nSortColumns;  c += 1 )
		//wave	 /Z /T wSort	= $("wSort" + num2str( c ) )
		//killWaves /Z wSort									// /Z to avoid error when there are identical sorting columns (should be caught earlier...)
		wave	/T	wSort	= $("wSort" + num2str( c ) )
		killWaves		wSort									// there must be no identical sorting columns
	endfor

//	//  Version 2
//	// ...sort each column = each of the multiple 1dim waves
//	for ( c = 0; c < nCols; c += 1 )
//		wave	/T	wTmp	= $("wTmp" + num2str( c ) ) 			
//		IndexSort	wSortIndx, wTmp							// ~16 us
//	endfor
//
//	// ...and finally build together the 2dim wave from the sorted 1dim waves. Voila.
//	for ( c = 0; c < nCols; c += 1 )
//		wave	/T	wTmp	= $("wTmp" + num2str( c ) )
//		for ( n = 0; n < nRows; n += 1 )
//			wt[ n ][ c ] = wTmp[ n ]							// ~35 000 us
//		endfor
//		killWaves	wTmp
//	endfor


//	//  Version 3
//	// ...sort each column = each of the multiple 1dim waves
// print "Version3 nCols:",  nCols
//	for ( c = 0; c < nCols; c += 1 )
//		wave	/T	wTmp	= $("wTmp" + num2str( c ) ) 			
//		IndexSort	wSortIndx, wTmp							// ~16 us
//	endfor
//
//	// ...and finally build together the 2dim wave from the sorted 1dim waves. Voila.
//	for ( n = 0; n < nRows; n += 1 )
//		for ( c = 0; c < nCols; c += 1 )
//			wave	/T	wTmp	= $("wTmp" + num2str( c ) )
//			wt[ n ][ c ] = wTmp[ n ]							// ~35 000 us
//		endfor
//	endfor
//
//	for ( c = 0; c < nCols; c += 1 )
//		wave	/T	wTmp	= $("wTmp" + num2str( c ) )
//		killWaves	wTmp
//	endfor


//	// Version 4
//	 make	/O  /T  /N=( nRows, nCols )	wt2
//
//	for ( n = 0; n < nRows; n += 1 )
//		variable	index	= wSortIndx[ n ]
//		wt2[ n ][ ] = wt[ index ][ q ]								// ~55 000 us  works but is even slower....
//	endfor
//	 wt = wt2
//	 killwaves wt2


//	// Version 5		???? findvalue works but will this be faster ???
//	for ( n = 0; n < nRows; n += 1 )
//		FindValue	/U=(n)		wSortIndx					// wSortIndx is unsigned long
//		if ( V_value == UFCom_kNOTFOUND )
//			print "Error:  SortByColumn  FindValue  NOTFOUND  n:", n, V_value	
//		else
//			print "\t n:", n, V_value	
//		endif
//	endfor
//	wt = wt2
// 	killwaves wt2

//MilliSeconds = stopMSTimer( nTimer) / 1000;   Print "Building....... \t", MilliSeconds, "\t  ms needed for SortByColumn()   rows:", nRows, MilliSeconds/nRows, "ms needed for SortByColumn() per row"; nTimer	= StartMSTimer

End

//------------------------------------------------------------------------------------------------------------------------------------------------------------------
//  SEARCHING THE DATA BASE

Function		UFCom_Search( lstSearch, bWholeWord, bCaseSensitive, sSep, sDBNm, sDBNmExtr, lstSearchCols, lstColNames, lstColWidth )
	string  	lstSearch
	variable	bWholeWord
	variable	bCaseSensitive	
	string 	sSep			
	string 	sDBNm	
	string 	sDBNmExtr	
	string  	lstSearchCols	
	string  	lstColNames
	string  	lstColWidth

	wave 	/T	wDB		= $sDBNm
	
	// Step 1: Find all rows containing the keywords 'lstSearch'
	string  	lstRowsFound	= UFCom_SearchDB( lstSearch, bWholeWord, bCaseSensitive, sSep, wDB, lstSearchCols )

	// Step 2: Now do something useful with the rows found...
	variable	n, nExtractedRows	= ItemsInList( lstRowsFound )
	for ( n = 0; n < nExtractedRows; n += 1 )
		variable	nOrow	= str2num( StringFromList( n, lstRowsFound ) )
		variable	nRow	= UFCom_RedimDBWave( sDBNmExtr, lstColNames + "ORow;" , lstColWidth + "40;" )  // !!! Assumption  do not change....
		wave 	/T	wDBExtr	= $sDBNmExtr
		variable	c, nCols	= ItemsInList( lstColNames )
		for ( c = 0; c < nCols; c += 1 )
			wDBExtr[ nRow ][ c ] = wDB[ nORow ][ c ] 
		endfor
		wDBExtr[ nRow ][ c ] = num2str(  nORow )
	endfor
End

Function	/S	UFCom_SearchDB( lstSearch, bWholeWord, bCaseSensitive, sSearchSep, wDB, lstColumnsToSearch)
// todo : 'whole word'  , combined words 'LF 356',  also case-sensitive (easy:strsearch param 0) ,  more elegant...., feed to table 
	string  	lstSearch								// the user input search string list : space separated but may contain more than 1 space between words
	variable	bWholeWord, bCaseSensitive
	string  	sSearchSep
	wave  /T	wDB
	string  	lstColumnsToSearch

	string  	lstSearchClean	= ""
	string  	sSearch0 		= "", sSearch1 = "", sSearch2 = ""
	
	// Remove multiple spaces : Collapse to 1 separator
	variable	ns, nSearch	= ItemsInList( lstSearch, " " )						// may be too many e.g. 'ab    cd'  will be broken into  'ab'  ' '  ' '  'cd'
	for ( ns = 0; ns < nSearch; ns += 1 )
		if ( strlen( UFCom_RemoveOuterWhiteSpace( StringFromList( ns, lstSearch, " " ) ) ) )
			lstSearchClean	+= StringFromList( ns, lstSearch, " " ) + sSearchSep		//  'sSearchSep'  (e.g. '|')  is any arbitrary separator but it must not be conatained in the data base entries
		endif
	endfor

	nSearch	= ItemsInList( lstSearchClean, sSearchSep )							// -> 'ab|dc|'
	printf "\t\tUFCom_SearchDB()  has input  %d items: '%s'  [searching max 3]\r", nSearch, lstSearchClean

	if ( nSearch > 0 )
		sSearch0 = UFCom_RemoveOuterWhiteSpace( StringFromList( 0, lstSearchClean, sSearchSep ) )    
	endif
	if ( nSearch > 1 )
		sSearch1 = UFCom_RemoveOuterWhiteSpace( StringFromList( 1, lstSearchClean, sSearchSep ) )  
	endif
	if ( nSearch > 2 )
		sSearch2 = UFCom_RemoveOuterWhiteSpace( StringFromList( 2, lstSearchClean, sSearchSep ) )  
	endif

	variable	n, nRows	= DimSize( wDB, 0 )
	string  	sDataSet

	variable c, nColsToSearch	= ItemsInList( lstColumnsToSearch )

	string 	lstMatchingRows	= ""
	for ( n = 0; n < nRows; n += 1 )
		sDataSet	= ""
		for ( c = 0; c < nColsToSearch; c += 1 )
			sDataSet	+= " " + wDB[ n ][ str2num( StringFromList( c, lstColumnsToSearch ) ) ]  + " "
		endfor
		 
		if ( nSearch == 1 )
			if ( UFCom_GrepString( sDataSet, sSearch0, bCaseSensitive, bWholeWord ) )
				lstMatchingRows	+= num2str( n ) + ";"
				// printf "\t\tUFCom_SearchDB()  has input  %d items: '%s'   :  Match\t%5d\tfound in row \t%4d\t\t%s  \r", nSearch, sSearch0, 						ItemsInList( lstMatchingRows ) , n,  sDataSet//wDB[ n ][ kBEST_SUPPLIER ],  UFCom_pd( sBestNr, 15), sDesc
			endif
		endif
		if ( nSearch == 2 )
			if ( UFCom_GrepString( sDataSet, sSearch0, bCaseSensitive, bWholeWord )  && UFCom_GrepString( sDataSet, sSearch1, bCaseSensitive, bWholeWord ) )
				lstMatchingRows	+= num2str( n ) + ";"
				// printf "\t\tUFCom_SearchDB()  has input  %d items: '%s'  '%s'  :  Match\t%5d\tfound in row \t%4d\t\t%s  \r", nSearch, sSearch0,  sSearch1,			ItemsInList( lstMatchingRows ) , n,  sDataSet//wDB[ n ][ kBEST_SUPPLIER ],  UFCom_pd( sBestNr, 15), sDesc
			endif
		endif
		if ( nSearch == 3 )
			if ( UFCom_GrepString( sDataSet, sSearch0, bCaseSensitive, bWholeWord )  && UFCom_GrepString( sDataSet, sSearch1, bCaseSensitive, bWholeWord )  && UFCom_GrepString( sDataSet, sSearch2, bCaseSensitive, bWholeWord ) )
				lstMatchingRows	+= num2str( n ) + ";"
				// printf "\t\tUFCom_SearchDB()  has input  %d items: '%s'  '%s'  '%s'  :  Match\t%5d\tfound in row \t%4d\t\t%s  \r", nSearch, sSearch0, sSearch1, sSearch2,	ItemsInList( lstMatchingRows ) , n,  sDataSet//wDB[ n ][ kBEST_SUPPLIER ],  UFCom_pd( sBestNr, 15), sDesc
			endif
		endif

	endfor
	// printf "\t\tGrep-Searching for '%s'  '%s'  '%s'   [max 3]    '%s'   :  Found  %s  matches. \r", sSearch0, sSearch1, sSearch2, sRegExpr0, SelectString( nMatch > 0, "no" , num2str( ItemsInList( lstMatchingRows ) )
	return	lstMatchingRows
End	


Function		UFCom_SaveDataBase( sPath, sFileNm, sBaseF, sFolder, lstWantWavesNm )
// Store  list of arbitrary  waves . It is possible to store a mix of text, number, 1dim, 2dim waves in 1 file. 
// However, it is recommended to store 1 wave per file as the loading of a mix of waves may pose problems or not work at all. 
// !!! 'sPath'  can be a normal path (e.g. 'C:dir1:dir2:'  or the string name of a symbolic path (e.g.  'sSymbPath'  or  'ksMYDATAPATH' ) .  The distinction between the 2 is the colon. 
// !!! Cave  If this proves to be too fragile  instead of  'IsSymbolicPath()'  an additional boolean 'bIsSymb' could be passed to 'SaveDataBase()' .
	string  	sPath
	string  	sFileNm, sBaseF, sFolder, lstWantWavesNm
	variable	n, nWantWaves= ItemsInList( lstWantWavesNm )
	string 	sWantWave
	string  	lstWaves = ""
	for ( n = 0; n < nWantWaves; n += 1 )
		lstWaves	= AddListItem( sBaseF + sFolder + StringFromList( n, lstWantWavesNm ) , lstWaves, ";", inf ) 
	endfor
	string 	sPathFile = ""
	variable	bIsSymbolicPath	= UFCom_IsSymbolicPath( sPath )
	if ( bIsSymbolicPath )
		save /O /T /B  	/P=$sPath  lstWaves  as sFileNm	
		PathInfo	/S 	$sPath;  	sPathFile	= S_Path + sFileNm		// only for debug print below 
	else
	 	sPathFile	= sPath + sFileNm		
		save /O /T /B  		lstWaves  as sPathFile
	endif

	if ( UFCom_DebugVar( "ComSaveDataBase" ) )
		 printf "\t\tSaveDatabase(  [%s path]\t%s\t%s\t%s\t%s\t%s\t )  save waves\t%s\tinto file '%s' \r" , SelectString( bIsSymbolicPath, "normal", "symbolic" ),  UFCom_pd( sPath,13),  UFCom_pd( sFileNm,25),  UFCom_pd( sBaseF,7),  UFCom_pd(  sFolder,7),  UFCom_pd( lstWantWavesNm, 19),  UFCom_pd(lstWaves,23), sPathFile
	endif
End




Function		UFCom_IsSymbolicPath( sPath )
// sPath  can be a normal path (e.g. 'C:dir1:dir2:'  or the string name of a symbolic path (e.g.  'sSymbPath'  or  'ksMYDATAPATH' ) .  The distinction between the 2 is the colon. 
// !!!  Cave   If this proves to be too fragile  instead of  'IsSymbolicPath()'  an additional boolean 'bIsSymb' could be passed to 'SaveDataBase()' .
	string   	sPath
	return	( strsearch( sPath, ":", 0 )  == UFCom_kNOTFOUND )  ?  UFCom_TRUE  :  UFCom_FALSE
End	


Function		UFCom_CompactDatabase_( sBaseF, sFolder, sDBNm, nCompactByColumn )
// Deletes any data base entries whose 'nCategoryColumn' entry is empty
	string  	sBaseF, sFolder, sDBNm
	variable	nCompactByColumn
	variable	n
	wave  /T	wDB		= $sBaseF + sFolder + sDBNm
	variable	nItems	= DimSize( wDB, 0 )
	printf "\r\t\t\tCompactDatabase( %s , %s, %d )  Entries : % 3d ) \t", sFolder, sDBNm, nCompactByColumn, nItems
	for ( n = 0; n < nItems; n += 1 )
 		if ( strlen( wDB[ n ][ nCompactByColumn ] ) == 0 )
			// printf "\t\t\t\t%3d /%4d\t%s\t%s\t%s \r", n+1, nItems, UFCom_pad( wDB[ n ][ 0 ] , 15 ) , wDB[ n ][ 1 ]  , wDB[ n ][ 2 ]  
			DeletePoints n , 1 , wDB 
			n		-= 1
			nItems	-= 1
		endif
	endfor
	printf "After Deleting empty entries : %d \r", DimSize( wDB, 0 )
End


Function		UFCom_DeleteDatabaseEntry_( sBaseF, sFolder, sDBNm, nRow )
// Deletes data base entry  row  'nRow'
	string  	sBaseF, sFolder, sDBNm
	variable	nRow
	wave  /T	wDB		= $sBaseF + sFolder + sDBNm
	DeletePoints nRow , 1 , wDB 
	variable	nItems	= DimSize( wDB, 0 )
	printf "\r\t\t\tDeleteDatabaseEntry( %s , %s, %d )  Entries (after deletion) : % 3d ) \r", sFolder, sDBNm, nRow, nItems
End

Function		UFCom_DeleteDatabaseEntry( wDB, nRow )
// Deletes data base entry  row  'nRow'
	wave  /T	wDB	
	variable	nRow
	DeletePoints nRow , 1 , wDB 
End

// untested and unused
//Function		UFCom_InsertDatabaseEntry_( sBaseF, sFolder, sDBNm, nRow )
//// Inserts data base entry  row  'nRow'
//	string  	sBaseF, sFolder, sDBNm
//	variable	nRow
//	wave  /T	wDB		= $sBaseF + sFolder + sDBNm
//	InsertPoints nRow , 1 , wDB 
//	variable	nItems	= DimSize( wDB, 0 )
//	printf "\r\t\t\tUFCom_InsertDatabaseEntry( %s , %s, %d )  Entries (after deletion) : % 3d ) \r", sFolder, sDBNm, nRow, nItems
//End



//==============================================================================================
//  CONVERTING A  2-DIM  DATABASE  (TEXT OR NUMERICAL)   INTO  1-DIM  NUMERICAL  WAVES

Function 		UFCom_IsValid( row )
// Dummy function prototype 
	variable	row
	print "in UFCom_IsValid with row= ", row		// Only dummy : never printed
End

Function		UFCom_Convert2DWaveTo1D( sSrcBaseF_, sSrcFolder_, sSrcWaveNm, sTgtFolderPath_, lstColumnNames, lstSkipColumns, fIsValid )
// Converts a 2-dimensional source wave located in 'sSrc...'  into many 1-dimensional waves stored in 'sTgtFolderPath_'.  
// The source wave may be text or numerical, the target wave is always numerical.   ToThink: target also text???  
//  If  'lstColumnNames'  contains valid titles then they are used as the 1-dim wave names,  if 'lstColumnNames' is empty then the 2-dim wave must contain valid dimension labels (not column titles!)  which will be used.
	string  	sSrcBaseF_
	string  	sSrcFolder_
	string  	sSrcWaveNm 
	string		sTgtFolderPath_									// usually  'root:uf:'  or  simply  'root:'   or  an empty string ""  which also means 'root:'  .  Any non-existant folder will be created.
	string		lstColumnNames									// if an empty string is passed the column names must be defined in and extracted from the wave (like in MiniDet) .
	string		lstSkipColumns										// e.g. '0;11;...' .  Often column 0  is a 'Marker' column which we are not interested in
	FUNCREF	UFCom_IsValid		fIsValid		
	string  	sWv1DNm

	wave  /Z	wTxtOrNum	= $sSrcBaseF_ + sSrcFolder_ + sSrcWaveNm
	if ( ! waveExists( wTxtOrNum ) )
		printf "Warning:  Source wave '%s'  not found.  \r", sSrcBaseF_ + sSrcFolder_ + sSrcWaveNm
		return	UFCom_kNOTFOUND 
	endif
	variable	bIsTextwave	= ( waveType( wTxtOrNum ) == 0 )
	if ( bIsTextwave )
		wave /T	wTxt		= $sSrcBaseF_ + sSrcFolder_ + sSrcWaveNm
	else
		wave 	wNum	= $sSrcBaseF_ + sSrcFolder_ + sSrcWaveNm
	endif
	variable	r, nMaxRows	= DimSize( wTxtOrNum, 0 )
	variable	c, nMaxCols	= DimSize( wTxtOrNum, 1 )
	variable	nValidRow		= 0
	
	// Normalise folder path: Fill in possibly missing colon and possibly missing 'root:'
	if ( cmpstr( sTgtFolderPath_[ 0, 4 ] , "root:" ) )						// desired folder path  does not start in root .(or was empty) ...
		sTgtFolderPath_= "root:" + sTgtFolderPath_					// ... so we prepend 'root:'    ( ToThink:  let the folder path start in current data folder???)
	endif
	sTgtFolderPath_	= RemoveEnding( sTgtFolderPath_ , ":" ) + ":"		// A colon will be appended to the path if there was none before.
	UFCom_PossiblyCreateFolder( sTgtFolderPath_ )						// The desired folder will be created if it does not yet exist.

	// If an empty  string list 'lstColumnNames'  has been passed then build 1-dim wave names list from the 2-dim wave column titles
	if ( ItemsInList( lstColumnNames ) == 0 )
		lstColumnNames = UFCom_ColNamesFromDimLabels( sSrcBaseF_, sSrcFolder_, sSrcWaveNm )
 	endif
 	
	// Save each result column as 1-D wave.
	 printf "\t\tUFCom_Convert2DWaveTo1D()  as %d   1-D waves \t'%s%s%s'\t-> '%s'\t[SkipColumns: '%s' ] '%s...' \r" , nMaxCols, sSrcBaseF_,  sSrcFolder_,  sSrcWaveNm,  sTgtFolderPath_, lstSkipColumns, lstColumnNames[0,200]
	for ( c = 0; c < nMaxCols; c += 1 )								// 

		if ( WhichListItem( num2str( c ) , lstSkipColumns ) == UFCom_kNOTFOUND )	// convert only interesting columns, ignore 'SkipColumns'
			
			sWv1DNm	= CleanupName( StringFromList( c, lstColumnNames ), 0 )

			make  /O /N=(nMaxRows)	   $sTgtFolderPath_ + sWv1DNm	// the column title will be the wave name 
			wave  	wv1D		= $sTgtFolderPath_ + sWv1DNm
			printf "%s%s;%s", SelectString( c==1, "", "\t\tUFCom_Convert2DWaveTo1D()\t  All converted columns: " ) ,  sWv1DNm , SelectString( c==nMaxCols-1, "", "\r" ) 
	
			// Extract column c of a  2-D text wave  into a numerical 1-D wave
			// Version1: save only valid minis, exclude removed minis
			nValidRow	= 0
			for ( r = 0; r < nMaxRows; r += 1 )					
				
// Version 1: Could  provide different 'fIsValid' functions for Text and numerical waves.  Could pass  'wBD'  to the 'fIsValid' function
//				if ( bIsTextwave )			
//					if ( fIsValid( r ) )	// wrong todo
//						wv1D[ nValidRow ] 	 =  str2num( wTxt[ r ][ c ] )	// Extract column c of a  2-D    text    wave  into a numerical 1-D wave
//						nValidRow			+= 1
//					endif
//				else
//					if ( fIsValid( r ) )
//						wv1D[ nValidRow ] 	 =  wNum[ r ][ c ]		// Extract column c of a  2-D numerical wave  into a numerical 1-D wave
//						nValidRow			+= 1
//					endif
//				endif

// Version 2: Same  'fIsValid'  functions for Text and numerical waves :  'wDB'  cannot be passed but must be constructed internally in 'fIsValid'.  
				if ( fIsValid( r ) )
					if ( bIsTextwave )			
						wv1D[ nValidRow ] 	 =  str2num( wTxt[ r ][ c ] )	// Extract column c of a  2-D    text   wave  into a numerical 1-D wave
					else
						wv1D[ nValidRow ] 	 =  wNum[ r ][ c ]		// Extract column c of a  2-D numerical wave  into a numerical 1-D wave
					endif
					nValidRow			+= 1
				endif

			endfor
			Redimension /N=(nValidRow) wv1D
			
			// Version2: save entire column including rows containing removed minis (->missing values and nans)
			// wv1D 		= str2num( wDB[ p ][ c ] )				// Extract column c of a  2-D text wave  into a numerical 1-D wave
		endif

	endfor
	return	0
End	


Function	/S	UFCom_ColNamesFromDimLabels( sSrcBaseF_, sSrcFolder_, sSrcWaveNm )
	string  	sSrcBaseF_, sSrcFolder_, sSrcWaveNm
	wave  	wTxtOrNum	= $sSrcBaseF_ + sSrcFolder_ + sSrcWaveNm
	variable	c, nMaxCols	= DimSize( wTxtOrNum, 1 )
	string  	sWv1DNm, lstColumnNames = ""
	for ( c = 0; c < nMaxCols; c += 1 )		
		sWv1DNm	  =  UFCom_RemoveWhiteSpace( GetDimLabel( wTxtOrNum, 1, c ) )
		lstColumnNames += sWv1DNm + ";"
 	endfor
	return	lstColumnNames
End


//==============================================================================================
//  GENERIC  DATABASE  FUNCTIONS  FOR  2DIM  TEXT WAVE

// Constants for displaying a table
static constant			kWIDTHCOL0 		= 30						// width of the 'Row' column
static constant			kTBL_MARGINX	=  8// 070825 for recipes, was 20						// bad empirical value to compute the required table window width from the table column widths
static constant			kTBL_BOTTOMYX	= 36						// space for Igors bottom bar (+Windows task bar?)
  

Function		UFCom_DisplayTable( xLeft, yTop, xRight, yBot, wDB, lstColumnNames, lstColumnWidths, lstColumnShades, sTblNm, sTitle, sfHook, bKillOrResize ) 
// Construct table and display it. Depending on  'bKillOrResize'  the table is  killed  and recreated   or  only resized.
// If the screen is wide and high enough display table with its full width from 'lstColumnWidths' and height, but 'xLeft' , 'xRight',  'yTop' and 'yBot'  (all in %)   may  narrow this range 

	wave 	/T  wDB
	variable	xLeft, yTop, xRight, yBot
	string		lstColumnNames, lstColumnWidths, lstColumnShades, sTblNm, sTitle, sfHook
	variable	bKillOrResize
	
	if ( bKillOrResize == UFCom_kKILL_TBL )
		UFCom_KillTable( sTblNm ) 
	endif
	if ( WinType ( sTblNm ) != UFCom_WT_TABLE )
		variable	nColWidth		= UFCom_GetInitialTableWidth( sTblNm, kWIDTHCOL0, lstColumnWidths ) 			// Computing  the required table window width from the table column widths is only approximate...
		variable	yTblHeightPts	= UFCom_GetTableHeight( wDB )								 		// Computing  the required table window height
	
		variable	rxMinPoints, rxMaxPoints, ryMinPoints, ryMaxPoints, xSz, ySz
		UFCom_GetIgorAppPoints( rxMinPoints, rxMaxPoints, ryMinPoints, ryMaxPoints )							// If the screen is.... 
		xSz	  = min( rxMinPoints + (xRight - xLeft)  * ( rxMaxPoints - rxMinPoints ) / 100, nColWidth + kTBL_MARGINX )	// ... wide enough display table with its full width 'nColWidth' ,  	but 'xLeft' and 'xRight' may  narrow this range (compute before xLeft is changed)
		ySz	  = min( ryMinPoints + (yBot	   - yTop)  * ( ryMaxPoints - ryMinPoints - kTBL_BOTTOMYX ) / 100, yTblHeightPts)//... high  enough display table with its full height 'yTblHeightPts' , but 'yTop' and 'yBot'   may  narrow this range (compute before yTop is changed)
		xLeft	  = 	  rxMinPoints + xLeft 	 * ( rxMaxPoints - rxMinPoints ) / 100
		yTop	  = 	  ryMinPoints + yTop	 * ( ryMaxPoints - ryMinPoints - kTBL_BOTTOMYX ) / 100
		// print "\t\tUFCom_DisplayTable() ", sTitle, "bKill:", bKillOrResize,  "xmin:", rxMinPoints, "xmax:", rxMaxPoints, "ymin:", ryMinPoints, "ymax:", ryMaxPoints, "-> xSz ", xSz, "-> l t r b " , xLeft, yTop, xLeft+xSz, yTop+ySz	

		Edit	   /K=1  /N=$sTblNm	/W=( xLeft, yTop, xLeft+xSz, yTop+ySz )   wDB  as  sTitle 	// ...and  kTBL_MARGINX  is only bad empirical value (maybe font and font size matter?...todo...)
		if ( strlen( sfHook ) )
			SetWindow $sTblNm , hook( $sfHook ) = $sfHook							// The hook function requires to use a named hook. For saving an extra parameter the name of the hook function is also used for the hook name.
		endif
	endif

	variable	c,  nColsFromTitles	= ItemsInList( lstColumnNames )
	UFCom_ModifyTableColumnWidth(	wDB, sTblNm, lstColumnWidths, kWIDTHCOL0 ) 
	UFCom_ModifyTableColumnTitles(	wDB, sTblNm, lstColumnNames ) 
	UFCom_ModifyTableColumnShading(wDB, sTblNm, lstColumnShades ) 
	// printf "\t\tUFCom_DisplayTable(  \t%s\tnColTitles:%3d\tnColWidths:%3d\tnWaveCols:%3d\t   \r",  UFCom_pd( sTblNm, 13), nColsFromTitles, ItemsInList( lstColumnWidths ), DimSize( wDB, 1 )
End




// for  'Extracted'  in  'Bestell'  but could and should be used everywhere..........
Function		UFCom_RedimDBWave( sDBFoWv, lstColTitles, lstColWidths )
	string  	sDBFoWv	
	string  	lstColTitles	
	string  	lstColWidths	

	variable	nRows
	variable	nItems	= ItemsInList( lstColTitles )
	wave  /Z/T	wv	= $sDBFoWv
	if ( ! waveExists( wv ) )
		nRows	= 1
		make /T /N=( nRows, nItems )  $sDBFoWv			// wave does not exist...
		wave  /T	wv	= $sDBFoWv					// ...so we create it with just 1 row 
	else														
		nRows	= DimSize( wv, 0 ) + 1
		Redimension  /N=(nRows, -1 ) wv
	endif
	return	nRows - 1			// the index of the new row
End	

// for  'Extracted'  in  'Bestell'  but could and should be used everywhere..........
Function		UFCom_ClearTbl( sDBFoNm )
	string 	sDBFoNm
	wave   /Z /T	wv		= $sDBFoNm
	if ( waveExists( wv ) )
		Redimension  /N=( 0, -1 ) wv
	endif
End

// for  'Extracted'  in  'Bestell'  but could and should be used everywhere..........
Function		UFCom_KillTbl( sDBFoNm, sTblNm )
	string  	sTblNm, sDBFoNm
	UFCom_KillTable( sTblNm )
	wave  /Z  /T	wv		= $sDBFoNm
	if ( waveExists( wv ) )
		KillWaves wv
	endif
End




Function		UFCom_MyTable( sTbl, sTitle, bDisplay, RowOfs, sTxt, sKeySep, sListSep )
	string  	sTbl	
	string  	sTitle	
	variable	bDisplay	
	variable	RowOfs							// 0 : into last row , 1: create new row
	string  	sTxt
	string  	sKeySep							// usually '='
	string  	sListSep							// usually '\t'
string sfHook=""	
	string  	lstColumnNames = "", lstColumnWidths = "", lstColumnShades = "", lstColumnValues = ""
	string  	sColumnName = "", sColumnValue = ""
	variable	nRows

	// Break text string into column titles and values
	variable	n, nItems	= ItemsInList( sTxt, sListSep )
	for ( n = 0; n < nItems; n += 1 )
		sColumnName		  =  StringFromList( n, sTxt, sListSep )				// e.g.  'Pts=   1000'
		sColumnValue		  =  UFCom_RemoveWhiteSpace( StringFromList( 1, sColumnName, sKeySep ) )	// e.g.  '1000'
		sColumnName		  =  StringFromList( 0, sColumnName, sKeySep )		// e.g.  'Pts'
		lstColumnNames	 += sColumnName + ";"
		lstColumnValues		 += sColumnValue + ";"
		lstColumnWidths	 += SelectString( n == 0 , "40;" , "200;" )			// Only the 'Nm' column is wider (will be autoresized below anyway)
	endfor	
	lstColumnShades = lstColumnWidths

	// Create the data wave  or increase its number of rows.  The number of columns required has been derived from the data string 'sTxt' . 
	wave  /Z/T	wv	= $UFCom_ksROOT_UF_ + sTbl
	if ( ! waveExists( wv ) )
		nRows	= 1
		make /T /N=( nRows, nItems )  $UFCom_ksROOT_UF_ + sTbl	// wave does not exist...
		wave  /T	wv	= $UFCom_ksROOT_UF_ + sTbl			// ...so we create it with just 1 row 
	else														
		if ( RowOfs == 1 )									// wave exists  but we need 1 more row...
			nRows	= DimSize( wv, 0 ) + 1
			Redimension  /N=(nRows, -1 ) wv
		endif

		if ( DimSize( wv, 1 )  < nItems )
			Redimension  /N=( -1, nItems ) wv
		endif

	endif

	wv[ nRows-1 ][ ]	= StringFromList( q, lstColumnValues )				// fill the newly appended row of the wave

	// Create the table  if it does not exist  and display the wave
	UFCom_DisplayTable( 0, 10, 70, 70, wv, lstColumnNames, lstColumnWidths, lstColumnShades, sTbl, sTitle, sfHook, UFCom_kRESIZE_TBL ) 
	ModifyTable   /W=$sTbl	 font = kTBL_FONT, size=kTBL_FONTSZ,  alignment[1]=0, alignment[2,inf]=2,  autosize={ 0,0,8,1,2}
//	ModifyTable   /W=$sTbl	 alignment[1]=0
	DoUpdate
// todo Autosize the table window
End	


Function		UFCom_MyTablePrvRow( sTbl, sValue, nCol, sKey, sKeySep, sListSep )
	string  	sTbl	
//	string  	sTitle	
//	variable	bDisplay	
//	variable	RowOfs							// 0 : into last row , 1: create new row
	string  	sValue	
	variable	nCol								// Bad code as  column  'nCol'  is fixed, should search for  sKey e.g. 'Load/ms'  or  'OverallTime'
	string  	sKey								// e.g. 'Dur/ms'
	string  	sKeySep							// usually '='
	string  	sListSep							// usually '\t'
	variable	nRows

	wave  /Z/T	wv	= $UFCom_ksROOT_UF_ + sTbl
	if ( waveExists( wv ) )
		nRows	= DimSize( wv, 0 ) 
		wv[ nRows-1 ][ nCol ]	= sValue
	endif
End		


Function		UFCom_KillTable( sTblNm ) 
	string		sTblNm 
	DoWindow /K $sTblNm
End

Function	/S	UFCom_ColTitle( col, lstColumnNames ) 	
	variable	col
	string  	lstColumnNames
	return	StringFromList( col, lstColumnNames ) 
End
	

Function		UFCom_FindOriginalColumnIndex( nColFew, lstFewColumnNames, lstColumnNames )
// Return the original column index (usually a constant kXX_YYY) corresponding to the full list  'lstColumnNames'  if the column index  'nColFew'  of a  Few-columns-view having the columns  'lstFewColumnNames'  is given .
	variable 	nColFew
	string  	lstFewColumnNames		// the titles of the reduced table containing only some columns
	string  	lstColumnNames		// the titles of the entire wave (=the full table containing all columns)
	string  	sTitle		= UFCom_ColTitle( nColFew, lstFewColumnNames ) 		
	variable	nIndex	= WhichListItem( sTitle, lstColumnNames )
	return	nIndex
End
			// Starting at the original column 'nColOrg'  in the wave   return  the next used  columns by skipping all empty columns.

Function		UFCom_FindReducedColumnIndex( nColAll, lstFewColumnNames, lstColumnNames )
// Return the column index of a  Few-columns-view having the columns  'lstFewColumnNames'  when the original column index  'nColAll' (usually a constant kXX_YYY) corresponding to the full list  'lstColumnNames'  is given .
	variable 	nColAll
	string  	lstFewColumnNames		// the titles of the reduced table containing only some columns
	string  	lstColumnNames		// the titles of the entire wave (=the full table containing all columns)
	string  	sTitle		= UFCom_ColTitle( nColAll, lstColumnNames ) 		
	variable	nIndex	= WhichListItem( sTitle, lstFewColumnNames )
	return	nIndex
End
			// Starting at the original column 'nColOrg'  in the wave   return  the next used  columns by skipping all empty columns.

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function   		UFCom_ConvertUmlauteWv( wSource, wTarget )
	wave	/T	wSource, wTarget
	variable	n, nRows	= min( DimSize( wSource, 0 ), DimSize( wTarget, 0 ) )
	for ( n = 0; n < nRows; n += 1 )
		wTarget[ n ]	= UFCom_ConvertUmlaute(  wSource[ n ] )	
	endfor
	// printf "\t\tUFCom_ConvertUmlauteWv()\twSource: %s  %s  %s  %s  \t->\twTarget: %s  %s  %s  %s  \r",  wSource[0], wSource[1], wSource[2], wSource[3],  wTarget[0], wTarget[1], wTarget[2], wTarget[3]
End
	
	
Function   /S	UFCom_ConvertUmlaute( sString )
	string  	sString
	sString = ReplaceString( "Ä", sString, "Ae" )	
	sString = ReplaceString( "Ö", sString, "Oe" )	
	sString = ReplaceString( "Ü", sString, "Ue" )	
	sString = ReplaceString( "ä", sString, "ae" )	
	sString = ReplaceString( "ö", sString, "oe" )	
	sString = ReplaceString( "ü", sString, "ue" )	
	sString = ReplaceString( "ß", sString, "ss" )	
	return	sString
End

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

static	 Function	ConvertGermanDateWv(  wSource, wTarget )
// Converts german date format   'dd.mm.yy'  into a format suitable for sorting : 'yy.mm.dd'
	wave	/T	wSource, wTarget
	variable	n, nRows	= min( DimSize( wSource, 0 ), DimSize( wTarget, 0 ) )
	for ( n = 0; n < nRows; n += 1 )
		wTarget[ n ]	= ConvertGermanDate(  wSource[ n ] )	
	endfor
	// printf "\t\tUFCom_ConvertGermanDateWv()\twSource: %s  %s  %s  %s  \t->\twTarget: %s  %s  %s  %s  \r",  wSource[0], wSource[1], wSource[2], wSource[3],  wTarget[0], wTarget[1], wTarget[2], wTarget[3]
End


static Function   /S	ConvertGermanDate( sString )
// Converts german date format   'dd.mm.yy'  into a format suitable for sorting : 'yymmdd' . We MUST REMOVE the dots because Igor gets very confused when encountering 2 decimal points !
	string  	sString
	if  ( IsGermanDate( sString ) )
		sString = sString[ 6, 7 ] + sString[ 3, 4 ] + sString[ 0, 1 ]
	endif
	return	sString
End

static Function  	IsGermanDate( sString )
// Returns if  'sString'  is a german date e.g.  'dd.mm.yy'
	string  	sString
	return	strlen( sString ) == 8  &&  !cmpstr( sString[2,2], "." )  &&  !cmpstr( sString[5,5], "." )  &&  str2num( sString[0,1] ) > 0  &&  str2num( sString[0,1] ) < 32  &&  str2num( sString[3,4] ) > 0  &&  str2num( sString[3,4] ) < 13  &&  str2num( sString[6,7] ) > -1  &&  str2num( sString[6,7] ) < 100  
End

