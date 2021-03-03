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

// 2006-0606  NO LONGER  ninstn.....
//	The code must allow multiple instances of the same trace allowing the same data to be displayed at the same time with different zoom factors,..
//	  ...for this we must do much bookkeeping because Igor has the restriction of requiring the same trace=wave name but appends its own instance number whereas we must do our own instance counting in Curves
// 2006-0606  NO LONGER  DisplayOffLine().
//	We take the approach to not even try to keep track which instances of which traces in which windows have to be redrawn, instead we we redraw all ( -> DisplayOffLine() )
//	This is sort of an overkill but here we do it only once in response to a (slow) user action while during acq we do the same routine (=updating all acq windows) very often... 
// 	...so we accept the (theoretical) disadvantage of updating traces which actually would have needed no update because it simplifies the program code tremendously  .

// Major revision 2004-01-08..2004-02-04
// Major revision 2006-05-20..2006-06-10

static constant	kCB_HTLN0				= 26		// 26 is the minimum value required for a popupmenu
static constant	kCB_HTLN1				= 20		// 20 is sufficient if the line only contains buttons 
static constant	cXSZ_TB_TRACE			= 80		// empirical values, could be computed .  81 for 'Dac0SC' , 86 for 'Dac0SCa' , 92 for 'Dac0 SC a', 110 for 'Dac0 Sweeps C'
static constant	cXSZ_CB_AUTOSCL			= 60		// 60 for 'AutoScl'
static constant	cXSZ_CB_TRUETIME		= 80		// 
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

  Function		CreateControlBarInAcqWnd_6( sWNm, wn, nio, cio, bAcqControlbar ) 
// depending on  'bAcqControlbar'  build and show or hide the controlbar  AND  show or hide the individual controls (buttons, checkboxes and popmenus..)
	string  	sWNm
	variable	wn, nio, cio, bAcqControlbar										// Show or hide the controlbar
	string  	sFo		= ksACQ

//	variable	wn		= DiacWnd2Nr( sWNm )
	string  	sChan	= DiacTraceChannel( sWNm, wn, nio, cio )

	variable	rYOfs, rYZoom
	variable	bTrueTime	= DiacTrueTime( sFo, sWNm )

	variable	ControlBarHeight = bAcqControlbar ?  kCB_HTLN0 + kCB_HTLN1 :  0 		// height 0 effectively hides the whole controlbar
	ControlBar /T /W = $sWNm  ControlBarHeight 								// /T creates at top, /B creates at bottom
	SetWindow	$sWNm,  	UserData( nio )	= num2str( nio )						// Set UD nio		Store the type (dac or adc)  of the trace we are currently working on quasi-globally within the graph
	SetWindow	$sWNm,  	UserData( cio )	= num2str( cio )						// Set UD cio		Store the linear index (0,1..) of the trace we are currently working on quasi-globally within the graph

	 printf "\t\t\tCreateControlBarInAcqWnd_6 \t\t\t\t\t\t'%s':%d\tni:%d\tci:%d\t%s\tbAcqCb:%2d \t \t \t \r",  sWNm, wn, nio, cio, UFCom_pd( sChan,7), bAcqControlbar
	ConstructCbTitleboxTraceNm( sWNm,  bAcqControlbar, sChan )				// 
//	ConstructCbPopmenuColors( sWNm,  bAcqControlbar, rsRGB )					//

	variable	rbAutoscl			= DiacTraceAutoScl( sWNm, wn, nio, cio )
	variable	bDisableCtrlAutoscl	= DisableCtrlAutoscl( sChan, bAcqControlbar ) 
	variable	bDisableCtrlZoomOfs	= DisableCtrlZoomOfs( sChan, bAcqControlbar, rbAutoscl ) 

	ConstructCbCheckboxAuto( 		sWNm, bDisableCtrlAutoscl, rbAutoscl )						

	ConstructCbCheckboxTrueTime(		sWNm,  !bAcqControlbar , bTrueTime )
	ConstructCbDatasctButton(			sWNm,  !bAcqControlbar  )
	ConstructCbFrameButton(			sWNm,  !bAcqControlbar  )
	ConstructCbLapButton( 			sWNm,  !bAcqControlbar  )
// 2009-04-02
	DiacHighlightRangeButton( sWNm, DiacRange( sFo, sWNm ) )
	ConstructCbCompressButton( 		sWNm,  !bAcqControlbar  )
	ConstructCbExpandButton( 		sWNm,  !bAcqControlbar  )
	ConstructCbReverseButton( 		sWNm,  !bAcqControlbar  )
	ConstructCbReversButton( 			sWNm,  !bAcqControlbar  )
	ConstructCbAdvancButton( 		sWNm,  !bAcqControlbar  )
	ConstructCbAdvanceButton( 		sWNm,  !bAcqControlbar  )
	ConstructCbXResetButton( 		sWNm,  !bAcqControlbar  )

	ConstructCbCloseButton( 			sWNm,  !bAcqControlbar )

	ConstructCbPopupmenuAddTrace(	sWNm, nio, cio, !bAcqControlbar, sChan  )
	ConstructCbPopupmenuYZoom( 		sWNm, nio, cio, bDisableCtrlZoomOfs )						
	ConstructCbCheckboxSliderShow(	sWNm, nio, cio, bDisableCtrlZoomOfs )

// 2009-03-06
//	ConstructCbSliderYOfs( 			sWNm, nio, cio, bDisableCtrlZoomOfs )								// also construct the optional Controlbar on the right (only in Igor5) 
	ConstructCbSliderYOfs( 			sWNm, nio, cio, bDisableCtrlZoomOfs  ||  ! CheckboxSliderShowState( sWNm ) )	// also construct the optional Controlbar on the right (only in Igor5) 

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


Function	/S	DiacTracesToAdd()									// Igor does not allow this function to be static
	return	LstIOAllDacAllAdc1Dim( ksACQ )
End	


Function		 fDiacAddTrace( s )
// Action proc executed when the user selects a trace from the  'AddTrace'  Popupmenu.  
	struct	WMPopupAction	&s
	string  	sFo		= ksACQ
	string  	sSubFoIni	=  "Scrip"
	if (  s.eventcode == UFCom_PME_MouseUp )									
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
		variable Gain		=  1357//str2num( UFPE_ioItem( lllstIO, nio, cio, kSC_IO_GAIN  )	)	 ;			Gain = numType( Gain ) == UFCom_kNUMTYPE_NAN  ?  1  :  Gain 	

		llllstDiac	= DiacTraceAdd( sFo, s.Win, wn, nio, cio, sIOType, sIONr, sIONm, sUnits, bAutoscl, YOfs, YZoom, Gain )

		llllstDiac 	= LstDiac(); 	UFCom_DisplayMultipleList( "fDiacAddTrace exit",  llllstDiac, DiacSeps(), 31 )  
		DiacUpdateFile( sFo, sSubFoIni, llllstDiac )									// modify trc: update trc

		string  	lstSomeWaves	= DiacqListAdcAndDacDim2( wn )
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
	variable	YZoom	= DiacTraceYZoom( sWNm, wn, nio, cio )
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
		if ( str2num( StringFromList( n, DiacZoomValues() ) ) == YZoom )	// compare numbers, the numbers as strings might be formatted in different ways ( trailing zeros...)
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
	// printf "\t\t\t\tfDiacZoom()  '%s'  gives  s.PopStr:'%s'  event:%d  \r", s.CtrlName, s.PopStr, s.eventcode	// bit field: bit 0: value set; 1: mouse down, 2: mouse up, 3: mouse moved
	string  	sFo		= ksACQ
	string  	sSubFoIni	=  "Scrip"
	if (  s.eventcode == 2 )														// 2 : mouse up
		variable	wn		= DiacWnd2Nr( s.Win )
		variable	nio		= str2num( GetUserData( s.win,  "",  "nio" ) )					// Get UD nio	 Get the quasi-globally stored  type (dac or adc)  of the trace we are currently working on 
		variable	cio		= str2num( GetUserData( s.win,  "",  "cio" ) )					// Get UD cio	 Get the quasi-globally stored  linear index (0,1..) of the trace we are currently working on
		string  	llllst		= DiacTraceYZoomSet( s.win,  wn, nio, cio, str2num(s.PopStr) )		// 
		DiacUpdateFile( sFo, sSubFoIni, llllst )								// modify trc: update trc
		// The new YZoom has now been set and will be effective during the next acquisition, but we want to immediately give some feedback to the..
		// ..user so he sees his YZoom  change has been accepted , so we go on and change the Y Axis range in the existing window :
		string  	sChan	= DiacTraceChannel( s.Win, wn, nio, cio )						// this  channel  is  given by the band the user clicked into 

		variable  	YOfs		= DiacTraceYOfs( s.Win, wn, nio, cio )
		variable  	YZoom	= DiacTraceYZoom( s.Win, wn, nio, cio )

		variable	Gain		= GainByNmForDisplay_ns( sFo, sChan )						// The user may change the AxoPatch Gain any time during acquisition

//		 printf "\t\t fDiacYZoom()   wn:%d   nio:%2d   cio:%2d    yZoom:%g    sChan: '%s'     -> Gain: %g \r", wn, nio, cio, str2num( s.PopStr ), sChan, Gain
		 printf "\t\tfDiacYZoom( %s )  \t\t\t\t\t\t\t\t'%s':%d\tni:%d\tci:%d\t%s\t yZoom:%g \t-> Gain: %g \r", s.CtrlName, s.win, wn, nio, cio, UFCom_pd(sChan,7), str2num( s.PopStr ), Gain
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


static  Function		ConstructCbCheckboxSliderShow( sWNm, nio, cio, bDisable )
	string  	sWNm
 	variable	nio, cio, bDisable
	variable	wn		   = DiacWnd2Nr( sWNm )
	variable	bSliderShow = DiacTraceSliderShow( sWNm, wn, nio, cio )
	Checkbox	CbCheckboxSliderShow,  win = $sWNm, size={ cXSZ_CB_AUTOSCL,20 },	proc=fDiacSliderShow,  title= "SliderYos"
	Checkbox	CbCheckboxSliderShow,  win = $sWNm, pos={ cXSZ_TB_TRACE + cXSZ_PM_TRACE + cXSZ_CB_AUTOSCL + cXSZ_PM_ZOOM + cXSZ_PM_COLOR , 2 }
	Checkbox	CbCheckboxSliderShow,  win = $sWNm, help={"................Automatical Scaling works only with Dac but not with Adc traces."}
	ShowHideCbCheckboxSliderShow( sWNm, bDisable, bSliderShow  )							// Enable or disable the control  and possibly adjust its value
End
static  Function		ShowHideCbCheckboxSliderShow( sWNm, bDisable, bSliderShow  )
//  Hide, gray or display (=enable)  the control   and   set its  state/value/limits  correctly  (even when hidden).
	string  	sWNm
 	variable	bDisable, bSliderShow
	Checkbox	CbCheckboxSliderShow,  win = $sWNm, disable =  bDisable, value = bSliderShow
End
static  Function		CheckboxSliderShowState( sWNm  )
//  return the setting of the SliderYos checkbox
	string  	sWNm
	ControlInfo   /W=$sWNm	CbCheckboxSliderShow
	return  V_Value
 End

Function		fDiacSliderShow( s )
// Executed only when the user changes the 'SliderShow' checkbox
	struct	WMCheckboxAction	&s
	if (  s.eventcode == UFCom_CBE_MouseUp )
		string  	sFo		= ksACQ
		string  	sSubFoIni	=  "Scrip"
 		variable	wn		= DiacWnd2Nr( s.Win )
		variable	nio		= str2num( GetUserData( s.win,  "",  "nio" ) )					// Get UD nio	 Get the quasi-globally stored  type (dac or adc)  of the trace we are currently working on 
		variable	cio		= str2num( GetUserData( s.win,  "",  "cio" ) )					// Get UD cio	 Get the quasi-globally stored  linear index (0,1..) of the trace we are currently working on
		string  	sChan	= DiacTraceChannel( s.win, wn, nio, cio )						// this  channel  is  given by the band the user clicked into 

// 2009-04-03
		string  llllst	= DiacTraceSliderShowSet( s.win, wn, nio, cio, s.checked )		// 
		DiacUpdateFile( sFo, sSubFoIni, llllst )										// modify trc: update trc

		variable bDisableCtr_SliderYofs	=  DiacControlBar( wn )  &  ! s.checked 
		variable  	YOfs		= DiacTraceYOfs( s.Win, wn, nio, cio )
		variable	Gain		= GainByNmForDisplay_ns( sFo, sChan )
		ShowHideCbSliderYOfs( 	s.win,  bDisableCtr_SliderYofs, YOfs, Gain )					// Display or hide the control  and possibly adjust its value
		 printf "\t\tfDiacSliderShow( %s )  \t\t\t\t\t'%s':%d\tni:%d\tci:%d\t%s\tCheckbox is %d    &  !   ControlBar is %d -> disable = %d \r", s.ctrlname, s.win, wn, nio, cio, UFCom_pd(sChan,7), s.checked, DiacControlBar( wn ) , bDisableCtr_SliderYofs
	endif
	return	0																// other return values reserved
End

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

static  Function		ConstructCbCloseButton( sWNm, bDisable )
	string  	sWNm
 	variable	bDisable
 	Button	  CbCloseButton,  	win = $sWNm, size={ 16,14 },	proc=fCbCloseButton,  fsize = 10, fstyle = 1,  title= "X" , font = "MS Sans Serif"
	Button	  CbCloseButton,  	win = $sWNm, pos = { cXSZ_TB_TRACE +  cXSZ_PM_TRACE + cXSZ_CB_AUTOSCL + cXSZ_PM_ZOOM + cXSZ_PM_COLOR + 4 * cXSZ_BUT_NARROW, 2 } 
	Button	  CbCloseButton,  	win = $sWNm, disable =  bDisable,  help={""}
End

Function	fCbCloseButton( s )
	struct	WMButtonAction	&s
	if ( s.eventcode == UFCom_CCE_mouseup )								// mouse up  inside button
		string  	sFo		= ksACQ
		variable	wn		= DiacWnd2Nr( s.win )
		variable	nio		= str2num( GetUserData( s.win,  "",  "nio" ) )			// Get UD nio	 Get the quasi-globally stored  type (dac or adc)  of the trace we are currently working on 
		variable	cio		= str2num( GetUserData( s.win,  "",  "cio" ) )			// Get UD cio	 Get the quasi-globally stored  linear index (0,1..) of the trace we are currently working on
		variable	bShow	= UFCom_FALSE
// 2009-04-03
		DiacWindowCBarShowSet( sFo, s.win, wn, bShow )
		CreateControlBarInAcqWnd_6(  s.win, wn, nio, cio, bShow ) 
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
	string  	sChan	= DiacTraceChannel( sWNm, wn, nio, cio )	
	variable  	YOfs		= DiacTraceYOfs( sWNm, wn, nio, cio )
	variable  	YZoom	= DiacTraceYZoom( sWNm, wn, nio, cio )
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
//print "todo  PossiblyAdjstSliderInAllWindows_ns( sFo )	todo_b reinsert.........2008-06-25"
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


Function		fDiacAutoScale( s )
// Executed only when the user changes the 'AutoScale' checkbox : If it is turned on, then YZoom and YOfs values are computed so that the currently displayed trace is fitted to the window.
	struct	WMCheckboxAction	&s
	if (  s.eventcode == UFCom_CBE_MouseUp )
		string  	sFo		= ksACQ
		string  	sSubFoIni	=  "Scrip"
		variable	wn		= DiacWnd2Nr( s.Win )
		variable	nio		= str2num( GetUserData( s.win,  "",  "nio" ) )					// Get UD nio	 Get the quasi-globally stored  type (dac or adc)  of the trace we are currently working on 
		variable	cio		= str2num( GetUserData( s.win,  "",  "cio" ) )					// Get UD cio	 Get the quasi-globally stored  linear index (0,1..) of the trace we are currently working on
		variable	bAutoScl	= s.checked
//		string  	llllst		= DiacParameterSet_( s.win, wn, nio, cio, kDIA_CV_AUTOSCL, num2str( bAutoScl ) )		// 
//		DiacUpdateFile( sFo, sSubFoIni, llllst )													// modify trc: update trc
	
		// The Dac trace has now been rescaled in the curves internally and will  be shown with new scaling during the next acquisition, but we want to immediately give some feedback to the
		//... user so he sees his rescaling has been accepted , so we go on redrawing all windows
		string  	sChan	= DiacTraceChannel( s.win, wn, nio, cio )	// this  channel  is  given by the band the user clicked into 
		variable  	YOfs		= DiacTraceYOfs( s.win, wn, nio, cio )			// retrieve the current values  YOfs ...
		variable  	YZoom	= DiacTraceYZoom( s.win, wn, nio, cio )			// ...and YZoom  from  'llllstDiac' (was 'Curves')...

		variable	Gain		= GainByNmForDisplay_ns( sFo, sChan )

		AutoscaleZoomAndOfs_6( wn, sChan, bAutoscl, YOfs, YZoom, Gain )							// ...but possibly change these values (here references) if bAutoScl has been turned ON 
		string  llllst	= DiacTraceAutoSclSet( s.win, wn, nio, cio, bAutoScl )		// 
		llllst		= DiacTraceYOfsSet(    s.win, wn, nio, cio, YOfs )			// store the possibly changed values
	 	llllst		= DiacTraceYZoomSet( s.win, wn, nio, cio, YZoom )		// 
		DiacUpdateFile( sFo, sSubFoIni, llllst )										// modify trc: update trc

		DurAcqRescaleYAxis_6( s.Win, sChan, YOfs, YZoom, Gain )
//		AutoscaleZoomAndOfs_6( wn, sChan, bAutoscl, YOfs, YZoom, Gain )
	
		// Hide the  Zoom  and  Offset  controls if  AutoScaling is ON, display them if Autoscaling is OFF
		variable	bAcqControlbar		= DiacControlBar( wn )
		variable	bDisableCtrlZoomOfs	= DisableCtrlZoomOfs( sChan, bAcqControlbar, bAutoScl )	// Determine whether the control must be enabled or disabled
		ShowHideCbPopupmenuYZoom( s.win,  nio, cio, bDisableCtrlZoomOfs, YZoom )			// Display or hide the Zoom popupmenu and possibly adjust its value
		variable	bSliderShow 		= DiacTraceSliderShow( s.win, wn, nio, cio )
		ShowHideCbCheckboxSliderShow( s.win, bDisableCtrlZoomOfs, bSliderShow  )			// Display or hide the Slider-Show/hide checkbox
// 2009-04-02
//		ShowHideCbSliderYOfs( 	s.win,  bDisableCtrlZoomOfs, YOfs, Gain )					// Display or hide the control  and possibly adjust its value
		variable bDisableCtr_SliderYofs	= bDisableCtrlZoomOfs  |  ! CheckboxSliderShowState( s.win  )
		ShowHideCbSliderYOfs( 	s.win,  bDisableCtr_SliderYofs, YOfs, Gain )					// Display or hide the control  and possibly adjust its value
	endif
	return	0																// other return values reserved
End



// 2009-12-12  unfortunately no longer static
//static   Function		AutoscaleZoomAndOfs_6( wn, sTNm, bAutoscl, rYOfs, rYZoom, Gain )
   Function		AutoscaleZoomAndOfs_6( wn, sTNm, bAutoscl, rYOfs, rYZoom, Gain )
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
		 printf "\t\t\tAutoscaleZoomAndOfs_( '%s'\t'%s'\tpts:\t%8d\t bAutoscl: %s )\tVmax:\t%7.2lf\tVmin:\t%7.2lf\tYaxis:\t%7.1lf\tYzoom:\t%7.2lf\tYofs:\t%7.1lf\tGain:\t%7.1lf\tsLBZoom:'%s'   \r",  sWNm, sTNm, numPnts( wData ), SelectString( bAutoscl, "OFF" , "ON" ), V_max, V_min, YAxis, rYZoom, rYOfs, Gain, "LBZoom"
	else													//  The checkbox  'Autoscale Y axis'  has been turned  OFF : So we restore and use the user supplied zoom factor setting from the Popupmenu
														//  We do not restore the  YOfs from slider because 	1. YOfs is at the optimum position as it has just been autoscaled  and the user can very easily  (re)adjust to any new position   
		ControlInfo /W=$sWNm LBZoom						//										2. the YOfs prior to AutoScaling would have had to be stored to be able to retrieve it which is not done in this version 
		rYZoom	= str2num( S_Value )							// Get the controls current value by reading S_Value  which is set by  ControlInfo
		 printf "\t\t\tAutoscaleZoomAndOfs_('%s' \t'%s'\t\t\t\t bAutoscl: %s )\t\t\t\t\tReturning zoom value from popupmenu: \tYzoom:\t%7.2lf\tsLBZoom:'%s'   \r",  sWNm, sTNm,  SelectString( bAutoscl, "OFF" , "ON" ), rYZoom, "LBZoom"
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
	string  	sFo		= ksACQ
	string  	sSubFoIni	=  "Scrip"

	if (  s.eventcode & 4  ||  s.eventcode & 9 )											// bit field expanded: 4 is mouse up, 9 is mouse moved + value set
		variable	wn		= DiacWnd2Nr( s.Win )
		variable	nio		= str2num( GetUserData( s.win,  "",  "nio" ) )					// Get UD nio	 Get the quasi-globally stored  type (dac or adc)  of the trace we are currently working on 
		variable	cio		= str2num( GetUserData( s.win,  "",  "cio" ) )					// Get UD cio	 Get the quasi-globally stored  linear index (0,1..) of the trace we are currently working on
		string  	llllst		= DiacTraceYOfsSet( s.win, wn, nio, cio, s.curval )	// 
		if (  s.eventcode & 4 )														// bit field expanded: 4 is mouse up, 9 is mouse moved + value set
			DiacUpdateFile( sFo, sSubFoIni, llllst )										// write only final file, not on every slider movement, (modify trc: update Trc)
		endif
		// The new YOffset has now been set and will be effective during the next acquisition, but we want to immediately give some feedback to the..
		// ..user so he sees his YOffset change has been accepted , so we go on and change the Yoffset in the existing window :
		string  	sChan	= DiacTraceChannel( s.Win, wn, nio, cio )	// this  channel  is  given by the band the user clicked into 
		variable  	YOfs		= DiacTraceYOfs( s.Win, wn, nio, cio )
		variable  	YZoom	= DiacTraceYZoom( s.Win, wn, nio, cio )

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

static  Function		ConstructCbCheckboxTrueTime( sWNm, bDisable, bTrueTime )
	string  	sWNm
 	variable	bDisable, bTrueTime 
	Checkbox	CbCheckboxTrueTime,  win = $sWNm, size={ cXSZ_CB_AUTOSCL,20 },	proc=fDiacTrueTime,  title= "True time"
	Checkbox	CbCheckboxTrueTime,  win = $sWNm, pos={  0 , 2 + kCB_HTLN0  }
	Checkbox	CbCheckboxTrueTime,  win = $sWNm, help={"True time is valid only for  the beginning of the trace if there are NoStore sections."}
	ShowHideCbCheckboxTrueTime( sWNm, bDisable, bTrueTime  )							// Enable or disable the control  and possibly adjust its value
End
static  Function		ShowHideCbCheckboxTrueTime( sWNm, bDisable, bTrueTime  )
//  Hide, gray or display (=enable)  the control   and   set its  state/value/limits  correctly  (even when hidden).
	string  	sWNm
 	variable	bDisable, bTrueTime  
	Checkbox	CbCheckboxTrueTime,  win = $sWNm, disable =  bDisable, value = bTrueTime
End

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

static  Function		ConstructCbDatasctButton( sWNm, bDisable )
	string  	sWNm
 	variable	bDisable 
 	Button	  CbDatasctButton,  	win = $sWNm, size={ 36,14 },  proc=fXDatasct_a,	fsize = 10, fstyle = 0,  title= "datsct" , font = "MS Sans Serif"
	Button	  CbDatasctButton,  	win = $sWNm, pos = { cXSZ_CB_TRUETIME + 1 * cXSZ_BUT_NARROW, 2 + kCB_HTLN0 } 
	Button	  CbDatasctButton,  	win = $sWNm, disable =  bDisable,  help={""}
	// Highlight the initial default button by printing the title in bold face on a gray background
//	Button	  CbDatasctButton,  	win = $sWNm, fstyle = 1, fcolor = ( 40000, 40000, 40000 )	// ass default: !!! Adjust this initial setting correspondingly in 'DiacRange()' and in  ConstructCb_XXX_Button()
End

static  Function		ConstructCbFrameButton( sWNm, bDisable )
	string  	sWNm
 	variable	bDisable 
 	Button	  CbFrameButton,  	win = $sWNm, size={ 36,14 },  proc=fXFrame_a,	fsize = 10, fstyle = 0,  title= "frame" , font = "MS Sans Serif"
	Button	  CbFrameButton,  	win = $sWNm, pos = { cXSZ_CB_TRUETIME + 3 * cXSZ_BUT_NARROW, 2 + kCB_HTLN0 } 
	Button	  CbFrameButton,  	win = $sWNm, disable =  bDisable,  help={""}
	// Highlight the initial default button by printing the title in bold face on a gray background
	// Button	  CbFrameButton,  	win = $sWNm, fstyle = 1, fcolor = ( 40000, 40000, 40000 )	// ass default: !!! Adjust this initial setting correspondingly in 'DiacRange()' and in  ConstructCb_XXX_Button()
End

static  Function		ConstructCbLapButton( sWNm, bDisable )
	string  	sWNm
 	variable	bDisable 
 	Button	  CbLapButton,  		win = $sWNm, size={ 36,14 },  proc=fXLap_a,	fsize = 10, fstyle = 0,  title= "lap" , font = "MS Sans Serif"
	Button	  CbLapButton,  		win = $sWNm, pos = { cXSZ_CB_TRUETIME + 5 * cXSZ_BUT_NARROW, 2 + kCB_HTLN0 } 
	Button	  CbLapButton,  		win = $sWNm, disable =  bDisable,  help={""}
End

static  Function		ConstructCbCompressButton( sWNm, bDisable )
	string  	sWNm
 	variable	bDisable 
 	Button	  CbCompressButton, 	win = $sWNm, size={ 16,14 },  proc=fXCompress_a, fsize = 10, fstyle = 1,  title= "><" , font = "MS Sans Serif"
	Button	  CbCompressButton, 	win = $sWNm, pos = { cXSZ_CB_TRUETIME + 8 * cXSZ_BUT_NARROW, 2 + kCB_HTLN0 } 
	Button	  CbCompressButton, 	win = $sWNm, disable =  bDisable,  help={""}
End

static  Function		ConstructCbExpandButton( sWNm, bDisable )
	string  	sWNm
 	variable	bDisable 
 	Button	  CbExpandButton,  	win = $sWNm, size={ 16,14 },  proc=fXExpand_a, fsize = 10, fstyle = 1,  title= "<>" , font = "MS Sans Serif"
	Button	  CbExpandButton,  	win = $sWNm, pos = { cXSZ_CB_TRUETIME + 9 * cXSZ_BUT_NARROW, 2 + kCB_HTLN0 } 
	Button	  CbExpandButton,  	win = $sWNm, disable =  bDisable,  help={""}
End

static  Function		ConstructCbReverseButton( sWNm, bDisable )
	string  	sWNm
 	variable	bDisable 
 	Button	  CbReverseButton,  	win = $sWNm, size={ 16,14 },  proc=fXReverse_a, fsize = 10, fstyle = 1,  title= "<<" , font = "MS Sans Serif"
	Button	  CbReverseButton,  	win = $sWNm, pos = { cXSZ_CB_TRUETIME + 11 * cXSZ_BUT_NARROW, 2 + kCB_HTLN0 } 
	Button	  CbReverseButton,  	win = $sWNm, disable =  bDisable,  help={""}
End

static  Function		ConstructCbReversButton( sWNm, bDisable )
	string  	sWNm
 	variable	bDisable 
 	Button	  CbReversButton,  	win = $sWNm, size={ 16,14 },  proc=fXRevers_a,	fsize = 10, fstyle = 1,  title= "<" , font = "MS Sans Serif"
	Button	  CbReversButton,  	win = $sWNm, pos = { cXSZ_CB_TRUETIME + 12 * cXSZ_BUT_NARROW, 2 + kCB_HTLN0 } 
	Button	  CbReversButton,  	win = $sWNm, disable =  bDisable,  help={""}
End

static  Function		ConstructCbAdvancButton( sWNm, bDisable )
	string  	sWNm
 	variable	bDisable 
 	Button	  CbAdvancButton,  	win = $sWNm, size={ 16,14 },  proc=fXAdvanc_a,  fsize = 10, fstyle = 1,  title= ">" , font = "MS Sans Serif"
	Button	  CbAdvancButton,  	win = $sWNm, pos = { cXSZ_CB_TRUETIME + 13 * cXSZ_BUT_NARROW, 2 + kCB_HTLN0 } 
	Button	  CbAdvancButton,  	win = $sWNm, disable =  bDisable,  help={""}
End

static  Function		ConstructCbAdvanceButton( sWNm, bDisable )
	string  	sWNm
 	variable	bDisable 
 	Button	  CbAdvanceButton,  	win = $sWNm, size={ 16,14 },  proc=fXAdvance_a, fsize = 10, fstyle = 1,  title= ">>" , font = "MS Sans Serif"
	Button	  CbAdvanceButton,  	win = $sWNm, pos = { cXSZ_CB_TRUETIME + 14 * cXSZ_BUT_NARROW, 2 + kCB_HTLN0 } 
	Button	  CbAdvanceButton,  	win = $sWNm, disable =  bDisable,  help={""}
End

static  Function		ConstructCbXResetButton( sWNm, bDisable )
	string  	sWNm
 	variable	bDisable 
 	Button	  CbXResetButton,  	win = $sWNm, size={ 16,14 },  proc=fXReset_a, fsize = 12, fstyle = 1,  title= "=" , font = "MS Sans Serif"
	Button	  CbXResetButton,  	win = $sWNm, pos = { cXSZ_CB_TRUETIME + 16 * cXSZ_BUT_NARROW, 2 + kCB_HTLN0 } 
	Button	  CbXResetButton,  	win = $sWNm, disable =  bDisable,  help={""}
End

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


Function		fDiacTrueTime( s )
	struct	WMCheckboxAction	&s
// 2009-04-02
	variable	value	= s.checked
	string  	sFo	 	= ksACQ						// can here (in contrast to main panel) not be retrieved from the control name
	string  	sSubFoIni	= "Scrip"
	variable	wn		= DiacWnd2Nr( s.win )
	DiacWindowXTrueTimeSet( sFo, s.win, wn, value )		// store new value = checkbox setting  in global list 'listDiac'...
	DiacUpdateFile( sFo, sSubFoIni, LstDiac() )				// ...save global list 'listDiac'  in the INI file

	DiacTrueTimeSet( ksACQ, s.win, value )				// store new value = checkbox setting in global variable , this avoids retrieval by ControlInfo
	DiacDisplayChannelsXRange_( ksACQ, ksFPUL, s.win )
End
	
	
Function		fXDatasct_a(  s ) 
	struct	WMButtonAction	&s
	if ( s.eventcode == UFCom_BUE_MouseUp )					
// 2009-04-02
		variable	nRange	= kRA_DS
		string  	sFo	 	= ksACQ						// can here (in contrast to main panel) not be retrieved from the control name
		string  	sSubFoIni	= "Scrip"
		variable	wn		= DiacWnd2Nr( s.win )
		DiacWindowRangeSet( sFo, s.win, wn, nRange )			// store new Range in global list 'listDiac'...
		DiacUpdateFile( sFo, sSubFoIni, LstDiac() )				// ...save global list 'listDiac'  in the INI file

		DiacRangeSet( sFo, s.win, nRange )					// store new Range in global variable 
		DiacHighlightRangeButton( s.win, nRange )
		DiacDisplayChannelsXRange_( ksACQ, ksFPUL, s.win )
	endif
End


Function		fXFrame_a(  s ) 
	struct	WMButtonAction	&s
	if ( s.eventcode == UFCom_BUE_MouseUp )					
// 2009-04-02
		variable	nRange	= kRA_FRAME
		string  	sFo	 	= ksACQ						// can here (in contrast to main panel) not be retrieved from the control name
		string  	sSubFoIni	= "Scrip"
		variable	wn		= DiacWnd2Nr( s.win )
		DiacWindowRangeSet( sFo, s.win, wn, nRange )			// store new Range in global list 'listDiac'...
		DiacUpdateFile( sFo, sSubFoIni, LstDiac() )				// ...save global list 'listDiac'  in the INI file

		DiacRangeSet( sFo, s.win, nRange )					// store new Range in global variable 
		DiacHighlightRangeButton( s.win, nRange )
		DiacDisplayChannelsXRange_( ksACQ, ksFPUL, s.win )
	endif
End


Function		fXLap_a(  s ) 
	struct	WMButtonAction	&s
	if ( s.eventcode == UFCom_BUE_MouseUp )					
// 2009-04-02
		variable	nRange	= kRA_LAP
		string  	sFo	 	= ksACQ						// can here (in contrast to main panel) not be retrieved from the control name
		string  	sSubFoIni	= "Scrip"
		variable	wn		= DiacWnd2Nr( s.win )
		DiacWindowRangeSet( sFo, s.win, wn, nRange )			// store new Range in global list 'listDiac'...
		DiacUpdateFile( sFo, sSubFoIni, LstDiac() )				// ...save global list 'listDiac'  in the INI file

		DiacRangeSet( sFo, s.win, nRange )					// store new Range in global variable 
		DiacHighlightRangeButton( s.win, nRange )
		DiacDisplayChannelsXRange_( ksACQ, ksFPUL, s.win )
	endif
End


Function	DiacHighlightRangeButton( sWNm, nRange )
	string  	sWNm
	variable	nRange
	Button	  CbDatasctButton,  	win = $sWNm, fstyle = 0, fcolor = (     0, 		0, 	   0	)	// 0: normal, 1: bold 
	Button	  CbFrameButton,  	win = $sWNm, fstyle = 0, fcolor = (     0, 		0, 	   0	)	// 0: normal, 1: bold 
	Button	  CbLapButton ,  	win = $sWNm, fstyle = 0, fcolor = (     0, 		0, 	   0	)	// 0: normal, 1: bold 
	if ( nRange == kRA_DS )
		Button	  CbDatasctButton,  	win = $sWNm, fstyle = 1, fcolor = ( 40000, 40000, 40000 )	// 0: normal, 1: bold 
	elseif ( nRange == kRA_FRAME )
		Button	  CbFrameButton,  	win = $sWNm, fstyle = 1, fcolor = ( 40000, 40000, 40000 )	// 0: normal, 1: bold 
	elseif ( nRange == kRA_LAP )
		Button	  CbLapButton ,  	win = $sWNm, fstyle = 1, fcolor = ( 40000, 40000, 40000 )	// 0: normal, 1: bold 
	endif
End

	
Function		fXCompress_a(  s ) 
	struct	WMButtonAction	&s
	if ( s.eventcode == UFCom_BUE_MouseUp )					

		AcqXAxisZoomAndShiftSet( s.win, AcqXAxisZoom( s.win ) /  XFCT )
		 printf "\t\t%s\t'%s'\t\t\t\t\t\t\t\txzoom:\t\t\t%lf \r",  s.CtrlName, s.win, AcqXAxisZoom( s.win )
		DiacDisplayChannelsXRange_( ksACQ, ksFPUL, s.win )

	endif
End

Function		fXExpand_a(  s ) 
	struct	WMButtonAction	&s
	if ( s.eventcode == UFCom_BUE_MouseUp )				

		AcqXAxisZoomAndShiftSet( s.win, AcqXAxisZoom( s.win ) *  XFCT )
		 printf "\t\t%s\t'%s'\t\t\t\t\t\t\t\txzoom:\t\t\t%lf \r",  s.CtrlName, s.win, AcqXAxisZoom( s.win )
		DiacDisplayChannelsXRange_( ksACQ, ksFPUL, s.win )

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

		AcqXAxisShiftSet( s.win, AcqXAxisShift( s.win ) + step )
		 printf "\t\t%s\t'%s'\t\tshift: %lf \r",  s.CtrlName, s.win, AcqXAxisShift( s.win )
		DiacDisplayChannelsXRange_( ksACQ, ksFPUL, s.win )

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

		AcqXAxisShiftSet( s.win, AcqXAxisShift( s.win ) - step )
		 printf "\t\t%s\t'%s'\t\tshift: %lf \r",  s.CtrlName, s.win, AcqXAxisShift( s.win )
		DiacDisplayChannelsXRange_( ksACQ, ksFPUL, s.win )

	endif
End


Function		fXReset_a(  s ) 
// Reset to normal:  XShift = 0, XScale = 1
	struct	WMButtonAction	&s
	if ( s.eventcode == 2 )					// 2 is mouse up

		AcqXAxisZoomSet( s.win, 1 )		// this order: first scale, then shift !
		AcqXAxisShiftSet( s.win, 0 )
		 printf "\t\t%s\t'%s'\t\tshift: %lf   \t\t\txzoom:\t\t\t%lf \r",  s.CtrlName, s.win, AcqXAxisShift( s.win ), AcqXAxisZoom( s.win )
		DiacDisplayChannelsXRange_( ksACQ, ksFPUL, s.win )

	endif
End


function	AcqXAxisShiftSet( sWNm, xShift )
	string  	sWNm
	variable	xShift

// 2009-04-02
	string  	sFo	 	= ksACQ						// can here (in contrast to main panel) not be retrieved from the control name
	string  	sSubFoIni	= "Scrip"
	variable	wn		= DiacWnd2Nr( sWNm )
	DiacWindowXShiftSet( sFo, sWNm, wn, xShift )			// store new XShift value in global list 'listDiac'...
	DiacUpdateFile( sFo, sSubFoIni, LstDiac() )				// ...save global list 'listDiac'  in the INI file

	string  	sFoVarNm	= UFCom_ksROOT_UF_ + ksACQ_ + ksDIA + ":" + sWNm + ":Shift" 	// e.g. 'root:uf:acq:dia:AW0:Shift
	return	UFCom_SetGVar( sFoVarNm, xShift )
End


function		AcqXAxisShift( sWNm )
	string  	sWNm
	string  	sFoVarNm	= UFCom_ksROOT_UF_ + ksACQ_ + ksDIA + ":" + sWNm + ":Shift" 	// e.g. 'root:uf:acq:dia:AW0:Shift
	return	UFCom_GVarCE( sFoVarNm, 0 )										// returns 0 if global does not exist yet (which should not happen)
End

function	AcqXAxisZoomSet( sWNm, xZoom )
	string  	sWNm
	variable	xZoom

// 2009-04-02
	string  	sFo	 	= ksACQ							// can here (in contrast to main panel) not be retrieved from the control name
	string  	sSubFoIni	= "Scrip"
	variable	wn		= DiacWnd2Nr( sWNm )
	DiacWindowXZoomSet( sFo, sWNm, wn, xZoom )			// store new XZoom value in global list 'listDiac'...
	DiacUpdateFile( sFo, sSubFoIni, LstDiac() )					// ...save global list 'listDiac'  in the INI file

	string  	sFoVarNm	= UFCom_ksROOT_UF_ + ksACQ_ + ksDIA + ":" + sWNm + ":Scale" 	// e.g. 'root:uf:acq:dia:AW0:Scale
	UFCom_SetGVar( sFoVarNm, xZoom )
	 printf "\t\tAcqXAxisZoomSet\t\t\t\t\t\t\t\txzoom: %lf   \r",  xZoom
End

function	AcqXAxisZoomAndShiftSet( sWNm, xZoom )
	string  	sWNm
	variable	xZoom

// 2009-04-02
	string  	sFo	 	= ksACQ							// can here (in contrast to main panel) not be retrieved from the control name
	string  	sSubFoIni	= "Scrip"
	variable	wn		= DiacWnd2Nr( sWNm )
	DiacWindowXZoomSet( sFo, sWNm, wn, xZoom )			// store new XZoom value in global list 'listDiac'...
	DiacUpdateFile( sFo, sSubFoIni, LstDiac() )					// ...save global list 'listDiac'  in the INI file

	string  	sFoVarNm	= UFCom_ksROOT_UF_ + ksACQ_ + ksDIA + ":" + sWNm + ":Scale" 	// e.g. 'root:uf:acq:dia:AW0:Scale

	// Compute/adjust  xShift such that  the midpoint of the displayed trace stays the same independent of the zoom factor  and set the global with this value (which is later retrieved and used in CopyExtractedSweep1_ns() )
	variable	xZoomOld	= AcqXAxisZoom( sWNm )
	variable	xShift	= AcqXAxisShift( sWNm )
	variable	xShiftNew	=  ( xShift + .5 ) * xZoom / xZoomOld - .5  

	AcqXAxisShiftSet( sWNm, xShiftNew )
	UFCom_SetGVar( sFoVarNm, xZoom )
	 printf "\t\tAcqXAxisZoomAndShiftSet\t\tshift: %lf ->\t%lf\txzoom: %lf  ->\t%lf\t \r",  xShift, xShiftNew, xZoomOld, xZoom

	// 2009-03-31 only test : same equations/processing as in CopyExtractedSweep1_ns()
	//variable	nPtsO = 14000	
	//xShift	= AcqXAxisShift( sWNm )								
	//xZoom	= AcqXAxisZoom( sWNm )									
	//variable	nPts_	= nPtsO /  AcqXAxisZoom( sWNm )		
	//variable	UserShift_	=  AcqXAxisShift( sWNm )	* nPts_			
	// printf "\t\tAcqXAxisZoomSet\t\t\t\tshift: %lf ->\t%lf\txzoom: %lf  ->\t%lf\t-> will display \t%d\tPts from \t%10.0lf\t...\t%10.0lf\t  [mid:\t%10.0lf\t, displayed pts:%10.0lf]\r",  xShift, xShiftNew, xZoomOld, xZoom, nPtsO, UserShift_, UserShift_+nPts_  ,UserShift_+nPts_/2  , nPts_
End

 function		AcqXAxisZoom( sWNm )
	string  	sWNm
	string  	sFoVarNm	= UFCom_ksROOT_UF_ + ksACQ_ + ksDIA + ":" + sWNm + ":Scale" 	// e.g. 'root:uf:acq:dia:AW0:Scale
	return	UFCom_GVarCE( sFoVarNm, 1 )										// returns 1 if global does not exist yet (which should not happen)
End


