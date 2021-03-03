/
// FPDISPDLG.IPF 
// 
// Routines for
//	editing trace and window appearance during acquisition 
//	statusbar during acquisition 

// History:
// Major revision 040108
	
#pragma rtGlobals=1								// Use modern global access method.

static constant	cXLBTRACESSIZE			= 92		// empirical values, could be computed .  81 for 'Dac0SC' , 86 for 'Dac0SCa' , 92 for 'Dac0 SC a'
static constant	cXBUTTONSIZE			= 31
static constant	cXBUTTONMARGIN			=  2
static constant	cXLBCOLORSIZE			= 96
static constant	cbVERTICAL_SLIDER_YOFS	= 1
static constant	bGrayDontHide	 = 1 //FALSE//TRUE								// disable the control by  either graying it only (pass 2)  or  by hiding it completely (pass 1)

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  CONTROLBARS  in  the  ACQUISITION  WINDOWS  with  BUTTONS(=Copy,Ins,Del)  ,  LISTBOXES(=Trace,YZoom)   ,   SLIDER(=YOfs)   and   POPMENU(=Colors)
//  
// The controlbar code for each of the the buttons, listboxes and popmemu is principally made up of 2 parts : 
// Part1 is easy, it stores the user setting in the underlying control structure TWA. This is the more  important part as TWA controls the display during the next acquisition.
// 030108
// Part2 is not so easy. Part 2 has the purpose to give the user some immediate feedback that his changes have been accepted. 
//	For this existing data are drawn preliminarily with changed colors, zooms, Yaxes in a manner which is to reflect the user changes at once which would without this code only take effect later during the next acquisition.
//	The code is relatively complex for a number of reasons:
//	- we must deal with 'single' traces  and  with  'superimposed' traces (derived from the basic trace name but with the begin point number appended)
//	- we allow multiple instances of the same trace allowing the same data to be displayed at the same time with different zoom factors,..
//		for this we must do much bookkeeping because Igor has the restriction of requiring the same trace=wave name but appends its own instance number..
//		whereas we must do our own instance counting in TWA
//	- Y axis are to be positioned neatly and Igor allows no Yaxis without accompanying  wave display
// 040108
// Part2 is also easy if another aproach is taken: we do not even try to keep track which instances of which traces in which windows have to be redrawn, instead we we redraw all ( -> DisplayOffLine() )
//	This is sort of an overkill but here we do it only once in response to a (slow) user action while during acq we do the same routine (=updating all acq windows) very often. 
// 	To make a long story short: As this approach simplifies the program code tremendously  we accept the (theoretical) disadvantage of updating traces which actually would have needed no update.

Function		CreateAllControlBarsInAcqWnd()
// show / hide the ControlBar  immediately
	variable	w, wCnt = WndCnt()
	for ( w = 0; w < wCnt; w += 1) 
		string	  sWNm = WndNm( w )			// or.... ControlUpdate(...)...
		CreateControlBarInAcqWnd( sWNm )		// show / hide the ControlBar  immediately
	endfor
End

Function		CreateControlBarInAcqWnd( sWNm ) 
// depending on  'gbAcqControlbar'  build and show or hide the controlbar  AND  show or hide the individual controls (buttons, listboxes..)
	string 	sWnm
	// supply the correct start values for the listboxes
	variable	w		= WndNr( sWNm )
	variable	rnRange, rnMode, rnInstance, rbAutoscl, rYOfs, rYZoom, rDacGain 
	string		rsRGB, rsUnits, rsTNm
	string		sCurves	= RetrieveCurves( w )		
	variable	CurveCnt	= ItemsInList( sCurves, sCURVSEP )
	variable	nCurve	= 0												
	
	
	nvar		gbAcqControlbar	= root:disp:gbAcqControlbar
	variable	bPopupDisable		= gbAcqControlbar && CurveCnt > 0	?   0 : 1 		// after all traces have been deleted hide all controls...
	variable	bPopupDisableIns	= gbAcqControlbar 				?   0 : 1 		// ...except the 'Insert' button : this is the only useful one 
	variable	ControlBarHeight 	= gbAcqControlbar				? 26 : 0 		// height 0 effectively hides the whole controlbar

	ControlBar /W = $sWNm  ControlBarHeight

	// Version 1 : Always display the 1. trace of the traces listbox in the traces listbox and its corresponding color and YZoom values
	// ... no matter which was the last selected active user trace when the user last pressed  'Save display config'  (stored in wWLoc and later reloaded on 'Apply')
	SetWndUsersTrace( w, nCurve )  	// 040104	 Overwrite this value  with   nCurve = 0  to avoid non-congruent  trace/color/zoom listboxes
																		
	// Version 2 : Display that trace of the traces listbox in the traces listbox (and its corresponding color and YZoom values) ...
	// ...which was the selected active user trace when the user last pressed  'Save display config' 
	// nCurve	= WndUsersTrace( w )	// 040104	
	
	string		sCurve	= StringFromList( nCurve, sCurves, sCURVSEP )				

	ExtractCurve( sCurve, rsTNm, rnRange, rnMode, rnInstance, rbAutoscl, rYOfs, rYZoom, rDacGain, rsUnits, rsRGB )		
	ConstructCbButtonCopy( sWNm, bPopupDisable )
	ConstructCbButtonInsert( sWNm, bPopupDisableIns )
	ConstructCbButtonDelete( sWNm, bPopupDisable )

	SetActiveWnd( sWNm)	
	ConstructCbListboxTraces( sWNm, bPopupDisable, nCurve, CurveCnt )					// only if there is more than 1 trace  the TraceSelectListbox will be constructed

	printf "\tCreateControlBarInAcqWnd( sWNm:%s ) \tnCurve:%d   rsTNm: '%s' \r",  sWNm, nCurve, rsTNm 
	ConstructCbPopmenuColors( sWNm, bPopupDisable, rsRGB )

	//  Version 1 : only  Dacs  can be autoscaled
	//variable	bShowAutosclCheckbox	=   ! bPopupDisable  && IsDacTrace( rsTNm )	

	//  Version 2 :  Dacs  and   Adcs  can be autoscaled
	variable	bShowAutosclCheckbox	=  ! bPopupDisable 

	variable	bShowZoomOfsControls	=  ! bPopupDisable  && ( ! bShowAutosclCheckbox || ( bShowAutosclCheckbox && ! rbAutoscl ) )
	ConstructCbCheckboxAuto( sWNm, bShowAutosclCheckbox, rbAutoscl )				// FALSE : enable checkbox (=Dac), TRUE : disable checkbox (=Adc)
	ConstructCbListboxYZoom( sWNm, bShowZoomOfsControls, rYZoom )					// FALSE : enable popup
//	ConstructCbListboxYOfs( sWNm, bShowZoomOfsControls, rYOfs )
	ConstructCbSliderYOfs( sWNm, bShowZoomOfsControls, rYOfs )

//	SetActiveWnd( sWNm)	
//	ConstructCbListboxTraces( sWNm, bPopupDisable, nCurve, CurveCnt )				// only if there is more than 1 trace  the TraceSelectListbox will be constructed
	//printf "\tCreateControlBarInAcqWnd( sWNm:%s ) \tw:%d , nWUT:%d =?= nCurve:%2d/%2g \tsCurve:'%s' \r", sWNm, w, WndUsersTrace( w ), nCurve, CurveCnt, sCurve
End

//  CONTROLBARS  in  the  ACQUISITION  WINDOWS : CONSTRUCTION

Function		ConstructCbListboxTraces( sWNm, bPopupDisable, nCurve, nCurveCnt )
// Fill the traces listbox in the ControlBar of each acquisition window only with those traces actually contained in the window. 
// 1. IGOR allows the 'live' update of the listbox  only via a global string or a function without parameters (=ActiveTN1L() ), which also needs a global string 'gsLbActiveWnd '
	string		sWNm
	variable	bPopupDisable, nCurve, nCurveCnt
	// Hide the Select-Trace-Listbox  if only 1 trace is left. One could alternatively show it even when only 1 trace is left to tell the user the type (which is also shown in the window title)
	// if ( nCurveCnt  >  0 )		//  show Select-Trace-Listbox  for  1  or more traces....
	// if ( nCurveCnt  >  1 )		//  show Select-Trace-Listbox  for  2  or more traces....
		variable	w	= WndNr( sWNm )
		PopupMenu  CbListboxTrace,  win = $sWNm, disable = bPopupDisable, title = "" , pos = {2, 2}, size = {36,16} , mode = nCurve+1	// 040104
		PopupMenu  CbListboxTrace,  win = $sWNm, proc = CbListboxTrace, 	value = ActiveTNL1()	// Igor does not allow locals in the following PopupMenu
		PopupMenu  CbListboxTrace,  win = $sWNm, help = {"If you have multiple traces in the windows, you must first select the trace to apply on."}
//	else
//		PopupMenu  CbListboxTrace,  win = $sWNm, disable = TRUE
//	endif
End

Function		ConstructCbButtonCopy( sWNm, bPopupDisable )
	string 	sWNm
	variable	bPopupDisable
	Button	CbButtonCopy,  win = $sWNm, disable = bPopupDisable, 	 size={ cXBUTTONSIZE,20},	proc=CbButtonCopy,  title="Copy"
	Button	CbButtonCopy,  win = $sWNm, pos={ cXLBTRACESSIZE, 2 }
End

Function		ConstructCbButtonInsert( sWNm, bPopupDisable )
	string 	sWNm
	variable	bPopupDisable
	Button	CbButtonInsert,       win = $sWNm, disable = bPopupDisable,	size={cXBUTTONSIZE,20},	proc=CbButtonInsert,  title="Ins"
	Button	CbButtonInsert,       win = $sWNm, pos = { cXLBTRACESSIZE + 1 * ( cXBUTTONSIZE + cXBUTTONMARGIN ) , 2 }
End

Function		ConstructCbButtonDelete( sWNm, bPopupDisable )
	string 	sWNm
 	variable	bPopupDisable
	Button	CbButtonDelete,     win = $sWNm, disable = bPopupDisable, 	size={ cXBUTTONSIZE,20 },	proc=CbButtonDelete,  title="Del"
	Button	CbButtonDelete,     win = $sWNm, pos={ cXLBTRACESSIZE + 2 * ( cXBUTTONSIZE + cXBUTTONMARGIN ) , 2 }
End

// 040109
Function		ConstructCbCheckboxAuto( sWNm, bPopupEnable, bAutoscl )
	string 	sWNm
 	variable	bPopupEnable, bAutoscl 
	Checkbox	CbCheckboxAuto,  win = $sWNm, disable = ! bPopupEnable, 	size={ cXBUTTONSIZE,20 },	proc=CbCheckboxAuto,  title="AS"
	Checkbox	CbCheckboxAuto,  win = $sWNm, pos={ cXLBTRACESSIZE + 3 * ( cXBUTTONSIZE + cXBUTTONMARGIN ) , 2 }
	Checkbox	CbCheckboxAuto,  win = $sWNm, value = bAutoscl
	Checkbox	CbCheckboxAuto,  win = $sWNm, help={"Automatical Scaling works only with Dac but not with Adc traces."}
End

Function		ConstructCbPopmenuColors( sWNm, bPopupDisable, sRGB )
	string		sWNm, sRGB
	variable	bPopupDisable
	variable	rnRed, rnGreen, rnBlue
	ExtractColors( sRGB, rnRed, rnGreen, rnBlue )
	PopupMenu CbPopmenuColors,  win = $sWNm, disable = bPopupDisable,  	size={ cXLBCOLORSIZE,16 },	proc=CbPopmenuColors,	title=""		
	PopupMenu CbPopmenuColors,  win = $sWNm, pos={ cXLBTRACESSIZE + 4 * ( cXBUTTONSIZE + cXBUTTONMARGIN ) , 2 }
	PopupMenu CbPopmenuColors,  win = $sWNm, mode=1, popColor = ( rnRed, rnGreen, rnBlue ), value = "*COLORPOP*"
	PopupMenu CbPopmenuColors,  win = $sWNm, help = {"If you have multiple traces in the windows, you must first select the trace to apply on, then the color."}
End

Function		ConstructCbListboxYZoom( sWNm, bPopupEnable, rYZoom )
	string		sWNm
	variable	bPopupEnable, rYZoom
//	variable	flag	= 	 bPopupEnable == 0 ?   1 + bGrayDontHide  :   0
	variable	flag	= 	 bPopupEnable == 0 ?   1 				 :   0

	PopupMenu CbListboxYZoom,   win = $sWNm, disable = flag, 	size={100,20}, 			proc=CbListboxYZoom,	title="yZm"		// 031103
	PopupMenu CbListboxYZoom,   win = $sWNm, pos={ cXLBTRACESSIZE + 4 * ( cXBUTTONSIZE + cXBUTTONMARGIN )+ cXLBCOLORSIZE - 44, 2 } 
	string		sYZoom	
	sprintf 	sYZoom, "%.2lf", rYZoom
	PopupMenu CbListboxYZoom,   win = $sWNm, mode=1, popvalue = sYZoom, 		value = ".1;.2;.5;1;2;5;10;20;50;100"				// 031103
	PopupMenu CbListboxYZoom ,  win = $sWNm, help = {"If you have multiple traces in the windows, you must first select the trace to apply on, then the Y zoom factor."}
End

//  YOFS  implemented as Listbox
//
//Function		ConstructCbListboxYOfs( sWNm, bPopupEnable, rYOfs )
//	string		sWNm
//	variable	bPopupEnable, rYOfs
//	PopupMenu CbListboxYOfs,   win = $sWNm, disable = ! bPopupEnable, 	size={100,20}, 				proc=CbListboxYOfs,		title="yOs"		// 040108
//	PopupMenu CbListboxYOfs,   win = $sWNm, pos={ cXLBTRACESSIZE + 4 * ( cXBUTTONSIZE + cXBUTTONMARGIN )+ cXLBCOLORSIZE + 50, 2 } 
//	PopupMenu CbListboxYOfs,   win = $sWNm, mode=1, popvalue = num2str( rYOfs ), value = "-5000;-2000;-1000;-500;-200;-100;-50;-20;-10;-5;-2;-1;0;1;2;5;10;20;50;100;200;500;1000;2000;5000"				// 031103
//	PopupMenu CbListboxYOfs ,  win = $sWNm, help = {"If you have multiple traces in the windows, you must first select the trace to apply on, then the Y offset."}
//End

//  YOFS  implemented as Slider
//
Function		ConstructCbSliderYOfs( sWNm, bPopupEnable, rYOfs )
	string		sWNm
	variable	bPopupEnable, rYOfs
	Slider 	CbSliderYOfs,   win = $sWNm, disable = ! bPopupEnable,			proc=CbSliderYOfs 

	GetWindow $sWNm, wSize											// Get the window dimensions in points .
	variable RightPix= ( V_right	-  V_left )	* screenresolution / IGOR_POINTS72 
	variable BotPix	= ( V_bottom - V_top ) * screenresolution / IGOR_POINTS72 
	//print  "\twindow dim in points:", V_left,  V_top,  V_right,  V_bottom , " -> RightPix:",  RightPix, BotPix
	
	if ( cbVERTICAL_SLIDER_YOFS )							// Vertical slider at the  right window border

		variable	ControlBarWidth 	= bPopupEnable  ? 76 : 0 		// width 0 makes the controlbar vanish
		ControlBar /W = $sWNm  /R ControlBarWidth
		Slider 	CbSliderYOfs,   win = $sWNm, vert = 1, side = 2,	size={ 0, BotPix - 30 },  pos = { RightPix -76, 28 }
		//ControlInfo /W=$sWNm CbSliderYOfs
		//printf "\tControlInfo Slider  in '%s' \tleft:%d \twidth:%d \ttop:%d \theight:%d \r", sWNm,  V_left, V_width, V_top, V_height
	
	else													// Horizontal slider
		Slider 	CbSliderYOfs,   win = $sWNm, vert = 0, side = 1, 	size={200,0}, 	pos = { cXLBTRACESSIZE + 4 * ( cXBUTTONSIZE + cXBUTTONMARGIN )+ cXLBCOLORSIZE + 50, 2 } 
	endif

// Todo: Update the YOfs slider whenever the window size changes. (If not the user has to momentarily switch the  'Trace / window controlbar'  off and on again to adjust the slider to the window.

End

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  CONTROLBARS  in  the  ACQUISITION  WINDOWS  :  THE  ACTION  PROCEDURES

Function		CbListboxTrace( ctrlName, popNum, popStr ) : PopupMenuControl
// executed when the user selected a trace from the listbox. Changes color and YZoom listboxes so that they contain the current values of the selected trace 
	string		ctrlName, popStr
	variable	popNum
	string		sWNm	= ActiveWnd()
	variable	w		= WndNr( sWNm )
	variable	t		= popNum - 1								// popnum -1 because listbox selections start at 1  [wrong: t = ioChan(popStr )]
	string		sCurves	= RetrieveCurves( w )							// the user selected trace ' t '  ...
	string		sCurve	= StringFromList( t, sCurves, sCURVSEP )			// ...so we extract the current values of trace  ' t ' ...	
	variable	rnRange, rnMode, rnInstance, rbAutoscl, rYOfs, rYZoom, rDacGain 
	string		rsRGB, rsUnits, rsTNm
	ExtractCurve( sCurve, rsTNm, rnRange, rnMode, rnInstance, rbAutoscl, rYOfs, rYZoom, rDacGain, rsUnits, rsRGB )	// ...and pass color , YZoom , YOfs when constructing the controls to supply the correct defaults/start values 		
	printf "\t\t%s( %d, %s ) in  wnd:%2d \t-> selected t:%d ? %d (instance)\t-> converted to '%s'  '%s'  \tAS:%d   [%s]\r", ctrlName, popNum, popStr, w, t, rnInstance, rsTNm, BuildMoRaName( rnRange, rnMode), rbAutoscl, sCurve 
	//printf "\tCbListboxTrace( %s, %d, %s ) in  wnd:%2d \t-> selected t:%d  \t-> converted to '%s' '%s'   \r", ctrlName, popNum, popStr, w, t, rsTNm, BuildMoRaNameI( rnRange, rnMode, rnInstance )

	ConstructCbPopmenuColors( sWNm, FALSE, rsRGB )					// FALSE : enable popup always

	//  Version 1 : only  Dacs  can be autoscaled
	//variable	bShowAutosclCheckbox	=  IsDacTrace( rsTNm )			// hide = FALSE : enable checkbox (=Dac), TRUE : disable checkbox (=Adc)

	//  Version 2 :  Dacs  and   Adcs  can be autoscaled
	variable	bShowAutosclCheckbox	=  TRUE

	variable	bShowZoomOfsControls	=  ! bShowAutosclCheckbox || ( bShowAutosclCheckbox && ! rbAutoscl )
	ConstructCbCheckboxAuto( sWNm, bShowAutosclCheckbox, rbAutoscl )	// FALSE : enable checkbox (=Dac), TRUE : disable checkbox (=Adc)
	ConstructCbListboxYZoom( sWNm, bShowZoomOfsControls, rYZoom )	
	//ConstructCbListboxYOfs( sWNm, bShowZoomOfsControls, rYOfs )	
	ConstructCbSliderYOfs( 	sWNm, bShowZoomOfsControls, rYOfs )		
	SetSliderLimits( sWNm, rDacGain ) //rYZoom )

	SetWndUsersTrace( w, t )										// we use a global variable to pass the trace to the color- and YZoom-Procs...
End

Function		IsDacTrace( sTNm )
// Returns whether the passed Trace is of type 'Dac'  (and not 'Adc') . Needed as only Dac traces be autoscaled.
	string	 	sTNm
	return	( cmpstr( sTNm[ 0, 2 ], "Dac" ) == 0 )
End


Function		CbButtonCopy( ctrlName ) : ButtonControl
// Executed when the user pressed the 'Copy' button : we store the trace to be copied globally using SetCopyCurve( sCurve )
	string		ctrlName
	string		sWNm	= ActiveWnd()
	variable	w		= ActiveWndNr()
	string		sCurve	= StringFromList( WndUsersTrace( w ), RetrieveCurves( w ), sCURVSEP )		
	SetCopyCurve( sCurve )
	printf "\t\t%s()  W:%2d   copying trace \t%d : '%s'  \r", ctrlName, w, WndUsersTrace( w ), CopyCurve()
End

Function		NextFreeInstance( sExistingCurves, sTNm, nRange, nMode )
	string		sExistingCurves, sTNm
	variable	nRange, nMode
	string		sTrace
	variable	i
	for ( i = 0; i < 99; i += 1 )										// todo: avoid arbitrary limit		
		sTrace	= sTNm + BuildMoRaNameInstance( nRange, nMode, i )	// e.g. 'Adc0 SM  '   or  ' Dac2 FS 1'
		if ( WhichListItem( sTrace, sExistingCurves ) == NOTFOUND )
			break
		endif 
	endfor
	return  i
End

Function		CbButtonInsert( ctrlName ) : ButtonControl
// Executed when the user pressed the 'Insert' button : we retrieve the trace to be copied from global CopyCurve()...
	string		ctrlName
	variable	rnRange, rnMode, rnInstance, rAuto, rYOfs, rYZoom, rDacGain, t 
	variable	rnRed, rnGreen, rnBlue 
	string		sTNL, sWindowTrace
	string		rsTNm, rsUnits, rsRGB
	string		sWNm		= ActiveWnd()			// the  name  of the window where the user clicked 'Insert'
	variable	w			= ActiveWndNr()		// the number of the window where the user clicked 'Insert'
	string		sCurves		= RetrieveCurves( w )		// the string holding the complete information about all traces in this window which is retrieved from TWA	
	variable	nWUT		= WndUsersTrace( w )

	string		sExistingCurves	= ActiveTNL1()			// the list holding the 'short form' name of all traces in this window which is retrieved from TWA e.g  'Adc0 SC  ;Adc0 SC 1;Dac1 FM  '
	string		sCopyCurve	= CopyCurve()			// the complete information about the currently selected trace (=previously selected in this or another wnd by having clicked 'Copy') 

	ExtractCurve( sCopyCurve, rsTNm, rnRange, rnMode, rnInstance, rAuto, rYOfs, rYZoom, rDacGain, rsUnits, rsRGB )

	// Get the trace instance as computed by FPulse
	printf "\t\t%s() W:%2d\t%d :'%s' \t( original  is \tinstance %d)\t   \r", ctrlName, w, nWUT, sCopyCurve, rnInstance
	rnInstance		= NextFreeInstance( sExistingCurves, rsTNm, rnRange, rnMode )					// the basic trace name is the same but the instances may differ between source and target graph 
	sCopyCurve	= BuildCurve( rsTNm, rnRange, rnMode, rnInstance, rAuto, rYOfs, rYZoom, rDacGain, rsUnits, rsRGB )	// e.g. 'Adc0;SM;20;mV;(40000,0,40000);0;1'	
	printf "\t\t%s() W:%2d\t%d :'%s' \t(converted to\tinstance %d)\tand adding to existing\t'%s' \r", ctrlName, w, nWUT, sCopyCurve, rnInstance, sExistingCurves

	sCurves	= AppendListItem( sCopyCurve, sCurves, sCURVSEP )
	StoreCurves(  w, sCurves )	
	CreateControlBarInAcqWnd( sWNm )  

	// The trace has now been added to TWA internally and will be shown during the next acquisition, but we want to immediately give some feedback to the user ...
	//...to indicate that the trace insertion has indeed been accepted  so we go on and add the trace (or all instances of this trace) to the insertion window :
	nvar		gPrevBlk	= root:disp:gPrevBlk
	gPrevBlk			= -1
	DisplayOffLine( w, w )
End


Function		CbButtonDelete( ctrlName ) : ButtonControl
// executed when the user pressed the 'Del' button.
	string		ctrlName
	string		sWNm	= ActiveWnd()
	variable	w		= ActiveWndNr()
	// First we remove the trace permanently from TWA (which does not automatically remove it from screen) 
	string		sCurves	= RetrieveCurves( w )
	variable	nWUT	= WndUsersTrace( w )
	string		sCurve	= StringFromList( WndUsersTrace( w ), sCurves, sCURVSEP )		
	variable	rnRange, rnMode, rnInstance, rAuto, rYOfs, rYZoom, rDacGain 
	string		rsRGB, rsUnits, rsTNm
	ExtractCurve( sCurve, rsTNm, rnRange, rnMode, rnInstance, rAuto, rYOfs, rYZoom, rDacGain, rsUnits, rsRGB )		// get all traces from this window...
	printf "\t\t%s()\t%s   erasing trace %d : '%s'  instance: %d \r", ctrlName, sWNm, nWUT, sCurve, rnInstance
	sCurves	= RemoveListItem( nWUT, sCurves, sCURVSEP )			// ...remove the trace permanently from TWA 	
	//printf "\t\t%s()\t%s   leaves %d traces: '%s'  \r", ctrlName, sWNm, ItemsInList( sCurves, sCURVSEP ), sCurves
	StoreCurves(  w, sCurves )												// restore the rest of the traces in TWA

	// Now shrink the traces listbox  or possibly hide the whole controlbar and all controls if the last trace has been removed
	CreateControlBarInAcqWnd( sWNm ) 

	// The trace has now been removed from TWA internally and will no longer be shown during the next acquisition, but we want to immediately give some feedback to the
	//... user so he sees his trace deletion has been accepted , so we go on and delete the trace (or all instances of this trace) in the existing window :
	nvar		gPrevBlk	= root:disp:gPrevBlk
	gPrevBlk			= -1
	DisplayOffLine( w, w )
End


Function		CbCheckboxAuto( ctrlName, bAutoscl ) : CheckboxControl
// Executed only when the user changes the 'AutoScale' checkbox : If it is turned on, then YZoom ans YOfs values are computed so that the currently displayed trace is fitted to the window.
	string		ctrlName
	variable	bAutoscl
	string		sWNm	= ActiveWnd()
	variable	w		= ActiveWndNr()
	// First we remove the trace permanently from TWA (which does not automatically remove it from screen) 
	string		sCurves	= RetrieveCurves( w )
	variable	nWUT	= WndUsersTrace( w )
	string		sCurve	= StringFromList( WndUsersTrace( w ), sCurves, sCURVSEP )		
	variable	rnRange, rnMode, rnInstance, rbAuto, rYOfs, rYZoom, rDacGain 
	string		rsRGB, rsUnits, rsTNm

	ExtractCurve( sCurve, rsTNm, rnRange, rnMode, rnInstance, rbAuto, rYOfs, rYZoom, rDacGain, rsUnits, rsRGB )			// get all traces from this window...
	
	printf "\t\t%s()\t%s   Autoscale nWUT %d : '%s'  is: %d -> %d \r", ctrlName, sWNm, nWUT, sCurve, rbAuto, bAutoscl
	AutoscaleZoomAndOfs( sWNm,  rsTNm, bAutoscl, rDacGain, rYOfs, rYZoom )

	ShowOrHideZoomAndOfsControls( sWNm, bAutoscl )								// Enable or disable the YZoom and  YOfs  listboxes depending  on  bAutoscl

	sCurve	= BuildCurve( rsTNm, rnRange, rnMode, rnInstance, bAutoScl, rYOfs, rYZoom, rDacGain, rsUnits, rsRGB )		// the new curve now containing the changed 'AutoScale' .. 
	sCurves	= RemoveListItem( nWUT, sCurves, sCURVSEP )										//..replaces... 	
	sCurves	= AddListItem( sCurve, sCurves, sCURVSEP, nWUT )										// ..the old curve
	StoreCurves(  w, sCurves )

	// The Dac trace has now been rescaled in TWA internally and will  be shown with new scaling during the next acquisition, but we want to immediately give some feedback to the
	//... user so he sees his rescaling has been accepted , so we go on redraw and all windows
	nvar		gPrevBlk	= root:disp:gPrevBlk
	gPrevBlk			= -1
	DisplayOffLine( w, w )
End

Function		AutoscaleZoomAndOfs( sWNm, rsTNm, bAutoscl, DacGain, rYOfs, rYZoom )
// 040109	 Adjust   YZoom  and  YOffset  values  depending on the state of the  'Autoscale'  checkbox.  
// Also store  YZoom  and  YOfs  in TWA  so that the next redrawing of the graph will reflect the changed values.
	string		sWNm, rsTNm
	variable	bAutoscl, DacGain 
	variable	&rYZoom, &rYOfs 
	string		sZoomLBName		= "CbListboxYZoom"
	variable	YAxis			= 0
	variable	DacRange 		= 10								// Volt

	//  Version 1 : only  Dacs  can be autoscaled
	// if ( IsDacTrace( rsTNm ) )										// Only for the Dac we know the exact signal range in advance allowing to scale automatically 

	//  Version 2 :  Dacs  and   Adcs  can be autoscaled
	if ( TRUE )

		if ( bAutoscl )											// 	The checkbox  'Autoscale Y axis for Dacs'  has been turned  ON :
			waveStats	/Q	$rsTNm								// 	...We compute the maximum/mimimum Dac values from the stimulus and set the zoom factor... 

			// // Version 1 :  We use symmetrical axes, the length is the longer of both. The window is filled to 90% . 
			// YAxis	= max( abs( V_max ), abs( V_min ) ) * DacGain / .9	
			// rYOfs	= 0
		
			// Version 2 :  We use asymmetrical axes, the length of each is adjusted separately.  The window is filled to 90% . 
			YAxis	= (  V_max   -  V_min  ) * DacGain	 / 2 / .9 
			rYOfs	= (  V_max  +  V_min  ) * DacGain	 / 2  
		
			rYZoom	= DacRange * 1000 / YAxis				
		else													// 	The checkbox  'Autoscale Y axis for Dacs'  has been turned  OFF : We use the user supplied zoom factor from the listbox
			ControlInfo /W=$sWNm $sZoomLBName					// 	Another way to get S_Value (set by  ControlInfo)
			rYZoom	= str2num( S_Value )
		endif
		printf "\t\t\tAutoscaleZoomAndOfs( '%s' \t'%s'\tpts:\t%8d\t bAutoscl: %s \tDgn:\t%7.1lf\t)  Yaxis:\t%7.1lf\t ->\tZm:\t%8.2lf\tOfs:\t%8.2lf\t  \r",  sWNm, rsTNm, numPnts( $rsTNm ), SelectString( bAutoscl, "OFF" , "ON" ), DacGain, YAxis, rYZoom, rYOfs
		return	TRUE
	else
		return	FALSE
	endif
End


Function		ShowOrHideZoomAndOfsControls( sWNm, bAutoscl )
// 040109	 turn  Y Zoom and Y Offset listboxes  on / off depending on the user switched  state of the  'Autoscale'   checkbox
	string		sWNm
	variable	bAutoscl
	nvar		gbAcqControlbar = root:disp:gbAcqControlbar
	if ( bAutoscl )
		// The checkbox  'Autoscale Y axis for Dacs'  has been turned  ON : We compute the maximum/mimimum Dac values from the stimulus and set the zoom factor so that the window is filled to 90%
		PopupMenu    CbListboxYZoom,	win = $sWNm, disable = bAutoscl + bGrayDontHide	// 'Autoscale Y axis for Dacs' is ON :  turn the YZoom control  OFF (gray or hide it)
		Slider	      CbSliderYOfs,	win = $sWNm, disable = bAutoscl + bGrayDontHide	// 'Autoscale Y axis for Dacs' is ON :  turn the   YOfs  control  OFF (gray or hide it)

		if ( cbVERTICAL_SLIDER_YOFS )
			variable	ControlBarWidth 	= bGrayDontHide == 0   ?  0   :  76		 		// only 'hide' sets width=0 to make the controlbar vanish,  'gray'  leaves it as it is
			ControlBar /W = $sWNm  /R ControlBarWidth
		endif

	else
		// The checkbox  'Autoscale Y axis for Dacs'  has been turned  OFF : Turn the YZoom and YOfs contol  ON  again
		PopupMenu    CbListboxYZoom,	win = $sWNm, disable = bAutoscl || !gbAcqControlbar// turn the YZoom control   ON  again. It  still contains the  previous user setting

		if ( cbVERTICAL_SLIDER_YOFS )
			ControlBarWidth 	= bAutoscl || !gbAcqControlbar	?  0 : 76					// width 0 makes the controlbar vanish
			ControlBar /W = $sWNm  /R ControlBarWidth
		endif

		Slider	      CbSliderYOfs,	win = $sWNm, disable = bAutoscl || !gbAcqControlbar	// turn the  YOfs    control  ON  again. It  still contains the  previous user setting
	endif
End


Function 		CbPopmenuColors( ctrlName, popNum, popStr ) : PopupMenuControl
	string		ctrlName, popStr
	variable	popNum
	string		sWNm	= ActiveWnd()
	//ControlInfo $ctrlName														// Another way to get rgb: sets V_Red, V_Green, V_Blue
	//printf "\t\tCbPopmenuColors( %s, %d, popstr:%s [~%s] )  ControlInfo returned (%d,%d,%d)\r", ctrlName, popNum, popStr, sWNm, V_Red, V_Green, V_Blue
	variable	w		= WndNr( sWNm )
	variable	nCurve, rnRange, rnMode, rnInstance, rAuto, rYOfs, rYZoom, rDacGain, nWUT
	string		sCurves, sCurve, rsRGB, rsUnits, rsTNm
	sCurves	= RetrieveCurves( w )
	nWUT	= WndUsersTrace( w )
	sCurve	= StringFromList( nWUT, sCurves, sCURVSEP )		
	ExtractCurve( sCurve, rsTNm, rnRange, rnMode, rnInstance, rAuto, rYOfs, rYZoom, rDacGain, rsUnits, rsRGB )
	// could be streamlined if   rYZoom / rsRGB  were passed as index....

	rsRGB	= popStr															// change only the color entry, keep all others by restoring them

	sCurve	= BuildCurve( rsTNm, rnRange, rnMode, rnInstance, rAuto, rYOfs, rYZoom, rDacGain, rsUnits, rsRGB )	// the new curve now containing the changed colors..
	printf "\t\t%s()  going to change \tcolor of trace %d : '%s'  \r", ctrlName, nWUT, sCurves
	sCurves	= RemoveListItem( nWUT, sCurves, sCURVSEP )						//..replaces... 	
	sCurves	= AddListItem( sCurve, sCurves, sCURVSEP, nWUT )						// ..the old curve
	printf "\t\t%s()  has changed \t\tcolor of trace %d : '%s'  \r", ctrlName, nWUT, sCurves
	StoreCurves(  w, sCurves )

	// The new colors have now been set and will be effective during the next acquisition, but we want to immediately give some feedback to the..
	// ..user so he sees his color change has been accepted, so we go on and colorize the trace (or all instances of this trace) in the existing window :
	nvar		gPrevBlk	= root:disp:gPrevBlk
	gPrevBlk			= -1
	DisplayOffLine( w, w )
End

Function		 CbListboxYZoom( ctrlName, popNum, sPop ) : PopupMenuControl
// Action proc executed when the user selects a zoom value from the listbox.  Update  TWA  and  change axis and traces immediately to give some feedback.
	string		ctrlName, sPop
	variable	popNum
	string		sWNm	= ActiveWnd()

	ControlInfo $ctrlName											// Another way to get S_Value (set by  ControlInfo)
	//printf "\t\t%s(..%2d,\tsPop:%s\t[~%s] )  ControlInfo returned %g   '%s'\r", ctrlName, popNum, pd(sPop,5), sWNm, V_Value, S_Value
	variable	w		= WndNr( sWNm )
	variable	nCurve, rnRange, rnMode, rnInstance, rAuto, rYOfs, rYZoom, rDacGain, nWUT
	string		sCurves, sCurve, rsRGB, rsUnits, rsTNm
	sCurves	= RetrieveCurves( w )
	nWUT	= WndUsersTrace( w )
	sCurve	= StringFromList( nWUT, sCurves, sCURVSEP )		
	ExtractCurve( sCurve, rsTNm, rnRange, rnMode, rnInstance, rAuto, rYOfs, rYZoom, rDacGain, rsUnits, rsRGB )

	rYZoom	= str2num( sPop )										// change only the YZoom entry, keep all others by restoring them

	sCurve	= BuildCurve( rsTNm, rnRange, rnMode, rnInstance, rAuto, rYOfs, rYZoom, rDacGain, rsUnits, rsRGB )// the new curve now containing the changed Yzoom factor.. 
	sCurves	= RemoveListItem( nWUT, sCurves, sCURVSEP )				//..replaces... 	
	sCurves	= AddListItem( sCurve, sCurves, sCURVSEP, nWUT )				// ..the old curve
	StoreCurves(  w, sCurves )

	SetSliderLimits( sWNm, rDacGain )  //rYZoom )

	// The new YZoom has now been set and will be effective during the next acquisition, but we want to immediately give some feedback to the..
	// ..user so he sees his YZoom  change has been accepted , so we go on and change the Y Axis range in the existing window :
	nvar		gPrevBlk	= root:disp:gPrevBlk
	gPrevBlk			= -1
	DisplayOffLine( w, w )
End

Function		SetSliderLimits( sWNm, DacGain ) //rYZoom )
	string 	sWNm
	variable	DacGain  //,YZoom
	variable	DacRange	= 10								// Volt
	variable	YAxis		= DacRange * 1000 / DacGain 			//   / YZoom 
	// printf "\t\t\tSetSliderLimits() \t'%s'\tZm:\t%7.1lf\tDGn:\t%7.1lf\t-> Axis:\t%7.1lf\t  \r", sWNm, YZoom, DacGain, YAxis
	printf "\t\t\tSetSliderLimits() \t'%s'\tDGn:\t%7.1lf\t-> Axis:\t%7.1lf\t  \r", sWNm, DacGain, YAxis
	Slider	CbSliderYOfs,	win = $sWNm,	limits = { -Yaxis, YAxis, 0 }
End

//  YOFS  implemented as Listbox
//
//Function		 CbListboxYOfs( ctrlName, popNum, sPop ) : PopupMenuControl
//// Action proc executed when the user selects an Y offset value from the listbox.  Update  TWA  and  change axis and traces immediately to give some feedback.
//	string		ctrlName, sPop
//	variable	popNum
//	string		sWNm	= ActiveWnd()
//
//	// ControlInfo $ctrlName											// Another way to get S_Value (set by  ControlInfo)
//	// printf "\t\t%s(..%2d,\tsPop:%s\t[~%s] )  ControlInfo returned %g   '%s'\r", ctrlName, popNum, pd(sPop,5), sWNm, V_Value, S_Value
//	variable	w		= WndNr( sWNm )
//	variable	nCurve, rnRange, rnMode, rnInstance, rAuto, rYOfs, rYZoom, rDacGain, nWUT
//	string		sCurves, sCurve, rsRGB, rsUnits, rsTNm
//	sCurves	= RetrieveCurves( w )
//	nWUT	= WndUsersTrace( w )
//	sCurve	= StringFromList( nWUT, sCurves, sCURVSEP )		
//	ExtractCurve( sCurve, rsTNm, rnRange, rnMode, rnInstance, rAuto, rYOfs, rYZoom, rDacGain, rsUnits, rsRGB )
//
//	rYOfs	= str2num( sPop )									// change only the Y offset entry, keep all others by restoring them
//
//	sCurve	= BuildCurve( rsTNm, rnRange, rnMode, rnInstance, rAuto, rYOfs, rYZoom, rDacGain, rsUnits, rsRGB )		// the new curve now containing the changed Yzoom factor.. 
//	sCurves	= RemoveListItem( nWUT, sCurves, sCURVSEP )			//..replaces... 	
//	sCurves	= AddListItem( sCurve, sCurves, sCURVSEP, nWUT )			// ..the old curve
//	StoreCurves(  w, sCurves )
//
//	// The new YOffset has now been set and will be effective during the next acquisition, but we want to immediately give some feedback to the..
//	// ..user so he sees his YOffset change has been accepted , so we go on and change the Yoffset in the existing window :
//	nvar		gPrevBlk	= root:disp:gPrevBlk
//	gPrevBlk			= -1
//	DisplayOffLine( w, w )
//End

//  YOFS  implemented as Slider
//
Function		CbSliderYOfs( sControlNm, value, event )
	string		sControlNm			// name of this slider control
	variable	value				// value of slider
	variable	event				// bit field: bit 0: value set; 1: mouse down, 2: mouse up, 3: mouse moved
	printf "\tSlider '%s'  gives value:%d  event:%d  \r", sControlNm, value, event
	string		sWNm	= ActiveWnd()
	variable	w		= WndNr( sWNm )
	variable	nCurve, rnRange, rnMode, rnInstance, rAuto, rYOfs, rYZoom, rDacGain, nWUT
	string		sCurves, sCurve, rsRGB, rsUnits, rsTNm
	sCurves	= RetrieveCurves( w )
	nWUT	= WndUsersTrace( w )
	sCurve	= StringFromList( nWUT, sCurves, sCURVSEP )		
	ExtractCurve( sCurve, rsTNm, rnRange, rnMode, rnInstance, rAuto, rYOfs, rYZoom, rDacGain, rsUnits, rsRGB )

	rYOfs	= value * rDacGain												// change only the Y offset entry, keep all others by restoring them

	sCurve	= BuildCurve( rsTNm, rnRange, rnMode, rnInstance, rAuto, rYOfs, rYZoom, rDacGain, rsUnits, rsRGB )	// the new curve now containing the changed Yzoom factor.. 
	sCurves	= RemoveListItem( nWUT, sCurves, sCURVSEP )						//..replaces... 	
	sCurves	= AddListItem( sCurve, sCurves, sCURVSEP, nWUT )						// ..the old curve
	StoreCurves(  w, sCurves )

	// The new YOffset has now been set and will be effective during the next acquisition, but we want to immediately give some feedback to the..
	// ..user so he sees his YOffset change has been accepted , so we go on and change the Yoffset in the existing window :
	nvar		gPrevBlk	= root:disp:gPrevBlk
	gPrevBlk			= -1
	DisplayOffLine( w, w )
	return 0				// other return values reserved
End


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  CONTROLBARS  in  the  ACQUISITION  WINDOWS : LITTLE  HELPERS

Function  /S	GetWindowTNL( sWndNm, nMode )
// nMode = 0 : returns a list of all traces contained in the given window e.g. 'Adc2,Dac0,Adc1..'
// nMode = 1 :  returns a list of all traces contained in the given window with Mode/Range extension and with instance  e.g. 'Adc2 SM  ,Dac0 FS 1,Adc1 RS 2'  with spaces for improved readability
 	string		sWndNm
 	variable	nMode
	variable	w = WndNr( sWndNm )
	string		sTNL = ""
	string		sCurve, sCurves	= RetrieveCurves( w )
	variable	ioch, ioCnt		= ItemsInList( sCurves, sCURVSEP )
	variable	rnRange, rnMode, rnInstance, rAuto, rYOfs, rYZoom, rDacGain
	string		sTNm, rsUnits, rsRGB
	for ( ioch = 0; ioch < ioCnt; ioch += 1 )
		sCurve	= StringFromList( ioch, sCurves, sCURVSEP )
		ExtractCurve( sCurve, sTNm, rnRange, rnMode, rnInstance, rAuto, rYOfs, rYZoom, rDacGain, rsUnits, rsRGB )		// parameters are changed
		if ( nMode == 1 )
			sTNm	+= BuildMoRaNameInstance( rnRange, rnMode, rnInstance ) 				// 040107
		endif
		sTNL	= AddListItem( sTNm, sTNL, ";", Inf )
		//printf "\t\tGetWindowTNL( %s, mode:%d ) : '%s'  \t-> '%s' \r", sWndNm, bMode, sTNm, sTNL
	endfor
	//printf "\t\t\tGetWindowTNL( %s, mode:%d )\tfrom sCurves\t'%s'  \tsCurves: '%s' \r", sWndNm, nMode, sTNL, sCurves[0,200]
	//printf "\t\t\tGetWindowTNL( %s, mode:%d )\tfrom IGOR :\t'%s'  \t \r", sWndNm, nMode, TraceNameList( sWndNm, ";", 1 )	// 031224
	return	sTNL
End

Function		SetActiveWnd( sWnd )
	string		sWnd
	svar		gsLbActiveWnd	= root:disp:gsLbActiveWnd
	gsLbActiveWnd	= sWnd
End

Function	/S	ActiveWnd()
	svar		gsLbActiveWnd	= root:disp:gsLbActiveWnd
 	return	gsLbActiveWnd
End
Function	/S	ActiveTNL1()
 	return 	( GetWindowTNL( ActiveWnd(), 1 ) )		// 040103 include instance number 0 1 2 ... but only for traces listbox, not for trace name
End

Function		ActiveWndNr()
	return	WndNr( ActiveWnd() )
End


Function	/S	SetCopyCurve( sCopyCurve )
// Needed to transfer information about the trace to be copied between graphs from the source traces listbox to the target traces listbox 
	string	 	sCopyCurve
	svar		gsCopyCurve	= root:disp:gsCopyCurve
	gsCopyCurve	= sCopyCurve
End
Function	/S	CopyCurve()
	svar		gsCopyCurve	= root:disp:gsCopyCurve
	return	gsCopyCurve
End

Function	/S	AppendListItem( sItem, sList, sSep )
// adds an item at the end of a list  but not expecting a separator at the end  like  AddListItem(sItem, sList, sSep, Inf)  does
	string	sList, sItem, sSep
//	return	SelectString( strlen( sList ), sItem, sList + sSep + sItem )
	variable	len =  strlen( sList )
	if( len == 0 )								
		return	sItem						// list was empty, add the element 
	elseif ( cmpstr( sList[ len-1, len-1] , sSep ) )
		return	sList + sSep + sItem			// list had elements but had no already trailing separator: add separator and element
	else
		return	sList + sItem				// list had elements and had already trailing separator: add the element
	endif	
End

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////    DISPLAY  DURING  ACQUISITION  DIALOG BOX
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function  	DisplayOptionsAcqWindows()

	// Try1: works but user has to close the panel and open it again to see changes in the entries e.g. when Dac channel number changes
	ConstructOrDisplayPanel(  "PnAcqWin" )	//
	// Try2: works but  this panel is accumulating....	(we must first close the panel automatically in case it exists)
	// Execute  "PnAcqWin()"	// we construct the panel every time (and do not only bring an existing to the front), as entries may have changed 

// Even better: when panel is visible; update it automatically when entries change, e.g. when Dac channel number changes
// Even better: when panel is not visible....

End

Window		PnAcqWin()
	PauseUpdate; Silent 1				// building window...
	string		sFolderPnText = "root:dlg:tPnAcqWnd"
	InitDisplayOptionsAcqWindows( sFolderPnText )		// constructs the text wave  'tPnAcqWn'  defining the panel controls
	variable	XSize = PnXsize( $sFolderPnText ) 
	variable	XLoc	= GetIgorAppPixel( "X" ) -  XSize - 170
	variable 	YLoc	= 100			// Panel location in pixel from upper side
	DrawPanel( $sFolderPnText, XSize,  XLoc, YLoc, "Disp Acquisition" )	
//021219
//	SetWindow	 PnAcqWin, hook = fHookPnAcqWin 	// prevent reentering when building windows...
EndMacro
 
Function		InitDisplayOptionsAcqWindows( sFolderPnText )
	string	sFolderPnText
	variable	n = -1, nItems = 30		// separator needs FLEN entry
	make /O /T /N=(nItems)	$sFolderPnText
	wave  /T	tPn		=	$sFolderPnText
	n = PnControl( tPn, n, "PN_CHKBOX", cVERT, "Automatic data windows" 	, sFOLDER_DLGTMP + sTRACE_BASE, lstTitleTraces(), "Automatic data windows" , "TrMoRa" ) 
	n = PnControl( tPn, n, "PN_CHKBOX", cVERT, "Range" 				, sFOLDER_DLGTMP + cRANGE,	sRANGETEXT, "Range", 	"TrMoRa" ) 
	n = PnControl( tPn, n, "PN_CHKBOX", cVERT, "Mode" 				, sFOLDER_DLGTMP + cMODE, 	sMODETEXT,   "Mode", 	"TrMoRa" ) 
	n += 1;	tPn[ n ] =	"PN_SEPAR"
	n += 1;	tPn[ n ] =	"PN_BUTTON;	buDispWARectAuto	;automatic;  |	PN_BUTTON	;buDispWARectUsSpec ;user specific" 
	n += 1;	tPn[ n ] =	"PN_BUTTON;	SaveDisplayConfig	;Save display config"
	//n += 1;	tPn[ n ] =	"PN_BUTTON;	EraseTraceInWnd	;Erase trace in window"

	redimension  /N = (n+1)	tPn	
End

Function		buDispWARectAuto( ctrlName ) : ButtonControl
	string	ctrlName
	TrMoRa( "ctrlName", 123 )
End

Function		buDispWARectUsSpec( ctrlName ) : ButtonControl
	string		ctrlName
	svar		gsScriptPath	= root:dlg:gsScriptPath
	LoadDisplayCfg( gsScriptPath )

End

Function		SaveDisplayConfig( ctrlName ) : ButtonControl
	string		ctrlName		
	 //printf "\tSaveDisplayCfg(%s)  \r", ctrlName 
	SaveDispCfg()
End

//Function		EraseTraceInWnd( ctrlName ) : ButtonControl
//	string	ctrlName		
//	string	sTNL	= ActiveTNL1()
//	 printf "\tEraseTraceInWnd(%s)  '%s' \r", ctrlName, sTNL 
//End

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  THE  TRACE  CHECKBOXES  APPEARING  IN  THE  PANEL  DEPEND  ON  THE  ENTRIES  IN  THE  SCIPT

strconstant	sTRACE_BASE		= "gbTrc"

Function	/S	lstTitleTraces()
	string		sList = ""
	string	sTrace, sFolder	= sFOLDER_DLGTMP
	variable	ioch			
	for ( ioch = 0; ioch < ioCnt(); ioch += 1 )				// all channels from script (Dac, Adc,Aver,PoN,Sum...)
		sTrace	= ios( ioch, cIONM ) 		
		sList	= AddListItem( sTrace, sList, ";", Inf )
	endfor												
	//printf "\tlstTitleTraces()  items:%d    \tsTitleList='%s' \r", ItemsInList( sList ), sList
	return	sList
End

Function  /S	TraceVarNm( sTrace )
	string	sTrace
	return	sTRACE_BASE + "_" + sTrace				// 030122  e.g.  Adc0 -> t_Adc0
	//return	sTRACE_BASE + sTrace				 	// e.g.  Adc0 -> tAdc0
End

Function  /S	TraceFromVarNm( sTraceVarName )
	string	sTraceVarName
	return	sTraceVarName[ strlen( sTRACE_BASE ) + 1, Inf ]	// remove the 't' and the '_' added above  e.g.  tAdc0 -> Adc0
	//return	sTraceVarName[ strlen( sTRACE_BASE ), Inf ]	// remove the 't' added above  e.g.  tAdc0 -> Adc0
End

Function  	bTraceOn( sTrace )
// returns TRUE or FALSE  for traces like 'Adc0'  which have a variable name like ' t_Adc0'
	string	sTrace
	return	FolderGetV( sFOLDER_DLGTMP, TraceVarNm( sTrace ), ON )	
End

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  IMPLEMENTATION  of  the  SEPARATE  MODE-RANGE  ( in 2 variables )

strconstant		cMODE		= "bMode"
constant			cCURRENT 	= 0,		cMANYSUPIMP = 1,	cMAXMODE = 2	//! must correspond to strings in ModeNm(), ModeVarNm() below
static  strconstant	sMODETEXT	= "Current;Many superimposed"
static  strconstant	sMODENM	= "C;M"

strconstant		cRANGE		= "bRange"
constant			cSWEEP 		= 0,	cFRAME = 1,  cPRIM = 2,	cRESULT = 3,	cMAXRANGE = 4	//! must correspond to strings in RangeNm(), RangeVarNm() below
static  strconstant	sRANGETEXT	= "Sweeps;Frames;Primary;Result"
static  strconstant	sRANGENM	= "S;F;P;R"

Function TrMoRa( sControlNm, bValue )
// update the trace-window-array according to the user settings in the panel
	string	sControlNm
	variable	bValue
	// printf "\t\tTrMoRa( '%s', %d ) \r",  sControlNm, bValue
	DisplayHelpTopicFor( sControlNm )	// EXPLICIT help display needed here as this action proc name is NOT derived from the control name (multiple controls have same proc)
	InitializeAutoWndArray()
	//  Retrieve the Mode/Range-Color-DispGain  string entries  and  build the (still empty) windows
	BuildWindows( FRONT )
	EnableButton( "PnPuls", "buPreparePrint", ENABLE )	// Now that the acquisition windows (and TWA) are constructed we can allow drawing in them (even if they are still empty)
End

Function  /S	ModeVarNm( n )
// returns the name of the global  'Mode'  variable  e.g. 'bModeCur' , 'bModeSup'
	variable	n
	return	cMODE + "_" + RemoveWhiteSpace( StringFromList( n, sMODETEXT ) )	// 030122
//	return	cMODE + RemoveWhiteSpace( StringFromList( n, sMODETEXT ) )
End

Function  /S	ModeNm( n )
// returns  an arbitrary  name for the mode, not for the variable  e.g. 'C' , 'M' 
	variable	n
	return	StringFromList( n, sMODENM )
End

Function		ModeNr( s )
// returns  index of the mode, given its name
	string	s
variable	nMode = 0			// Do not issue a warning when no character is passed.... 
if ( strlen( s ) )					// This happens when a window contains no traces.
	nMode = WhichListItem( s, sMODENM )
	if ( nMode == NOTFOUND )
		InternalError( "[ModeNr] '" + s + "' must be 'C' or 'M' " )
	endif
endif
	return nMode
End

Function  	bModeOn( n ) 
	variable	n
	return	FolderGetV( sFOLDER_DLGTMP, ModeVarNm( n ), ON ) 
End

// could be combined into ModeInfo( rnModeCnt, rsUsedModeList, rsUsedModeNames...)
Function	 /S	UsedModeList()
	variable	n
	string	sUsedList	= ""
	for ( n = 0; n < cMAXMODE; n += 1 ) 
		if ( bModeOn( n ) )
			sUsedList 	= AddListItem( num2str( n ), sUsedList, ";", Inf )	// makes list e.g. '0;1;3'
		endif
	endfor
	return	sUsedList
End

Function		UsedModeCnt()	
	variable	n, nUsedCnt = 0
	for ( n = 0; n < cMAXMODE; n += 1 ) 
		nUsedCnt +=  bModeOn( n )			// add  1 only  if  this mode is turned on
	endfor
	return	nUsedCnt	// shorter but dangerous when extending: 	return	bModeOn( cCURRENT)   +   bModeOn( cMANYSUPIMP )	
End	

Function		ModeCnt()	
	return	cMAXMODE
End	

Function  /S	RangeVarNm( n )
// returns the name of the global  'Range'  variable  e.g  'bRangeSweeps' , 'bRangeFrames' .....
	variable	n

//	return	cRANGE + StringFromList( n, sRANGETEXT )
	return	cRANGE + "_" + StringFromList( n, sRANGETEXT )	//030122
End

Function  /S	RangeNm( n )
// returns  an arbitrary  name for the range, not for the variable  e.g.  'S' , 'F',  'R',  'P'
	variable	n
	return	StringFromList( n, sRANGENM )
End

Function		RangeNr( s )
// returns  index of the range, given its name
	string	s
variable	n = 0				// Do not issue a warning when no character is passed.... 
if ( strlen( s ) )					// This happens when a window contains no traces.
	n = WhichListItem( s, sRANGENM )
	if ( n == NOTFOUND )
		InternalError( "[RangeNr] '" + s + "' must be 'S' (Sweep) or 'F' (Frame) or 'P' (Primary sweep) or 'R' (Result sweep) " )
	endif
endif
	return n
End

Function  	bRangeOn( n )
	variable	n
	return	FolderGetV( sFOLDER_DLGTMP, RangeVarNm( n ), ON )
End

Function		UsedRangeCnt()	
	variable	n, nUsedCnt = 0
	for ( n = 0; n < cMAXRANGE; n += 1 ) 
		nUsedCnt +=  bRangeOn( n )	// add  1 only  if  this range is turned on
	endfor
	return	nUsedCnt
End	

Function	 /S	UsedRangeList()
	variable	n
	string	sUsedList	= ""
	for ( n = 0; n < cMAXRANGE; n += 1 ) 
		if ( bRangeOn( n ) )
			sUsedList 	= AddListItem( num2str( n ), sUsedList, ";", Inf )	// makes list e.g. '0;1;3'
		endif
	endfor
	return	sUsedList
End

Function		RangeCnt()
	return	cMAXRANGE
End	


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  IMPLEMENTATION  for  STORING   MODE  and  RANGE  as  a 2-LETTER-STRING

Function	   /S 		BuildMoRaName( nRange, nMode )
// converts the Mode / range setting for storage in TWA  to a 2-letter-string  e.g. 	'SM',   'FC' 
	variable	nRange, nMode
	return	RangeNm( nRange ) + ModeNm( nMode )
End

Function	   /S 		BuildMoRaNameInstance( nRange, nMode, nInstance )		// 040107
// converts the Mode / range setting into a 2-letter-string  containing the instance number  e.g. 	'SM ',   'FC1'       ( obsolete: 'SMa',   'FCb' )  
	variable	nRange, nMode, nInstance 
	string   	sInstance = SelectString( nInstance != 0, " " , num2str( nInstance ) )	// for the 1. instance  do not display the zero but leave blank instead
	return	" " + BuildMoRaName( nRange, nMode ) + " " + sInstance 			// 040107
End

Function			ExtractMoRaName( sMoRa, rnRange, rnMode )
// retrieves the Mode / range setting  from TWA  and converts the 2-letter-string  into 2 numbers  e.g. 'SM'->0,1   'RS' ->3,0
	string		sMoRa
	variable	&rnRange, &rnMode
	rnRange	= RangeNr( sMora[0,0] )
	rnMode	= ModeNr(   sMora[1,1] )
End

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////    TRACE SELECT   PANEL
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function   /S	TraceSelectModalDialog( sTNL )
	string	sTNL
	string	sTrace = ""
	Prompt	sTrace, "Trace", popup, sTNL
	DoPrompt	"Select a trace", sTrace	
	if ( V_Flag )
		return	StringFromList( 0, sTNL )		// user canceled
	endif
	return	sTrace
End


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//    ACTION  PROCEDURES  from  the  PREFERENCES  PANEL
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function		root_disp_gbAcqControlbar( ctrlName, bValue ) 
// creates Trace / Window controlbar in acq windows
	string		ctrlName
	variable	bValue	
	CreateAllControlBarsInAcqWnd()		// show / hide the ControlBar  immediately
End

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  SAMPLE : NON-MODAL  PANEL

//Function CreateTraceSelectPanel()
//	DoWindow /F TrcSelectPanel			// try to bring to front
//	if ( V_Flag == 0 )						// panel does not yet exist
//		Execute "TraceSelectPanel()"
//	endif
// End
//
// Proc	TraceSelectPanel()
//	PauseUpdate; Silent 1				// building window...
//	variable	XLoc	= GetIgorAppPixel( "X" ) -  250  // - PnXsize( tPnAcqWn ) - 170
//	variable 	YLoc	= 300			// Panel location in pixel from upper side
//
//	NewPanel /K=1 /W=( XLoc, YLoc, XLoc +140, YLoc +60 ) 
//	PopupMenu popup1,pos={10,10},size={60,20},proc=TraceSelectProc,title="Traces"
//	PopupMenu popup1,value= 	GetTraceOnNameList()
//EndMacro

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////    COLORIZE  TRACES  PANEL
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//Function CreateTraceColorPanel()
//// Construction of this panel taken from KBColorizeTraces.IPF ( it does not fit in my usual panel construction because of the PopupMenu )
//	DoWindow /F ColorizePanel				// try to bring to front
//	if ( V_Flag == 0 )						// panel does not yet exist
//		Execute "TraceColorPanel()"
//	endif
// End
//
// Proc	TraceColorPanel()
//	PauseUpdate; Silent 1				// building window...
//	variable	XLoc	= GetIgorAppPixel( "X" ) -  250  // - PnXsize( tPnAcqWn ) - 170
//	variable 	YLoc	= 300			// Panel location in pixel from upper side
//
//// small single color popup
////	NewPanel /K=1 /W=( XLoc, YLoc, XLoc +90, YLoc + 32 )
////	PopupMenu popup0,pos={10,10},size={96,20},proc=ColorPopMenuProc,title="colors"
////	PopupMenu popup0,mode=1,popColor= (0,65535,65535),value= "*COLORPOP*"
//
//// larger double color / trace popup
//	NewPanel /K=1 /W=( XLoc, YLoc, XLoc +240, YLoc + 40 ) 
//	PopupMenu popup0,pos={5,10},size={96,20},proc=ColorPopMenuProc,title="colors"
//	PopupMenu popup0,mode=1,popColor= (0,65535,65535),value= "*COLORPOP*"
//
//	PopupMenu popup1,pos={100,10},size={60,20},proc=ColorPopMenuProc,title="traces"
//	PopupMenu popup1,value= 	ioChanList()
//EndMacro


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////    STATUSBAR   ( FUNCTION  VERSION  WITH  DEPENDENCIES )
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function		NewStatusBar( sSBNm, sSBTitle )	
	string	sSBNm, sSBTitle
	if ( winType( sSBNm ) != GRAPH )					// the desired status bar does not exist....
		KillGraphs( "SB*" )								// ..so kill any other status bar that might exist...
		if ( cmpstr( sSBNm, "SB_ACQUISITION" ) == 0 )	
			CreateStatusBarAcq( sSBNm, sSBTitle )		// ..and build the desired status bar 
		elseif ( cmpstr( sSBNm, "SB_CFSREAD" ) == 0 )	
			CreateStatusBarCFSRead( sSBNm, sSBTitle )	// ..and build the desired status bar 
		endif	
	endif											// Do nothing if the desired status bar exists already
End			   


Function		CreateStatusBarAcq( sSBNm, sSBTitle )	
// implemented as GRAPH (not panel! ) for TextBox to work, implemented as function, GRAPH WINDOW coordinates are POINTS
	string	sSBNm, sSBTitle
	PauseUpdate; Silent 1									// building window...
	variable	Ysize		= 31 							//?  has minimum of about 20..
	variable	YControlBar	= 22								// if not desired set to 0  AND  comment out  'ControlBar  YControlBar'  below
	variable	rxMinPoints, rxMaxPoints, ryMinPoints, ryMaxPoints 
 	GetIgorAppPoints( rxMinPoints, rxMaxPoints, ryMinPoints, ryMaxPoints )	// parameters changed by function
	// print  "CreateStatusBar() points  X..",   rxMinPoints, "..XR",  rxMaxPoints,  "Y...",  ryMinPoints, "...YB",  ryMaxPoints,  "appPixX", GetIgorAppPixel( "X" ),  "appPixY", GetIgorAppPixel( "Y" )

	Display	 	/K=1   /W=( rxMinPoints,     ryMaxPoints - ySize + 2, rxMaxPoints, ryMaxPoints + 2 ) as sSBTitle
	ControlBar 	YControlBar
	// print "ControlBar", sSBNm 
	DoWindow	/C $sSBNm

	// SetFormula gVar1, "gVar + 1"		// creates a dependency in a function, in Macro gVar1 := gVar + 1
	
	// TextBox: can only be used in graphs (not in panels), updates automatically (no explicit dependencies necessary)
	// Write the Cursor/Point/Region values into the LOWER statusbar line = one TextBox   (not here: upper=ValDisplay)

	// Igor requires to split the statusline into multiple textboxes because of the 400 characters per line limit  ( 3 with /MC is not good as it overwrites the end of the preceding field on 800x600)
	// Igor requires to split the statusline into multiple textboxes because of the 400 characters per line limit: Splitting into 2 instead of 3  blocks does not look very nice but avoids overwriting text...
	//TextBox /A=LC /X=0 /F=0 "  Stim: \\{root:dlg:gsScriptPath}     Data: \\{root:cfs:gsDataPath}\\{root:cfs:gsDataFile}     Duty:\\{\"%2d%\",root:cont:gDuty}    Lag:\\{\"%2ds\", LaggingTime()}    Blk:\\{root:disp:gPrevBlk} / \\{eBlocks()}    Swp:\\{root:cfs:gSwpsWritten} / \\{root:stim:gTotalSweeps}  "
	//TextBox /A=LC /X=0 /F=0 "  Stim: \\{root:dlg:gsScriptPath}     Data: \\{root:cfs:gsDataPath}\\{root:cfs:gsDataFile}     Resv:\\{\"%2d / %d\",root:cont:gMinReserve, root:cont:gChnkPerRep}    Lag:\\{\"%2ds\", LaggingTime()}    Blk:\\{root:disp:gPrevBlk} / \\{eBlocks()}    Swp:\\{root:cfs:gSwpsWritten} / \\{root:stim:gTotalSweeps}  "
	TextBox /A=LC /X=0 /F=0 "  Stim: \\{root:dlg:gsScriptPath}     Data: \\{root:cfs:gsDataPath}\\{root:cfs:gsDataFile}     Pred:\\{\"%4.2lf\",root:cont:gPrediction}    Lag:\\{\"%2ds\", LaggingTime()}    Blk:\\{root:disp:gPrevBlk} / \\{eBlocks()}    Swp:\\{root:cfs:gSwpsWritten} / \\{root:stim:gTotalSweeps}  "

	TextBox /A=RC /X=0 /F=0 " Time:\\{\"%2d / %2d  \", TimeElapsed(), root:stim:gTotalStimMicroSc/1e6 }   \\{root:cont:gsAllGains} "

	// ValDisplay: can be used in panels or in controlbars in graphs, invalid arguments can be ignored by using #, updates automatically (no explicit dependencies neccessary)????
	//ValDisplay vd1,  pos={0,2},  size={140,15},  title="Duty",  format="%2d%",  limits={0,100,80},  barmisc={0,30},  value= #"root:cont:gDuty", lowColor=(0,50000,0), highColor=(50000,0,0)
	//ValDisplay vd1,  pos={0,2},  size={140,15},  title="Resv",  format="%2d",  limits={-3,18,0},  barmisc={0,20},  value= #"root:cont:gReserve", lowColor=(65535,0,0), highColor=(0,50000,0)
	ValDisplay vd1,  pos={0,2},  size={120,15},  title="Pred",  format="%4.2lf",  limits={ 0,2,1},  barmisc={0,32},  value= #"root:cont:gPrediction", lowColor=(65535,0,0), highColor=(0,50000,0)

	StatusBarLiveDisplays( sSBNm )

EndMacro
 
Function		StatusBarLiveDisplays( sSBNm )
	string	sSBNm
	// update region location in status bar 
	// Write the Cursor/Point/Region values into the UPPER statusbar line = multiple ValDisplay m   (not here: lower=TextBox)
	ValDisplay sbCursX,		win = $sSBNm,  pos={200,3},   size={110,14}, title= "Cursor:X",	format= "%.1lf",  value= #"root:disp:gCursX"
	ValDisplay sbCursY,		win = $sSBNm,  pos={280,3},   size={80,14},   title= "       Y",		format= "%.1lf",  value= #"root:disp:gCursY"
	ValDisplay sbWaveY,		win = $sSBNm,  pos={360,3},   size={80,14},   title= "W: Y",		format= "%.1lf",  value= #"root:disp:gWaveY"
	ValDisplay sbWaveMin,	win = $sSBNm,  pos={460,3},   size={80,14},   title= "W: min",	format= "%.1lf",  value= #"root:disp:gWaveMin"
	ValDisplay sbWaveMax,	win = $sSBNm,  pos={560,3},   size={80,14},   title= "W: max",	format= "%.1lf",  value= #"root:disp:gWaveMax"
	ValDisplay sbPntX,		win = $sSBNm,  pos={700,3},   size={100,14}, title= "Point:X",	format= "%.1lf",  value= #"root:disp:gPx"
	ValDisplay sbPntY,		win = $sSBNm,  pos={780,3},   size={80,14},   title= "       Y",		format= "%.1lf",  value= #"root:disp:gPy"
	ValDisplay sbRegLeft,	win = $sSBNm,  pos={900,3},   size={90,14},   title= "Reg:left",	format= "%.1lf",  value= #"root:V_left"
	ValDisplay sbRegRight,	win = $sSBNm,  pos={990,3},   size={80,14},   title= " right",		format= "%.1lf",  value= #"root:V_right"
	ValDisplay sbRegTop,	win = $sSBNm,  pos={1060,3}, size={80,14},   title= "     top",	format= "%.1lf",  value= #"root:V_top"
	ValDisplay sbRegBot,		win = $sSBNm,  pos={1140,3}, size={80,14},   title= "     bot",	format= "%.1lf",  value= #"root:V_bottom"
	ValDisplay sbCursX,		win = $sSBNm,  help={"Shows the current  X  coordinate of the cursor."}, 			limits={0,0,0}, barmisc={0,1000}
	ValDisplay sbCursY,		win = $sSBNm,  help={"Shows the current  Y  coordinate of the cursor."}, 			limits={0,0,0}, barmisc={0,1000}
	ValDisplay sbPntX,		win = $sSBNm,  help={"Shows the  X  coordinate of the last recently clicked point."},	limits={0,0,0}, barmisc={0,1000}
	ValDisplay sbPntY,		win = $sSBNm,  help={"Shows the  Y  coordinate of the last recently clicked point."},	limits={0,0,0}, barmisc={0,1000}
	ValDisplay sbRegLeft,	win = $sSBNm,  help={"Shows the  left  coordinate of the last recently active region."}, 	limits={0,0,0}, barmisc={0,1000}
	ValDisplay sbRegRight,	win = $sSBNm,  help={"Shows the right coordinate of the last recently active region."},	limits={0,0,0}, barmisc={0,1000}
	ValDisplay sbRegTop,	win = $sSBNm,  help={"Shows the  top  coordinate of the last recently active region."}, 	limits={0,0,0}, barmisc={0,1000}
	ValDisplay sbRegBot,		win = $sSBNm,  help={"Shows the bottom coordinate of the last recently active region."},limits={0,0,0}, barmisc={0,1000}
End


Function WaveMinimum( w, left, right )		
// Returns min value of the specified wave in the specified range.
// The min ValDisplay control is tied to this function.
	Wave	w
	variable	left, right
	WaveStats /Q /R=( left, right ) w
	return V_min
End
	
Function WaveMaximum(w, left, right)	
// Returns max value of the specified wave in the specified range.
// The wMax ValDisplay control is tied to this function
	Wave	w
	variable	left, right
	WaveStats /Q /R= ( left, right ) w
	return V_max
End

