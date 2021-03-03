//
//  UF_AcqComments.ipf 
// 
 
#pragma rtGlobals=1									// Use modern global access method.

#include "UFCom_Panel"
//#include "UFPE_Constants3"

//=================================================================================================================
//	DIALOG PANEL  FOR  COMMENTS

static strconstant	ksPN_NAME		= "cmt"			// Panel name   _and_  subfolder name  _and_  section keyword in INI file
static strconstant	ksPN_TITLE		= "Comments"		// Panel title
static strconstant	ksPN_CTRLBASE	= "gbPnComment"	// The  button base name (without prefix root:uf... and postfix 0000) in the main panel displaying and hiding THIS subpanel
static strconstant	ksPN_INISUB		= "FPuls"			// The  INI subfolder  below folder 'acq'   and   the  INI file location (here in a subdirectory to FPulse=FPulseMain.ipf)
static strconstant	ksPN_INIKEY		= "Wnd"			// The  keyword in the INI file (here always 'Wnd' as we are dealing with window positions and visibility)


//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Action procedure for displaying and hiding a subpanel

Function		fPnComment( s ) 
// The  Button action procedure of the button in the main panel displaying and hiding THIS subpanel.  Unfortunately we can not wrap this in a function because of the specific Panel creation function name below (due to hook function)
	struct	WMButtonAction	&s
	nvar		state		= $ReplaceString( "_", s.ctrlname, ":" )					// the underlying button variable name is derived from the control name
	// printf "\t\t\t\t%s\tvalue:%2d   \t\t%s\t%s\t%s\t \r",  UFCom_pd( s.ctrlname, 25),  state, UFCom_pd(ksPN_INISUB ,9), UFCom_pd(ksPN_NAME ,9), UFCom_pd( ksPN_INIKEY ,9)	
	string  	sIniBasePath	= FunctionPath( ksFP_APP_NAME )					// the Ini file containing the window position will be written in a subdirectory parallel to UF_PulseMain.ipf 
	UFCom_WndVisibilitySetWrite_( ksACQ, ksPN_INISUB, ksPN_NAME, ksPN_INIKEY, state, sIniBasePath )
	if ( state )															// if we want to  _display_  the panel...
		if ( WinType( ksPN_NAME ) != UFCom_WT_PANEL )						// ...and only if the panel does not yet  exist ..
			PanelComment( UFCom_kPANEL_DRAW )							// *** specific ***...we must build the panel
		else
			UFCom_WndUnhide( ksPN_NAME )								//  display again the hidden panel 
		endif
	else
		UFCom_WndHide( ksPN_NAME )									//  hide the panel 
	endif
End


Function		PanelComment( nMode )
// Create the panel.  Unfortunately we can not wrap this in a function because of the specific hook function name
	variable	nMode
	string  	sFBase		= "root:uf:"
	string  	sFSub		= ksACQ_	
	string		sDFSave		= GetDataFolder( 1 )								// The following functions do NOT restore the CDF so we remember the CDF in a string .
	UFCom_PossiblyCreateFolder( sFBase + sFSub + ksPN_NAME ) 
	InitPanelComment( sFBase + sFSub, ksPN_NAME )							// *** specific ***fills big text wave  'sPnOptions' (=wPn)  with all information about the controls necessary to build the panel
	UFCom_RestorePanel2Sub( ksACQ, ksFPUL, ksPN_NAME, ksPN_TITLE, sFBase, sFSub, ksPN_INISUB, ksPN_INIKEY, ksPN_CTRLBASE, nMode )
	SetWindow		$ksPN_NAME,  hook( $ksPN_NAME ) = fHookCmt			// *** specific ***
	SetDataFolder sDFSave												// Restore CDF from the string  value
	//UFCom_LstPanelsSet( ksACQ, ksfACQVARS , AddListItem( ksPN_NAME, UFCom_LstPanels( ksACQ, ksfACQVARS ) ) )	
	UFCom_LstPanelsAdd( ksACQ, ksfACQVARS, ksPN_NAME )	
End


Function 		fHookCmt( s )
// The window hook function detects when the user moves or resizes or hides the panel  and stores these settings in the INI file
	struct	WMWinHookStruct &s
	string  	sIniBasePath	= FunctionPath( ksFP_APP_NAME )					// the Ini file containing the window position will be written in a subdirectory parallel to UF_PulseMain.ipf 
	return	UFCom_WndUpdateLocationHook( s, ksACQ, ksFPUL, ksPN_INISUB, ksPN_INIKEY, ksPN_CTRLBASE, sIniBasePath )
End


Function		InitPanelComment( sF, sPnOptions )
	string  	sF, sPnOptions
	string		sPanelWvNm = sF + sPnOptions
	variable	n = -1, nItems = 20
	// printf "\t\tInitPanelComment( '%s',  '%s' ) \r", sF, sPnOptions 
	make /O /T /N=(nItems)	$sPanelWvNm
	wave  /T	tPn	=		$sPanelWvNm
	//				Type	 NxL Pos MxPo OvS	Tabs		Blks		Mode	Name		RowTi	ColTi		ActionProc	XBodySz	FormatEntry	Initvalue						Visibility	HelpTopic
	n += 1;	tPn[ n ] =	"STR:  1:	0:	1:	0:	°:		,:		1,°:		gsGenComm:	General:	:		:			500:		:			~"+UFPE_ksNoGenCOMMENT+":	:		General comment:	"	
	n += 1;	tPn[ n ] =	"STR:  1:	0:	1:	0:	°:		,:		1,°:		gsSpecComm:	Specific:	:		:			500:		:			~no specific comment:			:		Specific comment:	"

	redimension  /N = ( n+1)	tPn
End

Function	/S	GeneralComment()
	svar		sGenComment	= root:uf:acq:cmt:gsGenComm0000	
	// printf "\t\tGeneralComment() \treturns '%s' \r", sGenComment
	return	sGenComment
End

Function	/S	SpecificComment()
	svar		sSpecComment	= root:uf:acq:cmt:gsSpecComm0000	
	// printf "\t\tSpecificComment() \treturns '%s' \r", sSpecComment
	return	sSpecComment
End


