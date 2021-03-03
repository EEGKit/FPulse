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

//#pragma IndependentModule=UFCom_
#include "UFCom_Constants"



//   !!!elsewhere also
constant		kSORTACTION_TOGGLE = 0,   kSORTACTION_UP = 1,	kSORTACTION_DOWN = -1



strconstant	ksDBMARKER_CREATE	= "_create_"


static constant	kTBL_ROWHEIGHT		= 22				// Unfortunately this depends on screen resolution, empirical values are 20 for 1280x1024, 22 for 1600x1200 . 
												// Perhaps it depends on font size, perhaps it can be retrieved somehow.



Function		UFCom_GetTableRowCol( s, r, c )
// Computes from MOUSE position and table coordinates which cell has been CLICKED. The  'TableInfo' string returns directly the selected cell but only if it is a true inner table cell. 
// Drawback 1: The  'TableInfo' string does not return info about outer cells ('Row' column and the 2 headlines) which we are especially interested in...
// Drawback 2: The  'TableInfo' string  for any row or column -1  when the cursor keys are used  -> This case must be trapped and  'TableRowColFromArrowKeys()'  must be used .
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
//	if (  s.mouseLoc.h <= xp * screenresolution / kIGOR_POINTS72  )//||  c >= nCols )
//		c	= -1
//		sColOutOfRange	= "> C: 'Row'\t"
//	else
//		c 	= nFirstCol
//		do
//			// Cave: Although multiple unused right columns are drawn by Igor they cannot get selected. Igor allows only to select the first unused column.
//			xp 	+=   NumberByKey( "WIDTH" , 	TableInfo( s.WinName, c ) )	
//			if ( s.mouseLoc.h <= xp * screenresolution / kIGOR_POINTS72  ||  c >=  nCols )		//  allow and monitor clicking into unused right columns 
//				sColOutOfRange	= SelectString( c >= nCols , " \t\t" , "> C: unused" )
//				break
//			endif
//			c	+= 1
//		while ( TRUE )
//	endif

	if (  s.mouseLoc.h <= xp * screenresolution / kIGOR_POINTS72  )//||  c >= nCols )
		c	= -1
		sColOutOfRange	= "> C: 'Row'\t"
	else
		c 	= nTgtCol
		sColOutOfRange	= SelectString( c >= nCols , " \t\t" , "> C: unused" )
	endif

	if ( nTgtRow == 0 )								// this can be the true row 0 or one of the 2 header lines
		r	= trunc( s.mouseLoc.v / kTBL_ROWHEIGHT ) - 3	// Inspite of the uncertainty in  kTBL_ROWHEIGHT it is precise enough to discriminate between the 3 lines on top
		sRowOutOfRange	= "> R: Header\t"
	else
		r	= nTgtRow				// ??? TARGETROW is computes delayed when the window is entered. Incorrect at the 1., works only at the 2. mouse action
		sRowOutOfRange	=  " \t \t"
		variable rowByMouse = trunc( s.mouseLoc.v / kTBL_ROWHEIGHT ) - 3 + nFirstRow
	endif
	
	string  	sEvTxt = UFCom_pad( s.eventName, 8 )
	//  printf "\t\txp:%4d\txSc:%4d\t >? xmo:%4d\tnCols:%3d\tc1:%d\tc:%3d\t[=%2d]\t%s\tyMouse:%4d\tnRows:%4d \tr1: %3d\tr:%3d\t[=%2d]\tOldRbM:%4d\t%s\tE:%2d\t%s\tMod:%4d\tkey:%4d \t \r", xp, xp * screenresolution / kIGOR_POINTS72, s.mouseLoc.h, nCols, nFirstCol, c, nTgtCol, sColOutOfRange, s.MouseLoc.v, nRows, nFirstRow, r, nTgtRow,rowByMouse,sRowOutOfRange, s.eventCode,sEvTxt, s.eventMod, s.keycode
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
	return	StringFromList( nKeyCode, klstKEYCODES )
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
	
		if ( WhichListItem( sWantWave, lstWavesInFile ) == kNOTFOUND )				// ...now check each of the wave names
			sprintf sTxt, "Expected wave\t'%s'\tnot found in file  '%s'  . This file contains only wave(s)  '%s' . Creating missing wave with %d pts...", sWantWave, sFile, lstWavesInFile, nPnts
			UFCom_Alert1( kERR_IMPORTANT, sTxt )
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
	string  	sDir, sFileNm, sBaseF, sF, sWantWave, lstWaveCols
	variable	nInitialRows = 0								// 'nInitialRows' = 0 : creates no row (as in Secutest, disadvantage: when the first data are entered the 2! rows[also the col nr row] are added  
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
// Cave1: The current data folder must not be  'sBaseF + sF'  (e.g. must not be 'ksROOTUF_ + ksF_REC_ ')   because  'duplicate'  below will fail
// Cave2: The data base must NOT have  0 rows. With 0 rows the number of columns is ignored and also set to 0 in 'SaveDataBase' : All redimensioning is useless...
	string  	sDir, sFileNm, sBaseF, sF, sWantWave, lstWaveCols
	variable	nInitialRows								// 'nInitialRows' can be 0 : creates no row (as in Secutest, disadvantage: when the first data are entered the 2! rows[also the col nr row] are added  
	variable	c, nWantWvCols	= ItemsInList( lstWaveCols )	// 'nInitialRows' can be 1 : creates an empty row (as in Recipes)

	string 	sFile				= sDir + sFileNm		
	string 	sTxt
	
// 060828
	variable	nCode
	string  	sFolderWave	= sBaseF + sF + sWantWave

	UFCom_PossiblyCreatePath( sDir )
	
	if ( ! UFCom_FileExists( sFile ) )												// The data base wave is missing : create it
		sprintf sTxt, "Could not load wave '%s' from file '%s' . Missing wave(s) will be created...", sWantWave, sFile 	
		UFCom_Alert1( kERR_IMPORTANT, sTxt )		
		// print "\t\tLoadDatabaseOne2Dim", "\t", sWantWave, "\t", "\tSubWaves:", lstWaveCols, nWantWvCols 
		make  /O  /T  /N= ( nInitialRows, nWantWvCols )  	$sFolderWave = ""	// nInitialRows can be 0 or 1. If rows are 0 then the column dimensioning fails as Igor sets the column number also to 0  (bad behaviour!)
		wave	/T	WantWave	= 		$sFolderWave				// create the missing wave in the folder...
		UFCom_SaveDataBase( sDir, sFileNm, sBaseF, sF, sWantWave )							//...and save the newly created missing wave (still empty)
		nCode	= 0
	else															// the wave has been loaded  so now we must check if no columns are missing... 
		LoadWave /O /T /A  /Q 	sFile										//  load the file containing the  stored data base from disk
		wave	/T	WantWave	= 	$sWantWave	
		variable	nRows	= DimSize( WantWave, 0 )
		variable	nColumns	= DimSize( WantWave, 1 )						// ...now check each of the columns 
		// Cave: Works only if there is at least 1 row....
		if ( nWantWvCols >  nColumns )
			sprintf sTxt, "Expecting 2 dimensional text wave '%s'  having  %d columns. Found %d columns (and %d rows). Redimensioning...", sWantWave, nWantWvCols, nColumns, nRows
			UFCom_Alert1( kERR_IMPORTANT, sTxt )		
			Redimension /N=( nRows, nWantWvCols )	WantWave
			duplicate	/O 	WantWave	$sFolderWave					// ...but the wave is loaded into the Current data folder so we move it into a folder..
			killWaves		WantWave								// ...and we delete the temporary wave in the root
			// printf "\t\t\tLoadDatabaseOne2Dim_NRows() now has %d columns and %d rows \r", DimSize( $sFolderWave, 1 ), DimSize( $sFolderWave, 0 ) 
			UFCom_SaveDataBase( sDir, sFileNm, sBaseF, sF, sWantWave )			// ...and save the wave with old and the newly created columns (still empty)
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
	variable	nInitialRows							// 'nInitialRows' can be 0 : creates no row (as in Secutest, disadvantage: when the first data are entered the 2! rows[also the col nr row] are added  
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

Function		UFCom_GetTableHeight( wDB ) 
	wave  /T	wDB
	variable	nRows		= DimSize( wDB, 0 )
	variable	TblHeightPts	= -6 + ( nRows + 5 ) * kTBL_ROWHEIGHT / screenresolution * kIGOR_POINTS72	// 6 = Title  +  Table edit line   +  Column names   +   Column numbers  +   Data rows  +  Empty line for new entry   +   Bottom scroll bar
	// printf "\t\t\t\tGetTableHeight() -> nRows:%d  -> returns %d \r", nRows, TblHeightPts
	return	TblHeightPts
End


Function		UFCom_GetInitialTableWidth( sTableNm, nWidthCol0, lstColWidth ) 
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


Function		UFCom_ModifyTableColumnWidth( wDB, sTableNm, lstColWidth, nWidthCol0 ) 
	wave 	/T  wDB
	string  	sTableNm, lstColWidth
	variable	nWidthCol0 
	variable	c, nCols	= ItemsInList( lstColWidth )
	nCols	= min( nCols, DimSize( wDB, 1 ) )					// 060913 prevent Igor from complaining when there are not as many wave columns as width columns
	ModifyTable /W = $sTableNm  width[ 0 ] = nWidthCol0
	for ( c = 0; c < nCols; c += 1 )
		variable	nColWidth	= str2num( UFCom_RemoveWhiteSpace( StringFromList( c, lstColWidth ) ) ) 
		ModifyTable /W = $sTableNm  width[ c + 1 ] = nColWidth		
	endfor
End


Function		UFCom_ModifyTableColumnTitles( wDB, sTableNm, lstColTitles ) 
	wave 	/T  wDB
	string  	sTableNm, lstColTitles
	variable	c, nCols	= ItemsInList( lstColTitles )
	nCols	= min( nCols, DimSize( wDB, 1 ) )					// 060913 prevent Igor from complaining when there are not as many wave columns as title columns
	for ( c = 0; c < nCols; c += 1 )
		ModifyTable /W = $sTableNm  title[ c + 1 ]		= StringFromList( c, lstColTitles ) 
		ModifyTable /W = $sTableNm  alignment[ c + 1 ]	= 0 		// 0 starts entry at left border 
	endfor
End


Function		UFCom_ModifyTableColumnShading( wDB, sTableNm, lstColShades ) 
	wave 	/T  wDB
	string  	sTableNm, lstColShades
	variable	c, nCols	= ItemsInList( lstColShades )
	nCols	= min( nCols, DimSize( wDB, 1 ) )					// 060913 prevent Igor from complaining when there are not as many wave columns as width columns
	for ( c = 0; c < nCols; c += 1 )
		variable	nColShade  = str2num( UFCom_RemoveWhiteSpace( StringFromList( c, lstColShades ) ) ) 
		if ( nColShade )
			ModifyTable /W = $sTableNm  rgb[ c + 1 ] = ( 0, 0, 65535 )
		endif
	endfor
End


Function		UFCom_SortDatabase( sFolder, sDBNm, PrimSortCol, order )
// Sort the data base  'sDBNm'   according to 'PrimSortCol' .  If not primarily sorting column 0  then column 0 is used as a secondary sorting index.
	string  	sFolder, sDBNm
	variable	PrimSortCol, order
	wave 	/T  wt  = $ksROOTUF_ + sFolder + sDBNm
	UFCom_SortByColumn( wt, PrimSortCol, order )
End	

Function		UFCom_SortByCol_AlNum_CaseIns( wt, PrimSortCol, SecSortCol, TertSortCol, nOrder )
// Sort   2dim  text wave  by any column. A primarily and a secondary sorting index is allowed.
// Todo:  Umlaute ?   Pass direction or toggle?
	wave  /T	wt
	variable	PrimSortCol, SecSortCol, TertSortCol
	variable	nOrder											// +1 : fixed order ascending,   -1: fixed order descending,   0 : toggle = invert order
	UFCom_SortByColumn_( wt, PrimSortCol, SecSortCol, TertSortCol, nOrder, kSORT_ALPHA_NUM_CASE_I )	//  Parameter is actually for 'SortList' , not for 'MakeIndex' .
End

Function		UFCom_SortByColumn( wt, PrimSortCol, nOrder )
// Sort   2dim  text wave  by any column. If not primarily sorting column 0  then column 0 is used as a secondary sorting index.
// Todo:  Umlaute ?   Pass direction or toggle?
	wave  /T	wt
	variable	PrimSortCol
	variable	nOrder											// +1 : fixed order ascending,   -1: fixed order descending,   0 : toggle = invert order
	variable	SecSortCol = 0,  TertSortCol = 0
	UFCom_SortByColumn_( wt, PrimSortCol, SecSortCol, TertSortCol, nOrder, 0 )		// 0 means default sort. Parameter is actually for 'SortList' , not for 'MakeIndex' .
End

Function		UFCom_SortByColumn_( wt, PrimSortCol, SecSortCol, TertSortCol, nOrder, nMode )
// Sort   2dim  text wave  by 3 arbitrary columns.
// Todo: Umlaute ?   Pass direction or toggle?
//  This  special  Umlaut sorting makes the process   very, very, very slow...........Times given are per row for 1.6GHz,  20 columns, 900 rows -> yielding  ~40 seconds!     
	wave  /T	wt
	variable	PrimSortCol, SecSortCol, TertSortCol
	variable	nOrder											// +1 : fixed order ascending,   -1: fixed order descending,   0 : toggle = invert order
	variable	nMode

	// Igor cannot reasonably sort the 2dim wave, so we....
	variable	n, nRows	= DimSize( wt, 0 )
	variable	c, nCols	= DimSize( wt, 1 )
//variable	nTimer, 	MilliSeconds 
//MilliSeconds = stopMSTimer( nTimer) / 1000;   Print "Start   ", MilliSeconds, "\t  ms needed for SortByColumn()   rows:", nRows, MilliSeconds/nRows, "ms needed for SortByColumn() per row"; nTimer	= StartMSTimer

	//Make   /O      	     /N = (nRows)   wSortIndx
	Make   /O /I /U   /N = (nRows)   wSortIndx					// wSortIndx should be unsigned long for 'FindValue' below

	// ...split it into multiple 1dim waves, 1 for each column, 
	for ( c = 0; c < nCols; c += 1 )
		Make /O /T  /N = (nRows)    $("wTmp" + num2str( c ) )
		wave	/T	wTmp	= $("wTmp" + num2str( c ) )
		wTmp	= wt[ p ][ c ]								// ~700 us     2-dim wave arithmetics is in this case  NOT  faster than a  2-dim loop!	
//		for ( n = 0; n < nRows; n += 1 )							// ~700 us
//			wTmp[ n ]	= wt[ n ][ c ]
//		endfor
	endfor

	// ...the column after which is to sorted has a special name and must be an extra wave, not only a reference... 
	//... because we want the umlaut replacements Ae Oe Ue  only temporarily as a sorting index but not in the data base. 
	duplicate	/O /T	$("wTmp" + num2str( PrimSortCol ) ) 	wtSortCol
	duplicate	/O /T	$ "wTmp" + num2str( SecSortCol )	wtSortCol2		// in addition to the primary sort column allow a secondary sort column....
	duplicate	/O /T	$ "wTmp" + num2str( TertSortCol )	wtSortCol3		// ...and also allow a tertiary sort column
	for ( n = 0; n < nRows; n += 1 )

// 060826
wtSortCol[ n ]	= UFCom_ConvertUmlaute(  wt[ n ][ PrimSortCol ] )					// ~110 us
wtSortCol2[ n ]	= UFCom_ConvertUmlaute(  wt[ n ][ SecSortCol ] )
wtSortCol3[ n ]	= UFCom_ConvertUmlaute(  wt[ n ][ TertSortCol ] )
	endfor

	if ( nOrder == kSORTACTION_TOGGLE )								// toggle = invert  the current sorting order
		// nOrder	= cmpstr( wtSortCol[ 0 ] , wtSortCol[ nRows - 1] ) 				// old non-alpha-numerical sort is WRONG.  Is it currently sorted up or down?
		string  	lstDummy		= wtSortCol[ 0 ] + ";" + wtSortCol[ nRows - 1] + ";"// create a list consisting only of the first and last item of the column to be sorted....
		string		lstDummyAlNum	= SortList( lstDummy, ";",  nMode )			//...and sort this list according to 'nMode' which can be normal or alphanumerical....
		variable	nOrderByLst	= cmpstr( lstDummy, 	lstDummyAlNum )		// A simple string compare 'cmpstr'  which does not take the alphanumerical sorting order into account will produce wrong results!
		nOrder =  -1 + 2 * nOrderByLst* nOrderByLst 						// empirical 'nOrder'  gives the correct sorting also for alpanumerical sorting : nOrderByLst +1 or -1  -> nOrder= +1,  nOrderByLst 0  -> nOrder = -1   
		//printf "\t\tSortByColumn_()\tPrimSC:%d\tRows:%d\tw[0]:\t%s\tw[last]:\t%s\t-> \tSimple non-AN cmpstr gives Order: %d\t  OrderByLst:%d\t->AN-Order: %d\tDuOrg: %s\t ->\tDuAN: %s \r", PrimSortCol, nRows,  UFCom_pd(wtSortCol[ 0 ],11) ,  UFCom_pd(wtSortCol[ nRows - 1],11) , cmpstr( wtSortCol[ 0 ] , wtSortCol[ nRows - 1] ) , nOrderByLst, nOrder,  UFCom_pd(lstDummy,13),  lstDummyAlNum
	endif

	// ...create the index wave after which will be sorted					 < 1us
	if ( nOrder >= 0 )
		if ( nMode == kSORT_ALPHA_NUM_CASE_I )	
			if ( 	  PrimSortCol == SecSortCol  && SecSortCol == TertSortCol )		
				MakeIndex  /A	wtSortCol , 					wSortIndx	// 1 column 		alphanum 	sort
			elseif ( SecSortCol == TertSortCol )							
				MakeIndex  /A	{ wtSortCol , wtSortCol2 },			wSortIndx	// 2 columns 		alphanum 	sort
			else													
				MakeIndex  /A	{ wtSortCol , wtSortCol2 , wtSortCol3 }, wSortIndx	// 3 columns 		alphanum 	sort
			endif
		else	
			if ( 	  PrimSortCol == SecSortCol  && SecSortCol == TertSortCol )		
				MakeIndex  	wtSortCol , 					wSortIndx	// 1 column 		default 	sort
			elseif ( SecSortCol == TertSortCol )							
				MakeIndex  	{ wtSortCol , wtSortCol2 },			wSortIndx	// 2 columns 		default 	sort
			else													
				MakeIndex  	{ wtSortCol , wtSortCol2 , wtSortCol3 }, wSortIndx	// 3 columns 		default 	sort
			endif
		endif
	else
		if ( nMode == kSORT_ALPHA_NUM_CASE_I )	
			if ( 	  PrimSortCol == SecSortCol  && SecSortCol == TertSortCol )		
				MakeIndex/A/R wtSortCol , 					wSortIndx	// 1 column 		alphanum 	sort, reversed
			elseif ( SecSortCol == TertSortCol )							
				MakeIndex/A/R { wtSortCol , wtSortCol2 },			wSortIndx	// 2 columns 		alphanum 	sort, reversed
			else													
				MakeIndex/A/R { wtSortCol , wtSortCol2 , wtSortCol3 },wSortIndx	// 3 columns 		alphanum 	sort, reversed
			endif
		else	
			if ( 	  PrimSortCol == SecSortCol  && SecSortCol == TertSortCol )		
				MakeIndex  /R	wtSortCol , 					wSortIndx	// 1 column 		default 	sort, reversed
			elseif ( SecSortCol == TertSortCol )							
				MakeIndex  /R	{ wtSortCol , wtSortCol2 },			wSortIndx	// 2 columns 		default 	sort, reversed
			else													
				MakeIndex  /R	{ wtSortCol , wtSortCol2 , wtSortCol3 }, wSortIndx	// 3 columns 		default 	sort, reversed
			endif
		endif
	endif

//	// ...create the index wave after which will be sorted					 < 1us
//	if ( nOrder < 0 )
//		if ( PrimSortCol == 0 )
//			if ( nMode == kSORT_ALPHA_NUM_CASE_I )	
//				MakeIndex  /R	/A	  wtSortCol , 			wSortIndx	// reverse alphanum 	sort
//			else															
//				MakeIndex  /R		  wtSortCol , 			wSortIndx	// reverse	default 	sort		
//			endif
//		else
//			if ( nMode == kSORT_ALPHA_NUM_CASE_I )	
//				MakeIndex  /R 	/A	{ wtSortCol , wtSortCol2 },	wSortIndx	// reverse alphanum 	sort
//			else														
//				MakeIndex  /R 		{ wtSortCol , wtSortCol2 },	wSortIndx	// reverse default 	sort		
//			endif
//		endif
//	else
//		if ( PrimSortCol == 0 )
//			if ( nMode == kSORT_ALPHA_NUM_CASE_I )	
//				MakeIndex  	/A	   wtSortCol , 			wSortIndx	// 		alphanum 	sort
//			else														
//				MakeIndex  		   wtSortCol , 			wSortIndx	// 		default 	sort	
//			endif
//		else
//			if ( nMode == kSORT_ALPHA_NUM_CASE_I )	
//				MakeIndex     	/A	 { wtSortCol , wtSortCol2 },	wSortIndx	// 		alphanum 	sort
//			else														
//				MakeIndex     		 { wtSortCol , wtSortCol2 },	wSortIndx	// 		default 	sort
//			endif
//		endif
//	endif






//MilliSeconds = stopMSTimer( nTimer) / 1000;   Print "Sum till now \t", MilliSeconds, "\t  ms needed for SortByColumn()   rows:", nRows, MilliSeconds/nRows, "ms needed for SortByColumn() per row"; nTimer	= StartMSTimer

// LH: Appending to end of text wave is fastest..

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


//	//  Version 3a
//	// ...sort each column = each of the multiple 1dim waves
// print "Version3a nCols:",  nCols
//	for ( c = 0; c < nCols; c += 1 )
//		wave	/T	wTmp	= $("wTmp" + num2str( c ) ) 			
//		IndexSort	wSortIndx, wTmp							// ~16 us
//	endfor
//	wave	/T	wTmp0, wTmp1,wTmp2, wTmp3,wTmp4, wTmp5,wTmp6, wTmp7,wTmp8, wTmp9, wTmp10, wTmp11,wTmp12, wTmp13,wTmp14, wTmp15,wTmp16, wTmp17,wTmp18
//
//	// ...and finally build together the 2dim wave from the sorted 1dim waves. Voila.
//	for ( n = 0; n < nRows; n += 1 )
//		wt[ n ][ 0 ] = wTmp0[ n ] 							// ~35 000 us
//		wt[ n ][ 1 ] = wTmp1[ n ] 							// ~35 000 us
//		wt[ n ][ 2 ] = wTmp2[ n ]							// ~35 000 us
//		wt[ n ][ 3 ] = wTmp3[ n ]							// ~35 000 us
//		wt[ n ][ 4 ] = wTmp4[ n ]							// ~35 000 us
//		wt[ n ][ 5 ] = wTmp5[ n ]							// ~35 000 us
//		wt[ n ][ 6 ] = wTmp6[ n ]							// ~35 000 us
//		wt[ n ][ 7 ] = wTmp7[ n ]							// ~35 000 us
//		wt[ n ][ 8 ] = wTmp8[ n ]							// ~35 000 us
//		wt[ n ][ 9 ] = wTmp9[ n ]							// ~35 000 us
//		wt[ n ][ 10 ] = wTmp10[ n ] 							// ~35 000 us
//		wt[ n ][ 11 ] = wTmp11[ n ] 							// ~35 000 us
//		wt[ n ][ 12 ] = wTmp12[ n ]							// ~35 000 us
//		wt[ n ][ 13 ] = wTmp13[ n ]							// ~35 000 us
//		wt[ n ][ 14 ] = wTmp14[ n ]							// ~35 000 us
//		wt[ n ][ 15 ] = wTmp15[ n ]							// ~35 000 us
//		wt[ n ][ 16 ] = wTmp16[ n ]							// ~35 000 us
//		wt[ n ][ 17 ] = wTmp17[ n ]							// ~35 000 us
//		wt[ n ][ 18 ] = wTmp18[ n ]							// ~35 000 us
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
//		if ( V_value == kNOTFOUND )
//			print "Error:  SortByColumn  FindValue  NOTFOUND  n:", n, V_value	
//		else
//			print "\t n:", n, V_value	
//		endif
//	endfor
//	wt = wt2
// 	killwaves wt2



//MilliSeconds = stopMSTimer( nTimer) / 1000;   Print "Building....... \t", MilliSeconds, "\t  ms needed for SortByColumn()   rows:", nRows, MilliSeconds/nRows, "ms needed for SortByColumn() per row"; nTimer	= StartMSTimer
	killWaves	wtSortCol , wtSortCol2 , wtSortCol3
//MilliSeconds = stopMSTimer( nTimer) / 1000; 

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
	// printf "\t\tSaveDatabase(  [%s path]\t%s\t%s\t%s\t%s\t%s\t )  save waves\t%s\tinto file '%s' \r" , SelectString( bIsSymbolicPath, "normal", "symbolic" ),  UFCom_pd( sPath,13),  UFCom_pd( sFileNm,25),  UFCom_pd( sBaseF,7),  UFCom_pd(  sFolder,7),  UFCom_pd( lstWantWavesNm, 19),  UFCom_pd(lstWaves,23), sPathFile
End

Function		UFCom_IsSymbolicPath( sPath )
// sPath  can be a normal path (e.g. 'C:dir1:dir2:'  or the string name of a symbolic path (e.g.  'sSymbPath'  or  'ksMYDATAPATH' ) .  The distinction between the 2 is the colon. 
// !!!  Cave   If this proves to be too fragile  instead of  'IsSymbolicPath()'  an additional boolean 'bIsSymb' could be passed to 'SaveDataBase()' .
	string   	sPath
	return	( strsearch( sPath, ":", 0 )  == kNOTFOUND )  ?  TRUE  :  FALSE
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


//==============================================================================================
//  GENERIC  DATABASE  FUNCTIONS  FOR  2DIM  TEXT WAVE

// Constants for displaying a table
static constant			kWIDTHCOL0 		= 30						// width of the 'Row' column
static constant			kTBL_MARGINX	= 20						// bad empirical value to compute the required table window width from the table column widths
static constant			kTBL_BOTTOMYX	= 36						// space for Igors bottom bar (+Windows task bar?)
 
  

Function		UFCom_DisplayTable_( xLeft, yTop, xRight, yBot, wDB, lstColumnNames, lstColumnWidths, lstColumnShades, sTblNm, sTitle, sfHook ) 
// Construct table and display it. If the table existed it is killed first.
	wave 	/T  wDB
	variable	xLeft, yTop, xRight, yBot
	string		lstColumnNames, lstColumnWidths, lstColumnShades, sTblNm, sTitle, sfHook

	
	DoWindow /K $sTblNm
	variable	nColWidth		= UFCom_GetInitialTableWidth( sTblNm, kWIDTHCOL0, lstColumnWidths ) 				// Computing  the required table window width from the table column widths is only approximate...
	variable	yTblHeightPts	= UFCom_GetTableHeight( wDB )								 				// Computing  the required table window height

	variable	rxMinPoints, rxMaxPoints, ryMinPoints, ryMaxPoints, xSz, ySz
	UFCom_GetIgorAppPoints( rxMinPoints, rxMaxPoints, ryMinPoints, ryMaxPoints )
	xSz	  = min( rxMinPoints + (xRight - xLeft)  * ( rxMaxPoints - rxMinPoints ) / 100, nColWidth + kTBL_MARGINX )	// compute before xLeft is changed
	ySz	  = min( ryMinPoints + (yBot	   - yTop)  * ( ryMaxPoints - ryMinPoints - kTBL_BOTTOMYX ) / 100, yTblHeightPts)// compute before yTop is changed
	xLeft	  = 	  rxMinPoints + xLeft 	 * ( rxMaxPoints - rxMinPoints ) / 100
	yTop	  = 	  ryMinPoints + yTop	 * ( ryMaxPoints - ryMinPoints - kTBL_BOTTOMYX ) / 100
	// print "\t\tDisplayTable_()", sTitle, "xmin:", rxMinPoints, "xmax:", rxMaxPoints, "ymin:", ryMinPoints, "ymax:", ryMaxPoints, "-> xSz ", xSz, "-> l t r b " , xLeft, yTop, xLeft+xSz, yTop+ySz	

	//	/K=2  disables the windows close button.  This may seem unnecessary (as the window is killed anyway before it is redisplayed, see above) but by forcing the uses to use the close butten in the panel we ensure that the panel button always displays the correct state.
//	Edit	/K=2	/N=$sTblNm	/W=( xLeft, yTop, xLeft+xSz, yTop+ySz )   wDB  as  sTitle // ...and  kTBL_MARGINX  is only bad empirical value (maybe font and font size matter?...todo...)
	Edit	/K=1	/N=$sTblNm	/W=( xLeft, yTop, xLeft+xSz, yTop+ySz )   wDB  as  sTitle // ...and  kTBL_MARGINX  is only bad empirical value (maybe font and font size matter?...todo...)
	SetWindow $sTblNm , hook( $sfHook ) = $sfHook//, hookCursor=13 , hookEvents=7	// The hook function requires to use a named hook. For saving an extra parameter the name of the hook function is also used for the hook name.
	variable	c,  nColsFromTitles	= ItemsInList( lstColumnNames )
	UFCom_ModifyTableColumnWidth(	wDB, sTblNm, lstColumnWidths, kWIDTHCOL0 ) 
	UFCom_ModifyTableColumnTitles(	wDB, sTblNm, lstColumnNames ) 
	UFCom_ModifyTableColumnShading(wDB, sTblNm, lstColumnShades ) 
	// printf "\t\tDisplayTable_( \t%s\tnColTitles:%3d\tnColWidths:%3d\tnWaveCols:%3d\t   \r",  UFCom_pd( sTblNm, 13), nColsFromTitles, ItemsInList( lstColumnWidths ), DimSize( wDB, 1 )
End


Function		UFCom_DisplayTable__( xLeft, yTop, xRight, yBot, wDB, lstColumnNames, lstColumnWidths, lstColumnShades, sTblNm, sTitle, sfHook ) 
// Construct table and display it. If the table existed it is killed first.
	wave 	/T  wDB
	variable	xLeft, yTop, xRight, yBot
	string		lstColumnNames, lstColumnWidths, lstColumnShades, sTblNm, sTitle, sfHook

	
//	DoWindow /K $sTblNm
//	if ( WinType ( sTblNm ) != kTABLE )

		variable	nColWidth		= UFCom_GetInitialTableWidth( sTblNm, kWIDTHCOL0, lstColumnWidths ) 				// Computing  the required table window width from the table column widths is only approximate...
		variable	yTblHeightPts	= UFCom_GetTableHeight( wDB )								 				// Computing  the required table window height
	
		variable	rxMinPoints, rxMaxPoints, ryMinPoints, ryMaxPoints, xSz, ySz
		UFCom_GetIgorAppPoints( rxMinPoints, rxMaxPoints, ryMinPoints, ryMaxPoints )
		xSz	  = min( rxMinPoints + (xRight - xLeft)  * ( rxMaxPoints - rxMinPoints ) / 100, nColWidth + kTBL_MARGINX )	// compute before xLeft is changed
		ySz	  = min( ryMinPoints + (yBot	   - yTop)  * ( ryMaxPoints - ryMinPoints - kTBL_BOTTOMYX ) / 100, yTblHeightPts)// compute before yTop is changed
		xLeft	  = 	  rxMinPoints + xLeft 	 * ( rxMaxPoints - rxMinPoints ) / 100
		yTop	  = 	  ryMinPoints + yTop	 * ( ryMaxPoints - ryMinPoints - kTBL_BOTTOMYX ) / 100
		// print "\t\tDisplayTable_()", sTitle, "xmin:", rxMinPoints, "xmax:", rxMaxPoints, "ymin:", ryMinPoints, "ymax:", ryMaxPoints, "-> xSz ", xSz, "-> l t r b " , xLeft, yTop, xLeft+xSz, yTop+ySz	
	
		//	/K=2  disables the windows close button.  This may seem unnecessary (as the window is killed anyway before it is redisplayed, see above) but by forcing the uses to use the close butten in the panel we ensure that the panel button always displays the correct state.
	//	Edit	/K=2	/N=$sTblNm	/W=( xLeft, yTop, xLeft+xSz, yTop+ySz )   wDB  as  sTitle // ...and  kTBL_MARGINX  is only bad empirical value (maybe font and font size matter?...todo...)
	if ( WinType ( sTblNm ) != kTABLE )
		Edit	/K=1	/N=$sTblNm	/W=( xLeft, yTop, xLeft+xSz, yTop+ySz )   wDB  as  sTitle // ...and  kTBL_MARGINX  is only bad empirical value (maybe font and font size matter?...todo...)
		SetWindow $sTblNm , hook( $sfHook ) = $sfHook//, hookCursor=13 , hookEvents=7	// The hook function requires to use a named hook. For saving an extra parameter the name of the hook function is also used for the hook name.
	else
//		DoUpdate
//		MoveWindow 	/W=$sTblNm	xLeft, yTop, xLeft+xSz, yTop+ySz  
//		Edit	/K=1	/N=$sTblNm	/W=( xLeft, yTop, xLeft+xSz, yTop+ySz )   wDB  as  sTitle // ...and  kTBL_MARGINX  is only bad empirical value (maybe font and font size matter?...todo...)
//		SetWindow $sTblNm , hook( $sfHook ) = $sfHook//, hookCursor=13 , hookEvents=7	// The hook function requires to use a named hook. For saving an extra parameter the name of the hook function is also used for the hook name.
	endif
		variable	c,  nColsFromTitles	= ItemsInList( lstColumnNames )
		UFCom_ModifyTableColumnWidth(	wDB, sTblNm, lstColumnWidths, kWIDTHCOL0 ) 
		UFCom_ModifyTableColumnTitles(	wDB, sTblNm, lstColumnNames ) 
		UFCom_ModifyTableColumnShading(wDB, sTblNm, lstColumnShades ) 
		// printf "\t\tDisplayTable_( \t%s\tnColTitles:%3d\tnColWidths:%3d\tnWaveCols:%3d\t   \r",  UFCom_pd( sTblNm, 13), nColsFromTitles, ItemsInList( lstColumnWidths ), DimSize( wDB, 1 )
//	endif
End

//Function		KillTable( ctrlName, sTblNm ) 
//	string		ctrlName, sTblNm 
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
	string  	lstFewColumnNames	// the titles of the reduced table containing only some columns
	string  	lstColumnNames	// the titles of the entire wave (=the full table containing all columns)
	string  	sTitle		= UFCom_ColTitle( nColFew, lstFewColumnNames ) 		
	variable	nIndex	= WhichListItem( sTitle, lstColumnNames )
	return	nIndex
End
			// Starting at the original column 'nColOrg'  in the wave   return  the next used  columns by skipping all empty columns.

Function		UFCom_FindReducedColumnIndex( nColAll, lstFewColumnNames, lstColumnNames )
// Return the column index of a  Few-columns-view having the columns  'lstFewColumnNames'  when the original column index  'nColAll' (usually a constant kXX_YYY) corresponding to the full list  'lstColumnNames'  is given .
	variable 	nColAll
	string  	lstFewColumnNames	// the titles of the reduced table containing only some columns
	string  	lstColumnNames	// the titles of the entire wave (=the full table containing all columns)
	string  	sTitle		= UFCom_ColTitle( nColAll, lstColumnNames ) 		
	variable	nIndex	= WhichListItem( sTitle, lstFewColumnNames )
	return	nIndex
End
			// Starting at the original column 'nColOrg'  in the wave   return  the next used  columns by skipping all empty columns.

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


