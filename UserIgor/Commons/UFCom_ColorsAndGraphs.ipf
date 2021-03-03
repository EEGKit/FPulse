//
//  UFCom_ColorsAndGraphs.ipf 
// 
#pragma rtGlobals=1							// Use modern global access method.

//#pragma IndependentModule=UFCom_

#include <WMColorPicker>

#include "UFCom_Constants"					// for UFCom_lstCOLORS
#include "UFCom_Errors"						// for 
#include "UFCom_ListProcessing"				// for 


//==========================================================================================================================================
//  COLORS

Function		UFCom_CreateGlobalsInFold_Misc( sFo )
// Creates all folder-specific variables. To be used once from CreateGlobals() as the current data folder is changed and not restored.
	string  	sFo								// 'ACQ'  or  'EVAL' 
	NewDataFolder  /O  /S $"root:uf:" + sFo + ":misc	"	// make a new data folder and use as CDF,  clear everything
// 2009-07-01 removed during the great cleanup
//	UFCom_CreateColors()
	string		/G	sAllTimers						// list of  arbitrary timer names, numbers (0..9) and values
End

// 2009-07-01 removed during the great cleanup
//Function		UFCom_CreateColors()  
//	// ColorsLinesMarkers.ipf
//	// lred  65 42 42    dark red  51  0 0 
//	// lor 65 57 42      or  65  47 8    brown  39 26 0
//	// lyel  65 65 42    65 65 0     46 46 0
//	// l green 42 65 42   065 0    0 44 0
//	// lcyan 49 65 65     0 60 60   0 45 45
//	// lblue 41,56,65      	 dBlue 0,0,52
//	// lmag 60,47,60     60,0,56 	 52, 0, 42
//	// lgrey   56 56 56  grey  41 41 41 dgrey 26 26 26
//	variable	nMAXCOLOR	= ItemsInList( UFCom_lstCOLORS )
//	make	/O /U /I /N=( nMAXCOLOR )	Red, Green, Blue
//
//	Red[ UFCom_cBRed ]	= 65535;	Green[ UFCom_cBRed ]	= 42000;	Blue[ UFCom_cBRed ]	= 42000;
//	Red[ UFCom_cRed ]		= 65535;	Green[ UFCom_cRed ]	= 0;		Blue[ UFCom_cRed ]		= 0;
////	Red[ UFCom_cDRed ]	= 54000;	Green[ UFCom_cDRed ]	= 0;		Blue[ UFCom_cDRed ]	= 0;
//	Red[ UFCom_cDRed ]	= 44000;	Green[ UFCom_cDRed ]	= 0;		Blue[ UFCom_cDRed ]	= 0;
//
//	Red[ UFCom_cYellow ]	= 65535;	Green[ UFCom_cYellow]	= 65535;	Blue[ UFCom_cYellow ]	= 0;
//	Red[ UFCom_cBOrange]	= 65535;	Green[ UFCom_cBOrange]	=57000;	Blue[ UFCom_cBOrange]	= 42000;	
//	Red[ UFCom_cOrange ]	= 65535;	Green[ UFCom_cOrange]	= 44000;	Blue[ UFCom_cOrange ]	= 2000;	
//	Red[ UFCom_cBrown ]	= 44000;	Green[ UFCom_cBrown ]	= 34000;	Blue[ UFCom_cBrown ]	= 0;
//
//	Red[ UFCom_cBGreen ]	= 42000;	Green[ UFCom_cBGreen]	= 65535;	Blue[ UFCom_cBGreen ]	= 42000;
//	Red[ UFCom_cGreen ]	= 0;		Green[ UFCom_cGreen]	= 56000;	Blue[ UFCom_cGreen ]	= 0;
////	Red[ UFCom_cDGreen ]	= 0;		Green[ UFCom_cDGreen]	= 46000;	Blue[ UFCom_cDGreen ]	= 0;
//	Red[ UFCom_cDGreen ]	= 0;		Green[ UFCom_cDGreen]	= 36000;	Blue[ UFCom_cDGreen ]	= 0;
//
//	Red[ UFCom_cBCyan ]	= 50000;	Green[ UFCom_cBCyan]	= 65535;	Blue[ UFCom_cBCyan ]	= 65535;
//	Red[ UFCom_cCyan ]		= 0;		Green[ UFCom_cCyan ]	= 60000;	Blue[ UFCom_cCyan ]	= 60000;
////	Red[ UFCom_cDCyan ]	= 0;		Green[ UFCom_cDCyan ]	= 48000;	Blue[ UFCom_cDCyan ]	= 48000;
//	Red[ UFCom_cDCyan ]	= 0;		Green[ UFCom_cDCyan ]	= 40000;	Blue[ UFCom_cDCyan ]	= 40000;
//
//	Red[ UFCom_cBBlue ]	= 41000;	Green[ UFCom_cBBlue ]	= 56000;	Blue[ UFCom_cBBlue ]	= 65535;
//	Red[ UFCom_cBlue ]		= 0;		Green[ UFCom_cBlue ]	= 0;		Blue[ UFCom_cBlue ]		= 65535;
//	Red[ UFCom_cDBlue ]	= 0;		Green[ UFCom_cDBlue ]	= 0;		Blue[ UFCom_cDBlue ]	= 50000;
//
//	Red[ UFCom_cBMag ]	= 60000;	Green[ UFCom_cBMag ]	= 47000;	Blue[ UFCom_cBMag ]	= 60000;
//	Red[ UFCom_cMag ]		= 60000;	Green[ UFCom_cMag ]	= 0;		Blue[ UFCom_cMag ]		= 56000;
////	Red[ UFCom_cDMag ]	= 52000;	Green[ UFCom_cDMag ]	= 0;		Blue[ UFCom_cDMag ]	= 42000;	//ok
//	Red[ UFCom_cDMag ]	= 48000;	Green[ UFCom_cDMag ]	= 0;		Blue[ UFCom_cDMag ]	= 38000;	//ok
//
//	Red[ UFCom_cBGrey ]	= 56000;	Green[ UFCom_cBGrey ]	= 56000;	Blue[ UFCom_cBGrey ]	= 56000;
//	Red[ UFCom_cGrey ]		= 41000;	Green[ UFCom_cGrey ]	= 41000;	Blue[ UFCom_cGrey ]		= 41000;
//	Red[ UFCom_cBlack ]	= 0;		Green[ UFCom_cBlack ]	= 0;		Blue[ UFCom_cBlack ]	= 0;		
//
//// Test the colors
////	make	/O /N=2 kikiX = { -10, 110} 
////	make	/O /N=2 kikiY = { 390, 410} 
////	display kikiY vs kikiX
////	SetDrawLayer		ProgBack
////	SetDrawEnv		linethick =1				,save
////	SetDrawEnv		xcoord = bottom,  ycoord = left	,save	// use axis scaling
////	variable	nColor,  nMAXCOLOR = ItemsInList( klstColors )
//
////	for ( nColor = 0; nColor < nMAXCOLOR; nColor += 1 )
////		SetDrawEnv	linefgc =( Red[ nColor ], Green[ nColor ], Blue[ nColor ] ), save
////		DrawRect		nColor*4, 400, nColor*4+2, 405 				// draw the rectangle marking the evaluated data point
////	endfor
//End

Function		UFCom_ExtractColors( sRGB, rnRed , rnGreen, rnBlue )
	string  	sRGB
	variable	&rnRed, &rnGreen, &rnBlue
	sRGB = sRGB[ 1, Inf ]						// eliminate leading bracket   e.g.  (65536,0,0  -> 65536,0,0
	rnRed	= str2num( StringFromList( 0, sRGB, "," ) )		
	rnGreen	= str2num( StringFromList( 1, sRGB, "," ) )	
	rnBlue	= str2num( StringFromList( 2, sRGB, "," ) )	
End

//static Function	 /S	ComposeColors( nRed , nGreen, nBlue )
//	variable	nRed, nGreen, nBlue
//	string	sRGB
//	sprintf	sRGB, "(%d,%d,%d)", nRed , nGreen, nBlue
//	return	sRGB
//End

// 2009-07-01 removed during the great cleanup
//Function		UFCom_Color( sFo, sColorNm, rnRed , rnGreen, rnBlue )
//// Return 3 color values for regions when 'sColorNm' is given.   Uses color WAVES.
//	string  	sFo, sColorNm
//	variable	&rnRed, &rnGreen, &rnBlue
//	string  	lstColors	= UFCom_RemoveWhiteSpace( UFCom_lstCOLORS )
//	variable	nColor	= WhichListItem( sColorNm, lstColors, ";", 0, 0 )
//	if ( nColor == UFCom_kNOTFOUND )
//		nColor = 0
//		printf "Internal error: '%s'  is not an element of '%s' .   Using '%s' .\r", sColorNm, lstColors, StringFromList( nColor, lstColors )
//	endif
//	wave	Red 		= $"root:uf:" + sFo + ":misc:Red",   Green = $"root:uf:" + sFo + ":misc:Green",   Blue = $"root:uf:" + sFo + ":misc:Blue"
//	rnRed	= Red[ nColor ]
//	rnGreen	= Green[ nColor ]
//	rnBlue	= Blue[ nColor ]
//	printf "\t\tUFCom_Color  using waves : \t'%s'  returns \t\t\tR:%d  G:%d  B:%d  \r",  sColorNm, rnRed , rnGreen, rnBlue
//End	


Function		UFCom_Color_( sColorNm, rnRed , rnGreen, rnBlue )
// Return 3 color values for regions when 'sColorNm' is given.   Uses a color LIST.
	string  	sColorNm
	variable	&rnRed, &rnGreen, &rnBlue
	string  	lstColors	= UFCom_RemoveWhiteSpace( UFCom_lstCOLORS )
	variable	nColor	= WhichListItem( sColorNm, lstColors, ";", 0, 0 )
	if ( nColor == UFCom_kNOTFOUND )
		nColor = 0
		printf "Internal error: '%s'  is not an element of '%s' .   Using '%s' .\r", sColorNm, lstColors, StringFromList( nColor, lstColors )
	endif
	string  	sRGB	= UFCom_RemoveWhiteSpace( StringFromList( nColor, UFCom_COLORS ) )
	rnRed	= str2num( StringFromList( 0, sRGB, ","  ) )
	rnGreen	= str2num( StringFromList( 1, sRGB, ","  ) )
	rnBlue	= str2num( StringFromList( 2, sRGB, ","  ) )
	// printf "\t\tUFCom_Color  using    list   : \t'%s'  returns '%s'  \tR:%d  G:%d  B:%d  \r",  sColorNm, sRGB, rnRed , rnGreen, rnBlue
End	

//==========================================================================================================================================
//  PROCESSING  GRAPHS

Function	/S	UFCom_DataWndNm( sFolder, ch )
	string  	sFolder
	variable	ch											//   window names must not contain '('  or  ')'	
	return	sFolder + num2str( ch ) 			 				// e.g. 'MDet0' , 'MDet1'
End

Function		UFCom_DataWndNm2Ch( sCfsWndNm )
	string		sCfsWndNm 
	return	UFCom_TrailingDigit( sCfsWndNm )					// extract the last character which must be a digit and convert to a number
End


Function		UFCom_RemoveTraceKillWave( sWNm, sFoWave )
// Note: Removes only the last instance of a trace in a graph so that possibly not all traces belonging to 'sFoWave' are removed.  THIS IS CONFUSING!		???
	string		sWNm, sFoWave
	wave /Z	wv	= $sFoWave
	if ( waveExists( wv ) )
		if ( WinType( sWNm ) )		// only if window exists
			string  	sTrace	= NameOfWave( wv )
			UFCom_EraseMatchingTraces( sWNm, sTrace )// Removing the trace from any graph is required  before we can attempt to delete the wave	DOES NOT WORK
			RemoveFromGraph /W=$sWNm  /Z  $sTrace	// Removing the trace from any graph is required ..
			printf "\t\t\tUFCom_RemoveTraceKillWave  \tremoving\t%s\t%s\t%s\tTraces left:%2d\t%s\t \r",  sWNm, UFCom_pd( sTrace,19), UFCom_pd(sFoWave,53),  ItemsInList( TraceNameList( sWNm, ";" , 1 )), TraceNameList( sWNm, ";" , 1 )[0,200]
		endif
		KillWaves /Z wv						// After the trace has been removed we can delete the corresponding wave
	endif
End


Function		UFCom_RemoveAllTextBoxes( sWNm )
// remove all  textboxes from the given  acq window 
	string		sWNm
	variable	n
	string 	sTBList	=  AnnotationList( sWNm )		// Version1: removes ALL annotations  ( e.g. axis unit,  PreparePrinting textbox ...)
	for ( n = 0; n < ItemsInList( sTBList ); n += 1 )
		string		sTBNm	= StringFromList( n, sTBList )
		TextBox	/W=$sWNm   /K  /N=$sTBNm
		// printf "\t\t\t\tRemoveAllTextBoxes( %s )  n:%2d/%2d   \tTBName:'%s' \t'%s'  \r", sWNm, n,  ItemsInList( sTBList ), sTBNm, sTBList
	endfor
End


Function		UFCom_PossiblyDisplayGraph( sWNm )
	string  	sWNm
	if ( WinType ( sWNm ) == 0 )
		display /K=1 /N=$sWNm 
	endif
End

Function		UFCom_PossiblyAppendToGraphW( sWNm, wv, red, green, blue )
	string  	sWNm
	wave	wv
	variable	red, green, blue 
	string 	sTNL	= TraceNameList( sWNm, ";", 1 )
	if ( WhichListItem( NameOfWave( wv ) , sTNL ) == UFCom_kNOTFOUND )
		AppendToGraph /W=$sWNm /C=(red,green,blue)  wv
	endif
End

Function		UFCom_PossiblyAppendToGraph( sWNm, sFoWvNm, red, green, blue )
	string  	sWNm, sFoWvNm
	variable	red, green, blue 
	wave	wv	=  $sFoWvNm
	UFCom_PossiblyAppendToGraphW( sWNm, wv, red, green, blue )
End

Function		UFCom_PossiblyAppendToGraphAxL( sWNm, sFoWvNm, red, green, blue, sAxis )
	string  	sWNm, sFoWvNm, sAxis
	variable	red, green, blue 
	string 	sTNL	= TraceNameList( sWNm, ";", 1 )
	if ( WhichListItem( NameOfWave( $sFoWvNm ) , sTNL ) == UFCom_kNOTFOUND )
		AppendToGraph /W=$sWNm /C=(red,green,blue)  /L=$sAxis  $sFoWvNm
	endif
End

Function		UFCom_PossiblyAppendToGraphAxR( sWNm, sFoWvNm, red, green, blue, sAxis )
	string  	sWNm, sFoWvNm, sAxis
	variable	red, green, blue 
	string 	sTNL	= TraceNameList( sWNm, ";", 1 )
	if ( WhichListItem( NameOfWave( $sFoWvNm ) , sTNL ) == UFCom_kNOTFOUND )
		AppendToGraph /W=$sWNm /C=(red,green,blue)  /R=$sAxis  $sFoWvNm
	endif
End

Function		UFCom_PossAppendToGraphWvAxR( sWNm, wv, red, green, blue, sAxis )
	string  	sWNm, sAxis
	wave	wv
	variable	red, green, blue 
	string 	sTNL	= TraceNameList( sWNm, ";", 1 )
	if ( WhichListItem( NameOfWave( wv ) , sTNL ) == UFCom_kNOTFOUND )
		AppendToGraph /W=$sWNm /C=(red,green,blue)  /R=$sAxis  wv
	endif
	
End

//--------------------------------------------------------------------------------------------------------------------------------------------------


Function		UFCom_PrintTNL( sText, sWNm )
// Prints debugging information about all traces in window 'sWNm'
	string  	sText, sWNm
	string 	sTNL			= TraceNameList( sWNm, ";", 1 )
	variable	n, nTraces			= ItemsInList( sTNL )
	for ( n = 0; n < nTraces; n += 1 )
		wave	wv			= WaveRefIndexed( sWNm, n, 1 )
		variable	pts			= numPnts( wv )
		string  	sFoWv		= GetWavesDataFolder( wv, 2 )			// 1 returns full path of data folder containing waveName but without wave name.  2 returns full folder path and wave name
		string  	sFo			= UFCom_RemoveLastListItems(1,sFoWv, ":")
		string  	sTrc			= UFCom_LastListItems( 1, sFoWv, ":" )	// is more robust than StringFromList( n, sTNL )  unless it is guaranteeed that  WaveRefIndexed() and TraceNameList() return entries in the same order.
		string  	sTrcFromTNL	= StringFromList( n, sTNL ) 
		string  	sAxisInfo		= TraceInfo( sWNm, "", n )
		string  	sYAxis		= StringByKey( "YAXIS", sAxisInfo )
		printf "\t\t%s\tPrintTNL\tWnd: '%s'\tn:%3d\t/ %3d\t%s\t%s\t%s\t<- from TNL\tpts:\t%8.0lf\tyAx:\t%s\t  \r", SelectString( n>0, UFCom_pad(sText,19), "\t\t\t\t"), sWNm, n, nTraces, UFCom_pd(sFo,49),  UFCom_pd(sTrc,27),  UFCom_pd(sTrcFromTNL,27),  pts, UFCom_pd(sYAxis,9)
	endfor
End

Function		UFCom_WaveExistsInGraph( sWNm, wv )
	string  	sWNm
	wave	wv
	CheckDisplayed /W=$sWNm  wv
	return	V_flag
//// 2010-08-19 fragile code: only works correctly  if  no wave with the same trace name  but from a different folder is already contained in the graph.   BUT: the same limitation is true for the simple code using  WhichListItem( sTNm, sTNL ) 
//// Reason: NameOfWave() returns the wave name part of 'sFoWvNm'  e.g. 'xxx',  but when displaying 'sFoWvNm'  the trace name will be  'xxx#1', 'xxx#2'..  if a wave with the same trace name 'xxx' but from a different folder is already contained in the graph
//	string  	sWNm, sFoWvNm
//	string 	sTNL	= TraceNameList( sWNm, ";", 1 )
//	// print	"\t\t\tUFCom_WaveExistsInGraph( ", sWNm, sFoWvNm  , "   )  \t -> trace:", NameOfWave( $sFoWvNm ) , "\texists:", WhichListItem( NameOfWave( $sFoWvNm ) , sTNL ) != UFCom_kNOTFOUND, " \tTNL:", sTNL
//	return	WhichListItem( NameOfWave( $sFoWvNm ) , sTNL ) != UFCom_kNOTFOUND
End

Function		UFCom_TraceExistsInGraph( sWNm, sTNm )
// 2010-08-19 fragile code: only works correctly  if  no wave with the same trace name  but from a different folder is already contained in the graph.   
// Reason:  sTNm  usually is just the wave name part of 'sFoWvNm'  e.g. 'xxx',  but when displaying 'sFoWvNm'  the trace name will be  'xxx#1', 'xxx#2'..  if a wave with the same trace name 'xxx' but from a different folder is already contained in the graph
	string  	sWNm, sTNm
	string 	sTNL	= TraceNameList( sWNm, ";", 1 )
	return	WhichListItem( sTNm, sTNL ) != UFCom_kNOTFOUND
End

Function		UFCom_TraceIsVisible( sWNm, sTNm )
	string  	sWNm, sTNm
	return	! NumberByKey( "hideTrace(x)", TraceInfo( sWNm, sTNm, 0 ), "=", ";" )
End

Function 		UFCom_EraseTracesInGraph( sWNm )
// erases all traces in the given window (no erasing in TWA, see also Erase_Traces() )
// Cave: IGOR renames remaining traces after every 'RemoveFromGraph' when there are 2 traces (e.g. Tr0 and Tr0#1) and Tr0 is removed, then the remaining Tr0#1 is renamed Tr0  
// To circumvent this: Either erase from the back (fast but perhaps not always working) or rebuild TNL after every remove.(see CbButtonDelete for code snippet)..
	string 	sWNm
	string 	sTNL	= TraceNameList( sWNm, ";", 1 )
	variable	t, tcnt
	tCnt =  ItemsInList( sTNL ) 			// erase traces on screen 
	// printf "\tEraseTracesInGraph  wnd:%s TrcNmList:%s \r", sWNm, sTNL[0,160]	
	for ( t = tCnt - 1; t >= 0; t -= 1 )		// erase traces on screen (move backwards through list to circumvent IGORs renaming of traces
		RemoveFromGraph  /W=$sWNm $StringFromList( t, sTNL )
		// printf "\t\tEraseTracesInGraph  wnd:%s  erasing  TrcNm:%s  \tfrom  sTNL:'%s'   \t-> leaving '%s' \r", sWNm, UFCom_pd(StringFromList( t, sTNL ),12), sTNL, TraceNameList( sWNm, ";", 1 )
	endfor
	sTNL	= TraceNameList( sWNm, ";", 1 )	// should by now be empty
	if ( strlen( sTNL ) )
		UFCom_InternalError( "EraseTracesInGraph( " + sWNm + " ) failed leaving traces '" + sTNL )
	endif
End



Function 		UFCom_EraseTracesInGraphExcept( sWNm, lstKeepMatches )
// erases all traces in the given window except those starting as the items in 'lstMatch' 
// Cave: IGOR renames remaining traces after every 'RemoveFromGraph'  when there are 2 traces (e.g. Tr0 and Tr0#1) and Tr0 is removed, then the remaining Tr0#1 is renamed Tr0  
	string 	sWNm, lstKeepMatches
	string 	sTNm, sTNL	= TraceNameList( sWNm, ";", 1 )
	variable	t, tcnt		=  ItemsInList( sTNL ) 		
	
	// printf "\tEraseTracesInGraphExcept( 1 %s,  %s )  traces:%d  TrcNmList:%s \r", sWNm, lstKeepMatches, ItemsInList( sTNL ), sTNL[0,160]	

	// 2005-0729		Does not work smoothly because of an unwanted side effect: x-axis always starts at x=-1	
	// make	/O /n=0 wDummy			// draw an invisible dummy wave which will not be erased as it is not contained in  sTNL..
	// AppendToGraph  /W=$sWNm wDummy	// ..which prevents that the axis are removed after the last trace in sTNL is erased

	variable	bKeep
	variable	k, nKeepMatches = ItemsInList( lstKeepMatches )
	string  	sKeepMatch
	for ( t = tCnt - 1; t >= 0; t -= 1 )										// erase traces on screen (move backwards through list to circumvent IGORs renaming of traces
		sTNm	= StringFromList( t, sTNL )
		bKeep	= UFCom_FALSE
		for ( k = 0; k < nKeepMatches; k += 1 )
			sKeepMatch	=  StringFromList( k, lstKeepMatches )
			if ( cmpstr( sTNm[ 0, strlen( sKeepMatch ) - 1 ], sKeepMatch ) == 0 )	// check each trace on screen if it belongs to those traces  (=lstKeepMatches) which are not to be erased
				bKeep	= UFCom_TRUE
				break
			endif				
		endfor
		if ( bKeep == UFCom_FALSE )
			RemoveFromGraph  /W=$sWNm $sTNm
			// printf "\tEraseTracesInGraphExcept( 2 %s,  %s )\terasing \t%s\tfrom  sTNL[traces:%3d] :'%s...' \t-> leaving\t[traces:%3d]\t'%s' \r", sWNm, lstKeepMatches, UFCom_pd(sTNm,12), tCnt, sTNL[0,100], ItemsInList( TraceNameList( sWNm, ";", 1 ) ), TraceNameList( sWNm, ";", 1 )[0,100]
		endif
	endfor
	// printf "\tEraseTracesInGraphExcept( 3 %s,  %s )\tleaving \t[traces:%3d]\t'%s'  \r", sWNm, lstKeepMatches, ItemsInList( TraceNameList( sWNm, ";", 1 ) ),  TraceNameList( sWNm, ";", 1 )[ 0, 160 ]
End

Function 		UFCom_EraseMatchingTraces( sWNm, sMatch )
// Erases all traces in the given window which start with  'sMatch' . This is useful for removing traces with any BegPt   e.g.  'AdcFM_'   will be remove  'AdcFM_0' ,  'AdcFM_1000' ,  'AdcFM_12345' 
	string 	sWNm, sMatch
	string 	sTNL	= TraceNameList( sWNm, ";", 1 )
	string  	lstMatch	= ListMatch( sTNL, sMatch + "*" )
	variable	t, tcnt	=  ItemsInList( lstMatch ) 			
	// printf "\t\tEraseMatchingTraces  wnd:%s    '%s'  erasing %d : '%s'   TNL[%d]:%s \r", sWNm, sMatch, tcnt, lstMatch[0,80],  ItemsInList( sTNL ) , sTNL[0,80]	

//	for ( t = tCnt - 1; t >= 0; t -= 1 )								// ...may here not be necessary..........erase traces on screen (move backwards through list to circumvent IGORs renaming of traces
	for ( t = 0; t < tcnt; t += 1 )
		RemoveFromGraph  /W=$sWNm $StringFromList( t, lstMatch )	
		 //printf "\t\tEraseMatchingTraces  wnd:%s  erasing  TrcNm:%s  \tfrom  sTNL:'%s'   \t-> leaving '%s' \r", sWNm, UFCom_pd(StringFromList( t, lstMatch ),12), lstMatch, TraceNameList( sWNm, ";", 1 )
	endfor
	// printf "\t\tEraseMatchingTraces  wnd:%s    '%s'  leaving %d : '%s'  \r", sWNm, sMatch, ItemsInList( TraceNameList( sWNm, ";", 1 ) )  , TraceNameList( sWNm, ";", 1 )
End


Function		UFCom_ReorderTraceToTop( sWNm, sTopTrace )
// Put 'sTopTrace' on top of the other traces so that it is always visible. 
	string 	sWNm, sTopTrace
	string 	sTNL	= TraceNameList( sWNm, ";", 1 )
	// 2010-07-02
	if ( WhichListItem( sTopTrace, sTNL ) != UFCOM_kNOTFOUND )				// check that trace 'sTopTrace' which is to be moved to top is actually contained in graph, if not 'ReorderTraces' below will fail
		sTNL	= RemoveFromList( sTopTrace, sTNL )
		variable	nt, nTraces	= ItemsInList( sTNL )
		for ( nt = 0; nt < nTraces; nt += 1 )
			ReorderTraces /W=$sWNm $sTopTrace,  { $StringFromList( nt, sTNL ) }	
		endfor
	endif
End



Function  	UFCom_KillGraphs( sMatch, sWndBaseNm )
// As we compact (=renumber) the acq graphs automatically whenever a window is killed and as Igors WinList() returns an unsorted list (very arbitrary order!) ...
// ...we may get a large number of compacting moves (worst case : (n+1)*n/2  )  if we do not sort the list of the windows to be deleted. 
// For example  WinList() returns unsorted list W2,W0,W3, W1 : If we kill from end  W2,W0,W3  we get compacting moves to be avoided  W3->W2, W2->W1  and so on
// When sorting ascending and killing from the end the number of compacting moves is reduced to 0. 
// The compacting is required whenever the user kills any acq window (except the highest). Here in KillAllGraphs() it is not needed  but  cannot? be avoided ....
// An added advantage of the sorting is that we can use a FOR-NEXT-loop, without sorting we would have to use a DO-WHILE-loop  plus  an  IF... 
// ..and we would have to REBUILD the window list within the loop everytime a window is killed (e.g. without  rebuild W0,W2,W1...
// .. Igor would kill W1, then W2 then W0  but after killing W1  the compact-move change the remaining list from W0,W2  to W0,W1  and  W2 can no longer be killed....
	string 	sMatch, sWndBaseNm
	variable	n, nItems
	string 	lstDeleteWnds
	lstDeleteWnds	= WinList( sMatch,  ";" , "WIN:" + num2str( UFCom_WN_GRAPH ) )						//??? shoud read UFCom_WN_GRAPH
	lstDeleteWnds	= UFCom_SortListExt( lstDeleteWnds, sWndBaseNm, UFCom_kSORTNUMERICAL )
	nItems		= ItemsInList( lstDeleteWnds )
	// print "\tKillGraphs() ", sMatch, "deleting  items:", nItems,  lstDeleteWnds 
	for ( n = nItems - 1; n >= 0;  n -= 1 )
		print "\tKillGraphs() sMatch:", sMatch, "deleting item: ", n, StringFromList( n, lstDeleteWnds ), "old list (invalid after compacting..)  ", lstDeleteWnds 
		DoWindow /K $StringFromList( n, lstDeleteWnds )	
	endfor
End 

Function		UFCom_ClearGroupOf( sMatch, nWinType ) 
// deletes graph windows containing 'sMatch' anywhere in the name
	string  	sMatch
	variable	nWinType
	string  	sMatch1 	= "*" + sMatch + "*" 
	string  	lstWins	= WinList( sMatch1,  ";" , "WIN:" + num2str( nWinType ) )		
	//printf "\t\tClearGroupOf (matching anywhere   \t%d\t'%s'\t'%s'\t%s  \r", nWinType, sMatch, sMatch1, lstGraphs[0,300]
	variable	n, nItems		= ItemsInList( lstWins )
	for ( n = 0; n < nItems;  n += 1 )
		DoWindow /K $StringFromList( n, lstWins )	
	endfor
	return	nItems
End

Function		UFCom_ClearGroupOfGraphs( sMatch ) 
// deletes graph windows containing 'sMatch' anywhere in the name
	string  	sMatch
	return	UFCom_ClearGroupOf( sMatch, UFCom_WN_GRAPH  |  UFCom_WN_GIZMO ) 
End

Function		UFCom_ClearGroupOfTables( sMatch ) 
// deletes table windows containing 'sMatch' anywhere in the name
	string  	sMatch
	return	UFCom_ClearGroupOf( sMatch, UFCom_WN_TABLE ) 
End

Function		UFCom_ClearGroupOfLayouts( sMatch ) 
// deletes layout windows containing 'sMatch' anywhere in the name
	string  	sMatch
	return	UFCom_ClearGroupOf( sMatch, UFCom_WN_LAYOUT ) 
End


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function		UFCom_PossiblyKillPanel( sWndNm )
// Attempts to delete a panel from screen. Does nothing if the panel does not exist.  Does not delete the underlying panel text wave 'tPnxxx"
	string  	sWndNm
	UFCom_PossiblyKillWindow( sWndNm, UFCom_WT_PANEL )
End	


Function		UFCom_PossiblyKillGraph( sWndNm )
// Attempts to delete a Graph from screen. Does nothing if the Graph does not exist. 
	string  	sWndNm
	return	UFCom_PossiblyKillWindow( sWndNm, UFCom_WT_GRAPH )
End	

Function		UFCom_PossiblyKillNotebook( sWndNm )
// Attempts to delete a notebook from screen. Does nothing if the notebook does not exist. 
	string  	sWndNm
	UFCom_PossiblyKillWindow( sWndNm, UFCom_WT_NOTEBOOK )
End	

Function		UFCom_PossiblyKillTable( sWndNm )
// Attempts to delete a table from screen. Does nothing if the table does not exist. 
	string  	sWndNm
	UFCom_PossiblyKillWindow( sWndNm, UFCom_WT_TABLE )
End	


Function		UFCom_PossiblyKillWindow( sWndNm, nWndType )
// Attempts to delete any window from screen. Does nothing if the window does not exist.  
	string  	sWndNm
	variable	nWndType
	if ( WinType( sWndNm ) == nWndType )
		KillWindow	$sWndNm
		return 	1
	endif
	return	0
End	


Function		UFCom_WndHide( sWin )
	string  	sWin
	if ( WinType( sWin ) )										// only if the window exists (the user may have 'forcefully' killed even a window designed to be permanent
// Igor5 
//		MoveWindow /W = $sWin  0, 0, 0, 0 						// minimise the window to an icon
// Igor6
		SetWindow $sWin, hide = 1
	endif
End


Function		UFCom_WndUnhide( sWin )
	string  	sWin
	if ( WinType( sWin ) )										// only if the window exists (the user may have 'forcefully' killed even a window designed to be permanent
		SetWindow $sWin, hide = 0
		DoWindow  /F $sWin
	endif
End


Function		UFCom_GraphExists( sWin )
	string  	sWin
	return	( WinType( sWin ) == UFCom_WT_GRAPH )
End

Function		UFCom_TableExists( sWin )
	string  	sWin
	return	( WinType( sWin ) == UFCom_WT_TABLE )
End


//===============================================================================================================================
//  WINDOW  LOCATIONS

static constant		YFREELO_FOR_SB_AND_CMDWND	= 140	// points
static constant		YNAMELINE						= 20		// points

//	 WORKS ONLY IN Igor6
Function		UFCom_IsMinimized1( sWndName )
// Return if  'sWndName'   is currently minimized.  
	string  	sWndName
	GetWindow $sWndName , hide							
	return  ( V_Value & 2 )		// bit 0 = hidden/shown,   bit 1 = minimised/visible
End
	

// WORKS ONLY IN Igor5
//Function		UFCom_IsMinimized( sWndName, xl, yt, xr, yb  )
//// Return if  'sWndName'   is currently minimized.   Also return as params the current window location which is only useful if the window was not minimized.
//	string  	sWndName
//	variable	&xl, &yt, &xr, &yb									// parameters changed by function
//	GetWindow $sWndName , wSize							// Get the existing windows coordinates...
//	xl = V_left												// ...and return them  (only useful if the window was not minimized)
//	yt = V_top
//	xr = V_right
//	yb = V_bottom											
//	return  ( xl == xr  &&  yt == yb )  
//End
	

//	 WORKS ONLY IN Igor5
//Function		UFCom_IsMinimized1( sWndName )
//// Return if  'sWndName'   is currently minimized.  
//	string  	sWndName
//	GetWindow $sWndName , wSize							// Get the existing windows coordinates...
//	return  ( V_left == V_right  &&  V_top == V_bottom )  
//End
	

// only for Igor5
//Function		UFCom_StoreWndLoc( sFolder, xl, yt, xr, yb )
//// Save the stimulus window coordinates
//	string  	sFolder
//	variable	xl, yt, xr, yb
//	string  	sDFSave	= GetDataFolder( 1 )
//	// printf "\t\t\tStoreWndLoc(0  \t%s ) \tx: %3d ...%3d ,    \ty: %3d  ...  %3d \tGetDataFolder : '%s' \r", sFolder, xl, xr, yt, yb, GetDataFolder(1)
//	nvar	/Z 	gxl	= $"root:uf:" + sFolder + ":gxl"
//	if ( ! nvar_exists( gxl ) )
//		NewDataFolder  /O  /S $"root:uf:" + sFolder 
//		variable 	/G 	$"root:uf:" + sFolder + ":gxl"
//		variable 	/G 	$"root:uf:" + sFolder + ":gyt"
//		variable 	/G 	$"root:uf:" + sFolder + ":gxr"
//		variable 	/G 	$"root:uf:" + sFolder + ":gyb"
//	endif		
//	nvar	 	gxl  	= $"root:uf:" + sFolder + ":gxl"
//	nvar		gyt  	= $"root:uf:" + sFolder + ":gyt"
//	nvar		gxr  	= $"root:uf:" + sFolder + ":gxr"
//	nvar		gyb 	= $"root:uf:" + sFolder + ":gyb"
//	gxl  = xl	;	gyt  = yt	;	gxr  = xr	;	gyb  = yb
//	SetDataFolder $sDFSave
//	// printf "\t\t\tStoreWndLoc(1  \t%s ) \tx: %3d ...%3d ,    \ty: %3d  ...  %3d \tGetDataFolder : '%s'    ?$sDF? %s \r", sFolder, xl, xr, yt, yb, GetDataFolder(1), sDFSave
//End	
//
//Function		UFCom_RetrieveWndLoc( sFolder, xl, yt, xr, yb )
//// Return the window coordinates
//	string  	sFolder
//	variable	&xl, &yt, &xr, &yb
//	nvar	 	gxl  	= $"root:uf:" + sFolder + ":gxl"
//	nvar		gyt  	= $"root:uf:" + sFolder + ":gyt"
//	nvar		gxr  	= $"root:uf:" + sFolder + ":gxr"
//	nvar		gyb 	= $"root:uf:" + sFolder + ":gyb"
//	xl	= gxl	;	yt	= gyt	;	xr	= gxr	;	yb	= gyb
//	// printf "\t\t\tRetrieveWndLoc(\t%s ) \tx: %3d ...%3d ,    \ty: %3d  ...  %3d \r", sFolder, xl, xr, yt, yb
//End

//===============================================================================================================================

Function	/S	UFCom_AllWindowsContainingWave( sWaveNm )
// Returns list of windows containing the wave 'sWaveNm'  e.g. "root:uf:MyWave" .  
// All graphs, tables and  layouts are searched.  Text waves are ignored.
	string  	sWaveNm
	return	UFCom_MatchWinsContainingWave( sWaveNm, "*" , ";" , "WIN:7" )	// 1 (graphs) + 2 (tables) + 4 (layouts)
// 2009-09-29 i   Although XOP/Gizmo windows are recognised by passing 4096 they still can not be cleared this way as 'CheckDisplayed' below fails...
//	return	UFCom_MatchWinsContainingWave( sWaveNm, "*" , ";" , "WIN:4103" )	// 1+2+4+4096
End

Function	/S	UFCom_MatchWinsContainingWave( sWaveNm, matchStr, separatorStr, optionsStr )
// Returns list of windows containing the wave 'sWaveNm'  e.g. "root:uf:MyWave" .  
// Only windows matching the  'WinList()' parameters are searched.   Text waves are ignored.
	string  	sWaveNm
	string  	matchStr, separatorStr, optionsStr 	
	string  	lstWinsContainingWave	= ""
	string  	lstWinsToCheck	= WinList( matchStr, separatorStr, optionsStr )
	variable	w, nWins	= ItemsInList( lstWinsToCheck, separatorStr )
	for ( w = 0; w < nWins; w += 1 )
		string  	sWin	= StringFromList( w, lstWinsToCheck, separatorStr )
		CheckDisplayed	/W=$sWin  $sWaveNm	// Note: XOP/Gizmo windows can unfortunately NOT be cleared this way as 'CheckDisplayed' below fails on them...
		if ( V_flag & 1 )
			lstWinsContainingWave += sWin + separatorStr
		endif
	endfor
	// printf "\t\t\tWave '%s' is contained in %d window(s) : '%s....' \r", sWaveNm, ItemsInList( lstWinsContainingWave, separatorStr ), lstWinsContainingWave[0, 200]
	return	lstWinsContainingWave
End	

Function		UFCom_CountGraphs()
	return	ItemsInList( WinList( "*" , ";" , "WIN:1" ) )		// 1 (graphs) + 2 (tables) + 4 (layouts)
End

Function		UFCom_CountTables()
	return	ItemsInList( WinList( "*" , ";" , "WIN:2" ) )		// 1 (graphs) + 2 (tables) + 4 (layouts)
End

Function		UFCom_CountLayouts()
	return	ItemsInList( WinList( "*" , ";" , "WIN:4" ) )		// 1 (graphs) + 2 (tables) + 4 (layouts)
End

Function		UFCom_CountGizmos()
	return	ItemsInList( WinList( "*" , ";" , "WIN:4096" ) )	// 1 (graphs) + 2 (tables) + 4 (layouts)
End

	

