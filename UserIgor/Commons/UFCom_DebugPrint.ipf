//
//  UCom_DebugPrint.ipf 
//
 
#pragma rtGlobals=1							// Use modern global access method.

//===============================================================================================================================
//
// 	Allows to turn all debug print statements belonging to a specific code section ON and OFF.
// 	Works for any application / project.
//	In the application(s) just 1 simple line is required to construct AND retrieve the global variable  e.g.  if ( UFCom_DebugVar( "acq", "ShowStep1" ) ) 

// How it works:
// 	This checkbox is used to turn debug print statements on and off.
//	If there is no automatical call to PanelDebugPrint( "PanelName" )  during the application initialisation there must be a button for this purpose or this function must be executed by the command line.
//	Additional debug prints can be added at any time at any place by inserting lines like
//		if ( UFCom_DebugVar( "acq", "ShowStep1" ) ) 
//			printf "\t\t variable1: %g \r", var1
//		endif 
//	To introduce the new debug variable   "ShowStep1"  the button  'Update Vars'  in the debug panel must be executed.
//	You may optionally enclose it in  #if dDEBUG  #endif   to avoid any possible speed penalty in the Release version

// Note:
// 	Since 2010-01-20 there is 1 debug print panel for each application. This requires passing  the application folder also.   The special folders 'com'  and  'fpe'  also have an extra debug panel.


#include "UFCom_ColorsAndGraphs" 				// UFCom_PossiblyKillPanel()
#include "UFCom_DataFoldersAndGlobals"			// UFCom_PossiblyCreateFolder()
#include "UFCom_Panel" 				

//static strconstant	ksDEBUGVARS		= "dbgvars"

static strconstant	ksDEBUG				= "dbg"			// Panel  AND  Folder base name  				->  'dbgacq'  ,  'dbgeva' ...
static strconstant	ksDEBUG_VARBASE	= "debug"//"dbgPrt"			// the base name of the parallel checkboxes Panel  	->  debug0000, debug0010, debug0020

static strconstant	klstDEBUG_COLS		= "0,1,2,3,"		// the 4. index 3, is required only in acq, can perhaps be eliminated  by  a construct like  &4   &&   &8  .  MUST ALSO ADJUST panel  column MxPo


//Function		fDbgPrint( s ) 
//	struct	WMButtonAction	&s
//	nvar		bState	= $ReplaceString( "_", s.ctrlname, ":" )	// the underlying button variable name is derived from the control name
//	string  	sFo		= StringFromList( 2,  s.ctrlname, "_" )		// e.g.  'acq' ,  'eva'  or 'best'
//	variable	xPercent	= 80
//	DisplayHideDebugPanel( sFo, xPercent, bState ) 
//End


Function		fDbgCom( s ) 
	struct	WMButtonAction	&s
	nvar		bState	= $ReplaceString( "_", s.ctrlname, ":" )	// the underlying button variable name is derived from the control name
	string  	sFo		= "com"
	variable	xPercent	= 86
	UFCom_DisplayHideDebugPanel( sFo, xPercent, bState ) 
End


Function		fDbgFpe( s ) 
	struct	WMButtonAction	&s
	nvar		bState	= $ReplaceString( "_", s.ctrlname, ":" )	// the underlying button variable name is derived from the control name
	string  	sFo		= "fpe"
	variable	xPercent	= 92
	UFCom_DisplayHideDebugPanel( sFo, xPercent, bState ) 
End


//static Function DisplayHideDebugPanel( sFo, xPercent, bState ) 
 Function		UFCom_DisplayHideDebugPanel( sFo, xPercent, bState ) 
	string  	sFo
	variable	xPercent, bState
	string  	sPnNm	= DebugPanelNm( sFo )
	// printf "\t\t\t\t%s\t\tsFo:\t\tPnName:\t%s\tvalue:%2d   \t \r",  sFo, UFCom_pd( sPnNm, 9 ), bState		
	if ( bState )
		PanelDebugPrint( sFo, sPnNm, xPercent )						// rebuild the DebugPrint panel
	else
		UFCom_PossiblyKillPanel( sPnNm ) 
	endif
End


static Function	PanelDebugPrint( sFo, sPnNm, xPosPercent )
	string  	sFo , sPnNm		//=  'Debug'  
	variable	xPosPercent
	string  	sFSub_ 	= sFo + ":"
	string  	sFBase	= UFCom_ksROOT_UF_
	string		sPnTitle	= "Debug " + sFo

	InitPanelDebugPrint(  UFCom_ksROOT_UF_ + sFSub_,  sPnNm )		

	variable	yPosPercent = 0, xSzPts = 50, ySzPts = 450, rxPosPts, ryPosPts		// Position the panel in percent of screen area. This is only approximately as long as the size of the panel  (=xSzPts, ySzPts)  is only guessed...
	UFCom_Panel3PositionIt( xPosPercent, yPosPercent, xSzPts, ySzPts, rxPosPts, ryPosPts )			// Compute approximate panel position and pass it back in 'rxPosPts' and 'ryPosPts'		
	UFCom_Panel3Sub_( sPnNm, sPnTitle, sFBase+sFSub_, rxPosPts, ryPosPts, 1, UFCom_kPANEL_DRAW)	// Compute the panel dimensions. Draw the panel displaying and hiding needed/unneeded controls

	UFCom_LstPanelsAdd( sFo, "", sPnNm )
End


static Function	InitPanelDebugPrint( sF, sPnOptions )
	string  	sF, sPnOptions
	string		sDFSave		= GetDataFolder( 1 )					// The following functions do NOT restore the CDF so we remember the CDF in a string .
	UFCom_PossiblyCreateFolder( sF + sPnOptions ) 	
	SetDataFolder sDFSave									// Restore CDF from the string  value
	string		sPanelWvNm = sF + sPnOptions
	variable	n = -1, nItems = 100
	// printf "\t\tInitPanelDebugPrint( '%s',  '%s' ) \r", sF, sPnOptions 
	make /O /T /N=(nItems)	$sPanelWvNm
	wave  /T	tPn	=		$sPanelWvNm
	variable  nCols	= ItemsInList( klstDEBUG_COLS, "," )
	
	//				Type	 NxL Pos 	MxPo 		OvS	Tabs		Blks		Mode		Name			RowTi			ColTi			ActionProc		XBodySz FormatEntry Initval	Visibility	SubHelp
	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:			0:	°:		,:		1,°:			dum20:			:				:			:				:		:		:		:		:"	//
	n += 1;	tPn[ n ] =	"CB:	   1:	0:"+num2str(nCols)+":	0:	°:		,:		1,°:	" + ksDEBUG_VARBASE + ":	UFCom_DbgLst():	fDbgColLst():	UFCom_DbgCB():	:		:		~0:		:		Specific Debug print:	"		// multi-row checkboxes, initial values must be zero to correspond with global vars
	n += 1;	tPn[ n ] =	"BU:	   1:	0:	2:			0:	°:		,:		1,°:			DbgAOn:			All On:			:			UFCom_fAllOn():	:		:		~0:		:		Turn all  debug variables on:"	//
	n += 1;	tPn[ n ] =	"BU:	   0:	1:	2:			0:	°:		,:		1,°:			DbgAOff:			All Off:			:			UFCom_fAllOff():	:		:		~0:		:		Turn all  debug variables off:"	//
	n += 1;	tPn[ n ] =	"BU:	   1:	0:	1:			0:	°:		,:		1,°:			DbgColl:			Update panel variables::			UFCom_fUpdateVars()::		:		~0:		:		Update debug variables:	"	// 

	redimension  /N = (n+1)	tPn
End


Function	/S	fDbgColLst( sBaseNm, sF, sWin )
	string  	sBaseNm, sF, sWin  
	return	klstDEBUG_COLS
End

Function		UFCom_fUpdateVars( s )
	struct	WMButtonAction	&s
	string  	sFo		= StringFromList( 2,  s.ctrlname, "_" )	// e.g.  'acq' ,  'eva'  or  'best'
	string  	sPnNm	= DebugPanelNm( sFo )
variable	xPercent = 50 // todo  get panel position
	PanelDebugPrint( sFo, sPnNm, xPercent )						// rebuild the DebugPrint panel
End


Function		UFCom_fAllOff( s )
	struct	WMButtonAction	&s
	string  	sFo		= StringFromList( 2, s.Ctrlname, "_" )
	DebugAllSet( sFo, UFCom_kOFF )
End

Function		UFCom_fAllOn( s )
	struct	WMButtonAction	&s
	string  	sFo		= StringFromList( 2, s.Ctrlname, "_" )
	DebugAllSet( sFo, UFCom_kON )
End

static Function	DebugAllSet( sFo, bState )
	string  	sFo
	variable	bState
	string  	sPnNm		= DebugPanelNm( sFo )
	string 	sCtrlBsNm		= ksDEBUG_VARBASE					// the name of the checkbox group is defined in the panel initialisation wave
	string  	lstVars		= UFCom_DbgLst( sCtrlBsNm, UFCom_ksROOT_UF_ + sFo + ":" , sPnNm )
	variable	col, n, nVars	= ItemsInList( lstVars, "," )
	// Construct the control name and set the control (=Checkbox)
	for ( n = 0; n < nVars; n += 1 )
		for ( col = 0; col < ItemsInList( klstDEBUG_COLS, "," ); col += 1)
			string sFoCtrlNm	= ReplaceString( ":", UFCom_ksROOT_UF_ + sFo + "_" + sPnNm + "_" + sCtrlBsNm + "00" + UFCom_IdxToDigitLetter( n ) + UFCom_IdxToDigitLetter( col ) , "_" )	
			CheckBox  $sFoCtrlNm, win = $sPnNm, value = bState					// Set / Reset  all  checkboxes of this group...
			// printf "\t\tDebugAllSet( bState:%2d ) \tsPnNm:\t%s\tsFoCtrlNm:\t%s\tsFo:'%s' \trow:\t%3d\tcol:%2d\t  \r", bState, UFCom_pd(sPnNm,28), UFCom_pd(sFoCtrlNm,28), sFo, n, col
		endfor
	endfor
End


static Function	/S	DebugPanelNm( sFo )
	string  	sFo
	return	ksDEBUG + sFo		// or  sFo + ksDEBUG.   Must be unique name so we can selectively build and delete Debug panels for each application
End


Function		UFCom_DebugVar( sFo, sVarNm )
// 1. Create or maintain  the global debug checkbox titles and values  IF  (on the first call)  this checkbox 'sVarNm'  does not  yet exist. In this case set its initial value to zero.  
// 2. Retrieve the value of the global debug variable  IF  (on further calls)  this checkbox  'sVarNm'  exists already.  
// However, the debug folder must already exist as 'UFCom_PossiblyCreateFolder()'  would impose a big speed penalty.
// Maintain the connection between the checkbox TITLES (which are too long to be used directly)  and the abbreviated indexed checkbox NAMES (e.g. debug0000, debug0012,  the indexes being '0 0 row col' .
	string  	sFo, sVarNm
	string  	sTxt		= "Exists:  "
	variable	row, col, nBinSum = 0

// 2010-01-21	Version 1:  Store Panel checkbox titles in data folder ksDEBUGVARS
//	// Construct the long real name variables, 1 for each row, in subfolder 'dbgvars'
//	string  	sFoPath	= UFCom_ksROOT_UF_ +  sFo + ":" +  ksDEBUGVARS 
//	nvar /Z	gVar		= $sFoPath + ":" + sVarNm 
//	if ( ! nvar_exists( gVar ) )
//		sTxt 	= "Creating 1"
//		UFCom_PossiblyCreateFolder_R( sFoPath )						// We accept the speed penalty as the variables are created seldom.
//		variable /G   	   $sFoPath + ":" + sVarNm  = 0					// the long real name variables, 1 for each row, in subfolder 'dbgvars'
//	endif
//	row		= UFCom_WhichFolderItem( sVarNm, sFoPath, 2 )// 2 is variables


// 2010-01-21	Version 2:  Store Panel checkbox titles as global string list 'lstCbTitles'  (in the in the application panel folder)
	string  	sFoPath	= UFCom_ksROOT_UF_ + sFo 
	svar /Z	lstCbTitles	= $sFoPath + ":" + "lstDbgCbTitles"
	if ( ! svar_exists( lstCbTitles ) )
		sTxt 	= "Creating 2  "
		UFCom_PossiblyCreateFolder_R( sFoPath )						// We accept the speed penalty as the variables are created seldom.
		string  /G  	   	   $sFoPath + ":" + "lstDbgCbTitles"  = sVarNm + ","	// add the long checkbox title, 1 for each row
		svar   lstCbTitles	= $sFoPath + ":" + "lstDbgCbTitles"
		row	= 0
	else
		sTxt 	= "Exists 2      "
		row	=  WhichListItem( sVarNm, lstCbTitles, ","  )  
		if ( row  == UFCom_kNOTFOUND )
			lstCbTitles 	+= sVarNm + ","						// add the long checkbox title, 1 for each row
			row		 =  ItemsInList( lstCbTitles, "," ) - 1 		// or  WhichListItem( sVarNm, lstCbTitles, "," )	
		endif	
	endif	

	// Construct the short indexed name variables, 3 cols for each row, in subfolder 'dbgXXX'
	string  	sPnNm	= DebugPanelNm( sFo )
	string  	sFoPath1	= UFCom_ksROOT_UF_ + sFo   + ":" + sPnNm 

	for ( col = 0; col < ItemsInList( klstDEBUG_COLS, "," ); col += 1) 
		string  	sVarNm1	= ksDEBUG_VARBASE + "00" + num2str( row ) + num2str( col )
		nvar	  /Z	gValue1	= $sFoPath1 + ":" + sVarNm1
		if ( ! nvar_exists( gValue1 ) )
			sTxt 	+= "+B"
			UFCom_PossiblyCreateFolder_R( sFoPath1 )	
			variable /G   	   $sFoPath1 + ":" + sVarNm1 = 0	// the short indexed name variables, 3 cols for each row, in subfolder 'dbgXXX'
			nvar	  gValue1	= $sFoPath1 + ":" + sVarNm1
		endif
		nBinSum	+= gValue1 * 2^col
	endfor	
	// printf "\t\tUFCom_DebugVar \t%d\t%s\t%s\t%s\t%s\trow:\t%3d\tcol:%2d\tReturning:%2.0lf\tBinSum:%2d\t%s\t%s \r", col, sFo, UFCom_pd(sVarNm,15),  sTxt,  UFCom_pd(sFoPath,16), row, col, gValue1, nBinSum, sFoPath1, sVarNm1
	return	nBinSum//gValue1
End 


Function	/S	UFCom_DbgLst( sBaseNm, sF, sWin )
// creates list which is used to fill multiple panel checkboxes, the comma separator is required by panel syntax
	string  	sBaseNm, sF, sWin  
	string  	sSep			= ","						// the comma separator is required by panel syntax

// 2010-01-21	Version 1:  Store Panel checkbox titles in data folder ksDEBUGVARS
//	string 	sFolderTitles	= sF + ksDEBUGVARS
//	string		lstCbTitles 		= UFCom_AllVariablesIn_( sFolderDbgVars, sSep )
// 2010-01-21	Version 2:  Store Panel checkbox titles as global string list 'lstCbTitles'  (in the in the application debug panel folder 'dbgXXX' )
	string 	sFolderTitles	= sF 
	svar 	/Z	lstCbTitles		= $sFolderTitles + "lstDbgCbTitles"
	if ( ! svar_exists( lstCbTitles ) )
		return ""
	endif
	// printf "\t\tUFCom_DbgLst a \t%s\t%s\t%s\t)  -> '%s'  returns %d items : [%s...] \r", UFCom_pd( sBaseNm,8), UFCom_pd( sF,10), UFCom_pd( sWin,7), sFolderTitles, ItemsInList( lstCbTitles, sSep), lstCbTitles[0,200]
	return	lstCbTitles
End


Function		UFCom_DbgCB( s )
	struct	WMCheckboxAction	&s
	variable	len		= strlen( s.Ctrlname )
	variable	row		= UFCom_DigitLetterToIdx(  (s.Ctrlname)[ len-2, len-2 ] )
	variable	col		= UFCom_DigitLetterToIdx(  (s.Ctrlname)[ len-1, len-1 ] )		// the column    for horizontal	checkboxes
	string  	sFo		= StringFromList( 2, s.Ctrlname, "_" )					// e.g  'root_uf_secu_debST_DbgPrint0000'  ->  'secu:'
	string  	sPnNm	= DebugPanelNm( sFo )
	string  	sFoPath1	= UFCom_ksROOT_UF_ + sFo   + ":" + sPnNm 
	string  	sVarNm1	= ksDEBUG_VARBASE + "00" + num2str( row ) + num2str( col )
	nvar		gValue1	= $sFoPath1 + ":" + sVarNm1
	// printf "\t\tUFCom_DbgCB() \t\t%s  -> index:row:%d  col:%d    sFo : '%s'  -> \t'%s'    VarNm:\t%s\t -> \t%2.0lf  \r", s.Ctrlname, row, col, sFo, sFoPath1, UFCom_pd( sVarNm1, 23), gValue1
End

