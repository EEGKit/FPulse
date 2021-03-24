
// FPOnlineA.ipf ( in CED1401 )
// 
// History: 
// 040217	computations now use seconds as time scale as in the other program parts (was milliseconds)
// 040217	introduced  Adc gain in the results
// 040227	Flaw: when not writing CFS file  the user has to 'Apply'  to clear the Analysis window to draw new results 

// todo
// OK	make  analysis display independent of  writing the CFS file
// OK	link  RGconstants  to  RESconstants
// OK	do not build  'time'  traces 
// OK	do not build  'beginning'  and  'end'  traces 
// OK	precise peak determination
// OK	display computed result as a region for visual checking 
// OK 	portions of analysis traces which were not defined should  NOT be displayed (instead of being displayed with 0)
// OK	small cross and big cross
// OK	set the shape of analysis regions    and the  fill pattern  with string lists 
// OK	after killing or expanding the analysis window it should be rebuilt and resized  and it should display traces   OR   there shoud be a REBUILD  button.  NO : user may minimize it and restore it, but if he kills it it is gone forever
// OK	erase regions of previous frames automatically
// OK 	make cINTER obsolete and remove it
// OK	combine PKUP, PKDN and PKBO
// OK	display the state of the  'Region' checkbox correctly (when visible it must be ON) (implemented but not as an elegant solution)
// OK 	order results so that base is always in front of peak		or    make analysis independent of ordering
// OK	peak direction is mixed up when a new peak is inserted
// OK	what if a new script is loaded containing new IO channels for which  no wFileRes waves exist?
// OK 	display peak direction button to its correct state
// OK	allow switching between second and frames  at any time
// OK	button 'Clear analysis window'
// OK	continuous display independent of CFS file
// OK	2. base, 2. peak
// OK	quotient of 2 peaks
// OK 	make 'RTim' work
// OK	allow 2 analysis windows
// OK	allow any number of analysis windows
// OK	X scaling also in minutes
// OK	optionally leave line segment blank between 2 protocols
// OK	decay fit

//	CRASH  when using more than 1 protocol
// 	make timing linear ( up to 1 second error , but occurring only on some systems with some scripts ! )
// 	GetAxis   /Q /W = $sWnd left	does NOT work under certain ? AUTOSCALE conditions., returns  min=max=0				

// Wishes: 
// 	rise fit starting values
//	display time needed for fit ( measure or Task manager...) , exit gracefully if fitting time takes too long for the acquisition timing requirement
// 	copy analysis window so that user can zoom  areas of the copied graph without loosing the original graph containing the total experiment duration
// 	Multiple blocks: e.g. Analyse just one selectable block  OR  define different regions belonging to blocks
// 	Multiple protocols: e.g. Scripts with Inc/Dec 40/60mV  : draw 1 analysis point after averaging  10  40mV frames, another  after averaging  10  60mV frames (JB) 
//			.....[ Is something aequivalent already possible? ]

#pragma rtGlobals=1							// Use modern global access method.

static	  strconstant	ksSEP_EQ			= "="
//static	  strconstant	AnalysisWindows()		= "WA0;WA1" 
static strconstant	csANALWNDBASE	= "A"	// The name should NOT start with 'W' as any window will be erased by  'KillTracesInMatchingGraphs( "W*" )'  when a script is loaded or applied


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  ANALYSIS 1 :  REDUCING  ANALYSIS 
//  Evaluation of  a number of original data points gives one result value.  Realized  here  are   'Base' , 'Peak'  and  'RTim'
//  Features:
//  - Elaborate routines...
//  - no keyword needed in the script , analysis is controlled by user defined regions and an  Analysis control panel

static  constant		FT_NONE = 0, FT_LINE = 1, FT_1EXP = 2, FT_1EXPCONST = 3, FT_2EXP = 4, FT_2EXPCONST = 5, FT_RISE = 6, FT_RISECONST = 7,  FT_RISDEC = 8, FT_RISDECCONST = 9, FT_MAXPAR = 10 
static strconstant	ksFITFUNC	= "none;Line;1 Exp;1 Exp+Con;2 Exp;2 Exp+Con;Rise;Rise+Con;RiseDec;RiseDecCon"		
static strconstant	ksPARNAMES	= "??~Co;Sl;~A0;T0;~A0;T0;Co;~A0;T0;A1;T1;~A0;T0;A1;T1;Co;~RT;De;Am;~RT;De;Am;Co;~RT;De;Am;Ta;TS;~RT;De;Am;Ta;TS;Co;~"		// must consist of 2 characters for the automatic name-building/extracting to work


// ----------------------------  P E A K   D I R E C T I O N S  ------------------------------
static constant		cPKDIRUP	= 0, 	cPKDIRDN	= 1, 	cPKDIRBOTH	= 2
static  strconstant	lstRGPKDIR	= "Up;Down;Both;"	


// ----------------------------  D E C A Y   F I T   F U N C T I O N S  ------------------------------
static  strconstant	lstRGDECAYFIT	= "Line;Exp1C;Exp2;"								// the actual fit functions
static strconstant	lstACTUALDECAYFIT= "1;3;4,"										// indices of the actual fit function, see FT_NONE = 0, FT_LINE = 1, FT_1EXP...

// ----------------------------  R I S E   F I T   F U N C T I O N S  ------------------------------
static  strconstant	lstRGRISEFIT		= "Line;Rise;RiseC;"								// the actual fit functions
static strconstant	lstACTUALRISEFIT	= "1;6;7;"										// indices of the actual fit function, see FT_NONE = 0, FT_LINE = 1, FT_1EXP...


// ----------------------------  X   A X I S  S C A L I N G  ------------------------------

// ----------------------------  R E S U L T S   NEW ------------------------------ ( NO BLANKS ALLOWED )  -----------------------
// Once for all channels
static constant		cEVNT = 0, cTIME = 1, cMINU = 2
strconstant		lstXPANEL_ = "frames;seconds;minutes"					
strconstant		lstXUNITS_	= "frame;s;minute"					
strconstant		lstRESfix_	= "Evnt;Tim_;Minu;"													// once for all channels,  value to display and possibly to file . Do NOT use 'Time' instead of 'Tim_' 

static constant		cPROT= 0, cBLCK = 1, cFRAM = 2
strconstant		lstRESpbf	= "Prot;Blck;Fram;"													// once for all channels,  value not to display but (probably) to file  


// 060511b   Base3 and Peak3
// Once for every channel
//static  strconstant	lstRESreg	= "Base;Peak;Bas2;Pea2;PQuo;RTim;Rise;Dcay;" // Mean;RT28;Lat1;Lat2;HfDu;SlRD;SDBs" // once for every channel,	value to file  and  to display wave
//static  strconstant	lstRGBEG	= "BaBg;PkBg;B2Bg;P2Bg;	;RTBg;RiBg;DcBg;"								// once for every channel, write value to file  . Empty field: do not write to file
//static  strconstant	lstRGEND	= "BaEn;PkEn;B2En;P2En;	;RTEn;RiEn;DcEn;"								// once for every channel, write value to file  . Empty field: do not write to file  
//static  strconstant	lstRESCOL = "20000,65535,655350;	65535,0,10000;		10000,10000,65535;	55000,0,55000;			0,0,0;		20000,60000,20000;	59000,26000,5000;	55000,48000,0;		0,0,0;"
//
//// ----------------------------  R E G I O N S  ------------------------------
//static  strconstant	lstRGTYPE	= "Base;Peak;Bas2;Pea2;PQuo;RTim;Rise;Dcay;"								// Must be sorted in the order needed for analysis (=base>peak>rtim, rise,decay>pquot). This order is used in 'RectangularIndex()'  
//constant			rgBASE 			= 0,	  		rgPEAK	= 1,  		rgBAS2 = 2,  		rgPEA2 = 3, 		rgPQUOT = 4,		rgRTIM = 5,   		rgRISE = 6,   		rgDECAY = 7, 	MAXREG_TYPE = 8	// index into marquee / region data
//
////							rgBASE  cyan		rgPEAK red		rgBAS2 blue		rgPEA2  magenta	rgPQUOT grey		rgRTIM  green		rgRISE  orange		rgDECAY yellow		
//static  strconstant 	lstRGCOLOR = "20000,58000,58000;	64000,5000,5000;	30000,30000,65535;	60000,25000,65535;	30000,30000,30000;	25000,65535,25000;	62000,28000,0;		55000,48000,0"	// User and final have the same color
//static  strconstant 	lstRGSHP_U = "	2		;		2		;		2		;		2		;		2		;		2		;		2		;		2		"	// User , index into lstRGSHAPE
//static  strconstant 	lstRGSHP_F  = "	5		;		7		;		5		;		7		;		0		;		4		;		9		;		9		"	// Final , index into lstRGSHAPE


// Once for every channel
static  strconstant	lstRESreg	= "Base;Peak;Bas2;Pea2;Bas3;Pea3;PQuo;RTim;Rise;Dcay;" // Mean;RT28;Lat1;Lat2;HfDu;SlRD;SDBs" // once for every channel,	value to file  and  to display wave
static  strconstant	lstRGBEG	= "BaBg;PkBg;B2Bg;P2Bg;B3Bg;P3Bg;	;RTBg;RiBg;DcBg;"								// once for every channel, write value to file  . Empty field: do not write to file
static  strconstant	lstRGEND	= "BaEn;PkEn;B2En;P2En;B3En;P3En;	;RTEn;RiEn;DcEn;"								// once for every channel, write value to file  . Empty field: do not write to file  
static  strconstant	lstRESCOL = "24000,65535,65535;	65535,0,6000;		16000,33000,62000;	54000,0,36000;		8000,6000,65535;	52000,0,56000;			0,0,0;		20000,60000,20000;	59000,26000,5000;	55000,48000,0;		0,0,0;"

// ----------------------------  R E G I O N S  ------------------------------
static  strconstant	lstRGTYPE	= "Base;Peak;Bas2;Pea2;Bas3;Pea3;PQuo;RTim;Rise;Dcay;"								// Must be sorted in the order needed for analysis (=base>peak>rtim, rise,decay>pquot). This order is used in 'RectangularIndex()'  
constant			rgBASE 			= 0,	  		rgPEAK	= 1,  		rgBAS2 = 2,  		rgPEA2 = 3,  		rgBAS3 = 4,  		rgPEA3 = 5, 		rgPQUOT = 6,		rgRTIM = 7,   		rgRISE = 8,   		rgDECAY = 9, 	MAXREG_TYPE = 10	// index into marquee / region data

//							rgBASE  cyan		rgPEAK red		rgBAS2 blue-cyan	rgPEA2  red-magenta	rgBAS3 blue		rgPEA3  magenta	rgPQUOT grey		rgRTIM  green		rgRISE  orange		rgDECAY yellow		
static  strconstant 	lstRGCOLOR = "16000,60000,54000;	65000,5000,5000;	26000,40000,60000;	58000,18000,38000;	32000,24000,65535;	56000,30000,65535;	30000,30000,30000;	25000,65535,25000;	62000,28000,0;		55000,48000,0"	// User and final have the same color
static  strconstant 	lstRGSHP_U = "	2		;		2		;		2		;		2		;		2		;		2		;		2		;		2		;		2		;		2		"	// User , index into lstRGSHAPE
static  strconstant 	lstRGSHP_F  = "	5		;		7		;		5		;		7		;		5		;		7		;		0		;		4		;		9		;		9		"	// Final , index into lstRGSHAPE




	
strconstant		lstRGSTAGE = "User;Final"					
static	 constant		cUSER	    = 0,	cFINAL	= 1,	MAXREG_STAGE	= 2			// refinement of searched region
static constant		ALLSTAGES = -1

strconstant		lstRGSHAPE = "hidden;Rect tall;Rect below;Rect user drawn;Line exact;Line thick;Line horz long;Cross small;Cross big;Fitted segment;"					
static constant		kHIDDEN = 0,  kRECTYFULL = 1,  kRECTYBELOW = 2,  kRECTEXACT = 3, kLINEEXACT = 4, kLINETHICK = 5 , kLINEHORZLONG = 6, kCROSSSMALL = 7 , kCROSSBIG = 8, kFITTED = 9	// Cave: when changing also edit   lstRGSHP   manuallly. Default 0 should be 'kHIDDEN'.


//constant			CLEAR		= 0, 	DRAW	= 1

constant			kNOT_OPEN_	= 0
strconstant		sOLAEXT_		= "ola"

static  strconstant	csFOLDER_OLA		= "root:uf:aco:ola:"		// the folder for evaluation and fit results
static  strconstant	csFOLDER_OLA_CROSS	= "root:uf:aco:ola:cross:"	// the folder for the cross or line displaying the evaluation result 
static  strconstant	csFOLDER_OLA_FITTED	= "root:uf:aco:ola:fit:"		// the folder for the fitted segments displaying the evaluation result 
static  strconstant	csFOLDER_OLA_DISP	= "root:uf:aco:ola:disp:"	// the folder for the DISPLAY results


Function		CreateGlobalsInFolder_OLA_()
// creates all folder-specific variables. To be used once from CreateGlobals() as the current data folder is changed and not restored

	NewDataFolder  /O  /S $RemoveEnding( csFOLDER_OLA)	// make a new data folder and use as CDF,  clear everything (remove trailing ':')

	variable	/G	gnPeakAverMS		= .5				// Average over that time (including both sides of peak) to reduce noise influence on peak height
	variable	/G	gnPeakAverMS2	= .5				// Average over that time (including both sides of peak) to reduce noise influence on peak height
	variable	/G	gnPeakAverMS3	= .5				// 060511b

	variable	/G	gbBlankPauses		= FALSE//TRUE			// Remove connecting lines in OLA graph when there is no experiment 
	variable	/G	gOLAFrmCnt		= 0				// frame counter for the OLA analysis
	variable	/G	gOLAHnd			= kNOT_OPEN_
	variable	/G	gnStartTicksOLA	= 0
	variable	/G	gOLADoFitOrStartVals= TRUE			//  1 : do fit , 0 : do not fit, display only starting values.  Can be set to 0  only in  debug mode in Test panel.

	make /O /T  /N = 0   wtAnRg	= ""					// the wave containing region information is built with size 0. One line is added whenever the user defines a new region.

	if ( ! kbIS_RELEASE )
		gnPeakAverMS		= 2							// Average (for testing) over a long time (including both sides of peak) to reduce noise influence on peak height
		gnPeakAverMS2	= 2							// Average (for testing) over a long time (including both sides of peak) to reduce noise influence on peak height
		gnPeakAverMS3	= 2							// 060511b
	endif

	NewDataFolder  /O  /S $RemoveEnding( csFOLDER_OLA_CROSS )		// remove trailing ':'
	NewDataFolder  /O  /S $RemoveEnding( csFOLDER_OLA_DISP ) 		// remove trailing ':'
	NewDataFolder  /O  /S $RemoveEnding( csFOLDER_OLA_FITTED ) 		// remove trailing ':'

End


static Function /S	stAnalWndNm( w )
	variable	w
	return	csANALWNDBASE + num2str( w )
End

static Function  /S	stAnalysisWindows()
	string  	sWinList	= WinList( csANALWNDBASE + "*" , ";" , "WIN:1" )			// return  list of all   graph windows matching  'WA*'
	// print sWinList
	return	sWinList
End


static Function	stAddAnalysisWnd()
// Construct and display  1 additional  Analysis windows with the next default name
	variable	w, wCnt
	string 	sWNm
	wCnt	= ItemsInList( stAnalysisWindows() ) + 1
	for ( w = 0; w < wCnt;  w += 1 )
		sWNm	= stAnalWndNm( w )
		variable	rnLeft, rnTop, rnRight, rnBot										// place the window in top half to the right of the acquisition windows 
		GetAutoWindowCorners( w, wCnt, 0, 1, rnLeft, rnTop, rnRight, rnBot, kWNDDIVIDER_, 100 )	// row, nRows, col, nCols
		if (  ! ( WinType( sWNm ) == kGRAPH ) )										//  There is no 'Analysis' window
			Display /K=2 /N=$( sWNm ) /W= ( rnLeft, rnTop, rnRight, rnBot ) 					// K=2 : disable killing	 . The user must kill a window with button 'Remove' to preserve ordering.	
		else
			MoveWindow	 /W=$sWNm  rnLeft, rnTop, rnRight, rnBot 
		endif
	endfor
	string  	sFolder		= ksfACO
	string  	sPnOptions	= ":dlg:tPnOLADisp" 
	InitPanelOLADisp( sFolder, sPnOptions )									// necessary to display the changed panel state immediately
	UpdatePanel(  "PnOLADisp" , "Online Analysis" , sFolder, sPnOptions )				// same params as in  ConstructOrDisplayPanel()
End

static Function	stRemoveAnalysisWnd()
//// Construct and display  1 additional  Analysis windows with the next default name
	variable	wCnt		= ItemsInList( stAnalysisWindows() ) 
	if ( wCnt )
		string 	sWNm	= stAnalWndNm( wCnt-1 )
		KillWindow $sWNm
		string  	sFolder		= ksfACO
		string  	sPnOptions	= ":dlg:tPnOLADisp" 
		InitPanelOLADisp( sFolder, sPnOptions )								// necessary to display the changed panel state immediately
		UpdatePanel(  "PnOLADisp" , "Online Analysis" , sFolder, sPnOptions )			// same params as in  ConstructOrDisplayPanel()				
	endif
End


static Function	stClearAnalysisWnd()
// the waves are not really killed (but could be should ever need arise) , only the flag is set telling that the waves need to be rebuilt.
	nvar		gOLAFrmCnt	= root:uf:aco:ola:gOLAFrmCnt
	nvar		gnStartTicksOLA= root:uf:aco:ola:gnStartTicksOLA

	gOLAFrmCnt		= 0
	gnStartTicksOLA	= ticks							// Resetting the ticks here will start the clock after the first region has been defined ( probably better: when acquisition starts )  

	variable	w, wCnt	= ItemsInList( stAnalysisWindows() )
	for ( w = 0; w < wCnt;  w += 1 )
		string  	sWNm	= StringFromList( w, stAnalysisWindows() )

		if ( WinType( sWNm ) == kGRAPH )
			string 	sTNL	= TraceNameList( sWNm, ";", 1 )
			variable	t,   tCnt	=  ItemsInList( sTNL ) 
			printf "\t\tClearAnalysisWnd()  wnd:%s has %d traces   [TrcNmList: %s..] \r", sWNm, tCnt, sTNL[0,160]	
			for ( t = 0;  t < tCnt; t += 1 )			
				wave	wv	= TraceNameToWaveRef(  sWNm, StringFromList( t, sTNL ) )	// !!!
				redimension  /N = 0   wv
			endfor
		endif
	endfor
End

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

static Function	stAnalysisIsOn()
// returns TRUE when at least one user region is defined    or  FALSE = 0  when no user region is defined
	return	stRegionCnt() > 0
End

// 031007  !    NOT  YET  REALLY  PROTOCOL  AWARE ............
Function		OnlineAnalysis_( sFolder, wG, wIO, pr, bl, fr )
	string  	sFolder
	wave  	wG
	wave  /T	wIO
	variable	pr, bl, fr
	nvar		gOLAFrmCnt	= root:uf:aco:ola:gOLAFrmCnt
	nvar		gnStartTicksOLA= root:uf:aco:ola:gnStartTicksOLA

	if ( stAnalysisIsOn() )							// If no cUSER region is defined we skip the whole analysis (this must be refined if there are analysis types requiring no cUSER region)
		if ( gOLAFrmCnt	== 0 )
			gnStartTicksOLA	= ticks			// Resetting the ticks here will start the clock after the first region has been defined ( probably better: when acquisition starts )  
		endif
		if ( pr == 0  &&  bl == 0  &&  fr == 0 )			// Insert a pause for every new protocol by  inserting a Nan rather than data in the display trace.
			gOLAFrmCnt	+= 1	
			stInsertNanInDisplayWave( gOLAFrmCnt )	// Inserting a Nan rather than data in the display trace marks those points as separators and allows blanking out intervals between protocols..
		endif													
		gOLAFrmCnt	+= 1	
		stOnlineAnalysis1Point( sFolder, wG, wIO, pr, bl, fr, gOLAFrmCnt )								
	endif
End												


static Function	stInsertNanInDisplayWave( index )
// Fill  display  wave with 1 Nan point to blank out the data point.
	variable	index
	variable	nP, rnType, n, nItems = stRegionCnt()
	string  	rsSrc, sOLANm, lstOLANm
	
	stAppendPointToTimeWaves( index )

	// Step 5 + 7: Construct the waves  which are displayed in the Analysis window  e.g.  Adc1Base, Acc0RTim, etc...and fill them with Nan to blank out the data point.
	for ( n = 0; n <  nItems; n += 1 )							// For all  channel/region combinations  which the user has defined 
		stRegionSrcType( n, rsSrc, rnType )					// passed parameters are changed

		lstOLANm	= stOlaNmLst( rsSrc, rnType, lstRESreg )			//  e.g. 'Adc1Base' , 'Adc0PkBg' 
		for ( nP = 0; nP < ItemsInList( lstOlaNm ); nP += 1 )
			sOlaNm	= StringFromList( nP, lstOlaNm )
			stNewElementOlaDisp( sOLANm, index ) 				// Returns TRUE if a new wave has just been constructed.
		 	stSetElementOlaDisp( sOlaNm, index, Nan )				// Nan allows blanking out intervals between protocols.
		endfor		
	endfor		
End


static Function	stAppendPointToTimeWaves( index )
//  Construct the waves  'Evnt'  , 'Tim_'  and  'Minu'  which are used as  XAxis .   'Prot' , Blck' , 'Fram'  could be but are not constructed here as they are not needed for the display. 
	variable	index
	nvar		gnStartTicksOLA	= root:uf:aco:ola:gnStartTicksOLA
	variable	value, n, seconds	= ( ticks - gnStartTicksOLA ) / kTICKS_PER_SEC
	for ( n = 0; n < ItemsInList( lstRESfix_ ); n += 1 )
		if ( n == cEVNT)				// Not very elegant, but Igor does not interpret nested conditional assignments correctly : WRONG : value = ( n == cEVNT )  ?  index - 1 : ( n == cTIME )   ?  seconds : seconds / 60	
			value	= index - 1 
		elseif ( n == cTIME )
			value	= seconds
		else	// n == cMINU 
			value	= seconds / 60
		endif
		string  	sOLANm	= StringFromList( n, lstRESfix_ ) 							
		// printf "\t\tAppendPointToTimeWaves( index: %d ) \tn: %d \t( = %s) \tvalue:\t%8.1lf\tseconds= %8.1lf\t\t ( sOlaNm: %s )\r", index, n, pd( StringFromList( n, lstRESfix_ ), 8), value, seconds, sOlaNm
		stNewElementOlaDisp( sOLANm, index )
		stSetElementOlaDisp( sOLANm, index, value )				//  Add   'Event'  , 'Time'  and  'Minu'   to display wave . Starting at 0 allows to use this wave as XAxis
	endfor
	return	seconds
End


static Function	stOnlineAnalysis1Point( sFolder, wG, wIO, pr, bl, fr, index )
// Function for online evaluation
// Design issue: the OLA is frame-oriented : it is executed once every frawe, sweeps are ignored 
// Flaw: works only if write mode is on , only viewing the analysis results is not possible
	string  	sFolder
	wave	wG
	wave  /T	wIO
	variable	pr, bl, fr, index
	nvar		gOLAHnd		= root:uf:aco:ola:gOLAHnd
	variable	nSmpInt		= wG[ kSI ]
	nvar		gbWriteMode	= root:uf:aco:cfsw:gbWriteMode
	svar		gsDataPath	= root:uf:aco:cfsw:gsDataPath							// use same path...
	svar		gsDataFileW	= root:uf:aco:cfsw:gsDataFileW							// ...and file name as CFS file...

variable	BegPt		= FrameBegSave( sFolder, pr, bl, fr )		// could this simplify BResultXShift  ???? (see 070424)

	string  	lstOLANm, sOLANm, sResultNm
	string  	sSrc, sLine 	= ""
	variable	nP, n, nType
	variable	nRegions	= stRegionCnt()		
	variable	nResults	= ItemsInList( stActiveResults() )
	
	printf "\t\t\tOnlineAnalysis1()\tpr: %d   bl: %d  fr: %d \tgOLAFrmCnt: %d\t\tnRegs:%2d\tnResults:%2d  \r", pr, bl, fr, index, nRegions, nResults

	//  Step 1 :  Open  the OLA file
	if ( gOLAHnd == kNOT_OPEN_  )											
		// Open the OLA result file using	the same path and file name as CFS file  but with another extension  
		if ( gbWriteMode )			
			string  	sOLAPath	 = StripExtension( gsDataPath + gsDataFileW ) + sOLAEXT_	//  OLA file is always written in parallel to CFS. If CFS is not written OLA is neither (could be changed...) 
			// printf "\t\tOnlineAnalysis1() gbWriteMode is %s opening '%s' \r", SelectString( gbWriteMode, " OFF :  NOT ", " ON : " ), sOLAPath
			variable	nOLAHnd
			Open  nOLAHnd  as sOLAPath
			gOLAHnd = nOLAHnd
			if ( gOLAHnd == kNOT_OPEN_ )	
				Alert( kERR_FATAL,  "Could not open Online analysis file '" + sOLAPath + "' ." )
				return	kERROR
			endif
		endif
	endif

	variable	seconds	= stAppendPointToTimeWaves( index )
	//  Add  'Event' , 'Prot' , 'Blck' , 'Fram'  and 'Tim_'  to file with  custom  formatting.
	sprintf 	sLine, "%s%s%3d;%s%s%3d;%s%s%3d;%s%s%3d;%s%s%10.1lf;" , StringFromList( cEVNT, lstRESfix_ ), ksSEP_EQ, index - 1, StringFromList( cPROT, lstRESpbf ), ksSEP_EQ, pr, StringFromList( cBLCK, lstRESpbf ), ksSEP_EQ, bl, StringFromList( cFRAM, lstRESpbf ), ksSEP_EQ, fr, StringFromList( cTIME, lstRESfix_ ), ksSEP_EQ, seconds  	


	// Step 5 : Construct the waves  which are displayed in the Analysis window  e.g.  Adc1Base, Acc0RTim, etc...
	for ( n = 0; n <  nRegions; n += 1 )								// For all  channel/region combinations  which the user has defined 
	
		stRegionSrcType( n, sSrc, nType )									// passed parameters are changed
	  	sResultNm		= stResultNm( sSrc )								// e.g. 'ResAdc0' , 'ResPoN1'
		wave  /Z	wResult	= $("root:uf:aco:ola:" + sResultNm ) 					// wResult is needed only for  temporary storage of peak and base to later compute Quot. 2 variables are sufficient?
		if ( ! waveExists( wResult ) )				
			make  /O	/D /N = ( MAXREG_TYPE, FT_MAXPAR )	$("root:uf:aco:ola:" + sResultNm) = 0	//			
			wave  	wResult		=	$("root:uf:aco:ola:" + sResultNm ) 	
		endif

		lstOlaNm	= stOlaNmLst( sSrc, nType, lstRESreg )						//  e.g. 'Adc1Base' , 'Adc0PkBg' . Used for the keywords in the file and for the result wave names
		for ( nP = 0; nP < ItemsInList( lstOlaNm ); nP += 1 )
			sOlaNm	= StringFromList( nP, lstOlaNm )
			stNewElementOlaDisp( sOLANm, index ) 						//  Returns TRUE if a new wave has just been constructed.
		endfor		
		
	endfor		

	// Step 7 : Build the computed part of the result line  (Base, Peak, ...)
	for ( n = 0; n <  nRegions; n += 1 )									// For all defined regions
		stRegionSrcType( n, sSrc, nType )
	
		variable	Gain		= GainByNmForDisplay_( wIO, sSrc )
	  	sResultNm		= stResultNm( sSrc )						// e.g. 'ResBase' , 'ResPeakUp'
		wave	wResult	= $("root:uf:aco:ola:" + sResultNm ) 				// wave has been built in 'BuildOnlineDisplayWaves()'

		//  REGION - RESULT - CONNECTION - SPECIFIC 1
		// The data points previously stored in 'wResult[ region type ][ 0 ]'  are  combined to give output results for file and display e.g. 'Peak' - 'Base' = 'Ampl'  
		// Here the connection is made between regions (to be evaluated)  and  results (to be printed and displayed, possibly from various regions)
		// Add the data point to  the 1 dimensional (Frames) result wave used to display data 1 frame after the other
		variable	nFitFunc	= 0
		if ( nType == rgBASE )
			wResult[ nType ][ 0 ]	= stBaseVal( wIO, sSrc, nType,  BegPt, nSmpInt / kXSCALE, Gain )
		elseif ( nType == rgPEAK )
			wResult[ nType ][ 0 ]	= stPeakVal( wIO, sSrc, nType, BegPt, nSmpInt / kXSCALE, Gain, wResult[ rgBASE ][ 0 ] ) - wResult[ rgBASE ][ 0 ] 

		elseif ( nType == rgBAS2 )
			wResult[ nType ][ 0 ]	= stBaseVal( wIO, sSrc, nType,  BegPt, nSmpInt / kXSCALE, Gain )
		elseif ( nType == rgPEA2 )
			wResult[ nType ][ 0 ]	= stPeakVal( wIO, sSrc, nType, BegPt, nSmpInt / kXSCALE, Gain, wResult[ rgBAS2 ][ 0 ] ) - wResult[ rgBAS2 ][ 0 ] 
// 060511b
		elseif ( nType == rgBAS3 )
			wResult[ nType ][ 0 ]	= stBaseVal( wIO, sSrc, nType,  BegPt, nSmpInt / kXSCALE, Gain )
		elseif ( nType == rgPEA3 )
			wResult[ nType ][ 0 ]	= stPeakVal( wIO, sSrc, nType, BegPt, nSmpInt / kXSCALE, Gain, wResult[ rgBAS3 ][ 0 ] ) - wResult[ rgBAS3 ][ 0 ] 


		elseif ( nType == rgPQUOT )
			wResult[ nType ][ 0 ]	= stPQuotVal( sSrc, nType, wResult[ rgPEAK ][ 0 ] , wResult[ rgPEA2 ][ 0 ] )
		elseif ( nType == rgRTIM )													// compute  rgRTIM  after rgBASE and rgPEAK, whose values are needed		
			wResult[ nType ][ 0 ]	= stRTimVal( wIO, sSrc, nType,  BegPt, nSmpInt /  kXSCALE, Gain, 20, 80, wResult[ rgBASE ][ 0 ],  wResult[ rgBASE ][ 0 ] + wResult[ rgPEAK ][ 0 ] )
		elseif ( nType == rgRISE )
			nFitFunc			= stRiseOrDecayFit( wResult, sSrc, nType,  BegPt, nSmpInt / kXSCALE, Gain, lstACTUALRISEFIT )		// Sets wResult to be retrieved below in AddToFileValOrPars(). There is only 1 wResult no matter how many traces.
		elseif ( nType == rgDECAY )
			nFitFunc			= stRiseOrDecayFit( wResult, sSrc, nType,  BegPt, nSmpInt / kXSCALE, Gain, lstACTUALDECAYFIT )	// Sets wResult to be retrieved below in AddToFileValOrPars(). There is only 1 wResult no matter how many traces.
		endif

		// Add value to display. Converts value  into a key-value-pair string entry to be added to the result file.  Also handles multiple wResult values as created (only) by fits.
		lstOlaNm	= stOlaNmLst( sSrc, nType, lstRESreg ) 												// e.g. Adc0Base  or  PoN1DcA0; PoN1DcT0;PoN1DcCo;			
		string  	sOnePair
		variable	nPars		= ItemsInList( lstOlaNm )	
		for ( nP = 0; nP < nPars; nP += 1 )
			sOlaNm	= StringFromList( nP, lstOlaNm )
		 	stSetElementOlaDisp( sOlaNm, index, wResult[ nType ][ nP ] )									// The  RESULT value is  always  added to the display wave. 
			if ( nPars == 1 )	// i.e. nP == 0
				sprintf  sOnePair, "%s%s%12.4lf" , sOLANm, ksSEP_EQ,  wResult[ nType ][ nP ]				// Base, Peak, Quot... all add just 1 value 
			else
				sprintf sOnePair, "%s%s%s%12.4lf", sOlaNm[ 0,5 ], stParName( nFitFunc, nP), ksSEP_EQ, wResult[ nType ][ nP ]	// xxxxDcay -> xxxxDc  so that  8 letters are generated e.g. Adc0DcT0  or PoN2DcA1 
			endif
			sLine		= AddListItem( sOnePair, sLine, ";" , Inf )		//  add the result to the value string which is written to the data file (was AddToFile()..)
		endfor

		sLine += stAddToFileBegOrEnd( sSrc, nType, stGetReg( sSrc, nType, cUSER, RLFT), lstRGBEG )	// But only if there is a name entry in the region  Beginning / End list this is added to the file. 
		sLine += stAddToFileBegOrEnd( sSrc, nType, stGetReg( sSrc, nType, cUSER, RRIG ), lstRGEND)	// This avoids storing meaningless region beginnings and ends e.g. for  'PQuot'					
	endfor

	// Step 8 : Write the result line  (Event, Block, .....Base, Peak, ...)
	if ( gbWriteMode )
		printf "\t\tOnlineAnalysis( p:%d  b:%d  f:%d )\t'%s' \r", pr, bl, fr, sLine	
		if ( gOLAHnd ) 
			fprintf gOLAHnd, "%s\r", sLine	
		endif	
	endif	

End


static Function	stRectangularIndex( wIO, n )
// Converts 'n'  (=linear successive index in line-oriented analysis region data) into  bigger linear index built of all  sources X  all regions (containing mostly gaps).
// The index  returned form  'RectangularIndex()'  is used to sort the unordered regions (as input by the user) into the order needed for analysis i.e.  base -> peak -> rtime, decay.
	wave  /T	wIO
	variable	n
	string  	sIOChanList	= IOChanList( wIO )
	variable	nPossibleIO	= ItemsInList( sIOChanList )
	string  	sSrc
	variable	nType
	stRegionSrcType( n, sSrc, nType )

	variable	nSrc			= WhichListItem( sSrc, sIOChanList )		
	variable	nRectIndex	= nSrc * MAXREG_TYPE + nType
	// printf "\t\t\t\tRectangularIndex( n:%d ) \tis %d  ( = nSrc:%d x nMaxReg:%d + nReg:%d ) , MaxRectIndex: %d (= %d x %d ) ,  sIOChanList:  '%s'  \r", n, nRectIndex, nSrc, MAXREG_TYPE, nType, MAXREG_TYPE * nPossibleIO,  MAXREG_TYPE, nPossibleIO, sIOChanList
	return	nRectIndex
End		

static Function	/S	stDefinedRegions()
// Returns a list containing all those regions which the user has specified . Needed to supply the appropriate list for the OLA analysis panel to be built .
	string  	sList	= ""
	string  	sSrc
	variable	nType
	variable	n, nItems	= stRegionCnt()
	for ( n = 0; n < nItems; n += 1 )
		stRegionSrcType( n, sSrc, nType )
		sList	= PossiblyAddListItem( stLongSrcRegNm( sSrc, nType ), sList )
	endfor	
	printf "\t\t\t\tDefinedRegions()    \tsList:  '%s'  \r", sList
	return	sList
End		


static Function	/S	stDefinedPkRegions()
// Returns a list containing all those regions which the user has specified . Needed to supply the appropriate list for the OLA analysis panel to be built .
	string  	sList	= ""
	string  	sSrc
	variable	nType
	variable	n, nItems	= stRegionCnt()
	for ( n = 0; n < nItems; n += 1 )
		stRegionSrcType( n, sSrc, nType )
// 060511b
//		if ( nType == rgPEAK  ||  nType == rgPEA2  )
		if ( nType == rgPEAK  ||  nType == rgPEA2   ||  nType == rgPEA3  )
			sList	= PossiblyAddListItem( stLongSrcRegNm( sSrc, nType ), sList )
		endif	
	endfor	
	 printf "\t\t\t\tDefinedPkRegions()  \tsList:  '%s'  \r", sList
	return	sList
End		


static Function	/S	stDefinedRsRegions()
// Returns a list containing all those regions which the user has specified . Needed to supply the appropriate list for the OLA analysis panel to be built .
	string  	sList	= ""
	string  	sSrc
	variable	nType
	variable	n, nItems	= stRegionCnt()
	for ( n = 0; n < nItems; n += 1 )
		stRegionSrcType( n, sSrc, nType )
		if (  nType == rgRISE  )
			sList	= PossiblyAddListItem( stLongSrcRegNm( sSrc, nType ), sList )
		endif	
	endfor	
	 printf "\t\t\t\tDefinedRsRegions()  \tsList:  '%s'  \r", sList
	return	sList
End		


static Function	/S	stDefinedDcRegions()
// Returns a list containing all those regions which the user has specified . Needed to supply the appropriate list for the OLA analysis panel to be built .
	string  	sList	= ""
	string  	sSrc
	variable	nType
	variable	n, nItems	= stRegionCnt()
	for ( n = 0; n < nItems; n += 1 )
		stRegionSrcType( n, sSrc, nType )
		if ( nType == rgDECAY )
			sList	= PossiblyAddListItem( stLongSrcRegNm( sSrc, nType ), sList )
		endif	
	endfor	
	 printf "\t\t\t\tDefinedDcRegions()  \tsList:  '%s'  \r", sList
	return	sList
End		


static Function	/S	stActiveResults()
// Returns a list containing all those results which could be computed as the user had specified the required region. 
// Needed to supply the appropriate list of results for the OLA analysis panel to be built not with all but only with possible result items.
	string  	sList	= ""

	//  REGION - RESULT - CONNECTION - SPECIFIC  2
	string  	sSrc
	variable	nType
	variable	n, nItems	= stRegionCnt()
	// Display in the panel first all  results.....
	for ( n = 0; n < nItems; n += 1 )
		stRegionSrcType( n, sSrc, nType )
		sList	= PossiblyAddListItem( stOla_NmLst( sSrc, nType, lstRESreg ), sList )	// Displays names with spaces in the panel. The spaces are automatically removed when referencing variables, waves or controls
	endfor	
	// printf "\t\t\t\tActiveResults()  \t\tsList:  '%s'  \r", sList
	return	sList
End		


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

static Function	stNewElementOlaDisp( sOLANm, index )
//  Add  a new element to  any entry type  ( e.g 'Event' ,  'Time' , 'Blck' , 'Adc0Base', ...of display wave .
// Returns  TRUE  if a new wave has just been constructed,  FALSE if a point has been added to an existing wave
	string  	sOLANm
	variable	index
	variable	value	= Nan
	wave  /Z	wOlaDisp	 =	$stFolderOlaDispNm( sOLANm ) 			// Check if the fixed result  OLA waves (=Event...Tim_) have already been defined. Checking  just 'Evnt' is sufficient, ...
	if ( ! waveExists( wOlaDisp ) )								// ...if this wave has not been defined  the others 'Blck' .. 'Tim_'  have neither been defined : build them all
		make /O /N= (index)	$stFolderOlaDispNm( sOLANm )  = value	// Nan hides points not yet computed  (not effective here as there are no points)
		// printf "\t\t\tNewElementOlaDisp() Building OLA Disp waves    \t\tn:%2d    \tsOLANm:\t%s\t= %g    \r", index, pd(sOLANm,9), value 
		return	TRUE
	else
		Redimension  /N=( index ) wOlaDisp
		wOlaDisp[ index - 1 ]	= value
		// printf "\t\t\tNewElementOlaDisp() Redimensioning OLA waves \t\tn:%2d   \tsOLANm:\t%s\t= %g   \t  \r", index, pd(sOLANm,9), value
		return	FALSE
	endif
End

static Function	stSetElementOlaDisp( sOLANm, index, value )
//  Set any entry type  ( e.g 'Event' ,  'Time' , 'Blck' , 'Adc0Base', ...of display wave  to 'value' . Starting at 0 allows to use this wave as XAxis
	string  	sOLANm
	variable	index, value
	wave	wOlaDisp	= $stFolderOlaDispNm( sOLANm ) 	
	wOlaDisp[ index ] = value							
// printf "\t\t\tSetElementOlaDisp( %s    index:%d   value:%g  ) \r", sOLANm, index, value
End

static Function  /S	stAddToFileBegOrEnd( sSrc, nType, value, sList )
// Converts 'value'  into a key-value-pair string entry to be added to the result file  and returns this string.  By ignoring this  return string  we do not add  to file .
	string 	sSrc, sList
	variable	nType, value
	string  	sKeyValuePair	= ""
	if ( strlen( RemoveWhiteSpace( StringFromList( nType, sList ) ) ) )						// Only if there is a name entry in the region  beginning/end  list...
	  	string  	sOLANm	= stOla1Nm( sSrc, nType, sList ) 							// 
		sprintf   	sKeyValuePair, "%s%s%12.4lf;" , sOLANm, ksSEP_EQ, value				//...we add  e.g.  Base Begin,  Peak End  (Quot has no Begin/End)
		// printf "\t\t\tAddToFileBegEnd( %s, %d ) adds '%s' \r", sSrc, nType, sKeyValuePair 
	endif
	return	sKeyValuePair
End


//static Function  /S	AddToFileValOrPars( sSrc, nType, value, sList )
//// Converts 'value'  into a key-value-pair string entry to be added to the result file  and returns this string.  Also handles multiple wResult values. By ignoring this  return string  we do not add  to file .
//	string 	sSrc, sList
//	variable	nType, value
//
//  	string  	sOLANm	= Ola1Nm( sSrc, nType, sList ) 							// Used for the keywords in the file and for the result wave names
//	string  	sValue = "",  lstKeyValuePairs	= ""
//	if ( nType == rgRISE  ||   nType == rgDECAY )
//		wave	wResult		= $(csFOLDER_OLA_PAR + "wResult" )							// Decay  or  Rise  adds all fit parameters
//		wave  /T	wNm		= $(csFOLDER_OLA_PAR + "wNm" )
//		variable	n, nPars	= numPnts( wResult )
//		for ( n = 0; n < nPars; n += 1 )
//			sprintf   	sValue, "%s%s%s%12.4lf" , sOLANm[ 0,5 ], wNm[ n ], ksSEP_EQ, wResult[ nRegTyp ][ n ]	// xxxxDcay -> xxxxDc  so that  8 letters are generated e.g. Adc0DcT0  or PoN2DcA1 
//			lstKeyValuePairs	= AddListItem( sValue, lstKeyValuePairs, ";" , Inf )		
//		endfor
//	else
//		sprintf   	lstKeyValuePairs, "%s%s%12.4lf;" , sOLANm, ksSEP_EQ, value				// Base, Peak, Quot... all add just 1 value 
//	endif
//	printf "\t\t\tAddToFileValOrPars( %s, %d ) adds '%s' \r", sSrc, nType, lstKeyValuePairs 
//	return	lstKeyValuePairs
//End


static Function	/S	stOla1Nm( sSrc, nType, sList )
// Converts source channel and result type  into  long  name  without spaces for the result waves  e.g.    'Adc1' + 'Base'   ->   'Adc1Base' , 'Adc0' + 'Dcay'  ->  'Adc0Dcay'
// Returns only 1 entry even for  fits (e.g. Decay and Rise) which have multiple parameters.  To be used for Region Beginning and End.
// Assumption : channel name must have 3 letters + 1 digit.  Flaw: works only for channels  0..9
	string		sSrc, sList
	variable	nType
	return	sSrc + StringFromList( nType, sList )						//    'Adc1' + 'Base'   ->   'Adc1Base' 
End

static Function	/S	stOlaNmLst( sSrc, nType, sList )
// Converts source channel and result type  into  long  name  without spaces for the result waves  e.g.    'Adc1' + 'Base'   ->   'Adc1Base' , 'Adc0' + 'PUBg'  ->  'Adc0PUBg'
// Assumption : channel name must have 3 letters + 1 digit.  Flaw: works only for channels  0..9
// Most regions (e.g. Base, Peak)  have 1 entry = 1 line,  but some regions ( e.g. Fits ) have multiple entries = multiple lines.
	string		sSrc, sList
	variable	nType
// 040730
	return	stOLAList( sSrc, nType, sList, "" )						// include no space in the name	   'Adc1' + 'Base'   ->   'Adc1Base' 
End


static Function	/S	stOla_NmLst( sSrc, nType, sList )
// Converts source channel and result type  into  long  name    with  spaces for the result waves  e.g.    'Adc1' + 'Base'   ->   'Adc1  Base' , 'Adc0' + 'PUBg'  ->  'Adc0  PUBg'
// Assumption : channel name must have 3 letters + 1 digit.  Flaw: works only for channels  0..9
// Most regions (e.g. Base, Peak)  have 1 entry = 1 line,  but some regions ( e.g. Fits ) have multiple entries = multiple lines.
	string		sSrc, sList 
	variable	nType
	return	stOLAList( sSrc, nType, sList, " " )						// include a space in the name for improved readability
End

static Function	/S	stOLAList( sSrc, nType, sList, sSep )
// Converts source channel and result type  into  long  name    (containing spaces  or not )   for the result waves  e.g.    'Adc1' + 'Base'   ->   'Adc1  Base' , 'Adc0' + 'PUBg'  ->  'Adc0  PUBg'
// Assumption : channel name must have 3 letters + 1 digit.  Flaw: works only for channels  0..9
// Most regions (e.g. Base, Peak)  have 1 entry = 1 line,  but some regions ( e.g. Fits ) have multiple entries = multiple lines.
	string		sSrc, sList , sSep
	variable	nType
	string		sOneName, sNameOrList	= ""
	if ( nType == rgRISE  ||  nType == rgDECAY )
		variable	nRadioIndex, nFitFncIndex
		string  	sControlNmBase, sParamNames		
		if ( nType == rgDECAY )
			sControlNmBase = ReplaceString( ":", "root:uf:aco:ola:DcFit" , "_" ) + "_" + sSrc + StringFromList( nType, lstRESreg )	// Build the radio button name withoul trailing index and count
			nRadioIndex	 = RadioButtonValueFromBaseNm( sControlNmBase )									// Get the radio button state
			nFitFncIndex	 = str2num( StringFromList( nRadioIndex, lstACTUALDECAYFIT ) )							// Convert to indices of the actual fit function, see FT_NONE = 0, FT_LINE = 1, FT_1EXP...
		endif
		if ( nType == rgRISE )
			// Get the radio button state
			sControlNmBase = ReplaceString( ":", "root:uf:aco:ola:RsFit" , "_" ) + "_" + sSrc + StringFromList( nType, lstRESreg )	// Build the radio button name withoul trailing index and count
			nRadioIndex	 = RadioButtonValueFromBaseNm( sControlNmBase )									// Get the radio button state
			nFitFncIndex	 = str2num( StringFromList( nRadioIndex, lstACTUALRISEFIT ) )							// Convert to  indices of the actual fit function, see FT_NONE = 0, FT_LINE = 1, FT_1EXP...
		endif
		sParamNames		= stParamNames( nFitFncIndex )
		variable	n, nPars	= ItemsInList( sParamNames )
		for ( n = 0; n < nPars; n += 1 )
			sOneName	= sSrc + sSep + StringFromList( nType, sList )[ 0, 1 ] + StringFromList( n, sParamNames )			// xxxxDcay -> xxxxDc  so that  8 letters are generated e.g. Adc0DcT0  or PoN2  DcA1 
			sNameOrList	= AddListItem( sOneName, sNameOrList, ";" , Inf )		
		endfor
	else
		sNameOrList	= sSrc + sSep + StringFromList( nType, sList )					//    'Adc1' + 'Base'   ->   'Adc1  Base'    OR    'Adc1Base'  , depending on   'sSep'  
	endif
	// print  "\t\t\t\tOLAList() :" , sNameOrList
	return	sNameOrList
End


static Function		stOLANmR( sOLANm, rsSrc, rnType, sList )
// Extracts source  (e.g. Adc1)  and  type (e.g. 0 for Base)  from  name string constructed  with  OlaNmLst() .  This name string  MUST NOT contain spaces as Ola_NmLst()  would insert.
// Improvement 1 :  could be made independent of  spaces , underscores etc.  by applying  'RemoveStringFromString().....
// Improvement 2 :  could also extract  Fit parameter e.g    PoN0DcT1	could extraxt  PoN0 ,  Decay   and   Tau1
// ??? searching is perhaps too slow???
	string		sOLANM, &rsSrc, sList
	variable	&rnType
	variable	n
	rsSrc		= sOLANm[ 0, 3 ]										// Assumption : 2  Four-letter-groups,  e.g.  Adc1Base    or  PoN0Peak...
	rnType	= WhichListItem( sOLANm[ 4, 7 ] , sList )						// if complete 4 letter  group ( Base, Peak...)  is found  then return that index...
	if ( rnType == kNOTFOUND )										// ...if not then it must be a combined 2 + 2 group used for fits e.g. DcA0   or RiT1
		for ( rnType = 0; rnType < ItemsInList( sList ); rnType += 1 )
			if ( cmpstr( StringFromList( rnType, sList )[ 0, 1 ],  sOLANm[ 4, 5 ] ) == 0 ) // compare 2 letters  (or supply a 2. 2-letter list e.g.  'Ba;Pe;Ba;Pe;Qu;RT;Ri;Dc'  and use WhichListItem()...) 
				break
			endif
		endfor
	endif
End



static Function	/S	stLongSrcRegNm( sSrc, nReg )
// Converts source channel and region type  into  long  name for the  panel entries  e.g.    'Adc1' + 'Base'   ->   'Adc1  Base'
//  Works in conjunction with    ExtractTraceAndRegType( sControlNm, rTrc, rReg ). 
// Every region (RiseFit, DecayFit too!) has 1 entry = 1 line.
	string		sSrc
	variable	nReg
	return	sSrc + " " + StringFromList( nReg, lstRGTYPE )
End

static Function	/S	stResultNm( sSrc )
	string		sSrc
	return	"Res" + sSrc						// returning  'sSrc'  alone crashes Igor ! ( Name conflict with acquis wave names?)
End

static Function	/S	stCrossXNm( sSrc, nReg, nStg )
	string		sSrc
	variable	nReg, nStg
	return	"X" + num2str( nStg ) + sSrc	+ StringFromList( nReg, lstRGTYPE )	
	//return	"CrossX" + num2str( nStg ) + sSrc	+ StringFromList( nReg, lstRGTYPE )	
End

static Function	/S	stCrossYNm( sSrc, nReg, nStg )
	string		sSrc
	variable	nReg, nStg
	return	"Y" + num2str( nStg ) + sSrc	+ StringFromList( nReg, lstRGTYPE )	
	//return	"CrossY" + num2str( nStg ) + sSrc	+ StringFromList( nReg, lstRGTYPE )	
End

static Function	/S	stFolderCrossNm( sCrossNm )
	string  	sCrossNm
	return   	csFOLDER_OLA_CROSS + sCrossNm
End

static Function	/S	stFolderOlaDispNm( sOLANm )
	string  	sOLANm
	return   	csFOLDER_OLA_DISP + sOLANm
End

static Function	/S	stFittedNm( sSrc, nReg, nStg )
	string		sSrc
	variable	nReg, nStg
	return	"Fit" + num2str( nStg ) + sSrc	+ StringFromList( nReg, lstRGTYPE )	
End

static Function	/S	stFolderFittedNm( sFittedNm )
	string  	sFittedNm
	return   	csFOLDER_OLA_FITTED + sFittedNm
End


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  ANALYSIS  FILE  FUNCTIONS

Function		FinishAnalysisFile_()
// Open Online analysis file,  write all accumulated data and close file
	// if no cUSER region is defined we skip the whole analysis file writing (this must be refined if there are analysis types requiring no cUSER region)
	if ( ! stAnalysisIsOn() )							
		return 0
	endif
	nvar		gOLAHnd		= root:uf:aco:ola:gOLAHnd
	if ( gOLAHnd != kNOT_OPEN_ )	
		Close	gOLAHnd
	endif
	gOLAHnd= kNOT_OPEN_
	return	0
End

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  ANALYSIS  EVALUATION  FUNCTIONS

static Function		stBaseVal( wIO, sSrc, nType, nBegPt, SIFact, Gain )
// Return the base Y value of the wave in the given interval. Average over the interval defined by user
// Display the range evaluated and the resulting value found in two boxes
// INTERmediary box :	X = user defined box,	Y = standard deviation of signal in this range
// cFINAL result  box :	X = user defined box,	Y = the evaluated base value
	wave  /T	wIO
	string 	sSrc
	variable	nType, nBegPt,  SIFact, Gain
	variable	PtLeft	= nBegPt + stGetReg( sSrc,  nType, cUSER,  RLFT ) / SIFact
	variable	PtRight	= nBegPt + stGetReg( sSrc,  nType, cUSER,  RRIG ) / SIFact
//	wave   	/Z	w = $sSrc
	wave   	/Z	w = $ksROOTUF_ + ksfACO_ + ksF_IO_ + sSrc
// printf "\t\tBaseVal( %s\t) waveexists:%d   w1:%d \r", sSrc, waveExists(w), waveExists(w1)
	WaveStats   /Q /R	= ( PtLeft, PtRight )  w			// evaluate the user defined region and store the results IGORs global variables
	//variable 	BroadenY	= V_sdev / gain					// use the standard deviation of the evaluted interval and broaden the box to make it better visible 
	variable	value	= V_avg / gain

	// Draw cross
	stSetRegLoc( wIO, sSrc, nType, cFINAL, ( PtLeft   - nBegPt ) * SIFact ,  value , ( PtRight - nBegPt ) * SIFact,  	value )	// BroadenY makes a (usually tiny) vertical cross line which is an indicator of the average noise

	 printf "\t\t\tBaseVal(\tsSrc:\t%s\tnTp:%2d\t\t\tBg:\t%7d\tL:\t%7d\tR:\t%7d\tSIFact:\t%7.4lf\t -> \tVAL:\t%7.2lf\t \r",  pd(sSrc,8),  nType, nBegPt, PtLeft, PtRight, SIFact , value
	return		value							// the base value 
End

static Function		stPeakVal( wIO, sSrc, nRTyp, nBegPt, SIFact, Gain, BaseValue )
// Return the minimum or maximum   (or the larger of both)  Y value of the wave in the given interval. Average over some points to the right and to the left of the peak to reduce noise influence.
	wave  /T	wIO
	string 	sSrc
	variable	nRTyp, nBegPt, SiFact, Gain, Basevalue
	nvar		gnPeakAverMS	= root:uf:aco:ola:gnPeakAverMS					// Average over that time (including both sides of peak) to reduce noise influence on peak height
	nvar		gnPeakAverMS2	= root:uf:aco:ola:gnPeakAverMS2					// Average over that time (including both sides of peak) to reduce noise influence on peak height
	nvar		gnPeakAverMS3	= root:uf:aco:ola:gnPeakAverMS3					// 060511b

	variable	PtLeft		= nBegPt + stGetReg( sSrc,  nRTyp, cUSER,  RLFT ) / SIFact
	variable	PtRight		= nBegPt + stGetReg( sSrc,  nRTyp, cUSER,  RRIG )  / SIFact
	variable	HalfIntervalPts

	// 060406  
	if ( nRTyp == rgPEAK )
		HalfIntervalPts	= gnPeakAverMS   / 2  / SIFact / 1000
	elseif (  nRTyp == rgPEA2 )
		HalfIntervalPts	= gnPeakAverMS2 / 2  / SIFact / 1000
	elseif (  nRTyp == rgPEA3 )
		HalfIntervalPts	= gnPeakAverMS3 / 2  / SIFact / 1000	// 060511b
	endif
	// print HalfIntervalPts
	wave   	/Z	w= $ksROOTUF_ + ksfACO_ + ksF_IO_ + sSrc
 	// printf "\t\tPeakVal( %s\t) waveexists:%d   w1:%d \r", sSrc, waveExists(w), waveExists(w1)
	WaveStats   /Q	/R = ( PtLeft, PtRight )  w							// find the location of the MINIMUM within the user defined region and store it in V_minloc...
	variable	MinTimeFound	= ( V_minloc - nBegPt ) * SIFact				// ..but do not use the value at this location directly, because it is a noise minimum.
	variable	MaxTimeFound	= ( V_maxloc - nBegPt ) * SIFact				// ..but do not use the value at this location directly, because it is a noise minimum.
	// WaveStats    /R = ( MinTimeFound / SIFact + nBegPt - HalfIntervalPts,	MinTimeFound / SIFact + nBegPt + HalfIntervalPts )  w	// no /Q flag : print results
	WaveStats   /Q	/R = ( MinTimeFound / SIFact + nBegPt - HalfIntervalPts,	MinTimeFound / SIFact + nBegPt + HalfIntervalPts )  w
	variable	MinValue		= V_avg / gain
	variable	MinBroadenY	= V_sdev / gain							// use the standard deviation of the evaluted interval and broaden the box to make it better visible 
	// WaveStats   	/R = ( MaxTimeFound / SIFact + nBegPt - HalfIntervalPts,	MaxTimeFound / SIFact + nBegPt + HalfIntervalPts )  w
	WaveStats   /Q	/R = ( MaxTimeFound / SIFact + nBegPt - HalfIntervalPts,	MaxTimeFound / SIFact + nBegPt + HalfIntervalPts )  w
	variable	MaxValue		= V_avg / gain
	variable	MaxBroadenY	= V_sdev / gain							// use the standard deviation of the evaluted interval and broaden the box to make it better visible 

	variable	PkValue, PkTimeFound, PkBroadenY
	variable	nPkDir	= stGetReg( sSrc, nRTyp, cUSER, RMODE )
	nPkDir	= numType( nPkDir ) == kNUMTYPE_NAN ?  cPKDIRUP : nPkDir	// if the user defines a peak region and starts an acquis without first having opened the OLA panel and without...
	if ( nPkDir == cPKDIRUP )										//...having selected a peak direction the peak dir will be undefined (=Nan) . We then use the value 0 = first radio button.
		PkValue		= MaxValue
		PkTimeFound	= MaxTimeFound
		PkBroadenY	= MaxBroadenY
	elseif( nPkDir == cPKDIRDN )
		PkValue		= MinValue
		PkTimeFound	= MinTimeFound
		PkBroadenY	= MinBroadenY
	else		// ( nPkDir == cPKDIRBO )		// Peak both
	// The base value must be subtracted for deciding which is bigger , but it must NOT be subtracted in the display as we want to display the found peak superimposed to the trace  
		PkValue		= abs( MaxValue - BaseValue ) > abs( MinValue - BaseValue ) ? MaxValue : 		MinValue		// in 'Both' mode return that value which has the larger absolute value
		PkTimeFound	= abs( MaxValue - BaseValue ) > abs( MinValue - BaseValue ) ? MaxTimeFound : 	MinTimeFound	
		PkBroadenY	= abs( MaxValue - BaseValue ) > abs( MinValue - BaseValue ) ? MaxBroadenY : 	MinBroadenY	
	endif

	// Draw cross
	stSetRegLoc( wIO, sSrc, nRTyp, cFINAL, PkTimeFound,   PkValue, PkTimeFound,  PkValue )

	// printf "\t\t\tPeakVal(  \tsSrc:\t%s\tnTp:%2d\t%s\tBg:\t%7d\tL:\t%7d\tR:\t%7d\tSIFact:\t%7.4lf\t ->\tVAL:\t%7.2lf\tMi:\t%7.2lf\tMx:\t%7.2lf\tTi:\t%7.2lf\tTx:\t%7.2lf\tHIPts:\t%7d\tFndTm:\t%7.3lf\t  \r",  pd(sSrc,8),  nRTyp, pd(StringFromList(nPkDir, lstRGPKDIR),4), nBegPt, PtLeft, PtRight, SIFact , PkValue, MinValue, MaxValue, MinTimeFound, MaxTimeFound, HalfIntervalPts , PkTimeFound 
	return		PkValue										// the peak value slightly averaged to reduce noise influence
End


static Function		stRTimVal( wIO, sSrc, nType, nBegPt, SIFact, Gain, lowPercent, highPercent , base, peakFromExtraPeak )
// Return the rise time of a signal from  lowPercent to highPercent  (typ. 20..80) in the given interval.
// Needs rgBASE and rgPEAK from previous computation.
// Flaw: if region does not include 80 (or20%) point, NO peak is found. If regions includes both 80% points on both sides of peak the false 80% point may be taken. Solution: start exactly at peak............

	wave  /T		wIO
	string 		sSrc
	variable		nType, nBegPt, SIFact, Gain, lowPercent, highPercent, base, peakFromExtraPeak
	nvar			gnPeakAverMS		= root:uf:aco:ola:gnPeakAverMS				// Average over that time (including both sides of peak) to reduce noise influence on peak height
	nvar			gnPeakAverMS2	= root:uf:aco:ola:gnPeakAverMS2				// Average over that time (including both sides of peak) to reduce noise influence on peak height
	nvar			gnPeakAverMS3	= root:uf:aco:ola:gnPeakAverMS3				// 060511b

	variable		peak
	peak = peakFromExtraPeak									// use peak value previously detemined in an extra rgPEAK region evaluation
	//peak	  = PeakUpVal( sSrc, nTrc, rgPEAK,  nType,  nBegPt, SIFact, Gain )	// determine rgPEAK here by evaluation of the rgRTIM region 
	//peak = PeakUpVal( sSrc, rgPEAK,  rgPEAK,  nBegPt, SIFact, Gain )		// determine rgPEAK here by evaluation of the rgRTIM region 
	
	variable		PtLeft	= nBegPt + trunc( stGetReg( sSrc,  nType, cUSER,  RLFT ) / SIFact ) 	// truncation is necessary because the following rise time detection expects integers
	variable		PtRight	= nBegPt + trunc( stGetReg( sSrc,  nType, cUSER,  RRIG )  / SIFact )
	variable 		n
	wave   	/Z	w = $ksROOTUF_ + ksfACO_ + ksF_IO_ + sSrc
	// get the value at the  20% and 80% location
	variable		y20	= base + lowPercent    * ( peak - base ) / 100
	variable		y80	= base + highPercent  * ( peak - base ) / 100
	
	//  GOING   BACKWARDS  IN  TIME : Start at the peak (right border) and go back in time till 80% point is crossed, then on till 20 % point is crossed.. Terminate at this point . Going back in time is safer...
	// ...than going up because the part containing stimulus artefacts is avoided completely, even when the user does not set the evaluation region precisely.
	// Different approach (probably much slower, but probably also more precise: do a spline through all of the points on the rising edge (perhaps after some smoothing..)
	variable	Pt80	= Nan
	for ( n = PtRight; n > PtLeft; n -= 1 )									// GOING   BACKWARDS  IN  TIME  
		//if ( n / 100 == trunc( n / 100 )  )//     ||   ( n > 128950 && n < 129050  ) )
		//	printf "\t\tRTimVal()  PtLeft: \t%7d\t%7d\t%7d\t\twn:\t%7.2lf\t\tbs:\t%7.2lf\ty2:\t%7.2lf\ty8:\t%7.2lf\tpk:\t%7.2lf\t\twn-1:\t%7.2lf  \r", PtLeft, n,  PtRight, w[ n ], base, y20, y80, peak, w[ n - 1]
		//endif
		if ( ( w[ n-1 ] <= y80  &&  y80  < w[ n ] ) ||  ( w[ n ] <= y80  &&  y80  < w[ n-1 ] ) )	// check both directions,  Igor needs ( && ) || ( && )
			Pt80	= n - ( y80 - w[ n ] ) / ( w[ n-1 ] - w[ n ] )						// linear interpolation between the sample points
			// print  "PT80", PtLeft, n , PtRight, "->PT80:", PT80,  (PT80-nBegPt)* SIFact
			break												// terminating avoids possible false detection when signal decreases again (and saves time)
		endif
	endfor
	variable	Pt20	= Nan
	for ( n = PtRight; n > PtLeft; n -= 1 )									// GOING   BACKWARDS  IN  TIME  
		//if ( n / 100 == trunc( n / 100 )  )//     ||   ( n > 128950 && n < 129050  ) )
		//	printf "\t\tRTimVal()  PtLeft: \t%7d\t%7d\t%7d\t\twn:\t%7.2lf\t\tbs:\t%7.2lf\ty2:\t%7.2lf\ty8:\t%7.2lf\tpk:\t%7.2lf\t\twn-1:\t%7.2lf  \r", PtLeft, n,  PtRight, w[ n ], base, y20, y80, peak, w[ n - 1]
		//endif
		if ( ( w[ n-1 ] <= y20  &&  y20  < w[ n ]  ) ||  ( w[ n ] <= y20  &&  y20 < w[ n-1 ] ) )	// check both directions,  Igor needs ( && ) || ( && )
			Pt20	= n - ( y20 - w[ n ] ) / ( w[ n-1 ] - w[ n ] )						// linear interpolation between the sample points
			// print  "PT20",   PtLeft, n , PtRight, "->PT20:", PT20,  (PT20-nBegPt)* SIFact
			break												// terminating avoids possible false detection when signal decreases again (and saves time)
		endif
	endfor


	// 	// GOING  WITH  TIME : Go upwards from left border till 20% point is crossed, then on till 80 % point is crossed. Terminate at this point .
	// 	// get the time of the 20% and 80% points by  interpolating linearly between those sample points which surround the 20% and the 80% limit
	// 	// Different approach (probably much slower, but probably also more precise: do a spline through all of the points on the rising edge (perhaps after some smoothing..)
	//	for ( n = PtLeft; n < PtRight; n += 1 )									// GOING  WITH  TIME
	//		// if ( n / 100 == trunc( n / 100 )    ||   ( n > 11390 && n < 11410)  )
	//		//	printf "\t\tRTimVal()  PtLeft: \t%7d\t%7d\t%7d\t\twn:\t%7.2lf\t\tbs:\t%7.2lf\ty2:\t%7.2lf\ty8:\t%7.2lf\tpk:\t%7.2lf\t\twn+1:\t%7.2lf  \r", PtLeft, n,  PtRight, w[ n ], base, y20, y80, peak, w[ n + 1]
	//		//	printf "\t\tRTimVal()  PtLeft: \t%7d\t%7d\t%7d\t\twn:\t%7.2lf\t\ty2:\t%7.2lf\ty8:\t%7.2lf\t\twn+1:\t%7.2lf  \r", PtLeft, n,  PtRight, w[ n ], y20, y80, w[ n + 1]
	//		//endif
	//		if ((w[ n ] <= y20  &&  y20 < w[ n+1 ] )  ||  ( w[ n+1 ] <= y20  &&  y20 <  w[ n ] ))	// check both directions,  Igor needs ( && ) || ( && )
	//			Pt20	= n + ( y20 - w[ n ] ) / ( w[ n+1 ] - w[ n ] )					// linear interpolation between the sample points
	//			print  PtLeft, n , PtRight, "->PT20:", PT20,  (PT20-nBegPt)* SIFact
	//			break												// terminating avoids possible false detection when signal decreases again (and saves time)
	//		endif
	//	endfor
	//	for ( n = PtLeft; n < PtRight; n += 1 )									// GOING  WITH  TIME
	//		if ((w[ n ] <= y80  &&  y80 < w[ n+1 ] )  || ( w[ n+1 ] <= y80  &&  y80 <  w[ n ] ) )	// check both directions,  Igor needs ( && ) || ( && )
	//			Pt80	= n + ( y80 - w[ n ] ) / ( w[ n+1 ] - w[ n ] ) 
	//			print  PtLeft, n , PtRight, "->PT80:", PT80,  (PT80-nBegPt)* SIFact
	//			break												// terminating avoids possible false detection when signal decreases again (and saves time)
	//		endif
	//	endfor

	// for cFINAL visual control : store  the exact  20%  and  80%  locations
	stSetRegLoc( wIO, sSrc, nType, cFINAL, ( Pt20   - nBegPt ) * SIFact ,  y20, ( Pt80 - nBegPt ) * SIFact,  y80 )

	 printf "\t\t\tRTimVal()  \tPL:\t%7d\tP2:\t%7.0lf\ts2:\t%7.2lf\tP8:\t%7.0lf\ts8:\t%7.2lf\tPR:\t%7d\tYbase:\t%7.1lf\tY20=\t%7.1lf\tY80=\t%7.1lf \tYpeak:\t%7.1lf\tReturns %g   \r", PtLeft-nBegPt, Pt20, (Pt20-nBegPt)* SIFact, Pt80, (Pt80-nBegPt)* SIFact,  PtRight-nBegPt,  base, y20, y80, peak, ( y80 - y20 ) / ( Pt80 - Pt20 ) / SIFact
	return	( y80 - y20 ) / ( Pt80 - Pt20 ) / SIFact
End


static Function		stPQuotVal( sSrc, nRTyp, Peak1Value, Peak2Value )
	string 	sSrc
	variable	nRTyp, Peak1Value, Peak2Value
	variable	Quot	= Peak1Value / Peak2Value
	// printf "\t\t\tPQuotVal(  \tsSrc:\t%s\tnTp:%2d\t%s\tP1:\t%7.2lf\tP2:\t%7.2lf\tQu:\t%7.2lf\t  \r",  pd(sSrc,8),  nRTyp, pd(StringFromList(nRTyp, lstRGTYPE), 8) , Peak1Value, Peak2Value, Quot 
	return		Quot
End


static Function		stRiseOrDecayFit( wResult, sSrc, nRegTyp, nBegPt, SIFact, Gain, lstActualFit )
// Fit some functions (line, monoexp, biexp) to the decay  phase as defined by the user who has set the start and the end of the decay region.
// Return fitted params in a wave
// Display the fitted function
	wave	wResult
	string 	sSrc, lstActualFit
	variable	nRegTyp, nBegPt,  SIFact, Gain
	nvar		gOLADoFitOrStartVals= root:uf:aco:ola:gOLADoFitOrStartVals					// 1 : do fit,  0 : do not fit, display only starting values.  Can be set to 0  only in  debug mode in Test panel.
	string  	sMsg
	variable	Left		= stGetReg( sSrc,  nRegTyp, cUSER,  RLFT ) 
	variable	Right	= stGetReg( sSrc,  nRegTyp, cUSER,  RRIG ) 
	variable	PtLeft	= nBegPt + Left 	  / SIFact
	variable	PtRight	= nBegPt + Right / SIFact
//	wave   	/Z	w = $sSrc
	wave   	/Z	w = $ksROOTUF_ + ksfACO_ + ksF_IO_ + sSrc
	
	variable	nRadFitFunc		 = stGetReg( sSrc, nRegTyp, cUSER, RMODE )			// indexing of the radio buttons in the panel  is 0,1,2.. . This conversion could also be done earlier in 
	variable	nFitFunc			 = str2num( StringFromList( nRadFitFunc, lstActualFit ) )		// indices of the actual fit function, see FT_NONE = 0, FT_LINE = 1, FT_1EXP...
	variable	/G	root:uf:aco:ola:gFitFunc = nFitFunc									// Igor requires this to be global for FitMultipleFunctionsOLA but to be used only locally

	if ( nFitFunc != FT_NONE )
		string  	sFittedNm	= stFittedNm( sSrc, nRegTyp, cFINAL )
		string  	sFoFittNm	= stFolderFittedNm( stFittedNm( sSrc, nRegTyp, cFINAL ) )
		string  	sFitOrStart	= SelectString( gOLADoFitOrStartVals, "start vals", " fitting " )

		duplicate /O 	w  			root:uf:aco:ola:wFitted
		wave		wFitted  =	root:uf:aco:ola:wFitted
		
		variable	n, nPars	= ItemsInList(stParamNames( nFitFunc ) )
		make  /O 	/D /N=( nPars ) 	root:uf:aco:ola:wPar = 0							// ..or $(csFOLDER_OLA + "wPar" ) = 0	
		wave	/D 	wPar	   	= 	root:uf:aco:ola:wPar

		//  OLA :  SetStartParams(),  FuncFit FitMultipleFunctionsOLA  and  wFiited  work  with  POINTS
		stSetStartParams( wPar, w, PtLeft, PtRight, SIFact, nFitFunc )						// stores results in  wPar

		duplicate	/O 	wPar 		$(csFOLDER_OLA + "wStartPar" )				// The fit will overwrite  wPar  but  we want to keep the starting values ...
		wave		wStartPar	= 	$(csFOLDER_OLA + "wStartPar" )				// ...to check how good the initial guesses were.  See  PrintFitResults() below.  

		variable 	V_fitOptions = 4												// Bit 2: Suppresses the Curve Fit information window . This may speed things up a bit...

		if ( gOLADoFitOrStartVals == FALSE )

			FuncFit /O	/N /Q  FitMultipleFunctionsOLA,  wPar, w[ PtLeft, PtRight ] /D= wFitted // display only starting values, do not fit	

		else			
			variable	V_FitMaxIters	= 60										// used as an indicator whether the fit converged or not
			variable	V_FitNumIters		
			variable	V_FitError		= 0										// do not stop or break into the debugger when fit fails
			variable	V_FitQuitReason	
	
			FuncFit /N/Q/W=1 FitMultipleFunctionsOLA, wPar, w[ PtLeft, PtRight] /D=wFitted	// do the fitting

			if ( V_FitError )
				sprintf sMsg, "\tFit failed : V_FitError:%d, V_FitQuitReason:%d [Bit0..3:Any error,SingMat,OutOfMem,NanOrInf]", V_FitError, V_FitQuitReason	
				Alert( kERR_IMPORTANT,  sMsg )
			endif
		endif

		if ( ! gOLADoFitOrStartVals  ||  ! V_FitError )
			duplicate /O 	/R=[	PtLeft, PtRight ]  wFitted	 $sFoFittNm				// store the fitted segment which will be displayed
			SetScale /P X Left ,  SIFact, "", 		$sFoFittNm
		endif
		stPrintFitResults( wPar, wStartPar, nRegTyp, nFitFunc, V_FitError, V_FitNumIters, V_FitMaxIters, V_chisq )
	
	endif

	printf "\t\tRsDcFit( '%s'\tff:%d\t%s\tsSrc:\t%s\tnTp:%2d\tBg:\t%7d\tptL:\t%7d\t:%7.2lfs\tptR:\t%7d\t:%7.2lfs\tSIFact:\t%7.4lf\t->\tP0:\t%7.3lf\tP1:\t%7.3lf \t \r",  sFoFittNm, nFitFunc, pd( StringFromList( nFitFunc, ksFITFUNC ), 9 ),pd(sSrc,8),  nRegTyp, nBegPt, PtLeft, Left, PtRight, Right, SIFact , wResult[ nRegTyp][0],  wResult[ nRegTyp][1] 

	// Transfer  the fitted parameters into the array holding the computed values of each region  for this evaluation pass 
	for ( n = 0; n < nPars; n += 1 )
		wResult[ nRegTyp ][ n ] = wPar[ n ]
	endfor
	KillWaves	wPar, wStartPar, wFitted
	return	nFitFunc	
End


static Function	/S	stParamNames( nFitFunc )			
	variable	nFitFunc
	return	StringFromList( nFitFunc, ksPARNAMES, "~" )
End

static Function	/S	stParName( nFitFunc, nPar )	
	variable	nFitFunc, nPar
	return	StringFromList( nPar, StringFromList( nFitFunc, ksPARNAMES, "~" ) )
End

static	 Function		stParCnt( nFitFunc )
	variable	nFitFunc
	return	ItemsInList ( StringFromList( nFitFunc, ksPARNAMES, "~" ) )
End



static Function		stSetStartParams( wPar, w, PtLeft, PtRight, SIFact, nFitFunc )
	wave  	/D wPar
	wave	w
	variable	PtLeft, PtRight, SIFact, nFitFunc

	// printf "\tSetStartParams()  \tnFitFunc:%d  %s \tParams:%d  \r", nFitFunc, pd( StringFromList( nFitFunc, ksFITFUNC ),9), numPnts( wPar )

	if ( 	nFitFunc   == FT_LINE )				// 	straight line
		wPar[ 0 ] = w[ PtLeft ]  				// y value at left region border = intersection value with an y axis shifted to begin of region 
		wPar[ 1 ] = ( w[ PtRight ] - w[ PtLeft ] ) / ( PtRight - PtLeft )		// the slope

	elseif ( 	nFitFunc   == FT_1EXP )			// 	1 exponential  without constant		(LSLIB.pas : 21)
		wPar[ 0 ] = w[ PtLeft ] 				// y value at left region border = intersection value with an y axis shifted to begin of region 
		wPar[ 1 ] =  ( PtRight - PtLeft ) / 4 		// Tau

	elseif ( nFitFunc == FT_1EXPCONST )			//	1 exponential  	with	 constant		(LSLIB.pas : 20)
		wPar[ 0 ] = w[ PtLeft ] - w[ PtRight ]		// y value at left region border = intersection value with an y axis shifted to begin of region 
		wPar[ 1 ] =  ( PtRight - PtLeft ) / 4 		// Tau
		wPar[ 2 ] = w[ PtRight ]				// const offset 
		
	elseif ( nFitFunc == FT_2EXP )				//	2 exponentials without constant		(LSLIB.pas : 21)
		wPar[ 0 ] =  w[ PtLeft ] / 2				// y value at left region border = intersection value with an y axis shifted to begin of region 
		wPar[ 1 ] =  ( PtRight - PtLeft ) / 10 		// TauFast
		wPar[ 2 ] = wPar[ 0 ] 
		wPar[ 3 ] = wPar[ 1 ] * 5				// TauSlow

	elseif ( nFitFunc == FT_2EXPCONST )			//	2 exponentials  	with	 constant		(LSLIB.pas : 20)
		wPar[ 0 ] = ( w[ PtLeft ] - w[ PtRight ] ) / 2	// y value at left region border = intersection value with an y axis shifted to begin of region 
		wPar[ 1 ] =  ( PtRight - PtLeft ) / 10 		// TauFast
		wPar[ 2 ] = wPar[ 0 ] 
		wPar[ 3 ] = wPar[ 1 ] * 5				// TauSlow
		wPar[ 4 ] = w[ PtRight ] 				// const offset 


variable	RT2080	= 1		// TODO
variable	Amplitude	= 100	// TODO
// From Eval....
//	if ( 	ExistsEvT(  ch, rg, kE_RISE80 )    &&  ExistsEvT(  ch, rg, kE_RISE20 ) )
//		RT2080	= EvT( ch, rg, kE_RISE80 ) - EvT( ch, rg, kE_RISE20 )
//	elseif ( ExistsEvT(  ch, rg, kE_RISE80 )  &&  ExistsEvT(  ch, rg, kE_RISE50 ) )
//		RT2080	= 2 * ( EvT( ch, rg, kE_RISE80 ) - EvT( ch, rg, kE_RISE50 ) )
//	elseif ( ExistsEvT(  ch, rg, kE_RISE50 )  &&  ExistsEvT(  ch, rg, kE_RISE20 ) )
//		RT2080	= 2 * ( EvT( ch, rg, kE_RISE50 ) - EvT( ch, rg, kE_RISE20 ) )
//	else
//		RT2080	= 1
//		Alert( kERR_LESS_IMPORTANT,  "RT20/50/80 do not exist. Assuming 1" )				// can occur for multiple reasons e.g. 1.wrong region 2.mixed with artefact
//	endif
//	if (	ExistsEvY( ch, rg, kE_PEAK )   &&   ExistsEvY( ch, rg, kE_BAS1 ) ) 				// Amp	kE_BAS1 or kE_BAS2
//		Amplitude	= EvY( ch, rg, kE_PEAK )  - EvY( ch, rg, kE_BAS1 ) 
//		// print "amp OK",  EvY( ch, rg, kE_PEAK )  , EvY( ch, rg, kE_BAS1 )
//	else
//		Amplitude	= 100
//		Alert( kERR_IMPORTANT,  "Amplitude and/or Base value does not exist. Assuming 100" )	// should not occur as any region has min/max (serious warning, Level1)
//	endif

	elseif ( nFitFunc == FT_RISE )				//	Sigmoidal rise	  ~  I_K   with delay	(LSLIB.pas : 14)
		wPar[ 0 ] = RT2080
		wPar[ 1 ] = 0						// delay
		wPar[ 2 ] = Amplitude					// the measured amplitude	

	elseif ( nFitFunc == FT_RISECONST )			//	Sigmoidal rise	  ~  I_K   with delay and constant	(LSLIB.pas : 14)
		wPar[ 0 ] = RT2080
		wPar[ 1 ] = 0						// delay
		wPar[ 2 ] = Amplitude					// the measured amplitude	
		wPar[ 3 ] = 0						// const offset  

	elseif ( nFitFunc == FT_RISDEC )			//	Rise and Decay	  ~  I_Na with delay	(LSLIB.pas : 12,13)
		wPar[ 0 ] = RT2080
		wPar[ 1 ] = 0						// delay
		wPar[ 2 ] = Amplitude					// the measured amplitude	
		wPar[ 3 ] = 20//0					// tau in bits
		wPar[ 4 ] = 0					

	elseif ( nFitFunc == FT_RISDECCONST )		//	Rise and Decay	  ~  I_Na with delay and constant	(LSLIB.pas : 12,13)
		wPar[ 0 ] = RT2080
		wPar[ 1 ] = 0						// delay
		wPar[ 2 ] = Amplitude					// the measured amplitude	
		wPar[ 3 ] = 20//0					// tau in bits
		wPar[ 4 ] = 0						
		wPar[ 5 ] = 0						// const offset  

	endif
End

Function	FitMultipleFunctionsOLA( wPar, x ) : FitFunc			// Igor requires this not to be static
	wave	wPar
	variable	x
	variable	y
	nvar		nFitFunc	= root:uf:aco:ola:gFitFunc

	if ( 	nFitFunc   == FT_LINE )						// 	straight line
		y = wPar[ 0 ] +  x * wPar[ 1 ]

	elseif ( nFitFunc == FT_1EXP )						// 	1 exponential  without constant		(LSLIB.pas : 21)
		y = wPar[ 0 ]  * exp( - x  / wPar[ 1 ] ) 
	
	elseif ( nFitFunc == FT_1EXPCONST )					//	1 exponential  	with	 constant		(LSLIB.pas : 20)
		y = wPar[ 0 ]  * exp( - x / wPar[ 1 ] ) + wPar[ 2 ] 

	elseif ( nFitFunc == FT_2EXP )						//	2 exponentials without constant		(LSLIB.pas : 21)
		y = wPar[ 0 ]  * exp( - x / wPar[ 1 ] ) + wPar[ 2 ]  * exp( - x / wPar[ 3 ] )

	elseif ( nFitFunc == FT_2EXPCONST )					//	2 exponentials  	with	 constant		(LSLIB.pas : 20)
		y = wPar[ 0 ]  * exp( -x / wPar[ 1 ] ) + wPar[ 2 ]  * exp( - x / wPar[ 3 ] ) + wPar[ 4 ]


	elseif ( nFitFunc == FT_RISE )						//	Sigmoidal rise	  ~  I_K   with delay				(LSLIB.pas : 14)
		y =  exp( 4 * ln( 1 - exp( - ( x - wPar[ 1 ] ) / wPar[ 0 ] ) ) ) * wPar[ 2 ] 
		y = numType( y ) == kNUMTYPE_NAN  ?  0  : y

	elseif ( nFitFunc == FT_RISECONST )					//	Sigmoidal rise	  ~  I_K   with delay and constant	(LSLIB.pas : 14)
		y =  exp( 4 * ln( 1 - exp( - ( x - wPar[ 1 ] ) / wPar[ 0 ] ) ) ) * wPar[ 2 ] + wPar[ 3 ] 
		y = numType( y ) == kNUMTYPE_NAN  ?  0  : y

	elseif ( nFitFunc == FT_RISDEC )					//	Rise and Decay	  ~  I_Na with delay				(LSLIB.pas : 12,13)
		y =  exp( 3 * ln( 1 - exp( - ( x - wPar[ 1 ] ) / wPar[ 0 ] ) ) ) * ( wPar[ 2 ] * exp( - x / wPar[ 3 ] ) + wPar[ 4 ] )
		y = numType( y ) == kNUMTYPE_NAN  ?  0  : y

	elseif ( nFitFunc == FT_RISDECCONST )				//	Rise and Decay	  ~  I_Na with delay and constant	(LSLIB.pas : 12,13)
		y =  exp( 3 * ln( 1 - exp( - ( x - wPar[ 1 ] ) / wPar[ 0 ] ) ) ) * ( wPar[ 2 ] * exp( - x / wPar[ 3 ] ) + wPar[ 4 ] )  + wPar[ 5 ] 
		y = numType( y ) == kNUMTYPE_NAN  ?  0  : y
	endif
	return	y
End


static Function		stPrintFitResults( wPar, wStartPar, nRegTyp, nFitFunc, FitError, nIter, maxIter, chisq )
	wave  /D	wPar, wStartPar
	variable	nRegTyp, nFitFunc, FitError, nIter, maxIter, chisq
	variable		gPrintMask= 255
	variable	n
	if ( TRUE)//gPrintMask &  RP_FIT )
		string		sMsg, sFitResults = "", sStartPars = ""
		for ( n = 0; n < ItemsInList( stParamNames( nFitFunc ) ); n += 1 )
			sFitResults += stParName( nFitFunc, n ) + ": " + num2str( wPar[ n ] ) + "   "
			sStartPars  += stParName( nFitFunc, n ) + ": " + num2str( wStartPar[ n ] ) + "   "
		endfor
		if ( nIter == 0 )							// show start values, do not fit
			sprintf	sMsg, "No fit, start values : " 
		elseif ( nIter == maxIter ||  FitError )
			sprintf	sMsg, "It:%2d/%3d\t*** Failed ***" , nIter, maxIter
		else
			sprintf	sMsg, "It:%2d/%3d\tChi:%8.2g" , nIter, maxIter, chisq
		endif
		printf "\t\t\tFit(  %s )\t\t\tStartPars:\t%s \r",  pd( StringFromList( nFitFunc, ksFITFUNC ), 9), sStartPars	// print the starting values
		printf "\t\t\tFit(  %s )\t%s\t%s \r",  pd( StringFromList( nFitFunc, ksFITFUNC ), 9),  sMsg, sFitResults		// print the final fitted values
	endif
End


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//   ANALYSIS :  THE  REGIONS...
//
// wish list / flaws / todo: 
// - delete region in user window even if  does not belong to 'first'  trace especially if it is the only region
// - allow selection of trace in user window, use not  only 'first' trace
// - draw newly defined region not only in the window in which it  has been defined but in all (in all those containing the right trace)			
// - clear regions by clicking into it (sometimes in some windows they extend over the window border making it impossible to enclose them in a 'delete' region 
// - allow mouse modifier buttons (=CTRL,SHIFT) for redion definition not only in AUTO, but also in cUSER windows (->must modify hook function)


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//   ANALYSIS :  REGION  DEFINITION  CALLED  FROM  ACQUISITION  WINDOW  HOOK  (FPDISP.IPF)

Function		AutoWndAnalysis( wIO, sInfo, cursX, cursY, modifier )
// extracts region coordinates from mouse position,  does NOT use IGORs Marquee values
	wave  /T	wIO
	string 	sInfo
	variable	cursX, cursY, modifier
	variable	MouseX, MouseY, nType//, nTrc
	string   	sSrc
	nvar		gWaveY	= root:uf:aco:disp:gWaveY,   gWaveMin = root:uf:aco:disp:gWaveMin,  gWaveMax = root:uf:aco:disp:gWaveMax
	nvar		gPx	= root:uf:aco:disp:gPx,  gPy = root:uf:aco:disp:gPy,  gR1x = root:uf:aco:disp:gR1x,  gR2x = root:uf:aco:disp:gR2x,  gR1y = root:uf:aco:disp:gR1y,  gR2y = root:uf:aco:disp:gR2y
	svar		gsWndSel  = root:uf:aco:disp:gsWndSel
	string 	sWnd	= StringByKey(     "WINDOW", sInfo ) 

	//  Store globally the last recently clicked point
	Variable isMouseDown = StrSearch( sInfo, "EVENT:mousedown;", 	0 ) != kNOTFOUND
	Variable isMouseUp	  = StrSearch( sInfo, "EVENT:mouseup;", 	0 ) != kNOTFOUND

	if ( isMouseDown  &&  It_Is( modifier, STOREPOINT ) )
		printf "\tstoring mouse position in  analysis.[%d ] \r", modifier
		gPx		= CursX
		gPy		= CursY
		gsWndSel= sWnd		// store POINT-clicked window name for use in EraseOneRegion
	endif

	if ( isMouseDown  &&   ( It_Is( modifier, STOREBASE )  ||  It_is( modifier, STOREPEAK ) ) )
		// Obsolete...?
		// Get  MARQUEE REGION values as they must permanently be displayed in the statusbar
		// The position  values in the statusbar are updated when the mouse drag is finished.  
		//  If a truely continuous position value updating is required (but only while dragging!) here (in CursorMovedHook)..
		// ..the status bar would have to be redrawn (or Update or...or...)
	  	gR1x	= CursX
	  	gR1y	= CursY
	endif

	if ( isMouseUp  &&   ( It_Is( modifier, STOREBASE )  ||  It_is( modifier, STOREPEAK ) ) )
	  	gR2x	= CursX
	  	gR2y	= CursY
		nType	= stRegionTypeFromModifier( modifier )
		sSrc		= stGetTraceNameFromWnd( sWnd )
	 	printf "\tAutoWndAnalysis() %s   type:%d   '%s' \r", sWnd, nType, sSrc
	
		// Displays the changes in all  windows
		//DispClearOneTrcOneTyp( CLEAR, sSrc, nType, cUSER )	// 040724
		stSetRegLoc( wIO, sSrc, nType,  cUSER, min( gR1x, gR2x ), max( gR1y, gR2y ), max( gR1x, gR2x ), min( gR1y, gR2y ) )				
		//DispClearOneTrcOneTyp( DRAW, sSrc, nType, cUSER )
		stDispClearOneTrcOneTyp( sSrc, nType, cUSER )		// 040727

		// Get (and store globally)  the  Y  value of the wave at the cursor's  X  location
		//?todo : do not get  the first  wave, but (if there is more than one) get the one the cursor is on ... 
		wave		wv 			= WaveRefIndexed( "", 0, 1 )			// Returns first Y wave in the top graph.

//		variable /G 	gWaveY		= wv[ round( x2pnt( wv, CursX ) ) ]
//		// Get (and store globally) the minimum and the maximum  Y  value of the wave in the region given by marquee left...right
//		variable /G	gWaveMax	= WaveMax( wv,   gR1x, gR2x )
//		variable /G	gWaveMin	= WaveMin( wv,   gR1x, gR2x )
		gWaveY		= wv[ round( x2pnt( wv, CursX ) ) ]				//0409
		// Get (and store globally) the minimum and the maximum  Y  value of the wave in the region given by marquee left...right
		gWaveMax	= stWaveMaximum( wv,  gR1x, gR2x )
		gWaveMin	= stWaveMinimum( wv,   gR1x, gR2x )
	endif

	// printf  "\tCursorMovedHook() waveexists  %s   : %d   crsX:%.1lf   waveindex :%.1lf \r", sWaveNm, waveexists ($sWaveNm),  gCursX,  nWaveIndex
	// printf  "\tCursorMovedHook() sWnd:%s  moX:%3d \tmoY:%3d \tcX:%5.1lf\tcY:%5.1lf \treX:%.1lf ..%.1lf \twMin:%.1lf \twMax:%.1lf \twvY:%.1lf \r",sWnd, mouseX, mouseY, gCursX, gCursY, gR1x, gR2x, gWaveMin, gWaveMax, gWaveY 
End

Static Function	stRegionTypeFromModifier( modifier )
// return region index (=region type) for a given combination of pressed keys, but ignore mouse buttons  (see also 'It_is( Modifier, goal )' )
	variable	modifier				
	modifier = modifier &  (kSHIFT + kALT + kCTRL)	// mask out mouse button (=1)
	return	modifier == STOREBASE ? rgBASE : rgPEAK
	// return	modifier == STORERTIM ? rgRTIM : (modifier == STOREBASE ? rgBASE : rgPEAK )	// !( )
End

static Function	stWaveMinimum( w, left, right )		
// Returns min value of the specified wave in the specified range.
// The min ValDisplay control is tied to this function.
	Wave	w
	variable	left, right
	WaveStats /Q /R=( left, right ) w
	return V_min
End
	
static Function	stWaveMaximum(w, left, right)	
// Returns max value of the specified wave in the specified range.
// The wMax ValDisplay control is tied to this function
	Wave	w
	variable	left, right
	WaveStats /Q /R= ( left, right ) w
	return V_max
End



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//   ANALYSIS :  MARQUEE   REGION   CONTEXT  MENU  FUNCTIONS

// The following marquee context menu functions pop up automatically when the user finishes the marquee dragging.
// These functions allow the user to specify what is to be done with the selected region.
// Different approach: Let the user specify the purpose of the region before the region is selected by a group of radio...
// ..buttons in an extra 'Marquee mode'' panel . This is more  efficient if multiple regions of the same 'mode' are to  be selected.
 

// 040802 PROBLEM: these functions are executed also from ReadCfs/Eval  but in that context the following functions will fail ...
//... (e.g. GetWindowTNL tries to extract mode and range from the trace name)  

Function		Base() : GraphMarquee
	DefineRegion( rgBASE )
End

Function		Peak() : GraphMarquee
	DefineRegion( rgPEAK )
End

Function		Base2() : GraphMarquee
	DefineRegion( rgBAS2 )
End

Function		Peak2() : GraphMarquee
	DefineRegion( rgPEA2 )
End

// 060511b
Function		Base3() : GraphMarquee
	DefineRegion( rgBAS3 )
End
Function		Peak3() : GraphMarquee
	DefineRegion( rgPEA3 )
End


Function		PQuot() : GraphMarquee
	DefineRegion( rgPQUOT )
End

Function		RTim() : GraphMarquee
	DefineRegion( rgRTIM )
End

Function		Rise() : GraphMarquee
	DefineRegion( rgRISE )
End

Function		Decay() : GraphMarquee
	DefineRegion( rgDECAY )
End


Function		DefineRegion( nType )
	variable	nType							// rgBASE, rgPEAK, rgRTIM...
	string  	sFolder	= ksfACO
	wave  /T	wIO		= $ksROOTUF_ + sFolder + ":ar:wIO"  				// This  'wIO'  is valid in FPulse ( Acquisition )
	variable	nStage	= cUSER

	GetMarquee left, bottom
	if ( V_Flag )											// if a marquee is active...
	
		string 	sWnd	= WinName( 0, 1 )					// get the name of the active graph (where the user defined the marquee)
	
		string  	sTNm	= stGetTraceNameFromWndLong( sWnd )	// 040724 return full name including source, range, mode, instance
		variable 	nRange	= stGetRangeNrFromTrc( sTNm )			// 040724
		string  	sSrc		= StringFromList( 0, sTNm, " " ) 			// !!! Extract source. Depends on space as separator as defined in BuildMoRaNameInstance()
	
		printf "\t\tDefineRegion()  '%s'   nRange: %d   '%s'  \r",  sTNm, nRange, sSrc

		if ( nRange == cRESULT )										// 040724 Only Results (=the last PoN sweep) must be shifted as they are displayed not with their true time ...
			nvar		gResultXShift		= root:uf:aco:disp:gResultXShift			// ...but with a time offset so that they start at time Zero (Frame and Primary are displayed with true time which is time offset Zero
			stSetRegLoc( wIO, sSrc, nType, nStage, V_left + gResultXShift, V_top, V_right + gResultXShift, V_bottom)	// store the marquee coordinates
		else
			stSetRegLoc( wIO, sSrc, nType, nStage, V_left, V_top, V_right, V_bottom)	// store the marquee coordinates
		endif
	
		stDispClearOneTrcOneTyp( sSrc, nType, nStage )							// draw it
	
		GetMarquee	/K												// ..kill the marquee to make the frame disappear automatically
	
		string  	sPnOptions	= ":dlg:tPnOLADisp" 
		InitPanelOLADisp( sFolder, sPnOptions )								// necessary to display the changed panel state immediately
		UpdatePanel(  "PnOLADisp", "Online Analysis" , sFolder, sPnOptions )			// 040220 redraw the 'OLA Disp' Panel as the added new region makes more 'Results' possible (same params as in  ConstructOrDisplayPanel())
	endif

End


Function 		Cancel() : GraphMarquee
	GetMarquee	/K						// kill the marquee to make the frame disappear automatically
End


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//   ANALYSIS :  THE  REGION  IMPLEMENTATION		IMPLEMENTATION  AS  LIST   040224

Static Function		stRegionCnt()
// returns the number of regions which are currently defined
	wave  /T	wtAnRg	= root:uf:aco:ola:wtAnRg
	return	numPnts( wtAnRg )
End

Static Function		stRegionSrcType( n, rsSrc, rnRTyp )
// passes back the source string e.g. 'Adc1'   and the  region type  e.g.  '0'  for  'Base'   when   the index of the region is given
	variable	n
	string  	&rsSrc
	variable	&rnRTyp
	wave  /T	wtAnRg	= root:uf:aco:ola:wtAnRg
	string  	sAnRg	= wtAnRg[ n ]	
	string  	sSrcType	= StringFromList( 0, sAnRg )
	rsSrc				= sSrcType[ 0, 3 ]					// Assumption : sSrc has 3 letters + 1 digit 
	string  	sType	= sSrcType[ 4, Inf ]					// another assumption : all entries in lstRGTYPE have SAME length, then this is better :  rsSrc =  sSrcType[ 0 , strlen( sSrcType) - strlen( StringFromList( 0, lstRGTYPE ) ) ]
	rnRTyp			= WhichListItem( sType, lstRGTYPE )		
End

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//    ANALYSIS :  LITTLE  REGION  HELPERS		IMPLEMENTATION  AS  LIST   040224

strconstant		sMAXREG_ITEMSEPS	= ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;"		// at least  'MAXREG_ITEMS' separators, will be truncated to needed number
static constant		RTRC = 0,  RLFT = 1, RRIG = 2, RTOP = 3, RBOT = 4, RSHP = 5, RRED = 6, RGRN = 7, RBLU = 8, RMODE = 9,  MAXREG_ITEMS = 10
static strconstant	lstREG_ITEMS	= "Trace;Left;Right;Top;Bot;Shape;Red;Green;Blue;Mode;"

static Function	stSetRegLoc( wIO, sSrc, nReg, nStg, left, top, right, bot )
// HERE the region string is built
	wave  /T	wIO
	string  	sSrc	
	variable	nReg, nStg,  left, top, right, bot			
	wave  /T	wtAnRg	= root:uf:aco:ola:wtAnRg
	variable	nItems	= numPnts( wtAnRg )
	variable	nIndex	= stIndex( sSrc, nReg )					// the line in the text wave, e.g.  Adc0Peak    or   Adc1Base
	variable	nPos, nst, nShape							// the index in one line 	e.g.  User+RED    or   Final+LEFT 
	string  	sRadButVarNm
	if ( nIndex == kNOTFOUND )
		// The region does not yet exist so we build the complete string with the new  location coordinates but also including default colors etc.
		Redimension   /N=( nItems+1) wtAnRg	
		nIndex		= nItems
		string   sSeps	= sMAXREG_ITEMSEPS[ 0, MAXREG_ITEMS - 1 ] 		// build empty string list so that 'ReplaceListItem()' can insert entries at the right location
		wtAnRg[ nIndex ]	= stIdentifier( sSrc, nReg ) + ";"
		for ( nst = cUSER; nst < MAXREG_STAGE; nst+= 1 )
			wtAnRg[ nIndex ]	+= StringFromList( nst, lstRGSTAGE ) + sSeps 
		endfor

		for ( nst = cUSER; nst < MAXREG_STAGE; nst+= 1 )
			nPos	 = 1 + nst * ( MAXREG_ITEMS ) + RRED ;	wtAnRg[ nIndex ] 	= ReplaceListItem( stDefaultRegColor( nReg, nst, RRED ),	wtAnRg[ nIndex ] , ";",  nPos ) 
			nPos	 = 1 + nst * ( MAXREG_ITEMS ) + RGRN ;	wtAnRg[ nIndex ] 	= ReplaceListItem( stDefaultRegColor( nReg, nst, RGRN ),	wtAnRg[ nIndex ] , ";",  nPos ) 
			nPos	 = 1 + nst * ( MAXREG_ITEMS ) + RBLU ;	wtAnRg[ nIndex ] 	= ReplaceListItem( stDefaultRegColor( nReg, nst, RBLU ),	wtAnRg[ nIndex ] , ";",  nPos ) 
			nPos	 = 1 + nst * ( MAXREG_ITEMS ) + RSHP ;	wtAnRg[ nIndex ] 	= ReplaceListItem( stDefaultRegShape( nReg, nst ), 		wtAnRg[ nIndex ] , ";",  nPos )	// default setting for the region shape
	
			// Each radio button internally stores its last setting independently from clearing graphs or loading scripts. Thats why we must read the radio button  PeakDir setting and store it in wtAnRg.
			// If we do not adjust both then the OLA may analyse with a PeakDir setting different from that shown in the panel. (Both adjust once the user clicks a PeakDir radio button but this is too late).
			sRadButVarNm	= "root:uf:aco:ola:PkDir:" + StringFromList( 0, wtAnRg[ nIndex ] )
			nvar	/Z tmp	= $sRadButVarNm 
			 print "\t\t\tSetRegLoc()", sRadButVarNm , " = " , tmp , "[ nvar_exists:", nvar_exists( tmp ) , " ]"
			nPos	 = 1 + nst * ( MAXREG_ITEMS ) + RMODE;	wtAnRg[ nIndex ] 	= ReplaceListItem( 	num2str( tmp ) 		 ,			wtAnRg[ nIndex ] , ";",  nPos )	

			// Same applies to type of decay fit function
			sRadButVarNm	= "root:uf:aco:ola:DcFit:" + StringFromList( 0, wtAnRg[ nIndex ] )
// 060511d
//			nvar		tmp	= $sRadButVarNm 
			nvar	/Z tmp	= $sRadButVarNm 
			 print "\t\t\tSetRegLoc()", sRadButVarNm , " = " , tmp, "[ nvar_exists:", nvar_exists( tmp ) , " ]" 
			nPos	 = 1 + nst * ( MAXREG_ITEMS ) + RMODE;	 wtAnRg[ nIndex ] 	= ReplaceListItem( 	num2str( tmp ) ,					wtAnRg[ nIndex ] , ";",  nPos )	

			// Same applies to type of rise fit function
			sRadButVarNm	= "root:uf:aco:ola:RsFit:" + StringFromList( 0, wtAnRg[ nIndex ] )
// 060511d
//			nvar		tmp	= $sRadButVarNm 
			nvar	/Z tmp	= $sRadButVarNm 
			 print "\t\t\tSetRegLoc()", sRadButVarNm , " = " , tmp , "[ nvar_exists:", nvar_exists( tmp ) , " ]"
			nPos	 = 1 + nst * ( MAXREG_ITEMS ) + RMODE ; wtAnRg[ nIndex ] 	= ReplaceListItem( 	num2str( tmp ) ,					wtAnRg[ nIndex ] , ";",  nPos )	
	
		endfor
		// printf "\t\t\tSetRegLoc()  Index( sSrc: '%s' , nReg:%2d  , Stg:%2d ) new, constructing\twtAnRg[ %d ] : '%s'  \r", sSrc, nReg, nStg, nItems, wtAnRg[ nIndex ] 
	else
		// The region exists already so we change only the location coordinates but we leave all other settings as they are
		// printf "\t\t\tSetRegLoc()  Index( sSrc: '%s' , nReg:%2d , Stg:%2d ) exists as  \t\twtAnRg[ %d ] : '%s' \r", sSrc, nReg, nStg, nIndex, wtAnRg[ nIndex ] 
	endif
	nPos		= 1 + nStg * ( MAXREG_ITEMS ) + RLFT  ;	wtAnRg[ nIndex ] 	= ReplaceListItem( num2str( left ),   wtAnRg[ nIndex ] , ";" ,  nPos ) 
	nPos		= 1 + nStg * ( MAXREG_ITEMS ) + RRIG  ;	wtAnRg[ nIndex ] 	= ReplaceListItem( num2str( right ), wtAnRg[ nIndex ] , ";" ,  nPos ) 
	nPos		= 1 + nStg * ( MAXREG_ITEMS ) + RTOP ;	wtAnRg[ nIndex ] 	= ReplaceListItem( num2str( top ),   wtAnRg[ nIndex ] , ";" ,  nPos ) 
	nPos		= 1 + nStg * ( MAXREG_ITEMS ) + RBOT ;	wtAnRg[ nIndex ] 	= ReplaceListItem( num2str( bot ),   wtAnRg[ nIndex ] , ";" ,  nPos ) 

	// BUILDING  AND  DISPLAYING   REGIONS    by  using  waves
	// OBSOLETE.........Regions to be displayed as as RECTANGLES are now stored and their processing is now finished. Drawing  and possibly erasing then is later controlled by FPULSE and done by repeatedly calling 'DisplayRegion()'  
	// Regions constructed with waves (crosses, lines, rectangles) are now stored .  We define them here as waves and let IGOR update (=erase and redraw) them automatically . Calls to 'DisplayRegion()'  are still needed to adjust cross size to axis length. 
	// Design issue: Only defined regions have a  wave 'wCross' . Letting all regions having 'wCross' would probably be too slow when drawing.  The cross in defined regions can/could  be turned  OFF (=hidden) by setting its values to NaN 
	nShape	= str2num( stDefaultRegShape( nReg, nStg ) )
	// printf "\t\t\tSetRegLoc()  Index( sSrc: '%s' , nReg:%2d  , Stg:%2d )   Retrieved default shape %d (=%s)  \r", sSrc, nReg, nStg, nShape, StringFromList( nShape, lstRGSHAPE ) 
	if ( nShape != kHIDDEN )
		string  	sCrossXNm	= stCrossXNm( sSrc, nReg, nStg )
		string  	sCrossYNm	= stCrossYNm( sSrc, nReg, nStg )

		wave  /Z	wCrossX	=	$stFolderCrossNm( sCrossXNm )
		wave  /Z	wCrossY	=	$stFolderCrossNm( sCrossYNm )
		// printf "\t\t\tSetRegLoc()  Index( sSrc: '%s' , nReg:%2d , Stg:%2d )  wave '%s'  exists: %d         wave '%s'  exists:%d    Retrieved default shape %d (=%s)  \r", sSrc, nReg, nStg, sCrossXNm, waveExists( wCrossX ), sCrossYNm, waveExists( wCrossY ) , nShape, StringFromList( nShape, lstRGSHAPE ) 
		if ( ! waveExists( wCrossX ) ) 
			variable	nCrossPoints	= 5			 							//  SLOPE would need 9 points
			make	/O	/N=(nCrossPoints)	$stFolderCrossNm( sCrossXNm ) 	= Nan 	// Build the XY wave pair which is to be displayed as a cross, rectangle or line
			make	/O	/N=(nCrossPoints)	$stFolderCrossNm( sCrossYNm ) 	= Nan	// Nan prevents drawing of unused points 
			wave	wCrossX	=	$stFolderCrossNm( sCrossXNm )
			wave	wCrossY	=	$stFolderCrossNm( sCrossYNm )
			// printWave( "\t\t\tSetRegLoc()  Constructing \t" + sCrossXNm, wCrossX ) ; 	PrintWave( "\t\t\tSetRegLoc()  Constructing \t" + sCrossYNm, wCrossY )
		endif
	endif

	// BUILDING  AND  DISPLAYING  FITTED SEGMENTS    by  using  waves...
	// ...takes place elsewhere e.g. in RiseOrDecayFit()

	stSortRegions( wIO )

End


static Function	stSortRegions( wIO )
	wave  /T	wIO
	wave  /T	wtAnRg	= root:uf:aco:ola:wtAnRg
	variable	n, nItems	= numPnts( wtAnRg )				// = RegionCnt()
	make  /O	/W /N = ( nItems )	root:uf:aco:ola:wIndex
	make  /O	/W /N = ( nItems )	root:uf:aco:ola:wSortkey
	wave	wIndex	=	root:uf:aco:ola:wIndex
	wave	wSortkey	=	root:uf:aco:ola:wSortkey
	for	( n = 0; n < nItems ; n += 1 )
		wSortkey[ n ]	= stRectangularIndex( wIO, n )			// Fill the sortkey wave (according to which we will sort)  with the indices computed from  PossibleIOChannels x MAXREG (containing gaps)
	endfor										// At any time all items in this wave should already be sorted except for the last, for which we are just trying to find its place
	// PrintWave( "SortRegions (before)", wSortkey )			// Just for checking the sorting
	MakeIndex	wSortkey, wIndex 
	IndexSort		wIndex, wtAnRg 
	// for	( n = 0; n < nItems ; n += 1 )					// Just for checking the sorting...
	//	wSortkey[ n ]	= RectangularIndex( n )		
	//endfor										
	// PrintWave( "SortRegions ( after )", 	wSortkey )			//...
	KillWaves		wIndex, wSortkey		
End



static Function   /S	stDefaultRegColor( nType, nStage, nColor )
// Get and return the program supplied default colors by breaking the string list  'lstRGCOLOR' 
	variable	nType, nStage, nColor
	string  	sList	= StringFromList( nType , lstRGCOLOR )
	return	RemoveWhiteSpace( StringFromList( nColor - RRED, sList , "," ) )
End

static Function    /S	stDefaultRegShape( nType, nStage )
// Get and return the program supplied default region shape  by breaking the string list  'lstRGSHP' 
	variable	nType, nStage
	return	RemoveWhiteSpace( SelectString( nStage, StringFromList( nType, lstRGSHP_U ) , StringFromList( nType, lstRGSHP_F ) ) )
End


static Function		stSetRegion( sSrc, nReg, nStg, nRgItem, value )
	string  	sSrc	
	variable	nReg, nStg, nRgItem, value			
	wave  /T	wtAnRg	= root:uf:aco:ola:wtAnRg
	variable	nItems	= numPnts( wtAnRg )			// = RegionCnt()
	variable	nIndex	= stIndex( sSrc, nReg )			// the line in the text wave, e.g.  Adc0Peak    or   Adc1Base
	variable	nPos, nst, nShape					// the index in one line 	e.g.  User+RED    or   Final+LEFT 
	nPos		= 1 + nStg * ( MAXREG_ITEMS ) + nRgItem	 ;	wtAnRg[ nIndex ] 	= ReplaceListItem( num2str( value ),   wtAnRg[ nIndex ] , ";" ,  nPos ) 
End


static Function		stUnDefineReg( sSrc,  nType )
	string  	sSrc
	variable	nType
	wave  /T	wtAnRg	= root:uf:aco:ola:wtAnRg
	variable	n, nItems= numPnts( wtAnRg )
	variable	nIndex	= stIndex( sSrc, nType )
	if ( nIndex == kNOTFOUND )
		printf "Internal error:UnDefineReg()   Index( sSrc: '%s' , nType:%2d  (nItems:%d) )  which is to be deleted does not exist ... \r", sSrc, nType, nItems
	else
		for ( n = nIndex; n < nItems - 1; n += 1 )
			wtAnRg[ n ] = wtAnRg[ n + 1 ] 
		endfor	 
		Redimension   /N=( nItems - 1 ) wtAnRg	
		// printf "\t\t\tUnDefineReg()  Index( sSrc: '%s' , nType:%2d )  = %d  has been deleted. Entries decreased from  %d  ->  %d  \r", sSrc, nType, nIndex, nItems ,  numPnts( wtAnRg )
	endif
End

static Function	stbBothRegAreDefined( sSrc, nType )
	string  	sSrc
	variable	nType
	return	stIndex( sSrc, nType ) != kNOTFOUND
End


static Function		stGetReg( sSrc, nType, nStg, nItem )
	string  	sSrc
	variable	nType, nStg, nItem
	wave  /T  	wtAnRg = root:uf:aco:ola:wtAnRg
	variable	nItems	= numPnts( wtAnRg )
	variable	nIndex	= stIndex( sSrc, nType )	// the line in the text wave, e.g.  Adc0Peak    or   Adc1Base
	variable	value, nPos					// the index in one line 	e.g.  User+RED    or   Final+LEFT 
	if ( nIndex == kNOTFOUND )
		// printf "\t\t\t\tInternal error: The requested region ( nTrc:%2d , nType:%2d ) does not exist .  \r", nTrc, nType 
	else
		nPos		= 1 + nStg * ( MAXREG_ITEMS ) + nItem
		value	= str2num( StringFromList( nPos, wtAnRg[ nIndex ] ) )
		// printf "\t\t\t\tGetReg( sSrc: '%s' , nTyp:%2d, nItm:%2d  %s\t) retrieves \t%9.3lf  \t) from \twtAnRg[ %d ] : '%s'  \r", sSrc, nType, nItem, pd( StringFromList( nItem, lstREG_ITEMS),5), value, nIndex, wtAnRg[ nIndex ] 
	endif
	// printf "\t\t\tGetReg( \tTr:\t%d\tTp:\t%d\t%s\tSt:\t%d\t%s\tn:\t%d )\tvalue:\t %g\t \r", nTrc, nType, pd(StringFromList( nType, lstRGTYPE ),5),  nStg, pd(StringFromList( nStg, lstRGSTAGE ),5), nItem ,value
	return	value
End


static Function		stGetRgColor( sSrc, nType, nStage, rnRed, rnGreen, rnBlue )
	string  	sSrc 
	variable	nType, nStage, &rnRed, &rnGreen, &rnBlue
	rnRed	= stGetReg( sSrc, nType, nStage, RRED )
	rnGreen	= stGetReg( sSrc, nType, nStage, RGRN )
	rnBlue	= stGetReg( sSrc, nType, nStage, RBLU )
End


static Function		stGetRgLoc( sSrc, nType, nStage, rnLeft, rnTop, rnRight, rnBot )
	string  	sSrc 
	variable	nType, nStage
	variable	&rnLeft, &rnTop, &rnRight, &rnBot			
	rnLeft	= stGetReg( sSrc, nType, nStage, RLFT )
	rnTop	= stGetReg( sSrc, nType, nStage, RTOP )
	rnRight	= stGetReg( sSrc, nType, nStage, RRIG )
	rnBot  	= stGetReg( sSrc, nType, nStage, RBOT )
End


static Function		stGetRegion( rnLeft, rnTop, rnRight, rnBot )
	variable	&rnLeft, &rnTop, &rnRight, &rnBot
	GetMarquee left, bottom
	if ( V_Flag )											// if a marquee is active...
		rnLeft	= V_left
		rnTop	= V_top
		rnRight	= V_right
		rnBot	= V_bottom
		printf "\tGetRegion() GetMarquee is OK:  l:%d  r:%d  t:%d  b:%d \r", rnLeft, rnTop, rnRight, rnBot
	else
		printf "\tGetRegion() GetMarquee failed....\r"
	endif
End

static Function		stIndex( sSrc, nType )
	string  	sSrc	
	variable	nType
	wave  /T	wtAnRg	= root:uf:aco:ola:wtAnRg
	variable	n, nItems	= numPnts( wtAnRg )
	for ( n = 0; n < nItems; n += 1 )
		if ( cmpstr( StringFromList( 0, wtAnRg[ n ] ), stIdentifier( sSrc, nType ) )  == 0 )	// this trace-type-combination exists already
			// printf "\t\t\t\tIndex( sSrc:%s , nType:%2d ) exists as index n:%2d : '%s' \r", sSrc, nType, n, wtAnRg[ n ] 
			return	n
		endif
	endfor
	return	kNOTFOUND
End

static Function  /S	stIdentifier( sSrc, nType )
	string  	sSrc	
	variable	nType
	string  	sType	= StringFromList( nType, lstRGTYPE )
	return	sSrc + sType
End
	

static Function		stPrintRegions()
	wave  /T	wtAnRg	= root:uf:aco:ola:wtAnRg
	variable	n, nItems	= numPnts( wtAnRg )
	for ( n = 0; n < nItems; n += 1 )
		printf  "\t\tPrintRegions()  \t%d / %d \t'%s' \r", n, nItems, wtAnRg[ n ] 
	endfor  
End




static Function		stDispClearOneTrcOneTyp( sSrc, nType, nStage )
//Function		DispClearOneTrcOneTyp( nMode, sSrc, nType, nStage )
// works through all traces of all windows checking if a region has to be drawn : processes one stage of one type of one trace
	string  	sSrc
//	variable	nMode	// 040724
	variable	nType, nStage

	variable	w, wCnt, t, tCnt
	variable	nRange
	string 	sWNm, sTNm
	string 	sTrcNameList = "",  sTrcNameListMR = ""

	// printf "\tDispClr11...should %s  sSrc: '%s'   stage:%d \r", SelectString( nMode, "erase" , "draw"),  sSrc, nStage
	wCnt = WndCnt_()
	// Draw or Clear: Process all windows (only FIRST trace of each window is processed)
	for ( w = 0; w <  wCnt; w += 1 )
		sWNm	= WndNm_( w )
		sTrcNameList		= GetWindowTNL( sWNm, 0 )	//?? maybe too often ,  too slow......get TrcNameList  only ONCE ???	
		sTrcNameListMR	= GetWindowTNL( sWNm, 1 )	// includes mode and range
		// print "\tDispClr1Trc1Typ", sTrcNameList, sTrcNameListMR

		// Draw the regions belonging to the traces contained in this window 
		tCnt = ItemsInList( sTrcNameList )
		for ( t = 0; t < tCnt; t += 1 )						// all traces contained in this window sWnd
			sTNm 	= StringFromList( t, sTrcNameListMR )	// includes mode and range
			nRange	= stGetRangeNrFromTrc( sTNm )
			sTNm 	= StringFromList( t, sTrcNameList )		// only the source, without mode or range
			
			if ( cmpstr( sTNm, sSrc ) == 0 )
				// printf "\t\tDispClr11...%s\t%s  %d/%d  %s  [TNL:%s] \r", sWNm, SelectString( nMode, "erasing" , "drawing"), t, tCnt, sTNm, sTrcNameList

				if ( nStage != ALLSTAGES )
					//stDisplayRegion( sWNm, sSrc, nType, nStage, nMode, nRange ) 
					stDisplayRegion( sWNm, sSrc, nType, nStage, nRange ) 
				else
					variable	stg
					for (  stg = 0;  stg <  MAXREG_STAGE;  stg += 1 )
						//stDisplayRegion( sWNm, sSrc, nType, stg, nMode, nRange ) 
						stDisplayRegion( sWNm, sSrc, nType, stg, nRange ) 
					endfor
				endif

			else
				// printf "\t\tDispClr11...%s\t%s  %d/%d  %s   !=  %s  nTrc NOTHING DONE\r", sWNm, SelectString( nMode, "erasing" , "drawing"), t, tCnt, sTNm, sSrc
			endif
		endfor
	endfor
End


//Function		DispClearAllTrcAllTypAllStg( nMode )
//// works through all traces of all windows redrawing (or clearing) regions: processes all stages of all types of all traces
//	variable	nMode
//
//	variable	w, wCnt, t, tCnt, nType, nStage
//	variable	nRange
//	string 	sWNm, sTNm
//	string 	sTrcNameList = "" , sTrcNameListMR = ""
//	// printf "\tDispClrAAA  \r"
//
//	wCnt = WndCnt_()
//	// Draw or Clear: Process all windows (only FIRST trace of each window is processed)
//	for ( w = 0; w <  wCnt; w += 1 )
//		sWNm	= WndNm_( w )
//		sTrcNameList 		= GetWindowTNL( sWNm, 0 )	//?? maybe too often ,  too slow......get TrcNameList  only ONCE ???	
//		sTrcNameListMR	= GetWindowTNL( sWNm, 1 )	// includes mode and range
//
//		// print "\tDispClrAAA", sTrcNameList, sTrcNameListMR
//
//		// Draw the regions belonging to the traces contained in this window 
//		tCnt = ItemsInList( sTrcNameList )
//		for ( t = 0; t < tCnt; t += 1 )							// all traces contained in this window sWnd
//			sTNm 	= StringFromList( t, sTrcNameListMR )		// includes mode and range
//			nRange	= GetRangeNrFromTrc( sTNm )
//			sTNm 	= StringFromList( t, sTrcNameList )		// only the source, without mode or range
//			for ( nType = 0; nType <  MAXREG_TYPE; nType += 1 )
//				for (  nStage = 0;  nStage <  MAXREG_STAGE;  nStage += 1 )
//					//DisplayRegion( sWNm, sTNm, nType, nStage, nMode, nRange ) 
//					DisplayRegion( sWNm, sTNm, nType, nStage, nRange ) 
//				endfor
//			endfor
//		endfor
//
//	endfor
//End


//static Function		DeleteAllTrcAllTypAllStg()
//// Clearing second step: delete in data structure
//	wave  /T	wtAnRg	= root:uf:aco:ola:wtAnRg
//	Redimension   /N = 0 wtAnRg	
//End


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//    ANALYSIS :  BIG  REGION  HELPERS

// 040724   fragment  (to be extended to many traces...)
static Function	stGetRangeNrFromTrc( sTNm )
// Extracts  e.g. 'Adc0 RM5'  ->  'R'  ->  3
	string 	sTNm
	variable	nPosOfRg		= strlen( sTNm ) - 4				// !!! ASSUMPTION   the range letter is the 4. to last letter ( S,F,P,R)	
	string  	sRangeLetter	= sTNm[ nPosOfRg, nPosOfRg ] 	// !!! ASSUMPTION   last letter is SINGLE instance digit (count max to 9)
	// printf "\t\t\tGetRangeNrFromTrc(1).%s  -> '%s'  -> %d\r",  sTNm,  sRangeLetter, RangeNr_( sRangeLetter )
	return 	RangeNr_( sRangeLetter )
End



// could be incorporated in GetTraceNameFromWndLong()  , see below
static Function  /S	stGetTraceNameFromWnd( sWNm )
// Return the name of the (used) trace contained in window sWNm. If  there are multiple traces in sWNm (because the user already copied some)..
// ..a modal dialog box pops up requiring the user to specify the trace
	string 	sWNm
	string 	sThisWindowsTNL, sTNm = ""
	variable	t, tCnt
	// Extract traces from TWA. 	Different approach (not used): extract traces from Igors TraceNameList().  Disadvantage: There are multiple traces from which we have to extract the base name, and keep it only once
	sThisWindowsTNL = GetWindowTNL( sWNm, 0 )

	tCnt	= ItemsInList( sThisWindowsTNL )
	// printf "\tGetTraceNameFromWnd (%s)  tCnt:%d   ThisWindowsTNL:%s \r", sWNm, tCnt, sThisWindowsTNL
	if ( tCnt < 1 )
		Alert( kERR_IMPORTANT,  "Analysis region definition (or some other action) requires one distinct trace. This window contains no traces. " )
	elseif ( tCnt > 1)
		sTNm	= stTraceSelectModalDialog( sThisWindowsTNL )
	else
		sTNm	= StringFromList( 0, sThisWindowsTNL )
	endif
	// printf "\tGetTraceNameFromWnd()..%s . Returning '%s' .   ThisWindowsTNL:%s has %d traces \r", sWNm, sTNm, sThisWindowsTNL, tCnt	
	return	sTNm
End

// 040724
static Function  /S	stGetTraceNameFromWndLong( sWNm )
// Return the LONG name of the (used) trace contained in window sWNm which includes  mode, range and instance. 
// If  there are multiple traces in sWNm (because the user already copied some) a modal dialog box pops up requiring the user to specify the trace
	string 	sWNm
	string 	sThisWindowsTNL, sTNm = ""
	variable	t, tCnt
	// Extract traces from TWA. 	Different approach (not used): extract traces from Igors TraceNameList().  Disadvantage: There are multiple traces from which we have to extract the base name, and keep it only once
	sThisWindowsTNL = GetWindowTNL( sWNm, 1 )

	tCnt	= ItemsInList( sThisWindowsTNL )
	// printf "\tGetTraceNameFromWndLong (%s)  tCnt:%d   ThisWindowsTNL:%s \r", sWNm, tCnt, sThisWindowsTNL
	if ( tCnt < 1 )
		Alert( kERR_IMPORTANT,  "Analysis region definition (or some other action) requires one distinct trace. This window contains no traces. " )
	elseif ( tCnt > 1)
		sTNm	= stTraceSelectModalDialog( sThisWindowsTNL )
	else
		sTNm	= StringFromList( 0, sThisWindowsTNL )
	endif
	// printf "\tGetTraceNameFromWndLong()..%s . Returning '%s' .   ThisWindowsTNL:%s has %d traces \r", sWNm, sTNm, sThisWindowsTNL, tCnt	
	return	sTNm
End

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//    TRACE SELECT   PANEL

static Function   /S	stTraceSelectModalDialog( sTNL )
	string 	sTNL
	string 	sTrace = ""
	Prompt	sTrace, "Trace", popup, sTNL
	DoPrompt	"Select a trace", sTrace	
	if ( V_Flag )
		return	StringFromList( 0, sTNL )		// user canceled
	endif
	return	sTrace
End

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//    ANALYSIS :  REGION  DISPLAY

static Function		stDisplayRegion( sWnd, sSrc, nReg, nStg, nRange )
//static Function		DisplayRegion( sWnd, sSrc, nReg, nStg, nMode, nRange )
// Maintains the display of a marquee by  drawing a colored rectangle after the temporary marquee frame supplied by IGOR has been cleared by IGOR
// displays region in all windows which contain the trace  'sSrc'
// Drawing is not using graphical primitives but rather uses waves which are updated under Igor's control 

	string 	sWnd, sSrc
	variable	nReg, nStg							// rgBASE, rgPEAK...	
//	variable	nMode								// clear it  or  draw it.	
	variable	nRange								// Sweep, Frame, Primary or Result
	variable	nShape								// how the region is displayed: as an exact or small rectangle, as a trapezoid, a line...
	variable	rLeft, rTop, rRight, rBot, rRed, rGreen, rBlue
	nvar		gResultXShift		= root:uf:aco:disp:gResultXShift
	
	stGetRgColor( sSrc, nReg, nStg, rRed, rGreen, rBlue )
	stGetRgLoc( sSrc, nReg, nStg, rLeft, rTop, rRight, rBot )

	nShape = stGetReg( sSrc, nReg, nStg, RSHP )

	// printf "\t\t\t\tDisplayRegion(1) src:'%s'  nReg:\t%s\t(%d)\tstg=%d nShp:\t%s\t(%d)\t %s \tL:\t%7.2lf\tR:\t%7.2lf\tT:\t%7.2lf\tB:\t%7.2lf\tRange:%d\txsh:\t%7.2lf\t \r", sSrc, pd(StringFromList( nReg, lstRGTYPE),9) , nReg, nStg, pd(StringFromList( nShape, lstRGSHAPE),12), nShape, sWnd, rLeft, rRight, rTop, rBot, nRange, gResultXShift

	// Get axis end points  for those drawing  modes where rectangle or line is to be drawn over full Y range or below X axis
	if ( nShape == kRECTYFULL )
		GetAxis /Q  /W = $sWnd left						
		rTop	= V_max
		rBot	= V_min

	elseif ( nShape == kLINEHORZLONG )
		GetAxis   /Q /W = $sWnd  bottom						
		rLeft		=  V_min
		rRight	=  V_max
	elseif ( nShape == kCROSSSMALL )
		GetAxis   /Q /W = $sWnd  bottom						
		rLeft		-=  ( V_max - V_min ) * .06
		rRight	+= ( V_max - V_min ) * .06
		// print AxisInfo("","left")
		GetAxis   /Q /W = $sWnd left			// TODO:  this does NOT work under certain ? AUTOSCALE conditions				
		// GetAxis    /W = $sWnd left		 					
		rTop		+= ( V_max - V_min ) * .04
		rBot		-=  ( V_max - V_min ) * .04
	elseif ( nShape == kCROSSBIG )
		GetAxis /Q  /W = $sWnd left						
		rTop		+= ( V_max - V_min ) * .4
		rBot		-=  ( V_max - V_min ) * .4
		GetAxis /Q  /W = $sWnd  bottom						
		rLeft		-=  ( V_max - V_min ) * .4 
		rRight	+= ( V_max - V_min ) * .4

	elseif ( nShape == kRECTYBELOW )
		GetAxis /Q  /W = $sWnd left						
		rTop	= V_min - ( .025 + .015 * nReg ) * ( V_max -V_min )	// cover a narrow strip below X axis 
		rBot	= V_min - ( .028 + .015 * nReg ) * ( V_max -V_min )
	endif

	// printf "\t\t\t\tDisplayRegion(2) src:'%s'  nReg:\t%s\t(%d)\tstg=%d nShp:\t%s\t(%d)\t %s \tL:\t%7.2lf\tR:\t%7.2lf\tT:\t%7.2lf\tB:\t%7.2lf \r", sSrc, pd(StringFromList( nReg, lstRGTYPE),9) , nReg, nStg, pd(StringFromList( nShape, lstRGSHAPE),12), nShape, sWnd, rLeft, rRight, rTop, rBot				// draw the rectangle marking the selected region

	// BUILDING  AND  DISPLAYING  CROSS  REGIONS    by  using  waves
	// Regions to be displayed as as CROSSES	are now stored .  We define them here as waves and let IGOR update (=erase and redraw) them automatically . Calls to 'DisplayRegion()'  are  needed just once to append the wave ro the graph. 
	// This call is necessary only because  ALL traces (including the CROSS) are cleared  by  'EraseTracesInGraph()'   when 'Start'  or  'Apply'  is pressed.  It would be unnecessary if  the CROSSES were not erased there.
	string 	sTNL
	if ( nShape != kHIDDEN )
		sTNL			= TraceNameList( sWnd, ";", 1 )
		string  	sCrossYNm= stCrossYNm( sSrc, nReg, nStg )
		string  	sCrossXNm= stCrossXNm( sSrc, nReg, nStg )
		wave  /Z	wCrossX	=	$stFolderCrossNm( sCrossXNm )
		wave  /Z	wCrossY	=	$stFolderCrossNm( sCrossYNm )

		if (  waveExists( wCrossX )  &&   waveExists( wCrossY ) )

			if ( WhichListItem( sCrossYNm, sTNL ) == kNOTFOUND )							// Is the cross not yet displayed?  We must check Y component of cross, checking  X will not work
	
				AppendToGraph /W=$sWnd	wCrossY vs wCrossX
				ModifyGraph	 /W=$sWnd	rgb( $sCrossYNm )  =( rRed, rGreen, rBlue )			// the color from lstRGCOLOR

				if ( nRange == cRESULT )												// 040724
					ModifyGraph	 /W=$sWnd	offset( $sCrossYNm )  = { -gResultXShift, 0 }		// 040724
				endif

				if ( nShape == kLINETHICK )	
					ModifyGraph  /W=$sWnd	 lsize( $sCrossYNm ) 	= 2							// fat line
				endif
				if ( nShape == kLINEEXACT )	
					ModifyGraph  /W=$sWnd	 mode( $sCrossYNm ) = 4							// line (default  is thin) and marker
					ModifyGraph  /W=$sWnd	 marker( $sCrossYNm ) = 1							// marker is 'X' 
				endif
				if ( nShape == kRECTEXACT || nShape == kRECTYFULL || nShape == kRECTYBELOW )	
					ModifyGraph  /W=$sWnd	 axisclip( left) = 2									// allow drawing outside (=below the bottom) axis 
					ModifyGraph  /W=$sWnd	 lsize( $sCrossYNm ) 	= 2							// fat line
				endif
				// printf "\t\t\tDisplayRegion() \tAppending to \t%s\t waves  \t%s\t  and  \t%s\t  \tTNL was: '%s'  \r" , pd( sWnd, 8), pd( sCrossXNm, 21), pd( sCrossYNm,21) , sTNL 
			endif
			// Fill the CROSS wave with the cross end points
			if ( nShape == kCROSSSMALL  ||  nShape == kCROSSBIG )
				wCrossX[ 0 ]  = rLeft; 			wCrossY[ 0 ]  = ( rTop+rBot )/2;	wCrossX[ 1 ] = rRight; 		wCrossY[ 1 ] = (rTop+rBot)/2	// horizontal line
				wCrossX[ 3 ]  = (rLeft+rRight)/2;	wCrossY[ 3 ]  =  rTop;			wCrossX[ 4 ] = (rLeft+rRight)/2; 	wCrossY[ 4 ] = rBot	 		// vertical line
			endif
			// Fill the  LINE  wave with the line end 
			if ( nShape == kLINETHICK  ||  nShape == kLINEEXACT  ||  nShape == kLINEHORZLONG )
				wCrossX[ 0 ]  = rLeft; 			wCrossY[ 0 ]  = rTop;			wCrossX[ 1 ] = rRight; 		wCrossY[ 1 ] =  rBot		
			endif
			if ( nShape == kRECTEXACT || nShape == kRECTYFULL || nShape == kRECTYBELOW )
				wCrossX[ 0 ]  = rLeft; 			wCrossY[ 0 ]  = rTop;			wCrossX[ 1 ] = rRight; 		wCrossY[ 1 ] =  rTop		
				wCrossX[ 2 ]  = rRight;		wCrossY[ 2 ]  = rBot;			wCrossX[ 3 ] = rLeft; 			wCrossY[ 3 ] =  rBot		
				wCrossX[ 4 ]  = rLeft;			wCrossY[ 4 ]  = rTop;			
			endif
			// printWave( "\t\t\tDisplayRegion() \t\tSetting value in \t" + sCrossXNm, wCrossX )	; 	PrintWave( "\t\t\tDisplayRegion() \t\tSetting value in \t" + sCrossYNm, wCrossY )
		else
			// printf "DisplayRegion() : cross waves  '%s'   ,  '%s'    do not exist  \r ",  FolderCrossNm( sCrossYNm ), FolderCrossNm( sCrossXNm )	// e.g. Base, Decay
		endif
	endif

	// BUILDING  AND  DISPLAYING  FITTED SEGMENTS    by  using  waves
	// Regions to be displayed as as Fitted segments must have been defined earlier, e.g. in RiseOrDecayFit().  As they are waves  IGOR updates (=erases and redraws) them automatically . 
	// Calls to 'DisplayRegion()'  are  needed ....????just once to append the wave ro the graph. 
	//...???... This call is necessary only because  ALL traces (including the CROSS) are cleared  by  'EraseTracesInGraph()'   when 'Start'  or  'Apply'  is pressed.  It would be unnecessary if  the ??????????...CROSSES were not erased there.
	if ( nShape == kFITTED ) 
		sTNL				= TraceNameList( sWnd, ";", 1 )
		string  	sFittedNm		= stFittedNm( sSrc, nReg, nStg )
		wave  /Z	wFittedSegment	= $stFolderFittedNm( sFittedNm )

		if (  waveExists( wFittedSegment ) )

			if ( WhichListItem( sFittedNm, sTNL ) == kNOTFOUND )							// Is the fitted segment not yet displayed?  
				AppendToGraph /W=$sWnd	wFittedSegment

				ModifyGraph	 /W=$sWnd	rgb( $sFittedNm )  =	( rRed, rGreen, rBlue )			// the color from lstRGCOLOR
				ModifyGraph	 /W=$sWnd	mode( $sFittedNm ) = 0						// 0 : lines, 2 : dots, 4 : lines and markers (fitted line may be hidden by org trace)

				if ( nRange == cRESULT )	// 040724
					ModifyGraph	 /W=$sWnd	offset( $sFittedNm )  = { -gResultXShift, 0 }	// 040724
				endif

				// printf "\t\t\tDisplayRegion() \tAppending to \t%s\t wave    \t%s\t  \t  \tTNL was: '%s'  \r" , pd( sWnd, 8), pd( sFittedNm, 21), sTNL 
			endif
		else
			printf "DisplayRegion() : fitted waves  '%s'    do not exist  \r ",  stFolderFittedNm( sFittedNm )	// e.g. Base, Peak, Quot
		endif
	endif
End


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function		DurAcqDrawRegion( sWNm, sSrc, nRange ) 
	string 	sWNm, sSrc
	variable	nRange
	// printf "\t\t\t\t\tDurAcqDrawRegion( '%s'  '%s'  ) \r", sWNm, sSrc  
	variable	nType=1, nStage = cUSER

	for ( nType = 0; nType <  MAXREG_TYPE; nType += 1 )
		if ( stbBothRegAreDefined( sSrc, nType ) )
			for ( nStage = 0; nStage <  MAXREG_STAGE; nStage += 1 )
				//DisplayRegion( sWNm, sSrc, nType, nStage, DRAW, nRange )
				stDisplayRegion( sWNm, sSrc, nType, nStage, nRange )
			endfor
		endif
	endfor
End

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//   ANALYSIS :  DIALOG  PANEL  FOR  DISPLAYING  ONLINE  ANALYSIS  RESULTS 

Function  		OLADispPanel()
	string  	sFo			= ksfACO
	string  	sPnOptions	= ":dlg:tPnOLADisp" 
	string  	sWin			= "PnOLADisp" 
	InitPanelOLADisp( sFo, sPnOptions )
	ConstructOrDisplayPanel(  sWin, "Online Analysis" , sFo, sPnOptions, 99, 90 )	// same params as in  UpdatePanel()
	PnLstPansNbsAdd( ksfACO,  sWin )
End

Function		InitPanelOLADisp( sFo, sPnOptions )
	string  	sFo, sPnOptions
	string		sPanelWvNm = ksROOTUF_ + sFo + sPnOptions
	variable	n = -1, nElements = 60					// many, at least 50 !
	make /O /T /N=(nElements) 	$sPanelWvNm
	wave /T	tPn			=	$sPanelWvNm

	n = PnControl(	tPn, n, 1, ON, 	"PN_CHKBOX", kVERT, 						"Regions",			"root:uf:aco:ola:cbReg",	stDefinedRegions(),	"Regions", 	"" , kWIDTH_NORMAL, sFo ) 
	//n = PnControl(	tPn, n, 2, ON, 	"PN_RADIO",	 kVERT,   					"Peak directions",		"root:uf:aco:ola:PkDir",		lstRGPKDIR,		"PeakRegions",   stDefinedPkRegions() , kWIDTH_NORMAL, sFo )	 // VERTICAL arrangement
	n = PnControl(	tPn, n, 2, ON, 	"PN_RADIO",  ItemsInList(lstRGPKDIR),		"Peak directions",		"root:uf:aco:ola:PkDir",		lstRGPKDIR,		"PeakRegions",   stDefinedPkRegions() , kWIDTH_NORMAL, sFo ) // HORIZONTAL arrangement
//	n = PnControl(	tPn, n, 2, ON, 	"PN_RADIO",  ItemsInList(lstRGPKDIR),		"Average peak over ms","root:uf:aco:ola:PkAvMs",	lstRGPKDIR,		"PeakRegions",   stDefinedPkRegions() , kWIDTH_NORMAL, sFo ) // HORIZONTAL arrangement

	// better realisation (more than 3..4 choices)  requires popup
	n = PnControl(	tPn, n, 2, ON, 	"PN_RADIO",  ItemsInList(lstRGRISEFIT),		"Rise fit",				"root:uf:aco:ola:RsFit",		lstRGRISEFIT,		"RiseRegions",    stDefinedRsRegions() , kWIDTH_NORMAL, sFo ) // HORIZONTAL arrangement
	n = PnControl(	tPn, n, 2, ON, 	"PN_RADIO",  ItemsInList(lstRGDECAYFIT),	"Decay fit",			"root:uf:aco:ola:DcFit",		lstRGDECAYFIT,	"DecayRegions", stDefinedDcRegions() , kWIDTH_NORMAL, sFo ) // HORIZONTAL arrangement

	// MUST be OFF : it is the user who must turn the checkbox on to see the results  or there will be a discrepancy between checkbox state and checkbox variable state 
	//n = PnControl(	tPn, n, 2, OFF, 	"PN_CHKBOX", kVERT,				"Display Results in window","root:uf:aco:ola:wa",		AnalysisWindows(),	"Results", 	  stActiveResults() , 		kWIDTH_NORMAL, sFo ) 	// VERTICAL arrangement
	n = PnControl(	tPn, n, 2, OFF, 	"PN_CHKBOX", ItemsInList(stAnalysisWindows()),"Display Results in window","root:uf:aco:ola:wa",  stAnalysisWindows(),"Results", 	  stActiveResults() , 		kWIDTH_NORMAL, sFo )	// HORIZONTAL arrangement

	n = PnControl(	tPn, n, 1, ON, 	"PN_RADIO",  ItemsInList( lstXPANEL_),		"X axis",				"root:uf:aco:ola:radXAxis",	lstXPANEL_,		"OLA X Axis", 	   "" , 				kWIDTH_NORMAL, sFo )	// HORIZONTAL arrangement
	n += 1;		tPn[ n ] 	=	"PN_CHKBOX;	root:uf:aco:ola:gbBlankPauses	;blank pauses"	

	n += 1;		tPn[ n ] 	=	"PN_SEPAR"
	n += 1;		tPn[ n ] 	=	"PN_SETVAR;	root:uf:aco:ola:gnPeakAverMS	;average peak   over ms; 	15; 	%.2lf ;.01,1000,0;	"			
	n += 1;		tPn[ n ] 	=	"PN_SETVAR;	root:uf:aco:ola:gnPeakAverMS2;average peak2 over ms; 	15; 	%.2lf ;.01,1000,0;	"			
	n += 1;		tPn[ n ] 	=	"PN_SETVAR;	root:uf:aco:ola:gnPeakAverMS3;average peak3 over ms; 	15; 	%.2lf ;.01,1000,0;	"	// 060511b		

	n += 1;		tPn[ n ] 	=	"PN_SEPAR"
	n += 1;		tPn[ n ] 	=	"PN_BUTTON;	buAddAnalysisWnd		;Add window;	| PN_BUTTON;	buRemoveAnalysisWnd ;Delete wnd;	| PN_BUTTON;	buClearAnalysisWnd		;Clear all"	// the title is deliberately made longer with spaces so that the  the window list above have enough width
	if ( ! kbIS_RELEASE )
		n += 1;	tPn[ n ] 	=	"PN_BUTTON;	buAnalPrintRegions	;Print regions"
		// n+=1;	tPn[ n ] 	=	"PN_BUTTON;	buEraseAllRegions		;Erase all regions"
	endif

	redimension  /N = (n+1)	tPn
End

Function		root_uf_aco_ola_cbReg( sControlNm, bValue )
// MUST HAVE SAME NAME AS VARIABLE. NAME MUST NOT BE LONGER !
	string  	sControlNm
	variable	bValue
	string  	rsFolderVarNmBase, rsOLANm, rsWNm
	ChkBoxVarNmExtractDim1( sControlNm, rsFolderVarNmBase, rsOLANm )	// Version1:  Hack the  source channel  and  peak type  out of control name  
	variable	rReg
	string  	rsSrc
	ExtractTraceAndRegType( rsOLANm, rsSrc, rReg )

	// displays changes in all  windows
	//DispClearOneTrcOneTyp( CLEAR, rsSrc, rReg, cUSER )	// 040724// clear it
	stUnDefineReg( rsSrc, rReg )
	Checkbox  $sControlNm, value = 1					// although the checkbox has just been turned OFF (also hiding it completely) we immediately turn it ON again internally (and invisibly), which avoids that it is re-shown in the OFF state when the user re-defines this region...
												// Flaw : ....this not an elegant solution .
	string  	sFolder		= ksfACO
	string  	sPnOptions	= ":dlg:tPnOLADisp" 
	InitPanelOLADisp( sFolder, sPnOptions )						// necessary to display the changed panel state immediately
	UpdatePanel(  "PnOLADisp", "Online Analysis" , sFolder, sPnOptions )	// redraw the 'OLA Disp' Panel as the deletion of regions makes  'Results' impossible  (same params as in  ConstructOrDisplayPanel1)
End

Function		root_uf_aco_ola_PkDir( sControlNm, bValue )
// Sample  action procedure  for 2dimensional   PnControl()  with Radio buttons 
	string  	sControlNm
	variable	bValue
	variable	nDirValue	= RadioButtonValue( sControlNm )
	string  	sOLANm	= RadioButtonExtractDim2Nm( sControlNm )			//  Version1: Hack the  source channel  and  peak type  out of control name  
	string 	rsSrc		= ""
	variable	rRTyp	
	ExtractTraceAndRegType( sOLANm, rsSrc, rRTyp )
	// printf "\tProc RADIO root_uf_aco_ola_PkDir( \tctrlNm:\t%s\tbVal:%d\tTitle:\t%s\t->\trsSrc:\t%s\t,\tRTyp:%d = '%s' \tRadio value is: %d  \r", pd(sControlNm,27), bValue,  pd( sOLANm, 13), rsSrc, rRTyp , StringFromList( rRTyp, lstRGTYPE), nDirValue
	stSetRegion( rsSrc, rRTyp, cUSER, RMODE, nDirValue )
End

Function		root_uf_aco_ola_RsFit( sControlNm, bValue )
// Sample  action procedure  for 2dimensional   PnControl()  with Radio buttons 
	string  	sControlNm
	variable	bValue
	variable	nRadioIndex	= RadioButtonValue( sControlNm )
	string  	sOLANm		= RadioButtonExtractDim2Nm( sControlNm )			//  Version1: Hack the  source channel  and  fit function  type  out of control name  
	string 	rsSrc			= ""
	variable	rRTyp	
	ExtractTraceAndRegType( sOLANm, rsSrc, rRTyp )
	// printf "\tProc RADIO root_uf_aco_ola_RsFit( \tctrlNm:\t%s\tbVal:%d\tTitle:\t%s\t->\trsSrc:\t%s\t,\tRTyp:%d = '%s' \tRadio value is: %d  \r", pd(sControlNm,27), bValue,  pd( sOLANm, 13), rsSrc, rRTyp , StringFromList( rRTyp, lstRGTYPE), nRadioIndex
	stSetRegion( rsSrc, rRTyp, cUSER, RMODE, nRadioIndex )	// The index of the radio button in the panel 0,1,2..  is stored.  One could also convert right here to the actual fit functions (see lstACTUALDECAYFIT)
	string  	sFolder		= ksfACO
	string  	sPnOptions	= ":dlg:tPnOLADisp" 
	InitPanelOLADisp( sFolder, sPnOptions )						// necessary to display the changed panel state immediately
	UpdatePanel(  "PnOLADisp", "Online Analysis" , sFolder, sPnOptions )	//  redraw the 'OLA Disp' Panel as the number and type of fit parameters (which are offered for display) depends on the changed fit function type
End
 
Function		root_uf_aco_ola_DcFit( sControlNm, bValue )
// Sample  action procedure  for 2dimensional   PnControl()  with Radio buttons 
	string  	sControlNm
	variable	bValue
	variable	nRadioIndex	= RadioButtonValue( sControlNm )
	string  	sOLANm		= RadioButtonExtractDim2Nm( sControlNm )			//  Version1: Hack the  source channel  and  fit function  type  out of control name  
	string 	rsSrc			= ""
	variable	rRTyp	
	ExtractTraceAndRegType( sOLANm, rsSrc, rRTyp )
	// printf "\tProc RADIO root_uf_aco_ola_DcFit( \tctrlNm:\t%s\tbVal:%d\tTitle:\t%s\t->\trsSrc:\t%s\t,\tRTyp:%d = '%s' \tRadio value is: %d  \r", pd(sControlNm,27), bValue,  pd( sOLANm, 13), rsSrc, rRTyp , StringFromList( rRTyp, lstRGTYPE), nRadioIndex
	stSetRegion( rsSrc, rRTyp, cUSER, RMODE, nRadioIndex )	// The index of the radio button in the panel 0,1,2..  is stored.  One could also convert right here to the actual fit functions (see lstACTUALDECAYFIT)
	string  	sFolder		= ksfACO
	string  	sPnOptions	= ":dlg:tPnOLADisp" 
	InitPanelOLADisp( sFolder, sPnOptions )						// necessary to display the changed panel state immediately
	UpdatePanel(  "PnOLADisp", "Online Analysis" , sFolder, sPnOptions )	// redraw the 'OLA Disp' Panel as the number and type of fit parameters (which are offered for display) depends on the changed fit function type
End

Function		ExtractTraceAndRegType( sSrcAndType, rsSrc, rType )
//  Relies on  naming convention used in  LongSrcRegNm( sSrc, nRes )
// and...Function  /S	Identifier( nTrc, nType )
	string  	sSrcAndType
	string  	&rsSrc
	variable	&rType
	rsSrc	= sSrcAndType[ 0, 3 ]										// Assumption :  naming convention
	string  	sTypeNm	= sSrcAndType[ 4, Inf ]
	rType	= WhichListItem( sTypeNm, lstRGTYPE )
	// printf "\t\t\t\tExtractTraceAndRegType()   \t%s\t%s\t%s\t%d \r", pd(sSrcAndType,22), pd( rsSrc,6), pd( sTypeNm,12),  rType
End


Function		root_uf_aco_ola_wa( sControlNm, bValue )
// Sample  action procedure  for 2dimensional   PnControl()  with  CheckBoxes 
// MUST HAVE SAME NAME AS VARIABLE. NAME MUST NOT BE MUCH LONGER !
// Sample : sControlNm  'root_uf_aco_ola_wa_Adc1Peak_WA0'  ,    boolean variable name : 'root:uf:aco:ola:wa:Adc1Peak_WA0'  , 	sOLANm: 'Adc1Peak'  ,  sWNm: 'WA0'
	string  	sControlNm
	variable	bValue
	string  	rsFolderVarNmBase, rsOLANm, rsWNm

	ChkBoxVarNmExtractDim2( sControlNm, rsFolderVarNmBase, rsOLANm, rsWNm )

	// This is just sample code to be commented out...
	// variable	val	=  ChkBoxValDim2( sControlNm )
	// printf "\tProc CHKBOX root_uf_aco_ola_wa( \tctrlNm: \t%s\tbVal:%d )    \t\t\t\tsOLANm:\t%s\tWnd:\t'%s'   val:%d \r\r", pd(sControlNm,27), bValue, pd(rsOLANM,12), rsWNm, val 
	// ...this is just sample code to be commented  out .

	
//	string 	sTrcOnNm	= rsFolderVarNmBase + "_" + rsOLANm + rsWNm		// split 'sOLANm'   e.g.  'Adc1Base'  or  'Adc0Peak'   into the source channel  string 'Adcn'  and  the index of the result
//	nvar 	  /Z	bTrcOn	 = $sTrcOnNm
//	 printf "\tProc (CHECKBOX)\tcontrol name (  '%s'  \tbValue: %d )    \t'%s' \texists: %d \tTrace '%s' \t in Wnd '%s'   is %s \r", sControlNm, bValue, sTrcOnNm, nvar_Exists( bTrcOn ), rsOLANm, rsWNm, SelectString( bTrcOn, "OFF" , "ON" )

	stDrawAnalysisWndTrace( rsWNm, rsOLANm )
	stDrawAnalysisWndXUnits( rsWNm )	
End


Function		root_uf_aco_ola_radXAxis( sControlNm, bValue )
// MUST HAVE SAME NAME AS VARIABLE
	// printf "\tProc (CHECKBOX)    control is '%s'    bValue:%d \r", sControlNm, bValue
	string  	sControlNm
	variable	bValue
	stRedrawAnalysisWndAllTraces()
End

static Function		stRedrawAnalysisWndAllTraces()
	variable	w, wCnt		= ItemsInList( stAnalysisWindows() )
	for ( w = 0; w < wCnt;  w += 1 )
		string  	sWNm	= StringFromList( w, stAnalysisWindows() )
		if ( WinType( sWNm ) == kGRAPH )
			string  	sTNL	= TraceNameList( sWNm, ";", 1 )
			variable	t,  tCnt	=  ItemsInList( sTNL ) 
			// printf "\t\tRedrawAnalysisWndAllTraces() \twnd:%s has %d traces   [TrcNmList: %s..] \r", sWNm, tCnt, sTNL[0,160]	
			for ( t = 0;  t < tCnt; t += 1 )	
				string  	sTrc		= StringFromList( t, sTNL ) 	
				stDrawAnalysisWndTrace( sWNm, sTrc )
			endfor
			stDrawAnalysisWndXUnits( sWNm )	
		endif
	endfor
End


Function		root_uf_aco_ola_gbBlankPauses( sControlNm, bValue )
// MUST HAVE SAME NAME AS VARIABLE
	string  	sControlNm
	variable	bValue
	// printf "\tProc (CHECKBOX)    control is '%s'    bValue:%d \r", sControlNm, bValue
	string  	lstOlaNm, sOLANm, sSrc, sEventNm	= "Evnt"					// Flaw / Assumption
	wave	wEvent		= $stFolderOlaDispNm( sEventNm ) 	
	variable	nType, n, nPts	= numPnts( wEvent )
	variable	nP, t , tCnt	= stRegionCnt()	

	if ( ! bValue )														// Fill the pauses = connect data points even during pauses....
		for ( t = 0;  t < tCnt; t += 1 )	
			stRegionSrcType( t, sSrc, nType )									// passed parameters are changed

			lstOlaNm	= stOlaNmLst( sSrc, nType, lstRESreg )						//  e.g. 'Adc1Base' , 'Adc0PkBg' . Used for the keywords in the file and for the result wave names
			for ( nP = 0; nP < ItemsInList( lstOlaNm ); nP += 1 )
				sOlaNm	= StringFromList( nP, lstOlaNm )
				wave	wOlaDisp	= $stFolderOlaDispNm( sOLANm ) 	
				for ( n = 0; n < nPts - 1; n += 1 )
					if ( numType( wOlaDisp[ n ] ) == kNUMTYPE_NAN )
						wOlaDisp[ n ]	= wOlaDisp[ n + 1] 						// Fill the pauses : reset the Nan Y value to that of the successor point...
						wEvent [ n ]	= wEvent[ n + 1 ]						//...reset the X value to that of  the successor point as a marker..   Done too often , once would be sufficient....						
					endif													// ..the event is changed not for the display but to have a marker which points must be restored
				endfor
			endfor
		endfor
	else			// bValue  = TRUE										// Blank the pauses...
		for ( t = 0;  t < tCnt; t += 1 )	
			stRegionSrcType( t, sSrc, nType )									// passed parameters are changed

			lstOlaNm	= stOlaNmLst( sSrc, nType, lstRESreg )						//  e.g. 'Adc1Base' , 'Adc0PkBg' . Used for the keywords in the file and for the result wave names
			for ( nP = 0; nP < ItemsInList( lstOlaNm ); nP += 1 )
				sOlaNm	= StringFromList( nP, lstOlaNm )
				wave	wOlaDisp	= $stFolderOlaDispNm( sOLANm ) 	
				for ( n = 0; n < nPts - 1; n += 1 )
					if ( wEvent [ n ] ==  wEvent[ n + 1 ] )							// These points are marked and must be restored
						wOlaDisp[ n ]	=  Nan								// Blank the pauses: first set the Y values to Nan ...
					endif							
				endfor
			endfor
		endfor
		for ( n = 0; n < nPts - 1; n += 1 )
			if ( wEvent [ n ] ==  wEvent[ n + 1 ] )								// These points are marked and must be restored
				wEvent [ n ]	=  wEvent[ n ] - 1 							// then set the X value to the value of the precessor point				
			endif							
		endfor
	endif	
End



static Function		stDrawAnalysisWndTrace( sWNm, sOLANm )
	string  	sWNm, sOLANm
	variable	rnType
	nvar		gbBlankPauses	= root:uf:aco:ola:gbBlankPauses
	nvar		nXAxis		= root:uf:aco:ola:radXAxis
	variable	nMode, Red, Green, Blue
	string  	sTraceInfo, sRGB, rsSrc
		
	if ( WhichListItem( sOLANm, TraceNameList( sWNm, ";", 1 ) )  !=  kNOTFOUND )	
		sTraceInfo	= TraceInfo( sWNm, sOLANm, 0 )						// The trace exists and the color and mode are retrieved directly form the trace (called when switching the X axis scaling)
		nMode	= NumberByKey( "mode(x)", sTraceInfo, "=" )
		sRGB	= StringByKey( 	"rgb(x)", 	sTraceInfo , "=" )[ 1, Inf ]			// 	discard the leading  (  with   which  sRGB starts 
	else
		stOLANmR( sOLANm, rsSrc, rnType, lstRESreg )						// The trace does not yet exist : use program supplied default colors and mode (called when first building the trace)
		nMode 	= 4												// 	4: connect and mark points with +, 3 : only markers +
		sRGB	= StringFromList( rnType, lstRESCOL )
	endif
	Red		= str2num( RemoveWhiteSpace( StringFromList( 0, sRGB, "," ) ) )
	Green	= str2num( RemoveWhiteSpace( StringFromList( 1, sRGB, "," ) ) )		
	Blue		= str2num( RemoveWhiteSpace( StringFromList( 2, sRGB, "," ) ) )	

	variable	bTrcOn	= ChkboxValFromString2Dim( "root:uf:aco:ola:wa", sOLANm, sWNm )
	// printf "\t\t\tDrawAnalysisWndTrace( %s\t%s\tnRes: %d )   Rgb:\t%7d\t%7d\t%7d\t  Mode: %d    \t'%s' \tTrace is %s\tXAxis:%d BlankP:%d  \r", sWNm, pd( sOLANm,9),  rnType, Red, Green, Blue, nMode, "root:uf:aco:ola:wa:" + sOLANm + "_" + sWNm,  SelectString( bTrcOn, "OFF" , "ON" ), nXAxis, gbBlankPauses


	// The waves to be appended must exist already to avoid an error so we  check their existence. They will not exist before the user started the first acquisition.
	// Another approach: Disable/grey the checkboxes until the waves exist. This seems cumbersome for the code and also for the user.   

// Flaw: If the user checks this checkbox before the 1. acquis then the analysis results will not automatically be displayed. For this to happen the user must again uncheck/check the button after acquis start.

	wave  /Z	wOlaDisp	= 	$stFolderOlaDispNm( sOLANm ) 	 				
	if ( waveExists( wOlaDisp ) )
		RemoveFromGraph  /Z  /W=$sWNm		$sOLANm  					// remove unconditionally, no error if the wave has just been defined and there is no trace with that name 
		variable	n, nPts	= numPnts( wOlaDisp )
		if ( bTrcOn )
			string  	sEvntSecMin	= StringFromList( nXAxis, lstRESfix_ )
			wave   /Z	wX			= $stFolderOlaDispNm( sEvntSecMin )			//  X  AXIS  is  frames, seconds or minutes
			if ( waveExists( wX ) )
				AppendToGraph /W=$sWNm	wOlaDisp vs  wX
				ModifyGraph	/W=$sWNm	rgb( $sOLANm )		= ( Red, Green, Blue ) 
				ModifyGraph	/W=$sWNm	mode( $sOLANm )	= nMode 			// 4: connect and mark points with +, 3 : only markers +
			endif
		endif
	endif


// todo: only if window exists (or grey Panel options)
//	wave	wOlaDisp	= 	$stFolderOlaDispNm( sOLANm ) 	 				
//
//	RemoveFromGraph /Z  /W=$sWNm		$sOLANm  					// remove unconditionally, no error if there was no trace with that name  
//	variable	n, nPts	= numPnts( wOlaDisp )
//
//	if ( bTrcOn )
//		string  	sEvntSecMin	= StringFromList( nXAxis, lstRESfix_ )
//		wave   	wX			= $stFolderOlaDispNm( sEvntSecMin )			//  X  AXIS  is  frames, seconds or minutes
//		AppendToGraph /W=$sWNm	wOlaDisp vs  wX
//		ModifyGraph	/W=$sWNm	rgb( $sOLANm )		= ( Red, Green, Blue ) 
//		ModifyGraph	/W=$sWNm	mode( $sOLANm )	= nMode 			// 4: connect and mark points with +, 3 : only markers +
//	
//	endif
End


static Function		stDrawAnalysisWndXUnits( sWNm )
	string  	sWNm
	nvar		nXAxis	= root:uf:aco:ola:radXAxis
	string  	sXUnits	= StringFromList( nXAxis, lstXUNITS_ )				// As Igor does not plot units automatically in the XY mode (like in the normal mode using 'SetScale x ' )...
	TextBox /W=$sWNm /N=tbXAxis /C /A=MB /E=2  /F=0	/Y=0  sXUnits	//...we display the units  's' , 'frame', ... as a Textbox
End


Function		buAddAnalysisWnd( ctrlName ) : ButtonControl
	string 	ctrlName
	stAddAnalysisWnd()
End

Function		buRemoveAnalysisWnd( ctrlName ) : ButtonControl
	string 	ctrlName
	stRemoveAnalysisWnd()
End

Function		buClearAnalysisWnd( ctrlName ) : ButtonControl
	string 	ctrlName
	stClearAnalysisWnd()
End

Function		buAnalPrintRegions( ctrlName ) : ButtonControl
	string 	ctrlName
	stPrintRegions()
End


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  ANALYSIS 2 :  ONE TO ONE  ANALYSIS 
//  Each original data point gives a computed result point.  Simple examples realized  here  are   Average  and  Sum 
//  Features:
//  - one short and simple routine for each analysis which is easily integrated into the acquisition framework
//  - needs a keyword in the script (e.g. 'Aver'  or 'Sum' )
//  - works with complete wave,  windows are handled and displayed like 'Adc'  , 'Dac'  and 'PoN'
  
// removed 040123
//Function	ComputeAverage( pr, bl, fr, sw )		// 031008  !    NOT   REALLY PROTOCOL  AWARE		
//// a first dummy and test function for online evaluation
//	variable	pr, bl, fr, sw
//	variable	nIO		= kIO_AVER
//	variable	c, nChans	= ioUse( wIO, nIO )
//	variable	BegPt	= SweepBegSave( pr, bl, fr, sw )	
//	variable	EndPt	= SweepEndSave( pr, bl, fr, sw )
//	variable	nPts		= EndPt - BegPt
//	variable	AVERPTS	= 20 * ( 1 + 3 * c )		// arbitrary test averaging factor
//	string  	bf
//	for ( c = 0; c < nChans; c += 1 )						
//		// This implementation should be hidden in BreakIONm() <--> BuildIONm()
//		string 	sSrc		= ioList2( nIO, c, cIOSRC, 0 )
//		string 	sCh0	=  sSrc[0,2]  + sIOCHSEP +  sSrc[3,99] 		// Adc1 -> Adc_1
// 		string 	swResult	= "Aver" + sIOCHSEP + sSrc		// 
//		// print "\tComputeAverage( fr, sw )", sSrc, "=?=",  ios(  nIO, c, cIOSRC ), ios(  nIO, c, cIONAME ),  "sSrc.....", sSrc, sSrc[0,2], "+", sSrc[3,99],  "Aver"+sIOCHSEP + sSrc, "=?=", ios2s( "Aver", c, cIONM )
//
//		wave  /Z	wCh0	= $sCh0
//		// 12/18/02 here no checking necessary: has been done in CheckPresenceOfRequiredSrcChans()
////		if ( !waveexists( wCh0 ) )							// does the extracted channel exist ?
////			Alert( kERR_FATAL,  "The data channel '" + sCh0 + "' required by ' Aver" + ":  " + sSrc + "' is not provided in the script file. " ) 
////			return kERROR
////		endif	
// 		wave	wResult	= $swResult 
//		// waveform arithmetic:  target[ tbeg, tEnd ] = src[ sBeg - tBeg + p ]
//		wResult[ BegPt, BegPt+nPts ] = wCh0[  p ]	// copy current sweep Ch0 e.g. 'Adc' data to 'Aver'	
//		variable n
//		for ( n = BegPt; n < BegPt + nPts; n += 1)
//			wResult[ n ] = ( ( AVERPTS - 1 ) * wResult[ n - 1 ] + wResult[ n ] ) / AVERPTS //! uses Igor clipping	
//		endfor
//	endfor
//End

//Function	ComputeSum( pr, bl, fr, sw )		// 031008  !    NOT   REALLY PROTOCOL  AWARE		
//// a second dummy and test function for online evaluation
//	variable	pr, bl, fr, sw
//	variable	nIO		= kIO_SUM
//	variable	c, nChans= ioUse( wIO, nIO )
//	variable	BegPt	= SweepBegSave( pr, bl, fr, sw )	
//	variable	EndPt	= SweepEndSave( pr, bl, fr, sw )
//	variable	nPts		= EndPt - BegPt
//	string 	bf
//	for ( c = 0; c < nChans; c += 1 )						
//		// This implementation should be hidden in BreakIONm() <--> BuildIONm()
//		string  	sSrc 	= FldAcqioio( "Sum" , c, cIOSRC )
//		string  	sCh0	= ioList2( nIO, c, cIOSRC, 0 )
//		string  	sCh1	= ioList2( nIO, c, cIOSRC, 1 )
//		string  	swResult	= FldAcqioio( "Sum", c, cIONM )
//		sCh0	= sCh0[0,2]  + sIOCHSEP +  sCh0[3,99] 	// Adc1 -> Adc_1	
//		sCh1	= sCh1[0,2]  + sIOCHSEP +  sCh1[3,99] 	// Adc1 -> Adc_1	
//		// printf "\tComputeSum( fr, sw )   sSrc:'%s'   sSrcCh0:'%s'   sSrcCh1:'%s'   sSum:'%s'  \r", sSrc, sCh0, sCh1, swResult
//
//		wave  /Z	wCh0	= $sCh0
//		// 12/18/02 here no checking necessary: has been done in CheckPresenceOfRequiredSrcChans()
////		if ( !waveexists( wCh0 ) )							// does the extracted channel exist ?
////			Alert( kERR_FATAL,  "The data channel '" + sCh0 + "' required by 'Sum:" + sSrc + "' is not provided in the script file." )
////			return kERROR
////		endif	
//		wave  /Z	wCh1	= $sCh1
////		if ( !waveexists( wCh1 ) )
////			Alert( kERR_FATAL,  "The data channel '" + sCh1 + "' required by 'Sum:" + sSrc + "' is not provided in the script file." )
////			return kERROR
////		endif	
// 		wave	wResult	= $swResult
//		// waveform arithmetic:  target[ tbeg, tEnd ] = src[ sBeg - tBeg + p ]
//		wResult[ BegPt, BegPt+nPts ] = wCh0[  p ] + wCh1[ p ]
//	endfor
//End

//static Function   /S	ioList1( ioch, nData, nEntry )
//// extracts one comma separated entry from script line (given by ioch) and sSubKey (given by nData)  e.g. 'Src:Adc2,Dac1'
//// Constructed for  subkey  'Src'   but can be used generally
//// Entry can be any string , not only a number. As no error checking is done syntax errors, illegal spaces etc. are not caught
//	variable	ioch, nData, nEntry
//	string  	sEntries	= iosOld( ioch, nData )
//	variable	EntryCnt	= ItemsInList( sEntries, sPSEP )
//	string  	sOneEntry	= StringFromList( nEntry, sEntries, sPSEP )
//	// printf "\tioList1()...srcCh:%d/%d  '%s'    returning sFullName:'%s'  \r", nEntry, EntryCnt, sEntries, sOneEntry
//	return	sOneEntry
//End

//static Function   /S	ioList2( nIO, c, nData, nEntry )
//// extracts one comma separated entry from script line (given by nIO and c) and sSubKey (given by nData)  e.g. 'Src:Adc2,Dac1'
//	variable	nIO, c, nData, nEntry
//	return	ioList1( NioC2ioch( nIO, c ), nData, nEntry )
//End

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

