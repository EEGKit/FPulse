////
//// UF_AcqDispCurves.ipf
//// 
//// Routines for
////	displaying traces during acquisition :  maintaining the display configuration as 'curves'
////
//
//#pragma rtGlobals=1							// Use modern global access method.
//
//
//
//  Function		SaveDispSettings( sFile ) 
//// store all  window / trace arrangement variables (=the display configuration contained in WLoc and WA) in 'sFile' having the extension 'DCF' 
//	string 	sFile
//	string 	bf
//	// First get the current window corners from IGOR ,  then store them in wLoc, finally save wLoc in the settings file 
//	// Cave: wLoc is updated here, not earlier: it may contain obsolete values here when windows have been moved or resized since last save.
//	// wLoc could be updated earlier on 'wnd resize' event but not on 'wnd move' event as IGOR does not supply the latter event....
//	variable	w, wCnt	= WndCnt()
//	// printf "\t\tSaveDispSettings( %s )  saves WA[ w:%d ]  and  WLoc[ w:%d ][ %d ] \r", sFile, wCnt, wCnt, cWNDLASTENTRY  
//	for ( w = 0; w < wCnt; w += 1 )
//		string 	sWnd	= WndNm( w )
//		if ( WinType( sWnd ) == UFCom_WT_GRAPH )							// check if the graph exists
//			GetWindow $sWnd, wSize
//			SetWndCorners( w, V_left, V_top, V_right, V_bottom )
//		endif
//	endfor
//	//  only for debug printing
//	ShowWndCurves( 0 )												
//	save /O /T /P=$UFPE_ksSCRIPTS_SYMPATH root:uf:acq:disp:wWLoc, root:uf:acq:disp:wWA as sFile 		// store all acquisition display variables to disk
//End	
//
//
// Function		LoadDispSettingWaves( sFo, sFile )
////// retrieve all window / trace arrangement variables (=the display configuration contained in WLoc and WA) from 'sFile' having the extension 'DCF' 
//	string 	sFo, sFile
//
//	loadwave /O /T /A  /Q /P=$UFPE_ksSCRIPTS_SYMPATH sFile								// read all acquisition display variables from disk
//	duplicate	/O 	wWLoc	   root:uf:acq:disp:wWLoc
//	killWaves	wWLoc
//	duplicate	/O 	wWA	   root:uf:acq:disp:wWA
//	killWaves	wWA
//End
//
//
//Function 		PossiblyRemoveInvalidCurves( sFo, w, nCurves, lstChans )
//	// Remove invalid curves from the underlying display configuration data structure
//	variable	w, nCurves						// traces in 1 window including orphans before cleaning
//	string  	sFo, lstChans
//	variable	ch, ra, mo
//	string		sChan, sRGB, sMsg, sCurve
//	variable	nCurve
//		
//	for ( nCurve = 0; nCurve < nCurves; nCurve += 1 )
//		sCurve	= CurvesOneCurve( w, nCurve )
//		ExtractChMoRaFromCurve( sCurve,  sChan, ra, mo )			// break Curve to get all traces to be displayed in window 'w'...
//		ch		= WhichListItem( sChan,  lstChans, UFCom_ksSEP_TAB, 0, 0 )	// 2008-05-15 case-insensitive
//		// printf "\t\tLoadDispSettings(b)\tw:%2d\tsChan: '%s' \tra:%2d  mo:%2d\t->ch:%2d\t[sCurve: '%s'] \r", w, sChan, mo, ra, ch, sCurve
//		if ( ch == UFCom_kNOTFOUND  ||   ra == UFCom_kNOTFOUND  ||   mo == UFCom_kNOTFOUND )
//			//  If the display configuration contains orphan traces (=Channels with not found in the script)  or corrupted traces (=mode or range -1) then these will automatically be removed from the display configuration file. 
//			if ( ch == UFCom_kNOTFOUND )
//				sprintf sMsg, "The channel  '%s'  found in the display config file has no correspondence in the script. Cannot display. Will adjust display configuration file...", sChan	// Happens when the user edits channels in the script and then forgets to save the display cfg
//			endif
//			if ( ra == UFCom_kNOTFOUND  ||   mo == UFCom_kNOTFOUND )
//				sprintf sMsg, "The curve  '%s'  found in the display config file is corrupted. Cannot display. Will adjust display configuration file...", sCurve						// Should happen only during development...
//			endif
//			UFCom_FoAlert( sFo, UFCom_kERR_IMPORTANT, sMsg )
//			CurvesDeleteCurve( w, nCurve )	
//			nCurve 	-= 1					
//			nCurves 	-= 1					
//		endif		
//	endfor
//	return	nCurves
//End








//=======================================================================================================================================================================================
//	ACQ  WINDOW CURVE :	Unfortunately   INTERFACE  and  IMPLEMENTATION  are not separated....
//	The DCF display information is coded in a string.  NEVER change the ordering as this would break all existing DCF files. Appending entries is OK, though.  The entries  'Units'  and  'Instance'  are no longer used and must be left empty.

constant			kCV_CHAN  = 0, kCV_MORA  = 1, kCV_ZOOM  = 2, csUNITS = 3, kCV_RGB = 4, kCV_OFS  = 5, cnINSTANCE = 6, kCV_AUTOSCL = 7, kCV_AXIS = 8	
static strconstant	ksCURVSEP			= "|"				

 Function		CurvesCnt( w )
	variable	w
print  "???CurvesCnt( w )  080620 ??? returns : ", ItemsInList( CurvesRetrieve( w ) , ksCURVSEP ) 	
	return	ItemsInList( CurvesRetrieve( w ) , ksCURVSEP ) 	
End

 Function	/S	CurvesOneCurve( w, nCurve )	
	variable	w, nCurve 
	return	StringFromList( nCurve,  CurvesRetrieve( w ) , ksCURVSEP ) 	
End

					
static Function		CurvesDeleteCurve( w, nCurve )
	variable	w, nCurve 
	string  	sCurves
	sCurves	= CurvesRetrieve( w )								
	sCurves	= RemoveListItem( nCurve, sCurves, ksCURVSEP )				// REMOVE the curve to be deleted
	CurvesStore( w, sCurves )
	return	nCurve
End
						
 Function		CurvesRemoveCurve( w, sChan, ra, mo )
	variable	w, ra, mo
	string  	sChan
	string  	sCurves
	variable	nCurve
	sCurves	= CurvesRetrieve( w )								
	nCurve	= WhichCurve( sCurves, ksCURVSEP, sChan, mo, ra )
	sCurves	= RemoveListItem( nCurve, sCurves, ksCURVSEP )				// REMOVE the curve to be deleted
	CurvesStore( w, sCurves )
	return	nCurve
End
						
 Function		CurvesAddCurve( w, sChan, ra, mo, bAutoscl, YOfs, YZoom, nAxis, sRGB )		
// ADD new trace to curves in window 'w' , return the index of the trace/curve which has just been added
	variable	w, ra, mo, bAutoscl, YOfs, YZoom, nAxis
	string  	sChan, sRGB
	string  	sCurves	= CurvesRetrieve( w )

	//string  	sCurve	= BuildCurve( sChan, nRange, nMode, bAutoscl, yOfs, yZoom, nAxis, sRGB )
	//string  	sCurve	= sChan + ";" + BuildMoRaName( ra, mo )  + ";" + num2str( yZoom ) + ";" + "UnitsUnUsed"+ ";" 	+ sRGB 
	string		sCurve 	= sChan + ";" + BuildMoRaName( ra, mo )  + ";" + num2str( yZoom ) + ";;" 					+ sRGB  	// 2006-0613	 ";;"	sUnits is empty
 	sCurve	+= ";" + num2str( yOfs ) + ";;" + num2str( bAutoscl ) 	+ ";" + num2str( nAxis ) 										// 2006-0613  ";;"	nInstance is empty

 	sCurves	= AddListItem( sCurve, sCurves, ksCURVSEP, inf )				// ADD new trace to curves in window 'w'
	CurvesStore( w, sCurves )
	return	ItemsInList( sCurves, ksCURVSEP ) - 1 
End


//static Function	  /S	BuildCurve( sChan, nRange, nMode, bAuto, yOfs, yZoom, nAxis, sRGB )
//	variable	nRange, nMode, bAuto, yOfs, yZoom, nAxis
//	string		sChan, sRGB 



//	//string   	sCurve = sChan + ";" + BuildMoRaName( nRange, nMode )  + ";" + num2str( yZoom ) + ";" + "UnitsUnUsed"+ ";" 	+ sRGB 
//	string		sCurve = sChan + ";" + BuildMoRaName( nRange, nMode )  + ";" + num2str( yZoom ) + ";;" 					+ sRGB  	// 2006-0613	 ";;"	sUnits is empty
// 	sCurve	+= ";" + num2str( yOfs ) + ";;" + num2str( bAuto ) 	+ ";" + num2str( nAxis ) 										// 2006-0613  ";;"	nInstance is empty
// 	// printf "\t\t\t\tBuildCurve() ->  '%s' \r", sCurve
// 	return	sCurve
//End

Function	/S	CurveRetrieveParameter( w, nCurve, nIndex )
	variable	w, nCurve, nIndex
	string 	sVarString
	string		sCurves, sCurve
	sCurves	= CurvesRetrieve( w )
	sCurve	= CurvesOneCurve( w, nCurve )		
	sVarString	= StringFromList( nIndex, sCurve )					//	 Retrieve the single entry... 	
	return	sVarString
End

static Function		ReplaceOneParameter( w, nCurve, nIndex, sVarString )
	variable	w, nCurve, nIndex
	string 	sVarString
	string		sCurves, sCurve
	sCurves	= CurvesRetrieve( w )
	sCurve	= CurvesOneCurve( w, nCurve )		
	sCurve	= RemoveListItem( nIndex, sCurve )					//	 Replace the single entry... 	
	sCurve	= AddListItem( sVarString, sCurve,  ";" , nIndex )			//	...in the list of many entries in 1 curve
	sCurves	= RemoveListItem( nCurve, sCurves, ksCURVSEP )		// Replace the curve with the changed entry... 	
	sCurves	= AddListItem( sCurve, sCurves, ksCURVSEP, nCurve )	//..in the list of many curves
	CurvesStore( w, sCurves )
End

Function		UpdateCurves( w, nIndex, sValue, sCurve, sChan, ra, mo, rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB )	
	variable	w, nIndex
	string  	sValue, sCurve
	string  	&sChan, &rsRGB
	variable	&ra, &mo, &rbAutoscl, &rYOfs, &rYZoom, &rnAxis 
	ExtractChMoRaFromCurve( sCurve, sChan, ra, mo )										// here only 'rsChan, ra, mo'  are extracted from the passed 'sCurve' , the remaining parameters in 'sCurve' contain old invalid values (as 'sCurve' has been set only once when the controlbar was constructed)
	variable	nCurve	= ExtractCurves( w, sChan, ra, mo, rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB)	// Extract fom 'sCurves' the one and only curve 'nCurve' with matching ' sChan, ra, mo' and from this the remaining (now valid) parameters 'rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB' 
	variable	Gain
	string  	sFo	= ksACQ
	
	if ( nCurve == UFCom_kNOTFOUND )
		UFCom_InternalError( "UpdateCurves() : could not find sCurve '" + sCurve + "'  in  sCurves '" + CurvesRetrieve( w )[0,200] + "...' . " )
		ShowWndCurves( -2 )
	else
		switch ( nIndex )
			case	kCV_AUTOSCL:
				rbAutoscl	= str2num( sValue )
				Gain		= GainByNmForDisplay_ns( sFo, sChan )
// 2009-12-12  ???
//				AutoscaleZoomAndOfs( w, sChan, mo, ra, rbAutoscl, rYOfs, rYZoom, Gain )
				AutoscaleZoomAndOfs_6( w, sChan, rbAutoscl, rYOfs, rYZoom, Gain )
				ReplaceOneParameter( w, nCurve, kCV_AUTOSCL, sValue )						// or  'BuildCurve()'  could be used rather than 3 times 'ReplaceOneParameter()'
				ReplaceOneParameter( w, nCurve, kCV_OFS , 	num2str( rYOfs ) )
				ReplaceOneParameter( w, nCurve, kCV_ZOOM,	num2str( rYZoom ) )
				break;
			case	kCV_ZOOM :
				ReplaceOneParameter( w, nCurve, nIndex, sValue )
				rYZoom	= str2num( sValue )
				break;
			case	kCV_OFS :
				ReplaceOneParameter( w, nCurve, nIndex, sValue )
				rYOfs	= str2num( sValue )
				break;
			case	kCV_RGB:
				ReplaceOneParameter( w, nCurve, nIndex, sValue )
				rsRGB	= sValue
				break;
			case	kCV_AXIS:
				ReplaceOneParameter( w, nCurve, nIndex, sValue )
				rnAxis	= str2num( sValue )
				break;
		endswitch
		 printf "\t\tUpdateCurves()  \t\t\t\t\tw:%2d\tcv:%2d\t\tax:%2d\t%s\tAuScl:%2d\tZm:\t%7.2lf\tOs:\t%7.1lf\tGn:\t%7.1lf\t%s\t \r", w, nCurve, rnAxis, UFCom_pd( StringFromList( nCurve,   CurvesRetrieve( w ), ksCURVSEP ),52), rbAutoscl, rYZoom, rYOfs, Gain, rsRGB
	endif	
	return	nCurve
End



static Function		WhichCurve( sCurves, sCurvSep, sChan, mo, ra )
// Returns index  'nCurve'  of the curve defined by  Channel, mode and range
	string		sCurves, sCurvSep, sChan
	variable	mo, ra
	string  	sTNmMoRa	= sChan + ";" + BuildMoRaName( ra, mo ) + ";"						// Assumption naming : Curves
	variable	pos			= strsearch( sCurves, sTNmMoRa, 0 )
	variable	nCurve		= 0
	if ( pos != UFCom_kNOTFOUND ) 
		sCurves	= sCurves[ 0, pos+1 ]				// truncate behind found position...
		nCurve	= ItemsInList( sCurves, sCurvSep ) 	// ..so that counting the list items gives the sought-after index 
	endif
	return	nCurve -1 							// returns index 0,1,2...    or  UFCom_kNOTFOUND (-1)  
End



 Function	  	ExtractChMoRaFromCurve( sCurve, rsChan, rnRange, rnMode )
// Extract  Channel, Range and Mode when  1 curve  'sCurve'  is given . The parameters (except the 1.) are changed
	string		sCurve
	variable	&rnRange, &rnMode
	string		&rsChan
	string		sMoRa
	rsChan	= StringFromList( kCV_CHAN , sCurve ) 
	sMoRa	=  StringFromList( 1, sCurve ) 
	ExtractMoRaName( sMoRa, rnRange, rnMode )					// convert 2-letter string into 2 numbers,  e.g. 'SM'->0,1   'RS' ->3,0
End

 Function	  	Curve2Range( w, nCurve  )		
// Extracts only the  'range'  when  the curve is given
	variable	w, nCurve
	variable	ra, mo
	string		sCurve	= CurvesOneCurve( w, nCurve )				// e.g 'Dac1;SM;........'
	string		sMoRa	=  StringFromList( kCV_MORA, sCurve ) 		// e.g. 'SM'
	ExtractMoRaName( sMoRa, ra, mo )							// convert 2-letter string into 2 numbers,  e.g. 'SM'->0,1   'RS' ->3,0
	return	ra
End

 Function 	  ExtractCurves( w, sChan, nRange, nMode, rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB )			
// Extracts 5 entries (rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB)  when  'sCurves(w)'  (containing all curves of 1 window)  and the trace name, the mode and the range are given. (sChan, range and mode are known already)
// There is only be 1 instance of each channel/mode/range  in 'sCurves' so the found curve is unique.
	string		sChan
	variable	w, nRange, nMode
	variable	&rbAutoscl, &rYOfs, &rYZoom, &rnAxis 
	string		&rsRGB
	string  	sCurves	= CurvesRetrieve( w )
	variable	nCurve	= WhichCurve( sCurves, ksCURVSEP, sChan, nMode, nRange )		// Get from all curves in this window the index of the one and only curve with matching  channel, mode and range
	if ( nCurve == UFCom_kNOTFOUND )
		string  	sMsg; sprintf sMsg, "ExtractCurves() : Could not find  '%s'  / '%s'  in  '%s' . \r", sChan,  BuildMoRaName( nRange, nMode ), sCurves;	UFCom_InternalError( sMsg )
		ShowWndCurves( -3 )
	else
		string  	sCurve	= CurvesOneCurve( w, nCurve )		
		ExtractCurveDispPars( w, nCurve, sCurve, sChan, rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB )	
	endif
	return 	nCurve
End


//// REMAKE STATIC.....
// Function	  	ExtractCurve( w, nCurve, rsChan, rnRange, rnMode, rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB  )	
//// Extracts all 9 entries (rsTNm, rnRange, rnMode, rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB)  including the trace name, the mode and the range when  1 curve  defined by window 'w' and index 'nCurve'  is given
//	variable	w, nCurve
//	variable	&rnRange, &rnMode, &rbAutoscl, &rYOfs, &rYZoom, &rnAxis 
//	string		&rsChan, &rsRGB
//	string  	sCurves	= CurvesRetrieve( w )
//	string		sCurve	= CurvesOneCurve( w, nCurve )		
//	string  	sMoRa	= StringFromList( kCV_MORA, sCurve ) 
//	rnMode	= Mora2Mode( sMoRa )								// convert 2-letter string into 2 numbers,  e.g. 'SM'->0,1   'RS' ->3,0
//	rnRange	= Mora2Range( sMoRa )								// convert 2-letter string into 2 numbers,  e.g. 'SM'->0,1   'RS' ->3,0
//	rsChan	= StringFromList( kCV_CHAN , sCurve ) 
//	ExtractCurveDispPars( w, nCurve, sCurve, rsChan, rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB )	
//End

static Function	  	ExtractCurveDispPars( w, nCurve, sCurve, sChan, rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB )	
	variable	w, nCurve
	string  	sCurve, sChan
	variable	&rbAutoscl, &rYOfs, &rYZoom, &rnAxis 
	string		&rsRGB
	variable	nItemCnt	= ItemsInList( sCurve )

	//rsUnits	= StringFromList( 3, sCurve ) 					// 2004-0123 As Units are fixed they are taken directly from the script / wIO. Only if they could be changed (e.g. like colors) they would have to be stored/extracted  in 'Curves'
	rYZoom	= str2num( StringFromList( kCV_ZOOM , sCurve ) )
	rsRGB	= StringFromList( kCV_RGB, sCurve )
	
	// 	  	The following additional drawing parameters were introduced.
	//	 	As they are NOT script parameters there are no default supplied by 'wIO etc.'  . These parameters are normally stored in the display config (DCF) file.
	//		But DCF files written with older FPulse versions do not yet have these entries, so we must supply defaults here.
	//  todo: set defaults when there is not DCF file at all
	rYOfs	= nItemCnt <= kCV_OFS    	? 	0 :  str2num( StringFromList( kCV_OFS , sCurve ) )	// 2004-0103
	//nInstance= nItemCnt <= cnINSTANCE  ?	0 :  str2num( StringFromList( cnINSTANCE, sCurve ) ) 
	if ( nItemCnt <= kCV_AUTOSCL )												// 'AutoScale' entry in this old DCF is missing..
		if ( IsDacTrace( sChan ) )
			rbAutoscl	= 1														//	...and it is a Dac : Do autoscaling
		else
			rbAutoscl	= 0														//	...and it is an Adc or PoN : use fixed Zoom from script  and Offset = 0
		endif
	else
		rbAutoscl	= str2num( StringFromList( kCV_AUTOSCL, sCurve ) )						// 'AutoScale' entry in DCF exists : use it
	endif

	if ( nItemCnt <= kCV_AXIS )													// 'nAxis' entry in this old DCF is missing..
		rnAxis	= 0															// each new trace is connected to axis 0 which is the 'left' axis	
		//rnAxis	= min( nCurve, YAxisMax() )											// each new trace is connected to a new axis, up to the limit of allowed axes
		ReplaceOneParameter( w, nCurve, kCV_AXIS, num2str( rnAxis ) )						// make the supplied default setting for this parameter permanent
	else
		rnAxis	= str2num( StringFromList( kCV_AXIS, sCurve ) )							// 'nAxis' entry in DCF exists : use it
	endif
	// printf "\t\t\t\tExtractCurveDispPars() ->   \tsChan:\t%s\tR:%d \tM:%d \trYZoom:\t%7.2lf\trsRGB:\t%s\tYOs:\t%7.2lf\tInst: %d\tAS:%d \t  \r", UFCom_pd(sChan,7), rnRange, rnMode, rYZoom, UFCom_pd(rsRGB,12), rYOfs, rbAutoscl
End



// 2005-1219    todo   AVOID  SEARCHING
Function   /S	FindFirstWnd_a( ch )	
// Return the name of the lowest-index acquisition window containing 'sChan' (=ch)  . There may be windows with higher index also containing 'sChan'
	variable	ch
	string	  	sChan	= StringFromList( ch, LstChan_a(), UFCom_ksSEP_TAB )	// e.g.   'Adc1'
	variable	w, wCnt	= AcqWndCnt()
	for ( w = 0; w < wCnt; w += 1 )
		variable	cv, nCurves	= CurvesCnt( w )				// e.g. 2  for separator '|'  :  'Adc1;FM;1;UnitsUnUsed;(0,53248,0);0;0;1|Dac0;FC;1;UnitsUnUsed;(40000,0,40000);0;0;1' 
		for ( cv = 0; cv < nCurves; cv += 1 )
			string  sCurve	= CurvesOneCurve( w, cv )				// e.g. 'Adc1;FM;1;UnitsUnUsed;(0,53248,0);0;0;1'   or  'Dac0;FC;1;UnitsUnUsed;(40000,0,40000);0;0;1' 
			if ( cmpstr( sChan, StringFromList( 0, sCurve ) ) == 0 )		// e.g. 'Adc1'  matches trace 0 
				return	WndNm( w )						// the lowest-index window containing 'sChan' . There may be windows with higher index also containing 'sChan'
			endif
		endfor
	endfor
	return ""
End


//=====================================================================================================================================
//  ACQ  WINDOW  CURVES  :	IMPLEMENTATION   as  a   1dim  text wave WA

static constant		cLFT = 0,    cRIG = 1,cTOP = 2,   cBOT = 3,    cWNDLASTENTRY = 4	// entries in wWLoc

 Function		AcqWndCnt()
	wave   /T	wv = root:uf:acq:disp:wWA
	return	numPnts( wv )
End

static  Function	MakeWA( wCnt )
	variable	wCnt
	make  /T	/O  /N=( 	wCnt )	root:uf:acq:disp:wWA
End

static Function	RedimensionWA( wCnt )
	variable	wCnt
	redimension /N = (	 wCnt )	root:uf:acq:disp:wWA
End

Function		ClearWA( wCnt )
	variable	wCnt
	redimension /N = (	 wCnt )	root:uf:acq:disp:wWA
	wave   /T	wv = root:uf:acq:disp:wWA
	wv = ""
End
	
 Function		CurvesStore( w, sCurves )
// fill WA : each window can have multiple traces which can have multiple curves
	variable	w
	string	 	sCurves

	wave   /Z /T	wv = root:uf:acq:disp:wWA
	if ( waveExists( wv ) )
		wv[ w ] = sCurves
	endif
	// printf "\t\t\t\tCurvesStore( w:%2d/%2d\t'%s' ) \r", w, DimSize( wv, 0 ), wv[ w ]
End

 Function   /S	CurvesRetrieve( w )
	variable	w
	wave   /T	wv = root:uf:acq:disp:wWA
	// printf "\t\t\t\tCurvesRetrieve( w:%d/%d)\t= '%s' \r", w, DimSize( wv, 0 ), wv[ w ]			// e.g. w:1	= 'Adc1;FM;1;UnitsUnUsed;(0,53248,0);0;0;1|Dac0;FC;1;UnitsUnUsed;(40000,0,40000);0;0;1' 
	return	wv[ w ]
End

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// 	ACQ  WINDOW  POSITIONS  : 	INTERFACE  and   TEST  FUNCTIONS

 Function			ShowWndCurves( nIndex )
	variable	nIndex
	variable	w,	 wCnt	= WndCnt()
	for ( w = 0; w < wCnt; w += 1 )						// loop thru windows
		 printf "\t\t\tShowWndCurves(%d)\tw:%2d/%2d\tL:%3d  \tT:%3d  \tR:%3d  \tB:%3d \t%s\r" , nIndex, w,  wCnt ,  WndLoc( w, cLFT ), WndLoc( w, cTOP ), WndLoc( w, cRIG ), WndLoc( w, cBOT ), CurvesRetrieve( w )
	endfor
End

 Function		MakeWnd( wCnt )
	variable	wCnt
	MakeWLoc( wCnt )
	MakeWA( wCnt )
End

 Function		RedimensionWnd( wCnt )
	variable	wCnt
	RedimensionWA( wCnt )
	RedimensionWLoc( wCnt )
End

static Function		SetWndCorners( w, nLeft, nTop, nRight, nBot )
	variable	w, nLeft, nTop, nRight, nBot
	SetWndLoc( w , cLFT,  nLeft )
	SetWndLoc( w , cTOP,  nTop )
	SetWndLoc( w , cRIG,  nRight )
	SetWndLoc( w , cBOT, nBot )
End

 Function		RetrieveWndCorners( w, rnLeft, rnTop, rnRight, rnBot )
	variable	w
	variable	&rnLeft, &rnTop, &rnRight, &rnBot
	rnLeft	= WndLoc( w, cLFT )
	rnTop	= WndLoc( w, cTOP )
	rnRight	= WndLoc( w, cRIG )
	rnBot	= WndLoc( w, cBOT )
	// printf "\t\tRetrieveWndCorners( w:%d  -> rnLeft:%d , rnTop:%d , rnRight:%d , rnBot:%d  ) \r", w, rnLeft, rnTop, rnRight, rnBot
End

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// 	ACQ  WINDOW  POSITIONS  :	IMPLEMENTATION   as  a   2dim  wave  WLoc

static Function		MakeWLoc( wCnt )
	variable	wCnt
	make	/O	/N=( wCnt, cWNDLASTENTRY )	root:uf:acq:disp:wWLoc
End

static Function		RedimensionWLoc( wCnt )
	variable	wCnt
	redimension 	/N = ( wCnt, cWNDLASTENTRY )	root:uf:acq:disp:wWLoc
End

 Function   WndCnt()
	wave   /Z 	wWLoc = root:uf:acq:disp:wWLoc
	return  waveExists( wWLoc )  ? dimSize( wWLoc, 0 ) : 0	// can be called without harm even before the wave has been constructed
End

static Function		SetWndLoc( w, border, value )
	variable	w, border, value
	wave   	wWLoc = root:uf:acq:disp:wWLoc
	wWLoc[ w ][ border ]	= round( value )
End

static  Function	WndLoc( w, border )
	variable	w, border
	wave   	wWLoc = root:uf:acq:disp:wWLoc
	return	wWLoc[ w ][ border ]
End

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//  ACQ  WINDOW  NAMES

Function  /S 	WndNm( w )
	variable	w
	return	DiacWnd( w )
End

  Function 		WndNr( sWndNm )
// return the window number
	string 	sWndNm
	return	str2num( sWndNm[ strlen(UFPE_ksW_WNM), Inf ] )
End



//=====================================================================================================================================
//   MODE  and  RANGE  ( in 2 variables )

  constant		kCURRENT 		= 0,		kMANYSUPIMP = 1
static	  strconstant	lstMODETEXT		= "Current,Many superimposed,"
static  strconstant	lstMODENM		= "C;M"
static  strconstant	lstMODETXT		= "C ,M ,"

  constant			kSWEEP 			= 0,	kFRAME = 1,  kPRIM = 2, 	kRESULT = 3
static	  strconstant	lstRANGETEXT		= "Sweeps,Frames,Primary,Result,"
static  strconstant	lstRANGENM		= "S;F;P;R"


Function		DispRange( ch, mo, ra )
	variable	ch, mo, ra
	nvar   	DispRange		= $"root:uf:acq:pul:cbDispRange" + num2str( ch ) + num2str( 0 ) + num2str( mo ) + num2str( ra ) 
	// printf "\t\t\tDispRange( ch:%2d )   'root:uf:acq:pul:cbDispRangeCh%dRg%dMo%dRa%d returns %.0lf \r", ch, ch, 0, mo, ra, DispRange
	return	DispRange
End

Function		SetDispRange( ch, mo, ra, value )
	variable	ch, mo, ra, value
	nvar   	DispRange		= $"root:uf:acq:pul:cbDispRange" + num2str( ch ) + num2str( 0 ) + num2str( mo ) + num2str( ra ) 
	DispRange	= value
	// printf "\t\t\tSetDispRange( ch:%2d )   'root:uf:acq:pul:cbDispRangeCh%dRg%dMo%dRa%d has been set to  %.0lf \r", ch, ch, 0, mo, ra, DispRange
End


  Function  /S	ModeNm( n )
// returns  an arbitrary  name for the mode, not for the variable  e.g. 'C' , 'M' 
	variable	n
	return	StringFromList( n, lstMODENM )
End

static Function		ModeNr( s )
// returns  index of the mode, given its name
	string  	s
	variable	nMode = 0				// Do not issue a warning when no character is passed.... 
	if ( strlen( s ) )					// This happens when a window contains no traces.
		nMode = WhichListItem( s, lstMODENM )
		if ( nMode == UFCom_kNOTFOUND )
			UFCom_DeveloperError( "[ModeNr] '" + s + "' must be 'C' or 'M' " )
		endif
	endif
	return nMode
End

 Function		ModeCnt()	
	return	ItemsInList( lstMODETEXT, UFCom_ksSEP_STD )
End	

static Function  /S	RangeNm( n )
// returns  an arbitrary  name for the range, not for the variable  e.g.  'S' , 'F',  'R',  'P'
	variable	n
	return	StringFromList( n, lstRANGENM )
End

 Function	/S	RangeNmLong( n )
// returns  an arbitrary  name for the range, not for the variable  e.g.  'Sweeps' , 'Frames',  'Result',  'Primary'
	variable	n
	return	StringFromList( n, lstRANGETEXT, UFCom_ksSEP_STD )
End

Function			RangeNr( s )
// returns  index of the range, given its name			used also in   GetRangeNrFromTrc()  in  FPOnline.ipf
	string 	s
	variable	n = 0				// Do not issue a warning when no character is passed.... 
	if ( strlen( s ) )					// This happens when a window contains no traces.
		n = WhichListItem( s, lstRANGENM )
		if ( n == UFCom_kNOTFOUND )
			UFCom_DeveloperError( "[RangeNr] '" + s + "' must be 'S' (Sweep) or 'F' (Frame) or 'P' (Primary sweep) or 'R' (Result sweep) " )
		endif
	endif
	return n
End

 Function		RangeCnt()
	return	ItemsInList( lstRANGETEXT, UFCom_ksSEP_STD )
End	



//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//  IMPLEMENTATION  for  STORING   MODE  and  RANGE  as  a 2-LETTER-string  (for Curves)

 Function	/S	BuildMoRaName( nRange, nMode )
// converts the Mode / range setting for storage in the  'Curves'  to a 2-letter-string   e.g. 	'SM',   'FC' 
	variable	nRange, nMode
	return	RangeNm( nRange ) + ModeNm( nMode )
End

static Function	/S 	BuildMoRaNameInstance( nRange, nMode, nInstance )		// 2004-0107
// converts the Mode / range setting into a 2-letter-string   containing the instance number  e.g. 	'SM ',   'FC1'       ( obsolete: 'SMa',   'FCb' )  
	variable	nRange, nMode, nInstance 
	string    	sInstance = SelectString( nInstance != 0, " " , num2str( nInstance ) )	// for the 1. instance  do not display the zero but leave blank instead
	return	" " + BuildMoRaName( nRange, nMode ) + " " + sInstance 			// 2004-0107
End

 Function		ExtractMoRaName( sMoRa, rnRange, rnMode )
// retrieves the Mode / range setting  from the  'Curves'  and converts the 2-letter-string   into 2 numbers  e.g. 'SM'->0,1   'RS' ->3,0
	string 	sMoRa
	variable	&rnRange, &rnMode
	rnRange	= RangeNr( sMora[0,0] )
	rnMode	= ModeNr(   sMora[1,1] )
End

static Function		Mora2Mode( sMoRa )
// retrieves the Mode setting  from the  'Curves'  and converts the 2-letter-string   into 2 numbers  e.g. 'SM'->0,1   'RS' ->3,0
	string 	sMoRa
	return	ModeNr(   sMora[1,1] )
End

static Function		Mora2Range( sMoRa )
// retrieves the Range setting  from the  'Curves'  and converts the 2-letter-string   into 2 numbers  e.g. 'SM'->0,1   'RS' ->3,0
	string 	sMoRa
	return	RangeNr( sMora[0,0] )
End






