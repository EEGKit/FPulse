
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

static	  strconstant	ksSEP_EQ		= "="
static constant		kMAX_OLA_WNDS	= 3		// !!! for the OLA results : Also adjust the number of listbox columns   ->  see  'ListBox  lbSelectResult,  win = ksRES_SEL_OA,  widths  = xxxxx' 

static strconstant	ksRES_SEL_OA	= "LbResSelOA"


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  ANALYSIS 1 :  REDUCING  ANALYSIS 
//  Evaluation of  a number of original data points gives one result value.  Realized  here  are   'Base' , 'Peak'  and  'RTim'
//  Features:
//  - Elaborate routines...
//  - no keyword needed in the script , analysis is controlled by user defined regions and an  Analysis control panel

// 060321
//static  constant		FT_NONE = 0, FT_LINE = 1, FT_1EXP = 2, FT_1EXPCONST = 3, FT_2EXP = 4, FT_2EXPCONST = 5, FT_RISE = 6, FT_RISECONST = 7,  FT_RISDEC = 8, FT_RISDECCONST = 9, FT_MAXPAR = 10 
//static strconstant	ksFITFUNC	= "none;Line;1 Exp;1 Exp+Con;2 Exp;2 Exp+Con;Rise;Rise+Con;RiseDec;RiseDecCon"		
//static strconstant	ksPARNAMES	= "??~Co;Sl;~A0;T0;~A0;T0;Co;~A0;T0;A1;T1;~A0;T0;A1;T1;Co;~RT;De;Am;~RT;De;Am;Co;~RT;De;Am;Ta;TS;~RT;De;Am;Ta;TS;Co;~"		// must consist of 2 characters for the automatic name-building/extracting to work
//
//
//// ----------------------------  P E A K   D I R E C T I O N S  ------------------------------
//static constant		cPKDIRUP	= 0, 	cPKDIRDN	= 1, 	cPKDIRBOTH	= 2
//static  strconstant	lstRGPKDIR	= "Up;Down;Both;"	

//
//// ----------------------------  D E C A Y   F I T   F U N C T I O N S  ------------------------------
//static  strconstant	lstRGDECAYFIT	= "Line;Exp1C;Exp2;"								// the actual fit functions
//static strconstant	lstACTUALDECAYFIT= "1;3;4,"										// indices of the actual fit function, see FT_NONE = 0, FT_LINE = 1, FT_1EXP...
//
//// ----------------------------  R I S E   F I T   F U N C T I O N S  ------------------------------
//static  strconstant	lstRGRISEFIT		= "Line;Rise;RiseC;"								// the actual fit functions
//static strconstant	lstACTUALRISEFIT	= "1;6;7;"										// indices of the actual fit function, see FT_NONE = 0, FT_LINE = 1, FT_1EXP...
//

// ----------------------------  X   A X I S  S C A L I N G  ------------------------------

// ----------------------------  R E S U L T S   NEW ------------------------------ ( NO BLANKS ALLOWED )  -----------------------

// 060321
//static constant		cPROT= 0, cBLCK = 1, cFRAM = 2
//strconstant		lstRESpbf	= "Prot;Blck;Fram;"													// once for all channels,  value not to display but (probably) to file  
//// Once for every channel
//static  strconstant	lstRESreg	= "Base;Peak;Bas2;Pea2;PQuo;RTim;Rise;Dcay;" // Mean;RT28;Lat1;Lat2;HfDu;SlRD;SDBs" // once for every channel,	value to file  and  to display wave
//static  strconstant	lstRGBEG	= "BaBg;PkBg;B2Bg;P2Bg;	;RTBg;RiBg;DcBg;"								// once for every channel, write value to file  . Empty field: do not write to file
//static  strconstant	lstRGEND	= "BaEn;PkEn;B2En;P2En;	;RTEn;RiEn;DcEn;"								// once for every channel, write value to file  . Empty field: do not write to file  
//static  strconstant	lstRESCOL = "20000,65535,655350;	65535,0,10000;		10000,10000,65535;	55000,0,55000;			0,0,0;		20000,60000,20000;	59000,26000,5000;	55000,48000,0;		0,0,0;"
//
//// ----------------------------  R E G I O N S  ------------------------------
////static  strconstant	lstRGTYPE	= "Base;Peak;Bas2;Pea2;PQuo;RTim;Rise;Dcay;"								// Must be sorted in the order needed for analysis (=base>peak>rtim, rise,decay>pquot). This order is used in 'RectangularIndex()'  
//constant			rgBASE 			= 0,	  		rgPEAK	= 1,  		rgBAS2 = 2,  		rgPEA2 = 3, 		rgPQUOT = 4,		rgRTIM = 5,   		rgRISE = 6,   		rgDECAY = 7, 	MAXREG_TYPE = 8	// index into marquee / region data
////
//////							rgBASE  cyan		rgPEAK red		rgBAS2 blue		rgPEA2  magenta	rgPQUOT grey		rgRTIM  green		rgRISE  orange		rgDECAY yellow		
//	  strconstant 	lstRGCOLOR = "20000,58000,58000;	64000,5000,5000;	30000,30000,65535;	60000,25000,65535;	30000,30000,30000;	25000,65535,25000;	62000,28000,0;		55000,48000,0"	// User and final have the same color
//static  strconstant 	lstRGSHP_U = "	2		;		4		;		2		;		2		;		2		;		2		;		2		;		2		"	// User , index into lstRGSHAPE
////static  strconstant 	lstRGSHP_F  = "	5		;		7		;		5		;		7		;		0		;		4		;		9		;		9		"	// Final , index into lstRGSHAPE
////	
////strconstant		lstRGSTAGE = "User;Final"					
////static	 constant		cUSER	    = 0,	cFINAL	= 1,	MAXREG_STAGE	= 2			// refinement of searched region
////static constant		ALLSTAGES = -1
////
//strconstant		lstRGSHAPE = "hidden;Rect tall;Rect below;Rect user drawn;Line exact;Line thick;Line horz long;Cross small;Cross big;Fitted segment;"					
//static constant		kHIDDEN = 0,  kRECTYFULL = 1,  kRECTYBELOW = 2,  kRECTEXACT = 3, kLINEEXACT = 4, kLINETHICK = 5 , kLINEHORZLONG = 6, kCROSSSMALL = 7 , kCROSSBIG = 8, kFITTED = 9	// Cave: when changing also edit   lstRGSHP   manuallly. Default 0 should be 'kHIDDEN'.

//constant			CLEAR		= 0, 	DRAW	= 1


// Once for all channels
static constant		cEVNT = 0, cTIME = 1, cMINU = 2
strconstant		lstXPANEL = "frames;seconds;minutes;"					
strconstant		lstXUNITS	= "frame;s;minute"					
strconstant		lstRESfix	= "Evnt;Tim_;Minu;"													// once for all channels,  value to display and possibly to file . Do NOT use 'Time' instead of 'Tim_' 

constant			kNOT_OPEN	= 0
strconstant		sOLAEXT		= "ola"

static  strconstant	csFO_OLA			= "root:uf:acq:ola"		// the folder for evaluation and fit results
//static  strconstant	csFO_OLA_			= "root:uf:acq:ola:"		// the folder for evaluation and fit results
static  strconstant	csFOLDER_OLA_CROSS	= "root:uf:acq:ola:cross:"	// the folder for the cross or line displaying the evaluation result 
static  strconstant	csFOLDER_OLA_DISP	= "root:uf:acq:ola:disp:"	// the folder for the DISPLAY results
static  strconstant	csFOLDER_OLA_FITTED	= "root:uf:acq:ola:fit:"		// the folder for the fitted segments displaying the evaluation result 

strconstant		ksOR		= "or"						// Online Result  and   Online Regions  : The first 2 letters 'or'   ( of ' ors'  and  'org' )  are the beginning of trace name. They are used to exclude these traces from erasing
strconstant		ksORS		= "ors"						// Online Result .  Has 2 functions:  1.subfolder name and  2. the first 2 letters (must be 'or' ) are the beginning of trace name (used to exclude these traces from erasing)
strconstant		ksORG		= "org"						// Online Region.  Has 2 functions:  1.subfolder name and  2. the first 2 letters (must be 'or' ) are the beginning of trace name (used to exclude these traces from erasing)

// 060321  ??? combine this with 'eval:de'   ??? different indices here
//// 051212
// constant		 kOA_PH_LATC0=2,  kOA_PH_LATC1=3,  kOA_PH_FIT0=4,  kOA_PH_FIT1=5, kOA_PH_MAX=6
 constant	kOA_PH_BASE=0,  kOA_PH_PEAK=1, kOA_PH_MAX=6
// strconstant	lstOA_PHASES		= "Base;Peak;Latency0;Latency1;Fit0;Fit1;"			//  Cave :  lstOA_PHASES  and  the Marquee functions must match
 
 // Indexing for ChannelRegion Evaluation ( CN_BEG and  CN_END , CN_BEGY and  CN_ENDY  must be successive
  constant	  kOABE_BEG = 0,  kOABE_END = 1,  kOABE_MAX = 2
static strconstant	 ksOA_TP_TEXT	= "Beg;End;"


Function		CreateGlobalsInFolder_OLA()
// creates all folder-specific variables. To be used once from CreateGlobals() as the current data folder is changed and not restored

	NewDataFolder  /O  /S $"root:uf:" + ksF_ACQ_PUL		// make a new data folder and use as CDF,  clear everything 

	make /O 	    /N = ( kMAXCHANS, kRG_MAX, kOA_PH_MAX, kOABE_MAX  )	wCRegion	= nan		// region coordinates ...
	make /O 	    /N = ( kMAXCHANS, kRG_MAX, kE_RESMAX	 )			wOLARes	= nan		
// 5 is number of initial results: redimension.....todo	


// 051215 CODE FROM FEVAL.IPF
	make /O  	    /N = ( kMAXCHANS,  cMAX_MAGN )					wMagn		= 0		// for  x and y  shifting and expanding the view
	make /O  	    /N = ( cMAXCURRG ) 								wPrevRegion	= 0		// saves channel, region, phase and CursorIndex when moving a cursor so that this previous cursor can be finished when the user fast-switches to a new cursor without 'ESC' e.g. 'b' 'B'. 
	make /O  	    /N = ( cMAXCURRG ) 								wCurRegion	= 0		// saves channel, modifier and mouse location when clicking a window to remember the 'active' graph when a panel button is pressed
	make /O  	    /N = ( kMAXCHANS, kMM_XYMAX )					wMnMx		= TRUE	// maximum X and Y data limits  and   whether  the display should be  'Reset' to these limits

	make /O 	    /N = ( kMAXCHANS, kRG_MAX, kOA_PH_MAX, CN_MAX  )	wCRegion		= 1		// region coordinates, drawing environment, number of phases in each region, ...
	make /O 	    /N	 = ( kMAXCHANS, kRG_MAX, kE_RESMAX, kE_MAXTYP)	wEval		= Nan	// Nan means this coord could not be evaluated

// 060317d weg
//	string		/G 	lstChRgTyp	= ""
	

	NewDataFolder  /O  /S $csFO_OLA		// make a new data folder and use as CDF,  clear everything 

//051219b
//	variable	/G	gPrintMask		= 0
//	variable	/G	gnPeakAverMS		= .5				// Average over that time (including both sides of peak) to reduce noise influence on peak height
//	variable	/G	bBlankPause		= FALSE//TRUE			// Remove connecting lines in OLA graph when there is no experiment 
	variable	/G	gOLAFrmCnt		= 0				// frame counter for the OLA analysis
	variable	/G	gOLAHnd			= kNOT_OPEN
	variable	/G	gnStartTicksOLA	= 0
	variable	/G	gOLADoFitOrStartVals= TRUE			//  1 : do fit , 0 : do not fit, display only starting values.  Can be set to 0  only in  debug mode in Test panel.

//	make /O /T  /N = 0   wtAnRg	= ""					// the wave containing region information is built with size 0. One line is added whenever the user defines a new region.

	if ( ! kbIS_RELEASE )
//		gnPeakAverMS	= 2							// Average (for testing) over a long time (including both sides of peak) to reduce noise influence on peak height
	endif

	NewDataFolder  /O  /S $RemoveEnding( csFOLDER_OLA_CROSS )		// remove trailing ':'
	NewDataFolder  /O  /S $RemoveEnding( csFOLDER_OLA_DISP ) 		// remove trailing ':'
	NewDataFolder  /O  /S $RemoveEnding( csFOLDER_OLA_FITTED ) 		// remove trailing ':'

End

//=======================================================================================================================================================

// sFO depends on panel == pul  or separate ola 
Function		fDispRange( s )
	struct	WMCheckboxAction	&s
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	string  	sFo	 	= GetUserData( 	s.win,  s.ctrlName,  "sFo" )		// e.g.  'root:uf:acq:ola:' 
	string  	sSubDir	= ReplaceString( "root:uf:", sFo, "" )		  	// e.g.  'root:uf:acq:ola:' -> 'acq:ola:'
	string  	sFolders	= sSubDir + s.win

	variable	ch		= TabIdx( s.ctrlName )
	variable	rg		= BlkIdx( s.ctrlName )
	variable	mo		= RowIdx( s.ctrlName )
	variable	ra		= ColIdx( s.ctrlName )
	string  	lstRegs	= LstOARg()
	string  	sFolder	= ksACQ
	// printf "\t%s\t%s\t%s\t%s\t%s\t%s\tch:%d\trg:%2d\tmo:%s\tra:%s\twCnt:%2d\t  \r",  pd(sProcNm,13), pd(s.CtrlName,31), sFo, sSubDir, sFolder, sFolders,  ch, rg, StringFromList( mo, lstMODETXT, "," ),  StringFromList( ra, lstRANGETEXT, "," ), AcqWndCnt3()
	InitializeAutoWndArray3()

	wave  	wG		= $"root:uf:" + sFolder + ":" + ksKPwg + ":wG"  						// This  'wG'	is valid in FPulse ( Acquisition )
	wave  /T	wIO		= $"root:uf:" + sFolder + ":ar:wIO"  								// This  'wIO'	is valid in FPulse ( Acquisition )
	wave  	wFix		= $"root:uf:" + sFolder + ":ar:wFix"  								// This  'wFix'	is valid in FPulse ( Acquisition )
	BuildWindows( sFolder, wG, wIO, wFix, kFRONT )				//  Retrieve the Mode/Range-Color string  entries  and  build the (still empty) windows
//	EnableButton( "disp", "root_uf_acq_ola_PrepPrint0000", kENABLE )	// Now that the acquisition windows (and TWA) are constructed we can allow drawing in them (even if they are still empty)
End
Function	/S	DispRangeLst()
	return	lstRANGETEXT
End
Function		DispRange( ch, rg, mo, ra )
	variable	ch, rg, mo, ra
	nvar   	DispRange		= $"root:uf:acq:pul:cbDispRange" + num2str( ch ) + num2str( rg ) + num2str( mo ) + num2str( ra ) 
	// printf "\t\t\tDispRange( ch:%2d )   'root:uf:acq:pul:cbDispRangeCh%dRg%dMo%dRa%d returns %d \r", ch, rg, mo, ra, DispRange
	return	DispRange
End


Function	/S	DispModeLst()
	return	lstMODETXT
End




//Function 		fClearWindow( s )
//// Only for testing.  Normally traces are cleared  ONLY  by  resetting them in the listbox as only then the correspondence between traces in listbox / on screen / analysed  is maintained. 
//	struct	WMButtonAction  &s
//	ClearWindows()
//End

Function	/S	LstOARg()
// Builds a region list consisting entirely of channel and region separators. From this list the number of regions in each channel can easily be derived.
	string  	sFolders	= ksF_ACQ_PUL
	string  	lstRegs		= ""
	string  	lstChans		= LstChAcq()
	variable	r, ch, nChans	= ItemsInList( lstChans, ksSEP_TAB )
	for ( ch = 0; ch < nChans; ch += 1 )
		variable	nRegs	= RegionCnt( sFolders, ch )		// 060124 Cave / Note : the 'svReg' line in the main panel limits the number of channels which are defined and can be processed 
		for ( r = 0; r < nRegs; r += 1 )
			lstRegs	   +=  ksSEP_STD  				//	the block prefix for the title may be empty only containing separators (to determine the number of regions/blocks)
		endfor
		lstRegs	   +=  ksSEP_TAB
	endfor
	// printf "\t\t\t\tLstOARg():\tnChans:%2d\tnRegs:%2d\t->\t'%s'  \r", nChans, nRegs, lstRegs
	return	lstRegs
End

//Function		root_uf_acq_ola_tc1( s )
//// Special tabcontrol action procedure. Called through	fTabControl3( s ) and  fTcPrc( s ).  This function name is derived from 'PnBuildFoTabcoNm()' 
//// 051110  Clicking  on a tab activates the corresponding graph window
//	struct	WMTabControlAction   &s
//	DoWindow  /F   $EvalWndNm( s.tab )						// Bring acq window corresponding to the tab-clicked channel to front and make it the active window 
//	printf "\t\troot_uf_acq_ola_tc1() \r"
//End


//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function		fOAReg( s ) 
// Demo: this  SetVariable control  changes the number of blocks. Consequently the Panel must be rebuilt  OR  it must have a constant large size providing space for the maximum number of blocks.
	struct	WMSetvariableAction    &s
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	string  	sFo	 	= GetUserData( 	s.win,  s.ctrlName,  "sFo" )		// e.g.  'root:uf:acq:' 
	string  	sSubDir	= ReplaceString( "root:uf:", sFo, "" )		  	// e.g.  'root:uf:acq:' -> 'acq:'
	string  	sFolders	= sSubDir + s.win
	string  	sFol_ders	= ReplaceString( ":", sFolders, "_" )

	variable	ch		= TabIdx( s.ctrlName )
	string  	lstRegs	= LstOARg()
	  printf "\t%s\t\t\t\t\t%s\tvar:%g\t-> \tch:%d\tLstBlk3:\t%s\t  \r",  pd(sProcNm,13), pd(s.CtrlName,26), s.dval,ch, pd( lstRegs, 19)

	Panel3Main(   "pul", "", "root:uf:" + ksACQ_, 100,  0 ) // Compute the location of panel controls and the panel dimensions. Redraw the panel displaying and hiding needed/unneeded controls


//	Panel3Sub(   "ola", "Online Analysis", "root:uf:" + ksACQ_, 50, 100,  kPN_DRAW ) // Compute the location of panel controls and the panel dimensions. Draw the panel displaying and hiding needed/unneeded controls
//	UpdateDependent_Of_AllowDelete( s.Win, "root_uf_acq_ola_cbAlDel0000" )	
//	UpdateDependent_Of_AllowDelete( s.Win, "root_uf_acq_set_cbAlDel0000" )	

//	DisplayCursors_Peak( ch )
//	DisplayCursors_Base( ch )
//	DisplayCursors_Lat( ch )
//	DisplayCursors_UsedFit( ch )					// Display the used fit cursors and hide the unused fit cursors immediately depending on the state of the region and fit checkboxes to give the user a feedback which parts of the data will be fitted in the next analysis
	LBResSelUpdateOA()							// update the 'Select results' panel whose size has changed
// // 051018
//	AllLatenciesCheck()		// If a region which has been turned off still contains a latency option this will be flagged as an error
End
	

//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// 	Action  procs  for  FITTING

Function	/S	fOAFitOnOff()
// Initial state of the  'Fit' checkboxes.   This same state must also be used for the initial visibility of the dependent  'FitFunc'  and  'FitRange' controls
// Syntax: tab blk row col 1-based-index;  (Tab0: Window,Peak  Tab2: Window,Cursor,  Tab3...: Window (=default)
//	return  "0010_1;0100_1;~0"	// Test init: Tab~ch~0, blk~reg~0, row~fit1~1 will be ON=1 ;  Tab~ch~0, blk~reg~1, row~fit0~0 will be ON=1 ;  all others will be off = 0 
	return  "0000_1;~0"			// Test init: Tab~ch~0, blk~reg~0, row~fit0~0 will be ON=1 ;  all others will be off = 0 
End


// Version 1 : will print  'Fit 0   CR   Fit 1  CR...'
Function	/S	fOAFitRowTitles()
	variable	fi, nFits	= ItemsInList( ksPHASES ) - PH_FIT0 
	string  	lstTitles	= ""
	for ( fi = 0; fi <  nFits; fi += 1 )
		lstTitles	+=  "Fi " + num2str( fi ) + ksSEP_STD			// ","  e.g.   'Fit 0,Fit 1,Fit 2,'
	endfor 
	// printf "\t\t\tfOAFitRowTitles1() / fFitRowDums() :'%s' \r", lstTitles
	return	lstTitles
End

// Version 2 : will print  '1. Fit   CR  2. Fit  CR...'     if  there is  also  'Fit'  in the panel textwave in the columntitles column
//Function	/S	fFitRowTitles()
//	variable	fi, nFits	= ItemsInList( ksPHASES ) - PH_FIT0 
//	string  	lstTitles	= ""
//	for ( fi = 0; fi <  nFits; fi += 1 )
//		lstTitles	+=  num2str( fi + 1 ) + ". ,"  	// e.g.   '1. ,2. ,3. ,'
//	endfor 
//	// printf "\t\t\tfFitRowTitles() / fFitRowDums() :'%s' \r", lstTitles
//	return	lstTitles
//End


Function	/S	fOAFitRowDums()
// Supplies as many separators as there are titles in the controlling 'Fit' checkbox. They are needed for  'RowCnt()'  to preserve panel geometry, otherwise 'Fit' checkbox and 'FitFunc'/'FitRng' controls will appear in different lines. 
	variable	fi, nFits	= ItemsInList( ksPHASES ) - PH_FIT0 
	string  	lstTitles	= ""
	for ( fi = 0; fi <  nFits; fi += 1 )
		lstTitles	+=  ksSEP_STD  					// e.g.   ','
	endfor 
	// printf "\t\t\tfFitRowTitles() / fFitRowDums :'%s' \r", lstTitles
	return	lstTitles
End


Function		fOAFit( s )
// Checkbox action proc....
	struct	WMCheckboxAction	&s
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	string  	sFo	 	= GetUserData( 	s.win,  s.ctrlName,  "sFo" )		// e.g.  'root:uf:acq:' 
	string  	sFolders	= RemoveEnding( ReplaceString( "root:uf:", sFo, "" ), ":" )		  	// e.g.  'root:uf:acq:pul:' -> 'acq:pul'
	 printf "\t\t%s(s)\t\t%s\tb:%2d  =\t%d : from control \tsFo:%s  sFolders:%s  \r",  sProcNm, pd(s.CtrlName,26), s.checked, PnValC( s.CtrlName ), sFo, sFolders
	string  	sThisControl, sControlledCoNm
	
	sThisControl		= StripFoldersAnd4Indices( s.CtrlName )			// remove all folders and the 4 trailing numbers e.g. 'root_uf_acq_ola_cbFit0000'  -> 'cbFit' 

	// Depending on the state of the  'Fit'  checkbox, enable or disable the depending control  'FitFnc'  (which is in the same line)
	sControlledCoNm	= ReplaceString( sThisControl, s.CtrlName, "pmFiFnc" )	// for this to work both the controlling control and the controlled (=enabled/disabled) control must reside in the same folder
	 printf "\t\t%s(s)\t\t%s\tb:%2d  =\t%d : from control \tUpdating:%s\t \r",  sProcNm, pd(s.CtrlName,26), s.checked, PnValC( s.CtrlName ), sControlledCoNm 
	// Display or hide the dependent control  'FitFnc' 
	PopupMenu $sControlledCoNm, win = $s.win,  userdata( bVisib )	= num2str( s.checked  )	// store the visibility state (depending here only on cbFit, not on the tab!) so that it can be retrieved in the tabcontrol action proc (~ShowHideTabControl3() )
	PopupMenu $sControlledCoNm, win = $s.win,  disable	=  s.checked  ?  0 :   kHIDE  // : kDISABLE
	// Bad:
	ControlUpdate  /W = $s.win $sControlledCoNm	// BAD: should not be needed  but without this line  SOME!  popupmenu controls are not displayed/hidden when they should (when the Checkbox Fit is changed)

	// Depending on the state of the  'Fit'  checkbox, enable or disable the depending control  'FitRng'  (which is in the same line)
	sControlledCoNm	= ReplaceString( sThisControl, s.CtrlName, "pmFiRng" )// for this to work both the controlling control and the controlled (=enabled/disabled) control must reside in the same folder
	 printf "\t\t%s(s)\t\t%s\tb:%2d  =\t%d : from control \tUpdating:%s\t \r",  sProcNm, pd(s.CtrlName,26), s.checked, PnValC( s.CtrlName ), sControlledCoNm 
	// Display or hide the dependent control  'FitRng'
	PopupMenu $sControlledCoNm, win = $s.win,  userdata( bVisib )	= num2str( s.checked  )	// store the visibility state (depending here only on cbFit, not on the tab!) so that it can be retrieved in the tabcontrol action proc (~ShowHideTabControl3() )
	PopupMenu $sControlledCoNm, win = $s.win,  disable	=  s.checked  ?  0 :   kHIDE  // : kDISABLE
	// Bad:
	ControlUpdate  /W = $s.win $sControlledCoNm	// BAD: should not be needed  but without this line  SOME!  popupmenu controls are not displayed/hidden when they should (when the Checkbox Fit is changed)


	// Turn the fit cursors on and off
	variable	ch		= TabIdx( s.ctrlName )
	variable	rg		= BlkIdx( s.ctrlName )
	variable	fi		= RowIdx( s.ctrlName )
//	variable	ph		= RowIdx( s.ctrlName ) + PH_FIT0 

string  	sWnd
	if ( cmpstr( sFolders, ksF_ACQ_PUL ) )
		sWnd	= EvalWndNm( ch )
	else
// 060120 ????
		sWnd	= FindFirstWnd( ch )		// possibly find and process window list 
	endif
//	//  printf "\t%s\t%s\tch:%d\trg:%d\tph:%d\t on:%d\tbVis:%d\t  \r",  pd(sProcNm,15), pd(s.CtrlName,25), ch, rg, ph, s.Checked, bVisib
//	DisplayHideCursors( sFolders, ch, rg, ph, sWnd, s.checked )
//
//	// Do a fit immediately. 
//	string		sFoldOrgWvNm		= GetOnlyOrAnyDataTrace( ch )
//	wave  /Z	wOrg				= $sFoldOrgWvNm
//	if ( waveExists( wOrg ) )							// exists only after the user has clicked into the data sections listbox to view, analyse or average a data section
//		OneFit( wOrg, ch, rg, fi, BegPt, nSI )						// will fit only if  'Fit' checkbox is 'ON'
//	endif
	LBResSelUpdateOA()										// Bebuild the listbox completely as in meantime while the listbox perhaps was invisible e.g the number of channels may have changed
End


//static	 Function	/S	GetOnlyOrAnyDataTrace( ch )
//	variable	ch
//	// Version 1 : Get the current sweep. ++ Gets  even in  'stacked' display mode the current trace, ignores all others.  -- Needs global current sweep and  global current size. 
//	wave	wCurRegion	= root:uf:acq:evl:wCurRegion
//	variable  	nCurSwp		= wCurRegion[ kCURSWP ]	
//	variable  	nSize		= wCurRegion[ kSIZE ]	
//	string		sTrc			= FoOrgWvNm( ch, nCurSwp, nSize )		// CAVE : RETURNS wave name including folder  -->  wOrg = $ sTrc
//	//  printf "\tGetOnlyOrAnyDataTrace( ch:%d )  '%s' \r", ch, sTrc	
//	return	sTrc											// CAVE : RETURNS wave name including folder  -->  wOrg = $ sTrc
//End


//Function		DoFit( ch, rg, fi )
//// Returns the state of the   1. Fit -    or  2. Fit - checkbox.  Another approach: 'ControlInfo'
//	variable 	ch, rg, fi
//	nvar		bFit	= $"root:uf:acq:ola:cbFit" + num2str( ch ) + num2str( rg ) + num2str( fi ) + "0"	//e.g. for ch 0  and  rg 0  and  fit 1:  root:uf:acq:ola:cbFit0010
//	return	bFit
//End


Function		fOAFitFnc( s )
// Action proc of the fit function popupmenu
	struct	WMPopupAction	&s
//	string  	sPath	= ksEVALCFG_DIR 						// e.g.  'C:Epc:Data:EvalCfg:'   or   'C:UserIgor:Ced:'  , must contain drive letter
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	variable	ch		= TabIdx( s.ctrlName )
	variable	rg		= BlkIdx( s.ctrlName )
	variable	fi		= RowIdx( s.ctrlName )
	variable	nFitFunc	= s.popnum - 1							// the popnumber is 1-based
	 printf "\t%s\t%s\tch:%d \trg:%d \tfi:%d \tnFitFnc:%d = '%s'\t \r",  pd(sProcNm,15), pd(s.CtrlName,25), ch, rg, fi, nFitFunc, FitFuncNm( nFitFunc )

//	// Do a fit immediately.
//	string		sFoldOrgWvNm		= GetOnlyOrAnyDataTrace( ch )
//	wave	wOrg				= $sFoldOrgWvNm 
//	OneFit( wOrg, ch, rg, fi, BegPt, nSI )									// will fit only if  'Fit' checkbox is 'ON'
	LBResSelUpdateOA()										// Bebuild the listbox completely as in meantime while the listbox perhaps was invisible e.g the number of channels may have changed

End


Function		fOAFitFncPops( sControlNm, sFo, sWin )
	string		sControlNm, sFo, sWin
	PopupMenu	$sControlNm, win = $sWin,	   value = 	ListFitFunctions()
End

Function	/S	fOAFitFncInit()
// The panel listbox is initially filled with the default fit functions given here. Syntax:   tab=ch  blk  row col  _ 1-based-index;  repeat n times;  ~ 1-based-index for all remaining controls; 
// only test :string		sInitialFitFuncs	=  "0000_2;0010_1;1000_1;1010_1;1000_1;1010_1;1000_1;1010_1;~4;"	// e.g. : ( Tab=ch=0: Line,none  Tab=ch=1..3:none,none, other tabs and blocks>1: value 4 = 1exp+con
	string		sInitialFitFuncs	=  "0000_4;~2;"	// e.g. : ( Tab=ch=0: Line,none  Tab=ch=1..3:none,none, other tabs and blocks>1: value 2 = line,  value 3 = exp, value 4 = 1exp+con
	// print "\t\tsInitialFitFuncs:", sInitialFitFuncs
	return	sInitialFitFuncs
End


//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//  LATENCIES

Function		LatencyCntA() 
	return	2						// !!!  adjust if we have more or less latencies   as  offered  in the  Main panel
End

Function		fLatCsrPopsAc( sControlNm, sFo, sWin )
// currently   fLatCsrPopsEv()   and   fLatCsrPopsAc()   are identical
	string		sControlNm, sFo, sWin
	PopupMenu	$sControlNm, win = $sWin,	 value = klstLATC
End

Function		fLat0Boa( s )
	struct	WMPopupAction	&s
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	string  	sFo	 	= GetUserData( 	s.win,  s.ctrlName,  "sFo" )		// e.g.  'root:uf:eva:' 
	string  	sSubDir	= ReplaceString( "root:uf:", sFo, "" )		  	// e.g.  'root:uf:eva:' -> 'eva:'
	string  	sFolders	= sSubDir + s.win

	variable	ch	= TabIdx( s.ctrlName )
	variable	rg	= BlkIdx( s.ctrlName )
	variable	lc	= 0, 	BegEnd = CN_BEG
	 printf "\t%s\t%s\tch:%d  \trg:%d  lc:%d  BegEnd:%d \t%s\t%g\t  \r",  pd(sProcNm,15), pd(s.CtrlName,31), ch, rg, lc, BegEnd, pd( s.popStr,9), (s.popnum-1)
	// TurnRemainingLatenciesOff( s.CtrlName, lc, BegEnd, ch, rg )		// Two advantages: 1. Prevent that the user accidentally redefines this latency in another channel or region.  2. Tidy up the panel. 
	variable	nChans	= ItemsInList( LstChAcq(), ksSEP_TAB )
	variable	LatCnt	= LatencyCntA()
	AllLatenciesCheck( sFolders, nChans, LatCnt )					//...BUT does not work as all hidden popmenus are restored whenever tabs are clicked. -> must recognise hidden state then
	// !OA DisplayCursor_Lat( sFolders, ch, rg, lc, BegEnd )
	LBResSelUpdateOA()										// update the 'Select results' panel whose contents may have changed
End

Function		fLat0Eoa( s )
	struct	WMPopupAction	&s
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	string  	sFo	 	= GetUserData( 	s.win,  s.ctrlName,  "sFo" )		// e.g.  'root:uf:eva:' 
	string  	sSubDir	= ReplaceString( "root:uf:", sFo, "" )		  	// e.g.  'root:uf:eva:' -> 'eva:'
	string  	sFolders	= sSubDir + s.win
	variable	ch	= TabIdx( s.ctrlName )
	variable	rg	= BlkIdx( s.ctrlName )
	variable	lc	= 0, 	BegEnd = CN_END
	 printf "\t%s\t%s\tch:%d  \trg:%d  lc:%d  BegEnd:%d \t%s\t%g\t  \r",  pd(sProcNm,15), pd(s.CtrlName,31), ch, rg, lc, BegEnd, pd( s.popStr,9), (s.popnum-1)
	// TurnRemainingLatenciesOff( s.CtrlName, lc, BegEnd, ch, rg )		// Two advantages: 1. Prevent that the user accidentally redefines this latency in another channer or region.  2. Tidy up the panel. 
	variable	nChans	= ItemsInList( LstChAcq(), ksSEP_TAB )
	variable	LatCnt	= LatencyCntA()
	AllLatenciesCheck( sFolders, nChans, LatCnt )					//...BUT does not work as all hidden popmenus are restored whenever tabs are clicked. -> must recognise hidden state then
	// !OA DisplayCursor_Lat( sFolders, ch, rg, lc, BegEnd )
	LBResSelUpdateOA()										// update the 'Select results' panel whose contents may have changed
End

Function		fLat1Boa( s )
	struct	WMPopupAction	&s
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	string  	sFo	 	= GetUserData( 	s.win,  s.ctrlName,  "sFo" )		// e.g.  'root:uf:eva:' 
	string  	sSubDir	= ReplaceString( "root:uf:", sFo, "" )		  	// e.g.  'root:uf:eva:' -> 'eva:'
	string  	sFolders	= sSubDir + s.win

	variable	ch	= TabIdx( s.ctrlName )
	variable	rg	= BlkIdx( s.ctrlName )
	variable	lc	= 1, 	BegEnd = CN_BEG
	 printf "\t%s\t%s\tch:%d  \trg:%d  lc:%d  BegEnd:%d \t%s\t%g\t  \r",  pd(sProcNm,15), pd(s.CtrlName,31), ch, rg, lc, BegEnd, pd( s.popStr,9), (s.popnum-1)
	// TurnRemainingLatenciesOff( s.CtrlName, lc, BegEnd, ch, rg )		// Two advantages: 1. Prevent that the user accidentally redefines this latency in another channel or region.  2. Tidy up the panel. 
	variable	nChans	= ItemsInList( LstChAcq(), ksSEP_TAB )
	variable	LatCnt	= LatencyCntA()
	AllLatenciesCheck( sFolders, nChans, LatCnt )					//...BUT does not work as all hidden popmenus are restored whenever tabs are clicked. -> must recognise hidden state then
	// !OA DisplayCursor_Lat( sFolders, ch, rg, lc, BegEnd )
	LBResSelUpdateOA()										// update the 'Select results' panel whose contents may have changed
End

Function		fLat1Eoa( s )
	struct	WMPopupAction	&s
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	string  	sFo	 	= GetUserData( 	s.win,  s.ctrlName,  "sFo" )		// e.g.  'root:uf:eva:' 
	string  	sSubDir	= ReplaceString( "root:uf:", sFo, "" )		  	// e.g.  'root:uf:eva:' -> 'eva:'
	string  	sFolders	= sSubDir + s.win
	variable	ch	= TabIdx( s.ctrlName )
	variable	rg	= BlkIdx( s.ctrlName )
	variable	lc	= 1, 	BegEnd = CN_END
	 printf "\t%s\t%s\tch:%d  \trg:%d  lc:%d  BegEnd:%d \t%s\t%g\t  \r",  pd(sProcNm,15), pd(s.CtrlName,31), ch, rg, lc, BegEnd, pd( s.popStr,9), (s.popnum-1)
	// TurnRemainingLatenciesOff( s.CtrlName, lc, BegEnd, ch, rg )		// Two advantages: 1. Prevent that the user accidentally redefines this latency in another channer or region.  2. Tidy up the panel. 
	variable	nChans	= ItemsInList( LstChAcq(), ksSEP_TAB )
	variable	LatCnt	= LatencyCntA()
	AllLatenciesCheck( sFolders, nChans, LatCnt )					//...BUT does not work as all hidden popmenus are restored whenever tabs are clicked. -> must recognise hidden state then
	// !OA DisplayCursor_Lat( sFolders, ch, rg, lc, BegEnd )
	LBResSelUpdateOA()										// update the 'Select results' panel whose contents may have changed
End


//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// QUOTIENTS     BAD   PopupMenu	$sControlNm, win = $sWin,	 value = ListACV1RegionOA( ch, rg )     AS does not compile  . Also   not intuitive

//Function		QuotientCntA() 
//	return	1						// !!!  adjust if we have more or less  quotients  as  offered in the  Main panel
//End
//
//Function		fQuotPopsAc( sControlNm, sFo, sWin )
//	string		sControlNm, sFo, sWin
//	variable	ch	= TabIdx( sControlNm )
//	variable	rg	= BlkIdx( sControlNm )
//	 printf "\t\tfQuotPopsAc( '%s'  '%s'  '%s' ) -> ch:%2d  rg:%2d  \r", sControlNm, sFo, sWin , ch, rg
//	PopupMenu	$sControlNm, win = $sWin,	 value = " a ; b ; c ; d ;"//ListACV1RegionOA( ch, rg ) 	// TODOA 1. does not compile  	 // 2. is this recursive ???
//End
//
//Function		fQuotEnum( s )
//	struct	WMPopupAction	&s
//	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
//	string  	sFo	 	= GetUserData( 	s.win,  s.ctrlName,  "sFo" )		// e.g.  'root:uf:eva:' 
//	string  	sSubDir	= ReplaceString( "root:uf:", sFo, "" )		  	// e.g.  'root:uf:eva:' -> 'eva:'
//	string  	sFolders	= sSubDir + s.win
//
//	variable	ch	= TabIdx( s.ctrlName )
//	variable	rg	= BlkIdx( s.ctrlName )
//	variable	lc	= 0, 	EnuDeno = CN_BEG	// here 0 = enumerator
//	 printf "\t%s\t%s\tch:%d  \trg:%d  lc:%d  Enu/Deno:%d \t%s\t%g\t  \r",  pd(sProcNm,15), pd(s.CtrlName,31), ch, rg, lc, EnuDeno, pd( s.popStr,9), (s.popnum-1)
//	// TurnRemainingLatenciesOff( s.CtrlName, lc, BegEnd, ch, rg )		// Two advantages: 1. Prevent that the user accidentally redefines this latency in another channel or region.  2. Tidy up the panel. 
//	// variable	nChans	= ItemsInList( LstChAcq(), ksSEP_TAB )
//	// variable	QuotCnt	= QuotientCntA()
//	// AllLatenciesCheck( sFolders, nChans, LatCnt )					//...BUT does not work as all hidden popmenus are restored whenever tabs are clicked. -> must recognise hidden state then
//	// !OA DisplayCursor_Lat( sFolders, ch, rg, lc, BegEnd )
//	LBResSelUpdateOA()										// update the 'Select results' panel whose contents may have changed
//End
//
//Function		fQuotDenom( s )
//	struct	WMPopupAction	&s
//	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
//	string  	sFo	 	= GetUserData( 	s.win,  s.ctrlName,  "sFo" )		// e.g.  'root:uf:eva:' 
//	string  	sSubDir	= ReplaceString( "root:uf:", sFo, "" )		  	// e.g.  'root:uf:eva:' -> 'eva:'
//	string  	sFolders	= sSubDir + s.win
//
//	variable	ch	= TabIdx( s.ctrlName )
//	variable	rg	= BlkIdx( s.ctrlName )
//	variable	lc	= 0, 	EnuDeno = CN_END	// here 1 = denominator
//	 printf "\t%s\t%s\tch:%d  \trg:%d  lc:%d  Enu/Deno:%d \t%s\t%g\t  \r",  pd(sProcNm,15), pd(s.CtrlName,31), ch, rg, lc, EnuDeno, pd( s.popStr,9), (s.popnum-1)
//	// TurnRemainingLatenciesOff( s.CtrlName, lc, BegEnd, ch, rg )		// Two advantages: 1. Prevent that the user accidentally redefines this latency in another channel or region.  2. Tidy up the panel. 
//	// variable	nChans	= ItemsInList( LstChAcq(), ksSEP_TAB )
//	// variable	QuotCnt	= QuotientCntA()
//	// AllLatenciesCheck( sFolders, nChans, LatCnt )					//...BUT does not work as all hidden popmenus are restored whenever tabs are clicked. -> must recognise hidden state then
//	// !OA DisplayCursor_Lat( sFolders, ch, rg, lc, BegEnd )
//	LBResSelUpdateOA()										// update the 'Select results' panel whose contents may have changed
//End

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function		fWAAutomatc( s )
	struct	WMButtonAction	&s

	string  	sFolder	= ksACQ

	InitializeAutoWndArray3()
	wave  	wG		= $"root:uf:" + sFolder + ":" + ksKPwg + ":wG"  						// This  'wG'	is valid in FPulse ( Acquisition )
	wave  /T	wIO		= $"root:uf:" + sFolder + ":ar:wIO"  								// This  'wIO'	is valid in FPulse ( Acquisition )
	wave  	wFix		= $"root:uf:" + sFolder + ":ar:wFix"  								// This  'wFix'	is valid in FPulse ( Acquisition )
	BuildWindows( sFolder, wG, wIO, wFix, kFRONT )				//  Retrieve the Mode/Range-Color string  entries  and  build the (still empty) windows
//	EnableButton( "disp", "root_uf_acq_ola_PrepPrint0000", kENABLE )	// Now that the acquisition windows (and TWA) are constructed we can allow drawing in them (even if they are still empty)
End

Function		fWAUserSpec( s )
	struct	WMButtonAction	&s
	svar		sScriptPath= root:uf:acq:pul:gsScrptPath0000
	string  	sFolder	= ksACQ
	LoadDisplayCfg( sFolder, sScriptPath )
End

Function		fSaveDspCfg( s )
	struct	WMButtonAction	&s
	  printf "\tfSaveDispCfg( %s )  \r", s.ctrlName 
	SaveDispCfg()
End


Function		DispAllDataLagging()
	string  	sFolders	= "acq:pul"
	nvar		bDispAllDataLagging	=$"root:uf:" + sFolders + ":DispAllLag0000"
	return	bDispAllDataLagging
End

Function		HighResolution()
	string  	sFolders	= "acq:pul"
	nvar		bHighResolution	= $"root:uf:" + sFolders + ":HighResol0000"
	return	bHighResolution
End

Function		fAcqCtrlbar( s )
// creates Trace / Window controlbar in acq windows
	struct	WMCheckboxAction	&s
	CreateAllControlBarsInAcqWnd()		// show / hide the ControlBar  immediately
End
Function		AcqControlBar()
	string  	sFolders	= "acq:pul"
	nvar		gbAcqControlbar	= $"root:uf:" + sFolders + ":AcqCtrlBar0000"
	return	gbAcqControlbar
End

Function		fPrepPrint( s )
	struct	WMButtonAction	&s
	string  	sFolder	= ksACQ
	wave  	wG		= $"root:uf:" + sFolder + ":" + ksKPwg + ":wG"  					// This  'wG'	is valid in FPulse ( Acquisition )
	wave  /T	wIO		= $"root:uf:" + sFolder + ":ar:wIO"  							// This  'wIO'	is valid in FPulse ( Acquisition )
	wave  	wFix		= $"root:uf:" + sFolder + ":ar:wFix"  							// This  'wFix'	is valid in FPulse ( Acquisition )
	PreparePrinting( sFolder, wG, wIO, wFix)
End

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function		fOAResSelect( s )
// Displays and hides the OLA  Result selection listbox panel
	struct	WMCheckboxAction	&s
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	printf "\t\t%s(s)\t\t%s\tchecked:%d\t \r",  sProcNm, pd(s.CtrlName,26), s.checked
	if (  s.checked ) 
		LBResSelUpdateOA()								// Bebuild the listbox completely as in meantime while the listbox perhaps was invisible e.g the number of channels may have changed
	else
		LBResSelHideOA()
	endif
End

Function		fOAClearResSel( s )
// Called when a button is pressed.  ALSO CALLED when moving the mouse over a button.  
	struct	WMButtonAction	&s
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	printf "\t\t%s(s)\t\t%s\t%d\t \r",  sProcNm, pd(s.CtrlName,26), mod( DateTime,10000)
	string  	sFolders		= "acq:pul"
	wave	wFlags		= $"root:uf:" + sFolders + ":wSRFlags"
	LBResSelClear( wFlags )
	// Reset the quasi-global string 	'lstOlaRes' which contains then information which OLA data are to be plotted in which windows. In this special simple context (=Reset the entire Listbox) simple code like '  lstOlaRes=""  '  would also be sufficient.
	string  	sWin			= ksRES_SEL_OA
	string  	sCtrlName		= "lbSelectResult"
	string  	lstOlaRes		= ExtractLBSelectedWindows( sFolders, sWin, sCtrlName )
	ListBox 	  $sCtrlname,    win = $sWin, 	userdata( lstOlaRes ) = lstOlaRes
End

//=======================================================================================================================================================
// THE   RESULT SELECTION   ONLINE  ANALYSIS   LISTBOX  PANEL			

static constant	kLBOLA_COLWID_TYP	= 62		// OLA Listbox column width for SrcRegTyp	 column  (in points)
static constant	kLBOLA_COLWID_WND	= 13		// OLA Listbox column width for    Window	 column  (in points)	(A0,A1 needs 20,  a,b,c needs 12,   A,B,C needs 14)

Function		LBResSelUpdateOA()
// Build the huge  'R_esult S_election'  listbox allowing the user to select some results Online graphical display
	string  	sFolders		= "acq:pul"
	nvar		bVisib		= $"root:uf:" + sFolders + ":cbResSelTb0000"		// The ON/OFF state ot the 'Select Results' checkbox
	string  	sWin			= ksRES_SEL_OA

	// 1. Construct the global string  'lstACVAllCh'  which contains all of the various evaluation and fitting values
	string  	lstACVAllCh	=  ListACVAllChansOA() 						// Base_00;BsRise_00;RT20_00;


	// 2. Get the the text for the cells by breaking the global string  'lstACVAllCh'  which contains all of the various evaluation and fitting values
	variable	len, n, nItems	= ItemsInList( lstACVAllCh )	
	 printf "\t\t\tLBResSelUpdateOA(a)\tlstACVAllCh has items:%3d <- \t '%s .... %s' \r", nItems, lstACVAllCh[0,80] , lstACVAllCh[ strlen( lstACVAllCh ) - 80, inf ]
	string 	sColTitle, lstColTitles	= ""				// e.g. 'Adc1 Rg 0~Adc3 Rg1~'
	string  	lstColItems = ""
	string  	lstCol2ChRg  = ""			// e.g. '1,0;0,2;'

	variable	nExtractCh, ch = -1
	variable	nExtractRg, rg = -1 
	string 	sOneItemIdx, sOneItem
	for ( n = 0; n < nItems; n += 1 )
		sOneItemIdx	= StringFromList( n, lstACVAllCh )						// e.g. 'Base_010'
		len			= strlen( sOneItemIdx )
		sOneItem		= sOneItemIdx[ 0, len-4 ] 							// strip 3 indices + separator '_'  e.g. 'Base_010'  ->  'Base'
		nExtractCh	= str2num( sOneItemIdx[ len-2, len-2 ] )					// !!! Assumption : ACV naming convention
		nExtractRg	= str2num( sOneItemIdx[ len-1, len-1 ] )					// !!! Assumption : ACV naming convention
		if ( ch != nExtractCh )											// Start new channel
			ch 		= nExtractCh
 			rg 		= -1 
		endif
		if ( rg != nExtractRg )											// Start new region
			rg 		  =  nExtractRg
			//sprintf sColTitle, "Ch%2d Rg%2d", ch, rg								// Assumption: Print results column title  e.g. 'Ch 0 Rg 0~Ch 2 Rg1~'
			sprintf sColTitle, "%s Rg%2d", StringFromList( ch, LstChAcq(), ksSEP_TAB ), rg	// Assumption: Print results column title  e.g. 'Adc1 Rg 0~Adc3 Rg1~'
			lstColTitles	  =  AddListItem( sColTitle, 	 lstColTitles,   ksCOL_SEP, inf )	// e.g. 'Adc1 Rg 0~Adc3 Rg1~'
			lstCol2ChRg += SetChRg( ch, rg )							// e.g.  '1,0;0,2;'
			lstColItems	 += ksCOL_SEP
		endif
		lstColItems	+= sOneItem + ";"
	endfor
	lstColItems	= lstColItems[ 1, inf ] + ksCOL_SEP							// Remove erroneous leading separator ( and add one at the end )

	// 3. Get the maximum number of items of any column
	variable	c, nCols	= ItemsInList( lstColItems, ksCOL_SEP )				// or 	ItemsInList( lstColTitles, ksCOL_SEP )
	variable	nRows	= 0
	string  	lstItemsInColumn
	for ( c = 0; c < nCols; c += 1 )
		lstItemsInColumn  = StringFromList( c, lstColItems, ksCOL_SEP )	
		nRows		  = max( ItemsInList( lstItemsInColumn ), nRows )
	endfor
	 printf "\t\t\tLBResSelUpdateOA(b)\tlstACVAllCh has items:%3d -> rows:%3d  cols:%2d\tColT: '%s'\tColItems: '%s...' \r", nItems, nRows, nCols, lstColTitles, lstColItems[0, 100]


	// 4. Compute panel size . The y size of the listbox and of the panel  are adjusted to the number of listbox rows (up to maximum screen size) 
	variable	nSubCols	= kMAX_OLA_WNDS
	variable	xSize		= nCols * ( kLBOLA_COLWID_TYP + nSubCols * kLBOLA_COLWID_WND )	+ 30 	 
	variable	ySizeMax	= GetIgorAppPixelY() -  kMAGIC_Y_MISSING_PIXEL	// Here we could subtract some Y pixel if we were to leave a bottom region not covered by a larges listbox.
	variable	ySizeNeed	= nRows * kLB_CELLY + kLB_ADDY				// We build a panel which will fit entirely on screen, even if not all listbox line fit into the panel...
	variable	ySize		= min( ySizeNeed , ySizeMax ) 					// ...as in this case Igor will automatically supply a listbox scroll bar.
			ySize		=  trunc( ( ySize -  kLB_ADDY ) / kLB_CELLY ) * kLB_CELLY + kLB_ADDY	// To avoid partial listbox lines shrink the panel in Y so that only full-height lines are displayed
	
	// 5. Draw  panel and listbox
	if ( bVisib )													// Draw the SelectResultsPanel and construct or redimension the underlying waves  ONLY IF  the  'Select Results' checkbox  is  ON

		if ( WinType( sWin ) != kPANEL )								// Draw the SelectResultsPanel and construct the underlying waves  ONLY IF  the panel does not yet exist
			// Define initial panel position.
			NewPanel1( sWin, kRIGHT, -40, xSize, kTOP, 0, ySize, kKILL_DISABLE, "OLA Results" )	// -30 is an X offset preventing this panel to be covered by the FPulse panel.  We must disable killing as this would destroy any selection in the listbox, but minimising is allowed.

			SetWindow	$sWin,  hook( SelRes ) = fHookPnSelResOA

			ModifyPanel /W=$sWin, fixedSize= 1						// prevent the user to maximize or close the panel by disabling these buttons

			// Create the 2D LB text wave	( Rows = maximum of results in any ch/rg ,  Columns = Ch0 rg0; Ch0 rg1; ... )
			make  /O 	/T 	/N = ( nRows, nCols*(1+nSubCols) )	$"root:uf:" + sFolders + ":wSRTxt"	= ""	// the LB text wave
			wave   	/T		wSRTxt				     =	$"root:uf:" + sFolders + ":wSRTxt"
		
			// Create the 3D LB flag wave. 	Rows x Columns (as above)  x 3  : last index 0 is flags, 1 is fore- or background color, 2 is the remaining color 
			make   /O	/B  /N = ( nRows, nCols*(1+nSubCols), 3 )	$"root:uf:" + sFolders + ":wSRFlags"	// byte wave is sufficient for up to 254 colors 
			wave   			wSRFlags				    = 	$"root:uf:" + sFolders + ":wSRFlags"
			
			// Create color table withs rows and columns exchanged. 3 rows, n columns is easier to read as n columns, 3 rows but must be transposed before Igor can use them.
			// At the moment these colors are the same as in the  DataSections  listbox
			//								black		blue			red			magenta			grey			light grey			green			yellow				

// Version1: (works but wrong colors)
//			make   /O	/W /U	root:uf:acq:ola:wSRColors= { {0, 0, 0 }, { 0, 0, 65535 },  { 65535, 0, 0 },  {40000,0,48000}, {44000,44000,44000},  {54000,54000,54000},  { 0, 50000, 0} ,   { 0, 56000, 56000 },  {65280,59904,48896} }	// order must be same as defined by constants above
//			wave	wSRColorsPr	 	= root:uf:acq:ola:wSRColors 		
//			MatrixTranspose 		  wSRColorsPr					// the same table is used for foreground and background. 	Igor requires  n  rows, 3 columns 
//			EvalColors( wSRColorsPr )								// 051108  

// Version2: (works...)
			make /O	/W /U /N=(128,3) 	   	   $"root:uf:" + sFolders + ":wSRColors" 		
			wave	wSRColorsPr	 		= $"root:uf:" + sFolders + ":wSRColors" 		
			EvalColors( wSRColorsPr )								// 051108  


			// Link the  indices  of  Foreground  and  Background  colors  to  their name strings which are later used to access the layer where the color is to be set
			variable	planeFore	= 1
			variable	planeBack	= 2
			SetDimLabel 2, planeBack,  $"backColors"	wSRFlags
			SetDimLabel 2, planeFore,   $"foreColors"	wSRFlags
	
		else													// The panel DOES exist. It may be minimised to an icon or it may be hidden behind other panels. If it is hidden then the checkbox must be actuated twice: hide and then restore panel to make it visible
			MoveWindow /W=$sWin	1,1,1,1						// Restore previous size and position. This does NOT take into account that the panel size may have changed in the meantime due to more or less columns or rows

			MoveWindow1( sWin, kRIGHT, -3, xSize, kTOP, 0, ySize )		// Extract previous panel position and size. Keep only position and discard size as the size may have changed in the meantime due to more or less columns or rows.

			wave   	/T		wSRTxt			= $"root:uf:" + sFolders + ":wSRTxt"
			wave   			wSRFlags		  	= $"root:uf:" + sFolders + ":wSRFlags"
			Redimension	/N = ( nRows, nCols*(1+nSubCols) )		wSRTxt
			Redimension	/N = ( nRows, nCols*(1+nSubCols), 3 )		wSRFlags
		endif

		// Set the column titles in the SR text wave, take the entries as computed above
		variable	w, lbCol
		for ( c = 0; c < nCols; c += 1 )								// the true columns 0,1,2  each including the window subcolumns
			for ( w = 0; w <= nSubCols; w += 1 )						// 1 more as w=0 is not a window but the SrcRegTyp column
				lbCol	= c * (nSubCols+1) + w
				if ( w == 0 )
					SetDimLabel 1, lbCol, $StringFromList( c, lstColTitles, ksCOL_SEP ), wSRTxt	// 1 means columns,   true column 		e.g. 'Ch 0 Rg 0'  or  'Ch 2 Rg1'  or  'Adc1 Rg 0'
				else
					SetDimLabel 1, lbCol, $AnalWndNm( w-1 ), wSRTxt					// 1 means columns,   window subcolumn	e.g. 'A' , 'B' , 'C'   or  'W0' , 'W1' 
				endif
			endfor
		endfor

		// Fill the listbox columns with the appropriate  text
		variable	r
		for ( c = 0; c < nCols; c += 1 )
			if ( c == 0 )
				ListBox   	lbSelectResult,    win = $sWin, 	widths  =	{ kLBOLA_COLWID_TYP,  kLBOLA_COLWID_WND,  kLBOLA_COLWID_WND,  kLBOLA_COLWID_WND }	// !!! number of entries depends on ...	
			else
				ListBox 	lbSelectResult,    win = $sWin, 	widths +=	{ kLBOLA_COLWID_TYP,  kLBOLA_COLWID_WND,  kLBOLA_COLWID_WND,  kLBOLA_COLWID_WND }	// ...'nSubCols' = 'kMAX_OLA_WNDS'
			endif
			lstItemsInColumn  = StringFromList( c, lstColItems, ksCOL_SEP )	
			for ( r = 0; r < ItemsInList( lstItemsInColumn ); r += 1 )
				for ( w = 0; w <= nSubCols; w += 1 )									// 1 more as w=0 is not a window but the SrcRegTyp column
					lbCol	= c *(nSubCols+1) + w
					if ( w == 0 )
						wSRTxt[ r ][ lbCol ]	= StringFromList( r, lstItemsInColumn )			// set the text  e.g  'Base' , 'F0_T0'
					else
						wSRTxt[ r ][ lbCol ]	= ""									// the subcolumns 'A' , 'B' , 'C'  are  NOT displayed in the cells but only in the titles
					endif
				endfor
			endfor
			for ( r = ItemsInList( lstItemsInColumn ); r < nRows; r += 1 )
				for ( w = 0; w <= nSubCols; w += 1 )
					lbCol	= c * (nSubCols+1) + w
					wSRTxt[ r ][ lbCol ]	= ""										// some columns may have less entries than other columns: delete old left-over entries
				endfor
			endfor
		endfor
	
		// Build the listbox which is the one and only panel control 
		// stale BP 2  : set 2 BPs in the next 2 lines. Run until  Igor stops at the 2. BP ( the 1. will.be skipped ).  Try to continue with  ESC....NO stale BP here.

		ListBox 	  lbSelectResult,    win = $sWin, 	pos = { 2, 0 },  size = { xSize, ySize + kLB_ADDY },  frame = 2
		ListBox	  lbSelectResult,    win = $sWin, 	listWave 			= $"root:uf:" + sFolders + ":wSRTxt"
		ListBox 	  lbSelectResult,    win = $sWin, 	selWave 			= $"root:uf:" + sFolders + ":wSRFlags",  editStyle = 1
		ListBox	  lbSelectResult,    win = $sWin, 	colorWave		= $"root:uf:" + sFolders + ":wSRColors"				// 051108
		// ListBox 	  lbSelectResult,    win = $sWin, 	mode 			 = 4// 5			// ??? in contrast to the  DataSections  panel  there is no mode setting required here ??? 
		ListBox 	  lbSelectResult,    win = $sWin, 	proc 	 			 = lbResSelOAProc
		ListBox 	  lbSelectResult,    win = $sWin, 	userdata( lstCol2ChRg ) = lstCol2ChRg

	endif		// bVisible : state of 'Select results panel' checkbox is  ON 

	// 060314
	// Store the string quasi-globally within the listbox panel window
	// ListBox 	 	lbSelectResult,    win = $sWin, 	UserData( lstACVAllCh ) = lstACVAllCh		// Store the string quasi-globally within the listbox which belongs to the panel window 
	SetWindow	$sWin,  					UserData( lstACVAllCh ) = lstACVAllCh		// Store the string quasi-globally within the panel window containing the listbox 


	// 7.	Construct the OLA result waves: 1 wave for each listbox entry.  Initially the wave all have just 1 point containing Nan so they will not be drawn. 
	AppendNanInDisplayWave( 0, sWin )		
	
End


//-----------------------------------------------------------------------------------------------------------------------------
// Used for encoding channel/region information indexed by listbox column

Function	/S	SetChRg( ch, rg )
	variable	ch, rg
	return	num2str(ch) + "," + num2str(rg) + ";" 					// e.g.  '1,0;'  for 1 column (=for 1 active channel)
End
Function		ChRg2Ch( sChRg )
	string  	sChRg										// e.g.  '1,0;' 
	return	str2num( StringFromList( 0, sChRg, "," ) )				// e.g.  ch = '1' 
End
Function		ChRg2Rg( sChRg )
	string  	sChRg										// e.g.  '1,0;' 
	return	str2num( StringFromList( 1, sChRg, "," ) )				// e.g.  rg  = '0' 
End


Function		LbCol2Ch( nLbCol )	
	variable	nLbCol										// the column in the listbox counting channel  AND additional window columns
	variable	nChIdx	= floor( nLbCol / ( kMAX_OLA_WNDS+1 ) )		// the index of the channel (ignoring all additional window columns)
	return	nChIdx
End

Function		LbCol2Wnd( nLbCol )	
	variable	nLbCol										// the column in the listbox counting channel  AND additional window columns
	variable	nWndIdx  = mod( nLbCol, kMAX_OLA_WNDS+1 )		// the index of the window
	return	nWndIdx
End

Function		LbCol2TypCol( nLbCol )	
	variable	nLbCol										// the column in the listbox counting channel  AND additional window columns
	variable	nTypCol	= LbCol2Ch( nLbCol ) * ( kMAX_OLA_WNDS+1 )	// the true column number of the type (e.g. 'Peak') corresponding to the clicked window (A,B or C) taking into account the channel and region 
	return	nTypCol
End


//-----------------------------------------------------------------------------------------------------------------------------

Function		LBResSelHideOA()
	string  	sWin	= ksRES_SEL_OA
	 printf "\t\t\tLBResSelHideOA()   sWin:'%s'  \r", sWin
	if (  WinType( sWin ) == kPANEL )						// check existance of the panel. The user may have killed it by clicking the panel 'Close' button 5 times in fast succession
		MoveWindow 	/W=$sWin   0 , 0 , 0 , 0				// hide the window by minimising it to an icon
	endif
End



Function 		fHookPnSelResOA( s )
// The window hook function of the 'Select results panel' detects when the user minimises the panel by clicking on the panel 'Minimise' button and adjusts the state of the 'select results' checkbox accordingly
	struct	WMWinHookStruct &s
	string  	sFolders		= "acq:pul"
	if ( s.eventCode != kWHK_mousemoved )
		// printf  "\t\tfHookPnSelResTable( %2d \t%s\t)  '%s'\r", s.eventCode,  pd(s.eventName,9), s.winName
		if ( s.eventCode == kWHK_move )									// This event also triggers if the panel is minimised to an icon or restored again to its previous state
			GetWindow     $s.WinName , wsize								// Get its current position		
			variable	bIsVisible	= ( V_left != V_right  &&  V_top != V_bottom )
			nvar		bCbState	= $"root:uf:" + sFolders + ":cbResSelTb0000"		// Turn the 'Select Results' checkbox  ON / OFF  if the user maximised or minimised the panel by clicking the window's  'Restore size'  or  'Minimise' button [ _ ] .
			bCbState			= bIsVisible								// This keeps the control's state consistent with the actual state.
			// printf "\t\tfHookPnSelResTable( %2d \t%s\t)  '%s'\tV_left:%3d, V_Right:%3d, V_top:%3d, V_bottom:%3d -> bVisible:%2d  \r", s.eventCode,  pd(s.eventName,9), s.winName, V_left, V_Right, V_top, V_bottom, bIsVisible
		endif
	endif
End

// 060317a
//Function		AutoSelectOLAResults( w, ch, rg, rtp )
//// Automatically selects an OLA listbox field (=automatically display OLA data in a possibly auto-constructed window)  when the user defines a region.
//// Limitations: 1.Currently implemented only for base and peak.  2. Fixed window 'w' is chosen.   3. User must click window away if he does not want to see the OLA results or if he wants to see them in another window.
//	variable	w, ch, rg, rtp
//	string  	sFolders		= "acq:pul"
//	wave	wFlags		= $"root:uf:" + sFolders + ":wSRFlags"
//	wave   /T	wTxt			= $"root:uf:" + sFolders + ":wSRTxt"
//	string  	sPlaneNm		= "BackColors" 
//	variable	pl			= FindDimLabel( wFlags, 2, sPlaneNm )
//	variable	nState	= 3										// todo ...could expand this.....
//	string  	sWnd
//	string  	sSrc		= StringFromList( ch, LstChAcq(), ksSEP_TAB )
//	string  	sTyp		= EvalNm( rtp )
//	string  	sOlaNm 	= OlaNm( sSrc, sTyp, rg ) 
//
//	// Compute the column index of the listbox field to be highlighted (=selected)  from the  source channel  chosen in the marquee menu when defining a region
//	string  	sWin			= ksRES_SEL_OA
//	string  	sCtrlName		= "lbSelectResult"
//	string  	lstCol2ChRg 	= GetUserData( 	sWin,  sCtrlName,  "lstCol2ChRg" )	// e.g. for 2 columns '0,0;1,2;'  (Col0 is Ch0Rg0 , col1 is Ch1Rg2) 
//	
//	string  	sChRg	= RemoveEnding( SetChRg( ch, rg ) )					// remove trailing separator
//	variable	col		= WhichListItem( sChRg, lstCol2ChRg ) 					// this is the ChRegSrc column index but it is not the true lb column index as it ignores the intermediate window columns
//	if ( col == kNOTFOUND )
//		InternalError( "AutoSelectOLAResults() could not find matching column for requested ChRg='" + sChRg + "' in list of all ChRgs='" + lstCol2ChRg + "' ." )
//		return	-1
//	endif
//	variable	nTrueCol	= col * (1+kMAX_OLA_WNDS)  + w					// this is the true lb column index including window columns
//	
//	// Compute the row index of the listbox field to be highlighted (=selected)  from the  result type  chosen in the marquee menu when defining a region
//	variable	row		= SearchRow( wTxt, col, sTyp )
//	if ( row == kNOTFOUND )
//		InternalError( "AutoSelectOLAResults() could not find matching  row  for requested Typ='" + sTyp + "' ." )
//		return	-1
//	endif
//
//
//	DSSet5( wFlags, row, row, nTrueCol, pl, nState )							// sets flags .  The range feature is not used here so  begin row = end row .
//
//	sWnd		= PossiblyAddAnalysisWnd( w-1 )
//	 printf "\t\tAutoSelectOLAResults(\tw:%2d \tch:%2d\trg:%2d\tnkE_Idx:%2d\t-> '%s'\t'%s'\t'%s'\t'%s'\t-> \trow:%2d\tcol:%2d\t(%2d )\t<-\t['%s'   '%s']  \r", w , ch, rg, rtp, sTyp, sWnd,  sSrc, sOlaNm, row, col, nTrueCol, sChRg, lstCol2ChRg
//// 060315
//	SetChRgTyp( sFolders, ch, rg, row, num2str( rtp ) )				// Make the connection between result 'rtp' and  Chan/Reg permanent in global list 'lstChRgTyp'
//	Construct1EvalPntInAcqWnd( sFolders, ch, rg, rtp )				// Construct  'wAcqPt'  .
//// 060315
//	DrawAnalysisWndTrace( sWnd, sOLANm )							// from now on display this SrcRegionTyp in this window
//	DrawAnalysisWndXUnits( sWnd )	
//End



Function		SearchRow( wTxt, col, sTyp )
// Compute the row index of the listbox field to be highlighted (=selected)  from the  result type  chosen in the marquee menu when defining a region
	wave   /T	wTxt		
//	variable	nTrueCol											// this is the true lb column index including window columns
	variable	col												// this is the ChRegSrc column index but it is not the true lb column index as it ignores the intermediate window columns
	string  	sTyp
	variable	nChanCol	= col * (1+kMAX_OLA_WNDS)  					// this is the true lb column index of the ChRgTyp  column  (multiple window columns have 1 'nChanCol' ) 
	variable	row = 0, nRows = DimSize( wTxt, 0 )
	do 
		if ( cmpstr( wTxt[ row ][ nChanCol ] , sTyp ) == 0 )
			return	row
		endif
		row += 1
	while ( row < nRows )
	return	kNOTFOUND
End


Function		lbResSelOAProc( s ) : ListBoxControl
// Dispatches the various actions to be taken when the user clicks in the Listbox. At the moment only mouse clicks and the state of the CTRL, ALT and SHIFT key are processed.
// At the moment the actions are  1. colorise the listbox fields  2. add result to  or remove result from window.  Note: if ( s.eventCode == kLBE_MouseUp  )	does not work here like it does in the data sections listbox ???
	struct	WMListboxAction &s
	string  	sFolders		= "acq:pul"
	wave	wFlags		= $"root:uf:" + sFolders + ":wSRFlags"
	wave   /T	wTxt			= $"root:uf:" + sFolders + ":wSRTxt"
	string  	sPlaneNm		= "BackColors" 
	variable	pl			= FindDimLabel( wFlags, 2, sPlaneNm )
	variable	nOldState		= State( wFlags, s.row, s.col, pl )					// the old state
	string  	lstCol2ChRg 	= GetUserData( 	s.win,  s.ctrlName,  "lstCol2ChRg" )	// e.g. for 2 columns '0,0;1,2;'  (Col0 is Ch0Rg0 , col1 is Ch1Rg2) 
	string  	lstOlaRes	 	= GetUserData( 	s.win,  s.ctrlName,  "lstOlaRes" )		// e.g. 'Base_00A;Peak_00B;F0_A0_01B;' : which OLA results in which OLA windows

	//.......na............... Convert the modifying key (e.g. 'Ctrl' ,  'Ctrl Alt / Alt Gr' ) to a state = color  (e.g. select for file, for print or for both )  
	variable	nState		= Modifier2State( s.eventMod, lstMOD2STATE1)		//..................na.......NoModif:cyan:3:Tbl+Avg ,  Alt:green:2:Avg ,  Ctrl:1:blue:Tbl ,   AltGr:cyan:3:Tbl+Avg 

//	 printf "\t\tlbSelResOAProc( s ) 1\trow:%2d\tcol:%2d  evCode:%2d\tevModif:%2d\toldstate:%2d -> %2d \tlstColChans:'%s' \r", s.row , s.col, s.eventCode, s.eventMod,  nOldState, nState, lstCol2ChRg

	//  Construct or delete  'wAcqPt'  . This wave contains just 1 analysed  X-Y-result point which is to be displayed in the acquisition window over the original trace as a visual check that the analysis worked.  
	variable	ch		= LbCol2Ch( s.col )								// the column of the channel (ignoring all additional window columns)
	variable	w		= LbCol2Wnd( s.col )	
	string  	sChRg	= StringFromList( ch, lstCol2ChRg )					// e.g. '0,0;1,2;'  ->  '1,2;'

	variable	rg		= ChRg2Rg( sChRg )									// e.g.  Base , Peak ,  F0_A1, Lat1_xxx ,  Quotxxx
	string  	sTyp		= wTxt[ s.row ][ LbCol2TypCol( s.col ) ]						// retrieves type when any window column  in any channel/region is clicked
	variable	rtp	= WhichListItemIgnoreWhiteSpace( sTyp, klstEVL_RESULTS ) 	// e.g. kE_Base=15,  kE_PEAK=25  todo fits......
	string  	sWnd
// 060317d weg
//	string		lstChRgTyp
	string  	sSrc		= StringFromList( ch, LstChAcq(), ksSEP_TAB )
// 060315
//	string  	sOlaNm 	= OlaNm( sSrc, sTyp, rg ) 								// e.g. 
	string  	sOlaNm 	= OlaNm1( sTyp, ch, rg ) 								// e.g. 'Peak_00'
	string  	sOlaNmW 	= OlaNmW( sTyp, ch, rg, w ) 							// e.g. 'Peak_00A'

	// Sample : sControlNm  'root_uf_acq_ola_wa_Adc1Peak_WA0'  ,    boolean variable name : 'root:uf:acq:ola:wa:Adc1Peak_WA0'  , 	sOLANm: 'Adc1Peak'  ,  sWnd: 'WA0'

	// MOUSE : SET a  cell. Click in a cell  in any row or column. Depending on the modifiers used, the cell changes state and color and stay in this state. It can be reset by shift clicking again or by globally reseting all cells.
	if ( s.eventCode == kLBE_MouseDown  &&  !( s.eventMod & kSHIFT ) )	// Only mouse clicks  without SHIFT  are interpreted here.  // ??? In this listbox only MouseDown is detected, whereas in the similar  DataSections  listbox  MouseUp  is detected???
		DSSet5( wFlags, s.row, s.row, s.col, pl, nState )				// sets flags .  The range feature is not used here so  begin row = end row .
		// printf "\t\tlbSelResOAProc( s ) 2\trow:%2d\tcol:%2d  evCode:%2d\tevModif:%2d\tstate:%2d =?=%2d  \r",  s.row, s.col,  s.eventCode, s.eventMod, nState, State( wFlags, s.row, s.col, pl )	
		if ( w == 0 ) 													//  A  SrcRegTyp  column cell has been clicked  : ignore  clicks 
			 printf "\t\tlbSelResOAProc( Ignore\trow:%2d\tcol:%2d  evCode:%2d\tevModif:%2d\toldstate:%2d -> %2d \tlstColChans:'%s' -> ch:%2d  rg.%2d  w:%2d  '%s'\t'%s'\t   \r", s.row , s.col, s.eventCode, s.eventMod,  nOldState, nState, lstCol2ChRg, ch, rg, w,  sOlaNm, sOlaNmW
		else
			if ( FindListItem( sOlaNmW, lstOlaRes ) == kNOTFOUND )
				lstOlaRes	= AddListItem( sOlaNmW, lstOlaRes )			// add to list only once (even if the user clicks multiple times on the same cell)
	
			// TODO Sort list according to channel/region : this avoids unnecessary calculations of  Base and peak in  OLA1Point()
	
				ListBox 	  $s.ctrlname,    win = $s.win, 	userdata( lstOlaRes ) = lstOlaRes
			endif
			 printf "\t\tlbSelResOAProc( ADD 4\trow:%2d\tcol:%2d  evCode:%2d\tevModif:%2d\toldstate:%2d -> %2d \tlstColChans:'%s' -> ch:%2d  rg.%2d  w:%2d  '%s'\t'%s'\t'%s'\t   \r", s.row , s.col, s.eventCode, s.eventMod,  nOldState, nState, lstCol2ChRg, ch, rg, w,  sOlaNm, sOlaNmW, lstOlaRes

			sWnd		= PossiblyAddAnalysisWnd( w-1 )
// 060317d weg
// 060315
//			lstChRgTyp	= SetChRgTyp( sFolders, ch, rg, s.row, num2str( rtp ) )	// Make the connection between result 'rtp' and  Chan/Reg permanent in global list 'lstChRgTyp'
			// 060316 Base and peak are already auto-constructed so we might avoid constructing them here

			if ( rtp != kNOTFOUND )// do not process fits, lats, ...
				Construct1EvalPntInAcqWnd( sFolders, ch, rg, rtp )				// Construct  'wAcqPt'  .
			endif
// 060315
			DrawAnalysisWndTrace( sWnd, sOLANm, rtp )							// from now on display this SrcRegionTyp in this window
			DrawAnalysisWndXUnits( sWnd )	
		endif

	endif

	// MOUSE :  RESET a cell  by  Shift Clicking
	if ( s.eventCode == kLBE_MouseDown  &&  ( s.eventMod & kSHIFT ) )		// Only mouse clicks  with    SHIFT  are interpreted here.  // ??? In this listbox only MouseDown is detected, whereas in the similar  DataSections  listbox  MouseUp  is detected???
		nState		= 0										// Reset a cell  
		DSSet5( wFlags, s.row, s.row, s.col, pl, nState )					// sets flags .  The range feature is not used here so  begin row = end row .
		// printf "\t\tlbSelResOAProc( s ) 3\trow:%2d\tcol:%2d  evCode:%2d\tevModif:%2d\tstate:%2d =?=%2d  \r",  s.row, s.col,  s.eventCode, s.eventMod, nState, State( wFlags, s.row, s.col, pl )	
		if ( w > 0 ) 												//  A  Window column cell has been clicked  ( ignore  clicks into  the  SrcRegTyp column)
			if ( FindListItem( sOlaNmW, lstOlaRes ) != kNOTFOUND )
				lstOlaRes	= RemoveFromList( sOlaNmW, lstOlaRes )		// remove from list only if the entry exists (even if the user shift clicks multiple times on the same cell)
				ListBox 	  $s.ctrlname,    win = $s.win, 	userdata( lstOlaRes ) = lstOlaRes
			endif
			variable	nUsed	= OlaWindowIsUsedTimes( w, lstOlaRes )	// Check if any other SrcRegTyp still uses this window. Only if no other SrcRegTyp uses this window we can remove not only the trace but also the window 
			 printf "\t\tlbSelResOAProc( DEL 1\trow:%2d\tcol:%2d  evCode:%2d\tevModif:%2d\toldstate:%2d -> %2d \tlstColChans:'%s' -> ch:%2d  rg.%2d  w:%2d [used:%2d] \t'%s'\t'%s'\t'%s'\t   \r", s.row , s.col, s.eventCode, s.eventMod,  nOldState, nState, lstCol2ChRg, ch, rg, w,  nUsed, sOlaNm, sOlaNmW, lstOlaRes

// 060317d weg
// 060315
//			lstChRgTyp	= SetChRgTyp( sFolders, ch, rg, s.row, "" )
// 060313 wrong: the point should only be deleted if it appears in no other window
			if ( rtp != kNOTFOUND )// do not process fits, lats, ...
				Delete1AcqEvalPoint( sFolders, ch, rg, rtp )				// Delete  'wAcqPt'  : Remove this SrcRegTyp from this acq window (W0, W1...) . Will trigger the  'Modified'  event in the acq window.
			endif
		endif
	
// 060313	// Remove the OLA trace from the OLA window  A, B or C 
		sWnd	= AnalWndNm( w-1 )
		if ( WinType( sWnd ) == kGRAPH )								// check if the graph exists but...
			RemoveFromGraph  /Z  /W=$sWnd		$sOLANm  			// ...do  not check if the trace exists ( /Z avoids complaints if the user tries to remove a non-existing trace )
	
	// 060315
	//		// Check if any other SrcRegTyp still uses this window. Only if no other SrcRegTyp uses this window we can remove not only the trace but also the window 
	//		variable	nUsed	= 0
	//		variable	c, nCols	= ItemsInList( lstCol2ChRg ) 					// the number of SrcRegTyp columns (ignoring any window columns) 
	//		for ( c = 0; c < nCols; c += 1 )
	//			variable	nTrueCol	= c * ( kMAX_OLA_WNDS + 1 ) + w  
	//			variable	r, nRows	= DimSize( wTxt, 0 )					// or wFlags
	//			for ( r = 0; r < nRows; r += 1 )
	//				nUsed += ( State( wFlags, r, nTrueCol, pl ) != 0 )
	//				// printf "\t\tlbSelResOAProc( DEL 3\tr:%2d/%2d\tcol:%2d  evCode:%2d\tevModif:%2d\toldstate:%2d -> %2d \tlstColChans:'%s' -> ch:%2d  rg.%2d  w:%2d  kEIdx:%3d   '%s' -> State:%2d   Used:%2d \r", r, nRows, nTrueCol, s.eventCode, s.eventMod,  nOldState, nState, lstCol2ChRg, ch, rg, w, rtp, sTyp, State( wFlags, r, nTrueCol, pl ), nUsed
	//			endfor
	//		endfor
			sWnd	= AnalWndNm( w-1 )
			if ( nUsed == 0 )
				KillWindow $sWnd
			endif
		endif

		string  sTxt   = "Window '" + sWnd + "' (still) used " + num2str( nUsed ) + " times. " + SelectString( nUsed, "Will", "Cannot" ) + " delete window."
		 printf "\t\tlbSelResOAProc( DEL 4\trow:%2d\tcol:%2d  evCode:%2d\tevModif:%2d\toldstate:%2d -> %2d \tlstColChans:'%s' -> ch:%2d  rg.%2d  w:%2d  kEIdx:%3d   '%s' -> %s  \r", s.row , s.col, s.eventCode, s.eventMod,  nOldState, nState, lstCol2ChRg, ch, rg, w, rtp, sTyp, sTxt
	endif

	// Check if a  QDP field has been clicked (=click in row  Q0, Q1, Q2, D0....P1, P2   ONLY  in column 0 [here: ch=0] ) : this will open the QDPSources select listbox.
	// If a column > 0 in a QPD row has been clicked the user wants to add the QPD result to the corresponding window.  This case is handled above.
	if ( ch == 0  &&  IsQDP( sFolders, wTxt[ s.row ][ 0 ] ) )				// Binary derived results (=Quot,Diff,Product) exist only once so for the  channel and for the region only the dummy index 0 exists.
		string  	sQDPBase= QDPNm2Base( wTxt[ s.row ][ 0 ]  )		// e.g. 'Qu1'  -> 'Qu' 	
		variable	nQDPIdx	= QDPNm2Nr( wTxt[ s.row ][ 0 ]  )		// e.g. 'Qu1'  -> '1' 	

		if ( s.eventCode == kLBE_MouseDown  &&  !( s.eventMod & kSHIFT ) )	// Only mouse clicks  without SHIFT  are interpreted here.  For some reason in this listbox only MouseDown is detected, whereas in the similar  DataSections  listbox  MouseUp  is detected???
			printf "\t\ttlbSelResOAProc( QDP+5\trow:%2d\t'%s'\t'%s'\tnQDPIdx:%2d\t \r", s.row, wTxt[ s.row ][ 0 ], sQDPBase, nQDPIdx
			LBSelectQDPSources( sFolders )
		else
			printf "\t\ttlbSelResOAProc( QDP-6\trow:%2d\t'%s'\t'%s'\tnQDPIdx:%2d\t \r", s.row, wTxt[ s.row ][ 0 ], sQDPBase, nQDPIdx
		endif
	endif

End

//Function 		Test()
//	string  	sFolders		= "acq:pul"
//	string  	sWin			= ksRES_SEL_OA
//	string  	sCtrlName		= "lbSelectResult"
//	string  	lstOlaRes		= ExtractLBSelectedWindows( sFolders, sWin, sCtrlName )
//	ListBox 	  $sCtrlname,    win = $sWin, 	userdata( lstOlaRes ) = lstOlaRes
//End

Function	/S	ExtractLBSelectedWindows( sFolders, sWin, sCtrlName )
	string  	sFolders, sWin, sCtrlName
	wave	wFlags		= $"root:uf:" + sFolders + ":wSRFlags"
	wave   /T	wTxt			= $"root:uf:" + sFolders + ":wSRTxt"
	string  	sPlaneNm		= "BackColors" 
	variable	pl			= FindDimLabel( wFlags, 2, sPlaneNm )
	string  	lstCol2ChRg 	= GetUserData( 	sWin,  sCtrlName,  "lstCol2ChRg" )			// e.g. for 2 columns '0,0;1,2;'  (Col0 is Ch0Rg0 , col1 is Ch1Rg2) 
	variable	c, nCols		= ItemsInList( lstCol2ChRg ) 							// the number of SrcRegTyp columns (ignoring any window columns) 
	variable	w, nWState													// w=0 is the  'SrcRegTyp' column ,   w=1,2,3  are the windows A,B,C
	variable	ch, rg, nTrueCol, r, nRows	
	string  	sOlaNmW, lstOlaRes = ""														// e.g. 'Peak_00A'
	for ( c = 0; c < nCols; c += 1 )
		ch		= str2num( StringFromList( 0, StringFromList( c, lstCol2ChRg ) , "," ) )	
		rg		= str2num( StringFromList( 1, StringFromList( c, lstCol2ChRg ) , "," ) )	
		w		= 0
		nTrueCol	= c * ( kMAX_OLA_WNDS + 1 ) + w  
		nRows	= DimSize( wTxt, 0 )							// or wFlags
		for ( r = 0; r < nRows; r += 1 )
			if ( strlen( wTxt[ r ][ nTrueCol ] ) )										// process only those window cells (A,B.C) whose RegSrcTyp column is not empty
				for ( w = 1; w < kMAX_OLA_WNDS + 1; w += 1 )
					nWState	= State( wFlags, r, nTrueCol+w, pl )
					if ( nWState )
						sOlaNmW 	= OlaNmW( wTxt[ r ][ nTrueCol ], ch, rg, w ) 			// e.g. 'Peak_00A'
						lstOlaRes	= AddListItem( sOlaNmW, lstOlaRes )
						// printf "\t\tExtractLBSelectedWindows(a)\tr:%2d/%2d\tc:%2d/%2d\tTCol:%2d\tlstColChans:'%s' -> ch:%2d  rg.%2d  w:%2d\t%s\t-> WState:%2d\t-> \t%s\t%s   \r", r, nRows, c, nCols, nTrueCol, lstCol2ChRg, ch, rg, w, pd( wTxt[ r ][ nTrueCol ], 8), nWState, pd(sOlaNmW,13), lstOlaRes
					endif
				endfor
			endif
		endfor
	endfor
	 printf "\t\tExtractLBSelectedWindows(b) '%s'   \r", lstOlaRes
	return	lstOlaRes
End

Function		OlaWindowIsUsedTimes( w, lstOlaRes )
	variable	w
	string  	lstOlaRes
	variable	nUsed	= 0
	variable	n, nItems	= ItemsInList( lstOlaRes )
	for ( n = 0; n < nItems; n += 1 )	
		nUsed	+= WindowMatches( w, StringFromList( n, lstOlaRes ) )
	endfor
	return	nUsed
End

Function		WindowMatches( w, sOneType_ChRgWnd )
	variable	w
	string  	sOneType_ChRgWnd						// e.g.  'Peak_01A'
	variable	len			= strlen( sOneType_ChRgWnd )
	string  	sLastCharacter	= sOneType_ChRgWnd[ len-1, len-1 ]
	return	! abs( cmpstr( AnalWndNm( w-1 ), sLastCharacter ) )
End


// 060317d weg
//static Function	/S	SetChRgTyp( sFolders, ch, rg, row, sTypNr )
//// Stores which results must be computed for any channel/region combination in a 3-sep list.  It is NOT stored in the list in which window the computed results are to be displayed. 
//// FLAW:  processes only   'klstEVL_RESULTS'   but no Fits, Latencies, Computations
//	string  	sFolders
//	variable	ch, rg, row
//	string  	sTypNr											// index kE_IDX as string e.g. '15' for Base.  Empty when removing an entry. 		
//	svar		lstChRgTyp = $"root:uf:" + sFolders + ":lstChRgTyp"			// e.g. ',,,15,,25,,;,,15,;°,,3,,,4,,,;,,5,,,6,,;°,1,,,0,,;0,,2,;'  =  3 chans (sep°) with 2 regions each (sep;) with some results (sep,) 
//	string  	lst1Chan	= StringFromList( ch, lstChRgTyp, ksSEP_TAB )
//	string  	lst1Region	= StringFromList( rg, 	lst1Chan, 	";" )
//  	lst1Region	= ReplaceListItem1( sTypNr, 	 lst1Region,	ksSEP_STD, 	row )
//  	lst1Chan	= ReplaceListItem1( lst1Region,	 lst1Chan, 		";" , 			rg )
//  	lstChRgTyp= ReplaceListItem1( lst1Chan,	 lstChRgTyp,	ksSEP_TAB, 	ch )
//	 printf "\t\tSetChRgTyp( ch:%2d  rg:%2d  sTypNr:'%s'  -> '%s'  \r", ch, rg, sTypNr,  lstChRgTyp
//	return  	lstChRgTyp
//End


Function		Delete1AcqEvalPoint( sFolders, ch, rg, rtp )
// similar 'DisplayEvaluatedPoints()'
	string  	sFolders
	variable	ch, rg, rtp		// e.g.  kE_BASE  or  kE_DT50 , todo implement fit results
	variable	shp	= -1
	// Check whether the eval data points wave exists  (the user may have deleted it)
	string  	sXNm	= AcqPtNmX( ch, rg, rtp )				// e.g. 'Dac0PeakX1
	string  	sYNm	= AcqPtNmY( ch, rg, rtp )				// e.g. 'Adc1BaseY0'
	string  	sFoXNm	= FoAcqPtNmX( sFolders, ch, rg, rtp )		// e.g. 'root:uf:acq:pul:ors:orsDac0PeakX1'
	string  	sFoYNm	= FoAcqPtNmY( sFolders, ch, rg, rtp )		// e.g. 'root:uf:acq:pul:ors:orsAdc1BaseY0'
	wave   /Z	wORsX	= $sFoXNm
	wave   /Z	wORsY	= $sFoYNm
	if ( waveExists( wORsX )  &&  waveExists( wORsY ) )
		// Check if the data point is already in the graph  (the user may have deleted it)
		string   sWnd	= FindFirstWnd( ch )						// possibly find and process window list 
		string   sTNL	= TraceNameList( sWnd, ";", 1 )
		if ( WhichListItem( sYNm, sTNL, ";" )  != kNOTFOUND )		// ONLY if  wave is  in graph...
			// printf "\t\tDelete1AcqEvalPoint()\tch:%d  rg:%d  rtp:%d %s\t  t:\t%8.3lf\t  y:\t%8.3lf\t Shp:%2d\t%s\t(%d)\t APPENDING\t%s\t%s\t'%s'\tX:%g %g\tY:%g %g \r", ch, rg, rtp, pd( StringFromList(rtp, klstEVL_RESULTS),9), x, y, shp, pd(StringFromList( nColor, klstCOLORS),5), nColor, "root:uf:" + sFolders + sXNm, sYNm, sWnd, wORsX[0], wORsY[0], wORsX[1], wORsY[1]
			 printf "\t\tDelete1AcqEvalPoint()   \tch:%d  rg:%d  rtp:%d %s\t  t:\t%8.3lf\t  y:\t%8.3lf\t Shp:%2d\t  \t  \t DELETING   \t%s\t  %s\t'%s'\tX:%g %g\tY:%g %g \r", ch, rg, rtp, pd( StringFromList(rtp, klstEVL_RESULTS),9), x, y, shp, sFoXNm, sYNm, sWnd, wORsX[0], wORsY[0], wORsX[1], wORsY[1]
			RemoveFromGraph /W=$sWnd $sYNm
		endif
		KillWaves wORsX, wORsY
	endif
End

Function		Construct1EvalPntInAcqWnd( sFolders, ch, rg, rtp )
// display the evaluated point in the ACQUISITION window (not in the OLA window). 
// similar 'DisplayEvaluatedPoints()'
	string  	sFolders
	variable	ch, rg, rtp		// e.g.  kE_BASE  or  kE_DT50 , todo implement fit results
	wave	wRed = root:uf:misc:Red, wGreen = root:uf:misc:Green, wBlue = root:uf:misc:Blue

	// Check whether the eval data points wave exists already, if not then construct it
	string  	sXNm	= AcqPtNmX( ch, rg, rtp )				// e.g. 'Dac0PeakX1
	string  	sYNm	= AcqPtNmY( ch, rg, rtp )				// e.g. 'Adc1BaseY0'
	string  	sFoXNm	= FoAcqPtNmX( sFolders, ch, rg, rtp )		// e.g. 'root:uf:acq:pul:ors:orsDac0PeakX1'
	string  	sFoYNm	= FoAcqPtNmY( sFolders, ch, rg, rtp )		// e.g. 'root:uf:acq:pul:ors:orsAdc1BaseY0'
	wave   /Z	wORsX	= $sFoXNm
	wave   /Z	wORsY	= $sFoYNm
	if ( ! waveExists( wORsX )  ||  ! waveExists( wORsY ) )
		string  	sFoldr	= RemoveEnding(  RemoveFromList( sYNm, sFoYNm, ":" ) , ":" )
		variable	shp		= str2num( StringFromList( rtp, klstEVL_SHAPES ) )
		variable	nColor	= WhichListItem( RemoveWhiteSpace( StringFromList( rtp, klstEVL_COLORS ) ), klstCOLORS )
		 printf "\t\tConstruct1EvalPntInAcqWnd()\tch:%d  rg:%d  rtp:%d -> shp:%2d    Constructing folder '%s'  for  '%s'  and  '%s' \t \r", ch, rg, rtp, shp, sFoldr, sFoXNm, sFoYNm
		ConstructAndMakeItCurrentFolder( sFoldr )
		make /O /N=2 	   $sFoXNm	= Nan	// X- and Y-waves containing just 22222222222... evaluated data point
		make /O /N=2 	   $sFoYNm	= Nan
		wave   wORsX	= $sFoXNm
		wave   wORsY	= $sFoYNm
	endif

	string  sWnd	= FindFirstWnd( ch )		// possibly find and process window list 

	// Check if the data point is already in the graph, only if it is yet missing then append it (this avoids multiple instances#1, #2...)
	string 		sTNL	= TraceNameList( sWnd, ";", 1 )
	if ( WhichListItem( sYNm, sTNL, ";" )  == kNOTFOUND )			// ONLY if  wave is not in graph...

		// printf "\t\tConstruct1EvalPntInAcqWnd()\tch:%d  rg:%d  rtp:%d %s\t  t:\t%8.3lf\t  y:\t%8.3lf\t Shp:%2d\t%s\t(%d)\t APPENDING\t%s\t%s\t'%s'\tX:%g %g\tY:%g %g \r", ch, rg, rtp, pd( StringFromList(rtp, klstEVL_RESULTS),9), x, y, shp, pd(StringFromList( nColor, klstCOLORS),5), nColor, "root:uf:" + sFolders + sXNm, sYNm, sWnd, wORsX[0], wORsY[0], wORsX[1], wORsY[1]
		 printf "\t\tConstruct1EvalPntInAcqWnd()\tch:%d  rg:%d  rtp:%d %s\t  t:\t%8.3lf\t  y:\t%8.3lf\t Shp:%2d\tCo:%2d\t APPENDING\t%s\t  %s\t'%s'\tX:%g %g\tY:%g %g \r", ch, rg, rtp, pd( StringFromList(rtp, klstEVL_RESULTS),9), x, y, shp, nColor, sFoXNm, sYNm, sWnd, wORsX[0], wORsY[0], wORsX[1], wORsY[1]
		AppendToGraph /W=$sWnd wORsY vs wORsX
		ModifyGraph 	 /W=$sWnd  rgb( 	$sYNm )	= ( wRed[ nColor ], wGreen[ nColor ], wBlue[ nColor ] ) 
		if ( shp == cLLINEH  ||  shp == cLLINEV )
			ModifyGraph 	 /W=$sWnd  mode( 	$sYNm )	= 0		// 0 : lines, 3 : markers ,  4 : lines + markers
		else
			ModifyGraph 	 /W=$sWnd  mode( 	$sYNm )	= 3		// 0 : lines, 3 : markers ,  4 : lines + markers		
			ModifyGraph 	 /W=$sWnd  marker( 	$sYNm )	= shp
			variable	size	= ( shp == cSLINEH  ||  shp == cSLINEV  ||  shp == cSCROSS ||  shp == cXCROSS ) ? 10 : 0	// Rect and Circle have automatic size = 0
			ModifyGraph 	 /W=$sWnd  msize( 	$sYNm )	= size
		endif
//	else
//		// printf "\t\tDisplay1EvalPoint()\tch:%d  rg:%d  pt:%d %s\t  t:\t%8.3lf\t  y:\t%8.3lf\t  Shp:%2d\t%s\t(%d)\tWaves exist \t%s\t...%s\r", ch, rg, n, pd( StringFromList(n, klstEVL_RESULTS),9), x, y, shp, pd(StringFromList( nColor, klstCOLORS),5), nColor, "root:uf:eva" + sChRgNFolder + sXNm,  sYNm
	endif
End


//---------- Naming for small (=1 or 2 point)  X-Y-waves containing the currently evaluated result (e.g. Peak, Base) which is drawn as a line (=Base)  or cross (=Peak) in the Acq window just over the original trace as a visual check  ------------
Function	/S	FoAcqPtNmX( sFolders, ch, rg, rtp )
	string  	sFolders			// e.g.  'acq:pul'  or  'eva:de'
	variable	ch, rg, rtp		// e.g.  kE_BASE  or  kE_DT50 , todo implement fit results
	return	"root:uf:" + sFolders + ":" + ksORS + ":" +  AcqPtNmX( ch, rg, rtp )
End
Function	/S	FoAcqPtNmY( sFolders, ch, rg, rtp )
	string  	sFolders			// e.g.  'acq:pul'  or  'eva:de'
	variable	ch, rg, rtp		// e.g.  kE_BASE  or  kE_DT50 , todo implement fit results
	return	"root:uf:" + sFolders + ":" + ksORS + ":" +  AcqPtNmY( ch, rg, rtp )
End
Function	/S	AcqPtNmX( ch, rg, rtp )
	variable	ch, rg, rtp		// e.g.  kE_BASE  or  kE_DT50 , todo implement fit results
	//string  	sAcqPtNm	= RemoveWhiteSpace( StringFromList( rtp, klstEVL_RESULTS ) ) + "_X_" + num2str( ch ) + "_" + num2str( rg )		// e.g. 'Base_X_0_1'
	string  	sAcqPtNm	= ksORS + RemoveWhiteSpace( StringFromList( rtp, klstEVL_RESULTS ) ) + "_X_" + num2str( ch ) + "_" + num2str( rg )	// e.g. 'orBase_Y_0_1'
	// printf "\t\t\tAcqPtNmX( ch:%2d,  rg:%2d,  rtp:%3d )  returns '%s'  \r", ch, rg, rtp, sAcqPtNm
	return 	sAcqPtNm
End
Function	/S	AcqPtNmY( ch, rg, rtp )
	variable	ch, rg, rtp		// e.g.  kE_BASE  or  kE_DT50 , todo implement fit results
	//string  	sAcqPtNm	= RemoveWhiteSpace( StringFromList( rtp, klstEVL_RESULTS ) ) + "_Y_" + num2str( ch ) + "_" + num2str( rg )		// e.g. 'Base_Y_0_1'
	string  	sAcqPtNm	= ksORS + RemoveWhiteSpace( StringFromList( rtp, klstEVL_RESULTS ) ) + "_Y_" + num2str( ch ) + "_" + num2str( rg )	// e.g. 'orBase_Y_0_1'
	// printf "\t\t\tAcqPtNmX( ch:%2d,  rg:%2d,  rtp:%3d )  returns '%s'  \r", ch, rg, rtp, sAcqPtNm
	return 	sAcqPtNm
End
//------------------------------------------------


Function	/S	ListACVAllChansOA()
// Returns list of titles of  'All Currently Computed Values'  which depends on the number of regions, the number and types of the fits and on the latencies, but not yet on the listbox
	variable	ch
	variable	nChans		= ItemsInList( LstChAcq(), ksSEP_TAB )
	string 	lstACVAllCh	= ""
	for ( ch = 0; ch < nChans; ch += 1 )
		lstACVAllCh	+= ListACVOA( ch )
	endfor
	 printf "ListACVAllChansOA()  has %d items, %s...%s \r", ItemsInList( lstACVAllCh ),  lstACVAllCh[0,80],  lstACVAllCh[ strlen( lstACVAllCh )-80, inf ]  
	return	lstACVAllCh
End

Function	/S	ListACVOA( ch )
// Returns complete list of titles of  'All Currently Computed Values'  which depends on the number of regions, the number and types of the fits and on the latencies, but not yet on the listbox
	variable	ch
	string  	sFolders	= ksF_ACQ_PUL 
	variable	nRegs	= RegionCnt(  sFolders, ch )
	variable	rg
	string  	lstACV	= ""
	for ( rg = 0; rg < nRegs; rg += 1 )
		lstACV	+= ListACV1RegionOA( ch, rg )
	endfor
	 printf "\t\tListACVOA( ch:%2d )  Items:%3d,  '%s' ... '%s'   \r", ch, ItemsInList( lstACV ), lstACV[0,80],  lstACV[ strlen( lstACV )-80, inf ]  
	return	lstACV
End

Function	/S	ListACV1RegionOA( ch, rg )
// Returns complete list of titles of  'All Currently Computed Values'  which depends on the number of regions, the number and types of the fits, but not yet on the listbox
	variable	ch, rg
	string  	sFolders	= ksF_ACQ_PUL
	variable	nChans	= ItemsInList( LstChAcq(), ksSEP_TAB )
	variable	LatCnt	= LatencyCntA() 
	string  	lstACV	= ""
	lstACV	+= ListACVGeneralTableOLA( sFolders, ch, rg )			
	lstACV	+= ListACVFitOLA( sFolders, ch, rg )					// generic.....not yet...???...
	lstACV	+= ListACVLat( sFolders, ch, rg, nChans, LatCnt )			// generic
	if ( ch == 0  &&  rg == 0 )
		lstACV	+= ListACV_QDP( sFolders , ch, rg ) 				// binary derived results (=Quot,Diff,Product) exist only once so the  channel/region concept is useless. Alternate approach (not taken): construct separate single column listbox only for QDP.
	endif
	 printf "\t\tListACV1OA( ch:%2d/%2d  rg:%2d  LC:%2d )  Items:%3d,  '%s' ... '%s'   \r", ch, nChans, rg, LatCnt, ItemsInList( lstACV ), lstACV[0,80],  lstACV[ strlen( lstACV )-80, strlen( lstACV )-1 ]  
	return	lstACV
End

Function	/S	ListACVGeneralTableOLA( sFolders, ch, rg )
// Returns complete list of titles of the general (=Non-fit)  'All Currently Computed Values'  which depends on the number of regions, the number and types of the fits, but not yet on the listbox
	string  	sFolders			// e.g. 	'acq:ola'  or  'eva:de'
	variable	ch, rg
	string  	sPostfx		= Postfix( ch, rg )
	string		lst			= ""
// todo possibly : use other selection parameters than  klstEVL_SHAPES
	variable	shp, pt, nPts	= ItemsInList( klstEVL_RESULTS )
	for ( pt = 0; pt < nPts; pt += 1 )
		shp	= str2num( StringFromList( pt, klstEVL_SHAPES ) )					// 
		if ( numtype( shp ) != kNUMTYPE_NAN ) 								// if the shape entry is not empty it must be drawn
			lst	= AddListItem( EvalNm( pt ) + sPostfx, lst, ";", inf )					// the general values : base, peak, etc
		endif
	endfor

	return	lst
End

Function	/S	ListACVFitOLA( sFolders, ch, rg )
// Returns list of all FitParameters, FitStartParameters and FitInfoNumbers (e.g. nIter, ChiSqr)  for the fit function specified by channel and region 
	string  	sFolders			// e.g. 	'acq:ola'  or  'eva:de'
	variable	ch, rg
	string  	lst		= ""	
	variable	fi, nFits	=  ItemsInList( ksPHASES ) - PH_FIT0
	for ( fi = 0; fi < nFits; fi += 1 )
		nvar		bFit		= $"root:uf:" + sFolders + ":cbFit" + num2str( ch ) + num2str( rg )  + num2str( fi ) + "0"	
		if ( bFit )
			lst	= ListACVFitOA( lst, sFolders, ch, rg, fi )
		endif
	endfor
	 printf "\t\tListACVFitOLA(\t'%s'\tch:%2d, rg:%2d )\t\t\treturns lst: '%s'  \r", sFolders, ch, rg, lst[0,200]
	return	lst
End	

Function	/S	ListACVFitOA( lst, sFolders, ch, rg, fi )
// !!! Cave: If this order (Params, derived Params)  is changed the extraction algorithm ( = ResultsFromLB_OA() ) must also be changed 
	string  	lst, sFolders
	variable	ch, rg, fi
	variable	pa, nPars
	variable	nFitInfo, nFitInfos	= FitInfoCnt()
	variable	nFitFunc			= FitFnc( sFolders, ch, rg, fi )
	nPars	= ParCnt( nFitFunc )					
	for ( pa = 0; pa < nPars; pa += 1 )				// the fit  parameters: 	  A0, T0, A1, T12,  Constant, Slope etc.-> Fit1_A0, Fit1_T0...
		lst	= AddListItem( FitParInLBNm( ch, rg, fi, pa, nFitFunc ),  lst, ";" , inf )			// e.g. 'Fit1_A0_00'
	endfor
	variable nDerived = DerivedCnt( nFitFunc )
	for ( pa = 0; pa < nDerived; pa += 1 )				// the derived parameters: wTau, Capacitance, ...
		lst	= AddListItem( FitDerivedInLBNm( ch, rg, fi, pa, nFitFunc ),  lst, ";" , inf )			// e.g. 'Fit1_WTau_00'
	endfor
	 printf "\t\tListACVFitOA(\t%s\tch:%2d, rg:%2d, fi:%2d )\treturns lst: '%s'  \r", sFolders, ch, rg, fi, lst[0,200]
	return	lst
End


Function		fOLAXAxis( s )
	struct	WMPopupAction	&s
	 printf "\tfOLAXAxis()   control is '%s'   bValue:%d \r", s.Ctrlname, 123
	string  	sControlNm
	variable	bValue
	RedrawAnalysisWndAllTraces()
End

Function		RedrawAnalysisWndAllTraces()
// 060321 revive again
//	variable	w, wCnt		= ItemsInList( AnalysisWindows() )
//	for ( w = 0; w < wCnt;  w += 1 )
//		string  	sWNm	= StringFromList( w, AnalysisWindows() )
//		if ( WinType( sWNm ) == kGRAPH )
//			string  	sTNL	= TraceNameList( sWNm, ";", 1 )
//			variable	t,  tCnt	=  ItemsInList( sTNL ) 
//			 printf "\t\tRedrawAnalysisWndAllTraces() \twnd:%s has %d traces   [TrcNmList: %s..] \r", sWNm, tCnt, sTNL[0,160]	
//			for ( t = 0;  t < tCnt; t += 1 )	
//				string  	sTrc		= StringFromList( t, sTNL ) 	
//				DrawAnalysisWndTrace( sWNm, sTrc )
//			endfor
//			DrawAnalysisWndXUnits( sWNm )	
//		endif
//	endfor
End

Function		fClearAnalysisWnd( s )
	struct	WMButtonAction	&s
	ClearAnalysisWnd()
End


Function		fBlankPause( s )
// 060228 THIs is wrong : points are swallowed.................
	struct	WMCheckboxAction	&s
	string  	sFolders	= ksF_ACQ_PUL 
	 printf "\t   TODO....fBlankPause()   control is '%s'    bValue:%d  sFolder:%s \r", s.Ctrlname, s.checked, sFolders
	string  	lstOlaNm, sOLANm, sSrc, sEventNm	= "Evnt"					// Flaw / Assumption
	wave	wEvent		= $FolderOlaDispNm( sEventNm ) 	
	variable	nType, n, nPts	= numPnts( wEvent )
//	variable	nP, t , tCnt	= RegionPhsCnt()	
//	variable	nP, tCnt	= 1

	string  	sChans	= LstChAcq()

// 060317e weg
// 060315
//	svar		lstChRgTyp = $"root:uf:" + sFolders + ":lstChRgTyp"			// e.g. ',,,15,,25,,;,,15,;°,,3,,,4,,,;,,5,,,6,,;°,1,,,0,,;0,,2,;'
//	variable	ch, nChans	= ItemsInList( lstChRgTyp, ksSEP_TAB )
//	for ( ch = 0; ch <  nChans; ch += 1 )
//		string  	lst1Chan	= StringFromList( ch, lstChRgTyp, ksSEP_TAB )
//		sSrc		= StringFromList( ch, sChans, ksSEP_TAB )
//		variable	rg, nRegions	= ItemsInList( lst1Chan, ";" )	// = RegionCnt( sFolders, ch )			// For all  channel/region combinations  which the user has defined 
//		for ( rg = 0; rg <  nRegions; rg += 1 )									// For all  channel/region combinations  which the user has defined 
//			string  	lst1Region	= StringFromList( rg, 	lst1Chan, 	";" )
//
//			variable	t, nTypes	= ItemsInList( lst1Region, ksSEP_STD )
//			for ( t = 0; t <  nTypes; t += 1 )	
//				string  	sTyp	= StringFromList( t, lst1Region, ksSEP_STD ) 								// For all  channel/region combinations  which the user has defined 
//				if ( strlen( sTyp ) )
//					variable	rtp	= str2num( sTyp )
//					string  	sName	= RemoveLeadingWhiteSpace( StringFromList( rtp, klstEVL_RESULTS ) )	// rtp=rtp
//// 060315
//				 	sOlaNm 	= OlaNm( sSrc, sName, rg ) 
//					wave	wOlaDisp	= $FolderOlaDispNm( sOLANm ) 	
//					if ( ! s.checked )													// Fill the pauses = connect data points even during pauses....
//						for ( n = 0; n < nPts - 1; n += 1 )
//							if ( numType( wOlaDisp[ n ] ) == kNUMTYPE_NAN )
//								wOlaDisp[ n ]	= wOlaDisp[ n + 1] 						// Fill the pauses : reset the Nan Y value to that of the successor point...
//								wEvent [ n ]	= wEvent[ n + 1 ]						//...reset the X value to that of  the successor point as a marker..   Done too often , once would be sufficient....						
//							endif													// ..the event is changed not for the display but to have a marker which points must be restored
//						endfor
//					else												//	s.checked = TRUE										// Blank the pauses...
//						for ( n = 0; n < nPts - 1; n += 1 )
//							if ( wEvent [ n ] ==  wEvent[ n + 1 ] )							// These points are marked and must be restored
//								wOlaDisp[ n ]	=  Nan								// Blank the pauses: first set the Y values to Nan ...
//							endif							
//						endfor
//					endif
//				endif
//			endfor
//		endfor
//	endfor
//	if ( s.checked )													// Fill the pauses = connect data points even during pauses....
//		for ( n = 0; n < nPts - 1; n += 1 )
//			if ( wEvent [ n ] ==  wEvent[ n + 1 ] )								// These points are marked and must be restored
//				wEvent [ n ]	=  wEvent[ n ] - 1 							// then set the X value to the value of the precessor point				
//			endif							
//		endfor
//	endif
End



Static  Function		DrawAnalysisWndTrace( sWNm, sOLANm, rtp )
	string  	sWNm, sOLANm
	variable	rtp
	variable	rnType
	wave	wRed = root:uf:misc:Red, wGreen = root:uf:misc:Green, wBlue = root:uf:misc:Blue
	nvar		bBlankPause	= root:uf:acq:pul:bBlankPause0000
	nvar		nXAxis		= root:uf:acq:pul:pmXAxis0000
	variable	nMode, nColor	= WhichListItem( RemoveWhiteSpace( StringFromList( rtp, klstEVL_COLORS ) ), klstCOLORS )
	string  	sTraceInfo, rsSrc
		
	if ( WhichListItem( sOLANm, TraceNameList( sWNm, ";", 1 ) )  !=  kNOTFOUND )	
		sTraceInfo	= TraceInfo( sWNm, sOLANm, 0 )						// The trace exists and the color and mode are retrieved directly from the trace (called when switching the X axis scaling)
		nMode	= NumberByKey( "mode(x)", sTraceInfo, "=" )
	endif

	 printf "\t\t\tDrawAnalysisWndTrace( %s\t%s\tnRes: %d )   Rgb:\t%7d\t%7d\t%7d\t  Mode: %d    \t'%s' \tXAxis:%d BlankP:%d  \r", sWNm, pd( sOLANm,9),  1234, wRed[ nColor ], wGreen[ nColor ], wBlue[ nColor ], nMode, "root:uf:acq:ola:wa:" + sOLANm + "_" + sWNm,  nXAxis, bBlankPause

	// The waves to be appended should exist already before the user started the first acquisition.
	wave  /Z	wOlaDisp	= 	$FolderOlaDispNm( sOLANm ) 	 				
	if ( ! waveExists( wOlaDisp ) )
		InternalError( "DrawAnalysisWndTrace(): Does not exist : '" + FolderOlaDispNm( sOLANm ) ) 	
	endif
	string  	sEvntSecMin	= StringFromList( nXAxis-1, lstRESfix )				// 'Evnt' , 'Tim_'  or 'Minu'	
	wave   /Z	wX			= $FolderOlaDispNm( sEvntSecMin )				//  X  AXIS  is  frames, seconds or minutes
	if ( waveExists( wX ) )
		AppendToGraph /W=$sWNm	wOlaDisp vs  wX
		ModifyGraph 	/W=$sWNm	rgb( 	$sOLANm )	= ( wRed[ nColor ], wGreen[ nColor ], wBlue[ nColor ] ) 
		ModifyGraph	/W=$sWNm	mode( $sOLANm )	= nMode 			// 4: connect and mark points with +, 3 : only markers +
	endif

End


Function		DrawAnalysisWndXUnits( sWNm )
	string  	sWNm
	nvar		nXAxis	= root:uf:acq:pul:pmXAxis0000
	string  	sXUnits	= StringFromList( nXAxis-1, lstXUNITS )				// As Igor does not plot units automatically in the XY mode (like in the normal mode using 'SetScale x ' )...
	TextBox /W=$sWNm /N=tbXAxis /C /A=MB /E=2  /F=0	/Y=0  sXUnits	//...we display the units  's' , 'frame', ... as a Textbox
End


//Function		buAnalPrintRegions( ctrlName ) : ButtonControl
//	string 	ctrlName
//	PrintRegions()
//End


//=======================================================================================================================================================

//static strconstant	csANALWNDBASE	= "A"	// The name should NOT start with 'W' as any window will be erased by  'KillTracesInMatchingGraphs( "W*" )'  when a script is loaded or applied

Static  Function	/S	AnalWndNm( w )
	variable	w
	// return	csANALWNDBASE + num2str( w )		// A0, A1  or  W0, W1...	needs  kLBOLA_COLWID_WND = 20
	// return	num2char( 97 + w )					// a, b, c...			needs  kLBOLA_COLWID_WND = 12
	return	num2char( 65 + w )					// A, B, C...			needs  kLBOLA_COLWID_WND = 14
End

// currently not needed
//Function		AnalWndNm2W( sWNm )
//	string  	sWNm	
//	//return	str2num( sWNm[ 1, inf ]				// A0, A1  or  W0, W1...	needs  kLBOLA_COLWID_WND = 20
//	//return	char2num( sWNm ) - 97				// a, b, c...			needs  kLBOLA_COLWID_WND = 12
//	return	char2num( sWNm ) - 65				// A, B, C...			needs  kLBOLA_COLWID_WND = 14
//End

Static  Function  /S	AnalysisWindows()
// returns list of OLA result windows
	variable	w
	string  	sWNm, sWinList = ""
	// sWinList	= WinList( csANALWNDBASE + "*" , ";" , "WIN:1" )	// Special case: works only for graph window names starting with csANALWNDBASE  e.g. 'A*'  or  'W*'
	for ( w = 0; w < kMAX_OLA_WNDS; w += 1 )					// General case: 
		sWNm	 =  AnalWndNm( w )							// works for graph window names starting with csANALWNDBASE  e.g. 'A*'  or  'W*' ....
		if ( ( WinType( sWNm ) == kGRAPH ) )						//  ...and also works for graph window names e.g.  'A' , 'B' , 'C'
			sWinList	+= sWNm + ";"
		endif	
	endfor
	 printf "\t\tAnalysisWindows() returns sWinList: '%s' \r", sWinList
	return	sWinList
End


Static  Function	/S	PossiblyAddAnalysisWnd( w )
// Construct and display  1 additional  Analysis windows with the next default name
	variable	w
	variable	wCnt		= kMAX_OLA_WNDS
	string 	sWNm	= AnalWndNm( w )
	variable	rnLeft, rnTop, rnRight, rnBot										// place the window in top half to the right of the acquisition windows 
	GetAutoWindowCorners( w, wCnt, 0, 1, rnLeft, rnTop, rnRight, rnBot, kWNDDIVIDER, 100 )	// row, nRows, col, nCols
	if (  ! ( WinType( sWNm ) == kGRAPH ) )										//  There is no 'Analysis' window
		Display /K=2 /N=$( sWNm ) /W= ( rnLeft, rnTop, rnRight, rnBot ) 					// K=2 : disable killing	 . The user must kill a window with button 'Remove' to preserve ordering.	
	endif
	return	sWNm
End


static	  Function		ClearAnalysisWnd()
// the waves are not really killed (but could be should ever need arise) , only the flag is set telling that the waves need to be rebuilt.
	nvar		gOLAFrmCnt	= root:uf:acq:ola:gOLAFrmCnt
	nvar		gnStartTicksOLA= root:uf:acq:ola:gnStartTicksOLA

	gOLAFrmCnt		= 0
	gnStartTicksOLA	= ticks							// Resetting the ticks here will start the clock after the first region has been defined ( probably better: when acquisition starts )  

	variable	w, wCnt	= ItemsInList( AnalysisWindows() )
	for ( w = 0; w < wCnt;  w += 1 )
		string  	sWNm	= StringFromList( w, AnalysisWindows() )

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


//=======================================================================================================================================================
//  CALLED  REGULARLY  DURING  ACQUISITION

static Function		AnalysisIsOn()
// returns TRUE when at least one user region is defined    or  FALSE = 0  when no user region is defined
	return	TRUE//RegionPhsCnt() > 0
End

// 031007  !    NOT  YET  REALLY  PROTOCOL  AWARE ............
Function		OnlineAnalysis( sFolders, wG, wIO, pr, bl, fr )
// This function is called once per frame  during acquisition from the background task. It is called in parallel to 'DispDuringAcqCheckLag()'  and  'WriteDatasection()'  
	string  	sFolders
	wave  	wG
	wave  /T	wIO
	variable	pr, bl, fr
	nvar		gOLAFrmCnt	= root:uf:acq:ola:gOLAFrmCnt
	nvar		gnStartTicksOLA= root:uf:acq:ola:gnStartTicksOLA

	if (  AnalysisIsOn() )										// If no cUSER region is defined we skip the whole analysis (this must be refined if there are analysis types requiring no cUSER region)
		if ( gOLAFrmCnt	== 0 )
			gnStartTicksOLA	= ticks						// Resetting the ticks here will start the clock after the first region has been defined ( probably better: when acquisition starts )  
		endif
		if ( pr == 0  &&  bl == 0  &&  fr == 0 )						// Insert a pause for every new protocol by  inserting a Nan rather than data in the display trace.
			gOLAFrmCnt	+= 1	
			AppendNanInDisplayWave( gOLAFrmCnt, ksRES_SEL_OA )// Inserting a Nan rather than data in the display trace marks those points as separators and allows blanking out intervals between protocols.	
		endif													
		gOLAFrmCnt	+= 1	
		OLA1Point( sFolders, wG[ kSI ], wIO, pr, bl, fr, gOLAFrmCnt )			// 051210					
	endif
End												

// 060314
static Function		AppendNanInDisplayWave( index, sWin )
// Construct   ALL POSSIBLE  OLA display  waves (also those that are not displayed) . Construct them  with 1 Nan point to blank out the data point.
	variable	index
	string  	sWin
	string  	lstACVAllCh 	= GetUserData( 	sWin,  "",  "lstACVAllCh" )	
	
	AppendPointToTimeWaves( index )

	variable	len, n, nItems	= ItemsInList( lstACVAllCh )	
	 printf "\t\t\tAppendNanInDisplayWave()\tlstACVAllCh has items:%3d <- \t '%s .... %s' \r", nItems, lstACVAllCh[0,80] , lstACVAllCh[ strlen( lstACVAllCh ) - 80, inf ]

	string 	sOneItemIndexed
	for ( n = 0; n < nItems; n += 1 )
		sOneItemIndexed	= StringFromList( n, lstACVAllCh )				// e.g. 'Base_010'
		NewElementOlaDisp( sOneItemIndexed, index ) 				// Returns TRUE if a new wave has just been constructed.
	 	SetElementOlaDisp( sOneItemIndexed, index, Nan )			// Nan allows blanking out intervals between protocols.
	endfor
End



Function	/S	OlaNm( sSrc, sName, rg ) 		// OBSOLETE
	string	  	sSrc, sName
	variable	rg

// 060314
	//return	sSrc + sName 							// e.g. 'Adc1Base'
//	return	sSrc + "_" + sName + "_" + num2str( rg ) 		// e.g. 'Adc1_Base_0'

// 060315  WRONG
	string  	sOlaNm	= "Peak" + "_" + num2str( 0 ) + num2str( rg ) 		

	// printf "\t\t\tOlaNm %s %s %d    old: '%s'     new: '%s' \r",  sSrc, sName, rg , sSrc + "_" + sName + "_" + num2str( rg ) , sOlaNm
	return "Peak" + "_" + num2str( 0 ) + num2str( rg ) 		
End


Function	/S	OlaNm1( sTyp, ch, rg ) 							
	string  	sTyp
	variable	ch, rg
	string  	sOlaNm	= sTyp + "_" + num2str( ch ) + num2str( rg )					// e.g. 'Peak_00'
	return	sOlaNm
End


Function	/S	OlaNmW( sTyp, ch, rg, w ) 							
	string  	sTyp
	variable	ch, rg, w
	string  	sOlaNmW	= sTyp + "_" + num2str( ch ) + num2str( rg ) + AnalWndNm( w-1 )	// e.g. 'Peak_00A'
	return	sOlaNmW
End


Static  Function		OLANmR( sOLANm, rsSrc, rnType, sList )
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



static Function		AppendPointToTimeWaves( index )
//  Construct the waves  'Evnt'  , 'Tim_'  and  'Minu'  which are used as  XAxis .   'Prot' , Blck' , 'Fram'  could be but are not constructed here as they are not needed for the display. 
	variable	index
	nvar		gnStartTicksOLA	= root:uf:acq:ola:gnStartTicksOLA
	variable	value, n, seconds	= ( ticks - gnStartTicksOLA ) / kTICKS_PER_SEC
	for ( n = 0; n < ItemsInList( lstRESfix ); n += 1 )
		if ( n == cEVNT)				// Not very elegant, but Igor does not interpret nested conditional assignments correctly : WRONG : value = ( n == cEVNT )  ?  index - 1 : ( n == cTIME )   ?  seconds : seconds / 60	
			value	= index - 1 
		elseif ( n == cTIME )
			value	= seconds
		else	// n == cMINU 
			value	= seconds / 60
		endif
		string  	sOLANm	= StringFromList( n, lstRESfix ) 							
		// printf "\t\tAppendPointToTimeWaves\tindex:\t%3d   \tn: %d \t\t%s\t= %8.2lf\tseconds= %8.2lf\t\t ( sOlaNm: %s )\r", index, n, pd( StringFromList( n, lstRESfix ), 12), value, seconds, sOlaNm
		NewElementOlaDisp( sOLANm, index )
		SetElementOlaDisp( sOLANm, index, value )				//  Add   'Event'  , 'Time'  and  'Minu'   to display wave . Starting at 0 allows to use this wave as XAxis
	endfor
	return	seconds
End


// 051210 new
static Function	OLA1Point( sFolders, nSmpInt, wIO, pr, bl, fr, index )
// Function for online evaluation
// Design issue: the OLA is frame-oriented : it is executed once every frame, sweeps are ignored 
	string  	sFolders
	variable	nSmpInt
	wave  /T	wIO
	variable	pr, bl, fr, index
	string  	sFolder		= StringFromList( 0, sFolders, ":" )

	nvar		gOLAHnd		= root:uf:acq:ola:gOLAHnd
	variable	bWriteMode	= WriteMode()
	svar		sDataDir		= root:uf:cfsw:gsDataDir							// use same path...
	svar		sDataFileW	= root:uf:acq:pul:gsDataFileW0000					// ...and file name as CFS file...
	variable	BegPt		= FrameBegSave( sFolder, pr, bl, fr )		// could this simplify BResultXShift  ???? (see 070424)
	string  	lstOLANm, sOLANm, sOLANmBP 
	string  	sSrc, sLine 	= ""
	variable	nP, n
	
	string  	sChans	= LstChAcq()
	variable	ch = 0, nChans	= ItemsInList( sChans ,  ksSEP_TAB )

	variable	rg = 0, nRegions
	variable	nState = 1
	string  	lstIndices, lstNames, sName
	variable	t, nTypes

variable	len, rtp
variable	PtLeft, PtRight, XaxisLeft = 0
variable	Gain, ph, SIFact, PkDir
string  	sType, sXNm, sYNm, sFoXNm , sFoYNm 

	wave  	wOLARes	= $"root:uf:" + ksF_ACQ_PUL + ":wOLARes"				// is needed only for  temporary storage of peak and base to later compute Quot. 2 variables are sufficient?

//	variable	nRegions	= RegionPhsCnt()		
//	variable	nResults	= ItemsInList( ActiveResults() )
//	
//	printf "\t\t\tOLA1Point(a) \t\t\t\tpr: %d   bl: %d  fr: %d \tgOLAFrmCnt: %d\t\t'%s'\t'%s'  \r", pr, bl, fr, index, sFolder, sFolders
//
//	//  Step 1 :  Open  the OLA file
//	if ( gOLAHnd == kNOT_OPEN  )											
//		// Open the OLA result file using	the same path and file name as CFS file  but with another extension  
//		if ( bWriteMode )			
//			string  	sOLAPath	 = StripExtension( sDataDir + sDataFileW ) + sOLAEXT	//  OLA file is always written in parallel to CFS. If CFS is not written OLA is neither (could be changed...) 
//			// printf "\t\tOnlineAnalysis1()  bWriteMode is %s opening '%s' \r", SelectString(  bWriteMode, " OFF :  NOT ", " ON : " ), sOLAPath
//			variable	nOLAHnd
//			Open  nOLAHnd  as sOLAPath
//			gOLAHnd = nOLAHnd
//			if ( gOLAHnd == kNOT_OPEN  )	
//				FoAlert( sFolder, kERR_FATAL,  "Could not open Online analysis file '" + sOLAPath + "' ." )
//				return	kERROR
//			endif
//		endif
//	endif

	variable	seconds	= AppendPointToTimeWaves( index )

//	//  Add  'Event' , 'Prot' , 'Blck' , 'Fram'  and 'Tim_'  to file with  custom  formatting.
//	sprintf 	sLine, "%s%s%3d;%s%s%3d;%s%s%3d;%s%s%3d;%s%s%10.1lf;" , StringFromList( cEVNT, lstRESfix ), ksSEP_EQ, index - 1, StringFromList( cPROT, lstRESpbf ), ksSEP_EQ, pr, StringFromList( cBLCK, lstRESpbf ), ksSEP_EQ, bl, StringFromList( cFRAM, lstRESpbf ), ksSEP_EQ, fr, StringFromList( cTIME, lstRESfix ), ksSEP_EQ, seconds  	



	// Step 5 : Construct the waves  which are displayed in the Analysis window  e.g.  Adc1Base, Adc0RTim, etc...
	string  	sWin			= ksRES_SEL_OA
	string  	sCtrlName		= "lbSelectResult"
	string  	lstOlaRes	 	= GetUserData( 	sWin,  sCtrlName,  "lstOlaRes" )		// e.g. 'Base_00A;Peak_00B;F0_A0_01B;' : which OLA results in which OLA windows

	// Add value to OLA display.
	// If any 'Basics' result (= result from 'klstEVL_RESULTS') for a specific channel/region combination is selected in the listbox then evaluate first both  Base and  Peak (which are required anyway)  and then evaluate the selected result.
	// Evaluate  Base and  Peak  only once  for  multiple selected results.
	// to think:  latencies may (later) need any  selected result   so we might save on  going through various evaluation conditions by  evaluating  ALL 'Basics' results by default  at the expense of some additional computing time  

	variable	nItems	= ItemsInList( lstOlaRes ) 
	for ( n = 0; n < nItems; n += 1 )	
		sOlaNm		= RemoveEnding( StringFromList( n, lstOlaRes ) )  			// !!! Assumption naming  :  truncate the window name (= A, B or C)
		len			= strlen( sOlaNm )
		ch			= str2num( sOlaNm[ len-2, len-2 ] )
		rg			= str2num( sOlaNm[ len-1, len-1 ] )
		sSrc			= StringFromList( ch, LstChAcq(), ksSEP_TAB )
		wave /Z   wOrg	= $ksROOTUF_ + ksACQ_ + ksF_IO_ + sSrc

		if ( n == 0  ||  IsNewChannelRegion( ch, rg ) )
			SetMustCompute( wOLARes, ch, rg ) 
			//ResetBaseAndPeak( wOLARes, ch, rg ) 
		endif

//		//  REGION - RESULT - CONNECTION - SPECIFIC 1
//		// The data points previously stored in 'wResult[ region type ][ 0 ]'  are  combined to give output results for file and display e.g. 'Peak' - 'Base' = 'Ampl'  
//		// Here the connection is made between regions (to be evaluated)  and  results (to be printed and displayed, possibly from various regions)
//		// Add the data point to  the 1 dimensional (Frames) result wave used to display data 1 frame after the other

		Gain		= GainByNmForDisplay( wIO, sSrc )
		SIFact	= nSmpInt / kXSCALE
		XaxisLeft	= 0

		// Process  'Base'  and  'Peak'  only once for each channel/region combination 
		if ( MustCompute( wOLARes, ch, rg ) )
		
			// Prepare for adding  value  to  Acquisition display.
			//sType 	= "Base"											// !!! Assumption naming  e.g.  'Peak_01'  ->  'Peak'
			//rtp		= WhichListItemIgnoreWhiteSpace( sType, klstEVL_RESULTS )	// = kE_BASE
			rtp		= kE_BASE
			sType	= EvalNm( rtp )									// 'Base'
			sOlaNmBP	= OlaNm1( sType, ch, rg )
			// 060316 Base and peak are here auto-constructed so we might avoid constructing them elsewhere
			Construct1EvalPntInAcqWnd( sFolders, ch, rg, rtp )				// Construct  'wAcqPt'  .
			sXNm	= AcqPtNmX( ch, rg, rtp )							// e.g. 'Dac0PeakX1
			sYNm	= AcqPtNmY( ch, rg, rtp )							// e.g. 'Adc1BaseY0'
			sFoXNm	= FoAcqPtNmX( sFolders, ch, rg, rtp )					// e.g. 'root:uf:acq:pul:ors:orsDac0PeakX1'
			sFoYNm	= FoAcqPtNmY( sFolders, ch, rg, rtp )					// e.g. 'root:uf:acq:pul:ors:orsAdc1BaseY0'
			wave  /Z	wORsX	= $sFoXNm
			wave  /Z	wORsY	= $sFoYNm

			ph					= kOA_PH_BASE
			PtLeft				= BegPt + Region( sFolders, ch, rg, ph, kOABE_BEG ) / SIFact	
			PtRight				= BegPt + Region( sFolders, ch, rg, ph, kOABE_END ) / SIFact	
			wOLARes[ ch ][ rg ][ rtp ]	= EvaluateBase( sFolders, wOrg, ch, rg, PtLeft, PtRight, XaxisLeft,  OFF ) 
			// Add value to Acquisition display wave for visual check
			if ( waveExists( wORsX )  &&  waveExists( wORsY ) )					// should exist but user may have killed the wave
				wORsX[ 0 ]	= Region( sFolders, ch, rg, ph, kOABE_BEG )	 	// or Eval( sFolders, ch, rg, kE_BASE, kTB... ) 
				wORsX[ 1 ]	= Region( sFolders, ch, rg, ph, kOABE_END ) 
				wORsY[ 0 ]	= wOLARes[ ch ][ rg ][ rtp ]						// or Eval( sFolders, ch, rg, kE_BASE, kY ) 
				wORsY[ 1 ]	= wOLARes[ ch ][ rg ][ rtp ]	
			endif
			NewElementOlaDisp( sOLANmBP, index ) 							//  Returns TRUE if a new wave has just been constructed.
			SetElementOlaDisp( sOlaNmBP, index, wOLARes[ ch] [ rg ][ rtp ] )			// The  RESULT value is  always  added to the display wave. 
			printf "\t\t\tOLA1Point(d) OFrC:%3d\t%s\tpr: %d   bl: %d  fr: %d\tn:%2d/%2d\t'%s'  '%s'\t'%s'\t[%s]\tch:%2d\trg:%2d\tph:%2d\trtp:%2d/%2d\tlft:\t%8.4lf\twORsX:%8.4lf\tValue:%g \r", index, sType, pr, bl, fr, n, nItems, sFolders, sSrc, sType, sOlaNmBP, ch, rg, ph, rtp, nTypes,  Region( sFolders, ch, rg, ph, kOABE_BEG ) ,  wORsX[0], wOLARes[ ch ][ rg ][ rtp ]


			// Prepare for adding  value  to  Acquisition display.
			//sType 	= "Peak"											// !!! Assumption naming  e.g.  'Peak_01'  ->  'Peak'
			//rtp		= WhichListItemIgnoreWhiteSpace( sType, klstEVL_RESULTS )	// = kE_PEAK
			rtp		= kE_PEAK
			sType	= EvalNm( rtp )									// 'Peak'
			sOlaNmBP	= OlaNm1( sType, ch, rg )
			// 060316 Base and peak are here auto-constructed so we might avoid constructing them elsewhere
			Construct1EvalPntInAcqWnd( sFolders, ch, rg, rtp )				// Construct  'wAcqPt'  .
			sXNm	= AcqPtNmX( ch, rg, rtp )							// e.g. 'Dac0PeakX1
			sYNm	= AcqPtNmY( ch, rg, rtp )							// e.g. 'Adc1BaseY0'
			sFoXNm	= FoAcqPtNmX( sFolders, ch, rg, rtp )					// e.g. 'root:uf:acq:pul:ors:orsDac0PeakX1'
			sFoYNm	= FoAcqPtNmY( sFolders, ch, rg, rtp )					// e.g. 'root:uf:acq:pul:ors:orsAdc1BaseY0'
			wave  /Z	wORsX	= $sFoXNm
			wave  /Z	wORsY	= $sFoYNm

			PkDir	= PeakDir( sFolders, ch, rg )
			if ( PkDir != kPEAK_OFF )
				ph					= kOA_PH_PEAK
				PtLeft				= BegPt + Region( sFolders, ch, rg, ph, kOABE_BEG ) / SIFact	
				PtRight				= BegPt + Region( sFolders, ch, rg, ph, kOABE_END ) / SIFact	
				wOLARes[ ch ][ rg ][ rtp ] 	= EvaluatePeak( sFolders, wOrg, ch, rg, index , PH_PEAK, PtLeft, PtRight) 
				// Add value to Acquisition display wave for visual check
				if ( waveExists( wORsX )  &&  waveExists( wORsY ) )					// should exist but user may have killed the wave
					wORsX[ 0 ]	= ( Eval( sFolders, ch, rg, kE_PEAK, kT ) - BegPt ) * SIFact 
					wORsX[ 1 ]	= nan
					wORsY[ 0 ]	= Eval( sFolders, ch, rg, kE_PEAK, kY )  //wOLARes[ ch ][ rg ][ rtp ]	
					wORsY[ 1 ]	= nan
				endif
				NewElementOlaDisp( sOLANmBP, index ) 							//  Returns TRUE if a new wave has just been constructed.
				SetElementOlaDisp( sOlaNmBP, index, wOLARes[ ch] [ rg ][ rtp ] )			// The  RESULT value is  always  added to the display wave. 
				printf "\t\t\tOLA1Point(e) OFrC:%3d\t%s\tpr: %d   bl: %d  fr: %d\tn:%2d/%2d\t'%s'  '%s'\t'%s'\t[%s]\tch:%2d\trg:%2d\tph:%2d\trtp:%2d/%2d\tlft:\t%8.4lf\twORsX:%8.4lf\tValue:%g \r", index, sType, pr, bl, fr, n, nItems, sFolders, sSrc, sType, sOlaNmBP, ch, rg, ph, rtp, nTypes,  Region( sFolders, ch, rg, ph, kOABE_BEG ) ,  wORsX[0], wOLARes[ ch ][ rg ][ rtp ]
			endif
		endif

		// Process  all other  'Basics'  results  ( all except  'Base'  and  'Peak' which have already been processed )
		sType 	= sOlaNm[ 0, len-4 ]									// !!! Assumption naming  e.g.  'Peak_01'  ->  'Peak'
		rtp	= WhichListItemIgnoreWhiteSpace( sType, klstEVL_RESULTS )
		if ( rtp != kE_BASE  &&   rtp != kE_PEAK  &&  rtp != kNOTFOUND )
	
			// Prepare for adding  value  to  Acquisition display.
			sXNm	= AcqPtNmX( ch, rg, rtp )							// e.g. 'Dac0PeakX1
			sYNm	= AcqPtNmY( ch, rg, rtp )							// e.g. 'Adc1BaseY0'
			sFoXNm	= FoAcqPtNmX( sFolders, ch, rg, rtp )					// e.g. 'root:uf:acq:pul:ors:orsDac0PeakX1'
			sFoYNm	= FoAcqPtNmY( sFolders, ch, rg, rtp )					// e.g. 'root:uf:acq:pul:ors:orsAdc1BaseY0'
			wave  /Z	wORsX	= $sFoXNm
			wave  /Z	wORsY	= $sFoYNm


			variable	PeakTime	= EvT( sFolders, ch, rg, kE_PEAK )
			variable	PeakValue = EvY( sFolders, ch, rg, kE_PEAK )
			variable	Val20	=  EvY( sFolders, ch, rg, kE_BAS2 ) * 4 / 5  +  PeakValue * 1 / 5
			variable	Val50	=  EvY( sFolders, ch, rg, kE_BAS2 ) * 1 / 2  +  PeakValue * 1 / 2
			variable	Val80	=  EvY( sFolders, ch, rg, kE_BAS2 ) * 1 / 5  +  PeakValue * 4 / 5

			if ( rtp == kE_RISE20 )
				wOLARes[ ch ][ rg ][ rtp ] 	= EvaluateCrossing( sFolders, wOrg, ch, rg, index, PkDir, "Rise",  PtLeft, PeakTime, 20, Val20, rtp ) 
			endif
			if ( rtp == kE_RISE50 )
				wOLARes[ ch ][ rg ][ rtp ] 	= EvaluateCrossing( sFolders, wOrg, ch, rg, index, PkDir, "Rise",  PtLeft, PeakTime, 50, Val50, rtp ) 
			endif
			if ( rtp == kE_RISE80 )
				wOLARes[ ch ][ rg ][ rtp ] 	= EvaluateCrossing( sFolders, wOrg, ch, rg, index, PkDir, "Rise",  PtLeft, PeakTime, 80, Val80, rtp ) 
			endif
			if ( rtp == kE_RISSLP )
				wOLARes[ ch ][ rg ][ rtp ] 	= EvaluateSlope(     sFolders, wOrg, ch, rg, index, PH_PEAK, PkDir, "Rise",  PtLeft, PeakTime, rtp ) 
			endif

			//  Evaluation to find the decay end location ( smoothed decay-baseline crossing next to peak location, may not exist ) [ SIMILAR  EVAL...] 
			if ( rtp == kE_DEC50  ||  rtp == kE_DECSLP )
				variable locEndDecay 
				variable start = EvT( sFolders, ch, rg, kE_PEAK )
				variable level = EvY(sFolders, ch, rg, kE_BASE ) //??????????? kE_BAS2 )  [ SIMILAR  EVAL...] 
				FindLevel	/Q /R=( start, Inf)  wOrg, level	// try to find time when decay crosses baseline ( may not exist )
				if ( V_flag )
					string  sMsg
					sprintf sMsg, "Decay did not find BaseLevel Crossing (%.1lf) after %.1lfms  (smoothing till end...) ", level, start
					Alert( kERR_LESS_IMPORTANT,  sMsg )
					locEndDecay = rightX( wOrg )					// inf is wrong!
				else
					locEndDecay  = V_LevelX
				endif
	
				if ( rtp == kE_DEC50 )
					wOLARes[ ch ][ rg ][ rtp ] 	= EvaluateCrossing( sFolders, wOrg, ch, rg, index, PkDir, "Decay",  PeakTime, locEndDecay, 50, Val50, rtp ) 
				endif
				if ( rtp == kE_DECSLP )
					wOLARes[ ch ][ rg ][ rtp ] 	= EvaluateSlope(     sFolders, wOrg, ch, rg, index, PH_PEAK, PkDir, "Decay",  PeakTime, locEndDecay, rtp ) 
				endif
			endif
			NewElementOlaDisp( sOLANm, index ) 							//  Returns TRUE if a new wave has just been constructed.
			SetElementOlaDisp( sOlaNm, index, wOLARes[ ch] [ rg ][ rtp ] )			// The  RESULT value is  always  added to the display wave. 
			 printf "\t\t\tOLA1Point(f)  OFrC:%3d\t%s\tpr: %d   bl: %d  fr: %d\tn:%2d/%2d\t'%s'  '%s'\t'%s'\t[%s]\tch:%2d\trg:%2d\tph:%2d\trtp:%2d/%2d\tlft:\t%8.4lf\twORsX:%8.4lf\tValue:%g \r", index, sType, pr, bl, fr, n, nItems, sFolders, sSrc, sType, sOlaNm, ch, rg, ph, rtp, nTypes,  Region( sFolders, ch, rg, ph, kOABE_BEG ) ,  1.2345, wOLARes[ ch ][ rg ][ rtp ]
		endif

		if (  rtp == kNOTFOUND )
			//  Do all the fitting 
			 printf "\t\t\tOLA1Point(g)  OFrC:%3d\t%s\tpr: %d   bl: %d  fr: %d\tn:%2d/%2d\t'%s'  '%s'\t'%s'\t[%s]\tch:%2d\trg:%2d\tph:%2d\trtp:%2d/%2d\tlft:\t%8.4lf\twORsX:%8.4lf\tValue:%g \r", index, sType, pr, bl, fr, n, nItems, sFolders, sSrc, sType, sOlaNm, ch, rg, ph, rtp, nTypes,  Region( sFolders, ch, rg, ph, kOABE_BEG ) ,  1.2345, wOLARes[ ch ][ rg ][ rtp ]
			variable	bSuccessfulFits	=  AllFitting( sFolders, wOrg, ch, rg, BegPt, SIFact )

			//  Process all latencies 
			//  Process all computations 

		endif


	//		if ( nType == rgBASE )
	//			wResult[ nType ][ 0 ]	= BaseVal( wIO, sSrc, nType,  BegPt, nSmpInt / kXSCALE, Gain )
	//		elseif ( nType == rgPEAK )
	//			wResult[ nType ][ 0 ]	= PeakVal( wIO, sSrc, nType, BegPt, nSmpInt / kXSCALE, Gain, wResult[ rgBASE ][ 0 ] ) - wResult[ rgBASE ][ 0 ] 
	//		elseif ( nType == rgBAS2 )
	//			wResult[ nType ][ 0 ]	= BaseVal( wIO, sSrc, nType,  BegPt, nSmpInt / kXSCALE, Gain )
	//		elseif ( nType == rgPEA2 )
	//			wResult[ nType ][ 0 ]	= PeakVal( wIO, sSrc, nType, BegPt, nSmpInt / kXSCALE, Gain, wResult[ rgBAS2 ][ 0 ] ) - wResult[ rgBAS2 ][ 0 ] 
	//		elseif ( nType == rgPQUOT )
	//			wResult[ nType ][ 0 ]	= PQuotVal( sSrc, nType, wResult[ rgPEAK ][ 0 ] , wResult[ rgPEA2 ][ 0 ] )
	//		elseif ( nType == rgRTIM )													// compute  rgRTIM  after rgBASE and rgPEAK, whose values are needed		
	//			wResult[ nType ][ 0 ]	= RTimVal( wIO, sSrc, nType,  BegPt, nSmpInt /  kXSCALE, Gain, 20, 80, wResult[ rgBASE ][ 0 ],  wResult[ rgBASE ][ 0 ] + wResult[ rgPEAK ][ 0 ] )
	//		elseif ( nType == rgRISE )
	//			nFitFunc			= RiseOrDecayFit( wResult, sSrc, nType,  BegPt, nSmpInt / kXSCALE, Gain, lstACTUALRISEFIT )		// Sets wResult to be retrieved below in AddToFileValOrPars(). There is only 1 wResult no matter how many traces.
	//		elseif ( nType == rgDECAY )
	//			nFitFunc			= RiseOrDecayFit( wResult, sSrc, nType,  BegPt, nSmpInt / kXSCALE, Gain, lstACTUALDECAYFIT )	// Sets wResult to be retrieved below in AddToFileValOrPars(). There is only 1 wResult no matter how many traces.

//		variable	nFitFunc	= 0

	endfor


//	// Step 8 : Write the result line  (Event, Block, .....Base, Peak, ...)
//	 printf "\t\tOLA1Point( p:%d  b:%d  f:%d )\t'%s' \r", pr, bl, fr, sLine	
//	if ( bWriteMode )
//		printf "\t\tOLA1Point( p:%d  b:%d  f:%d )\t'%s' \r", pr, bl, fr, sLine	
//		if ( gOLAHnd ) 
//			fprintf gOLAHnd, "%s\r", sLine	
//		endif	
//	endif	

End


static Function		IsNewChannelRegion( ch, rg )
	variable	ch, rg
	nvar	/Z	PrevCh	= root:uf:acq:pul:PrevCh
	nvar	/Z	PrevRg	= root:uf:acq:pul:PrevRg
	if ( ! nvar_exists( PrevCh ) )					
		variable	/G root:uf:acq:pul:PrevCh	= ch	// It  is  the first channel/region... 
		variable	/G root:uf:acq:pul:PrevRg	= rg	//..so we must compute Base and Peak
		return	TRUE
	else									
		if ( ch == PrevCh  &&  rg == PrevRg )		// Is  NOT the first channel/region..
			return	FALSE				// ..and is same as previous so we will not compute Base and Peak again 
		else
			PrevCh	= ch 					// ..but  channel/region. has changed  so we must compute Base and Peak again 
			PrevRg	= rg 
			return	TRUE
		endif
	endif
End

static Function		SetMustCompute( wOLARes, ch, rg ) 
	wave	wOlaRes
	variable	ch, rg
	variable	 rtp 	= kE_BASE
	wOLARes[ ch] [ rg ][ rtp ]	= Nan
End

static Function		MustCompute( wOLARes, ch, rg )
	wave	wOlaRes
	variable	ch, rg
	variable	 rtp 	= kE_BASE
	variable	code	= ( numType( wOLARes[ ch] [ rg ][ rtp ] ) == kNUMTYPE_NAN ) 
	return 	code
End




static Function		NewElementOlaDisp( sOLANm, index )
//  Add  a new element to  any entry type  ( e.g 'Event' ,  'Time' , 'Blck' , 'Adc0Base', ...of display wave .
// Returns  TRUE  if a new wave has just been constructed,  FALSE if a point has been added to an existing wave
	string  	sOLANm
	variable	index
	variable	value	= Nan
	wave  /Z	wOlaDisp	= 	$FolderOlaDispNm( sOLANm ) 			// Check if the fixed result  OLA waves (=Event...Tim_) have already been defined. Checking  just 'Evnt' is sufficient, ...
	if ( ! waveExists( wOlaDisp ) )								// ...if this wave has not been defined  the others 'Blck' .. 'Tim_'  have neither been defined : build them all
		make /O /N= (index)	$FolderOlaDispNm( sOLANm )  = value	// Nan hides points not yet computed  (not effective here as there are no points)
		// printf "\t\t\tNewElementOlaDisp()\tindex:\t%3d\tBUILD OLA wave\t%s\t= %8.2lf   \r", index, pd(sOLANm,12), value 
		return	TRUE
	else
		Redimension  /N=( index ) wOlaDisp
		wOlaDisp[ index - 1 ]	= value
		// printf "\t\t\tNewElementOlaDisp()\tindex:\t%3d\tRedim OLA wave\t%s\t= %8.2lf     \t  \r", index, pd(sOLANm,12), value
		return	FALSE
	endif
End

static Function		SetElementOlaDisp( sOLANm, index, value )
//  Set any entry type  ( e.g 'Event' ,  'Time' , 'Blck' , 'Adc0Base', ...of display wave  to 'value' . Starting at 0 allows to use this wave as XAxis
	string  	sOLANm
	variable	index, value
	wave	wOlaDisp	= $FolderOlaDispNm( sOLANm ) 	
	wOlaDisp[ index ] = value							
 	// printf "\t\t\tSetElementOlaDisp() \tindex:\t%3d\t\t\t\t\t%s\t= %8.2lf   \r", index, pd( sOLANm,12), value
End


// 060321
//Static  Function	/S	CrossXNm( sSrc, rg, ph )
//	string		sSrc
//	variable	rg, ph
//	return	ksOR + "orX" + num2str( rg ) + sSrc	+ StringFromList( ph, lstOA_PHASES )			// ksOR  ensures that the region will not be regularly erased
//End
//
//Static  Function	/S	CrossYNm( sSrc, rg, ph )
//	string		sSrc
//	variable	rg, ph
//	return	ksOR + "Y" + num2str( rg ) + sSrc	+ StringFromList( ph, lstOA_PHASES )			// ksOR  ensures that the region will not be regularly erased
//End
//
//Static  Function	/S	FolderCrossNm( sCrossNm )
//	string  	sCrossNm
//	return   	csFOLDER_OLA_CROSS + sCrossNm
//End

Static  Function	/S	FolderOlaDispNm( sOLANm )
	string  	sOLANm
	return   	csFOLDER_OLA_DISP + sOLANm
End

//Static  Function	/S	FittedNm( sSrc, rg, ph )
//	string		sSrc
//	variable	rg, ph
//	return	"Fit" + num2str( rg ) + sSrc	+ StringFromList( ph, lstOA_PHASES )	
//End

//Static  Function	/S	FolderFittedNm( sFittedNm )
//	string  	sFittedNm
//	return   	csFOLDER_OLA_FITTED + sFittedNm
//End


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  ANALYSIS  FILE  FUNCTIONS

Function		FinishAnalysisFile()
// Open Online analysis file,  write all accumulated data and close file
	// if no cUSER region is defined we skip the whole analysis file writing (this must be refined if there are analysis types requiring no cUSER region)
	if ( ! AnalysisIsOn() )							
		return 0
	endif
	nvar		gOLAHnd		= root:uf:acq:ola:gOLAHnd
	if ( gOLAHnd != kNOT_OPEN )	
		Close	gOLAHnd
	endif
	gOLAHnd= kNOT_OPEN	
	return	0
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
//   ANALYSIS :  REGION  DEFINITION  CALLED  FROM  ACQUISITION  WINDOW  HOOK  

// 060123
//Function		AutoWndAnalysis_StoreRegCsr( wIO, sInfo, cursX, cursY, modifier )
//	wave  /T	wIO


// 060321
//Function		AutoWndAnalysis_StoreRegCsr( sInfo, cursX, cursY, modifier )
//// Another way to set cursors : Extracts region coordinates  from mouse position,  does NOT use  IGORs  Marquee values (which is the other possibility)
//	string 	sInfo
//	variable	cursX, cursY, modifier
//	variable	MouseX, MouseY, ph//, nTrc
//	string   	sSrc
////051203	
////	nvar		gWaveY	= root:uf:disp:svWaveY,   		gWaveMin= root:uf:disp:svWaveMin, 			gWaveMax  = root:uf:disp:svWaveMax
////	nvar		gPx		= root:uf:disp:svPointX, 		gPy 		= root:uf:disp:svPointY
//	nvar		gWaveY	= root:uf:acq:pul:svWaveY0000,	gWaveMin= root:uf:acq:pul:svWaveMin0000, 	gWaveMax  = root:uf:acq:pul:svWaveMax0000
//	nvar		gPx		= root:uf:acq:pul:svPointX0000, 	gPy 		= root:uf:acq:pul:svPointY0000
//
//	nvar		gR1x 	= root:uf:disp:gR1x,  		gR2x 	= root:uf:disp:gR2x,  		gR1y = root:uf:disp:gR1y,  gR2y = root:uf:disp:gR2y
//	svar		gsWndSel  = root:uf:disp:gsWndSel
//	string 	sWnd	= StringByKey(     "WINDOW", sInfo ) 
//
//printf "\tAutoWndAnalysis_StoreRegCsr() %s  \r", sWnd
//
//	//  Store globally the last recently clicked point
//	variable isMouseDown = StrSearch( sInfo, "EVENT:mousedown;", 	0 ) != kNOTFOUND
//	variable isMouseUp	  = StrSearch( sInfo, "EVENT:mouseup;", 	0 ) != kNOTFOUND
//
//	if ( isMouseDown  &&  It_Is( modifier, STOREPOINT ) )
//		printf "\tstoring mouse position in  analysis.[%d ] \r", modifier
//		gPx		= CursX
//		gPy		= CursY
//		gsWndSel= sWnd		// store POINT-clicked window name for use in EraseOneRegion
//	endif
//
//	if ( isMouseDown  &&   ( It_Is( modifier, STOREBASE )  ||  It_is( modifier, STOREPEAK ) ) )
//		// Obsolete...?
//		// Get  MARQUEE REGION values as they must permanently be displayed in the statusbar
//		// The position  values in the statusbar are updated when the mouse drag is finished.  
//		//  If a truely continuous position value updating is required (but only while dragging!) here (in CursorMovedHook)..
//		// ..the status bar would have to be redrawn (or Update or...or...)
//	  	gR1x	= CursX
//	  	gR1y	= CursY
//	endif
//
//	if ( isMouseUp  &&   ( It_Is( modifier, STOREBASE )  ||  It_is( modifier, STOREPEAK ) ) )
//	  	gR2x	= CursX
//	  	gR2y	= CursY
//		ph	= RegionTypeFromModifier( modifier )
//		sSrc	= GetTraceNameFromWnd( sWnd )
//	 	printf "\tAutoWndAnalysis_StoreRegCsr() %s   p:%d   '%s' \r", sWnd, ph, sSrc
//	
//		// Displays the changes in all  windows
//		//DispClearOneTrcOneTyp( CLEAR, sSrc, nType, cUSER )	// 040724
//
//// 051213
////		SetRegLoc( wIO, sSrc, nType,  cUSER, min( gR1x, gR2x ), max( gR1y, gR2y ), max( gR1x, gR2x ), min( gR1y, gR2y ) )				
//		variable	ch	= WhichListItem( sSrc, LstChAcq(), ksSEP_TAB )			// TODO : simplify this
//		variable	rg = 0//todo
//		SetRegLoc3( ch, rg, ph, min( gR1x, gR2x ), max( gR1x, gR2x ) )				
//
//		//DispClearOneTrcOneTyp( DRAW, sSrc, nType, cUSER )
//
//// 051213
////		DispClearOneTrcOneTyp( sSrc, nType, cUSER )		// 040727
//
//		// Get (and store globally)  the  Y  value of the wave at the cursor's  X  location
//		//?todo : do not get  the first  wave, but (if there is more than one) get the one the cursor is on ... 
//		wave		wv 			= WaveRefIndexed( "", 0, 1 )			// Returns first Y wave in the top graph.
//
////		variable /G 	gWaveY		= wv[ round( x2pnt( wv, CursX ) ) ]
////		// Get (and store globally) the minimum and the maximum  Y  value of the wave in the region given by marquee left...right
////		variable /G	gWaveMax	= WaveMax( wv,   gR1x, gR2x )
////		variable /G	gWaveMin	= WaveMin( wv,   gR1x, gR2x )
//		gWaveY		= wv[ round( x2pnt( wv, CursX ) ) ]				//0409
//		// Get (and store globally) the minimum and the maximum  Y  value of the wave in the region given by marquee left...right
//		gWaveMax	= WaveMaximum( wv,  gR1x, gR2x )
//		gWaveMin	= WaveMinimum( wv,   gR1x, gR2x )
//	endif
//
//	// printf  "\tCursorMovedHook() waveexists  %s   : %d   crsX:%.1lf   waveindex :%.1lf \r", sWaveNm, waveexists ($sWaveNm),  CursX,  nWaveIndex
//	// printf  "\tCursorMovedHook() sWnd:%s  moX:%3d \tmoY:%3d \tcX:%5.1lf\tcY:%5.1lf \treX:%.1lf ..%.1lf \twMin:%.1lf \twMax:%.1lf \twvY:%.1lf \r",sWnd, mouseX, mouseY, CursX, CursY, gR1x, gR2x, gWaveMin, gWaveMax, gWaveY 
//End
//
//Static Function	RegionTypeFromModifier( modifier )
//// return region index (=region type) for a given combination of pressed keys, but ignore mouse buttons  (see also 'It_is( Modifier, goal )' )
//	variable	modifier				
//	modifier = modifier &  (kSHIFT + kALT + kCTRL)	// mask out mouse button (=1)
//	return	modifier == STOREBASE ? rgBASE : rgPEAK
//	// return	modifier == STORERTIM ? rgRTIM : (modifier == STOREBASE ? rgBASE : rgPEAK )	// !( )
//End
//
//static Function	WaveMinimum( w, left, right )		
//// Returns min value of the specified wave in the specified range.
//// The min ValDisplay control is tied to this function.
//	Wave	w
//	variable	left, right
//	WaveStats /Q /R=( left, right ) w
//	return V_min
//End
//	
//static Function	WaveMaximum(w, left, right)	
//// Returns max value of the specified wave in the specified range.
//// The wMax ValDisplay control is tied to this function
//	Wave	w
//	variable	left, right
//	WaveStats /Q /R= ( left, right ) w
//	return V_max
//End
//


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//   ANALYSIS :  MARQUEE   REGION   CONTEXT  MENU  FUNCTIONS

// The following marquee context menu functions pop up automatically when the user finishes the marquee dragging.
// These functions allow the user to specify what is to be done with the selected region.
// Different approach: Let the user specify the purpose of the region before the region is selected by a group of radio...
// ..buttons in an extra 'Marquee mode' panel . This is more  efficient if multiple regions of the same 'mode' are to  be selected.
 

// 040802 PROBLEM: these functions are executed also from ReadCfs/Eval  but in that context the following functions will fail ...
//... (e.g. GetWindowTNL tries to extract mode and range from the trace name) 

//Function		Base() : GraphMarquee
//	DefineRegionPhs( rgBASE )
//End
//
//Function		Peak() : GraphMarquee
//	DefineRegionPhs( rgPEAK )
//End
//
//Function		Base2() : GraphMarquee
//	DefineRegionPhs( rgBAS2 )
//End
//
//Function		Peak2() : GraphMarquee
//	DefineRegionPhs( rgPEA2 )
//End
//
//Function		PQuot() : GraphMarquee
//	DefineRegionPhs( rgPQUOT )
//End
//
//Function		RTim() : GraphMarquee
//	DefineRegionPhs( rgRTIM )
//End
//
//Function		Rise() : GraphMarquee
//	DefineRegionPhs( rgRISE )
//End
//
//Function		Decay() : GraphMarquee
//	DefineRegionPhs( rgDECAY )
//End


// 060317c weg
// 051212
//Function		Base0() : GraphMarquee
//	DefineRegionPhase( 0, kOA_PH_BASE, kE_BASE )//, kE_BASE )
//End
//Function		Peak0() : GraphMarquee
//	DefineRegionPhase( 0, kOA_PH_PEAK, kE_PEAK )
//End
//Function		Lat00() : GraphMarquee
//	DefineRegionPhase( 0, kOA_PH_LATC0, -1 )
//End
//Function		Lat01() : GraphMarquee
//	DefineRegionPhase( 0, kOA_PH_LATC1, -1 )
//End
//Function		Fit00() : GraphMarquee
//	DefineRegionPhase( 0, kOA_PH_FIT0, -1 )
//End
//Function		Fit01() : GraphMarquee
//	DefineRegionPhase( 0, kOA_PH_FIT1, -1 )
//End
//Function		Base1() : GraphMarquee
//	DefineRegionPhase( 1, kOA_PH_BASE, kE_BASE )
//End
//Function		Peak1() : GraphMarquee
//	DefineRegionPhase( 1, kOA_PH_PEAK, kE_PEAK )
//End
//Function		Lat10() : GraphMarquee
//	DefineRegionPhase( 1, kOA_PH_LATC0, -1)
//End
//Function		Lat11() : GraphMarquee
//	DefineRegionPhase( 1, kOA_PH_LATC1, -1 )
//End
//Function		Fit10() : GraphMarquee
//	DefineRegionPhase( 1, kOA_PH_FIT0, -1 )
//End
//Function		Fit11() : GraphMarquee
//	DefineRegionPhase( 1, kOA_PH_FIT1, -1 )
//End
//
//
//
//Function		DefineRegionPhase( rg, ph, rtp )
//	variable	rg, ph							// = kOA_PH_PEAK, kOA_PH_LATC0, kOA_PH_FIT1.
//	variable	rtp								// = kE_PEAK, kE_BASE
//	string  	sFolders	= ksF_ACQ_PUL
//
//	GetMarquee left, bottom
//	if ( V_Flag )												// if a marquee is active...
//	
//		string 	sWnd	= WinName( 0, 1 )						// get the name of the active graph (where the user defined the marquee)
//	
//		string  	sTNm	= GetTraceNameFromWndLong( sWnd )		// 040724 return full name including source, range, mode, instance
//		variable 	nRange	= GetRangeNrFromTrc( sTNm )				// 040724
//		string  	sSrc		= StringFromList( 0, sTNm, " " ) 				// !!! Extract source. Depends on space as separator as defined in BuildMoRaNameInstance()
//		variable	ch		= WhichListItem( sSrc, LstChAcq(), ksSEP_TAB )			// TODO : simplify this
//	
//		printf "\t\tDefineRegionPhase( rg:%2d  ph:%2d )  ActWnd: '%s'   ->  ch:%2d  '%s'   nRange: %d   '%s'  L:%g \tR:%g \r",  rg, ph, sWnd, ch, sTNm, nRange, sSrc, V_left, V_right
//
//		if ( nRange == kRESULT )										// 040724 Only Results (=the last PoN sweep) must be shifted as they are displayed not with their true time ...
//			nvar		gResultXShift		= root:uf:disp:gResultXShift			// ...but with a time offset so that they start at time Zero (Frame and Primary are displayed with true time which is time offset Zero
//			SetRegLoc3( ch, rg, ph, V_left + gResultXShift, V_right + gResultXShift )	// store the marquee coordinates
//		else
//			SetRegLoc3( ch, rg, ph, V_left, V_right )							// store the marquee coordinates
//		endif
//	
////		DispClearOneTrcOneTyp( sSrc, nType, nStage )							// draw it
//	
//		GetMarquee	/K												// ..kill the marquee to make the frame disappear automatically
//	
////		string  	sFolder		= ksACQ
////		string  	sPnOptions	= ":dlg:tPnOLADisp" 
////		InitPanelOLADisp( sFolder, sPnOptions )								// necessary to display the changed panel state immediately
////		UpdatePanel(  "PnOLADisp", "Online Analysis" , sFolder, sPnOptions )			// 040220 redraw the 'OLA Disp' Panel as the added new region makes more 'Results' possible (same params as in  ConstructOrDisplayPanel())
//	endif
//
//// 060317b weg
//// 051223
////		Construct1AcqEvalRegion( sFolders, ch, rg, ph, rtp )							// Display the region range as a colored bar below the x axis. 
//
//// 060317a weg
////		string  	sWin	= ksRES_SEL_OA
////		if ( WinType( sWin ) == kPANEL )									// After a region has been defined auto-select the appropriate results but  ONLY IF  the panel does already exist
////			variable	w		= 1	
////			if ( rtp ==  kE_BASE  ||  rtp ==  kE_PEAK )
////				AutoSelectOLAResults( w, ch, rg, rtp )
////			endif
////			// ToThink:  How handle fit regions, how handle latency regions ?
////		endif	
//End
//

// 060321
//	static Function		SetRegLoc3( ch, rg, ph, left, right )
//		variable	ch, rg, ph, left, right			
//	// 051212
//		wave	wOAReg	= $"root:uf:" + ksF_ACQ_PUL + ":wCRegion"
//		wOAReg[ ch ][ rg ][ ph ][ kOABE_BEG ] = left
//		wOAReg[ ch ][ rg ][ ph ][ kOABE_END ] = right
//		printf "\t\tSetRegLoc3( \tch:%2d\trg:%2d\tph:%2d\tlft:%g  right:%g   \r", ch, rg, ph, left, right
//	End





//Function		DefineRegionPhs( nType )
//	variable	nType							// rgBASE, rgPEAK, rgRTIM...
//	string  	sFolder	= ksACQ
//	wave  /T	wIO		= $"root:uf:" + sFolder + ":ar:wIO"  				// This  'wIO'  is valid in FPulse ( Acquisition )
//	variable	nStage	= cUSER
//
//	GetMarquee left, bottom
//	if ( V_Flag )											// if a marquee is active...
//	
//		string 	sWnd	= WinName( 0, 1 )					// get the name of the active graph (where the user defined the marquee)
//	
//		string  	sTNm	= GetTraceNameFromWndLong( sWnd )	// 040724 return full name including source, range, mode, instance
//		variable 	nRange	= GetRangeNrFromTrc( sTNm )			// 040724
//		string  	sSrc		= StringFromList( 0, sTNm, " " ) 			// !!! Extract source. Depends on space as separator as defined in BuildMoRaNameInstance()
//	
//		printf "\t\tDefineRegion()  '%s'   nRange: %d   '%s'  L:%g \tR:%g \r",  sTNm, nRange, sSrc, V_left, V_right
//
//		if ( nRange == kRESULT )										// 040724 Only Results (=the last PoN sweep) must be shifted as they are displayed not with their true time ...
//			nvar		gResultXShift		= root:uf:disp:gResultXShift			// ...but with a time offset so that they start at time Zero (Frame and Primary are displayed with true time which is time offset Zero
//			SetRegLoc( wIO, sSrc, nType, nStage, V_left + gResultXShift, V_top, V_right + gResultXShift, V_bottom)	// store the marquee coordinates
//		else
//			SetRegLoc( wIO, sSrc, nType, nStage, V_left, V_top, V_right, V_bottom)	// store the marquee coordinates
//		endif
//	
//		DispClearOneTrcOneTyp( sSrc, nType, nStage )							// draw it
//	
//		GetMarquee	/K												// ..kill the marquee to make the frame disappear automatically
//	
////		string  	sPnOptions	= ":dlg:tPnOLADisp" 
////		InitPanelOLADisp( sFolder, sPnOptions )								// necessary to display the changed panel state immediately
////		UpdatePanel(  "PnOLADisp", "Online Analysis" , sFolder, sPnOptions )			// 040220 redraw the 'OLA Disp' Panel as the added new region makes more 'Results' possible (same params as in  ConstructOrDisplayPanel())
//	endif
//
//End


// 060321
//Function 		Cancel() : GraphMarquee
//	GetMarquee	/K						// kill the marquee to make the frame disappear automatically
//End


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//    ANALYSIS :  LITTLE  REGION  HELPERS		IMPLEMENTATION  AS  LIST   040224

// 060321
//strconstant		sMAXREG_ITEMSEPS	= ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;"		// at least  'MAXREG_ITEMS' separators, will be truncated to needed number
//static constant		RTRC = 0,  RLFT = 1, RRIG = 2, RTOP = 3, RBOT = 4, RSHP = 5, RRED = 6, RGRN = 7, RBLU = 8, RMODE = 9,  MAXREG_ITEMS = 10
//static strconstant	lstREG_ITEMS	= "Trace;Left;Right;Top;Bot;Shape;Red;Green;Blue;Mode;"


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//    ANALYSIS :  BIG  REGION  HELPERS

// 060321
//// 040724   fragment  (to be extended to many traces...)
//static Function		GetRangeNrFromTrc( sTNm )
//// Extracts  e.g. 'Adc0 RM5'  ->  'R'  ->  3
//	string 	sTNm
//	variable	nPosOfRg		= strlen( sTNm ) - 4				// !!! ASSUMPTION   the range letter is the 4. to last letter ( S,F,P,R)	
//	string  	sRangeLetter	= sTNm[ nPosOfRg, nPosOfRg ] 	// !!! ASSUMPTION   last letter is SINGLE instance digit (count max to 9)
//	// printf "\t\t\tGetRangeNrFromTrc(1).%s  -> '%s'  -> %d\r",  sTNm,  sRangeLetter, RangeNr( sRangeLetter )
//	return 	RangeNr( sRangeLetter )
//End


// 060321
//// could be incorporated in GetTraceNameFromWndLong()  , see below
//static  Function  /S	GetTraceNameFromWnd( sWNm )
//// Return the name of the (used) trace contained in window sWNm. If  there are multiple traces in sWNm (because the user already copied some)..
//// ..a modal dialog box pops up requiring the user to specify the trace
//	string 	sWNm
//	string 	sThisWindowsTNL, sTNm = ""
//	variable	t, tCnt
//	// Extract traces from TWA. 	Different approach (not used): extract traces from Igors TraceNameList().  Disadvantage: There are multiple traces from which we have to extract the base name, and keep it only once
//	sThisWindowsTNL = GetWindowTNL( sWNm, 0 )
//
//	tCnt	= ItemsInList( sThisWindowsTNL )
//	// printf "\tGetTraceNameFromWnd (%s)  tCnt:%d   ThisWindowsTNL:%s \r", sWNm, tCnt, sThisWindowsTNL
//	if ( tCnt < 1 )
//		FoAlert( ksACQ, kERR_IMPORTANT,  "Analysis region definition (or some other action) requires one distinct trace. This window contains no traces. " )
//	elseif ( tCnt > 1)
//		sTNm	= TraceSelectModalDialog( sThisWindowsTNL )
//	else
//		sTNm	= StringFromList( 0, sThisWindowsTNL )
//	endif
//	// printf "\tGetTraceNameFromWnd()..%s . Returning '%s' .   ThisWindowsTNL:%s has %d traces \r", sWNm, sTNm, sThisWindowsTNL, tCnt	
//	return	sTNm
//End
//
//// 040724
//static  Function  /S	GetTraceNameFromWndLong( sWNm )
//// Return the LONG name of the (used) trace contained in window sWNm which includes  mode, range and instance. 
//// If  there are multiple traces in sWNm (because the user already copied some) a modal dialog box pops up requiring the user to specify the trace
//	string 	sWNm
//	string 	sThisWindowsTNL, sTNm = ""
//	variable	t, tCnt
//	// Extract traces from TWA. 	Different approach (not used): extract traces from Igors TraceNameList().  Disadvantage: There are multiple traces from which we have to extract the base name, and keep it only once
//	sThisWindowsTNL = GetWindowTNL( sWNm, 1 )
//
//	tCnt	= ItemsInList( sThisWindowsTNL )
//	// printf "\tGetTraceNameFromWndLong (%s)  tCnt:%d   ThisWindowsTNL:%s \r", sWNm, tCnt, sThisWindowsTNL
//	if ( tCnt < 1 )
//		FoAlert( ksACQ, kERR_IMPORTANT,  "Analysis region definition (or some other action) requires one distinct trace. This window contains no traces. " )
//	elseif ( tCnt > 1)
//		sTNm	= TraceSelectModalDialog( sThisWindowsTNL )
//	else
//		sTNm	= StringFromList( 0, sThisWindowsTNL )
//	endif
//	// printf "\tGetTraceNameFromWndLong()..%s . Returning '%s' .   ThisWindowsTNL:%s has %d traces \r", sWNm, sTNm, sThisWindowsTNL, tCnt	
//	return	sTNm
//End

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//    TRACE SELECT   PANEL

// 060321
//static Function   /S	TraceSelectModalDialog( sTNL )
//	string 	sTNL
//	string 	sTrace = ""
//	Prompt	sTrace, "Trace", popup, sTNL
//	DoPrompt	"Select a trace", sTrace	
//	if ( V_Flag )
//		return	StringFromList( 0, sTNL )		// user canceled
//	endif
//	return	sTrace
//End

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//    ANALYSIS :  REGION  DISPLAY


// 060317b weg
// 051223
//Function		Construct1AcqEvalRegion( sFolders, ch, rg, ph, rtp )
//// Display the region range as a colored bar below the x axis. Similar 'DisplayEvaluatedPoints()'
//	string  	sFolders
//	variable	ch, rg, ph		// e.g.  kOA_PH_BAS,  kOA_PH_PEAK
//	variable	rtp			// e.g.  kE_BASE,  kE_PEAK
//	wave	wRed = root:uf:misc:Red, wGreen = root:uf:misc:Green, wBlue = root:uf:misc:Blue
//	string  	sSrc	= StringFromList( ch, LstChAcq(), ksSEP_TAB )
//	variable	rLeft, rTop, rRight, rBot, rRed, rGreen, rBlue
//	
//	GetRegColor( sFolders, ph, rRed, rGreen, rBlue )
//
//	variable	nShape = str2num( StringFromList( ph, lstRGSHP_U ) ) // kRECTYBELOW// GetReg( sSrc, rg, ph, RSHP )
//
//	
//// TODO either append to all windows containing 'sSrc'   or  only to that window in which the user has defined the region
//		string  sWnd	= FindFirstWnd( ch )		// possibly find and process window list 
//
//	// Get axis end points  for those drawing  modes where rectangle or line is to be drawn over full Y range or below X axis
//	if ( nShape == kRECTYFULL )
//		GetAxis /Q  /W = $sWnd left						
//		rTop	= V_max
//		rBot	= V_min
//
//	elseif ( nShape == kLINEHORZLONG )
//		GetAxis   /Q /W = $sWnd  bottom						
//		rLeft		=  V_min
//		rRight	=  V_max
//	elseif ( nShape == kCROSSSMALL )
//		GetAxis   /Q /W = $sWnd  bottom						
//		rLeft		-=  ( V_max - V_min ) * .06
//		rRight	+= ( V_max - V_min ) * .06
//		// print AxisInfo("","left")
//		GetAxis   /Q /W = $sWnd left			// TODO:  this does NOT work under certain ? AUTOSCALE conditions				
//		// GetAxis    /W = $sWnd left		 					
//		rTop		+= ( V_max - V_min ) * .04
//		rBot		-=  ( V_max - V_min ) * .04
//	elseif ( nShape == kCROSSBIG )
//		GetAxis /Q  /W = $sWnd left						
//		rTop		+= ( V_max - V_min ) * .4
//		rBot		-=  ( V_max - V_min ) * .4
//		GetAxis /Q  /W = $sWnd  bottom						
//		rLeft		-=  ( V_max - V_min ) * .4 
//		rRight	+= ( V_max - V_min ) * .4
//
//	elseif ( nShape == kRECTYBELOW )
//		GetAxis /Q  /W = $sWnd left						
//		rTop	= V_min - ( .025 + .015 * ph ) * ( V_max -V_min )	// cover a narrow strip below X axis 
//		rBot	= V_min - ( .028 + .015 * ph ) * ( V_max -V_min )
//	endif
//
//	// printf "\t\t\t\tDisplayRegion3(2) src:'%s'  nReg:\t%s\t(%d)\tstg=%d nShp:\t%s\t(%d)\t %s \tL:\t%7.2lf\tR:\t%7.2lf\tT:\t%7.2lf\tB:\t%7.2lf \r", sSrc, pd(StringFromList( nReg, lstRGTYPE),9) , nReg, nStg, pd(StringFromList( nShape, lstRGSHAPE),12), nShape, sWnd, rLeft, rRight, rTop, rBot				// draw the rectangle marking the selected region
//
//
//
//
//
//	string 	sTNL
//	if ( nShape != kHIDDEN )
//
//		// Check whether the eval regions waves exists already, if not then construct it
//		string  	sCrossYNm= CrossYNm( sSrc, rg, ph )
//		string  	sCrossXNm= CrossXNm( sSrc, rg, ph )
//		wave  /Z	wCrossX	=	$FolderCrossNm( sCrossXNm )
//		wave  /Z	wCrossY	=	$FolderCrossNm( sCrossYNm )
//	
//		if (  ! waveExists( wCrossX )  ||   ! waveExists( wCrossY ) )
//			 printf "\t\tConstruct1AcqEvalRegion() : Marquee/cross waves\t'%s'\tand\t'%s'\t  do not exist, will be constructed  \r ",  pd(FolderCrossNm( sCrossYNm ),31),  pd(FolderCrossNm( sCrossXNm ),31)	// e.g. Base, Decay
//			variable	nCrossPoints	= 5			 							//  SLOPE would need 9 points
//			make	/O	/N=(nCrossPoints)	$FolderCrossNm( sCrossXNm ) 	= Nan 	// Build the XY wave pair which is to be displayed as a cross, rectangle or line
//			make	/O	/N=(nCrossPoints)	$FolderCrossNm( sCrossYNm ) 	= Nan	// Nan prevents drawing of unused points 
//			wave	wCrossX	=	$FolderCrossNm( sCrossXNm )
//			wave	wCrossY	=	$FolderCrossNm( sCrossYNm )
//		endif
//
//		sTNL			= TraceNameList( sWnd, ";", 1 )
//		if ( WhichListItem( sCrossYNm, sTNL ) == kNOTFOUND )							// Is the cross not yet displayed?  We must check Y component of cross, checking  X will not work
//
//			AppendToGraph /W=$sWnd	wCrossY vs wCrossX
//			ModifyGraph	 /W=$sWnd	rgb( $sCrossYNm )  =( rRed, rGreen, rBlue )			// the color from lstRGCOLOR
//
//// todo : into draw
////			if ( nRange == kRESULT )												// 040724
////				ModifyGraph	 /W=$sWnd	offset( $sCrossYNm )  = { -gResultXShift, 0 }		// 040724
////			endif
//
//			if ( nShape == kLINETHICK )	
//				ModifyGraph  /W=$sWnd	 lsize( $sCrossYNm ) 	= 2							// fat line
//			endif
//			if ( nShape == kLINEEXACT )	
//				ModifyGraph  /W=$sWnd	 mode( $sCrossYNm ) = 4							// line (default  is thin) and marker
//				ModifyGraph  /W=$sWnd	 marker( $sCrossYNm ) = 1							// marker is 'X' 
//			endif
//			if ( nShape == kRECTEXACT || nShape == kRECTYFULL || nShape == kRECTYBELOW )	
//				ModifyGraph  /W=$sWnd	 axisclip( left) = 2									// allow drawing outside (=below the bottom) axis 
//				ModifyGraph  /W=$sWnd	 lsize( $sCrossYNm ) 	= 2							// fat line
//			endif
//			// printf "\t\t\tConstruct1AcqEvalRegion() \tAppending to \t%s\t waves  \t%s\t  and  \t%s\t  \tTNL was: '%s'  \r" , pd( sWnd, 8), pd( sCrossXNm, 21), pd( sCrossYNm,21) , sTNL 
//		endif
//
//
//
//		// Fill the CROSS wave with the cross end points
//		rLeft		= Region( sFolders, ch, rg, ph, kOABE_BEG )
//		rRight	= Region( sFolders, ch, rg, ph, kOABE_END )
//		if ( nShape == kCROSSSMALL  ||  nShape == kCROSSBIG )
//			wCrossX[ 0 ]  = rLeft; 			wCrossY[ 0 ]  = ( rTop+rBot )/2;	wCrossX[ 1 ] = rRight; 		wCrossY[ 1 ] = (rTop+rBot)/2	// horizontal line
//			wCrossX[ 3 ]  = (rLeft+rRight)/2;	wCrossY[ 3 ]  =  rTop;			wCrossX[ 4 ] = (rLeft+rRight)/2; 	wCrossY[ 4 ] = rBot	 		// vertical line
//		endif
//		// Fill the  LINE  wave with the line end 
//		if ( nShape == kLINETHICK  ||  nShape == kLINEEXACT  ||  nShape == kLINEHORZLONG )
//			wCrossX[ 0 ]  = rLeft; 			wCrossY[ 0 ]  = rTop;			wCrossX[ 1 ] = rRight; 		wCrossY[ 1 ] =  rBot		
//		endif
//		if ( nShape == kRECTEXACT || nShape == kRECTYFULL || nShape == kRECTYBELOW )
//			wCrossX[ 0 ]  = rLeft; 			wCrossY[ 0 ]  = rTop;			wCrossX[ 1 ] = rRight; 		wCrossY[ 1 ] =  rTop		
//			wCrossX[ 2 ]  = rRight;		wCrossY[ 2 ]  = rBot;			wCrossX[ 3 ] = rLeft; 			wCrossY[ 3 ] =  rBot		
//			wCrossX[ 4 ]  = rLeft;			wCrossY[ 4 ]  = rTop;			
//		endif
//		// printWave( "\t\t\tDisplayRegion3() \t\tSetting value in \t" + sCrossXNm, wCrossX )	; 	PrintWave( "\t\t\tDisplayRegion() \t\tSetting value in \t" + sCrossYNm, wCrossY )
//	endif
//
//
//
//// TODO  fitted segments	
//// BUILDING  AND  DISPLAYING  FITTED SEGMENTS    by  using  waves
//	// Regions to be displayed as as Fitted segments must have been defined earlier, e.g. in RiseOrDecayFit().  As they are waves  IGOR updates (=erases and redraws) them automatically . 
//	// Calls to 'DisplayRegion()'  are  needed ....????just once to append the wave ro the graph. 
//	//...???... This call is necessary only because  ALL traces (including the CROSS) are cleared  by  'EraseTracesInGraph()'   when 'Start'  or  'Apply'  is pressed.  It would be unnecessary if  the ??????????...CROSSES were not erased there.
////	if ( nShape == kFITTED ) 
////		sTNL				= TraceNameList( sWnd, ";", 1 )
////		string  	sFittedNm		= FittedNm( sSrc, rg, ph )
////		wave  /Z	wFittedSegment	= $FolderFittedNm( sFittedNm )
////
////		if (  waveExists( wFittedSegment ) )
////
////			if ( WhichListItem( sFittedNm, sTNL ) == kNOTFOUND )							// Is the fitted segment not yet displayed?  
////				AppendToGraph /W=$sWnd	wFittedSegment
////
////				ModifyGraph	 /W=$sWnd	rgb( $sFittedNm )  =	( rRed, rGreen, rBlue )			// the color from lstRGCOLOR
////				ModifyGraph	 /W=$sWnd	mode( $sFittedNm ) = 0						// 0 : lines, 2 : dots, 4 : lines and markers (fitted line may be hidden by org trace)
////
////// todo : into draw
//////				if ( nRange == kRESULT )	// 040724
//////					ModifyGraph	 /W=$sWnd	offset( $sFittedNm )  = { -gResultXShift, 0 }	// 040724
//////				endif
////
////				// printf "\t\t\tDisplayRegion() \tAppending to \t%s\t wave    \t%s\t  \t  \tTNL was: '%s'  \r" , pd( sWnd, 8), pd( sFittedNm, 21), sTNL 
////			endif
////		else
////			printf "Construct1AcqEvalRegion() : fitted waves  '%s'    do not exist  \r ",  FolderFittedNm( sFittedNm )	// e.g. Base, Peak, Quot
////		endif
////
////	endif
//End


// 060321
//static Function		GetRegColor( sFolders, ph, rnRed, rnGreen, rnBlue )
//// Is possibly faster when taken from 4-dim array Region()
//	string  	sFolders
//	variable	ph
//	variable	&rnRed, &rnGreen, &rnBlue
//
//	rnRed	= str2num( StringFromList( 0, StringFromList( ph, lstRGCOLOR ) , "," ) )	// Region( sFolders, ch, rg, ph, kOABE_BEG )( sSrc, ch, rg, ph, RRED )
//	rnGreen	= str2num( StringFromList( 1, StringFromList( ph, lstRGCOLOR ) , "," ) )	// Region( sFolders, ch, rg, ph, kOABE_BEG )( sSrc, ch, rg, ph, RRED )
//	rnBlue	= str2num( StringFromList( 2, StringFromList( ph, lstRGCOLOR ) , "," ) )	// Region( sFolders, ch, rg, ph, kOABE_BEG )( sSrc, ch, rg, ph, RRED )
//
////	rnGreen	= GetReg( sSrc, ch, rg, ph, RGRN )
////	rnBlue	= GetReg( sSrc, ch, rg, ph, RBLU )
//End




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
////			FoAlert( sFolder, kERR_FATAL,  "The data channel '" + sCh0 + "' required by ' Aver" + ":  " + sSrc + "' is not provided in the script file. " ) 
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
////			FoAlert( sFolder, kERR_FATAL,  "The data channel '" + sCh0 + "' required by 'Sum:" + sSrc + "' is not provided in the script file." )
////			return kERROR
////		endif	
//		wave  /Z	wCh1	= $sCh1
////		if ( !waveexists( wCh1 ) )
////			FoAlert( sFolder, kERR_FATAL,  "The data channel '" + sCh1 + "' required by 'Sum:" + sSrc + "' is not provided in the script file." )
////			return kERROR
////		endif	
// 		wave	wResult	= $swResult
//		// waveform arithmetic:  target[ tbeg, tEnd ] = src[ sBeg - tBeg + p ]
//		wResult[ BegPt, BegPt+nPts ] = wCh0[  p ] + wCh1[ p ]
//	endfor
//End

//Static  Function   /S	ioList1( ioch, nData, nEntry )
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

//Static  Function   /S	ioList2( nIO, c, nData, nEntry )
//// extracts one comma separated entry from script line (given by nIO and c) and sSubKey (given by nData)  e.g. 'Src:Adc2,Dac1'
//	variable	nIO, c, nData, nEntry
//	return	ioList1( NioC2ioch( nIO, c ), nData, nEntry )
//End

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

