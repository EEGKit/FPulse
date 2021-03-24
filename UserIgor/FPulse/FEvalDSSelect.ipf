// 
//  FEvalDSSelect.ipf	Data section selection and analysis with a listbox

#pragma rtGlobals=1		// Use modern global access method.

 constant	kbACTIVE_MAGENTA	= 1		// highlight the active as bright white  with a shade of magenta
 constant	kMAGENTA			= 10000//6000	// the amount of missing green = the shade of magenta (<6000: very light pink, no false coloring of other states.  >15000: medium magenta but some false coloring)	


constant			kLB_MODE	 	= 8							// normally 8, only for debugging 5
constant			kHIDE_SELECTED 	= 1							// normally 1, only for debugging 0
constant			kBITSELECTED	= 0x01						// Igor-defined. The bit which controls the selection state of a listbox cell

// If columns are changed then  'xSize'   listbox 'widths'  also have to be adjusted
  constant		k_COLUMN_TITLE 	= -1							// Igor defined
  constant		kCOLM_ZERO = 0,   kCOLM_PR = 1,   kCOLM_BL = 2,   kCOLM_FR = 3,   kCOLM_SW = 4,   kCOLM_PON = 5
static  strconstant	lstCOLUMNLABELS	= "LSw;Pro;Blk;Frm;Sw;PoN;"		// the column titles in the LB text wave including and staritng with LinSweep

static constant		kLB_ADDY		= 18							// additional y pixel for window title, listbox column titles and 2 margins
static constant		kCLEAR = 0, 	kDRAW  = 1
static constant		kFIRST  = 0, 	kLAST    = 1

  strconstant	lstDISPMODE	= "single;stack;catenate;"					// popmenus need semicolon separators
	 constant   	kSINGLE = 1, 	kSTACKED  = 2,	kCATENATED = 3	// popmenus start with index 1

// The key modifiers
static strconstant	lstMOD		= "none 0;l mouse     1;   shift 2;lm shft       3;    alt   4;lm      alt 5;    sh alt 6;lm sh alt 7;         ctrl 8;lm      ctrl  9;    sh ctrl 10;lm sh ctrl 11;rm     AG  12;lm      AG 13;rm sh AGr14;lm sh AGr 15;r mouse 16; ??    17;rm shft    18;?? 19;?? 20;?? 21;?? 22;?? 23;rm ctrl 24;?? 25;rm sh ctrl 26;"
 constant		kMO_N=0,  kMO_LM=1,  kMO_S=2,  kMO_LMS=3,  kMO_A=4,  kMO_LMA=5,  kMO_SA=6,  kMO_LMSA=7,  kMO_C=8,  kMO_LMC=9,  kMO_SC=10,  kMO_LMSC=11,  kMO_AG=12,  kMO_LMAG=13,  kMO_SAG=14,  kMO_LMSAG=15
static constant		kMO_RM=16,  kMO_17=17,  kMO_RMS=18,  kMO_19=19,  kMO_20=20,  kMO_21=21,  kMO_22=22,  kMO_23=23,  kMO_RMC=24,  kMO_25=25,  kMO_RMSC=26

// Peculiarities
// Arrow Alt 		does not give the expected code  4  	(gives nothing)
// Arrow Shift Alt	does not give the expected code  6  	(gives nothing)
// Arrow Alt Gr		does not give the expected code 12  	(gives nothing)	(sometimes it works ??? )
// Left mouse AltGr	does not give the expected code 13  	(gives	5   )
// Right mouse Alt	does not give the expected code 20	(gives 	4   )


// The mapping  key modifiers -> states.  The Igor-defined fixed modifier number is index of items in a string list containing the  Eval-states (=tbl, avg, skip/view) as defined below.  Mouse=1 is ignored, Shift=2, Alt=4, Ctrl=8, AltGr=12
static strconstant	lstMOD2STATE	 = "4;4;4;4;2;2;2;2;1;1;1;1;3;3;3;3;"	// NoModif:red:4 ,    Alt:green:2 ,  Ctrl:1:blue ,   AltGr:cyan:3 
static strconstant	lstMOD2STATE1= "3;3;3;3;2;2;2;2;1;1;1;1;3;3;3;3;"	// NoModif:cyan:3 , Alt:green:2 ,  Ctrl:1:blue ,   AltGr:cyan:3 

// The states and colors. The mapping is done by assigning an arbitrary color number to any state. 'Auto' must be 0. The color numbers must correspond to  'wDSColors'
 strconstant	lstSTATUS    = "IgorAuto;tbl;avg;;fitfail;;;;skipped;;;;;;;;selected;;;;;;;;;;;;;;;;active;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;movie;"			  // the processing states as bit field 
	 constant		kST_TBL=1,  kST_AVG=2,  kST_FITFAIL=4,  kST_SKIP=8,  kST_SEL=16,  kST_ACTIV=32,  kST_MOVIE=64,  kST_MAX=128	  // numbering of states = selection of color is arbitrary (0 must be auto)	

	 constant		kSTDRAW_EVALUATED=1// the cell colors in Draw Results listbox ( 1 = blue,   2 = green,  3 = cyan,   4 = grey ) . This also the STATE but in this listbox only 1 state is recognised, so the value is arbitrary.


 strconstant	ksWAVG		= "wAvg" 					// ASSUMPTION: must be 4 chars !
 strconstant	ksWMOVAVG_	= "wMovAvg" 				


 strconstant	lstREM_ADD_	  = "No avg; rmov avg;Add avg;Strt movg;"
 constant		cAVG_NO = 0,   cAVG_REMOVE = 1,   cAVG_ADD = 2,   cAVG_ADD_START_MVG = 3

static constant		kTBL_ADD	 = 1

// The states and colors for the  'Result Select' listboxes for Draw, Print, ToFile
	constant		kRS_TOFILE		= 1		// save to file, display in table and print into history	1 = blue = CTRL,   2 = red = ALT,   3 = magenta = ALT CTRL,   4 = grey = no modifier
	constant		kRS_PRINT		= 1		// print into history window						1 = blue = CTRL,   2 = red = ALT,   3 = magenta = ALT CTRL,   4 = grey = no modifier
	constant		kRS_PRINTGRAPH	= 2		// print into textbox in graph					1 = blue = CTRL,   2 = red = ALT,   3 = magenta = ALT CTRL,   4 = grey = no modifier
	constant		kRS_DRAW		= 1		//										1 = blue = CTRL,   2 = red = ALT,   3 = magenta = ALT CTRL,   4 = grey = no modifier

// The amount of data extracted from the listbox
	constant		kLB_SELECT = 0,  kLB_ALL = 1

static constant		cDRAWPTS = 1000


Function		Grey( nState )
	variable	nState
	wave	wDSColors  =	root:uf:evo:lb:wDSColors
// 050927
//	return	( wDSColors[ nState ][ 0 ] + wDSColors[ nState ][ 0 ] + wDSColors[ nState ][ 2 ] ) / 3 / 256  	// ???
	return	( wDSColors[ nState ][ 0 ] + wDSColors[ nState ][ 1 ] + wDSColors[ nState ][ 2 ] ) / 3 / 256  	// ???
End


Function		EvalColors( wDSColors )
	wave   wDSColors
	wDSColors[ kST_TBL ][ 	kRED ]	= 	0;	wDSColors[ kST_TBL ][ 	kGREEN ]	= 	0;	wDSColors[ kST_TBL ][ 	kBLUE ]	= 65535;	//  1  blue	
	wDSColors[ kST_AVG ][ 	kRED ]	= 	0;	wDSColors[ kST_AVG ][ 	kGREEN ]	= 58000;	wDSColors[ kST_AVG ][ 	kBLUE ]	= 	0;	//  2  green
	wDSColors[ kST_FITFAIL][	kRED ]	= 65535;	wDSColors[ kST_FITFAIL][	kGREEN ]= 	0;	wDSColors[ kST_FITFAIL][	kBLUE ]	= 	0;	//  4  red
	variable	n
	for ( n = 0; n < 3; n += 1 )
		wDSColors[ 0			][ n ] = 232*256			//  0 : cannot change Igor's default color having the value 232*256 and the index 0. It is set here only for debug comparison of gray values...
		wDSColors[ kST_SKIP 	][ n ] = 136*256			// 16 dark grey
		wDSColors[ kST_SEL 	][ n ] = kbACTIVE_MAGENTA ? 65535   :  244*256		// 32 light grey
		wDSColors[ kST_ACTIV	][ n ] = 65535			// 64 white
	endfor
	if ( kbACTIVE_MAGENTA )
		wDSColors[ kST_ACTIV	][ kGREEN ] = 65535 - kMAGENTA	
	endif

	EvalColorMixing( wDSColors )
End

Function		EvalColorMixing( wDSColors )
	wave	wDSColors
	variable	st, n, nPow, nPowers, color, ColorValue
	string  	lstPowers
	for ( st = 1; st < kST_MAX / 2; st += 1 )			
		lstPowers	= ListPowers( st )
		nPowers	= ItemsInList( lstPowers )
		for ( color = 0; color < 3; color += 1 )
			ColorValue	= 0
			for ( n = 0; n < nPowers; n += 1 )
				nPow	= str2num( StringFromList( n, lstPowers ) )
				ColorValue += wDSColors[ 2^nPow ][ color ]			// wDSColors has 16 bit and is too small to hold the intermediate color sum directly 
			endfor
			wDSColors[ st ][ color ]  = ColorValue / nPowers
		endfor				
	endfor
	// Some color values are not suitable for linear addition / mixing:
	for ( color = 0; color < 3; color += 1 )
		wDSColors[ kST_ACTIV +	kST_SEL				][ color ]  = 65535
		wDSColors[ kST_ACTIV +	kST_SEL	+ kST_SKIP	][ color ]  = 65535
		wDSColors[ kST_ACTIV			+ kST_SKIP	][ color ]  = 65535
		wDSColors[ 			kST_SEL	+ kST_SKIP	][ color ]  = 188 * 256
	endfor
	if ( kbACTIVE_MAGENTA )
		wDSColors[ kST_ACTIV +	kST_SEL				][ kGREEN ]  = 65535 - kMAGENTA	
		wDSColors[ kST_ACTIV +	kST_SEL	+ kST_SKIP	][ kGREEN ]  = 65535 - kMAGENTA	
		wDSColors[ kST_ACTIV			+ kST_SKIP	][ kGREEN ]  = 65535 - kMAGENTA	
	endif
End			
//Function		EvalColorMixing( wDSColors )
//	wave	wDSColors
//	variable	st, n, nPow, nPowers, color, ColorValue
//	string  	lstPowers
//	for ( st = 1; st < 64; st += 1 )			// todo....64/128
//		lstPowers	= ListPowers( st )
//		nPowers	= ItemsInList( lstPowers )
//		for ( color = 0; color < 3; color += 1 )
//			ColorValue	= 0
//			for ( n = 0; n < nPowers; n += 1 )
//				nPow	= str2num( StringFromList( n, lstPowers ) )
//				ColorValue += wDSColors[ 2^nPow ][ color ]			// wDSColors has 16 bit and is too small to hold the intermediate color sum directly 
//			endfor
//			wDSColors[ st ][ color ]  = ColorValue / nPowers
//		endfor				
//	endfor
//	// Some color values are not suitable for linear addition / mixing:
//	for ( color = 0; color < 3; color += 1 )
//		wDSColors[ kST_ACTIV +	kST_SEL				][ color ]  = 65535
//		wDSColors[ kST_ACTIV +	kST_SEL	+ kST_SKIP	][ color ]  = 65535
//		wDSColors[ kST_ACTIV			+ kST_SKIP	][ color ]  = 65535
//		wDSColors[ 			kST_SEL	+ kST_SKIP	][ color ]  = 188 * 256
//	endfor
//	if ( kbACTIVE_MAGENTA )
//		wDSColors[ kST_ACTIV +	kST_SEL				][ kGREEN ]  = 65535 - kMAGENTA	
//		wDSColors[ kST_ACTIV +	kST_SEL	+ kST_SKIP	][ kGREEN ]  = 65535 - kMAGENTA	
//		wDSColors[ kST_ACTIV			+ kST_SKIP	][ kGREEN ]  = 65535 - kMAGENTA	
//	endif
//End			

Function	/S	States( nState, lstAllStates )
// Returns string containing the bits contained in 'nState' in an abbreviated but readable form
	variable	nState
	string  	lstAllStates
	string		lstStates	= ""
	variable	n, nMax=8   // very bad code, should be ItemsInList( lstAllStates )  which would also avoid  2^n
	for ( n = 0; n < nMax; n += 1 )
		if ( nState & 2^n )
			lstStates	+=  (StringFromList( 2^n, lstAllstates ) )[ 0, 3 ]  + "  "
		endif
	endfor
	return	lstStates
End
	


Function		DSDlg( xyOs, nWvKind )
	// Build the DataSectionsPanel
	variable	xyOs, nWvKind 
	variable	SctCnt	= DataSectionCnt_( nWvKind ) 
	variable	c, nCols	= ItemsInList( lstCOLUMNLABELS )

	// Possibly kill an old instance of the DataSectionsPanel and also kill the underlying waves
	string  	sDSPanelNm	= DSPanelNm_( nWvKind )

if ( WinType( sDSPanelNm ) == 7 )  // 2013-01-15  panel exists
	DoWindow  /K	$sDSPanelNm								// remove old panel  060511
endif

	KillWaves	  /Z	root:uf:evo:lb:wLBTxt , root:uf:evo:lb:wLBFlags, root:uf:evo:lb:wDSColors 	// 051108

	// Build the DataSectionsPanel . The y size of the listbox and of the panel  are adjusted to the number of data sections (up to maximum screen size) 
	variable	xPos	= 10
	if ( WinType( "de" ) == kPANEL ) 						// Retrieves the main evaluation panel's position from Igor	
		GetWindow     $"de" , wsize						// Only if the main evaluation panel exists retrieve its position from Igor..		
		xPos	= V_right * screenresolution / kIGOR_POINTS72 + 5	// ..and place the current panel just adjacent to the right
	endif
	xPos += xyOs
	variable	xSize		= 176 							// 176 for column widths 16 	    + 4 * 13 + 14	(=82?)  adjust when columns change
	variable	yPos		= 50 + xyOs
	variable	ySizeMax	= GetIgorAppPixelY() -  kY_MISSING_PIXEL_BOT - kY_MISSING_PIXEL_TOP - 85  // -85 leaves some space for the history window

// 051110c  060104 One-section-listbox
//	variable	ySizeNeed	= SctCnt * kLB_CELLY
	variable	ySizeNeed	= max( 2, SctCnt ) * kLB_CELLY			// the listbox can be created with 0 or 1 rows, but the minimum height (required for y scrollbar) is the height of a listbox with 2 rows		

	variable	ySize		= min( ySizeNeed , ySizeMax ) 
	NewPanel /W=( xPos, yPos, xPos + xSize + 4 , yPos + ySize + kLB_ADDY ) /K=1 as DSPanelTitle_( nWvKind )	// in pixel
	DoWindow  /C $sDSPanelNm
	PnLstPansNbsAdd( ksfEVO,  sDSPanelNm )

// 060511a  widening the panel will widen the listbox columns
	SetWindow  $sDSPanelNm,  hook( DsDlg ) = fDsDlgHook

	// Create the 2D LB text wave	( Rows = data sections, Columns = Both, Avg, Tbl )
	make   	/T 	/N = ( SctCnt, nCols )		root:uf:evo:lb:wLBTxt		// the LB text wave
	wave   	/T		wLBTxt		     =	root:uf:evo:lb:wLBTxt

	// Create the 3D LB flag wave. 	Rows x Columns (as above)  x 3  : last index 0 is flags, 1 is fore- or background color, 2 is the remaining color 
	make   /U	/B  /N = ( SctCnt, nCols, 3 )	root:uf:evo:lb:wLBFlags	// byte wave is sufficient for up to 254 colors 
	wave   			wLBFlags		    = 	root:uf:evo:lb:wLBFlags

	make /O	/W /U /N=(128,3) 	   root:uf:evo:lb:wDSColors 			// Creates	'root:uf:evo:lb:wDSColors' . This is the same for  'Org'  and  'Avg'	todo 64/128
	wave	wDSColors	 	= root:uf:evo:lb:wDSColors 		
	EvalColors( wDSColors )								// Sets 	'root:uf:evo:lb:wDSColors' . This is the same for  'Org'  and  'Avg'	

	// Link the  indices  of  Foreground  and  Background  colors  to  their name strings which are later used to access the layer where the color is to be set
	variable	planeFore	= 1
	variable	planeBack	= 2
	SetDimLabel 2, planeBack,  $"backColors"	wLBFlags
	SetDimLabel 2, planeFore,   $"foreColors"	wLBFlags


	// Set the column titles in the LB text wave, take the entries from the fixed string list. 
	for ( c = 0; c < nCols; c += 1 )
		SetDimLabel 1, c, $StringFromList( c, lstCOLUMNLABELS ), wLBTxt
	endfor

	// Fill the 	Avg+Tbl, Avg and Tbl listbox columns with data section numbers and/or 1-character-markers
	wLBTxt[ ][ kCOLM_ZERO ]	= num2str( p )								// set the initial text in 1 column of the LB = the row

	// Fill the 	Pr/Bl/Fr/Sw listbox columns with the protocol/block/frame/sweep numbers and colorise these cells according to their content
	SetListboxTxtAndColors( wLBTxt, wLBFlags )

	// Build the panel controls 
	ListBox 	  lbDataSections, 	win = $sDSPanelNm, 	pos = { 2, 0 },  size = { xSize, ySize + kLB_ADDY },  frame = 2
	ListBox	  lbDataSections,	win = $sDSPanelNm, 	listWave			= root:uf:evo:lb:wLBTxt
	ListBox 	  lbDataSections, 	win = $sDSPanelNm, 	selWave 			= root:uf:evo:lb:wLBFlags,  editStyle = 1
	ListBox	  lbDataSections, 	win = $sDSPanelNm, 	colorWave		= root:uf:evo:lb:wDSColors
	ListBox 	  lbDataSections, 	win = $sDSPanelNm, 	mode 			= kLB_MODE					// normally 8, for debugging 5	
	ListBox 	  lbDataSections, 	win = $sDSPanelNm, 	widths			= { 16, 13, 13, 13, 13, 14 }			// adjust when columns change
	ListBox 	  lbDataSections, 	win = $sDSPanelNm, 	proc 	 			= lbDataSectionsProc
	ListBox 	  lbDataSections, 	win = $sDSPanelNm, 	UserData( nWvKind ) = num2str( nWvKind )

	SetPrevRowInvalid() 
End


// 060511a  widening the panel will widen the listbox columns
Function 		fDsDlgHook( s )
// Detects and reacts on resizing the data sections panel
	struct	WMWinHookStruct &s 			
	if ( s.eventCode	!= kWHK_mousemoved )
		 printf "\t\t\tfDsDlgHook()\t\tEvntCode:%2d\t%s\tmod:%2d\t'%s'\t ", s.eventCode, pd( s.eventName, 8 ), s.eventMod, s.winName	// no CR here
	endif
	if ( s.eventCode	== kWHK_resize )
		variable	xWinWSize, xWinPixSize, yWinPixSize
		GetWindow $s.winName, wSize
		 xWinWSize	= V_right - V_left
		GetWindow $s.winName, wSizeDC
		xWinPixSize		=  V_right - V_left
		yWinPixSize		=  V_bottom - V_top
		 printf "\twidth( wSize):%4d\twidth( wSizeDC/pixel):%4d\theight:%4d\t ",  xWinWSize, xWinPixSize, yWinPixSize				// no CR here
		ListBox 	  lbDataSections, 	win = $s.winName, 	size = { xWinPixSize, yWinPixSize - kLB_ADDY }
		// ListBox 	  lbDataSections, 	win = $sDSPanelNm, 	widths	= { 16, 13, 13, 13, 13, 14 }								// one could additionally adjust different column widths...
	endif
	if ( s.eventCode	!= kWHK_mousemoved )
		 printf "\t\t \r"																						// the final CR (2 tabs for print elimination in Release)
	endif
End

//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//	THE  BIG  DATA SECTIONS  LISTBOX  ACTION  PROC

Function		lbDataSectionsProc( s ) : ListBoxControl
// Dispatches the various actions to be taken when the user clicks in the Listbox

// MOUSE and  MODIFIER  USAGE :
//	 for an explanation click the help button in the main evaluation panel which will open  the file  EvalHelp.txt
//	When clicking into a cell the corresponding data unit is only displayed.
// 	Double clicks do not work reliably as first there is an undesirable single click
// 	Shift Click on the header  is simply not recognised by Igor.

	struct	WMListboxAction &s

	variable	nWvKind		= str2num( GetUserData( s.win,  s.ctrlName, "nWvKind" ) )
	wave	wFlags		= s.selWave
	wave   /T	wTxt			= s.listWave
	nvar		gPrevRowFi 	= root:uf:evo:cfsr:gPrevRowFi
	nvar		gPrevRowLa 	= root:uf:evo:cfsr:gPrevRowLa
	nvar		gPrevColumn   	= root:uf:evo:cfsr:gPrevColumn
	nvar		gPrevRowCu   	= root:uf:evo:cfsr:gPrevRowCu

	variable	pl			= FindDimLabel( wFlags, 2, "BackColors" )
	variable	plFg			= FindDimLabel( wFlags, 2, "ForeColors" )
//	 printf "\rlbDataSectionsProc() "  ; print s
//	if ( s.col != gPrevColumn )
//		SetPrevRowInvalid() 
//	endif
	
	variable	nState	= kST_SEL
	 variable	nStatePrv	= State( wFlags, s.row, s.col, pl )					// Only for debug printing
	variable	dsPrvFirst, dsPrvLast, dsPrvCol								// first and last data section of the previous data unit
	variable	dsFirst, dsLast, dsSize									// first and last data section of the data unit we are currently in
	DSPrev( dsPrvFirst, dsPrvLast, dsPrvCol ) 								// passes back the first and last data section of the previous data unit
	DS2Lims( s.row, s.col, dsFirst, dsLast, dsSize ) 							// computes first and last data section of the data unit (=Prot, Block, Frame, Sweep) we are currently in
	string  	sCode	= pad( StringFromList(s.eventCode, lstLB_EVENTS),8)
	string  	sModif	= pad( StringFromList( s.eventMod, lstMod ), 10 )
	//string  	sColor	= pad(StringFromList( nStatePrv, lstSTATUS),6)
 
 	string		sTxt1	= "             "		
 	string		sTxt2	= "?            "		
 	string		sTxt3	= ""		


		variable	dsL, col, row, bSuccessfulFit
		variable	nAvgMode

	// ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' '
	// IN  THE COLUMN TITLES : 
	// We use the MouseDown event  so that the Cell drawing/updating code (which acts only on a single data unit)  below is not executed. We must do the drawing/updating of the entire column right here.
	// Commands acting on a data section column
	if ( s.row == k_COLUMN_TITLE )
	// if ( s.col >= kCOLM_PR  &&  s.col <= kCOLM_PON )		// skip the (1.) LinSwp column
		dsFirst	= 0
		dsLast	= DimSize( wFlags, 0 ) - 1	
		if (  s.eventCode == kLBE_mousedown   &&   s.eventMod == kMO_LM  )				//  1	left mouse
			sTxt1 = "lm dn      (hd)";	sTxt2 = "Col: Invert sel";	sTxt3 = ""					//  1 left mouse			Toggle the selection bit of all data sections of the entire column
			// gn DSToggle1( wFlags, dsFirst, dsLast, s.col, pl, kST_SEL )		// 
			DSInvertColumn( wFlags, s.col, pl, kST_SEL )
		
		elseif (   s.eventCode == kLBE_mousedown   &&   s.eventMod == kMO_LMS )			//  3 left mouse  + SHIFT   ???? does sometimes not work reliably ???
			sTxt1 = "lm dn  SH (hd)";	sTxt2 = "Col: Clear sel"; 	sTxt3 = ""
			// gn DSReset( wFlags, dsFirst, dsLast, s.col, pl, kST_SEL )		// 
			DSClearColumn( wFlags, s.col, pl, kST_SEL )								//					Set all data sections of the entire column to unselected state
	
		elseif (   s.eventCode == kLBE_mousedown   &&   s.eventMod == kMO_LMSC )			// 11 left mouse  + SHIFT + CTRL
			sTxt1 = "lm  C   SH (hd)";	sTxt2 = "Erase all avg"; sTxt3 = ""					//					Display this data unit , invert all from previous up to this and  keep the new states.
			DSClearColumn( wFlags, s.col, pl, kST_AVG )								//					Set all data sections of the entire column to unaveraged state

		elseif (   s.eventCode == kLBE_mousedown  &&  s.eventMod == kMO_LMSAG )			// 15 left mouse  +  SHIFT + ALT GR
			sTxt1 = "lm AG  SH (hd)";	sTxt2 = "Col: CLEAR ALL";	sTxt3 = "for Debug"
			// gn DSReset( wFlags, dsFirst, dsLast, s.col, pl, kST_AVG |  kST_TBL |  kST_SKIP |  kST_FITFAIL |  kST_SEL |  kST_ACTIV )		// 
			DSClearColumn( wFlags, s.col, pl, kST_AVG |  kST_TBL |  kST_SKIP |  kST_FITFAIL |  kST_SEL |  kST_ACTIV )	// Resets all data sections of the entire column to virgin state (for debug)
			DSDrawSelectedCells( FALSE, wFlags, wTxt, dsFirst, dsLast, s.col, pl, plFg, kST_ACTIV )				// provide feedback to the user that cells in this range have just been deselected 

			ResetDataBoundsX()				// Reset the X axis bounds which (only the  'kCATENATED' ) display mode would otherwise remember

			DSClearTraces( wFlags, s.col, pl )	// Cursors, fits and evaluated data points still remain

		endif

// 060219
		// Open a context menu on a right mouse click.....
		if (  s.eventCode == kLBE_mousedown   &&   s.eventMod == kMO_RM )   		// right mouse  (mouseUp does not work in this context)
	
			printf "\tfHookResults()\t%s\tmX:%4d\tcol: %4d  \tmY:%4d\tROW: %4d  \tE:%2d\t%s   \tMod:%4d\t \r", s.win, s.mouseLoc.h, col, s.mouseLoc.v, row, s.eventCode, pd( StringFromList( s.eventCode, lstLB_EVENTS ), 8 ),  s.eventMod

			if ( row == 0 )					// Clicked into the column header 
				PopupContextualMenu/C=( s.mouseLoc.h, s.mouseLoc.v ) "Count selected and set Avg;---;"
		
				strswitch( S_selection )
		
					case "Count selected and set Avg" :
						variable nCountSel	= 0
						dsFirst	= 0
						dsLast 	= DimSize( wFlags , 0 ) - 1										// the last data section of the entire experiment
						row		= 0
						do
							DS2Lims( row, s.col, dsFirst, dsL, dsSize ) 								// computes first and last data section of the current data unit e.g.  Frame or Block
							nState 	= State( wFlags, row, s.col, pl )
							if ( nState & kST_SEL )
								// print  row, s.col, nStatePrv, "->", nState
								nCountSel	+= 1
							endif
							row += dsSize
						while ( dsL < dsLast ) 		
						// Update the Setvariable field with the number of _SELECTED_  data units. Setting the underlying global variable automatically updates the SetVariable control.
						nvar	svMovAvg	= $"root:uf:evo:de:svMovAvg0000"	
						svMovAvg		= nCountSel
						// printf "\t\tCountSelected() \tSetting moving avg to %d \r", nCountSel
						break;

					case "---" :
						break;

				endswitch
				return	1				// 0 : allow Igor to do further processing (will open Igor's context menu) 
			endif
		endif

	endif
// ... 060219


	// IN  THE LISTBOX
	// Commands acting on the active current data unit									
	if ( s.row > k_COLUMN_TITLE )
		if (  s.eventCode == kLBE_CellSelect   &&   s.eventMod == kMO_N  ) 					//  0 arrow key
			sTxt1	= "ar";		sTxt2 = "Display";	sTxt3 = ""						// 						Just display this data unit.  Do not change any selection. Do no analysis.
			nState	= nStatePrv | kST_ACTIV
			// If this cell has never before been visited we mark it as 'skipped' as long as the used does neither an average nor an analysis
			if ( ! ( nState &  kST_AVG )  && ! ( nState &  kST_TBL ) && ! ( nState &  kST_FITFAIL ) && ! ( nState &  kST_SKIP ) ) 
				nState	= nState | kST_SKIP
			endif
			//DSJumpToBegOrEndOfDataUnit( wFlags, s.row, s.col, pl, kST_VIRGIN, kST_ACTIV )
			DSDisplayAndAnalyse( wFlags, dsFirst, dsLast, s.col, pl, nStatePrv, nState, cAVG_NO, 0, nWvKind )	
			DSUpdateListBox( wFlags, wTxt, dsFirst, dsLast, dsPrvFirst, dsPrvLast, dsPrvCol, s.row, s.col, pl, plFg, nState )
			
		elseif (  s.eventCode == kLBE_CellSelect   &&   s.eventMod == kMO_LM  )				//  1	left mouse
			sTxt1 = "lm";			sTxt2 = "Display";	sTxt3 = "StoreLims"				// 						Just display this data unit.  Do not change any selection. Do no analysis.
			nState	= nStatePrv | kST_ACTIV
			// If this cell has never before been visited we mark it as 'skipped' as long as the used does neither an average nor an analysis
			if ( ! ( nState &  kST_AVG )  && ! ( nState &  kST_TBL ) && ! ( nState &  kST_FITFAIL ) && ! ( nState &  kST_SKIP ) ) 
				nState	= nState | kST_SKIP
			endif
			DSDisplayAndAnalyse( wFlags, dsFirst, dsLast, s.col, pl, nStatePrv, nState, cAVG_NO, 0, nWvKind )	
			DSUpdateListBox( wFlags, wTxt, dsFirst, dsLast, dsPrvFirst, dsPrvLast, dsPrvCol, s.row, s.col, pl, plFg, nState )
			//DSStoreLims( s.row, s.col ) 											// 						Computes and stores first and last data section of the data unit (=Prot, Block, Frame, Sweep) we are currently in so that a range may be defined in the next action (usually by Shift Clicking)
			
		elseif (  s.eventCode == kLBE_CellSelect  	&&  s.eventMod == kMO_RM  )				// 16 Right mouse  
			sTxt1 = "rm       "; 		sTxt2 = "";			sTxt3 = "Average act"			//						Average the currenly active data unit
			// Mark this cell as averaged and possibly remove the 'skipped' state
			nState	= ( nStatePrv | kST_ACTIV | kST_AVG ) & ~kST_SKIP 
			DSDisplayAndAnalyse( wFlags, dsFirst, dsLast, s.col, pl, nStatePrv, nState, cAVG_ADD, 0, nWvKind )	
			DSUpdateListBox( wFlags, wTxt, dsFirst, dsLast, dsPrvFirst, dsPrvLast, dsPrvCol, s.row, s.col, pl, plFg, nState )
		
		elseif (  s.eventCode == kLBE_CellSelect  	&&  s.eventMod == kMO_RMC  )				// 24 Right mouse  + CTRL
			sTxt1 = "rm  C     ";		sTxt2 = "Analysis act";sTxt3 = ""						//						Analyse the currenly active data unit
			// Mark this cell as analysed and possibly remove the 'skipped' state
// 051011
// Version 1a : a virgin trace will  (directly after analysis)  be  kST_TBL = blue (independent of the success of the fit) . A trace whose fit has failed before (=red) will be magenta.
			nState		= ( nStatePrv  | kST_ACTIV | kST_TBL 			 ) & ~kST_SKIP							// temporarily add   kST_TBL  to the state. This state will perhaps have to be removed again below if the fit failed 
			bSuccessfulFit	= DSDisplayAndAnalyse( wFlags, dsFirst, dsLast, s.col, pl, nStatePrv, nState, cAVG_NO, kTBL_ADD, nWvKind)		
			nState = bSuccessfulFit  ?   nState  :  ( nState |  kST_FITFAIL )  & ~kST_TBL 								//  Remove again the kST_TBL (=analysis OK state) and add the  kST_FITFAIL state if the fit failed 
// Version 1b : a virgin trace will  (directly after analysis)  be  kST_TBL = blue (independent of the success of the fit) . A trace whose fit has failed before (=red) will be magenta. An OK-traces (=blue) will stay blue. 
//			nState		= ( nStatePrv  | kST_ACTIV 			 ) & ~kST_SKIP									// temporarily add   kST_TBL  to the state. This state will perhaps have to be removed again below if the fit failed 
//			bSuccessfulFit	= DSDisplayAndAnalyse( wFlags, dsFirst, dsLast, s.col, pl, nStatePrv, nState |kST_TBL, cAVG_NO, kTBL_ADD, nWvKind )	
//			nState = bSuccessfulFit  ?  ( nState  | kST_TBL )  & ~kST_FITFAIL  :  ( nState |  kST_FITFAIL )  & ~kST_TBL 		//  Remove again the kST_TBL (=analysis OK state) and add the  kST_FITFAIL state if the fit failed 
// Version 2 : the trace will  (directly after analysis)  be  kST_TBL  |  kST_FITFAIL  = magenta   independent of the success of the fit and independent of a previous success of the fit (= red or blue)
//			nState		= ( nStatePrv  | kST_ACTIV | kST_TBL | kST_FITFAIL ) & ~kST_SKIP							// temporarily add   kST_TBL   AND   kST_FITFAIL  to the state. These are mutually exclusive states so one of them must be removed again below
//			bSuccessfulFit	= DSDisplayAndAnalyse( wFlags, dsFirst, dsLast, s.col, pl, nStatePrv, nState, cAVG_NO, kTBL_ADD, nWvKind )		
//			nState = bSuccessfulFit  ?  nState & ~kST_FITFAIL  :  nState & ~kST_TBL 									//  Remove  one of the mutually exclusive states  kST_TBL   /   kST_FITFAIL

			// printf "\t\tlbDataSectionsProc( g ) \tSuccessful Fit:%2d \tds: %3d\t ...%3d, nStatePrv:%3d  \t-> \tnState: %3d \r", bSuccessfulFit, dsFirst, dsLast, nStatePrv, nState
			DSUpdateListBox( wFlags, wTxt, dsFirst, dsLast, dsPrvFirst, dsPrvLast, dsPrvCol, s.row, s.col, pl, plFg, nState )
																															
		elseif (  s.eventCode == kLBE_CellSelect  	&&  s.eventMod == kMO_AG )				// 12 Right mouse or ARROW   +  ALT GR  
			sTxt1 = "rm/ar AG";		sTxt2 = "Analysis act";sTxt3 = "Average act"
			// Mark this cell as analysed and averaged and possibly remove the 'skipped' state
// 051011
// Version 1a : a virgin trace will  (directly after analysis)  be  kST_TBL = blue (independent of the success of the fit) . A trace whose fit has failed before (=red) will be magenta.
			nState		= ( nStatePrv  | kST_ACTIV | kST_TBL | kST_AVG 	 ) & ~kST_SKIP							// temporarily add   kST_TBL  to the state. This state will perhaps have to be removed again below if the fit failed 
			bSuccessfulFit	= DSDisplayAndAnalyse( wFlags, dsFirst, dsLast, s.col, pl, nStatePrv, nState, cAVG_ADD, kTBL_ADD, nWvKind )			
			nState = bSuccessfulFit  ?   nState  :  ( nState |  kST_FITFAIL )  & ~kST_TBL 								//  Remove again the kST_TBL (=analysis OK state) and add the  kST_FITFAIL state if the fit failed 
			DSDisplayAndAnalyse( wFlags, dsFirst, dsLast, s.col, pl, nStatePrv, nState, cAVG_ADD, kTBL_ADD, nWvKind )	
			DSUpdateListBox( wFlags, wTxt, dsFirst, dsLast, dsPrvFirst, dsPrvLast, dsPrvCol, s.row, s.col, pl, plFg, nState )
	
		elseif (   s.eventCode == kLBE_CellSelect       &&   s.eventMod == kMO_LMA )			//  5 left mouse  + ALT
			sTxt1 = "lm     A     ";		sTxt2 = "Remove";	sTxt3 = "Average act"			//						 Possibly remove the 'averaged' state
			nState	=  ( nStatePrv | kST_ACTIV ) & ~kST_AVG				 			// After possibly removing  the 'averaged' state there may be the analysed state left:

//			DSDisplayAndAnalyse( wFlags, dsFirst, dsLast, s.col, pl, nStatePrv, nState, cAVG_REMOVE, 0, nWvKind )	
//			if ( nState & kST_TBL  ||  nState & kST_FITFAIL )  							// If this cell has been analysed earlier...
//				nState	=   nState & ~kST_SKIP									// ...we must remove the 'skipped' flag..
//			else																// ..if not
//				nState	=   nState |   kST_SKIP									// ...we must set the 'skipped' flag..
//			endif
			if  ( ! ( nState & kST_TBL  ||  nState & kST_FITFAIL ) )   						// If this cell has not been analysed earlier...
				nState	=   nState |   kST_SKIP									// ...we must set the 'skipped' flag..
			endif
			DSDisplayAndAnalyse( wFlags, dsFirst, dsLast, s.col, pl, nStatePrv, nState, cAVG_REMOVE, 0, nWvKind )	
			DSUpdateListBox( wFlags, wTxt, dsFirst, dsLast, dsPrvFirst, dsPrvLast, dsPrvCol, s.row, s.col, pl, plFg, nState )
	
		elseif (   s.eventCode == kLBE_CellSelect    &&  s.eventMod == kMO_C )				//  8 arrow key   + CTRL
			sTxt1 = "ar   C";			sTxt2 = "Invert Data Unit";	sTxt3 = "error";				//						Display this data unit , invert  it's state  and  keep the new state.
	// 050909 todo inverts uneven numbers of data sections, keeps even numbers 
			nState	= nStatePrv & kST_SEL  ? 	nStatePrv & ~kST_SEL  :  nStatePrv | kST_SEL	// invert the 'selected' bit
			DSToggleDataUnitAndStore( wFlags, s.row, s.col, pl, kST_SEL )
			// s.Row = DSToggleDataUnitAndStore( wFlags, s.row, s.col, pl, kST_SEL )		// 050911 gn
			DSDisplayAndAnalyse( wFlags, dsFirst, dsLast, s.col, pl, nStatePrv, nState, cAVG_NO, 0, nWvKind )	
			DSUpdateListBox( wFlags, wTxt, dsFirst, dsLast, dsPrvFirst, dsPrvLast, dsPrvCol, s.row, s.col, pl, plFg, nState )
	
		elseif (   s.eventCode == kLBE_CellSelect    &&  s.eventMod == kMO_LMC )				//  9 left mouse  + CTRL
			sTxt1 = "lm  C";			sTxt2 = "Inv   DS or DU";	sTxt3 = "Store";				//						Display this data unit , invert  it's state  and  keep the new state.
			nState	= nStatePrv & kST_SEL  ?  nStatePrv & ~kST_SEL  :  nStatePrv | kST_SEL	// invert the 'selected' bit, but do NOT set to 'active' . Setting 'active' could work for 1 data unit but would make no sense if a selection range is set or inverted.
			// 050915 Design issue: Setting or inverting a selection should  NOT set to active. This would work for 1 data unit but not if a selection range is set or inverted. 
			//nState	= nStatePrv & kST_SEL  ?  (nStatePrv|kST_ACTIV) & ~kST_SEL  :  (nStatePrv|kST_ACTIV)  | kST_SEL	// invert the 'selected' bit and set to active

	//		DSToggleAndStore( wFlags, s.row, s.col, pl, kST_VIRGIN, kST_SEL )
			DSDisplayAndAnalyse( wFlags, dsFirst, dsLast, s.col, pl, nStatePrv, nState, cAVG_NO, 0, nWvKind )	
			DSUpdateListBox( wFlags, wTxt, dsFirst, dsLast, dsPrvFirst, dsPrvLast, dsPrvCol, s.row, s.col, pl, plFg, nState )


			
		elseif (   s.eventCode == kLBE_CellSelectShift   &&   s.eventMod == kMO_SC )			// 10 arrow key  + SHIFT + CTRL
			sTxt1 = "ar   C      SH";	sTxt2 = "Inv Sel up to DS";	sTxt3 = "todo"
			nState	= nStatePrv | kST_SEL;
	//		DSToggle( wFlags, s.row, s.row, s.col, pl, kST_VIRGIN, kST_SEL )				
			DSUpdateListBox( wFlags, wTxt, dsFirst, dsLast, dsPrvFirst, dsPrvLast, dsPrvCol, s.row, s.col, pl, plFg, nState )
	
		elseif (   s.eventCode == kLBE_CellSelectShift   &&   s.eventMod == kMO_LMSC )			// 11 left mouse  + SHIFT + CTRL
			sTxt1 = "lm  C      SH";	sTxt2 = "Inv Sel up to DS"; sTxt3 = "todo"				//						Display this data unit , invert all from previous up to this and  keep the new states.
			nState	= nStatePrv;
	// 050909 perhaps drawing/updating below is unnecessary   and should / must? be prevented     ????  perhaps  a  _bDoDraw'  variable should be passed to the drawing/updating below
			DSToggleDataRangeAndStore( wFlags, s.row, s.col, pl, kST_SEL )
			DSUpdateListBox( wFlags, wTxt, dsFirst, dsLast, dsPrvFirst, dsPrvLast, dsPrvCol, s.row, s.col, pl, plFg, nState )
	
		elseif (   s.eventCode == kLBE_CellSelectShift   &&   s.eventMod == kMO_S )				//  2 arrow key  + SHIFT
			sTxt1 = "ar           SH";	sTxt2 = "Set selection";	sTxt3 = ""					//						Set  the 'selected' bit
			nState	= nStatePrv | kST_SEL;										// 						set the 'selected' bit
			DSUpdateListBox( wFlags, wTxt, dsFirst, dsLast, dsPrvFirst, dsPrvLast, dsPrvCol, s.row, s.col, pl, plFg, nState )
	
		elseif (   s.eventCode == kLBE_CellSelectShift   &&   s.eventMod == kMO_LMS )			//  3 left mouse  + SHIFT
			sTxt1 = "lm           SH";	sTxt2 = "Set selection";	sTxt3 = ""					//						Set  the 'selected' bit
			nState	= nStatePrv | kST_SEL;										// 						set the 'selected' bit
			DSUpdateListBox( wFlags, wTxt, dsFirst, dsLast, dsPrvFirst, dsPrvLast, dsPrvCol, s.row, s.col, pl, plFg, nState )

	
		// Commands acting on all selected data units
		elseif (  s.eventCode == kLBE_CellSelectShift  &&  s.eventMod == kMO_RMSC )			// 26 Right mouse  +  SHIFT + CTRL
			sTxt1 = "rm  C    SH"; 	sTxt2 = "Analysis all";	sTxt3 = ""
			dsFirst	= 0
			dsLast 	= DimSize( wFlags , 0 ) - 1										// the last data section of the entire experiment
			row		= 0
			do
				DS2Lims( row, s.col, dsFirst, dsL, dsSize ) 								// computes first and last data section of the current data unit e.g.  Frame or Block
				nStatePrv 	= State( wFlags, row, s.col, pl )
// 051011
// Version 1a : a virgin trace will  (directly after analysis)  be  kST_TBL = blue (independent of the success of the fit) . A trace whose fit has failed before (=red) will be magenta.
				nState	= ( nStatePrv | kST_TBL ) & ~kST_SKIP
				if ( nState & kST_SEL )
					// print  row, s.col, nStatePrv, "->", nState
					bSuccessfulFit	= DSDisplayAndAnalyse( wFlags, dsFirst, dsL, s.col, pl, nStatePrv, nState, cAVG_NO, kTBL_ADD, nWvKind )	
					nState = bSuccessfulFit ?  nState  :  ( nState |  kST_FITFAIL )  & ~kST_TBL //  Remove again the kST_TBL (=analysis OK state) and add the  kST_FITFAIL state if the fit failed 
					DSSet( wFlags, dsFirst, dsL, s.col, pl, nState )
				endif
				row += dsSize
			while ( dsL < dsLast ) 		

		elseif (  s.eventCode == kLBE_CellSelectShift  &&  s.eventMod == kMO_RMS )			// 18 Right mouse  + SHIFT
			sTxt1 = "rm        SH"; 	sTxt2 = "";			sTxt3 = "Average all"				// 						Average all selected data units
			dsFirst	= 0
			dsLast 	= DimSize( wFlags , 0 ) - 1										// the last data section of the entire experiment
			row		= 0
			nAvgMode = cAVG_ADD_START_MVG									// Pass this only once with the first trace to be averaged. This will initialise the 'Moving Avg' data structures. 	
			do	
				DS2Lims( row, s.col, dsFirst, dsL, dsSize ) 								// computes first and last data section of the current data unit e.g.  Frame or Block
				nStatePrv 	= State( wFlags, row, s.col, pl )
				nState	= ( nStatePrv | kST_AVG ) & ~kST_SKIP
				if ( nState & kST_SEL )
					// print  row, s.col, nStatePrv, "->", nState
					DSDisplayAndAnalyse( wFlags, dsFirst, dsL, s.col, pl, nStatePrv, nState, nAvgMode, 0, nWvKind )	
					DSSet( wFlags, dsFirst, dsL, s.col, pl, nState )
					nAvgMode	= cAVG_ADD									// Pass this after the first trace has been averaged to prevent initialisation of the 'Moving Avg' data structures.
				endif
				row += dsSize
			while ( dsL < dsLast ) 		

			// The moving averages have all been collected: Allow the user to do further processing by opening the 'Moving Average Data sections listbox' 
			 AvgDSDlg( 20, kWV_AVG_ )							// Build the  Moving Average  Data sections selection listbox
//			for ( ch = 0; ch < nChannels; ch += 1 )
//				wave  /Z  	wCatMovAvg	= FoMovAvgWvNm_( ch )
//				if ( waveExists( wCatMovAvg ) )
//				endif
//			endfor
//



	
		elseif (  s.eventCode == kLBE_CellSelectShift  &&  s.eventMod == kMO_SAG )			// 14 Right mouse or ARROW +  SHIFT + ALT GR	!!! 1. ambiguous and 2. (in addition) also unreliable 
			sTxt1 = "rm/ar AG SH"; 	sTxt2 = "Analysis all";	sTxt3 = "Average all"
			dsFirst	= 0
			dsLast 	= DimSize( wFlags , 0 ) - 1										// the last data section of the entire experiment
			row		= 0
			nAvgMode = cAVG_ADD_START_MVG									// Pass this only once with the first trace to be averaged. This will initialise the 'Moving Avg' data structures. 	
			do
				DS2Lims( row, s.col, dsFirst, dsL, dsSize ) 								// computes first and last data section of the current data unit e.g.  Frame or Block
				nStatePrv 	= State( wFlags, row, s.col, pl )
// 051011
// Version 1a : a virgin trace will  (directly after analysis)  be  kST_TBL = blue (independent of the success of the fit) . A trace whose fit has failed before (=red) will be magenta.
				nState	= ( nStatePrv | kST_TBL | kST_AVG ) & ~kST_SKIP
				if ( nState & kST_SEL )
					// print  row, s.col, nStatePrv, "->", nState
					bSuccessfulFit	= DSDisplayAndAnalyse( wFlags, dsFirst, dsL, s.col, pl, nStatePrv, nState, nAvgMode, kTBL_ADD, nWvKind )	
					nState 		= bSuccessfulFit  ?   nState  :  ( nState |  kST_FITFAIL )  & ~kST_TBL 				//  Remove again the kST_TBL (=analysis OK state) and add the  kST_FITFAIL state if the fit failed 
					DSSet( wFlags, dsFirst, dsL, s.col, pl, nState )
					nAvgMode	= cAVG_ADD									// Pass this after the first trace has been averaged to prevent initialisation of the 'Moving Avg' data structures.
				endif
				row += dsSize
			while ( dsL < dsLast ) 		

			// The moving averages have all been collected: Allow the user to do further processing by opening the 'Moving Average Data sections listbox' 
			 AvgDSDlg( 20, kWV_AVG_ )							// Build the  Moving Average  Data sections selection listbox
	
	
// 060705 MakeMovie	
		elseif (   s.eventCode == kLBE_CellSelectShift  &&  s.eventMod == kMO_LMSAG )			// 15 left mouse  +  SHIFT + ALT GR
			sTxt1 = "lm AG  SH";		sTxt2 = "";			sTxt3 = "MakeMovie"			//							MakeMovie
			dsFirst	= 0
			dsLast 	= DimSize( wFlags , 0 ) - 1										// the last data section of the entire experiment
			row		= 0

			// Unfortunately we cannot do the call to  'NewMovie'  right here  (symmetrical to 'MovieClose_')  as the graph has not yet but must been constructed before 'NewMovie' can be called.
			do
				DS2Lims( row, s.col, dsFirst, dsL, dsSize ) 								// computes first and last data section of the current data unit e.g.  Frame or Block
				nStatePrv 	= State( wFlags, row, s.col, pl )
				nState	= nStatePrv 
				if ( nState & kST_SEL )
// 060713
					DSDisplayAndAnalyse( wFlags, dsFirst, dsL, s.col, pl, kST_MOVIE, kST_MOVIE, cAVG_NO, kTBL_ADD, nWvKind )	
//					DSDisplayAndAnalyse( wFlags, dsFirst, dsL, s.col, pl, kST_MOVIE, kST_MOVIE, cAVG_NO, 0, nWvKind )	
				endif
				row += dsSize
			while ( dsL < dsLast ) 		

			// Unfortunately  'MovieClose_' cannot be placed  inside 'DSDisplayAndAnalyse()' as there the required information if we are in/after the last data unit is missing.
			MovieClose_()
	
		// Unused
	
		elseif (   s.eventCode == kLBE_CellSelect    &&  s.eventMod == kMO_LMAG )			// 13 left mouse  + ALT GR
			sTxt1 = "lm AG";		sTxt2 = "";			sTxt3 = "Unused"
			nState	= nStatePrv;
	
		elseif (   s.eventCode == kLBE_CellSelectShift   &&   s.eventMod == kMO_LMSA )			//  7 left mouse  + SHIFT  ALT		do not use: SHIFT ALT  switches character set
			sTxt1 = "lm     A    SH";	sTxt2 = "Do not use";	sTxt3 = "bad... "
			nState	= nStatePrv;
	
		else
			sTxt1 = ""; 			sTxt2 = "?";		sTxt3 = ""
		endif
	endif
  
  	// Enabling the following line will reveal any event, not only the 'kLBE_CellSelect'  and  'kLBE_CellSelectShift' event which we are normally interested in.....
	// printf "\tLB2\t%s\t%s\t%s\te:%2d %s\tmod:%2d %s\tPRV R:%2d\t..%2d\t..%2d\t  C:%2d   st:%2d\t-> CURR R:%2d\t..%2d\t..%2d\t C:%2d  st:%2d\tW:%s\tnwk:%d\t  \r", pad(sTxt1, 12), pad(sTxt2,12), pad(sTxt3,12), s.eventCode, sCode, s.eventMod, sModif, gPrevRowFi, gPrevRowCu, gPrevRowLa, gPrevColumn, nStatePrv, dsFirst, s.row, dsLast, s.col, nState, s.win, nWvKind

//	gPrevRowCu	= IsSelected( wFlags, s.col )
	// printf "\t -->LB2\tState:%2d\t%s\tprevR:%2d\t..%2d\t..%2d\t  \r", nState, pad(StringFromList(nState, lstSTATUS),6), gPrevRowFi, gPrevRowCu, gPrevRowLa
	return 0			// other return values reserved
End

//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

	  Function		DSSet5( wFlags, dsF, dsL, col, pl, nState )
// Set color = state  in listbox .  Mainly for listbox mode 5 : Igor will manage the cell selection and will display the selected cell in black. This will hide the previous cell state which is often undesirable. 
// Further refinements possible:  states may draw  text in the cells  or may change the  text (=foreground color) .
	wave	wFlags
	variable	dsF, dsL, col, pl, nState
	variable	ds
	for ( ds = dsF; ds <= dsL; ds += 1 )
		wFlags[ ds ][ col ][ pl ]	= nState
	endfor
	return	nState				
End			

static	  Function		DSSet( wFlags, dsF, dsL, col, pl, nState )
// Set color = state  in listbox . Mainly for listbox mode 8 : We will clear Igor's cell selection so that the selected cell is not overdrawn in  black. 
// Further refinements possible:  states may draw  text in the cells  or may change the  text (=foreground color, plFg) .
	wave	wFlags
	variable	dsF, dsL, col, pl, nState
	variable	ds
	for ( ds = dsF; ds <= dsL; ds += 1 )
		wFlags[ ds ][ col ][ pl ]	= nState	
if ( kHIDE_SELECTED )							// Bit 0x01 means cell is selected.  We turn off bit 0 so that  Igor will not display cell in 'selected' (=black) state except for a short flash. 
		wFlags[ ds ][ col ][ 0 ] = ( wFlags & ~kBITSELECTED )		// Cosmetics :Unselect the cell. ++ User sees the actual state instead of the black cell.   -- 1 it is now our resonsability to correctly display the state of the cell. 2.arrow keys will erroneously jump to column 0
endif
	endfor
	return	nState				
End			


static	  Function		DSReset( wFlags, dsF, dsL, col, pl, nState )
// Resets  the  'nState'  bit in column 'col'
	wave	wFlags
	variable	dsF, dsL, col, pl, nState
	variable	ds
	for ( ds = dsF; ds <= dsL; ds += 1 )
		wFlags[ ds ][ col ][ pl ]	= wFlags & ~nState 			// clear  the  'nState' bit 
	endfor
End			




static Function	Modifier2State( nModifier, lstStates )
	// Convert  the modifying key ( 'Ctrl'  or  'Ctrl Alt / Alt Gr'  )  to a state  (e.g. Avg, Tbl, View/Skip). 
	//  'Alt' + arrowkeys  is used by Igor,  'Alt' + mouse can be used freely.   'Shift' is used for selecting a range .  Will not work correctly with right mouse !!!
	variable	nModifier
	string  	lstStates
	return str2num( StringFromList( nModifier, lstStates ) )	
End


	 Function	 DSPrev( dsPrvFirst, dsPrvLast, dsPrvCol ) 
	// passes back the first and last data section of the previous data unit
	variable	&dsPrvFirst, &dsPrvLast, &dsPrvCol
	nvar		gPrevRowFi 	= root:uf:evo:cfsr:gPrevRowFi
	nvar		gPrevRowLa 	= root:uf:evo:cfsr:gPrevRowLa
	nvar		gPrevColumn   	= root:uf:evo:cfsr:gPrevColumn
	dsPrvFirst	= gPrevRowFi
	dsPrvLast	= gPrevRowLa
	dsPrvCol	= gPrevColumn
End

	 Function	 DSSetPrevious( dsFirst, dsLast, row, col )
	variable	dsFirst, dsLast, row, col 
	nvar		gPrevRowFi 	= root:uf:evo:cfsr:gPrevRowFi
	nvar		gPrevRowLa 	= root:uf:evo:cfsr:gPrevRowLa
	nvar		gPrevRowCu   	= root:uf:evo:cfsr:gPrevRowCu
	nvar		gPrevColumn   	= root:uf:evo:cfsr:gPrevColumn
	gPrevRowFi	= dsFirst
	gPrevRowLa	= dsLast
	gPrevRowCu	= row
	gPrevColumn	= col
End
	
static Function	PrevRowIsValid() 
	nvar		gPrevRowFi 	= root:uf:evo:cfsr:gPrevRowFi
	nvar		gPrevRowLa 	= root:uf:evo:cfsr:gPrevRowLa
	return	gPrevRowFi >= 0  &&  gPrevRowLa >= 0 	
End

static Function	SetPrevRowInvalid() 
	nvar		gPrevRowFi 	= root:uf:evo:cfsr:gPrevRowFi
	nvar		gPrevRowLa 	= root:uf:evo:cfsr:gPrevRowLa
	gPrevRowFi	= -1
	gPrevRowLa	= -1 	
End



static Function	DSUpdateListBox( wFlags, wTxt, dsF, dsL, dsPrvFirst, dsPrvLast, dsPrvCol, row, col, pl, plFg, nState )
	wave	wFlags
	wave  /T	wTxt
	variable	dsF, dsL, dsPrvFirst, dsPrvLast, dsPrvCol, row, col, pl, plFg, nState
	DSSet( wFlags, dsF, dsL, col, pl, nState )
	DSDrawSelectedCells( FALSE, wFlags, wTxt, dsPrvFirst, dsPrvLast, dsPrvCol, pl, 	plFg, kST_ACTIV )	// provide feedback to the user that cells in this range have just been deselected 
	DSDrawSelectedCells( TRUE,  wFlags, wTxt, dsF,		dsL,		col,	  pl, 	plFg, kST_ACTIV )	// provide feedback to the user that cells in this range have just been 	selected 
  	 // printf "\tLB1\t%s\t%s\t%s\te:%2d %s\tmod:%2d %s\tPRV R:%2d\t..%2d\t..%2d\t  C:%2d   st:%2d\t-> CURR R:%2d\t..%2d\t..%2d\t C:%2d  st:%2d\t  \r", pad(sTxt1, 12), pad(sTxt2,12), pad(sTxt3,12), s.eventCode, sCode, s.eventMod, sModif, gPrevRowFi, gPrevRowCu, gPrevRowLa, gPrevColumn, nStatePrv, dsFirst, s.row, dsLast, s.col, nState
	DSSetPrevious( dsF, dsL, row, col )												// store the current row/col as it is possibly required in the next call  when a range is spanned (e.g. LM shift Ctrl) 
End

static	  Function		DSToggle( wFlags, dsF, dsL, col, pl, nState1, nState2 )
	wave	wFlags
	variable	dsF, dsL, col, pl, nState1, nState2				// kBITSELECTED Bit 0x01 means cell is selected.  We turn off bit 0 so that  Igor will not display cell in 'selected' (=black) state except for a short flash. 
	variable	ds
	for ( ds = dsF; ds <= dsL; ds += 1 )
		 wFlags[ ds ][ col ][ 0 ] = ( wFlags & ~kBITSELECTED )		// Cosmetics :Unselect the cell. ++ User sees the actual state instead of the black cell.   -- 1 it is now our resonsability to correctly display the state of the cell. 2.arrow keys will erroneously jump to column 0
		// printf "\t\t\tDSToggle( dsF:%3d  \tdsl:%3d  \tcol:%2d\t)  toggling ds:%2d \r", dsF, dsL, col, ds
		if ( State( wFlags, ds, col, pl ) == nState1 )
			wFlags[ ds ][ col ][ pl ]	= nState2
		elseif ( State( wFlags, ds, col, pl ) == nState2 )
			wFlags[ ds ][ col ][ pl ]	= nState1
		endif
	endfor
End			

	  Function		DSToggle1( wFlags, dsF, dsL, col, pl, nState )
// Invert the 'nState' bit in column 'col'
	wave	wFlags
	variable	dsF, dsL, col, pl, nState
	variable	ds
	for ( ds = dsF; ds <= dsL; ds += 1 )
		wFlags[ ds ][ col ][ pl ]	= State( wFlags, ds, col, pl )  &  nState ? wFlags & ~nState : wFlags | nState	// clear  or set  the  'nState' bit  which inverts the state
	endfor
End			


static Function	DSDrawSelectedCells( bSelected, wFlags, wTxt, dsF, dsL, col, pl, plFg, nState )
// Provide feedback to the user that cells in this range have just been selected or deselected (change cell text e.g. 1->-1->1, a->A->a, '1   '->'   1' , change text color, change background color, change font, change style...)
// Prepend  '* '  and change background color  and change foreground color
	wave	wFlags
	wave  /T	wTxt
	variable	bSelected, dsF, dsL, col, pl, plFg, nState
	variable	ds, len
	string  	sPrefix	= "* "
  	for ( ds = dsF; ds <= dsL; ds += 1 )
// wFlags[ ds ][ col ][ 0 ] =  wFlags & ~kBIT_SEL)		// Cosmetics :Unselect the cell. ++ User sees the actual state instead of the black cell.   -- 1 it is now our resonsability to correctly display the state of the cell. 2.arrow keys will erroneously jump to column 0
		wFlags[ ds ][ col ][ pl ]     = bSelected  ?  wFlags | nState  :   wFlags  &  ~nState
		wFlags[ ds ][ col ][ plFg ] = bSelected  ?  0			   :   kST_FITFAIL			// use the  'fitFailed'  color for as normal foreground color as this will in most cases give the best contarst and the least confusion
		if (   bSelected  &&    cmpstr( (wTxt[ ds ][ col ])[ 0, 1 ] , sPrefix  ) )
			wTxt[ ds ][ col ] = sPrefix + wTxt[ ds ][ col ] 
		endif
		if ( ! bSelected  &&  ! cmpstr( (wTxt[ ds ][ col ])[ 0, 1 ] , sPrefix  ) )
			wTxt[ ds ][ col ] = (wTxt[ ds ][ col ])[ 2, inf ]
		endif
 	endfor
End



  Function		State( wFlags, row, col, pl )
	wave	wFlags
	variable	row, col, pl
	if ( ! waveExists( wFlags ) )
		printf "State(): wave is missing.\r"
		return 0
	endif
//	print "State", row, col, wFlags[ row] [ col ][ 0 ] ,  wFlags[ row] [ col ][ 0 ] & bitval , wFlags[ row] [ col ][ pl ]  
	return	wFlags[ row] [ col ][ pl ]
End


	  Function		DSStateNotActive( wFlags, row, col, pl )
// returns state with the 'active' flag removed
	wave	wFlags
	variable	row, col, pl
	return	wFlags[ row] [ col ][ pl ]  &  ~kST_ACTIV
End


static  Function		SetListboxTxtAndColors( wLBTxt, wFlags )
	wave  /T	wLBTxt
	wave  	wFlags
	variable	ds, dsCnt	= DimSize( wLBTxt, 0 )
	variable	pr, bl, fr, sw, pon
	string  	sPlaneNm	= "ForeColors"					// or use  mild colors in conjunction with 'backColors'
	variable	plFg		= FindDimLabel( wFlags, 2, sPlaneNm )
	variable	pl		= FindDimLabel( wFlags, 2, "BackColors" )
	variable	nColor	= kST_FITFAIL					// use the  'fitFailed'  color for as normal foreground color as this will in most cases give the best contrast and the least confusion
	for ( ds = 0; ds < dsCnt; ds += 1 )
		Ds2pbfs( ds, pr, bl, fr, sw, pon )
		wLBTxt[ ds ][ kCOLM_PR ]		= num2str( pr )		// set initial LB text
		DSSet( wFlags, ds, ds, kCOLM_PR, plFg, nColor ) 	// pr )			// colorise the LB text
		wLBTxt[ ds ][ kCOLM_BL ]		= num2str( bl )		
		DSSet( wFlags, ds, ds, kCOLM_BL, plFg, nColor ) 	// bl )
		wLBTxt[ ds ][ kCOLM_FR ]		= num2str( fr )		// set initial LB text
		DSSet( wFlags, ds, ds, kCOLM_FR, plFg, nColor ) 	// fr )
		wLBTxt[ ds ][ kCOLM_SW ]	= num2str( sw )		
		DSSet( wFlags, ds, ds, kCOLM_SW, plFg, nColor ) 	// sw )
		wLBTxt[ ds ][ kCOLM_PON ]	= num2str( pon )		
		DSSet( wFlags, ds, ds, kCOLM_PON, plFg, nColor )	// pon )
	endfor
End



static Function		DSClearTraces( wFlags, col, pl )
// Removes selectively  'nState'  in column  'col'  e.g.  removes  'Sel'   or  'Tbl'  on all data units in column. All  bits of  'nState'  are processed independently. 
// Also removes nState = 'Avg'  which is more complicate as the avg trace must also be cleared step by step.
// The listbox is updated, but the color/existance of the traces is not handled here except for the avg trace.   (Only-avg-traces should vanish, avg+tbl-traces should change color from avg+tbl  to  tbl.  
	wave	wFlags
	variable	col, pl
	variable	dsFirst, dsL, dsSize
	variable	dsLast	= DimSize( wFlags , 0 ) - 1										// the last data section of the entire experiment
	variable	row		= 0
	string  	sWNm, sTNL
	do
		DS2Lims( row, col, dsFirst, dsL, dsSize ) 										// computes first and last data section of the current data unit e.g.  Frame or Block
		variable	ch, nChans	= CfsChannels_()
	 	for ( ch = 0; ch < nChans; ch += 1 )
			string  	sDrawDataNm      = OrgWvNm( ch, dsFirst, dsSize )					// make a UNIQUE name for each trace segment		
			string  	sFoDrawDataNm  = FoOrgWvNm( ch, dsFirst, dsSize )					// make a UNIQUE name for each trace segment		
			wave   /Z	wDrawData	    =  $sFoDrawDataNm
			if ( waveExists( wDrawData ) )
				sWNm	= EvalWndNm( ch )
				if ( WinType( sWNm ) == kGRAPH ) 									// The user may have closed a window, perhaps to remove an empty channel, ...
					sTNL	= TraceNameList( sWNm, ";", 1 )
					if ( WhichListItem( sDrawDataNm, sTNL, ";" )  != kNOTFOUND )			// only if wave is in graph (the user may have removed it  or  'DispSkipped'  hides it)...
						RemoveFromGraph   /W=$sWNm  $sDrawDataNm				// this name does not contain the folder 
						KillWaves	$sFoDrawDataNm
					endif
				endif					
			endif
		endfor
		row += dsSize
	while ( dsL < dsLast ) 	
End

 Function		DSClearColumn( wFlags, col, pl, nState )
// Removes selectively  'nState'  in column  'col'  e.g.  removes  'Sel'   or  'Tbl'  on all data units in column. All  bits of  'nState'  are processed independently. 
// Also removes nState = 'Avg'  which is more complicate as the avg trace must also be cleared step by step.
// The listbox is updated, but the color/existance of the traces is not handled here except for the avg trace.   (Only-avg-traces should vanish, avg+tbl-traces should change color from avg+tbl  to  tbl.  
	wave	wFlags
	variable	col, pl, nState
	variable	dsFirst, dsL, dsSize
	variable	dsLast	= DimSize( wFlags , 0 ) - 1										// the last data section of the entire experiment
	variable	row		= 0
	do
		DS2Lims( row, col, dsFirst, dsL, dsSize ) 										// computes first and last data section of the current data unit e.g.  Frame or Block
		// Also update the average trace by subtracting the trace segment  of each data unit which is cleared from the average trace. At the end the average trace must consist only of rounding errors!
		if ( nState & kST_AVG )
			variable	ch, nChans	= CfsChannels_()
			variable	nThisState 	= State( wFlags, dsFirst, col, pl )
		 	for ( ch = 0; ch < nChans; ch += 1 )
				string  	sFoDrawDataNm  = "root:uf:evo:cfsr:" +  OrgWvNm( ch, dsFirst, dsSize )	// make a UNIQUE name for each trace segment		
				wave   /Z	wDrawData	    =	$sFoDrawDataNm
				if ( waveExists( wDrawData ) )
					DSAddOrRemoveAvg_( cAVG_REMOVE, nThisState, 0, ch, wDrawData, 0 )	// nState and nStatePrv must be interchanged for this call 
				endif
			endfor
		endif
		DSReset( wFlags, dsFirst, dsL, col, pl, nState )		
		row += dsSize
	while ( dsL < dsLast ) 	
End

static Function	DSInvertColumn( wFlags, col, pl, nState )
	wave	wFlags
	variable	col, pl, nState
	variable	dsFirst, dsL, dsSize
	variable	dsLast	= DimSize( wFlags , 0 ) - 1									// the last data section of the entire experiment
	variable	row		= 0
	do
		DS2Lims( row, col, dsFirst, dsL, dsSize ) 							// computes first and last data section of the current data unit e.g.  Frame or Block
		DSToggle1( wFlags, dsFirst, dsL, col, pl, nState )		// 
		row += dsSize
	while ( dsL < dsLast ) 		// todo : truncated
End

Function		GetLeftRightOfAllTraces(  wFlags, col, pl, ch, bDispSkipped, rLeftMost, rRightMost ) 
	wave	wFlags
	variable	col, pl, ch, bDispSkipped
	variable	&rLeftMost, &rRightMost
	variable	dsFirst, dsL, dsSize
	variable	dsLast	= DimSize( wFlags , 0 ) - 1									// the last data section of the entire experiment
	variable	row		= 0
	variable	nChecked	= 0
	rLeftMost	=  inf
	rRightMost	= -inf
	do
		DS2Lims( row, col, dsFirst, dsL, dsSize ) 									// computes first and last data section of the current data unit e.g.  Frame or Block
		variable	nState 		    = State( wFlags, row, col, pl )
		string  	sFoDrawDataNm  = FoOrgWvNm( ch, dsFirst, dsSize )					// make a UNIQUE name for each trace segment		
		wave   /Z	wDrawData	    =  $sFoDrawDataNm
		if ( waveExists( wDrawData ) )
			if ( nState != 0   &&   ( nState != kST_SKIP  ||  bDispSkipped == TRUE )  )		// Display any state except the Virgin and the Skipped state.  Display the skipped state if the user wants to see the unselected data sections.
				nChecked	+= 1
				rLeftMost	= min(  rLeftMost,    leftX(  wDrawData ) )
				rRightMost	= max( rRightMost, rightX( wDrawData ) )
				// printf "\t\t\tGetLeftRightOfAllTraces( col:%2d, ch:%2d, bSkip:%2d, nState:%3d ):\tChecked:%3d\t  row:%2d\t -> \t%s  \t -> \tleftmost:\t%8.3lf\trightmost:\t%8.3lf\t \r", col, ch, bDispSkipped, nState, nChecked, row, sFoDrawDataNm, rLeftMost, rRightMost
			endif
		endif
		row += dsSize
	while ( dsL < dsLast ) 		
	// printf "\t\t\tGetLeftRightOfAllTraces( col:%2d, ch:%2d, bSkip:%2d, nState:%3d ):\tChecked:%3d\t  row:%2d\t -> \t%s  \t -> \tleftmost:\t%8.3lf\trightmost:\t%8.3lf\t \r", col, ch, bDispSkipped, nState, nChecked, row, sFoDrawDataNm, rLeftMost, rRightMost
End 



static  Function	DSToggleDataUnitAndStore( wFlags, row, col, pl, nState )
	wave	wFlags
	variable	row, col, pl, nState
	nvar		gPrevRowCu   	= root:uf:evo:cfsr:gPrevRowCu
	variable	r, dsFirst, dsLast, dsSize
	if ( PrevRowIsValid() )
		DS2Lims( row, col, dsFirst, dsLast, dsSize ) 							// computes first and last data section of the data unit (=Prot, Block, Frame, Sweep) we are currently in
		// Jumps from first to last row of data unit (or reverse) . 
		variable	nDirection	   = gPrevRowCu - row						// -1 , 0 , 1
		variable	nJumpRow  =  nDirection > 0	?  dsFirst	: dsLast				// Cave : theoretically includes direction 0..
		if ( nDirection  )													// ...but this cannot ocur with arrow keys  and  the following lines would be skipped 
			for ( r = dsFirst; r <= dsLast; r += 1 ) 
				wFlags[ r 	][ col ][ 0 ]   = wFlags  & ~kBITSELECTED		// reset  bit 0x01 to 0 : clear old selection	
			endfor
			wFlags[ nJumpRow][ col ][ 0 ]  = wFlags   |  kBITSELECTED 	// set     bit 0x01 to 1	: show new selection at the other end of data unit 
		endif
		// printf "\t\tDSToggleDataUnitAndStore\t%s\tfrom DS:%4d\t...%5d\tDS %4d\t...%5d\tare offered...  \r", StringFromList( nState, lstSTATUS), dsFirst, dsLast, dsFirst, dsLast
		DSToggle1( wFlags, dsFirst, dsLast, col, pl, nState )			

	endif
	return	nJumpRow
End


static  Function	DSJumpToBegOrEndOfDataUnit( wFlags, row, col, pl, nState1, nState2 )
	wave	wFlags
	variable	row, col, pl, nState1, nState2 
	nvar		gPrevRowCu   	= root:uf:evo:cfsr:gPrevRowCu
	variable	r, dsFirst, dsLast, dsSize
	if ( PrevRowIsValid() )
		DS2Lims( row, col, dsFirst, dsLast, dsSize ) 							// computes first and last data section of the data unit (=Prot, Block, Frame, Sweep) we are currently in
		// Jumps from first to last row of data unit (or reverse) . 
		variable	nDirection	   =  row  - gPrevRowCu					// -1 , 0 , 1
		variable	nJumpRow  =  nDirection < 0	?  dsFirst	: dsLast				// Cave : theoretically includes direction 0..
		if ( nDirection  )													// ...but this cannot ocur with arrow keys  and  the following lines would be skipped 
			for ( r = dsFirst; r <= dsLast; r += 1 ) 
				wFlags[ r 	][ col ][ 0 ]   = wFlags  & ~kBITSELECTED	// reset  bit 0x01 to 0 : clear old selection	
			endfor
			wFlags[ nJumpRow][ col ][ 0 ]  = wFlags  |  kBITSELECTED 	// set     bit 0x01 to 1	: show new selection at the other end of data unit 
		endif
		printf "\t\tDSJumpToBegOrEndOfDataUnit\tentering col:%2d  row:%2d   ->DS:%4d\t...%5d\tjumping %s  ( DS %4d)  \r", row, col, dsFirst, dsLast, SelectString( nDirection, "to begin" , "not at all", "to end   " ), nJumpRow
	endif
End


static  Function	DSToggleDataRangeAndStore( wFlags, row, col, pl, nState )
	wave	wFlags
	variable	row, col, pl, nState 
	nvar		gPrevRowFi 	= root:uf:evo:cfsr:gPrevRowFi
	nvar		gPrevRowLa 	= root:uf:evo:cfsr:gPrevRowLa
	nvar		gPrevColumn   	= root:uf:evo:cfsr:gPrevColumn
	variable	dsFirst, dsLast, dsSize, nTmpFirst, nTmpLast

	DS2Lims( row, col, dsFirst, dsLast, dsSize ) 							// Only for debug printing: computes first and last data section of the data unit (=Prot, Block, Frame, Sweep) we are currently in
	if ( PrevRowIsValid() )
		if ( row > gPrevRowLa )										
			nTmpFirst	= gPrevRowFi										// We are advancing (going downwards in the listbox)
			dsFirst	= gPrevRowLa +1 									// we mark only the data units BELOW the previously selected starting data unit	
			nTmpLast	= dsLast
		else
			nTmpFirst	= dsFirst											// We are going back (upwards in the listbox)
			dsLast	= gPrevRowFi - 1									// we mark only the data units ABOVE the previously selected starting data unit
			nTmpLast	= gPrevRowLa
		endif					
		DSToggle1( wFlags, dsFirst, dsLast, col, pl, nState )			
//		DSDisplayAndAnalyse( wFlags, dsFirst, dsLast, col, pl, State( wFlags, row, col, pl ), 0 )	
		gPrevRowFi	= nTmpFirst										
		gPrevRowLa	= nTmpLast										// We store the entire range of data units INCLUDING the previously selected starting data unit
		gPrevColumn   	= col
	endif
End


Function		ClearResultSelection( wFlags )
// Resets the whole  'Select results'  listbox to 'unselected' : wSRFlags = nState = 0
	wave	wFlags	
	string  	sPlaneNm		= "BackColors" 
	variable	pl			= FindDimLabel( wFlags, 2, sPlaneNm )
	variable	row, nRows	= DimSize( wFlags, 0 )
	variable	col, nCols		= DimSize( wFlags, 1 )
	for ( col = 0; col <  nCols; col += 1 )
		for ( row = 0; row <  nRows; row += 1 )
			DSSet5( wFlags, row, row, col, pl,  0 )				// sets flags .  The range feature is not used here so  begin row = end row .
		endfor
	endfor
End



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

static  Function		Ds2pbfs( sct, pr, bl, fr, sw, pon )
// Computes protocol / block / frame / sweep / PoverN  if linear data section is given. Inverse of GetLinSweep() .
	variable	sct
	variable	&pr, &bl, &fr, &sw, &pon
	pr	= Sct2Pbfs( sct, kPROT	)	//	= wSct2Pbfs[ sct ][ kPROT ]									//  041210	
	bl	= Sct2Pbfs( sct, kBLK	)	//	= wSct2Pbfs[ sct ][ kBLK ]										//  041210	
	fr	= Sct2Pbfs( sct, kFRM	)	//	= wSct2Pbfs[ sct ][ kFRM ]										//  041210	
	sw	= Sct2Pbfs( sct, kSWP	)	//	= wSct2Pbfs[ sct ][ kSWP ]										//  041210	
	pon	= Sct2Pbfs( sct, kPON	)	//	= wSct2Pbfs[ sct ][ kPON ]										//  041210	
End


static  Function		DS2Lims( row, col, dsFi, dsLa, dsSz ) 	
// computes first and last data section of the data unit (=Prot, Block, Frame, Sweep) we are currently in
	variable	row, col
	variable	&dsFi, &dsLa, &dsSz 
	variable	pr, bl, fr, sw, pon

	Ds2pbfs( row, pr, bl, fr, sw, pon )
	if ( col == kCOLM_PR )
		bl	= 0
		fr	= 0
		sw	= 0
		dsFi	= Pbfs2Sct( pr, bl, fr, sw )
		bl	= CfsBlocks() - 1
		fr	= CfsFrames( bl ) - 1
		sw	= CfsSweeps( bl ) + CfsHasPoN( bl ) - 1
		dsLa	= Pbfs2Sct( pr, bl, fr, sw )	// [ pr ][ bl ][ fr ][ sw ]
	elseif	( col == kCOLM_BL )
		fr	= 0
		sw	= 0
		dsFi	= Pbfs2Sct( pr, bl, fr, sw )	// [ pr ][ bl ][ fr ][ sw ]
		fr	= CfsFrames( bl ) - 1
		sw	= CfsSweeps( bl ) + CfsHasPoN( bl ) - 1
		dsLa	= Pbfs2Sct( pr, bl, fr, sw )	// [ pr ][ bl ][ fr ][ sw ]
	elseif	( col == kCOLM_FR )
		sw	= 0
		dsFi	= Pbfs2Sct( pr, bl, fr, sw )	// [ pr ][ bl ][ fr ][ sw ]
		sw	= CfsSweeps( bl ) + CfsHasPoN( bl ) - 1
		dsLa	= Pbfs2Sct( pr, bl, fr, sw )	// [ pr ][ bl ][ fr ][ sw ]
//	elseif ( col == kCOLM_SW  ||  col == kCOLM_ZERO  )	
	elseif ( col == kCOLM_SW  ||  col == kCOLM_ZERO  ||  col == kCOLM_PON )	
		// dsFi  = wPbfs2Sct( pr, bl, fr, sw )	// [ pr ][ bl ][ fr ][ sw ]	// wrong: cannot access PoN sweep in  swp column
		// dsLa = wPbfs2Sct( pr, bl, fr, sw )	// [ pr ][ bl ][ fr ][ sw ]
		dsFi	= row
		dsLa	= row
	endif
	dsSz	= dsLa - dsFi + 1	
	// printf "\t\tDS2Lims(\trow:%3d\tcol:%3d\t ->\tF:%3d\tL:%3d\t(Sz:%4d)\t \r", row, col, dsFi, dsLa, dsSz
End


// 051027  not yet used
//Function		DSSelectedCnt( wFlags, col )
//	wave	wFlags
//	variable	col
//	variable	dsFirst	= 0
//	variable	dsLast 	= DimSize( wFlags , 0 ) - 1								// the last data section of the entire experiment
//	variable	dsL, dsSize
//	variable	row		= 0
//	variable	cnt		= 0
//	variable	nState, pl	= FindDimLabel( wFlags, 2, "BackColors" )
//	do
//		DS2Lims( row, col, dsFirst, dsL, dsSize ) 								// computes first and last data section of the current data unit e.g.  Frame or Block
//		nState	= State( wFlags, row, col, pl )					// Only for debug printing
//		if ( nState & kST_SEL )
//			cnt += 1
//		endif
//		row += dsSize
//	while ( dsL < dsLast ) 		
//	return	cnt
//End


//=======================================================================================================================
//=======================================================================================================================


Function		RedrawWindows()
// will only display traces but will neither analyse nor average, as the last 2 parameters  'nDoAverage'  and  'bDoEval'  in  'DSDisplayAndAnalyse()'  are both 0
	wave	wFlags		= root:uf:evo:lb:wLBFlags
	variable	nWvKind		= kWV_ORG_
	variable	col, nState	, dsFirst, dsLast, dsSize		
	variable	row, nRows	= DimSize( wFlags, 0 )
	string  	sPlaneNm		= "backColors" 
	variable	pl			= FindDimLabel( wFlags, 2, sPlaneNm )
	printf "\t\tRedrawWindows()     (should be !..) ..only displaying....\r"
	for ( col = 0; col <=  kCOLM_PON; col += 1 )

		for ( row = 0; row < nRows;  row += dsSize )
			DS2Lims( row, col, dsFirst, dsLast, dsSize ) 						// computes first and last data section of the current data unit e.g.  Frame or Block
			nState	= State( wFlags, row, col, pl ) 
			if ( nState != 0 )			
				DSDisplayAndAnalyse( wFlags, dsFirst, dsLast, col, pl, 0, nState, cAVG_NO, 0, nWvKind )		//nStatePrv = 0???
			endif		
		endfor

	endfor
	DSDisplayAvgAllChans()
End	


Function		ClearWindows()
	variable	ch, nChannels	= CfsChannels_()
	string		sWNm
	for ( ch = 0; ch < nChannels; ch += 1)
		sWNm	= EvalWndNm( ch )
		EraseTracesInGraph( sWNm )
	endfor
End

//=======================================================================================================================

 Function	DSDisplayAndAnalyse( wFlags, dsFirst, dsLast, col, pl, nStatePrv, nState, nAvgRemAdd, bDoEval, nWvKind )	
	wave	wFlags	
	variable	dsFirst, dsLast, col, pl, nStatePrv, nState, nAvgRemAdd, bDoEval, nWvKind

	wave	wDSColors		= root:uf:evo:lb:wDSColors
	nvar		gbDispSkipped		= $"root:uf:evo:de:gbDispSkip0000"
	nvar		gnDispMode		= $"root:uf:evo:de:gDspMode0000" 		
	variable	ch
	variable	nCurSwp		= dsFirst
	variable	nSize		= dsLast - dsFirst + 1
	variable	nDataPts, nDrawPts, nOfsPts, step = 1
	variable	XaxisLeft, XaxisRight							// 050120 in seconds
	variable	nChannels		= CfsChannels_()
	variable	nSmpInt		= CfsSmpInt()
	variable	nDataSections	= DataSectionCnt_( nWvKind ) 
	variable	row			= dsFirst, dsLa
	string		sDrawDataNm, sFoDrawDataNm	
	string  	sWNm, sTNL, sTxt

	// Decompose a range of data unit into single data units
	variable	bSuccessfulFits	= TRUE
	do

		ExtractionParams( row, col, nCurSwp, dsLa, nSize, nDataPts, nDrawPts, nOfsPts, step )  // Sets 'dsLa' which ends the loop. All but the first 2 parameters are references 

		// The wave must be scaled for the evaluation even if the user turned the graph off   
		if ( gnDispMode == kSTACKED )
			XaxisLeft	= 0											// Mode Stacked=Superimposed :	start all sweeps at 0
		elseif ( gnDispMode == kSINGLE )
			XaxisLeft	= nOfsPts * nSmpInt / kXSCALE						// Mode Single Sweep :			start each sweep at its proper time
		elseif ( gnDispMode == kCATENATED )
			XaxisLeft	= nOfsPts * nSmpInt / kXSCALE						// Mode catenated :				start each sweep at its proper time
		endif
	 	XaxisRight	= XaxisLeft + nDrawPts * step * nSmpInt / kXSCALE

		for ( ch = 0; ch < nChannels; ch += 1)
	
			sDrawDataNm	   = OrgWvNm( ch, nCurSwp, nSize )						// make a UNIQUE name for each trace segment
			sFoDrawDataNm  = FoOrgWvNm( ch, nCurSwp, nSize )					// = "root:uf:evo:cfsr:" + sDrawDataNm

			wave   /Z	wDrawData	=  $sFoDrawDataNm
			wave	wCurRegion	= root:uf:evo:evl:wCurRegion
			wCurRegion[ kCURSWP ]	= nCurSwp			
			wCurRegion[ kSIZE ]		= nSize		
			sWNm				= EvalWndNm( ch )

			// Reset the state of the PREVIOUSLY active trace to not-active (e.g. pink -> grey).  This must not be confused with  'nStatePrv'  which is the previous state of the CURRENT trace. Also get the left data border of the previous trace.
			variable	dsPrvFirst, dsPrvLast, dsPrvCol
			DsPrev( dsPrvFirst, dsPrvLast, dsPrvCol )
			string  	wPrevDrawDataNm	= OrgWvNm( ch, dsPrvFirst, dsPrvLast - dsPrvFirst + 1 )	
			variable	nStateNotActive	= DSStateNotActive( wFlags, dsPrvFirst, dsPrvCol, pl )
			// printf "\t\tDSDAA   %s will be set to not-active:%d \t  \r",  wPrevDrawDataNm, nStateNotActive
			if ( WinType( sWNm ) == kGRAPH ) 									// As the user may have closed a window, perhaps to remove an empty channel, ...
				ModifyGraph  /W=$sWNm /Z  rgb( $wPrevDrawDataNm ) = ( wDSColors[ nStateNotActive ][ 0 ], wDSColors[ nStateNotActive ][ 1 ], wDSColors[ nStateNotActive ][ 2 ] )
			endif

			// DISPLAYING
			sTxt		= "skip uns"
			if ( nState != 0   &&   ( nState != kST_SKIP  ||  gbDispSkipped == TRUE )  )		// Display any state except the Virgin and the Skipped state.  Display the skipped state if the user wants to see the unselected data sections.

				make	/O /N=(nDrawPts)	$sFoDrawDataNm
				wave	wDrawData	=	$sFoDrawDataNm
				sTxt	= "create"
				wave  	wData	= $WaveNm( nWvKind, ch ) 					// e.g.  $"root:uf:evo:cfsr:wCfsBig" + num2str( ch )			// Use it here an alias name 
				// Copying the data may not seem very effective, but it is currently the best way to do it. See Igor mailing list, Larry Hutchinson 050120
				CopyDrawPoints( wData, wDrawData, nDrawPts, nOfsPts, step )			// fill 'wDrawData' from original wave 'wData' starting at 'nOfsPts' and taking into account 'step' which depends on  'gbDispAllPnts'

				// printf "\t\tDSDisplayAndAnalyse(a) stp:%2d \tdltaX:%.4lf\tXaxisLeft:%6.4lf \tXaxisright:%6.4lf \tSmpInt:%g\t%s\tgraph has now %d traces  \r", step, deltaX( wDrawData ), XaxisLeft, XaxisRight, nSmpInt, sDrawDataNm, ItemsInList( sTNL )
				SetScale /I X, XaxisLeft , XaxisRight, ksXUNIT, wDrawData
				// printf "\t\tDSDisplayAndAnalyse(b)\tc:%d\t%s\tds:%3d..%3d\t sz:%3d \tstp:%2d \tdltaX:%.4lf\tXaxisLeft:%6.4lf \tXaxisRight:%6.4lf \tSmpInt:%g   \r", ch, sDrawDataNm, nCurSwp, dsL, DataSections(), step, deltaX( wDrawData ), XaxisLeft, XaxisRight, nSmpInt


				if ( WinType( sWNm ) == kGRAPH ) 									// As the user may have closed a window, perhaps to remove an empty channel, ...
																			// ..we do not automatically reopen the window. To revive the channel the file must be reloaded. 

// 051027 eliminate this (Moving avg -> new windows...)
					if ( gnDispMode == kSINGLE )
						// or : Eraseprevious...+ Cursors etc ???
						EraseTracesInGraphExcept( sWNm, ksWAVG ) 					// 050601 only erase data units traces, but leave averaged trace  TODO: this is called too often......
					endif

					sTNL	= TraceNameList( sWNm, ";", 1 )
					if ( WhichListItem( sDrawDataNm, sTNL, ";" )  == kNOTFOUND )			// only if wave is not in graph append the wave to the graph
						AppendToGraph  /W=$sWNm 	wDrawData					// wDrawData does contain folder ,  sDrawDataNm does NOT contain folder.
					endif														// This puts the data trace OVER the avg trace which is not nice, but  'ReorderTraces()'  fixes it.
					ModifyGraph 	  /W=$sWNm  rgb( $sDrawDataNm ) = ( wDSColors[ nState ][ 0 ], wDSColors[ nState ][ 1 ], wDSColors[ nState ][ 2 ] )
					ModifyGraph   /W=$sWNm  axisEnab( left )={ 0, 0.85 }					// 0.9 : leave 10% space on top for textbox ( 0.8 is better for windows lower than 1/3 screen height )
	
					if ( ! waveExists( wDrawData ) )
						InternalError ( "DSDisplayAndAnalyse()   '" + sFoDrawDataNm + "'  does not exist. " ) 	// can not happen as the wave is created above
					elseif ( waveExists( wDrawData )   &&  numPnts( wDrawData ) == 0 )
						InternalError ( "DSDisplayAndAnalyse()   '" + sFoDrawDataNm + "'  exists but  has 0 points. " ) 
					else
						// 'SetDataBounds()'  works but is called too often when this function 'DSDisplayAndAnalyse()'  is called from 'RedrawWindows()' . In that case it would be sufficient to call  'SetDataBounds()'  only for the 1. and the last trace.
						SetDataBounds( wFlags, col, pl, ch, wDrawData, sFoDrawDataNm, nSmpInt / kXSCALE, XaxisLeft, XaxisRight, gnDispMode, gbDispSkipped )
						RescaleAxisX( ch )
						nvar	gbAutoSclY	= $"root:uf:evo:de:cbAutoSclY" + num2str( ch ) + "000"
						if ( gbAutoSclY )
							RescaleAxisY( ch )
						endif
					endif

				endif					// graph exists

			endif					// state

			// ERASING...
			if ( nState == 0   ||   ( nState == kST_SKIP  &&  gbDispSkipped == FALSE )  )
				if ( waveExists( wDrawData ) )
					//RemoveAnalysis( wData, ch, nChannels, nOfsPts, nDataPts, nSmpInt, nDataSections )	
					if ( WinType( sWNm ) == kGRAPH ) 									// As the user may have closed a window, perhaps to remove an empty channel, ...
																				// ..we do not automatically reopen the window. To revive the channel the file must be reloaded. 
						sTNL	= TraceNameList( sWNm, ";", 1 )
						if ( WhichListItem( sDrawDataNm, sTNL, ";" )  != kNOTFOUND )			// only if wave is in graph (the user may have removed it  or  'DispSkipped'  hides it)...
							RemoveFromGraph   /W=$sWNm  $sDrawDataNm				// this name does not contain the folder 
							KillWaves	$sFoDrawDataNm
						endif
						sTxt = "kill     "
					endif					
				endif
			endif					// state

			// Main debug printing line
			string  	sPrintStates = pad( States( nStatePrv, lstSTATUS),11)  + "\t -> \t" + pad( States( nState, lstSTATUS),11)		// only for printing and only because otherwise the line below gets too long
			variable	ColorPrv	  = Grey( nStatePrv )
			// printf "\t\tDSDAA(b co:%d  ro:%3d\t cu:%2d\tL:%2d\t sz:%2d\tColPrv:%4d\tPrSt:%2d)\t%s\t( %2d )   %s\t'%s'  c:%d\tOpts:%6d\tDapt:%6d\tDrpt:%6d\tstp:%4d\t%s\t>%s\t%s\t \r", col, row, nCurSwp, dsLa, nSize, ColorPrv, nStatePrv, sPrintStates, nState, pad(sTxt,7), sWNm, ch, nOfsPts, nDataPts, nDrawPts, step, wPrevDrawDataNm, pd(sDrawDataNm,12), pd(sFoDrawDataNm,23)

			// ANALYSING.......
			if ( ! CursorsAreSet( ch ) )
				SpreadCursors( ch ) 
			endif

			ResetEval_( ch )			// This avoids obsolete results (from the previous data section) to be printed if after an analysis the next DS is only viewed but not analysed.

			ResetFitResults( ch ) 		// This avoids obsolete results (from the previous data section) to be printed if after an analysis the next DS is only viewed but not analysed.	

			if (  bDoEval   &&   nState & kST_TBL )	
				// printf "\t\tDSDAA() '%s' ch:%2d\t PrSt:%2d\tSt:%2d  XaxisLeft:%6.2lf=?=%6.2lf\t..%6.2lf=?=%6.2lf\tnOfsPts:%4d  \tnDataPts:%4d  nSmpInt:%d  dltaX:%.6lf=?=%.6lf \r", sWNm, ch, nStatePrv, nState,  XaxisLeft, leftX(wDrawData), rightX(wDrawData), XaxisLeft + nSmpInt / kXSCALE * V_npnts, nOfsPts, nDataPts, nSmpInt, nSmpInt / kXSCALE, deltaX( wDrawData ) 
				bSuccessfulFits  *=  Analyse_( wDrawData, nState, ch, XaxisLeft )		// one failing fit will set bSuccessfulFits to FALSE
				SetEvaluationCnt( ch, EvaluationCnt( ch ) + 1 )
			endif

			SetResultsValidWithoutAnalysis( ch, nOfsPts, nDataPts, nSmpInt, nDataSections, nCurSwp, nSize, nWvKind  )	// called AFTER Analyse_() as we must wait for the new updated evaluation cnt

if ( WinType( sWNm ) == kGRAPH ) 											// As the user may have closed a window, perhaps to remove an empty channel, ...
			DisplayCursors_Peak( ch )
			DisplayCursors_Base( ch )
			DisplayCursors_Lat( ch )
			DisplayCursors_UsedFit( ch )
endif

			// 060705  Making Movies
			if (  nState == kST_MOVIE )	
				string  	sFolders	= "evo:de"
				MovieAddGraph_( sFolders, ch, nCurSwp, nSize, dsFirst, dsLast )							// The movie will be constructed and built within this function but it will be closed outside and later.
			endif


		endfor					// all channels

// 060213  Aligning averages
//		AllAverages_( nChannels, XaxisLeft, nAvgRemAdd, nStatePrv, nState, nDataPts, nCurSwp, nSize )			// 051027a also outside channel loop
//		AllLatencies()													// must be outside the channel loop as it may span multiple channels

// 060213  Aligning averages
		AllLatencies()													// must be outside the channel loop as it may span multiple channels
		variable  AlignVal  = Alignment()										// computes the alignment time which will be used by 'AllAverages_()'
		AllAverages_( nChannels, XaxisLeft, nAvgRemAdd, nStatePrv, nState, nDataPts, nCurSwp, nSize, AlignVal )	// Average needs Latencies so it is evaluated after the Latencies 

		for ( ch = 0; ch < nChannels; ch += 1)									// Update the Evaluation results textbox AFTER the latencies have been computed
			string  sText  = PrintEvalTextbox( ch )								// Format the selected evaluated results to be printed in the textbox in the graph window  
			DispHideEvalTextbox__( ch, sText )								// Depending on the state of the on/off variable display or hide the textbox
		endfor					// all channels

		if (  bDoEval   &&   nState & kST_TBL )	
			AddToTableAllChans_( kLB_SELECT, kRS_TOFILE, nWvKind  )	// Possibly build the selected results wave 'wR0' , possibly build the selected results table, display the selected results table and save to file at appropriate times
			AddToTableAllChans_( kLB_ALL,        kRS_TOFILE, nWvKind  )	// Possibly build the total results wave 'wR1' , possibly build the total results table, do NOT display the total results table but save to file at appropriate times
		endif
		row += nSize

	while ( dsLa < dsLast   ) 		// todo : truncated
	return	bSuccessfulFits
End


static Function	ExtractionParams( row, col, nCurSwp, dsLa, nSize, nDataPts, nDrawPts, nOfsPts, step )  
// when row and column of the listbox are given, all parameters relevant for data extraction from the big original data wave are computed
	variable	row, col
	variable	&nCurSwp, &dsLa, &nSize				// references
	variable	&nDataPts							// reference : number of original data points, must be included in avg but may be too many for drawing
	variable	&nDrawPts						// reference : number of decimated points to be displayed in graph 
	variable	&nOfsPts, &step						// references
	nvar		gOfs			=   root:uf:evo:cfsr:gOfs 
	nvar		gbDispAllPnts	= $"root:uf:evo:cfsr:gbDispAllPnts"

	DS2Lims( row, col, nCurSwp, dsLa, nSize ) 						// computes first and last data section of the current data unit e.g.  Frame or Block

	nOfsPts	= DSBegin_( nCurSwp ) + gOfs * DSPoints_( nCurSwp )	
	nDataPts	= DSBegin_( nCurSwp  + nSize ) - DSBegin_( nCurSwp ) 
		
	if ( gbDispAllPnts )	
		nDrawPts	= nDataPts								// WITHOUT DECIMATION: displaying 2MB takes about 10 s 
		step		= 1
	else	
		nDrawPts	= min( cDRAWPTS, nDataPts )					// WITH DECIMATION: 2MB stepped down to 500 pts: display takes about  3s (display alone is faster than that, there are other time eaters...)
		step		= trunc( max( nDataPts / nDrawPts, 1 ) )
	endif		
End

//static Function	ExtractionParams1( ch, row, col, nCurSwp, dsLa, nSize, nDataPts, nDrawPts, nOfsPts, step, sDrawDataNm, sFoDrawDataNm )  
//// when row and column of the listbox are given, all parameters relevant for data extraction from the big original data wave are computed
//	variable	ch, row, col
//	variable	&nCurSwp, &dsLa, &nSize				// references
//	variable	&nDataPts							// reference : number of original data points, must be included in avg but may be too many for drawing
//	variable	&nDrawPts						// reference : number of decimated points to be displayed in graph 
//	variable	&nOfsPts, &step						// references
//	string  	&sDrawDataNm, &sFoDrawDataNm 		// references
//	nvar		gOfs				=   root:uf:evo:cfsr:gOfs 
//	nvar		gbDispAllPnts	= $"root:uf:evo:cfsr:gbDispAllPnts"
//
//	DS2Lims( row, col, nCurSwp, dsLa, nSize ) 						// computes first and last data section of the current data unit e.g.  Frame or Block
//
//	nOfsPts	= DSBegin_( nCurSwp ) + gOfs * DSPoints_( nCurSwp )	
//	nDataPts	= DSBegin_( nCurSwp  + nSize ) - DSBegin_( nCurSwp ) 
//		
//	if ( gbDispAllPnts )	
//		nDrawPts	= nDataPts								// WITHOUT DECIMATION: displaying 2MB takes about 10 s 
//		step		= 1
//	else	
//		nDrawPts	= min( cDRAWPTS, nDataPts )					// WITH DECIMATION: 2MB stepped down to 500 pts: display takes about  3s (display alone is faster than that, there are other time eaters...)
//		step		= trunc( max( nDataPts / nDrawPts, 1 ) )
//	endif		
//
//	sDrawDataNm	    = OrgWvNm( ch, nCurSwp, nSize )				// make a UNIQUE name for each trace segment
//
//	sFoDrawDataNm  = FoOrgWvNm( ch, nCurSwp, nSize )			// = "root:uf:evo:cfsr:" + sDrawDataNm
//End

// todo:  use waveform arithmetic or avoid the copying altogether.......
Static Function		CopyDrawPoints( wData, wDrawData, nDrawPts, nOfsPts, step )
	wave 	wData, wDrawData
	variable	nDrawPts, nOfsPts, step
	variable	n
	for ( n = 0; n < nDrawPts; n += 1 )
		wDrawData[ n ] = wData[ nOfsPts + n * step ]
	endfor
	// printf "\t\tCopyDrawPoints()   deltaX( wData ) : %g ,  deltaX( wDrawData ) : %g  \r", deltaX( wData ), deltaX( wDrawData )
End


//====================================================================================================================================
// THE  SELECT RESULTS   TABLE / PRINT and TOFILE   LISTBOX  PANEL			

Function		PanelRSUpdateTable_()
// Build the huge  'Select result'  listbox allowing the user to select some results for printing, for the reduced file or for  latencies
// Code takes into account the various states (visible, hidden, moved, existant, not-yet-existant...) and handles all cases while avoiding unnecessary  killing and reseting of the panel and of the waves.
// Note: The position of the panel window is maintained  WITHOUT using StoreWndLoc() / RetrieveWndLoc() !!!
	nvar		bVisib		= root:uf:evo:de:cbResSelTb0000					// The ON/OFF state ot the 'Select Results' checkbox

	// 1. Construct the global string  'lstACVAllCh'  which contains all of the various evaluation and fitting values
	string  	lstACVAllCh	=  ListACVAllChansTable() 

	// 2. Get the the text for the cells by breaking the global string  'lstACVAllCh'  which contains all of the various evaluation and fitting values
	variable	len, n, nItems	= ItemsInList( lstACVAllCh )	
	 printf "\t\t\tPanelRSUpdateTable(a)\tlstACVAllCh has items:%3d <- \t '%s .... %s' \r", nItems, lstACVAllCh[0,80] , lstACVAllCh[ strlen( lstACVAllCh ) - 80, inf ]
	string 	sColTitle, lstColTitles	= "", lstColItems = ""
	variable	nExtractCh, ch = -1
	variable	nExtractRg, rg = -1 
	string 	sOneItemIdx, sOneItem
	for ( n = 0; n < nItems; n += 1 )
		sOneItemIdx	= StringFromList( n, lstACVAllCh )					// e.g. 'Base_010'
		len			= strlen( sOneItemIdx )
		sOneItem		= sOneItemIdx[ 0, len-4 ] 						// strip 3 indices + separator '_'  e.g. 'Base_010'  ->  'Base'
		nExtractCh	= str2num( sOneItemIdx[ len-2, len-2 ] )				// !!! Assumption : ACV naming convention
		nExtractRg	= str2num( sOneItemIdx[ len-1, len-1 ] )				// !!! Assumption : ACV naming convention
		if ( ch != nExtractCh )										// Start new channel
			ch 		= nExtractCh
 			rg 		= -1 
		endif
		if ( rg != nExtractRg )										// Start new region
			rg 		= nExtractRg
			sprintf sColTitle, "Ch%2d Rg%2d", ch, rg					// Assumption: Print results column title  	
			lstColTitles	= AddListItem( sColTitle, lstColTitles, ksCOL_SEP, inf )
			lstColItems	+= ksCOL_SEP
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
	 printf "\t\t\tPanelRSUpdateTable(b)\tlstACVAllCh has items:%3d -> rows:%3d  cols:%2d\tColT: '%s'\tColItems: '%s...' \r", nItems, nRows, nCols, lstColTitles, lstColItems[0, 100]


	// 4. Compute panel size . The y size of the listbox and of the panel  are adjusted to the number of listbox rows (up to maximum screen size) 
	variable	xSize		= nCols * 75								// Adjust when column width changes. 75 is minimum needed to display the column title completely e.g. 'Ch 1 Rg 0'
	variable	ySizeMax	= GetIgorAppPixelY() -  kMAGIC_Y_MISSING_PIXEL	// Here we could subtract some Y pixel if we were to leave a bottom region not covered by a larges listbox.
	variable	ySizeNeed	= nRows * kLB_CELLY + kLB_ADDY				// We build a panel which will fit entirely on screen, even if not all listbox line fit into the panel...
	variable	ySize		= min( ySizeNeed , ySizeMax ) 					// ...as in this case Igor will automatically supply a listbox scroll bar.
			ySize		=  trunc( ( ySize -  kLB_ADDY ) / kLB_CELLY ) * kLB_CELLY + kLB_ADDY	// To avoid partial listbox lines shrink the panel in Y so that only full-height lines are displayed
	
	// 5. Draw  panel and listbox
	if ( bVisib )													// Draw the SelectResultsPanel and construct or redimension the underlying waves  ONLY IF  the  'Select Results' checkbox  is  ON

		string  	sWin	= "PnSelResPr"
		if ( WinType( sWin ) != kPANEL )								// Draw the SelectResultsPanel and construct the underlying waves  ONLY IF  the panel does not yet exist
			// Define initial panel position.
			NewPanel1( sWin, kRIGHT, -3, xSize, kTOP, 0, ySize, kKILL_DISABLE, "File Results" )	// -3 is a slight X offset preventing this panel to cover the smaller 'Draw results' panel completely.  We must disable killing as this would destroy any selection in the listbox, but minimising is allowed.

			SetWindow	$sWin,  hook( SelRes ) = fHookPnSelResPr
			ModifyPanel /W=$sWin, fixedSize= 1						// prevent the user to maximize or close the panel by disabling these buttons

			// Create the 2D LB text wave	( Rows = maximum of results in any ch/rg ,  Columns = Ch0 rg0; Ch0 rg1; ... )
			make  /O 	/T 	/N = ( nRows, nCols )		root:uf:evo:lb:wSRTxtPr	= ""	// the LB text wave
			wave   	/T		wSRTxt		     =	root:uf:evo:lb:wSRTxtPr
		
			// Create the 3D LB flag wave. 	Rows x Columns (as above)  x 3  : last index 0 is flags, 1 is fore- or background color, 2 is the remaining color 
			make   /O	/B  /N = ( nRows, nCols, 3 )	root:uf:evo:lb:wSRFlagsPr	// byte wave is sufficient for up to 254 colors 
			wave   			wSRFlags		    = 	root:uf:evo:lb:wSRFlagsPr
			
			// Create color table withs rows and columns exchanged. 3 rows, n columns is easier to read as n columns, 3 rows but must be transposed before Igor can use them.
			// At the moment these colors are the same as in the  DataSections  listbox
			//								black		blue			red			magenta			grey			light grey			green			yellow				

// Version1: (works but wrong colors)
//			make   /O	/W /U	root:uf:evo:lb:wSRColorsPr= { {0, 0, 0 }, { 0, 0, 65535 },  { 65535, 0, 0 },  {40000,0,48000}, {44000,44000,44000},  {54000,54000,54000},  { 0, 50000, 0} ,   { 0, 56000, 56000 },  {65280,59904,48896} }	// order must be same as defined by constants above
//			wave	wSRColorsPr	 	= root:uf:evo:lb:wSRColorsPr 		
//			MatrixTranspose 		  wSRColorsPr					// the same table is used for foreground and background. 	Igor requires  n  rows, 3 columns 
//			EvalColors( wSRColorsPr )								// 051108  

// Version2: (works...)
			make /O	/W /U /N=(128,3) 	   	   root:uf:evo:lb:wSRColorsPr 		
			wave	wSRColorsPr	 		= root:uf:evo:lb:wSRColorsPr 		
			EvalColors( wSRColorsPr )								// 051108  


			// Link the  indices  of  Foreground  and  Background  colors  to  their name strings which are later used to access the layer where the color is to be set
			variable	planeFore	= 1
			variable	planeBack	= 2
			SetDimLabel 2, planeBack,  $"backColors"	wSRFlags
			SetDimLabel 2, planeFore,   $"foreColors"	wSRFlags
	
		else													// The panel DOES exist. It may be minimised to an icon or it may be hidden behind other panels. If it is hidden then the checkbox must be actuated twice: hide and then restore panel to make it visible
			MoveWindow /W=$sWin	1,1,1,1						// Restore previous size and position. This does NOT take into account that the panel size may have changed in the meantime due to more or less columns or rows

			MoveWindow1( sWin, kRIGHT, -3, xSize, kTOP, 0, ySize )		// Extract previous panel position and size. Keep only position and discard size as the size may have changed in the meantime due to more or less columns or rows.

			wave   	/T		wSRTxt			= root:uf:evo:lb:wSRTxtPr
			wave   			wSRFlags		  	= root:uf:evo:lb:wSRFlagsPr
			Redimension	/N = ( nRows, nCols )		wSRTxt
			Redimension	/N = ( nRows, nCols, 3 )	wSRFlags
		endif

		// Set the column titles in the SR text wave, take the entries as computed above
		for ( c = 0; c < nCols; c += 1 )
			SetDimLabel 1, c, $StringFromList( c, lstColTitles, ksCOL_SEP ), wSRTxt	// 1 is columns
		endfor

		// Fill the listbox columns with the appropriate  text
		variable	r
		for ( c = 0; c < nCols; c += 1 )
			lstItemsInColumn  = StringFromList( c, lstColItems, ksCOL_SEP )	
			for ( r = 0; r < ItemsInList( lstItemsInColumn ); r += 1 )
				wSRTxt[ r ][ c ]	= StringFromList( r, lstItemsInColumn )				// set the text 
			endfor
			for ( r = ItemsInList( lstItemsInColumn ); r < nRows; r += 1 )
				wSRTxt[ r ][ c ]	= ""										// clear the text in the last rows if another column has more rows 
			endfor
		endfor
	
		// Build the listbox which is the one and only panel control 
		// stale BP 2  : set 2 BPs in the next 2 lines. Run until  Igor stops at the 2. BP ( the 1. will.be skipped ).  Try to continue with  ESC....NO stale BP here.

		ListBox 	  lbSelectResult,    win = PnSelResPr, 	pos = { 2, 0 },  size = { xSize, ySize + kLB_ADDY },  frame = 2
		ListBox	  lbSelectResult,    win = PnSelResPr, 	listWave 			= root:uf:evo:lb:wSRTxtPr
		ListBox 	  lbSelectResult,    win = PnSelResPr, 	selWave 			= root:uf:evo:lb:wSRFlagsPr,  editStyle = 1
		ListBox	  lbSelectResult,    win = PnSelResPr, 	colorWave		= root:uf:evo:lb:wSRColorsPr				// 051108
		// ListBox 	  lbSelectResult,    win = PnSelResPr, 	mode 			 = 4// 5			// ??? in contrast to the  DataSections  panel  there is no mode setting required here ??? 
		ListBox 	  lbSelectResult,    win = PnSelResPr, 	proc 	 			 = lbSelResPrProc_

	endif		// bVisible : state of 'Select results panel' checkbox is  ON 
End


Function		PanelRSHideTable_()
	printf "\t\t\tfPanelRSHideTable()    \r"
	string  	sWin	= "PnSelResPr"
	if (  WinType( sWin ) == kPANEL )						// check existance of the panel. The user may have killed it by clicking the panel 'Close' button 5 times in fast succession
		MoveWindow 	/W=$sWin   0 , 0 , 0 , 0				// hide the window by minimising it to an icon
	endif
End



Function 		fHookPnSelResTable( s )
// The window hook function of the 'Select results panel' detects when the user minimises the panel by clicking on the panel 'Close' button and adjusts the state of the 'select results' checkbox accordingly
	struct	WMWinHookStruct &s
	if ( s.eventCode != kWHK_mousemoved )
		// printf  "\t\tfHookPnSelResTable( %2d \t%s\t)  '%s'\r", s.eventCode,  pd(s.eventName,9), s.winName
		if ( s.eventCode == kWHK_move )									// This event also triggers if the panel is minimised to an icon or restored again to its previous state
			GetWindow     $s.WinName , wsize								// Get its current position		
			variable	bIsVisible	= ( V_left != V_right  &&  V_top != V_bottom )
			nvar		bCbState	= root:uf:evo:de:cbResSelTb0000				// Turn the 'Select Results' checkbox  ON / OFF  if the user maximised or minimised the panel by clicking the window's  'Restore size'  or  'Minimise' button [ _ ] .
			bCbState			= bIsVisible								// This keeps the control's state consistent with the actual state.
			// printf "\t\tfHookPnSelResTable( %2d \t%s\t)  '%s'\tV_left:%3d, V_Right:%3d, V_top:%3d, V_bottom:%3d -> bVisible:%2d  \r", s.eventCode,  pd(s.eventName,9), s.winName, V_left, V_Right, V_top, V_bottom, bIsVisible
		endif
	endif
End


Function		lbSelResPrProc_( s ) : ListBoxControl
// Dispatches the various actions to be taken when the user clicks in the Listbox. At the moment only mouse clicks and the state of the CTRL, ALT and SHIFT key are processed.
// at the moment the only action is colorising the listbox fields
// if ( s.eventCode == kLBE_MouseUp  )	// does not work here like it does in the data sections listbox ???
	struct	WMListboxAction &s
	wave	wFlags		= root:uf:evo:lb:wSRFlagsPr
	wave   /T	wTxt			= root:uf:evo:lb:wSRTxtPr
	string  	sPlaneNm		= "BackColors" 
	variable	pl			= FindDimLabel( wFlags, 2, sPlaneNm )
	variable	nOldState		= State( wFlags, s.row, s.col, pl )				// the old state

	// Convert the modifying key (e.g. 'Ctrl' ,  'Ctrl Alt / Alt Gr' ) to a state = color  (e.g. select for file, for print or for both )  
	//variable	nState		= Modifier2State( s.eventMod, lstMOD2STATE)	// NoModif:red:4:unused ,      Alt:green:2:Avg ,  Ctrl:1:blue:Tbl ,   AltGr:cyan:3:Tbl+Avg 
	variable	nState		= Modifier2State( s.eventMod, lstMOD2STATE1)	// NoModif:cyan:3:Tbl+Avg ,  Alt:green:2:Avg ,  Ctrl:1:blue:Tbl ,   AltGr:cyan:3:Tbl+Avg 

	// printf "\t\tlbSelResPrProc( s ) 1\trow:%2d\tcol:%2d  evCode:%2d\tevModif:%2d\toldstate:%2d -> %2d \r", s.row , s.col, s.eventCode, s.eventMod,  nOldState, nState

// weg 050901
//	// Design issue: One could alternatively stay in the same file  and only output a new header line, but this would probably be impossible or hard to read by EXCEL so we start a new file....
//	// This cell was not in TOFILE mode but has been set to TOFILE	||   this cell was in  TOFILE mode but the TOFILE mode has been turned off ..
//	if ( ( (nOldState & kRS_TOFILE) == 0  &&  nState & kRS_TOFILE)	||  ( ( nOldState & kRS_TOFILE  &&  ( nState & kRS_TOFILE ) == 0 ) ) )	
//		SaveTables()										// ...we need a new file as the column titles header will be invalid as there will be 1 more or 1 less item (or we need at least a new header line, see above)
//	endif

	// MOUSE : SET a cell. Click in a cell  in any row or column. Depending on the modifiers used, the cell changes state and color and stay in this state. It can be reset by shift clicking again or by globally reseting all cells.
	if ( s.eventCode == kLBE_MouseDown  &&  !( s.eventMod & kSHIFT ) )	// Only mouse clicks  without SHIFT  are interpreted here.  // ??? In this listbox only MouseDown is detected, whereas in the similar  DataSections  listbox  MouseUp  is detected???
		DSSet5( wFlags, s.row, s.row, s.col, pl, nState )				// sets flags .  The range feature is not used here so  begin row = end row .
		// printf "\t\tlbSelResPrProc( s ) 2\trow:%2d\tcol:%2d  evCode:%2d\tevModif:%2d\tstate:%2d =?=%2d  \r",  s.row, s.col,  s.eventCode, s.eventMod, nState, State( wFlags, s.row, s.col, pl )	
	endif
	// MOUSE :  RESET a cell  by  Shift Clicking
	if ( s.eventCode == kLBE_MouseDown  &&  ( s.eventMod & kSHIFT ) )	// Only mouse clicks  with    SHIFT  are interpreted here.  // ??? In this listbox only MouseDown is detected, whereas in the similar  DataSections  listbox  MouseUp  is detected???
		nState		= 0									// Reset a cell  
		DSSet5( wFlags, s.row, s.row, s.col, pl, nState )				// sets flags .  The range feature is not used here so  begin row = end row .
		// printf "\t\tlbSelResPrProc( s ) 3\trow:%2d\tcol:%2d  evCode:%2d\tevModif:%2d\tstate:%2d =?=%2d  \r",  s.row, s.col,  s.eventCode, s.eventMod, nState, State( wFlags, s.row, s.col, pl )	
	endif
End


static Function	/S	ListACVAllChansTable()
// Returns list of titles of  'All Currently Computed Values'  which depends on the number of regions, the number and types of the fits and on the latencies, but not yet on the listbox
	variable	ch
	variable	nChannels	= CfsChannels_()
	string 	lstACVAllCh	= ""
	for ( ch = 0; ch < nChannels; ch += 1 )
		lstACVAllCh	+= ListACVTable( ch )
	endfor
	 printf "ListACVAllChansTable()  has %d items \r", ItemsInList( lstACVAllCh )
	return	lstACVAllCh
End

Function	/S	ListACVTable( ch )
// Returns complete list of titles of  'All Currently Computed Values'  which depends on the number of regions, the number and types of the fits and on the latencies, but not yet on the listbox
	variable	ch
	variable	nRegs		= RegionCnt( ch )
	variable	rg
	string  	lstACV	= ""
	for ( rg = 0; rg < nRegs; rg += 1 )
		lstACV	+= ListACV1RegionTable_( ch, rg )
	endfor
	 printf "\t\tListACVTable( ch:%d )  Items:%3d,  '%s' ... '%s'   \r", ch, ItemsInList( lstACV ), lstACV[0,80],  lstACV[ strlen( lstACV )-80, strlen( lstACV )-1 ]  
	return	lstACV
End

Function	/S	ListACV1RegionTable_( ch, rg )
// Returns complete list of titles of  'All Currently Computed Values'  which depends on the number of regions, the number and types of the fits, but not yet on the listbox
	variable	ch, rg
	string  	lstACV	= ""
		lstACV	+= ListACVGeneralTable( ch, rg )
		lstACV	+= ListACVFit( ch, rg )
		lstACV	+= ListACVLat( ch, rg )
	// printf "\t\tListACVTable( ch:%d )  Items:%3d,  '%s' ... '%s'   \r", ch, ItemsInList( lstACV ), lstACV[0,80],  lstACV[ strlen( lstACV )-80, strlen( lstACV )-1 ]  
	return	lstACV
End


Function	/S	ListACVGeneralTable( ch, rg )
// Returns complete list of titles of the general (=Non-fit)  'All Currently Computed Values'  which depends on the number of regions, the number and types of the fits, but not yet on the listbox
	variable	ch, rg
	string  	sPostfx		= Postfix( ch, rg )
	string		lst			= ""
	variable	pt, nPts		= ItemsInList( klstEVL_PRINT )
	string  	lstPrintDetails	= ""								// the main value (Index:1) and possible subvalues e.g. beg Y value (index:4:kYB)  or end time (index:5:kTE)   
	variable	n, nDetails
	variable	nDetailIndex
	for ( pt = 0; pt < nPts; pt += 1 )
		lstPrintDetails	= RemoveWhiteSpace( StringFromList( pt, klstEVL_PRINT ) )								//
		nDetails		= ItemsInList( lstPrintDetails, "," )						// Assumption separator
		for ( n = 0; n < nDetails; n += 1 )
			nDetailIndex	= str2num( StringFromList( n, lstPrintDetails, "," ) )		// Assumption separator
			if ( numtype( nDetailIndex ) != kNUMTYPE_NAN )
				lst	= AddListItem( EvalNm( pt ) + StringFromList( nDetailIndex, klstE_POST ) + sPostfx, lst, ";", inf )				// the general values : base, peak, etc
			endif
		endfor
	endfor
	return	lst
End



Function	/S	ResultsFromLBAllChans( nMode, nAmount, nState )
	variable	nMode, nAmount, nState		
	variable	nChannels	= CfsChannels_()
	variable	ch
	string	  	sLine	   = ""
	for ( ch = 0; ch < nChannels; ch += 1 )
		sLine	  += ResultsFromLB( nMode, nAmount, nState, ch )
	endfor
	variable	len	= strlen( sLine )
	// printf "\t\tResultsFromLBAllChans() len:%4d \t'%s ... %s' \r", len, sLine[0, 70], sLine[len-70, inf]
	return	sLine
End


Function	/S	ResultsFromLB( nMode, nAmount, nState, ch )
//  If  'nAmout'  is kLB_SELECT  then returns list of  the  selected  results in the listbox. As the list determines the columns in the file  we include not only direct titles but also derive titles e.g.  'Peak_Y' , 'Peak_TE', ... 
//  If  'nAmout'  is     kLB_ALL	  then returns list of  all  the  results in the listbox. 
 // Returns 1 line of evaluated values or the column titles header line (depending on nMode ) . All regions are in 1 line. The column titles end with '_' and the channel digit and the region digit
// Handles  numbers  and  strings like File, Script, Date...
	variable	nMode, nAmount, nState, ch			
	variable	rg
	variable	nRegions	= RegionCnt( ch )
	wave /Z	wFlags	= root:uf:evo:lb:wSRFlagsPr
	wave/Z/T	wTxt		= root:uf:evo:lb:wSRTxtPr
	string  	sItem, sLine = ""
	if ( waveExists( wFlags )  &&  waveExists( wTxt ) )			// the waves necessary for printing exist only after the 'Select results panel' has been openend (by checking the checkbox control) 
		for ( rg = 0; rg < nRegions; rg += 1 )
			string  	lstResults	  = ExtractResults( wFlags, wTxt, nState, ch, rg, nAmount )	
			variable	r, nResults	  = ItemsInList( lstResults )
			variable	t
			variable	d, nDerived = ItemsInList( klstE_POST )			
			string  	sPostFix, sDirectTitle, sOneSelResult
			variable	len
			string  	lstAllFitResults 	= ListACVFit( ch, rg ) 								// e.g. for ch0 , rg0 and 2 fits  :  'Fit1_Fnc_00;Fit1_A0_00;....Fit2_Fnc_00;...
			string  	lstAllLatResults	= ListACVLat( ch, rg ) 								// e.g. ...........................................................for ch0 , rg0 and 2 fits  :  'Fit1_Fnc_00;Fit1_A0_00;....Fit2_Fnc_00;...
			variable	nEvlTitles	  	= ItemsInList( klstEVL_RESULTS )
			variable	nFitTitles		= ItemsInList( lstAllFitResults )
			variable	nLatTitles		= ItemsInList( lstAllLatResults )
			// printf "\t\tResultsFromLB(1\tch:%2d ) : Rg:%2d  nRes:%2d\tnTits:%3d\t'%s ...... %s' \r", ch, rg,  nResults, nEvlTitles, lstResults[0,100], lstResults[ strlen( lstResults)-80, inf]

			if ( nResults )

				for ( r = 0; r < nResults; r += 1 )											
					sOneSelResult	= StringFromList( r, lstResults )								// the selected results including direct results e.g. 'Peak'  AND derived results e.g. 'Peak_Y' , 'Peak_TE', ...and Fit results... 
					// printf "\t\tResultsFromLB(2\tch:%2d ) :\tr:%3d/%3d\t%s\r", ch, r, nResults, sOneSelResult

					// The results like Base, Peak, Rise
					for ( t = 0; t < nEvlTitles; t += 1 )											// all possible direct titles but no derived results
						sDirectTitle  = EvalNm( t ) 
						// printf "\t\tResultsFromLB(3a\tch:%2d ) :\tt:%3d/%3d\t %s\r", ch, t, nEvlTitles, sDirectTitle
						len		  = strlen( sDirectTitle )
						if ( cmpstr( sOneSelResult[ 0, len-1 ] , sDirectTitle ) == 0 )					// we found a selected  direct title  or  one of the derived titles (we stripped the 'derived' postfixes '_Y' , '_TE' , ...)  					
						// printf "\t\tResultsFromLB(4a\tst:%2d, ch:%2d ) :\t%s\r", nState, ch, sDirectTitle
							for ( d = 0; d < nDerived; d += 1 )	
								sPostFix	= StringFromList( d, klstE_POST )					// loop through all derived postfixes e.g.  '_Y' , '_TE' , ...
								if ( cmpstr( sOneSelResult, sDirectTitle + sPostFix ) == 0 )			// we found a selected  direct title (d=0)  or  one of the derived titles (d=1..6) and we now know by index 'd' which it is
								
									variable	bIsString
									if ( nMode == kCOL_TITLES_ )
										sprintf sItem, "%s", sOneSelResult + "_" + num2str( ch ) + num2str( rg ) + Eval_Unit__( ch, t, d )	// !!! Assumption naming  _ChRg ( and the units can be    '/' and ''  =  Peak/mV      or   '['  and  ']'   =  Peak[mV] )
									else
										bIsString	= str2num( StringFromList( t, klstEVL_IS_STRING ) )										
										if ( ! bIsString )
											sprintf sItem, "%g", Evalu( ch, rg, t, d ) * Eval_UnitFactor_( ch,  t, d )	// the numbers	
											//sprintf sItem,  "%s:%g  ", sOneSelResult, Evalu( ch, rg, t, d )		// the numbers	
										else
											sprintf sItem,  "%s", EvalString( ch, t )						// the few strings like Fi, Sc, DA  (File, Scipt and Date)
										endif
									endif
									// printf "\t\tResultsFromLB(6a\tst:%2d, ch:%2d ) :\tsItem: %s\r", nState, ch, sItem
									sLine	  += sItem + ";"

								endif
							endfor
						endif
					endfor				//  direct titles


					// THE  FITS
					for ( t = 0; t < nFitTitles; t += 1 )											// all possible fit titles (fit titles have no derived results)
						sDirectTitle  = StringFromList( t, lstAllFitResults ) 
						// printf "\t\tResultsFromLB(3b\tst:%2d, ch:%2d ) :\t%s\t%s\r", nState, ch, sOneSelResult, sDirectTitle
						if ( cmpstr( sOneSelResult, RemoveEnding( sDirectTitle, Postfix( ch, rg ) ) ) == 0 )	// We found a selected fit title in the list of all fit titles after stripping postfix  ( = '_ChRg' ) for the comparison
							// printf "\t\tResultsFromLB(4b\tst:%2d, ch:%2d ) :\trg:%2d\tt:%2d/%2d\t%s   \t%s\t \r", nState, ch, rg,  t , nFitTitles, sDirectTitle, sOneSelResult 


							variable 	fi 		= FitIndex( sOneSelResult ) 			//  Extract the phase / the index of the fit  e.g. 'Fit1_A2'  -> 1
							// Extract the index of the parameter. Approach1 (not taken): Compare names 'ParName( nFitFunc, nPar )' -> slow but does not depend on order
							// Extract the index of the parameter. Approach2: Use the known index 't'  and RELY ON ORDER IN ListACVFit() : 1. FitInfo, 2. Params, 3. StartParams
							variable	nFitFunc	= FitFnc( ch, rg, fi )					// 0=Line,  1=exp

							 if ( waveExists(  $FoParNm(  ch, rg, fi ) ) )		// true only after the first analysis has been made, false when only viewing data

								if ( nMode == kCOL_TITLES_ )
// 051110d
//									sprintf sItem, "%s", sOneSelResult + "_" + num2str( rg )	 + Fit_Unit_( ch, t, nFitFunc )				// !!! Assumption naming _Rg 
									sprintf sItem, "%s", sOneSelResult + "_" + num2str( ch ) + num2str( rg )	 + Fit_Unit_( ch, t, nFitFunc )	// !!! Assumption naming _ChRg 
								else
									// variable 	fi 	= FitIndex( sOneSelResult ) 			//  Extract the phase / the index of the fit  e.g. 'Fit1_A2'  -> 1
									//    Extract the index of the parameter. Approach1 (not taken): Compare names 'ParName( nFitFunc, nPar )' -> slow but does not depend on order
									//    Extract the index of the parameter. Approach2: Use the known index 't'  and RELY ON ORDER IN ListACVFit() : 1. FitInfo, 2. Params, 3. StartParams
									variable	Magnitude
									variable	nFitInfos	= FitInfoCnt()
									variable	pa, nPars	= ParCnt( nFitFunc )
									if ( t < nFitInfos )										// is Info : Extract  Info e.g.  Fit1_Fnc, Fit1_Beg, Fit2_Iter...
										pa		= t 
										sprintf sItem, "%g",  FitInfo( ch, rg, fi, pa ) 
										// printf "\t\tResultsFromLB(6b\tst:%2d, ch:%2d ) : rg:%2d   fi:%2d   ph:%2d   \tt:%2d/%2d  \tInfo:     %2d\t\t\t\t = \t%8g\t[-> %s] \r", nState, ch, rg, fi, fi +PH_FIT0, t, nFitTitles, pa,  FitInfo( ch, rg, fi, pa ), sItem 
									elseif ( t < nFitInfos + nPars )							// is Param

										pa		= t - nFitInfos
										Magnitude	= MagnitPar( nFitFunc, pa, ch )
										sprintf sItem, "%g",  FitPar( ch, rg, fi, pa ) / Magnitude
										// printf "\t\tResultsFromLB(6b\tst:%2d, ch:%2d ) : rg:%2d   fi:%2d   ph:%2d   \tt:%2d/%2d  \tPar:     %2d\t\t\t\t = \t%8g\t[-> %s] \r", nState, ch, rg, fi, fi +PH_FIT0, t, nFitTitles, pa,  FitPar( ch, rg, fi, pa ), sItem 
									elseif ( t < nFitInfos + 2 * nPars )							// is StartParam
										pa		= t - nFitInfos - nPars
										Magnitude	= MagnitPar( nFitFunc, pa, ch )
										sprintf sItem, "%g",  FitStPar( ch, rg, fi, pa ) / Magnitude 
										// printf "\t\tResultsFromLB(6b\tst:%2d, ch:%2d ) : rg:%2d   fi:%2d   ph:%2d   \tt:%2d/%2d  \tSTPar:%2d\t\t\t\t = \t%8g\t[-> %s] \r", nState, ch, rg, fi,  fi +PH_FIT0, t, nFitTitles, pa,  FitStPar( ch, rg, fi, pa ), sItem 
									else
										pa		= t - nFitInfos - 2 * nPars					// is Derived parameter
										Magnitude	= MagnitDer( nFitFunc, pa, ch )
										sprintf sItem, "%g",  FitDerivedPar( ch, rg, fi, pa ) / Magnitude 
										// printf "\t\tResultsFromLB(6b\tst:%2d, ch:%2d ) : rg:%2d   fi:%2d   ph:%2d   \tt:%2d/%2d  \tDerPar:%2d\t\t\t\t = \t%8g\t[-> %s] \r", nState, ch, rg, fi,  fi +PH_FIT0, t, nFitTitles, pa,  FitDerivedPar( ch, rg, fi, pa ), sItem 
	
									endif
								endif
							endif 		// fit par waves exist

							sLine	  += sItem + ";"
						endif
					endfor				//  fit titles	( Info, Params and StartParams )

					// THE  LATENCIES
					for ( t = 0; t < nLatTitles; t += 1 )											// all possible latency titles (latency titles have no derived results)
						sDirectTitle	   = StringFromList( t, lstAllLatResults ) 						// e.g. 'L0_R00B10_00'
						len		  = strlen( sDirectTitle )
						if ( cmpstr( sOneSelResult, RemoveEnding( sDirectTitle, Postfix( ch, rg ) ) ) == 0 )	// We found a selected latency title in the list of all latency titles after stripping postfix  ( = '_ChRg' ) for the comparison e.g. 'L0_R00B10'
							variable	la	   = LatNm2Nr( sDirectTitle )
							variable	LatVal  = LatValue( la ) * kLAT_SCALE_FACTOR		
							if ( nMode == kCOL_TITLES_ )
// 051109c
//								sprintf sItem, "%s", sOneSelResult + "_"  + Lat_Unit_()			// wrong!		  // !!! Assumption naming  (e.g.  L0_B00_P10  =Lat0 from BaseRise ch0 rg0  to  Peak ch1 rg0
								sprintf sItem, "%s", sOneSelResult + "_" + num2str( ch ) + num2str( rg ) + Lat_Unit_()// !!! Assumption naming  _ChRg (e.g.  L0_B00_P10_00  =Lat0 from BaseRise ch0 rg0  to  Peak ch1 rg0  to appear in ch0 rg0
							else
								sprintf sItem, "%g",  LatVal
							endif
							sLine	  += sItem + ";"

							// printf "\t\tResultsFromLB(8a\tamt:%d  st:%2d, ch:%2d )   rg:%2d  \tres:%3d /%3d\t%s\t t:%d/%d    la:%2d  %s :\tLatValue:%g  \r", nAmount, nState, ch, rg, r, nResults, pd(sOneSelResult,11), t, nLatTitles,  la, sDirectTitle, LatVal
						endif
					endfor

				endfor				// results
			endif					// nResults
		endfor				// regions
	endif
	// printf "\t\tResultsFromLB(ch:%d\t\tst:%2d  amount:%d ) \t-> items:%3d\t'%s .... %s' \r", ch, nState, nAmount, ItemsInList( sLine ), sLine[ 0, 60 ], sLine[ strlen( sLine ) - 60, inf ] 

	return	sLine
End

//====================================================================================================================================
// THE  SELECT RESULTS   DRAW   LISTBOX  PANEL			

static strconstant	ksCOL_SEP	= "~"	

Function		PanelRSUpdateDraw_()
// Build the huge  'Select result'  listbox allowing the user to select some results for printing, for the reduced file or for  latencies
// Code takes into account the various states (visible, hidden, moved, existant, not-yet-existant...) and handles all cases while avoiding unnecessary  killing and reseting of the panel and of the waves.
// Note: The position of the panel window is maintained  WITHOUT using StoreWndLoc() / RetrieveWndLoc() !!!
	nvar		bVisib		= root:uf:evo:de:cbResSelDr0000					// The ON/OFF state ot the 'Select Results' checkbox

	// 1. Construct the global string  'lstACVAllCh'  which contains all of the various evaluation and fitting values
	string  	lstACVAllCh	=  ListACVAllChansDraw() 

	// 2. Get the the text for the cells by breaking the global string  'lstACVAllCh'  which contains all of the various evaluation and fitting values
	variable	len, n, nItems	= ItemsInList( lstACVAllCh )	
	// printf "\t\t\tPanelRSUpdateDraw(a) lstACVAllCh has items:%3d\t '%s'   \r", nItems, lstACVAllCh[0,200]
	string 	sColTitle, lstColTitles	= "", lstColItems = ""
	variable	nExtractCh, ch = -1
	variable	nExtractRg, rg = -1 
	string 	sOneItemIdx, sOneItem
	for ( n = 0; n < nItems; n += 1 )
		sOneItemIdx	= StringFromList( n, lstACVAllCh )			// e.g. 'Base_010'
		len			= strlen( sOneItemIdx )
		sOneItem		= sOneItemIdx[ 0, len-4 ] 					// strip 3 indices + separator '_'  e.g. 'Base_010'  ->  'Base'
		nExtractCh	= str2num( sOneItemIdx[ len-2, len-2 ] )			// !!! Assumption : ACV naming convention
		nExtractRg	= str2num( sOneItemIdx[ len-1, len-1 ] )			// !!! Assumption : ACV naming convention
		if ( ch != nExtractCh )									// Start new channel
			ch 		= nExtractCh
 			rg 		= -1 
		endif
		if ( rg != nExtractRg )									// Start new region
			rg 		= nExtractRg
			sprintf sColTitle, "Ch%2d Rg%2d", ch, rg
			lstColTitles	= AddListItem( sColTitle, lstColTitles, ksCOL_SEP, inf )
			lstColItems	+= ksCOL_SEP
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
	// printf "\t\t\tPanelRSUpdateDraw(b)\tlstACVAllCh has items:%3d -> rows:%3d  cols:%2d\tColT: '%s'\tColItems: '%s...' \r", nItems, nRows, nCols, lstColTitles, lstColItems[0, 100]


	// 4. Compute panel size . The y size of the listbox and of the panel  are adjusted to the number of listbox rows (up to maximum screen size) 
	variable	xSize		= nCols * 75								// Adjust when column width changes. 75 is minimum needed to display the column title completely e.g. 'Ch 1 Rg 0'
	variable	ySizeMax	= GetIgorAppPixelY() -  kMAGIC_Y_MISSING_PIXEL	// Here we could subtract some Y pixel if we were to leave a bottom region not covered by a larges listbox.
	variable	ySizeNeed	= nRows * kLB_CELLY + kLB_ADDY				// We build a panel which will fit entirely on screen, even if not all listbox line fit into the panel...
	variable	ySize		= min( ySizeNeed , ySizeMax ) 					// ...as in this case Igor will automatically supply a listbox scroll bar.
			ySize		=  trunc( ( ySize -  kLB_ADDY ) / kLB_CELLY ) * kLB_CELLY + kLB_ADDY	// To avoid partial listbox lines shrink the panel in Y so that only full-height lines are displayed
	
	// 5. Draw  panel and listbox
	if ( bVisib )													// Draw the SelectResultsPanel and construct or redimension the underlying waves  ONLY IF  the  'Select Results' checkbox  is  ON

		string  	sWin	= "PnSelResDr"
		if (  WinType( sWin ) != kPANEL )							// Draw the SelectResultsPanel and construct the underlying waves  ONLY IF  the panel does not yet exist
			// Define initial panel position.
			NewPanel1( sWin, kRIGHT, 0, xSize, kBOTTOM, 0, ySize, kKILL_DISABLE, "Draw Results" )	// We must disable killing as this would destroy any selection in the listbox, but minimising is allowed.

			SetWindow	$sWin,  hook( SelRes ) = fHookPnSelResDraw_
			ModifyPanel /W=$sWin, fixedSize= 1						// prevent the user to maximize or close the panel by disabling these buttons

			// Create the 2D LB text wave	( Rows = maximum of results in any ch/rg ,  Columns = Ch0 rg0; Ch0 rg1; ... )
			make  /O 	/T 	/N = ( nRows, nCols )		root:uf:evo:lb:wSRTxtDr	= ""	// the LB text wave
			wave   	/T		wSRTxt		     =	root:uf:evo:lb:wSRTxtDr
		
			// Create the 3D LB flag wave. 	Rows x Columns (as above)  x 3  : last index 0 is flags, 1 is fore- or background color, 2 is the remaining color 
			make   /O	/B  /N = ( nRows, nCols, 3 )	root:uf:evo:lb:wSRFlagsDr	// byte wave is sufficient for up to 254 colors 
			wave   			wSRFlags		    = 	root:uf:evo:lb:wSRFlagsDr
			
			// Create color table withs rows and columns exchanged. 3 rows, n columns is easier to read as n columns, 3 rows but must be transposed before Igor can use them.
			// At the moment these colors are the same as in the  DataSections  listbox
			//								black		blue			red			magenta			grey			light grey			green			yellow				
// Version1: (works but wrong colors)
//			make   /O	/W /U	root:uf:evo:lb:wSRColorsPr= { {0, 0, 0 }, { 0, 0, 65535 },  { 65535, 0, 0 },  {40000,0,48000}, {44000,44000,44000},  {54000,54000,54000},  { 0, 50000, 0} ,   { 0, 56000, 56000 },  {65280,59904,48896} }	// order must be same as defined by constants above
//			wave	wSRColorsPr 	= root:uf:evo:lb:wSRColorsPr 		
//			MatrixTranspose 				  wSRColorsPr			// the same table is used for foreground and background. 	Igor requires  n  rows, 3 columns 
//			EvalColors( wSRColorsPr )								// 051108  

// Version2: (works...)
			make /O	/W /U /N=(128,3) 	   root:uf:evo:lb:wSRColorsDr 		
			wave	wSRColorsDr	 	= root:uf:evo:lb:wSRColorsDr 		
			EvalColors( wSRColorsDr )								// 051108  

		
			// Link the  indices  of  Foreground  and  Background  colors  to  their name strings which are later used to access the layer where the color is to be set
			variable	planeFore	= 1
			variable	planeBack	= 2
			SetDimLabel 2, planeBack,  $"backColors"	wSRFlags
			SetDimLabel 2, planeFore,   $"foreColors"	wSRFlags
	
		else													// The panel DOES exist. It may be minimised to an icon or it may be hidden behind other panels. If it is hidden then the checkbox must be actuated twice: hide and then restore panel to make it visible
			MoveWindow /W=$sWin	1,1,1,1						// Restore previous size and position. This does NOT take into account that the panel size may have changed in the meantime due to more or less columns or rows

			MoveWindow1( sWin, kRIGHT, 0, xSize, kBOTTOM, 0, ySize )	// Extract previous panel position and size. Keep only position and discard size as the size may have changed in the meantime due to more or less columns or rows.

			wave   	/T		wSRTxt			= root:uf:evo:lb:wSRTxtDr
			wave   			wSRFlags		  	= root:uf:evo:lb:wSRFlagsDr
			Redimension	/N = ( nRows, nCols )		wSRTxt
			Redimension	/N = ( nRows, nCols, 3 )	wSRFlags
		endif

		// Set the column titles in the SR text wave, take the entries as computed above
		for ( c = 0; c < nCols; c += 1 )
			SetDimLabel 1, c, $StringFromList( c, lstColTitles, ksCOL_SEP ), wSRTxt	// 1 is columns
		endfor

		// Fill the listbox columns with the appropriate  text
		variable	r
		for ( c = 0; c < nCols; c += 1 )
			lstItemsInColumn  = StringFromList( c, lstColItems, ksCOL_SEP )	
			for ( r = 0; r < ItemsInList( lstItemsInColumn ); r += 1 )
				wSRTxt[ r ][ c ]	= StringFromList( r, lstItemsInColumn )				// set the text 
			endfor
			for ( r = ItemsInList( lstItemsInColumn ); r < nRows; r += 1 )
				wSRTxt[ r ][ c ]	= ""									// clear the text in the last rows if another column has more rows 
			endfor
		endfor
	
		// Build the listbox which is the one and only panel control 
		// stale BP 2  : set 2 BPs in the next 2 lines. Run until  Igor stops at the 2. BP ( the 1. will.be skipped ).  Try to continue with  ESC....NO stale BP here.

		ListBox 	  lbSelectResult,    win = PnSelResDr, 	pos = { 2, 0 },  size = { xSize, ySize + kLB_ADDY },  frame = 2
		ListBox	  lbSelectResult,    win = PnSelResDr, 	listWave 			= root:uf:evo:lb:wSRTxtDr
		ListBox 	  lbSelectResult,    win = PnSelResDr, 	selWave 			= root:uf:evo:lb:wSRFlagsDr,  editStyle = 1
		ListBox	  lbSelectResult,    win = PnSelResDr, 	colorWave		= root:uf:evo:lb:wSRColorsDr
		// ListBox 	  lbSelectResult,    win = PnSelResDr, 	mode 			 = 4// 5			// ??? in contrast to the  DataSections  panel  there is no mode setting required here ???
		ListBox 	  lbSelectResult,    win = PnSelResDr, 	proc 	 			 = lbSelResDrawProc_

	endif		// bVisible : state of 'Select results panel' checkbox is  ON 
End


Function		PanelRSHideDraw_()
	printf "\t\t\tfPanelRSHideDraw()    \r"
	string  	sWin	= "PnSelResDr"
	if (  WinType( sWin ) == kPANEL )						// check existance of the panel. The user may have killed it by clicking the panel 'Close' button 5 times in fast succession
		MoveWindow 	/W=$sWin   0 , 0 , 0 , 0				// hide the window by minimising it to an icon
	endif
End



Function 		fHookPnSelResDraw_( s )
// The window hook function of the 'Select results panel' detects when the user minimises the panel by clicking on the panel 'Close' button and adjusts the state of the 'select results' checkbox accordingly
	struct	WMWinHookStruct &s
	if ( s.eventCode != kWHK_mousemoved )
		// printf  "\t\tfHookPnSelResDraw( %2d \t%s\t)  '%s'\r", s.eventCode,  pd(s.eventName,9), s.winName
		if ( s.eventCode == kWHK_move )									// This event also triggers if the panel is minimised to an icon or restored again to its previous state
			GetWindow     $s.WinName , wsize								// Get its current position		
			variable	bIsVisible	= ( V_left != V_right  &&  V_top != V_bottom )
			nvar		bCbState	= root:uf:evo:de:cbResSelDr0000				// Turn the 'Select Results' checkbox  ON / OFF  if the user maximised or minimised the panel by clicking the window's  'Restore size'  or  'Minimise' button [ _ ] .
			bCbState			= bIsVisible								// This keeps the control's state consistent with the actual state.
			// printf "\t\tfHookPnSelResDraw( %2d \t%s\t)  '%s'\tV_left:%3d, V_Right:%3d, V_top:%3d, V_bottom:%3d -> bVisible:%2d  \r", s.eventCode,  pd(s.eventName,9), s.winName, V_left, V_Right, V_top, V_bottom, bIsVisible
		endif
	endif
End

Function		lbSelResDrawProc_( s ) : ListBoxControl
// Dispatches the various actions to be taken when the user clicks in the Listbox. At the moment only mouse clicks and the state of the CTRL, ALT and SHIFT key are processed.
	struct	WMListboxAction &s
	wave	wFlags		= root:uf:evo:lb:wSRFlagsDr
	wave   /T	wTxt			= root:uf:evo:lb:wSRTxtDr
	string  	sPlaneNm		= "BackColors" 
	variable	pl			= FindDimLabel( wFlags, 2, sPlaneNm )
	variable	nState		= State( wFlags, s.row, s.col, pl )					// the old state
	// printf "\t\tlbSelResDrawProc( s ) 1\trow:%2d\tcol:%2d  evCode:%2d\tevModif:%2d\tstate:%2d  \r", s.row , s.col, s.eventCode, s.eventMod,  nState

	// MOUSE : SET a cell. Click in a cell  in any row or column. Depending on the modifiers used, the cell changes state and color and stay in this state. It can be reset by shift clicking again or by globally reseting all cells.
	// if ( s.eventCode == kLBE_MouseUp  &&  !( s.eventMod & kSHIFT ) )	// does not work here ??? In this listbox only MouseDown is detected, whereas in the similar  DataSections  listbox  MouseUp  is detected???
	if ( s.eventCode == kLBE_MouseDown  &&  !( s.eventMod & kSHIFT ) )	// Only mouse clicks  without SHIFT  are interpreted here.  

		// Version1 : Ignore any modifying key (e.g. 'Ctrl' ,  'Ctrl Alt / Alt Gr' ) which is appropriate for the Draw results selection. The user can press any modifier key and the same state (and the same cell color will result)
		// This code is appropriate when only one actions is to be executed. The state assigned here must correspond to the state which is checked in 'SelectedResultsDraw()' . Only the color matters here.
		nState		= kSTDRAW_EVALUATED
		// Version2 : Convert the modifying key (e.g. 'Ctrl' ,  'Ctrl Alt / Alt Gr' ) to a state = color  (e.g. select for file, for print or for both )  
		// This code is required when one of multiple actions (depending on the modifier key pressed) is to be executed, like it is done for the Print results selection
		//  nState		= Modifier2State( s.eventMod, lstMOD2STATE )	

		DSSet5( wFlags, s.row, s.row, s.col, pl, nState )				// sets flags .  The range feature is not used here so  begin row = end row .
		// printf "\t\tlbSelResDrawProc( s ) 2\trow:%2d\tcol:%2d  evCode:%2d\tevModif:%2d\tstate:%2d =?=%2d  \r",  s.row, s.col,  s.eventCode, s.eventMod, nState, State( wFlags, s.row, s.col, pl )	
	endif
	// MOUSE :  RESET a cell  by  Shift Clicking
	if ( s.eventCode == kLBE_MouseDown  &&  ( s.eventMod & kSHIFT ) )	// Only mouse clicks  with    SHIFT  are interpreted here.  // ??? In this listbox only MouseDown is detected, whereas in the similar  DataSections  listbox  MouseUp  is detected???
	// if ( s.eventCode == kLBE_MouseUp  &&  ( s.eventMod & kSHIFT ) )	// does not work here ???
		nState		= 0									// Reset a cell  
		DSSet5( wFlags, s.row, s.row, s.col, pl, nState )				// sets flags .  The range feature is not used here so  begin row = end row .
		// printf "\t\tlbSelDRResProc( s ) 3\trow:%2d\tcol:%2d  evCode:%2d\tevModif:%2d\tstate:%2d =?=%2d  \r",  s.row, s.col,  s.eventCode, s.eventMod, nState, State( wFlags, s.row, s.col, pl )	
	endif
End


Function	/S	ListACVAllChansDraw()
// Returns list of titles of  'All Currently Computed Values'  which depends on the number of regions. It does not depend on the number and types of the fits  and  on the latencies as these values cannot be drawn.
	variable	ch
	variable	nChannels	= CfsChannels_()
	string 	lstACVAllCh	= ""
	for ( ch = 0; ch < nChannels; ch += 1 )
		lstACVAllCh	+= ListACVDraw( ch )
	endfor
	//printf "ListACVAllChansDraw()  has %d items \r", ItemsInList( lstACVAllCh )
	return	lstACVAllCh
End

Function	/S	ListACVDraw( ch )
// Returns complete list of titles of  'All Currently Computed Values'  which depends on the number of regions.  It does not depend on the number and types of the fits  and  on the latencies as these values cannot be drawn.
	variable	ch
	variable	nRegs	 = RegionCnt( ch )
	variable	rg
	string  	lstACV	= ""

	for ( rg = 0; rg < nRegs; rg += 1 )
		lstACV	+= ListACVGeneralDraw( ch, rg )
// 051007 we cannot draw fit results (but we might allow turning the fitted results on and off...) 
//		lstACV	+= ListACVFit( ch, rg )
	endfor
	 printf "\t\tListACVDraw( ch:%d )  Items:%3d,  '%s' ... '%s'   \r", ch, ItemsInList( lstACV ), lstACV[0,80],  lstACV[ strlen( lstACV )-80, strlen( lstACV )-1 ]  
	return	lstACV
End

Function	/S	Postfix( ch, rg )
	variable	ch, rg
	return	"_" + num2str( ch ) + num2str( rg )								// !!! Assumption : ACV naming convention
End

Function	/S	ListACVGeneralDraw( ch, rg )
	variable	ch, rg
	string  	sPostfx	= Postfix( ch, rg )
	string		lst	= ""
	variable	shp, pt, nPts	= ItemsInList( klstEVL_RESULTS )
	for ( pt = 0; pt < nPts; pt += 1 )
		shp	= str2num( StringFromList( pt, klstEVL_SHAPES ) )					// 
		if ( numtype( shp ) != kNUMTYPE_NAN ) 								// if the shape entry is not empty it must be drawn
			lst	= AddListItem( EvalNm( pt ) + sPostfx, lst, ";", inf )					// the general values : base, peak, etc
		endif
	endfor
	return	lst
End


Function	/S	SelectedResultsDraw( nState, ch, rg )
	variable	nState, ch, rg
	wave /Z	wFlags			= root:uf:evo:lb:wSRFlagsDr
	wave/Z/T	wTxt				= root:uf:evo:lb:wSRTxtDr
	string  	lstResultIndices = "", lstResultNames = ""
	if ( waveExists( wFlags )  &&  waveExists( wTxt ) )			// the waves necessary for printing exist only after the 'Select results panel' has been openend (by checking the checkbox control) 
		string		lstResults	= ExtractResults( wFlags, wTxt, nState, ch, rg, kLB_SELECT ) 
		variable	r, nResults	= ItemsInList( lstResults )
		variable	t, nTitles	= ItemsInList( klstEVL_RESULTS )
		string  	sOneResult
		variable	nIndex
		if ( nResults )
	 		// printf "\t\tSelectedResultsDraw 1( nState:%2d, ch:%2d, rg:%2d )  nRes:%2d\tnTits:%3d\t\t\t\t\t\t\t\t\t\t'%s...' \r", nState, ch, rg, nResults, nTitles, lstResults[0,200]
			for ( r = 0; r < nResults; r += 1 )											
				sOneResult	= StringFromList( r, lstResults )							// includes direct results e.g. 'Peak'  and  derived results e.g. 'Peak_Y' , 'Peak_TE', ... 

				nIndex	= WhichListItemIgnoreWhiteSpace( sOneResult, klstEVL_RESULTS )

				if ( nIndex != kNOTFOUND )
					lstResultIndices	= AddListItem( num2str( nIndex ), lstResultIndices, ";", inf )
					lstResultNames	= AddListItem( sOneResult, 	lstResultNames, ";", inf )
					// printf "\t\tSelectedResultsDraw 2( nState:%2d, ch:%2d, rg:%2d )  nRes:%2d\tnTits:%3d\tfound Idx:%3d\t%s\t-> %s\t'%s...' \r", nState, ch, rg, nResults, nTitles, nIndex, pd( sOneResult,6), pd( lstResultIndices, 10 ), lstResults[0,200]
				endif
			endfor
			// printf "\t\tSelectedResultsDraw 3(\tSt:%2d, ch:%2d, rg:%2d )  nRes:%2d\tnTits:%3d\tfound -> %s\t%s\t<- '%s...' \r", nState, ch, rg, nResults, nTitles, pd( lstResultIndices, 10 ), lstResultNames[0,60], lstResults[0,60]
		endif
	endif
	return	lstResultIndices
End

//====================================================================================================================================
// THE  SELECT RESULTS  LISTBOX  PANELS  ( e.g. DRAW , PRINT )	: COMMON  FUNCTIONS			

//Function 		Tst()
//End


Function	/S	ExtractResults( wFlags, wTxt, nState, ch, rg, nAmount ) 
//  If  'nAmout'  is kLB_SELECT  then extract all selected results with a certain  'nState' , 'ch'  and  'rg'  from the listbox.  nState is a bit combination e.g. 3 will extract 1 and 2 .
//  If  'nAmout'  is 	kLB_ALL	     then extract all selected results with a certain  'ch'  and  'rg'  from the listbox independent of the state. 
//  For this to work the listbox panel must never be closed, but it can be minimised.
//  nState  is a bit combination and can be  1,  2,  1+2=3  or 4.   The unselected state=0 is not returned.  Returns list without channel / region postfix  e.g.  'Ch;Ev;Base;Fit1_A0;...' 
	variable	nState, ch, rg, nAmount
	wave	wFlags	
	wave   /T	wTxt		
	// Build the string containing the current state of the listbox. 
	string 	lstSelectResults		= ExtractResultsAnyChRg( wFlags, wTxt, nState, nAmount ) // e.g.  'Base_01;Fit1_Beg_11;....'
	string		lstResultsInStateChRg= ""
	string		sOneItem
	variable	len, n, nItems		= ItemsInList( lstSelectResults )				// e.g.  'Base_01;Fit1_Beg_11;....'
	variable	nExtrCh, nExtrRg
	for ( n = 0; n < nItems; n += 1 )
		sOneItem	= StringFromList( n, lstSelectResults )						// e.g.  'Base_01'			!!! Assumption separator ';'
		len		= strlen( sOneItem )
		nExtrCh	= str2num( sOneItem[ len-2, len-2 ] )						// e.g.  0					!!! Assumption ACV naming convention
		nExtrRg	= str2num( sOneItem[ len-1, len-1 ] )						// e.g.  1					!!! Assumption ACV naming convention
		if ( ch == nExtrCh  &&  rg == nExtrRg )
			sOneItem	= sOneItem[ 0, len-4 ]								// e.g.  'Base_01'  ->  'Base'	
			lstResultsInStateChRg	+= sOneItem + ";"					//						!!! Assumption separator ';'
		endif
	endfor
	// printf "\t\tExtractResults( ch:%d rg:%d\tst:%2d  amount:%d )\t-> items:%3d\t'%s...'  -->  '%s .... %s' \r", ch, rg, nState, nAmount, ItemsInList( lstResultsInStateChRg ), lstSelectResults[0,60],  lstResultsInStateChRg[ 0, 60 ], lstResultsInStateChRg[ strlen( lstResultsInStateChRg ) - 60, inf ] 
	return	lstResultsInStateChRg
End

static  Function	/S	ExtractResultsAnyChRg( wFlags, wTxt, nState, nAmount ) 
// Extract and returns all  results with a certain  'nState'  independent of  'ch'  and  'rg'  from the listbox.  'ch'  and  'rg'  are appended as postfix  e.g.  'Base_01;Fit1_Beg_11;....'
	wave	wFlags
	wave   /T	wTxt
	variable	nState, nAmount
	string 	lstSelectResults	= ""
	string  	sPlaneNm		= "BackColors" 
	variable	pl			= FindDimLabel( wFlags, 2, sPlaneNm )
	variable	row, nRows	= DimSize( wFlags, 0 )
	variable	col, nCols		= DimSize( wFlags, 1 )
	string  	sColTitle	= "???"
	variable	ch, rg
	for ( col = 0; col <  nCols; col += 1 )
		sColTitle	= GetDimLabel( wTxt, 1, col )			// 1 means columns
		sscanf sColTitle, "Ch %d Rg %d", ch, rg			// !!! Assumption  ACV naming convention
		// printf "\t\tExtractResultsAnyChRg() col:%2d  ->  ColLabel:'%s'  -> ch:%2d  rg:%2d  \r", col, sColTitle, ch, rg
		for ( row = 0; row <  nRows; row += 1 )
			// Depending on 'nAmount' check the state and return only matching states     OR   return every listbox item as long as it is not empty, which happens if some columns may have fewer rows than others
			if ( ( nAmount == kLB_SELECT  &&  ( nState & State( wFlags, row, col, pl ) ) )  ||  nAmount == kLB_ALL  &&  strlen( wTxt[ row ][ col ] )  )	
				lstSelectResults +=	wTxt[ row ][ col ] + "_" + num2str( ch ) + num2str( rg ) + ";"	//!!! Assumption separators
			endif
		endfor
	endfor
	// printf "\t\tExtractResultsAnyChRg(\tst:%2d  amount:%d ) -> items:%2d\t'%s .... %s' \r", nState, nAmount, ItemsInList( lstSelectResults ), lstSelectResults[0, 60] ,  lstSelectResults[ strlen( lstSelectResults ) - 60 , inf ]
	return	lstSelectResults	
End


Function		WhichListItemIgnoreWhiteSpace( sItem, lst )
// Similar to 'WhichListItem()'  but ignores leading blanks and tabs in the item of 'lst' , which improve readability of  'lst' in conjunction with other list linked through the list index.  
	string  	sItem, lst
	string	 	sListItem
	variable	n, nItems 	= ItemsInList( lst )
	for ( n = 0; n < nItems; n += 1 )
		sListItem	= RemoveLeadingWhiteSpace( StringFromList( n, lst ) )
		if ( cmpstr( sItem, sListItem ) == 0 )
			return	n
		endif
	endfor
	return	kNOTFOUND
End

//---------------------  Naming convention for fitted parameters ------------------------------------------------------------
//  How the names of the fitted parameters appear in the results textbox, in the result selection listbox and in the header of the result table and of the result file

strconstant	ksFITPREFIX		= "F"		// e.g.  "F" , "Fi" , "Fit"	

static Function		FitIndex( sResult )
	string  	sResult					// e.g. 'Fit1_A0'	-> 1
	variable	len	= strlen( ksFITPREFIX )
	return	str2num( sResult[ len, len ] )	// 			-> 1
End

static Function	/S	FitPrefix( nIndex )
	variable	nIndex
	return	ksFITPREFIX + num2str( nIndex ) + "_"		
End
//---------------------------------------------------------------------------------------------------------------------------------------------------

Function	/S	ListACVFit( ch, rg )
// Returns list of all FitParameters, FitStartParameters and FitInfoNumbers (e.g. nIter, ChiSqr)  for the fit function specified by channel and region 
// !!! Cave: If this order (=Info, Params, StartParams) is changed the extraction algorithm ( = ResultsFromLB() ) must also be changed 
	variable	ch, rg
	variable	fi, nFits	=  ItemsInList( ksPHASES ) - PH_FIT0
	variable	nFitInfo, pa, nPars
	string  	lst		= ""	
	string  	sPreFix
	for ( fi = 0; fi < nFits; fi += 1 )
		nvar		bFit		= $"root:uf:evo:de:cbFit" + num2str( ch ) + num2str( rg )  + num2str( fi ) + "0"	
		if ( bFit )
			variable	nFitInfos	= FitInfoCnt()
			variable	nFitFunc	= FitFnc( ch, rg, fi )
			for ( nFitInfo = 0; nFitInfo < nFitInfos; nFitInfo += 1 )										// the fixed fit values: FitFnc, FitBeg, Iterations, etc
				lst	= AddListItem( FitInfoInLBNm( ch, rg, fi, nFitInfo ), lst, ";", inf )
			endfor
			nPars	= ParCnt( nFitFunc )					
			for ( pa = 0; pa < nPars; pa += 1 )				// the fit  parameters: 	  A0, T0, A1, T12,  Constant, Slope etc.-> Fit1_A0, Fit1_T0...
				lst	= AddListItem( FitParInLBNm( ch, rg, fi, pa, nFitFunc ),  lst, ";" , inf )			// e.g. 'Fit1_A0_00'
			endfor
			for ( pa = 0; pa < nPars; pa += 1 )				// the start parameters: A0, T0, A1, T12,  Constant, Slope  all with '_S'  etc. 
				lst	= AddListItem( FitSTParInLBNm( ch, rg, fi, pa, nFitFunc ),  lst, ";" , inf )			// e.g. 'Fit1_A0_S_00'
			endfor
			variable nDerived = DerivedCnt( nFitFunc )
			for ( pa = 0; pa < nDerived; pa += 1 )				// the derived parameters: wTau, Capacitance, ...
				lst	= AddListItem( FitDerivedInLBNm( ch, rg, fi, pa, nFitFunc ),  lst, ";" , inf )			// e.g. 'Fit1_WTau_00'
			endfor
		endif
	endfor
	// printf "\t\tListACVFit(\tch:%2d, rg:%2d )\treturns lst: '%s'  \r", ch, rg, lst[0,200]
	return	lst
End	

//-----------------------------------------------  Naming convention : The fit titles in the listbox   -------------------------------------------------------
// The fit titles built here still contain the channel/region postfix, which is dropped later when the titles are actually displayed in the listbox
Function	/S	FitInfoInLBNm( ch, rg, fi, nFitInfo )
	variable	ch, rg, fi, nFitInfo
	string  	sNm		= FitPrefix( fi ) + FitInfoNm( nFitInfo ) + Postfix( ch, rg )
	return	sNm
End

Function	/S	FitParInLBNm( ch, rg, fi, par, nFitFunc )
	variable	ch, rg, fi, par, nFitFunc
	string  	sNm		= FitPrefix( fi ) + ParName( nFitFunc, par ) + Postfix( ch, rg )		// The fit  parameters:   A0, T0, A1, T12,  Constant, Slope etc.-> Fit1_A0.., Fit1_T0...
	return	sNm
End

Function	/S	FitSTParInLBNm( ch, rg, fi, par, nFitFunc )
	variable	ch, rg, fi, par, nFitFunc
	string  	sNm		= FitPrefix( fi ) + ParName( nFitFunc, par ) +"_S" + Postfix( ch, rg )	// The start parameters:   A0, T0, A1, T12,  Constant, Slope etc.-> Fit1_A0_S..., Fit1_T0_S....
	return	sNm
End

Function	/S	FitDerivedInLBNm( ch, rg, fi, par, nFitFunc )
	variable	ch, rg, fi, par, nFitFunc
	string  	sNm		= FitPrefix( fi ) + DerName( nFitFunc, par ) + Postfix( ch, rg )		// The derived parameters:  WTau, Cap  etc.	-> Fit1_WTau..., Fit1_Cap...
	return	sNm
End


//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//  LATENCIES
static strconstant ksLAT_BASENM		= "L"  	// "L"  ,  "La"  or  "Lat"	
static strconstant ksLAT_SEPAR		= "_"  	// ""   or   "_" 
static constant	  kLAT_DESC_LENGTH	= 1		// Can be 1 or 2 .   2 will give  'ma BR R5 Pk D5'   .  1 will give  'm B R P D'

static Function	/S	ListACVLat( nThisCh, nThisRg )
// Returns list of all latencies specified by channel and region (the end value determines the channel and region)
// We need 2 steps because the latency index  and  BegEnd   are not ordered in respect to channel and region
	variable	nThisCh, nThisRg
	variable	nChannels	= CfsChannels_()
	string  	lst		= ""	
	variable	BegEnd, lc, LatCnt	= LatencyCnt() 
	variable	ch, rg, rgCnt, nLatOp	
	string  	sLatOp

	make /O /T /N=( nChannels, kRG_MAX, LatCnt, 2 )  root:uf:evo:lb:wTmpLatNames = ""
	wave      /T  wTmpLatNames =  root:uf:evo:lb:wTmpLatNames

	// Step 1: Store all extracted  popupmenu settings in a 4 dim temporary wave. Only after this pass we can be sure that all settings are valid. 
	for ( lc = 0; lc < LatCnt; lc += 1 )
		for ( BegEnd = CN_BEG; BegEnd <=  CN_END; BegEnd += 1 )
			for ( ch = 0; ch < nChannels; ch += 1)
				rgCnt	= RegionCnt( ch )
				for ( rg = 0; rg < rgCnt;  rg += 1 )	
					nLatOp	= LatC( ch, rg, lc, BegEnd )
					sLatOp	= StringFromList( nLatOp, klstLATC_ )
					if ( nLatOp != kLAT_OFF_ )
						wTmpLatNames[ ch ][ rg ][ lc ][ BegEnd ] = LatNm( lc, BegEnd, ch, rg ) 
						// printf "\t\tListACVLat( a  ch:%d, rg:%d )\tlat:%2d/%2d\t  ch:%d   rg:%d\t%s\tLatOp:%2d\t(%s) \tLatNm:%s\t  \r", nThisCh, nThisRg, lc, LatCnt, ch, rg,  SelectString( BegEnd, "Beg:    " , "  -> End:" ), nLatOp, sLatOp, pd(wTmpLatNames[ ch ][ rg ][ lc ][ BegEnd ] ,12)
					endif
				endfor
			endfor
		endfor
	endfor
	
	// Step 2: Only after all extracted  popupmenu settings have been stored  in a 4 dim temporary wave we can extract them from there in any order.
	for ( lc = 0; lc < LatCnt; lc += 1 )
		for ( BegEnd = CN_BEG; BegEnd <=  CN_END; BegEnd += 1 )
			for ( ch = 0; ch < nChannels; ch += 1)
				rgCnt	= RegionCnt( ch )
				for ( rg = 0; rg < rgCnt;  rg += 1 )	
					lst  += wTmpLatNames[ ch ][ rg ][ lc ][ BegEnd ] 	// most of them are empty strings  
					// printf "\t\tListACVLat( b  ch:%d, rg:%d )\tlat:%2d/%2d\t  ch:%d   rg:%d\t%s\tlst: '%s' \t  \r", nThisCh, nThisRg, lc, LatCnt, ch, rg,  SelectString( BegEnd, "Beg:    " , "  -> End:" ), lst[0,200]
				endfor
			endfor
		endfor
		lst  +=  PostFix( nThisCh, nThisRg ) + ";"			//  add the list delimiter 
	endfor

	KillWaves  root:uf:evo:lb:wTmpLatNames
	// printf "\t\tListACVLat( c  ch:%d, rg:%d )\tlat:%2d/%2d\t lst: '%s' \r", nThisCh, nThisRg, lc, LatCnt,  lst[0,200]
	return	lst
End	


Function		LatencyCnt() 
	return	PH_LATC2 - PH_LATC0 + 1		// !!!  adjust if we have more or less than 3 latency cursors
End

Function	/S	LatNm( lc, BegEnd, ch, rg )
	variable	lc, BegEnd, ch, rg
	variable	nLatOp	= LatC( ch, rg, lc, BegEnd )
	string		sLatOp	= StringFromList( nLatOp, klstLATC_ )
	// e.g. for the begin  'Lat1m01'  and for the end  'R22'  , must be catenated elsewhere!
	return	SelectString( BegEnd, ksLAT_BASENM + num2str( lc ) + ksLAT_SEPAR + sLatOp[ 0, kLAT_DESC_LENGTH-1 ] + num2str( ch ) + num2str( rg ), sLatOp[ 0, kLAT_DESC_LENGTH-1 ] + num2str( ch ) + num2str( rg ) )	
End

Function		LatNm2Nr( sLatNm )
// Extracts the latency index (at the moment limited to 0, 1 or 2 because of panel size but could be more) from the latency name (e.g. 1 from  'Lat1m02R22'   or  0 from 'L0ma12Pk21' 
	string  	sLatNm
	variable	len	= strlen( ksLAT_BASENM )
	return	str2num( sLatNm[ len, len ] )
End

Function		LatValue( la )		
// Extracts the latency value from the latency index (at the moment limited to 0, 1 or 2 because of panel size but could be more)
	variable	la			// 
	svar   /Z	lstLatValues	= root:uf:evo:evl:glstLatValues
	if ( ! svar_exists( lstLatValues ) )
		string  /G	root:uf:evo:evl:glstLatValues = ""
		svar  	lstLatValues	= root:uf:evo:evl:glstLatValues
	 endif
	 return	str2num( StringFromList( la, lstLatValues ) ) 			// may return nan if the value does not yet exist
End

Function		SetLatValue( la, val )		
// Sets the latency value for a given latency index (at the moment limited to 0, 1 or 2 because of panel size but could be more)
	variable	la, val			// 
	svar   /Z	lstLatValues	= root:uf:evo:evl:glstLatValues
	if ( ! svar_exists( lstLatValues ) )
		string  /G 	root:uf:evo:evl:glstLatValues = ""
		svar  	lstLatValues	= root:uf:evo:evl:glstLatValues
	 endif
	lstLatValues = ReplaceListItem1( num2str( val ), lstLatValues, ";" , la )
End


static constant		kLAT_SCALE_FACTOR	= 1e3				//  kLAT_SCALE_FACTOR = 1e3  and  kLAT_SCALE_UNIT = "ms"  depend on each other and must be changed together 
static strconstant	kLAT_SCALE_UNIT		= "ms"				//  kLAT_SCALE_FACTOR = 1e3  and  kLAT_SCALE_UNIT = "ms"  depend on each other and must be changed together 

Function	/S	Lat_Unit_()
// return the 'units' string  including the unit separators   which  can be    '/' and ''  =  Latxxx/ms      or    '['  and  ']'   =  Latxxx[ms]
	return	ksSEP_UNIT1 + kLAT_SCALE_UNIT + ksSEP_UNIT2 		// e.g. can be     '/' and ''  =  Latxxx/ms      or    '['  and  ']'   =  Latxxx[ms]
End	


