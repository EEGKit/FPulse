//
// FPAcqDisp.ipf	+     FPDispDlg.ipf
// 
// Routines for
//	displaying traces during acquisition
//	displaying raw result traces after acquisition
//	preparing an acquisition window for hardcopy
//
// How the display during acquisition works...
// BEFORE ACQUISITION
// Before the acquisition starts, the users prefered window settings must be prepared.
// The acquis window panel is read : which Traces(Adc,PoN..) are to be shown in..
// ..which range (Frame, Sweep, Primary,Result) and in which mode (current, many=superimposed).
// These settings are combined in a 2 dimensional structure TWA  (TraceWindowArrangement)
// The TWA contains the complete information how the traces display should look like.
// DURING ACQUISITION
// The display routine receives only  the region on screen where to draw and which data are valid. 
// The latter is encoded in the frame and  the sweep number of the data .
// Positive sweep numbers means the valid display range is one sweep, 
// ..whereas a sweep number -1 means the data range that can be displayed is a frame.
//  From frame and sweep number the display routine itself computes data offset and data points to be drawn. 
//  The  TWA  containing the users prefered display settings is broken and trace, mode and range are extracted.
//  Those settings are compared against the currently valid data range and data are drawn if appropriate.

// History:

#pragma rtGlobals=1							// Use modern global access method.

constant		kDISP_FRAME			= -1
constant		kDISP_PRIM			= -2
constant		kDISP_RESULT			= -3

constant		kWNDDIVIDER_			= 75		// 15..100 : x position of a window separator if graph display area is to be divided in two columns
static constant	cLFT = 0,    cRIG = 1,cTOP = 2,   cBOT = 3,    	cUSERSTRACE	= 4, cWNDLASTENTRY = 5	// entries in wWLoc

static strconstant sDISP_CONFIG_EXT	= "dcf"
static strconstant sMORAPOINTSEP		= "_"		// separates TraceModeRange from starting point in trace names, e.g. Adc0SM_0 (blank is not allowed)
strconstant	ksCURVSEP			= "|"				

Function		CreateGlobalsInFolder_Disp_()
// creates all folder-specific variables. To be used once from CreateGlobals() as the current data folder is changed and not restored
	NewDataFolder  /O  /S root:uf:aco:disp				// analysis : make a new data folder and use as CDF,  clear everything
	variable	/G	gCursX	= 0, gCursY = 0,  gPx = 0, gPy = 0, gR1x = 0, gR1y = 0, gR2x = 0, gR2y = 0	
	variable	/G	gWaveY	= 0, gWaveMin= 0, gWaveMax = 0	
	variable	/G	gPrevBlk			= -1	
	string		/G	gsWndSel			= ""		// the window in which the user stored the last POINT, needed for EraseOneRegion..
	string		/G	gsLbActiveWnd		= ""		// needed to fill the traces listbox in AllowIndiviualColorsAxis with the specific traces contained in the window whose listbox has been selected
	string		/G	gsCopyCurve		= ""
	variable	/G	gbHighResolution	= 1		// keep 1 ! Displaying every point DURING ACQUIS without data decimation can be slow with MB waves 
//	variable	/G	gbDisplayAllPts	= 1		// displaying every point AFTER ACQUIS without data decimation can be slow with MB waves 
	variable	/G	gbDispAllDataLagging= 1
	variable	/G	bAcqControlbar	= 0
	variable	/G	gbAxis			= 1		// in each graph : display axis...
	variable	/G	gbScalebar		= 1		// ...or display scalebar   (or both or none)
	variable	/G	gResultXShift		= 0		// the RESULT traces must be shifted so much to, the left so that they effectively start at 0

	if ( ! kbIS_RELEASE )
		gbHighResolution	= 0				// possibly skip display points to gain display speed
//		gbDisplayAllPts	= 0				// possibly skip display points to gain display speed
		gbDispAllDataLagging= 0				// possibly skip display frames/sweeps to keep the display concurrent with the acquired data
	endif

End

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//    DISPLAY  RESULT  TRACES   ( USED AFTER ACQUISITION )
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function	  	DisplayRawAftAcq_( sFolder, wG, wIO, wFix )
// displays  COMPLETE  traces  AFTER  acquisition is  finished (displays complete waves, all sweeps and frames in one trace) 
// too slow when every point is checked (whether it lies within or outside a SAVE period) and drawn: decimating to 'nDrawPts'
	string  	sFolder
	wave  /T	wIO
	wave	wG, wFix
	nvar		gbDisplayAllPtsAA	= $ksROOTUF_ + sFolder + ":dlg:gbDisplayAllPtsAA"
	variable	nSmpInt			= wG[ kSI ]
	variable	PreNoSaveStart, PreNoSaveStop, PostNoSaveStart, PostNoSaveStop 
	// Get  traces to be displayed after acquisition  (these are the same traces / data as during acquisition)
	variable	f, b, s, rnLeft, rnTop, rnRight, rnBot,  pt, nPts
	variable	n, step, nDrawPts = 1000, pr
	string  	sTNm, sFolderTNm, sRGB
	variable	rnRed, rnGreen, rnBlue 
	variable	nIO, c, cCnt, ioch = 0
	for ( nIO = 0; nIO < kIO_MAX; nIO += 1 )		
		cCnt	= ioUse( wIO, nIO )
		for ( c = 0; c < cCnt; c += 1 )
			sTNm 		= ios( wIO, nIO, c, cIONM ) 		
	 		sFolderTNm 	= FldAcqioio( sFolder, wIO, nIO,c, cIONM ) 		
			nPts		= numPnts( $sFolderTNm )
			step		= gbDisplayAllPtsAA ? 1 :  trunc( max( nPts / nDrawPts, 1 ) )
	 		// printf "\t\tDisplayRawAftAcq() nIO:%d   c:%d   %s     %s  \tnSmpInt:%d    \tnPnts:%5d\t DrawPts%4d \tstep:%3d\r", nIO,c,  sTNm, sFolderTNm, nSmpInt, nPts, nDrawPts, step
	
			GetAutoWindowCorners( ioch, ioCnt( wIO ), 0, 1, rnLeft, rnTop, rnRight, rnBot, 0, 40 )	// references rn.. are changed by function
			ioch += 1
			// Make a second identical wave for the second color to discriminate between  SAVE and NOSAVE periods
			wave 		wData   =	$sFolderTNm		
	
			make  /O  /N=(nPts/step)	$( sFolderTNm + "_1" )
			wave 		wSave 	 = 	$( sFolderTNm + "_1" )
			make  /O  /N=(nPts/step)	$( sFolderTNm + "_2" )
			wave 		wNoSave  = 	$( sFolderTNm + "_2" )
	
	pr	= 0			// NOT  REALLY  PROTOCOL  AWARE
			for ( b  = 0; b < eBlocks( wG ); b += 1 )
				for ( f = 0; f < eFrames( wFix, b ); f += 1 )						
					for ( s = 0; s < eSweeps( wFix, b ); s += 1)						
						// printf "\t\tDisplayRawAftAcq()  (f:%d/%d, s:%d/%d) \tBeg:%5d \t... (Store:%5d \t... %5d)  \t... End:%5d \r", f,  eFrames(), s, eSweeps( wFix, b ),  SwpBegAll( b, f, s ), SwpBegSave( b, f, s ), SwpBegSave( b, f, s )+SwpLenSave( b, f, s ), SwpBegSave( b, f, s )+SwpLenAll( b, f, s )
						PreNoSaveStart		= SweepBegAll( sFolder, pr, b, f, s )						// NOT  REALLY  PROTOCOL  AWARE
						PreNoSaveStop		= SweepBegSave( sFolder, pr, b, f, s ) - 1
	 						PostNoSaveStart	= SweepBegSave( sFolder, pr, b, f, s ) + SweepLenSave( sFolder, pr, b, f, s ) + 1 
	 						PostNoSaveStop	= SweepBegAll( sFolder, pr, b, f, s )	    + SweepLenAll( sFolder, pr, b, f, s )
	 						for ( pt = PreNoSaveStart; pt < PreNoSaveStop; pt += step )	
							wNoSave[ pt / step ]	= wData[ pt ]			// use original data points of this period in the  NOSAVE   wave 
							wSave[ pt / step ]	= Nan				// eliminate display points of this period in the  SAVE   wave 
						endfor
						for ( pt = PreNoSaveStop; pt < PostNoSaveStart; pt += step )	
							wSave[ pt / step ]	= wData[ pt ]			// use original data points of this period in the  SAVE   wave 
							wNoSave[ pt / step ]	= Nan				// eliminate display points of this period in the NOSAVE   wave
						endfor
						for ( pt = PostNoSaveStart; pt < PostNoSaveStop; pt += step )	
							wNoSave[ pt / step ]	= wData[ pt ]			// use original data points of this period in the  NOSAVE   wave 
							wSave[ pt / step ]	= Nan				// eliminate display points of this period in the  SAVE   wave
						endfor
					endfor
				endfor
			endfor
	
			// Draw the data
			DoWindow  /K $( ksAFTERACOldWNM + "_" + sTNm ) 				// kill   window  'AfterAcq_xxx'
			Display /K=1 /W=( rnLeft, rnTop, rnRight, rnBot ) 
			ModifyGraph	margin( left )	= 40								// without this the axes are moved too much to the right by TextBox or SetScale y 
			ModifyGraph	margin( bottom )	= 35								// without this the axes are moved too much up by TextBox or SetScale x 
	
			DoWindow  /C $( "AfterAcq_" + sTNm ) 
			// Draw the Save / NoSave traces each with points blanked out by Nan
	
			sRGB	= ios( wIO, nIO, c, cIORGB )
			ExtractColors( sRGB, rnRed, rnGreen, rnBlue )
			// printf "\tDisplayRawAftAcq  nio:%d c:%d  ->  sRGB:%s  \t%d  %d  %d  \r", nIO, c,  sRGB, rnRed, rnGreen, rnBlue
	
			AppendToGraph /C=( rnRed, rnGreen, rnBlue ) wSave	
			AppendToGraph /C=( kCOLMX - rnRed, kCOLMX - rnGreen, kCOLMX - rnBlue ) wNoSave		// complementary color (does not work well with brown, black...)	
	
			SetScale /P X, 0, nSmpInt / kXSCALE * step, ksXUNIT, wSave 
			SetScale /P X, 0, nSmpInt / kXSCALE * step, ksXUNIT, wNoSave
	
			// Draw  Axis Units   TextBoxUnits 
	// 030610	 old	// Print YUnits as a Textbox (Advantage: can position it anywhere.  Drawback: As the units are not part of the wave they are unknown to 'Scalebar'
	//			TextBox	/E=1  /A=LB /X=2  /Y=0  /F=0   iosOld( ioch, cIOUNIT )		// print YUnits horiz.  /E=1: rel. wnd border as percentage of window size (WiSz+, AxMv-) 
	// 030610	 new	
			SetScale /P y, 0, 0,  ios( wIO, nIO,c, cIOUNIT ),  wSave				// Store the Y units of the wave within the wave to make it accessible for 'Scalebars()'...
			SetScale /P y, 0, 0,  ios( wIO, nIO,c, cIOUNIT ),  wNoSave				// Store the Y units of the wave within the wave to make it accessible for 'Scalebars()'...
			Label left "\\u#2"										//..but prevent  IGOR  from drawing the units automatically (in most cases at ugly positions)
			//..instead draw the Y units manualy as a Textbox : draw them horizontally in the lower left corner, 
			// the textbox has the same name as its corresponding axis: this allows easy deletion together with the axis (from the 'Axes and Scalebars' Panel)
			TextBox /C /N=left  /E=1 /A=LB /X=2  /Y=0  /F=0  ios( wIO, nIO,c, cIOUNIT)	//../E=1 means  rel. wnd border as percentage of window size (WiSz+, AxMv-) 
		endfor
	endfor
End


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//    AFTER  ACQUIS : APPLYING  FINISHING  TOUCHES  TO  'DURING'  ACQUISITION   TRACES   
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function		PreparePrinting( sFolder, wG, wIO ) 
// apply finishing touches to during-acquisition-graphs:
// supply all data points skipped during acquisition for speed reasons, supply file name and date, supply comment1
	// Print Date()					// prints   Di, 3. Sep 2002		depending on regional settings of operating system
	// Print Secs2Date(DateTime,0)	// prints   3/15/93  or 15.3.1993	depending on regional settings of operating system
	// Print Secs2Date(DateTime,1)	// prints   Monday, March 15, 1993
	// Print Secs2Date(DateTime,2)	// prints   Mon, Mar 15, 1993
	string  	sFolder
	wave  	wG
	wave  /T	wIO
	string 	ctrlName

	// Version 1 : use current  comment  without opening Dialog field
	svar		sComment1	= root:uf:aco:cfsw:gsGenComm
	// Version 2 : always open Comment Dialog field
	// string	sComment1  =  GetComment1()

	string		sFileTraceDateTimeComment, sWNm, sTrc1Nm
	svar		gsScriptPath	= root:uf:aco:script:gsScriptPath

	variable	w//,  wCnt	= WndCnt_()
	variable	nWndBeg	= 0
	variable	nWndEnd	= WndCnt_() - 1
	for ( w = nWndBeg; w <= nWndEnd; w += 1 )											// loop thru windows
		sWNm	= WndNm_( w )
		if ( WinType( sWNm ) == kGRAPH )
			// todo: if there are multiple different traces in the window (user has copied) then give each trace its own name tag
			sTrc1Nm	= StringFromList( 0, TraceNameList( sWNm, ";", 1 ) )			// get the first trace in the window e.g. Adc0SM_0
			sTrc1Nm	= sTrc1Nm[ 0, strsearch( sTrc1Nm, sMORAPOINTSEP, 0 ) - 1 ]// truncate the separator and the point e.g. Adc0SM
			// Format all items except comment in one line, comment in a second line below
			sFileTraceDateTimeComment	= GetFileName_() + "    (" + StripPathAndExtension( gsScriptPath ) + ")    " + sTrc1Nm + "    " + Secs2Date(DateTime,0) + "    " + time() + "\r" + sComment1
			TextBox	/W=$sWNm  /C  /N=$stTBNamePP()  /E=1  /A=LT  /F=0  sFileTraceDateTimeComment	// print  text  into the window /E=1: rel. wnd border as percentage of window size 
			// printf "\t\tPreparePrinting()  w:%2d/%2d \t%s \t%s \r", w, wCnt, sWNm, sFileTraceDateTimeComment
		endif
	endfor
	//DoUpdate  // does not work    todo: adjust scale size automatically to make room for the text box

	// Run  OFFLINE  through complete display to improve fidelity. Actually in most cases the early (and later overwritten) traces could be skipped here... 
	//? Flaw: If acquis was not in HiRes and if subsequently HiRes is turned on, then LoRes traces will not be changed to HiRes by PreparePrinting()..... 
	//? todo  what if user STOPed acquisition prematurely (not all traces up to eFrames(), eSweeps()  exist ????
	nvar gbHighResolution = root:uf:aco:disp:gbHighResolution
	if ( ! gbHighResolution )	
		gbHighResolution	= TRUE
		DisplayOffLine( sFolder, wG, wIO, wFix, nWndBeg, nWndEnd )
		gbHighResolution	= FALSE
	endif
	return 0
End

Function	DisplayOffLine( sFolder, wG, wIO, wFix, nWndBeg, nWndEnd )
	string  	sFolder
	wave  /T	wIO
	wave  	wG, wFix
	variable	nWndBeg, nWndEnd
	variable	b,  bCnt	= eBlocks( wG )
	for ( b  = 0; b < eBlocks( wG ); b += 1 )
		// printf "\t\t\tDisplayOffLine( nWndBeg:\t%8d\t  nWndEnd:\t%8d\t )   Block:%2d / %2d  has Frames:%2d  Sweeps:%2d \r",  nWndBeg, nWndEnd, b, eBlocks( wG ), eFrames( wFix, b ), eSweeps( wFix, b )
		variable	f,  fCnt	=  eFrames( wFix, b )
		for ( f = 0; f < fCnt; f += 1 )
			variable	s,  sCnt	=  eSweeps( wFix, b )
			for ( s = 0; s < sCnt; s += 1 )
				stDispDuringAcq( sFolder, wG, wIO, wFix, 0, b, f, s, 0,   kWNDDIVIDER_ - 1, nWndBeg, nWndEnd )		// 031008 p=0 : not really protocol aware
			endfor
			stDispDuringAcq( sFolder, wG, wIO, wFix, 0, b, f, kDISP_FRAME,  0,	kWNDDIVIDER_ - 1, nWndBeg, nWndEnd )	
			stDispDuringAcq( sFolder, wG, wIO, wFix, 0, b, f, kDISP_PRIM,	    0,	kWNDDIVIDER_ - 1, nWndBeg, nWndEnd )		
			stDispDuringAcq( sFolder, wG, wIO, wFix, 0, b, f, kDISP_RESULT, 0, kWNDDIVIDER_ - 1, nWndBeg, nWndEnd )	
		endfor
	endfor
End

static Function  /S	stTBNamePP()
	return	"TbPP"
End

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//    DISPLAY   ACQUISITION   TRACES   ( USED DURING ACQUISITION )
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function  /S 	WndNm_( w )
	variable	w
	return	ksW_WNM + num2str( w )
End

 Function  	WndNr_( sWndNm )
// return the window number
	string 	sWndNm
	return	str2num( sWndNm[ strlen(ksW_WNM), Inf ] )
End

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Implementation   of  the  acquis window location as  a  2dim  wave WLoc

Function		MakeWnd_( wCnt )
	variable	wCnt
	MakeWLoc( wCnt )
	MakeWA( wCnt )
End

static Function	stRedimensionWnd( wCnt )
	variable	wCnt
	RedimensionWA( wCnt )
	RedimensionWLoc( wCnt )
End

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function		MakeWLoc( wCnt )
	variable	wCnt
	make	/O	/N=( wCnt, cWNDLASTENTRY )	root:uf:aco:disp:wWLoc
End

Function		RedimensionWLoc( wCnt )
	variable	wCnt
	redimension /N = ( wCnt, cWNDLASTENTRY )	root:uf:aco:disp:wWLoc
End

Function   		WndCnt_()
	wave   /Z 	wWLoc = root:uf:aco:disp:wWLoc
	return  waveExists( wWLoc )  ? dimSize( wWLoc, 0 ) : 0	// can be called without harm even before the wave has been constructed
End

Function		SetWndLoc( w, border, value )
	variable	w, border, value
	wave   	wWLoc = root:uf:aco:disp:wWLoc
	wWLoc[ w ][ border ]	= round( value )
End

static Function	stWndLoc( w, border )
	variable	w, border
	wave   	wWLoc = root:uf:aco:disp:wWLoc
	return	wWLoc[ w ][ border ]
End

Function		SetWndUsersTrace( w, t )
// we need one global variable for each window in the listbox functions to pass the trace to the color- and YZoom-Procs...
	variable	w, t
	wave   	wWLoc = root:uf:aco:disp:wWLoc
	wWLoc[ w ][ cUSERSTRACE ] = t
	// SetWndLoc( w, cUSERSTRACE, value )		// equivalent expression
End

Function		WndUsersTrace( w )
// we need one global variable for each window  in the listbox functions to pass the trace to the color- and YZoom-Procs...
	variable	w
	wave   	wWLoc = root:uf:aco:disp:wWLoc
	return	wWLoc[ w ][ cUSERSTRACE ]
	// return	WndLoc( w, cUSERSTRACE )		// equivalent expression
End

Function		CopyWndLocAndUsersTrace( wTgt, wSrc )
// copies the complete contents of WLoc including UsersTrace, ......
	variable	wTgt, wSrc
	variable	p
	for ( p = 0; p < cWNDLASTENTRY; p += 1 )
		SetWndLoc( wTgt, p, stWndLoc( wSrc, p ) )
	endfor
End

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Implementation   of  the  Trace/Window  structure as  a  1dim  text wave WA

Function		MakeWA( wCnt )
	variable	wCnt
	make  /T	/O  /N=( 	wCnt )	root:uf:aco:disp:wWA
End

Function		RedimensionWA( wCnt )
	variable	wCnt
	redimension /N = (	 wCnt )	root:uf:aco:disp:wWA
End

Function		StoreCurves( w, sCurves )
// fill WA : each window can have multiple traces which can have multiple curves
	variable	w
	string	 	sCurves
	wave   /T	wv = root:uf:aco:disp:wWA
	wv[ w ] = sCurves
	// printf "\t\t\t\tStoreCurves( w:%d, '%s' ) \r", w, wv[ w ]
End

Function   /S	RetrieveCurves( w )
	variable	w
	wave   /T	wv = root:uf:aco:disp:wWA
	// printf "\t\t\t\tRetrieveCurves( w:%d )\t= '%s' \r", w, wv[ w ]
	return	wv[ w ]
End


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Implementation   of  the  Mode/Range, color, yZoom, Units, RGB...  as  a  string

// NEVER change the ordering as reading DCF files depends on it. Appending entries is OK, though.
constant	cTNM = 0, cMORA = 1, cYZOOM = 2, csUNITS_ = 3, csRGB = 4, cYOFS = 5, cnINSTANCE_ = 6, cbAUTOSCL = 7//, cGAIN = 8	

static Function	 stExtractCurve( sCurve, rsTNm, rnRange, rnMode, rnInstance, rbAutoscl, rYOfs, rYZoom, rsRGB  )		// parameters are changed
	string		sCurve
	variable	&rnRange, &rnMode, &rnInstance, &rbAutoscl, &rYOfs, &rYZoom
	string		&rsTNm, &rsRGB
	string		sMoRa
	variable	nItemCnt	= ItemsInList( sCurve )
	rsTNm	= StringFromList( 0, sCurve ) 
	sMoRa	=  StringFromList( 1, sCurve ) 
	stExtractMoRaName( sMoRa, rnRange, rnMode )		// convert 2-letter string into 2 numbers,  e.g. 'SM'->0,1   'RS' ->3,0
	rYZoom	= str2num( StringFromList( 2, sCurve ) )

// 040123
//	rsUnits	= StringFromList( 3, sCurve ) 			// As Units are fixed they are taken directly from the script / wIO. Only if they could be changed (e.g. like colors) they would have to be stored/extracted  in 'Curves'

	rsRGB	= StringFromList( 4, sCurve )
	// print	str2num( StringFromList( 5, sCurve ) )	, str2num( StringFromList( 6, sCurve ) ),  str2num( StringFromList( 7, sCurve ) )		// 040109
	
	// 0401  	The following additional drawing parameters were introduced.
	//	 	As they are NOT script parameters there are no default supplied by 'wIO etc.'  . These parameters are normally stored in the display config (DCF) file.
	//		But DCF files written with older FPulse versions do not yet have these entries, so we must supply defaults here.
	//  todo: set defaults when there is not DCF file at all
	rYOfs	= nItemCnt <= 5   ? 	0   :	str2num( StringFromList( 5, sCurve ) )		// 040103
	rnInstance	= nItemCnt <= 6   ? 	0   :	str2num( StringFromList( 6, sCurve ) ) 
	if ( nItemCnt <= 7 )												// Entry in DCF is missing..
		if ( stIsDacTrace( rsTNm ) )
			rbAutoscl	= 1											//	...and it is a Dac : Do autoscaling
		else
			rbAutoscl	= 0											//	...and it is an Adc or PoN : use fixed Zoom from script  and Offset = 0
		endif
	else
		rbAutoscl	= str2num( StringFromList( 7, sCurve ) )						// Entry in DCF exists : use it
	endif

	// printf "\t\t\t\tExtractCurve() ->   \trsTNm:\t%s\tR:%d \tM:%d \trYZoom:\t%7.2lf\trsRGB:\t%s\tYOs:\t%7.1lf\tInst: %d\tAS:%d \t  \r", pd(rsTNm,7), rnRange, rnMode, rYZoom, pd(rsRGB,12), rYOfs, rnInstance, rbAutoscl
End


Function	  /S	BuildCurve( sTNm, nRange, nMode, nInstance, bAuto, yOfs, yZoom, sRGB )
	variable	nRange, nMode, nInstance, bAuto, yOfs, yZoom
	string		sTNm, sRGB 
	string		sCurve = sTNm + ";" + stBuildMoRaName( nRange, nMode )  + ";" + num2str( yZoom ) + ";" + "UnitsUnUsed" + ";" + sRGB   	
// 040103..040112
 	sCurve	+= ";" + num2str( yOfs ) + ";" + num2str( nInstance ) 
 	sCurve	+= ";" + num2str( bAuto ) 
 	//sCurve	+= ";" + sNm 
 	// printf "\t\t\t\tBuildCurve() ->  '%s' \r", sCurve
 	return	sCurve
End

Function		ReplaceOneParameter( w, nWUT, nIndex, sVarString )
//constant	cTNM = 0, cMORA = 1, cYZOOM = 2, csUNITS_ = 3, csRGB = 4, cYOFS = 5, cnINSTANCE_ = 6, cbAUTOSCL = 7
	variable	w, nWUT, nIndex
	string 	sVarString
	string		sCurves, sCurve
	sCurves	= RetrieveCurves( w )
	sCurve	= StringFromList( nWUT, sCurves, ksCURVSEP )		
	sCurve	= RemoveListItem( nIndex, sCurve )					//	 Replace the single entry... 	
	sCurve	= AddListItem( sVarString, sCurve,  ";" , nIndex )			//	...in the list of many entries in 1 curve
	sCurves	= RemoveListItem( nWUT, sCurves, ksCURVSEP )		// Replace the curve with the changed entry... 	
	sCurves	= AddListItem( sCurve, sCurves, ksCURVSEP, nWUT )		//..in the list of many curves
	StoreCurves(  w, sCurves )
End

// 040120  no longer used
//Function	/S	RetrieveOneParameter( w, nWUT, nIndex )
////constant	cTNM = 0, cMORA = 1, cYZOOM = 2, csUNITS_ = 3, csRGB = 4, cYOFS = 5, cnINSTANCE_ = 6, cbAUTOSCL = 7
//	variable	w, nWUT, nIndex
//	string 	sVarString
//	string		sCurves, sCurve
//	sCurves	= RetrieveCurves( w )
//	sCurve	= StringFromList( nWUT, sCurves, ksCURVSEP )		
//	sVarString	= StringFromList( nIndex, sCurve )					//	 Retrieve the single entry... 	
//	return	sVarString
//End

Function			PossiblyAdjstSliderInAllWindow_( wIO )
// We change the slider limits in all windows in which a slider is displayed
	wave  /T	wIO
	variable	w
	for ( w = 0; w < WndCnt_(); w += 1 )
		string		sWNm	= WndNm_( w )
		string		sCurves	= RetrieveCurves( w )
		variable	nCurveCnt	= ItemsInList( sCurves, ksCURVSEP )
		variable	nWUT	= WndUsersTrace( w )
		string		sCurve	= StringFromList( nWUT, sCurves, ksCURVSEP )		
		variable	rnRange, rnMode, rnInstance, rbAutoscl, rYOfs, rYZoom 
		string		 rsTNm, rsRGB
		stExtractCurve( sCurve, rsTNm, rnRange, rnMode, rnInstance, rbAutoscl, rYOfs, rYZoom, rsRGB )	// Get all traces from this window...
		nvar		bAcqControlbar	= root:uf:aco:disp:bAcqControlbar
		variable	bDisableCtrlOfs		= DisableCtrlOfs(      rsTNm, bAcqControlbar, nCurveCnt, rbAutoscl )	// Determine whether the control must be enabled or disabled
		variable	Gain				= GainByNmForDisplay_( wIO, rsTNm )
		ShowHideCbSliderYOfs( sWNm,  bDisableCtrlOfs, rYOfs, Gain )								// Enable or disable the control  and possibly adjust its value
	endfor
End

Function		DisplayOffLineAllWindows( sFolder, wG, wIO, wFix )	
	string  	sFolder
	wave  /T	wIO
	wave	wG, wFix
	variable	w, wCnt	= WndCnt_()
	for ( w = 0; w < wCnt; w += 1 )
		nvar		gPrevBlk	= root:uf:aco:disp:gPrevBlk; gPrevBlk  = -1	// this enforces ConstructYAxis()
		DisplayOffLine( sFolder, wG, wIO, wFix, w, w )		 	//....we change the Y Axis range in all windows which contain this AD channel
	endfor
End	

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// 	IMPLEMENTATION  TEST  FUNCTIONS

Function		ShowTrcWndArray()
	//ShowWLocCornersVert()
	ShowWndCorners()
	stShowWndCurves( 0 )
End

Function		ShowWndCorners()
	variable	w
	printf "\t\tShowWndCorners(1) \r"
	for ( w = 0; w < WndCnt_();  w += 1 )
		ShowWndCorner( w )
	endfor
End

Function		ShowWndCorner( w )
	variable	w
	printf "\t\t\tWndCorner( w:%2d ) \tL:%3d  \tT:%3d  \tR:%3d  \tB:%3d   Userstrace:%d \r", w, stWndLoc( w, cLFT ), stWndLoc( w, cTOP ), stWndLoc( w, cRIG ), stWndLoc( w, cBOT ), WndUsersTrace( w )
End

Static Function	stShowWndCurves( nIndex )
	variable	nIndex
	variable	w,	 wCnt	= WndCnt_()
	// printf "\t\tShowWndCurves( %d ) \r", nIndex
	for ( w = 0; w < wCnt; w += 1 )						// loop thru windows
		// printf "\t\t\tW:%2d/%2d\t%s\r" , w,  wCnt , RetrieveCurves( w )
	endfor
End

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  LOADING , SAVING  and  INITIALIZING  THE  DISPLAY  CONFIGURATION

// How to save and restore the users Trace-Window-Configuration 
// Script has keyword DisplayConfig	(can be missing)
//   Program tries to extract DisplayConfig entry:
//....no........	if missing it builds automatic entry: e.g.  ''DISPCFG' + 'Script'  e.g.   'DispCfgIVK'
//	if missing it uses script name: e.g.  'DispCfg: IVK'
//   Program tries to open the one and only (user invisible) PTDispCfg file containing all  display configurations
//	If   PTDisplayCFg file cannot be opened (maybe missing)  or if desired entry is not found
//		then build  the rectangular array containing all possible windows (as before)
//
// User action needed:	Store automatic DispCfg   containing current script name 
// 					Store special     DispCfg   containing user supplied name


//Function		LoadDisplayCfgExt( sFileName, sDisplayCfgWanted )
//// sDisplayCfgWanted is for allowing the user to select one of multiple DCF file for a given script, right now not implemented further than this....
//	string	sFileName, sDisplayCfgWanted
//	string	sDisplayCfg
//	printf "\t\tLoadDisplayCfgExt( '%s' , '%s' ) \r", sFileName, sDisplayCfgWanted
//	sDisplayCfg = sDisplayCfgWanted
//	if ( bFoundDispCfg( sDisplayCfg ) )
//		printf "\t\tLoadDisplayCfgExt( '%s' , '%s' ) \t:  '%s'   found : displaying...\r", sFileName, sDisplayCfgWanted, sDisplayCfg
//	else
//		sDisplayCfg	= sFileName + sDISP_CONFIG_EXT 	// no dot
//		if ( bFoundDispCfg( sDisplayCfg ) )
//			printf "\t\tLoadDisplayCfgExt( '%s' , '%s' ) \t:  '%s'  not found but user display config  '%s'  found : displaying it...\r", sFileName, sDisplayCfgWanted, sDisplayCfgWanted, sDisplayCfg
//			LoadDispSettings( sDisplayCfg )
//		else
//			printf "\t\tLoadDisplayCfgExt( '%s' , '%s' ) \t:  neither  '%s'  nor user display config  '%s'  found : displaying all windows....\r", sFileName, sDisplayCfgWanted, sDisplayCfgWanted, sDisplayCfg
//			InitializeAutoWndArray()			
//		endif	
//	endif	
//
//	// Step 4: Retrieve the Mode/Range-Color string entries  and  build the (still empty) windows
//	BuildWindows( kFRONT ) // kBACK)					// display windows, kBACK: behind stimulus and stimulus text notebook
//	EnableButton( "PnPuls", "buPreparePrint", kENABLE )	// Now that the acquisition windows (and TWA) are constructed we can allow drawing in them (even if they are still empty)
//End

Function		LoadDisplayCfg_( sFolder,  sFileName ) 
	string		sFolder, sFileName
	wave  	wG	= $ksROOTUF_ + sFolder + ":keep:wG"	// This  'wG'	is valid in FPulse ( Acquisition )
	wave  /T	wIO	= $ksROOTUF_ + sFolder + ":ar:wIO"  			// This  'wIO'	is valid in FPulse ( Acquisition )
	wave  	wFix	= $ksROOTUF_ + sFolder + ":ar:wFix" 			// This  'wFix'	is valid in FPulse ( Acquisition )

	// printf "\t\tLoadDisplayCfg( '%s' ) \r", sFileName

	string		sDisplayCfg	= ksSCRIPTS_DRIVE + ksSCRIPTS_DIR + ksTMP_DIR + ksDIRSEP + StripPathAndExtension( sFileName ) + "." + sDISP_CONFIG_EXT		// C:UserIgor:Scripts:Tmp:XYZ.dcf
		if ( bFoundDispCfg( sDisplayCfg ) )
			// printf "\t\tLoadDisplayCfg( '%s' ) \t: user display config  '%s'  found : displaying it...\r", sFileName, sDisplayCfg
			LoadDispSettings( wIO, sDisplayCfg )
		else
			// printf "\t\tLoadDisplayCfg( '%s' ) \t: user display config  '%s'  NOT found : displaying all windows....\r", sFileName, sDisplayCfg
			InitializeAutoWndArray( wIO )			
		endif	

	// Step 4: Retrieve the Mode/Range-Color  string entries  and  build the (still empty) windows

	BuildWindows( sFolder, wG, wIO, wFix, kFRONT ) // kBACK)				// display windows, kBACK: behind stimulus and stimulus text notebook

//	EnableButton( "PnPuls", "buPreparePrint", kENABLE )	// Now that the acquisition windows (and TWA) are constructed we can allow drawing in them (even if they are still empty)
	EnableButton( "PnAcqWin", "buPreparePrint", kENABLE )	// Now that the acquisition windows (and TWA) are constructed we can allow drawing in them (even if they are still empty)
End


Function		bFoundDispCfg( sDisplayCfg )
	string 	sDisplayCfg
	return	FileExists( sDisplayCfg )					// already contains symbpath 
End

Function		SaveDispCfg()
// store current disp settings in specific file whose file name is derived from the script file name (other extension  and  other directory=subdirectory 'Tmp' ).
	svar		gsScriptPath	= root:uf:aco:script:gsScriptPath
	string		sFile
	sFile		= ksSCRIPTS_DRIVE + ksSCRIPTS_DIR + ksTMP_DIR + ksDIRSEP + StripPathAndExtension( gsScriptPath ) + "." + sDISP_CONFIG_EXT		// C:UserIgor:Scripts:Tmp:XYZ.dcf
	stSaveDispSettings( sFile )
End

static Function	stSaveDispSettings( sFile ) 
// store all window / trace arrangement variables (=the display configuration contained in WLoc and WA) in 'sFile' having the extension 'DCF' 
	string 	sFile
	string 	bf
	// First get the current window corners from IGOR ,  then store them in wLoc, finally save wLoc in the settings file 
	// Cave: wLoc is updated here, not earlier: it may contain obsolete values here when windows have been moved or resized since last save.
	// wLoc could be updated earlier on 'wnd resize' event but not on 'wnd move' event as IGOR does not supply the latter event....
	variable	w, wCnt	= WndCnt_()
	// printf "\t\tSaveDispSettings( %s )  saves WA[ w:%d ]  and  WLoc[ w:%d ][ %d ] \r", sFile, wCnt, wCnt, cWNDLASTENTRY  
	for ( w = 0; w < wCnt; w += 1 )
		string 	sWnd	= WndNm_( w )
		GetWindow $sWnd, wSize
		SetWndCorners( w, V_left, V_top, V_right, V_bottom )
	endfor
	save /O /T /P=symbPath root:uf:aco:disp:wWLoc, root:uf:aco:disp:wWA as sFile 	// store all acquisition display variables to disk
End	

Function		LoadDispSettings( wIO, sFile )
// retrieve all window / trace arrangement variables (=the display configuration contained in WLoc and WA) from 'sFile' having the extension 'DCF' 
	wave  /T	wIO
	string 	sFile
	string	 	bf
	variable	nRefNum
	variable	oldwCnt	= WndCnt_()

	loadwave /O /T /A  /Q /P=symbPath sFile			// read all acquisition display variables from disk
	duplicate	/O 	wWLoc		root:uf:aco:disp:wWLoc
	killWaves	wWLoc
	duplicate	/O 	wWA		root:uf:aco:disp:wWA
	killWaves	wWA

	variable	wCnt	= WndCnt_()
	// printf "\t\tLoadDispSettings( %s ) oldwCnt:%d ,  loading WA,WLoc(wCnt:%d) , script chs:'%s'   nWUT( w=0 ): %d  \r", sFile, oldwCnt, wCnt, ioChanList( wIO ), WndUsersTrace( 0 )

	// the user may have deleted IO channels in the script which are still contained in the display configuration WA: they must also be removed there...
	RemoveFromWATracesNotFoundInIO( ioChanList( wIO ) )

	// The event  'kill'  in hook in  'DeleteWindowsNoLongerUsed' decrements TWA size with every closed window. 
	// We give it before a bigger size size so that afterwards it is OK
	if ( oldwCnt > wCnt )
		stRedimensionWnd(  oldwCnt  )
	endif
	//ShowWndCurves( 1 )		// temporarily extended to bigger size than needed 

	//ShowTrcWndArray()
	// printf "\t\tLoadDispSettings()  oldwCnt:%d  wCnt:%d  \r", oldwCnt, wCnt
	DeleteWindowsNoLongerUsed( wCnt )
	//ShowWndCurves( 2 )
End


Function		RemoveFromWATracesNotFoundInIO( sAllowedTracesList )
	string		sAllowedTracesList 
	variable	nCurve, w, wCnt	= WndCnt_()
	// printf "\t\tRemoveFromWATracesNotFoundInIO( 1 allowed traces from IO : '%s' )  \r", sAllowedTracesList
	stShowWndCurves( 3 )												// show traces (=curves) in WA  BEFORE removing illegal curves
	for ( w = 0; w < wCnt; w += 1 )						
		// printf "\t\tRemoveFromWATracesNotFoundInIO( 2 )  w:%d  nWUT:%d \r", w, WndUsersTrace( w )
		string  	sCurves	= RetrieveCurves( w )
		for ( nCurve = 0; nCurve < ItemsInList( sCurves, ksCURVSEP ); nCurve += 1 )
			string  	sCurve	= StringFromList( nCurve, sCurves, ksCURVSEP )		
			variable	rnRange, rnMode, rnInstance, rAuto, rYOfs, rYZoom 
			string		rsTName, rsRGB
			stExtractCurve( sCurve, rsTName, rnRange, rnMode, rnInstance, rAuto, rYOfs, rYZoom, rsRGB )	// get all traces from this window...
			if ( WhichListItem( rsTName, sAllowedTracesList ) == kNOTFOUND )
				// printf "\t\tRemoveFromWATracesNotFoundInIO( 3 allowed traces from IO : '%s' )   removes curve %d '%s'  from WA:  \r", sAllowedTracesList, nCurve, rsTName
				sCurves	= RemoveListItem( nCurve, sCurves, ksCURVSEP )			// ...remove the trace permanently from TWA 	
				StoreCurves(  w, sCurves )										// restore the rest of the traces in TWA
			endif
		endfor
	endfor
	stShowWndCurves( 4 )												// show traces (=curves) in WA   AFTER  removing illegal curves
End

Function		DeleteWindowsNoLongerUsed( w )
// kill all windows which have a number higher than ' w ' 
// This is necessary during script rereading when building rectangular autowindows after having deleted an IO line in the script .
	variable	w
	variable	ww = w -1
	string 	sWNm	= WndNm_( ww )
	// Having determined the highest existing window we kill them successively by going down. Going down is much faster because it minimizes the..
	// ..number of 'window compacting' cycles in 'fAcqWndHook_' which is called on every window killing. 
	// printf "\tDeleteWindowsNoLongerUsed(3) \twill delete %d  windows (going down from WndCnt_()-1:W%d  to  W%d)  \r", max(0,  WndCnt_() - w),  WndCnt_()-1, w
	for ( ww =  WndCnt_() - 1; ww >= w; ww -= 1 )	// loop only thru those acquisition windows which are no longer needed
		sWNm	= WndNm_( ww )
		DoWindow	/K  	$sWNm							// kill the window: jump into the hook function and process TWA and WLoc
		// printf "\tDeleteWindowsNoLongerUsed(3) \tdeleting %d   '%s'  \r", ww, sWNm
	endfor		
End



Function		InitializeAutoWndArray( wIO )
// converts user settings from AcqWnd-Panel into an 2dim trace/window string array 
// the strings contain the Mode/Range, the color and the display gain of each curve in one window (multiple curves are allowed)
	wave  /T	wIO

	// Step 2: determine how many windows are needed altogether taking into account the  mode  and  range  settings which can be different for each source channel
	variable	wCnt	  = stAcqWndCnt( wIO )	

	nvar		PnDebgWndArrange  = root:uf:dlg:Debg:WndArrange
	if ( PnDebgWndArrange )
		printf "\tInitializeAutoWndArray()\tTraces ?  -> windows:%d   \r",  wCnt 
	endif
	// printf "\tInitializeAutoWndArray()\tTraces ? ->  windows:%d   \r",  wCnt 

	// Step 3: delete only those acquisition windows which are no longer needed, keep the rest to minimize flickering
	DeleteWindowsNoLongerUsed( wCnt )
	MakeWnd_( wCnt )

	// Step 4:  WA  construct the  Mode/Range-Color  string entries  and  store them
	stStoreBuildCurvesAuto( wIO )

	// Step 5: Compute the automatic window sizes and positions and store them in WLoc
	StoreAutoWindowLocations( wIO )							

End

static Function	stAcqWndCnt( wIO )	
	wave  /T	wIO
	variable	wCnt	= 0
	variable	nIO,c, cCnt
	for ( nIO = 0; nIO < kIO_MAX; nIO += 1 )
		cCnt	= ioUse( wIO, nIO )
		for ( c = 0; c < cCnt; c += 1 )
			wCnt	  +=  ItemsInList( UsedRanges( wIO, nIO, c ) ) *  ItemsInList( UsedModes( wIO, nIO, c ) )
		endfor
	endfor
	return	wCnt
End	


static Function	stStoreBuildCurvesAuto( wIO )
//  fill TWA with automatically constructed string to show all Mode/Range combinations on all traces
	wave  /T	wIO
	variable	RangeMax = stRangeCnt()
	variable	ModeMax	 = stModeCnt()

	variable	r, m, w = 0, RangeCnt, ModeCnt, mode, range
	variable	nInstance	= 0
	variable	bAuto	= 1			// should be 1 only for Dacs and else 0 
	variable	YZoom	= 1
	variable	YOfs		= 0
	string		sCurves, sRangeIndices, sModeIndices

	variable	nIO,c, cCnt
	for ( nIO = 0; nIO < kIO_MAX; nIO += 1 )
		cCnt	= ioUse( wIO, nIO )
		for ( c = 0; c < cCnt; c += 1 )
			sRangeIndices	= UsedRanges( wIO, nIO, c ) 
			sModeIndices	= UsedModes( wIO, nIO, c ) 
			RangeCnt	= ItemsInList( sRangeIndices )
			ModeCnt	= ItemsInList( sModeIndices )
			for ( r = 0; r < RangeCnt; r += 1)
				for ( m = 0; m < ModeCnt; m += 1)
					//ioch		= str2num( StringFromList( t, sSrcIndices ) )			// dereference trace......
					range	= str2num( StringFromList( r, sRangeIndices ) )			// dereference range......
					mode	= str2num( StringFromList( m, sModeIndices ) )			// dereference mode......
					sCurves	= BuildCurve( ios( wIO, nIO, c, cIONM ), range, mode, nInstance, bAuto, YOfs, YZoom, ios( wIO, nIO, c, cIORGB ) )
					StoreCurves( w, sCurves )
					// printf "\tStoreBuildCurvesAuto()\t nIO:%d c:%d   range:%d/%d    mode:%d/%d  ->w:%d \t'%s'  \r", nIO, c, range, RangeCnt, mode, ModeCnt, w, sCurves
					w += 1
				endfor
			endfor
		endfor
	endfor
End

Function		StoreAutoWindowLocations( wIO )
// Compute the automatic window sizes and positions and store them in WLoc
	wave  /T	wIO
	variable	rnLeft, rnTop, rnRight, rnBot
	variable	col		= -1 ,	nCols	= 0
	variable	row, nRows = 0												// the modes and ranges: SM, FC, PC...
	variable	w = 0
	variable	nIO,c, cCnt
	// Step 1 : count how many columns are needed (some sources may be completely off)
	for ( nIO = 0; nIO < kIO_MAX; nIO += 1 )
		cCnt	= ioUse( wIO, nIO )
		for ( c = 0; c < cCnt; c += 1 )
			nRows	=  ItemsInList( UsedRanges( wIO, nIO, c ) ) *  ItemsInList( UsedModes( wIO, nIO, c ) )
			nCols	+= ( nRows > 0 )
		endfor
	endfor
	// Step 2 : adjust the remaining columns so all screen space is used (make columns wider than normal if some sources are completely off)
	for ( nIO = 0; nIO < kIO_MAX; nIO += 1 )
		cCnt	= ioUse( wIO, nIO )
		for ( c = 0; c < cCnt; c += 1 )
			nRows	=  ItemsInList( UsedRanges( wIO, nIO, c ) ) *  ItemsInList( UsedModes( wIO, nIO, c ) )
			col		+= ( nRows > 0 )										// the sources  Adc, Dac, PoN  which have at least 1 window to be displayed...
			for ( row = 0; row < nRows; row += 1 )
				// printf "\t\tStoreAutoWindowLocations()   t:%2d \tw:%2d \tnRows:%2d \r", t, w, nRows
				GetAutoWindowCorners( row, nRows, col, nCols, rnLeft, rnTop, rnRight, rnBot, 0, kWNDDIVIDER_ )
				SetWndCorners( w, rnLeft, rnTop, rnRight, rnBot )
				w	+= 1
			endfor
		endfor
	endfor
End

Function		SetWndCorners( w, nLeft, nTop, nRight, nBot )
	variable	w, nLeft, nTop, nRight, nBot
	SetWndLoc( w , cLFT,  nLeft )
	SetWndLoc( w , cTOP,  nTop )
	SetWndLoc( w , cRIG,  nRight )
	SetWndLoc( w , cBOT, nBot )
End

static Function	stRetrieveWndCorners( w, rnLeft, rnTop, rnRight, rnBot )
	variable	w
	variable	&rnLeft, &rnTop, &rnRight, &rnBot
	rnLeft	= stWndLoc( w, cLFT )
	rnTop	= stWndLoc( w, cTOP )
	rnRight	= stWndLoc( w, cRIG )
	rnBot	= stWndLoc( w, cBOT )
	// printf "\t\tRetrieveWndCorners( w:%d  -> rnLeft:%d , rnTop:%d , rnRight:%d , rnBot:%d  ) \r", w, rnLeft, rnTop, rnRight, rnBot
End

Function		BuildWindows( sFolder, wG, wIO, wFix, nLayer )
// Retrieve the Mode/Range-Color  string entries  and  build the (still empty) windows
	string  	sFolder
	wave  /T	wIO
	wave  	wG, wFix
	variable	nLayer
	variable	w,  wCnt	= WndCnt_()
	variable	rnLeft, rnTop, rnRight, rnBot
	string 	sWNm, sActWnd		
	// printf "\t\tBuildWindows:  new wCnt:%d     \r",  wCnt
	//for ( w = 0; w < wCnt; w += 1 )						// loop   upwards   thru windows			 ( below: w -= 1 )
	for ( w = wCnt-1; w >= 0; w -= 1 )						// looping  downwards thru windows  flickers less ( below: w += 1 )
		stRetrieveWndCorners( w, rnLeft, rnTop, rnRight, rnBot )
		sWNm	= WndNm_( w )
		// to avoid flickering, as many windows as possible are not killed and rebuilt  but rather only erased inside, resized and brought to the front 
		if ( WinType( sWNm ) == kGRAPH )				// the window exists already
			 // printf "\t\t\tBuildWindows: existing   \t\twindow '%s'   \tis moved/resized...\r", sWNm
			RemoveTextBoxUnits( sWNm )				// 040122 must remove TexboxUnits before the traces are removed
			RemoveAcqTraces( sWNm )
			RemoveTextBoxPP( sWNm )
			MoveWindow	 /W=$sWNm  rnLeft, rnTop, rnRight, rnBot 
			if ( nLayer == kFRONT )
				DoWindow 	/F 	$sWNm				// kFRONT : display on top = completely visible
			else
				DoWindow 	/B  	$sWNm				// kBACK :	  display behind all other windows
			endif	
		else
			// printf "\t\t\tBuildWindows: non-existent \twindow '%s'   \tis constructed...\r", sWNm
			Display  /K=1/W=( rnLeft, rnTop, rnRight, rnBot )	/N=$sWNm // name the window right here
			if ( nLayer == kFRONT )
				DoWindow   /F 	$sWNm						  // kFRONT : display on top = completely visible
			else
				DoWindow   /B 	$sWNm						  // kBACK :    display behind all other windows
			endif	


			SetWindow		$sWNm		hook = fAcqWndHook_, hookEvents = 3		// 1:MouseClicks, 2:MouseMoves
			// add some additional pixels (4..20) to make room for IGORs window size dependent font size (effective only in AddaStart, not when user changes window size)
			variable	nAdditionalMargin = (rnRight-rnLeft+rnBot-rnTop) / 50
			ModifyGraph /W=$sWNm margin( left )	= 35 + nAdditionalMargin	// without this the axes are moved too much to the right by TextBox or SetScale y 
			ModifyGraph /W=$sWNm margin( bottom )	= 35					// without this the axes are moved too much up by TextBox or SetScale x 
		endif
		CreateControlBarInAcqWnd( wIO, sWNm ) 								// construct it  new  or  (in an existing graph) update it so that the traces-listbox will show the correct traces
	endfor			// w

	// 040122  A new script may have different gains or a different channel order : we adjust everything that the user sees to reflect the changes
	BuildGainInfo( wG, wIO, cGAININFO )										// 040118 the user may have changed the Adc gain or the order of Adc lines in script : reflect this in the status bar gain info 
	PossiblyAdjstSliderInAllWindow_( wIO )									// 040119 Change the slider limits in all windows which contain this AD channel   ( this is optional and could be commented out )

// 040204  TODO : THIS IS AWFULLY SLOW  if  high resolution during Acquis is  ON.............
	DisplayOffLineAllWindows( sFolder, wG, wIO, wFix )											// 040119 This is to display a changed Y axis in all windows which contain this AD channel   ( could probably be done simpler and more directly.....)

// 040224
//	ConstructAnRegions()

End


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  DISPLAY  DURING  ACQUISITION

constant	 cLAG = 5		// typical values  3..10  seconds    or    1..10 % 

Function		DispDuringAcqCheckLag_( sFolder, wG, wIO, wFix, pr, bl, fr, sw )		// partially  PROTOCOL  AWARE
	string  	sFolder
	wave  /T	wIO
	wave  	wG, wFix
	variable	pr, bl, fr, sw
	nvar		gbDispAllDataLagging	= root:uf:aco:disp:gbDispAllDataLagging
	variable	nLag		= LaggingTime()
	variable	nWndBeg	= 0
	variable	nWndEnd	= WndCnt_() - 1
	if ( gbDispAllDataLagging  ||  nLag < cLAG  ||  fr + sw == 0 )
		stDispDuringAcq( sFolder, wG, wIO, wFix, pr, bl, fr, sw, 0,   kWNDDIVIDER_ - 1, nWndBeg, nWndEnd )
		// printf "DispDuringAcqCheckLag LaggingTime():%.1lf \tdisplaying \r", nLag
	//else
		// printf "DispDuringAcqCheckLag LaggingTime():%.1lf \t\t\t\tskipping\r", nLag
	endif
End

// 2013-01-15  static
static Function	stDispDuringAcq( sFolder, wG, wIO, wFix, pr, bl, fr, sw, BorderLeft, BorderRight, nWndBeg, nWndEnd )			// partially  PROTOCOL  AWARE
//  Display superimposed and current sweeps and frames
	string  	sFolder
	wave  /T	wIO
	wave  	wG, wFix
	variable	pr, bl, fr, sw, BorderLeft, BorderRight, nWndBeg, nWndEnd
	nvar		PnDebgDispDurAcq	= root:uf:dlg:Debg:DispDurAcq
	variable	nSmpInt			= wG[ kSI ]
	nvar		gPrevBlk			= root:uf:aco:disp:gPrevBlk
	nvar		gResultXShift		= root:uf:aco:disp:gResultXShift
	string 	sWNm, rsTNm="", rsUnits="", rsNm="", rsRGB="", sCurves
	variable	nRangeData, BegPt, EndPt, Pts, bIsFirst//, xScl
	variable	rnLeft, rnTop, rnRight, rnBot
	variable	ut, nCurve, CurveCnt  
	variable	AdcRange		= 10					//  + - Volt
	// display  sweeps  or  frames ?
	if ( sw == kDISP_FRAME )						// sw = -1 : one frame is the unit to display
		nRangeData	= cFRAME
		BegPt		= FrameBegSave( sFolder, pr, bl, fr )	
		EndPt		= FrameEndSave( sFolder, wFix, pr, bl, fr )	// display the whole frame
		Pts			= EndPt - BegPt 
		bIsFirst		=  !( fr )
		// printf "\t\t\tDispDurAcq  trying to draw FRAME %d....bIs1: %d  \r", fr, bIsFirst
	elseif ( sw == kDISP_PRIM )					// sw = -2 : the first sweep in each frame is the unit to display
		nRangeData	= cPRIM
		BegPt		= FrameBegSave( sFolder, pr, bl, fr )	
		EndPt		= SweepEndSave( sFolder, pr, bl, fr, 0 )	// display only the first sweep of the frame (useful for skipping the PoN correction pulses)
		Pts			= EndPt - BegPt 
		bIsFirst		=  !( fr )
		// printf "\t\t\tDispDurAcq  trying to draw PRIMARY.... \r"
	elseif ( sw == kDISP_RESULT )				// sw = -3 : the last sweep in each frame is the unit to display
		nRangeData	= cRESULT
		BegPt		= SweepBegSave( sFolder, pr, bl, fr, eSweeps( wFix, bl ) -1 )	
		EndPt		= FrameEndSave( sFolder, wFix, pr, bl, fr )	// display only the last = result sweep of the frame (useful for skipping the PoN correction pulses)
		Pts			= EndPt - BegPt 
		bIsFirst		=  !( fr )
		// printf "\t\t\tDispDurAcq  trying to drawRESULT... \r"
	else										// sw >= 0 : one sweep is the unit to display
		nRangeData	= cSWEEP
		BegPt		= SweepBegSave( sFolder, pr, bl, fr, sw )	
		EndPt		= SweepEndSave( sFolder, pr, bl, fr, sw )
		Pts			= EndPt - BegPt 
		bIsFirst		=  !( fr + sw )
		 // printf "\t\t\tDispDurAcq  trying to draw SWEEP.... \r"
	endif

	variable	w
	variable	rnRange, rnMode, rnInstance, rAuto, rYOfs, rYZoom, yAxis
	string		sCurve


	// Called  only  once  for one initialization before the first block
	if ( gPrevBlk == -1 )							
		// ConstructYAxis()					// will NOT work here ?????????
		 //ComputeAndUseDacMinMax()		// Autoscale the Dacs : only for the Dac we know the exact signal range in advance . Do it only once even for multiple different blocks( the Dac min/max value is computed over all catenated blocks). 
		for ( w = nWndBeg; w <= nWndEnd; w += 1 )		
			sWNm	= WndNm_( w )							
			RemoveTextBoxPP( sWNm )		// remove any old PreparePrinting textbox. 
		endfor							// Alternate approach: keep the textbox but then update its contents (=time, file name) permanently
	endif
	// Called for initialization possibly multiple times always when encountering a new block
	if ( bl != gPrevBlk )
		gPrevBlk  = bl
		 ConstructYAxis()					//
		for ( w = nWndBeg; w <= nWndEnd; w += 1 )		
			sWNm	= WndNm_( w )							
			RemoveTextBoxUnits( sWNm )	// 040109  possibly so often not necessary, only nec. at 1. block ..? ( also removes PreparePrinting Textbox, should not..)
			RemoveAcqTraces( sWNm )		// and bring windows to front
			CountUsedYAxis( w )
		endfor
	endif

	// printf "\t\t\tDispDurAcq     prot:%d  block:%2d  frm:%2d  swp:%2d\t [points %6d..\t%6d \t=%6d\t pts]   ( igLastBlk:%d , bIsFirst:%d ) \r", pr, bl, fr, sw,  BegPt, EndPt, Pts, gPrevBlk, bIsFirst

	if ( PnDebgDispDurAcq )
		printf "\t\t\tDispDurAcq    prot:%d  block:%2d  frm:%2d  swp:%2d\t [points %6d..\t%6d \t=%6d pts]   ( igLastBlk:%d , bIsFirst:%d ) \r", pr, bl, fr, sw,  BegPt, EndPt, Pts, gPrevBlk, bIsFirst
	endif	

	wave	wYAxisNegLim	= root:uf:aco:disp:wYAxisNegLim
	wave	wYAxisPosLim	= root:uf:aco:disp:wYAxisPosLim

	for ( w = nWndBeg; w <= nWndEnd; w += 1 )							// loop thru windows : loop thru rectangular array defined by Acquis wnd options...
		ut		= 0
		sWNm	= WndNm_( w )							

		sCurves	= RetrieveCurves( w )
		CurveCnt	= ItemsInList( sCurves, ksCURVSEP )
		for ( nCurve = 0; nCurve < CurveCnt; nCurve += 1 )			
			ut += 1
			sCurve = StringFromList( nCurve, sCurves, ksCURVSEP )
			stExtractCurve( sCurve, rsTNm, rnRange, rnMode, rnInstance, rAuto, rYOfs, rYZoom, rsRGB )	// parameters are changed
			yAxis 	=  AdcRange * 1000  / rYZoom						
	
			variable	Gain	= GainByNmForDisplay_( wIO, rsTNm )		// 040204

			wYAxisNegLim[ w ][ ut ]	= - yAxis / Gain + rYOfs		// 040203
			wYAxisPosLim[ w ][ ut ]	=   yAxis / Gain + rYOfs
	
			// printf "\t\t\tDispDuringAcq(0) w:%2d\tnCurve:%2d/%2d\t%s\tpts:\t%7d\trd %d\t %s\t%d r\tut:%2d\trg:%2d  md:%2d\tZm:\t%7.2lf\tOs:\t%9.2lf   \tAx:\t%8.2lf   \tGn:\t%7.1lf\t Rgb:%s  \r", w, nCurve, CurveCnt, pd(rsTNm,10), pts, nRangeData , SelectString( nRangeData == rnRange, "!=", "=="), rnRange, ut,rnRange, rnMode, ryZoom, rYOfs, yAxis, Gain, rsRGB

			string  	sFolderTNm	= ksROOTUF_ + sFolder + ":" + ksF_IO + ":" + rsTNm
			if (  Pts > 0   &&   waveExists( $sFolderTNm )   &&    nRangeData == rnRange )
			//if (  Pts > 0   &&   waveExists( $rsTNm )   &&    nRangeData == rnRange )
	 			 // printf "\t\t\tDurAcq is1:%d  w:%2d/%2d\t/%2d/%d \tc:%d/%d  R:%d  M:%d  W:%s  \tO:%s \t'%s'\t'%s..' \r", bIsFirst, w, nwndbeg, nwndend, t,  nCurve, CurveCnt, rnRange, rnMode, sWNm, rsTNm, rsRGB, sCurve[0,80]

	gResultXShift = 0	// 040724
	if ( rnRange ==  cRESULT )
		gResultXShift	=  ( SweepBegSave( sFolder, pr, bl, fr, eSweeps( wFix, bl ) -1 ) - FrameBegSave( sFolder, pr, bl, fr )	) * nSmpInt / 1e6 
	endif

				DurAcqDrawTrace( sFolder, wIO, w, ut, sWNm, rsTNm, BegPt, Pts, bIsFirst, rnMode, rnRange, nSmpInt, rsRGB, Gain ) 
 				// printf "\t\t\tDurAcq  nRange:%d  pts: %d  smpint: %d xscl: %g '  gResultXShift:%7.2lf \r", rnRange, Pts, nSmpInt, xScl, gResultXShift
				if ( bIsFirst )
					 DurAcqDrawBottomPositionYAxis( wIO, w, ut, sWNm, rsTNm, pts, nSmpInt, rsRGB )
				endif
				DurAcqDrawYAxis( w, ut, sWNm, rsTNm )

				// removed 030319 reactivated 040220  removed 040223 as it gives error at program start (wave not yet defined)
				 DurAcqDrawRegion( sWNm, rsTNm, rnRange ) 

				//  DisplayAllRegionsX( sWNm, cINTER, cFINAL )		// only  intermediary and final regions change with each trace, USER is fixed and never changes
				//  DisplayAllRegions( sWNm )	// 260602

			endif
		endfor			// nCurve

	endfor			// window
End


Function		DurAcqDrawTrace( sFolder, wIO, w, ut, sWNm, sTNm, BegPt, Pts, bIsFirst, nMode, nRange, nSmpInt, sRGB, Gain ) 
// MANY Mode 2 : all appended traces have same name,  with /Q Flag,     fixed scales after first sweep.... but display is volatile
// Append: same non-unique wave name for every sweep,   /Q  flag  is used to avoid confusion among the appended waves... 
// Different  data are displayed under the same name, but any operation (e.g. resize window) destroys the data leaving only the last...
	wave  /T	wIO
	string		sFolder, sWNm, sTNm, sRGB
	variable	w, ut, BegPt, Pts, bIsFirst, nMode, nRange, nSmpInt, Gain
	nvar		PnDebgDispDurAcq = root:uf:dlg:Debg:DispDurAcq
	variable	rnRed, rnGreen, rnBlue//, xScl 

	ExtractColors( sRGB, rnRed , rnGreen, rnBlue )

	string		sTNmUsedNF	= BuildTraceNmForAcqDispNoFolder( sTNm, nMode, nRange, BegPt )			
	string		sTNmUsed 	= BuildTraceNmForAcqDisp( sFolder, sTNm, nMode, nRange, BegPt )	// the wave 'sTNmUsed' contains the data segment from 'sTNm' which is currently to be displayed		
	// printf "\t\t\t\tDurAcqDrawTrace 1)  \t  \t  \t  \t \tmode: %d\tbIs1:%d\tWNm: '%s' \tsTNm:%s ->\t%s  \tUsedTrc[ w:%2d ] = %d \t\t\t\t\t\t\t\t[cnt:%3d]\tTNL1: '%s'  \r", nMode, bIsFirst, sWNm, sTNm, pd(sTNmUsed,22),  w, ut, ItemsInList( TraceNameList( sWNm, ";", 1 )  ),  TraceNameList( sWNm, ";", 1 )  

	
	CopyExtractedSweep( sFolder, wIO, sTNm, sTNmUsed, BegPt, Pts, nSmpInt, Gain )		// We compute the new trace i.e. we update the data in 'sTNmUsed'  no matter whether we actually do 'AppendToGraph' below...
	wave	wYAxisExists	= root:uf:aco:disp:wYAxisExists								// ..during acquis the traces are regularly erased, so 'AppendToGraph' either actually draws the first trace in a blank window...
	wave  /T	wYAxisNm		= root:uf:aco:disp:wYAxisNm									// ..or (if it not the 1. trace) the existing (not erased) trace is given new data....

// 040206	Avoids drawing the same trace multiple times one over the other which impairs performance. This would occur e.g. when moving the YOfs slider. Within seconds hundreds of traces could accumulate... 
	if ( WhichListItem( sTNmUsedNF, TraceNameList( sWNm, ";", 1 ) ) == kNOTFOUND )		// For Redrawing outside acquis ( e.g. changed zoom,ofs ) the traces are not erased, they exist : here  we avoid drawing them over and over #1, #2, #3... when the YOfs slider is moved 
//...	
		if ( nMode == cMANYSUPIMP   ||   ( nMode == cCURRENT && bIsFirst ) )			// in CURRENT mode the trace is appended only once : IGOR updates automatically
			wYAxisExists[ w ][ ut ] = TRUE										// 141102 mark this Y axis as 'displayed'  as  we can later act only on  'displayed'  Y axis
	
			if ( ut == 1 ) 													// append the first trace with its Y Axis to the left....
				 AppendToGraph /Q /L 					/W=$sWNm  /C=( rnRed, rnGreen, rnBlue )	 $sTNmUsed
			else															// ..append all other traces with their Y Axis to the right
				// Here the connection is made between a certain trace and its accompanying axis name !  AxisInfo  will return  the name of the controlling wave 
				 AppendToGraph /Q /R=$wYAxisNm[ ut - 1 ]	/W=$sWNm  /C=( rnRed, rnGreen, rnBlue )	 $sTNmUsed 
			endif
			// printf "\t\t\t\tDurAcqDrawTrace 2) after appending \tmode: %d\tbIs1:%d\tWNm: '%s' \tsTNm:%s ->\t%s  \tUsedTrc[ w:%2d ] = %d \tvalid for ut != 1: AxNm: '%s'\t[cnt:%3d]\tTNL1: '%s'  \r", nMode, bIsFirst, sWNm, sTNm, pd(sTNmUsed,22),  w, ut, wYAxisNm[ ut - 1 ], ItemsInList( TraceNameList( sWNm, ";", 1 )  ),  TraceNameList( sWNm, ";", 1 )  
		endif

// 040206	Avoids drawing the same trace multiple times one over the other which impairs performance. This would occur e.g. when moving the YOfs slider. Within seconds hundreds of traces could accumulate... 
	endif
//...

	if ( PnDebgDispDurAcq )
		printf "\t\t\tDispDurAcq %s\t\t%s\tWnd:'%-16s' \tOrg:'%-10s'  \tOne:'%-18s'  \tbIsFirst:%d   BegPt:%d  PTS:%d ->pts:%d \r", "A?U", stModeNm( nMode ), sWNm, sTNm, sTNmUsed, bIsFirst, BegPt, Pts, numPnts($ sTNmUsed)
	endif		
	//return	xScl
End

// 040206
//Function	/S	BuildTraceNmForAcqDisp( sTNm, nMode, nRange, BegPt )
// 	string		sTNm
// 	variable	nMode, nRange, BegPt
// 	string		sBegPt
//	sprintf	sBegPt, "%d",  BegPt		// formats correctly  e.g. 160000 (wrong:num2str( BegPt ) formats 1.6e+05 which contains dot which is not allowed in wave name..) 
//	sTNm	= ksFOLDER_ACQTMP + ":" + sTNm + BuildMoRaName( nRange, nMode ) + sMORAPOINTSEP		// e.g. root:uf:acqtmp: + Adc0 + SM + _
//	
//	//  PERSISTENT DISPLAY  requires keeping a list of unique partial waves ( volatile display was much simpler but vanishes when resizing or drawing a region...)
//	// another approach: use block/frame/sweep composed number to uniquely identify the trace
//	if (  nMode == cMANYSUPIMP )		// append each trace while not clearing previous ones and  display in a persistent manner: needs a unique name
//		// Adding any unique number (e.g. the starting point or the frame/sweep) to the trace name makes the trace name also unique  leading to consequences: 
//		// 	1. memory is occupied for each wave, not only for one 	2. the display is no longer  volatile, when window is resized or when anything is drawn
//		return	sTNm + sBegPt		// e.g.   Adc0SM_160000 
//	else
//		return	sTNm				// in CURRENT mode it must be always the same (non-unique) name
//	endif
//End

// 040206
Function	/S	BuildTraceNmForAcqDisp( sFolder, sTNm, nMode, nRange, BegPt )
 	string		sFolder, sTNm
 	variable	nMode, nRange, BegPt
	return	ksROOTUF_ + ksfACO + ":dispFS:" + BuildTraceNmForAcqDispNoFolder( sTNm, nMode, nRange, BegPt )
End

Function	/S	BuildTraceNmForAcqDispNoFolder( sTNm, nMode, nRange, BegPt )
 	string		sTNm
 	variable	nMode, nRange, BegPt
 	string		sBegPt
	sprintf	sBegPt, "%d",  BegPt		// formats correctly  e.g. 160000 (wrong:num2str( BegPt ) formats 1.6e+05 which contains dot which is not allowed in wave name..) 
	sTNm	= sTNm + stBuildMoRaName( nRange, nMode ) + sMORAPOINTSEP		// e.g.Adc0 + SM + _
	
	//  PERSISTENT DISPLAY  requires keeping a list of unique partial waves ( volatile display was much simpler but vanishes when resizing or drawing a region...)
	// another approach: use block/frame/sweep composed number to uniquely identify the trace
	if (  nMode == cMANYSUPIMP )		// append each trace while not clearing previous ones and  display in a persistent manner: needs a unique name
		// Adding any unique number (e.g. the starting point or the frame/sweep) to the trace name makes the trace name also unique  leading to consequences: 
		// 	1. memory is occupied for each wave, not only for one 	2. the display is no longer  volatile, when window is resized or when anything is drawn
		return	sTNm + sBegPt		// e.g.   Adc0SM_160000 
	else
		return	sTNm				// in CURRENT mode it must be always the same (non-unique) name
	endif
End


static constant	cAXISMARGIN			= .15		// space at the right plot area border for second, third...  Adc axis all of which can have different scales

Function		 DurAcqDrawBottomPositionYAxis( wIO, w, ut, sWNm, sTNm, pts, nSmpInt, sRGB )
// 141102 Drawing multiple Y axis is a bit complicated for a variety of reasons:
// - depending on the number of traces / curves in a window, we want to position the axes neatly: the first to the left, all others to the right of the plot area
// - the drawing routine is called in an order determined by the frames and sweeps whenever they are ready to be drawn
// - the window / trace / usedTrace  is independent of the frames / sweeps order  and can (and will most probably) be COMPLETELY mixed up
// This leads to the complex code requiring  much bookkeeping with the help of  wYAxUsedMax,   wYABotAxEndMax, wYAxisExists
// - drawing the axis should be done as seldom as possible: only when really needed that is right in the very first display update
	wave  /T	wIO
	variable	w, ut, pts, nSmpInt//, xScl 
	string		sWNm, sTNm, sRGB
	string		rsNm, rsUnits
	NameUnitsByNm( wIO, sTNm, rsNm, rsUnits )							// 040123
	wave	wYAxUsedMax		= root:uf:aco:disp:wYAxUsedMax
	wave	wYAxisExists		= root:uf:aco:disp:wYAxisExists
	wave	wYABotAxEndMax	= root:uf:aco:disp:wYABotAxEndMax
	wave  /T	wYAxisNm			= root:uf:aco:disp:wYAxisNm
	variable	rnRed, rnGreen, rnBlue
	ExtractColors( sRGB, rnRed , rnGreen, rnBlue )
	variable	v_Min	= 0
	variable	v_Max	= pts * nSmpInt / kXSCALE

	variable	nRightAxisCnt	= wYAxUsedMax[ w ] - 1
	variable	LastDataPos	= v_Max     -   v_Min								// Igors original bottom axis end value (v_Min is 0) . Any offset here shifts axis to the right so that Y axis label of right axis is not within plot area
	variable	BotAxisEnd	= v_Max   + LastDataPos * nRightAxisCnt * cAXISMARGIN	// we make the original bottom axis longer to get space for additional Y axis so as if we had more data points

	string		sAxisNm	= wYAxisNm[ uT -1 ] 									// 030610
	// printf "\t\tDurAcqDrawBottomPositionYAxis()  w:%d  ut:%d   pts:%d  SI:%g  xScl:%g  v_min:%g   v_max:%g   nRightAxisCnt:%d   BotAxisEnd:%g  sAxisNm:'%s' \r", w, ut,  pts, nSmpInt, xScl, v_min, v_max, nRightAxisCnt,  BotAxisEnd, sAxisNm
	Label  	/W=$sWNm 	$sAxisNm  "\\u#2"								// Prevent  IGOR  from drawing the units (set in 'CopyExtractedSweep()'  automatically..
	//..instead draw the Y units manualy as a Textbox  just above the corresponding Y Axis  in the same color as the corresponding trace  
	// -54, 50, 20 are magic numbers which  are adjusted  so that the text is at the same  X as the axis. They SHOULD be   #defined......................
	// As it seems impossible to place the textbox automatically at the PERFECT position: not overlapping anything else, not blowing up the graph too much...
	// (position depends on units length, graph size, font size)  the user must possibly move it a bit (which is very fast and very easy)...
	variable	TbXPos	= ut == 1 ? -54 : 50 - 20 * ( wYAxUsedMax[ w ] - ut )			// left, left right,  left mid right...
	
	// The textbox has the same name as its corresponding axis: this allows easy deletion together with the axis (from the 'Axes and Scalebars' Panel)

	// 040120  draw the  TextBoxUnits
	//TextBox	/W=$sWNm /C /N=$sAxisNm  /E=0 /A=MC /X=(TbXPos)  /Y=52  /F=0  /G=(rnRed, rnGreen, rnBlue)   rsUnits	// print YUnits horiz.  /E=0: rel. position as percentage of plot area size 
	// 040122
	ModifyGraph	/W=$sWNm axisEnab( $sAxisNm ) = { 0, .96 }					//  supplies a small margin at the top of each Y axis  for the Channel name and the axis units
	TextBox 	/W=$sWNm /C /N=$sAxisNm  /E=0 /A=MC /X=(TbXPos)  /Y=52  /F=0  /G=(rnRed, rnGreen, rnBlue)   rsNm + "/ " + rsUnits	// print YUnits horiz.  /E=0: rel. position as percentage of plot area size 

	
	// printf "\t\tDurAcqDrawYAxis()  w:%2d\tut:%2d/%2d \tTbXPos:%d \t'%s'  \tAxNm:%s \t\r", w, ut, wYAxUsedMax[ w ], TbXPos, rsUnits, pd( sAxisNm,10)

	variable	ThisAxisPos	= wYAxUsedMax[ w ] == 2 ? LastDataPos : LastDataPos + ( ut - 2) / ( wYAxUsedMax[ w ]-2) * (BotAxisEnd - LastDataPos)	// here goes the new Y axis (value is referred to bottom axis data values)
	ModifyGraph	/W=$sWNm axisEnab( bottom ) = { 0, 1- (wYAxUsedMax[ w ]>1 )* .1 }	//  supplies a small margin to the right of the rightmost axis if there is at least  1 right Y axis for the rightmost Y axis numbers    

	// Demo/Sample code to prevent Igor form switching  the axis ticks  8000, 9000, 9999, 10, 11  (this would be fine if we had not hidden Igors Axis units as they were not located neatly..)
	// Different approach (not taken) : switch  mV -> V , pA -> nA etc. whenever Igor crosses his  'highTrip' value  (default seems to be 10000)
	 ModifyGraph  /W=$sWNm  highTrip( $wYAxisNm[ ut - 1 ] ) =100000			// 031103

	// printf "\t\tDurAcqDrawYAxis(2)  '%s'  \tut:%d/%d\tRiAxCnt:%d \tbottom axis   v_min:%g, v_Max:%g -> LastDataPos:%g  \tThisAxPos(%s):%4d\tBotAxEnd:%g / %g\r", sWNm, ut,  wYAxUsedMax[ w ], nRightAxisCnt, v_Min,  v_Max,  LastDataPos, pad(wYAxisNm[ ut - 1 ],5),ThisAxisPos, BotAxisEnd, wYABotAxEndMax[ w ]
	ModifyGraph /W=$sWNm  freePos( $wYAxisNm[ ut - 1 ] ) = { ThisAxisPos, bottom }	// draw the current Y axis at this position (value is referred to bottom axis data values)
	if ( BotAxisEnd > wYABotAxEndMax[ w ] )									// the current data to be displayed are longer than previous data: we must move and redraw all previously drawn Y axis
		wYABotAxEndMax[ w ] = max( BotAxisEnd, wYABotAxEndMax[ w ] )			// store the longest needed bottom axis 
		SetAxis	/W=$sWNm 	bottom, v_Min, BotAxisEnd						// make bottom axis longer if there are Y axis on the right (=multiple traces) to be drawn
		variable	utx
		for ( utx =1; utx <= wYAxUsedMax[ w ]; utx += 1 )							// we attempt to move all axis (=all traces) of this window, but...
			if ( wYAxisExists[ w ][ utx ]  &&   ( utx != ut ) )							// ..we can actually only move an existing axis (= trace must already have been appended), and we need not draw the current axis twice 
				ThisAxisPos	= wYAxUsedMax[ w ] == 2 ? LastDataPos : LastDataPos + ( utx - 2) / ( wYAxUsedMax[ w ]-2) * (BotAxisEnd - LastDataPos)	// here goes the new Y axis
				// printf "\t\tDurAcqDrawYAxis(2a)   '%s'  \tut:%d/%d/%d\tRiAxCnt:%d \tbottom axis   v_min:%g, v_Max:%g -> LastDataPos:%g  \tThisAxPos(%s):%4d\tBotAxEnd:%g / %g\r", sWNm, utx, ut , wYAxUsedMax[ w ], nRightAxisCnt, v_Min,  v_Max,  LastDataPos, pad(wYAxisNm[ ut - 1 ],5), ThisAxisPos, BotAxisEnd, wYABotAxEndMax[ w ]
				ModifyGraph /W=$sWNm  freePos( $wYAxisNm[ utx -1 ] ) = { ThisAxisPos, bottom }// draw the  Y axis at this position (value is referred to bottom axis data values)
				//gn printf "\t\tDurAcqDrawYAxis(2b)   '%s'  \t'%s' \r", sWNm, StringByKey( "RECREATION",  AxisInfo( sWNm, "bottom" ) )	
			endif
		endfor
	endif
	// print  "\r", AxisInfo( sWNm, "bottom" )
	// print  "\r", AxisInfo( sWNm, "left" )
	// print  "\r", AxisInfo( sWNm, "right0" )
End

Function		DurAcqDrawYAxis( w, ut, sWNm, sTNm )
	variable	w,  ut
	string		sWNm, sTNm
	wave	wYAxisNegLim		= root:uf:aco:disp:wYAxisNegLim
	wave	wYAxisPosLim		= root:uf:aco:disp:wYAxisPosLim
	wave	wYAxisLastNegLim	= root:uf:aco:disp:wYAxisLastNegLim
	wave	wYAxisLastPosLim	= root:uf:aco:disp:wYAxisLastPosLim
	if ( wYAxisLastNegLim[ w ][ ut ] != wYAxisNegLim[ w ][ ut ]  ||  wYAxisLastPosLim[ w ][ ut ] != wYAxisPosLim[ w ][ ut ] ) 
		// printf "\t\t\t\tDurAcqDrawYAxis() \tw:%2d \tut:%d\tWNm:%s \tODat:%s \twLast:%g..\t%g\t-> \twLim:%10.2lf...\t%10.2lf\t  \r", w, ut, sWNm, sTNm, wYAxisLastNegLim[ w ][ ut ],wYAxisLastPosLim[ w ][ ut ], wYAxisNegLim[ w ][ ut ],wYAxisPosLim[ w ][ ut ]
		wYAxisLastNegLim[ w ][ ut ]	= wYAxisNegLim[ w ][ ut ]
		wYAxisLastPosLim[ w ][ ut ]		= wYAxisPosLim[ w ][ ut ] 
		SetMultipleYAxisRange( ut, sWNm, wYAxisNegLim[ w ][ ut ], wYAxisPosLim[ w ][ ut ] )
	endif
End

Function		SetMultipleYAxisRange( ut, sWNm, NegLimit, PosLimit )
	variable	ut, PosLimit, NegLimit
	string		sWNm
	wave  /Z /T	wYAxisNm	= root:uf:aco:disp:wYAxisNm
	if ( waveExists( wYAxisNm ) ) 		
		// printf "\t\t\t\tSetMultipleYAxisRange()\tut:%d \tsWNm:%s \tNegLim:\t%10.2lf \tPosLim:\t%10.2lf \tAxisNm[ ut-1:%d ]='%s' \r",  ut, sWNm, NegLimit, PosLimit, ut,  wYAxisNm[ ut-1 ]

		if ( cmpstr( wYAxisNm[ 0 ], "left" ) )
			Alert( kERR_IMPORTANT,  "Axis name error with  ut = 1 . Should be 'left'  but is  '" + wYAxisNm[ ut - 1 ] + "' . " )  
		endif
		SetAxis /Z /W=$sWNm $wYAxisNm[ ut - 1 ],	NegLimit, PosLimit 	

//		if ( ut == 1 ) 
//			SetAxis /Z /W=$sWNm	left, 				NegLimit, PosLimit
//			
//			if ( cmpstr( wYAxisNm[ ut - 1 ], "left" ) )
//				Alert( kERR_IMPORTANT,  "Axis name error with  ut = 1 . Should be 'left'  but is  '" + wYAxisNm[ ut - 1 ] + "' . " )  
//			endif
//
//		else
//			SetAxis /Z /W=$sWNm $wYAxisNm[ ut - 1 ],	NegLimit, PosLimit 	
//		endif

	endif
End

//Function		SetMultipleYAxisLabelColorize( ut, sWNm, sRGB )
//	variable	ut
//	string		sWNm, sRGB
//	variable	rnRed, rnGreen, rnBlue
//	ExtractColors( sRGB,  rnRed, rnGreen, rnBlue )
//	wave  /Z /T	wYAxisNm	= root:uf:aco:disp:wYAxisNm
//	if ( waveExists( wYAxisNm ) ) 		
//		printf "\t\t\t\tSetMultipleYAxisLbColor()\tut:%d \tsWNm:%s \tColor: '%s'\t\t\t\t\t\t\tAxisNm[ ut-1:%d ]='%s' \r",  ut, sWNm, sRGB, ut,  wYAxisNm[ ut-1 ]
//		TextBox /W=$sWNm /C /N=$wYAxisNm[ ut-1 ]   /G = ( rnRed, rnGreen, rnBlue )   sYUnits	
//	endif
//End

 Function		CopyExtractedSweep( sFolder, wIO, sOrg, sOneDisp, BegPt, nPts, nSmpInt, Gain )
// do not draw all points of wave but only 'nDrawPts' : speed things up much  by loosing a little display fidelity
// going in steps through the original wave makes waveform arithmetic impossible but is still much faster
	wave  /T	wIO
	string		sFolder, sOrg, sOneDisp									// sOrg   is the same as elsewhere  sTNm
	variable	BegPt, nPts, nSmpInt, Gain
	nvar		gbHighResolution	= root:uf:aco:disp:gbHighResolution
	variable	n, nDrawPts 	= 1000						// arbitrary value				

	variable	step	= gbHighResolution ? 1 :  trunc( max( nPts / nDrawPts, 1 ) )
	//variable	step = trunc( max( nPts / nDrawPts, 1 ) )
	
	string  	sFolderOrg	= ksROOTUF_ + sFolder + ":" + ksF_IO + ":" + sOrg								
	if ( waveExists( $sFolderOrg ) )								
		wave	wOrgData	= $sFolderOrg
		make    /O /N = ( nPts / step )	$sOneDisp						//( "root:uf:aco:tmp:"  + sOneDisp )
		wave	wOneDispWaveCur = $sOneDisp						//( "root:uf:aco:tmp:"  + sOneDisp )

		// 030610 new   it should be sufficient to do this only once during initialization
		string 	sUnits	=  UnitsByNm( wIO, sOrg )							// Store the Y units of the wave within the wave to make it accessible for 'Scalebars()'...
		SetScale /P y, 0, 0,  sUnits,  wOneDispWaveCur						//..while at the same time prevent Igor from drawing them   ( Label...."\\u#2" ) 

		SetScale /P X, 0, nSmpInt / kXSCALE * step, ksXUNIT, wOneDispWaveCur 	// /P x 0, number : expand in x by number (Integer wave: change scale from points into ms using the SmpInt)
		// printf  "\t\t\t\t\tDispDurAcq   CopyExtractedSweep() '%s' \t%s\tBegPt:\t%8d\tPts:\t%8d\t   DrawPts:%d  step:%d  xscl:\t%10.4lf\txfactor:%g   Gain:%g \tsize:%.2lf=?=%d  sizeOrg:%d \r", sFolderOrg, pd( sOneDisp, 26), BegPt, nPts, nDrawPts, step, nSmpInt / kXSCALE * step, nSmpInt / kXSCALE*step, Gain, nPts/step, numPnts($sOneDisp), numPnts( $sOrg )
		// string bf; sprintf bf, "\t\t\t\t\tDispDurAcq   CopyExtractedSweep() '%s' \t%s\tOrgPts:\t%7d\t+%7d\t   DrawPts:%d  step:%d  \txfactor:%g   Gain:%g \r", sOrg, pd( sOneDisp, 25), BegPt, nPts, nDrawPts, step, nSmpInt / kXSCALE*step, Gain; Out( bf )
// 040209
// WRONG  for ( n = 0; n <   nPts; 		n += step )		// WRONG:  wFloat tries to write  into the next after the LAST element , which does no harm in IGOR but crashes the XOP
// 		    for ( n = 0; n <= nPts - nStep; 	n += step )
//		 	wOneDispWaveCur[ n / step ] = wOrgData[ BegPt + n ]	/  Gain
//		 endfor
		variable	code	= xUtilWaveExtract( wOneDispWaveCur, wOrgData, nPts, BegPt, step, 1/Gain )			// XOP because Igor is too slow  ,   Params: float tgt. float src, nPnts...
		if ( code )
			printf "****Error: xUtilWaveExtract() \r"
		endif

	endif
End

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function	/S	UnitsByNm( wIO, sTNm )
// Retrieves and returns 'Units' entry from script when the channel name is given,  e.g. 'Adc0'  or  'Dac2'
	wave  /T	wIO
	string 	sTNm
	variable	nIO, c
	Nm2NioC( wIO, sTNm, nIO, c )
	string	 	sUnit		= ios( wIO, nIO, c, cIOUNIT )

	// printf "\t\tUnitsByNm( \t\t\t%s ) :  '%s'  ? '%s'  \r", sTNm, sUnit, sUnit1
	return	sUnit
End

Function		NameUnitsByNm( wIO, sTNm, rsName, rsUnit )
// Retrieves and passes back  'Name'  and   'Units'  entry from script when the channel name is given,  e.g. 'Adc0'  or  'Dac2'
	wave  /T	wIO
	string 	sTNm
	string 	&rsName, &rsUnit
	variable	nIO, c
	Nm2NioC( wIO, sTNm, nIO, c )
	rsUnit	= ios( wIO, nIO, c, cIOUNIT )
	rsName	= ios( wIO, nIO, c, cIONAME )

	// printf "\t\tNameUnitsByNm( \t%s ) :  '%s'  ? '%s'  :  '%s'  ? '%s'  \r", sTNm, rsUnit, rsUnit1, rsName, rsName1
	// todo : possibly return bFound = kNOTFOUND  to distinguish between  'Entry was empty' (it not returning default)  and   'NoMatchingTraceFound'  (actually the latter should not occur)
End

Function		GainByNmForDisplay_( wIO, sTNm )
// Retrieves and returns gain for displaying traces  when the channel name is given,  e.g. 'Adc0'  or  'Dac2'
// The DISPLAY Gain for Dacs is always 1 no matter what the script gain is  as the script  Dac gain effects only the voltage output, not the displayed traces.
// The display of  Adc  and  PoN  traces is effected by their gain.   [ Exotic traces traces like  'Aver'  or  'Sum'   (not yet used)   are also effected by their gain, this behaviour could in the future be changed here...
	wave  /T	wIO
	string 	sTNm
	variable	Gain		= 1
	variable	nIO, c
	Nm2NioC( wIO, sTNm, nIO, c )
	string 	sSrc		= "none"
	if ( stIsDacTrace( sTNm ) )
		Gain	= 1							// For displaying Dac traces we must ignore the Gain. The Dac gain effects only the voltage output, not the displayed traces.
	elseif ( stIsPoNTrace( sTNm ) )
		sSrc	= "Adc" + ios( wIO, nIO, c, cIOSRC ) 		// Assumption: naming convention
		variable	nSrcIO, nSrcC
		Nm2NioC( wIO, sSrc, nSrcIO, nSrcC )
		Gain	= iov( wIO, nSrcIO, nSrcC, cIOGAIN )		// PoN traces have no explicit gain but inherit it from their 'Adc' src channel.
	else				
		Gain	= iov( wIO, nIO, c, cIOGAIN )	
	endif
	// printf "\t\t\t\t\tGainByNmForDisplay( '%s' ) \t-> ioch:%2d\thas Src:\t%s\treturns display gain:\t%7.2lf\t\t(Dacs always return 1) \r", pd(sTNm,9), ioch, pd( sSrc,6), Gain
	return	Gain
End

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function		KillTracesInMatchingGraphs_( sMatch )
	string 		sMatch
	string 		sDeleteList	= WinList( sMatch,  ";" , "WIN:" + num2str( kGRAPH ) )		// 1 is graph
	variable	n
	// kill all matching windows
	for ( n =0; n < ItemsInList( sDeleteList ); n += 1 )
		string  	sWNm	= StringFromList( n, sDeleteList ) 
		RemoveTextBoxUnits( sWNm ) // 040122 	Must remove TextboxUnits BEFORE the traces/axis as they are linked to the axis. If 'Units' had not to be drawn separately (as perhaps only in Igor4?)  the clearing would occur automatically together with the traces
		EraseTracesInGraph( sWNm )
	endfor
End

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function		RemoveTextBoxPP( sWNm )
	string	sWNm
	// remove the 'PreparePrinting'  textbox  from the given  acquis window
	TextBox	/W=$sWNm   /K  /N=$stTBNamePP()
End

Function		RemoveTextBoxUnits( sWNm )
// remove all  yUnits textboxes from the given  acquis window (they must have the same name as the corresponding axis)
	string		sWNm
	variable	n
	//string 	sTBList	=  AnnotationList( sWNm )		// Version1: removes ALL annotations : axis unit   and also   PreparePrinting textbox (removing the latter is usually undesired)
	string 	sTBList	=  AxisList( sWNm )			// Version2: removes  only  axis unit annotations, but only if they cohere to the standard 'Axis unit annotation name = Axis name'
	for ( n = 0; n < ItemsInList( sTBList ); n += 1 )
		string		sTBNm	= StringFromList( n, sTBList )
		TextBox	/W=$sWNm   /K  /N=$sTBNm
		// printf "\t\t\t\tRemoveTextBoxUnits( %s )  n:%2d/%2d   \tTBName:'%s' \t'%s'  \r", sWNm, n,  ItemsInList( sTBList ), sTBNm, sTBList
	endfor
End

Function		RemoveAcqTraces( sWNm )
// erases all traces in this window (must exist)  and  brings window to front  
	string 	sWNm
	EraseTracesInGraph( sWNm )				// 040104
	DoWindow /F $sWNm					// bring to front
End

Function		ConstructYAxis()
	//	dimensions : 		maximum window number	    x	max traces
	make	/O /N=( kMAXCHANS * stModeCnt() * stRangeCnt() )			root:uf:aco:disp:wYAxUsedMax	  = 0		// maximum number of traces / curves used in a specific window
	make	/O /N=( kMAXCHANS * stModeCnt() * stRangeCnt(), kMAXCHANS ) root:uf:aco:disp:wYAxisExists		  = 0		// flag telling if the specified trace / curve is already displayed in the window
	make	/O /N=( kMAXCHANS * stModeCnt() * stRangeCnt(), kMAXCHANS ) root:uf:aco:disp:wYAxisNegLim	  = -5000	// minimum axis end value
	make	/O /N=( kMAXCHANS * stModeCnt() * stRangeCnt(), kMAXCHANS ) root:uf:aco:disp:wYAxisLastNegLim = -5000	// minimum axis end value
	make	/O /N=( kMAXCHANS * stModeCnt() * stRangeCnt(), kMAXCHANS ) root:uf:aco:disp:wYAxisPoslim	  =  5000	// maximum axis end value
	make	/O /N=( kMAXCHANS * stModeCnt() * stRangeCnt(), kMAXCHANS ) root:uf:aco:disp:wYAxisLastPosLim  =  5000	// maximum axis end value
	make	/O /N=( kMAXCHANS * stModeCnt() * stRangeCnt() )			 root:uf:aco:disp:wYABotAxEndMax = -Inf	// bottom axis end point in a specific window
	make  /T	/O /N=8 root:uf:aco:disp:wYAxisNm = { "left", "right0", "right1", "right2", "right3", "right4", "right5", "right6" } 
	// printf "\t\tConstructYAxis() \r"
End

Function		CountUsedYAxis( w )
// Store the number of traces / curves for each window  in an Yaxis data structure  (the number of Yaxis is usually just the number of curves but could be less if some traces share the same Yaxis)
	variable	w
	wave	wYAxUsedMax	= root:uf:aco:disp:wYAxUsedMax
	string 	sCurves		= RetrieveCurves( w )
	wYAxUsedMax[ w ]		= ItemsInList( sCurves, ksCURVSEP )
	// printf "\t\tCountUsedYAxis() \t\t\t\t\t---> wYAxUsedMax[ w:%2d ]:%d \t'%s' \r", w, wYAxUsedMax[ w ], sCurves[0,200]
End


Function		TotalStorePoints( sFolder, wG, wFix )
	string  	sFolder
	wave  	 wG, wFix
	variable	b, f, s, pts = 0
	variable	pr	= 0				//  NOT  REALLY   PROTOCOL  AWARE  ..........
	for ( b  = 0; b < eBlocks( wG ); b += 1 )
		for ( f = 0; f < eFrames( wFix, b ); f += 1 )
			for ( s = 0; s < eSweeps( wFix, b ); s += 1 )
				//pts += SwpEndSave( b, f, s ) - SwpBegSave( b, f, s )
				pts += SweepEndSave( sFolder, pr, b, f, s ) - SweepBegSave( sFolder, pr, b, f, s )	//  NOT  REALLY   PROTOCOL  AWARE  ..........
			endfor
		endfor
	endfor
	// print "TotalStorePoints()  ", pts 	
	return	pts
End

Function		GetFinalSweepNr(  wG, wFix )
	wave  	 wG, wFix
	variable	b, f, SweepCnt = 0
	for ( b  = 0; b < eBlocks( wG ); b += 1 )
		for ( f = 0; f < eFrames( wFix, b ); f += 1)
			SweepCnt += eSweeps( wFix, b )
		endfor
	endfor
	// print "GetFinalSweepNr()", SweepCnt,	vGet( "Sweeps", "N" ) * vGet( "Frames", "N" ) 	// PULSE only
	return	SweepCnt
End

//// 031007  NOT   PROTOCOL  AWARE  ..........
//Function		SwpBegAll( b, f, s )
//	variable	b, f, s
//	return	swGetTime( b, f, s, SWPBEG )
//End
//
//Function		SwpLenAll( b, f, s )
//	variable	b, f, s
//	return	swGetTime( b, f, s, SWPLEN )
//End
//
//Function		SwpBegSave( b, f, s )
//	variable	b, f, s
//	return	swGetTime( b, f, s, SWPBEGSTORE )
//End
//
//Function		SwpLenSave( b, f, s )
//	variable	b, f, s
//	return	swGetTime( b, f, s, SWPLENSTORE )
//End
//
//Function		SwpEndSave( b, f, s )
//	variable	b, f, s
//	// printf "\tSwpEndSave( b:%d  , f:%d  , s:%d   ) -> %g + %g \r", b, f, s, SwpBegSave( b, f, s ) , SwpLenSave( b, f, s )
//	if ( f < 0 )				
//		InternalError( "SwpEndSave( f:" + num2str( f ) + ", s:" + num2str( s ) + " ) receives negative frame -> returns 0 "	 )// 140102
//		return 0
//	endif
//	return	SwpBegSave( b, f, s ) + SwpLenSave( b, f, s )
//End
//
//Function		FrmBegSave( b, f )
//	variable	b, f
//	return	SwpBegSave( b, f, 0 )
//End
//
//Function		FrmEndSave( b, f )
//	variable	b, f
//	variable	s =  eSweeps( wFix, b ) - 1; 
//	return	SwpEndSave( b, f, s )
//End
//// 031007 ......... NOT   PROTOCOL  AWARE 


// 031007  PROTOCOL  AWARE
Function		SweepBegAll( sFolder, p, b, f, s )
	string  	sFolder
	variable	p, b, f, s
	p	=  cPROT_AWARE	?  p  : 0				// use protocol 0 in the normal (=not Protocol aware) case
	return	swGetTimes( sFolder, p, b, f, s, SWPBEG )
End

Function		SweepLenAll( sFolder, p, b, f, s )
	string  	sFolder
	variable	p, b, f, s
	p	=  cPROT_AWARE	?  p  : 0				// use protocol 0 in the normal (=not Protocol aware) case
	return	swGetTimes( sFolder, p, b, f, s, SWPLEN )
End

Function		SweepBegSave( sFolder, p, b, f, s )
	string  	sFolder
	variable	p, b, f, s
	p	=  cPROT_AWARE	?  p  : 0				// use protocol 0 in the normal (=not Protocol aware) case
	return	swGetTimes( sFolder, p, b, f, s, SWPBEGSTORE )
End

Function		SweepLenSave( sFolder, p, b, f, s )
	string  	sFolder
	variable	p, b, f, s
	p	=  cPROT_AWARE	?  p  : 0				// use protocol 0 in the normal (=not Protocol aware) case
	return	swGetTimes( sFolder, p, b, f, s, SWPLENSTORE )
End

Function		SweepEndSave( sFolder, p, b, f, s )
	string  	sFolder
	variable	p, b, f, s
	// printf "\tSweepEndSave( p:%d , b:%d  , f:%d  , s:%d   ) -> %g + %g \r", p, b, f, s, SweepBegSave( p, b, f, s ) , SweepLenSave( p, b, f, s )
	if ( f < 0 )				
		InternalError( "SweepEndSave( f:" + num2str( f ) + ", s:" + num2str( s ) + " ) receives negative frame -> returns 0 "	 )// 140102
		return 0
	endif	
	p	=  cPROT_AWARE	?  p  : 0				// use protocol 0 in the normal (=not Protocol aware) case
	return	swGetTimes( sFolder, p, b, f, s, SWPBEGSTORE ) + swGetTimes( sFolder, 0, b, f, s, SWPLENSTORE ) // p(LEN) = 0 as the length is the same for all protocols
End

Function		SweepEndSaveProtAware( sFolder, p, b, f, s )
// used in Process() !
	string  	sFolder
	variable	p, b, f, s
	return	swGetTimes( sFolder, p, b, f, s, SWPBEGSTORE ) + swGetTimes( sFolder, 0, b, f, s, SWPLENSTORE ) // p(LEN) = 0 as the length is the same for all protocols
End

Function		FrameBegSave( sFolder, p, b, f )
	string  	sFolder
	variable	p, b, f
	return	SweepBegSave( sFolder, p, b, f, 0 )
End

Function		FrameEndSave( sFolder, wFix, p, b, f )
	string  	sFolder
	wave  	wFix
	variable	p, b, f
	variable	s =  eSweeps( wFix, b ) - 1; 
	return	SweepEndSave( sFolder, p, b, f, s )
End
// 031007  ............PROTOCOL  AWARE

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////   ACQUISITION  WINDOW  HOOK  FUNCTION
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// These constants determine the way PulsTrain reacts on pressing modifier keys during Online analysis
// As all possible combinations seem to be used, any extension would have to work  with xxx:GraphMarquee (like region RISE now)
// Another approach: try to extract double clicks (via timer ticks in the sInfo string) and use them..

constant		STOREPEAK = 2,  	STOREBASE =8,  STOREPOINT = 4

Function		It_is( Modifier, goal )
// check the exact combination of pressed and non-pressed keys, but ignore mouse buttons
	variable	Modifier, goal			
	modifier = modifier &  (kSHIFT + kALT + kCTRL)	// mask out mouse button (=1)
	return ( Modifier == goal )					// check exact match of each of  the three bits ( on / off )   
End	


Function		 fAcqWndHook_( sInfo )
// Here we handle all user actions (=mouse events)  executed in any  acquisition window.
// Executed whenever the mouse is moved within one of the acquisition windows. Gets mouse position in pixels...
// ..and computes wave and cursor values in axis coordinates which are displayed in the status bar.
// Depending on additional buttons pressed, different actions are executed:
// - Clicking (no keys):	
// - Clicking (+ALT 4):				Update and STOREPOINT 
// - Clicking (+CTRL 8):
// - Clicking (+SHIFT+CTRL 10):
// - Dragging (no keys):		
// - Dragging (+SHIFT 2):			Update and STOREPEAK region		
// - Dragging (+CTRL 8):			Update and STOREBASE region		
// - Dragging (+SHIFT+CTRL 10):		Copy traces from 'Auto' window into 'User' window.......no

// - Dragging (+ALT 4):				Used by IGOR (moves region within axes)
// - Dragging (+SHIFT+ALT 6):		Used by IGOR (switches character set)
// - Dragging (+CTRL+ALT 12):		does not work (ignores mousedown event)
// - Dragging (+SHIFT+CTRL+ALT 14):	does not work (ignores mousedown event)

// If these button combinations are sufficient then specifying the type of a region directly by a modifier key is good: it is effective and fast for the user. 
// If these button combinations are not sufficient then the type of a region must be specified afterwards by a  xxx : GraphMarque context menu (see isBase()...)

	string		sInfo
	string  	sFolder		= ksfACO
	wave  /T	wIO			= $ksROOTUF_ + sFolder + ":ar:wIO"  						// This  'wIO'  is valid in FPulse ( Acquisition )
	nvar		gCursX		= root:uf:aco:disp:gCursX
	nvar		gCursY		= root:uf:aco:disp:gCursY
	variable	nReturnCode	= 0						// 0 if nothing done, else 1 or 2 (prevents killing)
	string 	sEvent	= StringByKey(      "EVENT",	  sInfo )
	string		sWNm	= StringByKey(      "WINDOW", sInfo )	// user clicks into this window: remember it even if it is left or it gets deselected... 
	variable	Modifier	= NumberByKey( "MODIFIERS", sInfo )// Buttons and keys pressed: MOUSE=1,  SHIFT=2, ALT=4, CTRL=8
	variable	MouseX	= NumberByKey( "MOUSEX", sInfo )	// the current cursor position in pixel coordinates
	variable	MouseY	= NumberByKey( "MOUSEY", sInfo ) 
	variable	w, wNr, wCnt
	
	// Transform mouse pixels into axis coordinates and store globally (needed always as it is displayed in the StatusBar)	
	gCursX	= numType( MouseX ) != kNUMTYPE_NAN ? AxisValFromPixel( sWNm , "bottom", 	MouseX ) : 0
	gCursY	= numType( MouseY ) != kNUMTYPE_NAN ? AxisValFromPixel( sWNm , "left",        MouseY ) : 0

	// To speed things up, we quit immediately when the event  is MOUSEMOVE (which is almost always the case)
	// We proceed only for the rarely occuring MOUSEUP and MOUSEDOWN events which are the only events processed below
	// printf "\t\tfAcqWndHook event (including 'mousemoved' ):'%s'   \t in wnd '%s'  (wCnt:%d) \r", sEvent, sWnd, WndCnt_()
	if ( StrSearch( sInfo, "EVENT:mousemoved;", 	0 ) != kNOTFOUND )
		 // printf "returning prematurely (only mouse moves)\r"
		return 0 
	endif
	// printf "\t\tfAcqWndHook event (except 'mousemoved' ):%s \t in wnd '%s'  (wCnt:%d) [KeyModifier:%d] \r", pd(sEvent,12), sWnd, WndCnt_(), Modifier

	wNr	= WndNr_( sWNm ) 
	if ( cmpstr( sEvent, "activate" ) == 0 )
		SetActiveWnd( sWNm )			// needed to fill the traces listbox in AllowIndiviualColorsAxis with the specific traces contained in the window whose listbos has been selected
	endif
	
		// 040120		adjust the YOfs slider size to the graph size whenever the graph is resized
		w	= WndNr_( sWNm ) 
		if ( cmpstr( sEvent, "resize" )  == 0 )
			nvar		bAcqControlbar	= root:uf:aco:disp:bAcqControlbar
			variable	rnRange, rnMode, rnInstance, rbAutoscl, rYOfs, rYZoom 
			string		rsTNm, rsRGB 
			string		sCurves	= RetrieveCurves( w )		
			variable	CurveCnt	= ItemsInList( sCurves, ksCURVSEP )
			variable	nWUT	= WndUsersTrace( w )												
			string		sCurve	= StringFromList( nWUT, sCurves, ksCURVSEP )				
			stExtractCurve( sCurve, rsTNm, rnRange, rnMode, rnInstance, rbAutoscl, rYOfs, rYZoom, rsRGB )		
			variable	bDisableCtrlOfs		= DisableCtrlOfs(    rsTNm, bAcqControlbar, CurveCnt, rbAutoscl ) 
			variable	Gain		= GainByNmForDisplay_( wIO, rsTNm )
			ConstructCbSliderYOfs( sWNm, bDisableCtrlOfs, rYOfs, Gain )					// also constuct the optional Controlbar on the right (only in Igor5 and only if cbVERTICAL_SLIDER_YOFS is ON ) 
		endif

	if ( cmpstr( sEvent, "kill" ) == 0 )
		// When removing a window we must remove it at 3 places: in TWA, in WLoc  and the graph itself 
		wCnt	= WndCnt_()

		// 021105		Peculiar behaviour: 
		// We must explicitly kill the graph to be killed right here a 2. time to free the name so the next graph can use it below during rename with 'DoWindow /C'. 
		// If we don't do this Igor will complain that renaming will fail because the graph still exists, although we are in the 'killing' hook function for just this graph.
		// This seems to work although I do not really understand this. We HOPE  that it does not interfere with IGORs 'killing' process.....
		// We are in the 'killing' hook function and of course IGOR would also kill the graph but for us too late: probably after leaving function...

		// printf "\t\tfAcqWndHook event:'%s' [wCnt:%2d]  \tbefore \tdouble kill in wnd %2d  (%s) tsWinList: '%s'  ->... \r", sEvent, wCnt, wNr, sWnd, WinList( "W*",  ";" , "WIN:" + num2str( kGRAPH ) )
		DoWindow /K $sWNm
		// printf "\t\tfAcqWndHook event:'%s' [wCnt:%2d]  \tafter  \tdouble kill in wnd %2d  (%s) tsWinList: '%s'  ->... \r", sEvent, wCnt, wNr, sWnd, WinList( "W*",  ";" , "WIN:" + num2str( kGRAPH ) )

		// IGOR 4 code
//		// Remove index of killed window in TWA and in WLoc by copying all following into the previous (and deleting the last one by decreasing the array size) 
//		string 	sActWnd
//		for ( w = wNr + 1; w < wCnt; w += 1 )
//			// delay(.5)		// this delay is useful to trigger the error described below on a fast computer where it might otherwise escape detection 
//			CopyWndLocAndUsersTrace( w - 1, w )
//			StoreCurves( w - 1, RetrieveCurves( w ) )
//			// print "\t\t", sWNm ,  WndNm_( w ), "->",  WndNm_( w - 1 )	// old name  ->   new name
//
//			// These are very ( and I mean very ! ) serious IGOR limitations: 
//			// Igors 'Display'  creates a window but does not  accept a window name for  it . IGOR rather assigns an arbitrary 'Graphxxxxx' name
//			// Igors 'DoWindow /C   MyWndName'  renames a window but does not  accept a source window name. IGOR rather uses the current active window
//			// Igor provides no mechanism to 'lock'  the state in between those two actions
//			// -> in a program we must have control over the window names and therefore must rename them  with 'DoWindow /C   MyWndName'
//			// -> when the user changes and clicks into another window  just in between the moment of creation and renaming (which is quite likely in an event-driven program)...
//			// ...this concept crashes : Igor will then rename currently clicked window and not the intended window ....
//
//			// We must make sure that we rename an acquisition window and not a panel which the user might have clicked when execution is right here after 'Display'.... 
//			DoWindow /F $WndNm_( w )				// bring to front and make it the active window
//
//			sActWnd	=  WinName( 0, 255)			// Get the active (=top) window, this should be the window  just brought to the front...
//			if ( cmpstr( sActWnd, WndNm_( w ) ) )		// ..but it could also be some Panel  which the user might have clicked ....
//				w -= 1							// ..right after 'DoWindow /F ...' has been executed.  In this (not so rare) case we must get rid...
//				printf "\t\tSee the problem (2) : We must process window '%s' \tbut would have processed '%s' \t(without this correction code)...\r", WndNm_( w ), sActWnd		
//				continue							// ..of the panel and process this window  w  from the start  hoping to have more.. 
//			endif								// ..luck the next time...................
//
//			DoWindow /C $WndNm_( w -1 )			// rename with next smaller number
//		endfor

		// IGOR 5 code using  'RenameWindow'
		// Remove index of killed window in TWA and in WLoc by copying all following into the previous (and deleting the last one by decreasing the array size) 
		for ( w = wNr + 1; w < wCnt; w += 1 )
			CopyWndLocAndUsersTrace( w - 1, w )
			StoreCurves( w - 1, RetrieveCurves( w ) )
			// print "\t\t", sWNm ,  WndNm_( w ), "->",  WndNm_( w - 1 )	// old name  ->   new name
			RenameWindow	$WndNm_( w )	$WndNm_( w -1 )		// old name  ->   new name has next smaller number
		endfor

		stRedimensionWnd( wCnt - 1 )
	endif



	if ( It_is( Modifier, STOREBASE ) ||  It_is( Modifier, STOREPEAK ) ||  It_is( Modifier, STOREPOINT ) )
		AutoWndAnalysis( wIO, sInfo, gCursX, gCursY, modifier )	// it might be more effective to pass some variables and  the string
	endif

	return	nReturnCode						// 0 if nothing done, else 1 or 2 (prevents killing)
End


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  TRACE  ACCESS  FUNCTIONS  FOR  THE USER
//  Remarks:
//  It has become standard user practice to access the acquired data in form of the waves/traces displayed in the acquisition windows.
//  This was not originally intended: it was intended (and is perhaps better) to access the data from the complete acquisition wave (e.g. 'Adc0' )
//  Accessing the data from the display waves (as it is implemented here) has the advantage that the user can see and check the data on screen.
//  This is also the drawback: he cannot access those data for which he has turned the display OFF,  he cannot access trace segments...
// ...which are longer or have a different starting point than those on screen.
//  These limitations vanish when access to the complete waves is made: the user could copy arbitrary segments for his private use or act on the original wave...


Function		ShowTraceAccess_(  wG, wFix )
// prints completely composed acquisition display trace names (including folder, mode/range, begin point  which the user can use to access the traces
	wave  	 wG, wFix
	variable	bl, fr, sw, nType
	string		sTNm	= "Dac0"
	for ( bl = 0; bl < eBlocks( wG ); bl += 1 )
	printf  "\t\tShowTraceAccess()  ( only for '%s' )    Block:%2d/%2d \r", sTNm, bl,  eBlocks( wG )
		for ( fr = 0; fr < eFrames( wFix, bl ); fr += 1 )
			printf  "\t\t\tf:%2d\tF:%s\tP:%s\tR:%s\ts1%s\ts2%s ...\r", fr ,pd(TraceFB( sTNm,  fr, bl ),25), pd(TracePB( sTNm,  fr, bl ),25), pd(TraceRB( sTNm,  fr, bl ),25), pd(TraceSB( sTNm,  fr, bl, 0 ),25), pd(TraceSB( sTNm,  fr, bl, 1 ),25)
		endfor
	endfor
End

// There are 'nFrames'  traces in 'Many superimposed' mode e.g. 'Adc0SM_0' , 'Adc0SM_2000' , 'Adc0SM_4000'  which make sense to be selected...
// ...but there is only 1 'current'  mode trace e.g. 'Adc0SC_'  which is useless here because it stores just the last sweep or frame


// 031007     NOT REALLY  PROTOCOL  AWARE ............

Function  /S		TraceF( sTNm, fr )
// return composed  FRAME  Acquis display trace name  when base name and frame is given ( for block 0 ) 
	string		sTNm
	variable	fr
	variable	bl	= 0
	variable	pr	= 0	// 031007     NOT REALLY  PROTOCOL  AWARE ............
	string  	sFolder	= ksfACO
	return	Trace( sFolder, sTNm, cFRAME, FrameBegSave( sFolder, pr, bl, fr ) )
End

Function  /S		TraceP( sTNm, fr )
// return composed  PRIMARY  Acquis display trace name  when base name and frame is given ( for block 0 ) 
	string		sTNm
	variable	fr
	variable	bl	= 0
	variable	pr	= 0	// 031007     NOT REALLY  PROTOCOL  AWARE ............
	string  	sFolder	= ksfACO
	return	Trace( sFolder, sTNm, cPRIM, FrameBegSave( sFolder, pr, bl, fr ) )
End

Function  /S		TraceR( sTNm, fr )
// return composed  RESULT  Acquis display trace name  when base name and frame is given ( for block 0 ) 
	string		sTNm
	variable	fr
	variable	bl	= 0
	variable	pr	= 0	// 031007     NOT REALLY  PROTOCOL  AWARE ............
	string  	sFolder	= ksfACO
	wave  	wFix		= $ksROOTUF_ + sFolder + ":ar:wFix"  					// This  'wFix'	is valid in FPulse ( Acquisition )
	return	Trace( sFolder, sTNm, cRESULT, SweepBegSave( sFolder, pr, bl, fr,  eSweeps( wFix, bl ) - 1 ) )
End

Function  /S		TraceS( sTNm, fr, sw )
// return composed  SWEEP  Acquis display trace name  when base name,  frame  and  sweep  is given ( for block 0 ) 
	string		sTNm
	variable	fr, sw
	variable	bl	= 0
	variable	pr	= 0	// 031007     NOT REALLY  PROTOCOL  AWARE ............
	string  	sFolder	= ksfACO
	return	Trace( sFolder, sTNm, cSWEEP, SweepBegSave( sFolder, pr, bl, fr,  sw ) )
End

Function  /S		TraceFB( sTNm, fr, bl )
// return composed  FRAME  Acquis display trace name  when base name and frame and block is given
	string		sTNm
	variable	fr, bl
	variable	pr	= 0	// 031007     NOT REALLY  PROTOCOL  AWARE ............
	string  	sFolder	= ksfACO
	return	Trace( sFolder, sTNm, cFRAME, FrameBegSave( sFolder, pr, bl, fr ) )
End

Function  /S		TracePB( sTNm, fr, bl )
// return composed  PRIMARY  Acquis display trace name  when base name and frame and block is given
	string		sTNm
	variable	fr, bl
	variable	pr	= 0	// 031007     NOT REALLY  PROTOCOL  AWARE ............
	string  	sFolder	= ksfACO
	return	Trace( sFolder, sTNm, cPRIM, FrameBegSave( sFolder, pr, bl, fr ) )
End

Function  /S		TraceRB( sTNm, fr, bl )
// return composed  RESULT  Acquis display trace name  when base name and frame and block is given
	string		sTNm
	variable	fr, bl
	variable	pr	= 0	// 031007     NOT REALLY  PROTOCOL  AWARE ............
	string  	sFolder	= ksfACO
	wave  	wFix		= $ksROOTUF_ + sFolder + ":ar:wFix"  					// This  'wFix'	is valid in FPulse ( Acquisition )
	return	Trace( sFolder, sTNm, cRESULT, SweepBegSave( sFolder, pr, bl, fr,  eSweeps( wFix, bl ) - 1 ) )
End

Function  /S		TraceSB( sTNm, fr, bl, sw  )
// return composed  SWEEP  Acquis display trace name  when base name , frame , block  and  sweep  given
	string		sTNm
	variable	fr, sw, bl
	variable	pr	= 0	// 031007     NOT REALLY  PROTOCOL  AWARE ............
	string  	sFolder	= ksfACO
	return	Trace( sFolder, sTNm, cSWEEP, SweepBegSave( sFolder, pr, bl, fr, sw ) )
End

Function  /S		Trace( sFolder, sTNm, nRange, BegPt )
// returns  any  composed  Acquis display trace name....
	string		sFolder, sTNm
	variable	nRange, BegPt
	variable	nMode	= cMANYSUPIMP
	return	BuildTraceNmForAcqDisp( sFolder, sTNm, nMode, nRange, BegPt)
End

// 031007  -----------   NOT  REALLY  PROTOCOL  AWARE 

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// FPDispDlg.IPF 
// 
// Routines for
//	editing trace and window appearance during acquisition 
//	statusbar during acquisition 

// History:
// Major revision 040108..040204
	
//#pragma rtGlobals=1								// Use modern global access method.

static constant	cXLBTRACESSIZE			= 92		// empirical values, could be computed .  81 for 'Dac0SC' , 86 for 'Dac0SCa' , 92 for 'Dac0 SC a'
static constant	cXBUTTONSIZE			= 31
static constant	cXBUTTONMARGIN			=  2
static constant	cXLBCOLORSIZE			= 96
static constant	cbVERTICAL_SLIDER_YOFS	= 1 //1	// 0 : horizontal YOffset slider , 1 : vertical YOffset slider (better but requires Igor5) 
static constant	cbDISABLEbyGRAYING		= 0 //1 	// 0 : disable the control by hiding it completely (better as it save screen space and as it avoids confusion) ,  1 : disable the control by graying it 
static constant	cbALLOW_ADC_AUTOSCALE	= 1 //1 	// 0 : autoscale only Dacs ,  1 : also autoscale   Adc , Pon , etc ( todo: not yet working correctly. Problem: tries to autoscale trace on screen which may be flat line -> CRASHES sometimes )
static constant	cbAUTOSCALE_SYMMETRIC	= 0 //1 	// 0 : autoscale exactly between minimum and maximum of trace possibly offseting zero,  1 : autoscale keeping pos. and neg. half axis at same length ( zero in the middle)

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  CONTROLBARS  in  the  ACQUISITION  WINDOWS  with  BUTTONS(=Copy,Ins,Del)  ,  LISTBOXES(=Trace,YZoom)   ,   SLIDER(=YOfs)   and   POPMENU(=Colors)
//  
// The controlbar code for each of the the buttons, listboxes and popmemu is principally made up of 2 parts : 
// Part1 stores the user setting in the underlying control structure TWA. This is the more  important part as TWA controls the display during the next acquisition.
// Part2 has the purpose to give the user some immediate feedback that his changes have been accepted. 
//	For this existing data are drawn preliminarily with changed colors, zooms, Yaxes in a manner which is to reflect the user changes at once which would without this code only take effect later during the next acquisition.
//	The code must handle  'single'  traces  and   'superimposed'  traces (derived from the basic trace name but with the begin point number appended)
//	The code must allow multiple instances of the same trace allowing the same data to be displayed at the same time with different zoom factors,..
//	  ...for this we must do much bookkeeping because Igor has the restriction of requiring the same trace=wave name but appends its own instance number whereas we must do our own instance counting in TWA
//	We take the approach to not even try to keep track which instances of which traces in which windows have to be redrawn, instead we we redraw all ( -> DisplayOffLine() )
//	This is sort of an overkill but here we do it only once in response to a (slow) user action while during acquis we do the same routine (=updating all acquis windows) very often... 
// 	...so we accept the (theoretical) disadvantage of updating traces which actually would have needed no update because it simplifies the program code tremendously  .

Function		CreateAllControlBarsInAcqWnd( wIO )
// show / hide the ControlBar  immediately
	wave  /T	wIO
	variable	w, wCnt = WndCnt_()
	for ( w = 0; w < wCnt; w += 1) 
		string 	  sWNm = WndNm_( w )			// or.... ControlUpdate(...)...
		CreateControlBarInAcqWnd( wIO, sWNm )		// show / hide the ControlBar  immediately
	endfor
End

Function		CreateControlBarInAcqWnd( wIO, sWNm ) 
// depending on  'bAcqControlbar'  build and show or hide the controlbar  AND  show or hide the individual controls (buttons, listboxes..)
	wave  /T	wIO
	string  	sWnm
	// supply the correct start values for the listboxes
	variable	w		= WndNr_( sWNm )
	variable	rnRange, rnMode, rnInstance, rbAutoscl, rYOfs, rYZoom 
	string 	 rsTNm, rsRGB
	string 	sCurves	= RetrieveCurves( w )		
	variable	CurveCnt	= ItemsInList( sCurves, ksCURVSEP )
	variable	nCurve	= 0												
	
	nvar		bAcqControlbar	= root:uf:aco:disp:bAcqControlbar
	variable	bDisableGeneral	= DisableCtrlCopyDelColors( bAcqControlbar, CurveCnt ) 	// after all traces have been deleted hide the Traces, Copy , Delete and Color controls...
	variable	bDisableInsert		= DisableCtrlInsert( bAcqControlbar ) 					// the 'Insert' button is useful  even if there are no traces left 

	variable	ControlBarHeight 	= bAcqControlbar				? 26 : 0 			// height 0 effectively hides the whole controlbar

	ControlBar /W = $sWNm  ControlBarHeight

	// Version 1 : Always display the 1. trace of the traces listbox in the traces listbox and its corresponding color and YZoom values
	// ... no matter which was the last selected active user trace when the user last pressed  'Save display config'  (stored in wWLoc and later reloaded on 'Apply')
	//SetWndUsersTrace( w, nCurve )  	// 040104	 Overwrite this value  with   nCurve = 0  to avoid non-congruent  trace/color/zoom listboxes
																		
	// Version 2 : Display that trace of the traces listbox in the traces listbox (and its corresponding color and YZoom values) ...
	// ...which was the selected active user trace when the user last pressed  'Save display config' 
	 nCurve	= WndUsersTrace( w )	// 040104	
	
	string 	sCurve	= StringFromList( nCurve, sCurves, ksCURVSEP )				

	stExtractCurve( sCurve, rsTNm, rnRange, rnMode, rnInstance, rbAutoscl, rYOfs, rYZoom, rsRGB )		
	ConstructCbButtonCopy( sWNm, bDisableGeneral )
	ConstructCbButtonInsert( sWNm, bDisableInsert )
	ConstructCbButtonDelete( sWNm, bDisableGeneral )

	SetActiveWnd( sWNm)	
	ConstructCbListboxTraces( sWNm, bDisableGeneral, nCurve, CurveCnt )				// only if there is more than 1 trace  the TraceSelectListbox will be constructed

	// printf "\tCreateControlBarInAcqWnd( sWNm:%s ) \tnCurve:%d   rsTNm: '%s' \r",  sWNm, nCurve, rsTNm 
	ConstructCbPopmenuColors( sWNm, bDisableGeneral, rsRGB )

	variable	bDisableCtrlAutoscl	= DisableCtrlAutoscl( rsTNm, bAcqControlbar, CurveCnt ) 
	variable	bDisableCtrlZoom	= DisableCtrlZoom( rsTNm, bAcqControlbar, CurveCnt, rbAutoscl ) 
	variable	bDisableCtrlOfs		= DisableCtrlOfs(    rsTNm, bAcqControlbar, CurveCnt, rbAutoscl ) 

	ConstructCbCheckboxAuto( sWNm, bDisableCtrlAutoscl, rbAutoscl )						
	ConstructCbListboxYZoom( sWNm, bDisableCtrlZoom,  rYZoom )						
	variable	Gain	= GainByNmForDisplay_( wIO, rsTNm )
	ConstructCbSliderYOfs( sWNm, bDisableCtrlOfs, rYOfs, Gain )					// also constuct the optional Controlbar on the right (only in Igor5 and only if cbVERTICAL_SLIDER_YOFS is ON ) 

	// printf "\tCreateControlBarInAcqWnd( sWNm:%s ) \tw:%d , nWUT:%d =?= nCurve:%2d/%2g \tsCurve:'%s' \r", sWNm, w, WndUsersTrace( w ), nCurve, CurveCnt, sCurve
End

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Functions  controling  whether a specific control  of the control bar  is to be enabled, disabled by completely hiding it or disabled by just graying it.

Function		DisableCtrlInsert( bAcqCb ) 
	variable	bAcqCb
	variable	bDisableIns	= bAcqCb 				?   0 : 1 		// the 'Insert' button is useful  even if there are no traces left 
	return	bDisableIns
End

Function		DisableCtrlCopyDelColors( bAcqCb, nCurveCnt ) 
	variable	bAcqCb, nCurveCnt 
	variable	bDisable		= bAcqCb && nCurveCnt > 0	?   0 : 1 	// after all traces have been deleted hide the Traces, Copy , Delete and Color controls...
	return	bDisable
End

Function		DisableCtrlAutoscl( sTNm, bAcqCb, nCurveCnt ) 
	string  	sTNm
	variable	bAcqCb, nCurveCnt 
	variable	bDisableAutosclCheckbox
	if (  !  cbALLOW_ADC_AUTOSCALE )				
	 	bDisableAutosclCheckbox	=  DisableCtrlCopyDelColors( bAcqCb, nCurveCnt )   ||  ! stIsDacTrace( sTNm )	//  only  Dacs  can be autoscaled
	else
		bDisableAutosclCheckbox	=  DisableCtrlCopyDelColors( bAcqCb, nCurveCnt )  					//  Dacs and  Adcs can be autoscaled
	endif
	return	bDisableAutosclCheckbox
End

Function		DisableCtrlZoom( sTNm, bAcqCb, nCurveCnt, bAutoscl ) 
// determine whether the control must be shown or hidden depending on the state of of other controls and  depending on other factors
	string  	sTNm
	variable	bAcqCb, nCurveCnt, bAutoscl
	variable	bDisableGeneral	= DisableCtrlCopyDelColors( bAcqCb, nCurveCnt )			// after all traces have been deleted hide the Copy , Delete and Color controls...
	variable	bDisableCtrlAutoscl	= DisableCtrlAutoscl( sTNm, bAcqCb, nCurveCnt ) 
	variable	nDisableCtrlZoom	= bDisableGeneral   ||  ( ! bDisableCtrlAutoscl  &&  bAutoscl )		// not used : only enable (=0)  or hide (=1)  the control, no possibility to gray it
	if ( bDisableGeneral == 1 )		
		nDisableCtrlZoom  = 1													// if all controls are to disappear then the Zoom should also hide : do not allow graying
	else
		nDisableCtrlZoom  =  ( ! bDisableCtrlAutoscl  &&   bAutoscl )  *  ( 1 + cbDISABLEbyGRAYING )	// 0 enables , 1 disables by hiding , 2 disables by graying
	endif
	return	nDisableCtrlZoom													// 0 enables , 1 disables by hiding , 2 disables by graying
End

Function		DisableCtrlOfs( sTNm, bAcqCb, nCurveCnt, bAutoscl ) 
// determine whether the control must be shown or hidden depending on the state of of other controls and  depending on other factors
	string  	sTNm
	variable	bAcqCb, nCurveCnt, bAutoscl
	variable	bDisableGeneral	= DisableCtrlCopyDelColors( bAcqCb, nCurveCnt )			// after all traces have been deleted hide the Copy , Delete and Color controls...
	variable	bDisableCtrlAutoscl	= DisableCtrlAutoscl( sTNm, bAcqCb, nCurveCnt ) 
	variable	nDisableCtrlOfs		= bDisableGeneral   ||  ( ! bDisableCtrlAutoscl  &&  bAutoscl )		// not used : only enable (=0)  or hide (=1)  the control, no possibility to gray it
	if ( bDisableGeneral == 1 )		
		nDisableCtrlOfs 	= 1														// if all controls are to disappear then the Zoom should also hide : do not allow graying
	else
		nDisableCtrlOfs	=  ( ! bDisableCtrlAutoscl  &&   bAutoscl )  *  ( 1 + cbDISABLEbyGRAYING )	// 0 enables , 1 disables by hiding , 2 disables by graying
	endif
	return	nDisableCtrlOfs
End

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  CONTROLBARS  in  the  ACQUISITION  WINDOWS : CONSTRUCTION

Function		ConstructCbListboxTraces( sWNm, bDisable, nCurve, nCurveCnt )
// Fill the traces listbox in the ControlBar of each acquisition window only with those traces actually contained in the window. 
// 1. IGOR allows the 'live' update of the listbox  only via a global string  or a function without parameters (=ActiveTN1L() ), which also needs a global string  'gsLbActiveWnd '
	string 	sWNm
	variable	bDisable, nCurve, nCurveCnt
	// Hide the Select-Trace-Listbox  if only 1 trace is left. One could alternatively show it even when only 1 trace is left to tell the user the type (which is also shown in the window title)
	// if ( nCurveCnt  >  0 )		//  show Select-Trace-Listbox  for  1  or more traces....
	// if ( nCurveCnt  >  1 )		//  show Select-Trace-Listbox  for  2  or more traces....
		variable	w	= WndNr_( sWNm )
		PopupMenu  CbListboxTrace,  win = $sWNm, pos = {2, 2}, size = {36,16} , mode = nCurve+1, title = ""  
		PopupMenu  CbListboxTrace,  win = $sWNm, proc = CbListboxTrace, 	value = ActiveTNL1()		// Igor does not allow locals in the following PopupMenu
		PopupMenu  CbListboxTrace,  win = $sWNm, help = {"If you have multiple traces in the windows, you must first select the trace to apply on."}
		PopupMenu  CbListboxTrace,  win = $sWNm, disable = bDisable
	// else
	//	PopupMenu  CbListboxTrace,  win = $sWNm, disable = TRUE
	// endif
End

Function		ConstructCbButtonCopy( sWNm, bDisable )
	string  	sWNm
	variable	bDisable
	Button	CbButtonCopy,  win = $sWNm, disable = bDisable, 	 size={ cXBUTTONSIZE,20},	proc=CbButtonCopy,  title="Copy"
	Button	CbButtonCopy,  win = $sWNm, pos={ cXLBTRACESSIZE, 2 }
End

Function		ConstructCbButtonInsert( sWNm, bDisable )
	string  	sWNm
	variable	bDisable
	Button	CbButtonInsert,       win = $sWNm, disable = bDisable,	size={cXBUTTONSIZE,20},	proc=CbButtonInsert,  title="Ins"
	Button	CbButtonInsert,       win = $sWNm, pos = { cXLBTRACESSIZE + 1 * ( cXBUTTONSIZE + cXBUTTONMARGIN ) , 2 }
End

Function		ConstructCbButtonDelete( sWNm, bDisable )
	string  	sWNm
 	variable	bDisable
	Button	CbButtonDelete,     win = $sWNm, disable = bDisable, 	size={ cXBUTTONSIZE,20 },	proc=CbButtonDelete,  title="Del"
	Button	CbButtonDelete,     win = $sWNm, pos={ cXLBTRACESSIZE + 2 * ( cXBUTTONSIZE + cXBUTTONMARGIN ) , 2 }
End

Function		ConstructCbCheckboxAuto( sWNm, bDisable, bAutoscl )
	string  	sWNm
 	variable	bDisable, bAutoscl 
	Checkbox	CbCheckboxAuto,  win = $sWNm, size={ cXBUTTONSIZE,20 },	proc=CbCheckboxAuto,  title="AS"
	Checkbox	CbCheckboxAuto,  win = $sWNm, pos={ cXLBTRACESSIZE + 3 * ( cXBUTTONSIZE + cXBUTTONMARGIN ) , 2 }
	Checkbox	CbCheckboxAuto,  win = $sWNm, help={"Automatical Scaling works only with Dac but not with Adc traces."}
	ShowHideCbCheckboxAuto( sWNm, bDisable, bAutoscl  )									// Enable or disable the control  and possibly adjust its value
End
Function		ShowHideCbCheckboxAuto( sWNm, bDisable, bAutoscl  )
//  Hide, gray or display (=enable)  the control   and   set its  state/value/limits  correctly  (even when hidden).
	string  	sWNm
 	variable	bDisable, bAutoscl  
	Checkbox	CbCheckboxAuto,  win = $sWNm, disable = bDisable, value = bAutoscl
End


Function		ConstructCbPopmenuColors( sWNm, bDisable, sRGB )
	string 	sWNm, sRGB
	variable	bDisable
	variable	rnRed, rnGreen, rnBlue
	ExtractColors( sRGB, rnRed, rnGreen, rnBlue )
	PopupMenu CbPopmenuColors,  win = $sWNm, size={ cXLBCOLORSIZE,16 },	proc=CbPopmenuColors,	title=""		
	PopupMenu CbPopmenuColors,  win = $sWNm, pos={ cXLBTRACESSIZE + 4 * ( cXBUTTONSIZE + cXBUTTONMARGIN ) , 2 }
	PopupMenu CbPopmenuColors,  win = $sWNm, mode=1, popColor = ( rnRed, rnGreen, rnBlue ), value = "*COLORPOP*"
	PopupMenu CbPopmenuColors,  win = $sWNm, help = {"If you have multiple traces in the windows, you must first select the trace to apply on, then the color."}
	PopupMenu CbPopmenuColors,  win = $sWNm, disable = bDisable
End


Function		ConstructCbListboxYZoom( sWNm, bDisable, YZoom )
	string 	sWNm
	variable	bDisable, YZoom
	PopupMenu CbListboxYZoom,   win = $sWNm, size = { 100, 20 }, 		proc=CbListboxYZoom,	title="yZm"	
	PopupMenu CbListboxYZoom,   win = $sWNm, pos = { cXLBTRACESSIZE + 4 * ( cXBUTTONSIZE + cXBUTTONMARGIN )+ cXLBCOLORSIZE - 44, 2 } 
	PopupMenu CbListboxYZoom ,  win = $sWNm, help = {"If you have multiple traces in the windows, you must first select the trace to apply on, then the Y zoom factor."}
	ShowHideCbListboxYZoom( sWNm, bDisable, YZoom )									// Enable or disable the control  and possibly adjust its value
End

Function		ShowHideCbListboxYZoom( sWNm, bDisable, YZoom )
//  Hide, gray or display (=enable)  the control   and   set its  state/value/limits  correctly  (even when hidden).
	string 	sWNm
	variable	bDisable, YZoom
	variable	n, nSelected, nItemCnt	= ItemsInList( ZoomValues_() )
	// Search the item in the list which corresponds to the desired value 'YZoom'
	for ( n = 0; n < nItemCnt; n += 1 )
		if ( str2num( StringFromList( n, ZoomValues_() ) ) == YZoom )	// compare numbers, the numbers as strings might be formatted in different ways ( trailing zeros...)
			break
		endif
	endfor
	if ( n == nItemCnt )
		n = 4			// the desired value could not be found in the list,  so we select arbitrarily  a zoom of 1  to be displayed  which is the  4. item  in the list
	endif
	PopupMenu CbListboxYZoom,   win = $sWNm, disable = bDisable,  mode = n+1,  value = ZoomValues_()	// n+1 sets the selected item in the listbox,  counting starts at 1
End

Function	/S	ZoomValues_()							// Igor does not allow this function to be static
	return	".1;.2;.5;1;2;5;10;20;50;100"
End	


Function		ConstructCbSliderYOfs( sWNm, bDisable, YOfs, Gain )
	string 	sWNm
	variable	bDisable, YOfs, Gain
	Slider 	CbSliderYOfs,   win = $sWNm,	proc=CbSliderYOfs 
	GetWindow $sWNm, wSize											// Get the window dimensions in points .
	variable 	RightPix	= ( V_right	-  V_left )	* screenresolution / kIGOR_POINTS72 	// Convert to pixels ( This has been tested for 1600x1200  AND  for  1280x1024 )
	variable 	BotPix	= ( V_bottom - V_top ) * screenresolution / kIGOR_POINTS72 
	// print  "\twindow dim in points:", V_left,  V_top,  V_right,  V_bottom , " -> RightPix:",  RightPix, BotPix

	if ( cbVERTICAL_SLIDER_YOFS )								// Vertical slider at the  right window border
		Slider 	CbSliderYOfs,   win = $sWNm, vert = 1, side = 2,	size={ 0, BotPix - 30 },  pos = { RightPix -76, 28 }
		//ControlInfo /W=$sWNm CbSliderYOfs
		// printf "\tControlInfo Slider  in '%s' \tleft:%d \twidth:%d \ttop:%d \theight:%d \r", sWNm,  V_left, V_width, V_top, V_height
	else														// Horizontal slider
		Slider 	CbSliderYOfs,   win = $sWNm, vert = 0, side = 1, 	size={200,0}, 	pos = { cXLBTRACESSIZE + 4 * ( cXBUTTONSIZE + cXBUTTONMARGIN )+ cXLBCOLORSIZE + 50, 2 } 
	endif
	ShowHideCbSliderYOfs( sWNm, bDisable, YOfs, Gain )							// Enable or disable the control  and possibly adjust its value
End

Function		ShowHideCbSliderYOfs( sWNm, bDisable, YOfs, Gain )
//  Hide, gray or display (=enable)  the control   and   set its  state/value/limits  correctly  (even when hidden).
	string 	sWNm
	variable	bDisable, YOfs, Gain
	if ( cbVERTICAL_SLIDER_YOFS )								// Vertical slider at the  right window border
		variable	ControlBarWidth 	=    bDisable == 1   ?	0  : 76		// only hide=1 sets width = 0 and makes the controlbar vanish, enable=0 and gray=2 display  the controlbar
		ControlBar /W = $sWNm  /R ControlBarWidth
	endif
	variable	DacRange		= 10								// + - Volt
	variable	YAxisWithoutZoom	= DacRange * 1000 / Gain 			
	// printf "\t\t\tShowHideCbSliderYOfs() \t'%s'\tDGn:\t%7.1lf\t-> Axis(without zoom):\t%7.1lf\tVal:\t%7.1lf\t  \r", sWNm, Gain, YAxisWithoutZoom, YOfs / Gain
	Slider	CbSliderYOfs,	win = $sWNm, 	disable = bDisable,	value = YOfs / Gain,	limits = { -YAxisWithoutZoom, YAxisWithoutZoom, 0 } 
End

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  CONTROLBARS  in  the  ACQUISITION  WINDOWS  :  THE  ACTION  PROCEDURES

Function		CbListboxTrace( ctrlName, popNum, popStr ) : PopupMenuControl
// executed when the user selected a trace from the listbox. Changes color and YZoom listboxes so that they contain the current values of the selected trace 
	string 	ctrlName, popStr
	variable	popNum
	string 	sWNm	= ActiveWnd()
	variable	w		= WndNr_( sWNm )
	variable	t		= popNum - 1								// popnum -1 because listbox selections start at 1  [wrong: t = ioChan(popStr )]
	string 	sCurves	= RetrieveCurves( w )							// the user selected trace ' t '  ...
	string 	sCurve	= StringFromList( t, sCurves, ksCURVSEP )			// ...so we extract the current values of trace  ' t ' ...	
	variable	nCurveCnt	= ItemsInList( sCurves, ksCURVSEP )	
	variable	rnRange, rnMode, rnInstance, rbAutoscl, rYOfs, rYZoom 
	string 		rsTNm, rsRGB
	stExtractCurve( sCurve, rsTNm, rnRange, rnMode, rnInstance, rbAutoscl, rYOfs, rYZoom, rsRGB )	// ...and pass color , YZoom , YOfs when constructing the controls to supply the correct defaults/start values 		
	printf "\t\t%s( %d, %s ) in  wnd:%2d \t-> selected t:%d ? %d (instance)\t-> converted to '%s'  '%s'  \tAS:%d   [%s]\r", ctrlName, popNum, popStr, w, t, rnInstance, rsTNm, stBuildMoRaName( rnRange, rnMode), rbAutoscl, sCurve 
	// printf "\tCbListboxTrace( %s, %d, %s ) in  wnd:%2d \t-> selected t:%d  \t-> converted to '%s' '%s'   \r", ctrlName, popNum, popStr, w, t, rsTNm, BuildMoRaNameI( rnRange, rnMode, rnInstance )

	ConstructCbPopmenuColors( sWNm, FALSE, rsRGB )					// FALSE : enable popup always

	nvar		bAcqControlbar	= root:uf:aco:disp:bAcqControlbar
	variable	bDisableCtrlAutoscl	= DisableCtrlAutoscl( rsTNm, bAcqControlbar, nCurveCnt ) 
	variable	bDisableCtrlZoom	= DisableCtrlZoom( rsTNm, bAcqControlbar, nCurveCnt, rbAutoscl ) 
	variable	bDisableCtrlOfs		= DisableCtrlOfs(     rsTNm, bAcqControlbar, nCurveCnt, rbAutoscl )

	ShowHideCbCheckboxAuto( sWNm, bDisableCtrlAutoscl, rbAutoscl  )		// Enable or disable the control  and possibly adjust its value
	ShowHideCbListboxYZoom( sWNm,  bDisableCtrlZoom, rYZoom )			// Enable or disable the control  and possibly adjust its value
	string  	sFolder	= ksfACO
	wave  /T	wIO		= $ksROOTUF_ + sFolder + ":ar:wIO"  								// This  'wIO'  is valid in FPulse ( Acquisition )
	variable	Gain		= GainByNmForDisplay_( wIO, rsTNm )
	ShowHideCbSliderYOfs( 	sWNm,   bDisableCtrlOfs, rYOfs, Gain )		// Enable or disable the control  and possibly adjust its value

	SetWndUsersTrace( w, t )										// we use a global variable to pass the trace to the color- and YZoom-Procs...
End

static Function	stIsDacTrace( sTNm )
// Returns whether the passed trace is of type  'Dac'  and not  e.g.  'Adc'  or  'PoN' 
	string 	sTNm
	return	( cmpstr( sTNm[ 0, 2 ], "Dac" ) == 0 )
End

static Function	stIsPoNTrace( sTNm )
// Returns whether the passed trace is of type  'PoN'  and not  e.g.  'Adc'  or  'Dac' 
	string 	sTNm
	return	( cmpstr( sTNm[ 0, 2 ], "PoN" ) == 0 )
End


Function		CbButtonCopy( ctrlName ) : ButtonControl
// Executed when the user pressed the 'Copy' button : we store the trace to be copied globally using SetCopyCurve( sCurve )
	string 	ctrlName
	string 	sWNm	= ActiveWnd()
	variable	w		= ActiveWndNr()
	string 	sCurve	= StringFromList( WndUsersTrace( w ), RetrieveCurves( w ), ksCURVSEP )		
	SetCopyCurve( sCurve )
	printf "\t\t%s()  W:%2d   copying trace \t%d : '%s'  \r", ctrlName, w, WndUsersTrace( w ), CopyCurve()
End

Function		NextFreeInstance( sExistingCurves, sTNm, nRange, nMode )
	string 	sExistingCurves, sTNm
	variable	nRange, nMode
	string 	sTrace
	variable	i
	for ( i = 0; i < 99; i += 1 )										// todo: avoid arbitrary limit		
		sTrace	= sTNm + stBuildMoRaNameInstance( nRange, nMode, i )	// e.g. 'Adc0 SM  '   or  ' Dac2 FS 1'
		if ( WhichListItem( sTrace, sExistingCurves ) == kNOTFOUND )
			break
		endif 
	endfor
	return  i
End

Function		CbButtonInsert( ctrlName ) : ButtonControl
// Executed when the user pressed the 'Insert' button : we retrieve the trace to be copied from global CopyCurve()...
	string 	ctrlName
	variable	rnRange, rnMode, rnInstance, rAuto, rYOfs, rYZoom, t 
	variable	rnRed, rnGreen, rnBlue 
	string 	sTNL, sWindowTrace
	string 	rsTNm, rsRGB
	string 	sWNm		= ActiveWnd()			// the  name  of the window where the user clicked 'Insert'
	variable	w			= ActiveWndNr()		// the number of the window where the user clicked 'Insert'
	string 	sCurves		= RetrieveCurves( w )		// the string  holding the complete information about all traces in this window which is retrieved from TWA	
	variable	nWUT		= WndUsersTrace( w )

	string 	sExistingCurves	= ActiveTNL1()			// the list holding the 'short form' name of all traces in this window which is retrieved from TWA e.g  'Adc0 SC  ;Adc0 SC 1;Dac1 FM  '
	string 	sCopyCurve	= CopyCurve()			// the complete information about the currently selected trace (=previously selected in this or another wnd by having clicked 'Copy') 

	stExtractCurve( sCopyCurve, rsTNm, rnRange, rnMode, rnInstance, rAuto, rYOfs, rYZoom, rsRGB )

	// Get the trace instance as computed by FPulse
	printf "\t\t%s() W:%2d\t%d :'%s' \t( original  is \tinstance %d)\t   \r", ctrlName, w, nWUT, sCopyCurve, rnInstance
	rnInstance		= NextFreeInstance( sExistingCurves, rsTNm, rnRange, rnMode )					// the basic trace name is the same but the instances may differ between source and target graph 
	sCopyCurve	= BuildCurve( rsTNm, rnRange, rnMode, rnInstance, rAuto, rYOfs, rYZoom, rsRGB )	// e.g. 'Adc0;SM;20;mV;(40000,0,40000);0;1'	
	printf "\t\t%s() W:%2d\t%d :'%s' \t(converted to\tinstance %d)\tand adding to existing\t'%s' \r", ctrlName, w, nWUT, sCopyCurve, rnInstance, sExistingCurves

	sCurves	= AppendListItem( sCopyCurve, sCurves, ksCURVSEP )
	StoreCurves(  w, sCurves )	
	string  	sFolder	= ksfACO
	wave  /T	wIO		= $ksROOTUF_ + sFolder + ":ar:wIO" 						 // This  'wIO'  is valid in FPulse ( Acquisition )
	CreateControlBarInAcqWnd( wIO, sWNm )  

	// The trace has now been added to TWA internally and will be shown during the next acquisition, but we want to immediately give some feedback to the user ...
	//...to indicate that the trace insertion has indeed been accepted  so we go on and add the trace (or all instances of this trace) to the insertion window :
	nvar		gPrevBlk	= root:uf:aco:disp:gPrevBlk; gPrevBlk	= -1	// this enforces ConstructYAxis()
	wave  	wG		= $ksROOTUF_ + sFolder + ":keep:wG"  								// This  'wG'	is valid in FPulse ( Acquisition )
	wave  /T	wIO		= $ksROOTUF_ + sFolder + ":ar:wIO"  								// This  'wIO'	is valid in FPulse ( Acquisition )
	wave  	wFix		= $ksROOTUF_ + sFolder + ":ar:wFix"  								// This  'wFix'	is valid in FPulse ( Acquisition )
	DisplayOffLine( sFolder, wG, wIO, wFix, w, w )
End


Function		CbButtonDelete( ctrlName ) : ButtonControl
// executed when the user pressed the 'Del' button.
	string 	ctrlName
	string 	sWNm	= ActiveWnd()
	variable	w		= ActiveWndNr()
	// First we remove the trace permanently from TWA (which does not automatically remove it from screen) 
	string 	sCurves	= RetrieveCurves( w )
	variable	nWUT	= WndUsersTrace( w )
	string 	sCurve	= StringFromList( nWUT, sCurves, ksCURVSEP )		
	variable	rnRange, rnMode, rnInstance, rAuto, rYOfs, rYZoom 
	string 	rsTNm, rsRGB
	stExtractCurve( sCurve, rsTNm, rnRange, rnMode, rnInstance, rAuto, rYOfs, rYZoom, rsRGB )	// get all traces from this window...
	printf "\t\t%s()\t%s   erasing trace %d : '%s'  instance: %d \r", ctrlName, sWNm, nWUT, sCurve, rnInstance
	sCurves	= RemoveListItem( nWUT, sCurves, ksCURVSEP )			// ...remove the trace permanently from TWA 	
	// printf "\t\t%s()\t%s   leaves %d traces: '%s'  \r", ctrlName, sWNm, ItemsInList( sCurves, ksCURVSEP ), sCurves
	StoreCurves(  w, sCurves )										// restore the rest of the traces in TWA

	// Now shrink the traces listbox  or possibly hide the whole controlbar and all controls if the last trace has been removed
	string  	sFolder	= ksfACO
	wave  /T	wIO		= $ksROOTUF_ + sFolder + ":ar:wIO"  								// This  'wIO'  is valid in FPulse ( Acquisition )
	CreateControlBarInAcqWnd( wIO, sWNm ) 

	// The trace has now been removed from TWA internally and will no longer be shown during the next acquisition, but we want to immediately give some feedback to the
	//... user so he sees his trace deletion has been accepted , so we go on and delete the trace (or all instances of this trace) in the existing window :
	nvar		gPrevBlk	= root:uf:aco:disp:gPrevBlk; gPrevBlk	= -1			// this enforces ConstructYAxis()
	wave  	wG		= $ksROOTUF_ + sFolder + ":keep:wG"  								// This  'wG'	is valid in FPulse ( Acquisition )
	wave  /T	wIO		= $ksROOTUF_ + sFolder + ":ar:wIO"  								// This  'wIO'	is valid in FPulse ( Acquisition )
	wave  	wFix		= $ksROOTUF_ + sFolder + ":ar:wFix"  								// This  'wFix'	is valid in FPulse ( Acquisition )
	DisplayOffLine( sFolder, wG, wIO, wFix, w, w )
End


Function		CbCheckboxAuto( ctrlName, bAutoscl ) : CheckboxControl
// Executed only when the user changes the 'AutoScale' checkbox : If it is turned on, then YZoom and YOfs values are computed so that the currently displayed trace is fitted to the window.
	string 	ctrlName
	variable	bAutoscl
	string 	sWNm	= ActiveWnd()
	variable	w		= ActiveWndNr()

	string 	sCurves	= RetrieveCurves( w )
	variable	nCurveCnt	= ItemsInList( sCurves, ksCURVSEP )
	variable	nWUT	= WndUsersTrace( w )
	string 	sCurve	= StringFromList( nWUT, sCurves, ksCURVSEP )		
	variable	rnRange, rnMode, rnInstance, rbAuto, rYOfs, rYZoom 
	string 	rsTNm, rsRGB
	variable	Gain	

	stExtractCurve( sCurve, rsTNm, rnRange, rnMode, rnInstance, rbAuto, rYOfs, rYZoom, rsRGB )	// get all traces from this window...

	string  	sFolder	= ksfACO
	wave  /T	wIO		= $ksROOTUF_ + sFolder + ":ar:wIO"  								// This  'wIO'  is valid in FPulse ( Acquisition )
	Gain	= GainByNmForDisplay_( wIO, rsTNm )
	// printf "\t\t%s()\t%s   nWUT %d : %s \tAutoscale was: %d , now: %d  \tYzoom:\t%7.2lf\tYofs:\t%7.1lf\tGain:\t%7.1lf\t   \r", ctrlName, sWNm, nWUT, pd(sCurve,45), rbAuto, bAutoscl, rYZoom, rYOfs, Gain
// 060511c
	string  	sTNmPostFix= stBuildMoRaName( rnRange, rnMode ) + sMORAPOINTSEP		// e.g.Adc0 + SM + _
	stAutoscaleZoomAndOfs( sWNm,  rsTNm+sTNmPostFix, bAutoscl, rYOfs, rYZoom, Gain )
//	stAutoscaleZoomAndOfs( sWNm,  rsTNm,			bAutoscl, rYOfs, rYZoom, Gain )

	sCurve	= BuildCurve( rsTNm, rnRange, rnMode, rnInstance, bAutoScl, rYOfs, rYZoom, rsRGB)// the new curve now containing the changed 'AutoScale' .. 
	sCurves	= RemoveListItem( nWUT, sCurves, ksCURVSEP )									//..replaces... 	
	sCurves	= AddListItem( sCurve, sCurves, ksCURVSEP, nWUT )									// ..the old curve
	StoreCurves(  w, sCurves )

	nvar		bAcqControlbar	= root:uf:aco:disp:bAcqControlbar
	variable	bDisableCtrlZoom	= DisableCtrlZoom(   rsTNm, bAcqControlbar, nCurveCnt, bAutoscl ) 		// Determine whether the control must be enabled or disabled
	ShowHideCbListboxYZoom( sWNm,  bDisableCtrlZoom, rYZoom )									// Enable or disable the control  and possibly adjust its value

	variable	bDisableCtrlOfs		= DisableCtrlOfs(      rsTNm, bAcqControlbar, nCurveCnt, bAutoscl )		// Determine whether the control must be enabled or disabled
	ShowHideCbSliderYOfs( sWNm,  bDisableCtrlOfs, rYOfs, Gain )									// Enable or disable the control  and possibly adjust its value

	// The Dac trace has now been rescaled in TWA internally and will  be shown with new scaling during the next acquisition, but we want to immediately give some feedback to the
	//... user so he sees his rescaling has been accepted , so we go on redraw and all windows
	wave  	wG		= $ksROOTUF_ + sFolder + ":keep:wG"  								// This  'wG'	is valid in FPulse ( Acquisition )
	wave  /T	wIO		= $ksROOTUF_ + sFolder + ":ar:wIO"  								// This  'wIO'	is valid in FPulse ( Acquisition )
	wave  	wFix		= $ksROOTUF_ + sFolder + ":ar:wFix"  								// This  'wFix'	is valid in FPulse ( Acquisition )
	DisplayOffLine( sFolder, wG, wIO, wFix, w, w )
End


static Function	stAutoscaleZoomAndOfs( sWNm, rsTNm, bAutoscl, rYOfs, rYZoom, Gain )
// 040109	 Adjust   YZoom  and  YOffset  values  depending on the state of the  'Autoscale'  checkbox.  
// Also store  YZoom  and  YOfs  in TWA  so that the next redrawing of the graph will reflect the changed values.
	string 	sWNm, rsTNm
	variable	bAutoscl, Gain 
	variable	&rYZoom, &rYOfs 
	string 	sZoomLBName		= "CbListboxYZoom"
	variable	YAxis			= 0
	variable	DacRange 		= 10						// + - Volt

	if ( bAutoscl )										// The checkbox  'Autoscale Y axis'  has been turned  ON :
// 060511c
		wave 		wData	= TraceNameToWaveRef( "", rsTNm )
		waveStats	/Q	wData							// 	...We compute the maximum/mimimum Dac values from the stimulus and set the zoom factor... 
//		waveStats	/Q	$rsTNm							// 	...We compute the maximum/mimimum Dac values from the stimulus and set the zoom factor... 

		if ( cbAUTOSCALE_SYMMETRIC )					// 		Use symmetrical axes, the length is the longer of both. The window is filled to 90% . 
			 YAxis	= max( abs( V_max ), abs( V_min ) ) / .9	
			 rYOfs	= 0
		else											// 		The length of pos. and neg. half axis is adjusted separately.  The window is filled to 90% . 
			YAxis	= (  V_max   -  V_min  ) 		 / 2 / .9 
			rYOfs	= (  V_max  +  V_min  ) / Gain	 / 2  
		endif		

		rYZoom	= DacRange * 1000 / YAxis				
	else												//  The checkbox  'Autoscale Y axis'  has been turned  OFF : So we restore and use the user supplied zoom factor setting from the listbox
													//  We do not restore the  YOfs from slider because 	1. the user can very easily  (re)adjust to a new position   
													//										2. the YOfs is at the optimum position as it has just been autoscaled  
													//										3. the YOfs prior to AutoScaling would have had to be stored to be able to retrieve it which is not done in this version 
		ControlInfo /W=$sWNm $sZoomLBName				// Get the controls current value by reading S_Value  which is set by  ControlInfo
		rYZoom	= str2num( S_Value )
	endif
	// printf "\t\t\tAutoscaleZoomAndOfs( '%s' \t'%s'\tpts:\t%8d\t bAutoscl: %s )\tVmax:\t%7.2lf\tVmin:\t%7.2lf\tYaxis:\t%7.1lf\tYzoom:\t%7.2lf\tYofs:\t%7.1lf\tGain:\t%7.1lf\t  \r",  sWNm, rsTNm, numPnts( $rsTNm ), SelectString( bAutoscl, "OFF" , "ON" ), V_max, V_min, YAxis, rYZoom, rYOfs, Gain
End


Function 		CbPopmenuColors( ctrlName, popNum, sPop ) : PopupMenuControl
	string 	ctrlName, sPop
	variable	popNum
	string 	sWNm	= ActiveWnd()
	//ControlInfo $ctrlName										// Another way to get rgb: sets V_Red, V_Green, V_Blue
	// printf "\t\tCbPopmenuColors( %s, %d, popstr:%s [~%s] )  ControlInfo returned (%d,%d,%d)\r", ctrlName, popNum, popStr, sWNm, V_Red, V_Green, V_Blue
	variable	w		= WndNr_( sWNm )
	variable	nWUT	= WndUsersTrace( w )
	ReplaceOneParameter( w, nWUT, csRGB, sPop )

	// The new colors have now been set and will be effective during the next acquisition, but we want to immediately give some feedback to the..
	// ..user so he sees his color change has been accepted, so we go on and colorize the trace (or all instances of this trace) in the existing window :
	string  	sFolder	= ksfACO
	wave  	wG		= $ksROOTUF_ + sFolder + ":keep:wG"  								// This  'wG'	is valid in FPulse ( Acquisition )
	wave  /T	wIO		= $ksROOTUF_ + sFolder + ":ar:wIO"  								// This  'wIO'	is valid in FPulse ( Acquisition )
	wave  	wFix		= $ksROOTUF_ + sFolder + ":ar:wFix"  								// This  'wFix'	is valid in FPulse ( Acquisition )
	DisplayOffLine( sFolder, wG, wIO, wFix, w, w )
End

Function		 CbListboxYZoom( ctrlName, popNum, sPop ) : PopupMenuControl
// Action proc executed when the user selects a zoom value from the listbox.  Update  TWA  and  change axis and traces immediately to give some feedback.
	string 	ctrlName, sPop
	variable	popNum
	string 	sWNm	= ActiveWnd()

	ControlInfo $ctrlName											// Another way to get S_Value (set by  ControlInfo)
	// printf "\t\t%s(..%2d,\tsPop:%s\t[~%s] )  ControlInfo returned %g   '%s'\r", ctrlName, popNum, pd(sPop,5), sWNm, V_Value, S_Value
	variable	w		= WndNr_( sWNm )
	variable	nWUT	= WndUsersTrace( w )
	ReplaceOneParameter( w, nWUT, cYZOOM, sPop )

	// The new YZoom has now been set and will be effective during the next acquisition, but we want to immediately give some feedback to the..
	// ..user so he sees his YZoom  change has been accepted , so we go on and change the Y Axis range in the existing window :
	string  	sFolder	= ksfACO
	wave  	wG		= $ksROOTUF_ + sFolder + ":keep:wG"  								// This  'wG'	is valid in FPulse ( Acquisition )
	wave  /T	wIO		= $ksROOTUF_ + sFolder + ":ar:wIO"  								// This  'wIO'	is valid in FPulse ( Acquisition )
	wave  	wFix		= $ksROOTUF_ + sFolder + ":ar:wFix"  								// This  'wFix'	is valid in FPulse ( Acquisition )
	DisplayOffLine( sFolder, wG, wIO, wFix, w, w )
End

Function		CbSliderYOfs( sControlNm, value, event ) : SliderControl
	string 	sControlNm			// name of this slider control
	variable	value				// value of slider
	variable	event				// bit field: bit 0: value set; 1: mouse down, 2: mouse up, 3: mouse moved
	// printf "\tSlider '%s'  gives value:%d  event:%d  \r", sControlNm, value, event
	string 	sWNm	= ActiveWnd()
	variable	w		= WndNr_( sWNm )
	variable	nWUT	= WndUsersTrace( w )

	ReplaceOneParameter( w, nWUT, cYOFS, num2str( value ) )				//

	// The new YOffset has now been set and will be effective during the next acquisition, but we want to immediately give some feedback to the..
	// ..user so he sees his YOffset change has been accepted , so we go on and change the Yoffset in the existing window :
	//nvar		gPrevBlk	= root:uf:aco:disp:gPrevBlk;	gPrevBlk			= -1
	string  	sFolder	= ksfACO
	wave  	wG		= $ksROOTUF_ + sFolder + ":keep:wG"  								// This  'wG'	is valid in FPulse ( Acquisition )
	wave  /T	wIO		= $ksROOTUF_ + sFolder + ":ar:wIO"  								// This  'wIO'	is valid in FPulse ( Acquisition )
	wave  	wFix		= $ksROOTUF_ + sFolder + ":ar:wFix"  								// This  'wFix'	is valid in FPulse ( Acquisition )
	DisplayOffLine( sFolder, wG, wIO, wFix, w, w )
	return 0						// other return values reserved
End


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  CONTROLBARS  in  the  ACQUISITION  WINDOWS : LITTLE  HELPERS

Function  /S	GetWindowTNL( sWndNm, nMode )
// nMode = 0 : returns a list of all traces contained in the given window e.g. 'Adc2,Dac0,Adc1..'
// nMode = 1 :  returns a list of all traces contained in the given window with Mode/Range extension and with instance  e.g. 'Adc2 SM  ,Dac0 FS 1,Adc1 RS 2'  with spaces for improved readability
 	string 	sWndNm
 	variable	nMode
	variable	w = WndNr_( sWndNm )
	string 	sTNL = ""
	string 	sCurve, sCurves	= RetrieveCurves( w )
	variable	ioch, ioCnt		= ItemsInList( sCurves, ksCURVSEP )
	variable	rnRange, rnMode, rnInstance, rAuto, rYOfs, rYZoom
	string 	sTNm, rsRGB
	for ( ioch = 0; ioch < ioCnt; ioch += 1 )
		sCurve	= StringFromList( ioch, sCurves, ksCURVSEP )
		stExtractCurve( sCurve, sTNm, rnRange, rnMode, rnInstance, rAuto, rYOfs, rYZoom, rsRGB )		// parameters are changed
		if ( nMode == 1 )
			sTNm	+= stBuildMoRaNameInstance( rnRange, rnMode, rnInstance ) 				// 040107
		endif
		sTNL	= AddListItem( sTNm, sTNL, ";", Inf )
		// printf "\t\tGetWindowTNL( %s, mode:%d ) : '%s'  \t-> '%s' \r", sWndNm, bMode, sTNm, sTNL
	endfor
	// printf "\t\t\tGetWindowTNL( %s, mode:%d )\tfrom sCurves\t'%s'  \tsCurves: '%s' \r", sWndNm, nMode, sTNL, sCurves[0,200]
	// printf "\t\t\tGetWindowTNL( %s, mode:%d )\tfrom IGOR :\t'%s'  \t \r", sWndNm, nMode, TraceNameList( sWndNm, ";", 1 )	// 031224
	return	sTNL
End

Function		SetActiveWnd( sWnd )
	string 	sWnd
	svar		gsLbActiveWnd	= root:uf:aco:disp:gsLbActiveWnd
	gsLbActiveWnd	= sWnd
End

Function	/S	ActiveWnd()
	svar		gsLbActiveWnd	= root:uf:aco:disp:gsLbActiveWnd
 	return	gsLbActiveWnd
End
Function	/S	ActiveTNL1()
 	return 	( GetWindowTNL( ActiveWnd(), 1 ) )		// 040103 include instance number 0 1 2 ... but only for traces listbox, not for trace name
End

Function		ActiveWndNr()
	return	WndNr_( ActiveWnd() )
End


Function	/S	SetCopyCurve( sCopyCurve )
// Needed to transfer information about the trace to be copied between graphs from the source traces listbox to the target traces listbox 
	string 	sCopyCurve
	svar		gsCopyCurve	= root:uf:aco:disp:gsCopyCurve
	gsCopyCurve	= sCopyCurve
End
Function	/S	CopyCurve()
	svar		gsCopyCurve	= root:uf:aco:disp:gsCopyCurve
	return	gsCopyCurve
End


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////    DISPLAY  DURING  ACQUISITION  DIALOG BOX
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//   MODE  and  RANGE  ( in 2 variables )
constant			cCURRENT 		= 0,		cMANYSUPIMP = 1
// 2009-12-09 derived control name too long
static  strconstant	sMODETEXT		= "Current;SuprImp;"
static  strconstant	sMODENM		= "C;M"
// 2009-12-09 derived control name too longod
//static  strconstant	sMODEFOLDER	= "root:uf:aco:disp:Mod"
static  strconstant	sMODEFOLDER	= "root:uf:aco:disp:M"

constant			cSWEEP 			= 0,	cFRAME = 1,  cPRIM = 2,	cRESULT = 3
static  strconstant	sRANGETEXT		= "Sweeps;Frames;Primary;Result"
static  strconstant	sRANGENM		= "S;F;P;R"
// 2009-12-09 derived control name too long
//static  strconstant	sRANGEFOLDER	= "root:uf:aco:disp:cbRng"
static  strconstant	sRANGEFOLDER	= "root:uf:aco:disp:R"

static  strconstant	sRADIOhTEXT		= "RadH0;RadH1;RadH2"		// do not use  _
static  strconstant	sRADIOhFOLDER	= "root:uf:aco:disp:RadH"			// do not use  _
static  strconstant	sRADIOvTEXT		= "RadA;RadB;RadC"		// do not use  _
static  strconstant	sRADIOvFOLDER	= "root:uf:aco:disp:RadV"			// do not use  _

Function  		DisplayOptionsAcqWindows()
	string  	sFolder		= ksfACO
	string  	sPnOptions	= ":dlg:tPnAcqWnd"
	string  	sWin			= "PnAcqWin" 
	InitPanelDisplayOptionsAcq( sFolder, sPnOptions )				// constructs the text wave  'tPnAcqWn'  defining the panel controls
	ConstructOrDisplayPanel(  sWin , "Disp Acquisition" , sFolder, sPnOptions,  98, 80 )	// same params as in  UpdatePanel()
	PnLstPansNbsAdd( ksfACO,  sWin )
End
 
Function		InitPanelDisplayOptionsAcq( sFolder, sPnOptions )
	string  	sFolder, sPnOptions
	string		sPanelWvNm = 	  ksROOTUF_ + sFolder + sPnOptions
	wave  /T	wIO		     = 	$ksROOTUF_ + sFolder + ":ar:wIO"		// This  'wIO'  is valid in FPulse ( Acquisition )
	variable	n = -1, nItems = 100							// many more than visible because of TabControl 	// separator needs FLEN entry
	make /O /T /N=(nItems)	$sPanelWvNm
	wave  /T	tPn		=	$sPanelWvNm
	string		sTabControlEntries	= ""						// list with all control information. Separators  are   | ~~~;;;~ | ~~~;;;~ | 

	//   TABBED  PANEL ..........with 2 controls...............
//	n += 1;		tPn[ n ] 	=	"PN_SEPAR"
	sTabControlEntries	= ""
	sTabControlEntries	+=  "PN_CHKBOXT ~ "		+ num2str( ItemsInList(sRANGETEXT) ) 	+ "~ Range~" 	+ sRANGEFOLDER 	+ "~" + sRANGETEXT	+ ksTAB_V_SEP	// horizontal checkboxes
	sTabControlEntries	+=  "PN_CHKBOXT ~ " 	+ num2str( ItemsInList( sMODETEXT ) ) 	+ "~ Mode~" 	+ sMODEFOLDER 	+ "~" + sMODETEXT  	+ ksTAB_V_SEP	// horizontal checkboxes
	//sTabControlEntries	+=  "PN_CHKBOXT ~ " + num2str( 		kVERT			) 	+ "~ Range~" 	+ sRANGEFOLDER 	+ "~" + sRANGETEXT	+ ksTAB_V_SEP	//  vertical   checkboxes
	//sTabControlEntries	+=  "PN_CHKBOXT ~ " + num2str( 		kVERT			) 	+ "~ Mode~" 	+ sMODEFOLDER 	+ "~" + sMODETEXT  	+ ksTAB_V_SEP	//  vertical   checkboxes
	//sTabControlEntries	+=  "PN_RADIOT ~ " 	+ num2str( ItemsInList( sRADIOhTEXT ) ) + "~ RadioH~" 	+ sRADIOhFOLDER	+ "~" + sRADIOhTEXT  + ksTAB_V_SEP	// horizontal Radio buttons
	//sTabControlEntries	+=  "PN_RADIOT ~ " 	+ num2str(		kVERT			) 	+ "~ RadioV~" 	+ sRADIOvFOLDER	+ "~" + sRADIOvTEXT  + ksTAB_V_SEP	//   vertical   Radio buttons

// 041215a
//	n = PnControlTab(	tPn, n, ON, "tcSrc", "", lstTitleTraces( wIO ), sTabControlEntries, sFolder )					// the 2. string is the title which may be empty
	n = PnControlTab(	tPn, n, OFF, "tcSrc", "", lstTitleTraces( wIO ), sTabControlEntries, sFolder )					// the 2. string is the title which may be empty

//	sTabControlEntries	= ""
//	sTabControlEntries	+=  "PN_CHKBOXT~" 	+ num2str( 	kVERT			) 	+ "~ Range~" 	+ sRANGEFOLDER 	+ "1" +"~" + sRANGETEXT + ksTAB_V_SEP	//  vertical    checkboxes
//	sTabControlEntries	+=  "PN_CHKBOXT~" 	+ num2str( ItemsInList( sMODETEXT ) )	+ "~ Mode~" 	+ sMODEFOLDER 	+ "1" +"~" + sMODETEXT	  + ksTAB_V_SEP	// horizontal checkboxes
//	n = PnControlTab(	tPn, n, ON, "tcSrc3", "Source Channels", lstTitleTraces(), sTabControlEntries, sFolder )	// the 2. string is the title which may be empty
	
	n += 1;		tPn[ n ] 	=	"PN_SEPAR"
	n += 1;		tPn[ n ] 	=	"PN_BUTTON;	buDispWARectAuto	;automatic;  |	PN_BUTTON	;buDispWARectUsSpec ;user specific;	| PN_BUTTON;	buSaveDisplayConfig	;Save disp cfg"

	//n += 1;		tPn[ n ] 	=	"PN_BUTTON;	buEraseTraceInWnd	;Erase trace in window"
	n += 1;		tPn[ n ] 	=	"PN_CHKBOX;	root:uf:aco:disp:gbDispAllDataLagging;Display all data when lagging"
	n += 1;		tPn[ n ] 	=	"PN_CHKBOX;	root:uf:aco:disp:gbHighResolution	;High Resolution during acquis"
	n += 1;		tPn[ n ] 	=	"PN_CHKBOX;	root:uf:aco:disp:bAcqControlbar	;Trace / Window Controlbar"	
	n += 1;		tPn[ n ] 	=	"PN_BUTTON;	buPreparePrint				;Prepare printing Acq wnd"				// 

	redimension  /N = (n+1)	tPn	
End


// Action procedure for  TabControl , currently not needed
Function		tcSrc( sControlNm, nSelectedTab )	
	string  	sControlNm
	variable	nSelectedTab
	// printf "\t\ttcSrc( TabControl   '%s'   SelectedTab:%2d )  \t->\tsSelecting TabControl \r",   sControlNm, nSelectedTab
	return 0
End

Function		root_uf_aco_disp_R( sControlNm, bValue )					// name is derived from  sRANGEFOLDER 
// Sample  action procedure  for 2dimensional   PnControl()  with  CheckBoxes 
// MUST HAVE SAME NAME AS VARIABLE. NAME MUST NOT BE MUCH LONGER !
// Sample : sControlNm  'root_uf_aco_disp_R_Adc1_Frames'  ,    boolean variable name : 'root:uf:aco:disp:R:Adc1_Frames'  , 	sOLANm: 'Adc1'  ,  sRng: 'Frames'
	string  	sControlNm
	variable	bValue
	string  	rsFolderVarNmBase, rsSource, rsRng

	 // printf "\tProc TabControl CHKBOX  root_uf_aco_disp_R(\tctrlNm: \t%s\tbValue:%d )\r", pd(sControlNm,27), bValue 

	// This is just sample code to be commented out...
	 ChkBoxVarNmExtractDim2( sControlNm, rsFolderVarNmBase, rsSource, rsRng )
	 variable	val	=  ChkBoxValDim2( sControlNm )
	 // printf "\tProc CHKBOX root_uf_aco_disp_R(\tctrlNm: \t%s\tbVal:%d )    \t\t\t\tsSource:\t%s\tRng:\t'%s'   val:%d \r", pd(sControlNm,27), bValue, pd(rsSource,12), rsRng, val 
	// ...this is just sample code to be commented  out .

	TrMoRa( sControlNm, bValue )
End


Function		root_uf_aco_disp_Mod( sControlNm, bValue )					// name is derived from  sRANGEFOLDER 
// Sample  action procedure  for 2dimensional   PnControl()  with  CheckBoxes 
// MUST HAVE SAME NAME AS VARIABLE. NAME MUST NOT BE MUCH LONGER !
// Sample : sControlNm  'root_uf_aco_disp_Mod_Adc1_Frames'  ,    boolean variable name : 'root:uf:aco:disp:Mod:Adc1_Current'  , 	sOLANm: 'Adc1'  ,  sMode: 'Current'
	string  	sControlNm
	variable	bValue
	string  	rsFolderVarNmBase, rsSource, rsMode

	// This is just sample code to be commented out...
	ChkBoxVarNmExtractDim2( sControlNm, rsFolderVarNmBase, rsSource, rsMode )
	 variable   val	=  ChkBoxValDim2( sControlNm )
	printf "\tProc CHKBOX root_uf_aco_disp_Mod(\tctrlNm: \t%s\tbVal:%d )    \t\t\t\tsSource:\t%s\tMode:\t'%s'   val:%d \r", pd(sControlNm,27), bValue, pd(rsSource,12), rsMode, val 
	// ...this is just sample code to be commented  out .

	TrMoRa( sControlNm, bValue )
End


Function		root_uf_aco_disp_radH( sControlNm, bValue )
// Sample  action procedure  for 2dimensional   PnControl()  with  RadioButtons 
// MUST HAVE SAME NAME AS VARIABLE. NAME MUST NOT BE MUCH LONGER !
	string  	sControlNm
	variable	bValue
	string  	rsFolderVarNmBase, rsSource, rsRng
	 // printf "\t\tProc TabControl RADIO H  root_uf_aco_disp_radH(\tctrlNm: \t%s\tbValue:%d )\r", pd(sControlNm,27), bValue 

	// This is just sample code to be commented out...
	// ChkBoxVarNmExtractDim2( sControlNm, rsFolderVarNmBase, rsSource, rsRng )
	 // variable	val	=  ChkBoxValDim2( sControlNm )
	 // printf "\tProc CHKBOX root_uf_aco_disp_R(\tctrlNm: \t%s\tbVal:%d )    \t\t\t\tsSource:\t%s\tRng:\t'%s'   val:%d \r", pd(sControlNm,27), bValue, pd(rsSource,12), rsRng, val 
	// ...this is just sample code to be commented  out .
End

Function		root_uf_aco_disp_radV( sControlNm, bValue )
// Sample  action procedure  for 2dimensional   PnControl()  with  RadioButtons 
// MUST HAVE SAME NAME AS VARIABLE. NAME MUST NOT BE MUCH LONGER !
	string  	sControlNm
	variable	bValue
	string  	rsFolderVarNmBase, rsSource, rsRng
	 // printf "\t\tProc TabControl RADIO V  root_uf_aco_disp_radV(\tctrlNm: \t%s\tbValue:%d )\r", pd(sControlNm,27), bValue 
	// This is just sample code to be commented out...
	// ChkBoxVarNmExtractDim2( sControlNm, rsFolderVarNmBase, rsSource, rsRng )
	 // variable	val	=  ChkBoxValDim2( sControlNm )
	 // printf "\tProc CHKBOX root_uf_aco_disp_R(\tctrlNm: \t%s\tbVal:%d )    \t\t\t\tsSource:\t%s\tRng:\t'%s'   val:%d \r", pd(sControlNm,27), bValue, pd(rsSource,12), rsRng, val 
	// ...this is just sample code to be commented  out .
End


Function		buDispWARectAuto( ctrlName ) : ButtonControl
	string 	ctrlName
	TrMoRa( "ctrlName", 123 )
End

Function		buDispWARectUsSpec( ctrlName ) : ButtonControl
	string 	ctrlName
	svar		gsScriptPath= root:uf:aco:script:gsScriptPath
	string  	sFolder	= ksfACO
	LoadDisplayCfg_( sFolder,  gsScriptPath )

End

Function		buSaveDisplayConfig( ctrlName ) : ButtonControl
	string 	ctrlName		
	 // printf "\tSaveDisplayCfg(%s)  \r", ctrlName 
	SaveDispCfg()
End

//Function		buEraseTraceInWnd( ctrlName ) : ButtonControl
//	string 	ctrlName		
//	string 	sTNL	= ActiveTNL1()
//	 printf "\tEraseTraceInWnd(%s)  '%s' \r", ctrlName, sTNL 
//End

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  THE  TRACE  CHECKBOXES  APPEARING  IN  THE  PANEL  DEPEND  ON  THE  ENTRIES  IN  THE  SCRIPT

Function	/S	lstTitleTraces( wIO )
	wave  /T	wIO
	string 	sList = ""
	string 	sTrace, sFolder	= "root:uf:aco:disp:"
	variable	nIO, c, cCnt
	for ( nIO = 0; nIO < kIO_MAX; nIO += 1 )				// for all   Comp IO types  e.g. Pon, Sum, Aver
		cCnt	= ioUse( wIO, nIO )
		for ( c = 0; c < cCnt; c += 1 )
			sTrace	= ios( wIO, nIO, c, cIONM ) 		
			sList	= AddListItem( sTrace, sList, ";", Inf )
		endfor												
	endfor												
	
	// printf "\tlstTitleTraces()   items:%d    \tsTitleList='%s' \r", ItemsInList( sList ), sList	
	return	sList
End


Function		TrMoRa( sControlNm, bValue )
// update the trace-window-array according to the user settings in the panel
	string  	sControlNm
	variable	bValue
	// printf "\t\tTrMoRa( '%s', %d ) \r",  sControlNm, bValue
	string  	sFolder	= ksfACO
	wave  	wG		= $ksROOTUF_ + sFolder + ":keep:wG"  								// This  'wG'	is valid in FPulse ( Acquisition )
	wave  /T	wIO		= $ksROOTUF_ + sFolder + ":ar:wIO"  								// This  'wIO'	is valid in FPulse ( Acquisition )
	wave  	wFix		= $ksROOTUF_ + sFolder + ":ar:wFix"  								// This  'wFix'	is valid in FPulse ( Acquisition )
	InitializeAutoWndArray( wIO )
	//  Retrieve the Mode/Range-Color string  entries  and  build the (still empty) windows
	BuildWindows( sFolder, wG, wIO, wFix, kFRONT )
	EnableButton( "PnAcqWin", "buPreparePrint", kENABLE )	// Now that the acquisition windows (and TWA) are constructed we can allow drawing in them (even if they are still empty)
End


static Function  /S	stModeNm( n )
// returns  an arbitrary  name for the mode, not for the variable  e.g. 'C' , 'M' 
	variable	n
	return	StringFromList( n, sMODENM )
End

static Function	stModeNr( s )
// returns  index of the mode, given its name
	string  	s
	variable	nMode = 0				// Do not issue a warning when no character is passed.... 
	if ( strlen( s ) )					// This happens when a window contains no traces.
		nMode = WhichListItem( s, sMODENM )
		if ( nMode == kNOTFOUND )
			DeveloperError( "[ModeNr] '" + s + "' must be 'C' or 'M' " )
		endif
	endif
	return nMode
End

static Function	stModeCnt()	
	return	ItemsInList( sMODETEXT )
End	

Function	/S	UsedModes( wIO, nIO, c ) 
// Compute  and  return  for  1 trace the  list of used   Mode  indices  ( e.g  0;2;3;)
	wave  /T	wIO
	variable	nIO, c
	string  	sTab	  = ios( wIO, nIO, c, cIONM ) 		
	return	CheckedBoxIndicesInTabControl( sTab, sMODEFOLDER, sMODETEXT ) 
End


Function  /S	RangeNm( n )
// returns  an arbitrary  name for the range, not for the variable  e.g.  'S' , 'F',  'R',  'P'
	variable	n
	return	StringFromList( n, sRANGENM )
End

Function		RangeNr_( s )
// returns  index of the range, given its name
	string 	s
	variable	n = 0				// Do not issue a warning when no character is passed.... 
	if ( strlen( s ) )					// This happens when a window contains no traces.
		n = WhichListItem( s, sRANGENM )
		if ( n == kNOTFOUND )
			DeveloperError( "[RangeNr] '" + s + "' must be 'S' (Sweep) or 'F' (Frame) or 'P' (Primary sweep) or 'R' (Result sweep) " )
		endif
	endif
	return n
End

static Function	stRangeCnt()
	return	ItemsInList( sRANGETEXT )
End	

Function	/S	UsedRanges( wIO, nIO, c ) 
// Compute  and  return  for  1 trace the  list of used   Range  indices  ( e.g  0;2;3;)
	wave  /T	wIO
	variable	nIO, c
	string		sTrcOnIndices
	string  	sTab	  = ios( wIO, nIO, c, cIONM ) 		
	// printf "\t\t\tUsedRanges( nIO:%d, c:%d ->   \tsTab:\t%s\t)  returns: %s  \r", nIO, c, pd(sTab,9),  CheckedBoxIndicesInTabControl( sTab, sRANGEFOLDER, sRANGETEXT ) 
	return	CheckedBoxIndicesInTabControl( sTab, sRANGEFOLDER, sRANGETEXT ) 
End


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  IMPLEMENTATION  for  STORING   MODE  and  RANGE  as  a 2-LETTER-string 

static Function	   /S 	stBuildMoRaName( nRange, nMode )
// converts the Mode / range setting for storage in TWA  to a 2-letter-string   e.g. 	'SM',   'FC' 
	variable	nRange, nMode
	return	RangeNm( nRange ) + stModeNm( nMode )
End

static Function	   /S 	stBuildMoRaNameInstance( nRange, nMode, nInstance )		// 040107
// converts the Mode / range setting into a 2-letter-string   containing the instance number  e.g. 	'SM ',   'FC1'       ( obsolete: 'SMa',   'FCb' )  
	variable	nRange, nMode, nInstance 
	string    	sInstance = SelectString( nInstance != 0, " " , num2str( nInstance ) )	// for the 1. instance  do not display the zero but leave blank instead
	return	" " + stBuildMoRaName( nRange, nMode ) + " " + sInstance 			// 040107
End

static Function		stExtractMoRaName( sMoRa, rnRange, rnMode )
// retrieves the Mode / range setting  from TWA  and converts the 2-letter-string   into 2 numbers  e.g. 'SM'->0,1   'RS' ->3,0
	string 	sMoRa
	variable	&rnRange, &rnMode
	rnRange	= RangeNr_( sMora[0,0] )
	rnMode	= stModeNr(   sMora[1,1] )
End

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////    TRACE SELECT   PANEL
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//Function   /S	TraceSelectModalDialog( sTNL )
//	string 	sTNL
//	string 	sTrace = ""
//	Prompt	sTrace, "Trace", popup, sTNL
//	DoPrompt	"Select a trace", sTrace	
//	if ( V_Flag )
//		return	StringFromList( 0, sTNL )		// user canceled
//	endif
//	return	sTrace
//End


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//    ACTION  PROCEDURES  from  the  PREFERENCES  PANEL
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function		root_uf_aco_disp_bAcqControlbar( ctrlName, bValue ) 
// creates Trace / Window controlbar in acquis windows
	string 	ctrlName
	variable	bValue	
	string  	sFolder	= ksfACO
	wave  /T	wIO		= $ksROOTUF_ + sFolder + ":ar:wIO"  				// This  'wIO'  is valid in FPulse ( Acquisition )
	CreateAllControlBarsInAcqWnd( wIO )		// show / hide the ControlBar  immediately
End

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  SAMPLE : NON-MODAL  PANEL

//Function CreateTraceSelectPanel()
//	DoWindow /F TrcSelectPanel			// try to bring to front
//	if ( V_Flag == 0 )						// panel does not yet exist
//		Execute "TraceSelectPanel()"
//	endif
// End
//
// Proc	TraceSelectPanel()
//	PauseUpdate; Silent 1				// building window...
//	variable	XLoc	= GetIgorAppPixelX() -  250  // - PnXsize( tPnAcqWn ) - 170
//	variable 	YLoc	= 300			// Panel location in pixel from upper side
//
//	NewPanel /K=1 /W=( XLoc, YLoc, XLoc +140, YLoc +60 ) 
//	PopupMenu popup1,pos={10,10},size={60,20},proc=TraceSelectProc,title="Traces"
//	PopupMenu popup1,value= 	GetTraceOnNameList()
//EndMacro

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////    COLORIZE  TRACES  PANEL
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//Function CreateTraceColorPanel()
//// Construction of this panel taken from KBColorizeTraces.IPF ( it does not fit in my usual panel construction because of the PopupMenu )
//	DoWindow /F ColorizePanel				// try to bring to front
//	if ( V_Flag == 0 )						// panel does not yet exist
//		Execute "TraceColorPanel()"
//	endif
// End
//
// Proc	TraceColorPanel()
//	PauseUpdate; Silent 1				// building window...
//	variable	XLoc	= GetIgorAppPixelX() -  250  // - PnXsize( tPnAcqWn ) - 170
//	variable 	YLoc	= 300			// Panel location in pixel from upper side
//
//// small single color popup
////	NewPanel /K=1 /W=( XLoc, YLoc, XLoc +90, YLoc + 32 )
////	PopupMenu popup0,pos={10,10},size={96,20},proc=ColorPopMenuProc,title="colors"
////	PopupMenu popup0,mode=1,popColor= (0,65535,65535),value= "*COLORPOP*"
//
//// larger double color / trace popup
//	NewPanel /K=1 /W=( XLoc, YLoc, XLoc +240, YLoc + 40 ) 
//	PopupMenu popup0,pos={5,10},size={96,20},proc=ColorPopMenuProc,title="colors"
//	PopupMenu popup0,mode=1,popColor= (0,65535,65535),value= "*COLORPOP*"
//
//	PopupMenu popup1,pos={100,10},size={60,20},proc=ColorPopMenuProc,title="traces"
//	PopupMenu popup1,value= 	ioChanList( wIO )
//EndMacro


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////    STATUSBAR   ( FUNCTION  VERSION  WITH  DEPENDENCIES )
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//Function		NewStatusBar( sSBNm, sSBTitle )	
//	string 	sSBNm, sSBTitle
//	if ( winType( sSBNm ) != kGRAPH )					// the desired status bar does not exist....
//		KillGraphs( "SB*" )							// ..so kill any other status bar that might exist...
//		if ( cmpstr( sSBNm, "SB_ACQUISITION" ) == 0 )	
//			CreateStatusBarAcq( sSBNm, sSBTitle )		// ..and build the desired status bar 
//		elseif ( cmpstr( sSBNm, "SB_CFSREAD" ) == 0 )	
//			CreateStatusBarCFSRead( sSBNm, sSBTitle )	// ..and build the desired status bar 
//		endif	
//	endif											// Do nothing if the desired status bar exists already
//End			   


