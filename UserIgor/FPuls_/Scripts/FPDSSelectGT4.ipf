//
//  FPDSSelect.ipf	Data section selection and analysis with a listbox

#pragma rtGlobals=1		// Use modern global access method.

constant			kBITSELECTED	= 0x01						// Igor-defined. The bit which controls the selection state of a listbox cell

// If columns are changed then  'xSize'   listbox 'widths'  also have to be adjusted
static  constant		k_COLUMN_TITLE 	= -1							// Igor defined
static  constant		kCOLM_ZERO = 0,   kCOLM_PR = 1,   kCOLM_BL = 2,   kCOLM_FR = 3,   kCOLM_SW = 4,   kCOLM_PON = 5
static  strconstant	lstCOLUMNLABELS	= "LSw;Pro;Blk;Frm;Sw;PoN;"		// the column titles in the LB text wave including and staritng with LinSweep
  strconstant	lstCOL_SEL_NAMES	= "Prot;Block;Frame;Sweep;PoN;"	// the column names of the selectable columns excluding LinSweep

static constant		kLB_CELLY		= 16							// empirical cell height
// 050822
//static constant		kLB_ADDY		= 21							// additional y pixel for listbox header and margin
static constant		kLB_ADDY		= 18							// additional y pixel for window title, listbox column titles and 2 margins
static constant		kCLEAR = 0, 	kDRAW  = 1
static constant		kFIRST  = 0, 	kLAST    = 1

 strconstant	lstCOL_RANGE = "1 column,all cols,"						// radio buttons need colons separators
  strconstant	lstDISPMODE	= "single;stack;catenate;"					// popmenus need semicolon separators
static constant   	kSINGLE = 1, 	kSTACKED  = 2,	kCATENATED = 3	// popmenus start with index 1

// The key modifiers
static strconstant	lstMOD		= "none;mouse;   shift;m shft;    alt;m      alt;    sh alt;m sh alt;         ctrl;m      ctrl;    sh ctrl;m sh ctrl;        AG;m      AG;    sh AGr;m sh AGr"
static constant		kMO_N=0,  kMO_M=1,  kMO_S=2,  kMO_MS=3,  kMO_A=4,  kMO_MA=5,  kMO_SA=6,  kMO_MSA=7,  kMO_C=8,  kMO_MC=9,  kMO_SC=10,  kMO_MSC=11,  kMO_AG=12,  kMO_MAG=13,  kMO_SAG=14,  kMO_MSAG=15

// The mapping  key modifiers -> states.  The Igor-defined fixed modifier number is index of items in a string list containing the  Eval-states (=tbl, avg, skip/view) as defined below.  Mouse=1 is ignored, Shift=2, Alt=4, Ctrl=8, AltGr=12
static strconstant	lstMOD2STATE	= "4;4;4;4;2;2;2;2;1;1;1;1;3;3;3;3;"

// The states and colors. The mapping is done by assigning an arbitrary color number to any state. 'Auto' must be 0. The color numbers must correspond to  'wDSColors'
static strconstant	ksSTATUS	= "virgin;tabled;aver'd;tbl+avg;skipped;;;;current"		// the processing  states 		as bit field ( only tabled and averaged can be combined ) 
static strconstant	lstSTACOL	= "v_auto;tbl_blue ;avg_red;t+a_mag;sk_grey;;;;cur_apr"	// the processing  states_colors 	as bit field ( only tabled and averaged can be combined ) 
static constant		kST_VIRGIN 	= 0,	kST_TBL = 1,	kST_AVG	= 2,	kST_TBAV= 3,	kST_SKIP	= 4,										kST_CUR	= 8	// numbering of states = selection of color is arbitrary (0 must be auto)	
static  constant		k_COLORAUTO= 0,	kST_BLUE= 1,	kST_RED	= 2,	kST_MAG= 3,	kST_DGRY=4,	kST_LGRY=5, 	kST_GRN	= 6, 	kST_CYAN= 7,	kST_APRI	= 8	// same color order as in wDSColors below  


static strconstant	lstREM_ADD	= "Remove;Add;"
static constant		kREMOVE	= 0, 	kADD	= 1

// The states and colors for the  'Result Select' listboxes for Draw, Print, ToFile
	constant		kRS_TOFILE		= 1		// 1 = blue = CTRL,   2 = red = ALT,   3 = magenta = ALT CTRL,   4 = grey = no modifier
	constant		kRS_PRINT		= 1		// 1 = blue = CTRL,   2 = red = ALT,   3 = magenta = ALT CTRL,   4 = grey = no modifier
	constant		kRS_PRINTGRAPH	= 2		// 1 = blue = CTRL,   2 = red = ALT,   3 = magenta = ALT CTRL,   4 = grey = no modifier
	constant		kRS_DRAW		= 1		// 1 = blue = CTRL,   2 = red = ALT,   3 = magenta = ALT CTRL,   4 = grey = no modifier

Function		DSDlg( SctCnt, nChannels )
	// Build the DataSectionsPanel
	variable		SctCnt, nChannels

	// Possibly kill an old instance of the DataSectionsPanel and also kill the underlying waves
	DoWindow  /K	PnDSct
	KillWaves	  /Z	root:uf:wLBTxt , root:uf:wLBFlags, root:uf:wDSColors 


	// Build the DataSectionsPanel . The y size of the listbox and of the panel  are adjusted to the number of data sections (up to maximum screen size) 
	variable	xPos	= 10, c, nCols	= ItemsInList( lstCOLUMNLABELS )
	
	if ( WinType( "D3" ) == kPANEL ) 						// Retrieves the main evaluation panel's position from Igor	
		GetWindow     $"D3" , wsize						// Only if the main evaluation panel exists retrieve its position from Igor..		
		xPos	= V_right * screenresolution / kIGOR_POINTS72 + 5	// ..and place the current panel just adjacent to the right
	endif

	variable	xSize		= 176 							// 176 for column widths 16 	    + 4 * 13 + 14	(=82?)  adjust when columns change
//	variable	xSize		= 184							// 184 for column widths 16 + 2 * 8 + 4 * 13 	(=84?)  adjust when columns change
//	variable	xSize		= 206 							// 206 for column widths 16 + 2 * 8 + 5 * 13		(=97?)  adjust when columns change
	variable	yPos		= 50
	variable	ySizeMax	= GetIgorAppPixelY() -  kY_MISSING_PIXEL_BOT - kY_MISSING_PIXEL_TOP - 85  // -85 leaves some space for the history window
	variable	ySizeNeed	= SctCnt * kLB_CELLY
	variable	ySize		= min( ySizeNeed , ySizeMax ) 
	NewPanel /W=( xPos, yPos, xPos + xSize + 4 , yPos + ySize + kLB_ADDY ) /K=1 as "Data sections"	// in pixel
	DoWindow  /C PnDSct

	// Create the 2D LB text wave	( Rows = data sections, Columns = Both, Avg, Tbl )
	make   	/T 	/N = ( SctCnt, nCols )		root:uf:wLBTxt		// the LB text wave
	wave   	/T		wLBTxt		     =	root:uf:wLBTxt

	// Create the 3D LB flag wave. 	Rows x Columns (as above)  x 3  : last index 0 is flags, 1 is fore- or background color, 2 is the remaining color 
	make   	/B  /N = ( SctCnt, nCols, 3 )	root:uf:wLBFlags	// byte wave is sufficient for up to 254 colors 
	wave   			wLBFlags		    = 	root:uf:wLBFlags

	// Create color table withs rows and columns exchanged. 3 rows, n columns is easier to read as n columns, 3 rows but must be transposed before Igor can use them.
	// make   	/O /W /U	root:uf:wDSColors  = { { 0, 65535, 0 , 0 , 0, 65535 } , 	{ 0 ,  0, 65535, 0  , 65535, 0 } , 	{ 0, 0, 0, 65535, 65535, 65535 }  } 		// what Igor requires is hard to read : 6 rows , 3 columns : black, red, green, blue, cyan, magenta
	//								black		blue			red			magenta			grey			light grey			green			yellow				
	make 	/W /U	root:uf:wDSColors  = { {0, 0, 0 }, { 0, 0, 65535 },  { 65535, 0, 0 },  {40000,0,48000}, {44000,44000,44000},  {54000,54000,54000},  { 0, 50000, 0} ,   { 0, 56000, 56000 },  {65280,59904,48896} }	// order must be same as defined by constants above
	wave   wDSColors  =	root:uf:wDSColors
	MatrixTranspose 		  wDSColors				// the same table is used for foreground and background. 	Igor requires  n  rows, 3 columns 
	// magenta  green ModifyGraph rgb=(52224,0,41728) ModifyGraph rgb=(0,39168,0)

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
	SetPBFSTxt( wLBTxt, wLBFlags )

	// Build the panel controls 
	ListBox 	  lbDataSections, 	win = PnDSct, 	pos = { 2, 0 },  size = { xSize, ySize + kLB_ADDY },  frame = 2
	ListBox	  lbDataSections,	win = PnDSct, 	listWave 	= root:uf:wLBTxt
	ListBox 	  lbDataSections, 	win = PnDSct, 	selWave 	= root:uf:wLBFlags,  editStyle = 1
	ListBox	  lbDataSections, 	win = PnDSct, 	colorWave= root:uf:wDSColors
	ListBox 	  lbDataSections, 	win = PnDSct, 	mode  = 5	
	ListBox 	  lbDataSections, 	win = PnDSct, 	widths = { 16, 13, 13, 13, 13, 14 }			// adjust when columns change
	ListBox 	  lbDataSections, 	win = PnDSct, 	proc 	  = lbDataSectionsProc

	// Now that the listbox panel is constructed we open the graph windows and place them to the right of the listbox
	CFSDisplayAllChanInit( ksEVAL, nChannels )
	SetPrevRowInvalid() 

	svar		gsAvgNm		= root:uf:eval:D3:gsAvgNm0000	
	gsAvgNm	= ConstructNextResultFileNmA( CfsRdDataPath(), ksAVGEXT )	// the next free avg file where avg data will be written is displayed in SetVariable input field
															

End

//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//	THE  BIG  LISTBOX  ACTION  PROC

Function		lbDataSectionsProc( s ) : PopupMenuControl
// Dispatches the various actions to be taken when the user clicks in the Listbox

// MODIFIER  USAGE :
//	 We have 3 key modifiers for the evaluation to be done: 'Alt', 'Ctrl'  or  'Alt Gr' .     'Alt' +arrowkey  is used by Igor, 'Alt' + Mouse can be used.  'Shift'  is used for selecting a range .  
// 	 Modifiers are different for arrowkeys and mouse : Alt is allowed only with mouse, Alt is not allowed in conjunction with arrow key
//		Arrowkey	+ No mod:	= 0		+ Shift: 2		+ Alt:  -		+ Shift+Alt:  -  		+ Ctrl: 8		+ Shift+Ctrl: 10		+ Alt+Ctrl	-	+ Alt Gr: 12	Shift+Alt Gr: 14
//		Mouse: +1	+ No mod:	= 1		+ Shift: 3		+ Alt: 5		+ Shift+Alt: 7 		+ Ctrl: 9		+ Shift+Ctrl: 11		+ Alt+Ctrl	-	+ Alt Gr: 13 	Shift+Alt Gr: 15
//	This matches the evaluation modes : 	ModifNo ~ Viewed but not analysed, 	ModifAlt(only mouse) ~ Avg  , 	ModifCtrl ~ Tbl  , 	ModifAltGr ~ AvgTbl . 
//	Typical colors:					Dark Grey							Blue						Red				Magenta
//	 Further modes could be made accessible by  Checkboxes  or keyboard characters....
//	 Before any data unit is selected here is a 	5. light grey 'virgin' state. This is the Igor default listbox appearance.   
//	 After a data unit is selected but before an evaluation is done (or skipped)  there is a 6.  apricot  'current' state.
 
// MOUSE  and  KEYBOARD : What this function should do in reaction to user input (considering only mouse , keyboard modifiers and keyboard arrows, but no other keys or checkboxes )  :
//	 Click into data unit :		Colorise with 'current' color as 'current' unit .  Evaluate previous data unit according to  key modifiers pressed.  Colorise previous data unit with 'evaluated'  or  'view/skip'  color.
//	 Move arrow keys: 		Same as clicking. Additionally skip inner sweeps i.e. jump (depending on direction) to first or last sweep when entering a new data unit.  
//	 Shift Click into data unit:	Same as clicking,  but act on the whole range from the previously selected data unit up to the current  'Shift clicked'  data unit. 
//	 Shift arrow keys : 		Unnecessary and undefined.

// FURTHER NOTES:
//	When clicking into a cell the corresponding data unit is only displayed.   The modifiers effect the processing of the preceding data range ! 
// 	Double clicks do not work reliably as first there is an undesirable single click
// 	Shift Click on the header  is simply not recognised by Igor.

	struct	WMListboxAction &s
	wave	wBlk2Sct	= root:uf:cfsr:wBlk2Sct	
	wave	wFlags	= root:uf:wLBFlags

	variable	dsFirst, dsLast, dsSize, dsL						// first and last data section of the data unit we are currently in
	variable	nTmpFirst, nTmpLast, nState
	variable	row, col
	string  	sPlaneNm		= "BackColors" 
	variable	pl			= FindDimLabel( wFlags, 2, sPlaneNm )
	
	nvar		gPrevRowFi 	= root:uf:cfsr:gPrevRowFi
	nvar		gPrevRowLa 	= root:uf:cfsr:gPrevRowLa
	nvar		gPrevRowCu   	= root:uf:cfsr:gPrevRowCu
	nvar		gPrevColumn   	= root:uf:cfsr:gPrevColumn

	variable	nStateOnEntry	= State( wFlags, s.row, s.col, pl )

	if ( s.col != gPrevColumn )
		SetPrevRowInvalid() 
	endif
	
	DS2Lims( s.row, s.col, dsFirst, dsLast, dsSize ) 							// computes first and last data section of the data unit (=Prot, Block, Frame, Sweep) we are currently in
	// printf "\rlbDataSectionsProc() "  ; print s
	string  	sCode	= pad( StringFromList(s.eventCode, lstLB_EVENTS),8)
	string  	sModif	= pad( StringFromList( s.eventMod, lstMod ), 7 )
	string  	sColor	= pad(StringFromList( nStateOnEntry, lstSTACOL),6)
 	string		sTxt
	//????? This function may (sometimes) be interrupted by itself??? Instead of printing LB1...LB2 CR    LB1...LB2 crlf  sometimes  LB1LB1...LB2 crlf    LB2  is printed. Strange......
//  	printf "\tLB1\te:%2d %s\tmod:%2d %s\tprevR:%2d\t..%2d\t..%2d\tro:%2d\tprevC:%2d\tco:%2d e2:%2d\ts:%2d %s\t-> du:%2d\t..%2d", s.eventCode, sCode, s.eventMod, sModif, gPrevRowFi, gPrevRowCu, gPrevRowLa, s.row, gPrevColumn, s.col, s.eventCode2, nStateOnEntry, sColor, dsFirst, dsLast

	// ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' '
	// MOUSE : Click on the header : Set the selection state of the complete column and possibly analyse the data immediately. There is not delay as it is when clicking into a cell .
	if ( s.eventCode == kLBE_mousedown  &&  s.row == k_COLUMN_TITLE )
		if ( s.col >= kCOLM_PR  &&  s.col <= kCOLM_PON )
	//	// MOUSE : Click on the header : Toggle the selection state of the complete column.
		// Todo: Currently the state is toggled only between 'current = all selected'  and  'skip/viewed' .  Any evaluations are cleared which may be undesirable...  
	//		nState	= kST_APRI
	//		row	= DimSize( wFlags , 0 ) - 1										// the last data section of the entire experiment
	//		DS2Lims( row, s.col, dsFirst, dsLast, dsSize ) 							// computes  'dsLast'  : the last data section of the entire experiment
	//		row	= 0
	//		do
	//			DS2Lims( row, s.col, dsFirst, dsL, dsSize ) 							// computes first and last data section of the current data unit e.g.  Frame or Block
	//			DSToggleAnalysis( ksEVAL, wFlags, dsFirst, dsL, s.col,  pl, nState  )		// toggles current data unit 
	//			row += dsSize
	//		while ( dsL < dsLast ) 		// todo : truncated
			nState	= Modifier2State( s.eventMod )								// Convert the modifying key (e.g. 'Ctrl' ,  'Ctrl Alt / Alt Gr' ) to a state (e.g. Avg, Tbl; View/Skip)  
			dsLast	= DimSize( wFlags , 0 ) - 1									// the last data section of the entire experiment
			row		= 0
			do
				DS2Lims( row, s.col, dsFirst, dsL, dsSize ) 							// computes first and last data section of the current data unit e.g.  Frame or Block
				DSSetAndAnalyse( ksEVAL, wFlags, dsFirst, dsL, s.col, pl, nState )		// 
				row += dsSize
			while ( dsL < dsLast ) 		// todo : truncated
		endif	
	endif	

	// ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' '
	// MOUSE : Click in a cell  in columns  'Pro' , 'Blk'  ... 'pon' 	: Jump to and display the the selected  prot, block, frame, sweep or PoN
	if ( s.eventCode == kLBE_MouseUp  &&  !( s.eventMod & kSHIFT )  )					// Only mouse clicks  without SHIFT  are interpreted here 
		if ( PrevRowIsValid() )
			nState		= Modifier2State( s.eventMod )							// Convert the modifying key (e.g. 'Ctrl' ,  'Ctrl Alt / Alt Gr' ) to a state (e.g. Avg, Tbl; View/Skip)  
			DSSetAndAnalyse( ksEVAL, wFlags, gPrevRowFi, gPrevRowLa, s.col, pl, nState )	// change color of cells in Listbox and of traces in graph of previous data unit range according to the chosen evaluation e.g. 'Avg' or 'Skip/View'
		endif
		DS2Lims( s.row, s.col, dsFirst, dsLast, dsSize ) 								// computes first and last data section of the data unit (=Prot, Block, Frame, Sweep) we are currently in
		nState		= kST_CUR
// 050727 overwrites cursors and points of analysis
//DSSetAndAnalyse( ksEVAL, wFlags, dsFirst, dsLast, s.col, pl, nState )				// cosmetics: add current=offered cell range in apricot
		gPrevRowFi 	= dsFirst												// Store start of selected range. This will be needed for recoloring in the next call when...
		gPrevRowLa	= dsLast												// ..after having viewed the data the user has decided if and how to analyse the data unit
		gPrevColumn   	= s.col
	endif

	// ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' '
	// MOUSE: Shift Click in a cell  in columns  'Avg' , 'Tbl   : Toggle the selection state of a cell range from previously clicked cell up to and including this cell. Must stay in column.
	// Todo : Possibly exclude modifiers so that nothing at all is done when a modifier is pressed. Currently they are allowed and the action which would  be done if no modifier was pressed is executed. 
	if ( s.eventCode == kLBE_MouseUp  &&  ( s.eventMod & kSHIFT ) )					// Only mouse clicks while SHIFT is pressed are interpreted here 
		if ( PrevRowIsValid() )
			nState		= Modifier2State( s.eventMod )							// Convert the modifying key (e.g. 'Ctrl' ,  'Ctrl Alt / Alt Gr' ) to a state (e.g. Avg, Tbl; View/Skip)  
			if ( s.row > gPrevRowLa )										
				nTmpFirst	= gPrevRowFi										// We are advancing (going downwards in the listbox)
				dsFirst	= gPrevRowLa +1 									// we mark only the data units BELOW the previously selected starting data unit	
				nTmpLast	= dsLast
			else
				nTmpFirst	= dsFirst											// We are going back (upwards in the listbox)
				dsLast	= gPrevRowFi - 1									// we mark only the data units ABOVE the previously selected starting data unit
				nTmpLast	= gPrevRowLa
			endif					
			nState		= kST_CUR										// we are only extending the 'current' range of data units, we do not do any evaluation in this step
			DSSetAndAnalyse( ksEVAL, wFlags, dsFirst, dsLast, s.col, pl, nState )			// change color of cells in Listbox and of traces in graph  from apricot to 'Analysed' 
			gPrevRowFi	= nTmpFirst										
			gPrevRowLa	= nTmpLast										// We store the entire range of data units INCLUDING the previously selected starting data unit
			gPrevColumn   	= s.col
		endif
	endif

	// ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' '
	// KEYBOARD: Move with arrow key  in columns  'Pro' , 'Blk'  ... 'pon' 	: Jump to and display the the selected  prot, block, frame, sweep or PoN
	if ( s.eventCode == kLBE_CellSelect  &&   ( s.eventMod & 1 ) == 0  )					// Only keyboard arrow keys but no mouse clicks are interpreted here 
		if ( PrevRowIsValid() )
			nState		= Modifier2State( s.eventMod )							// Convert the modifying key (e.g. 'Ctrl' ,  'Ctrl Alt / Alt Gr' ) to a state (e.g. Avg, Tbl; View/Skip)  
			DSSetAndAnalyse( ksEVAL, wFlags, gPrevRowFi, gPrevRowLa, s.col, pl, nState )	// change color of cells in Listbox and of traces in graph of previous data unit range according to the chosen evaluation e.g. 'Avg' or 'Skip/View'
	
			DS2Lims( s.row, s.col, dsFirst, dsLast, dsSize ) 							// computes first and last data section of the data unit (=Prot, Block, Frame, Sweep) we are currently in
			// Jumps from first to last row of data unit (or reverse) . 
			variable	nDirection		= gPrevRowCu - s.Row						// -1 , 0 , 1
			variable	nJumpRow  =   nDirection > 0	?  dsFirst	: dsLast				// Cave : theoretically includes direction 0..
			if ( nDirection  )													// ...but this cannot ocur with arrow keys  and  the following lines would be skipped 
				variable r
				for ( r = dsFirst; r <= dsLast; r += 1 ) 
					wFlags[ r 	][ s.col ][ 0 ]   = wFlags[ r ][  s.col ][ 0 ]  & ( 0xff - kBITSELECTED )	// reset  bit 0x01 to 0 : clear old selection	
				endfor
				wFlags[ nJumpRow][ s.col ][ 0 ]  = wFlags[ nJumpRow][ s.col ][ 0 ]   |  kBITSELECTED 	// set     bit 0x01 to 1	: show new selection at the other end of data unit 
			endif
	
			// printf "\t\tfDSPanelHook()\tAnalyse:\t%s\tfrom DS:%4d\t...%5d\tDS %4d\t...%5d\tare offered...  \r", StringFromList( nState, ksSTATUS), dsFirst, dsLast, dsFirst, dsLast
			nState		= kST_CUR										// we are only extending the 'current' range of data units, we do not do any evaluation in this step
			DSSetAndAnalyse( ksEVAL, wFlags, dsFirst, dsLast, s.col, pl, nState )			// change color of analysed cells in Listbox and of traces in graph from apricot to 'Analysed' or 'Skipped'
	
			gPrevRowFi 	= dsFirst											// Store start of selected range. This will be needed for recoloring in the next call when...
			gPrevRowLa	= dsLast											// ..after having viewed the data the user has decided if and how to analyse the data unit
			gPrevColumn   	= s.col
		endif
	endif

	gPrevRowCu	= IsSelected( wFlags, s.col )
//	printf "\t -->LB2\tState:%2d\t%s\tprevR:%2d\t..%2d\t..%2d\t  \r", nState, pad(StringFromList(nState, lstSTACOL),6), gPrevRowFi, gPrevRowCu, gPrevRowLa
	return 0			// other return values reserved
End

//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function		Modifier2State( nModifier )
	// Convert  the modifying key ( 'Ctrl'  or  'Ctrl Alt / Alt Gr'  )  to a state  (e.g. Avg, Tbl, View/Skip). 
	//  'Alt' + arrowkeys  is used by Igor,  'Alt' + mouse can be used freely.   'Shift' is used for selecting a range .  
	variable	nModifier
	return str2num( StringFromList( nModifier, lstMOD2STATE ) )	
End


Function		PrevRowIsValid() 
	nvar		gPrevRowFi 	= root:uf:cfsr:gPrevRowFi
	nvar		gPrevRowLa 	= root:uf:cfsr:gPrevRowLa
	return	gPrevRowFi >= 0  &&  gPrevRowLa >= 0 	
End

Function		SetPrevRowInvalid() 
	nvar		gPrevRowFi 	= root:uf:cfsr:gPrevRowFi
	nvar		gPrevRowLa 	= root:uf:cfsr:gPrevRowLa
	gPrevRowFi	= -1
	gPrevRowLa	= -1 	
End


static Function	DSSetAndAnalyse( sFolder, wFlags, dsF, dsL, col, pl, nState )
// Set  state   and   add to  or  remove from  analysis. There is a  1 to 1 correspondence between colors and  states,  a color IS a  state , e.g.  Green=analysed,  Blue=Fitted,   Red=averaged.
// Further refinements possible:  states may draw  text in the cells  or may change the  text (=foregrund color) .
// CAVE :  'dsF'  and  'dsL'  must be the first and the last data section in the data unit (e.g. Prot, Block, Frame, Sweep)  given by  'col'
// CAVE :  only  data sections  which are currently selected  may be reset (=deselected)  with this function  (if this condition is not met then  RemoveFromGraph  will complain...)
	string  	sFolder
	wave	wFlags
	variable	dsF, dsL, col, pl, nState
	DSDisplayAllChan( sFolder, wFlags, dsF, dsL, col, pl, nState )	// add or remove cell range
	DSSet( wFlags, dsF, dsL, col, pl, nState )					// sets flags after Display for Analysis to work
	return	nState					
End			


Function		DSSet( wFlags, dsF, dsL, col, pl, nState )
// Set color = state  in listbox  but  do  no analysis
// Further refinements possible:  states may draw  text in the cells  or may change the  text (=foregrund color) .
	wave	wFlags
	variable	dsF, dsL, col, pl, nState
	variable	ds
	for ( ds = dsF; ds <= dsL; ds += 1 )
		wFlags[ ds ][ col ][ pl ]	= nState
	endfor
	return	nState				// needed for conditional assignment
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


Function		IsSelected( wFlags, col )
	wave	wFlags
	variable	col
	variable	ds, dsCnt	= DimSize( wFlags, 0 )
	variable	bitSelected= 0x01									// Bit 0x01 means cell is selected.  We turn off bit 0 so that  Igor will not display cell in 'selected' (=black) state except for a short flash. 
	for ( ds = 0; ds < dsCnt; ds += 1 )
		if ( wFlags[ ds ][ col ][ 0 ]  &  bitSelected )	
			return	ds
		endif
	endfor
	return	kNOTFOUND
End


Function		SetPBFSTxt( wLBTxt, wFlags )
	wave  /T	wLBTxt
	wave  	wFlags
	variable	ds, dsCnt	= DimSize( wLBTxt, 0 )
	variable	pr, bl, fr, sw, pon
	string  	sPlaneNm	= "ForeColors"					// or use  mild colors in conjunction with 'backColors'
	variable	pl		= FindDimLabel( wFlags, 2, sPlaneNm )
	for ( ds = 0; ds < dsCnt; ds += 1 )
		Ds2pbfs( ds, pr, bl, fr, sw, pon )
		wLBTxt[ ds ][ kCOLM_PR ]		= num2str( pr )		// set initial LB text
		DSSet( wFlags, ds, ds, kCOLM_PR, pl, pr )			// colorise the LB text
		wLBTxt[ ds ][ kCOLM_BL ]		= num2str( bl )		
		DSSet( wFlags, ds, ds, kCOLM_BL, pl, bl )
		wLBTxt[ ds ][ kCOLM_FR ]		= num2str( fr )		// set initial LB text
		DSSet( wFlags, ds, ds, kCOLM_FR, pl, fr )
		wLBTxt[ ds ][ kCOLM_SW ]	= num2str( sw )		
		DSSet( wFlags, ds, ds, kCOLM_SW, pl, sw )
		wLBTxt[ ds ][ kCOLM_PON ]	= num2str( pon )		
		DSSet( wFlags, ds, ds, kCOLM_PON, pl, pon )
	endfor
End


//Function		ResetOtherColumns( wFlags, ExcludeColumn, pl, nState )
//// Sets all columns to  'nState'  except  'ExcludeColumn' 
//	wave	wFlags
//	variable	ExcludeColumn, pl, nState
//	variable	col, row, EndRow = DimSize( wFlags, 0 ) - 1
//	for ( col = kCOLM_PR; col <= kCOLM_PON; col += 1 )
//		if ( col != ExcludeColumn )
//			DSSet( wFlags, 0, EndRow, col, pl, nState )
//		endif
//	endfor
//End

//Function		DSToggleUnit( s, wBlk2Sct, wFlags, pl, nColor1, nColor2, nDirection )
//// Toggles  complete prot,  block, frame or sweep when 1 data section (=s.row)  is given. Sets selected data section to first or last ds of unit depending on  'nDirection' .
//	struct	WMListboxAction &s
//	wave	wBlk2Sct
//	wave	wFlags	
//	variable	pl, nColor1, nColor2, nDirection
//	variable	dsFirst, dsLast, dsSize 
//	DS2Lims( s.row, s.col, dsFirst, dsLast, dsSize ) 									// computes first and last data section of the data unit (=Prot, Block, Frame, Sweep) we are currently in
////	if ( s.col >= kCOLM_PR  &&  s.col <= kCOLM_SW )
//		DSToggleAnalysis( wFlags, dsFirst, dsLast, s.col, pl, nColor1, nColor2 )
//		// todo : if nDirection == 0 ....
//		variable	nNewSelectedRow	= nDirection == 1  ?  dsFirst  :  dsLast					// Turn the first or last cell in this unit on so that when the user presses..
//		//wFlags[ nNewSelectedRow ] [ s.col ][ 0 ]   = ( wFlags | 0x01 )					// ..the  arrow  keys  the first cell of the next unit will be automatically selected
//		// printf "\t\tDSToggleUnit()(\tnDir:%d\tNew selection is nRowJump:%2d\t  \r", nDirection, nNewSelectedRow
////	endif
//	return	nNewSelectedRow
//End

//Function		DSToggleAnalysis( sFolder, wFlags, dsF, dsL, col, pl, nState )
//// Toggle the main state of a cell  range (dsf..dsL)  between 'nColor1' and  'nState' . 
//// No use is made of Igors 'Selected' flag which is stored in the Igor-defined  dimension 2 , index 0 , bit 0x10 of the  'wFlags'  wave.
//// The state  (e.g. analysed, fitted, averaged)  is stored in  the dimension 2 , index 1 (possibly also2) of the 'wFlags'  wave . THIS IS THE COLOR INFORMATION !
//// So there is a  1 to 1 correspondence between colors and  states,  a color IS a  state , e.g.  Green=analysed,  Blue=Fitted,   Red=averaged.
//// Further refinements possible:  states may draw  text in the cells  or may change the  text (=foregrund)  color  .
//// CAVE :  'dsF'  and  'dsL'  must be the first and the last data section in the data unit (e.g. Prot, Block, Frame, Sweep)  given by  'col'
//	string  	sFolder
//	wave	wFlags
//	variable	dsF, dsL, col, pl, nState
//	variable	ds
//	// Prevent Igor from displaying the 'selected' state
//	variable	bitSelected= 0x01								// Bit 0x01 means cell is selected.  We turn off bit 0 so that  Igor will not display cell in 'selected' (=black) state except for a short flash. 
//	for ( ds = dsF; ds <= dsL; ds += 1 )
//		wFlags[ ds ] [ col ][ 0 ]   = ( wFlags & ( 0xff - bitSelected ) )		// This is cosmetics. Drawback : it is now our resonsability to correctly display the state of the cell.
//	endfor
//
//	nState	= wFlags[ dsF ][ col ][ pl ] == 0 ?  nState  : 0				// Inverse 'nState' : If data unit was 'off' then set to 'nState' . If it was 'on' (=any state except 0) the turn it 'off' = set to 0
//	DSSetAndAnalyse( sFolder, wFlags, dsF, dsL, col, pl, nState )		// add or remove cell range depending on  'nColor'
//	// printf "DSToggleAnalysis() value: %d      wFlags[ row:%2d ][ col:%2d ][ flags=0 ]: %2d   \t->wFlags[row:%2d\t][col:%2d ][ pl:%d ]: %d\t  \r", value, row, col, wFlags[row][col][ 0 ] , row, col, pl, wFlags[row][col][ pl]
//End			


//Function		ToggleColumnState( column, nState )
//// Inverses selectively  'nState'  in any column  e.g.  toggles  'Average'  on all data units in column while leaving   'Table'  state untouched
//// Works fine but it is unclear what to do with state 0=virgin,   skipped=4  and current=8. First idea : skip=0, virgin=4
//	variable	column, nState
//	variable	dsFirst, dsLast, dsLastOfExp, dsSize 
//	variable	nOldState, nToggledState		
//	wave	wFlags		= root:uf:wLBFlags
//	string  	sPlaneNm		= "BackColors" 
//	variable	pl			= FindDimLabel( wFlags, 2, sPlaneNm )
//	variable	row			= DimSize( wFlags , 0 ) - 1						// the last data section of the entire experiment
//	DS2Lims( row, column, dsFirst, dsLastOfExp, dsSize )						// computes  'dsL'  : the last data section of the entire experiment
//	row	= 0
//	do
//		DS2Lims( row, column, dsFirst, dsLast, dsSize ) 						// computes first and last data section of the current data unit e.g.  Frame or Block
//		nOldState		= State( wFlags, dsFirst, column, pl )
//		nToggledState	= nOldState & nState  ?  nOldState & ( 0xffffffff - nState ) : nOldState | nState 
//		printf "\t\tToggleColumnState( column:%d, nState:%d ) \tdsFirst:%3d..%3d \tOldState:%2d\t->\tToggledState:%2d \t \r",  column, nState, dsFirst, dsLast, nOldState, nToggledState
//		DSSet( wFlags, dsFirst, dsLast, column, pl, nToggledState )
//		row += dsSize
//	while ( dsLast < dsLastOfExp ) 		// todo : truncated
//	SetPrevRowInvalid() 
//End

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function		Ds2pbfs( sct, pr, bl, fr, sw, pon )
// Computes protocol / block / frame / sweep / PoverN  if linear data section is given. Inverse of GetLinSweep() .
	variable	sct
	variable	&pr, &bl, &fr, &sw, &pon
	wave	wSct2pbfs	=	root:uf:cfsr:wSct2pbfs		

	pr	= wSct2pbfs[ sct ][ kPROT ]												//  041210	
	bl	= wSct2pbfs[ sct ][ kBLK ]													//  041210	
	fr	= wSct2pbfs[ sct ][ kFRM ]													//  041210	
	sw	= wSct2pbfs[ sct ][ kSWP ]													//  041210	
	pon	= wSct2pbfs[ sct ][ kPON ]													//  041210	
End


Function		DS2Lims( row, col, dsFi, dsLa, dsSz ) 	
// computes first and last data section of the data unit (=Prot, Block, Frame, Sweep) we are currently in
	variable	row, col
	variable	&dsFi, &dsLa, &dsSz 
	variable	pr, bl, fr, sw, pon
	wave	wBlk2Sct	=	root:uf:cfsr:wBlk2Sct		

	Ds2pbfs( row, pr, bl, fr, sw, pon )
	if ( col == kCOLM_PR )
		bl	= 0
		fr	= 0
		sw	= 0
		dsFi	= wBlk2Sct[ pr ][ bl ][ fr ][ sw ]
		bl	= CfsBlocks() - 1
		fr	= CfsFrames( bl ) - 1
		sw	= CfsSweeps( bl ) + CfsHasPoN( bl ) - 1
		dsLa	= wBlk2Sct[ pr ][ bl ][ fr ][ sw ]
	elseif	( col == kCOLM_BL )
		fr	= 0
		sw	= 0
		dsFi	= wBlk2Sct[ pr ][ bl ][ fr ][ sw ]
		fr	= CfsFrames( bl ) - 1
		sw	= CfsSweeps( bl ) + CfsHasPoN( bl ) - 1
		dsLa	= wBlk2Sct[ pr ][ bl ][ fr ][ sw ]
	elseif	( col == kCOLM_FR )
		sw	= 0
		dsFi	= wBlk2Sct[ pr ][ bl ][ fr ][ sw ]
		sw	= CfsSweeps( bl ) + CfsHasPoN( bl ) - 1
		dsLa	= wBlk2Sct[ pr ][ bl ][ fr ][ sw ]
//	elseif ( col == kCOLM_SW  ||  col == kCOLM_ZERO  )	
	elseif ( col == kCOLM_SW  ||  col == kCOLM_ZERO  ||  col == kCOLM_PON )	
		// dsFi  = wBlk2Sct[ pr ][ bl ][ fr ][ sw ]	// wrong: cannot access PoN sweep in  swp column
		// dsLa = wBlk2Sct[ pr ][ bl ][ fr ][ sw ]
		dsFi	= row
		dsLa	= row
	endif
	dsSz	= dsLa - dsFi + 1	
	// printf "\t\tDS2Lims(\trow:%3d\tcol:%3d\t ->\tF:%3d\tL:%3d\t(Sz:%4d)\t \r", row, col, dsFi, dsLa, dsSz
End


//=======================================================================================================================
// THE  NEW  DS-EVALUATION PANEL

Function		PanelDSEvalDetails3()
	string  	sFBase		= "root:uf:"
	string  	sFSub		= ksEVAL_	
	string  	sWin			= "D3" 
	string		sPnTitle//		= "Evaluation Details3"
	sprintf	sPnTitle, "%s %s", "Evaluation - Read Cfs " ,  FormatVersion()
	string		sDFSave		= GetDataFolder( 1 )						// The following functions do NOT restore the CDF so we remember the CDF in a string .
	// PossiblyCreateFolder( sFBase + sFSub + sWin )	// , kRESTORE_FOLDER )	// kSTAY_IN_NEW_FOLDER
	if ( PossiblyCreateFolder( sFBase + sFSub + sWin ) )	
		variable	/G	raCfsHeadr00	// todo ..ugly code   .................as the automatic creation is too late.........-> should automatically be created early enough.............		
		variable	/G	raStVal00		// todo ..ugly code   .................as the automatic creation is too late.........-> should automatically be created early enough.............		
		//variable	/G	raColRange00	// ...is here not yet needed?????........-> should automatically be created early enough.............		
	endif
	SetDataFolder sDFSave										// Restore CDF from the string  value
	InitPanelDSEvalDetails3( sFBase + sFSub, sWin )					// fills big text wave  'sPnOptions' (=wPn)  with all information about the controls necessary to build the panel
	Panel3Main(   sWin, 		sPnTitle, 		sFBase + sFSub,  0, 0 )	// Compute the location of panel controls and the panel dimensions. Draw the panel displaying and hiding needed/unneeded controls

// 050726
//	SetWindow	$sWin  , hook(PnEval) = fHookPnEvaluation1 			// prevent the user to accidentally minimize, maximize or close the panel
// 050728 unnamed window hook
	SetWindow	$sWin  , hook = fHookPnEvaluation1 				// WM,JP: using the one and only unnamed hook should avoid the crash but it does NOT!..... prevent the user to accidentally minimize, maximize or close the panel

	EnableSetVar(  sWin,  "root_uf_eval_D3_gsReadDPath0000",  kNOEDIT )	// read-only, but could also be made to allow file name entry
	EnableSetVar(  sWin,  "root_uf_eval_D3_gReadSmpInt0000",   kNOEDIT )	// read-only

	// Handle the status info
	EnableSetVar(  sWin,  "root_uf_eval_D3_gsStatusInf0000",   kNOEDIT )	// make the  'status info'  SetVariable field read-only
	SetFormula $"root:uf:eval:D3:gsStatusInf0000",  "num2str( root:uf:eval:evl:wCurRegion[ kCURSWP ] ) + Spaces3() + num2str( root:uf:cfsr:gDataSections) "
//    Swp:\\{\"%2d /%2d  \",  root:uf:cfsr:gCurSwp, root:uf:cfsr:gDataSections }   Pro:\\{\"%2d /%2d  \",  root:uf:cfsr:gProt, CfsProts() }   Frm:\\{\"%2d /%2d  \",  root:uf:cfsr:gFrm, CfsFrames(root:uf:cfsr:gBlk) }   Swp:\\{\"%2d /%2d  \",  root:uf:cfsr:gSwp, root:uf:cfsr:gSwpPerFrm } "



//	EnableButton( "PnEvaluation", "buDispCfsEvalPanel",    kDISABLE )		// wait till after the first data have been read
//	EnableButton( "PnEvaluation", "buEvStimDlg0000",  kDISABLE )			// wait till after the first data have been read
//	EnableCheckbox( "PnEvaluation", "root_uf_"+sFolder+"_D3_gbShwScr0000", kDISABLE )	

	EnableButton( 	  sWin, "root_uf_eval_D3_buEvStimDlg0000",  kDISABLE )	// wait till after the first data have been read
	EnableCheckbox(sWin, "root_uf_eval_D3_gbShwScr0000", kDISABLE )	
	UpdateDependent_Of_AllowDelete( sWin, "root_uf_eval_D3_cbAlDel0000" )	
End

Function	/S	Spaces3()
	return " / "
End


// 050726 named window hook
//Function 		fHookPnEvaluation1( s )
//// Catch window kill message and ignore it. Disables Window Close button to keep the user from accidentally closing the main EVAL Panel...
//// resizing (=minimizing or maximizing) and deactivating cannot be prevented the same way but  ModifyPanel and  MoveWindow  provide a workaround.... 
//	struct	WMWinHookStruct &s
//	string	  	sThisPrgNm	= "FEval"
//	if ( s.eventCode != kWHK_mousemoved )
//		 printf  "\t\t\t\t\t fHookPnEvaluation1( '%s' )  '%s'\r", s.eventName, s.winName
//		ModifyPanel /W=$s.winName, fixedSize= 1					// prevent the user to.... maximize the panel by disabling the Maximize button
//		if ( s.eventCode == kWHK_resize )
//			MoveWindow /W=$s.winName	1, 1, 1, 1					// prevent the user to.... minimize the panel by restoring the old size immediately
//		endif
//		if ( s.eventCode == kWHK_kill )							// The user tries to close the main panel
//			DoAlert 1, "All graphs will be deleted. \rDo you really want to quit '" + sThisPrgNm + "' ? "	// Param = 1 : 'Yes'  and  'No'  buttons	
//			if ( V_flag == 1 )									// V_flag = 1 : 'Yes' is clicked .
//				Cleanup( ksEVAL)
//				return  0  									// Return 0 : no special handling
//			else
//				return  2  									// Return 2 : prevents killing
//			endif	
//			//return ( V_flag == 1 ) 	?  0  : 2 						// V_flag = 1 : 'Yes' is clicked . Return 0 : no special handling,  2 : prevents killing
//		endif	
//		// return cmpstr( sEvent, "kill" ) ? 0 : 2						// 0 means no special handling, else 1 (no clipboard)  or 2 : prevents killing, ( killing can also be disabled by  'NewPanel   /K=2' )
//	endif
//	return	0
//End 
 

// 050728 unnamed window hook
Function 		fHookPnEvaluation1( sInfo )
// Catch window kill message and ignore it. Disables Window Close button to keep the user from accidentally closing the main EVAL Panel...
// resizing (=minimizing or maximizing) and deactivating cannot be prevented the same way but  ModifyPanel and  MoveWindow  provide a workaround.... 
	string		sInfo
	string 	sEvent	= StringByKey(     "EVENT",   sInfo )
	string		sWNm	= StringByKey(     "WINDOW", sInfo )		// user clicks into this window: remember it even if if gets... 
	string	  	sThisPrgNm	= "FEval"
	// printf  "\t\t\t\t\t fHookPnEvaluation1( '%s' )  '%s'   %s\r", sInfo, sWNm, sEvent
	ModifyPanel /W=$sWNm, fixedSize= 1					// prevent the user to.... maximize the panel by disabling the Maximize button
	if ( !cmpstr( sEvent, "resize" ) )
		MoveWindow /W=$sWNm	1, 1, 1, 1					// prevent the user to.... minimize the panel by restoring the old size immediately
	endif
	if ( cmpstr( sEvent, "kill" ) == 0 )							// The user tries to close the main panel
		DoAlert 1, "All graphs will be deleted. \rDo you really want to quit '" + sThisPrgNm + "' ? "	// Param = 1 : 'Yes'  and  'No'  buttons	
		if ( V_flag == 1 )									// V_flag = 1 : 'Yes' is clicked .
			Cleanup( ksEVAL)
			return  0  									// Return 0 : no special handling
		else
			return  2  									// Return 2 : prevents killing
		endif	
		//return ( V_flag == 1 ) 	?  0  : 2 						// V_flag = 1 : 'Yes' is clicked . Return 0 : no special handling,  2 : prevents killing
	endif	
	// return cmpstr( sEvent, "kill" ) ? 0 : 2						// 0 means no special handling, else 1 (no clipboard)  or 2 : prevents killing, ( killing can also be disabled by  'NewPanel   /K=2' )
	return	0
End 
 

Function		InitPanelDSEvalDetails3( sF, sPnOptions )
	string  	sF, sPnOptions
	string		sPanelWvNm = sF + sPnOptions
	variable	n = -1, nItems = 100
	printf "\tInitPanelDSEvalDetails3( '%s',  '%s' ) \r", sF, sPnOptions 
	make /O /T /N=(nItems)	$sPanelWvNm
	wave  /T	tPn	=		$sPanelWvNm
	// Cave / Flaw :   No tabcontrol = empty  'Tabs'  must have   different number of spaces (no Tab, not the empty string )  to be recognised correctly
	// Cave / Flaw :   For each item in  'Tabs'   there must be a  corresponding  'Blks'  entry  even if empty
	// Cave / Flaw :	   Only tabulators can be used  for aligning the following columns, do not use spaces.... (maybe they are allowed...)
	// Cave :	Supply as many row title separators for dependent controls as there are row titles for the leading control. See   'Fit' / 'FitFunc' / 'FitRng' control   and  the functions 'fFitRowTitles()' /  'fFitRowDums()' for an example.
	
	//				Type	 NxL Pos MxPo OvS	Tabs		Blks		Mode		Name		RowTi		ColTi			ActionProc	XBodySz	FormatEntry	Initval		Visibility	SubHelp

	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:		,:		,:			dum1a:		:			:			:			:		:			:			:		:	"		//	single separator needs ',' 
	n += 1;	tPn[ n ] =	"BU:    1:	0:	3:	0:	°:		,:		1,°:			PrevFile:		< Prev file:		:			fPrevFile():		:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	1:	3:	0:	°:		,:		1,°:			NextFile:		Next file >:		:			fNextFile:		:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	2:	3:	0:	°:		,:		1,°:			bCurAcqFile:	Current acq:	:			fCurAcqFile():	:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"STR:  1:	0:	3:	1:	°:		,:		1,°:			gsReadDPath:	 Path:		:			:			205:		:			:			:		:	"		//  	single  SetVariable for String display
	n += 1;	tPn[ n ] =	"BU:    0:	2:	3:	0:	°:		,:		1,°:			SelFile:		Select file:		:			fSelFile():		:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"SV:    1:	0:	3:	1:	°:		,:		1,:			gReadSmpInt:	Sample interval / us:	:		:	  		40:		%4d; 0,0,0:	:			:		:	"
	n += 1;	tPn[ n ] =	"STR:  1:	0:	3:	2:	°:		,:		1,°:			gsStatusInf:	 Info:			:			:			270:		:			:			:		:	"		//  	single  SetVariable for String display
	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:		,:		,:			dum1c:		:			:			:			:		:			:			:		:	"		//	single separator needs ',' 
	n += 1;	tPn[ n ] =	"RAD: 1:	0:	3:	0:	°:		,:		1,°:			raColRange:	Range  :		fColRangeLst():	fColRange():	:		:			:			:		:	"		//	1-dim horz radios
	n += 1;	tPn[ n ] =	"PM:	   1:	0:	3:	0:	°:		,:		,:			gDspMode:	:			Display:		fDispMode():	66:		fDispModeLst():	0000_1:		:		:	"		// 	1-dim  popmenu (1 row)
	n += 1;	tPn[ n ] =	"PM:	   0:	1:	3:	0:	°:		,:		,:			pmActiveCol:	:			Active:		fActiveColumn():	66:		fActiveColumnLst():0000_3:	:		:	"		// 	1-dim  popmenu (1 row)
////	n += 1;	tPn[ n ] =	"PN_POPUP	;root:uf:eval:evl:gnWndNumber	;Graph; 75	; 1 ;pmShowWindow_Lst;	pmShowWindow"	// !!! The value defined here must be 1 more than the initial 'gnDispMode' 	for the listbox correspond to the actual setting.
//	n += 1;	tPn[ n ] =	"PN_POPUP	;root:uf:eval:D3:gDspMode0000	;Display;75; 2 ;fDispModeLst;	fDispMode"			// !!! The value defined here must be 1 more than the initial 'gnDispMode' 	for the listbox correspond to the actual setting.
//	n += 1;	tPn[ n ] =	"PN_POPUP	;root:uf:eval:evl:gnActiveCol	;Active; 75	; 3 ;fActiveColumnLst;	fActiveColumn"			// !!! The value defined here must be the same as the initial 'gnActiveCol'  for correspondence. SPECIAL case as index 0 is missing!
	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:		,:		,:			dum1g:		:			:			:			:		:			:			:		:	"		//	single separator needs ',' 

	// TabGroup :Tabcontrol with 1dim controls
	n += 1;	tPn[ n ] =	"CB:	   1:	0:	3:	0:	LstChan():	,°,°,°,°,°,°:	1°1°1°1°1°1°:	cbEvlCh:		:	View,View + Average,Evaluate,:	fEvalChannel():	:	:			0002_1;1001_1;~0:	:	:	"		// 	!!!! assumption: must be horz control (see Analyse()( )
	
// Version1 : horz PMs are OK
//	n += 1;	tPn[ n ] =	"PM:	   0:	1:	3:	0:	LstChan():	,°,°,°,°,°,°:	1°1°1°1°1°1°:	pmYAxis:		:	Y axis Max,Y axis Min,:	fYaxis():		55:		fYaxisLst():		:			:		:	"		// 	1-dim  popmenu (1 row)

// Version2 : vert PMs are 1 positioned too high  when there is no CR  (=PM: 0: ...) ???
	// n += 1;	tPn[ n ] =	"PM:	   1:	0:	3:	0:	LstChan():	,°,°,°,°,°,°:	1°1°1°1°1°1°:	pmYAxis:		Yax top,Yax bot,:			:	fYaxisPM():55:		fYaxisLstPM():	fYaxisInitPM():	:		:	"		// 	1-dim  popmenu (1 column)
	n += 1;	tPn[ n ] =	"SV:	   1:	0:	3:	0:	LstChan():	,°,°,°,°,°,°:	1°1°1°1°1°1°:	svYAxis:		Yax top,Yax bot,:			:	fYaxis():	55:		%.3lf;-inf,inf,0:	fYaxisInit():		:		:	"		// 	1-dim  SetVariable (1 column)
	n += 1;	tPn[ n ] =	"SV:	   0:	1:	3:	0:	LstChan():	,°,°,°,°,°,°:	1°1°1°1°1°1°:	svXAxis:		:			Xax left,Xax right:	fXAxis():	55:		%.3lf;0,inf,0:	fXaxisInit():		:		:	"		//  	1 dim  SetVariable( 1 row)

	n += 1;	tPn[ n ] =	"SEP:  0:	0:	1:	0:	LstChan():	,:		,:			dum2a:		:			:			:			:		:			:			:		:	"		//	single separator needs ',' 

	n += 1;	tPn[ n ] =	"SV:	   1:	0:	3:	0:	LstChan():	,°,°,°,°,°,°:	1°1°1°1°1°1°:	svReg:		:			Eval Regions:	fReg():		35:		%2d;0,"+num2str(kRG_MAX)+",1:0000_2;1000_1:::"		//  !!! upper limit = kRG_MAX
	n += 1;	tPn[ n ] =	"PM:	   1:	0:	3:	0:	LstChan():	LstReg():	1,1,1,°1,1,1,°:	pmUpDn:		:			Peak Dir:		fPkDir():		55:		fPkDirLst():	0000_2;~1:	:		:	"		// 	1-dim  popmenu (1 col)
	n += 1;	tPn[ n ] =	"CB:	   0:	1:	3:	0:	LstChan():	LstReg():	1°1°1°1°1°1°:	cbChkNs:		:			Check noise:	fChkNoise():	:		:			0000_1;~0:	:		:	"		// 	single checkbox
	n += 1;	tPn[ n ] =	"CB:	   0:	2:	3:	0:	LstChan():	LstReg():	1°1°1°1°1°1°:	cbAutUs:		:			Auto/User:	fAutoUser():	:		:			0000_0;~1:	:		:	"		// 	single checkbox

	// The initial visibility of  'FiFnc'  and  'FiRng'   must be the same as the initial values of the  'Fit'  checkbox
	n += 1;	tPn[ n ] =	"CB:	   1:	0:	3:	0:	LstChan():	LstReg():	1,1,1,°1,1,1,°:	cbFit:		fFitRowTitles():	Fit:			fFit():			:		:			fFitOnOff():		:		:	"		// !!! the # of row titles ~ # of fits
	n += 1;	tPn[ n ] =	"PM:	   0:	1:	3:	0:	LstChan():	LstReg():	1,°:			pmFiFnc:		fFitRowDums():	Fn:			fFitFnc():		85:		fFitFncLst():	fFitFncInit():	fFitOnOff():	:	"		// 	1-dim  popmenu (1 col)
	n += 1;	tPn[ n ] =	"PM:	   0:	2:	3:	0:	LstChan():	LstReg():	1,1,1,°1,1,1,°:	pmFiRng:		fFitRowDums():	Rng:			fFitRng():		62:		fFitRngLst():	fFitRngInit():	fFitOnOff()::	"		// 	1-dim  popmenu (1 col)
	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	LstChan():	,:		1,°:			dum2b:		:			:			:			:		:			:			:		:	"		//	single separator needs ','

//	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	LstChan():	,:		1,°:			dum2c:		:			:			:			:		:			:			:		:	"		//	single separator needs ','
//	n += 1;	tPn[ n ] =	"BU:    1:	0:	8:	0:	LstChan():	,°,°,°,°,°,°:	1°:			buDiYShrink:	Y Shr:		:			fYShrink():		:		:			:			:		:	"		//	single button
//	n += 1;	tPn[ n ] =	"BU:    0:	1:	8:	0:	LstChan():	,°,°,°,°,°,°:	1°:			buDiYExpand:	Y Exp:		:			fYExpand():	:		:			:			:		:	"		//	single button
//	n += 1;	tPn[ n ] =	"BU:    0:	2:	8:	0:	LstChan():	,°,°,°,°,°,°:	1°:			buDiYUp:		Y Up:		:			fYUp():		:		:			:			:		:	"		//	single button
//	n += 1;	tPn[ n ] =	"BU:    0:	3:	8:	0:	LstChan():	,°,°,°,°,°,°:	1°:			buDiYDown:	Y Dwn:		:			fYDown():		:		:			:			:		:	"		//	single button
//	n += 1;	tPn[ n ] =	"BU:    0:	4:	8:	0:	LstChan():	,°,°,°,°,°,°:	1°:			buDiXShrink:	X Shr:		:			fXShrink():		:		:			:			:		:	"		//	single button
//	n += 1;	tPn[ n ] =	"BU:    0:	5:	8:	0:	LstChan():	,°,°,°,°,°,°:	1°:			buDiXExpand:	X Exp:		:			fXExpand():	:		:			:			:		:	"		//	single button
//	n += 1;	tPn[ n ] =	"BU:    0:	6:	8:	0:	LstChan():	,°,°,°,°,°,°:	1°:			buDiXLeft:		X Left:		:			fXLeft():		:		:			:			:		:	"		//	single button
//	n += 1;	tPn[ n ] =	"BU:    0:	7:	8:	0:	LstChan():	,°,°,°,°,°,°:	1°:			buDiXRight:	X Rite:		:			fXRight():		:		:			:			:		:	"		//	single button

	// TabGroup: One untabbed  separator
	//n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:		,:		,:			dum8e:		Stimfit keys:	:			:			:		:			:			:		:	"		//	single separator needs ','  for 'Blks'  and 'dummy' for 'Name'
	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:		,:		,:			dum2d:		:			:			:			:		:			:			:		:	"		//	single separator needs ','  for 'Blks'  and 'dummy' for 'Name'
	n += 1;	tPn[ n ] =	"BU:    1:	0:	8:	0:	°:		,:		1°:			buDiYShrink:	Y Shr:		:			fYShrink():		:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	1:	8:	0:	°:		,:		1°:			buDiYExpand:	Y Exp:		:			fYExpand():	:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	2:	8:	0:	°:		,:		1°:			buDiYUp:		Y Up:		:			fYUp():		:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	3:	8:	0:	°:		,:		1°:			buDiYDown:	Y Dwn:		:			fYDown():		:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	4:	8:	0:	°:		,:		1°:			buDiXShrink:	X Shr:		:			fXShrink():		:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	5:	8:	0:	°:		,:		1°:			buDiXExpand:	X Exp:		:			fXExpand():	:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	6:	8:	0:	°:		,:		1°:			buDiXLeft:		X Left:		:			fXLeft():		:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	7:	8:	0:	°:		,:		1°:			buDiXRight:	X Rite:		:			fXRight():		:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    1:	0:	8:	0:	°:		,:		1,°:			buBaseLCsr:	base l:		:			buDiBaseLSetCsr():	:	:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	1:	8:	0:	°:		,:		1,°:			buBaseRCsr:	Base r:		:			buDiBaseRSetCsr():	:	:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	2:	8:	0:	°:		,:		1,°:			buPeakBCsr:	PeakB:		:			buDiPeakBegCsr():	:	:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	3:	8:	0:	°:		,:		1,°:			buPeakECsr:	PeakE:		:			buDiPeakEndCsr():	:	:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	4:	8:	0:	°:		,:		1,°:			buFit0BCsr:	Fit B:			:			buDiFit0BegCsr():	:	:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	5:	8:	0:	°:		,:		1,°:			buFit0ECsr:	Fit E:			:			buDiFit0EndCsr():	:	:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	6:	8:	0:	°:		,:		1,°:			buFit1BCsr:	G fit B:		:			buDiFit1BegCsr():	:	:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	7:	8:	0:	°:		,:		1,°:			buFit1ECsr:	G fit E:		:			buDiFit1EndCsr():	:	:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    1:	0:	8:	0:	°:		,:		1,°:			buDiMove:	Move:		:			buDiMove():	:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	1:	8:	0:	°:		,:		1,°:			buDiResults:	Result:		:			buDiResults():	:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	2:	8:	0:	°:		,:		1,°:			buDiInfo:		Info:			:			buDiInfo():		:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	3:	8 :	0:	°:		,:		1,°:			buDiRescale:	rescale:		:			buDiRescale():	:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	4:	8:	0:	°:		,:		1,°:			buDiPlus:		+pkpts:		:			fDiPlus():		:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	5:	8:	0:	°:		,:		1,°:			buDiMinus:	-pkpts:		:			fDiMinus():		:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:		,:		,:			dum4:		:			:			:			:		:			:			:		:	"		//	single separator needs ',' 

	// TabGroups...: Some untabbed  1dim..3dim controls
	n += 1;	tPn[ n ] =	"RAD: 1:	0:	6:	0:	°:		,:		1,°:			raStVal:		:			StartVal,Do fit,:	fStartVal():		:		:			:			:		:	"		//	1-dim horz radios
	n += 1;	tPn[ n ] =	"SV:	   0:	2:	3:	0:	°:		,:		,:			svSideP:		:			Peak pts 1side:	fSidePts():		35:		%2d;0,20,1:	0000_5:		:		:	"		//  single  SetVariable

 
	n += 1;	tPn[ n ] =	"PM:	   1:	0:	3:	0:	°:		,:		,:			pmLaCsr:		:			Lat Curs:		fLatCursor():	70:		fLatCursorLst():	:			:		:	"		// 	1-dim  popmenu (1 row)
	n += 1;	tPn[ n ] =	"PM:	   0:	1:	3:	0:	°:		,:		,:			pmAutoSel:	:			Auto:			fAutoSelect():	72:		fAutoSelectLst():	:			:		:	"		// 	1-dim  popmenu (1 row)
	n += 1;	tPn[ n ] =	"PM:	   0:	2:	3:	0:	°:		,:		,:			pmPrRes:		:			Print:			fPrintReslts():	72:		fPrintResltsLst():	:			:		:	"		// 	1-dim  popmenu (1 row)

	n += 1;	tPn[ n ] =	"CB:	   1:	0:	3:	0:	°:		,:		,:			cbSmeTm:		Same Time:	:			fSameTime():	:		:			:			:		:	"		// 	1-dim  popmenu (1 row)
	n += 1;	tPn[ n ] =	"CB:	   0:	1:	3:	0:	°:		,:		,:			cbMltKp:		Multiple Keeps:	:			fMultKeeps():	:		:			:			:		:	"		// 	1-dim  popmenu (1 row)
	n += 1;	tPn[ n ] =	"CB:	   0:	2:	3:	0:	°:		,:		1,°:			cbResTB:		Results:		:			fResultTxtbox():	:		:			:			:		:	"		// 	1-dim  checkbox(1 row)
//	n += 1;	tPn[ n ] =	"CB:	   0:	2:	3:	0:	°:		,:		1,°:			cbShwAv:		Show Aver:	:			fShowAver():	:		:			:			:		:	"		// 	1-dim  popmenu (1 row)
//	n += 1;	tPn[ n ] =	"PM:	   1:	0:	3:	0:	°:		,:		,:			pmDspTr:		:			Disp:			fDspTraces():	85:		fDspTracesLst()::			:		:	"		// 	1-dim  popmenu (1 row)

	n += 1;	tPn[ n ] =	"CB:	   1:	0:	3:	0:	°:		,:		1,°:			cbDispCsr:		Disp Cursors:	:			fDispCurs():	:		:			;~1:			:		:	"		// 	1-dim  checkbox(1 row)
	n += 1;	tPn[ n ] =	"BU:    0:	1:	3:	0:	°:		,:		1,°:			buAutoC:		Auto Set Cursors:	:		fAutoSetCurs():	:		:			:			:		:	"		//	single button

	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:		,:		,°:			dum6a:		:			:			:			:		:			:			:		:	"		//	single separator needs ','
	n += 1;	tPn[ n ] =	"SV:    1:	0:	3:	0:	°:		,:		1,:			gAvgKeepCnt:	# Averaged:	:			:	  		40:		%4d; 0,0,0:	:			:		:	"
	n += 1;	tPn[ n ] =	"STR:  0:	1:	3:	1:	°:		,:		1,°:			gsAvgNm:		Avg:			:			fAvgNm():		210:		:			:			:		:	"		//  	single  SetVariable inputing a String
	n += 1;	tPn[ n ] =	"CB:	   1:	0:	3:	0:	°:		,:		1,°:			gbDispAvg:	Disp average:	:			fDispAvg():	:		:			:			:		:	"		// 	1-dim  checkbox(1 row)
	n += 1;	tPn[ n ] =	"BU:    0:	1:	3:	0:	°:		,:		1,°:			buEraseAvg:	Erase Avg:	:			fEraseAvg():	:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	2:	3:	0:	°:		,:		1,°:			buSaveAvg:	save avg:		:			fSaveAvg():	:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:		,:		,°:			dum6d:		:			:			:			:		:			:			:		:	"		//	single separator needs ','

	n += 1;	tPn[ n ] =	"SV:    1:	0:	3:	0:	°:		,:		1,:			gEvaluatCnt:	# Evaluated:	:			:	  		40:		%4d; 0,0,0:	:			:		:	"		//	single SetVariable
	n += 1;	tPn[ n ] =	"BU:    0:	1:	3:	0:	°:		,:		1,°:			buClrRSelDr:	clear draw selection:	:		fClearResSelDr():	:	:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"CB:    0:	2:	3:	0:	°:		,:		1,°:			cbResSelDr:	select draw results:	:		fResSelectDr():	:	:			:			:		:	"		//	single checkbox
	n += 1;	tPn[ n ] =	"BU:    1:	1:	3:	0:	°:		,:		1,°:			buClrRSelPr:	clear print selection:	:		fClearResSelPr():	:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"CB:    0:	2:	3:	0:	°:		,:		1,°:			cbResSelPr:	select print results:	:		fResSelectPr():	:	:			:			:		:	"		//	single checkbox
	n += 1;	tPn[ n ] =	"CB:	   1:	0:	3:	0:	°:		,:		1,°:			gbDispTbl:		disp table:		:			fDispTbl():		:		:			:			:		:	"		// 	single checkbox
	n += 1;	tPn[ n ] =	"BU:    0:	1:	3:	0:	°:		,:		1,°:			buResetTbl:	reset tbl:		:			fResetTbl():	:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	2:	3:	0:	°:		,:		1,°:			buSaveTbl:	save tbl:		:			fSaveTbl():	:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:		,:		,°:			dum6g:		:			:			:			:		:			:			:		:	"		//	single separator needs ','

	n += 1;	tPn[ n ] =	"CB:	   1:	0:	3:	0:	°:		,:		1,°:			gbDispUnsel:	Disp unselected::			fDispUnSel():	:		:			:			:		:	"		// 	1-dim  checkbox(1 row)
	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:		,:		,°:			dum6j:		:			:			:			:		:			:			:		:	"		//	single separator needs ','
//	n += 1;	tPn[ n ] =	"BU:    1:	0:	3:	0:	°:		,:		1,°:			buResActCol:	Reset Column:	:			fResActColumn()::		:			:			:		:	"		//	single button
//	n += 1;	tPn[ n ] =	"BU:    1:	0:	3:	0:	°:		,:		1,°:			buClearWindow:ClearWindow:	:			fClearWindow():	:		:			:			:		:	"		//	single button

	// Script and stimulus reconstruction
	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:		,:		,:			dum7a:		Script and stimulus reconstruction:	:	:	:		:			:			:		:	"		//	single separator needs ','  for 'Blks'  and 'dummy' for 'Name'
	n += 1;	tPn[ n ] =	"BU:    1:	0:	3:	0:	°:		,:		1,°:			buEvStimDlg:	Display stimulus:	:			fEvStimDlg():	:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"CB:	   1:	0:	5:	0:	°:		,:		1,°:			gbShwScr:	Script:		:			fShowScript():	:		:			:			:		:	"		// 	1-dim  popmenu (1 row)
	n += 1;	tPn[ n ] =	"RAD: 0:	1:	5:	0:	°:		,:		1,°:			raCfsHeadr:	:			fCfsHeaderLst():	fCfsHeader():	:		:			:			:		:	"		//	1-dim horz radios
	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:		,:		,°:			dum7c:		:			:			:			:		:			:			:		:	"		//	single separator needs ','

	// Saving and recalling panel settings
	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:		,:		,:			dum8a:		Save and recall settings:	:	:			:		:			:			:		:	"		//	single separator needs ','  for 'Blks'  and 'dummy' for 'Name'
	n += 1;	tPn[ n ] =	"STR:  1:	0:	4:	1:	°:		,:		1,°:			svSave:		Save:		:			fSaveSets():	120:		:			:			:		:	"		//  	single  SetVariable inputing a String
	n += 1;	tPn[ n ] =	"PM:	   0:	2:	4:	1:	°:		,:		1,°:			pmRecal:		:			Recall:		fRecallSets():	120:		fRecallSetsLst():	:			:		:	"		// 	1-dim  popmenu (1 row)
	n += 1;	tPn[ n ] =	"BU:    1:	0:	4:	0:	°:		,:		1,°:			buDeflt:		Defaults:		:			fDefaults():		:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"CB:	   0:	1:	4:	1:	°:		,:		1,°:			cbAlDel:		Allow delete:	:			fCbAllowDelete()::		:			:			:		:	"		// 	1-dim  popmenu (1 row)
	n += 1;	tPn[ n ] =	"PM:	   0:	2:	4:	1:	°:		,:		1,°:			pmDelet:		Delete:		:			fDeleteSets():	120:		fRecallSetsLst():	:			:		:	"		// 	1-dim  popmenu (1 row)
	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:		,:		,:			dum8e:		More panels and options:	:	:			:		:			:			:		:	"		//	single separator needs ','  for 'Blks'  and 'dummy' for 'Name'
	n += 1;	tPn[ n ] =	"BU:    1:	0:	3:	0:	°:		,:		1,°:			buPreferDlg:	Preferences:	:			fEvPreferDlg():	:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	1:	3:	0:	°:		,:		1,°:			buDatUtlDlg:	Data utilities:	:			fEvDataUtilDlg()::		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    1:	0:	3:	0:	°:		,:		1,°:			buTst00:		TraceCfs Pts:	:			fTrcCfsPtsTest()::		:			:			:		:	"		//	single button
	if ( n >= nItems )
		DeveloperError( "Wave in panel " + sPnOptions + " needs more (at least " + num2str( n+1 )  + " ) elements. " )
	endif

	redimension  /N = ( n+1)	tPn
End

//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function 		fDispMode( s )
// display  'stacked'  or  'catenated'
	struct	WMPopupAction	&s
	fPopup_struct1( s )											// sets the global variable
	RedrawWindows()
End
Function		fDispModeLst( sControlNm, sFo, sWin )
	string		sControlNm, sFo, sWin
	PopupMenu	$sControlNm, win = $sWin,	 value = lstDISPMODE		// e.g. "single;stack;catenate;"
End


Function 		fActiveColumn( s )
	struct	WMPopupAction	&s
	fPopup_struct1( s )											// sets the global variable
	nvar		gnActiveCol	= root:uf:eval:evl:gnActiveCol
	gnActiveCol	= s.popNum 			// 1 : Prot , 3 : Frm	( starting at 1 as LinSweep has column 0 but cannot be selected)
End
Function		fActiveColumnLst( sControlNm, sFo, sWin )
	string		sControlNm, sFo, sWin
	PopupMenu	$sControlNm, win = $sWin,	 value = lstCOL_SEL_NAMES			// e.g. "Prot;Block;Frame;Sweep;PoN;"  // the column names of the selectable columns excluding LinSweep which has index 0
End


Function 		fDispUnsel( s )
// display or hide unselected traces (=data units)
	struct	WMCheckboxAction	&s
	RedrawWindows()
End

//--------------------------------------------------------------------------------------------------------------------------------------------

Function 		fDispAvg( s )
	struct	WMCheckboxAction	&s
	DSDisplayAverage()
End


Function		fEraseAvg( s ) 
// Called when a button is pressed.  ALSO CALLED when moving the mouse over a button.  See  'fButtonProc_struct()'  on how to avoid this event.
	struct	WMButtonAction	&s
	if (  s.eventCode != kCCE_idle  &&  s.eventCode != kCCE_mousemoved  &&  s.eventCode != kCCE_leave  &&  s.eventCode != kCCE_enter  &&  s.eventCode != kCCE_mouseup ) 
		print 		s.ctrlname
		DSEraseAverages()
	endif
End

Function		fSaveAvg( s )
// Called when a button is pressed.  ALSO CALLED when moving the mouse over a button.  See  'fButtonProc_struct()'  on how to avoid this event.
	struct	WMButtonAction	&s
	if (  s.eventCode != kCCE_idle  &&  s.eventCode != kCCE_mousemoved  &&  s.eventCode != kCCE_leave  &&  s.eventCode != kCCE_enter  &&  s.eventCode != kCCE_mouseup ) 
		print 		s.ctrlname
		DSSaveAverage()
	endif
End


Function		fAvgNm( s )
	struct	WMSetvariableAction    &s

// 	...............WITHOUT fSetvar_struct1( s )	
//	fSetvar_struct1( s )											// sets the global variable

	svar		gsAvgNm	= root:uf:eval:D3:gsAvgNm0000					// If the user entered a file name including the index, then strip the index and..
	variable	nPathParts= ItemsInList( s.sVal, ":" )
	string  	sDriveDir	= RemoveEnding( RemoveListItem( nPathParts-1, s.sVal, ":" ), ":" )
	if ( ! FPDirectoryExists( sDriveDir ) )
		PossiblyCreatePath( sDriveDir )
	endif
	gsAvgNm	= ConstructNextResultFileNmA( s.sVal, ksAVGEXT )			// ..search the next free avg file index and display it in the SetVariable input field
	// printf "%s   %s    ->  %s \r", s.CtrlName, s.sVal, gsAvgNm
End

//--------------------------------------------------------------------------------------------------------------------------------------------

Function 		fDispTbl( s )
	struct	WMCheckboxAction	&s
//	DSDisplayAverage()
End


Function		fResetTbl( s ) 
// Called when a button is pressed.  ALSO CALLED when moving the mouse over a button.  See  'fButtonProc_struct()'  on how to avoid this event.
	struct	WMButtonAction	&s
	if (  s.eventCode != kCCE_idle  &&  s.eventCode != kCCE_mousemoved  &&  s.eventCode != kCCE_leave  &&  s.eventCode != kCCE_enter  &&  s.eventCode != kCCE_mouseup ) 
		print 		s.ctrlname
		EraseTables()
	endif
End

Function		fSaveTbl( s )
// Called when a button is pressed.  ALSO CALLED when moving the mouse over a button.  See  'fButtonProc_struct()'  on how to avoid this event.
	struct	WMButtonAction	&s
	if (  s.eventCode != kCCE_idle  &&  s.eventCode != kCCE_mousemoved  &&  s.eventCode != kCCE_leave  &&  s.eventCode != kCCE_enter  &&  s.eventCode != kCCE_mouseup ) 
		print 		s.ctrlname
		SaveTables()
	endif
End


Function		fTblNm( s )
// copied from 'Avg'
	struct	WMSetvariableAction    &s

// 	...............WITHOUT fSetvar_struct1( s )	
//	fSetvar_struct1( s )											// sets the global variable

	svar		gsTblNm	= root:uf:eval:D3:gsTblNm0000					// If the user entered a file name including the index, then strip the index and..
	variable	nPathParts= ItemsInList( s.sVal, ":" )
	string  	sDriveDir	= RemoveEnding( RemoveListItem( nPathParts-1, s.sVal, ":" ), ":" )
	if ( ! FPDirectoryExists( sDriveDir ) )
		PossiblyCreatePath( sDriveDir )
	endif
	gsTblNm	= ConstructNextResultFileNmA( s.sVal, ksTABLEEXT )			// ..search the next free tbl file index and display it in the SetVariable input field
	// printf "%s   %s    ->  %s \r", s.CtrlName, s.sVal, gsAvgNm
End

//--------------------------------------------------------------------------------------------------------------------------------------------

Function 		fResActColumn( s )
// The correspondence between traces in listbox / on screen / analysed  must be maintained. 
// Called when a button is pressed.  ALSO CALLED when moving the mouse over a button.  See  'fButtonProc_struct()'  on how to avoid this event.
	struct	WMButtonAction	&s
	if (  s.eventCode != kCCE_idle  &&  s.eventCode != kCCE_mousemoved  &&  s.eventCode != kCCE_leave  &&  s.eventCode != kCCE_enter  &&  s.eventCode != kCCE_mouseup ) 
		print 		s.ctrlname
		nvar		col	= root:uf:eval:evl:gnActiveCol
		ResetColumnLB( col )
	//	RedrawWindows()
	endif
End


Function 		buClearWindow( sCtrlNm ) : ButtonControl
// Only for testing.  Normally traces are cleared  ONLY  by  resetting them in the listbox as only then the correspondence between traces in listbox / on screen / analysed  is maintained. 
	string  	sCtrlNm
	ClearWindows()
End


Function 		pmShowWindow( sCtrlNm, popNum, popStr ) : PopupMenuControl
// Display the graph window for the trace segments. Construct it or bring it to front (the user may have closed it).
	string  	sCtrlNm, popStr
	variable 	popNum
	variable	ch	= popNum - 1
	string  	sWNm	= EvalWndNm( ch )
	if ( WinType( sWNm ) != kGRAPH ) 									// Only if there is no previous instance of this window...
		BuildEvalWnd( sWNm, ch, 3 )		
		RedrawWindows()
	else
		if ( IsMinimized1( sWnm ) )
			MoveWindow /W=$sWNm	1, 1, 1, 1							// restore the old size 
		else
			DoWindow 	/F $sWNm								// move to front
		endif
	endif
//	RedrawWindows()
End
Function		pmShowWindow_Lst( sControlNm )
	string		sControlNm
	PopupMenu	$sControlNm	 value = ListOfChans()
End
Function	/S	ListOfChans()
	nvar		gChannels		= root:uf:cfsr:gChannels
	variable	ch
//	string  	lstChans	= ";"
//	for ( ch = 0; ch < gChannels; ch += 1 )
//		lstChans	= AddListItem( num2str( ch ), lstChans, ";", inf )
//	endfor
	string  	lstChans	= "0;"							// after loading a file there will always be a channel  0 as any channel list starts with 0
	for ( ch = 1; ch < gChannels; ch += 1 )						// if we fill in the 0 already right here (before a file is loaded) we save updating the listbox.. 
		lstChans	= AddListItem( num2str( ch ), lstChans, ";", inf )	//..when a file is loaded
	endfor
	return	lstChans
End

// .............................

Function		fColRange( s )
	struct	WMCheckboxAction	&s
	fRadio_struct3( s )
	string  	sProcNm 		= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	string  	sFoRadVar
 	sFoRadVar	= (s.CtrlName)[ 0,  strlen( s.CtrlName ) - 3 ] // - 1 ]	// Assumption: each tab/block has it's own radio setting. Change  -3 -> -1 to have just 1 radio setting for all tabs/blocks
 	sFoRadVar	= ReplaceString( "_",  sFoRadVar, ":" )
	nvar		nGlobal		= $sFoRadVar					// retrieve the state of radio button group from this ONE global variable
	printf "\t\t%s   \t\t%s\tb:%2d  =\t%d : from control   \t\t\tFrom global nvar \t'%s' : \t\t%d  \r", sProcNm, pd(s.CtrlName,26), s.checked, PnValC( s.CtrlName ), sFoRadVar, nGlobal
End

Function	/S	fColRangeLst()
	return	lstCOL_RANGE
End
// .............................

Function	/S	LstChan()
	nvar		gChans	= root:uf:cfsr:gChannels
	variable	ch
	string  	lstChans	= ""
	for ( ch = 0; ch < gChans; ch += 1 )
		lstChans	+= CfsIONm( ch ) + ksSEP_TAB
	endfor
	return	lstChans
End	

Function	/S	LstReg()
// todo..............
	string  	lstRegs		= ""
	string  	lstChans		= LstChan()
	variable	r, n, nChans	= ItemsInList( lstChans, ksSEP_TAB )
	for ( n = 0; n < nChans; n += 1 )
		string  	svRegNm	= "root:uf:eval:D3:svReg" + num2str( n ) + "000"	// root:uf:eval:D3:svReg0000,  root:uf:eval:D3:svReg1000, ...
		nvar		nRegs	= $svRegNm	
		for ( r = 0; r < nRegs; r += 1 )
			lstRegs	   +=  ksSEP_STD  				//	the block prefix for the title may be empty only containing separators (to determine the number of regions/blocks)
		endfor
		lstRegs	   +=  ksSEP_TAB
	endfor
	// printf "\t\t\t\tLstReg():\t'%s'  \r", lstRegs
	return	lstRegs
End



constant	kEV_VIEW = 0,  kEV_AVER = 1,  kEV_EVAL = 2

Function		fEvalChannel( s )
// Checkbox action proc....
	struct	WMCheckboxAction	&s
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	variable	ch	= TabIdx( s.ctrlName )
	variable	typ	= ColIdx( s.ctrlName ) 
	  printf "\t%s\t%s\tch:%2d\tty:%2d\tb:%2d  =\t%d : from control \r",   pd(sProcNm,15), pd(s.CtrlName,31), ch, typ, s.checked, PnValC( s.CtrlName )
	if ( typ == 2 )														// The 3. checkbox in the row = 'Evaluation on/off'
		nvar		gbDoEvaluation	= root:uf:eval:evl:gbDoEvaluation				// We turn the Evaluation  on...
		if ( s.checked == 1 )
			gbDoEvaluation			= TRUE									// ...
			DoEvaluation( gbDoEvaluation )
// todo : enable  the tabcontrol again
		else
			gbDoEvaluation			= FALSE									// ...
			DoEvaluation( gbDoEvaluation )
// todo : disable / gray the tabcontrol
		endif
		PanelRSUpdateDr()							// update the 'Select results' panel whose size has changed
		PanelRSUpdatePr()							// update the 'Select results' panel whose size has changed
	endif
End


//   The Y-axis limit control implemented as a popupmenu.  Disadvantage:  The control cannot be updated with arbitrary values resulting from setting  Y Expand  Shrink  Up  Down . For this reason a Setvariable is chosen.
//	Function		fYAxisPM( s )
//		struct	WMPopupAction	&s
//		fPopup_struct1( s )											// sets the global variable
//		string  	sPath	= ksEVALCFG_DIR 							// e.g.  'C:Epc:Data:EvalCfg:'   or   'C:UserIgor:Ced:'  , must contain drive letter
//		string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
//		string  	sFo	 	= GetUserData( 	s.win,  s.ctrlName,  "sFo" )			// e.g.  'root:uf:eval:' 
//		string  	sSubDir	= ReplaceString( "root:uf:", sFo, "" )		  		// e.g.  'root:uf:eval:' -> 'eval:'
//	
//		string		sFolderWave	= "root:uf:eval:evl:wChanOpts"
//		wave	wWave		= $sFolderWave						// ASSUMPTION: wave name MUST NOT contain underscores 
//		variable	ch			= TabIdx( s.ctrlName )
//		string		sWNm		= CfsWndNm( ch )
//		variable	typ	= RowIdx( s.ctrlName ) 
//		if ( typ == 0 )
//			 typ	= 3		// 3 is Yax max/top control.
//		elseif ( typ == 1 )
//			typ = 2		// 2 is Yax min/bott control.  		Old: +2 obsolete  to skip 'OnOff;RgCnt;'  in  "OnOff;RgCnt;YAxMin;YAxMax;"
//		endif
//		wWave[ ch ][ typ ]= s.popnum-1
//	
//		GetAxis	/Q	/W=$sWNm  left
//		variable	yBott	= typ == 2 ? str2num(  s.popStr ) : V_min			// also the global variable is set e.g. for ch 0 :	$"root:uf:eval:d3:pmYAxis0010"
//		variable	yTop	= typ == 3 ? str2num(  s.popStr ) : V_max			// also the global variable is set e.g. for ch 1 :	$"root:uf:eval:d3:pmYAxis1000"
//		SetAxis	/W=$sWNm  left, yBott, yTop		// change the graph immediately. Without this line the change would come into effect only later on the next  RescaleXAxis()
//	
//		  printf "\t%s\t%s\t%s\tAdapted:\tch:%d\tty:%d\t%s\t%s\t%g\tyBot: %g\tyTop: %g\t  \r",  pd(sProcNm,15), pd(s.CtrlName,31), sWNm, ch, typ, pd( s.popStr,9), pd(sFolderWave,23), wWave[ ch ][ typ ], yBott, yTop
//	End
//	
//	Function		fYaxisLstPM( sControlNm, sFo, sWin )
//		string		sControlNm, sFo, sWin
//		PopupMenu	$sControlNm, win = $sWin,	 value = ksYAXIS
//	End
//	
//	Function	/S	fYaxisInitPM()
//		return "0000_4;0010_16;1000_3;1010_15;"	// Syntax: tab blk row col 1-based-index; ...
//	End


Function		fYAxis( s )
// Change the Y-axis limits according to the users entries in the input field. Also adjust  wMagn[ ch ][ cYEXP ]  and  wMagn[ ch ][ cYSHIFT ]	
// RescaleYAxis()   and   fYAxis()  are interdependent  and must be changed together
	struct	WMSetvariableAction    &s
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	variable	ch		= TabIdx( s.ctrlName )
	variable	typ		= RowIdx( s.ctrlName ) 
	string		sWNm	= CfsWndNm( ch )
	if ( typ == 0 )
		 typ	= 3		// 3 is Yax max/top control.
	elseif ( typ == 1 )
		typ = 2		// 2 is Yax min/bott control.  		Old: +2 obsolete  to skip 'OnOff;RgCnt;'  in  "OnOff;RgCnt;YAxMin;YAxMax;"
	endif

	GetAxis	/Q	/W=$sWNm  left
	variable	yBott	= typ == 2 ? s.dVal : V_min			// also the global variable is set e.g. for ch 0 :	$"root:uf:eval:d3:svYAxis0010"
	variable	yTop	= typ == 3 ? s.dVal : V_max			// also the global variable is set e.g. for ch 1 :	$"root:uf:eval:d3:svYAxis1000"
	SetAxis	/W=$sWNm  left, yBott, yTop			// change the graph immediately. Without this line the change would come into effect only later on the next  RescaleXAxis()

	// Update   wMagn[][]  and wMnMx[][]   with values  which were computed  from the settings in the  Y-Axis Setvariable limit fields
	wave	wMagn		= root:uf:eval:evl:wMagn
	wave	wMnMx		= root:uf:eval:evl:wMnMx
	wMagn[ ch ][ cYEXP ]	= ( wMnMx[ ch ][ MM_YMAX  ] - wMnMx[ ch ][ MM_YMIN ] ) /  ( yTop - yBott ) 
	wMagn[ ch ][ cYSHIFT ]	= ( yBott * wMnMx[ ch ][ MM_YMAX ]  - yTop * wMnMx[ ch ][ MM_YMIN ] ) / ( wMnMx[ ch ][ MM_YMAX ] - wMnMx[ ch ][ MM_YMIN ] + yBott - yTop )
	  printf "\t%s\t%s\t%s\tch:%d\tty:%d\t%g\tyBot: %g\tyTop: %g\t  \r",  pd(sProcNm,15), pd(s.CtrlName,31), sWNm, ch, typ, s.dVal, yBott, yTop
	 printf "\t\t\tfYAxis()\t\tch:%2d \t bott:\t%g\ttop: %g\t->YEXP: %g \t YSHIFT: %g \r", ch, yBott, yTop, wMagn[ ch ][ cYEXP ], wMagn[ ch ][ cYSHIFT ]
End

Function	/S	fYaxisInit()
	return "0000_100;0010_-300;"					// Syntax: tab blk row col _ value
End



Function		fXAxis( s )
// Change the X-axis limits according to the users entries in the input field. Also adjust  wMagn[ ch ][ cXEXP ]  and  wMagn[ ch ][ cXSHIFT ]	
// RescaleXAxis()   and   fXAxis()  are interdependent  and must be changed together
	struct	WMSetvariableAction    &s
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	variable	ch		= TabIdx( s.ctrlName )
	variable	typ		= ColIdx( s.ctrlName ) 				// the minimum or the maximum value
	string		sWNm	= CfsWndNm( ch )
	//  printf "\t%s\t\t\t\t\t%s\tch:%d\tty:%d\t%s\t%s\t%g\t  \r",  pd(sProcNm,13), s.CtrlName, ch, typ, pd( s.popStr,9), pd(sFolderWave,23), wWave[ ch ][ typ ]
	 //  printf "\t%s\t%s\t%s\tch:%2d\tty:%2d\t%.2lf\t  \r",   pd(sProcNm,15), pd(s.CtrlName,31), sWNm, ch, typ,  s.dval
	GetAxis	/Q	/W=$sWNm  bottom
	variable	xLeft	    = typ == 0 ? s.dVal : V_min			// also the global variable is set e.g. for ch 0 :	$"root:uf:eval:d3:svXAxis0000"
	variable	xRight  = typ == 1 ? s.dVal : V_max			// also the global variable is set e.g. for ch 1 :	$"root:uf:eval:d3:svXAxis1001"
	SetAxis		/W=$sWNm  bottom, xLeft, xRight		// change the graph immediately. Without this line the change would come into effect only later on the next  RescaleXAxis()
	// Update   wMagn[][]  and wMnMx[][]   with values  which were computed  from the settings in the  X-Axis Setvariable limit fields
	wave	wMagn		= root:uf:eval:evl:wMagn
	wave	wMnMx		= root:uf:eval:evl:wMnMx
	wMagn[ ch ][ cXEXP ]	= ( wMnMx[ ch ][ MM_XMAX  ] - wMnMx[ ch ][ MM_XMIN ] ) /  ( xRight - xLeft ) 
	wMagn[ ch ][ cXSHIFT ]	= ( xLeft * wMnMx[ ch ][ MM_XMAX ]  - xRight * wMnMx[ ch ][ MM_XMIN ] ) / ( wMnMx[ ch ][ MM_XMAX ] - wMnMx[ ch ][ MM_XMIN ] + xLeft - xRight )
	 printf "\t\t\tfXAxis()\t\tch:%2d \t left:\t%g\tright: %g\t->XEXP: %g \t XSHIFT: %g \r", ch, xLeft, xRight, wMagn[ ch ][ cXEXP ], wMagn[ ch ][ cXSHIFT ]
End


Function	/S	fXaxisInit()
//	return "0000_0;0001_500;1000_10;~1000;"	// Syntax: tab blk row col _ value
	return "0000_0;1000_1.5;"					// Syntax: tab blk row col _ value
End



Function		fReg( s ) 
// Demo: this  SetVariable control  changes the number of blocks. Consequently the Panel must be rebuilt  OR  it must have a constant large size providing space for the maximum number of blocks.
	struct	WMSetvariableAction    &s
//	fSetvar_struct1( s )										// sets the global variable
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	variable	ch		= TabIdx( s.ctrlName )
	string  	lstRegs	= LstReg()
	  printf "\t%s\t\t\t\t\t%s\tvar:%g\t-> \tch:%d\tLstBlk3:\t%s\t  \r",  pd(sProcNm,13), pd(s.CtrlName,26), s.dval,ch, pd( lstRegs, 19)

	Panel3Main(   "D3", "Evaluation Details3", "root:uf:" + ksEVAL_, 2, 95 ) // Compute the location of panel controls and the panel dimensions. Draw the panel displaying and hiding needed/unneeded controls
	UpdateDependent_Of_AllowDelete( s.Win, "root_uf_eval_D3_cbAlDel0000" )	

	DisplayUsedFitCursors( ch )								// Display the used fit cursors and hide the unused fit cursors immediately depending on the state of the region and fit checkboxes to give the user a feedback which parts of the data will be fitted in the next analysis
	DisplayPkBsLatCursors( ch )
	PanelRSUpdateDr()							// update the 'Select results' panel whose size has changed
	PanelRSUpdatePr()							// update the 'Select results' panel whose size has changed
End
	
Function		fDispCurs( s )
// Checkbox action proc....
	struct	WMCheckboxAction	&s
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	  printf "\t\t%s(s)\t\t%s\tb:%2d  =\t%d : from control \r",  sProcNm, pd(s.CtrlName,26), s.checked, PnValC( s.CtrlName )
	variable	ch
	nvar		gChans		= root:uf:cfsr:gChannels					
	for ( ch = 0; ch < gChans; ch += 1 )
		if ( s.checked )
			DisplayPkBsLatCursors( ch )
			DisplayUsedFitCursors( ch )
		else	
			HidePkBsLatCursors( ch )
			HideAllFitCursors( ch )
		endif
	endfor
End

Function		DisplayUsedFitCursors( ch )
	// Display the used fit cursors and hide the unused fit cursors immediately depending on the state of the region and fit checkboxes to give the user a feedback which parts of the data will be fitted in the next analysis
	variable	ch
	nvar		nRgUsed	= $"root:uf:eval:D3:svReg" + num2str( ch ) + "000"
	string		sWnd 	= CfsWndNm( ch )
	variable	ph, rg	
	for ( rg = 0; rg < nRgUsed; rg += 1 )							// Display the used fit cursors 
		for ( ph =  PH_FIT0; ph <   ItemsInList( ksPHASES ); ph += 1 )
			if ( DoFit( ch, rg, ph ) )
				DisplayCursor( ch, rg, ph, CN_BEG, sWnd )
				DisplayCursor( ch, rg, ph, CN_END, sWnd )
			endif
		endfor
	endfor
	for ( rg = nRgUsed; rg < kRG_MAX; rg += 1 )					// Hide the unused fit cursors 
		for ( ph =  PH_FIT0; ph < ItemsInList( ksPHASES ); ph += 1 )
			HideCursor( ch, rg, ph, CN_BEG, sWnd )
			HideCursor( ch, rg, ph, CN_END, sWnd )
		endfor
	endfor
End


Function		HideAllFitCursors( ch )
	// Hide all  fit cursors 
	variable	ch
	string		sWnd 	= CfsWndNm( ch )
	variable	ph, rg
	for ( rg = 0; rg < kRG_MAX; rg += 1 )
		for ( ph =  PH_FIT0; ph < ItemsInList( ksPHASES ); ph += 1 )
			HideCursor( ch, rg, ph, CN_BEG, sWnd )
			HideCursor( ch, rg, ph, CN_END, sWnd )
		endfor
	endfor
End

Function		DisplayPkBsLatCursors( ch )
	// Display all  peak, base and latency cursors
	variable	ch
	nvar		nRgUsed	= $"root:uf:eval:D3:svReg" + num2str( ch ) + "000"
	string		sWnd 	= CfsWndNm( ch )
	variable	ph, rg
	for ( rg = 0; rg < nRgUsed; rg += 1 )							// Display the peak, base and latency cursors if their region is on
		for ( ph =  0; ph < PH_FIT0; ph += 1 )
			DisplayCursor( ch, rg, ph, CN_BEG, sWnd )
			DisplayCursor( ch, rg, ph, CN_END, sWnd )
		endfor
	endfor
	for ( rg = nRgUsed; rg < kRG_MAX; rg += 1 )					// Hide the peak, base and latency cursors 
		for ( ph =  0; ph < PH_FIT0; ph += 1 )
			HideCursor( ch, rg, ph, CN_BEG, sWnd )
			HideCursor( ch, rg, ph, CN_END, sWnd )
		endfor
	endfor
End


Function		HidePkBsLatCursors( ch )
	// Hide all  peak, base and latency cursors 
	variable	ch
	string		sWnd 	= CfsWndNm( ch )
	variable	ph, rg
	for ( rg = 0; rg < kRG_MAX; rg += 1 )
		for ( ph =  0; ph < PH_FIT0; ph += 1 )
			HideCursor( ch, rg, ph, CN_BEG, sWnd )
			HideCursor( ch, rg, ph, CN_END, sWnd )
		endfor
	endfor
End


Function		RegionCnt( ch )
	variable	ch
	string  	sCtrlNm	  = "root_uf_eval_D3_svReg" + num2str( ch ) + "000"
	ControlInfo /W= $"D3" $sCtrlNm
	variable	cnt	= V_Value	
	// printf "\t\t\tRegionCnt( ch:%d ) from SetVariable( %s ): %d \t \r", ch, sCtrlNm, cnt
	return	cnt
End


Function		fPkDir( s )
	struct	WMPopupAction	&s
	fPopup_struct1( s )										// sets the global variable
	string  	sPath	= ksEVALCFG_DIR 						// e.g.  'C:Epc:Data:EvalCfg:'   or   'C:UserIgor:Ced:'  , must contain drive letter
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	string  	sFo	 	= GetUserData( 	s.win,  s.ctrlName,  "sFo" )		// e.g.  'root:uf:eval:' 
	string  	sSubDir	= ReplaceString( "root:uf:", sFo, "" )		  	// e.g.  'root:uf:eval:' -> 'eval:'

	variable	ch	= TabIdx( s.ctrlName )
	variable	rg	= BlkIdx( s.ctrlName )
	  printf "\t%s\t%s\tch:%d  \trg:%d  \t%s\t%g\t  \r",  pd(sProcNm,15), pd(s.CtrlName,31), ch, rg, pd( s.popStr,9), (s.popnum-1)

	nvar		gPkSidePts	= root:uf:eval:D3:svSideP0000				// additional points on each side of a peak averaged to reduce noise errors 
	OnePeak( ch, rg, gPkSidePts )						// Do a peak determination immediately.  Flaw : Gets any data sweep.  If the display mode is 'single'  this will be the current sweep.  If the display mode is 'stacked'  it can be any sweep, ...
End


// strconstant	klstPEAKDIR 	= "down;up"
strconstant	klstPEAKDIR 	= "up;down;"	//  Can NOT be static!   This order is more intuitive in Popupmenu  050804

Function		fPkDirLst( sControlNm, sFo, sWin )
	string		sControlNm, sFo, sWin
	PopupMenu	$sControlNm, win = $sWin,	 value = klstPEAKDIR
End

Function		PeakIsUp( ch, rg )
// Returns TRUE if upward is the currently selected peak direction  in the popupmenu, else FALSE
	variable	ch, rg
	string  	sCtrlNm	  = "root_uf_eval_D3_pmUpDn" + num2str( ch )  + num2str( rg )  + "00"		// the phase in the control is (in contrast to fit phases) always 0 (and not PH_PEAK) 
	ControlInfo /W= $"D3" $sCtrlNm
	//variable	bPeakIsUp	= V_Value	- 1				// list order is  klstPEAKDIR = "down;up;"
	variable	bPeakIsUp	= 2 - V_Value				// list order is  klstPEAKDIR = "up;down;" , this order is more intuitive in Popupmenu  050804
	// printf "\t\t\tPeakIsUp( ch:%d, rg:%d, from Popupmenu( %s ): %d \t \r", ch, rg, sCtrlNm, bPeakIsUp
	return	bPeakIsUp
End

Function	/S	PeakDirStr( bPeakIsUp )
	variable	bPeakIsUp
	//return	StringFromList(    bPeakIsUp,  klstPEAKDIR ) 	// list order is  klstPEAKDIR = "down;up;"
	return	StringFromList( 1- bPeakIsUp, klstPEAKDIR ) 	// list order is  klstPEAKDIR = "up;down;" , this order is more intuitive in Popupmenu  050804
End


//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// 	Action procs for FITTING

Function	/S	fFitOnOff()
// Initial state of the  'Fit' checkboxes.   This same state mus also be used for the initial visibility of the dependent  'FitFunc'  and  'FitRange' controls
	return  "0010_1;0100_1;1120_1;~0"			// Syntax: tab blk row col 1-based-index;  (Tab0: Window,Peak  Tab2: Window,Cursor,  Tab3...: Window (=default)
End


Function	/S	fFitRowTitles()
	variable	nFit
	string  	lstRowTitles	= ""
	for ( nFit = 0; nFit <  ItemsInList( ksPHASES ) - PH_FIT0 ; nFit += 1 )
		lstRowTitles	+=  num2str( nFit + 1 ) + ". ,"  	// e.g.   '1. ,2. ,3. ,'
	endfor 
	// printf "\t\t\tfFitRowTitles() / fFitRowDums() :'%s' \r", lstRowTitles
	return	lstRowTitles
End

Function	/S	fFitRowDums()
// Supplies as many separators as there are titles in the controlling 'Fit' checkbox. They are needed for  'RowCnt()'  to preserve panel geometry, otherwise 'Fit' checkbox and 'FitFunc'/'FitRng' controls will appear in different lines. 
	variable	nFit
	string  	lstRowTitles	= ""
	for ( nFit = 0; nFit <  ItemsInList( ksPHASES ) - PH_FIT0 ; nFit += 1 )
		lstRowTitles	+=  ","  					// e.g.   ',,,'
	endfor 
	// printf "\t\t\tfFitRowTitles() / fFitRowDums :'%s' \r", lstRowTitles
	return	lstRowTitles
End


Function		fFit( s )
// Checkbox action proc....
	struct	WMCheckboxAction	&s
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	// printf "\t\t%s(s)\t\t%s\tb:%2d  =\t%d : from control \r",  sProcNm, pd(s.CtrlName,26), s.checked, PnValC( s.CtrlName )
	string  	sThisControl, sControlledCoNm
	
	sThisControl		= StripFoldersAnd4Indices( s.CtrlName )			// remove all folders and the 4 trailing numbers e.g. 'root_uf_eval_D3_cbFit0000'  -> 'cbFit' 

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
	variable	ph		= RowIdx( s.ctrlName ) + PH_FIT0 
	string		sWnd 	= CfsWndNm( ch )
	//  printf "\t%s\t%s\tch:%d\trg:%d\tph:%d\t on:%d\tbVis:%d\t  \r",  pd(sProcNm,15), pd(s.CtrlName,25), ch, rg, ph, s.Checked, bVisib
	if ( s.checked  )
		DisplayCursor( ch, rg, ph, CN_BEG, sWnd )
		DisplayCursor( ch, rg, ph, CN_END, sWnd )
	else
		HideCursor( ch, rg, ph, CN_BEG, sWnd )
		HideCursor( ch, rg, ph, CN_END, sWnd )
	endif

	// Do a fit immediately. 
	string		sFoldOrgWvNm		= GetOnlyOrAnyDataTrace( ch )
	wave	wOrg				= $sFoldOrgWvNm
	OneFit( wOrg, ch, rg, ph )						// will fit only if  'Fit' checkbox is 'ON'

	PanelRSUpdateDr()							// update the 'Select results' panel whose size has changed
	PanelRSUpdatePr()							// update the 'Select results' panel whose size has changed
End


static Function	/S	GetOnlyOrAnyDataTrace( ch )
	variable	ch
	// Version 1 : Get the current sweep. ++ Gets  even in  'stacked' display mode the current trace, ignores all others.  -- Needs global current sweep and  global current size. 
	wave	wCurRegion	= root:uf:eval:evl:wCurRegion
	variable  	nCurSwp		= wCurRegion[ kCURSWP ]	
	variable  	nSize		= wCurRegion[ kSIZE ]	
	string		sTrc			= FoOrgWvNm( ch, nCurSwp, nSize )		// CAVE : RETURNS wave name including folder  -->  wOrg = $ sTrc
	//  printf "\tGetOnlyOrAnyDataTrace( ch:%d )  '%s' \r", ch, sTrc	
	return	sTrc											// CAVE : RETURNS wave name including folder  -->  wOrg = $ sTrc
End

//Function	/S	GetOnlyOrAnyDataTrace( ch, sWNm )
//	// Version 2 : Get any data sweep.  If the display mode is 'single'  this will be the current sweep.  If the display mode is 'stacked'  it can be any sweep, ...
//	// ..which is also OK as this function is thought to only give some feedback to the user when he changed the fit settings (called only in an 'Fit' action procedures) . 
//	string		sPointsMatch	= "wpY_"  		// the points waves
//	string		sCursorsMatch	= "wcY_"  		// the cursors waves
//	string		sFitsMatch		= "wF_"  			// the fit waves
//	string		sDummyMatch	= "wDummy"  		// dummy wave introduced as a workaround in  'EraseTracesInGraphExcept()'  , should not be necessary and should be removed...
//	string 	sTNL		= TraceNameList( sWNm, ";", 1 )
//	
//	 printf "\tGetOnlyOrAnyDataTrace( ch:%d )  original :\t\ttraces:%d  TrcNmList:%s \r", ch, ItemsInList( sTNL ), sTNL[0,160]	
//	sTNL			= ListMatch( sTNL, "!" + sPointsMatch + "*" )
//	 printf "\tGetOnlyOrAnyDataTrace( ch:%d )  after cleaning p:\ttraces:%d  TrcNmList:%s \r", ch, ItemsInList( sTNL ), sTNL[0,160]	
//	sTNL			= ListMatch( sTNL, "!" + sCursorsMatch + "*" )
//	 printf "\tGetOnlyOrAnyDataTrace( ch:%d )  after cleaning c:\ttraces:%d  TrcNmList:%s \r", ch, ItemsInList( sTNL ), sTNL[0,160]	
//	sTNL			= ListMatch( sTNL, "!" + sFitsMatch + "*" )
//	 printf "\tGetOnlyOrAnyDataTrace( ch:%d )  after cleaning c:\ttraces:%d  TrcNmList:%s \r", ch, ItemsInList( sTNL ), sTNL[0,160]	
//	sTNL			= ListMatch( sTNL, "!" + sDummyMatch + "*" )
//	 printf "\tGetOnlyOrAnyDataTrace( ch:%d )  after cleaning c:\ttraces:%d  TrcNmList:%s \r", ch, ItemsInList( sTNL ), sTNL[0,160]	
//	return	StringFromList( 0, sTNL )			// CAVE : RETURNS wave name  without   folder  -->  wOrg = TraceNameToWaveRef( sWNm, sFoldOrgWvNm )
//End



Function		DoFit( ch, rg, ph )
// Returns the state of the   1. Fit -    or  2. Fit - checkbox.  Another approach: 'ControlInfo'
	variable 	ch, rg, ph	
	nvar		bFit	= $"root:uf:eval:D3:cbFit" + num2str( ch ) + num2str( rg ) + num2str( ph - PH_FIT0 ) + "0"	//e.g. for ch 0  and  rg 0  and  fit 1:  root:uf:eval:D3:cbFit0010
	return	bFit
End

Function		fFitFnc( s )
// Action proc of the fit function popupmenu
	struct	WMPopupAction	&s
	fPopup_struct1( s )											// sets the global variable
	string  	sPath	= ksEVALCFG_DIR 							// e.g.  'C:Epc:Data:EvalCfg:'   or   'C:UserIgor:Ced:'  , must contain drive letter
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	variable	ch		= TabIdx( s.ctrlName )
	variable	rg		= BlkIdx( s.ctrlName )
	variable	ph		= RowIdx( s.ctrlName )
	variable	nFitFnc	= s.popnum - 1
	 printf "\t%s\t%s\tch:%d \trg:%d \tph:%d \tnFitFnc:%d = '%s'\t \r",  pd(sProcNm,15), pd(s.CtrlName,25), ch, rg, ph, nFitFnc, StringFromList( nFitFnc, sFITFUNC )

	// Do a fit immediately.
	string		sFoldOrgWvNm		= GetOnlyOrAnyDataTrace( ch )
	wave	wOrg				= $sFoldOrgWvNm 
	OneFit( wOrg, ch, rg, ph+PH_FIT0 )				// will fit only if  'Fit' checkbox is 'ON'

	PanelRSUpdateDr()							// update the 'Select results' panel whose size may have changed
	PanelRSUpdatePr()							// update the 'Select results' panel whose size may have changed
End

Function		FitFnc( ch, rg, ph )
// Returns the index of the fit function currently selected in the popupmenu
	variable	ch, rg, ph
	ph		-= PH_FIT0
	string  	sCtrlNm	  = "root_uf_eval_D3_pmFiFnc" + num2str( ch )  + num2str( rg )  + num2str( ph ) + "0"
	ControlInfo /W= $"D3" $sCtrlNm
	variable	nFitFunc	= V_Value	- 1
	// printf "\t\tFitFnc( ch:%d, rg:%d, ph:%d (was%d) ) from Popupmenu( %s ): %d \t \r", ch, rg, ph, ph + PH_FIT0, sCtrlNm, nFitFunc
	return	nFitFunc
End


Function		fFitFncLst( sControlNm, sFo, sWin )
	string		sControlNm, sFo, sWin
	PopupMenu	$sControlNm, win = $sWin,	   value = sFITFUNC
End

Function	/S	fFitFncInit()
// The panel listbox is initially filled with the default fit functions given here. Syntax:   tab=ch  blk  row col  _ 1-based-index;  repeat n times;  ~ 1-based-index for all remaining controls; 
	string		sInitialFitFuncs	=  "0000_2;0010_1;1000_1;1010_1;1000_1;1010_1;1000_1;1010_1;~4;"	// e.g. : ( Tab=ch=0: Line,none  Tab=ch=1..3:none,none, other tabs and blocks>1: value 4 = 1exp+con
	// print "\t\tsInitialFitFuncs:", sInitialFitFuncs
	return	sInitialFitFuncs
End



Function		fFitRng( s )
	struct	WMPopupAction	&s
	fPopup_struct1( s )											// sets the global variable
	string  	sPath	= ksEVALCFG_DIR 							// e.g.  'C:Epc:Data:EvalCfg:'   or   'C:UserIgor:Ced:'  , must contain drive letter
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	string  	sFo	 	= GetUserData( 	s.win,  s.ctrlName,  "sFo" )			// e.g.  'root:uf:eval:' 
	string  	sSubDir	= ReplaceString( "root:uf:", sFo, "" )		  		// e.g.  'root:uf:eval:' -> 'eval:'
	variable	ch		= TabIdx( s.ctrlName )
	variable	rg		= BlkIdx( s.ctrlName )
	variable	ph		= RowIdx( s.ctrlName ) 
	variable	nFitRng	= s.popnum - 1
	  printf "\t%s\t%s\tch:%d  \trg:%d  \tph:%d  \t%s\t%g\t= '%s' \t  \r",  pd(sProcNm,15), pd(s.CtrlName,23), ch, rg, ph, pd( s.popStr,9), nFitRng,  StringFromList( nFitRng, klstFITRANGE )
	// Do a fit immediately. 
	string		sFoldOrgWvNm		= GetOnlyOrAnyDataTrace( ch )
	wave	wOrg				= $sFoldOrgWvNm
	OneFit( wOrg, ch, rg, ph+PH_FIT0 )
End

Function		fFitRngLst( sControlNm, sFo, sWin )
	string		sControlNm, sFo, sWin
	PopupMenu	$sControlNm, win = $sWin,	  value = klstFITRANGE
End

Function	/S	fFitRngInit()
//	return "0000_1;0010_3;1000_1;1010_2;"	// Syntax: tab blk row col 1-based-index;  (Tab0: Window,Peak  Tab2: Window,Cursor,  Tab3...: Window (=default)
	return "~2;"						// Syntax: remaining values (in this case all values) 
End

//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function		fChkNoise( s )
// Checkbox action proc....
	struct	WMCheckboxAction	&s
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	  printf "\t\t%s(s)\t\t%s\tb:%2d  =\t%d : from control \r",  sProcNm, pd(s.CtrlName,26), s.checked, PnValC( s.CtrlName )
End

Function		CheckNoise( ch, rg )
// Returns the state of the   'Check noise' - checkbox.  Another approach: 'ControlInfo'
	variable 	ch, rg
	nvar		bCheckNoise	= $"root:uf:eval:D3:cbChkNs" + num2str( ch ) + num2str( rg ) + "00"	//e.g. for ch 0  and  rg 1:  root:uf:eval:D3:cbChkNs0100
	// printf "\t\t\tCheckNoise( ch:%d, rg:%d ) returns   %d \r", ch, rg, bCheckNoise
	return	bCheckNoise
End


Function		fAutoUser( s )
// Checkbox action proc....
	struct	WMCheckboxAction	&s
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	  printf "\t\t%s(s)\t\t%s\tb:%2d  =\t%d : from control \r",  sProcNm, pd(s.CtrlName,26), s.checked, PnValC( s.CtrlName )
End

Function		AutoUserLimit( ch, rg )
// Returns the state of the   'Auto/User' - checkbox.  Another approach: 'ControlInfo'
	variable 	ch, rg	
	nvar		bAutoUserLimit	= $"root:uf:eval:D3:cbAutUs" + num2str( ch ) + num2str( rg ) + "00"	//e.g. for ch 1  and  rg 0:  root:uf:eval:D3:cbAutUs1000
	// printf "\t\t\tAutoUserLimit( ch:%d, rg:%d ) returns   %d \r", ch, rg, bAutoUserLimit
	return	bAutoUserLimit
End


Function		fStartVal( s )
	struct	WMCheckboxAction	&s
	fRadio_struct3( s )
	string  	sProcNm 		= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	string  	sFoRadVar
 	sFoRadVar	= (s.CtrlName)[ 0,  strlen( s.CtrlName ) - 3 ] // - 1 ]			// Assumption: each tab/block has it's own radio setting. Change  -3 -> -1 to have just 1 radio setting for all tabs/blocks
 	sFoRadVar	= ReplaceString( "_",  sFoRadVar, ":" )
	nvar		nLinRadioIdx	= $sFoRadVar							// retrieve the state of radio button group from this ONE global variable
	printf "\t\t%s   \t\t%s\tb:%2d  =\t%d : from control   \t\t\tFrom global nvar \t'%s' : \t\t%d  \r", sProcNm, pd(s.CtrlName,26), s.checked, PnValC( s.CtrlName ), sFoRadVar, nLinRadioIdx
	nvar		gpStartValsOrFit	= root:uf:eval:D3:raStVal00					// 0 : do not fit, display only starting values, 1 : do fit
	gpStartValsOrFit	= nLinRadioIdx 
	SameDataAgain()
End


Function		fLatCursor( s )
	struct	WMPopupAction	&s
	fPopup_struct1( s )											// sets the global variable
	string  	sPath	= ksEVALCFG_DIR 							// e.g.  'C:Epc:Data:EvalCfg:'   or   'C:UserIgor:Ced:'  , must contain drive letter
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	string  	sFo	 	= GetUserData( 	s.win,  s.ctrlName,  "sFo" )			// e.g.  'root:uf:eval:' 
	string  	sSubDir	= ReplaceString( "root:uf:", sFo, "" )		  		// e.g.  'root:uf:eval:' -> 'eval:'
	  printf "\t%s\t\t\t\t  \r",  pd(sProcNm,13)
End

Function		fLatCursorLst( sControlNm, sFo, sWin )
	string		sControlNm, sFo, sWin
	PopupMenu	$sControlNm, win = $sWin,	 value = klstLATCSR
End


Function		fSidePts( s ) 
//  SetVariable action proc for the points around a peak over which the peak value is averaged. Single sided points are assumed ranging from 0 .. 20 so the true range is 1..41
	struct	WMSetvariableAction    &s
//	fSetvar_struct1( s )											// sets the global variable
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	nvar		gPkSidePts	= root:uf:eval:D3:svSideP0000				// additional points on each side of a peak averaged to reduce noise errors 
	gPkSidePts	= s.dval										

	  printf "\t%s\t%s\tvar:%g\t \r",  pd(sProcNm,13), pd(s.CtrlName,31), s.dval
	AllPeaks( gPkSidePts )										// Do determination of all peaks immediately.  Flaw : Gets any data sweep.
End


Function		fDiPlus( ctrlName ) : ButtonControl
// Plus  peak points .  Oldstyle function as it is called in the key-loop  'ExecuteActions( nKey1, nKey2 )'
	string		ctrlName
	 print ctrlname
	nvar		gPkSidePts	= root:uf:eval:D3:svSideP0000				// additional points on each side of a peak averaged to reduce noise errors 
	gPkSidePts	+= 1
	AllPeaks( gPkSidePts )										// Do determination of all peaks immediately.  Flaw : Gets any data sweep.
End
	
Function		fDiMinus( s )
// Minus  peak points 
	struct	WMButtonAction	&s
	nvar		gPkSidePts	= root:uf:eval:D3:svSideP0000				// additional points on each side of a peak averaged to reduce noise errors 
	if (  s.eventCode != kCCE_idle  &&  s.eventCode != kCCE_mousemoved  &&  s.eventCode != kCCE_leave  &&  s.eventCode != kCCE_enter  &&  s.eventCode != kCCE_mouseup ) 
		gPkSidePts	= max( 0, 	gPkSidePts - 1 )
		AllPeaks( gPkSidePts )										// Do determination of all peaks immediately.  Flaw : Gets any data sweep.
	endif
End

Function		AllPeaks( nPkSidePts )
// Do determination of all peaks immediately.  Flaw : Gets any data sweep.  If the display mode is 'single'  this will be the current sweep.  If the display mode is 'stacked'  it can be any sweep, ...
	variable	nPkSidePts									// additional points on each side of a peak averaged to reduce noise errors 
	variable	ch		= 0
	variable	rg		= 0
	nvar		gChans	= root:uf:cfsr:gChannels					
	nvar		nRgUsed	= $"root:uf:eval:D3:svReg" + num2str( ch ) + "000"
	for ( ch = 0; ch < gChans; ch += 1 )
		for ( rg = 0; rg < nRgUsed; rg += 1 )						// Display the used fit cursors 
			OnePeak( ch, rg, nPkSidePts )						// Do a peak determination immediately.  Flaw : Gets any data sweep.  If the display mode is 'single'  this will be the current sweep.  If the display mode is 'stacked'  it can be any sweep, ...
		endfor
	endfor
End

Function		OnePeak( ch, rg, nPkSidePts )
// Do a peak determination immediately.  Flaw : Gets any data sweep.  If the display mode is 'single'  this will be the current sweep.  If the display mode is 'stacked'  it can be any sweep, ...
	variable	ch, rg
	variable	nPkSidePts									// additional points on each side of a peak averaged to reduce noise errors 
	string		sWNm			= CfsWndNm( ch )
	string		sFoldOrgWvNm		= GetOnlyOrAnyDataTrace( ch )
	wave	wOrg				= $sFoldOrgWvNm
	variable	rLeft, rRight
	// 6a	 Evaluate the true minimum and maximum peak value and location by removing the noise in a region around the given approximate peak location 
	RegionX( ch, rg, PH_PEAK, rLeft, rRight )			// get the beginning of the Peak1 evaluation region (=rLeft)
	EvaluatePeak( wOrg, ch, rg, PH_PEAK, rLeft, rRight, nPkSidePts ) 
	// todo 050802 does not work ???       SetRegionY( ch, rg, PH_PEAK, EvY( ch, rg, kE_PEAK ), EvY( ch, rg, kE_PEAK ) )	// cosmetics: set the evaluated peak value as top and bottom of evaluation region to show the user the value (additionally to circle...)
	// DisplayCursors( ch, rg, PH_PEAK )
	DisplayOneEvaluatedPoint( kE_PEAK, ch, rg, sWNm )		// or  kE_AMPL
End






Function		fPrintReslts( s )
// History printing  needs an explicit action procedure to convert the index of the listbox entry into the print mask
	struct	WMPopupAction	&s
	fPopup_struct1( s )												// sets the global variable
	string  	sPath	= ksEVALCFG_DIR 								// e.g.  'C:Epc:Data:EvalCfg:'   or   'C:UserIgor:Ced:'  , must contain drive letter
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	string  	sFo	 	= GetUserData( 	s.win,  s.ctrlName,  "sFo" )				// e.g.  'root:uf:eval:' 
	string  	sSubDir	= ReplaceString( "root:uf:", sFo, "" )		  			// e.g.  'root:uf:eval:' -> 'eval:'

	nvar		gPrintMask	= root:uf:eval:evl:gprintMask
	gPrintMask			= str2num( StringFromList( s.popNum - 1, ksPRINTMASKS ) )	// Convert changed popup index into PrintMask bit field

	  printf "\t%s\t%s\tpopnum%2d\t%s\tgPrintMask:%4d\t  \r",  pd(sProcNm,15), pd(s.ctrlName,23), s.popNum, pd(s.popStr,11), gPrintMask
End

Function		fPrintResltsLst( sControlNm, sFo, sWin )
	string		sControlNm, sFo, sWin
	PopupMenu	$sControlNm, win = $sWin,	 value = ksPRINTRESULTS
End



Function		fAutoSelect( s )
//  Auto Selection of Print Results needs an explicit action procedure to convert the index of the listbox entry into the print mask
	struct	WMPopupAction	&s
	fPopup_struct1( s )												// sets the global variable
	string  	sPath	= ksEVALCFG_DIR 								// e.g.  'C:Epc:Data:EvalCfg:'   or   'C:UserIgor:Ced:'  , must contain drive letter
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	string  	sFo	 	= GetUserData( 	s.win,  s.ctrlName,  "sFo" )				// e.g.  'root:uf:eval:' 
	string  	sSubDir	= ReplaceString( "root:uf:", sFo, "" )		  			// e.g.  'root:uf:eval:' -> 'eval:'

// Set a default combination of selected results  e.g. 'Standard' , 'StimFit' , 'PeakAmp'...
	string  	lstAutoSelMask	= StringFromList( s.popNum - 1, ksAUTOSELECTMASK )			// Convert changed popup index into PrintMask list  field
	variable	n, nItems		= ItemsInList( lstAutoSelMask, "," )	// !!! Assumption separator
	variable	nIndex, nState = kRS_PRINT

// Set a default combination of selected results  e.g. 'Standard' , 'StimFit' , 'PeakAmp'...
	  printf "\t%s\t%s\tpopnum%2d\t%s\tgAutoSelMask: '%s' \t  \r",  pd(sProcNm,15), pd(s.ctrlName,23), s.popNum, pd(s.popStr,11), lstAutoSelMask
	wave /Z	wFlags			= root:uf:wSRFlagsPr
	wave /Z	wFlags			= root:uf:wSRFlagsPr
	string  	sPlaneNm		= "BackColors" 
	variable	pl			= FindDimLabel( wFlags, 2, sPlaneNm )
	variable	col, ch, rg
	string  	lst	= ListACVPr( ch )
	for ( n = 0; n < nItems; n += 1 )
		string  	sItem	 = StringFromList( n, lstAutoSelMask, "," )	// !!! Assumption separator
		nIndex	= WhichListItem( sItem, lst )
		if ( nIndex )
			GetChRg( sItem, ch, rg )
			col = 0
			if ( ch > 0  ||  rg > 0 )
				print "\tTODO\tGetChRg", sItem, "-> index: ", nIndex, ch, rg, "-> col: " , col
				col = 1 // TODO.......
				nIndex=nIndex-30 //TODO...
			endif
			print "\t\t\tGetChRg", sItem, "-> index: ", nIndex, ch, rg, "-> col: " , col
			DSSet( wFlags, nIndex, nIndex, col, pl, nState )
		endif
	endfor		

End

Function		fAutoSelectLst( sControlNm, sFo, sWin )
	string		sControlNm, sFo, sWin
	PopupMenu	$sControlNm, win = $sWin,	 value = ksAUTOSELECT
End


Function		GetChRg( sItem, ch, rg )
	string  	sItem
	variable	&ch, &rg
	variable	len	=strlen( sItem )
	ch	= str2num( sItem[ len-2, len-2 ] )
	rg	= str2num( sItem[ len-1, len-1 ] )		// !!! Assumption naming :   'name_ChRg'
End	


//strconstant	klstDSP_TRACES	= "Only traces;traces + avg;only average"
//
//Function		fDspTraces( s )
//	struct	WMPopupAction	&s
//	fPopup_struct1( s )											// sets the global variable
//	string  	sPath	= ksEVALCFG_DIR 							// e.g.  'C:Epc:Data:EvalCfg:'   or   'C:UserIgor:Ced:'  , must contain drive letter
//	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
//	string  	sFo	 	= GetUserData( 	s.win,  s.ctrlName,  "sFo" )			// e.g.  'root:uf:eval:' 
//	string  	sSubDir	= ReplaceString( "root:uf:", sFo, "" )		  		// e.g.  'root:uf:eval:' -> 'eval:'
//	  printf "\t%s\t\t\t\t\  \r",  pd(sProcNm,13)
//End
//
//Function		fDspTracesLst( sControlNm, sFo, sWin )
//	string		sControlNm, sFo, sWin
//	PopupMenu	$sControlNm, win = $sWin,  	 value = klstDSP_TRACES
//End


Function 		fSameTime( s )
	struct	WMCheckboxAction	&s
	print s.CtrlName
	//RedrawEvalPanel()						// enable / disable some dependent controls
//	variable	rg = 0// todo???
//	if ( bValue )
//		SetSameMagnification( rg )				// sets  'DO_RESET'  FALSE
//	endif
	RescaleAllChansBothAxis()
End

Function 		fMultKeeps( s )
	struct	WMCheckboxAction	&s
	print s.CtrlName
End

Function 		fResultTxtbox( s )
	struct	WMCheckboxAction	&s
	print s.CtrlName, s.checked
	PrintEvalTextboxAllChans()					// displays or hides the evaluation results in the graph window
End

Function		fAutoSetCurs( s )
// Called when a button is pressed.  ALSO CALLED when moving the mouse over a button.  See  'fButtonProc_struct()'  on how to avoid this event.
	struct	WMButtonAction	&s
	if (  s.eventCode != kCCE_idle  &&  s.eventCode != kCCE_mousemoved  &&  s.eventCode != kCCE_leave  &&  s.eventCode != kCCE_enter  &&  s.eventCode != kCCE_mouseup ) 
		string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
		printf "\t\t%s(s)\t\t%s\t%d\t \r",  sProcNm, pd(s.CtrlName,26), mod( DateTime,10000)
		AutoSetCursorsAllChans()
		SameDataAgain()
	endif
End

Function	fClearResSelDr( s )
// Called when a button is pressed.  ALSO CALLED when moving the mouse over a button.  See  'fButtonProc_struct()'  on how to avoid this event.
	struct	WMButtonAction	&s
	if (  s.eventCode != kCCE_idle  &&  s.eventCode != kCCE_mousemoved  &&  s.eventCode != kCCE_leave  &&  s.eventCode != kCCE_enter  &&  s.eventCode != kCCE_mouseup ) 
		string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
		printf "\t\t%s(s)\t\t%s\t%d\t \r",  sProcNm, pd(s.CtrlName,26), mod( DateTime,10000)
		wave	wFlags		= root:uf:wSRFlagsDr
		ClearResultSelection( wFlags )
	endif
End

Function		fResSelectDr( s )
// Displays and hides the Draw Result selection listbox panel
	struct	WMCheckboxAction	&s
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	printf "\t\t%s(s)\t\t%s\tchecked:%d\t \r",  sProcNm, pd(s.CtrlName,26), s.checked
	if (  s.checked ) 
		PanelRSUpdateDr()
	else
		PanelRSHideDr()
	endif
End

Function	fClearResSelPr( s )
// Called when a button is pressed.  ALSO CALLED when moving the mouse over a button.  See  'fButtonProc_struct()'  on how to avoid this event.
	struct	WMButtonAction	&s
	if (  s.eventCode != kCCE_idle  &&  s.eventCode != kCCE_mousemoved  &&  s.eventCode != kCCE_leave  &&  s.eventCode != kCCE_enter  &&  s.eventCode != kCCE_mouseup ) 
		string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
		printf "\t\t%s(s)\t\t%s\t%d\t \r",  sProcNm, pd(s.CtrlName,26), mod( DateTime,10000)
		wave	wFlags		= root:uf:wSRFlagsPr
		ClearResultSelection( wFlags )
	endif
End

Function		fResSelectPr( s )
// Displays and hides the Print/ToFile Result selection listbox panel
	struct	WMCheckboxAction	&s
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	printf "\t\t%s(s)\t\t%s\tchecked:%d\t \r",  sProcNm, pd(s.CtrlName,26), s.checked
	if (  s.checked ) 
		PanelRSUpdatePr()
	else
		PanelRSHidePr()
	endif
End

//---------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Saving and recalling panel settings

Function		fDefaults( s )
// Called when a button is pressed.  ALSO CALLED when moving the mouse over a button.  See  'fButtonProc_struct()'  on how to avoid this event.
	struct	WMButtonAction	&s
	if (  s.eventCode != kCCE_idle  &&  s.eventCode != kCCE_mousemoved  &&  s.eventCode != kCCE_leave  &&  s.eventCode != kCCE_enter  &&  s.eventCode != kCCE_mouseup ) 
		string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
		string  	sFo	 	= GetUserData( 	s.win,  s.ctrlName,  "sFo" )			// e.g.  'root:uf:eval:' 
		printf "\t\t%s(s)\t\t%s\t%s\t%s\t\t \r",  pd(sProcNm,15),  pd(s.CtrlName,31), pd(sFo,17), pd(s.win,9)

		ClearFolderVars( sFo + s.win + ":" )				// first kill all variables so that they do not exist in 'PnInitVars()' . If they existed the panel could never shrink again. Different approach: Overwrite variables in 'PnInitVars()' without existance-checking (->other problems..)
		Panel3Main(   "D3", "Evaluation Details3", "root:uf:" + ksEVAL_, 2, 95 ) // Compute the location of panel controls and the panel dimensions. Draw the panel displaying and hiding needed/unneeded controls
		UpdateDependent_Of_AllowDelete( s.Win, "root_uf_eval_D3_cbAlDel0000" )	

//		ControlUpdate	/A /W = $s.win

// todo : also  reset  regions and cursors  = wCRegion
	endif
End

Function		fSaveSets( s ) 
// Demo: this  SetVariable control  for inputing a string	...............WITHOUT fSetvar_struct1( s )	
	struct	WMSetvariableAction    &s
//	fSetvar_struct1( s )											// sets the global variable
	string  	sPath	= ksEVALCFG_DIR							// e.g.  "C:Epc:Data:EvalCfg:"   or   "C:UserIgor:Ced:" , must contain drive letter
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	string  	sFo	 	= GetUserData( 	s.win,  s.ctrlName,  "sFo" )			// e.g.  'root:uf:eval:' 
	string  	sSubDir	= ReplaceString( "root:uf:", sFo, "" )		  		// e.g.  'root:uf:eval:' -> 'eval:'
	string  	sLoadPath	= ksEVALCFG_DIR + sSubDir + s.win				// e.g.  'C:Epc:Data:EvalCfg:' + 'Eval:' + 'EvDet2'    or   'C:UserIgor:Ced:' + 'Acq' + 'PnMisc'  , must contain drive letter

	string  	sFileBase	= s.sval
	//printf "\t\t%s(s)\t\tCo:\t%s\tFo:%s\tWi:\t%s\tPa:\t%s\tSu:\t%s\tFi:\t'%s' '%s' \r",   pd(sProcNm,15), pd(s.CtrlName,31), pd(sFo,17), pd(s.win,9), pd(sPath,17), pd(sSubDir,17), sFileBase, "txt + ecf"

	SaveAllFolderVars( 		sFo, s.win, sPath + sSubDir + s.win, sFileBase, sEVALCFG_PANEL_EXT )		// .txt
	SaveRegionsAndCursors( 	sFo, s.win, sPath + sSubDir + s.win, sFileBase, sEVALCFG_REGION_EXT )		// .ecf

	string  /G	$"root:uf:glstPnSvFilesEvDet3" = ListOfMatchingFiles( sLoadPath, "*."+ sEVALCFG_PANEL_EXT, FALSE )	// Add this new file name entry to the global list of the PanelSave-files so that this file is included in the popupmenu already on ENTRY of the next fRecallSets()	

End

Function		SaveRegionsAndCursors( sFolder, sPanel, sPath, sFileBase, sFileExt )
//  'SaveRegionsAndCursors()'  and  'SaveAllFolderVars()'  are companion functions
	string  	sFolder, sPanel, sPath, sFileBase, sFileExt 
	PossiblyCreatePath( sPath )
	string  	sFilePath	= sPath + ":" + sFileBase + "." + sFileExt 
	save /O /T root:uf:eval:evl:wCRegion	as sFilePath 					// store all cursor region variables to disk under the name 'wCRegion' 
End	



Function		fDeleteSets( s )
	struct	WMPopupAction	&s
	fPopup_struct1( s )											// sets the global variable
	string  	sPath	= ksEVALCFG_DIR 							// e.g.  'C:Epc:Data:EvalCfg:'   or   'C:UserIgor:Ced:'  , must contain drive letter
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	string  	sFo	 	= GetUserData( 	s.win,  s.ctrlName,  "sFo" )			// e.g.  'root:uf:eval:' 
	string  	sSubDir	= ReplaceString( "root:uf:", sFo, "" )		  		// e.g.  'root:uf:eval:' -> 'eval:'
	string  	sLoadPath	= ksEVALCFG_DIR + sSubDir + s.win				// e.g.  'C:Epc:Data:EvalCfg:' + 'Eval:' + 'EvDet2'    or   'C:UserIgor:Ced:' + 'Acq' + 'PnMisc'  , must contain drive letter
	string  	sFileNm	= StringFromList( s.popNum-1, ListOfMatchingFiles( sLoadPath, "*." + sEVALCFG_PANEL_EXT, FALSE ) )
	printf "\t\t%s(s)\t\tCo:\t%s\tFo:%s\tWi:\t%s\tPa:\t%s\tSu:\t%s\t->\t%s -> Sel:%2d ~ %s \r",  sProcNm, pd(s.CtrlName,29), pd(sFo,17), pd(s.win,9), pd(sPath,17), pd(sSubDir,9), sLoadPath, s.popNum, sFileNm

	DeleteFile	sPath + sSubDir + s.win + ":" + sFileNm 					// Delete the file containing the panel variables.  The file has the extension  'txt' .
	string sFileNmEcf = StripExtensionAndDot( sFileNm ) + "." + sEVALCFG_REGION_EXT
	DeleteFile	sPath + sSubDir + s.win + ":" + sFileNmEcf 					// Delete the file containing the cursors and regions in wave wCRegion.  The file has the extension  'ecf' .

	string  /G	$"root:uf:glstPnSvFilesEvDet3" = ListOfMatchingFiles( sLoadPath, "*."+ sEVALCFG_PANEL_EXT, FALSE )// Remove the deleted entry from the global list of the PanelSave-files so that this file is excluded from the popupmenu already on ENTRY of the next fRecallSets()	
	PopupMenu	$s.ctrlName, win = $s.win, mode = 0 					//display the title ('Delete') in the box but not any of the files . (Even better would be '---' or blank).
End

Function		fRecallSets( s )
	struct	WMPopupAction	&s
	fPopup_struct1( s )											// sets the global variable
	string  	sPath	= ksEVALCFG_DIR 							// e.g.  'C:Epc:Data:EvalCfg:'   or   'C:UserIgor:Ced:'  , must contain drive letter
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	string  	sFo	 	= GetUserData( 	s.win,  s.ctrlName,  "sFo" )			// e.g.  'root:uf:eval:' 
	string  	sSubDir	= ReplaceString( "root:uf:", sFo, "" )		  		// e.g.  'root:uf:eval:' -> 'eval:'
	string  	sLoadPath	= ksEVALCFG_DIR + sSubDir + s.win				// e.g.  'C:Epc:Data:EvalCfg:' + 'Eval:' + 'EvDet2'    or   'C:UserIgor:Ced:' + 'Acq' + 'PnMisc'  , must contain drive letter

	string  	sFileNm	= StringFromList( s.popNum-1, ListOfMatchingFiles( sLoadPath, "*." + sEVALCFG_PANEL_EXT, FALSE ) )	
	string  	sThisControl = StripFolders( s.ctrlName )

	// Recall the panel variables.	  The file has the extension  'txt' .
	ClearFolderVars( sFo + s.win + ":" )				// first kill all variables so that they do not exist in 'PnInitVars()' . If they existed the panel could never shrink again. Different approach: Overwrite variables in 'PnInitVars()' without existance-checking (->other problems..)
	RecallAllFolderVars( sFo, s.win, sPath + sSubDir + s.win, sFileNm, sThisControl )	// ...and update panel with user settings
	Panel3Main(   "D3", "Evaluation Details3", "root:uf:" + ksEVAL_, 2, 95 ) // Compute the location of panel controls and the panel dimensions. Draw the panel displaying and hiding needed/unneeded controls

	// Recall the cursors and regions.  The file has the extension  'ecf' .
	string sFileNmEcf = StripExtensionAndDot( sFileNm ) + "." + sEVALCFG_REGION_EXT
	RecallRegionsAndCursors( sFo, s.win, sPath + sSubDir + s.win, sFileNmEcf )	// 
//	 printf "\t\t%s(s)\t\tCo:\t%s\tFo:%s\tWi:\t%s\tPa:\t%s\tSu:\t%s\t->\t%s -> Sel:%2d ~ %s + %s [%s] \r",  sProcNm, pd(s.CtrlName,29), pd(sFo,17), pd(s.win,9), pd(sPath,17), pd(sSubDir,9), sLoadPath, s.popNum, sFileNm, sFileNmEcf, sThisControl

	UpdateDependent_Of_AllowDelete(  s.win, "root_uf_eval_D3_cbAlDel0000" )	
End

Function		UpdateDependent_Of_AllowDelete(  sWin, sCtrlName )	
	string		sWin, sCtrlName
	ControlInfo	/W = $sWin $sCtrlName
	variable	bChecked			= V_Value
	string  	sThisControl		= StripFolders( sCtrlName )
	string  	sTheOtherControl	= "pmDelet0000"						// the control to be modified without folders
	string  	sCoNm   = ReplaceString( sThisControl, sCtrlName, sTheOtherControl )	// for this to work both controls must reside in the same folder
	PopupMenu  	$sCoNm, win = $sWin, mode = 0 						//display the title ('Delete') in the box but not any of the files . (Even better would be '---' or blank).
																// without this  'fRecallSetsLstT()'  will pop up the first entry of the files list in the 'Delete' box
	PopupMenu	$sCoNm, win = $sWin,  disable	=  bChecked  ?  0 :  kDISABLE // : kHIDE  // : kDISABLE
End


Function		fRecallSetsLst( sControlNm, sFo, sWin )
// callled via 'fPopupListProc3()'
	string		sControlNm, sFo, sWin
	string  	sSubDir	= ReplaceString( "root:uf:", sFo, "" )		  		// e.g.  'root:uf:eval:' -> 'eval:'
	string  	sLoadPath	=  ksEVALCFG_DIR + sSubDir + sWin		
	// print "\t\t\tfRecallSetsLst()", sControlNm, sFo , sWin, "->", sLoadPath
	svar	/Z	lstFiles	= $"root:uf:glstPnSvFilesEvDet3"	
	if ( ! svar_Exists( lstFiles ) )										// Fill list once when/before the panel is constructed for the first time. Later the existing list is updated by 'Save' and 'Delete' 
		string  /G	$"root:uf:glstPnSvFilesEvDet3" = ListOfMatchingFiles( sLoadPath, "*."+ sEVALCFG_PANEL_EXT, FALSE )// Construct the current file list.
	endif
	PopupMenu	$sControlNm, win = $sWin,  value =  #"root:uf:glstPnSvFilesEvDet3"	// Retrieve the current list as updated and stored by 'Save' and 'Delete'
End


Function		RecallRegionsAndCursors( sFolder, sWin, sPath, sFileName )
// Reads regions and cursors 
	string		sFolder, sWin, sPath, sFileName
	string  	sFilePath	= sPath + ":"  + sFileName 
	  printf "\t\t\tRecallRegionsAndCursors()\t%s\t%s\trecalled from\t'%s'\t  \r", pd(sFolder,17), pd(sWin,9), sFilePath
	Open	  	/R	/T = "????"  /Z=1	nRefNum  as sFilePath		
	loadwave /O /T /A  /Q 				 sFilePath					// read all cursor region variables from disk keeping the wave name 'wCRegion' 
	if ( V_Flag == 1 )					// the number of waves loaded
		duplicate	/O 	wCRegion			root:uf:eval:evl:wCRegion
		killWaves	wCRegion
	else
		Alert( kERR_FATAL,  " RecallRegionsAndCursors()  could not load wCRegion from '" + sFilePath + "' " )	
	endif
End


Function		fCbAllowDelete( s )
// Checkbox action proc enabling or graying the 'Delete'-Popupmenu in the same tabgroup. Disabling by default prevents that the user accidentally erases his saved panel settings
	struct	WMCheckboxAction	&s
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	  printf "\t\t%s(s)\t\t%s\tb:%2d  =\t%d : from control \r",  sProcNm, pd(s.CtrlName,26), s.checked, PnValC( s.CtrlName )
	UpdateDependent_Of_AllowDelete(  s.win, s.CtrlName )	
End

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function		fCfsHeader( s )
	struct	WMCheckboxAction	&s
	fRadio_struct3( s )
	string  	sProcNm 		= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	string  	sFoRadVar
 	sFoRadVar	= (s.CtrlName)[ 0,  strlen( s.CtrlName ) - 3 ] // - 1 ]	// Assumption: each tab/block has it's own radio setting. Change  -3 -> -1 to have just 1 radio setting for all tabs/blocks
 	sFoRadVar	= ReplaceString( "_",  sFoRadVar, ":" )
	nvar		nGlobal		= $sFoRadVar					// retrieve the state of radio button group from this ONE global variable
	printf "\t\t%s   \t\t%s\tb:%2d  =\t%d : from control   \t\t\tFrom global nvar \t'%s' : \t\t%d  \r", sProcNm, pd(s.CtrlName,26), s.checked, PnValC( s.CtrlName ), sFoRadVar, nGlobal
End

static  strconstant	lstCFSHEADER	= "no info,short,long,full info,"	// "no info;short;long;full info;"

Function	/S	fCfsHeaderLst()
	return	lstCFSHEADER
End


//====================================================================================================================================
// THE  SELECT RESULTS   DRAW   LISTBOX  PANEL			

static strconstant	ksCOL_SEP	= "~"	

Function		PanelRSUpdateDr()
// Build the huge  'Select result'  listbox allowing the user to select some results for printing, for the reduced file or for  latencies
// Code takes into account the various states (visible, hidden, moved, existant, not-yet-existant...) and handles all cases while avoiding unnecessary  killing and reseting of the panel and of the waves.
// Note: The position of the panel window is maintained  WITHOUT using StoreWndLoc() / RetrieveWndLoc() !!!
	nvar		bVisib		= root:uf:eval:D3:cbResSelDr0000					// The ON/OFF state ot the 'Select Results' checkbox

	// 1. Construct the global string  'lstACVAllCh'  which contains all of the various evaluation and fitting values
	string  	lstACVAllCh	=  ListACVAllChansDr() 

	// 2. Get the the text for the cells by breaking the global string  'lstACVAllCh'  which contains all of the various evaluation and fitting values
	variable	len, n, nItems	= ItemsInList( lstACVAllCh )	
	 printf "\t\t\tPanelRSUpdateDr()  lstACVAllCh has items:%3d\t '%s'   \r", nItems, lstACVAllCh
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
	 printf "\t\t\tPanelRSUpdateDr()  lstACVAllCh has items:%3d ->rows:%3d  cols:%2 d  ColT: '%s' ,  ColItems: '%s...' \r", nItems, nRows, nCols, lstColTitles, lstColItems[0, 100]


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
			NewPanel1( sWin, kRIGHT, 0, xSize, kBOTTOM, 0, ySize, kKILL_DISABLE, "Draw: Select Results" )	// We must disable killing as this would destroy any selection in the listbox, but minimising is allowed.

			SetWindow	$sWin,  hook( SelRes ) = fHookPnSelResDr
			ModifyPanel /W=$sWin, fixedSize= 1						// prevent the user to maximize or close the panel by disabling these buttons

			// Create the 2D LB text wave	( Rows = maximum of results in any ch/rg ,  Columns = Ch0 rg0; Ch0 rg1; ... )
			make  /O 	/T 	/N = ( nRows, nCols )		root:uf:wSRTxtDr	= ""	// the LB text wave
			wave   	/T		wSRTxt		     =	root:uf:wSRTxtDr
		
			// Create the 3D LB flag wave. 	Rows x Columns (as above)  x 3  : last index 0 is flags, 1 is fore- or background color, 2 is the remaining color 
			make   /O	/B  /N = ( nRows, nCols, 3 )	root:uf:wSRFlagsDr	// byte wave is sufficient for up to 254 colors 
			wave   			wSRFlags		    = 	root:uf:wSRFlagsDr
			
			// Create color table withs rows and columns exchanged. 3 rows, n columns is easier to read as n columns, 3 rows but must be transposed before Igor can use them.
			// At the moment these colors are the same as in the  DataSections  listbox
			//								black		blue			red			magenta			grey			light grey			green			yellow				
			make   /O	/W /U	root:uf:wSRColors  = { {0, 0, 0 }, { 0, 0, 65535 },  { 65535, 0, 0 },  {40000,0,48000}, {44000,44000,44000},  {54000,54000,54000},  { 0, 50000, 0} ,   { 0, 56000, 56000 },  {65280,59904,48896} }	// order must be same as defined by constants above
			wave   wSRColors  =	root:uf:wSRColors
			MatrixTranspose 		  wSRColors					// the same table is used for foreground and background. 	Igor requires  n  rows, 3 columns 
		
			// Link the  indices  of  Foreground  and  Background  colors  to  their name strings which are later used to access the layer where the color is to be set
			variable	planeFore	= 1
			variable	planeBack	= 2
			SetDimLabel 2, planeBack,  $"backColors"	wSRFlags
			SetDimLabel 2, planeFore,   $"foreColors"	wSRFlags
	
		else													// The panel DOES exist. It may be minimised to an icon or it may be hidden behind other panels. If it is hidden then the checkbox must be actuated twice: hide and then restore panel to make it visible
			MoveWindow /W=$sWin	1,1,1,1						// Restore previous size and position. This does NOT take into account that the panel size may have changed in the meantime due to more or less columns or rows

			MoveWindow1( sWin, kRIGHT, 0, xSize, kBOTTOM, 0, ySize )	// Extract previous panel position and size. Keep only position and discard size as the size may have changed in the meantime due to more or less columns or rows.

			wave   	/T		wSRTxt			= root:uf:wSRTxtDr
			wave   			wSRFlags		  	= root:uf:wSRFlagsDr
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
		ListBox	  lbSelectResult,    win = PnSelResDr, 	listWave 			= root:uf:wSRTxtDr
		ListBox 	  lbSelectResult,    win = PnSelResDr, 	selWave 			= root:uf:wSRFlagsDr,  editStyle = 1
		ListBox	  lbSelectResult,    win = PnSelResDr, 	colorWave		= root:uf:wDSColors
		// ListBox 	  lbSelectResult,    win = PnSelResDr, 	mode 			 = 4// 5			// ??? in contrast to the  DataSections  panel  there is no mode setting required here ???
		ListBox 	  lbSelectResult,    win = PnSelResDr, 	proc 	 			 = lbSelResDrProc

	endif		// bVisible : state of 'Select results panel' checkbox is  ON 
End


Function		PanelRSHideDr()
	printf "\t\t\tfPanelRSHideDr()    \r"
	string  	sWin	= "PnSelResDr"
	if (  WinType( sWin ) == kPANEL )						// check existance of the panel. The user may have killed it by clicking the panel 'Close' button 5 times in fast succession
		MoveWindow 	/W=$sWin   0 , 0 , 0 , 0				// hide the window by minimising it to an icon
	endif
End



Function 		fHookPnSelResDr( s )
// The window hook function of the 'Select results panel' detects when the user minimises the panel by clicking on the panel 'Close' button and adjusts the state of the 'select results' checkbox accordingly
	struct	WMWinHookStruct &s
	if ( s.eventCode != kWHK_mousemoved )
		// printf  "\t\tfHookPnSelResDr( %2d \t%s\t)  '%s'\r", s.eventCode,  pd(s.eventName,9), s.winName
		if ( s.eventCode == kWHK_move )									// This event also triggers if the panel is minimised to an icon or restored again to its previous state
			GetWindow     $s.WinName , wsize								// Get its current position		
			variable	bIsVisible	= ( V_left != V_right  &&  V_top != V_bottom )
			nvar		bCbState	= root:uf:eval:D3:cbResSelDr0000				// Turn the 'Select Results' checkbox  ON / OFF  if the user maximised or minimised the panel by clicking the window's  'Restore size'  or  'Minimise' button [ _ ] .
			bCbState			= bIsVisible								// This keeps the control's state consistent with the actual state.
			// printf "\t\tfHookPnSelResDr( %2d \t%s\t)  '%s'\tV_left:%3d, V_Right:%3d, V_top:%3d, V_bottom:%3d -> bVisible:%2d  \r", s.eventCode,  pd(s.eventName,9), s.winName, V_left, V_Right, V_top, V_bottom, bIsVisible
		endif
	endif
End

Function		lbSelResDrProc( s ) : PopupMenuControl
// Dispatches the various actions to be taken when the user clicks in the Listbox. At the moment only mouse clicks and the state of the CTRL, ALT and SHIFT key are processed.
	struct	WMListboxAction &s
	wave	wFlags		= root:uf:wSRFlagsDr
	wave   /T	wTxt			= root:uf:wSRTxtDr
	string  	sPlaneNm		= "BackColors" 
	variable	pl			= FindDimLabel( wFlags, 2, sPlaneNm )
	variable	nState		= State( wFlags, s.row, s.col, pl )					// the old state
	// printf "\t\tlbSelResDrProc( s ) 1\trow:%2d\tcol:%2d  evCode:%2d\tevModif:%2d\tstate:%2d  \r", s.row , s.col, s.eventCode, s.eventMod,  nState
	// MOUSE : SET a cell. Click in a cell  in any row or column. Depending on the modifiers used, the cell changes state and color and stay in this state. It can be reset by shift clicking again or by globally reseting all cells.
	if ( s.eventCode == kLBE_MouseDown  &&  !( s.eventMod & kSHIFT ) )	// Only mouse clicks  without SHIFT  are interpreted here.  // ??? In this listbox only MouseDown is detected, whereas in the similar  DataSections  listbox  MouseUp  is detected???
	// if ( s.eventCode == kLBE_MouseUp  &&  !( s.eventMod & kSHIFT ) )	// does not work here ???
		nState		= Modifier2State( s.eventMod )				// Convert the modifying key (e.g. 'Ctrl' ,  'Ctrl Alt / Alt Gr' ) to a state = color  (e.g. select for file, for print or for both )  
		DSSet( wFlags, s.row, s.row, s.col, pl, nState )				// sets flags .  The range feature is not used here so  begin row = end row .
		// printf "\t\tlbSelResDrProc( s ) 2\trow:%2d\tcol:%2d  evCode:%2d\tevModif:%2d\tstate:%2d =?=%2d  \r",  s.row, s.col,  s.eventCode, s.eventMod, nState, State( wFlags, s.row, s.col, pl )	
	endif
	// MOUSE :  RESET a cell  by  Shift Clicking
	if ( s.eventCode == kLBE_MouseDown  &&  ( s.eventMod & kSHIFT ) )	// Only mouse clicks  with    SHIFT  are interpreted here.  // ??? In this listbox only MouseDown is detected, whereas in the similar  DataSections  listbox  MouseUp  is detected???
	// if ( s.eventCode == kLBE_MouseUp  &&  ( s.eventMod & kSHIFT ) )	// does not work here ???
		nState		= 0									// Reset a cell  
		DSSet( wFlags, s.row, s.row, s.col, pl, nState )				// sets flags .  The range feature is not used here so  begin row = end row .
		// printf "\t\tlbSelDRResProc( s ) 3\trow:%2d\tcol:%2d  evCode:%2d\tevModif:%2d\tstate:%2d =?=%2d  \r",  s.row, s.col,  s.eventCode, s.eventMod, nState, State( wFlags, s.row, s.col, pl )	
	endif
End


Function	/S	ListACVAllChansDr()
// Returns list of titles of  'All Currently Computed Values'  which depends on the EvalState, on the number of regions, the number and types of the fits
	variable	ch
	nvar		gChans			= root:uf:cfsr:gChannels					
	string 	lstACVAllCh	= ""
	for ( ch = 0; ch < gChans; ch += 1 )
		lstACVAllCh	+= ListACVDr( ch )
	endfor
	//printf "ListACVAllChansDr()  has %d items \r", ItemsInList( lstACVAllCh )
	return	lstACVAllCh
End

Function	/S	ListACVDr( ch )
// Returns complete list of titles of  'All Currently Computed Values'  which depends on the EvalState, on the number of regions, the number and types of the fits
	variable	ch
	nvar		bEvalState	= $"root:uf:eval:D3:cbEvlCh" + num2str( ch ) + "002"	// 0 : has no region,  0 : just 1 row,  2 : EvalState is in the 3. column
	nvar		nRegs		= $"root:uf:eval:D3:svReg"    + num2str( ch ) + "000"	
	variable	rg, ph
	string  	lstACV	= ""

	if ( bEvalState )
		for ( rg = 0; rg < nRegs; rg += 1 )
			lstACV	+= ListACVGeneralDr( ch, rg )
			lstACV	+= ListACVFit( ch, rg )
		endfor
	endif
	printf "\t\tListACVDr( ch:%d )  Evalstate:%2d -> Items:%3d,  '%s' ... '%s'   \r", ch, bEvalState, ItemsInList( lstACV ), lstACV[0,80],  lstACV[ strlen( lstACV )-80, strlen( lstACV )-1 ]  
	return	lstACV
End

Function	/S	Postfix( ch, rg )
	variable	ch, rg
	return	"_" + num2str( ch ) + num2str( rg )										// !!! Assumption : ACV naming convention
End

Function	/S	ListACVGeneralDr( ch, rg )
	variable	ch, rg
	string  	sPostfx	= Postfix( ch, rg )
	string		lst	= ""
	variable	shp, pt, nPts	= ItemsInList( klstEVALRESULTS )
	for ( pt = 0; pt < nPts; pt += 1 )
		shp	= str2num( StringFromList( pt, klstEVALSHAPES ) )					// 
		if ( numtype( shp ) != kNUMTYPE_NAN ) 								// if the shape entry is not empty it must be drawn
			lst	= AddListItem( EvalNmDr( pt ) + sPostfx, lst, ";", inf )				// the general values : base, peak, etc
		endif
	endfor
	return	lst
End


Function	/S	SelectedResultsDraw( nState, ch, rg )
	variable	nState, ch, rg
	wave /Z	wFlags			= root:uf:wSRFlagsDr
	wave/Z/T	wTxt				= root:uf:wSRTxtDr
	string  	lstResultIndices = "", lstResultNames = ""
	if ( waveExists( wFlags )  &&  waveExists( wTxt ) )			// the waves necessary for printing exist only after the 'Select results panel' has been openend (by checking the checkbox control) 
		string		lstResults	= ExtractSelectedResults( wFlags, wTxt, nState, ch, rg ) 
		variable	r, nResults	= ItemsInList( lstResults )
		variable	t, nTitles	= ItemsInList( klstEVALRESULTS )
		string  	sOneResult
		variable	nIndex
		if ( nResults )
	 		// printf "\t\tSelectedResultsDraw 1( nState:%2d, ch:%2d, rg:%2d )  nRes:%2d\tnTits:%3d\t\t\t\t\t\t\t\t\t\t'%s...' \r", nState, ch, rg, nResults, nTitles, lstResults[0,200]
			for ( r = 0; r < nResults; r += 1 )											
				sOneResult	= StringFromList( r, lstResults )							// includes direct results e.g. 'Peak'  and  derived results e.g. 'Peak_Y' , 'Peak_TE', ... 

				nIndex	= WhichListItemIgnoreWhiteSpace( sOneResult, klstEVALRESULTS )

				if ( nIndex != kNOTFOUND )
					lstResultIndices	= AddListItem( num2str( nIndex ), lstResultIndices, ";", inf )
					lstResultNames	= AddListItem( sOneResult, 	lstResultNames, ";", inf )
					// printf "\t\tSelectedResultsDraw 2( nState:%2d, ch:%2d, rg:%2d )  nRes:%2d\tnTits:%3d\tfound Idx:%3d\t%s\t-> %s\t'%s...' \r", nState, ch, rg, nResults, nTitles, nIndex, pd( sOneResult,6), pd( lstResultIndices, 10 ), lstResults[0,200]
				endif
			endfor
			  printf "\t\tSelectedResultsDraw 3(\tSt:%2d, ch:%2d, rg:%2d )  nRes:%2d\tnTits:%3d\tfound -> %s\t%s\t<- '%s...' \r", nState, ch, rg, nResults, nTitles, pd( lstResultIndices, 10 ), lstResultNames[0,60], lstResults[0,60]
		endif
	endif
	return	lstResultIndices
End

//====================================================================================================================================
// THE  SELECT RESULTS   PRINT  LISTBOX  PANEL			


Function		PanelRSUpdatePR()
// Build the huge  'Select result'  listbox allowing the user to select some results for printing, for the reduced file or for  latencies
// Code takes into account the various states (visible, hidden, moved, existant, not-yet-existant...) and handles all cases while avoiding unnecessary  killing and reseting of the panel and of the waves.
// Note: The position of the panel window is maintained  WITHOUT using StoreWndLoc() / RetrieveWndLoc() !!!
	nvar		bVisib		= root:uf:eval:D3:cbResSelPr0000					// The ON/OFF state ot the 'Select Results' checkbox

	// 1. Construct the global string  'lstACVAllCh'  which contains all of the various evaluation and fitting values
	string  	lstACVAllCh	=  ListACVAllChansPr() 

	// 2. Get the the text for the cells by breaking the global string  'lstACVAllCh'  which contains all of the various evaluation and fitting values
	variable	len, n, nItems	= ItemsInList( lstACVAllCh )	
	 printf "\t\t\tPanelRSUpdatePR()  lstACVAllCh has items:%3d  \r", nItems
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
	 printf "\t\t\tPanelRSUpdatePR()  lstACVAllCh has items:%3d ->rows:%3d  cols:%2 d  ColT: '%s' ,  ColItems: '%s...' \r", nItems, nRows, nCols, lstColTitles, lstColItems[0, 100]


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
			NewPanel1( sWin, kRIGHT, -3, xSize, kTOP, 0, ySize, kKILL_DISABLE, "Print: Select Results" )	// -3 is a slight X offset preventing this panel to cover the smaller 'Draw results' panel completely.  We must disable killing as this would destroy any selection in the listbox, but minimising is allowed.

			SetWindow	$sWin,  hook( SelRes ) = fHookPnSelResPr
			ModifyPanel /W=$sWin, fixedSize= 1						// prevent the user to maximize or close the panel by disabling these buttons

			// Create the 2D LB text wave	( Rows = maximum of results in any ch/rg ,  Columns = Ch0 rg0; Ch0 rg1; ... )
			make  /O 	/T 	/N = ( nRows, nCols )		root:uf:wSRTxtPr	= ""	// the LB text wave
			wave   	/T		wSRTxt		     =	root:uf:wSRTxtPr
		
			// Create the 3D LB flag wave. 	Rows x Columns (as above)  x 3  : last index 0 is flags, 1 is fore- or background color, 2 is the remaining color 
			make   /O	/B  /N = ( nRows, nCols, 3 )	root:uf:wSRFlagsPr	// byte wave is sufficient for up to 254 colors 
			wave   			wSRFlags		    = 	root:uf:wSRFlagsPr
			
			// Create color table withs rows and columns exchanged. 3 rows, n columns is easier to read as n columns, 3 rows but must be transposed before Igor can use them.
			// At the moment these colors are the same as in the  DataSections  listbox
			//								black		blue			red			magenta			grey			light grey			green			yellow				
			make   /O	/W /U	root:uf:wSRColors  = { {0, 0, 0 }, { 0, 0, 65535 },  { 65535, 0, 0 },  {40000,0,48000}, {44000,44000,44000},  {54000,54000,54000},  { 0, 50000, 0} ,   { 0, 56000, 56000 },  {65280,59904,48896} }	// order must be same as defined by constants above
			wave   wSRColors  =	root:uf:wSRColors
			MatrixTranspose 		  wSRColors					// the same table is used for foreground and background. 	Igor requires  n  rows, 3 columns 
		
			// Link the  indices  of  Foreground  and  Background  colors  to  their name strings which are later used to access the layer where the color is to be set
			variable	planeFore	= 1
			variable	planeBack	= 2
			SetDimLabel 2, planeBack,  $"backColors"	wSRFlags
			SetDimLabel 2, planeFore,   $"foreColors"	wSRFlags
	
		else													// The panel DOES exist. It may be minimised to an icon or it may be hidden behind other panels. If it is hidden then the checkbox must be actuated twice: hide and then restore panel to make it visible
			MoveWindow /W=$sWin	1,1,1,1						// Restore previous size and position. This does NOT take into account that the panel size may have changed in the meantime due to more or less columns or rows

			MoveWindow1( sWin, kRIGHT, -3, xSize, kTOP, 0, ySize )		// Extract previous panel position and size. Keep only position and discard size as the size may have changed in the meantime due to more or less columns or rows.

			wave   	/T		wSRTxt			= root:uf:wSRTxtPr
			wave   			wSRFlags		  	= root:uf:wSRFlagsPr
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
		ListBox	  lbSelectResult,    win = PnSelResPr, 	listWave 			= root:uf:wSRTxtPr
		ListBox 	  lbSelectResult,    win = PnSelResPr, 	selWave 			= root:uf:wSRFlagsPr,  editStyle = 1
		ListBox	  lbSelectResult,    win = PnSelResPr, 	colorWave		= root:uf:wDSColors
		// ListBox 	  lbSelectResult,    win = PnSelResPr, 	mode 			 = 4// 5			// ??? in contrast to the  DataSections  panel  there is no mode setting required here ???
		ListBox 	  lbSelectResult,    win = PnSelResPr, 	proc 	 			 = lbSelResPrProc

	endif		// bVisible : state of 'Select results panel' checkbox is  ON 
End


Function		PanelRSHidePR()
	printf "\t\t\tfPanelRSHidePR()    \r"
	string  	sWin	= "PnSelResPr"
	if (  WinType( sWin ) == kPANEL )						// check existance of the panel. The user may have killed it by clicking the panel 'Close' button 5 times in fast succession
		MoveWindow 	/W=$sWin   0 , 0 , 0 , 0				// hide the window by minimising it to an icon
	endif
End



Function 		fHookPnSelResPr( s )
// The window hook function of the 'Select results panel' detects when the user minimises the panel by clicking on the panel 'Close' button and adjusts the state of the 'select results' checkbox accordingly
	struct	WMWinHookStruct &s
	if ( s.eventCode != kWHK_mousemoved )
		// printf  "\t\tfHookPnSelResPr( %2d \t%s\t)  '%s'\r", s.eventCode,  pd(s.eventName,9), s.winName
		if ( s.eventCode == kWHK_move )									// This event also triggers if the panel is minimised to an icon or restored again to its previous state
			GetWindow     $s.WinName , wsize								// Get its current position		
			variable	bIsVisible	= ( V_left != V_right  &&  V_top != V_bottom )
			nvar		bCbState	= root:uf:eval:D3:cbResSelPr0000				// Turn the 'Select Results' checkbox  ON / OFF  if the user maximised or minimised the panel by clicking the window's  'Restore size'  or  'Minimise' button [ _ ] .
			bCbState			= bIsVisible								// This keeps the control's state consistent with the actual state.
			// printf "\t\tfHookPnSelResPr( %2d \t%s\t)  '%s'\tV_left:%3d, V_Right:%3d, V_top:%3d, V_bottom:%3d -> bVisible:%2d  \r", s.eventCode,  pd(s.eventName,9), s.winName, V_left, V_Right, V_top, V_bottom, bIsVisible
		endif
	endif
End


Function		lbSelResPrProc( s ) : PopupMenuControl
// Dispatches the various actions to be taken when the user clicks in the Listbox. At the moment only mouse clicks and the state of the CTRL, ALT and SHIFT key are processed.
// if ( s.eventCode == kLBE_MouseUp  )	// does not work here like it does in the data sections listbox ???
	struct	WMListboxAction &s
	wave	wFlags		= root:uf:wSRFlagsPr
	wave   /T	wTxt			= root:uf:wSRTxtPr
	string  	sPlaneNm		= "BackColors" 
	variable	pl			= FindDimLabel( wFlags, 2, sPlaneNm )
	variable	nOldState		= State( wFlags, s.row, s.col, pl )					// the old state
	variable	nState		= Modifier2State( s.eventMod )				// Convert the modifying key (e.g. 'Ctrl' ,  'Ctrl Alt / Alt Gr' ) to a state = color  (e.g. select for file, for print or for both )  
	// printf "\t\tlbSelResPrProc( s ) 1\trow:%2d\tcol:%2d  evCode:%2d\tevModif:%2d\toldstate:%2d -> %2d \r", s.row , s.col, s.eventCode, s.eventMod,  nOldState, nState

	// Design issue: One could alternatively stay in the same file  and only output a new header line, but this would probably be impossible or hard to read by EXCEL so we start a new file....
	// This cell was not in TOFILE mode but has been set to TOFILE	||   this cell was in  TOFILE mode but the TOFILE mode has been turned off ..
	if ( ( (nOldState & kRS_TOFILE) == 0  &&  nState & kRS_TOFILE)	||  ( ( nOldState & kRS_TOFILE  &&  ( nState & kRS_TOFILE ) == 0 ) ) )	
		SaveTables()										// ...we need a new file as the column titles header will be invalid as there will be 1 more or 1 less item (or we need at least a new header line, see above)
	endif

	// MOUSE : SET a cell. Click in a cell  in any row or column. Depending on the modifiers used, the cell changes state and color and stay in this state. It can be reset by shift clicking again or by globally reseting all cells.
	if ( s.eventCode == kLBE_MouseDown  &&  !( s.eventMod & kSHIFT ) )	// Only mouse clicks  without SHIFT  are interpreted here.  // ??? In this listbox only MouseDown is detected, whereas in the similar  DataSections  listbox  MouseUp  is detected???
		DSSet( wFlags, s.row, s.row, s.col, pl, nState )				// sets flags .  The range feature is not used here so  begin row = end row .
		// printf "\t\tlbSelResPrProc( s ) 2\trow:%2d\tcol:%2d  evCode:%2d\tevModif:%2d\tstate:%2d =?=%2d  \r",  s.row, s.col,  s.eventCode, s.eventMod, nState, State( wFlags, s.row, s.col, pl )	
	endif
	// MOUSE :  RESET a cell  by  Shift Clicking
	if ( s.eventCode == kLBE_MouseDown  &&  ( s.eventMod & kSHIFT ) )	// Only mouse clicks  with    SHIFT  are interpreted here.  // ??? In this listbox only MouseDown is detected, whereas in the similar  DataSections  listbox  MouseUp  is detected???
		nState		= 0									// Reset a cell  
		DSSet( wFlags, s.row, s.row, s.col, pl, nState )				// sets flags .  The range feature is not used here so  begin row = end row .
		// printf "\t\tlbSelResPrProc( s ) 3\trow:%2d\tcol:%2d  evCode:%2d\tevModif:%2d\tstate:%2d =?=%2d  \r",  s.row, s.col,  s.eventCode, s.eventMod, nState, State( wFlags, s.row, s.col, pl )	
	endif
End


Function	/S	ListACVAllChansPr()
// Returns list of titles of  'All Currently Computed Values'  which depends on the EvalState, on the number of regions, the number and types of the fits
	variable	ch
	nvar		gChans			= root:uf:cfsr:gChannels					
	string 	lstACVAllCh	= ""
	for ( ch = 0; ch < gChans; ch += 1 )
		lstACVAllCh	+= ListACVPr( ch )
	endfor
	//printf "ListACVAllChansPr()  has %d items \r", ItemsInList( lstACVAllCh )
	return	lstACVAllCh
End

Function	/S	ListACVPr( ch )
// Returns complete list of titles of  'All Currently Computed Values'  which depends on the EvalState, on the number of regions, the number and types of the fits
	variable	ch
	nvar		bEvalState	= $"root:uf:eval:D3:cbEvlCh" + num2str( ch ) + "002"	// 0 : has no region,  0 : just 1 row,  2 : EvalState is in the 3. column
	nvar		nRegs		= $"root:uf:eval:D3:svReg"    + num2str( ch ) + "000"	
	variable	rg, ph, nFitInfo, pa
	string  	lstACV	= ""
	if ( bEvalState )
		for ( rg = 0; rg < nRegs; rg += 1 )
			lstACV	+= ListACVGeneralPr( ch, rg )
			lstACV	+= ListACVFit( ch, rg )
		endfor
	endif
	printf "\t\tListACVPr( ch:%d )  Evalstate:%2d -> Items:%3d,  '%s' ... '%s'   \r", ch, bEvalState, ItemsInList( lstACV ), lstACV[0,80],  lstACV[ strlen( lstACV )-80, strlen( lstACV )-1 ]  
	return	lstACV
End

Function	/S	ListACVGeneralPr( ch, rg )
	variable	ch, rg
	string  	sPostfx		= Postfix( ch, rg )
	string		lst			= ""
	variable	pt, nPts		= ItemsInList( klstALLOWPRINT )
	string  	lstPrintDetails	= ""								// the main value (Index:1) and possible subvalues e.g. beg Y value (index:4:kYB)  or end time (index:5:kTE)   
	variable	n, nDetails
	variable	nDetailIndex
	for ( pt = 0; pt < nPts; pt += 1 )
		lstPrintDetails	= RemoveWhiteSpace( StringFromList( pt, klstALLOWPRINT ) )								//
		nDetails		= ItemsInList( lstPrintDetails, "," )		// Assumption separator
		for ( n = 0; n < nDetails; n += 1 )
			nDetailIndex	= str2num( StringFromList( n, lstPrintDetails, "," ) )		// Assumption separator
			if ( numtype( nDetailIndex ) != kNUMTYPE_NAN )
				lst	= AddListItem( EvalNmDr( pt ) + StringFromList( nDetailIndex, klstE_POST ) + sPostfx, lst, ";", inf )				// the general values : base, peak, etc
			endif
		endfor
	endfor
	return	lst
End


Function	/S	SelectedResultsPrint( nState, ch )
// Returns list of the results selected in the listbox. As the list is for printing  we include not only direct titles but also derive titles e.g.  'Peak_Y' , 'Peak_TE', ... 
// Handles strings  e.g. File, Script, Date, Time
	variable	nState, ch
	variable	rg
	nvar		nRegions	= $"root:uf:eval:D3:svReg" + num2str( ch ) + "000"
	wave /Z	wFlags			= root:uf:wSRFlagsPr
	wave/Z/T	wTxt				= root:uf:wSRTxtPr
	string  	sItem, sLine = ""
	if ( waveExists( wFlags )  &&  waveExists( wTxt ) )			// the waves necessary for printing exist only after the 'Select results panel' has been openend (by checking the checkbox control) 
		for ( rg = 0; rg < nRegions; rg += 1 )
			string  	lstResults	  = ExtractSelectedResults( wFlags, wTxt, nState, ch, rg ) 
			variable	r, nResults	  = ItemsInList( lstResults )
			variable	t, nTitles	  
			variable	d, nDerived = ItemsInList( klstE_POST )			// or  kE_MAXTYP
			string  	sPostFix, sDirectTitle, sOneSelResult
			variable	len, cnt = 0
			if ( nResults )
		 		// printf "\t\tSelectedResultsPrint 1(\tSt:%2d, ch:%2d, rg:%2d )  nRes:%2d\tnTits:%3d\t\t\t\t\t\t\t\t\t\t'%s...' \r", nState, ch, rg, nResults, nTitles, lstResults[0,200]
				if ( nRegions > 1 )
					sprintf sItem, "   Rg:%d  ", rg
					sLine	+= sItem										
				endif
				for ( r = 0; r < nResults; r += 1 )	
					sOneSelResult	= StringFromList( r, lstResults )							// the selected results including direct results e.g. 'Peak'  AND derived results e.g. 'Peak_Y' , 'Peak_TE', ... 

					// The results like Base, Peak, Rise
					nTitles	  = ItemsInList( klstEVALRESULTS )
					for ( t = 0; t < nTitles; t += 1 )										// all possible direct titles but no derived results
						sDirectTitle  = RemoveLeadingWhiteSpace( StringFromList( t, klstEVALRESULTS ) )
						len		  = strlen( sDirectTitle )
						if ( cmpstr( sOneSelResult[ 0, len-1 ] , sDirectTitle ) == 0 )				// we found a selected  direct title  or  one of the derived titles (we stripped the 'derived' postfixes '_Y' , '_TE' , ...)  					
							for ( d = 0; d < nDerived; d += 1 )	
								sPostFix	= StringFromList( d, klstE_POST )				// loop through all derived postfixes e.g.  '_Y' , '_TE' , ...
								if ( cmpstr( sOneSelResult, sDirectTitle + sPostFix ) == 0 )		// we found a selected  direct title (d=0)  or  one of the derived titles (d=1..6) and we now know by index 'd' which it is
variable	bIsString	= str2num( StringFromList( t, klstIS_STRING ) )										
if ( ! bIsString )
									sprintf sItem,  "%s:%g  ", sOneSelResult, Eval( ch, rg, t, d )
else
									sprintf sItem,  "%s:%s  ", sOneSelResult, EvalString( t )
									printf "\t\tSelectedResultsPrint()  t:%2d  bIsString:%2d  -> '%s'  \r", t, bIsString,  sItem
endif
									sLine	+= sItem
								endif
							endfor
						endif
					endfor			//  direct titles

					// The Fits
					string  lstAllFitRESULTS = ListACVFit( ch, rg ) 						// e.g. for ch0 , rg0 and 2 fits  :  'Fit1_Fnc_00;Fit1_A0_00;....Fit2_Fnc_00;...
					nTitles			= ItemsInList( lstAllFitRESULTS )
					for ( t = 0; t < nTitles; t += 1 )									// all possible fit titles (fit titles have no derived results)
						sDirectTitle  = StringFromList( t, lstAllFitRESULTS ) 
						// printf "\t\tSelectedResultsToFile(3b\tst:%2d, ch:%2d ) :\t%s\t%s\r", nState, ch, sOneSelResult, sDirectTitle
						if ( cmpstr( sOneSelResult, RemoveEnding( sDirectTitle, Postfix( ch, rg ) ) ) == 0 )	// We found a selected fit title in the list of all fit titles after stripping postfix  ( = '_ChRg' ) for the comparison
							// printf "\t\tSelectedResultsToFile(4b\tst:%2d, ch:%2d ) :\trg:%2d\tt:%2d/%2d\t%s   \t%s\t \r", nState, ch, rg,  t , nTitles, sDirectTitle, sOneSelResult 

							variable 	ph 		= FitIndex( sOneSelResult ) - 1 + 3		//  Extract the phase / the index of the fit  e.g. 'Fit1_A0'  -> 3
							// Extract the index of the parameter. Use the known index 't'  and RELY ON ORDER IN ListACVFit() : 1. FitInfo, 2. Params, 3. StartParams
							variable	nFitFnc	= FitFnc( ch, rg, ph )					// Extracted from the ControlInfo which might be slow ???  0=FT_NONE,  1=Line,  2=exp
							variable	nFitInfos	= FitInfoCnt()
							variable	pa, nPars	= ParCnt( nFitFnc )
							if ( t < nFitInfos )										// is Info : Extract  Info e.g.  Fit1_Fnc, Fit1_Beg, Fit2_Iter...
								pa		= t 
								sprintf sItem,  "%s:%g   ", sOneSelResult,  FitInfo( ch, rg, ph, pa ) 
								// printf "\t\tSelectedResultsPrint(6b\tst:%2d, ch:%2d ) : rg:%2d   ph:%2d   \tt:%2d/%2d  \tInfo:     %2d\t\t\t\t = \t%8g\t[-> %s] \r", nState, ch, rg, ph, t, nTitles, pa,  FitInfo( ch, rg, ph, pa ), sItem 
							elseif ( t < nFitInfos + nPars )							// is Param
								pa		= t - nFitInfos
								sprintf sItem,  "%s:%g   ", sOneSelResult,  FitPar( ch, rg, ph, pa ) 
								// printf "\t\tSelectedResultsPrint(6b\tst:%2d, ch:%2d ) : rg:%2d   ph:%2d   \tt:%2d/%2d  \tPar:     %2d\t\t\t\t = \t%8g\t[-> %s] \r", nState, ch, rg, ph, t, nTitles, pa,  FitPar( ch, rg, ph, pa ), sItem 
							else												// is StartParam
								pa		= t - nFitInfos - nPars
								sprintf sItem,  "%s:%g   ", sOneSelResult,  FitStPar( ch, rg, ph, pa ) 
								// printf "\t\tSelectedResultsPrint(6b\tst:%2d, ch:%2d ) : rg:%2d   ph:%2d   \tt:%2d/%2d  \tSTPar:%2d\t\t\t\t = \t%8g\t[-> %s] \r", nState, ch, rg, ph, t, nTitles, pa,  FitStPar( ch, rg, ph, pa ), sItem 
							endif

							sLine	  += sItem
						endif
					endfor				//  fit titles	( Info, Params and StartParams )
	
				endfor			// results
			endif
		endfor			// regions
		printf "%s\r", sLine[0,250]
	endif
	// printf "\t\tSelectedResultsPrint(7 \tst:%2d, ch:%2d ) :\t%s\r", nState, ch, sLine
	return	sLine
End


Function	/S	SelectedResultsToFile( nState, ch, nMode )
// Returns list of the results selected in the listbox. As the list determines the columns in the file  we include not only direct titles but also derive titles e.g.  'Peak_Y' , 'Peak_TE', ... 
// Returns 1 line of evaluated values or the column titles header line (depending on nMode ) . All regions are in 1 line. The column titles end with '_' and the region number. 
//    DatSct_0	      Base_0	   Fit1_Co_0	   Fit2_Sl_1
//    24.0000	   2000.1478	   2770.9980	 -17282.5017	
//    25.0000	   -999.4886	  -1387.0249	   8668.9074
	variable	nState, ch, nMode			
	variable	rg
	nvar		nRegions	= $"root:uf:eval:D3:svReg" + num2str( ch ) + "000"
	wave /Z	wFlags		= root:uf:wSRFlagsPr
	wave/Z/T	wTxt			= root:uf:wSRTxtPr
	string  	sItem, sLine = ""
	if ( waveExists( wFlags )  &&  waveExists( wTxt ) )			// the waves necessary for printing exist only after the 'Select results panel' has been openend (by checking the checkbox control) 
		for ( rg = 0; rg < nRegions; rg += 1 )
			string  	lstResults	  = ExtractSelectedResults( wFlags, wTxt, nState, ch, rg ) 
			variable	r, nResults	  = ItemsInList( lstResults )
			variable	t, nTitles
			variable	d, nDerived = ItemsInList( klstE_POST )			// or  kE_MAXTYP
			string  	sPostFix, sDirectTitle, sOneSelResult
			variable	len
			// printf "\t\tSelectedResultsToFile(1\tSt:%2d, ch:%2d ) : Rg:%2d  nRes:%2d\tnTits:%3d\t\t\t\t\t\t\t\t\t\t'%s...' \r", nState, ch, rg,  nResults, nTitles, lstResults[0,200]
			if ( nResults )
				for ( r = 0; r < nResults; r += 1 )											
					sOneSelResult	= StringFromList( r, lstResults )								// the selected results including direct results e.g. 'Peak'  AND derived results e.g. 'Peak_Y' , 'Peak_TE', ... 
					// printf "\t\tSelectedResultsToFile(2\tst:%2d, ch:%2d ) :\t%s\r", nState, ch, sOneSelResult

					// The results like Base, Peak, Rise
					nTitles	  = ItemsInList( klstEVALRESULTS )
					for ( t = 0; t < nTitles; t += 1 )											// all possible direct titles but no derived results
						sDirectTitle  = RemoveLeadingWhiteSpace( StringFromList( t, klstEVALRESULTS ) )
						// printf "\t\tSelectedResultsToFile(3a\tst:%2d, ch:%2d ) :\t%s\r", nState, ch, sDirectTitle
						len		  = strlen( sDirectTitle )
						if ( cmpstr( sOneSelResult[ 0, len-1 ] , sDirectTitle ) == 0 )					// we found a selected  direct title  or  one of the derived titles (we stripped the 'derived' postfixes '_Y' , '_TE' , ...)  					
						// printf "\t\tSelectedResultsToFile(4a\tst:%2d, ch:%2d ) :\t%s\r", nState, ch, sDirectTitle
							for ( d = 0; d < nDerived; d += 1 )	
								sPostFix	= StringFromList( d, klstE_POST )					// loop through all derived postfixes e.g.  '_Y' , '_TE' , ...
								if ( cmpstr( sOneSelResult, sDirectTitle + sPostFix ) == 0 )			// we found a selected  direct title (d=0)  or  one of the derived titles (d=1..6) and we now know by index 'd' which it is
									if ( nMode == kCOLTITLES )
										sprintf sItem, "%12s\t", sOneSelResult + "_" + num2str( rg )	// !!! Assumption naming
									else
										sprintf sItem, "%12.4lf\t", Eval( ch, rg, t, d )
									endif
									// printf "\t\tSelectedResultsToFile(6a\tst:%2d, ch:%2d ) :\tsItem: %s\r", nState, ch, sItem
									sLine	  += sItem
								endif
							endfor
						endif
					endfor				//  direct titles

					// The Fits
					string  lstAllFitRESULTS = ListACVFit( ch, rg ) 								// e.g. for ch0 , rg0 and 2 fits  :  'Fit1_Fnc_00;Fit1_A0_00;....Fit2_Fnc_00;...
					nTitles			= ItemsInList( lstAllFitRESULTS )
					for ( t = 0; t < nTitles; t += 1 )											// all possible fit titles (fit titles have no derived results)
						sDirectTitle  = StringFromList( t, lstAllFitRESULTS ) 
						// printf "\t\tSelectedResultsToFile(3b\tst:%2d, ch:%2d ) :\t%s\t%s\r", nState, ch, sOneSelResult, sDirectTitle
						if ( cmpstr( sOneSelResult, RemoveEnding( sDirectTitle, Postfix( ch, rg ) ) ) == 0 )	// We found a selected fit title in the list of all fit titles after stripping postfix  ( = '_ChRg' ) for the comparison
							// printf "\t\tSelectedResultsToFile(4b\tst:%2d, ch:%2d ) :\trg:%2d\tt:%2d/%2d\t%s   \t%s\t \r", nState, ch, rg,  t , nTitles, sDirectTitle, sOneSelResult 

							if ( nMode == kCOLTITLES )
								sprintf sItem, "%12s\t", sOneSelResult + "_" + num2str( rg )	// !!! Assumption naming
							else
								variable 	ph 		= FitIndex( sOneSelResult ) - 1 + 3		//  Extract the phase / the index of the fit  e.g. 'Fit1_A0'  -> 3
								// Extract the index of the parameter. Approach1 (not taken): Compare names 'ParName( nFitFunc, nPar )' -> slow but does not depend on order
								// Extract the index of the parameter. Approach2: Use the known index 't'  and RELY ON ORDER IN ListACVFit() : 1. FitInfo, 2. Params, 3. StartParams
								variable	nFitFnc	= FitFnc( ch, rg, ph )					// Extracted from the ControlInfo which might be slow ???  0=FT_NONE,  1=Line,  2=exp
								variable	nFitInfos	= FitInfoCnt()
								variable	pa, nPars	= ParCnt( nFitFnc )
								if ( t < nFitInfos )										// is Info : Extract  Info e.g.  Fit1_Fnc, Fit1_Beg, Fit2_Iter...
									pa		= t 
									sprintf sItem, "%12.4lf\t",  FitInfo( ch, rg, ph, pa ) 
									// printf "\t\tSelectedResultsToFile(6b\tst:%2d, ch:%2d ) : rg:%2d   ph:%2d   \tt:%2d/%2d  \tInfo:     %2d\t\t\t\t = \t%8g\t[-> %s] \r", nState, ch, rg, ph, t, nTitles, pa,  FitInfo( ch, rg, ph, pa ), sItem 
								elseif ( t < nFitInfos + nPars )							// is Param
									pa		= t - nFitInfos
									sprintf sItem, "%12.4lf\t",  FitPar( ch, rg, ph, pa ) 
									// printf "\t\tSelectedResultsToFile(6b\tst:%2d, ch:%2d ) : rg:%2d   ph:%2d   \tt:%2d/%2d  \tPar:     %2d\t\t\t\t = \t%8g\t[-> %s] \r", nState, ch, rg, ph, t, nTitles, pa,  FitPar( ch, rg, ph, pa ), sItem 
								else												// is StartParam
									pa		= t - nFitInfos - nPars
									sprintf sItem, "%12.4lf\t",  FitStPar( ch, rg, ph, pa ) 
									// printf "\t\tSelectedResultsToFile(6b\tst:%2d, ch:%2d ) : rg:%2d   ph:%2d   \tt:%2d/%2d  \tSTPar:%2d\t\t\t\t = \t%8g\t[-> %s] \r", nState, ch, rg, ph, t, nTitles, pa,  FitStPar( ch, rg, ph, pa ), sItem 
								endif

							endif

							sLine	  += sItem
						endif
					endfor				//  fit titles	( Info, Params and StartParams )

				endfor				// results
			endif					// nResults
		endfor				// regions
	endif
	// printf "\t\tSelectedResultsToFile(7 \tst:%2d, ch:%2d ) :\t%s\r", nState, ch, sLine

	return	sLine
End

//====================================================================================================================================
// THE  SELECT RESULTS  LISTBOX  PANELS  ( e.g. DRAW , PRINT )	: COMMON  FUNCTIONS			

Function 		Tst()
	variable	nState 	= 1// blue
	variable	ch		= 0
variable rg=0
	SelectedResultsPrint( nState, ch )
	SelectedResultsDraw( nState, ch, rg )
End

Function	/S	ExtractSelectedResults( wFlags, wTxt, nState, ch, rg ) 
// Extract all selected results with a certain  'nState' , 'ch'  and  'rg'  from the listbox.  For this to work the listbox panel must never be closed, but it can be minimised.
// nState  can be  1,  2,  1+2=3  or 4.   The unselected state=0 is not returned.
	variable	nState, ch, rg
	wave	wFlags	
	wave   /T	wTxt		
	// Build the string containing the current state of the listbox. 
	string 	lstSelectResults		= RetrieveSelectResultsFromLB( wFlags, wTxt ) 
	string		lstResultsInStateChRg= ""
	string		sOneItem
	variable	len, n, nItems		= ItemsInList( lstSelectResults )					// e.g.  'Base_01=4;Fit1_Beg_11=2;....'
	variable	nExtrState, nExtrCh, nExtrRg
	for ( n = 0; n < nItems; n += 1 )
		sOneItem	= StringFromList( n, lstSelectResults )							// e.g.  'Base_01=4'			!!! Assumption separator ';'
		nExtrState	= str2num( StringFromList( 1, sOneItem, "=" ) )					// e.g.  4					!!! Assumption separator '='

		if ( nState  & nExtrState )											// allow  combinations of state e.g. Magenta = 3 will add  to list for nState = 1  and  = 2

			sOneItem	= StringFromList( 0, sOneItem, "=" ) 						// e.g.  'Base_01'			!!! Assumption separator '='
			len		= strlen( sOneItem )
			nExtrCh	= str2num( sOneItem[ len-2, len-2 ] )						// e.g.  0					!!! Assumption ACV naming convention
			nExtrRg	= str2num( sOneItem[ len-1, len-1 ] )						// e.g.  1					!!! Assumption ACV naming convention
			if ( ch == nExtrCh  &&  rg == nExtrRg )
				sOneItem	= sOneItem[ 0, len-4 ]								// e.g.  'Base_01'  ->  'Base'	
				lstResultsInStateChRg	+= sOneItem + ";"					//						!!! Assumption separator ';'
			endif
		endif
	endfor
	// printf "\t\tExtractSelectedResults( nState:%2d, ch:%2d, rg:%2d )  \t'%s...'  -> '%s' \r", nState, ch, rg, lstSelectResults[0,100], lstResultsInStateChRg[0,100] 
	return	lstResultsInStateChRg
End


Function	/S	RetrieveSelectResultsFromLB( wFlags, wTxt ) 
	wave	wFlags
	wave   /T	wTxt
	string 	lstSelectResults	= ""
	string  	sPlaneNm		= "BackColors" 
	variable	pl			= FindDimLabel( wFlags, 2, sPlaneNm )
	variable	row, nRows	= DimSize( wFlags, 0 )
	variable	col, nCols		= DimSize( wFlags, 1 )
	string  	sColTitle	= "???"
	variable	nState, ch, rg
	for ( col = 0; col <  nCols; col += 1 )
		sColTitle	= GetDimLabel( wTxt, 1, col )			// 1 means columns
		sscanf sColTitle, "Ch %d Rg %d", ch, rg			// !!! Assumption  ACV naming convention
		// printf "\t\tRetrieveSelectResultsFromLB() col:%2d  ->  ColLabel:'%s'  -> ch:%2d  rg:%2d  \r", col, sColTitle, ch, rg
		for ( row = 0; row <  nRows; row += 1 )
			nState		= State( wFlags, row, col, pl )	
			if ( nState )								// store only changed cells
				lstSelectResults +=	wTxt[ row ][ col ] + "_" + num2str( ch ) + num2str( rg ) + "=" + num2str( nState ) + ";"	//!!! Assumption separators
			endif
		endfor
	endfor
	// printf "\t\tRetrieveSelectResultsFromLB() -> items:%2d, list:\t'%s' \r", ItemsInList( lstSelectResults ), lstSelectResults[0, 200]
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

//---------------------  Naming convention ------------------------------------------------------------
Function		FitIndex( sResult )
	string  	sResult					// e.g. 'Fit1_A0'	-> 3
	variable	len	= strlen( "Fit" )
	return	str2num( sResult[ len, len ] )	// 			-> 3
End

Function	/S	FitPrefix( nIndex )
	variable	nIndex
	return	"Fit" + num2str( nIndex ) + "_"		
End
//-------------------------------------------------------------------------------------------------------------------

Function	/S	ListACVFit( ch, rg )
// !!! Cave: If this order (=Info, Params, StartParams) is changed the extraction algorithm ( = SelectedResultsToFile()  and  SelectedResultsPrint() ) must also be changed 
	variable	ch, rg
	variable	ph, nFitInfo, pa, nPars
	string  	lst		= ""	
	string  	sPreFix
	for ( ph = 0; ph < ItemsInList( ksPHASES ) - PH_FIT0; ph += 1 )
		nvar		bFit		= $"root:uf:eval:D3:cbFit" + num2str( ch ) + num2str( rg )  + num2str( ph ) + "0"	
		if ( bFit )
			variable	nFitInfos	= FitInfoCnt()
			nvar		nFitFnc	= $"root:uf:eval:D3:pmFiFnc" + num2str( ch ) + num2str( rg )  + num2str( ph ) + "0"
			for ( nFitInfo = 0; nFitInfo < nFitInfos; nFitInfo += 1 )										// the fixed fit values: FitFnc, FitBeg, Iterations, etc
				lst	= AddListItem( FitInfoInLBNm( ch, rg, ph, nFitInfo ), lst, ";", inf )
			endfor
			nPars	= ParCnt( nFitFnc-1 )					// -1 wg. FT_NONE
			for ( pa = 0; pa < nPars; pa += 1 )				// the fit  parameters: 	  A0, T0, A1, T12,  Constant, Slope etc.-> Fit1_A0, Fit1_T0...
				lst	= AddListItem( FitParInLBNm( ch, rg, ph, pa, nFitFnc ),  lst, ";" , inf )			// e.g. 'Fit1_A0_00'
			endfor
			for ( pa = 0; pa < nPars; pa += 1 )				// the start parameters: A0, T0, A1, T12,  Constant, Slope  all with '_S'  etc. 
				lst	= AddListItem( FitSTParInLBNm( ch, rg, ph, pa, nFitFnc ),  lst, ";" , inf )			// e.g. 'Fit1_A0_S_00'
			endfor
		endif
	endfor
	// printf "\t\tListACVFit( ch:%2d, rg:%2d ) returns lst: '%s'  \r", ch, rg, lst[0,200]
	return	lst
End	

//-----------------------------------------------  Naming convention : The fit titles in the listbox   -------------------------------------------------------
// The fit titles built here still contain the channel/region postfix, which is dropped later when the titles are actually displayed in the listbox
Function	/S	FitInfoInLBNm( ch, rg, ph, nFitInfo )
	variable	ch, rg, ph, nFitInfo
	string  	sNm		= FitPrefix( ph + 1 ) + FitInfoNm( nFitInfo ) + Postfix( ch, rg )
	return	sNm
End

Function	/S	FitParInLBNm( ch, rg, ph, par, nFitFnc )
	variable	ch, rg, ph, par, nFitFnc
	string  	sNm		= FitPrefix( ph + 1 ) + ParName( nFitFnc-1, par ) + Postfix( ch, rg )	//  -1 wg. FT_NONE . The fit  parameters: 	  A0, T0, A1, T12,  Constant, Slope etc.-> Fit1_A0, Fit1_T0...
	return	sNm
End

Function	/S	FitSTParInLBNm( ch, rg, ph, par, nFitFnc )
	variable	ch, rg, ph, par, nFitFnc
	string  	sNm		= FitPrefix( ph + 1 ) + ParName( nFitFnc-1, par ) +"_S" + Postfix( ch, rg )	//  -1 wg. FT_NONE . The fit  parameters: 	  A0, T0, A1, T12,  Constant, Slope etc.-> Fit1_A0, Fit1_T0...
	return	sNm
End
//------------------------------------------------------------------------------------------------------------------------------------------


Function		ClearResultSelection( wFlags )
// Resets the whole  'Select results'  listbox to 'unselected' : wSRFlags = nState = 0
	wave	wFlags	
	string  	sPlaneNm		= "BackColors" 
	variable	pl			= FindDimLabel( wFlags, 2, sPlaneNm )
	variable	row, nRows	= DimSize( wFlags, 0 )
	variable	col, nCols		= DimSize( wFlags, 1 )
	for ( col = 0; col <  nCols; col += 1 )
		for ( row = 0; row <  nRows; row += 1 )
			DSSet( wFlags, row, row, col, pl,  0 )				// sets flags .  The range feature is not used here so  begin row = end row .
		endfor
	endfor
End


//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


Function		RemoveColumnStateLB( column, nState )
// Removes selectively  'nState'  in any column  e.g.  removes  'Average'  on all data units in column while leaving   'Table'  state untouched
	variable	column, nState
	variable	dsFirst, dsLast, dsLastOfExp, dsSize 
	variable	nOldState, nRemovedState		
	wave	wFlags		= root:uf:wLBFlags
	string  	sPlaneNm		= "BackColors" 
	variable	pl			= FindDimLabel( wFlags, 2, sPlaneNm )
	variable	row			= DimSize( wFlags , 0 ) - 1						// the last data section of the entire experiment
	DS2Lims( row, column, dsFirst, dsLastOfExp, dsSize )						// computes  'dsL'  : the last data section of the entire experiment
	row	= 0
	do
		DS2Lims( row, column, dsFirst, dsLast, dsSize ) 						// computes first and last data section of the current data unit e.g.  Frame or Block

		nOldState		= State( wFlags, dsFirst, column, pl )
		nRemovedState	= nOldState & ( 0xffffffff - nState ) 					// mask out  the  'nState'  bit 



// 050728 todo  ?????????
variable	ch	= 0
	string   wDrawDataNm = OrgWvNm( ch, dsFirst, dsSize )		// make a UNIQUE name for each trace segment

	string   sWNm		= EvalWndNm( ch )
	wave   wDSColors  =	root:uf:wDSColors

	if ( WinType( sWNm ) == kGRAPH ) 									// As the user may have closed a window, perhaps to remove an empty channel, ...
																			// ..we do not automatically reopen the window. To revive the channel the file must be reloaded. 
		string	sTNL	= TraceNameList( sWNm, ";", 1 )
		if ( WhichListItem( wDrawDataNm, sTNL, ";" )  != kNOTFOUND )			// only if wave is not in graph append the wave to the graph
			ModifyGraph 	  /W=$sWNm  rgb( $wDrawDataNm ) = ( wDSColors[ nRemovedState ][ 0 ], wDSColors[ nRemovedState ][ 1 ], wDSColors[ nRemovedState ][ 2 ] )
		endif
	endif



		printf "\t\tRemoveColumnStateLB( colm:%d, nState:%d ) \tdsFirst:%3d..%3d \tOldState:%2d\t->\tRemovedState:%2d \t \r",  column, nState, dsFirst, dsLast, nOldState, nRemovedState
		DSSet( wFlags, dsFirst, dsLast, column, pl, nRemovedState )
		row += dsSize
	while ( dsLast < dsLastOfExp ) 		// todo : truncated
	SetPrevRowInvalid() 
End


Function		ResetColumnLB( column )
//
	variable	column
	variable	dsFirst, dsLast, dsLastOfExp, dsSize 
	variable	nState		= 0										// 0  = default = virgin state	: action will reset
	wave	wFlags		= root:uf:wLBFlags
	string  	sPlaneNm		= "BackColors" 
	variable	pl			= FindDimLabel( wFlags, 2, sPlaneNm )
	variable	row			= DimSize( wFlags , 0 ) - 1						// the last data section of the entire experiment
	DS2Lims( row, column, dsFirst, dsLastOfExp, dsSize )						// computes  'dsL'  : the last data section of the entire experiment
	row	= 0
	do
		DS2Lims( row, column, dsFirst, dsLast, dsSize ) 						// computes first and last data section of the current data unit e.g.  Frame or Block
		if ( State( wFlags, dsFirst, column, pl ) )
			DSSetAndAnalyse( ksEVAL, wFlags, dsFirst, dsLast, column, pl, nState )
		endif
		row += dsSize
	while ( dsLast < dsLastOfExp ) 		// todo : truncated
	SetPrevRowInvalid() 
End


Function		RedrawWindows()
	wave	wFlags		= root:uf:wLBFlags
	variable	col, nState	, dsFirst, dsLast, dsSize		
	variable	row, nRows	= DimSize( wFlags, 0 )
	string  	sPlaneNm		= "backColors" 
	variable	pl			= FindDimLabel( wFlags, 2, sPlaneNm )
	printf "\t\tRedrawWindows()     (should be !..) ..only displaying....\r"
	for ( col = 0; col <=  kCOLM_PON; col += 1 )
//		row	= 0
//		do
//			DS2Lims( row, col, dsFirst, dsLast, dsSize ) 						// computes first and last data section of the current data unit e.g.  Frame or Block
//			nState	= State( wFlags, dsFirst, col, pl ) 
//			if ( nState != 0 ) 
//				DSSetAndAnalyse( ksEVAL, wFlags, dsFirst, dsLast, col, pl, nState )
//			endif
//			row += dsSize
//		while ( row < nRows ) 

//		for ( row = 0; row <  nRows; 		)
//			DS2Lims( row, col, dsFirst, dsLast, dsSize ) 						// computes first and last data section of the current data unit e.g.  Frame or Block
//			nState	= State( wFlags, row, col, pl ) 
//			if ( nState != 0 )			
//				DSSetAndAnalyse( ksEVAL, wFlags, dsFirst, dsLast, col, pl, nState )
//			endif		
//			row += dsSize
//		endfor

		for ( row = 0; row < nRows;  row += dsSize )
			DS2Lims( row, col, dsFirst, dsLast, dsSize ) 						// computes first and last data section of the current data unit e.g.  Frame or Block
			nState	= State( wFlags, row, col, pl ) 
			if ( nState != 0 )			
				DSSetAndAnalyse( ksEVAL, wFlags, dsFirst, dsLast, col, pl, nState )
//				DSSetAndDisplay( ksEVAL, wFlags, dsFirst, dsLast, col, pl, nState )
			endif		
		endfor

	endfor
		DSDisplayAverage()
End	


Function		ClearWindows()
	nvar		gChannels		= root:uf:cfsr:gChannels
	variable	ch
	string		sWNm
	for ( ch = 0; ch < gChannels; ch += 1)
		sWNm	= EvalWndNm( ch )
		EraseTracesInGraph( sWNm )
	endfor
End


//=======================================================================================================================

Function		CFSDisplayAllChanInit( sFolder, nChannels )
// creates windows for  Eval  data
	string  	sFolder
	variable	nChannels

	string  	lstCfsWindows	= WinList( ksEVAL_WNM + "*", ";" , "WIN:1" )			// all graphs starting with 'Eval' , in this case 'Eval0' , Eval1' , Eval2' ...
	variable	ch, CfsWndCnt	= ItemsInList( lstCfsWindows )
	if ( CfsWndCnt != nChannels )											// If the number of windows changes we kill them all as their sizes will change
		for ( ch = 0; ch < CfsWndCnt; ch += 1)
			DoWindow  /K $StringFromList( ch, lstCfsWindows ) 					// Kill it
		endfor
		string  	sPnOptions	= ":dlg:tPnEvalDetails" 						// if windows are added or killed then reflect the changes in the Eval panel .  TODO also when only a channel number changes?!? 
		UpdatePanel(  "PnEvalDetails", "Evaluation Details" , sFolder, sPnOptions )		// same params as in  ConstructOrDisplayPanel()
	endif
	// print  "\t\tDebug1 : \t\t\tGraphs 'Eval..':", WinList( ksEVAL_WNM + "*", ";" , "WIN:1" ) , "all windows 'Eval..' except Graphs (should be none): ", WinList( ksEVAL_WNM + "*", ";" , "WIN:214" )

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

	// Save average (it there is one) when loading a new file
	nvar		gAvgKeepCnt	= root:uf:eval:D3:gAvgKeepCnt0000		// 
	if ( gAvgKeepCnt )
		DSSaveAverage()								// auto-build the average file name and save the data
		DSEraseAverages()								// also sets  gAvgKeepCnt	= 0
	endif
	// todo : also delete wAvg ???  redrawWindow  ??? erase Avq ???
End		


Function		BuildEvalWnd( sWNm, ch, nChans )
	string  	sWNm
	variable	ch, nChans		
	variable	Left, Top, Right, Bot
	GetAutoWindowCorners( ch, nChans, 0, 1, Left, Top, Right, Bot, 20, 95 )		//...then compute default size and position..

	if ( WinType( "PnDSct" ) == kPANEL ) 								// Only if the data section panel exists...
		GetWindow $"PnDSct" , wsize									// ..then position the data windows just to the right of the data sections panel...
		// printf "\t\tCFSDisplayAllChanInit()\tLeft:%4d\tPnWidth:%4d\t \r", Left, V_right
		Left	= V_right												// .. which overwrites the prevoius left border as computed above. 
	endif

	Display 	/K=1  /W=( Left, Top, Right, Bot )							//...and  build an empty window
	string  	sActWnd	= WinName( 0, 1 )								// Look for the active _GRAPH_ .  Use 'RenameWindow'  , do not use DoWindow /C .....
	RenameWindow   $sActWnd	$sWNm 								// Do not use DoWindow /C as this fails in in rare but reproducible cases (gChannels and file length changing, hitting 'next file very fast and often) as it uses the panel instead of the graph.
	SetWindow   	$sWNm	hook( hDSGraphHookNm )	= fDSGraphHook		//OK
	SetWindowTitle( sWNm, ch )										// Set new window title which may have changed even if number of channels remains constant e.g. 'Adc2' -> 'Adc3'
	// string  	sTNL	= TraceNameList( sWNm, ";", 1 ) ; printf "\t\tCFSDisplayAllChan( Init \t\t\t '%s'\t DiCn:%2d\tErase:%d  File:'%s'\tCh:%d/%d\tNm:%s\tTi:'%s'\tTraces:%3d\t'%s...' \r", StringFromList( nMovetoData, sDICFSMOVE), nDisplayCnt, bDoErase, gsDataFileR, ch, gChannels, sWNm, sWndTitle, ItemsInList( sTNL ), sTNL[ 0,100 ]
End


Function 		fDSGraphHook( s )
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
		// print s
		//printf "\t\t\tfDSGraphHook()\t\tEvntCode:%2d\t%s\tmod:%2d\tch:%d\t'%s'\t'%s' =%3d\tX:%4d\t%7.3lf\tY:%4d\t%7.3lf\t \r ", s.eventCode, pd( s.eventName, 8 ), s.eventMod, ch, s.winName,  sKey, s.keycode, s.mouseLoc.h, xaxval, s.mouseLoc.v, yaxval
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
		variable  	/G	root:uf:eval:evl:gnKey1		= kNOTFOUND			// The first key of a 2-key-combination must be remembered when the second key is processed. Code requires to start with kNOTFOUND.
		nvar	/Z	gbInCursorMode			= root:uf:eval:evl:gbInCursorMode// make the local globals known...
		nvar	/Z	gnKey1					= root:uf:eval:evl:gnKey1		//
	endif
	
	// For keyboard strokes we can only use the SHIFT modifier,  ALT interferes with Igor's menu, CTRL with Igor's shortcuts. Mouse CTRL ALT is OK.
	// Uses Stimfits 2-letter-shortcuts consequently. Only ADDITIONALLY buttons are provided...
	if ( s.eventCode == kWHK_keyboard ) 

		if ( gnKey1	!= kNOTFOUND )		 						// Are we expecting the 2. key of a  2-key-combination ?
			if ( IsValidKeyCombination( gnKey1, s.keycode ) )				// Is the 2. key appropriate for the 1. key? 
				ExecuteActions( gnKey1, s.keycode )
			else												// It is not a valid 2. key 
				if ( IsKey1of2( s.keycode ) )							// It is a 1. key of a new 2-key-combination
					gnKey1		= s.keycode
				else											// It is a single key
					gnKey1		= kNOTFOUND
					ExecuteActions( s.keycode, kNOTFOUND)
				endif
			endif
		else
			if ( IsKey1of2( s.keycode ) )								// It is a 1. key of a new 2-key-combination
				gnKey1		= s.keycode
			else												// It is a single key
				gnKey1		= kNOTFOUND
				ExecuteActions( s.keycode, kNOTFOUND)
			endif
		endif		
	endif

	return returnVal							// 0 : allow further processing by Igor or other hooks ,  1 : prevent any additional processing 
End


Function		SetWindowTitle( sWNm, ch )
	string  	sWNm
	variable	ch
	string  	sWndTitle	= "#" + num2str( ch ) + " : " + CfsIONm( ch )	
	DoWindow  /T	 $sWNm	sWndTitle
End

Function	/S	EvalWndNm( ch )
	variable	ch
	return	ksEVAL_WNM + num2str( ch ) 			 					//   window names must not contain '('  or  ')'
End

//Function	/S	CfsIONm( ch )
//// the window TITLE may contains bracket so the user sees the dependencies between  the Adc- and telegraph-channels...
//// ...but neither the window NAME   nor  any   TRACES  may contain brackets  '('  or  ')'   [superimposing will not work with illegal names as IGOR truncates the trace name at the first blank ]
//	variable	ch
//	string		sIOName	= GetCFSChanName( ch ) 			// name is limited to some 20 characters....
//	sIOName	= ReplaceCharWithString( sIOName, " ", "_" )	// convert spaces to underscores ( one could equally well remove them completely...)
//	sIOName	= ReplaceCharWithString( sIOName, "(", "_" )	// convert parenthesis to underscores
//	sIOName	= ReplaceCharWithString( sIOName, ")", "_" )	// convert parenthesis to underscores
//	sIOName	= RemoveWhiteSpace( sIOName )			// remove tabs, CR, LF
//	if ( strlen( sIOName ) == 0 ) 
//		sIOName	= "Adc" + num2str( ch )
//	endif
//	// printf "\tCfsIONm( ch :%d ) : sIOName:'%s' \r", ch, sIOName
//	return	sIOName
//End



static Function	DSDisplayAllChan( sFolder, wFlags, dsFirst, dsLast, col, pl, nState )	
//, ch, nChannels, wData, nCurSwp, bSupImp, sWNm, sIOName )
	string  	sFolder
	wave	wFlags	
	variable	dsFirst, dsLast, col, pl, nState

	wave	wDSColors		= root:uf:wDSColors
	nvar		gChannels			= root:uf:cfsr:gChannels
	nvar		gbDispUnselect		= $"root:uf:eval:D3:gbDispUnsel0000"
	nvar		gnDispMode		= $"root:uf:eval:D3:gDspMode0000" 		
	nvar		gDataSections		= root:uf:cfsr:gDataSections
//	nvar		gbDisplayAllPoints	= $"root:uf:cfsr:gbDisplayAllPoints"
//	nvar		gOfs				= root:uf:cfsr:gOfs 
	variable	ch
	variable	nCurSwp	= dsFirst
	variable	nSize	= dsLast - dsFirst + 1
	variable	nDataPts, nDrawPts, nOfsPts, step = 1
	variable	StartTime, EndTime							// 050120 in seconds
	variable	nSmpInt	= CFSSmpInt()
	variable	row		= dsFirst, dsLa
	string		wDrawDataNm, wFoDrawDataNm	
	string  	sWNm, sTNL, sTxt

	// Decompose a range of data unit into single data units
	do
		for ( ch = 0; ch < gChannels; ch += 1)
	
			ExtractionParams( ch, row, col, nCurSwp, dsLa, nSize, nDataPts, nDrawPts, nOfsPts, step, wDrawDataNm, wFoDrawDataNm )  // all but the first 3 parameters are references 
			wave   /Z	wDrawData	=	$wFoDrawDataNm

	wave	wCurRegion	= root:uf:eval:evl:wCurRegion
	wCurRegion[ kCURSWP ]	= nCurSwp			
	wCurRegion[ kSIZE ]		= nSize		

			// DISPLAYING.......
			sWNm	= EvalWndNm( ch )
			sTxt		= "skip uns"
			if ( nState != 0   &&   ( nState != kST_SKIP  ||  gbDispUnselect == TRUE )  )

				if ( !waveExists( wDrawData )   ||  numpnts( wDrawData ) != nDrawPts )		// user may have deleted wave  or  changed  gbDisplayAllPoints
					make	/O /N=(nDrawPts)	$wFoDrawDataNm
					wave	wDrawData	=	$wFoDrawDataNm
					sTxt	= "create"
					wave  	wData	= $"root:uf:cfsr:wCfsBig" + num2str( ch )			// Use it here under an alias name 
					// Copying the data may not seem very effective, but it is currently the best way to do it. See Igor mailing list, Larry Hutchinson 050120
					CopyDrawPoints( wData, wDrawData, nDrawPts, nOfsPts, step )
				else	
					sTxt	= "exists"
					wave  	wData	= $"root:uf:cfsr:wCfsBig" + num2str( ch )			// Use it here under an alias name 
				endif	

				if ( WinType( sWNm ) == kGRAPH ) 									// As the user may have closed a window, perhaps to remove an empty channel, ...
																			// ..we do not automatically reopen the window. To revive the channel the file must be reloaded. 
					if ( gnDispMode == kSINGLE )
						EraseTracesInGraphExcept( sWNm, ksWAVG ) 					// 050601 only erase data units traces, but leave averaged trace  TODO: this is called too often......
					endif

					sTNL	= TraceNameList( sWNm, ";", 1 )
					if ( WhichListItem( wDrawDataNm, sTNL, ";" )  == kNOTFOUND )			// only if wave is not in graph append the wave to the graph
						AppendToGraph  /W=$sWNm 	wDrawData					// wDrawData does contain folder ,  wDrawDataNm does NOT contain folder.
					endif
					ModifyGraph 	  /W=$sWNm  rgb( $wDrawDataNm ) = ( wDSColors[ nState ][ 0 ], wDSColors[ nState ][ 1 ], wDSColors[ nState ][ 2 ] )
	
					if ( gnDispMode == kSTACKED )
						StartTime	= 0											// Mode Stacked=Superimposed :	start all sweeps at 0
					elseif ( gnDispMode == kSINGLE )
						StartTime	= nOfsPts * nSmpInt / kXSCALE						// Mode Single Sweep :			start each sweep at its proper time
					elseif ( gnDispMode == kCATENATED )
						StartTime	= nOfsPts * nSmpInt / kXSCALE						// Mode catenated :				start each sweep at its proper time
					endif
				 	EndTime	= StartTime + nDrawPts * step * nSmpInt / kXSCALE
	
					// printf "\t\tDSDisplayAllChan(a) stp:%2d \tdltaX:%.4lf\tStartTime:%6.4lf \tEndTime:%6.4lf \tSmpInt:%g\t%s\tgraph has now %d traces  \r", step, deltaX( wDrawData ), StartTime, EndTime, nSmpInt, wDrawDataNm, ItemsInList( sTNL )
					SetScale /I X, StartTime , EndTime, ksXUNIT, wDrawData
					// printf "\t\tDSDisplayAllChan(b)\tc:%d\t%s\tds:%3d..%3d\tsz:%3d \tstp:%2d \tdltaX:%.4lf\tStartTime:%6.4lf \tEndTime:%6.4lf \tSmpInt:%g   \r", ch, wDrawDataNm, nCurSwp, dsL, gSize,  step, deltaX( wDrawData ), StartTime, EndTime, nSmpInt
		
					ModifyGraph   /W=$sWNm  axisEnab( left )={ 0, 0.85 }					// 0.9 : leave 10% space on top for textbox ( 0.8 is better for windows lower than 1/3 screen height )
					PrintEvalTextbox( ch, sWNm )
				endif					// graph exists

			endif					// state

			if ( nState == 0   ||   ( nState == kST_SKIP  &&  gbDispUnselect == FALSE )  )
				if ( waveExists( wDrawData ) )
					//RemoveAnalysis( wData, ch, nChannels, nOfsPts, nDataPts, nSmpInt, gDataSections )	
					if ( WinType( sWNm ) == kGRAPH ) 									// As the user may have closed a window, perhaps to remove an empty channel, ...
																	// ..we do not automatically reopen the window. To revive the channel the file must be reloaded. 
						sTNL	= TraceNameList( sWNm, ";", 1 )
						if ( WhichListItem( wDrawDataNm, sTNL, ";" )  != kNOTFOUND )			// only if wave is in graph (the user may have removed it  or  'DispUnselected'  hides it)...
							RemoveFromGraph   /W=$sWNm  $wDrawDataNm				// this name does not contain the folder 
							KillWaves	$wFoDrawDataNm
						endif
						sTxt = "kill     "
					endif					
				endif
			endif					// state

			variable	nPrevState	= State( wFlags, row,  col, FindDimLabel( wFlags, 2, "BackColors" ) )
			// Main debug printing line
			// printf "\t\tDSDisplayAllChan( co:%d\tro:%2d\tsF:%2d\tsL:%2d\tsz:%2d\tOst:%2d\tst:%2d\t%s\t%s\tWNm:%s  c:%d\tOpts:%6d\tDapt:%6d\tDrpt:%6d\tstp:%4d\twv:\t%s\t%s\t \r", col, row, nCurSwp, dsLa, nSize, nPrevState, nState, StringFromList(nState, lstSTACOL), sTxt, sWNm, ch, nOfsPts, nDataPts, nDrawPts, step, pd(wDrawDataNm,10), pd(wFoDrawDataNm,19)


			// 050603 Scale the averaged wave : In  'Single'  mode the time scale displays the true time values of the currently viewed data unit. Position the averaged trace at the same time.
			// 050603 Scale the averaged wave : In  'Stacked'  mode all data units and the time scale start at time 0. Position the averaged trace at the same time 0.
			if ( WinType( sWNm ) == kGRAPH ) 									// As the user may have closed a window, perhaps to remove an empty channel, ...
				if ( gnDispMode == kSINGLE  ||  gnDispMode == kSTACKED )
					wave  /Z	wAvg		= $FoAvgWvNm( ch )
					if ( waveExists ( wAvg ) )										// the user may have deleted the wave 
						SetScale /I X, StartTime , EndTime, ksXUNIT, wAvg
					endif
				endif
			endif


			// ANALYSING.......
// 050726
if ( nState & kST_AVG  ||   nState & kST_TBAV )		// untested and unfinished.........
				nvar		bEvalState	= $"root:uf:eval:D3:cbEvlCh" + num2str( ch ) + "002"			// 0 : has no region,  0 : just 1 row,  2 : EvalState is in the 3. column
				if ( bEvalState )
					 Analyse( ch, gChannels, nOfsPts, nDataPts, nSmpInt, gDataSections, nCurSwp, nSize )	
				endif
endif

			variable	bAddOrRemove	
			if (   ( nState & kST_AVG )  &&  ! ( nPrevState & kST_AVG )  )
				bAddOrRemove	   = kADD
				DSAddOrRemoveAvg( nState, ch, wDrawData, nDataPts, sWNm, bAddOrRemove )
				printf "\t\t\t%s\tavg\t  co:%d\tro:%2d\tsF:%2d\tsL:%2d\t%s\tPrSt:%2d\t-->%2d\t%s\t%s \r", pd(StringFromList( bAddOrRemove, lstREM_ADD),6), col, row, nCurSwp, dsLa,  StringFromList( nPrevState, lstSTACOL ), nPrevState,  nState, StringFromList( nState, lstSTACOL ), wFoDrawDataNm 	
			endif
			if ( ! ( nState & kST_AVG )  &&    ( nPrevState & kST_AVG )  )
				bAddOrRemove	   = kREMOVE
				DSAddOrRemoveAvg( nState, ch, wDrawData, nDataPts, sWNm, bAddOrRemove )
				printf "\t\t\t%s\tavg\t  co:%d\tro:%2d\tsF:%2d\tsL:%2d\t%s\tPrSt:%2d\t-->%2d\t%s\t%s \r", pd(StringFromList( bAddOrRemove, lstREM_ADD),6), col, row, nCurSwp, dsLa,  StringFromList( nPrevState, lstSTACOL ), nPrevState,  nState, StringFromList( nState, lstSTACOL ), wFoDrawDataNm
			endif
			
		endfor					// all channels

		row += nSize
	while ( dsLa < dsLast   ) 		// todo : truncated

End

static Function	ExtractionParams( ch, row, col, nCurSwp, dsLa, nSize, nDataPts, nDrawPts, nOfsPts, step, wDrawDataNm, wFoDrawDataNm )  
// when row and column of the listbox are given, all parameters relevant for data extraction from the big original data wave are computed
	variable	ch, row, col
	variable	&nCurSwp, &dsLa, &nSize				// references
	variable	&nDataPts							// reference : number of original data points, must be included inavg but may be too many for drawing
	variable	&nDrawPts						// reference : number of decimated points to be displayed in graph 
	variable	&nOfsPts, &step						// references
	string  	&wDrawDataNm, &wFoDrawDataNm 		// references
	nvar		gOfs				=   root:uf:cfsr:gOfs 
	nvar		gbDisplayAllPoints	= $"root:uf:cfsr:gbDisplayAllPoints"

	DS2Lims( row, col, nCurSwp, dsLa, nSize ) 						// computes first and last data section of the current data unit e.g.  Frame or Block

	nOfsPts	= DSBegin( nCurSwp ) + gOfs * DSPoints( nCurSwp )	
	nDataPts	= DSBegin( nCurSwp  + nSize ) - DSBegin( nCurSwp ) 
		
	if ( gbDisplayAllPoints )	
		nDrawPts	= nDataPts								// WITHOUT DECIMATION: displaying 2MB takes about 10 s 
		step		= 1
	else	
		nDrawPts	= min( cDRAWPTS, nDataPts )					// WITH DECIMATION: 2MB stepped down to 500 pts: display takes about  3s (display alone is faster than that, there are other time eaters...)
		step		= trunc( max( nDataPts / nDrawPts, 1 ) )
	endif		

	wDrawDataNm = OrgWvNm( ch, nCurSwp, nSize )				// make a UNIQUE name for each trace segment

	wFoDrawDataNm	= "root:uf:cfsr:" + wDrawDataNm
End

// todo:  use waveform arithmetic or avoid the copying altogether.......
Static Function		CopyDrawPoints( wData, wDrawData, nDrawPts, nOfsPts, step )
	wave 	wData, wDrawData
	variable	nDrawPts, nOfsPts, step
	variable	n
	for ( n = 0; n < nDrawPts; n += 1 )
		wDrawData[ n ] = wData[ nOfsPts + n * step ]
	endfor
End


////////////////////////////////////////////////////////////////////////////////////////////////
//  WRITE  AVERAGE    NEW  0501 controlled by DSSelect listbox
//  these functions seem to bear quite an amount of overhead but they have 2 distinct advantages:
//	- there are no global variables / strings / waves  concerning  the 'Average'  in the main function  'Analyse'  (which is already quite large), all data are 'hidden'
//	- there is extensive 'Existence' checking of waves and windows so no assumptions have to be made about the current state of the program (e.g. the user should not but may have deleted traces)

static  Function		DSAddOrRemoveAvg( nState, ch, wData, nDataPts, sWndNm, bAddOrRemove )
// writes average data in different files for each channel. The channels are distinct by the file name postfix.
// the channels are independent so if the user switches channels on/off during averaging the same averaging path may result in different indices from channel to channel
// writing averages could be realized somewhat simpler (header and data could be written in 1 step) but the framework used is here is more general and can be used similarly for 'AddToTable()' 
	variable	nState, ch, nDataPts, bAddOrRemove
	wave	wData
	string  	sWndNm
	nvar		gAvgKeepCnt	= root:uf:eval:D3:gAvgKeepCnt0000		// 
	string		sAvgWvNm	= AvgWvNm( ch )
	string		sFoAvgWvNm	= FoAvgWvNm( ch )
	// Update and display the average wave
	wave  /Z	wAvg = $sFoAvgWvNm			
	 printf "\t\t\tDSAddOrRemoveAvg\t%s\tch:%d\t%s\tnAvgd:%3d\tPts:%4d\tst:%2d\t%s\tdapts:%6d\tlft:\t%6.2lf\tdlt:\t%6.2lf \r", pd(StringFromList( bAddOrRemove, lstREM_ADD),6), ch, sAvgWvNm, AvgCnt(), numPnts( wData ), nState, "              ", nDataPts, leftx( wAvg), deltaX( wAvg ) 
	if ( ! waveExists ( wAvg ) )									// trace may not (yet) exist or the user may have deleted it
		duplicate	/O 	wData  $sFoAvgWvNm					// MUST USE $STRING SYNTAX (duplicate in user functions in loops...)
		wave  	wAvg 	= 	$sFoAvgWvNm			
		wAvg	= 0
	else
		if ( numPnts( wAvg ) < nDataPts )
			Redimension  	/N=(nDataPts)	wAvg				// Igor does not set points behind the redimensioned range to 0. This can be observed ..
		endif												// .. when averaging alternately long and short traces. This can be useful or undesired...
	endif
	variable	nAddOrRemove	= bAddOrRemove * 2 - 1				// Remove: 0 > 1 , Add: 1 > 1 
	gAvgKeepCnt	+= nAddOrRemove
	// todo: handles different segment lengths differently....	
	// wAvg	= gAvgKeepCnt  == 0  ?  0  :  ( wAvg * (gAvgKeepCnt - nAddOrRemove) + nAddOrRemove * wData )  /  gAvgKeepCnt 
	wAvg	= gAvgKeepCnt  == 0  ?  0  :  wAvg  +  ( wData - wAvg )   * nAddOrRemove /  gAvgKeepCnt

End


static  Function		DSDisplayAverage()
	variable	ch
	nvar		gChannels		= root:uf:cfsr:gChannels
	for ( ch = 0; ch < gChannels; ch += 1 ) 
		string		sWndNm		= EvalWndNm( ch )
		string  	sAvgNm		= AvgWvNm( ch )
		wave  /Z	wAvg		= $FoAvgWvNm( ch )
		DSDisplayAver( ch, wAvg, sAvgNm, sWndNm )
	endfor
End


static  Function		DSDisplayAver( ch, wAvg, sAvgNm, sWNm )
	variable	ch
	wave   /Z	wAvg
	string  	sWNm, sAvgNm									// name of trace without folder
	nvar		gbDispAverage	= root:uf:eval:D3:gbDispAvg0000
	string  	sTNL, sTxt	= "no  wave "
	if ( waveExists ( wAvg ) )										// the user may have deleted the wave 
		if ( WinType( sWNm ) == kGRAPH )							// the user may have killed the graph window
			sTNL	= TraceNameList( sWNm, ";", 1 )				// the user may have removed the trace from the graph 
			if ( WhichListItem( sAvgNm, sTNL, ";" )  == kNOTFOUND )		// only if   wave is not in graph append average wave. 
				AppendToGraph  /W=$sWNm 	wAvg				// wAvg does contain folder ,  sAvgNm does NOT contain folder.
			endif
			if ( gbDispAverage )
				ModifyGraph 	  /W=$sWNm  rgb( $sAvgNm ) = ( 43000, 33000, 0 ) 				// brown
				sTxt	= "Show avg"
			else
				ModifyGraph 	  /W=$sWNm  rgb( $sAvgNm ) = ( kBGCOLOR,kBGCOLOR,kBGCOLOR)	// background color = invisible 
				sTxt	= "Hide  avg"
			endif
		 printf "\t\t\tDSDisplayAverage( \tch:%d ) \t%s\t%s\t(exists) in W\t%s\t(exists)\tnAvgd:%3d\tPts:%4d\t \r", ch, sTxt, sAvgNm, sWNm, AvgCnt(), numPnts( wAvg)
		endif
	endif
End


static  Function	DSEraseAverages()
// Remove all  'average-marked' (usually red or magenta) data units from the data selection listbox  and erase the average wave for all channels.
// It would be syntactically cleaner to call  'DSSetAndAnalyse()'  repeatedly for each data unit but as the repeated subtraction and display of the average wave..
// ..would be too time-consuming, here a shortcut is made: the listbox is cleared separately from the average wave which is much faster..
	nvar		gAvgKeepCnt	= root:uf:eval:D3:gAvgKeepCnt0000			// 
	nvar		gChans		= root:uf:cfsr:gChannels						
	variable	ch,  col
	//EraseAvgFileNames()										// a new average file will be opened when the next averages is to be added

	for ( col = kCOLM_PR; col <= kCOLM_PON; col += 1 )
		RemoveColumnStateLB( col, kST_AVG )
	endfor

	for ( ch = 0; ch < gChans; ch += 1 ) 							
		string		sWNm	= EvalWndNm( ch )
		if ( WinType( sWNm ) == kGRAPH )						// the user may have killed the graph window
			RemoveFromGraph /Z /W=$sWNm  $AvgWvNm( ch )		// trace name contains no folder
			KillWaves   /Z	$FoAvgWvNm( ch )					// wave name contains folder
		endif
	endfor
	gAvgKeepCnt	= 0
End


static  Function	DSSaveAverage()
	nvar		gChannels		= root:uf:cfsr:gChannels
	nvar		gAvgKeepCnt	= root:uf:eval:D3:gAvgKeepCnt0000			// 
	svar		gsAvgNm		= root:uf:eval:D3:gsAvgNm0000	
	string  	sFilePath		= ""
	variable	ch
	for ( ch = 0; ch < gChannels; ch += 1 ) 
		wave  /Z	wAvg	= $FoAvgWvNm( ch )
		if ( ! waveExists ( wAvg ) )											// trace may not (yet) exist or the user may have deleted it
			Alert( kERR_LESS_IMPORTANT, "No averaged traces." )
			printf "\tNo averaged traces."
		else
			sFilePath		= gsAvgNm + ChannelSpecifier( ch ) + "." + ksAVGEXT	
			waveStats	/Q wAvg
			printf "  Ch:%d   %s\t#Avg:%2d\tAvg:\t%g\tPts:\t%g\t", ch, sFilePath, gAvgKeepCnt, mean( wAvg ), numPnts( wAvg )
			DSWriteAverage( ch, wAvg, sFilePath )							// Update  ( or create )  the average  file  by writing the  average wave data
		endif
	endfor
	gsAvgNm	= ConstructNextResultFileNmA( gsAvgNm, ksAVGEXT )		// search next free avg file and display it in SetVariable input field
	// printf "\tDSSaveAverage() searched and displays next free file where the next AVG data will be written :\t%s  \r", gsAvgNm
End

static Function	DSWriteAverage( ch, wAvg, sFilePath )
// Update  ( or create )  the average  file  by writing the  average wave data
	variable	ch
	wave	wAvg
	string		sFilePath
	variable	nRefNum
	Open  	nRefNum  as sFilePath					// Open file  by  creating it
	if ( nRefNum ) 									// ...a new average always overwrites the whole file, it never appends
		WriteAvgHeader( nRefNum, sFilePath, ch )
		WriteAvgData( nRefNum, wAvg, sFilePath, ch )
		Close	nRefNum
	endif
End

//static   Function		DSWriteAvgHeader( RefNum, sFilePath, ch )
//	variable	RefNum, ch					// only for debugging
//	string		sFilePath						// only for debugging
//	string		sLine		= "   Time      Value  \r"
//	// printf  "\t\t\tAddToAvg()  will add header writing into '%s'   :  %s", sFilePath, sLine	// sLine includes CR 
//	fprintf 	RefNum,  sLine
//End
//
//static   Function		DSWriteAvgData( RefNum, wWave, sFilePath, ch )
//	variable	RefNum, ch					// only for debugging
//	string		sFilePath						// only for debugging
//	wave	wWave
//	variable	step	=1//100					// todo make step variable, average over data points
//	variable	i, pts	= numPnts( wWave )
//	variable	dltax	= deltaX( wWave )
//	string		sLine
//	for ( i = 0; i < pts; i += step )
//		sprintf	sLine, "%8.3lf %8.3lf\r", i * dltax, wWave[ i ]
//		fprintf 	RefNum, sLine					// Add data
//		// printf  "\t\t\tAddToAvg( ch:%d )  will add average (pts:%d, dltax:%g)  writing into '%s'   :  %s", ch, pts, dltax, sFilePath, sLine
//	endfor		
//End

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Common file name management for result (=average and table) functions
//  the idea is to use as few globals as possible and to hide as much of the internals to the calling functions (like 'AddToAverage() '  or  'AddToTable() ' )

static  Function	/S	ConstructNextResultFileNmA( sCfsPath, sExt )
// Check if  ANY of the channels has already a result file with this name, if yes skip this name for ALL channels (just to avoid confusion, theoretically it could be used for other channels)
// Flaw  / limit  : channels 0-9  and  36 indices
	string		sCfsPath, sExt
	variable	NamingMode	= kDIGITLETTER							// 2 naming modes are allowed.   kDIGITLETTER is prefered to avoid confusion with the already used mode kTWOLETTER (used for Cfs file naming) 
	string		sFilePath, sFilePathShort 

	if ( ItemsInList( sCfsPath, "." ) == 2 ) 									// or check if there is an extension 'dat'								
		sFilePathShort	= StripExtensionAndDot( sCfsPath )					// Has dot : is the original  CFS.dat filepath. Convert to average file name by removing the dot and the 1..3 letters...
	else
		sFilePathShort	= RemoveIndexFromFileNm( sCfsPath )				// Has no dot : is an average filepath containing the index of the average but no channnel and no file extension
	endif

	 printf "\r\t\tConstructNextResultFileNmA(1 \t%s\t ) \tstripping to \t\t%s \r",  pd(sCfsPath,23), sFilePathShort
	variable	ch, n = 0, bFileNmFree
	do
		for ( ch = 0; ch <= 9; ch += 1 )									// !!!! limited to channels 0 to 9
			sFilePath	= BuildFileNm( sFilePathShort, ch, n, sExt, NamingMode )	// ..there can be multiple table files for each cfs file so we append a postfix
			if ( FileExists( sFilePath ) )
				bFileNmFree = FALSE
				// printf "\t\tConstructNextResultFileNmA(2 \t%s\t  )\talready used    \t%s \r",  pd(sCfsPath,23), sFilePath
				break
			endif	
			bFileNmFree = TRUE
		endfor
		n += 1													// try the next auto-built file name
	while ( bFileNmFree == FALSE )
		
	 printf "\r\t\tConstructNextResultFileNmA( '%s', '%s' )  returns %s \r",  sCfsPath, sExt, sFilePath
	string  	sFilePathIdx	= RemoveChanFromFileNm( StripExtensionAndDot( sFilePath ) )	// !!!  xxx_7_ch1.avg  ->  xxx_7
	 printf "\t\tConstructNextResultFileNmA(3 \t%s\t ) \treturns next free\t%s \r",  pd(sCfsPath,23), sFilePathIdx

	return	sFilePathIdx
End

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//  Auto-building  filenames  e.g.  for  Average files
//  Limitation:  there is only 1 character reserved for indexing so there are at most 36 files 

static strconstant	ksCHSEP	= "_ch"
static strconstant	ksIDXSEP	= "#"

static Function   /S	BuildFileNm( sCfsFileBase, ch, n, sExt, NamingMode )
// builds  result file name (e.g. average, table) when  path, file and dot (but no extension)  of CFS data  is given (and channel and index) 
// 2 naming modes are allowed.  kDIGITLETTER is prefered to avoid confusion with the already used mode kTWOLETTER (used for Cfs file naming) 
// e.g.  Cfsdata.dat, ch:1, n:6 -> Cfsdata_1f.avg  or  Cfsdata_1f.fit
	string		sCfsFileBase, sExt
	variable	ch, n, NamingMode
	string		sIndexString	= SelectString( NamingMode == kDIGITLETTER,  IdxToTwoLetters( n ),  IdxToDigitLetter( n ) ) 
	return	sCfsFileBase + ksIDXSEP + sIndexString + ChannelSpecifier( ch ) + "." + sExt	// channel number as  _1 digit  in name  e.g.  Cfsdata.dat, ch:1, n:6  ->	Cfsdata_f_ch1.avg	or  Cfsdata_f_ch1.fit
End

static Function   /S	ChannelSpecifier( ch )
	variable	ch
	return	ksCHSEP + num2str( ch )
End

static Function   /S	RemoveChanFromFileNm( sFilePathWithChan )	
// sFilePathWithChan   is the leading part of an auto-built filepath containing  drive, dir, basename, index and channel  but no file extension
// The index part (including the index separator) will be removed .   Must match  'ChannelSpecifier()'
	string  	sFilePathWithChan
	string  	sFilePathNoChan	= RemoveEnding( RemoveEnding( sFilePathWithChan ), ksCHSEP )	
	return	sFilePathNoChan
End

static Function   /S	RemoveIndexFromFileNm( sFilePathWithIndex )	
// sFilePathWithIndex   is the leading part of an auto-built filepath containing  drive, dir, basename and possibly an index but no channel and no file extension
// The index part (including the index separator) will be removed .   Must match  'BuildFileNm()'
// !!! Assumes that the actual index is just ONE character (  NamingMode = kDIGITLETTER  -> index = IdxToDigitLetter()    )
	string  	sFilePathWithIndex
	variable	len	= strlen( sFilePathWithIndex )
	string  	sFilePathNoIndex
	if ( cmpstr( sFilePathWithIndex[ len-2, len-2 ], ksIDXSEP ) == 0 )							// only if there is an index at the end...
	  	sFilePathNoIndex	= RemoveEnding( RemoveEnding( sFilePathWithIndex ), ksIDXSEP )	//..we remove it
	else
	  	sFilePathNoIndex	= sFilePathWithIndex										// if no index is recognised the path is returned unchanged
	endif
	return	sFilePathNoIndex
End

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
