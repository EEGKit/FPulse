////
//// UF_AcqDisp.ipf	+     FPDispDlg.ipf
//// 
//// Routines for
////	displaying traces during acquisition
////	displaying raw result traces after acquisition
////	preparing an acquisition window for hardcopy
////
//// How the display during acquisition works...
//// BEFORE ACQUISITION
//// Before the acquisition starts, the users prefered window settings must be prepared.
//// The acq window panel is read : which Traces(Adc,PoN..) are to be shown in which range (Frame, Sweep, Primary,Result) and in which mode (current, many=superimposed).
//// These settings are combined in a data structure  'Curves'  which contains the complete information how the traces display should look like.
//// DURING ACQUISITION
//// The display routine receives only  the region on screen where to draw and which data are valid. The latter is encoded in the frame and  the sweep number of the data .
//// Positive sweep numbers means the valid display range is one sweep, whereas a sweep number -1 means the data range that can be displayed is a frame.
////  From frame and sweep number the display routine itself computes data offset and data points to be drawn. 
////  The  'Curves'  containing the users prefered display settings is broken and trace, mode and range are extracted  and  compared against the currently valid data range,  if appropriate then data are drawn.
//
//// History:
//// Major revision 0605-0606
//
//#pragma rtGlobals=1							// Use modern global access method.
//
//#include "UFPE_Listbox"		

//constant			kWNDDIVIDER			= 75		// 15..100 : x position of a window separator if graph display area is to be divided in two columns

//static strconstant 	sDISP_CONFIG_EXT		= "dcf"
//static strconstant 	ksMORA_PTSEP		= "_"		// separates TraceModeRange from starting point in trace names, e.g. Adc0SM_0 (blank is not allowed)

//static constant		kbAUTOPOS = 0,  kbMYPOS = 1   

//Function		CreateGlobalsInFolder_Disp()
//// creates all folder-specific variables. To be used once from CreateGlobals() as the current data folder is changed and not restored
//	NewDataFolder  /O  /S root:uf:acq:disp				// analysis : make a new data folder and use as CDF,  clear everything
//	variable	/g	gR1x = 0, gR1y = 0, gR2x = 0, gR2y = 0	
//	variable	/g	gR1gR2_SeemNotNecessary
//	if ( ! FP_IsRelease() )
//	endif
//End


//static constant		kMAX_ACDIS_WNDS	= 4		// !!! number of Acq Display windows : Also adjust the number of listbox columns   ->  see  'ListBox  lbAcDis,  win = ksLB_ACDIS,  widths  = xxxxx' 
//
//static strconstant	ksLB_ACDIS			= "LbAcqDisplay"
//
// strconstant		klstAXIS_NAMES		= "left;right1;right2;right3;" 	// !!! Version compatibility: can only add axes, must never remove one.   Igor does not allow this string to be static as it fills a popupmenu
////static	 strconstant	klstAXIS_USED			= "0;1;2;3"
//
////=====================================================================================================================================
////   ACQUISITION  DISPLAY  -  USER INTERFACE WITH LISTBOX
//
//Function		fAcqDisplay( s )
//// Displays and hides the AcqDisplay selection listbox panel
//	struct	WMButtonAction	&s
//	nvar		state		= $ReplaceString( "_", s.ctrlname, ":" )		// the underlying button variable name is derived from the control name
//	string  	sFo		= ksACQ								// 'acq'
//	string  	sWin		= ksLB_ACDIS							//  'LbAcqDisplay'
//// Could also store visbility in INI file....like elsewhere
//	if (  state ) 
//		LBAcDisUpdate()		// Could pass window name		// Rebuild the listbox completely as in meantime while the listbox perhaps was invisible e.g the number of channels may have changed
//	else
//		UFCom_WndHide( sWin )								//  hide the panel  'LbAcqDisplay'  in  Acq 
//	endif	
//End
//
//// 2009-02-03 old
////Function		fAcqDisplay( s )
////// Displays and hides the AcqDisplay selection listbox panel
////	struct	WMButtonAction	&s
////	nvar		bVisib	= $ReplaceString( "_", s.ctrlname, ":" )		// the underlying button variable name is derived from the control name
////	printf "\t\t%s(s)\t\t\tchecked:%d\t \r",  UFCom_pd(s.CtrlName,26), bVisib
////	if (  bVisib ) 
////		LBAcDisUpdate()									// Rebuild the listbox completely as in meantime while the listbox perhaps was invisible e.g the number of channels may have changed
////	else
////		LBAcDisHide()
////	endif
////End
////
////Function		LBAcDisHide()
////	string  	sWin	= ksLB_ACDIS
////	// printf "\t\t\tLBAcDisHide()   sWin:'%s'  \r", sWin
////	if (  WinType( sWin ) == UFCom_WT_PANEL )				// check existance of the panel. The user may have killed it by clicking the panel 'Close' button 5 times in fast succession
////		MoveWindow 	/W=$sWin   0 , 0 , 0 , 0				// hide the window by minimising it to an icon
////	endif
////End
//
//Function		ClearLBAcDis( sFolders )
//	string  	sFolders
//	wave   /Z	wFlags		= $"root:uf:" + sFolders + ":wAcDisFlags"
//	if ( waveExists( wFlags ) ) 
//		UFPE_LBClear( wFlags )
//	endif
//End
//
////=======================================================================================================================================================
//// THE   ACQUISITION  DISPLAY  LISTBOX  PANEL			
//
//static constant	kLBACDIS_COLWID_TYP		= 62		// OLA Listbox column width for Mode/Range	 column  (in points)
//static constant	kLBACDIS_COLWID_WND	= 30		// OLA Listbox column width for    Window	 column  (in points)	(W0,W1 needs 24,   A0,A1 needs 20,  a,b,c needs 12,   A,B,C needs 14,  WA0,WA1..needs 30)
//static constant	kLBACDIS_Y				= 1		// 1 = top most y position
//
//Function		LBAcDisUpdate()
//// Build the huge  'Acquisition Display'  listbox allowing the user to select which channels and which data ranges (sweeps,frames) and modes (current, many) are to be displayed in which windows
//	string  	sFolders		= "acq:pul"
//	nvar		bVisib		= $"root:uf:acq:pul:buAcDisplay0000"				// The ON/OFF state ot the 'Acq Display' button
//	string  	sWin			= ksLB_ACDIS
//
//	// 1. Construct the global string  'lstAllMora'  which contains all display modes and ranges e.g.  'Sweeps Current..... Result Many'  and the channel suffix
//	// 	This string determines the entries and their order as displayed in the listbox
//	string  	lstAllMora		=  ListAllMora() 							// Sweeps C_0;Sweeps M_0;Frames C_0;.........Result M_2;    the index is the channel//
//
//
//	// 2. Get the the text for the cells by breaking the global string  'lstAllMora'  which contains all display modes and ranges e.g.  'Sweeps Current..... Result Many'  by truncating the channel suffix
//	variable	len, n, nItems	= ItemsInList( lstAllMora )	
//	// printf "\t\t\tLBAcDisUpdate(a)\tlstAllMora has items:%3d <- \t '%s .... %s' \r", nItems, lstAllMoRa[0,80] , lstAllMoRa[ strlen( lstAllMoRa ) - 80, inf ]
//	string 	sColTitle, lstColTitles	= ""									// e.g. 'Dac0~Adc3~PoN1~'
//	string  	lstColItems		= ""
////	string  	lstCol2ChRg	= ""										// e.g. '1,0;0,2;'
////	string		lstCurves		= ""
//	variable	nExtractCh, ch = -1
//	string 	sOneItemIdx, sOneItem
//	for ( n = 0; n < nItems; n += 1 )
//		sOneItemIdx	= StringFromList( n, lstAllMoRa )						// e.g. 'Frames C_0'
//		len			= strlen( sOneItemIdx )
//		sOneItem		= sOneItemIdx[ 0, len-3 ] 							// strip 1 indices + separator '_'  e.g. 'Frames C_0'  ->  'Frames'
//		nExtractCh	= str2num( sOneItemIdx[ len-1, len-1 ] )					// !!! Assumption : MoRa naming convention
//		if ( ch != nExtractCh )											// Start new channel
//			ch 		= nExtractCh
//			//sprintf sColTitle, "Ch%2d ", ch								// Assumption: Print results column title  e.g. 'Ch 0~Ch 2~'
//			sprintf sColTitle, "%s", StringFromList( ch, LstChan_a(), UFCom_ksSEP_TAB )	// Assumption: Print results column title  e.g. 'Adc1'  or  'Adc3'
//			lstColTitles	     =  AddListItem( sColTitle,  lstColTitles,   UFCom_ksCOL_SEP, inf )	// e.g. 'Adc1~Adc3~'
////			lstCol2ChRg +=  UFPE_SetChRg( ch, rg )							// e.g.  '1,0;0,2;'
//			lstColItems	   += UFCom_ksCOL_SEP
//		endif
//		lstColItems		+= sOneItem + ";"
//	endfor
//	lstColItems	= lstColItems[ 1, inf ] + UFCom_ksCOL_SEP							// Remove erroneous leading separator '~'  ( and add one at the end )
////	lstColItems	= lstColItems + UFCom_ksCOL_SEP								// Add separator '~'  at the end 
////
//	// 3. Get the maximum number of items of any column
////	variable	c, nCols	= ItemsInList( lstColItems, UFCom_ksCOL_SEP )				// or 	ItemsInList( lstColTitles, UFCom_ksCOL_SEP )
//	variable	r, c, nCols	= ItemsInList( LstChan_a(), UFCom_ksSEP_TAB )
//	variable	nRows	= nItems / nCols
//	string  	lstItemsInColumn
////	for ( c = 0; c < nCols; c += 1 )
////		lstItemsInColumn  = StringFromList( c, lstColItems, UFCom_ksCOL_SEP )	
////		nRows		  = max( ItemsInList( lstItemsInColumn ), nRows )
////	endfor
//	// printf "\t\t\tLBAcDisUpdate(b)\tlstAllMora has items:%3d -> rows:%3d  cols:%2d\tColT: '%s'\tColItems: '%s...' \r", nItems, nRows, nCols, lstColTitles, lstColItems[0, 100]
//
//
//	// 4. Compute panel size . The y size of the listbox and of the panel  are adjusted to the number of listbox rows (up to maximum screen size) 
//	variable	nSubCols	= kMAX_ACDIS_WNDS
//	variable	xSize		= nCols * ( kLBACDIS_COLWID_TYP + nSubCols * kLBACDIS_COLWID_WND )	+ 30 	 
//	variable	ySizeMax	= UFCom_GetIgorAppPixelY() -  UFCom_kMAGIC_Y_MISSING_PIXEL	// Here we could subtract some Y pixel if we were to leave a bottom region not covered by a larges listbox.
//	variable	ySizeNeed	= nRows * UFCom_kLB_CELLY + UFCom_kLB_ADDY				// We build a panel which will fit entirely on screen, even if not all listbox line fit into the panel...
//	variable	ySize		= min( ySizeNeed , ySizeMax ) 					// ...as in this case Igor will automatically supply a listbox scroll bar.
//			ySize		=  trunc( ( ySize -  UFCom_kLB_ADDY ) / UFCom_kLB_CELLY ) * UFCom_kLB_CELLY + UFCom_kLB_ADDY	// To avoid partial listbox lines shrink the panel in Y so that only full-height lines are displayed
//	
//	// 5. Draw  panel and listbox
//	if ( bVisib )													// Draw the SelectResultsPanel and construct or redimension the underlying waves  ONLY IF  the  'Select Results' checkbox  is  ON
//
//		if ( WinType( sWin ) != UFCom_WT_PANEL )								// Draw the SelectResultsPanel and construct the underlying waves  ONLY IF  the panel does not yet exist
//			// Define initial panel position.
//			UFCom_NewPanel1( sWin, UFCom_kRIGHT1, -200, xSize, kLBACDIS_Y, 0, ySize, UFCom_kKILL_DISABLE, "Acq Display" )	// -160 is an X offset preventing this panel to be covered by the FPulse panel.  We must disable killing as this would destroy any selection in the listbox, but minimising is allowed.
//
//			SetWindow	$sWin,  hook( SelRes ) = fHookPnAcDis
//
//			ModifyPanel /W=$sWin, fixedSize= 1						// prevent the user to maximize or close the panel by disabling these buttons
//
//			// Create the 2D LB text wave	( Rows = all modes and ranges ,  Columns = Ch0; Ch1; ... )
//			make  /O 	/T 	/N = ( nRows, nCols*(1+nSubCols) )	$"root:uf:" + sFolders + ":wAcDisTxt"	= ""	// the LB text wave
//			wave   	/T		wAcDisTxt				     =	$"root:uf:" + sFolders + ":wAcDisTxt"
//		
//			// Create the 3D LB flag wave. 	Rows x Columns (as above)  x 3  : last index 0 is flags, 1 is fore- or background color, 2 is the remaining color 
//			make   /O	/B  /N = ( nRows, nCols*(1+nSubCols), 3 )	$"root:uf:" + sFolders + ":wAcDisFlags"	// byte wave is sufficient for up to 254 colors 
//			wave   			wAcDisFlags			    = 	$"root:uf:" + sFolders + ":wAcDisFlags"
//			
//			// Create color table withs rows and columns exchanged. 3 rows, n columns is easier to read as n columns, 3 rows but must be transposed before Igor can use them.
//			// At the moment these colors are the same as in the  DataSections  listbox
//			//								black		blue			red			magenta			grey			light grey			green			yellow				
//
//			// Version1: (works but wrong colors)
//			// make   /O	/W /U	root:uf:acq:ola:wAcDisColors= { {0, 0, 0 }, { 0, 0, 65535 },  { 65535, 0, 0 },  {40000,0,48000}, {44000,44000,44000},  {54000,54000,54000},  { 0, 50000, 0} ,   { 0, 56000, 56000 },  {65280,59904,48896} }	// order must be same as defined by constants above
//			// wave	wAcDisColorsPr	 	= root:uf:acq:ola:wAcDisColors 		
//			// MatrixTranspose 		  wAcDisColorsPr					// the same table is used for foreground and background. 	Igor requires  n  rows, 3 columns 
//			//  UFPE_LBColors( wAcDisColorsPr )								// 2005-1108  
//
//			// Version2: (works...)
//			make /O	/W /U /N=(UFPE_ST_MAX,3) 	   	   $"root:uf:" + sFolders + ":wAcDisColors" 		
//			wave	wAcDisColorsPr	 		= $"root:uf:" + sFolders + ":wAcDisColors" 		
//			 UFPE_LBColors( wAcDisColorsPr )								// 2005-1108  
//
//
//			// Link the  indices  of  Foreground  and  Background  colors  to  their name strings which are later used to access the layer where the color is to be set
//			variable	planeFore	= 1,   planeBack = 2
//			SetDimLabel 2, planeBack,  $"backColors"	wAcDisFlags
//			SetDimLabel 2, planeFore,   $"foreColors"	wAcDisFlags
//
//
//	MakeWnd( kMAX_ACDIS_WNDS )	// 2006-0522 build the underlying waves just once, never delete them
//
//
//	
//		else														// The panel DOES exist. It may be minimised to an icon or it may be hidden behind other panels. If it is hidden then the checkbox must be actuated twice: hide and then restore panel to make it visible
//// 2009-02-03 old	MoveWindow /W=$sWin	1,1,1,1							// Restore previous size and position. This does NOT take into account that the panel size may have changed in the meantime due to more or less columns or rows
//			UFCom_WndUnhide( sWin )								// Restore previous size and position. This does NOT take into account that the panel size may have changed in the meantime due to more or less columns or rows
//
//			UFCom_MoveWindow1( sWin, UFCom_kRIGHT1, -200, xSize, kLBACDIS_Y, 0, ySize )	// Extract previous panel position and size. Keep only position and discard size as the size may have changed in the meantime due to more or less columns or rows.
//
//			wave   	/T		wAcDisTxt		= $"root:uf:" + sFolders + ":wAcDisTxt"
//			wave   			wAcDisFlags	= $"root:uf:" + sFolders + ":wAcDisFlags"
//			Redimension	/N = ( nRows, nCols*(1+nSubCols) )		wAcDisTxt
//			Redimension	/N = ( nRows, nCols*(1+nSubCols), 3 )		wAcDisFlags
//		endif
//
//		// Set the column titles in the SR text wave, take the entries as computed above
//		variable	w, lbCol
//		for ( c = 0; c < nCols; c += 1 )									// the true columns 0,1,2  each including the window subcolumns
//			for ( w = 0; w <= nSubCols; w += 1 )							// 1 more as w=0 is not a window but the Mode/Range column
//				lbCol	= c * (nSubCols+1) + w
//				if ( w == 0 )
//					SetDimLabel 1, lbCol, $StringFromList( c, lstColTitles, UFCom_ksCOL_SEP ), wAcDisTxt	// 1 means columns,   true column 		e.g. 'Dac0'  or  'Adc1'
//				else
//					SetDimLabel 1, lbCol, $WndNm( w-1 ), wAcDisTxt						// 1 means columns,   window subcolumn	e.g. 'A' , 'B' , 'C'   or  'W0' , 'W1' 
//				endif
//			endfor
//		endfor
//
//		// Fill the listbox columns with the appropriate  text
//		for ( c = 0; c < nCols; c += 1 )
//			if ( c == 0 )
//				// !!!  Bad code : number of entries depends on  'nSubCols' = 'kMAX_ACDIS_WNDS'	
//				if ( kMAX_ACDIS_WNDS == 1 )
//					ListBox   	lbAcDis,    win = $sWin, 	widths  =	{ kLBACDIS_COLWID_TYP,   kLBACDIS_COLWID_WND }	
//				elseif ( kMAX_ACDIS_WNDS == 2 )
//					ListBox   	lbAcDis,    win = $sWin, 	widths  =	{ kLBACDIS_COLWID_TYP,   kLBACDIS_COLWID_WND,  kLBACDIS_COLWID_WND }	
//				elseif ( kMAX_ACDIS_WNDS == 3 )
//					ListBox   	lbAcDis,    win = $sWin, 	widths  =	{ kLBACDIS_COLWID_TYP,   kLBACDIS_COLWID_WND,  kLBACDIS_COLWID_WND,  kLBACDIS_COLWID_WND }	
//				elseif ( kMAX_ACDIS_WNDS == 4 )
//					ListBox   	lbAcDis,    win = $sWin, 	widths  =	{ kLBACDIS_COLWID_TYP,   kLBACDIS_COLWID_WND,  kLBACDIS_COLWID_WND,  kLBACDIS_COLWID_WND,  kLBACDIS_COLWID_WND }	
//				else
//					ListBox   	lbAcDis,    win = $sWin, 	widths  =	{ kLBACDIS_COLWID_TYP,   kLBACDIS_COLWID_WND,  kLBACDIS_COLWID_WND,  kLBACDIS_COLWID_WND,  kLBACDIS_COLWID_WND,  kLBACDIS_COLWID_WND }	
//				endif
//			else
//				// !!!  Bad code : number of entries depends on  'nSubCols' = 'kMAX_ACDIS_WNDS'	
//				if ( kMAX_ACDIS_WNDS == 1 )
//					ListBox   	lbAcDis,    win = $sWin, 	widths  +=	{ kLBACDIS_COLWID_TYP,   kLBACDIS_COLWID_WND }	
//				elseif ( kMAX_ACDIS_WNDS == 2 )
//					ListBox   	lbAcDis,    win = $sWin, 	widths  +=	{ kLBACDIS_COLWID_TYP,   kLBACDIS_COLWID_WND,  kLBACDIS_COLWID_WND }	
//				elseif ( kMAX_ACDIS_WNDS == 3 )
//					ListBox   	lbAcDis,    win = $sWin, 	widths +=	{ kLBACDIS_COLWID_TYP,   kLBACDIS_COLWID_WND,  kLBACDIS_COLWID_WND,  kLBACDIS_COLWID_WND }	
//				elseif ( kMAX_ACDIS_WNDS == 4 )
//					ListBox   	lbAcDis,    win = $sWin, 	widths  +=	{ kLBACDIS_COLWID_TYP,   kLBACDIS_COLWID_WND,  kLBACDIS_COLWID_WND,  kLBACDIS_COLWID_WND,  kLBACDIS_COLWID_WND }	
//				else
//					ListBox   	lbAcDis,    win = $sWin, 	widths  +=	{ kLBACDIS_COLWID_TYP,   kLBACDIS_COLWID_WND,  kLBACDIS_COLWID_WND,  kLBACDIS_COLWID_WND,  kLBACDIS_COLWID_WND,  kLBACDIS_COLWID_WND }	
//				endif
//			endif
//			lstItemsInColumn  = StringFromList( c, lstColItems, UFCom_ksCOL_SEP )	
//			for ( r = 0; r < ItemsInList( lstItemsInColumn ); r += 1 )
//				for ( w = 0; w <= nSubCols; w += 1 )									// 1 more as w=0 is not a window but the Mode/Range column
//					lbCol	= c *(nSubCols+1) + w
//					if ( w == 0 )
//						wAcDisTxt[ r ][ lbCol ]	= StringFromList( r, lstItemsInColumn )			// set the text  e.g  'Base' , 'F0_T0'
//					else
//						wAcDisTxt[ r ][ lbCol ]	= ""									// the subcolumns 'A' , 'B' , 'C'  are  NOT displayed in the cells but only in the titles
//					endif
//				endfor
//			endfor
//		endfor
//	
//		// Build the listbox which is the one and only panel control 
//		ListBox 	  lbAcDis,    win = $sWin, 	pos = { 2, 0 },  size = { xSize, ySize + UFCom_kLB_ADDY },  frame = 2
//		ListBox	  lbAcDis,    win = $sWin, 	listWave 			= $"root:uf:" + sFolders + ":wAcDisTxt"
//		ListBox 	  lbAcDis,    win = $sWin, 	selWave 			= $"root:uf:" + sFolders + ":wAcDisFlags",  editStyle = 1
//		ListBox	  lbAcDis,    win = $sWin, 	colorWave		= $"root:uf:" + sFolders + ":wAcDisColors"				// 2005-1108
////		// ListBox 	  lbAcDis,    win = $sWin, 	mode 			 = 4// 5			// ??? in contrast to the  DataSections  panel  there is no mode setting required here ??? 
//		ListBox 	  lbAcDis,    win = $sWin, 	proc 	 			 = lbAcDisProc
//		// Design issue: Should  'lstCol2ChRg'  be stored in userdata?   As  the listbox  'lbAcDis'  is much simpler than  'lbSewlResOA'  it is actually not required  but could be done to maintain similarity of both listboxes...
////		ListBox 	  lbAcDis,    win = $sWin, 	userdata( lstCol2ChRg) = lstCol2ChRg
////		ListBox 	  lbAcDis,    win = $sWin, 	userdata( lstCurves ) 	 = lstCurves		// set UD lstCurves
//
//	endif		// bVisible : state of  'AcqDisplay'  button is  ON 
//
//
////	// Store the string quasi-globally within the listbox panel window
////	// ListBox 	 	lbAcDis,    win = $sWin, 	UserData( lstAllMoRa ) = lstAllMoRa		// Store the string quasi-globally within the listbox which belongs to the panel window 
////	SetWindow	$sWin,  				UserData( lstAllMoRa ) = lstAllMoRa		// Store the string quasi-globally within the panel window containing the listbox 
//
//End
//
//
//// 2009-02-02 old
////Function 		fHookPnAcDis( s )
////// The window hook function of the 'AcqDisplay Listbox Panel' detects when the user minimises the panel by clicking on the panel 'Minimise' button and adjusts the state of the 'AcqDisplay' button accordingly
////	struct	WMWinHookStruct &s
////	string  	sFolders		= "acq:pul"
////
////	if ( s.eventCode != UFCom_WHK_mousemoved )
////		 printf  "\t\tfHookPnAcDis( %2d \t%s\t)  '%s'\r", s.eventCode,  UFCom_pd(s.eventName,9), s.winName
////
////		if ( s.eventCode == UFCom_WHK_move )									// This event also triggers if the panel is minimised to an icon or restored again to its previous state
////			GetWindow     $s.WinName , wsize									// Get its current position		
////			variable	bIsVisible	= ( V_left != V_right  &&  V_top != V_bottom )// Igor5 Igor6 ???
////			UFCom_TurnButton( "pul", 	"root_uf_acq_pul_buAcDisplay0000",	bIsVisible )	//  Turn the 'Acq Display' button  ON / OFF  if the user maximised or minimised the panel by clicking the window's  'Restore size'  or  'Minimise' button [ _ ]  to keep the control's state consistent with the actual state.
////			 printf "\t\tfHookPnAcDis( %2d \t%s\t)  '%s'\tV_left:%3d, V_Right:%3d, V_top:%3d, V_bottom:%3d -> bVisible:%2d  \r", s.eventCode,  UFCom_pd(s.eventName,9), s.winName, V_left, V_Right, V_top, V_bottom, bIsVisible
////		endif
////
////	endif
////End
//
//// 2009-02-02
//Function 		fHookPnAcDis( s )
//// The window hook function of the 'AcqDisplay Listbox Panel' detects when the user minimises the panel by clicking on the panel 'Minimise' button and adjusts the state of the 'AcqDisplay' button accordingly
//	struct	WMWinHookStruct &s
//	//string  	sFolders		= "acq:pul"
//	string  	sFo			= ksACQ			// 'acq'
//	string  	sSubFoIni		= "FPuls"			// = ksPN_INISUB  (do not change!)
//	string  	sKey			= "Wnd"
//	string  	sIniBasePath	= FunctionPath( ksFP_APP_NAME )					// the Ini file containing the window position will be written in a subdirectory parallel to UF_PulseMain.ipf 
//	string  	lstWndInfo		= ""
//	string  	sWNm		= s.winName	
//	variable	bVisible 		= -1
//
//	string   sButtonName	 = "root_uf_" + sFo + "_" + ksFPUL + "_" + "buAcDisplay" + "0000" 		// will not work in Tabs: must adjust to 1000, 0100 ...
//
//	if ( s.eventCode != UFCom_WHK_mousemoved )
//		 //printf  "\t\tfHookPnAcDis( %2d \t%s\t%s\t%s\t%s\t%s\r", s.eventCode,  UFCom_pd(s.eventName,9),  sFo, UFCom_pd(sSubFoIni ,10), UFCom_pd(sWNm,11), UFCom_pd( sKey ,10)	
//
//		if ( s.eventCode == UFCom_WHK_kill )	
//			UFCom_IniFile_SectionSetWrite( sFo, sSubFoIni, sWNm, sKey, "" , sIniBasePath )	// clear all window information by setting  'lstWndInfo'  to an empty string   AND  change the settings file (last param : 1 means write to file)	
//			bVisible = 0											// store 'visible' state 
//			UFCom_TurnButton( 	ksFPUL, sButtonName, UFCom_kOFF )		// the user kas killed the panel so we adjust the button state so that the next press brings up the panel again
//		endif
//
//		// On every move/resize store position in memory  (for a different implementation see fFP_StimDispWndHook  ).....
//		if ( s.eventCode == UFCom_WHK_move  ||   s.eventCode == UFCom_WHK_resize )		// The move event also triggers if the panel is minimised to an icon or restored again to its previous state
//			GetWindow $sWNm hide												// retrieve 'hidden' state and store in V_Value, which can be 0, 1 or 2.    Evaluates  bit 0  (hidden/visible)   and   bit 1  (minimised/normal size)
//			bVisible 		= ! V_Value											// store 'visible' state 
//			UFCom_TurnButton( 	   ksFPUL, sButtonName, bVisible )						// if the window has been created in the hidden state  we adjust the button state so that the next press creates the window again
//			UFCom_WndVisibilitySet_(  sFo, sSubFoIni, sWNm, sKey, bVisible )					// do not write to disk 
//			GetWindow $sWNm wsize												// in points
//			UFCom_WndPositionSet_( sFo, sSubFoIni, sWNm, sKey, V_Left, V_Top, V_Right, V_Bottom )	// do not write to disk on every  'move/resize', but only on 'deactivate' below
//			// printf "\t\tfHookPnAcDis( %2d \t%s\t%s\t%s\t%s\t%s\tV_left:%3d, V_Right:%3d, V_top:%3d, V_bottom:%3d -> bVisible:%2d  %s\r", s.eventCode,  UFCom_pd(s.eventName,9), sFo, UFCom_pd(sSubFoIni,10), UFCom_pd(sWNm,11), UFCom_pd( sKey ,10)	, V_left, V_Right, V_top, V_bottom, bVisible, sButtonName
//		endif
//
//		// ...but write to file only when window is left
//		if ( s.eventCode == UFCom_WHK_activate )			
//			lstWndInfo	  = UFCom_Ini_Section( 		   sFo, sSubFoIni, sWNm, sKey )		
//			lstWndInfo	  = UFCom_IniFile_SectionSetWrite( sFo, sSubFoIni, sWNm, sKey, lstWndInfo, sIniBasePath )	// now finally write file  
//			 printf "\t\tfHookPnAcDis( %2d \t%s\t%s\t%s\t%s\t%s\twriting: '%s'  \r", s.eventCode,  UFCom_pd(s.eventName,9), sFo, UFCom_pd(sSubFoIni ,10), UFCom_pd(sWNm,11), UFCom_pd( sKey ,10), lstWndInfo
//		endif
//
//	endif
//End
//
//
//
//Function		lbAcDisProc( s ) : ListBoxControl
//// Dispatches the various actions to be taken when the user clicks in the Listbox. At the moment only mouse clicks and the state of the CTRL, ALT and SHIFT key are processed.
//// At the moment the actions are  1. colorise the listbox fields  2. add result to  or remove result from window.  Note: if ( s.eventCode == UFCom_LBE_MouseUp  )	does not work here like it does in the data sections listbox ???
//	struct	WMListboxAction &s
//// 2009-10-29
//if (  s.eventCode != UFCom_kEV_ABOUT_TO_BE_KILLED )
//	string  	sFolders		= "acq:pul"
//	string  	sFo		= ksACQ
//	wave	wFlags		= $"root:uf:" + sFolders + ":wAcDisFlags"
//	wave   /T	wTxt			= $"root:uf:" + sFolders + ":wAcDisTxt"
//	string  	sPlaneNm		= "BackColors" 
//	variable	pl			= FindDimLabel( wFlags, 2, sPlaneNm )
//	variable	nOldState		= UFPE_LBState( wFlags, s.row, s.col, pl )						// the old state
//	string  	lstCol2ChRg 	= LstChan_a()
////	string  	lstCurves	 	= GetUserData( 	s.win,  s.ctrlName,  "lstCurves" )			// get UD lstCurves  e.g. Dac0;FM;1;UnitsUnUsed;(50000,50000,0);0;0;1|Adc1;......|
////	string  	lstCol2ChRg 	= GetUserData( 	s.win,  s.ctrlName,  "lstCol2ChRg" )		// e.g. for 2 columns '0,0;1,2;'  (Col0 is Ch0Rg0 , col1 is Ch1Rg2) 
////	string  	lstOlaRes	 	= GetUserData( 	s.win,  s.ctrlName,  "lstOlaRes" )			// e.g. 'Base_00A;Peak_00B;F0_A0_01B;' : which OLA results in which OLA windows
//
//	//.......na............... Convert the modifying key (e.g. 'Ctrl' ,  'Ctrl Alt / Alt Gr' ) to a state = color  (e.g. select for file, for print or for both )  
//	variable	nState		= UFPE_LBModifier2State( s.eventMod, UFPE_lstMOD2STATE1)			//..................na.......NoModif:cyan:3:Tbl+Avg ,  Alt:green:2:Avg ,  Ctrl:1:blue:Tbl ,   AltGr:cyan:3:Tbl+Avg 
//
//
////	//  Construct or delete  'wAcqPt'  . This wave contains just 1 analysed  X-Y-result point which is to be displayed in the acquisition window over the original trace as a visual check that the analysis worked.  
//	variable	ch			= LbCol2Ch( s.col, kMAX_ACDIS_WNDS )				// the column of the channel (ignoring all additional window columns)
//	variable	w			= LbCol2Wnd0( s.col , kMAX_ACDIS_WNDS)			// windows are 0,1,2...
//	variable	mo			= LbRow2Mode( s.row )
//	variable	ra			= LbRow2Range( s.row )
//	string		sChan		=  StringFromList( ch, lstCol2ChRg, UFCom_ksSEP_TAB )
//	// printf "\t\tlbAcDisProc( s ) 1\trow:%2d\tcol:%2d  evCode:%2d\tevModif:%2d\toldstate:%2d -> %2d \tch:%2d\twnd:%2d\tmo:%2d\tra:%2d\tlstColChans:'%s' \r", s.row , s.col, s.eventCode, s.eventMod,  nOldState, nState, ch, w, mo, ra, lstCol2ChRg
////	string  	sChRg		= StringFromList( ch, lstCol2ChRg )						// e.g. '0,0;1,2;'  ->  '1,2;'
////	string  	sWndAcq		= FindFirstWnd_a( ch )
//
////	variable	rg			= UFPE_ChRg2Rg( sChRg )									// e.g.  Base , Peak ,  F0_A1, Lat1_xxx ,  Quotxxx
////	string  	sTyp			= wTxt[ s.row ][ LbCol2TypCol( s.col ) ]						// retrieves type when any window column  in any channel/region is clicked
////	variable	rtp			= UFPE_WhichListItemIgnorWhiteSp( sTyp, UFPE_klstEVL_RESULTS ) 	// e.g. UFPE_kE_Base=15,  UFPE_kE_PEAK=25  todo fits......
//	string  	sWndAcDis	= ""
//
//	string  	sLbMoRaNm 	= LbMoRaNm( ch, mo, ra ) 								// e.g. 
//	variable	BegPt		= 0
//	variable	nSmpInt		= UFPE_SmpInt( sFo )
//	variable	Pts, EndPt, bIsFirst	
//	variable	pr = 0,  bl = 0,   lap = 0,  fr = 0,  sw = 0
//	variable	nCurve, nCurves
//	variable	bAutoscl, YZoom, YOfs, rnAxis
//// todo : sChan...sChan1 ???
//	string  	sChan1		= StringFromList( ch, LstChan_a(), UFCom_ksSEP_TAB )				// e.g.   'Adc1'
//printf "\tlbAcDisProc   sChan:%s  sChan1:%s  \r", sChan, sChan1
//	string  	sAcDisTrcNm 	= BuildTraceNmForAcqDispNoFolder( sChan1, mo, ra, BegPt )
//variable	nAxis, nAxisCnt		
//
//
//	// MOUSE : SET a  cell. Click with Left Mouse in a cell  in any row or column. Depending on the modifiers used, the cell changes state and color and stays in this state. It can be reset by shift clicking again or by globally reseting all cells.
//	// ADD  A  CURVE  AND  POSSIBLY  AN  ACQUISITION  WINDOW
//	if ( s.eventCode == UFCom_LBE_MouseDown  &&  !( s.eventMod & UFCom_kMD_SHIFT )  &&  !( s.eventMod & UFCom_kMD_RIGHTCLICK ) )	// Only LEFT mouse clicks  without SHIFT  are interpreted here.  // ??? In this listbox only MouseDown is detected, whereas in the similar  DataSections  listbox  MouseUp  is detected???
//		if ( w < 0 ) 																		//  A  Mode/Range  column cell has been clicked  : ignore  clicks 
//			 printf "\t\tlbAcDisProc( Ignore\trow:%2d\tcol:%2d  evCode:%2d\tevModif:%2d\toldstate:%2d -> %2d \tch:%2d\twnd:%2d\tmo:%2d\tra:%2d\t%s\t%s\t'%s'\t   \r", s.row , s.col, s.eventCode, s.eventMod,  nOldState, nState, ch, w, mo, ra,  sWndAcDis, UFCom_pd(sLbMoRaNm,12), sAcDisTrcNm
//		else
//			if ( ! ( nOldState & 3 ) ) 		// the cell must have been unselected, do not attempt to select a trace twice
//				 UFPE_LBSet5( wFlags, s.row, s.row, s.col, pl, nState )									// sets flags and changes the color of the listbox field.  The range feature is not used here so  begin row = end row .
//	
//				// test 060519-060522  Display Offline : Display data resembling the data to be acquired so that the user is aided in preparing his display configuration to be used during real acquisition
//				sWndAcDis		= PossiblyAddAcDisWnd( w, kbAUTOPOS )
//				 printf "\t\tlbAcDisProc( ADD 2\trow:%d  col:%d  ch:%d\tw:%2d\tcv:%2d\t\t\t\tCd:%d  Md:%d  Stt:%d->%d\t\tra:%d\t\t\tmo:%2d\t%s\t'%s'   \r", s.row , s.col, ch, w, nCurve, s.eventCode, s.eventMod,  nOldState, nState, ra, mo, UFCom_pd(sLbMoRaNm,12), sAcDisTrcNm
//	
//				UFCom_EraseTracesInGraph( sWndAcDis ) 											// Remove all traces in  window  so that all traces can be rebuilt which simplifies the positioning of the Y axis.
//				bAutoscl	= 1			// should be 1 only for Dacs and else 0 
//				YZoom	= 1
//				YOfs		= 0
//
//// 2006-0619
//rnAxis	= YAxisCnt( w ) -1								// Depending on the state of the ALT button either find the last used axis and use it for drawing this trace
//rnAxis 	= max( 0, rnAxis )								// ...(if there is no axis then start with axis 0 )...
//if ( s.eventMod & UFCom_kMD_ALT )
//	rnAxis = min( rnAxis + 1,YAxisMax() - 1 )					// ... OR  construct a new axis for drawing this trace
//endif
//
//				string  sRGB	= Nm2Color( sFo, sChan )	
//				nCurve		= CurvesAddCurve( w, sChan, ra, mo, bAutoscl, YOfs, YZoom, rnAxis, sRGB )
//				nCurves		= CurvesCnt( w )
//				 printf "\t\tlbAcDisProc( ADD 4\trow:%d  col:%d  ch:%d\tw:%2d\tcv:%2d\t\tax:%2d/%2d\tCd:%d  Md:%d  Stt:%d->%d\t\tra:%d\t\t\tmo:%2d\t%s\t'%s'\t%s   \r", s.row , s.col, ch, w, nCurve, rnAxis, YAxisCnt( w ), s.eventCode, s.eventMod,  nOldState, nState, ra, mo, UFCom_pd(sLbMoRaNm,12), sAcDisTrcNm,  CurvesRetrieve( w )
//	
//				for ( nCurve = 0; nCurve < nCurves; nCurve += 1 )					// Rebuild all traces in window
//					nAxisCnt	= YAxisCnt( w )									// nYAxisCnt   could be less than   nCurves  if an Y axis has been removed perhaps because 2 or more traces share the same Y axis		
//					ra		= Curve2Range( w, nCurve  )		
//					Range2Pt( sFo, ra, pr, bl, lap, fr, sw, BegPt, EndPt, Pts, bIsFirst )
//					DurAcqDrawTraceAndAxis( sFo, w, nCurve, nAxisCnt, BegPt, Pts, bIsFirst, ra, nSmpInt )
//				endfor
//
//			endif
//		endif
//
//	endif
//
//	// MOUSE :  RESET a cell  by  Left Mouse Shift Clicking
//	// REMOVE  A  CURVE  AND  POSSIBLY  AN  ACQUISITION  WINDOW
//	if ( s.eventCode == UFCom_LBE_MouseDown  &&  ( s.eventMod & UFCom_kMD_SHIFT )  &&  !( s.eventMod & UFCom_kMD_RIGHTCLICK ) )	// Only LEFT mouse clicks  with    SHIFT  are interpreted here.  // ??? In this listbox only MouseDown is detected, whereas in the similar  DataSections  listbox  MouseUp  is detected???
//		nState		= 0													// Reset a cell  
//		 UFPE_LBSet5( wFlags, s.row, s.row, s.col, pl, nState )								// sets flags and changes the color of the listbox field.  The range feature is not used here so  begin row = end row .
//		// printf "\t\tlbAcDisProc( s ) 3\trow:%2d\tcol:%2d  evCode:%2d\tevModif:%2d\tstate:%2d =?=%2d  \r",  s.row, s.col,  s.eventCode, s.eventMod, nState, UFPE_LBState( wFlags, s.row, s.col, pl )	
//		sWndAcDis	= WndNm( w )
//		if ( w < 0 ) 															//  A  Window column cell has been clicked  ( ignore  clicks into  the  Mode/Range column)
//		endif
//	
//		// printf "\t\tlbAcDisProc( DEL 1\trow:%2d\tcol:%2d  evCode:%2d\tevModif:%2d\toldstate:%2d -> %2d \tch:%2d\twnd:%2d\tmo:%2d\tra:%2d\t%s\t%s\t'%s'\t   \r", s.row , s.col, s.eventCode, s.eventMod,  nOldState, nState, ch, w, mo, ra,  sWndAcDis, UFCom_pd(sLbMoRaNm,12), sAcDisTrcNm
//
// 		// Remove the  AcDis  trace from the AcDis  window  W0, W1 or W2
//		if ( WinType( sWndAcDis ) == UFCom_WT_GRAPH )							// check if the graph exists but...
//
//// 2006-0603
//			//EraseMatchingTraces( sWndAcDis, RemoveEnding( sAcDisTrcNm, "0" ) ) 		// Remove the selected trace. Possibly remove trailing 0 (=BegPt) so that traces with any BegPt will be removed.  All current traces (having is no BegPt and ending with '_' ) are unaffected.
//			// To do / to think : make this more selective : erase only the required trace and units_textbox
//			UFCom_EraseTracesInGraph( sWndAcDis ) 							// Remove all traces in  window  so that all traces can be rebuilt which simplifies the positioning of the Y axis.
//			UFCom_RemoveAllTextBoxes( sWndAcDis )
//
//			CurvesRemoveCurve( w, sChan1, ra, mo )								// REMOVE the curve to be deleted
//
//			nCurves	= CurvesCnt( w )
//			 printf "\t\tlbAcDisProc( DEL 2\trow:%d  col:%d  ch:%d\tw:%2d\tcv:%2d/%d\t\t\tCd:%d  Md:%d  Stt:%d->%d\t\tra:%d\t\t\tmo:%2d\t%s\t'%s'\t%s   \r", s.row , s.col, ch, w, nCurve, nCurves, s.eventCode, s.eventMod,  nOldState, nState, ra, mo, UFCom_pd(sLbMoRaNm,12), sAcDisTrcNm, CurvesRetrieve( w )	
//	
//			for ( nCurve = 0; nCurve < nCurves; nCurve += 1 )						// Rebuild all traces in window
//				nAxisCnt	= YAxisCnt( w )										// nYAxisCnt   could be less than   nCurves  if an Y axis has been removed perhaps because 2 or more traces share the same Y axis		
//				ra		= Curve2Range( w, nCurve  )		
//				Range2Pt( sFo, ra, pr, bl, lap, fr, sw, BegPt, EndPt, Pts, bIsFirst )
//				DurAcqDrawTraceAndAxis( sFo, w, nCurve, nAxisCnt, BegPt, Pts, bIsFirst, ra, nSmpInt )
//			endfor
//
//			// Check if any other Mode/Range still uses this window. Only if no other Mode/Range uses this window we can remove not only the trace but also the window 
//			variable	nUsed	= 0
//			variable	c, nCols	= ItemsInList( lstCol2ChRg, UFCom_ksSEP_TAB ) 					// the number of Mode/Range columns (ignoring any window columns) 
//			for ( c = 0; c < nCols; c += 1 )
//				variable	nTrueCol	= c * ( kMAX_ACDIS_WNDS + 1 ) +  w + 1  
//				variable	r, nRows	= DimSize( wTxt, 0 )								// or wFlags
//				for ( r = 0; r < nRows; r += 1 )
//					nUsed += ( UFPE_LBState( wFlags, r, nTrueCol, pl ) != 0 )
//					// printf "\t\tlbAcDisProc( DEL 3\tr:%2d/%2d\tcol:%2d  evCode:%2d\tevModif:%2d\toldstate:%2d -> %2d \tlstColChans:'%s' -> ch:%2d\twnd:%2d\tmo:%2d\tra:%2d\t%s  -> State:%2d   Used:%2d \r", r, nRows, nTrueCol, s.eventCode, s.eventMod,  nOldState, nState, lstCol2ChRg, ch, w, mo, ra,  sWndAcDis, UFPE_LBState( wFlags, r, nTrueCol, pl ), nUsed
//				endfor
//			endfor
//			sWndAcDis	= WndNm( w )
//			if ( nUsed == 0 )
//				KillWindow $sWndAcDis											// The 'about to be killed' event will be triggered for each control in the windows control bar
//			endif
//		endif
//
////		string  sTxt   = "Window '" + sWndAcDis + "' (still) used " + num2str( nUsed ) + " times. " + SelectString( nUsed, "Will", "Cannot" ) + " delete window."
////		 printf "\t\tlbAcDisProc( DEL 4\trow:%2d\tcol:%2d  evCode:%2d\tevModif:%2d\toldstate:%2d -> %2d \tlstColChans:'%s' -> ch:%2d  rg.%2d  w:%2d [%s] kEIdx:%3d   '%s' -> %s  \r", s.row , s.col, s.eventCode, s.eventMod,  nOldState, nState, lstCol2ChRg, ch, rg, w, sWndAcDis, rtp, sTyp, sTxt
//	endif
//
//
//	// MOUSE : SET a  cell. Click with RIGHT Mouse in a cell  in any row in a window column . This will pop up the Trace&Window controlbar.  Shift Click Right Mouse will reset again.
//	if ( s.eventCode == UFCom_LBE_MouseDown  &&  !( s.eventMod & UFCom_kMD_SHIFT )  &&   ( s.eventMod & UFCom_kMD_RIGHTCLICK ) )	// Only RIGHT mouse clicks  without SHIFT  are interpreted here.  
//		if ( w < 0 ) 																		//  A  Mode/Range  column cell has been clicked  : ignore  clicks 
//			 printf "\t\tlbAcDisProc( IgnoRM\trow:%2d\tcol:%2d  evCode:%2d\tevModif:%2d\toldstate:%2d -> %2d \tch:%2d\twnd:%2d\tmo:%2d\tra:%2d\t%s\t%s\t'%s'\t   \r", s.row , s.col, s.eventCode, s.eventMod,  nOldState, nState, ch, w, mo, ra,  sWndAcDis, UFCom_pd(sLbMoRaNm,12), sAcDisTrcNm
//		else
//			if ( nOldState & 3 )		// the cell must have been selected, do not attempt to create a controlbar for an unselectred trace
//			// UFPE_LBSet5( wFlags, s.row, s.row, s.col, pl, nState )										// sets flags and changes the color of the listbox field.  The range feature is not used here so  begin row = end row .
//				 printf "\t\tlbAcDisProc( +CtrlBar\trow:%2d\tcol:%2d  evCode:%2d\tevModif:%2d\toldstate:%2d -> %2d \tch:%2d\twnd:%2d\tmo:%2d\tra:%2d\t%s\t%s\t'%s'\t   \r", s.row , s.col, s.eventCode, s.eventMod,  nOldState, nState, ch, w, mo, ra,  sWndAcDis, UFCom_pd(sLbMoRaNm,12), sAcDisTrcNm
//				CreateControlBarInAcqWnd3( sChan, mo, ra, w, UFCom_kON ) 
//			endif
//		endif
//	endif
//
//	// MOUSE :  RESET a cell  by  RIGHT Mouse Shift Clicking . This will remove the  Trace&Window controlbar
//	if ( s.eventCode == UFCom_LBE_MouseDown  &&  ( s.eventMod & UFCom_kMD_SHIFT )  &&   ( s.eventMod & UFCom_kMD_RIGHTCLICK ) )	// Only RIGHT mouse clicks  without SHIFT  are interpreted here.  
//		if ( w < 0 ) 																		//  A  Mode/Range  column cell has been clicked  : ignore  clicks 
//			 printf "\t\tlbAcDisProc( Ig ShfRM\trow:%2d\tcol:%2d  evCode:%2d\tevModif:%2d\toldstate:%2d -> %2d \tch:%2d\twnd:%2d\tmo:%2d\tra:%2d\t%s\t%s\t'%s'\t   \r", s.row , s.col, s.eventCode, s.eventMod,  nOldState, nState, ch, w, mo, ra,  sWndAcDis, UFCom_pd(sLbMoRaNm,12), sAcDisTrcNm
//		else
//			// UFPE_LBSet5( wFlags, s.row, s.row, s.col, pl, nState )										// sets flags and changes the color of the listbox field.  The range feature is not used here so  begin row = end row .
//			 printf "\t\tlbAcDisProc( - CtrlBar\trow:%2d\tcol:%2d  evCode:%2d\tevModif:%2d\toldstate:%2d -> %2d \tch:%2d\twnd:%2d\tmo:%2d\tra:%2d\t%s\t%s\t'%s'\t   \r", s.row , s.col, s.eventCode, s.eventMod,  nOldState, nState, ch, w, mo, ra,  sWndAcDis, UFCom_pd(sLbMoRaNm,12), sAcDisTrcNm
//			// 2006-0608  STRANGE : Igor runs wild when the window is killed after having removed the last trace from the window  IF BEFORE ONE TRIED TO REMOVE  A  NON_EXISTING CONTROLBAR.  No idea why but here we do what must be done: we avoid the attempt to remove a non-existing controlbar....
//			if ( AcqControlBar( w ) )
//				CreateControlBarInAcqWnd3( sChan, mo, ra, w, UFCom_kOFF ) 
//			endif
//		endif
//	endif
//
//endif
//End
//
//
////=====================================================================================================================================
////  LOADING , SAVING  and  INITIALIZING  THE  DISPLAY  CONFIGURATION
//
//// How to save and restore the users Trace-Window-Configuration 
//// Script has keyword DisplayConfig	(can be missing)
////   Program tries to extract DisplayConfig entry:
////....no........	if missing it builds automatic entry: e.g.  ''DISPCFG' + 'Script'  e.g.   'DispCfgIVK'
////	if missing it uses script name: e.g.  'DispCfg: IVK'
////   Program tries to open the one and only (user invisible) PTDispCfg file containing all  display configurations
////	If   PTDisplayCFg file cannot be opened (maybe missing)  or if desired entry is not found
////		then build  the rectangular array containing all possible windows (as before)
////
//// User action needed:	Store automatic DispCfg   containing current script name 
//// 					Store special     DispCfg   containing user supplied name
//
//
//Function		fLoadDispCfg( s )
//	struct	WMButtonAction	&s
//	string  	sFolders	= "acq:pul"
//	LoadDisplayCfg( sFolders, ScriptPath( ksACQ ), "" )					// ""  	must keep this naming convention so that future versions can access old display configurations
//End
//Function		fLoadDispCfg2( s )
//	struct	WMButtonAction	&s
//	string  	sFolders	= "acq:pul"
//	LoadDisplayCfg( sFolders, ScriptPath( ksACQ ), "_2" )				// "_2"  	must keep this naming convention so that future versions can access old display configurations
//End
//Function		fLoadDispCfg3( s )
//	struct	WMButtonAction	&s
//	string  	sFolders	= "acq:pul"
//	LoadDisplayCfg( sFolders, ScriptPath( ksACQ ), "_3" )				// "_3"  	must keep this naming convention so that future versions can access old display configurations
//End
//
//Function		fSaveDspCfg( s )
//	struct	WMButtonAction	&s
//	  printf "\tfSaveDispCfg( %s )  \r", s.ctrlName 
//	SaveDispCfg( "" ) 									// "" 	must keep this naming convention so that future versions can access old display configurations
//End
//Function		fSaveDspCfg2( s )
//	struct	WMButtonAction	&s
//	  printf "\tfSaveDispCfg2( %s )  \r", s.ctrlName 
//	SaveDispCfg( "_2" )									// "_2"  	must keep this naming convention so that future versions can access old display configurations
//End
//Function		fSaveDspCfg3( s )
//	struct	WMButtonAction	&s
//	  printf "\tfSaveDispCfg3( %s )  \r", s.ctrlName 
//	SaveDispCfg( "_3" )									// "_3"  	must keep this naming convention so that future versions can access old display configurations
//End
//
//
// Function		LoadDisplayCfg( sFolders, sFileName, sIndex )
//	string		sFolders, sFileName, sIndex
//	string		sFo		= StringFromList( 0, sFolders, ":" )	// e.g. 'acq:pul'  ->  'acq'
//	string		sDisplayCfg	= UFPE_ksSCRIPTS_DRIVE + UFPE_ksSCRIPTS_DIR + UFPE_ksTMP_DIR + ":" + UFCom_StripPathAndExtension( sFileName ) + sIndex + "." + sDISP_CONFIG_EXT		// C:UserIgor:Scripts:Tmp:XYZ.dcf
//
//	if ( bFoundDispCfg( sDisplayCfg ) )
//		 printf "\r\t\tLoadDisplayCfg( \t%s\t'%s'\t%s ) \t: user display config  '%s'  found : displaying it...\r", sFo, sFileName, sIndex, sDisplayCfg
//		LoadDispSettings( sFo, sDisplayCfg )
//	else
//		 printf "\r\t\tLoadDisplayCfg( \t%s\t'%s'\t%s ) \t: user display config  '%s'  NOT found ...\r", sFo, sFileName, sIndex, sDisplayCfg
//		ClearLBAcDis( sFolders )
//
//		UFCom_WndHide( ksLB_ACDIS )					// remove any previous listbox as its channels are invalid so that the new empty listbox with the current channels will be built once the user clicks 'Acq Display +'
//		//LBAcDisUpdate()								//...so that the new empty listbox with the current channels can be built. All cells are empty as there is no display config file yet.
//
//		variable	w
//		for ( w = 0; w < kMAX_ACDIS_WNDS; w += 1 )
//			CurvesStore( w, "" )							// Kill all curves of this window
//			string  	sWNm	= WndNm( w )
//			if ( WinType( sWNm ) == UFCom_WT_GRAPH )			// This  'Acquisition display' window does already exist but we kill it so that no empty windows remain.. 				....
//				KillWindow  $sWNm					// The 'about to be killed' event will be triggered for each control in the windows control bar 
//			endif
//		endfor
//	endif	
//End
//
//
//static Function		bFoundDispCfg( sDisplayCfg )
//	string 	sDisplayCfg
//	return	UFCom_FileExists( sDisplayCfg )					
//End
//
//static Function		SaveDispCfg( sIndex )
//// store current disp settings in specific file whose file name is derived from the script file name (other extension  and  other directory=subdirectory 'Tmp' ).
//	string		sIndex
//	string		sScriptPath = ScriptPath( ksACQ )
//	string		sFile		  = UFPE_ksSCRIPTS_DRIVE + UFPE_ksSCRIPTS_DIR + UFPE_ksTMP_DIR + ":" + UFCom_StripPathAndExtension( sScriptPath ) + sIndex + "." + sDISP_CONFIG_EXT// C:UserIgor:Scripts:Tmp:XYZ.dcf
//	SaveDispSettings( sFile )
//End
//
//
//static Function		LoadDispSettings( sFo, sFile )
//// retrieve all window / trace arrangement variables (=the display configuration contained in WLoc and WA) from 'sFile' having the extension 'DCF' 
//	string 	sFo, sFile
//
//	LoadDispSettingWaves( sFo, sFile )
//
//	variable	w, wCnt	= WndCnt()
//	// printf "\t\tLoadDispSettings( %s ) oldwCnt:%d ,  loading WA,WLoc(wCnt:%d) , script chs:'%s'    \r", sFile, oldwCnt, wCnt, ioChanList( wIO )
//	 printf "\t\tLoadDispSettings( a \t%s )     \t loading WA,WLoc(wCnt:%d/%d) ,    \r", sFile, wCnt, kMAX_ACDIS_WNDS
//
//	//ShowWndCurves( 0 )	 	
//
//	// The new script may have a different number of IO channels...
//	RedimensionWnd(  kMAX_ACDIS_WNDS  )
//
//	//  Display Offline : Retrieve the Mode/Range-Color  string entries, build the windows and  display dummy traces so that the user is aided in preparing his display configuration to be used during real acquisition
//	string  	sFolders	= "acq:pul"
//
//	UFCom_TurnButton( "pul", "root_uf_acq_pul_buAcDisplay0000",	UFCom_kON )	// Set 'Acq Display' button state to ON so that the Online Acquisition Display listbox will be built in the following line... 
//
//	variable	nState		= 3										// the one and only ON state, could be expanded to more states and colors
//	variable	ch, row = -1, col = -1
//	wave   /Z	wFlags
//	variable	pl
//	
//	LBAcDisUpdate()												// Rebuild the listbox completely as in meantime while the listbox perhaps was invisible e.g the number of channels may have changed
//	ClearLBAcDis( sFolders )
//	wave   	wFlags		= $"root:uf:" + sFolders + ":wAcDisFlags"			// The panel  'ksLB_ACDIS'  must exist and does exist  as it has been built above in LBAcDisUpdate(). 
//	pl					= FindDimLabel( wFlags, 2, "BackColors"  )
//	string  	lstChans		= LstChan_a()
//
//	// Loop through all possible windows (which may or may not exist)
//	string  	sWNm, lst = ""
//	for ( w = 0; w < kMAX_ACDIS_WNDS; w += 1 )
//		sWNm	= WndNm( w )
//
//		if ( WinType( sWNm ) == UFCom_WT_GRAPH )						//  This  'Acquisition display' window does already exist....
//			KillWindow  $sWNm										// ..but we kill it so that no empty windows remain in case this channel is not used in this newly loaded script ..
//			sWNm	= ""											//  ...( the 'about to be killed' event will be triggered for each control in the windows control bar )
//		endif
//
//		variable	nCurve, nCurves, nOldCurves
//		nOldCurves  = CurvesCnt( w )									// traces in 1 window including orphans before cleaning
// 		nCurves	   = PossiblyRemoveInvalidCurves( sFo, w, nOldCurves, lstChans )	// Remove invalid curves from the underlying display configuration data structure e.g. if the new script has less channels
//		if ( nCurves != nOldCurves )	
//			SaveDispSettings( sFile ) 									// Store the display configuration if it has changed due to clean-up
//		endif
//
//		string		sChan, sCurve
//		variable	pr = 0,  bl = 0,   lap = 0,  fr = 0,  sw = 0
//		variable	ra, mo, Pts, BegPt, EndPt, bIsFirst
//		variable	nAxisCnt,  nSmpInt	= UFPE_SmpInt( sFo )
//		
//		// Build the Acq windows and fill the acq display listbox
//		for ( nCurve = 0; nCurve < nCurves; nCurve += 1 )
//			sCurve		= CurvesOneCurve( w, nCurve )
//			ExtractChMoRaFromCurve( sCurve,  sChan, ra, mo )				// break Curve to get all traces to be displayed in window 'w'...
//			ch			= WhichListItem( sChan,  lstChans, UFCom_ksSEP_TAB, 0, 0 )
//			sWNm		= PossiblyAddAcDisWnd( w, kbMYPOS ) 			// Build the window (which has been removed above) at the user's preferred position 
//			col			= LbChanWnd2Col( ch, w, kMAX_ACDIS_WNDS )
//			row			= LbModeRange2Row( mo, ra )
//			UFPE_LBSet5( wFlags, row, row, col, pl, nState )					// sets flags and changes the color of the listbox field.  The range feature is not used here so  begin row = end row .
//		endfor
//		// Draw the curves
//		for ( nCurve = 0; nCurve < nCurves; nCurve += 1 )
//			nAxisCnt	= YAxisCnt( w )									// nYAxisCnt   could be less than   nCurves  if an Y axis has been removed perhaps because 2 or more traces share the same Y axis		
//			ra		= Curve2Range( w, nCurve  )		
//			Range2Pt( sFo, ra, pr, bl, lap, fr, sw, BegPt, EndPt, Pts, bIsFirst )
//			DurAcqDrawTraceAndAxis( sFo, w, nCurve, nAxisCnt, BegPt, Pts, bIsFirst, ra, nSmpInt )
//			 printf "\t\tLoadDispSettings(c)  \t \t \t \t \tw:%2d\tcv:%2d/%d/%d\t\t%s\tra:%d\t\t\tmo:%2d\t\t\t\t\t\t\t\t\t\t%s\t%s   \r", 	 w, nCurve, CurvesCnt( w ), nOldCurves, UFCom_pd( lstChans, 23), ra, mo, UFCom_pd(sChan,7), UFCom_pd( CurvesOneCurve(w,nCurve), 43)
//		endfor
//
//	endfor
//
//	UFCom_EnableButton( "disp", "root_uf_acq_ola_PrepPrint0000", UFCom_kCo_ENABLE )	// Now that the acquisition windows (and the 'Curves') are constructed we can allow drawing in them (even if they are still empty)
//End
//
//
////=====================================================================================================================================
////   MODE  and  RANGE  ( in the Listbox )
//
//Function	/S	ListAllMora()
//// Returns list of titles containing all display modes and ranges e.g.  'Sweeps Current..... Result Many'  and the channel suffix. 
//// This function determines the entries and their order as displayed in the listbox.  ListAllMora()  and  LbModeRange2Row( mo, ra )  and  LbRow2Mode()  and  LbRow2Range()  must be changed together!
//	variable	ch, m, r
//	variable	nChans		= ItemsInList( LstChan_a(), UFCom_ksSEP_TAB )
//	string 	lstAllMoRa	= ""
//	
//	for ( ch = 0; ch < nChans; ch += 1 )
//		for ( r = 0; r < RangeCnt(); r += 1 )				// sweep, frame...
//			for ( m = 0; m < ModeCnt(); m += 1 )			// current , many
//				lstAllMoRa	+= LbMoRaNm( ch, m, r ) + ";" 	// !!! Assumption : MoRa naming convention
//				// printf "\t\tListAllMora(a)  \t%s\tItms:%2d\t'%s...%s \r", UFCom_pd(LbMoRaNm( ch, m, r ) ,12) , ItemsInList( lstAllMoRa ),  lstAllMoRa[0,80],  lstAllMoRa[ strlen( lstAllMoRa )-80, inf ]  
//			endfor
//		endfor
//	endfor
//	// printf "\t\tListAllMora(b)  \t\t\t\t\tItms:%2d\t'%s......%s \r", ItemsInList( lstAllMoRa ),  lstAllMoRa[0,80],  lstAllMoRa[ strlen( lstAllMoRa )-80, inf ]  
//	return	lstAllMoRa
//End
//Function		LbModeRange2Row( mo, ra )
//// This function determines the entries and their order as displayed in the listbox.  ListAllMora()  and  LbModeRange2Row( mo, ra )  and  LbRow2Mode()  and  LbRow2Range()  must be changed together!
//	variable	mo, ra
//	return	ra * ModeCnt() + mo
//End
//Function		LbRow2Mode( row )
//// This function determines the entries and their order as displayed in the listbox.  ListAllMora()  and  LbModeRange2Row( mo, ra )  and  LbRow2Mode()  and  LbRow2Range()  must be changed together!
//	variable	row
//	return	mod( row, ModeCnt() )	
//End
//Function		LbRow2Range( row )
//// This function determines the entries and their order as displayed in the listbox.  ListAllMora()  and  LbModeRange2Row( mo, ra )  and  LbRow2Mode()  and  LbRow2Range()  must be changed together!
//	variable	row
//	return	trunc( row / ModeCnt() )	
//End
//Function	/S	LbMoRaNm( ch, mo, ra )
//	variable	ch, mo, ra
//	return	RangeNmLong( ra ) + " " + ModeNm( mo ) + "_" + num2str( ch )  		// !!! Assumption : MoRa naming convention
//End
//
//
//
//static  Function	/S	PossiblyAddAcDisWnd( w, bAutoPos )
//// Construct and display  1 additional  Analysis window with the default name depending on 'w'
//	variable	w, bAutoPos
//	variable	wCnt		= kMAX_ACDIS_WNDS
//	string 	sWNm	= WndNm( w )
//	variable	rnLeft, rnTop, rnRight, rnBot													// place the window in top half to the right of the acquisition windows 
//	if (  ! ( WinType( sWNm ) == UFCom_WT_GRAPH ) )											//  This  'Acquisition display' window does not exist yet
//		if ( bAutoPos == kbAUTOPOS )
//			UFCom_GetAutoWindowCorners( w, wCnt, 0, 1, rnLeft, rnTop, rnRight, rnBot, kWNDDIVIDER, 100 )// row, nRows, col, nCols
//		else																		
//			RetrieveWndCorners( w, rnLeft, rnTop, rnRight, rnBot )									// use stored/retrieved position
//		endif
//		Display /K=2 /N=$( sWNm ) /W= ( rnLeft, rnTop, rnRight, rnBot ) 								// K=2 : disable killing	 . The user  should kill the window by first removing all traces which will automatically remove the window
//		// 2006-0608  STRANGE : Igor runs wild when the window is killed HERE after having removed the last trace from the window  IF BEFORE ONE TRIED TO REMOVE  A  NON_EXISTING CONTROLBAR.  We avoid the attempt to remove a non-existing controlbar elsewhere....
//		SetWindow   	$sWNm	hook( fAcqWndHookNm )	= fAcqWndHook			
//	endif
//	return	sWNm
//End
//
//
//////=====================================================================================================================================
//////   MODE  and  RANGE  ( in 2 variables )
////
////  constant		kCURRENT 		= 0,		kMANYSUPIMP = 1
////static	  strconstant	lstMODETEXT		= "Current,Many superimposed,"
////static  strconstant	lstMODENM		= "C;M"
////static  strconstant	lstMODETXT		= "C ,M ,"
////
////  constant			kSWEEP 			= 0,	kFRAME = 1,  kPRIM = 2, 	kRESULT = 3
////static	  strconstant	lstRANGETEXT		= "Sweeps,Frames,Primary,Result,"
////static  strconstant	lstRANGENM		= "S;F;P;R"
////
////
////Function		DispRange( ch, mo, ra )
////	variable	ch, mo, ra
////	nvar   	DispRange		= $"root:uf:acq:pul:cbDispRange" + num2str( ch ) + num2str( 0 ) + num2str( mo ) + num2str( ra ) 
////	// printf "\t\t\tDispRange( ch:%2d )   'root:uf:acq:pul:cbDispRangeCh%dRg%dMo%dRa%d returns %.0lf \r", ch, ch, 0, mo, ra, DispRange
////	return	DispRange
////End
////
////Function		SetDispRange( ch, mo, ra, value )
////	variable	ch, mo, ra, value
////	nvar   	DispRange		= $"root:uf:acq:pul:cbDispRange" + num2str( ch ) + num2str( 0 ) + num2str( mo ) + num2str( ra ) 
////	DispRange	= value
////	// printf "\t\t\tSetDispRange( ch:%2d )   'root:uf:acq:pul:cbDispRangeCh%dRg%dMo%dRa%d has been set to  %.0lf \r", ch, ch, 0, mo, ra, DispRange
////End
////
////
////static  Function  /S	ModeNm( n )
////// returns  an arbitrary  name for the mode, not for the variable  e.g. 'C' , 'M' 
////	variable	n
////	return	StringFromList( n, lstMODENM )
////End
////
////static Function		ModeNr( s )
//// returns  index of the mode, given its name
////	string  	s
////	variable	nMode = 0				// Do not issue a warning when no character is passed.... 
////	if ( strlen( s ) )					// This happens when a window contains no traces.
////		nMode = WhichListItem( s, lstMODENM )
////		if ( nMode == UFCom_kNOTFOUND )
////			UFCom_DeveloperError( "[ModeNr] '" + s + "' must be 'C' or 'M' " )
////		endif
////	endif
////	return nMode
////End
////
////static Function		ModeCnt()	
////	return	ItemsInList( lstMODETEXT, UFCom_ksSEP_STD )
////End	
////
////static Function  /S	RangeNm( n )
////// returns  an arbitrary  name for the range, not for the variable  e.g.  'S' , 'F',  'R',  'P'
////	variable	n
////	return	StringFromList( n, lstRANGENM )
////End
////
////static Function	/S	RangeNmLong( n )
////// returns  an arbitrary  name for the range, not for the variable  e.g.  'Sweeps' , 'Frames',  'Result',  'Primary'
////	variable	n
////	return	StringFromList( n, lstRANGETEXT, UFCom_ksSEP_STD )
////End
////
////Function			RangeNr( s )
////// returns  index of the range, given its name			used also in   GetRangeNrFromTrc()  in  FPOnline.ipf
////	string 	s
////	variable	n = 0				// Do not issue a warning when no character is passed.... 
////	if ( strlen( s ) )					// This happens when a window contains no traces.
////		n = WhichListItem( s, lstRANGENM )
////		if ( n == UFCom_kNOTFOUND )
////			UFCom_DeveloperError( "[RangeNr] '" + s + "' must be 'S' (Sweep) or 'F' (Frame) or 'P' (Primary sweep) or 'R' (Result sweep) " )
////		endif
////	endif
////	return n
////End
////
////static Function		RangeCnt()
////	return	ItemsInList( lstRANGETEXT, UFCom_ksSEP_STD )
////End	
////
//
//
//////--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//////  IMPLEMENTATION  for  STORING   MODE  and  RANGE  as  a 2-LETTER-string  (for Curves)
////
//// Function	/S	BuildMoRaName( nRange, nMode )
////// converts the Mode / range setting for storage in the  'Curves'  to a 2-letter-string   e.g. 	'SM',   'FC' 
////	variable	nRange, nMode
////	return	RangeNm( nRange ) + ModeNm( nMode )
////End
////
////static Function	/S 	BuildMoRaNameInstance( nRange, nMode, nInstance )		// 2004-0107
////// converts the Mode / range setting into a 2-letter-string   containing the instance number  e.g. 	'SM ',   'FC1'       ( obsolete: 'SMa',   'FCb' )  
////	variable	nRange, nMode, nInstance 
////	string    	sInstance = SelectString( nInstance != 0, " " , num2str( nInstance ) )	// for the 1. instance  do not display the zero but leave blank instead
////	return	" " + BuildMoRaName( nRange, nMode ) + " " + sInstance 			// 2004-0107
////End
////
////static Function		ExtractMoRaName( sMoRa, rnRange, rnMode )
////// retrieves the Mode / range setting  from the  'Curves'  and converts the 2-letter-string   into 2 numbers  e.g. 'SM'->0,1   'RS' ->3,0
////	string 	sMoRa
////	variable	&rnRange, &rnMode
////	rnRange	= RangeNr( sMora[0,0] )
////	rnMode	= ModeNr(   sMora[1,1] )
////End
////
////static Function		Mora2Mode( sMoRa )
////// retrieves the Mode setting  from the  'Curves'  and converts the 2-letter-string   into 2 numbers  e.g. 'SM'->0,1   'RS' ->3,0
////	string 	sMoRa
////	return	ModeNr(   sMora[1,1] )
////End
////
////static Function		Mora2Range( sMoRa )
////// retrieves the Range setting  from the  'Curves'  and converts the 2-letter-string   into 2 numbers  e.g. 'SM'->0,1   'RS' ->3,0
////	string 	sMoRa
////	return	RangeNr( sMora[0,0] )
////End
////
//
////=====================================================================================================================================
////    DISPLAY   ACQUISITION   TRACES   ( USED DURING ACQUISITION )
//
//// 2009-03-23b
////constant	 cLAG = 5		// typical values  3..10  seconds    or    1..10 % 
//
//Function		DispDuringAcqCheckLag( sFo, pr, bl, lap, fr, sw, nRange )		// partially  PROTOCOL  AWARE
//	string  	sFo
//	variable	pr, bl, lap, fr, sw, nRange
//
//// 2006-02-02
//	nvar		gPrevBlk	= root:uf:acq:pul:svPrevBlk0000
////	if ( gPrevBlk == -1 )							// Called  only  once  for one initialization before the first block
////		 //ComputeAndUseDacMinMax()			// Autoscale the Dacs : only for the Dac we know the exact signal range in advance . Do it only once even for multiple different blocks( the Dac min/max value is computed over all catenated blocks). 
////	endif
//
//	variable	w,  wCnt	= WndCnt()  
//	for ( w = 0; w < wCnt; w += 1 )										
//		string  	sWNm	= WndNm( w )
//
//		if ( WinType( sWNm ) == UFCom_WT_GRAPH )
//			// 2006-0202		simplify this
//			if ( gPrevBlk == -1 )		 					
//				RemoveTextBoxPP( sWNm )			// remove any old PreparePrinting textbox. 
//				RemoveTextBoxUnits( sWNm )			//here 060608	also removes PreparePrinting Textbox, but should not..
//				RemoveAcqTraces( sWNm )			// erase any leftovers from the preceding block, but this also deletes the Y axis...
//			endif
//			if ( bl != gPrevBlk )
//				RemoveAcqTraces( sWNm )			// erase any leftovers from the preceding block, but this also deletes the Y axis...
//			endif
//
//			//if (			  fr + sw == 0 )			// 2006-0524 this seems to have been wrong : sw was  sweep OR negative e.g. kDISP_FRAME -> last condition was UFCom_TRUE when sw = -kDISP_FRAME
//			if (		 ( fr == 0 && sw == 0 ) )		// ????  more stringent condition ...???? untested  and not understood..??? could new parameter 'nRange' simplify matters???.. 
//				DispDuringAcq( sFo, w,  pr, bl, lap, fr, sw, nRange )
//				// printf "DispDuringAcqCheckLag LagTime():%.1lf \tdisplaying \t(w:%2d/%2d) \r", nLag, w, wCnt
//				// else
//				// printf "DispDuringAcqCheckLag LagTime():%.1lf \t\t\t\tskipping \t(w:%2d/%2d)\r", nLag, w, wCnt
//			endif
//		endif
//	endfor
//// 2006-0202
//	gPrevBlk  = bl
//End
//
//
//static Function	DispDuringAcq( sFo, w,  pr, bl, lap, fr, sw, ra )			// partially  PROTOCOL  AWARE
////  Display superimposed and current sweeps and frames
//	string  	sFo
//	variable	w, pr, bl, lap, fr, sw, ra
//	variable	BegPt, EndPt, Pts, bIsFirst									// will be set by  'Range2Pt()'
//
//	variable	nSmpInt			= UFPE_SmpInt( sFo )
//
//	variable	nCurve, nCurves= CurvesCnt( w )
//	for ( nCurve = 0; nCurve < nCurves; nCurve += 1 )			
//		// printf "\t\t\tDispDurAcq()  prot:%d  block:%2d  frm:%2d  swp:%2d\t [points %6d..\t%6d \t=%6d\t pts]   ( \t\t\t\tbIsFirst:%d ) \r", pr, bl, fr, sw,  BegPt, BegPt+Pts, Pts, bIsFirst
//	variable	nAxisCnt=-1 // 2006-0620  do NOT redraw any axis
//		Range2Pt( sFo, ra, pr, bl, lap, fr, sw, BegPt, EndPt, Pts, bIsFirst )
//		DurAcqDrawTraceAndAxis( sFo, w, nCurve, nAxisCnt, BegPt, Pts, bIsFirst, ra, nSmpInt )	
//	endfor	
//End
//
//
//static  Function	Range2Pt( sFo, nRange,  pr, bl, lap, fr, sw, BegPt, EndPt, Pts, bIsFirst )
//	string  	sFo
//	variable	nRange,  pr, bl, lap, fr, sw
//	variable	&BegPt, &EndPt, &Pts, &bIsFirst
//
//	//svar	/Z	lllstTapeTimes	= $"root:uf:" + sFo + ":" + "lllstTapeTimes" 	
//
//	if ( nRange	== kFRAME )									// (old:sw = -1): one frame is the unit to display
//		BegPt		= UFPE_FrameBegSave( sFo, pr, bl, lap, fr )	
//		EndPt		= UFPE_FrameEndSave_( sFo, pr, bl, lap, fr )		// display the whole frame
//		//bIsFirst		=  !( fr )
//	elseif ( nRange == kPRIM )										// (old sw = -2) : the first sweep in each frame is the unit to display
//		BegPt		= UFPE_FrameBegSave( sFo, pr, bl, lap, fr )	
//		EndPt		= UFPE_SweepEndSave( sFo, pr, bl, lap, fr, 0 )		// display only the first sweep of the frame (useful for skipping the PoN correction pulses)
//		//bIsFirst		=  !( fr )
//	elseif ( nRange == kRESULT )									// (old:sw = -3) : the last sweep in each frame is the unit to display
//		BegPt		= UFPE_SweepBegSave( sFo, pr, bl, lap, fr, UFPE_eSweeps_( sFo, bl ) -1 )	
//		EndPt		= UFPE_FrameEndSave_( sFo, pr, bl, lap, fr )		// display only the last = result sweep of the frame (useful for skipping the PoN correction pulses)
//		//bIsFirst		=  !( fr )
//	else														// nRange	= kSWEEP    and     sw >= 0 : one sweep is the unit to display
//		BegPt		= UFPE_SweepBegSave( sFo, pr, bl, lap, fr, sw )	
//		EndPt		= UFPE_SweepEndSave( sFo, pr, bl, lap, fr, sw )
//		//bIsFirst		=  !( fr + sw )
//	endif
//	Pts			= EndPt - BegPt 
//	bIsFirst		=  ( fr == 0  &&  sw == 0 )
//	// printf "\t\t\tRange2Pt()     trying to draw \t%s\t[nRange:%2d]\tpr:\t%d\tbl:\t%d\tla:%d\tfr:\t%d\tsw:\t%d\t->\tbIsFirst:%2d\tBegPt:\t%7d\tPts:\t%7d\t \r",  UFCom_pd(RangeNmLong( nRange ),8), nRange,  pr, bl, lap, fr, sw, bIsFirst, BegPt, Pts
//End
//
//
//static  Function		DurAcqDrawTraceAndAxis( sFo, w, nCurve, nAxisCnt, BegPt, Pts, bIsFirst, nRange, nSmpInt )	
//// If the user changes the AxoPatch Gain the trace in the Acq Display should keep its height but the Y scaling should adjust. This may occur any time during acquisition. The DAT file will reflect the changed gain only at the beginning of thr next data section.
//	string  	sFo
//	variable	w, nCurve, nAxisCnt, BegPt, Pts, bIsFirst, nRange, nSmpInt
//	variable	sc=0
//
//// 2006-0623  060703  TODO    	1.  test this with  step > 1		2.  get  Xexpand  and   XShiftSecs  either from controls( e.g. slider)  or from  keyboard input (just like Eval)
//variable	XExpand		= 1//2
//pts		= pts / XExpand								// expands data and adjusts scale accordingly
//variable	XShiftSecs	= 0//.03							// shifts the data and the X axis scale accordingly
//BegPt	= BegPt + XShiftSecs / nSmpInt * UFPE_kXSCALE	// shifts data, keeps scale
//
//
//	string 	sWNm	= WndNm( w )							
//	string 	rsChan 	= ""
//	string  	rsRGB	= ""
//	string  	sFolderTNm
//	variable	ra, mo, rbAutoScl, rYOfs, rYZoom, rnAxis
//
//	ExtractCurve( w, nCurve, rsChan, ra, mo, rbAutoScl, rYOfs, rYZoom, rnAxis, rsRGB )				// parameters are changed
//	rnAxis		= UFCom_Clip(  0, rnAxis, YAxisMax() - 1 ) 
//
//	variable	Gain			= GainByNmForDisplay( sFo, rsChan )							// The user may change the AxoPatch Gain any time during acquisition
//
//	 // printf "\t\t\tDurAcqDrawTraceAndAxis(a)  bIs1.%2d\tw:%2d\tcv:%2d\t\tax:%2d\t\t\t\t\tpts:%6d\tra:%d\t %s\t%d r\tmo:%2d\t\t\tZm:\t%7.2lf\tOs:\t%7.2lf\tGn:\t%7.1lf\t'%s' \t%s\tSI:%3d\txss:%g\txxp:%g \r", bIsFirst, w, nCurve, rnAxis, pts, nRange , SelectString( nRange == ra, "!=", "=="), ra, mo, ryZoom, rYOfs, Gain, rsChan, UFCom_pd(rsRGB,15), nSmpInt, XShiftSecs, xExpand
//
// 	sFolderTNm	= "root:uf:" + sFo + ":" + UFPE_ksF_IO + ":" + rsChan
//	// print "DurAcqDrawTraceAndAxis()", sFolderTNm
//
//	if (  Pts > 0   &&   waveExists( $sFolderTNm )   &&    nRange == ra )
//		GetAxis/W=$sWNm /Q $YAxisName( rnAxis ) 									// check if axis exists
//		variable	bRedrawYAxis	= ( V_Flag != 0 )										// remember the fact that there was no such axis BEFORE the following 'DurAcqDrawTrace()' , which will construct an automatic axis, which will be repositioned below in 'DurAcqDrawXPositionOfYAxis()' 
//
//		 printf "\t\t\tDurAcqDrawTraceAndAxis(b.) bIs1.%2d\tw:%2d\tcv:%2d\t\tax:%2d/%2d\t\t\t\tpts:%6d\tra:%d\t %s\t%d r\tmo:%2d\t\tZm:\t%7.2lf\tOs:\t%7.2lf\tGn:\t%7.1lf\t'%s' \t%s\tSI:%3d\tbYax:%2d\r", bIsFirst,w,nCurve,rnAxis,nAxisCnt, pts, nRange , SelectString( nRange == ra, "!=", "=="), ra, mo, ryZoom,rYOfs, Gain,rsChan, UFCom_pd(rsRGB,15), nSmpInt,bRedrawYAxis
//		DurAcqDrawTrace( sFo, w, rnAxis, sWNm, rsChan, BegPt, Pts, bIsFirst, mo, ra, nSmpInt, XShiftSecs, rsRGB, Gain, bRedrawYAxis ) 
//
//// 2006-0620
//		if ( nAxisCnt == UFCom_kNOTFOUND )										//  ' nAxisCnt = UFCom_kNOTFOUND'  means that we have to redraw  Y axis 'rnAxis' 
//			bRedrawYAxis	= UFCom_TRUE										// Construct and draw Y axis only when required : i.e. when there is no axis as its traces have been removed (e.g. when a new block starts)
//			nAxisCnt		= YAxisCnt( w )
//		endif																	//...or  when the user adds or removes axes with the Y Axis listbox control in the ControlBar (in this case ' nAxisCnt = UFCom_kNOTFOUND' is passed as a flag
//
//		if ( bRedrawYAxis )														// Construct and draw Y axis only when required : i.e. when there is no axis as its traces have been removed (e.g. when a new block starts)
//			DurAcqDrawXPositionOfYAxis( sFo, w, rnAxis, nAxisCnt, sWNm, rsChan, rsRGB )	//...or  when the user adds or removes axes with the Y Axis listbox control in the ControlBar (in this case ' nAxisCnt = UFCom_kNOTFOUND' is passed as a flag
//		endif
//		DurAcqRescaleYAxis( rnAxis, sWNm, rYOfs, rYZoom, Gain )							// Rescale Y axis (independently of AutoScaling) as often as possible (here : whenever new data are drawn) as the Gain may change any time during acquisition. 
//																			// Rescaling the  Y axis depends only on  rYOfs, rYZoom and Gain but not on AutoScaling : when AutoScaling is set ON or OFF  rYOfs and rYZoom are set accordingly.
//	endif
//End
//
//
//
//static  Function		DurAcqDrawTrace( sFo, w, nAxis, sWNm, sChan, BegPt, Pts, bIsFirst, nMode, nRange, nSmpInt, XShiftSecs, sRGB, Gain, bRedrawYAxis ) 
//// MANY Mode 2 : all appended traces have same name,  with /Q Flag,     fixed scales after first sweep.... but display is volatile
//// Append: same non-unique wave name for every sweep,   /Q  flag  is used to avoid confusion among the appended waves... 
//// Different  data are displayed under the same name, but any operation (e.g. resize window) destroys the data leaving only the last...
//	string		sFo, sWNm, sChan, sRGB
//	variable	w, nAxis, BegPt, Pts, bIsFirst, nMode, nRange, nSmpInt, XShiftSecs, Gain, bRedrawYAxis
//	variable	rnRed, rnGreen, rnBlue
//
//	UFCom_ExtractColors( sRGB, rnRed , rnGreen, rnBlue )
//
//	string		sTNmUsedNF	= BuildTraceNmForAcqDispNoFolder( sChan, nMode, nRange, BegPt )			
//	string		sTNmUsed 	= BuildTraceNmForAcqDisp( sFo, sChan, nMode, nRange, BegPt )		// the wave 'sTNmUsed' contains the data segment from 'sChan' which is currently to be displayed		
//	// printf "\t\t\t\tDurAcqDrawTrace(1)  \t  \t \tmode: %d\tbIs1:%d\tWNm: '%s' \tsChan:%s ->\t%s  \tnAxis[ w:%2d ] = %d \t\t\t\t\t\t\t\t[cnt:%3d]\tTNL1: '%s'  \r", nMode, bIsFirst, sWNm, sChan, UFCom_pd(sTNmUsed,22),  w, nAxis, ItemsInList( TraceNameList( sWNm, ";", 1 )  ),  TraceNameList( sWNm, ";", 1 )  
//
//	CopyExtractedSweep( sFo, sChan, sTNmUsed, BegPt, Pts, nSmpInt, XShiftSecs, Gain )			// We compute the new trace i.e. we update the data in 'sTNmUsed'  no matter whether we actually do 'AppendToGraph' below .
//
//	// During acq the traces are regularly erased, so 'AppendToGraph' either actually draws the first trace in a blank window or (if it is not the 1. trace) the existing (not erased) trace is given new data....
//	// Avoid drawing the same trace multiple times one over the other which impairs performance. This would occur e.g. when moving the YOfs slider. Within seconds hundreds of traces could accumulate... 
//	if ( WhichListItem( sTNmUsedNF, TraceNameList( sWNm, ";", 1 ) ) == UFCom_kNOTFOUND )		// For Redrawing outside acq ( e.g. after changing zoom, ofs ) the traces are not erased, they exist : here  we avoid drawing them over and over #1, #2, #3... when the YOfs slider is moved 
//		if ( nMode == kMANYSUPIMP   ||   ( nMode == kCURRENT && bIsFirst ) )					// in CURRENT mode the trace is appended only once : IGOR updates automatically
//
//			if ( nAxis == 0 ) 															// append the first trace with its Y Axis to the left....
//				 AppendToGraph /Q /L 				/W=$sWNm	/C=( rnRed, rnGreen, rnBlue ) $sTNmUsed
//			else																	// ..append all other traces with their Y Axis to the right
//				// Here the connection is made between a certain trace and its accompanying axis name !  AxisInfo  will return  the name of the controlling wave 
//				 AppendToGraph /Q /R=$YAxisName( nAxis ) /W=$sWNm  /C=( rnRed, rnGreen, rnBlue ) $sTNmUsed 
//			endif
//
//			// printf "\t\t\t\tDurAcqDrawTrace(2) after appending \tmode: %d\tbIs1:%d\tWNm: '%s' \tsChan:%s ->\t%s  \tnAxis[ w:%2d ] = %d \tvalid for nAxis != 0: AxNm: '%s'\t[cnt:%3d]\tTNL1: '%s'  \r", nMode, bIsFirst, sWNm, sChan, UFCom_pd(sTNmUsed,22),  w, nAxis, YAxisName( nAxis ), ItemsInList( TraceNameList( sWNm, ";", 1 )  ),  TraceNameList( sWNm, ";", 1 )  
//		endif
//	endif
//
//	if ( UFCom_DebugVar( "DispDurAcq" ) )
//		printf "\t\t\tDispDurAcq %s\t\t%s\tWnd:'%-16s' \tOrg:'%-10s'  \tOne:'%-18s'  \tbIsFirst:%d   BegPt:%d  PTS:%d ->pts:%d \r", "A?U", ModeNm( nMode ), sWNm, sChan, sTNmUsed, bIsFirst, BegPt, Pts, numPnts($ sTNmUsed)
//	endif		
//	//return	xScl
//End

//static  Function	/S	BuildTraceNmForAcqDisp( sFo, sChan, nMode, nRange, BegPt )
// 	string		sFo, sChan
// 	variable	nMode, nRange, BegPt
//	return	"root:uf:" + ksACQ + ":dispFS:" + BuildTraceNmForAcqDispNoFolder( sChan, nMode, nRange, BegPt )
//End
//
//static  Function	/S	BuildTraceNmForAcqDispNoFolder( sChan, nMode, nRange, BegPt )
// 	string		sChan
// 	variable	nMode, nRange, BegPt
// 	string		sBegPt
//	sprintf	sBegPt, "%d",  BegPt			// formats correctly  e.g. 160000 (wrong:num2str( BegPt ) formats 1.6e+05 which contains dot which is illegal in wave name..) 
//	string  	sTNm	= sChan + BuildMoRaName( nRange, nMode ) + ksMORA_PTSEP		// e.g.Adc0 + SM + _
//	
//	//  PERSISTENT DISPLAY  requires keeping a list of unique partial waves ( volatile display would be much simpler but vanishes when resizing a graph...)
//	// another approach: use block/frame/sweep composed number to uniquely identify the trace
//	if (  nMode == kMANYSUPIMP )			// append each trace while not clearing previous ones and  display in a persistent manner: needs a unique name
//		// Adding any unique number (e.g. the starting point or the frame/sweep) to the trace name makes the trace name also unique  leading to consequences: 
//		// 	1. memory is occupied for each wave, not only for one 	2. the display is no longer  volatile, when window is resized or when anything is drawn
//		return	sTNm + sBegPt			// e.g.   Adc0SM_160000 
//	else
//		return	sTNm				// in CURRENT mode it must be always the same (non-unique) name
//	endif
//End
//

//static constant	cAXISMARGIN			= .11			// Supply this width for additional right Y axes at the right plot area border (and for the units textbox) .  Value is a compromise, there is no perfect value.
//
//static  Function		 DurAcqDrawXPositionOfYAxis( sFo, w, nAxis, nYAxisCnt, sWNm, sTNm, sRGB )
////  Drawing multiple Y axis is a bit complicated for a variety of reasons:
//// - depending on the number of traces / curves in a window, we want to position the axes neatly: the first to the left, all others to the right of the plot area
//// - the drawing routine is called in an order determined by the frames and sweeps whenever they are ready to be drawn
//// - the window / trace / usedTrace  is independent of the frames / sweeps order  and can (and will most probably) be COMPLETELY mixed up
//// This leads to the complex code requiring  some bookkeeping with the help of  nYAxisCnt
//// - drawing the axis should be done as seldom as possible: only when really needed that is right in the very first display update
//// Flaw: When the graph window is very small or very large the position of a  right Yaxis units textbox will  no longer be exactly above its right Y axis, but the textbox can be moved quickly by hand.
//	variable	w, nAxis, nYAxisCnt
//	string		sFo, sWNm, sTNm, sRGB
//	string		rsNm, rsUnits
//	NameUnitsByNm( sFo, sTNm, rsNm, rsUnits )								
//	variable	rnRed, rnGreen, rnBlue
//	UFCom_ExtractColors( sRGB, rnRed , rnGreen, rnBlue )
//
//	string		sAxisNm		= YAxisName( nAxis ) 									
//
//	// Version 1 :	Position Y axis  'right3'  at the bottom axis end   						if  'right1'  and/or  'right2'  are missing	e.g.	0__________1	 or	0_____3
//	//variable	AxPosFactor	= cAXISMARGIN *  nAxis 	
//	// Version 2 :	Leave a gap between the bottom axis end and the position of Y axis  'right3'	if  'right1'  and/or  'right2'  are missing	e.g.	0__________1	 or	0_____         3
//	variable	AxPosFactor	= cAXISMARGIN * ( nYAxisCnt - nAxis )
//
//	// Prevent  IGOR  from drawing the units (set in 'CopyExtractedSweep()'  automatically instead draw the Y units manually as a Textbox  just above the corresponding Y Axis  in the same color as the corresponding trace  
//	// As it seems impossible to place the textbox automatically at the PERFECT position (not overlapping anything else, not blowing up the graph too much: position depends on units length, graph size, font size)  the user may have to move it a bit (which is very fast and very easy)...
//	Label  		/W=$sWNm 		   $sAxisNm  	"\\u#2"							// Prevent  IGOR  from drawing the units
//	ModifyGraph	/W=$sWNm axisEnab( $sAxisNm )	= { 0, .96 }							//  supplies a small margin at the top of each Y axis  for the Channel name and the axis units
//
//	//  Draw the  Units in a TextBox (rather than letting Igor draw them) .  The textbox has the same name as its corresponding axis: this allows easy deletion together with the axis (from the 'Axes and Scalebars' Panel)
//	variable	TboxXPos	= nAxis == 0 ? -54 : 56 - 100 * AxPosFactor							// left, left right,  left mid right...    -54 and 56 are magic numbers which  are adjusted  so that the text is at the same  X as the axis. They SHOULD be   #defined.....
//	TextBox 	/W=$sWNm /C /N=$sAxisNm  /E=0 /A=MC /X=(TboxXPos)  /Y=52  /F=0  /G=(rnRed, rnGreen, rnBlue)   rsNm + "/ " + rsUnits	// print YUnits horiz.  /E=0: rel. position as percentage of plot area size 
//	// printf "\t\t\t\tDurAcqDrawXPositionOfYAxis(a)\tw:%2d\t\t\tax:%2d/%2d\t%s  TxP:%d\t\t\t\t\t\t\t\t \r", w, nAxis, nYAxisCnt, UFCom_pd(sAxisNm,5), TboxXPos
//
//// 2006-0606
//	// Demo/Sample code to prevent Igor form switching  the axis ticks  8000, 9000, 9999, 10, 11  (this would be fine if we had not hidden Igors Axis units as they were not located neatly..)
//	// Different approach (not taken) : switch  mV -> V , pA -> nA etc. whenever Igor crosses his  'highTrip'  value  (default seems to be 10000)
//	 ModifyGraph  /W=$sWNm  highTrip( $sAxisNm	 )    = 100000							// 2003-1103
//	if ( nAxis > 0 )	
//		ModifyGraph /W=$sWNm axisEnab( bottom )   = { 0, 1 - ( nYAxisCnt - 1 ) * cAXISMARGIN }	// make the bottom axis shorter to supply space for the additional Y axes on the right side of the graph
//		ModifyGraph /W=$sWNm freePos( $sAxisNm ) = {  AxPosFactor, kwFraction }			// draw the current Y axis at this position (value is referred to bottom axis data values)
//	endif
//End
//
////remake static
//  Function		DurAcqRescaleYAxis( nAxis, sWNm, YOfs, YZoom, Gain )	
//// Similar to  DurAcqRescaleYAxisOld()  but rather than storing the axis end values, checking for changes and possible rescaling  here no values are stored or checked but the rescaling is done every time (this is much simpler but could be slower...)
//	variable	nAxis, YOfs, YZoom, Gain
//	string		sWNm
//	variable	AdcRange			= 10								//  + - Volt
//	variable	yAxis 			= AdcRange * 1000  / YZoom						
//	variable	NegLimit			= - yAxis / Gain + YOfs
//	variable	PosLimit			=   yAxis / Gain + YOfs
////	wave   /T	wAxisName		= root:uf:acq:disp:wYAxisName
//	SetAxis /Z /W=$sWNm $YAxisName( nAxis ),  NegLimit, PosLimit
//End
//
////--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//
//static  Function		YAxisMax()
//// Retieve the maximum number of  allowed  Y axes 
//	return	ItemsInList( klstAXIS_NAMES )
//End
//
//static  Function	/S	YAxisName( ax )
//	variable	ax
//	return	StringFromList( ax, klstAXIS_NAMES )
//End
//
//static  Function		YAxisCnt( w )
//// Retieve the number of  used Y axes for each window.  This is often just the number of curves but it could also be less if some traces share the same Yaxis.
//	variable	w
//	variable	nCurve, nCurves= CurvesCnt( w )
//	string  	sAxis			= ""
//	string  	lstUsedAxis	= klstAXIS_NAMES				// e.g  'left;right1;right2;right3;' 
//	variable	nAxis, nAxes	= 0
//	for ( nCurve = 0; nCurve < nCurves; nCurve += 1 )
//
////		// Version1: Simply count all different axes:	'left;right2;'	 will  return  2.  If this code is used then after the deletion of axis 'right1'  the last axis 'right2'  must move automatically to the now empty position of axis 'right1'  as only space for 2 axis is provided.
////		string sCurve= CurvesOneCurve( w, nCurve )
////		nAxis		= str2num( StringFromList( kCV_AXIS, sCurve ) )
////		sAxis		= StringFromList( nAxis, klstAXIS_NAMES )
////		lstUsedAxis= RemoveFromList( sAxis, lstUsedAxis )				// e.g  'left;right1;right2;right3;'  ->  'left;right2;right3;'   if  nAxis=1  is removed
////		nAxes	= ItemsInList( klstAXIS_NAMES ) - ItemsInList( lstUsedAxis ) 	
//
//		// Version2: Return the index of the highest used axis + 1:  'left;right2;'  will  return  3 .   If this code is used it is after the deletion of axis 'right1' the users responsability to change all curves with axis 'right2' to 'right1'  to avoid an empty gap in the X axis.
//		nAxis		= str2num( CurveRetrieveParameter( w, nCurve, kCV_AXIS ) )
//		sAxis		= StringFromList( nAxis, klstAXIS_NAMES )				// here only for debug printing
//		nAxes	= max( nAxis + 1, nAxes )
//
//		// printf "\t\t\t\t\tYAxisCnt(1) : %d \t\t\tw:%2d\tcvs:\t  %2d\t%s\tRemoving axis%2d '%s'   \tUnUsedAxes:\t%s\t->\tAxisCnt:%2d\t[Curve:\t'%s' ]\r", nAxis, w, CurvesCnt( w ), klstAXIS_NAMES, nAxis, sAxis, UFCom_pd( lstUsedAxis,20), nAxes, CurvesOneCurve( w, nCurve )
//	endfor
//
//	// printf "\t\t\t\t\tYAxisCnt(2) : %d \t\t\tw:%2d\tcvs:\t  %2d\t%s\tRemoving axis%2d '%s'   \t->\tAxisCnt:%2d \r", nAxis, w, CurvesCnt( w ), klstAXIS_NAMES, nAxis, sAxis,  nAxes
//	return	nAxes
//End
//
////--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//
//static   Function		CopyExtractedSweep( sFo, sOrg, sOneDisp, BegPt, nPts, nSmpInt, XShiftSecs, Gain )
//// do not draw all points of wave but only 'nDrawPts' : speed things up much  by loosing a little display fidelity
//// going in steps through the original wave makes waveform arithmetic impossible but is still much faster
//	string		sFo, sOrg, sOneDisp												// sOrg   is the same as elsewhere  sTNm
//	variable	BegPt, nPts, nSmpInt, XShiftSecs, Gain
//	variable	bHighResolution = HighResolution()
//	variable	n, nDrawPts 	 = 1000											// arbitrary value				
//
//	variable	step	= bHighResolution ? 1 :  trunc( max( nPts / nDrawPts, 1 ) )
//	//variable	step = trunc( max( nPts / nDrawPts, 1 ) )
//	
//	string  	sFolderOrg	
// 	sFolderOrg	= "root:uf:" + sFo + ":" + UFPE_ksF_IO + ":" + sOrg
//
//	if ( waveExists( $sFolderOrg ) )								
//		wave	wOrgData	= $sFolderOrg
//		make    /O /N = ( nPts / step )	$sOneDisp								//( "root:uf:acq:tmp:"  + sOneDisp )
//		wave	wOneDispWaveCur = $sOneDisp								//( "root:uf:acq:tmp:"  + sOneDisp )
//
//		// 2003-0610 new   it should be sufficient to do this only once during initialization
//		string 	sUnits	=  UnitsByNm( sFo, sOrg )								// Store the Y units of the wave within the wave to make it accessible for 'Scalebars()'...
//		SetScale /P y, 0, 0,  sUnits,  wOneDispWaveCur								//..while at the same time prevent Igor from drawing them   ( Label...."\\u#2" ) 
//
//		SetScale /P X, XShiftSecs, nSmpInt / UFPE_kXSCALE * step, UFPE_ksXUNIT, wOneDispWaveCur 	// /P x 0, number : expand in x by number (Integer wave: change scale from points into ms using the SmpInt) .  XShiftSecs  shifts only the X axis scale but not the data
//
//
//		// printf "\t\t\t\t\tDispDurAcq() CopyExtractedSweep() '%s' \t%s\tBegPt:\t%8d\tPts:\t%8d\t   DrawPts:%d  step:%d  xscl:\t%10.4lf\txfactor:%g   Gain:%g \tsize:%.2lf=?=%d  sizeOrg:%d \r", sFolderOrg, UFCom_pd( sOneDisp, 26), BegPt, nPts, nDrawPts, step, nSmpInt / UFPE_kXSCALE * step, nSmpInt / UFPE_kXSCALE*step, Gain, nPts/step, numPnts($sOneDisp), numPnts( $sOrg )
//// 2004-0209
//// WRONG  for ( n = 0; n <   nPts; 		n += step )		// 2004-0209 WRONG:  wFloat tries to write  into the next after the LAST element , which does no harm in IGOR but crashes the XOP
//// 		   for ( n = 0; n <= nPts - nStep; 	n += step )
////		 	wOneDispWaveCur[ n / step ] = wOrgData[ BegPt + n ] /  Gain
////		   endfor
//		variable	code	= UFCom_UtilWaveExtract( wOneDispWaveCur, wOrgData, nPts, BegPt, step, 1/Gain )	// XOP because Igor is too slow  ,   Params: float tgt. float src, nPnts...
//		if ( code )
//			printf "****Error: UFCom_UtilWaveExtract() \r"
//		endif
//
//	endif
//End
//
////--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//
//static Function	/S	Nm2Color( sFo, sTNm )
//// Retrieves and returns 'RGB' entry from script when the channel name is given,  e.g. 'Adc0'  or  'Dac2'
//	string 	sFo, sTNm
//	variable	nio, cio
//	string	 	sColor
//	wave  /T	wIO	= $"root:uf:" + sFo + ":ar:wIO"  				
//	UFPE_ioNm2NioC( wIO, sTNm, nio, cio )
//	sColor		= UFPE_ios( wIO, nio, cio, UFPE_IO_RGB )
//	 printf "\t\tNm2Color( \t\t\t'%s',  '%s' ) : color: '%s'    \r", sFo, sTNm, sColor
//	return	sColor
//End
//
//static Function	/S	UnitsByNm( sFo, sTNm )
//// Retrieves and returns 'Units' entry from script when the channel name is given,  e.g. 'Adc0'  or  'Dac2'
//	string 	sFo, sTNm
//	variable	nio, cio
//	string	 	sUnit	
//	wave  /T	wIO	= $"root:uf:" + sFo + ":ar:wIO"  				
//	UFPE_ioNm2NioC( wIO, sTNm, nio, cio )
//	sUnit			= UFPE_ios( wIO, nio, cio, UFPE_IO_UNIT )
//	 // printf "\t\tUnitsByNm( \t\t\t'%s',  sTNm:'%s' ) : unit: '%s'   \r", sFo, sTNm, sUnit
//	return	sUnit
//End
//
//static Function		NameUnitsByNm( sFo, sTNm, rsName, rsUnit )
//// Retrieves and passes back  'Name'  and   'Units'  entry from script when the channel name is given,  e.g. 'Adc0'  or  'Dac2'
//	string 	sFo, sTNm
//	string 	&rsName, &rsUnit
//	variable	nio, cio
//	wave  /T	wIO		 = $"root:uf:" + sFo + ":ar:wIO"  				
//	UFPE_ioNm2NioC( wIO, sTNm, nio, cio )
//	rsUnit	= UFPE_ios( wIO, nio, cio, UFPE_IO_UNIT )
//	rsName	= UFPE_ios( wIO, nio, cio, UFPE_IO_NAME )
//	// 2006-0608
//	if ( strlen( rsName ) == 0 )								// if the user has not specified the name of the channel in the script (e.g Dac: Chan=0; Name=Stimulus0; ... )
//		rsName	= UFPE_ios( wIO, nio, cio, UFPE_IO_NM )		//...then the simple inherent name  'Dac0'  or  'Adc1'   or similar is used.
//	endif
//	// printf "\t\tNameUnitsByNm( \t%s , %s) :  unit:'%s'    name:'%s'   \r", sFo, sTNm, rsUnit, rsName
//	// todo : possibly return bFound = UFCom_kNOTFOUND  to distinguish between  'Entry was empty' (it not returning default)  and   'NoMatchingTraceFound'  (actually the latter should not occur)
//End
//
//Function		GainByNmForDisplay( sFo, sTNm )
//// Retrieves and returns gain for displaying traces  when the channel name is given,  e.g. 'Adc0'  or  'Dac2'
//// The DISPLAY Gain for Dacs is always 1 no matter what the script gain is  as the script  Dac gain affects only the voltage output, not the displayed traces.
//// The display of  Adc  and  PoN  traces is effected by their gain.   [ Exotic traces traces like  'Aver'  or  'Sum'   (not yet used)   are also effected by their gain, this behaviour could in the future be changed here...
//	string 	sFo, sTNm
//	variable	Gain		= 1
//	variable	nio, cio
//	string 	sSrc		= "none"
//	variable	nSrcIO, nSrcC
//	wave  /T	wIO		= $"root:uf:" + sFo + ":ar:wIO"  		
//	UFPE_ioNm2NioC( wIO, sTNm, nio, cio )
//	if ( IsDacTrace( sTNm ) )
//		Gain	= 1											// For displaying Dac traces we must ignore the Gain. The Dac gain affects only the voltage output, not the displayed traces.
//	elseif ( IsPoNTrace( sTNm ) )
//		sSrc	= "Adc" + UFPE_ios( wIO, nio, cio, UFPE_IO_SRC ) 		// Assumption: naming convention
//		UFPE_ioNm2NioC( wIO, sSrc, nSrcIO, nSrcC )
//		Gain	= UFPE_iov( wIO, nSrcIO, nSrcC, UFPE_IO_GAIN )		// PoN traces have no explicit gain but inherit it from their 'Adc' src channel.
//	else				
//		Gain	= UFPE_iov( wIO, nio, cio, UFPE_IO_GAIN )	
//	endif
//	if ( numType( gain ) == UFCom_kNUMTYPE_NAN )
//	 printf "\t\t\t\t\tGainByNmForDisplay( '%s' ) \t-> cio:%2d\thas Src:\t%s\treturns display gain:\t%7.2lf\t\t(Dacs always return 1) \r", UFCom_pd(sTNm,9), cio, UFCom_pd( sSrc,6), Gain
//	endif
//	return	Gain
//End
//
////--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//// Action procedure called whenever the AxoPatch gain setting in the FPulse main panel is changed 
//
// Function	/S	fGainHt( sBaseNm, sF, sWin )
//	string  	sBaseNm, sF		// e.g. 'root:uf:acq:'
//	string  	sWin 
//	string  	lstAllADs	  = LstAllAD( sBaseNm, sF, sWin )
//	variable	nGainRows = ItemsInList( LstAllADs, UFCom_ksSEP_STD )
//	//print "fGainHt()",  sBaseNm, sF, sWin, lstAllADs, "returns: ", nGainRows
//	return num2str( nGainRows ) 
//End
//
//
//Function		fGain( s )
//// Store the gain just set by the user in 'wIO' . This is needed  in WriteCFS .
//	struct	WMSetvariableAction  &s
//	variable	nio		= UFPE_IOT_ADC
//	variable	cio		= UFCom_RowIdx( s.ctrlname )							// cio : the linear Adc index in script passed with the variable name as postfix
//	variable	Gn		= s.dval
//	string  	sFo		= ksACQ
//	string  	sChan
//
//if ( NewStyle( sFo ) == kPULSE_OLD )
//	wave  /T	wIO		= $"root:uf:" + sFo + ":ar:wIO"  							// This  'wIO'	is valid in FPulse ( Acquisition )
//	UFPE_ioSet( wIO, nio, cio, UFPE_IO_GAIN, num2str( Gn ) )						
//	printf "\t\tfGain()  \t\tsControlNm: %s   \tvarName:%s   \t\t:setting wIO[ nio:%d, cio:%d UFPE_IO_GAIN ] =%g\t=?= %g \t'%s'\r", s.ctrlname,  s.vName , nio, cio, Gn, UFPE_iov( wIO, nio, cio, UFPE_IO_GAIN ),  UFPE_ios( wIO, nio, cio, UFPE_IO_NM )
//	
//	// The new Gain has now been set and will be effective during the next acquisition, but for the user to see immediately that his change has been accepted....
//	PossiblyAdjstSliderInAllWindows( sFo )										//....we change the slider limits in all windows which contain this AD channel   ( this is optional and could be commented out )
//// 2006-0607
////	DisplayOffLineAllWindows( sFo  )											// This is to display a changed Y axis in all windows which contain this AD channel   ( could probably be done simpler and more directly.....)
//	// The new Gain will be effective during the next acquisition, but to immediately give some feedback to the user that his Gain change has been accepted we change the Y Axis range in every instance of 'sChan' in all windows 
//	sChan	= UFPE_ios( wIO, nio, cio, UFPE_IO_NM )							// e.g 'Adc1'
//else
//	svar	/Z	lllstIO	= $"root:uf:" + sFo + ":lllstIO"  						
//	// print "todo_a: lst = UFPE_ioSet_ns()...fGain()   neu is OK"
//	lllstIO	= UFPE_ioSet_ns( lllstIO, nio, cio, kSC_IO_GAIN, num2str( Gn ) )						
//	printf "\t\tfGain()  \t\tsControlNm: %s   \tvarName:%s   \t\t:setting lllstIO[ nio:%d, cio:%d kSC_IO_GAIN ] =%g\t=?= %g \t'%s' '%s'\r", s.ctrlname,  s.vName , nio, cio, Gn, UFPE_iov_ns( lllstIO, nio, cio, kSC_IO_GAIN ),  UFPE_ioItem( lllstIO, nio, cio, kSC_IO_NAME),  UFPE_ioItem( lllstIO, nio, cio, kSC_IO_CHAN)
//	LstIoSet( sFo, lllstIO )													// make gain changes permanent by storing  'lllstIO'  globally 
//	
//	// The new Gain has now been set and will be effective during the next acquisition, but for the user to see immediately that his change has been accepted....
//	PossiblyAdjstSliderInAllWindows( sFo )										//....we change the slider limits in all windows which contain this AD channel   ( this is optional and could be commented out )
//// 2006-0607
////	DisplayOffLineAllWindows( sFo  )											// This is to display a changed Y axis in all windows which contain this AD channel   ( could probably be done simpler and more directly.....)
//	// The new Gain will be effective during the next acquisition, but to immediately give some feedback to the user that his Gain change has been accepted we change the Y Axis range in every instance of 'sChan' in all windows 
//	sChan	= UFPE_ioItem( lllstIO, nio, cio, UFPE_IO_NM )						// e.g 'Adc1'
//endif
//
//	variable	Gain		= GainByNmForDisplay( sFo, sChan )						// The user may change the AxoPatch Gain any time during acquisition
//	variable	w
//	for ( w = 0; w < kMAX_ACDIS_WNDS; w += 1 )
//		string  	sWNm	= WndNm( w )
//		if ( WinType( sWNm ) == UFCom_WT_GRAPH )
//			string  	sTNL			= TraceNameList( sWNm, ";", 1 )
//			string  	sMatchingTraces	= ListMatch( sTNL, sChan + "*" )			// e.g. 'Adc1SC_;Adc1FM_1000;Adc1xxxx;'  : any mode and any range 	
//			variable	mt, nMatchingTraces	= ItemsInList( sMatchingTraces )
//			string  	rsRGB											// parameters are set by  ExtractCurve()
//			variable	ra, mo, rbAutoscl, rYOfs, rYZoom, rnAxis					// parameters are set by  ExtractMoRaName()  and  ExtractCurve()
//			for ( mt = 0; mt < nMatchingTraces; mt += 1 )
//				string  	sTNm	= StringFromList( mt, sMatchingTraces )		// e.g. 'Adc1SC_'  or  'Adc1FM_1000'
//				string  	sMoRa	= sTNm[ strlen( sChan ), strlen( sChan ) + 1 ] 	// e.g. 'SC'  or  'FM'
//				ExtractMoRaName( sMoRa, ra, mo )
//				variable  	nCurve	= ExtractCurves( w, sChan, ra, mo, rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB )// Extract the one and only curve 'nCurve' with matching ' sChan, ra, mo' and from this the remaining (now valid) parameters 'rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB' 
//				DurAcqRescaleYAxis( rnAxis, sWNm, rYOfs, rYZoom, Gain )
//			endfor
//		endif
//	endfor
//End

//Function	/S	AxoGainControlName( row ) 
//	variable	row
//	return	"root_uf_acq_pul_svAxogain00" + num2str( row ) + "0"
//End
//Function		SetAxoGainInPanel( row, Gain ) 
//	variable	row, Gain
//	nvar		 Gn	= $"root:uf:acq:pul:svAxogain00" + num2str( row ) + "0"
//	Gn	= Gain
//End
//
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//Function		KillTracesInMatchingGraphs( sMatch )
//	string 		sMatch
//	string 		sDeleteList	= WinList( sMatch,  ";" , "WIN:" + num2str( UFCom_WT_GRAPH ) )		// 1 is graph
//	variable	n
//	// kill all matching windows
//	for ( n =0; n < ItemsInList( sDeleteList ); n += 1 )
//		string  	sWNm	= StringFromList( n, sDeleteList ) 
//		RemoveTextBoxUnits( sWNm ) 	// Must remove TextboxUnits BEFORE the traces/axis as they are linked to the axis. If 'Units' had not to be drawn separately (as perhaps only in Igor4?)  the clearing would occur automatically together with the traces
//		UFCom_EraseTracesInGraph( sWNm )
//	endfor
//End

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//static  Function		RemoveTextBoxPP( sWNm )
//	string	sWNm
//	// remove the 'PreparePrinting'  textbox  from the given  acq window
//	TextBox	/W=$sWNm   /K  /N=$TBNamePP()
//End

//static  Function		RemoveTextBoxUnits( sWNm )
//// remove all  yUnits textboxes from the given  acq window (they must have the same name as the corresponding axis)
//	string		sWNm
//	variable	n
//	//string 	sTBList	=  AnnotationList( sWNm )		// Version1: removes ALL annotations : axis unit   and also   PreparePrinting textbox (removing the latter is usually undesired)
//	string 	sTBList	=  AxisList( sWNm )			// Version2: removes  only  axis unit annotations, but only if they cohere to the standard 'Axis unit annotation name = Axis name'
//	for ( n = 0; n < ItemsInList( sTBList ); n += 1 )
//		string		sTBNm	= StringFromList( n, sTBList )
//		TextBox	/W=$sWNm   /K  /N=$sTBNm
//		// printf "\t\t\t\tRemoveTextBoxUnits( %s )  n:%2d/%2d   \tTBName:'%s' \t'%s'  \r", sWNm, n,  ItemsInList( sTBList ), sTBNm, sTBList
//	endfor
//End
//
//static  Function		RemoveAcqTraces( sWNm )
//// erases all traces in this window (must exist)  and  brings window to front  
//	string 	sWNm
//// 2006-0509
////	EraseTracesInGraphExceptOld( sWNm, UFPE_ksOR )					// 'or'   excludes  Online results
//	UFCom_EraseTracesInGraphExcept( sWNm, UFPE_ksOR+";"+UFPE_ksCSR+";"+UFPE_ksORS ) 	// only erase data units traces, but leave cursors and OLA results ???????
//	DoWindow /F $sWNm					// bring to front
//End
//
//
//// currently not used 060519
////Function		GetFinalSweepNr(  wG, wFix )
////	wave  	 wG, wFix
////	variable	b, f, SweepCnt = 0
////	for ( b  = 0; b < UFPE_eBlocks( sFo ); b += 1 )
////		for ( f = 0; f < UFPE_eFrames_( sFo, b ); f += 1)
////			SweepCnt += UFPE_eSweeps_( sFo, b )
////		endfor
////	endfor
////	// print "GetFinalSweepNr()", SweepCnt,	vGet( "Sweeps", "N" ) * vGet( "Frames", "N" ) 	// PULSE only
////	return	SweepCnt
////End
//
//
////--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
////   ACQUISITION  WINDOW  HOOK  FUNCTION
//
//Function		 fAcqWndHook( s )
//// Here we handle all user actions (=mouse events)  executed in any  acquisition window.
//// Executed whenever the mouse is moved within one of the acquisition windows. Gets mouse position in pixels and computes wave and cursor values in axis coordinates which are displayed in the Panel.
//	struct  	WMWinHookStruct  &s
//	string  	sFolders		= ksF_ACQ_PUL					// 'acq:pul'
//	wave	wCurRegion	= $"root:uf:" + sFolders + ":wCurRegion"	// 2006-0330
//	nvar		gCursX		= root:uf:acq:pul:svCursorX0000
//	nvar		gCursY		= root:uf:acq:pul:vdCursorY0000
//
//	variable	nReturnCode	= 0								// 0 if nothing done, else 1 or 2 (prevents killing)
//	variable	w, wCnt
//
//	variable 	isClick	= ( s.eventCode == UFCom_WHK_mouseup ) + ( s.eventCode == UFCom_WHK_mousedown )	// a click is either a MouseUp or a MouseDown (recognised only IN graph area, not on title area)
//	
//	// Transform mouse pixels into axis coordinates and store globally (needed always as it is displayed in the StatusBar)	
//	gCursX	= numType( s.mouseLoc.h ) != UFCom_kNUMTYPE_NAN ? AxisValFromPixel( s.winName , "bottom", s.mouseLoc.h  ) : 0
//	gCursY	= numType( s.mouseLoc.v ) != UFCom_kNUMTYPE_NAN ? AxisValFromPixel( s.winName , "left",       s.mouseLoc.v ) : 0
//
//	// To speed things up, we quit immediately when the event  is MOUSEMOVE (which is almost always the case)
//	// We proceed only for the rarely occuring MOUSEUP and MOUSEDOWN events which are the only events processed below
//	// printf "\t\tfAcqWndHook event (including 'mousemoved' ):'%s'   \t in wnd '%s'  (wCnt:%d) \r", s.eventName, sWnd, WndCnt()
//
//	if ( s.eventCode	== UFCom_WHK_mousemoved )
//		 // printf "\tfAcqWndHook(9 : returning prematurely (only mouse moves)  Time: %s\r", Time()
//		return 0 
//	endif
//	// printf "\t\tfAcqWndHook event (except 'mousemoved' ):%s \t in wnd '%s'  (wCnt:%d) [KeyModifier:%d]  Cursors: %g / %g\tyPt:%g \r", UFCom_pd(s.eventName,11), s.winName, WndCnt(), s.eventMod, gCursX, gCursY, s.YPointNumber
//
//	//  MOUSE  PROCESSING  // here  060330
//	if( isClick )												// can be either mouse up or mouse down
//		wCurRegion[ UFPE_kXMOUSE ]	= gCursX						// last clicked x is needed for 'FindAndMoveClosestCursor()' . This allows selection of cursors in different regions  with only 1 button/cursor
//	endif	
//
//	// Adjust the YOfs slider size to the graph size whenever the graph is resized
//	w	= WndNr( s.winName ) 
//	if ( s.eventCode	== UFCom_WHK_resize )
//		variable	bAcqControlbar = AcqControlBar( w )
//
//		string  	sChan, rsRGB
//		variable	nCurve, ra, mo, rbAutoscl, rYOfs, rYZoom, rnAxis
//		string  	sCurve 		= GetUserData( 	s.winName,  "",  "sCurve" )					// Get UD sCurve 
//		if ( strlen( sCurve ) )														// at the first start  (before the user has selected a curve)  sCurve is still empty
//			ExtractChMoRaFromCurve( sCurve, sChan, ra, mo )								// here only 'rsChan, ra, mo'  are extracted from  the curve , the remaining parameters contain old invalid values (as the curve has been set only once when the controlbar was constructed)
//			nCurve	= ExtractCurves( w, sChan, ra, mo, rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB )		// Extract the one and only curve 'nCurve' with matching ' sChan, ra, mo' and from this the remaining (now valid) parameters 'rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB' 
//	
//			variable	bDisableCtrlOfs	= DisableCtrlZoomOfs(   sChan, bAcqControlbar, rbAutoscl ) 
//	
//			string  	sFo		= StringFromList( 0, sFolders, ":" )						// 'acq:pul'  ->  'acq'
//			variable	Gain			= GainByNmForDisplay( sFo, sChan )
//			ConstructCbSliderYOfs( s.winName, bDisableCtrlOfs, rYOfs, Gain )						// Construct the optional Controlbar on the right (only in Igor5+) 
//		endif
//	endif
//
//	return	nReturnCode						// 0 if nothing done, else 1 or 2 (prevents killing)
//End


//=====================================================================================================================================
//      AFTER  ACQ :   DISPLAY  RESULT  TRACES   after the Acquisition has finished

//strconstant	ksAFTERACQ_WNM	= "AfterAcq"	// 

// Function	DisplayRawAftAcq()
//// displays  COMPLETE  traces  AFTER  acquisition is  finished (displays complete waves, all sweeps and frames in one trace) 
//// too slow when every point is checked (whether it lies within or outside a SAVE period) and drawn: decimating to 'nDrawPts'
//	string  	sFo	= ksACQ
//	wave  /T	wIO		= $"root:uf:" + sFo + ":ar:wIO"  			// This  'wIO'   	is valid in FPulse ( Acquisition )
//	variable	bDisplayAllPtsAA	= DisplayAllPointsAA()
//	variable	nSmpInt			= UFPE_SmpInt( sFo )
//	variable	PreNoSaveStart, PreNoSaveStop, PostNoSaveStart, PostNoSaveStop 
//	// Get  traces to be displayed after acquisition  (these are the same traces / data as during acquisition)
//	variable	f, b, s, rnLeft, rnTop, rnRight, rnBot,  pt, nPts
//	variable	n, step, nDrawPts = 1000, pr
//	string  	sTNm, sFolderTNm, sRGB
//	variable	rnRed, rnGreen, rnBlue 
//	variable	nIO, c, cCnt, ioch = 0
//variable lap=0
//	for ( nIO = 0; nIO < UFPE_IOT_MAX; nIO += 1 )		
//		cCnt	= UFPE_ioUse( wIO, nIO )
//		for ( c = 0; c < cCnt; c += 1 )
//			sTNm 		= UFPE_ios( wIO, nIO, c, UFPE_IO_NM ) 		
//	 		sFolderTNm 	= UFPE_ioFldAcqioio( sFo, wIO, nIO,c, UFPE_IO_NM ) 		
//			nPts		= numPnts( $sFolderTNm )
//			step		= bDisplayAllPtsAA ? 1 :  trunc( max( nPts / nDrawPts, 1 ) )
//	 		 printf "\t\tDisplayRawAftAcq() nIO:%d   c:%d   %s     %s  \tnSmpInt:%d    \tnPnts:%5d\t DrawPts%4d \tstep:%3d  (bDspAllPts:%2d) \r", nIO,c,  sTNm, sFolderTNm, nSmpInt, nPts, nDrawPts, step, bDisplayAllPtsAA
//	
//			UFCom_GetAutoWindowCorners( ioch, UFPE_ioCntAll( wIO ), 0, 1, rnLeft, rnTop, rnRight, rnBot, 0, 40 )	// references rn.. are changed by function
//			ioch += 1
//			// Make a second identical wave for the second color to discriminate between  SAVE and NOSAVE periods
//			wave 		wData   =	$sFolderTNm		
//	
//			make  /O  /N=(nPts/step)	$( sFolderTNm + "_1" )
//			wave 		wSave 	 = 	$( sFolderTNm + "_1" )
//			make  /O  /N=(nPts/step)	$( sFolderTNm + "_2" )
//			wave 		wNoSave  = 	$( sFolderTNm + "_2" )
//	
//	pr	= 0			// NOT  REALLY  PROTOCOL  AWARE
//			for ( b  = 0; b < UFPE_eBlocks( sFo ); b += 1 )
//				for ( f = 0; f < UFPE_eFrames_( sFo, b ); f += 1 )						
//					for ( s = 0; s < UFPE_eSweeps_( sFo, b ); s += 1)						
//						// printf "\t\tDisplayRawAftAcq()  (f:%d/%d, s:%d/%d) \tBeg:%5d \t... (Store:%5d \t... %5d)  \t... End:%5d \r", f,  UFPE_eFrames(), s, UFPE_eSweeps_( sFo, b ),  SwpBegAll( b, f, s ), SwpBegSave( b, f, s ), SwpBegSave( b, f, s )+SwpLenSave( b, f, s ), SwpBegSave( b, f, s )+SwpLenAll( b, f, s )
//						PreNoSaveStart		= UFPE_SweepBegAll( sFo, pr, b, f, s )						// NOT  REALLY  PROTOCOL  AWARE
//						PreNoSaveStop		= UFPE_SweepBegSave( sFo, pr, b, lap, f, s ) - 1
//	 						PostNoSaveStart	= UFPE_SweepBegSave( sFo, pr, b, lap, f, s ) + UFPE_SweepLenSave( sFo, pr, b, lap, f, s ) + 1 
//	 						PostNoSaveStop	= UFPE_SweepBegAll( sFo, pr, b, f, s )	    + UFPE_SweepLenAll( sFo, pr, b, f, s )
//	 						for ( pt = PreNoSaveStart; pt < PreNoSaveStop; pt += step )	
//							wNoSave[ pt / step ]	= wData[ pt ]			// use original data points of this period in the  NOSAVE   wave 
//							wSave[ pt / step ]	= Nan				// eliminate display points of this period in the  SAVE   wave 
//						endfor
//						for ( pt = PreNoSaveStop; pt < PostNoSaveStart; pt += step )	
//							wSave[ pt / step ]	= wData[ pt ]			// use original data points of this period in the  SAVE   wave 
//							wNoSave[ pt / step ]	= Nan				// eliminate display points of this period in the NOSAVE   wave
//						endfor
//						for ( pt = PostNoSaveStart; pt < PostNoSaveStop; pt += step )	
//							wNoSave[ pt / step ]	= wData[ pt ]			// use original data points of this period in the  NOSAVE   wave 
//							wSave[ pt / step ]	= Nan				// eliminate display points of this period in the  SAVE   wave
//						endfor
//					endfor
//				endfor
//			endfor
//	
//			// Draw the data
//			DoWindow  /K $( ksAFTERACQ_WNM + "_" + sTNm ) 				// kill   window  'AfterAcq_xxx'
//			Display /K=1 /W=( rnLeft, rnTop, rnRight, rnBot ) 
//			ModifyGraph	margin( left )	= 40								// without this the axes are moved too much to the right by TextBox or SetScale y 
//			ModifyGraph	margin( bottom )	= 35								// without this the axes are moved too much up by TextBox or SetScale x 
//	
//			DoWindow  /C $( "AfterAcq_" + sTNm ) 
//			// Draw the Save / NoSave traces each with points blanked out by Nan
//	
//			sRGB	= UFPE_ios( wIO, nIO, c, UFPE_IO_RGB )
//			UFCom_ExtractColors( sRGB, rnRed, rnGreen, rnBlue )
//			// printf "\tDisplayRawAftAcq  nio:%d c:%d  ->  sRGB:%s  \t%d  %d  %d  \r", nIO, c,  sRGB, rnRed, rnGreen, rnBlue
//	
//			AppendToGraph /C=( rnRed, rnGreen, rnBlue ) wSave	
//			AppendToGraph /C=( UFCom_kCOLMX - rnRed, UFCom_kCOLMX - rnGreen, UFCom_kCOLMX - rnBlue ) wNoSave		// complementary color (does not work well with brown, black...)	
//	
//			SetScale /P X, 0, nSmpInt / UFPE_kXSCALE * step, UFPE_ksXUNIT, wSave 
//			SetScale /P X, 0, nSmpInt / UFPE_kXSCALE * step, UFPE_ksXUNIT, wNoSave
//	
//			// Draw  Axis Units   TextBoxUnits 
//	// 2003-0610	 old	// Print YUnits as a Textbox (Advantage: can position it anywhere.  Drawback: As the units are not part of the wave they are unknown to 'Scalebar'
//	//			TextBox	/E=1  /A=LB /X=2  /Y=0  /F=0   iosOld( ioch, UFPE_IO_UNIT )		// print YUnits horiz.  /E=1: rel. wnd border as percentage of window size (WiSz+, AxMv-) 
//	// 2003-0610	 new	
//			SetScale /P y, 0, 0,  UFPE_ios( wIO, nIO,c, UFPE_IO_UNIT ),  wSave				// Store the Y units of the wave within the wave to make it accessible for 'Scalebars()'...
//			SetScale /P y, 0, 0,  UFPE_ios( wIO, nIO,c, UFPE_IO_UNIT ),  wNoSave				// Store the Y units of the wave within the wave to make it accessible for 'Scalebars()'...
//			Label left "\\u#2"										//..but prevent  IGOR  from drawing the units automatically (in most cases at ugly positions)
//			//..instead draw the Y units manualy as a Textbox : draw them horizontally in the lower left corner, 
//			// the textbox has the same name as its corresponding axis: this allows easy deletion together with the axis (from the 'Axes and Scalebars' Panel)
//			TextBox /C /N=left  /E=1 /A=LB /X=2  /Y=0  /F=0  UFPE_ios( wIO, nIO,c, UFPE_IO_UNIT)	//../E=1 means  rel. wnd border as percentage of window size (WiSz+, AxMv-) 
//		endfor
//	endfor
//End
//
//
////=====================================================================================================================================
////    AFTER  ACQ : APPLYING  FINISHING  TOUCHES  TO  'DURING'  ACQUISITION   TRACES   
//
//Function		fPrepPrint( s )
//	struct	WMButtonAction	&s
//	string  	sFo	= ksACQ
//	PreparePrinting( sFo )
//End
//
//static Function	PreparePrinting( sFo ) 
//// apply finishing touches to during-acquisition-graphs:
//// supply all data points skipped during acquisition for speed reasons, supply file name and date, supply comment1
//	// Print Date()					// prints   Di, 3. Sep 2002		depending on regional settings of operating system
//	// Print Secs2Date(DateTime,0)	// prints   3/15/93  or 15.3.1993	depending on regional settings of operating system
//	// Print Secs2Date(DateTime,1)	// prints   Monday, March 15, 1993
//	// Print Secs2Date(DateTime,2)	// prints   Mon, Mar 15, 1993
//	string  	sFo
//	string 	ctrlName
//
//	// Version 1 : use current  comment  without opening Dialog field
//	string		sComment1	= GeneralComment()
//	// Version 2 : always open Comment Dialog field
//	// string	sComment1	= GetComment1()
//
//	string		sFileTraceDateTimeComment, sWNm, sTrc1Nm
//	string		sScriptPath 	= ScriptPath( sFo )
//
//	variable	w,  wCnt	= WndCnt()
//	for ( w = 0; w < wCnt; w += 1 )										
//		sWNm	= WndNm( w )
//		if ( WinType( sWNm ) == UFCom_WT_GRAPH )
//			// todo: if there are multiple different traces in the window (user has copied) then give each trace its own name tag
//			sTrc1Nm	= StringFromList( 0, TraceNameList( sWNm, ";", 1 ) )			// get the first trace in the window e.g. Adc0SM_0
//			sTrc1Nm	= sTrc1Nm[ 0, strsearch( sTrc1Nm, ksMORA_PTSEP, 0 ) - 1 ]// truncate the separator and the point e.g. Adc0SM
//			// Format all items except comment in one line, comment in a second line below
//			sFileTraceDateTimeComment	= GetFileName() + "    (" + UFCom_StripPathAndExtension( sScriptPath ) + ")    " + sTrc1Nm + "    " + Secs2Date(DateTime,0) + "    " + time() + "\r" + sComment1
//			TextBox	/W=$sWNm  /C  /N=$TBNamePP()  /E=1  /A=LT  /F=0  sFileTraceDateTimeComment	// print  text  into the window /E=1: rel. wnd border as percentage of window size 
//			// printf "\t\tPreparePrinting()  w:%2d/%2d \t%s \t%s \r", w, wCnt, sWNm, sFileTraceDateTimeComment
//		endif
//	endfor
//	//DoUpdate  // does not work    todo: adjust scale size automatically to make room for the text box
//
//	// Run  OFFLINE  through complete display to improve fidelity. Actually in most cases the early (and later overwritten) traces could be skipped here... 
//	//? Flaw: If acq was not in HiRes and if subsequently HiRes is turned on, then LoRes traces will not be changed to HiRes by PreparePrinting()..... 
//	//? todo  what if user STOPed acquisition prematurely (not all traces up to UFPE_eFrames(), UFPE_eSweeps()  exist ????
//	variable bHighResolution = HighResolution()
//	if ( ! bHighResolution )	
//		bHighResolution	= UFCom_TRUE
//		for ( w = 0; w < wCnt; w += 1 )										
//			DisplayOffLine( sFo, w )
//		endfor
//		bHighResolution	= UFCom_FALSE
//	endif
//	return 0
//End
//
//static Function	DisplayOffLine( sFo, w )
//	string  	sFo
//	variable	w
//	variable	b,  bCnt	= UFPE_eBlocks( sFo )
//	string  	sWNm	= WndNm( w )
//	if ( WinType( sWNm ) == UFCom_WT_GRAPH )
//		for ( b  = 0; b < UFPE_eBlocks( sFo ); b += 1 )
//			// printf "\t\t\tDisplayOffLine( \tw:%2d\t%s )   Block:%2d / %2d  has Frames:%2d  Sweeps:%2d \r",  w, sWNm, b, UFPE_eBlocks( sFo ), UFPE_eFrames_( sFo, b ), UFPE_eSweeps_( sFo, b )
//
//			RemoveTextBoxPP( sWNm )		// remove any old PreparePrinting textbox. Alternate approach: keep the textbox but then update its contents (=time, file name) permanently
//			RemoveTextBoxUnits( sWNm )		// 2004-0109  possibly so often not necessary, only necessary at 1. block ..? ( also removes PreparePrinting Textbox, should not..)
//			RemoveAcqTraces( sWNm )		// and bring windows to front
//variable	lap = 0
//
//			variable	f,  fCnt	=  UFPE_eFrames_( sFo, b )
//			for ( f = 0; f < fCnt; f += 1 )
//				variable	s,  sCnt	=  UFPE_eSweeps_( sFo, b )
//				for ( s = 0; s < sCnt; s += 1 )
//					DispDuringAcq( sFo, w, 0, b, lap, f, s, kSWEEP )	// 2003-1008 p=0 : not really protocol aware
//				endfor 
//				DispDuringAcq( sFo, w, 0, b, lap, f, 0, kFRAME )	
//				DispDuringAcq( sFo, w, 0, b, lap, f, 0, kPRIM )		
//				DispDuringAcq( sFo, w, 0, b, lap, f, 0, kRESULT )	
//			endfor
//		endfor
//	endif
//End
//
//Static  Function  /S	TBNamePP()
//	return	"TbPP"
//End
//
//
//
//
//
////================================================================================================================================
////  CONTROLBARS  in  the  ACQUISITION  WINDOWS FOR EDITING TRACE and WINDOW APPEARANCE  with   POPMENU(=YZoom, Colors)   and   SLIDER(=YOfs)   
//
//// The controlbar code for each of the the buttons, listboxes and popmemu is principally made up of 2 parts : 
//// Part 1  stores the user setting in the underlying control structure.  This is the more  important part as this control structure controls the display during the next acquisition.
//// Part 2  has the purpose to give the user some immediate feedback that his changes have been accepted. 
////	To accomplish this existing data are drawn preliminarily with changed colors, zooms, Yaxes in a manner which is to reflect the user changes at once which would without this code only take effect later during the next acquisition.
////	The code must handle  'single'  traces  and   'superimposed'  traces (derived from the basic trace name but with the begin point number appended)
//
//// 2006-0606  NO LONGER  ninstn.....
////	The code must allow multiple instances of the same trace allowing the same data to be displayed at the same time with different zoom factors,..
////	  ...for this we must do much bookkeeping because Igor has the restriction of requiring the same trace=wave name but appends its own instance number whereas we must do our own instance counting in Curves
//// 2006-0606  NO LONGER  DisplayOffLine().
////	We take the approach to not even try to keep track which instances of which traces in which windows have to be redrawn, instead we we redraw all ( -> DisplayOffLine() )
////	This is sort of an overkill but here we do it only once in response to a (slow) user action while during acq we do the same routine (=updating all acq windows) very often... 
//// 	...so we accept the (theoretical) disadvantage of updating traces which actually would have needed no update because it simplifies the program code tremendously  .
//
//// Major revision 040108..040204
//// Major revision 060520..060610
//
//static constant	cXTRACENMSIZE			= 100		// empirical values, could be computed .  81 for 'Dac0SC' , 86 for 'Dac0SCa' , 92 for 'Dac0 SC a', 110 for 'Dac0 Sweeps C'
//static constant	cXCHECKBOXSIZE			= 64			// 60 for 'AutoScl'
//static constant	cXBUTTONMARGIN			=  2
//static constant	cXLBCOLORSIZE			= 96			
//static constant	cXLBZOOMSIZE			= 104			
//static constant	cbDISABLEbyGRAYING		= 0 //1 	// 0 : disable the control by hiding it completely (better as it save screen space and as it avoids confusion) ,  1 : disable the control by graying it 
//static constant	cbALLOW_ADC_AUTOSCALE	= 1 //1 	// 0 : autoscale only Dacs ,  1 : also autoscale   Adc , Pon , etc ( todo: not yet working correctly. Problem: tries to autoscale trace on screen which may be flat line -> CRASHES sometimes )
//static constant	cbAUTOSCALE_SYMMETRIC	= 0 //1 	// 0 : autoscale exactly between minimum and maximum of trace possibly offseting zero,  1 : autoscale keeping pos. and neg. half axis at same length ( zero in the middle)
//
//
//Function		AcqControlBar( w )
//	variable	w
//	string  	sWNm	= WndNm( w )
//	ControlInfo	/W=$sWNm	CbCheckboxAuto; 	return ( V_flag == UFCom_kCI_CHECKBOX )	// Check if the checkbox control exists. Only if it exists then the controlbar also exists. 
//End
//
//static  Function		CreateControlBarInAcqWnd3( sChan, mo, ra, w, bAcqControlbar ) 
//// depending on  'bAcqControlbar'  build and show or hide the controlbar  AND  show or hide the individual controls (buttons, listboxes..)
//	string  	sChan
//	variable	mo, ra
//	variable	w, bAcqControlbar											// Show or hide the controlbar
//	string  	sFo	= ksACQ
//	variable	Gain		= GainByNmForDisplay( sFo, sChan )
//	string  	sWNm	= WndNm( w )	
//	variable	rbAutoscl, rYOfs, rYZoom, rnAxis
//	string 	rsTNm, rsRGB
//
//	variable	ControlBarHeight = bAcqControlbar				? 26 : 0 			// height 0 effectively hides the whole controlbar
//	ControlBar /W = $sWNm  ControlBarHeight
//	
//	variable  	nCurve	= ExtractCurves( w, sChan, ra, mo, rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB )	// Extract fom 'the one and only curve 'nCurve' with matching ' sChan, ra, mo' and from this the remaining (now valid) parameters 'rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB' 
//	string  	sCurve	= CurvesOneCurve( w, nCurve )							
//	SetWindow	$sWNm,  	UserData( sCurve )	= sCurve						// Set UD sCurve	Store the string quasi-globally within the graph
//
//
//	//string  	sTNmMoRa	= sChan + " " + BuildMoRaName( ra, mo )				// e.g. 'Adc1 FM' 		needs  cXTRACENMSIZE >= 86
//	string  	sTNmMoRa	= sChan + " " + RangeNmLong( ra ) + " " + ModeNm( mo ) 	// e.g. 'Adc1 Frames M'	needs  cXTRACENMSIZE >= 120
//	 printf "\tCreateControlBarInAcqWnd3( sWNm:%s %d ) \t%s\t mo:%d ra:%d\t ofs:\t%7g  \t  zm:\t%7g  \tax:%2d\t%s \r",  sWNm, bAcqControlbar, UFCom_pd( sTNmMoRa, 15), mo, ra , rYOfs, rYZoom, rnAxis, rsRGB 
//	ConstructCbTitleboxTraceNm( sWNm,  bAcqControlbar, sTNmMoRa )				// 
//	ConstructCbPopmenuColors( sWNm,  bAcqControlbar, rsRGB )					//
//
//	variable	bDisableCtrlAutoscl	= DisableCtrlAutoscl( sChan, bAcqControlbar ) 
//	variable	bDisableCtrlZoomOfs	= DisableCtrlZoomOfs( sChan, bAcqControlbar, rbAutoscl ) 
//
//	ConstructCbCheckboxAuto( sWNm, bDisableCtrlAutoscl, rbAutoscl )						
//
//	ConstructCbYAxis( sWNm, bDisableCtrlAutoscl, rnAxis )
//
//
//	ConstructCbListboxYZoom( sWNm, bDisableCtrlZoomOfs,  rYZoom )						
//	ConstructCbSliderYOfs( 	sWNm, bDisableCtrlZoomOfs, rYOfs, Gain )				// also construct the optional Controlbar on the right (only in Igor5) 
//
//	// printf "\tCreateControlBarInAcqWnd( sWNm:%s ) \tw:%d , nCurve:%2d \tsCurve:'%s' \r", sWNm, w, nCurve, sCurve
//End
//
//
////-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
////  Functions  controling  whether a specific control  of the control bar  is to be enabled, disabled by completely hiding it or disabled by just graying it.
//
//// 2006-0607 simplified
//static  Function		DisableCtrlAutoscl( sTNm, bAcqCb ) 
//	string  	sTNm
//	variable	bAcqCb
//	variable	bDisableAutosclCheckbox
//	if (  !  cbALLOW_ADC_AUTOSCALE )				
//	 	bDisableAutosclCheckbox	=  ! bAcqCb   ||  ! IsDacTrace( sTNm )					//  only  Dacs  can be autoscaled
//	else
//		bDisableAutosclCheckbox	=  ! bAcqCb  									//  Dacs and  Adcs can be autoscaled
//	endif
//	return	bDisableAutosclCheckbox
//End
//
//static  Function		DisableCtrlZoomOfs( sTNm, bAcqCb, bAutoscl ) 
//// determine whether the control must be shown or hidden depending on the state of of other controls and  depending on other factors
//	string  	sTNm
//	variable	bAcqCb, bAutoscl
//	variable	bDisableGeneral	= ! bAcqCb
//	variable	bDisableCtrlAutoscl	= DisableCtrlAutoscl( sTNm, bAcqCb ) 
//	variable	nDisableCtrl		= bDisableGeneral   ||  ( ! bDisableCtrlAutoscl  &&  bAutoscl )	// not used : only enable (=0)  or hide (=1)  the control, no possibility to gray it
//	if ( bDisableGeneral == 1 )		
//		nDisableCtrl = 1														// if all controls are to disappear then the Zoom should also hide : do not allow graying
//	else
//		nDisableCtrl =  ( ! bDisableCtrlAutoscl  &&   bAutoscl )  *  ( 1 + cbDISABLEbyGRAYING )	// 0 enables , 1 disables by hiding , 2 disables by graying
//	endif
//	return	nDisableCtrl													// 0 enables , 1 disables by hiding , 2 disables by graying
//End
//
////-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
////  CONTROLBARS  in  the  ACQUISITION  WINDOWS : CONSTRUCTION
//
//static  Function		ConstructCbTitleboxTraceNm( sWNm, bDisable, sTNmMoRa )
//// Fill the Titlebox control  in the ControlBar with the name of the selected trace. 
//	string 	sWNm, sTNmMoRa
//	variable	bDisable
//	Titlebox  CbTitleboxTraceNm,  win = $sWNm,  pos = {2, 2},  title = sTNmMoRa,  frame = 2,  labelBack=(60000, 60000, 60000)
//	//Titlebox  CbTitleboxTraceNm,  win = $sWNm, size = {cXTRACENMSIZE-10,12} 			// TitleBox 'size'  has no effect, the field is automatically sized 
//	Titlebox  CbTitleboxTraceNm,  win = $sWNm, disable = ! bDisable
//End
//
//static  Function		ConstructCbCheckboxAuto( sWNm, bDisable, bAutoscl )
//	string  	sWNm
// 	variable	bDisable, bAutoscl 
//	Checkbox	CbCheckboxAuto,  win = $sWNm, size={ cXCHECKBOXSIZE,20 },	proc=fAutoScale,  title= "AutoScl"
//	Checkbox	CbCheckboxAuto,  win = $sWNm, pos={ cXTRACENMSIZE + 0 * ( cXCHECKBOXSIZE + cXBUTTONMARGIN ) , 2 }
//	Checkbox	CbCheckboxAuto,  win = $sWNm, help={"Automatical Scaling works only with Dac but not with Adc traces."}
//	ShowHideCbCheckboxAuto( sWNm, bDisable, bAutoscl  )							// Enable or disable the control  and possibly adjust its value
//End
//static  Function		ShowHideCbCheckboxAuto( sWNm, bDisable, bAutoscl  )
////  Hide, gray or display (=enable)  the control   and   set its  state/value/limits  correctly  (even when hidden).
//	string  	sWNm
// 	variable	bDisable, bAutoscl  
//	Checkbox	CbCheckboxAuto,  win = $sWNm, disable =  bDisable, value = bAutoscl
//End
//
//static  Function		ConstructCbPopmenuColors( sWNm, bDisable, sRGB )
//	string 	sWNm, sRGB
//	variable	bDisable
//	variable	rnRed, rnGreen, rnBlue
//	UFCom_ExtractColors( sRGB, rnRed, rnGreen, rnBlue )
//	PopupMenu CbPopmenuColors,  win = $sWNm, size={ cXLBCOLORSIZE,16 },	proc=fTraceColors,	title=""		
//	PopupMenu CbPopmenuColors,  win = $sWNm, pos={ cXTRACENMSIZE + 1 * ( cXCHECKBOXSIZE + cXBUTTONMARGIN ) , 2 }
//	PopupMenu CbPopmenuColors,  win = $sWNm, mode=1, popColor = ( rnRed, rnGreen, rnBlue ), value = "*COLORPOP*"
////	PopupMenu CbPopmenuColors,  win = $sWNm, help = {"If you have multiple traces in the windows, you must first select the trace to apply on, then the color."}
//	PopupMenu CbPopmenuColors,  win = $sWNm, disable = ! bDisable
//End
//
//
//static  Function		ConstructCbListboxYZoom( sWNm, bDisable, YZoom )
//	string 	sWNm
//	variable	bDisable, YZoom
//	PopupMenu CbListboxYZoom,   win = $sWNm, size = { cXLBZOOMSIZE, 20 }, 	proc=fYZoom,	title="   yZoom"	
//	PopupMenu CbListboxYZoom,   win = $sWNm, pos = { cXTRACENMSIZE + 1 * ( cXCHECKBOXSIZE + cXBUTTONMARGIN )+ cXLBCOLORSIZE - 44, 2 } 
////	PopupMenu CbListboxYZoom ,  win = $sWNm, help = {"If you have multiple traces in the windows, you must first select the trace to apply on, then the Y zoom factor."}
//	ShowHideCbListboxYZoom( sWNm, bDisable, YZoom )									// Enable or disable the control  and possibly adjust its value
//End
//
//static  Function		ShowHideCbListboxYZoom( sWNm, bDisable, YZoom )
////  Hide, gray or display (=enable)  the control   and   set its  state/value/limits  correctly  (even when hidden).
//	string 	sWNm
//	variable	bDisable, YZoom
//	variable	n, nSelected, nItemCnt	= ItemsInList( ZoomValues() )
//	// Search the item in the list which corresponds to the desired value 'YZoom'
//	for ( n = 0; n < nItemCnt; n += 1 )
//		if ( str2num( StringFromList( n, ZoomValues() ) ) == YZoom )	// compare numbers, the numbers as strings might be formatted in different ways ( trailing zeros...)
//			break
//		endif
//	endfor
//	if ( n == nItemCnt )
//		n = 4			// the desired value could not be found in the list,  so we select arbitrarily  a zoom of 1  to be displayed  which is the  4. item  in the list
//	endif
//	PopupMenu CbListboxYZoom,   win = $sWNm, disable = bDisable,  mode = n+1,  value = ZoomValues()	// n+1 sets the selected item in the listbox,  counting starts at 1
//End
//
//Function	/S	ZoomValues()							// Igor does not allow this function to be static
//	return	".1;.2;.5;1;2;5;10;20;50;100"
//End	
//
//
//static  Function		ConstructCbYAxis( sWNm, bDisable, rnAxis )
//	string  	sWNm
// 	variable	bDisable, rnAxis 
//	PopupMenu  CbPopupYAxis,  	win = $sWNm, size={ cXLBZOOMSIZE,20 },	proc=fPopupYAxis,  title= "Y axis"
//	PopupMenu  CbPopupYAxis,  	win = $sWNm, pos = { cXTRACENMSIZE + 1 * ( cXCHECKBOXSIZE + cXBUTTONMARGIN )+ cXLBCOLORSIZE + cXLBZOOMSIZE - 44, 2 } 
//	PopupMenu  CbPopupYAxis,  	win = $sWNm, help={""}
//	PopupMenu  CbPopupYAxis,  	win = $sWNm, disable =  bDisable,  mode = rnAxis +1,  value = klstAXIS_NAMES		// Hide, gray or display (=enable)  the control   and   set its  state/value/limits  correctly  (even when hidden)
//End
//
//
//static  Function		ConstructCbSliderYOfs( sWNm, bDisable, YOfs, Gain )
//	string 	sWNm
//	variable	bDisable, YOfs, Gain
//	Slider 	CbSliderYOfs,   win = $sWNm,	proc = fSliderYOfs 
//	GetWindow $sWNm, wSize											// Get the window dimensions in points .
//	variable 	RightPix	= ( V_right	-  V_left )	* screenresolution / UFCom_kIGOR_POINTS72 	// Convert to pixels ( This has been tested for 1600x1200  AND  for  1280x1024 )
//	variable 	BotPix	= ( V_bottom - V_top ) * screenresolution / UFCom_kIGOR_POINTS72 
//	// printf  "\t\t\t\tConstructCbSliderYOfs Slider  in '%s' \twindow dim in points:  %d  %d  %d  %d    -> RightPix: %d  %d  \r", sWNm, V_left,  V_top,  V_right,  V_bottom ,  RightPix, BotPix
//
//	Slider 	CbSliderYOfs,   win = $sWNm, vert = 1, side = 2,	size={ 0, BotPix - 30 },  pos = { RightPix -76, 28 }
//	//ControlInfo /W=$sWNm CbSliderYOfs
//	// printf "\tControlInfo Slider  in '%s' \tleft:%d \twidth:%d \ttop:%d \theight:%d \r", sWNm,  V_left, V_width, V_top, V_height
//	ShowHideCbSliderYOfs( sWNm, bDisable, YOfs, Gain )							// Enable or disable the control  and possibly adjust its value
//End
//
//static  Function		ShowHideCbSliderYOfs( sWNm, bDisable, YOfs, Gain )
////  Hide, gray or display (=enable)  the control   and   set its  state/value/limits  correctly  (even when hidden).
//	string 	sWNm
//	variable	bDisable, YOfs, Gain
//	variable	ControlBarWidth 	=    bDisable == 1   ?	0  : 76		//  Vertical slider at the  right window border :only hide=1 sets width = 0 and makes the controlbar vanish, enable=0 and gray=2 display  the controlbar
//	ControlBar /W = $sWNm  /R ControlBarWidth
//	variable	DacRange		= 10								// + - Volt
//	variable	YAxisWithoutZoom	= DacRange * 1000 / Gain 			
//	// printf "\t\t\t\tShowHideCbSliderYOfs() \t'%s'\tDGn:\t%7.1lf\t-> Axis(without zoom):\t%7.1lf\tVal:\t%7.1lf\t  \r", sWNm, Gain, YAxisWithoutZoom, YOfs / Gain
//	Slider	CbSliderYOfs,	win = $sWNm, 	disable = bDisable,	value = YOfs / Gain,	limits = { -YAxisWithoutZoom, YAxisWithoutZoom, 0 } 
//End
//
//static Function		PossiblyAdjstSlider( sFo, w )
//// We change the slider limits in all windows in which a slider is displayed
//	string  	sFo
//	variable	w
//	string		sWNm	= WndNm( w )
//	variable	nCurves	= CurvesCnt( w )
//	variable	nCurve
//	for ( nCurve = 0; nCurve < nCurves; nCurve += 1 )
//		variable	rnRange, rnMode, rbAutoscl, rYOfs, rYZoom, rnAxis 
//		string		 rsTNm, rsRGB
//		ExtractCurve( w, nCurve, rsTNm, rnRange, rnMode, rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB )	// Get all traces/curves from this window...
//		variable	bAcqControlbar	= AcqControlBar( w )
//		variable	bDisableCtrlOfs	= DisableCtrlZoomOfs(      rsTNm, bAcqControlbar, rbAutoscl )		// Determine whether the control must be enabled or disabled
//		variable	Gain			= GainByNmForDisplay( sFo, rsTNm )
//		ShowHideCbSliderYOfs( sWNm,  bDisableCtrlOfs, rYOfs, Gain )							// Enable or disable the control  and possibly adjust its value
//	endfor
//End
//
//Function			PossiblyAdjstSliderInAllWindows( sFo )
//// We change the slider limits in all windows in which a slider is displayed
//	string  	sFo
//	variable	w, wCnt =  WndCnt()
//	for ( w = 0; w < wCnt; w += 1 )
//		PossiblyAdjstSlider( sFo, w )
//	endfor
//End
//
////-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
////  CONTROLBARS  in  the  ACQUISITION  WINDOWS  :  THE  ACTION  PROCEDURES
//
//Function		IsDacTrace( sTNm )
//// Returns whether the passed trace is of type  'Dac'  and not  e.g.  'Adc'  or  'PoN' 
//	string 	sTNm
//	return	( cmpstr( sTNm[ 0, 2 ], "Dac" ) == 0 )
//End
//
//Function		IsPoNTrace( sTNm )
//// Returns whether the passed trace is of type  'PoN'  and not  e.g.  'Adc'  or  'Dac' 
//	string 	sTNm
//	return	( cmpstr( sTNm[ 0, 2 ], "PoN" ) == 0 )
//End
//
//
//Function		fAutoScale( s )
//// Executed only when the user changes the 'AutoScale' checkbox : If it is turned on, then YZoom and YOfs values are computed so that the currently displayed trace is fitted to the window.
//	struct	WMCheckboxAction	&s
//	if (  s.eventcode != UFCom_kEV_ABOUT_TO_BE_KILLED )
//		string  	rsChan, rsRGB													// parameters are set by  UpdateCurves()
//		variable	ra, mo, rbAutoscl, rYOfs, rYZoom, rnAxis								// parameters are set by  UpdateCurves()
//		variable	w		= WndNr( s.Win )
//		string  	sCurve 	= GetUserData( 	s.win,  "",  "sCurve" )							// Get UD sCurve 
//		variable	nCurve	= UpdateCurves( w, kCV_AUTOSCL,  num2str( s.checked ),  sCurve, rsChan, ra, mo, rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB )	
//	
//		// The Dac trace has now been rescaled in the curves internally and will  be shown with new scaling during the next acquisition, but we want to immediately give some feedback to the
//		//... user so he sees his rescaling has been accepted , so we go on redrawing all windows
//		string  	sFo	= ksACQ
//		variable	Gain		= GainByNmForDisplay( sFo, rsChan )
//		DurAcqRescaleYAxis( rnAxis, s.Win, rYOfs, rYZoom, Gain )
//	
//		// Hide the  Zoom  and  Offset  controls if  AutoScaling is ON, display them if Autoscaling is OFF
//		variable	bAcqControlbar		= AcqControlbar( w )
//		variable	bDisableCtrlZoomOfs	= DisableCtrlZoomOfs( rsChan, bAcqControlbar, s.checked )	// Determine whether the control must be enabled or disabled
//		ShowHideCbListboxYZoom( s.Win,  bDisableCtrlZoomOfs, rYZoom )					// Enable or disable the control  and possibly adjust its value
//		ShowHideCbSliderYOfs( 	s.Win,  bDisableCtrlZoomOfs, rYOfs, Gain )					// Enable or disable the control  and possibly adjust its value
//	endif
//	return	0																// other return values reserved
//End
//
//
//  Function		AutoscaleZoomAndOfs( w, sChan, mo, ra, bAutoscl, rYOfs, rYZoom, Gain )
//// Adjust   YZoom  and   YOffset  values  depending on the state of the  'Autoscale'  checkbox.  Return the changed  YZoom  and  YOfs  values  so that they can be stored in the curves  so that the next redraw will reflect the changed values.
//	string 	sChan
//	variable	w, mo, ra, bAutoscl, Gain 
//	variable	&rYOfs, &rYZoom
//
//	string 	sWNm			= WndNm( w )
//	string 	sZoomLBName		= "CbListboxYZoom"
//	variable	YAxis			= 0
//	variable	DacRange 		= 10											// + - Volt
//
//	string  	sTNL			= TraceNameList( sWNm, ";", 1 )
//	string  	sTNm			= sChan + BuildMoRaName( ra, mo ) + ksMORA_PTSEP	// e.g. 'Dac1FM_'	( in many/superimposed mode there is an integer point number appended, which we are not interested in)
//	string  	sMatchingTraces	= ListMatch( sTNL, sTNm + "*" )						// e.g. 'Dac1FM_;Dac1FM_1000;Dac1FM_2000;'			
//	variable	mt, nMatchingTraces	= ItemsInList( sMatchingTraces )
//	for ( mt = 0; mt < nMatchingTraces; mt += 1 )
//		sTNm	= StringFromList( mt, sMatchingTraces )							// e.g. 'Dac1FM_' ,  'Dac1FM_1000'  and  'Dac1FM_2000'		
//
//		if ( bAutoscl )												// The checkbox  'Autoscale Y axis'  has been turned  ON :
//			wave 		wData	= TraceNameToWaveRef( sWNm, sTNm )
//			waveStats	/Q	wData									// 	...We compute the maximum/mimimum Dac values from the stimulus and set the zoom factor... 
//	
//			if ( cbAUTOSCALE_SYMMETRIC )							// 		Use symmetrical axes, the length is the longer of both. The window is filled to 90% . 
//				 YAxis	= max( abs( V_max ), abs( V_min ) ) / .9	
//				 rYOfs	= 0
//			else													// 		The length of pos. and neg. half axis is adjusted separately.  The window is filled to 90% . 
//				YAxis	= (  V_max   -  V_min  ) 		 / 2 / .9 
//				rYOfs	= (  V_max  +  V_min  ) / Gain	 / 2  
//			endif		
//	
//			rYZoom	= DacRange * 1000 / YAxis				
//		else														//  The checkbox  'Autoscale Y axis'  has been turned  OFF : So we restore and use the user supplied zoom factor setting from the listbox
//																//  We do not restore the  YOfs from slider because 	1. the user can very easily  (re)adjust to a new position   
//																//										2. the YOfs is at the optimum position as it has just been autoscaled  
//			ControlInfo /W=$sWNm $sZoomLBName						//										3. the YOfs prior to AutoScaling would have had to be stored to be able to retrieve it which is not done in this version 
//			rYZoom	= str2num( S_Value )								// Get the controls current value by reading S_Value  which is set by  ControlInfo
//		endif
//		// printf "\t\t\tAutoscaleZoomAndOfs( '%s' \t'%s'\tpts:\t%8d\t bAutoscl: %s )\tVmax:\t%7.2lf\tVmin:\t%7.2lf\tYaxis:\t%7.1lf\tYzoom:\t%7.2lf\tYofs:\t%7.1lf\tGain:\t%7.1lf\t  \r",  sWNm, rsTNm, numPnts( $rsTNm ), SelectString( bAutoscl, "OFF" , "ON" ), V_max, V_min, YAxis, rYZoom, rYOfs, Gain
//	endfor
//End
//
//
//Function 		fTraceColors( s )
//	struct	WMPopupAction	&s
//	if (  s.eventcode != UFCom_kEV_ABOUT_TO_BE_KILLED )
//		string  	rsChan, rsRGB													// parameters are set by  UpdateCurves()
//		variable	ra, mo, rbAutoscl, rYOfs, rYZoom, rnAxis								// parameters are set by  UpdateCurves()
//		variable	w		= WndNr( s.Win )	
//		string  	sCurve 	= GetUserData( 	s.win,  "",  "sCurve" )							// Get UD sCurve 
//		variable	nCurve	= UpdateCurves( w, kCV_RGB, s.PopStr, sCurve, rsChan, ra, mo, rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB )	
//		// The new colors have now been set and will be effective during the next acquisition, but we want to immediately give some feedback to the..
//		// ..user so he sees his color change has been accepted, so we go on and colorize the trace (or all instances of this trace) in the existing window :
//		string  	sTNL			= TraceNameList( s.Win, ";", 1 )
//		string  	sTNm			= rsChan + BuildMoRaName( ra, mo ) + ksMORA_PTSEP	// e.g. 'Dac1FM_'	( in many/superimposed mode there is an integer point number appended, which we are not interested in)
//		string  	sMatchingTraces	= ListMatch( sTNL, sTNm + "*" )						// e.g. 'Dac1FM_;Dac1FM_1000;Dac1FM_2000;'			
//		variable	mt, nMatchingTraces	= ItemsInList( sMatchingTraces )
//		variable	nRed, nGreen, nBlue 
//		UFCom_ExtractColors( s.PopStr,  nRed, nGreen, nBlue )
//		for ( mt = 0; mt < nMatchingTraces; mt += 1 )
//			sTNm	= StringFromList( mt, sMatchingTraces )							// e.g. 'Dac1FM_' ,  'Dac1FM_1000'  and  'Dac1FM_2000'		
//			ModifyGraph	/W = $s.Win	rgb( $sTNm ) = ( nRed, nGreen, nBlue )	
//		endfor
//		// Also change the color of the units which are displayed as a textbox right above the Y axis)
//		string		sAxisNm		= YAxisName( rnAxis ) 									
//		TextBox 	/W=$s.win /C /N=$sAxisNm   /G=( nRed, nGreen, nBlue)  					// the textbox has the same name as its axis
//	endif
//	return	0																// other return values reserved
//End
//
//Function		 fYZoom( s )
//// Action proc executed when the user selects a zoom value from the listbox.  Update  the  'Curves'  and  change axis and traces immediately to give some feedback.
//	struct	WMPopupAction	&s
//	if (  s.eventcode != UFCom_kEV_ABOUT_TO_BE_KILLED )
//		string  	rsChan, rsRGB													// parameters are set by  UpdateCurves()
//		variable	ra, mo, rbAutoscl, rYOfs, rYZoom, rnAxis						// parameters are set by  UpdateCurves()
//		variable	w		= WndNr( s.Win )
//		string  	sCurve 	= GetUserData( 	s.win,  "",  "sCurve" )							// Get UD sCurve
//		variable	nCurve	= UpdateCurves( w, kCV_ZOOM , s.PopStr, sCurve, rsChan, ra, mo, rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB )	
//		// The new YZoom has now been set and will be effective during the next acquisition, but we want to immediately give some feedback to the..
//		// ..user so he sees his YZoom  change has been accepted , so we go on and change the Y Axis range in the existing window :
//		string  	sFo	= ksACQ
//		variable	Gain		= GainByNmForDisplay( sFo, rsChan )						// The user may change the AxoPatch Gain any time during acquisition
//		DurAcqRescaleYAxis( rnAxis, s.Win, rYOfs, rYZoom, Gain )
//	endif
//	return	0																// other return values reserved
//End
//
//Function		fPopupYAxis( s )
//// Executed only when the user changes the 'Y Axis'  listbox....
//	struct	WMPopupAction	&s
//	if (  s.eventcode != UFCom_kEV_ABOUT_TO_BE_KILLED )
//		string  	sFo	= ksACQ
//		string  	sChan, sRGB													// parameters are set by  UpdateCurves()
//		variable	ra, mo, bAutoscl, YOfs, YZoom, nAxis								// parameters are set by  UpdateCurves()
//		variable	w			= WndNr( s.Win )
//		variable	nCurves		= CurvesCnt( w )
//		string  	sCurve 		= GetUserData( 	s.win,  "",  "sCurve" )						// Get UD sCurve 
//		 printf "\t\tfPopupYAxis(1)\t\tw:%2d\tcv:%2d/%2d\t%s\t[%s]\t   \r", w, -1, nCurves, UFCom_pd(sCurve,43), CurvesRetrieve( w )
//		variable	nCurve		= UpdateCurves( w, kCV_AXIS,  num2str( s.popnum-1 ),  sCurve, sChan, ra, mo, bAutoscl, YOfs, YZoom, nAxis, sRGB )	// -1 = UFCom_kNOTFOUND means HIDE, 0 means DISPLAY
//		nCurves	= CurvesCnt( w )
//		 printf "\t\tfPopupYAxis(2)\t\tw:%2d\tcv:%2d/%2d\t%s\t[%s]\t   \r", w, nCurve, nCurves, UFCom_pd(sCurve,43), CurvesRetrieve( w )
//	
//		// Rearrange all Y axes of this window
//		variable	pr = 0,  bl = 0,  lap = 0, fr = 0,  sw = 0
//		variable	Pts, BegPt, EndPt, bIsFirst
//		variable	nSmpInt		= UFPE_SmpInt( sFo )
//		variable	nAxisCnt
//		
//		// Remove all traces with same channel, mode and range
//		string  	sTNL			= TraceNameList( s.Win, ";", 1 )
//		string  	sTNm			= sChan + BuildMoRaName( ra, mo ) + ksMORA_PTSEP	// e.g. 'Dac1FM_'	( in many/superimposed mode there is an integer point number appended, which we are not interested in)
//		string  	sMatchingTraces	= ListMatch( sTNL, sTNm + "*" )						// e.g. 'Dac1FM_;Dac1FM_1000;Dac1FM_2000;'			
//		variable	mt, nMatchingTraces	= ItemsInList( sMatchingTraces )
//		for ( mt = 0; mt < nMatchingTraces; mt += 1 )
//			sTNm	= StringFromList( mt, sMatchingTraces )							// e.g. 'Dac1FM_' ,  'Dac1FM_1000'  and  'Dac1FM_2000'		
//			RemoveFromGraph  /W=$s.Win  $sTNm 
//		endfor
//	
//		// Redraw traces
//		for ( nCurve = 0; nCurve < nCurves; nCurve += 1 )								// Rebuild all traces in window
//			nAxisCnt	= YAxisCnt( w )												// nYAxisCnt   could be less than   nCurves  if an Y axis has been removed perhaps because 2 or more traces share the same Y axis		
//			ra		= Curve2Range( w, nCurve )									// break 'sCurve' to get all traces to be displayed in window 'w'...
//			Range2Pt( sFo, ra, pr, bl, lap, fr, sw, BegPt, EndPt, Pts, bIsFirst )
//			DurAcqDrawTraceAndAxis( sFo, w, nCurve, nAxisCnt, BegPt, Pts, bIsFirst, ra, nSmpInt )
//		endfor
//	
//	////	ReplaceOneParameter( w, nCurve, kCV_AXIS, num2str(  s.checked -1) )		// -1 = UFCom_kNOTFOUND means HIDE, 0 means DISPLAY
//	//
//	//	 printf "\t\tfPopupYAxis(3)\tw:%2d\tnCurve:%2d/%2d\t->\t%s\t[%s]\t   \r", w, nCurve, nCurves, UFCom_pd(sCurve,43), CurvesRetrieve( w )
//	endif
//	return	0																// other return values reserved
//End		// fPopupYAxis()
//
//
//Function		fSliderYOfs( s )
//	struct	WMSliderAction	&s
//	// printf "\t\t\t\tfSliderYOfs()  '%s'  gives value:%d  event:%d  \r", s.CtrlName, s.curval, s.eventcode	// bit field: bit 0: value set; 1: mouse down, 2: mouse up, 3: mouse moved
//	if (  s.eventcode != UFCom_kEV_ABOUT_TO_BE_KILLED )
//		string  	rsChan, rsRGB													// parameters are set by  UpdateCurves()
//		variable	ra, mo, rbAutoscl, rYOfs, rYZoom, rnAxis								// parameters are set by  UpdateCurves()
//		variable	w		= WndNr( s.Win )
//		string  	sCurve 	= GetUserData( 	s.win,  "",  "sCurve" )							// Get UD sCurve
//		variable	nCurve	= UpdateCurves( w, kCV_OFS , num2str( s.curval ), sCurve, rsChan, ra, mo, rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB )	
//		// The new YOffset has now been set and will be effective during the next acquisition, but we want to immediately give some feedback to the..
//		// ..user so he sees his YOffset change has been accepted , so we go on and change the Yoffset in the existing window :
//		string  	sFo	= ksACQ
//		variable	Gain		= GainByNmForDisplay( sFo, rsChan )						// The user may change the AxoPatch Gain any time during acquisition
//		DurAcqRescaleYAxis( rnAxis, s.Win, rYOfs, rYZoom, Gain )
//	endif
//	return	0																// other return values reserved
//End

////================================================================================================================================
////  TRACE  ACCESS  FUNCTIONS  FOR  THE USER
////  Remarks:
////  It has become standard user practice to access the acquired data in form of the waves/traces displayed in the acquisition windows.
////  This was not originally intended: it was intended (and is perhaps better) to access the data from the complete acquisition wave (e.g. 'Adc0' )
////  Accessing the data from the display waves (as it is implemented here) has the advantage that the user can see and check the data on screen.
////  This is also the drawback: he cannot access those data for which he has turned the display OFF,  he cannot access trace segments...
//// ...which are longer or have a different starting point than those on screen.
////  These limitations vanish when access to the complete waves is made: the user could copy arbitrary segments for his private use or act on the original wave...
//
//Function		ShowTraceAccess( sFo )
//// prints completely composed acquisition display trace names (including folder, mode/range, begin point  which the user can use to access the traces
//	string  	sFo
//	variable	bl, fr, sw, nType
//	string		sTNm	= "Dac0"
//	for ( bl = 0; bl < UFPE_eBlocks( sFo ); bl += 1 )
//	printf  "\t\tShowTraceAccess()  ( only for '%s' )    Block:%2d/%2d \r", sTNm, bl,  UFPE_eBlocks( sFo )
//		for ( fr = 0; fr < UFPE_eFrames_( sFo, bl ); fr += 1 )
//			printf  "\t\t\tf:%2d\tF:%s\tP:%s\tR:%s\ts1%s\ts2%s ...\r", fr , UFCom_pd(TraceFB_( sTNm,  fr, bl ),25), UFCom_pd(TracePB_( sTNm,  fr, bl ),25), UFCom_pd(TraceRB_( sTNm,  fr, bl ),25), UFCom_pd(TraceSB_( sTNm,  fr, bl, 0 ),25), UFCom_pd(TraceSB_( sTNm,  fr, bl, 1 ),25)
//		endfor
//	endfor
//End
//
//// There are 'nFrames'  traces in 'Many superimposed' mode e.g. 'Adc0SM_0' , 'Adc0SM_2000' , 'Adc0SM_4000'  which make sense to be selected...
//// ...but there is only 1 'current'  mode trace e.g. 'Adc0SC_'  which is useless here because it stores just the last sweep or frame
//
//
//// 2003-10-07     NOT REALLY  PROTOCOL  AWARE ............
//
//Function  /S		TraceF_( sTNm, fr )
//// return composed  FRAME  Acq display trace name  when base name and frame is given ( for block 0 ) 
//	string		sTNm
//	variable	fr
//	variable	bl	= 0, lap=0
//	variable	pr	= 0	// 2003-10-07     NOT REALLY  PROTOCOL  AWARE ............
//	string  	sFo	= ksACQ
//	return	Trace_( sFo, sTNm, kFRAME, UFPE_FrameBegSave( sFo, pr, bl, lap, fr ) )
//End
//
//Function  /S		TraceP_( sTNm, fr )
//// return composed  PRIMARY  Acq display trace name  when base name and frame is given ( for block 0 ) 
//	string		sTNm
//	variable	fr
//	variable	bl	= 0, lap=0
//	variable	pr	= 0	// 2003-10-07     NOT REALLY  PROTOCOL  AWARE ............
//	string  	sFo	= ksACQ
//	return	Trace_( sFo, sTNm, kPRIM, UFPE_FrameBegSave( sFo, pr, bl, lap, fr ) )
//End
//
//Function  /S		TraceR_( sTNm, fr )
//// return composed  RESULT  Acq display trace name  when base name and frame is given ( for block 0 ) 
//	string		sTNm
//	variable	fr
//	variable	bl	= 0, lap=0
//	variable	pr	= 0	// 2003-10-07     NOT REALLY  PROTOCOL  AWARE ............
//	string  	sFo	= ksACQ
//	return	Trace_( sFo, sTNm, kRESULT, UFPE_SweepBegSave( sFo, pr, bl, lap, fr,  UFPE_eSweeps_( sFo, bl ) - 1 ) )
//End
//
//Function  /S		TraceS_( sTNm, fr, sw )
//// return composed  SWEEP  Acq display trace name  when base name,  frame  and  sweep  is given ( for block 0 ) 
//	string		sTNm
//	variable	fr, sw
//	variable	bl	= 0, lap=0
//	variable	pr	= 0	// 2003-10-07     NOT REALLY  PROTOCOL  AWARE ............
//	string  	sFo	= ksACQ
//	return	Trace_( sFo, sTNm, kSWEEP, UFPE_SweepBegSave( sFo, pr, bl, lap, fr,  sw ) )
//End
//
//Function  /S		TraceFB_( sTNm, fr, bl )
//// return composed  FRAME  Acq display trace name  when base name and frame and block is given
//	string		sTNm
//	variable	fr, bl
//	variable	pr	= 0, lap=0	// 2003-10-07     NOT REALLY  PROTOCOL  AWARE ............
//	string  	sFo	= ksACQ
//	return	Trace_( sFo, sTNm, kFRAME, UFPE_FrameBegSave( sFo, pr, bl, lap, fr ) )
//End
//
//Function  /S		TracePB_( sTNm, fr, bl )
//// return composed  PRIMARY  Acq display trace name  when base name and frame and block is given
//	string		sTNm
//	variable	fr, bl
//	variable	pr	= 0, lap=0	// 2003-10-07     NOT REALLY  PROTOCOL  AWARE ............
//	string  	sFo	= ksACQ
//	return	Trace_( sFo, sTNm, kPRIM, UFPE_FrameBegSave( sFo, pr, bl, lap, fr ) )
//End
//
//Function  /S		TraceRB_( sTNm, fr, bl )
//// return composed  RESULT  Acq display trace name  when base name and frame and block is given
//	string		sTNm
//	variable	fr, bl
//	variable	pr	= 0, lap=0	// 2003-10-07     NOT REALLY  PROTOCOL  AWARE ............
//	string  	sFo	= ksACQ
//	return	Trace_( sFo, sTNm, kRESULT, UFPE_SweepBegSave( sFo, pr, bl, lap, fr,  UFPE_eSweeps_( sFo, bl ) - 1 ) )
//End
//
//Function  /S		TraceSB_( sTNm, fr, bl, sw  )
//// return composed  SWEEP  Acq display trace name  when base name , frame , block  and  sweep  given
//	string		sTNm
//	variable	fr, sw, bl
//	variable	pr	= 0, lap=0	// 2003-10-07     NOT REALLY  PROTOCOL  AWARE ............
//	string  	sFo	= ksACQ
//	return	Trace_( sFo, sTNm, kSWEEP, UFPE_SweepBegSave( sFo, pr, bl, lap, fr, sw ) )
//End
//
//Function  /S		Trace_( sFo, sTNm, nRange, BegPt )
//// returns  any  composed  Acq display trace name....
//	string		sFo, sTNm
//	variable	nRange, BegPt
//	variable	nMode	= kMANYSUPIMP
//	return	BuildTraceNmForAcqDisp( sFo, sTNm, nMode, nRange, BegPt)
//End
//// 2003-10-07  -----------   NOT  REALLY  PROTOCOL  AWARE 
//
//
