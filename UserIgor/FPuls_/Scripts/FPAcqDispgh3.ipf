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
// The acq window panel is read : which Traces(Adc,PoN..) are to be shown in which range (Frame, Sweep, Primary,Result) and in which mode (current, many=superimposed).
// These settings are combined in a 2 dimensional structure TWA  (TraceWindowArrangement) which contains the complete information how the traces display should look like.
// DURING ACQUISITION
// The display routine receives only  the region on screen where to draw and which data are valid. The latter is encoded in the frame and  the sweep number of the data .
// Positive sweep numbers means the valid display range is one sweep, whereas a sweep number -1 means the data range that can be displayed is a frame.
//  From frame and sweep number the display routine itself computes data offset and data points to be drawn. 
//  The  TWA  containing the users prefered display settings is broken and trace, mode and range are extracted  and  compared against the currently valid data range,  if appropriate then data are drawn.

// History:
// Major revision 0605-0606

#pragma rtGlobals=1							// Use modern global access method.

constant			kWNDDIVIDER			= 75		// 15..100 : x position of a window separator if graph display area is to be divided in two columns
static constant		cLFT = 0,    cRIG = 1,cTOP = 2,   cBOT = 3,    cWNDLASTENTRY = 4	// entries in wWLoc

static strconstant 	sDISP_CONFIG_EXT		= "dcf"
static strconstant 	ksMORA_PTSEP		= "_"		// separates TraceModeRange from starting point in trace names, e.g. Adc0SM_0 (blank is not allowed)

static constant		kbAUTOPOS = 0,  kbMYPOS = 1   

Function		CreateGlobalsInFolder_Disp()
// creates all folder-specific variables. To be used once from CreateGlobals() as the current data folder is changed and not restored
	NewDataFolder  /O  /S root:uf:disp				// analysis : make a new data folder and use as CDF,  clear everything
	variable	/g	gR1x = 0, gR1y = 0, gR2x = 0, gR2y = 0	

	variable	/G	gResultXShift		= 0		// the RESULT traces must be shifted so much to, the left so that they effectively start at 0

// 060601 here new
	ConstructYAxis()

	if ( ! kbIS_RELEASE )
	endif
End


static constant		kMAX_ACDIS_WNDS	= 4		// !!! number of Acq Display windows : Also adjust the number of listbox columns   ->  see  'ListBox  lbAcDis,  win = ksLB_ACDIS,  widths  = xxxxx' 

static strconstant	ksLB_ACDIS			= "LbAcqDisplay"

static strconstant	ksCURVSEP			= "|"				


//=====================================================================================================================================
//   ACQUISITION  DISPLAY  -  USER INTERFACE WITH LISTBOX

Function		fAcqDisplay( s )
// Displays and hides the AcqDisplay selection listbox panel
	struct	WMButtonAction	&s
	nvar		bVisib	= $ReplaceString( "_", s.ctrlname, ":" )		// the underlying button variable name is derived from the control name
	printf "\t\t%s(s)\t\t\tchecked:%d\t \r",  pd(s.CtrlName,26), bVisib
	if (  bVisib ) 
		LBAcDisUpdate()									// Bebuild the listbox completely as in meantime while the listbox perhaps was invisible e.g the number of channels may have changed
	else
		LBAcDisHide()
	endif
End

//Function		fOAClearResSel( s )
//	struct	WMButtonAction	&s
//	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
//	printf "\t\t%s(s)\t\t%s\t%d\t \r",  sProcNm, pd(s.CtrlName,26), mod( DateTime,10000)
//	string  	sFolders		= "acq:pul"
//	ClearLBAcDis()
//	// Reset the quasi-global string 	'lstOlaRes' which contains then information which OLA data are to be plotted in which windows. In this special simple context (=Reset the entire Listbox) simple code like '  lstOlaRes=""  '  would also be sufficient.
//	string  	sWin			= ksLB_ACDIS
//	string  	sCtrlName		= "lbAcDis"
//	string  	lstOlaRes		= ExtractLBSelectedWindows( sFolders, sWin, sCtrlName )
//	ListBox 	  $sCtrlname,    win = $sWin, 	userdata( lstOlaRes ) = lstOlaRes
//End
Function		ClearLBAcDis( sFolders )
	string  	sFolders
	wave	wFlags		= $"root:uf:" + sFolders + ":wAcDisFlags"
	LBResSelClear( wFlags )
End

//=======================================================================================================================================================
// THE   ACQUISITION  DISPLAY  LISTBOX  PANEL			

static constant	kLBACDIS_COLWID_TYP		= 62		// OLA Listbox column width for Mode/Range	 column  (in points)
static constant	kLBACDIS_COLWID_WND	= 24		// OLA Listbox column width for    Window	 column  (in points)	(W0,W1 needs 24,   A0,A1 needs 20,  a,b,c needs 12,   A,B,C needs 14)
static constant	kLBACDIS_Y				= 1		// 1 = top most y position

Function		LBAcDisUpdate()
// Build the huge  'Acquisition Display'  listbox allowing the user to select which channels and which data ranges (sweeps,frames) and modes (current, many) are to be displayed in which windows
	string  	sFolders		= "acq:pul"
	nvar		bVisib		= $"root:uf:acq:pul:buAcDisplay0000"				// The ON/OFF state ot the 'Acq Display' button
	string  	sWin			= ksLB_ACDIS

	// 1. Construct the global string  'lstAllMora'  which contains all display modes and ranges e.g.  'Sweeps Current..... Result Many'  and the channel suffix
	// 	This string determines the entries and their order as displayed in the listbox
	string  	lstAllMora		=  ListAllMora() 							// Sweeps C_0;Sweeps M_0;Frames C_0;.........Result M_2;    the index is the channel//


	// 2. Get the the text for the cells by breaking the global string  'lstAllMora'  which contains all display modes and ranges e.g.  'Sweeps Current..... Result Many'  by truncating the channel suffix
	variable	len, n, nItems	= ItemsInList( lstAllMora )	
	 printf "\t\t\tLBAcDisUpdate(a)\tlstAllMora has items:%3d <- \t '%s .... %s' \r", nItems, lstAllMoRa[0,80] , lstAllMoRa[ strlen( lstAllMoRa ) - 80, inf ]
	string 	sColTitle, lstColTitles	= ""									// e.g. 'Dac0~Adc3~PoN1~'
	string  	lstColItems		= ""
//	string  	lstCol2ChRg	= ""										// e.g. '1,0;0,2;'
//	string		lstCurves		= ""
	variable	nExtractCh, ch = -1
	string 	sOneItemIdx, sOneItem
	for ( n = 0; n < nItems; n += 1 )
		sOneItemIdx	= StringFromList( n, lstAllMoRa )						// e.g. 'Frames C_0'
		len			= strlen( sOneItemIdx )
		sOneItem		= sOneItemIdx[ 0, len-3 ] 							// strip 1 indices + separator '_'  e.g. 'Frames C_0'  ->  'Frames'
		nExtractCh	= str2num( sOneItemIdx[ len-1, len-1 ] )					// !!! Assumption : MoRa naming convention
		if ( ch != nExtractCh )											// Start new channel
			ch 		= nExtractCh
			//sprintf sColTitle, "Ch%2d ", ch								// Assumption: Print results column title  e.g. 'Ch 0~Ch 2~'
			sprintf sColTitle, "%s", StringFromList( ch, LstChAcq(), ksSEP_TAB )	// Assumption: Print results column title  e.g. 'Adc1'  or  'Adc3'
			lstColTitles	     =  AddListItem( sColTitle,  lstColTitles,   ksCOL_SEP, inf )	// e.g. 'Adc1~Adc3~'
//			lstCol2ChRg += SetChRg( ch, rg )							// e.g.  '1,0;0,2;'
			lstColItems	   += ksCOL_SEP
		endif
		lstColItems		+= sOneItem + ";"
	endfor
	lstColItems	= lstColItems[ 1, inf ] + ksCOL_SEP							// Remove erroneous leading separator '~'  ( and add one at the end )
//	lstColItems	= lstColItems + ksCOL_SEP								// Add separator '~'  at the end 
//
	// 3. Get the maximum number of items of any column
//	variable	c, nCols	= ItemsInList( lstColItems, ksCOL_SEP )				// or 	ItemsInList( lstColTitles, ksCOL_SEP )
	variable	r, c, nCols	= ItemsInList( LstChAcq(), ksSEP_TAB )
	variable	nRows	= nItems / nCols
	string  	lstItemsInColumn
//	for ( c = 0; c < nCols; c += 1 )
//		lstItemsInColumn  = StringFromList( c, lstColItems, ksCOL_SEP )	
//		nRows		  = max( ItemsInList( lstItemsInColumn ), nRows )
//	endfor
	 printf "\t\t\tLBAcDisUpdate(b)\tlstAllMora has items:%3d -> rows:%3d  cols:%2d\tColT: '%s'\tColItems: '%s...' \r", nItems, nRows, nCols, lstColTitles, lstColItems[0, 100]


	// 4. Compute panel size . The y size of the listbox and of the panel  are adjusted to the number of listbox rows (up to maximum screen size) 
	variable	nSubCols	= kMAX_ACDIS_WNDS
	variable	xSize		= nCols * ( kLBACDIS_COLWID_TYP + nSubCols * kLBACDIS_COLWID_WND )	+ 30 	 
	variable	ySizeMax	= GetIgorAppPixelY() -  kMAGIC_Y_MISSING_PIXEL	// Here we could subtract some Y pixel if we were to leave a bottom region not covered by a larges listbox.
	variable	ySizeNeed	= nRows * kLB_CELLY + kLB_ADDY				// We build a panel which will fit entirely on screen, even if not all listbox line fit into the panel...
	variable	ySize		= min( ySizeNeed , ySizeMax ) 					// ...as in this case Igor will automatically supply a listbox scroll bar.
			ySize		=  trunc( ( ySize -  kLB_ADDY ) / kLB_CELLY ) * kLB_CELLY + kLB_ADDY	// To avoid partial listbox lines shrink the panel in Y so that only full-height lines are displayed
	
	// 5. Draw  panel and listbox
	if ( bVisib )													// Draw the SelectResultsPanel and construct or redimension the underlying waves  ONLY IF  the  'Select Results' checkbox  is  ON

		if ( WinType( sWin ) != kPANEL )								// Draw the SelectResultsPanel and construct the underlying waves  ONLY IF  the panel does not yet exist
			// Define initial panel position.
			NewPanel1( sWin, kRIGHT1, -200, xSize, kLBACDIS_Y, 0, ySize, kKILL_DISABLE, "Acq Display" )	// -160 is an X offset preventing this panel to be covered by the FPulse panel.  We must disable killing as this would destroy any selection in the listbox, but minimising is allowed.

			SetWindow	$sWin,  hook( SelRes ) = fHookPnAcDis

			ModifyPanel /W=$sWin, fixedSize= 1						// prevent the user to maximize or close the panel by disabling these buttons

			// Create the 2D LB text wave	( Rows = all modes and ranges ,  Columns = Ch0; Ch1; ... )
			make  /O 	/T 	/N = ( nRows, nCols*(1+nSubCols) )	$"root:uf:" + sFolders + ":wAcDisTxt"	= ""	// the LB text wave
			wave   	/T		wAcDisTxt				     =	$"root:uf:" + sFolders + ":wAcDisTxt"
		
			// Create the 3D LB flag wave. 	Rows x Columns (as above)  x 3  : last index 0 is flags, 1 is fore- or background color, 2 is the remaining color 
			make   /O	/B  /N = ( nRows, nCols*(1+nSubCols), 3 )	$"root:uf:" + sFolders + ":wAcDisFlags"	// byte wave is sufficient for up to 254 colors 
			wave   			wAcDisFlags			    = 	$"root:uf:" + sFolders + ":wAcDisFlags"
			
			// Create color table withs rows and columns exchanged. 3 rows, n columns is easier to read as n columns, 3 rows but must be transposed before Igor can use them.
			// At the moment these colors are the same as in the  DataSections  listbox
			//								black		blue			red			magenta			grey			light grey			green			yellow				

			// Version1: (works but wrong colors)
			// make   /O	/W /U	root:uf:acq:ola:wAcDisColors= { {0, 0, 0 }, { 0, 0, 65535 },  { 65535, 0, 0 },  {40000,0,48000}, {44000,44000,44000},  {54000,54000,54000},  { 0, 50000, 0} ,   { 0, 56000, 56000 },  {65280,59904,48896} }	// order must be same as defined by constants above
			// wave	wAcDisColorsPr	 	= root:uf:acq:ola:wAcDisColors 		
			// MatrixTranspose 		  wAcDisColorsPr					// the same table is used for foreground and background. 	Igor requires  n  rows, 3 columns 
			// EvalColors( wAcDisColorsPr )								// 051108  

			// Version2: (works...)
			make /O	/W /U /N=(128,3) 	   	   $"root:uf:" + sFolders + ":wAcDisColors" 		
			wave	wAcDisColorsPr	 		= $"root:uf:" + sFolders + ":wAcDisColors" 		
			EvalColors( wAcDisColorsPr )								// 051108  


			// Link the  indices  of  Foreground  and  Background  colors  to  their name strings which are later used to access the layer where the color is to be set
			variable	planeFore	= 1,   planeBack = 2
			SetDimLabel 2, planeBack,  $"backColors"	wAcDisFlags
			SetDimLabel 2, planeFore,   $"foreColors"	wAcDisFlags


	MakeWnd( kMAX_ACDIS_WNDS )	// 060522 build the underlying waves just once, never delete them


	
		else														// The panel DOES exist. It may be minimised to an icon or it may be hidden behind other panels. If it is hidden then the checkbox must be actuated twice: hide and then restore panel to make it visible
			MoveWindow /W=$sWin	1,1,1,1							// Restore previous size and position. This does NOT take into account that the panel size may have changed in the meantime due to more or less columns or rows

			MoveWindow1( sWin, kRIGHT1, -200, xSize, kLBACDIS_Y, 0, ySize )	// Extract previous panel position and size. Keep only position and discard size as the size may have changed in the meantime due to more or less columns or rows.

			wave   	/T		wAcDisTxt		= $"root:uf:" + sFolders + ":wAcDisTxt"
			wave   			wAcDisFlags	= $"root:uf:" + sFolders + ":wAcDisFlags"
			Redimension	/N = ( nRows, nCols*(1+nSubCols) )		wAcDisTxt
			Redimension	/N = ( nRows, nCols*(1+nSubCols), 3 )		wAcDisFlags
		endif

		// Set the column titles in the SR text wave, take the entries as computed above
		variable	w, lbCol
		for ( c = 0; c < nCols; c += 1 )									// the true columns 0,1,2  each including the window subcolumns
			for ( w = 0; w <= nSubCols; w += 1 )							// 1 more as w=0 is not a window but the Mode/Range column
				lbCol	= c * (nSubCols+1) + w
				if ( w == 0 )
					SetDimLabel 1, lbCol, $StringFromList( c, lstColTitles, ksCOL_SEP ), wAcDisTxt	// 1 means columns,   true column 		e.g. 'Dac0'  or  'Adc1'
				else
					SetDimLabel 1, lbCol, $WndNm( w-1 ), wAcDisTxt						// 1 means columns,   window subcolumn	e.g. 'A' , 'B' , 'C'   or  'W0' , 'W1' 
				endif
			endfor
		endfor

		// Fill the listbox columns with the appropriate  text
		for ( c = 0; c < nCols; c += 1 )
			if ( c == 0 )
				// !!!  Bad code : number of entries depends on  'nSubCols' = 'kMAX_ACDIS_WNDS'	
				if ( kMAX_ACDIS_WNDS == 1 )
					ListBox   	lbAcDis,    win = $sWin, 	widths  =	{ kLBACDIS_COLWID_TYP,   kLBACDIS_COLWID_WND }	
				elseif ( kMAX_ACDIS_WNDS == 2 )
					ListBox   	lbAcDis,    win = $sWin, 	widths  =	{ kLBACDIS_COLWID_TYP,   kLBACDIS_COLWID_WND,  kLBACDIS_COLWID_WND }	
				elseif ( kMAX_ACDIS_WNDS == 3 )
					ListBox   	lbAcDis,    win = $sWin, 	widths  =	{ kLBACDIS_COLWID_TYP,   kLBACDIS_COLWID_WND,  kLBACDIS_COLWID_WND,  kLBACDIS_COLWID_WND }	
				elseif ( kMAX_ACDIS_WNDS == 4 )
					ListBox   	lbAcDis,    win = $sWin, 	widths  =	{ kLBACDIS_COLWID_TYP,   kLBACDIS_COLWID_WND,  kLBACDIS_COLWID_WND,  kLBACDIS_COLWID_WND,  kLBACDIS_COLWID_WND }	
				else
					ListBox   	lbAcDis,    win = $sWin, 	widths  =	{ kLBACDIS_COLWID_TYP,   kLBACDIS_COLWID_WND,  kLBACDIS_COLWID_WND,  kLBACDIS_COLWID_WND,  kLBACDIS_COLWID_WND,  kLBACDIS_COLWID_WND }	
				endif
			else
				// !!!  Bad code : number of entries depends on  'nSubCols' = 'kMAX_ACDIS_WNDS'	
				if ( kMAX_ACDIS_WNDS == 1 )
					ListBox   	lbAcDis,    win = $sWin, 	widths  +=	{ kLBACDIS_COLWID_TYP,   kLBACDIS_COLWID_WND }	
				elseif ( kMAX_ACDIS_WNDS == 2 )
					ListBox   	lbAcDis,    win = $sWin, 	widths  +=	{ kLBACDIS_COLWID_TYP,   kLBACDIS_COLWID_WND,  kLBACDIS_COLWID_WND }	
				elseif ( kMAX_ACDIS_WNDS == 3 )
					ListBox   	lbAcDis,    win = $sWin, 	widths +=	{ kLBACDIS_COLWID_TYP,   kLBACDIS_COLWID_WND,  kLBACDIS_COLWID_WND,  kLBACDIS_COLWID_WND }	
				elseif ( kMAX_ACDIS_WNDS == 4 )
					ListBox   	lbAcDis,    win = $sWin, 	widths  +=	{ kLBACDIS_COLWID_TYP,   kLBACDIS_COLWID_WND,  kLBACDIS_COLWID_WND,  kLBACDIS_COLWID_WND,  kLBACDIS_COLWID_WND }	
				else
					ListBox   	lbAcDis,    win = $sWin, 	widths  +=	{ kLBACDIS_COLWID_TYP,   kLBACDIS_COLWID_WND,  kLBACDIS_COLWID_WND,  kLBACDIS_COLWID_WND,  kLBACDIS_COLWID_WND,  kLBACDIS_COLWID_WND }	
				endif
			endif
			lstItemsInColumn  = StringFromList( c, lstColItems, ksCOL_SEP )	
			for ( r = 0; r < ItemsInList( lstItemsInColumn ); r += 1 )
				for ( w = 0; w <= nSubCols; w += 1 )									// 1 more as w=0 is not a window but the Mode/Range column
					lbCol	= c *(nSubCols+1) + w
					if ( w == 0 )
						wAcDisTxt[ r ][ lbCol ]	= StringFromList( r, lstItemsInColumn )			// set the text  e.g  'Base' , 'F0_T0'
					else
						wAcDisTxt[ r ][ lbCol ]	= ""									// the subcolumns 'A' , 'B' , 'C'  are  NOT displayed in the cells but only in the titles
					endif
				endfor
			endfor
		endfor
	
		// Build the listbox which is the one and only panel control 
		ListBox 	  lbAcDis,    win = $sWin, 	pos = { 2, 0 },  size = { xSize, ySize + kLB_ADDY },  frame = 2
		ListBox	  lbAcDis,    win = $sWin, 	listWave 			= $"root:uf:" + sFolders + ":wAcDisTxt"
		ListBox 	  lbAcDis,    win = $sWin, 	selWave 			= $"root:uf:" + sFolders + ":wAcDisFlags",  editStyle = 1
		ListBox	  lbAcDis,    win = $sWin, 	colorWave		= $"root:uf:" + sFolders + ":wAcDisColors"				// 051108
//		// ListBox 	  lbAcDis,    win = $sWin, 	mode 			 = 4// 5			// ??? in contrast to the  DataSections  panel  there is no mode setting required here ??? 
		ListBox 	  lbAcDis,    win = $sWin, 	proc 	 			 = lbAcDisProc
		// Design issue: Should  'lstCol2ChRg'  be stored in userdata?   As  the listbox  'lbAcDis'  is much simpler than  'lbSewlResOA'  it is actually not required  but could be done to maintain similarity of both listboxes...
//		ListBox 	  lbAcDis,    win = $sWin, 	userdata( lstCol2ChRg) = lstCol2ChRg
//		ListBox 	  lbAcDis,    win = $sWin, 	userdata( lstCurves ) 	 = lstCurves		// set UD lstCurves

	endif		// bVisible : state of  'AcqDisplay'  button is  ON 


//	// Store the string quasi-globally within the listbox panel window
//	// ListBox 	 	lbAcDis,    win = $sWin, 	UserData( lstAllMoRa ) = lstAllMoRa		// Store the string quasi-globally within the listbox which belongs to the panel window 
//	SetWindow	$sWin,  					UserData( lstAllMoRa ) = lstAllMoRa		// Store the string quasi-globally within the panel window containing the listbox 

End


Function		LBAcDisHide()
	string  	sWin	= ksLB_ACDIS
	 printf "\t\t\tLBAcDisHide()   sWin:'%s'  \r", sWin
	if (  WinType( sWin ) == kPANEL )						// check existance of the panel. The user may have killed it by clicking the panel 'Close' button 5 times in fast succession
		MoveWindow 	/W=$sWin   0 , 0 , 0 , 0				// hide the window by minimising it to an icon
	endif
End



Function 		fHookPnAcDis( s )
// The window hook function of the 'AcqDisplay panel' detects when the user minimises the panel by clicking on the panel 'Minimise' button and adjusts the state of the 'AcqDisplay' button accordingly
	struct	WMWinHookStruct &s
	string  	sFolders		= "acq:pul"
	if ( s.eventCode != kWHK_mousemoved )
		// printf  "\t\tfHookPnAcDis( %2d \t%s\t)  '%s'\r", s.eventCode,  pd(s.eventName,9), s.winName
		if ( s.eventCode == kWHK_move )									// This event also triggers if the panel is minimised to an icon or restored again to its previous state
			GetWindow     $s.WinName , wsize								// Get its current position		
			variable	bIsVisible	= ( V_left != V_right  &&  V_top != V_bottom )
			TurnButton( "pul", 	"root_uf_acq_pul_buAcDisplay0000",	 bIsVisible )	//  Turn the 'Acq Display' button  ON / OFF  if the user maximised or minimised the panel by clicking the window's  'Restore size'  or  'Minimise' button [ _ ]  to keep the control's state consistent with the actual state.
			// printf "\t\tfHookPnAcDis( %2d \t%s\t)  '%s'\tV_left:%3d, V_Right:%3d, V_top:%3d, V_bottom:%3d -> bVisible:%2d  \r", s.eventCode,  pd(s.eventName,9), s.winName, V_left, V_Right, V_top, V_bottom, bIsVisible
		endif
	endif
End


Function		lbAcDisProc( s ) : ListBoxControl
// Dispatches the various actions to be taken when the user clicks in the Listbox. At the moment only mouse clicks and the state of the CTRL, ALT and SHIFT key are processed.
// At the moment the actions are  1. colorise the listbox fields  2. add result to  or remove result from window.  Note: if ( s.eventCode == kLBE_MouseUp  )	does not work here like it does in the data sections listbox ???
	struct	WMListboxAction &s
	string  	sFolders		= "acq:pul"
	string  	sFolder		= ksACQ
	wave	wFlags		= $"root:uf:" + sFolders + ":wAcDisFlags"
	wave   /T	wTxt			= $"root:uf:" + sFolders + ":wAcDisTxt"
	string  	sPlaneNm		= "BackColors" 
	variable	pl			= FindDimLabel( wFlags, 2, sPlaneNm )
	variable	nOldState		= State( wFlags, s.row, s.col, pl )						// the old state
	string  	lstCol2ChRg 	= LstChAcq()
//	string  	lstCurves	 	= GetUserData( 	s.win,  s.ctrlName,  "lstCurves" )			// get UD lstCurves  e.g. Dac0;FM;1;UnitsUnUsed;(50000,50000,0);0;0;1|Adc1;......|
//	string  	lstCol2ChRg 	= GetUserData( 	s.win,  s.ctrlName,  "lstCol2ChRg" )		// e.g. for 2 columns '0,0;1,2;'  (Col0 is Ch0Rg0 , col1 is Ch1Rg2) 
//	string  	lstOlaRes	 	= GetUserData( 	s.win,  s.ctrlName,  "lstOlaRes" )			// e.g. 'Base_00A;Peak_00B;F0_A0_01B;' : which OLA results in which OLA windows

	//.......na............... Convert the modifying key (e.g. 'Ctrl' ,  'Ctrl Alt / Alt Gr' ) to a state = color  (e.g. select for file, for print or for both )  
	variable	nState		= Modifier2State( s.eventMod, lstMOD2STATE1)			//..................na.......NoModif:cyan:3:Tbl+Avg ,  Alt:green:2:Avg ,  Ctrl:1:blue:Tbl ,   AltGr:cyan:3:Tbl+Avg 


//	//  Construct or delete  'wAcqPt'  . This wave contains just 1 analysed  X-Y-result point which is to be displayed in the acquisition window over the original trace as a visual check that the analysis worked.  
	variable	ch			= LbCol2Ch( s.col, kMAX_ACDIS_WNDS )				// the column of the channel (ignoring all additional window columns)
	variable	w			= LbCol2Wnd0( s.col , kMAX_ACDIS_WNDS)			// windows are 0,1,2...
	variable	mo			= LbRow2Mode( s.row )
	variable	ra			= LbRow2Range( s.row )
	string		sChan		=  StringFromList( ch, lstCol2ChRg, ksSEP_TAB )
	// printf "\t\tlbAcDisProc( s ) 1\trow:%2d\tcol:%2d  evCode:%2d\tevModif:%2d\toldstate:%2d -> %2d \tch:%2d\twnd:%2d\tmo:%2d\tra:%2d\tlstColChans:'%s' \r", s.row , s.col, s.eventCode, s.eventMod,  nOldState, nState, ch, w, mo, ra, lstCol2ChRg
//	string  	sChRg		= StringFromList( ch, lstCol2ChRg )						// e.g. '0,0;1,2;'  ->  '1,2;'
//	string  	sWndAcq		= FindFirstWnd( ch )

//	variable	rg			= ChRg2Rg( sChRg )									// e.g.  Base , Peak ,  F0_A1, Lat1_xxx ,  Quotxxx
//	string  	sTyp			= wTxt[ s.row ][ LbCol2TypCol( s.col ) ]						// retrieves type when any window column  in any channel/region is clicked
//	variable	rtp			= WhichListItemIgnoreWhiteSpace( sTyp, klstEVL_RESULTS ) 	// e.g. kE_Base=15,  kE_PEAK=25  todo fits......
	string  	sWndAcDis	= ""

	string  	sLbMoRaNm 	= LbMoRaNm( ch, mo, ra ) 								// e.g. 
	variable	BegPt		= 0
	variable	nSmpInt		= SmpInt( sFolder )
	variable	Pts, EndPt, bIsFirst	
	variable	pr = 0,  bl = 0,  fr = 0,  sw = 0
	variable	ResultXShift 	= 0
	variable	nCurve, nCurves
	variable	nInstn, bAutoscl, YZoom, YOfs, rnAxis
	string  	sRGB, sCurve, sCurves
	string  	sTNm		= StringFromList( ch, LstChAcq(), ksSEP_TAB )				// e.g.   'Adc1'
	string  	sAcDisTrcNm 	= BuildTraceNmForAcqDispNoFolder( sTNm, mo, ra, BegPt )
	variable	LastDataPos	= 0 


	// MOUSE : SET a  cell. Click with Left Mouse in a cell  in any row or column. Depending on the modifiers used, the cell changes state and color and stays in this state. It can be reset by shift clicking again or by globally reseting all cells.
	// ADD  AN  ACQUISITION  WINDOW
	if ( s.eventCode == kLBE_MouseDown  &&  !( s.eventMod & kSHIFT )  &&  !( s.eventMod & kRIGHTCLICK ) )	// Only LEFT mouse clicks  without SHIFT  are interpreted here.  // ??? In this listbox only MouseDown is detected, whereas in the similar  DataSections  listbox  MouseUp  is detected???
		if ( w < 0 ) 														//  A  Mode/Range  column cell has been clicked  : ignore  clicks 
			 printf "\t\tlbAcDisProc( Ignore\trow:%2d\tcol:%2d  evCode:%2d\tevModif:%2d\toldstate:%2d -> %2d \tch:%2d\twnd:%2d\tmo:%2d\tra:%2d\t%s\t%s\t'%s'\t   \r", s.row , s.col, s.eventCode, s.eventMod,  nOldState, nState, ch, w, mo, ra,  sWndAcDis, pd(sLbMoRaNm,12), sAcDisTrcNm
		else
			if ( ! ( nOldState & 3 ) ) 		// the cell must have been unselected, do not attempt to select a trace twice
				DSSet5( wFlags, s.row, s.row, s.col, pl, nState )							// sets flags and changes the color of the listbox field.  The range feature is not used here so  begin row = end row .
	
				// test 060519-060522  Display Offline : Display data resembling the data to be acquired so that the user is aided in preparing his display configuration to be used during real acquisition
				// 060522 For retrieving trace colors (and also  rYOfs and  rYZoom)  we need  'sCurves'    OR  SOMETHING  EQUIVALENT...........
				sWndAcDis		= PossiblyAddAcDisWnd( w, kbAUTOPOS )
				 printf "\t\tlbAcDisProc( ADD 2\trow:%2d\tcol:%2d  evCode:%2d\tevModif:%2d\toldstate:%2d -> %2d \tch:%2d\twnd:%2d\tmo:%2d\tra:%2d\t%s\t%s\t'%s'\t   \r", s.row , s.col, s.eventCode, s.eventMod,  nOldState, nState, ch, w, mo, ra,  sWndAcDis, pd(sLbMoRaNm,12), sAcDisTrcNm
	
				EraseTracesInGraph( sWndAcDis ) 									// Remove all traces in  window  so that all traces can be rebuilt which simplifies the positioning of the Y axis.
				nInstn	= 0
				bAutoscl	= 1			// should be 1 only for Dacs and else 0 
				YZoom	= 1
				YOfs		= 0
				sRGB	= Nm2Color( sFolder, sChan )	
				sCurve	= BuildCurve( sChan, ra, mo, nInstn, bAutoscl, YOfs, YZoom, rnAxis, sRGB )
				sCurves	= AddListItem( sCurve, RetrieveCurves( w ), ksCURVSEP, inf )		// ADD new trace to curves in window 'w'
				//sCurves	= RetrieveCurves( w )	 + sCurve + ksCURVSEP					// ADD new trace to curves in window 'w'
				StoreCurves( w, sCurves )
				nCurves	= ItemsInList( sCurves, ksCURVSEP )
				nCurve	= nCurves  - 1													// the index of the trace/curve which has just been added
				 printf "\t\tlbAcDisProc( ADD 4\trow:%2d\tcol:%2d  evCode:%2d\tevModif:%2d\toldstate:%2d -> %2d \tch:%2d\twnd:%2d\tmo:%2d\tra:%2d\t%s\t%s\t'%s'\t%d/%2d\t->\t%s   \r", s.row , s.col, s.eventCode, s.eventMod,  nOldState, nState, ch, w, mo, ra,  sWndAcDis, pd(sLbMoRaNm,12), sAcDisTrcNm, nCurve, nCurve+1, sCurves
	
				// Compute 'LastDataPos'  : The time of the last displayed point (assuming 0 for the time of the first displayed point)
				for ( nCurve = 0; nCurve < nCurves; nCurve += 1 )					
					sCurve		= StringFromList( nCurve, sCurves, ksCURVSEP )		
					ExtractCurve( sCurve, sChan, ra, mo, nInstn, bAutoscl, YOfs, YZoom, rnAxis, sRGB )	// break 'sCurve' to get all traces to be displayed in window 'w'...
					Range2Pt( sFolder, ra, pr, bl, fr, sw, BegPt, EndPt, Pts, bIsFirst )
					LastDataPos	= max( LastDataPos, pts * nSmpInt / kXSCALE )					// The time of the last displayed point (assuming 0 for the time of the first displayed point)
				endfor
				for ( nCurve = 0; nCurve < nCurves; nCurve += 1 )								// Rebuild all traces in window
					sCurve		= StringFromList( nCurve, sCurves, ksCURVSEP )		
					ExtractCurve( sCurve, sChan, ra, mo, nInstn, bAutoscl, YOfs, YZoom, rnAxis, sRGB )	// break 'sCurve' to get all traces to be displayed in window 'w'...
					Range2Pt( sFolder, ra, pr, bl, fr, sw, BegPt, EndPt, Pts, bIsFirst )
					DurAcqDrawTraceAndAxis( sFolder,  w, nCurve, nCurves, sCurve, BegPt, Pts, bIsFirst, ra, nSmpInt, ResultXShift, LastDataPos )
				endfor



			endif
		endif

	endif

	// MOUSE :  RESET a cell  by  Left Mouse Shift Clicking
	if ( s.eventCode == kLBE_MouseDown  &&  ( s.eventMod & kSHIFT )  &&  !( s.eventMod & kRIGHTCLICK ) )	// Only LEFT mouse clicks  with    SHIFT  are interpreted here.  // ??? In this listbox only MouseDown is detected, whereas in the similar  DataSections  listbox  MouseUp  is detected???
		nState		= 0													// Reset a cell  
		DSSet5( wFlags, s.row, s.row, s.col, pl, nState )								// sets flags and changes the color of the listbox field.  The range feature is not used here so  begin row = end row .
		// printf "\t\tlbAcDisProc( s ) 3\trow:%2d\tcol:%2d  evCode:%2d\tevModif:%2d\tstate:%2d =?=%2d  \r",  s.row, s.col,  s.eventCode, s.eventMod, nState, State( wFlags, s.row, s.col, pl )	
		sWndAcDis	= WndNm( w )
		if ( w < 0 ) 															//  A  Window column cell has been clicked  ( ignore  clicks into  the  Mode/Range column)
		endif
	
		// printf "\t\tlbAcDisProc( DEL 1\trow:%2d\tcol:%2d  evCode:%2d\tevModif:%2d\toldstate:%2d -> %2d \tch:%2d\twnd:%2d\tmo:%2d\tra:%2d\t%s\t%s\t'%s'\t   \r", s.row , s.col, s.eventCode, s.eventMod,  nOldState, nState, ch, w, mo, ra,  sWndAcDis, pd(sLbMoRaNm,12), sAcDisTrcNm

 		// Remove the  AcDis  trace from the AcDis  window  W0, W1 or W2
		if ( WinType( sWndAcDis ) == kGRAPH )									// check if the graph exists but...

// 060603b
			//EraseMatchingTraces( sWndAcDis, RemoveEnding( sAcDisTrcNm, "0" ) ) 		// Remove the selected trace. Possibly remove trailing 0 (=BegPt) so that traces with any BegPt will be removed.  All current traces (having is no BegPt and ending with '_' ) are unaffected.
			EraseTracesInGraph( sWndAcDis ) 									// Remove all traces in  window  so that all traces can be rebuilt which simplifies the positioning of the Y axis.

			sCurves	= RetrieveCurves( w )								
			nCurve	= WhichCurve( sCurves, ksCURVSEP, sTNm, mo, ra )
			sCurves	= RemoveListItem( nCurve, sCurves, ksCURVSEP )				// REMOVE the curve to be deleted
			StoreCurves( w, sCurves )
			nCurves	= ItemsInList( sCurves, ksCURVSEP )
			 printf "\t\tlbAcDisProc( DEL 2\trow:%2d\tcol:%2d  evCode:%2d\tevModif:%2d\toldstate:%2d -> %2d \tch:%2d\twnd:%2d\tmo:%2d\tra:%2d\t%s\t%s\t'%s'\t%d/%2d\t->\t%s   \r", s.row , s.col, s.eventCode, s.eventMod,  nOldState, nState, ch, w, mo, ra,  sWndAcDis, pd(sLbMoRaNm,12), sAcDisTrcNm,  nCurve, nCurves, sCurves

			// Compute 'LastDataPos'  : The time of the last displayed point (assuming 0 for the time of the first displayed point)
			for ( nCurve = 0; nCurve < nCurves; nCurve += 1 )					
				sCurve		= StringFromList( nCurve, sCurves, ksCURVSEP )		
				ExtractCurve( sCurve, sChan, ra, mo, nInstn, bAutoscl, YOfs, YZoom, rnAxis, sRGB )	// break 'sCurve' to get all traces to be displayed in window 'w'...
				Range2Pt( sFolder, ra, pr, bl, fr, sw, BegPt, EndPt, Pts, bIsFirst )
				LastDataPos	= max( LastDataPos, pts * nSmpInt / kXSCALE )			// The time of the last displayed point (assuming 0 for the time of the first displayed point)
			endfor
			for ( nCurve = 0; nCurve < nCurves; nCurve += 1 )						// Rebuild all traces in window
				sCurve		= StringFromList( nCurve, sCurves, ksCURVSEP )		
				ExtractCurve( sCurve, sChan, ra, mo, nInstn, bAutoscl, YOfs, YZoom, rnAxis, sRGB )	// break 'sCurve' to get all traces to be displayed in window 'w'...
				Range2Pt( sFolder, ra, pr, bl, fr, sw, BegPt, EndPt, Pts, bIsFirst )
				DurAcqDrawTraceAndAxis( sFolder,  w, nCurve, nCurves, sCurve, BegPt, Pts, bIsFirst, ra, nSmpInt, ResultXShift, LastDataPos )
			endfor


			// Check if any other Mode/Range still uses this window. Only if no other Mode/Range uses this window we can remove not only the trace but also the window 
			variable	nUsed	= 0
			variable	c, nCols	= ItemsInList( lstCol2ChRg, ksSEP_TAB ) 				// the number of Mode/Range columns (ignoring any window columns) 
			for ( c = 0; c < nCols; c += 1 )
				variable	nTrueCol	= c * ( kMAX_ACDIS_WNDS + 1 ) +  w + 1  
				variable	r, nRows	= DimSize( wTxt, 0 )							// or wFlags
				for ( r = 0; r < nRows; r += 1 )
					nUsed += ( State( wFlags, r, nTrueCol, pl ) != 0 )
					// printf "\t\tlbAcDisProc( DEL 3\tr:%2d/%2d\tcol:%2d  evCode:%2d\tevModif:%2d\toldstate:%2d -> %2d \tlstColChans:'%s' -> ch:%2d\twnd:%2d\tmo:%2d\tra:%2d\t%s  -> State:%2d   Used:%2d \r", r, nRows, nTrueCol, s.eventCode, s.eventMod,  nOldState, nState, lstCol2ChRg, ch, w, mo, ra,  sWndAcDis, State( wFlags, r, nTrueCol, pl ), nUsed
				endfor
			endfor
			sWndAcDis	= WndNm( w )
			if ( nUsed == 0 )
				KillWindow $sWndAcDis
			endif
		endif

//		string  sTxt   = "Window '" + sWndAcDis + "' (still) used " + num2str( nUsed ) + " times. " + SelectString( nUsed, "Will", "Cannot" ) + " delete window."
//		 printf "\t\tlbAcDisProc( DEL 4\trow:%2d\tcol:%2d  evCode:%2d\tevModif:%2d\toldstate:%2d -> %2d \tlstColChans:'%s' -> ch:%2d  rg.%2d  w:%2d [%s] kEIdx:%3d   '%s' -> %s  \r", s.row , s.col, s.eventCode, s.eventMod,  nOldState, nState, lstCol2ChRg, ch, rg, w, sWndAcDis, rtp, sTyp, sTxt
	endif


	// MOUSE : SET a  cell. Click with RIGHT Mouse in a cell  in any row in a window column . This will pop up the Trace&Window controlbar.  Shift Click Right Mouse will reset again.
	if ( s.eventCode == kLBE_MouseDown  &&  !( s.eventMod & kSHIFT )  &&   ( s.eventMod & kRIGHTCLICK ) )	// Only RIGHT mouse clicks  without SHIFT  are interpreted here.  
		if ( w < 0 ) 																		//  A  Mode/Range  column cell has been clicked  : ignore  clicks 
			 printf "\t\tlbAcDisProc( IgnoRM\trow:%2d\tcol:%2d  evCode:%2d\tevModif:%2d\toldstate:%2d -> %2d \tch:%2d\twnd:%2d\tmo:%2d\tra:%2d\t%s\t%s\t'%s'\t   \r", s.row , s.col, s.eventCode, s.eventMod,  nOldState, nState, ch, w, mo, ra,  sWndAcDis, pd(sLbMoRaNm,12), sAcDisTrcNm
		else
			if ( nOldState & 3 )		// the cell must have been selected, do not attempt to create a controlbar for an unselectred trace
			//DSSet5( wFlags, s.row, s.row, s.col, pl, nState )										// sets flags and changes the color of the listbox field.  The range feature is not used here so  begin row = end row .
				 printf "\t\tlbAcDisProc( +CtrlBar\trow:%2d\tcol:%2d  evCode:%2d\tevModif:%2d\toldstate:%2d -> %2d \tch:%2d\twnd:%2d\tmo:%2d\tra:%2d\t%s\t%s\t'%s'\t   \r", s.row , s.col, s.eventCode, s.eventMod,  nOldState, nState, ch, w, mo, ra,  sWndAcDis, pd(sLbMoRaNm,12), sAcDisTrcNm
				CreateControlBarInAcqWnd3( sChan, mo, ra, w, ON ) 
			endif
		endif
	endif

	// MOUSE :  RESET a cell  by  RIGHT Mouse Shift Clicking . This will remove the  Trace&Window controlbar
	if ( s.eventCode == kLBE_MouseDown  &&  ( s.eventMod & kSHIFT )  &&   ( s.eventMod & kRIGHTCLICK ) )	// Only RIGHT mouse clicks  without SHIFT  are interpreted here.  
		if ( w < 0 ) 																		//  A  Mode/Range  column cell has been clicked  : ignore  clicks 
			 printf "\t\tlbAcDisProc( Ig ShfRM\trow:%2d\tcol:%2d  evCode:%2d\tevModif:%2d\toldstate:%2d -> %2d \tch:%2d\twnd:%2d\tmo:%2d\tra:%2d\t%s\t%s\t'%s'\t   \r", s.row , s.col, s.eventCode, s.eventMod,  nOldState, nState, ch, w, mo, ra,  sWndAcDis, pd(sLbMoRaNm,12), sAcDisTrcNm
		else
			//DSSet5( wFlags, s.row, s.row, s.col, pl, nState )										// sets flags and changes the color of the listbox field.  The range feature is not used here so  begin row = end row .
			 printf "\t\tlbAcDisProc( - CtrlBar\trow:%2d\tcol:%2d  evCode:%2d\tevModif:%2d\toldstate:%2d -> %2d \tch:%2d\twnd:%2d\tmo:%2d\tra:%2d\t%s\t%s\t'%s'\t   \r", s.row , s.col, s.eventCode, s.eventMod,  nOldState, nState, ch, w, mo, ra,  sWndAcDis, pd(sLbMoRaNm,12), sAcDisTrcNm
			// 060608  STRANGE : Igor runs wild when the window is killed after having removed the last trace from the window  IF BEFORE ONE TRIED TO REMOVE  A  NON_EXISTING CONTROLBAR.  No idea why but here we do what must be done: we avoid the attempt to remove a non-existing controlbar....
			if ( AcqControlBar( w ) )
				CreateControlBarInAcqWnd3( sChan, mo, ra, w, OFF ) 
			endif
		endif
	endif

End


//=====================================================================================================================================
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


Function		fLoadDispCfg( s )
	struct	WMButtonAction	&s
	svar		sScriptPath= root:uf:acq:pul:gsScrptPath0000
	string  	sFolder	= ksACQ
	LoadDisplayCfg( sFolder, sScriptPath, "" )					// ""  	must keep this naming convention so that future versions can access old display configurations
End

Function		fLoadDispCfg2( s )
	struct	WMButtonAction	&s
	svar		sScriptPath= root:uf:acq:pul:gsScrptPath0000
	string  	sFolder	= ksACQ
	LoadDisplayCfg( sFolder, sScriptPath, "_2" )				// "_2"  	must keep this naming convention so that future versions can access old display configurations
End

Function		fSaveDspCfg( s )
	struct	WMButtonAction	&s
	  printf "\tfSaveDispCfg( %s )  \r", s.ctrlName 
	SaveDispCfg( "" ) 									// "" 	must keep this naming convention so that future versions can access old display configurations
End
Function		fSaveDspCfg2( s )
	struct	WMButtonAction	&s
	  printf "\tfSaveDispCfg2( %s )  \r", s.ctrlName 
	SaveDispCfg( "_2" )									// "_2"  	must keep this naming convention so that future versions can access old display configurations
End


 Function		LoadDisplayCfg( sFolder, sFileName, sIndex )
	string		sFolder, sFileName, sIndex
	string		sDisplayCfg = ksSCRIPTS_DRIVE + ksSCRIPTS_DIR + ksTMP_DIR + ksDIRSEP + StripPathAndExtension( sFileName ) + sIndex + "." + sDISP_CONFIG_EXT		// C:UserIgor:Scripts:Tmp:XYZ.dcf
	if ( bFoundDispCfg( sDisplayCfg ) )
		 printf "\t\tLoadDisplayCfg( \t%s\t'%s'\t%s ) \t: user display config  '%s'  found : displaying it...\r", sFolder, sFileName, sIndex, sDisplayCfg
		LoadDispSettings( sFolder, sDisplayCfg )
	else
		// todo : ??? alert user
		 printf "\t\tLoadDisplayCfg( \t%s\t'%s'\t%s ) \t: user display config  '%s'  NOT found ...\r", sFolder, sFileName, sIndex, sDisplayCfg
	endif	
End


static Function		bFoundDispCfg( sDisplayCfg )
	string 	sDisplayCfg
	return	FileExists( sDisplayCfg )					// already contains symbpath 
End

static Function		SaveDispCfg( sIndex )
// store current disp settings in specific file whose file name is derived from the script file name (other extension  and  other directory=subdirectory 'Tmp' ).
	string		sIndex
	svar		sScriptPath = root:uf:acq:pul:gsScrptPath0000
	string		sFile		  = ksSCRIPTS_DRIVE + ksSCRIPTS_DIR + ksTMP_DIR + ksDIRSEP + StripPathAndExtension( sScriptPath ) + sIndex + "." + sDISP_CONFIG_EXT// C:UserIgor:Scripts:Tmp:XYZ.dcf
	SaveDispSettings( sFile )
End

static  Function		SaveDispSettings( sFile ) 
// store all window / trace arrangement variables (=the display configuration contained in WLoc and WA) in 'sFile' having the extension 'DCF' 
	string 	sFile
	string 	bf
	// First get the current window corners from IGOR ,  then store them in wLoc, finally save wLoc in the settings file 
	// Cave: wLoc is updated here, not earlier: it may contain obsolete values here when windows have been moved or resized since last save.
	// wLoc could be updated earlier on 'wnd resize' event but not on 'wnd move' event as IGOR does not supply the latter event....
	variable	w, wCnt	= WndCnt()
	// printf "\t\tSaveDispSettings( %s )  saves WA[ w:%d ]  and  WLoc[ w:%d ][ %d ] \r", sFile, wCnt, wCnt, cWNDLASTENTRY  
	for ( w = 0; w < wCnt; w += 1 )
		string 	sWnd	= WndNm( w )
		if ( WinType( sWnd ) == kGRAPH )								// check if the graph exists
			GetWindow $sWnd, wSize
			SetWndCorners( w, V_left, V_top, V_right, V_bottom )
		endif
	endfor
// 060526 only for debug printing
	ShowTrcWndArray()												
	save /O /T /P=symbPath root:uf:disp:wWLoc, root:uf:disp:wWA as sFile 	// store all acquisition display variables to disk
End	

// 060524
static Function		LoadDispSettings( sFolder, sFile )
// retrieve all window / trace arrangement variables (=the display configuration contained in WLoc and WA) from 'sFile' having the extension 'DCF' 
	string 	sFolder, sFile
	string	 	bf
	variable	nRefNum

	loadwave /O /T /A  /Q /P=symbPath sFile			// read all acquisition display variables from disk
	duplicate	/O 	wWLoc	   root:uf:disp:wWLoc
	killWaves	wWLoc
	duplicate	/O 	wWA	   root:uf:disp:wWA
	killWaves	wWA
	wave  /T	wWA		= root:uf:disp:wWA

	variable	w//, wCnt	= WndCnt()
	// printf "\t\tLoadDispSettings( %s ) oldwCnt:%d ,  loading WA,WLoc(wCnt:%d) , script chs:'%s'    \r", sFile, oldwCnt, wCnt, ioChanList( wIO )
	 printf "\t\tLoadDispSettings( a \t%s )     \t loading WA,WLoc(wCnt:%d) ,    \r", sFile, kMAX_ACDIS_WNDS
	//ShowWndCurves( 0 )		
	//ShowWndCorners()

	// The new script may have a different number of IO channels...
	RedimensionWnd(  kMAX_ACDIS_WNDS  )

	//  Display Offline : Retrieve the Mode/Range-Color  string entries, build the windows and  display dummy traces so that the user is aided in preparing his display configuration to be used during real acquisition
	string  	sFolders	= "acq:pul"

	TurnButton( "pul", 	"root_uf_acq_pul_buAcDisplay0000",		ON )		// Set 'Acq Display' button state to ON so that the Online Acquisition Display listbox will be built in the following line... 
	LBAcDisUpdate()											// Rebuild the listbox completely as in meantime while the listbox perhaps was invisible e.g the number of channels may have changed
	ClearLBAcDis( sFolders )

	string  	sWndAcDis, sCurves, sCurve
	string  	sCleanCurves	= ""									// like sCurves, but orphan traces (=Channels with no correspondence in  script) have been removed
	variable	nState		= 3											// the one and only ON state, could be expanded to more states and colors
	variable	ch, row = -1, col = -1
	wave   	wFlags		= $"root:uf:" + sFolders + ":wAcDisFlags"				// The panel  'ksLB_ACDIS'  must exist and does exist  as it has been built above in LBAcDisUpdate(). 
	variable	pl			= FindDimLabel( wFlags, 2, "BackColors"  )
	string  	lstChans		= LstChAcq()
	variable	nCurve, nCurves

	for ( w = 0; w < kMAX_ACDIS_WNDS; w += 1 )
		sCurves		= RetrieveCurves( w )
		sCleanCurves	= sCurves
		nCurves		=  ItemsInList( sCurves, ksCURVSEP )							// traces in 1 window
		sWndAcDis	= WndNm( w )

		if ( WinType( sWndAcDis ) == kGRAPH )									//  This  'Acquisition display' window does already exist....
			KillWindow  $sWndAcDis											// ..but we kill it so that no empty windows remain..
			sWndAcDis	= ""												// ..in case this channel is not used in this newly loaded script
		endif


		variable	ra, mo, rnInstance, rAutoscl, rYOfs, rYZoom, rnAxis 
		string		sChan, sRGB
		variable	pr = 0,  bl = 0,  fr = 0,  sw = 0
		variable	Pts, BegPt, EndPt, bIsFirst
		variable	nSmpInt		= SmpInt( sFolder )
		variable	ResultXShift 	= 0
		variable	LastDataPos	= 0
		for ( nCurve = 0; nCurve < nCurves; nCurve += 1 )
			sCurve	= StringFromList( nCurve, sCurves, ksCURVSEP )		
			ExtractCurve( sCurve, sChan, ra, mo, rnInstance, rAutoscl, rYOfs, rYZoom, rnAxis, sRGB )// break 'sCurve' to get all traces to be displayed in window 'w'...
			ch	= WhichListItem( sChan,  lstChans, ksSEP_TAB )
			if ( ch == kNOTFOUND )
				FoAlert( sFolder, kERR_IMPORTANT, "The channel  '" + sChan + "'  found in the display config file has no correspondence in the script. Cannot display. Will adjust display configuration file..." )	// Happens when the user edits channels in the script and then forgets to save the display cfg
				// 060531 If the display configuration contains channels not found in the script these will automatically be removed from the display configuration file. 
				sCleanCurves	= RemoveFromList( sCurve, sCleanCurves, ksCURVSEP )	
				StoreCurves( w, sCleanCurves )
				SaveDispSettings( sFile ) 
			else
				sWndAcDis	= PossiblyAddAcDisWnd( w, kbMYPOS ) 				// Build the window (which has been removed above) at the user's preferred position 
				Range2Pt( sFolder, ra, pr, bl, fr, sw, BegPt, EndPt, Pts, bIsFirst )
				LastDataPos	= max( LastDataPos, pts * nSmpInt / kXSCALE )			// The time of the last displayed point (assuming 0 for the time of the first displayed point)

				col			= LbChanWnd2Col( ch, w, kMAX_ACDIS_WNDS )
				row			= LbModeRange2Row( mo, ra )
				DSSet5( wFlags, row, row, col, pl, nState )							// sets flags and changes the color of the listbox field.  The range feature is not used here so  begin row = end row .
			endif

			 printf "\t\t\tLoadDispSettings( b  \trow:%2d\tcol:%2d \t <-\t%s\tch:%2d\tmo:%2d\tra:%2d\twnd:%2d\t'%s'\tldp:%8g\tScript: %s\tCv:%d  ClnC:%d\t%s   \r", row , col, pd(sChan,8), ch, mo, ra, w, sWndAcDis, LastDataPos, pd( lstChans, 23), ItemsInList( sCurves, ksCURVSEP), ItemsInList( sCleanCurves, ksCURVSEP), pd( sCurve, 43)
		endfor
		for ( nCurve = 0; nCurve < nCurves; nCurve += 1 )
			sCurve	= StringFromList( nCurve, sCurves, ksCURVSEP )		
			ExtractCurve( sCurve, sChan, ra, mo, rnInstance, rAutoscl, rYOfs, rYZoom, rnAxis, sRGB )	// break 'sCurve' to get all traces to be displayed in window 'w'...
			Range2Pt( sFolder, ra, pr, bl, fr, sw, BegPt, EndPt, Pts, bIsFirst )
			DurAcqDrawTraceAndAxis( sFolder,  w, nCurve, nCurves, sCurve, BegPt, Pts, bIsFirst, ra, nSmpInt, ResultXShift, LastDataPos )
			 printf "\t\t\tLoadDispSettings( c  \trow:%2d\tcol:%2d \t <-\t%s\tch:%2d\tmo:%2d\tra:%2d\twnd:%2d\t'%s'\tldp:%8g\tScript: %s\tCv:%d  ClnC:%d\t%s   \r", row , col, pd(sChan,8), ch, mo, ra, w, sWndAcDis, LastDataPos, pd( lstChans, 23), ItemsInList( sCurves, ksCURVSEP), ItemsInList( sCleanCurves, ksCURVSEP), pd( sCurve, 43)
		endfor

	endfor
	
	EnableButton( "disp", "root_uf_acq_ola_PrepPrint0000", kENABLE )	// Now that the acquisition windows (and TWA) are constructed we can allow drawing in them (even if they are still empty)
End


//=====================================================================================================================================
//   MODE  and  RANGE  ( in the Listbox )

Function	/S	ListAllMora()
// Returns list of titles containing all display modes and ranges e.g.  'Sweeps Current..... Result Many'  and the channel suffix. 
// This function determines the entries and their order as displayed in the listbox.  ListAllMora()  and  LbModeRange2Row( mo, ra )  and  LbRow2Mode()  and  LbRow2Range()  must be changed together!
	variable	ch, m, r
	variable	nChans		= ItemsInList( LstChAcq(), ksSEP_TAB )
	string 	lstAllMoRa	= ""
	
	for ( ch = 0; ch < nChans; ch += 1 )
		for ( r = 0; r < RangeCnt(); r += 1 )				// sweep, frame...
			for ( m = 0; m < ModeCnt(); m += 1 )			// current , many
				lstAllMoRa	+= LbMoRaNm( ch, m, r ) + ";" 	// !!! Assumption : MoRa naming convention
				// printf "\t\tListAllMora(a)  \t%s\tItms:%2d\t'%s...%s \r", pd(LbMoRaNm( ch, m, r ) ,12) , ItemsInList( lstAllMoRa ),  lstAllMoRa[0,80],  lstAllMoRa[ strlen( lstAllMoRa )-80, inf ]  
			endfor
		endfor
	endfor
	 printf "\t\tListAllMora(b)  \t\t\t\t\tItms:%2d\t'%s......%s \r", ItemsInList( lstAllMoRa ),  lstAllMoRa[0,80],  lstAllMoRa[ strlen( lstAllMoRa )-80, inf ]  
	return	lstAllMoRa
End
Function		LbModeRange2Row( mo, ra )
// This function determines the entries and their order as displayed in the listbox.  ListAllMora()  and  LbModeRange2Row( mo, ra )  and  LbRow2Mode()  and  LbRow2Range()  must be changed together!
	variable	mo, ra
	return	ra * ModeCnt() + mo
End
Function		LbRow2Mode( row )
// This function determines the entries and their order as displayed in the listbox.  ListAllMora()  and  LbModeRange2Row( mo, ra )  and  LbRow2Mode()  and  LbRow2Range()  must be changed together!
	variable	row
	return	mod( row, ModeCnt() )	
End
Function		LbRow2Range( row )
// This function determines the entries and their order as displayed in the listbox.  ListAllMora()  and  LbModeRange2Row( mo, ra )  and  LbRow2Mode()  and  LbRow2Range()  must be changed together!
	variable	row
	return	trunc( row / ModeCnt() )	
End
Function	/S	LbMoRaNm( ch, mo, ra )
	variable	ch, mo, ra
	return	RangeNmLong( ra ) + " " + ModeNm( mo ) + "_" + num2str( ch )  		// !!! Assumption : MoRa naming convention
End



static  Function	/S	PossiblyAddAcDisWnd( w, bAutoPos )
// Construct and display  1 additional  Analysis window with the default name depending on 'w'
	variable	w, bAutoPos
	variable	wCnt		= kMAX_ACDIS_WNDS
	string 	sWNm	= WndNm( w )
	variable	rnLeft, rnTop, rnRight, rnBot												// place the window in top half to the right of the acquisition windows 
	if (  ! ( WinType( sWNm ) == kGRAPH ) )												//  This  'Acquisition display' window does not exist yet
		if ( bAutoPos == kbAUTOPOS )
			GetAutoWindowCorners( w, wCnt, 0, 1, rnLeft, rnTop, rnRight, rnBot, kWNDDIVIDER, 100 )	// row, nRows, col, nCols
		else																		
			RetrieveWndCorners( w, rnLeft, rnTop, rnRight, rnBot )								// use stored/retrieved position
		endif
		Display /K=2 /N=$( sWNm ) /W= ( rnLeft, rnTop, rnRight, rnBot ) 							// K=2 : disable killing	 . The user  should kill the window by first removing all traces which will automatically remove the window
		// 060608  STRANGE : Igor runs wild when the window is killed HERE after having removed the last trace from the window  IF BEFORE ONE TRIED TO REMOVE  A  NON_EXISTING CONTROLBAR.  We avoid the attempt to remove a non-existing controlbar elsewhere....
		SetWindow   	$sWNm	hook( fAcqWndHookNm )	= fAcqWndHook			
	endif
	return	sWNm
End


//=====================================================================================================================================
//   MODE  and  RANGE  ( in 2 variables )

static  constant		kCURRENT 		= 0,		kMANYSUPIMP = 1
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


static  Function  /S	ModeNm( n )
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
		if ( nMode == kNOTFOUND )
			DeveloperError( "[ModeNr] '" + s + "' must be 'C' or 'M' " )
		endif
	endif
	return nMode
End

static Function		ModeCnt()	
	return	ItemsInList( lstMODETEXT, ksSEP_STD )
End	

static Function  /S	RangeNm( n )
// returns  an arbitrary  name for the range, not for the variable  e.g.  'S' , 'F',  'R',  'P'
	variable	n
	return	StringFromList( n, lstRANGENM )
End

static Function	/S	RangeNmLong( n )
// returns  an arbitrary  name for the range, not for the variable  e.g.  'Sweeps' , 'Frames',  'Result',  'Primary'
	variable	n
	return	StringFromList( n, lstRANGETEXT, ksSEP_STD )
End

Function			RangeNr( s )
// returns  index of the range, given its name			used also in   GetRangeNrFromTrc()  in  FPOnline.ipf
	string 	s
	variable	n = 0				// Do not issue a warning when no character is passed.... 
	if ( strlen( s ) )					// This happens when a window contains no traces.
		n = WhichListItem( s, lstRANGENM )
		if ( n == kNOTFOUND )
			DeveloperError( "[RangeNr] '" + s + "' must be 'S' (Sweep) or 'F' (Frame) or 'P' (Primary sweep) or 'R' (Result sweep) " )
		endif
	endif
	return n
End

static Function		RangeCnt()
	return	ItemsInList( lstRANGETEXT, ksSEP_STD )
End	

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//  IMPLEMENTATION  for  STORING   MODE  and  RANGE  as  a 2-LETTER-string  (for Curves)

static Function	/S	BuildMoRaName( nRange, nMode )
// converts the Mode / range setting for storage in TWA  to a 2-letter-string   e.g. 	'SM',   'FC' 
	variable	nRange, nMode
	return	RangeNm( nRange ) + ModeNm( nMode )
End

static Function	/S 	BuildMoRaNameInstance( nRange, nMode, nInstance )		// 040107
// converts the Mode / range setting into a 2-letter-string   containing the instance number  e.g. 	'SM ',   'FC1'       ( obsolete: 'SMa',   'FCb' )  
	variable	nRange, nMode, nInstance 
	string    	sInstance = SelectString( nInstance != 0, " " , num2str( nInstance ) )	// for the 1. instance  do not display the zero but leave blank instead
	return	" " + BuildMoRaName( nRange, nMode ) + " " + sInstance 			// 040107
End

static Function		ExtractMoRaName( sMoRa, rnRange, rnMode )
// retrieves the Mode / range setting  from TWA  and converts the 2-letter-string   into 2 numbers  e.g. 'SM'->0,1   'RS' ->3,0
	string 	sMoRa
	variable	&rnRange, &rnMode
	rnRange	= RangeNr( sMora[0,0] )
	rnMode	= ModeNr(   sMora[1,1] )
End


//=====================================================================================================================================
//  DISPLAY  DURING  ACQUISITION

constant	 cLAG = 5		// typical values  3..10  seconds    or    1..10 % 

Function		DispDuringAcqCheckLag( sFolder, wFix, pr, bl, fr, sw, nRange )		// partially  PROTOCOL  AWARE
	string  	sFolder
	wave  	wFix
	variable	pr, bl, fr, sw, nRange
	variable	bDispAllDataLagging	= DispAllDataLagging()
	variable	nLag				= LagTime()

// 060202
	nvar		gPrevBlk	= root:uf:acq:pul:svPrevBlk0000
//	if ( gPrevBlk == -1 )							// Called  only  once  for one initialization before the first block
//		 //ComputeAndUseDacMinMax()			// Autoscale the Dacs : only for the Dac we know the exact signal range in advance . Do it only once even for multiple different blocks( the Dac min/max value is computed over all catenated blocks). 
//	endif

	variable	w,  wCnt	= WndCnt() 
	for ( w = 0; w < wCnt; w += 1 )										
		string  	sWNm	= WndNm( w )

		if ( WinType( sWNm ) == kGRAPH )
			// 060202		simplify this
			if ( gPrevBlk == -1 )		 					
	// 060602
	//			SetYAxisCnt( w )
				RemoveTextBoxPP( sWNm )			// remove any old PreparePrinting textbox. 
// test here 060608
				RemoveTextBoxUnits( sWNm )			//also removes PreparePrinting Textbox, but should not..
				RemoveAcqTraces( sWNm )			// erase any leftovers from the preceding block, but this also deletes the Y axis...
			endif
			if ( bl != gPrevBlk )
				// ConstructYAxis()					// weg  060601
// test weg 060608
//RemoveTextBoxUnits( sWNm )			// 040109  possibly so often not necessary, only necessary at 1. block ..? ( also removes PreparePrinting Textbox, should not..)
				RemoveAcqTraces( sWNm )			// erase any leftovers from the preceding block, but this also deletes the Y axis...
			endif

			// 060524???
			//if ( bDispAllDataLagging  ||  nLag < cLAG  ||  fr + sw == 0 )		// 060524 this seems to have been wrong : sw was  sweep OR negative e.g. kDISP_FRAME -> last condition was TRUE when sw = -kDISP_FRAME
			if ( bDispAllDataLagging  ||  nLag < cLAG  || ( fr == 0 && sw == 0 ) )	// ????  more stringent condition ...???? untested  and not understood..??? could new parameter 'nRange' simplify matters???.. 
				DispDuringAcq( sFolder, w, wFix, pr, bl, fr, sw, nRange )
				// printf "DispDuringAcqCheckLag LagTime():%.1lf \tdisplaying \t(w:%d) \r", nLag, w
			//else
				// printf "DispDuringAcqCheckLag LagTime():%.1lf \t\t\t\tskipping \t(w:%d)\r", nLag, w
			endif
		endif
	endfor
// 060202
	gPrevBlk  = bl
End


static Function	DispDuringAcq( sFolder, w, wFix, pr, bl, fr, sw, nRange )			// partially  PROTOCOL  AWARE
//  Display superimposed and current sweeps and frames
	string  	sFolder
	wave  	wFix
	variable	w, pr, bl, fr, sw, nRange
	variable	BegPt, EndPt, Pts, bIsFirst									// will be set by  'Range2Pt()'
	variable	PnDebgDispDurAcq	= DebugSection() & kDBG_DispDurAcq
	variable	nSmpInt			= SmpInt( sFolder )
	variable	ResultXShift		=  ( SweepBegSave( sFolder, pr, bl, fr, eSweeps( wFix, bl ) -1 ) - FrameBegSave( sFolder, pr, bl, fr )	) * nSmpInt / 1e6 

//????WHY is  Range2Pt()   OUTSIDE the curves loop????????? 
	Range2Pt( sFolder, nRange,  pr, bl, fr, sw, BegPt, EndPt, Pts, bIsFirst )			// display  sweeps  or  frames ?

	// printf "\t\t\tDispDurAcq()  prot:%d  block:%2d  frm:%2d  swp:%2d\t [points %6d..\t%6d \t=%6d\t pts]   ( igLastBlk:%d , bIsFirst:%d ) \r", pr, bl, fr, sw,  BegPt, EndPt, Pts, 123, bIsFirst

	if ( PnDebgDispDurAcq )
		printf "\t\t\tDispDurAcq()  prot:%d  block:%2d  frm:%2d  swp:%2d\t [points %6d..\t%6d \t=%6d pts]   ( igLastBlk:%d , bIsFirst:%d ) \r", pr, bl, fr, sw,  BegPt, EndPt, Pts, 123, bIsFirst
	endif	

	string  	sCurve, sCurves		= RetrieveCurves( w )
	variable	nCurve, nCurves	= ItemsInList( sCurves, ksCURVSEP )
	variable	LastDataPos

// 060608 New code?????????????????
	// Compute 'LastDataPos'  : The time of the last displayed point (assuming 0 for the time of the first displayed point)
	for ( nCurve = 0; nCurve < nCurves; nCurve += 1 )					
		sCurve		= StringFromList( nCurve, sCurves, ksCURVSEP )		
		Range2Pt( sFolder, nRange, pr, bl, fr, sw, BegPt, EndPt, Pts, bIsFirst )
		LastDataPos	= max( LastDataPos, pts * nSmpInt / kXSCALE )			// The time of the last displayed point (assuming 0 for the time of the first displayed point)
	endfor


	for ( nCurve = 0; nCurve < nCurves; nCurve += 1 )			
	  	sCurve	= StringFromList( nCurve, sCurves, ksCURVSEP )
		DurAcqDrawTraceAndAxis( sFolder,  w, nCurve, nCurves, sCurve, BegPt, Pts, bIsFirst, nRange, nSmpInt, ResultXShift, LastDataPos )
	endfor	
End


static Function	Range2Pt( sFolder, nRange,  pr, bl, fr, sw, BegPt, EndPt, Pts, bIsFirst )
	string  	sFolder
	variable	nRange,  pr, bl, fr, sw
	variable	&BegPt, &EndPt, &Pts, &bIsFirst
	wave  	wFix		= $"root:uf:" + sFolder + ":ar:wFix"  			
	if ( nRange	== kFRAME )								// (old:sw = -1): one frame is the unit to display
		BegPt		= FrameBegSave( sFolder, pr, bl, fr )	
		EndPt		= FrameEndSave( sFolder, wFix, pr, bl, fr )		// display the whole frame
//		bIsFirst		=  !( fr )
	elseif ( nRange == kPRIM )									// (old sw = -2) : the first sweep in each frame is the unit to display
		BegPt		= FrameBegSave( sFolder, pr, bl, fr )	
		EndPt		= SweepEndSave( sFolder, pr, bl, fr, 0 )		// display only the first sweep of the frame (useful for skipping the PoN correction pulses)
//		bIsFirst		=  !( fr )
	elseif ( nRange == kRESULT )								// (old:sw = -3) : the last sweep in each frame is the unit to display
		BegPt		= SweepBegSave( sFolder, pr, bl, fr, eSweeps( wFix, bl ) -1 )	
		EndPt		= FrameEndSave( sFolder, wFix, pr, bl, fr )		// display only the last = result sweep of the frame (useful for skipping the PoN correction pulses)
//		bIsFirst		=  !( fr )
	else													// nRange	= kSWEEP    and     sw >= 0 : one sweep is the unit to display
		BegPt		= SweepBegSave( sFolder, pr, bl, fr, sw )	
		EndPt		= SweepEndSave( sFolder, pr, bl, fr, sw )
//		bIsFirst		=  !( fr + sw )
	endif
	Pts			= EndPt - BegPt 
	bIsFirst		=  ( fr == 0  &&  sw == 0 )
	// printf "\t\t\tRange2Pt()  trying to draw \t%s\t[nRange:%2d]\tpr:\t%d\tbl:\t%d\tfr:\t%d\tsw:\t%d\t->\tbIsFirst:%2d\tBegPt:\t%7d\tPts:\t%7d\t \r",  pd(RangeNmLong( nRange ),8), nRange,  pr, bl, fr, sw, bIsFirst, BegPt, Pts
End


static  Function		DurAcqDrawTraceAndAxis( sFolder, w, nCurve, nCurves, sCurve, BegPt, Pts, bIsFirst, nRange, nSmpInt, ResultXShift, LastDataPos )	
// If the user changes the AxoPatch Gain the trace in the Acq Display should keep its height but the Y scaling should adjust. This may occur any time during acquisition. The DAT file will reflect the changed gain only at the beginning of thr next data section.
	string  	sFolder, sCurve
	variable	w, nCurve, nCurves, BegPt, Pts, bIsFirst, nRange, nSmpInt, ResultXShift, LastDataPos

	string 	rsChan = "",  rsRGB = ""
	variable	ra, mo, rnInstance, rbAutoScl, rYOfs, rYZoom, rnAxis
	string 	sWNm	= WndNm( w )							

	ExtractCurve( sCurve, rsChan, ra, mo, rnInstance, rbAutoScl, rYOfs, rYZoom, rnAxis, rsRGB )				// parameters are changed
	variable	Gain			= GainByNmForDisplay( sFolder, rsChan )							// The user may change the AxoPatch Gain any time during acquisition

	// printf "\t\t\tDurAcqDrawTraceAndAxis w:%2d\tnCurve:%2d\tpts:\t%7d\trd %d\t %s\t%d r\tut:%2d\trg:%2d  md:%2d\tZm:\t%7.2lf\tOs:\t%9.2lf   \tGn:\t%7.1lf\t Rgb:%s  \r", w, nCurve, pts, nRange , SelectString( nRange == rnRange, "!=", "=="), rnRange, nCurve+1,rnRange, rnMode, ryZoom, rYOfs, Gain, rsRGB

	string  	sFolderTNm	= "root:uf:" + sFolder + ":" + ksF_IO + ":" + rsChan
	if (  Pts > 0   &&   waveExists( $sFolderTNm )   &&    nRange == ra )
		nvar		gResultXShift	= root:uf:disp:gResultXShift
		gResultXShift =  ( ra ==  kRESULT )  ?  ResultXShift  :  0	// 040724

		// 060608
		// avoid passing ncurves, compute nAxes = AxisCnt()  only in  DurAcqDrawXPositionOfYAxis()   STORE nAxis  in sCurve ??? 
		// -> if one axis of one curve is removed or added  the axis index of all other following curves must also change......  or store   nAxisVisible in sCurve
		//
// 060609  OR  string list   lstAxes = "0;1;1;2;"   : curves 1 and 2 share the same axis 1
variable	nAxis	= nCurve
// variable nAxes = nCurves
//variable	nAxis	= Curve2Axis( nCurve )
// variable nAxes = AxisCnt()
		wave  /T	wAxisName	= root:uf:disp:wYAxisName	
		GetAxis/W=$sWNm /Q $wAxisName[ nCurve ]										// check if axis exists
		variable	bRedrawYAxis	= ( V_Flag != 0 )											// remember the fact that there was no such axis before the following 'DurAcqDrawTrace()' , which will construct an automatic axis, which will be repositioned below in 'DurAcqDrawXPositionOfYAxis()' 

		 printf "\t\t\tDurAcqDrawTraceAndAxis()\tbIsFirst:%d  w:%2d/%d \tcv:%2d\tR:%d  M:%d  W:%s  \tO:%s \t'%s'\tpts: %d  smpint: %d  gResultXShift:%7.2lf \tDrawYax:%2d\t'%s..' \r", bIsFirst, w, t,  nCurve, ra, mo, sWNm, rsChan, rsRGB, Pts, nSmpInt, gResultXShift, bRedrawYAxis, sCurve[0,80]
		DurAcqDrawTrace( sFolder, w, nCurve, sWNm, rsChan, BegPt, Pts, bIsFirst, mo, ra, nSmpInt, rsRGB, Gain ) 

		// 060608
		if ( bRedrawYAxis )															// Construct and draw Y axis only when required : i.e. when there is no axis as its traces have been removed (e.g. when a new block starts)
			DurAcqDrawXPositionOfYAxis( sFolder, w, nCurve, nCurves, sWNm, rsChan, Pts, rsRGB, LastDataPos )	
		endif
//		if ( ! rbAutoScl )
		DurAcqRescaleYAxis( nCurve, sWNm, rYOfs, rYZoom, Gain )							// Rescale Y axis (independently of AutoScaling) as often as possible (here : whenever new data are drawn) as the Gain may change any time during acquisition. 
																				// Rescaling the  Y axis depends only on  rYOfs, rYZoom and Gain but not on AutoScaling : when AutoScaling is set ON or OFF  rYOfs and rYZoom are set accordingly.
//		endif	
		//DurAcqRescaleYAxisOld( w, nCurve, sWNm, rsChan, rYOfs, rYZoom, rnAxis, Gain )				// Gain may change any time during acquisition. 
	endif
End

static  Function		DurAcqDrawTrace( sFolder, w, nCurve, sWNm, sTNm, BegPt, Pts, bIsFirst, nMode, nRange, nSmpInt, sRGB, Gain ) 
// MANY Mode 2 : all appended traces have same name,  with /Q Flag,     fixed scales after first sweep.... but display is volatile
// Append: same non-unique wave name for every sweep,   /Q  flag  is used to avoid confusion among the appended waves... 
// Different  data are displayed under the same name, but any operation (e.g. resize window) destroys the data leaving only the last...
	string		sFolder, sWNm, sTNm, sRGB
	variable	w, nCurve, BegPt, Pts, bIsFirst, nMode, nRange, nSmpInt, Gain
	variable	PnDebgDispDurAcq = DebugSection() & kDBG_DispDurAcq
	variable	rnRed, rnGreen, rnBlue

	ExtractColors( sRGB, rnRed , rnGreen, rnBlue )

	string		sTNmUsedNF	= BuildTraceNmForAcqDispNoFolder( sTNm, nMode, nRange, BegPt )			
	string		sTNmUsed 	= BuildTraceNmForAcqDisp( sFolder, sTNm, nMode, nRange, BegPt )	// the wave 'sTNmUsed' contains the data segment from 'sTNm' which is currently to be displayed		
	 printf "\t\t\t\tDurAcqDrawTrace(1)  \t  \t  \t  \t \tmode: %d\tbIs1:%d\tWNm: '%s' \tsTNm:%s ->\t%s  \tUsedTrc[ w:%2d ] = %d \t\t\t\t\t\t\t\t[cnt:%3d]\tTNL1: '%s'  \r", nMode, bIsFirst, sWNm, sTNm, pd(sTNmUsed,22),  w, nCurve+1, ItemsInList( TraceNameList( sWNm, ";", 1 )  ),  TraceNameList( sWNm, ";", 1 )  

	
	CopyExtractedSweep( sFolder, sTNm, sTNmUsed, BegPt, Pts, nSmpInt, Gain )				// We compute the new trace i.e. we update the data in 'sTNmUsed'  no matter whether we actually do 'AppendToGraph' below...
//	wave	wAxisExists	= root:uf:disp:wYAxisExists									// ..during acq the traces are regularly erased, so 'AppendToGraph' either actually draws the first trace in a blank window...
	wave  /T	wAxisName	= root:uf:disp:wYAxisName									// ..or (if it is not the 1. trace) the existing (not erased) trace is given new data....

	// Avoid drawing the same trace multiple times one over the other which impairs performance. This would occur e.g. when moving the YOfs slider. Within seconds hundreds of traces could accumulate... 
	if ( WhichListItem( sTNmUsedNF, TraceNameList( sWNm, ";", 1 ) ) == kNOTFOUND )			// For Redrawing outside acq ( e.g. changed zoom,ofs ) the traces are not erased, they exist : here  we avoid drawing them over and over #1, #2, #3... when the YOfs slider is moved 
		if ( nMode == kMANYSUPIMP   ||   ( nMode == kCURRENT && bIsFirst ) )				// in CURRENT mode the trace is appended only once : IGOR updates automatically
//			wAxisExists[ w ][ nCurve ] = TRUE										// 141102 mark this Y axis as 'displayed'  as  we can later act only on  'displayed'  Y axis
	
			if ( nCurve == 0 ) 													// append the first trace with its Y Axis to the left....
				 AppendToGraph /Q /L 					/W=$sWNm  /C=( rnRed, rnGreen, rnBlue )	 $sTNmUsed
			else																// ..append all other traces with their Y Axis to the right
				// Here the connection is made between a certain trace and its accompanying axis name !  AxisInfo  will return  the name of the controlling wave 
				 AppendToGraph /Q /R=$wAxisName[ nCurve ] /W=$sWNm  /C=( rnRed, rnGreen, rnBlue )	 $sTNmUsed 
			endif
			 printf "\t\t\t\tDurAcqDrawTrace(2) after appending \tmode: %d\tbIs1:%d\tWNm: '%s' \tsTNm:%s ->\t%s  \tUsedTrc[ w:%2d ] = %d \tvalid for nCurve != 0: AxNm: '%s'\t[cnt:%3d]\tTNL1: '%s'  \r", nMode, bIsFirst, sWNm, sTNm, pd(sTNmUsed,22),  w, nCurve+1, wAxisName[ nCurve ], ItemsInList( TraceNameList( sWNm, ";", 1 )  ),  TraceNameList( sWNm, ";", 1 )  
		endif
	endif

	if ( PnDebgDispDurAcq )
		printf "\t\t\tDispDurAcq %s\t\t%s\tWnd:'%-16s' \tOrg:'%-10s'  \tOne:'%-18s'  \tbIsFirst:%d   BegPt:%d  PTS:%d ->pts:%d \r", "A?U", ModeNm( nMode ), sWNm, sTNm, sTNmUsed, bIsFirst, BegPt, Pts, numPnts($ sTNmUsed)
	endif		
	//return	xScl
End

static  Function	/S	BuildTraceNmForAcqDisp( sFolder, sTNm, nMode, nRange, BegPt )
 	string		sFolder, sTNm
 	variable	nMode, nRange, BegPt
	return	"root:uf:" + ksACQ + ":dispFS:" + BuildTraceNmForAcqDispNoFolder( sTNm, nMode, nRange, BegPt )
End

static  Function	/S	BuildTraceNmForAcqDispNoFolder( sTNm, nMode, nRange, BegPt )
 	string		sTNm
 	variable	nMode, nRange, BegPt
 	string		sBegPt
	sprintf	sBegPt, "%d",  BegPt			// formats correctly  e.g. 160000 (wrong:num2str( BegPt ) formats 1.6e+05 which contains dot which is illegal in wave name..) 
	sTNm	= sTNm + BuildMoRaName( nRange, nMode ) + ksMORA_PTSEP		// e.g.Adc0 + SM + _
	
	//  PERSISTENT DISPLAY  requires keeping a list of unique partial waves ( volatile display would be much simpler but vanishes when resizing a graph...)
	// another approach: use block/frame/sweep composed number to uniquely identify the trace
	if (  nMode == kMANYSUPIMP )			// append each trace while not clearing previous ones and  display in a persistent manner: needs a unique name
		// Adding any unique number (e.g. the starting point or the frame/sweep) to the trace name makes the trace name also unique  leading to consequences: 
		// 	1. memory is occupied for each wave, not only for one 	2. the display is no longer  volatile, when window is resized or when anything is drawn
		return	sTNm + sBegPt			// e.g.   Adc0SM_160000 
	else
		return	sTNm				// in CURRENT mode it must be always the same (non-unique) name
	endif
End


static constant	cAXISMARGIN			= .14//.15		// space at the right plot area border for second, third...  Adc axis all of which can have different scales

// 060603 new
static  Function		 DurAcqDrawXPositionOfYAxis( sFolder, w, nCurve, nCurves, sWNm, sTNm, pts, sRGB, LastDataPos )
// 141102 Drawing multiple Y axis is a bit complicated for a variety of reasons:
// - depending on the number of traces / curves in a window, we want to position the axes neatly: the first to the left, all others to the right of the plot area
// - the drawing routine is called in an order determined by the frames and sweeps whenever they are ready to be drawn
// - the window / trace / usedTrace  is independent of the frames / sweeps order  and can (and will most probably) be COMPLETELY mixed up
// This leads to the complex code requiring  much bookkeeping with the help of  YAxisCnt(),  wYAxisExists
// - drawing the axis should be done as seldom as possible: only when really needed that is right in the very first display update
	variable	w, nCurve, nCurves, pts
	variable	LastDataPos								// The time of the last displayed point (assuming 0 for the time of the first displayed point)
	string		sFolder, sWNm, sTNm, sRGB
	string		rsNm, rsUnits
	NameUnitsByNm( sFolder, sTNm, rsNm, rsUnits )								// 040123
// 060609 retrieve right here , do not pass............
variable	nYAxis			= nCurves										// nYAxis   could be less than   nCurves  if an Y axis has been removed perhaps because 2 or more traces share the same Y axis		
	variable	nRightAxisCnt	= nYAxis - 1
//	wave	wAxisExists	= root:uf:disp:wYAxisExists
	wave  /T	wAxisName	= root:uf:disp:wYAxisName
	variable	rnRed, rnGreen, rnBlue
	ExtractColors( sRGB, rnRed , rnGreen, rnBlue )
	variable	v_Min	= 0
	variable	BotAxisEnd	= LastDataPos * ( 1 + nRightAxisCnt * cAXISMARGIN )			// we make the original bottom axis longer to get space for additional Y axis so as if we had more data points

	string		sAxisNm		= wAxisName[ nCurve ] 									// 030610
	 printf "\t\t\t\tDurAcqDrawXPositionOfYAxis()  w:%d  curve:%d   pts:%d  RightAxisCnt:%d   LastDataPos:%g  BotAxisEnd:%g  sAxisNm:'%s' \r", w, nCurve,  pts, nRightAxisCnt, LastDataPos, BotAxisEnd, sAxisNm

	// Prevent  IGOR  from drawing the units (set in 'CopyExtractedSweep()'  automatically instead draw the Y units manually as a Textbox  just above the corresponding Y Axis  in the same color as the corresponding trace  
	// As it seems impossible to place the textbox automatically at the PERFECT position (not overlapping anything else, not blowing up the graph too much: position depends on units length, graph size, font size)  the user may have to move it a bit (which is very fast and very easy)...
	Label  	/W=$sWNm 	$sAxisNm  "\\u#2"									// Prevent  IGOR  from drawing the units

	//  Draw the  Units in a TextBox (rather than letting Igor draw them) .  The textbox has the same name as its corresponding axis: this allows easy deletion together with the axis (from the 'Axes and Scalebars' Panel)
// 	DrawTextboxUnits( sWNm, nCurve, nCurves, ....
// 060606
//	variable	TboxXPos	= 	ut == 1   ? 	-54 : 50 - 20 			*	( nYAxis - ut )		// left, left right,  left mid right...    -54, 50, 20 are magic numbers which  are adjusted  so that the text is at the same  X as the axis. They SHOULD be   #defined.....
	variable	TboxXPos	= nCurve == 0 ? -54 : 46 - 66 * cAXISMARGIN *	( nYAxis - nCurve - 1 )	// left, left right,  left mid right...    -54, 50, 66 are magic numbers which  are adjusted  so that the text is at the same  X as the axis. They SHOULD be   #defined.....
	ModifyGraph	/W=$sWNm axisEnab( $sAxisNm ) = { 0, .96 }						//  supplies a small margin at the top of each Y axis  for the Channel name and the axis units
	TextBox 	/W=$sWNm /C /N=$sAxisNm  /E=0 /A=MC /X=(TboxXPos)  /Y=52  /F=0  /G=(rnRed, rnGreen, rnBlue)   rsNm + "/ " + rsUnits	// print YUnits horiz.  /E=0: rel. position as percentage of plot area size 
	
	// printf "\t\t\t\tDurAcqDrawXPositionOfYAxis()  w:%2d\tut:%2d/%2d \tTboxXPos:%d \t'%s'  \tAxNm:%s \t\r", w, nCurve+1, nYAxis, TboxXPos, rsUnits, pd( sAxisNm,10)

// 060606
	// Demo/Sample code to prevent Igor form switching  the axis ticks  8000, 9000, 9999, 10, 11  (this would be fine if we had not hidden Igors Axis units as they were not located neatly..)
	// Different approach (not taken) : switch  mV -> V , pA -> nA etc. whenever Igor crosses his  'highTrip' value  (default seems to be 10000)
	 ModifyGraph  /W=$sWNm  highTrip( $sAxisNm		 )	=100000					// 031103
	variable	YAxisXPos	
	if ( nCurve > 0 )
		YAxisXPos	= LastDataPos * ( 1 +  (nCurve - 1) * cAXISMARGIN ) 					// here goes the new Y axis (value is referred to bottom axis data values)
		//ModifyGraph	/W=$sWNm axisEnab( bottom ) = { 0, 1- ( nYAxis  >1 ) * .1 }			//  supplies a small margin to the right of the rightmost axis if there is at least  1 right Y axis for the rightmost Y axis numbers    

		 printf "\t\t\t\tDurAcqDrawXPositionOfYAxis(2)\t'%s'\t%s\tut:%d/%d\tRiAxCnt:%d \tbottom axis   v_min:%g, v_Max:%g -> LastDataPos:%g  \tThisAxPos(%s):%4d\tBotAxEnd:%g / %g\r", sWNm, pd(sAxisNm,5), nCurve+1,  nYAxis, nRightAxisCnt, v_min,  1234,  LastDataPos, pad(wAxisName[ nCurve],5),YAxisXPos, BotAxisEnd, 12345
		ModifyGraph /W=$sWNm  freePos( $sAxisNm ) 		= { YAxisXPos, bottom }		// draw the current Y axis at this position (value is referred to bottom axis data values)

		SetAxis	/W=$sWNm 	bottom, v_Min, BotAxisEnd							// make bottom axis longer if there are Y axis on the right (=multiple traces) to be drawn
	endif
End


static  Function		DurAcqRescaleYAxis( nCurve, sWNm, YOfs, YZoom, Gain )	
// Similar to  DurAcqRescaleYAxisOld()  but rather than storing the axis end values, checking for changes and possible rescaling  here no values are stored or checked but the rescaling is done every time (this is much simpler but could be slower...)
	variable	nCurve, YOfs, YZoom, Gain
	string		sWNm
	variable	AdcRange			= 10								//  + - Volt
	variable	yAxis 			= AdcRange * 1000  / YZoom						
	variable	NegLimit			= - yAxis / Gain + YOfs
	variable	PosLimit			=   yAxis / Gain + YOfs
	wave   /T	wAxisName		= root:uf:disp:wYAxisName
	SetAxis /Z /W=$sWNm $wAxisName[ nCurve ],  NegLimit, PosLimit
End

//static  Function		DurAcqRescaleYAxisOld( w, nCurve, sWNm, sChan, YOfs, YZoom, Gain )	
//	variable	w,  nCurve, YOfs, YZoom, Gain
//	string		sWNm, sChan
//	variable	AdcRange			= 10								//  + - Volt
//	variable	yAxis 			= AdcRange * 1000  / YZoom						
//	variable	NegLimit			= - yAxis / Gain + YOfs
//	variable	PosLimit			=   yAxis / Gain + YOfs
//	wave	wYAxisNegLim		= root:uf:disp:wYAxisNegLim
//	wave	wYAxisPosLim		= root:uf:disp:wYAxisPosLim
//	wave	wYAxisLastNegLim	= root:uf:disp:wYAxisLastNegLim
//	wave	wYAxisLastPosLim	= root:uf:disp:wYAxisLastPosLim
//	wave   /T	wYAxisName			= root:uf:disp:wYAxisName
//// 060607
//	wYAxisNegLim[ w ][ nCurve ]	= NegLimit			
//	wYAxisPosLim[ w ][ nCurve ]	= PosLimit
//	if ( wYAxisLastNegLim[ w ][ nCurve ] != wYAxisNegLim[ w ][ nCurve ]   ||   wYAxisLastPosLim[ w ][ nCurve ] != wYAxisPosLim[ w ][ nCurve ] ) 
//		 printf "\t\t\t\tDurAcqRescaleYAxisOld() \tw:%2d \tcv:%2d\tWNm:'%s'\t'%s'\t'%s'\tos:\t%7g\tzo:\t%7g\tyax:\t%7g\tgn:\t%7g\twLast:%g..\t%g\t-> \twLim:%10.2lf...\t%10.2lf\t  \r", w, nCurve, sWNm, wYAxisName[ nCurve ], sChan, YOfs, YZoom, yAxis, Gain, wYAxisLastNegLim[ w ][ nCurve ],wYAxisLastPosLim[ w ][ nCurve ], wYAxisNegLim[ w ][ nCurve ],wYAxisPosLim[ w ][ nCurve ]
//		wYAxisLastNegLim[ w ][ nCurve ]	= wYAxisNegLim[ w ][ nCurve ]
//		wYAxisLastPosLim[ w ][ nCurve ]		= wYAxisPosLim[ w ][ nCurve ] 
//		SetAxis /Z /W=$sWNm $wYAxisName[ nCurve ],  wYAxisNegLim[ w ][ nCurve ], wYAxisPosLim[ w ][ nCurve ]  	
//		//SetMultipleYAxisRange( nCurve, sWNm, wYAxisNegLim[ w ][ nCurve ], wYAxisPosLim[ w ][ nCurve ] )
//	endif
//End

//static  Function		SetMultipleYAxisRange( nCurve, sWNm, NegLimit, PosLimit )
//	variable	nCurve, PosLimit, NegLimit
//	string		sWNm
//	wave  /Z /T	wYAxisName	= root:uf:disp:wYAxisName
//	if ( waveExists( wYAxisName ) ) 		
//		 printf "\t\t\t\tSetMultipleYAxisRange()\tcurve:%2d \t\tWNm:'%s'\tAxisNm[ nCurve:%d ] : '%s'\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\twLim:%10.2lf...\t%10.2lf [PosLim]  \r",  nCurve, sWNm, nCurve,  wYAxisName[ nCurve ], NegLimit, PosLimit
//
//		if ( cmpstr( wYAxisName[ 0 ], "left" ) )
//			FoAlert( ksACQ, kERR_IMPORTANT,  "Axis name error with  nCurve = 0   /   ut = 1 . Should be 'left'  but is  '" + wYAxisName[ nCurve ] + "' . " )  
//		endif
//		SetAxis /Z /W=$sWNm $wYAxisName[ nCurve ],	NegLimit, PosLimit 	
//
//	endif
//End

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

static  Function		ConstructYAxis()
	//	dimensions : 		maximum window number	    x	max traces
//	make	/O /N= ( kMAX_ACDIS_WNDS			      )	root:uf:disp:wYAxisUsedMax	= 0		// maximum number of y axis (which can be less than the number of traces / curves) used in a specific window
//	make	/O /N= ( kMAX_ACDIS_WNDS, kMAXCHANS )	root:uf:disp:wYAxisNegLim		= -5000	// minimum axis end value
//	make	/O /N= ( kMAX_ACDIS_WNDS, kMAXCHANS )	root:uf:disp:wYAxisLastNegLim	= -5000	// minimum axis end value
//	make	/O /N= ( kMAX_ACDIS_WNDS, kMAXCHANS )	root:uf:disp:wYAxisPoslim		=  5000	// maximum axis end value
//	make	/O /N= ( kMAX_ACDIS_WNDS, kMAXCHANS )	root:uf:disp:wYAxisLastPosLim 	=  5000	// maximum axis end value
//	make	/O /N= ( kMAX_ACDIS_WNDS			      )	root:uf:disp:wYAxisBotAxEndMax= -Inf		// bottom axis end point in a specific window
	make	/O /N= ( kMAX_ACDIS_WNDS, kMAXCHANS )	root:uf:disp:wYAxisExists		= 0		// flag telling if the specified trace / curve is already displayed in the window
	make  /T	/O /N= 8 	root:uf:disp:wYAxisName = { "left", "right0", "right1", "right2", "right3", "right4", "right5", "right6" } 
	// printf "\t\tConstructYAxis() \r"
End

// 060302
//static  Function		SetYAxisCnt( w )
//// Store the number of traces / curves for each window  in an Yaxis data structure  (the number of Yaxis is usually just the number of curves but could be less if some traces share the same Yaxis)
//	variable	w
//	wave	wYAxisUsedMax= root:uf:disp:wYAxisUsedMax
//	string 	sCurves		= RetrieveCurves( w )
//	wYAxisUsedMax[ w ]		= ItemsInList( sCurves, ksCURVSEP )
//	// printf "\t\t\tSetYAxisCnt() \t\t\t\t---> wYAxisUsedMax[ w:%2d ]:%d \t'%s' \r", w, wYAxisUsedMax[ w ], sCurves[0,200]
//End
//
//static  Function		YAxisCnt( w )
//// Retieve the number of traces / curves for each window from the Yaxis data structure  (the number of Yaxis is usually just the number of curves but could be less if some traces share the same Yaxis)
//	variable	w
//	wave	wYAxisUsedMax= root:uf:disp:wYAxisUsedMax
//	// printf "\t\t\tYAxisCnt() \t\t\t\t\t---> wYAxisUsedMax[ w:%2d ]:%d  \r", w, wYAxisUsedMax[ w ]		
//	return	wYAxisUsedMax[ w ]		
//End

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

static   Function		CopyExtractedSweep( sFolder, sOrg, sOneDisp, BegPt, nPts, nSmpInt, Gain )
// do not draw all points of wave but only 'nDrawPts' : speed things up much  by loosing a little display fidelity
// going in steps through the original wave makes waveform arithmetic impossible but is still much faster
	string		sFolder, sOrg, sOneDisp									// sOrg   is the same as elsewhere  sTNm
	variable	BegPt, nPts, nSmpInt, Gain
	variable	bHighResolution = HighResolution()
	variable	n, nDrawPts 	 = 1000						// arbitrary value				

	variable	step	= bHighResolution ? 1 :  trunc( max( nPts / nDrawPts, 1 ) )
	//variable	step = trunc( max( nPts / nDrawPts, 1 ) )
	
	string  	sFolderOrg	= "root:uf:" + sFolder + ":" + ksF_IO + ":" + sOrg								
	if ( waveExists( $sFolderOrg ) )								
		wave	wOrgData	= $sFolderOrg
		make    /O /N = ( nPts / step )	$sOneDisp						//( "root:uf:acq:tmp:"  + sOneDisp )
		wave	wOneDispWaveCur = $sOneDisp						//( "root:uf:acq:tmp:"  + sOneDisp )

		// 030610 new   it should be sufficient to do this only once during initialization
		string 	sUnits	=  UnitsByNm( sFolder, sOrg )							// Store the Y units of the wave within the wave to make it accessible for 'Scalebars()'...
		SetScale /P y, 0, 0,  sUnits,  wOneDispWaveCur						//..while at the same time prevent Igor from drawing them   ( Label...."\\u#2" ) 

		SetScale /P X, 0, nSmpInt / kXSCALE * step, ksXUNIT, wOneDispWaveCur 	// /P x 0, number : expand in x by number (Integer wave: change scale from points into ms using the SmpInt)
		// printf "\t\t\t\t\tDispDurAcq() CopyExtractedSweep() '%s' \t%s\tBegPt:\t%8d\tPts:\t%8d\t   DrawPts:%d  step:%d  xscl:\t%10.4lf\txfactor:%g   Gain:%g \tsize:%.2lf=?=%d  sizeOrg:%d \r", sFolderOrg, pd( sOneDisp, 26), BegPt, nPts, nDrawPts, step, nSmpInt / kXSCALE * step, nSmpInt / kXSCALE*step, Gain, nPts/step, numPnts($sOneDisp), numPnts( $sOrg )
// 040209
// WRONG  for ( n = 0; n <   nPts; 		n += step )		// 040209 WRONG:  wFloat tries to write  into the next after the LAST element , which does no harm in IGOR but crashes the XOP
// 		   for ( n = 0; n <= nPts - nStep; 	n += step )
//		 	wOneDispWaveCur[ n / step ] = wOrgData[ BegPt + n ] /  Gain
//		   endfor
		variable	code	= xUtilWaveExtract( wOneDispWaveCur, wOrgData, nPts, BegPt, step, 1/Gain )			// XOP because Igor is too slow  ,   Params: float tgt. float src, nPnts...
		if ( code )
			printf "****Error: xUtilWaveExtract() \r"
		endif

	endif
End

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

static Function	/S	Nm2Color( sFolder, sTNm )
// Retrieves and returns 'RGB' entry from script when the channel name is given,  e.g. 'Adc0'  or  'Dac2'
	string 	sFolder, sTNm
	wave  /T	wIO		 = $"root:uf:" + sFolder + ":ar:wIO"  				
	variable	nIO, c
	Nm2NioC( wIO, sTNm, nIO, c )
	string	 	sColor		= ios( wIO, nIO, c, cIORGB )
	// printf "\t\tNm2Color( \t\t\t%s, %s ) :  '%s'  ? '%s'  \r", sFolder, sTNm, sUnit, sUnit1
	return	sColor
End

static Function	/S	UnitsByNm( sFolder, sTNm )
// Retrieves and returns 'Units' entry from script when the channel name is given,  e.g. 'Adc0'  or  'Dac2'
	string 	sFolder, sTNm
	wave  /T	wIO		 = $"root:uf:" + sFolder + ":ar:wIO"  				
	variable	nIO, c
	Nm2NioC( wIO, sTNm, nIO, c )
	string	 	sUnit		= ios( wIO, nIO, c, cIOUNIT )
	// printf "\t\tUnitsByNm( \t\t\t%s, %s ) :  '%s'  ? '%s'  \r", sFolder, sTNm, sUnit, sUnit1
	return	sUnit
End

static Function		NameUnitsByNm( sFolder, sTNm, rsName, rsUnit )
// Retrieves and passes back  'Name'  and   'Units'  entry from script when the channel name is given,  e.g. 'Adc0'  or  'Dac2'
	string 	sFolder, sTNm
	string 	&rsName, &rsUnit
	wave  /T	wIO		 = $"root:uf:" + sFolder + ":ar:wIO"  				
	variable	nIO, c
	Nm2NioC( wIO, sTNm, nIO, c )
	rsUnit	= ios( wIO, nIO, c, cIOUNIT )
	rsName	= ios( wIO, nIO, c, cIONAME )
	// 060608
	if ( strlen( rsName ) == 0 )						// if the user has not specified the name of the channel in the script (e.g Dac: Chan=0; Name=Stimulus0; ... )
		rsName	= ios( wIO, nIO, c, cIONM )			//...then the simple inherent name  'Dac0'  or  'Adc1'   or similar is used.
	endif
	// printf "\t\tNameUnitsByNm( \t%s , %s) :  '%s'  ? '%s'  :  '%s'  ? '%s'  \r", sFolder, sTNm, rsUnit, rsUnit1, rsName, rsName1
	// todo : possibly return bFound = kNOTFOUND  to distinguish between  'Entry was empty' (it not returning default)  and   'NoMatchingTraceFound'  (actually the latter should not occur)
End

Function		GainByNmForDisplay( sFolder, sTNm )
// Retrieves and returns gain for displaying traces  when the channel name is given,  e.g. 'Adc0'  or  'Dac2'
// The DISPLAY Gain for Dacs is always 1 no matter what the script gain is  as the script  Dac gain effects only the voltage output, not the displayed traces.
// The display of  Adc  and  PoN  traces is effected by their gain.   [ Exotic traces traces like  'Aver'  or  'Sum'   (not yet used)   are also effected by their gain, this behaviour could in the future be changed here...
	string 	sFolder, sTNm
	variable	Gain		= 1
	variable	nIO, c
	wave  /T	wIO		= $"root:uf:" + sFolder + ":ar:wIO"  						// This  'wIO'  is valid in FPulse ( Acquisition )
	Nm2NioC( wIO, sTNm, nIO, c )
	string 	sSrc		= "none"
	if ( IsDacTrace( sTNm ) )
		Gain	= 1								// For displaying Dac traces we must ignore the Gain. The Dac gain effects only the voltage output, not the displayed traces.
	elseif ( IsPoNTrace( sTNm ) )
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

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Action procedure called whenever the AxoPatch gain setting in the FPulse main panel is changed 

Function		fGain( s )
// Store the gain just set by the user in 'wIO' . This is needed  in WriteCFS .
	struct	WMSetvariableAction  &s
	variable	nIO		= kIO_ADC
	variable	c		= RowIdx( s.ctrlname )										// c : the linear Adc index in script passed with the variable name as postfix
	variable	Gn		= s.dval
	string  	sFolder	= ksACQ
	wave  /T	wIO		= $"root:uf:" + sFolder + ":ar:wIO"  								// This  'wIO'	is valid in FPulse ( Acquisition )
	ioSet( wIO, nIO, c, cIOGAIN, num2str( Gn ) )						
	printf "\t\tfGain()  \t\tsControlNm: %s   \tvarName:%s   \t\t:setting wIO[ nIO:%d, c:%d cIOGAIN ] =%g\t=?= %g \t'%s'\r", s.ctrlname,  s.vName , nIO, c, Gn, iov( wIO, nIO, c, cIOGAIN ),  ios( wIO, nIO, c, cIONM )
	
	// The new Gain has now been set and will be effective during the next acquisition, but for the user to see immediately that his change has been accepted....
	PossiblyAdjstSliderInAllWindows( sFolder )											//....we change the slider limits in all windows which contain this AD channel   ( this is optional and could be commented out )
// 060607
//	DisplayOffLineAllWindows( sFolder  )												// This is to display a changed Y axis in all windows which contain this AD channel   ( could probably be done simpler and more directly.....)
	// The new Gain will be effective during the next acquisition, but to immediately give some feedback to the user that his Gain change has been accepted we change the Y Axis range in every instance of 'sChan' in all windows 
	string  	sChan	= ios( wIO, nIO, c, cIONM )										// e.g 'Adc1'
	variable	Gain		= GainByNmForDisplay( sFolder, sChan )							// The user may change the AxoPatch Gain any time during acquisition
	variable	w
	for ( w = 0; w < kMAX_ACDIS_WNDS; w += 1 )
		string  	sWNm	= WndNm( w )
		string  	sCurves	= RetrieveCurves( w )
		if ( WinType( sWNm ) == kGRAPH )
			string  	sTNL			= TraceNameList( sWNm, ";", 1 )
			string  	sMatchingTraces	= ListMatch( sTNL, sChan + "*" )					// e.g. 'Adc1SC_;Adc1FM_1000;Adc1xxxx;'  : any mode and any range 	
			variable	mt, nMatchingTraces	= ItemsInList( sMatchingTraces )
			string  	rsRGB													// parameters are set by  ExtractCurve()
			variable	ra, mo, rnInstance, rbAutoscl, rYOfs, rYZoom, rnAxis					// parameters are set by  ExtractMoRaName()  and  ExtractCurve()
			for ( mt = 0; mt < nMatchingTraces; mt += 1 )
				string  	sTNm	= StringFromList( mt, sMatchingTraces )				// e.g. 'Adc1SC_'  or  'Adc1FM_1000'
				string  	sMoRa	= sTNm[ strlen( sChan ), strlen( sChan ) + 1 ] 			// e.g. 'SC'  or  'FM'
				ExtractMoRaName( sMoRa, ra, mo )
//				variable	nCurve	= WhichCurve( sCurves, ksCURVSEP, sChan, mo, ra )
//				string  	sCurve	= StringFromList( nCurve,  sCurves, ksCURVSEP )		//  'sCurves' contains the parameters of all windows and all traces, which are valid at any time as they are updated whenever any parameter is changed.
//				ExtractCurve1( sCurve, sChan, ra, mo, rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB )			// The remaining (now valid) parameters 'rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB' are extracted from 'sCurve/sCurves' . 
				variable  	nCurve	= ExtractCurves( sCurves, sChan, ra, mo, rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB )// Extract fom 'sCurves' the one and only curve 'nCurve' with matching ' sChan, ra, mo' and from this the remaining (now valid) parameters 'rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB' 
				//ExtractCurve( sCurve, sChan, ra, mo, rnInstance, rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB )	// Now all parameters extracted from 'sCurve' are valid as 'sCurve' is extracted from 'sCurves' which always contains currently valid values
				//DurAcqRescaleYAxisOld( w, nCurve, sWNm, sChan, rYOfs, rYZoom, rnAxis, Gain )
			variable	nAxis	= nCurve
				DurAcqRescaleYAxis( nCurve, sWNm, rYOfs, rYZoom, Gain )
			endfor
		endif
	endfor
End

Function	/S	AxoGainControlName( row ) 
	variable	row
	return	"root_uf_acq_pul_svAxogain00" + num2str( row ) + "0"
End
Function		SetAxoGainInPanel( row, Gain ) 
	variable	row, Gain
	nvar		 Gn	= $"root:uf:acq:pul:svAxogain00" + num2str( row ) + "0"
	Gn	= Gain
End

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function		KillTracesInMatchingGraphs( sMatch )
	string 		sMatch
	string 		sDeleteList	= WinList( sMatch,  ";" , "WIN:" + num2str( kGRAPH ) )		// 1 is graph
	variable	n
	// kill all matching windows
	for ( n =0; n < ItemsInList( sDeleteList ); n += 1 )
		string  	sWNm	= StringFromList( n, sDeleteList ) 
		RemoveTextBoxUnits( sWNm ) 	// Must remove TextboxUnits BEFORE the traces/axis as they are linked to the axis. If 'Units' had not to be drawn separately (as perhaps only in Igor4?)  the clearing would occur automatically together with the traces
		EraseTracesInGraph( sWNm )
	endfor
End

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

static  Function		RemoveTextBoxPP( sWNm )
	string	sWNm
	// remove the 'PreparePrinting'  textbox  from the given  acq window
	TextBox	/W=$sWNm   /K  /N=$TBNamePP()
End

static  Function		RemoveTextBoxUnits( sWNm )
// remove all  yUnits textboxes from the given  acq window (they must have the same name as the corresponding axis)
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

static  Function		RemoveAcqTraces( sWNm )
// erases all traces in this window (must exist)  and  brings window to front  
	string 	sWNm
// 060509
//	EraseTracesInGraphExceptOld( sWNm, ksOR )					// 'or'   excludes  Online results
	EraseTracesInGraphExcept( sWNm, ksOR+";"+ksCSR+";"+ksORS ) 	// only erase data units traces, but leave cursors and OLA results ???????
	DoWindow /F $sWNm					// bring to front
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

// currently not used 060519
//Function		GetFinalSweepNr(  wG, wFix )
//	wave  	 wG, wFix
//	variable	b, f, SweepCnt = 0
//	for ( b  = 0; b < eBlocks( wG ); b += 1 )
//		for ( f = 0; f < eFrames( wFix, b ); f += 1)
//			SweepCnt += eSweeps( wFix, b )
//		endfor
//	endfor
//	// print "GetFinalSweepNr()", SweepCnt,	vGet( "Sweeps", "N" ) * vGet( "Frames", "N" ) 	// PULSE only
//	return	SweepCnt
//End


//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//   ACQUISITION  WINDOW  HOOK  FUNCTION

Function		 fAcqWndHook( s )
// Here we handle all user actions (=mouse events)  executed in any  acquisition window.
// Executed whenever the mouse is moved within one of the acquisition windows. Gets mouse position in pixels and computes wave and cursor values in axis coordinates which are displayed in the Panel.
	struct  	WMWinHookStruct  &s
	string  	sFolders		= ksF_ACQ_PUL					// 'acq:pul'
	wave	wCurRegion	= $"root:uf:" + sFolders + ":wCurRegion"	// 060330
	nvar		gCursX		= root:uf:acq:pul:svCursorX0000
	nvar		gCursY		= root:uf:acq:pul:vdCursorY0000

	variable	nReturnCode	= 0								// 0 if nothing done, else 1 or 2 (prevents killing)
	variable	w, wCnt

	variable 	isClick	= ( s.eventCode == kWHK_mouseup ) + ( s.eventCode == kWHK_mousedown )	// a click is either a MouseUp or a MouseDown (recognised only IN graph area, not on title area)
	
	// Transform mouse pixels into axis coordinates and store globally (needed always as it is displayed in the StatusBar)	
	gCursX	= numType( s.mouseLoc.h ) != kNUMTYPE_NAN ? AxisValFromPixel( s.winName , "bottom", s.mouseLoc.h  ) : 0
	gCursY	= numType( s.mouseLoc.v ) != kNUMTYPE_NAN ? AxisValFromPixel( s.winName , "left",       s.mouseLoc.v ) : 0

	// To speed things up, we quit immediately when the event  is MOUSEMOVE (which is almost always the case)
	// We proceed only for the rarely occuring MOUSEUP and MOUSEDOWN events which are the only events processed below
	// printf "\t\tfAcqWndHook event (including 'mousemoved' ):'%s'   \t in wnd '%s'  (wCnt:%d) \r", s.eventName, sWnd, WndCnt()

	if ( s.eventCode	== kWHK_mousemoved )
		 // printf "\tfAcqWndHook(9 : returning prematurely (only mouse moves)  Time: %s\r", Time()
		return 0 
	endif
	// printf "\t\tfAcqWndHook event (except 'mousemoved' ):%s \t in wnd '%s'  (wCnt:%d) [KeyModifier:%d]  Cursors: %g / %g \r", pd(s.eventName,11), s.winName, WndCnt(), s.eventMod, gCursX, gCursY

	//  MOUSE  PROCESSING  // here  060330
	if( isClick )												// can be either mouse up or mouse down
		wCurRegion[ cXMOUSE ]	= gCursX						// last clicked x is needed for 'FindAndMoveClosestCursor()' . This allows selection of cursors in different regions  with only 1 button/cursor
	endif	

	// Adjust the YOfs slider size to the graph size whenever the graph is resized
	w	= WndNr( s.winName ) 
	if ( s.eventCode	== kWHK_resize )
		variable	bAcqControlbar = AcqControlBar( w )

		string  	sCurves, sChan, rsRGB
		variable	nCurve, ra, mo, rnInstance, rbAutoscl, rYOfs, rYZoom, rnAxis
		string  	sCurve 		= GetUserData( 	s.winName,  "",  "sCurve" )						// Get UD sCurve 
		ExtractCurve( sCurve, sChan, ra, mo, rnInstance, rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB )		// here only 'rsChan, ra, mo'  are extracted from 'sCurve' , the remaining parameters contain old invalid values (as 'sCurve' has been set only once when the controlbar was constructed)
		sCurves	= RetrieveCurves( w )
//		nCurve	= WhichCurve( sCurves, ksCURVSEP, rsChan, mo, ra )
//		sCurve	= StringFromList( nCurve,  sCurves, ksCURVSEP )							//  'sCurves' contains the parameters of all windows and all traces, which are valid at any time as they are updated whenever any parameter is changed.
//		//ExtractCurve( sCurve, sChan, ra, mo, rnInstance, rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB )	// Now all parameters extracted from 'sCurve' are valid as 'sCurve' is extracted from 'sCurves' which always contains currently valid values
//		ExtractCurve1( sCurve, sChan, ra, mo, rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB )				// The remaining (now valid) parameters 'rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB' are extracted from 'sCurve/sCurves' . 
		nCurve	= ExtractCurves( sCurves, sChan, ra, mo, rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB )	// Extract fom 'sCurves' the one and only curve 'nCurve' with matching ' sChan, ra, mo' and from this the remaining (now valid) parameters 'rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB' 

		variable	bDisableCtrlOfs	= DisableCtrlZoomOfs(   sChan, bAcqControlbar, rbAutoscl ) 

		string  	sFolder		= StringFromList( 0, sFolders, ":" )							// 'acq:pul'  ->  'acq'
		variable	Gain			= GainByNmForDisplay( sFolder, sChan )
		ConstructCbSliderYOfs( s.winName, bDisableCtrlOfs, rYOfs, Gain )							// Construct the optional Controlbar on the right (only in Igor5+) 
	endif

	return	nReturnCode						// 0 if nothing done, else 1 or 2 (prevents killing)
End


//=====================================================================================================================================
//      AFTER  ACQ :   DISPLAY  RESULT  TRACES   after the Acquisition has finished

Function		fDisplayRaw( s )
// Called only when a button is pressed  on MouseUp 
	struct	WMButtonAction &s
	DisplayRawAftAcq()
End

static Function	DisplayRawAftAcq()
// displays  COMPLETE  traces  AFTER  acquisition is  finished (displays complete waves, all sweeps and frames in one trace) 
// too slow when every point is checked (whether it lies within or outside a SAVE period) and drawn: decimating to 'nDrawPts'
	string  	sFolder	= ksACQ
	wave  	wG		= $"root:uf:" + sFolder + ":" + ksKPwg + ":wG"  	// This  'wG'  	is valid in FPulse ( Acquisition )
	wave  /T	wIO		= $"root:uf:" + sFolder + ":ar:wIO"  			// This  'wIO'   	is valid in FPulse ( Acquisition )
	wave 	wFix		= $"root:uf:" + sFolder + ":ar:wFix"  			// This  'wFix'  	is valid in FPulse ( Acquisition )
	variable	bDisplayAllPtsAA	= DisplayAllPointsAA()
	variable	nSmpInt			= SmpInt( sFolder )
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
			step		= bDisplayAllPtsAA ? 1 :  trunc( max( nPts / nDrawPts, 1 ) )
	 		 printf "\t\tDisplayRawAftAcq() nIO:%d   c:%d   %s     %s  \tnSmpInt:%d    \tnPnts:%5d\t DrawPts%4d \tstep:%3d  (bDspAllPts:%2d) \r", nIO,c,  sTNm, sFolderTNm, nSmpInt, nPts, nDrawPts, step, bDisplayAllPtsAA
	
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
			DoWindow  /K $( ksAFTERACQ_WNM + "_" + sTNm ) 				// kill   window  'AfterAcq_xxx'
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


//=====================================================================================================================================
//    AFTER  ACQ : APPLYING  FINISHING  TOUCHES  TO  'DURING'  ACQUISITION   TRACES   

Function		fPrepPrint( s )
	struct	WMButtonAction	&s
	string  	sFolder	= ksACQ
	PreparePrinting( sFolder )
End

static Function	PreparePrinting( sFolder ) 
// apply finishing touches to during-acquisition-graphs:
// supply all data points skipped during acquisition for speed reasons, supply file name and date, supply comment1
	// Print Date()					// prints   Di, 3. Sep 2002		depending on regional settings of operating system
	// Print Secs2Date(DateTime,0)	// prints   3/15/93  or 15.3.1993	depending on regional settings of operating system
	// Print Secs2Date(DateTime,1)	// prints   Monday, March 15, 1993
	// Print Secs2Date(DateTime,2)	// prints   Mon, Mar 15, 1993
	string  	sFolder
	string 	ctrlName

	// Version 1 : use current  comment  without opening Dialog field
	string		sComment1	= GeneralComment()
	// Version 2 : always open Comment Dialog field
	// string	sComment1	= GetComment1()

	string		sFileTraceDateTimeComment, sWNm, sTrc1Nm
	svar		sScriptPath	= root:uf:acq:pul:gsScrptPath0000

	variable	w,  wCnt	= WndCnt()
	for ( w = 0; w < wCnt; w += 1 )										
		sWNm	= WndNm( w )
		if ( WinType( sWNm ) == kGRAPH )
			// todo: if there are multiple different traces in the window (user has copied) then give each trace its own name tag
			sTrc1Nm	= StringFromList( 0, TraceNameList( sWNm, ";", 1 ) )			// get the first trace in the window e.g. Adc0SM_0
			sTrc1Nm	= sTrc1Nm[ 0, strsearch( sTrc1Nm, ksMORA_PTSEP, 0 ) - 1 ]// truncate the separator and the point e.g. Adc0SM
			// Format all items except comment in one line, comment in a second line below
			sFileTraceDateTimeComment	= GetFileName() + "    (" + StripPathAndExtension( sScriptPath ) + ")    " + sTrc1Nm + "    " + Secs2Date(DateTime,0) + "    " + time() + "\r" + sComment1
			TextBox	/W=$sWNm  /C  /N=$TBNamePP()  /E=1  /A=LT  /F=0  sFileTraceDateTimeComment	// print  text  into the window /E=1: rel. wnd border as percentage of window size 
			// printf "\t\tPreparePrinting()  w:%2d/%2d \t%s \t%s \r", w, wCnt, sWNm, sFileTraceDateTimeComment
		endif
	endfor
	//DoUpdate  // does not work    todo: adjust scale size automatically to make room for the text box

	// Run  OFFLINE  through complete display to improve fidelity. Actually in most cases the early (and later overwritten) traces could be skipped here... 
	//? Flaw: If acq was not in HiRes and if subsequently HiRes is turned on, then LoRes traces will not be changed to HiRes by PreparePrinting()..... 
	//? todo  what if user STOPed acquisition prematurely (not all traces up to eFrames(), eSweeps()  exist ????
	variable bHighResolution = HighResolution()
	if ( ! bHighResolution )	
		bHighResolution	= TRUE
		for ( w = 0; w < wCnt; w += 1 )										
			DisplayOffLine( sFolder, w )
		endfor
		bHighResolution	= FALSE
	endif
	return 0
End

static Function	DisplayOffLine( sFolder, w )
	string  	sFolder
	variable	w
	wave  	wG		= $"root:uf:" + sFolder + ":" + ksKPwg + ":wG"  						// This  'wG'	is valid in FPulse ( Acquisition )
	wave  	wFix		= $"root:uf:" + sFolder + ":ar:wFix"  								// This  'wFix'	is valid in FPulse ( Acquisition )
	variable	b,  bCnt	= eBlocks( wG )
	string  	sWNm	= WndNm( w )
// 060602
//	SetYAxisCnt( w )
	if ( WinType( sWNm ) == kGRAPH )
		for ( b  = 0; b < eBlocks( wG ); b += 1 )
			// printf "\t\t\tDisplayOffLine( \tw:%2d\t%s )   Block:%2d / %2d  has Frames:%2d  Sweeps:%2d \r",  w, sWNm, b, eBlocks( wG ), eFrames( wFix, b ), eSweeps( wFix, b )

			RemoveTextBoxPP( sWNm )		// remove any old PreparePrinting textbox. Alternate approach: keep the textbox but then update its contents (=time, file name) permanently
			RemoveTextBoxUnits( sWNm )		// 040109  possibly so often not necessary, only necessary at 1. block ..? ( also removes PreparePrinting Textbox, should not..)
			RemoveAcqTraces( sWNm )		// and bring windows to front

			variable	f,  fCnt	=  eFrames( wFix, b )
			for ( f = 0; f < fCnt; f += 1 )
				variable	s,  sCnt	=  eSweeps( wFix, b )
				for ( s = 0; s < sCnt; s += 1 )
					DispDuringAcq( sFolder, w, wFix, 0, b, f, s, kSWEEP )	// 031008 p=0 : not really protocol aware
				endfor 
				DispDuringAcq( sFolder, w, wFix, 0, b, f, 0, kFRAME )	
				DispDuringAcq( sFolder, w, wFix, 0, b, f, 0, kPRIM )		
				DispDuringAcq( sFolder, w, wFix, 0, b, f, 0, kRESULT )	
			endfor
		endfor
	endif
End

//static Function		DisplayOffLineAllWindows( sFolder )	
//	string  	sFolder
//	variable	w, wCnt	= WndCnt()
//	for ( w = 0; w < wCnt; w += 1 )
//		// 060602
//		//nvar		gPrevBlk	= root:uf:acq:pul:svPrevBlk0000; gPrevBlk  = -1	// this enforces ConstructYAxis()
//		DisplayOffLine( sFolder, w )		 							//....we change the Y Axis range in all windows which contain this AD channel
//	endfor
//End	

Static  Function  /S	TBNamePP()
	return	"TbPP"
End

//=====================================================================================================================================
//    DISPLAY   ACQUISITION   TRACES   ( USED DURING ACQUISITION )

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//  Implementation   of  the  acq window location as  a  2dim  wave WLoc

static Function		MakeWnd( wCnt )
	variable	wCnt
	MakeWLoc( wCnt )
	MakeWA( wCnt )
End

static Function		RedimensionWnd( wCnt )
	variable	wCnt
	RedimensionWA( wCnt )
	RedimensionWLoc( wCnt )
End

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

static Function		MakeWLoc( wCnt )
	variable	wCnt
	make	/O	/N=( wCnt, cWNDLASTENTRY )	root:uf:disp:wWLoc
End

static Function		RedimensionWLoc( wCnt )
	variable	wCnt
	redimension /N = ( wCnt, cWNDLASTENTRY )	root:uf:disp:wWLoc
End

static Function   WndCnt()
	wave   /Z 	wWLoc = root:uf:disp:wWLoc
	return  waveExists( wWLoc )  ? dimSize( wWLoc, 0 ) : 0	// can be called without harm even before the wave has been constructed
End

static Function		SetWndLoc( w, border, value )
	variable	w, border, value
	wave   	wWLoc = root:uf:disp:wWLoc
	wWLoc[ w ][ border ]	= round( value )
End

static  Function	WndLoc( w, border )
	variable	w, border
	wave   	wWLoc = root:uf:disp:wWLoc
	return	wWLoc[ w ][ border ]
End

static Function		SetWndCorners( w, nLeft, nTop, nRight, nBot )
	variable	w, nLeft, nTop, nRight, nBot
	SetWndLoc( w , cLFT,  nLeft )
	SetWndLoc( w , cTOP,  nTop )
	SetWndLoc( w , cRIG,  nRight )
	SetWndLoc( w , cBOT, nBot )
End

static Function		RetrieveWndCorners( w, rnLeft, rnTop, rnRight, rnBot )
	variable	w
	variable	&rnLeft, &rnTop, &rnRight, &rnBot
	rnLeft	= WndLoc( w, cLFT )
	rnTop	= WndLoc( w, cTOP )
	rnRight	= WndLoc( w, cRIG )
	rnBot	= WndLoc( w, cBOT )
	// printf "\t\tRetrieveWndCorners( w:%d  -> rnLeft:%d , rnTop:%d , rnRight:%d , rnBot:%d  ) \r", w, rnLeft, rnTop, rnRight, rnBot
End

//=====================================================================================================================================
//  Implementation   of  the  Trace/Window  structure as  a  1dim  text wave WA

Function  /S 	WndNm( w )
	variable	w
	return	ksW_WNM + num2str( w )
End

  Function 		WndNr( sWndNm )
// return the window number
	string 	sWndNm
	return	str2num( sWndNm[ strlen(ksW_WNM), Inf ] )
End


 Function		AcqWndCnt()
	wave   /T	wv = root:uf:disp:wWA
	return	numPnts( wv )
End

static  Function		MakeWA( wCnt )
	variable	wCnt
	make  /T	/O  /N=( 	wCnt )	root:uf:disp:wWA
End

static Function		RedimensionWA( wCnt )
	variable	wCnt
	redimension /N = (	 wCnt )	root:uf:disp:wWA
End

static Function		StoreCurves( w, sCurves )
// fill WA : each window can have multiple traces which can have multiple curves
	variable	w
	string	 	sCurves
	wave   /T	wv = root:uf:disp:wWA

// 060608  ONLY TEST -  ERROR debugging   GN!!!!!!!!
//	sCurves	= RemoveEnding( sCurves, ksCURVSEP ) + ksCURVSEP	// append trailing separator if it was missing
// 060608  ONLY TEST -  ERROR debugging   GN!!!!!!!!
//	sCurves	= RemoveEnding( sCurves, ksCURVSEP ) 				// remove trailing separator if there was one
		
	wv[ w ] = sCurves
	 printf "\t\t\t\tStoreCurves( w:%2d/%2d\t'%s' ) \r", w, DimSize( wv, 0 ), wv[ w ]
End

static Function   /S	RetrieveCurves( w )
	variable	w
	wave   /T	wv = root:uf:disp:wWA
	// printf "\t\t\t\tRetrieveCurves( w:%d/%d)\t= '%s' \r", w, DimSize( wv, 0 ), wv[ w ]			// e.g. w:1	= 'Adc1;FM;1;UnitsUnUsed;(0,53248,0);0;0;1|Dac0;FC;1;UnitsUnUsed;(40000,0,40000);0;0;1' 
	return	wv[ w ]
End

Function			ClearWA( wCnt )
	variable	wCnt
	redimension /N = (	 wCnt )	root:uf:disp:wWA
	wave   /T	wv = root:uf:disp:wWA
	wv = ""
End
	

// 051219    todo   AVOID  SEARCHING
Function   /S	FindFirstWnd( ch )	
// Return the name of the lowest-index acquisition window containing 'sChan' (=ch)  . There may be windows with higher index also containing 'sChan'
	variable	ch
	string	  	sChan	= StringFromList( ch, LstChAcq(), ksSEP_TAB )	// e.g.   'Adc1'
	variable	w, wCnt	= AcqWndCnt()
	for ( w = 0; w < wCnt; w += 1 )
		string  	sCurve	= RetrieveCurves( w )
		variable	t, tCnt	= ItemsInList( sCurve, ksCURVSEP )		// e.g. 2  for separator '|'  :  'Adc1;FM;1;UnitsUnUsed;(0,53248,0);0;0;1|Dac0;FC;1;UnitsUnUsed;(40000,0,40000);0;0;1' 
		for ( t = 0; t < tCnt; t += 1 )
			string  sTrace	= StringFromList( t, sCurve, ksCURVSEP )	// e.g. 'Adc1;FM;1;UnitsUnUsed;(0,53248,0);0;0;1'   or  'Dac0;FC;1;UnitsUnUsed;(40000,0,40000);0;0;1' 
			if ( cmpstr( sChan, StringFromList( 0, sTrace ) ) == 0 )		// e.g. 'Adc1'  matches trace 0 
				return	WndNm( w )						// the lowest-index window containing 'sChan' . There may be windows with higher index also containing 'sChan'
			endif
		endfor
	endfor
	return ""
End


//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// 	IMPLEMENTATION  TEST  FUNCTIONS

Function		ShowTrcWndArray()
	ShowWndCorners()
	ShowWndCurves( 0 )
End

static Function	ShowWndCorners()
	variable	w
	printf "\t\tShowWndCorners(1) \r"
	for ( w = 0; w < WndCnt();  w += 1 )
		ShowWndCorner( w )
	endfor
End

static Function	ShowWndCorner( w )
	variable	w
	printf "\t\t\tWndCorner( w:%2d ) \tL:%3d  \tT:%3d  \tR:%3d  \tB:%3d   \r", w, WndLoc( w, cLFT ), WndLoc( w, cTOP ), WndLoc( w, cRIG ), WndLoc( w, cBOT )//, WndUsersTrace( w )
End

 Function	ShowWndCurves( nIndex )
	variable	nIndex
	variable	w,	 wCnt	= WndCnt()
	for ( w = 0; w < wCnt; w += 1 )						// loop thru windows
		 printf "\t\t\tShowWndCurves(%d)\tW:%2d/%2d\t%s\r" , nIndex, w,  wCnt , RetrieveCurves( w )
	endfor
End



//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Implementation   of  the  Mode/Range, color, yZoom, Units, RGB...  as  a  string

// NEVER change the ordering as this would break all existing DCF files. Appending entries is OK, though.
constant	cTNM = 0, cMORA = 1, cYZOOM = 2, csUNITS = 3, csRGB = 4, cYOFS = 5, cnINSTANCE = 6, cbAUTOSCL = 7, cAXIS = 8	


Function		UpdateCurves( w, nIndex, sValue, sCurve, sChan, ra, mo, rnInstance, rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB )	
	variable	w, nIndex
	string  	sValue, sCurve
	string  	&sChan, &rsRGB
	variable	&ra, &mo, &rnInstance, &rbAutoscl, &rYOfs, &rYZoom, &rnAxis 
	string 	sCurves
	variable	nCurve
	ExtractCurve( sCurve, sChan, ra, mo, rnInstance, rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB )		// here only 'rsChan, ra, mo'  are extracted from 'sCurve' , the remaining parameters contain old invalid values (as 'sCurve' has been set only once when the controlbar was constructed)
	sCurves	= RetrieveCurves( w )
//	nCurve	= WhichCurve( sCurves, ksCURVSEP, rsChan, mo, ra )
//	sCurve	= StringFromList( nCurve,  sCurves, ksCURVSEP )							//  'sCurves' contains the parameters of all windows and all traces, which are valid at any time as they are updated whenever any parameter is changed.
//	//ExtractCurve( sCurve, rsChan, ra, mo, rnInstance, rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB )	// Now all parameters extracted from 'sCurve' are valid as 'sCurve' is extracted from 'sCurves' which always contains currently valid values
//	ExtractCurve1( sCurve, rsChan, ra, mo, rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB )				// The remaining (now valid) parameters 'rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB' are extracted from 'sCurve/sCurves' . 
	nCurve	= ExtractCurves( sCurves, sChan, ra, mo, rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB )	// Extract fom 'sCurves' the one and only curve 'nCurve' with matching ' sChan, ra, mo' and from this the remaining (now valid) parameters 'rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB' 
	
	switch ( nIndex )
		case	cbAUTOSCL:
			rbAutoscl			= str2num( sValue )
			string  	sFolder	= ksACQ
			variable	Gain		= GainByNmForDisplay( sFolder, sChan )
			AutoscaleZoomAndOfs( w, sChan, mo, ra, rbAutoscl, rYOfs, rYZoom, Gain )
			ReplaceOneParameter( w, nCurve, cbAUTOSCL, sValue )						// or  'BuildCurve()'  could be used rather than 3 times 'ReplaceOneParameter()'
			ReplaceOneParameter( w, nCurve, cYOFS, 	num2str( rYOfs ) )
			ReplaceOneParameter( w, nCurve, cYZOOM, 	num2str( rYZoom ) )

			break;
		case	cYZOOM:
			ReplaceOneParameter( w, nCurve, nIndex, sValue )
			rYZoom	= str2num( sValue )
			break;
		case	cYOFS:
			ReplaceOneParameter( w, nCurve, nIndex, sValue )
			rYOfs	= str2num( sValue )
			break;
		case	csRGB:
			ReplaceOneParameter( w, nCurve, nIndex, sValue )
			rsRGB	= sValue
			break;
		case	cAXIS:
			ReplaceOneParameter( w, nCurve, nIndex, sValue )
			rnAxis	= str2num( sValue )
			break;
	endswitch
	if ( nCurve == kNOTFOUND )
		InternalError( "UpdateCurves() : could not find sCurve '" + sCurve + "' in '" + sCurves[0,200] + "...' . " )
	endif	
	 printf "\t\tUpdateCurves()  \tw:%2d  nCv:%2d\t%s\tAutoscale:%2d\tYzoom:\t%7.2lf\tYofs:\t%7.1lf\tGain:\t%7.1lf\t%s\tAx:%2d\t \r", w, nCurve, pd( StringFromList( nCurve,   RetrieveCurves( w ), ksCURVSEP ),52), rbAutoscl, rYZoom, rYOfs, Gain, rsRGB, rnAxis
	return	nCurve
End



static Function		WhichCurve( sCurves, sCurvSep, sChan, mo, ra )
// Returns index  'nCurve'  of the curve defined by  Channel, mode and range
	string		sCurves, sCurvSep, sChan
	variable	mo, ra
	string  	sTNmMoRa	= sChan + ";" + BuildMoRaName( ra, mo ) + ";"						// Assumption naming : Curves
	variable	pos			= strsearch( sCurves, sTNmMoRa, 0 )
	variable	nCurve		= 0
	if ( pos != kNOTFOUND ) 
		sCurves	= sCurves[ 0, pos+1 ]				// truncate behind found position...
		nCurve	= ItemsInList( sCurves, sCurvSep ) 	// ..so that counting the list items gives the sought-after index 
	endif
	return	nCurve -1 							// returns index 0,1,2...    or  kNOTFOUND (-1)  
End



// not used at the moment 060608
//static Function	  	Curve2Range( sCurve  )		
//// Extracts only the  'range'  when  'sCurve'  is given
//	string		sCurve							// e.g 'Dac1;SM;........'
//	variable	ra, mo
//	string		sMoRa	=  StringFromList( 1, sCurve ) 	// e.g. 'SM'
//	ExtractMoRaName( sMoRa, ra, mo )				// convert 2-letter string into 2 numbers,  e.g. 'SM'->0,1   'RS' ->3,0
//	return	ra
//End

//static Function /S	  ExtractCurve1( sCurves, sTNm, ra, mo, rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB )			// sChan/mo/ra are known already....
//// Extracts 5 entries (rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB)  when  'sCurves'  (containing all curves of 1 window)  and the trace name, the mode and the range are given. 
//// There can only be 1 instance of each trace/mode/range  in 'sCurves'
//	string		sCurves, sTNm
//	variable	ra, mo
//	variable	&rbAutoscl, &rYOfs, &rYZoom, &rnAxis 
//	string		&rsRGB
//	variable	nCurve	= WhichCurve( sCurves, ksCURVSEP, sTNm, mo, ra )
//
//	string  	sCurve	= StringFromList( nCurve, sCurves, ksCURVSEP )		
//	variable	nItemCnt	= ItemsInList( sCurve )
//
//	//ExtractCurve( sCurve, sChan, ra, mo, rnInstance, rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB )			// sChan/mo/ra are known already so by doubling the code we simplify.......
//	rYZoom	= str2num( StringFromList( 2, sCurve ) )
//	rsRGB	= StringFromList( 4, sCurve )
//	// print	str2num( StringFromList( 5, sCurve ) )	, str2num( StringFromList( 6, sCurve ) ),  str2num( StringFromList( 7, sCurve ) )		
//	
//	// 	  	The following additional drawing parameters were introduced.
//	//	 	As they are NOT script parameters there are no default supplied by 'wIO etc.'  . These parameters are normally stored in the display config (DCF) file.
//	//		But DCF files written with older FPulse versions do not yet have these entries, so we must supply defaults here.
//	//  todo: set defaults when there is not DCF file at all
//	rYOfs	= nItemCnt <= 5   ? 	0   :	str2num( StringFromList( 5, sCurve ) )		// 040103
//	//rnInstance= nItemCnt <= 6   ? 	0   :	str2num( StringFromList( 6, sCurve ) ) 
//	if ( nItemCnt <= 7 )												// Entry in DCF is missing..
//		if ( IsDacTrace( sTNm ) )
//			rbAutoscl	= 1											//	...and it is a Dac : Do autoscaling
//		else
//			rbAutoscl	= 0											//	...and it is an Adc or PoN : use fixed Zoom from script  and Offset = 0
//		endif
//	else
//		rbAutoscl	= str2num( StringFromList( 7, sCurve ) )						// Entry in DCF exists : use it
//	endif
//	return	sCurve
//	// printf "\t\t\t\tExtractCurve1() ->   \trsTNm:\t%s\tR:%d \tM:%d \trYZoom:\t%7.2lf\trsRGB:\t%s\tYOs:\t%7.1lf\tInst: %d\tAS:%d \t  \r", pd(sTNm,7), ra, mo, rYZoom, pd(rsRGB,12), rYOfs, 1234, rbAutoscl
//End

static Function 	  ExtractCurves( sCurves, sChan, ra, mo, rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB )			
// Extracts 5 entries (rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB)  when  'sCurves'  (containing all curves of 1 window)  and the trace name, the mode and the range are given. (sTNm, ra, mo are known already)
// There can only be 1 instance of each trace/mode/range  in 'sCurves'
	string		sCurves, sChan
	variable	ra, mo
	variable	&rbAutoscl, &rYOfs, &rYZoom, &rnAxis 
	string		&rsRGB
	variable	nCurve	= WhichCurve( sCurves, ksCURVSEP, sChan, mo, ra )		// Get from all curves in this window the index of the one and only curve with matching  channel, mode and range

	string  	sCurve	= StringFromList( nCurve, sCurves, ksCURVSEP )		
	variable	nItemCnt	= ItemsInList( sCurve )

	//ExtractCurve( sCurve, sChan, ra, mo, rnInstance, rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB )			// sChan/mo/ra are known already so by doubling the code we simplify.......
	rYZoom	= str2num( StringFromList( 2, sCurve ) )
	rsRGB	= StringFromList( 4, sCurve )
	// print	str2num( StringFromList( 5, sCurve ) )	, str2num( StringFromList( 6, sCurve ) ),  str2num( StringFromList( 7, sCurve ) )		
	
	// 	  	The following additional drawing parameters were introduced.
	//	 	As they are NOT script parameters there are no default supplied by 'wIO etc.'  . These parameters are normally stored in the display config (DCF) file.
	//		But DCF files written with older FPulse versions do not yet have these entries, so we must supply defaults here.
	//  todo: set defaults when there is not DCF file at all
	rYOfs	= nItemCnt <= 5   ? 	0   :	str2num( StringFromList( 5, sCurve ) )		// 040103
	//rnInstance= nItemCnt <= 6   ? 	0   :	str2num( StringFromList( 6, sCurve ) ) 
	if ( nItemCnt <= 7 )												// Entry in DCF is missing..
		if ( IsDacTrace( sChan ) )
			rbAutoscl	= 1											//	...and it is a Dac : Do autoscaling
		else
			rbAutoscl	= 0											//	...and it is an Adc or PoN : use fixed Zoom from script  and Offset = 0
		endif
	else
		rbAutoscl	= str2num( StringFromList( 7, sCurve ) )						// Entry in DCF exists : use it
	endif
	return	nCurve
	// printf "\t\t\t\tExtractCurves() ->   \trsTNm:\t%s\tR:%d \tM:%d \trYZoom:\t%7.2lf\trsRGB:\t%s\tYOs:\t%7.1lf\tInst: %d\tAS:%d \t  \r", pd(sChan,7), ra, mo, rYZoom, pd(rsRGB,12), rYOfs, 1234, rbAutoscl
End


static Function	  	ExtractCurve( sCurve, sChan, rnRange, rnMode, rnInstance, rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB  )		// all parameters (except the 1.) are changed
// Extracts all 9 entries (rsTNm, rnRange, rnMode, rnInstance, rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB)  including the trace name, the mode and the range when  1 curve  'sCurve'  is given
	string		sCurve
	variable	&rnRange, &rnMode, &rnInstance, &rbAutoscl, &rYOfs, &rYZoom, &rnAxis 
	string		&sChan, &rsRGB
	string		sMoRa
	variable	nItemCnt	= ItemsInList( sCurve )
	sChan	= StringFromList( 0, sCurve ) 
	sMoRa	=  StringFromList( 1, sCurve ) 
	ExtractMoRaName( sMoRa, rnRange, rnMode )		// convert 2-letter string into 2 numbers,  e.g. 'SM'->0,1   'RS' ->3,0

// 040123
//	rsUnits	= StringFromList( 3, sCurve ) 			// As Units are fixed they are taken directly from the script / wIO. Only if they could be changed (e.g. like colors) they would have to be stored/extracted  in 'Curves'

	rYZoom	= str2num( StringFromList( 2, sCurve ) )
	rsRGB	= StringFromList( 4, sCurve )
	// print	str2num( StringFromList( 5, sCurve ) )	, str2num( StringFromList( 6, sCurve ) ),  str2num( StringFromList( 7, sCurve ) )		
	
	// 	  	The following additional drawing parameters were introduced.
	//	 	As they are NOT script parameters there are no default supplied by 'wIO etc.'  . These parameters are normally stored in the display config (DCF) file.
	//		But DCF files written with older FPulse versions do not yet have these entries, so we must supply defaults here.
	//  todo: set defaults when there is not DCF file at all
	rYOfs	= nItemCnt <= 5   ? 	0   :	str2num( StringFromList( 5, sCurve ) )		// 040103
	rnInstance	= nItemCnt <= 6   ? 	0   :	str2num( StringFromList( 6, sCurve ) ) 
	if ( nItemCnt <= 7 )												// Entry in DCF is missing..
		if ( IsDacTrace( sChan ) )
			rbAutoscl	= 1											//	...and it is a Dac : Do autoscaling
		else
			rbAutoscl	= 0											//	...and it is an Adc or PoN : use fixed Zoom from script  and Offset = 0
		endif
	else
		rbAutoscl	= str2num( StringFromList( 7, sCurve ) )						// Entry in DCF exists : use it
	endif

	// printf "\t\t\t\tExtractCurve() ->   \trsTNm:\t%s\tR:%d \tM:%d \trYZoom:\t%7.2lf\trsRGB:\t%s\tYOs:\t%7.1lf\tInst: %d\tAS:%d \t  \r", pd(sChan,7), rnRange, rnMode, rYZoom, pd(rsRGB,12), rYOfs, rnInstance, rbAutoscl
End


static Function	  /S	BuildCurve( sChan, nRange, nMode, nInstance, bAuto, yOfs, yZoom, nAxis, sRGB )
	variable	nRange, nMode, nInstance, bAuto, yOfs, yZoom, nAxis
	string		sChan, sRGB 
	string		sCurve = sChan + ";" + BuildMoRaName( nRange, nMode )  + ";" + num2str( yZoom ) + ";" + "UnitsUnUsed" + ";" + sRGB + ";" + num2str( nAxis )   	
 	sCurve	+= ";" + num2str( yOfs ) + ";" + num2str( nInstance ) 
 	sCurve	+= ";" + num2str( bAuto ) 
 	//sCurve	+= ";" + sNm 
 	// printf "\t\t\t\tBuildCurve() ->  '%s' \r", sCurve
 	return	sCurve
End

static Function		ReplaceOneParameter( w, nCurve, nIndex, sVarString )
//constant	cTNM = 0, cMORA = 1, cYZOOM = 2, csUNITS = 3, csRGB = 4, cYOFS = 5, cnINSTANCE = 6, cbAUTOSCL = 7
	variable	w, nCurve, nIndex
	string 	sVarString
	string		sCurves, sCurve
	sCurves	= RetrieveCurves( w )
	sCurve	= StringFromList( nCurve, sCurves, ksCURVSEP )		
	sCurve	= RemoveListItem( nIndex, sCurve )					//	 Replace the single entry... 	
	sCurve	= AddListItem( sVarString, sCurve,  ";" , nIndex )			//	...in the list of many entries in 1 curve
	sCurves	= RemoveListItem( nCurve, sCurves, ksCURVSEP )		// Replace the curve with the changed entry... 	
	sCurves	= AddListItem( sCurve, sCurves, ksCURVSEP, nCurve )		//..in the list of many curves
	StoreCurves(  w, sCurves )
End

// 040120  no longer used
//Function	/S	RetrieveOneParameter( w, nCurve, nIndex )
////constant	cTNM = 0, cMORA = 1, cYZOOM = 2, csUNITS = 3, csRGB = 4, cYOFS = 5, cnINSTANCE = 6, cbAUTOSCL = 7
//	variable	w, nCurve, nIndex
//	string 	sVarString
//	string		sCurves, sCurve
//	sCurves	= RetrieveCurves( w )
//	sCurve	= StringFromList( nCurve, sCurves, ksCURVSEP )		
//	sVarString	= StringFromList( nIndex, sCurve )					//	 Retrieve the single entry... 	
//	return	sVarString
//End

 Function			PossiblyAdjstSliderInAllWindows( sFolder )
// We change the slider limits in all windows in which a slider is displayed
	string  	sFolder
	variable	w, wCnt =  WndCnt()
	for ( w = 0; w < wCnt; w += 1 )
		PossiblyAdjstSlider( sFolder, w )
	endfor
End

static Function		PossiblyAdjstSlider( sFolder, w )
// We change the slider limits in all windows in which a slider is displayed
	string  	sFolder
	variable	w
	string		sWNm	= WndNm( w )
	string		sCurves	= RetrieveCurves( w )
	variable	nCurves	= ItemsInList( sCurves, ksCURVSEP )
	variable	nCurve
// 060530b
//	nCurve	= WndUsersTrace( w )
	for ( nCurve = 0; nCurve < nCurves; nCurve += 1 )

		string		sCurve	= StringFromList( nCurve, sCurves, ksCURVSEP )		
		variable	rnRange, rnMode, rnInstance, rbAutoscl, rYOfs, rYZoom, rnAxis 
		string		 rsTNm, rsRGB
		ExtractCurve( sCurve, rsTNm, rnRange, rnMode, rnInstance, rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB )	// Get all traces/curves from this window...
		variable	bAcqControlbar	= AcqControlBar( w )
		variable	bDisableCtrlOfs	= DisableCtrlZoomOfs(      rsTNm, bAcqControlbar, rbAutoscl )		// Determine whether the control must be enabled or disabled
		variable	Gain			= GainByNmForDisplay( sFolder, rsTNm )
		ShowHideCbSliderYOfs( sWNm,  bDisableCtrlOfs, rYOfs, Gain )							// Enable or disable the control  and possibly adjust its value
// 060530b
	endfor
End


//================================================================================================================================
//  CONTROLBARS  in  the  ACQUISITION  WINDOWS FOR EDITING TRACE and WINDOW APPEARANCE  with   POPMENU(=YZoom, Colors)   and   SLIDER(=YOfs)   

// The controlbar code for each of the the buttons, listboxes and popmemu is principally made up of 2 parts : 
// Part 1  stores the user setting in the underlying control structure 'sCurves'.  This is the more  important part as 'sCurves' controls the display during the next acquisition.
// Part 2  has the purpose to give the user some immediate feedback that his changes have been accepted. 
//	To accomplish this existing data are drawn preliminarily with changed colors, zooms, Yaxes in a manner which is to reflect the user changes at once which would without this code only take effect later during the next acquisition.
//	The code must handle  'single'  traces  and   'superimposed'  traces (derived from the basic trace name but with the begin point number appended)

// 060606  NO LONGER  rnInstance.....
//	The code must allow multiple instances of the same trace allowing the same data to be displayed at the same time with different zoom factors,..
//	  ...for this we must do much bookkeeping because Igor has the restriction of requiring the same trace=wave name but appends its own instance number whereas we must do our own instance counting in TWA
// 060606  NO LONGER  DisplayOffLine().
//	We take the approach to not even try to keep track which instances of which traces in which windows have to be redrawn, instead we we redraw all ( -> DisplayOffLine() )
//	This is sort of an overkill but here we do it only once in response to a (slow) user action while during acq we do the same routine (=updating all acq windows) very often... 
// 	...so we accept the (theoretical) disadvantage of updating traces which actually would have needed no update because it simplifies the program code tremendously  .

// Major revision 040108..040204
// Major revision 060520..060610

static constant	cXTRACENMSIZE			= 100		// empirical values, could be computed .  81 for 'Dac0SC' , 86 for 'Dac0SCa' , 92 for 'Dac0 SC a', 110 for 'Dac0 Sweeps C'
static constant	cXCHECKBOXSIZE			= 64			// 60 for 'AutoScl'
static constant	cXBUTTONMARGIN			=  2
static constant	cXLBCOLORSIZE			= 96			
static constant	cXLBZOOMSIZE			= 104			
static constant	cbDISABLEbyGRAYING		= 0 //1 	// 0 : disable the control by hiding it completely (better as it save screen space and as it avoids confusion) ,  1 : disable the control by graying it 
static constant	cbALLOW_ADC_AUTOSCALE	= 1 //1 	// 0 : autoscale only Dacs ,  1 : also autoscale   Adc , Pon , etc ( todo: not yet working correctly. Problem: tries to autoscale trace on screen which may be flat line -> CRASHES sometimes )
static constant	cbAUTOSCALE_SYMMETRIC	= 0 //1 	// 0 : autoscale exactly between minimum and maximum of trace possibly offseting zero,  1 : autoscale keeping pos. and neg. half axis at same length ( zero in the middle)


Function		AcqControlBar( w )
	variable	w
	string  	sWNm	= WndNm( w )
	ControlInfo	/W=$sWNm	CbCheckboxAuto; 	return ( V_flag == kCI_CHECKBOX )	// Check if the checkbox control exists. Only if it exists then the controlbar also exists. 
	//ControlInfo	/W=$sWNm	CbCheck...boxAuto; 	return ( V_flag == kCI_SETVARIABLE)// Check if the checkbox control exists. Only if it exists then the controlbar also exists. 
End

static  Function		CreateControlBarInAcqWnd3( sChan, mo, ra, w, bAcqControlbar ) 
// depending on  'bAcqControlbar'  build and show or hide the controlbar  AND  show or hide the individual controls (buttons, listboxes..)
	string  	sChan
	variable	mo, ra
	variable	w, bAcqControlbar											// Show or hide the controlbar
	string  	sFolder	= ksACQ
	variable	Gain		= GainByNmForDisplay( sFolder, sChan )
	string  	sWNm	= WndNm( w )	
	variable	rbAutoscl, rYOfs, rYZoom, rnAxis
	variable	rbHideYAx	= TRUE 
	string 	rsTNm, rsRGB
	string 	sCurves	= RetrieveCurves( w )		

	variable	ControlBarHeight = bAcqControlbar				? 26 : 0 			// height 0 effectively hides the whole controlbar
	ControlBar /W = $sWNm  ControlBarHeight
	
//	string  	sCurve	= ExtractCurve1( sCurves, sChan, ra, mo, rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB )	// sChan/mo/ra are known already so we extract only  rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB....
	variable  	nCurve	= ExtractCurves( sCurves, sChan, ra, mo, rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB )	// Extract fom 'sCurves' the one and only curve 'nCurve' with matching ' sChan, ra, mo' and from this the remaining (now valid) parameters 'rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB' 
	string  	sCurve	= StringFromList( nCurve,  sCurves, ksCURVSEP )							
	SetWindow	$sWNm,  	UserData( sCurve )	= sCurve						// Set UD sCurve	Store the string quasi-globally within the graph


	//string  	sTNmMoRa	= sChan + " " + BuildMoRaName( ra, mo )				// e.g. 'Adc1 FM' 		needs  cXTRACENMSIZE >= 86
	string  	sTNmMoRa	= sChan + " " + RangeNmLong( ra ) + " " + ModeNm( mo ) 	// e.g. 'Adc1 Frames M'	needs  cXTRACENMSIZE >= 120
	 printf "\tCreateControlBarInAcqWnd3( sWNm:%s %d ) \t%s\t mo:%d ra:%d\t%g\t%g\t%s \r",  sWNm, bAcqControlbar, pd( sTNmMoRa, 13), mo, ra , rYOfs, rYZoom, rnAxis, rsRGB 
	ConstructCbTitleboxTraceNm( sWNm,  bAcqControlbar, sTNmMoRa )				// 
	ConstructCbPopmenuColors( sWNm,  bAcqControlbar, rsRGB )					//

	variable	bDisableCtrlAutoscl	= DisableCtrlAutoscl( sChan, bAcqControlbar ) 
	variable	bDisableCtrlZoomOfs	= DisableCtrlZoomOfs( sChan, bAcqControlbar, rbAutoscl ) 

	ConstructCbCheckboxAuto( sWNm, bDisableCtrlAutoscl, rbAutoscl )						
	ConstructCbCheckboxHideYAx( sWNm, bDisableCtrlAutoscl, rbHideYAx )
	ConstructCbListboxYZoom( sWNm, bDisableCtrlZoomOfs,  rYZoom )						
	ConstructCbSliderYOfs( 	sWNm, bDisableCtrlZoomOfs, rYOfs, Gain )				// also construct the optional Controlbar on the right (only in Igor5) 

	// printf "\tCreateControlBarInAcqWnd( sWNm:%s ) \tw:%d , nCurve:%d =?= nCurve:%2d \tsCurve:'%s' \r", sWNm, w, WndUsersTrace( w ), nCurve, sCurve
End


//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//  Functions  controling  whether a specific control  of the control bar  is to be enabled, disabled by completely hiding it or disabled by just graying it.

// 060607 simplified
static  Function		DisableCtrlAutoscl( sTNm, bAcqCb ) 
	string  	sTNm
	variable	bAcqCb
	variable	bDisableAutosclCheckbox
	if (  !  cbALLOW_ADC_AUTOSCALE )				
	 	bDisableAutosclCheckbox	=  ! bAcqCb   ||  ! IsDacTrace( sTNm )					//  only  Dacs  can be autoscaled
	else
		bDisableAutosclCheckbox	=  ! bAcqCb  									//  Dacs and  Adcs can be autoscaled
	endif
	return	bDisableAutosclCheckbox
End

static  Function		DisableCtrlZoomOfs( sTNm, bAcqCb, bAutoscl ) 
// determine whether the control must be shown or hidden depending on the state of of other controls and  depending on other factors
	string  	sTNm
	variable	bAcqCb, bAutoscl
	variable	bDisableGeneral	= ! bAcqCb
	variable	bDisableCtrlAutoscl	= DisableCtrlAutoscl( sTNm, bAcqCb ) 
	variable	nDisableCtrl		= bDisableGeneral   ||  ( ! bDisableCtrlAutoscl  &&  bAutoscl )	// not used : only enable (=0)  or hide (=1)  the control, no possibility to gray it
	if ( bDisableGeneral == 1 )		
		nDisableCtrl = 1														// if all controls are to disappear then the Zoom should also hide : do not allow graying
	else
		nDisableCtrl =  ( ! bDisableCtrlAutoscl  &&   bAutoscl )  *  ( 1 + cbDISABLEbyGRAYING )	// 0 enables , 1 disables by hiding , 2 disables by graying
	endif
	return	nDisableCtrl													// 0 enables , 1 disables by hiding , 2 disables by graying
End

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//  CONTROLBARS  in  the  ACQUISITION  WINDOWS : CONSTRUCTION

static  Function		ConstructCbTitleboxTraceNm( sWNm, bDisable, sTNmMoRa )
// Fill the Titlebox control  in the ControlBar with the name of the selected trace. 
	string 	sWNm, sTNmMoRa
	variable	bDisable
	Titlebox  CbTitleboxTraceNm,  win = $sWNm,  pos = {2, 2},  title = sTNmMoRa,  frame = 2,  labelBack=(60000, 60000, 60000)
	//Titlebox  CbTitleboxTraceNm,  win = $sWNm, size = {cXTRACENMSIZE-10,12} 			// TitleBox 'size'  has no effect, the field is automatically sized 
	Titlebox  CbTitleboxTraceNm,  win = $sWNm, disable = ! bDisable
End

static  Function		ConstructCbCheckboxAuto( sWNm, bDisable, bAutoscl )
	string  	sWNm
 	variable	bDisable, bAutoscl 
	Checkbox	CbCheckboxAuto,  win = $sWNm, size={ cXCHECKBOXSIZE,20 },	proc=CbCheckboxAuto,  title= "AutoScl"
	Checkbox	CbCheckboxAuto,  win = $sWNm, pos={ cXTRACENMSIZE + 0 * ( cXCHECKBOXSIZE + cXBUTTONMARGIN ) , 2 }
	Checkbox	CbCheckboxAuto,  win = $sWNm, help={"Automatical Scaling works only with Dac but not with Adc traces."}
	ShowHideCbCheckboxAuto( sWNm, bDisable, bAutoscl  )							// Enable or disable the control  and possibly adjust its value
End
static  Function		ShowHideCbCheckboxAuto( sWNm, bDisable, bAutoscl  )
//  Hide, gray or display (=enable)  the control   and   set its  state/value/limits  correctly  (even when hidden).
	string  	sWNm
 	variable	bDisable, bAutoscl  
	Checkbox	CbCheckboxAuto,  win = $sWNm, disable =  bDisable, value = bAutoscl
End

static  Function		ConstructCbPopmenuColors( sWNm, bDisable, sRGB )
	string 	sWNm, sRGB
	variable	bDisable
	variable	rnRed, rnGreen, rnBlue
	ExtractColors( sRGB, rnRed, rnGreen, rnBlue )
	PopupMenu CbPopmenuColors,  win = $sWNm, size={ cXLBCOLORSIZE,16 },	proc=CbPopmenuColors,	title=""		
	PopupMenu CbPopmenuColors,  win = $sWNm, pos={ cXTRACENMSIZE + 1 * ( cXCHECKBOXSIZE + cXBUTTONMARGIN ) , 2 }
	PopupMenu CbPopmenuColors,  win = $sWNm, mode=1, popColor = ( rnRed, rnGreen, rnBlue ), value = "*COLORPOP*"
//	PopupMenu CbPopmenuColors,  win = $sWNm, help = {"If you have multiple traces in the windows, you must first select the trace to apply on, then the color."}
	PopupMenu CbPopmenuColors,  win = $sWNm, disable = ! bDisable
End


static  Function		ConstructCbListboxYZoom( sWNm, bDisable, YZoom )
	string 	sWNm
	variable	bDisable, YZoom
	PopupMenu CbListboxYZoom,   win = $sWNm, size = { cXLBZOOMSIZE, 20 }, 	proc=CbListboxYZoom,	title="   yZoom"	
	PopupMenu CbListboxYZoom,   win = $sWNm, pos = { cXTRACENMSIZE + 1 * ( cXCHECKBOXSIZE + cXBUTTONMARGIN )+ cXLBCOLORSIZE - 44, 2 } 
//	PopupMenu CbListboxYZoom ,  win = $sWNm, help = {"If you have multiple traces in the windows, you must first select the trace to apply on, then the Y zoom factor."}
	ShowHideCbListboxYZoom( sWNm, bDisable, YZoom )									// Enable or disable the control  and possibly adjust its value
End

static  Function		ShowHideCbListboxYZoom( sWNm, bDisable, YZoom )
//  Hide, gray or display (=enable)  the control   and   set its  state/value/limits  correctly  (even when hidden).
	string 	sWNm
	variable	bDisable, YZoom
	variable	n, nSelected, nItemCnt	= ItemsInList( ZoomValues() )
	// Search the item in the list which corresponds to the desired value 'YZoom'
	for ( n = 0; n < nItemCnt; n += 1 )
		if ( str2num( StringFromList( n, ZoomValues() ) ) == YZoom )	// compare numbers, the numbers as strings might be formatted in different ways ( trailing zeros...)
			break
		endif
	endfor
	if ( n == nItemCnt )
		n = 4			// the desired value could not be found in the list,  so we select arbitrarily  a zoom of 1  to be displayed  which is the  4. item  in the list
	endif
	PopupMenu CbListboxYZoom,   win = $sWNm, disable = bDisable,  mode = n+1,  value = ZoomValues()	// n+1 sets the selected item in the listbox,  counting starts at 1
End

Function	/S	ZoomValues()							// Igor does not allow this function to be static
	return	".1;.2;.5;1;2;5;10;20;50;100"
End	


static  Function		ConstructCbCheckboxHideYAx( sWNm, bDisable, bHide )
	string  	sWNm
 	variable	bDisable, bHide 
	Checkbox	CbCheckboxHideYAx,  win = $sWNm, size={ cXCHECKBOXSIZE,20 },	proc=CbCheckboxAuto,  title= "Hide Y axis"
	Checkbox	CbCheckboxHideYAx,  win = $sWNm, pos = { cXTRACENMSIZE + 1 * ( cXCHECKBOXSIZE + cXBUTTONMARGIN )+ cXLBCOLORSIZE + cXLBZOOMSIZE - 44, 2 } 
	Checkbox	CbCheckboxHideYAx,  win = $sWNm, help={""}
	Checkbox	CbCheckboxHideYAx,  win = $sWNm, disable =  bDisable, value = bHide		// Hide, gray or display (=enable)  the control   and   set its  state/value/limits  correctly  (even when hidden)
End


static  Function		ConstructCbSliderYOfs( sWNm, bDisable, YOfs, Gain )
	string 	sWNm
	variable	bDisable, YOfs, Gain
	Slider 	CbSliderYOfs,   win = $sWNm,	proc=CbSliderYOfs 
	GetWindow $sWNm, wSize											// Get the window dimensions in points .
	variable 	RightPix	= ( V_right	-  V_left )	* screenresolution / kIGOR_POINTS72 	// Convert to pixels ( This has been tested for 1600x1200  AND  for  1280x1024 )
	variable 	BotPix	= ( V_bottom - V_top ) * screenresolution / kIGOR_POINTS72 
	// print  "\twindow dim in points:", V_left,  V_top,  V_right,  V_bottom , " -> RightPix:",  RightPix, BotPix

	Slider 	CbSliderYOfs,   win = $sWNm, vert = 1, side = 2,	size={ 0, BotPix - 30 },  pos = { RightPix -76, 28 }
	//ControlInfo /W=$sWNm CbSliderYOfs
	// printf "\tControlInfo Slider  in '%s' \tleft:%d \twidth:%d \ttop:%d \theight:%d \r", sWNm,  V_left, V_width, V_top, V_height
	ShowHideCbSliderYOfs( sWNm, bDisable, YOfs, Gain )							// Enable or disable the control  and possibly adjust its value
End

static  Function		ShowHideCbSliderYOfs( sWNm, bDisable, YOfs, Gain )
//  Hide, gray or display (=enable)  the control   and   set its  state/value/limits  correctly  (even when hidden).
	string 	sWNm
	variable	bDisable, YOfs, Gain
	variable	ControlBarWidth 	=    bDisable == 1   ?	0  : 76		//  Vertical slider at the  right window border :only hide=1 sets width = 0 and makes the controlbar vanish, enable=0 and gray=2 display  the controlbar
	ControlBar /W = $sWNm  /R ControlBarWidth
	variable	DacRange		= 10								// + - Volt
	variable	YAxisWithoutZoom	= DacRange * 1000 / Gain 			
	// printf "\t\t\tShowHideCbSliderYOfs() \t'%s'\tDGn:\t%7.1lf\t-> Axis(without zoom):\t%7.1lf\tVal:\t%7.1lf\t  \r", sWNm, Gain, YAxisWithoutZoom, YOfs / Gain
	Slider	CbSliderYOfs,	win = $sWNm, 	disable = bDisable,	value = YOfs / Gain,	limits = { -YAxisWithoutZoom, YAxisWithoutZoom, 0 } 
End

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//  CONTROLBARS  in  the  ACQUISITION  WINDOWS  :  THE  ACTION  PROCEDURES

Function		IsDacTrace( sTNm )
// Returns whether the passed trace is of type  'Dac'  and not  e.g.  'Adc'  or  'PoN' 
	string 	sTNm
	return	( cmpstr( sTNm[ 0, 2 ], "Dac" ) == 0 )
End

Function		IsPoNTrace( sTNm )
// Returns whether the passed trace is of type  'PoN'  and not  e.g.  'Adc'  or  'Dac' 
	string 	sTNm
	return	( cmpstr( sTNm[ 0, 2 ], "PoN" ) == 0 )
End


Function		CbCheckboxAuto( s )
// Executed only when the user changes the 'AutoScale' checkbox : If it is turned on, then YZoom and YOfs values are computed so that the currently displayed trace is fitted to the window.
	struct	WMCheckboxAction	&s
	string  	rsChan, rsRGB													// parameters are set by  UpdateCurves()
	variable	ra, mo, rnInstance, rbAutoscl, rYOfs, rYZoom, rnAxis						// parameters are set by  UpdateCurves()
	variable	w		= WndNr( s.Win )
	string  	sCurve 	= GetUserData( 	s.win,  "",  "sCurve" )							// Get UD sCurve 
	variable	nCurve	= UpdateCurves( w, cbAUTOSCL,  num2str( s.checked ),  sCurve, rsChan, ra, mo, rnInstance, rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB )	

	// The Dac trace has now been rescaled in TWA internally and will  be shown with new scaling during the next acquisition, but we want to immediately give some feedback to the
	//... user so he sees his rescaling has been accepted , so we go on redrawing all windows
	string  	sFolder	= ksACQ
	variable	Gain		= GainByNmForDisplay( sFolder, rsChan )
	//DurAcqRescaleYAxisOld( w, nCurve, s.Win, rsChan, rYOfs, rYZoom, rnAxis, Gain )
variable	nAxis	= nCurve
	DurAcqRescaleYAxis( nCurve, s.Win, rYOfs, rYZoom, Gain )

	// Hide the  Zoom  and  Offset  controls if  AutoScaling is ON, display them if Autoscaling is OFF
	variable	bAcqControlbar		= AcqControlbar( w )
	variable	bDisableCtrlZoomOfs	= DisableCtrlZoomOfs( rsChan, bAcqControlbar, s.checked )	// Determine whether the control must be enabled or disabled
	ShowHideCbListboxYZoom( s.Win,  bDisableCtrlZoomOfs, rYZoom )					// Enable or disable the control  and possibly adjust its value
	ShowHideCbSliderYOfs( 	s.Win,  bDisableCtrlZoomOfs, rYOfs, Gain )					// Enable or disable the control  and possibly adjust its value
End


static  Function		AutoscaleZoomAndOfs( w, sChan, mo, ra, bAutoscl, rYOfs, rYZoom, Gain )
// Adjust   YZoom  and   YOffset  values  depending on the state of the  'Autoscale'  checkbox.  Return the changed  YZoom  and  YOfs  values  so that they can be stored in TWA  so that the next redraw will reflect the changed values.
	string 	sChan
	variable	w, mo, ra, bAutoscl, Gain 
	variable	&rYOfs, &rYZoom

	string 	sWNm			= WndNm( w )
	string 	sZoomLBName		= "CbListboxYZoom"
	variable	YAxis			= 0
	variable	DacRange 		= 10								// + - Volt

	string  	sTNL			= TraceNameList( sWNm, ";", 1 )
	string  	sTNm			= sChan + BuildMoRaName( ra, mo ) + ksMORA_PTSEP	// e.g. 'Dac1FM_'	( in many/superimposed mode there is an integer point number appended, which we are not interested in)
	string  	sMatchingTraces	= ListMatch( sTNL, sTNm + "*" )						// e.g. 'Dac1FM_;Dac1FM_1000;Dac1FM_2000;'			
	variable	mt, nMatchingTraces	= ItemsInList( sMatchingTraces )
	for ( mt = 0; mt < nMatchingTraces; mt += 1 )
		sTNm	= StringFromList( mt, sMatchingTraces )							// e.g. 'Dac1FM_' ,  'Dac1FM_1000'  and  'Dac1FM_2000'		

		if ( bAutoscl )												// The checkbox  'Autoscale Y axis'  has been turned  ON :
			wave 		wData	= TraceNameToWaveRef( sWNm, sTNm )
			waveStats	/Q	wData									// 	...We compute the maximum/mimimum Dac values from the stimulus and set the zoom factor... 
	
			if ( cbAUTOSCALE_SYMMETRIC )							// 		Use symmetrical axes, the length is the longer of both. The window is filled to 90% . 
				 YAxis	= max( abs( V_max ), abs( V_min ) ) / .9	
				 rYOfs	= 0
			else													// 		The length of pos. and neg. half axis is adjusted separately.  The window is filled to 90% . 
				YAxis	= (  V_max   -  V_min  ) 		 / 2 / .9 
				rYOfs	= (  V_max  +  V_min  ) / Gain	 / 2  
			endif		
	
			rYZoom	= DacRange * 1000 / YAxis				
		else														//  The checkbox  'Autoscale Y axis'  has been turned  OFF : So we restore and use the user supplied zoom factor setting from the listbox
																//  We do not restore the  YOfs from slider because 	1. the user can very easily  (re)adjust to a new position   
																//										2. the YOfs is at the optimum position as it has just been autoscaled  
			ControlInfo /W=$sWNm $sZoomLBName						//										3. the YOfs prior to AutoScaling would have had to be stored to be able to retrieve it which is not done in this version 
			rYZoom	= str2num( S_Value )								// Get the controls current value by reading S_Value  which is set by  ControlInfo
		endif
		// printf "\t\t\tAutoscaleZoomAndOfs( '%s' \t'%s'\tpts:\t%8d\t bAutoscl: %s )\tVmax:\t%7.2lf\tVmin:\t%7.2lf\tYaxis:\t%7.1lf\tYzoom:\t%7.2lf\tYofs:\t%7.1lf\tGain:\t%7.1lf\t  \r",  sWNm, rsTNm, numPnts( $rsTNm ), SelectString( bAutoscl, "OFF" , "ON" ), V_max, V_min, YAxis, rYZoom, rYOfs, Gain
	endfor
End


Function 		CbPopmenuColors( s )
	struct	WMPopupAction	&s
	string  	rsChan, rsRGB													// parameters are set by  UpdateCurves()
	variable	ra, mo, rnInstance, rbAutoscl, rYOfs, rYZoom, rnAxis						// parameters are set by  UpdateCurves()
	variable	w		= WndNr( s.Win )
	string  	sCurve 	= GetUserData( 	s.win,  "",  "sCurve" )							// Get UD sCurve 
	variable	nCurve	= UpdateCurves( w, csRGB, s.PopStr, sCurve, rsChan, ra, mo, rnInstance, rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB )	
	// The new colors have now been set and will be effective during the next acquisition, but we want to immediately give some feedback to the..
	// ..user so he sees his color change has been accepted, so we go on and colorize the trace (or all instances of this trace) in the existing window :
	string  	sTNL			= TraceNameList( s.Win, ";", 1 )
	string  	sTNm			= rsChan + BuildMoRaName( ra, mo ) + ksMORA_PTSEP	// e.g. 'Dac1FM_'	( in many/superimposed mode there is an integer point number appended, which we are not interested in)
	string  	sMatchingTraces	= ListMatch( sTNL, sTNm + "*" )						// e.g. 'Dac1FM_;Dac1FM_1000;Dac1FM_2000;'			
	variable	mt, nMatchingTraces	= ItemsInList( sMatchingTraces )
	variable	nRed, nGreen, nBlue 
	ExtractColors( s.PopStr,  nRed, nGreen, nBlue )
	for ( mt = 0; mt < nMatchingTraces; mt += 1 )
		sTNm	= StringFromList( mt, sMatchingTraces )							// e.g. 'Dac1FM_' ,  'Dac1FM_1000'  and  'Dac1FM_2000'		
		ModifyGraph	/W = $s.Win	rgb( $sTNm ) = ( nRed, nGreen, nBlue )	
	endfor
	// Also change the color of the units which are displayed as a textbox right above the Y axis)
variable	nAxis	= nCurve
	wave  /T	wAxisName	= root:uf:disp:wYAxisName							
	string		sAxisNm		= wAxisName[ nCurve ] 									
	TextBox 	/W=$s.win /C /N=$sAxisNm   /G=( nRed, nGreen, nBlue)  					// the textbox has the same name as its axis
End

Function		 CbListboxYZoom( s )
// Action proc executed when the user selects a zoom value from the listbox.  Update  TWA  and  change axis and traces immediately to give some feedback.
	struct	WMPopupAction	&s
	string  	rsChan, rsRGB													// parameters are set by  UpdateCurves()
	variable	ra, mo, rnInstance, rbAutoscl, rYOfs, rYZoom, rnAxis						// parameters are set by  UpdateCurves()
	variable	w		= WndNr( s.Win )
	string  	sCurve 	= GetUserData( 	s.win,  "",  "sCurve" )							// Get UD sCurve
	variable	nCurve	= UpdateCurves( w, cYZOOM, s.PopStr, sCurve, rsChan, ra, mo, rnInstance, rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB )	
	// The new YZoom has now been set and will be effective during the next acquisition, but we want to immediately give some feedback to the..
	// ..user so he sees his YZoom  change has been accepted , so we go on and change the Y Axis range in the existing window :
	string  	sFolder	= ksACQ
	variable	Gain		= GainByNmForDisplay( sFolder, rsChan )						// The user may change the AxoPatch Gain any time during acquisition
variable	nAxis	= nCurve
	//DurAcqRescaleYAxisOld( w, nCurve, s.Win, rsChan, rYOfs, rYZoom, Gain )
	DurAcqRescaleYAxis( nCurve, s.Win, rYOfs, rYZoom, Gain )
End

Function		CbSliderYOfs( s )
	struct	WMSliderAction	&s
	// printf "\t\tSlider '%s'  gives value:%d  event:%d  \r", s.CtrlName, s.curval, s.eventcode	// bit field: bit 0: value set; 1: mouse down, 2: mouse up, 3: mouse moved
	string  	rsChan, rsRGB													// parameters are set by  UpdateCurves()
	variable	ra, mo, rnInstance, rbAutoscl, rYOfs, rYZoom, rnAxis						// parameters are set by  UpdateCurves()
	variable	w		= WndNr( s.Win )
	string  	sCurve 	= GetUserData( 	s.win,  "",  "sCurve" )							// Get UD sCurve
	variable	nCurve	= UpdateCurves( w, cYOFS, num2str( s.curval ), sCurve, rsChan, ra, mo, rnInstance, rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB )	
	// The new YOffset has now been set and will be effective during the next acquisition, but we want to immediately give some feedback to the..
	// ..user so he sees his YOffset change has been accepted , so we go on and change the Yoffset in the existing window :
	string  	sFolder	= ksACQ
	variable	Gain		= GainByNmForDisplay( sFolder, rsChan )						// The user may change the AxoPatch Gain any time during acquisition
variable	nAxis	= nCurve
	//DurAcqRescaleYAxisOld( w, nCurve, s.Win, rsChan, rYOfs, rYZoom, rnAxis, Gain )
	DurAcqRescaleYAxis( nCurve, s.Win, rYOfs, rYZoom, Gain )
	return	0															// other return values reserved
End


//================================================================================================================================
//  TRACE  ACCESS  FUNCTIONS  FOR  THE USER
//  Remarks:
//  It has become standard user practice to access the acquired data in form of the waves/traces displayed in the acquisition windows.
//  This was not originally intended: it was intended (and is perhaps better) to access the data from the complete acquisition wave (e.g. 'Adc0' )
//  Accessing the data from the display waves (as it is implemented here) has the advantage that the user can see and check the data on screen.
//  This is also the drawback: he cannot access those data for which he has turned the display OFF,  he cannot access trace segments...
// ...which are longer or have a different starting point than those on screen.
//  These limitations vanish when access to the complete waves is made: the user could copy arbitrary segments for his private use or act on the original wave...

Function		ShowTraceAccess(  wG, wFix )
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
// return composed  FRAME  Acq display trace name  when base name and frame is given ( for block 0 ) 
	string		sTNm
	variable	fr
	variable	bl	= 0
	variable	pr	= 0	// 031007     NOT REALLY  PROTOCOL  AWARE ............
	string  	sFolder	= ksACQ
	return	Trace( sFolder, sTNm, kFRAME, FrameBegSave( sFolder, pr, bl, fr ) )
End

Function  /S		TraceP( sTNm, fr )
// return composed  PRIMARY  Acq display trace name  when base name and frame is given ( for block 0 ) 
	string		sTNm
	variable	fr
	variable	bl	= 0
	variable	pr	= 0	// 031007     NOT REALLY  PROTOCOL  AWARE ............
	string  	sFolder	= ksACQ
	return	Trace( sFolder, sTNm, kPRIM, FrameBegSave( sFolder, pr, bl, fr ) )
End

Function  /S		TraceR( sTNm, fr )
// return composed  RESULT  Acq display trace name  when base name and frame is given ( for block 0 ) 
	string		sTNm
	variable	fr
	variable	bl	= 0
	variable	pr	= 0	// 031007     NOT REALLY  PROTOCOL  AWARE ............
	string  	sFolder	= ksACQ
	wave  	wFix		= $"root:uf:" + sFolder + ":ar:wFix"  					// This  'wFix'	is valid in FPulse ( Acquisition )
	return	Trace( sFolder, sTNm, kRESULT, SweepBegSave( sFolder, pr, bl, fr,  eSweeps( wFix, bl ) - 1 ) )
End

Function  /S		TraceS( sTNm, fr, sw )
// return composed  SWEEP  Acq display trace name  when base name,  frame  and  sweep  is given ( for block 0 ) 
	string		sTNm
	variable	fr, sw
	variable	bl	= 0
	variable	pr	= 0	// 031007     NOT REALLY  PROTOCOL  AWARE ............
	string  	sFolder	= ksACQ
	return	Trace( sFolder, sTNm, kSWEEP, SweepBegSave( sFolder, pr, bl, fr,  sw ) )
End

Function  /S		TraceFB( sTNm, fr, bl )
// return composed  FRAME  Acq display trace name  when base name and frame and block is given
	string		sTNm
	variable	fr, bl
	variable	pr	= 0	// 031007     NOT REALLY  PROTOCOL  AWARE ............
	string  	sFolder	= ksACQ
	return	Trace( sFolder, sTNm, kFRAME, FrameBegSave( sFolder, pr, bl, fr ) )
End

Function  /S		TracePB( sTNm, fr, bl )
// return composed  PRIMARY  Acq display trace name  when base name and frame and block is given
	string		sTNm
	variable	fr, bl
	variable	pr	= 0	// 031007     NOT REALLY  PROTOCOL  AWARE ............
	string  	sFolder	= ksACQ
	return	Trace( sFolder, sTNm, kPRIM, FrameBegSave( sFolder, pr, bl, fr ) )
End

Function  /S		TraceRB( sTNm, fr, bl )
// return composed  RESULT  Acq display trace name  when base name and frame and block is given
	string		sTNm
	variable	fr, bl
	variable	pr	= 0	// 031007     NOT REALLY  PROTOCOL  AWARE ............
	string  	sFolder	= ksACQ
	wave  	wFix		= $"root:uf:" + sFolder + ":ar:wFix"  					// This  'wFix'	is valid in FPulse ( Acquisition )
	return	Trace( sFolder, sTNm, kRESULT, SweepBegSave( sFolder, pr, bl, fr,  eSweeps( wFix, bl ) - 1 ) )
End

Function  /S		TraceSB( sTNm, fr, bl, sw  )
// return composed  SWEEP  Acq display trace name  when base name , frame , block  and  sweep  given
	string		sTNm
	variable	fr, sw, bl
	variable	pr	= 0	// 031007     NOT REALLY  PROTOCOL  AWARE ............
	string  	sFolder	= ksACQ
	return	Trace( sFolder, sTNm, kSWEEP, SweepBegSave( sFolder, pr, bl, fr, sw ) )
End

Function  /S		Trace( sFolder, sTNm, nRange, BegPt )
// returns  any  composed  Acq display trace name....
	string		sFolder, sTNm
	variable	nRange, BegPt
	variable	nMode	= kMANYSUPIMP
	return	BuildTraceNmForAcqDisp( sFolder, sTNm, nMode, nRange, BegPt)
End
// 031007  -----------   NOT  REALLY  PROTOCOL  AWARE 


