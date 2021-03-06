//
//  FP_ColorsAndGraphs.ipf 
// 
#pragma rtGlobals=1							// Use modern global access method.

//===============================================================================================================================
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//===============================================================================================================================
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

constant			cBRed=0, cRed=1, cDRed=2, cYellow=3, cBOrange=4, cOrange=5, cBrown=6, cBGreen=7, cGreen=8, cDGreen=9, cBCyan=10, cCyan=11, cDCyan=12, cBBlue=13, cBlue=14, cDBlue=15, cBMag=16, cMag=17, cDMag=18, cBGrey=19, cGrey=20, cBlack=21
strconstant		klstCOLORS = "BRed;Red;DRed;cYellow;BOrange;Orange;Brown;BGreen;Green;DGreen;BCyan;Cyan;DCyan;BBlue;Blue;DBlue;BMag;Mag;DMag;BGrey;Grey;Black"


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  COLORS

Function		CreateGlobalsInFolder_Misc( sFo )
// Creates all folder-specific variables. To be used once from CreateGlobals() as the current data folder is changed and not restored.
	string  	sFo								// 'FPULS'  or  'EVAL' 
// 2009-12-10
//	NewDataFolder  /O  /S root:uf:aco:misc			// make a new data folder and use as CDF,  clear everything
	NewDataFolder  /O  /S $ksROOTUF_ + sFo + ":misc"	// make a new data folder and use as CDF,  clear everything

	CreateColors()
	//string		/G	$"root:uf:sAllTimersOld"			// required only for old timers, e.g.   KillAllTimers( ) , StopTimerl( )  or StartTimer( )
End

Function		CreateColors()  
	// ColorsLinesMarkers.ipf
	// lred  65 42 42    dark red  51  0 0 
	// lor 65 57 42      or  65  47 8    brown  39 26 0
	// lyel  65 65 42    65 65 0     46 46 0
	// l green 42 65 42   065 0    0 44 0
	// lcyan 49 65 65     0 60 60   0 45 45
	// lblue 41,56,65      	 dBlue 0,0,52
	// lmag 60,47,60     60,0,56 	 52, 0, 42
	// lgrey   56 56 56  grey  41 41 41 dgrey 26 26 26
	variable	nMAXCOLOR	= ItemsInList( klstColors )
	make	/O /U /I /N=( nMAXCOLOR )	Red, Green, Blue

	Red[ cBRed ]	= 65535;	Green[ cBRed ]	= 42000;	Blue[ cBRed ]	= 42000;
	Red[ cRed ]	= 65535;	Green[ cRed ]	= 0;		Blue[ cRed ]	= 0;
//	Red[ cDRed ]	= 54000;	Green[ cDRed ]	= 0;		Blue[ cDRed ]	= 0;
	Red[ cDRed ]	= 44000;	Green[ cDRed ]	= 0;		Blue[ cDRed ]	= 0;

	Red[ cYellow ]	= 65535;	Green[ cYellow]	= 65535;	Blue[ cYellow ]	= 0;
	Red[ cBOrange]	= 65535;	Green[ cBOrange]=57000;	Blue[ cBOrange]= 42000;	
	Red[ cOrange ]	= 65535;	Green[ cOrange]= 44000;	Blue[ cOrange ]	= 2000;	
	Red[ cBrown ]	= 44000;	Green[ cBrown ]	= 34000;	Blue[ cBrown ]	= 0;

	Red[ cBGreen ]	= 42000;	Green[ cBGreen]= 65535;	Blue[ cBGreen ]	= 42000;
	Red[ cGreen ]	= 0;		Green[ cGreen]	= 56000;	Blue[ cGreen ]	= 0;
//	Red[ cDGreen ]	= 0;		Green[ cDGreen]= 46000;	Blue[ cDGreen ]	= 0;
	Red[ cDGreen ]	= 0;		Green[ cDGreen]= 36000;	Blue[ cDGreen ]	= 0;

	Red[ cBCyan ]	= 50000;	Green[ cBCyan]	= 65535;	Blue[ cBCyan ]	= 65535;
	Red[ cCyan ]	= 0;		Green[ cCyan ]	= 60000;	Blue[ cCyan ]	= 60000;
//	Red[ cDCyan ]	= 0;		Green[ cDCyan ]= 48000;	Blue[ cDCyan ]	= 48000;
	Red[ cDCyan ]	= 0;		Green[ cDCyan ]= 40000;	Blue[ cDCyan ]	= 40000;

	Red[ cBBlue ]	= 41000;	Green[ cBBlue ]	= 56000;	Blue[ cBBlue ]	= 65535;
	Red[ cBlue ]	= 0;		Green[ cBlue ]	= 0;		Blue[ cBlue ]	= 65535;
	Red[ cDBlue ]	= 0;		Green[ cDBlue ]	= 0;		Blue[ cDBlue ]	= 50000;

	Red[ cBMag ]	= 60000;	Green[ cBMag ]	= 47000;	Blue[ cBMag ]	= 60000;
	Red[ cMag ]	= 60000;	Green[ cMag ]	= 0;		Blue[ cMag ]	= 56000;
//	Red[ cDMag ]	= 52000;	Green[ cDMag ]	= 0;		Blue[ cDMag ]	= 42000;	//ok
	Red[ cDMag ]	= 48000;	Green[ cDMag ]	= 0;		Blue[ cDMag ]	= 38000;	//ok

	Red[ cBGrey ]	= 56000;	Green[ cBGrey ]	= 56000;	Blue[ cBGrey ]	= 56000;
	Red[ cGrey ]	= 41000;	Green[ cGrey ]	= 41000;	Blue[ cGrey ]	= 41000;
	Red[ cBlack ]	= 0;		Green[ cBlack ]	= 0;		Blue[ cBlack ]	= 0;		

// Test the colors
//	make	/O /N=2 kikiX = { -10, 110} 
//	make	/O /N=2 kikiY = { 390, 410} 
//	display kikiY vs kikiX
//	SetDrawLayer		ProgBack
//	SetDrawEnv		linethick =1				,save
//	SetDrawEnv		xcoord = bottom,  ycoord = left	,save	// use axis scaling
//	variable	nColor,  nMAXCOLOR = ItemsInList( klstColors )

//	for ( nColor = 0; nColor < nMAXCOLOR; nColor += 1 )
//		SetDrawEnv	linefgc =( Red[ nColor ], Green[ nColor ], Blue[ nColor ] ), save
//		DrawRect		nColor*4, 400, nColor*4+2, 405 				// draw the rectangle marking the evaluated data point
//	endfor
End

Function		ExtractColors( sRGB, rnRed , rnGreen, rnBlue )
	string  	sRGB
	variable	&rnRed, &rnGreen, &rnBlue
	sRGB = sRGB[ 1, Inf ]						// eliminate leading bracket   e.g.  (65536,0,0  -> 65536,0,0
	rnRed	= str2num( StringFromList( 0, sRGB, "," ) )		
	rnGreen	= str2num( StringFromList( 1, sRGB, "," ) )	
	rnBlue	= str2num( StringFromList( 2, sRGB, "," ) )	
End

//Function	 /S	ComposeColors( nRed , nGreen, nBlue )
//	variable	nRed, nGreen, nBlue
//	string	sRGB
//	sprintf	sRGB, "(%d,%d,%d)", nRed , nGreen, nBlue
//	return	sRGB
//End


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  PROCESSING  GRAPHS

Function		RemoveAllTextBoxes( sWNm )
// remove all  textboxes from the given  acquis window 
	string		sWNm
	variable	n
	string 	sTBList	=  AnnotationList( sWNm )		// Version1: removes ALL annotations  ( e.g. axis unit,  PreparePrinting textbox ...)
	for ( n = 0; n < ItemsInList( sTBList ); n += 1 )
		string		sTBNm	= StringFromList( n, sTBList )
		TextBox	/W=$sWNm   /K  /N=$sTBNm
		// printf "\t\t\t\tRemoveAllTextBoxes( %s )  n:%2d/%2d   \tTBName:'%s' \t'%s'  \r", sWNm, n,  ItemsInList( sTBList ), sTBNm, sTBList
	endfor
End

Function 		EraseTracesInGraph( sWNm )
// erases all traces in the given window (no erasing in TWA, see also Erase_Traces() )
// Cave: IGOR renames remaining traces after every 'RemoveFromGraph' when there are 2 traces (e.g. Tr0 and Tr0#1) and Tr0 is removed, then the remaining Tr0#1 is renamed Tr0  
// To circumvent this: Either erase from the back (fast but perhaps not always working) or rebuild TNL after every remove.(see CbButtonDelete for code snippet)..
	string 		sWNm
	string 		sTNL	= TraceNameList( sWNm, ";", 1 )
	variable	t, tcnt
	tCnt =  ItemsInList( sTNL ) 			// erase traces on screen 
	// printf "\tEraseTracesInGraph  wnd:%s TrcNmList:%s \r", sWNm, sTNL[0,160]	
	for ( t = tCnt - 1; t >= 0; t -= 1 )		// erase traces on screen (move backwards through list to circumvent IGORs renaming of traces
		RemoveFromGraph  /W=$sWNm $StringFromList( t, sTNL )
		// printf "\t\tEraseTracesInGraph  wnd:%s  erasing  TrcNm:%s  \tfrom  sTNL:'%s'   \t-> leaving '%s' \r", sWNm, pd(StringFromList( t, sTNL ),12), sTNL, TraceNameList( sWNm, ";", 1 )
	endfor
	sTNL	= TraceNameList( sWNm, ";", 1 )	// should by now be empty
	if ( strlen( sTNL ) )
		InternalError( "EraseTracesInGraph( " + sWNm + " ) failed leaving traces '" + sTNL )
	endif
End



Function 		EraseTracesInGraphExcept( sWNm, lstKeepMatches )
// erases all traces in the given window except those starting as the items in 'lstMatch' 
// Cave: IGOR renames remaining traces after every 'RemoveFromGraph'  when there are 2 traces (e.g. Tr0 and Tr0#1) and Tr0 is removed, then the remaining Tr0#1 is renamed Tr0  
	string 	sWNm, lstKeepMatches
	string 	sTNm, sTNL	= TraceNameList( sWNm, ";", 1 )
	variable	t, tcnt		=  ItemsInList( sTNL ) 		
	
	// printf "\tEraseTracesInGraphExcept( 1 %s,  %s )  traces:%d  TrcNmList:%s \r", sWNm, lstKeepMatches, ItemsInList( sTNL ), sTNL[0,160]	

	// 050729		Does not work smoothly because of an unwanted side effect: x-axis always starts at x=-1	
	// make	/O /n=0 wDummy			// draw an invisible dummy wave which will not be erased as it is not contained in  sTNL..
	// AppendToGraph  /W=$sWNm wDummy	// ..which prevents that the axis are removed after the last trace in sTNL is erased

	variable	bKeep
	variable	k, nKeepMatches = ItemsInList( lstKeepMatches )
	string  	sKeepMatch
	for ( t = tCnt - 1; t >= 0; t -= 1 )										// erase traces on screen (move backwards through list to circumvent IGORs renaming of traces
		sTNm	= StringFromList( t, sTNL )
		bKeep	= FALSE
		for ( k = 0; k < nKeepMatches; k += 1 )
			sKeepMatch	=  StringFromList( k, lstKeepMatches )
			if ( cmpstr( sTNm[ 0, strlen( sKeepMatch ) - 1 ], sKeepMatch ) == 0 )	// check each trace on screen if it belongs to those traces  (=lstKeepMatches) which are not to be erased
				bKeep	= TRUE
				break
			endif				
		endfor
		if ( bKeep == FALSE )
			RemoveFromGraph  /W=$sWNm $sTNm
			// printf "\tEraseTracesInGraphExcept( 2 %s,  %s )\terasing \t%s\tfrom  sTNL[traces:%3d] :'%s...' \t-> leaving\t[traces:%3d]\t'%s' \r", sWNm, lstKeepMatches, pd(sTNm,12), tCnt, sTNL[0,100], ItemsInList( TraceNameList( sWNm, ";", 1 ) ), TraceNameList( sWNm, ";", 1 )[0,100]
		endif
	endfor
	// printf "\tEraseTracesInGraphExcept( 3 %s,  %s )\tleaving \t[traces:%3d]\t'%s'  \r", sWNm, lstKeepMatches, ItemsInList( TraceNameList( sWNm, ";", 1 ) ),  TraceNameList( sWNm, ";", 1 )[ 0, 160 ]
End

Function 		EraseMatchingTraces( sWNm, sMatch )
// Erases all traces in the given window which start with  'sMatch' . This is useful for removing traces with any BegPt   e.g.  'AdcFM_'   will be remove  'AdcFM_0' ,  'AdcFM_1000' ,  'AdcFM_12345' 
	string 	sWNm, sMatch
	string 	sTNL	= TraceNameList( sWNm, ";", 1 )
	string  	lstMatch	= ListMatch( sTNL, sMatch + "*" )
	variable	t, tcnt	=  ItemsInList( lstMatch ) 			
	// printf "\t\tEraseMatchingTraces  wnd:%s    '%s'  erasing %d : '%s'   TNL[%d]:%s \r", sWNm, sMatch, tcnt, lstMatch[0,80],  ItemsInList( sTNL ) , sTNL[0,80]	

//	for ( t = tCnt - 1; t >= 0; t -= 1 )								// ...may here not be necessary..........erase traces on screen (move backwards through list to circumvent IGORs renaming of traces
	for ( t = 0; t < tcnt; t += 1 )
		RemoveFromGraph  /W=$sWNm $StringFromList( t, lstMatch )	
		 //printf "\t\tEraseMatchingTraces  wnd:%s  erasing  TrcNm:%s  \tfrom  sTNL:'%s'   \t-> leaving '%s' \r", sWNm, pd(StringFromList( t, lstMatch ),12), lstMatch, TraceNameList( sWNm, ";", 1 )
	endfor
	// printf "\t\tEraseMatchingTraces  wnd:%s    '%s'  leaving %d : '%s'  \r", sWNm, sMatch, ItemsInList( TraceNameList( sWNm, ";", 1 ) )  , TraceNameList( sWNm, ";", 1 )
End



//Function 		EraseTracesInGraphExceptOld( sWNm, sMatch )
//// erases all traces in the given window except those starting with  'sMatch' 
//// Cave: IGOR renames remaining traces after every 'RemoveFromGraph'  when there are 2 traces (e.g. Tr0 and Tr0#1) and Tr0 is removed, then the remaining Tr0#1 is renamed Tr0  
//	string 	sWNm, sMatch
//	string 	sTNm, sTNL	= TraceNameList( sWNm, ";", 1 )
//	variable	t, tcnt		=  ItemsInList( sTNL ) 		
//	variable	len			= strlen( sMatch )
//	
//	// printf "\tEraseTracesInGraphExceptOld( 1 %s,  %s )  traces:%d  TrcNmList:%s \r", sWNm, sMatch, ItemsInList( sTNL ), sTNL[0,160]	
//
//	// 050729		Does not work smoothly because of an unwanted side effect: x-axis always starts at x=-1	
//	// make	/O /n=0 wDummy			// draw an invisible dummy wave which will not be erased as it is not contained in  sTNL..
//	// AppendToGraph  /W=$sWNm wDummy	// ..which prevents that the axis are removed after the last trace in sTNL is erased
//
//	for ( t = tCnt - 1; t >= 0; t -= 1 )		// erase traces on screen (move backwards through list to circumvent IGORs renaming of traces
//		sTNm	= StringFromList( t, sTNL )
//// 050801   TODO..............
//// erase data, cursors, points
////		if ( cmpstr( sTNm[ 0, len-1 ] , sMatch ) )
//// erase data and cursors
////		if ( cmpstr( sTNm[ 0, len-1 ] , sMatch )  &&  cmpstr( sTNm[ 0, 3 ], "wpY_"  )	 )								// !!! Assumption cursor waves have the name 'wcY_...'
//// erase data and points, leave cursors
//
//// 060404
//// Ugly bad code
//// erase data
////		if ( cmpstr( sTNm[ 0, len-1 ], sMatch )  &&  cmpstr( sTNm[ 0, 3 ], "wcY_" )   &&  cmpstr( sTNm[ 0, 3 ], "wpY_"  )	 )		// !!! Assumption point waves have the name 'wpY_...'
//		if ( cmpstr( sTNm[ 0, len-1 ], sMatch )  &&  cmpstr( sTNm[ 0, strlen(ksCSR)-1 ], ksCSR )   &&  cmpstr( sTNm[ 0, strlen(ksORS)-1 ], ksORS) )	// !!! Assumption point waves have the name 'ors..'
//
//			RemoveFromGraph  /W=$sWNm $sTNm
//			// printf "\tEraseTracesInGraphExceptOld( 2 %s,  %s )\terasing \t%s\tfrom  sTNL[traces:%3d] :'%s...' \t-> leaving\t[traces:%3d]\t'%s' \r", sWNm, sMatch, pd(sTNm,12), tCnt, sTNL[0,100], ItemsInList( TraceNameList( sWNm, ";", 1 ) ), TraceNameList( sWNm, ";", 1 )[0,100]
//		endif
//	endfor
//	// printf "\tEraseTracesInGraphExceptOld( 3 %s,  %s )\tleaving \t[traces:%3d]\t'%s'  \r", sWNm, sMatch, ItemsInList( TraceNameList( sWNm, ";", 1 ) ),  TraceNameList( sWNm, ";", 1 )[ 0, 160 ]
//End




//Function	/S	RemoveAllLike( sList, sMatch )
//// removes all traces from  'sList'  starting with  'sMatch' 
//	string 	sList, sMatch
//	 printf "RemoveAllLike( 1 %s,  %s ) \r", sMatch, sList[ 0, 160 ]
//	sList	= ListMatch( sList, "!" + sMatch + "*" )
//	 printf "RemoveAllLike( 2 %s,  %s )  \r", sMatch, sList[ 0, 160 ]
//	return	sList
//End

// 060915
//Function  		KillAllGraphs()
//	KillGraphs( "*", ksW_WNM )				// also kills StatusBar which is probably not intended
//End 


//Function  	KillGraphsUnsorted( sMatch )
//// Kills graphs without sorting
//	string 	sMatch
//	variable	n, nItems
//	string 	lstDeleteWnds = WinList( sMatch,  ";" , "WIN:" + num2str( kGRAPH ) )		
//	// lstDeleteWnds	= SortListExt( lstDeleteWnds, sWndBaseNm, kSORTNUMERICAL )
//	nItems		= ItemsInList( lstDeleteWnds )
//	// print "\tKillGraphs() ", sMatch, "deleting  items:", nItems,  lstDeleteWnds 
//	for ( n = nItems - 1; n >= 0;  n -= 1 )
//		// print "\tKillGraphs() ", sMatch, "deleting item: ", n, StringFromList( n, lstDeleteWnds ), "old list (invalid after compacting..)  ", lstDeleteWnds 
//		DoWindow /K $StringFromList( n, lstDeleteWnds )	
//	endfor
//End 

Function  	KillGraphs( sMatch, sWndBaseNm )
// As we compact (=renumber) the acquis graphs automatically whenever a window is killed and as Igors WinList() returns an unsorted list (very arbitrary order!) ...
// ...we may get a large number of compacting moves (worst case : (n+1)*n/2  )  if we do not sort the list of the windows to be deleted. 
// For example  WinList() returns unsorted list W2,W0,W3, W1 : If we kill from end  W2,W0,W3  we get compacting moves to be avoided  W3->W2, W2->W1  and so on
// When sorting ascending and killing from the end the number of compacting moves is reduced to 0. 
// The compacting is required whenever the user kills any acquis window (except the highest). Here in KillAllGraphs() it is not needed  but  cannot? be avoided ....
// An added advantage of the sorting is that we can use a FOR-NEXT-loop, without sorting we would have to use a DO-WHILE-loop  plus  an  IF... 
// ..and we would have to REBUILD the window list within the loop everytime a window is killed (e.g. without  rebuild W0,W2,W1...
// .. Igor would kill W1, then W2 then W0  but after killing W1  the compact-move change the remaining list from W0,W2  to W0,W1  and  W2 can no longer be killed....
	string 	sMatch, sWndBaseNm
	variable	n, nItems
	string 	lstDeleteWnds
	lstDeleteWnds	= WinList( sMatch,  ";" , "WIN:" + num2str( kGRAPH ) )		
	lstDeleteWnds	= SortListExt( lstDeleteWnds, sWndBaseNm, kSORTNUMERICAL )
	nItems		= ItemsInList( lstDeleteWnds )
	// print "\tKillGraphs() ", sMatch, "deleting  items:", nItems,  lstDeleteWnds 
	for ( n = nItems - 1; n >= 0;  n -= 1 )
		print "\tKillGraphs() sMatch:", sMatch, "deleting item: ", n, StringFromList( n, lstDeleteWnds ), "old list (invalid after compacting..)  ", lstDeleteWnds 
		DoWindow /K $StringFromList( n, lstDeleteWnds )	
	endfor
End 


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function		PossiblyKillPanel( sWndNm )
// Attempts to delete a panel from screen. Does nothing if the panel does not exist.  Does not delete the underlying panel text wave 'tPnxxx"
	string  	sWndNm
	PossiblyKillWindow( sWndNm, kPANEL )
End	


Function		PossiblyKillNotebook( sWndNm )
// Attempts to delete a panel from screen. Does nothing if the panel does not exist.  Does not delete the underlying panel text wave 'tPnxxx"
	string  	sWndNm
	PossiblyKillWindow( sWndNm, kNOTEBOOK )
End	


Function		PossiblyKillWindow( sWndNm, nWndType )
// Attempts to delete any window from screen. Does nothing if the window does not exist.  
	string  	sWndNm
	variable	nWndType
	if ( WinType( sWndNm ) == nWndType )
		KillWindow	$sWndNm
	endif
End	

//===============================================================================================================================
//  WINDOW  LOCATIONS

static constant		YFREELO_FOR_SB_AND_CMDWND	= 140	// points
static constant		YNAMELINE						= 20		// points

Function		IsMinimized( sWndName, xl, yt, xr, yb  )
// Return if  'sWndName'   is currently minimized.   Also return as params the current window location which is only useful if the window was not minimized.
	string  	sWndName
	variable	&xl, &yt, &xr, &yb									// parameters changed by function
	GetWindow $sWndName , wSize							// Get the existing windows coordinates...
	xl = V_left												// ...and return them  (only useful if the window was not minimized)
	yt = V_top
	xr = V_right
	yb = V_bottom											
	// print	"IsMinimized", xl, yt, xr, yb
	return  ( xl == xr  &&  yt == yb )  
End
	
	
Function		IsMinimized1( sWndName )
// Return if  'sWndName'   is currently minimized.  
	string  	sWndName
	GetWindow $sWndName , wSize							// Get the existing windows coordinates...
	return  ( V_left == V_right  &&  V_top == V_bottom )  
End
	
// 060915	
//Function		GetDefaultScriptOrStimWndLoc( sFolder,  bScriptOrStim, xl, yt, xr, yb ) 
//// Compute a largely arbitrary window location and return the coordinates as parameters. nOfsX, nOfsY can be used to specify  TopRight  or  MidLeft etc...
//	string  	sFolder
//	variable	bScriptOrStim
//	variable	&xl, &yt, &xr, &yb													// 	parameters changed by function
//	variable	nOfsX = 0, nOfsY = 0
//	if ( cmpstr( sFolder, ksEVAL ) == 0 )								// the script windows in  FPULS  and in  Eval  are offset a bit... 
//		nOfsX += 10											//...so that they don't cover each other completely  
//		nOfsY += 20
//	endif
//	variable	rxMinPoints, rxMaxPoints, ryMinPoints, ryMaxPoints 						// ...compute default position 
//	GetIgorAppPoints( rxMinPoints, rxMaxPoints, ryMinPoints, ryMaxPoints )					// 	parameters changed by function
//	variable	 UsableYPoints = ryMaxPoints - ryMinPoints - YFREELO_FOR_SB_AND_CMDWND
//	// or : if ( cmpstr( sSubFolder, ":stim" ) )
//	if ( bScriptOrStim == kSTIM )												
//		xl = 2  + nOfsX														// The upper screen half... 
//		yt = kIGOR_YMIN_WNDLOC + nOfsY										// ...is for the stimulus graph
//		xr = rxMaxPoints / 2  + nOfsX; 
//		yb = kIGOR_YMIN_WNDLOC + UsableYPoints / 2+ nOfsY						
//	elseif ( bScriptOrStim == kSCRIPT )
//		xl = 2  + nOfsX														// The lower screen half...
//		yt = kIGOR_YMIN_WNDLOC + UsableYPoints / 2 + YNAMELINE + nOfsY			// ...is for the script text
//		xr = rxMaxPoints / 2  + nOfsX; 
//		yb = kIGOR_YMIN_WNDLOC + UsableYPoints + YNAMELINE + nOfsY	
//	endif
//End

Function		StoreWndLoc( sFolder, xl, yt, xr, yb )
// Save the stimulus window coordinates
	string  	sFolder
	variable	xl, yt, xr, yb
	string  	sDFSave	= GetDataFolder( 1 )
	 printf "\t\t\tStoreWndLoc(0  \t%s ) \tx: %3d ...%3d ,    \ty: %3d  ...  %3d \tGetDataFolder : '%s' \r", sFolder, xl, xr, yt, yb, GetDataFolder(1)
	nvar	/Z 	gxl	= $ksROOTUF_ + sFolder + ":gxl"
	if ( ! nvar_exists( gxl ) )
		NewDataFolder  /O  /S $ksROOTUF_ + sFolder 
		variable 	/G 	$ksROOTUF_ + sFolder + ":gxl"
		variable 	/G 	$ksROOTUF_ + sFolder + ":gyt"
		variable 	/G 	$ksROOTUF_ + sFolder + ":gxr"
		variable 	/G 	$ksROOTUF_ + sFolder + ":gyb"
	endif		
	nvar	 	gxl  	= $ksROOTUF_ + sFolder + ":gxl"
	nvar		gyt  	= $ksROOTUF_ + sFolder + ":gyt"
	nvar		gxr  	= $ksROOTUF_ + sFolder + ":gxr"
	nvar		gyb 	= $ksROOTUF_ + sFolder + ":gyb"
	gxl  = xl	;	gyt  = yt	;	gxr  = xr	;	gyb  = yb
	SetDataFolder $sDFSave
	// printf "\t\t\tStoreWndLoc(1  \t%s ) \tx: %3d ...%3d ,    \ty: %3d  ...  %3d \tGetDataFolder : '%s'    ?$sDF? %s \r", sFolder, xl, xr, yt, yb, GetDataFolder(1), sDFSave
End	

Function		RetrieveWndLoc( sFolder, xl, yt, xr, yb )
// Return the window coordinates
	string  	sFolder
	variable	&xl, &yt, &xr, &yb
	nvar	 	gxl  	= $ksROOTUF_ + sFolder + ":gxl"
	nvar		gyt  	= $ksROOTUF_ + sFolder + ":gyt"
	nvar		gxr  	= $ksROOTUF_ + sFolder + ":gxr"
	nvar		gyb 	= $ksROOTUF_ + sFolder + ":gyb"
	xl	= gxl	;	yt	= gyt	;	xr	= gxr	;	yb	= gyb
	// printf "\t\t\tRetrieveWndLoc(\t%s ) \tx: %3d ...%3d ,    \ty: %3d  ...  %3d \r", sFolder, xl, xr, yt, yb
End


