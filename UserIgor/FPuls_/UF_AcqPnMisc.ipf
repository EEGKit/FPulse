// UF_AcqPnMisc.ipf
 

#pragma  rtGlobals 	= 1					// Use modern global access method. 	Do not use a tab after #pragma. Doing so will give compilation error in Igor 4.

// General  'Includes'
#include "UFCom_Constants"
#include "UFCom_Panel"

//#include "UFPE_Constants3"

//=================================================================================================================
//	SUBPANEL  MISCELLANEOUS

static strconstant	ksPN_NAME		= "mis"			// Panel name   _and_  subfolder name  _and_  section keyword in INI file
static strconstant	ksPN_TITLE		= "Miscellaneous"	// Panel title
static strconstant	ksPN_CTRLBASE	= "gbPnMisc"		// The  button base name (without prefix root:uf... and postfix 0000) in the main panel displaying and hiding THIS subpanel
static strconstant	ksPN_INISUB		= "FPuls"			// The  INI subfolder  below folder 'acq'   and   the  INI file location (here in a subdirectory to FPulse=FPulseMain.ipf)
static strconstant	ksPN_INIKEY		= "Wnd"			// The  keyword in the INI file (here always 'Wnd' as we are dealing with window positions and visibility)

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Action procedure for displaying and hiding a subpanel

Function		fMiscellan( s ) 
// The  Button action procedure of the button in the main panel displaying and hiding THIS subpanel.  Unfortunately we can not wrap this in a function because of the specific Panel creation function name below (due to hook function)
	struct	WMButtonAction	&s
	nvar		state		= $ReplaceString( "_", s.ctrlname, ":" )					// the underlying button variable name is derived from the control name
	// printf "\t\t\t\t%s\tvalue:%2d   \t\t%s\t%s\t%s\t \r",  UFCom_pd( s.ctrlname, 25),  state, UFCom_pd(ksPN_INISUB  ,9), UFCom_pd(ksPN_NAME ,9), UFCom_pd( ksPN_INIKEY ,9)	
	string  	sIniBasePath	= FunctionPath( ksFP_APP_NAME )					// the Ini file containing the window position will be written in a subdirectory parallel to UF_PulseMain.ipf 
	UFCom_WndVisibilitySetWrite_( ksACQ, ksPN_INISUB, ksPN_NAME, ksPN_INIKEY, state, sIniBasePath )
	if ( state )															// if we want to  _display_  the panel...
		if ( WinType( ksPN_NAME ) != UFCom_WT_PANEL )						// ...and only if the panel does not yet  exist ..
			PanelMiscellaneous( UFCom_kPANEL_DRAW )						// *** specific ***...we must build the panel
		else
			UFCom_WndUnhide( ksPN_NAME )								//  display again the hidden panel 
		endif
	else
		UFCom_WndHide( ksPN_NAME )									//  hide the panel 
	endif
End

//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function		PanelMiscellaneous( nMode )
// Create the panel.  Unfortunately we can not wrap this in a function because of the specific hook function name
	variable	nMode
	string  	sFBase		= "root:uf:"
	string  	sFSub		= ksACQ_	
	string		sDFSave		= GetDataFolder( 1 )								// The following functions do NOT restore the CDF so we remember the CDF in a string .
	UFCom_PossiblyCreateFolder( sFBase + sFSub + ksPN_NAME ) 
	InitPanelMiscellaneous( sFBase + sFSub, ksPN_NAME )						// *** specific ***fills big text wave  'sPnOptions' (=wPn)  with all information about the controls necessary to build the panel
	UFCom_RestorePanel2Sub( ksACQ, ksFPUL, ksPN_NAME, ksPN_TITLE, sFBase, sFSub, ksPN_INISUB, ksPN_INIKEY, ksPN_CTRLBASE, nMode )
	SetWindow		$ksPN_NAME,  hook( $ksPN_NAME ) = fHookMis			// *** specific ***
	SetDataFolder sDFSave												// Restore CDF from the string  value
	UFCom_LstPanelsAdd( ksACQ, ksfACQVARS, ksPN_NAME )	
End


Function 		fHookMis( s )
// The window hook function detects when the user moves or resizes or hides the panel  and stores these settings in the INI file
	struct	WMWinHookStruct &s
	string  	sIniBasePath	= FunctionPath( ksFP_APP_NAME )					// the Ini file containing the window position will be written in a subdirectory parallel to UF_PulseMain.ipf 
	return	UFCom_WndUpdateLocationHook( s, ksACQ, ksFPUL, ksPN_INISUB, ksPN_INIKEY, ksPN_CTRLBASE, sIniBasePath )
End


Function		InitPanelMiscellaneous( sF, sPnOptions )
	string  	sF, sPnOptions
	string		sPanelWvNm = sF + sPnOptions
	variable	n = -1, nItems = 20
	// printf "\t\tInitPanelMiscellaneous( '%s',  '%s' ) \r", sF, sPnOptions 
	make /O /T /N=(nItems)	$sPanelWvNm
	wave  /T	tPn	=		$sPanelWvNm
	// Cave / Flaw :   No tabcontrol = empty  'Tabs'  must have   different number of spaces (no Tab, not the empty string )  to be recognised correctly
	// Cave / Flaw :   For each item in  'Tabs'   there must be a  corresponding  'Blks'  entry  even if empty
	// Cave / Flaw :	   Only tabulators can be used  for aligning the following columns, do not use spaces.... (maybe they are allowed...)
	
	//				Type	 NxL Pos MxPo OvS	Tabs		Blks		Mode		Name		RowTi				ColTi		ActionProc	XBodySz	FormatEntry	Initvalue		Visibility	HelpTopic

	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	°:		,:		1,°:			ShowKeysDef:	Keywords and defaults:	:		fShowKeysDef()::		:			:			:		Keywords and defaults:	"
	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	°:		,:		1,°:			KillGraphs:		Kill all graphs:			:		fKillAllGraphs():	:		:			:			:		Kill all graphs:			"
	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:		,:		1,°:			dum2:		Acquisition Speed testing:	:		:			5:		:			:			:		:						" 
	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	°:		,:		1,°:			DisplayRaw:	Display raw data (after acq) ::		fDisplayRaw():	:		:			:			:		Display raw data after acquisition:"
	n += 1;	tPn[ n ] =	"CB:	   1:	0:	1:	0:	°:		,:		1,°:			gbDspAllPA:	Display all points (after acq) ::		:			:		:			fDspAllPAInit():	:		Display all points after acquisition:"
	n += 1;	tPn[ n ] =	"CB:	   1:	0:	1:	0:	°:		,:		1,°:			AcqCheck:	Quick check TG (after acq)  ::		fQuickCheckAcq():		:			:			:		Quick check of Telegraph channels:"
	n += 1;	tPn[ n ] =	"CB:	   1:	0:	1:	0:	°:		,:		1,°:			TimeStats:		Show timing statistics:		:		:			:		:			:			:		Show Timing Statistics:		"
// 2009-??	removed the possibility to search an improved stimulus timing
//	n += 1;	tPn[ n ] =	"CB:	   1:	0:	1:	0:	°:		,:		1,°:			ImprStimTim:	Search improved stim timing::		:			:		:			:			:		Search improved stimulus timing:	"
	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:		,:		1,°:			dum4:		:					:		:			:		:			:			:		:						" 
	n += 1;	tPn[ n ] =	"CB:	   1:	0:	1:	0:	°:		,:		1,°:			RequireCed:	Require Ced1401 hardware::		:			:		:			fRequireCedInit()::		Require Ced1401 hardware:	"

	redimension  /N = ( n+1)	tPn
End

// To get all Helptopics for the above panel  execute   PnTESTAllTitlesOrHelptopics( "root:uf:acq:", "mis" ) 
//  -> Keywords and defaults;Test CED1401;Kill all graphs;;Display raw data (after acq);Display all points after acquisition;Quick check TG (after acq);Show Timing Statistics;Search improved stim timing;Require Ced1401 hardware;  

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function		fShowKeysDef( s )
// Called only when a button is pressed  on MouseUp 
	struct	WMButtonAction &s
	// print s.ctrlName
	printf "\r"
	PrintKeywordsIO()
	PrintKeywordsElements()
	printf "\r"
End

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -	

Function		fKillAllGraphs( s )
// Called only when a button is pressed  on MouseUp 
	struct	WMButtonAction &s
	print s.ctrlName
	KillAllGraphs()
End

static Function  		KillAllGraphs()
//	string  	lstDeleteWnds	= WinList( "Task",  ";" , "WIN:1" )
	string  	sMatch = "*"
	string  	lstDeleteWnds	= WinList( "*",  ";" , "WIN:1" )			// 2008-07-25
	variable	n, nItems		= ItemsInList( lstDeleteWnds )
	 printf "\tKillGraphs( '%s' ) deleting %d items from '%s' \r", sMatch, nItems,  lstDeleteWnds 
	for ( n = nItems - 1; n >= 0;  n -= 1 )
		print "\tKillGraphs()  deleting item: ", n, StringFromList( n, lstDeleteWnds ), "old list (invalid after compacting..)  ", lstDeleteWnds 
		DoWindow /K $StringFromList( n, lstDeleteWnds )	
	endfor
End 

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -	

Function		fDisplayRaw( s )
// Called only when a button is pressed  on MouseUp 
	struct	WMButtonAction &s
	string  	sFo 	= ksACQ
	DisplayRawAftAcq_ns()
End

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -	

Function		DisplayAllPointsAA()
	nvar 		bDisplayAllPointsAA	= $"root:uf:acq:mis:gbDspAllPA0000"
	return	bDisplayAllPointsAA
End
Function	/S	fDspAllPAInit( sBaseNm, sF, sWin )
	string  	sBaseNm, sF, sWin 
	return "~"+ num2str( FP_IsRelease() )  			// 0 in Debug mode = faster display , 1 in Release mode = high fidelity display
End


// 2005-1121
Function		fQuickCheckAcq( s )
	struct	WMCheckboxAction &s
	string  	sProc	= GetUserData( 	s.win,  s.ctrlName,  "sProc" )
	 printf "\t\t%s( s )\tCNm:'%s'  ONLY TEST / SAMPLE CODE \r", sProc, s.ctrlname 
End

Function	/S	fRequireCedInit( sBaseNm, sF, sWin )
	string  	sBaseNm, sF, sWin 
	return "~"+ num2str( FP_IsRelease() )  + ";"		// allows the user to run the program without Ced1401 (is useful  e.g. in ReadCfs or in  Stimulus construction) . 	 Syntax: ~0; or ~1;   acts on remaining  (in this case: all) values 
End

