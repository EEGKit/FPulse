	//
	// UF_AcqDisp4.ipf
	// 
	// Routines for
	//	displaying traces during acquisition
	//
//	// How the display during acquisition works...
//	// BEFORE ACQUISITION
//	// Before the acquisition starts, the users prefered window settings must be prepared.
//	// The acq window panel is read : which Traces(Adc,PoN..) are to be shown in which range (Frame, Sweep, Primary,Result) and in which mode (current, many=superimposed).
//	// These settings are combined in a data structure  'Curves'  which contains the complete information how the traces display should look like.
//	// DURING ACQUISITION
//	// The display routine receives only  the region on screen where to draw and which data are valid. The latter is encoded in the frame and  the sweep number of the data .
//	// Positive sweep numbers means the valid display range is one sweep, whereas a sweep number -1 means the data range that can be displayed is a frame.
//	//  From frame and sweep number the display routine itself computes data offset and data points to be drawn. 
//	//  The  'Curves'  containing the users prefered display settings is broken and trace, mode and range are extracted  and  compared against the currently valid data range,  if appropriate then data are drawn.
//	
	// History:
	// Major revision 2008-05...2008-06
	
#pragma rtGlobals=1							// Use modern global access method.

#include "UFCom_ListProcessing" 


//================================================================================================================================
// RANGE   new-style  (must be combined with old-style)

// old-style
//  constant		kSWEEP 		= 0,	kFRAME = 1,  kPRIM = 2, 	kRESULT = 3
//static  strconstant	lstRANGETEXT	= "Sweeps,Frames,Primary,Result,"
//static  strconstant	lstRANGENM	= "S;F;P;R"

//  new-style
constant			 kRA_DS = 0,   kRA_FRAME = 1,    kRA_LAP = 4
static    strconstant	lstRA_TEXT_ns	= "DaSct;Frames;Primary;Result;Lap;"

Function		DiacRangeSet( sFo, sWNm, nRange )
	string  	sFo, sWNm
	variable	nRange
	variable	/G		  $"root:uf:" + sFo + ":" + ksDIA + ":" + sWNm + ":Range" 	= nRange
End
	
Function		DiacRange( sFo, sWNm )
	string  	sFo, sWNm
	nvar  /Z	nRange	= $"root:uf:" + sFo + ":" + ksDIA + ":" + sWNm + ":Range" 
	if ( ! nvar_exists( nRange ) )
		variable /G	   $"root:uf:" + sFo + ":" + ksDIA + ":" + sWNm + ":Range" 	= kRA_DS// kRA_FRAME	// ass default: !!! Adjust this initial setting correspondingly in 'DiacRange()' and in  ConstructCb_XXX_Button()
	endif
	nvar  	nRange	= $"root:uf:" + sFo + ":" + ksDIA + ":" + sWNm + ":Range" 
	// 2009-04-02
//	DiacHighlightRangeButton( sWNm, nRange )
	return	nRange
End
	
Function	/S	DiacRangeNm( nRange )
	variable	nRange
	return	StringFromList( nRange, lstRA_TEXT_ns )[ 0, 0 ]	// returns 'F'  for frame  or  'B' for block
End

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

Function		DiacTrueTimeSet( sFo, sWNm, bValue )
	string  	sFo, sWNm
	variable	bValue
	variable /G $"root:uf:" + sFo + ":" + ksDIA + ":" + sWNm + ":TrueTime"  = bValue
End

Function		DiacTrueTime( sFo, sWNm )
	string  	sFo	 			// e.g.  'acq' 
	string  	sWNm
 	nvar	/Z	bTrueTime    =	$"root:uf:" + sFo + ":" + ksDIA + ":" + sWNm + ":TrueTime"
	if ( ! nvar_exists( bTrueTime ) )
		variable   /G		$"root:uf:" + sFo + ":" + ksDIA + ":" + sWNm + ":TrueTime"  = 0	// 0 is simpler to debug  ,  1  is faster to display.  
	 	nvar	bTrueTime    =	$"root:uf:" + sFo + ":" + ksDIA + ":" + sWNm + ":TrueTime"
	endif
	return	bTrueTime
	//return	nvar_exists( bTrueTime )  ?  bTrueTime  :  0	// 0 or 1 .    As this function can be called before this panel SetVariable  control has been constructed  the existance of the global must be checked.
End


//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// The acquisition display window name 

 Function	/S	DiacWnd( w )
	variable	w
	return	"AW" + num2str( w ) 
End

 Function		DiacWnd2Nr( sWNm )
	string  	sWNm
	return	str2num( sWNm[ strlen( "AW" ), inf ] ) 
End

//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//  The Diac  - Display Acq Window list

// 2009-06-25
// strconstant	ksDIA			= "dia"		// subfolder below  'root:uf:acq'  to hold the windows subfolders which hold the windows / ??? lists
static constant	kDIA_WNDMAX	= 6

Function	/S	LstDiacWnd( sFo )
// returns quadruple list containing all acquisition windows names, window locations, curves and curve items
	string  	sFo
	string  	lst		= ""
	variable	wn, wCnt	= DiacWndCnt()
	for ( wn = 0; wn < wCnt; wn += 1 )
		lst	+= DiacWnd( wn ) + UFCom_ksSEP_TAB
	endfor
	return	lst
End


//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function		fDiacWndAdd( s ) 
	struct	WMButtonAction	&s
 	string  	sFo	 	= StringFromList( 2, s.ctrlName, "_" )			// e.g.  'root_uf_acq_pul_xxx'  -> 'acq' 
	string  	sSubFoIni	=  "Scrip"
	variable	w//, nWnd 	=  ItemsInList( lst, UFCom_ksSEP_TAB )

	svar	/Z	lllstIO			= $"root:uf:" + sFo + ":" + "lllstIO" 	
	if ( ! svar_exists( lllstIO ) )
		printf "Warning: Must load script before attempting to add an acquisition display window.\r"
		return 	UFCom_kNOTFOUND 
	endif
			
	// Loop upwards through all possible windows, find the first _missing_ window and create it. 
	for ( w = 0; w < kDIA_WNDMAX; w += 1 )
		string  	sWNm	= DiacWnd( w )
		if ( WinType( sWNm ) != UFCom_WT_GRAPH )				// window can be created as it does not exist
			UFCom_PossiblyCreateFolder( "root:uf:" + sFo + ":" + ksDIA  + ":" + sWNm )	// Create the window subfolder
			// Create the windows at staggered default postion 
			variable	left, top, right, bot
			DiacWindowPositionDefault( w, left, top, right, bot )			// staggers the windows (references are changed)
			DiacPossiblyCreateWindow( sWNm,  left, top, right, bot )
			DiacUpdateFile( sFo, sSubFoIni, LstDiac() )							// add wnd: update Wnd

			DiacWndAddTraces( sFo, sSubFoIni, w, sWNm, lllstIO )
			break
		endif
	endfor

	 printf "\t\tfDiacWndAdd()\ts.ctrlName: '%s'  \tsFo: '%s'    s.win: '%s'  sets  LstDiacWnd: '%s'    AllDiacTraces:'%s'    llstIO:'%s'  \r", s.ctrlName, sFo, s.win, LstDiacWnd( sFo ), LstIOAllDacAllAdc2Dim( sFo ), lllstIO
End


static Function		DiacWndAddTraces( sFo, sSubFo, wn, sWNm, lllstIO )
	string  	sFo, sSubFo, sWNm, lllstIO
	variable	wn
 	string  	sPn	 	= ksFPUL						// 'pul' 
	string   	sChan	= "",  llllstDiac = ""

	// Feed the Display acq 'dia' popupmenu initially with traces from which the user may select which to display and which to hide. The format assumed is a double list with seps ';' and ',' .
	// Extract only Dac and Adc channels from  'llstIO' ,  ignore  Dig  and SV 
	// Design issue:  Fill the newly created window with all possible Dac and Adc channels  (those defined in the script -> lllstIO). The user must remove unwanted traces later.
	//   Alternatively one could supply only 1 trace or leave the window empty initially.  In this case the user would have to add the desired traces later. 
	variable	nio, cio, cioCnt
	string  	sIOType, sIONr, sIONm, sUnits, lstAllDiacTraces = ""
	llllstDiac = LstDiac(); 	UFCom_DisplayMultipleList( "DiacWndAddTraces init",  llllstDiac, DiacSeps(), 31 )  
	//for ( nio = kSC_DAC; nio <= kSC_DIG; nio += 1 )			// Loop through  'Dac' , 'Adc'  and  'Dig'
	for ( nio = kSC_DAC; nio <= kSC_ADC; nio += 1 )				// Loop only through  'Dac' and 'Adc'

		sIOType	= StringFromList( nio, klstSC_NIO )

		cioCnt	= UFPE_ioChanCnt( lllstIO, nio )	
		for ( cio = 0; cio < cioCnt; cio += 1 )
			sIONr		 =  UFPE_ioItem( lllstIO, nio, cio, kSC_IO_CHAN )
			sIONm		 =  UFPE_ioItem( lllstIO, nio, cio, kSC_IO_NAME )
			sUnits		 =  UFPE_ioItem( lllstIO, nio, cio, kSC_IO_UNIT  )	

			sChan		 =  sIOType + sIONr
			lstAllDiacTraces	+= sChan + UFPE_ksDI_CHANSEP	// ','

			// Assume some default values
			variable bAutoscl	= 1			// should be 1 only for Dacs and else 0 
			variable YZoom		= 1
			variable YOfs		= 0
			variable Gain		=  str2num( UFPE_ioItem( lllstIO, nio, cio, kSC_IO_GAIN  )	)	 ;	Gain = numType( Gain ) == UFCom_kNUMTYPE_NAN  ?  1  :  Gain 	

			//llllstDiac = LstDiac(); 	UFCom_DisplayMultipleList( "DiacWndAddTraces  cio -",  llllstDiacc, DiacSeps(), 31 )  
			llllstDiac	= DiacTraceAdd( sFo, sWNm, wn, nio, cio, sIOType, sIONr, sIONm, sUnits, bAutoscl, YOfs, YZoom, Gain )

			// llllstDiac = LstDiac(); 	UFCom_DisplayMultipleList( "DiacWndAddTraces  cio +",  llllstDiac, DiacSeps(), 31 )  
		endfor

		lstAllDiacTraces	+=  UFPE_ksDI_TYPESEP	// ";"

	endfor
	llllstDiac = LstDiac(); 	UFCom_DisplayMultipleList( "DiacWndAddTraces exit",  llllstDiac, DiacSeps(), 31 )  
	DiacUpdateFile( sFo, sSubFo, llllstDiac )						// add trc: update Trc

	DiacDisplayChannels( sFo, sPn, sWNm, lstAllDiacTraces )
End
	

static Function		DiacPossiblyCreateWindow( sWNm, left, top, right, bot )
	string  	sWNm
	variable	left, top, right, bot
	string  	sFo	= ksACQ
	variable	wn	= DiacWnd2Nr( sWNm )
	if ( WinType( sWNm ) != UFCom_WT_GRAPH )				// Create window only if it does not exist yet.  Otherwise Igor would would create a window with an auto-incremented name which we don't want.
		Display /N=$sWNm /K=1	/W=(left, top, right, bot)
		SetWindow  $sWNm   hook( hFP_DiacWndHook ) = fFP_DiacWndHook	
		printf "\t\tDiacPossiblyCreateWindow()  \tCreating \tsWNm:'%s'\tw:%2d\tleft:\t%d\ttop:\t%d\tright:\t%d\tbot:\t%d\t \r", sWNm, wn, left, top, right, bot
	else	
		MoveWindow/W=$sWNm  left, top, right, bot
		printf "\t\tDiacPossiblyCreateWindow()  \tMoving  \tsWNm:'%s'\tw:%2d\tleft:\t%d\ttop:\t%d\tright:\t%d\tbot:\t%d\t \r", sWNm, wn, left, top, right, bot
	endif
	DiacWindowPositionSet( sFo, sWNm, wn, Left, Top, Right, Bot )

	//UFCom_DisplayMultipleList( "llllstDiac  DPCW",  LstDiac(), DiacSeps(), 31 )  
//	DiacUpdateFile( sFo, sSubFo, LstDiac() )						// add wnd: update Wnd
End


//==================================================================================================================================

static constant		cAXISMARGIN		= .15			// space at the right plot area border for second, third...  Dac stimulus axis all of which can have different scales
static constant		cDGOWIDTH		= .04			// width of 1 Digout trace refered to whole window height
static constant		cDECIMATIONLIMIT = 20000		// 10000 to 50000 works well for IVK: 525000pts (135000 without blank), 15 frames, 5 sweeps
//static constant		cMINIMUMSTEP	= 6			// as decimation has a considerable overhead  smaller steps make no sense

static constant		cLINES = 0, cLINESandMARKERS = 4, cCITYSCAPE	= 6


static constant		kFP_MARG				= .15								// space to the left of the Y scales for displaying the label (=Trace name) in percent of the data area width
//static constant     	kFP_MARG				= .1								// space between  Y scales in percent of the data area width


//==================================================================================================================================
//  Display acq:  The Acquisition window hook function.  It reacts on the user actions like killing or resizing the window  or on the user selecting traces and do something with them e.g. colorise, manual scale etc. 

Function 		fFP_DiacWndHook( s )
// Detects and reacts on double clicks and keystrokes without executing  Igor's default double click actions. Parts of the code are taken from WM 'Percentile and Box Plot.ipf'
	struct	WMWinHookStruct &s 			// test ? static 
	string  	sTxt 			= ""
	variable	returnVal		= 0
	string  	sKey			= num2char( s.keycode )
	string  	sFo			= ksACQ
	string  	sSubFoIni		=  "Scrip"
	string  	sChan = "", sChNm = "",  llllstDiac  = ""
	string  	sWNm		= s.winname
	variable	wn			= DiacWnd2Nr( sWNm )
	string  	sPn			= ksFPUL


	if ( s.eventCode	!= UFCom_WHK_mousemoved )
		//  printf "\t\tfFP_DiacWndHook(a)\t\tEvntCode:%2d\t%s\tmod:%2d\t'%s'\t'%s' =%3d \r ", s.eventCode, UFCom_pd( s.eventName, 10 ), s.eventMod, sWNm,  sKey, s.keycode
	endif


	if ( s.eventCode	== UFCom_WHK_kill )
		//  Catch the kill event as we must also remove the killed window from the acq window list
		// Note: The initialisation of DiAc windows is done differently than it is done for most other windows
		// 1. Kill event does not have to switch a panel buttons appearance.   2. There is a dedicated framework in  UF_AcqDispCurves6.ipf  (may perhaps not be required)    3. Traces are stored
		llllstDiac = LstDiac(); 	UFCom_DisplayMultipleList( "fFP_DiacWndHook( kill wnd init )",  llllstDiac, DiacSeps(), 31 )  
		DiacWndRemove( wn )
		llllstDiac = LstDiac(); 	UFCom_DisplayMultipleList( "fFP_DiacWndHook( kill wnd exit )",  llllstDiac, DiacSeps(), 31 )  
		DiacUpdateFile( sFo, sSubFoIni, LstDiac() )						// kill wnd: update Wnd

		UFCom_EraseTracesInGraph( sWNm )	
		KillDataFolder  $"root:uf:" + sFo + ":" + ksDIA + ":" + sWNm	 		// Also kill the corresponding data folder

		//PanelPulse() // no tabs: not required...
		 printf "\t\tfFP_DiacWndHook(a) \t'%s'=%3d\tec:%2d\t%s\tmod:%2d\t'%s':%d\t\t\t\t\t\t\t\t\t\t\t\t\t\tX:%4d\tY:%4d\tXPixel:%d \r ", sKey, s.keycode, s.eventCode, UFCom_pd( s.eventName, 10 ), s.eventMod, sWNm, wn, s.mouseLoc.h,  s.mouseLoc.v, 1234//nXPixel
		return 0							// 0 : allow further processing by Igor or other hooks ,  1 : prevent any additional processing 
	endif

	if ( s.eventCode	== UFCom_WHK_resize  )
		if ( DiacControlBar( wn ) )
			AdjustCbSliderYOfsToWnd( sWNm )
		endif
		return 0															// 0 : allow further processing by Igor or other hooks ,  1 : prevent any additional processing 
	endif

	if ( s.eventCode	== UFCom_WHK_deactivate )
		// Note: The initialisation of DiAc windows is done differently than it is done for most other windows
		// 1. Kill event does not have to switch a panel buttons appearance.   2. There is a dedicated framework in  UF_AcqDispCurves6.ipf  (may perhaps not be required)  3. Traces are stored   4. The slider in the controlbar must be adjusted on resize
		GetWindow $sWNm wsize												// window dimensions in points
		DiacWindowPositionSet( sFo, sWNm, wn, V_Left,  V_Top,  V_Right, V_Bottom )
		DiacUpdateFile( sFo, sSubFoIni, LstDiac() )						// move wnd: update Wnd
		 printf "\t\tfFP_DiacWndHook(c) \t'%s'=%3d\tec:%2d\t%s\tmod:%2d\t'%s':%d\t\t\t\t\t\t\t\twPo:%4d\t%4d\t%4d\t%4d \r ", sKey, s.keycode, s.eventCode, UFCom_pd( s.eventName, 10 ), s.eventMod, sWNm, wn, V_Left,  V_Top,  V_Right, V_Bottom
		return 0															// 0 : allow further processing by Igor or other hooks ,  1 : prevent any additional processing 
	endif
		


	// Tricky and not fully understood: the mouse down event is sometimes swallowed  and the values (sometimes?) are updated only after the hook function is left
	// if ( s.eventCode	!= UFCom_WHK_mousemoved )//  &&  s.eventCode != UFCom_WHK_modified )	// we exclude the 'modified' event as each change of the data segment triggers this event many times per second
	 if ( s.eventCode	== UFCom_WHK_mouseup )
		//variable	ch = -1,  su = -1
		variable	nio = -1,   cio = -1 
// SHOULD BE 080709  superseded by TraceFromPixel  like in StimDisp6
		if ( ! FP_WhichChannelSubChannel( sWNm, s.mouseLoc.v , nio, cio, s.eventName ) )	// if found  the displayed channel  ch  and its subchannel  su  are passed back, if not  0  is returned (could alternatively set nio/cio to UFCom_kNotFound...)
			return 	0													// 0 : allow further processing by Igor or other hooks ,  1 : prevent any additional processing 
		endif
// 2009-04-04
	DiacWindowNioSet( sFo, sWNm, wn, nio )
	DiacWindowCioSet( sFo, sWNm, wn, cio )
	DiacUpdateFile( sFo, sSubFoIni, LstDiac() )						// remove trc: update Trc
		string  	sAxisNm	= DiacTraceChannel( s.winname, wn, nio, cio ) 				// assumption = sChan  e.g 'adc2'
		variable	CursX	= numType( s.mouseLoc.h ) != UFCom_kNUMTYPE_NAN ? AxisValFromPixel( s.winName , "bottom", s.mouseLoc.h  ) : 0
		variable	CursY	= numType( s.mouseLoc.h ) != UFCom_kNUMTYPE_NAN ? AxisValFromPixel( s.winName , sAxisNm, s.mouseLoc.v  ) : 0
		 printf "\t\tfFP_DiacWndHook(d) \t'%s'=%3d\tec:%2d\t%s\tmod:%2d:\t'%s':%d\tni:%d\tci:%d\t%s\t\t\t\t\t\t\t\t\tX:%4d\tY:%4d\tx:%8.3lf\ty:%7.1lf\t \r ", sKey, s.keycode, s.eventCode, UFCom_pd( s.eventName, 10 ), s.eventMod, sWNm, wn, nio, cio, UFCom_pd(sAxisNm,7), s.mouseLoc.h,  s.mouseLoc.v, CursX, CursY
	endif


	//  ToManual:   NORMAL  CLICKS : Create Controlbar
	if (  s.eventCode == UFCom_WHK_mouseup  &&  ! ( s.eventMod & UFCom_kMD_SHIFT ) &&  ! ( s.eventMod & UFCom_kMD_ALT ) &&  ! ( s.eventMod & UFCom_kMD_CTRL ) ) 
		sTxt = "MouseUp"
		//if ( 1  ||  ! DiacControlBar( w ) )
			variable	bShow	= UFCom_TRUE
// 2009-04-03
			DiacWindowCBarShowSet( sFo, sWNm, wn, bShow )
			CreateControlBarInAcqWnd_6(  sWNm, wn, nio, cio, bShow )	// use nio, cio from above (could also retrieve values...)
		//endif
	endif

	//  ToManual:   SHIFT  CLICKS :  Remove Trace/Curve from  llllstDiac  and from window  and  from  llllstDiac
	if (  s.eventCode == UFCom_WHK_mouseup  &&  ( s.eventMod & UFCom_kMD_SHIFT ) &&  ! ( s.eventMod & UFCom_kMD_ALT ) &&  ! ( s.eventMod & UFCom_kMD_CTRL ) ) 
		sTxt 		= "MouseUp"
		llllstDiac 	= LstDiac(); 		UFCom_DisplayMultipleList( "fFP_DiacWndHook( kill crv init )",  llllstDiac, DiacSeps(), 31 )  
		
		string  	sIOType	= DiacTraceTyp( sWNm, wn, nio, cio )
		string  	sIONr	= DiacTraceNr( sWNm, wn, nio, cio )		// determine channel name _before_ 'DiacTraceRemove()' below
		string  	sFoTrcNm	= DiacqFoTrcNm( sFo, sWNm, sIOType, sIONr )
		string  	sTNm	= DiacqTrcNm( sIOType, sIONr )
		RemoveFromGraph /Z /W=$s.winname, $sTNm			
		Killwaves 						$sFoTrcNm

		DiacTraceRemove( wn, nio, cio )  				 //  ??? todo tothink   is this cio  the same in llllstIO  and  llllstDiac / curves
		llllstDiac 	= LstDiac(); 		UFCom_DisplayMultipleList( "fFP_DiacWndHook( kill crv exit )",  llllstDiac, DiacSeps(), 31 )  
		DiacUpdateFile( sFo, sSubFoIni, LstDiac() )						// remove trc: update Trc
		string  	lstSomeWaves	= DiacqListAdcAndDacDim2( wn )
		DiacDisplayChannels( sFo, sPn, sWNm, lstSomeWaves )
	endif

//	//  ToManual:  SHIFT CLICKS  into  CORRELATION: Set the Critical Correlation Coefficient to the clicked Y value  and Rerecognise the entire wave with the new value.  
//	// User must Shift Click into the  CorrCoef band as RCrit value is taken from there. 
//	if (  s.eventCode == UFCom_WHK_mouseup  &&   ( s.eventMod & UFCom_kMD_SHIFT ) &&  ! ( s.eventMod & UFCom_kMD_ALT ) &&  ! ( s.eventMod & UFCom_kMD_CTRL ) ) 
//	
//	//  ToManual:  CONTROL CLICKS   and    CONTROL  SHIFT CLICKS   into  DATA :  Add just this single clicked Mini    or   this pair of overlapping minis   to the Detected Minis Data base  manually  
//	// User must Control Click into the  _Data_  band   AND  must previously have set up a marquee
//	if (  s.eventCode == UFCom_WHK_mouseup  &&  ! ( s.eventMod & UFCom_kMD_ALT ) &&   ( s.eventMod & UFCom_kMD_CTRL ) ) 				// ignore  SHIFT state  here
//
//	//  KEYSTROKE  PROCESSING
//	// For keyboard strokes we can only use the SHIFT modifier,  ALT interferes with Igor's menu, CTRL with Igor's shortcuts. Mouse CTRL ALT is OK.
//	if ( s.eventCode == UFCom_WHK_keyboard ) 
//		MD_ExecuteActions( s.keycode )
//	endif
	
	return returnVal							// 0 : allow further processing by Igor or other hooks ,  1 : prevent any additional processing 
End


//==========================================================================================================================================
//
Function	/S	DiacqListAdcAndDacDim2( wn )
// returns double list containing all  Adcs and Dacs   e.g.  'Dac0,Dac2,;Adc1,Adc0,Adc7,;'
	variable	wn
	string  	sWNm	= DiacWnd( wn )
	string  	lst		= ""
	variable	nio, nioCnt, cio, cioCnt
	nioCnt	= DiacTypCnt( wn )
	for ( nio = 0; nio < nioCnt; nio += 1 )
		cioCnt	= DiacTraceCnt( wn, nio )
		for ( cio = 0; cio < cioCnt; cio += 1 )
			lst	+=  DiacTraceChannel( sWNm, wn, nio, cio ) + UFPE_ksDI_CHANSEP	// ','
		endfor
		lst 	+= UFPE_ksDI_TYPESEP	// ';'
	endfor
	return	lst
End


Function	/S	DiacqListAdcAndDacDim1( wn )
// returns  semicolon-separated list containing all  Adcs and Dacs   e.g.  'Dac0;Dac2;Adc1;'
	variable	wn
	return  	UFCom_FlattenDoubleList(  DiacqListAdcAndDacDim2(wn) , UFPE_ksDI_TYPESEP, UFPE_ksDI_CHANSEP, UFPE_ksDI_TYPESEP )	//  ;  ,  ; 
End



// 			Order is like klstSC_NIO	dac adc dig (and possibly sv)
static constant		kSC_IOSV_HT		= 2									// Numbers are arbitrary relative units, the gap between is implicitly assumed to be 1 (in code below) . FLAW: height of dig and sv can for some unknown reason not be 1 (why???)
static strconstant	klstSC_IO_HT		= "10;20;2;"							// make dac trace narrower compared to stimulus display .  Numbers are arbitrary relative units, the gap between is implicitly assumed to be 1 (in code below)


 Function		DiacDisplayChannels( sFo, sPn, sWNm, lstSomeWaves )
	string  	sFo
	string  	sPn					// the panel name  e.g. 'pul'
	string  	sWNm				// the acquisition display graph window
	string  	lstSomeWaves
	
	variable	sc 			= 0		//todo

// 2008-06-25
//	UFCom_EraseTracesInGraph( sWNm )								// Erace traces left over from a previous script..........................Erase all traces to enforce rebuilding the X axis adjusted to new number of points (could also be done in other ways...)

	 string  	lstYAxisCeiling    =    DiacDisplayAllTracesAndAxes( sFo, sPn, sWNm, lstSomeWaves, sc )// must pass points not seconds
	DiacYAxisCeilingSet( sFo, sWNm, lstYAxisCeiling )				// We store the Y axis positions so that we can later retrieve which channel/subchannel is desired when the user clicks into the graph
	 printf "\t\tDiacDisplayChannels( \tSomeWaves:\t%s\tAllWaves: \t%s...\t-> lstYAxis: '%s'  \r", UFCom_pd( lstSomeWaves, 29), UFCom_pd(  LstIOAllDacAllAdc2Dim( sFo ), 29), lstYAxisCeiling
End


static Function		DiacYAxisCeilingSet( sFo, sWNm, lstYAxisCeiling )
	string  	sFo, sWNm, lstYAxisCeiling				
	string 	 /G				$"root:uf:"  +  sFo + ":" +  ksDIA + ":" +  sWNm + ":glstYAxisCeiling"	= lstYAxisCeiling
End

static Function	/S	DiacYAxisCeiling( sFo, sWNm )
	string  	sFo, sWNm			
	svar	  /Z	glstYAxisCeiling	  = 	$"root:uf:"  +  sFo + ":" +  ksDIA + ":" +  sWNm + ":glstYAxisCeiling"
	if ( ! svar_exists( glstYAxisCeiling ) ) 
		string  /G				$"root:uf:"  +  sFo + ":" +  ksDIA + ":" +  sWNm + ":glstYAxisCeiling"	= ""
		svar	glstYAxisCeiling	  = 	$"root:uf:"  +  sFo + ":" +  ksDIA + ":" +  sWNm + ":glstYAxisCeiling"
	endif
	return	glstYAxisCeiling		
End



static Function	/S	DiacDisplayAllTracesAndAxes( sFo, sPn, sWNm, lstSomeWaves, sc )
// Displays the waves and from 'lstSomeWaves'  in the x range  'ptBeg, ptEnd'  and  constructs all required axes.
// 'lstSomeWaves' contains all data channels including subchannels for the results.
// Collect and offer all used dig, dac and adc channels.  Let the user selectively turn them off or on  (e.p popupmenu) and  store the 'on' channels in a double string list 'llstDispChans' .
// Loop through  'llstDispChans' and construct the partial axes on the left.
// Loop through  'llstDispChans' and display the data on their appropriate axis.
// This is simple and fast as long as we do not support overlaid dacs or adcs because no right axes are required.
// Code is similar to  MiniDet code  MD_DisplayAllTracesAndAxes( sWNm, lstSomeWaves, sSep, ptBeg, ptEnd )
// Also see and possibly change the similar but reduced function  'DiacDisplayChannelsXRange()'  below
	string  	sFo, sPn, sWNm, lstSomeWaves		// double list
	variable	sc

	svar		lllstIO			= $"root:uf:" + sFo + ":" + "lllstIO" 	

	variable	decstep 		= 1// todo DiSHiRes( sFo, sPn )  ?  1  : round( max( 1, DiSDispTotalDur( sFo ) / cDECIMATIONLIMIT ) )		// decimation begins when wave points exceed this limit

	string  	lstOneIO_		= "" , sIOType	= "", sIONr	= "", lstOneIO=""
	string  	sIOUnits		= "",	 sIORgb	= ""
	string  	sAxNm 		= "" , sAxLabel	= ""	
	string  	sChan 		= ""
	string  	sWvNm 		= ""
	variable	ch, nChans	= ItemsInList( lstSomeWaves )		// usually 3 or 4 ,  'dig' , 'dac' , 'sv'  and possibly  'adc'
	variable	su, nSubs
	variable	TotalHt 		= 0, SuHt	= 0 
	variable	nRed, nGreen, nBlue
	variable	nio 
	variable	wn			= DiacWnd2Nr( sWNm )
	variable	nRange		= DiacRange( sFo, sWNm )
	
	
	
//  2009-03-25   here 
	variable	nSmpInt	 = SmpIntDacUs( sFo )
	variable	pr = 0,  bl = 0,  la = 0,  fr = 0
	variable	BegSv_, Pts, BegDisp=0
	svar		lllstTapeTimes	= $"root:uf:" + sFo + ":" + "lllstTapeTimes" 	
	svar		llstBLF		= $"root:uf:" + sFo + ":" + "llstBLF" 	
	svar		llstNewdsTimes	= $"root:uf:" + sFo + ":" + "llstNewdsTimes" 	
	if ( nRange == kRA_DS ) 
		variable gr=0 //todo_a
		UFPE_Nds_Extract( sc, pr, bl, la, fr, gr, 1, llstNewdsTimes, llstBLF, BegSv_, Pts )	// BegSv_, Pts  = here =  BegDisp, nPts   are references which are computed and passed back (TRUE TIMES)
	else
		RangeToPoints( 	sFo, pr, bl, la, fr, nRange, nSmpInt, llstBLF, lllstTapeTimes, BegSv_, Pts )	
	endif

	
	// Compute required total height for all channels and subchannels  (from lstSomeWaves, not from lllstIO) .  Compute in arbitrary units.
	for ( ch = 0; ch < nChans; ch += 1)
		nSubs	= SubCnt( ch, lstSomeWaves )
		lstOneIO_	= StringFromList( ch, lstSomeWaves )
		for ( su = 0; su < nSubs; su += 1 )
			sIOType	= UFCom_RemoveTrailingDigits( StringFromList( su,  lstOneIO_, UFPE_ksDI_CHANSEP ) )		// 'adc2'  ->  'adc'
			if ( strlen( sIOType ) ) 										// process only traces whose list entries are not empty and which should be displayed.  The list 'lstSomeWaves'  contains spaceholders for hidden traces which must be skipped here, 
				nio		= WhichListItem( sIOType, klstSC_NIO, ";", 0, 0 )
				SuHt		= str2num( StringFromList( nio, klstSC_IO_HT ) )
				SuHt		=  numType( SuHt ) == UFCom_kNUMTYPE_NAN  ?    kSC_IOSV_HT   :   SuHt						// ugly SV ..the SV wave 
				// printf "\t\tDiacDisplayAllTracesAndAxes(a)\t%s\t%s ch:%2d, nio:%2d, sIOType: \t%s\tnSubs:%2d\t SuH:%g\tllstIO:'%s'  \r",  UFCom_pd( lstSomeWaves, 49), UFCom_pd( lstOneIO_, 19),  ch, nio, UFCom_pd( sIOType, 6), nSubs,  SuHt, lllstIO
				TotalHt	+= SuHt + 1										// the gap of 1 is added always 
			endif
		endfor
	endfor

	 printf "\t\tDiacDisplayAllTracesAndAxes(b)\t%s\t chs:%2d\t\tTotHt:%3d\tdecstep:%d \tllstIO:'%s'  \r",  UFCom_pd( lstSomeWaves, 49), nChans, TotalHt, decstep, lllstIO

	// Compute for every channel/subchannel axis  min and max value  in the range 0 ... 1
	variable	YAxMin = 0, YAxMax = 0											// in the range 0 ... 1
	variable	YValMin = 0, YValMax = 0											// data values
		
	// Loop through all  VISIBLE channels and subaxes (from lstSomeWaves, not from lllstIO)  and  position them one above the other 
	string  	lstYAxisCeiling	= ""											// store the top positions of the Y axes in % of plot area.  From this the channel and subchannel is retrieved when the user clicks into a subchannel band.
	for ( ch = 0; ch < nChans; ch += 1)
		nSubs	= SubCnt( ch, lstSomeWaves )
		lstOneIO_	= StringFromList( ch, lstSomeWaves )
		for ( su = 0; su < nSubs; su += 1 )
			sIOType	= UFCom_RemoveTrailingDigits( StringFromList( su,  lstOneIO_ , UFPE_ksDI_CHANSEP ) )	// 'dac2'  ->  'dac'
			if ( strlen( sIOType ) ) 												// process only traces whose list entries are not empty and which should be displayed.  The list 'lstSomeWaves'  contains spaceholders for hidden traces which must be skipped here, 
				nio		= WhichListItem( sIOType, klstSC_NIO, ";", 0, 0 )
				SuHt		= str2num( StringFromList( nio, klstSC_IO_HT ) )
				SuHt		=  numType( SuHt ) == UFCom_kNUMTYPE_NAN  ?    kSC_IOSV_HT   :   SuHt		// ugly SV ..the SV wave 
	
				YAxMin 	 =  (ch==0  && su==0)  ?  1 / TotalHt  :  YAxMin				// the gap of 1 is added already before the first band
				YAxMax	+= SuHt / TotalHt

//			if ( nio == kSC_DIG  ||  nio == kSC_DAC  ||   nio == kSC_ADC )

				sIONr	= num2str( UFCom_TrailingDigits( StringFromList( su,  lstOneIO_ , UFPE_ksDI_CHANSEP ) ) )// from lstSomeWaves, not from lllstIO
				sIOType	= StringFromList( nio, klstSC_NIO )
				// todo_C : names could be improved....
				sChan	= sIOType + sIONr		// ass naming
				sAxLabel	= sIOType + sIONr
				sAxNm	= sIOType + sIONr//sAxNm	=  YAxNm( ch, su )

				// ??? todo tothink replace llstIO by llstCurves				  	
				lstOneIO	= StringFromList( nio, lllstIO, "~" )
				sIOUnits	= UFPE_ioItem_( lstOneIO, su, kSC_IO_UNIT )	;	sIOUnits	= SelectString( strlen( sIOUnits ), 	"", 		sIOUnits )	// retrieve script entry or supply defaults
				sIORgb	= UFPE_ioItem_( lstOneIO, su, kSC_IO_RGB  )	;	sIORgb	= SelectString( strlen( sIORgb ),  	"(0:0:0)",	sIORgb )	// retrieve script entry or supply defaults
				sIORgb	= ReplaceString( "(" , ReplaceString( ")" , sIORgb, "" ) , "" )			// ass sep  ( )
				nRed	= str2num( StringFromList( 0, sIORgb, ":" ) )						// ass sep   : 
				nGreen	= str2num( StringFromList( 1, sIORgb, ":" ) )
				nBlue	= str2num( StringFromList( 2, sIORgb, ":" ) )


				sWvNm	= DiacqFoTrcNm( sFo, sWNm, sIOType, sIONr )
				UFCom_PossiblyCreateFolder( UFCom_RemoveLastListItems( 1, sWvNm, ":" ) )			//  e.g  sWvNm = 'root:uf:dia:W0:adc'  will create folder  'root:uf:dia:W0:' 

				// Copy the first sweep of the big  Dac/Adc waves into the partial waves 'sWvNm'  which will be displayed in the acquisition display windows (initially after a script has been loaded  and then later on during acquisition)
				string  	sFoBigWv	 = WvNmOut( sFo, sIOType, sIONr, sc )
				variable	Gain		 = GainByNmForDisplay_ns( sFo, sChan )					// The user may change the AxoPatch Gain any time during acquisition

	
//		//  2009-03-25   here UNTESTED....( SHOULD BE EXECUTED ONLY ONCE....................)
//				variable	BegSv_, Pts, BegDisp=0
//				svar		lllstTapeTimes	= $"root:uf:" + sFo + ":" + "lllstTapeTimes" 	
//				svar		llstBLF		= $"root:uf:" + sFo + ":" + "llstBLF" 	
//				svar		llstNewdsTimes	= $"root:uf:" + sFo + ":" + "llstNewdsTimes" 	
//				if ( nRange == kRA_DS ) 
//					variable gr=0 //todo_a
//					UFPE_Nds_Extract( sc, pr, bl, la, fr, gr, 1, llstNewdsTimes, llstBLF, BegSv_, Pts )	// BegSv_, Pts  = here =  BegDisp, nPts   are references which are computed and passed back (TRUE TIMES)
//				else
//					RangeToPoints( 	sFo, pr, bl, la, fr, nRange, nSmpInt, llstBLF, lllstTapeTimes, BegSv_, Pts )	
//				endif

				CopyExtractedSweep1_ns( sFo, 	sWNm, sFoBigWv, 	sIOUnits, sWvNm, BegSv_, BegDisp, Pts, nSmpInt, Gain )		// pts = PtsSv = PtsDi
				print "\t\tDiacDisplayAllTracesAndAxes\tra:", nRange, "\t\tUNTESTED\t\t\tB:\t    ", BegSv_,  "\t..   ", BegSv_+Pts





	
				wave  /Z	wv	   = $sWvNm		// has been created by  'CopyExtractedSweep_ns()'  above
				if ( waveExists( wv ) && numpnts( wv ) > 1)
					 printf "\t\tDiacDisplayAllTracesAndAxes(d)\t ch:%d nio:%d ty:\t%s\tsu:%d\tSuH:%3d  %s\tlstOneIO: %s\t%s\t%s\texists:%d  pts:%g\tCh:%s \tAN:%s\tAL:%s\tUn:\t'%s'\tGn:\t%g\t decstp:%g  pnt2x:%g\r", ch,nio,sIOType,su,SuHt,sWNm,UFCom_pd(lstOneIO_,9),UFCom_pd(lstOneIO,29),UFCom_pd(sWvNm,29),waveExists(wv),numpnts(wv),sChan,sAxNm,sAxLabel,sIOUnits,Gain, decstep,pnt2x(wv,Pts/decstep)

					string  	sTNm	= DiacqTrcNm( sIOType, sIONr )
					// Avoid multiple instances #1, #2... of the same channel  (all 'nRange' e.g. frame or block have the _same_ channel name e.g. 'dac0' or 'adc2' )
					if ( ! UFCom_TraceExistsInGraph( sWNm, sTNm ) )
						AppendToGraph /W=$sWNm /L=$sAxNm /C=(nRed,nGreen,nBlue) wv			// add the entire wave even if only a small segment is to be displayed, extract the segment by adjusting the axis limits (below)
					endif
					ModifyGraph	 /W=$sWNm	mode = cCITYSCAPE								// cityscape increases drawing time appr. 3 times ! 
		
					WaveStats /Q wv; 	YValMin = V_min; YValMax = V_max							// determine data limits  /Q=quietly=non-verbose
		
					// Axis adjustments...
// 2009-04-02 test weg
					// Although it should be sufficient to set the X axis range just once per window and not once for each nio/cio  this overhead does not hurt as this code is called only very rarely when the user changes channnels
//					GetAxis	/W=$sWNm  /Q bottom
//					if ( V_Flag != 0 )															// axis does not exist: only then create a new x axis, as we do not want to overwrite existing x axis settings . 
//						SetAxis 	/W=$sWNm bottom, pnt2x( wv, 0 ), pnt2x( wv, Pts/decstep ) 			// adjust the X axis scale to the entire data range defined by nRange = block or lap
//					endif


// 2009-03-06
//					SetAxis 		/W=$sWNm			$sAxNm,	 YValMin, YValMax				// use a fixed Y axis range corresponding to the data limits,  
if (  YValMin != YValMax )	
					SetAxis 		/W=$sWNm			$sAxNm,	 YValMin, YValMax				// use a fixed Y axis range corresponding to the data limits,  
else
					SetAxis 		/W=$sWNm	/A		$sAxNm			// autoscale axis.  The axis will not adjust immediately but later on after ADC data will have been sampled
endif
					
					ModifyGraph	/W=$sWNm 	axisEnab(  $sAxNm )	= {  YAxMin, YAxMax }			// stack the Y axes vertically
					ModifyGraph	/W=$sWNm 	freePos( 	$sAxNm ) 	= { .9*kFP_MARG, kwFraction }		// X-position the stacked Y axes neatly leaving a 10% marging on the left  for Y scales and units...
					ModifyGraph	/W=$sWNm 	axisEnab(	 bottom ) 	= {  kFP_MARG, 1 }				// ... and shift the  X axis accordingly so that its left end is aligned to the  stacked Y axes (leaving a 1% margin)
					ModifyGraph	/W=$sWNm 	lblPos( 	$sAxNm )	= 80 							// move label to the left  (in points)
		
					if ( nio == kSC_DIG )
						ModifyGraph	/W=$sWNm 	axThick(	$sAxNm )	= 0,	noLabel(  $sAxNm ) =  1,	tick( $sAxNm ) = 3 	// hide axis : suppress axis, ticks 
						ModifyGraph	/W=$sWNm 	lblPos( 	$sAxNm )  = 40,	lblLatPos( $sAxNm ) = -8	// move label to the left and up (in points)
					endif	
	//				if ( nio == UFCom_kNOTFOUND )		// the SV wave
	//					ModifyGraph	/W=$sWNm 	axThick(	$sAxNm )	= 0,  noLabel( $sAxNm ) =  2, tick( $sAxNm ) = 3 	// hide axis : suppress axis, ticks and labels 
	//				endif	
		
					YAxMin	 =  YAxMax + 1 / TotalHt											// the next axis' lower end will be this axis' upper end ( plus a small margin between the stacked Y axes) 
		
					Label	/W=$sWNm  $sAxNm, "\S" + sAxLabel + SelectString( strlen( sIOUnits) , "" , " / " + sIOUnits )	// '\S'  uses smaller font
		
					lstYAxisCeiling += num2str( YAxMax ) + ";"
					 printf "\t\tDiacDisplayAllTracesAndAxes(g)\t ch:%2d/%2d\t\tsu:%2d\t\t\t%6d\t..%6d\t%s\tAxMax:%5.3lf\t-> next higher AxMin:%5.3lf\tValMin:%5.2lf\tValMax:%5.2lf\t'%s...'  \r", ch, nChans, su, BegSv_, BegSv_+pts, sAxNm, YAxMax, YAxMin, YValMin, YValMax, lstYAxisCeiling[0,100]
				else
					 printf "\t\tDiacDisplayAllTracesAndAxes(h)\t ch:%2d,  nio:%2d,  sIOType:\t%s\tSuHt:%g\tlstOneIO:\t%s\tlstOneIO_:\t%s\tsu:%2d\t'%s' >>>\t%s\texists:%d  has pnts:%g\r", ch, nio, UFCom_pd( sIOType,6),  SuHt, UFCom_pd( lstOneIO_,11),  UFCom_pd(lstOneIO,29), su, sAxNm, UFCom_pd(sWvNm,29), waveExists( wv )  ,numpnts( wv )
				endif	
//endif	// nio == kSC_xxx
	
			endif 	// strlen( sIOType) 
		endfor	// su

		lstYAxisCeiling += ksFP_SEP

	endfor	// channels

	return	lstYAxisCeiling
End


Function		DiacDisplayChannelsXRange_( sFo, sPn, sWNm )
	string  	sFo
	string  	sPn					// the panel name  e.g. 'pul'
	string  	sWNm				// the acquisition display graph window
	variable	wn			= DiacWnd2Nr( sWNm )
	string  	lstSomeWaves	= DiacqListAdcAndDacDim2( wn )
	DiacDisplayChannelsXRange( ksACQ, ksFPUL, sWNm, lstSomeWaves )
End


Function		DiacDisplayChannelsXRange( sFo, sPn, sWNm, lstSomeWaves )
// Computes the waves from 'lstSomeWaves'  in the X range,  'lstSomeWaves' contains all data channels including subchannels for the results.
// Reduced version of 'DiacDisplayAllTracesAndAxes()'  but very similar.  The  Y  axis are completely ignored here (-> no Y-autoscaling if the X range is changed)
// SHOULD BE INTEGRATED  INTO  'DiacDisplayAllTracesAndAxes()'  to avoid doubling of code......
	string  	sFo
	string  	sPn					// the panel name  e.g. 'pul'
	string  	sWNm				// the acquisition display graph window
	string  	lstSomeWaves			// double list
	variable	sc 			= 0		// todo_c

	svar		lllstIO			= $"root:uf:" + sFo + ":" + "lllstIO" 	
	svar		lllstPoN		= $"root:uf:" + sFo + ":" + "lllstPoN" 	

	variable	decstep 		= 1		// todo DiSHiRes( sFo, sPn )  ?  1  : round( max( 1, DiSDispTotalDur( sFo ) / cDECIMATIONLIMIT ) )		// decimation begins when wave points exceed this limit

	string  	lstOneIO_		= "",   sIOType = "",   sIONr = "",   lstOneIO = "",   sIOUnits = "",   sChan = "",   sWvNm = ""
	variable	ch, nChans	= ItemsInList( lstSomeWaves )		// usually 3 or 4 ,  'dig' , 'dac' , 'sv'  and possibly  'adc'
	variable	nio, su, nSubs
	variable	wn			= DiacWnd2Nr( sWNm )
	variable	nRange		= DiacRange( sFo, sWNm )
		
	// Loop through all  VISIBLE channels and subaxes (from lstSomeWaves, not from lllstIO)  and  position them one above the other 
	for ( ch = 0; ch < nChans; ch += 1)
		nSubs	= SubCnt( ch, lstSomeWaves )
		lstOneIO_	= StringFromList( ch, lstSomeWaves )
		for ( su = 0; su < nSubs; su += 1 )
			sIOType	= UFCom_RemoveTrailingDigits( StringFromList( su,  lstOneIO_ , UFPE_ksDI_CHANSEP ) )		// 'dac2'  ->  'dac'		//todo_c  hide implementation, hide UFPE_ksDI_CHANSEP
			if ( strlen( sIOType ) ) 													// process only traces whose list entries are not empty and which should be displayed.  The list 'lstSomeWaves'  contains spaceholders for hidden traces which must be skipped here, 
				nio		= WhichListItem( sIOType, klstSC_NIO, ";", 0, 0 )
				sIONr	= num2str( UFCom_TrailingDigits( StringFromList( su,  lstOneIO_ , UFPE_ksDI_CHANSEP ) ) )// from lstSomeWaves, not from lllstIO
				sIOType	= StringFromList( nio, klstSC_NIO )
				sChan	= sIOType + sIONr											// ass naming

				lstOneIO	= StringFromList( nio, lllstIO, "~" )
				sIOUnits	= UFPE_ioItem_( lstOneIO, su, kSC_IO_UNIT ) ;	sIOUnits	= SelectString( strlen( sIOUnits ), 	"",  sIOUnits )	// retrieve script entry or supply defaults

				sWvNm	= DiacqFoTrcNm( sFo, sWNm, sIOType, sIONr )
				UFCom_PossiblyCreateFolder( UFCom_RemoveLastListItems( 1, sWvNm, ":" ) )		//  e.g  sWvNm = 'root:uf:dia:W0:adc'  will create folder  'root:uf:dia:W0:' 

				// Copy the first sweep of the big  Dac/Adc waves into the partial waves 'sWvNm'  which will be displayed in the acquisition display windows (initially after a script has been loaded  and then later on during acquisition)

				variable	pr = 0,  bl = 0,  la = 0,  fr = 0,  gr = 0, sw = 0 
// 2009-03-31...
				nvar	/Z 	pr_	= $"root:uf:" + sFo + ":stim:igLastProt"
				nvar	/Z	bl_	= $"root:uf:" + sFo + ":stim:igLastB"
				nvar	/Z	la_	= $"root:uf:" + sFo + ":stim:igLastLap"
				nvar	/Z	fr_	= $"root:uf:" + sFo + ":stim:igLastFrm"
				nvar	/Z	gr_	= $"root:uf:" + sFo + ":stim:igLastGrp"
				nvar	/Z	sw_	= $"root:uf:" + sFo + ":stim:igLastSwp"	// unused
				pr	= nvar_exists( pr_ )	?  pr_  :  0
				bl	= nvar_exists( bl_ )	?  bl_  :  0
				la	= nvar_exists( la_ )	?  la_  :  0
				fr	= nvar_exists( fr_ )	?  fr_   :  0
				gr	= nvar_exists( gr_ )	?  gr_  :  0
				sw	= nvar_exists( sw_ )	?  sw_  :  0
//...2009-03-31
				variable	nSmpInt	 = SmpIntDacUs( sFo )
				string  	sFoBigWv	 = WvNmOut( sFo, sIOType, sIONr, sc )
				variable	Gain		 = GainByNmForDisplay_ns( sFo, sChan )					// The user may change the AxoPatch Gain any time during acquisition

				variable	BegSv_, Pts
				variable	BegDisp = 0
				svar		lllstTapeTimes	= $"root:uf:" + sFo + ":" + "lllstTapeTimes" 	
				svar		llstBLF		= $"root:uf:" + sFo + ":" + "llstBLF" 	
				svar		llstNewdsTimes	= $"root:uf:" + sFo + ":" + "llstNewdsTimes" 	

				if ( nRange == kRA_DS ) 
					UFPE_Nds_Extract( sc, pr, bl, la, fr, gr, 1, llstNewdsTimes, llstBLF, BegDisp, Pts )	// BegSv_, Pts  = here =  BegDisp, nPts   are references which are computed and passed back (TRUE TIMES)
					variable , BegPt, nPtsSv
					UFPE_Grp_Extract( sc, pr, bl, la, fr, gr, sw, 1, lllstPoN, llstBLF, BegSv_, nPtsSv )								//  For WriteDataSaction() and ComputePon().  BegPt,   nPtsSv are references which are computed and passed back
				else
					RangeToPoints( 	sFo, pr, bl, la, fr, nRange, nSmpInt, llstBLF, lllstTapeTimes, BegSv_, Pts )	
				endif

// 2009-03-31c  gn
//				UFPE_Nds_Extract( sc, pr, bl, la, fr, gr, 1, llstNewdsTimes, llstBLF, BegSv_, Pts )	// BegSv_, Pts  = here =  BegDisp, nPts   are references which are computed and passed back (TRUE TIMES)
//				variable	BegDisp = BegSv_

// 2009-03-31alt does not react correctly on Advance during acq
//				if ( nRange == kRA_DS ) 
//					UFPE_Nds_Extract( sc, pr, bl, la, fr, gr, 1, llstNewdsTimes, llstBLF, BegSv_, Pts )	// BegSv_, Pts  = here =  BegDisp, nPts   are references which are computed and passed back (TRUE TIMES)
//				else
//					RangeToPoints( 	sFo, pr, bl, la, fr, nRange, nSmpInt, llstBLF, lllstTapeTimes, BegSv_, Pts )	
//				endif
//				CopyExtractedSweep1_ns( sFo, 	sWNm, sFoBigWv, 	sIOUnits, sWvNm, BegSv_, BegDisp, Pts, nSmpInt, Gain )	// pts = PtsSv = PtsDi 

// test 
//variable	tmp = BegSv_; BegDisp=BegSv_; BegSv_=0

				CopyExtractedSweep1_ns( sFo, 	sWNm, sFoBigWv, 	sIOUnits, sWvNm, BegSv_, BegDisp, Pts, nSmpInt, Gain )	// pts = PtsSv = PtsDi 
				printf "\t\t\t\t\tDiacDisplayChannels\tra:%d\t\tp:%d b:%d l:%d f:%d g:%d\t\tB:\t%10.0lf\t..%9.0lf\t\r", nRange, pr, bl, la, fr, gr, BegSv_,  BegSv_+Pts
	
			endif 	// strlen( sIOType) 
		endfor	// su
	endfor	// channels
End



//// SHOULD BE INCORPORATED
//
////static Function 		MyDecimate1( wSource, sDestName, step, XPos, bKeepMinMaxInDecimation, nStartPt, nEndPt )
//////  The code has been taken from the procedure file: "C:Programme:WaveMetrics:Igor Pro Folder:WaveMetrics Procedures:Analysis:Decimation.ipf"
//////  This decimation function is adequate for stimulus or digout as amplitude is maintained independently of decimation 
////	wave 	wSource
////	string 	sDestName				// String contains name of dest which must already exist
////	variable 	step
////	variable	bKeepMinMaxInDecimation	// UFCom_TRUE : adequate for stimulus or digout as amplitude is maintained independently of decimation 
////	variable 	XPos						// ignored..........1 : X's are at left edge of decimation window (original FDecimate behavior),   2 : X's are in the middle;   3 : X's are at right edge
////	variable 	nStartPt, nEndPt 
////
////	XPos -= 1
////	wave 	dw 		= $sDestName						// Make compiler understand the next line as a wave assignment
////
////	variable	pt, nTargetPt = trunc( nStartPt / step )				// keep minimum and maximum within the interval
////	if ( ! bKeepMinMaxInDecimation )						
////		for ( pt = nStartPt; pt <= nEndPt -  step; pt +=  step, nTargetPt += 1 )
////			waveStats  /Q /R=[ pt, pt + step - 1]	wSource	
////			dw[ nTargetPt    ]	= V_avg	
////		endfor
////	else
////		for ( pt = nStartPt; pt <= nEndPt ; pt += 2 * step, nTargetPt += 2 )		// pt <= nEndPt  must perhaps be refined to avoid (uncleared) garbage spikes in the traces 
////			waveStats  /Q /R=[ pt, pt + 2 * step - 1]	wSource	
////			dw[ nTargetPt +  ( v_minLoc   > v_maxloc ) ]	= V_min	
////			dw[ nTargetPt +  ( v_maxLoc >= v_minloc ) ]	= V_max
////		endfor
////	endif
////End

//==========================================================================================================================================

static strconstant ksFP_SEP = "~"

// SHOULD BE 2008-07-09  superseded by TraceFromPixel  like in StimDisp6

Function		FP_WhichChannelSubChannel( sWNm, mouseLocV, nio, su, sEventName )
// Returns channel and subchannel when the user clicks into a graph window by evaluating the Y mouse position in relation to the position of the traces bands
	string  	sWNm, sEventName
	variable	mouseLocV
	variable	&nio, &su
	nio 		= 0
	su	 	= 0
	GetWindow $sWNm, psizeDC
	variable	YPercentGraph		= ( V_bottom - mouseLocV ) / ( V_bottom - V_top )

	string  	lstYAxisCeiling	= DiacYAxisCeiling( ksACQ, sWNm )
	variable	nNioDisp			= ItemsInList( lstYAxisCeiling, ksFP_SEP )
	// printf "\t\tFP_WhichChannelSubChannel( MouseLocV:%5d ) [%s] -> ch:%2d\tsu:%2d\t [nNioDisp:%2d]\r", mouseLocV , lstYAxisCeiling, ch, su, nNioDisp
	for ( nio = 0; nio < nNioDisp; nio += 1 )
		string  	sSubChs	= StringFromList( nio, lstYAxisCeiling, ksFP_SEP )
		variable	nSubChs	= ItemsInlist( sSubChs )
		for ( su = 0; su < nSubChs; su += 1 )
			variable	YPercentOfThisSubAxis	= str2num( StringFromList( su, sSubChs ) )
			if ( YPercentOfThisSubAxis > YPercentGraph )
				// printf "\t\tFP_WhichChannelSubChannel( \t\t\t%s\tY:%5d )\tY%%Graph: %6.3g \t?>? %6.3g Y%%OfThisSubAxis [%s] \tnio:%2d\tcio/su:%2d\t \r", UFCom_pd( sEventName, 10 ), mouseLocV , YPercentGraph, YPercentOfThisSubAxis, lstYAxisCeiling, nio, su
				return	UFCom_TRUE				// and pass back the channel and subchannel index
			endif
		endfor
	endfor		
	return	UFCom_FALSE							// for some reason the channel/subchannnel could not be retrieved (should not happen, but happens if clicking into controlbar or above uppermost trace band )
End	




static Function		SubCnt( ch, llst )
	// counts the number of subchannels for 'dig'  or 'dac'  or 'adc'
	variable	ch
	string  	llst						
	string  	lst	= StringFromList( ch, llst, UFPE_ksDI_TYPESEP )		//  ';'				
	return	SubChanCnt( lst, UFPE_ksDI_CHANSEP  )				//  ','
End

static Function		SubChanCnt( lst, sSep )
// Counts the number of subchannels for 'dig'  or 'dac'  or 'adc'  .  Also count only empty list entries which are placeholders for hidden traces.
	string  	lst, sSep						
	variable	nItems	= ItemsInList( lst, sSep )
	// printf "\t\t\tSubChanCnt( lst:\t%s\t  ,  ','  ) returns %d items \r", UFCom_pd( lst, 29), nItems
	return	nItems
End

	
//=====================================================================================================================================
//  LOADING , SAVING  and  INITIALIZING  THE  ACQUISITION  DISPLAY  CONFIGURATION

 Function		LoadDisplayCfgAcq( sFolders )
// Called whenever a script file is loaded.  Attempts to load an acquisition display config file 'DiacFile' with same name as script but with extension '.ini'  and located in a subdirectory of where the script file has been loaded from.
// When the  'DiacFile'  can not be found, it is attempted to use the current acquisition display configuration 'Curves'  if the channels used there and the channels specified in the script match.  
// Channels used in the current 'Curves' (left over from the previous script) which do not exist in the newly-loaded script are removed from 'Curves' .  In this way display configurations can be inherited.

// todo_a : must also delete these traces from graph, has formerly been done by    UFCom_EraseTracesInGraph( sWNm )			

	string		sFolders
	string		sFo		= StringFromList( 0, sFolders, ":" )			// e.g. 'acq:pul'  ->  'acq'
	string  	sSubFoIni	=  "Scrip"
	string		sIniPath	= DiacIniFile_Path( sFo, sSubFoIni, UFCom_FALSE )		// last param: Do _not_ create file if it does not exist
	//string  	sIniPath	= UFPE_ksSCRIPTS_DRIVE + UFPE_ksSCRIPTS_DIR + UFPE_ksTMP_DIR + ":" + UFCom_StripPathAndExtension( sScriptPath ) + sIndex + "." + sDISP_CONFIG_EXT		// C:UserIgor:Scripts:Tmp:XYZ.dcf
	string  	lst		= LstDiac()
	//UFCom_DisplayMultipleList( "llllstDiac  A",  lst, DiacSeps(), 31 )  
	
	// Checking the existance of the file is only required when loading/saving a separate DIA file ( VERSION 1).  In the current  VERSION 2 when loading/saving the single huge INI file this is not required as its existance is checked at program start...
	// see UF_AcqDispCurves5

// Not required in VERSION 2
//	if ( UFCom_FileExists( sIniPath ) )		
//		 printf "\r\t\tLoadDisplayCfgAcq( \t\t'%s'\t) \r\t\t\t -> user display config\t'%s'  FOUND : displaying it.. ]\r", ScriptPath( sFo ), sIniPath

		lst	= DiacIniFile_Read( sFo, sSubFoIni )	//  sIniPath is read...
		LstDiacSet( lst )

		string  	sWNm//, sWInfo
		variable	wn, WndCnt	= DiacWndCnt()
		variable	left, top, right, bot
		for ( wn = 0; wn < WndCnt; wn += 1 )
			sWNm	= DiacWnd( wn )
			UFCom_PossiblyCreateFolder( "root:uf:" + sFo + ":" + ksDIA  + ":" + sWNm )	// Create the window subfolder

			DiacWindowPosition( sWNm, wn, left, top, right, bot )
			//sWInfo	= UFCom_Ini_Section( sFo, sSubFoIni, sWNm, "Wnd" )		
			//UFCom_WndPosition_( sFo, sWInfo, left, top, right, bot )
			// 2009-04-02
			variable	nRange	= DiacWindowRange( sWNm, wn )
			variable	xShift	= DiacWindowXShift( sWNm, wn )
			variable	xZoom	= DiacWindowXZoom( sWNm, wn )
			variable	bTruetime	= DiacWindowXTrueTime( sWNm, wn )
// 2009-04-03
			variable	bCBarShow= DiacWindowCBarShow( sWNm, wn )
			printf "\t\tLoadDisplayCfgAcq( \tWindow:'%s' :  TrueTime:%d\tRange:\t%d\txShift:\t%g\txZoom:\t%g\tPos: left:%d  top:%d  rght:%d  bot:%d \r", sWNm, bTruetime, nRange, xShift, xZoom, left, top, right, bot 

			DiacPossiblyCreateWindow( sWNm, left, top, right, bot )	// or just move it

			// 2009-04-02
			DiacRangeSet( sFo, sWNm, nRange )
			AcqXAxisShiftSet( sWNm, xShift )		// ??? DiacWindowXShiftSet(   sFo, sWNm, wn, xShift )
			AcqXAxisZoomSet( sWNm, xZoom )		// ??? DiacWindowXZoomSet( sFo, sWNm, wn, xZoom )
			DiacTruetimeSet( sFo, sWNm, nRange )
			
// 2009-04-04
variable nio	= DiacWindowNio( sWNm, wn )
variable cio	= DiacWindowCio( sWNm, wn )
			CreateControlBarInAcqWnd_6(  sWNm, wn, nio, cio, bCBarShow ) 

		endfor
		for ( wn = WndCnt; wn < kDIA_WNDMAX; wn += 1 )
			sWNm	= DiacWnd( wn )
			UFCom_PossiblyKillGraph( sWNm )
		endfor
// Not required in VERSION 2
//	else
//		 printf "\r\t\tLoadDisplayCfgAcq( \t\t'%s'\t ) \r\t\t -> user display config\t'%s'  NOT FOUND ...Trying to use the current display configuration \r", ScriptPath( sFo), sIniPath
//	endif

	//UFCom_DisplayMultipleList( "llllstDiac  B",  LstDiac(), DiacSeps(), 31 )  

	variable	bDirty	= DiacAdjustCurvesToScriptChans( sFo )			// Check that all channels  referenced in the Dis Acq settings are actually contained in the IOList 'lllstIO',  remove offending ones. (The use may have changed/renamed any file)

	// Store the display configuration if it has changed because it had to be cleaned-up
	if ( bDirty )	
		 printf "\t\tLoadDisplayCfgAcq( \tWindow:'%s' :  Channels have changed :  Saving:'%s' \r", sWNm, sIniPath
		string	 	lllstDiac	= LstDiac()
		DiacUpdateFile( sFo, sSubFoIni, lllstDiac )
	endif

	// Redraw all windows
	string  	sPn			= ksFPUL
	string  	lstAllDiacTraces	= LstIOAllDacAllAdc2Dim( sFo )
	for ( wn = 0; wn < WndCnt; wn += 1 )
		sWNm		= DiacWnd( wn )
		DiacDisplayChannels( sFo, sPn, sWNm, lstAllDiacTraces )
	endfor

	UFCom_DisplayMultipleList( "llllstDiac  C",  LstDiac(), DiacSeps(), 31 )  
		
////		for ( wn = 0; wn < kDIA_WNDMAX; wn += 1 )
//// //todo update tabs...
////			DiacWndRemove( wn )						// Remove all traces/curves of this window from the data structure
////			UFCom_PossiblyKillGraph(  DiacWnd( wn ) )			// Also remove any  'Acquisition display' window so that no empty windows remain. 
////		endfor										// Note: The 'about to be killed' event will be triggered for each control in the windows control bar.
End


Function		DiacAdjustCurvesToScriptChans( sFo )
	string		sFo
	string  	llllstDiac		= LstDiac()
	variable	wn, WndCnt	= DiacWndCnt()
	string  	sMsg, sWNm, sChan = ""
	string  	lstChans		= LstChan_a()					// the linear channel list as given by the script (from lllstIO)
	variable	nio, nioCnt, cio, cioCnt, nCurves, bDirty = UFCom_FALSE
	 printf "\t\tDiacAdjustCurvesToScriptChans  \t loading  wCnt:%2d/%2d    lstChans:'%s'    llllstDiac:'%s' \r", WndCnt, kDIA_WNDMAX,  lstChans, llllstDiac

	for ( wn = 0; wn < WndCnt; wn += 1 )
		sWNm		= DiacWnd( wn )
		nCurves		= 0
		nioCnt		= DiacTypCnt( wn )					// number of trace types in the Diac structure of this window 'wn',  usually 2 (dacs and adcs)   but also 1 if there are only adc(s)  
		for ( nio = 0; nio < nioCnt; nio += 1 )
			cioCnt	= DiacTraceCnt( wn, nio )				// number dacs or adcs in the Diac structure of this window 'wn'   possibly including orphans (=channels not found in the script e.g. because the user deleted them there)
			// Remove invalid curves from the underlying display configuration data structure
			for ( cio = 0; cio < cioCnt; cio += 1 )
				sChan	= DiacTraceChannel( sWNm, wn, nio, cio ) 
				//  If the display configuration contains orphan traces (=Channels with not found in the script)  then these will automatically be removed from the display configuration file. 
				if ( WhichListItem( sChan,  lstChans, UFCom_ksSEP_TAB ) == UFCom_kNOTFOUND )
					sprintf sMsg, "The channel  '%s'  found in the display config file has no correspondence in the script [wn:%2d / %s / %s]. Cannot display. Will adjust display configuration file...", sChan, wn, lstChans, DiacWndTraces( wn )		// Happens when the user edits channels in the script and then forgets to save the display cfg
					UFCom_FoAlert( sFo, UFCom_kERR_IMPORTANT, sMsg )
					DiacTraceRemove( wn, nio, cio )
//???				RemoveFromGraph /Z /W=$sDiacWnd, $sChan
					cio 		-=  1	
					cioCnt	-=  1	
					bDirty 	 =  UFCom_TRUE// 2008-07-21 080722  080723 080724 ?????????  was UFCom_FALSE				
				else
					nCurves 	+= 1
					printf "\t\tDiacAdjustCurvesToScriptChans   \tDiacWnd '%s' : The channel  '%s'  found in the display config file has also been found in the script [wn:%2d / %s / %s]  Will display %d traces...\r", sWNm, sChan, wn, lstChans, DiacWndTraces( wn ), nCurves	
				endif		
			endfor
		endfor
		if ( nCurves == 0 )							// no curves found  in  Display Config   for  this window: remove this window		
			UFCom_PossiblyKillGraph(  sWNm )			// Remove any  'Acquisition display' window so that no empty windows remain. This ensures that Igor does not autoincrement the graph name???? 
			DiacWndRemove( wn )
			wn 		-= 1
			WndCnt	-= 1
			printf "\t\tDiacAdjustCurvesToScriptChans   \tDiacWnd '%s'  does not contain curves and will be killed..   [%s] \r", sWNm,  LstDiacWnd( sFo )
		endif	
	endfor
	return	bDirty
//	// Store the display configuration if it has changed because it had to be cleaned-up
//	if ( bDirty )	
//		 printf "\t\tDiacAdjustCurvesToScriptChans( \tWindow:'%s' :  Channels have changed :  Saving:'%s' \r", sWNm, sIniPath
//		SaveDispSettings_6( sIniPath ) 
//	endif
//
//	string  	sPn			= ksFPUL
//	string  	lstAllDiacTraces	= LstIOAllDacAllAdc2Dim( sFo )
//	for ( wn = 0; wn < WndCnt; wn += 1 )
//		sWNm		= DiacWnd( wn )
//		DiacDisplayChannels( sFo, sPn, sWNm, lstAllDiacTraces )
//	endfor
End


// no longer used
//  Function		SaveDispSettings_6( sPathFile ) 
//// store all  window / trace arrangement variables (=the display configuration lllstDiac) in 'sFile' having the extension 'DCF' 
//	string 	sPathFile
//	string	 	lllstDiac	= LstDiac()
//	 printf "\t\tSaveDispSettings_6( %s ) \r", sPathFile
//	UFCom_WriteTxtFile( sPathFile, lllstDiac )
//End	


//	//=====================================================================================================================================
//	//    DISPLAY   ACQUISITION   TRACES   ( USED DURING ACQUISITION )
//	
//	constant	 cLAG = 5		// typical values  3..10  seconds    or    1..10 % 
	

//=====================================================================================================================================
// 2009-03-24
Function		DispDuringAcq1_ns( sFo, pr, bl, lap, fr, nRange, BegPt, nPtsSv, BegDisp, nPtD )	
// works only for  ELIMINATE_BLANKS() = 2 !!!
	string  	sFo
	variable	pr, bl, lap, fr, nRange
	variable	BegPt, nPtsSv, BegDisp, nPtD 											// range  just processed by the Acquisition task 'Process()'
	nvar		gPrevBlk	= root:uf:acq:pul:svPrevBlk0000

	variable	wn,  wCnt	= DiacWndCnt()  
	variable	eb		 = ELIMINATE_BLANKS()
	for ( wn = 0; wn < wCnt; wn += 1 )	
		string  	sWNm	= DiacWnd( wn )
		variable  	nRa		= DiacRange( sFo, sWNm )				// range (e.g. data section, frame, lap)  selected for this window 'sWNm'

		if ( nRa == nRange  &&  WinType( sWNm ) == UFCom_WT_GRAPH )

			variable	sc = 0		// todo_c
			variable	nSmpInt	= SmpIntDacUs( sFo )
			variable	cio, cioCnt, nio, 	nioCnt = DiacTypCnt( wn )			// number of trace types in the Diac structure of this window 'wn',  usually 2 (dacs and adcs)   but also 1 if there are only adc(s)  
			
			for ( nio = 0; nio < nioCnt; nio += 1 )
				cioCnt	= DiacTraceCnt( wn, nio )				// number dacs or adcs in the Diac structure of this window 'wn'   possibly including orphans (=channels not found in the script e.g. because the user deleted them there)
				for ( cio = 0; cio < cioCnt; cio += 1 )
					string 	sIOTyp = "",  sIONr = "",   sNm = "",   sUnits = ""
					string  	sFoBigWv = "",  sTrcDisp = ""
					variable	bAutoScl, YOfs, YZoom
				
					DiacTraceExtract( sWNm, wn, nio, cio, sIOTyp, sIONr, sNm, sUnits, bAutoscl, YOfs, YZoom  )	//  wn, nio, cio are input parameters, the rest are output parameters which are changed
					sTrcDisp 	= DiacqFoTrcNm( sFo, sWNm, sIOTyp, sIONr )							// the wave 'sTrcDisp' contains the data segment from 'sChan' which is currently to be displayed, the folder name contains the window		
		
					if (  waveExists( $sTrcDisp )  )												// this window 'wn'  contains this Dac/Adc trace  'sTrcDisp'  (not all windows contain all traces)
						sFoBigWv	=  WvNmOut( sFo, sIOTyp, sIONr, sc )
					
						if (  waveExists( $sFoBigWv )  )
							string 	sChan 	= sIOTyp + sIONr								// ass naming
							variable	Gain		= GainByNmForDisplay_ns( sFo, sChan )				// The user may change the AxoPatch Gain any time during acquisition
// 2009-03-25 ???
							variable	Pts		= nPtsSv		// 2009-03-25    nPtsSv  or  nPtD
							CopyExtractedSweep1_ns( sFo, sWNm, sFoBigWv, sUnits, sTrcDisp, BegPt, BegDisp, Pts,   nSmpInt, Gain )	// We compute the new trace i.e. we update the data in 'sTrcDisp'  no matter whether we actually do 'AppendToGraph' below .
						endif
						// printf "\t\t\t\t\t\tDispDuringAcq1_ns(2)\t\t\t\t    wn:%d\tp:%d b:%d l:%d f:%d     \tnio:%2d\tcio:%2d\t%s\tpts:%6d\tZm:\t%7.2lf\tOs:\t%7.2lf\tGn:\t%7.1lf\t'%s' \tSI:%3d\t \r", wn, pr, bl, lap, fr, nio,cio, UFCom_pd(sFoBigWv,25),  Pts, yZoom, YOfs, Gain,sChan, nSmpInt
					endif
				endfor	
			endfor	
			// printf "\t\t\t\t\tDispDuringAcq1_ns \tr:%d,%d\t\tp:%d b:%d l:%d f:%d  \t\t\tB:\t%10.0lf\t..%9.0lf\tPtD:\t%10.0lf\tDis_:\t%10.0lf\t\t\twn:%d/%d \r", nRa, nRange, pr, bl, lap, fr,  BegPt, BegPt + nPtsSv, nPtD, BegDisp, wn, wCnt
		endif
	endfor
	gPrevBlk  = bl
End

static   Function		CopyExtractedSweep1_ns( sFo, sWNm, sFoBigWv, sUnits, sTrcDisp, BegSv, BegDisp, nPts, nSmpInt, Gain )
// do not draw all points of wave but only 'nDrawPts' by  going in steps through the original wave: this speeds things up much  but  looses a little display fidelity
	string		sFo, sWNm, sFoBigWv, sUnits, sTrcDisp
	variable	BegSv, nPts
	variable	BegDisp													// BegDisp is required to shift the time scale (=another  X offset)  when 'TrueTime' is checked
	variable	nSmpInt, Gain			
	wave	wOrgData	 = $sFoBigWv										// must exist: existance must have been checked before...

	variable	xShift, xZoom												// the user settings 'Advance/Reverse'  and  'Compress/XZoom' in the graph control panel
	variable	XShiftSecs= 0												// the shift of the time scale (=the entire  X offset) including the effects of 'TrueTime' and 'Advance/Reverse'
	variable	UserShift	= 0												// UserShift  is the X offset possibly introduced by the 'Advance'  and 'Reverse' buttons
// 2009-03-30a
	xShift	= AcqXAxisShift( sWNm )								
	xZoom	= AcqXAxisZoom( sWNm )									
	nPts		= nPts / xZoom
	UserShift	= xShift * nPts												// UserShift  is the X offset possibly introduced by the 'Advance'  and 'Reverse' buttons (and corrected there so that the midpoint stays fixed independent of zoom)

	if ( DiacTrueTime( sFo, sWNm ) )  	
		XShiftSecs	= ( BegDisp + UserShift ) / UFPE_kXSCALE * nSmpInt 		//  WITH  user shift (=Advance,Reverse) .  X scale is true time  (only the beginning of the trace is at true times as no-store sections distort later times)
	else
		XShiftSecs	= 		    UserShift  / UFPE_kXSCALE * nSmpInt 			//  WITH  user shift (=Advance,Reverse) .  X scale always restarts at 0 (shifts the data and the X axis scale accordingly)
	endif

	variable  	TgtPt	 	 = 0
	variable	bHighResolution = HighResolution()
	variable	nDrawPts 		 = 1000										// arbitrary value				
	variable	step			 = bHighResolution ? 1 :  trunc( max( nPts / nDrawPts, 1 ) )

	make    	/O /N = ( nPts / step ) $sTrcDisp								
	wave	wvDisp = $sTrcDisp							
 	variable	DiTgtBeg	=    TgtPt 		   / step
	variable	DiTgtEnd	=  ( TgtPt  + nPts ) / step 
 	variable	OrgBeg	=    BegSv + UserShift / step 		 					//  WITH  user shift (=Advance,Reverse) 

	wvDisp[ DiTgtBeg, DiTgtEnd - 1]  = wOrgData[ OrgBeg  - TgtPt + p * step ] / Gain		// p must be kept literally within the brackets
	
	// 2003-06-10 new   it should be sufficient to do this only once during initialization
	//sUnits	=  UnitsByNm_ns( sFo, sOrg )									// Store the Y units of the wave within the wave to make it accessible for 'Scalebars()'...
	SetScale	/P y, 0, 0,  sUnits,  wvDisp										//..while at the same time prevent Igor from drawing them   ( Label...."\\u#2" ) 

	SetScale	/P X, XShiftSecs, nSmpInt/UFPE_kXSCALE*step, UFPE_ksXUNIT, wvDisp 	// /P x 0, number : expand in x by number (Integer wave: change scale from points into ms using the SmpInt) .  XShiftSecs  shifts only the X axis scale but not the data
	printf "\t\t\t\t\tCopyExtractedSweep1_ns\t\t\t\t\t\t\tB:\t%10.0lf\t..%9.0lf\tPts:\t%10.0lf\tDis_:\t%10.0lf\t\t\t\t\t\tTgt:%5g\tstep:\t%6d\txss:\t%g\t%s\t%s\tsh:\t%.2lf\tzm:\t%.2lf\t%10.0lf\t...\t%10.0lf\t%10.0lf\t \r", BegSv, BegSv+nPts, nPts, BegDisp, TgtPt, step, XShiftSecs, UFCom_pd( sFoBigWv,24),  UFCom_pd(sTrcDisp,21), xShift, xZoom, DiTgtBeg, DiTgtEnd, OrgBeg
End

//=====================================================================================================================================


Function	RangeToPoints( sFo, pr, bl, lap, fr, nRange, nSmpInt, llstBLF, lllstTapeTimes, BegPt, nPtS )	//  BegPt  and  nPts  are references which are passed back
// ...
	string		sFo
	variable	pr, bl, lap, fr, nRange, nSmpInt
	string  	llstBLF, lllstTapeTimes
	variable	&BegPt, &nPtS

	variable	nFrm		= UFPE_Frames( llstBLF, bl )
	variable	Pts1Prot	= TotalTapePts_ns( sFo, nSmpInt, llstBLF, lllstTapeTimes )
	variable	Time1Lap	= UFPE_TapePts1Lap_( sFo, bl, nSmpInt, llstBLF, lllstTapeTimes )
	variable	Time1Frm	= Time1Lap / nFrm
	variable	TapeBeg	= 0
	nPtS		= Time1Frm * 1000 / nSmpInt											// frame is default
	nPtS		=  ( nRange == kRA_LAP )  ?  nPtS * nFrm   :  nPtS							// to display a lap containing 'nFrm' frames more points are required (or use 'Time1Lap' )
	BegPt	= ( pr * Pts1Prot )  +  ( ( lap * Time1Lap ) + fr * Time1Frm + TapeBeg ) * 1000 / nSmpInt	// ugly : better pass points
	 printf "\t\t\t\t\tRangeToPoints   \tra:%d\t\tp:%d b:%d l:%d f:%d  \t\t\t\tB:\t%10.0lf\t..%9.0lf\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\tT1L:\t%10.0lf\tT1F:\t%10.0lf\t \r", nRange, pr, bl, lap, fr,  BegPt, BegPt + nPtS, Time1Lap , Time1Frm
End



//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//static Function	/S	Nm2Color( sFo, sTNm )
//// Retrieves and returns 'RGB' entry from script when the channel name is given,  e.g. 'Adc0'  or  'Dac2'
//	string 	sFo, sTNm
//	variable	nio, cio
//	string	 	sColor
//	svar	/Z	lllstIO	= $"root:uf:" + sFo + ":lllstIO"  						
//	UFPE_ioNm2NioC_ns( lllstIO, sTNm, nio, cio )
//	sColor		= UFPE_ioItem( lllstIO, nio, cio, kSC_IO_RGB )
//	 printf "\t\tNm2Color( \t\t\t'%s',  '%s' ) : color: '%s'    \r", sFo, sTNm, sColor
//	return	sColor
//End

//static Function	/S	UnitsByNm_ns( sFo, sTNm )
//// Retrieves and returns 'Units' entry from script when the channel name is given,  e.g. 'Adc0'  or  'Dac2'
//	string 	sFo, sTNm
//	variable	nio, cio
//	string	 	sUnit	
//	svar	/Z	lllstIO	= $"root:uf:" + sFo + ":lllstIO"  						
//	UFPE_ioNm2NioC_ns( lllstIO, sTNm, nio, cio )
//	sUnit		= UFPE_ioItem( lllstIO, nio, cio, kSC_IO_UNIT )
//	 // printf "\t\tUnitsByNm( \t\t\t'%s',  sTNm:'%s' ) : unit: '%s'   \r", sFo, sTNm, sUnit
//	return	sUnit
//End

//static Function		NameUnitsByNm( sFo, sTNm, rsName, rsUnit )
//// Retrieves and passes back  'Name'  and   'Units'  entry from script when the channel name is given,  e.g. 'Adc0'  or  'Dac2'
//	string 	sFo, sTNm
//	string 	&rsName, &rsUnit
//	variable	nio, cio
//	svar	/Z	lllstIO	= $"root:uf:" + sFo + ":lllstIO"  						
//	UFPE_ioNm2NioC_ns( lllstIO, sTNm, nio, cio )
//	rsUnit	= UFPE_ioItem( lllstIO, nio, cio, kSC_IO_UNIT )
//	rsName	= UFPE_ioItem( lllstIO, nio, cio, kSC_IO_NAME )
//	// 2006-0608
//	if ( strlen( rsName ) == 0 )								// if the user has not specified the name of the channel in the script (e.g Dac: Chan=0; Name=Stimulus0; ... )
//		rsName	= StringFromList( nio, klstSC_NIO ) + UFPE_ioItem( lllstIO, nio, cio, kSC_IO_CHAN ) //...then the simple inherent name  'Dac0'  or  'Adc1'   or similar is used.
//	endif
//	// printf "\t\tNameUnitsByNm( \t%s , %s) :  unit:'%s'    name:'%s'   \r", sFo, sTNm, rsUnit, rsName
//	// todo : possibly return bFound = UFCom_kNOTFOUND  to distinguish between  'Entry was empty' (it not returning default)  and   'NoMatchingTraceFound'  (actually the latter should not occur)
//End

// Save/Restore window location 1:  Define the keywords fro retrieving the entry from the INI file
static strconstant	ksPN_INISUB			= "FPuls"			// The  INI subfolder  below folder 'acq'   and   the  INI file location (here in a subdirectory to FPulse=FPulseMain.ipf)
static strconstant	ksPN_INIKEY			= "Wnd"			// The  keyword in the INI file (here always 'Wnd' as we are dealing with window positions and visibility)
static strconstant	ksAFTER_ACQ_WNM	= "After_Acq"		// 


 Function		DisplayRawAftAcq_ns()
// displays  bigIO  traces  growing DURING acquisition (and also the entire bigio trace after acquisition is finished) 
// the telegraph channels are displayed but they have no effect on the true AD channels here 
// Limitations:  	Dacs are not displayed.  To view Dacs during testing they can be BNC-connected to an ADC ,
//			The colors are hard-coded.  Adcs above the second are all displayed in gray, telegraphs in black.   
	string  	sFo			= ksACQ
	variable	sc			= 0
	variable	nSmpInt		= SmpIntDacUs( sFo )
	string  	sSubFoC		= UFPE_ksCOns
	nvar		gnCompress	= $"root:uf:" + sFo + ":" + sSubFoC + ":gnCompressTG"
	string  	sBigIO

	string  	sWNm		= ksAFTER_ACQ_WNM
	DoWindow  /K $sWNm 								// the window will be deleted anyhow in  'InterpretScript..'  where all data  (=bigio) are zapped and the data folders erased.  
													// Could be done more mildly.  This is done to ensure that tere is nothing left over from a previois script when a new script is loaded.
	//UFCom_EraseTracesInGraph( ksAFTER_ACQ_WNM )		// ...the window will be deleted anyhow...
	variable 	left = 20,  top = 70,  right = 320,  bot = 350			// coordinates are such that they do not cover the 'current acq file'  button in 'Eval'  

	// Save/Restore window location 2 : Retrieve the entry from the INI file.  If not found use the passed values as default.
	string  	sWndInfo	= UFCom_Ini_Section( sFo, ksPN_INISUB, sWNm, ksPN_INIKEY )
			sWndInfo	= UFCom_WndPosition_( sFo, sWndInfo, left, top, right, bot )
	// printf "\t\tDisplayRawAftAcq_ns()    %s %s %ss %s : %s   %d %d %d %d \r", sFo,  ksPN_INISUB,  sWNm, ksPN_INIKEY, sWndInfo,  left, top, right, bot

	Display 	 /N=$sWNm   /K=1  /W=( left, top, right, bot )		// allow killing wihout confirmation	

	// Save/Restore window location 3:  Connect a hook function to the window  which recognises window movements
	string  	sfHook	= "fHookDispAfterAcq"
	SetWindow $sWNm , hook( $sfHook ) = $sfHook							// The hook function requires to use a named hook. For saving an extra parameter the name of the hook function is also used for the hook name.

	svar		lllstIO			= $"root:uf:" + sFo + ":" + "lllstIO" 	
	svar		lllstIOTG		= $"root:uf:" + sFo + ":" + "lllstIOTG" 	
	variable	nio			= kSC_ADC
	variable	cio, cioCnt		= UFPE_ioChanCnt( lllstIOTG, nio )	// includes TG channels
	variable	nCntAD		= UFPE_ioChanCnt( lllstIO,	    nio )	//	ItemsInList( StringFromList( kSC_ADC, lllstIO, "~" ) )

	// The true AD and the telegraph channels
	string  	sIONr, sIOType	= StringFromList( nio, klstSC_NIO )
	string  	sAxLabel, 	sAxNm
	variable	YAxMin, YAxMax
	for ( cio = 0; cio < cioCnt; cio += 1 )
		sIONr	= UFPE_ioItem( lllstIOTG, nio, cio, kSC_IO_CHAN )	
	  	sAxLabel	= sIOType + sIONr
		yAxMin	=  cio 	 / cioCnt
		yAxMax	= ( cio + 1 ) / cioCnt * .95
		sAxNm		= "left" + num2str( cio )
		sBigIO		= UFPE_FoAcqADTG( sFo, sc, lllstIOTG, cio, nCntAD )
		wave   wBigIO	= $sBigIO
		variable	compress	= 1
if ( ELIMINATE_BLANKS()  <= 1	 &&   cio >=  nCntAD )				// old-style, to be removed...
		compress	= gnCompress
endif
		SetScale 	/P X, 0, nSmpInt / UFPE_kXSCALE * compress, UFPE_ksXUNIT, wBigIO 
		AppendToGraph /W=$sWNm  /L=$sAxNm /C=( 0, 60000, 0 ) wBigIO			// green
		ModifyGraph	 /W=$sWNm 	axisEnab(  $sAxNm )	= {  YAxMin, YAxMax }	// stack the Y axes vertically
		ModifyGraph	/W=$sWNm 	lblPos( 	$sAxNm )	= 85 					// move label to the left  (in points)
		Label		 /W=$sWNm  $sAxNm, 	sAxLabel 						// normal size labels
	endfor
	ModifyGraph	 /W=$sWNm 	axisEnab( bottom ) = {  .2, 1 }	// leave a left margin for Y axis  scale and units
	if ( numPnts( wBigIO ) < 400 )
		ModifyGraph  mode=4, marker=10					// display each point as a marker
	endif
End


// Save/Restore window location 4: Define a hook function which recognises window movements  and stores the changed coordinates in the INI file
Function		fHookDispAfterAcq( s )
// The window hook function detects when the user moves or resizes or hides the table window  and stores these settings in the INI file
	struct	WMWinHookStruct &s
	string  	sIniBasePath	= FunctionPath( ksFP_APP_NAME )	// the Ini file containing the window position will be written in a subdirectory parallel to UF_PulseMain.ipf 
	string  	sSubFo	= "" ,  sControlBase = ""				// only required if there were a corresponding button in the main panel which must adjust its state to the windows state
	UFCom_WndUpdateLocationHook( s, ksACQ, sSubFo, ksPN_INISUB, ksPN_INIKEY, sControlBase, sIniBasePath )
	//UFCom_Wnd_UpdateLocationHook( s, ksACQ, ksPN_INISUB, ksPN_INIKEY, sIniBasePath )
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

Function		ShowTraceAccess( sFo )
// prints completely composed acquisition display trace names (including folder, mode/range, begin point  which the user can use to access the traces
	string  	sFo
	variable	bl, fr, sw, nType
	string		sTNm	= "Dac0"
	for ( bl = 0; bl < UFPE_eBlocks( sFo ); bl += 1 )
	printf  "\t\tShowTraceAccess()  ( only for '%s' )    Block:%2d/%2d \r", sTNm, bl,  UFPE_eBlocks( sFo )
		for ( fr = 0; fr < UFPE_eFrames_( sFo, bl ); fr += 1 )
			printf  "\t\t\tf:%2d\tF:%s\tP:%s\tR:%s\ts1%s\ts2%s ...\r", fr , UFCom_pd(TraceFB_( sTNm,  fr, bl ),25), UFCom_pd(TracePB_( sTNm,  fr, bl ),25), UFCom_pd(TraceRB_( sTNm,  fr, bl ),25), UFCom_pd(TraceSB_( sTNm,  fr, bl, 0 ),25), UFCom_pd(TraceSB_( sTNm,  fr, bl, 1 ),25)
		endfor
	endfor
End

// There are 'nFrames'  traces in 'Many superimposed' mode e.g. 'Adc0SM_0' , 'Adc0SM_2000' , 'Adc0SM_4000'  which make sense to be selected...
// ...but there is only 1 'current'  mode trace e.g. 'Adc0SC_'  which is useless here because it stores just the last sweep or frame


// 2003-10-07     NOT REALLY  PROTOCOL  AWARE ............

Function  /S		TraceF_( sTNm, fr )
// return composed  FRAME  Acq display trace name  when base name and frame is given ( for block 0 ) 
	string		sTNm
	variable	fr
	variable	bl	= 0, lap=0
	variable	pr	= 0	// 2003-10-07     NOT REALLY  PROTOCOL  AWARE ............
	string  	sFo	= ksACQ
	return	Trace_( sFo, sTNm, kFRAME, UFPE_FrameBegSave( sFo, pr, bl, lap, fr ) )
End

Function  /S		TraceP_( sTNm, fr )
// return composed  PRIMARY  Acq display trace name  when base name and frame is given ( for block 0 ) 
	string		sTNm
	variable	fr
	variable	bl	= 0, lap=0
	variable	pr	= 0	// 2003-10-07     NOT REALLY  PROTOCOL  AWARE ............
	string  	sFo	= ksACQ
	return	Trace_( sFo, sTNm, kPRIM, UFPE_FrameBegSave( sFo, pr, bl, lap, fr ) )
End

Function  /S		TraceR_( sTNm, fr )
// return composed  RESULT  Acq display trace name  when base name and frame is given ( for block 0 ) 
	string		sTNm
	variable	fr
	variable	bl	= 0, lap=0
	variable	pr	= 0	// 2003-10-07     NOT REALLY  PROTOCOL  AWARE ............
	string  	sFo	= ksACQ
	return	Trace_( sFo, sTNm, kRESULT, UFPE_SweepBegSave( sFo, pr, bl, lap, fr,  UFPE_eSweeps_( sFo, bl ) - 1 ) )
End

Function  /S		TraceS_( sTNm, fr, sw )
// return composed  SWEEP  Acq display trace name  when base name,  frame  and  sweep  is given ( for block 0 ) 
	string		sTNm
	variable	fr, sw
	variable	bl	= 0, lap=0
	variable	pr	= 0	// 2003-10-07     NOT REALLY  PROTOCOL  AWARE ............
	string  	sFo	= ksACQ
	return	Trace_( sFo, sTNm, kSWEEP, UFPE_SweepBegSave( sFo, pr, bl, lap, fr,  sw ) )
End

Function  /S		TraceFB_( sTNm, fr, bl )
// return composed  FRAME  Acq display trace name  when base name and frame and block is given
	string		sTNm
	variable	fr, bl
	variable	pr	= 0, lap=0	// 2003-10-07     NOT REALLY  PROTOCOL  AWARE ............
	string  	sFo	= ksACQ
	return	Trace_( sFo, sTNm, kFRAME, UFPE_FrameBegSave( sFo, pr, bl, lap, fr ) )
End

Function  /S		TracePB_( sTNm, fr, bl )
// return composed  PRIMARY  Acq display trace name  when base name and frame and block is given
	string		sTNm
	variable	fr, bl
	variable	pr	= 0, lap=0	// 2003-10-07     NOT REALLY  PROTOCOL  AWARE ............
	string  	sFo	= ksACQ
	return	Trace_( sFo, sTNm, kPRIM, UFPE_FrameBegSave( sFo, pr, bl, lap, fr ) )
End

Function  /S		TraceRB_( sTNm, fr, bl )
// return composed  RESULT  Acq display trace name  when base name and frame and block is given
	string		sTNm
	variable	fr, bl
	variable	pr	= 0, lap=0	// 2003-10-07     NOT REALLY  PROTOCOL  AWARE ............
	string  	sFo	= ksACQ
	return	Trace_( sFo, sTNm, kRESULT, UFPE_SweepBegSave( sFo, pr, bl, lap, fr,  UFPE_eSweeps_( sFo, bl ) - 1 ) )
End

Function  /S		TraceSB_( sTNm, fr, bl, sw  )
// return composed  SWEEP  Acq display trace name  when base name , frame , block  and  sweep  given
	string		sTNm
	variable	fr, sw, bl
	variable	pr	= 0, lap=0	// 2003-10-07     NOT REALLY  PROTOCOL  AWARE ............
	string  	sFo	= ksACQ
	return	Trace_( sFo, sTNm, kSWEEP, UFPE_SweepBegSave( sFo, pr, bl, lap, fr, sw ) )
End

Function  /S		Trace_( sFo, sTNm, nRange, BegPt )
// returns  any  composed  Acq display trace name....
	string		sFo, sTNm
	variable	nRange, BegPt
	variable	nMode	= kMANYSUPIMP
	return	BuildTraceNmForAcqDisp( sFo, sTNm, nMode, nRange, BegPt)
End
// 2003-10-07  -----------   NOT  REALLY  PROTOCOL  AWARE 


static strconstant 	ksMORA_PTSEP		= "_"		// separates TraceModeRange from starting point in trace names, e.g. Adc0SM_0 (blank is not allowed)

static  Function	/S	BuildTraceNmForAcqDisp( sFo, sChan, nMode, nRange, BegPt )
 	string		sFo, sChan
 	variable	nMode, nRange, BegPt
	return	"root:uf:" + ksACQ + ":dispFS:" + BuildTraceNmForAcqDispNoFolder( sChan, nMode, nRange, BegPt )
End

static  Function	/S	BuildTraceNmForAcqDispNoFolder( sChan, nMode, nRange, BegPt )
 	string		sChan
 	variable	nMode, nRange, BegPt
 	string		sBegPt
	sprintf	sBegPt, "%d",  BegPt			// formats correctly  e.g. 160000 (wrong:num2str( BegPt ) formats 1.6e+05 which contains dot which is illegal in wave name..) 
	string  	sTNm	= sChan + BuildMoRaName( nRange, nMode ) + ksMORA_PTSEP		// e.g.Adc0 + SM + _
	
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

