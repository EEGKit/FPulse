// UF_PulsMain.ipf
// 
//	contains the main program entry point  FPuls()  when FPuls is started via Igors main menu ( FPuls.IPF controls the menu entry )
//	contains initialization routines: define folders, globals
//	contains the main FPuls panel  and some of its short functions 
//	contains the Preferences panel
//
// Comments:
//	in FPULS (and in other program parts)  there are 5 intermediate stages in which to display data (=waves)
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


// The big improvements of this version (and why the progress is slow...)
//		Faster Script loading:
//			- achieved by more appropriate data structures and code, this is mostly finished and seems to be OK
//		Blanks are allowed anywhere in the script, but this requires further modifications:
//			- NewDS  (New Data section) user setting which controls whether store sections interrupted by a nostore section are to be  stored in the CFS file as 1 or 2 data sections
//			- Better stimulus display, preferably of the 'Split axis' type :  do NOT display nostore sections but do display short stubs indicating that there is a skipped section. Display TRUE time scale.
//		Only the short Stored-IO (=TapeIO) waves are held in memory. The formerly used BigIO waves  which included nostore periods are no longer used as they clogged the memory.
// 			- It must be ensured that the DAC puts out any desired value also during nostore-periods.  The user will have to supply short 'Store' stubs (1 data point is sufficient) with the desired nostore Dac value.			












#pragma  rtGlobals 	= 1					// Use modern global access method. 	Do not use a tab after #pragma. Doing so will give compilation error in Igor 4.
#pragma  IgorVersion = 6.00				// prevents the attempt to run this procedure under Igor4 or lower. Do not use a tab after #pragma. Doing so will make the version check ineffective in Igor 4.
#pragma  ModuleName= FPPulseProc


#define   dDEBUG						// Comment this line for a Release version (this automatically done in the Release process)


#include <Decimation>					// decrease number of display data points to speed up drawing...
#include <PerformanceTestReport>			// measure how much time is spent in various parts of the program code 

// General  'Includes'
#include "UFCom_Constants"
#include "UFCom_ColorsAndGraphs"
#include "UFCom_DataBase"
#include "UFCom_DataFoldersAndGlobals"
#include "UFCom_DebugPrint"
#include "UFCom_DirectorySelection"
#include "UFCom_DirsAndFiles"
#include "UFCom_Errors"
#include "UFCom_Help"
#include "UFCom_Ini"
#include "UFCom_LineProcessing"
#include "UFCom_ListProcessing"
#include "UFCom_Memory"
#include "UFCom_Notebooks"
#include "UFCom_Numbers"
#include "UFCom_Panel"
#include "UFCom_PixelsAndPoints"
#include "UFCom_ReleaseComments"			// 2006-1031
#include "UFCom_Timers"

#include "UFPE_Actions"					
#include "UF_Acq_Actions"		//REMOVE			
#include "UFPE_Cursors"					
#include "UFPE_EvPoints"					
#include "UFPE_Listbox"					// for the Acquisition display listbox
#include "UFPE_UtilFilter"
#include "UFPE_UtilCutting"
#include "UFPE_Digout3"
#include "UFPE_Fit"
#include "UF_Acq_Fit"		//REMOVE
#include "UFPE_FitFunctions"	

// 2008-07-24 should be separated and later made obsolete
//#include "UF_AcqCed"					
//#include "UF_AcqCfsWrite"
//#include "UF_AcqDisp"
//#include "UF_AcqStim"	
//#include "UFPE_ChunksAndTimes"

#include "UFPE_Constants3"
#include "UFPE_Script3"//Old"
#include "UFPE_Stim3"//Old"		// includes UFPE_ChunksAndTimes

#include "UFPE_ConvertScript3to4"

// 2008-03-01 New-style script
#include "UFPE_Script4"
#include "UFPE_StimDisp4"
#include "UFPE_StimTiming"

#include "UF_AcqStimDisp4"
#include "UF_AcqActions"					
#include "UF_AcqComments"					
#include "UF_AcqPnMisc"
#include "UF_AcqPnPrefs"
#include "UF_AcqScript"
#include "UF_AcqScriptActions"
#include "UF_AcqUtilities"

#include "UF_AcqDispCurves"

// 2008-03-01 New-style script
#include "UF_AcqCed4"					
#include "UF_AcqCfsWrite4"
#include "UF_AcqDisp4"
#include "UF_AcqDispCurves4"
#include "UF_AcqStimControlbar"


#include "UF_AcqDispControlbar"
#include "UF_AcqOLASelect" 
#include "UF_AcqOnLineA"

#include "UF_AcqWriteSettings"

// old.........The test functions in the file  'UF_Test.ipf'  are not to be distributed to the user :  The code in   'UF_Test.ipf'  is automatically deleted in the Release version (but the empty wrapper 'UF_Test.ipf' is supplied)
// Alternate approach to prevent distribution to the user:  Rename 'UF_Test.ipf'  to  'Test.ipf'  to prevent copying to the release directory  and  automatically delete the preceding  line '#include "UF_Test" '  in FPulsMain and in FEvalMain	
#ifdef dDEBUG	
#include "_UF_AcqTest_4"						// The leading underscore prevents that this file is released to the user  but ALSO   #ifdef dDEBUG is required  to prevent  #including  this file in the Release version
#include "_UF_AcqTestMC700"						// The leading underscore prevents that this file is released to the user  but ALSO   #ifdef dDEBUG is required  to prevent  #including  this file in the Release version
#endif

strconstant	ksACQ			= "acq"			// the subfolder for the  'acquisition'  variables. Do not change as action proc names (and globals in panels) depend on it.
strconstant	ksACQ_			= "acq:"			// the subfolder for the  'acquisition'  variables. Do not change as action proc names (and globals in panels) depend on it.

strconstant	ksF_ACQ_PUL		= "acq:pul"		// the main acquisition subfolder
strconstant	ksFPUL			= "pul"			// the main acquisition subfolder

static strconstant	klstDEBUGPRINT	= "Timer;ShowLines;ShowKeys;ShowIO;ShowVal;AmpTime;ShowEle;Expand;Digout;OutElems;Telegraph;Ced;AcqDA;AcqAD;CfsWrite;DispDurAcq;"


//=====================================================================================================================================


static   Function		CreateGlobals( sFo, sIniBasePath )
// The folder hierarchy is not trivial as it must fulfill certain requirements
// 1. The folder path must be short as of Igor's 31 character limitation for function names and even shorter for control names.
// 2. Depending on the state of the program (FPuls and FEval running, only  1 running, none running, new script loaded) some folders are completely cleared/removed.
// 3. For some subfolders the folder path must include  'sFolder'  (e.g. 'ac'  and  'ev' )  to discriminate between  FPuls  and  FEval 
	string  	sFo, sIniBasePath
	string  	sSubFoIni	= "FPuls"							// = ksPN_INISUB  (do not change!)
	string		sDFSave	= GetDataFolder( 1 )					// remember CDF in a string.

	UFCom_PossiblyCreateFolder( "root:uf:" + sFo )				// creates  'root:uf:acq' .  Holds subfolders  'ar' , 'stim' , 'dig' , 'store' , 'io' , 'co' , 'dispFS'  which are cleared whenever a new script is loaded.
// 2009-04-22
	NewDataFolder  /O/S 	$"root:uf:" + sFo + ":" + ksfACQVARS

//	//  The SUBFOLDERS to the following folder are cleared whenever a new script is loaded. 
//	NewDataFolder	/O	$"root:uf:" + sFo					// creates  'root:uf:acq' .  Holds subfolders  'ar' , 'stim' , 'dig' , 'store' , 'io' , 'co' , 'dispFS'  which are cleared whenever a new script is loaded.

UFCom_IniFile_Read( sFo, sSubFoIni, sIniBasePath )

UFCom_PossiblyCreateFolder( "root:uf:" + sFo + ":dispFS" )		// for acquisition display  old-style and new-style

	// The following folders keep their variables when switching between FPuls and FEval. They are cleared only when both FPuls and FEval are closed.
// 2009-12-12 old-style
//	UFPE_CreateGlobalsInFo_Script( sFo )						// for data which are not cleared when a script is loaded e.g. 'wMK', 'wSK' , 'gsMainkey'  and 'ScriptPath'   

	UFCom_CreateGlobalsInFold_Misc( sFo )

// 2008-07-25
//	// Stimulus display panel : reconstruct it the way the user left it the last time (position, size, hidden/visible state  is stored) 
//	PanelStimulusDisp_a( sFo, ksACQ_SD, UFCom_kPANEL_INIT )	// 2005-0815 create a hidden panel just to construct globals like  'gbDisplay'  
//
//	// Comments panel :  reconstruct it the way the user left it the last time (position, size, hidden/visible state  is stored) 
//	PanelComment( UFCom_kPANEL_INIT )			// 2006-0515 Construct Comment panel invisibly  at startup. The panel must be constructed during initialisation because its automatic globals are needed. 

	// The following folders hold FPuls variables. The variable in these folders  'cfsw' , 'ola' , 'disp' , 'dlg' , 'keep' , 'std'   keep their values when a new script is loaded. They are cleared when FPuls is closed.
// 2008-07-25  ALL folders should be cleared when a new script is loaded:  also  script , cfsw , disp.   Perhaps misc , dbgprint, com 
	CreateGlobalsInFolder_CfsWrite()						// create 'root:uf:acq:cfsw'
	CreateGlobalsInFolder_OLA()						
 
 	CreateGlobalsInFolder_Disp()

	CreateGlobalsInFolder_Keep( sFo )						// creates  'root:uf:acq:keep'   or  'root:uf:acq:pul'

//old	UFCom_DebugPrintPrepare( sFo, klstDEBUGPRINT )		// Creates all debug print variables.  This is better than creating them later 1 by 1 as then the panel  would have to adjust every time a new variable is added.

	SetDataFolder sDFSave								// restore CDF from the string value

	variable	/G	root:V_marquee = 1//=1	// 0 / 1 enable / disable live update of marquee variables (V_top..)
	variable	/G	root:V_left,  root:V_right,  root:V_top,  root:V_bottom
End

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function		CreateGlobalsInFolder_Disp()
// creates all folder-specific variables. To be used once from CreateGlobals() as the current data folder is changed and not restored
	NewDataFolder  /O  /S root:uf:acq:disp				// analysis : make a new data folder and use as CDF,  clear everything
	variable	/g	gR1x = 0, gR1y = 0, gR2x = 0, gR2y = 0	
	variable	/g	gR1gR2_SeemNotNecessary
	if ( ! FP_IsRelease() )
	endif
End

// 2008-07-18 not used ???
//static Function		Cleanup( sFolder )   
//	string  	sFolder
//	KillAllGraphs()									// Required before waves can be deleted (possible refinement: kill only those graphs containing waves from folders to be deleted  OR even finer: keep the graphs but remove those waves form graph)
//	UFCom_PossiblyKillPanel( UFCom_PrefPanelName( sFolder ) ) 
////	UFCom_PossiblyKillPanel( ksF_MIS )					// had to be removed because ksF_MIS has been made static.   ??????????
//	UFCom_PossiblyKillPanel( ksACQ_SD ) 				// the StimDisp panel in Acq  'sda'
//	UFCom_PossiblyKillNotebook( ksSCRIPT_NBNM )
//	UFCom_KillDataFoldUnconditionly( "root:uf:acq:cfsw" )	
//	UFCom_KillDataFoldUnconditionly( "root:uf:acq:ola" )	
//	UFCom_KillDataFoldUnconditionly( "root:uf:acq:disp" )	
//	UFCom_KillDataFoldUnconditionly( "root:uf:" + sFolder )	// kills all subfolders
//End



static Function	CreateGlobalsInFolder_Keep( sFolder )
// 2006-0127 This data folder(s) are not deleted on loading a new script. Perhaps these are thre cause for memory fragmentation?
// creates all folder-specific variables. To be used once from CreateGlobals() as the current data folder is changed and not restored
	string  	sFolder
	NewDataFolder  /O  	     $"root:uf:" + sFolder + ":" + UFPE_ksKEEPwr	// acquisition: make a new data folder for wRaw
	NewDataFolder  /O         $"root:uf:" + sFolder + ":" + UFPE_ksKEEPwl	// acquisition: make a new data folder for wLines
	NewDataFolder  /O         $"root:uf:" + sFolder + ":" + UFPE_ksKPwg	// acquisition: make a new data folder for wG
	
	NewDataFolder  /O  /S  $"root:uf:" + sFolder + ":" + UFPE_ksKEEP	// acquisition: make a new data folder and use as CDF,  clear everything
//	variable	/G	gnProts	= 1								// for all general acquisition variables which keep their state when a new script is loaded, e.g. gnProts

	variable	/G	gbRunning		= 0						// for all general acquisition variables which keep their state when a new script is loaded....
	variable	/G	gnTicksStart		= 0		
	variable	/G	gnTicksStop		= 0		

// Defining some panel variables right here is practical (though not mandatory) : It allows to comment out the corresponding panel lines without having to comment out all occurrences of the variable throughout the whole program.
// It makes the code also  also independent of the settings of     kSTATUS_DO_DISPLAY_PANEL
// If the variables were not defined here this would lead to linker errors because of undefined variables, which do not exist as they have not been automatically constructed during the panel building process.
	variable	/G	vdPredict0000		= 1
	variable	/G	svPrevBlk0000		= 0
	variable	/G	svBlockCnt0000	= 0
	variable	/G	svSwpsWrt0000	= 0
	variable	/G	svSwpsTot0000		= 1
	variable	/G	svTmElaps0000		= 0
	variable	/G	svTotSecs0000		= 1

End



Function		FPuls()
// This is the  PROGRAM  ENTRY  POINT  when the program is started via 'Menu -> Analysis -> FPuls' 
// This is NOT executed when the program is started via  'Open experiment' ...
//  ..but still cold start via menu / IPF  and  warm start  via  Pxp must work  (and possibly supply new  objects)
// !!! Do not change the function name  'FPuls()'   as  it is used as an argument to FunctionPath()  (and possibly/probably at other places...)   

	// printf "\tFPuls() Program start 		 current DF:'%s'   \r", GetDataFolder(1) 
	string  	sSubFoIni		= "FPuls"										// = ksPN_INISUB  (do not change!)
	string  	sIniBasePath	= FunctionPath( ksFP_APP_NAME )					// the Ini file containing the window position will be written in a subdirectory parallel to UF_PulsMain.ipf 

// 2008-07-25
UFCom_KillDataFoldUnconditionly( "root:uf:acq" )

  	string  	sFo	= ksACQ
  	CreateGlobals( sFo, sIniBasePath )
	if ( Initialize() )
												// DeleteGlobals ...
		return	UFCom_kERROR									
	endif

	PanelPulse()									// first main panel window  on the LEFT/ right   new style

	PanelMiscellaneous( 	  UFCom_kPANEL_INIT)			// all subpanels must be constructed _AFTER_ the main panel  as their visibility must set the  corresponding button in the main panel

	PanelDataUtilities_a(  UFCom_kPANEL_INIT )			

// todo 20090130  change to UFCom_kPANEL_INIT
//	PanelPreferencesAcq( UFCom_kPANEL_DRAW )		// 2006-0515 Construct AND display  Preferences  panel early (at least before 'SearchAndSetLastUsedFile()' ) as only afterwards  Warnings/Errors work [ 'prfa' needed in 'DoAlert()']
	PanelPreferencesAcq( UFCom_kPANEL_INIT )		// 2006-0515 Construct AND display  Preferences  panel early (at least before 'SearchAndSetLastUsedFile()' ) as only afterwards  Warnings/Errors work [ 'prfa' needed in 'DoAlert()']

// 2008-07-25 here
// 2009-12-12 old-style
//	PanelStimulusDisp_a( sFo, ksACQ_SD, UFCom_kPANEL_INIT )	// Stimulus display panel : reconstruct it the way the user left it the last time (position, size, hidden/visible state  is stored) 
	PanelComment( UFCom_kPANEL_INIT )				//  Comments panel : The panel must be constructed during initialisation because its automatic globals are needed. Reconstruct it the way the user left it the last time...

																				// We cannot allow to... 
	UFCom_EnableButton( "pul", 	"root_uf_acq_pul_ApplyScript0000",	  UFCom_kCo_DISABLE )		// ..apply a script at cold startup before it has been loaded a first time
	UFCom_EnableSetVar( "pul", 	"root_uf_acq_pul_gnProts0000",	  UFCom_kCo_NOEDIT_SV)	// ..change the number of protocols as this would trigger 'ApplyScript()'
	UFCom_EnableButton( "pul",	"root_uf_acq_pul_gbShowScrpt0000",  UFCom_kCo_DISABLE )		// ..hide/edit a script at cold startup before it has been loaded a first time
	UFCom_EnableButton( "pul", 	"root_uf_acq_pul_SaveScript0000",	  UFCom_kCo_DISABLE )		// ..save a script at cold startup before it has been loaded a first time
	UFCom_EnableButton( "pul", 	"root_uf_acq_pul_SaveAsScrpt0000",  UFCom_kCo_DISABLE )		// ..save a script at cold startup before it has been loaded a first time
	UFCom_EnableButton( "pul", 	"root_uf_acq_pul_StartAcq0000",	  UFCom_kCo_DISABLE )		// ..go into acquisition at cold startup before before a script has been loaded
	UFCom_EnableButton( "pul", 	"root_uf_acq_pul_StopFinish0000",	  UFCom_kCo_DISABLE )		// ..stop an acquisition at cold startup before before a script has been loaded
	UFCom_EnableButton( "pul", 	"root_uf_acq_pul_DisplayStim0000",	  UFCom_kCo_DISABLE )		// ..display a stimulus before wE and wFix  has been set by reading a script
	UFCom_EnableButton( "pul", 	"root_uf_acq_pul_buDisplStim0000",	  UFCom_kCo_DISABLE )		// ..display a stimulus before a script has been read
	UFCom_EnableButton( "pul", 	"root_uf_acq_pul_buDiacWnAdd0000",UFCom_kCo_DISABLE )		// ..add an acq window to display an acquired trace before a script has been read

	UFCom_EnableSetVar( "pul", 	"root_uf_acq_pul_svPrevBlk0000",	UFCom_kCo_NOEDIT_SV  )	// Setvariable must only display value
	UFCom_EnableSetVar( "pul", 	"root_uf_acq_pul_svBlockCnt0000",	UFCom_kCo_NOEDIT_SV  )	// Setvariable must only display value
	UFCom_EnableSetVar( "pul", 	"root_uf_acq_pul_svSwpsWrt0000",	UFCom_kCo_NOEDIT_SV  )	// Setvariable must only display value
	UFCom_EnableSetVar( "pul", 	"root_uf_acq_pul_svSwpsTot0000",	UFCom_kCo_NOEDIT_SV  )	// Setvariable must only display value
	UFCom_EnableSetVar( "pul", 	"root_uf_acq_pul_svTmElaps0000",	UFCom_kCo_NOEDIT_SV  )	// Setvariable must only display value
	UFCom_EnableSetVar( "pul", 	"root_uf_acq_pul_svTotSecs0000",	UFCom_kCo_NOEDIT_SV  )	// Setvariable must only display value
	UFCom_EnableSetVar( "pul", 	"root_uf_acq_pul_svCursorX0000",	UFCom_kCo_NOEDIT_SV  )	// Setvariable must only display value
	UFCom_EnableSetVar( "pul", 	"root_uf_acq_pul_svWaveMax0000",	UFCom_kCo_NOEDIT_SV  )	// Setvariable must only display value
	UFCom_EnableSetVar( "pul", 	"root_uf_acq_pul_svWaveMin0000",	UFCom_kCo_NOEDIT_SV  )	// Setvariable must only display value
	UFCom_EnableSetVar( "pul", 	"root_uf_acq_pul_svWaveY0000",	UFCom_kCo_NOEDIT_SV  )	// Setvariable must only display value
	UFCom_EnableSetVar( "pul", 	"root_uf_acq_pul_svPointX0000",	UFCom_kCo_NOEDIT_SV  )	// Setvariable must only display value
	UFCom_EnableSetVar( "pul", 	"root_uf_acq_pul_svPointY0000",	UFCom_kCo_NOEDIT_SV  )	// Setvariable must only display value

	UFCom_EnableButton( "disp", 	"root_uf_acq_ola_PrepPrint0000",	UFCom_kCo_DISABLE )		//  ..draw in the acquisition windows before they (and TWA) have been created

	UFCom_EnableChkbox( "pul", 	"root_uf_acq_pul_cbAppndData0000",UFCom_kCo_DISABLE )	// Checking this checkbox executes 'FinishActionProc()' which needs 'root:uf:acq:co:gbAcquiring and root:uf:acq:co:gbIncremFile' which are not created before a script is loaded 

	UFCom_PossiblyCreatePath( UFPE_ksSCRIPTS_DRIVE + UFPE_ksSCRIPTS_DIR + UFPE_ksTMP_DIR )	// creates 'C:UserIgor:Scripts:Tmp'  automatically including  'C:UserIgor:Scripts' .  For  Display Config   and  for  SaveAs

	// Fill the panel with the variables and strings retrieved from the INI file
	SetAppendData( Ini_AppendData() )
	SetAutoBackup( Ini_AutoBackup() )
	SetFileBase(  	 Ini_FileBase() )

	// Retrieve the last recently used script paths  list  from the INI file
	string  	sScriptDir = "",   sScriptPath = "",   lstLRU = ""
	lstLRU	  = UFCom_Ini_Section( sFo, sSubFoIni, "Script", "Path" )							// ini scriptpath load
	ScriptPathLRUSet( sFo, lstLRU )
	sScriptPath = ScriptPathLRUTop_( lstLRU )									

	sScriptDir	  = UFCom_StripFileAndExtension( sScriptPath )
	// print "\tFPuls(a)\tScriptPath  :",  UFCom_Ini_Section( sFo, sSubFoIni, "Script", "Path" ), "      dir:", sscriptdir, "          lstLRU:", lstLRU
	if (  UFCom_PossiblyCreatePath( sScriptDir ) == UFCom_kOK )
		lstLRU	= ScriptPathSet( sFo, ksFPUL, sScriptPath ) 									
		// print "\tFPuls(b)\tScriptPath  :",  UFCom_Ini_Section( sFo, sSubFoIni, "Script", "Path" ), "      dir:", sscriptdir, "          lstLRU:", lstLRU
  		UFCom_IniFile_SectionSetWrite( sFo, sSubFoIni, "Script", "Path", lstLRU , sIniBasePath )		// ini scriptpath save
  		NewPath /O /Q	$UFPE_ksSCRIPTS_SYMPATH,  UFCom_StripFileAndExtension( sScriptPath )	// only drive and directory is left as a symbolic path can never include the file name
		 PathInfo /S 	$UFPE_ksSCRIPTS_SYMPATH;  printf "\t\tFPuls() \t PathInfo: Symbolic path '%s' does %s exist.    ScriptDir  '%s'  is OK. \r", S_path, SelectString( v_Flag,  "NOT", "" ) , sScriptDir
		// PathInfo   /S 	$ksSECU_SYMPATH;  	 printf "\t\tfCustomer(1)  Customer path: '%s' + '%s'  should set the same symbolic path: '%s'  \t  \r", ksSECU_DBPATH, sCustDir_,  s_path
	else
		UFCom_Alert1( UFCom_kERR_FATAL,  "Could not create directory  '" + sScriptDir + "'...." )
		lstLRU	= ScriptPathSet(  sFo, ksFPUL, "" ) 										// 1. The empty string will clear the title line in the popupmen indicating that we currently have no active script file.  2. Or perhaps set to   ' UFPE_ksSCRIPTS_DRIVE + UFPE_ksSCRIPTS_DIR'
	endif
	// print "\tFPuls(d)\tScriptPath  :",  UFCom_Ini_Section( sFo, sSubFoIni, "Script", "Path" ), "      dir:", sscriptdir, "          lstLRU:", lstLRU

	// Retrieve the data path  (e.g.  'C:Epc:Data'   or   'D:Data:Epc'  from the INI file
	string  	sDataDir	= Ini_DataDir()
	if ( UFCom_PossiblyCreatePath( sDataDir )  == UFCom_kOK )				// Build the path  e.g. 'D:Data:Epc'  if it does not exist yet
		DataDirSet(  sDataDir )										// fill the 'DataDir'  Setvariable string input field in the main panel with the  stored value from the INI file 
		SearchAndSetLastUsedFile()									// start with ZZ..... or start with AA...., decrement repeatedly until file exists
	endif															// Note: the DEFAULT path is NOT stored in the INI file.  If this is required it should be done in  'Ini_DataDir()'  and only if initially strlen(sDataDir) == 0

	//PanelMC700( UFCom_kPANEL_DRAW ) 							// Show MCC700B panel always at startup : only while and for testing the MCC700B 
End	


static Function	Initialize()

	DefaultGUIFont all ={  UFCom_ksFONT, UFCom_kFONTSIZE, 0 }			// affects all controls in all panel except those using 'DrawText' 
	Execute "DefaultFont	 /U  	"+ UFCom_ksFONT_							// affects  'DrawText'  (used in some controls)

	// Reserve enough memory for the transfer area
	variable	code, nMinKB, nMaxKB									// 2004-0225	Must be called only ONCE (recommendation of Tim Bergel, CED) 
	//nMinKB	= 1600;	nMaxKB	= 4000								// Seems to work, any smaller values will fail in rare occasions with special scripts e..g. capacitance.txt (TransferAreaPoints 444760, 502000 )
	nMinKB	= 8000;	nMaxKB	= 24000								// Seems to work, any smaller values will fail in rare occasions with special scripts e..g. capacitance.txt (TransferAreaPoints 444760, 502000 )
	//nMinKB	= 16000;	nMaxKB	= 16000								// Seems to work, any smaller values will fail in rare occasions with special scripts e..g. capacitance.txt (TransferAreaPoints 444760, 502000 )
	//nMinKB	= 64000;	nMaxKB	= 80000								// Seems to work, any smaller values will fail in rare occasions with special scripts e..g. capacitance.txt (TransferAreaPoints 444760, 502000 )

	code	 = UFP_CedWorkingSet( nMinKB, nMaxKB, UFCom_kOFF )				// This MUST be  the first XOP used !   Reserves memory so that loading of scripts which are huge (~20MPts) or require a large transfer area (~512kPts) will not fail.

	 // printf "\t\tCedInit  UFP_CedWorkingSet( minKb: %d , maxKB: %d )  returns %d \r", nMinKB, nMaxKB, code

	return	0
End


//=====================================================================================================================================
// THE  NEW  MAIN  PULS  PANEL

Function		PanelPulse()
	string  	sFBase		= "root:uf:"
	string  	sFSub_		= ksACQ_		//  e.g. 'acq:' 
	string  	sWin			= ksFPUL		//  e.g. 'pul' 		the panel
	string		sPnTitle
	sprintf	sPnTitle, "%s %s", ksFP_APP_NAME,  FP_FormatVersion()
	string		sDFSave		= GetDataFolder( 1 )					// The following functions do NOT restore the CDF so we remember the CDF in a string .
	UFCom_PossiblyCreateFolder( sFBase + sFSub_ + sWin ) 	
	SetDataFolder sDFSave									// Restore CDF from the string  value
	InitPanelPulse( sFBase, sFSub_, sWin )						// fills big text wave  'sPnOptions' (=wPn)  with all information about the controls necessary to build the panel
	UFCom_Panel3Main(   sWin, 	sPnTitle, 	sFBase + sFSub_,  100, 0 )			// Compute the location of panel controls and the panel dimensions. Draw the panel displaying and hiding needed/unneeded controls
	//UFCom_LstPanelsSet( ksACQ, ksfACQVARS,  AddListItem( sWin, UFCom_LstPanels( ksACQ, ksfACQVARS ) ) )	
	UFCom_LstPanelsAdd( ksACQ, ksfACQVARS, sWin )	

	UFCom_EnableSetVar(  sWin,  "root_uf_acq_pul_gsDataFileW0000",   UFCom_kCo_NOEDIT_SV )	// read-only
	EnableDisableAxogains( ksACQ )
End


Function		InitPanelPulse( sFBase, sFSub_, sWin )
	string  	sFBase, sFSub_,  sWin				// e.g. 'root:uf:' , 'acq:' , 'pul' 
//	string  	sF								// e.g. 'root:uf:acq:' 
	string		sPanelWvNm = sFBase + sFSub_ + sWin
	string  	sFo	= RemoveEnding( sFSub_ , ":" )
	variable	n = -1, nItems = 200
	 printf "\t\tInitPanelPulse  '%s',  '%s',  '%s'  \r", sFBase, sFSub_, sWin 
	make /O /T /N=(nItems)	$sPanelWvNm
	wave  /T	tPn	=		$sPanelWvNm
	// Cave / Flaw :   No tabcontrol = empty  'Tabs'  must have   different number of spaces (no Tab, not the empty string )  to be recognised correctly
	// Cave / Flaw :   For each item in  'Tabs'   there must be a  corresponding  'Blks'  entry  even if empty
	// Cave / Flaw :	   Only tabulators can be used  for aligning the following columns, do not use spaces.... (maybe they are allowed...)

	//				Type	 NxL Pos MxPo OvS	Tabs			Blks			Mode		Name		RowTi		ColTi			ActionProc	XBodySz	FormatEntry		Initval		Visibility	SubHelp

	n += 1;	tPn[ n ] =	"PM:	   1:	0:	1:	0:	°:			,:			1,°:			pmScrptPath:	:			:			fPmScriptPath():	292:		fScriptPathPops_a():	0000_1:		:		Script Path:		" // 
	n += 1;	tPn[ n ] =	"BU:    1:	0:	6:	0:	°:			,:			1,°:			ReloadScrpt:	Reload :		:			fReloadScript():	:		:				:			:		Reload a script:		"  //	single button
	n += 1;	tPn[ n ] =	"BU:    0:	1:	6:	0:	°:			,:			1,°:			LoadScript:	Browse:		:			fLoadScript():	:		:				:			:		Loading a script:	" //	single button
	n += 1;	tPn[ n ] =	"BU:    0:	2:	6:	0:	°:			,:			1,°:			gbShowScrpt:	Edit ~Hide:	:			fShowScript():	:		fStdColorLst_a():	~0:			:		Show or hide script:	" // no title needed and any BodySz
	n += 1;	tPn[ n ] =	"BU:    0:	3:	6:	0:	°:			,:			1,°:			ApplyScript:	Apply:		:			fApplyScript():	:		:				:			:		Apply Script:		" //	single button
	n += 1;	tPn[ n ] =	"BU:    0:	4:	6:	0:	°:			,:			1,°:			SaveScript:	Save:		:			fSaveScript():	:		:				:			:		Save Script:		" //	single button
	n += 1;	tPn[ n ] =	"BU:    0:	5:	6:	0:	°:			,:			1,°:			SaveAsScrpt:	Save as:		:			fSaveAsScript():	:		:				:			:		Save Script As:		" //	single button

	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:			,:			1,°:			dum2:		:			:			:			:		:				:			:		:				" //	single separator needs ',' 
	n += 1;	tPn[ n ] =	"BU:    1:	0:	5:	0:	°:			,:			1,°:			StartAcq:		Start:			:			fStart():		:		:				:			:		Start Acquisition:	" //	single button
	n += 1;	tPn[ n ] =	"BU:    0:	1:	5:	0:	°:			,:			1,°:			StopFinish:	Finish:		:			fStopFinish():	:		:				:			:		Stop and Finish:		" //	single button
	n += 1;	tPn[ n ] =	"STC:  1:	0:	5:	1:	°:			,:			1,°:			gnAcqStatus:	:			:					:	:		fAcqTitleColorLst():	:			:		Acquisition status:	"
	n += 1;	tPn[ n ] =	"PM:	   0:	2:	5:	1:	°:			,:			1,°:			pmTrigMode:	:			Trig:			fTrigMode():	70:		fTrigModePops():	0000_1:		:		Trigger mode:		" // 	1-dim  popmenu (1 row)
	n += 1;	tPn[ n ] =	"BU:    0:	4:	5:	0:	°:			,:			1,°:			gbWriteMode:	watch~write:	:			fWatchWrite():	:		fWatchWriteColLst():	~0:			:		Watch and Write:	" 
	n += 1;	tPn[ n ] =	"SV:    1:	0:	3:	0:	°:			,:			1,:			gnProts:	 	Protocols:		:			fProts():  		40:		%2d; 1,9999,0:		~1:			:		Protocols:			" // !!! folder KEEP
	n += 1;	tPn[ n ] =	"CB:	   0:	1:	3:	0:	°:			,:			1,°:			cbAppndData:	Append Data:	:			fAppendData():	:		:				~0:			:		Append Data:		"
	n += 1;	tPn[ n ] =	"CB:	   0:	2:	3:	0:	°:			,:			1,°:			cbAutoBckup:	Auto Backup:	:			fAutoBackup() :	:		:				~0:			:		Automatic backup:	"
	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:			,:			,:			dum4:		:			:			:			:		:				:			:		:				" //	single separator needs ',' 

	n += 1;	tPn[ n ] =	"STR:  1:	0:	4:	2:	°:			,:			1,°:			gsDataDir:		:			:			fDataDir():		212:		:				:			:		Data Path:			" //  	single  SetVariable for String display
	n += 1;	tPn[ n ] =	"BU:    0:	3:	4:	0:	°:			,:			1,°:			buDataPath:	Browse Data:	:			fDataPath():	:		:				:			:		Data Path:			" //	single button
	n += 1;	tPn[ n ] =	"STR:  1:	0:	4:	2:	°:			,:			1,°:			gsFileBase:	Filebase:		:			fFileBase():	165:		:				:			:		File Base:			" //  	single  SetVariable for String display

	n += 1;	tPn[ n ] =	"SV:     0:	3:	4:	0:	°:			,:			1,°:			gCell:		Cell:			:			fCell:			42:		%2d; 0,99,1:		~0:			:		Cell:				" //  	single  SetVariable for integer number display

	n += 1;	tPn[ n ] =	"STR:  1:	0:	4:	2:	°:			,:			1,°:			gsDataFileW:	:			:			:			212:		:				:			:		File Base:			" //  	single  SetVariable for String input or display
	n += 1;	tPn[ n ] =	"BU:    0:	3:	4:	0:	°:			,:			1,°:			buDelete:		Delete:		:			fDelete():		:		:				:			:		Delete last file:		" //	single button

	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:			,:			1,°:			dum6:		:			:			:			:		:				:			:		:				" //	single separator needs ',' 
	n += 1;	tPn[ n ] =	"BU:    1:	0:	4:	0:	°:			,:			1,°:			buDisplStim:	Stimulus +~Stimulus -::		fbuDisplayStimWnd()::	fStdColorLst_a():	:			:		Stimulus window:	" // !!!  ass name 
	n += 1;	tPn[ n ] =	"BU:    0:	1:	4:	0:	°:			,:			1,°:			DataUtils:		DataUtilities+~DataUtilities-::	fDataUtils_a():	:		fStdColorLst_a():	:			:		Acquisition Windows:	" 
	n += 1;	tPn[ n ] =	"BU:    0:	2:	4:	0:	°:			,:			1,°:			Preferences:	Preferences+~Preferences-::	fPreferDlg_a():	:		fStdColorLst_a():	:			:		Acq Preferences:	"
	n += 1;	tPn[ n ] =	"BU:    0:	3:	4:	0:	°:			,:			1,°:			gbPnMisc:		Miscellan +~Miscellan -::		fMiscellan():	:		fStdColorLst_a():	~0:			:		Miscellaneous (Acq):	" 

	n += 1;	tPn[ n ] =	"BU:    1:	0:	4:	0:	°:			,:			1,°:			buDiacWnAdd:	Add AcqWnd:	:			fDiacWndAdd():	:		:				:			:		Add window:		" 
	n += 1;	tPn[ n ] =	"BU:    0:	1:	4:	0:	°:			,:			1,°:			gbPnTst1401:	Tst Ced1401+~Tst Ced1401-::	fPnTest1401():	:		:				:			:		Test CED1401:			"
	n += 1;	tPn[ n ] =	"BU:    0:	2:	4:	0:	°:			,:			1,°:			gbPnComment:	Comment +~Comment -::		fPnComment():	:		fStdColorLst_a():	:			:		Comment:			" 
	n += 1;	tPn[ n ] =	"BU:    0:	3:	4:	0:	°:			,:			1,°:			gbNbPuHelp:	Mini Help +~Mini Help -::		fNbPuHelp():	:		fStdColorLst_a():	:			:		Mini Help(Acq):		" 

	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:			,:			1,°:			dum8:		AxoPatch gains::			:			fGainHt():	:				:			:		:						" //	single separator needs ',' 
	n += 1;	tPn[ n ] =	"SV:	   1:	0:	1:	0:	°:			,:			1,°:			svAxogain:	LstAllAD():		:			fGain():		60:		%.1lf;.5,1000,0:		~0:			:		Axopatch Gain:	" 			//  	1 dim  SetVariable( 1 row)
	// 2005-1201 only currently not used 
	// n += 1;	tPn[ n ] =	"SV:	   1:	0:	2:	0:	°:			,:			1,°:			gCCpAStep:	CC step:		:			fCCpAStep():	50: 		%4d;-3000,3000,100:	~100:		:		CC step:		" 			// 	
	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:			,:			1,°:			dum8a:		:			:			:			:		:				:			:		:						" //	single separator needs ',' 

	// BAD BAD CODE: The  Tabco index of the channels  tabcontrol  is  kTC_CHS = 3  ( the preceding empty Tabco indices are 0 and 2 ) .   Must be adjusted if this block is moved, but should compute itself automatically!
	n += 1;	tPn[ n ] =	"BU:    1:	0:	8:	0:	fLstCh_a():		,°,°,°,°,°,°:		1°1°1°1°1°1°:	buBaseLCsr:	[ bs:			:			fBaseBegCsrM_a()::		:				:			:		Base region Begin (b):"	//
	n += 1;	tPn[ n ] =	"BU:    0:	1:	8:	0:	fLstCh_a():		,°,°,°,°,°,°:		1°1°1°1°1°1°:	buBaseRCsr:	Bs ]:			:			fBaseEndCsrM_a()::		:				:			:		Base region End  (B):	"	//
	n += 1;	tPn[ n ] =	"BU:    0:	2:	8:	0:	fLstCh_a():		,°,°,°,°,°,°:		1°1°1°1°1°1°:	buPeakBCsr:	[ pk:			:			fPeakBegCsrM_a()::		:				:			:		Peak region Begin (p):"	//
	n += 1;	tPn[ n ] =	"BU:    0:	3:	8:	0:	fLstCh_a():		,°,°,°,°,°,°:		1°1°1°1°1°1°:	buPeakECsr:	Pk ]:			:			fPeakEndCsrM_a()::		:				:			:		Peak region End  (P):	"	//
	n += 1;	tPn[ n ] =	"BU:    1:	0:	8:	1:	fLstCh_a():		,°,°,°,°,°,°:		1°1°1°1°1°1°:	buSpreadC:	spread curs:	:			fSpreadCurs():	:		:				:			:		Spread cursors evenly:"	//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	2:	8:	1:	fLstCh_a():		,°,°,°,°,°,°:		1°1°1°1°1°1°:	buAutoSetC:	autoset curs:	:			fAutoSetCurs():	:		:				:			:		Automatically set cursors:"	//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	6:	8:	0:	fLstCh_a():		,°,°,°,°,°,°:		1°1°1°1°1°1°:	buCancelCsr:	ESC:			:			fCancelCsrM_a()::		:				:			:		Cursor cancel:		"	//
	n += 1;	tPn[ n ] =	"BU:    0:	7:	8:	0:	fLstCh_a():		,°,°,°,°,°,°:		1°1°1°1°1°1°:	buOKCsr:		OK:			:			fOKCsrM_a():	:		:				:			:		Cursor OK:			"	//

// 2006-0124 ??? !!! Cave  TODO  the following line limits the number of channels,  ( extended here from 6 to 8 which is sufficient to load for file 00Demo4Dacs500.txt)  but only 6 tabs fit on the panel............
	n += 1;	tPn[ n ] =	"SV:	   1:	0:	3:	0:	fLstCh_a():		,°,°,°,°,°,°,°,°:	1°1°1°1°1°1°1°1°:svReg:		:			Regions:		fReg_a():		32:		%2d;0,"+num2str(UFPE_kRG_MAX)+",1:~1::	Evaluation regions:			" 	//  	upper limit = UFPE_kRG_MAX
	n += 1;	tPn[ n ] =	"PM:	   1:	0:	3:	0:	fLstCh_a():		fLstRg_a():	:			pmBaseOp:	:			Base:		fBaseOp_a():	65:		UFPE_fBaseOpPops():~2:			:		Base:	"					// 	1-dim  popmenu (1 col)
	n += 1;	tPn[ n ] =	"PM:	   1:	0:	3:	0:	fLstCh_a():		fLstRg_a():	1,1,1,°1,1,1,°:	pmUpDn:		:			PkDir:		fPkDir_a():		52:		UFPE_fPkDirPops():	0000_3;1000_2~1::		Peak direction:				" 	// 	1-dim  popmenu (1 col)
	n += 1;	tPn[ n ] =	"SV:	   0:	1:	3:	0:	fLstCh_a():		fLstRg_a():	1°1°1°1°1°1°:	svSideP:		:			Pts1side:		fSidePts_a():	35:		%2d;0,20,1:		0000_3:		:		Additional Peak points on each side:" 	//  single  SetVariable
	n += 1;	tPn[ n ] =	"SV:	   0:	2:	3:	0:	fLstCh_a():		fLstRg_a():	1°1°1°1°1°1°:	svRserMV:	Rser/mV:		:			:			32:		%3d;1,1000,0:		~10:			:		R-series measurement Pulse voltage:"	//  	1 dim  SetVariable( 1 row)

	n += 1;	tPn[ n ] =	"PM:	   1:	0:	4:	0:	fLstCh_a():		fLstRg_a():	1,1,1,°1,1,1,°:	pmLat00:		:			L0:			fLat0B_a():	38:		UFPE_fLatCsrPops():	~1:			:		Select Latency 0  Begin:	"		// 	1-dim  popmenu (1 col)
	n += 1;	tPn[ n ] =	"PM:	   0:	1:	4:	0:	fLstCh_a():		fLstRg_a():	1,1,1,°1,1,1,°:	pmLat01:		:			 >:			fLat0E_a():	38:		UFPE_fLatCsrPops():	~1:			:		Select Latency 0 End:	" 		// 	1-dim  popmenu (1 col)
	n += 1;	tPn[ n ] =	"PM:	   0:	2:	4:	0:	fLstCh_a():		fLstRg_a():	1,1,1,°1,1,1,°:	pmLat10:		:			L1:			fLat1B_a():	38:		UFPE_fLatCsrPops():	~1:			:		Select Latency 1  Begin:	" 		// 	1-dim  popmenu (1 col)
	n += 1;	tPn[ n ] =	"PM:	   0:	3:	4:	0:	fLstCh_a():		fLstRg_a():	1,1,1,°1,1,1,°:	pmLat11:		:			 >:			fLat1E_a():	38:		UFPE_fLatCsrPops():	~1:			:		Select Latency 1 End:	" 		// 	1-dim  popmenu (1 col)
// QUOTIENTS     BAD   PopupMenu	$sControlNm, win = $sWin,	 value = ListACV1RegionOA( ch, rg )     AS does not compile  . Also   not intuitive
//	n += 1;	tPn[ n ] =	"PM:	   1:	0:	4:	0:	fLstCh_a():		fLstRg_a():	1,1,1,°1,1,1,°:	pmQuot00:	:			Q0:			fQuotEnum():	38:		fQuotPopsAc():		~1:			:		Select Quot 0 enumerator:	" 		// 	1-dim  popmenu (1 col)
//	n += 1;	tPn[ n ] =	"PM:	   0:	1:	4:	0:	fLstCh_a():		fLstRg_a():	1,1,1,°1,1,1,°:	pmQuot01:	:			  /:			fQuotDenom():	38:		fQuotPopsAc():		~1:			:		Select Quot 0 denominator:	" 		// 	1-dim  popmenu (1 col)

	// The initial visibility of  'FiFnc'  and  'FiRng'   must be the same as the initial values of the  'Fit'  checkbox
// 2006-0428
//	n += 1;	tPn[ n ] =	"CB:	   1:	0:	3:	0:	fLstCh_a():		fLstRg_a():	1,1,1,°1,1,1,°:	cbFit:		fFitRowTitles():	:			fFit_a():		:		:				fFitInSt_a():	:		Fit 0 and Fit 1:				" // !!! the # of row titles ~ # of fits
	n += 1;	tPn[ n ] =	"BU:    1:	0:	8:	0:	fLstCh_a():		fLstRg_a():	1,1,1,°1,1,1,°:	buFitBCsr:		fFitBegTitles_a()::			fFitBegCsrM_a()::		:				:			:		Fit 0 region Begin (f):			" // Special case : fCsr_a() changes the button colors which is...
	n += 1;	tPn[ n ] =	"BU:    0:	1:	8:	0:	fLstCh_a():		fLstRg_a():	1,1,1,°1,1,1,°:	buFitECsr:		fFitEndTitles_a()::			fFitEndCsrM_a()::		:				:			:		Fit 0 region End  (F):			" // ...normally done by an entry in the 'FormatEntry' column.
	n += 1;	tPn[ n ] =	"PM:	   0:	1:	3:	0:	fLstCh_a():		fLstRg_a():	1,1,1,°1,1,1,°:	pmFiFnc:		fFitRowDums_a():Fn:			fFitFnc_a():	65:		UFPE_fFitFPops():	UFPE_fFitFInit():	fFitInSt_a():Fit Function:				" // 	1-dim  popmenu (1 col)
	n += 1;	tPn[ n ] =	"PM:	   0:	2:	3:	0:	fLstCh_a():		fLstRg_a():	1,1,1,°1,1,1,°:	pmFiRng:		fFitRowDums_a():Rng:		fFitRng_a():	58:		UFPE_fFitRPops():	UFPE_fFitRInit():fFitInSt_a():Fit Range:					" // 	1-dim  popmenu (1 col)
	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	fLstCh_a():		fLstRg_a():	1,°:			dum30:		:			:			:			:		:				:			:		:						" //	single separator needs ','
	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	fLstCh_a():		,:			,:			dum40:		OA windows:	:			:			:		:				:			:		:						" //	single separator needs ',' 
	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	fLstCh_a():		,:			,:			dum50:		:			:			:			:		:				:			:		:						" //	single separator needs ',' 

	n += 1;	tPn[ n ] =	"BU:	   1:	0:	3:	0:	°:			,:			1,°:			bClearAll:		clear all:		:			fClearAnalysisWnd():	:	:				:			:		Clear all:		" // 	
	n += 1;	tPn[ n ] =	"CB:	   0:	1:	3:	0:	°:			,:			1,°:			bBlankPause:	blank pauses:	:			fBlankPause():	:		:				~1:			:		Blank Pauses:		" // 	
	n += 1;	tPn[ n ] =	"PM:	   0:	2:	3:	0:	°:			,:			1,°:			pmXAxis:		:			X:			fOLAXAxis():	64:		fXAxisPops_a():		0000_1:		:		OLA X Axis:		" // 	1-dim  popmenu (1 row)

//	n += 1;	tPn[ n ] =	"CB:	   1:	0:	2:	0:	°:			,:			1,°:			bBlankPause:	blank pauses:	:			fBlankPause():	:		:				~1:			:		Blank Pauses:		" // 	
//	n += 1;	tPn[ n ] =	"PM:	   0:	1:	2:	0:	°:			,:			1,°:			pmXAxis:		:			X Axis:		fOLAXAxis():	76:		fXAxisPops_a():		0000_1:		:		OLA X Axis:		" // 	1-dim  popmenu (1 row)


	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:			,:			1,°:			dum60:		:			:			:			:		:				:			:		:						" //	single separator needs ',' 
	n += 1;	tPn[ n ] =	"BU:    1:	0:	4:	0:	°:			,:			1,°:			buAcDisplay:	AcqDisplay +~AcqDisplay -::	fAcqDisplay():	:		fStdColorLst_a():	:			:		Acquisition Display:			" 
// 2009-12-12 old-style
//	n += 1;	tPn[ n ] =	"BU:    0:	3:	4:	0:	°:			,:			1,°:			DisplayStim:	Stimulus +~Stimulus -:	:		fDisplayStim_a()::		fStdColorLst_a():	:			:		Stimulus panel:		" 
	n += 1;	tPn[ n ] =	"BU:    1:	0:	6:	0:	°:			,:			1,°:			buLoadDisp:	Ld Disp:		:			fLoadDispCfg():	:		:				:			:		load user display configuration:" 
	n += 1;	tPn[ n ] =	"BU:    0:	1:	6:	0:	°:			,:			1,°:			buLoadDisp2:	LdDis2:		:			fLoadDispCfg2()::		:				:			:		load user display configuration 2:" 
	n += 1;	tPn[ n ] =	"BU:    0:	2:	6:	0:	°:			,:			1,°:			buLoadDisp3:	LdDis3:		:			fLoadDispCfg3()::		:				:			:		load user display configuration 2:" 
	n += 1;	tPn[ n ] =	"BU:    0:	3:	6:	0:	°:			,:			1,°:			buSaveDisp:	Sv Disp:		:			fSaveDspCfg():	:		:				:			:		save acq display configuration:	" 
	n += 1;	tPn[ n ] =	"BU:    0:	4:	6:	0:	°:			,:			1,°:			buSaveDisp2:	SvDis2:		:			fSaveDspCfg2()::		:				:			:		save acq display configuration 2:	" 
	n += 1;	tPn[ n ] =	"BU:    0:	5:	6:	0:	°:			,:			1,°:			buSaveDisp3:	SvDis3:		:			fSaveDspCfg3()::		:				:			:		save acq display configuration 3:	" 
	n += 1;	tPn[ n ] =	"CB:	   1:	0:	1:	0:	°:			,:			1,°:			HighResol:	High Resolution during acquis::	:			:		:				~1:			:		High Resolution during acquisition:" // KEEP 1 as initial value ! 	
// 2006-05-31
//	n += 1;	tPn[ n ] =	"CB:	   1:	0:	1:	0:	°:			,:			1,°:			AcqCtrlbar:	Trace / Window Controlbar::	fAcqCtrlbar():	:		:				~0:			:		Trace / Window Controlbar:	" // 	
	n += 1;	tPn[ n ] =	"BU:    1:	0:	4:	1:	°:			,:			1,°:			PrepPrint:		Prepare printing acq wnd:	:	fPrepPrint():	:		:				:			:		Prepare printing acq wnd:		" //	
	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:			,:			1,°:			dum70:		:			:			:			:		:				:			:		:						" //	single separator needs ',' 
	n += 1;	tPn[ n ] =	"BU:    1:	0:	2:	0:	°:			,:			1,°:			buResSelOA:	OA selection +~OA selection -::	fOAResSelect():	:		fStdColorLst_a():	:			:		OLA draw selection:			" //	single checkbox
	n += 1;	tPn[ n ] =	"BU:    0:	2:	3:	0:	°:			,:			1,°:			buClrRSelTb:	clear OA sel:	:			fOAClearResSel()::		:				:			:		Clear OLA draw selection:		" //	single button
// 2005-12-19b
//	n += 1;	tPn[ n ] =	"PM:	   1:	1:	2:	0:	°:			,:			,:			pmPrRes:		:			Print:			fPrintReslts():	72:		UFPE_fPrintResltsPops()::			:		Print results:	"		// 	1-dim  popmenu (1 row)
	n += 1;	tPn[ n ] =	"PM:	   1:	1:	2:	0:	°:			,:			,:			pmPrRes:		:			Print:			:			72:		UFPE_fPrintResltsPops()::			:		Print results:	"		// 	1-dim  popmenu (1 row)





	n += 1;	tPn[ n ] =	"BU:    1:	0:	3:	1:	°:			,:			1,°:			cbOLACsr:		Online Analysis cursor values +~Online Analysis cursor values -::fOLACursorsDsp()::fStdColorLst_a():~1::		Display online analysis cursors:	" // ~1 : must be initially on so that variables are constructed
     if ( OLACursorsDisplay() )
//	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:			,:			1,°:			dum80:		Online Analysis cursor values::	:			:		:				:			:		:						" //	single separator needs ',' 
	n += 1;	tPn[ n ] =	"SV:	   1:	0:	2:	0:	°:			,:			1,°:			svCursorX:		Cursor X:		:			:			58:		%.3lf;0,0,0:		~0:			:		Online analysis cursors:		" // 0,0,0: in conjunction with UFCom_kCo_NOEDIT_SV makes the control read-only, could alternatively use ValDisplay (but requiring 'Execute')  
	n += 1;	tPn[ n ] =	"VD:	   0:	1:	2:	0:	°:			,:			1,°:			vdCursorY:	Cursor Y:		:			:			58:		%.2lf:				~0:			:		Online analysis cursors:		" // ValDisplay sample (without colored bar), could alternatively use SetVariable( UFCom_kCo_NOEDIT_SV )
	n += 1;	tPn[ n ] =	"SV:	   1:	0:	2:	0:	°:			,:			1,°:			svWaveMax:	Wv max:		:			:			58:		%.4lf;0,0,0:		~0:			:		Online analysis wave maximum:	" // 0,0,0: in conjunction with UFCom_kCo_NOEDIT_SV makes the control read-only, could alternatively use ValDisplay (but requiring 'Execute')  
	n += 1;	tPn[ n ] =	"SV:	   1:	0:	2:	0:	°:			,:			1,°:			svWaveMin:	Wv min:		:			:			58:		%.4lf;0,0,0:		~0:			:		Online analysis wave minimum:	" // 0,0,0: in conjunction with UFCom_kCo_NOEDIT_SV makes the control read-only, could alternatively use ValDisplay (but requiring 'Execute')  
	n += 1;	tPn[ n ] =	"SV:	   0:	1:	2:	0:	°:			,:			1,°:			svWaveY:		Wave Y:		:			:			58:		%.4lf;0,0,0:		~0:			:		Online analysis wave Y value:	" // 0,0,0: in conjunction with UFCom_kCo_NOEDIT_SV makes the control read-only, could alternatively use ValDisplay (but requiring 'Execute')  
	n += 1;	tPn[ n ] =	"SV:	   1:	0:	2:	0:	°:			,:			1,°:			svPointX:		Point X:		:			:			58:		%.2lf;0,0,0:		~0:			:		Online analysis point X:		" // 0,0,0: in conjunction with UFCom_kCo_NOEDIT_SV makes the control read-only, could alternatively use ValDisplay (but requiring 'Execute')  
	n += 1;	tPn[ n ] =	"SV:	   0:	1:	2:	0:	°:			,:			1,°:			svPointY:		Point Y:		:			:			58:		%.2lf;0,0,0:		~0:			:		Online analysis point Y:		" // 0,0,0: in conjunction with UFCom_kCo_NOEDIT_SV makes the control read-only, could alternatively use ValDisplay (but requiring 'Execute')  
     endif

   	n += 1;	tPn[ n ] =	"BU:    1:	0:	3:	1:	°:			,:			1,°:			cbAcqStat:	Acquisition status +~Acquisition status -::	fAcqStatusDsp()::fStdColorLst_a():	~1:			:		Display acquisition status:		" // ~1 : must be initially on so that variables are constructed
  if ( AcqStatusDisplay() )
//	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:			,:			1,°:			dum90:		Acquisition status::			:			:		:				:			:		:						" //	single separator needs ',' 
	n += 1;	tPn[ n ] =	"VD:    1:	0:	2:	0:	°:			,:			1,°:			vdPredict:		Pred:			:			:			:		fVdPrediction():		:			:		Prediction of acquisition success:" //  ValDisplay
	n += 1;	tPn[ n ] =	"SV:	   1:	0:	4:	0:	°:			,:			1,°:			svPrevBlk:		Blk:			:			:			32:		%d;-1,10000,0:		~-1:			:		Current block:				" //  	1 dim  SetVariable( 1 row)
	n += 1;	tPn[ n ] =	"SV:	   0:	1:	4:	0:	°:			,:			1,°:			svBlockCnt:	/:			:			:			32:		%d;-1,10000,0:		~1:			:		Total number of blocks:		" //  	1 dim  SetVariable( 1 row)
	n += 1;	tPn[ n ] =	"SV:	   0:	2:	4:	0:	°:			,:			1,°:			svSwpsWrt:	Swp:			:			:			32:		%d;-1,10000,0:		~0:			:		Sweeps written:				" //  	1 dim  SetVariable( 1 row)
	n += 1;	tPn[ n ] =	"SV:	   0:	3:	4:	0:	°:			,:			1,°:			svSwpsTot:	/:			:			:			32:		%d;-1,10000,0:		~1:			:		Total number of sweeps:		" //  	1 dim  SetVariable( 1 row)
// too wide (245 as compared to 215 above )
//	n += 1;	tPn[ n ] =	"SV:	   1:	0:	10:	2:	°:			,:			1,°:			svPrevBlk:		Blk:			:			:			32:		%d;-1,10000,0:		~-1:			:		Current block:				" //  	1 dim  SetVariable( 1 row)
//	n += 1;	tPn[ n ] =	"SV:	   0:	3:	10:	1:	°:			,:			1,°:			svBlockCnt:	/:			:			:			32:		%d;-1,10000,0:		~1:			:		Total number of blocks:		" //  	1 dim  SetVariable( 1 row)
//	n += 1;	tPn[ n ] =	"SV:	   0:	5:	10:	2:	°:			,:			1,°:			svSwpsWrt:	Swp:			:			:			32:		%d;-1,10000,0:		~0:			:		Sweeps written:				" //  	1 dim  SetVariable( 1 row)
//	n += 1;	tPn[ n ] =	"SV:	   0:	8:	10:	1:	°:			,:			1,°:			svSwpsTot:	/:			:			:			32:		%d;-1,10000,0:		~1:			:		Total number of sweeps:		" //  	1 dim  SetVariable( 1 row)
// too wide (242 as compared to 215 above )
//	n += 1;	tPn[ n ] =	"SV:	   1:	0:	14:	3:	°:			,:			1,°:			svPrevBlk:		Blk:			:			:			32:		%d;-1,10000,0:		~-1:			:		Current block:				" //  	1 dim  SetVariable( 1 row)
//	n += 1;	tPn[ n ] =	"SV:	   0:	4:	14:	2:	°:			,:			1,°:			svBlockCnt:	/:			:			:			32:		%d;-1,10000,0:		~1:			:		Total number of blocks:		" //  	1 dim  SetVariable( 1 row)
//	n += 1;	tPn[ n ] =	"SV:	   0:	7:	14:	3:	°:			,:			1,°:			svSwpsWrt:	Swp:			:			:			32:		%d;-1,10000,0:		~0:			:		Sweeps written:				" //  	1 dim  SetVariable( 1 row)
//	n += 1;	tPn[ n ] =	"SV:	   0:	11:	14:	2:	°:			,:			1,°:			svSwpsTot:	/:			:			:			32:		%d;-1,10000,0:		~1:			:		Total number of sweeps:		" //  	1 dim  SetVariable( 1 row)

	n += 1;	tPn[ n ] =	"SV:	   1:	0:	2:	0:	°:			,:			1,°:			svTmElaps:	Time:		:			:			40:		%d;-1,10000,0:		~0:			:		Elapsed time:				" //  	1 dim  SetVariable( 1 row)
	n += 1;	tPn[ n ] =	"SV:	   0:	1:	2:	0:	°:			,:			1,°:			svTotSecs:	    /:			:			:			40:		%d;-1,10000,0:		~1:			:		Total time of protocol:			" //  	1 dim  SetVariable( 1 row)
     endif

#ifdef dDEBUG	
	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:			,:			,:			dum98:		:			:			:			:		:				:			:							"
 //  	n += 1;	tPn[ n ] =	"BU:    1:	0:	3:	0:	°:			,:			1,°:			buDbgPrint:	Debug Print +~Debug Print -::	fDbgPrint():	:		fStdColorLst_a():	~1:			:		Debug Printing:			" // ~1 : must be initially on so that variables are constructed
   	n += 1;	tPn[ n ] =	"BU:    1:	0:	3:	0:	°:			,:			1,°:			buDbgApp:	Debug "+sFo+" +~Debug "+sFo+" -::	fDbgAppAcq()::		fStdColorLst_a():	~1:			:		Debug Printing Application:	" // ~1 : must be initially on so that variables are constructed
   	n += 1;	tPn[ n ] =	"BU:    0:	1:	3:	0:	°:			,:			1,°:			buDbgCom:	Debug Com +~Debug Com -::	fDbgCom():	:		fStdColorLst_a():	~1:			:		Debug Printing Com:		" // ~1 : must be initially on so that variables are constructed
   	n += 1;	tPn[ n ] =	"BU:    0:	2:	3:	0:	°:			,:			1,°:			buDbgFpe:	Debug Fpe +~Debug Fpe -::	fDbgFpe():		:		fStdColorLst_a():	~1:			:		Debug Printing Fpe:		" // ~1 : must be initially on so that variables are constructed
   	n += 1;	tPn[ n ] =	"BU:    1:	0:	3:	1:	°:			,:			1,°:			buPnTest:		Test +~Test -:	:			fPnTest4():	:		fStdColorLst_a():	~1:			:		Testing:				" // ~1 : must be initially on so that variables are constructed
   	n += 1;	tPn[ n ] =	"BU:    1:	0:	3:	1:	°:			,:			1,°:			buPnTstMC7:	Test MC700+~Test MC700 -::	fPnTestMC700()::		fStdColorLst_a():	~1:			:		Test MC700:			" // ~1 : must be initially on so that variables are constructed
#endif

	if ( n >= nItems )
		UFCom_DeveloperError( "Wave in panel " + sWin + " needs more (at least " + num2str( n+1 )  + " ) elements. " )
	endif

	redimension  /N = ( n+1)	tPn
End

//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function		fDbgAppAcq( s ) 
	struct	WMButtonAction	&s
	nvar		bState	= $ReplaceString( "_", s.ctrlname, ":" )	// the underlying button variable name is derived from the control name
	string  	sFo		= StringFromList( 2,  s.ctrlname, "_" )		// e.g.  'acq' ,  'eva'  or 'best'
	variable	xPercent	= 70
	UFCom_DisplayHideDebugPanel( sFo, xPercent, bState ) 
End

//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function		fNbPuHelp( s ) 
	struct	WMButtonAction	&s
	string  	sHelpWnd	= "FPulsHelp"  
	string  	sHelpDir	= FunctionPath( "" )							// Path to file containing this function.
	string  	sHelpFile	= "FPulsHelp.txt"
	nvar		state		= $ReplaceString( "_", s.ctrlname, ":" )			// the underlying button variable name is derived from the control name
	UFCom_GenericMiniHelp_( state, sHelpWnd, sHelpDir, sHelpFile )
End


Function	/S	fStdColorLst_a()
//	return  "56000,56000,56000~42000,42000,42000"
	return  "56000,56000,58000~40000,40000,40000"
End


Function		fOLACursorsDsp( s ) 
	struct	WMButtonAction	&s
	// nvar	state		= $ReplaceString( "_", s.ctrlname, ":" )	// the underlying button variable name is derived from the control name
	// printf "\t\t\t\t%s\tvalue:%2d   \t \r",  s.ctrlname, state	
	PanelPulse()										// rebuild THIS main FPuls  showing or hiding the  OLA cursors section
End
Function		OLACursorsDisplay()
	nvar	/Z	bOLEval	= root:uf:acq:pul:cbOLACsr0000
	if ( ! nvar_exists( bOLEval ) )
		return	1									//Must initially return 1 (=display panel section) so that the panel variables are constructed. It is up to the user to hide this panel section later.
	endif
	return	bOLEval
End


Function		fAcqStatusDsp( s ) 
	struct	WMButtonAction	&s
	// nvar	state		= $ReplaceString( "_", s.ctrlname, ":" )	// the underlying button variable name is derived from the control name
	// printf "\t\t\t\t%s\tvalue:%2d   \t \r",  s.ctrlname, state	
	PanelPulse()						// rebuild THIS main FPuls  showing or hiding the  Acquisition Status section
End
Function		AcqStatusDisplay()
	nvar	/Z	bAcqStat	= root:uf:acq:pul:cbAcqStat0000
	if ( ! nvar_exists( bAcqStat ) )
		return	1									//Must initially return 1 (=display panel section) so that the panel variables are constructed. It is up to the user to hide this panel section later.
	endif
	return	bAcqStat
End


//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

 Function	/S	LstAllAD( sBaseNm, sF, sWin )
// Makes a  list containing the names of all  AD channels  including those controlled by a telegraph channel.  
// Reads the gain of each channel from 'lllstIO' (lllstIO has been set with the gain as found in the script) and update the panel gain (=svAxogain00x0) with the lllstIO gain.
	string  	sBaseNm, sF		// e.g. 'root:uf:acq:'
	string  	sWin 
	string 	lstADNames	= "", 	sADCNm	= "", sBase = "Adc"
	variable	cio, nCntAD, nio = kSC_ADC

	svar	/Z	lllstIO	= $"root:uf:" + ksACQ + ":lllstIO"  						
	if ( svar_exists( lllstIO ) )
		nCntAD	=  UFPE_ioUse_ns( lllstIO, nio )
		sBase	= "Adc"
		for ( cio = 0; cio < nCntAD; cio += 1 )
			if ( UFPE_ioTGChan(		lllstIO, nio, cio )  != UFCom_kNOTFOUND )								// this is a true Adc channel having a corresponding telegraph channel 
				sADCNm	=  sBase+ UFPE_ioItem( lllstIO, nio, cio, kSC_IO_CHAN ) + " (Tg" 	+ num2str( UFPE_ioTGChan( 	lllstIO, nio, cio ) ) + ")      "
			elseif ( UFPE_ioTGMCChan( lllstIO, nio, cio )  != UFCom_kNOTFOUND )								// this is a true Adc channel having a corresponding MULTICLAMP telegraph channel
				sADCNm	=  sBase+ UFPE_ioItem( lllstIO, nio, cio, kSC_IO_CHAN ) + " (MCTg"	+ num2str( UFPE_ioTGMCChan(	lllstIO, nio, cio ) ) + ")"
			else																	// this is a true Adc channel  without  a corresponding telegraph channel
				sADCNm	=  sBase+ UFPE_ioItem( lllstIO, nio, cio, kSC_IO_CHAN ) + "                             " 	// magical number of spaces makes a better vertical alignment of the Setvariable titles  in the panal  //  " (fix)   "
			endif
			lstADNames	+=  "Gain   " + sADCNm + UFCom_ksSEP_STD
			// printf "\t\t\t\tTelegraphGain() LstAllAD()   cio:%2d/%2d   \t%s\tList: '%s' \r", c, nCntAD, UFCom_pd(sADCNm,12), lstADNames
		endfor
	else
		// printf  "\t\t\tTelegraphGain( LstAllAD() \tlstADNames: '%s'   as   lllstIO is not yet defined  \r", lstADNames
	endif

	// printf  "\t\t\tTelegraphGain( LstAllAD( \t%s\t%s, %s ) \t\tlstADNames: '%s'   \r", UFCom_pd(sBaseNm,13), sF, sWin, sACQ ), lstADNames
	return	lstADNames
End

Function		EnableDisableAxogains( sFo )
// Axogain Setvariable controls: disable the control (=no Edit, display only) if it is a telegraph controlled channel, enable (=allow changing the value) if it is a normal not-telegraph-controlled channel
	string  	sFo
	string  	sCNm	= ""
	variable	cio, nCntAD, nio	= kSC_ADC, Gain

	nio	= kSC_ADC
	svar	/Z	lllstIO	= $"root:uf:" + ksACQ + ":lllstIO"  						
//	svar	/Z	lllstIO	= $"root:uf:" + ksACQ + ":lllstIOTG"  						
	if ( svar_exists( lllstIO ) )
		nCntAD	=  UFPE_ioUse_ns( lllstIO, nio )
		for ( cio = 0; cio < nCntAD; cio += 1 )
			sCNm	= AxoGainControlName( cio )
			if ( UFPE_ioTGChan( lllstIO, nio, cio )  != UFCom_kNOTFOUND )						// this is a true Adc channel having a corresponding telegraph channel 
				UFCom_EnableSetVar( "pul", sCNm, UFCom_kCo_NOEDIT_SV )
			elseif ( UFPE_ioTGMCChan( lllstIO, nio, cio )  != UFCom_kNOTFOUND )			 		// this is a true Adc channel having a corresponding MULTICLAMP telegraph channel
				UFCom_EnableSetVar( "pul", sCNm, UFCom_kCo_NOEDIT_SV )
			else																	// this is a true Adc channel  without  a corresponding telegraph channel
				UFCom_EnableSetVar( "pul", sCNm, UFCom_kCo_ENABLE_SV )
			endif
			Gain	= UFPE_iov_ns( lllstIO, nio, cio, kSC_IO_GAIN )
			SetAxoGainInPanel( cio, Gain ) 
			// printf "\t\t\t\tTelegraphGain() EnableDisableAxogains()   cio:%2d/%2d   \t%s\tGain:\t%8.2g \r", cio, nCntAD, sCNm, Gain
		endfor
	endif

End


static Function	/S	AxoGainControlName( row ) 
	variable	row
	return	"root_uf_acq_pul_svAxogain00" + num2str( row ) + "0"
End
 Function		SetAxoGainInPanel( row, Gain ) 
	variable	row, Gain
	nvar		 Gn	= $"root:uf:acq:pul:svAxogain00" + num2str( row ) + "0"
	Gn	= Gain
End



// 2005-1201 only currently not used 
// Function		fCCpAStep( s )
//	struct	WMSetvariableAction	 &s
//	 printf "\t\t'%s'  num:%g \r", s.ctrlname, s.dval
//	string  	sFolder	= ksACQ
//	wave  	wG		= $"root:uf:" + sFolder + ":" + UFPE_ksKPwg + ":wG" 					// This  'wG'  	is valid in FPuls ( Acquisition )
//	wave  /T	wIO		= $"root:uf:" + sFolder + ":ar:wIO"  					// This  'wIO'  	is valid in FPuls ( Acquisition )
//	wave  /T	wVal		= $"root:uf:" + sFolder + ":ar:wVal"  					// This  'wVal'  	is valid in FPuls ( Acquisition )
//	wave 	wFix		= $"root:uf:" + sFolder + ":ar:wFix" 		 			// This  'wFix'	is valid in FPuls ( Acquisition )
//	wave 	wEinCB	= $"root:uf:" + sFolder + ":ar:wEinCB" 		 			// This  'wEinCB'is valid in FPuls ( Acquisition )
//	wave 	wELine	= $"root:uf:" + sFolder + ":ar:wELine" 					// This  'wELine' is valid in FPulse ( Acquisition )
//	wave 	wE		= $"root:uf:" + sFolder + ":ar:wE"  					// This  'wE'  	is valid in FPuls ( Acquisition )
//	wave 	wBFS	= $"root:uf:" + sFolder + ":ar:wBFS" 					// This  'wBFS'  	is valid in FPuls ( Acquisition )
//	string		sSegList	= UFPE_ChangeAllOccurences( wG, wFix, wEinCB, wE, wBFS, "VarSegm", "Amp", s.dval/10 )  //? todo   scaling...
//	UFPE_OutElemsSomeToWave( sFolder, wG, wIO, wVal, wELine, wE, wBFS, sSegList )
//	UFPE_DisplayStimulus( sFolder, UFPE_kNOINIT )
// End

//=================================================================================================================================================


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


  
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//
//Function		SwitchTriggerMode( sSubFoC, sSubFoW )
//	string  	sSubFoC, sSubFoW
//	string  	sFo			= ksACQ
//	variable	bTrigMode		= TrigMode()
//	nvar		gbRunning	= $"root:uf:acq:" + UFPE_ksKEEP + ":gbRunning"
//	nvar		gbAcquiring	= $"root:uf:acq:" + sSubFoC + ":gbAcquiring"
//	string		sMode		= SelectString( bTrigMode, 	 "  to normal SW " , "  to HW E3E4  " )
//	string		sAcq			= SelectString( gbAcquiring, " during pause" , " during acquisition" )
//
// 	 printf "\t\tSwitchTriggerMode()\tbTrigMode : %.0lf     running: %.0lf    acquiring : %.0lf   \r", bTrigMode, gbRunning, gbAcquiring
// 	StartStopFinishButtonTitles( sFo, sSubFoC )							// As the user has switched a basic mode  the button titles are updated 
// 	FinishFiles()												// As the user has switched a basic mode  a new file is started
//
// 	variable	bApplyScript	= UFCom_TRUE
//// 2009-12-12
////	StopADDA( "\tFINISHING ACQUISITION  by  switching trigger mode" + sMode + sAcq , bApplyScript, sSubFoC, sSubFoW )	//   invoke   ApplyScript() 
//	StopADDA_ns( "\tFINISHING ACQUISITION  by  switching trigger mode" + sMode + sAcq , bApplyScript )	//   invoke   ApplyScript() 
//End
//

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


// demo

//Function MySetMarkerValues(w)
//        WAVE w          // input data wave
//        string tt,tout= NameOfWave(w)+"_tm"
//        Variable np= numpnts(w),i
//        Make/O/T/N=(np) $tout
//        WAVE/T wout= $tout
//        for(i=0;i<np;i+=1)
//                sprintf tt,"%.3g",w[i]
//                wout[i]= tt
//        endfor
//End

//make/n=10/O jack=sin(x/8);display jack; MySetMarkerValues(jack) ; ModifyGraph mode=3,textMarker(jack)={jack_tm,"default",0,0,5,0.00,0.00}
