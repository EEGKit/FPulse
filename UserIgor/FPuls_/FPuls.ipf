// FPuls.ipf  :	The new version branch  V4xx
//			Add a direct entry  in  IGORs  'Analysis'  menu  and  set  the  FPuls version number. 
// 			There must be a shortcut from this file into ..\ Programme \ Wavemetrics \ Igor Pro Folder \ Igor Procedures 

#pragma rtGlobals=2		// Use modern global access method.  

//Menu "Analysis", dynamic
Menu "FPuls", dynamic
	FP_AnalysisMenuItem(), /Q, Execute/P/Q/Z "INSERTINCLUDE \"UF_PulsMain\""; 	Execute/P/Q "COMPILEPROCEDURES ";	Execute/P/Q "FPuls()"	
	"Quit FPuls "+ksFP_VERSION[0,0] + "." + ksFP_VERSION[1,inf],	 	UnloadFPuls()		//
End


Function	/S	FP_AnalysisMenuItem() 
	string  	sVersion		= FP_FormatVersion()									// e.g. '300'  -> '3.00 D'  or  '302c'  ->  '3.02.c'
	 return	ksFP_APP_NAME + sVersion										// menu item is always enabled  
End


Function	/S	FP_FormatVersion()	  
	string  	sVersion			= ksFP_VERSION				// formats version string  e.g. '300'  -> '3.00 D'  or  '1302c'  ->  '13.02.c'
	variable	len				= strlen( sVersion )			
	variable	nVersionNumber	= str2num( sVersion )				// e.g. '300'  or  '1302c'  ->   '300'  or  '1302'     truncate any letter
	string  	sVersionLetter		= SelectString( len == strlen( num2str( nVersionNumber ) ) , "." + sVersion[ len-1, len-1 ], "" )  
	sprintf  	sVersion, " %.2lf%s %s" , nVersionNumber / 100 , sVersionLetter, SelectString( FP_IsRelease(), "D", "" )	// D is reminder if we are still in the debug version
	return	sVersion										// e.g. '3.00'  or  '13.02.c'  
End

Function		FP_IsRelease()
	// Check if THIS functions stems from directory 'FPuls' (=Release). Any other dir name e.g. 'FPuls_' is considered to be the Debug directory.   !!! Assumption : The release dir IS the application name,
// 2009-12-15 ???   fragile code, what if user changes 'FPuls' ???
	variable	bIsRelease	= strsearch( FunctionPath( "FP_IsRelease"), ksFP_APP_NAME + ":" + ksFP_APP_NAME + ".ipf" , 0 )  > 0 	// Only  'X:yz:FPuls:FPuls.ipf' is a Release 
	// printf "\t\tFP_IsRelease() \tFunctionPath(\t'FP_IsRelease' \t): '%s'  \t-> Is Release : %d \r", FunctionPath( "FP_IsRelease"), bIsRelease
	return 	bIsRelease 	// Only  'X:yz:FPuls:FPuls.ipf' is a Release 
End


static strconstant	ksACQ			= "acq"			// the subfolder for the  'acquisition'  variables. Do not change as action proc names (and globals in panels) depend on it.

strconstant		ksfACQVARS			= "acqvars"		// Subfolder for internal variables, waves and strings  introduced  to hide and protect them from the user....
strconstant		ksfACQVARS_			= "acqvars:"		// ....Located in the  'root:uf:acq' subfolder  parallel  to the  main panel subfolder 'pul'  and parallel to any waves which the user might access.


strconstant		ksFP_APP_NAME		= "FPuls"		 
strconstant		ksFP_VERSION		=  "404"			// Use 3 or 4  digits (and optionally 1 letter) . OTHER THAN THIS DO NOT CHANGE THIS LINE !




//strconstant		ksFP_VERSION		=  "404"			// 2010-02-02...2010-02-12  2010-02-03 catch the No-Amp error.  Digout and Nostore periods finally OK for Eliminate_Blanks=2.  
//strconstant		ksFP_VERSION		=  "403"			// 2010-01-10...2010-02-01  improved stimulus display, fixed digout tming error, NoStore periods can now have a Dac output value

//strconstant		ksFP_VERSION		=  "402"			// 2010-01-26	Digout and Nostore periods OK (only) for Eliminate_Blanks=2.  Still missing: split axis  and   Dac value always 0 (=wrong) during Nostore perionds for Eliminate_Blanks=2  (for EB=1, which we don't want this would be OK)
//strconstant		ksFP_VERSION		=  "402"			// 2010-01-04	Ced handle stored in Igor, no longer in XOP (2 handles stored in V3  Xop and in V4 Xop have prevented to acquire in V3 and in V4 in parallel )
//strconstant		ksFP_VERSION		=  "401"			// 2009-12-14...12-31  removed loading of old-style scripts (must be incorporated again at least in FEval using as many new-style functions as possible)
//strconstant		ksFP_VERSION		=  "400a"			// 2009-10-29  excluded kill events form DispStimHook function   and from 3 ListboxHook function.  Renamed UF_AcqTest4   _UF_AcqTest4  so it is excluded from the release version.
//strconstant		ksFP_VERSION		=  "400"			// 2009-10-29  renamed FPulse612  to  FPuls400  

//strconstant		ksVERSION			=  "612"			// 2009-10-28...moved 'disp' and 'cfsw' into 'root:uf:acq'
'//strconstant		ksVERSION			=  "611"			// 2009-04-23...
//strconstant		ksVERSION			=  "610"			// 2009-03-27...2009-04-23  Quit Application removes most 'Acq' folders, panels and graphs ( folders misc, script  and  Disp Stim Acq panel still remain)
//strconstant		ksVERSION			=  "609"			// 2009-03-17...2009-03-27 acquisition and pon testing
//strconstant		ksVERSION			=  "608"			// 2009-02-04...no changes
//strconstant		ksVERSION			=  "607"			// 2009-02-03  finished 'Ini_Acq'
//strconstant		ksVERSION			=  "606"			// 2008-07-01  switched to new computer, Win2000 to XP, Igor from D to C, UserIgor from C to D.   20090202 Disabled 'FPPrefs' , enables 'Ini_Acq'
//strconstant		ksVERSION			=  "605"			// 2008-06-26  acquisition display: intermediary, revamp sweeps and pon    (todo killing dia windows mixes up things )
//strconstant		ksVERSION			=  "604"			// 2008-06-24  acquisition display: intermediary
//strconstant		ksVERSION			=  "603"			// 2008-06-21  acquisition display: intermediary
//strconstant		ksVERSION			=  "602"			// 2008-06-21  acquisition display: curves now contain nio and cio
//strconstant		ksVERSION			=  "601"			// 2008-06-12  start on new acquisition display
//strconstant		ksVERSION			=  "600"			// 2007-0808  start on wish list items from 070506.  New: Laps, blanks allowed, anywhere in script, faster loading.  Unfinished is PoN, acquisition display , and more...
//strconstant		ksVERSION			=  "454"			// 2007-0319 remember position of non-listbox panel  070320 remember position of listbox-panels  
//strconstant		ksVERSION			=  "453"			// 2007-0309  Reload last scripts, Display/Hide notebook improved but it now requires Igor6, fixed minor bugs in Panel (handled AboutToBeKilled event)
//strconstant		ksVERSION			=  "452"			// 2007-0309  search and fixed error mwas only in V3xx
//strconstant		ksVERSION			=  "405"			// 2007-0123  seems to work, now try to install V326.....
//strconstant		ksVERSION			=  "404c"			// 2007-0123  debugged releasing
//strconstant		ksVERSION			=  "404b"			// 2007-0123  debugged releasing
//strconstant		ksVERSION			=  "404a"			// 2007-0122  errors removing  Test / Wrapper / Project / ProjectInstall / ProjectRelease IPFS from Release version
//strconstant		ksVERSION			=  "404"			// 2007-0122  Removed  Test / Wrapper / Project / ProjectInstall / ProjectRelease IPFS from Release version
//strconstant		ksVERSION			=  "403"			// 2007-0122  New Release / Installation / Deinstallation / Backup routines
//strconstant		ksVERSION			=  "402"			// 2007-0119  Minor improvements: Renaming of backup=Archive  directories and files
//strconstant		ksVERSION			=  "401"			// 2006-1101  Tidied up functions and files to allow multiple Projects / SecuCheck etc.
//strconstant		ksVERSION			=  "400m"			// 2006-0712  Movies
//strconstant		ksVERSION			=  "400n"			// 2006-0703 Unfinished : Acq windows UF_AcqDisp.ipf streamlined
//strconstant		ksVERSION			=  "400m"			// 2006-0609-060622 Unfinished : Acq windows UF_AcqDisp.ipf streamlined
//strconstant		ksVERSION			=  "400l"			// 2006-0601 Unfinished : Acq windows UF_AcqDisp.ipf streamlined
//strconstant		ksVERSION			=  "400k"			// 2006-0531 Unfinished : Acq windows
//strconstant		ksVERSION			=  "400i"			// 2006-0414 Unfinished: Error in Eval handling Pon protocols  060419 Error avoiding protocols with odd number of points   060505 colored buttons
//strconstant		ksVERSION			=  "400h"			// 2006-0405 Combination of EVAL + ACQ  pushed further  (still unfinished)
//strconstant		ksVERSION			=  "400g"			// 2006-0404 Combination of EVAL + ACQ  pushed further  (still unfinished)
//strconstant		ksVERSION			=  "400f"			// 2006-0330 Combination of EVAL + ACQ  pushed further  (still unfinished)
//strconstant		ksVERSION			=  "400e"			// 2006-0329 Combination of EVAL + ACQ  pushed further  (still unfinished)
//strconstant		ksVERSION			=  "400d"			// 2006-0201 Castrated program (no Ced...) to investigate fragmentation. Todo: Check success of 'make' even for small waves (though failure there is very improbable) . New: UFCom_UtilContiguousMemory and UFCom_UtilPhysicalMemory
//strconstant		ksVERSION			=  "400c"			// 2006-0124 probably found cause for rare error during script load: memory fragmentation lead to 'out of memory error' but user could continue (and/or sometimes the error was not displayed by Igor) . No fix possible (see IML LH050203) but program now exits.  New: UFCom_UtilContiguousMemory and UFCom_UtilPhysicalMemory
//strconstant		ksVERSION			=  "400buggy"		// 2006-0116 for  Yeka because E3E4 works  ---- Unfinished: OnlineAnalysis
//strconstant		ksVERSION			=  "400b"			// 2005-1208 Unfinished: OnlineAnalysis converted to new style
//strconstant		ksVERSION			=  "400a"			// 2005-1208 Unfinished: FPuls Main Panel  converted to new style, Scripts without ADC allowed

// Late Patches as version 400 exists since 051208
//strconstant		ksVERSION			=  "317"			// 2006-0515a  Keep Disp config when changing the number of protocols  
//strconstant		ksVERSION			=  "316"			// 2006-0511a  Data sections panel has adjustable column widths    060511b  Added a 3. Base/peak region for OLA    060511c Fixed rsTNm/AutoScalerror  060511d Fixed  DcFit/RiseFit nvar flaw    060511e  New  Mini Help in Acq     060511f   Append mode comments  and renaming
//strconstant		ksVERSION			=  "315"			// 2006-0414 Error in Eval handling Pon protocols  060419 Error avoiding protocols with odd number of points
//strconstant		ksVERSION			=  "314"			// 2006-0406 Ola: Peak2 has its own value for  'average over ms' 
//strconstant		ksVERSION			=  "313"			// 2006-0406 Script now recognises and outputs StimWave parameters Y-Offset  and  X-Scaling
//strconstant		ksVERSION			=  "312a"			// 2006-0221 InnoSetup now also copies FEvalHelp.txt
//strconstant		ksVERSION			=  "312"			// 2006-0220 Slopes OK
//strconstant		ksVERSION			=  "311"			// 2006-0219 'FEvalHelp.txt'  will automatically be found. Listbox Contextual menu to set 'All Mov Avg'.  Result table Contextual menu to compute 'Mean of a column.
//strconstant		ksVERSION			=  "310"			// 2006-0216 Alignment of averages (hopefully OK, no longer depending on Latencies) .  DT50 error (EvaluateCrossings) . Reduced smoothpoints for 7 to 5. Still better todo: make automatic or adjustable
//strconstant		ksVERSION			=  "309"			// 2006-0213 Alignment of averages with Latencies 0,1,2  (wrong)
//strconstant		ksVERSION			=  "308"			// 2006-0210 Convert Dat files into old style for  'StimFit' compatibily by removing the script.
//strconstant		ksVERSION			=  "307a"			// 2006-0208 InnoSetup makes 1 link to the  'UserIgor\Ced\' directory but no longer to each file (recommendation of HR, WaveMetrics)
//strconstant		ksVERSION			=  "306h"			// 2006-0206 Delayed patch: make E3E4 HW trigger work


//strconstant		ksVERSION			=  "306i"			// 2005-1124 Unfinished: DebugPrintPanel  converted to new style
//strconstant		ksVERSION			=  "306h"			// 2005-1123 Unfinished: New help system
//strconstant		ksVERSION			=  "306g"			// 2005-1114 Different tables and files for  original  and  MovingAverage  data
//strconstant		ksVERSION			=  "306f"			// 2005-1109 AutoSetCursors. Rseries test pulse adjustable. User cannot proceed when  'redimension' error occurs again.  Bug fixes: Radio buttons are now OK when settings are recalled. Result selection listboxex are no longer cleared when a new file is loaded.
//strconstant		ksVERSION			=  "306e"			// 2005-1105	workaround for  'redimension'  error :   to provoke the error set  bCRASH_ON_REDIM_TEST14 = TRUE , execute 'Pntest()  and  'test14'
//strconstant		ksVERSION			=  "306d"			// 2005-1103	moving average : working but some flaws and inconsistencies
//strconstant		ksVERSION			=  "306c"			// 2005-1021	non-proportional font in the eva textbox
//strconstant		ksVERSION			=  "306b"			// 2005-1021	Computes Mean, SDBase and Event Validity
//strconstant		ksVERSION			=  "306a"			// 2005-1020	BigStep for evaluation  (distinguishing between small and capital letters). 	First really useful version.
//strconstant		ksVERSION			=  "305o"			// 2005-1020	Latency cursors and lots of improvements and bug fixes. 
//strconstant		ksVERSION			=  "305n"			// 2005-1012	Unfinished. For A. Harris. 	Error reading the same data twice fixed.  Evaluated and derived parameters now have units. FitFail results are red. Simplified Eval panel usage.
//strconstant		ksVERSION			=  "305m"			// 2005-1006 Unfinished. For Pauli.   	Reads truncated file 'dummydye0AM.dat' .    'FEvalHelp.txt'  included in the release version.
//strconstant		ksVERSION			=  "305l"			// 2005-1004 Unfinished. For A. Harris.	Units in the evaluation window textbox.  Convert evaluation results into XY wave (button 'conv tvl > XY'). Computes Capacitance and weighted tau.
//strconstant		ksVERSION			=  "305k"			// 2005-1004 Unfinished. For Pauli. 
//strconstant		ksVERSION			=  "305j"			// 2005-0921 Unfinished. Proceeded with Evaluation: Viewing  and  averaging/analysis are now separate. Analysis now works also in 'catenate' and 'stacked' mode
//strconstant		ksVERSION			=  "305i"			// 2005-0902 Unfinished. Proceeded with Evaluation: mainly result -> table -> file  and lots of related things
//strconstant		ksVERSION			=  "305h"			// 2005-0817 Unfinished. Proceeded with Evaluation: mainly result selection listbox panels  and lots of related things
//strconstant		ksVERSION			=  "305g"			// 2005-0726 Unfinished. Combined Eval and details panel  but crashes when attempting to close the EvalDetails3 panel (maybe Igor 5.04 problem?)
//strconstant		ksVERSION			=  "305f"			// 2005-0610 Unfinished. Combined Eval and details panel.  Converted   Misc-Panel  to new style.  Fixed bug concerning 2 DA chans + 2 blocks (UF_Stim.ipf wELine[ c ][ f.. ->  wELine[ c ][ b.. )
//strconstant		ksVERSION			=  "305d"			// 2005-0503 Unfinished. Advanced 4 dimensional panels. DebugPrintOptions  in UF_PulsMain rather than in UF_Test. gbRunning etc. in :Keep: instead of  :co:   Delete button disabled during acquisition 
//strconstant		ksVERSION			=  "305c"			// 2005-0428 Unfinished. Advanced 4 dimensional panels... 
//strconstant		ksVERSION			=  "305b"			// 2005-0413 Unfinished. Advanced 4 dimensional panels but evaluation is not yet making use of them...
//strconstant		ksVERSION			=  "305a"			// 2005-0205 Script are stored in Cfs Acq file including comment, limit 64 lines->15kByte. Eliminated wLines -> gsCOScript instead. Moved InitializeCfsDescriptors  into LoadProcessScript 
//strconstant		ksVERSION			=  "304f"			// 2005-0204 Fixed crash (TG array was 1 too short in some cases)
//strconstant		ksVERSION			=  "304d"			// 2004-1215 First try on data section listbox : display but no analysis yet
//strconstant		ksVERSION			=  "304c"			// 2004-1215 Average now writes every point (used to be for testing every 100th point)
//strconstant		ksVERSION			=  "304b"			// 2004-1215a changed default behavior: now all acq windows are initially off. Reason: with many frames and 'Many Supimp' on  building all the acqr windows took awfully long. Better would be more specific: e.g. only Frames and Current ON...
//strconstant		ksVERSION			=  "304a"			// 2004-1213 removed bugs in OLA, made panels Gain, DispAcq and OLA remember their position
//strconstant		ksVERSION			=  "303a"			// 2004-1206 Comments stripped out of release version
//strconstant		ksVERSION			=  "302a"			// 2004-1203 Fixed heap scramble problem . Removed string handle locking in the XOPs completely (IHC2 -> IHC)
//strconstant		ksVERSION			=  "301a"			// 2004-1130	Release with InnoSetup

//constant			knVERSION			=  241			// 2004-1005 Unfinished. Connected  MultiClamp 700B    and started  controlling the  700A and 700B from FPuls
//constant			knVERSION			=  240			// 2004-0920 Unfinished. Split into FPuls and Eval.  Eval revisited and made to behave like Pascal StimFit. 
//constant			knVERSION			=  239			// 2004-0801 Online analysis revisited (decay fit, multiple traces in 1 acq window)
//constant			knVERSION			=  238			// 2004-0707 Data filtering ,  Release/Installation/Deinstalllation routines
//constant			knVERSION			=  237			// 2004-0429 rearranged panels, colored buttons and text fields
//constant			knVERSION			=  236			// 2004-0420 major revision of Display Stimulus  (stack frames + cat sweeps, 1 large display trace rather than many small ones , faster )
//constant			knVERSION			=  235			// 2004-0310 ReadCFS  speed improvement  and  OnlineAnalysis 
//constant			knVERSION			=  234			// 2004-0310 Fourth refinement of OnlineAnalysis 
//constant			knVERSION			=  233			// 2004-0227 Third refinement of OnlineAnalysis 
//constant			knVERSION			=  232			// 2004-0223 Second refinement of OnlineAnalysis 
//constant			knVERSION			=  231			// 2004-0217 First refinement of OnlineAnalysis 
//constant			knVERSION			=  230			// 2004-0217 Fixed error drawing only the 1 frame, reactivated and adjusted OnlineAnalysis
//constant			knVERSION			=  229			// 2004-0120 Multiple instances of same trace in acq window, YOfs slide, Gains revamped
//constant			knVERSION			=  228			// 2003-1215 Standard 1401 supported. Works with Igor5. ReadCfs finally handles  multiple blocks in conjunction with a truncated last protocol.
//constant			knVERSION			=  227			// 2003-1120 removed Timer2 mode, instead Blank chunks are eliminated
//constant			knVERSION			=  226			// 2003-1111 Avoids GetVarDesc error when there are too many script lines to be stored in script .'Apply' is much faster when there are many blocks and at the same time many frames
//constant			knVERSION			=  225			// 2003-1104 new acquisition mode in which the 'InterBlockInterval/InterProtocolInterval'  (= 'Blank' line after 'EndFrame' ) is processed differently: the acquisition is stopped and restarted when the next stimulus is to begin.
//constant			knVERSION			=  224			// 2003-1101 A Y Zoom factor determines the length of the Y axis in the acquisition windows, previously the length mixed up with the AxoPatch gain could be set.
//constant			knVERSION			=  223			// 2003-1006 Hardware triggered E3E4 acq mode, decrease CED memory, set reaction time
//constant			knVERSION			=  222			// 2003-0918 ReadCfs reads multiple (but not yet truncated) protocols
//constant			knVERSION			=  221			// 2003-0915 finished compressed telegraphs, improved Transfer area and Ced memory usage, SetTransferArea keeps minimum
//constant			knVERSION			=  220			// 2003-0725 MarkPerfTestTime, compressed telegraphs, bugfix to read IgorPlsT200 data files, bugfix to read FPulse211 data with very many frames (appr.>100)
//constant			knVERSION			=  219			// 2003-0715 eliminated delay after 'Start'
//constant			knVERSION			=  218			// 2003-0710 file filter in ReadCfs,  button AND text input 'DataPath' directory selection, oversized  panel fields
//constant			knVERSION			=  217			// 2003-0707 made digital output behave the same on power1401 and on 1401plus with hardware error...and removed the code again as CED fixed the power1401
//constant			knVERSION			=  216			// 2003-0627 fixed multiple bugs in digital output for power1401 (but 1401plus will not work)
//constant			knVERSION			=  215			// 2003-0612 fixed bugs MultiClamp, DataPath
//constant			knVERSION			=  214			// 2003-0601 ... 2003-06-11	'Axes and Scalebars', rescaling of data from 'IgorPlsT205'...
//constant			knVERSION			=  213			// 2003-0513	telegraph data no longer stored or displayed, MultiClamp telegraphs introduced
//constant			knVERSION			=  212			// 2003-0404	CfsRead  now reads  multiple blocks
//constant			knVERSION			=  211			// 2003-0327	Errors: Cosmetics: Reread split into Apply and Save/as/copy
//constant			knVERSION			=  210			// 2003-0326	Errors:CFSRead  SmpInt was fixed 100, IFI+IBI, Cosmetics: Short Dac and DigOut pulses are stretched for display New: zoom with double click
//constant			knVERSION			=  209			// 2003-0313	Errors:DigOut, Telegraph. New (not yet released): Evaluation similar to Stimfit
//constant			knVERSION			=  208			// 2003-0130	Errors:CFS-YScale.    Revamped: Panels.   New (not yet released): Automatic help


//========================================================================================================================================================
// UNLOADING THE APPLICATION

static strconstant UFCom_ksROOT_UF_	= "root:uf:" 

Function 	UnloadFPuls()
 	UnloadApplication_FPuls( UFCom_ksROOT_UF_,  ksACQ, "UF_PulsMain" )
End


Function 	UnloadApplication_FPuls( sRootUf,  sSubFolder, sApplMain )
	string  	sRootUf,  sSubFolder, sApplMain

	RemovePanels()
	UF_KillDataFoldUnconditionly( sRootUf +  sSubFolder )		// kill the folder  'root:uf:acq'  including all variables, strings and waves (if required also kill the windows using the waves to be killed)  

//	if ( WinType( sSubFolder ) == UFCom_WT_PANEL )		// 7 is panel 
//		KillWindow	$sSubFolder
//	endif
//	KillWaves /Z	$sRootUf +  sSubFolder				// kill the main panels text _wave_ 'secu'  which is located in 'root:uf'  (and not like all other stuff in the subfolder  'root:uf:secu')

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
			 printf "\t\tUF_ZapAllDataInFolderTree 1   \tCDF is '%s' . \tsFolderPath: '%s' : %4d waves could not be killed because of open windows: '%s...'  \r", curDF, sFolderPath, nWaves, lstWaves[0,200]
		endif
		for ( wv = 0; wv < nWaves; wv += 1 )
			//string  	sWave	= RemoveEnding( sFolderPath, ":" ) + ":" 	+ StringFromList( wv, lstWaves )
			string  	sWave	= curDF 							+ StringFromList( wv, lstWaves )
			string  	lstWins	= UF_AllWindowsContainingWave( sWave )
			variable	wnd, nWins	= ItemsInList( lstWins )
			for ( wnd = 0; wnd < nWins; wnd += 1 )
				KillWindow $StringFromList( wnd, lstWins )				// kill the window which contains 'sWave'
			endfor
		endfor
		KillWaves		/A/Z										// now it should be possible to also kill the remaining waves 
		lstWaves		= WaveList( "*" , ";" , "" ) 						// these waves could not be killed as they are in use
		if ( ItemsInList( lstWaves ) )
			 printf "+++Error : UF_ZapAllDataInFolderTree  2    \tCDF is '%s' . \tsFolderPath: '%s' : %4d waves could not be killed after deletion of windows: '%s...'  \r", curDF, sFolderPath, nWaves, lstWaves[0,200]
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
//  THE  LIST  OF  ALL  PANELS  CONSTRUCTED  IN  FPULS  (is required when FPuls is to be removed from Igor)

static Function		RemovePanels()
// Will delete all panel windows belonging to this application.  The  panel window names are retrieved from global list, to which each panel must add its name upon creation
// Another approch (not taken): let the name of each panel start with  'Fp' or 'eva'  or 'md'  .  This would eliminate the need for a global list of panel names.  Problem:  Control names get too long (31 chars including folder names).
 	string  	lstPanels	= FP_LstPanels()	
	variable pa, paCnt	= ItemsInList( lstPanels )
	for ( pa = 0; pa < paCnt; pa += 1 )
		string     sPanel	= StringFromList( pa, lstPanels )
		if ( WinType( sPanel ) ) //== 7 )		// 7 is panel 
			KillWindow	$sPanel
		endif
	endfor
End

static Function	/S	FP_LstPanels() 
// Is static but must be identical to  ' UFCom_LstPanels( ksACQ, ksfACQVARS )'  which can unfortunately not be called here as  'UFCom_xxx()'  functions are not accessible here.
	svar  /Z	lst	= 	$UFCom_ksROOT_UF_ + ksACQ + ":"  + ksfACQVARS + ":" + "lstPanels"
	if ( ! svar_exists( lst ) )																// OK on first call
		string  /G		$UFCom_ksROOT_UF_ + ksACQ + ":"  + ksfACQVARS + ":" + "lstPanels"	= ""
		svar  /Z	lst =	$UFCom_ksROOT_UF_ + ksACQ + ":"  + ksfACQVARS + ":" + "lstPanels"
		if ( ! svar_exists( lst ) )		// OK now only if folders do not exist because user selected 'Quit' before starting the application....
			return	""		// todo_c: better solution is to gray the 'Quit' menu item when not allowed			
		endif
	endif
	return	lst
End


