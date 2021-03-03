
// UF_AcqScript.ipf 
// 
// Routines for loading and processing scripts used only by FPulse  
//
 
#pragma rtGlobals=1						// Use modern global access method.

static constant	kb_AUTOWRITE_CONVERTED_FILE = 1	// 1 for user release version

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//   GENERAL SCRIPT FILE LOADING

//=======================================================================================================================================
//  CHECKING  THE SCRIPT  VERSION  

static strconstant	klstFPULSEVERSIONS	=  "Pulse;FPULS4"
 constant			kPULSE_OLD	= 0,   kPULS4_NEW = 1

Function		WhichScriptVersion( sFilepath, lstVersionKeyword )
// Returns index in 'lstVersionKeyword'  or UFCom_kNOTFOUND if none of the keywords supplied by  'lstVersionKeyword'  could be found in 'sFilepath'
	string  	sFilepath, lstVersionKeyword						// 'FPULSE'  for old style script 2002-2007,  'FPULS4' for new style script 2008++
	variable	k, nKeywords	= ItemsInList( lstVersionKeyword )
	for ( k = 0; k < nKeywords; k += 1 )
		string  	sVersion	= StringFromList( k, lstVersionKeyword )
		if ( IsScriptVersion( sFilepath, sVersion ) )
			return	k
		endif
	endfor
	return	UFCom_kNOTFOUND
End

Function		IsScriptVersion( sFilepath, sVersionKeyword )
// Returns truth if  'sVersionKeyword'  (e.g. 'FPuls4' ) has been found in the file
	string  	sFilepath, sVersionKeyword						// 'FPULSE'  for old style script 2002-2007,  'FPULS4' for new style script 2008++
	string  	sFileNm	= UFCom_StripPathAndExtension( sFilepath )
	variable	code		= UFCom_FALSE
	//Grep   /E= 	sVersionKeyword /LIST="~" /Q  sFilepath			// case-sensitive 	!!! possible problem: the separator '~' must not occur in any line (not even in a comment) 
	Grep	/E= "(?i)"+	sVersionKeyword /LIST="~" /Q  sFilepath			// case-insensitive	!!! possible problem: the separator '~' must not occur in any line (not even in a comment) 
	string		lstGreps	= S_Value
	variable	g, nGreps	= ItemsInList( lstGreps,"~" )			// !!! possible problem: the separator ';' must not occur in any line (not even in a comment) 
	for ( g = 0; g < nGreps; g += 1 )
		// the version keyword (e.g. 'FPULS4' )  is case-insensitive,  can be anywhere in file but must be the sole entry in its line (leading and trailing whitespaces are allowed)
		if ( cmpstr( UFCom_RemoveOuterWhiteSpace( StringFromList( g, lstGreps, "~" ) ), sVersionKeyword ) == 0 )	// case-insensitive	
			code	= UFCom_TRUE
			break
		endif
	endfor
	// printf "\t\tIsScriptVersion(  '%s', \t'%s'\t  )  finds  nGreps:%2d  and returns %d  \tlstGreps: '%s' \r", sFilepath, sVersionKeyword,  nGreps, code, lstGreps
	return	code
End


//=======================================================================================================================================

strconstant		ksSCRIPT_NBNM 	= "Script"			// change with care as name is used literally in FPulsePrefs FPPrefs ??? 080817 ???

static strconstant	ksAFTERACQ_WNM	= "AfterAcq"	// 


static Function	InitAllLoadScript( sFo )    
	string  	sFo
// Cave:	Some waves MUST be killed when rereading a script/stimfile  e.g. traces in 'online analysis options', 'Acquisition window options'
// 		Some waves MUST NOT be killed when rereading a stimfile (no times changed in stimfile)   e.g. 'wAnRegion'  for  user analysis regions, colors
// 		Some waves MUST SOMETIMES be killed when rereading a stimfile when times have been changed in stimfile:  e.g. 'wAnRegion'  for  user analysis regions
//		We kill selected waves  by  killing  waves  located  special  data folders. Another approach: pass wave names to be killed  in a list.

	// printf "\t\tInitAllLoadScript 0 sFo:%s   entry  data folder  '%s' \r", sFo, GetDataFolder( 1 )
	//  KILLING GRAPHS (or at least killing all traces in a graph) is required by IGOR before we can kill a wave contained in a graph
	KillTracesInMatchingGraphs( UFPE_ksW_WNM + "*" )		// Any window (not only Acq windows) will be erased when a script is loaded or applied if its name starts with 'W'

// 2009-12-12
//	UFCom_EraseTracesInGraph( UFPE_StimWndNm( sFo ) )		//  we do NOT kill the window (because we want to keep a user-adjusted size and position), but we must kill all traces to avoid an error in 'KillWaves' below 
	UFCom_EraseTracesInGraph( UFPE_StimWndNm_ns( sFo ) )		//  we do NOT kill the window (because we want to keep a user-adjusted size and position), but we must kill all traces to avoid an error in 'KillWaves' below 

// todo UFCom_KillGraphs( ksAFTERACQ_WNM  ) without sorting
	UFCom_KillGraphs( ksAFTERACQ_WNM + "*", UFPE_ksW_WNM )	// the windows built by 'Display raw data (after acq)'

	// The following line removes all graphs which are named by IGOR (default='Graph0', 'Graph1'...) and not renamed by FPulse.
	// Actually there should be no such default-named graphs except when the user removes traces from graphs. 
	UFCom_KillGraphs( "Graph*", UFPE_ksW_WNM )

End


static Function		KillTracesInMatchingGraphs( sMatch )
	string 		sMatch
	string 		sDeleteList	= WinList( sMatch,  ";" , "WIN:" + num2str( UFCom_WT_GRAPH ) )		// 1 is graph
	variable	n
	// kill all matching windows
	for ( n =0; n < ItemsInList( sDeleteList ); n += 1 )
		string  	sWNm	= StringFromList( n, sDeleteList ) 
		RemoveTextBoxUnits( sWNm ) 	// Must remove TextboxUnits BEFORE the traces/axis as they are linked to the axis. If 'Units' had not to be drawn separately (as perhaps only in Igor4?)  the clearing would occur automatically together with the traces
		UFCom_EraseTracesInGraph( sWNm )
	endfor
End


static  Function		RemoveTextBoxUnits( sWNm )
// remove all  yUnits textboxes from the given  acq window (they must have the same name as the corresponding axis)
	string		sWNm
	variable	n
	//string 	sTBList	=  AnnotationList( sWNm )		// Version1: removes ALL annotations : axis unit   and also   PreparePrinting textbox (removing the latter is usually undesired)
	string 	sTBList	=  AxisList( sWNm )			// Version2: removes  only  axis unit annotations, but only if they cohere to the standard 'Axis unit annotation name = Axis name'
	for ( n = 0; n < ItemsInList( sTBList ); n += 1 )
		string		sTBNm	= StringFromList( n, sTBList )
		TextBox	/W=$sWNm   /K  /N=$sTBNm
		// printf "\t\t\t\tRemoveTextBoxUnits( %s )  n:%2d/%2d   \tTBName:'%s' \t'%s'  \r", sWNm, n,  ItemsInList( sTBList ), sTBNm, sTBList
	endfor
End



// works for both old- and new-style

Function 	/S	LoadScriptFileDialog( sPath, sSymPath )
	string		sPath, sSymPath
 	string		sFilePath		= UFCom_GetFileNameFromDialog( sSymPath, sPath )				// will return an empty string  if user clicked Cancel
	 // printf "\t\tLoadScriptFileDialog(  '%s'  ,  '%s'  )  returns  %s\r", UFCom_pd(sSymPath,29), UFCom_pd(sPath,29), UFCom_pd(sFilePath,30)
	return	sFilePath
End


Function 		LoadProcessScript( sFo, sFilePath )
// Loads the script file given by 'sPath'.  If empty string then a  FileOpenDialog  is presented.  Enables/disables controls depending  on whether a valid script has been loaded.
// Returns  empty string if user clicked  Cancel .  Even if script file was not valid  the script name is returned so that  the user can open and edit the script 
// Pass back  'rCode'  to indicate success or failure   and  return  file name which may be empty
// In case of error  pass back an error code rather than  an empty path for  'ScriptPath'  so that  the user can open and edit the script 
	string		sFo, sFilePath
	variable	code	= 0

 	string		sFileNm		=  UFCom_FilenameOnly( sFilePath )	
	string  	sSubFoIni		=  "Scrip"
 	string  	sIniBasePath	= ScriptPath( sFo )							// derive  IniPath  from Script path   as  sSubFoIni =  'Scrip'
	string   	sRawScript	= "",  sFilePath3 = "",  sFilePath4 = "",  sTxt = ""

	UFCom_EnableSetVar(  "pul", 	"root_uf_acq_pul_gnProts0000",	UFCom_kCo_NOEDIT_SV)// We cannot change the number of protocols as this would trigger 'ApplyScript()'
	UFCom_EnableButton(  "pul", 	"root_uf_acq_pul_ApplyScript0000",	UFCom_kCo_DISABLE )	// 'Apply'  	will not work
	UFCom_EnableButton(  "pul", 	"root_uf_acq_pul_SaveScript0000", 	UFCom_kCo_DISABLE )	// 'Save'  	will not work
	UFCom_EnableButton(  "pul", 	"root_uf_acq_pul_SaveAsScrpt0000",UFCom_kCo_DISABLE )	// 'SaveAs'  will not work
	UFCom_EnableButton(  "pul", 	"root_uf_acq_pul_StartAcq0000", 	UFCom_kCo_DISABLE )	// Do not  allow to go into acquisition  when a script is just being loaded
	UFCom_EnableButton(  "pul", 	"root_uf_acq_pul_StopFinish0000", 	UFCom_kCo_DISABLE )	// Do not allow to stop an acquisition at cold startup before before a script has been loaded
	UFCom_EnableButton(  "pul",	"root_uf_acq_pul_DisplayStim0000",	UFCom_kCo_DISABLE )	// we cannot  display a stimulus before wE and wFixSwp..  has been set by reading a script
// 2008-07-11 here required???
//	UFCom_EnableButton( "pul", 	"root_uf_acq_pul_buDisplStim0000",	UFCom_kCo_DISABLE )	// ..display a stimulus before a script has been read
//	UFCom_EnableButton( "pul", 	"root_uf_acq_pul_buDiacWnAdd0000",UFCom_kCo_DISABLE )	// ..add an acq window to display an acquired trace before a script has been read


// 2008-02-28
//Execute  "SetIgorOption DebugTimer,Start"

MarkPerfTestTime 100	// LoadScript: begin
MarkPerfTestTime 200	// InterpretScript: begin
	// todo Gain Panel????? here

	// printf "\t\tLoadScript 0 sFo:%s    entry data folder  '%s' \r", sFo, GetDataFolder( 1 )
	
	if ( strlen( sFilePath ) )

		UFCom_ResetStartTimer_( sFo, "OverAll" )

		variable	nNewStyle	= WhichScriptVersion( sFilePath, klstFPULSEVERSIONS )

		if ( nNewStyle == UFCom_kNOTFOUND )

			printf "Error: Script version unknown [should be one of '%s' ] .  Exiting..\r", klstFPULSEVERSIONS
			UFCom_Alert( UFCom_kERR_FATAL,  "Script version unknown [should be one of '" + klstFPULSEVERSIONS + "' ] .\rExiting.." )
			return	UFCom_kERROR				// = -1 = UFCom_kNOTFOUND

//		// 2009-12-16 convert old-style to new-style
//		elseif ( nNewStyle == kPULSE_OLD )				// old-style FPulse V3xx
//
//			sFilePath3		= UFCom_StripExtensionAndDot( sFilePath ) + ".tx3" 
//			if ( cmpstr( sFilePath, sFilePath3 ) )
//				CopyFile	/O sFilePath   sFilePath3						// is done only once (as sFilePath3 should never exist). After this pass the txt file is NewStyle. This assumption will fail  if the user has interfered by manually renaming
//			else
//				sFilePath	= UFCom_StripExtensionAndDot( sFilePath ) + ".txt"	// for the mis-behaved case when  'sFilePath'  has extension '.tx3'  but is new-style FPuls4 (may happen if the user has interfered by manually renaming)
//				CopyFile	/O  sFilePath3   sFilePath			
//			endif
//			
//			sRawScript	= ReadScript( sFo, sFilePath )			
//			sRawScript	= UFPE_ConvertScript3to4( sRawScript  ) 	
//			if ( kb_AUTOWRITE_CONVERTED_FILE )
//				UFCom_WriteTxtFile_( sFilePath, sRawScript, 0 )
//			endif
//			sprintf sTxt, "\tLOADING AND CONVERTING  Version3  SCRIPT  '%s.txt'  to  FPuls4.  The V3 file will be renamed  '%s.tx3' ",  sFilePath, UFCom_StripPathAndExtension( sFilePath )
//		else										// must be new-style FPuls4
//
//			// Read the original new-style raw script including  comments and empty lines  for the script notebook and for storing it in the acquisition file 
//
//			sRawScript	= ReadScript( sFo, sFilePath )			
//			sprintf sTxt, "\tLOADING  SCRIPT  '%s'  ", sFilePath


		// 2010-01-11 convert old-style to new-style
		elseif ( nNewStyle == kPULSE_OLD )						// old-style FPulse V3xx

			sFilePath4		= UFCom_StripExtensionAndDot( sFilePath ) + "_.txt" 
			CopyFile	/O sFilePath   sFilePath4					
			sRawScript	= ReadScript( sFo, sFilePath4 )			
			sRawScript	= UFPE_ConvertScript3to4( sRawScript, 0  ) // last par: 0 or 1 bPrintIt
			if ( kb_AUTOWRITE_CONVERTED_FILE )
				UFCom_WriteTxtFile_( sFilePath4, sRawScript, 0 )
			endif
			sprintf sTxt, "\tLOADING AND CONVERTING  Version3  SCRIPT  '%s.txt'  to  FPuls4.  The V4 file will be renamed  '%s' ",  sFilePath, UFCom_RemoveFilePath( sFilePath4 )

		else												// is new-style FPuls4

			sRawScript	= ReadScript( sFo, sFilePath )			// Read the original new-style raw script including  comments and empty lines  for the script notebook and for storing it in the acquisition file 
			sprintf sTxt, "\tLOADING  SCRIPT  (V4xx)  '%s'  ", sFilePath

		endif
		
		printf "%s \r", sTxt									

		InitAllLoadScript( sFo )								// kills ar:wLine, clears graphs, kills all waves in 'root:uf:acq:'  
MarkPerfTestTime 202	// InterpretScript: InitAll1

		UFCom_IniFile_Read( sFo, sSubFoIni, sIniBasePath )			// retrieve the initialisation settings from file as early as possible (perhaps even earlier...)  			
		

	
		// Create the script notebook (but display it only if the state is not hidden)
		ConstructScriptNotebook( sFo, ksSCRIPT_NBNM, sFileNm, sRawScript )

		UFPE_CompactScript( sFo, sRawScript )					// 2005-0205  sets  globals  'gsScriptTxt'  and  'gsCoScript'  (original  amd compacted script without comments)
MarkPerfTestTime 204	// InterpretScript: Compact


		InitializeCFSDescriptors( sFo, sRawScript )					// 2005-0207 Should be called  only once during initialisation, but is actually called with every new script file as..
														// 1. flaw in Pascal Pulse (file name is inDesc)   2. number of script lines must be known. Could be improved?
		 // printf "\t\tLoadScript   receives %s\t-> FileNameDialog()  returns  %s\r", UFCom_pd(sPath,29), UFCom_pd(sFilePath,30)

		UFCom_ResetStartTimer_( sFo, "LoadScr" )

		variable	sc		 =   0									// index for applying multiple scripts
		Code	 		+=  InterpretScript_ns( sFo, ksFPUL, sRawScript, sc ) 	// sets globals lllstIO, llstBLF, lstTotdur 

		// only appropriate  in FPULSE; not in FEVAL
		string  	llstBLF		= LstBlf_( sFo )
		svar		lllstIO			= $"root:uf:" + sFo + ":" + "lllstIO" 	
		svar		lllstIOTG		= $"root:uf:" + sFo + ":" + "lllstIOTG" 	
		svar		lstTotdur		= $"root:uf:" + sFo + ":" + "lstTotdur" 	
		svar		lllstTapeTimes	= $"root:uf:" + sFo + ":" + "lllstTapeTimes" 	
		CreateAndFill_wG( sFo, sc, lllstIO, lllstIOTG, lstTotdur )
		wave	wG			 =   $FoWvNmWgNs( sFo )
		CreateGlobalsInFolder_Co_ns( sFo, UFPE_ksCOns )
		KillDataFolder/Z	$"root:uf:" + sFo + ":store"; NewDataFolder $"root:uf:" + sFo + ":store"	// for the data controlling the storing of periods and the skipping of blanks 
		
//			// Workaround as one can not pass svar  (lllstIO) as reference
//			string  	lllstIOCopy	 =  lllstIO
//			string  	lllstIOTG	 =  TelegraphConnect_ns( wG, lllstIOCopy )			// appends the telegraph channels to lllstIO and returns the TG-expanded triple list, changes and passes back 'lllstIOCopy'
//			lllstIO				 =  lllstIOCopy
//			UFCom_DisplayMultipleList( "lllstIO", lllstIO, "~;,", 7 )
//			UFCom_DisplayMultipleList( "lllstIOTG", lllstIOTg, "~;,", 7 )
		
		UFCom_ResetStartTimer_( sFo, "CedInit" )
		svar		lllstIOTG	 =   $"root:uf:" + sFo + ":" + "lllstIOTG" 	
		Code			+= CEDInitialize_ns( sFo, UFPE_ksCOns, sc, lllstIO, lllstIOTG, llstBLF, lstTotdur, lllstTapeTimes, wG ) 			

		UFCom_StopTimer_( sFo, "CedInit" )

		AcqTblSetCell( 	sFo, ksTBL_ACQ, num2str( trunc( UFCom_ReadTimer_( sFo, "CedInit" )/1000  ) ), "CedInit" )	

		UFCom_StopTimer_( sFo, "LoadScr" )
		AcqTblSetCell( 	sFo, ksTBL_ACQ, num2str( trunc( UFCom_ReadTimer_( sFo, "LoadScr" )/1000  ) ), "Load/ms" )	// Bad code as  column is fixed, should search table titles for  "DigOut"

		if ( Code  )							// Sets  wG , wIO ,  wFix , wE...... in  root:uf:acq:	, needs wLine(acq)	
			 printf "\tLOADING  '%s'  FAILED (code:%d)... \r", sFileNm, code
			UFCom_FoAlert( sFo, UFCom_kERR_IMPORTANT,  "Bad script file  or  script was empty..." )
// 2009-12-12 old-style
//			DoWindow /K $ksACQ_SD								// the StimDisp panel in Acq  'sda'

			DoWindow /K $"disp"
		else
			 printf "\tLOADING  '%s'  IS  DONE... \r", sFileNm
			UFCom_EnableButton(  "pul", 	"root_uf_acq_pul_ApplyScript0000",	  UFCom_kCo_ENABLE )	// 2003-0801allow  'Apply'  to check for errors if script is loaded no matter whether it contains errors or not
			UFCom_EnableButton(  "pul",	"root_uf_acq_pul_gbShowScrpt0000", UFCom_kCo_ENABLE )	// ..hide/edit a script at cold startup before it has been loaded a first time
			UFCom_EnableSetVar(  "pul",	"root_uf_acq_pul_gnProts0000", 	  UFCom_kCo_ENABLE_SV )// ..allow also changing the number of protocols ( which triggers 'ApplyScript()'  )
			UFCom_EnableButton(  "pul",	"root_uf_acq_pul_StartAcq0000", 	  UFCom_kCo_ENABLE )	// ..now allow to go into acquisition  after script loading has been completed
			UFCom_EnableButton(  "pul",	"root_uf_acq_pul_DisplayStim0000",  	  UFCom_kCo_ENABLE )	// ..now allow to display a stimulus after wE and wFixSwp..  have been set 
			UFCom_EnableButton(  "pul", 	"root_uf_acq_pul_buDisplStim0000",	  UFCom_kCo_ENABLE )	// ..now allow to display a stimulus after a script has been read
			UFCom_EnableButton(  "pul", 	"root_uf_acq_pul_buDiacWnAdd0000",UFCom_kCo_ENABLE )	// ..now allow to add an acq window to display an acquired trace after a script has been read
			UFCom_EnableChkbox( "pul", 	"root_uf_acq_pul_cbAppndData0000", UFCom_kCo_ENABLE )	// Checking this checkbox executes 'FinishActionProc()' which needs 'root:uf:acq:co:gbAcquiring and root:uf:acq:co:gbIncremFile' which have now been created as a script has been loaded

			UFCom_Panel3Main(   "pul" , 	"", 	"root:uf:" + ksACQ_,  100, 0 )		// Redraw the panel as Chans/Gains may have changed. Panel is assumed to exist, the title will be empty if the user has killed the panel.
	
			EnableDisableAxogains( sFo )									// works for both old- and new-style
			
			UFCom_ResetStartTimer_( sFo, "Display" )
// 2009-12-12 old-style
//			if (  nNewStyle == kPULSE_OLD )	// old-style
//				// Note: 	Changing the number of protocols reloads the display configuration which would destroy the recent user changes. 
//				// 		If the user wants to keep his changes he must save his disp cfg BEFORE he changes the number or protocols.
//				LoadDisplayCfg( sFo, sFilePath, "" )     		// 2006-0518	Introduced a 2. display configuration (but the primary display configuration is loaded by default here)
//			
//				//TurnButton( "pul", 	"root_uf_acq_pul_buAcDisplay0000",	UFCom_ON )	// Set 'Acq Display' button state to ON so that the Online Acquisition Display listbox will be built in the following line... 
//				LBAcDisUpdate()											// Rebuild the listbox completely as in meantime while the listbox perhaps was invisible e.g the number of channels may have changed
//			else
				// Note: ...???...Changing the number of protocols reloads the display configuration which would destroy the recent user changes. 
				// 	      ..???...	If the user wants to keep his changes he must save his disp cfg BEFORE he changes the number or protocols.
	
				LoadDisplayCfgAcq( sFo )		// 2006-0518	Introduced a 2. display configuration (but the primary display configuration is loaded by default here)
				LoadDisplayCfgStim( sFo )		
//			endif
			UFCom_StopTimer_( sFo, "Display" )

			UFCom_TurnButton( "pul",	"root_uf_acq_pul_buResSelOA0000",		UFCom_kON )		// 2006-0515 Set 'Select Results' button state to ON so that the Online Analysis listbox will be built in the following line... 
			LBResSelUpdateOA()														// 2006-0515 Rebuild the Online Analysis listbox  as  Process() /OnlineAnalysis()/AppendPointToTimeWaves()  depends on the existance

		endif
		
		UFCom_EnableButton("pul",	"root_uf_acq_pul_gbShowScrpt0000",	UFCom_kCo_ENABLE )	// ..hide/edit a script at cold startup before it has been loaded a first time
		UFCom_EnableButton( "pul",	"root_uf_acq_pul_SaveScript0000", 		UFCom_kCo_ENABLE )	// allow saving the script whether the scripts contains errors or not...
		UFCom_EnableButton( "pul",	"root_uf_acq_pul_SaveAsScrpt0000", 	UFCom_kCo_ENABLE )	// ....because the user must have a chance to store the script after removing errors

//UFCom_PrintAllTimers( 1 ) 
		UFCom_StopTimer_( sFo, "OverAll" )
		AcqTblSetCell( sFo, ksTBL_ACQ, num2str( trunc( UFCom_ReadTimer_( sFo, "OverAll" )/1000  ) ),	  "OverAll" )

  	endif		// strlen( sFilepath )


MarkPerfTestTime 290	// InterpretScript: End
MarkPerfTestTime 190	// LoadScript: end

// 2008-02-28
//Execute  "SetIgorOption DebugTimer,Stop"
	return	code
End 


// 2009-12-12 old-style
//Function 			InterpretScript( sFo )
//// Note:  InterpretScriptNoCedInit   and  InterpretScript    are introduced so that the  CedInitialize part can be separated into  UF_AcqCed.ipf  where it belongs. Otherwise all UF_AcqXXX.ipf files would have to be linked to Eval where they are not really needed.
//// reads script  as  'wLine'  , extracts all data, builds all the necessary DAC, ADC, Dig waves, and extracts (and stores) supplementary data needed for display formating, for IO, etc.
//// extracts the numbers  from ' wLine' and stores  them in ' wVal' ,  fills in missing values, builds DAC wave from ' wVal'
//// this routine is very slow when the script loaded contains MANY FRAMES and few sweeps/blocks (e.g 100 and  1/1)  compared to 10/10/1  or 10/1/10.  
//	string		sFo						// subfolder of root (root:'sF':...) used to discriminate between multiple instances of the  InterpretScript    e.g. from FPulse and from FEval
// 	if ( UFPE_InterpretScriptPart1( sFo, UFPE_kDOACQ ) == UFCom_kOK )
//
//		if ( UFPE_SupplyWavesCOMPChans( sFo ) )					// constructs 'PoNN' , 'PeakN' ....waves
//			return UFCom_kERROR 									
//		endif
//MarkPerfTestTime 220	// InterpretScript: SupplyCOMPChans
//
//		UFPE_DisplayStimulus( sFo, ksACQ_SD, kbACQ_STIMW_OS, UFPE_kDO_INIT )						// displays partial waves with automatic names,  UFPE_kDO_INIT= -1 enforces initialization 
//MarkPerfTestTime 221	// InterpretScript: DisplayStimulus
//	
//		UFCom_ResetStartTimer_( sFo, "CedInit" )
//		if ( CEDInitialize( sFo ) )			
//			return UFCom_kERROR 								// executing the Ced initialization already here (and not later when the acquistion is started)  saves valuable 'PreStart'-time 
//		endif
//		UFCom_StopTimer_( sFo, "CedInit" )
//		AcqTblSetCell( sFo, ksTBL_ACQ, num2str( trunc( UFCom_ReadTimer_( sFo, "CedInit" )/1000  ) ), 	"CedInit" )
//	
//MarkPerfTestTime 222	// InterpretScript: CEDInititialize
//	else
//		return	UFCom_kERROR
//	endif
//	return	0
//End


static Function	/S	ReadScript( sFo, sFilePath )
// Reads  script file  xxx.txt .   Data must be delimited by CR, LF or both.  
	string		sFo, sFilePath							// can be empty ...
	variable	nRefNum, nLine = 0, len1
	string		sLine		= ""
	string	  	sScript	= ""

	Open /Z=2 /R /P=$UFPE_ksSCRIPTS_SYMPATH  nRefNum  as sFilePath		// /Z = 2: opens dialog box  if file is missing,  /Z = 1: no dialog / does nothing if file is missing
 	// PathInfo /S $UFPE_ksSCRIPTS_SYMPATH;  printf "\t\tReadScriptFile(): Receives '%s'   Symbolic path '%s' does %s exist.  Has opened :'%s'  (RefNum:%d)  \r",sFilePath, S_path, SelectString( v_Flag,  "NOT", "" ), s_FileName, nRefNum 	

	if ( nRefNum != 0 )								//  2 failure modes: script file missing  or  user cancelled file open dialog
		do										// Read original script (keeping comments and empty lines) into string  'sScript'
			FReadLine nRefNum, sLine				// For the notebook  comments  and  empty lines  are kept..
			len1  = strlen( sLine )						// Empty lines contain CR or LF: their length is > 0...
			sScript += sLine 
		while ( len1 > 0 )     							//...is not yet end of file EOF
		Close nRefNum								// Close the script file... but reopen as a Notebook  below....

		variable	nRawLines = ItemsInList( sScript, "\r" )
		// printf "\t\tReadScript(   \t'%s', '%s' ) len:%3d, lines:%2d \r", sFo, sFilePath, strlen( sScript ), nRawLines

	else
		UFCom_FoAlert( sFo, UFCom_kERR_FATAL,  "Could not open '" + sFilePath + "' " )	
	endif
	// printf "\t\tReadScript() was asked to open and opened  sFilePath   '%s' \r", sFilePath
	return	sScript
End


//==================================================================================================================================
//==================================================================================================================================
//  PROCESSING  THE NEWSTYLE SCRIPT /  FAST SCRIPT LOADING

// Indices into wave  'wG'  holding all general numbers which define a script
static constant	UFPE_WG_SI = 0,  UFPE_WG_CNTDA = 1,  UFPE_WG_CNTAD = 2,  UFPE_WG_CNTTG = 3,  UFPE_WG_CNTPON = 4
//static constant	UFPE_WG_CNTIO = 5
static constant	UFPE_WG_BLOCKS = 6,  UFPE_WG_SWPWRIT = 7,  UFPE_WG_PNTS = 8,  UFPE_WG_TOTAL_US = 9,   UFPE_WG_SWPTOT = 10
static constant	UFPE_WG_MAX = 11

strconstant	UFPE_ksKPwgns	= "wgns"

Function	/S	FoWvNmWgNs( sFo )
	string  	sFo
	return	"root:uf:" + sFo + ":" + UFPE_ksKPwgns + ":wG"
End

static	Function	CreateAndFill_wG( sFo, sc, lllstIO, lllstIOTG, lstTotdur )
	string  	sFo
	variable	sc
	string  	lllstIO, lllstIOTG
	string  	lstTotdur				// for each block the info of total durations including all repeats and frames
	string  	sFoWvNm	= 	FoWvNmWgNs( sFo )
	UFCom_PossiblyCreateFolder( UFCom_RemoveLastListItems( 1, sFoWvNm, ":" ) )
	make /O/N = (UFPE_WG_MAX)   $sFoWvNm  = 0	// for all general acquisition variables	e.g. SmpInt, CntAD, Pnts [must not be deleted on 'Apply' after 'Start' as used in XOP]
	wave  	wG	  		        	= $sFoWvNm	    	// There are 2  instances of  'wG :  in FPulse  in folder  'Acq'   and in FEval  in folder  'eva' 
	wG[ UFPE_WG_SI		]	= SmpIntDacUs( sFo )
	wG[ UFPE_WG_CNTDA 	]	= ItemsInList( StringFromList( kSC_DAC, lllstIO, "~" ) )
	wG[ UFPE_WG_CNTAD	]	= ItemsInList( StringFromList( kSC_ADC, lllstIO, "~" ) )
	wG[ UFPE_WG_CNTTG	]	= ItemsInList( StringFromList( kSC_ADC, lllstIOTG, "~" ) ) -  ItemsInList( StringFromList( kSC_ADC, lllstIO, "~" ) )
	wG[ UFPE_WG_CNTPON	]	= 0
	//wG[ UFPE_WG_CNTIO	]	= 5	// not used
	wG[ UFPE_WG_BLOCKS	]	= 0
	wG[ UFPE_WG_SWPWRIT ]	= 0
	wG[ UFPE_WG_PNTS	]	= TotalTrueDurPts_( sFo, sc )
	wG[ UFPE_WG_TOTAL_US ]	= wG[ UFPE_WG_PNTS ] * wG[ UFPE_WG_SI ] // !!!!!!!!!!!!!  * nProts 
	wG[ UFPE_WG_SWPTOT	]	= 0
End
		

// Not all combinations are valid e.g. it makes no sense to have a Dac have a TGChan, and although PoN has a SmpInt the user should not have access to it in the script.
// Only valid IO-IOSubkey -combinations are included in wSK, those missing there are invalid.
// Only Chan and SmpInt must be provided in the script, others can be missing. Checking those 2 entries is not coded in wSK but done automatically elsewhere.
//strconstant	ksIOTYPES	= "Dac;Adc;PoN;Sum;Aver;"									// must be same order as in wMK[]
//constant			UFPE_IOT_DAC = 0,   UFPE_IOT_ADC = 1,   UFPE_IOT_PON = 2,  UFPE_IOT_SUM = 3,  UFPE_IOT_AVER = 4,  UFPE_IOT_MAX = 5	// must be same order as in wMK[]

//constant			UFPE_IO_NM = 0,  UFPE_IO_CHAN = 1,  UFPE_IO_NAME = 2
//constant			UFPE_IO_GAIN = 3,  UFPE_IO_GAINOLD = 4,  UFPE_IO_TGCH = 5,  UFPE_IO_TGMCCH = 6,  UFPE_IO_SRC = 7,  UFPE_IO_UNIT = 8,  UFPE_IO_SMPI = 9,  UFPE_IO_RGB = 10,  UFPE_IO_USED = 11,  UFPE_IO_LAST = 12
//static strconstant	sALLIODATA 	= "Nm;Chan;Name;Gain;GainOld;TGChan;TGMCChan;Src;Units;SmpInt;RGB;used;"

strconstant	UFPE_ksCOns	= "cons"

static Function	CreateGlobalsInFolder_Co_ns( sFo, sSubFo )
// creates all folder-specific variables. To be used once from CreateGlobals() as the current data folder is changed and not restored
	string  	sFo, sSubFo
	string		sDFSave		= GetDataFolder( 1 )			// remember CDF in a string.
	NewDataFolder  /O  /S  $"root:uf:" + sFo + ":" + sSubFo	// acquisition: create a new data folder and use as CDF,  clear everything
	variable	/G	gnAddIdx
	variable	/G	gnLastDacPos
	variable	/G	gReserve			= Inf
	variable	/G	gMinReserve		= Inf
	variable	/G	gErrCnt			= 0
	variable	/G	gnRep, gnReps
	variable	/G	gnChunk
	variable	/G	gPntPerChnk
	variable	/G	gChnkPerRep
	variable	/G	gnOfsDO
	variable	/G	gnOfsDA, gSmpArOfsDA
	variable	/G	gnOfsAD, gSmpArOfsAD
	variable	/G	gnCompressTG
	variable	/G	gMaxSmpPtspChan
	variable	/G	gCedMemSize		= UFPE_kTESTCEDMEMSIZE	
	variable	/G	gBkPeriodTimer
	variable	/G	gbIncremFile
	variable	/G	gbAcquiring		= 0 
	SetDataFolder sDFSave								// restore CDF from the string value
End

