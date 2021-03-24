//
//  FP_DebugPrint.ipf 
// 
#pragma rtGlobals=1							// Use modern global access method.

//===============================================================================================================================
//   OUT  FUNCTIONS  needed  for DEBUG  PRINTING  ( belong to  FPTest.ipf   but are included here to avoid linker errors when  FPTest.ipf  is not included  in the Release version

constant	kIGOR_MAXSTRING = 253				//  IGOR help (string too long error)  claims this to be 400!
static constant			NAM = 1		// must be same as in Dialog.ipf !	


//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//   NOTE 	:   TEST  AND  DEBUG  FUNCTIONS  can only be  accessed by developer and  power user  by entering  ''PnDebugPrint()'   in the command line
//
// 050530  To avoid  NVAR checking errors this code is required not only in DEBUG but also in RELEASE mode  so it can unfortunately not be placed in FPTest.ipf  but is placed here in FPulseMain.ipf  instead. It is NOT needed in EVAL. 
//		  Consequence: Although the panel should not be accessible in RELEASE mode it actually is accessible  but only indirectly by entering  ''PnDebugPrint()'   in the command line. Also the code is but should not be visible.

static  strconstant  csDEBUG_DEPTHALL	= " Nothing, Modules, Functions,"
static  strconstant  csDEBUG_DEPTHSEL	= " Nothing, Functions, Loops, Details, Everything,"
static  strconstant  csDEBUG_SECTIONS	= " Timer, ShowLines, ShowKeys, ShowIO, ShowVal, ShowAmpTim, ShowEle, Expand, Digout, OutElems, Telegraph, Ced, AcqDA, AcqAD, CfsWr, DispDurAcq, WndArrange," 
constant  		kDBG_TIMER=1,  kDBG_SHOWLINES=2,  kDBG_SHOWKEYS=4,  kDBG_SHOWIO=8,  kDBG_SHOWVAL=16,  kDBG_SHOWAMPTIM=32,  kDBG_SHOWELE=64,  kDBG_EXPAND=128, kDBG_DIGOUT=256 
constant		kDBG_OUTELEMS=512,  kDBG_TELEGRAPH=1024,  kDBG_CED=2048,  kDBG_ACQDA=4096,  kDBG_ACQAD=8192,  kDBG_CFSWR=16384,  kDBG_DISPDURACQ=32768,  kDBG_WNDARRANGE=65536


// for debug print options
static strconstant	ksDLG_			= "dlg:"		
static strconstant	ksDEBUG			= "deb"			// gn	"debug" 


Function		PnDebugPrint()
	PanelDebugPrint()
End
	
Function		PanelDebugPrint()
	string  	sFBase		= ksROOTUF_
	string  	sFSub		= ksDLG_	
	string  	sWin			= ksDEBUG 
	string		sPnTitle		= "Debug Print"
	stInitPanelDebugPrint(  ksROOTUF_ + ksDLG_,  ksDEBUG )			// normally this code is required here but in this case it has already been executed in  'CreateGlobals()'  above
	Panel3Sub(   sWin, sPnTitle,	sFBase + sFSub,  0, 0, kPANEL_DRAW )	// Compute the location of panel controls and the panel dimensions. Draw the panel displaying and hiding needed/unneeded controls.  Prevents closing
End

static Function	stInitPanelDebugPrint( sF, sPnOptions )
	string  	sF, sPnOptions
	string		sDFSave		= GetDataFolder( 1 )					// The following functions do NOT restore the CDF so we remember the CDF in a string .
	PossiblyCreateFolder( sF + sPnOptions ) 	
	SetDataFolder sDFSave									// Restore CDF from the string  value
	string		sPanelWvNm = sF + sPnOptions
	variable	n = -1, nItems = 100
	 printf "\t\tInitPanelDebugPrint( '%s',  '%s' ) \r", sF, sPnOptions 
	make /O /T /N=(nItems)	$sPanelWvNm
	wave  /T	tPn	=		$sPanelWvNm
	
	//				Type	 NxL Pos MxPo OvS  Tabs Blks  Mode	Name			RowTi			ColTi		ActionProc	XBodySz	FormatEntry	Initval			Visibility	SubHelp
	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:	,:	,:		dum0:			Depth(all) :		:			:				:	:			:				:								"	//	single separator needs ',' 
	n += 1;	tPn[ n ] =	"RAD: 1:	0:	1:	0:	°:	,:	1,°:		raDebgGen:		fDebgGenLst():	:			:				:	:			0010_1~0:		:		Debug print depth all:		"	//	single button
	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:	,:	,:		dum2:			Depth(selected) :	:			:				:	:			:				:		Debug print depth selected:"	//	single button
	n += 1;	tPn[ n ] =	"RAD: 1:	0:	1:	0:	°:	,:	1,°:		raDebgSel:		fDebgSelLst():	:			:				:	:			0020_1~0:		:		Debug print depth selected:"	//	single button
	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:	,:	,:		dum4:			Section :			:			:				:	:			:				:		Debug print sections:		"		// multi-row checkboxes
	n += 1;	tPn[ n ] =	"CB:	   1:	0:	1:	0:	°:	,:	1,°:		Section:			fSectionLst():		:			:				:	:			0030_1;0050_1~0::		Debug print sections:		"		// multi-row checkboxes
	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	°:	,:	1,°:		buSelAll:			Select all:		:			fDebugSelectAll():	:	:			:				:		Debug print select all:		"		//	single button
	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	°:	,:	1,°:		buDeselAll:		Deselect all:		:			fDebugDeselectAll()::	:			:				:		Debug print deselect all:	"		//	single button
	redimension  /N = (n+1)	tPn
End

Function		DebugDepthGen()
//	nvar		DepthGen	= root:uf:dlg:gRadDebgGen
	nvar	  /Z	DepthGen	= root:uf:dlg:deb:raDebgGen00
	variable	bDebg	= nvar_exists( DepthGen )
	return	bDebg  ?  DepthGen  :  0 
End

Function		DebugDepthSel()
//	nvar		DepthGen	= root:uf:dlg:gRadDebgSel
	nvar	  /Z	DepthSel	= root:uf:dlg:deb:raDebgSel00
	variable	bDebg	= nvar_exists( DepthSel )
	return	bDebg  ?  DepthSel  :  0 
End

Function		DebugSection()
	nvar   /Z	DebgSct		= root:uf:dlg:deb:Section00
	variable	bDebgExists	= nvar_exists( DebgSct )
	// printf "\t\t\tDebugSection()   'root:uf:dlg:deb:Section00'  does %s exist, returning %d \r",  SelectString( bDebgExists, "NOT", "" ), DebgSct
	return	bDebgExists  ?  DebgSct  :  0 
End

Function	/S	fDebgGenLst( sBaseNm, sF, sWin )
	string  	sBaseNm, sF, sWin  
	return	csDEBUG_DEPTHALL
End
Function	/S	fDebgSelLst( sBaseNm, sF, sWin )
	string  	sBaseNm, sF, sWin 
	return	csDEBUG_DEPTHSEL
End
Function	/S	fSectionLst( sBaseNm, sF, sWin )
	string  	sBaseNm, sF, sWin 
	return	csDEBUG_SECTIONS	
End


Function		fDebugSelectAll( s )
	struct	WMButtonAction	&s
	PnRadioCheck(   s.win, "root_uf_dlg_deb_raDebgSel0020" ) 	// Turn 'Loop' sel radio button on, all others OFF	(turning 'Everything' on would give too much information)
	PnChkboxSetAll(  s.win, "root_uf_dlg_deb_Section0000",   ON )	// Turn ON all = ShowIO, ShowEle, Expand, CFS...
End
Function		fDebugDeselectAll( s ) 
//  we must turn EVERYTHING OFF (especially ..SelFunc,..SelLoop, ..SelAll) to gain the speed advantage
	struct	WMButtonAction	&s
	PnRadioCheck(   s.win, "root_uf_dlg_deb_raDebgSel0000" ) 	// Turn 'Nothing' sel radio button on, all others OFF	
	PnChkboxSetAll(  s.win, "root_uf_dlg_deb_Section0000",   OFF )	// Turn OFF all = ShowIO, ShowEle, Expand, CFS...
End



