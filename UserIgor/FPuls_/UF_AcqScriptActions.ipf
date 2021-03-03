// UF_AcqScriptActions.ipf
// 

#pragma  rtGlobals 	= 1					// Use modern global access method. 	Do not use a tab after #pragma. Doing so will give compilation error in Igor 4.


// General  'Includes'
#include "UFCom_Constants"
#include "UF_AcqScript"

//=====================================================================================================================================
//  Reading and updating the 'Scriptpath' popupmenu control  using  LRU 


Function		fPmScriptPath( s ) 
	struct	WMPopupAction	&s
	if ( s.eventcode == 2 )							// -1: control being killed,  2: mouseup 
	 	string  	lst, sFo	= StringFromList( 2, s.ctrlName, "_" )						// as passed from 'PanelCheckbox3()'   e.g.  'root:uf:acq:pul:'  -> 'pul' 
		 string  	lstLRU	= lstScriptPath_a()
		 // printf "\t\tfPmScrptPath  a Popup  evcode:%d   \t\tSelect: '%s'  -> Items:%d  '%s'  \r", s.eventcode, s.popstr,  ItemsInList( lstLRU ),  lstLRU

		lstLRU	= ScriptPathLRUAdd( sFo, ksFPUL, s.popstr )	

		// printf "\t\tfPmScrptPath  b Popup  evcode:%d   \t\tSelect: '%s'  -> Items:%d  '%s'  \r", s.eventcode, s.popstr,  ItemsInList( lstLRU ), lstLRU

		ReloadScript( sFo, s.popstr ) 
	endif
	// printf "\t\tfPmScrptPath  c Popup  evcode:%d   \t\tSelect: '%s'  -> Items:%d  '%s'  \r", s.eventcode, s.popstr,  ItemsInList( lstLRU ), lstLRU
End

Function		fScriptPathPops_a( sControlNm, sFo, sWin )
	string		sControlNm, sFo, sWin
	PopupMenu	$sControlNm, win = $sWin,	 value = lstScriptPath_a()			// no local parameters allowed ->specific function required
End

Function	/S	lstScriptPath_a()
	//printf "lstScriptPath_a   : returns  '%s'  \r", ScriptPathLRU( ksACQ ) 
	return	ScriptPathLRU( ksACQ ) 
End	

//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function		fReloadScript( s ) 
// Runs a changed script and saves the changes permanently.  'Reload'  and  'Apply'  are the same if the script has not been changed.
	struct	WMButtonAction	&s
	string  	sScriptPath	= ScriptPath( ksACQ )
	ReloadScript( ksACQ, sScriptPath ) 
End

Function		ReloadScript( sFo, sScriptPath ) 
	string  	sFo, sScriptPath 
	if ( UFCom_FileExists( sScriptPath ) )
		variable	rCode	= 0
		LoadScript( sScriptPath, rCode )									// pass an existing path to skip a FileOpenDialog.  The path hopefully contains a valid script.
	else
		UFCom_Alert( UFCom_kERR_IMPORTANT, "Could not open script '" + sScriptPath + "' . " ) 
		string  	lstLRU	= ScriptPathSet(  sFo, ksFPUL, "" ) 				// 1. The empty string will clear the title line in the popupmen indicating that we currently have no active script file.  2. Or perhaps set to   ' UFPE_ksSCRIPTS_DRIVE + UFPE_ksSCRIPTS_DIR'
			  	lstLRU	= ScriptPathLRURemove( sFo, ksFPUL, sScriptPath )	// the missing file will no longer be offered in the popupmenu
	endif
End

Function		fLoadScript( s ) 
	struct	WMButtonAction	&s
	string  	sScriptPath	= ""							// pass an empty path to invoke a FileOpenDialog
	variable	rCode	= 0
	LoadScript( sScriptPath, rCode )
End

Function		LoadScript( sScriptPath, Code )
	variable	&Code
	string  	sScriptPath
	 printf "\t\tLoadScript  bef load \tcode:%2d   sScriptPath: '%s'  \r", Code, sScriptPath
	sScriptPath		= LoadScriptFileDialog( sScriptPath, UFPE_ksSCRIPTS_SYMPATH )	// let the user select a script in 'ScriptPath'
	string  lstLRU		= ScriptPathSet( ksACQ, ksFPUL, sScriptPath )					// change the global 'ScriptPath' early so that it is valid in  'LoadProcessScript'  for deriving the Acq Disp settings filepath
	string  sIniBasePath	= FunctionPath( ksFP_APP_NAME )							// the Ini file containing the window position will be written in a subdirectory parallel to UF_PulseMain.ipf 
	UFCom_IniFile_SectionSetWrite( ksACQ, "FPuls", "Script", "Path", lstLRU, sIniBasePath )	// ini scriptpath save

	Code				= LoadProcessScript( ksACQ , sScriptPath )					

	 printf "\t\tLoadScript  aft load \tcode:%2d   sScriptPath: '%s' =?= '%s'  (Scriptpath from INI) \r", Code, sScriptPath, UFCom_Ini_Section( ksACQ, "FPuls", "Script", "Path" )[0,200]
End

Function		fApplyScript( s ) 
	struct	WMButtonAction	&s
	// printf "\t\tButtonProc \t%s\t \r",  s.ctrlname
	ApplyScript()
End

Function		ApplyScript()
// Runs a temporarily changed script without changing the script permanently.  'Reload'  will restore the previous version.    'Reload'  and  'Apply'  are the same if the script has not been changed.
	string		sScriptPath		= ScriptPath( ksACQ )
	string		sNoteBookName	= ksSCRIPT_NBNM 			// = 'Script'	
	string		sTmpScriptPath		= UFPE_ksSCRIPTS_DRIVE + UFPE_ksSCRIPTS_DIR + UFPE_ksTMP_DIR + ":" + UFCom_StripPathAndExtension( sScriptPath ) + ".txt" 	// 'C:UserIgor:Scripts:Tmp:XYZ.txt'
	if ( WinType( sNoteBookName ) == UFCom_WT_NOTEBOOK )						// window exists and is a notebook
		SaveNoteBook  /O /S=2	$sNoteBookName  as  sTmpScriptPath				// save any changes the user may have made  in a temporary script....
	endif																	// ...(leave the original script unchanged)....
	// printf "\t\tApplyScript() \t\t\tsScriptPath: '%s' .\tSaving as and reloading script/NB  '%s' \r", sScriptPath,  sTmpScriptPath 
	variable	Code	= 0
	sTmpScriptPath	= LoadScriptFileDialog( sTmpScriptPath, UFPE_ksSCRIPTS_SYMPATH )	// ...and pass the valid temporary script path to load the script without opening the FileOpenDialog
	Code			= LoadProcessScript( ksACQ, sTmpScriptPath )						// ... BUT DO NOT CHANGE the global 'ScriptPath'
End																	


Function		fSaveScript( s ) 
	struct	WMButtonAction	&s
	string  	sScriptPath		= ScriptPath( ksACQ )
	string		sNoteBookName	= ksSCRIPT_NBNM 		// = 'Script'	
	// printf "\t\t%s \t\t\tsScriptPath: '%s' . \tSaving as sNoteBookName:\t'%s' \r", ctrlName, sScriptPath, sNoteBookName 
	if ( WinType( sNoteBookName ) == UFCom_WT_NOTEBOOK )				// window exists and is a notebook
		SaveNoteBook  /O /S=2	$sNoteBookName  as  sScriptPath	// 2003-1211 save any changes in the script the user may have made in the same file (will not work without /S=2 = Save as)
	endif
	UFCom_EnableButton( "pul", "root_uf_acq_pul_ApplyScript0000", 	UFCom_kCo_ENABLE )		// 2004-08-05 Enable the 'Apply' button after save. It may have been disabled when trying to load a bad script, 
End

Function		fSaveAsScript( s ) 
	struct	WMButtonAction	&s
	// printf "\t\tButtonProc \t%s\t \r",  s.ctrlname
	string  	sScriptPath	= ScriptPath( ksACQ )
	string		sWNm		= ksSCRIPT_NBNM 		// = 'Script'		
	if ( WinType( sWNm ) == UFCom_WT_NOTEBOOK )							// window exists and is a notebook
		string		sName	= ""
		// printf "\t\t%s   1 \tsScriptPath:'%s'  -> \r", s,ctrlname, sScriptPath
		variable	nRefNum
		Open	/D  /T = "TEXT" 	nRefNum  as sScriptPath							// Save / Create dialog: can also choose a dir besides file and cancel
		if ( strlen( S_fileName	) )
			 sName	= S_fileName	
		endif

		SaveNoteBook  /O /S=2 $sWNm  as sName							// save any changes the user may have made and change Notebook title 
		DoWindow /T $sWNm, UFCom_FileNameOnly( sName )					// update window title

		string  lstLRU		= ScriptPathSet( ksACQ, ksFPUL, sName )
		string  sIniBasePath	= FunctionPath( ksFP_APP_NAME )					// the Ini file containing the window position will be written in a subdirectory parallel to UF_PulseMain.ipf 
		UFCom_IniFile_SectionSetWrite( ksACQ, "FPuls", "Script", "Path", lstLRU, sIniBasePath )		// ini scriptpath save

		 printf "\t\t%s   2 \tsScriptPath:'%s'  =?= '%s'  ->Saving NB as:  \t'%s' \r", s.ctrlname, sScriptPath, ScriptPath( ksACQ ), sName
	endif
End

Function		fShowScript( s ) 
	struct	WMButtonAction	&s
	nvar		state			= $ReplaceString( "_", s.ctrlname, ":" )			// the underlying button variable name is derived from the control name
	string  	sFo			= ksACQ									// 'acq'
	string  	sSubFoIni		= "Scrip"
	string  	sWNm		= ksSCRIPT_NBNM							//  'script' 
	
	string  	sIniBasePath	= ScriptPath( sFo )							// derive  IniPath  from Script path   as  sSubFoIni =  'Scrip'
	UFCom_WndVisibilitySetWrite_( sFo, sSubFoIni, sWNm, "Wnd", state, sIniBasePath )
	 printf "\t\t\t\t%s\tstate:%2g \tWnd exists (on action proc entry):%2d\tLoaded prefs \t \r",  s.ctrlname, state,  WinType(sWNm)==UFCom_WT_NOTEBOOK 

	string  	sScriptTxt		= ScriptTxt( sFo )
	string  	sTitle  		= UFCom_FilenameOnly( ScriptPath( sFo ) )
	ConstructScriptNotebook( sFo, sWNm, sTitle, sScriptTxt ) 				// ...we construct it (but perhaps invisibly)
End


Function 		fScriptNbWndHook( s )
// The window hook function of the  script notebook window detects when the user moves the notebook and stores the coordinates in the INI file. 
//  And it adjusts the corresponding show/hide button in the main panel according to the windows show/hide/killed state.
	struct	WMWinHookStruct &s
	string  	sFo			= ksACQ
	string  	sSubFo		= ksFPUL
	string  	sSubFoIni		= "Scrip"
	string  	sKey			= "Wnd"
	string  	sControlBase 	= "gbShowScrpt"
	string  	sIniBasePath	= ScriptPath( sFo )							// derive  IniPath  from Script path   as  sSubFoIni =  'Scrip'
	return	UFCom_WndUpdateLocationHook( s, sFo, sSubFo, sSubFoIni, sKey, sControlBase, sIniBasePath )
End

	Function		ConstructScriptNotebook( sFo, sNb, sTitle, sText )
		string  	sFo, sNb, sTitle, sText
		string  	sSubFoIni		= "Scrip"
		string  	sIniBasePath	= ScriptPath( sFo )							// derive  IniPath  from Script path   as  sSubFoIni =  'Scrip'
		variable	bVisible		= UFCom_WndVisibility(  sFo, sSubFoIni, sNb, "Wnd" )
		string  	lstWndInfo		= UFCom_Ini_Section( sFo, sSubFoIni, sNb, "Wnd" )			//
		 printf "\t\tConstructScriptNotebook: '%s'  setting  visible :%d \r" , lstWndInfo, bVisible
		if ( strlen( lstWndInfo ) == 0 )
			variable	left = 10,  top = 50,  right = 250,  bot = 270						// default window position only used if valid positions could not be found in global INI list / INI file.... 
			lstWndInfo	= UFCom_WndPositionSetWrite( sFo, sSubFoIni, sNb, "Wnd", lstWndInfo, left, top, right, bot, sIniBasePath )
		else
			lstWndInfo	= UFCom_WndPosition_( sFo, lstWndInfo, left, top, right, bot )			// ...which will normally be overwritten by the window positions extracted from  'sWndInfo'  (if 'sWndInfo' is not empty)
		endif

		if (  WinType( sNb ) != UFCom_WT_NOTEBOOK )							// Only if the Notebook window does not  exist.. 
			NewNotebook /F=0 /K=2  /V=(bVisible) /W=( left, top, right, bot )  /N=$sNb		// disable the window close button
		 	SetWindow	$sNb, hook( Script )     = fScriptNbWndHook						// the processing in response to user actions in the notebook window :  save panel coordinates on move/resize
			//UFCom_LstPanelsSet( ksACQ, ksfACQVARS,  AddListItem( sNb, UFCom_LstPanels( ksACQ, ksfACQVARS ) ) )	
			UFCom_LstPanelsAdd( ksACQ, ksfACQVARS, sNb )	
		else
			// print "ConstructScriptNotebook: moving window, visible :" , bVisible
			if ( bVisible )
				UFCom_WndUnhide( sNb )
			else
				UFCom_WndHide( sNb )
			endif
// 
//			MoveWindow/W=$sNb  left, top, right, bot	// 2009-02-02  DOES not work as 'deactivate' is called when window is minimised (???NOT for other windows???) and so the wrong 'minimised' coordinates are stored which are here restored(=wrong also)
		endif	
		// print "ConstructScriptNotebook: setting  visible :" , bVisible
		string  sButtonName	= "root_uf_" + sFo + "_" + ksFPUL + "_" + "gbShowScrpt" + "0000" 
		UFCom_TurnButton( ksFPUL, sButtonName, bVisible )							// if the window has been created in the hidden state  we adjust the button state so that the next press creates the window again

		Notebook	$sNb selection={startOfFile, endOfFile}, text="", selection={startOfFile, startOfFile}	// delete old stuff
		Notebook	$sNb text = sText
		DoWindow  /T	$sNb, sTitle
	End

//=========================================================================================================================
