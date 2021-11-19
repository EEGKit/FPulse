// 2021-11-10  Copied, modified and renamed from Igor6  AxonTelegraphMonitor.ipf , contains still much unnecessary stuff which could be removed
//
//		Goal is to allow for a 64 bit version of FPulse by replacing/eliminating the FP_MC700TG XOP  which is limited to 32 bit 
//		Main differences to original file AxonTelegraphMonitor.ipf:
//			Is no longer Independent module, instead static functions  and specific naming (FP_xxx) is used
//			FPulse panel construction frame work is used, some data e.g RS compensation are not displayed
//			Panel displays data of _all_ server channels, not just those of the selected one
//			Scanning of servers and statting the monitoring background task is done automatically when panel is opened
//			TimeOut time is not adjustable but fixed internally
//
//	ToDo
// 			Ensure that the servers are scanned and that the monitoring background task is started whenever a script containing Axon MultiClamp channels is loaded...
//			...perhaps wihout or with hidden panel 'axon telegraph Gain'		

#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=6.1	// Control panel features and named background tasks.
//#pragma Version=1.0
//#pragma IndependentModule=AxonTelegraphPanel

// REVISION HISTORY
// Version		Description
// 1.0			Initial release



// Igor structure that should be used with the AxonTelegraphGetDataStruct() external function.
Structure AxonTelegraph_DataStruct
	uint32 Version			// Structure version.  Value should always be 13.
	uint32 SerialNum
	uint32 ChannelID
	uint32 ComPortID
	uint32 AxoBusID
	uint32 OperatingMode
	String OperatingModeString
	uint32 ScaledOutSignal
	String ScaledOutSignalString
	double Alpha
	double ScaleFactor
	uint32 ScaleFactorUnits
	String ScaleFactorUnitsString
	double LPFCutoff
	double MembraneCap
	double ExtCmdSens
	uint32 RawOutSignal
	String RawOutSignalString
	double RawScaleFactor
	uint32 RawScaleFactorUnits
	String RawScaleFactorUnitsString
	uint32 HardwareType
	String HardwareTypeString
	double SecondaryAlpha
	double SecondaryLPFCutoff
	double SeriesResistance
EndStructure

Constant kTelegraphDataStructVersion = 13
Constant kBackgroundTaskPeriod = 30

StrConstant kAxonTelegraphPanelName = "pnlAxonTelegraphPanel"
StrConstant kAxonTelegraphPanelDF = "root:AxonTelegraphPanel"

//Menu "Misc", hideable
//	"Axon Telegraph Data", /Q, AxonTelegraphDataPanel()
//end

///////////////////////////////////////////////////////////////
// INITIALIZATION AND PANEL BUILDING
///////////////////////////////////////////////////////////////

// 2021-11-10  Use AxonTelegraph Xop
//**
// Initializes globals and builds the panel.
//*
Function		Dlg_AxonTgGain( nMode )
	variable	nMode					//  kPN_INIT  or  kPN_DRAW

	string  	sFBase		= ksROOTUF_
	string  	sFSub		= ksfACO_	
	string  	sWin		= "AxTg" 
	string	sPnTitle		= "Axon Telegraph Gain"

	if ( WinType( sWin ) == kPANEL )
		KillWindow $sWin			// in order to alow resizing of panel when number of servers changes
	endif
		
	FP_TG_Initialize()
	string 	lstServer	= FP_TG_ScanForServers()
	FP_TG_StartMonitoring()
	//printf "\t\tLstServ()\t\twould return  \t\t'%s' \t(when building panels sections) \r\t\t\t\t%s \r",  LstServ( "","","" ) , lstServer

	string	sDFSave		= GetDataFolder( 1 )						// The following functions do NOT restore the CDF so we remember the CDF in a string .
	PossiblyCreateFolder( sFBase + sFSub + sWin ) 
	SetDataFolder sDFSave											// Restore CDF from the string  value
	stInitPanelAxonTgGain( sFBase + sFSub, sWin )						// fills big text wave  'sPnOptions' (=wPn)  with all information about the controls necessary to build the panel
	Panel3Sub_(   sWin, 	sPnTitle, 	sFBase + sFSub,  90, 80,  nMode, 1 ) // Compute the location of panel controls and the panel dimensions. Draw the panel displaying and hiding needed/unneeded controls.  Last par:1 allows closing
	PnLstPansNbsAdd( ksfACO,  sWin )
	SetWindow $sWin hook(FP_AxonTelegraphPanel)=FP_AxonTelegraphMonitor_Hook
End

static Function	stInitPanelAxonTgGain( sF, sPnOptions )
	string  	sF, sPnOptions
	string	sPanelWvNm = sF + sPnOptions
	variable	n = -1, nItems = 20
	// printf "\tstInitPanelAxonTgGain( '%s',  '%s' ) \r", sF, sPnOptions 
	make /O /T /N=(nItems)	$sPanelWvNm
	wave  /T	tPn	=		$sPanelWvNm
	// Cave / Flaw :   No tabcontrol = empty  'Tabs'  must have   different number of spaces (no Tab, not the empty string )  to be recognised correctly
	// Cave / Flaw :   For each item in  'Tabs'   there must be a  corresponding  'Blks'  entry  even if empty
	// Cave / Flaw :	   Only tabulators can be used  for aligning the following columns, do not use spaces.... (maybe they are allowed...)
	//					Type  NxL Pos MxPo OvS Tabs 	Blks			Mode	Name		RowTi									ColTi  ActionProc			XBodySz	FormatEntry			Initval		Visibility	SubHelp

//	//  High and narrow panel
//	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:		LstServ():	1,°:		sep10:		:										:	:					:		:					:			:		:	"		
//	n += 1;	tPn[ n ] =	"STR:  1:	0:	1:	0:	°:		LstServ():	1,°:		strServer:	Server:									:	:					210:		:					:			:		:	"		
//	n += 1;	tPn[ n ] =	"STR:  1:	0:	4:	1:	°:		LstServ():	1,°:		strTyp:		Type:									:	:					100:		:					:			:		:	"		
//	n += 1;	tPn[ n ] =	"SV:    0:	4:	8:	0:	°:		LstServ():	1,°:		svTyp:		   :										:	:					24:		%2d; 0,100,0:		:			:		:	"		
//	n += 1;	tPn[ n ] =	"SV:    1:	0:	2:	0:	°:		LstServ():	1,°:		svSerNum:	Serial number:							:	:					50:		%7d; 0,10000000,0:	:			:		:	"		
//	n += 1;	tPn[ n ] =	"SV:    0:	1:	2:	0:	°:		LstServ():	1,°:		svChanID:	   Channel ID:								:	:					60:		%2d; 0,100,0:		:			:		:	"		
//	n += 1;	tPn[ n ] =	"SV:    1:	0:	2:	0:	°:		LstServ():	1,°:		svComPrt	:	Com Port /A:								:	:					50:		%2d; 0,100,0:		:			:		:	"		
//	n += 1;	tPn[ n ] =	"SV:    0:	1:	2:	0:	°:		LstServ():	1,°:		svAxoBus:	   Axobus /A:								:	:					60:		%2d; 0,100,0:		:			:		:	"		
//	n += 1;	tPn[ n ] =	"STR:  1:	0:	2:	0:	°:		LstServ():	1,°:		strMode:		Operating Mode:							:	:					50:		:					:			:		:	"		
//	n += 1;	tPn[ n ] =	"SV:    0:	4:	8:	0:	°:		LstServ():	1,°:		svOpMode:	   :										:	:					24:		%2d; 0,100,0:		:			:		:	"		
//	n += 1;	tPn[ n ] =	"SV:    1:	0:	2:	0:	°:		LstServ():	1,°:		svPriScl:		Prim Scale Factor:							:	:					50:		%.2f; 0,10000,0:		:			:		:	"		
//	n += 1;	tPn[ n ] =	"STR:  0:	4:	8:	1:	°:		LstServ():	1,°:		strPriSclU:	:										:	:					66:		:					:			:		:	"		
//	n += 1;	tPn[ n ] =	"SV:    1:	0:	2:	0:	°:		LstServ():	1,°:		svPriGn:		Prim Output Gain:							:	:					50:		%4d; 0,10000,0:		:			:		:	"		
//	n += 1;	tPn[ n ] =	"SV:    0:	1:	2:	0:	°:		LstServ():	1,°:		svPriFil:		   Bessel / Hz:								:	:					60:		%.2f; 0,100000,0:		:			:		:	"		
//	n += 1;	tPn[ n ] =	"SV:    1:	0:	2:	0:	°:		LstServ():	1,°:		svSecGn:		Sec  Output Gain:							:	:					50:		%4d; 0,10000,0:		:			:		:	"		
//	n += 1;	tPn[ n ] =	"SV:    0:	1:	2:	0:	°:		LstServ():	1,°:		svSecFil:		   Bessel / Hz:								:	:					60:		%.2f; 0,100000,0:		:			:		:	"		
//	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:		,:			1,°:		sep20:		:										:	:					:		:					:			:		:	"		
//	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	°:		,:			1,°:		buCmpTg:	Compare  Axon vs FP_MC700Tg  telegraphs:	: fCompareTgData_fp():	:		:					:			:		:	"		
//	n += 1;	tPn[ n ] =	"RAD:  1:	0:	1:	0:	°:		,:			1,°:		raTgSrc:		:				Axon TG Xop,FP_MC700TG:		:					:		:					0001_1~0:	:		:	"		//	1-dim horz radios
// // n += 1;	tPn[ n ] =	"RAD:  1:	0:	1:	0:	°:		,:			1,°:		raTgSrc:		Axon TG Xop,FP_MC700TG:					:	:					:		:					0010_1~0:	:		:	"		//	1-dim vert radios


	//  Low and wide panel
	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:		LstServ():	1,°:		sep10:		:										:	:					:		:					:			:		:	"		
	n += 1;	tPn[ n ] =	"STR:  1:	0:	4:	2:	°:		LstServ():	1,°:		strServer:	Server:									:	:					300:		:					:			:		:	"		
	n += 1;	tPn[ n ] =	"STR:  1:	0:	4:	0:	°:		LstServ():	1,°:		strTyp:		Typ:										:	:					86:		:					:			:		:	"		
	n += 1;	tPn[ n ] =	"SV:    0:	1:	4:	0:	°:		LstServ():	1,°:		svTyp:		Typ no:									:	:					50:		%4d; 0,100,0:		:			:		:	"		
	n += 1;	tPn[ n ] =	"SV:    0:2:	4:	0:	°:		LstServ():	1,°:		svSerNum:	Serial no:									:	:					50:		%7d; 0,10000000,0:	:			:		:	"		
	n += 1;	tPn[ n ] =	"SV:    0:	3:	4:	0:	°:		LstServ():	1,°:		svChanID:	Chan ID:									:	:					50:		%4d; 0,100,0:		:			:		:	"		
	n += 1;	tPn[ n ] =	"STR:  1:	0:	4:	0:	°:		LstServ():	1,°:		strMode:		Mode:									:	:					50:		:					:			:		:	"		
	n += 1;	tPn[ n ] =	"SV:    0:	1:	4:	0:	°:		LstServ():	1,°:		svOpMode:	Mode no:								:	:					50:		%4d; 0,100,0:		:			:		:	"		
	n += 1;	tPn[ n ] =	"SV:    0:	2:	4:	0:	°:		LstServ():	1,°:		svComPrt	:	ComPrt-A:								:	:					50:		%4d; 0,100,0:		:			:		:	"		
	n += 1;	tPn[ n ] =	"SV:    0:	3:	4:	0:	°:		LstServ():	1,°:		svAxoBus:	Axobus-A:								:	:					50:		%4d; 0,100,0:		:			:		:	"		
	n += 1;	tPn[ n ] =	"SV:    1:	0:	4:	0:	°:		LstServ():	1,°:		svPriScl:		Prim Scl:									:	:					50:		%.2f; 0,10000,0:		:			:		:	"		
	n += 1;	tPn[ n ] =	"STR:  0:	1:	4:	0:	°:		LstServ():	1,°:		strPriSclU:	:										:	:					50:		:					:			:		:	"		
	n += 1;	tPn[ n ] =	"SV:    0:	2:	4:	0:	°:		LstServ():	1,°:		svPriGn:		Prim Gain:								:	:					50:		%4d; 0,10000,0:		:			:		:	"		
	n += 1;	tPn[ n ] =	"SV:    0:	3:	4:	0:	°:		LstServ():	1,°:		svPriFil:		Bessel/Hz:								:	:					50:		%.1f; 0,100000,0:		:			:		:	"		
	n += 1;	tPn[ n ] =	"SV:    1:	2:	4:	0:	°:		LstServ():	1,°:		svSecGn:		Sec Gain:									:	:					50:		%4d; 0,10000,0:		:			:		:	"		
	n += 1;	tPn[ n ] =	"SV:    0:	3:	4:	0:	°:		LstServ():	1,°:		svSecFil:		Bessel/Hz:								:	:					50:		%.1f; 0,100000,0:		:			:		:	"		
	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:		,:			1,°:		sep20:		:										:	:					:		:					:			:		:	"		
	n += 1;	tPn[ n ] =	"BU:    1:	0:	2:	0:	°:		,:			1,°:		buCmpTg:	Compare  Axon vs FP_MC700Tg  telegraphs:	: fCompareTgData_fp():	:		:					:			:		:	"		
	n += 1;	tPn[ n ] =	"RAD:  0:	1:	2:	0:	°:		,:			1,°:		raTgSrc:		:				Axon TG Xop,FP_MC700TG:		:					:		:					0001_1~0:	:		:	"		//	1-dim horz radios
   //	n += 1;	tPn[ n ] =	"RAD:  1:	0:	1:	0:	°:		,:			1,°:		raTgSrc:		Axon TG Xop,FP_MC700TG:					:	:					:		:					0010_1~0:	:		:	"		//	1-dim vert radios

	redimension  /N = ( n+1)	tPn
End

Function		TelegraphSource_fp()
// get selected radio buttons for telegraph source , either 'Axon TG Xop' or 'FP_MC700TG'
	nvar 	nSource	= $(ksROOTUF_ + ksfACO_ + "AxTg:" +"raTgSrc" + "00" )
	printf "\t\tTelegraphSource_fp()  \treturns nSource:%2d   = %s  \r", nSource, StringFromList( nSource, "Axon TG Xop,FP_MC700TG", "," )	// same as above in panel
	return 	nSource
End	

Function		fCompareTgData_fp( s )
// 2021-11-10   Get and display  Axon MC 700A or 700B  telegraph data from   FP_MC700TG XOP  and also  from AxonTelegraph XOP (for comparison, in order to make FP_MC700TG obsolete)
	struct	WMButtonAction &s
	TelegraphSource_fp()		// only for debug print
	FP_DisplayAvailMCTgChans()
End

Function /S 	LstServ( sBaseNm, sFo, sWin )
	string	sBaseNm, sFo, sWin
	string	currentDF = GetDataFolder(1)
	SetDataFolder $(kAxonTelegraphPanelDF)
	svar /Z	lstServers	= serverlist				// from XOP
	if ( ! svar_exists( lstServers ) ) 	
		SetDataFolder currentDF
		return ""
	endif
	variable	ns, nServer	= ItemsInList( lstServers )
	string  	lstServr	= ""
	for ( ns = 0; ns < nServer; ns += 1 )
		//lstServr	+= num2str( ns ) + "  " + ksSEP_STD	// for panel sections
		lstServr	+= ksSEP_STD						// for panel sections
	endfor
	SetDataFolder currentDF
	return	lstServr
End	

Function FP_AxonTelegraphMonitor_Hook(s)
	STRUCT WMWinHookStruct &s
	
	Switch (s.eventCode)
		Case 2:		// Window is being killed.
			NVAR/Z monitoring = $(kAxonTelegraphPanelDF+":currentlyMonitoring")
			if (NVAR_Exists(monitoring))
				monitoring = !monitoring
				Control_monitoring()
			endif
			break
	EndSwitch
	return 0
End


//**
// Initializes all global variables for the panel.
//*
Function FP_Tg_Initialize()
	String currentDF = GetDataFolder(1)
	NewDataFolder/O/S $(kAxonTelegraphPanelDF)
	
	// Variables
	Variable/G panelInitialized = 1
	Variable/G timeoutMs = AxonTelegraphGetTimeoutMs()
	if (!exists("currentSerialNum"))
		Variable/G currentSerialNum = NaN
	endif
	
	if (!exists("currentChannelID"))
		Variable/G currentChannelID = NaN
	endif

	if (!exists("currentComPortID"))
		Variable/G currentComPortID = NaN
	endif
	
	if (!exists("currentAxoBusID"))
		Variable/G currentAxoBusID = NaN
	endif	
				
	if (!exists("currentlyMonitoring"))
		Variable/G currentlyMonitoring =  0
	endif
	
	if (!exists("V_Flagsss"))
		Variable/G V_Flag = 0
	endif
	
	if (!exists("getLongStrings"))
		Variable/G getLongStrings = 1
	endif

// 2021-11-17 weg	
//	// Data variables
//	String globalVarList
//	globalVarList = "OperatingMode;ScaledOutSignal;Alpha;ScaleFactor;ScaleFactorUnits;LPFCutoff;"
//	globalVarList += "MembraneCap;ExtCmdSens;RawOutSignal;RawScaleFactor;RawScaleFactorUnits;"
//	globalVarList += "HardwareType;SecondaryAlpha;SecondaryLPFCutoff;SeriesResistance;"
//	String currentGlobalVarName
//	Variable n, numGlobalVars = ItemsInList(globalVarList, ";")
//	For (n=0; n<numGlobalVars; n+=1)
//		currentGlobalVarName = StringFromList(n, globalVarList, ";")
//		if (!exists(currentGlobalVarName))
//			Variable/G $(currentGlobalVarName) = 0
//		endif
//	EndFor
	
	// Strings
	if (!exists("serverList"))
		//String/G serverList = "Click the \"Find servers\" button and then select a server"
		string/G serverList = ""
	endif
	
// 2021-11-17 weg	
//	// Data strings
//	String globalStringList
//	globalStringList = "OperatingMode;ScaledOutSignal;ScaleFactorUnits;RawOutSignal;RawScaleFactorUnits;HardwareType;"
//	String currentGlobalStringName
//	Variable numGlobalStrings = ItemsInList(globalStringList, ";")
//	For (n=0; n<numGlobalStrings; n+=1)
//		currentGlobalStringName = StringFromList(n, globalStringList, ";")
//		if (!exists(currentGlobalStringName + "_str"))
//			String/G $(currentGlobalStringName + "_str") = ""
//		endif
//	EndFor
	
	SetDataFolder currentDF
End

//**
// Initializes all global variables for my panel.
//*
Function		FP_TG_InitMyPanelVariables()
// 2021-11-17 todo	num of chans=servers,  construct only if not existing?
	string  lstServers	=  FP_TG_ScanForServers()
	variable ns = 0
	for ( ns = 0; ns < ItemsInList(lstServers); ns += 1 )
		string 	/G	$"root:uf:aco:AxTg:strTyp0" 	+ num2str(ns) + "00"	= "?"
		variable 	/G 	$"root:uf:aco:AxTg:svTyp0" 	+ num2str(ns) + "00"	= nan
		variable 	/G 	$"root:uf:aco:AxTg:svSerNum0" 	+ num2str(ns) + "00"	= nan
		variable 	/G 	$"root:uf:aco:AxTg:svChanID0"  	+ num2str(ns) + "00"	= nan
		variable 	/G 	$"root:uf:aco:AxTg:svComPrt0"  	+ num2str(ns) + "00"	= nan
		variable 	/G 	$"root:uf:aco:AxTg:svAxoBus0"  	+ num2str(ns) + "00"	= nan
		string 	/G	$"root:uf:aco:AxTg:stMode0" 	+ num2str(ns) + "00"	= "?"
		variable 	/G 	$"root:uf:aco:AxTg:svOpMode0" + num2str(ns) + "00"	= nan
		variable 	/G	$"root:uf:aco:AxTg:svPriScl0"  	+ num2str(ns) + "00"	= nan
		string 	/G	$"root:uf:aco:AxTg:strPriSclU0" 	+ num2str(ns) + "00"	= "?"
		variable 	/G	$"root:uf:aco:AxTg:svPriGn0"  	+ num2str(ns) + "00"	= nan
		variable 	/G	$"root:uf:aco:AxTg:svPriFil0"  	+ num2str(ns) + "00"	= nan
		variable 	/G	$"root:uf:aco:AxTg:svSecGn0"  	+ num2str(ns) + "00"	= nan
		variable 	/G	$"root:uf:aco:AxTg:svSecFil0"  	+ num2str(ns) + "00"	= nan
	endfor
End

///////////////////////////////////////////////////////////////
// BACKGROUND TASK RELATED
///////////////////////////////////////////////////////////////
//**
// Start or stop the background task that monitors the amplifier telegraphs.
//*
Function Control_monitoring()
	NVAR/Z monitoring = $(kAxonTelegraphPanelDF+":currentlyMonitoring")
	CtrlNamedBackground axonTelegraph status
	Variable run = NumberByKey("RUN", S_info , ":", ";")
	if (!NVAR_Exists(monitoring))
		FP_TG_Initialize()
		NVAR/Z monitoring = $(kAxonTelegraphPanelDF+":currentlyMonitoring")
	endif
		
	if (monitoring)
		if (numtype(run) != 0 || run == 0)
			String cmd
			sprintf cmd, "CtrlNamedBackground axonTelegraph, burst=0, dialogsOK=1, period=%d, proc=%s#Background_monitoring, start", kBackgroundTaskPeriod, GetIndependentModuleName()
			Execute cmd
		endif
	else
		if (run == 1)
			CtrlNamedBackground axonTelegraph, stop=1
		endif
	endif
End

//**
// Background task that Igor calls each time the background task should run.
//*
Function Background_monitoring(s)
	STRUCT WMBackgroundStruct &s
	Variable start = StopMsTimer(-2)
	NVAR/Z monitoring = $(kAxonTelegraphPanelDF+":currentlyMonitoring")
	if (NVAR_Exists(monitoring) && monitoring)
		// UpdateAllData()
		// stUpdateAllData()
		FP_TG_GetAxonDataUsingStruct()
	endif
	//printf "Background task took %f ms.\r", (StopMsTimer(-2) - start) / 1000
	return 0		// Continue background task.
End


//static Function stUpdateAllData()
//	FP_TG_GetAxonDataUsingStruct()
//End


Function	FP_TG_StartMonitoring()
	// provides currently  no means to stop background task = runs as long as FPulse is active  (or even longer???)
	NVAR/Z monitoring = $(kAxonTelegraphPanelDF+":currentlyMonitoring")
	CtrlNamedBackground axonTelegraph status
	Variable run = NumberByKey("RUN", S_info , ":", ";")
	if (!NVAR_Exists(monitoring))
		FP_TG_Initialize()
		NVAR/Z monitoring = $(kAxonTelegraphPanelDF+":currentlyMonitoring")
	endif

	monitoring = 1		
	if (monitoring)
		if (numtype(run) != 0 || run == 0)
			String cmd
			sprintf cmd, "CtrlNamedBackground axonTelegraph, burst=0, dialogsOK=1, period=%d, proc=%s#Background_monitoring, start", kBackgroundTaskPeriod, GetIndependentModuleName()
			Execute cmd
		endif
	endif
End


Function  /S	 FP_TG_ScanForServers()
// retrieves all available Axon Telegraph servers and stores them in global list 'serverList'.   ALSO returns local list.
	string currentDF = GetDataFolder(1)
	SetDataFolder $(kAxonTelegraphPanelDF)
	
	nvar	 timeout = $(kAxonTelegraphPanelDF + ":timeoutMs")
	AxonTelegraphFindServers
	wave telegraphServersWave = W_TelegraphServers
	
	string 	sServerList = ""
	variable n, numServers = DimSize(telegraphServersWave, 0)
	string currentServerDesc
	for (n=0; n<numServers; n+=1)
		// Note:  If the format string below is changed it must also be changed in PopMenu_SelectServer().
		if (telegraphServersWave[n][0] < 0)
			// Server is a 700A server.
			sprintf currentServerDesc, "%s: ComPort: %d   AxoBus ID: %d   Channel ID: %d", "700A", telegraphServersWave[n][%ComPortID],  telegraphServersWave[n][%AxoBusID], telegraphServersWave[n][%ChannelID]
		else
			// Server is a 700B server.
			sprintf currentServerDesc, "%s:  Serial number: %d    Channel ID: %d", "700B", telegraphServersWave[n][%SerialNum], telegraphServersWave[n][%ChannelID]
		endif
		sServerList = AddListItem(currentServerDesc, sServerList, ";", inf)
	endfor
	svar serverList	
	serverList	= sServerList 
	printf "\t\tstScanForServers() \t\tsetting global  'serverList'  :  '%s' \r", serverList
	SetDataFolder currentDF
	return sServerList
End



Function FP_TG_GetAxonDataUsingStruct()
// 2021-11-10  Use AxonTelegraph Xop:  Retrieve and display data of _all_ servers, not just those of  the currently selected server 
	String currentDF = GetDataFolder(1)
	SetDataFolder $(kAxonTelegraphPanelDF)

	svar /Z	lstServers	= serverlist
	if ( ! svar_exists( lstServers ) ) 	
		SetDataFolder currentDF
		return 0
	endif

	nvar currentChannelID, currentSerialNum, currentComPortID, currentAxoBusID

	variable ns, nServers	= ItemsInList( lstServers )
	string 	sOneServer	
	for ( ns = 0; ns < nServers; ns += 1 )
		sOneServer	= StringFromList( ns, lstServers )

		variable channel, serial, comPort, axoBus
		sscanf sOneServer, "700B:  Serial number: %d    Channel ID: %d", serial, channel	// DO NOT CHANGE - style is provided by XOP
		if (V_flag == 2)
			// The selected item represents a 700B server.
			currentChannelID = channel
			currentSerialNum = serial
			currentComPortID = -1
			currentAxoBusID = -1
		else
			// The selected item must represent a 700A server.
			sscanf sOneServer, "700A: ComPort: %d  AxoBus ID: %d  Channel ID: %d", comPort, axoBus, channel	// DO NOT CHANGE - style is provided by XOP
			if (V_flag == 3)
				// The selected item represents a 700A server.
				currentChannelID = channel
				currentSerialNum = -1
				currentComPortID = comPort
				currentAxoBusID = axoBus
			endif
		endif

		// Get all string values for the currently processed server.
		NVAR/Z serialNum = currentSerialNum
		NVAR/Z channelID = currentChannelID
		NVAR/Z comPortID = currentComPortID
		NVAR/Z axoBusID = currentAxoBusID
		
		if (!NVAR_Exists(serialNum) || !NVAR_Exists(channelID) || !NVAR_Exists(comPortID) || !NVAR_Exists(axoBusID))
			SetDataFolder currentDF
			return 0
		elseif (numtype(serialNum) != 0 || numtype(channelID) != 0 || numtype(comPortID) != 0 || numtype(axoBusID) != 0)
			SetDataFolder currentDF
			return 0
		endif
		
		NVAR/Z getLongStrings = getLongStrings
		if (!NVAR_Exists(getLongStrings) || numtype(getLongStrings) != 0)
			Variable/G getLongStrings = 1
			NVAR getLongStrings = getLongStrings
		endif
	
		try
			STRUCT AxonTelegraph_DataStruct tds
			tds.version = kTelegraphDataStructVersion
			if (serialNum < 0)
				// We're using a 700A
				AxonTelegraphAGetDataStruct(comPortID, axoBusID, channelID, getLongStrings, tds);AbortOnRTE
			else
				// We're using a 700B
				AxonTelegraphGetDataStruct(serialNum, channelID, getLongStrings, tds);AbortOnRTE
			endif
			
			//ClearErrorMessage()
			NVAR OperatingMode,ScaledOutSignal,Alpha,ScaleFactor,ScaleFactorUnits,LPFCutoff
			NVAR HardwareType,SecondaryAlpha,SecondaryLPFCutoff,SeriesResistance
			svar	  ScaleFactorUnitsString
		
			// Copy data from structure into global variables.
			OperatingMode = tds.OperatingMode
	
			svar	strServer	= $"root:uf:aco:AxTg:strServer0"	+ num2str(ns) + "00";	strServer 	= sOneServer
			svar	strTyp	= $"root:uf:aco:AxTg:strTyp0"  		+ num2str(ns) + "00";	strTyp 		= tds.HardwareTypeString
			nvar	svTyp	= $"root:uf:aco:AxTg:svTyp0"  		+ num2str(ns) + "00";	svTyp 		= tds.HardwareType
			nvar	svSerNum= $"root:uf:aco:AxTg:svSerNum0"  	+ num2str(ns) + "00";	svSerNum 	= tds.SerialNum
			nvar	svChanID	= $"root:uf:aco:AxTg:svChanID0"  	+ num2str(ns) + "00";	svChanID 	= tds.ChannelID
			nvar	svComPrt	=$"root:uf:aco:AxTg:svComPrt0"  	+ num2str(ns) + "00";	svComPrt 	= tds.ComPortID
			nvar	svAxoBus	= $"root:uf:aco:AxTg:svAxoBus0"  	+ num2str(ns) + "00";	svAxoBus 	= tds.AxoBusID
			svar	strMode	= $"root:uf:aco:AxTg:strMode0" 	+ num2str(ns) + "00";	strMode 		= tds.OperatingModeString
			nvar	svMode	= $"root:uf:aco:AxTg:svOpMode0" 	+ num2str(ns) + "00";	svMode 		= tds.OperatingMode
			nvar	svPriScl	= $"root:uf:aco:AxTg:svPriScl0"  	+ num2str(ns) + "00";	svPriScl 		= tds.ScaleFactor
			svar	strPriSclU	= $"root:uf:aco:AxTg:strPriSclU0" 	+ num2str(ns) + "00";	strPriSclU 	= tds.ScaleFactorUnitsString
			nvar	svPriGn	= $"root:uf:aco:AxTg:svPriGn0"  	+ num2str(ns) + "00";	svPriGn 		= tds.Alpha
			nvar	svPriFi	= $"root:uf:aco:AxTg:svPriFil0" 		+ num2str(ns) + "00";	svPriFi 		= tds.LPFCutoff
			nvar	svSecGn	= $"root:uf:aco:AxTg:svSecGn0"		+ num2str(ns) + "00";	svSecGn 		= tds.SecondaryAlpha
			nvar	svSecFi	= $"root:uf:aco:AxTg:svSecFil0" 		+ num2str(ns) + "00";	svSecFi 		= tds.SecondaryLPFCutoff
	
		catch
			String errorMessage = GetRTErrMessage()
			Variable value
			value = GetRTError(1)
			//SetErrorMessage(StringFromList(1, errorMessage, ";"))
			printf "*** Error: %s  \r", StringFromList(1, errorMessage, ";" )
		endtry

	endfor
	SetDataFolder currentDF	
End

