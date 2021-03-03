//
// FEvalUtilities.Ipf   :	Routines for	Filtering data
//							Cutting out and storing episodes
//							AXIS  and  SCALEBARS

#include <Axis Utilities>

#pragma rtGlobals=1								// Use modern global access method.
#pragma version=2

Function		CreateGlobalsInFolder_Util_evo()
// creates all folder-specific variables. To be used once from CreateGlobals() as the current data folder is changed and not restored.
	string  	sFo 		= ksEVO
	NewDataFolder  /O  /S $"root:uf:" + sFo + ":util"				// make a new data folder and use as CDF,  clear everything
	variable	/G	gbCrsSetCt		= FALSE		// button with 2 states: enable cursors for user to set,  cut out the selected range (to be used as stimwave) and disable cursors
	string  	/G	gsCutPath						// Name of the cut out wave
	variable	/G	gbFiltApRm		= FALSE		// button with 2 states: 
	variable	/G	gFilterFreq			= 1000		// filter frequency
End

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//      DIALOG  :   DATA  UTILITIES  PANEL

static strconstant	ksPN_NAME	= "PnDataUtilitiesE" 

Function  		DataUtilitiesDlg_evo()
	string  	sFo 			= ksEVO
	string  	sPnOptions	= ":dlg:tPnUtil" 
	string  	sWin			= ksPN_NAME
	InitPanelDataUtilities( sFo, sPnOptions )
	ConstructOrDisplayPanel(  sWin, "Data Utilities E" , sFo, sPnOptions,  100, 95 )
	LstPanels_Eva3Set( AddListItem( sWin, LstPanels_Eva3() ) )	// ??? todo_c could prevent adding more than once....
End

static Function		InitPanelDataUtilities( sFo, sPnOptions )
	string  	sFo, sPnOptions
	string		sPanelWvNm = 	  "root:uf:" + sFo + sPnOptions
	variable	n = -1, nItems = 30		
	make /O /T /N=(nItems)	$sPanelWvNm
	wave  /T	tPn		= 	$sPanelWvNm

	n += 1;	tPn[ n ] =	"PN_SEPAR;	;Filtering"
	// Sample for PN_BUTCOL		( looks like a button with 2 states but is actually used like a CheckBox with programmed titles and colors )
	n += 1;	tPn[ n ] =	"PN_BUTCOL;	root:uf:evo:util:gbFiltApRm	; Apply Filter~Remove Filter; ; ;  52000,52000,52000 ~ 56000,56000,56000 ; | PN_POPUP; 	root:uf:evo:util:gFilterType ;; 80 ; 2 ;gFilterType_Lst; gFilterType | PN_SETVAR;	root:uf:evo:util:gFilterFreq;Freq;  50 ; %5.0lf; .01,99000,1000; " // allow after-comma digits but don't display or step through them

	n += 1;	tPn[ n ] =	"PN_SEPAR;	;Cutting stimulus data"
	n += 1;	tPn[ n ] =	"PN_BUTCOL;	root:uf:evo:util:gbCrsSetCt	; Cursors Set~ Cursors Cut;  ;  ;  51000,51000,51000 ~ 58000,58000,58000 ;  | PN_SETSTR;	root:uf:evo:util:gsCutPath ; ;	30 ; 	1 | 	"	//! Sample	 : PN_SETSTR  and   doubling 	the field length

	n += 1;	tPn[ n ] =	"PN_SEPAR;	;  "
	n += 1;	tPn[ n ] =	"PN_BUTTON;	buAxisScalebarsDlg_evo	;Axes and  Scalebars"		
	redimension  /N = ( n+1)	tPn	
End


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	FILTERING  and  SMOOTHING

Function		root_uf_evo_util_gbFiltApRm( s )
	struct	WMCustomControlAction 	&s
	FiltApRm( s, ksEVO, ksPN_NAME )
End


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	CUTTING  and  STORING  EPISODES

Function		root_uf_evo_util_gbCrsSetCt( s )
	struct	WMCustomControlAction 	&s
	CrsSetCt( s, ksEVO )
End

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  	AXIS  and  SCALEBARS  2003-05-30

Function		buAxisScalebarsDlg_evo( ctrlName ) : ButtonControl
	string		ctrlName		
	AxisScalebarsDlg( ksEVO )		
End
