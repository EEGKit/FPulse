// FPTest.IPF
// 

#pragma  rtGlobals 	= 1					// Use modern global access method. 	Do not use a tab after #pragma. Doing so will give compilation error in Igor 4.
#pragma  IgorVersion = 5.0					// prevents the attempt to run this procedure under Igor4 or lower. Do not use a tab after #pragma. Doing so will make the version check ineffective in Igor 4.
#pragma  ModuleName= FPTestProc


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//   DIALOG  	:   TEST  PANEL
//
//   NOTE 	:   Test and debug functions can only be  accessed by developer and  power user  by entering  'PnTest()'   in the command line

Function		PnTest()
	string  	sFolder		= ksCOM
	string  	sPnOptions	= ":dlg:tPnTestDebug" 
	InitPanelTest( sFolder, sPnOptions )
	ConstructOrDisplayPanel(  "PnTestDebug", "Test + Debug" , sFolder, sPnOptions,  98, 99 )
End

Function		InitPanelTest( sFolder, sPnOptions )
	string  	sFolder, sPnOptions
	string		sPanelWvNm = 	  "root:uf:" + sFolder + sPnOptions
	variable	n = -1, nItems = 50		
	make /O /T /N=(nItems)	$sPanelWvNm
	wave  /T	tPn		= 	$sPanelWvNm
// 050530
//	n += 1;	tPn[ n ] =	"PN_BUTTON;	buDebugPrintOptions			;Print options (Debug)"
	n += 1;	tPn[ n ] =	"PN_BUTTON;	buDispTimeForReadScript		;Measure time needed for 'Apply'"
	n += 1;	tPn[ n ] =	"PN_BUTTON;	buDispTimeForReadCfs		;Measure time needed for 'ReadCfs'"
	n += 1;	tPn[ n ] =	"PN_CHKBOX;	root:uf:ola:gOLADoFitOrStartVals;Do OLA fit (or display only Start vals)"		// Flaw: folder  'ola'  is only known in  Acq  , not in  Eval
	n += 1;	tPn[ n ] =	"PN_BUTTON;	buShowSweepTimes			;Show sweep times"
	n += 1;	tPn[ n ] =	"PN_BUTTON;	buStopBackgroundTask		;Stop background task"
	n += 1;	tPn[ n ] =	"PN_SEPAR"

	n += 1;	tPn[ n ] =	"PN_BUTTON;	buTest1					;Test1 Read WA                  "
	n += 1;	tPn[ n ] =	"PN_BUTTON;	buTest2					;Test2  Trace access for user"
	n += 1;	tPn[ n ] =	"PN_BUTTON;	buTest3					;Test3   Waves in Folders"
	n += 1;	tPn[ n ] =	"PN_BUTTON;	buTest4					;Test4    Igors numbers    "
	n += 1;	tPn[ n ] =	"PN_BUTTON;	buTest5					;Test5  AppendToGraph "
	n += 1;	tPn[ n ] =	"PN_BUTTON;	buTest6					;Test6  DisplayHelpTopic"
	n += 1;	tPn[ n ] =	"PN_BUTTON;	buTest7					;Test7  SetPoints Once "
	n += 1;	tPn[ n ] =	"PN_BUTTON;	buTest8					;Test8   SetPoints Cont "
	n += 1;	tPn[ n ] =	"PN_BUTTON;	buTest9					;Test9 SetPoints Cont + neighbours"
	n += 1;	tPn[ n ] =	"PN_BUTTON;	buTest10					;Test10      Primes"
	n += 1;	tPn[ n ] =	"PN_BUTTON;	buTest11					;Test11 ReplaceListItem"
	n += 1;	tPn[ n ] =	"PN_BUTTON;	buTest12					;Test12 Heap scramble + TransferArea"
	n += 1;	tPn[ n ] =	"PN_BUTTON;	buTest13					;Test13   Ced U14Ld"
	n += 1;	tPn[ n ] =	"PN_BUTTON;	buTest14					;Test14  bCRASH_ON_REDIM - AutoLoadScripts"	// 051105
	n += 1;	tPn[ n ] =	"PN_BUTTON;	buTest15					;Test15 SetVariable + PopupMenu Format"
	n += 1;	tPn[ n ] =	"PN_BUTTON;	buTest16					;Test16 Try-Catch-EndTry: foo(0..6)"
	n += 1;	tPn[ n ] =	"PN_BUTTON;	buTest17					;Test17    Fonts "
	n += 1;	tPn[ n ] =	"PN_BUTTON;	buTest18					;Test18   Setk ksFONT , kFONTSIZE"
	n += 1;	tPn[ n ] =	"PN_BUTTON;	buTest19					;Test19   Construct sin wave"
	n += 1;	tPn[ n ] =	"PN_BUTTON;	buTest20					;Test20  Construct sine sweep for filter test"
	n += 1;	tPn[ n ] =	"PN_BUTTON;	buTest21					;Test21  pd : pad/truncate"
	n += 1;	tPn[ n ] =	"PN_BUTTON;	buTest22					;Test22  unused"
	n += 1;	tPn[ n ] =	"PN_BUTTON;	buTest23					;Test23  unused"
	n += 1;	tPn[ n ] =	"PN_BUTTON;	buTest24					;Test24  unused"

	n += 1;	tPn[ n ] =	"PN_SEPAR"
	// Sample for PN_BUTCOL		( looks like a button with 2 states but is actually used like a CheckBox with programmed titles and colors )
	variable	/G  root:uf:com:gBUTCOL = 0
	n += 1;	tPn[ n ] =	"PN_BUTCOL;	root:uf:com:gBUTCOL 		; BUTCOLstate0~BUTCOLstate1;  ;  ;  15000,55000,65535 ~ 60000,0,65000 ;    " 
	n += 1;	tPn[ n ] =	"PN_BUTTON;	buPanelPictureTest	;PanelPictTest;	| PN_BUTTON;	buCustomControlTest	;Customcontrol;	"
	// Sample for PN_DICOLTXT
	variable	/G  root:uf:com:gDICOLTXT = 0
	n += 1;	tPn[ n ] =	"PN_BUTTON;	bu_DICOLTXT_Test	;COLTest + cc; 	| PN_DICOLTXT;  root:uf:com:gDICOLTXT ; wait0~acq1~trig2~run3;  ;  ;  35000,35000,65535 ~ 60000,0,65000 ~ 60000,60000,0 ~ 0,60000,0;    " //  No Oversize : no trailing  | 
	//n += 1;	tPn[ n ] =	"PN_BUTTON;	bu_DICOLTXT_Test 	;COLTest + cc;	| PN_DICOLTXT;  root:uf:com:gDICOLTXT ; wait0~acq1~trig2~run3;  ;1;  35000,35000,65535 ~ 60000,0,65000 ~ 60000,60000,0 ~ 0,60000,0;   | " //  'OverSize' is > 0 reqires trailing  | 
	redimension  /N = (n+1)	tPn	
End

// 050530
//Function		buDebugPrintOptions( ctrlName ) : ButtonControl
//	string 		ctrlName		
//	DebugPrintOptions()
//End

Function		buDispTimeForReadScript( ctrlName ) : ButtonControl
	string 	ctrlName
	string 	sNotebookPath	  =  "C:\\UserIgor\\Ced\\TimeInReadScript"
	string 	sNotebookName = "TimeSpent1"						// this notebook must be written by extracting  the time measuring breakpoints from the code (=MarkPerfTestTime)
	printf "Display the time spent in 'ReadScript()' . \r\tThe notebook '%s'  is opened (in)visibly.  ' Execute  SetIgorOption DebugTimer,Start/Stop'   must be enabled. \r", sNotebookPath 
	//OpenNotebook /K=1 /V=0	/N=$sNotebookName  sNotebookPath	// invisible, could also use /P=symbpath...
	OpenNotebook	/K=1	/V=1	/N=$sNotebookName  sNotebookPath		// visible, could also use /P=symbpath...
	ProcessTest( "TimeSpentInReadScript", sNotebookName )				// open the table with the measured times
End

Function		buDispTimeForReadCfs( ctrlName ) : ButtonControl
	string 	ctrlName
	string 	sNotebookPath	  =  "C:\\UserIgor\\Ced\\TimeInReadCfs"
	string 	sNotebookName = "TimeReadCfs"						// this notebook must be written by extracting  the time measuring breakpoints from the code (=MarkPerfTestTime)
	printf "Display the time spent in 'ReadCfs()' . \r\tThe notebook '%s'  is opened (in)visibly.  ' Execute  SetIgorOption DebugTimer,Start/Stop'   must be enabled. \r", sNotebookPath 
	//OpenNotebook /K=1 /V=0	/N=$sNotebookName   sNotebookPath	// invisible, could also use /P=symbpath...
	OpenNotebook	/K=1	/V=1	/N=$sNotebookName  sNotebookPath		// visible, could also use /P=symbpath...
	ProcessTest( "TimeSpentInReadCfs", sNotebookName )				// open the table with the measured times
End


Function		buShowSweepTimes( ctrlName ) : ButtonControl
	string 		ctrlName
	printf "ShowSweepTimes()  %s    \r",  ctrlName
	string  	sFolder	= ksACQ
	wave 	wG		= $"root:uf:" + sFolder + ":keep:wG"  					// This  'wG'  	is valid in FPulse ( Acquisition )
	wave 	wFix		= $"root:uf:" + sFolder + ":ar:wFix"  					// This  'wFix'  	is valid in FPulse ( Acquisition )
	ShowSwTimes( sFolder, wG, wFix ) 
End


Function		buStopBackgroundTask( ctrlName ) : ButtonControl
	string 	ctrlName	

	printf "\r\tStopping BackgroundTask \r"
	CtrlBackGround stop
	KillBackGround 
End

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function		buTest1( ctrlName ) : ButtonControl
	string 	ctrlName		
	ShowTrcWndArray()
End


Function		buTest2( ctrlName ) : ButtonControl
	string  	ctrlName		
	string  	sFolder	= ksACQ
	wave 	wG		= $"root:uf:" + sFolder + ":keep:wG"  					// This  'wG'  	is valid in FPulse ( Acquisition )
	wave 	wFix		= $"root:uf:" + sFolder + ":ar:wFix"  					// This  'wFix'  	is valid in FPulse ( Acquisition )
	ShowTraceAccess( wG, wFix )
End


Function		buTest3( ctrlName ) : ButtonControl
	string  	ctrlName		
	printf  "\r\tTest3   Waves in Folders  \r"
	make  /O wInRoot = sin( .1*x)
	make  /O root:uf:disp:wInRootDisp = cos( .1*x )
	make  /O root:uf:disp:wInRootDisp2 = .5* cos( .1*x )
	wave	wInSubFolder2 = root:uf:disp:wInRootDisp2

	display /K= 1 wInRoot
	delay(1)
	AppendToGraph root:uf:disp:wInRootDisp, wInSubFolder2	// Folder !
	delay(1)
	
	ModifyGraph	rgb( wInRoot ) = (0,55555,0 )
	ModifyGraph	rgb( wInRootDisp ) = (0,55555,0 )		// no folder !
	ModifyGraph	rgb( wInRootDisp2 ) = (0,55555,0 )		// no folder !
	delay(1)

	SetScale 	/P x, 0, 3, "frame" , 	wInRoot , root:uf:disp:wInRootDisp, wInSubFolder2 	// FOLDER !
End


Function		buTest4( ctrlName ) : ButtonControl
// Igors numbers 
	string  	ctrlName		
	variable	n
	for ( n = 2000000000; n < 5e9; n += 10000000 )
		printf "%d\t\t%g \r", n, n 
	endfor
	printf "finished number test 1 : '%%d' formating is limited to 32 bit \r"
	printf "number test 2 :   .6 < 6/10 = %s    .6 == 6/10 = %s   .6 > 6/10 = %s \r", SelectString( .6 < 6/10, "FALSE", "TRUE"), SelectString( .6 ==6/10, "FALSE", "TRUE"), SelectString( .6 > 6/10, "FALSE", "TRUE")
End


Function		buTest5( ctrlName ) : ButtonControl
//  appendtograph
	string 	ctrlName		
	make /O w1=sin(x)
	make /O w2=cos(x)
	dowindow /K $"test"
	display /K=1 
	dowindow /C $"test"
	appendtograph w1
	appendtograph w2
End


Function		buTest6( ctrlName ) : ButtonControl
	string 	ctrlName		
	//DisplayHelpTopic  /K=1 "Waves[Waveform Arithmetic and Assignment]"
	//DisplayHelpTopic  /K=1 "HowTo[Get multiple traces in one window]"
	DisplayHelpTopic  /K=1 "HowTo[Convert a script from a previous version into a version >= 206]"
	//DisplayHelpTopic  /K=1 "Installation[Convert a script from a previous version into a version >= 206]"
End


Function		buTest7( ctrlName ) : ButtonControl
	string 	ctrlName	
	string  	sFolder	= ksACQ
	wave 	wG		= $"root:uf:" + sFolder + ":keep:wG"  					// This  'wG'  	is valid in FPulse ( Acquisition )
	SetPointsTestOnce( sFolder, wG )
End


Function		buTest8( ctrlName ) : ButtonControl
	string 	ctrlName	
	string  	sFolder	= ksACQ
	wave 	wG		= $"root:uf:" + sFolder + ":keep:wG"  					// This  'wG'  	is valid in FPulse ( Acquisition )
	SetPointsTestCont( sFolder, wG )
End


Function		buTest9( ctrlName ) : ButtonControl
	string 	ctrlName	
	string  	sFolder	= ksACQ
	wave 	wG		= $"root:uf:" + sFolder + ":keep:wG"  					// This  'wG'  	is valid in FPulse ( Acquisition )
	SetPointsTestContNeighbors( sFolder, wG )
End


Function		SetPointsTestOnce( sFolder, wG )		// 030724
// for testing  problematic combinations of nCEDMemPts, nPnts, nSmpInt, nDa, nAD, nTG, nSlices   which have been found with  'SetPointsTestCont()'
	string  	sFolder 
	wave	wG
	nvar		gnReps		= root:uf:acq:co:gnReps			// these..
	nvar 		gChnkPerRep	= root:uf:acq:co:gChnkPerRep		// are
	nvar		gPntPerChnk	= root:uf:acq:co:gPntPerChnk		// all
	nvar		gSmpArOfsDA	= root:uf:acq:co:gSmpArOfsDA		// set
	nvar 		gSmpArOfsAD	= root:uf:acq:co:gSmpArOfsAD		// by
	nvar		gnOfsDO		= root:uf:acq:co:gnOfsDO			// SetPoints ()
	string		bf
	variable	SmpArEndDA, SmpArEndAD, nChunkTimeMS, nTrfAreaPts				// are computed
   	variable	nCEDMemPts, nPnts, nSmpInt, nDA, nAD, nTG, nSlices, OptChkTimeMs	// input parameters
//	nCEDMemPts	=   500000;	nPnts	= 446140;		nSmpInt	= 105;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	= 3710
//	nCEDMemPts	= 1500000;	nPnts	= 395320;		nSmpInt	= 105;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	= 2830
//	nCEDMemPts	= 2000000;	nPnts	= 197324;		nSmpInt	=  40;	nDA	= 2;	nAD	= 3;	nTG	= 1;	nSlices	=  410
//	nCEDMemPts	= 6000000;	nPnts	= 854884;		nSmpInt	=  65;	nDA	= 1;	nAD	= 3;	nTG	= 3;	nSlices	=  3690
//	nCEDMemPts	= 3000000;	nPnts	= 8844448;	nSmpInt	= 115;	nDA	= 2;	nAD	= 1;	nTG	= 2;	nSlices	=  4530	// gives warning
//	nCEDMemPts	= 3000000;	nPnts	= 8844458;	nSmpInt	= 115;	nDA	= 2;	nAD	= 1;	nTG	= 2;	nSlices	=  4530	// corrected
//	nCEDMemPts	= 3000000;	nPnts	= 8844548;	nSmpInt	= 115;	nDA	= 2;	nAD	= 1;	nTG	= 2;	nSlices	=  4530	// corrected
//	nCEDMemPts	= 3000000;	nPnts	= 8845448;	nSmpInt	= 115;	nDA	= 2;	nAD	= 1;	nTG	= 2;	nSlices	=  4530	// corrected
//	nCEDMemPts	= 13000000;	nPnts	= 4483984;	nSmpInt	=  95;	nDA	= 1;	nAD	= 2;	nTG	= 1;	nSlices	=  1630	// gives warning
//	nCEDMemPts	= 13000000;	nPnts	= 4483990;	nSmpInt	=  95;	nDA	= 1;	nAD	= 2;	nTG	= 1;	nSlices	=  1630	// corrected
//	nCEDMemPts	= 13000000;	nPnts	= 4484000;	nSmpInt	=  95;	nDA	= 1;	nAD	= 2;	nTG	= 1;	nSlices	=  1630	// corrected
//	nCEDMemPts	=     500000;	nPnts	= 4484000;	nSmpInt	=  95;	nDA	= 1;	nAD	= 1;	nTG	= 0;	nSlices	=  1630	// corrected

//	nCEDMemPts	=  8000000;	nPnts	= 560010;		nSmpInt	=  50;	nDA	= 1;	nAD	= 2;	nTG	= 2;	nSlices	=  1630	// 030901

	nCEDMemPts	=  8000000;	nPnts	= 1024*1024-29800;	nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// 030902 test to provoke TA > 1MB error
	nCEDMemPts	=  8000000;	nPnts	= 1046821;	nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// 030902  131x131x61 test to provoke TA > 1MB error
	nCEDMemPts	=  8000000;	nPnts	= 1081143;	nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// 030902  131x131x63 test to provoke TA > 1MB error
	nCEDMemPts	=  80000000;	nPnts	= 1081143;	nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// 030902  131x131x63 test to provoke TA > 1MB error
	nCEDMemPts	=  80000000;	nPnts	= 131*131*7*11;	nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// 030902test to provoke TA > 1MB error
	nCEDMemPts	=  80000000;	nPnts	= 131*131*7*13;	nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// 030902test to provoke TA > 1MB error
	nCEDMemPts	=  80000000;	nPnts	= 131*131*7*17;	nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// 030902test to provoke TA > 1MB error
	nCEDMemPts	=  80000000;	nPnts	= 131*131*7*19;	nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// 030902test to provoke TA > 1MB error
	nCEDMemPts	=  80000000;	nPnts	= 131*131*11*13;	nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// 030902test to provoke TA > 1MB error
	nCEDMemPts	=  80000000;	nPnts	= 131*131*11*17;	nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// 030902test to provoke TA > 1MB error
	nCEDMemPts	=  80000000;	nPnts	= 131*131*11*19;	nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// 030902test to provoke TA > 1MB error
	nCEDMemPts	=  8000000;	nPnts	= 131*131*7*19*11;	nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// 030902test to provoke TA > 1MB error

	nCEDMemPts	=  8000000;	nPnts	= 131*137*2*29;	nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// 030902test to provoke TA > 1MB error
	nCEDMemPts	=  8000000;	nPnts	= 131*137*2*31;	nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// 030902test to provoke TA > 1MB error
	nCEDMemPts	=  8000000;	nPnts	= 131*137*3*19;	nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// 030902test to provoke TA > 1MB error
	nCEDMemPts	=  8000000;	nPnts	= 131*137*4*14;	nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// 030902test to provoke TA > 1MB error
	nCEDMemPts	=  8000000;	nPnts	= 131*139*7*9;		nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// 030902test to provoke TA > 1MB error
	nCEDMemPts	=  8000000;	nPnts	= 137*139*7*9;		nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// 030902test to provoke TA > 1MB error
	nCEDMemPts	=  8000000;	nPnts	= 131*149*7*9;		nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// 030902test to provoke TA > 1MB error
	nCEDMemPts	=  8000000;	nPnts	= 151*149*7*7;		nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// 030902test to provoke TA > 1MB error
	nCEDMemPts	=  8000000;	nPnts	= 151*149*7*9;		nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// 030902test to provoke TA > 1MB error
	nCEDMemPts	=  8000000;	nPnts	= 151*151*7*9;		nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// 030902test to provoke TA > 1MB error
	nCEDMemPts	=  8000000;	nPnts	= 151*151*5*9;		nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// 030902test to provoke TA > 1MB error
	nCEDMemPts	=  8000000;	nPnts	= 151*157*5*9;		nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// +++030902test to provoke TA > 1MB error
//	nCEDMemPts	=  8000000;	nPnts	= 149*157*5*9;		nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// +++030902test to provoke TA > 1MB error
//	nCEDMemPts	=  8000000;	nPnts	= 151*157*5*9;		nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// +++030902test to provoke TA > 1MB error
//	nCEDMemPts	=  8000000;	nPnts	= 151*167*5*9;		nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// +++030902test to provoke TA > 1MB error
//	nCEDMemPts	=  8000000;	nPnts	= 167*131*5*9;		nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// +++030902test to provoke TA > 1MB error
//	nCEDMemPts	=  8000000;	nPnts	= 131*151*5*9;		nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// +++030902test to provoke TA > 1MB error
//	nCEDMemPts	=  8000000;	nPnts	= 131*157*3*17;	nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// +++030902test to provoke TA > 1MB error
//	nCEDMemPts	=  8000000;	nPnts	= 131*149*5*11;	nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// +++030902test to provoke TA > 1MB error
//	nCEDMemPts	=  8000000;	nPnts	= 131*299*3*9;		nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// +++030902test to provoke TA > 1MB error
//	nCEDMemPts	=  8000000;	nPnts	= 131*131*5*7;		nSmpInt	=  50;	nDA	= 1;	nAD	= 2;	nTG	= 2;	nSlices	=  1630	// +++030902test to provoke TA > 1MB error
//	nCEDMemPts	=  8000000;	nPnts	= 67*67*13*17;		nSmpInt	=  50;	nDA	= 1;	nAD	= 2;	nTG	= 2;	nSlices	=  1630	// +++030902test to provoke TA > 1MB error
//	nCEDMemPts	=  8000000;	nPnts	= 67*67*11*19;		nSmpInt	=  50;	nDA	= 1;	nAD	= 2;	nTG	= 2;	nSlices	=  1630	// +++030902test to provoke TA > 1MB error
//	nCEDMemPts	=  8000000;	nPnts	= 67*83*11*17*19;	nSmpInt	=  50;	nDA	= 1;	nAD	= 2;	nTG	= 2;	nSlices	=  1630	// +++030902test to provoke TA > 1MB error
//	nCEDMemPts	=  8000000;	nPnts	= 67*83*10*17*20;	nSmpInt	=  50;	nDA	= 1;	nAD	= 2;	nTG	= 2;	nSlices	=  1630	// +++030902test to provoke TA > 1MB error
//	nCEDMemPts	=  1406546;	nPnts	=  5684200;		nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 2;	nSlices	=  10		// +++030902test to provoke TA > 1MB error
//	nCEDMemPts	=  5400306;	nPnts	=  8038600;		nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 2;	nSlices	=  10		// +++030902test to provoke TA > 1MB error
//	nCEDMemPts	=  1984802;	nPnts	=   6144400;		nSmpInt	=  50;	nDA	= 2;	nAD	= 3;	nTG	= 1;	nSlices	=  10		// +++040902test
//	nCEDMemPts	=  5000000 ;	nPnts	=   8111800;		nSmpInt	=  50;	nDA	= 3;	nAD	= 2;	nTG	= 1;	nSlices	= 0		// +++040902test
//	nCEDMemPts	=  6996000 ;	nPnts	=   9773800;		nSmpInt	=  50;	nDA	= 1;	nAD	= 3;	nTG	= 2;	nSlices	= 2270	// +++040902test
//	nCEDMemPts	=  8000000;	nPnts	=  10009 * 10037;	nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 2;	nSlices	=  10		// Product of 2 primes
	nCEDMemPts	=  8000000;	nPnts	=    1019 *   1021;	nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 2;	nSlices	=  10		// Product of 2 primes
//	nCEDMemPts	=  9999997;	nPnts	=  1048583;		nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 2;	nSlices	=  10		// Prime number will fail
//	nCEDMemPts	=  100000;		nPnts	=   2 * 3 * 3 * 3 * 5 * 5 * 19;	nSmpInt=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// +++030902test to provoke TA > 1MB error


  	OptChkTimeMs =10000 // 1000 030901	

	nTrfAreaPts	= SetPoints( sFolder, wG, nCEDMemPts, nPnts, nSmpInt , nDA, nAD, nTG, nSlices, kERR_IMPORTANT, kERR_IMPORTANT )	// all params are points not bytes	

	SmpArEndDA	= gSmpArOfsDA + trunc( 2 * gChnkPerRep * gPntPerChnk * nDA + .5 )			// like SetPoints ()	
	SmpArEndAD 	= gSmpArOfsAD + trunc( 2 * gChnkPerRep * gPntPerChnk * ( nAD + nTG ) + .5 )	// like SetPoints ()		
	nChunkTimeMS	= gPntPerChnk * nSmpInt /  1000
	printf "\t%8d\t%8d\tSi:%4d\t%2d\t%2d\t%2d\tSl:%4d\t: Rep:%4d\t* Chk:%4d\t* PpC:%5d\tTA:%8d\t%7d\t%7d\t\t%7d\t%7d\t%10d\t[%4d /\t%4dms]\t \r", nCEDMemPts, nPnts, nSmpInt , nDA, nAD, nTG, nSlices, gnReps, gChnkPerRep, gPntPerChnk, nTrfAreaPts, gSmpArOfsDA, SmpArEndDA, gSmpArOfsAD, SmpArEndAD, gnOfsDO, nChunkTimeMS, OptChkTimeMs

End


Function		SetPointsTestCont( sFolder, wG )		// 030724
// for finding problematic combinations of nCEDMemPts, nPnts, nSmpInt, nDa, nAD, nTG, nSlices, e.g. nReps > 100,  nChunksPerRep > 100,  Chunktime < 100 ms
	string  	sFolder
	wave	wG
	variable	SmpArEndDA, SmpArEndAD, nChunkTimeMS, nTrfAreaPts				// are computed
   	variable	nCEDMemPts, nPnts, nSmpInt, nDA, nAD, nTG, nSlices, OptChkTimeMs	// input parameters
	string		bf
	printf "\r\tSetPointsTestCont()	[ stop with 'Abort', turn on Print options debug ,  Loops ,  Acq ] \r"
	delay( 1 )
	nvar		gnReps		= root:uf:acq:co:gnReps
	nvar 		gChnkPerRep	= root:uf:acq:co:gChnkPerRep
	nvar		gPntPerChnk	= root:uf:acq:co:gPntPerChnk
	nvar		gSmpArOfsDA	= root:uf:acq:co:gSmpArOfsDA
	nvar 		gSmpArOfsAD	= root:uf:acq:co:gSmpArOfsAD
	nvar		gnOfsDO		= root:uf:acq:co:gnOfsDO
	do
		nCEDMemPts	= Random( 500000, 8000000, 500000 )
		nPnts		= Random( 200, 10000000, 2 )			// decreasing the step size to 2..8 will issue more 'Data points' warnings and errors
		nSmpInt		= Random( 20, 220, 5 )
		nDA			= Random( 1, 3, 1 )
		nAD			= Random( 1, 4, 1 )
		nTG			= Random( 0, 3, 1 )
		nSlices		= Random( 10, 5000, 20 )

		nTrfAreaPts	= SetPoints( sFolder, wG, nCEDMemPts, nPnts, nSmpInt , nDA, nAD, nTG, nSlices, kERR_IMPORTANT, kERR_IMPORTANT )	// all params are points not bytes	

		SmpArEndDA	= gSmpArOfsDA + trunc( 2 * gChnkPerRep * gPntPerChnk * nDA + .5 )			// like SetPoints ()	
		SmpArEndAD 	= gSmpArOfsAD + trunc( 2 * gChnkPerRep * gPntPerChnk * ( nAD + nTG ) + .5 )	// like SetPoints ()	
		nChunkTimeMS	= gPntPerChnk * nSmpInt / 1000
//		printf "\t %10d \t %10d \tSi:%4d\t%2d\t%2d\t%2d\tSl:%4d\t:Rep:%6d\t* Chk:%4d\t* PpC:%5d\tTA:%8d\t%7d\t%7d\t\t%7d\t%7d\t%10d\t[%4d /\t%4dms]\t \r", nCEDMemPts*2, nPnts, nSmpInt , nDA, nAD, nTG, nSlices, gnReps, gChnkPerRep, gPntPerChnk, nTrfAreaPts, gSmpArOfsDA, SmpArEndDA, gSmpArOfsAD, SmpArEndAD, gnOfsDO, nChunkTimeMS, OptChkTimeMs

		if ( nTrfAreaPts == kERROR )
			break
		endif
	while ( TRUE )
End


Function		SetPointsTestContNeighbors( sFolder, wG )		// 030724
// for finding problematic combinations of nCEDMemPts, nPnts, nSmpInt, nDa, nAD, nTG, nSlices, e.g. nReps > 100,  nChunksPerRep > 100,  Chunktime < 100 ms
	string  	sFolder
	wave	wG
   	variable	nCEDMemPts, nPnts, nSmpInt, nDA, nAD, nTG, nSlices, OptChkTimeMs	// input parameters
	variable	Neighbors		= 50
	printf "\r\tSetPointsTestCont  checking + %d neighbors()	[ stop with 'Abort' ]  \r", Neighbors
	delay( 1 )
	do
		nCEDMemPts	= Random( 500000, 8000000, 500000 )
		nPnts		= Random( 100, 10000000, 2 )			// decreasing the step size to 2..8 will issue more 'Data points' warnings and errors
		nSmpInt		= Random( 20, 220, 5 )
		nDA			= Random( 1, 3, 1 )
		nAD			= Random( 1, 4, 1 )
		nTG			= Random( 0, 3, 1 )
		nSlices		= Random( 10, 5000, 20 )
		CheckNeighbors( sFolder, wG, nCEDMemPts, nPnts, nSmpInt , nDA, nAD, nTG, nSlices, Neighbors )	
	while ( TRUE )
End




Function		buTest10( ctrlName ) : ButtonControl
// Primes
	string 	ctrlName	
	//variable	n, nStart	=   100160001, 	nEnd	  =   	  100160100		// takes 4s	10007*10009 = 100160063	
	variable	n, nStart	= 2000160001,	nEnd  =	2000160100		// takes 20s with FP Implementation, 10ms with Igor
	string  	lstFactors

	printf "\tOnly Igor's much faster implementation is executed. See  FPPrimeFactors()  ....\r"
	// Step 1 : print primes to check them
	for ( n =  nStart; n < nEnd; n += 2 )
		lstFactors	= FPPrimeFactors( n )
		printf "\t\tFPPrimeFactors( %d ) : \t%s\tIgor:\t", n, pd( lstFactors, 32)
		PrimeFactors	n
	endfor
	
	// Step 2 : measure time needed to compute primes
	KillAllTimers()

	ResetStartTimer( "IPrime" )
	for ( n =  nStart; n < nEnd; n += 2 )
		PrimeFactors /Q  n
	endfor
	ReadTimer( "IPrime" )
	StopTimer( "IPrime" )

	ResetStartTimer( "FPrime" )
	for ( n =  nStart; n < nEnd; n += 2 )
		lstFactors	= FPPrimeFactors( n )
	endfor
	ReadTimer( "FPrime" )
	StopTimer( "FPrime" )
	
	PrintAllTimers( ON )
	KillAllTimers()
End


Function		buTest11( ctrlName ) : ButtonControl
	string 	ctrlName	
	printf "\tReplaceListItem   %s\r", ctrlName
	string  	sList, sItem
	variable	nPos, nMax = 5
	string  	sListSep	= ","		
	sItem		= "+"	//  "+"  or  ""
	sList		= "0,1,2,"
	for ( nPos = 0; nPos < nMax; nPos += 1 )
	 	ReplaceListItem1( sItem, sList, sListSep, nPos )
	endfor 
	sList		= "0,1,2"
	for ( nPos = 0; nPos < nMax; nPos += 1 )
	 	ReplaceListItem1( sItem, sList, sListSep, nPos )
	endfor 
	sList		= "0,,2,"
	for ( nPos = 0; nPos < nMax; nPos += 1 )
	 	ReplaceListItem1( sItem, sList, sListSep, nPos )
	endfor 
	sList		= "0,,2"
	for ( nPos = 0; nPos < nMax; nPos += 1 )
	 	ReplaceListItem1( sItem, sList, sListSep, nPos )
	endfor 
	sList		= ",,2,"
	for ( nPos = 0; nPos < nMax; nPos += 1 )
		printf "?"
	 	ReplaceListItem1( sItem, sList, sListSep, nPos )
	endfor 
	sList		= ",,2"
	for ( nPos = 0; nPos < nMax; nPos += 1 )
		printf "?"
	 	ReplaceListItem1( sItem, sList, sListSep, nPos )
	endfor 
	sList		= "0,1,"
	for ( nPos = 0; nPos < nMax; nPos += 1 )
	 	ReplaceListItem1( sItem, sList, sListSep, nPos )
	endfor 
	sList		= "0,1"
	for ( nPos = 0; nPos < nMax; nPos += 1 )
	 	ReplaceListItem1( sItem, sList, sListSep, nPos )
	endfor 
	sList		= "0,,"
	for ( nPos = 0; nPos < nMax; nPos += 1 )
		printf "?"
	 	ReplaceListItem1( sItem, sList, sListSep, nPos )
	endfor 
	sList		= ",1,"
	for ( nPos = 0; nPos < nMax; nPos += 1 )
		printf "?"
	 	ReplaceListItem1( sItem, sList, sListSep, nPos )
	endfor 
	sList		= ",1"
	for ( nPos = 0; nPos < nMax; nPos += 1 )
	 	ReplaceListItem1( sItem, sList, sListSep, nPos )
	endfor 
	sList		= ",,"
	for ( nPos = 0; nPos < nMax; nPos += 1 )
		printf "?"
	 	ReplaceListItem1( sItem, sList, sListSep, nPos )
	endfor 
	sList		= "0,"
	for ( nPos = 0; nPos < nMax; nPos += 1 )
	 	ReplaceListItem1( sItem, sList, sListSep, nPos )
	endfor 
	sList		= ","
	for ( nPos = 0; nPos < nMax; nPos += 1 )
	 	ReplaceListItem1( sItem, sList, sListSep, nPos )
	endfor 
	sList		= "0"
	for ( nPos = 0; nPos < nMax; nPos += 1 )
	 	ReplaceListItem1( sItem, sList, sListSep, nPos )
	endfor 
	sList		= ""
	for ( nPos = 0; nPos < nMax; nPos += 1 )
	 	ReplaceListItem1( sItem, sList, sListSep, nPos )
	endfor 

	nMax = 4
	sItem		= ""	//  "+"  or  ""
	sList		= "0,1,"
	for ( nPos = 0; nPos < nMax; nPos += 1 )
	 	ReplaceListItem1( sItem, sList, sListSep, nPos )
	endfor 
	sList		= "0,1"
	for ( nPos = 0; nPos < nMax; nPos += 1 )
	 	ReplaceListItem1( sItem, sList, sListSep, nPos )
	endfor 
	sList		= "0,,"
	for ( nPos = 0; nPos < nMax; nPos += 1 )
		printf "?"
	 	ReplaceListItem1( sItem, sList, sListSep, nPos )
	endfor 
	sList		= ",1,"
	for ( nPos = 0; nPos < nMax; nPos += 1 )
		printf "?"
	 	ReplaceListItem1( sItem, sList, sListSep, nPos )
	endfor 
	sList		= ",1"
	for ( nPos = 0; nPos < nMax; nPos += 1 )
	 	ReplaceListItem1( sItem, sList, sListSep, nPos )
	endfor 
	sList		= ",,"
	for ( nPos = 0; nPos < nMax; nPos += 1 )
		printf "?"
	 	ReplaceListItem1( sItem, sList, sListSep, nPos )
	endfor 
	sList		= "0,"
	for ( nPos = 0; nPos < nMax; nPos += 1 )
	 	ReplaceListItem1( sItem, sList, sListSep, nPos )
	endfor 
	sList		= ","
	for ( nPos = 0; nPos < nMax; nPos += 1 )
	 	ReplaceListItem1( sItem, sList, sListSep, nPos )
	endfor 
	sList		= "0"
	for ( nPos = 0; nPos < nMax; nPos += 1 )
	 	ReplaceListItem1( sItem, sList, sListSep, nPos )
	endfor 
	sList		= ""
	for ( nPos = 0; nPos < nMax; nPos += 1 )
	 	ReplaceListItem1( sItem, sList, sListSep, nPos )
	endfor 

End

static constant	kSKIP_RESULTS_WHICH_ARE_OK = 10

Function		buTest12( ctrlName ) : ButtonControl
// Heap Scramble + TransferArea
// 030911 empirical ly found: 1. the minimum and the maximum requested working size (accessible only in XOP) must be  at least 36 KB more than the needed Transfer area points (*2) 
// 					   2. the minimum and the maximum requested working size (accessible only in XOP) should never be made smaller than the current sizes (->changed XOP code)
// 030912 obsolete and useless when minimum and the maximum requested working size are fixed and independent of TransferAreaPoints  as it is now....
	string 	ctrlName	
	variable	nResult	= 0
	variable	nTrfAreaPts, n = 0
	string  	sFolder	= ksACQ
	printf "\r\t TestHeapScramble	[ stop with 'Abort' ]     FIRST a script must have been loaded  OR  the Ced must have been opened manually  (Test CED 1401) !!!!\r"
	delay( 1 )
	String 	savDF	= GetDataFolder(1)			// Save current DF for restore.
	NewDataFolder/O/S $"root:uf:" + sFolder + ":ar"		// Make sure this exists.  /S make current folder (in which  'wAbsorbMem'  will be placed)

// OKstring   	sFo = "keep"
string   	sFo = "keep1"

	NewDataFolder/O $"root:uf:" + sFolder + ":" +  sFo	// Make sure this exists, but don't make it current folder.
	do 
		n	+= 1
		nTrfAreaPts	= Random( 100, 524288, 2 )	
		nResult		= TestHeapScramble( sFolder, sFo, n, nTrfAreaPts )
	while( nResult == 0 )							// break at any error (e.g. CED not open or failed setting transfer area)
	SetDataFolder 	savDF						// Restore current DF.
End

Function		TestHeapScramble( sFolder, sFo, n, nTrfAreaPts )
	// 041203  TEST to detect heap scramble problems : This code is equivalent to the main 'Apply Script' code up to  Nov04 which failed sporadically due to a heap scramble bug.
	string  	sFolder, sFo
	variable	n, nTrfAreaPts
	variable	showMode	= 0//MSGLINE 
	variable	nResultUnset	= 0

	// 041203  TEST to detect heap scramble problems : This code is equivalent to the main 'Apply Script' code up to  Nov04 which failed sporadically due to a heap scramble bug.
	// Allocate some memory  on the heap
	variable	nHeapPts	= Random( 100, 100000, 2 )	
	make	/O /N=(nHeapPts)		wAbsorbMem
	if ( nHeapPts != numPnts( wAbsorbMem ) )
		printf "++Internal error:\tHeap Scramble(n:\t%8d\t) : Could not\t'Make' wave  \r" , n
		return	-1
	endif 
	// Redimension the memory  on the heap
	wAbsorbMem[ nHeapPts / 2 ] =  nHeapPts / 2 			// dummy operation
	variable	nRedimPts	= Random( 100, 100000, 2 )	
	Redimension 	/N=(nRedimPts)		wAbsorbMem
	if ( nRedimPts != numPnts( wAbsorbMem ) )
		printf "++Internal error: Heap Scramble (n:\t%8d\t) : Could not\tRedimension  wave  from  \t%8d\t to \t%8d\t points.  TAPoints:%8d \r" , n, nHeapPts, nRedimPts, nTrfAreaPts
		KillWaves 	wAbsorbMem
		return	-1	
	endif 
	// Free the memory on the heap
	KillWaves 	wAbsorbMem

	
	// Create and lock the  ADDA wave in the transfer area where all data must go through

//	NewDataFolder  /O $"root:uf:" + sFolder + ":" + sFo				// this is OK and required only when 'sFo'  is not 'keep'  e.g. when it is 'keep1' 
//
//	wave  /Z	wRaw	= $"root:uf:" + sFolder + ":" + sFo + ":wRaw"  	// 041203 must be PERMANENT data folder, will give sporadic heap scramble problems if a regularly cleared folder (e.g.ar) is used	
//	if ( waveExists( wRaw ) )
//		nvar	/Z gResult	= $"root:uf:" + sFolder + ":gResult"
//		if ( nvar_exists( gResult )  && gResult == 0 ) 
//			nResultUnset	= xCEDUnsetTransferArea( 0, wRaw, showMode ) 
//			if ( nResultUnset )   
//				printf "++Internal error: \tHeap Scramble (n:\t%8d\t) : Could not UnsetTransferArea\t'wRaw' .   TAPoints:%8d -> Result: %d\r" , n, nTrfAreaPts, nResultUnset
//				KillWaves		wRaw
//				return	nResultUnset
//			endif														
//		endif															
//		KillWaves		wRaw
//	endif




//  OK  but data folder is not deleted
//	NewDataFolder  /O $"root:uf:" + sFolder + ":" + sFo				// this is OK and required only when 'sFo'  is not 'keep'  e.g. when it is 'keep1' 
//
//	wave  /Z	wRaw	= $"root:uf:" + sFolder + ":" + sFo + ":wRaw"  	// 041203 must be PERMANENT data folder, will give sporadic heap scramble problems if a regularly cleared folder (e.g.ar) is used	
//	if ( waveExists( wRaw ) )
//		nResultUnset	= xCEDUnsetTransferArea( 0, wRaw, showMode ) 
//		if ( nResultUnset )   
//			printf "++Internal error: \tHeap Scramble (n:\t%8d\t) : Could not UnsetTransferArea\t'wRaw' .   TAPoints:%8d -> Result: %d\r" , n, nTrfAreaPts, nResultUnset
//			KillWaves		wRaw
//			return	nResultUnset
//		endif														
//		KillWaves		wRaw
//	endif



// WRONG because it is attempted to unset a non-existing transfer area
//	wave  /Z	wRaw	= $"root:uf:" + sFolder + ":" + sFo + ":wRaw"  		// 041203 must be PERMANENT data folder, will give sporadic heap scramble problems if a regularly cleared folder (e.g.ar) is used	
//	if ( waveExists( wRaw ) )
//		nResultUnset	= xCEDUnsetTransferArea( 0, wRaw, showMode ) 
//		if ( nResultUnset )   
//			printf "++Internal error: \tHeap Scramble (n:\t%8d\t) : Could not UnsetTransferArea\t'wRaw' .   TAPoints:%8d -> Result: %d\r" , n, nTrfAreaPts, nResultUnset
//			KillWaves		wRaw
//			return	nResultUnset
//		endif														
//	endif
//	KillDataFolderUnconditionally( "root:uf:" + sFolder + ":" + sFo + ":"	 ) 		// does   work
//	NewDataFolder  /O $"root:uf:" + sFolder + ":" + sFo					// this is OK and required only when 'sFo'  is not 'keep'  e.g. when it is 'keep1' 



//  Partially/largely  OK #1:	Data folder is deleted.   
//					Can Reset Ced   (but cannot Open/close/open Ced)  between  'Abort'  and  restarting  this 'Test12'
//					It is not required to load a  script  before starting  this 'Test12' but  the Ced has to be opened before manually.
//  Todo : adopt this code to the real acquisition and check if  the redimensioning-error is gone even when  'bCRASH_ON_REDIM_TEST14'  is ON (running Test14 /butest14)
	wave  /Z	wRaw	= $"root:uf:" + sFolder + ":" + sFo + ":wRaw"  			// 051108 works with a regularly cleared folder (e.g. 'keep1') 	
	if ( waveExists( wRaw ) )
		nvar	/Z gResult	= $"root:uf:" + sFolder + ":gResult"
		if ( nvar_exists( gResult )  && gResult == 0 ) 
// 2009-10-22 modify for Igor6
//			nResultUnset	= xCEDUnsetTransferArea( 0, wRaw, showMode ) 	// The attempt to unset a non-existing transfer area  (=error -528)  will do no harm as it is caught in the XOP.
			nResultUnset	= UFP_CEDUnsetTransferArea( 0, wRaw, showMode ) 	// The attempt to unset a non-existing transfer area  (=error -528)  will do no harm as it is caught in the XOP.
			if ( nResultUnset )   										// This error -528 will occur after having been in test mode and then switching the Ced on
				printf "++Internal error: \tHeap Scramble (n:\t%8d\t) : Could not UnsetTransferArea\t'wRaw' .   TAPoints:%8d -> Result: %d\r" , n, nTrfAreaPts, nResultUnset
				KillWaves		wRaw
				return	nResultUnset
			else
				if ( mod( n, kSKIP_RESULTS_WHICH_ARE_OK ) == 0 )
					// printf "\t\t\t\tHeap Scramble (n:\t%8d\t) : OK \t\tUnsetting Transfer area OK.  \r" , n
				endif
			endif														
		endif															
	endif
	KillDataFolderUnconditionally( "root:uf:" + sFolder + ":" + sFo )				// does   work
	NewDataFolder  	 $"root:uf:" + sFolder + ":" + sFo						// this is OK and required only when 'sFo'  is not 'keep'  e.g. when it is 'keep1' 


//  WRONG   #2
//	nvar	/Z gResult	= $"root:uf:" + sFolder + ":gResult"
//	if ( nvar_exists( gResult )  && gResult == 0 ) 
//		nResultUnset	= xCEDUnsetTransferArea( 0, wRaw, showMode ) 		// The attempt to unset a non-existing transfer area  (=error -528)  will do no harm as it is caught in the XOP.
//		if ( nResultUnset )   											// This error -528 will occur after having been in test mode and then switching the Ced on
//			printf "++Internal error: \tHeap Scramble (n:\t%8d\t) : Could not UnsetTransferArea\t'wRaw' .   TAPoints:%8d -> Result: %d\r" , n, nTrfAreaPts, nResultUnset
//			return	nResultUnset
//		else
//			if ( mod( n, kSKIP_RESULTS_WHICH_ARE_OK ) == 0 )
//				printf "\t\t\t\tHeap Scramble (n:\t%8d\t) : OK \t\tUnsetting Transfer area \t'wRaw' is  OK.  \r" , n
//			endif
//		endif														
//	endif															
//	KillDataFolderUnconditionally( "root:uf:" + sFolder + ":" + sFo )				// does   work
//	NewDataFolder  	 $"root:uf:" + sFolder + ":" + sFo						// this is OK and required only when 'sFo'  is not 'keep'  e.g. when it is 'keep1' 


	make  	/W /N=( nTrfAreaPts )  $"root:uf:" + sFolder + ":" + sFo + ":wRaw" 		// allowed area 0, allowed size up to 512KWords=1MB , 16 bit integer
	wave	wRaw			= $"root:uf:" + sFolder + ":" + sFo + ":wRaw"
	variable /G 				   $"root:uf:" + sFolder + ":gResult"
	nvar		 gResult			= $"root:uf:" + sFolder + ":gResult"
// 2009-10-22 modify for Igor6
//	gResult			= xCEDSetTransferArea( 0, nTrfAreaPts, wRaw , showMode )
	gResult			= UFP_CEDSetTransferArea( 0, nTrfAreaPts, wRaw , showMode )
	if ( gResult )   
		printf "++Internal error: \tHeap Scramble (n:\t%8d\t) : Could not  SetTransferArea \t'wRaw' .   TAPoints:%8d -> Result: %d\r" , n, nTrfAreaPts, gResult
		return	gResult
	endif															// dummy operation : can we read the memory ?


	// Write into and read from  the  ADDA wave  some data
	variable	nInt16	= mod( nTrfAreaPts, 65536 ) - 32768					// adjust to wave type
	wRaw	= nInt16												// dummy operation : can we write into the memory ?
	if ( nInt16 != wRaw[ 0 ]   ||   nInt16 != wRaw[ trunc(nTrfAreaPts/2) ]  ||   nInt16 != wRaw[  nTrfAreaPts-1  ]  ||  numPnts( wRaw ) !=  nTrfAreaPts )   
		printf "++Internal error:\tHeap Scramble (n:\t%8d\t) : Could not\tread/write  into \t'wRaw' .   TAPoints:\t%8d \t?=\t%8d\t,\t%8d ?= \t%8d ?= \t%8d ?= \t%8d \r" , n, nTrfAreaPts,  numPnts( wRaw ),  nInt16, wRaw[ 0 ] , wRaw[ trunc(nTrfAreaPts/2) ] , wRaw[  nTrfAreaPts-1 ]
		return	-1
	endif															// dummy operation : can we read the memory ?

	if ( mod( n, kSKIP_RESULTS_WHICH_ARE_OK ) == 0 )
		printf "\t\t\t\tHeap Scramble (n:\t%8d\t) : OK \t\tRedimensioning from\t\t%8d\t to\t%8d\t points.  TAPoints:%8d \r" , n, nHeapPts, nRedimPts, nTrfAreaPts
	endif
	
	return	0
End


Function		buTest13( ctrlName ) : ButtonControl
	string 	ctrlName	
	variable	hnd, code

	printf "\r\tTest13 Ced U14Ld \r"

// 2009-10-22 modify for Igor6
//	xCEDCloseAndOpen(  ERRLINE )					// do NOT show error box  ( Parameter1 = n1401 should be 0, see prog int lib 3.20, dec 99, p.5)
	UFP_CEDCloseAndOpen(  ERRLINE )					// do NOT show error box  ( Parameter1 = n1401 should be 0, see prog int lib 3.20, dec 99, p.5)
//	hnd		= xCEDGetHandle();
	hnd		= UFP_CEDGetHandle();
	printf "\t\tAcqDA CEDInit1401DACADC() : Ced  Hnd:%d \r",  hnd
	if ( hnd != 0 )
		return hnd
	endif

	// load these commands, 'KILL' (when loaded first) actually unloads all commands before reloading them to free occupied memory (recommendation of Tim Bergel, 2000 and 2003)
	string 		sCmdDir	= "c:\\1401\\"
	string 		sCmds	= "KILL,MEMDAC,ADCMEM,ADCBST,DIGTIM,SM2,SN2,SS2"	// the  Test/error led  should not flash unless commands are overwritten (which cannot occur bcause of 'KILL' above)
// 2009-10-22 modify for Igor6
//	code		= xCEDLdErrOut( MSGLINE, sCmdDir, sCmds )
	code		= UFP_CEDLdErrOut( MSGLINE, sCmdDir, sCmds )
	// printf "\t\tAcqDA CEDInit1401DACADC()  loading commands  '%s'  '%s' \treturns code:%d \r", sCmdDir, sCmds, code
	if ( code )
		return	code
	endif
End

Function		CedTimer2Off()
// will actually not really turn the timer off, but will start with appr. 10 years low, then 1 hour high
	string 		sBuf	= "TIMER2,C,2,65535,65535,65535;"	// clock, mode, pre1, pre2, count : Hi duration = pre1*pre2,  period = pre1*pre2*count
	CEDSendStringCheckErrors( sBuf, 1 ) 
//	variable	code = xCEDSendStringErrOut( MSGLINE, sBuf ) 
End

Function		CedTimer2Set( mode, pre1, pre2, count )
	variable	mode, pre1, pre2, count
	//variable	code
	string 		sBuf
	sprintf sBuf, "TIMER2,C,%d,%d,%d,%d;", mode, pre1, pre2, count	// C = clock, CG = gated clock,  Hi duration = pre1*pre2,  period = pre1*pre2*count
	CEDSendStringCheckErrors( sBuf, 1 ) 
	//code	= xCEDSendStringErrOut( MSGLINE, sBuf ) 
End

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function		buTest14( ctrlName ) : ButtonControl
	string 	ctrlName	
	string 	lstScripts	= "C:UserIgor:Ced:Scripts:000CrashFr1_plus16mb.txt;C:UserIgor:Ced:Scripts:000CrashFr31_plus16mb.txt;C:UserIgor:Ced:Scripts:000CrashFr2_plus16mb.txt;C:UserIgor:Ced:Scripts:000CrashFr7_plus16mb.txt;"	// should but does not crash with  1401Plus Ced (16 MB)
	//string 	lstScripts	= "C:UserIgor:Ced:Scripts:000CrashFr1_plus16mb.txt;C:UserIgor:Ced:Scripts:000CrashFr3_plus16mb.txt;C:UserIgor:Ced:Scripts:000CrashFr2_plus16mb.txt;C:UserIgor:Ced:Scripts:000CrashFr7_plus16mb.txt;"	// should but does not crash with  1401Plus Ced (16 MB)
	// string 	lstScripts	= "C:UserIgor:Ced:Scripts:000CrashFr1_power.txt;C:UserIgor:Ced:Scripts:000CrashFr2_power.txt;"			// crashes with  Power Ced (32 MB)
	printf "\rTest14 :  Heap scramble + AutoLoadScripts\r"
	printf "\t\t\tStop with 'Abort' . Will continuously load scripts '%s' \r", lstScripts[ 0, 200 ]
	string  	sScript, sCtrlName = "buLoadScript"
	variable	n, nScripts	= ItemsInList( lstScripts )
	variable	rCode, cnt	= 0
	do
		for ( n = 0; n < nScripts; n += 1 )
			sScript	= StringFromList( n, lstScripts )
		
			svar		gsScriptPath	= root:uf:script:gsScriptPath
			// printf "\t\t%d\t%s (bef load)\tgsScriptPath: '%s'   '%s' \r", cnt, CtrlName, gsScriptPath, sScript
// 060515a	constant	kbKEEP_ACQ_DISP = 0,  kbNEW_ACQ_DISP = 1
			gsScriptPath	= LoadScript( ksACQ , sScript, rCode, kbNEW_ACQ_DISP )								// pass an empty path to invoke a FileOpenDialog
			 printf "\t\t%d\t%s (aft load)\tgsScriptPath: '%s'   '%s'  \r", cnt, sCtrlName, gsScriptPath, sScript
			// buLoadScript_Title( sCtrlName )   // gives linker error when only Eval  is started 
			cnt += 1
		endfor
	while ( rCode == kOK )			//Stop at first error.   User may exit prematurely with  'Abort'  
End

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function		buTest15( ctrlName ) : ButtonControl
	string 	ctrlName	
	printf "\tSetVar+Popupmenu Format\r"
	NewPanel  /K=1 /W=( 10, 10, 450, 600 )
	variable	xP1	= 100, 	xP2	= 400, dy = 20, n

	variable	xS1	= 100, 	xS2	= 300, xs
	variable	bw1	= 80, 	bw2	= 200, bw
	string  	s1	= "s1", 	s2	= "s2_long_string", s3	= "s3_very_very_long_very_very_long_string", sTxt, sPad	
	variable	nBlankPixels, nBlanks, nPixel1Blank	= FontSizeStringWidth( ksFONT, kFONTSIZE, 0, " " ) 
	//	Left margin changes ( = Igor default behavior :  insert automatically blanks in front of the title so that the title end  is glued to the input field )

	n = dy

	DrawText  20, n, "Pixel/Blank: " + num2str(nPixel1Blank)
	n 	= TestSetvarAndPopupmenu( "", xs1, bw1, xp1, dy, n )
	n 	= TestSetvarAndPopupmenu( "", xs1, xs1,  xp1, dy, n )
	n 	= TestSetvarAndPopupmenu( s1, xs1, bw1, xp1, dy, n )
	n 	= TestSetvarAndPopupmenu( s2, xs1, bw1, xp1, dy, n )
	n 	= TestSetvarAndPopupmenu( s2, xs1, bw2, xp1, dy, n )
	n 	= TestSetvarAndPopupmenu( s1, xs2, bw2, xp1, dy, n )
	n 	= TestSetvarAndPopupmenu( s2, xs2, bw1, xp1, dy, n )
	n 	= TestSetvarAndPopupmenu( s2, xs2, bw2, xp1, dy, n )
	n 	= TestSetvarAndPopupmenu( s3, xs2, bw1, xp1, dy, n )
	n 	= TestSetvarAndPopupmenu( "Recal2", 340, 100, 2, dy, n )
	n 	= TestSetvarAndPopupmenu( "Recal2", 330, 100, 2, dy, n )
	n 	= TestSetvarAndPopupmenu( "Recal2", 320, 100, 2, dy, n )
	n 	= TestSetvarAndPopupmenu( "Recal2", 310, 100, 2, dy, n )
	n 	= TestSetvarAndPopupmenu( "Recal2", 300, 100, 2, dy, n )	// THERE SEEMS to BE A MAXIMUM SIZE of about 300...
	n 	= TestSetvarAndPopupmenu( "Recal2", 290, 100, 2, dy, n )	// ...controls greater than that are not positioned correctly

End

Function	TestSetvarAndPopupmenu( sTxt, xs, bodyw, xp, dy, n )
	string  	sTxt
 	variable	xs, bodyw, xp, dy, n
	FormatSetvarPopup( sTxt, xs, bodyw )		// references are changed
	n += dy;	SetVariable	$"sv"+num2str(n),	pos	= { xp,     n }, 	title = sTxt,	   bodywidth	= bodyw,	size	= { xs, dy - 2 } 	//  		len OK	right OK justified 
	n += dy;	Popupmenu	$"pm"+num2str(n),	pos	= { xp+1, n-1 }, 	title = sTxt,	   bodywidth	= bodyw,	size	= { xs, dy - 2 } 	// 		len OK	right OK justified 
	return	n
End


////////////////////////////////////////////////////////////////////////////////////////////////////

Function		buTest16( ctrlName ) : ButtonControl
	string 	ctrlName		
	printf "\r\tTest16   Try-Catch-EndTry: Execute from the command line   foo(0)  ..  foo(6)   \r" 
End

//	try-catch-endtry Example
// The following example demonstrates how abort flow control may be used. 
// Execute the foo function with 0 to 6 as input parameters.  foo(0) ... foo(6)
Function foo(a)
	Variable a

	print "A"
	try
		print "B1"
		AbortOnValue  a==1 || a==2,33
		print "B2"
		bar(a)
		print "B3"
		try
			print "C1"
			if( a==4 || a==5 )
				Make $""; AbortOnRTE
			endif
			Print "C2"
		catch
			Print "D1"
			// will be runtime error so pass along to outer catch
			AbortOnValue a==5, V_AbortCode
			Print "D2"
		endtry
		Print "B4"
		if( a==6 )
			do
			while(1)
		endif
		Print "B5"
	catch
		print "Abort code= ", V_AbortCode
		if( V_AbortCode == -4 )
			Print "Runtime error= ", GetRTError(1)
		endif
		if( a==1 )
			abort "Aborting again"
		endif
		Print "E"
	endtry
	print "F"
End

Function bar(b)
	Variable b
	Print "Bar A"
	AbortOnValue b==3,99
	Print "Bar B"
End

// The result ( not showing additional alert boxes and messages )
//•foo(1)
//  A  
//  B1  
//  Abort code=   33  
//•foo(2)
//  A  
//  B1  
//  Abort code=   33  
//  E  
//  F  
//•foo(3)
//  A  
//  B1  
//  B2  
//  Bar A  
//  Abort code=   99  
//  E  
//  F  
//•foo(4)
//  A  
//  B1  
//  B2  
//  Bar A  
//  Bar B  
//  B3  
//  C1  
//  D1  
//  D2  
//  B4  
//  B5  
//  F  
//•foo(5)
//  A  
//  B1  
//  B2  
//  Bar A  
//  Bar B  
//  B3  
//  C1  
//  D1  
//  Abort code=   -4  
//  Runtime error=   227  
//  E  
//  F  
//•foo(6)
//  A  
//  B1  
//  B2  
//  Bar A  
//  Bar B  
//  B3  
//  C1  
//  C2  
//  B4  
//  Abort code=   1  
//  E  
//  F  

////////////////////////////////////////////////////////////////////////////////////////////////////

Function		buTest17( ctrlName ) : ButtonControl
	string 	ctrlName	
	printf "\r\tTest17  Fonts \r"
	// Parameters: all, panel, graph, table, button, checkbox, tabcontrol .  0 normal , 1 fat ,  2 cursive
	// DefaultGuiFont/Win all={"",12,0}       			
	// DefaultGuiFont/Win all={"MS Sans Serif",12,0}      	// MS SS works half: coarsely grained, not all fontsizes make a difference. No effect on button title, Setvariable text, DrawText
//	DefaultGuiFont/Win all		={"Arial",11,0}       	// Arial    works good: every fontsizes between 8 and 14 is different . 	 No effect on button title, Setvariable text, DrawText
//	DefaultGuiFont/Win Button		={"Arial",11,0} 		// OK : effects Button
//	DefaultGuiFont/Win Checkbox	={"Arial",11,0} 		// OK : effects Checkbox
//	DefaultGuiFont/Win Panel		={"Arial",8,0} 		// OK : effects Setvariable text
	printf "FontSizeStringWidth()  gives wrong pixel count for tabs:\r"
	string 	   sText = "text" ,   sTab1 =  "	" ,    sTab2 = "\t"
	printf " sText:'%s'  : %d pixel ;  sTab1:\t'%s'  : %d pixel ;  sTab2:\t'%s'  : %d pixel \r", sText, FontSizeStringWidth( "Arial", 12, 0, sText ), sTab1, FontSizeStringWidth( "Arial", 12, 0, sTab1 ), sTab2, FontSizeStringWidth( "Arial", 12, 0, sTab2 )
End

Function		buTest18( ctrlName ) : ButtonControl
	string 	ctrlName	
	printf "\tTest18  ksFONT and kFONTSIZE \r"
	DefaultGUIFont all ={  ksFONT, kFONTSIZE, 0 }		// effects all controls in all panel except those using 'DrawText' 
	Execute "DefaultFont	 /U  	"+ ksFONT_			// effects  'DrawText'  (used in some controls)
End

Function		buTest19( ctrlName ) : ButtonControl
	string 	ctrlName	
	printf "\tTest19  Construct sin wave\r"
	variable	AmplitudeFactor	= 2
	variable	SmpIntInMs	= .2
	variable	DurationInMs	= 10
	variable	FreqencyInHz	= 200
	make	/O /N = ( DurationInMs / SmpIntInMs ) 	SinWave 
	SinWave = AmplitudeFactor * sin( p * 2 * pi * FreqencyInHz * SmpIntInMs / 1000  )
	display	/K=1 	SinWave
	modifygraph mode = 4			// lines and markers
	setscale 	/P x , 0, SmpIntInMs/1000, "s" ,  SinWave
End


Function		buTest20( ctrlName ) : ButtonControl
	string 	ctrlName	
	printf "\r\tTest20  Construct sine sweep for filter test \r"
	Make /O /n = 1200 sineSweep
	setscale /p x,  0,  0.0001, "s",  sineSweep
	sineSweep = sin( 2*pi*x*480/0.12*x )
	display /K=1 sineSweep
End

Function		buTest21( ctrlName ) : ButtonControl
	string 	ctrlName	
	variable	fct	= 1.1//1.12
	variable	nFontSize	= 11//10
	string  	lstLen
	lstLen	= "9;12;20;21;19;24;28;29;30;31;"	// "8;12;16;21;24;28;29;30;31;"
	printf "\r\tTest21 does not work as Igor's   'FontSizeStringWidth()'   does not return correct values -> pd()  and pad()  cannot work either... \r"
	printf "\r\tTest21 pd : pad/truncate    fct :%g     \tlstlen:%s\t \r", fct, lstLen
	string  	lstTest	= ";i;iii;iiiiii;iiiiiiiiii;iiiiiiiiiiiiiii;iiiiiiiiiiiiiiiiiiiiiiiii;W;WWW;WWWWWWW;WWWWWWWWWWWW;WWWWWWWWWWWWWWWW;WWWWWWWWWWWWWWWWWWWWWWWWW;"
lsttest = LowerStr( lsttest)
	variable	i, nItems = ItemsInList( lstTest )
	string  	sItem	
//	for ( i = 0; i < nItems; i += 1 )
//		sItem	 = StringFromList( i, lstTest )
//		printf "\t\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t- \r", pdT( sItem, 5+os, fct ), pdT( sItem, 10+os, fct ),  pdT( sItem, 15+os, fct ), pdT( sItem, 20+os, fct ), pdT( sItem, 25+os, fct), pdT( sItem, 30+os, fct), pdT( sItem, 35+os, fct)
//	endfor8
string  str	= "iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii"	
PRINT 	GetDefaultFont( "kiki" )
print "FontSizeStringWidth", FontSizeStringWidth( "default", nFontSize, 0, str ), strlen( str), str
print "FontSizeStringWidth", FontSizeStringWidth( "MS Sans Serif", nFontSize, 0, str ), strlen( str), str
print "FontSizeStringWidth", FontSizeStringWidth( "Arial", nFontSize, 0, str ), strlen( str), str
print "FontSizeStringWidth", FontSizeStringWidth( "Helvetica", nFontSize, 0, str ), strlen( str), str
  str	= "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW"	
print "FontSizeStringWidth", FontSizeStringWidth( "default", nFontSize, 0, str ), strlen( str), str
print "FontSizeStringWidth", FontSizeStringWidth( "MS Sans Serif", nFontSize, 0, str ), strlen( str), str
print "FontSizeStringWidth", FontSizeStringWidth( "Arial", nFontSize, 0, str ), strlen( str), str
print "FontSizeStringWidth", FontSizeStringWidth( "Helvetica", nFontSize, 0, str ), strlen( str), str
	variable	l, lItems	= ItemsInList( lstLen )
	for ( i = 0; i < nItems; i += 1 )
		sItem	 = StringFromList( i, lstTest )
		for ( l = 0; l < lItems; l += 1 )
			variable 	nLen	= str2num( StringFromList( l, lstLen ) )
			printf "\t%s", pdT( sItem, nLen, fct )
		endfor
		printf "\r"
	endfor
	
//	variable	l
//	for ( l = 5; l < 35; l += 1 )
//		printf "\rl:%2d\t", l
//		for ( i = 0; i < nItems; i += 1 )
//			sItem	 = StringFromList( i, lstTest )
//			printf "\t%s", pdT( sItem, l, fct )
//		endfor
//	endfor
End

Function  /S  pdT( str, len, fct )
// returns string  padded with spaces or truncated so that 'len' (in chars) is approximately achieved
// IGOR4 crashes:	print str,  GetDefaultFontSize( "", "" ),   Tabs are counted  8 pixels by IGOR which is obviously NOT what the user expects...
// empirical: a space is 2 pixels wide for font size 8, 3 pixels wide  for font size 9..12, 4 pixels wide for font size 13
// 161002 automatically encloses str  ->  'str'
	string 	str
	variable	len, fct
	variable	nFontSize		= 10
	// print str, FontSizeStringWidth( "default", 10, 0, str ), FontSizeStringWidth( "default", 10, 0, "0123456789" ), FontSizeStringWidth( "default", 10, 0, "abcdefghij" ), FontSizeStringWidth( "default", 10, 0, "ABCDEFGHIJ" )
	string  	sFont	= "default"	//GetDefaultFont( "" )
	variable	nStringPixel		= FontSizeStringWidth( "default", nFontSize, 0, str )
	variable	nRequestedPixel	= len * cTYPICALCHARPIXEL
	variable	nDiffPixel			= nRequestedPixel - nStringPixel
//	variable	OldLen = strlen( str )
//	variable	nTruncatedLen		= OldLen - 1 +  nDiffPixel / cTYPICALCHARPIXEL		// +2...-2  is not better  than -1
//	if ( nDiffPixel >= 0 )			// string is too short and must be padded
//		// printf  "Pd( '%s' , %2d ) has pixel:%d \trequested pixel:%2d \tnDiffPixel:%d  padding spaces to len :%d ->'%s' \r", str, len, nStringPixel, nRequestedPixel,nDiffPixel, oldLen+nDiffPixel / cSPACEPIXEL, PadString( str, oldlen + nDiffPixel / cSPACEPIXEL,  0x20 ) 	
//		return	"'" + str + "'" + PadString( str, OldLen + nDiffPixel / cSPACEPIXEL,  0x20 )[ strlen( str ), Inf ]
//	endif	
//	if ( nDiffPixel < 0 )			// string is too long and must be truncated
//		// printf  "Pd( '%s' , %2d ) has pixel:%d \trequested pixel:%2d \tnDiffPixel:%d  truncating chars:%d  ->'%s' \r", str, len, nStringPixel, nRequestedPixel,nDiffPixel,   ceil( nDiffPixel / cTYPICALCHARPIXEL ),str[ 0,OldLen - 1 + ceil( nDiffPixel / cTYPICALCHARPIXEL ) ] 
//		return	"'" + str[ 0, nTruncatedLen ] + "'"
//		//return	"'" + str[ 0, len ] + "'"		// is not better
//	endif

	variable	OldLen// = strlen( str )
//	variable	nTruncatedLen		= OldLen - 1 +  nDiffPixel / cTYPICALCHARPIXEL		// +2...-2  is not better  than -1
////			nTruncatedLen		= OldLen -2 +  nDiffPixel / cTYPICALCHARPIXEL		// +1, +0  is not better

	// Todo: Speed this up by first padding / truncating to approximate size , then fine tune by incremental  padding / truncating
	if ( nDiffPixel >= 0 )			// string is too short and must be padded
		// printf  "Pd( '%s' , %2d ) has pixel:%d \trequested pixel:%2d \tnDiffPixel:%d  padding spaces to len :%d ->'%s' \r", str, len, nStringPixel, nRequestedPixel,nDiffPixel, oldLen+nDiffPixel / cSPACEPIXEL, PadString( str, oldlen + nDiffPixel / cSPACEPIXEL,  0x20 ) 	
		str	+= "'"
		do
			str	+= " "
		while (  FontSizeStringWidth( sFont, nFontSize, 0, str ) < nRequestedPixel  / fct ) 		
		return	"'" + str
	endif
	if ( nDiffPixel < 0 )			// string is too long and must be truncated
		// printf  "Pd( '%s' , %2d ) has pixel:%d \trequested pixel:%2d \tnDiffPixel:%d  truncating chars:%d  ->'%s' \r", str, len, nStringPixel, nRequestedPixel,nDiffPixel,   ceil( nDiffPixel / cTYPICALCHARPIXEL ),str[ 0,OldLen - 1 + ceil( nDiffPixel / cTYPICALCHARPIXEL ) ] 
		do
			OldLen	= strlen( str )
			str		= str[ 0, OldLen - 2 ]
		while (  OldLen > 0  &&  FontSizeStringWidth( sFont, nFontSize, 0, str ) / fct > nRequestedPixel - 4 ) 		// -6 is for trailing  ..'
		return	"'" + str + "'"		
	endif
End


Function		buTest22( ctrlName ) : ButtonControl
	string 	ctrlName	
End


Function		buTest23( ctrlName ) : ButtonControl
	string 	ctrlName	
	printf "\r\tTest23 \r"
End


Function		buTest24( ctrlName ) : ButtonControl
	string 	ctrlName	
	printf "\r\tTest24 \r"
End



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function		root_uf_acq_co_gCOLBUTCOL( s )
	struct	WMCustomControlAction 	&s
	printf "\t\t%s\thas value%2d  \r", pd( s.ctrlName,24 ), s.nVal
End

Function 		buPanelPictureTest( ctrlName ) : ButtonControl
	string 		ctrlName	
	printf "\tPanelPictureTest\r"
	NewPanel  /K=1 /W=( 10, 10, 450, 350 )
	DrawPict 	10,10,  4,2,					ProcGlobal#myPictName
	Button 	buWrite, 	pos={10,35},	picture = FPTestProc#Bu3WriteWatch3, title = " "
	
	Checkbox cbW2, 	pos={10,60}, 	picture = FPPulseProc#cb6WatchWrite339c, title = "kiki "
	Checkbox cbW3, 	pos={10,80}, 	picture = FPTestProc#myPictNam1, disable=2

	CustomControl ccW2, pos={10,110}, 	picture =  FPPulseProc#cb6WatchWrite339c, title = "kikik"
	CustomControl ccW3, pos={10,135}, 	picture = {FPPulseProc#cb6WatchWrite339c,0}
	CustomControl ccW4, pos={10,165}, 	picture = {FPPulseProc#cb6WatchWrite339c,1}
	CustomControl ccW5, pos={10,195}, 	picture = {FPPulseProc#cb6WatchWrite339c,2}
	CustomControl ccW6, pos={10,225}, 	picture = {FPPulseProc#cb6WatchWrite339c,3}
	CustomControl ccW7, pos={10,255}, 	picture = {FPPulseProc#cb6WatchWrite339c,6}

	SetVariable	sv1, pos={30,275}, labelback=(55555,0,0), noedit=1,size={100,14}, bodywidth= 50, title="XXX", disable=0

	Checkbox cbW4, 	pos={200,50}, 	picture = FPTestProc#cb6ScriptEditHide354, title = " "
	Checkbox cbW5, 	pos={200,80}, 	picture = FPTestProc#cb6ScriptEditHide355, title = " "		//OK
	Checkbox cbW6, 	pos={200,100}, 	picture = FPTestProc#cb6ScriptEditHide356, title = " "
	Checkbox cbW7, 	pos={200,120}, 	picture = FPTestProc#cb6ScriptEditHide357, title = " "
	Checkbox cbW8, 	pos={200,150}, 	picture = FPTestProc#cb6ScriptEditHide358, title = " "
	Checkbox cbW9, 	pos={200,180}, 	picture = FPTestProc#cb6ScriptEditHide359, title = " "		//OK

	TitleBox 	tbW1, 	pos={200,200},  title = "  kiki  " , frame = 0,  size={60,80}, fColor=(55555,0,0), labelback=(0, 55555,0)
	TitleBox 	tbW2, 	pos={200,225},  title = "kiki" , frame = 1
	TitleBox 	tbW3, 	pos={200,250},  title = "kiki" , frame = 2,  size={60,40}, labelback=(55555, 55555,0)
	TitleBox 	tbW4, 	pos={200,275},  title = "kiki" , frame = 5, labelback=(0, 55555,0), anchor = LT
	TitleBox 	tbW5, 	pos={200,300},  size ={40,40},  title="X"
End

// PNG: width= 301, height= 15
//Picture myPictName
//	ASCII85Begin
//	M,6r;%14!\!!!!.8Ou6I!!!$O!!!!0#Qau+!'ZPU0E;(Q&TgHDFAm*iFE_/6AH5;7DfQssEc39jTBQ
//	=U""[#35u`*!m@2@<+u'MH1Y)%_n,a2"*aioufCf40Kic>GE'\GnlgAU3?mLsQJ/=ZloO)Xo`2$.qO
//	(^C8<Rc.Re/J''H\Q67f<nN!(o,4Rnc?nWlF8p8QjMmArK[@ak34?OX3ul-eTG_f=^L6#kB#[r\:/<
//	)G3j#VH`Q.GG?Soc@qTjm^HJ5(NA9h1fat1\+2'DKNh$Sf<OkPGaUmEVEQs<;Y7[(e\M5EuKMK.<Gk
//	r>r.Uu.ArV"u57Qc*YYhlIA]+^^;@745>_HNcY/)+htGI2FS0WT([o]Ct$&=+Applb.T:q%''SekIa
//	n%7[rVnnH#dV/sVGZ7J3DC&<9D\!CDmVXTjgV=*6-=Jg%FnJe7qs5PJF>u!0d4N'BZ,Nt;3+7-6Ckl
//	OKdR\`k[Q)hD-VSHDm?$[&)Mo!@]oY+g$.E*i[o.AnNPl4(U.,mm+0AH(o3dJd%JZ[s8#t/8Hrf-je
//	api).P0A9U_N'0\\-.+k![+n_kY)90Kp44>AC'Uk![+n_kY)90Kp44>HTn8S2o!dm-lE^H$b$p;(@N
//	S*k\_YP\QIumtN$@igb+uF.CfhB]ko::2;Q16W[Ec&%oc->?5p4L"@J],=s&(2fFjug/47E%nZ^7M+
//	N,5MK4EHG.+PkZ<(CEL/&%l?uuQ#a4$*RZf*'uCC^d;Pr5sgnf'o0r@gQQ:E/G[P16(hf)q^ST!N."
//	8:9_"B4N=)lZe-AFhBG-+a>"\&rC&f)aaPs+`2k2/J73A1"%tIg(Js#)C+&k_5@+%U^"^7'd]E!M+H
//	B/fFfM&Ti0SK_j2^E&!_l\c2OpsZ57jMeIPNU@%^GCTKGCE'InJtVslrs4NjKuNtnM9;c7!Aht[La/
//	LRdrla7ot#6Qg)3q6AcSV(Lm:-EDr1Wi[rTghF12i67Ne*sX-f?`=ejYT]L2FI+h<ol\A,_!Kkr;H@
//	[%BC-K+CI9K&cl$)M`<!Zm@glP_[.S@YX^1fI`%$BJEcl-):S2R.88'Sb(1a;e,NWC./?_gUs.:fAl
//	b`CnH43*Opch9gHkl?!!#SZ:.26O@"J
//	ASCII85End
//End
//
// PNG: width= 41, height= 15
Picture myPictName
	ASCII85Begin
	M,6r;%14!\!!!!.8Ou6I!!!!J!!!!0#Qau+!;?/,M?!VV&TgHDFAm*iFE_/6AH5;7DfQssEc39jTBQ
	=U!-q.(5u`*!c'2'4!$MV9[q-*4dH>3?+c,o%C5!*/"ki)q)?bAToQD+UH@l2a3IL1&%RTlh>F>jpZ
	OkW4@?*e1;68O1jXndeT8.@b9l9[.<'/(I&*`HT]^CB'KY4lRl7@,0C;5CajRa,WF5?Q!'QiZuE`t[
	Gr^UF=Q?tFg!!!!j78?7R6=>B
	ASCII85End
End

// PNG: width= 355, height= 15
static Picture cb6ScriptEditHide354
	ASCII85Begin
	M,6r;%14!\!!!!.8Ou6I!!!%0!!!!0#Qau+!5@DP,6.]D&TgHDFAm*iFE_/6AH5;7DfQssEc39jTBQ
	=U"9D(^5u`*!m9;kl'2]=4/V2asC&Ys2[`ou95Wr-N+Xs@G(5#H"J;=FrqA5TYLE;*a/4cF#,!u#Nm
	BN@u/1h^cb<F5n&fP\?&.];,iQ^Mu:"mkSV>1U0hn3kT_nMP\]ZFBUF)_BaQ2;Le#af)2Y3UQt^nGl
	T++F4AmIaDba,&MkG5^AU.^ACb>A(0/?BG8=6EtWSFQC#Ng/dG\KI@O-19VFMV.R'%[RFf$_>AR@O.
	U<%DroEU8;I1UGCOODo>PK*//1b=Ed;5--!dR1QiXD3/2!c9e517:rKLXI\?<HU]=YM[L3&C8;!MFB
	TL6b>#(qL)*2X`6BK/sq*/fL^6ASgI"p!E4gMq+&*C17D>-6s,GOO=65h!ZLjrpR$X&V2s1`FnZ<IP
	G,gh8Mgmu:ir3Ih),Q5?+`di[J^I5q!/!&R4@^0dj=PbB;^Zq0u+0/)<=N>qrf4Km:MJ^%M`=^4jjB
	p]FL=j:aV%I"TF+TtgZ=Lj,oLf@^+#pI/>Pk'2c:W\L4E?&Oj!UAW?1^?;X"Mp>SQ5i5IDQhBe$0)@
	9616GG`R^q+525Jtj[1q,'61lk!=aKf,1+O`pWe_!-nm[g7mar;mI_97OMp21VhmF:N\R&<8h``/R:
	@LIYA[qqV>5LF?=9_,"G^D&8g,i<N!eZCC-XqP&4a('i$BR>E%($J(oue`6`a[pE_;._Go6%+*B+[S
	8m]G-#7=TDEHad8;aS^AM:KDl;1&I8fj\pkGeOc\.5VtN-)u5Ee&]S6VmjibIMX:uC7Za82\_LrK:/
	kp/hO7eq-B4mCkX:qklBge6bt'*Sn[7qfQ4?]!Ydt3Me!%-dfIT+hp?0oP4O[s9Q<Mj]YLH-\-b'>d
	=h3<8k2fUedsZdMV/C:Oe?eQojeLT+l>g9;p97!EPl:8!gn@bC;ER]&P>Q'UtIcf5lZIHr&L2kPi>#
	:N#53Q3B281.mA5((cn)cJ6ddu->t=%4p@9d^(C[Xh5X;?&P?PiJo;S'?Be)>hhZq_>8<8sRZ7s0N6
	k74a9YP.eQ,*a\8Q&H4#u2;!$D\;f6($i;qdTNJfp/Iom.VYX>l(BrsaGKEhi?n/X9-29V+Emd$%Pu
	p;sr@#67RQQR?=6(<2<kH(OD0OmX)]UMi],aC($id?k].h_#46IcR"#%F-P<qj6+f5KXE8Sb#b[a=V
	$VHH;]@J[Jg86HmrYi5qa:N</5X:?UV1^@uVpHos^d`^.:E`tSGV>?bg2@g3ja^ULP\H95tbb\4I]k
	^+Cp4_3je[`^1kq7EF/_;;X*&_9*UlO:5C/,fQoVII39UP1/t!!!!j78?7R6=>B
	ASCII85End
End

// PNG: width= 355, height= 15
static Picture cb6ScriptEditHide355
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

// PNG: width= 357, height= 15
static Picture cb6ScriptEditHide356
	ASCII85Begin
	M,6r;%14!\!!!!.8Ou6I!!!%2!!!!0#Qau+!42\sA,lT0&TgHDFAm*iFE_/6AH5;7DfQssEc39jTBQ
	=U"<:!$5u`*!m9@nP'1!=]>6;crNAUD@Ci7uIEX^H-71bW6MUZ)H.i;+Qi",YhG\JcOH4X8a+FslV#
	i1uWa+j;nZsZ-P4.\U21u8?Y*X3_(]ZnYIEO2)#IYY0!p7'aUc8T\!]^/gmdpiBVgfe9J_%aeqD>3W
	S2N;d&n'd'[=YE6o[)gL)Qg[$J/]QUWiuBsJ'pgO["b7!]'T/acrI*G/@s1QQ``Sp:imFl)/2`pA\3
	87B*T#K+>e.V8]on<.,8GOfh4<rX[E$SoTMR0?5e1-+=BLC60+APeMTkElgeJ;HpZE&d"TVZ5D/X9.
	/M/Ot_m1hu6bhLpS!IXYqgJH*kScF4Jg69k`c&j6A#r_3!Pl^p7[Pg5_t1NAX7^0!`q>h1`F/5@\L5
	h*eZ.8<1`FnZQ2_=4\^>'np'kPI3IcMXiWl$<U[R*S^>Jl5KaH@R/!Z"AP`1hB#hO4p5o?Jb!s"AAZ
	s#%8=V[@X3GFodBctW9rc`3u<NJ<1"TTF[(hOPNbPAl5*GC&F)"W0Jg[k6R8<tfmAP$M\i&DG!aI_R
	?Si>ca-3[n\He+s[Km'&LTGEN1b1/e5T'`-B(h7"&MD0rkJf"QriBVB`lC/Vj8C36I+sLm^VJ-6/;;
	?89YXgK47Zc,a@"`K_@OOX<ND-!&T?m*2>juFCVXOE;85fraJ@ruo^i:bGbfGNj-B2]T-I54kUb%`h
	0rG`k(C=M>*X$l3itb!E`=Kfg"c:Hm\DIl'(C;7/.n0VR8(%SMZg".DEO6;t0,.V!Bl2<F/ZsS.r*j
	l!9RDVL^laf`obKojd:j9W(ak\_TsU.Wd$@3Jd%Go4EJm+7ii3dG5;%CWQ3)V*#V;Ml!&Q*s?.+I:d
	h/uGK&ah;T[A=^8hgeiHdmjp-rR`W9i_f>oo%mbJ>"+944RjF+]</F&hd-fE*Vmt568]&\!k]CL4iO
	j)!Ypp0Mju][#_(U6:s)aM2=--8O5Yc?K'!N5Z@+S!3@LM123G5eh<sjECD,u]7_=B.AX85#eHG"HW
	4`W>S.:[Q7r@`Pp@NO8>/#>+<r9XW?mKg:i.VX4)/V7!9!agD;-fEM62aFT',Y$HG'dg7_H_Gru?LX
	A@;-t[:l31qg@\=+MP&0DBHT@[p(JO-fpd$g:6'#Np3R"p\djh2Rk6.^3g"_)2o8W9u[A(eN%'\?Wn
	7s%d2u\^%:ZV^C1SPSWb8uaN\?,]#fumJ?c+>,KB%OE:<5#_?!U>Dd&^\A,cGJ_83s@*#o^dH6'a7=
	C5ErgDrH(iLTA\`PlV4];%m.I40P/@b+7K<=ohQ.eraM<r.5Z6nn@.7"fP=ff4`r;?`*tIfU3$A]l?
	VPAL:"!!#SZ:.26O@"J
	ASCII85End
End

// PNG: width= 358, height= 15
static Picture cb6ScriptEditHide357
	ASCII85Begin
	M,6r;%14!\!!!!.8Ou6I!!!%3!!!!0#Qau+!*I>5B)ho3&TgHDFAm*iFE_/6AH5;7DfQssEc39jTBQ
	=U"<0p#5u`*!m9@nP'1!=].tQ]r7N2102RdN53<ncR+p^b+7;=Q5'b%$cn-Amo]JLE84U<WAO?eLfK
	^MRg@mbTG=tlV9*R>d))K13=%ti2:hI^A`\Co)L^I-Y!qp"J;kF8r!??WHraUnMPDQY\5@#ACI[ejb
	DS&RJ$qsf+/ZkoK%>3+hO9=OAJ(?9;<E=Nq`MMmh(E(^B8$H:HMhO\T=EOr"LA#rKXnGlW=QC?'1g`
	G^2%W?9&/Dj[V?I$OWOUAe.me55OlD%tl:ahV0TNj+qcd0Z!QNdam7:p-iDPm]5qr9c<K#=m2HZO7L
	EH1N@ag/iKrI/*i>*d_-p\F9NbMWX5N]:2Zf,8(WZ!+76!:/t:@CjAecgt>Bf#*d=f5B@Vj2Hf9Y"5
	ToX(&E_BN2$4r]=fS7\^RJ2it$#r;QAQ+*<MR^O?(ODWe>?.9tK,<%:dE1/_9u>hA'B@@14.!'$"fC
	:1if<Ff]RV.gjDJM=G+hmL:#Z2EN+[q$=cQsX6!kPII:TpZs3bkHO'cfamD=gD.q-(U<Oj%r8kH_0D
	GhNXq/'TB<bBohBmg8RDj=uY/<=2u>-[X6_<N.jhU_Q7AV@MI0Y"N=NCDdlZh5q<S*LpS>nShAqu'_
	blR02dai&QCV6(a7n7(^^jh,84b8kO\TOf0!6@l2*Y'dR6Ga+E-f_E#_IU1U<^Ifcs\)a\u+T.37ME
	9Q%hc77*B(#6>q>\CV9fnUiN85pGnIDLBC=77,(4Mp]>nOgG/,lolhC9Pjof%)lO?>2F@$M]i)P^Y#
	)!dp=4AE9&91^"3g0FQUMU`]9p\..&;n[,ho,1bPG,ghT`E\?Np`JErhjV-"iP!m;tu!0%A"QaEI=I
	7umF_'*;^ci?@-V&0GprG"abW)WaqP8+3h/L,O<?mnS-:Gl9@Lfta[KT$W.*9V_>:B3-#YV,,g6UIf
	!%!=Hs(oSNBg'?+Q+f-.CoL,1]UnFA,Yjg`$TIG?l!*0j:RC)0CCDkWr\0;QK?-\N=(/bl>"Pm2.r@
	53'Y)%a>b8Gkm.[1KDYY^ifO:d_=e8e#$W&>@=4TTD%!9!agD;-fE\ZH;MT',Y$HG'dg7_IdeIiX";
	Gbt-+Q"ZffgOAG7+MQ"KDBHN:]2L>K-fpd$g<eb;Np3R"p[(bY2Rk6.]Qh[Q)%7:.=iLX4eN%'\heE
	sY%d2u[]sI-k^F]oqS`<';aN\9*]#fumJ?c+>,DPPeE;.Y@_?!U>>--#k&c]j]It)q\%ZZ*d]oHG5X
	KAVDm>`7OnFkGQ_SXj5h9i"R4qPI`1$^0aWe^pc(&1q#Q%$gn&^:2c&RjHh2U5``<.Q4Q&"^dPbK#n
	u[/^1,!(fUS7'8jaJc
	ASCII85End
End

// PNG: width= 359, height= 15
static Picture cb6ScriptEditHide358
	ASCII85Begin
	M,6r;%14!\!!!!.8Ou6I!!!%4!!!!0#Qau+!4N<'=TAF%&TgHDFAm*iFE_/6AH5;7DfQssEc39jTBQ
	=U"=-Q,5u`*!m9@nP'1!=]>6;crNAUD@9Q&T)EX^H-71bnS'rf"l<\U3+_&r:[nBtQ(oH:MK5lqc6&
	\9o8Nt(JfBu,=+G!(+BBtOa=4:FEoH(13rd`lCQr=39!m5MA4ST!E"H.fH+-V"/5>V:$A@>r#>F$Au
	!1Nj8sIXL$:m6p0!&Xh>Edd?qa/2!7h+C6ue;8p'J<H79o<FK<pV#VX)0C8)n0ufs[c32F</mf/E/s
	e6@lh.2>1'8QRhV))B\!k$oM:s0p3bRjIXc:k$cN#)S0.\_.!l3UH>h"3?0EJ1E:!Z5p<)9lNHq.0Z
	/B6?)k2sOt_EX5qac(,Hqd0TOl?9f!\(?ma":[jB/Vs.kF3]'-;?;=@p%9G5,)>KqNCMr:l,NCc\)`
	Y@TtW&+b2oqaXOV(IE`r>6)S&nLq=aJm)EGQ^r=fL=j25eB^V&=sX98pOEJh`0dSu0ijpT4L`'Fs3O
	TPTlD)W@BLpJR/dkf-'p!Q*effXIq#Z[rgGUY2&YnZ@@ZOG(G4O:o_2!*bfH_)VOfka\9.i-=6Pd:^
	9*"$7ff6(BN*V92mJofd4mEdE%3*Sr#9?0$^qTqUU[SJuTo,oJOO@NK**!hKh6$$)k4#*a3?k`o98D
	6n+;,_]R`i[jJN!.%.!+Cin"pd6rqEfG\8GQGqfrR0K`uZhboK5ndBt@^m:c-,s3"@5;)*+ReBd?ld
	.<8B)-nc<0b];g]AO;K@HN@LK\EK#MM1ZqE5p;.5Y(5TLAO=3*9<<]NUM'c+=b]cDnCmAm)Oa*Mnq>
	Hs>E/b%!p&e/R.c[L^*?DdoSX3I7OM!'Bq/e(QdT1q_,r`q5XPY-j[BE^aNq:7"Y^'UZ4[W]Jo=4l!
	^K*Tg(eI<Q6E$NL4@\i&i<));[J20B'gL7?E-slojeLt;qIDL5gU=3C8d`*+cJZ*TgXkC(E=7hq&]X
	3X_1@r.=FO^JFmtB5nN6e7)mj..%qn,qBX%I_BbeIjfm\(JRPL3!WZ7=I$q>A60fH=U:DH\-G-XY'J
	G]FPRP.EUha%Hd9I7irK]?hTbK&oYBZa$V'.'3@8]`;^7a3,9_W5-@0(oAH&T!6s7A3=#M4+;Dm`aP
	J671##_*kDrjYpQqF\2Wr`_X9FHF9.C,QUZ]\O/AL5l@pdD<9Y\>ph-DaTN<&?:!GijH!E`_mX,`02
	&RN)pgK1&pTG#!/9B9m=n:A,\JK!47as!?a1fNmUS0D&Zrb$8c5ANWaRp/86(h<QIY1F`Jc$U$V7:L
	[O)>W)ft/j'Z_@/S]LR5_lhX2Wj2+7I?*Qc/o&p6]&c&L-ud86`<?.]k/R;?:.&,G;fjSHX=TTHrV=
	[NB`W%B?B*rZ2"A"!!#SZ:.26O@"J
	ASCII85End
End

// PNG: width= 359, height= 15
static Picture cb6ScriptEditHide359
	ASCII85Begin
	M,6r;%14!\!!!!.8Ou6I!!!%4!!!!0#Qau+!4N<'=TAF%&TgHDFAm*iFE_/6AH5;7DfQssEc39jTBQ
	=U"<^9(5u`*!m9@nP'1!=]>6;crNAUD@Ci7uIEX^H-71bW6MUZ)H.i;+Qi",YhG\JcOH4X8a:]_@E&
	\9o8Nt(JfBu,=+G!(+BBtOa=4A:0`o/8CoVV04iq]3Q!gM^\2GJ8A"k&o9j*?>,Fl..%g$q;)BD7cF
	KY\BWFgE/B/a.4(Gd3:B;T"jjsS&X8miuBsJ&sk4XjVHUZ!?_OG\U7guB8<rd(6#M'^;+5`/mkR/lZ
	%9I#<KN&^:J95.=EKU[mqoi:>-ZQX%SMG"$eJG-l.^s1Ga#4V84!>+uM@q[o5H;rp_!T+i:O%HYmV:
	DJnm7ag+<(\(gkbK4T2;?2iUE@Q8sk,E<Q%%q(>N`[[5\!3E9'K]s+24O7e")NPYP>ebPg$lL/PgEN
	b)/rRtXX]@'@q/<I!CUI>Rha"')oD@-8IaC.2s7Z-/qlS1R]Pq/c<%:I6a[g,sE*\ePKOJUU!8oh3U
	X9(*-'=XdP3/^0!5_Fk\I4$_@c?8rDE5s!(h8qE@"RS=55(dT+(NOhI;[ACZQ`PX=I(8(Q%7mk80`J
	QkBYp?Vk=`_Z1`0mAf9;/6\8K)g:::?*dY8CggQ.UZ]$S2>(RRsZp?ut<pDb)P)u>:#fVmY6+9])GV
	kAkY7;EV#0.Ug2$u<1cq2S#L+8-]TJ`4`ncN.jBYgS7qqO`k%IJ\Ya[a-d-m?gUL4X$#BYc#k;rLEL
	.;r[i.h40E_MfH?I,O%^6Ti<u_Lr,MbaZ*E&dK3Z+nmWZ"/eU$#5#52U#^8,7W?jRCc\@,:)C>U"Y^
	(8h>&em,n^8L*[dmF*?pKgT/bL`dkiqY]gRI\F<Z<k#.0;X%VcU-[MT0%"AlB<%O=AK8S&;q6Nc$g@
	48Q-OU36lC((@d,Nu*0K0Z\i*Cacn<C>;I"[Q#;(r&>_(SkfER]IW",E/<aN<C%8(OZ0OJCoc_'7*9
	CO=DB$SP9Y"l=Z7Q8JN,=UdL]KBN(9$'XSVkSid98ePH7].RP>B(*I9rK3Asj7)F282Pf>d<0n4`pR
	-.#8hGoN,,)3g7NeLY,m4r9'W2XU"=9"BBd40g(lGka9GeNFpqC\$G)ZIqej]njoD!73=p4mNh?&AF
	%_m7o=F'UDZq(-WTNVKX>@,S:hV36Y`F:POf2U*d#KLgXQUJLTL2)FY-1UWh)f@Zab7!>6?^Yn"HZ`
	(#n^lVdTYm2^FQ]G_iieOJ5jNA2!&E#;;f8o$3+/g5d"ii,(>QM`YAaIf+ka!Kd/j7WATr?B\.0"-C
	:/p@*@risa6em.kjZUglKmlF\D>Q-g"aL6:s?Mg`]7k$,c%WqXQ5l&+i2qE*'&ti_o=]QO<gX#nHUV
	2B?Be3_n?$M!!#SZ:.26O@"J
	ASCII85End
End

// PNG: width= 361, height= 15
static Picture cb6ScriptEditHide360
	ASCII85Begin
	M,6r;%14!\!!!!.8Ou6I!!!%6!!!!0#Qau+!3*l8l2Uea&TgHDFAm*iFE_/6AH5;7DfQssEc39jTBQ
	=U"<pE*5u`*!m9@nP'1!=]>6;crNAUD@Ci7uIEX^H-71bW6MUZ)H.i;+Qi",YhG\JcOH4X8a+FsfT#
	i1uWa+j;nZsZ-P4.\U21u8?Y*X5ulH(13re,>R"G6g9K^6sE*q=a3Ff3P.uF8u<+>K_s[LbVTPZp-L
	SR5fu25CM`9pET<#Mqi,ln]h5Q`r?B5Wf#_cWjm0H.^teBaU^-,:ahWQG';4H:GBcq`=e5RKjq%3C.
	7NP*pE+Ek5*O)Q0ac@e/kU95O!$%Y-0s:%KM2lWE_(%c-8]EPTCL2MTk]de4pHAn)k3\K`o:Mc&I^B
	KnY4ZP@99+_-lci!5fW^#5i\tq/?NA8"<<N#64a6N%nA6eGruoD9^CgaPf*R]A7qCI,k(JgLB+9f\.
	*TeS8*#2B%Qi[E<uSc.lth4NDb'[@BIrJ+80ZiVrRi?f*fW85[:5m7O3!2'jKDH,@",Ic-!\jT'gB=
	m^AOP,sPboSg.N__g:a2:#PI>STmB?ZF8'hSC&H#3L98lf)<@">[u%fB)^R4ti'FMd[H#Y6:AN6CQS
	I*63&.Srlo)`d5[RRW3#m$jgYLBpW0IJ7rli\Bc#`PB$B.YpG4b5T:UU^!bPi;2#.T814PfL?HQk$B
	Kd@!-R3j0g<l*YF+5VTdRfM#[//b:MW.dk6H8'UBR-ilZ+4E4gYmn-D(>%T`dS9-PSDB6jknued?'4
	<-]/K??("Ji+M1\^kY-l6c:U+i$Uc\ADY6fOZ9mBn@>;c1iRR_D87P='1tGAD0X)2`AU,qcfsgK`W?
	POic'??7u7ApR3r=+D2:`X9.6r%/iLsRkpV[e/ZD:6!<VZJ2M>8P4'[^J(^MNm$47E^Zd^`2TE,,]O
	u=!nP;'E'*BV7DN>/`M`Ag]\B`lLWV-9jeX<8qV*Kq9L7Y4Si<Ke/Nd'OBUlpu-4EP\D8#`(j=CJ%A
	?&Q31NUtuf7TRJ;'+'E#=8jLl4M`.+t5s`\)rlJY:;_&"OX?LkaBjlVE4/bSf7O1ZNa[7Om80obuFR
	r)u[+(g0,8*HtH$DY*B7a2^6d__Q,:Htu9-0[tg/'>ER+a4o^i`r31aDoG\Mco:Nl-A4of<'uiq5V4
	kO=BWbI(ud7=4gu&ZTsr^)PYfm(Ii!/=4Og\Yap97TbtAFB(a+?E$sE>SU%A^>YC,GJc+LnG>!kB[=
	s10n41L"?N'Bc1XqZ0n1>e!4ms_!0E\p-KlXXQ3E+F"WB+=7tQ)3(DRFQ.VP0r4Z_NYZg@,J#3aujT
	O+h^QOBjpX&6L(#<KN*\NW6-/S]M%k]HOfH^7')@7XB14Lcm)[r=h5*Gn&4mMD',n\;r&WZl[9^8(W
	7&*.BF:H$fRz8OZBBY!QNJ
	ASCII85End
End

// PNG: width= 339, height= 15
static Picture cb6WatchWrite339b
	ASCII85Begin
	M,6r;%14!\!!!!.8Ou6I!!!$u!!!!0#Qau+!7hdp)ZTj<&TgHDFAm*iFE_/6AH5;7DfQssEc39jTBQ
	=U"/\XX5u`*!m@1@Uj=h-1-bu$qa'Eo;m0B/8PRjF>(((T^&mo&:#;c\np^p.L2d>/<:ishp_p-H[N
	ak/2P=Tsc_:Xr*g@<C3*,h[<!e@kb@BQ8XaAV[.Gl7bq[Q;AlX7jjb.WGXGl4hdYICRsH2?;)\bu-a
	OV<EbZ-g:/o(:$"%m.Ykn49L,FY-lj0.Fs+_idZ1c@VU$HWTtJqr-81QJ%V7SSPJ$JhX;QTd-[0/G<
	*&d*Yr:1FFL"e!&X`Iq9s5&^tt"3B?7E&gV_#!+A"33YAQ'fNSX:.!6K,^V%chIb4BE<SbhXB3naGp
	PHj]V)L/%.>"XWps&CP9<WI"7/H?p"X-+D.E-6G#MlAJMc5+(Sqi>[J5/CUPk>)EaRp>^21VJmN7g4
	f%OR)03+!t'M$5Qbe6b^7HpBm,CLZFliDI;LRgh;N3`K"TPcPUOA1)&(q)<n[^.k>\<e+5#J3uch\Y
	;GNL"W3E9nf_ZsTCW8qm44/W<rn%dYC$Ti]U]LJgK,;9`dU:\=$DVdgSh4QY#4%9#*c0Z%K,2`?),&
	R$pArMK$j%Z$-BV>9=P4e=7!S5kLI1MakQ-/^\i'GMObRN]R%%;H$c+NQQH]EZ1F]\f5c%?B<UoH(C
	-:t$$BW,<4??Hhm-_*Z::CE1?a3VNR1i:TnU8dp$bgkUC;mZHY7qO1lrd)n(itEh@cYNEjk-Vm)I"V
	n)S<2TdUt"Vq?fC]NE<FFmRc1)+&*r`WLY>nCYPC9t(i+G3?SUXKD;)I4U48ha;5:0#-A#`9-GlGol
	?iF>ckROcOp>MH]Ne=ad^q=a`nB]GOf-,=u?3p(TUSI%KV5dlpYVq=@Q-r=TS?8gSs.i3CN/G)-G,'
	*8?">bsV[olf%"ThJ_LWSUDI+d@fkp.S#%3JS&>_WW:AcDT$>%I+A70jK/M'H.,/WsaauZ1<Hf=cOg
	3?Qb$G%k^(W.2YD;Ep<;-k,6K2_'n7.Umdo:bGo`=F"umK$!AhVFcm!ekJs1T)2[]-H--_KP,E"4B>
	UQqN"4h4\e'-Ja]%OC:E%D;aYW)^HjDsYPJ>CMM8J_U?#_%`JL`7lM,Hsi47M^I#GmY_$>-q6!s#"%
	;X3u7-;/oL%Qr1E0K]t4F1YKRBQlJE-@R4*7_=_:H#A-1Y$N`Hoj'^3$C:7./k&S88p(VNeDh4gpo`
	I\_;F#pF&`H+z8OZBBY!QNJ
	ASCII85End
End


// PNG: width= 339, height= 15
static Picture cb6WatchWrite338b
	ASCII85Begin
	M,6r;%14!\!!!!.8Ou6I!!!$u!!!!0#Qau+!7hdp)ZTj<&TgHDFAm*iFE_/6AH5;7DfQssEc39jTBQ
	=U"05!]5u`*!m@1pej=h!-h17TW*UIX>SIa?YW?8nbY&FA\6/i8%rdYB."8k]c;(cqFq4VQR4W(i'-
	;C%)R^Q+d:mFW-NeLt):,@UT)?@pcKW0PA,'20'j7O&cRc4H7(<t`6<8n6A`<iPaqf&lJY5t<!CREG
	_F=qm6km9,]\<,qU@(4kk^aT8JASI)@<A>RfWW1pKWNk"<Ub#0goAfN8rpalBFZOepH,"jAX6U[PBe
	H9d``C*sN(f;X%fcc\g]%$8BtN53mm[1Jnt>A^J+6#SalW?K/S:ueh<Y.bg?hU7WN$;jk?%2Ek3DLu
	g@j`oU%8+2][7Qp<>G?-mp,Ci!,05f!IuZ1.]KBIXtHnl4dCfL$%o_bpj!>L/,]<mp([&9jLS]il%N
	A*-s.aG>h97/Qs;d&=<rI!q"F:8.niu.1<Cecq]bFf#"*MdG!&-@L2_L]A;FVN`'Y=V(+)eSk>N:C2
	R%%*C"0[#BM%p?9/'C1k7)7^<uQ4a!a:c#ne*?k3uch\Y;GMQr%6#sq.L+RUTjU,7X=/.:p+t"n;m<
	fNUk@<o^&+WXa^:\Lbnd>Pi`3$G$_QIlJ8W(m<--Mrcn3qSJU\+HFGDMH_'Vl59@OJk=%HcjQrVd?K
	^>a%^%f:MSKLrDT<[0@E!V&NB/#(0],<Y1<(_RPemXtn53gC%kVks:'Tm[KHAJ.h2QL4,6.KFGpa39
	EM;&I3nn^(KZf>h)U;Q*PnHt73];+QBWT3mTWbdd<g^SbQ42X<gmS[02so.N&t/>SK]_\")h(=khG0
	@!dFbQrI'qfW+8YmP[A%>GouYY)l=6jRV3TRoOsCgVVq>/8o2Hg#p5qJZT;VPDQZ)qd/,Af#Nboi>-
	2&!a!t$4Y97<DsmBeMi:L)hWhG3q\o#(]Y1.8dF_hKOOpdp\@.5YFb3e]N8jc>']K491MP"6070;Qd
	-1`Q2k5r(I1I.THr:?-BZk-4!Gc4Rl@i9[8.T/uSDG(=WskaW(%)u&YD&&-@#4ioJka\VKg,Q&f_?.
	[AT:]2+NjGQ'U4?prOm2/V=o/auLjTBl9S`E@Lk:ZtsGL<S'&H0Cu"_=I;<n!**gWa&?XgNlin'(h4
	(o+LQICMjH@&!f7F=%FB_^hQ1DYaD79j`m^M4Y+tU$7?mi8">&>J4"[laM2I`A!X.l!3lADcN_)6Tm
	X-pi#j)!?Iigk3?0N9)nql!(fUS7'8jaJc
	ASCII85End
End

// PNG: width= 338, height= 15
static Picture cb6WatchWrite337b
	ASCII85Begin
	M,6r;%14!\!!!!.8Ou6I!!!$t!!!!0#Qau+!'/EQ,ldoF&TgHDFAm*iFE_/6AH5;7DfQssEc39jTBQ
	=U"1(Qe5u`*!m@1@ugFs1(:Ph6sBBg!U&_J1e/QpiE7Mc1&![3&T,tNc$Cq'Co!/!L4s,^'U_o:4`8
	Pr!8U+AP_J\mL=kofPA4H_1oWWI^qAcnA,C5>PPchEb:!,.7*r3pA=NhR.fTII$@NUK*G/XK,SYNpK
	aYB27?@ac"?"QMgC%fkqgH3"#8bslJ3Y$)m2;D^:+6I5CmO557H[Q:P'5/6LYgUaOr3j3WTH<u'LUZ
	E9lJ1pQZk4,Z<@e"=67<4a4l?N1r,g#0DeLbC4EEF5Q:Sj?SM251nW#!PI+)/t4mdD3k)]fGD<1[HN
	't)V(=i0EgIT7jseMmnd-G0\Uo[LGD<*G&@Ws#rIHf-]Z%"rd@XRb]OcR\qVl/j_[WFWJOQ@?p#K16
	3##b1"b[*kM^AERsYl2rp&lgn>Y0K",OpQF=oMmTrTOkf*L!7Q]HCgPO-6Ff^;a-i?`$`DPAaalMeR
	's1tlLb+2A>d'CEo>4GVX5n!3rQf:fdSS*`b]8he+T&!SO:+7fdS";iCt"eITn8I*!10=c34.;r3fL
	p3J<upS\`DAGD:q9?Gu*Q-gEfjk7P<H^"_"_^O1P+7%FSJ4CYdpGC+Z)QgYHWW:N9F#B+c.B2@u9bm
	()7&V49l'WYa!hQR!oYY(IC4A^ueEP#8/!dGd.gR/XnINOO2md(A-dS;jI^2s+p=[a_V-gr<iq(:*7
	8,IQA%GpXk$6@3I%A\Xkk>k<F&fN8T*,):*\I/9n<QSY6cF)<Ok/N\^:a3TdLJX&&gqsL+p"66+4LV
	VZM;)`]ntGf=;(E!kT3j.(59Ef=08;^c8<R*1,%>>(c^fH^_aj:-II?0KpY,ZjQeU]`3i;^4/SR>@+
	.s2k@<g+h]^>27j;AZAPIDRHKKOm=h&.F1i@s51(`q+MHQ!\S6(,TIEqu<R\:B&W;clmL0;P_pW%7A
	:JYZptq7,Zr&<4l)S+AV31.MJ&!,!Xtq37:K[54=/6"aiofsmZpF`?5%oXN13G`M+Nhb+J)r4#L-f1
	oCCq)C4PkAh2\IU"8T=e.P9\B_SgfguL`:24>BO6`U&m:V%?gLo96&:MHa)$!c<<MbouCL'ZO@<KKj
	cUoW7a4A6tq>!TOP+=D9hLSFMmIjb1V;k=cr=l05>a/.JfZJFe+_B+5a8[sko+uYNR+<'u[&bsH=#q
	'Zq$-+1I"'-5*drV6&'C.&3+d;nLB%;S!(fUS7'8jaJc
	ASCII85End
End
// PNG: width= 337, height= 15
static Picture cb6WatchWrite336b
	ASCII85Begin
	M,6r;%14!\!!!!.8Ou6I!!!$s!!!!0#Qau+!7L%G-3+#G&TgHDFAm*iFE_/6AH5;7DfQssEc39jTBQ
	=U"/\XX5u`*!m@-CZlQ?a(a)/-KAUY-Y;'d<W]6;p]&p4ke-a7oLCoV$n?Goa["e#g%?iGsT7MCFEJ
	2*'1^K)t@_&aJK@/sqO=TUj[kA[JpL<*?dr;QNnJ3(<_J$]"/-n93?lKfSBG^FpG/shr4<Rk&Tku@;
	nVC/;K`eBj&!#>QrkIK/i>b)i_V.a8*KV%(.5F_%dCirq7mgbiS\uI6Ic7>HCT"!VLDsskI!8uW0I/
	#ZR:K[<mrK5mp\2lePMBo_p^Y6X823+^Nl)D%Q57u:8HdtH.rZeOJ_"6#JE3#`kqTAE1YbK^[-jmJs
	d_AEMWZ">2;#==FMk2tpSk<eUB,(Em:G7)*PlT\OK2q=np%e(hn45<<Zq32ejBf_lK)gPe[C"AQ_IV
	_9cftV?hgTe5'W1TlkuaZ!HkuI"(SVk])IVPYKY^;BK,8`OD`9I.F5sX]4Lo?F!n6:s9!+]"+k\:tJ
	R#ZAJSF^JV,kq"OR/3u5bk_EJSF^JV:NJs+k\:d9]f#Z7XePjcQ!",h:;`.o),poSiMIqSXlI:n*UU
	uc+OB]Ra9<*E6b5#1L`:UoksU)nG,'Tc?YXl7dT9=hC[V,5!S5H3=jcdi6@eBj!"rX0EZp?!%:%O=M
	8<4HY/LG'5=,d!+U/R'F!kdH8dV^@f&>GR_,m^=A.IlfR2k.S$e,M1/-Os^j;KR`t%h4*#c9If')G)
	)gb!caf\@,1*tF>@Q;_,)n%6gfMj/JSQcn;I@D1bhn06eo+$.rF`cLn`7J)2o'P)RND/+fCQnM+Iu%
	8o1d(TYddZ=-WoBi5aW6Ni(9hQ+)UEL!md'/#1_-.iGOMXk!(c5@q1t&F5!hnG:?V^lpkTd8F8'R`H
	3n:T"Rb,@="b`ALgYC\J1W]R34q[!EVqp.$CIJ[@7@_S:M<S?5EmUu.$kauemQu<pnU1'/\$2DXO!6
	eB$BpjCepHDK(a--UtD7oe#ISFFUi*P%"0&gHmT*mkC(\;%#!Y7:AR+p5Q&jg<)mLPns#3qJp[nQOl
	p@tOr_UMK?iP:CQ4l!d-EYl1A8=Ir-3\1$b(,aN<m?ZS=*NEAZ:n4CEZEhEHT.9bXs<4`n&-qEW4N5
	asJ!pmQfsH2VU+&dW&pUDR.IK.nZdMCh4S#&@:VVj*]^4riRjhe,$5-Q4g(c8uJC2h^cBoO6UuI_c;
	6e8q?$'>,@B0z8OZBBY!QNJ
	ASCII85End
End
// PNG: width= 338, height= 15
static Picture cb6WatchWrite337a
	ASCII85Begin
	M,6r;%14!\!!!!.8Ou6I!!!$t!!!!0#Qau+!'/EQ,ldoF&TgHDFAm*iFE_/6AH5;7DfQssEc39jTBQ
	=U"1Cch5u`*!m@1pej"M$0-Z".jB=8nd(2?'a)dM>%ie#)b7/T>(W#Xa:hY%0u<W7R:%n3Pc@H_B>4
	3lJuS4:X'"lkQ*;9%Yd`(j00'``&.)`Unq6Y%ZmI_:(15Z@TrIuEIH-n<mWgcsUHQV.=WlPcYl4K"o
	$g7=o"5;$XJqklLU=Kg<VYQ03uAtuaT<A>Rf.2n[&U$'JNkMu0Of]p!"D;QG-+6pF,8".BfSF)o$h=
	_jP*rlX-gA^d9A\U?8m8a*`EhWHsE:m9XalW?G/S:ue?QD[5V3Ut=LfQR8(!?+iC!.-,Y&C(PO$4F2
	c]=5i>3iIFacV$$'s;6Z"[EaX"HIZW\b&j)LYf'7\@K>MR8b4oHODb-rT=Og0(AnmbEn#(PM`*=qB8
	'6)CZ(=I%Igq8p:W+T?#cg%qNZ8p:XClXPP>A,kq*YmH'?RpN\X3oO/#tQh5q:/r$n"bfn9ke*?W@^
	mtW[gIF<jN;nWCVn<->i6DCim3A0E`d^@];dKM7gWfkdm3A0ENr"K@VgKJ<[np3"D.e.U&5W@N(@[[
	B\"2WG6g34V'9%6e:Pc@M,"hHjM)nG^H,a`7n+QD10Adj8;<Ncsce.XOh4EL#jnlqCl9%r,q4!qug!
	b:qD1f1>LtjWtb1/4bDcd'J=D+1Y4A_&gH+R+7&pU"igQ`@rINJu&GP21&=U?*dhtd,nfgL;d#^Id0
	YMV\,G''8;d.f1O;Wq5#X<FF73;%$dPgENdiBTmjgf53#WC[:qGJ8kB[5GXc%ja!bHO,V`aWnH[d"n
	5B_P=Aq8mFf'P7P?UN*>0Wnbd2Xiq\tAGVS3g8!:fb?Qur@p,pEO#(.[lf]POaGeFOdEeSp*Zt#L7e
	Iq`c6NN/hWR?,7jR%IN+jZgsK=i5o-0,pXm%+cn%Yk3`[.'8+g=*Q^"f`7pPfrfS`Wc9-Q,88rGp.$
	:UY`ea#*R9JjeHI=65l1T2lCpb<K7=p!R=<[o;OLKC*u!=J^0k6hm2.oF`?/#FM#g`Gdcr!?V:nSI(
	N-Zf?R2gof+eLVfSF"I(N.^]fL/[G+EUnZBGoID:?W3D:_@OgWp#]pZJtN+o6dH1B=YXW_+]tepB7\
	qpb`A4=d8$**X?mjnDgo8QO-`H^"=\l@qc`Z)?K.MW7bj8uZiIANZ3=ddG"mZ6t/$!\Y9%q>u`7.88
	iK:.7smH?p'nhsl`I^VK^W[1VL[k&+2_z8OZBBY!QNJ
	ASCII85End
End

// PNG: width= 335, height= 15
static Picture cb6WatchWrite335a
	ASCII85Begin
	M,6r;%14!\!!!!.8Ou6I!!!$q!!!!0#Qau+!:,0hI/j6I&TgHDFAm*iFE_/6AH5;7DfQssEc39jTBQ
	=U".VqN5u`*!m@-gFlS&m#-[g*YAR5o:/>O89*GjI6W#I!W&93>?:qM79=K6`LHD0OOD_Wr7`f;iuS
	3O]7TO=:03m)\Z4GfPAXT9QjF-nGU+Yjis5MeU*TZV`B^KL5R'U<J<G5LZQ]`s"m/E_%0kFs=BSY2H
	:/nk+;IL?-7!0HBS0kO[]4=I$S,gA[%O8$u`Q`%+=EH=74SmS)9eRrkXkG%.(N=Gs/_eHU;AcR@*oB
	l8E]Y<=7]CNGl''IO$mRnhIjn[:UAuTe,>Y%Y%Pl)1,UJ0#_Pik9ZOTdl&5=Sit>qo<M+!m\@0h"st
	c2=>9Pbu9-!*/e*pbB>t8l'"lk[tV1&,2-lBGuWPWIdK<fQt/XNVH%b=7esHjPE0'U.0g:o2.uF<ag
	%;\BjFAg$a/F[0i,2UOu3[=3o<$mYBl+Y'O2$o\o(uBb834mH#*!(+)\L[o9k]2R%$?l)Z\qf-FS^,
	uD0r2R%$?l)Z\qf-FS^,uC+T2R%$?l)Z\bf-FS^,KRNWbj'+-b<,TOd^?E4^V%>G/FVpmcdlf,lh=2
	-:da-Y.EtrS]Em]N\6YNWCO!UAGPGpC(ZE"F[juNH%I]YP%UY4e,+P!4G,])WiUL=bXstYg]-+$^a-
	sYM`Hc'dFZ+u*$3@6MND``Go.&SaN2Y^I:c!4Z1iT&Ze)Kbs:Xkn%KT^?G:*Q:.KkBT5XNmMi/bd00
	/7!T5P_ADWRAj+OAMs;drNkX__CSDK#4QTpK@Ndcj%Hd&,'1AOd/9CrT*ktMc`-IqR^q!PQDI)8o_L
	:W"]EP#PGOSYa&L#N/UMgi8M&l3?t8$<;gN,'7tsV+4J`:t0EZj!P!"fef]KGA@Q@l`VneFjFQY+/:
	@AgMM$6#<gZ`"\0X8Eb"q`N:Yi3\89r,nu'Fq?5S\fquq2S92^d$<t*%7-idUY&##CI[;R20$k@\kH
	MEk-14?,KV(LnNom4/mt4c='_b_R\ZI:4k02rSCh4n(U3RfCX`/GKoXG^r$H8>uR&c1U0kC7KiOmX]
	:s9f*o*q-4\a81Thh.;F%-3<J,9RSC6$V$UORD\1&1]?Z=tRAu2n9duL!^bscD2I6F8(Xn?SH9i<[?
	djB:pj5GYq]-i%`1OrUF]mu>:muQpco#l78;DFs8^u9$X/iRi(HLc9P;tpD6T649'rrW7di%B&:SuV
	hk!!#SZ:.26O@"J
	ASCII85End
End

// PNG: width= 337, height= 15
static Picture cb6WatchWrite336a
	ASCII85Begin
	M,6r;%14!\!!!!.8Ou6I!!!$s!!!!0#Qau+!7L%G-3+#G&TgHDFAm*iFE_/6AH5;7DfQssEc39jTBQ
	=U"/SRW5u`*!m@-CZlQ?a(a8O,cQh`YW8!S+Fmb2N`8<ciET"sV#ZDj!UHP&m_(\kP&p#WrUA2F=G#
	E8%Pnn[>b)!mAn(^=q['EnIfQV2R&:d\bEH@CAB!'lhJ_LJoWh]OC/'j0p*oD'BTAQb&TQ&\:/CjL]
	%?s'W8XEQ/pQiY!C\^XdnX-3db'Fda2d.@/#B=m%0X\LIg_eHa?P[t0]H)5#uoC8<!]j#%JJ8b&Nq;
	XTP@+e3K>B5YnipuYA,g#0DeLbC4EF)m@:Sj?SM251nW#!PI+)/t>hHo*7>90h#<1[HN't)V<T#9r\
	r_Y.EeMo=7._H,Do[J<RWO*.`<Y"WmqTe8#4V6=UYf[WV5+b%`*_AhZ2X-!U4D:*9LbO'[9.SgH9L^
	)tX>WoP*=o&;@;>7sN[;6PB5):.,ItXk%OMZk(qcY#"S%`MFqYN&%o07OPO!B=0Pt0reEQc<a[UO^j
	LUlg9\WVuFaAL(Z;Fp0NRlAXVX5n!3X:"!Z;EfSbaZ\Tr45dtf`gHJSI,5Uq/rMrZO8o84+i[amgPo
	74c<7-cd-lUcD,JC@^g"CIei^,q)Ju2H'E2:m.RO;0Adg75NfjC&(p7,c(<JG+q;gO,D*T7-pG[R]j
	a9SAsGCjrBR%W`p-_V$JKdtDJ)GWp2)LP]<O.O9Dp^"I,fOBZ\hR7:>SR\H<[>gNqVr^)RebY)!\Ac
	]qU0jpEiV&&h5EZ*GD:(XU73L<U%?FSVs\Fc&LIr5t(Qp&#$]u\Si8slDmkZG&1b8'6haej?rAXUK/
	(`-\#5,:HkR(?49WtOX.2f<Q!O8T"F_n=-*"6n@<lVhHC#3^)T<Yd4rm9BM$AR4TGp5#t'%,hJH=IT
	q;pJ]6E#[9B^"VYWG4jQ5_/5hP-#eI\$`I9MhUjU0PDY1aq9(aqRm@b6t:b0^8mj;BY3>>WuWJ(J<d
	Ek3>.=Vp#0-qfcXMCepJtWcj/=%d<6fD&W.p-3s;.6dOh8K]c$(s*Nm:KV-@8bL5Y9.3HS6q%QRJcd
	1\EFs&.B3g2A$2)^UbX5d<qEBKc>a7Bs1pl2Ut7#8S9`5J`*$Dl6K$Y^7!M[LS<<_>YAZo/urlaIX$
	2Ta<f4$)!$h/DMB%Qj"MPMJE0;+fq;/)qe.PYL$UfCS^bGBKl%f6;AEPVAD)3YjmS?Ki\^<+e$N!;m
	'3!8jf*CW\sD!!!!j78?7R6=>B
	ASCII85End
End
// PNG: width= 302, height= 15
static Picture cb6WatchWrite301a
	ASCII85Begin
	M,6r;%14!\!!!!.8Ou6I!!!$P!!!!0#Qau+!7dpR1B7CT&TgHDFAm*iFE_/6AH5;7DfQssEc39jTBQ
	=U"(=bh5u`*!m9@DEgFs&4MWVF@=[-:\!I[4Om56n?aCRWO^t9ai;C%%k7gp+.Jb=eGa:<#g7T*dF[
	UN\7leldtD%e7fSnP[3D-I!Zc9WJdHk:F4p%n5;@jW1bm<Z0Dd=8d2X7M1uR8m70"Fs\VE6`atB27U
	mCG!d@'k[.8o(MDDcahO#`-up'A<;Q]5-[/TWi_;NmFhO?5,gd(SqUgkhgO;[r@Yhu`q*\Y4Cr*;(#
	Ho60+Xq)rmPpT"-3sggA5ftaQ*(N+7HnPecLB0(8'4iCK26e@/u>I83#/I(XC0L0>'^UnG)Je/1:ik
	?N'ijE.aIHLB'SE6I+XXgf(HoTqW;+Hg?$2M0l7,$ij::^H;&l;rn3ZfMh=e9QHC3VW+;?:0f7.Tqn
	t,ge;aR"Uc*)6qB`Z\tjn#I&,/c:'QionM*SuOp9Y1O[bNq)+=2<a.VZNBqQIgBf%i>#*HUhEgWq:,
	6+K:mMl`M\tjoW\Gsu*GE1"L\$CQL?Wgh)DH/.V74)sNGR#(0KCRAH+0PiTAFda$GCXZl(b\VTnQPE
	N-?&g,rt+o;n^8+uH<a9\4&7#upVT2aa;RAYN@'VtTOf_KJKDF3ClDM0(d$i-irB4il`FuD1l4%(jf
	_e].Dj/7nSnK%7=L-f(<WGek!_:%[/)]>CNjjF1ic3-N/X`dj9[4[e2KF"Er%(hSnVtq)\j"L<&"KW
	ZAhgM+gfBM9F7t3J[=[R9YC)q"0rO`d(N$_kh_i/0EetRM52j$qk:5qjC5&&7RRQ.jC5&&7RRQ.jAR
	DZHjZ+f5WH^qX2hT*>RY+NPb8.V\JW?'-p\06`g%RKM1nE27Lh+E'oAu)OAgCu4C/3N.fLWin3hPL&
	sjY&<Kp.TUqf*!^=n_0R,Zcg]Pf(YeUY##3iR$CkLHk1/q9%L*Di`]/Ul6a@VO1)J*BZl*Q21[?.UA
	KOo.aOq9gQ&+)LJ6hVVCc[eR&JQ<lC%jAV&df^B<6onj+_H&c/SlJN%&pci0?[WTl$k9Yugmroj\?`
	5o)B1$@*c>OMODc!XJL<RQ*^:e^8201-4BV<d7DRO>er+1TceUGnAJr,E<3hKNF=]JHl!;Hf;]u$O2
	BY>kq!!!!j78?7R6=>B
	ASCII85End
End
// PNG: width= 299, height= 15
static Picture cb6WatchWrite299a
	ASCII85Begin
	M,6r;%14!\!!!!.8Ou6I!!!$M!!!!0#Qau+!&KR_G5qUC&TgHDFAm*iFE_/6AH5;7DfQssEc39jTBQ
	=U"%c'P5u`*!m@1q0gFs%$l(U3+B@\.9#3Z/8CTkig74n]9"igNaQQeGs59ccI&%"R^6ZukS0p3_XM
	IgRR?ON3nW1!ub;7,-((]sbACM3hB#AMYf\(C?l4lL4cCD>M#T\B%<[IA=Y(p13RG&De).&CTSB[Ef
	hfCtV=5Nd4Q`-up_CtDkVj4p4;h>,B&CYd>(%+1]\C+t#U!*F%:I/>Lfq=3tIj7@W#4hi?2d48dnr%
	;$8f^l;bKH?^+T6'&%h]9#"TKU'0m?LSuUgF?L]MSn6!.@"3(s6$_Pf0j4G^=boCtG`<Wif,X6/V,@
	G6Kpu'Z*h+6Re@eZis85=_3f:P]Bnu>6%*$^H3^#.<9L3e(lR!9qfS]$B:F%P(6.QahWUaKs>SQONL
	a'5hWp#BWrsIQ:ZEF.Vh<NAcGAt_5c^$-LH4p'atEtqc=[F/u"A;dQU5='fo-?D3QPhLWWds^i-Bj2
	Th;oH^,#<UQ5XZ(pa#i(\pgh2g)dFo/f*bru&;lL$p:4;ocL3^XMfKT5ja5peHu2FhC<8)[:flM>]J
	QT5qQd37QPgO*>-Z?K[:PKc3cpLHV5/MOH]bp%_4*:KW,\Z=H4QUHua7."?!KV[+ltm,@NgM0qq`/M
	`mn[iEP3,Ia,trW'XD9JB@:3-rGD@*Ua",HPK6Ab<&34pK1>)''D;afBt)EpHip#;\ng*@n1;(beH?
	$q%rsp\,JK(!!:oNSmdH3F-&Q<A%`PB(AGUDBHqm?Z$`LC(s$AqJsb%;PP*"PnIZBnk!:5>ZiMD$X,
	i&qYW)sTgjM%dcZr_#rV;&%qrf<'+0lpfAWSF81BDt.>8Gsp/t4LiX\oo-d(h/>l3_6U:al+!mL&nH
	^c;$:hh"(HU:V*#%h@A8Ne4G-hAgt`sDsW+@%5#o!Ko.Ofsf?7",u-?i_N9AuU0Q'!\(q6se0'-h;;
	(.!_M\2Z)<=Zp&G[Lo8h3r%.i$$i`).`Y^RA5u7(An7@Pmbq&"o(phnuDg;ut'5?7R15msT4@atoH_
	JHHIVqq@4cBrdd5elV])6K"KU,uJLK6X<2SEiWI")0AAt`M&n6V4W!!!!j78?7R6=>B
	ASCII85End
End

// PNG: width= 151, height= 15
static Picture Bu3WriteWatch3
	ASCII85Begin
	M,6r;%14!\!!!!.8Ou6I!!!"c!!!!0#Qau+!+s<pz&TgHDFAm*iFE_/6AH5;7DfQssEc39jTBQ=U!Z
	=Qt5u`*!m9)0(K.mkl7$eF<&"lIB^iaiQ.2(%h$[dLPJg1#HV2,X-+/6;T\\1/\=M)9l:h0p=Z"ILa
	0P_n6eli&-`kX?[ocTQ!(&T]NEk]h$$-0b2!8n:dN%qsAG4'Y\R*>Ij=Ol3W0GlS[Fu`ojVo.<O$u"
	pL?P_r1$#eKAJ^9Ahm-\(f9S.q'hWYZe;tr)%$B-\G&iOm%^ur`DNi0eVHsNd*J0<AgEo+),nu&pCh
	W5R[jm;OJ;^cW0OQmH=S%;&&l<-\UnV*gU<KZV_%/euGbQcl@m%k<.&$f7jn/J,Y9:XpSSZ)nP#MCU
	Epq>(C%D"@J9-\i"h2NDe/+2h0lBW,DZ(L-!I(gB/-0AK.Xc`a=o+sa,P]M5d(;).=:C$0N'KE@i7@
	\d/Cc7b*+3%9u40,s-Bj2Vn]"I&I#u_J>U.lg*a;6Z"Q7)ZLU[qpt>!G15h'Ts3C&UK#3J2b;8,1g0
	7qUS"O]tXt8&Q+=j;-8!Oe=S"K[9N@`qUI4^`F>Jd$4/f"SmQ<,0>cE%13d1Hkf1ar8H\Q>WG$)0aj
	0*gpdtqE^"tF#V1.#F-C)F\=0se!%Rbgs-2=5^@-\DUiB@;@TH)@j#;,XDsQBj*-$8D1ep6ng00uM?
	(;D6ls[$(eh57+'j,8GAYIpdEhF7Q#p[6NGkLp1+iKPYBm]q8oo@$o0@*/h!!!!j78?7R6=>B
	ASCII85End
End

// PNG: width= 301, height= 15
static Picture myPictNam1
	ASCII85Begin
	M,6r;%14!\!!!!.8Ou6I!!!$O!!!!0#Qau+!'ZPU0E;(Q&TgHDFAm*iFE_/6AH5;7DfQssEc39jTBQ
	=U!k_)m5u`*!m@1@Uj?O-.-\s@_fnY.X1nm2U!X]JJO)X%iBFklu6QA6-dDNk<Rj(p9nMt)lY\,b]k
	VSo.YWSMr_XdV"#Yj'^Y#;5Mb,KIMj6*&2dhqW8mF"#H\p!=+7R0/oqh=VY'1)]Zf?2Cf#KUOh=[>5
	%/E07@[eKBsN-KY#61?$BSmG(Zr:lEe:Tpgn=ZQQq59*.n_Gn7>5.pYQ"%1O:n)n$hO1PbXK*Ocm<5
	Afqa'FD/]tXS8;jHOd(Pp+;Mbom;cWk*o:*3LdQ$J5`&1((.pk0NeM@(e-Uks=+8t9Sa#r>a"'iLPm
	'Cd&)$Uo\DR*hpYP_p,g,$mj)1`GMK>,BN^6&?6apnIbe<U)\/X)H0"q9rnT(@K\:,+U;=50n316mK
	#5/fqpjXjGbL#ELYg)Ni9gnJE<cL!H!npGY'QU(Q(+(WK_;?#;J=1&c.g_.]A)Sa-Nu&]718\iMo]G
	a.2T#i5gT_*AN:'o`hoL&8<[ii7giLX7!;%`s'B@j:\5gJ#/sqBLqjrAt_d*F`$WhbUH,X@/LsS"Wb
	Jc]#DbcADBfWGK(Up>1FR7V/tCmeZ?D)/7R;"BJ5IrR_=YC0I256GXjYf6)pplfVnkV'/aLPn5D$P,
	T!:`CiU.(ecY&iql(mK2tPH8dHZ,6)u74-%qDPQXJ;6:K%AWq2-bpI>^X-O@u=&&m\+@O@u=&&m`Z'
	C-;g,9Sp)8iZLD&7Kimbb)Q7B'A08Q%@tY$qKS.%?ThGSMPm>e1gWE0.-[Q4lc8aWkWBd1PG/`Z("%
	<6XMh)./8I_CR^R)!q_T5`n'cAa-]6l3^YeF%DWk+!d#s3gn'foklh`NFh&f[ZW<V*p\*3nY#?LgCl
	JM,m7r>0H'M\OUMb7Q#rW7$4+TGpD+C>*K!!#SZ:.26O@"J
	ASCII85End
End

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//  Sample for PN_DICOLTXT   drawing  into a   CUSTOMCONTROL 

Function		bu_DICOLTXT_Test( ctrlName ) : ButtonControl
// Test for displaying 4 possibilities of a global variable (0..3) as a colored text  field. Increment the global and watch the display. 
	string 		ctrlName
	nvar		gDICOLTXT	= root:uf:com:gDICOLTXT
	gDICOLTXT	= mod( gDICOLTXT +1, 4 )
	// printf "testing  %s   : %d    \r",  ctrlName, gDICOLTXT
End

Function		buCustomControlTest( ctrlName ) : ButtonControl
	string 		ctrlName	
	printf "\tCustomControlTest    (also press  COLTest button)  \r"
	Execute "MeterPanel()" 
	Execute "NumberPanel()" 
End


// PNG: width= 223, height= 180
Picture PanelMeterNoScale1
	ASCII85Begin
	M,6r;%14!\!!!!.8Ou6I!!!#V!!!#+#Qau+!1Tp)iW&rY&TgHDFAm*iFE_/6AH5;7DfQssEc39jTBQ
	=U#(]?65u`*!mG0F:)b1m'nPpnh+J:S?W-P8e=<.L=]Rg..(`<SC?kdiP`^-.-n1-1"nC6)E%8T9@)
	rPq5JlUFnl#(^QpIATX4WfnXZ@%P$r:]i[\<HT3D#d/2%Xe=B,O0rbf1e2OqDRDC@(\\;D7jSgHeq>
	\(g_'S0C#?+**/o`kOVHs`5,FtA6/n>RlVFW&@%cMZP0oV)$VJ,\0)`oG?Vc]h#!dQbl7OlG:P1*FA
	XE-;($H_-Zi35FAXE-;($H_-ZfNp`qu=!9Y*7pjQc.fr?&0genMa4o8PI;D,Nr4fgui3g2rKUkP<5Q
	1_K3EELh7caK>f[W"Zb@'=t+U\u6:RW"Zb@'=t+U\u6:RW"Zb@'=t+U\u6:RW"Zb@'=t+U\u6:RW"Z
	b@'=t+U\u6:RW"Zb@'=t+U\u6:RW"Zb@'=t+U\u6:RW"Zb@'=t+U\u6:RW"Zb@'=t+U\u6:RW"Zb@'
	=t+U\u6:RW"Zb@'=t+U\u6:RW"Zb@'=t+U\u6:RW"Zb@'=t+U\u6:RW"Zb@'=t+U\u6:RW"Zb@'=t+
	U\u6:RW"Zb@'=t+U\u6:RW"Zb@'=q*,]R*nUT1h:1']eQWA9.FS:AD]ufh%imdAE,ZBjYKP.M+"[d\
	`n,=D.ML$j<gcJhH>A0'\*Bl@^eTKJ)PC0'\+m<nBE'0)0#]f7R;%cFpb:=3G==4ioMiFiK<"dW,",
	dkoPlB%r3(E`XPc)N@.U!Ttho2I0A9LJ%P6g"9,6U\5q=a_EhILrSA1;SE(X[+l5[l1+A\m&\V%C>O
	VD5)@lp2,'I!>NN,Jg%iM!C!Pl89fMH^iJ@kEM`RKLVs0p,MPBo1V>Wj,@hNH,lJ.1hdrsu4dW,#dR
	0Fb'5^-)'0l_R'pb")`QUE`(T\J*6D>:_7:=K$RdDke-i%^0%ZST7kcfXt=\oc^=omAjPpMJ."J?I=
	BMPBT9:cO[3HN!)4j3:C"r&ruS*5M6dWFqB:Su,GP^'QiihgbFl]oVW_k05Qof)GZh\&Q@fm+3&Oh&
	aqJkV#Z:R@q8Z8+O^7prdjk'<X.O^Vl_[3R$JES);g=^hPkMchR.j]X(IbK6*F#cN&=c)LJUNAQeI#
	B&o9`fCtCHDk6n+:^l+?e`*:bVT"s;2]YuCl0RDOjGQ)MHWB,EB3CO%Mhg"CNA:.(g9I+E*ChNe.nV
	&>lM;OK`,0iikucRjj'S1NPs'B?Br>S@JULjp"Wsu58CBQRpQ%XA5'<<bf40/fmbX1Od^a:b`gEgG6
	Q$6<<n"%GkBXVqb[V+(UsA:mYG-G^[Y$!g`_!@8i1%[RguG#n%J8;nB=>FH8n=JLQS:D$p`37/+4!S
	\L36g0SCYDd78Y&tHC*sho#S%1A:lq:M`RO^_`C#0q-LZ:.Eh:\pTV1l096P-Zmm_>-X5`--pB<0'#
	$&E5sATscV%:cf/kLLpZsQUcrKD,'E>^#\CbN$WRIl[,RH-MC,qj09@'+YMP=@G%J*>,PMl&TjoQ3g
	!m/e$:!Kqj$H*k@;]o,bqaQ^GS"5$9,TGG)MEIJZI!tk]eT6M5XbPXT2/SNC9p'.9D@IY%hK#*VmFc
	u/(3<7j?We3/?9<9.j[PI(ep2O^4+%"1I2P1r%V%E3^V%,Ej,oDD(g$F(eT*^pFi8]PlXN;QNVX,Am
	gJBN(j2C92n)MZR)=k>cd-oF=Z7S/e$%BrSM`RMf^&0g:X`O@_&r3di3^L1B2IcB1,\*OpPP+I]X25
	,HoJ/\*ne\g5KT5-kqG1X@X_p4Rir]<B(FtpM:lU%0pai.J%U9o^Q/gS@>MpF\U>anO.8Augk^@DBY
	..%c.!3Vq#:R3Bi\'nZhX8Qh0iP*T)6GKc!&Wm_S0s&GI%)mbpMe7Wr,p`4%G_\bg%,MJsr:gca80,
	8CN4E=jKRdh[h*Y(sL8pRm=U\$togFGpMY`k]W5(AF>.4_qYg2s-\tJ4%#[a]hi>m(KPp\7+i2qmVO
	o3i'!3W3n"[JhmfB`?.90d@pI^Er:Ja;%foOpS^9frco"t0f>\ZR%nQm.Aq)q;@<OujVG:2CE*1jD1
	-;2q\PC-l%^$H'All@!*>4*.3ui&$ZtL/kn1<:QFTMfgXpDV;'=t+U])Dg%&&%AlD@.Hc!!!!j78?7
	R6=>B
	ASCII85End
End


Window MeterPanel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(648,55,957,305) /K=1
	SetDrawLayer UserBack
	DrawText 87,38,"Mouse Moved Speed"
	CustomControl cc30,pos={45,53},size={223,180},proc=MyCC_MeterFunc1
	CustomControl cc30,userdata= A"5VRScnm%q6!94'K"
	CustomControl cc30,picture= {ProcGlobal#PanelMeterNoScale1,1}

// 2 Versions : 
//	CustomControl cc30, value =root:uf:com:gDICOLTXT		//  needed only for Version2 : needle ~ COLTXT-button
EndMacro


Structure CC_MeterInfo1
	double voltage		// voltage value (0-10)
	STRUCT Point lastMouse
EndStructure


Function MyCC_MeterFunc1(s)
	STRUCT WMCustomControlAction &s

	STRUCT CC_MeterInfo1 info
	
	if( s.eventCode==kCCE_drawOSBM )
		drawscale1(0,10,10)
	elseif( s.eventCode==kCCE_draw )
		StructGet/S info,s.userdata
// 2 Versions : 
		drawneedle1(info.voltage)			//   needed only for Version1 : needle ~ mouse speed
//		drawneedle1( s.nVal )				//   needed only for Version2 : needle ~ COLTXT-button

	elseif( s.eventCode==kCCE_mousemoved )
		StructGet/S info,s.userdata
		variable dist= sqrt((s.mouseLoc.h-info.lastMouse.h)^2+(s.mouseLoc.v-info.lastMouse.v)^2)
		info.voltage= info.voltage + (dist-info.voltage)/10
		info.lastMouse= s.mouseLoc
		StructPut/S info,s.userdata	// will be written out to control
		s.needAction= 1				// want redraw
// Test1 :  LH added ....
//        elseif( s.eventCode==kCCE_modernize )
//                StructGet/S info,s.userdata
//                info.voltage= s.nVal
//                StructPut/S info,s.userdata     // will be written out to control
//... to MyCC_MeterFunc, added your value line, created the data folder and variable
	endif
	
	return 0
End

Function drawneedle1(v)
	Variable v	// volts
	
	if( v<0 )
		v= 0
	elseif( v>10 )
		v= 10
	endif
	
	Variable theta= 2.39 - 1.67*v/10		// Note: constants are specific to panel meter image
	Variable x0= 110, y0= 131,len= 96
	Variable x= x0 + len*cos(theta)
	Variable y= y0 - len*sin(theta)
	
	SetDrawEnv linefgc= (65535,0,0)
	DrawLine x0,y0,x,y
	// print "DrawLine",  x0,y0,x,y
end


Function drawscale1(vmin,vmax,n)
	Variable vmin,vmax,n
	
	variable i
	Variable theta0= 2.39			// Note: constants are specific to panel meter image
	Variable dtheta= -1.67/n
	Variable x00= 110, y00= 131,len= 85,ticklen=10,labellen=15
	String s
	
	SetDrawEnv textxjust= 1,textyjust= 1,save
	for(i=0;i<=n;i+=1)
		Variable theta= theta0 + i*dtheta
		Variable x0= x00 + len*cos(theta)
		Variable y0= y00 - len*sin(theta)
		sprintf s,"%.2g",vmin+i*(vmax-vmin)/n
		DrawLine x0,y0,x00 + (len+ticklen)*cos(theta),y00 - (len+ticklen)*sin(theta)
		DrawText x00 + (len+labellen)*cos(theta),y00 - (len+labellen)*sin(theta),s
		if( i!=n )
			DrawLine x0,y0,x00 + len*cos(theta+dtheta),y00 - len*sin(theta+dtheta)
		endif
	endfor
end


//////////////////////////////////////////////////////////////////////////

// PNG: width= 280, height= 49
Picture Numbers0to9_1
	ASCII85Begin
	M,6r;%14!\!!!!.8Ou6I!!!$:!!!!R#Qau+!00#^OT5@]&TgHDFAm*iFE_/6AH5;7DfQssEc39jTBQ
	=U"5QO:5u`*!m@2jnj"La,mA^'a?hQ[Z.[
	.,Kgd(1o5*(PSO8oS[GX%3u'11dTl)fII/"f-?Jq*no#
	Qb>Y+UBKXKHQpQ&qYW88I,Ctm(`:C^]$4<ePf>Y(L\U!R2N7CEAn![N1I+[hTtr.VepqSG4R-;/+$3
	IJE.V(>s0B@E@"n"ET+@5J9n_E:qeR_8:Fl?m1=DM;mu.AEj!)]K4CUuCa4T=W)#(SE>uH[A4\;IG/
	e]FqJ4u,2`*p=N5sc@qLD5bH89>gIBdF-1i6SF28oH@"3c2m)bDr&,UB$]i]/0bA.=qbR2#\-D9E?O
	2>3D>`($p(Kn)F8aF@)LYiXn[h2K):5@^kF?94)j*1Xtq1U2oFZmY.te?0G)EQ%5,RVT-c)DVa+%mP
	%+bS*_hN$hC*8uCJuIWqTHJR.U?32`_B)(g_8e#*YXa>=faEdJsF]6iJlrQ@QAX7huJUmXj8:PBTb2
	Y:DYf*Sci'Q"3_;@RDQA:A/([2sO8r$hW)\B$XBGASJ:6OpC+GL<FjVfeNm20U<l<9J%cndX3'HP+k
	R.IV?U>ns*_;Zt[]6G6"Rb-*'Nm-E8]LXXXo7Ub>A**7Bm5cS*">HbQ&_RhmUe]$iu@T?Cci:e-_`k
	sE+H.GRSMT(9to;IZuH`T4%Yt<jF$+W?Yh6Q*_`C4sGig=L@DKoT%.H=#e_H"QEeeBVNTWBSMYr3dj
	O=T%d&4kT9#cWPHS>kAG;3=or2(IK*IBF$^qK,+m0NSDK_!+e0#3fAI>HfKa<sk0641u\W@r+Y:$.i
	i$grCPR#&6,;+>nTs_IKS6XcYR)A$fJiC6Z_d2S!$R>_ZH+[<p:JI0ub]\BhE(0RP@((KTRTGo;#SY
	LT^9;D7X#km%UV20?$RS"FZoIF!(`FY-iL?n$%#o;-Wj(\PaBS6ZRQe@:kC>%ULrhTWLNM=n@fUbRp
	SKkLe\kJ)Sd]u7!?pRJk-!XL[/MZX'"n4?a?JIKO0k'KUm1IZ+roB=:Bq'$&E<#$Krp%p,E"4sI>[-
	0F#^ff5SN':2fO)LNC?L4(2ga=!aLm8)tVbGAM?L`l^=$D_YP7Z(sOFs)BL5er5G95p3?m%hM^lSr'
	*E^O@8=u6hL`L$mPcq!Bl-iHuGA6hiip%`cFjl9>W?'E-&5T%Y.]i2A@1i%p8XJ5[khb:&"JXYSC\r
	10Ss8<Ye;S^"Nc0%-DFouAiPQ9OemnR!"sHH$JKt@!"d0E"'M(P%:`p'15_10`!<nVt"TALQ>PF8WL
	Z:#f!!!!j78?7R6=>B
	ASCII85End
End

Window 	NumberPanel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(974,35,1243,180) /K=1

	//  the Counter
	SetDrawLayer UserBack
	DrawText 24,68,"Click the Number:"
	DrawLine 50,50,20,20				// just test
	CustomControl ccClickTheNumber,pos={182,37},size={28,49},proc=MyCC_CounterFunc1
	CustomControl ccClickTheNumber,userdata= A"!!!!$",picture= {ProcGlobal#Numbers0to9_1,10}

	//  the Color field 1
	CustomControl ccColorField,pos={160,100}, proc=MyCC_ColorFieldFunc
	// CustomControl ccColorField, userdata= A"!!!!$"						// not needed
	CustomControl ccColorField, picture= {FPPulseProc#cb6WatchWrite339c,4}	// divide 6 pictures into 4 
	CustomControl ccColorField, value =root:uf:com:gDICOLTXT	

	//  the Color field 2
	CustomControl ccColorField2,pos={160,130}, proc=MyCC_ColorFieldFunc2
	CustomControl ccColorField2, picture= {FPPulseProc#cb6WatchWrite339c,6}	// 6 pictures are OK
	CustomControl ccColorField2, value =root:uf:com:gDICOLTXT	
EndMacro

///////////////////////  the Counter

Structure 	CC_CounterInfo1
	Int32 theCount		// current frame of 10 frame sequence of numbers in 
EndStructure


Function 	MyCC_CounterFunc1(s)
	STRUCT WMCustomControlAction &s

	STRUCT CC_CounterInfo1 info

	if (  s.eventCode != kCCE_idle  &&  s.eventCode != kCCE_mousemoved ) 
	//if (  s.eventCode != kCCE_mousemoved ) 
		printf "\tMyCC_CounterFunc1() \tnVal:%d \tEventCode:%2d    \t%s \r ", s.nVal,  s.eventCode, pd( StringFromList( s.eventCode, lstEVENTCODES ), 8 )
	endif	

	if( s.eventCode==kCCE_frame )
		StructGet/S info,s.userdata
		s.curFrame= mod(info.theCount+(s.curFrame!=0),10)
	elseif( s.eventCode==kCCE_mouseup )
		StructGet/S info,s.userdata
		info.theCount= mod(info.theCount+1,10)
		StructPut/S info,s.userdata	// will be written out to control
	elseif( s.eventCode==kCCE_modernize )
		// print " *****modernize gCC"
	endif
	
	return 0
End

///////////////////////  the Color field

Function 	MyCC_ColorFieldFunc( s )
	STRUCT WMCustomControlAction &s

	if (  s.eventCode != kCCE_idle  &&  s.eventCode != kCCE_mousemoved ) 
		// printf "\tMyCC_ColorFieldFunc() \tnVal:%d \tEventCode:%2d    \t%s \r ", s.nVal,  s.eventCode, pd( StringFromList( s.eventCode, lstEVENTCODES ), 8 )
	endif	
	if( s.eventCode==kCCE_frame )	// could / should use kCCE_draw ?
		s.curFrame= s.nVal
	endif
	return 0
End

///////////////////////  the Color field2

Function 	MyCC_ColorFieldFunc2( s )
	STRUCT WMCustomControlAction &s

	if (  s.eventCode != kCCE_idle  &&  s.eventCode != kCCE_mousemoved ) 
		// printf "\tMyCC_ColorFieldFunc2()\tnVal:%d \tEventCode:%2d    \t%s \r ", s.nVal,  s.eventCode, pd( StringFromList( s.eventCode, lstEVENTCODES ), 8 )
	endif	
	if( s.eventCode==kCCE_frame )	// could / should use kCCE_draw ?
		s.curFrame= s.nVal
	endif
	return 0
End


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	DIALOG:  DEBUGPRINT  OPTIONS

//  050530 This code is required also when not in DEBUG mode so it cannot be placed in FPTest.ipf  but is placed in FPulseMain.ipf  instead.
//Function		DebugPrintOptions()
//	string  	sFolder		= ksCOM					// must work both in  Acq  and  in  Eval 
//	string  	sPnOptions	= ":dlg:tDebugPrint"			
//	InitPanelDebugPrintOptions(  sFolder, sPnOptions )
//	ConstructOrDisplayPanel(  "PnDebug",  "Debug Print Options" , sFolder, sPnOptions, 90, 0 )
//	DebugPrintDeselectAll()							// Start the panel with options set to 'No printing'  (cannot be static)
//End
//
//// 050504  - 050530 This code is required also when not in DEBUG mode so it cannot be placed in FPTest.ipf  but is placed in FPulseMain.ipf  instead.
////static  strconstant  csDEBUG_SECTIONS	= " Timer; CfsRd; ShowLines; ShowKeys; ShowIO; ShowVal; ShowAmpTim; ShowEle; Expand; Digout; OutElems; Telegraph; CedInit; AcqDA; AcqAD; CfsWr; DispDurAcq; WndArrange" 
////static  strconstant  csDEBUG_DEPTHALL	= " Nothing; Modules; Functions"
////static  strconstant  csDEBUG_DEPTHSEL	= " Nothing; Functions; Loops; Details; Everything"
////
////Function		InitPanelDebugPrintOptions(  sFolder, sPnOptions )
////	string  	sFolder, sPnOptions
////	string		sPanelWvNm = "root:uf:" + sFolder + sPnOptions
////	variable	n = -1, nItems = 40
////	make /O /T /N=(nItems)	   $sPanelWvNm
////	wave  /T	tPn			= $sPanelWvNm	
////	//						TYPE	;   FLEN	;FORM; LIM;PRC;  	NAM						; TXT				
////	n = PnControl(	tPn, n, 1, ON, 	"PN_RADIO", 	 kVERT, " Depth (all): ",	"root:uf:dlg:gRadDebgGen",  csDEBUG_DEPTHALL ,	"Debug Depth all",  	"" , 	kWIDTH_NORMAL, sFolder ) 	
////	n = PnControl(	tPn, n, 1, ON, 	"PN_RADIO", 	 kVERT, " Depth (select):",	"root:uf:dlg:gRadDebgSel",   csDEBUG_DEPTHSEL ,	"Debug Depth select",  "" , kWIDTH_NORMAL, sFolder ) 	
////	n = PnControl(	tPn, n, 1, ON, 	"PN_CHKBOX", kVERT, "Selection:",	"root:uf:dlg:Debg",  		   csDEBUG_SECTIONS ,	"Debug Selection",  	"" , 	kWIDTH_NORMAL, sFolder ) 		
////	n += 1;	tPn[ n ]	= 		"PN_BUTTON; 	buDebugSelectAll		; Select all"			
////	n += 1;	tPn[ n ]	= 		"PN_BUTTON; 	buDebugDeselectAll		; Deselect all"			
////	redimension   /N=(n+1)	tPn
////End
//
//
//Function		buDebugSelectAll( ctrlName ) : ButtonControl
//	string 	ctrlName
//	DebugPrintSelectAll()
//End
//
//Function		buDebugDeselectAll( ctrlName ) : ButtonControl
//	string		ctrlName
//	DebugPrintDeselectAll()
//End
//
//Function	DebugPrintDeselectAll()
//	//  we must turn EVERYTHING OFF (especially ..SelFunc,..SelLoop, ..SelAll) to gain the speed advantage
//	RadioCheckUncheck( "root_uf_dlg_gRadDebgSel_0_5", 1 ) 			// Turn 'Nothing' sel radio button on, all others OFF	
//	ChkboxSetAll(  "root:uf:dlg:Debg" , FALSE )						// = ShowIO, ShowEle, Expand, CFS...
//End
//
//static Function	DebugPrintSelectAll()
//	RadioCheckUncheck( "root_uf_dlg_gRadDebgSel_2_5", 1 ) 			// Turn 'Loop' sel radio button on, all others OFF	(turning 'Everything' on would give too much information)
//	ChkboxSetAll(  "root:uf:dlg:Debg" , TRUE )						// = ShowIO, ShowEle, Expand, CFS...
//End
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//      DIALOG  :   MULTICLAMP700  PANEL

Function  		MC700Dlg()
	string  	sFolder		= ksCOM			
	string  	sPnOptions	= ":dlg:tPnMC700"	
	InitPanelMC700(  sFolder, sPnOptions )
	ConstructOrDisplayPanel(  "PnMC700",  "MC700" , sFolder, sPnOptions, 100, 50 )

	EnableButton( "PnMC700", "buMC700CreateObject",			kENABLE )
	EnableButton( "PnMC700", "buMC700ScanAllMultiClamps",		kDISABLE )
	EnablePopup( "PnMC700", "root_uf_misc_MC700_gpSelectMCC",kDISABLE )
	EnableButton( "PnMC700", "buMC700SetModeVC",			kDISABLE )
	EnableButton( "PnMC700", "buMC700SetModeCC",			kDISABLE )
	EnableButton( "PnMC700", "buMC700Reset",				kDISABLE )
	EnableButton( "PnMC700", "buMC700DestroyObject",			kDISABLE )
End

Function		InitPanelMC700( sFolder, sPnOptions )
	string  	sFolder, sPnOptions
	string		sPanelWvNm = 	  "root:uf:" + sFolder + sPnOptions
	variable	n = -1, nItems = 30		

	ConstructAndMakeItCurrentFolder( "root:uf:misc:MC700" )
	string  	/G				root:uf:misc:MC700:glstlstAllMCCIds 	= ""
	string  	/G				root:uf:misc:MC700:glstPopupMCCs	= "" 	
	variable	/G				root:uf:misc:MC700:gpSelectMCC
	variable	/G				root:uf:misc:MC700:hMCCmsg
	variable	/G				root:uf:misc:MC700:gDebugMsg	= 0


	make /O /T /N=(nItems)	$sPanelWvNm
	wave  /T	tPn		= 	$sPanelWvNm
	n += 1;	tPn[ n ] =	"PN_SEPAR	; ;--- Set and Get MC700 state [MC700] ---"
	n += 1;	tPn[ n ] =	"PN_BUTTON;	buMC700CheckAPIVersion			;CheckAPIVersion"
	n += 1;	tPn[ n ] =	"PN_BUTTON;	buMC700CreateObject			;CreateObject"
	n += 1;	tPn[ n ] =	"PN_BUTTON;	buMC700ScanAllMultiClamps		;Scan All MultiClamps"
	n += 1;	tPn[ n ] =	"PN_POPUP  ;	root:uf:misc:MC700:gpSelectMCC;; 	200	;   1	;gpSelectMCC_Lst; gpSelectMCC  "	// Sample: Default value (Par4) supplied, reset on panel rebuild.
//	n += 1;	tPn[ n ] =	"PN_POPUP  ;	root:uf:misc:MC700:gpMC700	;; 	200	;	;gpSelectMCC_Lst; gpSelectMCC  "	// Sample: No default value (Par4) supplied, set only at program start. PrintResults needs an explicit action procedure 
	n += 1;	tPn[ n ] =	"PN_BUTTON;	buMC700SetModeVC				;Set Mode VC"
	n += 1;	tPn[ n ] =	"PN_BUTTON;	buMC700SetModeCC				;Set Mode CC"
	n += 1;	tPn[ n ] =	"PN_BUTTON;	buMC700GetMode				;Get Mode"
	n += 1;	tPn[ n ] =	"PN_BUTTON;	buMC700SetGain1				;Set Gain 1"
	n += 1;	tPn[ n ] =	"PN_BUTTON;	buMC700SetGain100				;Set Gain100"
	n += 1;	tPn[ n ] =	"PN_BUTTON;	buMC700GetGain				;Get Gain"
	n += 1;	tPn[ n ] =	"PN_BUTTON;	buMC700Reset					;Reset"
	n += 1;	tPn[ n ] =	"PN_BUTTON;	buMC700DestroyObject			;DestroyObject"
	n += 1;	tPn[ n ] =	"PN_SEPAR	; ;--- Process the MC700 telegraphs [MC700Tg] ---"
	n += 1;	tPn[ n ] =	"PN_SETVAR;	root:uf:misc:MC700:gDebugMsg		;Debug messages (none:0, all:4); 	20; 	%1d ;0,4,1;	"			
	n += 1;	tPn[ n ] =	"PN_BUTTON;	buMC700TgDisplayAvailChans		;Display available MC700 TG channels"
	n += 1;	tPn[ n ] =	"PN_SEPAR;	"
	n += 1;	tPn[ n ] =	"PN_BUTTON;	buNumberTest					;NumberTest (largest integer?)"
	redimension  /N = ( n+1)	tPn	
End

static constant		kMC700_MODEL	= 0 ,   kMC700_SERIALNUM	= 1 ,  kMC700_COMPORT = 2 ,   kMC700_DEVICE = 3 ,  kMC700_CHANNEL = 4
static strconstant	lstMC700_ID		= "Model;Serial#;COMPort;Device;Channel;"	// Assumption : Order is MoSeCoDeCh (same as in XOP)
static	 strconstant	kMC700_MODELS	= "700A;700B"
static constant		kMC700_MODE_VC	= 0 ,   kMC700_MODE_CC	= 1
static	 strconstant	kMC700_MODES	= "VC;IC;I=0"


//===========================================================================================
//  Action  procedures  for  MCC700 : 		---  Process the MC700 telegraphs [ XOP = MC700Tg ] ---

Function		root_uf_misc_MC700_gDebugMsg( ctrlName, varNum, varStr, varName ) : SetVariableControl
//Function		gDebugMsg( ctrlName, varNum, varStr, varName ) : SetVariableControl
	string		ctrlName, varStr, varName
	variable	varNum
	nvar		gDebugMsg	= root:uf:misc:MC700:gDebugMsg	
	print "\t\t" , ctrlName, gDebugMsg
	UFP_MCTgDebugMsg( gDebugMsg )
End

Function		buMC700TgDisplayAvailChans( ctrlName ) : ButtonControl
	string 	ctrlName		
	DisplayAvailMCTgChans()
End

//===========================================================================================
//  Action  procedures  for  MCC700 : 		--- Set and Get MC700 state [ XOP = MC700 ] ---

Function		buMC700CheckAPIVersion( ctrlName ) : ButtonControl
	string 	ctrlName		
	variable	nCode	= UFP_MCCMSG_CheckAPIVersion()		
	print	 	"\t\t", ctrlName, nCode
End


Function		buMC700CreateObject( ctrlName ) : ButtonControl
	string 	ctrlName		
//	ConstructAndMakeItCurrentFolder( "root:uf:misc:MC700" )
//	string  	/G				root:uf:misc:MC700:glstlstAllMCCIds 	= ""
//	string  	/G				root:uf:misc:MC700:glstPopupMCCs	= "" 	
//	variable	/G				root:uf:misc:MC700:gpSelectMCC
//	variable	/G				root:uf:misc:MC700:hMCCmsg
	nvar		hMCCmsg	    	= 	root:uf:misc:MC700:hMCCmsg
	hMCCmsg	= UFP_MCCMSG_CreateObject()
	printf	 "\t\t%s :  \t\t0x%08x  %d \r", ctrlName, hMCCmsg, hMCCmsg
	if ( hMCCmsg ) 
		EnableButton( "PnMC700", "buMC700CreateObject",		kDISABLE )
		EnableButton( "PnMC700", "buMC700ScanAllMultiClamps",	kENABLE )
		EnableButton( "PnMC700", "buMC700DestroyObject",		kENABLE )
	else
		printf	"Error: Could not 'CreateObject'  \t%s :  \t\t0x%08x  %d \r", ctrlName, hMCCmsg, hMCCmsg
	endif
End


Function		buMC700ScanAllMultiClamps( ctrlName ) : ButtonControl
	string 	ctrlName		
	nvar		hMCCmsg		= root:uf:misc:MC700:hMCCmsg
	svar		glstlstAllMCCIds = root:uf:misc:MC700:glstlstAllMCCIds 	
	svar		glstPopupMCCs = root:uf:misc:MC700:glstPopupMCCs 	
	nvar		gpSelectMCC	= root:uf:misc:MC700:gpSelectMCC
	if ( hMCCmsg )
		glstlstAllMCCIds	= UFP_MCCScanMultiClamps( hMCCmsg )
		printf	"\t\t%s \t0x%08x  %d     Items:%d    '%s'  \r", ctrlName, hMCCmsg, hMCCmsg, ItemsInList( glstlstAllMCCIds, "~" ), glstlstAllMCCIds	
		glstPopupMCCs	= SelectMCCList()
		gpSelectMCC	= 0
		ControlUpdate	/W=$"PnMC700"   root_uf_misc_MC700_gpSelectMCC 
		EnablePopup( "PnMC700", "root_uf_misc_MC700_gpSelectMCC", kENABLE )
	else
		glstlstAllMCCIds	= ""
		glstPopupMCCs	= ""
		Alert( kERR_IMPORTANT, "Communication with MultiClamp(s) not ready.  (" + ctrlName + ") " )
		gpSelectMCC	= -1//Nan
		PopupMenu	  root_uf_misc_MC700_gpSelectMCC 	 mode = 1, popvalue = "No device"
	endif
End


Function		gpSelectMCC( sControlNm, popNum, popStr ) : PopupMenuControl
	string		sControlNm, popStr
	variable	popNum
	nvar		gpSelectMCC	= root:uf:misc:MC700:gpSelectMCC
	gpSelectMCC	= popNum - 1										// popNum starts at 1
	printf "\t\t\tgpSelectMCC( '%s' ) selects %d  :  '%s' \r",  sControlNm, popNum, popStr
	nvar		hMCCmsg		= root:uf:misc:MC700:hMCCmsg
	if ( hMCCmsg )
		svar		glstlstAllMCCIds = root:uf:misc:MC700:glstlstAllMCCIds 	
		variable	rnModel, rnCOMPort, rnDevice, rnChannel 				
		string  	rsSerialNumber									
		ExtractMC700Identifications( gpSelectMCC, glstlstAllMCCIds, rnModel, rsSerialNumber, rnCOMPort, rnDevice, rnChannel ) 	// references are changed here and returned
		variable	nCode	= UFP_MCCMSG_SelectMultiClamp( hMCCmsg, rnModel, rsSerialNumber, rnCOMPort, rnDevice, rnChannel )
		if ( nCode == 0 )
			Alert( kERR_IMPORTANT, sControlNm + " failed. " )
		else
			EnableButton( "PnMC700", "buMC700SetModeVC",		kENABLE )
			EnableButton( "PnMC700", "buMC700SetModeCC",		kENABLE )
			EnableButton( "PnMC700", "buMC700Reset",			kENABLE )
		endif		
	endif		
End

Function		gpSelectMCC_Lst( sControlNm )
// fills in the entries in the popupmenu for the MC700 selection 
	string			sControlNm
	// print "\t\tgpSelectMCC_Lst()    sControlNm: " ,  sControlNm
	PopupMenu	$sControlNm	 value = SelectMCCList()
	PopupMenu	$sControlNm	 mode = 1, popvalue = "No device"
End

Function		buMC700SetModeVC( ctrlName ) : ButtonControl
	string 	ctrlName		
	MC700SetMode( kMC700_MODE_VC )
End

Function		buMC700SetModeCC( ctrlName ) : ButtonControl
	string 	ctrlName		
	MC700SetMode( kMC700_MODE_CC )
End

Function		buMC700GetMode( ctrlName ) : ButtonControl
	string 	ctrlName		
	variable	nMode	= MC700GetMode()
	printf "\t\t%s\tMode:\t%s\t(%d) \r", ctrlName, StringFromList( nMode, kMC700_MODES ),  nMode
End

Function		buMC700SetGain1( ctrlName ) : ButtonControl
	string 	ctrlName		
	MC700SetGain( 1 )
End

Function		buMC700SetGain100( ctrlName ) : ButtonControl
	string 	ctrlName		
	MC700SetGain( 100 )
End

Function		buMC700GetGain( ctrlName ) : ButtonControl
	string 	ctrlName		
	variable	Gain	= MC700GetGain()
	printf "\t\t%s\tGain: %.1lf \r", ctrlName, Gain
End



Function		buMC700Reset( ctrlName ) : ButtonControl
	string 	ctrlName		
	nvar		hMCCmsg		= root:uf:misc:MC700:hMCCmsg
	if ( hMCCmsg )
		variable	nCode		= UFP_MCCMSG_Reset( hMCCmsg )
		if ( nCode == 0 )
			Alert( kERR_IMPORTANT, ctrlName + " failed. " )
		endif		
	else
		Alert( kERR_IMPORTANT, "Communication with MultiClamp(s) not ready.  (" + ctrlName + ") " )
	endif
End

Function		buMC700DestroyObject( ctrlName ) : ButtonControl
	string 	ctrlName		
	nvar		hMCCmsg		= root:uf:misc:MC700:hMCCmsg
	nvar		gpSelectMCC	= root:uf:misc:MC700:gpSelectMCC
	svar		glstlstAllMCCIds = root:uf:misc:MC700:glstlstAllMCCIds 	
	svar		glstPopupMCCs = root:uf:misc:MC700:glstPopupMCCs 	
	if ( hMCCmsg )
		UFP_MCCMSG_DestroyObject( hMCCmsg )
	else
		Alert( kERR_IMPORTANT, "Communication with MultiClamp(s) not ready.  (" + ctrlName + ") " )
	endif
	hMCCmsg		= 0			// also set to  NULL in XOP
	gpSelectMCC	= -1
	glstlstAllMCCIds	= ""
	glstPopupMCCs	= ""
	PopupMenu	  root_uf_misc_MC700_gpSelectMCC	 mode = 1, popvalue = "No device"
	EnableButton( "PnMC700", "buMC700CreateObject",			kENABLE )
	EnableButton( "PnMC700", "buMC700ScanAllMultiClamps",		kDISABLE )
	EnablePopup( "PnMC700", "root_uf_misc_MC700_gpSelectMCC",kDISABLE )
	EnableButton( "PnMC700", "buMC700SetModeVC",			kDISABLE )
	EnableButton( "PnMC700", "buMC700SetModeCC",			kDISABLE )
	EnableButton( "PnMC700", "buMC700Reset",				kDISABLE )
	EnableButton( "PnMC700", "buMC700DestroyObject",			kDISABLE )
End

//===========================================================================================
//  Helpers  for  MCC700

Function	/S	SelectMCCList()
// fills in the entries in the popupmenu for the MC700 selection 
	svar		glstlstAllMCCIds = root:uf:misc:MC700:glstlstAllMCCIds 	
	string  	lstPopupMCCs	= ""
	variable	mcc, nMCCs	= ItemsInList( glstlstAllMCCIds, "~" )	
	for ( mcc = 0; mcc < nMCCs; mcc += 1 )
		variable	rnModel, rnCOMPort, rnDevice, rnChannel 				
		string  	rsSerialNumber									
		ExtractMC700Identifications( mcc, glstlstAllMCCIds, rnModel, rsSerialNumber, rnCOMPort, rnDevice, rnChannel ) 	// references are changed here and returned
		string  	sModel	= StringFromList( rnModel, kMC700_MODELS )
		// printf "\t\t\tSelectMCCPopupList()\tMCC:%d/%d\tMo:%s (%d)\tCh:%d \tCo:%d \tDe:%d \tSN:%s \r", mcc, nMCCs, sModel, rnModel, rnChannel, rnDevice,  rnCOMPort, rsSerialNumber
		string  	sPopup1MCC
		string  	sName	= SelectString( rnModel , StringFromList( kMC700_COMPORT, lstMC700_ID ),	StringFromList( kMC700_SERIALNUM, lstMC700_ID ) )
		string  	sComOrSer= SelectString( rnModel , num2str( rnCOMPort ),	rsSerialNumber )
		string  	sDeviceNm= SelectString( rnModel , StringFromList( kMC700_DEVICE, lstMC700_ID ) , "" )
		string  	sDevice	= SelectString( rnModel ,  num2str( rnDevice )  , "" )
		sprintf sPopup1MCC, "%s   Ch:%d   %s:%s   %s %s", sModel, rnChannel, sName, sComOrSer, sDeviceNm[0,2], sDevice		
		lstPopupMCCs	+= sPopup1MCC + ";"
	endfor	
	// print "\t\tSelectMCCPopupList()", lstPopupMCCs
	return	lstPopupMCCs
End


Function		ExtractMC700Identifications( nMCC, lstlstAllMCCIds, rnModel, rsSerialNumber, rnCOMPort, rnDevice, rnChannel ) 
	variable	nMCC
	string  	lstlstAllMCCIds
	variable	&rnModel, &rnCOMPort, &rnDevice, &rnChannel 				// references are changed here and returned
	string  	&rsSerialNumber										// references are changed here and returned
	string  	lstOneMCCId	= StringFromList( nMCC, lstlstAllMCCIds, "~" )
	rnModel		= str2num( StringFromList( kMC700_MODEL, 		lstOneMCCId ) ) 
	rsSerialNumber	= 		StringFromList( kMC700_SERIALNUM, 	lstOneMCCId ) 
	rnCOMPort	= str2num( StringFromList( kMC700_COMPORT, 	lstOneMCCId ) ) 
	rnDevice		= str2num( StringFromList( kMC700_DEVICE, 		lstOneMCCId ) ) 
	rnChannel		= str2num( StringFromList( kMC700_CHANNEL, 	lstOneMCCId ) ) 
End 


Function		MC700SelectMultiClamp( nModel, sSerialNumber, nCOMPort, nDevice, nChannel )
	variable	nModel, nCOMPort, nDevice, nChannel 
	string  	sSerialNumber
	nvar		hMCCmsg		= root:uf:misc:MC700:hMCCmsg
	if ( hMCCmsg )
		variable	nCode	= UFP_MCCMSG_SelectMultiClamp( hMCCmsg, nModel, sSerialNumber, nCOMPort, nDevice, nChannel )
		if ( nCode == 0 )
			Alert( kERR_IMPORTANT, "MC700SelectMultiClamp() failed. " )
		endif		
	else
		Alert( kERR_IMPORTANT, "MC700SelectMultiClamp() failed as communication with MultiClamp(s) was not ready." )
	endif
End


Function		MC700SetMode( nMode ) 
	variable	nMode
	nvar		hMCCmsg		= root:uf:misc:MC700:hMCCmsg
	if ( hMCCmsg )
		variable	nCode	= UFP_MCCMSG_SetMode( hMCCmsg, nMode )
		if ( nCode == 0 )
			Alert( kERR_IMPORTANT, "MC700SetMode() failed. " )
		endif		
	else
		Alert( kERR_IMPORTANT, "MC700SetMode() failed as communication with MultiClamp(s) was not ready." )
	endif
End

Function		MC700GetMode()
	nvar		hMCCmsg		= root:uf:misc:MC700:hMCCmsg
	variable	nMode	= -1
	if ( hMCCmsg )
		nMode	= UFP_MCCMSG_GetMode( hMCCmsg )
	else
		Alert( kERR_IMPORTANT, "MC700GetMode() failed as communication with MultiClamp(s) was not ready." )
	endif
	return	nMode
End

Function		MC700SetGain( Gain ) 
	variable	Gain
	nvar		hMCCmsg		= root:uf:misc:MC700:hMCCmsg
	if ( hMCCmsg )
		variable	nCode	= UFP_MCCMSG_SetPrimSignalGain( hMCCmsg, Gain )
		if ( nCode == 0 )
			Alert( kERR_IMPORTANT, "MC700SetGain() failed. " )
		endif		
	else
		Alert( kERR_IMPORTANT, "MC700SetGain() failed as communication with MultiClamp(s) was not ready." )
	endif
End

Function		MC700GetGain()
	nvar		hMCCmsg		= root:uf:misc:MC700:hMCCmsg
	variable	Gain	= -1
	if ( hMCCmsg )
		Gain	= UFP_MCCMSG_GetPrimSignalGain( hMCCmsg )
	else
		Alert( kERR_IMPORTANT, "MC700GetGain() failed as communication with MultiClamp(s) was not ready." )
	endif
	return Gain
End

Function		MC700GetSecondaryGain()
	nvar		hMCCmsg		= root:uf:misc:MC700:hMCCmsg
	variable	Gain	= -1
	if ( hMCCmsg )
		Gain	= UFP_MCCMSG_GetSecoSignalGain( hMCCmsg )
	else
		Alert( kERR_IMPORTANT, "MC700GetSecondaryGain() failed as communication with MultiClamp(s) was not ready." )
	endif
	return Gain
End

Function		buNumberTest( ctrlName ) : ButtonControl
	string 	ctrlName		
	// Does Igor represent 32 bit integers correctly ? YES - tested up to 5e11 
	variable	n
	variable	nBeg		= 100000000
	variable	nStep	= 39999997
	variable	nEnd		= 5e11
	for ( n = nBeg; n < nEnd; n += nStep )
		printf "%10d   %.15lf   %.15lf \r", n, n, n - round( n )
	endfor
End



