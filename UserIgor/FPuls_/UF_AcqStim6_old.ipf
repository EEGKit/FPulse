// UF_AcqStim6.ipf 
// 
// Special routines for stimulus display used only by FPulse  but not by  FEVAL
//

 
#pragma rtGlobals=1						// Use modern global access method.

//#include "UFCom_Panel" 					// UFCom_PossiblyCreateFolder()
//#include "UFCom_ListProcessing" 
//#include "UFCom_ColorsAndGraphs" 		



//================================================================================================================================
//	STIMULUS  DISPLAY  CONTROLBAR

static constant		kSD_CB_HTLN0				= 26			// 26 is the minimum value required for a popupmenu
static constant		kSD_CB_HTLN1				= 20			// 20 is sufficient if the line only contains buttons 

static strconstant	klstSD_CB_CONTROLS	= "pm,Block,120;cb,Laps,60;cb,no store,60;cb,Hi Res,60;pm,Add,100;bu,Help,40;"	// !!! ALSO CHANGE BELOW


// ONLY  FOR  FPULSE ,  NOT  FOR  EVAL because of  'lstDiSBlocks_a() '  and  'lstDiSHiddenTraces_a()'
 Function	UFPE_DiSControlbar( sWNm,  sFo, sWndInfo, bControlbar )
	string  	sWNm			// e.g. 'Sti'
	string  	sFo
	string  	sWndInfo			// contains the desired initial settings when the controlbar is created
	variable	bControlbar												// Show or hide the controlbar

	variable	ControlBarHeight = bControlbar ?  kSD_CB_HTLN0 : 0//+ kSD_CB_HTLN1 :  0 	// height 0 effectively hides the whole controlbar
	ControlBar /T /W = $sWNm  ControlBarHeight 								// /T creates at top, /B creates at bottom

	string  	sName, sTitle
	variable	wi, ht, left, top
	variable	i, nItems	= ItemsInList( klstSD_CB_CONTROLS, ";" )
	for ( i = 0; i < nItems; i += 1 )
	  	sName	= UFPE_DiSCbarName( sFo, sWNm, i, klstSD_CB_CONTROLS) 
		left		= UFPE_DiSCbarPos( i, klstSD_CB_CONTROLS )
		wi		= UFPE_DiSCbarWidth( i, klstSD_CB_CONTROLS )
	  	sTitle		= UFPE_DiSCbarTitle( i , klstSD_CB_CONTROLS) 
		printf "\t\tUFPE_DiSControlbar( '%s'  '%s'  ) \ti:%2d/%2d\tsName:\t%s\tsTitle:\t%s\tleft:%3d\twi:%3d\t  \r", sWNm,  sFo, i, nItems, UFCom_pd( sName, 23), UFCom_pd( sTitle, 13), left, wi
		if ( 	cmpstr( UFPE_DiSCbarTyp( i, klstSD_CB_CONTROLS ), "bu" )  == 0 )
			Button			$sName,	win = $sWNm,  	pos={ left, 2 },  	size={ wi,20 },  title= sTitle
			if ( 	cmpstr( UFPE_DiSCbarTitle( i, klstSD_CB_CONTROLS ), "Help" ) 	== 0 )									// !!! ALSO CHANGE ABOVE
				Button		$sName,	win = $sWNm,  proc = fDiSHelp
			endif			
		elseif ( cmpstr( UFPE_DiSCbarTyp( i, klstSD_CB_CONTROLS ), "cb" ) == 0 )
			Checkbox			$sName,	win = $sWNm,  	pos={ left, 2 },  	size={ wi,20 },  title= sTitle
			if ( 	cmpstr( UFPE_DiSCbarTitle( i, klstSD_CB_CONTROLS ), "Laps" ) 	== 0 )									// !!! ALSO CHANGE ABOVE
				Checkbox		$sName,	win = $sWNm,  	proc = fDiSExpandLaps
			elseif ( cmpstr( UFPE_DiSCbarTitle( i, klstSD_CB_CONTROLS ), "no store" ) == 0 )										// !!! ALSO CHANGE ABOVE
				Checkbox		$sName,	win = $sWNm,  	proc = fDiSShowNoStore
			elseif ( cmpstr( UFPE_DiSCbarTitle( i, klstSD_CB_CONTROLS ), "Hi Res" )	== 0 )									// !!! ALSO CHANGE ABOVE
				Checkbox		$sName,	win = $sWNm,  	proc = fDiSHiRes
			endif			
		elseif ( cmpstr( UFPE_DiSCbarTyp( i, klstSD_CB_CONTROLS ), "pm" )  == 0 )
			Popupmenu		$sName,	win = $sWNm,  	pos={ left, 0 },  	size={ wi-20,20 },  title= sTitle
			if ( 	cmpstr( UFPE_DiSCbarTitle( i, klstSD_CB_CONTROLS ), "Block" ) 	== 0 )									// !!! ALSO CHANGE ABOVE
				Popupmenu	$sName,	win = $sWNm,  	proc = fDiSBlocks,	       value = lstDiSBlocks_a() 
			elseif ( cmpstr( UFPE_DiSCbarTitle( i, klstSD_CB_CONTROLS ), "Add" ) 	== 0 )									// !!! ALSO CHANGE ABOVE
				Popupmenu	$sName,	win = $sWNm,  	proc = fDiSHiddenTraces_a, value = lstDiSHiddenTraces_a()	
			endif
		endif
	endfor
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
	  	DiSDispTracesUpdatePM( sFo, ksFPUL )									// ..and update  'Display Remove' popupmenu so that the added trace will be offered for further 'Removes' 
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
//	  	DiSDispTracesUpdatePM( sFo, ksFPUL )									// ..and update  'Display Remove' popupmenu so that the added trace will be offered for further 'Removes' 
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
	printf "\t\t\tlstDiSHiddenTraces_a() \treturns:\t'%s' \r", lst
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
	printf "\t\t\tDiSHiddenTraces_a()   \treturns:\t'%s' \r", lst
	return	lst																// Reverse list so that the order in popupmenu corresponds to display order
End


Function	 	DiSDispTracesUpdatePM( sFo, sWNm )							// ..and update  'Display Remove' popupmenu so that the removed trace will not be offered for further 'Removes' 
	string  	sFo, sWNm	
	// Update the popupmenu so that only the currently available items (traces)  are offered.
	string  	sFoCNmIdx	= "root_uf_" + sFo + "_" + sWNm + "_" + "pmAdd" 
	 print  "\t\t\tDiSDispTracesUpdatePM(",  sFo, sWNm," ,  ) ->", sFoCNmIdx, "[Updating popupmenu]"
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


