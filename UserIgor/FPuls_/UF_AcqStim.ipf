//// UF_AcqStim
//
//strconstant	ksACQ_SD		= "sda"			// Stimulus display  panel and subfolder name			
//
//
//// 2009-12-12 old-style
//Function		fDisplayStim_a( s ) 
//	struct	WMButtonAction	&s
//	nvar		state			= $ReplaceString( "_", s.ctrlname, ":" )		// the underlying button variable name is derived from the control name
//	string  	sFo			= ksACQ								// 'acq'
//	string  	sSubFoIni		= "FPuls"								// = ksPN_INISUB  (do not change!)
//	string  	sWin			= ksACQ_SD							//  'sda'  in  Acq 
//	string  	sIniBasePath	= FunctionPath( ksFP_APP_NAME )			// the Ini file containing the window position will be written in a subdirectory parallel to UF_PulseMain.ipf 
//	UFCom_WndVisibilitySetWrite_( sFo, sSubFoIni, ksACQ_SD, "Wnd", state, sIniBasePath )
//	if ( state )													// if we want to  _display_  the panel...
//		if ( WinType( sWin ) != UFCom_WT_PANEL )					// ...and only if the panel does not yet  exist ..
//			PanelStimulusDisp_a( sFo, sWin, UFCom_kPANEL_DRAW )	// ...we must build the panel
//		else
//			UFCom_WndUnhide( sWin )							//  display again the hidden panel 'sda'  in  Acq  
//		endif
//	else
//		UFCom_WndHide( sWin )									//  hide the panel  'sda'  in  Acq 
//	endif	
//End
//
//
//
////=================================================================================================
////	STIMULUS  DISPLAY  PANEL
//
//// 2009-12-12 old-style
//Function		PanelStimulusDisp_a( sFolder, sWin, nMode  )
//	string  	sFolder, sWin
//	variable 	nMode
//	string  	sFBase		= "root:uf:"
//	string  	sFSub		= sFolder + ":"
//	string		sPnTitle		= "Disp Stim " + sFolder
//	string		sDFSave		= GetDataFolder( 1 )						// The following functions do NOT restore the CDF so we remember the CDF in a string .
//	UFCom_PossiblyCreateFolder( sFBase + sFSub + sWin ) 
//	InitPanelStimulusDisp_a( sFBase + sFSub, sWin )						// Fills both big text waves  'sPnOptions' (=wPn)  in 'root:uf:acq:'  and  in  'root:uf:eva:'  with all information about the controls necessary to build the panel
//
//	// Compute the panel dimensions. Draw the panel displaying and hiding needed/unneeded controls
//	string  	sSubFoIni = "FPuls",   sKey = "Wnd",   sControlBase = "DisplayStim"
//	UFCom_RestorePanel2Sub( ksACQ, ksFPUL, sWin, sPnTitle, sFBase, sFSub, sSubFoIni, sKey, sControlBase, nMode )
//	FP_LstDelWindowsSet( AddListItem( sWin, FP_LstDelWindows() ) )		// add this panel to global list so that we can remove in on Cleanup or Exit
//
//	SetWindow		$sWin,  hook( $sWin ) = fHookSda
//	SetDataFolder sDFSave										// Restore CDF from the string  value
//End
//
////--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//
//// 2009-12-12 old-style
//Function 		fHookSda( s )
//// The window hook function of the 'Disp Stim Acq Panel' detects when the user moves the panel and stores the coordinatesin the INI file. 
////  And it adjusts the corresponding show/hide button in the main panel according to the windows show/hide/killed state.
//	struct	WMWinHookStruct &s
//	string  	sFo			= ksACQ
//	string  	sSubFo		= ksFPUL
//	string  	sSubFoIni		= "FPuls"
//	string  	sKey			= "Wnd"
//	string  	sControlBase 	= "DisplayStim"
//	string  	sIniBasePath	= FunctionPath( ksFP_APP_NAME )					// the Ini file containing the window position will be written in a subdirectory parallel to UF_PulseMain.ipf 
//	return	UFCom_WndUpdateLocationHook( s, sFo, sSubFo, sSubFoIni, sKey, sControlBase, sIniBasePath )
//End
//
//
//
//// 2009-12-12 old-style
//Function		InitPanelStimulusDisp_a( sF, sPnOptions )
//// 	Same Function for  Acq  and  Eval .  The actions procs are also similar functions in  Acq  and  Eval , but the names differ... ( see  UF_AcqScript.ipf  and  FPDispStim.ipf )
//// 	Here are the samples united for  many  radio button  and  checkbox  varieties.....
//	string  	sF, sPnOptions
//	string  	sPanelWvNm	= sF + sPnOptions 
//	variable	n = -1, nItems = 35
//	make /O /T /N=(nItems) 	$sPanelWvNm
//	wave  /T	tPn		= 	$sPanelWvNm
//
//	// Cave / Flaw :   No tabcontrol = empty  'Tabs'  must have   different number of spaces (no Tab, not the empty string )  to be recognised correctly
//	// Cave / Flaw :   For each item in  'Tabs'   there must be a  corresponding  'Blks'  entry  even if empty
//	// Cave / Flaw :	   Only tabulators can be used  for aligning the following columns, do not use spaces.... (maybe they are allowed...)
//	
//	//				Type	 NxL Pos MxPo OvS	Tabs	Blks	ModeName		RowTi			ColTi			ActionProc	XBodySz	FormatEntry	Initval		Visibility	SubHelp
//
//	n += 1;	tPn[ n ] =	"CB:	   1:	0:	2:	0:	°:	,:	1,°:	gbDisplay:		Display stimulus:		:			fDisplay_a():	:		:			:			:		:		"		// 	
//	n += 1;	tPn[ n ] =	"CB:	   1:	0:	2:	0:	°:	,:	1,°:	bAllBlocks:	All blocks:			:			fAllBlocks_a():	:		:			:			:		:		"		// 	
//	n += 1;	tPn[ n ] =	"SV:	   0:	1:	2:	0:	°:	,:	1,°:	gnDspBlock:	Block:			:			fDspBlock_a():	40:		%2d; 0,99,1:	:			:		:		"		// 	
//	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:	,:	,:	dum1b:		Range:			:			:			3:		:			:			:		:		"		//	single separator needs ','  for 'Blks'  and 'dummy' for 'Name'
//	n += 1;	tPn[ n ] =	"RAD: 1:	0:	1:	0:	°:	,:	1,°:	raRangeFS:	UFPE_fRangeFSLst()::			fRangeFS_a():	:		:			0010_1;~0:	:		Range:	"		//	1-dim vert radios
//	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:	,:	,:	dum1d:		Mode:			:			:			2:		:			:			:		:		"		//	single separator needs ','  for 'Blks'  and 'dummy' for 'Name'
//	n += 1;	tPn[ n ] =	"RAD: 1:	0:	1:	0:	°:	,:	1,°:	raCatStck:		UFPE_fCatStckLst():	:			fCatStck_a()::			:			0000_1;~0:	:		Mode:	"		//	1-dim vert radios
//	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:	,:	,:	dum1f:		:				:			:			:		:			:			:		:		"		//	single separator needs ',' 
//	n += 1;	tPn[ n ] =	"CB:	   1:	0:	1:	0:	°:	,:	1,°:	bShowBlank:	include blank periods:	:			fShowBlanks_a()::		:			:			:		:		"		// 	
//	n += 1;	tPn[ n ] =	"CB:	   1:	0:	1:	0:	°:	,:	1,°:	gbSameYAx:	use same Y-axis for Dacs:	:		fSameYAx_a():	:		:			:			:		:		"		// 	
//
//	redimension   /N=(n+1)	tPn
//End
//
// // To get all Helptopics for the above panel  execute from the command line   PnTESTAllTitlesOrHelptopics( 'root:uf:eva:', 'sde' )   or  PnTESTAllTitlesOrHelptopics( "root:uf:acq:", "sda" ) 
//// ->   Display stimulus;All blocks;Block;Range;all frames; all sweeps, all frames; first sweep, one frame; all sweeps,;Mode;catenate frames, stack frames;;include blank periods;use same Y-axis for Dacs;  
//
////--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//
//constant		kbACQ_STIMW_OS	= 0				// Stimulus display window offset : false for application acquisition		
//
//Function		fDisplay_a( s )
//	struct	WMCheckboxAction	&s
//	string  	sProcNm	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
// 	string  	sFo	 	= GetUserData(	s.win,  s.ctrlName,  "sFo" )								// as passed from 'PanelCheckbox()3'   e.g.  'root:uf:acq:std:' 
// 	string  	sF	 	= StringFromList( 2, sFo, ":" )										// e.g.  'root:uf:acq:std:'  ->  'acq' 
//	// printf "\t\t%s\t\t%s\t%s\t%s\t%s\t-> val: %g\t  \r",  UFCom_pd(sProcNm+"(s)",15),  UFCom_pd(s.CtrlName,31),	 UFCom_pd(sF,9), UFCom_pd(sFo,17), UFCom_pd(s.win,9),  s.checked
//	// only for debugging
//	// string 	rsFolder, rsVar, sGlobalRadioVar  = RadioButtonBaseName( s.ctrlName ) ;   SplitBaseIntoFolderandVar( sGlobalRadioVar, rsFolder, rsVar ) ;   nvar value = $rsFolder + rsVar
//	// printf "\tProc (RADIO)\t\tbutton is '%s'   ->'%s'  -> '%s' + '%s' ->\t%s = %d\r", s.ctrlname,  sGlobalRadioVar, rsFolder, rsVar, UFCom_pd(rsFolder+rsVar,23), value
//	if ( s.checked )
////		if ( cmpstr( sF, ksACQ ) == 0 )
//			UFPE_DisplayStimulus( sF, ksACQ_SD, kbACQ_STIMW_OS, UFPE_kNOINIT )				// **************   SPECIAL ONLY  in   ACQ 	*************
////		elseif ( cmpstr( sF, ks~EVAL ) == 0 )
////			InterpretScriptNoCedInit( sF )				//***************   SPECIAL ONLY  in  EVAL	**************  gbDoAcq = UFCom_FALSE
////		endif
//	else
//		string  	sStimWndName	= UFPE_StimWndNm( sF ) 
//		if ( WinType( sStimWndName ) == UFCom_WT_GRAPH )		// only if a graph window with that name exists...
//// Igor5
////			variable	xl, yt, xr, yb
////			UFCom_IsMinimized( sStimWndName, xl, yt, xr, yb  )		// get the window coordinates
////			UFCom_StoreWndLoc( sF + ":" + ksACQ_SD,  xl, yt, xr, yb ) 
////			MoveWindow 	/W=$sStimWndName   0 , 0 , 0 , 0		// hide window by minimizing it
//// Igor6
//			SetWindow $sStimWndName, hide = 1
//		endif
//	endif
//End
//
//
//
//Function		fAllBlocks_a( s )
//// sample: action proc with auto_built generic name
//	struct	WMCheckboxAction	&s
//	string  	sProcNm	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
// 	string  	sFo	 	= GetUserData(	s.win,  s.ctrlName,  "sFo" )								// as passed from 'PanelCheckbox()3'   e.g.  'root:uf:acq:std:' 
// 	string  	sF	 	= StringFromList( 2, sFo, ":" )										// e.g.  'root:uf:acq:std:'  ->  'acq' 
//	// printf "\t\t%s\t\t%s\t%s\t%s\t%s\t-> val: %g\t  \r",  UFCom_pd(sProcNm+"(s)",15),  UFCom_pd(s.CtrlName,31),	 UFCom_pd(sF,9), UFCom_pd(sFo,17), UFCom_pd(s.win,9),  s.checked
//	UFPE_StoreRetrieveStimDispSetts( s.ctrlname, s.checked, sF, ksACQ_SD )
//	UFPE_DisplayStimulus( sF, ksACQ_SD, kbACQ_STIMW_OS, UFPE_kNOINIT )
//	return	0
//End
//
//Function		fDspBlock_a( s )										
//	struct	WMSetVariableAction   &s
// 	string  	sFo	 	= GetUserData(	s.win,  s.ctrlName,  "sFo" )						// as defined/passed in 'PanelSetVar3()'
// 	string  	sF	 	= StringFromList( 2, sFo, ":" )								// e.g.  'root:uf:acq:std:'  ->  'acq' 
//	printf "\tProc (kSETVAR)\t generic name ()   folder: '%s'  '%s'  '%s'    control is '%s' \t-> val: %g    varnm:%s  \r", UFCom_ksROOT_UF_ , sFo,  sF, s.ctrlName, s.dval, s.vname
//	nvar		gnDspBlock = $"root:uf:" + sF + ":" + ksACQ_SD + ":gnDspBlock0000"
//	gnDspBlock		 = min( gnDspBlock, UFPE_eBlocks( sFo ) - 1 )			// if the user attempted too high a value, correct the value shown in the dialog box 
// print  "TODO........gnDspBlock( s )  "
//	UFPE_DisplayStimulus( sF, ksACQ_SD, kbACQ_STIMW_OS, UFPE_kNOINIT )
//	return	0
//End
//
//Function		fRangeFS_a( s )
//// Sample: if the proc field in a radio button in tPanel is empty then a proc with an auto-built name like this is called ( partial folder, underscore, variable base name)
//// Advantage: Empty proc field in radio button in tPanel.  No explicit call to  'fRadio_struct( s )'  is necessary. 
//	struct	WMCheckboxAction	&s
//	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
// 	string  	sFo	 	= GetUserData(	s.win,  s.ctrlName,  "sFo" )
// 	string  	sF	 	= StringFromList( 2, sFo, ":" )										// e.g.  'root:uf:acq:std:'  ->  'acq' 
//	//string 	rsFolder, rsVar, sGlobalRadioVar  = RadioButtonBaseName( s.ctrlName ) ;   SplitBaseIntoFolderandVar( sGlobalRadioVar, rsFolder, rsVar ) ;   
//	//nvar value = $rsFolder + rsVar;   printf "\tProc (generic RADIO)\t\tbutton is '%s'   ->'%s'  -> '%s' + '%s' ->\t%s = %d\r", s.ctrlname,  sGlobalRadioVar, rsFolder, rsVar, UFCom_pd(rsFolder+rsVar,23), value
//	UFPE_DisplayStimulus( sF, ksACQ_SD, kbACQ_STIMW_OS, UFPE_kNOINIT )
//End
//
//Function		fCatStck( s )
//	struct	WMCheckboxAction	&s
// 	string  	sFo	 	= GetUserData(	s.win,  s.ctrlName,  "sFo" )								// as passed from 'PanelCheckbox()3'   e.g.  'root:uf:acq:std:' 
// 	string  	sF	 	= StringFromList( 2, sFo, ":" )										// e.g.  'root:uf:acq:std:'  ->  'acq' 
//	//string 	rsFolder, rsVar, sGlobalRadioVar  = RadioButtonBaseName( s.ctrlName ) ;   SplitBaseIntoFolderandVar( sGlobalRadioVar, rsFolder, rsVar ) ;  
//	// nvar value = $rsFolder + rsVar;   printf "\tProc (generic RADIO)\t\tbutton is '%s'   ->'%s'  -> '%s' + '%s' ->\t%s = %d\r", s.ctrlname,  sGlobalRadioVar, rsFolder, rsVar, UFCom_pd(rsFolder+rsVar,23), value
//	UFPE_DisplayStimulus( sF, ksACQ_SD, kbACQ_STIMW_OS, UFPE_kNOINIT )
//End
//
//
//Function		fShowBlanks_a( s )	
//	struct	WMCheckboxAction	&s
//	string  	sProcNm	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
// 	string  	sFo	 	= GetUserData(	s.win,  s.ctrlName,  "sFo" )								// as passed from 'PanelCheckbox()3'   e.g.  'root:uf:acq:std:' 
// 	string  	sF	 	= StringFromList( 2, sFo, ":" )										// e.g.  'root:uf:acq:std:'  ->  'acq' 
//	printf "\t\t%s\t\t%s\t%s\t%s\t%s\t-> val: %g\t  \r",  UFCom_pd(sProcNm+"(s)",15),  UFCom_pd(s.CtrlName,31),	 UFCom_pd(sF,9), UFCom_pd(sFo,17), UFCom_pd(s.win,9),  s.checked
//	UFPE_DisplayStimulus( sF, ksACQ_SD, kbACQ_STIMW_OS, UFPE_kNOINIT )
//	return	0
//End
//
//Function		fSameYAx_a( s )
//	struct	WMCheckboxAction	&s
//	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
// 	string  	sFo	 	= GetUserData(	s.win,  s.ctrlName,  "sFo" )								// as passed from 'PanelCheckbox()3'   e.g.  'root:uf:acq:std:' 
// 	string  	sF	 	= StringFromList( 2, sFo, ":" )										// e.g.  'root:uf:acq:std:'  ->  'acq' 
//	printf "\t\t%s\t\t%s\t%s\t%s\t%s\t-> val: %g\t  \r",  UFCom_pd(sProcNm+"(s)",15),  UFCom_pd(s.CtrlName,31),	 UFCom_pd(sF,9), UFCom_pd(sFo,17), UFCom_pd(s.win,9),  s.checked
//	UFPE_DisplayStimulus( sF , ksACQ_SD, kbACQ_STIMW_OS, UFPE_kNOINIT )
//	return	0
//End
//
//
//
////---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
