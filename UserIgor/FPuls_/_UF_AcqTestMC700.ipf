//
//   	_UF_AcqTestMC700.ipf		( for Version 3nn)
// 
//	Note:	The leading underscore prevents that this file is released to the user,  but ALSO in  UF_PulsMain.ipf    #ifdef dDEBUG is required  to prevent  #including  this file in the Release version
// 	Note:	Many  (but not all)  of the Test functions  rely on FPulse functions ,  so  an  ACTIVE  FPulse is required.  FPulse installation alone is NOT sufficient!
//			Test functions requiring  FPulse  are marked  '//(//'
// 		:	This file  could in principle be split into stand-alone test functions and in FPulse-related test functions (but this is not done...)
//			

#pragma  rtGlobals 	= 1					// Use modern global access method. 	Do not use a tab after #pragma. Doing so will give compilation error in Igor 4.
#pragma  IgorVersion = 5.0					// prevents the attempt to run this procedure under Igor4 or lower. Do not use a tab after #pragma. Doing so will make the version check ineffective in Igor 4.

//#include "UFPE_Dialog_319"
//#include "UFPE_Panel_319"
#include "UFCom_Timers"
#include "UFCom_Numbers"
#include "UFCom_DataFoldersAndGlobals"
//#include "UFPE_Constants3"

//=====================================================================================================================================================
//      DIALOG  :   MULTICLAMP700  PANEL

//  New main menu bar entry.  A shortcut to  THIS  file  and a shortcut to  THIS  directory  'UserIgor:Ced'  is required.
Menu "Test MC700"
	"Test functions MC700",		PnTestMC700_()				// 
End

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

static strconstant	ksPN_NAME		= "MC7"		// Panel name   _and_  subfolder name  _and_  section keyword in INI file
static strconstant	ksPN_TITLE		= "Test MC700"		// The  button base name (without prefix root:uf... and postfix 0000) in the main panel displaying and hiding THIS subpanel
static strconstant	ksPN_CTRLBASE	= "buPnTstMC7"	// The  button base name (without prefix root:uf... and postfix 0000) in the main panel displaying and hiding THIS subpanel
static strconstant	ksPN_INISUB		= "FPuls"			// The  INI subfolder  below folder 'acq'   and   the  INI file location (here in a subdirectory to FPulse=FPulseMain.ipf)
static strconstant	ksPN_INIKEY		= "Wnd"			// The  keyword in the INI file (here always 'Wnd' as we are dealing with window positions and visibility)


//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Action procedure for displaying and hiding a subpanel

Function		fPnTestMC700( s ) 
// The  Button action procedure of the button in the main panel displaying and hiding THIS subpanel.  Unfortunately we can not wrap this in a function because of the specific Panel creation function name below (due to hook function)
	struct	WMButtonAction	&s
	nvar		state		= $ReplaceString( "_", s.ctrlname, ":" )					// the underlying button variable name is derived from the control name
	// printf "\t\t\t\t%s\tvalue:%2d   \t\t%s\t%s\t%s\t \r",  UFCom_pd( s.ctrlname, 25),  state, UFCom_pd(ksPN_INISUB  ,9), UFCom_pd(ksPN_NAME ,9), UFCom_pd( ksPN_INIKEY ,9)	
	string  	sIniBasePath	= FunctionPath( ksFP_APP_NAME )					// the Ini file containing the window position will be written in a subdirectory parallel to UF_PulseMain.ipf 
	UFCom_WndVisibilitySetWrite_( ksACQ, ksPN_INISUB, ksPN_NAME, ksPN_INIKEY, state, sIniBasePath )
	if ( state )															// if we want to  _display_  the panel...
		if ( WinType( ksPN_NAME ) != UFCom_WT_PANEL )						// ...and only if the panel does not yet  exist ..
			PnTestMC700( UFCom_kPANEL_DRAW )							// *** specific ***...we must build the panel
		else
			UFCom_WndUnhide( ksPN_NAME )								//  display again the hidden panel 
		endif
	else
		UFCom_WndHide( ksPN_NAME )									//  hide the panel 
	endif
End

//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function		PnTestMC700_()
	PnTestMC700( UFCom_kPANEL_DRAW )
End

Function		PnTestMC700( nMode )
// Create the panel.  Unfortunately we can not wrap this in a function because of the specific hook function name
	variable	nMode
	string  	sFBase		= "root:uf:"
	string  	sFSub		= ksACQ_	
	string		sDFSave		= GetDataFolder( 1 )								// The following functions do NOT restore the CDF so we remember the CDF in a string .
	UFCom_PossiblyCreateFolder( sFBase + sFSub + ksPN_NAME ) 
	InitPanelTestMC700( sFBase + sFSub, ksPN_NAME )						// *** specific ***fills big text wave  'sPnOptions' (=wPn)  with all information about the controls necessary to build the panel
	UFCom_RestorePanel2Sub( ksACQ, ksFPUL, ksPN_NAME, ksPN_TITLE, sFBase, sFSub, ksPN_INISUB, ksPN_INIKEY, ksPN_CTRLBASE, nMode )
	SetWindow		$ksPN_NAME,  hook( $ksPN_NAME ) = fHookTestMC700		// *** specific ***
	SetDataFolder sDFSave												// Restore CDF from the string  value
	//UFCom_LstPanelsSet( ksACQ, ksfACQVARS , AddListItem( ksPN_NAME, UFCom_LstPanels( ksACQ, ksfACQVARS ) ) )	
	UFCom_LstPanelsAdd( ksACQ, ksfACQVARS, ksPN_NAME )	

	UFCom_EnableButton( ksPN_NAME,  ReplaceString( ":", sFBase + sFSub + ksPN_NAME + ":" + "bu7CreObj" 	+ "0000" , "_" ), UFCom_kCo_ENABLE )
	UFCom_EnableButton( ksPN_NAME,  ReplaceString( ":", sFBase + sFSub + ksPN_NAME + ":" + "bu7ScanAll" 	+ "0000" , "_" ), UFCom_kCo_DISABLE )
	UFCom_EnablePopup( ksPN_NAME,  ReplaceString( ":", sFBase + sFSub + ksPN_NAME + ":" + "pm7SelMCC" 	+ "0000" , "_" ), UFCom_kCo_DISABLE )
	UFCom_EnableButton( ksPN_NAME,  ReplaceString( ":", sFBase + sFSub + ksPN_NAME + ":" + "bu7SetVC" 	+ "0000" , "_" ), UFCom_kCo_DISABLE )
	UFCom_EnableButton( ksPN_NAME,  ReplaceString( ":", sFBase + sFSub + ksPN_NAME + ":" + "bu7SetCC" 	+ "0000" , "_" ), UFCom_kCo_DISABLE )
	UFCom_EnableButton( ksPN_NAME,  ReplaceString( ":", sFBase + sFSub + ksPN_NAME + ":" + "bu7Reset" 	+ "0000" , "_" ), UFCom_kCo_DISABLE )
	UFCom_EnableButton( ksPN_NAME,  ReplaceString( ":", sFBase + sFSub + ksPN_NAME + ":" + "bu7Destroy" 	+ "0000" , "_" ), UFCom_kCo_DISABLE )

End


Function 		fHookTestMC700( s )
// The window hook function detects when the user moves or resizes or hides the panel  and stores these settings in the INI file
	struct	WMWinHookStruct &s
	string  	sIniBasePath	= FunctionPath( ksFP_APP_NAME )					// the Ini file containing the window position will be written in a subdirectory parallel to UF_PulseMain.ipf 
	return	UFCom_WndUpdateLocationHook( s, ksACQ, ksFPUL, ksPN_INISUB, ksPN_INIKEY, ksPN_CTRLBASE, sIniBasePath )
End


Function		InitPanelTestMC700( sF, sPnOptions )
	string  	sF, sPnOptions
	string		sPanelWvNm = sF + sPnOptions
	variable	n = -1, nItems = 20
	// printf "\t\tInitPanelTestMC700( '%s',  '%s' ) \r", sF, sPnOptions 
	make /O /T /N=(nItems)	$sPanelWvNm
	wave  /T	tPn	=		$sPanelWvNm

//  old V3  BUT REQUIRED  ????
//	UFCom_ConstructAndMakeCurFoldr( "root:uf:acq:misc:MC700" )
//	string  	/G				root:uf:acq:misc:MC700:glstlstAllMCCIds 	= ""
//	string  	/G				root:uf:acq:misc:MC700:glstPopupMCCs	= "" 	
//	variable	/G				root:uf:acq:misc:MC700:pm7SelMCC0000	// gpSelectMCC
//	variable	/G				root:uf:acq:misc:MC700:hMCCmsg
//	variable	/G				root:uf:acq:misc:MC700:sv7DbgMsg0000	= 0

	make /O /T /N=(nItems)	$sPanelWvNm
	wave  /T	tPn		= 	$sPanelWvNm

	//				Type	 NxL Pos MxPo OvS	Tabs		Blks		Mode		Name		RowTi							ColTi		ActionProc			XBodySz	FormatEntry	Initvalue		Visibility	HelpTopic

	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:		,:		1,°:			dum20:		--- Set and Get MC700 state [MC700] ---:	:		:					12:		:			:			:		:	" 
	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	°:		,:		1,°:			bu7ChkApi:	CheckAPIVersion:					:		fMC700CheckAPIVersion():	:		:			:			:		:	"
	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	°:		,:		1,°:			bu7CreObj:	CreateObject:						:		fMC700CreateObject():	:		:			:			:		:	"
	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	°:		,:		1,°:			bu7ScanAll:	Scan All MultiClamps:					:		fMC700ScanAllMultiClamps()::		:			:			:		:	"
// UNFINISHED !
	n += 1;	tPn[ n ] =	"PM:    1:	0:	1:	0:	°:		,:		1,°:			pm7SelMCC:	:								SelectMCC:fMC700SelectMCC():		200:		fSelectMCC_Pops():0000_1:		:		:	"
	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	°:		,:		1,°:			bu7SetVC:		Set Mode VC:						:		fMC700SetModeVC():		:		:			:			:		:	"
	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	°:		,:		1,°:			bu7SetCC:		Set Mode CC:						:		fMC700SetModeCC():		:		:			:			:		:	"
	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	°:		,:		1,°:			bu7GetMode:	Get Mode:							:		fMC700GetMode():		:		:			:			:		:	"
	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	°:		,:		1,°:			bu7SetGn1:	Set Gain 1:						:		fMC700SetGain1():		:		:			:			:		:	"
	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	°:		,:		1,°:			bu7SetGn100:	Set Gain 100:						:		fMC700SetGain100():		:		:			:			:		:	"
	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	°:		,:		1,°:			bu7GetGain:	Get Gain:							:		fMC700GetGain():		:		:			:			:		:	"
	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	°:		,:		1,°:			bu7Reset:		Reset':							:		fMC700Reset():			:		:			:			:		:	"
	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	°:		,:		1,°:			bu7Destroy:	DestroyObject:						:		fMC700DestroyObject():	:		:			:			:		:	"

	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:		,:		1,°:			dum30:		:								:		:					:		:			:			:		:	" 
	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:		,:		1,°:			dum40:		--- Process the MC700 telegraphs [MC700Tg] ---::		:					2:		:			:			:		:	" 
// UNFINISHED ?
	n += 1;	tPn[ n ] =	"SV:    1:	0:	1:	0:	°:		,:		1,°:			sv7DbgMsg:	Debug messages (none 0  all 4):			:		fMC700DebugMsg():		20:		%1d ;0,4,1:	~0:			:		:	"
	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	°:		,:		1,°:			bu7AvChan:	Display available MC700 TG channels:	:		fMC700TgDisplayAvailChans()::		:			:			:		:	"

	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:		,:		1,°:			dum50:		:								:		:					:		:			:			:		:	" 
	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:		,:		1,°:			dum60:		:								:		:					:		:			:			:		:	" 
	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	°:		,:		1,°:			buNumberTst:	NumberTest (largest integer?):			:		fNumberTest():	:		:			:			:		:	"

//  old V3 
//	n += 1;	tPn[ n ] =	"PN_SEPAR	; ;--- Set and Get MC700 state [MC700] ---"
//	n += 1;	tPn[ n ] =	"PN_BUTTON;	buMC700CheckAPIVersion			;CheckAPIVersion"
//	n += 1;	tPn[ n ] =	"PN_BUTTON;	buMC700CreateObject			;CreateObject"
//	n += 1;	tPn[ n ] =	"PN_BUTTON;	buMC700ScanAllMultiClamps		;Scan All MultiClamps"
//	n += 1;	tPn[ n ] =	"PN_POPUP  ;	root:uf:acq:misc:MC700:gpSelectMCC;; 	200	;   1	;fSelectMCC_Pops; gpSelectMCC  "
//	n += 1;	tPn[ n ] =	"PN_BUTTON;	buMC700SetModeVC				;Set Mode VC"
//	n += 1;	tPn[ n ] =	"PN_BUTTON;	buMC700SetModeCC				;Set Mode CC"
//	n += 1;	tPn[ n ] =	"PN_BUTTON;	buMC700GetMode				;Get Mode"
//	n += 1;	tPn[ n ] =	"PN_BUTTON;	buMC700SetGain1				;Set Gain 1"
//	n += 1;	tPn[ n ] =	"PN_BUTTON;	buMC700SetGain100				;Set Gain100"
//	n += 1;	tPn[ n ] =	"PN_BUTTON;	buMC700GetGain				;Get Gain"
//	n += 1;	tPn[ n ] =	"PN_BUTTON;	buMC700Reset					;Reset"
//	n += 1;	tPn[ n ] =	"PN_BUTTON;	buMC700DestroyObject			;DestroyObject"
//	n += 1;	tPn[ n ] =	"PN_SEPAR	; ;--- Process the MC700 telegraphs [MC700Tg] ---"
//	n += 1;	tPn[ n ] =	"PN_SETVAR;	root:uf:acq:misc:MC700:gDebugMsg		;Debug messages (none:0, all:4); 	20; 	%1d ;0,4,1;	"			
//	n += 1;	tPn[ n ] =	"PN_BUTTON;	buMC700TgDisplayAvailChans		;Display available MC700 TG channels"
//	n += 1;	tPn[ n ] =	"PN_SEPAR;	"
//	n += 1;	tPn[ n ] =	"PN_BUTTON;	buNumberTest					;NumberTest (largest integer?)"
	redimension  /N = ( n+1)	tPn	

End


static constant		kMC700_MODEL	= 0 ,   kMC700_SERIALNUM	= 1 ,  kMC700_COMPORT = 2 ,   kMC700_DEVICE = 3 ,  kMC700_CHANNEL = 4
static strconstant	lstMC700_ID		= "Model;Serial#;COMPort;Device;Channel;"	// Assumption : Order is MoSeCoDeCh (same as in XOP)
static	 strconstant	kMC700_MODELS	= "700A;700B"
static constant		kMC700_MODE_VC	= 0 ,   kMC700_MODE_CC	= 1
static	 strconstant	kMC700_MODES	= "VC;IC;I=0"


//===========================================================================================
//  Action  procedures  for  MCC700 : 		---  Process the MC700 telegraphs [ XOP = MC700Tg ] ---

Function		fMC700DebugMsg( s ) 
	struct	WMSetvariableAction &s
	variable	varNum
	nvar		gDebugMsg	= root:uf:acq:misc:MC700:sv7DbgMsg0000
	print "\t\t" , s.ctrlName, gDebugMsg
	UFP_MCTgDebugMsg( gDebugMsg )
End

Function		fMC700TgDisplayAvailChans( s )
	struct	WMButtonAction &s
	DisplayAvailMCTgChans_ns()			//(//  UF_AcqCfsWrite
End

//===========================================================================================
//  Action  procedures  for  MCC700 : 		--- Set and Get MC700 state [ XOP = MC700 ] ---

Function		fMC700CheckAPIVersion( s )
	struct	WMButtonAction &s
	variable	nCode	= UFP_MCCMSG_CheckAPIVersion()		
	print	 	"\t\t", s.ctrlName, nCode
End


Function		fMC700CreateObject(  s )
	struct	WMButtonAction &s
	string  	sFBase		= "root:uf:"
	string  	sFSub		= ksACQ_	
//	ConstructAndMakeCurFoldr( "root:uf:acq:misc:MC700" )
//	string  	/G				root:uf:acq:misc:MC700:glstlstAllMCCIds 	= ""
//	string  	/G				root:uf:acq:misc:MC700:glstPopupMCCs	= "" 	
//	variable	/G				root:uf:acq:misc:MC700:gpSelectMCC
//	variable	/G				root:uf:acq:misc:MC700:hMCCmsg
	nvar		hMCCmsg	    	= 	root:uf:acq:misc:MC700:hMCCmsg
	hMCCmsg	= UFP_MCCMSG_CreateObject()
	printf	 "\t\t%s :  \t\t0x%08x  %d \r", s.ctrlName, hMCCmsg, hMCCmsg
	if ( hMCCmsg ) 
		UFCom_EnableButton( ksPN_NAME,  ReplaceString( ":", sFBase + sFSub + ksPN_NAME + ":" + "bu7CreObj" 	+ "0000" , "_" ), UFCom_kCo_DISABLE )
		UFCom_EnableButton( ksPN_NAME,  ReplaceString( ":", sFBase + sFSub + ksPN_NAME + ":" + "bu7ScanAll" 	+ "0000" , "_" ), UFCom_kCo_ENABLE )
		UFCom_EnableButton( ksPN_NAME,  ReplaceString( ":", sFBase + sFSub + ksPN_NAME + ":" + "bu7Destroy" 	+ "0000" , "_" ), UFCom_kCo_ENABLE )
	else
		printf	"Error: Could not 'CreateObject'  \t%s :  \t\t0x%08x  %d \r", s.ctrlName, hMCCmsg, hMCCmsg
	endif
End


Function		fMC700ScanAllMultiClamps( s )
	struct	WMButtonAction &s
	string  	sFBase		= "root:uf:"
	string  	sFSub		= ksACQ_	
	nvar		hMCCmsg		= root:uf:acq:misc:MC700:hMCCmsg
	svar		glstlstAllMCCIds = root:uf:acq:misc:MC700:glstlstAllMCCIds 	
	svar		glstPopupMCCs = root:uf:acq:misc:MC700:glstPopupMCCs 	
	nvar		gpSelectMCC	= root:uf:acq:misc:MC700:gpSelectMCC
	if ( hMCCmsg )
		glstlstAllMCCIds	= UFP_MCCScanMultiClamps( hMCCmsg )
		printf	"\t\t%s \t0x%08x  %d     Items:%d    '%s'  \r", s.ctrlName, hMCCmsg, hMCCmsg, ItemsInList( glstlstAllMCCIds, "~" ), glstlstAllMCCIds	
		glstPopupMCCs	= SelectMCCList_()
		gpSelectMCC	= 0
		ControlUpdate	/W=$"PnMC700"   root_uf_misc_MC700_gpSelectMCC 
		UFCom_EnablePopup( ksPN_NAME,  ReplaceString( ":", sFBase + sFSub + ksPN_NAME + ":" + "pm7SelMCC" 	+ "0000" , "_" ), UFCom_kCo_ENABLE )
	else
		glstlstAllMCCIds	= ""
		glstPopupMCCs	= ""
		UFCom_Alert( UFCom_kERR_IMPORTANT, "Communication with MultiClamp(s) not ready.  (" + s.ctrlName + ") " )
		gpSelectMCC	= -1//Nan
		PopupMenu	  root_uf_misc_MC700_gpSelectMCC 	 mode = 1, popvalue = "No device"
	endif
End


Function		fMC700SelectMCC( s )
	struct	WMPopupAction &s
	string  	sFBase		= "root:uf:"
	string  	sFSub		= ksACQ_	
	nvar		gpSelectMCC	= root:uf:acq:misc:MC700:gpSelectMCC
	gpSelectMCC	= s.popNum - 1										// popNum starts at 1
	printf "\t\t\tgpSelectMCC( '%s' ) selects %d  :  '%s' \r",  s.ctrlName, s.popNum, s.popStr
	nvar		hMCCmsg		= root:uf:acq:misc:MC700:hMCCmsg
	if ( hMCCmsg )
		svar		glstlstAllMCCIds = root:uf:acq:misc:MC700:glstlstAllMCCIds 	
		variable	rnModel, rnCOMPort, rnDevice, rnChannel 				
		string  	rsSerialNumber									
		ExtractMC700Identifications( gpSelectMCC, glstlstAllMCCIds, rnModel, rsSerialNumber, rnCOMPort, rnDevice, rnChannel ) 	// references are changed here and returned
		variable	nCode	= UFP_MCCMSG_SelectMultiClamp( hMCCmsg, rnModel, rsSerialNumber, rnCOMPort, rnDevice, rnChannel )
		if ( nCode == 0 )
			UFCom_Alert( UFCom_kERR_IMPORTANT, s.ctrlName + " failed. " )
		else
			UFCom_EnableButton( ksPN_NAME,  ReplaceString( ":", sFBase + sFSub + ksPN_NAME + ":" + "bu7SetVC" 	+ "0000" , "_" ), UFCom_kCo_ENABLE )
			UFCom_EnableButton( ksPN_NAME,  ReplaceString( ":", sFBase + sFSub + ksPN_NAME + ":" + "bu7SetCC" 	+ "0000" , "_" ), UFCom_kCo_ENABLE )
			UFCom_EnableButton( ksPN_NAME,  ReplaceString( ":", sFBase + sFSub + ksPN_NAME + ":" + "bu7Reset" 	+ "0000" , "_" ), UFCom_kCo_ENABLE )
		endif		
	endif		
End


Function		fSelectMCC_Pops( sControlNm, sFo, sWin )
// fills in the entries in the popupmenu for the MC700 selection 
	string		sControlNm, sFo, sWin
	// print "\t\tfSelectMCC_Lst()    sControlNm: " ,  sControlNm, sFo, sWin 
	PopupMenu	$sControlNm, win = $sWin,	 value = SelectMCCList_() ,   mode = 1, popvalue = "No device"
	//PopupMenu	$sControlNm, win = $sWin,	 value = SelectMCCList_() 
End

Function		fMC700SetModeVC(  s )
	struct	WMButtonAction &s
	MC700SetMode( kMC700_MODE_VC )
End

Function		fMC700SetModeCC(  s )
	struct	WMButtonAction &s
	MC700SetMode( kMC700_MODE_CC )
End

Function		fMC700GetMode(  s )
	struct	WMButtonAction &s
	variable	nMode	= MC700GetMode()
	printf "\t\t%s\tMode:\t%s\t(%d) \r", s.ctrlName, StringFromList( nMode, kMC700_MODES ),  nMode
End

Function		fMC700SetGain1(  s )
	struct	WMButtonAction &s
	MC700SetGain( 1 )
End

Function		fMC700SetGain100(  s )
	struct	WMButtonAction &s
	string 	ctrlName		
	MC700SetGain( 100 )
End

Function		fMC700GetGain(  s )
	struct	WMButtonAction &s
	variable	Gain	= MC700GetGain()
	printf "\t\t%s\tGain: %.1lf \r", s.ctrlName, Gain
End



Function		fMC700Reset(  s )
	struct	WMButtonAction &s
	nvar		hMCCmsg		= root:uf:acq:misc:MC700:hMCCmsg
	if ( hMCCmsg )
		variable	nCode		= UFP_MCCMSG_Reset( hMCCmsg )
		if ( nCode == 0 )
			UFCom_Alert( UFCom_kERR_IMPORTANT, s.ctrlName + " failed. " )
		endif		
	else
		UFCom_Alert( UFCom_kERR_IMPORTANT, "Communication with MultiClamp(s) not ready.  (" + s.ctrlName + ") " )
	endif
End

Function		fMC700DestroyObject(  s )
	struct	WMButtonAction &s
	string  	sFBase		= "root:uf:"
	string  	sFSub		= ksACQ_	
	nvar		hMCCmsg		= root:uf:acq:misc:MC700:hMCCmsg
	nvar		gpSelectMCC	= root:uf:acq:misc:MC700:gpSelectMCC
	svar		glstlstAllMCCIds = root:uf:acq:misc:MC700:glstlstAllMCCIds 	
	svar		glstPopupMCCs = root:uf:acq:misc:MC700:glstPopupMCCs 	
	if ( hMCCmsg )
		UFP_MCCMSG_DestroyObject( hMCCmsg )
	else
		UFCom_Alert( UFCom_kERR_IMPORTANT, "Communication with MultiClamp(s) not ready.  (" + s.ctrlName + ") " )
	endif
	hMCCmsg		= 0			// also set to  NULL in XOP
	gpSelectMCC	= -1
	glstlstAllMCCIds	= ""
	glstPopupMCCs	= ""
	PopupMenu	  root_uf_misc_MC700_gpSelectMCC	 mode = 1, popvalue = "No device"
	UFCom_EnableButton( ksPN_NAME,  ReplaceString( ":", sFBase + sFSub + ksPN_NAME + ":" + "bu7CreObj" 	+ "0000" , "_" ), UFCom_kCo_ENABLE )
	UFCom_EnableButton( ksPN_NAME,  ReplaceString( ":", sFBase + sFSub + ksPN_NAME + ":" + "bu7ScanAll" 	+ "0000" , "_" ), UFCom_kCo_DISABLE )
	UFCom_EnablePopup( ksPN_NAME,  ReplaceString( ":", sFBase + sFSub + ksPN_NAME + ":" + "pm7SelMCC" 	+ "0000" , "_" ), UFCom_kCo_DISABLE )
	UFCom_EnableButton( ksPN_NAME,  ReplaceString( ":", sFBase + sFSub + ksPN_NAME + ":" + "bu7SetVC" 	+ "0000" , "_" ), UFCom_kCo_DISABLE )
	UFCom_EnableButton( ksPN_NAME,  ReplaceString( ":", sFBase + sFSub + ksPN_NAME + ":" + "bu7SetCC" 	+ "0000" , "_" ), UFCom_kCo_DISABLE )
	UFCom_EnableButton( ksPN_NAME,  ReplaceString( ":", sFBase + sFSub + ksPN_NAME + ":" + "bu7Reset" 	+ "0000" , "_" ), UFCom_kCo_DISABLE )
	UFCom_EnableButton( ksPN_NAME,  ReplaceString( ":", sFBase + sFSub + ksPN_NAME + ":" + "bu7Destroy" 	+ "0000" , "_" ), UFCom_kCo_DISABLE )
End

//===========================================================================================
//  Helpers  for  MCC700

Function	/S	SelectMCCList_()
// fills in the entries in the popupmenu for the MC700 selection 
	svar		glstlstAllMCCIds = root:uf:acq:misc:MC700:glstlstAllMCCIds 	
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


static Function		ExtractMC700Identifications( nMCC, lstlstAllMCCIds, rnModel, rsSerialNumber, rnCOMPort, rnDevice, rnChannel ) 
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


static Function		MC700SelectMultiClamp( nModel, sSerialNumber, nCOMPort, nDevice, nChannel )
	variable	nModel, nCOMPort, nDevice, nChannel 
	string  	sSerialNumber
	nvar		hMCCmsg		= root:uf:acq:misc:MC700:hMCCmsg
	if ( hMCCmsg )
		variable	nCode	= UFP_MCCMSG_SelectMultiClamp( hMCCmsg, nModel, sSerialNumber, nCOMPort, nDevice, nChannel )
		if ( nCode == 0 )
			UFCom_Alert( UFCom_kERR_IMPORTANT, "MC700SelectMultiClamp() failed. " )
		endif		
	else
		UFCom_Alert( UFCom_kERR_IMPORTANT, "MC700SelectMultiClamp() failed as communication with MultiClamp(s) was not ready." )
	endif
End


static Function		MC700SetMode( nMode ) 
	variable	nMode
	nvar		hMCCmsg		= root:uf:acq:misc:MC700:hMCCmsg
	if ( hMCCmsg )
		variable	nCode	= UFP_MCCMSG_SetMode( hMCCmsg, nMode )
		if ( nCode == 0 )
			UFCom_Alert( UFCom_kERR_IMPORTANT, "MC700SetMode() failed. " )
		endif		
	else
		UFCom_Alert( UFCom_kERR_IMPORTANT, "MC700SetMode() failed as communication with MultiClamp(s) was not ready." )
	endif
End

static Function		MC700GetMode()
	nvar		hMCCmsg		= root:uf:acq:misc:MC700:hMCCmsg
	variable	nMode	= -1
	if ( hMCCmsg )
		nMode	= UFP_MCCMSG_GetMode( hMCCmsg )
	else
		UFCom_Alert( UFCom_kERR_IMPORTANT, "MC700GetMode() failed as communication with MultiClamp(s) was not ready." )
	endif
	return	nMode
End

static Function		MC700SetGain( Gain ) 
	variable	Gain
	nvar		hMCCmsg		= root:uf:acq:misc:MC700:hMCCmsg
	if ( hMCCmsg )
		variable	nCode	= UFP_MCCMSG_SetPrimSignalGain( hMCCmsg, Gain )
		if ( nCode == 0 )
			UFCom_Alert( UFCom_kERR_IMPORTANT, "MC700SetGain() failed. " )
		endif		
	else
		UFCom_Alert( UFCom_kERR_IMPORTANT, "MC700SetGain() failed as communication with MultiClamp(s) was not ready." )
	endif
End

static Function		MC700GetGain()
	nvar		hMCCmsg		= root:uf:acq:misc:MC700:hMCCmsg
	variable	Gain	= -1
	if ( hMCCmsg )
		Gain	= UFP_MCCMSG_GetPrimSignalGain( hMCCmsg )
	else
		UFCom_Alert( UFCom_kERR_IMPORTANT, "MC700GetGain() failed as communication with MultiClamp(s) was not ready." )
	endif
	return Gain
End

static Function		MC700GetSecondaryGain()
	nvar		hMCCmsg		= root:uf:acq:misc:MC700:hMCCmsg
	variable	Gain	= -1
	if ( hMCCmsg )
		Gain	= UFP_MCCMSG_GetSecoSignalGain( hMCCmsg )
	else
		UFCom_Alert( UFCom_kERR_IMPORTANT, "MC700GetSecondaryGain() failed as communication with MultiClamp(s) was not ready." )
	endif
	return Gain
End

Function		fNumberTest( s )
	struct	WMButtonAction &s
	// Does Igor represent 32 bit integers correctly ? YES - tested up to 5e11 
	variable	n
	variable	nBeg		= 100000000
	variable	nStep	= 39999997
	variable	nEnd		= 5e11
	for ( n = nBeg; n < nEnd; n += nStep )
		printf "%10d   %.15lf   %.15lf \r", n, n, n - round( n )
	endfor
End



