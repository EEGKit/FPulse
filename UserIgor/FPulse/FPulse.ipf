// FPulse.ipf  :	The old version branch  V3xx
//			Add a direct entry  in  IGORs  'Analysis'  menu  and  set  the  FPulse version number. 
// 			There must be a shortcut from this file into ..\ Programme \ Wavemetrics \ Igor Pro Folder \ Igor Procedures 

#pragma rtGlobals=2		// Use modern global access method.  

static strconstant ksROOT_UF_	= "root:uf:" 

Menu "FPulse", dynamic
	FPUL_Title(), /Q, Execute/P/Q/Z "INSERTINCLUDE \"FPulseMain\""; 	Execute/P/Q "COMPILEPROCEDURES ";	Execute/P/Q "FPulse()"
	" Quit " +  FPUL_Title() ,   UnloadFPuls3()
End

Menu "FEval", dynamic
	FE_Title(), /Q, Execute/P/Q/Z "INSERTINCLUDE \"FEvalMain\""; 	Execute/P/Q "COMPILEPROCEDURES ";	Execute/P/Q "FEvl()"	
	" Quit " +  FE_Title() ,   UnloadFEval3()
End

Function	/S	FPUL_Title()
	variable	nItem
	return  	"FPulse" + stFormatVersion()					// e.g. '300'  -> '3.00'  or  '302c'  ->  '3.02.c'
End

Function	/S	FE_Title() 
	variable	nItem
	return	"FEval" + stFormatVersion()						// e.g. '300'  -> '3.00'  or  '302c'  ->  '3.02.c'
End
 
static Function	/S	stFormatVersion()	 
// formats version string  e.g. '300'  -> '3.00'  or  '1302c'  ->  '13.02.c'
	string  	sVersion, sVersionOrg	 = ksFP3_VERSION		// e.g. '300'  or  '1302c'
	variable	nVersionNumber	= str2num( sVersionOrg )		// e.g. '300'  or  '1302'
	variable	len				= strlen( sVersionOrg )
	string  	sVersionLetter	= SelectString( len == strlen( num2str( nVersionNumber ) ) , "." + sVersionOrg[ len-1, len-1 ], "" )  
	sprintf  sVersion, " %.2lf%s %s" , nVersionNumber / 100 , sVersionLetter, SelectString( kbIS_RELEASE, "D", "" )	// D is reminder if we are still in the debug version
	return	sVersion
End


//========================================================================================================================================================
// HISTORY

static strconstant	ksfACO		= "aco"			// the one-and-only subfolder
static strconstant	ksfEVO		= "evo"			// the one-and-only subfolder
 
strconstant	ksFP3_APPNAME	= "FPulse"	  	
strconstant	ksFP3_VERSION	= "345" 			// Use 3 or 4  digits (and optionally 1 letter) . CONVENTION: Increment AFTER releasing.....
constant		kbIS_RELEASE	=  1				// Set to 1 only temporarily  in a Release version.  Is normally set to 0 during  program development to facilitate debugging.
											// For releasing execute  'PnRelease()'

//	345		2021-08-01  fixed bug reported by Peipeng. Bug occurred only for Protocols>1 and in this case for some combinations of script duration and sample interval, had nothing to do with number of DAC channels. Bug lead to scrambled/fragmented acquisition data.
//	344		2021-05-14  renamed function  FPU_Title()  to  FPUL_Title()  to avoid name conflict with FPulse5.   FPulse5 requires the name to be FPU_Title().
//	343		2021-03-10  'FPulse'  and  'FEval'  still  accessible in Main menu, but  new-style Unloading reverted to old-style.
//	342		2021-03-10  Panel  Test1401  converted to new-style (this was easy, but most other panels are beasts, so currently no attempt is made).   'FPulse'  and  'FEval'  still  accessible in Main menu, but  new-style Unloading reverted.
//	341		2021-03-09  renamed all static functions  stXXX().  No intended real code changes.  Possibly without EVAL???
//	340		2021-03-09  test to incorporate new framework: formatted panels with tabs (just for easier view of code).   'FPulse'  and  'FEval'  accessible in Main menu.  Unloading changed to new-style but is no good.

//	337		2013-01-15  made some functions static to avoid interference with FPuls5
//	336		2012-01-30  Revamped Release Process, XOPs are now handled as in all other projects  (BUT THE RELEASE procedure file   PnRelease.ipf   ist still old-style)  
//	335		2012-01-26  Revamped UFCom files
//	333		2010-03-30  (2010-03-29) Eliminated the 'Can not SetTranferArea' flaw by using 1.FIXED  and 2. SMALLER  TranferArea size .  Increased  MAXDIGOUT from 2000 to 10000.
//	332		2010-03-27  Fixed BAD ACQ BUG ('Missing Data'). Remove Statusbar when FPulse is 'Quit' .  This avoids the error occurring when referencing the non-existant wave 'wG'.
//	331		2010-02-17  Revamped Ced acquisition so that V3 and V4 can both be used at the same time (Must reload the script when switching versions)
//	330		2009-12-11  Ced Power1401Mk2  is now recognised.   Replaced all Ced files (.c, .h, .lib, .dll) by newest versions
//	329		2009-12-10  moved  misc folder in Eval from aco.misc  to evo.misc. 
//	328		2009-12-10  fixed bug in Acquis Display configuration load/save (due to additionally inserted  folder 'aco' the control names were too long)
//	327		2009-10-30  removed trial time kTTD.  There are now 2 StimDisp panels and 2 DataUtil panels (separate panels for ACOld and EVOld )
//	326		2009-10-28  Menu items 'Quit Eval3' and 'Quit FPuls3' (->deleted hook function).  Also move 'ola' and 'disp' into 'aco',  The only remaining folders are 'aco, evo, dlg, dbgprint' so now the versions 32x and 61x should be able to coexist.
//	325		2009-10-28  move 'cfsr' into 'evo', create 'evo:lb' . 
//	324		2009-10-28  renaming  eva -> evo 
//	323		2009-10-27 
//	322		2009-10-27  renaming  acq -> aco 
//	320		2009-10-22  modify for Igor6: Removed loop in action procs.  Removed trial time/birthfile (also in XOPs). Using InnoSetup5 (IgorPro folder path changed, no birth file).

//	319		060821  Movies : subtract base line
//	318		060712  Movies
//	317a		060526  No error found...........Attempted to fix error in StimWave interpolation when interpolating different sample rates and  sclX!=1 (Neither I nor Li could not reproduce error)
//	317		060515a  Keep Disp config when changing the number of protocols   060515b
//	316		060511a  Data sections panel has adjustable column widths    060511b  Added a 3. Base/peak region for OLA    060511c Fixed rsTNm/AutoScalerror  060511d Fixed  DcFit/RiseFit nvar flaw    060511e  New  Mini Help in Acquis     060511f   Append mode comments  and renaming
//	315		060414 Error in Eval handling Pon protocols  060419 Error avoiding protocols with odd number of points
//	314		060406 Peak and Peak2 may have different settings for 'average  peak over ms' 
//	313		060406 Script now recognises and outputs StimWave parameters Y-Offset  and  X-Scaling
//	312a		060221 InnoSetup now also copies FEvalHelp.txt
//	312		060220 Slopes OK
//	311		060219 'FEvalHelp.txt'  will automatically be found. Listbox Contextual menu to set 'All Mov Avg'.  Result table Contextual menu to compute 'Mean of a column.
//	310		060216 Alignment of averages (hopefully OK, no longer depending on Latencies) .  DT50 error (EvaluateCrossings) . Reduced smoothpoints for 7 to 5. Still better todo: make automatic or adjustable
//	309		060213 Alignment of averages with Latencies 0,1,2  (wrong)
//	308		060210 Convert Dat files into old style for  'StimFit' compatibily by removing the script.
//	307a		060208 InnoSetup makes 1 link to the  'UserIgor\Ced\' directory but no longer to each file (recommendation of HR, WaveMetrics)
//	306h		060206 Delayed patch: make E3E4 HW trigger work

//	306f		051109 AutoSetCursors. Rseries test pulse adjustable. User cannot proceed when  'redimension' error occurs again.  Bug fixes: Radio buttons are now OK when settings are recalled. Result selection listboxex are no longer cleared when a new file is loaded.
//	306e		051105	workaround for  'redimension'  error :   to provoke the error set  bCRASH_ON_REDIM_TEST14 = TRUE , execute 'Pntest()  and  'test14'
//	306d		051103	moving average : working but some flaws and inconsistencies
//	306c		051021	non-proportional font in the eval textbox
//	306b		051021	Computes Mean, SDBase and Event Validity
//	306a		051020	BigStep for evaluation  (distinguishing between small and capital letters). 	First really useful version.
//	305o		051020	Latency cursors and lots of improvements and bug fixes. 
//	305n		051012	Unfinished. For A. Harris. 	Error reading the same data twice fixed.  Evaluated and derived parameters now have units. FitFail results are red. Simplified Eval panel usage.
//	305m	051006 Unfinished. For Pauli.   	Reads truncated file 'dummydye0AM.dat' .    'FEvalHelp.txt'  included in the release version.
//	305l		051004 Unfinished. For A. Harris.	Units in the evaluation window textbox.  Convert evaluation results into XY wave (button 'conv tvl > XY'). Computes Capacitance and weighted tau.
//	305k		051004 Unfinished. For Pauli. 
//	305j		050921 Unfinished. Proceeded with Evaluation: Viewing  and  averaging/analysis are now separate. Analysis now works also in 'catenate' and 'stacked' mode
//	305i		050902 Unfinished. Proceeded with Evaluation: mainly result -> table -> file  and lots of related things
//	305h		050817 Unfinished. Proceeded with Evaluation: mainly result selection listbox panels  and lots of related things
//	305g		050726 Unfinished. Combined Eval and details panel  but crashes when attempting to close the EvalDetails3 panel (maybe Igor 5.04 problem?)
//	305f		050610 Unfinished. Combined Eval and details panel.  Converted   Misc-Panel  to new style.  Fixed bug concerning 2 DA chans + 2 blocks (FPStim.ipf wELine[ c ][ f.. ->  wELine[ c ][ b.. )
//	305d		050503 Unfinished. Advanced 4 dimensional panels. DebugPrintOptions  in FPulseMain rather than in FPTest. gbRunning etc. in :keep: instead of  :co:   Delete button disabled during acquisition 
//	305c		050428 Unfinished. Advanced 4 dimensional panels... 
//	305b		050413 Unfinished. Advanced 4 dimensional panels but evaluation is not yet making use of them...
//	305a		050205 Script are stored in Cfs Acquis file including comment, limit 64 lines->15kByte. Eliminated wLines -> gsCOScript instead. Moved  InitializeCfsDescriptors   into  LoadScript  
//	304f		050204 Fixed crash (TG array was 1 too short in some cases)
//	304d		041215 First try on data section listbox : display but no analysis yet
//	304c		041215 Average now writes every point (used to be for testing every 100th point)
//	304b		041215a changed default behavior: now all acquis windows are initially off. Reason: with many frames and 'Many Supimp' on  building all the acqr windows took awfully long. Better would be more specific: e.g. only Frames and Current ON...
//	304a		041213 removed bugs in OLA, made panels Gain, DispAcq and OLA remember their position
//	303a		041206 Comments stripped out of release version
//	302a		041203 Fixed heap scramble problem . Removed string handle locking in the XOPs completely (IHC2 -> IHC)
//	301a		041130	Release with InnoSetup

//	241		041005 Unfinished. Connected  MultiClamp 700B    and started  controlling the  700A and 700B from FPulse
//	240		040920 Unfinished. Split into FPulse and Eval.  Eval revisited and made to behave like Pascal StimFit. 
//	239		040801 Online analysis revisited (decay fit, multiple traces in 1 acquis window)
//	238		040707 Data filtering ,  Release/Installation/Deinstalllation routines
//	237		040429 rearranged panels, colored buttons and text fields
//	236		040420 major revision of Display Stimulus  (stack frames + cat sweeps, 1 large display trace rather than many small ones , faster )
//	235		040310 ReadCFS  speed improvement  and  OnlineAnalysis 
//	234		040310 Fourth refinement of OnlineAnalysis 
//	233		040227 Third refinement of OnlineAnalysis 
//	232		040223 Second refinement of OnlineAnalysis 
//	231		040217 First refinement of OnlineAnalysis 
//	230		040217 Fixed error drawing only the 1 frame, reactivated and adjusted OnlineAnalysis
//	229		040120 Multiple instances of same trace in acquis window, YOfs slide, Gains revamped
//	228		031215 Standard 1401 supported. Works with Igor5. ReadCfs finally handles  multiple blocks in conjunction with a truncated last protocol.
//	227		031120 removed Timer2 mode, instead Blank chunks are eliminated
//	226		031111 Avoids GetVarDesc error when there are too many script lines to be stored in script .'Apply' is much faster when there are many blocks and at the same time many frames
//	225		031104 new acquisition mode in which the 'InterBlockInterval/InterProtocolInterval'  (= 'Blank' line after 'EndFrame' ) is processed differently: the acquisition is stopped and restarted when the next stimulus is to begin.
//	224		031101 A Y Zoom factor determines the length of the Y axis in the acquisition windows, previously the length mixed up with the AxoPatch gain could be set.
//	223		031006 Hardware triggered E3E4 acquis mode, decrease CED memory, set reaction time
//	222		030918 ReadCfs reads multiple (but not yet truncated) protocols
//	221		030915 finished compressed telegraphs, improved Transfer area and Ced memory usage, SetTransferArea keeps minimum
//	220		030725 MarkPerfTestTime, compressed telegraphs, bugfix to read IgorPlsT200 data files, bugfix to read FPulse211 data with very many frames (appr.>100)
//	219		030715 eliminated delay after 'Start'
//	218		030710 file filter in ReadCfs,  button AND text input 'DataPath' directory selection, oversized  PN_SETSTR, PN_DISPSTR fields
//	217		030707 made digital output behave the same on power1401 and on 1401plus with hardware error...and removed the code again as CED fixed the power1401
//	216		030627 fixed multiple bugs in digital output for power1401 (but 1401plus will not work)
//	215		030612 fixed bugs MultiClamp, DataPath
//	214		030601..030611	'Axes and Scalebars', rescaling of data from 'IgorPlsT205'...
//	213		030513	telegraph data no longer stored or displayed, MultiClamp telegraphs introduced
//	212		030404	CfsRead  now reads  multiple blocks
//	211		030327	Errors: Cosmetics: Reread split into Apply and Save/as/copy
//	210		030326	Errors:CFSRead  SmpInt was fixed 100, IFI+IBI, Cosmetics: Short Dac and DigOut pulses are stretched for display New: zoom with double click
//	209		030313	Errors:DigOut, Telegraph. New (not yet released): Evaluation similar to Stimfit
//	208		030130	Errors:CFS-YScale.    Revamped: Panels.   New (not yet released): Automatic help


//========================================================================================================================================================
// UNLOADING THE APPLICATION

Function 	UnloadFEval3()
	EV3_RemovePanels()
 	UnloadApplication_( ksROOT_UF_,  ksfEVO, "FEvalMain" )
End

Function 	UnloadFPuls3()
	DoWindow /K $"SB_ACQUISITION"	// 2010-03-25 (ksSB_WNDNAME="SB_ACQUISITION")      Remove the Statusbar window.  If the Statusbar window remained  'LaggingTime()'  tries to call non-existent 'wG'
	FP3_RemovePanels()
 	UnloadApplication_( ksROOT_UF_,  ksfACO, "FPulseMain" )
	KillBackground					// 2010-02-08 untested, but should be helpful when switching between  FPulse versions 3 and 4 .   Must perhaps be made more specific: NOW it KILLS  ALL bkg functions in ALL applications?????
End


Function 	UnloadApplication_( sRootUf,  sSubFolder, sApplMain )
	string  	sRootUf,  sSubFolder, sApplMain
	stKillDataFoldUnconditionly( sRootUf +  sSubFolder )		// kill the folder  'root:uf:ev0'  or  'root:uf:aco'  including all variables, strings and waves (if required also kill the windows using the waves to be killed)  
	Execute/P "DELETEINCLUDE \""+ sApplMain +"\""		// Unload specific procedure files.  However, procedure windows opened by double-clicking on the file remain open, especially ALL  included files opened by double-clicking on THIS file.
	Execute/P/Q "COMPILEPROCEDURES "
End

// -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// The following code has been copied from  'DataFoldersAndGlobals.ipf'  
// By copying the code we do not have to  #include  'DataFoldersAndGlobals.ipf' , 'Constants.ipf'  (and other files) which simplifies the Debug/Release processing. 

static constant	kDF_FOLDERS	= 1,  	kDF_WAVES 	   = 2,   	kDF_VARIABLES = 4,   kDF_STRINGS 	= 8
static	 constant	kIGOR_WAVE	= 1,  	kIGOR_VARIABLE  = 2, 	kIGOR_string  	= 3, 	kIGOR_FOLDER	= 4	

static Function	stKillDataFoldUnconditionly( sFolderPath )
	string  	sFolderPath
	if ( DataFolderExists( sFolderPath ) )
		stZapAllDataInFolderTree( sFolderPath )
		KillDataFolder   $sFolderPath
		if ( V_Flag )
			printf "+++Error: CDF is '%s' .   Tried to but could not kill data folder '%s' .  Objects left: \r", GetDataFolder( 1 ), sFolderPath
			//string		sDFSave	= GetDataFolder( 1 )			// remember CDF in a string.
			print	DataFolderDir( kDF_FOLDERS |  kDF_WAVES |  kDF_VARIABLES |  kDF_STRINGS )
			//SetDataFolder sDFSave							// restore CDF from the string value
		endif
	endif
End


static Function 	stZapAllDataInFolderTree( sFolderPath )
// Deletes recursively ALL variables, strings and waves from  'sFolderPath'  and its subfolders. 
// Deletes  waves even if they are used in a graph or table by first killing  tables and graphs
// Todo/ToCheck: text waves, panels,   waves used in XOPs,  locked waves ?
	string 	sFolderPath

	if ( DataFolderExists( sFolderPath ) )
		string 	savDF	= GetDataFolder(1)
	
		SetDataFolder sFolderPath							// e.g. 'stim'
		string  	curDF	= GetDataFolder(1)				// e.g. 'root:uf:fpu:stim'
	
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
			string  	lstWins	= stAllWindowsContainingWave( sWave )
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
			 printf "+++Error : stZapAllDataInFolderTree 3    \tCDF is '%s' . \tsFolderPath: '%s' : %4d waves could not be killed after deletion of windows: '%s...'  \r", curDF, sFolderPath, nWaves, lstWaves[0,200]
		endif
	
		variable 	i
		variable 	nDataFolderCnt = CountObjects( ":" , kIGOR_FOLDER )			// kill all subfolders (4 is data folder)
		for ( i = 0; i < nDataFolderCnt; i += 1 )
			string 	sNextPath = GetIndexedObjName( ":" , kIGOR_FOLDER , i )
			stZapAllDataInFolderTree( sNextPath )
		endfor
		SetDataFolder savDF
	endif
End

static Function	/S stAllWindowsContainingWave( sWaveNm )
// Returns list of windows containing the wave 'sWaveNm'  e.g. "root:uf:MyWave" .  
// All graphs, tables and  layouts are searched.  Text waves are ignored.
	string  	sWaveNm
	return	stMatchWinsContainingWave( sWaveNm, "*" , ";" , "WIN:7" )	// 1+2+4
End

static Function	/S stMatchWinsContainingWave( sWaveNm, matchStr, separatorStr, optionsStr )
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
	stFPRemovePanels( ksfACO )
End

Function		EV3_RemovePanels()
	stFPRemovePanels( ksfEVO )
End


Function		PnLstPansNbsAdd( sFo, sPanel )
	string  	sFo, sPanel
	string  	lstPanels	= stFPLstPanels( sFo )
	if ( WhichListItem( sPanel, lstPanels ) == -1 )
		stFPLstPanelsSet( sFo, AddListItem( sPanel, lstPanels ) )				// add this panel to global list so that we can remove in on Cleanup or Exit
	endif
End


static Function	stFPRemovePanels( sFo )
	string  	sFo
	variable pa, paCnt	= ItemsInList( stFPLstPanels( sFo ) )
	for ( pa = 0; pa < paCnt; pa += 1 )
		string     sPanel	= StringFromList( pa, stFPLstPanels( sFo ) )	
		if ( WinType( sPanel ) == 7 )		// 7 is panel 
			KillWindow	$sPanel
		endif
	endfor
End


static Function	/S	stFPLstPanels( sFo ) 
	string  	sFo
	svar  /Z	lst	= 	$ksROOT_UF_ + sFo + ":"  + "lstPanels"
	if ( ! svar_exists( lst ) )																// OK on first call
		string  /G		$ksROOT_UF_ + sFo + ":"  + "lstPanels"	= ""
		svar  /Z	lst =	$ksROOT_UF_ + sFo + ":"  + "lstPanels"
		if ( ! svar_exists( lst ) )		// OK now only if folders do not exist because user selected 'Quit' before starting the application....
			return	""		// todo_c: better solution is to gray the 'Quit' menu item when not allowed			
		endif
	endif
	return	lst
End

static Function	stFPLstPanelsSet( sFo, lst )
	string  	sFo, lst
	string  /G			$ksROOT_UF_ + sFo + ":"  + "lstPanels"	= lst
	// printf "\tstFPLstPanelsSet \t'%s'   '%s' \r", sFo,  lst
End	



