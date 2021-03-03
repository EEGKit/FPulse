// UF_AcqActions


//===========================================================================================================================================

//===========================================================================================================================================

Function	/S	fLstCh_a( sBaseNm, sF, sWin )
	string  	sBaseNm, sF, sWin 
	string  	sFolders	= ReplaceString( "root:uf:", sF, "" ) + sWin 	  	// e.g.  'root:uf:acq:' + 'pul'  -> 'acq:pul'
	return	LstChan_a()
End	

// 2008-06-15  Should be moved to   UF_AcqDisp6 ???
// 2008-06-15  Called VERY OFTEN.    Are all these calls really necessary???
Function	/S	LstChan_a()
// Companion function to   'IndexOfTab()'

	string  	sFo	= ksACQ
	string 	sTrace, sList = ""
	variable	nio, cio, cioCnt
	string  	sIOType, lstOneIO, sIONr
	svar	/Z	lllstIO			= $"root:uf:" + sFo + ":" + "lllstIO" 	
	if ( svar_exists( lllstIO ) )
		for ( nio = 0; nio <= kSC_ADC; nio += 1 )					// dac , adc but no pon yet
			sIOType	= StringFromList( nio, klstSC_NIO )
			lstOneIO	= StringFromList( nio, lllstIO, "~" )
			cioCnt	= ItemsInList( lstOneIO )
			for ( cio = 0; cio < cioCnt; cio += 1 )
				sIONr	=  StringFromList( kSC_IO_CHAN, StringFromList( cio, lstOneIO )	, "," )	
				sTrace	=  sIOType + sIONr
				sList		= AddListItem( sTrace, sList,  UFCom_ksSEP_TAB, Inf )
			endfor
		endfor
	endif
	// printf "\tLstChan_a()  items:%d    \tsTitleList='%s' \r", ItemsInList( sList, UFCom_ksSEP_TAB ), sList	
	return	sList
End

//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function	/S	fLstRg_a( sBaseNm, sF, sWin )
	string  	sBaseNm, sF, sWin 
	string  	sFolders	= ReplaceString( "root:uf:", sF, "" ) + sWin 	  	// e.g.  'root:uf:eva:' + 'de'  -> 'eva:de'
	return	LstReg_a( sFolders )
End

Function	/S	LstReg_a( sFolders )
// Builds a region list consisting entirely of channel and region separators. From this list the number of regions in each channel can easily be derived.
	string  	sFolders		
	string  	lstRegs		= ""
	string  	lstChans		= LstChan_a()
	variable	r, ch, nChans	= ItemsInList( lstChans, UFCom_ksSEP_TAB )
	for ( ch = 0; ch < nChans; ch += 1 )
		variable	nRegs	= UFPE_RegionCnt( sFolders, ch )
		for ( r = 0; r < nRegs; r += 1 )
			lstRegs	   += UFCom_ksSEP_STD  				//	the block prefix for the title may be empty only containing separators (to determine the number of regions/blocks)
		endfor
		lstRegs	   += UFCom_ksSEP_TAB
	endfor
	// printf "\t\t\t\tLstReg_a( %s ):\t'%s'  \r", sFolders, lstRegs
	return	lstRegs
End

//===========================================================================================================================================

Function		fReg_a( s ) 
// Demo: this  SetVariable control  changes the number of blocks. Consequently the Panel must be rebuilt  OR  it must have a constant large size providing space for the maximum number of blocks.
	struct	WMSetvariableAction    &s
	string  	sFolders	= ReplaceString( "root:uf:", GetUserData( s.win,  s.ctrlName, "sFo" ), "" ) + s.win	// e.g.  'root:uf:acq:' -> 'acq:pul'

	variable	ch		= UFCom_TabIdx( s.ctrlName )
	string  	lstRegs	= LstReg_a( sFolders )
	string  	sWnd	= FindFirstWnd_a( ch )
	variable	LatCnt	= LatCnt_a()
	variable	FitCnt	= FitCnt_a()
	variable	nChans	= ItemsInList( LstChan_a(), UFCom_ksSEP_TAB )
	  printf "\t%s\t\t\t\t\t%s\tvar:%g\t-> \tch:%d\tLstBlk3:\t%s\t  \r",  UFCom_pd(sFolders,13), UFCom_pd(s.CtrlName,26), s.dval,ch, UFCom_pd( lstRegs, 19)

	// Compute the location of panel controls and the panel dimensions. Redraw the panel displaying and hiding needed/unneeded controls
	UFCom_Panel3Main(   "pul", "", "root:uf:" + ksACQ_, 100,  0 )		

	UFPE_DisplayCursors_Peak( sFolders, sWnd, ch, LatCnt )
	UFPE_DisplayCursors_Base( sFolders, sWnd, ch, LatCnt )
	UFPE_DisplayCursors_Lat(    sFolders, sWnd, ch, LatCnt )
	UFPE_DisplayCursors_UsedFit( sFolders, sWnd, ch, LatCnt, FitCnt )					// Display the used fit cursors and hide the unused fit cursors immediately depending on the state of the region and fit checkboxes to give the user a feedback which parts of the data will be fitted in the next analysis

	LBResSelUpdateOA()											// update the 'Select results' panel whose size has changed
	UFPE_AllLatenciesCheck( sFolders, nChans, LatCnt )					// If a region which has been turned off still contains a latency option this will be flagged as an error

// gn ControlUpdate /A /W=$"de"

End


Function		UFPE_RegionCnt( sFolders, ch )
	string  	sFolders
	variable	ch
	// string  	sCtrlNm  = "root_uf_eva_de_svReg" + num2str( ch ) + "000" // Version1: get value from ControlInfo which might be slow
	// ControlInfo /W= $ksDE $sCtrlNm
	// variable	cnt	= V_Value	
	nvar		cnt	= $"root:uf:" + sFolders + ":svReg" + num2str( ch ) + "000"	 // Version2: get value from underlying variable which should be faster than getting it from the ControlInfo
	// printf "\t\t\tUFPE_RegionCnt( %s ch:%d ) : %d \t \r", sFolders, ch, cnt
	return	cnt
End

//===========================================================================================================================================

Function		UFPE_DisplayCursors_Base( sFolders, sWnd, ch, LatCnt )
	string  	sFolders, sWnd
	variable	ch, LatCnt
	variable	rg
	for ( rg = 0; rg < UFPE_kRG_MAX; rg += 1 )						
		DisplayCursor_Base( sFolders, sWnd, ch, rg, LatCnt )
	endfor
End

static Function		DisplayCursor_Base( sFolders, sWnd, ch, rg, LatCnt )
	string  	sFolders, sWnd
	variable	ch, rg, LatCnt
	variable	bOn	=  rg < UFPE_RegionCnt( sFolders, ch )  &&  UFPE_BaseOp_( sFolders, ch, rg ) != kBASE_OFF	// order is vital: check region first  and avoid so the evaluation of UFPE_BaseOp_() for unused regions which is illegal 
	UFPE_DisplayHideCursors( sFolders, sWnd, ch, rg, UFPE_kCSR_BASE, 0, bOn, LatCnt )							// Display the base cursors only if they are 'on'  and if their region is 'on'...
End


Function		UFPE_DisplayCursors_Peak( sFolders, sWnd, ch, LatCnt )
	string  	sFolders, sWnd
	variable	ch, LatCnt
	variable	rg
	for ( rg = 0; rg < UFPE_kRG_MAX; rg += 1 )						
		DisplayCursor_Peak( sFolders, sWnd, ch, rg, LatCnt )
	endfor
End

static Function		DisplayCursor_Peak( sFolders, sWnd, ch, rg, LatCnt )
	string  	sFolders, sWnd
	variable	ch, rg, LatCnt
	variable	bOn		= rg < UFPE_RegionCnt( sFolders, ch )  &&  UFPE_PeakDir( sFolders, ch, rg ) != kPEAK_OFF	// order is vital: check region first  and avoid so the evaluation of UFPE_PeakDir() for unused regions which is illegal 
	UFPE_DisplayHideCursors( sFolders, sWnd, ch, rg, UFPE_kCSR_PEAK, 0, bOn, LatCnt )						// Display the peak cursors only if the peak is up or down and if their region is on and hide them if the peak is off or the region is off
End	


Function		UFPE_DisplayCursors_Lat( sFolders, sWnd, ch, LatCnt )
	string  	sFolders, sWnd
	variable	ch, LatCnt
	variable	rg, BegEnd, lc
	for ( lc = 0; lc < LatCnt; lc += 1 )
		for ( BegEnd= UFPE_CN_BEG; BegEnd <=  UFPE_CN_END; BegEnd += 1 )
			for ( rg = 0; rg < UFPE_kRG_MAX; rg += 1 )						
				UFPE_DisplayCursor_Lat( sFolders, sWnd, ch, rg, lc, BegEnd, LatCnt )										// will also hide cursors if checkbox control is off
			endfor
		endfor
	endfor
End

Function		UFPE_DisplayCursor_Lat( sFolders, sWnd, ch, rg, lc, BegEnd, LatCnt )
	string  	sFolders, sWnd
	variable	ch, rg, lc, BegEnd, LatCnt
	variable	bOn	=  rg < UFPE_RegionCnt( sFolders, ch )  &&   UFPE_LatC( sFolders, ch, rg, lc, BegEnd) == kLAT_MANUAL// order is vital: check region first  and avoid so the evaluation of LatCsr() for unused regions which is illegal
	DisplayHideCursor( sFolders, ch, rg, UFPE_kCSR_LAT, lc, BegEnd, sWnd, bOn, LatCnt )					  // will also hide cursors if checkbox control is off
End


Function		UFPE_DisplayCursors_UsedFit( sFolders, sWnd, ch, LatCnt, FitCnt )
	// Display the used fit cursors and hide the unused fit cursors immediately depending on the state of the region and fit checkboxes to give the user a feedback which parts of the data will be fitted in the next analysis
	string  	sFolders, sWnd
	variable	ch, LatCnt, FitCnt
	variable	rg, fi
	for ( rg = 0; rg < UFPE_kRG_MAX; rg += 1 )							
		for ( fi = 0; fi < FitCnt; fi += 1 )
			variable	bOn	= rg  < UFPE_RegionCnt( sFolders, ch )  &&  UFPE_DoFit( sFolders, ch, rg, fi, LatCnt )   	// order is vital: check region first  and avoid so the evaluation of UFPE_DoFit() for unused regions which is illegal 
			UFPE_DisplayHideCursors( sFolders, sWnd, ch, rg, UFPE_kCSR_FIT, fi, bOn, LatCnt )				// Display only the used fit cursors,  hide the cursors if the fit is not useg or if the region is off 
		endfor
	endfor
End

//===========================================================================================================================================

Function		UFPE_DisplayHideCursors( sFolders, sWnd, ch, rg, ct, nc, bOn, LatCnt )
	string  	sFolders, sWnd
	variable	ch, rg, ct, nc, bOn, LatCnt
	DisplayHideCursor( sFolders, ch, rg, ct, nc, UFPE_CN_BEG, sWnd, bOn, LatCnt )
	DisplayHideCursor( sFolders, ch, rg, ct, nc, UFPE_CN_END, sWnd, bOn, LatCnt )
End

	
static  Function		DisplayHideCursor( sFolders, ch, rg, ct, nc, nCsr, sWnd, bOn, LatCnt )
	string  	sFolders
	variable	ch, rg, ct, nc, nCsr, bOn, LatCnt
	string		sWnd
	if ( bOn )
		CursorDisplay( sFolders, ch, rg, ct, nc, nCsr, sWnd, LatCnt )
	else
		CursorHide( sFolders, ch, rg, ct, nc, nCsr, sWnd, LatCnt )
	endif
End
//===========================================================================================================================================

Function	RestoreCursorsBE_a( sFolders, ch, rg, ct, nc, LatCnt, FitCnt )
// Restore cursors to the last position (the cursor position before the cursors were removed because the user switched Base, peak or Fit off.
	string  	sFolders
	variable	ch, rg, ct, nc, LatCnt, FitCnt 
	RestoreCursor_a( sFolders, ch, rg, ct, nc, UFPE_CN_BEG, LatCnt, FitCnt  )
	RestoreCursor_a( sFolders, ch, rg, ct, nc, UFPE_CN_END, LatCnt, FitCnt  )
End

Function	RestoreCursor_a( sFolders, ch, rg, ct, nc, BegEnd, LatCnt, FitCnt  )
// Restore cursors to the last position (the cursor position before the cursors were removed because the user switched Base, peak or Fit off.
	string  	sFolders
	variable	ch, rg, ct, nc, BegEnd, LatCnt, FitCnt 
	wave	wCursor	= $"root:uf:" + sFolders + ":wCursor"
// 2006-0428
//	if ( ! UFPE_CursorIsSet( sFolders, ch, rg, ct, nc, BegEnd ) )	
//		AutoSetCursor( sFolders, ch, rg, ct, nc, BegEnd ) 
//	endif	
//	variable	ph		= UFPE_Csr2Ph(  sFolders, ct, nc )
//	wCursor[ ch ][ rg ][ ph ][ BegEnd ]	= wCursor[ ch ][ rg ][ ph ][ UFPE_CN_SV+ BegEnd ]

//	if ( ! UFPE_CursorIsSet( sFolders, ch, rg, ct, nc, BegEnd ) )	
//		AutoSetCursor( sFolders, ch, rg, ct, nc, BegEnd ) 
//	else	
//		variable	ph				 = UFPE_Csr2Ph(  sFolders, ct, nc )
//		wCursor[ ch ][ rg ][ ph ][ BegEnd ] = wCursor[ ch ][ rg ][ ph ][ UFPE_CN_SV+ BegEnd ]
//	endif	

	variable	ph		= UFPE_Csr2Ph(  sFolders, ct, nc, LatCnt  )
	if ( numType( wCursor[ ch ][ rg ][ ph ][ BegEnd + UFPE_CN_SV ] ) == UFCom_kNUMTYPE_NAN ) 
		AutoSetCursor_a( sFolders, ch, rg, ct, nc, BegEnd, LatCnt, FitCnt ) 							// sets  BegEnd  and  BegEnd + UFPE_CN_SV
	else	
		wCursor[ ch ][ rg ][ ph ][ BegEnd ] = wCursor[ ch ][ rg ][ ph ][ UFPE_CN_SV+ BegEnd ]
	endif	

//	 printf "\t\t\tRestoreCursor_a( ch:%d , rg:%d , ph:%d ,value:\t%8.3lf\t  ) \r", ch, rg, ph, wCursor[ ch ][ rg ][ ph ][ UFPE_CN_BEG ]
End

 Function		AutoSetCursor_a( sFolders, ch, rg, ct, nc, BegEnd, LatCnt, FitCnt )
// Attempt to set Base cursor, Peak cursor and Peak direction automatically for first region and the first fit.  The user can discard the auto-cursors by pressing  'Spread cursors'  again.
// 2006-0426 : Flaw : computes all 3 phases but sets only 1 (efficiency)
	string  	sFolders							// e.g.  'eva:de'  or  'acq:pul'
	variable	ch, rg, ct, nc, BegEnd, LatCnt, FitCnt
	variable	BegPt = 0,	  SIFact = 1, nCurSwpDummy = -1 
	variable	pt, PkDir, PkLoc, PkEnd, FitEnd, DirFactor
	variable	CursorPosition
	string  	sFoldOrgWvNm
	variable	AxisRangeX, TimeLeftX
	string  	sWnd = "", sSrc = "", sTNL = "", sFirstTrace = ""
	variable	rTop = inf, rBottom = -inf

// 2006-0324    bad and ugly code for multiple reasons: 1. arbitrary trace selection   2. arbitrary FindFirstWnd_a()  3. the AxisRangeX  is taken from the wave scaling deltaX / numPnts of  wv  e.g. 'Adc1FC_'   (it might be better to extract it from 'root:uf:acq:pul:io:Adc1' )
	sWnd		= FindFirstWnd_a( ch )
	sSrc			= StringFromList( ch, LstChan_a(), UFCom_ksSEP_TAB )
	sTNL		= TraceNameList( sWnd, ";", 1 )					// e.g.  'wcY_r0_p1_n0;wcY_r0_p1_n1;wcY_r0_p5_n0;Adc1FC_;wcY_r0_p5_n1;Adc1PM_;'
	sTNL		= ListMatch( sTNL, sSrc + "*" )					// e.g.  'Adc1FC_;Adc1PM_;'
	sFirstTrace	= StringFromList( 0, sTNL )						// !!! arbitrary / restriction :  could also use any other trace in this window
	wave  /Z	wv	= TraceNameToWaveRef( sWnd, sFirstTrace )
	sFoldOrgWvNm	= NameOfWave( wv )							
	//sFoldOrgWvNm = UFCom_ksROOT_UF_ + ksACQ_ + UFPE_ksF_IO_ + StringFromList( ch, LstChan_a(), UFCom_ksSEP_TAB )	// in ACQ : Folders + sSource   e.g.  'root:uf:acq:pul:io:Adc1'

// 2006-0427a  better + - inf ????   (this mutilates the stubs...???)
// 2006-0502
//CursorGetYAxis( sWnd, rTop, rBottom )   
	// printf "\t\t\tAutoSetCursors a  ch:%d   rg:    %d  \t\t\t\twave:\t%s\t%s\t%s\thas  deltax: %g  leftX: %g  numPnts: %g \tsTNL: '%s...' \r", ch, rg, UFCom_pd(sFoldOrgWvNm,14), UFCom_pd(sWnd,5), UFCom_pd(sFirstTrace,14), deltaX( wv ), leftX( wv ), numpnts( wv ), sTNL[ 0, 100]

	if ( waveExists( wv ) )

		AxisRangeX	= numPnts( wv ) * deltaX( wv )
		TimeLeftX	 	= leftX( wv )

		if ( rg == 0 )
	
			WaveStats /Q   wv
			PkDir	=  V_avg * 2  < V_min + V_max   ?   kPEAK_UP	:  kPEAK_DOWN	// The higher peak (min or max compared to average) determines the peak direction.. This simple evaluation...
			PkLoc	=  V_avg * 2  < V_min + V_max   ?   V_maxloc	:  V_minloc		// ...may be wrong for nearly equal pos and neg peaks if one has much greater area/time constant shifting the average.
			pt 		= ( PkLoc - TimeLeftX ) / deltaX( wv )
			DirFactor	= PkDir * 2 - 3		// Up=1 -> -1 ,  Down=2 -> +1
			do
				pt += 1
			while ( wv[ pt ] * DirFactor < ( V_avg + V_sdev ) *  DirFactor  &&   pt < V_npnts )	// Arbitrary: PeakEnd is when the decay reaches the mean (rough estimate, tampered by noise)
			PkEnd	= pnt2x( wv, pt )
			FitEnd	= PkEnd + .5 * ( PkEnd - PkLoc )							// Arbitrary: FitEnd is 50% behind PeakEnd
				
			// Try to find  reasonable cursor settings  whenever possible  (todo:  if possible extend this to more regions and to latency cursors...)
			if ( ct == UFPE_kCSR_BASE )
				CursorPosition	= ( BegEnd == UFPE_CN_BEG ) 	?   TimeLeftX + .004 * AxisRangeX    :  TimeLeftX + .90  * ( PkLoc - TimeLeftX )
				UFPE_SetCursorX( sFolders, ch, rg, UFPE_Csr2Ph(  sFolders, UFPE_kCSR_BASE, nc, LatCnt ), BegEnd, CursorPosition )
				UFPE_SetBaseOp_( sFolders, ch, rg, kBASE_MEAN )									// set to normal = mean mode for which the AutoSettings were calculated
			elseif ( ct == UFPE_kCSR_PEAK )
				CursorPosition	= ( BegEnd == UFPE_CN_BEG ) 	?   TimeLeftX + .94  * ( PkLoc - TimeLeftX )	 :  PkEnd
				UFPE_SetCursorX( sFolders, ch, rg, UFPE_Csr2Ph(  sFolders, UFPE_kCSR_PEAK, nc, LatCnt ), BegEnd,  CursorPosition )				
				UFPE_SetPeakDir( sFolders, ch, rg, PkDir )											// update the popupmenu with the auto-determined peak direction
			elseif ( ct == UFPE_kCSR_FIT )
				CursorPosition	= ( BegEnd == UFPE_CN_BEG ) 	?   PkLoc    :  	FitEnd
				UFPE_SetCursorX( sFolders, ch, rg, UFPE_Csr2Ph(  sFolders, UFPE_kCSR_FIT, nc, LatCnt ), BegEnd,  CursorPosition )
			endif
	
			 printf "\t\tAutoSetCursor(a\t\tch:%d rg:%d ct:%d nc:%d )\tPts:\t%8d\tAvg:\t%8.2lf\tMax:\t%8.2lf\tMin:\t%8.2lf\t -> \tPkDir: %s \tPkPt:%8d\tPkLoc:\t%.4lf\tPkEnd:\t%.4lf\tFitEnd:\t%.4lf\t  \r", ch, rg, ct, nc, V_npnts, V_avg, V_max, V_min, UFPE_PeakDirStr_( PkDir ), pt, PkLoc, PkEnd, FitEnd	
		endif

		if ( !  UFPE_CursorIsSet(     sFolders, ch, rg, ct, nc, BegEnd, LatCnt ) )
			UFPE_SpreadCursor( sFolders, ch, rg, ct, nc, BegEnd, AxisRangeX, TimeLeftX, LatCnt, FitCnt )
			 printf "\t\tAutoSetCursor(s\t\tch:%d rg:%d ct:%d nc:%d ) \tNo AutoSet value available: Only spreading cursors...\r", ch, rg, ct, nc
		endif
//		if ( !  UFPE_CursorIsSet(     sFolders, ch, rg, ct, nc, UFPE_CN_END ) )
//			UFPE_SpreadCursor( sFolders, ch, rg, ct, nc, UFPE_CN_END, AxisRangeX, TimeLeftX )
//			 printf "\t\tAutoSetCursor(s\t\tch:%d rg:%d ct:%d nc:%d ) \tNo AutoSet value available: Only spreading cursors...\r", ch, rg, ct, nc
//		endif


		UFPE_CursorSetValue( sFolders, ch, rg, ct, nc, BegEnd, BegPt, SIFact, rTop, rBottom, LatCnt, FitCnt )
//		UFPE_CursorSetValue( sFolders, ch, rg, ct, nc, UFPE_CN_END, BegPt, SIFact, rTop, rBottom )
	endif
End

//===========================================================================================================================================

// 2006-0317
Function		fCancelCsrM_a( s )
	struct  	WMButtonAction	&s								// 2005-1116  called by  pressing a Mouse button in the panel
	string  	sFolders	= ReplaceString( "root:uf:", GetUserData( s.win,  s.ctrlName, "sFo" ), "" ) + s.win	// e.g.  'root:uf:acq:' -> 'acq:pul'
	variable	ch		= UFCom_TabIdx( s.ctrlName )
	string  	sWnd	= FindFirstWnd_a( ch )
	printf "\t\t'%s'\t%s  %s \t'%s' %2d \r", s.CtrlName, sFolders, s.win,   StringFromList( s.eventCode, UFCom_CCE_lstEVENTCODES ), s.eventCode
	UFPE_QuitCursorPositioning( sFolders, sWnd, UFPE_kCURSOR_DISCARD, LatCnt_a(), FitCnt_a() )			// end the mode in which Igor moves Base/Peak/Latency cursors  and  do not save the last cursor
	//buCfsESC( sFolders, sWnd, ch )
End

Function		fOKCsrM_a( s )
	struct  	WMButtonAction	&s								// 2005-1116  called by  pressing a Mouse button in the panel
	string  	sFolders	= ReplaceString( "root:uf:", GetUserData( s.win,  s.ctrlName, "sFo" ), "" ) + s.win	// e.g.  'root:uf:acq:' -> 'acq:pul'
	variable	ch		= UFCom_TabIdx( s.ctrlName )
	string  	sWnd	= FindFirstWnd_a( ch )
	printf "\t\t'%s'\t%s  %s \t'%s' %2d \r", s.CtrlName, sFolders, s.win,   StringFromList( s.eventCode, UFCom_CCE_lstEVENTCODES ), s.eventCode
	UFPE_QuitCursorPositioning( sFolders, sWnd, UFPE_kCURSOR_SAVE, LatCnt_a(), FitCnt_a() )				// end the mode in which Igor moves Base/Peak/Latency cursors  and  save the last cursor
	//buCfsCR( sFolders, sWnd, ch )
End

//===================================================================================================================

Function		fBaseOp_a( s )
	struct	WMPopupAction	&s
	string  	sFolders	= ReplaceString( "root:uf:", GetUserData( s.win,  s.ctrlName, "sFo" ), "" ) + s.win	// e.g.  'root:uf:acq:' -> 'acq:pul'
	variable	ch		= UFCom_TabIdx( s.ctrlName )
	variable	rg		= UFCom_BlkIdx( s.ctrlName )
	 printf "\t%s\t%s\tch:%d  \trg:%d  \t%s\t%g\t  \r",  UFCom_pd(sFolders,15), UFCom_pd(s.CtrlName,31), ch, rg, UFCom_pd( s.popStr,9), (s.popnum-1)
// 2006-0426
	variable	BegPt 	= 0,	  SIFact = 1, nCurSwpDummy = -1 
	variable	Top 		= Inf, Bottom = -inf
// 2006-0510c
	variable	bOn		=  rg < UFPE_RegionCnt( sFolders, ch )  &&  UFPE_BaseOp_( sFolders, ch, rg ) != kBASE_OFF &&  UFPE_BaseOp_( sFolders, ch, rg ) != kBASE_SLOPE	// order is vital: check region first  and avoid so the evaluation of UFPE_BaseOp_() for unused regions which is illegal 
	string  	sWnd	= FindFirstWnd_a( ch )
	UFPE_DisplayHideCursors( sFolders, sWnd, ch, rg, UFPE_kCSR_BASE, 0, bOn, LatCnt_a()  )						// Display the base cursors only if they are 'on'  and if their region is 'on'...
	if ( UFPE_BaseOp_( sFolders, ch, rg ) == kBASE_OFF )
		UFPE_RemoveCursorsBE( sFolders, ch, rg, UFPE_kCSR_BASE, 0, LatCnt_a() )
//	elseif ( UFPE_BaseOp_( sFolders, ch, rg ) == kBASE_SLOPE )
//		RestoreCursorsBE( sFolders, ch, rg, UFPE_kCSR_BASE, 0 )
//		OnePeakBase( sFolders, ch, rg, BegPt, SIFact, nCurSwpDummy )				// Do a Peak and Base determination immediately. 
//	elseif ( UFPE_BaseOp_( sFolders, ch, rg )  == kBASE_MANUAL )
//		RestoreCursorsBE( sFolders, ch, rg, UFPE_kCSR_BASE, 0 )
//		OnePeakBase( sFolders, ch, rg, BegPt, SIFact, nCurSwpDummy )				// Do a Peak and Base determination immediately. 
	else 																// UFPE_BaseOp_( sFolders, ch, rg ) == kBASE_MEAN  ||  UFPE_BaseOp_( sFolders, ch, rg )  == kBASE_DRIFT 
		RestoreCursorsBE_a( sFolders, ch, rg, UFPE_kCSR_BASE, 0, LatCnt_a(), FitCnt_a() )
		OnePeakBase_a( sFolders, ch, rg, BegPt, SIFact, nCurSwpDummy )				// Do a Peak and Base determination immediately. 
	endif
	UFPE_CursorSetValue( sFolders, ch, rg, UFPE_kCSR_BASE, 0, UFPE_CN_BEG,  BegPt, SIFact, Top, Bottom, LatCnt_a(), FitCnt_a() )
	UFPE_CursorSetValue( sFolders, ch, rg, UFPE_kCSR_BASE, 0, UFPE_CN_END,  BegPt, SIFact, Top, Bottom, LatCnt_a(), FitCnt_a()  )

End


Function		fPkDir_a( s )
	struct	WMPopupAction	&s
	string  	sFolders	= ReplaceString( "root:uf:", GetUserData( s.win,  s.ctrlName, "sFo" ), "" ) + s.win	// e.g.  'root:uf:acq:' -> 'acq:pul'
	string  	sFol_ders	= ReplaceString( ":", sFolders, "_" )

	variable	ch		= UFCom_TabIdx( s.ctrlName )
	variable	rg		= UFCom_BlkIdx( s.ctrlName )
	// printf "\t%s\t%s\tch:%d  \trg:%d  \t%s\t%g\t%s\t   \r",  UFCom_pd(sFolders,15), UFCom_pd(s.CtrlName,31), ch, rg, UFCom_pd( s.popStr,9), (s.popnum-1), sFolders
	UFCom_EnableSetVar(  s.win,  "root_uf_" + sFol_ders + "_svSideP" + num2str( ch )  + num2str( rg )  + "00", (s.popnum-1 == kPEAK_OFF  ?  UFCom_kCo_DISABLE_SV :  UFCom_kCo_ENABLE_SV) )  

	variable	BegPt = 0,	  SIFact = 1, nCurSwpDummy = -1 
	variable	Top = Inf, Bottom = -inf

	if ( UFPE_PeakDir( sFolders, ch, rg ) == kPEAK_OFF )
		UFPE_RemoveCursorsBE( sFolders, ch, rg, UFPE_kCSR_PEAK, 0, LatCnt_a() )
	else
		RestoreCursorsBE_a( sFolders, ch, rg, UFPE_kCSR_PEAK, 0, LatCnt_a(), FitCnt_a()  )
		OnePeakBase_a( sFolders, ch, rg, BegPt, SIFact, nCurSwpDummy )			// 2006-0120   Do a peak and base determination immediately.  Works both in  EVAL  and in  ACQ 
	endif
	UFPE_CursorSetValue( sFolders, ch, rg, UFPE_kCSR_PEAK, 0, UFPE_CN_BEG,  BegPt, SIFact, Top, Bottom, LatCnt_a(), FitCnt_a() )
	UFPE_CursorSetValue( sFolders, ch, rg, UFPE_kCSR_PEAK, 0, UFPE_CN_END,  BegPt, SIFact, Top, Bottom, LatCnt_a(), FitCnt_a() )
End

Function		fSidePts_a( s ) 
//  SetVariable action proc for the points around a peak over which the peak value is averaged. Single sided points are assumed ranging from 0 .. 20 so the true range is 1..41
	struct	WMSetvariableAction    &s
	string  	sFolders	= ReplaceString( "root:uf:", GetUserData( s.win,  s.ctrlName, "sFo" ), "" ) + s.win	// e.g.  'root:uf:acq:' -> 'acq:pul'
	variable	ch		= UFCom_TabIdx( s.ctrlName )
	variable	rg		= UFCom_BlkIdx( s.ctrlName )

	// printf "\t%s\t%s\tch:%2d\trg:%2d\tvar:%g\tEvCd:%d\tEvMod:%d\t%s\t \r",  UFCom_pd(sFolders,13), UFCom_pd(s.CtrlName,31), ch, rg, s.dval, s.eventcode, s.eventmod, sFolders

//	WON'T WORK IN  ACQ : can unfortunately not do a peak determination immediately  as  the  wave  wOrg   is not known in OLA and can at the moment not be determined simply ....
//	variable	BegPt = 0,	  SIFact = 1
//	if ( cmpstr( sFolders, ksF_ACQ_PUL ) )
//		variable 	nCurSwpDummy = -1 			// Eval code !
//		OnePeakBase_a( sFolders, ch, rg, BegPt, SIFact, nCurSwpDummy )							// Do determination of the corresponding  Peak  and Base  immediately.  
//	endif
End


Function		OnePeakBase_a( sFolders, ch, rg, BegPt, SIFact, nCurSwp )
// Do a Peak and a Base determination immediately e.g. when the uses has changed evaluation settings  e.g. the peak direction  or the base mode
// ???.......???........ Flaw : Gets any data sweep.  If the display mode is 'single'  this will be the current sweep.  If the display mode is 'stacked'  it can be any sweep, ...
	string  	sFolders
	variable	ch, rg, nCurSwp, BegPt, SIFact
	string  	sFoldOrgWvNm 
	string		sFolder		= StringFromList( 0, sFolders, ":" )

	// Elaborate case : each channel may appear in multiple windows and there it may appear in multiple traces (=Modes/Ranges) . It is not sufficient to display the peak marker only in the first of them as they may have different amplitude scales (however, they have all the same time scale)
	// Evaluate the true minimum and maximum peak value and location by removing the noise in a region around the given approximate peak location 
	EvaluateMultiplePeaksBases_a( sFolders, ch, rg, nCurSwp, BegPt, SIFact )	// construct and process window/trace  list 
End


Function   		EvaluateMultiplePeaksBases_a( sFolders, ch, rg, nCurSwp, BegPt, SIFact )
	string  	sFolders
	variable	ch, rg, nCurSwp, BegPt, SIFact
	string	  	sChan	= StringFromList( ch, LstChan_a(), UFCom_ksSEP_TAB )	// e.g.   'Adc1'
	variable	w, wCnt	= AcqWndCnt()
	for ( w = 0; w < wCnt; w += 1 )
		string  	sWNm	= WndNm( w )		
		string 	sTNL	= TraceNameList( sWNm, ";", 1 ) 
		sTNL	= ListMatch( sTNL, sChan + "*" )
		variable	t, tCnt	= ItemsInList( sTNL )	
		for ( t = 0; t < tCnt; t += 1 )
			string  	sTrace	= StringFromList( t, sTNL )
			wave  /Z	wOrg		= TraceNameToWaveRef( sWNm, sTrace )

			if ( WaveExists( wOrg ) )
// 2006-0120	  Error: 	ignores right Y scale (e.g. dac in 0_OLA1,txt
				UFPE_EvaluatePeak( sFolders, wOrg, ch, rg, nCurSwp, BegPt, SIFact ) 
				UFPE_EvaluateBase( sFolders, wOrg, ch, rg, nCurSwp, BegPt, SIFact ) 
				UFPE_ComputeBasePeakDependants( sFolders, wOrg, ch, rg, nCurSwp, BegPt, SIFact ) 
				// printf "\t\tFindAllAcqWnd( sFolders:'%s' \tch:%2d\trg:%2d ) \tw:%2d\t'%s'\tTrace:%2d/%2d\t%s\tWaveExists:%2d\tL:%.3g\tR:%.3g\tsTNL:'%s...'  \r", sFolders, ch, rg, w, sWNm, t, tCnt, UFCom_pd(sTrace,22), WaveExists( wOrg ), rLeft, rRight, sTNL[0,120 ]	
			else
				// printf "\t???FindAllAcqWnd( sFolders:'%s' \tch:%2d\trg:%2d ) \tw:%2d\t'%s'\tTrace:%2d/%2d\t%s\tWaveExists:%2d\tsTNL:'%s...'  \r", sFolders, ch, rg, w, sWNm, t, tCnt, UFCom_pd(sTrace,22), WaveExists( wOrg ), sTNL[0,120 ]	
			endif
		endfor
	endfor
End


//===================================================================================================================

static Function	FindAndMoveClosestCursor_a( sFolders, sWnd, ch, ct, nc, nCsr , sWvNm )
	string  	sFolders, sWnd, sWvNm
	variable	ch, ct, nc, nCsr

	UFPE_QuitCursorPositioning(   sFolders, sWnd, UFPE_kCURSOR_SAVE, LatCnt_a(), FitCnt_a() )			// End the mode in which Igor moves Base/Peak/Latency cursors  and  save the last cursor

	DoWindow  /F   $sWnd							// To allow cursor movement we must bring the eva window to front and make it the active window. This is needed only if the user clicked into the panel for the command, not if he pressed a key.  

	 printf "\tFindAndMoveClosestCursor_a(\t\t\t\t\tch:%d \t\t\t %s\t%d\tCursor%2d %s ):\t%s\t \r", ch, UFCom_pd( UFCom_RemoveWhiteSpace( StringFromList( ct, UFPE_kCSR_NAME ) ), 8 ), nc, nCsr, SelectString( nCsr, "A", "B" ), sWvNm
	variable	rg 			= FindClosestRegion( sFolders, ch, ct, nc, nCsr )
	MoveCursor_a( sFolders, sWnd, ch, rg, ct, nc, nCsr, sWvNm )
End

static Function	FindClosestRegion( sFolders, ch, ct, nc,  nCsr )
// If there is more than 1 region in the actice graph/channel then select the one which is closest to the cursor
	string  	sFolders
	variable	ch, ct, nc, nCsr
	wave	wCurRegion	= $"root:uf:" + sFolders + ":wCurRegion"
	variable	xAxVal		= wCurRegion[ UFPE_kXMOUSE ]
	variable	xPhCsr
	variable	rg, ClosestRegion = 0, ClosestDistance = Inf
	variable	rgCnt		= UFPE_RegionCnt( sFolders, ch )
	variable	ph		= UFPE_Csr2Ph(  sFolders, ct, nc, LatCnt_a() )
	for ( rg = 0; rg < rgCnt; rg += 1 )
		xPhCsr	= UFPE_CursorX( sFolders, ch, rg, ph, UFPE_CN_BEG   + nCsr )
		if ( abs( xPhCsr - xAxVal ) < ClosestDistance )
			ClosestDistance = abs( xPhCsr - xAxVal )
			ClosestRegion	= rg
			// printf "\t\t\t\tFindClosestRegion( ch:%d , ph:%d \t( %s )\t, nCsr:%d \t( %s )\t ) \tXCsr:\t%7.3lf \tXReg:\t%7.3lf \tXDelta:\t%7.3lf\t \r", ch, ph, RemoveWhiteSpace( StringFromList( ct, UFPE_kCSR_NAME ) ), nCsr, StringFromList( nCsr, UFPE_ksLR_CSR), xAxVal, xPhCsr, ClosestDistance 
		endif
	endfor
	// printf "\t\t\t\tFindClosestRegion( ch:%d , ph:%d \t( %s )\t, nCsr:%d \t( %s )\t ) returns closest region %d. (rgCnt:%d) \r", ch, ph, RemoveWhiteSpace( StringFromList( ct, UFPE_kCSR_NAME ) ), nCsr, StringFromList( nCsr, UFPE_ksLR_CSR), ClosestRegion, rgCnt	
	return	ClosestRegion
End
	

static Function	MoveCursor_a( sFolders, sWndNm, ch, rg, ct, nc, nCsr, sWvNm )
	string  	sFolders, sWndNm, sWvNm
	variable	ch, rg, ct, nc, nCsr
	variable	ph			= UFPE_Csr2Ph(  sFolders, ct, nc, LatCnt_a() )
	variable	xPhCsr		= UFPE_CursorX( sFolders, ch, rg, ph, UFPE_CN_BEG   + nCsr )
	variable	rRed, rGreen, rBlue
	UFPE_EvalColor_( sFolders, ct, nc, rRed, rGreen, rBlue )
	wave	wPrevRegion	= $"root:uf:" + sFolders + ":wPrevRegion"
	wPrevRegion[ UFPE_kCH ]		= ch								// save until 'UFPE_QuitCursorPositioning()'
	wPrevRegion[ UFPE_kRG ]		= rg								// save until 'UFPE_QuitCursorPositioning()'
	wPrevRegion[ UFPE_kCT ]		= ct								// ...
	wPrevRegion[ UFPE_kNC ]		= nc								// ...
	wPrevRegion[ UFPE_kCURSOR ]	= nCsr 							// ...
	 printf "\tMoveCursor_a( \t\t\t\t\t\t\t\tch:%d   \trg:%d   \t %s\t%d\tCursor%2d %s   \tWvNm:'%s'\tWnd:'%s'\txPhCsr:%g \r", ch, rg, UFCom_pd( UFCom_RemoveWhiteSpace( StringFromList( ct, UFPE_kCSR_NAME ) ), 8), nc, nCsr, SelectString( nCsr, "A", "B" ), sWvNm, sWndNm, xPhCsr
	string  	sCursorAorB	= SelectString( nCsr, "A", "B" )
	ShowInfo	/W= $sWndNm  								// Display Igors cursor control box. This is not mandatory for cursor usage.
	if ( strlen( sWvNm ) )										// 2005-1219  onyl in EVAL we know the name of the wave
		Cursor	/W = $sWndNm /A=1 /H=1 /S=1 /L=0  /C=(rRed, rGreen, rBlue)  $sCursorAorB, $sWvNm, xPhCsr		// draw the 'locked-to-wave' crosshair cursor
	else
		GetAxis	/W = $sWndNm  left
		variable   yVal  = ( V_min + V_max ) / 2
		Cursor  /F	/W = $sWndNm /A=1 /H=1 /S=1 /L=0  /C=(rRed, rGreen, rBlue)  $sCursorAorB, $sWvNm, xPhCsr	, yVal// draw the 'roam-free' crosshair cursor which locks to any (=the nearest) trace
	endif
	// Now we are in  Igors 'Cursor' mode.  Igor allows moving its cursor with the mouse or with the arrow keys
	// It is our responsability to quit the 'Cursor' mode,  e.g. by  pressing  CR/Enter, by pressing ESC  or by releasing (or clicking) the mouse  
End

//=================================================================================================

// UNUSED...

Function		fLat0CsrM_a( s )
// Toggle button with 2 states : Set and display the single cursor  or   hide the single cursor. On the next button press the previous value will still be restored (although the cursor value has temporarily been set to Nan)
	struct  	WMButtonAction	&s		
	string  	sFolders	= ReplaceString( "root:uf:", GetUserData( s.win,  s.ctrlName, "sFo" ), "" ) + s.win	// e.g.  'root:uf:acq:' -> 'acq:pul'
	fCsr_a( sFolders, s.CtrlName,  UFPE_kCSR_LAT, 0, UFPE_kLEFT_CSR ) 	
End
Function		fLat1CsrM_a( s )
// Toggle button with 2 states : Set and display the single cursor  or   hide the single cursor. On the next button press the previous value will still be restored (although the cursor value has temporarily been set to Nan)
	struct  	WMButtonAction	&s		
	string  	sFolders	= ReplaceString( "root:uf:", GetUserData( s.win,  s.ctrlName, "sFo" ), "" ) + s.win	// e.g.  'root:uf:acq:' -> 'acq:pul'
	fCsr_a( sFolders, s.CtrlName,  UFPE_kCSR_LAT, 1, UFPE_kLEFT_CSR ) 	
End
Function		fLat2CsrM_a( s )
// Toggle button with 2 states : Set and display the single cursor  or   hide the single cursor. On the next button press the previous value will still be restored (although the cursor value has temporarily been set to Nan)
	struct  	WMButtonAction	&s		
	string  	sFolders	= ReplaceString( "root:uf:", GetUserData( s.win,  s.ctrlName, "sFo" ), "" ) + s.win	// e.g.  'root:uf:acq:' -> 'acq:pul'
	fCsr_a( sFolders, s.CtrlName,  UFPE_kCSR_LAT, 2, UFPE_kLEFT_CSR ) 	
End

//=================================================================================================

Function		fCsr_a( sFolders, sCtrlName, ct, nc, nCsr )
	string		sFolders, sCtrlName
	variable	ct, nc, nCsr
	string  	sWvNm, sWnd
	variable	ch		= UFCom_TabIdx( sCtrlName )
	variable	rg		= UFCom_BlkIdx( sCtrlName )
	string  	sBuVarNm	= ReplaceString( "_", sCtrlName, ":" )					// the underlying button variable name is derived from the control name
	string  	sWin		= StringFromList( 1, sFolders,  ":" )					// the panel window is derived from the control name  e.g. 'eva:de'  ->  'de'
	nvar		state		= $sBuVarNm
	// SAMPLE CODE (normally not required) for colorising a button the special way:
	// This additional code is required in each button action proc only if you want any sophisticated formating not possible with the much simpler title and format lists in the panel definition (e.g. 'buFiltAppl' or 'gbCursrCut' )
	variable	rRed, rGreen, rBlue
	UFPE_EvalColorDark_( sFolders, ct, nc, rRed, rGreen, rBlue )						// possible improvement: keep the color but supply a darker shade for the button background

	// UFPE_EvalColor( sFolders, ct, nc, rRed, rGreen, rBlue )						// possible improvement: keep the color but supply a darker shade for the button background
	if ( state == 0 )
		Button 	$sCtrlName, win = $sWin, fstyle=0					// normal 
		Button 	$sCtrlName, win = $sWin,  fcolor = (0,0,0)				// black
	else
		Button 	$sCtrlName, win = $sWin, fstyle=1					// bold  
		Button 	$sCtrlName, win = $sWin, fcolor = (rRed, rGreen, rBlue)		// colored 
	endif
	 printf "\tfCsr()\t%s\tch:%d  rg:%d\tct:%d nc:%d\t %s\thas value:%2d  rgb:(%5d,%5d,%5d) \r",  sFolders, ch, rg, ct, nc, sBuVarNm, state, rRed, rGreen, rBlue

	sWvNm	= "" 
	sWnd	= FindFirstWnd_a( ch )									// possibly find and process window list 
	FindAndMoveClosestCursor_a( sFolders, sWnd, ch, ct, nc, nCsr, sWvNm )	// Highlight  the cursor and allow moving it
End



Function		fBaseBegCsrM_a( s )
	struct  	WMButtonAction	&s								// 2005-1116  called by  pressing a Mouse button in the panel
	string  	sFolders	= ReplaceString( "root:uf:", GetUserData( s.win,  s.ctrlName, "sFo" ), "" ) + s.win	// e.g.  'root:uf:acq:' -> 'acq:pul'
	printf "\t\t'%s'\t%s  %s \t'%s' %2d \r", s.CtrlName, sFolders, s.win,   StringFromList( s.eventCode, UFCom_CCE_lstEVENTCODES ), s.eventCode
	fCsr_a( sFolders, s.CtrlName, UFPE_kCSR_BASE, 0, UFPE_kLEFT_CSR )
End

Function		fBaseEndCsrM_a( s )
	struct  	WMButtonAction	&s							// 2005-1116  called by  pressing a Mouse button in the panel
	string  	sFolders	= ReplaceString( "root:uf:", GetUserData( s.win,  s.ctrlName, "sFo" ), "" ) + s.win	// e.g.  'root:uf:acq:' -> 'acq:pul'
	printf "\t\t'%s'\t%s  %s \t'%s' %2d \r", s.CtrlName, sFolders, s.win,   StringFromList( s.eventCode, UFCom_CCE_lstEVENTCODES ), s.eventCode
	fCsr_a( sFolders, s.CtrlName, UFPE_kCSR_BASE, 0, UFPE_kRIGHT_CSR )
End


Function		fPeakBegCsrM_a( s )
	struct  	WMButtonAction	&s							// 2005-1116  called by  pressing a Mouse button in the panel
	string  	sFolders	= ReplaceString( "root:uf:", GetUserData( s.win,  s.ctrlName, "sFo" ), "" ) + s.win	// e.g.  'root:uf:acq:' -> 'acq:pul'
	fCsr_a( sFolders, s.CtrlName, UFPE_kCSR_PEAK, 0, UFPE_kLEFT_CSR )
End

Function		fPeakEndCsrM_a( s )
	struct  	WMButtonAction	&s							
	string  	sFolders	= ReplaceString( "root:uf:", GetUserData( s.win,  s.ctrlName, "sFo" ), "" ) + s.win	// e.g.  'root:uf:acq:' -> 'acq:pul'
	fCsr_a( sFolders, s.CtrlName, UFPE_kCSR_PEAK, 0, UFPE_kRIGHT_CSR )
End

//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function		LatCnt_a( ) 
	return	2							// !!!  adjust if we have more or less latencies   as  offered  in the  ACQ Main panel
End


Function		fLat0B_a( s )
	struct	WMPopupAction	&s
	string  	sFolders	= ReplaceString( "root:uf:", GetUserData( s.win,  s.ctrlName, "sFo" ), "" ) + s.win	// e.g.  'root:uf:acq:' -> 'acq:pul'
	fLatCsr_a( sFolders, s.CtrlName, 0, UFPE_CN_BEG )
End

Function		fLat0E_a( s )
	struct	WMPopupAction	&s
	string  	sFolders	= ReplaceString( "root:uf:", GetUserData( s.win,  s.ctrlName, "sFo" ), "" ) + s.win	// e.g.  'root:uf:acq:' -> 'acq:pul'
	fLatCsr_a( sFolders, s.CtrlName, 0, UFPE_CN_END )
End

Function		fLat1B_a( s )
	struct	WMPopupAction	&s
	string  	sFolders	= ReplaceString( "root:uf:", GetUserData( s.win,  s.ctrlName, "sFo" ), "" ) + s.win	// e.g.  'root:uf:acq:' -> 'acq:pul'
	fLatCsr_a( sFolders, s.CtrlName, 1, UFPE_CN_BEG )
End

Function		fLat1E_a( s )
	struct	WMPopupAction	&s
	string  	sFolders	= ReplaceString( "root:uf:", GetUserData( s.win,  s.ctrlName, "sFo" ), "" ) + s.win	// e.g.  'root:uf:acq:' -> 'acq:pul'
	fLatCsr_a( sFolders, s.CtrlName, 1, UFPE_CN_END )
End

Function		fLat2B_a( s )
	struct	WMPopupAction	&s
	string  	sFolders	= ReplaceString( "root:uf:", GetUserData( s.win,  s.ctrlName, "sFo" ), "" ) + s.win	// e.g.  'root:uf:acq:' -> 'acq:pul'
	fLatCsr_a( sFolders, s.CtrlName, 2, UFPE_CN_BEG )
End

Function		fLat2E_a( s )
	struct	WMPopupAction	&s
	string  	sFolders	= ReplaceString( "root:uf:", GetUserData( s.win,  s.ctrlName, "sFo" ), "" ) + s.win	// e.g.  'root:uf:acq:' -> 'acq:pul'
	fLatCsr_a( sFolders, s.CtrlName, 2, UFPE_CN_END )
End

Function		fLatCsr_a( sFolders, sCtrlName, latcsr, BegEnd )
	string 	sFolders, sCtrlName
	variable	latcsr, BegEnd 
	variable	nChans
	variable	ch		= UFCom_TabIdx( sCtrlName )
	variable	rg		= UFCom_BlkIdx( sCtrlName )
	variable	LatCnt	= LatCnt_a()
	string  	sWnd	= ""
	// TurnRemainingLatenciesOff( sCtrlName, latcsr, BegEnd, ch, rg )	// Two advantages but not yet working): 1. Prevent that the user accidentally redefines this latency in another channel or region.  2. Tidy up the panel. 
	
// will work only in final merge when  UF_OnlineA.ipf  is included in EVAL 
	nChans	= ItemsInList( LstChan_a(), UFCom_ksSEP_TAB )
	UFPE_AllLatenciesCheck( sFolders, nChans, LatCnt )						//...BUT does not work as all hidden popmenus are restored whenever tabs are clicked. -> must recognise hidden state then
	// UFPE_DisplayCursor_Lat( sFolders, ch, rg, latcsr, BegEnd )
	LBResSelUpdateOA()									// update the 'Select results' panel whose contents may have changed

	 printf "\t%s\t%s\tch:%d/%2d  \trg:%d  latcsr:%d/%2d  BegEnd:%d \t  \r",  UFCom_pd( sCtrlName,31), UFCom_pd( sFolders, 9), ch, nChans, rg, latcsr, LatCnt, BegEnd
End

//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// 2006-0428
Function		fFitBegCsrM_a( s )
	struct  	WMButtonAction	&s							
	string  	sFolders	= ReplaceString( "root:uf:", GetUserData( s.win,  s.ctrlName, "sFo" ), "" ) + s.win	// e.g.  'root:uf:eva:' -> 'eva:de'  
	variable	ch		= UFCom_TabIdx( s.CtrlName )
	variable	rg		= UFCom_BlkIdx(   s.CtrlName )
	variable	fi		= UFCom_RowIdx( s.CtrlName )
	fCsr_a( sFolders, s.CtrlName, UFPE_kCSR_FIT, fi, UFPE_kLEFT_CSR )
	variable	bOnOff	= UFPE_DoFit( sFolders, ch, rg, fi, LatCnt_a() )
	DoOneFit_a( sFolders, ch, rg,  UFPE_kCSR_FIT, fi, s.CtrlName,  bOnOff )
End


Function		fFitEndCsrM_a( s )
	struct  	WMButtonAction	&s							
	string  	sFolders	= ReplaceString( "root:uf:", GetUserData( s.win,  s.ctrlName, "sFo" ), "" ) + s.win	// e.g.  'root:uf:acq:' -> 'acq:pul'
	variable	ch		= UFCom_TabIdx( s.CtrlName )
	variable	rg		= UFCom_BlkIdx(   s.CtrlName )
	variable	fi		= UFCom_RowIdx( s.CtrlName )
	fCsr_a( sFolders, s.CtrlName, UFPE_kCSR_FIT, fi, UFPE_kRIGHT_CSR )
	variable	bOnOff	= UFPE_DoFit( sFolders, ch, rg, fi, LatCnt_a() )
	DoOneFit_a( sFolders, ch, rg,  UFPE_kCSR_FIT, fi, s.CtrlName,  bOnOff )
End


Function		FitCnt_a()
	string  	sFolders 
	return	2					// 3 for testing
End


Function	/S	fFitInSt_a( sBaseNm, sF, sWin )
// Initial state of the  'Fit' checkboxes.   Implemented as function as this same state must also be used for the initial visibility of the dependent  'FitFunc'  and  'FitRange' controls
// Syntax: tab blk row col 1-based-index;  (Tab0: Window,Peak  Tab2: Window,Cursor,  Tab3...: Window (=default)
//	return  "0010_1;0100_1;~0"	// Test init: Tab~ch~0, blk~reg~0, row~fit1~1 will be ON=1 ;  Tab~ch~0, blk~reg~1, row~fit0~0 will be ON=1 ;  all others will be off = 0 
//	return  "0000_1;~0"			// Test init: Tab~ch~0, blk~reg~0, row~fit0~0 will be ON=1 ;  all others will be off = 0 
	string  	sBaseNm, sF, sWin 
	string  	sFolders	= ReplaceString( "root:uf:", sF, "" ) + sWin 	  	// e.g.  'root:uf:acq:' + 'pul'  -> 'acq:pul'
	
	return  "0000_1;~0"			// Test init: Tab~ch~0, blk~reg~0, row~fit0~0 will be ON=1 ;  all others will be off = 0 
End


Function	/S	fFitRowDums_a( sBaseNm, sF, sWin )
// Supplies as many separators as there are titles in the controlling 'Fit' checkbox. They are needed for  'RowCnt()'  to preserve panel geometry, otherwise 'Fit' checkbox and 'FitFunc'/'FitRng' controls will appear in different lines. 
	string  	sBaseNm, sF, sWin 
	variable	fi, nFits	= FitCnt_a() 
	string  	lstTitles	= ""
	for ( fi = 0; fi <  nFits; fi += 1 )
		lstTitles	+= UFCom_ksSEP_STD  					// e.g.   ','
	endfor 
	// printf "\t\t\tfFitRowTitles() / fFitRowDums_a :'%s' \r", lstTitles
	return	lstTitles
End


Function	/S	fFitBegTitles_a( sBaseNm, sF, sWin )
	string  	sBaseNm, sF, sWin 
	variable	fi, nFits	= FitCnt_a() 
	string  	lstTitles	= ""
	for ( fi = 0; fi <  nFits; fi += 1 )
		//lstTitles	+=  "[fit" + num2str( fi ) + "off" + UFCom_ksSEP_TILDE + "[fit"	+ num2str( fi ) + "on" + UFCom_ksSEP_TILDE + UFCom_ksSEP_STD	//   e.g.   '[fit0off, [fit0on, [fit1off, [fit1on, ..'
		lstTitles	+=  "[fit" + num2str( fi ) + "+" + UFCom_ksSEP_TILDE + "[fit" 	+ num2str( fi ) + "-" + UFCom_ksSEP_TILDE + UFCom_ksSEP_STD	//   e.g.   '[fit0+, [fit0-, [fit1+, [fit1-, ..'
	endfor 
	// printf "\t\t\tfFitBegTitles_a( '%s'  '%s'  '%s' ) / fFitRowDums_a() :'%s' \r", sBaseNm, sF, sWin , lstTitles
	return	lstTitles
End

Function	/S	fFitEndTitles_a( sBaseNm, sF, sWin )
	string  	sBaseNm, sF, sWin 
	variable	fi, nFits	= FitCnt_a() 
	string  	lstTitles	= ""
	for ( fi = 0; fi <  nFits; fi += 1 )
		//lstTitles	+=  "fit" + num2str( fi ) + "off]" + UFCom_ksSEP_TILDE + "fit" +	num2str( fi ) + "on]" + UFCom_ksSEP_TILDE + UFCom_ksSEP_STD	//   e.g.   'fit0off],  fit0on],  fit1off],  fit1on], ..'
		lstTitles	+=  "fit" + num2str( fi ) + "+]" + UFCom_ksSEP_TILDE + "fit" + 	num2str( fi ) + "-]" + UFCom_ksSEP_TILDE + UFCom_ksSEP_STD	//   e.g.   'fit0+],  fit0-],  fit1+],  fit1-], ..'
	endfor 
	// printf "\t\t\tfFitEndTitles_a( '%s'  '%s'  '%s' ) / fFitRowDums_a() :'%s' \r", sBaseNm, sF, sWin , lstTitles
	return	lstTitles
End


static Function		DoOneFit_a( sFolders,  ch, rg,  nc, fi, sCtrlName,  bOnOff )
	string  	sFolders,  sCtrlName
	variable	ch, rg,  nc, fi, bOnOff
	
	// Depending on the state of the  'Fit'  checkbox, enable or disable the depending controls
	UFPE_TurnDependingControlOnOff_( sFolders, sCtrlName, "pmFiFnc", bOnOff )			// Depending on the state of the  'Fit'  checkbox, enable or disable the depending control  'FitFnc'  (which is in the same line)
	UFPE_TurnDependingControlOnOff_( sFolders, sCtrlName, "pmFiRng", bOnOff )			// Depending on the state of the  'Fit'  checkbox, enable or disable the depending control  'FitRng'  (which is in the same line)

	string		sWnd
	string  	lstFitResults = ""
	variable	BegPt = 0,	  SIFact = 1
	string		sFoldOrgWvNm	= ""

	// Do a fit immediately. 
// 2006-0324    bad and ugly code for multiple reasons: 1. arbitrary trace selection   2. arbitrary FindFirstWnd_a()  3. the AxisRangeX  is taken from the wave scaling deltaX / numPnts of  wv  e.g. 'Adc1FC_'   (it might be better to extract it from 'root:uf:acq:pul:io:Adc1' )
	string sSrc, sTNL, sFirstTrace
	sWnd		= FindFirstWnd_a( ch )
	sSrc			= StringFromList( ch, LstChan_a(), UFCom_ksSEP_TAB )
	sTNL		= TraceNameList( sWnd, ";", 1 )					// e.g.  'wcY_r0_p1_n0;wcY_r0_p1_n1;wcY_r0_p5_n0;Adc1FC_;wcY_r0_p5_n1;Adc1PM_;'
	sTNL		= ListMatch( sTNL, sSrc + "*" )					// e.g.  'Adc1FC_;Adc1PM_;'
	sFirstTrace	= StringFromList( 0, sTNL )						// !!! arbitrary / restriction :  could also use any other trace in this window
	wave  /Z	wOrg	= TraceNameToWaveRef( sWnd, sFirstTrace )
	sFoldOrgWvNm	= NameOfWave( wOrg )						// = UFCom_ksROOT_UF_ + ksACQ_ + UFPE_ksF_IO_ + StringFromList( ch, LstChan_a(), UFCom_ksSEP_TAB )	// in ACQ : Folders + sSource   e.g.  'root:uf:acq:pul:io:Adc1'
	 printf "\t\tDoOneFit_a  \tch:%d   rg: 0..%d  \tfi:%d  \twave:\t%s\t%s\t1.tr\t%s\thas  deltax: %g  leftX: %g  numPnts: %g \tsTNL: '%s...' \r", ch, rg-1, fi, UFCom_pd(sFoldOrgWvNm,14), UFCom_pd(sWnd,5), UFCom_pd(sFirstTrace,14), deltaX( wOrg ), leftX( wOrg ), numpnts( wOrg ), sTNL[ 0, 100]

	if ( waveExists( wOrg ) )										// exists only after the user has clicked into the data sections listbox to view, analyse or average a data section
		 UFPE_OneFit( sFolders, sWnd, wOrg, ch, rg, fi, BegPt, SIFact, lstFitResults, LatCnt_a(), FitCnt_a() )		// will fit only if  'Fit' checkbox is 'ON'
	endif

	LBResSelUpdateOA()											// Rebuild the listbox completely as in meantime while the listbox perhaps was invisible e.g the number of channels may have changed
End


// 2007-0226 seems to be unused....
//Function		fFit_a( s )
//// Checkbox action proc....
//	struct	WMCheckboxAction	&s
//	string  	sFo	 	= GetUserData( 	s.win,  s.ctrlName,  "sFo" )				// e.g.  'root:uf:eva:' 
//	string  	sFolders	= RemoveEnding( ReplaceString( "root:uf:", sFo, "" ), ":" )  	// e.g.  'root:uf:eva:de:' -> 'eva:de'
//	variable	bOnOff	= s.checked
//	variable	LatCnt	= LatCnt_a()
//	variable	FitCnt	= FitCnt_a()
//
//	// Depending on the state of the  'Fit'  checkbox, enable or disable the depending controls
//	UFPE_TurnDependingControlOnOff( s.Win, s.CtrlName, "pmFiFnc", bOnOff )			// Depending on the state of the  'Fit'  checkbox, enable or disable the depending control  'FitFnc'  (which is in the same line)
//	UFPE_TurnDependingControlOnOff( s.Win, s.CtrlName, "pmFiRng", bOnOff )			// Depending on the state of the  'Fit'  checkbox, enable or disable the depending control  'FitRng'  (which is in the same line)
//
//	// Turn the fit cursors on and off
//	variable	ch		= UFCom_TabIdx( s.ctrlName )
//	variable	rg		= UFCom_BlkIdx( s.ctrlName )
//	variable	fi		= UFCom_RowIdx( s.ctrlName )
//	string  	sWnd	= FindFirstWnd_a( ch )
//	string  	lstFitResults = ""
//	variable	Top 		= Inf, Bottom = -inf
//	variable	BegPt 	= 0,	  SIFact = 1
//	
//	// Display or hide the cursor pair immediately
//	if ( ! UFPE_CursorsAreSetBE( sFolders, ch, rg, UFPE_kCSR_FIT, fi, LatCnt ) )
//		variable	AxisRangeX = 0, TimeLeftX = 0,  nPnts = 0, delta = 0
//		if ( GetWaveParamForCursors_a( sFolders, ch, AxisRangeX, TimeLeftX, nPnts, delta ) != UFCom_kNOTFOUND )
//			 printf "\t\t\tSpreadCursors a  ch:%d   rg: %d  \tfi:%d  \t\thas  deltax: %g  leftX: %g  numPnts: %g \t \r", ch, rg, fi,   delta, TimeLeftX, nPnts
//			UFPE_SpreadCursorsBE( sFolders, ch, rg, UFPE_kCSR_FIT, fi , AxisRangeX, TimeLeftX, LatCnt, FitCnt ) 		// 2006-0328 spread cursors evenly
//			UFPE_CursorSetValue(    sFolders, ch, rg, UFPE_kCSR_FIT, fi, UFPE_CN_BEG, BegPt, SIFact, Top, Bottom, LatCnt, FitCnt )
//			UFPE_CursorSetValue(    sFolders, ch, rg, UFPE_kCSR_FIT, fi, UFPE_CN_END, BegPt, SIFact, Top, Bottom, LatCnt, FitCnt )
////ltl			 printf "\t\te \tch:%d  rg:0..%d\tct:%d fi:%d\t has  deltax: %g   TimeLeftX: %g     X axis range: %g : (%g..%g)    -->  UFPE_CursorX() = %8.3lf  [XCOs:%g , XAXL:%g] \r",  
////ch, rg-1, UFPE_kCSR_FIT, fi, delta, TimeLeftX,  AxisRangeX,  TimeLeftX,  TimeLeftX + AxisRangeX, CursorX(sFolders,ch,rg,UFPE_Csr2Ph( sFolders,UFPE_kCSR_FIT,fi, LatCnt ),UFPE_CN_BEG), UFPE_XCursrOs( sFolders, ch ), UFPE_XaxisLft( sFolders, ch )
//		else
//			 printf "\t%s\tf  \tch:%d   wave does not exist.\r",  UFCom_pd(s.ctrlName,25), ch
//		endif
//	endif
//	
//	  printf "\t\t%s\tch:%d\trg:%d\tct:%d\tnc=fi:%d\t on:%d\tbVis:%d\t  \r",  UFCom_pd(s.CtrlName,25), ch, rg, UFPE_kCSR_FIT, fi, s.checked, s.checked
//	UFPE_DisplayHideCursors( sFolders, sWnd, ch, rg, UFPE_kCSR_FIT, fi, s.checked, LatCnt )
//
//	// Do a fit immediately. 
//// 2006-0324    bad and ugly code for multiple reasons: 1. arbitrary trace selection   2. arbitrary FindFirstWnd_a()  3. the AxisRangeX  is taken from the wave scaling deltaX / numPnts of  wv  e.g. 'Adc1FC_'   (it might be better to extract it from 'root:uf:acq:pul:io:Adc1' )
//	string sSrc, sTNL, sFirstTrace, sFoldOrgWvNm
//	//sWnd		= FindFirstWnd_a( ch )
//	sSrc			= StringFromList( ch, LstChan_a(), UFCom_ksSEP_TAB )
//	sTNL		= TraceNameList( sWnd, ";", 1 )					// e.g.  'wcY_r0_p1_n0;wcY_r0_p1_n1;wcY_r0_p5_n0;Adc1FC_;wcY_r0_p5_n1;Adc1PM_;'
//	sTNL		= ListMatch( sTNL, sSrc + "*" )					// e.g.  'Adc1FC_;Adc1PM_;'
//	sFirstTrace	= StringFromList( 0, sTNL )						// !!! arbitrary / restriction :  could also use any other trace in this window
//	wave  /Z	wOrg	= TraceNameToWaveRef( sWnd, sFirstTrace )
//	sFoldOrgWvNm	= NameOfWave( wOrg )						// = UFCom_ksROOT_UF_ + ksACQ_ + UFPE_ksF_IO_ + StringFromList( ch, LstChan_a(), ksSEP_TAB )	// in ACQ : Folders + sSource   e.g.  'root:uf:acq:pul:io:Adc1'
//	// printf "\t\td  \tch:%d   rg: 0..%d  \tfi:%d  \twave:\t%s\t%s\t1.tr\t%s\thas  deltax: %g  leftX: %g  numPnts: %g \tsTNL: '%s...' \r", ch, rg-1, fi, UFCom_pd(sFoldOrgWvNm,14), UFCom_pd(sWnd,5), UFCom_pd(sFirstTrace,14), deltaX( wOrg ), leftX( wOrg ), numpnts( wOrg ), sTNL[ 0, 100]
//
//	if ( waveExists( wOrg ) )										// exists only after the user has clicked into the data sections listbox to view, analyse or average a data section
//		 UFPE_OneFit( sFolders, sWnd, wOrg, ch, rg, fi, BegPt, SIFact, lstFitResults, LatCnt, FitCnt )		// will fit only if  'Fit' checkbox is 'ON'
//	endif
//
//	LBResSelUpdateOA()											// Rebuild the listbox completely as in meantime while the listbox perhaps was invisible e.g the number of channels may have changed
//End

static	 Function		GetWaveParamForCursors_a( sFolders, ch, AxisRangeX, TimeLeftX, nPnts, delta )
	string  	sFolders												// e.g.  'eva:de'  or  'acq:pul'
	variable	ch 
	variable	&AxisRangeX, &TimeLeftX, &nPnts, &delta
	variable	rg, ph
	string  	sFoldOrgWvNm
	string  	sWnd = "", sSrc = "", sTNL = "", sFirstTrace = ""
	
	// 2006-0324    bad and ugly code for multiple reasons: 1. arbitrary trace selection   2. arbitrary FindFirstWnd_a()  3. the AxisRangeX  is taken from the wave scaling deltaX / numPnts of  wv  e.g. 'Adc1FC_'   (it might be better to extract it from 'root:uf:acq:pul:io:Adc1' )
	sWnd		= FindFirstWnd_a( ch )
	sSrc			= StringFromList( ch, LstChan_a(), UFCom_ksSEP_TAB )
	sTNL		= TraceNameList( sWnd, ";", 1 )					// e.g.  'wcY_r0_p1_n0;wcY_r0_p1_n1;wcY_r0_p5_n0;Adc1FC_;wcY_r0_p5_n1;Adc1PM_;'
	sTNL		= ListMatch( sTNL, sSrc + "*" )					// e.g.  'Adc1FC_;Adc1PM_;'
	sFirstTrace	= StringFromList( 0, sTNL )						// !!! arbitrary / restriction :  could also use any other trace in this window
	wave  /Z	wv	= TraceNameToWaveRef( sWnd, sFirstTrace )
	sFoldOrgWvNm	= NameOfWave( wv )							
	//sFoldOrgWvNm = UFCom_ksROOT_UF_ + ksACQ_ + UFPE_ksF_IO_ + StringFromList( ch, LstChan_a(), UFCom_ksSEP_TAB )	// in ACQ : Folders + sSource   e.g.  'root:uf:acq:pul:io:Adc1'
	// printf "\t\t\tGetWaveParamForCursors_a  ch:%d   rg: 0..%d  \tph: 0..%d  \twave:\t%s\t%s\t%s\thas  deltax: %g  leftX: %g  numPnts: %g \tsTNL: '%s...' \r", ch, rg-1, ph-1, UFCom_pd(sFoldOrgWvNm,14), UFCom_pd(sWnd,5), UFCom_pd(sFirstTrace,14), deltaX( wv ), leftX( wv ), numpnts( wv ), sTNL[ 0, 100]

	if ( waveExists( wv ) )
		nPnts		 = numPnts( wv ) 
		delta			 = deltaX( wv )
		AxisRangeX	 = numPnts( wv ) * deltaX( wv )
		TimeLeftX		 = leftX( wv )
		return	0
	else
		return 	UFCom_kNOTFOUND
	endif
End


Function		fFitFnc_a( s )
// Action proc of the fit function popupmenu
	struct	WMPopupAction	&s
	string  	sFolders	= ReplaceString( "root:uf:", GetUserData( s.win,  s.ctrlName, "sFo" ), "" ) + s.win	// e.g.  'root:uf:acq:' -> 'acq:pul'
	variable	ch		= UFCom_TabIdx( s.ctrlName )
	variable	rg		= UFCom_BlkIdx( s.ctrlName )
	variable	fi		= UFCom_RowIdx( s.ctrlName )
	variable	nFitFunc	= s.popnum - 1							// the popnumber is 1-based
	// printf "\t%s\t%s\tch:%d \trg:%d \tfi:%d \tnFitFnc:%d = '%s'\t \r",  UFCom_pd(sFolders,15), UFCom_pd(s.CtrlName,25), ch, rg, fi, nFitFunc,  UFPE_FitFuncNm( nFitFunc )

	string  	lstFitResults		= ""
	variable	BegPt = 0,	  SIFact = 1
	variable	LatCnt	= LatCnt_a()
	variable	ph		= UFPE_Csr2Ph(  sFolders, UFPE_kCSR_FIT, fi, LatCnt )

	// Do a fit immediately.
	variable	bFit	= UFPE_DoFit( sFolders, ch, rg, fi, LatCnt )
	if ( bFit )
// 2006-0324    bad and ugly code for multiple reasons: 1. arbitrary trace selection   2. arbitrary FindFirstWnd_a()  3. the AxisRangeX  is taken from the wave scaling deltaX / numPnts of  wv  e.g. 'Adc1FC_'   (it might be better to extract it from 'root:uf:acq:pul:io:Adc1' )
		string sWnd	= FindFirstWnd_a( ch )
		string sSrc		= StringFromList( ch, LstChan_a(), UFCom_ksSEP_TAB )
		string sTNL	= TraceNameList( sWnd, ";", 1 )					// e.g.  'wcY_r0_p1_n0;wcY_r0_p1_n1;wcY_r0_p5_n0;Adc1FC_;wcY_r0_p5_n1;Adc1PM_;'
		sTNL		= ListMatch( sTNL, sSrc + "*" )					// e.g.  'Adc1FC_;Adc1PM_;'
		string sFirstTrace= StringFromList( 0, sTNL )						// !!! arbitrary / restriction :  could also use any other trace in this window
		wave  /Z	wOrg	= TraceNameToWaveRef( sWnd, sFirstTrace )
		string sFoldOrgWvNm	= NameOfWave( wOrg )						// = UFCom_ksROOT_UF_ + ksACQ_ + UFPE_ksF_IO_ + StringFromList( ch, LstChan_a(), ksSEP_TAB )	// in ACQ : Folders + sSource   e.g.  'root:uf:acq:pul:io:Adc1'

		 // printf "\t\t\tfFitFnc( d )\t  %s\tch:%2d  rg:%2d  \tph: 0..%d  \t\t\tLeftX:\t%5.3lfs\tRigX:\t%5.3lf\tPts(wT):\t%7g\tBegPt:\t%7g\tdltax:\t%8.6lf\tSF:\t%7g\t%s\twave:\t%s\t1.tr\t%s\tsTNL: '%s...' \r", sFolders, ch, rg-1, ph-1, leftX( wOrg ), rightX( wOrg ), numpnts( wOrg ), BegPt, deltaX( wOrg ), SIFact, UFCom_pd(sWnd,5), UFCom_pd(sFoldOrgWvNm,14), UFCom_pd(sFirstTrace,14), sTNL[ 0, 100]
		if ( waveExists( wOrg ) )										// exists only after the user has clicked into the data sections listbox to view, analyse or average a data section
			 UFPE_OneFit( sFolders, sWnd, wOrg, ch, rg, fi, BegPt, SIFact, lstFitResults, LatCnt, FitCnt_a() )		// will fit only if  'Fit' checkbox is 'ON'
		endif
	endif
	LBResSelUpdateOA()											// Rebuild the listbox completely as in meantime while the listbox perhaps was invisible e.g the number of channels may have changed
End


Function		fFitRng_a( s )
	struct	WMPopupAction	&s
	string  	sFolders	= ReplaceString( "root:uf:", GetUserData( s.win,  s.ctrlName, "sFo" ), "" ) + s.win	// e.g.  'root:uf:acq:' -> 'acq:pul'
	variable	ch		= UFCom_TabIdx( s.ctrlName )
	variable	rg		= UFCom_BlkIdx( s.ctrlName )
	variable	fi		= UFCom_RowIdx( s.ctrlName ) 
	variable	nFitRng	= s.popnum - 1
	  printf "\t%s\tch:%d  \trg:%d  \tfi:%d  \t%s\t%g\t= '%s' \t  \r",  UFCom_pd(s.CtrlName,23), ch, rg, fi, UFCom_pd( s.popStr,9), nFitRng,  StringFromList( nFitRng, UFPE_klstFITRANGE )

	// Do a fit immediately. 
	string sWnd	= FindFirstWnd_a( ch )
	string sSrc		= StringFromList( ch, LstChan_a(), UFCom_ksSEP_TAB )
	string sTNL	= TraceNameList( sWnd, ";", 1 )					// e.g.  'wcY_r0_p1_n0;wcY_r0_p1_n1;wcY_r0_p5_n0;Adc1FC_;wcY_r0_p5_n1;Adc1PM_;'
	sTNL		= ListMatch( sTNL, sSrc + "*" )					// e.g.  'Adc1FC_;Adc1PM_;'
	string sFirstTrace= StringFromList( 0, sTNL )						// !!! arbitrary / restriction :  could also use any other trace in this window
	wave  /Z	wOrg	= TraceNameToWaveRef( sWnd, sFirstTrace )
	string sFoldOrgWvNm	= NameOfWave( wOrg )						// = UFCom_ksROOT_UF_ + ksACQ_ + UFPE_ksF_IO_ + StringFromList( ch, LstChan_a(), ksSEP_TAB )	// in ACQ : Folders + sSource   e.g.  'root:uf:acq:pul:io:Adc1'

	variable	BegPt = 0,	  nSFact = 1
	string  	lstFitResults		= "" 
	 UFPE_OneFit( sFolders, sWnd, wOrg, ch, rg, fi, BegPt, nSFact, lstFitResults, LatCnt_a(), FitCnt_a() )
End


