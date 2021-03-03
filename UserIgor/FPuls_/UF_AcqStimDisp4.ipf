// UF_AcqStimdisp4.ipf 
// 
// Routines for stimulus display used by FPulse  
//


#pragma rtGlobals=1						// Use modern global access method.

#include "UFCom_Panel" 					// UFCom_PossiblyCreateFolder()
#include "UFCom_ListProcessing" 
//#include "UFCom_ColorsAndGraphs" 		
//

Function 		fFP_StimDispWndHook( s )
// The window hook function of the 'Stimulus Display' graph detects when the user interacts with the graph. 
// Moving/resizing the graph does not directly write the coordinates to file as this would be called much too often, instaed it is done on 'deactivate'.  
// Drawback:  After moving/resizing the user must click into another window to trigger 'deactivate' or the changes will not be stored.
// Also recognises and processes mouse clicks in the graph.
	struct	WMWinHookStruct &s
	// printf "\t\tfFP_StimDispWndHook   \t%s  \r", s.eventName
// 2009-10-29
if (  s.eventCode != 2  &&   s.eventCode != 17 )				// 2:kill,  17:killvote
	string  	sFo			= ksACQ
	string  	sSubFo		= ksFPUL
	string  	sSubFoIni		= "Scrip"
	string  	sControlBase 	= "buDisplStim"										// !!!  ass name    the 'Stimulus display + ' /  'Stimulus display -'  button in the main panel
	string  	sIniBasePath	= ScriptPath( sFo )									// derive  IniPath  from Script path   as  sSubFoIni =  'Scrip'
	UFPE_StimDispWndHook( s, sFo, sSubFo, sSubFoIni, sControlBase, sIniBasePath )
endif
End


//==================================================================================================================================
//  DISPLAY STIMULUS :  THE  BUTTON  ACTION PROCEDURE

Function		fbuDisplayStimWnd( s ) 
	struct	WMButtonAction	&s
	nvar		bDisplay		= $ReplaceString( "_", s.ctrlname, ":" )				// the underlying button variable name is derived from the control name
	string  	sFo			= StringFromList( 2,  s.ctrlname, "_" )					// e.g.  'root_uf_acq_pul_buDisplStim0000' -> 'acq'
	string  	sSubFo		= StringFromList( 3,  s.ctrlname, "_" )					// e.g.  'root_uf_acq_pul_buDisplStim0000' -> 'pul'
	string  	sSubFoIni		= "Scrip"
	// print  "\t\tfbuDisplayStimWnd( s ) ", s.ctrlname, sFo, sSubFo, "state:", bDisplay
	string  	sWNm		= UFPE_StimWndNm_ns( sFo )						// the stimulus graph window
	string  	sIniBasePath	= ScriptPath( sFo )								// derive  IniPath  from Script path   as  sSubFoIni =  'Scrip'
	string  	lstWndInfo		= UFCom_Ini_Section( sFo, sSubFoIni, sWNm, "Wnd" )
	string  	lstIODi		= UFCom_Ini_Section( sFo, sSubFoIni, sWNm, "Trc" )
	variable	left = 0,  top = 0,  right = 0,  bot = 0
	string  	sTxt	= ""

	if ( bDisplay )															// User wants to _display_ the stimulus display window so we possibly construct it
		if (  WinType( sWNm ) != UFCom_WT_GRAPH )								// The Stimulus graph window does not yet exist (this is normal at startup).. 
			sTxt		= ">Creating"
			UFCom_PossiblyCreateFolder( "root:uf:" + sFo + ":" + ksDIS  + ":" + sWNm )		// Create the window subfolder

			// Design issue: If the user has _KILLED_ (not only hidden) the window it will be created at the _DEFAULT_ position (not on the position from the INI file)  if the user presses 'Display'.  However,  on LoadCfg it will be created at the INI position.
			lstWndInfo	= UFCom_Ini_Section( sFo, sSubFoIni, sWNm, "Wnd" )			//
			if ( strlen( lstWndInfo ) == 0 )
				DisplayStimWndPositionDefault( left, top, right, bot )					// default window position only used if valid positions could not be found in global INI list / INI file.... 
				lstWndInfo	= UFCom_WndPositionSetWrite( sFo, sSubFoIni, sWNm, "Wnd", lstWndInfo, left, top, right, bot, sIniBasepath )
			else
				lstWndInfo	= UFCom_WndPosition_( sFo, lstWndInfo, left, top, right, bot )	// ...which will normally be overwritten by the window positions extracted from  'lstWndInfo'  (if 'lstWndInfo' is not empty)
			endif
			Display	/N = $sWNm  /K=1	/W=(left, top, right, bot)
			DoWindow /T	$sWNm    UFCom_FileNameOnly( ScriptPath( sFo ) )			// set the window title
			SetWindow     	$sWNm   hook( hFP_StimDispWndHook ) = fFP_StimDispWndHook
			DiSControlbar_a( sWNm, sFo, lstWndInfo, 1 )

			lstIODi	= DiS_TrcDefaults( sFo, sIniBasePath )									// store the added traces (still defaults)

			UFPE_DisplayStimulusCompute( sFo, sWNm )
			UFPE_DiSAppendChansAndAxes( sFo, sWNm )

		else																// User wants to _display_ the window but the window exists already and is only hidden...

			if ( WinType( sWNm ) )											// only if the window exists (the user may have 'forcefully' killed even a window designed to be permanent
				sTxt		= "> Unhide"
				SetWindow $sWNm, hide = 0									// ...so we only have to restore the window.  Unhides HIDDEN and  restores MINIMISED windows
				DoWindow /F $sWNm										// bring  the stimulus graph window  to the front
			endif

		endif

		//DoWindow /F $sWNm												// bring  the stimulus graph window  to the front

	else																	// User wants to _hide_ the stimulus graph 
		sTxt		= "> Hiding"
		if ( WinType( sWNm ) == UFCom_WT_GRAPH )								//    only if a graph window with that name exists already ...
			UFCom_WndHide( sWNm )										// .. we may simply hide it
		endif
	endif
	UFCom_WndVisibilitySetWrite_( sFo, sSubFoIni, sWNm, "Wnd", bDisplay, sIniBasepath )
	printf "\t\tfbuDisplayStimWnd()\t%s\t%s\tsWNm:'%s'\tleft:\t%d\ttop:\t%d\tright:\t%d\tbot:\t%d\t (has also stored ini)\t%s \r", sTxt, sFo, sWNm, left, top, right, bot, lstWndInfo[0,200]
End


static Function		DiSPossiblyCreateWindow( sFo, sSubFoIni, sSection, sKey, sWNm )
// Creates the stimulus window  including the controlbar  or only moves it.  The location of the window and the settings of the control bar are retrieved from 'lstWndInfo'  and restored accordingly.   
	string  	sFo, sSubFoIni, sSection, sKey, sWNm
	variable	left, top, right, bot
	string  	lstWndInfo	= UFCom_Ini_Section( sFo, sSubFoIni, sSection, sKey )
	UFCom_WndPosition_(	 sFo, lstWndInfo, left, top, right, bot )							// extract  'lstWndInfo'  and pass back the window (default) position (references are changed)
	variable	nBlock	= DiS_WndBlock(	lstWndInfo )
	variable	nLap		= DiS_WndLap(   	lstWndInfo )
	variable	bNostore	= DiS_WndNostore(	lstWndInfo )
	variable	bHires	= DiS_WndHires(	lstWndInfo )
	variable	bVis		= UFCom_WndVisibility_(	lstWndInfo )
	string  	sTxt		= ""
	if ( WinType( sWNm ) != UFCom_WT_GRAPH )									// Create window only if it does not exist yet. 

		sTxt	= "Creating"
		Display 	/N = $sWNm /K=1	/W=(left, top, right, bot)   /HIDE=( ! bVis)
		SetWindow 	$sWNm   hook( hFP_StimDispWndHook ) = fFP_StimDispWndHook	
		DiSControlbar_a( sWNm, sFo, lstWndInfo, 1 )

	else	
		sTxt	= "Moving"
		MoveWindow/W=$sWNm  left, top, right, bot
	endif
	DoWindow /T	$sWNm    UFCom_FileNameOnly( ScriptPath( sFo ) )				// set the window title
	string  	sButtonName	= "root_uf_acq_pul_buDisplStim0000"		// !!!  ass name    the 'Stimulus display + ' /  'Stimulus display -'  button in the main panel
	UFCom_TurnButton( ksFPUL, sButtonName, bVis )				// if the window is to be created in the hidden state we adjust the button state so that the next press creates the window again
	DiSBlocksUpdatePM(	sFo, sWNm, nBlock )
	DiSExpandLapsSet(	sFo, sWNm, nLap )
	DiSNostoreSet(		sFo, sWNm, bNostore )
	DiSHiresSet(		sFo, sWNm, bHires )
	printf "\t\tDiSPossiblyCreateWindow    \t%s\t%s\t%s\tleft:\t%d\ttop:\t%d\tright:\t%d\tbot:\t%d\tBlock:%2d\tLap:%2d\tNostore:%2d\tHires:%2d\tVisibility:%2d \r", sTxt, sFo, sWNm, left, top, right, bot, nBlock, nLap, bNostore, bHires, bVis
End


//================================================================================================================================
//	LOADING  AND  SAVING  THE STIMULUS  DISPLAY  CONFIGURATION

 Function		LoadDisplayCfgStim( sFolders )
// Called whenever a script file is loaded.  Attempts to read initialisation settings from an INI file with same name as script but with extension '.ini'  and located in a subdirectory of where the script file has been loaded from.
// In contrast to the processing of the acquisition display windows here no attempt is made to inherit configuration settings from the previous previous script if those settings are missing.  Instead hard-coded defaults are used.
	string		sFolders
	string  	sTxt, lstWndInfo, sTrcInfo, sSubFoIni, sSection,  sKey
	string		sFo		= StringFromList( 0, sFolders, ":" )					// e.g. 'acq:pul'  ->  'acq'
	string  	sWNm 	= UFPE_StimWndNm_ns( sFo )
	variable	left = 0,  top = 0,  right = 0,  bot = 0
	UFCom_PossiblyCreateFolder( "root:uf:" + sFo + ":" + ksDIS  + ":" + sWNm )		// Create the window subfolder

	string  	sIniBasePath	= ScriptPath( sFo )							// derive  IniPath  from Script path   as  sSubFoIni =  'Scrip'
	sTxt		= "FOUND" 
	sSubFoIni	= "Scrip"
	sSection	= cSTIMWNDNAME		// e.g. 'Sti'
	sKey  	= "Wnd"
	lstWndInfo	= UFCom_Ini_Section( sFo, sSubFoIni, sSection, sKey )						// tries to extract from the huge global multi-line string list containing the entire settings and returns 1 section, which can be empty
	if ( strlen( lstWndInfo ) == 0 )													// missing file or missing section
		DisplayStimWndPositionDefault( left, top, right, bot )						// default window position only used if valid positions could not be found in global INI list / INI file.... 
		lstWndInfo	= UFCom_WndPositionSetWrite( sFo, sSubFoIni,  sSection, sKey, lstWndInfo, left, top, right, bot, sIniBasePath )
		sTxt		=  "COULD NOT FIND"
	endif
	// printf "\r\t\tLoadDisplayCfgStim  \t\t   \r\t\t\t%s user display config file  and  WndInfo : '%s'  \r", sTxt, lstWndInfo
	DiSPossiblyCreateWindow( sFo, sSubFoIni, sSection, sKey, sWNm )				// create or just move it

	sTxt		= "FOUND" 
	sKey  	= "Trc"
	sTrcInfo	= UFCom_Ini_Section( sFo, sSubFoIni, sSection, sKey )						// tries to extract from the huge global multi-line string list containing the entire settings and returns 1 section, which can be empty
	if ( strlen( sTrcInfo ) == 0 )											// missing file or missing section
		sTrcInfo	= DiS_TrcDefaults( sFo, sIniBasePath )
		sTxt		=  "COULD NOT FIND"
	endif
	 printf "\r\t\tLoadDisplayCfgStim  \t\t   \r\t\t\t%s user display config file  and  TrcInfo  : '%s'  \r", sTxt, sTrcInfo
	//UFCom_DisplayMultipleList_( "LoadDisplayCfgStim( init )  sTrcInfo ", sTrcInfo,	"~;,", 7, UFPE_ioTemplate( 0 ) )
	//UFCom_DisplayMultipleList_( "LoadDisplayCfgStim()   lllstIO ", LstIO( sFo ),	"~;,", 7, UFPE_ioTemplate( 0 ) )

	// Check that all channels  referenced in the Dis Stimulus settings are actually contained in the IOList 'lllstIO',  remove offending ones. 
	// Change the Disp Stimulus entry in the INI file and store the file.  [This mismatch in the data structures will arise if the user changes channels in the script file or renames the INI or the script file]
	// A more rude (but perhaps cleaner) approach would be to delete the entire Dis Stimulus settings  'sTrcInfo'  in the INI file if any channel mismatch is detected.
	DiS_AdjustTracesToScriptChans( sFo, sSubFoIni, sSection, sKey, sTrcInfo, sIniBasePath )		
	
	UFPE_DisplayStimulusCompute( sFo , sWNm )							// the window including the controlbar has been created above so now we can compute the trace which depends on the controlbar settings
	
	UFPE_DiSAppendChansAndAxes( sFo, sWNm )

//	UFCom_DisplayMultipleList( "lstIODI  B",  lstIODI, "~;,", 7 )  
//	printf "\t\tlstWndInfo B: '%s'  \r", lstWndInfo
End


