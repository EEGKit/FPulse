// 
// UF_AcqOLASelect.ipf	OLA  QDP (=Quot - Diff - Product)  result  selection  listbox

#pragma rtGlobals=1		// Use modern global access method.

Function		IsQDP( sFolders, sNm )
// Compare the listbox field text 'sNm'  (e.g.  'Base_01' , F0_Tau_00'  or  'Quo_00' )  against all valid QDP names  to decide if the given field belongs to the QDP group (like only the 3. does).
	string  	sFolders
	string  	sNm
	variable	ch	= 0 , rg	= 0							// Binary derived results (=Quot,Diff,Product) exist only once so for the  channel and for the region only the dummy index 0 exists.
	string  	lst	= ListACV_QDP( sFolders , ch, rg ) 	
	variable	n, nItems	= ItemsInList( lst )
	for ( n = 0; n < nItems; n += 1 )
		if ( cmpstr(  UFPE_ChRgPostFixStrip_( StringFromList( n, lst ) ) , sNm ) == 0 )// Compare after having removed the dummy ChRg-postfix  (e.g. 'Qu1_00'  -> 'Qu1' )	
			return	UFCom_TRUE
		endif
	endfor
	return	UFCom_FALSE
End


//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//  QDP RESULTS for Online Graphics

// Bad code: must always keep order QDP  = Quot Diff Prod , append new item at the end
static constant		kQDP_QUOTS		= 2		// !!! number of QUOT  results : Also adjust the number of listbox columns   ->  see  'ListBox  $ksLB_QDPSRC_CNM,  win = $ksLB_QDPSRC_WNM,  widths  = xxxxx' 
static constant		kQDP_DIFFS		= 1
static constant		kQDP_PRODS		= 1
static strconstant	ksQDP_QUOT_BASE= "Q"  	// e.g  'Q'  or  'QUO'
static strconstant	ksQDP_DIFF_BASE	= "Di"  	// e.g  'D'  or  'Di'  or  'Dif'	
static strconstant	ksQDP_PROD_BASE= "P"  	// e.g  'P'  or  'Pr'  or  'Pro'	
static strconstant	klstQDP_QUOT_EXT	= "e;d;"  	// e.g  'enumerator and denominator'
static strconstant	klstQDP_DIFF_EXT	= "a;s;"  	// e.g  'add and subtract'	
static strconstant	klstQDP_PROD_EXT	= "f;m;"  	// e.g  'factor and multiplicaror'	

//-----------------------------------------------------------------------------------------
Function	/S	ListACV_QDP( sFolders, ch, rg )// ) //, nThisCh, nThisRg, nChannels, AnyCnt )
// Bad code: must always keep order QDP  = Quot Diff Prod , append new item at the end
// Returns list of all  QDP names  in the  short and simple version used as entries in the  OLA Results panel. The user clicks these if he wants to compute a QDP to specify channel, region, type and begin/end of the QDP 
// Binary derived results (=Quot,Diff,Product) exist only once so for the  channel and for the region only the dummy index 0 exists.
	string  	sFolders
	variable	ch, rg
	string  	sPostfx	= UFPE_ChRgPostFix( ch, rg )
	string  	lst		= ""	
	variable	n
	string  	sNm
	for ( n = 0; n < kQDP_QUOTS; n += 1 )
		sNm	 =  QDPNm( ksQDP_QUOT_BASE, n )
		lst	+= sNm + sPostfx + ";"
	endfor
	for ( n = 0; n < kQDP_DIFFS; n += 1 )
		sNm	 =  QDPNm( ksQDP_DIFF_BASE, n )
		lst	+= sNm + sPostfx + ";"
	endfor
	for ( n = 0; n < kQDP_PRODS; n += 1 )
		sNm	 =  QDPNm( ksQDP_PROD_BASE, n )
		lst	+= sNm + sPostfx + ";"
	endfor
	return	lst
End
	
//-----------------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------------

//-----------------------------------------------------------------------------------------
Function	/S	QDPNmExt( sBaseNm, n, ne, lstExt )
	string  	sBaseNm, lstExt
	variable	n, ne
	return	QDPNm( sBaseNm, n ) + StringFromList( ne, lstExt )	// e.g. 'Q0e'  or  'D1s'
End
//-----------------------------------------------------------------------------------------

//-----------------------------------------------------------------------------------------
Function	/S	QDPNm( sBaseNm, n )
	string  	sBaseNm
	variable	n
	return	sBaseNm + num2str( n )		// e.g. 'Q0'  or  'D1'
End
Function	/S	QDPNm2Base( sNm )
	string  	sNm
	variable	len	= strlen( sNm )			// the last character is the index which will be truncated
	return	sNm[ 0, len-2 ] 
End
Function		QDPNm2Nr( sNm )
	string  	sNm
	variable	len	= strlen( sNm )
	return	str2num( sNm[ len-1, len-1 ] )	// the last character is the index which is returned
End
//-----------------------------------------------------------------------------------------

Function	/S	Col2Nm( col )
	variable	col						// the true listbox column possibly including multiple SourceRegions and the  QDPSrc subcolumn  
	string  	sNm
End

//-----------------------------------------------------------------------------------------

Function	/S	SubCol2SubNm( subcol )
// Bad code: must always keep order QDP  = Quot Diff Prod , append new item at the end
// returns  SubName   e.g. 'Q0e'  or  'D1s'
	variable	subcol					// the subcolumn index restarting at 0 at every SourceRegion column
	variable	n, be, sc	= 0
	for ( n = 0; n < kQDP_QUOTS; n += 1 )
		for ( be = 0; be < ItemsInList( klstQDP_QUOT_EXT ); be += 1 )
			if ( sc == subcol )
				return	QDPNmExt( ksQDP_QUOT_BASE, n, be, klstQDP_QUOT_EXT )
			endif
			sc += 1
		endfor
	endfor
	for ( n = 0; n < kQDP_DIFFS; n += 1 )
		for ( be = 0; be < ItemsInList( klstQDP_DIFF_EXT ); be += 1 )
			if ( sc == subcol )
				return	QDPNmExt( ksQDP_DIFF_BASE, n, be, klstQDP_DIFF_EXT )
			endif
			sc += 1
		endfor
	endfor
	for ( n = 0; n < kQDP_PRODS; n += 1 )
		for ( be = 0; be < ItemsInList( klstQDP_PROD_EXT ); be += 1 )
			if ( sc == subcol ) 
				return	QDPNmExt( ksQDP_PROD_BASE, n, be, klstQDP_PROD_EXT )
			endif
			sc += 1
		endfor
	endfor
	return	""		// ERROR, should never happen
End

Function		SubNm2SubCol( sSubNm )
	string  	sSubNm					// e.g. 'Q0e'  or  'D1s'
	variable	subcol					// the subcolumn index restarting at 0 at every SourceRegion column
End
//-----------------------------------------------------------------------------------------



//	variable	BegEnd, lc
//	variable	ch, rg, rgCnt, nAnyOp	
//	string  	sAnyOp
//
//	make /O /T /N=( nChannels, UFPE_kRG_MAX, AnyCnt, 2 )  $"root:uf:" + sFolders + ":wTmpAnyNames" = ""
//	wave      /T  wTmpAnyNames =  $"root:uf:" + sFolders + ":wTmpAnyNames"
//
//	// Step 1: Store all extracted  ...???...popupmenu...???...    settings in a 4 dim temporary wave. Only after this pass we can be sure that all settings are valid. 
//	for ( lc = 0; lc < AnyCnt; lc += 1 )
//		for ( BegEnd = UFPE_CN_BEG; BegEnd <=  UFPE_CN_END; BegEnd += 1 )
//			for ( ch = 0; ch < nChannels; ch += 1)
//				rgCnt	= UFPE_RegionCnt( sFolders, ch )
//				for ( rg = 0; rg < rgCnt;  rg += 1 )	
//					nAnyOp	= 1 // TODOA  AnyC(   UFPE_LatC( sFolders, ch, rg, lc, BegEnd )
//					sAnyOp	= StringFromList( nAnyOp, klstANYC )		// TODOA  AnyC(  
//					if ( nAnyOp != kANY_OFF )
//						wTmpAnyNames[ ch ][ rg ][ lc ][ BegEnd ] = AnyNm( sFolders, lc, BegEnd, ch, rg ) 
//						 printf "\t\tListQDPSrcDiff( a  ch:%d, rg:%d )\tany:%2d/%2d\t  ch:%d   rg:%d\t%s\tAnyOp:%2d\t(%s) \tAnyNm:%s\t  \r", nThisCh, nThisRg, lc, AnyCnt, ch, rg,  SelectString( BegEnd, "Beg:    " , "  -> End:" ), nAnyOp, sAnyOp, UFCom_pd(wTmpAnyNames[ ch ][ rg ][ lc ][ BegEnd ] ,12)
//					endif
//				endfor
//			endfor
//		endfor
//	endfor
//	
//	// Step 2: Only after all extracted  popupmenu settings have been stored  in a 4 dim temporary wave we can extract them from there in any order.
//	for ( lc = 0; lc < AnyCnt; lc += 1 )
//		for ( BegEnd = UFPE_CN_BEG; BegEnd <=  UFPE_CN_END; BegEnd += 1 )
//			for ( ch = 0; ch < nChannels; ch += 1)
//				rgCnt	= UFPE_RegionCnt( sFolders, ch )
//				for ( rg = 0; rg < rgCnt;  rg += 1 )	
//					lst  += wTmpAnyNames[ ch ][ rg ][ lc ][ BegEnd ] 	// most of them are empty strings  
//					// printf "\t\tListQDPSrcDiff( b  ch:%d, rg:%d )\tAny:%2d/%2d\t  ch:%d   rg:%d\t%s\tlst: '%s' \t  \r", nThisCh, nThisRg, lc, AnyCnt, ch, rg,  SelectString( BegEnd, "Beg:    " , "  -> End:" ), lst[0,200]
//				endfor
//			endfor
//		endfor
//		lst  +=  PostFix( nThisCh, nThisRg ) + ";"			//  add the list delimiter 
//	endfor
//
//	KillWaves  $"root:uf:" + sFolders + ":wTmpAnyNames"
//	 printf "\t\tListQDPSrcDif( c  ch:%d, rg:%d )\tAny:%2d/%2d\t lst: '%s' \r", nThisCh, nThisRg, lc, AnyCnt,  lst[0,200]
//	return	lst
//End	
//
//Function	/S	AnyNm( sFolders, lc, BegEnd, ch, rg )
//// Builds partial  latency name (=first or second half)  e.g. for the begin  'Lat1m01'  but  for the end only   'R22'  . Both parts must be catenated elsewhere!
//	string  	sFolders
//	variable	lc, BegEnd, ch, rg
//	variable	nAnyOp	= 1 	// todoA   AnyC(     UFPE_LatC( sFolders, ch, rg, lc, BegEnd )
//	string		sAnyOp	= StringFromList( nAnyOp, klstANYC )
//	// e.g. for the begin  'Diff1m01'  but  for the end only   'R22'  .  Both parts must be catenated elsewhere!
//
//// TODOA
//	return	SelectString( BegEnd, ksDIFF_BASE + num2str( lc ) + ksQDP_SEPAR + sAnyOp[ 0, kQDP_DESC_LENGTH-1 ] + num2str( ch ) + num2str( rg ),   sAnyOp[ 0, kQDP_DESC_LENGTH-1 ] + num2str( ch ) + num2str( rg ) )	
//End


//=======================================================================================================================================================
// THE   RESULT SELECTION   ONLINE  ANALYSIS   LISTBOX  PANEL			

static strconstant	ksLB_QDPSRC_WNM		= "PnSelQDPSrc" 
static strconstant	ksLB_QDPSRC_CNM		= "LbSelQDPSrc" 
static constant		kLB_QDPSRC_COLWID_MAIN	= 62				// OLA QDP sources listbox column width for SrcRegTyp	 column  (in points)
static constant		kLB_QDP_CW				= 28				// OLA QDP sources listbox column width for    Window	 column  (in points)	(Q0,Q1 needs 22,  a,b,c needs 12,   A,B,C needs 14)
static constant		kLB_QDP_Y				= .8

Function		LBSelectQDPSources( sFolders )
// Build the huge  QDP selection  listbox allowing the user to select input param for Quotients, Diffs etc. (which will be displayed in the Online graph windows)
// Note: The position of the panel window is maintained  WITHOUT using StoreWndLoc() / RetrieveWndLoc() !!!
	string  	sFolders				// e.g 		= "acq:pul"
	// !QDP nvar		bVisib		= $"root:uf:" + sFolders + ":bu_ResSelOA0000"		// The ON/OFF state ot the 'Select Results OA' button

	// 1. Construct the global string  'lstQDPSrcAllChs'  which contains all of the various evaluation and fitting values
	string  	lstQDPSrcAllChs=  ListQDPSrcAllChs( UFPE_klstEVL_QDPSRC ) 						// Base_00;BsRise_00;RT20_00;

	// 2. Get the the text for the cells by breaking the global string  'lstQDPSrcAllChs'  which contains all of the various evaluation and fitting values
	variable	len, n, nItems	= ItemsInList( lstQDPSrcAllChs )	
	 printf "\t\t\tLBSelectQDP()\tlstACVAllCh has items:%3d <- \t '%s .... %s' \r", nItems, lstQDPSrcAllChs[0,80] , lstQDPSrcAllChs[ strlen( lstQDPSrcAllChs ) - 80, inf ]
	string 	sColTitle, lstColTitles	= ""				// e.g. 'Adc1 Rg 0~Adc3 Rg1~'
	string  	lstColItems = ""
	string  	lstCol2ChRg  = ""			// e.g. '1,0;0,2;'

// 2009-07-03 separate general eval entries like DS, Bef, Date   from Ch-Reg-dependant ones like Base, Peak
//	variable	nExtractCh, ch = -1
//	variable	nExtractRg, rg = -1 
	string  	sExtractCh,  sCh = "-1"
	string  	sExtractRg, sRg = "-1"

	string 	sOneItemIdx, sOneItem
	for ( n = 0; n < nItems; n += 1 )
		sOneItemIdx	= StringFromList( n, lstQDPSrcAllChs )					// e.g. 'Base_01'
		len			= strlen( sOneItemIdx )
		sOneItem		= UFPE_ChRgPostFixStrip_( sOneItemIdx )				// strip 3 indices + separator '_'  e.g. 'Base_010'  ->  'Base'

// 2009-07-03 separate general eval entries like DS, Bef, Date   from Ch-Reg-dependant ones like Base, Peak
//		nExtractCh	= UFPE_ChRgPostFix2Ch( sOneItemIdx )
//		nExtractRg	= UFPE_ChRgPostFix2Rg( sOneItemIdx )
//		if ( ch != nExtractCh )											// Start new channel
//			ch 		= nExtractCh
// 			rg 		= -1 
//		endif
//		if ( rg != nExtractRg )											// Start new region
//			rg 		  =  nExtractRg
//			//sprintf sColTitle, "Ch%2d Rg%2d", ch, rg								// Assumption: Print results column title  e.g. 'Ch 0 Rg 0~Ch 2 Rg1~'
//			sprintf sColTitle, "%s Rg%2d", StringFromList( ch, LstChan_a(), UFCom_ksSEP_TAB ), rg	// Assumption: Print results column title  e.g. 'Adc1 Rg 0~Adc3 Rg1~'
//			lstColTitles	  =  AddListItem( sColTitle, 	 lstColTitles,   UFCom_ksCOL_SEP, inf )	// e.g. 'Adc1 Rg 0~Adc3 Rg1~'
//			lstCol2ChRg +=  UFPE_SetChRg( ch, rg )								// e.g.  '1,0;0,2;'

		sExtractCh		= UFPE_ChRgPostFix2Ch_( sOneItemIdx )		// e.g. ""   or   0,1,2...
		sExtractRg	= UFPE_ChRgPostFix2Rg_( sOneItemIdx )
		if ( ! stringmatch( sCh, sExtractCh ) )						// Start new channel
			sCh 		= sExtractCh
 			sRg 		= "-1" 
		endif
		if ( ! stringmatch( sRg, sExtractRg ) )									// Start new region
			sRg 		= sExtractRg
			sColTitle	= SelectString(  strlen( sCh )  ||  strlen( sRg ) , ksGENERAL, "Ch " + sCh + " Rg " + sRg )
			//sprintf sColTitle, "Ch %s Rg %s", sCh, sRg
			lstColTitles	     =  AddListItem( sColTitle, lstColTitles, UFCom_ksCOL_SEP, inf )
			lstCol2ChRg  += UFPE_ChRg_Set_( sCh, sRg )				// e.g.  '1,0;0,2;'


			lstColItems	 += UFCom_ksCOL_SEP
		endif
		lstColItems	+= sOneItem + ";"
	endfor
	lstColItems	= lstColItems[ 1, inf ] + UFCom_ksCOL_SEP							// Remove erroneous leading separator ( and add one at the end )

	// 3. Get the maximum number of items of any column
	variable	c, nCols	= ItemsInList( lstColItems, UFCom_ksCOL_SEP )				// or 	ItemsInList( lstColTitles, UFCom_ksCOL_SEP )
	variable	nRows	= 0
	string  	lstItemsInColumn
	for ( c = 0; c < nCols; c += 1 )
		lstItemsInColumn  = StringFromList( c, lstColItems, UFCom_ksCOL_SEP )	
		nRows		  = max( ItemsInList( lstItemsInColumn ), nRows )
	endfor
	variable	nSubCols	= ( kQDP_QUOTS + kQDP_DIFFS + kQDP_PRODS ) * 2							// 2 for both factors, enumerator, denominator... 
	 printf "\t\t\tLBSelectQDP(b)\tlstACVAllCh has items:%3d -> rows:%3d  cols:%2d\t[SubCols:2*(%d+%d+%d)=%d]\tColT: '%s'\tColItems: '%s...' \r", nItems, nRows, nCols, kQDP_QUOTS, kQDP_DIFFS, kQDP_PRODS, nSubCols, lstColTitles, lstColItems[0, 100]


	// 4. Compute panel size . The y size of the listbox and of the panel  are adjusted to the number of listbox rows (up to maximum screen size) 
	variable	xSize		= nCols * ( kLB_QDPSRC_COLWID_MAIN + nSubCols * kLB_QDP_CW )	+ 30 	// + 30 for scrollbar + margins
	variable	ySizeMax	= UFCom_GetIgorAppPixelY() -  UFCom_kMAGIC_Y_MISSING_PIXEL- 0	// Here we could subtract some Y pixel if we were to leave a bottom region not covered by a large listbox.
	variable	ySizeNeed	= max( 2, nRows ) * UFCom_kLB_CELLY + UFCom_kLB_ADDY			// [2 is min LB height] . We build a panel which will fit entirely on screen, even if not all listbox line fit into the panel...
	variable	ySize		= min( ySizeNeed , ySizeMax ) 						// ...as in this case Igor will automatically supply a listbox scroll bar.
	ySize	 =  trunc( ( ySize -  UFCom_kLB_ADDY ) / UFCom_kLB_CELLY ) * UFCom_kLB_CELLY + UFCom_kLB_ADDY	// To avoid partial listbox lines shrink the panel in Y so that only full-height lines are displayed
	
	// 5. Draw  panel and listbox
//	if ( bVisib )													// Draw the SelectResultsPanel and construct or redimension the underlying waves  ONLY IF  the  'Select Results' checkbox  is  ON

		string  	sWin	= ksLB_QDPSRC_WNM
		if ( WinType( sWin ) != UFCom_WT_PANEL )								// Draw the SelectResultsPanel and construct the underlying waves  ONLY IF  the panel does not yet exist
			// Define initial panel position.
			UFCom_NewPanel1( sWin, UFCom_kRIGHT1, -200, xSize, kLB_QDP_Y, 0, ySize, UFCom_kKILL_ALLOW, "QDP Sources" )	// -200 is an X offset preventing this panel to be covered by other panels.  We must disable killing as this would destroy any selection in the listbox, but minimising is allowed.
			UFCom_LstPanelsAdd( ksACQ, ksfACQVARS, sWin )	
//			UFCom_LstPanelsSet( ksACQ, ksfACQVARS , AddListItem( sWin, UFCom_LstPanels( ksACQ, ksfACQVARS ) ) )	

//			SetWindow	$sWin,  hook( SelRes ) = fHookPnSelResOA
//			ModifyPanel /W=$sWin, fixedSize= 1						// prevent the user to maximize or close the panel by disabling these buttons

			// Create the 2D LB text wave	( Rows = maximum of results in any ch/rg ,  Columns = Ch0 rg0; Ch0 rg1; ... )
			make  /O 	/T 	/N = ( nRows, nCols*(1+nSubCols) )	$"root:uf:" + sFolders + ":wQDPSrcTxt"	= ""	// the LB text wave
			wave   	/T		wTxt					     =	$"root:uf:" + sFolders + ":wQDPSrcTxt"
		
			// Create the 3D LB flag wave. 	Rows x Columns (as above)  x 3  : last index 0 is flags, 1 is fore- or background color, 2 is the remaining color 
			make   /O	/B  /N = ( nRows, nCols*(1+nSubCols), 3 )	$"root:uf:" + sFolders + ":wQDPSrcFlags"	// byte wave is sufficient for up to 254 colors 
			wave   			wFlags				    = 	$"root:uf:" + sFolders + ":wQDPSrcFlags"
			
			// Create color table................???........... withs rows and columns exchanged. 3 rows, n columns is easier to read as n columns, 3 rows but must be transposed before Igor can use them.
			// At the moment these colors are the same as in the  DataSections  listbox
			make /O	/W /U /N=(UFPE_ST_MAX,3) 	   	   $"root:uf:" + sFolders + ":wQDPSrcColors" 		
			wave	wColors		 		= $"root:uf:" + sFolders + ":wQDPSrcColors" 		
			 UFPE_LBColors( wColors )		


			// Link the  indices  of  Foreground  and  Background  colors  to  their name strings which are later used to access the layer where the color is to be set
			variable	planeFore	= 1
			variable	planeBack	= 2
			SetDimLabel 2, planeBack,  $"backColors"	wFlags
			SetDimLabel 2, planeFore,   $"foreColors"	wFlags
	
		else													// The panel DOES exist. It may be minimised to an icon or it may be hidden behind other panels. If it is hidden then the checkbox must be actuated twice: hide and then restore panel to make it visible
			MoveWindow /W=$sWin	1,1,1,1						// Restore previous size and position. This does NOT take into account that the panel size may have changed in the meantime due to more or less columns or rows

			UFCom_MoveWindow1( sWin, UFCom_kRIGHT1, -3, xSize, kLB_QDP_Y, 0, ySize )// Extract previous panel position and size. Keep only position and discard size as the size may have changed in the meantime due to more or less columns or rows.

			wave   	/T		wTxt			= $"root:uf:" + sFolders + ":wQDPSrcTxt"
			wave   			wFlags	  	= $"root:uf:" + sFolders + ":wQDPSrcFlags"
			Redimension	/N = ( nRows, nCols*(1+nSubCols) )		wTxt
			Redimension	/N = ( nRows, nCols*(1+nSubCols), 3 )		wFlags
		endif

		// Set the column titles in the SR text wave, take the entries as computed above
		variable	w, lbCol
		for ( c = 0; c < nCols; c += 1 )								// the true columns 0,1,2  each including the window subcolumns
			for ( w = 0; w <= nSubCols; w += 1 )						// 1 more as w=0 is not a window but the SrcRegTyp column
				lbCol	= c * (nSubCols+1) + w
				if ( w == 0 )
					sColTitle	= StringFromList( c, lstColTitles, UFCom_ksCOL_SEP )	// 1 means columns,   true column 	e.g. 'Ch 0 Rg 0'  or  'Adc1 Rg1'  or  'Adc1 Rg 0'
				else
					sColTitle	= SubCol2SubNm( w - 1 )  				// 1 means columns,   subcolumn	e.g. 'Q0e'  or  'D1s' 
				endif
				SetDimLabel 1, lbCol, $sColTitle, wTxt
				// printf "\t\tLBSelectQDPSources() \tc:%2d/%2d\tw:%2d/%2d\t->\tlbCol:%2d\t'%s'\t   \r", c, nCols, w, nSubCols, lbCol, sColTitle
			endfor
		endfor

		// Fill the listbox columns with the appropriate  text.................???????????????
		variable	r
		for ( c = 0; c < nCols; c += 1 )
			if ( c == 0 )
				ListBox   	$ksLB_QDPSRC_CNM,    win = $ksLB_QDPSRC_WNM, 	widths  =	{ kLB_QDPSRC_COLWID_MAIN,  kLB_QDP_CW,  kLB_QDP_CW,  kLB_QDP_CW, kLB_QDP_CW,  kLB_QDP_CW,  kLB_QDP_CW, kLB_QDP_CW,  kLB_QDP_CW }	// !!! number of entries depends on 'nSubCols'...	
			else
				ListBox 	$ksLB_QDPSRC_CNM,    win = $ksLB_QDPSRC_WNM, 	widths +=	{ kLB_QDPSRC_COLWID_MAIN,  kLB_QDP_CW,  kLB_QDP_CW,  kLB_QDP_CW, kLB_QDP_CW,  kLB_QDP_CW,  kLB_QDP_CW,  kLB_QDP_CW,  kLB_QDP_CW }	// ..= 2* ( kQDP_QUOTS + kQDP_DIFFS + kQDP_PRODS )
			endif
			lstItemsInColumn  = StringFromList( c, lstColItems, UFCom_ksCOL_SEP )	
			for ( r = 0; r < ItemsInList( lstItemsInColumn ); r += 1 )
				for ( w = 0; w <= nSubCols; w += 1 )			// 1 more as w=0 is not a window but the SrcRegTyp column
					lbCol	= c *(nSubCols+1) + w
					if ( w == 0 )
						wTxt[ r ][ lbCol ]	= StringFromList( r, lstItemsInColumn )				// set the text 
					else
						wTxt[ r ][ lbCol ]	= ""
					endif
				endfor
			endfor
			for ( r = ItemsInList( lstItemsInColumn ); r < nRows; r += 1 )
				for ( w = 0; w <= nSubCols; w += 1 )
					lbCol	= c * (nSubCols+1) + w
					wTxt[ r ][ lbCol ]	= ""
				endfor
			endfor
		endfor
	
		// Build the listbox which is the one and only panel control.  For some reason there is (in contrast to the DataSections panel)  no mode=4  or  mode=5  setting required here. 
		ListBox 	  $ksLB_QDPSRC_CNM,    win = $ksLB_QDPSRC_WNM, 	pos = { 2, 0 },  size = { xSize, ySize + UFCom_kLB_ADDY },  frame = 2
		ListBox	  $ksLB_QDPSRC_CNM,    win = $ksLB_QDPSRC_WNM, 	listWave 			= $"root:uf:" + sFolders + ":wQDPSrcTxt"
		ListBox 	  $ksLB_QDPSRC_CNM,    win = $ksLB_QDPSRC_WNM, 	selWave 			= $"root:uf:" + sFolders + ":wQDPSrcFlags",  editStyle = 1
		ListBox	  $ksLB_QDPSRC_CNM,    win = $ksLB_QDPSRC_WNM, 	colorWave		= $"root:uf:" + sFolders + ":wQDPSrcColors"				// 2005-1108
		ListBox 	  $ksLB_QDPSRC_CNM,    win = $ksLB_QDPSRC_WNM, 	proc 	 		 	= LbSelQDPSrcProc
//		ListBox 	  $ksLB_QDPSRC_CNM,    win = $ksLB_QDPSRC_WNM, 	userdata( lstCol2ChRg)	= lstCol2ChRg

//	endif		// bVisible : state of 'Select QDP sources panel' checkbox is  ON 
End



Function		LbSelQDPSrcProc( s ) : ListBoxControl
// Dispatches the various actions to be taken when the user clicks in the Listbox. 
// At the moment the actions are  1. colorise the listbox fields  2. add  QDP beg/end  to  or remove QDP beg/end  from window.  Note: if ( s.eventCode == UFCom_LBE_MouseUp  )	does not work here like it does in the data sections listbox ???
	struct	WMListboxAction &s

// 2009-10-29
if (  s.eventCode != UFCom_kEV_ABOUT_TO_BE_KILLED )

	string  	sFolders		= "acq:pul"
	wave	wFlags		= $"root:uf:" + sFolders + ":wQDPSrcFlags"
	wave   /T	wTxt			= $"root:uf:" + sFolders + ":wQDPSrcTxt"
	string  	sPlaneNm		= "BackColors" 
	variable	pl			= FindDimLabel( wFlags, 2, sPlaneNm )
	variable	nOldState		= UFPE_LBState( wFlags, s.row, s.col, pl )					// the old state
//	string  	lstCol2ChRg 	= GetUserData( 	s.win,  s.ctrlName,  "lstCol2ChRg" )	// e.g. for 2 columns '0,0;1,2;'  (Col0 is Ch0Rg0 , col1 is Ch1Rg2) 

	//.......na............... Convert the modifying key (e.g. 'Ctrl' ,  'Ctrl Alt / Alt Gr' ) to a state = color  (e.g. select for file, for print or for both )  
	variable	nState		= UFPE_LBModifier2State( s.eventMod, UFPE_lstMOD2STATE1)		//..................na.......NoModif:cyan:3:Tbl+Avg ,  Alt:green:2:Avg ,  Ctrl:1:blue:Tbl ,   AltGr:cyan:3:Tbl+Avg 

	 //printf "\t\tLbSelQDPSrcProc( s ) 1\trow:%2d\tcol:%2d  evCode:%2d\tevModif:%2d\toldstate:%2d -> %2d \tlstColChans:'%s' \r", s.row , s.col, s.eventCode, s.eventMod,  nOldState, nState, lstCol2ChRg
	 printf "\t\tLbSelQDPSrcProc( s ) 1\trow:%2d\tcol:%2d  evCode:%2d\tevModif:%2d\toldstate:%2d -> %2d \t \r", s.row , s.col, s.eventCode, s.eventMod,  nOldState, nState

//	//  Construct or delete  'wAcqPt'  . This wave contains just 1 analysed  X-Y-result point which is to be displayed in the acquisition window over the original trace as a visual check that the analysis worked.  
//	variable	ch		= LbCol2Ch( s.col )								// the column of the channel (ignoring all additional window columns)
//	variable	w		= LbCol2Wnd( s.col )	
//	string  	sChRg	= StringFromList( ch, lstCol2ChRg )					// e.g. '0,0;1,2;'  ->  '1,2;'
//
//	variable	rg		= UFPE_ChRg2Rg( sChRg )									// e.g.  Base , Peak ,  F0_A1, Lat1_xxx ,  Quotxxx
//	string  	sTyp		= wTxt[ s.row ][ ch  ]									// retrieves type when window column is clicked
//	variable	rtp	= UFPE_WhichListItemIgnorWhiteSp( sTyp, UFPE_klstEVL_RESULTS ) 	// e.g. UFPE_kE_Base=15,  UFPE_kE_PEAK=25  todo fits......
//	string  	sWnd, lstChRgTyp
//	string  	sSrc		= StringFromList( ch, LstChan_a(), UFCom_ksSEP_TAB )
//	string  	sOlaNm 	= OlaNm( sSrc, sTyp, rg ) 								// e.g. 
//	// Sample : sControlNm  'root_uf_acq_ola_wa_Adc1Peak_WA0'  ,    boolean variable name : 'root:uf:acq:ola:wa:Adc1Peak_WA0'  , 	sOLANm: 'Adc1Peak'  ,  sWnd: 'WA0'
//
//	// MOUSE : SET a  cell. Click in a cell  in any row or column. Depending on the modifiers used, the cell changes state and color and stay in this state. It can be reset by shift clicking again or by globally reseting all cells.
//	if ( s.eventCode == UFCom_LBE_MouseDown  &&  !( s.eventMod & kSHIFT ) )	// Only mouse clicks  without SHIFT  are interpreted here.  // ??? In this listbox only MouseDown is detected, whereas in the similar  DataSections  listbox  MouseUp  is detected???
//		 UFPE_LBSet5( wFlags, s.row, s.row, s.col, pl, nState )				// sets flags .  The range feature is not used here so  begin row = end row .
//		// printf "\t\tlbSelResOAProc( s ) 2\trow:%2d\tcol:%2d  evCode:%2d\tevModif:%2d\tstate:%2d =?=%2d  \r",  s.row, s.col,  s.eventCode, s.eventMod, nState, UFPE_LBState( wFlags, s.row, s.col, pl )	
//		 printf "\t\tLbSelQDPSrcProc( ADD 4\trow:%2d\tcol:%2d  evCode:%2d\tevModif:%2d\toldstate:%2d -> %2d \tlstColChans:'%s' -> ch:%2d  rg.%2d  w:%2d  kEIdx:%3d   '%s'\t'%s\t   \r", s.row , s.col, s.eventCode, s.eventMod,  nOldState, nState, lstCol2ChRg, ch, rg, w,  rtp, sTyp, sOlaNm
//
//		if ( w > 0 ) 														//  A  Window column cell has been clicked  ( ignore  clicks into  the  SrcRegTyp column)
//			sWnd		= PossiblyAddAnalysisWnd( w-1 )
//			lstChRgTyp	= SetChRgTyp( sFolders, ch, rg, s.row, num2str( rtp ) )	// Make the connection between result 'rtp' and  Chan/Reg permanent in global list 'lstChRgTyp'
//			Construct1AcqEvalPoint( sFolders, ch, rg, rtp )					// Construct  'wAcqPt'  .
//			DrawAnalysisWndTrace( sWnd, sOLANm )							// from now on display this SrcRegionTyp in this window
//			DrawAnalysisWndXUnits( sWnd )	
//		endif
//
//	endif
//
//	// MOUSE :  RESET a cell  by  Shift Clicking
//	if ( s.eventCode == UFCom_LBE_MouseDown  &&  ( s.eventMod & kSHIFT ) )	// Only mouse clicks  with    SHIFT  are interpreted here.  // ??? In this listbox only MouseDown is detected, whereas in the similar  DataSections  listbox  MouseUp  is detected???
//		nState		= 0									// Reset a cell  
//		 UFPE_LBSet5( wFlags, s.row, s.row, s.col, pl, nState )				// sets flags .  The range feature is not used here so  begin row = end row .
//		// printf "\t\tlbSelResOAProc( s ) 3\trow:%2d\tcol:%2d  evCode:%2d\tevModif:%2d\tstate:%2d =?=%2d  \r",  s.row, s.col,  s.eventCode, s.eventMod, nState, UFPE_LBState( wFlags, s.row, s.col, pl )	
//		if ( w > 0 ) 												//  A  Window column cell has been clicked  ( ignore  clicks into  the  SrcRegTyp column)
//			lstChRgTyp	= SetChRgTyp( sFolders, ch, rg, s.row, "" )
//			Delete1AcqEvalPoint( sFolders, ch, rg, rtp )				// Delete  'wAcqPt'  : Remove this SrcRegTyp from this window 
//		endif
//	
//		// Only if no other SrcRegTyp uses this window we can remove also the window 
//		variable	nUsed	= 0
//		variable	c, nCols	= ItemsInList( lstCol2ChRg ) 					// the number of SrcRegTyp columns (ignoring any window columns) 
//		string  	sTxt		= ""
//		for ( c = 0; c < nCols; c += 1 )
//			variable	nTrueCol	= c * ( kMAX_OLA_WNDS + 1 ) + w  
//			variable	r, nRows	= DimSize( wTxt, 0 )					// or wFlags
//			for ( r = 0; r < nRows; r += 1 )
//				nUsed += ( UFPE_LBState( wFlags, r, nTrueCol, pl ) != 0 )
//				// printf "\t\tlbSelResOAProc( DEL 3\tr:%2d/%2d\tcol:%2d  evCode:%2d\tevModif:%2d\toldstate:%2d -> %2d \tlstColChans:'%s' -> ch:%2d  rg.%2d  w:%2d  kEIdx:%3d   '%s' -> State:%2d   Used:%2d \r", r, nRows, nTrueCol, s.eventCode, s.eventMod,  nOldState, nState, lstCol2ChRg, ch, rg, w, rtp, sTyp, UFPE_LBState( wFlags, r, nTrueCol, pl ), nUsed
//			endfor
//		endfor
//		sWnd	= AnalWndNm( w-1 )
//		if ( nUsed == 0 )
//			sTxt	= "Window '" + sWnd + "' no longer used : Delete window."
//			KillWindow $sWnd
//		else
//			sTxt	= "Window '" + sWnd + "' still used " + num2str( nUsed ) + " times. Cannot delete window."
//		endif
//		 printf "\t\tLbSelQDPSrcProc( DEL 4\trow:%2d\tcol:%2d  evCode:%2d\tevModif:%2d\toldstate:%2d -> %2d \tlstColChans:'%s' -> ch:%2d  rg.%2d  w:%2d  kEIdx:%3d   '%s' -> %s  \r", s.row , s.col, s.eventCode, s.eventMod,  nOldState, nState, lstCol2ChRg, ch, rg, w, rtp, sTyp, sTxt
//	endif
//
//	// Check if a  QDP field has been clicked (=click in row  Q0, Q1, Q2, D0....P1, P2   ONLY  in column 0 [here: ch=0] ) : this will open the QDPSources select listbox.
//	// If a column > 0 in a QPD row has been clicked the user wants to add the QPD result to the corresponding window.  This case is handled above.
//	if ( ch == 0  &&  IsQDP( sFolders, wTxt[ s.row ][ 0 ] ) )				// Binary derived results (=Quot,Diff,Product) exist only once so for the  channel and for the region only the dummy index 0 exists.
//		string  	sQDPBase= QDPNm2Base( wTxt[ s.row ][ 0 ]  )		// e.g. 'Qu1'  -> 'Qu' 	
//		variable	nQDPIdx	= QDPNm2Nr( wTxt[ s.row ][ 0 ]  )		// e.g. 'Qu1'  -> '1' 	
//
//		if ( s.eventCode == UFCom_LBE_MouseDown  &&  !( s.eventMod & kSHIFT ) )	// Only mouse clicks  without SHIFT  are interpreted here.  For some reason in this listbox only MouseDown is detected, whereas in the similar  DataSections  listbox  MouseUp  is detected???
//			printf "\t\ttLbSelQDPSrcProc( QDP+5\trow:%2d\t'%s'\t'%s'\tnQDPIdx:%2d\t \r", s.row, wTxt[ s.row ][ 0 ], sQDPBase, nQDPIdx
//			LBSelectQDPSources( sFolders )
//		else
//			printf "\t\tLbSelQDPSrcProc( QDP-6\trow:%2d\t'%s'\t'%s'\tnQDPIdx:%2d\t \r", s.row, wTxt[ s.row ][ 0 ], sQDPBase, nQDPIdx
//		endif
//	endif

endif

End



Function	/S	ListQDPSrcAllChs( lstGenSelect  )
// Returns list of titles of  'All Currently Computed Values'  which depends on the number of regions, the number and types of the fits and on the latencies, but not yet on the listbox
	string  	lstGenSelect
	variable	ch
	variable	nChans		= ItemsInList( LstChan_a(), UFCom_ksSEP_TAB )
	string 	lstACVAllCh	= ""
	for ( ch = 0; ch < nChans; ch += 1 )
		lstACVAllCh	+= ListQDPSrcOA( ch, lstGenSelect )
	endfor
	 printf "ListQDPSrcAllChs()  has %d items (%s...%s) \r", ItemsInList( lstACVAllCh ),  lstACVAllCh[0,80],  lstACVAllCh[ strlen( lstACVAllCh )-80, inf ]  
	return	lstACVAllCh
End

Function	/S	ListQDPSrcOA( ch, lstGenSelect )
// Returns complete list of titles of  'All Currently Computed Values'  which depends on the number of regions, the number and types of the fits and on the latencies, but not yet on the listbox
	variable	ch
	string  	lstGenSelect
	string  	sFolders	= ksF_ACQ_PUL 
	variable	nRegs	= UFPE_RegionCnt(  sFolders, ch )
	variable	rg
	string  	lstACV	= ""
	for ( rg = 0; rg < nRegs; rg += 1 )
		lstACV	+= ListQDPSrc1RegionOA( ch, rg, lstGenSelect )
	endfor
	 printf "\t\tListQDPSrcOA( ch:%2d )\t\t\t\tItms:%3d\t'%s' ... '%s'   \r", ch, ItemsInList( lstACV ), lstACV[0,80],  lstACV[ strlen( lstACV )-80, inf ]  
	return	lstACV
End

Function	/S	ListQDPSrc1RegionOA( ch, rg, lstGenSelect )
// Returns complete list of titles of  'All Currently Computed Values'  which depends on the number of regions, the number and types of the fits, but not yet on the listbox
	variable	ch, rg
	string  	lstGenSelect
	string  	sFolders	= ksF_ACQ_PUL
	variable	nChans	= ItemsInList( LstChan_a(), UFCom_ksSEP_TAB )
	variable	LatCnt	= LatCnt_a() 
	string  	lstACV	= ""
	lstACV	+= ListQDPSrcGenOLA( sFolders, ch, rg, lstGenSelect )			
	lstACV	+= ListQDPSrcFitOLA( sFolders, ch, rg )					// generic.....not yet...???...
	// ?QDP lstACV	+= ListQDPSrcLat( sFolders, ch, rg, nChans, LatCnt )			// generic
	// lstACV	+= ListQDPSrcDiff( sFolders, ch, rg, nChans, kOLA_DIFF_MAX )	// generic
	 printf "\t\tListQDPSrc1OA( ch:%2d/%2d  rg:%2d  LC:%2d )\tItms:%3d\t'%s' ... '%s'   \r", ch, nChans, rg, LatCnt, ItemsInList( lstACV ), lstACV[0,80],  lstACV[ strlen( lstACV )-80, strlen( lstACV )-1 ]  
	return	lstACV
End

Function	/S	ListQDPSrcGenOLA( sFolders, ch, rg, lstGenSelect )
// Returns complete list of titles of the general (=Non-fit)  'All Currently Computed Values'  which depends on the number of regions, the number and types of the fits, but not yet on the listbox
	string  	sFolders, lstGenSelect			// e.g. 	'acq:ola'  or  'eva:de'
	variable	ch, rg
	string  	sPostfx		= UFPE_ChRgPostFix( ch, rg )
	string		lst			= ""
	variable	shp, pt, nPts	= ItemsInList( UFPE_klstEVL_RESULTS )
	for ( pt = 0; pt < nPts; pt += 1 )
		shp	= str2num( StringFromList( pt, lstGenSelect ) )					// 
		if ( numtype( shp ) != UFCom_kNUMTYPE_NAN ) 								// if there is a value in 'lstGenSelect'  this item will be added to the QDPSources select panel
			lst	= AddListItem( UFPE_EvalNm( pt ) + sPostfx, lst, ";", inf )					// the general values : base, peak, etc
		endif
	endfor

	return	lst
End

Function	/S	ListQDPSrcFitOLA( sFolders, ch, rg )
// Returns list of all FitParameters, FitStartParameters and FitInfoNumbers (e.g. nIter, ChiSqr)  for the fit function specified by channel and region 
	string  	sFolders			// e.g. 	'acq:ola'  or  'eva:de'
	variable	ch, rg
	string  	lst		= ""	
	variable	fi, nFits	=  FitCnt_a()
	for ( fi = 0; fi < nFits; fi += 1 )
		if ( UFPE_DoFit( sFolders, ch, rg, fi, LatCnt_a() ) )
			lst	= ListQDPSrcFitOA( lst, sFolders, ch, rg, fi )
		endif
	endfor
	 printf "\t\tListQDPSrcFitOLA(\t'%s'\tch:%2d, rg:%2d   )\t'%s'  \r", sFolders, ch, rg, lst[0,200]
	return	lst
End	

Function	/S	ListQDPSrcFitOA( lst, sFolders, ch, rg, fi )
// !!! Cave: If this order (Params, derived Params)  is changed the extraction algorithm ( = ResultsFromLB_OA() ) must also be changed 
	string  	lst, sFolders
	variable	ch, rg, fi
	variable	pa, nPars
	variable	nFitInfo, nFitInfos	=  UFPE_FitInfoCnt()
	variable	nFitFunc			= UFPE_FitFnc_( sFolders, ch, rg, fi )
	nPars	=  UFPE_ParCnt( nFitFunc )					
	for ( pa = 0; pa < nPars; pa += 1 )				// the fit  parameters: 	  A0, T0, A1, T12,  Constant, Slope etc.-> Fit1_A0, Fit1_T0...
		lst	= AddListItem( UFPE_FitParInLBNm( ch, rg, fi, pa, nFitFunc ),  lst, ";" , inf )			// e.g. 'Fit1_A0_00'
	endfor
	variable nDerived =  UFPE_DerivedCnt( nFitFunc )
	for ( pa = 0; pa < nDerived; pa += 1 )				// the derived parameters: wTau, Capacitance, ...
		lst	= AddListItem( UFPE_FitDerivedInLBNm( ch, rg, fi, pa, nFitFunc ),  lst, ";" , inf )			// e.g. 'Fit1_WTau_00'
	endfor
	 printf "\t\tListQDPSrcFitOA(\t%s\tch:%2d, rg:%2d, fi:%2d )\t'%s'  \r", sFolders, ch, rg, fi, lst[0,200]
	return	lst
End



//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// DIFFS

static constant	kQDP_DESC_LENGTH = 1
static strconstant	ksQDP_SEPAR = "_"
static strconstant ksDIFF_BASE	= "d"  	// "L"  ,  "La"  or  "Lat"	
constant		kOLA_DIFF_MAX	= 2
strconstant 	klstANYC	= "off;DE;FG;HI"
constant		kANY_OFF = 0

Function	/S	ListQDPSrcDiff( sFolders, nThisCh, nThisRg, nChannels, AnyCnt )
// Returns list of all  Diffs  specified by channel and region (the end value determines the channel and region)
// We need 2 steps because the   Diffs  index  and  BegEnd   are not ordered in respect to channel and region
	string  	sFolders							// e.g. 'acq:pul'
	variable	nThisCh, nThisRg, nChannels, AnyCnt 
	string  	lst		= ""	
	variable	BegEnd, lc
	variable	ch, rg, rgCnt, nAnyOp	
	string  	sAnyOp

	make /O /T /N=( nChannels, UFPE_kRG_MAX, AnyCnt, 2 )  $"root:uf:" + sFolders + ":wTmpAnyNames" = ""
	wave      /T  wTmpAnyNames =  $"root:uf:" + sFolders + ":wTmpAnyNames"

	// Step 1: Store all extracted  ...???...popupmenu...???...    settings in a 4 dim temporary wave. Only after this pass we can be sure that all settings are valid. 
	for ( lc = 0; lc < AnyCnt; lc += 1 )
		for ( BegEnd = UFPE_CN_BEG; BegEnd <=  UFPE_CN_END; BegEnd += 1 )
			for ( ch = 0; ch < nChannels; ch += 1)
				rgCnt	= UFPE_RegionCnt( sFolders, ch )
				for ( rg = 0; rg < rgCnt;  rg += 1 )	
					nAnyOp	= 1 // TODOA  AnyC(   UFPE_LatC( sFolders, ch, rg, lc, BegEnd )
					sAnyOp	= StringFromList( nAnyOp, klstANYC )		// TODOA  AnyC(  
					if ( nAnyOp != kANY_OFF )
						wTmpAnyNames[ ch ][ rg ][ lc ][ BegEnd ] = AnyNm( sFolders, lc, BegEnd, ch, rg ) 
						 printf "\t\tListQDPSrcDiff( a  ch:%d, rg:%d )\tany:%2d/%2d\t  ch:%d   rg:%d\t%s\tAnyOp:%2d\t(%s) \tAnyNm:%s\t  \r", nThisCh, nThisRg, lc, AnyCnt, ch, rg,  SelectString( BegEnd, "Beg:    " , "  -> End:" ), nAnyOp, sAnyOp, UFCom_pd(wTmpAnyNames[ ch ][ rg ][ lc ][ BegEnd ] ,12)
					endif
				endfor
			endfor
		endfor
	endfor
	
	// Step 2: Only after all extracted  popupmenu settings have been stored  in a 4 dim temporary wave we can extract them from there in any order.
	for ( lc = 0; lc < AnyCnt; lc += 1 )
		for ( BegEnd = UFPE_CN_BEG; BegEnd <=  UFPE_CN_END; BegEnd += 1 )
			for ( ch = 0; ch < nChannels; ch += 1)
				rgCnt	= UFPE_RegionCnt( sFolders, ch )
				for ( rg = 0; rg < rgCnt;  rg += 1 )	
					lst  += wTmpAnyNames[ ch ][ rg ][ lc ][ BegEnd ] 	// most of them are empty strings  
					// printf "\t\tListQDPSrcDiff( b  ch:%d, rg:%d )\tAny:%2d/%2d\t  ch:%d   rg:%d\t%s\tlst: '%s' \t  \r", nThisCh, nThisRg, lc, AnyCnt, ch, rg,  SelectString( BegEnd, "Beg:    " , "  -> End:" ), lst[0,200]
				endfor
			endfor
		endfor
		lst  +=  UFPE_ChRgPostFix( nThisCh, nThisRg ) + ";"			//  add the list delimiter 
	endfor

	KillWaves  $"root:uf:" + sFolders + ":wTmpAnyNames"
	 printf "\t\tListQDPSrcDif( c  ch:%d, rg:%d )\tAny:%2d/%2d\t lst: '%s' \r", nThisCh, nThisRg, lc, AnyCnt,  lst[0,200]
	return	lst
End	

Function	/S	AnyNm( sFolders, lc, BegEnd, ch, rg )
// Builds partial  latency name (=first or second half)  e.g. for the begin  'Lat1m01'  but  for the end only   'R22'  . Both parts must be catenated elsewhere!
	string  	sFolders
	variable	lc, BegEnd, ch, rg
	variable	nAnyOp	= 1 	// todoA   AnyC(     UFPE_LatC( sFolders, ch, rg, lc, BegEnd )
	string		sAnyOp	= StringFromList( nAnyOp, klstANYC )
	// e.g. for the begin  'Diff1m01'  but  for the end only   'R22'  .  Both parts must be catenated elsewhere!

// TODOA
	return	SelectString( BegEnd, ksDIFF_BASE + num2str( lc ) + ksQDP_SEPAR + sAnyOp[ 0, kQDP_DESC_LENGTH-1 ] + num2str( ch ) + num2str( rg ),   sAnyOp[ 0, kQDP_DESC_LENGTH-1 ] + num2str( ch ) + num2str( rg ) )	
End

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
