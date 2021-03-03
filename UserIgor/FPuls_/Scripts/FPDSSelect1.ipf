//
//  FPDSSelect.ipf	Data section selection and analysis with a listbox

#pragma rtGlobals=1		// Use modern global access method.

//#include "FPConstants"

//static  constant		kMAX_DS	=  60
static  strconstant	lstCOLUMNLABELS	= "A+T;A;T;Pro;Blk;Frm;Sw;PoN;"									// the column titles in the LB text wave
static  constant		kCOLM_AT = 0,   kCOLM_AVG = 1,   kCOLM_TBL = 2,   kCOLM_PR = 3,   kCOLM_BL = 4,   kCOLM_FR = 5,   kCOLM_SW = 6,   kCOLM_PON = 7
static  constant		k_COLORAUTO = 0, kBLUE = 1, kMAGENTA = 2,  kRED = 3,  kGREEN = 4,  kCYAN = 5,  kAPRICOT = 6		// same color order as in wDSColors below  
static  constant		k_COLUMN_TITLE 	= -1						// Igor defined

static constant		kLB_CELLY		= 16						// empirical cell height
static constant		kLB_ADDY		= 21						// additional y pixel for listbox header and margin
static constant		kPN_ADDY		= 30						// additional y pixel for Panel controls above and below listbox

Function		DSDlg( SctCnt )
	// Build the DataSectionsPanel
	variable		SctCnt

	// Possibly kill an old instance of the DataSectionsPanel and also kill the underlying waves
	DoWindow  /K	PnDSct
	KillWaves	  /Z	root:uf:wLBTxt , root:uf:wLBFlags, root:uf:wDSColors 


	// Build the DataSectionsPanel . The y size of the listbox and of the panel  are adjusted to the number of data sections (up to maximum screen size) 
	variable	c, nCols	= ItemsInList( lstCOLUMNLABELS )
	variable	xPos		= 2
//	variable	xSize		= 184							// 184 for column widths 16 + 2 * 8 + 4 * 13 (=84?)
	variable	xSize		= 206							// 206 for column widths 16 + 2 * 8 + 5 * 13 (=97?)
	variable	yPos		= 50
	variable	ySizeMax	= GetIgorAppPixelY() -  kY_MISSING_PIXEL_BOT - kY_MISSING_PIXEL_TOP - 85  // -85 leaves some space for the history window
	variable	ySizeNeed	= SctCnt * kLB_CELLY
	variable	ySize		= min( ySizeNeed, ySizeMax )  
	NewPanel /W=( xPos, yPos, xPos + xSize + 4, yPos + ySize + kLB_ADDY + kPN_ADDY ) /K=1 as "Data sections"
	DoWindow  /C PnDSct


	// Create the 2D LB text wave	( Rows = data sections, Columns = Both, Avg, Tbl )
	make   	/T 	/N = ( SctCnt, nCols )		root:uf:wLBTxt		// the LB text wave
	wave   	/T		wLBTxt		     =	root:uf:wLBTxt

	// Create the 3D LB flag wave. 	Rows x Columns (as above)  x 3  : last index 0 is flags, 1 is fore- or background color, 2 is the remaining color 
	//make   	/B  /O /N = ( SctCnt, nCols, 3 )	root:uf:wLBFlags	// byte wave is sufficient for up to 254 colors 
	make   	/B  /N = ( SctCnt, nCols, 3 )	root:uf:wLBFlags	// byte wave is sufficient for up to 254 colors 
	wave   			wLBFlags		    = 	root:uf:wLBFlags

	// Create color table withs rows and columns exchanged. 3 rows, n columns is easier to read as n columns, 3 rows but must be transposed before Igor can use them.
	// make   	/O /W /U	root:uf:wDSColors  = { { 0, 65535, 0 , 0 , 0, 65535 } , 	{ 0 ,  0, 65535, 0  , 65535, 0 } , 	{ 0, 0, 0, 65535, 65535, 65535 }  } 		// what Igor requires is hard to read : 6 rows , 3 columns : black, red, green, blue, cyan, magenta
	make 	/W /U	root:uf:wDSColors  = { { 0, 0, 0 }, { 0, 0, 65535 }, {40000,0,48000},  { 65535, 0, 0 },   { 0, 50000, 0} ,   { 0, 56000, 56000 }, {65280,59904,48896} }	// order must be same as defined by constants above
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
	wLBTxt[ ][ kCOLM_AT ]	= num2str(p)								// set the initial text in 1 column of the LB
	wLBTxt[ ][ kCOLM_AVG ]	= "A"									// initially empty. Will be filled with 'A' for those DS already averaged
	wLBTxt[ ][ kCOLM_TBL ]	= "T"

	// Fill the 	Pr/Bl/Fr/Sw listbox columns with the protocol/block/frame/sweep numbers and colorise these cells according to their content
	SetPBFSTxt( wLBTxt, wLBFlags )

	// Build the panel controls 
	PopupMenu 	popInstantAnalysis,	win = PnDSct, 	pos = { 0, 4 }, size = { 80, 16 },	title="Analysis", 		proc = popInstantAnalysisProc
	PopupMenu	popInstantAnalysis,	win = PnDSct, 	mode = 3,	popvalue = "delayed", value = #"\"instantaneous;delayed\""

	Button		buAnalyseNow, 		win = PnDSct, 	pos = { 120, 4 },  size = { 66, 20 }, title = "Analyse now", proc = buAnalyseNowProc

	ListBox 		lbDataSections, 	win = PnDSct, 	pos = { 2, 30 },  size = { xSize, ySize + kLB_ADDY },  frame = 2
	ListBox		lbDataSections,		win = PnDSct, 	listWave 	= root:uf:wLBTxt
	ListBox 		lbDataSections, 	win = PnDSct, 	selWave 	= root:uf:wLBFlags,  editStyle = 1
	ListBox	 	lbDataSections, 	win = PnDSct, 	colorWave= root:uf:wDSColors
	ListBox 		lbDataSections, 	win = PnDSct, 	mode = 5//4
	ListBox 		lbDataSections, 	win = PnDSct, 	widths = { 16, 8, 8, 13 }											// ??? too wide
	ListBox 		lbDataSections, 	win = PnDSct, 	proc = lbDataSectionsProc
End

//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function 		popInstantAnalysisProc( sCtrlNm, popNum, popStr ) : PopupMenuControl
	string  	sCtrlNm
	variable 	popNum
	string  	popStr
	if ( popNum == 1 ) 									// analyse immediately
		Button	buAnalyseNow	win = PnDSct, 	disable = 2		// disable the button
	else												// analyse later
		Button	buAnalyseNow	win = PnDSct, 	disable = 0		// enable the button
	endif
End


Function 		buAnalyseNowProc( sCtrlNm ) : ButtonControl
	string  	sCtrlNm
	wave	wLBFlags	= root:uf:wLBFlags
	variable	col, row, nRows	= DimSize( wLBFlags, 0 )
	variable	nColorIndex	= kBLUE
//	for ( col = kCOLM_AVG; col <=  kCOLM_TBL; col += 1 )
	for ( col = 0; col <=  kCOLM_PON; col += 1 )
		for ( row = 0; row <  nRows; row += 1 )
			if ( IsSelected( wLBFlags, row, col ) )
				SetSub(  wLBFlags, row, col, nColorIndex, "backColors" )
				//SetSub(  wLBFlags, row+1, col, nColorIndex+1, "foreColors" )
				//printf "\tbuAnalyseNow() \tRow:%4d / %4d\twLBFlags\t[ %3d ][ %3d ][ 0 ]\t:%2d\twLBFlags\t[ %3d ][ %3d ][ 1 ]\t:%2d\twLBFlags\t[ %3d ][ %3d ][ 2 ]\t:%2d\t    \r", row, nRows, row, col, wLBFlags[ row][col][ 0 ], row, col, wLBFlags[ row][col][ 1 ], row, col, wLBFlags[ row][col][ 2 ]
			endif
		endfor
	endfor
End


Function		lbDataSectionsProc(s) : PopupMenuControl
// Dispatches the various actions to be taken when the user clicks in the LB
	struct	WMListboxAction &s

	wave	wBlk2Sct	= root:uf:cfsr:wBlk2Sct	
	nvar		gRange	= root:uf:cfsr:gRaDispRange
	nvar 		gProt		= root:uf:cfsr:gProt
	nvar 		gBlk		= root:uf:cfsr:gBlk 
	nvar 		gFrm		= root:uf:cfsr:gFrm
	nvar 		gSwp	= root:uf:cfsr:gSwp
	nvar		gProtMx	= root:uf:cfsr:gProtMx
	nvar		gBlkMx	= root:uf:cfsr:gBlkMx
	nvar		gFrmMx	= root:uf:cfsr:gFrmMx
	nvar		gSwpMx	= root:uf:cfsr:gSwpMx

	variable	nColor	= 0
	variable	pr, bl, fr, sw, pon
	variable	row,	col

	wave	wLBFlags	= root:uf:wLBFlags

	nvar	/Z	gPreviousRow 	= root:uf:gPreviousRow
	nvar	/Z	gPreviousCol   	= root:uf:gPreviousCol
	if ( ! nvar_exists( gPreviousRow ) )
		variable	/G			 root:uf:gPreviousRow
		variable	/G			 root:uf:gPreviousCol
		nvar		gPreviousRow = root:uf:gPreviousRow
		nvar		gPreviousCol   =	 root:uf:gPreviousCol
	endif

	// Igor sample code.....
	if ( s.eventCode == 1  &&  s.eventMod & 0x10 )		// mouse down and contextual modifiers?
		PopupContextualMenu "Select All"
		if ( V_Flag ==1 )
			wLBFlags= wLBFlags | 1
		endif
	endif 

	//printf "\t\tLBproc: ctrlName= %s, row= %4d,\tcol= %d, event=\t%s   \t(%d), event2=\t%s\t(%d) \r",s.ctrlName, s.row, s.col, StringFromList(s.eventCode, lstLB_EVENTS), s.eventCode, StringFromList(s.eventCode2, lstLB_EVENTS), s.eventCode2

	// Click in a cell  in column 0  'A+T' 	: Jump to and display the selected  data section 
	if ( s.eventCode == kLBE_CellSelect  &&  s.col == kCOLM_PR )						// allow selection only in column  'A+T'
		if ( Ds2pbfs( s.row, pr, bl, fr, sw, pon ) != cNOTFOUND )
			printf "Ds2pbfs( row:%2d ) \t-> p:%2d  b:%2d  f:%2d  s:%2d  pon:%2d  \r", s.row, pr, bl, fr, sw, pon
			gProt		= pr
			gBlk		= bl
			gFrm		= fr
			gSwp	= sw
			JumpTo()
		else
			printf "Ds2pbfs( row:%2d )   *** NOTFOUND \r", s.row
		endif
	endif

	// Click in a cell  in columns  'Pro' , 'Blk'  ... 'pon' 	: Jump to and display the the selected  prot, block, frame, sweep or PoN
	if ( s.eventCode == kLBE_CellSelect  &&  ( s.col >= kCOLM_PR && s.col <= kCOLM_PON )  )			// allow selection only in columns  'Avg'  and  'Tbl'

		gPreviousCol	= s.col												// store start of selected range
		gPreviousRow	= s.row												// store start of selected range

		Ds2pbfs( s.row, pr, bl, fr, sw, pon ) 
		printf "\t\tLBproc: ctrlName= %s, row= %4d,\tcol= %d, event=\t%s   \tp:%2d\tb:%2d\tf:%2d\ts:%2d\to:%2d\t \r",s.ctrlName, s.row, s.col, StringFromList(s.eventCode, lstLB_EVENTS), pr, bl, fr, sw, pon

		if ( s.col == kCOLM_PR )
			gRange	= cCFS_PRO
			gProt		= pr
			gBlk		= 0
			gFrm		= 0
			gSwp	= 0
			JumpTo()
			for ( bl = 0; bl < CfsBlocks(); bl += 1 )
				for ( fr = 0; fr < CfsFrames( bl ); fr += 1 )
					for ( sw = 0; sw < CfsSweeps( bl ); sw += 1 )
						row	= wBlk2Sct[ pr ][ bl ][ fr ][ sw ]
						Toggle( wLBFlags, row, s.col, kAPRICOT, "backColors"  )
					endfor					 
				endfor					 
			endfor					 
			ResetOtherColumns( wLBFlags, s.col )							// Disallow mixing e.g. blocks with sweeps. Not mandatory, could be allowed although it makes little sense. 
		endif
		if ( s.col == kCOLM_BL )
//			gRange	= cCFS_FRM//cCFS_BLK
			gRange	= cCFS_BLK
			gProt		= pr
			gBlk		= bl
			gFrm		= 0
			gSwp	= 0
			gProtMx	= pr
			gBlkMx	= bl
			gFrmMx	= CfsFrames( bl ) - 1
			gSwpMx	= CfsSweeps( bl ) -1 
			JumpTo()
			for ( fr = 0; fr < CfsFrames( bl ); fr += 1 )
				for ( sw = 0; sw < CfsSweeps( bl ); sw += 1 )
					row	= wBlk2Sct[ pr ][ bl ][ fr ][ sw ]
					Toggle( wLBFlags, row, s.col, kAPRICOT, "backColors"  )
				endfor					 
			endfor					 
			ResetOtherColumns( wLBFlags, s.col )							// Disallow mixing e.g. blocks with sweeps. Not mandatory, could be allowed although it makes little sense. 
		endif
		if ( s.col == kCOLM_FR )
			gRange	= cCFS_FRM
			gProt		= pr
			gBlk		= bl
			gFrm		= fr
			gSwp	= 0
			JumpTo()
			for ( sw = 0; sw < CfsSweeps( bl ); sw += 1 )
				row	= wBlk2Sct[ pr ][ bl ][ fr ][ sw ]
				Toggle( wLBFlags, row, s.col, kAPRICOT, "backColors"  )
			endfor					 
			ResetOtherColumns( wLBFlags, s.col )									// Disallow mixing e.g. blocks with sweeps. Not mandatory, could be allowed although it makes little sense. 
		endif
		if ( s.col == kCOLM_SW )
			gRange	= cCFS_SWP
			gProt		= pr
			gBlk		= bl
			gFrm		= fr
			gSwp	= sw
			JumpTo()
			row	= wBlk2Sct[ pr ][ bl ][ fr ][ sw ]
			Toggle( wLBFlags, row, s.col, kAPRICOT, "backColors"  )
			ResetOtherColumns( wLBFlags, s.col )									// Disallow mixing e.g. blocks with sweeps. Not mandatory, could be allowed although it makes little sense. 
		endif
	endif

	//  CFS_RES = 8  ???

	// Click in a cell  in columns  'Avg' , 'Tbl 	: Toggle the selection state of this cell    and   jump to and display the the selected  prot, block, frame, sweep or PoN
	if ( s.eventCode == kLBE_CellSelect  &&  ( s.col == kCOLM_AVG || s.col == kCOLM_TBL )  )	// allow selection only in columns  'Avg'  and  'Tbl'
		nColor		=      s.col == 1	?  kRED	:  kMAGENTA
		gPreviousCol	= s.col												// store start of selected range
		gPreviousRow	= s.row												// store start of selected range
		Toggle( wLBFlags, s.row, s.col, nColor, "backColors" )
	endif

//	// Shift Click in a cell  in columns  'Avg' , 'Tbl   : Toggle the selection state of a cell range from previously clicked cell up to and including this cell
//	if ( s.eventCode == kLBE_CellSelectShift  &&  ( s.col == kCOLM_AVG || s.col == kCOLM_TBL ) )// allow selection only in columns  'Avg'  and  'Tbl'   BUT POSSIBLY SPANNING COLUMNS
//		nColor	=      s.col == 1	?  kRED	:  kMAGENTA
//		Toggle( wLBFlags, gPreviousRow, gPreviousCol, nColor, "backColors" )			// has already been toggled when storing start of selected range, now revert bcause it is finally set below
//		variable	BegRow 	= min (  gPreviousRow, s.row )
//		variable	EndRow 	= max ( gPreviousRow, s.row )
//		variable	BegCol 	= min (  gPreviousCol,   s.col )
//		variable	EndCol 	= max ( gPreviousCol,   s.col )
//		for ( col = BegCol; col <= Endcol; col += 1 )
//			for ( row = BegRow; row <= EndRow; row += 1 )
//				Toggle( wLBFlags, row, col, nColor, "backColors" )
//	 		endfor
// 		endfor
//	endif

	// Shift Click in a cell  in columns  'Avg' , 'Tbl   : Toggle the selection state of a cell range from previously clicked cell up to and including this cell. Must stay in column.
	if ( s.eventCode == kLBE_CellSelectShift  &&   s.col >= kCOLM_AVG )				
		nColor	= kAPRICOT
		variable	BegRow 	= min (  gPreviousRow, s.row )
		variable	EndRow 	= max ( gPreviousRow, s.row )
		if ( gPreviousCol == s.col )
			Toggle( wLBFlags, gPreviousRow, gPreviousCol, nColor, "backColors" )			// has already been toggled when storing start of selected range, now revert bcause it is finally set below
			for ( row = BegRow; row <= EndRow; row += 1 )
				Toggle( wLBFlags, row, s.col, nColor, "backColors" )
	 		endfor
 		endif
	endif


//	DOES NOT WORK...
//	// Shift Click on the header : Reset the selection state of the complete column  
//	if ( s.eventCode == kLBE_CellSelectShift  &&  s.row == k_COLUMN_TITLE  &&  ( s.col >= kCOLM_AVG && s.col <= kCOLM_PON ) )
//		nColor	= kGREEN
//		EndRow	= DimSize( wLBFlags , 0 )
//		for ( row = 0; row < EndRow; row += 1 )
//			Toggle( wLBFlags, row, s.col,  nColor, "backColors"  )
// 		endfor
//	endif	
	
	// Click on the header : Toggle the selection state of the complete column  
	if ( s.eventCode == kLBE_mousedown  &&  s.row == k_COLUMN_TITLE  &&  ( s.col >= kCOLM_AVG && s.col <= kCOLM_PON ) )
		nColor	= kAPRICOT
		EndRow	= DimSize( wLBFlags , 0 )
		for ( row = 0; row < EndRow; row += 1 )
			Toggle( wLBFlags, row, s.col,  nColor, "backColors"  )
 		endfor
	endif	

	// Double Click on the header : Reset the selection state of the complete column  
	if ( s.eventCode == kLBE_DoubleClick  &&  s.row == k_COLUMN_TITLE  &&  ( s.col >= kCOLM_AVG && s.col <= kCOLM_PON ) )
		nColor	= kAPRICOT
		EndRow	= DimSize( wLBFlags , 0 )
		for ( row = 0; row < EndRow; row += 1 )
			SetSub( wLBFlags, row, s.col,  1, "backColors"  )
 		endfor
	endif	

	
//	// Double Click on the header : Toggle the selection state of the complete column  
//	if ( s.eventCode == kLBE_DoubleClick  &&  s.row == k_COLUMN_TITLE  &&  ( s.col >= kCOLM_AVG && s.col <= kCOLM_PON ) )
//		nColor	= kAPRICOT
//		EndRow	= DimSize( wLBFlags , 0 )
//		for ( row = 0; row < EndRow; row += 1 )
//			Toggle( wLBFlags, row, s.col,  nColor, "backColors"  )
// 		endfor
//	endif	
	
	//  Only Test :  double-clicking on a listbox field changes the foreground color (Flaw: there is a select event after the dblclk which may mask the dblclk...)
	if ( s.eventCode == kLBE_DoubleClick  &&  s.row != k_COLUMN_TITLE  &&  ( s.col == 1 || s.col == 2 )  )	// allow selection only in columns  'Avg'  and  'Tbl'
		nColor	= kGREEN
		Toggle( wLBFlags, s.row, s.col,  nColor, "foreColors"  )
	endif	
	
	return 0			// other return values reserved
End


Function		ResetOtherColumns( wF, ExcludeCol )
	wave	wF
	variable	ExcludeCol
	variable	nColor	= 0				// 0 : Reset
	variable	col, row, nRows = DimSize( wF, 0 )
	for ( col = kCOLM_PR; col <= kCOLM_PON; col += 1 )
		if ( col != ExcludeCol )
			for ( row = 0; row < nRows; row += 1 )
				SetSub( wF, row, col, nColor, "backColors" )
			endfor
		endif
	endfor
End


Function		Toggle( wF, row, col, nColorIndex, sPlaneNm )
// Toggle the main state of any cell between 'selected' and  'unselected' .  This state is stored in the Igor-defined  dimension 2 , index 0 , bit 0x10 of the  'wLBFlags'  wave.
// Further  (sub)states  (e.g. analysed, fitted, averaged) are stored in  the dimension 2 , index 1 (possibly also2) of the 'wLBFlags'  wave . THIS IS THE COLOR INFORMATION !
// So there is a  1 to 1 correspondence between colors and  substates,  a color IS a substate , e.g.  Green=analysed,  Blue=Fitted,   Red=averaged.
// Further refinements possible:  Substates may draw  text in the cells  or may change the  text (=foregrund)  color  .
	wave	wF
	variable	row, col, nColorIndex
	string  	sPlaneNm
	variable	bitval		= 0x10						// 0x10 : checkbox state ,  0x20 : cell is checkbox
	if ( ! waveExists( wF ) )
		printf "Toggle():  wave is missing.\r"
		return 0
	endif
	wF[ row] [ col ][ 0 ] 	= ( wF & ( 0xff - bitval ) ) | ( ~wF & bitval ) // toggle just 1 bit  :   0 -> 1  and  1 -> 0

	// Prevent Igor from displaying the 'selected' state
	variable	bitSelected= 0x01						// 0x01: cell is selected
	wF[ row] [ col ][ 0 ] 	= ( wF & ( 0xff - bitSelected ) )		// turn off bit 0 : Igor will not display cell in 'selected' (=black) state except for a short flash. WE take care of displaying the state of the cell.

	variable	plane	= FindDimLabel( wF, 2, sPlaneNm )

	variable 	value	= ( wF[ row] [ col ][ 0 ] & bitval ) > 0
	wF[ row ][ col ][plane]	= value * nColorIndex
	//printf "Toggle() value: %d      wF[ row:%2d ][ col:%2d ][ flags=0 ]: %2d   \t->wF[row:%2d\t][col:%2d ][ plane:%d ]: %d\t%s\t  \r", value, row, col, wF[row][col][ 0 ] , row, col, plane, wF[row][col][plane], sPlaneNm
End			

Function	IsSelected( wF, row, col )
// 
	wave	wF
	variable	row, col
	variable	bitval		= 0x10						// 0x10 : checkbox state
	if ( ! waveExists( wF ) )
		printf "IsSelected(): wave is missing.\r"
		return 0
	endif
	//print "IsSelected", row, col, wF[ row] [ col ][ 0 ] ,  wF[ row] [ col ][ 0 ] & bitval 
	return	wF[ row] [ col ][ 0 ] & bitval 
End

Function	SetSub( wF, row, col, nColorIndex, sPlaneNm )
// Set color and substate. There is a  1 to 1 correspondence between colors and  substates,  a color IS a substate , e.g.  Green=analysed,  Blue=Fitted,   Red=averaged.
// Further refinements possible:  Substates may draw  text in the cells  or may change the  text (=foregrund color) .
	wave	wF
	variable	row, col, nColorIndex
	string  	sPlaneNm
	variable	bitval		= 0x10						// 0x10 : checkbox state
	if ( ! waveExists( wF ) )
		printf "SetSub(): wave is missing.\r"
		return 0
	endif
	variable	plane	= FindDimLabel( wF, 2, sPlaneNm )
	wF[ row ][ col ][plane]	= nColorIndex
	wF[ row] [ col ][ 0 ]	=  wF & ( 0xff - bitval )  
End			


Function		SetPBFSTxt( wLBTxt, wFlags )
	wave  /T	wLBTxt
	wave  	wFlags
	variable	ds, dsCnt	= DimSize( wLBTxt, 0 )
	variable	pr, bl, fr, sw, pon
	string  	sPlaneNm	= "ForeColors"					// or use  mild colors in conjunction with 'backColors'
	for ( ds = 0; ds < dsCnt; ds += 1 )
		Ds2pbfs( ds, pr, bl, fr, sw, pon )
		wLBTxt[ ds ][ kCOLM_PR ]		= num2str( pr )		// set initial LB text
		SetSub( wFlags, ds, kCOLM_PR, pr, sPlaneNm )		// colorise the LB text
		wLBTxt[ ds ][ kCOLM_BL ]		= num2str( bl )		
		SetSub( wFlags, ds, kCOLM_BL, bl, sPlaneNm )
		wLBTxt[ ds ][ kCOLM_FR ]		= num2str( fr )		// set initial LB text
		SetSub( wFlags, ds, kCOLM_FR, fr, sPlaneNm )
		wLBTxt[ ds ][ kCOLM_SW ]	= num2str( sw )		
		SetSub( wFlags, ds, kCOLM_SW, sw, sPlaneNm )
		wLBTxt[ ds ][ kCOLM_PON ]	= num2str( pon )		
		SetSub( wFlags, ds, kCOLM_PON, pon, sPlaneNm )
	endfor
End

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function	Ds2pbfs( sct, pr, bl, fr, sw, pon )
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

//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
