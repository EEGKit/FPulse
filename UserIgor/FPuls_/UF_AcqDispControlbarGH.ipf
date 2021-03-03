	//
	// UF_AcqDispControlbar.ipf
	// 
	// Routines for
	
#pragma rtGlobals=1							// Use modern global access method.

#include "UFCom_ListProcessing" 

//================================================================================================================================
//  CONTROLBARS  in  the  ACQUISITION  WINDOWS FOR EDITING TRACE and WINDOW APPEARANCE  with   POPMENU(=YZoom, Colors)   and   SLIDER(=YOfs)   

// The controlbar code for each of the the buttons, checkboxes and popmenus is principally made up of 2 parts : 
// Part 1  stores the user setting in the underlying control structure.  This is the more  important part as this control structure controls the display during the next acquisition.
// Part 2  has the purpose to give the user some immediate feedback that his changes have been accepted. 
//	To accomplish this existing data are drawn preliminarily with changed colors, zooms, Yaxes in a manner which is to reflect the user changes at once which would without this code only take effect later during the next acquisition.
//	The code must handle  'single'  traces  and   'superimposed'  traces (derived from the basic trace name but with the begin point number appended)

// 060606  NO LONGER  ninstn.....
//	The code must allow multiple instances of the same trace allowing the same data to be displayed at the same time with different zoom factors,..
//	  ...for this we must do much bookkeeping because Igor has the restriction of requiring the same trace=wave name but appends its own instance number whereas we must do our own instance counting in Curves
// 060606  NO LONGER  DisplayOffLine().
//	We take the approach to not even try to keep track which instances of which traces in which windows have to be redrawn, instead we we redraw all ( -> DisplayOffLine() )
//	This is sort of an overkill but here we do it only once in response to a (slow) user action while during acq we do the same routine (=updating all acq windows) very often... 
// 	...so we accept the (theoretical) disadvantage of updating traces which actually would have needed no update because it simplifies the program code tremendously  .

// Major revision 040108..040204
// Major revision 060520..060610

static constant	kCB_HTLN0				= 26			// 26 is the minimum value required for a popupmenu
static constant	kCB_HTLN1				= 20			// 20 is sufficient if the line only contains buttons 
static constant	cXSZ_TB_TRACE			= 80		// empirical values, could be computed .  81 for 'Dac0SC' , 86 for 'Dac0SCa' , 92 for 'Dac0 SC a', 110 for 'Dac0 Sweeps C'
static constant	cXSZ_CB_AUTOSCL			= 60			// 60 for 'AutoScl'
static constant	cXSZ_CB_INCLUDE			= 80			// 
static constant	cXSZ_PM_COLOR			=  0		// 96	 is a good value if the color menu is reintroduced again		
static constant	cXSZ_PM_ZOOM			= 104			
static constant	cXSZ_PM_TRACE			= 104			
//static constant	cXLBEXTRASIZE		= 80			
static constant	cXSZ_BUT_NARROW	= 20			
//static constant	cXLBCLOSEBUTTONSIZE= 20			
static constant	cbDISABLEbyGRAYING		= 0 //1 	// 0 : disable the control by hiding it completely (better as it save screen space and as it avoids confusion) ,  1 : disable the control by graying it 
static constant	cbALLOW_ADC_AUTOSCALE	= 1 //1 	// 0 : autoscale only Dacs ,  1 : also autoscale   Adc , Pon , etc ( todo: not yet working correctly. Problem: tries to autoscale trace on screen which may be flat line -> CRASHES sometimes )
static constant	cbAUTOSCALE_SYMMETRIC	= 0 //1 	// 0 : autoscale exactly between minimum and maximum of trace possibly offseting zero,  1 : autoscale keeping pos. and neg. half axis at same length ( zero in the middle)


Function		DiacControlBar( w )
	variable	w
	string  	sWNm	= DiacWnd( w )
	ControlInfo	/W=$sWNm	CbCheckboxAuto; 	return ( V_flag == UFCom_kCI_CHECKBOX )	// Check if the checkbox control exists. Only if it exists then the controlbar also exists. 
End

  Function		CreateControlBarInAcqWnd_6( sWNm, nio, cio, bAcqControlbar ) 
//static  Function	CreateControlBarInAcqWnd_6( sChan, mo, ra, w, bAcqControlbar ) 
// depending on  'bAcqControlbar'  build and show or hide the controlbar  AND  show or hide the individual controls (buttons, checkboxes and popmenus..)
	string  	sWNm
	variable	nio, cio, bAcqControlbar										// Show or hide the controlbar
	string  	sFo		= ksACQ

	variable	wn		= DiacWnd2Nr( sWNm )
	string  	sChan	= DiacParameter_( sWNm, wn, nio, cio, kDIA_CV_IOTYP ) + DiacParameter_( sWNm, wn, nio, cio, kDIA_CV_IONR )	

	variable	rbAutoscl, rYOfs, rYZoom
	variable	bIncludeNoStore	= 0

	variable	ControlBarHeight = bAcqControlbar ?  kCB_HTLN0 + kCB_HTLN1 :  0 		// height 0 effectively hides the whole controlbar
	ControlBar /T /W = $sWNm  ControlBarHeight 								// /T creates at top, /B creates at bottom
	SetWindow	$sWNm,  	UserData( nio )	= num2str( nio )						// Set UD nio		Store the type (dac or adc)  of the trace we are currently working on quasi-globally within the graph
	SetWindow	$sWNm,  	UserData( cio )	= num2str( cio )						// Set UD cio		Store the linear index (0,1..) of the trace we are currently working on quasi-globally within the graph

	// printf "\tCreateControlBarInAcqWnd_6( sWNm: '%s'   nio:%2d  cio:%2d    bAcqCb:%2d ) \t%s\t \t \t \r",  sWNm, nio, cio, bAcqControlbar, UFCom_pd( sChan, 15)
	ConstructCbTitleboxTraceNm( sWNm,  bAcqControlbar, sChan )				// 
//	ConstructCbPopmenuColors( sWNm,  bAcqControlbar, rsRGB )					//

	variable	bDisableCtrlAutoscl	= DisableCtrlAutoscl( sChan, bAcqControlbar ) 
	variable	bDisableCtrlZoomOfs	= DisableCtrlZoomOfs( sChan, bAcqControlbar, rbAutoscl ) 

	ConstructCbCheckboxAuto( sWNm, bDisableCtrlAutoscl, rbAutoscl )						

	ConstructCbCheckboxInclude( 	sWNm, !bAcqControlbar , bIncludeNoStore )
//	ConstructCbSweepButton(		sWNm, !bAcqControlbar  )
	ConstructCbFrameButton(		sWNm, !bAcqControlbar  )
	ConstructCbLapButton( 		sWNm, !bAcqControlbar  )
	ConstructCbCompressButton( 	sWNm,  !bAcqControlbar  )
	ConstructCbExpandButton( 	sWNm,  !bAcqControlbar  )
	ConstructCbReverseButton( 	sWNm,  !bAcqControlbar  )
	ConstructCbReversButton( 		sWNm,  !bAcqControlbar  )
	ConstructCbAdvancButton( 	sWNm,  !bAcqControlbar  )
	ConstructCbAdvanceButton( 	sWNm,  !bAcqControlbar  )

	ConstructCbCloseButton( 		sWNm,  !bAcqControlbar )

	ConstructCbPopupmenuAddTrace( 	sWNm, nio, cio, !bAcqControlbar, sChan  )
	ConstructCbPopupmenuYZoom( 	sWNm, nio, cio, bDisableCtrlZoomOfs )						

	ConstructCbSliderYOfs( 		sWNm, nio, cio, bDisableCtrlZoomOfs )			// also construct the optional Controlbar on the right (only in Igor5) 

End


//===========================================================================================================================================
//  DIA CONTROLBAR 1 : TRACE SELECTION  AND   Y  AXIS MANIPULATION 

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//  Functions  controling  whether a specific control  of the control bar  is to be enabled, disabled by completely hiding it or disabled by just graying it.

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

static  Function		ConstructCbTitleboxTraceNm( sWNm, bDisable, sTNm )
// Fill the Titlebox control  in the ControlBar with the name of the selected trace. 
	string 	sWNm, sTNm
	variable	bDisable
	Titlebox  CbTitleboxTraceNm,  win = $sWNm,  pos = {2, 2},  title = sTNm,  frame = 2,  labelBack=(60000, 60000, 60000)
	//Titlebox  CbTitleboxTraceNm,  win = $sWNm, size = {cXSZ_TB_TRACE-10,12} 			// TitleBox 'size'  has no effect, the field is automatically sized 
	Titlebox  CbTitleboxTraceNm,  win = $sWNm, disable = ! bDisable
End

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

static  Function		ConstructCbPopupmenuAddTrace( sWNm, nio, cio, bDisable, sChan  )
	string 	sWNm, sChan 
	variable	nio, cio, bDisable
	variable	wn		= DiacWnd2Nr( sWNm )
	PopupMenu LBAddTrace,   win = $sWNm, size = { cXSZ_PM_TRACE, 20 }, 	proc=fDiacAddTrace,	title="Add"	
	PopupMenu LBAddTrace,   win = $sWNm, pos = { cXSZ_TB_TRACE , 2 } 
	ShowHideCbPopupmenuAddTrace( sWNm, nio, cio, bDisable, sChan  )									// Enable or disable the control  and possibly adjust its value
End


static  Function		ShowHideCbPopupmenuAddTrace( sWNm, nio, cio, bDisable, sChan  )
//  Hide, gray or display (=enable)  the control   and   set its  state/value/limits  correctly  (even when hidden).
	string 	sWNm, sChan 
	variable	nio, cio, bDisable
	variable	n = WhichListItem( sChan, DiacTracesToAdd() )	// Search and return the item in the list which corresponds to the desired value 'sChan' .  Note:  In this Popupmenu each 'sChan' should occur only once. However, the same 'sChan' e.g with different zoom may exist in the graph.
	PopupMenu LBAddTrace,   win = $sWNm, disable = bDisable,  mode = n+1,  value = DiacTracesToAdd()	// n+1 sets the selected item in the Popupmenu,  counting starts at 1.  
End


Function	/S	DiacTracesToAdd()							// Igor does not allow this function to be static
	return	LstIOAllDacAllAdc1Dim( ksACQ )
End	


Function		 fDiacAddTrace( s )
// Action proc executed when the user selects a trace from the  'AddTrace'  Popupmenu.  
	struct	WMPopupAction	&s
	string  	sFo	= ksACQ
	if (  s.eventcode == 2 )										// 2 : mouse up
		variable	nio, cio
		variable	wn		= DiacWnd2Nr( s.Win )
		string  	sTNm	=  s.PopStr							// this  channel  is  given by the 'AddTrace' popupmenu item band the user clicked into 
		string  	sPn 		= ksFPUL
		string  	lllstIo		= LstIo( sFo )

		UFPE_ioNm2NioC_ns( lllstIO, sTNm, nio, cio )					// sets the references  nio and cio
	  	string  	llllstDiac 	= LstDiac(); 	UFCom_DisplayMultipleList( "fDiacAddTrace exit",  llllstDiac, DiacSeps(), 31 )  

		string  	sIOType	 =  StringFromList( nio, klstSC_NIO )
		string  	sIONr	 =  UFPE_ioItem( lllstIO, nio, cio, kSC_IO_CHAN )
		string  	sIONm	 =  UFPE_ioItem( lllstIO, nio, cio, kSC_IO_NAME )
		string  	sUnits	 =  UFPE_ioItem( lllstIO, nio, cio, kSC_IO_UNIT  )	

		// Assume some default values
		variable bAutoscl	= 1			// should be 1 only for Dacs and else 0 
		variable YZoom		= 1
		variable YOfs		= 0
		variable Gain		=  1234//str2num( UFPE_ioItem( lllstIO, nio, cio, kSC_IO_GAIN  )	)	 ;			Gain = numType( Gain ) == UFCom_kNUMTYPE_NAN  ?  1  :  Gain 	

		llllstDiac	= DiacCurvesAddCurve( sFo, s.Win, wn, nio, cio, sIOType, sIONr, sIONm, sUnits, bAutoscl, YOfs, YZoom, Gain )

		llllstDiac 	= LstDiac(); 	UFCom_DisplayMultipleList( "fDiacAddTrace exit",  llllstDiac, DiacSeps(), 31 )  
		DiacUpdateFile( sFo, llllstDiac )									// modify trc: update trc

		string  	lstSomeWaves	= LstDiacAdcAndDacDim2( wn )
		DiacDisplayChannels( sFo, sPn, s.Win, lstSomeWaves )

		 printf "\t\t\t fDiacAddTrace()  '%s'  gives  PopStr:'%s'  event:%d   wn:%d   nio:%2d  cio:%2d   sTNm/sChan: '%s' =?= '%s'     '%s' \r", s.CtrlName, s.PopStr, s.eventcode, wn, nio, cio, sTNm, sIOType + sIONr, LstDiac()
	else
		 printf "\t\t\t fDiacAddTrace()  '%s'  gives  PopStr:'%s'  event:%d  '%s' \r", s.CtrlName, s.PopStr, s.eventcode, LstDiac()	// -1: control being killed,  2: mouse up,
	endif
	return	0																	// other return values reserved
End


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

static  Function		ConstructCbCheckboxAuto( sWNm, bDisable, bAutoscl )
	string  	sWNm
 	variable	bDisable, bAutoscl 
	Checkbox	CbCheckboxAuto,  win = $sWNm, size={ cXSZ_CB_AUTOSCL,20 },	proc=fDiacAutoScale,  title= "AutoScl"
	Checkbox	CbCheckboxAuto,  win = $sWNm, pos={ cXSZ_TB_TRACE + cXSZ_PM_TRACE, 2 }
	Checkbox	CbCheckboxAuto,  win = $sWNm, help={"Automatical Scaling works only with Dac but not with Adc traces."}
	ShowHideCbCheckboxAuto( sWNm, bDisable, bAutoscl  )							// Enable or disable the control  and possibly adjust its value
End
static  Function		ShowHideCbCheckboxAuto( sWNm, bDisable, bAutoscl  )
//  Hide, gray or display (=enable)  the control   and   set its  state/value/limits  correctly  (even when hidden).
	string  	sWNm
 	variable	bDisable, bAutoscl  
	Checkbox	CbCheckboxAuto,  win = $sWNm, disable =  bDisable, value = bAutoscl
End

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


static  Function		ConstructCbPopupmenuYZoom( sWNm, nio, cio, bDisable )
	string 	sWNm
	variable	nio, cio, bDisable
	variable	wn		= DiacWnd2Nr( sWNm )
	variable	YZoom	= str2num( DiacParameter_( sWNm, wn, nio, cio, kDIA_CV_YZOOM ) )
	PopupMenu LBZoom,   win = $sWNm, size = { cXSZ_PM_ZOOM, 20 }, 	proc=fDiacYZoom,	title="   yZoom"	
	PopupMenu LBZoom,   win = $sWNm, pos = { cXSZ_TB_TRACE + cXSZ_PM_TRACE + cXSZ_CB_AUTOSCL , 2 } 
//	PopupMenu LBZoom ,  win = $sWNm, help = {"If you have multiple traces in the windows, you must first select the trace to apply on, then the Y zoom factor."}
	ShowHideCbPopupmenuYZoom( sWNm, nio, cio, bDisable, YZoom )									// Enable or disable the control  and possibly adjust its value
End

static  Function		ShowHideCbPopupmenuYZoom( sWNm, nio, cio, bDisable, YZoom )
//  Hide, gray or display (=enable)  the control   and   set its  state/value/limits  correctly  (even when hidden).
	string 	sWNm
	variable	nio, cio, bDisable, YZoom
	variable	n, nSelected, nItemCnt	= ItemsInList( DiacZoomValues() )
	// Search the item in the list which corresponds to the desired value 'YZoom'
	for ( n = 0; n < nItemCnt; n += 1 )
		if ( str2num( StringFromList( n, ZoomValues() ) ) == YZoom )	// compare numbers, the numbers as strings might be formatted in different ways ( trailing zeros...)
			break
		endif
	endfor
	if ( n == nItemCnt )
		n = 4			// the desired value could not be found in the list,  so we select arbitrarily  a zoom of 1  to be displayed  which is the  4. item  in the list
	endif
	PopupMenu LBZoom,   win = $sWNm, disable = bDisable,  mode = n+1,  value = DiacZoomValues()	// n+1 sets the selected item in the Popupmenu,  counting starts at 1
End

//Function	/S	CbPopupmenuYZoomNm( nio, cio )
//	variable	nio, cio
//	return	 "CbPopupmenuYZoom"
//End

Function	/S	DiacZoomValues()							// Igor does not allow this function to be static
	return	".1;.2;.5;1;2;5;10;20;50;100"
End	

Function		 fDiacYZoom( s )
// Action proc executed when the user selects a zoom value from the Popupmenu.  Update  the  'Curves'  and  change axis and traces immediately to give some feedback.
	struct	WMPopupAction	&s
	 printf "\t\t\t\tfDiacZoom()  '%s'  gives  s.PopStr:'%s'  event:%d  \r", s.CtrlName, s.PopStr, s.eventcode	// bit field: bit 0: value set; 1: mouse down, 2: mouse up, 3: mouse moved
	string  	sFo	= ksACQ
	if (  s.eventcode == 2 )														// 2 : mouse up
		variable	wn		= DiacWnd2Nr( s.Win )
		variable	nio		= str2num( GetUserData( s.win,  "",  "nio" ) )					// Get UD nio	 Get the quasi-globally stored  type (dac or adc)  of the trace we are currently working on 
		variable	cio		= str2num( GetUserData( s.win,  "",  "cio" ) )					// Get UD cio	 Get the quasi-globally stored  linear index (0,1..) of the trace we are currently working on
		string  	llllst		= DiacParameterSet_( s.win,  wn, nio, cio, kDIA_CV_YZOOM, s.PopStr )		// 
		DiacUpdateFile( sFo, llllst )								// modify trc: update trc
		// The new YZoom has now been set and will be effective during the next acquisition, but we want to immediately give some feedback to the..
		// ..user so he sees his YZoom  change has been accepted , so we go on and change the Y Axis range in the existing window :
		string  	sChan	= DiacParameter_( s.Win, wn, nio, cio, kDIA_CV_IOTYP ) + DiacParameter_( s.Win, wn, nio, cio, kDIA_CV_IONR )	// this  channel  is  given by the band the user clicked into 

		variable  	YOfs		= str2num( DiacParameter_( s.Win, wn, nio, cio, kDIA_CV_YOFS ) )
		variable  	YZoom	= str2num( DiacParameter_( s.Win, wn, nio, cio, kDIA_CV_YZOOM ) )

		variable	Gain		= GainByNmForDisplay_ns( sFo, sChan )						// The user may change the AxoPatch Gain any time during acquisition

		 printf "\t\t fDiacYZoom()   wn:%d   nio:%2d   cio:%2d    yZoom:%g    sChan: '%s'     -> Gain: %g \r", wn, nio, cio, str2num( s.PopStr ), sChan, Gain
		DurAcqRescaleYAxis_6( s.Win, sChan, YOfs, YZoom, Gain )
	endif
	return	0																// other return values reserved
End

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

//static  Function		ConstructCbPopmenuColors( sWNm, bDisable, sRGB )
//	string 	sWNm, sRGB
//	variable	bDisable
//	variable	rnRed, rnGreen, rnBlue
//	UFCom_ExtractColors( sRGB, rnRed, rnGreen, rnBlue )
//	PopupMenu CbPopmenuColors,  win = $sWNm, size={ cXSZ_PM_COLOR,16 },	proc=fTraceColors,	title=""		
//	PopupMenu CbPopmenuColors,  win = $sWNm, pos={ cXSZ_TB_TRACE + +  cXSZ_PM_TRACE + cXSZ_CB_AUTOSCL + cXSZ_PM_ZOOM , 2 } 
//	PopupMenu CbPopmenuColors,  win = $sWNm, mode=1, popColor = ( rnRed, rnGreen, rnBlue ), value = "*COLORPOP*"
////	PopupMenu CbPopmenuColors,  win = $sWNm, help = {"If you have multiple traces in the windows, you must first select the trace to apply on, then the color."}
//	PopupMenu CbPopmenuColors,  win = $sWNm, disable = ! bDisable
//End

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


static  Function		ConstructCbCloseButton( sWNm, bDisable )
	string  	sWNm
 	variable	bDisable
 	Button	  CbCloseButton,  	win = $sWNm, size={ 16,14 },	proc=fCbCloseButton,  fsize = 10, fstyle = 1,  title= "X" , font = "MS Sans Serif"
	Button	  CbCloseButton,  	win = $sWNm, pos = { cXSZ_TB_TRACE +  cXSZ_PM_TRACE + cXSZ_CB_AUTOSCL + cXSZ_PM_ZOOM + cXSZ_PM_COLOR, 2 } 
	Button	  CbCloseButton,  	win = $sWNm, disable =  bDisable,  help={""}
End

Function	fCbCloseButton( s )
	struct	WMButtonAction	&s
	if ( s.eventcode == UFCom_CCE_mouseup )								// mouse up  inside button
		variable	nio		= str2num( GetUserData( s.win,  "",  "nio" ) )			// Get UD nio	 Get the quasi-globally stored  type (dac or adc)  of the trace we are currently working on 
		variable	cio		= str2num( GetUserData( s.win,  "",  "cio" ) )			// Get UD cio	 Get the quasi-globally stored  linear index (0,1..) of the trace we are currently working on
		CreateControlBarInAcqWnd_6(  s.win, nio, cio, UFCom_FALSE ) 
	endif
End

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

static  Function		ConstructCbSliderYOfs( sWNm, nio, cio, bDisable )
	string 	sWNm
	variable	nio, cio, bDisable 
	string  	sFo		= ksACQ
	variable	wn		= DiacWnd2Nr( sWNm )
	Slider 	CbSliderYOfs,   win = $sWNm,	proc = fDiacSliderYOfs 
	AdjustCbSliderYOfsToWnd( sWNm )
	string  	sChan	= DiacParameter_( sWNm, wn, nio, cio, kDIA_CV_IOTYP ) + DiacParameter_( sWNm, wn, nio, cio, kDIA_CV_IONR )	
	variable  	YOfs		= str2num( DiacParameter_( sWNm, wn, nio, cio, kDIA_CV_YOFS ) )
	variable  	YZoom	= str2num( DiacParameter_( sWNm, wn, nio, cio, kDIA_CV_YZOOM ) )
	variable	Gain		= GainByNmForDisplay_ns( sFo, sChan )
	ShowHideCbSliderYOfs( sWNm, bDisable, YOfs, Gain )								// Enable or disable the control  and possibly adjust its value
End

Function	AdjustCbSliderYOfsToWnd( sWNm )
	string 	sWNm
	GetWindow $sWNm, wSize												// Get the window dimensions in points .
	variable 	RightPix	= ( V_right	-  V_left )	* screenresolution / UFCom_kIGOR_POINTS72 	// Convert to pixels ( This has been tested for 1600x1200  AND  for  1280x1024 )
	variable 	BotPix	= ( V_bottom - V_top ) * screenresolution / UFCom_kIGOR_POINTS72 
	// printf  "\t\t\t\tAdjustCbSliderYOfsToWnd Slider  in '%s' \twindow dim in points:  %d  %d  %d  %d    -> RightPix: %d  %d  \r", sWNm, V_left,  V_top,  V_right,  V_bottom ,  RightPix, BotPix
//	Slider 	CbSliderYOfs,   win = $sWNm, vert = 1, side = 2,	size={ 0, BotPix - 30 },  pos = { RightPix -76, 28 }
	Slider 	CbSliderYOfs,   win = $sWNm, vert = 1, side = 2,	size={ 0, BotPix - ( 4 + kCB_HTLN0 + kCB_HTLN1) },  pos = { RightPix -76, 2 + kCB_HTLN0 + kCB_HTLN1 }
	//ControlInfo /W=$sWNm CbSliderYOfs
	// printf "\tControlInfo Slider  in '%s' \tleft:%d \twidth:%d \ttop:%d \theight:%d \r", sWNm,  V_left, V_width, V_top, V_height
End





static  Function		ShowHideCbSliderYOfs( sWNm, bDisable, YOfs, Gain )
//  Hide, gray or display (=enable)  the control   and   set its  state/value/limits  correctly  (even when hidden).
	string 	sWNm
	variable	bDisable, YOfs, Gain
	variable	ControlBarWidth 	=    bDisable == 1   ?	0  : 76		//  Vertical slider at the  right window border :only hide=1 sets width = 0 and makes the controlbar vanish, enable=0 and gray=2 display  the controlbar
	ControlBar /W = $sWNm  /R ControlBarWidth
	variable	DacRange		= 10								// + - Volt
	variable	YAxisWithoutZoom	= DacRange * 1000 / Gain 			
	// printf "\t\t\t\tShowHideCbSliderYOfs() \t'%s'\tDGn:\t%7.1lf\t-> Axis(without zoom):\t%7.1lf\tVal:\t%7.1lf\t  \r", sWNm, Gain, YAxisWithoutZoom, YOfs / Gain
	Slider	CbSliderYOfs,	win = $sWNm, 	disable = bDisable,	value = YOfs / Gain,	limits = { -YAxisWithoutZoom, YAxisWithoutZoom, 0 } 
End

Function			PossiblyAdjstSliderInAllWind_ns( sFo )
// We change the slider limits in all windows in which a slider is displayed
	string  	sFo
	variable	w, wCnt =  WndCnt()
print "todo  PossiblyAdjstSliderInAllWindows_ns( sFo )"
	for ( w = 0; w < wCnt; w += 1 )
		PossiblyAdjstSlider_ns( sFo, w )
	endfor
End

static Function		PossiblyAdjstSlider_ns( sFo, wn )
// We change the slider limits in all windows in which a slider is displayed
	string  	sFo
	variable	wn
//	string		sWNm	= WndNm( wn )
//	variable	nCurves	= CurvesCnt( wn )
//	variable	nCurve
//	for ( nCurve = 0; nCurve < nCurves; nCurve += 1 )
//		variable	rnRange, rnMode, rbAutoscl, rYOfs, rYZoom, rnAxis 
//		string		 rsTNm, rsRGB
//		ExtractCurve( w, nCurve, rsTNm, rnRange, rnMode, rbAutoscl, rYOfs, rYZoom, rnAxis, rsRGB )	// Get all traces/curves from this window...
//		variable	bAcqControlbar	= DiacControlBar( w )
//		variable	bDisableCtrlOfs	= DisableCtrlZoomOfs(      rsTNm, bAcqControlbar, rbAutoscl )		// Determine whether the control must be enabled or disabled
//		variable	Gain			= GainByNmForDisplay_ns( sFo, rsTNm )
//		ShowHideCbSliderYOfs( sWNm,  bDisableCtrlOfs, rYOfs, Gain )							// Enable or disable the control  and possibly adjust its value
//	endfor
End

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//  CONTROLBARS  in  the  ACQUISITION  WINDOWS  :  THE  ACTION  PROCEDURES

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


Function		fDiacAutoScale( s )
// Executed only when the user changes the 'AutoScale' checkbox : If it is turned on, then YZoom and YOfs values are computed so that the currently displayed trace is fitted to the window.
	struct	WMCheckboxAction	&s
	if (  s.eventcode != UFCom_kEV_ABOUT_TO_BE_KILLED )
		string  	sFo	= ksACQ
		variable	wn		= DiacWnd2Nr( s.Win )
		variable	nio		= str2num( GetUserData( s.win,  "",  "nio" ) )					// Get UD nio	 Get the quasi-globally stored  type (dac or adc)  of the trace we are currently working on 
		variable	cio		= str2num( GetUserData( s.win,  "",  "cio" ) )					// Get UD cio	 Get the quasi-globally stored  linear index (0,1..) of the trace we are currently working on
		variable	bAutoScl	= s.checked
//		string  	llllst		= DiacParameterSet_( s.win, wn, nio, cio, kDIA_CV_AUTOSCL, num2str( bAutoScl ) )		// 
//		DiacUpdateFile( sFo, llllst )													// modify trc: update trc
	
		// The Dac trace has now been rescaled in the curves internally and will  be shown with new scaling during the next acquisition, but we want to immediately give some feedback to the
		//... user so he sees his rescaling has been accepted , so we go on redrawing all windows
		string  	sChan	= DiacParameter_( s.Win, wn, nio, cio, kDIA_CV_IOTYP ) + DiacParameter_( s.Win, wn, nio, cio, kDIA_CV_IONR )	// this  channel  is  given by the band the user clicked into 
		variable  	YOfs		= str2num( DiacParameter_( s.Win, wn, nio, cio, kDIA_CV_YOFS ) )			// retrieve the current values  YOfs ...
		variable  	YZoom	= str2num( DiacParameter_( s.Win, wn, nio, cio, kDIA_CV_YZOOM ) )			// ...and YZoom  from  'llllstDiac' (was 'Curves')...

		variable	Gain		= GainByNmForDisplay_ns( sFo, sChan )

		AutoscaleZoomAndOfs_6( wn, sChan, bAutoscl, YOfs, YZoom, Gain )							// ...but possibly change these values (here references) if bAutoScl has been turned ON 
		string  llllst	= DiacParameterSet_( s.win, wn, nio, cio, kDIA_CV_AUTOSCL,	num2str( bAutoScl ) )		// 
		llllst		= DiacParameterSet_( s.win, wn, nio, cio, kDIA_CV_YOFS, 	num2str( YOfs ) )		// store the possibly changed values
	 	llllst		= DiacParameterSet_( s.win, wn, nio, cio, kDIA_CV_YZOOM, 	num2str( YZoom ) )		// 
		DiacUpdateFile( sFo, llllst )										// modify trc: update trc

		DurAcqRescaleYAxis_6( s.Win, sChan, YOfs, YZoom, Gain )
//		AutoscaleZoomAndOfs_6( wn, sChan, bAutoscl, YOfs, YZoom, Gain )
	
		// Hide the  Zoom  and  Offset  controls if  AutoScaling is ON, display them if Autoscaling is OFF
		variable	bAcqControlbar		= DiacControlBar( wn )
		variable	bDisableCtrlZoomOfs	= DisableCtrlZoomOfs( sChan, bAcqControlbar, bAutoScl )	// Determine whether the control must be enabled or disabled
		ShowHideCbPopupmenuYZoom( s.Win,  nio, cio, bDisableCtrlZoomOfs, YZoom )				// Enable or disable the control  and possibly adjust its value
		ShowHideCbSliderYOfs( 	s.Win,  bDisableCtrlZoomOfs, YOfs, Gain )					// Enable or disable the control  and possibly adjust its value
	endif
	return	0																// other return values reserved
End



static   Function		AutoscaleZoomAndOfs_6( wn, sTNm, bAutoscl, rYOfs, rYZoom, Gain )
// Adjust   YZoom  and   YOffset  values  depending on the state of the  'Autoscale'  checkbox.  Return the changed  YZoom  and  YOfs  values  so that they can be stored in the curves  so that the next redraw will reflect the changed values.
	string 	sTNm				// does not include folder, e.g. 'dac0'
	variable	wn, bAutoscl, Gain 
	variable	&rYOfs, &rYZoom

	string 	sWNm		= DiacWnd( wn )
	variable	YAxis		= 0
	variable	DacRange	= 10								// + - Volt
	if ( bAutoscl )											// The checkbox  'Autoscale Y axis'  has been turned  ON :

		wave 	      wData	= TraceNameToWaveRef( sWNm, sTNm )
		// OR wave    wData	= $DiacqFoTrcNm( sFo, sWNm, sIOType, sIONr, nRange ) // includes folder
		waveStats	/Q  wData									// 	...We compute the maximum/mimimum Dac values from the stimulus and set the zoom factor... 

		if ( cbAUTOSCALE_SYMMETRIC )						// 		Use symmetrical axes, the length is the longer of both. The window is filled to 90% . 
			 YAxis	= max( abs( V_max ), abs( V_min ) ) / .9	
			 rYOfs	= 0
		else												// 		The length of pos. and neg. half axis is adjusted separately.  The window is filled to 90% . 
			YAxis	= (  V_max   -  V_min  ) 		 / 2 / .9 
			rYOfs	= (  V_max  +  V_min  ) / Gain	 / 2  
		endif		

		rYZoom	= DacRange * 1000 / YAxis				
		 printf "\t\t\tAutoscaleZoomAndOfs( '%s' \t'%s'\tpts:\t%8d\t bAutoscl: %s )\tVmax:\t%7.2lf\tVmin:\t%7.2lf\tYaxis:\t%7.1lf\tYzoom:\t%7.2lf\tYofs:\t%7.1lf\tGain:\t%7.1lf\tsLBZoom:'%s'   \r",  sWNm, sTNm, numPnts( wData ), SelectString( bAutoscl, "OFF" , "ON" ), V_max, V_min, YAxis, rYZoom, rYOfs, Gain, "LBZoom"
	else													//  The checkbox  'Autoscale Y axis'  has been turned  OFF : So we restore and use the user supplied zoom factor setting from the Popupmenu
														//  We do not restore the  YOfs from slider because 	1. YOfs is at the optimum position as it has just been autoscaled  and the user can very easily  (re)adjust to any new position   
		ControlInfo /W=$sWNm LBZoom						//										2. the YOfs prior to AutoScaling would have had to be stored to be able to retrieve it which is not done in this version 
		rYZoom	= str2num( S_Value )							// Get the controls current value by reading S_Value  which is set by  ControlInfo
		 printf "\t\t\tAutoscaleZoomAndOfs( '%s' \t'%s'\t\t\t\t bAutoscl: %s )\t\t\t\t\tReturning zoom value from popupmenu: \tYzoom:\t%7.2lf\tsLBZoom:'%s'   \r",  sWNm, sTNm,  SelectString( bAutoscl, "OFF" , "ON" ), rYZoom, "LBZoom"
	endif
End


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
//		string		sAxisNm		= YAxis_Name( rnAxis ) 									
//		TextBox 	/W=$s.win /C /N=$sAxisNm   /G=( nRed, nGreen, nBlue)  					// the textbox has the same name as its axis
//	endif
//	return	0																// other return values reserved
//End


Function		fDiacSliderYOfs( s )
	struct	WMSliderAction	&s
	// printf "\t\t\t\tfDiacSliderYOfs()  '%s'  gives value:%d  event:%d  \r", s.CtrlName, s.curval, s.eventcode	// bit field: bit 0: value set; 1: mouse down, 2: mouse up, 3: mouse moved
	string  	sFo	= ksACQ

	if (  s.eventcode & 4  ||  s.eventcode & 9 )											// bit field expanded: 4 is mouse up, 9 is mouse moved + value set
		variable	wn		= DiacWnd2Nr( s.Win )
		variable	nio		= str2num( GetUserData( s.win,  "",  "nio" ) )					// Get UD nio	 Get the quasi-globally stored  type (dac or adc)  of the trace we are currently working on 
		variable	cio		= str2num( GetUserData( s.win,  "",  "cio" ) )					// Get UD cio	 Get the quasi-globally stored  linear index (0,1..) of the trace we are currently working on
		string  	llllst		= DiacParameterSet_( s.win, wn, nio, cio, kDIA_CV_YOFS, num2str( s.curval ) )	// 
		if (  s.eventcode & 4 )														// bit field expanded: 4 is mouse up, 9 is mouse moved + value set
			DiacUpdateFile( sFo, llllst )												// write only final file, not on every slider movement, (modify trc: update Trc)
		endif
		// The new YOffset has now been set and will be effective during the next acquisition, but we want to immediately give some feedback to the..
		// ..user so he sees his YOffset change has been accepted , so we go on and change the Yoffset in the existing window :
		string  	sChan	= DiacParameter_( s.Win, wn, nio, cio, kDIA_CV_IOTYP ) + DiacParameter_( s.Win, wn, nio, cio, kDIA_CV_IONR )	// this  channel  is  given by the band the user clicked into 
		variable  	YOfs		= str2num( DiacParameter_( s.Win, wn, nio, cio, kDIA_CV_YOFS ) )
		variable  	YZoom	= str2num( DiacParameter_( s.Win, wn, nio, cio, kDIA_CV_YZOOM ) )

		variable	Gain		= GainByNmForDisplay_ns( sFo, sChan )						// The user may change the AxoPatch Gain any time during acquisition

		DurAcqRescaleYAxis_6( s.Win, sChan, YOfs, YZoom, Gain )
	endif
	return	0																// other return values reserved
End


 Function		GainByNmForDisplay_ns( sFo, sTNm )
// Retrieves and returns gain for displaying traces  when the channel name is given,  e.g. 'Adc0'  or  'Dac2'
// The DISPLAY Gain for Dacs is always 1 no matter what the script gain is  as the script  Dac gain affects only the voltage output, not the displayed traces.
// The display of  Adc  and  PoN  traces is effected by their gain.   [ Exotic traces traces like  'Aver'  or  'Sum'   (not yet used)   are also effected by their gain, this behaviour could in the future be changed here...
	string 	sFo, sTNm
	variable	Gain		= 1
	variable	nio, cio
	string 	sSrc		= "none"
	variable	nSrcIO, nSrcC
	svar	/Z	lllstIO		= $"root:uf:" + sFo + ":lllstIO"  						

	UFPE_ioNm2NioC_ns( lllstIO, sTNm, nio, cio )					// searches nio and cio corresponding to 'sTNm' .  Slow and not very effective....

	if ( IsDacTrace( sTNm ) )
		Gain	= 1											// For displaying Dac traces we must ignore the Gain. The Dac gain affects only the voltage output, not the displayed traces.
//	elseif ( IsPoNTrace( sTNm ) )
//		sSrc	= "Adc" + UFPE_ios( wIO, nio, cio, UFPE_IO_SRC ) 		// Assumption: naming convention
//		UFPE_ioNm2NioC_ns( lllstIO, sSrc, nSrcIO, nSrcC )
//		Gain	= UFPE_iov_ns( lllstIO, nSrcIO, nSrcC, kSC_IO_GAIN )	// PoN traces have no explicit gain but inherit it from their 'Adc' src channel.
	else				
		Gain	= UFPE_iov_ns( lllstIO, nio, cio, kSC_IO_GAIN )			// todo:  should apply to Adc and Pon traces
	endif

	if ( numType( gain ) == UFCom_kNUMTYPE_NAN )
		 printf "\t\t\t\t\tGainByNmForDisplay_ns( '%s' ) \t-> cio:%2d\thas Src:\t%s\treturns display gain:\t%7.2lf\t\t(Dacs always return 1) \r", UFCom_pd(sTNm,9), cio, UFCom_pd( sSrc,6), Gain
	endif
	return	Gain
End


	static  Function		DurAcqRescaleYAxis_6( sWNm, sAxisNm, YOfs, YZoom, Gain )	
	// Similar to  DurAcqRescaleYAxisOld()  but rather than storing the axis end values, checking for changes and possible rescaling  here no values are stored or checked but the rescaling is done every time (this is much simpler but could be slower...)
		variable	YOfs, YZoom, Gain
		string		sWNm, sAxisNm
		variable	AdcRange			= 10								//  + - Volt
		variable	yAxis 			= AdcRange * 1000  / YZoom						
		variable	NegLimit			= - yAxis / Gain + YOfs
		variable	PosLimit			=   yAxis / Gain + YOfs
		SetAxis /Z /W=$sWNm $sAxisNm,  NegLimit, PosLimit
	End
	


//===========================================================================================================================================
//  DIA CONTROLBAR 2 :  X  AXIS MANIPULATION 
//  Display acq:  Action procs for scaling the traces (zoom, shift, autoscale etc.)

static constant  XFCT		= 2
static constant  XSHIFT	= .9


//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

static  Function		ConstructCbCheckboxInclude( sWNm, bDisable, bIncludeNoStore )
	string  	sWNm
 	variable	bDisable, bIncludeNoStore 
	Checkbox	CbCheckboxInclude,  win = $sWNm, size={ cXSZ_CB_AUTOSCL,20 },	proc=fDiacInclNoStore,  title= "Include no-store"
	Checkbox	CbCheckboxInclude,  win = $sWNm, pos={  0 , 2 + kCB_HTLN0  }
	Checkbox	CbCheckboxInclude,  win = $sWNm, help={"The time scale is misleading if no-store periods are skipped."}
	ShowHideCbCheckboxInclude( sWNm, bDisable, bIncludeNoStore  )							// Enable or disable the control  and possibly adjust its value
End
static  Function		ShowHideCbCheckboxInclude( sWNm, bDisable, bIncludeNoStore  )
//  Hide, gray or display (=enable)  the control   and   set its  state/value/limits  correctly  (even when hidden).
	string  	sWNm
 	variable	bDisable, bIncludeNoStore  
	Checkbox	CbCheckboxInclude,  win = $sWNm, disable =  bDisable, value = bIncludeNoStore
End

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

//static  Function		ConstructCbSweepButton( sWNm, bDisable )
//	string  	sWNm
// 	variable	bDisable 
// 	Button	  CbSweepButton,  	win = $sWNm, size={ 36,14 },  proc=fXSweep_a,	fsize = 10, fstyle = 0,  title= "sweep" , font = "MS Sans Serif"
//	Button	  CbSweepButton,  	win = $sWNm, pos = { cXSZ_CB_INCLUDE + 1 * cXSZ_BUT_NARROW, 2 + kCB_HTLN0 } 
//	Button	  CbSweepButton,  	win = $sWNm, disable =  bDisable,  help={""}
//End

static  Function		ConstructCbFrameButton( sWNm, bDisable )
	string  	sWNm
 	variable	bDisable 
 	Button	  CbFrameButton,  	win = $sWNm, size={ 36,14 },  proc=fXFrame_a,	fsize = 10, fstyle = 0,  title= "frame" , font = "MS Sans Serif"
	Button	  CbFrameButton,  	win = $sWNm, pos = { cXSZ_CB_INCLUDE + 3 * cXSZ_BUT_NARROW, 2 + kCB_HTLN0 } 
	Button	  CbFrameButton,  	win = $sWNm, disable =  bDisable,  help={""}
End

static  Function		ConstructCbLapButton( sWNm, bDisable )
	string  	sWNm
 	variable	bDisable 
 	Button	  CbLapButton,  		win = $sWNm, size={ 36,14 },  proc=fXLap_a,	fsize = 10, fstyle = 0,  title= "lap" , font = "MS Sans Serif"
	Button	  CbLapButton,  		win = $sWNm, pos = { cXSZ_CB_INCLUDE + 5 * cXSZ_BUT_NARROW, 2 + kCB_HTLN0 } 
	Button	  CbLapButton,  		win = $sWNm, disable =  bDisable,  help={""}
End

static  Function		ConstructCbCompressButton( sWNm, bDisable )
	string  	sWNm
 	variable	bDisable 
 	Button	  CbCompressButton, 	win = $sWNm, size={ 16,14 },  proc=fXCompress_a, fsize = 10, fstyle = 1,  title= "><" , font = "MS Sans Serif"
	Button	  CbCompressButton, 	win = $sWNm, pos = { cXSZ_CB_INCLUDE + 8 * cXSZ_BUT_NARROW, 2 + kCB_HTLN0 } 
	Button	  CbCompressButton, 	win = $sWNm, disable =  bDisable,  help={""}
End

static  Function		ConstructCbExpandButton( sWNm, bDisable )
	string  	sWNm
 	variable	bDisable 
 	Button	  CbExpandButton,  	win = $sWNm, size={ 16,14 },  proc=fXExpand_a, fsize = 10, fstyle = 1,  title= "<>" , font = "MS Sans Serif"
	Button	  CbExpandButton,  	win = $sWNm, pos = { cXSZ_CB_INCLUDE + 9 * cXSZ_BUT_NARROW, 2 + kCB_HTLN0 } 
	Button	  CbExpandButton,  	win = $sWNm, disable =  bDisable,  help={""}
End

static  Function		ConstructCbReverseButton( sWNm, bDisable )
	string  	sWNm
 	variable	bDisable 
 	Button	  CbReverseButton,  	win = $sWNm, size={ 16,14 },  proc=fXReverse_a, fsize = 10, fstyle = 1,  title= "<<" , font = "MS Sans Serif"
	Button	  CbReverseButton,  	win = $sWNm, pos = { cXSZ_CB_INCLUDE + 11 * cXSZ_BUT_NARROW, 2 + kCB_HTLN0 } 
	Button	  CbReverseButton,  	win = $sWNm, disable =  bDisable,  help={""}
End

static  Function		ConstructCbReversButton( sWNm, bDisable )
	string  	sWNm
 	variable	bDisable 
 	Button	  CbReversButton,  	win = $sWNm, size={ 16,14 },  proc=fXRevers_a,	fsize = 10, fstyle = 1,  title= "<" , font = "MS Sans Serif"
	Button	  CbReversButton,  	win = $sWNm, pos = { cXSZ_CB_INCLUDE + 12 * cXSZ_BUT_NARROW, 2 + kCB_HTLN0 } 
	Button	  CbReversButton,  	win = $sWNm, disable =  bDisable,  help={""}
End

static  Function		ConstructCbAdvancButton( sWNm, bDisable )
	string  	sWNm
 	variable	bDisable 
 	Button	  CbAdvancButton,  	win = $sWNm, size={ 16,14 },  proc=fXAdvanc_a,  fsize = 10, fstyle = 1,  title= ">" , font = "MS Sans Serif"
	Button	  CbAdvancButton,  	win = $sWNm, pos = { cXSZ_CB_INCLUDE + 13 * cXSZ_BUT_NARROW, 2 + kCB_HTLN0 } 
	Button	  CbAdvancButton,  	win = $sWNm, disable =  bDisable,  help={""}
End

static  Function		ConstructCbAdvanceButton( sWNm, bDisable )
	string  	sWNm
 	variable	bDisable 
 	Button	  CbAdvanceButton,  	win = $sWNm, size={ 16,14 },  proc=fXAdvance_a, fsize = 10, fstyle = 1,  title= ">>" , font = "MS Sans Serif"
	Button	  CbAdvanceButton,  	win = $sWNm, pos = { cXSZ_CB_INCLUDE + 14 * cXSZ_BUT_NARROW, 2 + kCB_HTLN0 } 
	Button	  CbAdvanceButton,  	win = $sWNm, disable =  bDisable,  help={""}
End

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


static  Function	/S	BuildThisTraceNm( sFo, sWNm )
 	string		sFo, sWNm
	variable	nio		= str2num( GetUserData( sWNm,  "",  "nio" ) )					// Get UD nio	 Get the quasi-globally stored  type (dac or adc)  of the trace we are currently working on 
	variable	cio		= str2num( GetUserData( sWNm,  "",  "cio" ) )					// Get UD cio	 Get the quasi-globally stored  linear index (0,1..) of the trace we are currently working on
 	string  	sIOType	= StringFromList( nio, klstSC_NIO )
	string  	sIONr	= UFPE_ioItem__( sFo, nio, cio, kSC_IO_CHAN )
	return	DiacqFoTrcNm( sFo, sWNm, sIOType, sIONr )
End


Function		fDiacInclNoStore( s )
	struct	WMCheckboxAction	&s
	DiacIncludeNoStoreSet( ksACQ, s.win, s.checked )

// perhaps  less code must be executed
	variable	wn			= DiacWnd2Nr( s.win )
	string  	lstSomeWaves	= LstDiacAdcAndDacDim2( wn )
	DiacDisplayChannelsXRange( ksACQ, ksFPUL, s.win, lstSomeWaves )
End
	
	
//Function		fXSweep_a(  s ) 
//	struct	WMButtonAction	&s
//	if ( s.eventcode == 2 )					// 2 is mouse up
//		DiacRangeSet( ksACQ, s.win, kRA_SWEEP )
//
//		variable	wn			= DiacWnd2Nr( s.win )
//		string  	lstSomeWaves	= LstDiacAdcAndDacDim2( wn )
//		DiacDisplayChannelsXRange( ksACQ, ksFPUL, s.win, lstSomeWaves )
//
//		string 	sTNm	= BuildThisTraceNm( ksACQ, s.win ) 
//		variable	xLnew	= 0
//		variable	xRnew	= rightx( $sTNm )
//		SetAxis	/W=$s.win  bottom, xLnew, xRnew
//	endif
//End


Function		fXFrame_a(  s ) 
	struct	WMButtonAction	&s
	if ( s.eventcode == 2 )					// 2 is mouse up
		DiacRangeSet( ksACQ, s.win, kRA_FRAME )

		variable	wn			= DiacWnd2Nr( s.win )
		string  	lstSomeWaves	= LstDiacAdcAndDacDim2( wn )
		DiacDisplayChannelsXRange( ksACQ, ksFPUL, s.win, lstSomeWaves )

		string 	sTNm	= BuildThisTraceNm( ksACQ, s.win ) 
		variable	xLnew	= 0
		variable	xRnew	= rightx( $sTNm )
		SetAxis	/W=$s.win  bottom, xLnew, xRnew
	endif
End

// 080625
//		variable	nRange	= kRA_LAP
//		variable	nio		= str2num( GetUserData( s.win,  "",  "nio" ) )					// Get UD nio	 Get the quasi-globally stored  type (dac or adc)  of the trace we are currently working on 
//		variable	cio		= str2num( GetUserData( s.win,  "",  "cio" ) )					// Get UD cio	 Get the quasi-globally stored  linear index (0,1..) of the trace we are currently working on
//		string  	sIOType	= DiacParameter_( sWNm, wn, nio, cio, kDIA_CV_IOTYP )
//		string  	sIONr	= DiacParameter_( sWNm, wn, nio, cio, kDIA_CV_IONR )		// determine channel name _before_ 'DiacParameterClearCurve()' below
//		string  	sFoTrcNm	= DiacqFoTrcNm( ksACQ, s.win, sIOType, sIONr, nRange )
//		string  	sTNmKill	= DiacqTrcNm( sIOType, sIONr, nRange )
//		RemoveFromGraph 	/Z /W=$s.win, 	$sTNmKill			
//	Killwaves 			/Z			$sFoTrcNm

// 080625
//		variable	nRange	= kRA_LAP
//		string  	sFolder	= "root:uf:" + ksACQ + ":" + ksDIA + ":" +  s.win + ":" + DiacRangeNm( nRange ) 
//		KillDataFolder /Z $sFolder
	endif
End


Function		fXLap_a(  s ) 
	struct	WMButtonAction	&s
	if ( s.eventcode == 2 )					// 2 is mouse up
		DiacRangeSet( ksACQ, s.win, kRA_LAP )

		variable	wn			= DiacWnd2Nr( s.win )
		string  	lstSomeWaves	= LstDiacAdcAndDacDim2( wn )
		DiacDisplayChannelsXRange( ksACQ, ksFPUL, s.win, lstSomeWaves )

		string 	sTNm	= BuildThisTraceNm( ksACQ, s.win ) 
		variable	xLnew	= 0
		variable	xRnew	= rightx( $sTNm )
		SetAxis	/W=$s.win  bottom, xLnew, xRnew

// 080625
//		variable	nRange	= kRA_FRAME
//		variable	nio		= str2num( GetUserData( s.win,  "",  "nio" ) )					// Get UD nio	 Get the quasi-globally stored  type (dac or adc)  of the trace we are currently working on 
//		variable	cio		= str2num( GetUserData( s.win,  "",  "cio" ) )					// Get UD cio	 Get the quasi-globally stored  linear index (0,1..) of the trace we are currently working on
//		string  	sIOType	= DiacParameter_( sWNm, wn, nio, cio, kDIA_CV_IOTYP )
//		string  	sIONr	= DiacParameter_( sWNm, wn, nio, cio, kDIA_CV_IONR )		// determine channel name _before_ 'DiacParameterClearCurve()' below
//		string  	sFoTrcNm	= DiacqFoTrcNm( ksACQ, s.win, sIOType, sIONr, nRange )
//		string  	sTNmKill	= DiacqTrcNm( sIOType, sIONr, nRange )
//		RemoveFromGraph 	/Z /W=$s.win, 	$sTNmKill			
//		Killwaves 			/Z			$sFoTrcNm

// 080625
//		variable	nRange	= kRA_FRAME
//		string  	sFolder	= "root:uf:" + ksACQ + ":" + ksDIA + ":" +  s.win + ":" + DiacRangeNm( nRange ) 
//		KillDataFolder /Z $sFolder

	endif
End


Function		fXCompress_a(  s ) 
	struct	WMButtonAction	&s
	if ( s.eventcode == 2 )					// 2 is mouse up
		GetAxis	/W=$s.win  /Q bottom
		if ( V_Flag == 0 )			// axis exists
			string 	sTNm	= BuildThisTraceNm( ksACQ, s.win ) 
			variable	nAllPts	= numPnts( $sTNm )
			variable	xL		= V_min
			variable	xR		= V_max
			variable	xMid		=  ( V_max + V_min ) / 2
			variable	xDif		= V_max - V_min
			variable	xLnew	= max ( 0, xMid + ( xL- xMid ) * XFCT )
			variable	xRnew	= min( xMid + ( xR- xMid ) * XFCT, rightx( $sTNm ) )
		
			 printf "\t\t%s\t'%s'\tPts:\t%8d\tV_min:\t%8d\tV_max:\t%8d\tMid:\t%8d\tDif:\t%g\t->V__min:\t%8d\tV_max:\t%8d\t \r",  s.CtrlName, sTNm, nAllPts, V_min, V_max, xMid,  xDif, xLnew, xRnew
			SetAxis	/W=$s.win  bottom, xLnew, xRnew
		endif
	endif
End

Function		fXExpand_a(  s ) 
	struct	WMButtonAction	&s
	if ( s.eventcode == 2 )					// 2 is mouse up
		GetAxis	/W=$s.win  /Q bottom
		if ( V_Flag == 0 )			// axis exists
			string 	sTNm	= BuildThisTraceNm( ksACQ, s.win ) 
			variable	nAllPts	= numPnts( $sTNm )
			variable	xL		= V_min
			variable	xR		= V_max
			variable	xMid		=  ( V_max + V_min ) / 2
			variable	xDif		= V_max - V_min
			variable	xLnew	= xMid + ( xL- xMid ) / XFCT
			variable	xRnew	= xMid + ( xR- xMid ) / XFCT
			 printf "\t\t%s\t'%s'\tPts:\t%8d\tV_min:\t%8d\tV_max:\t%8d\tMid:\t%8d\tDif:\t%g\t->V__min:\t%8d\tV_max:\t%8d\t \r",  s.CtrlName, sTNm, nAllPts, V_min, V_max, xMid,  xDif, xLnew, xRnew
			SetAxis	/W=$s.win  bottom, xLnew, xRnew
		endif
	endif
End

Function		fXAdvance_a(  s ) 
// Step forward big step (~90% of displayed range) 
	struct	WMButtonAction	&s
	XAdvance( s, XSHIFT )
End

Function		fXAdvanc_a(  s ) 
// Step forward small step (~18% of displayed range) 
	struct	WMButtonAction	&s
	XAdvance( s, XSHIFT/5 )
End

static Function 	XAdvance( s, step )
	struct	WMButtonAction	&s
	variable	step
	if ( s.eventcode == 2 )					// 2 is mouse up
		GetAxis	/W=$s.win  /Q bottom
		if ( V_Flag == 0 )			// axis exists
			string 	sTNm	= BuildThisTraceNm( ksACQ, s.win ) 
			variable	nAllPts	= numPnts( $sTNm )
			variable	xL		= V_min
			variable	xR		= V_max
			variable	xMid		= ( V_max + V_min ) / 2
			variable	xDif		= V_max - V_min
			variable	xRnew	= min( rightx( $sTNm ), xR + xDif * step )
			variable	xLnew	= xRnew - xDif
			 printf "\t\t%s\t'%s'\tPts:\t%8d\tV_min:\t%8d\tV_max:\t%8d\tMid:\t%8d\tDif:\t%g\t->V__min:\t%8d\tV_max:\t%8d\t \r",  s.CtrlName, sTNm, nAllPts, V_min, V_max, xMid,  xDif, xLnew, xRnew
			SetAxis	/W=$s.win  bottom, xLnew, xRnew
		endif
	endif
End

Function		fXReverse_a(  s ) 
// Step back big step (~90% of displayed range) 
	struct	WMButtonAction	&s
	XRevers_a(  s, XSHIFT )
End 

Function		fXRevers_a(  s ) 
// Step back small step (~18% of displayed range) 
	struct	WMButtonAction	&s
	XRevers_a(  s, XSHIFT/5 )
End 

static Function	XRevers_a(  s, step ) 
	struct	WMButtonAction	&s
	variable	step
	variable	ch 		= 0
	if ( s.eventcode == 2 )					// 2 is mouse up
		GetAxis	/W=$s.win  /Q bottom
		if ( V_Flag == 0 )			// axis exists
			string 	sTNm	= BuildThisTraceNm( ksACQ, s.win ) 
			variable	nAllPts	= numPnts( $sTNm )
			variable	xL		= V_min
			variable	xR		= V_max
			variable	xMid		= ( V_max + V_min ) / 2
			variable	xDif		= V_max - V_min
			variable	xLnew	= max( 0, xL - xDif * step )		
			variable	xRnew	= xLnew + xDif
			 printf "\t\t%s\t'%s'\tPts:\t%8d\tV_min:\t%8d\tV_max:\t%8d\tMid:\t%8d\tDif:\t%g\t->V__min:\t%8d\tV_max:\t%8d\t \r",  s.CtrlName, sTNm, nAllPts, V_min, V_max, xMid,  xDif, xLnew, xRnew
			SetAxis	/W=$s.win  bottom, xLnew, xRnew
		endif
	endif
End


