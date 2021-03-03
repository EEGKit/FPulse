//
// FEvalStim.ipf
// 

strconstant		ksPN_NAME_SDEO	= "sdeo"			// Panel name   _and_  subfolder name  _and_  section keyword in INI file
static strconstant	ksPN_TITLE		= "Disp Stim Eval"	// Panel title


Function		DisplayOptionsStimulus_evo( xPos , yPos, nMode  )
	variable	xPos, yPos
	variable 	nMode
	string  	sFBase		= "root:uf:"
	string  	sFo			= ksEVO
	string  	sFSub		= sFo + ":"
	string  	sWin			= ksPN_NAME_SDEO 					
	string		sPnTitle		= ksPN_TITLE
	string		sDFSave		= GetDataFolder( 1 )						// The following functions do NOT restore the CDF so we remember the CDF in a string .
	PossiblyCreateFolder( sFBase + sFSub + sWin ) 
	SetDataFolder sDFSave										// Restore CDF from the string  value
	InitPanelDisplayStimulus_evo( sFBase + sFSub, sWin )					// Fills both big text waves  'sPnOptions' (=wPn)  in 'root:uf:aco:'  and  in  'root:uf:evo:'  with all information about the controls necessary to build the panel
	Panel3Sub(   sWin,	sPnTitle, 	sFBase + sFSub,   xPos, yPos , nMode ) 	// Compute the location of panel controls and the panel dimensions. Draw the panel displaying and hiding needed/unneeded controls
	LstPanels_Eva3Set( AddListItem( sWin, LstPanels_Eva3() ) )	// ??? todo_c could prevent adding more than once....
End


Function		InitPanelDisplayStimulus_evo( sF, sPnOptions )
// 	Same Function for  Acq  and  Eval .  The actions procs are also similar functions in  Acq  and  Eval , but the names differ... ( see  FPAcqScript.ipf  and  FPDispStim.ipf )
// 	Here are the samples united for  many  radio button  and  checkbox  varieties.....
	string  	sF, sPnOptions
	string  	sPanelWvNm	= sF + sPnOptions 
	variable	n = -1, nItems = 35
	make /O /T /N=(nItems) 	$sPanelWvNm
	wave  /T	tPn		= 	$sPanelWvNm

	//				Type	 NxL Pos MxPo OvS	Tabs	Blks	ModeName		RowTi			ColTi			ActionProc		XBodySz	FormatEntry	Initval		Visibility	SubHelp
	n += 1;	tPn[ n ] =	"CB:	   1:	0:	2:	0:	°:	,:	1,°:	gbDisplay:		Display stimulus:		:			fDisplay_evo():		:		:			:			:		:	"		// 	
	n += 1;	tPn[ n ] =	"CB:	   1:	0:	2:	0:	°:	,:	1,°:	bAllBlocks:	All blocks:			:			fAllBlocks_evo():	:		:			:			:		:	"		// 	
	n += 1;	tPn[ n ] =	"SV:	   0:	1:	2:	0:	°:	,:	1,°:	gnDspBlock:	Block:			:			fDspBlock_evo():	40:		%2d; 0,99,1:	:			:		:	"		// 	
	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:	,:	,:	dum1b:		Range:			:			:				:		:			:			:		:	"		//	single separator needs ','  for 'Blks'  and 'dummy' for 'Name'
	n += 1;	tPn[ n ] =	"RAD: 1:	0:	1:	0:	°:	,:	1,°:	raRangeFS:	fRangeFSLst():	:			fRangeFS_evo():	:		:			0010_1;~0:	:		:	"		//	1-dim vert radios
	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:	,:	,:	dum1d:		Mode:			:			:				:		:			:			:		:	"		//	single separator needs ','  for 'Blks'  and 'dummy' for 'Name'
	n += 1;	tPn[ n ] =	"RAD: 1:	0:	1:	0:	°:	,:	1,°:	raCatStck:		fCatStckLst():	:			fCatStck_evo():		:		:			0000_1;~0:	:		:	"		//	1-dim vert radios
	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:	,:	,:	dum1f:		:				:			:				:		:			:			:		:	"		//	single separator needs ',' 
	n += 1;	tPn[ n ] =	"CB:	   1:	0:	1:	0:	°:	,:	1,°:	bShowBlank:	include blank periods:	:			fShowBlanks_evo():	:		:			:			:		:	"		// 	
	n += 1;	tPn[ n ] =	"CB:	   1:	0:	1:	0:	°:	,:	1,°:	gbSameYAx:	use same Y-axis for Dacs:	:		fSameYAx_evo():	:		:			:			:		:	"		// 	

	redimension   /N=(n+1)	tPn
End

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function		fDisplay_evo( s )
	struct	WMCheckboxAction &s
 	string  	sF	 	= ksEVO
	string  	sWin		= ksPN_NAME_SDEO 					
	if ( s.checked )
		InterpretScript_( sF, sWin, kNOACQ )				
	else
		string  	sStimWndName	= StimWndNm( sF ) 
		if ( WinType( sStimWndName ) == kGRAPH )				// only if a graph window with that name exists...
			variable	xl, yt, xr, yb
			IsMinimized( sStimWndName, xl, yt, xr, yb  )				// get the window coordinates
			StoreWndLoc( sF + ":" + sWin,  xl, yt, xr, yb ) 
			MoveWindow 	/W=$sStimWndName   0 , 0 , 0 , 0		// hide window by minimizing it
		endif
	endif
End

Function		fAllBlocks_evo( s )
// sample: action proc with auto_built generic name
	struct	WMCheckboxAction &s
 	string  	sF	 	= ksEVO
	string  	sWin		= ksPN_NAME_SDEO 					
	// printf "\t\t%s\t\t%s\t%s\t%s\t-> val: %g\t  \r",   pd(s.CtrlName,31),	 pd(sF,9), pd(sFo,17), pd(s.win,9),  s.checked
	StoreRetrieveStimDispSettings(  sF, sWin, s.checked )
	DisplayStimulus1( sF, sWin, kNOINIT )
	return	0
End

Function		fDspBlock_evo( s )	
//									// valid for  kbSUBFOLDER_IN_ACTIONPROC_NM_SV = 0 
//Function		std_gnDspBlock( s )			// valid for  kbSUBFOLDER_IN_ACTIONPROC_NM_SV = 1 
	struct	WMSetVariableAction   &s
 	string  	sF	 	= ksEVO
	string  	sWin		= ksPN_NAME_SDEO 					
	nvar		gnDspBlock = 	$"root:uf:" + sF + ":" + ksPN_NAME_SDEO + ":gnDspBlock0000"
	wave	wG		= 	$"root:uf:" + sF + ":keep:wG"
	gnDspBlock		 = min( gnDspBlock, eBlocks( wG ) - 1 )			// if the user attempted too high a value, correct the value shown in the dialog box 
	DisplayStimulus1( sF, sWin, kNOINIT )
	return	0
End

Function		fRangeFS_evo( s )
// Sample: if the proc field in a radio button in tPanel is empty then a proc with an auto-built name like this is called ( partial folder, underscore, variable base name)
// Advantage: Empty proc field in radio button in tPanel.  No explicit call to  'fRadio_struct( s )'  is necessary. 
	struct	WMCheckboxAction &s
	string  	sF	 	= ksEVO
	string  	sWin		= ksPN_NAME_SDEO 					
	DisplayStimulus1( sF, sWin, kNOINIT )
End

Function		fCatStck_evo( s )
	struct	WMCheckboxAction &s
	string  	sF	 	= ksEVO
	string  	sWin		= ksPN_NAME_SDEO 					
	DisplayStimulus1( sF, sWin, kNOINIT )
End

Function		fShowBlanks_evo( s )					// SAMPLE : DO NOT DELETE
// sample: procedure with special name
	struct	WMCheckboxAction &s
	string  	sF	 	= ksEVO
	string  	sWin		= ksPN_NAME_SDEO 					
	// printf "\t\t\t%s\t%s\t%s\t%s\t-> val: %g\t  \r",  pd(s.CtrlName,31),	 pd(sF,9), pd(sFo,17), pd(s.win,9),  s.checked
	fChkbox( s.ctrlName, s.checked )					// sets Help : needed here as this action proc name is NOT auto-derived from the control name
	DisplayStimulus1( sF, sWin, kNOINIT )
	return	0
End

Function		fSameYAx_evo( s )
// sample: action proc with auto_built generic name
	struct	WMCheckboxAction &s
	string  	sF	 	= ksEVO
	string  	sWin		= ksPN_NAME_SDEO 					
	// printf "\t\t\t%s\t%s\t%s\t%s\t-> val: %g\t  \r",   pd(s.CtrlName,31),	 pd(sF,9), pd(sFo,17), pd(s.win,9),  s.checked
	DisplayStimulus1( sF , sWin, kNOINIT )
	return	0
End

