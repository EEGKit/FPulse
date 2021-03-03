// UF_AcqPnMisc.ipf
 

#pragma  rtGlobals 	= 1					// Use modern global access method. 	Do not use a tab after #pragma. Doing so will give compilation error in Igor 4.

// General  'Includes'
#include "UFCom_Panel"
//#include "UFPE_Constants3"

//=================================================================================================================
//	SUBPANEL  PREFERENCESL in ACQ

static strconstant	ksPN_NAME		= "prfa"			// Panel name   _and_  subfolder name  _and_  section keyword in INI file
static strconstant	ksPN_TITLE		= "Preferences Acq"	// Panel title
static strconstant	ksPN_CTRLBASE	= "Preferences"		// The  button base name (without prefix root:uf... and postfix 0000) in the main panel displaying and hiding THIS subpanel
static strconstant	ksPN_INISUB		= "FPuls"			// The  INI subfolder  below folder 'acq'   and   the  INI file location (here in a subdirectory to FPulse=FPulseMain.ipf)
static strconstant	ksPN_INIKEY		= "Wnd"			// The  keyword in the INI file (here always 'Wnd' as we are dealing with window positions and visibility)

//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Action procedure for displaying and hiding a subpanel

Function		fPreferDlg_a( s ) 
// The  Button action procedure of the button in the main panel displaying and hiding THIS subpanel.  Unfortunately we can not wrap this in a function because of the specific Panel creation function name below (due to hook function)
	struct	WMButtonAction	&s
	nvar		state		= $ReplaceString( "_", s.ctrlname, ":" )					// the underlying button variable name is derived from the control name
	// printf "\t\t\t\t%s\tvalue:%2d   \t\t%s\t%s\t%s\t \r",  UFCom_pd( s.ctrlname, 25),  state, UFCom_pd(ksPN_INISUB  ,9), UFCom_pd(ksPN_NAME ,9), UFCom_pd( ksPN_INIKEY ,9)	
	string  	sIniBasePath	= FunctionPath( ksFP_APP_NAME )					// the Ini file containing the window position will be written in a subdirectory parallel to UF_PulseMain.ipf 
	UFCom_WndVisibilitySetWrite_( ksACQ, ksPN_INISUB, ksPN_NAME, ksPN_INIKEY, state, sIniBasePath )
	if ( state )															// if we want to  _display_  the panel...
		if ( WinType( ksPN_NAME ) != UFCom_WT_PANEL )						// ...and only if the panel does not yet  exist ..
			PanelPreferencesAcq( UFCom_kPANEL_DRAW )					// *** specific ***...we must build the panel
		else
//			UFCom_Panel3SubUnhide( ksPN_NAME )							//  display again the hidden panel 
			UFCom_WndUnhide( ksPN_NAME )								//  display again the hidden panel 
		endif
	else
//		UFCom_Panel3SubHide( ksPN_NAME )								//  hide the panel  
		UFCom_WndHide( ksPN_NAME )									//  hide the panel 
	endif
End


Function		PanelPreferencesAcq( nMode )
// Create the panel.  Unfortunately we can not wrap this in a function because of the specific hook function name
	variable	nMode
	string  	sFBase		= "root:uf:"
	string  	sFSub		= ksACQ_	
	string		sDFSave		= GetDataFolder( 1 )								// The following functions do NOT restore the CDF so we remember the CDF in a string .
	UFCom_PossiblyCreateFolder( sFBase + sFSub + ksPN_NAME ) 
	InitPanelPreferencesAcq( sFBase + sFSub, ksPN_NAME )						// *** specific ***fills big text wave  'sPnOptions' (=wPn)  with all information about the controls necessary to build the panel
	UFCom_RestorePanel2Sub( ksACQ, ksFPUL, ksPN_NAME, ksPN_TITLE, sFBase, sFSub, ksPN_INISUB, ksPN_INIKEY, ksPN_CTRLBASE, nMode )
	SetWindow		$ksPN_NAME,  hook( $ksPN_NAME ) = fHookPrfa			// *** specific ***
	SetDataFolder sDFSave												// Restore CDF from the string  value
//	UFCom_LstPanelsSet( ksACQ, ksfACQVARS,  AddListItem( ksPN_NAME, UFCom_LstPanels( ksACQ, ksfACQVARS ) ) )					// add this panel to global list so that we can remove in on Cleanup or Exit
	UFCom_LstPanelsAdd( ksACQ, ksfACQVARS, ksPN_NAME )	
End


Function 		fHookPrfa( s )
// The window hook function detects when the user moves or resizes or hides the panel  and stores these settings in the INI file
	struct	WMWinHookStruct &s
	string  	sIniBasePath	= FunctionPath( ksFP_APP_NAME )					// the Ini file containing the window position will be written in a subdirectory parallel to UF_PulseMain.ipf 
			UFCom_WndUpdateLocationHook( s, ksACQ, ksFPUL, ksPN_INISUB, ksPN_INIKEY, ksPN_CTRLBASE, sIniBasePath )
End


Function		InitPanelPreferencesAcq( sF, sPnOptions )
	string  	sF, sPnOptions
	string		sPanelWvNm = sF + sPnOptions
	variable	n = -1, nItems = 20
	// printf "\t\tInitPanelPreferencesAcq( '%s',  '%s' ) \r", sF, sPnOptions 
	make /O /T /N=(nItems)	$sPanelWvNm
	wave  /T	tPn	=		$sPanelWvNm
	// Cave / Flaw :   No tabcontrol = empty  'Tabs'  must have   different number of spaces (no Tab, not the empty string )  to be recognised correctly
	// Cave / Flaw :   For each item in  'Tabs'   there must be a  corresponding  'Blks'  entry  even if empty
	// Cave / Flaw :	   Only tabulators can be used  for aligning the following columns, do not use spaces.... (maybe they are allowed...)
	
	//				Type	 NxL Pos MxPo OvS	Tabs		Blks		Mode		Name		RowTi				ColTi		ActionProc		XBodySz	FormatEntry		Initvalue		Visibility	HelpTopic

	n += 1;	tPn[ n ] =	"PM:	   1:	0:	1:	0:	°:		,:		1,°:			gnWarnLevl:	:					Warning level::				90:		fAcWarnLvlPops():	fAcWarnLvlInit()::		Warning level:			" // 	1-dim  popmenu (1 row)
	n += 1;	tPn[ n ] =	"CB:	   1:	0:	1:	0:	°:		,:		1,°:			gbWarnBeep:	Warning beep:			:		:				:		:				~1:			:		Warning beep:			" // 	

// 2010-02-02	removed the possibility to shrink the Ced memory
//	n += 1;	tPn[ n ] =	"SV:	   1:	0:	1:	0:	°:		,:		1,°:			gShrinkMem:	Decrease Ced mem  (MB):	:		fShrinkCedMem():	50: 		%.3lf;.001,1024,0:	~0:			:		Decrease Ced memory:	" // initial value must be 0 as this is used as a 'firsttime' indicator
// 2010-02-07	revived
	n += 1;	tPn[ n ] =	"SV:	   1:	0:	1:	0:	°:		,:		1,°:			gShrinkMem:	Decrease Ced mem  (MB):	:		fShrinkCedMem():	50: 		%.3lf;.001,1024,0:	~0:			:		Decrease Ced memory:	" // initial value must be 0 as this is used as a 'firsttime' indicator

	n += 1;	tPn[ n ] =	"SV:	   1:	0:	1:	0:	°:		,:		1,°:			gMxReactTm:	Max reaction time (s):		:		fMaxReactnTm():	50: 		%.1lf;.1,10,0:		fMxReactTmInit()::		Max reaction time:			" // 	
	n += 1;	tPn[ n ] =	"SV:	   1:	0:	1:	0:	°:		,:		1,°:			gMinCmpres:	Min TG compression:		:		fMinCompression():	50: 		%d;1,1000,0:		~1:			:		Min TG Compression:			" // 	

	redimension  /N = ( n+1)	tPn
End

Function		fAcWarnLvlPops( sControlNm, sFo, sWin )
	string		sControlNm, sFo, sWin
	PopupMenu	$sControlNm, win = $sWin,	 value = UFCom_kERR_lstWARNING_LEVEL
End
Function	/S	fAcWarnLvlInit( sBaseNm, sF, sWin )
	string  	sBaseNm, sF, sWin 
	return "0000_"+ num2str( 4 - 2 * FP_IsRelease() ) 		// 4 in Debug mode = only severe warnings , 2 in Release mode = also less important warnings
End

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -	

// 2010-02-02	removed the possibility to shrink the Ced memory
// 2010-02-07	revived
Function		fShrinkCedMem( s )
	struct	WMSetvariableAction	  &s
	 printf "\t\tfShrinkCedMem  %s \r", s.ctrlName
	nvar		gCedMemSize	= $"root:uf:acq:" +  UFPE_ksCOns  + ":gCedMemSize"
 	nvar		gShrinkMemMB	= root:uf:acq:prfa:gShrinkMem0000
	gShrinkMemMB			= min( gCEDMemSize / UFPE_kMBYTE, gShrinkMemMB )
	ApplyScript()									// necessary for the changed settings to be effective at the next 'Start'
End
Function		ShrinkCedMem()
	nvar		gShrinkMemMB	= root:uf:acq:prfa:gShrinkMem0000
	// printf "\t\tShrinkCedMem   returns %g \r", gShrinkMemMB
	return	gShrinkMemMB
End
Function		SetShrinkCedMem( ShrinkCedMem )
	variable	ShrinkCedMem
	nvar		gShrinkMemMB	= root:uf:acq:prfa:gShrinkMem0000
	gShrinkMemMB			= ShrinkCedMem
	// printf "\t\tSetShrinkCedMem    sets to %g \r", gShrinkMemMB
	// return	gShrinkMemMB
End

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -	

static	 constant	kMAX_REACTIONTIME	= 1.5			// Adjust chunk size  and repetitions such that the interval between display update is not longer than this seconds (if possible) 
											//...typical value 1 .. 3 . Bigger values improve overall performance as fewer chunks have to be processed.
											// Set this to a very high value to obtain maximum data rates ( this also decreases the 'Apply' time somewhat )
Function		fMaxReactnTm( s )
	struct	WMSetvariableAction	  &s
	 printf "\t\tfMaxReactnTm  %s \r", s.ctrlName
	ApplyScript()								// necessary for the changed settings to be effective at the next 'Start'
End
Function		MaxReactnTm() 
	nvar		gMaxReactnTime 	= root:uf:acq:prfa:gMxReactTm0000 
	return	gMaxReactnTime
End
Function	/S	fMxReactTmInit( sBaseNm, sF, sWin )
	string  	sBaseNm, sF, sWin 
	return	 "~"+ num2str( kMAX_REACTIONTIME)  
End

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -	

Function		fMinCompression( s )
// Mainly for debugging.  Avoid  small compression rates (or no compression at all) which FPulse selects if a slightly better FigureOfMerit FOM could be achieved.  For testing we need real compression with low Ced Mem settings.
	struct	WMSetvariableAction	  &s
	 printf "\t\tfMinCompression  %s   has sets to %g  \r", s.ctrlName, MinCompression() 
	ApplyScript()								// necessary for the changed settings to be effective at the next 'Start'
End
Function		MinCompression() 
	nvar		gMinCmpres 	= root:uf:acq:prfa:gMinCmpres0000 
	return	gMinCmpres
End


