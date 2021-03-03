//
//  FPDSSelect.ipf	Data section selection and analysis with a listbox

#pragma rtGlobals=1		// Use modern global access method.

constant			kBITSELECTED	= 0x01						// Igor-defined. The bit which controls the selection state of a listbox cell

// If columns are changed then  'xSize'   listbox 'widths'  also have to be adjusted
static  constant		k_COLUMN_TITLE 	= -1							// Igor defined
static  constant		kCOLM_ZERO = 0,   kCOLM_PR = 1,   kCOLM_BL = 2,   kCOLM_FR = 3,   kCOLM_SW = 4,   kCOLM_PON = 5
static  strconstant	lstCOLUMNLABELS	= "LSw;Pro;Blk;Frm;Sw;PoN;"		// the column titles in the LB text wave including and staritng with LinSweep
static  strconstant	lstCOL_SEL_NAMES	= "Prot;Block;Frame;Sweep;PoN;"	// the column names of the selectable columns excluding LinSweep

static constant		kLB_CELLY		= 16							// empirical cell height
static constant		kLB_ADDY		= 21							// additional y pixel for listbox header and margin
static constant		kCLEAR = 0, 	kDRAW  = 1
static constant		kFIRST  = 0, 	kLAST    = 1

static strconstant	lstLB_RANGE = "1 column;all cols;"					// listbox width

static strconstant	ksDISPMODE	= "single;stacked;catenated;"
static constant		kSINGLE = 0, 	kSTACKED  = 1,	kCATENATED = 2

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


Function		DSDlg( SctCnt, nChannels )
	// Build the DataSectionsPanel
	variable		SctCnt, nChannels

	// Possibly kill an old instance of the DataSectionsPanel and also kill the underlying waves
	DoWindow  /K	PnDSct
	KillWaves	  /Z	root:uf:wLBTxt , root:uf:wLBFlags, root:uf:wDSColors 


	// Build the DataSectionsPanel . The y size of the listbox and of the panel  are adjusted to the number of data sections (up to maximum screen size) 
	variable	xPos	= 10, c, nCols	= ItemsInList( lstCOLUMNLABELS )
	
	if ( WinType( "PnDSEvaluation" ) == kPANEL ) 				// Retrieves panel position from Igor	
		GetWindow     $"PnDSEvaluation" , wsize				// Only if the panel exists retrieve panel position from Igor..		
		xPos	= V_right * screenresolution / IGOR_POINTS72 + 5		// ..and place the current panel just adjacent to the right
	endif

	variable	xSize		= 176 							// 176 for column widths 16 	    + 4 * 13 + 14	(=82?)  adjust when columns change
//	variable	xSize		= 184							// 184 for column widths 16 + 2 * 8 + 4 * 13 	(=84?)  adjust when columns change
//	variable	xSize		= 206 							// 206 for column widths 16 + 2 * 8 + 5 * 13		(=97?)  adjust when columns change
	variable	yPos		= 50
	variable	ySizeMax	= GetIgorAppPixelY() -  kY_MISSING_PIXEL_BOT - kY_MISSING_PIXEL_TOP - 85  // -85 leaves some space for the history window
	variable	ySizeNeed	= SctCnt * kLB_CELLY
	variable	ySize		= min( ySizeNeed , ySizeMax ) 
	NewPanel /W=( xPos, yPos, xPos + xSize + 4 , yPos + ySize + kLB_ADDY ) /K=1 as "Data sections"
	DoWindow  /C PnDSct

	// Create the 2D LB text wave	( Rows = data sections, Columns = Both, Avg, Tbl )
	make   	/T 	/N = ( SctCnt, nCols )		root:uf:wLBTxt		// the LB text wave
	wave   	/T		wLBTxt		     =	root:uf:wLBTxt

	// Create the 3D LB flag wave. 	Rows x Columns (as above)  x 3  : last index 0 is flags, 1 is fore- or background color, 2 is the remaining color 
	make   	/B  /N = ( SctCnt, nCols, 3 )	root:uf:wLBFlags	// byte wave is sufficient for up to 254 colors 
	wave   			wLBFlags		    = 	root:uf:wLBFlags

	// Create color table withs rows and columns exchanged. 3 rows, n columns is easier to read as n columns, 3 rows but must be transposed before Igor can use them.
	// make   	/O /W /U	root:uf:wDSColors  = { { 0, 65535, 0 , 0 , 0, 65535 } , 	{ 0 ,  0, 65535, 0  , 65535, 0 } , 	{ 0, 0, 0, 65535, 65535, 65535 }  } 		// what Igor requires is hard to read : 6 rows , 3 columns : black, red, green, blue, cyan, magenta
	make 	/W /U	root:uf:wDSColors  = { {0, 0, 0 }, { 0, 0, 65535 },  { 65535, 0, 0 },  {40000,0,48000}, {44000,44000,44000},  {54000,54000,54000},  { 0, 50000, 0} ,   { 0, 56000, 56000 },  {65280,59904,48896} }	// order must be same as defined by constants above
	wave   wDSColors  =	root:uf:wDSColors
	MatrixTranspose 		  wDSColors				// the same table is used for foreground and background. 	Igor requires  n  rows, 3 columns 
	// mag greenModifyGraph rgb=(52224,0,41728)ModifyGraph rgb=(0,39168,0)

	// Link the  indices  of  Foreground  and  Background  colors  to  their name strings which are later used to access the layer where the color is to be set
	variable	planeFore	= 1
	variable	planeBack	= 2
	SetDimLabel 2, planeBack, $"backColors"	wLBFlags
	SetDimLabel 2, planeFore, 	$"foreColors"	wLBFlags


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

	svar		gsAvgNm		= root:uf:eval:evl:gsAvgNm	
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
//	 When a data unit is selected but before an evaluation is done (or skipped) there is a 6.  apricot  'current' state.
 
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
	//printf "\rlbDataSectionsProc() "  ; print s
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
	if ( s.eventCode == kLBE_MouseUp  &&  !( s.eventMod & SHIFT )  )					// Only mouse clicks  without SHIFT  are interpreted here 
		if ( PrevRowIsValid() )
			nState		= Modifier2State( s.eventMod )							// Convert the modifying key (e.g. 'Ctrl' ,  'Ctrl Alt / Alt Gr' ) to a state (e.g. Avg, Tbl; View/Skip)  
			DSSetAndAnalyse( ksEVAL, wFlags, gPrevRowFi, gPrevRowLa, s.col, pl, nState )	// change color of cells in Listbox and of traces in graph of previous data unit range according to the chosen evaluation e.g. 'Avg' or 'Skip/View'
		endif
		DS2Lims( s.row, s.col, dsFirst, dsLast, dsSize ) 							// computes first and last data section of the data unit (=Prot, Block, Frame, Sweep) we are currently in
		nState		= kST_CUR
		DSSetAndAnalyse( ksEVAL, wFlags, dsFirst, dsLast, s.col, pl, nState )			// cosmetics: add current=offered cell range in apricot
		gPrevRowFi 	= dsFirst											// Store start of selected range. This will be needed for recoloring in the next call when...
		gPrevRowLa	= dsLast											// ..after having viewed the data the user has decided if and how to analyse the data unit
		gPrevColumn   	= s.col
	endif

	// ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' '
	// MOUSE: Shift Click in a cell  in columns  'Avg' , 'Tbl   : Toggle the selection state of a cell range from previously clicked cell up to and including this cell. Must stay in column.
	// Todo : Possibly exclude modifiers so that nothing at all is done when a modifier is pressed. Currently they are allowed and the action which would  be done if no modifier was pressed is executed. 
	if ( s.eventCode == kLBE_MouseUp  &&  ( s.eventMod & SHIFT ) )						// Only mouse clicks while SHIFT is pressed are interpreted here 
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


Function		DSSetAndAnalyse( sFolder, wFlags, dsF, dsL, col, pl, nState )
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
	return	NOTFOUND
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
//		//printf "\t\tDSToggleUnit()(\tnDir:%d\tNew selection is nRowJump:%2d\t  \r", nDirection, nNewSelectedRow
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
//	//printf "DSToggleAnalysis() value: %d      wFlags[ row:%2d ][ col:%2d ][ flags=0 ]: %2d   \t->wFlags[row:%2d\t][col:%2d ][ pl:%d ]: %d\t  \r", value, row, col, wFlags[row][col][ 0 ] , row, col, pl, wFlags[row][col][ pl]
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
	//printf "\t\tDS2Lims(\trow:%3d\tcol:%3d\t ->\tF:%3d\tL:%3d\t(Sz:%4d)\t \r", row, col, dsFi, dsLa, dsSz
End


//=======================================================================================================================
// THE  NEW  DS-EVALUATION PANEL

constant			kACT_VIEW		= 0,	kACT_AVG = 1,  kACT_ANAL = 2
static  strconstant	lstACT_TEXT		= "View;Average;Analysis"
static  strconstant	lstACT_FOLDER	= "root:uf:eval:cbAct"


Function		DSEvaluationPanel()
	string  	sFolder		= ksEVAL
	string  	sPnOptions	= ":dlg:tPnDSEvaluation"						// 040831 must be :dlg: for HelpTopic...???
	string		sPnTitle
	sprintf	sPnTitle, "%s %s", "Eval  " ,  FormatVersion()
	InitPanelDSEvaluation( sFolder, sPnOptions )	
	ConstructOrDisplayPanel(   "PnDSEvaluation", sPnTitle, sFolder, sPnOptions, 0,0 ) 
	EnableSetVar(  "PnDSEvaluation",  "root_uf_cfsr_gsRdDataPath", cNOEDIT )	// read-only, but could also be made to allow file name entry
	EnableSetVar(  "PnDSEvaluation",  "root_uf_cfsr_gCFSSmpInt", cNOEDIT )		// read-only
End

Function		InitPanelDSEvaluation( sFolder, sPnOptions )
	string  	sFolder, sPnOptions
	string		sPanelWvNm = "root:uf:" + sFolder + sPnOptions
	variable	n = -1, nItems = 80
	make /O /T /N=(nItems) $sPanelWvNm
	wave  /T	tPn		=   $sPanelWvNm
	string		sTabControlEntries	= ""						// list with all control information. Separators  are   | ~~~;;;~ | ~~~;;;~ | 
	
//	PopupMenu  pmShowWindow,	win = PnDSct1, 	pos = { xSize + 8, 2*20 },	size = {115,12},	title="Graph  ", bodywidth = 75,	proc = pmShowWindow, 	mode = 3,	popvalue = "0",		value = pmShowWindow_Lst()
//	PopupMenu  pmDisplayMode,	win = PnDSct1, 	pos = { xSize + 8,  6*20 },	size = {115,14},	title="Display", bodywidth = 75,	proc = pmDisplayMode,  	mode = 3,	popvalue="stacked",	value = pmDisplayMode_Lst()

//	n += 1;	tPn[ n ] =	"PN_SEPAR"
//	n += 1;	tPn[ n ] =	"PN_SETVAR;	root:uf:cfsr:gStep;Step  ;  40 ; %3d ;1,999,1;	|	| 	"
//	
//	n += 1;	tPn[ n ] =	"PN_SEPAR"
//	n += 1;	tPn[ n ] =	"PN_BUTTON	;buDispCfsEraseTblAvg  		;Erase t + a;	| PN_BUTTON	;buDispCfsSaveTblAvg  ;save t + a;	| PN_BUTTON	;buDispCfsKeepTblAvg	;tbl+avg >"
//	n += 1;	tPn[ n ] =	"PN_BUTTON	;buDispCfsEraseTbl	    		;Erase Tbl;		| PN_BUTTON	;buDispCfsSaveTbl	    ;save  tbl;	| PN_BUTTON	;buDispCfsKeepTbl		;Table  >"

	n += 1;	tPn[ n ] =	"PN_BUTTON	;buDispCFSSelectFile			;Select file;	| PN_BUTTON	;buDispCFSCurAcqFile;Current acq;	"
	n += 1;	tPn[ n ] =	"PN_BUTTON	;buDispCfsPrevFile			;< Prev file; 	| PN_BUTTON	;buDispCfsNextFile;Next file >;"
	n += 1;	tPn[ n ] =	"PN_SETVAR	;root:uf:cfsr:gsRdDataPath		;;  140;"//140; "
	n += 1;	tPn[ n ] =	"PN_SETVAR	;root:uf:cfsr:gCFSSmpInt		;Sample interval / us  ; 25; %4d; 0,0,0 "
	n += 1;	tPn[ n ] =	"PN_SEPAR"
	n = PnControl( tPn, n,1, ON, "PN_RADIO", ItemsInList( lstLB_RANGE), "", "root:uf:eval:evl:gLBRange",  lstLB_RANGE,   "Range",  "" , kWIDTH_NORMAL, sFolder ) // horizontal radio buttons
	n += 1;	tPn[ n ] =	"PN_SEPAR"
	n += 1;	tPn[ n ] =	"PN_POPUP	;root:uf:eval:evl:gnWndNumber	;Graph; 75	; 1 ;pmShowWindow_Lst;	pmShowWindow"	// !!! The value defined here must be 1 more than the initial 'gnDisplayMode' 	for the listbox correspond to the actual setting.
	n += 1;	tPn[ n ] =	"PN_POPUP	;root:uf:eval:evl:gnDisplayMode	;Display;75; 2 ;pmDisplayMode_Lst;	pmDisplayMode"	// !!! The value defined here must be 1 more than the initial 'gnDisplayMode' 	for the listbox correspond to the actual setting.
	n += 1;	tPn[ n ] =	"PN_POPUP	;root:uf:eval:evl:gnActiveCol	;Active; 75	; 3 ;pmActiveColumn_Lst;	pmActiveColumn"	// !!! The value defined here must be the same as the initial 'gnActiveCol'  for correspondence. SPECIAL case as index 0 is missing!
	n += 1;	tPn[ n ] =	"PN_SEPAR"

	//   TABBED  PANEL 
	sTabControlEntries	= ""
	//sTabControlEntries	+=  "PN_CHKBOXT ~ "	+ num2str( ItemsInList(lstACT_TEXT) ) 	+ "~ Action~" 	+ lstACT_FOLDER 	+ "~" + lstACT_TEXT	+ "|"	// horizontal checkboxes
	sTabControlEntries	+=  "PN_CHKBOXT ~ " 	+ num2str( 	cVERT			) 	+ "~ Action~" 	+ lstACT_FOLDER 	+ "~" + lstACT_TEXT	+ "|"	//  vertical   checkboxes

	n = PnControlTab(	tPn, n, OFF, "tcAct", "kiki", ListOfCfsChans(), sTabControlEntries, sFolder )					// the 2. string is the title which may be empty


	n += 1;	tPn[ n ] =	"PN_SEPAR"
	n += 1;	tPn[ n ] =	"PN_SETVAR	;root:uf:eval:evl:gAvgKeepCnt	;# Averaged     ; 40; %4d; 0,0,0 "
	n += 1;	tPn[ n ] =	"PN_BUTTON	;buEraseAvg	  	  		;Erase Avg;	| PN_BUTTON	;buSaveAvg	 	;save avg;"
	n += 1;	tPn[ n ] =	"PN_SETVAR	;root:uf:eval:evl:gsAvgNm		;;  140;"//140; "
//	n += 1;	tPn[ n ] =	"PN_BUTTON	;buAvgDoSave		;do save;"
	n += 1;	tPn[ n ] =	"PN_CHKBOX	;root:uf:cfsr:gbDispAverage		;Disp average;"
	n += 1;	tPn[ n ] =	"PN_SEPAR"
	n += 1;	tPn[ n ] =	"PN_SETVAR	;root:uf:eval:evl:gEvaluatedCnt	;# Evaluated    ; 40; %4d; 0,0,0 "
	n += 1;	tPn[ n ] =	"PN_SEPAR"
	n += 1;	tPn[ n ] =	"PN_CHKBOX	;root:uf:eval:evl:gbDispUnselect;	Disp unselected;"
	n += 1;	tPn[ n ] =	"PN_SEPAR"
	n += 1;	tPn[ n ] =	"PN_BUTTON	;buResetActiveColumn		;Reset Column"
	n += 1;	tPn[ n ] =	"PN_SEPAR"
	n += 1;	tPn[ n ] =	"PN_SEPAR"
	n += 1;	tPn[ n ] =	"PN_SEPAR"
	n += 1;	tPn[ n ] =	"PN_BUTTON	;buClearWindow			;Clear Window"
// 050217
//	n =	PnSeparator( tPn, n, " " )
//	n = 	PnMultiLineEvalDetailsNew( tPn, n )
//	n =	PnSeparator( tPn, n, " " )
//


//	n += 1;	tPn[ n ] =	"PN_SETSTR	;root:uf:cfsr:gsRdDataFilter ;Filter ; 20 ;  1	|										| PN_BUTTON	;buDispCFSSelectFile	;Select file"	// 'Filter' extends into the empty middle field
//	n += 1;	tPn[ n ] =	"PN_SEPAR"
//	n += 1;	tPn[ n ] =	"PN_BUTTON	;buDispCfsBaseLSetCsr	;base l; 		| PN_BUTTON	;buDispCfsPeakBegSetCsr; PeakB;	| PN_BUTTON	;buDispCfsPeakEndSetCsr ;PeakE;		| PN_BUTTON	;buDispCFSPlus		;+ pkpts;	| PN_BUTTON	;buDispCFSMinus	;- pkpts;	"
//	n += 1;	tPn[ n ] =	"PN_BUTTON	;buDispCfsBaseRSetCsr	;Base r; 		| PN_BUTTON	;buDispCfsMove		;Move; 	| PN_BUTTON	;buDispCfsResults	;Results;			| PN_BUTTON	;buDispCfsInfo		;Info;		| PN_BUTTON	;buDispCfsRescale	;rescale;			"
//	n += 1;	tPn[ n ] =	"PN_SEPAR"
//	n += 1;	tPn[ n ] =	"PN_CHKBOX;	root:uf:"+sFolder+":dlg:gbShowScript;Show/hide script;| PN_BUTTON;	buDisplayStimEvalDlg	;	Stimulus"
//	n = PnControl(	tPn, n,1, ON, 	"PN_RADIO", ItemsInList(lstCFSHEADER), "",	"root:uf:cfsr:gRadCfsHeader",  lstCFSHEADER,   "",  "" , kWIDTH_NORMAL, sFolder ) 	// horizontal radio buttons
//	n += 1;	tPn[ n ] =	"PN_SEPAR"
//	n += 1;	tPn[ n ] =	"PN_BUTTON;	buDispCfsEvalPanel	;Eval Details Pn;	"
//	n += 1;	tPn[ n ] =	"PN_BUTTON;	buSaveEvalConfig	;Save eval config;	| PN_BUTTON;	buLoadEvalConfig		;Load eval config;	"
//	n += 1;	tPn[ n ] =	"PN_BUTTON;	buEvPreferencesDlg	;Preferences;		| PN_BUTTON;	buEvDataUtilitiesDlg		;Data utilities;		"
	redimension   /N=(n+1)	tPn

End 

//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//  THE  ACTION  PROCS

// Action procedure for  TabControl , currently not needed
Function		tcAct( sControlNm, nSelectedTab )	
	string  	sControlNm
	variable	nSelectedTab
	printf "\t\ttcAzt( TabControl   '%s'   SelectedTab:%2d )  \t->\tsSelecting TabControl \r",   sControlNm, nSelectedTab
	return 0
End

Function		root_uf_eval_cbAct( sControlNm, bValue )					// name is derived from  lstACT_FOLDER 
// Sample  action procedure  for 2dimensional   PnControl()  with  CheckBoxes 
// MUST HAVE SAME NAME AS VARIABLE. NAME MUST NOT BE MUCH LONGER !
// Sample : sControlNm  'root_uf_disp_cbAct_Adc1_View'  ,    boolean variable name : 'root:uf:disp:cbAct:Adc1_View'  , 	sTab: 'Adc1'  ,  sAct: 'View'
	string  	sControlNm
	variable	bValue

	 printf "\tProc TabControl CHKBOX  root_uf_eval_cbAct(\tctrlNm: \t%s\tbValue:%d )\r", pd(sControlNm,31), bValue 
	variable	ch, nChans	= ItemsInList( ListOfCfsChans() )
	variable	a, nActions	= ItemsInList( lstACT_TEXT )
	for ( ch = 0; ch < nChans; ch += 1 )
		string  sTab	= StringFromList( ch, ListOfCfsChans() )
		for ( a = 0; a < nActions; a += 1 )
			variable nState	= IsCheckedInTabControlN( sTab, lstACT_FOLDER, lstACT_TEXT, a )
			print sTab, StringFromList( a, lstACT_TEXT ), "      \t-> ", nState
		endfor
	endfor
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


Function	/S	ListOfCfsChans()
	nvar		gChannels		= root:uf:cfsr:gChannels
	variable	ch
	string  	lstChans	= ""
	for ( ch = 0; ch < gChannels; ch += 1 )
		lstChans	= AddListItem( CfsIONm( ch ), lstChans, ";", inf )
	endfor
	return	lstChans
End



Function 		pmDisplayMode( sCtrlNm, popNum, popStr ) : PopupMenuControl
// display  'stacked'  or  'catenated'
	string  	sCtrlNm, popStr
	variable 	popNum
	nvar		gnDisplayMode		= root:uf:eval:evl:gnDisplayMode
	gnDisplayMode	= popNum - 1
	RedrawWindows()
End
Function		pmDisplayMode_Lst(sCtrlNm )
	string		sCtrlNm
	PopupMenu	$sCtrlNm	 value = ListOfModes()
End
Function	/S	ListOfModes()
	return	ksDISPMODE		// e.g. "single;stacked;catenated;"
End


Function 		pmActiveColumn( sCtrlNm, popNum, popStr ) : PopupMenuControl
	string  	sCtrlNm, popStr
	variable 	popNum
	variable	column
	nvar		gnActiveCol	= root:uf:eval:evl:gnActiveCol
	gnActiveCol	= popNum 			// 1 : Prot , 3 : Frm	( starting at 1 as LinSweep has column 0 but cannot be selected)
End
Function		pmActiveColumn_Lst( sControlNm )
	string		sControlNm
	PopupMenu	$sControlNm	 value = ListOfSelectableColumns()
End
Function	/S	ListOfSelectableColumns()
	return	lstCOL_SEL_NAMES			// e.g. "Prot;Block;Frame;Sweep;PoN;"  // the column names of the selectable columns excluding LinSweep which has index 0
End

Function 		root_uf_eval_evl_gbDispUnselect( sCtrlNm, bValue ) : CheckboxControl
// display or hide unselected traces (=data units)
	string  	sCtrlNm
	variable 	bValue
	nvar		gbDispUnselect	= root:uf:eval:evl:gbDispUnselect
	RedrawWindows()
End


Function		buEraseAvg( sCtrlNm ) : ButtonControl
	string		sCtrlNm
	print 		sCtrlNm
	DSEraseAverages()
End

Function		buSaveAvg( sCtrlNm ) : ButtonControl
	string		sCtrlNm
	DSSaveAverage()
End


Function		root_uf_eval_evl_gsAvgNm( ctrlName, varNum, varStr, varName ) : SetVariableControl
	string		ctrlName, varStr, varName
	variable	varNum
	svar		gsAvgNm	= root:uf:eval:evl:gsAvgNm						// If the user entered a file name including the index, then strip the index and..
	variable	nPathParts= ItemsInList( varStr, ":" )
	string  	sDriveDir	= RemoveEnding( RemoveListItem( nPathParts-1, varStr, ":" ), ":" )
	if ( ! FPDirectoryExists( sDriveDir ) )
		PossiblyCreatePath( sDriveDir )
	endif
	gsAvgNm	= ConstructNextResultFileNmA( varStr, ksAVGEXT )			// ..search the next free avg file index and display it in the SetVariable input field
	//printf "%s   %s   %s  ->  %s \r", ctrlName, varStr, varName, gsAvgNm
End


Function 		root_uf_cfsr_gbDispAverage( sCtrlNm, bValue ) : CheckboxControl
	string  	sCtrlNm
	variable 	bValue
	nvar		gbDispAverage	= root:uf:cfsr:gbDispAverage

	DSDisplayAverage()
End




Function 		buResetActiveColumn( sCtrlNm ) : ButtonControl
// The correspondence between traces in listbox / on screen / analysed  must be maintained. 
	string  	sCtrlNm
	print 		sCtrlNm
	nvar		col	= root:uf:eval:evl:gnActiveCol
	ResetColumn( col )
//	RedrawWindows()
End

Function 		buClearWindow( sCtrlNm ) : ButtonControl
// Only for testing.  Normally traces are cleared  ONLY  by  resetting them in the listbox as only then the correspondence between traces in listbox / on screen / analysed  is maintained. 
	string  	sCtrlNm
	ClearWindows()
End


//Function 		buRedrawWindows( sCtrlNm ) : ButtonControl
//	string  	sCtrlNm
//	RedrawWindows()
//End

//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


Function		RemoveColumnState( column, nState )
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




variable	ch	= 0
	string   sIOName	= CfsIONm( ch )
	string   wDrawDataNm= sIOName + "_" + num2str( dsFirst ) + "_" + num2str( dsSize ) // make a UNIQUE name for each trace segment
	string   sWNm		= EvalWndNm( ch )
	wave   wDSColors  =	root:uf:wDSColors

	if ( WinType( sWNm ) == kGRAPH ) 									// As the user may have closed a window, perhaps to remove an empty channel, ...
																			// ..we do not automatically reopen the window. To revive the channel the file must be reloaded. 
		string	sTNL	= TraceNameList( sWNm, ";", 1 )
		if ( WhichListItem( wDrawDataNm, sTNL, ";" )  != cNOTFOUND )			// only if wave is not in graph append the wave to the graph
			ModifyGraph 	  /W=$sWNm  rgb( $wDrawDataNm ) = ( wDSColors[ nRemovedState ][ 0 ], wDSColors[ nRemovedState ][ 1 ], wDSColors[ nRemovedState ][ 2 ] )
		endif
	endif



		printf "\t\tRemoveColumnState( column:%d, nState:%d ) \tdsFirst:%3d..%3d \tOldState:%2d\t->\tRemovedState:%2d \t \r",  column, nState, dsFirst, dsLast, nOldState, nRemovedState
		DSSet( wFlags, dsFirst, dsLast, column, pl, nRemovedState )
		row += dsSize
	while ( dsLast < dsLastOfExp ) 		// todo : truncated
	SetPrevRowInvalid() 
End


Function		ResetColumn( column )
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
	printf "\t\tRedrawWindows()     only displaying....\r"
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
	//print  "\t\tDebug1 : \t\t\tGraphs 'Eval..':", WinList( ksEVAL_WNM + "*", ";" , "WIN:1" ) , "all windows 'Eval..' except Graphs (should be none): ", WinList( ksEVAL_WNM + "*", ";" , "WIN:214" )

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
	nvar		gAvgKeepCnt	= root:uf:eval:evl:gavgKeepCnt		// 
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
		//printf "\t\tCFSDisplayAllChanInit()\tLeft:%4d\tPnWidth:%4d\t \r", Left, V_right
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
//	wave	wCurRegion	= root:uf:eval:evl:wCurRegion
//	wave	wMagn		= root:uf:eval:evl:wMagn
//	wave	wMnMx		= root:uf:eval:evl:wMnMx
//	variable	returnVal		= 0
	variable	ch 			= 123//CfsWndNm2Ch( s.winName )
	variable	xaxval		= AxisValFromPixel( s.winName, "bottom", s.mouseLoc.h  )
	variable	yaxval		= AxisValFromPixel( s.winName, "left", s.mouseLoc.v  )
	string  	sKey			= num2char( s.keycode )
//	variable 	isClick		= ( s.eventCode == kWHK_mouseup ) + ( s.eventCode == kWHK_mousedown )	// a click is either a MouseUp or a MouseDown

	if ( s.eventCode	!= kWHK_mousemoved )
		//print s
//		printf "\t\t\tfDSGraphHook()\t\tEvntCode:%2d\t%s\tmod:%2d\tch:%d\t'%s'\t'%s' =%3d\tX:%4d\t%7.3lf\tY:%4d\t%7.3lf\t \r ", s.eventCode, pd( StringFromList( s.eventCode, lstWINHOOKCODES ), 8 ), s.eventMod, ch, s.winName,  sKey, s.keycode, s.mouseLoc.h, xaxval, s.mouseLoc.v, yaxval
	endif
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
//	//printf "\tCfsIONm( ch :%d ) : sIOName:'%s' \r", ch, sIOName
//	return	sIOName
//End



Function		DSDisplayAllChan( sFolder, wFlags, dsFirst, dsLast, col, pl, nState )	
//, ch, nChannels, wData, nCurSwp, bSupImp, sWNm, sIOName )
	string  	sFolder
	wave	wFlags	
	variable	dsFirst, dsLast, col, pl, nState

	wave	wDSColors		= root:uf:wDSColors
	nvar		gChannels			= root:uf:cfsr:gChannels
	nvar		gbDispUnselect		= $"root:uf:eval:evl:gbDispUnselect"
	nvar		gnDisplayMode		= $"root:uf:eval:evl:gnDisplayMode"
//	nvar		gbDisplayAllPoints	= $"root:uf:cfsr:gbDisplayAllPoints"
//	nvar		gDataSections		= root:uf:cfsr:gDataSections
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
	
			ExtractionParams( ch, row, col, nCurSwp, dsLa, nSize, nDataPts, nDrawPts, nOfsPts, step, wDrawDataNm, wFoDrawDataNm )  
			wave   /Z	wDrawData	=	$wFoDrawDataNm

			// DISPLAYING.......
			sWNm	= EvalWndNm( ch )
			sTxt		= "skip uns"
			if ( nState != 0   &&   ( nState != kST_SKIP  ||  gbDispUnselect == TRUE )  )

				if ( !waveExists( wDrawData )   ||  numpnts( wDrawData ) != nDrawPts )		// user may have deleted wave or  changed gbDisplayAllPoints
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
					sTNL	= TraceNameList( sWNm, ";", 1 )
					if ( WhichListItem( wDrawDataNm, sTNL, ";" )  == cNOTFOUND )			// only if wave is not in graph append the wave to the graph
						AppendToGraph  /W=$sWNm 	wDrawData					// wDrawData does contain folder ,  wDrawDataNm does NOT contain folder.
					endif
					ModifyGraph 	  /W=$sWNm  rgb( $wDrawDataNm ) = ( wDSColors[ nState ][ 0 ], wDSColors[ nState ][ 1 ], wDSColors[ nState ][ 2 ] )
	
					if ( gnDisplayMode == kSTACKED )
						StartTime	= 0											// Mode Stacked=Superimposed :	start all sweeps at 0
					elseif ( gnDisplayMode == kSINGLE )
						StartTime	= nOfsPts * nSmpInt / cXSCALE						// Mode Single Sweep :			start each sweep at its proper time
					elseif ( gnDisplayMode == kCATENATED )
						StartTime	= nOfsPts * nSmpInt / cXSCALE						// Mode catenated :				start each sweep at its proper time
					endif
				 	EndTime	= StartTime + nDrawPts * step * nSmpInt / cXSCALE
	
					// printf "\t\tDSDisplayAllChan(a) stp:%2d \tdltaX:%.4lf\tStartTime:%6.4lf \tEndTime:%6.4lf \tSmpInt:%g\t%s\tgraph has now %d traces  \r", step, deltaX( wDrawData ), StartTime, EndTime, nSmpInt, wDrawDataNm, ItemsInList( sTNL )
					SetScale /I X, StartTime , EndTime, cXUNIT, wDrawData
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
						if ( WhichListItem( wDrawDataNm, sTNL, ";" )  != cNOTFOUND )			// only if wave is in graph (the user may have removed it 'DispUnselected' hides it)...
							RemoveFromGraph   /W=$sWNm  $wDrawDataNm				// this name does not contain the folder 
							KillWaves	$wFoDrawDataNm
						endif
						sTxt = "kill     "
					endif					
				endif
			endif					// state


			variable	nPrevState	= State( wFlags, row,  col, FindDimLabel( wFlags, 2, "BackColors" ) )
			printf "\t\tDSDisplayAllChan( co:%d\tro:%2d\tsF:%2d\tsL:%2d\tsz:%2d\tOst:%2d\tst:%2d\t%s\t%s\tWNm:%s  c:%d\tOpts:%6d\tdapts:%5d\tdrpts:%5d\tstp:%4d\twv:\t%s\t%s\t \r", col, row, nCurSwp, dsLa, nSize, nPrevState, nState, StringFromList(nState, lstSTACOL), sTxt, sWNm, ch, nOfsPts, nDataPts, nDrawPts, step, pd(wDrawDataNm,10), pd(wFoDrawDataNm,19)

			// ANALYSING.......
			// Analyse( wData, ch, nChannels, nOfsPts, nDataPts, nSmpInt, gDataSections )	// the xScale is set  in Analyse()
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

Function		ExtractionParams( ch, row, col, nCurSwp, dsLa, nSize, nDataPts, nDrawPts, nOfsPts, step, wDrawDataNm, wFoDrawDataNm )  
// when row and column of the listbox are given, all parameters relevant for data extraction from the big original data wave are computed
	variable	ch, row, col
	variable	&nCurSwp, &dsLa, &nSize				// references
	variable	&nDataPts							// reference : number of original data points, must be included inavg but may be too many for drawing
	variable	&nDrawPts						// reference : number of decimated points to be displayed in graph 
	variable	&nOfsPts, &step						// references
	string  	&wDrawDataNm, &wFoDrawDataNm 		// references
	nvar		gOfs				= root:uf:cfsr:gOfs 
	nvar		gbDisplayAllPoints	= $"root:uf:cfsr:gbDisplayAllPoints"
	
	DS2Lims( row, col, nCurSwp, dsLa, nSize ) 						// computes first and last data section of the current data unit e.g.  Frame or Block

	nOfsPts	= DSBegin( nCurSwp ) + gOfs * DSPoints( nCurSwp )	
	nDataPts	= DSBegin( nCurSwp  + nSize ) - DSBegin( nCurSwp ) 
		
	if ( gbDisplayAllPoints )	
		nDrawPts	= nDataPts										// WITHOUT DECIMATION: displaying 2MB takes about 10 s 
		step		= 1
	else	
		nDrawPts	= min( cDRAWPTS, nDataPts )							// WITH DECIMATION: 2MB stepped down to 500 pts: display takes about  3s (display alone is faster than that, there are other time eaters...)
		step		= trunc( max( nDataPts / nDrawPts, 1 ) )
	endif		

	string   sIOName	= CfsIONm( ch )
	wDrawDataNm		= sIOName + "_" + num2str( nCurSwp ) + "_" + num2str( nSize ) // make a UNIQUE name for each trace segment
	wFoDrawDataNm	= "root:uf:cfsr" + ksF_SEP + wDrawDataNm
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
	nvar		gAvgKeepCnt	= root:uf:eval:evl:gAvgKeepCnt		// 
	string		sAvgWvNm	= AvgWvNm( ch )
	string		sFoAvgWvNm	= FoAvgWvNm( ch )
	// Update and display the average wave
	wave  /Z	wAvg = $sFoAvgWvNm			
	//printf "\t\t\tDSAddOrRemoveAvg\t%s\tch:%d\t%s\tnAvgd:%3d\tPts:%4d\tst:%2d\t%s\tdapts:%6d\t \r", pd(StringFromList( bAddOrRemove, lstREM_ADD),6), ch, sAvgWvNm, AvgCnt(), numPnts( wData ), nState, "              ", nDataPts 
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
	nvar		gbDispAverage	= root:uf:cfsr:gbDispAverage
	string  	sTNL, sTxt	= "no  wave "
	if ( waveExists ( wAvg ) )										// the user may have deleted the wave 
		if ( WinType( sWNm ) == kGRAPH )							// the user may have killed the graph window
			sTNL	= TraceNameList( sWNm, ";", 1 )				// the user may have removed the trace from the graph 
			if ( WhichListItem( sAvgNm, sTNL, ";" )  == cNOTFOUND )		// only if   wave is not in graph append average wave. 
				AppendToGraph  /W=$sWNm 	wAvg				// wAvg does contain folder ,  sAvgNm does NOT contain folder.
			endif
			if ( gbDispAverage )
				ModifyGraph 	  /W=$sWNm  rgb( $sAvgNm ) = ( 43000, 33000, 0 ) 				// brown
				sTxt	= "Show avg"
			else
				ModifyGraph 	  /W=$sWNm  rgb( $sAvgNm ) = ( cBGCOLOR,cBGCOLOR,cBGCOLOR)	// background color = invisible 
				sTxt	= "Hide  avg"
			endif
		//printf "\t\t\tDSDisplayAverage( \tch:%d ) \t%s\t%s\t(exists) in W\t%s\t(exists)\tnAvgd:%3d\tPts:%4d\t \r", ch, sTxt, sAvgNm, sWNm, AvgCnt(), numPnts( wAvg)
		endif
	endif
End


static  Function	DSEraseAverages()
// Remove all  'average-marked' (usually red or magenta) data units from the data selection listbox  and erase the average wave for all channels.
// It would be syntactically cleaner to call  'DSSetAndAnalyse()'  repeatedly for each data unit but as the repeated subtraction and display of the average wave..
// ..would be too time-consuming, here a shortcut is made: the listbox is cleared separately from the average wave which is much faster..
	nvar		gAvgKeepCnt	= root:uf:eval:evl:gavgKeepCnt			// 
	nvar		gChans		= root:uf:cfsr:gChannels						
	variable	ch,  col
	//EraseAvgFileNames()										// a new average file will be opened when the next averages is to be added

	for ( col = kCOLM_PR; col <= kCOLM_PON; col += 1 )
		RemoveColumnState( col, kST_AVG )
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
	nvar		gAvgKeepCnt	= root:uf:eval:evl:gAvgKeepCnt			// 
	svar		gsAvgNm		= root:uf:eval:evl:gsAvgNm	
	string  	sFilePath		= ""
	variable	ch
	for ( ch = 0; ch < gChannels; ch += 1 ) 
		wave  /Z	wAvg	= $FoAvgWvNm( ch )
		if ( ! waveExists ( wAvg ) )											// trace may not (yet) exist or the user may have deleted it
			Alert( cLESSIMPORTANT, "No averaged traces." )
			printf "\tNo averaged traces."
		else
			sFilePath		= gsAvgNm + ChannelSpecifier( ch ) + "." + ksAVGEXT	
			waveStats	/Q wAvg
			printf "  Ch:%d   %s\t#Avg:%2d\tAvg:\t%g\tPts:\t%g\t", ch, sFilePath, gAvgKeepCnt, mean( wAvg ), numPnts( wAvg )
			DSWriteAverage( ch, wAvg, sFilePath )							// Update  ( or create )  the average  file  by writing the  average wave data
		endif
	endfor
	gsAvgNm	= ConstructNextResultFileNmA( gsAvgNm, ksAVGEXT )		// search next free avg file and display it in SetVariable input field
	//printf "\tDSSaveAverage() searched and displays next free file where the next AVG data will be written :\t%s  \r", gsAvgNm
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
//	//printf  "\t\t\tAddToAvg()  will add header writing into '%s'   :  %s", sFilePath, sLine	// sLine includes CR 
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
//		//printf  "\t\t\tAddToAvg( ch:%d )  will add average (pts:%d, dltax:%g)  writing into '%s'   :  %s", ch, pts, dltax, sFilePath, sLine
//	endfor		
//End

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Common file name management for result (=average and table) functions
//  the idea is to use as few globals as possible and to hide as much of the internals to the calling functions (like 'AddToAverage() '  or  'AddToTable() ' )

static  Function	/S	ConstructNextResultFileNmA( sCfsPath, sExt )
// Check if  ANY of the channels has already a result file with this name, if yes skip this name for ALL channels (just to avoid confusion, theoretically it could be used for other channels)
// Flaw  / limit  : channels 0-9  and  36 indices
	string		sCfsPath, sExt
	variable	NamingMode	= cDIGITLETTER							// 2 naming modes are allowed.   cDIGITLETTER is prefered to avoid confusion with the already used mode cTWOLETTER (used for Cfs file naming) 
	string		sFilePath, sFilePathShort 

	if ( ItemsInList( sCfsPath, "." ) == 2 ) 									// or check if there is an extension 'dat'								
		sFilePathShort	= StripExtensionAndDot( sCfsPath )					// Has dot : is the original  CFS.dat filepath. Convert to average file name by removing the dot and the 1..3 letters...
	else
		sFilePathShort	= RemoveIndexFromFileNm( sCfsPath )				// Has no dot : is an average filepath containing the index of the average but no channnel and no file extension
	endif

	//printf "\r\t\tConstructNextResultFileNmA(1 \t%s\t ) \tstripping to \t\t%s \r",  pd(sCfsPath,23), sFilePathShort
	variable	ch, n = 0, bFileNmFree
	do
		for ( ch = 0; ch <= 9; ch += 1 )									// !!!! limited to channels 0 to 9
			sFilePath	= BuildFileNm( sFilePathShort, ch, n, sExt, NamingMode )	// ..there can be multiple table files for each cfs file so we append a postfix
			if ( FileExists( sFilePath ) )
				bFileNmFree = FALSE
				//printf "\t\tConstructNextResultFileNmA(2 \t%s\t  )\talready used    \t%s \r",  pd(sCfsPath,23), sFilePath
				break
			endif	
			bFileNmFree = TRUE
		endfor
		n += 1													// try the next auto-built file name
	while ( bFileNmFree == FALSE )
		
	//printf "\r\t\tConstructNextResultFileNmA( '%s', '%s' )  returns %s \r",  sCfsPath, sExt, sFilePath
	string  	sFilePathIdx	= RemoveChanFromFileNm( StripExtensionAndDot( sFilePath ) )	// !!!  xxx_7_ch1.avg  ->  xxx_7
	//printf "\t\tConstructNextResultFileNmA(3 \t%s\t ) \treturns next free\t%s \r",  pd(sCfsPath,23), sFilePathIdx

	return	sFilePathIdx
End

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//  Auto-building  filenames  e.g.  for  Average files
//  Limitation:  there is only 1 character reserved for indexing so there are at most 36 files 

static strconstant	ksCHSEP	= "_ch"
static strconstant	ksIDXSEP	= "#"

static Function   /S	BuildFileNm( sCfsFileBase, ch, n, sExt, NamingMode )
// builds  result file name (e.g. average, table) when  path, file and dot (but no extension)  of CFS data  is given (and channel and index) 
// 2 naming modes are allowed.  cDIGITLETTER is prefered to avoid confusion with the already used mode cTWOLETTER (used for Cfs file naming) 
// e.g.  Cfsdata.dat, ch:1, n:6 -> Cfsdata_1f.avg  or  Cfsdata_1f.fit
	string		sCfsFileBase, sExt
	variable	ch, n, NamingMode
	string		sIndexString	= SelectString( NamingMode == cDIGITLETTER,  IdxToTwoLetters( n ),  IdxToDigitLetter( n ) ) 
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
// !!! Assumes that the actual index is just ONE character (  NamingMode = cDIGITLETTER  -> index = IdxToDigitLetter()    )
	string  	sFilePathWithIndex
	variable	len	= strlen( sFilePathWithIndex )
	string  	sFilePathNoIndex
	if ( cmpstr( sFilePathWithIndex[ len-2, len-2 ], ksIDXSEP ) == 0 )							// only if there is an index at the end...
	  	sFilePathNoIndex	= RemoveEnding( RemoveEnding( sFilePathWithIndex ), ksIDXSEP )	//..we remove it
	else
	  	sFilePathNoIndex	= sFilePathWithIndex										// if no index is recognised the path is returened unchanged
	endif
	return	sFilePathNoIndex
End

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
