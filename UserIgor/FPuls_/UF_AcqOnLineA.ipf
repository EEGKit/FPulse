
// UF_AcqOnlineA.ipf ( in CED1401 )
// 
// History: 
// 2004-0217	computations now use seconds as time scale as in the other program parts (was milliseconds)
// 2004-0217	introduced  Adc gain in the results
// 2004-0227	Flaw: when not writing CFS file  the user has to 'Apply'  to clear the Analysis window to draw new results 

// todo
// OK	make  analysis display independent of  writing the CFS file
// OK	link  RGconstants  to  RESconstants
// OK	do not build  'time'  traces 
// OK	do not build  'beginning'  and  'end'  traces 
// OK	precise peak determination
// OK	display computed result as a region for visual checking 
// OK 	portions of analysis traces which were not defined should  NOT be displayed (instead of being displayed with 0)
// OK	small cross and big cross
// OK	set the shape of analysis regions    and the  fill pattern  with string lists 
// OK	after killing or expanding the analysis window it should be rebuilt and resized  and it should display traces   OR   there shoud be a REBUILD  button.  NO : user may minimize it and restore it, but if he kills it it is gone forever
// OK	erase regions of previous frames automatically
// OK 	make cINTER obsolete and remove it
// OK	combine PKUP, PKDN and PKBO
// OK	display the state of the  'Region' checkbox correctly (when visible it must be ON) (implemented but not as an elegant solution)
// OK 	order results so that base is always in front of peak		or    make analysis independent of ordering
// OK	peak direction is mixed up when a new peak is inserted
// OK	what if a new script is loaded containing new IO channels for which  no wFileRes waves exist?
// OK 	display peak direction button to its correct state
// OK	allow switching between second and frames  at any time
// OK	button 'Clear analysis window'
// OK	continuous display independent of CFS file
// OK	2. base, 2. peak
// OK	quotient of 2 peaks
// OK 	make 'RTim' work
// OK	allow 2 analysis windows
// OK	allow any number of analysis windows
// OK	X scaling also in minutes
// OK	optionally leave line segment blank between 2 protocols
// OK	decay fit

//	CRASH  when using more than 1 protocol
// 	make timing linear ( up to 1 second error , but occurring only on some systems with some scripts ! )
// 	GetAxis   /Q /W = $sWnd left	does NOT work under certain ? AUTOSCALE conditions., returns  min=max=0				

// Wishes: 
// 	rise fit starting values
//	display time needed for fit ( measure or Task manager...) , exit gracefully if fitting time takes too long for the acquisition timing requirement
// 	copy analysis window so that user can zoom  areas of the copied graph without loosing the original graph containing the total experiment duration
// 	Multiple blocks: e.g. Analyse just one selectable block  OR  define different regions belonging to blocks
// 	Multiple protocols: e.g. Scripts with Inc/Dec 40/60mV  : draw 1 analysis point after averaging  10  40mV frames, another  after averaging  10  60mV frames (JB) 
//			.....[ Is something aequivalent already possible? ]

#pragma rtGlobals=1							// Use modern global access method.


//=================================================================================================================
//	SUBPANEL  OLA  =  ONLINE ANALYSIS

static strconstant	ksPN_NAME		= "LbResSelOA"	// Panel name   _and_  subfolder name  _and_  section keyword in INI file
static strconstant	ksPN_TITLE		= "OLA Results"	// Panel title
static strconstant	ksPN_CTRLBASE	= "buResSelOA"	// The  button base name (without prefix root:uf... and postfix 0000) in the main panel displaying and hiding THIS subpanel
static strconstant	ksPN_INISUB		= "FPuls"			// The  INI subfolder  below folder 'acq'   and   the  INI file location (here in a subdirectory to FPulse=FPulseMain.ipf)
static strconstant	ksPN_INIKEY		= "Wnd"			// The  keyword in the INI file (here always 'Wnd' as we are dealing with window positions and visibility)


//-----------------------------------------------------------------------------------------------------------------------------
// Action procedure for displaying and hiding a subpanel

// 2008-07-17 old
//Function		fOAResSelect( s )
//// Button action procedure of the button in the main panel to display and hide this  OLA  Result selection listbox panel
//	struct	WMButtonAction	&s
//	nvar		state		= $ReplaceString( "_", s.ctrlname, ":" )		// the underlying button variable name is derived from the control name
//	string  	sWin		= ksPN_NAME						// 'LbResSelOA'
//	struct	FPulsePrefs FPPrefs
//	FPulseLoadPackagePrefs( FPPrefs )
//	// printf "\t\t\t\t%s\tvalue:%2d \tLoaded prefs \tL:%4d\tT:%4d\tVis:%4d\t \r",  UFCom_pd(s.CtrlName,31), state,  FPPrefs.Ola[UFCom_WLF],  FPPrefs.Ola[UFCom_WTP],  FPPrefs.Ola[UFCom_WVI]
//
//	// 2007-0320 remember Listbox-Panel position
//	if ( state )													// if we want to  _display_  the panel...
//		LBResSelUpdateOA()										// Rebuild the listbox completely as in meantime while the listbox perhaps was invisible e.g the number of channels may have changed
//	else
//		UFCom_Panel3SubHide( sWin )								//  hide the panel  'ola'  in  Acq 
//		FPPrefs.Ola[ UFCom_WVI ] = 0
//	endif
//
//	FPulseSavePackagePrefs( FPPrefs )
//End

// 2008-07-17 new
Function		fOAResSelect( s )
// Button action procedure of the button in the main panel to display and hide this  OLA  Result selection listbox panel
	struct	WMButtonAction	&s
	nvar		state		= $ReplaceString( "_", s.ctrlname, ":" )		// the underlying button variable name is derived from the control name
	 printf "\t\t\t\t%s\tvalue:%2d   \t\t%s\t%s\t%s\t \r",  UFCom_pd( s.ctrlname, 25),  state, UFCom_pd(ksPN_INISUB  ,11), UFCom_pd(ksPN_NAME ,11), UFCom_pd( ksPN_INIKEY ,11)	
	string  	sIniBasePath	= FunctionPath( ksFP_APP_NAME )					// the Ini file containing the window position will be written in a subdirectory parallel to UF_PulseMain.ipf 
	UFCom_WndVisibilitySetWrite_( ksACQ, ksPN_INISUB, ksPN_NAME, ksPN_INIKEY, state, sIniBasePath )
	if ( state )													// if we want to  _display_  the panel...
		LBResSelUpdateOA()										// Rebuild the listbox completely as in meantime while the listbox perhaps was invisible e.g the number of channels may have changed
	else
//		UFCom_Panel3SubHide( ksPN_NAME )						//  hide the panel  'LbResSelOA'  in  Acq 
		UFCom_WndHide( ksPN_NAME )							//  hide the panel  'LbResSelOA'  in  Acq 
	endif
End


// 2008-07-17
Function 		fHookPnSelResOA( s )
// The window hook function detects when the user moves or resizes or hides the panel  and stores these settings in the INI file
	struct	WMWinHookStruct &s
	string  	sIniBasePath	= FunctionPath( ksFP_APP_NAME )					// the Ini file containing the window position will be written in a subdirectory parallel to UF_PulseMain.ipf 
	return	UFCom_WndUpdateLocationHook( s, ksACQ, ksFPUL, ksPN_INISUB, ksPN_INIKEY, ksPN_CTRLBASE, sIniBasePath )
End

// 2008-07-17 old
//Function 		fHookPnSelResOA( s )
//// The window hook function of the 'Select results panel' detects when the user moves the panel  and stores the top-left corner coordinates in the peferences file
//	struct	WMWinHookStruct &s
//	string  	sFolders	= "acq:pul"
//	string  	sWin		= ksPN_NAME							// 'LbResSelOA'
//	struct	FPulsePrefs FPPrefs
//	if ( s.eventCode != UFCom_WHK_mousemoved )
//		// printf  "\t\tfHookPnSelResOA( %2d \t%s\t)  '%s'\r", s.eventCode,  UFCom_pd(s.eventName,9), s.winName
//		if ( s.eventCode == UFCom_WHK_move )						// This event also triggers if the panel is minimised to an icon or restored again to its previous state
//			// 2007-0320 remember Listbox-Panel position
//			FPulseLoadPackagePrefs( FPPrefs )
//			GetWindow $s.winName hide							// retrieve 'hidden' state and store in V_Value
//			variable	bVisible		  = ! V_Value					// store 'visible' state 
//			FPPrefs.Ola[ UFCom_WVI ]  = bVisible						// store 'visible' state 
//			GetWindow     $s.WinName , wsize						// Get its current position		
//			FPPrefs.Ola[UFCom_WLF]  = V_left;   FPPrefs.Ola[UFCom_WTP]  = V_top
////			variable	bVisible	= ( V_left != V_right  &&  V_top != V_bottom )
//			UFCom_TurnButton( "pul", 	"root_uf_acq_pul_buResSelOA0000",	 bVisible )	//  Turn the 'Select Results' checkbox  ON / OFF  if the user maximised or minimised the panel by clicking the window's  'Restore size'  or  'Minimise' button [ _ ]  to keep the control's state consistent with the actual state.
//			 printf "\t\tfHookPnSelResOA( %2d \t%s\t)  '%s'\tV_left:%3d, V_Right:%3d, V_top:%3d, V_bottom:%3d -> bVisible:%2d  \r", s.eventCode,  UFCom_pd(s.eventName,9), s.winName, V_left, V_Right, V_top, V_bottom, bVisible
//			FPulseSavePackagePrefs( FPPrefs )
//		endif
//	endif
End


static	  strconstant	ksSEP_EQ		= "="
static constant		kMAX_OLA_WNDS	= 3		// !!! for the OLA results : Also adjust the number of listbox columns   ->  see  'ListBox  lbSelectResult,  win = ksPN_NAME,  widths  = xxxxx' 


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  ANALYSIS 1 :  REDUCING  ANALYSIS 
//  Evaluation of  a number of original data points gives one result value.  Realized  here  are   'Base' , 'Peak'  and  'RTim'
//  Features:
//  - Elaborate routines...
//  - no keyword needed in the script , analysis is controlled by user defined regions and an  Analysis control panel


// Once for all channels
static constant		cEVNT = 0, cTIME = 1, cMINU = 2
strconstant		lstXPANEL = "frames;seconds;minutes;"					
strconstant		lstXUNITS	= "frame;s;minute"					
strconstant		lstRESfix	= "Evnt;Tim_;Minu;"													// once for all channels,  value to display and possibly to file . Do NOT use 'Time' instead of 'Tim_' 

constant			kNOT_OPEN	= 0
strconstant		sOLAEXT		= "ola"


// 2006-0331  todo weg ??????????????
static  strconstant	csFO_OLA			= "root:uf:acq:ola"		// the folder for evaluation and fit results
//static  strconstant	csFO_OLA_			= "root:uf:acq:ola:"		// the folder for evaluation and fit results
static  strconstant	csFOLDER_OLA_CROSS	= "root:uf:acq:ola:cross:"	// the folder for the cross or line displaying the evaluation result 
static  strconstant	csFOLDER_OLA_DISP	= "root:uf:acq:ola:disp:"	// the folder for the DISPLAY results
static  strconstant	csFOLDER_OLA_FITTED	= "root:uf:acq:ola:fit:"		// the folder for the fitted segments displaying the evaluation result 
//.......... 060331  weg ??????????????

// 2007-0227 test
//strconstant		UFPE_ksOR		= "or"						// Online Result  and   Online Regions  : The first 2 letters 'or'   ( of ' ors'  and  'org' )  are the beginning of trace name. They are used to exclude these traces from erasing
//strconstant		UFPE_ksORS		= "ors"						// Online Result .  Has 2 functions:  1.subfolder name and  2. the first 2 letters (must be 'or' ) are the beginning of trace name (used to exclude these traces from erasing)
//strconstant		UFPE_ksORG		= "org"						// Online Region.  Has 2 functions:  1.subfolder name and  2. the first 2 letters (must be 'or' ) are the beginning of trace name (used to exclude these traces from erasing)

// Indexing for magnifying  wMagn[]
static	constant		cXSHIFT = 0, cXEXP = 1, cYSHIFT = 2, cYEXP = 3, cMAX_MAGN = 4  


Function		CreateGlobalsInFolder_OLA()
// creates all folder-specific variables. To be used once from CreateGlobals() as the current data folder is changed and not restored

	NewDataFolder  /O  /S $"root:uf:" + ksF_ACQ_PUL		// make a new data folder and use as CDF,  clear everything 

	make /O 	    /N = ( UFPE_kMAXCHANS, UFPE_kRG_MAX, UFPE_kE_RESMAX	 )			wOLARes	= nan		
// 5 is number of initial results: redimension.....todo	


// 2005-1215 CODE FROM UF_EVAL.IPF
	make /O  	    /N = ( UFPE_kMAXCHANS,  cMAX_MAGN )					wMagn		= 0		// for  x and y  shifting and expanding the view
	make /O  	    /N = ( UFPE_kMAXCURRG ) 								wPrevRegion	= 0		// saves channel, region, phase and CursorIndex when moving a cursor so that this previous cursor can be finished when the user fast-switches to a new cursor without 'ESC' e.g. 'b' 'B'. 
	make /O  	    /N = ( UFPE_kMAXCURRG ) 								wCurRegion	= 0		// saves channel, modifier and mouse location when clicking a window to remember the 'active' graph when a panel button is pressed
	make /O  	    /N = ( UFPE_kMAXCHANS, UFPE_kMM_XYMAX )					wMnMx		= UFCom_TRUE	// maximum X and Y data limits  and   whether  the display should be  'Reset' to these limits

	variable	nPhaseCnt = UFPE_kC_PHASES_BASEplusPEAK + LatCnt_a() + FitCnt_a()
//	make /O 	    /N = ( UFPE_kMAXCHANS, UFPE_kRG_MAX, UFPE_kC_PHASES_BASEplusPEAK, UFPE_CN_MAX)  wBandY		= 0		// Y top and bottom values for  Base band ( set by CheckNoise()  or by user )   and   for  Peak
	make /O 	    /N = ( UFPE_kMAXCHANS, UFPE_kRG_MAX, nPhaseCnt, 	   UFPE_CN_MAX  )	wCursor		= nan	// cursor X values  ( initial value  nan  means this cursor has not yet been set )
	make /O 	    /N = ( UFPE_kMAXCHANS )								wXCsrOS		= 0		// workaround required to unify  EVAL  and  ACQ 
	make /O 	    /N = ( UFPE_kMAXCHANS )								wXAxisLeft	= 0		// workaround required to unify  EVAL  and  ACQ 

	make /O 	    /N	 = ( UFPE_kMAXCHANS, UFPE_kRG_MAX, UFPE_kE_RESMAX, UFPE_kE_MAXTYP)	wEval		= Nan	// Nan means this coord could not be evaluated

	NewDataFolder  /O  /S $csFO_OLA		// make a new data folder and use as CDF,  clear everything 

// 2005-12-19b
//	variable	/G	gPrintMask		= 0
//	variable	/G	gnPeakAverMS		= .5				// Average over that time (including both sides of peak) to reduce noise influence on peak height
//	variable	/G	bBlankPause		= UFCom_FALSE//UFCom_TRUE			// Remove connecting lines in OLA graph when there is no experiment 
	variable	/G	gOLAFrmCnt		= 0				// frame counter for the OLA analysis
	variable	/G	gOLAHnd			= kNOT_OPEN
	variable	/G	gnStartTicksOLA	= 0
//	variable	/G	gOLADoFitOrStartVals= UFCom_TRUE			//  1 : do fit , 0 : do not fit, display only starting values.  Can be set to 0  only in  debug mode in Test panel.

//	make /O /T  /N = 0   wtAnRg	= ""					// the wave containing region information is built with size 0. One line is added whenever the user defines a new region.

	if ( ! FP_IsRelease() )
//		gnPeakAverMS	= 2							// Average (for testing) over a long time (including both sides of peak) to reduce noise influence on peak height
	endif

	NewDataFolder  /O  /S $RemoveEnding( csFOLDER_OLA_CROSS )		// remove trailing ':'
	NewDataFolder  /O  /S $RemoveEnding( csFOLDER_OLA_DISP ) 		// remove trailing ':'
	NewDataFolder  /O  /S $RemoveEnding( csFOLDER_OLA_FITTED ) 		// remove trailing ':'

	UFPE_EvPntConstructWaves( ksF_ACQ_PUL )
	UFPE_CursorConstructWaves( ksF_ACQ_PUL, LatCnt_a(), FitCnt_a()  )
End

//=======================================================================================================================================================


//Function 		fClearWindow( s )
//// Only for testing.  Normally traces are cleared  ONLY  by  resetting them in the listbox as only then the correspondence between traces in listbox / on screen / analysed  is maintained. 
//	struct	WMButtonAction  &s
//	ClearWindows()
//End

//Function		root_uf_acq_ola_tc1( s )
//// Special tabcontrol action procedure. Called through	fTabControl3( s ) and  fTcPrc( s ).  This function name is derived from 'PnBuildFoTabcoNm()' 
//// 2005-1110  Clicking  on a tab activates the corresponding graph window
//	struct	WMTabControlAction   &s
//	DoWindow  /F   $WndNm_e( s.tab )						// Bring acq window corresponding to the tab-clicked channel to front and make it the active window 
//	printf "\t\troot_uf_acq_ola_tc1() \r"
//End


//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//Function		fOAReg( s ) 
//// Demo: this  SetVariable control  changes the number of blocks. Consequently the Panel must be rebuilt  OR  it must have a constant large size providing space for the maximum number of blocks.
//	struct	WMSetvariableAction    &s
//	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
//	string  	sFo	 	= GetUserData( 	s.win,  s.ctrlName,  "sFo" )		// e.g.  'root:uf:acq:' 
//	string  	sSubDir	= ReplaceString( "root:uf:", sFo, "" )		  	// e.g.  'root:uf:acq:' -> 'acq:'
//	string  	sFolders	= sSubDir + s.win
//	string  	sFol_ders	= ReplaceString( ":", sFolders, "_" )
//
//	variable	ch		= UFCom_TabIdx( s.ctrlName )
//	string  	lstRegs	=  LstReg( sFolders )
//	  printf "\t%s\t\t\t\t\t%s\tvar:%g\t-> \tch:%d\tLstBlk3:\t%s\t  \r",  UFCom_pd(sProcNm,13), UFCom_pd(s.CtrlName,26), s.dval,ch, UFCom_pd( lstRegs, 19)
//
//	Panel3Main(   "pul", "", "root:uf:" + ksACQ_, 100,  0 ) // Compute the location of panel controls and the panel dimensions. Redraw the panel displaying and hiding needed/unneeded controls
//
//
////	Panel3Sub(   "ola", "Online Analysis", "root:uf:" + ksACQ_, 50, 100,  UFCom_WT_PANEL_DRAW ) // Compute the location of panel controls and the panel dimensions. Draw the panel displaying and hiding needed/unneeded controls
////	UpdateDependent_Of_AllowDelete( s.Win, "root_uf_acq_ola_cbAlDel0000" )	
////	UpdateDependent_Of_AllowDelete( s.Win, "root_uf_acq_set_cbAlDel0000" )	
//
//	UFPE_DisplayCursors_Peak( sFolders, ch )
//	UFPE_DisplayCursors_Base( sFolders, ch )
//	UFPE_DisplayCursors_Lat( sFolders, ch )
//	UFPE_DisplayCursors_UsedFit( sFolders, ch )					// Display the used fit cursors and hide the unused fit cursors immediately depending on the state of the region and fit checkboxes to give the user a feedback which parts of the data will be fitted in the next analysis
//	LBResSelUpdateOA()							// update the 'Select results' panel whose size has changed
//// // 2005-1018
////	UFPE_AllLatenciesCheck()		// If a region which has been turned off still contains a latency option this will be flagged as an error
//End
	

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//  LATENCIES

//Function		LatencyCntA( ) 
//	return	2							// !!!  adjust if we have more or less latencies   as  offered  in the  ACQ Main panel
//End
//
//Function		fLatCsrPopsAc( sControlNm, sFo, sWin )
//// currently   fLatCsrPopsEv()   and   fLatCsrPopsAc()   are identical
//	string		sControlNm, sFo, sWin
//	print "\t\tfLatCsrPopsAc()",  sControlNm, sFo, sWin
//	PopupMenu	$sControlNm, win = $sWin,	 value = klstLATC
//End
//
// 2006-0328
//Function		fLat0Boa( s )
//	struct	WMPopupAction	&s
//	string  	sFolders	= ReplaceString( "root:uf:", GetUserData( s.win,  s.ctrlName, "sFo" ), "" ) + s.win	// e.g.  'root:uf:acq:' -> 'acq:pul'
//	fLatCsrA( sFolders, s.CtrlName, 0, UFPE_CN_BEG )
//End
//
//Function		fLat0Eoa( s )
//	struct	WMPopupAction	&s
//	string  	sFolders	= ReplaceString( "root:uf:", GetUserData( s.win,  s.ctrlName, "sFo" ), "" ) + s.win	// e.g.  'root:uf:acq:' -> 'acq:pul'
//	fLatCsrA( sFolders, s.CtrlName, 0, UFPE_CN_END )
//End
//
//Function		fLat1Boa( s )
//	struct	WMPopupAction	&s
//	string  	sFolders	= ReplaceString( "root:uf:", GetUserData( s.win,  s.ctrlName, "sFo" ), "" ) + s.win	// e.g.  'root:uf:acq:' -> 'acq:pul'
//	fLatCsrA( sFolders, s.CtrlName, 1, UFPE_CN_BEG )
//End
//
//Function		fLat1Eoa( s )
//	struct	WMPopupAction	&s
//	string  	sFolders	= ReplaceString( "root:uf:", GetUserData( s.win,  s.ctrlName, "sFo" ), "" ) + s.win	// e.g.  'root:uf:acq:' -> 'acq:pul'
//	fLatCsrA( sFolders, s.CtrlName, 1, UFPE_CN_END )
//End
//
//
//Function		fLatCsrA( sFolders, sCtrlName, latcsr, BegEnd )
//	string 	sFolders, sCtrlName
//	variable	latcsr, BegEnd 
//	variable	ch		= UFCom_TabIdx( sCtrlName )
//	variable	rg		=UFCom_BlkIdx( sCtrlName )
//	// TurnRemainingLatenciesOff( s.CtrlName, latcsr, BegEnd, ch, rg )	// Two advantages: 1. Prevent that the user accidentally redefines this latency in another channel or region.  2. Tidy up the panel. 
//	variable	nChans	= ItemsInList( LstChan_a(), UFCom_ksSEP_TAB )
//	variable	LatCnt	= LatencyCnt( sFolders )
//	UFPE_AllLatenciesCheck( sFolders, nChans, LatCnt )					//...BUT does not work as all hidden popmenus are restored whenever tabs are clicked. -> must recognise hidden state then
//	// !OA UFPE_DisplayCursor_Lat( sFolders, ch, rg, latcsr, BegEnd )
//	LBResSelUpdateOA()										// update the 'Select results' panel whose contents may have changed
//	 printf "\t%s\t%s\tch:%d/%2d  \trg:%d  latcsr:%d/%2d  BegEnd:%d \t  \r",  UFCom_pd( sCtrlName,31), UFCom_pd( sFolders, 9), ch, nChans, rg, latcsr, LatCnt, BegEnd
//End
//
//Function		fLat0Boa( s )
//	struct	WMPopupAction	&s
//	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
//	string  	sFo	 	= GetUserData( 	s.win,  s.ctrlName,  "sFo" )		// e.g.  'root:uf:eva:' 
//	string  	sSubDir	= ReplaceString( "root:uf:", sFo, "" )		  	// e.g.  'root:uf:eva:' -> 'eva:'
//	string  	sFolders	= sSubDir + s.win
//
//	variable	ch	= UFCom_TabIdx( s.ctrlName )
//	variable	rg	=UFCom_BlkIdx( s.ctrlName )
//	variable	lc	= 0, 	BegEnd = UFPE_CN_BEG
//	 printf "\t%s\t%s\tch:%d  \trg:%d  lc:%d  BegEnd:%d \t%s\t%g\t  \r",  UFCom_pd(sProcNm,15), UFCom_pd(s.CtrlName,31), ch, rg, lc, BegEnd, UFCom_pd( s.popStr,9), (s.popnum-1)
//	// TurnRemainingLatenciesOff( s.CtrlName, lc, BegEnd, ch, rg )		// Two advantages: 1. Prevent that the user accidentally redefines this latency in another channel or region.  2. Tidy up the panel. 
//	variable	nChans	= ItemsInList( LstChan_a(), UFCom_ksSEP_TAB )
//	variable	LatCnt	= LatencyCnt( sFolders )
//	UFPE_AllLatenciesCheck( sFolders, nChans, LatCnt )					//...BUT does not work as all hidden popmenus are restored whenever tabs are clicked. -> must recognise hidden state then
//	// !OA UFPE_DisplayCursor_Lat( sFolders, ch, rg, lc, BegEnd )
//	LBResSelUpdateOA()										// update the 'Select results' panel whose contents may have changed
//End
//
//Function		fLat0Eoa( s )
//	struct	WMPopupAction	&s
//	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
//	string  	sFo	 	= GetUserData( 	s.win,  s.ctrlName,  "sFo" )		// e.g.  'root:uf:eva:' 
//	string  	sSubDir	= ReplaceString( "root:uf:", sFo, "" )		  	// e.g.  'root:uf:eva:' -> 'eva:'
//	string  	sFolders	= sSubDir + s.win
//	variable	ch	= UFCom_TabIdx( s.ctrlName )
//	variable	rg	=UFCom_BlkIdx( s.ctrlName )
//	variable	lc	= 0, 	BegEnd = UFPE_CN_END
//	 printf "\t%s\t%s\tch:%d  \trg:%d  lc:%d  BegEnd:%d \t%s\t%g\t  \r",  UFCom_pd(sProcNm,15), UFCom_pd(s.CtrlName,31), ch, rg, lc, BegEnd, UFCom_pd( s.popStr,9), (s.popnum-1)
//	// TurnRemainingLatenciesOff( s.CtrlName, lc, BegEnd, ch, rg )		// Two advantages: 1. Prevent that the user accidentally redefines this latency in another channer or region.  2. Tidy up the panel. 
//	variable	nChans	= ItemsInList( LstChan_a(), UFCom_ksSEP_TAB )
//	variable	LatCnt	= LatencyCnt( sFolders )
//	UFPE_AllLatenciesCheck( sFolders, nChans, LatCnt )					//...BUT does not work as all hidden popmenus are restored whenever tabs are clicked. -> must recognise hidden state then
//	// !OA UFPE_DisplayCursor_Lat( sFolders, ch, rg, lc, BegEnd )
//	LBResSelUpdateOA()										// update the 'Select results' panel whose contents may have changed
//End
//
//Function		fLat1Boa( s )
//	struct	WMPopupAction	&s
//	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
//	string  	sFo	 	= GetUserData( 	s.win,  s.ctrlName,  "sFo" )		// e.g.  'root:uf:eva:' 
//	string  	sSubDir	= ReplaceString( "root:uf:", sFo, "" )		  	// e.g.  'root:uf:eva:' -> 'eva:'
//	string  	sFolders	= sSubDir + s.win
//
//	variable	ch	= UFCom_TabIdx( s.ctrlName )
//	variable	rg	=UFCom_BlkIdx( s.ctrlName )
//	variable	lc	= 1, 	BegEnd = UFPE_CN_BEG
//	 printf "\t%s\t%s\tch:%d  \trg:%d  lc:%d  BegEnd:%d \t%s\t%g\t  \r",  UFCom_pd(sProcNm,15), UFCom_pd(s.CtrlName,31), ch, rg, lc, BegEnd, UFCom_pd( s.popStr,9), (s.popnum-1)
//	// TurnRemainingLatenciesOff( s.CtrlName, lc, BegEnd, ch, rg )		// Two advantages: 1. Prevent that the user accidentally redefines this latency in another channel or region.  2. Tidy up the panel. 
//	variable	nChans	= ItemsInList( LstChan_a(), UFCom_ksSEP_TAB )
//	variable	LatCnt	= LatencyCnt( sFolders )
//	UFPE_AllLatenciesCheck( sFolders, nChans, LatCnt )					//...BUT does not work as all hidden popmenus are restored whenever tabs are clicked. -> must recognise hidden state then
//	// !OA UFPE_DisplayCursor_Lat( sFolders, ch, rg, lc, BegEnd )
//	LBResSelUpdateOA()										// update the 'Select results' panel whose contents may have changed
//End
//
//Function		fLat1Eoa( s )
//	struct	WMPopupAction	&s
//	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
//	string  	sFo	 	= GetUserData( 	s.win,  s.ctrlName,  "sFo" )		// e.g.  'root:uf:eva:' 
//	string  	sSubDir	= ReplaceString( "root:uf:", sFo, "" )		  	// e.g.  'root:uf:eva:' -> 'eva:'
//	string  	sFolders	= sSubDir + s.win
//	variable	ch	= UFCom_TabIdx( s.ctrlName )
//	variable	rg	=UFCom_BlkIdx( s.ctrlName )
//	variable	lc	= 1, 	BegEnd = UFPE_CN_END
//	 printf "\t%s\t%s\tch:%d  \trg:%d  lc:%d  BegEnd:%d \t%s\t%g\t  \r",  UFCom_pd(sProcNm,15), UFCom_pd(s.CtrlName,31), ch, rg, lc, BegEnd, UFCom_pd( s.popStr,9), (s.popnum-1)
//	// TurnRemainingLatenciesOff( s.CtrlName, lc, BegEnd, ch, rg )		// Two advantages: 1. Prevent that the user accidentally redefines this latency in another channer or region.  2. Tidy up the panel. 
//	variable	nChans	= ItemsInList( LstChan_a(), UFCom_ksSEP_TAB )
//	variable	LatCnt	= LatencyCnt( sFolders )
//	UFPE_AllLatenciesCheck( sFolders, nChans, LatCnt )					//...BUT does not work as all hidden popmenus are restored whenever tabs are clicked. -> must recognise hidden state then
//	// !OA UFPE_DisplayCursor_Lat( sFolders, ch, rg, lc, BegEnd )
//	LBResSelUpdateOA()										// update the 'Select results' panel whose contents may have changed
//End




//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// QUOTIENTS     BAD   PopupMenu	$sControlNm, win = $sWin,	 value = ListACV1RegionOA( ch, rg )     AS does not compile  . Also   not intuitive

//Function		QuotientCntA() 
//	return	1						// !!!  adjust if we have more or less  quotients  as  offered in the  Main panel
//End
//
//Function		fQuotPopsAc( sControlNm, sFo, sWin )
//	string		sControlNm, sFo, sWin
//	variable	ch	= UFCom_TabIdx( sControlNm )
//	variable	rg	=UFCom_BlkIdx( sControlNm )
//	 printf "\t\tfQuotPopsAc( '%s'  '%s'  '%s' ) -> ch:%2d  rg:%2d  \r", sControlNm, sFo, sWin , ch, rg
//	PopupMenu	$sControlNm, win = $sWin,	 value = " a ; b ; c ; d ;"//ListACV1RegionOA( ch, rg ) 	// TODOA 1. does not compile  	 // 2. is this recursive ???
//End
//
//Function		fQuotEnum( s )
//	struct	WMPopupAction	&s
//	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
//	string  	sFo	 	= GetUserData( 	s.win,  s.ctrlName,  "sFo" )		// e.g.  'root:uf:eva:' 
//	string  	sSubDir	= ReplaceString( "root:uf:", sFo, "" )		  	// e.g.  'root:uf:eva:' -> 'eva:'
//	string  	sFolders	= sSubDir + s.win
//
//	variable	ch	= UFCom_TabIdx( s.ctrlName )
//	variable	rg	=UFCom_BlkIdx( s.ctrlName )
//	variable	lc	= 0, 	EnuDeno = UFPE_CN_BEG	// here 0 = enumerator
//	 printf "\t%s\t%s\tch:%d  \trg:%d  lc:%d  Enu/Deno:%d \t%s\t%g\t  \r",  UFCom_pd(sProcNm,15), UFCom_pd(s.CtrlName,31), ch, rg, lc, EnuDeno, UFCom_pd( s.popStr,9), (s.popnum-1)
//	// TurnRemainingLatenciesOff( s.CtrlName, lc, BegEnd, ch, rg )		// Two advantages: 1. Prevent that the user accidentally redefines this latency in another channel or region.  2. Tidy up the panel. 
//	// variable	nChans	= ItemsInList( LstChan_a(), UFCom_ksSEP_TAB )
//	// variable	QuotCnt	= QuotientCntA()
//	// UFPE_AllLatenciesCheck( sFolders, nChans, LatCnt )					//...BUT does not work as all hidden popmenus are restored whenever tabs are clicked. -> must recognise hidden state then
//	// !OA UFPE_DisplayCursor_Lat( sFolders, ch, rg, lc, BegEnd )
//	LBResSelUpdateOA()										// update the 'Select results' panel whose contents may have changed
//End
//
//Function		fQuotDenom( s )
//	struct	WMPopupAction	&s
//	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
//	string  	sFo	 	= GetUserData( 	s.win,  s.ctrlName,  "sFo" )		// e.g.  'root:uf:eva:' 
//	string  	sSubDir	= ReplaceString( "root:uf:", sFo, "" )		  	// e.g.  'root:uf:eva:' -> 'eva:'
//	string  	sFolders	= sSubDir + s.win
//
//	variable	ch	= UFCom_TabIdx( s.ctrlName )
//	variable	rg	=UFCom_BlkIdx( s.ctrlName )
//	variable	lc	= 0, 	EnuDeno = UFPE_CN_END	// here 1 = denominator
//	 printf "\t%s\t%s\tch:%d  \trg:%d  lc:%d  Enu/Deno:%d \t%s\t%g\t  \r",  UFCom_pd(sProcNm,15), UFCom_pd(s.CtrlName,31), ch, rg, lc, EnuDeno, UFCom_pd( s.popStr,9), (s.popnum-1)
//	// TurnRemainingLatenciesOff( s.CtrlName, lc, BegEnd, ch, rg )		// Two advantages: 1. Prevent that the user accidentally redefines this latency in another channel or region.  2. Tidy up the panel. 
//	// variable	nChans	= ItemsInList( LstChan_a(), UFCom_ksSEP_TAB )
//	// variable	QuotCnt	= QuotientCntA()
//	// UFPE_AllLatenciesCheck( sFolders, nChans, LatCnt )					//...BUT does not work as all hidden popmenus are restored whenever tabs are clicked. -> must recognise hidden state then
//	// !OA UFPE_DisplayCursor_Lat( sFolders, ch, rg, lc, BegEnd )
//	LBResSelUpdateOA()										// update the 'Select results' panel whose contents may have changed
//End

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function		HighResolution()
	string  	sFolders	= "acq:pul"
	nvar		bHighResolution	= $"root:uf:" + sFolders + ":HighResol0000"
	return	bHighResolution
End

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function		fOAClearResSel( s )
// Called when a button is pressed.  ALSO CALLED when moving the mouse over a button.  
	struct	WMButtonAction	&s
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	printf "\t\t%s(s)\t\t%s\t%d\t \r",  sProcNm, UFCom_pd(s.CtrlName,26), mod( DateTime,10000)
	string  	sFolders		= "acq:pul"
	wave	wFlags		= $"root:uf:" + sFolders + ":wSRFlags"
	UFPE_LBClear( wFlags )
	// Reset the quasi-global string 	'lstOlaRes' which contains then information which OLA data are to be plotted in which windows. In this special simple context (=Reset the entire Listbox) simple code like '  lstOlaRes=""  '  would also be sufficient.
	string  	sWin			= ksPN_NAME
	string  	sCtrlName		= "lbSelectResult"
	string  	lstOlaRes		= ExtractLBSelectedWindows( sFolders, sWin, sCtrlName )
	ListBox 	  $sCtrlname,    win = $sWin, 	userdata( lstOlaRes ) = lstOlaRes
End

//=======================================================================================================================================================
// THE   RESULT SELECTION   ONLINE  ANALYSIS   LISTBOX  PANEL			

static constant	kLBOLA_COLWID_TYP	= 62		// OLA Listbox column width for SrcRegTyp	 column  (in points)
static constant	kLBOLA_COLWID_WND	= 13		// OLA Listbox column width for    Window	 column  (in points)	(A0,A1 needs 20,  a,b,c needs 12,   A,B,C needs 14)
static constant	kLBOLA_Y			= .6

Function		LBResSelUpdateOA()
// Build the huge  'R_esult S_election'  listbox allowing the user to select some results Online graphical display
	string  	sWin			= ksPN_NAME
// 2008-07-17 old
//	struct	FPulsePrefs 	FPPrefs
//	FPulseLoadPackagePrefs( FPPrefs )
	string  	sIniBasePath	= FunctionPath( ksFP_APP_NAME )					// the Ini file containing the window position will be written in a subdirectory parallel to UF_PulseMain.ipf 
	string  	sFolders		= "acq:pul"
	string  	sFo			= ksACQ
	nvar		bVisib		= $"root:uf:" + sFolders + ":buResSelOA0000"		// The ON/OFF state ot the 'Select Results OA' button

	// 1. Construct the global string  'lstACVAllCh'  which contains all of the various evaluation and fitting values
	string  	lstACVAllCh	=  ListACVAllChansOA() 						// Base_00;BsRise_00;RT20_00;


	// 2. Get the the text for the cells by breaking the global string  'lstACVAllCh'  which contains all of the various evaluation and fitting values
	variable	len, n, nItems	= ItemsInList( lstACVAllCh )	
	// printf "\t\t\tLBResSelUpdateOA(a)\tlstACVAllCh has items:%3d <- \t '%s .... %s' \r", nItems, lstACVAllCh[0,80] , lstACVAllCh[ strlen( lstACVAllCh ) - 80, inf ]
	string 	sColTitle, lstColTitles	= ""				// e.g. 'Adc1 Rg 0~Adc3 Rg1~'
	string  	lstColItems		= ""
	string  	lstCol2ChRg	= ""					// e.g. '1,0;0,2;'

// 2009-07-03 separate general eval entries like DS, Bef, Date   from Ch-Reg-dependant ones like Base, Peak
//	variable	nExtractCh, ch = -1
//	variable	nExtractRg, rg = -1 
	string  	sExtractCh,  sCh = "-1"
	string  	sExtractRg, sRg = "-1"


	string 	sOneItemIdx, sOneItem
	for ( n = 0; n < nItems; n += 1 )
		sOneItemIdx	= StringFromList( n, lstACVAllCh )						// e.g. 'Base_010'
		len			= strlen( sOneItemIdx )
		sOneItem		= UFPE_ChRgPostFixStrip_( sOneItemIdx )				// strip 3 indices + separator '_'  e.g. 'Base_010'  ->  'Base'

// 2009-07-03 separate general eval entries like DS from Ch-Reg-dependant ones like Base, Peak
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
//			lstColTitles	     =  AddListItem( sColTitle, 	 lstColTitles,   UFCom_ksCOL_SEP, inf )	// e.g. 'Adc1 Rg 0~Adc3 Rg1~'
//			lstCol2ChRg +=  UFPE_SetChRg( ch, rg )							// e.g.  '1,0;0,2;'

		sOneItem		= UFPE_ChRgPostFixStrip_( sOneItemIdx )		// strip 2 indices + separator '_'  e.g. 'Base_10'  ->  'Base'
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



			lstColItems	   += UFCom_ksCOL_SEP
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
	// printf "\t\t\tLBResSelUpdateOA(b)\tlstACVAllCh has items:%3d -> rows:%3d  cols:%2d\tColT: '%s'\tColItems: '%s...' \r", nItems, nRows, nCols, lstColTitles, lstColItems[0, 100]


	// 4. Compute panel size . The y size of the listbox and of the panel  are adjusted to the number of listbox rows (up to maximum screen size) 
	variable	nSubCols	= kMAX_OLA_WNDS
	variable	xSzPix	= nCols * ( kLBOLA_COLWID_TYP + nSubCols * kLBOLA_COLWID_WND )	+ 30 	 
	variable	ySizeMax	= UFCom_GetIgorAppPixelY() -  UFCom_kMAGIC_Y_MISSING_PIXEL	// Here we could subtract some Y pixel if we were to leave a bottom region not covered by a larges listbox.
	variable	ySizeNeed	= nRows * UFCom_kLB_CELLY + UFCom_kLB_ADDY				// We build a panel which will fit entirely on screen, even if not all listbox line fit into the panel...
	variable	ySzPix	= min( ySizeNeed , ySizeMax ) 					// ...as in this case Igor will automatically supply a listbox scroll bar.
			ySzPix	=  trunc( ( ySzPix -  UFCom_kLB_ADDY ) / UFCom_kLB_CELLY ) * UFCom_kLB_CELLY + UFCom_kLB_ADDY	// To avoid partial listbox lines shrink the panel in Y so that only full-height lines are displayed
	
	// 5. Draw  panel and listbox
	if ( bVisib )													// Draw the SelectResultsPanel and construct or redimension the underlying waves  ONLY IF  the  'Select Results' checkbox  is  ON

		if ( WinType( sWin ) != UFCom_WT_PANEL )								// Draw the SelectResultsPanel and construct the underlying waves  ONLY IF  the panel does not yet exist
			// Define initial panel position.
			//UFCom_NewPanel1( sWin, UFCom_kRIGHT1, -100, xSzPix, kLBOLA_Y, 0, ySzPix, UFCom_kKILL_DISABLE, ksPN_TITLE )	// -50 is an X offset preventing this panel to be covered by the FPulse panel.  We must disable killing as this would destroy any selection in the listbox, but minimising is allowed.
			// 2007-0320 remember Listbox-Panel position
// 2008-07-17
			variable	left, top, right, bot
			string  	sWndInfo = UFCom_Ini_Section( sFo, ksPN_INISUB, ksPN_NAME, ksPN_INIKEY )
			UFCom_WndPosition_( sFo, sWndInfo, left, top, right, bot )
			UFCom_NewPanel1_( sWin, left, top, xSzPix, ySzPix, UFCom_kKILL_DISABLE, ksPN_TITLE )
			//UFCom_NewPanel1_( sWin, FPPrefs.Ola[ UFCom_WLF ] , FPPrefs.Ola[ UFCom_WTP ] , xSzPix, ySzPix, UFCom_kKILL_DISABLE, ksPN_TITLE )
//			UFCom_LstPanelsSet( ksACQ, ksfACQVARS , AddListItem( sWin, UFCom_LstPanels( ksACQ, ksfACQVARS ) ) )	
			UFCom_LstPanelsAdd( ksACQ, ksfACQVARS, sWin )	
	
			SetWindow	$sWin,  hook( SelRes ) = fHookPnSelResOA

			ModifyPanel /W=$sWin, fixedSize= 1						// prevent the user to maximize or close the panel by disabling these buttons

			// Create the 2D LB text wave	( Rows = maximum of results in any ch/rg ,  Columns = Ch0 rg0; Ch0 rg1; ... )
			make  /O 	/T 	/N = ( nRows, nCols*(1+nSubCols) )	$"root:uf:" + sFolders + ":wSRTxt"	= ""	// the LB text wave
			wave   	/T		wSRTxt				     =	$"root:uf:" + sFolders + ":wSRTxt"
		
			// Create the 3D LB flag wave. 	Rows x Columns (as above)  x 3  : last index 0 is flags, 1 is fore- or background color, 2 is the remaining color 
			make   /O	/B  /N = ( nRows, nCols*(1+nSubCols), 3 )	$"root:uf:" + sFolders + ":wSRFlags"	// byte wave is sufficient for up to 254 colors 
			wave   			wSRFlags				    = 	$"root:uf:" + sFolders + ":wSRFlags"
			
			// Create color table withs rows and columns exchanged. 3 rows, n columns is easier to read as n columns, 3 rows but must be transposed before Igor can use them.
			// At the moment these colors are the same as in the  DataSections  listbox
			//								black		blue			red			magenta			grey			light grey			green			yellow				

// Version1: (works but wrong colors)
//			make   /O	/W /U	root:uf:acq:ola:wSRColors= { {0, 0, 0 }, { 0, 0, 65535 },  { 65535, 0, 0 },  {40000,0,48000}, {44000,44000,44000},  {54000,54000,54000},  { 0, 50000, 0} ,   { 0, 56000, 56000 },  {65280,59904,48896} }	// order must be same as defined by constants above
//			wave	wSRColorsPr	 	= root:uf:acq:ola:wSRColors 		
//			MatrixTranspose 		  wSRColorsPr					// the same table is used for foreground and background. 	Igor requires  n  rows, 3 columns 
//			 UFPE_LBColors( wSRColorsPr )								// 2005-1108  

// Version2: (works...)
			make /O	/W /U /N=(UFPE_ST_MAX,3) 	   $"root:uf:" + sFolders + ":wSRColors" 		
			wave	wSRColorsPr	 			= $"root:uf:" + sFolders + ":wSRColors" 		
			 UFPE_LBColors( wSRColorsPr )								// 2005-1108  


			// Link the  indices  of  Foreground  and  Background  colors  to  their name strings which are later used to access the layer where the color is to be set
			variable	planeFore	= 1
			variable	planeBack	= 2
			SetDimLabel 2, planeBack,  $"backColors"	wSRFlags
			SetDimLabel 2, planeFore,   $"foreColors"	wSRFlags
	
		else	
															// The panel DOES exist. It may be minimised to an icon or it may be hidden behind other panels. If it is hidden then the checkbox must be actuated twice: hide and then restore panel to make it visible
			// 2007-0320 remember Listbox-Panel position
			//UFCom_Panel3SubUnhide( sWin )						//  display again the hidden panel 'ola' 
			UFCom_WndUnhide( ksPN_NAME )						//  display again the hidden panel 'ola' 

// 2008-07-17
//			FPPrefs.Ola[ UFCom_WVI ] = 1
			UFCom_WndVisibilitySetWrite_( ksACQ, ksPN_INISUB, ksPN_NAME, ksPN_INIKEY, 1, sIniBasePath )

			wave   	/T		wSRTxt			= $"root:uf:" + sFolders + ":wSRTxt"
			wave   			wSRFlags		  	= $"root:uf:" + sFolders + ":wSRFlags"
			Redimension	/N = ( nRows, nCols*(1+nSubCols) )		wSRTxt
			Redimension	/N = ( nRows, nCols*(1+nSubCols), 3 )		wSRFlags
		endif

		// Set the column titles in the SR text wave, take the entries as computed above
		variable	w, lbCol
		for ( c = 0; c < nCols; c += 1 )								// the true columns 0,1,2  each including the window subcolumns
			for ( w = 0; w <= nSubCols; w += 1 )						// 1 more as w=0 is not a window but the SrcRegTyp column
				lbCol	= c * (nSubCols+1) + w
				if ( w == 0 )
					SetDimLabel 1, lbCol, $StringFromList( c, lstColTitles, UFCom_ksCOL_SEP ), wSRTxt	// 1 means columns,   true column 		e.g. 'Ch 0 Rg 0'  or  'Ch 2 Rg1'  or  'Adc1 Rg 0'
				else
					SetDimLabel 1, lbCol, $AnalWndNm( w-1 ), wSRTxt					// 1 means columns,   window subcolumn	e.g. 'A' , 'B' , 'C'   or  'W0' , 'W1' 
				endif
			endfor
		endfor

		// Fill the listbox columns with the appropriate  text
		variable	r
		for ( c = 0; c < nCols; c += 1 )
			if ( c == 0 )
				ListBox   	lbSelectResult,    win = $sWin, 	widths  =	{ kLBOLA_COLWID_TYP,  kLBOLA_COLWID_WND,  kLBOLA_COLWID_WND,  kLBOLA_COLWID_WND }	// !!! number of entries depends on ...	
			else
				ListBox 	lbSelectResult,    win = $sWin, 	widths +=	{ kLBOLA_COLWID_TYP,  kLBOLA_COLWID_WND,  kLBOLA_COLWID_WND,  kLBOLA_COLWID_WND }	// ...'nSubCols' = 'kMAX_OLA_WNDS'
			endif
			lstItemsInColumn  = StringFromList( c, lstColItems, UFCom_ksCOL_SEP )	
			for ( r = 0; r < ItemsInList( lstItemsInColumn ); r += 1 )
				for ( w = 0; w <= nSubCols; w += 1 )									// 1 more as w=0 is not a window but the SrcRegTyp column
					lbCol	= c *(nSubCols+1) + w
					if ( w == 0 )
						wSRTxt[ r ][ lbCol ]	= StringFromList( r, lstItemsInColumn )			// set the text  e.g  'Base' , 'F0_T0'
					else
						wSRTxt[ r ][ lbCol ]	= ""									// the subcolumns 'A' , 'B' , 'C'  are  NOT displayed in the cells but only in the titles
					endif
				endfor
			endfor
			for ( r = ItemsInList( lstItemsInColumn ); r < nRows; r += 1 )
				for ( w = 0; w <= nSubCols; w += 1 )
					lbCol	= c * (nSubCols+1) + w
					wSRTxt[ r ][ lbCol ]	= ""										// some columns may have less entries than other columns: delete old left-over entries
				endfor
			endfor
		endfor
	
		// Build the listbox which is the one and only panel control 
		// stale BP 2  : set 2 BPs in the next 2 lines. Run until  Igor stops at the 2. BP ( the 1. will.be skipped ).  Try to continue with  ESC....NO stale BP here.

		ListBox 	  lbSelectResult,    win = $sWin, 	pos = { 2, 0 },  size = { xSzPix, ySzPix + UFCom_kLB_ADDY },  frame = 2
		ListBox	  lbSelectResult,    win = $sWin, 	listWave 			= $"root:uf:" + sFolders + ":wSRTxt"
		ListBox 	  lbSelectResult,    win = $sWin, 	selWave 			= $"root:uf:" + sFolders + ":wSRFlags",  editStyle = 1
		ListBox	  lbSelectResult,    win = $sWin, 	colorWave		= $"root:uf:" + sFolders + ":wSRColors"				// 2005-1108
		// ListBox 	  lbSelectResult,    win = $sWin, 	mode 			 = 4// 5			// ??? in contrast to the  DataSections  panel  there is no mode setting required here ??? 
		ListBox 	  lbSelectResult,    win = $sWin, 	proc 	 			 = lbResSelOAProc
		ListBox 	  lbSelectResult,    win = $sWin, 	userdata( lstCol2ChRg ) = lstCol2ChRg

	endif		// bVisible : state of 'Select results panel' checkbox is  ON 

	// 2006-0314
	// Store the string quasi-globally within the listbox panel window
	// ListBox 	 	lbSelectResult,    win = $sWin, 	UserData( lstACVAllCh ) = lstACVAllCh		// Store the string quasi-globally within the listbox which belongs to the panel window 
	SetWindow	$sWin,  					UserData( lstACVAllCh ) = lstACVAllCh		// Store the string quasi-globally within the panel window containing the listbox 


	// 7.	Construct the OLA result waves: 1 wave for each listbox entry.  Initially the wave all have just 1 point containing Nan so they will not be drawn. 
	AppendNanInDisplayWave( 0, sWin )		
	
End


//-----------------------------------------------------------------------------------------------------------------------------
// Used for encoding channel/region information indexed by listbox column

Function		LbCol2Ch( nLbCol, nSubCols )	
	variable	nLbCol										// the column in the listbox counting channel  AND additional window columns
	variable	nSubCols										// the number of window columns (same for each channel, typically 3)
	variable	nChIdx	= floor( nLbCol / ( nSubCols+1 ) )				// the index of the channel (ignoring all additional window columns)
	return	nChIdx
End

Function		LbCol2Wnd( nLbCol, nSubCols )	
	variable	nLbCol										// the column in the listbox counting channel  AND additional window columns
	variable	nSubCols										// the number of window columns (same for each channel, typically 3)
	variable	nWndIdx  = mod( nLbCol,  nSubCols + 1 )				// the index of the window
	return	nWndIdx										// 1 based : 1,2,3...
End
Function		LbCol2Wnd0( nLbCol, nSubCols )	
	variable	nLbCol										// the column in the listbox counting channel  AND additional window columns
	variable	nSubCols										// the number of window columns (same for each channel, typically 3)
	variable	nWndIdx  = mod( nLbCol,  nSubCols + 1 ) - 1			// the index of the window
	return	nWndIdx										// 0 based : 0,1,2...
End

Function		LbCol2TypCol( nLbCol, nSubCols )	
	variable	nLbCol										// the column in the listbox counting channel  AND additional window columns
	variable	nSubCols										// the number of window columns (same for each channel, typically 3)
	variable	nTypCol	= LbCol2Ch( nLbCol, nSubCols ) * ( nSubCols+1 )	// the true column number of the type (e.g. 'Peak') corresponding to the clicked window (A,B or C) taking into account the channel and region 
	return	nTypCol
End

Function		LbChanWnd2Col( nMainCol, nSubCol, nSubCols )
	variable	nMainCol										// typically the channel
	variable	nSubCol										// typically the window	
	variable	nSubCols										// the number of window columns (same for each channel, typically 3)
	variable	nTruecol	= 1 + nMainCol * ( nSubCols+1 ) + nSubCol		// the true column number 
	return	nTruecol
End



// 2006-0317a
//Function		AutoSelectOLAResults( w, ch, rg, rtp )
//// Automatically selects an OLA listbox field (=automatically display OLA data in a possibly auto-constructed window)  when the user defines a region.
//// Limitations: 1.Currently implemented only for base and peak.  2. Fixed window 'w' is chosen.   3. User must click window away if he does not want to see the OLA results or if he wants to see them in another window.
//	variable	w, ch, rg, rtp
//	string  	sFolders		= "acq:pul"
//	wave	wFlags		= $"root:uf:" + sFolders + ":wSRFlags"
//	wave   /T	wTxt			= $"root:uf:" + sFolders + ":wSRTxt"
//	string  	sPlaneNm		= "BackColors" 
//	variable	pl			= FindDimLabel( wFlags, 2, sPlaneNm )
//	variable	nState	= 3										// todo ...could expand this.....
//	string  	sWnd
//	string  	sSrc		= StringFromList( ch, LstChan_a(), UFCom_ksSEP_TAB )
//	string  	sTyp		= UFPE_EvalNm( rtp )
//	string  	sOlaNm 	= OlaNm( sSrc, sTyp, rg ) 
//
//	// Compute the column index of the listbox field to be highlighted (=selected)  from the  source channel  chosen in the marquee menu when defining a region
//	string  	sWin			= ksPN_NAME
//	string  	sCtrlName		= "lbSelectResult"
//	string  	lstCol2ChRg 	= GetUserData( 	sWin,  sCtrlName,  "lstCol2ChRg" )	// e.g. for 2 columns '0,0;1,2;'  (Col0 is Ch0Rg0 , col1 is Ch1Rg2) 
//	
//	string  	sChRg	= RemoveEnding(  UFPE_SetChRg( ch, rg ) )					// remove trailing separator
//	variable	col		= WhichListItem( sChRg, lstCol2ChRg ) 					// this is the ChRegSrc column index but it is not the true lb column index as it ignores the intermediate window columns
//	if ( col == UFCom_kNOTFOUND )
//		UFCom_InternalError( "AutoSelectOLAResults() could not find matching column for requested ChRg='" + sChRg + "' in list of all ChRgs='" + lstCol2ChRg + "' ." )
//		return	-1
//	endif
//	variable	nTrueCol	= col * (1+kMAX_OLA_WNDS)  + w					// this is the true lb column index including window columns
//	
//	// Compute the row index of the listbox field to be highlighted (=selected)  from the  result type  chosen in the marquee menu when defining a region
//	variable	row		= SearchRow( wTxt, col, sTyp )
//	if ( row == UFCom_kNOTFOUND )
//		UFCom_InternalError( "AutoSelectOLAResults() could not find matching  row  for requested Typ='" + sTyp + "' ." )
//		return	-1
//	endif
//
//
//	 UFPE_LBSet5( wFlags, row, row, nTrueCol, pl, nState )							// sets flags .  The range feature is not used here so  begin row = end row .
//
//	sWnd		= PossiblyAddAnalysisWnd( w-1 )
//	 printf "\t\tAutoSelectOLAResults(\tw:%2d \tch:%2d\trg:%2d\tnUFPE_kE_Idx:%2d\t-> '%s'\t'%s'\t'%s'\t'%s'\t-> \trow:%2d\tcol:%2d\t(%2d )\t<-\t['%s'   '%s']  \r", w , ch, rg, rtp, sTyp, sWnd,  sSrc, sOlaNm, row, col, nTrueCol, sChRg, lstCol2ChRg
//// 2006-0315
//	SetChRgTyp( sFolders, ch, rg, row, num2str( rtp ) )				// Make the connection between result 'rtp' and  Chan/Reg permanent in global list 'lstChRgTyp'
//	Construct1EvalPointInAcqWnd( sFolders, ch, rg, rtp )				// Construct  'wAcqPt'  .
//// 2006-0315
//	DrawAnalysisWndTrace( sWnd, sOLANm )							// from now on display this SrcRegionTyp in this window
//	DrawAnalysisWndXUnits( sWnd )	
//End



Function		SearchRow( wTxt, col, sTyp )
// Compute the row index of the listbox field to be highlighted (=selected)  from the  result type  chosen in the marquee menu when defining a region
	wave   /T	wTxt		
//	variable	nTrueCol											// this is the true lb column index including window columns
	variable	col												// this is the ChRegSrc column index but it is not the true lb column index as it ignores the intermediate window columns
	string  	sTyp
	variable	nChanCol	= col * (1+kMAX_OLA_WNDS)  					// this is the true lb column index of the ChRgTyp  column  (multiple window columns have 1 'nChanCol' ) 
	variable	row = 0, nRows = DimSize( wTxt, 0 )
	do 
		if ( cmpstr( wTxt[ row ][ nChanCol ] , sTyp ) == 0 )
			return	row
		endif
		row += 1
	while ( row < nRows )
	return	UFCom_kNOTFOUND
End


Function		lbResSelOAProc( s ) : ListBoxControl
// Dispatches the various actions to be taken when the user clicks in the Listbox. At the moment only mouse clicks and the state of the CTRL, ALT and SHIFT key are processed.
// At the moment the actions are  1. colorise the listbox fields  2. add result to  or remove result from window.  Note: if ( s.eventCode == UFCom_LBE_MouseUp  )	does not work here like it does in the data sections listbox ???
	struct	WMListboxAction &s
// 2009-10-29
if (  s.eventCode != UFCom_kEV_ABOUT_TO_BE_KILLED )
	string  	sFolders		= "acq:pul"
	wave	wFlags		= $"root:uf:" + sFolders + ":wSRFlags"
	wave   /T	wTxt			= $"root:uf:" + sFolders + ":wSRTxt"
	string  	sPlaneNm		= "BackColors" 
	variable	pl			= FindDimLabel( wFlags, 2, sPlaneNm )
	variable	nOldState		= UFPE_LBState( wFlags, s.row, s.col, pl )						// the old state
	string  	lstCol2ChRg 	= GetUserData( 	s.win,  s.ctrlName,  "lstCol2ChRg" )		// e.g. for 2 columns '0,0;1,2;'  (Col0 is Ch0Rg0 , col1 is Ch1Rg2) 
	string  	lstOlaRes	 	= GetUserData( 	s.win,  s.ctrlName,  "lstOlaRes" )			// e.g. 'Base_00A;Peak_00B;F0_A0_01B;' : which OLA results in which OLA windows

	//.......na............... Convert the modifying key (e.g. 'Ctrl' ,  'Ctrl Alt / Alt Gr' ) to a state = color  (e.g. select for file, for print or for both )  
	variable	nState		= UFPE_LBModifier2State( s.eventMod, UFPE_lstMOD2STATE1)			//..................na.......NoModif:cyan:3:Tbl+Avg ,  Alt:green:2:Avg ,  Ctrl:1:blue:Tbl ,   AltGr:cyan:3:Tbl+Avg 

	 printf "\t\tlbSelResOAProc( s ) 1\trow:%2d\tcol:%2d  evCode:%2d\tevModif:%2d\toldstate:%2d -> %2d \tlstColChans:'%s' \r", s.row , s.col, s.eventCode, s.eventMod,  nOldState, nState, lstCol2ChRg

	//  Construct or delete  'wAcqPt'  . This wave contains just 1 analysed  X-Y-result point which is to be displayed in the acquisition window over the original trace as a visual check that the analysis worked.  
	variable	ch		= LbCol2Ch( s.col, kMAX_OLA_WNDS )					// the column of the channel (ignoring all additional window columns)
	variable	w		= LbCol2Wnd( s.col, kMAX_OLA_WNDS )	
	string  	sChRg	= StringFromList( ch, lstCol2ChRg )						// e.g. '0,0;1,2;'  ->  '1,2;'
	string  	sWndAcq	= FindFirstWnd_a( ch )

	variable	rg		= UFPE_ChRg_2Rg( sChRg )									// e.g.  Base , Peak ,  F0_A1, Lat1_xxx ,  Quotxxx
	string  	sTyp		= wTxt[ s.row ][ LbCol2TypCol( s.col, kMAX_OLA_WNDS ) ]		// retrieves type when any window column  in any channel/region is clicked
	variable	rtp		= UFPE_WhichListItemIgnorWhiteSp( sTyp, UFPE_klstEVL_RESULTS ) 	// e.g. UFPE_kE_Base=15,  UFPE_kE_PEAK=25  todo fits......
	string  	sWndOla
	string  	sSrc		= StringFromList( ch, LstChan_a(), UFCom_ksSEP_TAB )
// 2006-0315
//	string  	sOlaNm 	= OlaNm( sSrc, sTyp, rg ) 								// e.g. 
	string  	sOlaNm 	= OlaNm1( sTyp, ch, rg ) 								// e.g. 'Peak_00'
	string  	sOlaNmW 	= OlaNmW( sTyp, ch, rg, w ) 							// e.g. 'Peak_00A'

	// Sample : sControlNm  'root_uf_acq_ola_wa_Adc1Peak_WA0'  ,    boolean variable name : 'root:uf:acq:ola:wa:Adc1Peak_WA0'  , 	sOLANm: 'Adc1Peak'  ,  sWnd: 'WA0'

	// MOUSE : SET a  cell. Click in a cell  in any row or column. Depending on the modifiers used, the cell changes state and color and stay in this state. It can be reset by shift clicking again or by globally reseting all cells.
	if ( s.eventCode == UFCom_LBE_MouseDown  &&  !( s.eventMod & UFCom_kMD_SHIFT ) )	// Only mouse clicks  without SHIFT  are interpreted here.  // ??? In this listbox only MouseDown is detected, whereas in the similar  DataSections  listbox  MouseUp  is detected???
		 UFPE_LBSet5( wFlags, s.row, s.row, s.col, pl, nState )				// sets flags .  The range feature is not used here so  begin row = end row .
		// printf "\t\tlbSelResOAProc( s ) 2\trow:%2d\tcol:%2d  evCode:%2d\tevModif:%2d\tstate:%2d =?=%2d  \r",  s.row, s.col,  s.eventCode, s.eventMod, nState, UFPE_LBState( wFlags, s.row, s.col, pl )	
		if ( w == 0 ) 													//  A  SrcRegTyp  column cell has been clicked  : ignore  clicks 
			 printf "\t\tlbSelResOAProc( Ignore\trow:%2d\tcol:%2d  evCode:%2d\tevModif:%2d\toldstate:%2d -> %2d \tlstColChans:'%s' -> ch:%2d  rg.%2d  w:%2d [%s]  '%s'\t'%s'\t   \r", s.row , s.col, s.eventCode, s.eventMod,  nOldState, nState, lstCol2ChRg, ch, rg, w,  sOlaNm, sOlaNmW
		else
			if ( FindListItem( sOlaNmW, lstOlaRes ) == UFCom_kNOTFOUND )
				lstOlaRes	= AddListItem( sOlaNmW, lstOlaRes )			// add to list only once (even if the user clicks multiple times on the same cell)
	
			// TODO Sort list according to channel/region : this avoids unnecessary calculations of  Base and peak in  OLA1Point()
	
				ListBox 	  $s.ctrlname,    win = $s.win, 	userdata( lstOlaRes ) = lstOlaRes
			endif

			sWndOla		= PossiblyAddAnalysisWnd( w-1 )
			 printf "\t\tlbSelResOAProc( ADD 4\trow:%2d\tcol:%2d  evCode:%2d\tevModif:%2d\toldstate:%2d -> %2d \tlstColChans:'%s' -> ch:%2d  rg.%2d  w:%2d [%s]  '%s'\t'%s'\t'%s'\t   \r", s.row , s.col, s.eventCode, s.eventMod,  nOldState, nState, lstCol2ChRg, ch, rg, w, sWndOla, sOlaNm, sOlaNmW, lstOlaRes

			// 2006-0316 Base and peak are already auto-constructed so we might avoid constructing them here
			if ( rtp != UFCom_kNOTFOUND )// do not process fits, lats, ...
				UFPE_EvPntSetShape( sFolders, ch, rg, rtp, sWndAcq )
			endif
// 2006-0315
			DrawAnalysisWndTrace( sWndOla, sOLANm, rtp )							// from now on display this SrcRegionTyp in this window
			DrawAnalysisWndXUnits( sWndOla )	
		endif

	endif

	// MOUSE :  RESET a cell  by  Shift Clicking
	if ( s.eventCode == UFCom_LBE_MouseDown  &&  ( s.eventMod & UFCom_kMD_SHIFT ) )			// Only mouse clicks  with    SHIFT  are interpreted here.  // ??? In this listbox only MouseDown is detected, whereas in the similar  DataSections  listbox  MouseUp  is detected???
		nState		= 0											// Reset a cell  
		 UFPE_LBSet5( wFlags, s.row, s.row, s.col, pl, nState )						// sets flags .  The range feature is not used here so  begin row = end row .
		// printf "\t\tlbSelResOAProc( s ) 3\trow:%2d\tcol:%2d  evCode:%2d\tevModif:%2d\tstate:%2d =?=%2d  \r",  s.row, s.col,  s.eventCode, s.eventMod, nState, UFPE_LBState( wFlags, s.row, s.col, pl )	
		sWndOla	= AnalWndNm( w-1 )
		if ( w > 0 ) 													//  A  Window column cell has been clicked  ( ignore  clicks into  the  SrcRegTyp column)
			if ( FindListItem( sOlaNmW, lstOlaRes ) != UFCom_kNOTFOUND )
				lstOlaRes	= RemoveFromList( sOlaNmW, lstOlaRes )			// remove from list only if the entry exists (even if the user shift clicks multiple times on the same cell)
				ListBox 	  $s.ctrlname,    win = $s.win, 	userdata( lstOlaRes ) = lstOlaRes
			endif
			variable	nUsed	= OlaWindowIsUsedTimes( w, lstOlaRes )		// Check if any other SrcRegTyp still uses this window. Only if no other SrcRegTyp uses this window we can remove not only the trace but also the window 

// 2006-0313 wrong: the point should only be deleted if it appears in no other window
			 printf "\t\tlbSelResOAProc( DEL 1\trow:%2d\tcol:%2d  evCode:%2d\tevModif:%2d\toldstate:%2d -> %2d \tlstColChans:'%s' -> ch:%2d  rg.%2d  w:%2d [%s] [used:%2d] \t'%s'\t'%s'\t'%s'\t   \r", s.row , s.col, s.eventCode, s.eventMod,  nOldState, nState, lstCol2ChRg, ch, rg, w,  sWndOla, nUsed, sOlaNm, sOlaNmW, lstOlaRes
			if ( rtp != UFCom_kNOTFOUND )// do not process fits, lats, ...
				UFPE_EvPntHide( sFolders, ch, rg, rtp, sWndAcq )					// Hide : Remove this  Typ from this window
			endif
		endif
	
// 2006-0313	// Remove the OLA trace from the OLA window  A, B or C 
// 2006-0327 ???
		if ( WinType( sWndOla ) == UFCom_WT_GRAPH )								// check if the graph exists but...
			RemoveFromGraph  /Z  /W=$sWndOla		$sOLANm  			// ...do  not check if the trace exists ( /Z avoids complaints if the user tries to remove a non-existing trace )
	
	// 2006-0315
	//		// Check if any other SrcRegTyp still uses this window. Only if no other SrcRegTyp uses this window we can remove not only the trace but also the window 
	//		variable	nUsed	= 0
	//		variable	c, nCols	= ItemsInList( lstCol2ChRg ) 					// the number of SrcRegTyp columns (ignoring any window columns) 
	//		for ( c = 0; c < nCols; c += 1 )
	//			variable	nTrueCol	= c * ( kMAX_OLA_WNDS + 1 ) + w  
	//			variable	r, nRows	= DimSize( wTxt, 0 )					// or wFlags
	//			for ( r = 0; r < nRows; r += 1 )
	//				nUsed += ( UFPE_LBState( wFlags, r, nTrueCol, pl ) != 0 )
	//				// printf "\t\tlbSelResOAProc( DEL 3\tr:%2d/%2d\tcol:%2d  evCode:%2d\tevModif:%2d\toldstate:%2d -> %2d \tlstColChans:'%s' -> ch:%2d  rg.%2d  w:%2d  kEIdx:%3d   '%s' -> State:%2d   Used:%2d \r", r, nRows, nTrueCol, s.eventCode, s.eventMod,  nOldState, nState, lstCol2ChRg, ch, rg, w, rtp, sTyp, UFPE_LBState( wFlags, r, nTrueCol, pl ), nUsed
	//			endfor
	//		endfor
			sWndOla	= AnalWndNm( w-1 )
			if ( nUsed == 0 )
				KillWindow $sWndOla
			endif
		endif

		string  sTxt   = "Window '" + sWndOla + "' (still) used " + num2str( nUsed ) + " times. " + SelectString( nUsed, "Will", "Cannot" ) + " delete window."
		 printf "\t\tlbSelResOAProc( DEL 4\trow:%2d\tcol:%2d  evCode:%2d\tevModif:%2d\toldstate:%2d -> %2d \tlstColChans:'%s' -> ch:%2d  rg.%2d  w:%2d [%s] kEIdx:%3d   '%s' -> %s  \r", s.row , s.col, s.eventCode, s.eventMod,  nOldState, nState, lstCol2ChRg, ch, rg, w, sWndOla, rtp, sTyp, sTxt
	endif

	// Check if a  QDP field has been clicked (=click in row  Q0, Q1, Q2, D0....P1, P2   ONLY  in column 0 [here: ch=0] ) : this will open the QDPSources select listbox.
	// If a column > 0 in a QPD row has been clicked the user wants to add the QPD result to the corresponding window.  This case is handled above.
	if ( ch == 0  &&  IsQDP( sFolders, wTxt[ s.row ][ 0 ] ) )				// Binary derived results (=Quot,Diff,Product) exist only once so for the  channel and for the region only the dummy index 0 exists.
		string  	sQDPBase= QDPNm2Base( wTxt[ s.row ][ 0 ]  )		// e.g. 'Qu1'  -> 'Qu' 	
		variable	nQDPIdx	= QDPNm2Nr( wTxt[ s.row ][ 0 ]  )		// e.g. 'Qu1'  -> '1' 	

		if ( s.eventCode == UFCom_LBE_MouseDown  &&  !( s.eventMod & UFCom_kMD_SHIFT ) )	// Only mouse clicks  without SHIFT  are interpreted here.  For some reason in this listbox only MouseDown is detected, whereas in the similar  DataSections  listbox  MouseUp  is detected???
			printf "\t\ttlbSelResOAProc( QDP+5\trow:%2d\t'%s'\t'%s'\tnQDPIdx:%2d\t \r", s.row, wTxt[ s.row ][ 0 ], sQDPBase, nQDPIdx
			LBSelectQDPSources( sFolders )
		else
			printf "\t\ttlbSelResOAProc( QDP-6\trow:%2d\t'%s'\t'%s'\tnQDPIdx:%2d\t \r", s.row, wTxt[ s.row ][ 0 ], sQDPBase, nQDPIdx
		endif
	endif

endif
End


//Function 		Test()
//	string  	sFolders		= "acq:pul"
//	string  	sWin			= ksPN_NAME
//	string  	sCtrlName		= "lbSelectResult"
//	string  	lstOlaRes		= ExtractLBSelectedWindows( sFolders, sWin, sCtrlName )
//	ListBox 	  $sCtrlname,    win = $sWin, 	userdata( lstOlaRes ) = lstOlaRes
//End

Function	/S	ExtractLBSelectedWindows( sFolders, sWin, sCtrlName )
	string  	sFolders, sWin, sCtrlName
	wave	wFlags		= $"root:uf:" + sFolders + ":wSRFlags"
	wave   /T	wTxt			= $"root:uf:" + sFolders + ":wSRTxt"
	string  	sPlaneNm		= "BackColors" 
	variable	pl			= FindDimLabel( wFlags, 2, sPlaneNm )
	string  	lstCol2ChRg 	= GetUserData( 	sWin,  sCtrlName,  "lstCol2ChRg" )			// e.g. for 2 columns '0,0;1,2;'  (Col0 is Ch0Rg0 , col1 is Ch1Rg2) 
	variable	c, nCols		= ItemsInList( lstCol2ChRg ) 							// the number of SrcRegTyp columns (ignoring any window columns) 
	variable	w, nWState													// w=0 is the  'SrcRegTyp' column ,   w=1,2,3  are the windows A,B,C
	variable	ch, rg, nTrueCol, r, nRows	
	string  	sOlaNmW, lstOlaRes = ""														// e.g. 'Peak_00A'
	for ( c = 0; c < nCols; c += 1 )
		ch		= str2num( StringFromList( 0, StringFromList( c, lstCol2ChRg ) , "," ) )	
		rg		= str2num( StringFromList( 1, StringFromList( c, lstCol2ChRg ) , "," ) )	
		w		= 0
		nTrueCol	= c * ( kMAX_OLA_WNDS + 1 ) + w  
		nRows	= DimSize( wTxt, 0 )							// or wFlags
		for ( r = 0; r < nRows; r += 1 )
			if ( strlen( wTxt[ r ][ nTrueCol ] ) )										// process only those window cells (A,B.C) whose RegSrcTyp column is not empty
				for ( w = 1; w < kMAX_OLA_WNDS + 1; w += 1 )
					nWState	= UFPE_LBState( wFlags, r, nTrueCol+w, pl )
					if ( nWState )
						sOlaNmW 	= OlaNmW( wTxt[ r ][ nTrueCol ], ch, rg, w ) 			// e.g. 'Peak_00A'
						lstOlaRes	= AddListItem( sOlaNmW, lstOlaRes )
						// printf "\t\tExtractLBSelectedWindows(a)\tr:%2d/%2d\tc:%2d/%2d\tTCol:%2d\tlstColChans:'%s' -> ch:%2d  rg.%2d  w:%2d\t%s\t-> WState:%2d\t-> \t%s\t%s   \r", r, nRows, c, nCols, nTrueCol, lstCol2ChRg, ch, rg, w, UFCom_pd( wTxt[ r ][ nTrueCol ], 8), nWState, UFCom_pd(sOlaNmW,13), lstOlaRes
					endif
				endfor
			endif
		endfor
	endfor
	 printf "\t\tExtractLBSelectedWindows(b) '%s'   \r", lstOlaRes
	return	lstOlaRes
End

Function		OlaWindowIsUsedTimes( w, lstOlaRes )
	variable	w
	string  	lstOlaRes
	variable	nUsed	= 0
	variable	n, nItems	= ItemsInList( lstOlaRes )
	for ( n = 0; n < nItems; n += 1 )	
		nUsed	+= WindowMatches( w, StringFromList( n, lstOlaRes ) )
	endfor
	return	nUsed
End

Function		WindowMatches( w, sOneType_ChRgWnd )
	variable	w
	string  	sOneType_ChRgWnd						// e.g.  'Peak_01A'
	variable	len			= strlen( sOneType_ChRgWnd )
	string  	sLastCharacter	= sOneType_ChRgWnd[ len-1, len-1 ]
	return	! abs( cmpstr( AnalWndNm( w-1 ), sLastCharacter ) )
End




Function	/S	ListACVAllChansOA()
// Returns list of titles of  'All Currently Computed Values'  which depends on the number of regions, the number and types of the fits and on the latencies, but not yet on the listbox
	variable	ch
	variable	nChans		= ItemsInList( LstChan_a(), UFCom_ksSEP_TAB )
	string 	lstACVAllCh	= ""
	for ( ch = 0; ch < nChans; ch += 1 )
		lstACVAllCh	+= ListACVOA( ch )
	endfor
	// printf "ListACVAllChansOA()  \t\t\tItms:%2d\t'%s...%s \r", ItemsInList( lstACVAllCh ),  lstACVAllCh[0,80],  lstACVAllCh[ strlen( lstACVAllCh )-80, inf ]  
	return	lstACVAllCh
End

Function	/S	ListACVOA( ch )
// Returns complete list of titles of  'All Currently Computed Values'  which depends on the number of regions, the number and types of the fits and on the latencies, but not yet on the listbox
	variable	ch
	string  	sFolders	= ksF_ACQ_PUL 
	variable	nRegs	= UFPE_RegionCnt(  sFolders, ch )
	variable	rg
	string  	lstACV	= ""
	for ( rg = 0; rg < nRegs; rg += 1 )
		lstACV	+= ListACV1RegionOA( ch, rg )
	endfor
	// printf "\t\tListACVOA(  \tch:%2d )  \t\t\t\t\tItms:%2d\t'%s' ... '%s'   \r", ch, ItemsInList( lstACV ), lstACV[0,80],  lstACV[ strlen( lstACV )-80, inf ]  
	return	lstACV
End

Function	/S	ListACV1RegionOA( ch, rg )
// Returns complete list of titles of  'All Currently Computed Values'  which depends on the number of regions, the number and types of the fits, but not yet on the listbox
	variable	ch, rg
	string  	sFolders	= ksF_ACQ_PUL
	variable	nChans	= ItemsInList( LstChan_a(), UFCom_ksSEP_TAB )
	variable	LatCnt	= LatCnt_a() 
	string  	lstACV	= ""
	lstACV	+= ListACVGeneralTableOLA( sFolders, ch, rg )			
	lstACV	+= ListACVFitOLA( sFolders, ch, rg )					// generic.....not yet...???...
	lstACV	+= ListACVLat( sFolders, ch, rg, nChans, LatCnt )			// generic
	if ( ch == 0  &&  rg == 0 )
		lstACV	+= ListACV_QDP( sFolders , ch, rg ) 				// binary derived results (=Quot,Diff,Product) exist only once so the  channel/region concept is useless. Alternate approach (not taken): construct separate single column listbox only for QDP.
	endif
	// printf "\t\tListACV1OA(\tch:%2d/%2d  rg:%2d  LC:%2d    ) \tItms:%2d\t'%s' ... '%s'   \r", ch, nChans, rg, LatCnt, ItemsInList( lstACV ), lstACV[0,80],  lstACV[ strlen( lstACV )-80, strlen( lstACV )-1 ]  
	return	lstACV
End

//-----------------------------------------------------------------------------------


Function	/S	ListACVGeneralTableOLA( sFolders, ch, rg )
// Returns complete list of titles of the general (=Non-fit)  'All Currently Computed Values'  which depends on the number of regions, the number and types of the fits, but not yet on the listbox
	string  	sFolders			// e.g. 	'acq:ola'  or  'eva:de'
	variable	ch, rg
	string  	sPostfx		= UFPE_ChRgPostFix( ch, rg )
	string		lst			= ""
// todo possibly : use other selection parameters than  UFPE_klstEVL_SHAPES
	variable	shp, pt, nPts	= ItemsInList( UFPE_klstEVL_RESULTS )
	for ( pt = 0; pt < nPts; pt += 1 )
		shp	= str2num( StringFromList( pt, UFPE_klstEVL_SHAPES ) )					// 
		if ( numtype( shp ) != UFCom_kNUMTYPE_NAN ) 								// if the shape entry is not empty it must be drawn
			lst	= AddListItem( UFPE_EvalNm( pt ) + sPostfx, lst, ";", inf )					// the general values : base, peak, etc
		endif
	endfor

	return	lst
End

Function	/S	ListACVFitOLA( sFolders, ch, rg )
// Returns list of all FitParameters, FitStartParameters and FitInfoNumbers (e.g. nIter, ChiSqr)  for the fit function specified by channel and region 
	string  	sFolders			// e.g. 	'acq:ola'  or  'eva:de'
	variable	ch, rg
	string  	lst		= ""	
	variable	fi, nFits	=  FitCnt_a()
	for ( fi = 0; fi < nFits; fi += 1 )
		if ( UFPE_DoFit( sFolders, ch, rg, fi, LatCnt_a() ) )
			lst	= ListACVFitOA( lst, sFolders, ch, rg, fi )
		endif
	endfor
	// printf "\t\tListACVFitOLA(\t'%s'\tch:%2d, rg:%2d  )  \tItms:%2d\t'%s'  \r", sFolders, ch, rg, ItemsInList( lst ), lst[0,200]
	return	lst
End	

Function	/S	ListACVFitOA( lst, sFolders, ch, rg, fi )
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
	// printf "\t\tListACVFitOA(\t'%s'\tch:%2d, rg:%2d, fi:%2d )\tItms:%2d\t'%s'  \r", sFolders, ch, rg, fi, ItemsInList( lst ),  lst[0,200]
	return	lst
End


Function		fOLAXAxis( s )
	struct	WMPopupAction	&s
	 printf "\tfOLAXAxis()   control is '%s'   bValue:%d \r", s.Ctrlname, 123
	string  	sControlNm
	variable	bValue
	RedrawAnalysisWndAllTraces()
End

Function		fXAxisPops_a( sControlNm, sFo, sWin )
	string		sControlNm, sFo, sWin
	PopupMenu	$sControlNm, win = $sWin,	   value = 	lstXPANEL
End


Function		RedrawAnalysisWndAllTraces()
// 2006-0321 revive again
//	variable	w, wCnt		= ItemsInList( AnalysisWindows() )
//	for ( w = 0; w < wCnt;  w += 1 )
//		string  	sWNm	= StringFromList( w, AnalysisWindows() )
//		if ( WinType( sWNm ) == UFCom_WT_GRAPH )
//			string  	sTNL	= TraceNameList( sWNm, ";", 1 )
//			variable	t,  tCnt	=  ItemsInList( sTNL ) 
//			 printf "\t\tRedrawAnalysisWndAllTraces() \twnd:%s has %d traces   [TrcNmList: %s..] \r", sWNm, tCnt, sTNL[0,160]	
//			for ( t = 0;  t < tCnt; t += 1 )	
//				string  	sTrc		= StringFromList( t, sTNL ) 	
//				DrawAnalysisWndTrace( sWNm, sTrc )
//			endfor
//			DrawAnalysisWndXUnits( sWNm )	
//		endif
//	endfor
End

Function		fClearAnalysisWnd( s )
	struct	WMButtonAction	&s
	ClearAnalysisWnd()
End


Function		fBlankPause( s )
// 2006-0228 THIs is wrong : points are swallowed.................
	struct	WMCheckboxAction	&s
	string  	sFolders	= ksF_ACQ_PUL 
	 printf "\t   TODO....fBlankPause()   control is '%s'    bValue:%d  sFolder:%s \r", s.Ctrlname, s.checked, sFolders
	string  	lstOlaNm, sOLANm, sSrc, sEventNm	= "Evnt"					// Flaw / Assumption
	wave	wEvent		= $FolderOlaDispNm( sEventNm ) 	
	variable	nType, n, nPts	= numPnts( wEvent )
//	variable	nP, t , tCnt	= RegionPhsCnt()	
//	variable	nP, tCnt	= 1

	string  	sChans	= LstChan_a()

// 2006-0317e weg
// 2006-0315
//	svar		lstChRgTyp = $"root:uf:" + sFolders + ":lstChRgTyp"			// e.g. ',,,15,,25,,;,,15,;°,,3,,,4,,,;,,5,,,6,,;°,1,,,0,,;0,,2,;'
//	variable	ch, nChans	= ItemsInList( lstChRgTyp, UFCom_ksSEP_TAB )
//	for ( ch = 0; ch <  nChans; ch += 1 )
//		string  	lst1Chan	= StringFromList( ch, lstChRgTyp, UFCom_ksSEP_TAB )
//		sSrc		= StringFromList( ch, sChans, UFCom_ksSEP_TAB )
//		variable	rg, nRegions	= ItemsInList( lst1Chan, ";" )	// = RegionCnt( sFolders, ch )			// For all  channel/region combinations  which the user has defined 
//		for ( rg = 0; rg <  nRegions; rg += 1 )									// For all  channel/region combinations  which the user has defined 
//			string  	lst1Region	= StringFromList( rg, 	lst1Chan, 	";" )
//
//			variable	t, nTypes	= ItemsInList( lst1Region, UFCom_ksSEP_STD )
//			for ( t = 0; t <  nTypes; t += 1 )	
//				string  	sTyp	= StringFromList( t, lst1Region, UFCom_ksSEP_STD ) 								// For all  channel/region combinations  which the user has defined 
//				if ( strlen( sTyp ) )
//					variable	rtp	= str2num( sTyp )
//					string  	sName	= RemoveLeadingWhiteSpace( StringFromList( rtp, UFPE_klstEVL_RESULTS ) )	// rtp=rtp
//// 2006-0315
//				 	sOlaNm 	= OlaNm( sSrc, sName, rg ) 
//					wave	wOlaDisp	= $FolderOlaDispNm( sOLANm ) 	
//					if ( ! s.checked )													// Fill the pauses = connect data points even during pauses....
//						for ( n = 0; n < nPts - 1; n += 1 )
//							if ( numType( wOlaDisp[ n ] ) == UFCom_kNUMTYPE_NAN )
//								wOlaDisp[ n ]	= wOlaDisp[ n + 1] 						// Fill the pauses : reset the Nan Y value to that of the successor point...
//								wEvent [ n ]	= wEvent[ n + 1 ]						//...reset the X value to that of  the successor point as a marker..   Done too often , once would be sufficient....						
//							endif													// ..the event is changed not for the display but to have a marker which points must be restored
//						endfor
//					else												//	s.checked = UFCom_TRUE										// Blank the pauses...
//						for ( n = 0; n < nPts - 1; n += 1 )
//							if ( wEvent [ n ] ==  wEvent[ n + 1 ] )							// These points are marked and must be restored
//								wOlaDisp[ n ]	=  Nan								// Blank the pauses: first set the Y values to Nan ...
//							endif							
//						endfor
//					endif
//				endif
//			endfor
//		endfor
//	endfor
//	if ( s.checked )													// Fill the pauses = connect data points even during pauses....
//		for ( n = 0; n < nPts - 1; n += 1 )
//			if ( wEvent [ n ] ==  wEvent[ n + 1 ] )								// These points are marked and must be restored
//				wEvent [ n ]	=  wEvent[ n ] - 1 							// then set the X value to the value of the precessor point				
//			endif							
//		endfor
//	endif
End



Static  Function		DrawAnalysisWndTrace( sWNm, sOLANm, rtp )
	string  	sWNm, sOLANm
	variable	rtp
	variable	rnType
	wave	wRed = root:uf:acq:misc:Red, wGreen = root:uf:acq:misc:Green, wBlue = root:uf:acq:misc:Blue
	nvar		bBlankPause	= root:uf:acq:pul:bBlankPause0000
	nvar		nXAxis		= root:uf:acq:pul:pmXAxis0000
	string  	lstColors		= UFCom_RemoveWhiteSpace( UFCom_lstCOLORS )
	variable	nMode, nColor	= WhichListItem( UFCom_RemoveWhiteSpace( StringFromList( rtp, UFPE_klstEVL_COLORS ) ), lstColors )
	string  	sTraceInfo, rsSrc
		
	if ( WhichListItem( sOLANm, TraceNameList( sWNm, ";", 1 ) )  != UFCom_kNOTFOUND )	
		sTraceInfo	= TraceInfo( sWNm, sOLANm, 0 )						// The trace exists and the color and mode are retrieved directly from the trace (called when switching the X axis scaling)
		nMode	= NumberByKey( "mode(x)", sTraceInfo, "=" )
	endif

	 printf "\t\t\tDrawAnalysisWndTrace( %s\t%s\tnRes: %d )   Rgb:\t%7d\t%7d\t%7d\t  Mode: %d    \t'%s' \tXAxis:%d BlankP:%d  \r", sWNm, UFCom_pd( sOLANm,9),  1234, wRed[ nColor ], wGreen[ nColor ], wBlue[ nColor ], nMode, "root:uf:acq:ola:wa:" + sOLANm + "_" + sWNm,  nXAxis, bBlankPause

	// The waves to be appended should exist already before the user started the first acquisition.
	wave  /Z	wOlaDisp	= 	$FolderOlaDispNm( sOLANm ) 	 				
	if ( ! waveExists( wOlaDisp ) )
		UFCom_InternalError( "DrawAnalysisWndTrace(): Does not exist : '" + FolderOlaDispNm( sOLANm ) ) 	
	endif
	string  	sEvntSecMin	= StringFromList( nXAxis-1, lstRESfix )				// 'Evnt' , 'Tim_'  or 'Minu'	
	wave   /Z	wX			= $FolderOlaDispNm( sEvntSecMin )				//  X  AXIS  is  frames, seconds or minutes
	if ( waveExists( wX ) )
		AppendToGraph /W=$sWNm	wOlaDisp vs  wX
		ModifyGraph 	/W=$sWNm	rgb( 	$sOLANm )	= ( wRed[ nColor ], wGreen[ nColor ], wBlue[ nColor ] ) 
		ModifyGraph	/W=$sWNm	mode( $sOLANm )	= nMode 			// 4: connect and mark points with +, 3 : only markers +
	endif

End


Function		DrawAnalysisWndXUnits( sWNm )
	string  	sWNm
	nvar		nXAxis	= root:uf:acq:pul:pmXAxis0000
	string  	sXUnits	= StringFromList( nXAxis-1, lstXUNITS )				// As Igor does not plot units automatically in the XY mode (like in the normal mode using 'SetScale x ' )...
	TextBox /W=$sWNm /N=tbXAxis /C /A=MB /E=2  /F=0	/Y=0  sXUnits	//...we display the units  's' , 'frame', ... as a Textbox
End


//Function		buAnalPrintRegions( ctrlName ) : ButtonControl
//	string 	ctrlName
//	PrintRegions()
//End


//=======================================================================================================================================================

//static strconstant	csANALWNDBASE	= "A"	// The name should NOT start with 'W' as any window will be erased by  'KillTracesInMatchingGraphs( "W*" )'  when a script is loaded or applied
static constant			kWNDDIVIDER			= 75		// 15..100 : x position of a window separator if graph display area is to be divided in two columns

static  Function	/S	AnalWndNm( w )
	variable	w
	// return	csANALWNDBASE + num2str( w )		// A0, A1  or  W0, W1...	needs  kLBOLA_COLWID_WND = 20
	// return	num2char( 97 + w )					// a, b, c...			needs  kLBOLA_COLWID_WND = 12
	return	num2char( 65 + w )					// A, B, C...			needs  kLBOLA_COLWID_WND = 14
End

// currently not needed
//Function		AnalWndNm2W( sWNm )
//	string  	sWNm	
//	//return	str2num( sWNm[ 1, inf ]				// A0, A1  or  W0, W1...	needs  kLBOLA_COLWID_WND = 20
//	//return	char2num( sWNm ) - 97				// a, b, c...			needs  kLBOLA_COLWID_WND = 12
//	return	char2num( sWNm ) - 65				// A, B, C...			needs  kLBOLA_COLWID_WND = 14
//End

static  Function  /S	AnalysisWindows()
// returns list of OLA result windows
	variable	w
	string  	sWNm, sWinList = ""
	// sWinList	= WinList( csANALWNDBASE + "*" , ";" , "WIN:1" )	// Special case: works only for graph window names starting with csANALWNDBASE  e.g. 'A*'  or  'W*'
	for ( w = 0; w < kMAX_OLA_WNDS; w += 1 )					// General case: 
		sWNm	 =  AnalWndNm( w )							// works for graph window names starting with csANALWNDBASE  e.g. 'A*'  or  'W*' ....
		if ( ( WinType( sWNm ) == UFCom_WT_GRAPH ) )						//  ...and also works for graph window names e.g.  'A' , 'B' , 'C'
			sWinList	+= sWNm + ";"
		endif	
	endfor
	 printf "\t\tAnalysisWindows() returns sWinList: '%s' \r", sWinList
	return	sWinList
End


static  Function	/S	PossiblyAddAnalysisWnd( w )
// Construct and display  1 additional  Analysis windows with the next default name
	variable	w
	variable	wCnt		= kMAX_OLA_WNDS
	string 	sWNm	= AnalWndNm( w )
	variable	rnLeft, rnTop, rnRight, rnBot										// place the window in top half to the right of the acquisition windows 
	UFCom_GetAutoWindowCorners( w, wCnt, 0, 1, rnLeft, rnTop, rnRight, rnBot, kWNDDIVIDER, 100 )	// row, nRows, col, nCols
	if (  ! ( WinType( sWNm ) == UFCom_WT_GRAPH ) )										//  There is no 'Analysis' window
		Display /K=2 /N=$( sWNm ) /W= ( rnLeft, rnTop, rnRight, rnBot ) 					// K=2 : disable killing	 . The user must kill a window with button 'Remove' to preserve ordering.	
	endif
	return	sWNm
End


static	  Function		ClearAnalysisWnd()
// the waves are not really killed (but could be should ever need arise) , only the flag is set telling that the waves need to be rebuilt.
	nvar		gOLAFrmCnt	= root:uf:acq:ola:gOLAFrmCnt
	nvar		gnStartTicksOLA= root:uf:acq:ola:gnStartTicksOLA

	gOLAFrmCnt		= 0
	gnStartTicksOLA	= ticks							// Resetting the ticks here will start the clock after the first region has been defined ( probably better: when acquisition starts )  

	variable	w, wCnt	= ItemsInList( AnalysisWindows() )
	for ( w = 0; w < wCnt;  w += 1 )
		string  	sWNm	= StringFromList( w, AnalysisWindows() )

		if ( WinType( sWNm ) == UFCom_WT_GRAPH )
			string 	sTNL	= TraceNameList( sWNm, ";", 1 )
			variable	t,   tCnt	=  ItemsInList( sTNL ) 
			printf "\t\tClearAnalysisWnd()  wnd:%s has %d traces   [TrcNmList: %s..] \r", sWNm, tCnt, sTNL[0,160]	
			for ( t = 0;  t < tCnt; t += 1 )			
				wave	wv	= TraceNameToWaveRef(  sWNm, StringFromList( t, sTNL ) )	// !!!
				redimension  /N = 0   wv
			endfor
		endif
	endfor
End


//=======================================================================================================================================================
//  CALLED  REGULARLY  DURING  ACQUISITION

static Function		AnalysisIsOn()
// returns UFCom_TRUE when at least one user region is defined    or  UFCom_FALSE = 0  when no user region is defined
	return	UFCom_TRUE//RegionPhsCnt() > 0
End

// 2003-10-07  !    NOT  YET  REALLY  PROTOCOL  AWARE ............
Function		OnlineAnalysis( sFolders, pr, bl, lap, fr )
// This function is called once per frame  during acquisition from the background task. It is called in parallel to 'DispDuringAcqCheckLag()'  and  'WriteDatasection()'  
	string  	sFolders
	variable	pr, bl, lap, fr
	string  	sFolder	= StringFromList( 0, sFolders, ":" )
	variable	nSmpInt	= UFPE_SmpInt( sFolder )
	nvar		gOLAFrmCnt	  = root:uf:acq:ola:gOLAFrmCnt
	nvar		gnStartTicksOLA = root:uf:acq:ola:gnStartTicksOLA

	if (  AnalysisIsOn() )										// If no cUSER region is defined we skip the whole analysis (this must be refined if there are analysis types requiring no cUSER region)
		if ( gOLAFrmCnt	== 0 )
			gnStartTicksOLA	= ticks						// Resetting the ticks here will start the clock after the first region has been defined ( probably better: when acquisition starts )  
		endif
		if ( pr == 0  &&  bl == 0  &&  fr == 0 )						// Insert a pause for every new protocol by  inserting a Nan rather than data in the display trace.
			gOLAFrmCnt	+= 1	
			AppendNanInDisplayWave( gOLAFrmCnt, ksPN_NAME )// Inserting a Nan rather than data in the display trace marks those points as separators and allows blanking out intervals between protocols.	
		endif													
		gOLAFrmCnt	+= 1	
		OLA1Point( sFolders, nSmpInt, pr, bl, lap, fr, gOLAFrmCnt )			// 2005-12-10					
	endif
End												

// 2006-03-14
static Function		AppendNanInDisplayWave( index, sWin )
// Construct   ALL POSSIBLE  OLA display  waves (also those that are not displayed) . Construct them  with 1 Nan point to blank out the data point.
	variable	index
	string  	sWin
	string  	lstACVAllCh 	= GetUserData( 	sWin,  "",  "lstACVAllCh" )	
	
	AppendPointToTimeWaves( index )

	variable	len, n, nItems	= ItemsInList( lstACVAllCh )	
	// printf "\t\t\tAppendNanInDisplayWave\tlstACVAllCh has items:%3d <- \t '%s .... %s' \r", nItems, lstACVAllCh[0,80] , lstACVAllCh[ strlen( lstACVAllCh ) - 80, inf ]

	string 	sOneItemIndexed
	for ( n = 0; n < nItems; n += 1 )
		sOneItemIndexed	= StringFromList( n, lstACVAllCh )				// e.g. 'Base_010'
		NewElementOlaDisp( sOneItemIndexed, index ) 				// Returns UFCom_TRUE if a new wave has just been constructed.
	 	SetElementOlaDisp( sOneItemIndexed, index, Nan )			// Nan allows blanking out intervals between protocols.
	endfor
End



Function	/S	OlaNm( sSrc, sName, rg ) 					// OBSOLETE
	string	  	sSrc, sName
	variable	rg

// 2006-0314
	//return	sSrc + sName 							// e.g. 'Adc1Base'
//	return	sSrc + "_" + sName + "_" + num2str( rg ) 		// e.g. 'Adc1_Base_0'

// 2006-0315  WRONG
	string  	sOlaNm	= "Peak" + "_" + num2str( 0 ) + num2str( rg ) 		

	// printf "\t\t\tOlaNm %s %s %d    old: '%s'     new: '%s' \r",  sSrc, sName, rg , sSrc + "_" + sName + "_" + num2str( rg ) , sOlaNm
	return "Peak" + "_" + num2str( 0 ) + num2str( rg ) 		
End


Function	/S	OlaNm1( sTyp, ch, rg ) 							
	string  	sTyp
	variable	ch, rg
	string  	sOlaNm	= sTyp + "_" + num2str( ch ) + num2str( rg )					// e.g. 'Peak_00'
	return	sOlaNm
End


Function	/S	OlaNmW( sTyp, ch, rg, w ) 							
	string  	sTyp
	variable	ch, rg, w
	string  	sOlaNmW	= sTyp + "_" + num2str( ch ) + num2str( rg ) + AnalWndNm( w-1 )	// e.g. 'Peak_00A'
	return	sOlaNmW
End


Static  Function		OLANmR( sOLANm, rsSrc, rnType, sList )
// Extracts source  (e.g. Adc1)  and  type (e.g. 0 for Base)  from  name string constructed  with  OlaNmLst() .  This name string  MUST NOT contain spaces as Ola_NmLst()  would insert.
// Improvement 1 :  could be made independent of  spaces , underscores etc.  by applying  'RemoveStringFromString().....
// Improvement 2 :  could also extract  Fit parameter e.g    PoN0DcT1	could extraxt  PoN0 ,  Decay   and   Tau1
// ??? searching is perhaps too slow???
	string		sOLANM, &rsSrc, sList
	variable	&rnType
	variable	n
	rsSrc		= sOLANm[ 0, 3 ]										// Assumption : 2  Four-letter-groups,  e.g.  Adc1Base    or  PoN0Peak...
	rnType	= WhichListItem( sOLANm[ 4, 7 ] , sList )						// if complete 4 letter  group ( Base, Peak...)  is found  then return that index...
	if ( rnType == UFCom_kNOTFOUND )										// ...if not then it must be a combined 2 + 2 group used for fits e.g. DcA0   or RiT1
		for ( rnType = 0; rnType < ItemsInList( sList ); rnType += 1 )
			if ( cmpstr( StringFromList( rnType, sList )[ 0, 1 ],  sOLANm[ 4, 5 ] ) == 0 ) // compare 2 letters  (or supply a 2. 2-letter list e.g.  'Ba;Pe;Ba;Pe;Qu;RT;Ri;Dc'  and use WhichListItem()...) 
				break
			endif
		endfor
	endif
End



static Function		AppendPointToTimeWaves( index )
//  Construct the waves  'Evnt'  , 'Tim_'  and  'Minu'  which are used as  XAxis .   'Prot' , Blck' , 'Fram'  could be but are not constructed here as they are not needed for the display. 
	variable	index
	nvar		gnStartTicksOLA	= root:uf:acq:ola:gnStartTicksOLA
	variable	value, n, seconds	= ( ticks - gnStartTicksOLA ) / UFCom_kTICKS_PER_SEC
	for ( n = 0; n < ItemsInList( lstRESfix ); n += 1 )
		if ( n == cEVNT)				// Not very elegant, but Igor does not interpret nested conditional assignments correctly : WRONG : value = ( n == cEVNT )  ?  index - 1 : ( n == cTIME )   ?  seconds : seconds / 60	
			value	= index - 1 
		elseif ( n == cTIME )
			value	= seconds
		else	// n == cMINU 
			value	= seconds / 60
		endif
		string  	sOLANm	= StringFromList( n, lstRESfix ) 							
		// printf "\t\tAppendPointToTimeWaves\tindex:\t%3d   \tn: %d \t\t%s\t= %8.2lf\tseconds= %8.2lf\t\t ( sOlaNm: %s )\r", index, n, UFCom_pd( StringFromList( n, lstRESfix ), 12), value, seconds, sOlaNm
		NewElementOlaDisp( sOLANm, index )
		SetElementOlaDisp( sOLANm, index, value )				//  Add   'Event'  , 'Time'  and  'Minu'   to display wave . Starting at 0 allows to use this wave as XAxis
	endfor
	return	seconds
End


// 2005-1210 new
static Function	OLA1Point( sFolders, nSmpInt, pr, bl, lap, fr, index )
// Function for online evaluation
// Design issue: the OLA is frame-oriented : it is executed once every frame, sweeps are ignored 
	string  	sFolders
	variable	nSmpInt
	variable	pr, bl, lap, fr, index
	string  	sFolder		= StringFromList( 0, sFolders, ":" )

	nvar		gOLAHnd		= root:uf:acq:ola:gOLAHnd
	variable	bWriteMode	= WriteMode()
	string		sDataDir		= DataDir() 

	variable	BegPt		= UFPE_FrameBegSave( sFolder, pr, bl, lap, fr )		// could this simplify BResultXShift  ???? (see 070424)  SEE  SPREADCURSORS FOR A  DIFFERENT  APPROACH
	string  	lstOLANm, sOLANm, sOLANmBP 
//	string  	sLine 	= ""
	string  	lstFitResults	= ""
	variable	nP, n
	
	string  	sChans	= LstChan_a()

	variable	ch = 0, nChans	= ItemsInList( sChans ,  UFCom_ksSEP_TAB )

	variable	rg = 0, nRegions
	variable	nState = 1
	string  	lstIndices, lstNames, sName
	variable	t, nTypes
variable	value
variable	len, rtp
variable	Gain, SIFact, PkDir
string  	sWnd, sSrc, sType//, sXNm, sYNm, sFoXNm , sFoYNm 

	wave  	wOLARes	= $"root:uf:" + ksF_ACQ_PUL + ":wOLARes"				// is needed only for  temporary storage of peak and base to later compute Quot. 2 variables are sufficient?

//	printf "\t\t\tOLA1Point(a) \t\t\t\tpr: %d   bl: %d  fr: %d \tgOLAFrmCnt: %d\t\t'%s'\t'%s'  \r", pr, bl, fr, index, sFolder, sFolders
//
//	//  Step 1 :  Open  the OLA file
//	if ( gOLAHnd == kNOT_OPEN  )											
//		// Open the OLA result file using	the same path and file name as CFS file  but with another extension  
//		if ( bWriteMode )			
//			string  	sOLAPath	 = StripExtension( sDataDir + DataFileW() ) + sOLAEXT	//  OLA file is always written in parallel to CFS. If CFS is not written OLA is neither (could be changed...) 
//			// printf "\t\tOnlineAnalysis1()  bWriteMode is %s opening '%s' \r", SelectString(  bWriteMode, " OFF :  NOT ", " ON : " ), sOLAPath
//			variable	nOLAHnd
//			Open  nOLAHnd  as sOLAPath
//			gOLAHnd = nOLAHnd
//			if ( gOLAHnd == kNOT_OPEN  )	
//				UFCom_FoUFCom_Alert( sFolder, UFCom_kERR_FATAL,  "Could not open Online analysis file '" + sOLAPath + "' ." )
//				return	UFCom_kERROR
//			endif
//		endif
//	endif

	variable	seconds	= AppendPointToTimeWaves( index )

//	//  Add  'Event' , 'Prot' , 'Blck' , 'Fram'  and 'Tim_'  to file with  custom  formatting.
//	sprintf 	sLine, "%s%s%3d;%s%s%3d;%s%s%3d;%s%s%3d;%s%s%10.1lf;" , StringFromList( cEVNT, lstRESfix ), ksSEP_EQ, index - 1, StringFromList( cPROT, lstRESpbf ), ksSEP_EQ, pr, StringFromList( cBLCK, lstRESpbf ), ksSEP_EQ, bl, StringFromList( cFRAM, lstRESpbf ), ksSEP_EQ, fr, StringFromList( cTIME, lstRESfix ), ksSEP_EQ, seconds  	



	// Step 5 : Construct the waves  which are displayed in the Analysis window  e.g.  Adc1Base, Adc0RTim, etc...
	string  	sWin			= ksPN_NAME
	string  	sCtrlName		= "lbSelectResult"
	string  	lstOlaRes	 	= GetUserData( 	sWin,  sCtrlName,  "lstOlaRes" )		// e.g. 'Base_00A;Peak_00B;F0_A0_01B;' : which OLA results in which OLA windows

	// Add value to OLA display.
	// If any 'Basics' result (= result from 'UFPE_klstEVL_RESULTS') for a specific channel/region combination is selected in the listbox then evaluate first both  Base and  Peak (which are required anyway)  and then evaluate the selected result.
	// Evaluate  Base and  Peak  only once  for  multiple selected results.
	// to think:  latencies may (later) need any  selected result   so we might save on  going through various evaluation conditions by  evaluating  ALL 'Basics' results by default  at the expense of some additional computing time  

	variable	nItems	= ItemsInList( lstOlaRes ) 
	// printf "\t\t\tOLA1Point(a) OFrC:%3d\t%s\tpr: %d   bl: %d  fr: %d\tBegPt:\t%8d\tn:    %2d\t'%s' \t \r", index, sFolders, pr, bl, fr, BegPt, nItems, lstOlaRes
	for ( n = 0; n < nItems; n += 1 )	
		sOlaNm		= RemoveEnding( StringFromList( n, lstOlaRes ) )  			// !!! Assumption naming  :  truncate the window name (= A, B or C)
		len			= strlen( sOlaNm )
		ch			= str2num( sOlaNm[ len-2, len-2 ] )
		rg			= str2num( sOlaNm[ len-1, len-1 ] )
		sWnd		= FindFirstWnd_a( ch )									// possibly find and process window list 
		sSrc			= StringFromList( ch, LstChan_a(), UFCom_ksSEP_TAB )
		wave /Z   wOrg	= $UFCom_ksROOT_UF_ + ksACQ_ + UFPE_ksF_IO_ + sSrc

// 2009-12-12
//		Gain		= GainByNmForDisplay( sFolder, sSrc )
		Gain		= GainByNmForDisplay_ns( sFolder, sSrc )
		SIFact	= nSmpInt / UFPE_kXSCALE
// 2006-0411
		variable	xOs	=  BegPt * SIFact
		UFPE_SetXCursrOs( sFolders, ch, xOs )	


		// Compute OLA result data point and add it to  the 1 dimensional (Frames) result wave used to display data 1 frame after the other
		// Process  'Base'  and  'Peak'  only once for each channel/region combination 

		if (  IsNewChannelRegion( ch, rg )  ||  n == 0 )							// order is important :  IsNewChannelRegion()  MUST be executed independently of  'n' 
			// Prepare for adding  value  to  Acquisition display.
			rtp		= UFPE_kE_BASE
			sType	= UFPE_EvalNm( rtp )										// 'Base'
			sOlaNmBP	= OlaNm1( sType, ch, rg )
			// 2006-0316 Base and peak are here auto-constructed so we might avoid constructing them elsewhere

			wOLARes[ ch ][ rg ][ rtp ]	= UFPE_EvaluateBase( sFolders, wOrg, ch, rg, index, BegPt, SIFact ) 
			// Add value to Acquisition display wave for visual check: draw a horizontal line
			NewElementOlaDisp( sOLANmBP, index ) 							//  Returns UFCom_TRUE if a new wave has just been constructed.
			SetElementOlaDisp( sOlaNmBP, index, wOLARes[ ch] [ rg ][ rtp ] )			// The  RESULT value is  always  added to the display wave. 
			// printf "\t\t\tOLA1Point(d) OFrC:%3d\t%s\tpr:%d  bl:%d  fr: %d\tn:%2d/%2d\t%s\t'%s'\t\tch:%2d\trg:%2d\tph:%2d\trtp:%2d/%2d\t\tValue:%6g\tleft:\t%8.4lf\r", index,sSrc,pr,bl,fr,n,nItems,pd(sOlaNmBP,13),sType,ch,rg,ph,rtp,nTypes, wOLARes[ch][rg][rtp], rLeft


			// Prepare for adding  value  to  Acquisition display.
			rtp		= UFPE_kE_PEAK
			sType	= UFPE_EvalNm( rtp )									// 'Peak'
			sOlaNmBP	= OlaNm1( sType, ch, rg )

			// 2006-0316 Base and peak are here auto-constructed so we might avoid constructing them elsewhere
			PkDir	= UFPE_PeakDir( sFolders, ch, rg )
			if ( PkDir != kPEAK_OFF )
				wOLARes[ ch ][ rg ][ rtp ] 	= UFPE_EvaluatePeak( sFolders, wOrg, ch, rg, index, BegPt, SIFact ) 
				// Add value to Acquisition display wave for visual check: draw a symbol
				NewElementOlaDisp( sOLANmBP, index ) 							//  Returns UFCom_TRUE if a new wave has just been constructed.
				SetElementOlaDisp( sOlaNmBP, index, wOLARes[ ch] [ rg ][ rtp ] )			// The  RESULT value is  always  added to the display wave. 
				// printf "\t\t\tOLA1Point(e) OFrC:%3d\t%s\tpr: %d   bl: %d  fr: %d\tn:%2d/%2d\t%s\t'%s'\t\t\tch:%2d\trg:%2d\tph:%2d\trtp:%2d/%2d\tValue:%6g\tleft:\t%8.4lf  \r", index, sSrc,pr,bl,fr,n,nItems, UFCom_pd(sOlaNmBP,13), sType,ch,rg,ph,rtp,nTypes, wOLARes[ch][rg][rtp], rLeft
			endif
		endif

		// Process  all other  'Basics'  results  ( all except  'Base'  and  'Peak' which have already been processed )
		sType 	= sOlaNm[ 0, len-4 ]									// !!! Assumption naming  e.g.  'Peak_01'  ->  'Peak'
		rtp	= UFPE_WhichListItemIgnorWhiteSp( sType, UFPE_klstEVL_RESULTS )
		if ( rtp != UFPE_kE_BASE  &&   rtp != UFPE_kE_PEAK  &&  rtp != UFCom_kNOTFOUND )
	
			variable	rLeft		= UFPE_CursorX( sFolders, ch, rg, UFPE_kC_PHASE_PEAK, UFPE_CN_BEG ) 				// the left peak cursor is also the left border of the crossings/slope analysing region

// 2006-0413 ????? PeakTime	= UFPE_EvT( sFolders, ch, rg, UFPE_kE_PEAK ) + xOs	// ?????????
			variable	PeakTime	= UFPE_EvT( sFolders, ch, rg, UFPE_kE_PEAK )
			variable	PeakValue= UFPE_EvY( sFolders, ch, rg, UFPE_kE_PEAK )
			variable	Val20	=  UFPE_EvY( sFolders, ch, rg, UFPE_kE_BASE ) * 4 / 5  +  PeakValue * 1 / 5
			variable	Val50	=  UFPE_EvY( sFolders, ch, rg, UFPE_kE_BASE ) * 1 / 2  +  PeakValue * 1 / 2
			variable	Val80	=  UFPE_EvY( sFolders, ch, rg, UFPE_kE_BASE ) * 1 / 5  +  PeakValue * 4 / 5

			if ( rtp == UFPE_kE_RISE20 )
				wOLARes[ ch ][ rg ][ rtp ] 	= UFPE_EvaluateCrossing( sFolders, wOrg, ch, rg, index, BegPt, SIFact, PkDir, "Rise",  rLeft / SIFact, PeakTime, 20, Val20, rtp ) 
			endif
			if ( rtp == UFPE_kE_RISE50 )
				wOLARes[ ch ][ rg ][ rtp ] 	= UFPE_EvaluateCrossing( sFolders, wOrg, ch, rg, index, BegPt, SIFact, PkDir, "Rise",  rLeft / SIFact, PeakTime, 50, Val50, rtp ) 
			endif
			if ( rtp == UFPE_kE_RISE80 )
				wOLARes[ ch ][ rg ][ rtp ] 	= UFPE_EvaluateCrossing( sFolders, wOrg, ch, rg, index, BegPt, SIFact, PkDir, "Rise",  rLeft / SIFact, PeakTime, 80, Val80, rtp ) 
			endif
			if ( rtp == UFPE_kE_RISSLP )
				wOLARes[ ch ][ rg ][ rtp ] 	= UFPE_EvaluateSlope(     sFolders, wOrg, ch, rg, index, BegPt, SIFact, PkDir, "Rise",  rLeft /  SIFact, PeakTime, rtp ) 
			endif


// 2006-0424 todo :  eliminate
			if ( rtp == UFPE_kE_BRISE )
				variable	BaseBeg	= UFPE_Eval(sFolders, ch, rg, UFPE_kE_BASE, UFPE_kTB ) ,	BaseBegY	= UFPE_Eval(sFolders, ch, rg, UFPE_kE_BASE, UFPE_kYB)
				variable	BaseEnd	= UFPE_Eval(sFolders, ch, rg, UFPE_kE_BASE, UFPE_kTE ) ,	BaseEndY	= UFPE_Eval(sFolders, ch, rg, UFPE_kE_BASE, UFPE_kYE)
				variable	RiseBeg	= UFPE_EvVexists( sFolders, ch, rg, UFPE_kE_RISE20 )  ?   UFPE_EvV(sFolders, ch, rg, UFPE_kE_RISE20)  : UFPE_EvV(sFolders, ch, rg, UFPE_kE_RISE50)	// the 20% crossing may not exist BUT the 50% CROSSING IS ASSUMED TO EXIST
				variable	RiseBegY	= UFPE_EvVexists( sFolders, ch, rg, UFPE_kE_RISE20 )  ?   UFPE_EvY(sFolders, ch, rg, UFPE_kE_RISE20)  : UFPE_EvY(sFolders, ch, rg, UFPE_kE_RISE50)	// the 20% crossing may not exist BUT the 50% CROSSING IS ASSUMED TO EXIST
				variable	RiseEnd	= UFPE_EvV(sFolders, ch, rg, UFPE_kE_RISE80) ,	RiseEndY	= UFPE_EvY(sFolders, ch, rg, UFPE_kE_RISE80)
// 2006-0424
//				wOLARes[ ch ][ rg ][ rtp ] 	= EvaluateBaseRise( sFolders, ch, rg, index, BegPt, SIFact, BaseBeg/SIFact, BaseBegY, BaseEnd/SIFact, BaseEndY , RiseBeg, RiseBegY, RiseEnd, RiseEndY )
			endif


			//  Evaluation to find the decay end location ( smoothed decay-baseline crossing next to peak location, may not exist ) [ SIMILAR  EVAL...] 
			if ( rtp == UFPE_kE_DEC50  ||  rtp == UFPE_kE_DECSLP )
// 2006-0413.................!!!!!
print " 060413.....peaktime............!!!!!"
				variable locEndDecay 
				variable level	= UFPE_EvY(sFolders, ch, rg, UFPE_kE_BASE ) 
				FindLevel	/Q /R=( PeakTime, Inf)  wOrg, level	// try to find time when decay crosses baseline ( may not exist )
				if ( V_flag )
					string  sMsg
					sprintf sMsg, "Decay did not find BaseLevel Crossing (%.1lf) after %.1lfms  (smoothing till end...) ", level, PeakTime
					UFCom_Alert( UFCom_kERR_LESS_IMPORTANT,  sMsg )
					locEndDecay = rightX( wOrg )					// inf is wrong!
				else
					locEndDecay  = V_LevelX
				endif
	
				if ( rtp == UFPE_kE_DEC50 )
					wOLARes[ ch ][ rg ][ rtp ] 	= UFPE_EvaluateCrossing( sFolders, wOrg, ch, rg, index, BegPt, SIFact, PkDir, "Decay",  PeakTime, locEndDecay, 50, Val50, rtp ) 
				endif
				if ( rtp == UFPE_kE_DECSLP )
					wOLARes[ ch ][ rg ][ rtp ] 	= UFPE_EvaluateSlope(     sFolders, wOrg, ch, rg, index, BegPt, SIFact, PkDir, "Decay",  PeakTime, locEndDecay, rtp ) 
				endif
			endif

			if ( rtp == UFPE_kE_HALDU )
				variable	HalfDurBeg	= UFPE_EvV( sFolders, ch, rg, UFPE_kE_RISE50 ) 
				variable	HalfDurEnd	= UFPE_EvV( sFolders, ch, rg, UFPE_kE_DEC50 )  
				variable	HalfDurY		= UFPE_EvY( sFolders, ch, rg, UFPE_kE_DEC50 ) 			// or  UFPE_EvY( sFolders, ch, rg, UFPE_kE_RISE50 ) )
				wOLARes[ ch ][ rg ][ rtp ] 	= UFPE_EvaluateHalfDuration( sFolders, ch, rg, BegPt, SIFact, "HalfDur", HalfDurY, HalfDurBeg, HalfDurEnd ) 

			endif

			if ( rtp == UFPE_kE_RT2080 )
				variable	Rise20T		= ( UFPE_EvV( sFolders, ch, rg, UFPE_kE_RISE20 ) 
				variable	Rise80T		= ( UFPE_EvV( sFolders, ch, rg, UFPE_kE_RISE80 )
				wOLARes[ ch ][ rg ][ rtp ] 	= UFPE_EvaluateRiseTime2080( sFolders, ch, rg, BegPt, SIFact, "RT2080", Rise20T,  Val20,  Rise80T, Val80 ) 
			endif

			NewElementOlaDisp( sOlaNm, index ) 								//  Returns UFCom_TRUE if a new wave has just been constructed.
			SetElementOlaDisp(   sOlaNm, index, wOLARes[ ch] [ rg ][ rtp ] )			// The  RESULT value is  always  added to the display wave. 
			// printf "\t\t\tOLA1Point(f)  OFrC:%3d\t%s\tpr: %d   bl: %d  fr: %d\tn:%2d/%2d\t%s\t'%s'\t[%s]\tch:%2d\trg:%2d\tph:%2d\trtp:%2d/%2d\tlft:\t%8.4lf\tValue:%g \r", index, sSrc, pr, bl, fr, n, nItems, UFCom_pd( sOlaNm,13), sType, sType, ch, rg, -1, rtp, nTypes,  1.2345, wOLARes[ ch ][ rg ][ rtp ]
		endif


		//  Do all the fitting 
		variable	LatCnt	= LatCnt_a()
		variable	FitCnt	= FitCnt_a()
		variable	fi		= UFPE_PossiblyGetFitIndex( sOlaNm )							// extracts those starting with  'F0_...' , 'F1_...' ,   ...   'F9_...'
		if (  fi != UFCom_kNOTFOUND )
			variable	nFitFunc		= UFPE_FitFnc_( sFolders, ch, rg, fi )
			string  	sFitPar		= StringFromList( 1, sOlaNm, "_" )			// assumption naming
			variable	par			= UFPE_WhichParam( nFitFunc, sFitPar )
			if (  IsNewChannelRegionFit( ch, rg, fi )  ||  n == 0 )						// order is important :  IsNewChannelRegionFit()  MUST be executed independently of  'n' 
				 UFPE_OneFit( sFolders, sWnd, wOrg, ch, rg, fi, BegPt, SIFact, lstFitResults, LatCnt, FitCnt )		// lstFitResults will be set
			endif
			value	= str2num( StringFromList( par, lstFitResults ) )
			// printf "\t\t\tOLA1Point(g) OFrC:%3d\t%s\tpr: %d   bl: %d  fr: %d\tn:%2d/%2d\t%s\t'%s'\t%s\tch:%2d\trg:%2d\tfit: %2d\tpar:%2d/%2d\tlft:\t%8.4lf\tValue:%8g \tlstFitResults:%s \r", index, sSrc, pr, bl, fr, n, nItems, UFCom_pd( sOlaNm,13), sType, UFCom_pd(sFitPar, 5), ch, rg, fi, par, nTypes,  1.2345, value, lstFitResults
			NewElementOlaDisp( sOlaNm, index ) 								//  Returns UFCom_TRUE if a new wave has just been constructed.
			SetElementOlaDisp(   sOlaNm, index, value )		
		endif

		//  Process all latencies 
		//  Process all computations 

		UFPE_SetXCursrOs( sFolders, ch, 0 )								// 2006-0411 reset the X offset. This necessary so that  'OnePeakBase()'  correctly display the analysed points, e.g. when the user changes controls and a single quick-check analysis is made. 

	endfor


//	// Step 8 : Write the result line  (Event, Block, .....Base, Peak, ...)
//	 printf "\t\tOLA1Point( p:%d  b:%d  f:%d )\t'%s' \r", pr, bl, fr, sLine	
//	if ( bWriteMode )
//		printf "\t\tOLA1Point( p:%d  b:%d  f:%d )\t'%s' \r", pr, bl, fr, sLine	
//		if ( gOLAHnd ) 
//			fprintf gOLAHnd, "%s\r", sLine	
//		endif	
//	endif	

End

static Function		IsFit( sOlaNm )
	string  	sOlaNm
End	


static Function		IsNewChannelRegion( ch, rg )
	variable	ch, rg
	nvar	/Z	PrevCh	= root:uf:acq:pul:PrevCh
	nvar	/Z	PrevRg	= root:uf:acq:pul:PrevRg
	if ( ! nvar_exists( PrevCh )  ||  ! nvar_exists( PrevRg )  )					
		variable	/G root:uf:acq:pul:PrevCh	= ch			// It  is  the first channel/region... 
		variable	/G root:uf:acq:pul:PrevRg	= rg			//..so we must compute Base and Peak
		return	UFCom_TRUE
	else									
		if ( ch == PrevCh  &&  rg == PrevRg )				// Is  NOT the first channel/region..
			return	UFCom_FALSE						// ..and is same as previous so we will not compute Base and Peak again 
		else
			PrevCh	= ch 							// ..but  channel/region  has changed  so we must compute Base and Peak again 
			PrevRg	= rg 
			return	UFCom_TRUE
		endif
	endif
End

static Function		IsNewChannelRegionFit( ch, rg, fi )
	variable	ch, rg, fi
	nvar	/Z	PrevCh	= root:uf:acq:pul:PrevCh
	nvar	/Z	PrevRg	= root:uf:acq:pul:PrevRg
	nvar	/Z	PrevFi	= root:uf:acq:pul:PrevFi
	if ( ! nvar_exists( PrevCh )  ||  ! nvar_exists( PrevRg )  ||  ! nvar_exists( PrevFi ) )					
		variable	/G root:uf:acq:pul:PrevCh	= ch			// It  is  the first channel/region/fit... 
		variable	/G root:uf:acq:pul:PrevRg	= rg			//..so we must do the fit
		variable	/G root:uf:acq:pul:PrevFi	= fi			//..so we must compute Base and Peak
		return	UFCom_TRUE
	else									
		if ( ch == PrevCh  &&  rg == PrevRg  &&  fi == PrevFi )	// Is  NOT the first channel/region/fit..
			return	UFCom_FALSE						// ..and is same as previous so we will not do the same fit again 
		else
			PrevCh	= ch 							// ..but  channel/region/fit has changed  so we must do the fit again 
			PrevRg	= rg 
			PrevFi	= fi 
			return	UFCom_TRUE
		endif
	endif
End

//static Function		SetMustCompute( wOLARes, ch, rg ) 
//	wave	wOlaRes
//	variable	ch, rg
//	variable	 rtp 	= UFPE_kE_BASE
//	wOLARes[ ch] [ rg ][ rtp ]	= Nan
//End
//
//static Function		MustCompute( wOLARes, ch, rg )
//	wave	wOlaRes
//	variable	ch, rg
//	variable	 rtp 	= UFPE_kE_BASE
//	variable	code	= ( numType( wOLARes[ ch] [ rg ][ rtp ] ) == UFCom_kNUMTYPE_NAN ) 
//	return 	code
//End




static Function		NewElementOlaDisp( sOLANm, index )
//  Add  a new element to  any entry type  ( e.g 'Event' ,  'Time' , 'Blck' , 'Adc0Base', ...of display wave .
// Returns  UFCom_TRUE  if a new wave has just been constructed,  UFCom_FALSE if a point has been added to an existing wave
	string  	sOLANm
	variable	index
	variable	value	= Nan
	wave  /Z	wOlaDisp	= 	$FolderOlaDispNm( sOLANm ) 			// Check if the fixed result  OLA waves (=Event...Tim_) have already been defined. Checking  just 'Evnt' is sufficient, ...
	if ( ! waveExists( wOlaDisp ) )								// ...if this wave has not been defined  the others 'Blck' .. 'Tim_'  have neither been defined : build them all
		make /O /N= (index)	$FolderOlaDispNm( sOLANm )  = value	// Nan hides points not yet computed  (not effective here as there are no points)
		// printf "\t\t\tNewElementOlaDisp()\tindex:\t%3d\tBUILD OLA wave\t%s\t= %8.2lf   \r", index, UFCom_pd(sOLANm,12), value 
		return	UFCom_TRUE
	else
		Redimension  /N=( index ) wOlaDisp
		wOlaDisp[ index - 1 ]	= value
		// printf "\t\t\tNewElementOlaDisp()\tindex:\t%3d\tRedim OLA wave\t%s\t= %8.2lf     \t  \r", index, UFCom_pd(sOLANm,12), value
		return	UFCom_FALSE
	endif
End

static Function		SetElementOlaDisp( sOLANm, index, value )
//  Set any entry type  ( e.g 'Event' ,  'Time' , 'Blck' , 'Adc0Base', ...of display wave  to 'value' . Starting at 0 allows to use this wave as XAxis
	string  	sOLANm
	variable	index, value
	wave	wOlaDisp	= $FolderOlaDispNm( sOLANm ) 	
	wOlaDisp[ index ] = value							
 	// printf "\t\t\tSetElementOlaDisp() \tindex:\t%3d\t\t\t\t\t%s\t= %8.2lf   \r", index, UFCom_pd( sOLANm,12), value
End


// 2006-0321
//Static  Function	/S	CrossXNm( sSrc, rg, ph )
//	string		sSrc
//	variable	rg, ph
//	return	UFPE_ksOR + "orX" + num2str( rg ) + sSrc	+ StringFromList( ph, lstOA_PHASES )			// UFPE_ksOR  ensures that the region will not be regularly erased
//End
//
//Static  Function	/S	CrossYNm( sSrc, rg, ph )
//	string		sSrc
//	variable	rg, ph
//	return	UFPE_ksOR + "Y" + num2str( rg ) + sSrc	+ StringFromList( ph, lstOA_PHASES )			// UFPE_ksOR  ensures that the region will not be regularly erased
//End
//
//Static  Function	/S	FolderCrossNm( sCrossNm )
//	string  	sCrossNm
//	return   	csFOLDER_OLA_CROSS + sCrossNm
//End

Static  Function	/S	FolderOlaDispNm( sOLANm )
	string  	sOLANm
	return   	csFOLDER_OLA_DISP + sOLANm
End

//Static  Function	/S	FittedNm( sSrc, rg, ph )
//	string		sSrc
//	variable	rg, ph
//	return	"Fit" + num2str( rg ) + sSrc	+ StringFromList( ph, lstOA_PHASES )	
//End

//Static  Function	/S	FolderFittedNm( sFittedNm )
//	string  	sFittedNm
//	return   	csFOLDER_OLA_FITTED + sFittedNm
//End


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  ANALYSIS  FILE  FUNCTIONS

Function		FinishAnalysisFile()
// Open Online analysis file,  write all accumulated data and close file
	// if no cUSER region is defined we skip the whole analysis file writing (this must be refined if there are analysis types requiring no cUSER region)
	if ( ! AnalysisIsOn() )							
		return 0
	endif
	nvar		gOLAHnd		= root:uf:acq:ola:gOLAHnd
	if ( gOLAHnd != kNOT_OPEN )	
		Close	gOLAHnd
	endif
	gOLAHnd= kNOT_OPEN	
	return	0
End


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  ANALYSIS 2 :  ONE TO ONE  ANALYSIS 
//  Each original data point gives a computed result point.  Simple examples realized  here  are   Average  and  Sum 
//  Features:
//  - one short and simple routine for each analysis which is easily integrated into the acquisition framework
//  - needs a keyword in the script (e.g. 'Aver'  or 'Sum' )
//  - works with complete wave,  windows are handled and displayed like 'Adc'  , 'Dac'  and 'PoN'
  
// removed 040123
//Function	ComputeAverage( pr, bl, fr, sw )		// 2003-1008  !    NOT   REALLY PROTOCOL  AWARE		
//// a first dummy and test function for online evaluation
//	variable	pr, bl, fr, sw
//	variable	nIO		= UFPE_IOT_AVER
//	variable	c, nChans	= UFPE_ioUse( wIO, nIO )
//	variable	BegPt	= SweepBegSave( pr, bl, fr, sw )	
//	variable	EndPt	= SweepEndSave( pr, bl, fr, sw )
//	variable	nPts		= EndPt - BegPt
//	variable	AVERPTS	= 20 * ( 1 + 3 * c )		// arbitrary test averaging factor
//	string  	bf
//	for ( c = 0; c < nChans; c += 1 )						
//		// This implementation should be hidden in BreakIONm() <--> BuildIONm()
//		string 	sSrc		= ioList2( nIO, c, UFPE_IO_SRC, 0 )
//		string 	sCh0	=  sSrc[0,2]  + sIOCHSEP +  sSrc[3,99] 		// Adc1 -> Adc_1
// 		string 	swResult	= "Aver" + sIOCHSEP + sSrc		// 
//		// print "\tComputeAverage( fr, sw )", sSrc, "=?=",  UFPE_ios(  nIO, c, UFPE_IO_SRC ), UFPE_ios(  nIO, c, UFPE_IO_NAME ),  "sSrc.....", sSrc, sSrc[0,2], "+", sSrc[3,99],  "Aver"+sIOCHSEP + sSrc, "=?=", ios2s( "Aver", c, UFPE_IO_NM )
//
//		wave  /Z	wCh0	= $sCh0
//		// 12/18/02 here no checking necessary: has been done in CheckPresenceOfRequiredSrcChans()
////		if ( !waveexists( wCh0 ) )							// does the extracted channel exist ?
////			FoUFCom_Alert( sFolder, UFCom_kERR_FATAL,  "The data channel '" + sCh0 + "' required by ' Aver" + ":  " + sSrc + "' is not provided in the script file. " ) 
////			return UFCom_kERROR
////		endif	
// 		wave	wResult	= $swResult 
//		// waveform arithmetic:  target[ tbeg, tEnd ] = src[ sBeg - tBeg + p ]
//		wResult[ BegPt, BegPt+nPts ] = wCh0[  p ]	// copy current sweep Ch0 e.g. 'Adc' data to 'Aver'	
//		variable n
//		for ( n = BegPt; n < BegPt + nPts; n += 1)
//			wResult[ n ] = ( ( AVERPTS - 1 ) * wResult[ n - 1 ] + wResult[ n ] ) / AVERPTS //! uses Igor clipping	
//		endfor
//	endfor
//End

//Function	ComputeSum( pr, bl, fr, sw )		// 2003-1008  !    NOT   REALLY PROTOCOL  AWARE		
//// a second dummy and test function for online evaluation
//	variable	pr, bl, fr, sw
//	variable	nIO		= UFPE_IOT_SUM
//	variable	c, nChans= UFPE_ioUse( wIO, nIO )
//	variable	BegPt	= SweepBegSave( pr, bl, fr, sw )	
//	variable	EndPt	= SweepEndSave( pr, bl, fr, sw )
//	variable	nPts		= EndPt - BegPt
//	string 	bf
//	for ( c = 0; c < nChans; c += 1 )						
//		// This implementation should be hidden in BreakIONm() <--> BuildIONm()
//		string  	sSrc 	= UFPE_ioFldAcqioio( "Sum" , c, UFPE_IO_SRC )
//		string  	sCh0	= ioList2( nIO, c, UFPE_IO_SRC, 0 )
//		string  	sCh1	= ioList2( nIO, c, UFPE_IO_SRC, 1 )
//		string  	swResult	= UFPE_ioFldAcqioio( "Sum", c, UFPE_IO_NM )
//		sCh0	= sCh0[0,2]  + sIOCHSEP +  sCh0[3,99] 	// Adc1 -> Adc_1	
//		sCh1	= sCh1[0,2]  + sIOCHSEP +  sCh1[3,99] 	// Adc1 -> Adc_1	
//		// printf "\tComputeSum( fr, sw )   sSrc:'%s'   sSrcCh0:'%s'   sSrcCh1:'%s'   sSum:'%s'  \r", sSrc, sCh0, sCh1, swResult
//
//		wave  /Z	wCh0	= $sCh0
//		// 12/18/02 here no checking necessary: has been done in CheckPresenceOfRequiredSrcChans()
////		if ( !waveexists( wCh0 ) )							// does the extracted channel exist ?
////			UFCom_FoUFCom_Alert( sFolder, UFCom_kERR_FATAL,  "The data channel '" + sCh0 + "' required by 'Sum:" + sSrc + "' is not provided in the script file." )
////			return UFCom_kERROR
////		endif	
//		wave  /Z	wCh1	= $sCh1
////		if ( !waveexists( wCh1 ) )
////			UFCom_FoUFCom_Alert( sFolder, UFCom_kERR_FATAL,  "The data channel '" + sCh1 + "' required by 'Sum:" + sSrc + "' is not provided in the script file." )
////			return UFCom_kERROR
////		endif	
// 		wave	wResult	= $swResult
//		// waveform arithmetic:  target[ tbeg, tEnd ] = src[ sBeg - tBeg + p ]
//		wResult[ BegPt, BegPt+nPts ] = wCh0[  p ] + wCh1[ p ]
//	endfor
//End

//Static  Function   /S	ioList1( ioch, nData, nEntry )
//// extracts one comma separated entry from script line (given by ioch) and sSubKey (given by nData)  e.g. 'Src:Adc2,Dac1'
//// Constructed for  subkey  'Src'   but can be used generally
//// Entry can be any string , not only a number. As no error checking is done syntax errors, illegal spaces etc. are not caught
//	variable	ioch, nData, nEntry
//	string  	sEntries	= iosOld( ioch, nData )
//	variable	EntryCnt	= ItemsInList( sEntries, UFPE_sPSEP )
//	string  	sOneEntry	= StringFromList( nEntry, sEntries, UFPE_sPSEP )
//	// printf "\tioList1()...srcCh:%d/%d  '%s'    returning sFullName:'%s'  \r", nEntry, EntryCnt, sEntries, sOneEntry
//	return	sOneEntry
//End

//Static  Function   /S	ioList2( nIO, c, nData, nEntry )
//// extracts one comma separated entry from script line (given by nIO and c) and sSubKey (given by nData)  e.g. 'Src:Adc2,Dac1'
//	variable	nIO, c, nData, nEntry
//	return	ioList1( NioC2ioch( nIO, c ), nData, nEntry )
//End

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

