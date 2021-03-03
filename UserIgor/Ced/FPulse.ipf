// FPulse.ipf  :	The old version branch  V3xx
//			Add a direct entry  in  IGORs  'Analysis'  menu  and  set  the  FPulse version number. 
// 			There must be a shortcut from this file into ..\ Programme \ Wavemetrics \ Igor Pro Folder \ Igor Procedures 

#pragma rtGlobals=2		// Use modern global access method.  

Menu "Analysis", dynamic
	AnalysisMenuItem( 1 ), /Q, Execute/P/Q/Z "INSERTINCLUDE \"FPulseMain\""; 	Execute/P/Q "COMPILEPROCEDURES ";	Execute/P/Q "FPulse()"	
	AnalysisMenuItem( 2 ), /Q, Execute/P/Q/Z "INSERTINCLUDE \"FEvalMain\""; 	Execute/P/Q "COMPILEPROCEDURES ";	Execute/P/Q "FEvl()"	
	"Quit FPulse "+ksVERSION[0,0] + "." + ksVERSION[1,inf] ,  UnloadFPuls3()		
	"Quit FEval " + ksVERSION[0,0] + "." + ksVERSION[1,inf] ,  UnloadFEval3()		
End

Function	/S	AnalysisMenuItem( nItem ) 
	variable	nItem
	string  	lstPrograms	= "empty;FPulse;FEval ;"			// numbering starts at 1
	string  	sVersion		= FormatVersion()				// e.g. '300'  -> '3.00'  or  '302c'  ->  '3.02.c'
// 2009-10-22 modify for Igor6    GANZ WEG
//	return	SelectString( xUtilError( 2 ) == -1, "" , "(" ) + StringFromList( nItem, lstPrograms ) + sVersion
	return									StringFromList( nItem, lstPrograms ) + sVersion
End

static Function	/S	FormatVersion()	 
// formats version string  e.g. '300'  -> '3.00'  or  '1302c'  ->  '13.02.c'
	string  	sVersion, sVersionOrg	 = ksVERSION				// e.g. '300'  or  '1302c'
	variable	nVersionNumber	= str2num( sVersionOrg )		// e.g. '300'  or  '1302'
	variable	len				= strlen( sVersionOrg )
	string  	sVersionLetter		= SelectString( len == strlen( num2str( nVersionNumber ) ) , "." + sVersionOrg[ len-1, len-1 ], "" )  
	sprintf  sVersion, " %.2lf%s %s" , nVersionNumber / 100 , sVersionLetter, SelectString( kbIS_RELEASE, "D", "" )	// D is reminder if we are still in the debug version
	return	sVersion
End


// 2009-10-22 modify for Igor6  separate main menu items 

//Menu "FPulse", dynamic
//	FP_MenuItem(), /Q, Execute/P/Q/Z "INSERTINCLUDE \"FPulseMain\""; 	Execute/P/Q "COMPILEPROCEDURES ";	Execute/P/Q "FPulse()"	
//End
//
//Menu "FEval", dynamic
//	FE_MenuItem(), /Q, Execute/P/Q/Z "INSERTINCLUDE \"FEvalMain\""; 	Execute/P/Q "COMPILEPROCEDURES ";	Execute/P/Q "FEval()"	
//End
//
//Function	/S	FP_MenuItem() 
//	variable	nItem
//	return  	"FPulse" + FormatVersion()		// e.g. '300'  -> '3.00'  or  '302c'  ->  '3.02.c'
//// 2009-10-22 modify for Igor6    GANZ WEG
////	return	SelectString( xUtilError( 2 ) == -1, "" , "(" ) + StringFromList( nItem, lstPrograms ) + sVersion
//End
//
//Function	/S	FE_MenuItem() 
//	variable	nItem
//	return	"FEval" + FormatVersion()		// e.g. '300'  -> '3.00'  or  '302c'  ->  '3.02.c'
//// 2009-10-22 modify for Igor6    GANZ WEG
////	return	SelectString( xUtilError( 2 ) == -1, "" , "(" ) + StringFromList( nItem, lstPrograms ) + sVersion
//End
// 
//static Function	/S	FormatVersion()	 
//// formats version string  e.g. '300'  -> '3.00'  or  '1302c'  ->  '13.02.c'
//	string  	sVersion, sVersionOrg	 = ksVERSION				// e.g. '300'  or  '1302c'
//	variable	nVersionNumber	= str2num( sVersionOrg )		// e.g. '300'  or  '1302'
//	variable	len				= strlen( sVersionOrg )
//	string  	sVersionLetter		= SelectString( len == strlen( num2str( nVersionNumber ) ) , "." + sVersionOrg[ len-1, len-1 ], "" )  
//	sprintf  sVersion, " %.2lf%s %s" , nVersionNumber / 100 , sVersionLetter, SelectString( kbIS_RELEASE, "D", "" )	// D is reminder if we are still in the debug version
//	return	sVersion
//End


static strconstant	ksACOld				= "aco"			// the one-and-only subfolder
static strconstant	ksEVO				= "evo"			// the one-and-only subfolder
 
strconstant		ksAPP_NAME			= "FPulse"	 	 
strconstant		ksVERSION			=  "333"			// Use 3 or 4  digits (and optionally 1 letter) . CONVENTION: Increment AFTER releasing.....
constant			kbIS_RELEASE			=  1				// Set to 1 only temporarily  in a Release version.  Is normally set to 0 during  program development to facilitate debugging.


strconstant		ksfACOVARS		= "acovars"		// Subfolder for internal variables, waves and strings  introduced  to hide and protect them from the user....
strconstant		ksfACOVARS_		= "acovars:"		// ....Located in the  'root:uf:eva' subfolder  parallel  to the  main panel subfolder 'evl'  and parallel to any waves which the user might access.
strconstant		ksfEVOVARS		= "evovars"		// Subfolder for internal variables, waves and strings  introduced  to hide and protect them from the user....
strconstant		ksfEVOVARS_		= "evovars:"		// ....Located in the  'root:uf:eva' subfolder  parallel  to the  main panel subfolder 'evl'  and parallel to any waves which the user might access.



// Late Patches as version 400 exists since 051208
//strconstant		ksVERSION			=  "333"			// 2010-03-30 (2010-03-29) Eliminated the 'Can not SetTranferArea' flaw by using 1.FIXED  and 2. SMALLER  TranferArea size .  Increased  MAXDIGOUT from 2000 to 10000.
//strconstant		ksVERSION			=  "332"			// 2010-03-27 Fixed BAD ACQ BUG ('Missing Data'). Remove Statusbar when FPulse is 'Quit' .  This avoids the error occurring when referencing the non-existant wave 'wG'.
//strconstant		ksVERSION			=  "331"			// 2010-02-17 Revamped Ced acquisition so that V3 and V4 can both be used at the same time (Must reload the script when switching versions)
//strconstant		ksVERSION			=  "330"			// 2009-12-11 Ced Power1401Mk2  is now recognised.   Replaced all Ced files (.c, .h, .lib, .dll) by newest versions
//strconstant		ksVERSION			=  "329"			// 2009-12-10 moved  misc folder in Eval from aco.misc  to evo.misc. 
//strconstant		ksVERSION			=  "328"			// 2009-12-10 fixed bug in Acq Display configuration load/save (due to additionally inserted  folder 'aco' the control names were too long)
//strconstant		ksVERSION			=  "327"			// 2009-10-30 removed trial time kTTD.  There are now 2 StimDisp panels and 2 DataUtil panels (separate panels for ACOld and EVOld )
//strconstant		ksVERSION			=  "326"			// 2009-10-28 Menu items 'Quit Eval3' and 'Quit FPuls3' (->deleted hook function).  Also move 'ola' and 'disp' into 'aco',  The only remaining folders are 'aco, evo, dlg, dbgprint' so now the versions 32x and 61x should be able to coexist.
//strconstant		ksVERSION			=  "325"			// 2009-10-28 move 'cfsr' into 'evo', create 'evo:lb' . 
//strconstant		ksVERSION			=  "324"			// 2009-10-28 renaming  eva -> evo 
//strconstant		ksVERSION			=  "323"			// 2009-10-27 
//strconstant		ksVERSION			=  "322"			// 2009-10-27 renaming  acq -> aco 
//strconstant		ksVERSION			=  "320"			// 2009-10-22 modify for Igor6: Removed loop in action procs.  Removed trial time/birthfile (also in XOPs). Using InnoSetup5 (IgorPro folder path changed, no birth file).

//strconstant		ksVERSION			=  "319"			// 060821  Movies : subtract base line
//strconstant		ksVERSION			=  "318"			// 060712  Movies
//strconstant		ksVERSION			=  "317a"			// 060526  No error found...........Attempted to fix error in StimWave interpolation when interpolating different sample rates and  sclX!=1 (Neither I nor Li could not reproduce error)
//strconstant		ksVERSION			=  "317"			// 060515a  Keep Disp config when changing the number of protocols   060515b
//strconstant		ksVERSION			=  "316"			// 060511a  Data sections panel has adjustable column widths    060511b  Added a 3. Base/peak region for OLA    060511c Fixed rsTNm/AutoScalerror  060511d Fixed  DcFit/RiseFit nvar flaw    060511e  New  Mini Help in Acq     060511f   Append mode comments  and renaming
//strconstant		ksVERSION			=  "315"			// 060414 Error in Eval handling Pon protocols  060419 Error avoiding protocols with odd number of points
//strconstant		ksVERSION			=  "314"			// 060406 Peak and Peak2 may have different settings for 'average  peak over ms' 
//strconstant		ksVERSION			=  "313"			// 060406 Script now recognises and outputs StimWave parameters Y-Offset  and  X-Scaling
//strconstant		ksVERSION			=  "312a"			// 060221 InnoSetup now also copies FEvalHelp.txt
//strconstant		ksVERSION			=  "312"			// 060220 Slopes OK
//strconstant		ksVERSION			=  "311"			// 060219 'FEvalHelp.txt'  will automatically be found. Listbox Contextual menu to set 'All Mov Avg'.  Result table Contextual menu to compute 'Mean of a column.
//strconstant		ksVERSION			=  "310"			// 060216 Alignment of averages (hopefully OK, no longer depending on Latencies) .  DT50 error (EvaluateCrossings) . Reduced smoothpoints for 7 to 5. Still better todo: make automatic or adjustable
//strconstant		ksVERSION			=  "309"			// 060213 Alignment of averages with Latencies 0,1,2  (wrong)
//strconstant		ksVERSION			=  "308"			// 060210 Convert Dat files into old style for  'StimFit' compatibily by removing the script.
//strconstant		ksVERSION			=  "307a"			// 060208 InnoSetup makes 1 link to the  'UserIgor\Ced\' directory but no longer to each file (recommendation of HR, WaveMetrics)
//strconstant		ksVERSION			=  "306h"			// 060206 Delayed patch: make E3E4 HW trigger work

//strconstant		ksVERSION			=  "306f"			// 051109 AutoSetCursors. Rseries test pulse adjustable. User cannot proceed when  'redimension' error occurs again.  Bug fixes: Radio buttons are now OK when settings are recalled. Result selection listboxex are no longer cleared when a new file is loaded.
//strconstant		ksVERSION			=  "306e"			// 051105	workaround for  'redimension'  error :   to provoke the error set  bCRASH_ON_REDIM_TEST14 = TRUE , execute 'Pntest()  and  'test14'
//strconstant		ksVERSION			=  "306d"			// 051103	moving average : working but some flaws and inconsistencies
//strconstant		ksVERSION			=  "306c"			// 051021	non-proportional font in the eval textbox
//strconstant		ksVERSION			=  "306b"			// 051021	Computes Mean, SDBase and Event Validity
//strconstant		ksVERSION			=  "306a"			// 051020	BigStep for evaluation  (distinguishing between small and capital letters). 	First really useful version.
//strconstant		ksVERSION			=  "305o"			// 051020	Latency cursors and lots of improvements and bug fixes. 
//strconstant		ksVERSION			=  "305n"			// 051012	Unfinished. For A. Harris. 	Error reading the same data twice fixed.  Evaluated and derived parameters now have units. FitFail results are red. Simplified Eval panel usage.
//strconstant		ksVERSION			=  "305m"			// 051006 Unfinished. For Pauli.   	Reads truncated file 'dummydye0AM.dat' .    'FEvalHelp.txt'  included in the release version.
//strconstant		ksVERSION			=  "305l"			// 051004 Unfinished. For A. Harris.	Units in the evaluation window textbox.  Convert evaluation results into XY wave (button 'conv tvl > XY'). Computes Capacitance and weighted tau.
//strconstant		ksVERSION			=  "305k"			// 051004 Unfinished. For Pauli. 
//strconstant		ksVERSION			=  "305j"			// 050921 Unfinished. Proceeded with Evaluation: Viewing  and  averaging/analysis are now separate. Analysis now works also in 'catenate' and 'stacked' mode
//strconstant		ksVERSION			=  "305i"			// 050902 Unfinished. Proceeded with Evaluation: mainly result -> table -> file  and lots of related things
//strconstant		ksVERSION			=  "305h"			// 050817 Unfinished. Proceeded with Evaluation: mainly result selection listbox panels  and lots of related things
//strconstant		ksVERSION			=  "305g"			// 050726 Unfinished. Combined Eval and details panel  but crashes when attempting to close the EvalDetails3 panel (maybe Igor 5.04 problem?)
//strconstant		ksVERSION			=  "305f"			// 050610 Unfinished. Combined Eval and details panel.  Converted   Misc-Panel  to new style.  Fixed bug concerning 2 DA chans + 2 blocks (FPStim.ipf wELine[ c ][ f.. ->  wELine[ c ][ b.. )
//strconstant		ksVERSION			=  "305d"			// 050503 Unfinished. Advanced 4 dimensional panels. DebugPrintOptions  in FPulseMain rather than in FPTest. gbRunning etc. in :keep: instead of  :co:   Delete button disabled during acquisition 
//strconstant		ksVERSION			=  "305c"			// 050428 Unfinished. Advanced 4 dimensional panels... 
//strconstant		ksVERSION			=  "305b"			// 050413 Unfinished. Advanced 4 dimensional panels but evaluation is not yet making use of them...
//strconstant		ksVERSION			=  "305a"			// 050205 Script are stored in Cfs Acq file including comment, limit 64 lines->15kByte. Eliminated wLines -> gsCOScript instead. Moved  InitializeCfsDescriptors   into  LoadScript  
//strconstant		ksVERSION			=  "304f"			// 050204 Fixed crash (TG array was 1 too short in some cases)
//strconstant		ksVERSION			=  "304d"			// 041215 First try on data section listbox : display but no analysis yet
//strconstant		ksVERSION			=  "304c"			// 041215 Average now writes every point (used to be for testing every 100th point)
//strconstant		ksVERSION			=  "304b"			// 041215a changed default behavior: now all acq windows are initially off. Reason: with many frames and 'Many Supimp' on  building all the acqr windows took awfully long. Better would be more specific: e.g. only Frames and Current ON...
//strconstant		ksVERSION			=  "304a"			// 041213 removed bugs in OLA, made panels Gain, DispAcq and OLA remember their position
//strconstant		ksVERSION			=  "303a"			// 041206 Comments stripped out of release version
//strconstant		ksVERSION			=  "302a"			// 041203 Fixed heap scramble problem . Removed string handle locking in the XOPs completely (IHC2 -> IHC)
//strconstant		ksVERSION			=  "301a"			// 041130	Release with InnoSetup

//constant			knVERSION			=  241			// 041005 Unfinished. Connected  MultiClamp 700B    and started  controlling the  700A and 700B from FPulse
//constant			knVERSION			=  240			// 040920 Unfinished. Split into FPulse and Eval.  Eval revisited and made to behave like Pascal StimFit. 
//constant			knVERSION			=  239			// 040801 Online analysis revisited (decay fit, multiple traces in 1 acq window)
//constant			knVERSION			=  238			// 040707 Data filtering ,  Release/Installation/Deinstalllation routines
//constant			knVERSION			=  237			// 040429 rearranged panels, colored buttons and text fields
//constant			knVERSION			=  236			// 040420 major revision of Display Stimulus  (stack frames + cat sweeps, 1 large display trace rather than many small ones , faster )
//constant			knVERSION			=  235			// 040310 ReadCFS  speed improvement  and  OnlineAnalysis 
//constant			knVERSION			=  234			// 040310 Fourth refinement of OnlineAnalysis 
//constant			knVERSION			=  233			// 040227 Third refinement of OnlineAnalysis 
//constant			knVERSION			=  232			// 040223 Second refinement of OnlineAnalysis 
//constant			knVERSION			=  231			// 040217 First refinement of OnlineAnalysis 
//constant			knVERSION			=  230			// 040217 Fixed error drawing only the 1 frame, reactivated and adjusted OnlineAnalysis
//constant			knVERSION			=  229			// 040120 Multiple instances of same trace in acq window, YOfs slide, Gains revamped
//constant			knVERSION			=  228			// 031215 Standard 1401 supported. Works with Igor5. ReadCfs finally handles  multiple blocks in conjunction with a truncated last protocol.
//constant			knVERSION			=  227			// 031120 removed Timer2 mode, instead Blank chunks are eliminated
//constant			knVERSION			=  226			// 031111 Avoids GetVarDesc error when there are too many script lines to be stored in script .'Apply' is much faster when there are many blocks and at the same time many frames
//constant			knVERSION			=  225			// 031104 new acquisition mode in which the 'InterBlockInterval/InterProtocolInterval'  (= 'Blank' line after 'EndFrame' ) is processed differently: the acquisition is stopped and restarted when the next stimulus is to begin.
//constant			knVERSION			=  224			// 031101 A Y Zoom factor determines the length of the Y axis in the acquisition windows, previously the length mixed up with the AxoPatch gain could be set.
//constant			knVERSION			=  223			// 031006 Hardware triggered E3E4 acq mode, decrease CED memory, set reaction time
//constant			knVERSION			=  222			// 030918 ReadCfs reads multiple (but not yet truncated) protocols
//constant			knVERSION			=  221			// 030915 finished compressed telegraphs, improved Transfer area and Ced memory usage, SetTransferArea keeps minimum
//constant			knVERSION			=  220			// 030725 MarkPerfTestTime, compressed telegraphs, bugfix to read IgorPlsT200 data files, bugfix to read FPulse211 data with very many frames (appr.>100)
//constant			knVERSION			=  219			// 030715 eliminated delay after 'Start'
//constant			knVERSION			=  218			// 030710 file filter in ReadCfs,  button AND text input 'DataPath' directory selection, oversized  PN_SETSTR, PN_DISPSTR fields
//constant			knVERSION			=  217			// 030707 made digital output behave the same on power1401 and on 1401plus with hardware error...and removed the code again as CED fixed the power1401
//constant			knVERSION			=  216			// 030627 fixed multiple bugs in digital output for power1401 (but 1401plus will not work)
//constant			knVERSION			=  215			// 030612 fixed bugs MultiClamp, DataPath
//constant			knVERSION			=  214			// 030601..030611	'Axes and Scalebars', rescaling of data from 'IgorPlsT205'...
//constant			knVERSION			=  213			// 030513	telegraph data no longer stored or displayed, MultiClamp telegraphs introduced
//constant			knVERSION			=  212			// 030404	CfsRead  now reads  multiple blocks
//constant			knVERSION			=  211			// 030327	Errors: Cosmetics: Reread split into Apply and Save/as/copy
//constant			knVERSION			=  210			// 030326	Errors:CFSRead  SmpInt was fixed 100, IFI+IBI, Cosmetics: Short Dac and DigOut pulses are stretched for display New: zoom with double click
//constant			knVERSION			=  209			// 030313	Errors:DigOut, Telegraph. New (not yet released): Evaluation similar to Stimfit
//constant			knVERSION			=  208			// 030130	Errors:CFS-YScale.    Revamped: Panels.   New (not yet released): Automatic help


//========================================================================================================================================================
// UNLOADING THE APPLICATION

static strconstant UFCom_ksROOT_UF_	= "root:uf:"

Function 	UnloadFEval3()
	EV3_RemovePanels()
 	UnloadApplication_( UFCom_ksROOT_UF_,  ksEVO, "FEvalMain" )
End

Function 	UnloadFPuls3()
	DoWindow /K $"SB_ACQUISITION"	// 2010-03-25 (ksSB_WNDNAME="SB_ACQUISITION")      Remove the Statusbar window.  If the Statusbar window remained  'LaggingTime()'  tries to call non-existent 'wG'
	FP3_RemovePanels()
 	UnloadApplication_( UFCom_ksROOT_UF_,  ksACOld, "FPulsMain" )
	KillBackground					// 2010-02-08 untested, but should be helpful when switching between  FPulse versions 3 and 4 .   Must perhaps be made more specific: NOW it KILLS  ALL bkg functions in ALL applications?????
End


Function 	UnloadApplication_( sRootUf,  sSubFolder, sApplMain )
	string  	sRootUf,  sSubFolder, sApplMain
	UF_KillDataFoldUnconditionly( sRootUf +  sSubFolder )		// kill the folder  'root:uf:ev0'  or  'root:uf:aco'  including all variables, strings and waves (if required also kill the windows using the waves to be killed)  
	Execute/P "DELETEINCLUDE \""+ sApplMain +"\""		// Unload specific procedure files.  However, procedure windows opened by double-clicking on the file remain open, especially ALL  included files opened by double-clicking on THIS file.
	Execute/P/Q "COMPILEPROCEDURES "
End

// -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// The following code has been copied from  'UFCom_DataFoldersAndGlobals.ipf'  
// By copying the code we do not have to  #include  'UFCom_DataFoldersAndGlobals.ipf' , 'UFCom_Constants.ipf'  (and other files) which simplifies the Debug/Release processing. 

static constant	UFCom_kDF_FOLDERS	= 1,  	UFCom_kDF_WAVES 	   = 2,   	UFCom_kDF_VARIABLES = 4,   UFCom_kDF_STRINGS 	= 8
static	 constant	UFCom_kIGOR_WAVE	= 1,  	UFCom_kIGOR_VARIABLE  = 2, 	UFCom_kIGOR_string  	= 3, 	UFCom_kIGOR_FOLDER	= 4	

static Function		UF_KillDataFoldUnconditionly( sFolderPath )
	string  	sFolderPath
	if ( DataFolderExists( sFolderPath ) )
		UF_ZapAllDataInFolderTree( sFolderPath )
		KillDataFolder   $sFolderPath
		if ( V_Flag )
			printf "+++Error: CDF is '%s' .   Tried to but could not kill data folder '%s' .  Objects left: \r", GetDataFolder( 1 ), sFolderPath
			//string		sDFSave	= GetDataFolder( 1 )			// remember CDF in a string.
			print	DataFolderDir( UFCom_kDF_FOLDERS |  UFCom_kDF_WAVES |  UFCom_kDF_VARIABLES |  UFCom_kDF_STRINGS )
			//SetDataFolder sDFSave							// restore CDF from the string value
		endif
	endif
End


static Function 		UF_ZapAllDataInFolderTree( sFolderPath )
// Deletes recursively ALL variables, strings and waves from  'sFolderPath'  and its subfolders. 
// Deletes  waves even if they are used in a graph or table by first killing  tables and graphs
// Todo/ToCheck: text waves, panels,   waves used in XOPs,  locked waves ?
	string 	sFolderPath

	if ( DataFolderExists( sFolderPath ) )
		string 	savDF	= GetDataFolder(1)
	
		SetDataFolder sFolderPath							// e.g. 'stim'
		string  	curDF	= GetDataFolder(1)				// e.g. 'root:uf:acq:stim'
	
		KillVariables	/A/Z
		KillStrings		/A/Z
	
		// First kill all windows which contain waves, so that afterwards the waves can be killed.
		KillWaves		/A/Z										// try to kill as many waves as possible, those used in graphs, tables or XOPs can not and will not be killed
		string  	lstWaves		= WaveList( "*" , ";" , "" ) 				// these waves could not be killed as they are in use
		variable	wv, nWaves	= ItemsInList( lstWaves )
		if ( nWaves )
			 printf "\t\tUF_ZapAllDataInFolderTree  1 \tCDF is '%s' . \tsFolderPath: '%s' : %4d waves could not be killed because of open windows: '%s...'  \r", curDF, sFolderPath, nWaves, lstWaves[0,200]
		endif
		for ( wv = 0; wv < nWaves; wv += 1 )
			//string  	sWave	= RemoveEnding( sFolderPath, ":" ) + ":" 	+ StringFromList( wv, lstWaves )
			string  	sWave	= curDF 							+ StringFromList( wv, lstWaves )
			string  	lstWins	= UF_AllWindowsContainingWave( sWave )
			variable	wnd, nWins	= ItemsInList( lstWins )
			for ( wnd = 0; wnd < nWins; wnd += 1 )
				string  sWin	= StringFromList( wnd, lstWins )	
				 printf "\t\tUF_ZapAllDataInFolderTree 2 \tCDF is '%s' . \tsFolderPath: '%s' \tKilling window '%s' containing wave '%s'  \r", curDF, sFolderPath, sWin, sWave

// ???? BUG  ???? 2009-06-15   Igor complains here about a missing wave .     But  kill/killvote events in hook function are not to blame  
				KillWindow $sWin							// kill the window which contains 'sWave'
			endfor
		endfor
		KillWaves		/A/Z										// now it should be possible to also kill the remaining waves 
		lstWaves		= WaveList( "*" , ";" , "" ) 						// these waves could not be killed as they are in use
		if ( ItemsInList( lstWaves ) )
			 printf "+++Error : UF_ZapAllDataInFolderTree 3    \tCDF is '%s' . \tsFolderPath: '%s' : %4d waves could not be killed after deletion of windows: '%s...'  \r", curDF, sFolderPath, nWaves, lstWaves[0,200]
		endif
	
		variable 	i
		variable 	nDataFolderCnt = CountObjects( ":" , UFCom_kIGOR_FOLDER )			// kill all subfolders (4 is data folder)
		for ( i = 0; i < nDataFolderCnt; i += 1 )
			string 	sNextPath = GetIndexedObjName( ":" , UFCom_kIGOR_FOLDER , i )
			UF_ZapAllDataInFolderTree( sNextPath )
		endfor
		SetDataFolder savDF
	endif
End

static Function	/S	UF_AllWindowsContainingWave( sWaveNm )
// Returns list of windows containing the wave 'sWaveNm'  e.g. "root:uf:MyWave" .  
// All graphs, tables and  layouts are searched.  Text waves are ignored.
	string  	sWaveNm
	return	UF_MatchWinsContainingWave( sWaveNm, "*" , ";" , "WIN:7" )	// 1+2+4
End

static Function	/S	UF_MatchWinsContainingWave( sWaveNm, matchStr, separatorStr, optionsStr )
// Returns list of windows containing the wave 'sWaveNm'  e.g. "root:uf:MyWave" .  
// Only windows matching the  'WinList()' parameters are searched.   Text waves are ignored.
	string  	sWaveNm
	string  	matchStr, separatorStr, optionsStr 	
	string  	lstWinsContainingWave	= ""
	string  	lstWinsToCheck	= WinList( matchStr, separatorStr, optionsStr )
	variable	w, nWins	= ItemsInList( lstWinsToCheck, separatorStr )
	for ( w = 0; w < nWins; w += 1 )
		string  	sWin	= StringFromList( w, lstWinsToCheck, separatorStr )
		CheckDisplayed	/W=$sWin  $sWaveNm
		if ( V_flag & 1 )
			lstWinsContainingWave += sWin + separatorStr
		endif
	endfor
	 printf "\t\t\tWave '%s' is contained in %d window(s) : '%s....' \r", sWaveNm, ItemsInList( lstWinsContainingWave, separatorStr ), lstWinsContainingWave[0, 200]
	return	lstWinsContainingWave
End	

//=========================================================================================================================
//  THE  LIST  OF  ALL  PANELS  CONSTRUCTED  IN  FEVAL  (is required when FEval is to be removed from Igor)

 Function		FP3_RemovePanels()
	variable pa, paCnt	= ItemsInList( LstPanels_Fp3() )
	for ( pa = 0; pa < paCnt; pa += 1 )
		string     sPanel	= StringFromList( pa, LstPanels_Fp3() )	
		if ( WinType( sPanel ) == 7 )		// 7 is panel 
			KillWindow	$sPanel
		endif
	endfor
End

Function		LstPanels_Fp3Set( lst )
	string  	lst
	string  /G			$UFCom_ksROOT_UF_ + ksACOld + ":"  + ksfACOVARS_ + "lstPanels"	= lst
	// print "LstPanels_Fp3Set", lst
End	

Function	/S	LstPanels_Fp3() 
	svar  /Z	lst	= 	$UFCom_ksROOT_UF_ + ksACOld + ":"  + ksfACOVARS_ + "lstPanels"
	if ( ! svar_exists( lst ) )																// OK on first call
		string  /G		$UFCom_ksROOT_UF_ + ksACOld + ":"  + ksfACOVARS_ + "lstPanels"	= ""
		svar  /Z	lst =	$UFCom_ksROOT_UF_ + ksACOld + ":"  + ksfACOVARS_ + "lstPanels"
		if ( ! svar_exists( lst ) )		// OK now only if folders do not exist because user selected 'Quit' before starting the application....
			return	""		// todo_c: better solution is to gray the 'Quit' menu item when not allowed			
		endif
	endif
	return	lst
End


Function		EV3_RemovePanels()
	variable pa, paCnt	= ItemsInList( LstPanels_Eva3() )
	for ( pa = 0; pa < paCnt; pa += 1 )
		string     sPanel	= StringFromList( pa, LstPanels_Eva3() )	
		if ( WinType( sPanel ) == 7 )		// 7 is panel 
			KillWindow	$sPanel
		endif
	endfor
End

Function		LstPanels_Eva3Set( lst )
	string  	lst
	string  /G			$UFCom_ksROOT_UF_ + ksEVO + ":"  + ksfEVOVARS_ + "lstPanels"	= lst
	// print "LstPanels_Eva3Set", lst
End	

Function	/S	LstPanels_Eva3() 
	svar  /Z	lst	= 	$UFCom_ksROOT_UF_ + ksEVO + ":"  + ksfEVOVARS_ + "lstPanels"
	if ( ! svar_exists( lst ) )																// OK on first call
		string  /G		$UFCom_ksROOT_UF_ + ksEVO + ":"  + ksfEVOVARS_ + "lstPanels"	= ""
		svar  /Z	lst =	$UFCom_ksROOT_UF_ + ksEVO + ":"  + ksfEVOVARS_ + "lstPanels"
		if ( ! svar_exists( lst ) )		// OK now only if folders do not exist because user selected 'Quit' before starting the application....
			return	""		// todo_c: better solution is to gray the 'Quit' menu item when not allowed			
		endif
	endif
	return	lst
End
