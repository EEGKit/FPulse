//  FPEVAL.IPF 

// 040921 todo : see RP_HEADER.....

// 
// 0302 Data evaluation procedures (IGOR version closely resembling Pascal STIMFIT)
//
// History: 

//You can kill two birds with one stone if you use the menus in parallel with your buttons.  If you have a button named "button0", 
//which calls the function or procedure named "buttonproc", then you should be able to make a menu like this to duplicate the effect of clicking the button:
//
//
//Menu "Buttons"

//Menu "Buttons"
//        "Next /x", 	buDispCfsNextData("buDispCfsNextData")
//        "Next /q", 	buDispCfsNextData("buDispCfsNextData")
//        "Next /c", 	buDispCfsNextData("buDispCfsNextData")
//        "Next /0", 	buDispCfsNextData("buDispCfsNextData")
//        "Next /" + num2char( 49), 	buDispCfsNextData("buDispCfsNextData")		//    Next /1
//        "&Next",	buDispCfsNextData("buDispCfsNextData")
//        "Prev /9",	buDispCfsPrevData("buDispCfsPrevData")
//        "Pre&v",	buDispCfsPrevData("buDispCfsPrevData")
//End


//        "Run button 0/<ascii key>", buttonproc("button0")
//End
//
//
//Sending the name to the button procedure is only necessary if you use one procedure for multiple buttons, and the control name is how you distinguish them. 
// If the button procedure ignores the ctrlname parameter (as mine usually do), you can pass an empty string.
//
//
//One problem with this solution is that as far as I know, the only unused ascii keys are the numbers 0-9, so unless these are 
//coincidentally the only control keys your DOS program uses, I don't think your users are going to be any happier memorizing 
//a whole new set of key controls.  And 10 ctrl keys may not be enough if you don't want to use a mouse.


// todo   checkbox   ShowInfo  on/off


#pragma rtGlobals=1							// Use modern global access method.
strconstant	sTABLEEXT	= "fit"
strconstant	ksAVGEXT	= "avg"
constant		cBGCOLOR	= 60000		// 55000 = medium grey , 60000 = light grey
static	 constant	LEFT = 8, 		TOP = 4, 		RIGHT = 2, 	BOT = 1	// Region display: these values detemine which lines will be shown 
static	 constant	LINENODOTS 	= 0, FINESTDOTS = 1, FINEDOTS = 2, MEDIUMDOTS = 3, COARSEDOTS = 7, VERYCOARSEDOTS = 8	// Region display
constant 		cBASE_SLICES			= 4	// for baseline evaluation: divide baseline region in so many pieces and analyse and compare them separately
//constant		cSIDE_PTS_TO_ADD	= 2	// 3 is too many for real data for fine evaluation : reduce noise influence to peak value by averaging so many point on each side (2 is too small for test data)
constant		RG_MAX				= 3	// maximum number of regions per channel ( 050216 max. 1digit!)
constant		FIT_MAX				= 3	// maximum number of fits per region ( 050216 max. 1digit!)
static	constant	cCH	= 0,	cRG	= 1, 	cPH	= 2, cCURSOR = 3, cXMOUSE = 4, cYMOUSE = 5, cMODIF = 6, cMAXCURRG = 7	// index for wCurRegion ans wPrevRegion
 
// DIFF  BSBEG  BSEND
// Indexing for parameters extracted initially from  (extended)  WaveStats : wWSOrg  holds  statistics params from original data, wWSSmooth from  noise-reduced data
static constant		wsBEG = 0, wsEND = 1, wsXSCL = 2, wsPTS = 3, wsZIG = 4, wsDEV = 5, wsAVG = 6, wsRMS = 7, wsMIN = 8, wsMAX = 9, wsMINL = 10, wsMAXL = 11, wsMAXWS = 12 
static strconstant	sWS	= " bg; en; xs; pt; zg; dv; av; rm; mi; ma; mil; mal"

// Indexing for  wMnMx:
static constant		MM_XMIN = 0, MM_XMAX = 1, MM_YMIN = 2, MM_YMAX = 3, MM_XYMAX = 4

// Indexing for finally extracted evaluation parameters:
static constant		cT = 1, cPT = 2, cY = 3, cVAL = 4, cSHOW = 5, EV_MAXTYP = 6		//todo let slope also store BASE NOISE 
static constant		EV_BBEG = 0,  EV_BEND = 1,   EV_BRISE = 2,   EV_RISE20 = 3,   EV_RISE50 = 4,  EV_RISE80 = 5,  EV_RISSLP = 6,  EV_PEAK = 7,  EV_DEC50 = 8,  EV_DECSLP = 9
static constant		EV_TIME = 10, EV_AMPL = 11,  EV_MEAN = 12, EV_RT2080 = 13, EV_LATC1 =14, EV_LATC2 = 15,  EV_HALDU =16, EV_SLOP =17,  EV_BASE =18,  EV_SDBASE =19
static constant		EV_MAXPTS = 20
//static strconstant	sEVMASK1	= " 1	;	2	;	4	;		8	;		16	;		32	;		64	;		128		;	256		;	512	"
static strconstant	sEVA	= "BB;BE;BR;R2;R5;R8;RS;P1;D5;DS;P2"
static strconstant	sEVAL	= " BsBeg; BsEnd; BsRise; RT20; RT50; RT80; RiseMxSlp; Peak; DT50; DecMxSlp;Time/;Ampl/;Mean/;RT2080/;Latenc1/;Latenc2/;HalDu/;SlopR/D;Base;SDBase"
//							BaseBeg, RT50 , Peak
static strconstant	lstEVAL_PRINTALL	= "	0; 	1;	2;	3;	4;	5;	6;	7;	8;	9;	10; 	11;	12;	13;	14;	15;	16;	17;	18;	19"
static strconstant	lstEVAL_PRINTFILE	= "	10; 	11;	12;	13;	14;	15;	16;	17;	18;	19"	// used in table file
static strconstant	lstEVAL_PRINTSCR1= "	11;	12;	13;	14;	15;	16;	17;	1;	19; 	7"	// used as one and only screen line
static strconstant	lstEVAL_PRINTSCR2a= "	11;	12;	13;	14;	15;	16;	17"				// used as first screen line
static strconstant	lstEVAL_PRINTSCR2b= "	1;	19"									// used as second screen line


//     File        Event #       Time/       Ampl/       Mean/     RT2080/    Latenc1/    Latenc2/      HalDu/     SlopR/D        Base      SDBase      FITPAR
//    230103~1           1   55981.417       34.76       33.48      0.9781    -39.8753    -24.7000     17.9486      1.0000      -32.73        1.08
//    230103~1           2   55983.267       37.15       34.93      0.9543    -39.8259    -31.1000     17.8858      0.3571      -34.10        1.14

//		fprintf nRefNum, "     File        Event #       Time/       Ampl/       Mean/     RT2080/    Latenc1/    Latenc2/      HalDu/     SlopR/D        Base      SDBase      FITPAR\r"
// not yet used
//strconstant lstCOLS =	"     File        Event #       Time/       Ampl/       Mean/     RT2080/    Latenc1/    Latenc2/      HalDu/     SlopR/D        Base      SDBase      FITPAR"
//constant	cFILE=0, cEVENT=1, cTIME=2, cAMPL=3, cMEAN=4, cRT2080=5, cLATENC1=6, cLATENC2=7, cHALDU=8, cSLOPRD=9, cBASE=10, cSDBASE=11, cFITPAR=12

// Possible drawing parameters using Igor's markers
static constant		cNONE = 0, cRECT = 13, cSLINEH = 9, cSLINEV = 10, cLLINEH = -9, cLLINEV = -10, cSCROSS = 0, cCIRCLE = 41 , cXCROSS = 1// , cFCROSS = 12, cLCROSS = 24

// Indexing for channels
static constant		CH_ONOFF = 0,  CH_RGCNT = 1,  CH_YAXISMIN = 2,  CH_YAXISMAX = 3
static strconstant	ksCHANS	= "OnOff;RgCnt;YAxMin;YAxMax;"


// Indexing for phase/region ( also working for cursors which are sort of generalized/specialized regions ):
static constant		PH_BASE = 0, PH_PEAK = 1, PH_LATCSR = 2, PH_FIT0 = 3,  PH_FIT1 = 4 ,  PH_FIT2 =  5		// The fits must be the last entries as their number ...
static strconstant	ksPHASES	= "Base;Peak;LatencyCsr;Fit0;Fit1;Fit2;"								//... is determined by counting from the end

// Indexing for controls and values:
// Indexing for ChannelRegion Evaluation ( CN_BEG and  CN_END , CN_BEGY and  CN_ENDY  must be successive
static constant		CN_VISIBLE = 0,  CN_BEG = 1, CN_END = 2, CN_BEGY = 3, CN_ENDY = 4, CN_ISUP = 5,  CN_CHK_NS = 6, CN_LIM_A = 7,  CN_USHI = 8, CN_USLO = 9
static constant		CN_COLOR = 10, CN_CSRSHAPE = 11, CN_CSRCNT = 12,  CN_LO = 13,		CN_RES = 15, CN_FITFNC = 16 , CN_FITRANGE = 17 
static constant		CN_MAX = 18
static strconstant	sCN_TEXT	= "unused;Beg;End;BegY;EndY;IsUp;ChkNs;LimAuto;UserHi;UserLo;Color;Shape;CsrCnt;Lo;  ;Res;FitFnc;FitRange"
// strconstant	sCN_COLOR	= ";;;;;;;;;;;;;;;;cRED;cBLUE;;;;"
// strconstant	sCN_SHAPE	= ";;;;;;;;;;;;;;;;cRECT;cCIRCLE;;;;"
// strconstant	sCN_PRINT	= ";;1;0,;;1;;;0;;;;;;;;"


// Indexing for the evaluation cursor shape
static constant		CSR_STUBS = 4, CSR_VALSHORT = 8, CSR_VALMEDIUM = 16, CSR_VALFULL = 32, CSR_YSHORT = 64, CSR_YFULL = 128


// Popupmenu indexing for fit functions
static constant		FT_NONE = 0, FT_LINE = 1, FT_1EXP = 2, FT_1EXPCONST = 3, FT_2EXP = 4, FT_2EXPCONST = 5, FT_RISE = 6, FT_RISECONST = 7,  FT_RISDEC = 8, FT_RISDECCONST = 9//, FT_FNCMAX = 10 
// todo 040804 combine with OLA  or separate strictly.........
strconstant		sFITFUNC	= "none;Line;1 Exp;1 Exp+Con;2 Exp;2 Exp+Con;Rise;Rise+Con;RiseDec;RiseDecCon"		// SAME as in PANEL,  cannot be static

static constant		kSTARTOK = 0 ,  kFITERROR = 1 ,  kNUMITER = 2 ,  kMAXITER = 3 , kCHISQ = 4  ,  kMAXFITINFO = 5		// indices for wInfo

// Popupmenu indexing for the fit range
static constant		FR_WINDOW	= 0, FR_CSR = 1, FR_PEAK = 2
 strconstant        	ksFITRANGE	= "Rn:Window;Rng:Cursor;Rng:Peak"										// cannot be static

// Popupmenu indexing for the latency cursor
static constant		LC_MANUAL	= 0, LC_PEAK = 1, LC_RISE = 2
strconstant		sLATCSR		= "LC:Manual;LC:Peak;LC:Rise"												// cannot be static

// Popupmenu indexing for result printing
// 040921 todo Separate or unify   RP_HEADER = 1, RP_HEADER2 = 2 
// 2 popups for printing ? ( for History and for Textbox) ?  Or 1 popup, History may display more information  and must display channel ?   Some entries (e.g. RP_BASEPEAK1 = 4, RP_BASEPEAK2 = 8, RP_EVALVERt, RP_TIMES ) are only for debug / history , not for textbox .  
constant			RP_NONE	= 0, RP_HEADER = 1, RP_EVSCR1 = 2, RP_EVSCR2 = 4, RP_CURSORINFO = 8, RP_FITSTART = 16, RP_FIT = 32,  RP_EVFILE = 64, RP_EVALVERT = 128, RP_TIMES = 256, RP_BASEPEAK1 = 512, RP_BASEPEAK2 = 1024 		// only powers of 2 can be added to give..
 strconstant		ksPRINTMASKS	= "   0	;   1	   ;  3      ;     35     ;   43           ; 32 ;    48      ; 	  49   ;   	34	   ;     51	    	   ;   8 ;  5       ; 64;  128     ; 256   ;  	512      ; 	1024	    ; 2047  "		// cannot be static as it is used in Window macro					// ..arbitrary combinations  ,   cannot be static
 strconstant		ksPRINTRESULTS	= "nothing;Header;StimFit;Standard;Stand+Info;Fit  ;Fit + Start;H+Fit+Start;Fit + Results;H+Fit+St+Res;Info;Stimfit2;File;EvalVert;Times;BasePeak1;BasePeak2;Print All"		// cannot be static

//constant			RP_NONE	= 0, RP_HEADER = 1, RP_FITSTART = 16, RP_FIT = 32, RP_EVSCR1 = 64, RP_EVSCR2 = 128, RP_CURSORINFO = 256, RP_EVFILE = 512, RP_EVALVERT = 1024, RP_TIMES = 2048, RP_BASEPEAK1 = 4096, RP_BASEPEAK2 = 8192 		// only powers of 2 can be added to give..
// strconstant		ksPRINTMASKS	    = "   0	;   1	 ; 32 ;    48	; 	49	     ;   	96	   ;     113	    	;     97     ;   353		; 256;  64   ;  129  ; 512;  1024  ; 2048 ; 3071;   	4096	; 	8192	  "		// cannot be static as it is used in Window macro					// ..arbitrary combinations  ,   cannot be static
// strconstant		ksPRINTRESULTS = "nothing;Header;Fit  ;Fit + Start;aH+Fit+Start;Fit + Results;aH+Fit+St+Res;aStandard;aStand+Info;Info;Stimfit;aStimfit2;File;EvalVert;Times;Print All;BasePeak1;BasePeak2"		// cannot be static

//constant			RP_NONE	= 0, RP_HEADER = 1, RP_HEADER2 = 2, RP_BASEPEAK1 = 4, RP_BASEPEAK2 = 8, RP_FITSTART = 16, RP_FIT = 32, RP_EVSCR1 = 64, RP_EVSCR2 = 128, RP_CURSORINFO = 256, RP_EVFILE = 512, RP_EVALVERT = 1024, RP_TIMES = 2048 		// only powers of 2 can be added to give..
// strconstant		ksPRINTMASKS	    = "   0	;   1	 ;     2      ;   	4	; 	8	  ; 32 ;    48	; 	51	     ;   	96	   ;     115	    	;     99     ;   355		; 256;  64   ;  131  ; 512;  1024  ; 2048 ; 3071"		// cannot be static as it is used in Window macro					// ..arbitrary combinations  ,   cannot be static
// strconstant		ksPRINTRESULTS = "nothing;Header;AHeader2;BasePeak1;BasePeak2;Fit  ;Fit + Start;aH+Fit+Start;Fit + Results;aH+Fit+St+Res;aStandard;aStand+Info;Info;Stimfit;aStimfit2;File;EvalVert;Times;Print All"		// cannot be static

// Indexing for magnify
//static constant	cXSHIFT = 0, cXEXP = 1, cXFIXED = 2, cYSHIFT = 3, cYEXP = 4, cYFIXED = 5, cMAX_MAGN = 6  
static constant		cXSHIFT = 0, cXEXP = 1, cYSHIFT = 2, cYEXP = 3, cMAX_MAGN = 4  


// Popupmenu indexing for Y axis end values
strconstant		ksYAXIS	= "auto;10000;5000;2000;1000;500;200;100;50;20;10;5;2;1;-1;-2;-5;-10;-20;-50;-100;-200;-500;-1000;-2000;-5000;-10000"


strconstant		ksPEAKDIR 	= "Peak down;Peak up"

static constant		kLEFT_CSR = 0,	kRIGHT_CSR = 1
static strconstant	ksLR_CSR	="left;right"


constant	kFI_ON = 0  	// the only variable stored in wChRgFit	


Function		CreateGlobalsInFolder_SubEvl( sFolder )
// creates all folder-specific variables. To be used once from CreateGlobals() as the current data folder is changed and not restored
	string  	sFolder
	NewDataFolder  /O  /S $"root:uf:" + sFolder + ":evl"			// Evaluation (offline) : make a new data folder and use as CDF

//	variable	/G	gChans								// number of channels to be evaluated will be set when CFS file hase been read (same as 'root:uf:cfsr:gChannels' )

	// Globals for stand-alone Panel controls which are NOT controlled  by the huge WCRegion wave because they are outside the channel/region/phase ordering
	variable	/G	gbDoEvaluation		= FALSE				// the user can turn the evaluation off just for viewing the data. This prevents fitting and speeds things up.
	variable	/G	gFitCnt			= 1					// Number of Fit ranges offered per Region.  Maximum is 3.
	variable	/G	gPrintMask		= 1					// controls the amount of result printing
	variable	/G	gPkSidePts		= 2					// additional points on each side of a peak averaged to reduce noise errors 
	variable	/G	gbSameMagn		= TRUE				// time of 2. channel always same as 1. channel
	variable	/G	gbShowAverage	= TRUE				// 
// For   Data Section Selection
	variable	/G	gLBRange			= 1					// 0 : show columns iup to selected,  1: show all columns
	variable	/G	gnWndNumber		= 0					// The initial popmenu value must correspond and must be 1 more !!! 
	variable	/G	gnDisplayMode		= 1					// 0:single, 1:stacked, 2:catenated. The initial popmenu value must correspond and must be 1 more !!!
	variable	/G	gnActiveCol		= 3					// 1:Prot, 	 2:Block, 	 3:Frame.	     This initial popmenu value must correspond and must be the same (special case as index 0 is missing in the list) !!!
	variable	/G	gbDispUnselect		= 1					// display  also  the unselected traces in a different color,  the selected traces are always drawn
	variable	/G	gAvgKeepCnt		= 0					// number of currently averages traces in memory
	string  	/G	gsAvgNm			= ""					// the user may override the auto-built name for the averaged traces
	variable	/G	gEvaluatedCnt		= 0					// 0 means start a new result file xxx_n.fit 
	variable	/G	gTblKeepCnt		= 0					// 0 means start a new result file xxx_n.fit 
	variable	/G	gbMultipleKeeps	= FALSE
	variable	/G	gpStartValsOrFit		= 0					// 0 : do not fit, display only starting values, 1 : do fit
	variable	/G	gpDispTracesOrAvg	= 0					// 0 : only traces, 1: traces + average,  2 : only average
	variable	/G	gpLatencyCsr		= LC_MANUAL
	variable	/G	gpPrintResults		= 7					// Initial index into 'ksPRINTRESULTS' popup defining which data are printed. 
	variable	/G	gbResTextbox		= TRUE				// display or hide the evaluation results in the textbox in the graph window
// evl
	make /O /T  /N = ( cMAXCHANS )							wCurrAvgFile	= ""	// could be combined with an additional index...
	make /O /T  /N = ( cMAXCHANS )							wCurrTblFile	= ""	//.........
	make /O  	    /N = ( cMAXCHANS,  cMAX_MAGN )				wMagn		= 0	// for  x and y  shifting and expanding the view
	make /O  	    /N = ( cMAXCURRG ) 							wPrevRegion	= 0	// saves channel, region, phase and CursorIndex when moving a cursor so that this previous cursor can be finished when the user fast-switches to a new cursor without 'ESC' e.g. 'b' 'B'. 
	make /O  	    /N = ( cMAXCURRG ) 							wCurRegion	= 0	// saves channel, modifier and mouse location when clicking a window to remember the 'active' graph when a panel button is pressed
	make /O  	    /N = ( cMAXCHANS, MM_XYMAX )				wMnMx		= TRUE// maximum X and Y data limits  and   whether  the display should be  'Reset' to these limits

	variable	nPH_MAX	= ItemsInList( ksPHASES )
	variable	nCH_MAX	= ItemsInList( ksCHANS )									// the number of different entries in wChanOpts
	make /O 	    /N = ( cMAXCHANS, nCH_MAX ) 					wChanOpts=Nan	// Channel options: OnOff, number of Regions, Y axis min and max values
	make /O 	    /N = ( cMAXCHANS, RG_MAX, nPH_MAX, CN_MAX  )	wCRegion	= 1		// region coordinates, drawing environment, number of phases in each region, whether the peak goes up or down, ...
	make /O 	    /N	 = ( cMAXCHANS, RG_MAX, EV_MAXPTS, EV_MAXTYP) wEval = Nan	// Nan means this coord could not be evaluated


// 050216
	make /O 	    /N = ( cMAXCHANS, RG_MAX )			wChRg	=  kAC_HIDE	// 0 or 1 : this region is defined for this channel or not
// 050216  either 1 dim less (see wChRg )  or  incorporate into wcregion..............(additional index required)
	make /O 	    /N = ( cMAXCHANS, RG_MAX, FIT_MAX, 1  )	wChRgFit	= kAC_HIDE		// 0 or 1 : this fit is defined for this channel and region or not


	// Drawing parameters for evaluated data points:	BASBEG  BASEND   BRISE 1RISE20  1RISE50  	1RISE80   1RISSLP   1PEAK   		1DEC50   1DECSLP    TIME,	AMPL,	MEAN,	RT2080 ,	LATC1,	LATC2,	HALDU,	SLOP,	BASE,	SDBASE=19
	make /O /N = ( EV_MAXPTS ) wEvalColor	 = {  cGreen, 	cGreen,   cBBlue , cDBlue , cDBlue,		cDBlue, 	cDCyan, 	cRed,		cGreen,	cCyan,	cCyan }	//  Peak displayed by small cross
//	make /O /N = ( EV_MAXPTS ) wEvalShapeold={cLLINEH, cLLINEH, cRECT, cCIRCLE, cSLINEH, 	cCIRCLE,	cXCROSS,cSCROSS	,	cSLINEH,	cXCROSS,cNONE,	cNONE,	cNONE,	cNONE,	cNONE,	cNONE,	cNONE,	cNONE,	cNONE,	cNONE	}
	make /O /N = ( EV_MAXPTS ) wEvalShape = { cLLINEH,  cLLINEH, cRECT, cCIRCLE, cSLINEH,	cCIRCLE,	cRECT,	cSCROSS,	cSLINEV, cSLINEV,	cNONE,	cNONE,	cNONE,	cNONE,	cNONE,	cNONE,	cNONE,	cNONE,	cNONE,	cNONE	}

	// Initialisation values 
	variable	ch
	for ( ch = 0; ch < cMAXCHANS; ch += 1 )
		wMagn[ ch ][ cXSHIFT ]	= 0
		wMagn[ ch ][ cXEXP ]	= 1
		wMagn[ ch ][ cYSHIFT]	= 0
		wMagn[ ch ][ cYEXP ]	= 1
		// 050216
		wChRg[ ch ][ 0 ] = kAC_UNCHECKED					// 050216  the 1. region checkbox must be accessible initially.  All other are accessible once the 1. one is tirned on.
		variable rg
		for ( rg = 0; rg < RG_MAX; rg += 1 )
			wChRgFit[ ch ][ rg ][ 0 ][ kFI_ON ] = kAC_UNCHECKED		// 050216  the   1.   fit  checkbox   must be accessible initially.  All other are accessible once the 1. one is tirned on.
		endfor

	endfor

	wChanOpts[ 0 ][ CH_ONOFF ]		= 1		// 1 : display this channel  window (and its accompanying regions in panel)  
	wChanOpts[ 0 ][ CH_YAXISMIN ]	= 0		// 0 is 'auto . The index of the popup listbox ( counting starts at 0 )
	wChanOpts[ 0 ][ CH_YAXISMAX ]	= 0		// 0 is 'auto . The index of the popup listbox ( counting starts at 0 )
	wChanOpts[ 0 ][ CH_RGCNT ]		= 1		// 1..3 regions are possible.
	
	// Initialisation values :
	//	chan 0	region 0
	wCRegion[ 0 ][ 0 ][ PH_BASE ][ CN_CHK_NS]		= TRUE
	wCRegion[ 0 ][ 0 ][ PH_BASE ][ CN_LIM_A ]		= TRUE
	wCRegion[ 0 ][ 0 ][ PH_BASE ][ CN_CSRCNT ]		= 2	
	wCRegion[ 0 ][ 0 ][ PH_BASE ][ CN_CSRSHAPE]	= CSR_YSHORT + CSR_STUBS + CSR_VALSHORT // CSR_VALMEDIUM

	CopyToAllChansRegionsFromBase()

	wCRegion[ 0 ][ 0 ][ PH_PEAK ][ CN_ISUP ]			= FALSE
	wCRegion[ 0 ][ 0 ][ PH_PEAK ][ CN_CSRCNT ]		= 2	
	wCRegion[ 0 ][ 0 ][ PH_PEAK ][ CN_CSRSHAPE]	= CSR_YSHORT + CSR_VALSHORT

	wCRegion[ 0 ][ 0 ][ PH_LATCSR][ CN_CSRCNT]		= 1	
	wCRegion[ 0 ][ 0 ][ PH_LATCSR][ CN_CSRSHAPE]	= CSR_YFULL + CSR_VALSHORT+ CSR_STUBS

	wCRegion[ 0 ][ 0 ][ PH_FIT0   ][ CN_CSRCNT ]		= 2	
	wCRegion[ 0 ][ 0 ][ PH_FIT0   ][ CN_CSRSHAPE]	= CSR_YSHORT + CSR_STUBS
	wCRegion[ 0 ][ 0 ][ PH_FIT0   ][ CN_FITFNC ]		= FT_LINE
	wCRegion[ 0 ][ 0 ][ PH_FIT1   ][ CN_CSRCNT ]		= 2	
	wCRegion[ 0 ][ 0 ][ PH_FIT1   ][ CN_CSRSHAPE]	= CSR_YSHORT// + CSR_STUBS
	wCRegion[ 0 ][ 0 ][ PH_FIT1   ][ CN_FITFNC ]		= FT_LINE
	wCRegion[ 0 ][ 0 ][ PH_FIT2   ][ CN_CSRCNT ]		= 2	
	wCRegion[ 0 ][ 0 ][ PH_FIT2   ][ CN_CSRSHAPE]	= CSR_YSHORT + CSR_STUBS
	wCRegion[ 0 ][ 0 ][ PH_FIT2   ][ CN_FITFNC ]		= FT_NONE

CopyToAllChansRegions()

	SetPhColor( PH_BASE, 	cGreen )
	SetPhColor( PH_PEAK, 	cRed )
	SetPhColor( PH_LATCSR, 	cBlue )
	SetPhColor( PH_FIT0, 	cMag )
	SetPhColor( PH_FIT1,	cCyan )
	SetPhColor( PH_FIT2, 	cOrange )

	//	chan 0	region 1
	wCRegion[ 0 ][ 1 ][ PH_FIT0 ][ CN_FITFNC ]		= FT_RISE
	wCRegion[ 0 ][ 1 ][ PH_FIT1 ][ CN_FITFNC ]		= FT_NONE
	wCRegion[ 0 ][ 1 ][ PH_FIT2 ][ CN_FITFNC ]		= FT_NONE

	//	chan 1	region 0
//	wCRegion[ 1 ][ 0 ][ PH_BASE ][ CN_CHK_NS]		= TRUE		// use or ignore noise limits in the baseline (and possibly discard noisy records)
//	wCRegion[ 1 ][ 0 ][ PH_BASE ][ CN_LIM_A]			= TRUE		// use automatically  determined limits for the noise check or use limits set by the user
	wCRegion[ 1 ][ 0 ][ PH_FIT0 ][ CN_FITFNC ]		= FT_RISE
	wCRegion[ 1 ][ 0 ][ PH_FIT1 ][ CN_FITFNC ]		= FT_RISDEC 	// Rise, Decay, etc. combined with Fit function or other evaluation e.g.  RISE_FitHH, DEC_FitExp1, DEC_FitEx2
	wCRegion[ 1 ][ 0 ][ PH_FIT2 ][ CN_FITFNC ]		= FT_NONE 	// Rise, Decay, etc. combined with Fit function or other evaluation e.g.  RISE_FitHH, DEC_FitExp1, DEC_FitEx2
	
End


static Function		CopyToAllChansRegionsFromBase()
	wave	wCRegion		= root:uf:eval:evl:wCRegion
	variable	ch, rg, ph, typ
	variable	nPH_MAX		= ItemsInList( ksPhases )
	for ( ch = 0; ch < cMAXCHANS; ch += 1 )
		for ( rg = 0; rg < RG_MAX; rg += 1 )
			for ( ph = 0; ph < nPH_MAX; ph += 1 )
				for ( typ = 0; typ < CN_MAX; typ += 1 )
					wCRegion[ ch ][ rg ][ ph ][ typ ]	= wCRegion[ 0 ][ 0 ][ PH_BASE ][ typ ]	
				endfor		
			endfor		
		endfor		
	endfor		
End

static Function		CopyToAllChansRegions()
	wave	wCRegion		= root:uf:eval:evl:wCRegion
	variable	ch, rg, ph, typ
	variable	nPH_MAX	= ItemsInList( ksPhases )
	for ( ch = 0; ch < cMAXCHANS; ch += 1 )
		for ( rg = 0; rg < RG_MAX; rg += 1 )
			for ( ph = 0; ph < nPH_MAX; ph += 1 )
				for ( typ = 0; typ < CN_MAX; typ += 1 )
					wCRegion[ ch ][ rg ][ ph ][ typ ]	= wCRegion[ 0 ][ 0 ][ ph ][ typ ]	
				endfor		
			endfor		
		endfor		
		variable	type, typeCnt	= ItemsInList( ksCHANS )
		wave	wChanOpts	= root:uf:eval:evl:wChanOpts
		for ( type = 0; type < typeCnt; type += 1 )
			wChanOpts[ ch ][ type ]	= wChanOpts[ 0 ][ type ]	
		endfor
	endfor		
End



static Function		CursorsAreSet( ch )
	variable	ch 
	wave	wCRegion		= root:uf:eval:evl:wCRegion
	variable	rg = 0
	variable	csrPos	= wCRegion[ ch ][ rg ][ PH_BASE ][ CN_BEG ]
	if ( csrPos == wCRegion[ ch ][ rg ][ PH_BASE ][ CN_END ]  && csrPos == wCRegion[ ch ][ rg ][ PH_PEAK ][ CN_BEG ] && csrPos == wCRegion[ ch ][ rg ][ PH_PEAK ][ CN_END ] )
		return	FALSE	// if beginning and end of base and peak regions are the same we assume that these are the startup values meaning that no region has been set
	endif
	return	TRUE
End


static Function		AutoSetCursorsAllChans()
	variable	ch
	for ( ch = 0; ch < cMAXCHANS; ch += 1 )
		AutoSetCursors( ch )
	endfor
End

static Function		AutoSetCursors( ch )
// Spread Base, Peak and Latency cursor (at least for first region) to reasonable values ( X between 1%, 10%, 30% of X full scale ) independent of actual time range.
// The cursors are placed not too close so that the user has no difficulties picking a certain cursor.
// ToDo/ToImprove: Do search the peak and place the cursors accordingly.
	variable	ch
	wave	wCRegion		= root:uf:eval:evl:wCRegion
	variable	rg, ph
	variable	nPH_MAX		= ItemsInList( ksPhases )
// 040915
//	wave	wMnMx	= root:uf:eval:evl:wMnMx
//	variable	AxisRange	= wMnMx[ ch ] [ MM_XMAX ] - wMnMx[ ch ] [ MM_XMIN ]
//	if ( TRUE ) // Axis does REALLY exist. Even for an empty graph Igor claims V_Flag=0 (=axis exists), although there is no (visible) axis, but the values are Nan.
//		//printf "\t\t\tAutoSetCursors() in top graph '%s' . X axis exists:%d .  Has  X axis range : %g  \r", sTopGraph, !V_Flag, AxisRange

	string		sFoldOrgWvNm	= FoOrgWvNm( ch )
	wave	wOrg 		= $sFoldOrgWvNm
	variable	AxisRange		= numPnts( wOrg ) * deltaX( wOrg )
		
	if ( AxisRange > 0 )
		for ( rg = 0; rg < RG_MAX; rg += 1 )
			for ( ph = 0; ph < nPH_MAX; ph += 1 )
				// The first region takes up the 40% of the graph for the cursors. 
				nvar		gFitCnt	= root:uf:eval:evl:gfitCnt
				if ( rg == 0  &&  ph == PH_BASE )
					wCRegion[ ch ][ rg ][ ph ][ CN_BEG ]	= .01 * AxisRange
					wCRegion[ ch ][ rg ][ ph ][ CN_END ]	= .08 * AxisRange
				elseif ( rg == 0  &&  ph == PH_LATCSR ) 
					wCRegion[ ch ][ rg ][ ph ][ CN_BEG ]	= .10 * AxisRange
				elseif ( rg == 0  &&  ph == PH_PEAK )
					wCRegion[ ch ][ rg ][ ph ][ CN_BEG ]	= .12 * AxisRange
					wCRegion[ ch ][ rg ][ ph ][ CN_END ]	= .20 * AxisRange
				elseif ( rg == 0  &&  ph == PH_FIT0  &&  gFitCnt >= 1 )
					wCRegion[ ch ][ rg ][ ph ][ CN_BEG ]	= .22 * AxisRange
					wCRegion[ ch ][ rg ][ ph ][ CN_END ]	= .26 * AxisRange
				elseif ( rg == 0  &&  ph == PH_FIT1  &&  gFitCnt >= 2 )
					wCRegion[ ch ][ rg ][ ph ][ CN_BEG ]	= .28 * AxisRange
					wCRegion[ ch ][ rg ][ ph ][ CN_END ]	= .32 * AxisRange
				elseif ( rg == 0  &&  ph == PH_FIT2  &&  gFitCnt >= 3 )
					wCRegion[ ch ][ rg ][ ph ][ CN_BEG ]	= .34 * AxisRange
					wCRegion[ ch ][ rg ][ ph ][ CN_END ]	= .38 * AxisRange
				else
				// The remaining regions share the last 60% of the graph for the cursors. 
					wCRegion[ ch ][ rg ][ ph ][ CN_BEG ]	= (  .40 + (rg-1) *.60 / ( RG_MAX - 1 ) + ph * .05 ) 	* AxisRange	// up 4 phases provided, must be (automatically?) spaced closer if more are to be used 
					wCRegion[ ch ][ rg ][ ph ][ CN_END ]	= (  .40 + (rg-1) *.60 / ( RG_MAX - 1 ) + ph * .05 + .03 ) * AxisRange
				endif
			endfor		
		endfor		
		printf "\t\t\tAutoSetCursors( ch:%d   wave:'%s' )  has  X axis range : %g : OK	\r", ch, sFoldOrgWvNm, AxisRange
	else
		printf "\t\t\tAutoSetCursors( ch:%d   wave:'%s' )  has  X axis range : %g : FAILED \r", ch, sFoldOrgWvNm, AxisRange
	endif
End

static Function		SetPhColor(  ph, nColor )
	variable	ph, nColor
	wave	wCRegion		= root:uf:eval:evl:wCRegion
	variable	ch, rg
	for ( ch = 0; ch < cMAXCHANS; ch += 1 )
		for ( rg = 0; rg < RG_MAX; rg += 1 )
			wCRegion[ ch ][ rg ][ ph ][ CN_COLOR ]	= nColor	
		endfor		
	endfor		
End


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//    MAIN  EVALUATION  FUNCTION

Function	/S	FoOrgWvNm( ch )
	variable	ch
	return	"root:uf:eval:evl" + ksF_SEP + "wOrg" + num2str( ch )	// name must be unique for each channel
End

Function	/S	OrgWvNm( ch )
	variable	ch
	return	"wOrg" + num2str( ch )	// name must be unique for each channel
End


Function		Analyse( wBig, ch, nChannels, nOfsPts, nPts, nSmpInt, gDataSections ) 
	wave	wBig
	variable	ch, nChannels, nOfsPts, nPts, nSmpInt, gDataSections 

	string		sMsg
	variable	rLeft, rRight, rTop, rBot
	variable	msBeg, msEnd
	variable	rg = 0, rgCnt
//	nvar		gChans		= root:uf:cfsr:gChannels				// The number channels in eval: must be updated both in  'InitPanelEvalDetails()' and  'Analyse()'...
//	gChans				= nChannels						//...as either may be called first. (Or replace all occurrences of  'cfsr:gChannels'  by  'cfsr:gChannels' )

	nvar		gPrintMask	= root:uf:eval:evl:gprintMask
	nvar		gPkSidePts	= root:uf:eval:evl:gpkSidePts			// additional points on each side of a peak averaged to reduce noise errors 
	nvar		gTblKeepCnt	= root:uf:eval:evl:gTblKeepCnt			// 0 means start a new result file xxx_n.fit
	wave	wMnMx		= root:uf:eval:evl:wMnMx
	wave	wChanOpts	= root:uf:eval:evl:wChanOpts
	wave	wCRegion		= root:uf:eval:evl:wCRegion

	string		sWndNm		= CfsWndNm( ch )
	string		sOrgWvNm	= OrgWvNm( ch )					// wave name without folder
	string		sFoldOrgWvNm	= FoOrgWvNm( ch )
	duplicate	/O /R=[ nOfsPts, nOfsPts + nPts - 1 ]  wBig  $sFoldOrgWvNm// the copied region has an unique wave name for each channel
	wave	wOrg 		= $sFoldOrgWvNm

	variable	dltaX			= nSmpInt / cXSCALE			
	variable	StartTime 		= 0								// Display every sweep start at 0 ms . Comment this line to display the true sweep start time (magnifying regions will not work!)
	//StartTime= nOfsPts * dltaX								// UNFINISHED....Display every sweep start at the real time (but excluding blank periods...)
	SetScale /P X, StartTime, dltaX, cXUNIT,  wOrg  

	WaveStats  /Q wOrg					
	wMnMx[ ch ] [ MM_YMIN ]	=  V_min						// needed for scaling 		(also used to be workaround because GetAxis sometimes does not work)
	wMnMx[ ch ] [ MM_YMAX ]=  V_max						// we compute the extrema once to save time
	wMnMx[ ch ] [ MM_XMIN ]	=  StartTime				
	wMnMx[ ch ] [ MM_XMAX ]=  StartTime + dltaX * V_npnts	
	//printf "\tAnalyse() WndNm:%s\tch:%d  StartTime:%6.1lf\t..%6.1lf\tnOfsPts:%4d  \tnPts:%4d  nSmpInt:%d  dltaX:%.4lf=?=%.4lf \r", pd( sWndNm,16), ch, StartTime, StartTime + dltaX * V_npnts, nOfsPts, nPts, nSmpInt, dltaX  , deltaX( wOrg ) 

	// if ( nPts != numpnts(wOrg) )							// could not duplicate the specified number of points because we are at the end of the source wave...
	//	Alert( cMESSAGE,  "End of data" )					// ...normally the management of the Prot/Frame/Sweep-numbers takes care that this never happens when ONE sweep is the unit, ...
	//	return 0										// ...but it may occur in the special case (e.g. File 80702.dat) with interleaved data when reading 2 or more sweeps as the smallest unit. 
	// endif											

	if ( ! CursorsAreSet( ch ) )
		AutoSetCursors( ch )
	endif

	if ( gPrintMask &  RP_HEADER )
		string	sText = PrintEvalTBHeader( ch )	+  "\r"
		printf "%s", sText
		printf "\tAnalyse # \tKeeps:%2d \tAvgs:%2d  %s\r", gTblKeepCnt, AvgCnt() , pd( sOrgWvNm, 9)
	endif

//	DisplayAverage( ch )									// needed because all traces in the window are cleared before displaying new data

	string  	sTNL	= TraceNameList( sWndNm, ";", 1 )
	if ( WhichListItem( sOrgWvNm, sTNL, ";" )  == cNOTFOUND )	// ONLY if  wave is not in graph...
		AppendToGraph  /W=$sWndNm  /C=( 0, 0, 0 )	wOrg		// ...append data wave in black. wOrg contains folder.
		ModifyGraph 	  /W=$sWndNm  axisEnab( left )={ 0, 0.85 }	// 0.9 : leave 10% space on top for textbox ( 0.8 is better for windows lower than 1/3 screen height )
	endif

	variable	YAxisMinIndex	= wChanOpts[ ch ][ CH_YAXISMIN ]
	variable	YAxisMinValue	= str2num( StringFromList( YAxisMinIndex, ksYAXIS ) )
	// printf "\t\tAnalyse() \tPopup AxisMin ( ch:%d ) : %g    [index:%d]  (nan  is auto)\r", ch, YAxisMinValue, YAxisMinIndex 
	if ( numtype( YAxisMinValue ) == cNUMTYPE_NAN )			// this is the  'auto'  value
		YAxisMinValue	=  wMnMx[ ch ] [ MM_YMIN ]
	endif

	variable	YAxisMaxIndex	= wChanOpts[ ch ][ CH_YAXISMAX ]
	variable	YAxisMaxValue	= str2num( StringFromList( YAxisMaxIndex, ksYAXIS ) )
	// printf "\t\tAnalyse() \tPopup AxisMax ( ch:%d ) : %g    [index:%d]   (nan  is auto)\r", ch, YAxisMaxValue, YAxisMaxIndex 
	if ( numtype( YAxisMaxValue ) == cNUMTYPE_NAN )			// this is the  'auto'  value
		YAxisMaxValue	=  wMnMx[ ch ] [ MM_YMAX ]
	endif
	SetAxis	 	  /W=$sWndNm  left, YAxisMinValue, YAxisMaxValue
	
	// If the BASE evaluation is disabled, all following evaluations (Peak1, Peak2,...) must be disabled too because the baseline value is required
	// if we allow disabling the BASE evaluation we should alert the user:  Peak evaluation in Panel must be greyed/disabled or checkmark must automatically removed
	
	rgCnt		= wChanOpts[ ch ][ CH_RGCNT ]
	for ( rg = 0; rg < rgCnt;  rg += 1 )	

		// 2  Draw the evaluation ranges : duration of baseline, time when slope to peak1 (and  peak 2) starts, ... 
		// MUST NEVER EXTEND INTO THE RISING PHASE (optimum is extremum in between artefact and signal peak)
		// 3	Compute the BASE value
		
		//RegionX( ch, rg, PH_BASE, msBeg, msEnd )				// get the beginning and end of base evaluation region 
		if ( RegionX( ch, rg, PH_BASE, msBeg, msEnd ) == FALSE )		// check if the base evaluation region exists and get the beginning and end of this region
			AutoSetCursors( ch )
			RegionX( ch, rg, PH_BASE, msBeg, msEnd )				// get the beginning and end of base evaluation region 
		endif

		if (   wCRegion[ ch ][ rg ][ PH_BASE ][ CN_CHK_NS ] )
			if (   wCRegion[ ch ][ rg ][ PH_BASE ][ CN_LIM_A ] )
				AutomaticBaseRegion( wOrg, ch, rg, msBeg, msEnd, rTop, rBot ) // guess the allowed baseline band from the noise in the given interval[ BaseL, BaseR ]
				SetRegionY( ch, rg, PH_BASE, rTop, rBot )
				//SetEvalRegionParams( ch, rg, PH_BASE, 2, cBRed, 	FINEDOTS,  .15,  LEFT+TOP+RIGHT+BOT )
				//SetEvalRegionParams( ch, rg, PH_BASE,   .15,  LEFT+TOP+RIGHT+BOT )
				DisplayCursors( ch, rg, PH_BASE )		// automatic mode: draw differently
			else
				UserRegionBaseY( ch, rg, PH_BASE, rTop, rBot )	// get the user's Hi and Lo values  (stored separately so that they don't get overwritten when the user..
				SetRegionY( ch, rg, PH_BASE, rTop, rBot )			//...switches temporarily into 'auto' mode   and copy them into the evaluation region 
				//SetEvalRegionParams( ch, rg, PH_BASE, 2, cOrange, 	FINEDOTS,  .15,  LEFT+TOP+RIGHT+BOT )
				//SetEvalRegionParams( ch, rg, PH_BASE,  .15,  LEFT+TOP+RIGHT+BOT )
				DisplayCursors( ch, rg, PH_BASE ) 		// user has set time and Y region: draw differently
			endif
			EvaluateBase( wOrg, ch, rg, StartTime,  ON ) 
		else
			SetRegionY( ch, rg, PH_BASE, (wOrg(msBeg) + wOrg(msEnd))/2, (wOrg(msBeg) + wOrg(msEnd))/2 )	//around the trace
			//SetEvalRegionParams( ch, rg, PH_BASE, 2, cYellow, 	LINENODOTS,  .15,  LEFT+TOP+RIGHT+BOT )
			//SetEvalRegionParams( ch, rg, PH_BASE,   .15,  LEFT+TOP+RIGHT+BOT )
			DisplayCursors( ch, rg, PH_BASE ) 			// user has only set time region: draw differently
			EvaluateBase( wOrg, ch, rg, StartTime,  OFF ) 
		endif

		// 4	ConfidenceBand
		//ConfidenceBand( wOrg, rBaseNoise )	// not used (too slow)	//todo let slope also store BASE NOISE
	
		// 6	Evaluate Peak1
		// 6a	 Evaluate the true minimum and maximum peak value and location by removing the noise in a region around the given approximate peak location 
		RegionX( ch, rg, PH_PEAK, rLeft, rRight )	// get the beginning of the Peak1 evaluation region (=rLeft)
		EvaluatePeak( wOrg, ch, rg, PH_PEAK, rLeft, rRight, gPkSidePts, EV_PEAK ) 
		SetRegionY( ch, rg, PH_PEAK, EvY( ch, rg, EV_PEAK ), EvY( ch, rg, EV_PEAK ) )	// cosmetics: set the evaluated peak value as top and bottom of evaluation region to show the user the value (additionally to circle...)
		DisplayCursors( ch, rg, PH_PEAK )
	 
		// 6b	 Compute the real levels in the rising and falling phases of a UP  or  DOWN peak
		variable	Val20, Val50, Val80, 	rLoc20, rLoc50, rLoc80
		Val20	=  EvY( ch, rg, EV_BEND ) * 4 / 5  +  EvY( ch, rg, EV_PEAK ) * 1 / 5
		Val50	=  EvY( ch, rg, EV_BEND ) * 1 / 2  +  EvY( ch, rg, EV_PEAK ) * 1 / 2
		Val80	=  EvY( ch, rg, EV_BEND ) * 1 / 5  +  EvY( ch, rg, EV_PEAK ) * 4 / 5
	
		// 6c  Evaluation to find the rise start location ( smoothed rise-baseline crossing next to peak location, exists always )
		RegionX( ch, rg, PH_PEAK, rLeft, rRight )	// get the beginning of the Peak1 evaluation region (=rLeft)
		variable	bPeakIsUp = wCRegion[ ch ][ rg ][ PH_PEAK ][ CN_ISUP ]
		EvaluateCrossing( wOrg, ch, rg, bPeakIsUp, "Rise",  rLeft, EvT( ch, rg, EV_PEAK ), 20, Val20, EV_RISE20 ) 
		EvaluateCrossing( wOrg, ch, rg, bPeakIsUp, "Rise",  rLeft, EvT( ch, rg, EV_PEAK ), 50, Val50, EV_RISE50 ) 
		EvaluateCrossing( wOrg, ch, rg, bPeakIsUp, "Rise",  rLeft, EvT( ch, rg, EV_PEAK ), 80, Val80, EV_RISE80 ) 
		EvaluateSlope(	   wOrg, ch, rg, PH_PEAK, bPeakIsUp, "Rise",  rLeft, EvT( ch, rg, EV_PEAK ), EV_RISSLP ) 
		
		// 6d  Get intersection of  baseline  and  line going through RT20 and RT80 
		variable	RISE20orRISE50 = ExistsEvT( ch, rg, EV_RISE20 )  ?   EV_RISE20  :  EV_RISE50					// the 20% crossing may not exist BUT the 50% CROSSING IS ASSUMED TO EXIST
		FourPointIntersection( ch, rg, EV_BBEG, EV_BEND, RISE20orRISE50, EV_RISE80,  EV_BRISE ) 

		// 6e  Risetime 20 to 80
		if ( ExistsEvT( ch, rg, EV_RISE80 )  &&   ExistsEvT( ch, rg, EV_RISE20 )  )
			SetEval( ch, rg, EV_RT2080, cVAL, EvT( ch, rg, EV_RISE80 )  - EvT( ch, rg, EV_RISE20 ) )
		endif
		
		// 6h  Evaluation to find the decay end location ( smoothed decay-baseline crossing next to peak location, may not exist )
		variable locEndDecay 
		FindLevel	/Q /R=( EvT( ch, rg, EV_PEAK ) , Inf)  wOrg, EvY( ch, rg, EV_BEND )	// try to find time when decay crosses baseline ( may not exist )
		if ( V_flag )
			sprintf sMsg, "Decay did not find BaseLevel Crossing (%.1lf) after %.1lfms  (smoothing till end...) ", EvY( ch, rg, EV_BEND ), EvT( ch, rg, EV_PEAK )  
			Alert( cLESSIMPORTANT,  sMsg )
			locEndDecay = Inf
		endif
		locEndDecay  = V_LevelX
		EvaluateCrossing( wOrg, ch, rg, bPeakIsUp, "Decay",  EvT( ch, rg, EV_PEAK ) , locEndDecay, 50, Val50, EV_DEC50 ) 
		EvaluateSlope(	   wOrg, ch, rg, PH_PEAK, bPeakIsUp, "Decay",  EvT( ch, rg, EV_PEAK ) , locEndDecay, EV_DECSLP ) 
	
//		// 8	Evaluate the series resistance measuring peak2 at the end
//			RegionX( ch, rg, PH_PEAK2, rLeft, rRight )					// get the beginning and the end of the Peak2 evaluation region (=rLeft)
//			EvaluatePeak( wOrg, ch, rg, PH_PEAK2, rLeft, rRight, 0, c2PEAK )	// the series resistance measuring Peak2 at the end ( we use 0 SidePts because we know that it is a sharp asymmetric peak)
//			SetRegionY( ch, rg, PH_PEAK2, EvY( ch, rg, c2PEAK ), EvY( ch, rg, c2PEAK ) )	// cosmetics: set the evaluated peak value as top and bottom of evaluation region to show the user the value (additionally to circle...)
//			DisplayCursors( ch, rg, PH_PEAK2, TRUE ) 


		// 10a  Half duration
		if ( ExistsEvT( ch, rg, EV_DEC50 )  &&   ExistsEvT( ch, rg, EV_RISE50 )  )
			SetEval( ch, rg, EV_HALDU, cVAL, EvT( ch, rg, EV_DEC50 )  - EvT( ch, rg, EV_RISE50 ) )
		endif
		// 10b  Latency1
		if ( ExistsEvT( ch, rg, EV_BRISE ) )
			SetEval( ch, rg, EV_LATC1, cVAL, EvT( ch, rg, EV_BRISE ) )		// todo    wrong
		endif
		// 10b  Base and Peak
		if ( ExistsEvY( ch, rg, EV_BEND )  &&  ExistsEvY( ch, rg, EV_PEAK ) )		// or EV_BBEG
			SetEval( ch, rg, EV_BEND, cVAL, EvY( ch, rg, EV_BEND ) )
			SetEval( ch, rg, EV_PEAK, cVAL, EvY( ch, rg, EV_PEAK ) )
			SetEval( ch, rg, EV_AMPL, cVAL, EvY( ch, rg, EV_PEAK ) - EvY( ch, rg, EV_BEND ) )
		endif



		// 11  Print and display the evaluated special points into the history window  
		if ( gPrintMask &  RP_TIMES )
			PrintEvalHistLine( ch, rg, nOfsPts / nPts, gDataSections )	
		endif
		if ( gPrintMask &  RP_BASEPEAK2 )
			PrintEvalHist( ch, rg )									// prints multiple lines
		endif

		if ( gPrintMask &  RP_EVALVERT )
			PrintEvalHistVert( ch, rg, lstEVAL_PRINTALL )					// prints multiple lines
		endif
		if ( gPrintMask &  RP_EVFILE )
			PrintEvalHistHorzHeader( ch, rg, lstEVAL_PRINTFILE )			// prints 1 line
			PrintEvalHistHorzValues(  ch, rg, lstEVAL_PRINTFILE )			// prints 1 line
		endif
		if ( gPrintMask &  RP_EVSCR1 )
			PrintEvalHistHorzHeader( ch, rg, lstEVAL_PRINTSCR1 )			// prints 1 line
			PrintEvalHistHorzValues(  ch, rg, lstEVAL_PRINTSCR1 )			// prints 1 line
		endif
		if ( gPrintMask &  RP_EVSCR2 )
			PrintEvalHistHorzHeader( ch, rg, lstEVAL_PRINTSCR2a )			// prints 1. of 2 lines
			PrintEvalHistHorzValues(  ch, rg, lstEVAL_PRINTSCR2a )			// prints 1. of 2 lines
			PrintEvalHistHorzHeader( ch, rg, lstEVAL_PRINTSCR2b )			// prints 2. of 2 lines
			PrintEvalHistHorzValues(  ch, rg, lstEVAL_PRINTSCR2b )			// prints 2. of 2 lines
		endif


		DisplayEvaluatedPoints( ch, rg, sWndNm )

		// 9	Do all the fitting ( mainly  the  Decay   or the   RiseDecay    phase )
		AllFitting( wOrg, ch, rg )


//print KeyboardState( "" )		
//		// 10  Draw the Latency Cursor
//		printf "\t\tDrawing Latency Cursor...ch:%d  rg:%d \r", ch, rg
		DisplayCursor( ch, rg, PH_LATCSR, CN_BEG, sWndNm )

	endfor	// regions

	// 11a  Print and display the evaluated special points into the textboy in the graph window  
//	PrintEvalTextbox( ch, sWndNm )

End

static Function		AllFitting( wOrg, ch, rg )
	wave	wOrg
	variable	ch, rg
	nvar		gFitCnt	= root:uf:eval:evl:gfitCnt
	wave	wCRegion	= root:uf:eval:evl:wCRegion
	variable	rLeft, rRight
	variable	ph, phCnt	= gFitCnt
	string  	sMsg, sTNL
	string		sWndNm		= CfsWndNm( ch )

	for ( ph = PH_FIT0; ph < PH_FIT0 + phCnt; ph += 1 )

		variable	nFitFunc	= wCRegion[ ch ][ rg ][ ph ][ CN_FITFNC ]
		RegionX( ch, rg, ph		, rLeft, rRight )	//WRONG	include cursor			// get the beginning and the end of the Peak2 evaluation region (=rLeft)
		variable	/G	root:uf:eval:fit:gFitFunc	= nFitFunc
		nvar			gFitFunc				= root:uf:eval:fit:gFitFunc
		nvar			gpStartValsOrFit			= root:uf:eval:evl:gpStartValsOrFit			// 0 : do not fit, display only starting values, 1 : do fit
		if ( nFitFunc != FT_NONE )

			duplicate /O /R=( rLeft, rRight )	wOrg    root:uf:eval:fit:wFitted				// Extract the segment to be fitted. It extends still over the old xLeft..xRight. range.
			duplicate /O /R=( rLeft, rRight )	wOrg    root:uf:eval:fit:wPiece				// Igor requires that wFitted has same length as source wave
			wave		wFitted	= root:uf:eval:fit:wFitted
			wave		wPiece	= root:uf:eval:fit:wPiece
			SetScale /I X, 0,  rRight - rLeft , "", wFitted									// Shift the wave so that it starts at 0. This makes fitting easier. Must be shifted back after fitting...
			SetScale /I X, 0,  rRight - rLeft , "", wPiece
			// printf "\tFitting( left:\t%6.3lf..\t%7.3lf\tch:%d  rg:%d  ph:%d)\tnFitFunc:%d  %s\r", rLeft, rRight, ch, rg, ph, gFitFunc, pd( StringFromList( gFitFunc, sFITFUNC ), 9 )

			variable	n, nPars		= ItemsInList( ParamNames( nFitFunc ) )
			string  	sFitChanFolder	= ksF_SEP + "fit" + ksF_SEP + "c" + num2str( ch ) + ksF_SEP 	// e.g  ':fit:c1:'
			string  	sStParNm		= "wStPar_r" + num2str( rg ) + "_p" + num2str( ph ) 
			string  	sParNm		= "wPar_r"    + num2str( rg ) + "_p" + num2str( ph ) 
			string  	sInfoNm		= "wInfo_r"    + num2str( rg ) + "_p" + num2str( ph ) 
			wave	/Z /D  wStartPar= $"root:uf:eval" + sFitChanFolder + sStParNm
			wave	/Z /D  wPar	=  $"root:uf:eval" + sFitChanFolder + sParNm

			if ( ! waveExists( wPar )  ||  ! waveExists( wStPar ) )
				ConstructAndMakeItCurrentFolder( RemoveEnding( "root:uf:eval" + sFitChanFolder, ksF_SEP ) )
				make /O  /D /N=( nPars )	$"root:uf:eval" + sFitChanFolder + sParNm		= 0
				make /O  /D /N=( nPars )	$"root:uf:eval" + sFitChanFolder + sStParNm	= nan//0
				make /O /N=(kMAXFITINFO)$"root:uf:eval" + sFitChanFolder + sInfoNm		= 0			// to hold   V_FitError, V_FitNumIters, V_FitMaxIters, V_chisq 
			endif
			wave	/D 	wPar	   	= 	$"root:uf:eval" + sFitChanFolder + sParNm	
			wave	/D 	wStartPar	= 	$"root:uf:eval" + sFitChanFolder + sStParNm	
			wave	 	wInfo	= 	$"root:uf:eval" + sFitChanFolder + sInfoNm	


			//  EVAL :   SetStartParams(),  FuncFit FitMultipleFunctionsEval  and  wFitted  work  with  TRUE TIMES
			wInfo[ kSTARTOK ]	= SetStartParams( wPar, wPiece, ch, rg, ph, nFitFunc, rLeft, rRight )	// stores results in  wPar
			if ( wInfo[ kSTARTOK ] )
				wStartPar	= wPar														// The fit will overwrite  wPar  but  we want to keep the starting values to check how good the initial guesses were.  See  PrintFitResults() below.  
			
				variable 	V_fitOptions = 4													// Bit 2: Suppresses the Curve Fit information window . This may speed things up a bit...

				if ( gpStartValsOrFit == FALSE )

					FuncFit /O	/N/ Q 	FitMultipleFunctionsEval, wPar, wPiece  /D= wFitted			// display only starting values, do not fit	

				else			
					variable	V_FitNumIters, V_FitMaxIters = 60								// used as an indicator whether the fit converged or not
					variable	V_FitError	= 0,  V_FitQuitReason								// do not stop or break into the debugger when fit fails

					FuncFit /N /Q /W=1 FitMultipleFunctionsEval, wPar, wPiece  /D= wFitted 			// do the fitting

					if ( V_FitError )
					sprintf sMsg, "\tFit failed : V_FitError:%d, V_FitQuitReason:%d [Bit0..3:Any error,SingMat,OutOfMem,NanOrInf]", V_FitError, V_FitQuitReason	
						Alert( cIMPORTANT,  sMsg )
					endif
				endif
				if ( ! gpStartValsOrFit  ||  ! V_FitError )

					string  	sFittedRangeNm	= "wF_r" + num2str( rg ) + "_p" + num2str( ph ) 
					string		sFoFittedRangeNm	= "root:uf:eval" + sFitChanFolder + sFittedRangeNm	// Make new wave e.g. 'fit:c1:wF0_r1_p0'   and fill it with an extracted segment
					wave	/Z	wF			= $sFoFittedRangeNm
					if ( ! waveExists( wF ) )
						ConstructAndMakeItCurrentFolder( RemoveEnding( "root:uf:eval" + sFitChanFolder, ksF_SEP ) )
					endif
					duplicate /O 		wFitted	$sFoFittedRangeNm							//..(=the fitted range) of the fitted wave. In the new wave the fitted range starts with point 0 . 
					SetScale /I X, rLeft,  rRight , "",  $sFoFittedRangeNm							// Shift the wave back so that it starts again at  'rLeft'
	
					variable	rRed, rGreen, rBlue
					EvalRegionColor( ch, rg, ph, rRed, rGreen, rBlue )
					sTNL	= TraceNameList( sWndNm, ";", 1 )
					if ( WhichListItem( sFittedRangeNm, sTNL, ";" )  == cNOTFOUND )				// ONLY if  wave is not in graph...
						AppendToGraph /W=$sWndNm	 /C=( rRed, rGreen, rBlue )	$sFoFittedRangeNm
					endif
				endif
				// Display  /K=1 wFitted, wPiece
			endif
			wInfo[ kFITERROR ]	= V_FitError
			wInfo[ kNUMITER ]	= V_FitNumIters
			wInfo[ kMAXITER ]	= V_FitMaxIters
			wInfo[ kCHISQ ]		= V_chisq 
			//PrintFitResultsIntoHist( wPar, wStartPar, ch, rg, ph, V_FitError, V_FitNumIters, V_FitMaxIters, V_chisq )
			sMsg	= PrintFitResultsIntoHist( wPar, wStartPar, wInfo, ch, rg, ph )
			if ( strlen( sMsg ) )
				printf "%s \r" , sMsg
			endif
			// SetRegionY( ch, rg, ph, (wMnMx[ch][ MM_YMIN ] + wMnMx[ch][ MM_YMAX ] ) / 2, (wMnMx[ch][ MM_YMIN ] + wMnMx[ch][ MM_YMAX ] ) / 2 )	// set the region in the middle
			 DisplayCursors( ch, rg, ph ) 

		endif
	endfor		// phases
End


static Function	/S	ParamNames( nFitFunc )			// 040804 static as also used in Eval
	variable	nFitFunc
	return	StringFromList( nFitFunc, ksPARNAMES, "~" )
End

static Function	/S	ParName( nFitFunc, nPar )			// 040804 static as also used in Eval
	variable	nFitFunc, nPar
	return	StringFromList( nPar, StringFromList( nFitFunc, ksPARNAMES, "~" ) )
End


static Function	/S	PrintFitResultsIntoHist( wPar, wStartPar, wInfo, ch, rg, ph )
	wave  /D	wPar, wStartPar
	wave	wInfo
	variable	ch, rg, ph
	wave	wCRegion	= root:uf:eval:evl:wCRegion
	nvar		gPrintMask= root:uf:eval:evl:gprintMask
	variable	nFitFunc	= wCRegion[ ch ][ rg ][ ph ][ CN_FITFNC ]
	string		sLine	= ""
	if ( nFitFunc !=  FT_NONE )
		if ( gPrintMask &  RP_FIT )
			string		sMsg, sFitAndStartPars = ""
			variable	n
			for ( n = 0; n < numPnts( wPar ); n += 1 )
				if ( gPrintMask &  RP_FITSTART )
					sFitAndStartPars   += ParName( nFitFunc, n ) + ": " + num2str( wPar[ n ] ) + " (" + num2str( wStartPar[ n ] ) + ")   "
				else
					sFitAndStartPars   += ParName( nFitFunc, n ) + ": " + num2str( wPar[ n ] ) + "   "
				endif
			endfor
	
			if ( ! wInfo[ kSTARTOK ] )
				sMsg			 = "Fit failed as no start parameters could be found."
				sFitAndStartPars = ""
			elseif ( wInfo[ kNUMITER ] == 0 )													// show start values, do not fit
				sprintf	sMsg, "No fit, start values : " 
			elseif ( wInfo[ kNUMITER ] == wInfo[ kMAXITER ]   ||   wInfo[ kFITERROR ]  )
				sprintf	sMsg, "It:%2d/%3d\t*** Failed ***" , wInfo[ kNUMITER ],  wInfo[ kMAXITER ]		
			else
				sprintf	sMsg, "It:%2d/%3d\tChi:%8.2g" ,  wInfo[ kNUMITER ],  wInfo[ kMAXITER ],  wInfo[ kCHISQ ]
			endif
	
			sprintf sLine, "ch:%d  rg:%d  %s\t%s\t%s\t  %s ", ch, rg, StringFromList( ph, ksPHASES), pd( StringFromList( nFitFunc, sFITFUNC ), 9), sMsg, sFitAndStartPars	// print the fitted and the starting values in one line
		endif
	endif
	return	sLine
End


////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//   BIG   HELPERS

static Function		AutomaticBaseRegion( wWave, ch, rg, BaseL, BaseR, rBaseT, rBaseB )
// guess the allowed baseline band from the noise in the given interval[ BaseL, BaseR ]
	wave	wWave
	variable	ch, rg, BaseL, BaseR, &rBaseT, &rBaseB
	variable	HalfWidth, MinMaxY, Average
	WaveStats /Q  /R=( BaseL, BaseR ) wWave				// First get wave average and deviation in the given time interval 
	Average	= V_avg
	HalfWidth	= V_sdev	* 1								// arbitrarily assume a band based on the noise level found in the interval
	wave	wMnMx	= root:uf:eval:evl:wMnMx					// But when there is little or no noise the band is too small and must be widened...
	MinMaxY	= wMnMx[ ch ][ MM_YMAX ] - wMnMx[ ch ][ MM_YMIN ]
	HalfWidth	= max( HalfWidth, MinMaxY * .02 )				// arbitrarily assume a band based on the minimum and maximum of complete wave
	//printf "\t\tAutomaticBaseRegion() \tBaseL:%5.1lf, BaseR:%5.1lf, ch:%d, MinMaxY:%5.1lf , HalfWidth:%5.1lf, Average:%5.1lf \r", BaseL, BaseR, ch, MinMaxY, HalfWidth, Average
	rBaseT	= Average + HalfWidth
	rBaseB	= Average  - HalfWidth 
End

static Function		EvaluateBase( wWave, ch, rg, StartTime, bDoNoiseCheck )									
//	get the BASE value when time range is given. Check if base is too noisy and mark this record
// to do : more nSECTIONS -> more tests -> then allow 1 or 2 failures
//todo let slope also store BASE NOISE????
	wave	wWave
	variable	ch, rg, StartTime, bDoNoiseCheck		
	nvar		gPrintMask= root:uf:eval:evl:gprintMask
	string		sMsg
	variable	rAvgValue	= 0 
	variable	LocBaseBeg, LocBaseEnd, BandAvgHi, BandAvgLo
	RegionX( ch, rg, PH_BASE, LocBaseBeg, LocBaseEnd )				// get the time range in which to evaluate the base 
	RegionY( ch, rg, PH_BASE, BandAvgHi, BandAvgLo )					// get the allowed band

	if ( bDoNoiseCheck )
		variable	dltax		= deltax( wWave )
		variable	n, pts	= ( LocBaseEnd - LocBaseBeg ) / dltax - 1		// one point less because the last point may already be in the artefact
		variable	nSlicePts	= trunc ( pts / cBASE_SLICES )
		variable	DurSlice	= nSlicePts * dltax
		variable	bTooNoisy		= 0
		rAvgValue	= 0 
		for ( n = 0; n < cBASE_SLICES; n += 1 )
			// Error occurs with empty channels (PATCH600!) . WavStats  error is mixed up with  FindLevel  error  .....
			WaveStats /Q  /R=( LocBaseBeg + n * DurSlice, LocBaseBeg + ( n + 1 ) * DurSlice ) wWave		// Measure average of every slice...
			if (GetRTError(0))
				print "****Internal warning : EvaluateBase() : " + GetRTErrMessage()
				variable dummy = GetRTError(1)
			endif
			if ( V_avg  < BandAvgLo	||   BandAvgHi < V_avg )									// ...and check if average is within narrow average band
				bTooNoisy	 += 1
				sprintf sMsg, "In  ch:%d  baseline slice %d of %d \t(Dur %6.2lf ..%6.2lf) \tthe average %.2lf \tis out of allowed avg band %.1lf ... %.1lf ", ch, n, cBASE_SLICES, n * DurSlice,  ( n + 1 ) * DurSlice,  V_avg , BandAvgLo, BandAvgHi
				Alert( cLESSIMPORTANT,  sMsg )
			endif		
			rAvgValue	= ( n * rAvgValue + V_avg ) / ( n + 1 )		
			//printf "\t\tEvaluateBase %3d/%3d\tDur %5.1lf ..%5.1lf\tPts:%4d\tAvg:%4.0lf\tDev:%4.1lf\trms:%4.0lf\tmiL:%4.0lf\tmi:%4.0lf\tmxL%4.0lf\tmx:%4.0lf\tdlt:%4.0lf\t->Avg:%4.0lf \r", n, cBASE_SLICES, n * DurSlice,  ( n + 1 ) * DurSlice,  V_npnts,  V_avg , V_sdev, V_rms ,V_minloc,  V_min, V_maxloc, V_max , V_max-V_min, rAvgValue 
		endfor
		for ( n = 0; n < cBASE_SLICES; n += 1 )
			if ( V_avg  < BandAvgLo	||   BandAvgHi < V_avg )	// check if average is within narrow average band
				bTooNoisy	 += 1
				sprintf sMsg, "In  ch:%d  baseline slice %d of %d \t(Dur %6.2lf ..%6.2lf) \tthe average %.2lf \tis out of allowed avg band %.1lf ... %.1lf ", ch, n, cBASE_SLICES, n * DurSlice,  ( n + 1 ) * DurSlice,  V_avg , BandAvgLo, BandAvgHi
				Alert( cLESSIMPORTANT,  sMsg )
			endif		
		endfor
	else
		rAvgValue	= fAverage( wWave, LocBaseBeg , LocBaseEnd )	// Measure average 
	endif
	
	SetEval( ch, rg, EV_BBEG, cT, LocBaseBeg )
	SetEval( ch, rg, EV_BBEG, cY, rAvgValue )
	SetEval( ch, rg, EV_BEND, cT, LocBaseEnd )
	SetEval( ch, rg, EV_BEND, cY, rAvgValue )
	if ( gPrintMask &  RP_BASEPEAK1 )
		if ( bTooNoisy ) 
			printf "\t\t\tEvaluateBase(%d)\t**** Base region evaluated in %d slices from %6.2lf ..%6.2lfms :\t TOO NOISY, discard record. [ Failed %d of %d tests ] \r", ch, cBASE_SLICES, LocBaseBeg-StartTime, LocBaseEnd-StartTime, bTooNoisy, 2 * cBASE_SLICES
		else
			printf "\t\t\tEvaluateBase(%d)\tBase region evaluated  in %d slices from %6.2lf ..%6.2lfms :\t OK \t\tBaseline value: %.1lf \r", ch, cBASE_SLICES, LocBaseBeg-StartTime, LocBaseEnd-StartTime, rAvgValue
		endif
	endif
End



static Function	EvaluatePeak( wWave, ch, rg, nRgType, msBeg, msEnd, nSidePts, nResultIndex ) 	
// Peak direction is initially known (passed as parameter)
// todo : value is OK, but time of sharp peak (=PEAK2) is not determined correctly (1/4 point late)  even if side points = 0.  Better wavestats????? (needs endloc!!)
	wave	wWave
	variable	ch, rg, nRgType, msBeg, msEnd, nSidePts, nResultIndex
	nvar		gPrintMask= root:uf:eval:evl:gprintMask
	variable	PreciseLoc, PreciseValue 			
	string		sMsg
	variable	dltax			= deltaX( wWave )
	variable	nSmoothPts	= nSidePts * 2 + 1
	wave	wCRegion		= root:uf:eval:evl:wCRegion
	variable	bPeak_Is_Up 	= wCRegion[ ch ][ rg ][ PH_PEAK ][ CN_ISUP ]
	string		sText		= SelectString( bPeak_Is_Up, "Minimum", "Maximum" )

	// First find the absolute extremum, then smooth 'nSidePts' around this point to refine the values by reducing noise influence . 'nSidePts' is CRITICAL !
	// Problem 1 : if  'nSidePts'  is too small  and  if  peak is symmetric and noisy	:  Error: noise peaks are returned  instead of the correct smoothed values
	// Problem 2 : if  'nSidePts'  is too large  and  if  peak is asymmetric		:  Error: averaged (=too low and shifted) peak is returned  instead of the correct one-point-peak
	// string		sTmpWvNm = "wPeak" + num2str( ch )		// wPeak0, wPeak1, ...-
	string			sTmpWvNm =  "root:uf:eval:evl" + ksF_SEP + "wPeak" + num2str( ch )		// wPeak0, wPeak1, ...-
	duplicate /O 	/R=( 	msBeg, msEnd ) wWave  $sTmpWvNm	// () in the wave units , here in ms
	wave		wSmoothedPeak = $sTmpWvNm

//030324
//AppendToGraph 				/Q /C=(0,15000, 65000) wSmoothedPeak	// Peaks are blue  

	//AppendToGraph 	/W=$sWndNm	/Q /C=(65000,15000, 65000) wSmoothedRiseDecay	// slopes are magenta  
	// the evaluation interval set by user may be too short for smoothing  or  it may lie after the sweep end (then having 0 points)
	// printf "\t\tEvaluatePeak()  ch:%d  rg:%d  msEnd - msBeg:%5.2lf ?>? nSmoothPts*dltax:%6.4lf   AND  nPnts:%d ?>=? nSmoothPts:%d \r", ch, rg, msEnd - msBeg, nSmoothPts * dltax, numPnts(wSmoothedPeak), nSmoothPts 
	variable	IntervalDuration	= min ( numPnts(wSmoothedPeak) * dltaX ,  msEnd - msBeg )
	if ( IntervalDuration <= nSmoothPts * dltaX )
		sprintf sMsg, "Chan:%d, region:%d : Interval for evaluation of  peak lies outside the sweep  or  is too short (%.1lfms) . Minimum duration needed is %d * %.1lfms. ", ch, rg,  IntervalDuration, nSmoothPts , dltax 
		Alert( cLESSIMPORTANT,  sMsg )
	else  
		Smooth		/B ( nSmoothPts ),	wSmoothedPeak
		WaveStats	/Q	wSmoothedPeak
		//WaveStats	/Q /R=( msBeg, msEnd )  wWave
		PreciseValue	= bPeak_Is_Up ? V_max : V_min	
		PreciseLoc	= bPeak_Is_Up ? V_maxloc : V_minloc	
	endif
	// Problem 1 : May erroneously find local peak when using a too large range and too few nSidePts
	// Problem 2 : May erroneously shift the correctly found global peak when peak is asymmetric and when using too many nSidePts
	//	if ( bPeak_Is_Up )
	//		FindPeak /Q /B=(addedPts)  	/R = ( msBeg, msEnd )  wWave
	//	else
	//		FindPeak /Q /B=(addedPts)  /N /R = ( msBeg, msEnd )  wWave
	//	endif
	//	if ( V_flag )
	//		sprintf sMsg, "%s not found . Search started at %.1lfms (increasing time) .", sText, msBeg
	//		Alert( cLESSIMPORTANT,  sMsg )
	//	else
	//		PreciseLoc	= V_peakLoc
	//		PreciseValue	= V_peakVal
	//	endif
	SetEval( ch, rg, nResultIndex, cT, PreciseLoc )
	SetEval( ch, rg, nResultIndex, cY, PreciseValue )
	if ( gPrintMask &  RP_BASEPEAK1 )
		printf "\t\t\tEvaluatePeak(%d)\tPk %1d\t%s\tLoc:%6.2lf \tRange %.2lf to %.2lfms.\tPrecVal(avg over %d pts=%.2lf ms) : %6.2lf\r",ch,  nRgType, SelectString( bPeak_Is_Up, "down", "up" ), PreciseLoc, msBeg, msEnd, nSmoothPts, (nSmoothPts-1)*deltax(wWave), PreciseValue
	endif
End



static Function	EvaluateCrossing( wWave, ch, rg, bPeak_Is_Up, sPhase, msBeg, msEnd, Percent, Val, nResultIndex ) 
// Evaluate the rising or the decaying phase
//  Find the time when the given 'Percent' level is crossed. Use the smoothed data to reduce noise influence. ( 0% is baseline, 100% is precisePeak)
	wave	wWave
	variable	ch, rg, bPeak_Is_Up				// evaluate pos or neg peak
	string		sPhase					// 'Rise'  or 'Decay'
	variable	msBeg, msEnd				// search range limits
	variable	Percent, Val, nResultIndex
	string		sMsg
	variable	dltax			= deltax( wWave )
	//variable	nSmoothPts	=  cSIDE_PTS_TO_ADD * 2 + 1
	variable	nSmoothPts	= 7			
	// Alternate approach: one could evaluate short intervals without smoothing............ 
	if ( ( msEnd - msBeg ) <= nSmoothPts * dltax )
		sprintf sMsg, "Interval for evaluation of crossing is too short (%.1lfms). Minimum duration needed is %d * %.1lfms. ", msEnd - msBeg , nSmoothPts , dltax 
		Alert( cLESSIMPORTANT,  sMsg )
	else  
		FindLevel	/Q /B = (nSmoothPts) /R=( msEnd, msBeg )  wWave, Val	// search backward
		if ( V_flag )
			sprintf sMsg, "FindLevel did not find %.0lf%% level crossing  (%.1lf) within interval %.1lfms .. %.1lfms ", Percent, Val, msbeg, msEnd 
			Alert( cLESSIMPORTANT,  sMsg )
		else
			//printf "\t\tEvaluateCrossing()\tPk %s, %s\tFound %.0lf%% level crossing (%6.1lf)\tat %6.1lfms\r", SelectString (bPeak_Is_Up, "down", "  up  " ), sPhase, Percent, Val, V_levelX
		endif
		SetEval( ch, rg, nResultIndex, cT, V_levelX )		// marking this entry as non-existing  by setting it to Nan if not found 
		SetEval( ch, rg, nResultIndex, cY, Val )
	endif
End


static Function	EvaluateSlope( wWave, ch, rg, nRgType, bPeak_Is_Up, sPhase, msBeg, msEnd, nResultIndex  ) 
// Evaluate the rising or the decaying phase.  Search the steepest slope
	wave	wWave
	variable	ch, rg, nRgType, bPeak_Is_Up				// evaluate pos or neg peak
	string		sPhase					// 'Rise'  or 'Decay'
	variable	msBeg, msEnd				// search range limits
	variable	nResultIndex 
	nvar		gPrintMask	= root:uf:eval:evl:gprintMask
	variable	n, dltax 		= deltaX( wWave )
	string		sMsg
	// first remove the noise by smoothing the data until they are almost monotonic ( 2/5  or  3/7  points )
	// this prepares the edges for precise determination of times of level crossings (e.g.RT2080) and slopes unless there is an extreme curvature
	// the extremes are deteriorated (flattened)  but we don't use those values
	variable	bSearchPosSlope = ( bPeak_Is_Up && !cmpstr( sPhase, "Rise" ) )  ||  ( !bPeak_Is_Up && cmpstr( sPhase, "Rise" ) )  ?  1  :  -1   
	//variable	nSmoothPts 	=  cSIDE_PTS_TO_ADD * 2 + 1
	variable	nSmoothPts	= 7						// 5 is NOT enough

	// Alternate approach: one could evaluate short intervals without smoothing............ 
	//string		sTmpWvNm = "wPeak" + sPhase + num2str( ch )// wPeakRise0, wPeakDecay2, ...-
	string			sTmpWvNm = "root:uf:eval:evl" + ksF_SEP + "wPeak" + sPhase + num2str( ch )// wPeakRise0, wPeakDecay2, ...-
	duplicate /O 	/R=( 	msBeg, msEnd ) wWave  $sTmpWvNm	// () in the wave units , here in ms
	wave		wSmoothedRiseDecay = $sTmpWvNm

//030324	
//	AppendToGraph 				/Q /C=(65000,15000, 65000) wSmoothedRiseDecay	// slopes are magenta  
	//AppendToGraph 	/W=$sWndNm	/Q /C=(65000,15000, 65000) wSmoothedRiseDecay	// slopes are magenta  
	//AppendToGraph 	/W=$sWndNm	/Q /C=(65000,15000, 65000) wPeakRise	// slopes are magenta  
	//AppendToGraph 	/W=$sWndNm	/Q /C=(45000,0, 45000) 	wPeakDecay	// slopes are magenta  

	if ( ( msEnd - msBeg ) <= nSmoothPts * dltax )
		sprintf sMsg, "Interval for evaluation of   slope   is too short (%.1lfms). Minimum duration needed is %d * %.1lfms. ", msEnd - msBeg , nSmoothPts , dltax 
		Alert( cLESSIMPORTANT,  sMsg )
	else  
		Smooth		/B ( nSmoothPts ),	wSmoothedRiseDecay
	
		waveStats	/Q	wSmoothedRiseDecay
		if ( gPrintMask &  RP_BASEPEAK1 )
			printf "\t\t\tEvaluateSlope(%d)\tPk %1d\t%s\t%s\t\tRange %.2lf to %.2lfms.\tSmoothbox:%d \tMin( %.0lfms ): %5.0lf \tMax(%.0lfms): %5.0lf \r", ch, nRgType, SelectString (bPeak_Is_Up, "down", "up" ), sPhase, msBeg, msEnd,  nSmoothPts, V_minloc, V_min, V_maxloc, V_max
		endif
		//....then search the biggest y difference between adjacent points = steepest slope
		variable	Slope = 0, SteepestSlope = 0, ptSlope
		for ( n = 0; n < V_npnts - 1; n += 1 )
			Slope	= bSearchPosSlope * ( wSmoothedRiseDecay[ n + 1 ] - wSmoothedRiseDecay[ n ] )
			if ( Slope > SteepestSlope )
				SteepestSlope = Slope
				ptSlope	= n
				//printf "\t\t\t%s found steeper %s slope between point %3d \tand %3d \t(%6.1lfms)  : %g \r", pd(sPhase,6), SelectString (bSearchPosSlope==1, "neg.", "pos." ), ptSlope, ptSlope + 1, pnt2x( wSmoothed, n ), SteepestSlope
			endif
		endfor
		SetEval( ch, rg, nResultIndex, cT, pnt2x( wSmoothedRiseDecay, ptSlope ) ) 	// todo interpolate between this and next value
		SetEval( ch, rg, nResultIndex, cY, wSmoothedRiseDecay[ ptSlope ] ) 		// todo interpolate between this and next value
		SetEval( ch, rg, nResultIndex, cVAL, SteepestSlope ) 			
	endif
End


////////////////////////////////////////////////////////////////////////////////////////////////
//  WRITE  AVERAGE  (0501 to be made obsolete,  ->  Avg new controlled by DSSelect listbox)
//  these functions seem to bear quite an amount of overhead but they have 2 distinct advantages:
//	- there are no global variables / strings / waves  concerning  the 'Average'  in the main function  'Analyse'  (which is already quite large), all data are 'hidden'
//	- there is extensive 'Existence' checking of waves and windows so no assumptions have to be made about the current state of the program (e.g. the user should not but may have deleted traces)

Function		AddToAverage()
// writes average data in different files for each channel. The channels are distinct by the file name postfix.
// the channels are independent so if the user switches channels on/off during averaging the same averaging path may result in different indices from channel to channel
// writing averages could be realized somewhat simpler (header and data could be written in 1 step) but the framework used is here is more general and can be used similarly for 'AddToTable()' 
	nvar		gAvgKeepCnt	= root:uf:eval:evl:gavgKeepCnt		// 
	nvar		gChans		= root:uf:cfsr:gChannels					
	variable	nRefNum, ch
	string		sFilePath
	//variable	NamingMode	= cTWOLETTER
	string		sAvgWvNm, sFoldOrgWvNm
	// Update and display the average wave
	for ( ch = 0; ch < gChans; ch += 1 ) 							
		sAvgWvNm	 = FoAvgWvNm( ch )
		wave  /Z	wAvg = $sAvgWvNm			
		sFoldOrgWvNm	 = FoOrgWvNm( ch )
		wave  /Z	wOrg	 = $sFoldOrgWvNm			
		if ( waveExists ( wOrg ) )										// trace may not (yet) exist or the user may have deleted it
			if ( gAvgKeepCnt == 0 )
				duplicate	/O  $sFoldOrgWvNm  $sAvgWvNm				// MUST USE $STRING SYNTAX (duplicate in user functions in loops...)
			endif
			if ( waveExists ( wAvg ) )									// trace may not (yet) exist or the user may have deleted it
				wAvg	= ( wAvg * gAvgKeepCnt + wOrg )  / ( gAvgKeepCnt + 1 )	// to do  cursor   offset
				gAvgKeepCnt	+= 1									// increment ONLY when there has actually been added to the average
			endif
		endif
		DisplayAverage( ch )
	endfor

	WriteAverage( ch, wAvg )				// Update  ( or create )  the average  file  by writing the  average wave data
End


static Function	WriteAverage( ch, wAvg )
		// Update  ( or create )  the average  file  by writing the  average wave data
	variable	ch
	wave	wAvg
	variable	nRefNum
	string		sFilePath
	if ( FileBasesDiffer( CfsRdDataPath() , CurrentAvgFile( ch ) ) ) 		// the user may have changed the Cfs file or may have cleared the average. In either case a new average file will be written. 
		sFilePath	= ConstructNextResultFileNm( CfsRdDataPath(), ch, ksAVGEXT )
		SetCurrentAvgFile( sFilePath, ch )						// includes channel number  and index  e.g. Cfsdata_10.avg
		printf "\t\tAddToAvg()  searching next unused free file, found %s ...	\r", pd( sFilePath , 26 )
	endif
	sFilePath	= CurrentAvgFile( ch )
	Open  	nRefNum  as sFilePath					// Open file  by  creating it
	if ( nRefNum ) 									// ...a new average always overwrites the whole file, it never appends
		WriteAvgHeader( nRefNum, sFilePath, ch )
		WriteAvgData( nRefNum, wAvg, sFilePath, ch )
		Close	nRefNum
	endif
End

   Function		WriteAvgHeader( RefNum, sFilePath, ch )
	variable	RefNum, ch					// only for debugging
	string		sFilePath						// only for debugging
	string		sLine		= "   Time      Value  \r"
	//printf  "\t\t\tAddToAvg()  will add header writing into '%s'   :  %s", sFilePath, sLine	// sLine includes CR 
	fprintf 	RefNum,  sLine
End

   Function		WriteAvgData( RefNum, wWave, sFilePath, ch )
	variable	RefNum, ch					// only for debugging
	string		sFilePath						// only for debugging
	wave	wWave
	variable	step	=1//100					// todo make step variable, average over data points
	variable	i, pts	= numPnts( wWave )
	variable	dltax	= deltaX( wWave )
	string		sLine
	for ( i = 0; i < pts; i += step )
		sprintf	sLine, "%8.3lf %8.3lf\r", i * dltax, wWave[ i ]
		fprintf 	RefNum, sLine					// Add data
		//printf  "\t\t\tAddToAvg( ch:%d )  will add average (pts:%d, dltax:%g)  writing into '%s'   :  %s", ch, pts, dltax, sFilePath, sLine
	endfor		
End

Function		EraseAverages()
	nvar		gAvgKeepCnt	= root:uf:eval:evl:gavgKeepCnt		// 
	nvar		gChans		= root:uf:cfsr:gChannels						
	EraseAvgFileNames()								// a new average file will be opened when the next averages is to be added

	variable	ch
	for ( ch = 0; ch < gChans; ch += 1 ) 							
		wave  /Z	wAvg	= $FoAvgWvNm( ch )
		if ( waveExists ( wAvg ) )						// trace may not (yet) exist or the user may have deleted it
			wAvg		= 0
		endif
		DisplayAverage( ch )
	endfor
	gAvgKeepCnt	= 0
End

Function		SaveAverages()
	nvar		gChans		= root:uf:cfsr:gChannels						
	variable	ch
	for ( ch = 0; ch < gChans; ch += 1 ) 							
	endfor
End

Function		AvgCnt()
	nvar		gAvgKeepCnt	= root:uf:eval:evl:gavgKeepCnt					// 
	return	gAvgKeepCnt
End

static Function		DisplayAverage( ch )
	variable	ch
	string		sWndNm		= CfsWndNm( ch )
	string  	sAvgNm		= FoAvgWvNm( ch )
	wave  /Z	wAvg		= $sAvgNm
	string  	sTxt
	nvar		gbShowAverage= root:uf:eval:evl:gbShowAverage
	if ( WinType( sWndNm ) == kGRAPH  &&  waveExists ( wAvg ) )				// window or trace may not (yet) exist
		if ( gbShowAverage )
			AppendToGraph 	/W=$sWndNm	/C=( 43000, 33000, 0 ) 				wAvg	// brown
			sTxt	= "Show avg"
		else
			// cosmetics: unnecessary in normal mode because the whole wnd is cleared when displaying new data, but USED TO HIDE THE TRACE IMMEDIATELY WHEN user unchecks the 'ShowAverage' button
			AppendToGraph 	/W=$sWndNm	/C=(cBGCOLOR,cBGCOLOR,cBGCOLOR)	wAvg	// background = invisible 
			sTxt	= "Hide avg"
		endif
		printf "\t\t\tDisplayAverage( ch:%d ) \t%s\t%s\t(exists) in W\t%s\t(exists)\tnAvgd:%3d\tPts:%4d\t \r", ch, sTxt, sAvgNm, sWndNm, AvgCnt(), numPnts( wAvg)
	endif
End

static Function		DisplayAllAverages()
	nvar		gChans		= root:uf:cfsr:gChannels						
	variable	ch
	for ( ch = 0; ch < gChans; ch += 1 ) 							
		DisplayAverage( ch )
	endfor
End

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Wave  and file name management for result average functions

Function	/S	AvgWvNm( ch )
	variable	ch
	return	"wAvg" + num2str( ch )			// name must be unique for each channel  (ASSUMPTION: 4 chars...)
End

Function	/S	FoAvgWvNm( ch )
	variable	ch
	return	"root:uf:eval:evl" + ksF_SEP + "wAvg" + num2str( ch )			// name must be unique for each channel  (ASSUMPTION: 4 chars...)
End

// todo  : avg, tbl   could be indices into a  wave  with 1 more dimension

static  Function		SetCurrentAvgFile( sFile, ch )
	string		sFile
	variable 	ch
	wave   /T	wCurrAvgFile	= root:uf:eval:evl:wCurrAvgFile
	wCurrAvgFile[ ch ]	= sFile
End

static  Function  /S	CurrentAvgFile( ch )
	variable 	ch
	wave   /T	wCurrAvgFile	= root:uf:eval:evl:wCurrAvgFile
	return	wCurrAvgFile[ ch ]
End

Function		EraseAvgFileNames()
	variable	ch
	for ( ch = 0; ch < cMAXCHANS; ch += 1 )
		SetCurrentAvgFile( "", ch )						// a new average file will be opened when the next average is to be added
	endfor
End

////////////////////////////////////////////////////////////////////////////////////////////////
//  WRITE  TABLE

Function		AddToTable()
// writes table data in different files for each channel. The channels are distinct by the file name postfix.
// the channels are independent so if the user switches channels on/off during evaluation the same table path may result in different indices from channel to channel
// nearly the same framework is used in  'AddToAverage()' 
//	nvar		gAvgKeepCnt	= root:uf:eval:evl:gavgKeepCnt		// 
	nvar		gTblKeepCnt	= root:uf:eval:evl:gTblKeepCnt						// 
	nvar		gChans		= root:uf:cfsr:gChannels					
	variable	nRefNum, ch
	string		sFilePath, sLine
	variable	NamingMode	= cDIGITLETTER

	// Update  ( or create )  the table  by writing the result data
	for ( ch = 0; ch < gChans; ch += 1 ) 							
		if ( FileBasesDiffer( CfsRdDataPath() , CurrentTblFile( ch ) ) ) 			// the user may have changed the Cfs file or may have cleared the table. In either case a new table file will be written. 
			sFilePath	= ConstructNextResultFileNm( CfsRdDataPath(), ch, sTABLEEXT )
			SetCurrentTblFile( sFilePath, ch )						// includes channel number  and index  e.g. Cfsdata_10.fit
			printf "\t\tAddToTable()  searching next unused free file, found %s ...	\r", pd( sFilePath , 26 )
			
			Open  	nRefNum  as sFilePath					// Open file  by  creating it
			if ( nRefNum ) 
				sLine		= PrintEvalFileHorzHeader(  lstEVAL_PRINTFILE )	// Write header
				fprintf 	nRefNum, "%s\r", sLine
				Close	nRefNum							// Close file after every write
			endif
		endif
		sFilePath	= CurrentTblFile( ch )
		Open  /A  nRefNum  as sFilePath						// Open existing file  for  appending  
		if ( nRefNum ) 
			variable	rg	= 0
			sLine		= PrintEvalFileHorzValues(  ch, rg, lstEVAL_PRINTFILE )	// Add data
			//print ch, sLine
			fprintf 	nRefNum, "%s\r", sLine
			Close	nRefNum								// Close file after every write
		endif
	endfor
End

Function		SaveTables()
	EraseTblFileNames()								// a new table file will be opened when the next results are to be added
	nvar		gTblKeepCnt	= root:uf:eval:evl:gTblKeepCnt						// 
	nvar		gChans		= root:uf:cfsr:gChannels						
	variable	ch
	for ( ch = 0; ch < gChans; ch += 1 ) 							
	endfor
End

Function		EraseTables()
	EraseTblFileNames()								// a new table file will be opened when the next results are to be added
	nvar		gTblKeepCnt	= root:uf:eval:evl:gTblKeepCnt						// 
	nvar		gChans		= root:uf:cfsr:gChannels						
	variable	ch
	for ( ch = 0; ch < gChans; ch += 1 ) 							
	endfor
End

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  File name management for result table  functions

static Function		SetCurrentTblFile( sFile, ch )
	string		sFile
	variable 	ch
	wave   /T	wCurrTblFile	= root:uf:eval:evl:wCurrTblFile
	wCurrTblFile[ ch ]	= sFile
End

static Function  /S	CurrentTblFile( ch )
	variable 	ch
	wave   /T	wCurrTblFile	= root:uf:eval:evl:wCurrTblFile
	return	wCurrTblFile[ ch ]
End

static Function		EraseTblFileNames()
	variable	ch
	for ( ch = 0; ch < cMAXCHANS; ch += 1 )
		SetCurrentTblFile( "", ch )						// a new table file will be opened when the next  table results are to be added
	endfor
End

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Common file name management for result (=average and table) functions
//  the idea is to use as few globals as possible and to hide as much of the internals to the calling functions (like 'AddToAverage() '  or  'AddToTable() ' )

static  Function	/S	ConstructNextResultFileNm( sCfsPath, ch, sExt )
	string		sCfsPath, sExt
	variable	ch
	variable	NamingMode	= cDIGITLETTER						// 2 naming modes are allowed.   cDIGITLETTER is prefered to avoid confusion with the already used mode cTWOLETTER (used for Cfs file naming) 
	string		sFilePath
	sFilePath	= StripExtensionAndDot( sCfsPath )						// Convert Cfs data file name to average file name by removing the dot and the 1..3 letters...
	sFilePath	= BuildFileNm( sFilePath, ch, 0, sExt, NamingMode )			// ..there can be multiple table files for each cfs file so we append a postfix
	sFilePath	= GetNextFile( sFilePath, cSEARCHFREE, cUP, NamingMode )	// find the next unused file name
	return	sFilePath
End

static  Function		FileBasesDiffer( sCfsFile, sResultFile ) 
// compare the file bases of  the Cfs file and of the table/average file. They will differ the user changed the cfs data file  OR  when the current table/average file name has been cleared
	string		sCfsFile, sResultFile
	string		sCfsFileBase	= StripExtensionAndDot( sCfsFile )			// Convert Cfs data file name to Cfs file base name by removing the dot and the 1..3 letters...
	//print "\tFileBasesDiffer(", sCfsFileBase,  sResultFile , ")",  SelectString( cmpstr( sCfsFileBase, sResultFile[ 0, strlen( sCfsFileBase ) - 1 ] ) , "are same ", "differing" )
	return	cmpstr( sCfsFileBase, sResultFile[ 0, strlen( sCfsFileBase ) - 1 ] )	// the result file may have any ending, only the first characters are compared
End

static Function   /S	BuildFileNm( sCfsFileBase, ch, n, sExt, NamingMode )
// builds  result file name (e.g. average, table) when  path, file and dot (but no extension)  of CFS data  is given (and channel and index) 
// 2 naming modes are allowed.  cDIGITLETTER is prefered to avoid confusion with the already used mode cTWOLETTER (used for Cfs file naming) 
// e.g.  Cfsdata.dat, ch:1, n:6 -> Cfsdata_1f.avg  or  Cfsdata_1f.fit
	string		sCfsFileBase, sExt
	variable	ch, n, NamingMode
	string		sIndexString	= SelectString( NamingMode == cDIGITLETTER,  IdxToTwoLetters( n ),  IdxToDigitLetter( n ) ) 
	//return	sCfsFileBase + "_" + sIndexString + "." + sExt				// no channel number in name		   e.g.  Cfsdata.dat, 	     n:6   ->	Cfsdata_f.avg    	or  Cfsdata_f.fit
	return	sCfsFileBase + "_" + num2str( ch ) + sIndexString + "." + sExt	// channel number as  _1 digit  in name  e.g.  Cfsdata.dat, ch:1, n:6  ->	Cfsdata_1f.avg	or  Cfsdata_1f.fit
End

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  LITTLE  HELPERS 

//Function		SetRegion( ch, rg, ph, Left, Right, Top, Bot )
//// converts and stores the given coordinates of a region in X and Y 
//	variable	ch, rg, ph, Left, Right, Top, Bot
//	SetRegionX( ch, rg, ph, Left, Right )
//	SetRegionY( ch, rg, ph, Top, Bot )
//End
//
//Function		SetRegionX( ch, rg, ph, Left, Right )
//// converts and stores the given coordinates of a region in X 
//	variable	ch, rg, ph, Left, Right
//	wave	wCRegion	= root:uf:eval:evl:wCRegion
//	wCRegion[ ch ][ rg ][ ph ][ CN_BEG ]		= Left
//	wCRegion[ ch ][ rg ][ ph ][ CN_END]		= Right
//End

static Function		SetRegionY( ch, rg, ph, Top, Bot )
// converts and stores the given coordinates of a region in  Y 
// PH_PEAK is not handled....
	variable	ch, rg, ph, Top, Bot
	wave	wCRegion	= root:uf:eval:evl:wCRegion
	wCRegion[ ch ][ rg ][ ph ][ CN_BEGY ]		= Top
	wCRegion[ ch ][ rg ][ ph ][ CN_ENDY ]		= Bot		// for base and peak
End

static Function		RegionX( ch, rg, ph, rL, rR )
// return a region's X coordinates as references, return directly whether the region has already been set
	variable	ch, rg, ph, &rL, &rR
	wave	wCRegion	= root:uf:eval:evl:wCRegion
	rL	= wCRegion[ ch ][ rg ][ ph ][ CN_BEG ]
	rR	= wCRegion[ ch ][ rg ][ ph ][ CN_END ]
	//print "\t\tRegionX  ch, rg , ph:" ,ch, rg, ph, "->", rL, rR
	return 	numType( rL ) != NUMTYPE_NAN
End

static Function		RegionY( ch, rg, ph, rT, rB )
// return a region's Y coordinates as references
	variable	ch, rg, ph, &rT, &rB
	wave	wCRegion	= root:uf:eval:evl:wCRegion
	rT	= wCRegion[ ch ][ rg ][ ph ][ CN_BEGY ]
	rB	= wCRegion[ ch ][ rg ][ ph ][ CN_LO ]
//	rB	= wCRegion[ ch ][ rg ][ ph ][ CN_BEGY ]
End

static Function		UserRegionBaseY( ch, rg, ph, rT, rB )
// return a region's  USER Y coordinates as references
	variable	ch, rg, ph, &rT, &rB
	wave	wCRegion	= root:uf:eval:evl:wCRegion
	rT	= wCRegion[ ch ][ rg ][ ph ][ CN_BEGY ]
	rB	= wCRegion[ ch ][ rg ][ ph ][ CN_LO ]
//	rB	= wCRegion[ ch ][ rg ][ ph ][ CN_BEGY ]
End

//Function		SetUserRegionBaseY( ch, rg, ph, Top, Bot )
//// converts and stores the given coordinates of a region in X and Y waves which are suitable for easy drawing
//	variable	ch, rg, ph, Top, Bot
//	wave	wCRegion	= root:uf:eval:evl:wCRegion
//	wCRegion[ ch ][ rg ][ ph ][ CN_USHI ]	= Top
//	wCRegion[ ch ][ rg ][ ph ][ CN_USLO ]	= Bot
//End

//Function		SetEvalRegionParams( ch, rg, ph, VertExt, nDrawDir )
//	variable	ch, rg, ph, VertExt, nDrawDir
//	wave	wCRegion	= root:uf:eval:evl:wCRegion
////	wCRegion[ ch ][ rg ][ ph ][ CN_LEN ]		= VertExt
////	wCRegion[ ch ][ rg ][ ph ][ CN_DIR ]		= nDrawDir
//	//print "\t\tSetEvalRegionParams()  ch:",  ch, rg, ph, pd(StringFromList( ph, ksPHASES ),9), "\t", nCsrCnt, "Color:", nColor, StringFromList( nColor, sCOLORS), "\tDot:", nDotting, VertExt, "   \tDrawDir:", nDrawDir 
//End

static Function		EvalRegionColor( ch, rg, ph, rRed, rGreen, rBlue )
// return 3 color values for regions when channel and region type is given
	variable	ch, rg, ph
	variable	&rRed, &rGreen, &rBlue 
	variable	nColor
	wave	Red 		= root:uf:misc:Red, Green = root:uf:misc:Green, Blue = root:uf:misc:Blue
	wave	wCRegion	= root:uf:eval:evl:wCRegion
	nColor	= wCRegion[ ch ][ rg ][ ph ][ CN_COLOR ]	
	rRed		= Red[ nColor ]
	rGreen	= Green[ nColor ]
	rBlue		= Blue[ nColor ]
End


static Function		DisplayCursors( ch, rg, ph )
	variable	ch, rg, ph
	string		sWnd	= CfsWndNm( ch ) 
	DisplayCursor( ch, rg, ph, CN_BEG, sWnd )
	DisplayCursor( ch, rg, ph, CN_END, sWnd )
End

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

static Function	FourPointIntersection( ch, rg, index1a, index1b, index2a, index2b, ResultIndex )
// computes intersection given by 2 lines from 4 special evaluation points (given by EVAL-index)  and sets  ResultIndex
	variable	ch, rg, index1a, index1b, index2a, index2b, ResultIndex 
	variable	rx, ry		// are changed
	FourPointXYIntersection( EvT(ch, rg, index1a), EvY(ch, rg, index1a), EvT(ch, rg, index1b), EvY(ch, rg, index1b), EvT(ch, rg, index2a), EvY(ch, rg, index2a ), EvT( ch, rg, index2b), EvY( ch, rg, index2b ), rx, ry ) 
	SetEval( ch, rg, ResultIndex, cT, rx )
	SetEval( ch, rg, ResultIndex, cY, ry )
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
	//printf "\t\tx1a=%g      \ty1a=%g  ,  \tx1b=%g      \ty1b=%g      \tgives line1  y = %gx + %g \r\tx2a=%g      \ty2a=%g  ,  \tx2b=%g      \ty2b=%g    \tgives line2  y = %gx + %g . Intersection at x=%g, y=%g (=%g) \r", x1a, y1a, x1b, y1b, slope1, const1, x2a, y2a, x2b, y2b, slope2, const2, rx, ry , slope2 * rx + const2
End

static Function	TwoLineIntersection( slope1, const1, slope2, const2, rx, ry )
// todo : error checking , division by 0
	variable	slope1, const1			// defines 1. line   y = slope * x + const
	variable	slope2, const2			// defines 2. line   y = slope * x + const
	variable	&rx, &ry				// intersection : parameters are changed
 	rx = ( const2 - const1 ) / ( slope1 - slope2 ) 
	ry = slope1 * rx + const1
	//printf "\t\tx line1  y = %gx + %g \r\tx2a=%g      \tline2  y = %gx + %g . Intersection at x=%g, y=%g (=%g) \r", slope1, const1, slope2, const2, rx, ry , slope2 * rx + const2
End

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  PRINTING  THE  RESULTS  (in textbox in graph, in the history window, into file)

static Function		PrintEvalHistLine( ch, rg, nSection, gDataSections )
	variable	ch, rg, nSection, gDataSections
	variable	n
	string		sText
	sprintf	sText, "\tAnalyse(ch:%d rg:%d %3d/%3d )" , ch, rg, nSection, gDataSections  
	for ( n = 0; n < EV_MAXPTS; n += 1 )
		string		sNm		= StringFromList( n, sEVA )
		variable	value	= EvT( ch, rg, n )
		printf "%s\t%s:%6.2lf%s", SelectString( n==0, "", sText ), sNm, Value, SelectString( n== EV_MAXPTS - 1, "", "\r" ) 
	endfor
End

static Function		PrintEvalHist( ch, rg )
	variable	ch, rg
	variable	n
	for ( n = 0; n < EV_MAXPTS; n += 1 )
		if ( ExistsEvT( ch, rg, n ) ) 
			printf "\t\t\tPrintEval() \t%s\tt = %6.2lf\ty = %6.2lf\tvalue = %6.2lf \r", pd( EvalNm( n ), 12) , EvT( ch, rg, n ), EvY( ch, rg, n ), Eval( ch, rg, n , cVAL )
		endif
	endfor
End
static Function		PrintEvalHistVert( ch, rg, sMask )
	variable	ch, rg
	string		sMask
	variable	m, n
	for ( m = 0; m < ItemsInList( sMask ); m += 1 )
		n	= str2num( StringFromList( m, sMask ) )
//		if ( ExistsEvT( ch, rg, n ) ) 
			printf "\t\t\tPrintEvalVert(%3d >%3d\tch:%d  rg:%d ) \t%s\tt = %6.2lf\ty = %6.2lf\tvalue = %6.2lf \r", m, n, ch, rg, pd( EvalNm( n ), 12) , EvT( ch, rg, n ), EvY( ch, rg, n ), Eval( ch, rg, n , cVAL )
//		endif
	endfor
End

static Function		PrintEvalHistHorzHeader( ch, rg, sMask )
	variable	ch, rg
	string		sMask
	variable	m, n
	string		sEntry	= ""
	string		sLine		= "\t\t\t"
	//string	sLine		= "ch:" + num2str( ch ) +"  rg:" + num2str( rg ) + "  fr:" + num2str( GetCurFrm() ) 
	variable	fr	= GetCurFrm()
	if ( mod( fr, 5 ) == 0 )									// print only 1 header every 5 result lines
		for ( m = 0; m < ItemsInList( sMask ); m += 1 )
			n	= str2num( StringFromList( m, sMask ) )
			sprintf sEntry, "\t%11s",  EvalNm( n )				// formatted with tabs to compensate for the proportional font
			sLine		+= sEntry
		endfor
		printf "%s\r", sLine
	endif
End

static Function		PrintEvalHistHorzValues( ch, rg, sMask )
	variable	ch, rg
	string		sMask
	variable	m, n
	string		sEntry	= ""
//	string		sLine		= "\t\t\t"
	string		sLine		= "ch:" + num2str( ch ) +"  rg:" + num2str( rg ) + "  fr:" + num2str( GetCurFrm() ) 
	for ( m = 0; m < ItemsInList( sMask ); m += 1 )
		n	= str2num( StringFromList( m, sMask ) )
		sprintf sEntry, "\t%11.4lf",  Eval( ch, rg, n , cVAL )	// formatted with tabs to compensate for the proportional font
		sLine		+= sEntry
	endfor
	printf "%s\r", sLine
End

/////////////////////////////////////////////////////////////

static  Function		PrintEvalTextboxAllChans()	
// Print and display the evaluated special points into the textbox in the graph window  
	nvar		gChans		= root:uf:cfsr:gChannels			
	variable	ch
	for ( ch = 0; ch < gChans;  ch += 1 )	
		string  sWNm = CfsWndNm( ch ) 
		PrintEvalTextbox(  ch, sWNm )
	endfor
End


Function		PrintEvalTextbox( ch, sWNm )
// Print and display the evaluated special points into the textbox in the graph window  
	variable	ch
	string  	sWNm
	nvar		gbDoEvaluation	= root:uf:eval:evl:gbDoEvaluation 
	nvar		gbResTextbox	= root:uf:eval:evl:gbResTextbox
	nvar		gPrintMask	= root:uf:eval:evl:gprintMask
	nvar		gFitCnt		= root:uf:eval:evl:gfitCnt
	wave 	wChanOpts	= root:uf:eval:evl:wChanOpts
	wave 	wCRegion		= root:uf:eval:evl:wCRegion
	string		sText		= ""
//	string  	sWNm		= CfsWndNm( ch ) 
	variable	ph, bPrintHorzNames	= 1
	if ( WinType( sWNm ) == kGRAPH ) 
		if ( ! gbResTextbox )
			TextBox	/W=$sWNm  /K  /N=$TBEvalHeaderAndResultsNm( ch ) 	// remove the textbox
		else
	if ( ch == 0 )
			sText	= "\F'Terminal'\Z09"						// non-proportional font, Z08 and Z09 are both  OK
	elseif ( ch == 1 )
			sText	= "\F'Terminal'\Z08"						// non-proportional font, Z08 and Z09 are both  OK
//			sText	= "\F'Fixedsys'\Z09"						// too big
//			sText	= "\F'Terminal'\Z09"						// non-proportional font,  Z08 and Z09 are both  OK
	else
//			sText	= "\F'Courier New'\Z08"					// non-proportional font,  too wide
//			sText	= "\F'Small Fonts'\Z07"					// very narrow proportional font,  Z06 and Z07 are both  OK
			sText	= ""									// narrow proportional font
	endif
			if ( gPrintMask &  RP_HEADER )
				sText	+= PrintEvalTBHeader( ch )	+  "\r"
//				sText	+= "analyse"    				+  "\r"
			endif
			//sText  +=  "\r"	// prints 1 line

			if ( gbDoEvaluation )
				
				variable	rg, rgCnt		= wChanOpts[ ch ][ CH_RGCNT ]
				for ( rg = 0; rg < rgCnt;  rg += 1 )	
					
					string  	sRgTxt	= SelectString( rgCnt == 1 , "rg:" + num2str( rg ) , "    " )			// if there is only 1 region we do not print it's number to keep the textbox simple
					if ( bPrintHorzNames )
						if ( gPrintMask &  RP_EVSCR1 )
							sText  += PrintEvalTBHorzNames( lstEVAL_PRINTSCR1 )		+ "\r"	// prints 1 line
						endif
					endif
					if ( gPrintMask &  RP_EVSCR1 )
						sText  += PrintEvalTBHorzValues( sRgTxt, ch, rg, lstEVAL_PRINTSCR1 )	+ "\r"		// prints 1 line
					endif

					bPrintHorzNames	= 0
					if ( gPrintMask &  RP_FIT )

						for ( ph = PH_FIT0; ph < PH_FIT0 + gFitCnt;  ph += 1 )
							variable	nFitFunc	= wCRegion[ ch ][ rg ][ ph ][ CN_FITFNC ]
							if ( nFitFunc !=  FT_NONE )
								string  	sFitChanFolder	= ksF_SEP + "fit" + ksF_SEP + "c" + num2str( ch ) + ksF_SEP 	// e.g  ':fit:c1:'
								string  	sStParNm		= "wStPar_r" + num2str( rg ) + "_p" + num2str( ph ) 
								string  	sParNm		= "wPar_r"    + num2str( rg ) + "_p" + num2str( ph ) 
								string  	sInfoNm		= "wInfo_r"    + num2str( rg ) + "_p" + num2str( ph ) 
								wave	/D 	wPar	   	= $"root:uf:eval" + sFitChanFolder + sParNm	
								wave	/D 	wStartPar	= $"root:uf:eval" + sFitChanFolder + sStParNm	
								wave	 	wInfo	= $"root:uf:eval" + sFitChanFolder + sInfoNm	
		
								sText		  +=	PrintEvalTBFitResults( wPar, wStartPar, wInfo, sRgTxt, ch, rg, ph )		+ "\r"
								bPrintHorzNames += 1					// to improve textbox readability we include additional  'HorzNames' if there were fits which interupted the layout
							endif
	
						endfor				
					endif

					if ( gPrintMask &  RP_CURSORINFO )
						sText	+= PrintEvalTBCursorInfo( ch, rg )
					endif

				endfor				

			endif

			sText	= RemoveEnding( sText, "\r" )
//			TextBox	/W=$sWNm  /C  /N=$TBEvalHeaderAndResultsNm( ch )  /E=1	/A=MT  /F=2  sText	// /E=1: shrink y axis so that textbox is above plot area
			TextBox	/W=$sWNm  /C  /N=$TBEvalHeaderAndResultsNm( ch )  /E=2	/A=MT  /F=2  sText	// /E=2: overwrite plot area

// old		TextBox	/W=$sWndNm /C  /N=$TBEvalHeaderAndResultsNm( ch ) 	/E=0  /A=LT 	/Y=0  /F=2  sHeaderAndResults			// /C /N avoids multiple identical text entries

		endif

	endif
	
End

static  Function  /S	TBEvalHeaderAndResultsNm( ch )
	variable	ch
	return	"TBEvaHeader" + num2str( ch )
End

static Function  /S	PrintEvalTBHeader( ch )
// 040920	todo   gCurSwp ??? nCurSwp ??? gCurFrm
	variable	ch
	svar		gsDate		= root:uf:cfsr:gsDate		
	svar		gsTime		= root:uf:cfsr:gsTime		
	svar		gsComment	= root:uf:cfsr:gsComment		
	nvar		gProt			= root:uf:cfsr:gProt		
	nvar		gBlk			= root:uf:cfsr:gBlk		
	nvar		gFrm			= root:uf:cfsr:gFrm		
	nvar		gSwp		= root:uf:cfsr:gSwp		
	nvar		gOfs			= root:uf:cfsr:gOfs 
	nvar		gSize		= root:uf:cfsr:gSize 

	variable	nCurSwp		= GetLinSweep( cLOWER )	//  uses and possibly clips gProt	.. gSwp


// 040920
	nvar		gCurSwp		= root:uf:cfsr:gCurSwp
	variable	nSmpInt		= CFSSmpInt()
	variable	nOfsPts		= DSBegin( gCurSwp ) + gOfs * DSPoints( gCurSwp )	
	variable	ThisTraceStartTime	= nOfsPts * nSmpInt / cXSCALE						// in seconds

// 041010
	//variable	nDataPts	= DSPoints( gCurSwp ) 
	variable	nDataPts	= DSBegin( nCurSwp  + gSize ) - DSBegin( nCurSwp ) 

	variable	ThisTraceEndTime	= ( nOfsPts + nDataPts ) * nSmpInt / cXSCALE			// in seconds
	// variable	ThisTraceStartTime	= nOfsPts * nSmpInt / MILLITOMICRO				// in milliseconds

	svar		gsDataFileR	= root:uf:cfsr:gsDataFileR
	svar		gsStimFile		= root:uf:cfsr:gsStimFile
	string		sLine	= "" , sText = ""
	if ( strlen( RemoveWhiteSpace( gsComment ) )  &&  cmpstr( gsComment, ksNoGeneralComment )  ) 	// only if the user has entered a comment....
		sText	+= gsComment	+ "\r" 											//...then print the comment line ( above all other lines like in StimFit)
	endif
//	sTextBox1	+= gsDataFileR + "    (" + gsStimFile + ")    " + gsDate + "    " + gsTime +  "     " +  CfsIONm( ch ) + " (" + num2str( ch ) + ")" 
//	sTextBox1	+= "     Prot:" + num2str( gProt ) + "   Blk:" + num2str( gBlk ) + "   Frm:" + num2str( gFrm ) + "   Swp:" + num2str( gSwp ) + "    (" + num2str( nCurSwp ) + ")     Time: " + num2str( ThisTraceStartTime ) + "ms"  + "\r"
	sprintf sLine, "%s   (%s)   %s   %s   %s (%d)   Prot:%d   Blk:%d   Frm:%d   Swp:%d   (%d)   Time:%.6lf .. %.6lfs   Pts:%d ", gsDataFileR, gsStimFile, gsDate, gsTime, CfsIONm( ch ), ch, gProt, gBlk, gFrm, gSwp, nCurSwp,ThisTraceStartTime, ThisTraceEndTime,  nDataPts
	sText	+= sLine
	return	sText
End

Function		GetCurFrm()
	nvar		gFrm			= root:uf:cfsr:gFrm		
	return	gFrm
End


static Function	/S	PrintEvalTBHorzNames( sMask )
	string		sMask
	variable	m, n
	string		sEntry	= ""
	string		sLine		= "    "
	variable	fr	= GetCurFrm()
	for ( m = 0; m < ItemsInList( sMask ); m += 1 )
		n	= str2num( StringFromList( m, sMask ) )
		sprintf sEntry, "%11s",  EvalNm( n )				// formatted with tabs to compensate for the proportional font
		sLine		+= sEntry
	endfor
	//printf "%s\r", sLine
	return	sLine
End

static Function	/S	PrintEvalTBHorzValues( sRgTxt, ch, rg, sMask )
	variable	ch, rg
	string		sRgTxt, sMask
	variable	m, n
	string		sEntry	= ""
	string  	sLine		= sRgTxt
//	string		sLine		= "rg:" + num2str( rg ) + "\t"
	for ( m = 0; m < ItemsInList( sMask ); m += 1 )
		n	= str2num( StringFromList( m, sMask ) )
		sprintf sEntry, "%11.4lf",  Eval( ch, rg, n , cVAL )	// formatted with tabs to compensate for the proportional font
		sLine		+= sEntry
	endfor
	//printf "%s\r", sLine
	return	sLine
End


static Function	/S	PrintEvalTBFitResults( wPar, wStartPar, wInfo, sRgTxt, ch, rg, ph )
	wave  /D	wPar, wStartPar
	wave	wInfo
	string  	sRgTxt
	variable	ch, rg, ph
	nvar		gPrintMask= root:uf:eval:evl:gprintMask
	wave	wCRegion	= root:uf:eval:evl:wCRegion
	variable	nFitFunc	= wCRegion[ ch ][ rg ][ ph ][ CN_FITFNC ]
	string		sLine		= "" 
	string		sMsg, sFitAndStartPars = ""
	variable	n
	for ( n = 0; n < numPnts( wPar ); n += 1 )
		if ( gPrintMask &  RP_FITSTART )
			sFitAndStartPars   += ParName( nFitFunc, n ) + ": " + num2str( wPar[ n ] ) + " (" + num2str( wStartPar[ n ] ) + ")   "
		else
			sFitAndStartPars   += ParName( nFitFunc, n ) + ": " + num2str( wPar[ n ] ) + "   "
		endif
	endfor

	if ( ! wInfo[ kSTARTOK ] )
		sMsg			 = "  Fit failed as no start parameters could be found."
		sFitAndStartPars = ""
	elseif ( wInfo[ kNUMITER ] == 0 )													// show start values, do not fit
		sprintf	sMsg, "No fit, start values : " 
	elseif ( wInfo[ kNUMITER ] == wInfo[ kMAXITER ]   ||   wInfo[ kFITERROR ]  )
		sprintf	sMsg, "It:%2d/%d   *** Failed ***" , wInfo[ kNUMITER ],  wInfo[ kMAXITER ]		
	else
		sprintf	sMsg, "It:%2d/%d  Chi:%8.2g" ,  wInfo[ kNUMITER ],  wInfo[ kMAXITER ],  wInfo[ kCHISQ ]
	endif

	//sprintf sLine, "rg:%d  %s  %-10s  %s  %s ", rg, StringFromList( ph, ksPHASES),  StringFromList( nFitFunc, sFITFUNC ),  sMsg, sFitAndStartPars	// print the fitted and the starting values in one line
	sprintf sLine, "%s  %s  %-10s  %s  %s ", sRgTxt, StringFromList( ph, ksPHASES),  StringFromList( nFitFunc, sFITFUNC ),  sMsg, sFitAndStartPars	// print the fitted and the starting values in one line
	return	sLine
End

/////////////////////////////////////////////////////////////

static Function	/S	PrintEvalFileHorzHeader( sMask )
	string		sMask
	variable	m, n
	string		sEntry = "",  sLine	= ""
	for ( m = 0; m < ItemsInList( sMask ); m += 1 )
		n	= str2num( StringFromList( m, sMask ) )
		sprintf sEntry, " %11s",  EvalNm( n )				// formatted very much like STIMFIT file
		sLine		+= sEntry
	endfor
	return	sLine
End

static Function	/S	PrintEvalFileHorzValues( ch, rg, sMask )
	variable	ch, rg
	string		sMask
	variable	m, n
	string		sEntry = "", sLine	= ""
	for ( m = 0; m < ItemsInList( sMask ); m += 1 )
		n	= str2num( StringFromList( m, sMask ) )
		sprintf sEntry, " %11.4lf",  Eval( ch, rg, n , cVAL )		// formatted very much like STIMFIT file
		sLine		+= sEntry
	endfor
	return	sLine
End

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

static Function		DisplayCursor( ch, rg, ph, BegEnd, sWnd )
// We use waves to draw the markers instead of drawing primitives. Big advantage: no erasing is necessary.  Drawback: more elaborate code.
	variable	ch, rg, ph, BegEnd
	string		sWnd
	wave	wCRegion	= root:uf:eval:evl:wCRegion

	// Check whether the cursor wave exists already, if not then construct it
	variable	nCsr		= BegEnd - CN_BEG 
	string  	sChRgNFolder	= ksF_SEP + "csr" + ksF_SEP + "c" + num2str( ch ) + ksF_SEP 	// e.g  ':csr:c1:'
	string  	sXNm		= "wcX_r" + num2str( rg ) + "_p" + num2str( ph ) + "_n" + num2str( nCsr )
	string  	sYNm		= "wcY_r" + num2str( rg ) + "_p" + num2str( ph ) + "_n" + num2str( nCsr )
	wave	/Z	wX		= $"root:uf:eval" + sChRgNFolder + sXNm
	wave	/Z	wY		= $"root:uf:eval" + sChRgNFolder + sYNm
	if ( ! waveExists( wX )  ||  ! waveExists( wY ) )
		ConstructAndMakeItCurrentFolder( RemoveEnding( "root:uf:eval" + sChRgNFolder, ksF_SEP ) )
		make /O /N=11	  $"root:uf:eval" + sChRgNFolder + sXNm	= Nan	// X- and Y-waves containing 11 points : 4 lines and 3 Nan-points in between
		make /O /N=11	  $"root:uf:eval" + sChRgNFolder + sYNm	= Nan
	endif
	wave     wX = 	  $"root:uf:eval" + sChRgNFolder + sXNm
	wave     wY = 	  $"root:uf:eval" + sChRgNFolder + sYNm
	
	// Get the drawing parameters
	variable	x		= wCRegion[ ch ][ rg ][ ph ][ CN_BEG   + nCsr ]
	variable	y		= wCRegion[ ch ][ rg ][ ph ][ CN_BEGY + nCsr ]
	variable	nColor	= wCRegion[ ch ][ rg ][ ph ][ CN_COLOR ] 
	variable	CsrCnt	= wCRegion[ ch ][ rg ][ ph ][ CN_CSRCNT ] 
	variable	CsrShape	= wCRegion[ ch ][ rg ][ ph ][ CN_CSRSHAPE ] 
	variable	nDotting	= rg + 1								// 0 is line, rg 0 ~ 1 ~ very fine dots,  rg 1 ~ 2 ~ small dots,  rg 7 ~ 8 ~ coarse dotting

	variable	VertExt	= wCRegion[ ch ][ rg ][ ph ][ CN_CSRSHAPE ]  & CSR_YSHORT 		?  .25  :  .05		// make vertical lines longer ( 1 ~ Y full scale)
			VertExt	= wCRegion[ ch ][ rg ][ ph ][ CN_CSRSHAPE ]  & CSR_YFULL 		?   1	  :  VertExt		// make vertical lines longer ( 1 ~ Y full scale)
	variable	HrzValExt	= wCRegion[ ch ][ rg ][ ph ][ CN_CSRSHAPE ]  & CSR_VALSHORT  	?  .01  :  .04		// the middle stub : TURNED OFF AT THE MOMENT as the value is often out of range
			HrzValExt	= wCRegion[ ch ][ rg ][ ph ][ CN_CSRSHAPE ]  & CSR_VALMEDIUM	?  .05  :  HrzValExt	
			HrzValExt	= wCRegion[ ch ][ rg ][ ph ][ CN_CSRSHAPE ]  & CSR_VALFULL		?    1	  :  HrzValExt	

	// Get the current axis length
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

	// For some unknown reason neither  'GateAxis'  nor  ' AxisValFromPixel()'  work reliably. They do work often, though....
	wave	wMnMx	= root:uf:eval:evl:wMnMx
	variable	xMinMax	= wMnMx[ ch ] [ MM_XMAX ] - wMnMx[ ch ] [ MM_XMIN ]
	variable	yMinMax	= wMnMx[ ch ] [ MM_YMAX ] - wMnMx[ ch ] [ MM_YMIN ]



	// Compute the stub lengths
	variable	dxStubRight	=  CsrCnt ==  1   ||   BegEnd == CN_BEG  ?   0.008 	* xMinMax  : 0
	variable	dxStubLeft		=  CsrCnt ==  1   ||   BegEnd == CN_END  ?   0.008	* xMinMax  : 0
	variable	dxValRight		=  CsrCnt ==  1   ||   BegEnd == CN_BEG  ?   HrzValExt * xMinMax  : 0				//  the middle stub : TURNED OFF AT THE MOMENT as the value is often out of range
	variable	dxValLeft		=  CsrCnt ==  1   ||   BegEnd == CN_END  ?   HrzValExt * xMinMax  : 0

	wave	Red = root:uf:misc:Red, Green = root:uf:misc:Green, Blue = root:uf:misc:Blue
	wave	wEvalColor	= root:uf:eval:evl:wEvalColor

	// Compute cursor end points
	// wave	w = $"root:uf:eval:evl:wOrg" + num2str( ch )						// currently not used : w( x ) is the y-value of the data wave at the current cursor position
	yTop		=  yTop 	 -  .01 * ( yTop - yBottom )
	yBottom	=  yBottom + .01 * ( yTop - yBottom ) 
	// printf "\t\tDisplayCursor()\tch:%d  rg:%d  ph:%d  %s\txMinMax:\t%6.2lf\tstubXR:\t%6.2lf\t \r", ch, rg, ph, pd( StringFromList(ph, ksPHASES),9), xMinMax, dxStubRight

	// Check if the cursor is already in the graph, only if is yet missing then append it 
	string 		sTNL	= TraceNameList( sWnd, ";", 1 )
	//print  sYNm,sTNL
	if ( WhichListItem( sYNm, sTNL, ";" )  == cNOTFOUND )		// ONLY if  wave is not in graph...
		AppendToGraph /W=$sWnd wY vs wX
		ModifyGraph 	 /W=$sWnd  mode( 	$sYNm )	= 0		// 0 : lines, 3 : markers ,  4 : lines + markers
		ModifyGraph 	 /W=$sWnd  rgb( 	$sYNm )	= ( Red[ nColor ], Green[ nColor ], Blue[ nColor ] ) 
		if ( CsrCnt == 1 )
			ModifyGraph 	 /W=$sWnd  marker( 	$sYNm )	= 4
		else
			ModifyGraph 	 /W=$sWnd  marker( 	$sYNm )	= 48 -3 * nCsr//50 - 3 * nCsr //49 - 3 * nCsr // 33 - 2 * nCsr //wEvalShape[ n ]
		endif
		ModifyGraph 	 /W=$sWnd  msize( 	$sYNm )	= 0 //wEvalSize[ n ]
		ModifyGraph 	 /W=$sWnd  lstyle( 	$sYNm )	= nDotting
	 endif

	// Fill the cursor wave points so that the desired cursor shape is drawn
	// could be streamlined........
	if ( BegEnd == CN_BEG  && CsrCnt == 1 )						// only 1 cursor (Latency) : draw stubs to both sides
		wX[ 0 ]	= x + dxStubRight	; 	wY[ 0 ] = yTop			// upper stub
		wX[ 1 ]	= x  - dxStubRight	; 	wY[ 1 ] = yTop			// 
	
		wX[ 3 ]	= x  				; 	wY[ 3 ] = yTop			// vertical line
		wX[ 4 ]	= x				; 	wY[ 4 ] = yBottom		// 
	
		wX[ 6 ]	= x  - dxStubRight	; 	wY[ 6 ] = yBottom		// lower stub
		wX[ 7 ]	= x + dxStubRight	; 	wY[ 7 ] = yBottom		//
	endif
	if ( BegEnd == CN_BEG  && CsrCnt == 2 )						// left cursor : draw stubs to the right
		wX[ 0 ]	= x + dxStubRight	; 	wY[ 0 ] = yTop			// upper stub
		wX[ 1 ]	= x  				; 	wY[ 1 ] = yTop			// 
	
		wX[ 3 ]	= x  				; 	wY[ 3 ] = yTop			// vertical line
		wX[ 4 ]	= x				; 	wY[ 4 ] = yBottom		// 
	
		wX[ 6 ]	= x  				; 	wY[ 6 ] = yBottom		// lower stub
		wX[ 7 ]	= x + dxStubRight	; 	wY[ 7 ] = yBottom		//
	endif
	if ( BegEnd == CN_END  && CsrCnt == 2 )						// right cursor : draw stubs to the left
		wX[ 0 ]	= x  - dxStubLeft		; 	wY[ 0 ] = yTop			// upper stub
		wX[ 1 ]	= x 				; 	wY[ 1 ] = yTop			// 
	
		wX[ 3 ]	= x  				; 	wY[ 3 ] = yTop			// vertical line
		wX[ 4 ]	= x				; 	wY[ 4 ] = yBottom		// 
	
		wX[ 6 ]	= x 				; 	wY[ 6 ] = yBottom		// lower stub
		wX[ 7 ]	= x  - dxStubLeft		; 	wY[ 7 ] = yBottom		// 
	endif

	// wX[ 9 ]	 	= x  - dxValLeft		; 	wY[ 9 ]   = y       			// the middle stub : TURNED OFF AT THE MOMENT as the value is often out of range
	// wX[ 10 ]     	= x + dxValRight		; 	wY[ 10 ] = y			// 

	// Blank out unused fit cursors. Alternate approach: An entry in wcRegion[ ][ ][ ][ CN_VISIBLE ].........
	nvar		gFitCnt	= root:uf:eval:evl:gfitCnt
	if ( gFitCnt <= 2  &&  ph == PH_FIT2 )
		wY = Nan	
	elseif ( gFitCnt <= 1  &&  ph == PH_FIT1 )
		wY = Nan	
	elseif ( gFitCnt <= 0  &&  ph == PH_FIT0 )
		wY = Nan	
	endif
End


Function		EraseAndClearFits( ch, sWnd )
// Clear   fitted segments  from the display. This can be done by clearing the folder,  by setting the value to  Nan  or by deleting the wave. 
// It is not sufficient to only erase the points in the graph because they will reappear (with wrong values) when advancing from file to file. 
	variable	ch
	string  	sWnd
	string  	lstTNL		= TraceNameList( sWnd, ";", 1 )
	string		lstMatched	= ListMatch( lstTNL, "wF*" )
	// print "\t\tEraseAndClearCursors", lstmatched
	variable	t, tCnt			=  ItemsInList( lstMatched ) 
	for ( t = 0; t < tCnt; t += 1 )		
		RemoveFromGraph  /W=$sWnd $StringFromList( t, lstmatched )
	endfor
	string  	sFittedSegmentFolder	= "root:uf:eval:fit" + ksF_SEP + "c" + num2str( ch ) 
	if ( DataFolderExists( sFittedSegmentFolder ) )	// will not exist if number of fits = 0
		KillDataFolder  $sFittedSegmentFolder
	endif
End

Function		EraseAndClearCursors( ch, sWnd )
// Clear   cursors  from the display. This can be done  by clearing the folder, by setting the value to  Nan  or by deleting the wave. 
// It is not sufficient to only erase the points in the graph because they will reappear (with wrong values) when advancing from file to file. 
	variable	ch
	string  	sWnd
	string  	lstTNL		= TraceNameList( sWnd, ";", 1 )
	string		lstMatched	= ListMatch( lstTNL, "wC*" )
	// print "\t\tEraseAndClearCursors", lstmatched
	variable	t, tCnt			=  ItemsInList( lstMatched ) 
	for ( t = 0; t < tCnt; t += 1 )		
		RemoveFromGraph  /W=$sWnd $StringFromList( t, lstmatched )
	endfor
	KillDataFolder  $"root:uf:eval:csr" + ksF_SEP + "c" + num2str( ch ) 
End

Function		EraseAndClearEvaluatedPoints( ch, sWnd )
// Clear evaluated data points from the display. This can be done  by clearing the folder, by setting the value to  Nan  or by deleting the wave. 
// It is not sufficient to only erase the points in the graph because they will reappear (with wrong values) when advancing from file to file. 
	variable	ch
	string  	sWnd
	string  	lstTNL		= TraceNameList( sWnd, ";", 1 )
	string		lstMatched	= ListMatch( lstTNL, "wP*" )
	// print "\t\tEraseAndClearEvaluatedPoints", lstmatched
	variable	t, tCnt			=  ItemsInList( lstMatched ) 
	for ( t = 0; t < tCnt; t += 1 )	
		RemoveFromGraph  /W=$sWnd $StringFromList( t, lstmatched )
	endfor
	KillDataFolder  $"root:uf:eval:pts" + ksF_SEP + "c" + num2str( ch ) 
End


static Function		DisplayEvaluatedPoints( ch, rg, sWnd )
//  Using Igor markers : ++ markers always keep their size independent of zoom,  ++ needs no redraw (except long hor/vert lines), ++no erasing is necessary, ++simple code (similar to DisplayCursor() ).  
	variable	ch, rg
	string		sWnd
	variable	n
	variable	x, y

	// Get the current X axis length
	GetAxis /W=$sWnd /Q bottom
	variable	xLeft		= V_min  + .01 * ( V_max - V_min )
	variable	xRight	= V_max  - .01 * ( V_max - V_min )			// do not extend over complete range, leave a little bit free on each side 
	GetAxis /W=$sWnd /Q left
	variable	yBottom	= V_min
	variable	yTop		= V_max 

	// Get the drawing parameters
	wave	Red = root:uf:misc:Red, Green = root:uf:misc:Green, Blue = root:uf:misc:Blue
	wave	wEvalColor	= root:uf:eval:evl:wEvalColor
	wave	wEvalShape	= root:uf:eval:evl:wEvalShape

	for ( n = 0; n < EV_MAXPTS; n += 1 )
		// Check whether the eval data points wave exists already, if not then construct it
		string  	sChRgNFolder	= ksF_SEP + "pts" + ksF_SEP + "c" + num2str( ch ) + ksF_SEP 	// e.g  'pts:c1:'
		string  	sXNm		= "wpX_r" + num2str( rg ) + "_n" + num2str( n ) 
		string  	sYNm		= "wpY_r" + num2str( rg ) + "_n" + num2str( n ) 
		wave	/Z	wX	= $"root:uf:eval" + sChRgNFolder + sXNm
		wave	/Z	wY	= $"root:uf:eval" + sChRgNFolder + sYNm
		if ( ! waveExists( wX )  ||  ! waveExists( wY ) )
			ConstructAndMakeItCurrentFolder( RemoveEnding( "root:uf:eval" + sChRgNFolder, ksF_SEP ) )
			make /O /N=2 	  $"root:uf:eval" + sChRgNFolder + sXNm	= Nan	// X- and Y-waves containing just 22222222222... evaluated data point
			make /O /N=2 	  $"root:uf:eval" + sChRgNFolder + sYNm	= Nan
		endif
		wave	wX	= $"root:uf:eval" + sChRgNFolder + sXNm
		wave	wY	= $"root:uf:eval" + sChRgNFolder + sYNm

		// Get data point to be drawn
		//printf "\t\tDispEval..\tch:%d  rg:%d  pt:%d %s\tt:%6.2lf\ty:%6.2lf \txSp:\t%7.2lf\tySs:\t%7.2lf\t\r", ch, rg, n, pd( StringFromList(n, sEVAL),9), EvT( ch, rg, n ),  EvY( ch, rg, n ), xSizeP, ySizeP
		x = EvT( ch, rg, n )
		y = EvY( ch, rg, n )

		// Check if the data point is already in the graph, only if it is yet missing then append it 
		string 		sTNL	= TraceNameList( sWnd, ";", 1 )
		if ( WhichListItem( sYNm, sTNL, ";" )  == cNOTFOUND )			// ONLY if  wave is not in graph...
			variable	 nColor	= wEvalColor[ n ]
			variable	shp		= wEvalShape[ n ]
			AppendToGraph /W=$sWnd wY vs wX
			ModifyGraph 	 /W=$sWnd  rgb( 	$sYNm )	= ( Red[ nColor ], Green[ nColor ], Blue[ nColor ] ) 
			if ( shp == cLLINEH  ||  shp == cLLINEV )
				ModifyGraph 	 /W=$sWnd  mode( 	$sYNm )	= 0		// 0 : lines, 3 : markers ,  4 : lines + markers
			else
				ModifyGraph 	 /W=$sWnd  mode( 	$sYNm )	= 3		// 0 : lines, 3 : markers ,  4 : lines + markers
				ModifyGraph 	 /W=$sWnd  marker( 	$sYNm )	= shp
				variable	size	= ( shp == cSLINEH  ||  shp == cSLINEV  ||  shp == cSCROSS ||  shp == cXCROSS ) ? 10 : 0	// Rect and Circle have automatic size = 0
				ModifyGraph 	 /W=$sWnd  msize( 	$sYNm )	= size
			endif
		 endif

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

	endfor
End


//	if ( nShape == SLOPE )
//		// DrawPoly	/W=$sWnd	rLeft-2, rBot, 1, 1,  {rLeft-2, rBot, rLeft+2, rBot, rRight+2, rTop, rRight-2, rTop, rLeft-2, rBot }	// thick bar
//		 DrawPoly	/W=$sWnd	rLeft-1, rBot, 1, 1,  {rLeft-1, rBot, rLeft+1, rBot, rRight+1, rTop, rRight-1, rTop, rLeft-1, rBot }	// thin bar

//	endfor
//	SetDrawEnv	/W=$sWnd	dash 	= 0			,save
//	SetDrawLayer	/W=$sWnd	ProgFront
//End

static Function		RescaleEvaluatedDataPoints( ch )
	variable	ch
	wave	wChanOpts= root:uf:eval:evl:wChanOpts
	variable	rg, rgCnt	 = wChanOpts[ ch ][ CH_RGCNT ]
	for ( rg = 0; rg < rgCnt;  rg += 1 )	
		string		sWnd	= CfsWndNm( ch )
		DisplayEvaluatedPoints( ch, rg, sWnd )
	endfor
End

static Function		RescaleCursors( ch )
	variable	ch
	wave	wChanOpts= root:uf:eval:evl:wChanOpts
	variable	rg, rgCnt	 = wChanOpts[ ch ][ CH_RGCNT ]
	for ( rg = 0; rg < rgCnt;  rg += 1 )	
		string		sWnd	= CfsWndNm( ch )
		variable	ph, phCnt	= ItemsInList( ksPHASES )
		for ( ph = 0; ph < phCnt;  ph += 1 )	
			variable	BegEnd
			for ( BegEnd = CN_BEG; BegEnd <= CN_END;  BegEnd += 1 )	
				DisplayCursor( ch, rg, ph, BegEnd, sWnd )
			endfor
		endfor
	endfor
End

static Function		RescaleAllCursors()
	variable	ch
	nvar		gChans	= root:uf:cfsr:gChannels					
	for ( ch = 0; ch < gChans;  ch += 1 )	
		RescaleCursors( ch )
	endfor
End


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  IMPLEMENTATION of  EVAL

static Function		EvT( ch, rg, pt )
	variable	ch, rg, pt
	wave	wEval	= root:uf:eval:evl:wEval
	return	wEval[ ch ][ rg ][ pt ][ cT ]
End	

static Function		EvY( ch, rg, pt )
	variable	ch, rg, pt
	wave	wEval	= root:uf:eval:evl:wEval
	return	wEval[ ch ][ rg ][ pt ][ cY ]
End	

static Function		EvV( ch, rg, pt )
	variable	ch, rg, pt
	wave	wEval	= root:uf:eval:evl:wEval
	return	wEval[ ch ][ rg ][ pt ][ cVAL ]
End	

static Function		Eval( ch, rg, pt, nType )
	variable	ch, rg, pt, nType
	wave	wEval	= root:uf:eval:evl:wEval
	//printf "\t\tEval( \t\tch:%d  rg:%d  pt:%d  nType:%d )  \tretrieves\t%g   \r", ch, rg, pt, nType, wEval[ ch ][ rg ][ pt ][ nType ]
	return	wEval[ ch ][ rg ][ pt ][ nType ]
End	

static Function		SetEval( ch, rg, pt, nType, Value ) 
	variable	ch, rg, pt,  nType, Value
	wave	wEval	= root:uf:eval:evl:wEval
	wEval[ ch ][ rg ][ pt ][ nType ] = Value
	//printf "\t\tSetEval( \tch:%d  rg:%d  pt:%d  nType:%d )  \tstores \t%g    =?= %g  =?= %g \r", ch, rg, pt, nType, value, Eval( ch, rg, pt, nType ), wEval[ ch ][ rg ][ pt ][ nType ]
End	

static Function		ExistsEvT( ch, rg, pt )
	variable	ch, rg, pt
	wave	wEval	= root:uf:eval:evl:wEval
	return	numtype( wEval[ ch ][ rg ][ pt ][ cT ] ) != NUMTYPE_NAN
End	
static Function		ExistsEvY( ch, rg, pt )
	variable	ch, rg, pt
	wave	wEval	= root:uf:eval:evl:wEval
	return	numtype( wEval[ ch ][ rg ][ pt ][ cY ] ) != NUMTYPE_NAN
End	
//Function		E_ExistsEval( ch, rg, typ )
//	variable	ch, rg, typ
//	wave	wCRegion	= root:uf:eval:evl:wCRegion
//variable xx=0//todo
//	return	wCRegion[ ch ][ rg ][ xx ][ typ ]  !=  1		// todo must be nan or inf
//End	


static Function	/S	EvalNm( pt )
	variable	pt
	return	StringFromList( pt, sEVAL )
End	



//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//   EVALUATION  WINDOW  HOOK  FUNCTION
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

static constant	kDOUBLECLICK_TIME 	= 30
static constant	kDOUBLECLICK_RANGE	= 5		// 5 pixel may be too small when a cursor is close to or on an axis
// 041224 static removed
 constant	kPAGEUP				= 11
 constant	kPAGEDOWN			= 12
 constant	kARROWLEFT			= 28
 constant	kARROWRIGHT		= 29
 constant	kARROWUP			= 30
 constant	kARROWDOWN		= 31


Function 		fEvalWndNamedHook( s )
// Detects and reacts on double clicks and keystrokes without executing  Igor's default double click actions. Parts of the code are taken from WM 'Percentile and Box Plot.ipf'
	struct	WMWinHookStruct &s 			// test ? static 
	wave	wCurRegion	= root:uf:eval:evl:wCurRegion
	wave	wMagn		= root:uf:eval:evl:wMagn
	wave	wMnMx		= root:uf:eval:evl:wMnMx
	variable	returnVal		= 0
	variable	ch 			= CfsWndNm2Ch( s.winName )
	variable	xaxval		= AxisValFromPixel( s.winName, "bottom", s.mouseLoc.h  )
	variable	yaxval		= AxisValFromPixel( s.winName, "left", s.mouseLoc.v  )
	string  	sKey			= num2char( s.keycode )
	variable 	isClick		= ( s.eventCode == kWHK_mouseup ) + ( s.eventCode == kWHK_mousedown )	// a click is either a MouseUp or a MouseDown

	if ( s.eventCode	!= kWHK_mousemoved )
		//print s
		//printf "\t\t\tfEvalWndNamedHook()\t\tEvntCode:%2d\t%s\tmod:%2d\tch:%d\t'%s'\t'%s' =%3d\tX:%4d\t%7.3lf\tY:%4d\t%7.3lf\t \r ", s.eventCode, pd( StringFromList( s.eventCode, lstWINHOOKCODES ), 8 ), s.eventMod, ch, s.winName,  sKey, s.keycode, s.mouseLoc.h, xaxval, s.mouseLoc.v, yaxval
	endif

	//  MOUSE  PROCESSING
	if( isClick )													// can be either mouse up or mouse down
		wCurRegion[ cCH ]		= ch								// Remember value for Expand, Shrink, Up, Down, Left, Right 
		wCurRegion[ cMODIF ]	= s.eventMod						// the modifier (SHIFT, CTRL, ALT)  is needed  when the user leaves the graph to click a panel button rather than staying in the graph and using a key
		wCurRegion[ cXMOUSE ]	= xAxVal							// last clicked x is needed for cursor adjustment when the user leaves the graph to click a panel button rather than staying in the graph and using a key
		wCurRegion[ cYMOUSE ]	= yAxVal							// last clicked y is needed for cursor adjustment when the user leaves the graph to click a panel button rather than staying in the graph and using a key
	endif	


	//  KEYSTROKE  PROCESSING
	nvar	/Z	gbInCursorMode= root:uf:eval:evl:gbInCursorMode				// globals to be used as static locals
	nvar	/Z	gnKey1		= root:uf:eval:evl:gnKey1						//

	if ( !nvar_Exists( gnKey1) ) //  ||  !nvar_Exists(MouseDnX)  ||  !nvar_Exists(MouseDnY)  ||  !nvar_Exists(MouseDnTime)  ||  !nvar_Exists(bSawDblClick) ) 
		variable	/G	root:uf:eval:evl:gbInCursorMode	= FALSE				// Start with the arrow keys navigating through the data file rather than moving the crosshair cursors
		variable  	/G	root:uf:eval:evl:gnKey1		= cNOTFOUND			// The first key of a 2-key-combination must be remembered when the second key is processed. Code requires to start with NOTFOUND.
		nvar	/Z	gbInCursorMode			= root:uf:eval:evl:gbInCursorMode// make the local globals known...
		nvar	/Z	gnKey1					= root:uf:eval:evl:gnKey1		//
	endif
	
	// For keyboard strokes we can only use the SHIFT modifier,  ALT interferes with Igor's menu, CTRL with Igor's shortcuts. Mouse CTRL ALT is OK.
	// Uses Stimfits 2-letter-shortcuts consequently. Only ADDITIONALLY buttons are provided...
	if ( s.eventCode == kWHK_keyboard ) 

		if ( gnKey1	!= cNOTFOUND )								// Are we expecting the 2. key of a  2-key-combination ?
			if ( IsValidKeyCombination( gnKey1, s.keycode ) )				// Is the 2. key appropriate for the 1. key? 
				ExecuteActions( gnKey1, s.keycode )
			else												// It is not a valid 2. key 
				if ( IsKey1of2( s.keycode ) )							// It is a 1. key of a new 2-key-combination
					gnKey1		= s.keycode
				else											// It is a single key
					gnKey1		= cNOTFOUND
					ExecuteActions( s.keycode, cNOTFOUND)
				endif
			endif
		else
			if ( IsKey1of2( s.keycode ) )								// It is a 1. key of a new 2-key-combination
				gnKey1		= s.keycode
			else												// It is a single key
				gnKey1		= cNOTFOUND
				ExecuteActions( s.keycode, cNOTFOUND)
			endif
		endif		
	endif

	return returnVal							// 0 : allow further processing by Igor or other hooks ,  1 : prevent any additional processing 
End


//static Function	ProcessKey1()	
//End


// could PROBABLY NOT / PERHAPS be simplified by recognizing the SHIFT modifier 
// Define the 2-key-combinations. Separartor is '~'  . The first 2 entries after '~' are the primary key, any number of following entries are the secondary keys.  
//								X				   Y						Peak		Fit0		Fit1		    Fit2		
strconstant	ksKeyCombinations	= "x;X;e;E;s;S;l;L;r;R;28;29~y;Y;e;E;s;S;u;U;d;D;30;31~p;P;b;B;e;E~f;F;b;B;e;E~g;G;b;B;e;E~h;H;b;B;e;E"	// 28 arrR, 29 arrL, 30 arrU, 31 arrD, 11 pgU, 12 pgD 
						
static Function	IsKey1of2( nKey1 )
// Is  'nKey1'  the  1. key of a 2-key-combination ? 
	variable	nKey1
	variable	g, nGroups	= ItemsInList( ksKeyCombinations, "~" )	// e.g.  X , Y , E_rase
	variable	i1, nFirstKeys = 2, nGroupKey1
	string  	sGroup, sGroupKey1

	for ( g = 0; g < nGroups; g += 1 )
		sGroup		= StringFromList( g, ksKeyCombinations, "~" )
		for ( i1 = 0; i1< nFirstKeys; i1 += 1 )
			sGroupKey1	= StringFromList( i1, sGroup )
			nGroupKey1	= numType( str2num( sGroupKey1 ) ) == cNUMTYPE_NAN  ?  char2num( sGroupKey1 )  : str2num( sGroupKey1 )		// e.g. convert "A" to 65  and "28" to 28 	
			if ( nKey1 == nGroupKey1 )
				return	TRUE							// found  'nKey1'  as first key of a combination
			endif
		endfor
	endfor
	return	FALSE
End

static Function	IsValidKeyCombination( nKey1, nKey2 )
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
			nGroupKey1	= numType( str2num( sGroupKey1 ) ) == cNUMTYPE_NAN  ?  char2num( sGroupKey1 )  : str2num( sGroupKey1 )		// e.g. convert "A" to 65  and "28" to 28 	
			for ( i2 = 2; i2 < 2 + nSecondKeys; i2 += 1 )
				sGroupKey2	= StringFromList( i2, sGroup )
				nGroupKey2	= numType( str2num( sGroupKey2 ) ) == cNUMTYPE_NAN  ?  char2num( sGroupKey2 )  : str2num( sGroupKey2 )	// e.g. convert "A" to 65  and "28" to 28 	
				if ( nKey1 == nGroupKey1  &&   nKey2 == nGroupKey2 )
					//printf "\t\t\t\tIsValidKeyCombination( key1:%3d (%s), key2:%3d(%s) )  returns TRUE \r",   nKey1, num2char(nKey1),   nKey2, num2char(nKey2) 
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

static Function	ExecuteActions( nKey1, nKey2 )
	variable  	nKey1, nKey2

	if ( nKey2 == cNOTFOUND )									// NORMAL  1-KEY-PROCESSING
	
		//printf "\t\t\tfEvalWndNamedHook()\tExecuteActions() : 1 key processing \tCod:%3d,%3d:\t%s, \r ",  nKey1, nKey2, num2char(nKey1)

		switch( nKey1 )

			case   27 :											// ESC
				buDispCfsESC( "buDispCfsESC" )					// looks like a button procedure but has no button 	
				break

			case   43 :											// +	Plus  peak points
				buDispCfsPlus( "buDispCfsPlus" ) 	
				break

			case   45 :											// -	Minus  peak points
				buDispCfsMinus( "buDispCfsMinus" ) 	
				break

			case  65 :											// A	store in Average
			case  97 :											// a
				buDispCfsKeepAvg( "buDispCfsKeepAvg" )
				break

			case  66 :											// b	Base set  right cursor
				buDispCfsBaseRSetCsr( "buDispCfsBaseRSetCsr" ) 	
				break

			case  98 :											// B	Base set  left   cursor
				buDispCfsBaseLSetCsr( "buDispCfsBaseLSetCsr" ) 	
				break

			case   68 :											// D	
			case 100 :											// d
				break

			case   70 :											// F
			case 102 :											// f
				break

			case   73 :											// I	Info
			case 105 :											// i
				buDispCfsInfo( "buDispCfsInfo" ) 	
				break

			case   77 :											// M	Move number of sweeps in file
			case 109 :											// m
				buDispCfsMove( "buDispCfsMove" ) 	
				break

			case   78 :											// N	Align
			case 110 :											// n
				break
				
//			case   80 :											// P	Peak set cursor is 2-key-combination
//			case 112 :											// p
//				buDispCfsPeakBegSetCsr( "buDispCfsPeakSetCsr" ) 	
//				break

			case   82 :											// R	Results
			case 114 :											// r
				buDispCfsResults( "buDispCfsResults" ) 	
				break

			case   83 :											// S
			case 115 :											// s
				break

			case   84 :											// T	store in Table
			case 116 :											// t
				buDispCfsKeepTbl( "buDispCfsKeepTbl" )
				break

			case kARROWLEFT :
				buDispCfsPrevData( "buDispCfsPrevData" ) 	
				break

			case kARROWRIGHT :
					buDispCfsNextData( "buDispCfsNextData" ) 	
				break

			case kARROWUP :
				buDispCfsFirstData( "buDispCfsFirstData" ) 	
				break

			case kARROWDOWN :
				buDispCfsLastData( "buDispCfsLastData" ) 	
				break

			case  32 :											// 'SPACE'  display same data again
				buDispCfsSameData( "buDispCfsSameData" ) 	
				break

		endswitch

	else																	// SPECIAL  2-KEY-PROCESSING

		//printf "\t\t\tfEvalWndNamedHook()\tExecuteActions() : 2 key processing \tCod:%3d,%3d:\t%s,%s\t \r ",  nKey1, nKey2, num2char(nKey1), num2char(nKey2)
		switch( nKey1 )
			case   88 :														// X 
			case 120 :														// x 
				if ( 	nKey2 ==  69  ||   nKey2 == 101 )								// E or e	Expand 
					buDispCfsXExpand( "buDispCfsXExpand" ) 	
				elseif ( nKey2 == 83  ||   nKey2 == 115 )							// S or s	Shrink 
					buDispCfsXShrink( "buDispCfsXShrink" ) 	
				elseif ( nKey2 ==  76 	||   nKey2 ==  108  ||  nKey2 == kARROWLEFT   )		// L or l 	Left
					buDispCfsXLeft( "buDispCfsXLeft" ) 	
				elseif ( nKey2 == 82 	||   nKey2 == 114  ||  nKey2 ==  kARROWRIGHT )	// R or r	Right
					buDispCfsXRight( "buDispCfsXRight" ) 	
				endif
				break

			case   89 :														// Y 
			case 121 :														// y 
				if ( 	nKey2 ==  69  ||   nKey2 == 101 )								// E or e	Expand 
					buDispCfsYExpand( "buDispCfsYExpand" ) 	
				elseif ( nKey2 == 83  ||   nKey2 == 115 )							// S or s	Shrink 
					buDispCfsYShrink( "buDispCfsYShrink" ) 	
				elseif ( nKey2 == 85  ||  nKey2 == 117  ||  nKey2 == kARROWUP   )		// U or u	Up 
					buDispCfsYUp( "buDispCfsYUp" ) 	
				elseif ( nKey2 == 68 ||  nKey2 == 100  ||  nKey2 == kARROWDOWN )		// D or d	Down 
					buDispCfsYDown( "buDispCfsYDown" ) 	
				endif
				break

			case   80 :														// P	Peak set cursor
			case 112 :														// p
				if ( 	nKey2 ==  66  ||   nKey2 ==  98 )								// B or b	Begin of Peak range  ( left  peak cursor )
					buDispCfsPeakBegSetCsr( "buDispCfsPeakBegSetCsr" ) 	
				elseif ( 	nKey2 ==  69  ||   nKey2 == 101 )							// E or e	End   of Peak range  ( right peak cursor )
					buDispCfsPeakEndSetCsr( "buDispCfsPeakEndSetCsr" ) 	
				endif
				break

			case   70 :														// F	Fit0 set cursor
			case 102 :														// f
				if ( 	nKey2 ==  66  ||   nKey2 ==  98 )								// B or b	Begin of Peak range  ( left  peak cursor )
					buDispCfsFit0BegSetCsr( "buDispCfsFit0BegSetCsr" ) 	
				elseif ( 	nKey2 ==  69  ||   nKey2 == 101 )							// E or e	End   of Peak range  ( right peak cursor )
					buDispCfsFit0EndSetCsr( "buDispCfsFit0EndSetCsr" ) 	
				endif
				break

			case   71 :														// G	Fit1 set cursor
			case 103 :														// g
				if ( 	nKey2 ==  66  ||   nKey2 ==  98 )								// B or b	Begin of Peak range  ( left  peak cursor )
					buDispCfsFit1BegSetCsr( "buDispCfsFit1BegSetCsr" ) 	
				elseif ( 	nKey2 ==  69  ||   nKey2 == 101 )							// E or e	End   of Peak range  ( right peak cursor )
					buDispCfsFit1EndSetCsr( "buDispCfsFit1EndSetCsr" ) 	
				endif
				break

			case   72 :														// H	Fit2 set cursor
			case 104 :														// h
				if ( 	nKey2 ==  66  ||   nKey2 ==  98 )								// B or b	Begin of Peak range  ( left  peak cursor )
					buDispCfsFit2BegSetCsr( "buDispCfsFit2BegSetCsr" ) 	
				elseif ( 	nKey2 ==  69  ||   nKey2 == 101 )							// E or e	End   of Peak range  ( right peak cursor )
					buDispCfsFit2EndSetCsr( "buDispCfsFit2EndSetCsr" ) 	
				endif
				break

		endswitch
	endif
End
	


//static Function		FindClickedPhaseCursor( sWnd, ch, xPix, yPix, modifier )
//	string		sWnd
//	variable	ch, xPix, yPix, modifier
//	wave	wCRegion	= root:uf:eval:evl:wCRegion
//	variable	rg, ph, nCsr
//	variable	xAxVal	= AxisValFromPixel( sWnd, "bottom", xPix )fb
//	variable	xSnapRng	= abs( AxisValFromPixel( sWnd, "bottom", kDOUBLECLICK_RANGE ) - AxisValFromPixel( sWnd, "bottom", 0 ) )
//	variable	yAxVal	= AxisValFromPixel( sWnd, "left", yPix )
//	variable	ySnapRng	= abs( AxisValFromPixel( sWnd, "left", kDOUBLECLICK_RANGE ) - AxisValFromPixel( sWnd, "left", 0 ) )
//	//printf "\t\tFindClickedPhaseCursor( ch:%d  xPix:%4d  >xRng %d..%d \tyPix:%4d >yRng %d..%d )\r", ch, xPix, xAxVal - xSnapRng, xAxVal  + xSnapRng, yPix, yAxVal - ySnapRng, yAxVal  +  ySnapRng
//	variable	bFound	= FALSE
//	for ( rg = 0; rg < RG_MAX  &&  bFound == FALSE; rg += 1 )
//		for ( ph = 0; ph < PH_MAX &&  bFound == FALSE; ph += 1 )
//			for ( nCsr = 0; nCsr < wCRegion[ ch ][ rg ][ ph ][ CN_CSRCNT ]; nCsr += 1 )
//				variable	xPhCsr	=  wCRegion[ ch ][ rg ][ ph ][ CN_BEG   + nCsr ]		
//				//variable	yPhCsr	=  wCRegion[ ch ][ rg ][ ph ][ CN_BEGY + nCsr ]	// 040823
//				//printf "\t\tFindClickedPhaseCursor( ch:%d  X:%3d...%3d ?\t%3d   \tY:%3d...%3d ?\t%3d )  \tCHECKED rg:%d  ph:%d  nCsr:%d %s \r", ch, xAxVal- xSnapRng, xAxVal+xSnapRng, xPhCsr, yAxVal- ySnapRng, yAxVal+ySnapRng, yPhCsr,  rg, ph, nCsr, SelectString( abs( xPhCsr - xAxVal ) < xSnapRng  || abs( yPhCsr - yAxVal ) < ySnapRng , "-> - ", "-> FOUND x and/or y" )
//
//				if ( abs( xPhCsr - xAxVal ) < xSnapRng )									// Version 1 : user can double click anywhere on the vertical line 
//				//if ( abs( xPhCsr - xAxVal ) < xSnapRng  &&  abs( yPhCsr - yAxVal ) < ySnapRng )		// Version 2 : user must double click on the intersection of vertical line and the hor. stubs
//
//					//printf "\t\tFindClickedPhaseCursor( ch:%d  xPix:%4d >%d+-%d  ? %d   \tyPix:%4d )   FOUND  rg:%d  ph:%d  nCsr:%d \r", ch, xPix, xAxVal, xSnapRng, xPhCsr, yPix, rg, ph,  nCsr 
//				
//					DrawEval1( ch, rg, ph, CN_BEG   + nCsr, FALSE ) 		// cosmetics: clear old region or cursor immediately
//					string		sWvNm		= "wOrg" + num2str(  ch )
//					variable	rRed, rGreen, rBlue
//					EvalRegionColor( ch, rg, ph, rRed, rGreen, rBlue )
//	
//					wave	wCurRegion	= root:uf:eval:evl:wCurRegion
//					wCurRegion[ cCH ]		= ch						// save until 'Accept'
//					wCurRegion[ cRG ]		= rg						// ...
//					wCurRegion[ cPH ]		= ph						// ...
//					wCurRegion[ cCURSOR ]	= nCsr 					// ...
//					nvar	gbInCursorMode	= root:uf:eval:evl:gbInCursorMode
//					gbInCursorMode		= TRUE					// the arrow keys must now move Igor's cursors and must no longer navigate through the data file
//		
//					// Cursor /F /W=$CfsWndNm( ch ) /A=1 /H=1 /S=1 /L=0  /C=(rRed, rGreen, rBlue)  A, $sWvNm, xPhCsr, yPhCsr	// draw the 'Free' crosshair cursor
//					// Cursor	  /W=$CfsWndNm( ch ) /A=1 /H=1 /S=1 /L=0  /C=(rRed, rGreen, rBlue)  A, $sWvNm, xPhCsr		// 040823 draw the 'locked-to-wave' crosshair cursor
//					string  	sCursorAorB	= SelectString( nCsr, "A", "B" )
//					Cursor      /W=$CfsWndNm( ch ) /A=1 /H=1 /S=1 /L=0  /C=(rRed, rGreen, rBlue)  $sCursorAorB, $sWvNm, xPhCsr	// 040823 draw the 'locked-to-wave' crosshair cursor
//
//					ShowInfo	/W= $CfsWndNm( ch )  				// 040823 Display the small cursor control box. This is not mandatory for cursor usage.
//					// Now we are in  Igors 'Cursor' mode.  Igor allows moving its cursor with the mouse or with the arrow keys
//					// It is our responsability to quit the 'Cursor' mode,  e.g. by  pressing  the  AdjustAccept button, by pressing ESC  or by releasing (or clicking) the mouse  
//	
//					bFound	= TRUE
//					break			// breaking  out of the outer two loops also is done above in the loop condition 
//				endif
//			endfor
//		endfor
//	endfor
//	// There was no PhaseCursor at the double clicked position, so the user wants to magnify around this point
//	// shift 2,  alt 4, ctrl 8
//	if ( ! bFound )
//		wave	wMagn	= root:uf:eval:evl:wMagn
//		if( modifier & 4 )				// alt key	: reset X and Y
//			wMagn[ ch ][ cXSHIFT ]	= 0
//			wMagn[ ch ][ cXEXP ]	= 1
//			wMagn[ ch ][ cYSHIFT]	= 0
//			wMagn[ ch ][ cYEXP ]	= 1
//		elseif ( modifier & 2 )			// shift key: expand Y
//			wMagn[ ch ][ cYSHIFT]	=  yAxVal 
//			wMagn[ ch ][ cYEXP ]	*= 2
//		elseif( modifier & 8 )			// ctrl key	: expand X and Y
//			wMagn[ ch ][ cXSHIFT ]	=  xAxVal 
//			wMagn[ ch ][ cXEXP ]	*= 2
//			wMagn[ ch ][ cYSHIFT]	=  yAxVal 
//			wMagn[ ch ][ cYEXP ]	*= 2
//		elseif ( modifier == 0 )			// no modifier: expand X    ???todo check other possibilities/combinations
//			wMagn[ ch ][ cXSHIFT ]	=  xAxVal 
//			wMagn[ ch ][ cXEXP ]	*= 2
//		else
//			printf "\tEvalWndHook(): unknown modifier value %d \r", modifier
//		endif
//
//		wave	wMnMx		= root:uf:eval:evl:wMnMx
//		nvar		gbSameMagn	= root:uf:eval:evl:gbSameMagn 
//		if ( ch == 0 )
//			if ( gbSameMagn )
//				SetSameMagnification()	
//			endif	
//		endif	
//
//		RescaleAllChansBothAxis()
//	endif
//
//End


static Function		SetSameMagnification()
// set  X  magnification of ALL Cfs channels  to magnification of master channel  0 (0=ASSUMPTION)
	wave 	wMagn	= root:uf:eval:evl:wMagn
	variable	ch, nWnd
	nvar		gChans	= root:uf:cfsr:gChannels						// set magnification of ALL Cfs channels..
	for ( ch = 1; ch < gChans; ch += 1 ) 							//...even if they are currently turned off
		wMagn[ ch ][ cXSHIFT ]	=  wMagn[ 0 ][ cXSHIFT ]	
		wMagn[ ch ][ cXEXP ]	=  wMagn[ 0 ][ cXEXP ]
	endfor
End



static Function		RescaleAllChansBothAxis()
	variable	ch
	nvar		gbSameMagn	= root:uf:eval:evl:gbSameMagn 
	if ( gbSameMagn )
		SetSameMagnification()	
	endif	
	nvar		gChans	= root:uf:cfsr:gChannels
	for ( ch = 0; ch < gChans; ch += 1 )
		RescaleBothAxis( ch )
	endfor
End

static Function		RescaleBothAxis( ch )
	variable	ch
	RescaleXAxis( ch )
	RescaleYAxis( ch )
End

static Function		RescaleXAxis( ch )
	variable	ch
	string		sWNm	= CfsWndNm( ch ) 
	if ( WinType( sWNm ) == kGRAPH )
		wave	wMagn	= root:uf:eval:evl:wMagn
		wave	wMnMx	= root:uf:eval:evl:wMnMx
		// Clip  SHIFT value so that   XRight  never goes to the left of  XAxisLeft  when moving the trace to the left  and   XLeft  never goes to the right of  XAxisRight  when moving to the right
		wMagn[ ch ][ cXSHIFT ] 	= min( max( wMnMx[ ch ][ MM_XMIN ] - wMnMx[ ch ][ MM_XMAX ] / wMagn[ ch ][ cXEXP ] ,   wMagn[ ch ][ cXSHIFT ]  )  , wMnMx[ ch ][ MM_XMAX ] - wMnMx[ ch ][ MM_XMIN ] / wMagn[ ch ][ cXEXP ] ) 
		variable	xRight	= ( wMagn[ ch ][ cXSHIFT ] + ( wMnMx[ ch ][ MM_XMAX ] ) / wMagn[ ch ][ cXEXP ] ) 
		variable	xLeft		= ( wMagn[ ch ][ cXSHIFT ] + ( wMnMx[ ch ][ MM_XMIN  ] ) / wMagn[ ch ][ cXEXP ] ) 
		xLeft 	+= .02 *  ( xLeft - xRight )						// Deliberately make axis appr. 2% longer on each side so that the trace never disappears completely
	 	xRight	-=  .02 *  ( xLeft - xRight )						// ...
		 SetAxis	/Z /W = $sWNm  	bottom, 	xLeft, 	xRight
		//printf "\t\t\t\tRescaleXAxis( \t'%s'\tch:%d\t)	 \txshf:\t%7.3lf  \txexp:\t%7.3lf  \txMin:\t%7.3lf  \txMax:\t%7.3lf  \t->AxL:\t%7.3lf  \t... AxR:\t%7.3lf  \t \r", sWNm, ch, wMagn[ ch ][ cXSHIFT ], wMagn[ ch ][ cXEXP ],  wMnMx[ ch ][ MM_XMIN ],  wMnMx[ ch ][ MM_XMAX ],  xLeft , xRight
	endif
End

static Function		RescaleYAxis( ch )
	variable	ch
	string		sWNm	= CfsWndNm( ch ) 
	if ( WinType( sWNm ) == kGRAPH )
		wave	wMagn	= root:uf:eval:evl:wMagn
		wave	wMnMx	= root:uf:eval:evl:wMnMx
		// Clip  SHIFT value so that   Ymax never goes below  YAxisBottom when moving the trace down   and   YMin  never goes above  YAxisTop  when moving up
		wMagn[ ch ][ cYSHIFT ] 	= min( max( wMnMx[ ch ][ MM_YMIN ] - wMnMx[ ch ][ MM_YMAX ] / wMagn[ ch ][ cYEXP ] ,   wMagn[ ch ][ cYSHIFT ]  )  , wMnMx[ ch ][ MM_YMAX ] - wMnMx[ ch ][ MM_YMIN ] / wMagn[ ch ][ cYEXP ] ) 
		variable	yBottom	= ( wMagn[ ch ][ cYSHIFT ] + ( wMnMx[ ch ][ MM_YMIN  ] ) / wMagn[ ch ][ cYEXP ] ) 
		variable	yTop		= ( wMagn[ ch ][ cYSHIFT ] + ( wMnMx[ ch ][ MM_YMAX ] ) / wMagn[ ch ][ cYEXP ] ) 
		yTop 	+= .02 *  ( yTop - yBottom )						// Deliberately make axis appr. 2% longer on each side so that the trace never disappears completely
	 	yBottom	-=  .02 *  ( yTop - yBottom )						// ...
		SetAxis	/Z /W = $sWNm  	left,   	yBottom,	yTop 
		//printf "\t\t\t\tRescaleYAxis( \t'%s'\tch:%d\t)	 \tyShf:\t%7.3lf  \tyExp:\t%7.3lf  \tyMin:\t%7.3lf  \tyMax:\t%7.3lf  \t->AxB:\t%7.3lf  \t... AxT:\t%7.3lf  \t \r", sWNm, ch, wMagn[ ch ][ cYSHIFT ], wMagn[ ch ][ cYEXP ],  wMnMx[ ch ][ MM_YMIN ] ,  wMnMx[ ch ][ MM_YMAX ] , yBottom, yTop
	endif
End

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function	PossiblySaveCsrAndQuitCsrMode()
// Finish positioning ONE cursor by shrinking the crosshair to normal cursor. Store the last cursor position in its corresponding region.
	nvar		gbInCursorMode	= root:uf:eval:evl:gbInCursorMode
	if ( gbInCursorMode )											// was in mode in which Igor moves Base/Peak/Latency cursors
		gbInCursorMode			= FALSE						// end the mode in which Igor moves Base/Peak/Latency cursors
		wave	wPrevRegion	= root:uf:eval:evl:wPrevRegion
		variable	ch			= wPrevRegion[ cCH ]				// has previously been stored during 'FindAndMove..'
		variable	rg			= wPrevRegion[ cRG ]				// ...
		variable	ph			= wPrevRegion[ cPH ]				// ...
		variable	nCsr			= wPrevRegion[ cCURSOR ]			// ...
		string  	sCursorAorB	= SelectString( nCsr, "A", "B" )			// 0 is cursor A, 1 is cursor B 
		string		sWndNm 		= CfsWndNm( ch )
		if ( WinType( sWndNm ) == kGRAPH )							// the user may have killed the graph with the unfinished crosshair cursor
			wave	wCRegion	= root:uf:eval:evl:wCRegion
			wCRegion[ ch ][ rg ][ ph ][ CN_BEG   + nCsr ]	= hcsr( $sCursorAorB, sWndNm )		
			wCRegion[ ch ][ rg ][ ph ][ CN_BEGY+ nCsr ]	= vcsr( $sCursorAorB, sWndNm )	

			Cursor 	/W=$sWndNm /K  $sCursorAorB				// Remove the crosshair cursor from the graph

			DisplayCursor( ch, rg, ph, CN_BEG + nCsr, sWndNm )			// TODO obsolete=????? cosmetics: display new region or cursor  immediately
			 printf "\tPossiblySaveCursorQuitCursorMode()  retrieves  \tch:%d   \trg:%d   \tph:%d  %s  \tCursor %s \r", ch, rg, ph, pd (StringFromList( ph, ksPHASES ), 9), sCursorAorB
		else
			print "\tPossiblySaveCursorQuitCursorMode() failed as graph'" + sWndNm + "' could not be found. \r"	
		endif
	endif
End


static Function	FindAndMoveClosestCursor( ph, nCsr )
	variable	ph, nCsr
	// printf "\tFindAndMoveClosestCursor( \tph:%d (\t%s\t) , nCsr:%2d )  \r", ph, pd( StringFromList( ph, ksPHASES ), 6 ), nCsr
	wave	wCurRegion	= root:uf:eval:evl:wCurRegion
	variable	ch			= wCurRegion[ cCH ]				
	variable	rg 			= FindClosestRegion( ch, ph, nCsr )
	MoveCursor( ch, rg, ph, nCsr )
End

static Function	MoveCursor( ch, rg, ph, nCsr )
	variable	 ch, rg, ph, nCsr

	wave	wCRegion	= root:uf:eval:evl:wCRegion
	variable	xPhCsr	= wCRegion[ ch ][ rg ][ ph ][ CN_BEG   + nCsr ]
	string  	sWndNm	= CfsWndNm( ch )

	DisplayCursor( ch, rg, ph, CN_BEG + nCsr, sWndNm ) 		// TODO obsolete=????? cosmetics: clear old region or cursor immediately
	string		sWvNm		= "wOrg" + num2str(  ch )
	variable	rRed, rGreen, rBlue
	EvalRegionColor( ch, rg, ph, rRed, rGreen, rBlue )

	wave	wPrevRegion	= root:uf:eval:evl:wPrevRegion
	wPrevRegion[ cCH ]		= ch						// save until 'PossiblySaveCsrAndQuitCsrMode()'
	wPrevRegion[ cRG ]		= rg						// ...
	wPrevRegion[ cPH ]		= ph						// ...
	wPrevRegion[ cCURSOR ]	= nCsr 					// ...
	nvar	gbInCursorMode	= root:uf:eval:evl:gbInCursorMode
	gbInCursorMode		= TRUE					// the arrow keys must now move Igor's cursors and must no longer navigate through the data file

	// Cursor /F /W=$CfsWndNm( ch ) /A=1 /H=1 /S=1 /L=0  /C=(rRed, rGreen, rBlue)  A, $sWvNm, xPhCsr, yPhCsr	// draw the 'Free' crosshair cursor
	// Cursor	  /W=$CfsWndNm( ch ) /A=1 /H=1 /S=1 /L=0  /C=(rRed, rGreen, rBlue)  A, $sWvNm, xPhCsr		// 040823 draw the 'locked-to-wave' crosshair cursor
	string  	sCursorAorB	= SelectString( nCsr, "A", "B" )
	Cursor      /W=$sWndNm /A=1 /H=1 /S=1 /L=0  /C=(rRed, rGreen, rBlue)  $sCursorAorB, $sWvNm, xPhCsr	// 040823 draw the 'locked-to-wave' crosshair cursor

// 040827
//	ShowInfo	/W= $sWndNm  				// 040823 Display the small cursor control box. This is not mandatory for cursor usage.
	// Now we are in  Igors 'Cursor' mode.  Igor allows moving its cursor with the mouse or with the arrow keys
	// It is our responsability to quit the 'Cursor' mode,  e.g. by  pressing  the  AdjustAccept button, by pressing ESC  or by releasing (or clicking) the mouse  
End

static Function	FindClosestRegion( ch, ph, nCsr )
// If there is more than 1 region in the actice graph/channel then select the one which is closest to the cursor
	variable	ch, ph, nCsr
	wave	wCRegion		= root:uf:eval:evl:wCRegion
	wave	wCurRegion	= root:uf:eval:evl:wCurRegion
	wave	wChanOpts	= root:uf:eval:evl:wChanOpts
	variable	xAxVal		= wCurRegion[ cXMOUSE ]
	variable	xPhCsr
	variable	rg, ClosestRegion = 0, ClosestDistance = Inf
	variable	rgCnt		= wChanOpts[ ch ][ CH_RGCNT ]
	for ( rg = 0; rg < rgCnt; rg += 1 )
		xPhCsr	= wCRegion[ ch ][ rg ][ ph ][ CN_BEG   + nCsr ]
		if ( abs( xPhCsr - xAxVal ) < ClosestDistance )
			ClosestDistance = abs( xPhCsr - xAxVal )
			ClosestRegion	= rg
			//printf "\t\t\t\tFindClosestRegion( ch:%d , ph:%d \t( %s )\t, nCsr:%d \t( %s )\t ) \tXCsr:\t%7.3lf \tXReg:\t%7.3lf \tXDelta:\t%7.3lf\t \r", ch, ph, StringFromList( ph, ksPHASES), nCsr, StringFromList( nCsr, ksLR_CSR), xAxVal, xPhCsr, ClosestDistance 
		endif
	endfor
	//printf "\t\t\t\tFinfGetClosestRegion( ch:%d , ph:%d \t( %s )\t, nCsr:%d \t( %s )\t ) returns closest region %d. (rgCnt:%d) \r", ch, ph, StringFromList( ph, ksPHASES), nCsr, StringFromList( nCsr, ksLR_CSR), ClosestRegion, rgCnt	
	return	ClosestRegion
End
	
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  StimFit Clones   :	Functions to simulate StimFit as much as possible : Same keys and same actions

Function		buDispCfsESC( ctrlName ) : ButtonControl
	string		ctrlName
	PossiblySaveCsrAndQuitCsrMode()							// end the mode in which Igor moves Base/Peak/Latency cursors
	SameDataAgain()
End

Function		buDispCfsBaseLSetCsr( ctrlName ) : ButtonControl
	string		ctrlName
	PossiblySaveCsrAndQuitCsrMode()							// End the mode in which Igor moves Base/Peak/Latency cursors
	SameDataAgain()
	FindAndMoveClosestCursor( PH_BASE, kLEFT_CSR )				// Highlight  the Base begin cursor and allow moving it
End

Function		buDispCfsBaseRSetCsr( ctrlName ) : ButtonControl
// Highlight one of the Base  cursors and allow moving it
	string		ctrlName
	PossiblySaveCsrAndQuitCsrMode()							// end the mode in which Igor moves Base/Peak/Latency cursors
	SameDataAgain()
	FindAndMoveClosestCursor( PH_BASE, kRIGHT_CSR )			// Highlight  the Base  end  cursor and allow moving it
End


Function		buDispCfsPeakBegSetCsr( ctrlName ) : ButtonControl
	string		ctrlName
	PossiblySaveCsrAndQuitCsrMode()							// End the mode in which Igor moves Base/Peak/Latency cursors
	SameDataAgain()
	FindAndMoveClosestCursor( PH_PEAK, kLEFT_CSR )				// Highlight  the Peak  begin cursor and allow moving it
End

Function		buDispCfsPeakEndSetCsr( ctrlName ) : ButtonControl
	string		ctrlName
	PossiblySaveCsrAndQuitCsrMode()							// End the mode in which Igor moves Base/Peak/Latency cursors
	SameDataAgain()
	FindAndMoveClosestCursor( PH_PEAK, kRIGHT_CSR)			// Highlight  the Peak  end  cursor and allow moving it
End


Function		buDispCfsFit0BegSetCsr( ctrlName ) : ButtonControl
	string		ctrlName
	PossiblySaveCsrAndQuitCsrMode()							// End the mode in which Igor moves Base/Peak/Latency cursors
	SameDataAgain()
	FindAndMoveClosestCursor( PH_FIT0, kLEFT_CSR )				// Highlight  the  FIT0   begin cursor and allow moving it
End

Function		buDispCfsFit0EndSetCsr( ctrlName ) : ButtonControl
	string		ctrlName
	PossiblySaveCsrAndQuitCsrMode()							// End the mode in which Igor moves Base/Peak/Latency cursors
	SameDataAgain()
	FindAndMoveClosestCursor( PH_FIT0, kRIGHT_CSR)				// Highlight  the  Fit0  end  cursor and allow moving it
End


Function		buDispCfsFit1BegSetCsr( ctrlName ) : ButtonControl
	string		ctrlName
	PossiblySaveCsrAndQuitCsrMode()							// End the mode in which Igor moves Base/Peak/Latency cursors
	SameDataAgain()
	FindAndMoveClosestCursor( PH_FIT1, kLEFT_CSR )				// Highlight  the  FIT1   begin cursor and allow moving it
End

Function		buDispCfsFit1EndSetCsr( ctrlName ) : ButtonControl
	string		ctrlName
	PossiblySaveCsrAndQuitCsrMode()							// End the mode in which Igor moves Base/Peak/Latency cursors
	SameDataAgain()
	FindAndMoveClosestCursor( PH_FIT1, kRIGHT_CSR)				// Highlight  the  Fit1  end  cursor and allow moving it
End


Function		buDispCfsFit2BegSetCsr( ctrlName ) : ButtonControl
	string		ctrlName
	PossiblySaveCsrAndQuitCsrMode()							// End the mode in which Igor moves Base/Peak/Latency cursors
	SameDataAgain()
	FindAndMoveClosestCursor( PH_FIT2, kLEFT_CSR )				// Highlight  the  FIT2   begin cursor and allow moving it
End

Function		buDispCfsFit2EndSetCsr( ctrlName ) : ButtonControl
	string		ctrlName
	PossiblySaveCsrAndQuitCsrMode()							// End the mode in which Igor moves Base/Peak/Latency cursors
	SameDataAgain()
	FindAndMoveClosestCursor( PH_FIT2, kRIGHT_CSR)				// Highlight  the  Fit2  end  cursor and allow moving it
End


Function		buDispCfsResults( ctrlName ) : ButtonControl
// Results
	string		ctrlName
	nvar		gbResTextbox	= root:uf:eval:evl:gbResTextbox			// display or hide the evaluation results in the textbox in the graph window
	gbResTextbox	=!	gbResTextbox							// toggle the state
	PrintEvalTextboxAllChans()					// displays or hides the evaluation results in the graph window
	// the checkbox is automatically modified	(can be simplified, either button with changing title or checkbox) 
End

Function		buDispCfsInfo( ctrlName ) : ButtonControl
// Print Info textbox displaying evaluation borders in the Evaluation window. The button toggles the switch state showing or hiding the box.  
	string		ctrlName
	print ctrlname, "UNUSED***************************************"
End


static Function	/S	PrintEvalTBCursorInfo( ch, rg )
// Print Info textbox displaying evaluation borders in the Evaluation window. 
//  The  'LastPoint'  is referred to 1 sweep, not to trace displayed on screen (can be frame, block, ...) 
	variable	ch, rg
	wave	wChanOpts	= root:uf:eval:evl:wChanOpts
	wave	wCRegion		= root:uf:eval:evl:wCRegion
	nvar		gFitCnt		= root:uf:eval:evl:gfitCnt					
	nvar		gPkSidePts	= root:uf:eval:evl:gpkSidePts 
	variable	rgCnt , ph = -1, phCnt
	string  	sText	= ""
	rgCnt		= wChanOpts[ ch ][ CH_RGCNT ]
	string  	sRgTxt	= SelectString( rgCnt == 1 , "rg:" + num2str( rg ) , "    " )		// if there is only 1 region we do not print it's number to keep the textbox simple
	for ( ph = 0; ph < PH_FIT0 + gFitCnt;  ph += 1 )
		variable	nFitFunc	= wCRegion[ ch ][ rg ][ ph ][ CN_FITFNC ]
		if ( nFitFunc != FT_NONE ) 
			string  	sValNm	= StringFromList( ph, ksPHASES )
			sText  += EvalInfoLineBegEnd( sRgTxt, ch, rg, ph, sValNm )	+ "\r"
		endif
	endfor				
	variable	bPeak_Is_Up 	= wCRegion[ ch ][ rg ][ PH_PEAK ][ CN_ISUP ]

//	sText  += EvalInfoLineS( sRgTxt, "Direction:" , StringFromList( 	wCRegion[ ch ][ rg ][ PH_PEAK ][ CN_ISUP ] , ksPEAKDIR  ) )	+ "\r"
//	sText  += EvalInfoLine1Val( sRgTxt, "Peak SidePts:" ,	 gPkSidePts )	+ "\r"

	sText  += EvalInfoLineS( sRgTxt, "Direction:" , StringFromList( 	wCRegion[ ch ][ rg ][ PH_PEAK ][ CN_ISUP ] , ksPEAKDIR  ) )	//+ "\r"
	sText  += EvalInfoLine1Val( "      ", "Peak SidePts:" ,	 gPkSidePts )	+ "\r"

	return	sText
End

Function	/S	EvalInfoLine1Val( sRgTxt, sValNm, Val )
	variable	Val
	string  	sRgTxt, sValNm 
	string  	sLine
	variable	nFieldLen		= 8
	sprintf  sLine, "%s  %s  %7.3lf\t ", sRgTxt, sValNm, Val
	return	sLine
End

Function	/S	EvalInfoLineS( sRgTxt, sValNm, sValue )
	string  	sRgTxt, sValNm, sValue 
	string  	sLine
	variable	nFieldLen		= 12
	sprintf  sLine, "%s  %s  %s ", sRgTxt, sValNm, sValue
	return	sLine
End

Function	/S	EvalInfoLineBegEnd( sRgTxt, ch, rg, ph, sValNm )
	variable	ch, rg, ph
	string  	sRgTxt, sValNm 
	nvar		gCfsSmpInt	= root:uf:cfsr:gCfsSmpInt
	string  	sLine
	variable	nFieldLen		= 12						// 9 saves 1 tab but truncates the last letter of  'LatencyCsr'
	variable	nBeg, nEnd, Beg_s, End_s
	wave	wCRegion	= root:uf:eval:evl:wCRegion
	RegionX( ch, rg, ph, Beg_s, End_s )
	nBeg		= round( Beg_s * cXSCALE / gCfsSmpInt )
	nEnd		= round( End_s * cXSCALE /  gCfsSmpInt )
	variable	CsrCnt	= wCRegion[ ch ][ rg ][ ph ][ CN_CSRCNT ] 
	if ( CsrCnt == 1 )					// e.g. LatencyCsr
		sprintf  sLine, "%s  %-12s  %6d (%7.3lf ) ", sRgTxt, sValNm, nBeg, Beg_s
	else							// e.g. Base, Peak, Fit
		sprintf  sLine, "%s  %-12s  %6d (%7.3lf ) ..%6d (%7.3lf )\t ", sRgTxt, sValNm, nBeg, Beg_s, nEnd, End_s
	endif
	return	sLine
End

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function		buDispCfsPlus( ctrlName ) : ButtonControl
// Plus  peak points
	string		ctrlName
	//print ctrlname
	nvar		gPkSidePts	= root:uf:eval:evl:gpkSidePts				// additional points on each side of a peak averaged to reduce noise errors 
	gPkSidePts	+= 1
	SameDataAgain()
End

Function		buDispCfsMinus( ctrlName ) : ButtonControl
// Minus  peak points
	string		ctrlName
	print ctrlname
	nvar		gPkSidePts	= root:uf:eval:evl:gpkSidePts				// additional points on each side of a peak averaged to reduce noise errors 
	gPkSidePts	= max( 0, 	gPkSidePts - 1 )
	SameDataAgain()
End

Function		buDispCfsMove( ctrlName ) : ButtonControl
// Move a number of sweeps in File
	string		ctrlName
	print ctrlname
	PossiblySaveCsrAndQuitCsrMode()							// end the mode in which Igor moves Base/Peak/Latency cursors
End

Function		buDispCfsXExpand( ctrlName ) : ButtonControl
	string		ctrlName
	wave	wCurRegion	= root:uf:eval:evl:wCurRegion
	wave	wMagn		= root:uf:eval:evl:wMagn
	variable	ch			=   wCurRegion[ cCH ] 
	variable	factor		= ( wCurRegion[ cMODIF ] == SHIFT )  ?   1.26  :  2	// appr.  3. root of 2  like Stimfit   or  2  
	variable	xAxVal		=   wCurRegion[ cXMOUSE ] 
	wMagn[ ch ][ cXEXP ]	*= factor	
	wMagn[ ch ][ cXSHIFT ]	=  xAxVal
	RescaleXAxis( ch )												//...possibly  clip  here the cXSHIFT value
	RescaleEvaluatedDataPoints( ch )
	RescaleCursors( ch )
End

Function		buDispCfsXShrink( ctrlName ) : ButtonControl
	string		ctrlName
	wave	wCurRegion	= root:uf:eval:evl:wCurRegion
	wave	wMagn		= root:uf:eval:evl:wMagn
	variable	ch			=   wCurRegion[ cCH ] 
	wMagn[ ch ][ cXEXP ]       /=  ( wCurRegion[ cMODIF ] == SHIFT )  ?   1.26  :  2	// appr.  3. root of 2  like Stimfit   or  2  
	wMagn[ ch ][ cXSHIFT ]	=    wCurRegion[ cXMOUSE ] 
	RescaleXAxis( ch )												//...possibly  clip  here the cXSHIFT value
	RescaleEvaluatedDataPoints( ch )
End

Function		buDispCfsXLeft( ctrlName ) : ButtonControl
	string		ctrlName
	wave	wCurRegion	= root:uf:eval:evl:wCurRegion
	wave	wMagn		= root:uf:eval:evl:wMagn
	wave	wMnMx		= root:uf:eval:evl:wMnMx
	variable	ch			=  wCurRegion[ cCH ] 
	variable	factor		= ( wCurRegion[ cMODIF ] == SHIFT ) ?  .25  :  .05  	//  depending on Shift key try to move trace  5%  or  25%  of  axis...	
	wMagn[ ch ][ cXSHIFT]    +=  factor * ( wMnMx[ ch ][ MM_XMAX ] - wMnMx[ ch ][ MM_XMIN ] ) / wMagn[ ch ][ cXEXP ]//  try to move trace to the left  5%  or  25% of  bottom axis...	
	RescaleXAxis( ch )												//...possibly  clip  here the cXSHIFT value
End

Function		buDispCfsXRight( ctrlName ) : ButtonControl
	string		ctrlName
	wave	wCurRegion	= root:uf:eval:evl:wCurRegion
	wave	wMagn		= root:uf:eval:evl:wMagn
	wave	wMnMx		= root:uf:eval:evl:wMnMx
	variable	ch			=  wCurRegion[ cCH ] 
	variable	factor		= ( wCurRegion[ cMODIF ] == SHIFT ) ?  .25  :  .05  	//  depending on Shift key try to move trace  5%  or  25%  of  axis...	
	wMagn[ ch ][ cXSHIFT]    -=  factor * ( wMnMx[ ch ][ MM_XMAX ] - wMnMx[ ch ][ MM_XMIN ] ) / wMagn[ ch ][ cXEXP ]	//  try to move trace to the right  5%  or  25% of  bottom axis... 
	RescaleXAxis( ch )												//...possibly  clip  here the cXSHIFT value
End


Function		buDispCfsYExpand( ctrlName ) : ButtonControl
	string		ctrlName
	wave	wCurRegion	= root:uf:eval:evl:wCurRegion
	wave	wMagn		= root:uf:eval:evl:wMagn
	variable	ch			=   wCurRegion[ cCH ] 
	variable	factor		= ( wCurRegion[ cMODIF ] == SHIFT )  ?   1.26  :  2	// appr.  3. root of 2  like Stimfit   or  2  
	variable	yAxVal		=   wCurRegion[ cYMOUSE ] 
	wMagn[ ch ][ cYEXP ]	*= factor	
	wMagn[ ch ][ cYSHIFT ]	=  yAxVal
	RescaleYAxis( ch )												//...possibly  clip  here the cXSHIFT value
	RescaleEvaluatedDataPoints( ch )
	RescaleCursors( ch )
End

Function		buDispCfsYShrink( ctrlName ) : ButtonControl
	string		ctrlName
	wave	wCurRegion	= root:uf:eval:evl:wCurRegion
	wave	wMagn		= root:uf:eval:evl:wMagn
	variable	ch			=   wCurRegion[ cCH ] 
	variable	factor		= ( wCurRegion[ cMODIF ] == SHIFT )  ?   1.26  :  2	// appr.  3. root of 2  like Stimfit   or  2  
	variable	yAxVal		=   wCurRegion[ cYMOUSE ] 
	wMagn[ ch ][ cYEXP ]       /=  factor
	wMagn[ ch ][ cYSHIFT ]	=    yAxVal
	RescaleYAxis( ch )												//...possibly  clip  here the cYSHIFT value
	RescaleEvaluatedDataPoints( ch )
	RescaleCursors( ch )
End

Function		buDispCfsYUp( ctrlName ) : ButtonControl
	string		ctrlName
	wave	wCurRegion	= root:uf:eval:evl:wCurRegion
	wave	wMagn		= root:uf:eval:evl:wMagn
	wave	wMnMx		= root:uf:eval:evl:wMnMx
	variable	ch			=  wCurRegion[ cCH ] 
	variable	factor		= ( wCurRegion[ cMODIF ] == SHIFT ) ?  .25  :  .05  	//  depending on Shift key try to move trace  5%  or  25%  of  axis...	
	wMagn[ ch ][ cYSHIFT]   -=  factor * ( wMnMx[ ch ][ MM_YMAX ] - wMnMx[ ch ][ MM_YMIN ] ) / wMagn[ ch ][ cYEXP ]	//  try to move trace up  5%  or  25%  of  left axis...	
	RescaleYAxis( ch )												//...possibly  clip  here the cYSHIFT value
	RescaleCursors( ch )
End

Function		buDispCfsYDown( ctrlName ) : ButtonControl
	string		ctrlName
	wave	wCurRegion	= root:uf:eval:evl:wCurRegion
	wave	wMagn		= root:uf:eval:evl:wMagn
	wave	wMnMx		= root:uf:eval:evl:wMnMx
	variable	ch			=  wCurRegion[ cCH ] 
	variable	factor		= ( wCurRegion[ cMODIF ] == SHIFT ) ?  .25  :  .05  	//  depending on Shift key try to move trace  5%  or  25%  of  axis...	
	wMagn[ ch ][ cYSHIFT]   +=  factor * ( wMnMx[ ch ][ MM_YMAX ] - wMnMx[ ch ][ MM_YMIN ] ) / wMagn[ ch ][ cYEXP ]	//  try to move trace down  5%  or  25% of  left axis... 
	RescaleYAxis( ch )												//...possibly  clip  here the cXSHIFT value
	RescaleCursors( ch )
End


Function		buDispCfsRescale( ctrlName ) : ButtonControl
// Rescale
	string		ctrlName
	print ctrlname
	wave	wMagn	= root:uf:eval:evl:wMagn
	variable	ch
	nvar		gChans	= root:uf:cfsr:gChannels					// check ALL Cfs channels..
	for ( ch = 0; ch < gChans; ch += 1 )
		wMagn[ ch ][ cXSHIFT ]	= 0
		wMagn[ ch ][ cXEXP ]	= 1
		wMagn[ ch ][ cYSHIFT]	= 0
		wMagn[ ch ][ cYEXP ]	= 1
		RescaleBothAxis( ch )
		RescaleCursors( ch )
	endfor
End

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  THE  EVALUATION  DETAILS - ANALYSIS  PANEL

Function		EvalDetailsDlg()	
	string  	sFolder		= ksEVAL
	string  	sPnOptions	= ":dlg:tPnEvalDetails" 

// 050217
//	InitPanelEvalDetails( sFolder, sPnOptions )
	InitPanelEvalDetailsNew( sFolder, sPnOptions )

	ConstructOrDisplayPanel(  "PnEvalDetails", "Evaluation Details" , sFolder, sPnOptions,  100, 50 )	// same params as in  UpdatePanel()

	// Make sure that the initial  'gpPrintResults' value is not only shown in the popup but also effective : Convert to print mask.
	// Later (with every change of the popup value)  this is done automatically   by the popup action procedure, but for the initalisation extra code is required. 
	ControlInfo	 /W=	$"PnEvalDetails"    root_uf_eval_evl_gpPrintResults				// Get initial popup index
	//printf "\t\t\tControlInfo	 /W=PnEvalDetails    root_uf_eval_evl_gpPrintResults  V_Flag: %d (popup=3)     V_Value: %d  (starting at 1) \r", V_Flag, V_Value
	variable	tmp = V_value
	nvar		gPrintMask	= root:uf:eval:evl:gprintMask
	gPrintMask			= str2num( StringFromList( tmp - 1, ksPRINTMASKS ) )	// Convert initial popup index into PrintMask bit field

	nvar		gbDoEvaluation	= root:uf:eval:evl:gbDoEvaluation					// We turn the Evaluation automatically on...
	gbDoEvaluation			= TRUE									// ...as this is probably what the user wants when he opens the EvalDetails panel
	DoEvaluation( gbDoEvaluation )
//	AutoSetCursors()
End

Function		KillEvalDetailsDlg()	
	DoWindow /K $"PnEvalDetails"
End

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	COMMON  PN_MULTI   FUNCTIONS  NEW

Function		InitPanelEvalDetailsNew( sFolder, sPnOptions )
	string  	sFolder, sPnOptions
	string		sPanelWvNm = "root:uf:" + sFolder + sPnOptions
	variable	n = -1, nItems = 80
//	nvar		gChannels	= root:uf:cfsr:gChannels				
//	nvar		gChans	= root:uf:cfsr:gChannels					// The number channels in eval: must be updated both in  'InitPanelEvalDetails()' and  'Analyse()'...
//	gChans			= gChannels						//...as either may be called first. (Or replace all occurrences of  'cfsr:gChannels'  by  'cfsr:gChannels' )

	make /O /T /N=(nItems)	$sPanelWvNm
	wave  /T	tPn	=	$sPanelWvNm
//	n =	PnLine1New( tPn, n )
//	n =	PnSeparator( tPn, n, " " )

	n = 	PnMultiLineEvalDetailsNew( tPn, n )

	n =	PnSeparator( tPn, n, " " )
	n += 1;	tPn[ n ] = " PN_POPUP;		root:uf:eval:evl:gpStartValsOrFit	;; 	80	;		;gpStartValsOrFit_Lst;	gpStartValsOrFit;  | | | "			// Sample: No default value (Par4) supplied, set only at program start. 
	
//	n =	PnLine2( tPn, n )
//	n =	PnSeparator( tPn, n, " " )
	n =	PnLine3New( tPn, n )
	n =	PnSeparator( tPn, n, " " )
	n =	PnLine4New( tPn, n )				// Same time? , Multiple keeps? , Show average? ...
	n =	PnSeparator( tPn, n, " " )
	n += 1;	tPn[ n ] =	"PN_BUTTON;	buAutoSetCursors;Auto Set Cursors; | PN_BUTTON;	buTest00	;TraceCfs() Pts; | PN_BUTTON;	buTest01	;Test01; | "
	redimension  /N = (n+1)	tPn
End

//static Function		PnLine1New( tPanel, n )
//	wave   /T	tPanel
//	variable	n
//	string		sLine		= ""
////	sLine		+=	"  PN_CHKBOX;	root:uf:eval:evl:gbDoEvaluation	;Evaluation;	"
////	sLine		+=	"| PN_SETVAR;		root:uf:eval:evl:gfitCnt	 		;         Fits; 		22	;  %2d ;0," + num2str( ItemsInList( ksPHASES ) - PH_FIT0 ) + ",1; "	// adjust the maximum value 	  
////	sLine		+=	"| PN_POPUP;		root:uf:eval:evl:gpStartValsOrFit	;; 	80	;		;gpStartValsOrFit_Lst;	gpStartValsOrFit"			// Sample: No default value (Par4) supplied, set only at program start. 
//	sLine		+=	"| "
//	sLine		+=	" PN_POPUP;		root:uf:eval:evl:gpStartValsOrFit	;; 	80	;		;gpStartValsOrFit_Lst;	gpStartValsOrFit"			// Sample: No default value (Par4) supplied, set only at program start. 
//	sLine		+=	"| "
//	sLine		+=	"| "
//	tPanel[ n + 1 ] = sLine
//	return	n + 1
//End

static Function		PnLine3New( tPanel, n )
	wave   /T	tPanel
	variable	n
	string		sLine		= ""
	sLine		+=	"  PN_POPUP;		root:uf:eval:evl:gpLatencyCsr		;; 	80	;	2	;gpLatencyCsr_Lst; "				// Sample: Default value (Par4) supplied, reset on panel rebuild.
	sLine		+=	"| PN_SETVAR;		root:uf:eval:evl:gpkSidePts 		; Peakpts; 		22	;  %2d ;0,20,1; "	  
	sLine		+=	"| PN_POPUP;		root:uf:eval:evl:gpPrintResults		;; 	80	;		;gpPrintResults_Lst;	gpPrintResults"	// Sample: No default value (Par4) supplied, set only at program start. PrintResults needs an explicit action procedure 
	sLine		+=	"| "
	tPanel[ n + 1 ] = sLine
	return	n + 1
End

static Function		PnLine4New( tPanel, n )
	wave   /T	tPanel
	variable	n
	string		sLine		= ""
	sLine		+=	"  PN_CHKBOX;	root:uf:eval:evl:gbSameMagn	;Same time; 	"
	sLine		+=	"| PN_CHKBOX;	root:uf:eval:evl:gbMultipleKeeps	;Multiple keeps; "	
	sLine		+=	"| PN_CHKBOX;	root:uf:eval:evl:gbShowAverage	;Show average;	"	
	sLine		+=	"| PN_POPUP;		root:uf:eval:evl:gpDispTracesOrAvg	;; 	80	;		;gpDispTracesOrAvg_Lst;	gpDispTracesOrAvg"	// Sample: No default value (Par4) supplied, set only at program start. 
	sLine		+=	"| PN_CHKBOX;	root:uf:eval:evl:gbResTextbox	;Results;	"	
	tPanel[ n + 1 ] = sLine
	return	n + 1
End


Function		PnMultiLineEvalDetailsNew( tPanel, n )
	wave   /T	tPanel
	variable	n
	wave	wChRg	= root:uf:eval:evl:wChRg
	wave	wChRgFit	= root:uf:eval:evl:wChRgFit
	wave	wChanOpts= root:uf:eval:evl:wChanOpts
	wave	wCRegion	= root:uf:eval:evl:wCRegion
	nvar		gChans	= root:uf:cfsr:gChannels
	// printf "\t\t\tPnMultiLineEvalDetailsNew()  root:uf:cfsr:gChannels:%d \r", gChans
	variable	i = 0, ch, rg, rgCnt , ph, phCnt
	for ( ch = 0; ch < gChans;  ch += 1 )	
		tPanel[ n + i + 1 ] =	"PN_SEPAR "
		i += 1


		rgCnt	  = wChanOpts[ ch ][ CH_RGCNT ]
		tPanel[ n + i  +1 ] =	ChanPnLineNew( ch )
		i += 1
		if ( wChanOpts[ ch ][ CH_ONOFF ] == TRUE )							// display the region lines in the panel only if the channel checkbox is on 
			for ( rg = 0; rg < RG_MAX;  rg += 1 )

				variable	nState	= wChRg[ ch ][ rg ] 

				if ( nState  == kAC_ON  ||  nState == kAC_ON_LOCKED  )	

					tPanel[ n + i  +1 ] =	RegionPnLineNew( ch, rg, nState )	+ "|" +  RegionAndPhasesPnLineNew( ch, rg )
					i += 1

					for ( ph = 0; ph < FIT_MAX; ph += 1 )
						if	( wChRgFit[ ch ][ rg ][ ph ][ kFI_ON ] == kAC_ON  )				// 
							tPanel[ n + i + 1 ] =	FitPnLineNew( ch, rg, ph )
							i += 1
						elseif ( wChRgFit[ ch ][ rg ][ ph ][ kFI_ON ] == kAC_ON_LOCKED  )	
							tPanel[ n + i + 1 ] =	FitGreyPnLineNew( ch, rg, ph )
							i += 1
						elseif ( wChRgFit[ ch ][ rg ][ ph ][ kFI_ON ] == kAC_UNCHECKED  )	
							tPanel[ n + i + 1 ] =	FitCBOnlyPnLineNew( ch, rg, ph )
							i += 1
						endif
					endfor

				elseif ( nState == kAC_UNCHECKED  )	
				//	tPanel[ n + i  +1 ] =	RegionPnLineNew( ch, rg, nState )		// display only Region checkbox to later allow turning the region on again
					tPanel[ n + i  +1 ] =	RegionOnlyPnLineNew( ch, rg )		// display only Region checkbox to later allow turning the region on again
					i += 1
				endif						// there is also nState = kAC_HIDE but this state needs no processing


			endfor												
		endif



	endfor												
	return	n + i  
End


static Function  /S	ChanPnLineNew( ch )
	variable	ch
	string  	sChanNm	=  CfsIONm( ch ) 
	string		sLine		= ""
	sLine		+=	"  PN_WVCHKBOX; 	root:uf:eval:evl:wChanOpts ;" + sChanNm + ";  0	;" + IndexToStr2( ch, CH_ONOFF ) 	+	"; 			;  fCbChanOnOff"
	sLine		+=	" | PN_WVPOPUP;	root:uf:eval:evl:wChanOpts;Min;			60	;" + IndexToStr2( ch, CH_YAXISMIN )	+	"; fYAxis_Lst 	;  fYAxisMin"
	sLine		+=	" | PN_WVPOPUP;	root:uf:eval:evl:wChanOpts;Max;			60	;" + IndexToStr2( ch, CH_YAXISMAX )+	"; fYAxis_Lst 	; fYAxisMax"
	sLine		+=	" |  "
	return	sLine
End


static Function  /S	RegionPnLineNew( ch, rg, nState )
	variable	ch, rg, nState 
//gn	variable	nDisable	=  ( nState == kAC_ON  ||  nState == kAC_ON_LOCKED ||  nState == kAC_UNCHECKED )  ?   0   :   2		// kAC_HIDE  makes  nDisable = 2
//	variable	nDisable	=  ( nState == kAC_ON  ||  nState == kAC_ON_LOCKED )  ?   0   :   2		// kAC_UNCHECKED  makes  nDisable = 2
	variable	nDisable	=  ( nState == kAC_ON_LOCKED )  ?   2   :  0		// kAC_UNCHECKED  makes  nDisable = 2
	string		sLine		= ""
	sLine		+=	"  PN_WVCHKBOX; 	root:uf:eval:evl:wChRg;         Reg " + num2str( rg ) + ";" + num2str( nDisable ) + ";" + IndexToStr2( ch, rg ) 	+	"; 		;  fCbRegOnOff"
	return	sLine
End

static Function  /S	RegionOnlyPnLineNew( ch, rg )
	variable	ch, rg
	string		sLine		= ""
	sLine		+=	"  PN_WVCHKBOX; 	root:uf:eval:evl:wChRg;         Reg " + num2str( rg ) + "; 0;" + IndexToStr2( ch, rg ) 	+	"; 					;  fCbRegOnOff"
	return	sLine
End


static Function  /S	RegionAndPhasesPnLineNew( ch, rg )
	variable	ch, rg
	variable	ph
	string		sLine			= ""
	sLine		+=	"  PN_WVPOPUP	;root:uf:eval:evl:wCRegion	;;		80	;" + IndexToStr4( ch, rg, PH_PEAK, CN_ISUP )	+ 		"; fPkUpDn_Lst ; fPkUpDn"
	sLine		+=	"| PN_WVCHKBOX; 	root:uf:eval:evl:wCRegion	 ;Check ns;   0	;" + IndexToStr4( ch, rg, PH_PEAK, CN_CHK_NS ) +		"; 	; fCbCheckNs"
	sLine		+=	"| PN_WVCHKBOX; 	root:uf:eval:evl:wCRegion	 ;Auto/user;  0	;" + IndexToStr4( ch, rg, PH_PEAK, CN_LIM_A )     +		"; 	; fCbAutoUser"
	return	sLine
End


static Function  /S	FitPnLineNew( ch, rg, ph )
	variable	ch, rg, ph
	string		sLine		= " | "
  	// 050216 the 'length' field (also usable: 'limit' field) is used to store normal(=0) , hide(=1) and disable(=2) information
	sLine	   +=	"  PN_WVCHKBOX; 	root:uf:eval:evl:wChRgFit;     Fit " + num2str( ph ) + "; 0	;" + IndexToStr4( ch, rg, ph, kFI_ON ) 	+	"; 				; fCbFitOnOff"
	sLine	   +=	" | PN_WVPOPUP	;root:uf:eval:evl:wCRegion	;;		80	; " + IndexToStr4( ch, rg, ph+PH_FIT0, CN_FITFNC ) +	"; fFitFuncs_Lst	; fFitFuncs"
	sLine   +=	" | PN_WVPOPUP	;root:uf:eval:evl:wCRegion	;;		80	; " + IndexToStr4( ch, rg, ph+PH_FIT0, CN_FITRANGE) +	"; fFitRange_Lst; fFitRange"
	return	sLine
End

static Function  /S	FitGreyPnLineNew( ch, rg, ph )
	variable	ch, rg, ph
	string		sLine		= " | "
  	// 050216 the 'length' field (also usable: 'limit' field) is used to store normal(=0) , hide(=1) and disable(=2) information
	sLine	   +=	"  PN_WVCHKBOX; 	root:uf:eval:evl:wChRgFit;     Fit " + num2str( ph ) + "; 2	;" + IndexToStr4( ch, rg, ph, kFI_ON ) 	+	"; 				; fCbFitOnOff"
	sLine	   +=	" | PN_WVPOPUP	;root:uf:eval:evl:wCRegion	;;		80	; " + IndexToStr4( ch, rg, ph+PH_FIT0, CN_FITFNC ) +	"; fFitFuncs_Lst	; fFitFuncs"
	sLine   +=	" | PN_WVPOPUP	;root:uf:eval:evl:wCRegion	;;		80	; " + IndexToStr4( ch, rg, ph+PH_FIT0, CN_FITRANGE) +	"; fFitRange_Lst; fFitRange"
	return	sLine
End

static Function  /S	FitCBOnlyPnLineNew( ch, rg, ph )
	variable	ch, rg, ph
	string		sLine		= " | "
 	// 050216 the 'length' field (also usable: 'limit' field) is used to store normal(=0) , hide(=1) and disable(=2) information
	sLine	   +=	"  PN_WVCHKBOX; 	root:uf:eval:evl:wChRgFit;     Fit " + num2str( ph ) + "; 0	;" + IndexToStr4( ch, rg, ph, kFI_ON ) 	+	"; 				; fCbFitOnOff"
	sLine		+= " | "
	sLine		+= " | "
 	return	sLine
End

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Function		fCbRegOnOff( sControlNm, bValue )
	string		sControlNm
	variable	bValue
	variable	ch, rg
	StrToIndex2( sControlNm, ch, rg )									// 2 dims !!!  retrieves ch, typ
	// Convert auto-built global variable controlled by SETVAR / PN_WVCHKBOX  back into element of 2-dimensional wave
	string		sFolderCtrlBase	= sControlNm[ 0, strlen( sControlNm ) - 1 - 2 ]		// 2 dims !!! truncate channel and region e.g. root_uf_eval_evl_wChanOpts10 -> root_uf_eval_evl_wChanOpts
	string		sFolderWave	= ReplaceCharWithString( sFolderCtrlBase, "_" , ":" )	// e.g. root_uf_eval_evl_wChanOpts -> root:uf:eval:evl:wChanOpts	
	wave	wWave		= $sFolderWave							// ASSUMPTION: wave name MUST NOT contain underscores 
//	wWave[ ch ][ rg ]		= bValue 									// 2 dims !!!
	print "\tfCbRegOnOff( PN_WVCHKBOX )  \t  retrieves   ",  sControlNm, "\tchan:", ch, rg,  "   \t-> ", sFolderWave, wWave[ ch ][ rg ], "    \t = ", bValue

	//  wave	is   wChRg	= root:uf:eval:evl:wChRg
	if ( 	rg == 0  					&&  	bValue )
		wWave[ ch ][ rg	     ]	= kAC_ON 	
		wWave[ ch ][ rg + 1]	= kAC_UNCHECKED 	
	elseif ( rg > 0  && rg < RG_MAX - 1  	&&  	bValue )  
		wWave[ ch ][ rg - 1 ]	= kAC_ON_LOCKED 	
		wWave[ ch ][ rg      ]	= kAC_ON 	
		wWave[ ch ][ rg + 1]	= kAC_UNCHECKED 	
	elseif ( 		rg == RG_MAX - 1 	&&  	bValue )  
		wWave[ ch ][ rg - 1 ]	= kAC_ON_LOCKED 	
		wWave[ ch ][ rg      ]	= kAC_ON 	
	elseif ( 		rg == RG_MAX - 1 	&&  !	bValue )  
		wWave[ ch ][ rg - 1 ]	= kAC_ON	
		wWave[ ch ][ rg      ]	= kAC_UNCHECKED 	
	elseif ( rg > 0  && rg < RG_MAX - 1  	&&  !	bValue )  
		wWave[ ch ][ rg - 1 ]	= kAC_ON	
		wWave[ ch ][ rg      ]	= kAC_UNCHECKED 	
		wWave[ ch ][ rg + 1]	= kAC_HIDE 	
	elseif ( rg == 0  					&&  !	bValue )  
		wWave[ ch ][ rg      ]	= kAC_UNCHECKED 	
		wWave[ ch ][ rg + 1]	= kAC_HIDE 	
	endif
	
	UpdatePanelDetailsEval()
//	// First kill the window which has just been turned  off ( it does no harm if it is already closed )...
//	nvar		gChans	= root:uf:cfsr:gChannels									// check ALL Cfs channels..
//	string		sWndNm
//	sWndNm	= CfsWndNm( ch ) 
//	if ( bValue == FALSE )
//		DoWindow /K $sWndNm 
//	endif
//	//...then resize or build those which should be on
//	variable	w = 0, wCnt = gChans
//	for ( ch = 0; ch < gChans; ch += 1 ) 										// loop through ALL windows ven if they are currently off
//		sWndNm	= CfsWndNm( ch ) 
//		wave	wChanOpts	= root:uf:eval:evl:wChanOpts
//		if ( wChanOpts[ ch ][ CH_ONOFF ] == TRUE )
//			variable	Left, Top, Right, Bot
//			GetAutoWindowCorners( w, wCnt, 0, 1, Left, Top, Right, Bot, 0, 100 )
//			if ( WinType( sWndNm ) == kGRAPH )								// the window exists already
//				//...then resize those which exist and should be on
//				MoveWindow	 /W=$sWndNm  Left, Top, Right, Bot 
//			else
//				//...then build those which do not yet exist and should be on
//				display 	/K=1  /W=( Left, Top, Right, Bot ) //as  sWndTitle		// build an empty window
//				DoWindow  /C $sWndNm 									// rename the window
//			endif
//			DoWindow 	/F 	$sWndNm									// FRONT : display on top = completely visible
//			w += 1													// count the  'ON'  windows
//		endif
//	endfor
//	if ( bValue == TRUE )				// only if a window is added we have to do the analysis ( actually analysing the added channel would be sufficient )
//		SameDataAgain()
//	endif
//
//	// Depending on the state of  'Chan' control   enable / disable  related   regions 
//	KillEvalDetailsDlg()	
//	EvalDetailsDlg()	
End

// AutoControl constants : group of controls is totally off or not constructed , is totally on ,  only the checkbox is visible for switching the group on and off 
constant	kAC_UNCHECKED = 0,  kAC_ON = 1,  kAC_ON_LOCKED = 2,  kAC_HIDE = 3

Function		fCbFitOnOff( sControlNm, bValue )
	string		sControlNm
	variable	bValue
	variable	ch, rg, ph, type
	StrToIndex4( sControlNm, ch, rg, ph, type )									// 4 dims !!!  retrieves ch, typ
	// Convert auto-built global variable controlled by SETVAR / PN_WVCHKBOX  back into element of 2-dimensional wave
	string		sFolderCtrlBase		= sControlNm[ 0, strlen( sControlNm ) - 1 - 4 ]		// 4 dims !!! truncate channel and region e.g. root_uf_eval_evl_wChanOpts10 -> root_uf_eval_evl_wChanOpts
	string		sFolderWave		= ReplaceCharWithString( sFolderCtrlBase, "_" , ":" )	// e.g. root_uf_eval_evl_wChanOpts -> root:uf:eval:evl:wChanOpts	
	wave	wWave			= $sFolderWave							// ASSUMPTION: wave name MUST NOT contain underscores 
//	wWave[ ch ][ rg ][ ph ][ type ]	= bValue 									// 4 dims !!!
	print "\tfCbFitOnOff( PN_WVCHKBOX )  \t  retrieves   ",  sControlNm, "\tchan:", ch, rg, ph, type, "\t-> ", sFolderWave, wWave[ ch ][ rg ][ ph ][ type ], "\t = ", bValue

	//  wave	is   wChRgFit	= root:uf:eval:evl:wChRgFit
	if ( type == kFI_ON )
		if ( 	ph == 0  					&&  	bValue )
			wWave[ ch ][ rg ][ ph 	     ][ type ]	= kAC_ON 	
			wWave[ ch ][ rg ][ ph + 1][ type ]	= kAC_UNCHECKED 	
		elseif ( ph > 0  && ph < FIT_MAX - 1  	&&  	bValue )  
			wWave[ ch ][ rg ][ ph - 1 ][ type ]	= kAC_ON_LOCKED 	
			wWave[ ch ][ rg ][ ph      ][ type ]	= kAC_ON 	
			wWave[ ch ][ rg ][ ph+1 ]	= kAC_UNCHECKED 	
		elseif ( 		ph == FIT_MAX - 1 	&&  	bValue )  
			wWave[ ch ][ rg ][ ph - 1 ][ type ]	= kAC_ON_LOCKED 	
			wWave[ ch ][ rg ][ ph      ][ type ]	= kAC_ON 	
		elseif ( 		ph == FIT_MAX - 1 	&&  !	bValue )  
			wWave[ ch ][ rg ][ ph - 1 ][ type ]	= kAC_ON	
			wWave[ ch ][ rg ][ ph      ][ type ]	= kAC_UNCHECKED 	
		elseif ( ph > 0  && ph < FIT_MAX - 1  	&&  !	bValue )  
			wWave[ ch ][ rg ][ ph - 1 ][ type ]	= kAC_ON	
			wWave[ ch ][ rg ][ ph      ][ type ]	= kAC_UNCHECKED 	
			wWave[ ch ][ rg ][ ph + 1][ type ]	= kAC_HIDE 	
		elseif ( ph == 0  					&&  !	bValue )  
			wWave[ ch ][ rg ][ ph      ][ type ]	= kAC_UNCHECKED 	
			wWave[ ch ][ rg ][ ph + 1][ type ]	= kAC_HIDE 	
		endif
	endif
	
	UpdatePanelDetailsEval()
End


Function		UpdatePanelDSEval()
	string  	sPnOptions	= ":dlg:tPnDSEvaluation"						// 040831 must be :dlg: for HelpTopic...???
	string  	sFolder		= ksEVAL	
	string		sPnTitle
	sprintf	sPnTitle, "%s %s", "Eval  " ,  FormatVersion()
	InitPanelDSEvaluation( sFolder, sPnOptions )	
	UpdatePanel(   "PnDSEvaluation", sPnTitle, sFolder, sPnOptions ) 			// display or hide needed/unneeded controls
End

Function		UpdatePanelDetailsEval()
	string  	sPnOptions	= ":dlg:tPnEvalDetails" 
	string  	sFolder		= ksEVAL	
	string		sPnTitle		= "Evaluation Details"
	InitPanelEvalDetailsNew( sFolder, sPnOptions )
	UpdatePanel(   "PnEvalDetails", sPnTitle, sFolder, sPnOptions ) 			// display or hide needed/unneeded controls
End


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	COMMON  PN_MULTI   FUNCTIONS


Function		InitPanelEvalDetails( sFolder, sPnOptions )
	string  	sFolder, sPnOptions
	string		sPanelWvNm = "root:uf:" + sFolder + sPnOptions
	variable	n = -1, nItems = 80
//	nvar		gChannels	= root:uf:cfsr:gChannels				
//	nvar		gChans	= root:uf:cfsr:gChannels					// The number channels in eval: must be updated both in  'InitPanelEvalDetails()' and  'Analyse()'...
//	gChans			= gChannels						//...as either may be called first. (Or replace all occurrences of  'cfsr:gChannels'  by  'cfsr:gChannels' )

	make /O /T /N=(nItems)	$sPanelWvNm
	wave  /T	tPn	=	$sPanelWvNm
	n =	PnLine1( tPn, n )
	n =	PnSeparator( tPn, n, " " )

	n = 	PnMultiLineEvalDetails( tPn, n )

	n =	PnSeparator( tPn, n, " " )
	n =	PnLine2( tPn, n )
	n =	PnSeparator( tPn, n, " " )
	n =	PnLine3( tPn, n )
	n =	PnSeparator( tPn, n, " " )
	n =	PnLine4( tPn, n )				// Same time? , Multiple keeps? , Show average? ...
	n =	PnSeparator( tPn, n, " " )
	n += 1;	tPn[ n ] =	"PN_BUTTON;	buAutoSetCursors;Auto Set Cursors; | PN_BUTTON;	buTest00	;TraceCfs() Pts; | PN_BUTTON;	buTest01	;Test01; "
	redimension  /N = (n+1)	tPn
End


Function		PnMultiLineEvalDetails( tPanel, n )
	wave   /T	tPanel
	variable	n
	wave	wChanOpts= root:uf:eval:evl:wChanOpts
	wave	wCRegion	= root:uf:eval:evl:wCRegion
	nvar		gChans	= root:uf:cfsr:gChannels
printf "\t\t\tPnMultiLineEvalDetails()  root:uf:cfsr:gChannels:%d \r", gChans
	variable	i = 0, ch, rg, rgCnt , ph, phCnt
	for ( ch = 0; ch < gChans;  ch += 1 )	
		tPanel[ n + i + 1 ] =	"PN_SEPAR "
		i += 1
		rgCnt	  = wChanOpts[ ch ][ CH_RGCNT ]
		tPanel[ n + i  +1 ] =	ChanAndRegionCntPnLine( ch )
		i += 1
		if ( wChanOpts[ ch ][ CH_ONOFF ] == TRUE )									// display the region lines in the panel only if the channel checkbox is on 
			for ( rg = 0; rg < rgCnt;  rg += 1 )	
				tPanel[ n + i + 1 ] =	RegionAndPhasesPnLine( ch, rg )
				i += 1
			endfor												
		endif
	endfor												
	return	n + i  
End


static Function  /S	ChanAndRegionCntPnLine( ch )
	variable	ch
	string  	sChanNm	=  CfsIONm( ch ) 
	string		sLine		= ""
	sLine		+=	"  PN_WVCHKBOX; 	root:uf:eval:evl:wChanOpts ;" + sChanNm + "; 0	;" + IndexToStr2( ch, CH_ONOFF ) 	+	"; 			;  fCbChanOnOff"
	sLine		+=	"| PN_WVSETVAR;	root:uf:eval:evl:wChanOpts;Regions;	20	;" + IndexToStr2( ch, CH_RGCNT ) 	+	";0," + num2str( RG_MAX ) + ",1; fRgInCh"	
	sLine		+=	"| PN_WVPOPUP;	root:uf:eval:evl:wChanOpts;Min;		60	;" + IndexToStr2( ch, CH_YAXISMIN )	+	"; fYAxis_Lst 	;  fYAxisMin"
	sLine		+=	"| PN_WVPOPUP;	root:uf:eval:evl:wChanOpts;Max;		60	;" + IndexToStr2( ch, CH_YAXISMAX )+	"; fYAxis_Lst 	; fYAxisMax"
	sLine		+=	AddHorizontalSeps( 4 )		// parameter is the number of preceding columns in this line
	return	sLine
End

Function	/S	AddHorizontalSeps( nExistingColumns )
//  Return so many horizontal separators as string so that all panel columns are adjusted neatly. The number needed depends on the number of preceding entries in this line and on the number of fits to be done.
	variable	nExistingColumns
	variable	nMinimumColumns	= 4		// take from the longest line ( with number of fits = 0 )
	nvar		gFitCnt			= root:uf:eval:evl:gfitCnt
	string  	sSeps			= ""					
	variable	hs, nAddSeps		= max( 3 + 2 * gFitCnt,  nMinimumColumns )  -  nExistingColumns
	for ( hs = 0; hs < nAddSeps; hs += 1 )
		sSeps		+=	"| PN_SEPHORZ"
	endfor
	return	sSeps
End


static Function  /S	RegionAndPhasesPnLine( ch, rg )
	variable	ch, rg
	nvar		gFitCnt	= root:uf:eval:evl:gfitCnt
	variable	ph
	string		sLine			= ""
	sLine		+=	"  PN_WVPOPUP	;root:uf:eval:evl:wCRegion	;;		80	; " + IndexToStr4( ch, rg, PH_PEAK, CN_ISUP )	+ 		"; fPkUpDn_Lst ; fPkUpDn"
	if ( gFitCnt == 0 )
		sLine  +=	"| PN_SEPHORZ"					// fill to  'nMinimumColumns' = 4 
	endif
	for ( ph = 0; ph < gFitCnt; ph += 1 )
		sLine   +=	"| PN_WVPOPUP	;root:uf:eval:evl:wCRegion	;;		80	; " + IndexToStr4( ch, rg, ph+PH_FIT0, CN_FITFNC ) +	"; fFitFuncs_Lst	; fFitFuncs"
		sLine   +=	"| PN_WVPOPUP	;root:uf:eval:evl:wCRegion	;;		80	; " + IndexToStr4( ch, rg, ph+PH_FIT0, CN_FITRANGE) +	"; fFitRange_Lst; fFitRange"
	endfor
	sLine		+=	"| PN_WVCHKBOX; 	root:uf:eval:evl:wCRegion	 ;Check ns;  0	;" + IndexToStr4( ch, rg, PH_PEAK, CN_CHK_NS ) +		"; 	; fCbCheckNs"
	sLine		+=	"| PN_WVCHKBOX; 	root:uf:eval:evl:wCRegion	 ;Auto/user;  0	;" + IndexToStr4( ch, rg, PH_PEAK, CN_LIM_A )     +		"; 	; fCbAutoUser"
	return	sLine
End


static Function		PnLine1( tPanel, n )
	wave   /T	tPanel
	variable	n
	string		sLine		= ""
	sLine		+=	"  PN_CHKBOX;	root:uf:eval:evl:gbDoEvaluation	;Evaluation;	"
	sLine		+=	"| PN_SETVAR;		root:uf:eval:evl:gfitCnt	 		;         Fits; 		22	;  %2d ;0," + num2str( ItemsInList( ksPHASES ) - PH_FIT0 ) + ",1; "	// adjust the maximum value 	  
	sLine		+=	"| PN_POPUP;		root:uf:eval:evl:gpStartValsOrFit	;; 	80	;		;gpStartValsOrFit_Lst;	gpStartValsOrFit"			// Sample: No default value (Par4) supplied, set only at program start. 
	sLine		+=	AddHorizontalSeps( 3 )					// parameter is the number of preceding columns in this line
	tPanel[ n + 1 ] = sLine
	return	n + 1
End

static Function		PnLine2( tPanel, n )
	wave   /T	tPanel
	variable	n
	string		sLine		= ""
	sLine 	= 	" PN_DISPVAR;	root:uf:eval:evl:gTblKeepCnt	;in Tbl: ;	20	;%3d	"
	sLine 	+= 	"| PN_DISPVAR;	root:uf:eval:evl:gavgKeepCnt	;in Avg: ;	20	;%3d	"
	sLine		+=	AddHorizontalSeps( 2 )					// parameter is the number of preceding columns in this line
	tPanel[ n + 1 ] = sLine
	return	n + 1
End

static Function		PnLine3( tPanel, n )
	wave   /T	tPanel
	variable	n
	string		sLine		= ""
	sLine		+=	"  PN_POPUP;		root:uf:eval:evl:gpLatencyCsr		;; 	80	;	2	;gpLatencyCsr_Lst; "				// Sample: Default value (Par4) supplied, reset on panel rebuild.
	sLine		+=	"| PN_SETVAR;		root:uf:eval:evl:gpkSidePts 		; Peakpts; 		22	;  %2d ;0,20,1; "	  
	sLine		+=	"| PN_POPUP;		root:uf:eval:evl:gpPrintResults		;; 	80	;		;gpPrintResults_Lst;	gpPrintResults"	// Sample: No default value (Par4) supplied, set only at program start. PrintResults needs an explicit action procedure 
	sLine		+=	AddHorizontalSeps( 3 )					// parameter is the number of preceding columns in this line
	tPanel[ n + 1 ] = sLine
	return	n + 1
End

static Function		PnLine4( tPanel, n )
	wave   /T	tPanel
	variable	n
	string		sLine		= ""
	sLine		+=	"  PN_CHKBOX;	root:uf:eval:evl:gbSameMagn	;Same time; 	"
	sLine		+=	"| PN_CHKBOX;	root:uf:eval:evl:gbMultipleKeeps	;Multiple keeps; "	
	sLine		+=	"| PN_CHKBOX;	root:uf:eval:evl:gbShowAverage	;Show average;	"	
	sLine		+=	"| PN_POPUP;		root:uf:eval:evl:gpDispTracesOrAvg	;; 	80	;		;gpDispTracesOrAvg_Lst;	gpDispTracesOrAvg"	// Sample: No default value (Par4) supplied, set only at program start. 
	sLine		+=	"| PN_CHKBOX;	root:uf:eval:evl:gbResTextbox	;Results;	"	
	sLine		+=	AddHorizontalSeps( 1 )					// parameter is the number of preceding columns in this line
	tPanel[ n + 1 ] = sLine
	return	n + 1
End


////////////////////////////////////////////////////////////////////////////////////////////////
//  CONTROL  ACTION  PROCEDURES

Function		root_uf_eval_evl_gbDoEvaluation( sControlNm, bValue )
// Sample: if the proc field in a checkbox in tPanel is empty then a proc with an auto-built name like this is called ( folder, underscore, variable base name)
// Advantage: Empty proc field in radio button in tPanel.  No explicit call to  'fChkbox( sControlNm, bValue )'  is necessary. Disadvantage: long function name containing folder is necessary
// Showing/hiding the evaluation panel is independent of the DoEvaluation checkbox  but is controlled by an exta 'Show panel' button  and the window close [X] button
	string		sControlNm
	variable	bValue	
	DoEvaluation( bValue )
End													

Static Function	DoEvaluation( bValue)
	variable	bValue	
	variable	ch
	nvar		gChans	= root:uf:cfsr:gChannels					// check ALL Cfs channels..
	for ( ch = 0; ch < gChans; ch += 1 )
		string  	sWNm	= CfsWndNm( ch ) 
		if ( WinType( sWNm ) == kGRAPH )
			if ( bValue ) 								// = gbDoEvaluation
				ShowInfo	/W= $sWNm 					// 040823 Display the small cursor control box. This is not mandatory for cursor usage.
			else
				HideInfo	/W=$sWNm					// Remove the Cursor control box  (this control box is not mandatory for cursor usage) ...
				EraseAndClearEvaluatedPoints( ch, sWNm )
				EraseAndClearCursors( ch, sWNm )			
				EraseAndClearFits( ch, sWNm )			
			endif
		endif
	endfor
	if ( bValue )
		if ( WinType( sWNm ) == kGRAPH )
			variable /G  root:uf:cfsr:gnDisplayCnt = 0			// global to keep the value till the next call to this function (should actually be static!)
//			if ( ! CursorsAreSet() )
//				AutoSetCursors()
//			endif
			SameDataAgain()
		endif
	endif
End

// TODO:
// FLAW  concerning all SetVariable controls: The Folder is missing in Action proc name , shoud be......................... 
Function		root_uf_eval_evl_gfitCnt( sControlNm, varNum, VarStr, sVarNm ) : SetVariableControl
//Function		gFitCnt( sControlNm, varNum, VarStr, sVarNm ) : SetVariableControl
	string		sControlNm, VarStr, sVarNm
	variable	varNum
	variable	ch
	nvar		gFitCnt	= root:uf:eval:evl:gfitCnt
	 print "...gFitCnt()",  sControlNm, varNum, VarStr, sVarNm, gFitCnt
	KillEvalDetailsDlg()	
	EvalDetailsDlg()	
	SameDataAgain()
	RescaleAllCursors()
End



Function		root_uf_eval_evl_gbSameMagn( sControlNm, bValue )
	string		sControlNm		
	variable	bValue
	//RedrawEvalPanel()						// enable / disable some dependent controls
//	variable	rg = 0// todo???
//	if ( bValue )
//		SetSameMagnification( rg )				// sets  'DO_RESET'  FALSE
//	endif
	RescaleAllChansBothAxis()
End


Function		root_uf_eval_evl_gbResTextbox( sControlNm, bValue )
	string		sControlNm		
	variable	bValue
	PrintEvalTextboxAllChans()					// displays or hides the evaluation results in the graph window
End


Function		fRgInCh( sControlNm, varNum, VarStr, sVarNm ) : SetVariableControl	// specified name (PN_WVSETVAR) has no folders
	string		sControlNm, VarStr, sVarNm
	variable	varNum
	variable	ch, typ
	StrToIndex2( sControlNm, ch, typ )									// 2 dims !!!   retrieves ch, typ
	// Convert auto-built global variable controlled by SETVAR / PN_WVSETVAR  back into element of 1-dimensional wave
	string		sFolderWave	= sVarNm[ 0, strlen( sVarNm ) - 1 - 2 ]				// 2 dims !!!   truncate channel  e.g. root_uf_eval_evl_wChanOpts12 -> root_uf_eval_evl_wChanOpts
	sFolderWave		= ReplaceCharWithString( sFolderWave, "_" , ":" )		// e.g. root_uf_eval_evl_wChanOpts -> root:uf:eval:evl:wChanOpts	
	wave	wWave	= $sFolderWave								// ASSUMPTION: wave name MUST NOT contain underscores 
	wWave[ ch ][ typ ]	= varNum 										// 2 dims !!!
	// print "\t\tfRgInCh( PN_WVSETVAR )  retrieves ",  sControlNm, ch, typ,  "-> ",varNum, sVarNm, sVarNm, sFolderWave, wWave[ ch ][ typ ]

	string  	sFolder		= ksEVAL
	string  	sPnOptions	= ":dlg:tPnEvalDetails" 
	UpdatePanel(  "PnEvalDetails", "Evaluation Details" , sFolder, sPnOptions )	// same params as in  ConstructOrDisplayPanel()
	//UpdatePanel(  "PnEvalDetails" )

	variable /G  root:uf:cfsr:gnDisplayCnt = 0		// this will erase the cursors...
	SameDataAgain()
End


Function		fCbChanOnOff( sControlNm, bValue )
	string		sControlNm
	variable	bValue
	variable	ch, typ
	StrToIndex2( sControlNm, ch, typ )									// 2 dims !!!  retrieves ch, typ
	// Convert auto-built global variable controlled by SETVAR / PN_WVCHKBOX  back into element of 2-dimensional wave
	string		sFolderCtrlBase	= sControlNm[ 0, strlen( sControlNm ) - 1 - 2 ]		// 2 dims !!! truncate channel and region e.g. root_uf_eval_evl_wChanOpts10 -> root_uf_eval_evl_wChanOpts
	string		sFolderWave	= ReplaceCharWithString( sFolderCtrlBase, "_" , ":" )	// e.g. root_uf_eval_evl_wChanOpts -> root:uf:eval:evl:wChanOpts	
	wave	wWave		= $sFolderWave							// ASSUMPTION: wave name MUST NOT contain underscores 
	wWave[ ch ][ typ ]			= bValue 								// 2 dims !!!
	print "\tfCbChanOnOff( PN_WVCHKBOX )  retrieves ",  sControlNm, "chan:", ch, typ,  "-> ", sFolderWave, wWave[ ch ], bValue

	// First kill the window which has just been turned  off ( it does no harm if it is already closed )...
	nvar		gChans	= root:uf:cfsr:gChannels									// check ALL Cfs channels..
	string		sWndNm
	sWndNm	= CfsWndNm( ch ) 
	if ( bValue == FALSE )
		DoWindow /K $sWndNm 
	endif
	//...then resize or build those which should be on
	variable	w = 0, wCnt = gChans
	for ( ch = 0; ch < gChans; ch += 1 ) 										// loop through ALL windows ven if they are currently off
		sWndNm	= CfsWndNm( ch ) 
		wave	wChanOpts	= root:uf:eval:evl:wChanOpts
		if ( wChanOpts[ ch ][ CH_ONOFF ] == TRUE )
			variable	Left, Top, Right, Bot
			GetAutoWindowCorners( w, wCnt, 0, 1, Left, Top, Right, Bot, 0, 100 )
			if ( WinType( sWndNm ) == kGRAPH )								// the window exists already
				//...then resize those which exist and should be on
				MoveWindow	 /W=$sWndNm  Left, Top, Right, Bot 
			else
				//...then build those which do not yet exist and should be on
				display 	/K=1  /W=( Left, Top, Right, Bot ) //as  sWndTitle		// build an empty window
				DoWindow  /C $sWndNm 									// rename the window
			endif
			DoWindow 	/F 	$sWndNm									// FRONT : display on top = completely visible
			w += 1													// count the  'ON'  windows
		endif
	endfor
	if ( bValue == TRUE )				// only if a window is added we have to do the analysis ( actually analysing the added channel would be sufficient )
		SameDataAgain()
	endif

	// Depending on the state of  'Chan' control   enable / disable  related   regions 
	KillEvalDetailsDlg()	
	EvalDetailsDlg()	
End


Function		fCbCheckNs( sControlNm, bValue )
	string		sControlNm
	variable	bValue
	variable	ch, rg, ph, typ
	StrToIndex4( sControlNm, ch, rg, ph, typ )								// 4 dims !!! 
	// Convert auto-built global variable controlled by SETVAR / PN_WVCHKBOX  back into element of 2-dimensional wave
	string		sFolderCtrlBase	= sControlNm[ 0, strlen( sControlNm ) - 1 - 4 ]		// 4 dims !!!  truncate channel and region e.g. root_uf_eval_evl_wRegionDir1012 -> root_uf_eval_evl_wCRegion
	string		sFolderWave	= ReplaceCharWithString( sFolderCtrlBase, "_" , ":" )	// e.g. root_uf_eval_evl_wCRegion -> root:uf:eval:evl:wCRegion	
	wave	wWave		= $sFolderWave							// ASSUMPTION: wave name MUST NOT contain underscores 
	wWave[ ch ][ rg ][ ph ][ typ ]= bValue 									// 4 dims !!! 
	//print "fCbCheckNs( PN_WVCHKBOX )  retrieves ",  sControlNm, ch, rg, ph, typ, StringFromList( ph, ksPHASES ), StringFromList( typ, sCN_TEXT ), "-> ", sFolderWave, wWave[ ch ][ rg ][ ph ][ typ ], bValue
	// depending on the state of  'Check noise' control   enable / disable  related  control  'Auto/User' limits
	EnableCheckbox( "PnEvalDetails", sFolderCtrlBase + IndexToStr4( ch, rg, ph, CN_LIM_A ), 	!bValue )	
End

Function		fCbAutoUser( sControlNm, bValue )
	string		sControlNm
	variable	bValue
	variable	ch, rg, ph, typ
	StrToIndex4( sControlNm, ch, rg, ph, typ )								// 4 dims !!! 
	// Convert auto-built global variable controlled by SETVAR / PN_WVCHKBOX  back into element of 2-dimensional wave
	string		sFolderCtrlBase	= sControlNm[ 0, strlen( sControlNm ) - 1 - 4 ]		// 4 dims !!!  truncate channel and region e.g. root_uf_eval_evl_wRegionDir1012 -> root_uf_eval_evl_wCRegion
	string		sFolderWave	= ReplaceCharWithString( sFolderCtrlBase, "_" , ":" )	// e.g. root_uf_eval_evl_wCRegion -> root:uf:eval:evl:wCRegion	
	wave	wWave		= $sFolderWave							// ASSUMPTION: wave name MUST NOT contain underscores 
	wWave[ ch ][ rg ][ ph ][ typ ]= bValue 									// 4 dims !!! 
	//print "fCbAutouser( PN_WVCHKBOX )  retrieves ",  sControlNm, ch, rg, ph, typ, StringFromList( ph, ksPHASES ), StringFromList( typ, sCN_TEXT ), "-> ", sFolderWave, wWave[ ch ][ rg ][ ph ][ typ ], bValue
End



Function		fYaxisMin( sControlNm, popNum, popStr ) : PopupMenuControl
// executed when the user selected an item from the listbox
	string		sControlNm, popStr
	variable	popNum
	variable	ch, typ
	StrToIndex2( sControlNm, ch, Typ )									// 2 dims: 2 !!! 
	// Convert auto-built global variable controlled by POPMENU / PN_WVPOPUP  back into element of  1-  to  4-dimensional wave
	string		sFolderCtrlBase	= sControlNm[ 0, strlen( sControlNm ) - 1 - 2 ]		// 2 dims: 2 !!!   truncate channel , region and phase e.g. root_uf_eval_evl_wChanOpts10 -> root_uf_eval_evl_wChanOpts
	string		sFolderWave	= ReplaceCharWithString( sFolderCtrlBase, "_" , ":" )	// e.g. root_uf_eval_evl_wChanOpts -> root:uf:eval:evl:wChanOpts	
	wave	wWave		= $sFolderWave							// ASSUMPTION: wave name MUST NOT contain underscores 
	wWave[ ch ][ typ ]= popNum - 1										// 2 dims: 2 !!! 
	//print "faxisMin:",  sControlNm, ch, typ, StringFromList( typ, ksCHANS ), "->", pd(popStr,9), pd(sFolderWave,16), wWave[ ch ][ typ ]
	SameDataAgain()
End

Function		fYaxisMax( sControlNm, popNum, popStr ) : PopupMenuControl
// executed when the user selected an item from the listbox
	string		sControlNm, popStr
	variable	popNum
	variable	ch, typ
	StrToIndex2( sControlNm, ch, Typ )									// 2 dims !!! 
	// Convert auto-built global variable controlled by POPMENU / PN_WVPOPUP  back into element of  1-  to  4-dimensional wave
	string		sFolderCtrlBase	= sControlNm[ 0, strlen( sControlNm ) - 1 - 2 ]		// 2 dims !!!   truncate channel , region and phase e.g. root_uf_eval_evl_wChanOpts10 -> root_uf_eval_evl_wChanOpts
	string		sFolderWave	= ReplaceCharWithString( sFolderCtrlBase, "_" , ":" )	// e.g. root_uf_eval_evl_wChanOpts -> root:uf:eval:evl:wChanOpts	
	wave	wWave		= $sFolderWave							// ASSUMPTION: wave name MUST NOT contain underscores 
	wWave[ ch ][ typ ]= popNum - 1										// 2 dims !!! 
	//print "faxisMax:",  sControlNm, ch, typ, StringFromList( typ, ksCHANS ), "->", pd(popStr,9), pd(sFolderWave,16), wWave[ ch ][ typ ]
	SameDataAgain()
End

Function		fYaxis_Lst( sControlNm )
	string			sControlNm
	PopupMenu	$sControlNm	 value = ksYAXIS
End




// Version 1 : PEAK  DIRECTION  CONTROLLED  BY  CHECKBOX
// sLine	+=	"| PN_WVCHKBOX; 	root:uf:eval:evl:wCRegion	 ;Peak: up;	;" + IndexToStr4( ch, rg, PH_PEAK, CN_ISUP )	+ 	"; 	; fCbPkUpDn"

//Function		fCbPkUpDn( sControlNm, bValue )
//	string		sControlNm
//	variable	bValue
//	variable	ch, rg, ph, typ
//	StrToIndex4( sControlNm, ch, rg, ph, typ )	
//	// Convert auto-built global variable controlled by SETVAR / PN_WVCHKBOX  back into element of 2-dimensional wave
//	string		sFolderCtrlBase	= sControlNm[ 0, strlen( sControlNm ) - 5 ]			// truncate channel and region e.g. root_uf_eval_evl_wRegionDir1012 -> root_uf_eval_evl_wCRegion
//	string		sFolderWave	= ReplaceCharWithString( sFolderCtrlBase, "_" , ":" )	// e.g. root_uf_eval_evl_wCRegion -> root:uf:eval:evl:wCRegion	
//	wave	wWave		= $sFolderWave							// ASSUMPTION: wave name MUST NOT contain underscores 
//	wWave[ ch ][ rg ][ ph ][ typ ]= bValue 
//	//print "fCbPkUpDn( PN_WVCHKBOX )  retrieves ",  sControlNm, ch, rg, ph, typ, StringFromList( ph, ksPHASES ), StringFromList( typ, sCN_TEXT ), "-> ", sFolderWave, wWave[ ch ][ rg ][ ph ][ typ ], bValue
//	SameDataAgain()
//End


// Version 2 : PEAK  DIRECTION  CONTROLLED  BY  LISTBOX
// sLine		+=	"| PN_WVPOPUP	;root:uf:eval:evl:wCRegion	 ;;		80	;" + IndexToStr4( ch, rg, PH_PEAK, CN_ISUP )	+       "; fPkUpDn_Lst ; fPkUpDn"

Function		fPkUpDn( sControlNm, popNum, popStr ) : PopupMenuControl
// executed when the user selected an item from the listbox
	string		sControlNm, popStr
	variable	popNum
	variable	ch, rg, ph, typ
	StrToIndex4( sControlNm, ch, rg, ph, Typ )								// 4 dims !!! 
	// Convert auto-built global variable controlled by POPMENU / PN_WVPOPUP  back into element of  1-  to  4-dimensional wave
	string		sFolderCtrlBase	= sControlNm[ 0, strlen( sControlNm ) - 1 - 4 ]		// 4 dims !!!  truncate channel , region and phase e.g. root_uf_eval_evl_wRegion1032 -> root_uf_eval_evl_wCRegion
	string		sFolderWave	= ReplaceCharWithString( sFolderCtrlBase, "_" , ":" )	// e.g. root_uf_eval_evl_wCRegion -> root:uf:eval:evl:wCRegion	
	wave	wWave		= $sFolderWave							// ASSUMPTION: wave name MUST NOT contain underscores 
	wWave[ ch ][ rg ][ ph ][ typ ]= popNum - 1								// 4 dims !!! 
	print "fPkUpDn:",  sControlNm, ch, rg, ph, typ, StringFromList( ph, ksPHASES ), "->", pd(popStr,9), pd(sFolderWave,16), wWave[ ch ][ rg ][ ph ][ typ ]
	SameDataAgain()
End

Function		fPkUpDn_Lst( sControlNm )
	string			sControlNm
	PopupMenu	$sControlNm	 value = ksPEAKDIR 
End


Function		fFitFuncs( sControlNm, popNum, popStr ) : PopupMenuControl
// executed when the user selected an item from the listbox
	string		sControlNm, popStr
	variable	popNum
	variable	ch, rg, ph, typ
	StrToIndex4( sControlNm, ch, rg, ph, Typ )								// 4 dims !!! 
	// Convert auto-built global variable controlled by POPMENU / PN_WVPOPUP  back into element of  1-  to  4-dimensional wave
	string		sFolderWave	= sControlNm[ 0, strlen( sControlNm ) -1 - 4 ]			// 4 dims !!!   truncate channel , region and phase e.g. root_uf_eval_evl_wRegion1032 -> root_uf_eval_evl_wCRegion
	sFolderWave		= ReplaceCharWithString( sFolderWave, "_" , ":" )		// e.g. root_uf_eval_evl_wCRegion -> root:uf:eval:evl:wCRegion	
	wave	wWave	= $sFolderWave								// ASSUMPTION: wave name MUST NOT contain underscores 
	wWave[ ch ][ rg ][ ph ][ typ ]= popNum - 1								// 4 dims !!! 
	print "fFitFuncs:",  sControlNm, ch, rg, ph, typ, pd(StringFromList( ph, ksPHASES),7), StringFromList( typ, sCN_TEXT ),"\t->", pd(popStr,9), pd(sFolderWave,16), wWave[ ch ][ rg ][ ph ][ typ ], StringFromList( wWave[ ch ][ rg ][ ph ][ typ ], sFITFUNC )
	SameDataAgain()
End

Function		fFitFuncs_Lst( sControlNm )
	string			sControlNm
	PopupMenu	$sControlNm	 value = sFITFUNC
End


Function		fFitRange( sControlNm, popNum, popStr ) : PopupMenuControl
// executed when the user selected an item from the listbox
	string		sControlNm, popStr
	variable	popNum
	variable	ch, rg, ph, typ
	StrToIndex4( sControlNm, ch, rg, ph, Typ )								// 4 dims !!!
	// Convert auto-built global variable controlled by POPMENU / PN_WVPOPUP  back into element of  1-  to  4-dimensional wave
	string		sFolderWave	= sControlNm[ 0, strlen( sControlNm ) - 1 - 4 ]		// 4 dims !!!   truncate channel , region and phase e.g. root_uf_eval_evl_wRegion1032 -> root_uf_eval_evl_wCRegion
	sFolderWave		= ReplaceCharWithString( sFolderWave, "_" , ":" )		// e.g. root_uf_eval_evl_wCRegion -> root:uf:eval:evl:wCRegion	
	wave	wWave	= $sFolderWave								// ASSUMPTION: wave name MUST NOT contain underscores 
	wWave[ ch ][ rg ][ ph ][ typ ]= popNum - 1								// 4 dims !!!
	print "fFitRange:",  sControlNm, ch, rg, ph, typ, pd(StringFromList( ph, ksPHASES),7), StringFromList( typ, sCN_TEXT ),"\t->", pd(popStr,9), pd(sFolderWave,16), wWave[ ch ][ rg ][ ph ][ typ ], StringFromList( wWave[ ch ][ rg ][ ph ][ typ ], sFITFUNC )
	SameDataAgain()
End

Function		fFitRange_Lst( sControlNm )
	string			sControlNm
	PopupMenu	$sControlNm	 value = ksFITRANGE
End


//Function		buAccept( sControlNm ) : ButtonControl
//	string		sControlNm		
//	AcceptCursorsStoreRegion()
//End
//
//Function		buSaveTable( sControlNm ) : ButtonControl
//	string		sControlNm		
//	printf "\tSave tables.\r"
//	SaveTables()
//End
//
//Function		buSaveAverage( sControlNm ) : ButtonControl
//	string		sControlNm		
//	printf "\tSave averages..\r"
//	SaveAverages()
//End
//
//Function		buEraseAverage( sControlNm ) : ButtonControl
//	string		sControlNm		
//	printf "\tClear averages..\r"
//	EraseAverages()
//End

// works differently....????
//Function		gsPFS( ctrlName, varNum, varStr, varName ) : SetVariableControl
//Function		root_uf_cfsr_gsPFS( ctrlName, varNum, varStr, varName ) : SetVariableControl
//Function		root_uf_eval_evl_gbShowAverage( sControlNm, bValue )	

// Sample: the auto-built proc name (=no explicit proc name given in panel definition) contains automatically the folder
// Sample: when an explicit proc name is given in panel definition then the folder may be missing in this name e.g. gbShowAverage()
Function		root_uf_eval_evl_gbShowAverage( sControlNm, bValue )	
	string		sControlNm		
	variable	bValue
	DisplayAllAverages()
End


//Function		buEvalPrevData( sControlNm ) : ButtonControl
//	string		sControlNm
//	ReadCfsFile( cSAMEFILE, cPREVDATA, cERASE, cSINGLE )
//End
//
//Function		buEvalSameData( sControlNm ) : ButtonControl
//	string		sControlNm
//	ReadCfsFile( cSAMEFILE, cSAMEDATA, cERASE, cSINGLE )
//End
//
//Function		buEvalNextData( sControlNm ) : ButtonControl
//	string		sControlNm
//	ReadCfsFile( cSAMEFILE, cNEXTDATA, cERASE, cSINGLE )
//End
//
//Function		buEvalKeepToTbl( sControlNm ) : ButtonControl
//	string		sControlNm
//	nvar		gTblKeepCnt	= root:uf:eval:evl:gTblKeepCnt					// 
//	AddToTable()
//	ReadCfsFile( cSAMEFILE, cNEXTDATA, cERASE, cSINGLE )
//End
//
//Function		buEvalAvg( sControlNm ) : ButtonControl
//	string		sControlNm
//	AddToAverage()
//	ReadCfsFile( cSAMEFILE, cNEXTDATA, cERASE, cSINGLE )
//End
//
//Function		buEvalKeepTblAvg( sControlNm ) : ButtonControl
//	string	sControlNm
//	AddToTable()
//	AddToAverage()
//	ReadCfsFile( cSAMEFILE, cNEXTDATA, cERASE, cSINGLE )
//End

Function		gpStartValsOrFit( sControlNm, popNum, popStr ) : PopupMenuControl
	string		sControlNm, popStr
	variable	popNum
	nvar		gpStartValsOrFit	= root:uf:eval:evl:gpStartValsOrFit					// 0 : do not fit, display only starting values, 1 : do fit
	gpStartValsOrFit	= popNum - 1											// popNum starts at 1
	SameDataAgain()
End
Function		gpStartValsOrFit_Lst( sControlNm )
	string			sControlNm
	PopupMenu	$sControlNm	 value = "Start values;Do fit"
End


Function		gpPrintResults( sControlNm, popNum, popStr ) : PopupMenuControl
// PrintResults needs an explicit action procedure to convert the index of the listbox entry into the print mask
	string		sControlNm, popStr
	variable	popNum
	nvar		gpPrintResults	= root:uf:eval:evl:gpPrintResults
	gpPrintResults	= popNum - 1											// popNum starts at 1
	nvar		gPrintMask	= root:uf:eval:evl:gprintMask
	gPrintMask	= str2num( StringFromList( popNum - 1, ksPRINTMASKS ) )			// Convert changed popup index into PrintMask bit field
//	SetFormula	gPrintMask,	"str2num( StringFromList( popNum - 1, ksPRINTMASKS ) )"
	 // print "\t\tgpPrintResults:",  sControlNm, popNum, popStr,"-> print mask: ", gPrintMask
	SameDataAgain()
End
Function		gpPrintResults_Lst( sControlNm )
	string			sControlNm
	PopupMenu	$sControlNm	 value = ksPRINTRESULTS
End


Function		gpLatencyCsr_Lst( sControlNm )
	string			sControlNm
	PopupMenu	$sControlNm	 value = sLATCSR
End


Function		gpDispTracesOrAvg( sControlNm, popNum, popStr ) : PopupMenuControl
	string		sControlNm, popStr
	variable	popNum
	DisplayAllAverages1( popNum - 1)									// popNum starts at 1
End
Function		gpDispTracesOrAvg_Lst( sControlNm )
	string			sControlNm
	PopupMenu	$sControlNm	 value = "Only traces;traces + avg;only average"
End


static Function		DisplayAverage1( nMode, ch )
// change colors of original and average traces depending on what the user wants to see (as selected in the Popup DispTracesOrAvg)
	variable	nMode, ch
	wave  /Z	wAvg	= $FoAvgWvNm( ch )
	string		sWndNm	= CfsWndNm( ch )
	if ( WinType( sWndNm ) == kGRAPH  &&  waveExists ( wAvg ) )				// window or trace may not (yet) exist
		string  	sTNL	= TraceNameList( sWndNm, ";", 1 )
		string  	sOrgNames=  ListMatch( sTNL, "wOrg*" )
		string  	sAvgNames=  ListMatch( sTNL, "wAvg*" )
		variable	nOrg, OrgCnt	= ItemsInList( sOrgNames )					// can be more than 1 in multiple traces mode
		variable	nAvg, AvgCnt	= ItemsInList( sAvgNames )					// should be 1
		variable	ORed, OGreen, OBlue, ARed, AGreen, ABlue
		printf "\t\tDisplayAverage1( mode:%d , ch:%d)  \t'%s' \tOrg(%3d):%s \tAvg(%3d):%s  \r", nMode, ch, sWndNm, OrgCnt, sOrgNames, AvgCnt, sAvgNames
		if ( nMode == 0 )
			// cosmetics: unnecessary in normal mode because the whole wnd is cleared when displaying new data, but USED TO HIDE THE TRACE IMMEDIATELY WHEN user unchecks the 'ShowAverage' button
			ARed = cBGCOLOR; 	AGreen = cBGCOLOR;  ABlue = cBGCOLOR	// background = invisible 
			ORed = 0;			OGreen = 0;		  OBlue = 0			// black 
		elseif ( nMode	== 1 )
			ARed = 43000; 		AGreen = 3000;  	ABlue = 3000			// dark red
			ORed = 32768;		OGreen = 32768;	OBlue = 32768			// grey 
		elseif ( nMode	== 2 )
			ARed = 65535; 		AGreen = 0;  		ABlue = 0				// red
			ORed = cBGCOLOR;	OGreen = cBGCOLOR;OBlue = cBGCOLOR	// background = invisible 
		endif
		for ( nAvg = 0; nAvg < AvgCnt; nAvg += 1 )
			string  	sAvgNm	= StringFromList( nAvg, sAvgNames )
			ModifyGraph 	/W=$sWndNm	  rgb( $sAvgNm )  = ( ARed, AGreen, ABlue ) 
		endfor
		for ( nOrg = 0; nOrg < OrgCnt; nOrg += 1 )
			string  	sOrgNm	= StringFromList( nOrg, sOrgNames )
			ModifyGraph 	/W=$sWndNm	  rgb( $sOrgNm )	  = ( ORed, OGreen, OBlue ) 
		endfor
	endif
End

static Function		DisplayAllAverages1( nMode )
	variable	nMode
	nvar		gChans		= root:uf:cfsr:gChannels						
	variable	ch
	for ( ch = 0; ch < gChans; ch += 1 ) 							
		DisplayAverage1( nMode, ch )
	endfor
End




////////////////////////////////////////////////////////////////////////////////////////////////
//  LITTLE  HELPERS


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  FITTING

static Function		SetStartParams( wPar, w, ch, rg, ph, nFitFunc, Left, Right )
// Returns  whether  starting parameters could be computed
	wave  	/D wPar
	wave	w
	variable	ch, rg, ph, nFitFunc, Left, Right
	string  	sMsg
// OLD 040908
// Use previously computed values for  RT2080, Amp, ...
//	 todo..........check and complain only in those fit functions where these starting values are actually needed (e.g. NOT in FT_LINE)
//	variable	RT2080, Amplitude
//	if ( 	ExistsEvT(  ch, rg, EV_RISE80 )    &&  ExistsEvT(  ch, rg, EV_RISE20 ) )
//		RT2080	= EvT( ch, rg, EV_RISE80 ) - EvT( ch, rg, EV_RISE20 )
//	elseif ( ExistsEvT(  ch, rg, EV_RISE80 )  &&  ExistsEvT(  ch, rg, EV_RISE50 ) )
//		RT2080	= 2 * ( EvT( ch, rg, EV_RISE80 ) - EvT( ch, rg, EV_RISE50 ) )
//	elseif ( ExistsEvT(  ch, rg, EV_RISE50 )  &&  ExistsEvT(  ch, rg, EV_RISE20 ) )
//		RT2080	= 2 * ( EvT( ch, rg, EV_RISE50 ) - EvT( ch, rg, EV_RISE20 ) )
//	else
//		RT2080	= 1
//		Alert( cLESSIMPORTANT,  "RT20/50/80 do not exist. Assuming 1" )				// can occur for multiple reasons e.g. 1.wrong region 2.mixed with artefact
//	endif
//
//	variable	Delay	= Left  												// assume begin of Peak evaluation region as starting value for  delay  in Rise fits
//	variable	TauDecay = ( Right - Delay - 2* RT2080 ) * 0.3  							// assume Decay  is much slower  than  Rise
//	
//	if (	ExistsEvY( ch, rg, EV_PEAK )   &&   ExistsEvY( ch, rg, EV_BBEG ) ) 				// Amp	EV_BBEG or EV_BEND
//		Amplitude	= EvY( ch, rg, EV_PEAK )  - EvY( ch, rg, EV_BBEG ) 
//		//print "amp OK",  EvY( ch, rg, EV_PEAK )  , EvY( ch, rg, EV_BBEG )
//	else
//		Amplitude	= 100
//		Alert( cIMPORTANT,  "Amplitude and/or Base value does not exist. Assuming 100" )	// should not occur as any region has min/max (serious warning, Level1)
//	endif
//	//printf "\tSetStartParams(\tch:%d  rg:%d  ph:%d)  \tnFitFunc:%d  %s\tParams:%d \tt1:%6.2lf \tt2:%6.2lf  \ta1:%6.2lf \ta2:%6.2lf  \r", ch, rg, ph, nFitFunc, pd( StringFromList( nFitFunc, sFITFUNC ),9), numpnts( wPar), EvT( ch, rg, EV_RISE80 ) , EvT( ch, rg, EV_RISE20 ), EvY( ch, rg, EV_PEAK )  , EvY( ch, rg, EV_BBEG ) 
//	//printf "\tSetStartParams( \tch:%d  rg:%d  ph:%d)  \tnFitFunc:%d  %s \tParams:%d \tRT2080:%6.2lf \tAmp:%6.2lf  \r", ch, rg, ph, nFitFunc, pd( StringFromList( nFitFunc, sFITFUNC ),9), numpnts( wPar), RT2080, Amplitude
	
	variable	nSmoothPts	= 5
	variable	nPnts		= numPnts( w )		// the points in the range to be fitted 

	if ( nPnts < nSmoothPts )

		sprintf sMsg, "Cannot fit '%s'  (channel:%d  region:%d  Fit:%d) : range to be fitted is off screen or contains too few (%d)  points.", StringFromList( nFitFunc, sFITFUNC ), ch, rg, ph - PH_FIT0, nPnts
		Alert( cIMPORTANT,  sMsg )
		wPar	= Nan						// or return error code
		return	FALSE			
	else  

		// Compute the starting values right here.  Another approach would be to use previously computed values for  RT2080, Amp, ...
		if ( nFitFunc == FT_RISE  ||  nFitFunc == FT_RISECONST ||  nFitFunc == FT_RISDEC  ||  nFitFunc == FT_RISDECCONST )
			variable	x20, x80, RT2080, Delay, Amp, Dip, TauDecay, Level
			Wavestats  /Q	w											// Get minimum and maximum of wave
			if ( GetRTError( 0 ) )											// Workaround / cripple code : it seems that ( in other program locations )  the  WavStats  error is mixed up with the  FindLevel  error  .....
				print "****Internal warning : SetStartParams() : " + GetRTErrMessage()
				variable dummy = GetRTError( 1 )
				return	FALSE
			endif
	//		if ( V_Flag )
	//			sprintf sMsg, "While fitting '%s'  (channel:%d  region:%d  phase:%d)  WaveStats gave error in range %.2lf..%.2lfms .", pd( StringFromList( nFitFunc, sFITFUNC ),9), ch, rg, ph, Left, Right
	//			Alert( cIMPORTANT,  sMsg )
	//		endif
			Amp		= V_max
			Dip		= V_min
			Level	= .2
	
			FindLevel	  /Q			  /B=(nSmoothPts)  w  V_min + Level * ( Amp - Dip )		// Find the 20% crossing  going forward  (averaging box is 5 points wide) 
			x20		= PossiblyReportFindLevelError( V_Flag,  V_LevelX, ch, rg, ph, nFitFunc, Left, Right, Level, Dip, Amp ) 
			Level	= .8
			FindLevel	 /Q			  /B=(nSmoothPts)  w  V_min + Level * ( Amp - Dip )		// Find the 80% crossing  going forward  (averaging box is 5 points wide)
			x80		= PossiblyReportFindLevelError( V_Flag,  V_LevelX, ch, rg, ph, nFitFunc, Left, Right, Level, Dip, Amp ) 
			RT2080	= x80 - x20
			Delay	= x20  											// 	delay		TODO: better start value for  delay is intersection of RT2080 with baseline
		endif
		if ( nFitFunc == FT_RISDEC  ||  nFitFunc == FT_RISDECCONST )	
			Level	= .2
			FindLevel	 /Q  /R=( Inf, 0 )  /B=(nSmoothPts)  w   V_min + Level * ( Amp - Dip ) 		// Find the 20% crossing  going backward  (averaging box is 5 points wide)
			x20		= PossiblyReportFindLevelError( V_Flag,  V_LevelX, ch, rg, ph, nFitFunc, Left, Right, Level, Dip, Amp ) 
			Level	= .8
			FindLevel	 /Q  /R=( Inf, 0 )  /B=(nSmoothPts)  w   V_min + Level * ( Amp - Dip ) 		// Find the 80% crossing  going backward  (averaging box is 5 points wide)
			x80		= PossiblyReportFindLevelError( V_Flag,  V_LevelX, ch, rg, ph, nFitFunc, Left, Right, Level, Dip, Amp ) 
			TauDecay	= x20 - x80										// TauDecay		TODO: better start value for  TauDecay is intersection  with baseline
		endif
		
		// printf "\tSetStartParams()  \tnFitFunc:%d  %s \tParams:%d   L:%6.3lf  R:%6.3lf   w( 0.0 ) : %6.3lf\t w( R-L %6.3lf ) : %6.3lf\t \r", nFitFunc, pd( StringFromList( nFitFunc, ksFITFUNC ),9), numPnts( wPar ), Left, Right, w( 0 ), Right-Left, w( Right-Left ) 
	
		if ( 	nFitFunc   == FT_LINE )							// straight line
			wPar[ 0 ] = w[ 0 ]  								//	y value at left region border = intersection value with an y axis shifted to begin of region 
			wPar[ 1 ] = ( w( Right  - Left ) - w( 0 ) ) / ( Right - Left )		//	the slope
	
		elseif ( 	nFitFunc   == FT_1EXP )						// 1 exponential  without constant		(LSLIB.pas : 21)
			wPar[ 0 ] = w[ 0 ] 								// 	y value at left region border = intersection value with an y axis shifted to begin of region 
			wPar[ 1 ] =  ( Right - Left ) / 4 						// 	Tau
	
		elseif ( nFitFunc == FT_1EXPCONST )						// 1 exponential  	with	 constant		(LSLIB.pas : 20)
			wPar[ 0 ] = w( 0 ) - w( Right - Left )					// 	y value at left region border = intersection value with an y axis shifted to begin of region  with constant offset subtracted
			wPar[ 1 ] =  ( Right - Left ) / 4 						// 	Tau
			wPar[ 2 ] = w( Right - Left )							// 	const offset 
			
		elseif ( nFitFunc == FT_2EXP )							// 2 exponentials without constant		(LSLIB.pas : 21)
			wPar[ 0 ] =  w( 0 ) / 2								//	 y value at left region border = intersection value with an y axis shifted to begin of region 
			wPar[ 1 ] =  ( Right - Left ) / 10 						// 	TauFast
			wPar[ 2 ] = wPar[ 0 ] 								// 	AmpSlow
			wPar[ 3 ] = wPar[ 1 ] * 5							// 	TauSlow
	
		elseif ( nFitFunc == FT_2EXPCONST )						// 2 exponentials  	with	 constant		(LSLIB.pas : 20)
			wPar[ 0 ] = ( w( 0 ) - w( Right - Left ) ) / 2				// 	y value at left region border = intersection value with an y axis shifted to begin of region 
			wPar[ 1 ] =  ( Right - Left ) / 10 						// 	TauFast
			wPar[ 2 ] = wPar[ 0 ] 								// 	AmpSlow
			wPar[ 3 ] = wPar[ 1 ] * 5							// 	TauSlow
			wPar[ 4 ] = w( Right- Left ) 							// 	const offset 
	
		elseif ( nFitFunc == FT_RISE )							// Sigmoidal rise	  ~  I_K   with delay		(LSLIB.pas : 14)
			wPar[ 0 ] = RT2080								//	rise time
			wPar[ 1 ] = Delay
			wPar[ 2 ] = Amp									// 	the measured amplitude	
	
		elseif ( nFitFunc == FT_RISECONST )						// Sigmoidal rise	  ~  I_K   with delay and constant	(LSLIB.pas : 14)
			wPar[ 0 ] = RT2080								//	rise time
			wPar[ 1 ] = Delay								// 	delay
			wPar[ 2 ] = Amp// - w( Right - Left )					// 	the measured amplitude with constant offset	 subtracted
			wPar[ 3 ] =  0//w( Right - Left )						// 	const offset  
	
		elseif ( nFitFunc == FT_RISDEC )						// Rise and Decay  ~  I_Na with delay				(LSLIB.pas : 12,13)
			wPar[ 0 ] = RT2080								//	rise time
			wPar[ 1 ] = Delay								// 	delay
			wPar[ 2 ] = 15 *  Amp * ( 1 + exp( Delay / RT2080 ) ) 		//	 purely empirical........
			wPar[ 3 ] = TauDecay 							//	 TauDecay
			wPar[ 4 ] = 0					
	
		elseif ( nFitFunc == FT_RISDECCONST )					// Rise and Decay  ~  I_Na with delay and constant	(LSLIB.pas : 12,13)
			wPar[ 0 ] = RT2080								//	rise time
			wPar[ 1 ] = Delay								// 	delay
			wPar[ 2 ] = 15 *  Amp * ( 1 + exp( Delay / RT2080 ) ) 		//	 purely empirical........
			wPar[ 3 ] = TauDecay 							//	 TauDecay
			wPar[ 5 ] = w( Right - Left )							// 	const offset  
		endif
	
		//printf "\tSetStartParams( \tch:%d  rg:%d  ph:%d)  \tnFitFunc:%d  %s \tParams:%d \tRT2080:%6.2lf \tAmp:%6.2lf  \r", ch, rg, ph, nFitFunc, pd( StringFromList( nFitFunc, sFITFUNC ),9), numpnts( wPar), RT2080, Amplitude

	endif
	if ( numtype( x20 ) == cNUMTYPE_NAN  ||  numtype( x80 ) == cNUMTYPE_NAN ) 
		return	FALSE
	endif
	return	TRUE
End


static Function		PossiblyReportFindLevelError( Flag, LevelX, ch, rg, ph, nFitFunc, Left, Right, Level, Dip, Amp ) 
	variable	Flag, LevelX, ch, rg, ph, nFitFunc, Left, Right, Level , Dip, Amp
	string  	sMsg
	if ( Flag )
		sprintf sMsg, "While fitting '%s'  (channel:%d  region:%d  Fit:%d)  %d%% level crossing in range %.2lf...%.2lfms could not be found (min:%.2lf, max:%.2lf)  [Flag:%d].", StringFromList( nFitFunc, sFITFUNC ), ch, rg, ph - PH_FIT0, 100*Level, Left, Right, Dip, Amp, Flag
		Alert( cIMPORTANT,  sMsg )
		return	Nan
	endif
	return	LevelX
End


// also used in OLA
Function		FitMultipleFunctionsEval( wPar, x ) : FitFunc			// cannot be static
	wave	wPar
	variable	x
	variable	y
	nvar		nFitFunc	= root:uf:eval:fit:gFitFunc

	if ( 	nFitFunc   == FT_LINE )							// 	straight line
		y = wPar[ 0 ] +  x * wPar[ 1 ]

	elseif ( nFitFunc == FT_1EXP )							// 	1 exponential  without constant		(LSLIB.pas : 21)
		y = wPar[ 0 ]  * exp( - x  / wPar[ 1 ] ) 
	
	elseif ( nFitFunc == FT_1EXPCONST )						//	1 exponential  	with	 constant		(LSLIB.pas : 20)
		y = wPar[ 0 ]  * exp( - x / wPar[ 1 ] ) + wPar[ 2 ] 

	elseif ( nFitFunc == FT_2EXP )							//	2 exponentials without constant		(LSLIB.pas : 21)
		y = wPar[ 0 ]  * exp( - x / wPar[ 1 ] ) + wPar[ 2 ]  * exp( - x / wPar[ 3 ] )

	elseif ( nFitFunc == FT_2EXPCONST )						//	2 exponentials  	with	 constant		(LSLIB.pas : 20)
		y = wPar[ 0 ]  * exp( -x / wPar[ 1 ] ) + wPar[ 2 ]  * exp( - x / wPar[ 3 ] ) + wPar[ 4 ]

	elseif ( nFitFunc == FT_RISE )							//	Sigmoidal rise	  ~  I_K   with delay				(LSLIB.pas : 14)
		y =  exp( 4 * ln( 1 - exp( - ( x - wPar[ 1 ] ) / wPar[ 0 ] ) ) ) * wPar[ 2 ] 
		y = numType( y ) == NUMTYPE_NAN  ?  0  : y

	elseif ( nFitFunc == FT_RISECONST )						//	Sigmoidal rise	  ~  I_K   with delay and constant	(LSLIB.pas : 14)
		y =  exp( 4 * ln( 1 - exp( - ( x - wPar[ 1 ] ) / wPar[ 0 ] ) ) ) * wPar[ 2 ] + wPar[ 3 ] 
		y = numType( y ) == NUMTYPE_NAN  ?  0  : y

	elseif ( nFitFunc == FT_RISDEC )						//	Rise and Decay	  ~  I_Na with delay				(LSLIB.pas : 12,13)
		y =  exp( 3 * ln( 1 - exp( - ( x - wPar[ 1 ] ) / wPar[ 0 ] ) ) ) * ( wPar[ 2 ] * exp( - x / wPar[ 3 ] ) + wPar[ 4 ] )
		y = numType( y ) == NUMTYPE_NAN  ?  0  : y

	elseif ( nFitFunc == FT_RISDECCONST )					//	Rise and Decay	  ~  I_Na with delay and constant	(LSLIB.pas : 12,13)
		y =  exp( 3 * ln( 1 - exp( - ( x - wPar[ 1 ] ) / wPar[ 0 ] ) ) ) * ( wPar[ 2 ] * exp( - x / wPar[ 3 ] ) + wPar[ 4 ] )  + wPar[ 5 ] 
		y = numType( y ) == NUMTYPE_NAN  ?  0  : y
	endif

//	// 	straight line
//	if ( 	nFitFunc   == FT_LINE )
//		y = wPar[ 0 ] +  x * wPar[ 1 ]  
//	
//	// 	1 exponential  without constant		(LSLIB.pas : 21)
//	elseif ( 	nFitFunc   == FT_1EXP )
//		y = wPar[ 0 ]  * exp( - x / wPar[ 1 ] ) 
//	
//	//	1 exponential  	with	 constant		(LSLIB.pas : 20)
//	elseif ( nFitFunc == FT_1EXPCONST )
//		y = wPar[ 0 ]  * exp( - x / wPar[ 1 ] ) + wPar[ 2 ] 
//
//	//	2 exponentials without constant		(LSLIB.pas : 21)
//	elseif ( nFitFunc == FT_2EXP )
//		y = wPar[ 0 ]  * exp( - x / wPar[ 1 ] ) + wPar[ 2 ]  * exp( - x / wPar[ 3 ] )
//
//	//	2 exponentials  	with	 constant					(LSLIB.pas : 20)
//	elseif ( nFitFunc == FT_2EXPCONST )
//		y = wPar[ 0 ]  * exp( -x / wPar[ 1 ] ) + wPar[ 2 ]  * exp( - x / wPar[ 3 ] ) + wPar[ 4 ]
//
//	//	Sigmoidal rise	  ~  I_K   with delay				(LSLIB.pas : 14)
//	elseif ( nFitFunc == FT_RISE )
//		y =  exp( 4 * ln( 1 - exp( - ( x - wPar[ 1 ] ) / wPar[ 0 ] ) ) ) * wPar[ 2 ] 
//		//y =   x  <  wPar[ 3 ]  ?  0  :  exp( 4 * ln( 1 - exp( - ( x - wPar[ 1 ] ) / wPar[ 0 ] ) ) ) * wPar[ 2 ] 		//?????????? PAR 3
//		y = numType( y ) == NUMTYPE_NAN  ?  0  : y
//
//	//	Sigmoidal rise	  ~  I_K   with delay and constant	(LSLIB.pas : 14)
//	elseif ( nFitFunc == FT_RISECONST )
//		y =  exp( 4 * ln( 1 - exp( - ( x - wPar[ 1 ] ) / wPar[ 0 ] ) ) ) * wPar[ 2 ] + wPar[ 3 ] 
//		//y =   x  <  wPar[ 3 ]  ?  0  :  exp( 4 * ln( 1 - exp( - ( x - wPar[ 1 ] ) / wPar[ 0 ] ) ) ) * wPar[ 2 ] 		//?????????? PAR 3
//		y = numType( y ) == NUMTYPE_NAN  ?  0  : y
//
//	//	Rise and Decay	  ~  I_Na with delay				(LSLIB.pas : 12,13)
//	elseif ( nFitFunc == FT_RISDEC )
//		//org	: y =   x <= wPar[ 1 ]  ?  0  :  exp( 3 * ln( 1 - exp( - ( x - wPar[ 1 ] ) / wPar[ 0 ] ) ) ) * ( wPar[ 2 ] * exp( - x / wPar[ 3 ] ) + wPar[ 4 ] )
//		y =  exp( 3 * ln( 1 - exp( - ( x - wPar[ 1 ] ) / wPar[ 0 ] ) ) ) * ( wPar[ 2 ] * exp( - x / wPar[ 3 ] ) + wPar[ 4 ] )
//		//y =  exp( 3 * ln( 1 - exp( - ( x-26 - wPar[ 1 ] ) / wPar[ 0 ] ) ) ) * ( wPar[ 2 ] * exp( - (x-26) / wPar[ 3 ] ) + wPar[ 4 ] ) -1000
//		y = numType( y ) == NUMTYPE_NAN  ?  0  : y
//
//	//	Rise and Decay	  ~  I_Na with delay and constant	(LSLIB.pas : 12,13)
//	elseif ( nFitFunc == FT_RISDECCONST )
//		//org	: y =   x <= wPar[ 1 ]  ?  0  :  exp( 3 * ln( 1 - exp( - ( x - wPar[ 1 ] ) / wPar[ 0 ] ) ) ) * ( wPar[ 2 ] * exp( - x / wPar[ 3 ] ) + wPar[ 4 ] )
//		//y =  exp( 3 * ln( 1 - exp( - ( x - wPar[ 5 ] - wPar[ 1 ] ) / wPar[ 0 ] ) ) ) * ( wPar[ 2 ] * exp( - (x - wPar[ 5 ] ) / wPar[ 3 ] ) + wPar[ 4 ] ) 
//		y =  exp( 3 * ln( 1 - exp( - ( x - wPar[ 1 ] ) / wPar[ 0 ] ) ) ) * ( wPar[ 2 ] * exp( - x / wPar[ 3 ] ) + wPar[ 4 ] )  + wPar[ 5 ] 
//		y = numType( y ) == NUMTYPE_NAN  ?  0  : y
//	endif
////		if ( x == trunc( x ) )
////			print x,y
////		endif
	return	y
End

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function		buTest01( sControlNm ) : ButtonControl
	string		sControlNm	
	nvar	gpLatencyCsr = root:uf:eval:evl:gpLatencyCsr
	print "\tbuTest1  gpLatencyCsr =", gpLatencyCsr
End

Function		buAutoSetCursors( sControlNm ) : ButtonControl
	string		sControlNm	
	AutoSetCursorsAllChans()
	SameDataAgain()
End

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Slider magnify test

Function		buTest00( sControlNm ) : ButtonControl
	string		sControlNm
 TraceCfs( 0, 0 )
 TraceCfs( 0, 1 )
 TraceCfs( 0, 2 )
 TraceCfs( 1, 0 )
 TraceCfs( 1, 1 )
 TraceCfs( 1, 2 )
 TraceCfs( 2, 0 )
 TraceCfs( 2, 1 )
 TraceCfs( 3, 0 )
 TraceCfs( 3, 1 )
// 	SliderExample()
End

//Function SliderExample()
//	NewPanel /W=(150,50,501,285)
//	variable/G var1
//	variable/G wMagn[ ch ][ cXEXP ], wMagn[ ch ][ cXSHIFT ]
//	Execute "ModifyPanel cbRGB=(56797,56797,56797)"
//	SetVariable setvar0,pos={141,18},size={122,17},limits={-Inf,Inf,1},value= var1
//	Slider foo,pos={26,31},size={62,143},limits={-5,10,1},variable= var1
//	// Horizontal expand	
//	Slider foo2,pos={173,161},size={150,53}
//	Slider foo2,limits={1,20,1},variable= wMagn[ ch ][ cXEXP ],vert= 0,thumbColor= (0,1000,0), proc = fRedrawExpanded
//
//	Slider foo3,pos={80,31},size={62,143}
//	Slider foo3,limits={0,350,0},variable= var1,side= 2,thumbColor= (1000,1000,0)
//
//	Slider foo4,pos={173,59},size={150,13}
//	Slider foo4,limits={0,250,0},variable= var1,side= 0,vert= 0,thumbColor= (1000,1000,1000)
//
//	// Horizontal shift
//	Slider foo5,pos={173,90},size={150,53}
//	Slider foo5,limits={0,450,0},variable= wMagn[ ch ][ cXSHIFT ],side= 2,vert= 0,ticks= 10,thumbColor= (500,1000,1000), proc = fRedrawShifted
//End

//Function		fRedrawShifted( sControlNm, value, event )
//	string		sControlNm	// name of this slider control
//	variable	value		// value of slider
//	variable	event		// bit field: bit 0: value set; 1: mouse down, 2: mouse up, 3: mouse moved
//	//printf "\tSlider '%s'  gives value:%d  event:%d  \r", sControlNm, value, event
//	RedrawIt()
//	return 0				// other return values reserved
//End
//Function		fRedrawExpanded( sControlNm, value, event )
//	string		sControlNm	// name of this slider control
//	variable	value		// value of slider
//	variable	event		// bit field: bit 0: value set; 1: mouse down, 2: mouse up, 3: mouse moved
//	//printf "\tSlider '%s'  gives value:%d  event:%d  \r", sControlNm, value, event
//	RedrawIt()
//	return 0				// other return values reserved
//End
//
//Function		RedrawIt()
//	nvar		wMagn[ ch ][ cXSHIFT ]
//	nvar		wMagn[ ch ][ cXEXP ]
//	variable	ch		= 0
//	string		sWndNm	= CfsWndNm( ch ) 
//	wave	wMnMx	= root:uf:eval:evl:wMnMx
//	SetAxis	/W = $sWndNm  bottom,  wMagn[ ch ][ cXSHIFT ] - ( wMagn[ ch ][ cXSHIFT ] - wMnMx[ ch ][ MM_XMIN ] ) / wMagn[ ch ][ cXEXP ], wMagn[ ch ][ cXSHIFT ] + ( wMnMx[ ch ][ MM_XMAX ]  - wMagn[ ch ][ cXSHIFT ] ) / wMagn[ ch ][ cXEXP ]  
//End

