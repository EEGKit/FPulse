// UF_AcqStimControlbar.ipf 
 
// Special routines for stimulus display controlbar for FPulse 
 
#pragma rtGlobals=1						// Use modern global access method.

#include "UFCom_Controlbar"
#include "UFCom_Ini"


//================================================================================================================================
//	STIMULUS  DISPLAY  CONTROLBAR

static constant		kSD_CB_HTLN0				= 26			// 26 is the minimum value required for a popupmenu
static constant		kSD_CB_HTLN1				= 20			// 20 is sufficient if the line only contains buttons 

//static strconstant	klstSD_CB_CONTROLS	= "sep,,0,5~pm,Block,120,10~cb,Laps,60,10~cb,no store,60,10~cb,Hi Res,60,10~pm,Add,100,10~bu,Help,40;"					// !!! ALSO CHANGE BELOW
static strconstant	klstSD_CB_CONTROLS	= "sep,,0,5~pm,Block,120,10~cb,Laps,60,10~cb,only 2 Frm,60,10~cb,no store,60,10~cb,Hi Res,60,10~pm,Add,100,10~bu,Help,40;"	// !!! ALSO CHANGE BELOW


// ONLY  FOR  FPULSE ,  NOT  FOR  EVAL because of  'lstDiSBlocks_a() '  and  'lstDiSHiddenTraces_a()'
 Function	DiSControlbar_a( sWNm,  sFo, sWndInfo, bControlbar )
	string  	sWNm			// e.g. 'Sti'
	string  	sFo
	string  	sWndInfo			// contains the desired initial settings when the controlbar is created
	variable	bControlbar												// Show or hide the controlbar

	variable	ControlBarHeight = bControlbar ?  kSD_CB_HTLN0 : 0//+ kSD_CB_HTLN1 :  0 	// height 0 effectively hides the whole controlbar
	ControlBar /T /W = $sWNm  ControlBarHeight 								// /T creates at top, /B creates at bottom

	string  	sName, sTitle, lst
	variable	wi, ht, left, top, marginR, i, nItems

	lst		= klstSD_CB_CONTROLS
	nItems	= UFCom_ControlbarItems( lst )
	for ( i = 0; i < nItems; i += 1 )
	  	sName	= UFCom_ControlbarName( sFo, sWNm, i, lst) 
		left		= UFCom_ControlbarPos( i, lst )
		wi		= UFCom_ControlbarWidth( i, lst )
	  	sTitle		= UFCom_ControlbarTitle( i , lst) 
		marginR	= UFCom_ControlbarMarginR( i, lst )
		// printf "\t\tDiSControlbar_a  '%s'  '%s'  ) \ti:%2d/%2d\tsName:\t%s\tsTitle:\t%s\tleft:%3d\twi:%3d\tmaR:%3d\t  \r", sWNm,  sFo, i, nItems, UFCom_pd( sName, 23), UFCom_pd( sTitle, 13), left, wi, marginR
		if ( 	cmpstr( UFCom_ControlbarTyp( i, lst ), "bu" )  == 0 )
			Button			$sName,	win = $sWNm,  	pos={ left, 2 },  	size={ wi,20 },  title= sTitle
			if ( 	cmpstr( UFCom_ControlbarTitle( i, lst ), "Help" ) 	== 0 )									// !!! ALSO CHANGE ABOVE
				Button		$sName,	win = $sWNm,  proc = fDiSHelp_a
			endif			
		elseif ( cmpstr( UFCom_ControlbarTyp( i, lst ), "cb" ) == 0 )
			Checkbox			$sName,	win = $sWNm,  	pos={ left, 2 },  	size={ wi,20 },  title= sTitle
			if ( 	cmpstr( UFCom_ControlbarTitle( i, lst ), "Laps" ) 	== 0 )									// !!! ALSO CHANGE ABOVE
				Checkbox		$sName,	win = $sWNm,  	proc = fDiSExpandLaps_a
			elseif ( cmpstr( UFCom_ControlbarTitle( i, lst ), "only 2 Frm" ) == 0 )									// !!! ALSO CHANGE ABOVE
				Checkbox		$sName,	win = $sWNm,  	proc = fDiSShowClipFrames_a
			elseif ( cmpstr( UFCom_ControlbarTitle( i, lst ), "no store" ) == 0 )									// !!! ALSO CHANGE ABOVE
				Checkbox		$sName,	win = $sWNm,  	proc = fDiSShowNoStore_a
			elseif ( cmpstr( UFCom_ControlbarTitle( i, lst ), "Hi Res" ) == 0 )									// !!! ALSO CHANGE ABOVE
				Checkbox		$sName,	win = $sWNm,  	proc = fDiSHiRes_a
			endif			
		elseif ( cmpstr( UFCom_ControlbarTyp( i, lst ), "pm" )  == 0 )
			Popupmenu		$sName,	win = $sWNm,  	pos={ left, 0 },  	size={ wi-20,20 },  title= sTitle
			if ( 	cmpstr( UFCom_ControlbarTitle( i, lst ), "Block" ) 	== 0 )									// !!! ALSO CHANGE ABOVE
				Popupmenu	$sName,	win = $sWNm,  	proc = fDiSBlocks_a,	       value = lstDiSBlocks_a() 
			elseif ( cmpstr( UFCom_ControlbarTitle( i, lst ), "Add" ) 	== 0 )									// !!! ALSO CHANGE ABOVE
				Popupmenu	$sName,	win = $sWNm,  	proc = fDiSHiddenTraces_a, value = lstDiSHiddenTraces_a()	
			endif
		endif
	endfor
End

//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function		fDiSBlocks_a( s ) 
	struct	WMPopupAction	&s
	if ( s.eventcode == 2 )							// -1: control being killed,  2: mouseup 
	 	string  	sFo	 		= StringFromList( 2, s.ctrlName, "_" )						// as passed from 'PanelCheckbox3()'   e.g.  'root:uf:acq:pul:'  -> 'pul' 
		string  	sIniBasePath	= ScriptPath( sFo )									// derive  IniPath  from Script path   as  sSubFoIni =  'Scrip'
		 printf "\t\tfDiSBlocks_a Popup  evcode:%d ) \t\tIndex of Blocks popupmenu : %d    All blocks:%2d    '%s'   '%s'     IniBasePath: '%s' \r", s.eventcode, DiSDspBlock( sFo, s.win ), DiSAllBlocks( sFo, s.win ),  s.ctrlname,  s.win, sIniBasePath
		DisBlocks_( s, sFo, sIniBasePath )	
	endif
End

Function		fDiSExpandLaps_a( s ) 
	struct	WMCheckboxAction	&s
	if ( s.eventcode == 2 )							// -1: control being killed,  2: mouseup 
	 	string  	sFo	 		= StringFromList( 2, s.ctrlName, "_" )						// as passed from 'PanelCheckbox3()'   e.g.  'root:uf:acq:pul:'  -> 'pul' 
		string  	sIniBasePath	= ScriptPath( sFo )									// derive  IniPath  from Script path   as  sSubFoIni =  'Scrip'
		// printf "\t\tfDiSExpandLaps_a \t%s\t%s\t%s\t-> val: %g\t=?=\t%g    IniBasePath: '%s \r", UFCom_pd(s.CtrlName,31),	 UFCom_pd(sFo,17), UFCom_pd(s.win,9),  s.checked, DiSExpandLaps( sFo, s.win ),   sIniBasePath
		DiSExpandLaps_( s, sFo, sIniBasePath )	
	endif
End

Function		fDiSHiRes_a( s )
	struct	WMCheckboxAction	&s
	if ( s.eventcode == 2 )							// -1: control being killed,  2: mouseup 
	 	string  	sFo 	= StringFromList( 2, s.ctrlName, "_" )						// as passed from 'PanelPopupmenu3()'   e.g.  'root:uf:acq:pul:'  -> 'pul' 
	 	// printf "\t\t\t%s\t%s\t%s\t-> val: %g\t  \r",    UFCom_pd(s.CtrlName,31),	sFo, UFCom_pd(s.win,6),  s.checked
		// THERE SHOULD BE  no need to redraw the screen immediately, wait for additional user commands (e.g. display/hide blocks, Laps, blanks)
		string  	sIniBasePath	= ScriptPath( sFo )							// derive  IniPath  from Script path   as  sSubFoIni =  'Scrip'
		DiSHiRes_( s, sFo, sIniBasePath )	
	endif
End

Function		fDiSShowClipFrames_a( s )	
	struct	WMCheckboxAction	&s
	if ( s.eventcode == 2 )							// -1: control being killed,  2: mouseup 
	 	string  	sFo	= StringFromList( 2, s.ctrlName, "_" )								
		// printf "\t\t%s\t%s\t%s\t-> val: %g\t  TODO......ok a..\r", UFCom_pd(s.CtrlName,31),	 UFCom_pd(sFo,17), UFCom_pd(s.win,9),  s.checked
		string  	sIniBasePath	= ScriptPath( sFo )							// derive  IniPath  from Script path   as  sSubFoIni =  'Scrip'
		DiSShowClipFrames_( s, sFo, sIniBasePath )	
	endif
	return	0
End

Function		fDiSShowNoStore_a( s )	
	struct	WMCheckboxAction	&s
	if ( s.eventcode == 2 )							// -1: control being killed,  2: mouseup 
	 	string  	sFo	= StringFromList( 2, s.ctrlName, "_" )								
		// printf "\t\t%s\t%s\t%s\t-> val: %g\t  TODO......ok a..\r", UFCom_pd(s.CtrlName,31),	 UFCom_pd(sFo,17), UFCom_pd(s.win,9),  s.checked
		string  	sIniBasePath	= ScriptPath( sFo )							// derive  IniPath  from Script path   as  sSubFoIni =  'Scrip'
		DiSShowNoStore_( s, sFo, sIniBasePath )	
	endif
	return	0
End

//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function		fDiSHelp_a( s )	
	struct	WMButtonAction	&s
 	string  	sFo	 	= StringFromList( 2, s.ctrlName, "_" )								// as passed from 'PanelCheckbox()3'   e.g.  'root:uf:acq:std:' 
	if ( s.eventcode == UFCom_CCE_mouseup )								// mouse up  inside button
		 printf "\t\t%s\t%s\t%s\t \t  \r", UFCom_pd(s.CtrlName,31),	 UFCom_pd(sFo,17), UFCom_pd(s.win,9)
	endif
End


//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// ONLY  FOR  FPULSE ,  NOT  FOR  EVAL

// To make the popupmenu code generally usable in  EVAL  and  in  ACQ we would  have to pass  'sFo'  to  'lstDiSHiddenTraces_a()'  but unfortunately  this function can not receive local parameters.
// As a workaround we introduce different copies of this code in   EVAL  and  in  ACQ  where only the function names (_a/_e)  and the folders  (ksACQ/ksEVAL) differ  slightly .
Function		fDiSHiddenTraces_a( s ) 
// Action proc for the  'Add to Display'  popupmenu
	struct	WMPopupAction	&s
	if ( s.eventcode == 2 )														// -1: control being killed,  2: mouseup 
		string  	sWNm		= UFPE_StimWndNm_ns( ksACQ )					// the stimulus graph window  e.g. 'Sti' 
	 	string  	sFo	 		= StringFromList( 2, s.ctrlName, "_" )					// as passed from 'PanelPopupmenu3()'   e.g.  'root:uf:acq:pul:'  -> 'pul' 
		string  	sSubFoIni		= "Scrip"
		string  	sIniBasePath	= ScriptPath( sFo )								// derive  IniPath  from Script path   as  sSubFoIni =  'Scrip'
		string  	lllstIODi		= UFCom_Ini_Section( ksACQ, sSubFoIni, sWNm, "Trc" )	
		string  	sTrace		= ""
		variable	bvisible, cio, cioCnt, nio, nTypes = UFPE_ioTypeCnt( lllstIODi )	
		for ( nio = 0; nio < nTypes; nio += 1)
			cioCnt	= UFPE_ioChanCnt( lllstIODi, nio )
			for ( cio = 0; cio < cioCnt; cio += 1 )
				sTrace	= StringFromList( nio, klstSC_NIO ) + UFPE_ioItem( lllstIODi, nio, cio, kSC_IO_CHAN ) 	// sIOTyp + sIONr  e.g. 'dac2'	, ass sep
				if ( cmpstr( s.popstr, sTrace ) == 0 )
					lllstIODi	= UFPE_ioSet_ns( lllstIODi, nio, cio, kSC_IO_VIS, "1" )	
				endif
			endfor	
		endfor
		UFCom_IniFile_SectionSetWrite( sFo, sSubFoIni, sWNm, "Trc", lllstIODi, sIniBasePath )	// store  Traces list globally and in INI file  
	  	DiSDispTracesUpdatePM_a( sFo, ksFPUL )									// ..and update  'Display Remove' popupmenu so that the added trace will be offered for further 'Removes' 
		 printf "\t\tfDiSHiddenTraces_a( Popup action \tevcode:%d\t)  \t%s\tlllstIODi:\t%s\t  \r", s.eventcode, s.ctrlname, UFCom_pd( lllstIODi, 70)
		UFPE_DiSAppendChansAndAxes( ksACQ, s.win )

//	 	string  	sFo	 	= StringFromList( 2, s.ctrlName, "_" )						// as passed from 'PanelPopupmenu3()'   e.g.  'root:uf:acq:pul:'  -> 'pul' 
//	 	string  	llstAll		= DiSAllTraces_a()									// get list of  all allowed traces (as defined in the script)
//		string  	llstDisp	= DiSDispTraces_a()									// get former list of traces of the 'Display Remove'  popupmemu..
//		string  	llstHide	= DiSHiddenTraces_a()								// ..the  'Hide=Display Add'  list is always computed by subtracting  'Display' traces  from  'All'  traces
//		variable	rMain = -1, rSub = -1											
//	  	llstHide	= UFCom_RemoveFromDoubleList_( s.popStr, llstHide, ";" , "," , 0, rMain, rSub )// only for retrieving the position 'rMain, rSub' of the selected item in the 'Hide=Display Add' double list, because the item will be added in the display list at THIS  position. 'llstHide' is ignored here but computed later from 'llstAll' minus 'LLstDisp' 
//		llstDisp	= UFCom_ReplaceDoubleListItem( s.popStr, rMain, rSub, llstDisp, ";" , ","  )	// Insert the trace which has been selected in and removed from the 'Hide=Display Add' popupmenu  at the correct position in the  'Disp Remove' double list.
////		DiSDispTracesSet( sFo, llstDisp )											// ..store  'Display Remove' double list globally  
//	  	DiSDispTracesUpdatePM_a( sFo, ksFPUL )									// ..and update  'Display Remove' popupmenu so that the added trace will be offered for further 'Removes' 
////		 printf "\t\tfDiSHiddenTraces_a( Popup action \tevcode:%d\t)  Index of Blocks popupmenu : %d    '%s'\tAll:\t%s\tDisp:\t%s\tHide:\t%s    \tHiding \t%s    \t->\t%s \r", s.eventcode, DiSHideTraceIdx( sFo, s.win ), s.ctrlname, UFCom_pd( llstAll, 30),  UFCom_pd( llstDisp, 30),  UFCom_pd( llstHide, 30),  s.popstr, UFCom_pd( lstDiSDispTraces_a(), 30)	
//		 printf "\t\tfDiSHiddenTraces_a( Popup action \tevcode:%d\t)  Index of Blocks popupmenu : %d    '%s'\tAll:\t%s\tDisp:\t%s\tHide:\t%s    \tHiding \t%s    \t->\t%s \r", s.eventcode, 123, s.ctrlname, UFCom_pd( llstAll, 30),  UFCom_pd( llstDisp, 30),  UFCom_pd( llstHide, 30),  s.popstr, UFCom_pd( lstDiSDispTraces_a(), 30)	
//		UFPE_DiSDisplayChannels( ksACQ, llstDisp, s.win )
	endif
End

// 2008-07-17 not used ???
//Function		fDiSHideTracesPops_a( sControlNm, sFo, sWin )
//	string		sControlNm, sFo, sWin
//	PopupMenu	$sControlNm, win = $sWin,	 value = lstDiSHiddenTraces_a()				// no local parameters allowed ->specific function required
//End

Function	/S	lstDiSHiddenTraces_a()
	string  	lst	= UFCom_ReverseList( UFCom_FlattenDoubleList( DiSHiddenTraces_a(), ";" , "," , ";"  ), ";" )	// Glue function: convert double list (nio, cio)  into single list with 1 linear index as required by the popupmenu
	// printf "\t\t\tlstDiSHiddenTraces_a   \treturns:\t'%s' \r", lst
	return	lst															// Reverse list so that the order in popupmenu corresponds to display order
End							

Function	/S	DiSHiddenTraces_a()
	string  	sSubFoIni	= "Scrip"
	string  	sWNm	= UFPE_StimWndNm_ns( ksACQ )							// the stimulus graph window  e.g. 'Sti' 
	string  	lst		= ""//UFCom_SubtractDoubleList( DiSAllTraces_a(), DiSDispTraces_a(), ";", "," , 0 )	// in contrast to the Disp traces the Hide traces are not stored in a global string but rather computed from 'All' - 'Disp whenever needed
	string  	lllstIODi	= UFCom_Ini_Section( ksACQ, sSubFoIni, sWNm, "Trc" )	
	variable	bvisible, cio, cioCnt, nio, nTypes = UFPE_ioTypeCnt( lllstIODi )	
	for ( nio = 0; nio < nTypes; nio += 1)
// do not offer or display ADCs
if ( nio != kSC_ADC )
		cioCnt	= UFPE_ioChanCnt( lllstIODi, nio )
		for ( cio = 0; cio < cioCnt; cio += 1 )
			bVisible	= UFPE_iov_ns( lllstIODi, nio, cio, kSC_IO_VIS )	
			if ( ! bVisible )														// process only traces which are NOT displayed.  The list 'lllstIODi'  also contains visible AND hidden traces.
				lst +=  StringFromList( nio, klstSC_NIO ) + UFPE_ioItem( lllstIODi, nio, cio, kSC_IO_CHAN ) + ","	// sIOTyp + sIONr  e.g. 'dac2'	, ass sep
			endif
		endfor	
		lst += ";"	// ass sep	
endif
	endfor
	// printf "\t\t\tDiSHiddenTraces_a     \treturns:\t'%s' \r", lst
	return	lst																// Reverse list so that the order in popupmenu corresponds to display order
End


Function	 	DiSDispTracesUpdatePM_a( sFo, sWNm )							// ..and update  'Display Remove' popupmenu so that the removed trace will not be offered for further 'Removes' 
	string  	sFo, sWNm	
	// Update the popupmenu so that only the currently available items (traces)  are offered.
	string  	sFoCNmIdx	= "root_uf_" + sFo + "_" + sWNm + "_" + "pmAdd" 
	 print  "\t\t\tDiSDispTracesUpdatePM_a(",  sFo, sWNm," ,  ) ->", sFoCNmIdx, "[Updating popupmenu]"
	ControlUpdate  /W = $sWNm	$sFoCNmIdx								// update the available entries in the popupmenu
End

//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// ONLY  FOR  FPULSE ,  NOT  FOR  EVAL
// To make the popupmenu code generally usable in  EVAL  and  in  ACQ we would  have to pass  'sFo'  to  'lstDisBlocks_a()'  but unfortunately  this function can not receive local parameters.
// As a workaround we introduce different copies of this code in   EVAL  and  in  ACQ  where only the function names (_a/_e)  and the folders  (ksACQ/ksEVAL) differ  slightly .

// not used
//Function		fDisBlocksPops_a( sControlNm, sFo, sWin )
//	string		sControlNm, sFo, sWin
//	PopupMenu	$sControlNm, win = $sWin,	 value = lstDisBlocks_a()			// no local parameters allowed ->specific function required
//End

Function	/S	lstDisBlocks_a()
// Specific access function :  retrieve from global assuming a specific subfolder.  Similar but distinct copies of this function must be used in FPulse/FEval (ksACQ/ksEVAL, _a/_e)  
//	svar  	llstBLF	= $"root:uf:" + ksACQ + ":" + "llstBLF" 	
//	string  	lstPops	= ""
//	variable	bl, nBlk 	= UFPE_Blocks( llstBLF )
//	for ( bl = 0; bl <nBlk; bl += 1 )
//		lstPops	+= num2str( bl ) + ";"
//	endfor
	return	lstDisBlocks( ksACQ ) 
End	


