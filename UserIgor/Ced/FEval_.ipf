//  FEVAL_.IPF 

// 0302 Data evaluation procedures (IGOR version closely resembling Pascal STIMFIT)
//
// History: 
// todo   checkbox   ShowInfo  on/off


#pragma rtGlobals=1								// Use modern global access method.

//constant		kRSERIES_VOLTAGE	= .005		// a 5 mV pulse is used for measuring the series resistance

strconstant	ksTBLEXT_			= "fit"		// the small table file containing only selected data
strconstant	ksTOTALTBLEXT_		= "tbl"		// the large total table file containing all data
strconstant	ksAVGEXT_			= "avg"
constant		kBGCOLOR_			= 60000		// 55000 = medium grey , 60000 = light grey
static	 constant	LEFT = 8, 		TOP = 4, 		RIGHT = 2, 	BOT = 1	// Region display: these values detemine which lines will be shown 
static	 constant	LINENODOTS 	= 0, FINESTDOTS = 1, FINEDOTS = 2, MEDIUMDOTS = 3, COARSEDOTS = 7, VERYCOARSEDOTS = 8	// Region display
static constant 		kBASE_SLICES			= 4			// for baseline evaluation: divide baseline region in so many pieces and analyse and compare them separately
	 constant		kRG_MAX				= 4			// maximum number of regions per channel ( 050216 max. 1digit!)

//static	constant	cCH	= 0,	cRG	= 1, 	cPH	= 2, cCURSOR = 3, cXMOUSE = 4, cYMOUSE = 5, cMODIF = 6, cMAXCURRG = 7	// index for wCurRegion and wPrevRegion
		constant	cCH	= 0,	cRG	= 1, 	cPH	= 2, cCURSOR = 3, cXMOUSE = 4, cYMOUSE = 5, kCURSWP = 6,  kSIZE = 7,  cMAXCURRG = 8	// index for wCurRegion and wPrevRegion
 
// DIFF  BSBEG  BSEND
// Indexing for parameters extracted initially from  (extended)  WaveStats : wWSOrg  holds  statistics params from original data, wWSSmooth from  noise-reduced data
static constant		wsBEG = 0, wsEND = 1, wsXSCL = 2, wsPTS = 3, wsZIG = 4, wsDEV = 5, wsAVG = 6, wsRMS = 7, wsMIN = 8, wsMAX = 9, wsMINL = 10, wsMAXL = 11, wsMAXWS = 12 
static strconstant	sWS	= " bg; en; xs; pt; zg; dv; av; rm; mi; ma; mil; mal"

// Indexing for  wMnMx[]:
static constant		MM_XMIN = 0, MM_XMAX = 1, MM_YMIN = 2, MM_YMAX = 3, MM_XYMAX = 4


// 050812 to be eliminated.............
static strconstant	lstEVAL_PRINTALL	= "	0; 	1;	2;	3;	4;	5;	6;	7;	8;	9;	10; 	11;	12;	13;	14;	15;	16;	17;	18;	19"
//static strconstant	lstEVAL_PRINTFILE	= "	10; 	11;	12;	13;	14;	15;	16;	17;	18;	19"	// used in table file
static strconstant	lstEVAL_PRINTSCR1= "	11;	12;	13;	14;	15;	16;	17;	1;	19; 	7"	// used as one and only screen line
static strconstant	lstEVAL_PRINTSCR2a= "	11;	12;	13;	14;	15;	16;	17"				// used as first screen line
static strconstant	lstEVAL_PRINTSCR2b= "	1;	19"									// used as second screen line



// 050813
// Indexing for finally extracted evaluation parameters = the GENERAL part of   All  Computed Values (ACV) :
 	constant		kVAL = 0, kT = 1, kY = 2, kTB = 3, kYB = 4, kTE = 5, kYE = 6,  kE_MAXTYP = 7
	strconstant	klstE_POST	= ";_T;_Y;_TB;_YB;_TE;_YE"
	constant		kE_CHNAME=0,   kE_EVENT=1,   kE_SINCE1DS=2,  kE_FILE=3,        kE_SCRIPT=4,    kE_DATE=5,       kE_TIME=6,     kE_DS=7,              kE_DSMX=8,      kE_BEG=9,        kE_END=10,        kE_PTS=11,      kE_AMPL=12,  kE_BAS1=13, kE_BAS2=14, kE_BASE=15, kE_SDBASE=16, kE_MEAN=17,  kE_SDEV=18
	constant		kE_BRISE=19,    kE_RISE20=20,  kE_RISE50=21,     kE_RISE80=22,  kE_RT2080=23,  kE_RISSLP=24,  kE_PEAK=25,  kE_EVVALID=26,  kE_HALDU=27,  kE_DEC50=28,  kE_DECSLP=29,  kE_RSER=30 

	 strconstant	klstEVL_RESULTS= "Ch;	Ev;Since1DS; 	Fi; 	Sc;	Da; 	Ti;	DS;  DMx;  Beg;End; Pts;	Ampl;Base1;	Base2;	Base;	SDBase;	Mean;	SDev; 	BsRise; 	RT20; 	RT50; 	RT80;	RT2080;	RiseSlp;	Peak; 	EvValid; 	HalfDur;	DT50;	DecSlp;	Rser;		"
	 strconstant	klstEVL_PRINT	     =  "0;	0;	0;		0;	0;	0;	0;	0;	0;	    0;	   0;	  0;	0;	0;		0; 		0,3,5;	0;		0;		0;		1,2;		1,2;		1,2;		1,2;		0,1;		0,1;		0,1,3,5;	0;		0;		0,1;		0,1;		0;			"
	 strconstant	klstEVL_IS_STRING="1;	0;	0;		1;	1;	1;	1;	1;	0;	    0;	   0;	  0;	0;	0;		0; 		0;		0;		0;		0;		0;		0;		0;		0;		0;		0;		0;		0;		0;		0;		0;		0;			"
	 strconstant	klstEVL_UNITS    =	" ;	;	s;		;	;	;	;	;	;	    ms; ms;	  ;	au;	au;		au; 		au;		au;		au;		au;		;		;		;		;		ms;		?;		au;		;		ms;		ms;		U2;		MO;			"
	//							 					  									cLLINEH cLLINEH cLLINEH							cRECT	cCIRCLE;	cSLINEH	cCIRCLE			cRECT	cRECT			cLLINEH	cSLINEV	cSLINEV	cSCROSS	
	 strconstant	klstEVL_SHAPES =	" ;	;	;		;	;	;	;	;	;	    ;	   ;	  ;	;	-9;		-9; 		-9;		;		;		;		13;		41;		9;		41;		;		13;		13;		;		-9;		10;		10;		0;			"
//	 strconstant	klstEVL_COLORS =	" ;	;	;		;	;	;	;	;	;	    ;	   ; 	  ;	;	DGreen;	DGreen; 	Green;	;		;		;		BBlue;	DBlue;	DBlue;	DBlue;	;		DCyan;	Red;		;		Yellow;	Green;	DCyan;	Mag;			"
	 strconstant	klstEVL_COLORS =	" ;	;	;		;	;	;	;	;	;	    ;	   ;	  ;	;	DGreen;	DGreen; 	Green;	;		;		;		BBlue;	DBlue;	Red;		DBlue;	;		DCyan;	Red;		;		Yellow;	Green;	DCyan;	Mag;			"


//  STIMFIT LOOK & FEEL
//     File        Event #       Time/       Ampl/       Mean/     RT2080/    Latenc1/    Latenc2/      HalDu/     SlopR/D        Base      SDBase      FITPAR
//    230103~1           1   55981.417       34.76       33.48      0.9781    -39.8753    -24.7000     17.9486      1.0000      -32.73        1.08
//    230103~1           2   55983.267       37.15       34.93      0.9543    -39.8259    -31.1000     17.8858      0.3571      -34.10        1.14
//strconstant lstCOLS =	"     File        Event #       Time/       Ampl/       Mean/     RT2080/    Latenc1/    Latenc2/      HalDu/     SlopR/D        Base      SDBase      FITPAR"
//constant	cFILE=0, cEVENT=1, cTIME=2, cAMPL=3, cMEAN=4, cRT2080=5, cLATENC1=6, cLATENC2=7, cHALDU=8, cSLOPRD=9, cBASE=10, cSDBASE=11, cFITPAR=12

// Possible drawing parameters using Igor's markers
static constant		kNONE = 0, cRECT = 13, cSLINEH = 9, cSLINEV = 10, cLLINEH = -9, cLLINEV = -10, cSCROSS = 0, cCIRCLE = 41 , cXCROSS = 1// , cFCROSS = 12, cLCROSS = 24	// some are Igor-defined markers


// Indexing for phase/region ( also working for cursors which are sort of generalized/specialized regions ):
	 constant		PH_BASE=0,  PH_PEAK=1,  PH_LATC0=2,  PH_LATC1=3,  PH_LATC2=4,  PH_FIT0=5,  PH_FIT1=6,  PH_FIT2=7// any number of fits are possible here ( requires at least PH_FIT2, adjust klstPH_CSRSHAPE and supply action procs if you want more)....
 strconstant	ksPHASES		= "Base;Peak;Latency0;Latency1;Latency2;Fit0;Fit1;"//Fit2;"						// ...but only  'ksPHASES'  determines how many fits are actually executed.  !!! # of fits MUST be ~  # of rows in Panel de
 strconstant	klstPH_CSRSHAPE	= " 9; 	9;	17; 		17; 		17;	  8;    8;	8;"							// e.g. CSR_VALSHORT + CSR_YSHORT = 9 .    Required are entries  INCLUDING PH_FIT2  even if  'ksPHASES'  determines that less fits are actually executed 
// strconstant	klstPH_CSRSHAPE	= " 9; 	9;	16; 		16; 		16;	  8;    8;	8;"							// e.g. CSR_VALSHORT + CSR_YSHORT = 9 .    Required are entries  INCLUDING PH_FIT2  even if  'ksPHASES'  determines that less fits are actually executed 
static constant	CSR_VALSHORT = 1, CSR_VALMEDIUM = 2, CSR_VALFULL = 4, CSR_YSHORT = 8, CSR_YFULL = 16
 
// Indexing for controls and values:
// Indexing for ChannelRegion Evaluation ( CN_BEG and  CN_END , CN_BEGY and  CN_ENDY  must be successive
  constant	  CN_BEG = 0, CN_END = 1, CN_BEGY = 2, CN_ENDY = 3,  CN_XAXLEFT = 4,  CN_XCSR_OS = 5,  CN_COLOR = 6,  CN_LO = 7,  CN_MAX = 8
static strconstant	sCN_TEXT	= "Beg;End;BegY;EndY;XaxLft;XcsrOs;Color;Lo;"

// Popupmenu indexing for the fit range
static constant		FR_WINDOW	= 0, FR_CSR = 1, FR_PEAK = 2
strconstant      	  	klstFITRANGE	= "Windw;Cursor;Peak"										// Igor does not allow this to be static

// Popupmenu indexing for result printing into history 
static	 constant		RP_HEADER = 1,  RP_FITSTART = 2,  RP_FIT = 4,  RP_BASEPEAK1 = 8 				// only powers of 2 can be added to give arbitrary combinations
 strconstant		ksPRINTRESULTS	= "nothing;Header;StimFit;Fit + Start;BasePeak;Print All"			//  Igor does not allow this to be static
 strconstant		ksPRINTMASKS	= "   0	;   1	   ;  3      ; 	7     ;   	8           ; 15 ;"				//  Arbitrary combinations . Cannot be static as it is used in Window macro
 
// Popupmenu indexing for autoselect results
 strconstant		ksAUTOSELECT	= "File+DSct;Standard1;Standard2;StimFit;"	//  Igor does not allow this to be static
 //								    File+DSct;		Standard1;				Standard2;						StimFit;								
 strconstant		lstlstAUTOSELECT	= "Fi_00,DS_00~Fi_00,DS_00,Base_00,Peak_01~Fi_00,DS_00,Peak_01,Ampl_01,Peak_T_10~DS_00,Base_00,Base_TB_00,Base_TE_01,Peak_00"
 //			sPostfix	= "_" + num2str( ch ) + num2str( rg )									// !!! Assumption : ACV naming convention


// Indexing for magnifying  wMagn[]
static constant		cXSHIFT = 0, cXEXP = 1, cYSHIFT = 2, cYEXP = 3, cMAX_MAGN = 4  


// Popupmenu indexing for Y axis end values
strconstant		ksYAXIS_	= "auto;10000;5000;2000;1000;500;200;100;50;20;10;5;2;1;-1;-2;-5;-10;-20;-50;-100;-200;-500;-1000;-2000;-5000;-10000;"


static constant		kLEFT_CSR = 0,	kRIGHT_CSR = 1
static strconstant	ksLR_CSR	="left;right"

// AutoControl constants : group of controls is totally off or not constructed , is totally on ,  only the checkbox is visible for switching the group on and off 
constant	kAC_UNCHECKED = 0,  kAC_ON = 1,  kAC_ON_LOCKED = 2,  kAC_HIDE = 3

constant	kFI_ON = 0  	// the only variable stored in wChRgFit	


Function		CreateGlobalsInFolder_SubEvl( sFolder )
// creates all folder-specific variables. To be used once from CreateGlobals() as the current data folder is changed and not restored
	string  	sFolder
	NewDataFolder  /O  /S $"root:uf:" + sFolder + ":evl"			// Evaluation (offline) : make a new data folder and use as CDF

	print "CreateGlobalsInFolder_SubEvl", sFolder

//	variable	/G	gChans								// number of channels to be evaluated will be set when CFS file hase been read (same as 'root:uf:evo:cfsr:gChannels' )

	// Globals for stand-alone Panel controls which are NOT controlled  by the huge wCRegion wave because they are outside the channel/region/phase ordering

//	variable	/G	gFitCnt			= 2					// !!!  Number of Fit ranges offered per Region. Must be == # of row titles in panel line '...cbFit:	  1. ,2. ,:	Fit:	fFit():	...'      Maximum is 3.
	variable	/G	gPrintMask		= 1					// controls the amount of result printing
//	variable	/G	gPkSidePts		= 2					// additional points on each side of a peak averaged to reduce noise errors  TOTHINK: same value for all channels/regions (except rSeries) 
//	variable	/G	gbSameMagn		= TRUE				// time of 2. channel always same as 1. channel
//	variable	/G	gbShowAverage	= TRUE				// 
// 050607
//	variable	/G	gnDispMode		= 1					// 0:single, 1:stacked, 2:catenated. The initial popmenu value must correspond and must be 1 more !!!
//	variable	/G	gbDispSkipped		= 1					// display  also  the unselected traces in a different color,  the selected traces are always drawn
//	variable	/G	gAvgKeepCnt		= 0					// number of currently averages traces in memory
//	string  	/G	gsAvgNm			= ""					// the user may override the auto-built name for the averaged traces

// 050608
//	variable	/G	gTblKeepCnt		= 0					// 0 means start a new result file xxx_n.fit 
//	variable	/G	gpStartValsOrFit		= 0					// 0 : do not fit, display only starting values, 1 : do fit
//	variable	/G	gpDispTracesOrAvg	= 0					// 0 : only traces, 1: traces + average,  2 : only average
//	variable	/G	gpPrintResults		= 7					// Initial index into 'ksPRINTRESULTS' popup defining which data are printed. 
//	variable	/G	gbResTextbox		= TRUE				// display or hide the evaluation results in the textbox in the graph window
// evl
	make /O  	    /N = ( kMAXCHANS,  cMAX_MAGN )				wMagn		= 0	// for  x and y  shifting and expanding the view
	make /O  	    /N = ( cMAXCURRG ) 							wPrevRegion	= 0	// saves channel, region, phase and CursorIndex when moving a cursor so that this previous cursor can be finished when the user fast-switches to a new cursor without 'ESC' e.g. 'b' 'B'. 
	make /O  	    /N = ( cMAXCURRG ) 							wCurRegion	= 0	// saves channel, modifier and mouse location when clicking a window to remember the 'active' graph when a panel button is pressed
	make /O  	    /N = ( kMAXCHANS, MM_XYMAX )				wMnMx		= TRUE// maximum X and Y data limits  and   whether  the display should be  'Reset' to these limits

	variable	nPH_MAX				= ItemsInList( ksPHASES )
	variable	nEVALRESULTS_MAX	= ItemsInList( klstEVL_RESULTS )
	make /O 	    /N = ( kMAXCHANS, kRG_MAX, nPH_MAX, CN_MAX  )	wCRegion	= 1				// region coordinates, drawing environment, number of phases in each region, whether the peak goes up or down, ...
	make /O 	    /N	 = ( kMAXCHANS, kRG_MAX, nEVALRESULTS_MAX, kE_MAXTYP) wEval = Nan	// Nan means this coord could not be evaluated


// 050216
	make /O 	    /N = ( kMAXCHANS, kRG_MAX )			wChRg	=  kAC_HIDE	// 0 or 1 : this region is defined for this channel or not
// 050216  either 1 dim less (see wChRg )  or  incorporate into wCRegion..............(additional index required)
	make /O 	    /N = ( kMAXCHANS, kRG_MAX,  nPH_MAX - PH_FIT0 , 1  )	wChRgFit	= kAC_HIDE		// 0 or 1 : this fit is defined for this channel and region or not

	// Initialisation values 
	variable	ch
	for ( ch = 0; ch < kMAXCHANS; ch += 1 )
		wMagn[ ch ][ cXSHIFT ]	= 0
		wMagn[ ch ][ cXEXP ]	= 1
		wMagn[ ch ][ cYSHIFT]	= 0
		wMagn[ ch ][ cYEXP ]	= 1
		// 050216
		wChRg[ ch ][ 0 ] = kAC_UNCHECKED					// 050216  the 1. region checkbox must be accessible initially.  All other are accessible once the 1. one is turned on.
		variable rg
		for ( rg = 0; rg < kRG_MAX; rg += 1 )
			wChRgFit[ ch ][ rg ][ 0 ][ kFI_ON ] = kAC_UNCHECKED		// 050216  the   1.   fit  checkbox   must be accessible initially.  All other are accessible once the 1. one is turned on.
		endfor

	endfor

	// Initialisation values :
	CopyToAllChansRegionsFromBase()

	CopyToAllChansRegions()

	SetPhColor( PH_BASE, 	cGreen )
	SetPhColor( PH_PEAK, 	cRed )
	SetPhColor( PH_LATC0, 	cBlue )
	SetPhColor( PH_LATC1, 	cBlack )
	SetPhColor( PH_LATC2, 	cBrown )
	SetPhColor( PH_FIT0, 	cMag )
	SetPhColor( PH_FIT1,	cCyan )
	SetPhColor( PH_FIT2, 	cOrange )

End


static Function		CopyToAllChansRegionsFromBase()
	wave	wCRegion		= root:uf:evo:evl:wCRegion
	variable	ch, rg, ph, typ
	variable	nPH_MAX		= ItemsInList( ksPHASES )
	for ( ch = 0; ch < kMAXCHANS; ch += 1 )
		for ( rg = 0; rg < kRG_MAX; rg += 1 )
			for ( ph = 0; ph < nPH_MAX; ph += 1 )
				for ( typ = 0; typ < CN_MAX; typ += 1 )
					wCRegion[ ch ][ rg ][ ph ][ typ ]	= wCRegion[ 0 ][ 0 ][ PH_BASE ][ typ ]	
				endfor		
			endfor		
		endfor		
	endfor		
End

static Function		CopyToAllChansRegions()
	wave	wCRegion		= root:uf:evo:evl:wCRegion
	variable	ch, rg, ph, typ
	variable	nPH_MAX	= ItemsInList( ksPHASES )
	for ( ch = 0; ch < kMAXCHANS; ch += 1 )
		for ( rg = 0; rg < kRG_MAX; rg += 1 )
			for ( ph = 0; ph < nPH_MAX; ph += 1 )
				for ( typ = 0; typ < CN_MAX; typ += 1 )
					wCRegion[ ch ][ rg ][ ph ][ typ ]	= wCRegion[ 0 ][ 0 ][ ph ][ typ ]	
				endfor		
			endfor		
		endfor		
	endfor		
End

 Function		SetXaxisLeft( ch, XaxisLeft )
	variable	ch, XaxisLeft
	wave	wCRegion		= root:uf:evo:evl:wCRegion
	variable	rg, ph
	variable	nPH_MAX		= ItemsInList( ksPHASES )
	for ( rg = 0; rg < kRG_MAX; rg += 1 )
		for ( ph = 0; ph < nPH_MAX; ph += 1 )
			wCRegion[ ch ][ rg ][ ph ][ CN_XAXLEFT ]	= XaxisLeft
		endfor		
	endfor		
	// printf "\t\tSetXaxisLeft( ch:%2d, XaxisLeft: %g) -> wCRegion[0][0][0][ CN_XAXLEFT ]: %g \r", ch, XaxisLeft, wCRegion[0][0][0][ CN_XAXLEFT ]  
End


 Function		SetXCursrOs( ch, XcursorOs )
	variable	ch, XcursorOs
	wave	wCRegion		= root:uf:evo:evl:wCRegion
	variable	rg, ph
	variable	nPH_MAX		= ItemsInList( ksPHASES )
	for ( rg = 0; rg < kRG_MAX; rg += 1 )
		for ( ph = 0; ph < nPH_MAX; ph += 1 )
			wCRegion[ ch ][ rg ][ ph ][ CN_XCSR_OS ]	= XcursorOs
		endfor		
	endfor		
	// printf "\t\tSetXCursrOs(  ch:%2d, XaxisLeft: %g) -> wCRegion[0][0][0][ CN_XCSR_OS ]: %g \r", ch, XcursorOs, wCRegion[0][0][0][ CN_XCSR_OS ]  
End



	Function		CursorsAreSet( ch )
	variable	ch 
	variable	rg = 0	// todo ??? only channel 0 is checked
	variable	csrPos	= RegionBegEnd( ch, rg, PH_BASE, CN_BEG )
	if ( csrPos == RegionBegEnd( ch, rg, PH_BASE, CN_END )  && csrPos == RegionBegEnd( ch, rg, PH_PEAK, CN_BEG ) && csrPos == RegionBegEnd( ch, rg, PH_PEAK, CN_END ) )
		return	FALSE	// if beginning and end of base and peak regions are the same we assume that these are the startup values meaning that no region has been set
	endif
	return	TRUE
End


	 Function		SpreadCursors( ch )
// Spread Base, Peak and Latency cursor (at least for first region) to reasonable values ( X between 1%, 10%, 30% of X full scale ) independent of actual time range.
// The cursors are placed not too close so that the user has no difficulties picking a certain cursor.
// ToDo/ToImprove: Do search the peak and place the cursors accordingly.
	variable	ch 
	variable	rg, ph
	variable	nPH_MAX		= ItemsInList( ksPHASES )

	string		sFoldOrgWvNm	= FoCurOrgWvNm( ch )
	wave  /Z	wOrg 		= $sFoldOrgWvNm
	if ( waveExists( wOrg ) )
		variable	AxisRange	 = numPnts( wOrg ) * deltaX( wOrg )
		variable	TimeLeftX	 = leftX( wOrg )
		for ( rg = 0; rg < kRG_MAX; rg += 1 )
			for ( ph = 0; ph < nPH_MAX; ph += 1 )
				// The first region takes up the 40% of the graph for the cursors. 
				if ( rg == 0  &&  ph == PH_BASE )
					SetRegionBegEnd( ch, rg, ph, CN_BEG , .01 * AxisRange + TimeLeftX )
					SetRegionBegEnd( ch, rg, ph, CN_END , .06 * AxisRange + TimeLeftX )
				elseif ( rg == 0  &&  ph == PH_LATC0 ) 
					SetRegionBegEnd( ch, rg, ph, CN_BEG , .08 * AxisRange + TimeLeftX )
					SetRegionBegEnd( ch, rg, ph, CN_END , .10 * AxisRange + TimeLeftX )
				elseif ( rg == 0  &&  ph == PH_LATC1 ) 
					SetRegionBegEnd( ch, rg, ph, CN_BEG , .12 * AxisRange + TimeLeftX )
					SetRegionBegEnd( ch, rg, ph, CN_END , .14 * AxisRange + TimeLeftX )
				elseif ( rg == 0  &&  ph == PH_LATC2 ) 
					SetRegionBegEnd( ch, rg, ph, CN_BEG , .16 * AxisRange + TimeLeftX )
					SetRegionBegEnd( ch, rg, ph, CN_END , .18 * AxisRange + TimeLeftX )
				elseif ( rg == 0  &&  ph == PH_PEAK )
					SetRegionBegEnd( ch, rg, ph, CN_BEG , .20 * AxisRange + TimeLeftX )
					SetRegionBegEnd( ch, rg, ph, CN_END , .23 * AxisRange + TimeLeftX )
				elseif ( rg == 0  &&  ph == PH_FIT0  &&  nPH_MAX > PH_FIT0 ) 
					SetRegionBegEnd( ch, rg, ph, CN_BEG , .25 * AxisRange + TimeLeftX )
					SetRegionBegEnd( ch, rg, ph, CN_END , .28 * AxisRange + TimeLeftX )
				elseif ( rg == 0  &&  ph == PH_FIT1  &&  nPH_MAX >PH_FIT1 )
					SetRegionBegEnd( ch, rg, ph, CN_BEG , .30 * AxisRange + TimeLeftX )
					SetRegionBegEnd( ch, rg, ph, CN_END , .33 * AxisRange + TimeLeftX )
				elseif ( rg == 0  &&  ph == PH_FIT2  &&  nPH_MAX > PH_FIT2 )
					SetRegionBegEnd( ch, rg, ph, CN_BEG , .35 * AxisRange + TimeLeftX )
					SetRegionBegEnd( ch, rg, ph, CN_END , .38 * AxisRange + TimeLeftX )
				else
				// The remaining regions share the last 60% of the graph for the cursors. 
					SetRegionBegEnd( ch, rg, ph, CN_BEG ,  (  .40 + (rg-1) *.60 / ( kRG_MAX - 1 ) + ph * .036 ) 		*  AxisRange + TimeLeftX )	// .05 for 4 phases (=1 fit) , .036 for 5 phases (=2 fits), must be (automatically?) spaced closer if more are to be used 
					SetRegionBegEnd( ch, rg, ph, CN_END ,  (  .40 + (rg-1) *.60 / ( kRG_MAX - 1 ) + ph * .036 + .025 ) * AxisRange + TimeLeftX )
				endif
			endfor		
		endfor		
		wave	wCRegion	= root:uf:evo:evl:wCRegion
		printf "\t\t\tSpreadCursors(b ch:%d   rg: 0..%d  ph: 0..%d  wave:'%s' )  has  TimeLeftX: %g   X axis range: %g : (%g..%g)  OK->SetRBE(0,0,0, %8.3lf + dx)  -> sets internally to %8.3lf \r", ch, rg-1, ph-1, sFoldOrgWvNm, TimeLeftX,  AxisRange,  TimeLeftX,  TimeLeftX + AxisRange, TimeLeftX, RegionBegEnd(0,0,0,CN_BEG)
	else
		 printf "\t\t\tSpreadCursors( ch:%d   wave:'%s' )  does not exist.\r", ch, sFoldOrgWvNm
	endif
	DisplayCursors_Base( ch )
	DisplayCursors_Peak( ch )
	DisplayCursors_Lat( ch )
	DisplayCursors_UsedFit( ch )								// Display the used fit cursors and hide the unused fit cursors immediately depending on the state of the region and fit checkboxes to give the user a feedback which parts of the data will be fitted in the next analysis
End


	 Function		AutoSetCursors( ch )
// Attempt to set Base cursor, Peak cursor and Peak direction automatically for first region and the first fit.  The user can discard the auto-cursors by pressing  'Spread cursors'  again.
	variable	ch 
	variable	rg = 0, ph = 0
	variable	nPH_MAX		= ItemsInList( ksPHASES )
	variable	pt, PkDir, PkLoc, PkEnd, FitEnd, DirFactor

	string		sFoldOrgWvNm	= FoCurOrgWvNm( ch )
	wave  /Z	wOrg 		= $sFoldOrgWvNm
	variable	AxisRange	 	= numPnts( wOrg ) * deltaX( wOrg )
	variable	TimeLeftX	 	= leftX( wOrg )
	if ( waveExists( wOrg ) )

		WaveStats /Q   wOrg
		PkDir	=  V_avg * 2  < V_min + V_max   ?   kPEAK_UP_	:  kPEAK_DOWN_	// The higher peak (min or max compared to average) determines the peak direction.. This simple evaluation...
		PkLoc	=  V_avg * 2  < V_min + V_max   ?   V_maxloc	:  V_minloc		// ...may be wrong for nearly equal pos and neg peaks if one has much greater time constant shifting the average.
		pt 		= ( PkLoc - TimeLeftX ) / deltaX( wOrg )
		DirFactor	= PkDir * 2 - 3		// Up=1 -> -1 ,  Down=2 -> +1
		do
			pt += 1
		while ( wOrg[ pt ] * DirFactor < ( V_avg + V_sdev ) *  DirFactor  &&   pt < V_npnts )	// Arbitrary: PeakEnd is when the decay reaches the mean (rough estimate, tampered by noise)
		PkEnd	= pnt2x( wOrg, pt )
		FitEnd	= PkEnd + .5 * ( PkEnd - PkLoc )							// Arbitrary: FitEnd is 50% behind PeakEnd
			
		SetRegionBegEnd( ch, rg, PH_BASE, CN_BEG,	TimeLeftX + .004 * AxisRange )
		SetRegionBegEnd( ch, rg, PH_BASE, CN_END,	TimeLeftX + .90  * ( PkLoc - TimeLeftX ) )
		SetRegionBegEnd( ch, rg, PH_PEAK, CN_BEG,	TimeLeftX + .94  * ( PkLoc - TimeLeftX ) )
		SetRegionBegEnd( ch, rg, PH_PEAK, CN_END,	PkEnd )
		SetRegionBegEnd( ch, rg, PH_FIT0, 	CN_BEG,	PkLoc )
		SetRegionBegEnd( ch, rg, PH_FIT0, 	CN_END,	FitEnd )
		SetPeakDir( ch, rg, PkDir )											// update the popupmenu with the auto-determined peak direction
		OnePeak( ch, rg )												// Do determination of the corresponding  peak immediately.  

		DisplayCursors_Base( ch )
		DisplayCursors_Peak( ch )
		// DisplayCursors_Lat( ch )
		DisplayCursors_UsedFit( ch )								// Display the used fit cursors and hide the unused fit cursors immediately depending on the state of the region and fit checkboxes to give the user a feedback which parts of the data will be fitted in the next analysis
		// printf "\t\tAutoSetCursors( ch:%2d )\tPts:\t%8d\tAvg:\t%8.2lf\tMax:\t%8.2lf\tMin:\t%8.2lf\t -> \tPkDir: %s \tPkPt:%8d\tPkLoc:\t%.4lf\tPkEnd:\t%.4lf\tFitEnd:\t%.4lf\t  \r", ch, V_npnts, V_avg, V_max, V_min, PeakDirStr( PkDir ), pt, PkLoc, PkEnd, FitEnd					
	endif
End


static Function		SetPhColor(  ph, nColor )
	variable	ph, nColor
	wave	wCRegion		= root:uf:evo:evl:wCRegion
	variable	ch, rg
	for ( ch = 0; ch < kMAXCHANS; ch += 1 )
		for ( rg = 0; rg < kRG_MAX; rg += 1 )
			wCRegion[ ch ][ rg ][ ph ][ CN_COLOR ]	= nColor	
		endfor		
	endfor		
End


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//    MAIN  EVALUATION  FUNCTION

Function	/S	FoCurOrgWvNm( ch )
	variable	ch
	wave	wCurRegion	= root:uf:evo:evl:wCurRegion
	variable	nCurSwp		= wCurRegion[ kCURSWP ]		
	variable	nSize		= wCurRegion[ kSIZE ]		
//	return	"root:uf:evo:evl:" + OrgWvNm( ch, nCurSwp, nSize )			// name must be unique for each channel
	return	"root:uf:evo:cfsr:" + OrgWvNm( ch, nCurSwp, nSize )				// name must be unique for each trace segment
End

Function	/S	FoOrgWvNm( ch, nCurSwp, nSize )
	variable	ch, nCurSwp, nSize
//	return	"root:uf:evo:evl:" + OrgWvNm( ch, nCurSwp, nSize )			// name must be unique for each channel
	return	"root:uf:evo:cfsr:" + OrgWvNm( ch, nCurSwp, nSize )				// name must be unique for each trace segment
End

Function	/S	OrgWvNm( ch, nCurSwp, nSize )
	variable	ch, nCurSwp, nSize
//	return	"wOrg" + num2str( ch )								// name must be unique for each channel
	return	CfsIONm_( ch ) + "_" + num2str( nCurSwp ) + "_" + num2str( nSize)	// make a UNIQUE name for each trace segment
End


Function		Analyse_( wOrg, nState, ch, XaxisLeft ) 
// Returns truth whether ALL fits (in all regions) were successful.
	wave	wOrg
	variable	nState, ch, XaxisLeft  

	string		sMsg
	variable	rLeft, rRight, rTop, rBot
	variable	msBeg, msEnd
	variable	rg = 0, rgCnt
	nvar		gPrintMask	= root:uf:evo:evl:gprintMask
	string		sWNm		= CfsWndNm( ch )
	string  	sTNL		= TraceNameList( sWNm, ";", 1 )
	variable	bSuccessfulFits	= TRUE							// assume a successful fit if no analysis has been done at all because  RegionCnt()  was 0

	// if ( nDataPts != numpnts(wOrg) )							// could not duplicate the specified number of points because we are at the end of the source wave...
	//	Alert( kERR_MESSAGE,  "End of data" )					// ...normally the management of the Prot/Frame/Sweep-numbers takes care that this never happens when ONE sweep is the unit, ...
	//	return 0											// ...but it may occur in the special case (e.g. File 80702.dat) with interleaved data when reading 2 or more sweeps as the smallest unit. 
	// endif											

//	if ( gPrintMask &  RP_HEADER )
//		printf "\tAnalyse # \tKeeps:%2d \tAvgs:%2d  %s\r", EvaluationCnt(), AvgCnt_( ch ) , pd( OrgWvNm( ch, nCurSwp, nSize ), 9)
//	endif

	// If the BASE evaluation is disabled, all following evaluations (Peak1, Peak2,...) must be disabled too because the baseline value is required
	// if we allow disabling the BASE evaluation we should alert the user:  Peak evaluation in Panel must be greyed/disabled or checkmark must automatically removed
	
	rgCnt		= RegionCnt( ch )
	for ( rg = 0; rg < rgCnt;  rg += 1 )	

		// 1  Draw the evaluation ranges : duration of baseline, time when slope to peak1 (and  peak 2) starts, ... 
		// MUST NEVER EXTEND INTO THE RISING PHASE (optimum is extremum in between artefact and signal peak)
		
		// 2 Compute the  mean value of the entire trace
		EvaluateMeanAndSDev( wOrg, ch, rg ) 
		
		
		// 3	Compute the BASE value
		//RegionX( ch, rg, PH_BASE, msBeg, msEnd )				// get the beginning and end of base evaluation region 
		if ( RegionX( ch, rg, PH_BASE, msBeg, msEnd ) == FALSE )		// check if the base evaluation region exists and get the beginning and end of this region
			SpreadCursors( ch )
			RegionX( ch, rg, PH_BASE, msBeg, msEnd )			// get the beginning and end of base evaluation region 
		endif

		if ( CheckNoise( ch, rg ) )		
			if ( AutoUserLimit( ch, rg ) )							// use automatically  determined limits for the noise check or use limits set by the user
				AutomaticBaseRegion( wOrg, ch, rg, msBeg, msEnd, rTop, rBot ) // guess the allowed baseline band from the noise in the given interval[ BaseL, BaseR ]
				SetRegionY( ch, rg, PH_BASE, rTop, rBot )
			else
				UserRegionBaseY( ch, rg, PH_BASE, rTop, rBot )	// get the user's Hi and Lo values  (stored separately so that they don't get overwritten when the user..
				SetRegionY( ch, rg, PH_BASE, rTop, rBot )			//...switches temporarily into 'auto' mode   and copy them into the evaluation region 
			endif
			EvaluateBase( wOrg, ch, rg, XaxisLeft,  ON ) 
		else
			SetRegionY( ch, rg, PH_BASE, (wOrg(msBeg) + wOrg(msEnd))/2, (wOrg(msBeg) + wOrg(msEnd))/2 )	//around the trace
			EvaluateBase( wOrg, ch, rg, XaxisLeft,  OFF ) 
		endif

		//    ConfidenceBand
		//ConfidenceBand( wOrg, rBaseNoise )			// not used (too slow)	//todo let slope also store BASE NOISE
	
		if ( PeakDir( ch, rg ) != kPEAK_OFF_ )
	 		// Evaluate Peak  and compute related values ( e.g. EventValid, Rseries )
			// Evaluate the true minimum and maximum peak value and location by removing the noise in a region around the given approximate peak location 
			RegionX( ch, rg, PH_PEAK, rLeft, rRight )			// get the beginning of the Peak1 evaluation region (=rLeft)
			EvaluatePeak( wOrg, ch, rg, PH_PEAK, rLeft, rRight ) 
			SetRegionY( ch, rg, PH_PEAK, EvY( ch, rg, kE_PEAK ), EvY( ch, rg, kE_PEAK ) )	// cosmetics: set the evaluated peak value as top and bottom of evaluation region to show the user the value (additionally to circle...)
		 
	// 050813 todo clarify BAS1, BAS2 and BASE
			if ( ExistsEvY( ch, rg, kE_BAS1 )  &&  ExistsEvY( ch, rg, kE_BAS2 )  &&  ExistsEvY( ch, rg, kE_PEAK ) )		
	//			SetEval( ch, rg, kE_BAS1, kVAL, EvY( ch, rg, kE_BAS1 ) )
	//			SetEval( ch, rg, kE_BAS2, kVAL, EvY( ch, rg, kE_BAS2 ) )
	//			SetEval( ch, rg, kE_BASE, kVAL, EvY( ch, rg, kE_BAS2 ) )							// Version1: the base value is the value of the trailing base segment (which is right before the peak) 
				//SetEval( ch, rg, kE_BASE, kVAL, ( EvY( ch, rg, kE_BAS1 )  + EvY( ch, rg, kE_BAS2 ) ) / 2)	// Version2: the base value is the average between the leading and the trailing base segment
				SetEval( ch, rg, kE_PEAK, kVAL, EvY( ch, rg, kE_PEAK ) )
				SetEval( ch, rg, kE_AMPL, kVAL, EvY( ch, rg, kE_PEAK ) - EvY( ch, rg, kE_BAS2 ) )
				// 050902 Problems computing the series resistance
				// 1. Works only in VC mode when Base/Peak/Amp  are in pA.  User responsibility 
				// 2. The PeakSidePoints must be set to 0 as a very asymmetric peak is expected. Also User responsibility  .
				// 3. Due to opening channels before and during the Rseries pulse the baseline right before the pulse might be noisy or (worse) steadily rising. In this case it is important to set only a narrow baseline region right before the pulse. Also User responsibility  
				//	Perhaps an improvement would be to also analyse the negative peak and to alert the user if there are large differences.  ??? TODO
				//	TODO  incorporate units  ( = pA here in VC mode ) , and convert to MegOhms. 
				SetEval( ch, rg, kE_RSER, kVAL, RserMV( ch, rg ) / EvV( ch, rg, kE_AMPL ) * 1e6 )	// compute the series resistance from the peak amplitude . Todo : recognise 'MOhm' and 'pA' from 'klstEVL_UNITS' to compute 1e6

				// Check EVENT VALIDITY : Check if there is an event within the peak window having an amplitude larger than  'user-defined-factor x Base Standard deviation'
				// Refinements:	1. check that base line is not extraordinary noisy which would prevent detection of a valid peak (compare  with SDev(whole trace)  or with previous SDBase values)
				// 			2. check that the detected peak is not a noise peak (compute peak area)
				// Different approach: Compute event validity not for every peak but only for those where a latency is defined. Maybe this has advantages but it is more complex.... 
				variable	bEvValid	= abs( EvV( ch, rg, kE_AMPL ) )  > SDevFactor_( ch, rg )  * EvV( ch, rg, kE_SDBASE )
				//printf "\t\tEvent is valid  ch:%2d  rg:%2d   %g  ? > ?  %g   [%g  x %g]   -> bEventValid:%2d	\r", ch, rg, abs( EvV( ch, rg, kE_AMPL ) ) ,  EvV( ch, rg, kE_SDBASE ) * SDevFactor( ch, rg )  ,  SDevFactor( ch, rg )  ,  EvV( ch, rg, kE_SDBASE ) , bEvValid	
				SetEval( ch, rg, kE_EVVALID, kVAL, bEvValid )
			endif


			//  Compute the real levels in the rising and falling phases of a UP  or  DOWN peak
			variable	Val20, Val50, Val80, 	rLoc20, rLoc50, rLoc80
			Val20	=  EvY( ch, rg, kE_BAS2 ) * 4 / 5  +  EvY( ch, rg, kE_PEAK ) * 1 / 5
			Val50	=  EvY( ch, rg, kE_BAS2 ) * 1 / 2  +  EvY( ch, rg, kE_PEAK ) * 1 / 2
			Val80	=  EvY( ch, rg, kE_BAS2 ) * 1 / 5  +  EvY( ch, rg, kE_PEAK ) * 4 / 5
		
			//  Evaluation to find the rise start location ( smoothed rise-baseline crossing next to peak location, exists always )
			RegionX( ch, rg, PH_PEAK, rLeft, rRight )	// get the beginning of the Peak1 evaluation region (=rLeft)
			variable	nPeakDir	= PeakDir( ch, rg )
			EvaluateCrossing( wOrg, ch, rg, nPeakDir, "Rise",  rLeft, EvT( ch, rg, kE_PEAK ), 20, Val20, kE_RISE20 ) 
			EvaluateCrossing( wOrg, ch, rg, nPeakDir, "Rise",  rLeft, EvT( ch, rg, kE_PEAK ), 50, Val50, kE_RISE50 ) 
			EvaluateCrossing( wOrg, ch, rg, nPeakDir, "Rise",  rLeft, EvT( ch, rg, kE_PEAK ), 80, Val80, kE_RISE80 ) 
			EvaluateSlope(	   wOrg, ch, rg, PH_PEAK, nPeakDir, "Rise",  rLeft, EvT( ch, rg, kE_PEAK ), kE_RISSLP ) 
			
			//  Get intersection of  baseline  and  line going through RT20 and RT80 
			variable	RISE20orRISE50 = ExistsEvT( ch, rg, kE_RISE20 )  ?   kE_RISE20  :  kE_RISE50					// the 20% crossing may not exist BUT the 50% CROSSING IS ASSUMED TO EXIST
			FourPointIntersection( ch, rg, kE_BAS1, kE_BAS2, RISE20orRISE50, kE_RISE80,  kE_BRISE ) 
	
			//  Risetime 20 to 80
			if ( ExistsEvT( ch, rg, kE_RISE80 )  &&   ExistsEvT( ch, rg, kE_RISE20 )  )
				SetEval( ch, rg, kE_RT2080, kVAL,  EvT( ch, rg, kE_RISE80 )  - EvT( ch, rg, kE_RISE20 ) )
				SetEval( ch, rg, kE_RT2080,  kT,   ( EvT( ch, rg, kE_RISE80 )  + EvT( ch, rg, kE_RISE20 ) ) / 2 )
			endif
			
			//  Evaluation to find the decay end location ( smoothed decay-baseline crossing next to peak location, may not exist )
			variable locEndDecay 
// 060216
			variable start = EvT( ch, rg, kE_PEAK )
			variable level = EvY( ch, rg, kE_BAS2 )
			FindLevel	/Q /R=( start, Inf)  wOrg, level	// try to find time when decay crosses baseline ( may not exist )
			if ( V_flag )
				sprintf sMsg, "Decay did not find BaseLevel Crossing (%.1lf) after %.1lfms  (smoothing till end...) ", level, start
				Alert( kERR_LESS_IMPORTANT,  sMsg )
				//locEndDecay = Inf
				locEndDecay = rightX( wOrg )
			else
				locEndDecay  = V_LevelX
			endif
// 060216
			EvaluateCrossing( wOrg, ch, rg, nPeakDir, "Decay",  EvT( ch, rg, kE_PEAK ) , locEndDecay, 50, Val50, kE_DEC50 ) 
			EvaluateSlope(	   wOrg, ch, rg, PH_PEAK, nPeakDir, "Decay",  EvT( ch, rg, kE_PEAK ) , locEndDecay, kE_DECSLP ) 
		
			//   Half duration
			if ( ExistsEvT( ch, rg, kE_DEC50 )  &&   ExistsEvT( ch, rg, kE_RISE50 )  )
				SetEval( ch, rg, kE_HALDU, kVAL, EvT( ch, rg, kE_DEC50 )  - EvT( ch, rg, kE_RISE50 ) )
			endif
	
		endif		// Peak is On


		//  Display the selected evaluated special points in the graph
		if ( WinType( sWNm ) == kGRAPH ) 									// As the user may have closed a window, perhaps to remove an empty channel, ...
			DisplayEvaluatedPoints( ch, rg, sWNm )
		endif
		//  Do all the fitting 
		bSuccessfulFits	=  AllFitting( wOrg, ch, rg )

	endfor		// regions
	return	bSuccessfulFits
End		// of  Analyse_()



Function		SetResultsValidWithoutAnalysis( ch, nOfsPts, nDataPts, nSmpInt, nDataSections, nCurSwp, nSize, nWvKind  )
	variable	ch, nOfsPts, nDataPts, nSmpInt, nDataSections, nCurSwp, nSize, nWvKind 
	variable	rg, rgCnt	= RegionCnt( ch )
	for ( rg = 0; rg < rgCnt;  rg += 1 )	

		// Store some general numbers in  'wEval'  so that they can be retrieved in  'ResultsFromLB()'  
		SetEval( ch, rg, kE_EVENT, 	kVAL, EvaluationCnt( ch ) )		
		SetEval( ch, rg, kE_SINCE1DS,	kVAL, DSTimeSinceFr1_( nCurSwp ) )

// 051114a
//		SetEval( ch, rg, kE_DS, 		kVAL, nCurSwp )
		string  /G 	root:uf:evo:evl:gsDSName					// was kE_DS = number, is now a string to accomodate MovAvg  data section name  e.g.  1_6_4
		svar	gsDSName	= root:uf:evo:evl:gsDSName
		if ( nWvKind == kWV_ORG_ )
			gsDSName	= num2str( nCurSwp )
		else
			gsDSName	= DsNm_( nCurSwp )		// for kWV_AVG  e.g.  1_6_4
		endif

		SetEval( ch, rg, kE_DSMX,		kVAL, nDataSections )
		SetEval( ch, rg, kE_BEG,		kVAL, nOfsPts * nSmpInt / kXSCALE )			// in seconds
		//SetEval( ch, rg, kE_BEG,	kVAL, nOfsPts * nSmpInt / kMILLITOMICRO )		// in milliseconds
		SetEval( ch, rg, kE_END,		kVAL,  ( nOfsPts + nDataPts ) * nSmpInt / kXSCALE )	// in seconds
		SetEval( ch, rg, kE_PTS,		kVAL, nDataPts )
	endfor
End



static Function	/S	OldColumnTitles( nAmount, lstTitles, nWvKind )
// Return the previous column titles. This allows to check if the user changed any settings which would require writing a new column title line in the total results file e.g. # of channels, regions or fits,  the fit function, or a new file has been loaded
//  glstResultTitles  contains  only the selected titles , glstCombiCols  contains  the selected titles  plus titles that once were selected but are now not longer selected
	variable	nAmount, nWvKind
	string  	lstTitles
	// Two global strings are needed to check if the user changed any settings which would require writing a new column title line in the results file e.g. # of channels, regions or fits,  the fit function, or a new file has been loaded
	svar	   /Z	glstResultTitles	= $ResultTitles( nAmount, nWvKind )	// there will be 4 strings: 2 for selected results(org+avg), 2 for total results (the total results will not change when an existing LB field is selected, but the selected results will)
	if ( ! svar_exists( glstResultTitles ) )
		string  /G	$ResultTitles( nAmount, nWvKind )	= ""
		svar	   	glstResultTitles	= $ResultTitles( nAmount, nWvKind )	
	endif
	string  lstOldTitles	= glstResultTitles
	if ( cmpstr( glstResultTitles,  lstTitles ) )
		// printf "\t\tColumnTitlesHaveChanged() : CHANGE\t'lstTitles'\thas %3d items : '%s .... %s' \r", ItemsInList( lstTitles ), lstTitles[0,60], lstTitles[ strlen( lstTitles )-60 , inf ]
		glstResultTitles	= lstTitles											// The user HAS changed settings requiring writing a new column title line in the total results file
	// else
		// printf "\t\tColumnTitlesHaveChanged() : same  \t'lstTitles'\thas %3d items : '%s .... %s' \r", ItemsInList( lstTitles ), lstTitles[0,60], lstTitles[ strlen( lstTitles )-60 , inf ]
	endif
	return	lstOldTitles
End


// Constants for displaying a results table
static constant		kRES_TBL_MARGINX	= 14
static constant		kRES_COLWIDTH		= 50			// 20 is minimum column width allowed by Igor
static strconstant	ksRES_TBLBASENM	= "tbResults"

 constant			kCOL_TITLES_	= 0,  kVALUES_ = 1


static Function	/S	ResultWvNm( nAmount, nWvKind )	
// There are 4 result waves :  2 small 'selected'  and  2  huge 'total'  results waves  ( for  Org and for Avg )
	variable	nAmount								// kLB_SELECT  or  kLB_ALL
	variable	nWvKind 								// kWV_ORG_	  or  kWV_AVG 
	return	"root:uf:evo:evl:wR" + num2str( nAmount ) + SelectString( nWvKind, "Org", "Avg" )
End

Function	/S	ResultTableNm_( nAmount, nWvKind )
// There are 4 result tables :  2 small 'selected'  and  2  huge 'total'  results tables  ( for  Org and for Avg )
// 051111 Route results from original data and from averaged data into different waves, tables and files
	variable	nAmount								// kLB_SELECT  or  kLB_ALL
	variable	nWvKind 								// kWV_ORG_	  or  kWV_AVG 
	return	ksRES_TBLBASENM + num2str( nAmount ) + SelectString( nWvKind, "Org", "Avg" )	
End

static Function	/S	CombiColsNm( nAmount, nWvKind )
// There are 4 combi columns :  2 small 'selected'  and  2  huge 'total'  results tables  ( for  Org and for Avg )
// 051111 Route results from original data and from averaged data into different waves, tables and files
	variable	nAmount								// kLB_SELECT  or  kLB_ALL
	variable	nWvKind 								// kWV_ORG_	  or  kWV_AVG 
	return	"root:uf:evo:evl:glstCombiCols" + num2str( nAmount )+ num2str( nWvKind )	
End

static Function	/S	ResultTitles( nAmount, nWvKind ) 
// There are (generally) 4 result titles :  2 small 'selected'  and  2  huge 'total'  results tables  ( for  Org and for Avg ) , but  glstResultTitles  contains  only the selected titles 
	variable	nAmount								// kLB_SELECT  or  kLB_ALL
	variable	nWvKind 								// kWV_ORG_	  or  kWV_AVG 
	return	"root:uf:evo:evl:glstResultTitles" + num2str( nAmount )+ num2str( nWvKind )
End	


Function		AddToTableAllChans_( nAmount, nState, nWvKind  )
//  Big advantage (when compared to 'AddDirectlyToFile()'  : Does adjust automatically to the user selecting additional results during the analysis, does insert the additionally required columns.
//  Depending on 'nAmount' possibly build the selected results wave 'wR0'  or  the total wave 'wR1' , possibly build the results table, display the selected results wave and save to file at appropriate times
//  If 'nAmount'  is kLB_SELECT  then the results are only those whose LB-fields are colored : Possibly build the results wave 'wR0', possibly build the results table, display the results wave and save to file at appropriate times
//  If 'nAmount'  is 	kLB_ALL	     then the results are  all  LB-fields (many!) :	 Possibly build the results wave 'wR1', possibly build the results table, do NOT display the results wave but save to file at appropriate times
//  wR0 and wR1  are  TEXT  waves so we can store channel, file and script name just like numbers.
//  If the user   adds 	columns, additional columns are inserted also for previous rows where they stay empty.
//  If the user deletes	columns, they are in effect kept but will stay empty from then on,  so the table can only grow but never shrink. This approach keeps all information without the need for inserting title rows among the values.

	variable	nAmount		// kLB_SELECT  or  kLB_ALL
	variable	nState
	variable	nWvKind 		// kWV_ORG_	  or  kWV_AVG 
	variable	ch
	string	  	lstValues = "", 	lstColTits = ""

	// Get the column titles  and the values for the fields currently selected in the listbox  (or get all titles and values if nAmount is kLB_ALL )
	nvar		gChans	= root:uf:evo:cfsr:gChannels
	for ( ch = 0; ch < gChans; ch += 1 )
		lstColTits	+= ResultsFromLB( kCOL_TITLES_, nAmount, nState, ch )			// TODO is called too often, is needed only once at the beginning or when the columns change (e.g. additional channels are evaluated)
		lstValues	+= ResultsFromLB( kVALUES_, nAmount, nState, ch  )				// these results (selected or total) will be printed into table and saved to file at appropriate times
	endfor
	
	string 	lstOldCols		= OldColumnTitles( nAmount, lstColTits, nWvKind )		// Retrieve old column titles and store the current 'lstColTits'  which will be retrieved as 'lstOldCols'  on the next call
	variable 	r, nRows, c, nCols, cOld, nOldCols, bNewHeader, CombiIdx

	string  	sOldColTitle, sColTitle, lstTotalCols, sValue, lstCombiVals = ""
// 051111 Route results from original data and from averaged data into different waves, tables and files
	string  	sResultTblNm	= ResultTableNm_( nAmount, nWvKind )				// there are 2 small 'selected'  and  2  huge 'total'  results tables  ( for  Org and for Avg )

	nCols		= ItemsInList( lstValues )
	bNewHeader	= cmpstr( lstColTits, lstOldCols )

	//  glstResultTitles (passed as lstOldTitle here)  contains  only the selected titles , glstCombiCols  contains  the selected titles  plus titles that once were selected but are now not longer selected
	svar	   /Z	glstCombiCols	= $CombiColsNm( nAmount, nWvKind )				// we must remember the old and new combined columns forever even if columns are deleted at some times.
	if ( ! svar_exists( glstCombiCols ) )
		string  /G	$CombiColsNm( nAmount, nWvKind )	= lstOldCols
		svar	   	glstCombiCols	= $CombiColsNm( nAmount, nWvKind )
	endif
	lstOldCols	  = glstCombiCols											// remember the previous combined columns because they are needed below for shifting all previous data to the right
	// printf "\t\tAddToTableToFileAllChans(1)\tCombiCols\titems:%2d : \t%s .... %s \r", ItemsInList( glstCombiCols ), glstCombiCols[ 0, 90 ], glstCombiCols[ strlen( glstCombiCols ) -  90, inf ] 

	lstTotalCols  = ResultsFromLBAllChans( kCOL_TITLES_, kLB_ALL, nState )

	// Build the new combined columns
	variable	OldIdx, NewIdx
	string  	sTitle
	nCols	= ItemsInList( lstTotalCols )
	for ( c = 0; c < nCols; c += 1 )
		sTitle		= StringFromList( c, lstTotalCols )
		OldIdx	= WhichListItem( sTitle, glstCombiCols )
		NewIdx	= WhichListItem( sTitle, lstColTits )
		if ( OldIdx == kNOTFOUND  &&  NewIdx != kNOTFOUND )
			// printf "\t\tAddToTableToFileAllChans() \t%3d /%3d \t%s\tfound \t\t\t\t\t\tin NewList (item:%3d)  \r", c, nCols, pd(sTitle,12), NewIdx
			glstCombiCols	= AddListItem( sTitle, glstCombiCols, ";", inf )
		endif
	endfor
	// printf "\t\tAddToTableToFileAllChans(2)\tCombiCols\titems:%2d :\t%s .... %s \r", ItemsInList( glstCombiCols ), glstCombiCols[ 0, 90 ], glstCombiCols[ strlen( glstCombiCols ) -  90, inf ] 

	// Order the combined titles: Loop through all total column titles and check if the title is in the combined title list. If yes add to the rebuilt and now ordered combined title list. 
	string  	lstTmp	= glstCombiCols
	glstCombiCols	= ""
	nCols	= ItemsInList( lstTotalCols )
	for ( c = 0; c < nCols; c += 1 )
		sTitle		= StringFromList( c, lstTotalCols )
		CombiIdx	= WhichListItem( sTitle, lstTmp )
		if ( CombiIdx != kNOTFOUND )
			glstCombiCols	= AddListItem( sTitle, glstCombiCols, ";", inf )
			// printf "\t\tAddToTableToFileAllChans(2a)\tc:%2d/%2d\tindex:%2d\tCombiCols\t%s... + %s -> %s... \r", c, nCols, CombiIdx, glstCombiCols[ 0, 90 ], sTitle, glstCombiCols[ 0, 90 ] 
		endif
	endfor	
	// printf "\t\tAddToTableToFileAllChans(3)\tCombiCols\titems %2d :\t%s .... %s \r", ItemsInList( glstCombiCols ), glstCombiCols[ 0, 90 ], glstCombiCols[ strlen( glstCombiCols ) -  90, inf ] 
	
	// Loop through all current column titles and find the column location in the combined column titles. At the column location found insert the current data value.
	nCols	= ItemsInList( lstColTits )
	for ( c = 0; c < nCols; c += 1 )
		sTitle		= StringFromList( c, lstColTits )
		CombiIdx	=  WhichListItem( sTitle, glstCombiCols )
		sValue	= StringFromList( c, lstValues )
		// printf "\t\tAddToTableToFileAllChans(4)\t%s\t= %s\tis item %2d/%2d \tin current list, will be placed in col %2d/%2d in Combined list.\t%s .... %s \r", pd( sTitle,12), pd(sValue,10), c, nCols, CombiIdx, ItemsInList( glstCombiCols ), glstCombiCols[ 0, 90 ], glstCombiCols[ strlen( glstCombiCols ) -  90, inf ] 
		lstCombiVals	= ReplaceListItem1( sValue, lstCombiVals, ";", CombiIdx )
	endfor	
	// printf "\t\tAddToTableToFileAllChans(5)\tCombiVals\titems %2d :\t%s .... %s \r", ItemsInList( lstCombiVals ), lstCombiVals[ 0, 90 ], lstCombiVals[ strlen( lstCombiVals ) -  90, inf ] 

	// Build or redimension the wave which feeds the results table
	nCols	= ItemsInList( glstCombiCols )						// the table contains old and new columns: it can only grow but never shrink, so no data will ever be lost 
// 051111 Route results from original data and from averaged data into different waves, tables and files
	string  	sResultWvNm		= ResultWvNm( nAmount, nWvKind )	// there are 2 small 'selected'  and  2  huge 'total'  results waves  ( for  Org and for Avg )
	wave  /Z	/T	wt			= 	$sResultWvNm
	if ( ! waveExists( wt ) )
		nRows 	= 0
		make /T/N=( nRows + 1, nCols )	$sResultWvNm
		wave  /T	wt			= 	$sResultWvNm
	else
		nRows	= DimSize( wt, 0 )							// the result wave 'wt' exists so we make space for one more line 
		Redimension /N=( nRows + 1, nCols )  wt
	endif

	// Shift the items in preceding rows to the right so that they match the new column titles which in part will be shifted due to the additional columns
	if ( bNewHeader	 )
		// printf "\t\tAddToTableToFileAllChans(6a)\tOldCols    \titems %2d :\t%s .... %s \r", ItemsInList( lstOldCols ), lstOldCols[ 0, 90 ], lstOldCols[ strlen( lstOldCols ) -  90, inf ] 
		// printf "\t\tAddToTableToFileAllChans(6b)\tCombiCols\titems %2d :\t%s .... %s \r", ItemsInList( glstCombiCols ), glstCombiCols[ 0, 90 ], glstCombiCols[ strlen( glstCombiCols ) -  90, inf ] 
		nCols	= ItemsInList( glstCombiCols )
		cOld 		= 0
		for ( c = 0; c < nCols; c += 1 )
			sColTitle		= StringFromList( c, glstCombiCols )
			sOldColTitle	= StringFromList( cOld, lstOldCols )
			if ( cmpstr( sColTitle, sOldColTitle ) ) 
				cOld -= 1									// a new column is inserted
				for ( r = 0; r < nRows; r += 1 )
					variable cc
					for ( cc = nCols; cc > c; cc -= 1 )				// shift all columns behind the inserted column to the right...
						wt[ r ][ cc ] = wt[ r ][ cc - 1 ]  			//...starting  from the last and going to the left to preserve the data
					endfor
					wt[ r ][ cc ] = "-"
				endfor
			endif
			cOld += 1	
		endfor
	endif

	// Fill the new row with the values from the results wave
	for ( c = 0; c < nCols; c += 1 )
		wt[ nRows ][ c ]	=  StringFromList( c, lstCombiVals )			// wR0 and wR1  are  text waves 
	endfor

	// Possibly build the table to display the selected results.  Depending on the state of the 'Disp Table' checkbox display or hide (=minimise)  the table.
	if ( WinType( sResultTblNm ) != kTABLE )

		variable	nColWidth	= ( nCols + 1 ) * kRES_COLWIDTH	
		variable	xMaxPt	= GetIgorAppPixelX() * kIGOR_POINTS72 / screenresolution	// convert to points
		variable	yMaxPt	= GetIgorAppPixelY() * kIGOR_POINTS72 / screenresolution	// convert to points

// 051111 Route results from original data and from averaged data into different waves, tables and files
		if ( nAmount == kLB_SELECT ) 
			if ( nWvKind == kWV_ORG_ ) 
				Edit	 /N=$sResultTblNm  /K=2   /W=( xMaxPt/3,	yMaxPt/2 - 20,	xMaxPt/3 + nColWidth + kRES_TBL_MARGINX, yMaxPt )  wt  as  "Results Org"		// the bottom middle to right corner
			else
				Edit	 /N=$sResultTblNm  /K=2   /W=( xMaxPt/3+20,	yMaxPt/2-20+10,xMaxPt/3 + nColWidth + kRES_TBL_MARGINX, yMaxPt )  wt  as  "Results Avg"		// the bottom middle to right corner
			endif
		else
			if ( nWvKind == kWV_ORG_ ) 
				Edit	 /N=$sResultTblNm  /K=1   /W=( xMaxPt/5,	yMaxPt/2,		xMaxPt/5 + nColWidth + kRES_TBL_MARGINX, yMaxPt )  wt  as  "All Results Org"	// the bottom middle to right corner
			else
				Edit	 /N=$sResultTblNm  /K=1   /W=( xMaxPt/5+20,	yMaxPt/2  +10,	xMaxPt/5 + nColWidth + kRES_TBL_MARGINX, yMaxPt )  wt  as  "All Results Avg"	// the bottom middle to right corner
			endif
		endif
//		if ( ! DisplayTable() )
		if ( ! DisplayTable()  ||  nAmount == kLB_ALL )		// the display of only the small table depends on the state of the 'Disp table' checkbox, the huge table is always hidden. 
			MoveWindow /W=$sResultTblNm	0, 0, 0, 0					// minimise table (table killing must be and is prevented  by Edit /K=2)
		endif

	 	SetWindow $sResultTblNm , hook( ResultTable ) = fHookResults_
		ModifyTable /W=$sResultTblNm		width	= kRES_COLWIDTH			// Flaw: will fail when table is empty...
	
	endif
	
	// Update the table header with possibly changed column titles 
	if ( bNewHeader )
		nCols	= ItemsInList( glstCombiCols )							// the table contains old and new columns: it can only grow but never shrink, so no data will ever be lost 
		DoUpdate													// 050901 force Igor to provide additional columns in the table for the grown wave NOW 		
		for ( c = 0; c < nCols; c += 1 )
			sColTitle	= StringFromList( c, glstCombiCols ) 
			ModifyTable /Z /W=$sResultTblNm     title[ c + 1 ]	   = sColTitle
			ModifyTable /Z /W=$sResultTblNm     alignment[ c + 1 ] = 0			// 0 starts entry at left border 
		endfor
	endif
End


static constant		kTBLFILE_TABBED = 0,  kTBLFILE_SPACED = 1	// the column delimiter in the table file is the tabulator (more flexible, saves disk space, but readable only with e.g. EXCEL)  or  spaces (12 chars/column, directly readable) 

Function		SaveTblFile_( nAmount, nWvKind )
// Design issue / todo: save tab delimites, fixed format with spaces (Date->date, time, no long file and script names), or let  Igor save wave...?
// 051111 Route results from original data and from averaged data into different waves, tables and files
	variable	nAmount			// kLB_SELECT  or  kLB_ALL
	variable	nWvKind 			// kWV_ORG_	  or  kWV_AVG 
	
	variable	nFormat	= kTBLFILE_SPACED				// the column delimiter in the table file is the tabulator (more flexible, saves disk space, but readable only with e.g. EXCEL)  or  spaces (12 chars/column, directly readable) 
	variable	c, nCols, r, nRows
	variable	nRefNum
	string  	sItem


//  Design issue: Revive this code if the current table file is to be closed and a new table file is to be openend automatically  when the user changes the Cfs file. ???
// if ( FileBasesDiffer( CfsRdDataPath() , CurrentTableFile() ) ) 						// the user may have changed the Cfs file or may have cleared the table. In either case a new table file will be written. 
//	sFilePath	= ConstructNextResultFileName_( CfsRdDataPath(), ksTBLEXT_ )
//	SetCurrentTableFile( sFilePath )											// includes index  e.g. Cfsdata_10.fit

	string  	sFileExt	= SelectString( nAmount , ksTBLEXT_, ksTOTALTBLEXT_ ) 		// the  'selected'  file  will get the extension  '.fit' ,  the  'total'  file will get the extension  '.tbl'  
	string  	sSpecifier	= SelectString( nWvKind, "org", "mav" )				
	string  	sFilePath	= ConstructNextResultFileName_( CfsRdDataPath(), sSpecifier, sFileExt ) // append  specifier 'Org'  or  'Avg'  to base name e.g. 'C:Epc:Data:123_1_org.fit'   or  'C:Epc:Data:456_2mav.tbl' 
	svar		gsTblNm	= root:uf:evo:de:gsTblNm0000	
	gsTblNm	= sFilePath												// update control : the next free  tbl   file where  tbl  data will be written is displayed in SetVariable input field


	Open  	nRefNum  as sFilePath										// Open file  by  creating it
	if ( nRefNum ) 														// ...a new average always overwrites the whole file, it never appends
	
// 051111 Route results from original data and from averaged data into different waves, tables and files
		wave  /Z	/T	wt			= 	$ResultWvNm( nAmount, nWvKind )//$"root:uf:evo:evl:wR" + num2str( nAmount )
		if ( waveExists( wt ) )
			nRows	= DimSize( wt, 0 )	
			nCols	= DimSize( wt, 1 )	
			svar	   	glstCombiCols	=	$CombiColsNm( nAmount, nWvKind )
			for ( c = 0; c < nCols; c += 1 )
				if ( nFormat == kTBLFILE_TABBED )
					sprintf sItem, "%s\t",	 StringFromList( c, glstCombiCols )
				else
					// sprintf sItem, "%-13s ", StringFromList( c, glstCombiCols )		// titles are left justified
					sprintf sItem, "%13s ", StringFromList( c, glstCombiCols )		// titles are right justified
				endif
				 printf  "%s%s", sItem, SelectString( c == nCols - 1 , "", "\r" )
				fprintf  nRefNum, "%s%s", sItem, SelectString( c == nCols - 1 , "", "\r" )
			endfor
	
			for ( r = 0; r < nRows; r += 1 )
				for ( c = 0; c < nCols; c += 1 )
					if ( nFormat == kTBLFILE_TABBED )
						sprintf sItem, "%s\t",	 wt[ r ][ c ]
					else
						sprintf sItem, "%13s ", wt[ r ][ c ]						// values are right justified
					endif
					 printf  "%s%s", sItem, SelectString( c == nCols - 1 , "", "\r" )
					fprintf  nRefNum, "%s%s", sItem, SelectString( c == nCols - 1 , "", "\r" )
				endfor
			endfor
		endif
		Close	nRefNum
		printf "\t\tSaveTblFile_( nAmount:%2d, nWvKind:%2d ) has written '%s'  having %d rows and %d columns. (Format: '%s' ) \r", nAmount, nWvKind, sFilePath, nRows, nCols, SelectString( nFormat, "tabbed" , "spaces(14 chars/column)" )
	endif
End


Function		EraseTbl_( nAmount, nWvKind )
	variable	nAmount		// kLB_SELECT  or  kLB_ALL
	variable	nWvKind 		// kWV_ORG_	  or  kWV_AVG 

// 051111 Route results from original data and from averaged data into different waves, tables and files
	string  	sTblNm	= ResultTableNm_( nAmount, nWvKind )	

	if ( WinType( sTblNm ) == kTABLE )	
		KillWindow $sTblNm
	endif
// 051111 Route results from original data and from averaged data into different waves, tables and files
	wave /T /Z  wt = $ResultWvNm( nAmount, nWvKind )//"root:uf:evo:evl:wR" + num2str( nAmount )
	if ( waveExists( wt ) )
		KillWaves	wt
	endif

	string  /G	$ResultTitles( nAmount, nWvKind )  	= ""		//  glstResultTitles  contains  only the selected titles 
	string  /G	$CombiColsNm( nAmount, nWvKind )	= ""		//  glstCombiCols    contains  the selected titles  plus titles that once were selected but are now not longer selected
End



Function		ConvTbl_( nAmount, nWvKind )
	variable	nAmount			// kLB_SELECT  or  kLB_ALL
	variable	nWvKind 			// kWV_ORG_	  or  kWV_AVG 
	
// 051111 Route results from original data and from averaged data into different waves, tables and files
	variable	c, nCols, r = 0, nRows
	string  	sColNm, sWvNm
	string  	sResultWvNm	= ResultWvNm( nAmount, nWvKind )
	wave  /Z	/T	wt		= $sResultWvNm
	if ( waveExists( wt ) )
		nRows	= DimSize( wt, 0 )	
		nCols	= DimSize( wt, 1 )	
		svar	   	glstCombiCols	=	$CombiColsNm( nAmount, nWvKind )
		for ( c = 0; c < nCols; c += 1 )
			sColNm	= StringFromList( c, glstCombiCols )			// 
			sWvNm	= CleanupName( sColNm, 0 )				// e.g.  'Peak_00/mV'   ->	'Peak_00_mV'
			sWvNm	+= SelectString( nWvKind, "_Org", "_Avg" )	// e.g.  'Peak_00_mV'   ->	'Peak_00_mV_Org'
			printf  "\t\tConvTbl( nAmount:%2d ) \tsColNm:\t%s\tcol:\t%3d\twriting wave: \t%s\thaving %d rows  extracted from '%s' \r", nAmount, pd( sColNm, 16), c, pd( sWvNm, 16), nRows, sResultWvNm					// 

			if ( numType( str2num( wt[ r ][ c ] ) ) == kNUMTYPE_NAN )	// probably a text wave. This will fail if the user has given a number as data file or script file name
				make /T /O /N=(nRows)   	   $"root:" + sWvNm 		// todo. better use klstEVL_IS_STRING  ???
				wave /T		wtTmp	= $"root:" + sWvNm
				for ( r = 0; r < nRows; r += 1 )
					wtTmp[ r ] = wt[ r ][ c ]	
					// printf  "\t\tConvTbl( nAmount:%2d, nWvKind :%2d ) \tsColNm:\t%s\tWv:\t%s\tcol:\t%3d\tr:%2d\t%s \r", nAmount, nWvKind , pd( sColNm, 16), pd( sWvNm, 16), c, r, wtTmp[ r ]					// 
				endfor
			else
				make 	/O /N=(nRows)    $"root:" + sWvNm 
				wave		wTmp	= $"root:" + sWvNm
				for ( r = 0; r < nRows; r += 1 )
					wTmp[ r ] = str2num( wt[ r ][ c ] )	
					// printf  "\t\tConvTbl( nAmount:%2d, nWvKind:%2d ) \tsColNm:\t%s\tWv:\t%s\tcol:\t%3d\tr:%2d\t%g\r", nAmount, nWvKind , pd( sColNm, 16), pd( sWvNm, 16), c, r, wTmp[ r ]					// 
				endfor
			endif
		endfor
		printf "\t\tConvTbl( nAmount:%2d, nWvKind :%2d) has written %d waves  having %d rows  extracted from '%s'   \r", nAmount, nWvKind, nCols, nRows, sResultWvNm
	else
		printf "\t\tConvTbl( nAmount:%2d, nWvKind :%2d) has NOT written any converted waves as  source wave '%s'  does not exist  \r", nAmount, nWvKind, sResultWvNm
	endif
End


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function			FitAllChansAllRegions_()
// Do all fits 
	nvar		gChans	= root:uf:evo:cfsr:gChannels					
	variable	ch
	for ( ch = 0; ch < gChans; ch += 1 )
		variable	rg, nRegs	= RegionCnt( ch )
		string		sFoldOrgWvNm		= GetOnlyOrAnyDataTrace( ch )
		wave	wOrg				= $sFoldOrgWvNm 
		for ( rg = 0; rg < nRegs; rg += 1 )
			AllFitting( wOrg, ch, rg )
		endfor		
	endfor		
End

static Function		AllFitting( wOrg, ch, rg )
	wave	wOrg
	variable	ch, rg
	variable	fi, nFits =  ItemsInList( ksPHASES ) - PH_FIT0
	variable	bSuccessfulFit	= TRUE
	for ( fi = 0; fi < nFits; fi += 1 )
		bSuccessfulFit  *=  OneFit( wOrg, ch, rg, fi )		// one failing fit will set bSuccessfulFit to FALSE
	endfor		
	return	bSuccessfulFit
End

Function		OneFit( wOrg, ch, rg, fi )
	wave	wOrg
	variable	ch, rg, fi
	variable	rLeft, rRight
	string  	sMsg, sTNL
	string		sWndNm		= CfsWndNm( ch )
	variable	bSuccessfulFit	= TRUE											// will return TRUE if fit is off but when it is on and only start values have been checked FALSE will be returned

	variable	bFit	= DoFit( ch, rg, fi )
	if ( bFit )
		variable	nFitFunc	= FitFnc( ch, rg, fi )
		//variable	nFitFunc	= FitFncFromPopup( ch, rg, fi )
		RegionX( ch, rg, fi + PH_FIT0, rLeft, rRight )	//WRONG	include cursor			// get the beginning and the end of the Peak2 evaluation region (=rLeft)
		variable	/G	root:uf:evo:fit:gFitFunc	= nFitFunc							// Igor requires this to be global for 'FitMultipleFunctionsEval()'  but to be used only locally

		nvar			gFitFunc				= root:uf:evo:fit:gFitFunc
		variable		bOnlyStartValsNoFit		= OnlyStartValsNoFit_()					// 0 : do the fit,  1 : display only starting values but do no fitting

		duplicate /O /R=( rLeft, rRight )	wOrg    root:uf:evo:fit:wFitted				// Extract the segment to be fitted. It extends still over the old xLeft..xRight. range.
		duplicate /O /R=( rLeft, rRight )	wOrg    root:uf:evo:fit:wPiece				// Igor requires that wFitted has same length as source wave
		wave		wFitted	= root:uf:evo:fit:wFitted
		wave		wPiece	= root:uf:evo:fit:wPiece
		SetScale /I X, 0,  rRight - rLeft , "", wFitted								// Shift the wave so that it starts at 0. This makes fitting easier. Must be shifted back after fitting...
		SetScale /I X, 0,  rRight - rLeft , "", wPiece
		// printf "\tFitting( left:\t%6.3lf..\t%7.3lf\tch:%d  rg:%d  fi:%d)\tnFitFunc:%d  %s\r", rLeft, rRight, ch, rg, fi, gFitFunc, pd( FitFuncNm( gFitFunc ), 9 )

		variable	nPars			= ParCnt( nFitFunc )
		variable	nFitInfos			= FitInfoCnt()
		string  	sFoInfoNm			= FoInfoNm( ch, rg, fi )
		string  	sFoParNm			= FoParNm( ch, rg, fi )					// the wave name is indexed with channel, region and fit
		string  	sFoStParNm		= FoStParNm( ch, rg, fi )
		string  	sFoDerParNm		= FoDerParNm( ch, rg, fi )
		string  	sFitChanSubFolder	= FitChanSubFolderNm( ch )

		wave	/Z /D  wPar	=  $sFoParNm							// the wave name is indexed with channel, region and fit
		wave	/Z /D  wStartPar= $sFoStParNm							
		wave	/Z /D  wDerPar	=  $sFoDerParNm				
		if ( ! waveExists( wPar )  ||  ! waveExists( wStPar )   ||  ! waveExists( wDerPar ) )
			ConstructAndMakeItCurrentFolder( RemoveEnding( "root:uf:evo" + sFitChanSubFolder, ":" ) )
			make /O  /D /N=( nPars )	$sFoParNm		= 0		
			make /O  /D /N=( nPars )	$sFoStParNm		= nan	
			make /O  /D /N=( nPars )	$sFoDerParNm		= nan	
			make /O 	    /N=(nFitInfos)	$sFoInfoNm		= 0				// to hold   V_FitError, V_FitNumIters, V_FitMaxIters, V_chisq 
		endif
		wave	/D 	wPar	   	= 	$sFoParNm						// the wave name is indexed with channel, region and fit
		wave	/D 	wStartPar	= 	$sFoStParNm				
		wave	/D 	wDerPar	= 	$sFoDerParNm				
		wave	 	wInfo	= 	$sFoInfoNm				


		//  EVAL :   'SetStartParams()' ,  'FuncFit FitMultipleFunctionsEval'  and  'wFitted'  work  with  TRUE TIMES
		bSuccessfulFit	= FALSE														// will also return FALSE if no fit has been done as only start values have been checked
		variable	bStartOK		= SetStartParams( wPar, wPiece, ch, rg, fi, nFitFunc, rLeft, rRight )		// stores results in  wPar
		if ( bStartOK )
			wStartPar	= wPar														// The fit will overwrite  wPar  but  we want to keep the starting values to check how good the initial guesses were.  See  PrintFitResults() below.  
		
			nvar		nMaxIter			= root:uf:evo:de:gFitMaxIter0000
			variable	V_FitMaxIters		= nMaxIter										// used as an indicator whether the fit converged or not
			variable	V_FitNumIters		= 0
			variable	V_FitError			= 0											// do not stop or break into the debugger when fit fails
			variable	V_FitQuitReason
			variable 	V_FitOptions		 = 4											// Bit 2: Suppresses the Curve Fit information window . This may speed things up a bit...

			if ( bOnlyStartValsNoFit )

				FuncFit /O	/N/ Q 	FitMultipleFunctionsEval, wPar, wPiece  /D= wFitted			// display only starting values, do not fit	

			else			
//				nvar		nMaxIter		= root:uf:evo:de:gFitMaxIter0000
//				variable	V_FitMaxIters	= nMaxIter										// used as an indicator whether the fit converged or not
//				variable	V_FitNumIters	= 0
//				variable	V_FitError		= 0											// do not stop or break into the debugger when fit fails
//				variable	V_FitQuitReason
	
				FuncFit /N /Q /W=1 FitMultipleFunctionsEval, wPar, wPiece  /D= wFitted 			// do the fitting

				bSuccessfulFit	= FittingWasSuccessful_( V_FitError, V_FitNumIters, V_FitMaxIters )
				if ( bSuccessfulFit )
					ComputeDerivedParams( wPar, wDerPar, ch, rg, fi, nFitFunc )
				else
					// Design issue: keep the fitted values even if the fit failed (they may be close to the optimum values but can also be completely false)   OR  discard them by setting them to  Nan
					ResetFitResult_( ch, rg, fi ) 	// set the fitted values to  Nan  if the fit failed for any reason (even if the values may be acceptable)
					sprintf sMsg, "\tFit failed : ch:%2d,  rg:%2d,  fit:%2d,  Iterations: %d / %d ,\tV_FitError:%d,  V_FitQuitReason:%d [Bit0..3:Any error,SingMat,OutOfMem,NanOrInf]", ch, rg, fi, V_FitNumIters, V_FitMaxIters, V_FitError, V_FitQuitReason	
					Alert( kERR_IMPORTANT,  sMsg )
				endif
			endif
			if ( bOnlyStartValsNoFit  ||  bSuccessfulFit )

				string  	sFittedRangeNm	= "wF_r" + num2str( rg ) + "_p" + num2str( fi + PH_FIT0 ) 
				string		sFoFittedRangeNm	= "root:uf:evo" + sFitChanSubFolder + sFittedRangeNm	// Make new wave e.g. 'fit:c1:wF0_r1_p0'   and fill it with an extracted segment
				wave	/Z	wF			= $sFoFittedRangeNm
				if ( ! waveExists( wF ) )
					ConstructAndMakeItCurrentFolder( RemoveEnding( "root:uf:evo" + sFitChanSubFolder, ":" ) )
				endif
				duplicate /O 		wFitted	$sFoFittedRangeNm								//..(=the fitted range) of the fitted wave. In the new wave the fitted range starts with point 0 . 
				SetScale /I X, rLeft,  rRight , "",  $sFoFittedRangeNm								// Shift the wave back so that it starts again at  'rLeft'

				variable	rRed, rGreen, rBlue
				EvalRegionColor( ch, rg,  fi + PH_FIT0, rRed, rGreen, rBlue )
				if ( WinType( sWndNm ) == kGRAPH ) 										// the user may have killed the window
					sTNL	= TraceNameList( sWndNm, ";", 1 )
					if ( WhichListItem( sFittedRangeNm, sTNL, ";" )  == kNOTFOUND )				// ONLY if  wave is not in graph...
						AppendToGraph /W=$sWndNm	 /C=( rRed, rGreen, rBlue )	$sFoFittedRangeNm
					endif
				endif
			endif
			// Display  /K=1 wFitted, wPiece
		endif
		SetFitInfo( wInfo, nFitFunc, rLeft, rRight, V_FitNumIters, V_FitMaxIters, V_chisq )
		sMsg	= PrintFitResultsIntoHistory( wInfo, ch, rg, fi, nFitFunc, bStartOK, V_FitError )
		if ( strlen( sMsg ) )
			printf "%s \r" , sMsg
		endif
		// SetRegionY( ch, rg, ph, (wMnMx[ch][ MM_YMIN ] + wMnMx[ch][ MM_YMAX ] ) / 2, (wMnMx[ch][ MM_YMIN ] + wMnMx[ch][ MM_YMAX ] ) / 2 )	// set the region in the middle

	endif			// fit checkbox 
	return	bSuccessfulFit
End		// OneFit


Function		FittingWasSuccessful_( FitError, FitNumIters, FitMaxIters ) 
	variable	FitError, FitNumIters, FitMaxIters
	return	FitError == 0   &&  FitNumIters < FitMaxIters
End

Function		ResetFitResults( ch ) 	
	variable	ch
	variable	rg, nRegs	= RegionCnt( ch )
	for ( rg = 0; rg < nRegs; rg += 1 )
		variable	fi, nFits =  ItemsInList( ksPHASES ) - PH_FIT0
		for ( fi = 0; fi < nFits; fi += 1 )
			ResetFitResult_( ch, rg, fi ) 	
		endfor		
	endfor		
End		

Function		ResetFitResult_( ch, rg, fi ) 	
	variable	ch, rg, fi
	wave	/Z /D  wStartPar= $FoStParNm( ch, rg, fi )
	wave	/Z /D  wDerPar	=  $FoDerParNm( ch, rg, fi )
	wave	/Z /D  wPar	=  $FoParNm( ch, rg, fi )
	wave	/Z /D  wInfo	=  $FoInfoNm( ch, rg, fi )
	if ( waveExists( wPar ) )
		wPar = Nan
	endif
	 if ( waveExists( wStartPar ) )
		wStartPar = Nan
	endif
	 if ( waveExists( wDerPar ) )
		wStartPar = Nan
	endif
	 if ( waveExists( wInfo ) )
		wInfo = Nan
	endif
End

//-------------------------------------------  Access functions  ------------------------------------------------------------

Function		FitInfo( ch, rg, fi, par )
// similar: FitFnc()
	variable	ch, rg, fi, par 
	string  	sFoInfoNm		= FoInfoNm( ch, rg, fi )
	wave	/D 	wInfo   	= $sFoInfoNm		
	return	wInfo[ par ]
End	

Function		FitPar( ch, rg, fi, par )
	variable	ch, rg, fi, par 
	string  	sFoParNm		= FoParNm( ch, rg, fi )
	wave	/D 	wPar	   	= $sFoParNm		
	return	wPar[ par ]
End	

// 051007 currently not used
Function		FitParIsValid( ch, rg, fi, par )
	variable	ch, rg, fi, par 
	string  	sFoParNm		= FoParNm( ch, rg, fi )
	wave	/D 	wPar	   	= $sFoParNm		
	return	numtype( wPar[ par ] ) != kNUMTYPE_NAN
End	

Function		FitStPar( ch, rg, fi, par )
	variable	ch, rg, fi, par 
	string  	sFoStParNm	= FoStParNm( ch, rg, fi )
	wave	/D 	wStPar   	= $sFoStParNm		
	return	wStPar[ par ]
End	

Function		FitDerivedPar( ch, rg, fi, par )
	variable	ch, rg, fi, par 
	string  	sFoDerParNm	= FoDerParNm( ch, rg, fi )
	wave	/D 	wDerPar   	= $sFoDerParNm		
	return	wDerPar[ par ]
End	

//-----------------------------------------------  Naming convention  -------------------------------------------------------
static Function	/S		FitChanSubFolderNm( ch )
	variable	ch
	return	":fit:" + "c" + num2str( ch ) + ":" 	// e.g  ':fit:c1:'
End

Function	/S		FoParNm( ch, rg, fi )
	variable	ch, rg, fi					// fi = 0,1,2...
	string  	sParNm		= "wPar_r" + num2str( rg ) + "_p" + num2str( fi + PH_FIT0 ) 
	return	"root:uf:evo" + FitChanSubFolderNm( ch ) + sParNm
End

Function	/S		FoStParNm( ch, rg, fi )
	variable	ch, rg, fi					// fi = 0,1,2...
	string  	sStParNm		= "wStPar_r" + num2str( rg ) + "_p" + num2str( fi + PH_FIT0 ) 
	return	"root:uf:evo" + FitChanSubFolderNm( ch ) + sStParNm
End

static Function	/S		FoDerParNm( ch, rg, fi )
	variable	ch, rg, fi					// fi = 0,1,2...
	string  	sDerParNm		= "wDerPar_r" + num2str( rg ) + "_p" + num2str( fi + PH_FIT0 ) 
	return	"root:uf:evo" + FitChanSubFolderNm( ch ) + sDerParNm
End

static Function	/S		FoInfoNm( ch, rg, fi )
	variable	ch, rg, fi					// fi = 0,1,2...
	string  	sInfoNm		= "wInfo_r" + num2str( rg ) + "_p" + num2str( fi + PH_FIT0 ) 
	return	"root:uf:evo" + FitChanSubFolderNm( ch ) + sInfoNm
End

//--------------------------------------------------------------------------------------------------------------------------------

//constant kpA = 1e-12

static Function	/S	PrintFitResultsIntoHistory( wInfo, ch, rg, fi, nFitFunc, bStartOK, nFitError )
	wave	wInfo		// possible todo: eliminate wInfo  by using access functions just like for par, stpar, derivedpar
	variable	ch, rg, fi, nFitFunc, bStartOK, nFitError
	nvar		gPrintMask= root:uf:evo:evl:gprintMask
	string		sLine	= ""
	if ( gPrintMask &  RP_FIT )
		string		sUnit, sUnitAu, sMsg, sFitAndStartPars = ""
		variable	n,  Magnitude

		for ( n = 0; n < ParCnt( nFitFunc ); n += 1 )
			sUnit		= AutoUnit( ParUnit( nFitFunc, n ) , ch ) 				// e.g. 'mV'  or  'pA'   but  no longer 'au'  (=automatic)  which has been converted to a real unit 
			Magnitude	= MagnitPar( nFitFunc, n, ch )
			// printf "\t\tPrintFitResultsIntoHistory  FitPar    \tch:%2d\tn:%2d  \tsUnit:'%s'   \t -> '%s'\tMagnitude:%g  \r",  ch, n, ParUnit( nFitFunc, n ), sUnit,  Magnitude
			if ( gPrintMask &  RP_FITSTART )
				sFitAndStartPars   += ParName( nFitFunc, n ) + ": " + num2str( FitPar( ch, rg, fi, n ) /  Magnitude ) + " (" + num2str( FitStPar( ch, rg, fi, n )  /  Magnitude ) + ")" + sUnit + "   "
			else
				sFitAndStartPars   += ParName( nFitFunc, n ) + ": " + num2str( FitPar( ch, rg, fi, n )  /  Magnitude ) + sUnit + "   "
			endif
		endfor

		for ( n = 0; n < DerivedCnt( nFitFunc ); n += 1 )
			sUnit		= AutoUnit( DerUnit( nFitFunc, n ), ch ) 
			Magnitude	= MagnitDer( nFitFunc, n , ch )
			// printf "\t\tPrintFitResultsIntoHistory  Derived  \tch:%2d\tn:%2d  \tsUnit:'%s'   \t -> '%s'\tMagnitude:%g  \r",  ch, n, DerUnit( nFitFunc, n ), sUnit,  Magnitude
			sFitAndStartPars   += DerName( nFitFunc, n ) + ": " + num2str( FitDerivedPar( ch, rg, fi, n )  /  Magnitude ) + sUnit + "   "
		endfor

		if ( ! bStartOK )
			sMsg			 = "Fit failed as no start parameters could be found."
			sFitAndStartPars = ""
		elseif ( FitInfoNIter( wInfo ) == 0 )													// show start values, do not fit
			sprintf	sMsg, "No fit, start values : " 
		elseif ( FitInfoNIter( wInfo ) == FitInfoMaxIter( wInfo )   ||   nFitError  )
			sprintf	sMsg, "It:%2d/%3d\t*** Failed ***" ,FitInfoNIter( wInfo ),  FitInfoMaxIter( wInfo )		
		else
			sprintf	sMsg, "It:%2d/%3d\tChi:%8.2g" ,  FitInfoNIter( wInfo ),  FitInfoMaxIter( wInfo ),  FitInfoChiSqr( wInfo )
		endif

		sprintf sLine, "ch:%d  rg:%d  %s\t%s\t%s\t  %s ", ch, rg, StringFromList( fi + PH_FIT0, ksPHASES), pd( FitFuncNm_( nFitFunc ), 9), sMsg, sFitAndStartPars	// print the fitted and the starting values in one line
	endif
	return	sLine
End

Function		MagnitPar( nFitFunc, n, ch )
	variable	nFitFunc, n, ch
	string  	sUnit		= AutoUnit( ParUnit( nFitFunc, n ) , ch ) 	// e.g. 'mV'  or  'pA'   but  no longer 'au'  (=automatic)  which has been converted to a real unit 
	variable	Magnitude	= MagnAuto( sUnit )
	return	Magnitude
End

Function		MagnitDer( nFitFunc, n, ch )
	variable	nFitFunc, n, ch
	string  	sUnit		= AutoUnit( DerUnit( nFitFunc, n ) , ch ) 	// e.g. 'mV'  or  'pA'   but  no longer 'au'  (=automatic)  which has been converted to a real unit 
	variable	Magnitude	= MagnAuto( sUnit )
	return	Magnitude
End

Function		MagnAuto( sUnit )
// Converts	'au'  (=automatic unit)  into a real unit  'mV'  or  'pA' 
	string  	sUnit
	variable	Magnitude	= Magn( sUnit )

	// This is needed as the whole program uses  'pA'  or  'mV'  as basic units.  Can be eliminated if the program is revamped to use  'A'  and  'V'  instead.
	// ANY parameter measured in  Volt  or  Ampere  must be converted wirh these constants.
	if ( ( strlen( sUnit ) == 1  &&  char2num( sUnit )  == char2num( "A" ) )  ||  ( strlen( sUnit ) == 2  &&  char2num( sUnit [1,1] )  == char2num( "A" ) ) )	
		Magnitude *= 1e12					// compensate as  'pA'  is used as basic unit  (not good...)
	endif
	if ( ( strlen( sUnit ) == 1  &&  char2num( sUnit )  == char2num( "V" ) )  ||  ( strlen( sUnit ) == 2  &&  char2num( sUnit [1,1] )  == char2num( "V" ) ) )	
		Magnitude *= 1e3					// compensate as  'mV'  is used as basic unit  (not good...)
	endif
	
	return	Magnitude
End

Function		Magn( sUnit )
// Computes magnitude  from unit e.g. 'mV' -> 1e-3  ,  'MOhm' -> 1e6 
	string  	sUnit
	if ( strlen( sUnit ) <= 1 )			// no unit or no unit prefix  e.g.  'V'  or empty string
		return	1
	endif
	switch	( char2num( sUnit[ 0, 0 ] ) )	// must be case-sensitive  'm' != 'M'  (strswitch is not case-sensitive  'm' = 'M')	
		case	 	97 :			// "a" :
			return	1e-18
		case	 	102 :			// "f" :
			return	1e-15
		case	 	112 :			// "p" :
			return	1e-12
		case	 	110 :			// "n" :
			return	1e-9
		case	 	117 :			// "u" :			// todo  the real  mü
			return	1e-6
		case	 	109 :			// "m" :
			return	1e-3
		case	 	107 :			// "k" :
			return	1e3
		case	 	77 :			// "M" :
			return	1e6
		case	 	71 :			// "G" :
			return	1e9
		case	 	84 :			// "T" :
			return	1e12
		default :	 	
			return	1
	endswitch
End

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//  LATENCIES

Function	AllLatenciesCheck()
 // Check that the user makes only legal  selections in the popmenu (can only define the beginning or the end of a latency cursor once!)
// Todo: TurnRemainingLatenciesOff()  : If 1 latency option( lc, begEnd ) is is turned on, disable  those with the same (lc, begEnd)   in all other channels and regions. This automatically prevents the user error defining a latency twice.
// Todo: Possibly check for same setting beg = end (trivial and obvious case resulting in value 0)
 	nvar		gChannels	= root:uf:evo:cfsr:gChannels
	variable	BegEnd, lc, LatCnt	= LatencyCnt()
	variable	ch, rg, rgCnt, nLatOp, nFoundDoubleEntry	 = 0
	string  	sTxt
	make  /O	/I  /N=( LatCnt, 2 )  wLatCheckDoubleEntry = 0
	for ( lc = 0; lc < LatCnt; lc += 1 )
		for ( BegEnd= CN_BEG; BegEnd <=  CN_END; BegEnd += 1 )
			for ( ch = 0; ch < gChannels; ch += 1)
				rgCnt	= RegionCnt( ch )
				for ( rg = 0; rg < rgCnt;  rg += 1 )	
					nLatOp	= LatC( ch, rg, lc, BegEnd )
					if ( nLatOp != kLAT_OFF_ )
						wLatCheckDoubleEntry[ lc ][ BegEnd ] += 1
						if ( wLatCheckDoubleEntry[ lc ][ BegEnd ]  > 1 )
							sprintf sTxt, "The %s of latency %d is defined multiple times.", SelectString( BegEnd, "beginning" , "end" ), lc 
							Alert( kERR_IMPORTANT, sTxt )
							nFoundDoubleEntry += 1
						endif						
						// printf "\t\tAllLatenciesCheck() \tl:%d/%d\t   BegEnd:%d   ch:%d   rg:%d\t%s Latc:%2d\t(%s)   \r", lc, LatCnt, BegEnd, ch, rg,  SelectString( BegEnd, "beg: " , "\t\t\t\t -> end: " ), nLatOp, StringFromList( nLatOp, klstLATC )
					endif
				endfor
			endfor
		endfor
	endfor
	if ( nFoundDoubleEntry == 0 )	// if  we had the above error (=double entries) we do not want to report this error again
		for ( lc = 0; lc < LatCnt; lc += 1 )
			variable	bMissing =  wLatCheckDoubleEntry[ lc ][ CN_BEG ]  - wLatCheckDoubleEntry[ lc ][ CN_END ] 	// should be 1-1 = 0
			if ( bMissing )		
				sprintf sTxt, "The %s of latency %d is missing while the %s is defined.", SelectString( bMissing, "beginning" , "", "end" ),  lc, SelectString( -bMissing, "beginning" , "", "end" ) 
				Alert( kERR_IMPORTANT, sTxt )
			endif
		endfor
	endif
	killWaves  wLatCheckDoubleEntry
End

// W W W W  W  W  W  W d   should be Ohm

 Function		AllLatencies()
// Compute latencies from the settings of all channnels and regions and store them in a global list (L0,L1,L2) to make them easily accessible from now on.
	nvar		gChannels	= root:uf:evo:cfsr:gChannels
	variable	BegEnd, lc, LatCnt	= LatencyCnt()
	variable	ch, rg, rgCnt, nLatOp	
	string  	sLatNm, sLatOp
	variable	Val, ValB, ValE, LatVal
	AllLatenciesCheck()										// the error has already been reported earlier during input, but the user may have ignored or missed it, so we remind again
	for ( lc = 0; lc < LatCnt; lc += 1 )
		sLatNm = ""
		for ( BegEnd = CN_BEG; BegEnd <=  CN_END; BegEnd += 1 )
			for ( ch = 0; ch < gChannels; ch += 1)
				rgCnt	= RegionCnt( ch )
				for ( rg = 0; rg < rgCnt;  rg += 1 )	
					nLatOp	= LatC( ch, rg, lc, BegEnd )
					sLatOp	= StringFromList( nLatOp, klstLATC_ )

					if ( nLatOp != kLAT_OFF_ )

						if ( nLatOp == kLAT_MANUAL_ )
							Val	= RegionBegEnd( ch, rg, PH_LATC0 + lc, BegEnd )
						elseif ( nLatOp == kLAT_BR_ )
							Val	= EvT( ch, rg, kE_BRISE )
						elseif ( nLatOp == kLAT_RT5_ )
							Val	= EvT( ch, rg, kE_RISE50 )
						elseif ( nLatOp == kLAT_PK_ )
							Val	= EvT( ch, rg, kE_PEAK )
						elseif ( nLatOp == kLAT_DT5_ )
							Val	= EvT( ch, rg, kE_DEC50 )
// 060109 Latency RiseSlp
						elseif ( nLatOp == kLAT_RSLP_ )
							Val	= EvT( ch, rg, kE_RISSLP )
						endif	
				
						if ( BegEnd == CN_BEG )
							ValB	  = Val
							LatVal = 0
						else
							ValE   = Val
							LatVal = ValE - ValB
							SetLatValue( lc, LatVal )		
						endif

						sLatNm	+= LatNm( lc, BegEnd, ch, rg )			// e.g. 'Lat0m00m00'  or  'Lat1P01R22' 
						//printf "\t\tAllLatencies() \tl:%d/%d\t   BegEnd:%d   ch:%d   rg:%d\t%s Latc:%2d\t(%s)   \r", lc, LatCnt, BegEnd, ch, rg,  SelectString( BegEnd, "beg: " , "\t\t\t\t -> end: " ), nLatOp, StringFromList( nLatOp, klstLATC )
						// printf "\t\tAllLatencies() \tl:%d/%d\t   BegEnd:%d   ch:%d   rg:%d\t%s\tLatOp:%2d\t(%s) \tLatNm:%s\tVal:%g\tLatVal:%g  \r", lc, LatCnt, BegEnd, ch, rg,  SelectString( BegEnd, "Beg:    " , "  -> End:" ), nLatOp, sLatOp, pd(sLatNm,12), Val, LatVal
					endif

				endfor
			endfor
		endfor
	endfor
End

//  NOT  YET WORKING
// Function		TurnRemainingLatenciesOff( sThisCtrlNm, nThisLat, nThisBegEnd, nThisCh, nThisRg )
//// Two advantages: 1. Prevent that the user accidentally redefines this latency in another channer or region.  2. Tidy up the panel. 
////..BUT does not work as all hidden popmenus are restored whenever tabs are clicked. -> must recognise hidden state then
//	string  	sThisCtrlNm
//	variable	nThisLat, nThisBegEnd, nThisCh, nThisRg
//	nvar		gChannels	= root:uf:evo:cfsr:gChannels
//	variable	LatCnt	= LatencyCnt()
//	variable	ch, rg, rgCnt, len = strlen( sThisCtrlNm )
//	string  	sCtrlBaseNm	= sThisCtrlNm[ 0, len - 7 ]
//	string  	sctrlName
//	variable	nLatOp	= LatC( nThisCh, nThisRg,  nThisLat, nThisBegEnd )
//	for ( ch = 0; ch < gChannels; ch += 1)
//		rgCnt	= RegionCnt( ch )
//		for ( rg = 0; rg < rgCnt;  rg += 1 )	
//			sctrlName	= sCtrlBaseNm + num2str( nThisLat ) + num2str( nThisBegEnd ) + num2str( ch ) + num2str( rg ) + "00"
//
//			if ( ch == nThisCh  &&  rg == nThisRg )
//				 printf "\t\tTurnRemainingLatenciesOff( ON a )\tThisLat:%d/%d\t   ThisBegEnd:%d   ch:%d   rg:%d\tThisCNm:%s   OtherCNm:%s   \r", nThisLat, LatCnt, nThisBegEnd, ch, rg, sThisCtrlNm, sctrlName
//			else
//				if ( nLatOp != kLAT_OFF )
//					 printf "\t\tTurnRemainingLatenciesOff( OFF )\tThisLat:%d/%d\t   ThisBegEnd:%d   ch:%d   rg:%d\tThisCNm:%s   OtherCNm:%s   \r", nThisLat, LatCnt, nThisBegEnd, ch, rg, sThisCtrlNm, sctrlName
//					PopupMenu	$sctrlName disable = 1		// normal:0,  hide:1,  grey:2
//				else
//					 printf "\t\tTurnRemainingLatenciesOff( ON b )\tThisLat:%d/%d\t   ThisBegEnd:%d   ch:%d   rg:%d\tThisCNm:%s   OtherCNm:%s   \r", nThisLat, LatCnt, nThisBegEnd, ch, rg, sThisCtrlNm, sctrlName
//					PopupMenu	$sctrlName disable = 0		// normal:0,  hide:1,  grey:2
//				endif
//			endif
//		endfor
//	endfor
//End


////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//   BIG   HELPERS

static Function	EvaluateMeanAndSDev( wWave, ch, rg ) 
	wave	wWave
	variable	ch, rg
	WaveStats /Q  wWave					// First get wave average and deviation in the given time interval 
	// printf "\t\tEvaluateMeanAndSDev() \t\tch:%2d  rg:%2d \tpts:%8d\t Mean: %g  sDev:%g \r", ch, rg, numpnts( wWave), V_avg, V_sdev
	SetEval( ch, rg, kE_MEAN, kY,		V_avg )		
	SetEval( ch, rg, kE_MEAN, kVAL,	V_avg )
	SetEval( ch, rg, kE_SDEV, kY,		V_sdev )		
	SetEval( ch, rg, kE_SDEV, kVAL,	V_sdev )
End

static Function		AutomaticBaseRegion( wWave, ch, rg, BaseL, BaseR, rBaseT, rBaseB )
// guess the allowed baseline band from the noise in the given interval[ BaseL, BaseR ]
	wave	wWave
	variable	ch, rg, BaseL, BaseR, &rBaseT, &rBaseB
	variable	HalfWidth, MinMaxY, Average
	WaveStats /Q  /R=( BaseL, BaseR ) wWave					// First get wave average and deviation in the given time interval 
	Average	= V_avg
	HalfWidth	= V_sdev	* 1									// arbitrarily assume a band based on the noise level found in the interval
	wave	wMnMx	= root:uf:evo:evl:wMnMx					// But when there is little or no noise the band is too small and must be widened...
	MinMaxY	= wMnMx[ ch ][ MM_YMAX ] - wMnMx[ ch ][ MM_YMIN ]	// TODO  Arbitrarily assume a band based on the minimum and maximum of complete wave...  
	HalfWidth	= max( HalfWidth, MinMaxY * .02 )					// ...which is wrong as it does not take into account whether there is a synaptic event or not.....
	// printf "\t\tAutomaticBaseRegion() \tBaseL:%5.1lf, BaseR:%5.1lf, ch:%d, MinMaxY:%5.1lf , HalfWidth:%5.1lf, Average:%5.1lf \r", BaseL, BaseR, ch, MinMaxY, HalfWidth, Average
	rBaseT	= Average + HalfWidth
	rBaseB	= Average  - HalfWidth 
End

static Function		EvaluateBase( wWave, ch, rg, XaxisLeft, bDoNoiseCheck )									
//	get the BASE value when time range is given. Check if base is too noisy and mark this record
// to do : more nSECTIONS -> more tests -> then allow 1 or 2 failures
//todo let slope also store BASE NOISE????
	wave	wWave
	variable	ch, rg, XaxisLeft, bDoNoiseCheck		
	nvar		gPrintMask= root:uf:evo:evl:gprintMask
	string		sMsg
	variable	AvgValue		= 0 
	variable	SDevValue	= 0 
	variable	LocBaseBeg, LocBaseEnd, BandAvgHi, BandAvgLo
	RegionX( ch, rg, PH_BASE, LocBaseBeg, LocBaseEnd )				// get the time range in which to evaluate the base 
	RegionY( ch, rg, PH_BASE, BandAvgHi, BandAvgLo )					// get the allowed band

	if ( bDoNoiseCheck )
	// todo : there could be rounding errors if   'pts / kBASE_SLICES'  leaves a remainder   AND  check the inclusion/exclusion of thr last point  
		variable	dltax		= deltax( wWave ) 						// in seconds
		variable	n, pts	= ( LocBaseEnd - LocBaseBeg ) / dltax - 1		// one point less because the last point may already be in the artefact
		variable	nSlicePts	= trunc ( pts / kBASE_SLICES )
		variable	DurSlice	= nSlicePts * dltax
		variable	bTooNoisy		= 0
		for ( n = 0; n < kBASE_SLICES; n += 1 )
			// Error occurs with empty channels (PATCH600!) . WavStats  error is mixed up with  FindLevel  error  .....
			WaveStats /Q  /R=( LocBaseBeg + n * DurSlice, LocBaseBeg + ( n + 1 ) * DurSlice ) wWave		// Measure average and standard deviation of every slice...
			if ( GetRTError(0) )
				print "****Internal warning : EvaluateBase() : " + GetRTErrMessage()
				variable dummy = GetRTError(1)
			endif
			if ( V_avg  < BandAvgLo	||   BandAvgHi < V_avg )									// ...and check if average is within narrow average band
				bTooNoisy	 += 1
				sprintf sMsg, "In  ch:%d  baseline slice %d of %d \t(Dur %6.2lf ..%6.2lfms) \tthe average %.2lf \tis out of allowed avg band %.1lf ... %.1lf ", ch, n, kBASE_SLICES, n * DurSlice*1000,  ( n + 1 ) * DurSlice*1000,  V_avg , BandAvgLo, BandAvgHi
				Alert( kERR_LESS_IMPORTANT,  sMsg )
			endif		
			AvgValue	 = ( n * AvgValue   + V_avg   ) / ( n + 1 )		
			sDevValue = ( n * sDevValue + V_sdev ) / ( n + 1 )		
			// printf "\t\tEvaluateBase %3d/%3d\tDur %6.2lf ..%6.2lfms\tPts:%4d\tAvg:%4.0lf\tDev:%4.1lf\trms:%4.0lf\tmiL:%4.0lf\tmi:%4.0lf\tmxL%4.0lf\tmx:%4.0lf\tdlt:%4.0lf\t->Avg:%4.0lf \r", n, kBASE_SLICES, n * DurSlice*1000,  ( n + 1 ) * DurSlice*1000,  V_npnts,  V_avg , V_sdev, V_rms ,V_minloc,  V_min, V_maxloc, V_max , V_max-V_min, AvgValue 
		endfor
		// 051013 why is this executed again?
		for ( n = 0; n < kBASE_SLICES; n += 1 )
			if ( V_avg  < BandAvgLo	||   BandAvgHi < V_avg )	// check if average is within narrow average band
				bTooNoisy	 += 1
				sprintf sMsg, "In  ch:%d  baseline slice %d of %d \t(Dur %6.2lf ..%6.2lfms) \tthe average %.2lf \tis out of allowed avg band %.1lf ... %.1lf ", ch, n, kBASE_SLICES, n * DurSlice*1000,  ( n + 1 ) * DurSlice*1000,  V_avg , BandAvgLo, BandAvgHi
				Alert( kERR_LESS_IMPORTANT,  sMsg )
			endif		
		endfor
	else
		WaveStats /Q  /R=( LocBaseBeg, LocBaseEnd ) wWave		// Measure average and standard deviation of the entire base region
		AvgValue	 = V_avg
		sDevValue = V_sdev
	endif
// 050813 todo clarify BAS1, BAS2 and BASE   ,   set BASE right here
	SetEval( ch, rg, kE_BAS1, kT,		LocBaseBeg )
	SetEval( ch, rg, kE_BAS1, kY,		AvgValue )		
	SetEval( ch, rg, kE_BAS1, kVAL,	AvgValue )
	SetEval( ch, rg, kE_BAS2, kT,		LocBaseEnd )
	SetEval( ch, rg, kE_BAS2, kY,		AvgValue )
	SetEval( ch, rg, kE_BAS2, kVAL,	AvgValue )
	SetEval( ch, rg, kE_BASE, kTB,		LocBaseBeg )	
	SetEval( ch, rg, kE_BASE, kTE,		LocBaseEnd )
	SetEval( ch, rg, kE_BASE, kY,		AvgValue )	
	SetEval( ch, rg, kE_BASE, kVAL,	AvgValue )				// Version1: the base value is the value of the trailing base segment (which is right before the peak) 
	SetEval( ch, rg, kE_SDBASE, kY,	SDevValue )	
	SetEval( ch, rg, kE_SDBASE, kVAL,	SDevValue )	
	if ( gPrintMask &  RP_BASEPEAK1 )
		if ( bTooNoisy ) 
			printf "\t\t\tEvaluateBase(%d)\t**** Base region evaluated in %d slices from %6.2lf ..%6.2lfms :\t TOO NOISY, discard record. [ Failed %d of %d tests ] \r", ch, kBASE_SLICES, LocBaseBeg-XaxisLeft, LocBaseEnd-XaxisLeft, bTooNoisy, 2 * kBASE_SLICES
		else
			printf "\t\t\tEvaluateBase(%d)\tBase region evaluated  in %d slices from %6.2lf ..%6.2lfms :\t OK \t\tBaseline value: %.1lf \r", ch, kBASE_SLICES, LocBaseBeg-XaxisLeft, LocBaseEnd-XaxisLeft, AvgValue
		endif
	endif
End



static	 Function	EvaluatePeak( wWave, ch, rg, nRgType, Beg, Ende ) 	
// Peak direction is initially known (passed as parameter)
// todo : value is OK, but time of sharp peak (=PEAK2) is not determined correctly (1/4 point late)  even if side points = 0.  Better wavestats????? (needs endloc!!)
	wave	wWave
	variable	ch, rg, nRgType, Beg, Ende
	variable	nSidePts		= PeakSidePts( ch, rg )									// additional points on each side of a peak averaged to reduce noise errors 
	nvar		gPrintMask	= root:uf:evo:evl:gprintMask
	variable	PreciseLoc, PreciseValue 			
	string		sMsg
	variable	dltax			= deltax( wWave ) 						// in seconds
	variable	nSmoothPts	= nSidePts * 2 + 1
	variable	nPeakDir	 	= PeakDir( ch, rg ) 

	// First find the absolute extremum, then smooth 'nSidePts' around this point to refine the values by reducing noise influence . 'nSidePts' is CRITICAL !
	// Problem 1 : if  'nSidePts'  is too small  and  if  peak is symmetric and noisy	:  Error: noise peaks are returned  instead of the correct smoothed values
	// Problem 2 : if  'nSidePts'  is too large  and  if  peak is asymmetric		:  Error: averaged (=too low and shifted) peak is returned  instead of the correct one-point-peak
	// string		sTmpWvNm = "wPeak" + num2str( ch )				// wPeak0, wPeak1, ...-
	string			sTmpWvNm =  "root:uf:evo:evl:" + "wPeak" + num2str( ch )		// wPeak0, wPeak1, ...-
	duplicate /O 	/R=( 	Beg, Ende ) wWave  $sTmpWvNm				// () in the wave units , here in seconds
	wave		wSmoothedPeak = $sTmpWvNm

	//AppendToGraph 				/Q /C=(0,15000, 65000) wSmoothedPeak	// Peaks are blue  

	//AppendToGraph 	/W=$sWndNm	/Q /C=(65000,15000, 65000) wSmoothedRiseDecay	// slopes are magenta  
	// the evaluation interval set by user may be too short for smoothing  or  it may lie after the sweep end (then having 0 points)
	variable	IntervalDuration	= min ( numPnts(wSmoothedPeak) * dltaX ,  Ende - Beg )
	// printf "\t\t\tEvaluatePeak( ch:%2d, rg:%2d )\tPk %1d\t%s     \tBeg:%5.3lfs, End:%5.3lfs  End - Beg:%5.3lfs  ?>?  nSmoothPts*dltax:%6.4lfs   AND  nPnts:%d ?>=? nSmoothPts:%d  [deltax:%.3lfms IntDur:%gms]\r", ch, rg, nRgType, PeakDirStr( nPeakDir ), Beg, Ende, Ende - Beg, nSmoothPts * dltax, numPnts(wSmoothedPeak), nSmoothPts , dltax*1000, IntervalDuration*1000
	if ( IntervalDuration <= nSmoothPts * dltaX )
		sprintf sMsg, "Chan:%d, region:%d : Interval for evaluation of  peak lies outside the sweep  or  is too short (%.2lfms) . Minimum duration needed is %d * %.3lfms. ", ch, rg,  IntervalDuration*1000, nSmoothPts , dltax*1000 
		Alert( kERR_LESS_IMPORTANT,  sMsg )
	else  
		Smooth		/B ( nSmoothPts ),	wSmoothedPeak
		WaveStats	/Q	wSmoothedPeak
		//WaveStats	/Q /R=( msBeg, msEnd )  wWave
		PreciseValue	= nPeakDir == kPEAK_UP_  ?  V_max 	:  ( nPeakDir == kPEAK_DOWN_  ?  V_min	:  nan )	
		PreciseLoc	= nPeakDir == kPEAK_UP_  ?  V_maxloc  	:  ( nPeakDir == kPEAK_DOWN_  ?  V_minloc  :  nan )	
	endif
	// Problem 1 : May erroneously find local peak when using a too large range and too few nSidePts
	// Problem 2 : May erroneously shift the correctly found global peak when peak is asymmetric and when using too many nSidePts
	//	if ( bPeakIsUp )
	//		FindPeak /Q /B=(addedPts)  	/R = ( Beg, Ende )  wWave
	//	else
	//		FindPeak /Q /B=(addedPts)  /N /R = ( Beg, Ende )  wWave
	//	endif
	//	//string	sText		= SelectString( bPeakIsUp, "Minimum", "Maximum" )	// list order is 'down;up;'
	//	string		sText		= SelectString( bPeakIsUp, "Maximum", "Minimum" )	// list order is 'up;down;;'
	//	if ( V_flag )
	//		sprintf sMsg, "%s not found . Search started at %.4lfs (increasing time) .", sText, Beg
	//		Alert( kERR_LESS_IMPORTANT,  sMsg )
	//	else
	//		PreciseLoc	= V_peakLoc
	//		PreciseValue	= V_peakVal
	//	endif
	SetEval( ch, rg, kE_PEAK, kT, PreciseLoc )
	SetEval( ch, rg, kE_PEAK, kY, PreciseValue )
	SetEval( ch, rg, kE_PEAK, kTB, Beg )
	SetEval( ch, rg, kE_PEAK, kTE, Ende )
	// printf "\t\t\tEvaluatePeak(ch:%2d  rg:%2d )\tPk %1d\t%s     \tRange %.4lf to %.4lfs.\tLoc:%6.2lf \tPrecVal(avg over %d pts * %.3lfms = %.3lf ms) : %6.2lf\r", ch, rg, nRgType, PeakDirStr( nPeakDir ), Beg, Ende, PreciseLoc, nSmoothPts, dltax*1000, (nSmoothPts-1)*dltax*1000, PreciseValue
	if ( gPrintMask &  RP_BASEPEAK1 )
		printf "\t\t\tEvaluatePeak(ch:%2d  rg:%2d )\tPk %1d\t%s     \tRange %.4lf to %.4lfs.\tLoc:%6.2lf \tPrecVal(avg over %d pts * %.3lfms = %.3lf ms) : %6.2lf\r", ch, rg, nRgType, PeakDirStr( nPeakDir ), Beg, Ende, PreciseLoc, nSmoothPts, dltax*1000, (nSmoothPts-1)*dltax*1000, PreciseValue
	endif

End


Function		OnePeak( ch, rg )
// Do a peak determination immediately. 
// ???.......???........ Flaw : Gets any data sweep.  If the display mode is 'single'  this will be the current sweep.  If the display mode is 'stacked'  it can be any sweep, ...
	variable	ch, rg
	string		sWNm		= CfsWndNm( ch )
	string		sFoldOrgWvNm	= GetOnlyOrAnyDataTrace( ch )
	wave	wOrg			= $sFoldOrgWvNm
	variable	rLeft, rRight
	// 6a	 Evaluate the true minimum and maximum peak value and location by removing the noise in a region around the given approximate peak location 
	RegionX( ch, rg, PH_PEAK, rLeft, rRight )			// get the beginning of the Peak1 evaluation region (=rLeft)
	EvaluatePeak( wOrg, ch, rg, PH_PEAK, rLeft, rRight ) 
	// todo 050802 does not work ???       SetRegionY( ch, rg, PH_PEAK, EvY( ch, rg, kE_PEAK ), EvY( ch, rg, kE_PEAK ) )	// cosmetics: set the evaluated peak value as top and bottom of evaluation region to show the user the value (additionally to circle...)
	DisplayOneEvaluatedPoint( kE_PEAK, ch, rg, sWNm )		// or  kE_AMPL
End



// 060219
static Function	EvaluateCrossing( wWave, ch, rg, nPeakDir, sPhase, Beg, Ende, Percent, Val, nResultIndex ) 
// Evaluate the rising or the decaying phase
//  Find the time when the given 'Percent' level is crossed. Up till  060219: Use the smoothed data to reduce noise influence. ( 0% is baseline, 100% is precisePeak)
//  060219 No longer any smoothing as smoothing failed VERY OFTEN when there were too few points on the rising edge.  Could ONLY be re-implemented if it is made sure that there are enough points on the rising phase.
// Todo : possibly adjust search direction  e.g. always peak down...
	wave	wWave
	variable	ch, rg, nPeakDir			// evaluate pos or neg peak  or  no peak at all
	string		sPhase				// 'Rise'  or 'Decay'
	variable	Beg, Ende				// search range limits
	variable	Percent, Val, nResultIndex
	string		sMsg

//	variable	dltax			= deltax( wWave )
//	variable	nSmoothPts	= 7			
//	// Alternate approach: one could evaluate short intervals without smoothing............ 
//	if ( ( Ende - Beg ) <= nSmoothPts * dltax )
//		sprintf sMsg, "EvaluateCrossing( ch:%2d  rg:%2d  Pk %s\t%s )\tInterval for evaluation of crossing is too short (%.3lfs .. %.3lfs = %.3lfms). Minimum duration needed is %d * %.3lfms. ", ch, rg, PeakDirStr( nPeakDir ) , sPhase, Beg, Ende, (Ende - Beg)*1000 , nSmoothPts , dltax*1000
//		printf "Error:\t%s\r", sMsg
//		Alert( kERR_LESS_IMPORTANT,  sMsg )
//	elseif ( Beg < leftx( wWave )   ||   Ende  < leftx( wWave )   ||  Beg > rightx( wWave )   ||   Ende > rightx( wWave ) )
//		sprintf sMsg, "EvaluateCrossing( ch:%2d  rg:%2d  Pk %s\t%s )\tAt least one of the interval borders ( %.3lf .. %.3lfs ) lies outside the wave borders ( %.3lf .. %.3lfs ) ", ch, rg, PeakDirStr( nPeakDir ) , sPhase, Beg, Ende, leftx( wWave ), rightx( wWave ) 
//		printf "Error:\t%s\r", sMsg
//		Alert( kERR_LESS_IMPORTANT,  sMsg )
//	else  
//		FindLevel	/Q /B = (nSmoothPts) /R=( Ende, Beg )  wWave, Val	// search backward
//		if ( V_flag )
//			sprintf sMsg, "EvaluateCrossing( ch:%2d  rg:%2d  Pk %s\t%s )\tFindLevel did not find %.0lf%% level crossing  (%.3lf) within interval %.3lf .. %.3lfs ", ch, rg, PeakDirStr( nPeakDir ) ,sPhase, Percent, Val, Beg, Ende
//			printf "Error:\t%s\r", sMsg
//			Alert( kERR_LESS_IMPORTANT,  sMsg )
//		else
//			 // printf "\t\tEvaluateCrossing( ch:%d   Pk %s  %s\t)  Found %.0lf%% level crossing (%7.2lf)\tat %7.2lfms \r", ch, pad(PeakDirStr( nPeakDir ),5) , pad(sPhase,6), Percent, Val, V_levelX
//		endif
//		SetEval( ch, rg, nResultIndex, kT, V_levelX )		// marking this entry as non-existing  by setting it to Nan if not found 
//		SetEval( ch, rg, nResultIndex, kY, Val )
//	endif


	if ( Beg < leftx( wWave )   ||   Ende  < leftx( wWave )   ||  Beg > rightx( wWave )   ||   Ende > rightx( wWave ) )
		sprintf sMsg, "EvaluateCrossing( ch:%2d  rg:%2d  Pk %s\t%s )\tAt least one of the interval borders ( %.3lf .. %.3lfs ) lies outside the wave borders ( %.3lf .. %.3lfs ) ", ch, rg, PeakDirStr( nPeakDir ) , sPhase, Beg, Ende, leftx( wWave ), rightx( wWave ) - deltaX( wWave )
		printf "Error:\t%s\r", sMsg
		Alert( kERR_LESS_IMPORTANT,  sMsg )
	else  
		FindLevel	/Q 				 /R=( Ende, Beg )  wWave, Val	// search backward
		if ( V_flag )
			sprintf sMsg, "EvaluateCrossing( ch:%2d  rg:%2d  Pk %s\t%s )\tFindLevel did not find %.0lf%% level crossing  (%.3lf) within interval %.3lf .. %.3lfs ", ch, rg, PeakDirStr( nPeakDir ) ,sPhase, Percent, Val, Beg, Ende
			printf "Error:\t%s\r", sMsg
			Alert( kERR_LESS_IMPORTANT,  sMsg )
		else
			 // printf "\t\tEvaluateCrossing( ch:%d   Pk %s  %s\t)  Found %.0lf%% level crossing (%7.2lf)\tat %7.2lfms \r", ch, pad(PeakDirStr( nPeakDir ),5) , pad(sPhase,6), Percent, Val, V_levelX
		endif
		SetEval( ch, rg, nResultIndex, kT, V_levelX )		// marking this entry as non-existing  by setting it to Nan if not found 
		SetEval( ch, rg, nResultIndex, kY, Val )
	endif
End

static Function	EvaluateSlope( wWave, ch, rg, nRgType, nPeakDir, sPhase, Beg, Ende, nResultIndex  ) 
// Evaluate the rising or the decaying phase.  Search the steepest slope
//  060219 No longer any smoothing as smoothing failed VERY OFTEN when there were too few points on the rising edge.  Could ONLY be re-implemented if it is made sure that there are enough points on the rising phase.
//  060219 *Must* use *integer* indexes for for the wave points to obtain consistent results.  'Beg'  and  'Ende'  are float and Igor interpolates wave Y values if point index is not integer. So e.g. the difference wv[123] - wv[124]  differs from  wv[123.3] - wv[124.3]  leading to inconsistent slope results !!!!
	wave	wWave
	variable	ch, rg, nRgType, nPeakDir			// evaluate pos or neg peak  or no peak at all
	string		sPhase						// 'Rise'  or 'Decay'
	variable	Beg, Ende						// search range limits
	variable	nResultIndex 
	nvar		gPrintMask	= root:uf:evo:evl:gprintMask
	variable	n
	string		sMsg			= ""

	variable	bSearchPosSlope = ( nPeakDir == kPEAK_UP_  &&  !cmpstr( sPhase, "Rise" ) )  ||  ( nPeakDir == kPEAK_DOWN_  &&  cmpstr( sPhase, "Rise" ) )  ?  1  :  -1   

	if ( Beg < leftx( wWave )   ||   Ende  < leftx( wWave )   ||   Beg > rightx( wWave )   ||   Ende > rightx( wWave ) )
		sprintf sMsg, "EvaluateSlope(   \t ch:%2d  rg:%2d  Pk %s  %s\t)  At least one of the interval borders ( %.3lf .. %.3lfs ) lies outside the wave borders ( %.3lf .. %.3lfs ) ", ch, rg, pad(PeakDirStr( nPeakDir ),5) , pad(sPhase,6), Beg, Ende, leftx( wWave ), rightx( wWave ) - deltaX( wWave )
		printf "Error:\t%s\r", sMsg
		Alert( kERR_LESS_IMPORTANT,  sMsg )
	else  
		// printf "\t\tEvaluateSlope(   \t ch:%2d  rg:%2d  Pk %s  %s\t)  Beg/ End interval borders ( %.6lf .. %.6lfs ) . Wave borders ( %.6lf .. %.6lfs ) \r", ch, rg, pad(PeakDirStr( nPeakDir ),5) , pad(sPhase,6), Beg, Ende, leftx( wWave ), pnt2x(wWave,numpnts(wWave)-1)// WM: more accurate than rightx(wWave)-deltaX(wWave)

		// Search the biggest y difference between adjacent points = steepest slope
		variable	Slope = 0, SteepestSlope = 0, ptSlope
		variable	nBegPt	= round( ( Beg   - leftX( wWave ) ) / deltaX( wWave ) )
		variable	nEndPt	= round( ( Ende - leftX( wWave ) ) / deltaX( wWave ) )
		for ( n = nBegPt ; n < nEndPt; n += 1 )
			Slope	= bSearchPosSlope * ( wWave[ n + 1 ] - wWave[ n ] )
			if ( Slope > SteepestSlope )
				SteepestSlope = Slope
				ptSlope	= n
				// printf "\t\t\t%s found steeper %s slope between\t%10.6lf\t[pt:%4.1lf] \tand\t%10.6lf\t[pt:%4.1lf] \t pnt2x( n:%4.1lf ):\t%9.6lfs  -> Slope:\t%6.1lf\t(%.1lf/ms)\t[nPnts:%3.1lf] \r", pd(sPhase,6), SelectString (bSearchPosSlope==1,"neg.","pos."),  wWave[ ptSlope ], ptSlope, wWave[ ptSlope + 1 ], ptSlope + 1, n, pnt2x( wWave, n ), SteepestSlope, SteepestSlope/deltaX(wWave)/1000, nEndPt-nBegPt
			endif
		endfor
		SetEval( ch, rg, nResultIndex, kT, ( pnt2x( wWave, ptSlope ) + pnt2x( wWave, ptSlope+1 ) ) / 2 ) 	// todo interpolate between this and next value
		SetEval( ch, rg, nResultIndex, kY, ( wWave[ ptSlope ] + wWave[ ptSlope+1 ]  ) / 2 ) 			// todo interpolate between this and next value
		SetEval( ch, rg, nResultIndex, kVAL, SteepestSlope/deltaX(wWave)/1000 ) 					// in Y units / milliseconds		
	endif

//	variable	nSmoothPts	= 1						// 5 is NOT enough
//	variable	dltax	 		= deltaX( wWave )
//	// Alternate approach: one could evaluate short intervals without smoothing............ 
//	//string		sTmpWvNm = "wPeak" + sPhase + num2str( ch )// wPeakRise0, wPeakDecay2, ...-
//	string			sTmpWvNm = "root:uf:evo:evl:" + "wPeak" + sPhase + num2str( ch )// wPeakRise0, wPeakDecay2, ...-
//	duplicate /O 	/R=( Beg, Ende ) wWave  $sTmpWvNm	// () in the wave units , here in seconds
//	wave		wSmoothedRiseDecay = $sTmpWvNm
//
//	AppendToGraph 				/Q /C=(65000,15000, 65000) wSmoothedRiseDecay	// for testing : slopes are magenta  
//
//	if ( ( Ende - Beg ) <= nSmoothPts * dltax )
//		sprintf sMsg, "EvaluateSlope(   \t ch:%2d  rg:%2d ) Interval for evaluation of   slope   is too short (%.3lfms). Minimum duration needed is %d * %.3lfms. ", ch, rg, (Ende - Beg)*1000 , nSmoothPts , dltax 
//		Alert( kERR_LESS_IMPORTANT,  sMsg )
//	elseif ( Beg < leftx( wWave )   ||   Ende  < leftx( wWave )   ||   Beg > rightx( wWave )   ||   Ende > rightx( wWave ) )
//		sprintf sMsg, "EvaluateSlope(   \t ch:%2d  rg:%2d  Pk %s  %s\t)  At least one of the interval borders ( %.3lf .. %.3lfs ) lies outside the wave borders ( %.3lf .. %.3lfs ) ", ch, rg, pad(PeakDirStr( nPeakDir ),5) , pad(sPhase,6), Beg, Ende, leftx( wWave ), rightx( wWave ) 
//		printf "Error:\t%s\r", sMsg
//		Alert( kERR_LESS_IMPORTANT,  sMsg )
//	else  
//
//		Smooth		/B ( nSmoothPts ),	wSmoothedRiseDecay
//	
//		waveStats	/Q	wSmoothedRiseDecay
//		if ( gPrintMask &  RP_BASEPEAK1 )
//			printf "\t\t\tEvaluateSlope(ch:%2d  rg:%2d)\tPk %1d\t%s\t%s\t\tRange %.3lf to %.3lfs.\tSmoothbox:%d \tMin( %.3lfs ): %5.0lf \tMax(%.3lfs): %5.0lf \r", ch, rg, nRgType, PeakDirStr( nPeakDir ), sPhase, Beg, Ende,  nSmoothPts, V_minloc, V_min, V_maxloc, V_max
//		endif
//		// Todo 051013  this computes garbage.......
//		//....then search the biggest y difference between adjacent points = steepest slope
//		variable	Slope = 0, SteepestSlope = 0, ptSlope
//		for ( n = 0; n < V_npnts - 1; n += 1 )
//			Slope	= bSearchPosSlope * ( wSmoothedRiseDecay[ n + 1 ] - wSmoothedRiseDecay[ n ] )
//			if ( Slope > SteepestSlope )
//				SteepestSlope = Slope
//				ptSlope	= n
//				// printf "\t\t\t%s found steeper %s slope between point %3d \tand %3d \t pnt2x( n:%3d ):\t%6.3lfs  -> SteepestSlope: %g \r", pd(sPhase,6), SelectString (bSearchPosSlope==1, "neg.", "pos." ), ptSlope, ptSlope + 1, n, pnt2x( wSmoothedRiseDecay, n ), SteepestSlope
//			endif
//		endfor
//		SetEval( ch, rg, nResultIndex, kT, pnt2x( wSmoothedRiseDecay, ptSlope ) ) 	// todo interpolate between this and next value
//		SetEval( ch, rg, nResultIndex, kY, wSmoothedRiseDecay[ ptSlope ] ) 		// todo interpolate between this and next value
//		SetEval( ch, rg, nResultIndex, kVAL, SteepestSlope ) 			
//	endif

End
// ...060219

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  File name management for result table  functions

static	 Function		SetCurrentTableFile( sFile )
	string		sFile
	string  /G	root:uf:evo:evl:gsCurrTblFile = sFile
End

static Function  /S	CurrentTableFile()
	svar  /Z	gsCurrTblFile	= root:uf:evo:evl:gsCurrTblFile
	if ( ! svar_exists( gsCurrTblFile ) )
		string  /G	root:uf:evo:evl:gsCurrTblFile	= ""
		svar 		gsCurrTblFile	= root:uf:evo:evl:gsCurrTblFile
	endif
	return	gsCurrTblFile
End

//static Function		EraseTblFileNames()
//	SetCurrentTableFile( "" )						// a new table file will be opened when the next  table results are to be added
//End

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Common file name management for result (=average and table) functions
//  the idea is to use as few globals as possible and to hide as much of the internals to the calling functions (like 'AddToAverage() '  or  'AddDirectlyToFile() ' )

	  Function	/S	ConstructNextResultFileName_( sCfsPath, sSpecifier, sExt )
	string		sCfsPath, sSpecifier, sExt
	variable	NamingMode	= kDIGITLETTER							// 2 naming modes are allowed.   kDIGITLETTER is prefered to avoid confusion with the already used mode kTWOLETTER (used for Cfs file naming) 
	string		sFilePath
	sFilePath	= StripExtensionAndDot( sCfsPath )							// Convert Cfs data file name to average file name by removing the dot and the 1..3 letters...
	sFilePath	= BuildFileName( sFilePath, 0, sSpecifier, sExt, NamingMode )				// ..there can be multiple table files for each cfs file so we append a postfix
	sFilePath	= GetNextFileNm( ksEVO, sFilePath, kSEARCH_FREE, kUP, NamingMode )	// find the next unused file name
	return	sFilePath
End

static Function   /S	BuildFileName( sCfsFileBase, n, sSpecifier, sExt, NamingMode )
// builds  result file name (e.g. average, table) when  path, file and dot (but no extension)  of CFS data  is given (and index) 
// 2 naming modes are allowed.  kDIGITLETTER is prefered to avoid confusion with the already used mode kTWOLETTER (used for Cfs file naming) 
// no channel number is coded in the name (the order of columns determines the channel number) 	  e.g.  Cfsdata.dat, 	     n:6    org   ->	Cfsdata_org_f .tbl   	or  Cfsdata_mav_f.fit
	string		sCfsFileBase, sSpecifier, sExt
	variable	n, NamingMode
	string		sIndexString	= SelectString( NamingMode == kDIGITLETTER,  IdxToTwoLetters( n ),  IdxToDigitLetter( n ) ) 
	return	sCfsFileBase + "_" + sSpecifier + "_" + sIndexString + "." + sExt				// no channel number in name		   e.g.  Cfsdata.dat, 	     n:6    org   ->	Cfsdata_org_f .tbl   	or  Cfsdata_mav_f.fit
End


static  Function		FileBasesDiffer( sCfsFile, sResultFile ) 
// compare the file bases of  the Cfs file and of the table/average file. They will differ the user changed the cfs data file  OR  when the current table/average file name has been cleared
	string		sCfsFile, sResultFile
	string		sCfsFileBase	= StripExtensionAndDot( sCfsFile )			// Convert Cfs data file name to Cfs file base name by removing the dot and the 1..3 letters...
	// print "\tFileBasesDiffer(", sCfsFileBase,  sResultFile , ")",  SelectString( cmpstr( sCfsFileBase, sResultFile[ 0, strlen( sCfsFileBase ) - 1 ] ) , "are same ", "differing" )
	return	cmpstr( sCfsFileBase, sResultFile[ 0, strlen( sCfsFileBase ) - 1 ] )	// the result file may have any ending, only the first characters are compared
End

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  LITTLE  HELPERS 

static	 Function		SetRegionBegEnd( ch, rg, ph, typ, value)
// set a region's  X beginning or end   referred to time 0  ( after subtracting the start time offset = WITHOUT  start time offset )
	variable	ch, rg, ph, typ, value
	wave	wCRegion	= root:uf:evo:evl:wCRegion
	wCRegion[ ch ][ rg ][ ph ][ typ ]	= value - wCRegion[ ch ][ rg ][ ph ][ CN_XCSR_OS ] 
End

	 Function		RegionBegEnd( ch, rg, ph, typ )
// return a region's  X beginning or end  INCLUDING  the start time offset
	variable	ch, rg, ph, typ
	wave	wCRegion	= root:uf:evo:evl:wCRegion
	// if ( ch == 0  &&  rg == 0  &&  ph == 0  &&  typ == CN_BEG )  
	// // if ( ch == 0  &&  rg == 0  && ( ph == 0  || ph == 1 )  &&  typ == CN_BEG )  
	//	printf "\t\t\tRegionBegEnd( ch:%d , rg:%d , ph:%d , typ:%d  ) returns  Reg:\t%8.3lf\t +  Start:\t%8.3lf\t = \t%8.3lf \r", ch, rg, ph, typ, wCRegion[ ch ][ rg ][ ph ][ typ ] , wCRegion[ ch ][ rg ][ ph ][ CN_XCSR_OS ],  wCRegion[ ch ][ rg ][ ph ][ typ ]  + wCRegion[ ch ][ rg ][ ph ][ CN_XCSR_OS ] 
	// endif
	return	wCRegion[ ch ][ rg ][ ph ][ typ ]  + wCRegion[ ch ][ rg ][ ph ][ CN_XCSR_OS ] 
End

static	 Function		RegionX( ch, rg, ph, rL, rR )
// return a region's X coordinates as references, return directly whether the region has already been set
	variable	ch, rg, ph, &rL, &rR
	rL	= RegionBegEnd( ch, rg, ph, CN_BEG )
	rR	= RegionBegEnd( ch, rg, ph, CN_END )
	// print "\t\tRegionX  ch, rg , ph:" ,ch, rg, ph, "->", rL, rR
	return 	numType( rL ) != kNUMTYPE_NAN
End

static	 Function		SetRegionY( ch, rg, ph, Top, Bot )
// converts and stores the given coordinates of a region in  Y 
// PH_PEAK is not handled....
	variable	ch, rg, ph, Top, Bot
	wave	wCRegion	= root:uf:evo:evl:wCRegion
	wCRegion[ ch ][ rg ][ ph ][ CN_BEGY ]		= Top
	wCRegion[ ch ][ rg ][ ph ][ CN_ENDY ]		= Bot		// for base and peak
End

static Function		RegionY( ch, rg, ph, rT, rB )
// return a region's Y coordinates as references
	variable	ch, rg, ph, &rT, &rB
	wave	wCRegion	= root:uf:evo:evl:wCRegion
	rT	= wCRegion[ ch ][ rg ][ ph ][ CN_BEGY ]
	rB	= wCRegion[ ch ][ rg ][ ph ][ CN_LO ]
//	rB	= wCRegion[ ch ][ rg ][ ph ][ CN_BEGY ]
End

static Function		UserRegionBaseY( ch, rg, ph, rT, rB )
// return a region's  USER Y coordinates as references
	variable	ch, rg, ph, &rT, &rB
	wave	wCRegion	= root:uf:evo:evl:wCRegion
	rT	= wCRegion[ ch ][ rg ][ ph ][ CN_BEGY ]
	rB	= wCRegion[ ch ][ rg ][ ph ][ CN_LO ]
//	rB	= wCRegion[ ch ][ rg ][ ph ][ CN_BEGY ]
End

static Function		EvalRegionColor( ch, rg, ph, rRed, rGreen, rBlue )
// return 3 color values for regions when channel and region type is given
	variable	ch, rg, ph
	variable	&rRed, &rGreen, &rBlue 
	variable	nColor
// 2009-12-10
	string  	sFo		= ksEVO
	wave	Red 		= $"root:uf:" + sFo + ":misc:Red", Green = $"oot:uf:" + sFo + ":misc:Green",   Blue = $"root:uf:" + sFo + ":misc:Blue"
//	wave	Red 		= root:uf:aco:misc:Red, Green = root:uf:aco:misc:Green, Blue = root:uf:aco:misc:Blue
	wave	wCRegion	= root:uf:evo:evl:wCRegion
	nColor	= wCRegion[ ch ][ rg ][ ph ][ CN_COLOR ]	
	rRed		= Red[ nColor ]
	rGreen	= Green[ nColor ]
	rBlue		= Blue[ nColor ]
End


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

static Function	FourPointIntersection( ch, rg, index1a, index1b, index2a, index2b, ResultIndex )
// computes intersection given by 2 lines from 4 special evaluation points (given by EVAL-index)  and sets  ResultIndex
	variable	ch, rg, index1a, index1b, index2a, index2b, ResultIndex 
	variable	rx, ry		// are changed
	FourPointXYIntersection( EvT(ch, rg, index1a), EvY(ch, rg, index1a), EvT(ch, rg, index1b), EvY(ch, rg, index1b), EvT(ch, rg, index2a), EvY(ch, rg, index2a ), EvT( ch, rg, index2b), EvY( ch, rg, index2b ), rx, ry ) 
// 050811 kE_BRISE
	SetEval( ch, rg, ResultIndex, kT, rx )
	SetEval( ch, rg, ResultIndex, kY, ry )
End

static Function	FourPointXYIntersection( x1a, y1a, x1b, y1b, x2a, y2a, x2b, y2b, rx, ry )
// returns intersection given by 2 lines from 4 points (each x and y )   in rx  and  ry 
// todo : error checking , division by 0
	variable	x1a, y1a, x1b, y1b		// defines 1. line
	variable	x2a, y2a, x2b, y2b		// defines 2. line
	variable	&rx, &ry				// intersection : parameters are changed
	variable	slope1	= ( y1a - y1b ) / ( x1a - x1b )
	variable	const1	= y1a - slope1 * x1a
	variable	slope2	= ( y2a - y2b ) / ( x2a - x2b )
	variable	const2	= y2a - slope2 * x2a
 	rx = ( const2 - const1 ) / ( slope1 - slope2 ) 
	ry = slope1 * rx + const1
	// printf "\t\tx1a=%g      \ty1a=%g  ,  \tx1b=%g      \ty1b=%g      \tgives line1  y = %gx + %g \r\tx2a=%g      \ty2a=%g  ,  \tx2b=%g      \ty2b=%g    \tgives line2  y = %gx + %g . Intersection at x=%g, y=%g (=%g) \r", x1a, y1a, x1b, y1b, slope1, const1, x2a, y2a, x2b, y2b, slope2, const2, rx, ry , slope2 * rx + const2
End

static Function	TwoLineIntersection( slope1, const1, slope2, const2, rx, ry )
// todo : error checking , division by 0
	variable	slope1, const1			// defines 1. line   y = slope * x + const
	variable	slope2, const2			// defines 2. line   y = slope * x + const
	variable	&rx, &ry				// intersection : parameters are changed
 	rx = ( const2 - const1 ) / ( slope1 - slope2 ) 
	ry = slope1 * rx + const1
	// printf "\t\tx line1  y = %gx + %g \r\tx2a=%g      \tline2  y = %gx + %g . Intersection at x=%g, y=%g (=%g) \r", slope1, const1, slope2, const2, rx, ry , slope2 * rx + const2
End

//=================================================================================================
//   PRINTING THE  RESULTS  IN  THE  TEXTBOX  IN  THE  GRAPH

static  Function  /S	TBEvalHeaderAndResultsNm( ch )
	variable	ch
	return	"TBEvaHeader" + num2str( ch )
End

  		Function		DispHideEvalTextboxAllChans()	
// displays or hides the already existing evaluation results in the textbox in the graph window
	nvar		gChans		= root:uf:evo:cfsr:gChannels			
	variable	ch
	for ( ch = 0; ch < gChans;  ch += 1 )	
		DispHideEvalTextbox__(  ch, "" )
	endfor
End

Function		DispHideEvalTextbox__( ch, sText )
// Display or hide the textbox in the graph window by changing the visibility flag
	variable	ch
	string  	sText
	nvar		bResTextbox	= root:uf:evo:de:cbResTB0000
	string  	sTBNm		=TBEvalHeaderAndResultsNm( ch ) 
	string  	sWNm		= CfsWndNm( ch ) 
	if ( WinType( sWNm ) == kGRAPH ) 					// the user may have killed the window
		if ( strlen( sText ) )							// if text is supplied we turn the visibility of the textbox on and off using the text displaying  or hiding it
			TextBox	/W=$sWNm  /C  /N=$sTBNm  /V=(bResTextbox)  /E=2	/A=MT  /F=2  sText	// /E=2: overwrite plot area
		else										// if no text is supplied we ignore any possibly existing text and just turn the visibility of the textbox on and off so not to clear the existing text
			TextBox	/W=$sWNm  /C  /N=$sTBNm  /V=(bResTextbox)  /E=2	/A=MT  /F=2  		// /E=2: overwrite plot area
		endif
	endif
End


Function	/S	PrintEvalTextbox( ch )
// Print and display the evaluated special points into the textbox in the graph window  
	variable	ch
	variable	nMaxCols		// empirically determined value how many result columns fit into 1 line. If more a line break is inserted.  PROBLEM  todo: more columns will fit in Landscape mode
	string		sItem, sRawLine = "",  sText = ""

	// Font testing ........
	if ( ch == 0 )
			sText	= "\F'Lucida Console'\Z07"	; nMaxCols = 8	// small non-proportional font, OK
		//	sText	= "\F'Terminal'\Z08"						// non-proportional font, Z08 and Z09 are both  OK
	elseif ( ch == 1 )
// todo : only for testing size 08
			sText	= "\F'Lucida Console'\Z08"	; nMaxCols = 7	// non-proportional font,  too wide
		//	sText	= "\F'Courier New'\Z08"					// non-proportional font,  too wide
		//	sText	= "\F'Terminal'\Z08"						// proportional font, Z08 and Z09 are both  OK
		//	sText	= "\F'Fixedsys'\Z09"						// too big
		//	sText	= "\F'Terminal'\Z09"						// proportional font,  Z08 and Z09 are both  OK
	else
			sText	= "\F'Lucida Console'\Z07"	; nMaxCols = 8	// small non-proportional font, OK
		//	sText	= "\F'Small Fonts'\Z07"					// very narrow proportional font,  Z06 and Z07 are both  OK
		//	sText	= "\F'Courier New'\Z08"					// non-proportional font,  too wide
	endif

	// Print the header = the column titles
	variable	c, nCols, len, rg, rgOld, nNewRgIdx = inf
	
	sRawLine	= ResultsFromLB( kCOL_TITLES_, kLB_SELECT, kRS_PRINTGRAPH, ch )		// key modifier must be ALT (green)  or  AltGr  (cyan)  to print the selected results in the graph

	len	= strlen( sRawLine )
	// printf "\t\tPrintEvalTextbox( a ch:%2d )  len:%3d\t'%s ... %s' \r", ch, len, sRawLine[0, 70], sRawLine[len-70, inf]

	nCols	= ItemsInList( sRawLine )
	rgOld		= 0
	for ( c = 0; c < nCols; c += 1 )
		sItem	 	= StringFromList( c, sRawLine )
		len		= strlen( sItem )
		rg		= str2num( sItem[ len-1, len-1 ] )
		if ( rgOld == 0  && rg == 1 )		
			sText	 += "  Rg=1:"										// same length as below
			rgOld 	  = rg
			nNewRgIdx = c 
		endif	

		// sprintf sItem, "%12s", sItem[ 0, len-4 ]								// strip   '_ChRg'  postfix  if there are no appended units : e.g. 'Peak_T_00'	   ->	'Peak_T'
		variable	n_ChRg_Beg	= strsearch( sItem, "_", inf, 1 )					// finds the position of the LAST occurrence of  '_' 	   e.g. 'Peak_T_00/mV'
		variable	n_ChRg_End	= strsearch( sItem, ksSEP_UNIT1, 0 )				// finds the position of  '/'  or  of  '['    				   e.g. 'Peak_T_00/mV'  or  'Peak_T_00[mV]'
		if ( n_ChRg_End != kNOTFOUND )
			sprintf sItem, "%12s ", sItem[ 0, n_ChRg_Beg - 1 ] + sItem[ n_ChRg_End, inf ]// strip   '_ChRg'  postfix  if there are appended units : 	   e.g. 'Peak_T_00/mV'  ->	'Peak_T/mV'  or  'Peak_T[mV]'
		else
			sprintf sItem, "%12s ", sItem[ 0, n_ChRg_Beg - 1 ]					// strip   '_ChRg'  postfix  if there are no appended units : e.g. 'DS_00'	  	    ->	'DS'
		endif
		sText	+= sItem
		// Possible insert a line break
		if ( c == nMaxCols -1  &&  nMaxCols < nCols )
			sText	+= "\r"
		endif
		
	endfor			
	sText	+= "\r"
	// Print the values
	sRawLine	 = ResultsFromLB( kVALUES_, kLB_SELECT, kRS_PRINTGRAPH, ch )	// key modifier must be ALT (green)  or  AltGr  (cyan)  to print the selected results in the graph
	rgOld		= 0
	for ( c = 0; c < nCols; c += 1 )
		sprintf sItem, "%12s ", StringFromList( c, sRawLine )  
		if ( c == nNewRgIdx )
			sText	 += "       "											// same length as above
		endif
		sText	+= sItem
		// Possible insert a line break
		if ( c == nMaxCols -1  &&  nMaxCols < nCols )
			sText	+= "\r"
		endif
	endfor			
	len	= strlen( sText )
	// printf "\t\tPrintEvalTextbox( b ch:%2d )  len:%3d\t'%s ... %s' \r", ch, len, sText[0, 70], sText[len-70, inf]

	// Rearrange the broken lines
	string 	sTextCopy	= sText
	variable	nl, nLines = ItemsInList( sTextCopy, "\r" )
	if ( nLines >= 4 )
		make /O /T /N=(nLines)  wTmpLine
		sText = ""
		for ( nl = 0; nl < nLines; nl += 1 )
			wTmpLine[ nl ]	= StringFromList( nl   	 , sTextCopy, "\r" )			// e.g 4 lines:  header0  header1   value0    value1
		endfor	
		for ( nl = 0; nl < nLines/2; nl += 1 )								// shuffle around..
			sText  += wTmpLine[ nl ] + "\r" + wTmpLine[ nl + nLines/2 ] + "\r"		// e.g 4 lines:  header0   value0    header1  value1
		endfor	
	endif
	KillWaves wTmpLine

	// The comment appears behind the header/value part because comment lines are not shuffled 
	svar		gsComment	= root:uf:evo:cfsr:gsComment		
	if ( strlen( RemoveWhiteSpace( gsComment ) )  &&  cmpstr( gsComment, ksNoGeneralComment )  ) 	// only if the user has entered a comment then print it....
		sText	+= gsComment	+ "\r" 											//...below all other lines (in StimFit it is printed above all other lines)
	endif

	return	sText
End


//=================================================================================================
//  THE  CURSORS

Function		DisplayHideCursors( ch, rg, ph, sWnd, bOn )
	variable	ch, rg, ph, bOn
	string		sWnd
	DisplayHideCursor( ch, rg, ph, CN_BEG, sWnd, bOn )
	DisplayHideCursor( ch, rg, ph, CN_END, sWnd, bOn )
End

static Function		HideCursor( ch, rg, ph, BegEnd, sWnd )
	variable	ch, rg, ph, BegEnd
	string		sWnd
	variable	nCsr		= BegEnd - CN_BEG 
	string  	sYNm		= "wcY_r" + num2str( rg ) + "_p" + num2str( ph ) + "_n" + num2str( nCsr )
	ModifyGraph  /Z /W=$sWnd	hidetrace( $sYNm ) = 1
End
	
	  Function		DisplayHideCursor( ch, rg, ph, BegEnd, sWnd, bOn )
// We use waves to draw the markers instead of drawing primitives. Big advantage: no erasing is necessary.  Drawback: more elaborate code.
	variable	ch, rg, ph, BegEnd, bOn
	string		sWnd
//	nvar		gbDispCursors	= root:uf:evo:de:cbDispCsr0000
//	if ( ! gbDispCursors )
	if ( ! bOn )
		HideCursor( ch, rg, ph, BegEnd, sWnd )
		return 0
	endif

	wave	wCRegion	= root:uf:evo:evl:wCRegion
// 2009-12-10
	string  	sFo		= ksEVO
	wave	Red 		= $"root:uf:" + sFo + ":misc:Red", Green = $"oot:uf:" + sFo + ":misc:Green",   Blue = $"root:uf:" + sFo + ":misc:Blue"
//	wave	Red = root:uf:aco:misc:Red, Green = root:uf:aco:misc:Green, Blue = root:uf:aco:misc:Blue

	// Build a unique cursor wave name
	variable	nCsr		= BegEnd - CN_BEG 
	string  	sChRgNFolder	= ":" + "csr:" + "c" + num2str( ch ) + ":" 	// e.g  ':csr:c1:'
	string  	sXNm		= "wcX_r" + num2str( rg ) + "_p" + num2str( ph ) + "_n" + num2str( nCsr )
	string  	sYNm		= "wcY_r" + num2str( rg ) + "_p" + num2str( ph ) + "_n" + num2str( nCsr )
	ModifyGraph  /Z /W=$sWnd	hidetrace( $sYNm ) = 0

	// Check whether the cursor wave exists already, if not then construct it
	wave	/Z	wX		= $"root:uf:evo" + sChRgNFolder + sXNm
	wave	/Z	wY		= $"root:uf:evo" + sChRgNFolder + sYNm
	if ( ! waveExists( wX )  ||  ! waveExists( wY ) )
		ConstructAndMakeItCurrentFolder( RemoveEnding( "root:uf:evo" + sChRgNFolder, ":" ) )
		make /O /N=11	  $"root:uf:evo" + sChRgNFolder + sXNm	= Nan	// X- and Y-waves containing 11 points : 4 lines and 3 Nan-points in between
		make /O /N=11	  $"root:uf:evo" + sChRgNFolder + sYNm	= Nan
	endif
	wave     wX = 	  $"root:uf:evo" + sChRgNFolder + sXNm
	wave     wY = 	  $"root:uf:evo" + sChRgNFolder + sYNm
	
	// Get the drawing parameters which depend on the cursor shape
	variable	x		= RegionBegEnd( ch, rg, ph, CN_BEG   + nCsr )
	variable	y		= RegionBegEnd( ch, rg, ph, CN_BEGY + nCsr )
	variable	nColor	= wCRegion[ ch ][ rg ][ ph ][ CN_COLOR ] 
	variable	CsrShape	= str2num( StringFromList( ph , klstPH_CSRSHAPE ) )
	variable	nDotting	= rg + 1								// 0 is line, rg 0 ~ 1 ~ very fine dots,  rg 1 ~ 2 ~ small dots,  rg 7 ~ 8 ~ coarse dotting

	variable	VertExt	= CsrShape  & CSR_YSHORT 		?  .25  :  .05		// make vertical lines longer ( 1 ~ Y full scale)
			VertExt	= CsrShape  & CSR_YFULL 		?   1	  :  VertExt		// make vertical lines longer ( 1 ~ Y full scale)
	variable	HrzValExt	= CsrShape  & CSR_VALSHORT  	?  .01  :  .04		// the middle stub : TURNED OFF AT THE MOMENT as the value is often out of range
// gn variable	HrzValExt	= CsrShape  & CSR_VALSHORT  	?  .01  :    0		// the middle stub : TURNED OFF AT THE MOMENT as the value is often out of range
			HrzValExt	= CsrShape  & CSR_VALMEDIUM	?  .05  :  HrzValExt	
			HrzValExt	= CsrShape  & CSR_VALFULL		?    1	  :  HrzValExt	

	// Get the current axis length
// 050921 possible to do  get wave leftX()  instead
	GetAxis /W=$sWnd /Q left
	variable	yBottom	= V_min    //- .02 * ( V_max - V_min )
	variable	yTop		= V_max  //+ .02 * ( V_max - V_min )			// extend  over complete range
	//variable	yMinMax	= V_max - V_min 

	GetAxis /W=$sWnd /Q bottom
	variable	xRight	= V_max
	variable	xLeft		= V_min
	//variable	xMinMax	= xRight - xLeft//V_max - V_min 
	variable	xaxval0	= AxisValFromPixel( sWnd, "bottom", 0  )
	variable	xaxval5	= AxisValFromPixel( sWnd, "bottom", 10  )
	variable	dltax		= xaxval5 - xaxval0

	// For some unknown reason neither  'GetAxis'  nor  ' AxisValFromPixel()'  work reliably. They do work often, though....
	wave	wMnMx	= root:uf:evo:evl:wMnMx
	variable	xMinMax	= wMnMx[ ch ] [ MM_XMAX ] - wMnMx[ ch ] [ MM_XMIN ]
	variable	yMinMax	= wMnMx[ ch ] [ MM_YMAX ] - wMnMx[ ch ] [ MM_YMIN ]


	// Compute the stub lengths
	variable	dxStubRight	=  BegEnd == CN_BEG  ?   0.008 	* xMinMax  : 0
	variable	dxStubLeft		=  BegEnd == CN_END  ?   0.008	* xMinMax  : 0
	variable	dxValRight		=  BegEnd == CN_BEG  ?   HrzValExt * xMinMax  : 0				//  the middle stub : TURNED OFF AT THE MOMENT as the value is often out of range
	variable	dxValLeft		=  BegEnd == CN_END  ?   HrzValExt * xMinMax  : 0


	// Compute cursor end points
	// wave	w = $"root:uf:evo:evl:wOrg" + num2str( ch )						// currently not used : w( x ) is the y-value of the data wave at the current cursor position
	yTop		=  yTop 	 -  .01 * ( yTop - yBottom )
	yBottom	=  yBottom + .01 * ( yTop - yBottom ) 
	// printf "\t\tDisplayCursor()\tch:%d  rg:%d  ph:%d  %s\txMinMax:\t%6.2lf\tstubXR:\t%6.2lf\tx: %g\ty: %g \r", ch, rg, ph, pd( StringFromList(ph, ksPHASES),9), xMinMax, dxStubRight, x, y

	// Check if the cursor is already in the graph, only if is yet missing then append it 
	string 		sTNL	= TraceNameList( sWnd, ";", 1 )
	// print  sYNm,sTNL
	if ( WhichListItem( sYNm, sTNL, ";" )  == kNOTFOUND )		// ONLY if  wave is not in graph...
		AppendToGraph /W=$sWnd wY vs wX
		ModifyGraph 	 /W=$sWnd  mode( 	$sYNm )	= 0		// 0 : lines, 3 : markers ,  4 : lines + markers
		ModifyGraph 	 /W=$sWnd  rgb( 	$sYNm )	= ( Red[ nColor ], Green[ nColor ], Blue[ nColor ] ) 
		ModifyGraph 	 /W=$sWnd  marker( 	$sYNm )	= 48 -3 * nCsr//50 - 3 * nCsr //49 - 3 * nCsr // 33 - 2 * nCsr 
		ModifyGraph 	 /W=$sWnd  msize( 	$sYNm )	= 0 //wEvalSize[ n ]
		ModifyGraph 	 /W=$sWnd  lstyle( 	$sYNm )	= nDotting
	 endif

	// Fill the cursor wave points so that the desired cursor shape is drawn
	// could be streamlined........
	if ( BegEnd == CN_BEG )									// left cursor : draw stubs to the right
		wX[ 0 ]	= x + dxStubRight	; 	wY[ 0 ] = yTop			// upper stub
		wX[ 1 ]	= x  				; 	wY[ 1 ] = yTop			// 
	
		wX[ 3 ]	= x  				; 	wY[ 3 ] = yTop			// vertical line
		wX[ 4 ]	= x				; 	wY[ 4 ] = yBottom		// 
	
		wX[ 6 ]	= x  				; 	wY[ 6 ] = yBottom		// lower stub
		wX[ 7 ]	= x + dxStubRight	; 	wY[ 7 ] = yBottom		//
	endif
	if ( BegEnd == CN_END )									// right cursor : draw stubs to the left
		wX[ 0 ]	= x  - dxStubLeft		; 	wY[ 0 ] = yTop			// upper stub
		wX[ 1 ]	= x 				; 	wY[ 1 ] = yTop			// 
	
		wX[ 3 ]	= x  				; 	wY[ 3 ] = yTop			// vertical line
		wX[ 4 ]	= x				; 	wY[ 4 ] = yBottom		// 
	
		wX[ 6 ]	= x 				; 	wY[ 6 ] = yBottom		// lower stub
		wX[ 7 ]	= x  - dxStubLeft		; 	wY[ 7 ] = yBottom		// 
	endif

	// wX[ 9 ]	 	= x  - dxValLeft		; 	wY[ 9 ]   = y       			// the middle stub : TURNED OFF AT THE MOMENT as the value is often out of range
	// wX[ 10 ]     	= x + dxValRight		; 	wY[ 10 ] = y			// 

End


static Function		DisplayOneEvaluatedPoint( nEvalPointIdx, ch, rg, sWnd )
//  Using Igor markers : ++ markers always keep their size independent of zoom,  ++ needs no redraw (except long hor/vert lines), ++no erasing is necessary, ++simple code (similar to DisplayCursor() ).  
	variable	nEvalPointIdx, ch, rg
	string		sWnd

	variable	shp		= str2num( StringFromList( nEvalPointIdx, klstEVL_SHAPES ) )
	variable	nColor	= WhichListItem( RemoveWhiteSpace( StringFromList( nEvalPointIdx, klstEVL_COLORS ) ), klstColors )
//	if ( numtype( shp ) != kNUMTYPE_NAN )
		// Get the current X axis length
		GetAxis /W=$sWnd /Q bottom
		variable	xLeft		= V_min  + .01 * ( V_max - V_min )
		variable	xRight	= V_max  - .01 * ( V_max - V_min )			// do not extend over complete range, leave a little bit free on each side 
		GetAxis /W=$sWnd /Q left
		variable	yBottom	= V_min
		variable	yTop		= V_max 
		Display1EvalPoint( nEvalPointIdx, ch, rg, sWnd, xLeft, xRight, yTop, yBottom, nColor, shp ) 
//	endif
End


static Function		DisplayEvaluatedPoints( ch, rg, sWnd )
//  Using Igor markers : ++ markers always keep their size independent of zoom,  ++ needs no redraw (except long hor/vert lines), ++no erasing is necessary, ++simple code (similar to DisplayCursor() ).  
	variable	ch, rg
	string		sWnd
	wave	wWave = $FoCurOrgWvNm( ch )

	variable	nEvalPointIdx,nColor, shp

	// Get the current X axis length 050921 old
	//  GetAxis /W=$sWnd /Q bottom  // old and wrong : when X shrink has been executed the data are shorter than the axis (also in catenate mode) . In these cases the 'Base' line should clip at the data limits, not at the axis limits.

	// 050921 Get the current data range for baseline clipping.  Clipping at the axis limits (->GetAxis) is undesirable as the baseline could be longer than the data if the data have been X shrunk (or if in catreanted mode).
	variable	xLeft		= leftX( wWave ) 	// V_min  + .01 * ( V_max - V_min )
	variable	xRight	= rightX( wWave ) 	// V_max  - .01 * ( V_max - V_min )			// do not extend over complete range, leave a little bit free on each side 
	GetAxis /W=$sWnd /Q left
	variable	yBottom	= V_min
	variable	yTop		= V_max 

	variable	nState	= kSTDRAW_EVALUATED					// 1 = blue = CTRL,   2 = green= ALT,   3 = cyan = ALT CTRL,   4 = grey = no modifier
	string 	lstIndices	= SelectedResultsDraw( nState, ch, rg )
	variable	i, nIndices	= ItemsInList( lstIndices )
	for ( i = 0; i < nIndices; i += 1 )
		nEvalPointIdx	= str2num( StringFromList( i, lstIndices ) )
		shp			= str2num( StringFromList( nEvalPointIdx, klstEVL_SHAPES ) )
		nColor		= WhichListItem( RemoveWhiteSpace( StringFromList( nEvalPointIdx, klstEVL_COLORS ) ), klstColors )
		Display1EvalPoint( nEvalPointIdx, ch, rg, sWnd, xLeft, xRight, yTop, yBottom, nColor, shp )
	endfor
End


static Function		Display1EvalPoint( n, ch, rg, sWnd, xLeft, xRight, yTop, yBottom, nColor, shp )
	variable	n, ch, rg, nColor, shp
	string		sWnd
	variable	 xLeft, xRight, yTop, yBottom
// 2009-12-10
	string  	sFo		= ksEVO
	wave	wRed 	= $"root:uf:" + sFo + ":misc:Red",   wGreen = $"oot:uf:" + sFo + ":misc:Green",    wBlue = $"root:uf:" + sFo + ":misc:Blue"
//	wave	wRed = root:uf:aco:misc:Red, wGreen = root:uf:aco:misc:Green, wBlue = root:uf:aco:misc:Blue

	variable	x, y

	// Check whether the eval data points wave exists already, if not then construct it
	string  	sChRgNFolder	= ":" + "pts:" + "c" + num2str( ch ) + ":" 	// e.g  'pts:c1:'
	string  	sXNm		= "wpX_r" + num2str( rg ) + "_n" + num2str( n ) 
	string  	sYNm		= "wpY_r" + num2str( rg ) + "_n" + num2str( n ) 
	wave	/Z	wX	= $"root:uf:evo" + sChRgNFolder + sXNm
	wave	/Z	wY	= $"root:uf:evo" + sChRgNFolder + sYNm
	if ( ! waveExists( wX )  ||  ! waveExists( wY ) )
		// printf "\t\tDisplay1EvalPoint()\tch:%d  rg:%d  pt:%d  Constructing %s\t%s\t \r", ch, rg, n, "root:uf:evo" + sChRgNFolder + sXNm, "root:uf:evo" + sChRgNFolder + sYNm
		ConstructAndMakeItCurrentFolder( RemoveEnding( "root:uf:evo" + sChRgNFolder, ":" ) )
		make /O /N=2 	   $"root:uf:evo" + sChRgNFolder + sXNm	= Nan	// X- and Y-waves containing just 22222222222... evaluated data point
		make /O /N=2 	   $"root:uf:evo" + sChRgNFolder + sYNm	= Nan
		wave	wX	= $"root:uf:evo" + sChRgNFolder + sXNm
		wave	wY	= $"root:uf:evo" + sChRgNFolder + sYNm
	endif

	// Get data point to be drawn
	x = EvT( ch, rg, n )
	y = EvY( ch, rg, n )

	// Check if the data point is already in the graph, only if it is yet missing then append it 
	string 		sTNL	= TraceNameList( sWnd, ";", 1 )
	if ( WhichListItem( sYNm, sTNL, ";" )  == kNOTFOUND )			// ONLY if  wave is not in graph...

		// printf "\t\tDisplay1EvalPoint()\tch:%d  rg:%d  pt:%d %s\t  t:\t%8.3lf\t  y:\t%8.3lf\t Shp:%2d\t%s\t(%d)\t APPENDING\t%s\t%s\t \r", ch, rg, n, pd( StringFromList(n, klstEVL_RESULTS),9), x, y, shp, pd(StringFromList( nColor, klstCOLORS),5), nColor, "root:uf:evo" + sChRgNFolder + sXNm, "root:uf:evo" + sChRgNFolder + sYNm
		AppendToGraph /W=$sWnd wY vs wX
		ModifyGraph 	 /W=$sWnd  rgb( 	$sYNm )	= ( wRed[ nColor ], wGreen[ nColor ], wBlue[ nColor ] ) 
		if ( shp == cLLINEH  ||  shp == cLLINEV )
			ModifyGraph 	 /W=$sWnd  mode( 	$sYNm )	= 0		// 0 : lines, 3 : markers ,  4 : lines + markers
		else
			ModifyGraph 	 /W=$sWnd  mode( 	$sYNm )	= 3		// 0 : lines, 3 : markers ,  4 : lines + markers
			ModifyGraph 	 /W=$sWnd  marker( 	$sYNm )	= shp
			variable	size	= ( shp == cSLINEH  ||  shp == cSLINEV  ||  shp == cSCROSS ||  shp == cXCROSS ) ? 10 : 0	// Rect and Circle have automatic size = 0
			ModifyGraph 	 /W=$sWnd  msize( 	$sYNm )	= size
		endif
	else
		// printf "\t\tDisplay1EvalPoint()\tch:%d  rg:%d  pt:%d %s\t  t:\t%8.3lf\t  y:\t%8.3lf\t  Shp:%2d\t%s\t(%d)\tWaves exist \t%s\t...%s\r", ch, rg, n, pd( StringFromList(n, klstEVL_RESULTS),9), x, y, shp, pd(StringFromList( nColor, klstCOLORS),5), nColor, "root:uf:evo" + sChRgNFolder + sXNm,  sYNm
	endif
		
	// Update the wave with the new value: this also automatically updates the display  	
	wX[ 0 ] = x		;	wY[ 0 ] = y
	wX[ 1 ] = Nan	;	wY[ 1 ] = Nan

	if ( shp == cLLINEH )
		wX[ 0 ] = xLeft	;	wY[ 0 ] = y
		wX[ 1 ] = xRight	;	wY[ 1 ] = y
	endif
	if ( shp == cLLINEV )
		wX[ 0 ] = x		;	wY[ 0 ] = yTop
		wX[ 1 ] = x		;	wY[ 1 ] = yBottom
	endif
	// if ( nShape == cSLOPE )
	//	// DrawPoly	/W=$sWnd	rLeft-2, rBot, 1, 1,  {rLeft-2, rBot, rLeft+2, rBot, rRight+2, rTop, rRight-2, rTop, rLeft-2, rBot }	// thick bar
	//	 DrawPoly	/W=$sWnd	rLeft-1, rBot, 1, 1,  {rLeft-1, rBot, rLeft+1, rBot, rRight+1, rTop, rRight-1, rTop, rLeft-1, rBot }	// thin bar
End


//	if ( nShape == SLOPE )
//		// DrawPoly	/W=$sWnd	rLeft-2, rBot, 1, 1,  {rLeft-2, rBot, rLeft+2, rBot, rRight+2, rTop, rRight-2, rTop, rLeft-2, rBot }	// thick bar
//		 DrawPoly	/W=$sWnd	rLeft-1, rBot, 1, 1,  {rLeft-1, rBot, rLeft+1, rBot, rRight+1, rTop, rRight-1, rTop, rLeft-1, rBot }	// thin bar

//	endfor
//	SetDrawEnv	/W=$sWnd	dash 	= 0			,save
//	SetDrawLayer	/W=$sWnd	ProgFront
//End


static Function		RescaleCursors( ch )
	variable	ch
	variable	rg, rgCnt	 = RegionCnt( ch )
	for ( rg = 0; rg < rgCnt;  rg += 1 )	
		string		sWnd	= CfsWndNm( ch )
		variable	ph, phCnt	= ItemsInList( ksPHASES )
		for ( ph = 0; ph < phCnt;  ph += 1 )	
			variable	BegEnd
			for ( BegEnd = CN_BEG; BegEnd <= CN_END;  BegEnd += 1 )	
// 051013
				DisplayHideCursor( ch, rg, ph, BegEnd, sWnd, ON )
			endfor
		endfor
	endfor
End

	 Function		RescaleAllCursors()
// ???? used when wCRegion[]  is loaded from the config file.  Is this really needed?  050929
	variable	ch
	nvar		gChans	= root:uf:evo:cfsr:gChannels					
	for ( ch = 0; ch < gChans;  ch += 1 )	
		RescaleCursors( ch )
	endfor
End


//=================================================================================================
//   IMPLEMENTATION of  EVAL

	 Function		EvT( ch, rg, pt )
	variable	ch, rg, pt
	wave	wEval	= root:uf:evo:evl:wEval
	return	wEval[ ch ][ rg ][ pt ][ kT ]
End	


	 Function		EvY( ch, rg, pt )
	variable	ch, rg, pt
	wave	wEval	= root:uf:evo:evl:wEval
	return	wEval[ ch ][ rg ][ pt ][ kY ]
End	

	 Function		EvV( ch, rg, pt )
	variable	ch, rg, pt
	wave	wEval	= root:uf:evo:evl:wEval
	return	wEval[ ch ][ rg ][ pt ][ kVAL ]
End	

	 Function		Eval( ch, rg, pt, nType )
	variable	ch, rg, pt, nType
	wave	wEval	= root:uf:evo:evl:wEval
	// printf "\t\tEval( \t\tch:%d  rg:%d  pt:%d  nType:%d )  \tretrieves\t%g   \r", ch, rg, pt, nType, wEval[ ch ][ rg ][ pt ][ nType ]
	return	wEval[ ch ][ rg ][ pt ][ nType ]
End	

static Function		SetEval( ch, rg, pt, nType, Value ) 
//	 Function		SetEval( ch, rg, pt, nType, Value ) 
	variable	ch, rg, pt,  nType, Value
	wave	wEval	= root:uf:evo:evl:wEval
	wEval[ ch ][ rg ][ pt ][ nType ] = Value
	// printf "\t\tSetEval( \tch:%d  rg:%d  pt:%d  nType:%d )  \tstores \t%g    =?= %g  =?= %g \r", ch, rg, pt, nType, value, Eval( ch, rg, pt, nType ), wEval[ ch ][ rg ][ pt ][ nType ]
End	

static Function		ExistsEvT( ch, rg, pt )
	variable	ch, rg, pt
	wave	wEval	= root:uf:evo:evl:wEval
	return	numtype( wEval[ ch ][ rg ][ pt ][ kT ] ) != kNUMTYPE_NAN
End	
static Function		ExistsEvY( ch, rg, pt )
	variable	ch, rg, pt
	wave	wEval	= root:uf:evo:evl:wEval
	return	numtype( wEval[ ch ][ rg ][ pt ][ kY ] ) != kNUMTYPE_NAN
End	
//Function		E_ExistsEval( ch, rg, typ )
//	variable	ch, rg, typ
//	wave	wCRegion	= root:uf:evo:evl:wCRegion
//variable xx=0//todo
//	return	wCRegion[ ch ][ rg ][ xx ][ typ ]  !=  1		// todo must be nan or inf
//End	


// 051004
//	 Function	/S	EvalNm_( pt )
//// Name may include whitespaces
//	variable	pt
//	return	StringFromList( pt, klstEVL_RESULTS )
//End	


	 Function	/S	EvalNm( pt )
	variable	pt
	return	RemoveLeadingWhiteSpace( StringFromList( pt, klstEVL_RESULTS ) )	// remove tabs which are there only for better readability during programming
End	

	 Function	/S	Eval_Unit__( ch, pt, d )
// return the 'units' string  including the unit separators   which  can be    '/' and ''  =  Peak/mV      or    '['  and  ']'   =  Peak[mV]
	variable	ch, pt, d
	string  	sUnit		= RemoveLeadingWhiteSpace( StringFromList( pt, klstEVL_UNITS ) )
	
	if ( d == kT  ||  d == kTB  ||  d == kTE )
		sUnit		= "s"
	else
		if ( cmpstr( sUnit, "au" ) == 0 )
			sUnit		= FileChanYUnits( ch )				// mV  or  pA  depending on...
		elseif ( cmpstr( sUnit, "U2" ) == 0 )
			sUnit		= "u2"							// mV  or  pA  depending on...
		elseif ( cmpstr( sUnit, "MO" ) == 0 )
			sUnit		= "MOhm"
		endif
	endif

	if ( strlen( sUnit ) )
		sUnit	= ksSEP_UNIT1 + sUnit + ksSEP_UNIT2 		// e.g. can be    '/' and ''  =  Peak/mV      or   '['  and  ']'   =  Peak[mV]
	endif
	// printf "\t\tEval_Unit__( ch:%2d , pt:%3d, d:%d  )\t->\t'%s\t%s'\t + '%s' \r", ch, pt, d, pad( EvalNm( pt ), 9 ), StringFromList( d, klstE_POST ), sUnit
	return	sUnit
End	


	 Function		Eval_UnitFactor_( ch, pt, d )
// return the scaling factor appropriate for the 'units' string  e.g.  1 for 's',   1000 for 'ms'
	variable	ch, pt, d
	string  	sUnit		= RemoveLeadingWhiteSpace( StringFromList( pt, klstEVL_UNITS ) )
	variable	Factor	= 1

	if ( d == kT  ||  d == kTB  ||  d == kTE )
		Factor	= 1
	else
		if ( cmpstr( sUnit, "au" ) == 0 )
			Factor	= 1
		elseif ( cmpstr( sUnit, "U2" ) == 0 )
			Factor	= 1
		elseif ( cmpstr( sUnit, "MO" ) == 0 )
			Factor	= 1
		elseif ( cmpstr( sUnit, "ms" ) == 0 )
			Factor	= 1000
		elseif ( cmpstr( sUnit, "us" ) == 0 )
			Factor	= 1000000
		endif
	endif
	// printf "\t\tEval_UnitFactor_( ch:%2d , pt:%3d, d:%d  )\t->\t'%s\t%s'\t + '%s' :\tFactor:%g\r", ch, pt, d, pad( EvalNm( pt ), 9 ), StringFromList( d, klstE_POST ), sUnit, Factor
	return	Factor
End	





Function	/S		EvalString( ch, pt )
// Supply the few strings which cannot be stored in number array  'wEval'  . For this to work the  'klstEVL_IS_STRING'  value must be set to TRUE. 
	variable	ch, pt
	string  	sStr	= "?"
	if ( pt == kE_CHNAME )
		sStr	= CfsIONm_( ch )	
	elseif ( pt == kE_FILE )
		svar		gsDataFileR	= root:uf:evo:cfsr:gsDataFileR
		sStr	= 	gsDataFileR
	elseif ( pt == kE_SCRIPT )
		svar		gsStimFile		= root:uf:evo:cfsr:gsStimFile
		sStr	= 	gsStimFile
	elseif ( pt == kE_DATE )
		svar		gsDate		= root:uf:evo:cfsr:gsDate		
		sStr	= 	gsDate
	elseif ( pt == kE_TIME )
		svar		gsTime		= root:uf:evo:cfsr:gsTime		
		sStr	= 	gsTime
// 051114a
	elseif ( pt == kE_DS )
		svar		gsDSName	= root:uf:evo:evl:gsDSName		
		sStr	= 	gsDSName
	endif
	return	sStr
End

Function	ResetEval_( ch )
	variable	ch
	variable	rg, pt, typ
	for ( rg = 0; rg < kRG_MAX;  rg += 1 )	
		for ( pt = 0; pt < ItemsInList( klstEVL_RESULTS );  pt += 1 )	
			for ( typ = 0; typ < kE_MAXTYP;  typ += 1 )	
				SetEval( ch, rg, pt, typ, nan )
			endfor
		endfor
	endfor
End

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//   EVALUATION  WINDOW  HOOK  FUNCTION
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function		CFSDisplayAllChanInit( sFolder, nChannels )
// creates windows for  Eval  data
	string  	sFolder
	variable	nChannels

	string  	lstCfsWindows	= WinList( ksEVO_WNM + "*", ";" , "WIN:1" )			// all graphs starting with 'Eval' , in this case 'Eval0' , Eval1' , Eval2' ...
	variable	ch, CfsWndCnt	= ItemsInList( lstCfsWindows )
	if ( CfsWndCnt != nChannels )											// If the number of windows changes we kill them all as their sizes will change
		for ( ch = 0; ch < CfsWndCnt; ch += 1)
			DoWindow  /K $StringFromList( ch, lstCfsWindows ) 					// Kill it
		endfor
		string  	sPnOptions	= ":dlg:tPnEvalDetails" 						// if windows are added or killed then reflect the changes in the Eval panel .  TODO also when only a channel number changes?!? 
		UpdatePanel(  "PnEvalDetails", "Evaluation Details" , sFolder, sPnOptions )		// same params as in  ConstructOrDisplayPanel()
	endif
	// print  "\t\tDebug1 : \t\t\tGraphs 'Eval..':", WinList( ksEVO_WNM + "*", ";" , "WIN:1" ) , "all windows 'Eval..' except Graphs (should be none): ", WinList( ksEVO_WNM + "*", ";" , "WIN:214" )

	for ( ch = 0; ch < nChannels; ch += 1)
		// Keep user-changed window size and position when going to a new file if the new file has the same number of channels.  Build the window only when necessary
		// The window title contains brackets so the user sees the dependencies between  the Adc- and telegraph-channels  but the window name must not contain brackets  '('  or  ')'
		string  	sWNm	= EvalWndNm( ch )
		if ( WinType( sWNm ) != kGRAPH ) 									// Only if there is no previous instance of this window...
			BuildEvalWnd( sWNm, ch, nChannels )
		else
			SetWindowTitle( sWNm, ch )									// the Adc channel might have changed even if this window and this number of windows is unchanged
		endif
		EraseTracesInGraph( sWNm )
		RemoveAllTextBoxes( sWNm )							
	endfor

//	// Save average (it there is one) when loading a new file
//	if ( AvgCnt_( 0 ) )
//		DSSaveAvgAllChans_()								// auto-build the average file name and save the data
//		DSEraseAvgAllChans_()								//
//	endif
//	// todo : also delete wAvg ???  redrawWindow  ??? erase Avq ???
End		


Function		BuildEvalWnd( sWNm, ch, nChans )
	string  	sWNm
	variable	ch, nChans		
	variable	Left, Top, Right, Bot
	GetAutoWindowCorners( ch, nChans, 0, 1, Left, Top, Right, Bot, 20, 95 )		//...then compute default size and position..

	string  	sDSPanelNm	= DSPanelNm_( kWV_ORG_ )
	if ( WinType( sDSPanelNm ) == kPANEL ) 								// Only if the data section panel exists...
		GetWindow $sDSPanelNm , wsize								// ..then position the data windows just to the right of the data sections panel...
		// printf "\t\tCFSDisplayAllChanInit()\tLeft:%4d\tPnWidth:%4d\t \r", Left, V_right
		Left	= V_right												// .. which overwrites the prevoius left border as computed above. 
	endif

	Display 	/K=1  /W=( Left, Top, Right, Bot )							//...and  build an empty window
	string  	sActWnd	= WinName( 0, 1 )								// Look for the active _GRAPH_ .  Use 'RenameWindow'  , do not use DoWindow /C .....
	RenameWindow   $sActWnd	$sWNm 								// Do not use DoWindow /C as this fails in in rare but reproducible cases (nChans and file length changing, hitting 'next file very fast and often) as it uses the panel instead of the graph.
	SetWindow   	$sWNm	hook( hDSGraphHookNm )	= fDSGraphHook		//OK
	SetWindowTitle( sWNm, ch )										// Set new window title which may have changed even if number of channels remains constant e.g. 'Adc2' -> 'Adc3'
	// string  	sTNL = TraceNameList( sWNm, ";", 1 ) ; printf "\t\tCFSDisplayAllChan( Init \t\t\t\t DiCn:%2d\tFile:'%s'\tCh:%d/%d\tNm:%s\tTi:'%s'\tTraces:%3d\t'%s...' \r", nDisplayCnt, gsDataFileR, ch, nChans, sWNm, sWndTitle, ItemsInList( sTNL ), sTNL[ 0,100 ]
End


Function 		fDSGraphHook( s )
// Detects and reacts on double clicks and keystrokes without executing  Igor's default double click actions. Parts of the code are taken from WM 'Percentile and Box Plot.ipf'
	struct	WMWinHookStruct &s 			// test ? static 
	wave	wCurRegion	= root:uf:evo:evl:wCurRegion
	variable	returnVal		= 0
	variable	ch 			= CfsWndNm2Ch( s.winName )
	variable	xaxval		= AxisValFromPixel( s.winName, "bottom", s.mouseLoc.h  )
	variable	yaxval		= AxisValFromPixel( s.winName, "left", s.mouseLoc.v  )
	string  	sKey			= num2char( s.keycode )
	variable 	isClick		= ( s.eventCode == kWHK_mouseup ) + ( s.eventCode == kWHK_mousedown )	// a click is either a MouseUp or a MouseDown (recognised only IN graph area, not on title area)

	if ( s.eventCode	== kWHK_activate )
		// Clicking in a window activates the corresponding tab in the panel.   BAD CODE TODO : window and control names are hard-wired......
		Tabcontrol    root_uf_evo_de_tc1 , win=de , value = ch  	 		// 051110 We must set the correct tab and additionally ...
		TabControl3( "de", "root_uf_evo_de_tc1", ch )					// 051110 ..we must update the controls inside so that they correspond to the selected tab. This name is derived from 'PnBuildFoTabcoNm()' .  
	endif

	if ( s.eventCode	!= kWHK_mousemoved )
		// print s
		// printf "\t\t\tfDSGraphHook()\t\tEvntCode:%2d\t%s\tmod:%2d\tch:%d\t'%s'\t'%s' =%3d\tX:%4d\t%7.3lf\tY:%4d\t%7.3lf\tClik:%2d\t \r ", s.eventCode, pd( s.eventName, 8 ), s.eventMod, ch, s.winName,  sKey, s.keycode, s.mouseLoc.h, xaxval, s.mouseLoc.v, yaxval, isClick
	endif
	//  MOUSE  PROCESSING
	if( isClick )													// can be either mouse up or mouse down
		//wCurRegion[ cCH ]		= ch								// Remember value for Expand, Shrink, Up, Down, Left, Right 
		wCurRegion[ cXMOUSE ]	= xAxVal							// last clicked x is needed for cursor adjustment when the user leaves the graph to click a panel button rather than staying in the graph and using a key
		wCurRegion[ cYMOUSE ]	= yAxVal							// last clicked y is needed for cursor adjustment when the user leaves the graph to click a panel button rather than staying in the graph and using a key
	endif	


	//  KEYSTROKE  PROCESSING
	nvar	/Z	gnKey1		= root:uf:evo:evl:gnKey1						//

	if ( !nvar_Exists( gnKey1) ) //  ||  !nvar_Exists(MouseDnX)  ||  !nvar_Exists(MouseDnY)  ||  !nvar_Exists(MouseDnTime)  ||  !nvar_Exists(bSawDblClick) ) 
		variable  	/G	root:uf:evo:evl:gnKey1		= kNOTFOUND			// The first key of a 2-key-combination must be remembered when the second key is processed. Code requires to start with kNOTFOUND.
		nvar	/Z	gnKey1					= root:uf:evo:evl:gnKey1		// make the local globals known...
	endif
	
	// For keyboard strokes we can only use the SHIFT modifier,  ALT interferes with Igor's menu, CTRL with Igor's shortcuts. Mouse CTRL ALT is OK.
	// Uses Stimfits 2-letter-shortcuts consequently. Only ADDITIONALLY buttons are provided...
	if ( s.eventCode == kWHK_keyboard ) 

		if ( gnKey1	!= kNOTFOUND )		 						// Are we expecting the 2. key of a  2-key-combination ?
			if ( IsValidKeyCombination( gnKey1, s.keycode ) )				// Is the 2. key appropriate for the 1. key? 
				ExecuteActions( gnKey1, s.keycode, ch )
			else												// It is not a valid 2. key 
				if ( IsKey1of2( s.keycode ) )							// It is a 1. key of a new 2-key-combination
					gnKey1		= s.keycode
				else											// It is a single key
					gnKey1		= kNOTFOUND
					ExecuteActions( s.keycode, kNOTFOUND, ch)
				endif
			endif
		else
			if ( IsKey1of2( s.keycode ) )								// It is a 1. key of a new 2-key-combination
				gnKey1		= s.keycode
			else												// It is a single key
				gnKey1		= kNOTFOUND
				ExecuteActions( s.keycode, kNOTFOUND, ch)
			endif
		endif		
	endif
	
	return returnVal							// 0 : allow further processing by Igor or other hooks ,  1 : prevent any additional processing 
End


static Function		SetWindowTitle( sWNm, ch )
	string  	sWNm
	variable	ch
	string  	sWndTitle	= "#" + num2str( ch ) + " : " + CfsIONm_( ch )	
	DoWindow  /T	 $sWNm	sWndTitle
End

Function	/S	EvalWndNm( ch )
	variable	ch
	return	ksEVO_WNM + num2str( ch ) 			 					//   window names must not contain '('  or  ')'
End

Function	/S	CfsWndNm( ch )
	variable	ch
	return	EvalWndNm( ch )
End
Function		CfsWndNm2Ch( sCfsWndNm )
	string		sCfsWndNm 
	//return	str2num( sCfsWndNm[ strlen( sCfsWndNm ) - 1, strlen( sCfsWndNm ) - 1 ] )  	// extract the last character which must be a digit and convert to a number
	return	TrailingDigit( sCfsWndNm )						// extract the last character which must be a digit and convert to a number
End

Function	/S	CfsIONm_( ch )
// the window TITLE may contains bracket so the user sees the dependencies between  the Adc- and telegraph-channels...
// ...but neither the window NAME   nor  any   TRACES  may contain brackets  '('  or  ')'   [superimposing will not work with illegal names as IGOR truncates the trace name at the first blank ]
	variable	ch
	string		sIOName	= GetCFSChanName( ch ) 			// name is limited to some 20 characters....
	sIOName	= ReplaceCharWithString( sIOName, " ", "_" )	// convert spaces to underscores ( one could equally well remove them completely...)
	sIOName	= ReplaceCharWithString( sIOName, "(", "_" )	// convert parenthesis to underscores
	sIOName	= ReplaceCharWithString( sIOName, ")", "_" )	// convert parenthesis to underscores
	sIOName	= RemoveWhiteSpace( sIOName )			// remove tabs, CR, LF
	if ( strlen( sIOName ) == 0 ) 
		sIOName	= "Adc" + num2str( ch )
	endif
	// printf "\tCfsIONm_( ch :%d ) : sIOName:'%s' \r", ch, sIOName
	return	sIOName
End

// Igor 5 made this obsolete						
static Function  /S  	ReplaceCharWithString( sString, sChar, sRep )
	string 	sString, sChar, sRep 
	return	ReplaceString( sChar, sString, sRep)			
End

//Static  Function  /S	TBEvalYUnitsNm( ch )
//	variable	ch
//	return	"TBEvalYUnits" + num2str( ch )
//End


static constant	kSCL_SMALLSTEP	= 1.26		// as in Stimfit appr.  3. root of 2 
static constant	kSCL_BIGSTEP	= 2 			// as in Stimfit	
static constant	kSHIFT_SMALLSTEP= .05		// try to move 5% of axis
static constant	kSHIFT_BIGSTEP	= .25			// try to move 25% of axis	


// could PROBABLY NOT / PERHAPS be simplified by recognizing the SHIFT modifier 
// Define the 2-key-combinations. Separator is '~'  . The first 2 entries after '~' are the primary key, any number of following entries are the secondary keys.  
//								X				   Y						Peak		Fit0		Fit1		    Fit2		
//strconstant	ksKeyCombinations	= "x;X;e;E;s;S;l;L;r;R;28;29~y;Y;e;E;s;S;u;U;d;D;30;31~p;P;b;B;e;E~f;F;b;B;e;E~g;G;b;B;e;E~h;H;b;B;e;E"	// 28 arrR, 29 arrL, 30 arrU, 31 arrD, 11 pgU, 12 pgD 
//strconstant	ksKeyCombinations	= "x;X;e;E;s;S;l;L;r;R;28;29~y;Y;e;E;s;S;u;U;d;D;30;31~"	// 28 arrR, 29 arrL, 30 arrU, 31 arrD, 11 pgU, 12 pgD 

strconstant	ksKeyCombinations	= ""	// 051012 no more 2-key-combinations
						
//static 	Function	IsKey1of2( nKey1 )
		 Function	IsKey1of2( nKey1 )
// Is  'nKey1'  the  1. key of a 2-key-combination ? 
	variable	nKey1
	variable	g, nGroups	= ItemsInList( ksKeyCombinations, "~" )	// e.g.  X , Y , E_rase
	variable	i1, nFirstKeys = 2, nGroupKey1
	string  	sGroup, sGroupKey1

	for ( g = 0; g < nGroups; g += 1 )
		sGroup		= StringFromList( g, ksKeyCombinations, "~" )
		for ( i1 = 0; i1< nFirstKeys; i1 += 1 )
			sGroupKey1	= StringFromList( i1, sGroup )
			nGroupKey1	= numType( str2num( sGroupKey1 ) ) == kNUMTYPE_NAN  ?  char2num( sGroupKey1 )  : str2num( sGroupKey1 )		// e.g. convert "A" to 65  and "28" to 28 	
			if ( nKey1 == nGroupKey1 )
				return	TRUE							// found  'nKey1'  as first key of a combination
			endif
		endfor
	endfor
	return	FALSE
End

static 	Function	IsValidKeyCombination( nKey1, nKey2 )
// Is the 2. key appropriate for the 1. key? 
	variable	nKey1, nKey2
	variable	g, nGroups	= ItemsInList( ksKeyCombinations, "~" )	// e.g.  X , Y , E_rase
	variable	i1, nFirstKeys = 2, nGroupKey1
	variable	i2, nSecondKeys, nGroupKey2
	string  	sGroup, sGroupKey1, sGroupKey2

	for ( g = 0; g < nGroups; g += 1 )
		sGroup		= StringFromList( g, ksKeyCombinations, "~" )
		nSecondKeys	= ItemsInList( sGroup ) - 2					// the first 2 letters are key1,  e.g.  x;X.....~y;Y;.....~e;E;.....
		for ( i1 = 0; i1< nFirstKeys; i1 += 1 )
			sGroupKey1	= StringFromList( i1, sGroup )
			nGroupKey1	= numType( str2num( sGroupKey1 ) ) == kNUMTYPE_NAN  ?  char2num( sGroupKey1 )  : str2num( sGroupKey1 )		// e.g. convert "A" to 65  and "28" to 28 	
			for ( i2 = 2; i2 < 2 + nSecondKeys; i2 += 1 )
				sGroupKey2	= StringFromList( i2, sGroup )
				nGroupKey2	= numType( str2num( sGroupKey2 ) ) == kNUMTYPE_NAN  ?  char2num( sGroupKey2 )  : str2num( sGroupKey2 )	// e.g. convert "A" to 65  and "28" to 28 	
				if ( nKey1 == nGroupKey1  &&   nKey2 == nGroupKey2 )
					// printf "\t\t\t\tIsValidKeyCombination( key1:%3d (%s), key2:%3d(%s) )  returns TRUE \r",   nKey1, num2char(nKey1),   nKey2, num2char(nKey2) 
					return	TRUE						// found valid combination
				endif
			endfor
		endfor
	endfor
	return	FALSE
End

//static Function	CheckIsKey1of2AndExecuteActions( sWnd, ch, nKey1, nKey2, xAxVal, yAxVal, nMod )
//	string  	sWnd
//	variable  	ch, nKey1, nKey2, xAxVal, yAxVal, nMod
//End

static 	Function	ExecuteActions( nKey1, nKey2, ch )
	variable  	nKey1, nKey2, ch
	string  	sCh	= num2str( ch )
	struct	WMButtonAction	swmBuActDummy

	if ( nKey2 == kNOTFOUND )										// NORMAL  1-KEY-PROCESSING
	
		// printf "\t\t\tfEvalWndNamedHook()\tExecuteActions() : 1 key processing \tCod:%3d,%3d\tch:%2d\t:\t%s, \r ",  nKey1, nKey2, ch, num2char(nKey1)

		switch( nKey1 )

			case   27 :												// ESC
				buCfsESC( ch )										// looks like a button procedure but has no button 	
				break
			case   13 :												// CR  = Enter
				buCfsCR( ch )										// looks like a button procedure but has no button 	
				break

			case  98 :												// b	base set  left   cursor
				buBaseBegCsr( "root_uf_evo_de_buBaseLCsr" + sCh + "000" ) 	 	
				break

			case  66 :												// B	Base set  right cursor
				buBaseEndCsr( "root_uf_evo_de_buBaseRCsr" + sCh + "000" ) 	
				break

			case 112 :												// p	peak set left    cursor
				buPeakBegCsr( "root_uf_evo_de_buPeakBCsr" + sCh + "000" ) 	
				break

			case   80 :												// P	Peak set right cursor
				buPeakEndCsr( "root_uf_evo_de_buPeakECsr" + sCh + "000" ) 	
				break

			case  102 :											// f	fit0   set  left    cursor
				buFit0BegCsr( "root_uf_evo_de_buFit0BCsr" + sCh + "000" ) 	
				break
			case   70 :												// F	Fit0  set  right  cursor
				buFit0EndCsr( "root_uf_evo_de_buFit0ECsr" + sCh + "000" ) 	
				break

			case  103 :											// g	fit1   set  left    cursor
				buFit1BegCsr( "root_uf_evo_de_buFit1BCsr" + sCh + "000" ) 	
				break
			case   71 :												// G	Fit1  set  right  cursor
				buFit1EndCsr( "root_uf_evo_de_buFit1ECsr" + sCh + "000" ) 	
				break

			case  104 :											// h	fit2   set  left    cursor
				buFit2BegCsr( "root_uf_evo_de_buFit2BCsr" + sCh + "000" ) 	
				break
			case   72 :												// H	Fit2  set  right  cursor
				buFit2EndCsr( "root_uf_evo_de_buFit2ECsr" + sCh + "000" ) 	
				break

			case 108 :												// l    Lat0  set  left  cursor
				buLat0BegCsr( "root_uf_evo_de_buLat0BCsr" + sCh + "000" ) 	
				break
			case  76 :												// L	Lat0  set  right  cursor 
				buLat0EndCsr( "root_uf_evo_de_buLat0ECsr" + sCh + "000" ) 	
				break
			case   109 :											// m	Lat1  set  left  cursor
				buLat1BegCsr( "root_uf_evo_de_buLat1BCsr" + sCh + "000" ) 	
				break
			case   77 :												// M	Lat1  set  right  cursor
				buLat1EndCsr( "root_uf_evo_de_buLat1ECsr" + sCh + "000" ) 	
				break
			case   110 :											// n	Lat2  set  left  cursor
				buLat2BegCsr( "root_uf_evo_de_buLat2BCsr" + sCh + "000" ) 	
				break
			case   78 :												// N	Lat2  set  right  cursor
				buLat2EndCsr( "root_uf_evo_de_buLat2ECsr" + sCh + "000" ) 	
				break

	
			case   88 :												// X 
				fXExpand( "BigStep_" + sCh + "000" ) 	
				break
			case 120 :												// x 
				fXExpand( "SmallStep_" + sCh + "000" ) 	
				break

			case  67 :												// C	
				fXCompress( "BigStep_" + sCh + "000" ) 								//     'BigStep'  is a keyword
				break
			case  99 :												// c
				fXCompress( "SmallStep_" + sCh + "000" ) 	
				break

			case  65 :												// A	
				fXAdvance( "BigStep_" + sCh + "000" ) 								//     'BigStep'  is a keyword
				break
			case  97 :												// a
			//case kARROWLEFT :												// Igor has reserved this for cursors				
				fXAdvance( "SmallStep_" + sCh + "000" ) 	
				break

			case  82 :												// R 
				fXReverse( "BigStep_" + sCh + "000" ) 	
			case 114 :												// r 
			//case kARROWRIGHT :										yy		// Igor has reserved this for cursors		
				fXReverse( "SmallStep_" + sCh + "000" ) 	
				break


			case   89 :												// Y 
				fYExpand(  "BigStep_" + sCh + "000"  ) 	
				break
			case 121 :												// y 
				fYExpand(  "SmallStep_" + sCh + "000" ) 	
				break

			case   83 :												// S
				fYShrink( "BigStep_" + sCh + "000" ) 	
				break
			case 115 :												// s
				fYShrink( "SmallStep_" + sCh + "000" ) 	
				break

			case  85 :												// U
				fYUp( "BigStep_" + sCh + "000" ) 	
				break
			case 117 :												// u
			case kARROWUP :
				fYUp( "SmallStep" + sCh + "000" ) 	
				break

			case  68 :												// D
				fYDown( "BigStep_" + sCh + "000" ) 	
				break
			case 100 :												// d
			case kARROWDOWN :
				fYDown( "SmallStep" + sCh + "000" ) 	
				break

			case   84 :												// T	
			case 116 :												// t
				break

			case  32 :												// 'SPACE'  
				break

		endswitch

	else																	// SPECIAL  2-KEY-PROCESSING

		// printf "\t\t\tfEvalWndNamedHook()\tExecuteActions() : 2 key processing \tCod:%3d,%3d:\t%s,%s\t \r ",  nKey1, nKey2, num2char(nKey1), num2char(nKey2)
		switch( nKey1 )
// SAMPLE code
//			case 104 :														// h
//				if ( 	nKey2 ==  66  ||   nKey2 ==  98 )								// B or b	Begin of Fit2 range  ( left  peak cursor )
//					buFit2BegCsr( "buFit2BegCsr" ) 	
//				elseif ( 	nKey2 ==  69  ||   nKey2 == 101 )							// E or e	End   of Fit2 range  ( right peak cursor )
//					buFit2EndCsr( "buFit2EndCsr" ) 	
//				endif
//				break

		endswitch
	endif
End

Function		Rescale( ch )
	variable	ch
	wave	wMagn	= root:uf:evo:evl:wMagn
	wMagn[ ch ][ cXSHIFT ]	= 0
	wMagn[ ch ][ cXEXP ]	= 1
	wMagn[ ch ][ cYSHIFT]	= 0
	wMagn[ ch ][ cYEXP ]	= 1
	RescaleAxisX( ch )
	RescaleAxisY( ch )
End

static Function		SetSameMagnification( MasterChan )
// set  X magnification and shift  of ALL Cfs channels  to magnification and shift  of master channel
	variable	MasterChan
	wave 	wMagn	= root:uf:evo:evl:wMagn
	nvar		gChans	= root:uf:evo:cfsr:gChannels					// set magnification of ALL Cfs channels..
	variable	ch
	for ( ch = 0; ch < gChans; ch += 1 ) 							//...even if they are currently turned off
		wMagn[ ch ][ cXSHIFT ]	=  wMagn[ MasterChan ][ cXSHIFT ]	
		wMagn[ ch ][ cXEXP ]	=  wMagn[ MasterChan ][ cXEXP ]
	endfor
End


Function		ResetDataBoundsX()		
	// Reset the X axis bounds which (only the  'kCATENATED' ) display mode would otherwise remember
	wave	wMnMx	= root:uf:evo:evl:wMnMx
	nvar		gChans	= root:uf:evo:cfsr:gChannels	
	variable	ch = 0
	for ( ch = 0; ch < gChans; ch += 1 ) 	
		wMnMx[ ch ][ MM_XMIN ]	=  inf
		wMnMx[ ch ][ MM_XMAX ]	=  -inf
	endfor
End


Function		SetDataBounds( wFlags, col, pl, ch, wDrawData, sFoDrawDataNm, dltaX, XaxisLeft, XaxisRight, nDispMode, bDispSkipped )
	wave 	wFlags
	string  	sFoDrawDataNm
	wave	wDrawData
	variable	col, pl, ch, dltaX, XaxisLeft, XaxisRight, nDispMode, bDispSkipped
						
	wave	wMnMx		= root:uf:evo:evl:wMnMx
	WaveStats  /Q wDrawData					
	wMnMx[ ch ][ MM_YMIN ]	=  V_min									// needed for scaling 		(also used to be workaround because GetAxis sometimes does not work)
	wMnMx[ ch ][ MM_YMAX]	=  V_max									// we compute the extrema once to save time
	SetXCursrOs( ch, XaxisLeft )										// to let the functions in Analyse_() access the parameter easily

	// In catenated  mode the axis borders extend from the first visible trace segment on the left to the last on the right
	if ( nDispMode == kCATENATED )
		// print "\t\tSetDataBounds(kCATENATED) 0  old  wMnMx[ ch ][ MM_XMIN ]", wMnMx[ ch ][ MM_XMIN ]	

		// Version 1:  by storing  minimum and maximum the range will always grow and never shrink, not even if an outer trace segment is removed. (However, it is possible to set a reduced X range with the SetVariable controls)   
		wMnMx[ ch ][ MM_XMIN ]	=  min( XaxisLeft, wMnMx[ ch ][ MM_XMIN ] )				
		SetXaxisLeft( ch, wMnMx[ ch ][ MM_XMIN ] )						// to let the functions in Analyse_() access the parameter easily
		wMnMx[ ch ][ MM_XMAX]	=  max( XaxisRight, wMnMx[ ch ][ MM_XMAX] )

		// Version 2:  loop through all visible trace segments and get minimum and maximum. Thus the range may grow and also shrink again  if an outer traces segment is removed 
		// 'SetDataBounds()'  works but is called too often when this function 'DSDisplayAndAnalyse()'  is called from 'RedrawWindows()' . In that case it would be sufficient to call  'SetDataBounds()'  only for the 1. and the last trace.
		//  This will be a problem if there are many trace segments AND if we are using Version 2 (where  'GetLeftRightOfAllTraces()'  loops through all traces).
//		variable 	rLeftMost, rRightMost
//		GetLeftRightOfAllTraces(  wFlags, col, pl, ch, bDispSkipped, rLeftMost, rRightMost ) 
//		wMnMx[ ch ][ MM_XMIN ]	=  min( XaxisLeft, rLeftMost )				
//		SetXaxisLeft( ch, wMnMx[ ch ][ MM_XMIN ] )						// to let the functions in Analyse_() access the parameter easily
//		wMnMx[ ch ][ MM_XMAX]	=  max( XaxisRight, rRightMost )

		// print "\t\tSetDataBounds(kCATENATED) 1    ->  wMnMx[ ch ][ MM_XMIN ]", wMnMx[ ch ][ MM_XMIN ] " = new XaxisLeft "	
	else
		SetXaxisLeft( ch, XaxisLeft )									// to let the functions in Analyse_() access the parameter easily
		wMnMx[ ch ][ MM_XMIN ]	=  XaxisLeft				
		wMnMx[ ch ][ MM_XMAX]	=  XaxisRight  // XaxisLeft + dltaX * V_npnts	
		if ( abs( leftX( wDrawData ) - XaxisLeft ) > abs(XaxisLeft) * 1e-2   ||   abs( rightX( wDrawData ) -  (XaxisLeft + dltaX * V_npnts) ) > abs( XaxisLeft + dltaX * V_npnts ) * 1e-2 )
			InternalError ( "DSDisplayAndAnalyse() SetDataBounds()" + sFoDrawDataNm + ": leftX() " + num2str( leftX( wDrawData ) ) + "=?=" +  num2str( XaxisLeft ) + " (=StartTm) ,  rightX() " +  num2str( rightX( wDrawData )  ) + "=?=" +   num2str( XaxisLeft + dltaX * V_npnts ) + " (=StT+dlta*Pts)" ) 
		endif
	endif
End						


static Function		RescaleBothAxisAllChans( MasterChan )
	variable	MasterChan
	nvar		gbSameTime	= $"root:uf:evo:de:cbSmeTm" + num2str( MasterChan ) + "000" 
	if ( gbSameTime )
		SetSameMagnification( MasterChan )	
	endif	
	nvar		gChans	= root:uf:evo:cfsr:gChannels
	variable	ch
	for ( ch = 0; ch < gChans; ch += 1 )
		RescaleAxisX( ch )
		RescaleAxisY( ch )
	endfor
End




//static Function		RescaleAxisX( ch )
	 Function		RescaleAxisX( ch )
// Change the X-axis limits according to the users commands   X - Expand  Shrink  Left  Right. Also adjust X-Axis Setvariable limit fields .
// RescaleAxisX()   and   fXAxis()  are interdependent  and must be changed together
	variable	ch
	string		sWNm	= CfsWndNm( ch ) 
	if ( WinType( sWNm ) == kGRAPH ) 					// the user may have killed the window
		wave	wMagn	= root:uf:evo:evl:wMagn
		wave	wCRegion	= root:uf:evo:evl:wCRegion
		variable	XaxisLeft	= wCRegion[ ch ][ 0 ][ 0 ][ CN_XAXLEFT ]	// todo 0,0,0
		RescaleXClipAndSetAxis( ch, wMagn[ ch ][ cXSHIFT ], XaxisLeft, sWNm )	// sets and possibly clips 'wMagn[ ch ][ cXSHIFT ]'
	endif
End

Function		RescaleClipSetAxisX( ch, xLeft, xRight, sWNm )
// sets and possibly clips 'wMagn[ ch ][ cXSHIFT ]'
	variable	ch, xLeft, xRight
	string  	sWNm 

	wave	wMagn		= root:uf:evo:evl:wMagn			// Update   wMagn[][]  and wMnMx[][]   with values  computed  from the settings in the  X-Axis Setvariable limit fields
	wave	wMnMx		= root:uf:evo:evl:wMnMx
	wMagn[ ch ][ cXEXP ]	= ( wMnMx[ ch ][ MM_XMAX  ] - wMnMx[ ch ][ MM_XMIN ] ) /  ( xRight - xLeft ) 
	wave	wCRegion		= root:uf:evo:evl:wCRegion
	variable	XaxisLeft		= wCRegion[ ch ][ 0 ][ 0 ][ CN_XAXLEFT ]	// todo 0,0,0
	RescaleXClipAndSetAxis( ch, xLeft - XaxisLeft ,  XaxisLeft, sWNm )	// sets and possibly clips 'wMagn[ ch ][ cXSHIFT ]'
	// printf "\t\t\tfXAxis()\t\tch:%2d \t left:\t%g\tright: %g\t->XEXP: %g \t XSHIFT: %g \r", ch, xLeft, xRight, wMagn[ ch ][ cXEXP ], wMagn[ ch ][ cXSHIFT ]
End

static Function		RescaleXClipAndSetAxis( ch, OldShift, XaxisLeft, sWNm )
// Clip  SHIFT value so that   XRight  never goes to the left of  XAxisLeft  when moving the trace to the left  and   XLeft  never goes to the right of  XAxisRight  when moving to the right
	variable	ch, OldShift, XaxisLeft
	string  	sWNm
	wave	wMagn	= root:uf:evo:evl:wMagn
	wave	wMnMx	= root:uf:evo:evl:wMnMx
	variable	ShiftMin		=  ( wMnMx[ ch ][ MM_XMIN ] - wMnMx[ ch ][ MM_XMAX ] )  /  wMagn[ ch ][ cXEXP ]  		// Empirical...........
	variable	ShiftMax		=    wMnMx[ ch ][ MM_XMAX ] - wMnMx[ ch ][ MM_XMIN ] 
	wMagn[ ch ][ cXSHIFT ] 	= min( max( .98 * ShiftMin + .02 * ShiftMax ,  OldShift )  , .98 * ShiftMax + .02 * ShiftMin )		// clip so that the trace never disappears completely
	variable	xLeft			=  XaxisLeft + wMagn[ ch ][ cXSHIFT ] 
	variable	xRight		=  XaxisLeft + wMagn[ ch ][ cXSHIFT ] +  ( wMnMx[ ch ][ MM_XMAX ] - wMnMx[ ch ][ MM_XMIN  ] ) / wMagn[ ch ][ cXEXP ]  

	 SetAxis	/Z /W = $sWNm  	bottom, 	xLeft, 	xRight
	// printf "\t\t\tRescaleXClipAndSetAxis( \t'%s'\tch:%d\t)	 \tXshf:\t%7.3lf  \t -> \t%7.3lf  \t(%7.3lf..\t%7.3lf) \tXexp:\t%7.3lf  \tXmin:\t%7.3lf  \tXmax:\t%7.3lf  \t->AxL:\t%7.3lf  \t... AxR:\t%7.3lf  \t \r", sWNm, ch, OldShift,  wMagn[ ch ][ cXSHIFT ], ShiftMin, ShiftMax, wMagn[ ch ][ cXEXP ],  wMnMx[ ch ][ MM_XMIN ],  wMnMx[ ch ][ MM_XMAX ],  xLeft , xRight

	// Update the X-Axis Setvariable limit fields with the new values which are computed and set according to the   wMagn[][]  and wMnMx[][]   values  which were computed  from the users  X-ESLR commands
	nvar	XAxLeft	= $"root:uf:evo:de:svXAxis" + num2str( ch ) + "000"		// e.g. for ch 0 :	$"root:uf:evo:de:svXAxis0000"
	nvar	XAxRight	= $"root:uf:evo:de:svXAxis" + num2str( ch ) + "001"		// e.g. for ch 1 :	$"root:uf:evo:de:svXAxis1001"
	XAxLeft	= xLeft
	XAxRight	= xRight
	// printf "\t\t\tRescaleXClipAndSetAxis()\tch:%2d \t left:\t%10.4g\tright:\t%10.4g\t<- XEXP:\t%10.4g\t XSHIFT:\t%10.4g\tXMIN:\t%10.4g\t XMAX:\t%10.4g\t \r", ch, xLeft, xRight, wMagn[ ch ][ cXEXP ], wMagn[ ch ][ cXSHIFT ], wMnMx[ ch ][ MM_XMIN  ], wMnMx[ ch ][ MM_XMAX  ]
End


Function		RescaleClipSetAxisY( ch,  yBott, yTop, sWNm )
// sets and possibly clips 'wMagn[ ch ][ cYSHIFT ]'
	variable	ch,  yBott, yTop
	string  	sWNm 
	SetAxis	/W=$sWNm  left, yBott, yTop			// change the graph immediately. Without this line the change would come into effect only later on the next  RescaleAxisY()

	// Update   wMagn[][]  and wMnMx[][]   with values  which were computed  from the settings in the  Y-Axis Setvariable limit fields
	wave	wMagn		= root:uf:evo:evl:wMagn
	wave	wMnMx		= root:uf:evo:evl:wMnMx
	wMagn[ ch ][ cYEXP ]	= ( wMnMx[ ch ][ MM_YMAX  ] - wMnMx[ ch ][ MM_YMIN ] ) /  ( yTop - yBott ) 
	wMagn[ ch ][ cYSHIFT ] 	=  yBott -  wMnMx[ ch ][ MM_YMIN ]		// Allow any value even if the trace is not visible. Any such value will be clipped so that the trace will be visible if the user executes one of..
														//...the following commands :Rescale, AutoSclY, Yshrink, Yexpand, Yup, Ydown  (these will call 'RescaleAxisY() where the clipping will be done).
	 // printf "\t\t\tfYAxis()\t\tch:%2d \t bott:\t%g\ttop: %g\t->YEXP: %g \t YSHIFT: %g \r", ch, yBott, yTop, wMagn[ ch ][ cYEXP ], wMagn[ ch ][ cYSHIFT ]
End

//static Function		RescaleAxisY( ch )
	 Function		RescaleAxisY( ch )
// Change the Y-axis limits according to the users commands   Y - Expand  Shrink  Up  Down.  Also adjust  Y-Axis SetVariable limit fields .
// RescaleAxisY()   and   fYAxis()  are interdependent  and must be changed together
	variable	ch
	string		sWNm	= CfsWndNm( ch ) 
	if ( WinType( sWNm ) == kGRAPH ) 					// the user may have killed the window
		wave	wMagn	= root:uf:evo:evl:wMagn
		wave	wMnMx	= root:uf:evo:evl:wMnMx
		// Clip  SHIFT value so that   Ymax never goes below  YAxisBottom when moving the trace down   and   Ymin  never goes above  YAxisTop  when moving up
		variable	OldShift		= wMagn[ ch ][ cYSHIFT ] 	
		variable	ShiftMin		=  ( wMnMx[ ch ][ MM_YMIN ] - wMnMx[ ch ][ MM_YMAX ] )  /  wMagn[ ch ][ cYEXP ]  
		variable	ShiftMax		=    wMnMx[ ch ][ MM_YMAX ] - wMnMx[ ch ][ MM_YMIN ] 
		wMagn[ ch ][ cYSHIFT ] 	= min( max( .98 * ShiftMin + .02 * ShiftMax ,  OldShift )  , .98 * ShiftMax + .02 * ShiftMin )		// clip so that the trace never disappears completely
		variable	yBott			=  wMnMx[ ch ][ MM_YMIN ] + wMagn[ ch ][ cYSHIFT ] 
		variable	yTop			=  wMnMx[ ch ][ MM_YMIN ] + wMagn[ ch ][ cYSHIFT ] +  ( wMnMx[ ch ][ MM_YMAX ] - wMnMx[ ch ][ MM_YMIN  ] ) / wMagn[ ch ][ cYEXP ]  

		SetAxis	/Z /W = $sWNm   left,  yBott,  yTop 
		// printf "\t\t\tRescaleAxisY( \t'%s'\tch:%d\t)	 \tYshf:\t%7.3lf  \t -> \t%7.3lf  \tYexp:\t%7.3lf  \tYmin:\t%7.3lf  \tYmax:\t%7.3lf  \t->AxB:\t%7.3lf  \t... AxT:\t%7.3lf  \t \r", sWNm, ch, OldShift, wMagn[ ch ][ cYSHIFT ], wMagn[ ch ][ cYEXP ],  wMnMx[ ch ][ MM_YMIN ] ,  wMnMx[ ch ][ MM_YMAX ] , yBott, yTop

		// Update the Y-Axis Setvariable limit fields with the new values which are computed and set according to the   wMagn[][]  and wMnMx[][]   values  which were computed  from the users  Y-ESUD commands
		// Problem: cannot update this Y-axix popupmenu field as simply as the X-axis setvariable field as the popupmenu field accepts only those round values which are initially contained in its list.
		// Solution 1: Round to the next popupmenu list value.
		// Solution 2: Also use a setvariable control for Y-axis as is used for X-axis
		// This works only with a Setvariable , this will NOT work with a Popupmenu : 
		 nvar	YAxTop	= $"root:uf:evo:de:svYAxis" + num2str( ch ) + "000"		// e.g. for ch 1 :	$"root:uf:evo:de:svXAxis1000"
		 nvar	YAxBott	= $"root:uf:evo:de:svYAxis" + num2str( ch ) + "010"		// e.g. for ch 0 :	$"root:uf:evo:de:svXAxis0010"
		 YAxBott	= yBott
		 YAxTop	= yTop
	endif
End

Function		AutoSclY( bChecked )
	variable	bChecked
	if ( bChecked )
		wave	wMagn	= root:uf:evo:evl:wMagn
		variable	ch
		nvar		gChans	= root:uf:evo:cfsr:gChannels					// check ALL Cfs channels..
		for ( ch = 0; ch < gChans; ch += 1 )
			wMagn[ ch ][ cYSHIFT]	= 0
			wMagn[ ch ][ cYEXP ]	= 1
			RescaleAxisY( ch )
		endfor
	endif
End


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  StimFit Clones   :	Functions to simulate StimFit as much as possible : Same keys and same actions

Function		fXAdvance__( s ) 
	struct	WMButtonAction	&s
	if (  s.eventCode == kCCE_mouseup ) 
		fXAdvance( s.ctrlName ) 
	endif
End
Function		fXAdvance( sctrlName ) 
	string		sctrlName
	variable	ch			= TabIdx( sctrlName )
	variable	factor		= cmpstr( sctrlName[ 0, 6 ], "BigStep" )  ?   kSHIFT_SMALLSTEP : kSHIFT_BIGSTEP			// .05  and  .25  
	DoWindow  /F   $EvalWndNm( ch )					// To have an effect on the trace we must bring the eval window to front and make it the active window. This is needed only if the user clicked into the panel for the command, not if he pressed a key.  
	XAdvance( ch, factor )
End
Function		XAdvance( ch, factor )
	variable	ch, factor
	wave	wMagn		= root:uf:evo:evl:wMagn
	wave	wMnMx		= root:uf:evo:evl:wMnMx
	wMagn[ ch ][ cXSHIFT]    +=  factor * ( wMnMx[ ch ][ MM_XMAX ] - wMnMx[ ch ][ MM_XMIN ] ) / wMagn[ ch ][ cXEXP ]	//  try to move trace to the left  5%  or  25% of  bottom axis...	
	// printf "\t\tXAdvance( ch:%2d )  Factor: %.3lf \r", ch, factor
	RescaleAxisX( ch )																			//...possibly  clip  here the cXSHIFT value
End				


Function		fXReverse__( s ) 
	struct	WMButtonAction	&s
	if (  s.eventCode == kCCE_mouseup ) 
		fXReverse( s.ctrlName ) 
	endif
End
Function		fXReverse( sctrlName ) 
	string		sctrlName 
	variable	ch			= TabIdx( sctrlName )
	variable	factor		= cmpstr( sctrlName[ 0, 6 ], "BigStep" )  ?   kSHIFT_SMALLSTEP : kSHIFT_BIGSTEP			// .05  and  .25  
	DoWindow  /F   $EvalWndNm( ch )					// To have an effect on the trace we must bring the eval window to front and make it the active window. This is needed only if the user clicked into the panel for the command, not if he pressed a key.  
	XReverse( ch, factor )
End
Function		XReverse( ch, factor )
	variable	ch, factor
	wave	wMagn		= root:uf:evo:evl:wMagn
	wave	wMnMx		= root:uf:evo:evl:wMnMx
	wMagn[ ch ][ cXSHIFT]    -=  factor * ( wMnMx[ ch ][ MM_XMAX ] - wMnMx[ ch ][ MM_XMIN ] ) / wMagn[ ch ][ cXEXP ]	//  try to move trace to the right  5%  or  25% of  bottom axis... 
	RescaleAxisX( ch )																			//...possibly  clip  here the cXSHIFT value
End


Function		fYUp__( s ) 
	struct	WMButtonAction	&s
	if (  s.eventCode == kCCE_mouseup ) 
		fYUp( s.ctrlName ) 
	endif
End
Function		fYUp( sctrlName ) 
	string		sctrlName
	variable	ch			= TabIdx( sctrlName )
	variable	factor		= cmpstr( sctrlName[ 0, 6 ], "BigStep" )  ?   kSHIFT_SMALLSTEP : kSHIFT_BIGSTEP			// .05  and  .25  
	DoWindow  /F   $EvalWndNm( ch )					// To have an effect on the trace we must bring the eval window to front and make it the active window. This is needed only if the user clicked into the panel for the command, not if he pressed a key.  
	YUp( ch, factor )
End
Function		YUp( ch, factor )
	variable	ch, factor
	wave	wMagn		= root:uf:evo:evl:wMagn
	wave	wMnMx		= root:uf:evo:evl:wMnMx
	wMagn[ ch ][ cYSHIFT]   -=  factor * ( wMnMx[ ch ][ MM_YMAX ] - wMnMx[ ch ][ MM_YMIN ] ) / wMagn[ ch ][ cYEXP ]	//  try to move trace up  5%  or  25%  of  left axis...	
	RescaleAxisY( ch )																			//...possibly  clip  here the cYSHIFT value
End


Function		fYDown__( s ) 
	struct	WMButtonAction	&s
	if (  s.eventCode == kCCE_mouseup ) 
		fYDown( s.ctrlName ) 
	endif
End
Function		fYDown( sctrlName ) 
	string		sctrlName
	variable	ch			= TabIdx( sctrlName )
	variable	factor		= cmpstr( sctrlName[ 0, 6 ], "BigStep" )  ?   kSHIFT_SMALLSTEP : kSHIFT_BIGSTEP			// .05  and  .25  
	DoWindow  /F   $EvalWndNm( ch )					// To have an effect on the trace we must bring the eval window to front and make it the active window. This is needed only if the user clicked into the panel for the command, not if he pressed a key.  
	YDown( ch, factor )
End
Function		YDown( ch, factor  )
	variable	ch, factor
	wave	wMagn		= root:uf:evo:evl:wMagn
	wave	wMnMx		= root:uf:evo:evl:wMnMx
	wMagn[ ch ][ cYSHIFT]   +=  factor * ( wMnMx[ ch ][ MM_YMAX ] - wMnMx[ ch ][ MM_YMIN ] ) / wMagn[ ch ][ cYEXP ]	//  try to move trace down  5%  or  25% of  left axis... 
	RescaleAxisY( ch )												//...possibly  clip  here the cXSHIFT value
End


Function		fXExpand__( s ) 
	struct	WMButtonAction	&s
	if (  s.eventCode == kCCE_mouseup ) 
		fXExpand( s.ctrlName ) 
	endif
End
Function		fXExpand( sctrlName ) 
	string		sctrlName
	variable	ch			= TabIdx( sctrlName )
	variable	factor		= cmpstr( sctrlName[ 0, 6 ], "BigStep" )  ?   kSCL_SMALLSTEP : kSCL_BIGSTEP	// appr.  3. root of 2  like Stimfit   or  2  	
	DoWindow  /F   $EvalWndNm( ch )					// To have an effect on the trace we must bring the eval window to front and make it the active window. This is needed only if the user clicked into the panel for the command, not if he pressed a key.  
	XExpand( ch, factor )
End
Function		XExpand( ch, factor )
	variable	ch, factor 
	wave	wCurRegion	= root:uf:evo:evl:wCurRegion
	wave	wMagn		= root:uf:evo:evl:wMagn
	wave	wMnMx		= root:uf:evo:evl:wMnMx
	variable	xAxVal		=  wCurRegion[ cXMOUSE ] 
	wave	wCRegion		= root:uf:evo:evl:wCRegion
	variable	XaxisLeft		= wCRegion[ ch ][ 0 ][ 0 ][ CN_XAXLEFT ]	// todo 0,0,0
	variable	xLeft			=  XaxisLeft + wMagn[ ch ][ cXSHIFT ] 
	variable	xRight		=  XaxisLeft + wMagn[ ch ][ cXSHIFT ] +  ( wMnMx[ ch ][ MM_XMAX ] - wMnMx[ ch ][ MM_XMIN  ] ) / wMagn[ ch ][ cXEXP ]  
	// same code as in RescaleAxisX( ch ) !!!  or   use    GetAxis  bottom ???		
	if ( xAxVal < xLeft  ||  xRight < xAxVal )			// if  xAxVal  is outside of screen..
		xAxVal = ( xLeft + xRight ) / 2			// ...then use a value in the middle of the screen
	endif

	wMagn[ ch ][ cXEXP ]	*= factor	
	wMagn[ ch ][ cXSHIFT ]	=  ( xAxVal - XaxisLeft ) * ( 1 - 1 / wMagn[ ch ][ cXEXP ] )

	RescaleAxisX( ch )												//...possibly  clip  here the cXSHIFT value
End


Function		fXCompress__( s ) 
	struct	WMButtonAction	&s
	if (  s.eventCode == kCCE_mouseup ) 
		fXCompress( s.ctrlName ) 
	endif
End
Function		fXCompress( sctrlName ) 
	string		sctrlName
	variable	ch			= TabIdx( sctrlName )
	variable	factor		= cmpstr( sctrlName[ 0, 6 ], "BigStep" )  ?   kSCL_SMALLSTEP : kSCL_BIGSTEP	// appr.  3. root of 2  like Stimfit   or  2  	
	DoWindow  /F   $EvalWndNm( ch )					// To have an effect on the trace we must bring the eval window to front and make it the active window. This is needed only if the user clicked into the panel for the command, not if he pressed a key.  
	XCompress( ch, factor )
End
Function		XCompress( ch, factor )
	variable	ch, factor
	wave	wCurRegion	= root:uf:evo:evl:wCurRegion
	wave	wMagn		= root:uf:evo:evl:wMagn
	wave	wMnMx		= root:uf:evo:evl:wMnMx
	variable	xAxVal		=   wCurRegion[ cXMOUSE ] 
	wave	wCRegion		= root:uf:evo:evl:wCRegion
	variable	XaxisLeft		= wCRegion[ ch ][ 0 ][ 0 ][ CN_XAXLEFT ]	// todo 0,0,0
	variable	xLeft		=  XaxisLeft + wMagn[ ch ][ cXSHIFT ] 
	variable	xRight	=  XaxisLeft + wMagn[ ch ][ cXSHIFT ] +  ( wMnMx[ ch ][ MM_XMAX ] - wMnMx[ ch ][ MM_XMIN  ] ) / wMagn[ ch ][ cXEXP ]  
	// same code as in RescaleAxisX( ch ) !!!  or   use    GetAxis  bottom ???		
	if ( xAxVal < xLeft  ||  xRight < xAxVal )			// if  xAxVal  is outside of screen..
		xAxVal = ( xLeft + xRight ) / 2			// ...then use a value in the middle of the screen
	endif

	wMagn[ ch ][ cXEXP ]       /= factor
	wMagn[ ch ][ cXSHIFT ]	=  ( xAxVal - XaxisLeft ) * ( 1 - 1 / wMagn[ ch ][ cXEXP ] )

	RescaleAxisX( ch )												//...possibly  clip  here the cXSHIFT value
End


Function		fYExpand__( s ) 
	struct	WMButtonAction	&s
	if (  s.eventCode == kCCE_mouseup ) 
		fYExpand( s.ctrlName ) 
	endif
End
Function		fYExpand( sctrlName ) 
	string		sctrlName
	variable	ch			= TabIdx( sctrlName )
	variable	factor		= cmpstr( sctrlName[ 0, 6 ], "BigStep" )  ?   kSCL_SMALLSTEP : kSCL_BIGSTEP	// appr.  3. root of 2  like Stimfit   or  2  	
	DoWindow  /F   $EvalWndNm( ch )					// To have an effect on the trace we must bring the eval window to front and make it the active window. This is needed only if the user clicked into the panel for the command, not if he pressed a key.  
	YExpand( ch, factor )
End
Function		YExpand( ch, factor )
	variable	ch, factor
	// print "YExpand  ch:",ch, "\tfactor:",factor 
	wave	wCurRegion	= root:uf:evo:evl:wCurRegion
	wave	wMagn		= root:uf:evo:evl:wMagn
	variable	yAxVal		=   wCurRegion[ cYMOUSE ] 
	wMagn[ ch ][ cYEXP ]	*= factor	
	wMagn[ ch ][ cYSHIFT ]	=  yAxVal
	RescaleAxisY( ch )												//...possibly  clip  here the cXSHIFT value
End


Function		fYShrink__( s ) 
	struct	WMButtonAction	&s
	if (  s.eventCode == kCCE_mouseup ) 
		fYShrink( s.ctrlName ) 
	endif
End
Function		fYShrink( sctrlName )
	string		sctrlName
	variable	ch			= TabIdx( sctrlName )
	variable	factor		= cmpstr( sctrlName[ 0, 6 ], "BigStep" )  ?   kSCL_SMALLSTEP : kSCL_BIGSTEP	// appr.  3. root of 2  like Stimfit   or  2  	
	DoWindow  /F   $EvalWndNm( ch )					// To have an effect on the trace we must bring the eval window to front and make it the active window. This is needed only if the user clicked into the panel for the command, not if he pressed a key.  
	YShrink( ch, factor )
End
Function		YShrink( ch, factor )
	variable	ch, factor
	// print "YShrink  ch:",ch, "\tfactor:",factor 
	wave	wCurRegion	= root:uf:evo:evl:wCurRegion
	wave	wMagn		= root:uf:evo:evl:wMagn
	variable	yAxVal		=   wCurRegion[ cYMOUSE ] 
	wMagn[ ch ][ cYEXP ]       /=  factor
	wMagn[ ch ][ cYSHIFT ]	=    yAxVal
	RescaleAxisY( ch )												//...possibly  clip  here the cYSHIFT value
End


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function		buCfsESC( ch )
	variable	ch
	QuitCursorPositioning( kCURSOR_DISCARD, ch )				// end the mode in which Igor moves Base/Peak/Latency cursors  and  do not save the last cursor

End

Function		buCfsCR( ch )
	variable	ch
	QuitCursorPositioning( kCURSOR_SAVE, ch )					// end the mode in which Igor moves Base/Peak/Latency cursors  and  save the last cursor
End

Function		buBaseBegCsr( ctrlName ) 
	string		ctrlName
	variable	ch		= TabIdx( ctrlName )
	FindAndMoveClosestCursor( ch, PH_BASE, kLEFT_CSR )		// Highlight  the Base begin cursor and allow moving it
End

Function		buBaseEndCsr( ctrlName ) 
	string		ctrlName
	variable	ch		= TabIdx( ctrlName )
	// print "buBaseEndCsr   ch:",ch, ctrlName
	FindAndMoveClosestCursor( ch, PH_BASE, kRIGHT_CSR )		// Highlight  the Base  end  cursor and allow moving it
End


Function		buPeakBegCsr( ctrlName ) 
	string		ctrlName
	variable	ch		= TabIdx( ctrlName )
	FindAndMoveClosestCursor( ch, PH_PEAK, kLEFT_CSR )		// Highlight  the Peak  begin cursor and allow moving it
End

Function		buPeakEndCsr( ctrlName ) 
	string		ctrlName
	variable	ch		= TabIdx( ctrlName )
	FindAndMoveClosestCursor( ch, PH_PEAK, kRIGHT_CSR)		// Highlight  the Peak  end  cursor and allow moving it
End


Function		buFit0BegCsr( ctrlName ) 
	string		ctrlName
	variable	ch		= TabIdx( ctrlName )
	FindAndMoveClosestCursor( ch, PH_FIT0, kLEFT_CSR )		// Highlight  the  FIT0   begin cursor and allow moving it
End

Function		buFit0EndCsr( ctrlName ) 
	string		ctrlName
	variable	ch		= TabIdx( ctrlName )
	FindAndMoveClosestCursor( ch, PH_FIT0, kRIGHT_CSR)		// Highlight  the  Fit0  end  cursor and allow moving it
End


Function		buFit1BegCsr( ctrlName ) 
	string		ctrlName
	variable	ch		= TabIdx( ctrlName )
	if ( ItemsInList( ksPHASES ) > PH_FIT1 )
		FindAndMoveClosestCursor( ch, PH_FIT1, kLEFT_CSR )	// Highlight  the  FIT1   begin cursor and allow moving it
	endif
End

Function		buFit1EndCsr( ctrlName ) 
	string		ctrlName
	variable	ch		= TabIdx( ctrlName )
	if ( ItemsInList( ksPHASES ) > PH_FIT1 )
		FindAndMoveClosestCursor( ch, PH_FIT1, kRIGHT_CSR)	// Highlight  the  Fit1  end  cursor and allow moving it
	endif
End

Function		buFit2BegCsr( ctrlName ) 
	string		ctrlName									// Fit2 is currently not used
	variable	ch		= TabIdx( ctrlName )
	if ( ItemsInList( ksPHASES ) > PH_FIT2 )
		FindAndMoveClosestCursor( ch, PH_FIT2, kLEFT_CSR )	// Highlight  the  FIT2   begin cursor and allow moving it
	endif
End

Function		buFit2EndCsr( ctrlName ) 
	string		ctrlName
	variable	ch		= TabIdx( ctrlName )					// Fit2 is currently not used
	if ( ItemsInList( ksPHASES ) > PH_FIT2 )
		FindAndMoveClosestCursor( ch, PH_FIT2, kRIGHT_CSR)	// Highlight  the  Fit2  end  cursor and allow moving it
	endif
End

Function		buLat0BegCsr( ctrlName ) 
	string		ctrlName
	variable	ch		= TabIdx( ctrlName )
	FindAndMoveClosestCursor( ch, PH_LATC0, kLEFT_CSR )		// Highlight  the Latency0  begin cursor and allow moving it
End

Function		buLat0EndCsr( ctrlName ) 
	string		ctrlName
	variable	ch		= TabIdx( ctrlName )
	FindAndMoveClosestCursor( ch, PH_LATC0, kRIGHT_CSR)		// Highlight  the Latency0  end  cursor and allow moving it
End

Function		buLat1BegCsr( ctrlName ) 
	string		ctrlName
	variable	ch		= TabIdx( ctrlName )
	FindAndMoveClosestCursor( ch, PH_LATC1, kLEFT_CSR )		// Highlight  the Latency1  begin cursor and allow moving it
End

Function		buLat1EndCsr( ctrlName ) 
	string		ctrlName
	variable	ch		= TabIdx( ctrlName )
	FindAndMoveClosestCursor( ch, PH_LATC1, kRIGHT_CSR)		// Highlight  the Latency1  end  cursor and allow moving it
End


Function		buLat2BegCsr( ctrlName ) 
	string		ctrlName
	variable	ch		= TabIdx( ctrlName )
	FindAndMoveClosestCursor( ch, PH_LATC2, kLEFT_CSR )			// Highlight  the Latency2  begin cursor and allow moving it
End

Function		buLat2EndCsr( ctrlName ) 
	string		ctrlName
	variable	ch		= TabIdx( ctrlName )
	FindAndMoveClosestCursor( ch, PH_LATC2, kRIGHT_CSR)			// Highlight  the Latency2  end  cursor and allow moving it
End

// 051110b  TODO:  either convert to a button  OR  ensure that all channels always automatically have the same time scaling if it is a checkbox and the checkbox is  ON
Function 		fSameTime( s )
	struct	WMCheckboxAction	&s
	variable	ch		= TabIdx( s.ctrlName )
	// print "fSameTime( s )   ch:", ch, s.CtrlName
	RescaleBothAxisAllChans( ch )
End

//=================================================================================================

static constant	kCURSOR_DISCARD = 0, kCURSOR_SAVE = 1

static Function	FindAndMoveClosestCursor( ch, ph, nCsr )
	variable	ch, ph, nCsr
	wave	wCurRegion	= root:uf:evo:evl:wCurRegion

	QuitCursorPositioning( kCURSOR_SAVE, ch )						// 051020  End the mode in which Igor moves Base/Peak/Latency cursors  and  save the last cursor

	DoWindow  /F   $EvalWndNm( ch )							// To allow cursor movement we must bring the eval window to front and make it the active window. This is needed only if the user clicked into the panel for the command, not if he pressed a key.  

	variable	nCurSwp		= wCurRegion[ kCURSWP ]		
	variable	nSize		= wCurRegion[ kSIZE ]		
	 printf "\tFindAndMoveClosestCursor( \t\t\t\t\tch:%d \t\t\tph:%d\t %s\tCursor%2d %s ):\tnCurSwp:%3d\tnSize:%3d\t \r", ch, ph, pd( StringFromList( ph, ksPHASES ), 8 ), nCsr, SelectString( nCsr, "A", "B" ), nCurSwp, nSize
	variable	rg 			= FindClosestRegion( ch, ph, nCsr )
	MoveCursor( ch, rg, ph, nCsr, nCurSwp, nSize )
End


static Function	QuitCursorPositioning( bSaveCursor, ch_passed )
// Finish positioning ONE cursor by shrinking the crosshair to normal cursor. Store the last cursor position in its corresponding region.
	variable	bSaveCursor
	variable	ch_passed									// 051110  test : is useless  and can be removed!) as it may be the (changed) new current window whereas we need the previous window to set the cursors
	wave	wPrevRegion	= root:uf:evo:evl:wPrevRegion
	variable	ch			= wPrevRegion[ cCH ]				// has previously been stored during 'MoveCursor()'
	variable	rg			= wPrevRegion[ cRG ]				// ...
	variable	ph			= wPrevRegion[ cPH ]				// ...
	variable	nCsr			= wPrevRegion[ cCURSOR ]			// ...

	string  	sCursorAorB	= SelectString( nCsr, "A", "B" )			// 0 is cursor A, 1 is cursor B 
	string		sWndNm 		= CfsWndNm( ch )

	if ( WinType( sWndNm ) == kGRAPH )							// the user may have killed the graph with the unfinished crosshair cursor

		variable CursorExists= strlen( CsrInfo( $sCursorAorB, sWndNm ) ) > 0	// the 1. parameter (cursor A or B) is a name, not a string
		if ( CursorExists )

			if ( bSaveCursor )
				SetRegionBegEnd( ch, rg, ph, CN_BEG   + nCsr, hcsr( $sCursorAorB, sWndNm ) )	
				SetRegionBegEnd( ch, rg, ph, CN_BEGY + nCsr, vcsr( $sCursorAorB, sWndNm ) )	
			endif
			Cursor 	/W=$sWndNm /K  $sCursorAorB				// Remove the crosshair cursor from the graph
// 051020
			HideInfo	/W=$sWndNm								// Remove the Cursor control box  (this control box is not mandatory for cursor usage) ...

			DisplayHideCursor( ch, rg, ph, CN_BEG + nCsr, sWndNm, ON)	// display cursor at new location immediately
			 printf "\tQuitCursorPositioning( bDoSave:%2d )  retrieves  \tch:%d   \trg:%d   \tph:%d\t %s\tCursor%2d %s \t\tch_passed:%2d\r", bSaveCursor, ch, rg, ph, pd (StringFromList( ph, ksPHASES ), 8), nCsr, sCursorAorB, ch_passed
		else
			printf "\tQuitCursorPositioning( bDoSave:%2d )  failed in graph '%s'  :  cursor  '%s'  does  not exist. \t\t\t\tch_passed:%2d\r", bSaveCursor, sWndNm, sCursorAorB, ch_passed
		endif
	else
		printf "\tQuitCursorPositioning( bDoSave:%2d )  failed as graph '%s'  could not be found. \t\tch_passed:%2d\r", bSaveCursor, sWndNm	, ch_passed
	endif
End


static Function	MoveCursor( ch, rg, ph, nCsr, nCurSwp, nSize )
	variable	 ch, rg, ph, nCsr, nCurSwp, nSize
	variable	xPhCsr	= RegionBegEnd( ch, rg, ph, CN_BEG   + nCsr )
	string  	sWndNm	= CfsWndNm( ch )

// 051013
	DisplayHideCursor( ch, rg, ph, CN_BEG + nCsr, sWndNm, ON ) 	// TODO obsolete=????? cosmetics: clear old region or cursor immediately
	string		sWvNm		= OrgWvNm(ch, nCurSwp, nSize ) 
	variable	rRed, rGreen, rBlue
	EvalRegionColor( ch, rg, ph, rRed, rGreen, rBlue )

	wave	wPrevRegion	= root:uf:evo:evl:wPrevRegion
	wPrevRegion[ cCH ]		= ch							// save until 'QuitCursorPositioning()'
	wPrevRegion[ cRG ]		= rg							// save until 'QuitCursorPositioning()'
	wPrevRegion[ cPH ]		= ph							// ...
	wPrevRegion[ cCURSOR ]	= nCsr 						// ...

	 printf "\tMoveCursor( \t\t\t\t\t\t\t\t\tch:%d   \trg:%d   \tph:%d\t %s\tCursor%2d %s   \tnCurSwp:%3d\tnSize:%3d\t \r", ch, rg, ph, pd (StringFromList( ph, ksPHASES ), 8), nCsr, SelectString( nCsr, "A", "B" ), nCurSwp, nSize

	// Cursor /F /W=$CfsWndNm( ch ) /A=1 /H=1 /S=1 /L=0  /C=(rRed, rGreen, rBlue)  A, $sWvNm, xPhCsr, yPhCsr	// draw the 'Free' crosshair cursor
	// Cursor	  /W=$CfsWndNm( ch ) /A=1 /H=1 /S=1 /L=0  /C=(rRed, rGreen, rBlue)  A, $sWvNm, xPhCsr		// draw the 'locked-to-wave' crosshair cursor
	string  	sCursorAorB	= SelectString( nCsr, "A", "B" )

// 051020
	ShowInfo	/W= $sWndNm  							// Display Igors cursor control box. This is not mandatory for cursor usage.
	Cursor	/W = $sWndNm /A=1 /H=1 /S=1 /L=0  /C=(rRed, rGreen, rBlue)  $sCursorAorB, $sWvNm, xPhCsr		// draw the 'locked-to-wave' crosshair cursor

	// Now we are in  Igors 'Cursor' mode.  Igor allows moving its cursor with the mouse or with the arrow keys
	// It is our responsability to quit the 'Cursor' mode,  e.g. by  pressing  CR/Enter, by pressing ESC  or by releasing (or clicking) the mouse  
End

static Function	FindClosestRegion( ch, ph, nCsr )
// If there is more than 1 region in the actice graph/channel then select the one which is closest to the cursor
	variable	ch, ph, nCsr
	wave	wCurRegion	= root:uf:evo:evl:wCurRegion
	variable	xAxVal		= wCurRegion[ cXMOUSE ]
	variable	xPhCsr
	variable	rg, ClosestRegion = 0, ClosestDistance = Inf
	variable	rgCnt		= RegionCnt( ch )
	for ( rg = 0; rg < rgCnt; rg += 1 )
		xPhCsr	= RegionBegEnd( ch, rg, ph, CN_BEG   + nCsr )
		if ( abs( xPhCsr - xAxVal ) < ClosestDistance )
			ClosestDistance = abs( xPhCsr - xAxVal )
			ClosestRegion	= rg
			// printf "\t\t\t\tFindClosestRegion( ch:%d , ph:%d \t( %s )\t, nCsr:%d \t( %s )\t ) \tXCsr:\t%7.3lf \tXReg:\t%7.3lf \tXDelta:\t%7.3lf\t \r", ch, ph, StringFromList( ph, ksPHASES), nCsr, StringFromList( nCsr, ksLR_CSR), xAxVal, xPhCsr, ClosestDistance 
		endif
	endfor
	// printf "\t\t\t\tFindClosestRegion( ch:%d , ph:%d \t( %s )\t, nCsr:%d \t( %s )\t ) returns closest region %d. (rgCnt:%d) \r", ch, ph, StringFromList( ph, ksPHASES), nCsr, StringFromList( nCsr, ksLR_CSR), ClosestRegion, rgCnt	
	return	ClosestRegion
End
	
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////


