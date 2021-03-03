////
////  UF_AcqDebugPrint.ipf 
////
// 
//#pragma rtGlobals=1							// Use modern global access method.
//
////===============================================================================================================================
//// NEW DEBUG PRINTING  070401
////
//// How it works:
//// In any source file (including Common files)  calls to  'UFCom_DebugCreateFolderAndVar()'  create a global variable in the folder 'dbgprint' , e.g. 'gMaxControlWidth' and set it to an initial value (usually 0 ).
//// A hidden control panel is built from all variables in the folder 'dbgprint'  (checkbox, setvariable or radio buttons).  Must be updated if variables in  'dbgprint'  are added or deleted.
//// The power user can display the normally hidden panel and change the values.
//// Calls to  'UFCom_DebugVar()'  retrieve the debug print  settings and  and can be used to control how much is printed
//
//// todo: radio buttons
//// default value must set checkbox state  
//
////static strconstant	ksF_DEBUGPRINT	= "dbgprint"
////
////
////
////Function		UFCom_DebugPrintPrepare( lstVars )
////// Creates debug print variables as defined in  'lstVars' and initialise them to 0.  
////// Creating all debug print variables here in 1 step is cleaner than creating them 1 by 1 later when they are accessed for the first time (this can also be done but then the panel must adjust every time a new variable is added)
////	string  	lstVars
////	variable	n, nItems = ItemsInList( lstVars )
////	for ( n = 0; n < nItems; n += 1 )
////		string  sVarNm	= StringFromList( n, lstVars )
////		//UFCom_DebugCreateFolderAndVar( sVarNm, 0 )
////		UFCom_DebugVar( sVarNm )
////	endfor
////End 
////
////
//////Function		UFCom_DebugCreateFolderAndVar( sVarNm, nValue )
//////// Creates 1 debug print variable and initialises it to 0.  If required the folder is also built.  
//////// Useful for adding single variables not belonging to a package like 'FPulse' but belonging to a 'common' function e.g. the widest control  icomputed in UFCom_Panel.ipf
//////	string  	sVarNm
//////	variable	nValue 
////////	UFCom_PossiblyCreateFolder( UFCom_ksROOT_UF_ + ksF_DEBUGPRINT ) 		// We accept the speed penalty as the variables are created seldom.
//////	nvar /Z	gVar	= $UFCom_ksROOT_UF_ + ksF_DEBUGPRINT + ":" + sVarNm
//////	if ( nvar_exists( gVar ) )
//////		return	gVar							// do not initialise if the variable exists already
//////	else
//////		UFCom_PossiblyCreateFolder( UFCom_ksROOT_UF_ + ksF_DEBUGPRINT ) 		// We accept the speed penalty as the variables are created seldom.
//////		variable /G   $UFCom_ksROOT_UF_ + ksF_DEBUGPRINT + ":" + sVarNm	= nValue
//////		return	nValue
//////	endif
//////End 
////
////
////Function		UFCom_DebugVar( sVarNm )
////// Retrieve the value of the global debug variable.  If the variable has not yet been created then create it and set its initial value to zero.  
////// However, the debug folder must already exist as 'UFCom_PossiblyCreateFolder()'  would impose a big speed penalty.
////	string  	sVarNm
////	variable	nValue	= 0		// initial value if the variable does not yet exist
////	nvar /Z	gVar	= $UFCom_ksROOT_UF_ + ksF_DEBUGPRINT + ":" + sVarNm
////	if ( nvar_exists( gVar ) )
////		return	gVar
////	else
////		UFCom_PossiblyCreateFolder( UFCom_ksROOT_UF_ + ksF_DEBUGPRINT ) 		// We accept the speed penalty as the variables are created seldom.
////		variable /G   $UFCom_ksROOT_UF_ + ksF_DEBUGPRINT + ":" + sVarNm	= nValue
////		//UFCom_InternalWarning( "Global variable does not exist : '" +  UFCom_ksROOT_UF_ + ksF_DEBUGPRINT + ":" + sVarNm + "' .  Returning " + num2str( nValue ) + " ." )
////		// PnDebugPrint()					// Append the newly created variable to the panel.  This should take into account hidden/visible state. (It is better to create all vars in 1 step at the beginning (->UFCom_DebugPrintPrepare())
////		return	nValue
////	endif
////End 
////
////
////Function	/S	fVarsLst( sBaseNm, sF, sWin )
////	string  	sBaseNm, sF, sWin  
////
////	string		sVarNm, lstVars = ""
////	variable 	index = 0
////	do
////		sVarNm = GetIndexedObjName( UFCom_ksROOT_UF_ + ksF_DEBUGPRINT, 2, index)	// 2 : variables
////		if ( strlen( sVarNm ) == 0 )
////			break
////		endif
////		lstVars += " " + sVarNm + "," 
////		index += 1
////	while( 1 )
////	printf "\t\tfVarsLst( %s  %s  %s )  -> '%s'  returns '%s' \r", sBaseNm, sF, sWin, UFCom_ksROOT_UF_ + ksF_DEBUGPRINT, lstVars
////	return	lstVars
////End
////
////
////Function		fVarsCBAction( s )
////	struct	WMCheckboxAction	&s
////	variable	len		= strlen( s.Ctrlname )
////	variable	row		= str2num( (s.Ctrlname)[ len-2, len-2 ] )
////	string  	sVarNm	= UFCom_RemoveWhiteSpace( StringFromList( row, fVarsLst( "","","" ) , "," ) )
////	nvar		gValue	= $UFCom_ksROOT_UF_ + ksF_DEBUGPRINT + ":" + sVarNm
////	gValue	= s.checked
////	printf "\t\tfVarsCBAction() %s  -> index:%d -> '%s' -> value:%2d  \r", s.Ctrlname, row, sVarNm, gValue
////End
////
////
//
////===============================================================================================================================
////   NOTE 	:   TEST  AND  DEBUG  FUNCTIONS  can only be  accessed by developer and  power user  by entering  'PnDebugPrint()'   or  'PanelDebugPrint()'  in the command line
////
//// 050530  To avoid  NVAR checking errors this code is required not only in DEBUG but also in RELEASE mode  so it can unfortunately not be placed in UF_Test.ipf  but is placed here in UF_PulseMain.ipf  instead. It is NOT needed in EVAL. 
////		  Consequence: Although the panel should not be accessible in RELEASE mode it actually is accessible  but only indirectly by entering  ''PnDebugPrint()'   in the command line. Also the code is but should not be visible.
//
//static  strconstant  csDEBUG_DEPTHALL	= " Nothing, Modules, Functions,"
//static  strconstant  csDEBUG_DEPTHSEL	= " Nothing, Functions, Loops, Details, Everything,"
//
////static  strconstant  csDEBUG_SECTIONS	= " Timer, ShowLines, ShowKeys, ShowIO, ShowVal, ShowAmpTim, ShowEle, Expand, Digout, OutElems, Telegraph, Ced, AcqDA, AcqAD, CfsWr, DispDurAcq, WndArrange," 
////constant  		UFCom_kDBG_TIMER=1,  UFCom_kDBG_SHOWLINES=2,  UFCom_kDBG_SHOWKEYS=4,  UFCom_kDBG_SHOWIO=8,  UFCom_kDBG_SHOWVAL=16,  UFCom_kDBG_SHOWAMPTIM=32,  UFCom_kDBG_SHOWELE=64,  UFCom_kDBG_EXPAND=128, UFCom_kDBG_DIGOUT=256 
////constant		UFCom_kDBG_OUTELEMS=512,  UFCom_kDBG_TELEGRAPH=1024,  UFCom_kDBG_CED=2048,  UFCom_kDBG_ACQDA=4096,  UFCom_kDBG_ACQAD=8192,  UFCom_kDBG_CFSWR=16384,  UFCom_kDBG_DISPDURACQ=32768,  UFCom_kDBG_WNDARRANGE=65536
//
//
//// for debug print options
//static strconstant	ksDLG_			= "dlg:"		
//static strconstant	ksDEBUG			= "deb"			// gn	"debug" 
//
//
//Function		PnDebugPrint()
//	PanelDebugPrint()
//End
//	
//static Function		PanelDebugPrint()
//	string  	sFBase		= UFCom_ksROOT_UF_
//	string  	sFSub		= ksACQ_//ksDLG_	
//	string  	sWin			= ksDEBUG 
//	string		sPnTitle		= "Debug Print"
//	InitPanelDebugPrint(  UFCom_ksROOT_UF_ + sFSub,  ksDEBUG )							// normally this code is required here but in this case it has already been executed in  'CreateGlobals()'  above
//
//	variable	xPosPercent = 85, yPosPercent = 95, xSzPts = 50, ySzPts = 450, rxPosPts, ryPosPts		// Position the panel in percent of screen area. This is only approximately as long as the size of the panel  (=xSzPts, ySzPts)  is only guessed...
//	UFCom_Panel3PositionIt( xPosPercent, yPosPercent, xSzPts, ySzPts, rxPosPts, ryPosPts )			// Compute approximate panel position and pass it back in 'rxPosPts' and 'ryPosPts'		
//	UFCom_Panel3Sub_( sWin, sPnTitle, sFBase+sFSub, rxPosPts, ryPosPts, 1, UFCom_kPANEL_DRAW )	// Compute the panel dimensions. Draw the panel displaying and hiding needed/unneeded controls
//End
//
//static Function	InitPanelDebugPrint( sF, sPnOptions )
//	string  	sF, sPnOptions
//	string		sDFSave		= GetDataFolder( 1 )					// The following functions do NOT restore the CDF so we remember the CDF in a string .
//	UFCom_PossiblyCreateFolder( sF + sPnOptions ) 	
//	SetDataFolder sDFSave									// Restore CDF from the string  value
//	string		sPanelWvNm = sF + sPnOptions
//	variable	n = -1, nItems = 100
//	 printf "\t\tInitPanelDebugPrint( '%s',  '%s' ) \r", sF, sPnOptions 
//	make /O /T /N=(nItems)	$sPanelWvNm
//	wave  /T	tPn	=		$sPanelWvNm
//	
//	//				Type	 NxL Pos MxPo OvS	Tabs		Blks		Mode		Name			RowTi		ColTi			ActionProc	XBodySz	FormatEntry	Initval		Visibility	SubHelp
//	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:		,:		,:			dum0:			Depth(all) :		:			:				:	:			:			:						"	//	single separator needs ',' 
//	n += 1;	tPn[ n ] =	"RAD: 1:	0:	1:	0:	°:		,:		1,°:			raDebgGen:		fDebgGenLst():	:			:				:	:			0010_1~0:	:		Debug print depth all:	"	//	single button
//	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:		,:		,:			dum2:			Depth(selected) ::			:				:	:			:			:		Debug print depth selected:"	//	single button
//	n += 1;	tPn[ n ] =	"RAD: 1:	0:	1:	0:	°:		,:		1,°:			raDebgSel:		fDebgSelLst():	:			:				:	:			0020_1~0:	:		Debug print depth selected:"	//	single button
//// 070401
////	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:		,:		,:			dum4:			Section :		:			:				:	:			:			:		Debug print sections:	"		// 
////	n += 1;	tPn[ n ] =	"CB:	   1:	0:	1:	0:	°:		,:		1,°:			Section:			fSectionLst():	:			:				:	:			0030_1;0050_1~0::		Debug print sections:	"		// multi-row checkboxes
////	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	°:		,:		1,°:			buSelAll:			Select all:		:			fDebugSelectAll():	:	:			:			:		Debug print select all:	"		//	single button
////	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	°:		,:		1,°:			buDeselAll:		Deselect all:	:			fDebugDeselectAll():	:	:			:			:		Debug print deselect all:	"		//	single button
//
//	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:		,:		,:			dum6:			Section :		:			:				:	:			:			:		Sections Debug print:	"		//
////	n += 1;	tPn[ n ] =	"CB:	   1:	0:	1:	0:	°:		,:		1,°:			DebugPrint:		fVarsLst():		:			fVarsCBAction():		:	:			~0:			:		New Debug print:	"		// multi-row checkboxes, initial values must be zero to correspond with global vars
//
//	n += 1;	tPn[ n ] =	"CB:	   1:	0:	1:	0:	°:		,:		1,°:			FoDbgPrt:			UFCom_DbgSpecLst()::		UFCom_DbgSpecCB()::	:			~0:			:		Specific Debug print:	"		// multi-row checkboxes, initial values must be zero to correspond with global vars
//	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:		,:		,:			dum8:			Common :		:			:				:	:			:			:		Sections Debug print:	"		//
//	n += 1;	tPn[ n ] =	"CB:	   1:	0:	1:	0:	°:		,:		1,°:			DbgPrCom:		UFCom_DbgComLst()::		UFCom_DbgComCB()::	:			~0:			:		Common Debug print:	"		// multi-row checkboxes, initial values must be zero to correspond with global vars
//
//	redimension  /N = (n+1)	tPn
//End
//
////Function		DebugDepthGen()
//////	nvar		DepthGen	= root:uf:dlg:gRadDebgGen
////	nvar	  /Z	DepthGen	= root:uf:dlg:deb:raDebgGen00
////	variable	bDebg	= nvar_exists( DepthGen )
////	return	bDebg  ?  DepthGen  :  0 
////End
////
////Function		DebugDepthSel()
//////	nvar		DepthGen	= root:uf:dlg:gRadDebgSel
////	nvar	  /Z	DepthSel	= root:uf:dlg:deb:raDebgSel00
////	variable	bDebg	= nvar_exists( DepthSel )
////	return	bDebg  ?  DepthSel  :  0 
////End
//
////Function		DebugSection()
////	nvar   /Z	DebgSct		= root:uf:dlg:deb:Section00
////	variable	bDebgExists	= nvar_exists( DebgSct )
////	// printf "\t\t\tDebugSection()   'root:uf:dlg:deb:Section00'  does %s exist, returning %d \r",  SelectString( bDebgExists, "NOT", "" ), DebgSct
////	return	bDebgExists  ?  DebgSct  :  0 
////End
//
//Function	/S	fDebgGenLst( sBaseNm, sF, sWin )
//	string  	sBaseNm, sF, sWin  
//	return	csDEBUG_DEPTHALL
//End
//
//Function	/S	fDebgSelLst( sBaseNm, sF, sWin )
//	string  	sBaseNm, sF, sWin 
//	return	csDEBUG_DEPTHSEL
//End
//
//// 070401
////Function	/S	fSectionLst( sBaseNm, sF, sWin )
////	string  	sBaseNm, sF, sWin 
////	return	csDEBUG_SECTIONS	
////End
////
////Function		fDebugSelectAll( s )
////	struct	WMButtonAction	&s
////	UFCom_PnRadioCheck(   s.win, "root_uf_dlg_deb_raDebgSel0020" ) 	// Turn 'Loop' sel radio button on, all others OFF	(turning 'Everything' on would give too much information)
////	UFCom_PnChkboxSetAll(  s.win, "root_uf_dlg_deb_Section0000",   UFCom_kON )	// Turn ON all = ShowIO, ShowEle, Expand, CFS...
////End
////
////Function		fDebugDeselectAll( s ) 
//////  we must turn EVERYTHING OFF (especially ..SelFunc,..SelLoop, ..SelAll) to gain the speed advantage
////	struct	WMButtonAction	&s
////	UFCom_PnRadioCheck(   s.win, "root_uf_dlg_deb_raDebgSel0000" ) 	// Turn 'Nothing' sel radio button on, all others OFF	
////	UFCom_PnChkboxSetAll(  s.win, "root_uf_dlg_deb_Section0000",   UFCom_kOFF )	// Turn OFF all = ShowIO, ShowEle, Expand, CFS...
////End
//
//
//
