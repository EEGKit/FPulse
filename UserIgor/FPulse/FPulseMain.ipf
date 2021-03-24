// FPulseMain.ipf
// 
//	contains the main program entry point  FPulse()  when FPulse is started via Igors main menu ( FPulse.IPF controls the menu entry )
//	contains initialization routines: define folders, globals
//	contains the main FPulse panel  and some of its short functions 
//	contains the Preferences panel
//
// Comments:
//	in PULSE (and in other program parts)  there are 5 intermediate stages in which to display data (=waves)
//	-	stimulus wave
//	-	partial ADC (also DAC) waves while sampling  
//	-	full waves after sampling
//	-	sweeps (also frames) after sampling
//	-	sweeps (also frames) after reading CFS files
//	-	full waves built from swps/frms after reading CFS files

// History: 

// todo: 
// balloon help....for dialogs
// todo: check for  Igor behaviour/bug: even if  endpoint is before startpoint waveform arithmetic copies..... wave[ startpoint, startpoint-1 ]   acts but should not

// 050816  todo : possible convert  FPulse panel to  Panel3Main()  , the others e.g. preferences, data utilities to Panel2Sub()

#pragma  rtGlobals 	= 1					// Use modern global access method. 	Do not use a tab after #pragma. Doing so will give compilation error in Igor 4.
#pragma  IgorVersion = 5.02				// prevents the attempt to run this procedure under Igor4 or lower. Do not use a tab after #pragma. Doing so will make the version check ineffective in Igor 4.
#pragma  ModuleName= FPPulseProc

#define   dDEBUG						// Comment this line for a Release version (this automatically done in the Release process)

#include <Decimation>					// decrease number of display data points to speed up drawing...
#include <PerformanceTestReport>			// measure how much time is spent in various parts of the program code 

// No special  'Includes'  for FPulse in addition to 'FPulseMain' , unfortunately all files contain functions needed also in Eval
static  strconstant	lst_SPECIAL_FILES	= "FPulsMain"

// General  'Includes'
#include "FP_Constants"
#include "FP_FPulseConstants"
#include "FP_ColorsAndGraphs"
#include "FP_DataFoldersAndGlobals"

#include "FP_DebugPrint"

#include "FP_DirectorySelection"
#include "FP_DirsAndFiles"
#include "FP_Errors"
#include "FP_LineProcessing"
#include "FP_ListProcessing"
#include "FP_Memory"
#include "FP_Numbers"

#include "FP_Panel"	


#include "FP_PixelsAndPoints"
#include "FP_Timers"

#include "FPMisc_V3xx"
#include "FPDialog"

#include "FPUtilities"
#include "FPScript"
// 051006
//#include "FEvalFit"
#include "FPStim"						// All  #include "..."  require a link into 'User Procedures'
#include "FPAcqCed"					// these files are listed in lst_FILES_ONLY_ACQ so that they can be closed when FPulse is left
#include "FPAcqScript"
#include "FPAcqDisp"
#include "FPCfsWrite"
#include "FPOnLineA"

#include "FPRelease"					// the code in this file is automatically excluded in the Release version (only an empty wrapper is supplied)

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

static   Function		stCreateGlobals( sFo )
// The folder hierarchy is not trivial as it must fulfill certain requirements
// 1. The folder path must be short as of Igor's 31 character limitation for function names and even shorter for control names.
// 2. Depending on the state of the program (FPulse and FEval running, only  1 running, none running, new script loaded) some folders are completely cleared/removed.
// 3. For some subfolders the folder path must include  'sFolder'  (e.g. 'ac'  and  'ev' )  to discriminate between  FPulse  and  FEval 
	string  	sFo
	string		sDFSave	= GetDataFolder( 1 )				// remember CDF in a string.
	NewDataFolder	/O  /S root:uf
	NewDataFolder  /O   root:uf:aco
	NewDataFolder  /O   root:uf:aco:dlg


	//  The SUBFOLDERS to the following folder are cleared whenever a new script is loaded. 
	NewDataFolder	/O	$ksROOTUF_ + sFo				// creates  'root:uf:aco' .  Holds subfolders  'ar' , 'stim' , 'dig' , 'store' , 'io' , 'co' , 'dispFS'  which are cleared whenever a new script is loaded.

//	NewDataFolder  /O	$ksROOTUF_ + sFo + ":" + ksVAR		// required early e.g. for the panel list 'lstPanels'

	// The following folders keep their variables when switching between FPulse and FEval. They are cleared only when both FPulse and FEval are closed.
	CreateGlobalsInFolder_Script()						// for data which are not cleared when a script is loaded e.g. 'wMK', 'wSK' , 'gsMainkey'  and 'gsScriptPath'   
	stCreateGlobalsInFolder_Dlg()

	CreateGlobalsInFolder_Misc( sFo )

	Dilg_Miscellaneous( kPN_INIT)						// 050815 create a hidden panel just to construct globals like  'AcqCheck'  or  'TimeStats'

	CreateGlobalsInFolder_Util_aco()
	Dilg_DisplayOptionsStimulus_aco( 50, 10, kPN_INIT )	// 050815 create a hidden panel just to construct globals like  'gbDisplay'  

	// The following folders hold FPulse variables. The variable in these folders  'cfsw' , 'ola' , 'disp' , 'dlg' , 'keep' , 'std'   keep their values when a new script is loaded. They are cleared when FPulse is closed.
	CreateGlobalsInFolder_CfsWrite_()
	CreateGlobalsInFolder_OLA_()
	CreateGlobalsInFolder_Disp_()
	stCreateGlobalsInFolder_SubDlg( sFo )				// creates  'root:uf:aco:dlg'
	stCreateGlobalsInFolder_Keep( sFo )					// creates  'root:uf:aco:keep'
//	CreateGlobalsInFolder_StimDisp( sFo )					// creates  'root:uf:aco:std'

	string  	sComFolder	= ksfACO

	string  	sPnOptions	= ":dlg:tDebugPrint"			// Construct   root:uf:dlg:debg:xxxx .  Although the code will work only in DEBUG mode...
	InitPanelDebugPrintOptions(  sComFolder, sPnOptions )	// ...the variables must exist also in RELEASE mode (else a NVAR checking error is issued)
	// Set the initial global variable values even though the panel does not yet exist. It will only exist after  'DebugPrintOptions()'  will have been called.
	nvar		gRadDebgSel	=  root:uf:dlg:gRadDebgSel		// Turn 'Nothing' sel radio button on, all others OFF....	
	gRadDebgSel	= 0 								// ...we cannot use  RadioCheckUncheck( "root_uf_dlg_gRadDebgSel_0_5", 1 )  as this requires the panel to exist which is not true right now..
	ChkboxUnderlyingVariablesSetAll( "root:uf:dlg:Debg" , FALSE )	// Start all options set to 'No printing'    (= ShowIO, ShowEle, Expand, CFS...)  .  We cannot use DebugPrintDeselectAll() as this requires the panel to exist which is not true right now..

	SetDataFolder sDFSave							// restore CDF from the string value

	variable	/G	root:V_marquee = 1//=1	// 0 / 1 enable / disable live update of marquee variables (V_top..)
	variable	/G	root:V_left,  root:V_right,  root:V_top,  root:V_bottom
End


//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

static Function  	stKillAllGraphs()
	KillGraphs( "*", ksW_WNM )				// also kills StatusBar which is probably not intended
End 


// 2009-12-10	In EVAL  and in FPULSE  there is still a common data folder 'dlg'  .  Unfortunately it seems not easy to distribute to  'aco' and 'evo' ...
static Function	stCreateGlobalsInFolder_Dlg()
// Creates all folder-specific variables. To be used once from CreateGlobals() as the current data folder is changed and not restored.
	NewDataFolder  /O  /S root:uf:dlg			// Make a new data folder and use as Current DF,  clear everything
										// This should be a folder in which variables keep their state : mostly dialog variables
	string		/G	gsHelpLinks		= ""
	variable	/G	gbHelpMode		= 0//1	// show context-sensitive help topics for every button and checkbox
	variable	/G	gbHelpConnShow	= 1		// for testing: show connected Controlelements and their Topic/Subtopic link
	variable	/G	gnWarningLevel	= 2		// 1 : only severe warnings	  2 : many warnings  	3 : all warnings	4 : also messages
	variable	/G	gbWarningBeep		= 1		// turn on/off the beep in addition to the printed '++++Warning...' line
	variable	/G	gRadDebgGen		= 1		// Radio button controlling the general printing,  1 as default makes sense, but is slow
	variable	/G	gRadDebgSel		= 0		// Radio button controlling selected printing

	if ( ! kbIS_RELEASE )
		gnWarningLevel		= 4
	endif
End

static Function	stCreateGlobalsInFolder_Keep( sFolder )
// creates all folder-specific variables. To be used once from CreateGlobals() as the current data folder is changed and not restored
	string  	sFolder
	NewDataFolder  /O  /S  $ksROOTUF_ + sFolder + ":keep"		// acquisition: make a new data folder and use as CDF,  clear everything
	variable	/G	gnProts	= 1							// for all general acquisition variables which keep their state when a new script is loaded, e.g. gnProts
// 050530  was in  :co:  but must now in :keep: as it must be maintained  ( -> LaggingTime()  ElapsedTime()  ) , :co:  is killed....  Other possibility: do not kill  :co:  but instead set all variables to 0
	variable	/G	gbRunning		= 0
	variable	/G	gnTicksStart		= 0		
	variable	/G	gnTicksStop		= 0		
	variable	/G	gPrediction		= 1
End

//in sub...
static Function	stCreateGlobalsInFolder_SubDlg( sFolder )
// creates all folder-specific variables. To be used once from CreateGlobals() as the current data folder is changed and not restored
	string  	sFolder
	string		sDFSave		= GetDataFolder( 1 )				// remember CDF in a string.

	NewDataFolder  /O  /S  $ksROOTUF_ + sFolder +":dlg"				// acquisition: make a new data folder and use as CDF

	// The FPulse Panel
	variable	/G	gbShowScript		= 1		
	variable	/G	gnAcqStatus		= 0						// 031023  0 : waiting for 'Start',   1: 'Start' has been pressed (but Acquis not yet started, waiting for E3E4 trigger),  2 : Acquis is running
	variable	/G	raTrigMode		= 0						// 031027  0 : normal SW trigger ('Start' button) ,    1 : HW trigger by E3E4 mode: Acquis starts with HI pulse on CED Event4  ,    2 : timer triggered
	variable	/G	gbAutoBackup		= 0						// write backup file automatically ?
	variable	/G	gbAppendData		= 0						// 031028  0 : open and write new file for each trigger   1 : keep writing into the same file until user selects 'Finish file' 

	// The Pref Panel
	variable	/G	gbDisplayAllPtsAA	= 1							// displaying every point without data decimation can be slow with MB waves 
	variable	/G	gShrinkCedMemMB	= 0						// 031030	 must  be  0  as this is used as a 'firsttime' indicator
	variable	/G	gMaxReactnTime	= MAX_REACTIONTIME		// 031016

	
	// The Gain Panel
	variable	/G	CCpAStep		= 100

	if ( ! kbIS_RELEASE )
		gbShowScript			= 0						// 031113 normal setting 1, but 0 saves time when during testing the same script is loaded over and over
		gbDisplayAllPtsAA		= 0							// possibly skip display points to gain display speed
	endif
	SetDataFolder sDFSave								// restore CDF from the string value
End



Function		FPulse()
// This is the  PROGRAM  ENTRY  POINT  when the program is started via 'Menu -> Analysis -> FPulse' 
// This is NOT executed when the program is started via  'Open experiment' ...
//  ..but still cold start via menu / IPF  and  warm start  via  Pxp must work  (and possibly supply new  objects)
	// printf "\tFPulse() Program start 		 current DF:'%s'   \r", GetDataFolder(1) 
  	 
  	stCreateGlobals( ksfACO )

	if ( stInitialize() )
								// DeleteGlobals ...
		return	kERROR										//
	endif

	PulsePanel()										// first main panel window  on the right
													// We cannot allow to... 
	EnableButton( "PnPuls", 	"buApplyScript", kDISABLE )		// ..apply a script at cold startup before it has been loaded a first time
	EnableSetVar( "PnPuls", "root_uf_aco_keep_gnProts", kNOEDIT )// ..change the number of protocols as this would trigger 'ApplyScript()'
	EnableButton( "PnPuls", 	"buSaveScript",	kDISABLE )		// ..save a script at cold startup before it has been loaded a first time
	EnableButton( "PnPuls", 	"buSaveAsScript", kDISABLE )		// ..save a script at cold startup before it has been loaded a first time
	EnableButton( "PnPuls", 	"buStart",		kDISABLE )		// ..go into acquisition at cold startup before before a script has been loaded
	EnableButton( "PnPuls", 	"buStopFinish",	kDISABLE )		// ..stop an acquisition at cold startup before before a script has been loaded
	EnableButton( "PnAcqWin", "buPreparePrint", kDISABLE )		//  ..draw in the acquisition windows before they (and TWA) have been created
	EnableButton( "PnPuls", 	"buDisplayStimDlg",kDISABLE )		// ..display a stimulus before wE and wFix  has been set by reading a script
	EnableButton( "PnPuls", 	"buAcqWindowsDlg", kDISABLE)	// ..build this panel before a script is loaded and 'wIO' is built for 'lstTitleTraces()'
	EnableButton( "PnPuls", 	"buAnalysisAcqDlg", kDISABLE )	// ..build this panel before a script is loaded and 'wIO' is built for 'ioChanList()'
	EnableButton( "PnPuls", 	"buOLAnalysisDlg",  kDISABLE )	// ..build this panel before a script is loaded and 'wIO' is built for 'ioChanList()'
	EnableButton( "PnPuls", 	"buGainDlg",	kDISABLE )		// ..build the Gain panel before a script is loaded and 'wIO' is built for 'MakeSingleADList()'

	PreferencesDlg()									// show Preferences panel always at startup
	
	// MC700Dlg_() 				 					// show MC700 panel always at startup : only for testing the MCC700B 
End


static Function	stInitialize()
	SearchAndSetLastUsedFile_()								// start with ZZ..... or start with AA...., decrement repeatedly until file exists

	PossiblyCreatePath( ksEVOCFG_DIR )							// creates 'C:Epc:Data:EvalCfg:'	 	   automatically including  'C:Epc:Data'
	PossiblyCreatePath( ksSCRIPTS_DRIVE + ksSCRIPTS_DIR + ksTMP_DIR )// creates 'C:UserIgor:Scripts:Tmp'  automatically including  'C:UserIgor:Scripts'

 	NewPath /O /Q	symbPath,  ksSCRIPTS_DRIVE + ksSCRIPTS_DIR + ksDIRSEP
 	// PathInfo /S symbPath;  string bf; sprintf bf, "\t\tLoadScript   \t PathInfo: Symbolic path '%s' does %s exist. \r", S_path, SelectString( v_Flag,  "NOT", "" ); Out( bf )

	DefaultGUIFont all ={  ksFONT, kFONTSIZE, 0 }					// effects all controls in all panel except those using 'DrawText' 
	Execute "DefaultFont	 /U  	"+ ksFONT_						// effects  'DrawText'  (used in some controls)


	// Reserve enough memory for the transfer area
	variable	code, nMinKB, nMaxKB							// 040225	Must be called only ONCE (recommendation of Tim Bergel, CED) 
	nMinKB	= 1600;	nMaxKB	= 4000						// Seems to work, any smaller values will fail in rare occasions with special scripts e..g. capacitance.txt (TransferAreaPoints 444760, 502000 )
	// 041111 This MUST be  the first XOP used .......

	code	 = xCedWorkingSet( nMinKB, nMaxKB, OFF )				//  Reserves memory so that loading of scripts which are huge (~20MPts) or require a large transfer area (~512kPts) will not fail.

	 // printf "\t\tCedInit  xCedWorkingSet( minKb: %d , maxKB: %d )  returns %d \r", nMinKB, nMaxKB, code
	return	0
End


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//     MAIN  PULSE  PANEL

Function 		PulsePanel()
	string  	sFo		   = ksfACO
	string  	sPnOptions = ":dlg:tPnPuls"								// 040831 must be :dlg: for HelpTopic...???
	string  	sWin	   =  "PnPuls"
	string		sPnTitle
//	sprintf	sPnTitle, "%s %.2lf", RemoveEnding( ksPRG_NAME, ".ipf" ) ,  knVERSION / 100
//	sprintf	sPnTitle, "%s %s", RemoveEnding( ksPRG_NAME, ".ipf" ) ,  FormatVersion()
	sprintf	sPnTitle, "%s %s", ksFP3_APPNAME,  FormatVersion()
	InitPanelFPulse( sFo, sPnOptions )									// initialize the panel controls in 'tPnPuls'
	ConstructOrDisplayPanel( 	  sWin , sPnTitle, sFo, sPnOptions, 100, 0 )
	ModifyPanel /W=$sWin, fixedSize= 1					// prevent the user to.... maximize the panel by disabling the Maximize button
	PnLstPansNbsAdd( ksfACO,  sWin )
End 
 
 	 
Function		InitPanelFPulse( sFolder, sPnOptions )
	string  	sFolder, sPnOptions
	string		sPanelWvNm = ksROOTUF_ + sFolder + sPnOptions
	variable	n = -1, nElements = 30		// separator needs FLEN entry
	make /O /T /N=(nElements) 	$sPanelWvNm
	wave  /T	tPn			= 	$sPanelWvNm
	//					TYPE		NAM				TXT	  FLEN	FORM LIM	PRC
	n += 1;	tPn[ n ] =	"PN_BUTTON;	buLoadScript		;Script file;	"
	n += 1;	tPn[ n ] =	"PN_BUTTON;	buApplyScript		;Apply;   ;  		| PN_BUTTON;	buSaveScript		;Save; 	|  PN_BUTTON;	buSaveAsScript		;Save as;	"//	| PN_BUTTON;	buSaveCopyScript	;SaveCopy; "	
	n += 1;	tPn[ n ] =	"PN_BUTPICT;	root:uf:"+sFolder+":dlg:gbShowScript; ; 59 ; FPPulseProc#cb6ScriptEditHide"
	n += 1;	tPn[ n ] =	"PN_SEPAR"

	n += 1;	tPn[ n ] =	"PN_BUTTON;	buStart			;Start;			|  PN_BUTTON;	buStopFinish		;Finish;	|  PN_BUTPICT;	    root:uf:aco:cfsw:gbWriteMode	; ; 56	;FPPulseProc#cb6WatchWrite339c"

	n = PnControl(	tPn, n, 1, ON, 	"PN_RADIO", 2, "", 	 "root:uf:aco:dlg:raTrigMode",  "Trig 'Start';Trig E3E4" ,    "Trigger mode", 	"" , kWIDTH_NORMAL, sFolder	) // 2 is number of entries = horizontal mode
	n += 1;	tPn[ n ] =	"PN_DICOLTXT; root:uf:"+sFolder+":dlg:gnAcqStatus; wait Start?~wait Trig?~reloading~acquiring;;   ; 35000,35000,65535 ~ 60000,0,65000 ~ 60000,60000,0 ~ 0,60000,0; | PN_CHKBOX;	root:uf:"+sFolder+":dlg:gbAutoBackup	;Auto backup; "
	//1; 	" // 0 as step to avoid displaying up/down arrows which would allow editing even in the kNOEDIT case. Another approach: Completely hide the control  by setting  instead of kNOEDIT=3    FALSE = 0
	n += 1;	tPn[ n ] =	"PN_SETVAR;	root:uf:aco:keep:gnProts	;Protocols; 	25;	 %2d ;1,9999,0;  | PN_CHKBOX;	root:uf:"+sFolder+":dlg:gbAppendData	;Append data;	" 
	
	n += 1;	tPn[ n ] =	"PN_SEPAR"
	n += 1;	tPn[ n ] =	"PN_BUTTON;	buDataPath		;Data;			| PN_SETSTR; root:uf:aco:cfsw:gsTmpDataPath ; ;	30 ; 	2 | |	"	//! Sample : PN_SETSTR  and  tripling the field length
	n += 1; 	tPn[ n ] =	"PN_SETSTR;	root:uf:aco:cfsw:gsFileBase;FileBase;	 80 "			
	n += 1;	tPn[ n ] =	"PN_SETVAR;	root:uf:aco:cfsw:gCell	;Cell;   		40; 	%2d ;0,99,1;	"			

	n += 1;	tPn[ n ] =	"PN_BUTTON;	buDelete			;Delete;			| PN_DISPSTR;	root:uf:aco:cfsw:gsDataFileW; ;	20 ; 	2  | |"	//! Sample : PN_DISPSTR  and  tripling the field length 

	n += 1;	tPn[ n ] =	"PN_SEPAR"
	n += 1;	tPn[ n ] =	"PN_BUTTON;	buAcqWindowsDlg	;Acq windows;	| PN_BUTTON;	buDisplayStimDlg	;Stimulus"
	n += 1;	tPn[ n ] =	"PN_BUTTON;	buOLAnalysisDlg	;OLA analysis;  	| PN_BUTTON;	buDataUtilitiesDlg	;Data utilities"		

	n += 1;	tPn[ n ] =	"PN_BUTTON;	buPreferencesDlg	;Preferences;		| PN_BUTTON;	buMiscellaneousDlg	;Miscellaneous"		

	//n += 1; tPn[ n ] =	"PN_BUTTON;	buComment1		;Comment1;"												// example for text input  with DoPrompt( string ). 
// 060511e
//	n += 1;	tPn[ n ] =	"PN_BUTTON;	buComment		;Comments		| PN_BUTTON;	buGainDlg			;Gain Axogain" 
	n += 1;	tPn[ n ] =	"PN_BUTTON;	buComment		;Comments		| PN_BUTTON;	buGainDlg			;Gain AxoPa	| PN_BUTTON;	buAcqHelp	;Help" 

	redimension  /N = (n+1)	tPn
End


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	ACTION    PROCS  FOR   PULSE  DIALOG

Function		root_uf_aco_dlg_gbShowScript( sControlNm, bValue )
	string		sControlNm
	variable	bValue
	string  	sFolder	= ksfACO
	svar		gsScript	= $ksROOTUF_ + sFolder + ":gsScript"
	DisplayHideNotebook( bValue, sFolder , ":script", ksSCRIPT_NB_WNDNAME, gsScript )	
End


Function		root_uf_aco_keep_gnProts( ctrlName, varNum, varStr, varName ) : SetVariableControl		//??????????????????????????????????????
//Function		gnProts( ctrlName, varNum, varStr, varName ) : SetVariableControl					//??????????????????????????????????????
	string		ctrlName, varStr, varName
	variable	varNum
	printf "\t**** root_uf_aco_keep_gnProts(%s, %g, %s , %s)  \r", ctrlName, varNum, varStr, varName 
	string  	sFolder	= ksfACO
	nvar		gnProts	= $ksROOTUF_ + sFolder + ":keep:gnProts"
	gnProts			= varnum
	ApplyScript_( kbKEEP_ACQ_DISP )	
End


Function		buApplyScript( ctrlName ) : ButtonControl
	string		ctrlName
	ApplyScript_( kbKEEP_ACQ_DISP )
End

Function		buSaveScript( ctrlName ) : ButtonControl
	string		ctrlName
	svar		gsScriptPath		= root:uf:aco:script:gsScriptPath
	string		sNoteBookName	= ksSCRIPT_NB_WNDNAME 		// = 'Script'	
	// printf "\t\t%s \t\t\tgsScriptPath: '%s' . \tSaving as sNoteBookName:\t'%s' \r", ctrlName, gsScriptPath, sNoteBookName 
	if ( WinType( sNoteBookName ) == kNOTEBOOK )					// window exists and is a notebook
		SaveNoteBook  /O /S=2	$sNoteBookName  as  gsScriptPath		// 031211 save any changes in the script the user may have made in the same file (will not work without /S=2 = Save as)
	endif
	EnableButton( "PnPuls", "buApplyScript",	 	kENABLE )				// 040805 Enable the 'Apply' button after save. It may have been disabled when trying to load a bad script, 
															// ...but (assuming the user corrected the errors)  we give the user a chance to reload the same script directly (without having to locate it again with the file dialog)  
End

Function		buSaveAsScript( ctrlName ) : ButtonControl
	string		ctrlName 
	svar		gsScriptPath		= root:uf:aco:script:gsScriptPath
	string		sNoteBookName	= ksSCRIPT_NB_WNDNAME 		// = 'Script'	
	if ( WinType( sNoteBookName ) == kNOTEBOOK )					// window exists and is a notebook

		string		sName	= ""
		// printf "\t\t%s   1 \tgsScriptPath:'%s'  -> \r", ctrlName, gsScriptPath
		variable	nRefNum
		Open	/D  /T = "TEXT" 	nRefNum  as gsScriptPath			// Save / Create dialog: can also choose a dir besides file and cancel
		if ( strlen( S_fileName	) )
			 sName	= S_fileName	
		endif

		SaveNoteBook  /O /S=2 $sNoteBookName  as sName			// save any changes the user may have made and change Notebook title 
		gsScriptPath	= sName
		buLoadScript_Title( "buLoadScript" )							// update the button text to reflect the changed script file name
		// printf "\t\t%s   2 \tgsScriptPath:'%s'  ->Saving NB as:  \t'%s' \r", ctrlName, gsScriptPath, sName
	endif
End


Function		buLoadScript( ctrlName ) : ButtonControl
	string		ctrlName
	svar		gsScriptPath	= root:uf:aco:script:gsScriptPath
	// printf "\t\t%s (bef load)\tgsScriptPath: '%s' \r", ctrlName, gsScriptPath
	variable	rCode
	gsScriptPath	= LoadScript_(  "", rCode, kbKEEP_ACQ_DISP)					// pass an empty path to invoke a FileOpenDialog
	// printf "\t\t%s (aft load)\tgsScriptPath: '%s' \r", ctrlName, gsScriptPath
	buLoadScript_Title( ctrlName )
End
Function		buLoadScript_Title( ctrlName )
	string		ctrlName
	svar		gsScriptPath	= root:uf:aco:script:gsScriptPath
	string		sText		=  StripPathAndExtension( gsScriptPath )  
	Button	$ctrlName	win = PnPuls,	title = "Script: " + sText 			//todo: should get button text automatically from panel entry
End


Function		buStart( ctrlName ) : ButtonControl
	string		ctrlName
	string  	sFolder	= ksfACO
	StartActionProc_()
End

Function		buStopFinish( ctrlName ) : ButtonControl
	string		ctrlName
	FinishActionProc_()
End

// 060511f   Append mode comments  and renaming
Function		StartActionProc_()
	string  	sFolder = ksfACO
	variable	hnd			= CedHandle_()
	nvar		raTrigMode	= $ksROOTUF_+sFolder+":dlg:raTrigMode"
	nvar		bAppendData	= $ksROOTUF_+sFolder+":dlg:gbAppendData"
	nvar		gbRunning	= root:uf:aco:keep:gbRunning

	// printf "\t\tStartActionProc_     \t\traTrigMode:%d   AppendData:%d    gbRunning:%d   \r", 	raTrigMode, bAppendData, gbRunning
	StartStopFinishButtonTitles_( sFolder )

	if ( raTrigMode == 0 )	 	// SW triggered normal mode
		if ( ! gbRunning )
			StartStimulusAndAcquisition_()
		endif
	endif
End
 

Function		FinishActionProc_()
	string  	sFolder = ksfACO
	variable	hnd			= CedHandle_()
	nvar		raTrigMode	= $ksROOTUF_+sFolder+":dlg:raTrigMode"
	nvar		bAppendData_	= $ksROOTUF_+sFolder+":dlg:gbAppendData"
	nvar		gbRunning 	= root:uf:aco:keep:gbRunning
	nvar		gbAcquiring 	= root:uf:aco:co:gbAcquiring
	nvar		bIncremFile	= root:uf:aco:co:gbIncremFile

	// printf "\t\tFinishActionProc_ entry  \traTrigMode:%d   AppendData:%d    gbRunning:%d   bIncremFile:%d  \r", 	raTrigMode, bAppendData_, gbRunning, bIncremFile
	StartStopFinishButtonTitles_( sFolder )

// 2010-02-09 only test to simplify the code.   E3E4  (stop/ finish)  works by selecting  Trig 'Start'   again
//	if ( raTrigMode == 0  )							// SW  triggered normal mode
//		FinishFiles_( sFolder )
//		if ( gbAcquiring )
//			StopADDA_( "\tUSER ABORT1" , FALSE, hnd )	//  FALSE: do not invoke ApplyScript_()
//			gbAcquiring = FALSE						// normally this is set in 'CheckReadyDacPosition()'  but user abortion is not correctly handled there  
//		endif
//	endif
//	if ( raTrigMode == 1 )							// HW E3E4 trigger
//		FinishFiles_( sFolder )							// close CFS file so that next acquisition is written to a new file
//		if ( gbAcquiring )								// abort only when user pressed 'Finish' during the stimulus/acquisition phase,... not during the waiting phase: 
//			StopADDA_( "\tUSER ABORT2" , FALSE, hnd )		//  FALSE: do not invoke ApplyScript_()
//		endif
//	endif

	FinishFiles_( sFolder )
	if ( gbAcquiring )
		StopADDA_( "\tUSER ABORT1" , FALSE, hnd )	//  FALSE: do not invoke ApplyScript_()
		if ( raTrigMode == 0  )									// only in SW  triggered normal mode, not in HW-triggered E3E4 mode
			gbAcquiring = FALSE						// normally this is set in 'CheckReadyDacPosition()'  but user abortion is not correctly handled there  
		endif
	endif


	if (  bAppendData_ )
		bIncremFile	= TRUE
	endif
	 printf "\t\tFinishActionProc_ exit   \traTrigMode:%d   AppendData:%d    gbRunning:%d   gbAcquiring(exit):%d   bIncremFile:%d  \r", 	raTrigMode, bAppendData_, gbRunning, gbAcquiring, bIncremFile
End
// ................... 060511f   Append mode comments  and renaming



Function		buAcqWindowsDlg( ctrlName ) : ButtonControl
	string	ctrlName		
	DisplayOptionsAcqWindows()
End

Function		buOLAnalysisDlg( ctrlName ) : ButtonControl
	string		ctrlName		
	OLADispPanel()
End

Function		buPreferencesDlg( ctrlName ) : ButtonControl
	string		ctrlName		
	PreferencesDlg()
End
 
Function		buGainDlg( ctrlName ) : ButtonControl
	string		ctrlName		
	GainDlg()
End


// 060511e
strconstant		ksfACO_HELP_WND	= "FPulse Acq Help"   
strconstant		ksfACO_HELP_PATH	= "FPulseHelp.txt"

Function		buAcqHelp( ctrlName ) : ButtonControl
	string		ctrlName		
	string  	sPath = FunctionPath( "" )						// Path to file containing this function.
	if ( cmpstr( sPath[0], ":" ) == 0 )
		InternalError( "Could not locate file '" + ksfACO_HELP_PATH + "' ." )
		return -1										// This is the built-in procedure window or a packed procedure (not a standalone file)   OR  procedures are not compiled.
	endif
	
	sPath = ParseFilePath( 1, sPath, ":", 1,0 ) + ksfACO_HELP_PATH// Create path to the help file.
	 printf "\t\tfAcqHelp     \thelp path: '%s' \r", sPath

	OpenNotebook	/K=1	/V=1	/N=$ksfACO_HELP_WND   sPath	// visible, could also use /P=symbpath...
	MoveWindow /W=$ksfACO_HELP_WND	1, 1, 1, 1			// restore from minimised to old size
End



Function		buDisplayStimDlg( ctrlName ) : ButtonControl
	string		ctrlName	
	Dilg_DisplayOptionsStimulus_aco( 80, 0, kPN_DRAW )
End

Function		buDataUtilitiesDlg( ctrlName ) : ButtonControl
	string		ctrlName		
	DataUtilitiesDlg_aco()
End


Function		buMiscellaneousDlg( ctrlName ) : ButtonControl
	string		ctrlName		
	Dilg_Miscellaneous( kPN_DRAW )
End


// Igors XOP error handling
// an XOP returns to IGOR the value which the XOP stored in p->result (which is a passed parameter, not the return value)..
// ..but it additionally processes errors depending on the XOP return value. 
// Only if the return value is zero (according to documentation) no error handling is done (also returning -1 seems? to be OK)
// XOP return values <= -2  or  >= +1  lead to IGORs error handling: a message box stating the error and where it occurred.
// As this interrupts program execution this feature should be used only in case of severe errors, for slighter errors it is..
// ..better to return 0 (=no error message box) and a convenient  value in p->result  (e.g. Nan) to transmit the error to IGOR.
// In case of severe errors the return value of the XOP (<= -2  or  >= +1 ) determines which error message is printed:
// XOP return value	 -10000	...	    -2	    :	unspecific error message box  containing only the number of the error (not useful)
// XOP return value		1	...	  9999 :	IGOR errors (see  ..\ XOPSupport \ IgorXOP.H,  there are unused periods in between ) 
// XOP return value	  10000	... 	11999 :	User program errors (see  ..\ XOPSupport \ IgorXOP.H  :  #define FIRST_XOP_ERR 10000 ) 
// For the user progam errors to work there must be
// 	-	a define for the error number 	e.g. in 	MyXOPErr.H		
//			#define MY_FIRST_ERROR		1 + FIRST_XOP_ERR
// 			#define MY_SECOND_ERROR	2 + FIRST_XOP_ERR
// 	-	and  an entry in  xxxWinCustom.RC  in the string resource  like
//			1100 STR#				
//			BEGIN    
//				"\r Error message in message box 1  \0",	  
//				"\r Error message in message box 2  \0",	

  

Function		buPreparePrint( ctrlName ) : ButtonControl
	string	  	ctrlName
	string  	sFolder	= ksfACO
	wave  	wG		= $ksROOTUF_ + sFolder + ":keep:wG"  								// This  'wG'	is valid in FPulse ( Acquisition )
	wave  /T	wIO		= $ksROOTUF_ + sFolder + ":ar:wIO"  								// This  'wIO'	is valid in FPulse ( Acquisition )
	PreparePrinting( sFolder, wG, wIO )
End
	
Function		buComment( ctrlName ) : ButtonControl
	string	 	ctrlName
	//? panel is completely built new,  drawing the existing one might be enough (Even if it was closed???)
	// this would also avoid flickering... even better: set focus (blinking cursor into the first (=datapath) field...
	CommentDlg()	
End

//	//! Example : comment1 with PROMPT INPUT FIELD
//	Function		buComment1( ctrlName ) : ButtonControl
//	// the button is 'buComment1', the string is 'geComment1'
//		string	ctrlName
//		GetComment1()
//		return 0
//	End
//	
//	Function	 /S	GetComment1()
//		svar		GeComment1
//		string	sGenComment = GeComment1
//		Prompt	sGenComment, "Enter comment. A maximum of 72 characters is stored in the CFS file."
//		DoPrompt	"General comment: ", sGenComment
//		if ( !V_flag ) 
//			GeComment1	= sGenComment		// user did not cancel 
//		endif
//		//? show user the possibly truncated string.  Allow longer strings in the plot.
//		return	GeComment1[ 0, 71 ]				// the space provided in the CFS file limits the string length to 72 chars
//	End


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//    PREFERENCES PANEL

Function		PreferencesDlg()	
	string  	sFolder	= ksfACO
	string  	sWin		= "PanelPref"
	stInitPanelPreferences( sFolder, ":dlg:tPnPref" )	// constructs the text wave  'root:uf:aco:dlg:tPnPref'  defining the panel controls
	ConstructOrDisplayPanel(  sWin, "Preferences", sFolder, ":dlg:tPnPref",  100,100 )
	PnLstPansNbsAdd( ksfACO,  sWin )
End

static Function	stInitPanelPreferences( sFolder, sPnOptions )
	string  	sFolder, sPnOptions
	string	sPanelWvNm = ksROOTUF_ + sFolder + sPnOptions
	variable	n = -1, nItems = 30
	make /O /T /N=(nItems)	$sPanelWvNm
	wave  /T	tPn	=		$sPanelWvNm
	//					TYPE		NAM									TXT			
	n += 1;	tPn[ n ] =	"kCHKBOX;	dlg:gbDisplayAllPtsAA					;Display all points (after acquisition)"
	n += 1;	tPn[ n ] =	"PN_SETVAR;	root:uf:dlg:gnWarningLevel				;Warning level (none:1, all:4); 		20; 	%1d ;1,4,1;	"			
	n += 1;	tPn[ n ] =	"PN_CHKBOX;	root:uf:dlg:gbWarningBeep				;Warning beep"
	n += 1;	tPn[ n ] =	"PN_SETVAR;	root:uf:"+sFolder+":dlg:gShrinkCedMemMB	;Decrease Ced mem  (MB);			20;	%.2lf;  .01, 1024, 0; "	// 0 for delta( sLim ) means no up/down fields
	n += 1;	tPn[ n ] =	"PN_SETVAR;	root:uf:"+sFolder+":dlg:gMaxReactnTime	;Max reaction time (s);				20;	%.1lf; .1,   10, 0; "	// 0 for delta( sLim ) means no up/down fields
	redimension  /N = (n+1)	tPn 
End

Function		root_uf_aco_dlg_gShrinkCedMemMB( ctrlName, varNum, varStr, varName ) : SetVariableControl
	string	ctrlName, varStr, varName
	variable	varNum
	print "root_uf_aco_dlg_gShrinkCedMemMB  ctrlName:", ctrlName
	nvar		gShrinkCedMemMB	= root:uf:aco:dlg:gShrinkCedMemMB
	nvar		gCedMemSize		= root:uf:aco:co:gCedMemSize
	gShrinkCedMemMB	= min( gCEDMemSize / MBYTE, gShrinkCedMemMB )
	ApplyScript_( kbKEEP_ACQ_DISP )							// necessary for the changed settings to be effective at the next 'Start'
End

Function		root_uf_aco_dlg_gMaxReactnTime( ctrlName, varNum, varStr, varName ) : SetVariableControl
	string	ctrlName, varStr, varName
	variable	varNum
	//print "root_uf_aco_dlg_gMaxReactnTime  ctrlName:", ctrlName
	ApplyScript_( kbKEEP_ACQ_DISP )							// necessary for the changed settings to be effective at the next 'Start'
End

//------------------------------------------------------------------------------------------------

Function		root_uf_aco_dlg_raTrigMode( sControlNm, bValue )
// Sample: if the proc field in a radio button in tPanel is empty this function (with auto-built name)  is called (if it exists) .  Advantage: No need  to specify the proc field in the panel line.
	string	sControlNm
	variable	bValue									// is useless as it is always 1 for a radio button
	string  	sFolder	  = ksfACO
	nvar		raTrigMode= $ksROOTUF_ + sFolder + ":dlg:raTrigMode"
	// printf "\r\tProc (RADIO)\t\traTrigMode : %d   (%s) \r", raTrigMode, sControlNm
	//wave 	wG		= $ksROOTUF_ + sFolder + ":keep:wG"	  				// This  'wG'  	is valid in FPulse ( Acquisition )
	//wave  /T wIO	= $ksROOTUF_ + sFolder + ":ar:wIO"  					// This  'wIO'	is valid in FPulse ( Acquisition )
	//wave  	wRaw	= $ksROOTUF_ + sFolder + ":keep:wRaw"		
	//wave  /T wVal	= $ksROOTUF_ + sFolder + ":ar:wVal"  					// This  'wVal'	is valid in FPulse ( Acquisition )
	//wave 	wFix		= $ksROOTUF_ + sFolder + ":ar:wFix" 					// This  'wFix'  	is valid in FPulse ( Acquisition )
	SwitchTriggerMode_( sFolder )//, wG, wIO, wVal, wFix )
End

Function		SwitchTriggerMode_( sFolder )//, wG, wIO, wVal, wFix )
	string  	sFolder
	//wave /T wIO, wVal 
	//wave  	wG, wFix
	variable	hnd	= CedHandle_()
	nvar		raTrigMode	= root:uf:aco:dlg:raTrigMode
	//nvar	gbRunning	= root:uf:aco:co:gbRunning
	nvar		gbRunning	= root:uf:aco:keep:gbRunning
	nvar		gbAcquiring	= root:uf:aco:co:gbAcquiring
	string	sMode		= SelectString( raTrigMode, 	"  to normal SW " , "  to HW E3E4  " )
	string	sAcq		= SelectString( gbAcquiring, 	" during pause" , " during acquisition" )
 	// printf "\r\tSwitchTriggerMode_()\traTrigMode : %d     running: %d    acquiring : %d \r", raTrigMode, gbRunning, gbAcquiring
	StartStopFinishButtonTitles_( sFolder )						// As the user has switched a basic mode  the button titles are updated 
 	FinishFiles_( sFolder )										// As the user has switched a basic mode  a new file is started
 	variable	bApplyScript	= TRUE
	StopADDA_( "\tFINISHING ACQUISITION  by  switching trigger mode" + sMode + sAcq , bApplyScript, hnd )	//   invoke   ApplyScript_() 
End

Function		root_uf_aco_dlg_gbAppendData( sControlNm, bValue )
// 060511f   Append mode comments  and renaming
// The usage of the  'Load Script' button   and the  'Append data' checkbox  sometimes leads to user complaints and confusion but the implementation should actually be that way.
// If the 'Append data' mode  is ON  and the user then loads a new script  the new data will be appended to the old data file (file name will NOT increment).  This is a special but desired behaviour of FPulse as it allows to continue the data file even if the script changed!
// If the 'Append data' mode  is ON  and the user then loads a new script  AND wants to start a new file witththe incremented file name he/she has to  click the 'Append data' checkbox  TWICE.
	string	sControlNm
	variable	bValue
	FinishActionProc_() 			// Most probably the user wants to start a new  file after he/she has switched this basic mode. Includes Button update.
End

//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//      DIALOG  :   MISCELLANEOUS  PANEL ---  NEWSTYLE

Function		Dilg_Miscellaneous( nMode )
	variable	nMode					//  kPN_INIT  or  kPN_DRAW
	string  	sFBase		= ksROOTUF_
	string  	sFSub		= ksfACO_	
	string  	sWin		= "misc" 		// was "mis" 	// 2009-12-12 old-style      renamed from  'mis'  to  'misc'  to avoid confusion with new-style

	string	sPnTitle		= "Miscellaneous"
	string	sDFSave		= GetDataFolder( 1 )						// The following functions do NOT restore the CDF so we remember the CDF in a string .
	if ( PossiblyCreateFolder( sFBase + sFSub + sWin ) )	
		// variable	/G	raCfsHeadr00	// todo ..ugly code   .................as the automatic creation is too late.........-> should automatically be created early enough.............		
	endif
	SetDataFolder sDFSave											// Restore CDF from the string  value
	stInitPanelMiscellaneous1( sFBase + sFSub, sWin )					// fills big text wave  'sPnOptions' (=wPn)  with all information about the controls necessary to build the panel
	Panel3Sub(   sWin, 	sPnTitle, 	sFBase + sFSub,  100, 95,  nMode)	// Compute the location of panel controls and the panel dimensions. Draw the panel displaying and hiding needed/unneeded controls.  Prevents closing
	PnLstPansNbsAdd( ksfACO,  sWin )
End

static Function	stInitPanelMiscellaneous1( sF, sPnOptions )
	string  	sF, sPnOptions
	string	sPanelWvNm = sF + sPnOptions
	variable	n = -1, nItems = 20
	// printf "\tInitPanelMiscellaneous1( '%s',  '%s' ) \r", sF, sPnOptions 
	make /O /T /N=(nItems)	$sPanelWvNm
	wave  /T	tPn	=		$sPanelWvNm
	// Cave / Flaw :   No tabcontrol = empty  'Tabs'  must have   different number of spaces (no Tab, not the empty string )  to be recognised correctly
	// Cave / Flaw :   For each item in  'Tabs'   there must be a  corresponding  'Blks'  entry  even if empty
	// Cave / Flaw :	   Only tabulators can be used  for aligning the following columns, do not use spaces.... (maybe they are allowed...)
	
	//					Type  NxL Pos MxPo OvS  Tabs	Blks		Mode		Name		RowTi				ColTi		ActionProc		XBodySz	FormatEntry	Initvalue		Visibility	SubHelp
	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	°:		,:		1,°:			ShowKeysDe:	Keywords and defaults:			:	fShowKeysDef_():	:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	°:		,:		1,°:			Test1401Dl:	Test CED1401:				:	fTest1401Dlg_():	:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	°:		,:		1,°:			KillGraphs:		Kill all graphs:				:	fKillAllGraphs_():	:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:		,:		,:			dum10:		:							:	:				:		:			:			:		:	"		//	single separator needs ',' 
	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	°:		,:		1,°:			DisplayRaw:	Display raw data (after Acq):	:	fDisplayRaw_():	:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"CB:	   1:	0:	1:	0:	°:		,:		1,°:			AcqCheck:	Quick check (after Acq/TG)   :	:	:				:		:			:			:		:	"		// 	
	n += 1;	tPn[ n ] =	"CB:	   1:	0:	1:	0:	°:		,:		1,°:			TimeStats:		Show timing statistics:		:	:				:		:			:			:		:	"		// 	
	n += 1;	tPn[ n ] =	"CB:	   1:	0:	1:	0:	°:		,:		1,°:			ImprStimTi:	Search improved stim timing:	:	:				:		:			:			:		:	"		// 	
	n += 1;	tPn[ n ] =	"CB:	   1:	0:	1:	0:	°:		,:		1,°:			RequireCed:	Require Ced1401 hardware:		:	:				:		:			fRequireCedInit_()::	:	"		// 	
#ifdef dDEBUG	
	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:		,:		,:			dum20:		:							:	:				:		:			:			:		:	"		//	single separator needs ',' 
	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	°:		,:		1,°:			buStopBkg:	Stop background task / kill Acq:	:	fStopBkg_():		:		:			:			:		:	"
	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	°:		,:		1,°:			buTestAcq:	Test acquisition:				:	fTestAcq_():		:		:			:			:		:	"
#endif

	redimension  /N = ( n+1)	tPn
End

Function		fShowKeysDef_( s )
// Called when a button is pressed.  ALSO CALLED when moving the mouse over a button.  See  'fButtonProc_struct()'  on how to avoid this event.
	struct	WMButtonAction &s
	// print "fShowKeysDef_", s.eventcode
	if (  s.eventCode == kCCE_mouseup ) 
		// print s.ctrlName
		ShowKeysForUser()
	endif
End

Function		fTest1401Dlg_( s )
// Called when a button is pressed.  ALSO CALLED when moving the mouse over a button.  See  'fButtonProc_struct()'  on how to avoid this event.
	struct	WMButtonAction &s
	if (  s.eventCode == kCCE_mouseup ) 
		print s.ctrlName
		// 2021-03-10 old-style weg
		//Test1401Dlg()
		Dilg_Test1401( kPN_DRAW )		// 2021-03-10 new-style
	endif
End

Function		fKillAllGraphs_( s )
// Called when a button is pressed.  ALSO CALLED when moving the mouse over a button.  See  'fButtonProc_struct()'  on how to avoid this event.
	struct	WMButtonAction &s
	if (  s.eventCode == kCCE_mouseup ) 
		print s.ctrlName
		stKillAllGraphs()
	endif
End

Function		fDisplayRaw_( s )
// Called when a button is pressed.  ALSO CALLED when moving the mouse over a button.  See  'fButtonProc_struct()'  on how to avoid this event.
	struct	WMButtonAction &s
	if (  s.eventCode == kCCE_mouseup ) 
		string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
		string  	sFo	 	= GetUserData( 	s.win,  s.ctrlName,  "sFo" )							// as passed from 'PanelButton3()'   e.g.  'root:uf:aco:' 
		printf "\t\t%s\t\t%s\t%s\t%s\t\t \r",  pd(sProcNm+"(s)",15),  pd(s.CtrlName,31),	 pd(sFo,17),  	pd(s.win,9)
		wave  	wG		= $sFo + "keep:wG"  								// This  'wG'	is valid in FPulse ( Acquisition )
		wave  /T	wIO		= $sFo + "ar:wIO"  								// This  'wIO'	is valid in FPulse ( Acquisition )
		wave  	wFix		= $sFo + "ar:wFix"  								// This  'wFix'	is valid in FPulse ( Acquisition )
		string  	sFolder	= ReplaceString( ksROOTUF_, RemoveEnding( sFo ), "" )		// e.g.  'root:uf:aco:'  ->  'aco'
		DisplayRawAftAcq_( sFolder, wG, wIO, wFix )
	endif
End

Function	/S	fRequireCedInit_( sBaseNm, sFo, sWin )
// callled via 'fPopupListProc3()'
	string		sBaseNm, sFo, sWin
	return "~"+ num2str( kbIS_RELEASE)  + ";"		// allows the user to run the program without Ced1401 (is useful  e.g. in ReadCfs or in  Stimulus construction) . 	 Syntax: ~0; or ~1;   acts on remaining  (in this case: all) values 
End


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	BUTTON  PICTURES

// PNG: width= 355, height= 15
static Picture cb6ScriptEditHide
	ASCII85Begin
	M,6r;%14!\!!!!.8Ou6I!!!%0!!!!0#Qau+!5@DP,6.]D&TgHDFAm*iFE_/6AH5;7DfQssEc39jTBQ
	=U";FEq5u`*!m9@nP'1!=]>6:XV2U]s%?ut)bOCOq).tWis<2::^=M]NF#Ck)b^e8b=d"B\s"URRf6
	tgJd*ZNhVdXhM5m!/5cdWcFYGSkf:o/8Co[%#<VpH+&!2rDnEG.r8!k%300S/qbtl1Q$*$mlh"D7@7
	/Z"]`GH_3NGc[$3"UIAcY]lNij2N>>d`]7js,\CX);?2g%(\[UtD;1*)0bkO8\U8tK[9UGmBJcIW8.
	TfeG@t^a_0Yr]->JT@kacpAGIH(p]E!Ie^/-?r(Ddm_G"RB(80ToS(U[0DdJ`_O-"5K8]tM+m]Y'3Z
	Q=Yp>I_RNo/^*GRqttZb"`OSJ7iX+:du6$$=J\mrJBc?`+K%U;f6*S-k2Wk=2f@F`_o/ImSk(Aub@7
	eYX-Lk>r]=fS>-6q6XtN_sq>9>65NnUWrV6BZ6iF&&,?h3MWDo%LP*+1?d;$)a5nKoZ!s"AA1n.2n=
	V@^u3GFKX#p@;g?Fhi#,ZZ##:,0aBS&"+0o/pR4N/fXTGojG-ZWWDA=Y.aZH6qK/'[k(*laj5\iTVW
	lA#t%.UY1<DP)u>;N-;qciJ.&Lc[(O)D)Mu:)+tMW^GZWOHDP[m,7+Z[Ki!FJ%),0!_KHc?>TG.(>T
	>!PBbE*dTLggO/mT;C?Y_QhjTi<Fd=P*=o=0p[("r\6PE17S:dU8+%0auhd=P)aK#1&m-Z<H,.h40E
	JrK%(I'DXc6L<\:6,J1@k"XXeLkCV=J9qs)JQ!d"",>K<;"D]En;e9@%>D0hl!bE04t_3PFFHp0&dc
	8s`sM#?Kh.t[-;H8?/knFl=X$.9$5#SA!SYL%"gs0P=^:d4lmZ'E!><5X6kTUKE.E+'(lBn7W5A%b'
	Ggn3$a_G#7A/:nL9Vh_.[k+XJtT&@`,G/V"f\5q-7]A\#pY[*Ol._LMQch1+Hka6Pb'WUUl*/g]a99
	UrQNYQOi@SS\POXug/K@!"g)VF-P$SZ72#[*C>d:2"U/)-TGGK]OV$tZKiF"mC.fc7^6*;'WC:eq,R
	d\Qn:ah`"M\E!U.[dA:dSD['u$?X:s='\_QX$Uo/td9,Q(nP)\H?,jhK>\'`a2;)\;p0r:9)UjnTkC
	55s1)e.Fuoo;^V1I.t?]//H:fRL7c)i&Hb]P)/fP9s$+Z,bD\qS&-#Y=(>4V?C_`Vr0;=8k\t,th)k
	(#poE0McoF)fJBWDpPah#!%N$]&1h)i4"S_Ae-lbKD!.`T[4m(XM*#orWcbY`?X]Fs<s,E"tW85i'*
	T#W*>$AKY[6&]AgP>R[LKSiR3/>bA`6@S"Q$c4C'$U;nOMeRiCn/BI8Rc:Ti?+OpA]qVgK1u=G!!#S
	Z:.26O@"J
	ASCII85End
End

// PNG: width= 339, height= 15
static picture	cb6WatchWrite339c
	ASCII85Begin
	M,6r;%14!\!!!!.8Ou6I!!!$u!!!!0#Qau+!7hdp)ZTj<&TgHDFAm*iFE_/6AH5;7DfQssEc39jTBQ
	=U"/&4R5u`*!m@1@uj"Lm,WG=<`B.cCk'^u?LCY*`CdA9+C^uukN.?^B1YM4IjJ3a'`b7>Hqhk1@n=
	L(99OrORQ-k([(D)N"u;3mJ%VJ2L!Wo..8DR\8iMObjXTCc*`/rH.Y6+)1Ci8OJQ,uaV&VdcRkGO05
	EK9q?3d&IK?pVgTm3m&;7[;JJhOG>mp\5cPZ@iH)S51o]$rqZ3W34:i\XB-A,r)H`7A&^F)(TfRg4(
	pdc3W0dNTmfMp<rc(Lm?R0tho9?3!MI_I:+t<<,91Y[_!TBP-b/;N^"Q!^gj6C(qYeUKrS,lgDR$\A
	lfKSXo%e>9rJ.4@p$'l-k*WDXmK"Ham7gmP\sDX1,Pt)SHZL"jp<k"hqXbWpTH@W!H)OF29o[G[oQ%
	J?HF6=n:B5XOHB#EA?2)*H#!l<,"cFY!lPbKgUT9<)72!rd3PCC.4)fY2bO]@YB$M9FkGquX3V'nj<
	1!b]j5,OhU[l.*<1(Qu%.N,.rM/qtZW&p>.SSmZL2FOm4R8OAF>QeYF"g?QV[_C(O*K5;$g;8qeE:e
	VQf5H(_nAb4i#Mgq0lST>8,QcNDJT$5'_BI-lYVjelZQLM)m-B4VcCD\N2ZQ-5c9*-09<K1USXD0N2
	ZP@cl"nsg1g6J<q>Z@5HI'h3b,'V40@Aq9&?-%L\6Ei46pE1H`oaV>[:g!!O:ggA&h%^LXp2#_tn,g
	A!u!h0.GiHhK9`Np80M.P&PG!c?kE?&TYLp7'+C"ZZgN"VdPf+Xi?2=d<Uk%Op!e[PL\!F:0&IcPTZ
	NA+4*E`P-5MpOQPs$$[rk*hG0@!D1(dXS#-MU9CFO^(Y&7;e[oOf6^bGL;n\[o3L#@.1t>6+cWG-3"
	U:&&Rd-_`hbkfsdo7uL#mUI,P/#bpFFqL=g!&N<@t:PN+Qp3tQYqk"IM@fuN<3E0f)-pICYBBWjF@>
	gSkVDjQ\(pI2GhK-OKUk[$k8Z,eSude<1c`hV"XL;-Qba8M@k%&8/Z1j:BWPjO<#@\^n!U]ID0eN:F
	;7nj=,k3-Vr2JhLpr1)]e]r*(QXH/(:TekMuGu$hB^RBYlCU(Difak]1Br;-Hb,s)pQ60`gRW^AZij
	ecoSVc%kJ/Xn>f>C`IWArNu:c-g>j@^mVW^dR$4Dhs.&4mp!JHpe[$#1cBiaQ^.r+Ws9oIqu\RsgL0
	Y]]_;C+!!#SZ:.26O@"J
	ASCII85End
End

