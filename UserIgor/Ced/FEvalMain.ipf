// FEvalMain.ipf
// 
//	contains the main program entry point  FEvl()  when FEval  is started via Igors main menu ( FPulse.ipf controls the menu entry )
//	contains initialization routines: define folders, globals
//	contains the main FEval  panel  and some of its short functions 
//
// History: 

// todo: 
// balloon help....for dialogs
// todo: check for  Igor behaviour/bug: even if  endpoint is before startpoint waveform arithmetic copies..... wave[ startpoint, startpoint-1 ]   acts but should not

#pragma  rtGlobals 	= 1					// Use modern global access method. 	Do not use a tab after #pragma. Doing so will give compilation error in Igor 4.
#pragma  IgorVersion = 5.02				// prevents the attempt to run this procedure under Igor4 or lower. Do not use a tab after #pragma. Doing so will make the version check ineffective in Igor 4.

// todo 040831
//#pragma  ModuleName= FPPulseProc

#include <Decimation>					// decrease number of display data points to speed up drawing...
#include <PerformanceTestReport>			// measure how much time is spent in various parts of the program code 

// Special  'Includes'  for  FEval
#include "FEval_"						
#include "FEvalCfsRead"					// All  #include "..."  require a link into 'User Procedures'
#include "FEvalPanel"					// these files are listed in lst_SPECIAL_FILES so that they can be closed when FEval is left
#include "FEvalDSSelect"
#include "FEvalAvg"
#include "FEvalStim"
#include "FEvalUtilities"
static  strconstant	lst_SPECIAL_FILES	= "FEvalMain;FEval;FEvalCfsRead;FEvalPanel;FEvalDSSelect;FEvalAvg;"

// General  'Includes'
#include "FP_Constants"
#include "FP_FPulseConstants"
#include "FP_ColorsAndGraphs"
#include "FP_DataFoldersAndGlobals"

// 2009-10-28 remove debug printing
#include "FP_DebugPrint"

#include "FP_DirectorySelection"
#include "FP_DirsAndFiles"
#include "FP_Help"
#include "FP_Errors"
#include "FP_LineProcessing"
#include "FP_ListProcessing"
#include "FP_Memory"
#include "FP_Notebooks"
#include "FP_Numbers"

// 2009-10-22 modify for Igor6
//#include "FPPanelOld"		
//#include "FPPanelOldMore"	

#include "FP_Panel"	



#include "FP_PixelsAndPoints"
#include "FP_Timers"

#include "FPMisc_V3xx"
#include "FPDialog"

#include "FPUtilities"
#include "FPScript"
#include "FPStim"
#include "FEvalFit"	

//#include "FPAcqCed"					// unfortunately we must include this file even in EVAL to avoid linker errors although the code is actually never used
#include "FPAcqScript"					// unfortunately we must include this file even in EVAL although very few functions are actually used
//#include "FPAcqDisp"					// unfortunately we must include this file even in EVAL although very few functions are actually used
//#include "FPCfsWrite"					// unfortunately we must include this file even in EVAL although very few functions are actually used
//#include "FPOnlineA"					// unfortunately we must include this file even in EVAL although very few functions are actually used

#include "FPRelease"					// the code in this file is automatically excluded in the Release version (only an empty wrapper is supplied)
// 2009-10-27
//#include "FPTest"						// the code in this file is automatically excluded in the Release version (only an empty wrapper is supplied)
#include "FPMovie"

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//static constant		kNOERASE	= 0,	cERASE	= 1
//static constant		cSINGLE		= 0,	cSUPIMP	= 1
// static constant    	kLOWER 		= 0,	kUPPER 	= 1	// 0 : compute LinSweep, check and possibly clip prot/block/frame/sweep for lower bound or single trace , 1 for multiple trace or upper bound
//	constant		kLOWER 		= 0,	kUPPER 	= 1	// 0 : compute LinSweep, check and possibly clip prot/block/frame/sweep for lower bound or single trace , 1 for multiple trace or upper bound


static   Function		CreateGlobals( sFo )
// We define all globals here so that we can be sure they are known throughout the program because this function is called at the program entry 
// An exception could be a global strictly localized in some closely connected functions with one local entry point (where it could also be defined)  
	string  	sFo
	string		sDFSave		= GetDataFolder( 1 )				// remember CDF in a string.
	NewDataFolder  /O   root:uf


// 2009-12-10	Even in EVAL  there is a data folder 'aco'  containing  the subfolders  'dlg'  and  'script' .  Unfortinately it seems not easy to distribute to 'evo' ...
	NewDataFolder  /O   root:uf:aco
// 2009-10-27
//	NewDataFolder  /O   root:uf:com
//	NewDataFolder  /O   root:uf:com:dlg
	NewDataFolder  /O   root:uf:aco:dlg


	//  The SUBFOLDERS to the following folder are cleared whenever a new script is loaded. 
	NewDataFolder	/O		$"root:uf:" + sFo				// creates  'root:uf:evo' .  	Holds subfolders which are cleared whenever............(acq:  a new script is loaded.)
	NewDataFolder	/O		$"root:uf:" + sFo + ":lb"			// creates  'root:uf:evo:lb'   for wLBTxt, wDSColors etc

	CreateGlobalsInFolder_SubEvl( sFo )

	NewDataFolder  /O/S 	$"root:uf:" + sFo + ":fit"
	NewDataFolder  /O	 	$"root:uf:" + sFo + ":" + ksfEVOVARS		// required early e.g. for the panel list 'lstPanels'

	// The following folders keep their variables when switching between FPulse and FEval. They are cleared only when both FPulse and FEval are closed.
	CreateGlobalsInFolder_Script()							// for data which are not cleared when a script is loaded e.g. 'wMK', 'wSK' , 'gsMainkey'  and 'gsScriptPath'   
	CreateGlobalsInFolder_Dlg()

	CreateGlobalsInFolder_Misc( sFo )

	CreateGlobalsInFolder_Util_evo()

	// The following folders hold FPulse variables. They keep their values when a new script is loaded. They are cleared when FPulse is closed.
	CreateGlobalsInFolder_CfsRd_()							// creates  'root:uf:evo:cfsr'

	CreateGlobalsInFolder_Keep( sFo )						// creates  'root:uf:aco:keep'
	CreateGlobalsInFolder_SubDlg( sFo )					// creates  'root:uf:aco:dlg'

// 2009-10-28 remove debug printing
// 2009-10-27
//	string  	sComFolder	= ksCOM						// 050530 must work in  Acq  with all variables from  'csDEBUG_SECTIONS'    but  in  Eval  it needs only a few variables ( for DisplayStimulus()... )
	string  	sComFolder	= ksACOld

	string  	sPnOptions	= ":dlg:tDebugPrint"				// Construct   root:uf:dlg:debg:xxxx .  Although the code will work only in DEBUG mode...
	InitPanelDebugPrintOptions(  sComFolder, sPnOptions )		// ...the variables must exist also in RELEASE mode (else a NVAR checking error is issued)
	// Set the initial global variable values even though the panel does not yet exist. It will only exist after  'DebugPrintOptions()'  will have been called.
	nvar		gRadDebgSel	=  root:uf:dlg:gRadDebgSel			// Turn 'Nothing' sel radio button on, all others OFF....	
	gRadDebgSel	= 0 									// ...we cannot use  RadioCheckUncheck( "root_uf_dlg_gRadDebgSel_0_5", 1 )  as this requires the panel to exist which is not true right now..
	ChkboxUnderlyingVariablesSetAll( "root:uf:dlg:Debg" , FALSE )	// Start all options set to 'No printing'    (= ShowIO, ShowEle, Expand, CFS...)  .  We cannot use DebugPrintDeselectAll() as this requires the panel to exist which is not true right now..


	MoviesPanel(	 ksPN_MOVIE, 2, 75, kPN_INIT )			// 060707 automatically create a hidden panel to 1.)construct the folder to store globals like.....  and 2.) to create variables like 'pmMovChan0000'  which are needed during movie construction which may occur before the user opens the panel  
//	MoviesPanel(	 ksPN_MOVIE, 2, 75, kPN_DRAW )		// 060707 automatically create a hidden panel to 1.)construct the folder to store globals like.....  and 2.) to create variables like 'pmMovChan0000'  which are needed during movie construction which may occur before the user opens the panel  


	SetDataFolder sDFSave								// restore CDF from the string value

End


static Function	CreateGlobalsInFolder_Dlg()
// Creates all folder-specific variables. To be used once from CreateGlobals() as the current data folder is changed and not restored.
	NewDataFolder  /O  /S root:uf:dlg				// Make a new data folder and use as Current DF,  clear everything
										// This should be a folder in which variables keep their state : mostly dialog variables
	string		/G	gsHelpLinks		= ""
	variable	/G	gbHelpMode		= 0//1	// show context-sensitive help topics for every button and checkbox
	variable	/G	gbHelpConnShow	= 1		// for testing: show connected Controlelements and their Topic/Subtopic link
	variable	/G	gnWarningLevel		= 2		// 1 : only severe warnings	  2 : many warnings  	3 : all warnings	4 : also messages
	variable	/G	gbWarningBeep		= 1		// turn on/off the beep in addition to the printed '++++Warning...' line
	variable	/G	gRadDebgGen		= 1		// Radio button controlling the general printing,  1 as default makes sense, but is slow
	variable	/G	gRadDebgSel		= 0		// Radio button controlling selected printing

	if ( ! kbIS_RELEASE )
		gnWarningLevel		= 4
	endif
End

//in sub...
static Function	CreateGlobalsInFolder_SubDlg( sFolder )
// creates all folder-specific variables. To be used once from CreateGlobals() as the current data folder is changed and not restored
	string  	sFolder
	string		sDFSave		= GetDataFolder( 1 )				// remember CDF in a string.

	NewDataFolder  /O  /S  $"root:uf:" + sFolder +":dlg"							// acquisition: make a new data folder and use as CDF,  clear everything

	SetDataFolder sDFSave								// restore CDF from the string value
End

static Function	CreateGlobalsInFolder_Keep( sFolder )
// creates all folder-specific variables. To be used once from CreateGlobals() as the current data folder is changed and not restored
	string  	sFolder
	NewDataFolder  /O  /S  $"root:uf:" + sFolder + ":keep"		// acquisition: make a new data folder and use as CDF,  clear everything
	variable	/G	gnProts	= 1							// for all general acquisition variables which keep their state when a new script is loaded, e.g. gnProts
End


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function		FEvl()
// This is the  PROGRAM  ENTRY  POINT  when the program is started via 'Menu -> Analysis -> FEval' 
// This is NOT executed when the program is started via  'Open experiment' ...
//  ..but still cold start via menu / IPF  and  warm start  via  Pxp must work  (and possibly supply new  objects)

 	// printf "\tFEvl() Program start 		 current DF:'%s'   \r", GetDataFolder(1) 
// 2009-10-22
//  	 if ( xUtilError( 2 ) == kERROR )
//  		//CloseProcs( lst_SPECIAL_FILES )
//  	 	return kERROR
//  	 endif
  	CreateGlobals( ksEVO )
	Initialize()												//
	PanelEvaluation_()									// The main panel window  on the left
End


static constant			kFONTSIZE 		= 12				// determines only the separator font size and the width of text space (inversely?) in panels, not the button or checkbox text...?
static strconstant		ksFONT			= "MS Sans Serif" 	// the panels are designed for  "MS Sans Serif" 
static strconstant		ksFONT_			= "\"MS Sans Serif\""// special syntax needed for   'DrawText , SetDrawEnv..'


Static Function	Initialize()
	PossiblyCreatePath( ksEVOCFG_DIR )						// creates 'C:Epc:Data:EvalCfg:'	 automatically including  'C:Epc:Data'
	PossiblyCreatePath( ksSCRIPTS_DRIVE + ksSCRIPTS_DIR )		// creates 'C:UserIgor:Scripts:' . This is needed for storing a script (extracted from Cfs file) and for storing cut-out segments 
	DefaultGUIFont all ={  ksFONT, kFONTSIZE, 0 }					// effects all controls in all panel except those using 'DrawText' 
	Execute "DefaultFont	 /U  	"+ ksFONT_						// effects  'DrawText'  (used in some controls)
End


