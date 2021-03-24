
// FPAcqScript.ipf 
// 
// Routines for loading and processing scripts used only by FPulse  
//
 
#pragma rtGlobals=1						// Use modern global access method.

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//   GENERAL SCRIPT FILE LOADING
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//constant			YFREELO_FOR_SB_AND_CMDWND	= 140	// points
//static constant		YNAMELINE						= 20		// points
// 2009-12-12  to avoid confusion with new-style
//strconstant		ksSCRIPT_NB_WNDNAME 		= "Script"
strconstant		ksSCRIPT_NB_WNDNAME 		= "Script_"


static Function	stInitAllLoadScript( sFolder )
	string  	sFolder
// Cave:	Some waves MUST be killed when rereading a script/stimfile  e.g. traces in 'online analysis options', 'Acquisition window options'
// 		Some waves MUST NOT be killed when rereading a stimfile (no times changed in stimfile)   e.g. 'wAnRegion'  for  user analysis regions, colors
// 		Some waves MUST SOMETIMES be killed when rereading a stimfile when times have been changed in stimfile:  e.g. 'wAnRegion'  for  user analysis regions
//		We kill selected waves  by  killing  waves  located  special  data folders. Another approach: pass wave names to be killed  in a list.

	// printf "\t\tInitAllLoadScript 0 sFolder:%s    entry  data folder  '%s' \r", sFolder, GetDataFolder( 1 )
	//  KILLING GRAPHS (or at least killing all traces in a graph) is required by IGOR before we can kill a wave contained in a graph
	KillTracesInMatchingGraphs_( ksW_WNM + "*" )		// Any window (not only Acquis windows) will be erased when a script is loaded or applied if its name starts with 'W'

	EraseTracesInGraph( StimWndNm( sFolder ) )			// 031201 we do NOT kill the window (because we want to keep a user-adjusted size and position), but we must kill all traces to avoid an error in 'KillWaves' below 

// todo KillGraphs( ksAFTERACOldWNM  ) without sorting
	KillGraphs( ksAFTERACOldWNM + "*", ksW_WNM )	// the windows built by 'Display raw data (after Acq)'
	KillGraphs( ksREADCFS_WNM	 + "*", ksW_WNM )	// the windows built by 'ReadCfs'
	KillGraphs( ksfEVO_WNM		 + "*", ksW_WNM )	// the windows built by 'ReadCfs/Eval new '  041215
	
	// The following line removes all graphs which are named by IGOR (default='Graph0', 'Graph1'...) and not renamed by FPulse.
	// Actually there should be no such default-named graphs except when the user removes traces from graphs. 
	KillGraphs( "Graph*", ksW_WNM )

// 051103  sDFSave  might be one of the folders deleted above  (e.g.  root:uf:aco:ar)  so we may not be able to restore it
	// string		sDFSave	= GetDataFolder( 1 )
	// printf "\t\tInitAllLoadScript(4 sFolder:%s )  saves data folder  '%s' \r", sFolder, sDFSave

	KillDataFolderUnconditionally( ksROOTUF_ + sFolder + ":ar" )
	KillDataFolderUnconditionally( ksROOTUF_ + sFolder + ":stim" )
if (  bCRASH_ON_REDIM_TEST14 )				// 051105   
	KillDataFolderUnconditionally( ksROOTUF_ + sFolder + ":dig" )
	KillDataFolderUnconditionally( ksROOTUF_ + sFolder + ":store" )
endif
	KillDataFolderUnconditionally( ksROOTUF_ + sFolder + ":" + ksF_IO )	// root:uf:aco:io     (acquisition) : for the large basic IO waves  e.g. 'Dac0'  ,  'Adc1' , 'PoN1'
	KillDataFolderUnconditionally( ksROOTUF_ + sFolder + ":co" )
	KillDataFolderUnconditionally( ksROOTUF_ + sFolder + ":dispFS" )			// root:uf:aco:tmp  (acquisition) : for the whole bunch of similar display waves Adc..., Dac... with different FrmSwp-suffices

// 051103  sDFSave  might be one of the folders deleted above  (e.g.  root:uf:aco:ar)  so we may not be able to restore it
//	SetDataFolder sDFSave 
	SetDataFolder "root:" 
	// printf "\t\tInitAllLoadScript 5 sFolder:%s    \r", sFolder
End


Function 	/S	LoadScript_( sPath, rCode, bKeepOrNewAcqDisp)
// Loads the script file given by 'sPath'.  If empty string then a  FileOpenDialog  is presented.  Enables/disables controls depending  on whether a valid script has been loaded.
// Returns  empty string if user clicked  Cancel .  Even if script file was not valid  the script name is returned so that  the user can open and edit the script 
	string  	sPath
	variable	&rCode
	variable	bKeepOrNewAcqDisp

	string		sFolder	= ksfACO
	string		sWin		= ksPN_NAME_SDAO

	rCode	= kOK
 	string		sFileName		= GetFileNameFromDialog( sPath )		// can also be empty string  if user clicked Cancel

	EnableSetVar( "PnPuls", "root_uf_aco_keep_gnProts", kNOEDIT)	// We cannot change the number of protocols as this would trigger 'ApplyScript()'
	EnableButton( "PnPuls", "buApplyScript",		kDISABLE )			// 'Apply'  	will not work
	EnableButton( "PnPuls", "buSaveScript", 		kDISABLE )			// 'Save'  	will not work
	EnableButton( "PnPuls", "buSaveAsScript",	kDISABLE )			// 'SaveAs'  will not work
	EnableButton( "PnPuls", "buStart", 			kDISABLE )			// Do not  allow to go into acquisition  when a script is just being loaded
	EnableButton( "PnPuls", "buStopFinish", 		kDISABLE )			// Do not allow to stop an acquisition at cold startup before before a script has been loaded
	EnableButton( "PnPuls", "buDisplayStimDlg",	kDISABLE )			// we cannot  display a stimulus before wE and wFixSwp..  has been set by reading a script
	EnableButton( "PnPuls", "buAcqWindowsDlg",	kDISABLE )			// we cannot  display the panel before 'wIO' in PnControl(..Traces..) has been set...
	EnableButton( "PnPuls", "buAnalysisAcqDlg", 	kDISABLE )			// we cannot build this panel before a script is loaded and 'wIO' is built for 'ioChanList()'
	EnableButton( "PnPuls", "buOLAnalysisDlg",	kDISABLE )			// we cannot build this panel before a script is loaded and 'wIO' is built for 'ioChanList()'
	// todo Gain Panel????? here

	// printf "\t\tLoadScript 0 sFolder:%s    entry data folder  '%s' \r", sFolder, GetDataFolder( 1 )

	
	if ( strlen( sFileName ) )

		//string bf; sprintf bf, "\tLOADING  SCRIPT  '%s.TXT' ...  \r", UpperStr( StripPathAndExtension( sFileName ) ) ;  Out( bf )
		string bf; sprintf bf, "\tLOADING  SCRIPT  V3xx  '%s.txt' ...  \r", StripPathAndExtension( sFileName ) ;  Out( bf )
		stInitAllLoadScript( sFolder )									// kills ar:wLine, clears graphs, kills all waves in 'root:uf:aco:'  
		
		// Read the original raw script including  comments and empty lines  for the script notebook and for storing it in the acquisition file 
		string    sRawScript	= stReadScript( sFolder, sFileName )			
		CompactScript( sFolder, sRawScript )							// 050205  sets  globals  'gsScript'  and  'gsCoScript'  (original  amd compacted script without comments)
		InitializeCFSDescriptors_( ksfACO, sRawScript )					// 050207 Should be called  only once during initialisation, but is actually called with every new script file as..
															// 1. flaw in Pascal Pulse (file name is inDesc)   2. number of script lines must be known. Could be improved?

		 // printf "\t\tLoadScript   receives %s\t-> FileNameDialog()  returns  %s  \tCalling  InterpretScript/.../SetTranfersArea \r", pd(sPath,29), pd(sFileName,30)

		if ( InterpretScript_( ksfACO, ksPN_NAME_SDAO, kDOACQ ) != kERROR )				// Sets  wG , wIO ,  wFix , wE...... in  root:uf:aco:	, needs wLine(aco)	
			sprintf bf, "\t\tLoadScript   WaveLists:%s     %s \r", WaveList( "Dac_*", ";", "" ),  WaveList( "Adc_*", ";", "" ); Out( bf )
			sprintf bf, "\tLOADING  IS  DONE... \r"; 	Out( bf )
			EnableButton( "PnPuls", "buApplyScript",		kENABLE )	// 030801allow  'Apply'  to check for errors if script is loaded no matter whether it contains errors or not
			EnableSetVar( "PnPuls", "root_uf_aco_keep_gnProts", TRUE )	// ..allow also changing the number of protocols ( which triggers 'ApplyScript()'  )
			EnableButton( "PnPuls", "buStart", 			kENABLE )	// ..now allow to go into acquisition  after script loading has been completed
			EnableButton( "PnPuls", "buDisplayStimDlg", 	kENABLE )	// ..now allow to display a stimulus after wE and wFixSwp..  have been set 
			EnableButton( "PnPuls", "buAcqWindowsDlg", 	kENABLE )	// ..now allow to build the panel after a script is loaded and 'wIO' is built for 'lstTitleTraces()'
			EnableButton( "PnPuls", "buAnalysisAcqDlg", 	kENABLE )	// ..now allow to build this panel after a script is loaded and 'wIO' is built for 'ioChanList()'
			EnableButton( "PnPuls", "buOLAnalysisDlg", 	kENABLE )	// ..now allow to build this panel after a script is loaded and 'wIO' is built for 'ioChanList()'
			EnableButton( "PnPuls", "buGainDlg",			kENABLE )	// ..now allow to build the Gain panel after a script is loaded and 'wIO' is built for 'MakeSingleADList()'
		
			string  	sPnOptions	= ":dlg:tPnAcqWnd" 
			InitPanelDisplayOptionsAcq( sFolder, sPnOptions )				// constructs the text wave  'tPnAcqWn'  defining the panel controls
			UpdatePanel(  "PnAcqWin",  "Disp Acquisition" , sFolder, sPnOptions )	// redraw the 'Disp Acquisition' Panel as traces may have changed (same params as in  ConstructOrDisplayPanel1)

			sPnOptions			= ":dlg:tPnGain" 
			InitPanelGain( sFolder, sPnOptions )
			UpdatePanel(  "PanelGain", "Gain" , sFolder, sPnOptions )			// redraw the 'Gain' Panel as the telegraph connections may have changed (same params as in  ConstructOrDisplayPanel1)
	
			if ( bKeepOrNewAcqDisp )									// 060515a if the user changes only the number protocols while staying in the same script  it is not desired to switch back to the saved display configuration (in case the user modified the disp cfg in the meantime)
				LoadDisplayCfg_( sFolder, sFileName ) 
			endif
		else
			Alert( kERR_IMPORTANT,  "Bad script file  or  script was empty..." )
			DoWindow /K $sWin										// the StimDisp panel in FPULSE 
			DoWindow /K PnAcqWin
			// 040202 do NOT return an empty path for  'gsScriptPath'  even in case of error so that  the user can open and edit the script 
			rCode	= kERROR
		endif
		
		EnableButton( "PnPuls", "buSaveScript", 		kENABLE )			// allow saving the script whether the scripts contains errors or not...
		EnableButton( "PnPuls", "buSaveAsScript", 	kENABLE )			// ....because the user must have a chance to store the script after removing errors

  	endif

	return	sFileName												// can also be empty string  if user clicked Cancel
End 

Function		ApplyScript_( bKeepOrNewAcqDisp ) 
	variable	bKeepOrNewAcqDisp
	svar		gsScriptPath		= root:uf:aco:script:gsScriptPath
	string		sNoteBookName	= ksSCRIPT_NB_WNDNAME 			// = 'Script'	
	string		sTmpScriptPath		= ksSCRIPTS_DRIVE + ksSCRIPTS_DIR + ksTMP_DIR + ksDIRSEP + StripPathAndExtension( gsScriptPath ) + ".txt" 	// 'C:UserIgor:Scripts:Tmp:XYZ.txt'
	if ( WinType( sNoteBookName ) == kNOTEBOOK )					// window exists and is a notebook
		SaveNoteBook  /O /S=2	$sNoteBookName  as  sTmpScriptPath	// save any changes the user may have made  in a temporary script....
	endif														// ...(leave the original script unchanged)....
	// printf "\t\tApplyScript() \t\t\tgsScriptPath: '%s' .\tSaving as and reloading script/NB  '%s' \r", gsScriptPath,  sTmpScriptPath 
	variable	rCode
	LoadScript_( sTmpScriptPath, rCode, bKeepOrNewAcqDisp )						// ...and pass the valid temporary script path to load the script without opening the FileOpenDialog
End															// ...do not change 'gsScriptPath'


static Function	/S	stReadScript( sFolder, sFilePath )
// Reads  script file XXX.txt .   Data must be delimited by CR, LF or both.  Removes comments starting with  // 
// Removes any whitespaces ( Blanks, tabs, CR, LF ). Packs stripped data into text wave 'wLine'
// if ksDIRSEP == "\\" windows style the Macintosh style ":" returned by IGOR must here be converted. Cave: C:MacFolder-> C:\Winfolder
	string		sFolder, sFilePath								// can be empty ...
	variable	nRefNum, nLine = 0, len1
	string		sLine		= ""
	string	  	sScript	= ""

	Open /Z=2 /R /P=symbPath  nRefNum  as sFilePath		// /Z = 2: opens dialog box  if file is missing,  /Z = 1: no dialog / does nothing if file is missing
 	// PathInfo /S symbPath;  printf "\t\tReadScriptFile(): Receives '%s'   Symbolic path '%s' does %s exist.  Has opened :'%s'  (RefNum:%d)  \r",sFilePath, S_path, SelectString( v_Flag,  "NOT", "" ), s_FileName, nRefNum 	

	if ( nRefNum != 0 )								//  2 failure modes: script file missing  or  user cancelled file open dialog
		// Read original script (keeping comments and empty lines) into string  'sScript'  to be displayed as a text notebook which the user may view and/or edit. and save.
		do 										
			FReadLine nRefNum, sLine				// For the notebook  comments  and  empty lines  are kept..
			len1  = strlen( sLine )						// Empty lines contain CR or LF: their length is > 0...
			sScript += sLine 
		while ( len1 > 0 )     							//...is not yet end of file EOF
		Close nRefNum								// Close the script file... but reopen as a Notebook  below....

		variable	nRawLines = ItemsInList( sScript, "\r" )
		// printf "\t\tReadScript(   \t'%s', '%s' ) len:%3d, lines:%2d \r", sFolder, sFilePath, strlen( sScript ), nRawLines

		// Display the script as a notebook
		nvar		bShowScript	= $ksROOTUF_+sFolder+":dlg:gbShowScript"	
		ConstructOrUpdateNotebook( bShowScript, sFolder , ":script" , ksSCRIPT_NB_WNDNAME, sScript )	// 041013

	else
		Alert( kERR_FATAL,  "Could not open '" + sFilePath + "' " )	
	endif
	// printf "\t\tReadScript() was asked to open and opened  sFilePath   '%s' \r", sFilePath
	return	sScript
End

Function	/S	CompactScript( sFolder, sRawScript )
// Discard    empty lines  and  comments  from script string  for the stimulus extraction.  Fills  globals  gsScript  and  gsCoScript
	string  	sFolder, sRawScript

	variable	n, nRawLines	= ItemsInList( sRawScript, "\r" )
	variable	nLine	= 0
	string  	sLine	, sCompactScript	= ""		
	for ( n = 0; n < nRawLines; n += 1 )
		sLine	= StringFromList( n, sRawScript, "\r" )
		sLine = RemoveComment( sLine,  "//" )				// remove all comments  starting with ' // ' 
		sLine = RemoveWhiteSpace( sLine )			
		if ( strlen( sLine ) )
			sCompactScript	+= sLine + "\r"		
			// printf "\t\tCompactScript( \t'%s' ) n%2d, '%s' \r", sFolder, nLine, sLine
			nLine += 1
		endif
	endfor
	// printf "\t\tCompactScript( \t'%s' ) len:%3d, lines:%2d	-> CompactedLines:%2d \r", sFolder, strlen( sRawScript ), nRawLines, nLine

	string	  /G	$ksROOTUF_ + sFolder + ":gsScript"      = sRawScript	// Keep the original wave including comments and empty lines...
													// ...for the script notebook and for storing it in the acquisition data file   
	string	  /G	$ksROOTUF_ + sFolder + ":gsCoScript" = sCompactScript	// Keep compacted  wave without comments and empty lines...
													// ...for the stimulus generation

//if (  !  bNEWSCRIPT )
	variable	nCoLines		= ItemsInList( sCompactScript, "\r" ) 		// or  nLines()  (valid after wLine has been set)
	make /O /T /N=(nCoLines)  $ksROOTUF_ + sFolder + ":keep:wLines"	
	for ( n = 0; n < nCoLines; n += 1 )
		SetScrLine( sFolder, n, StringFromList( n, sCompactScript, "\r" ) ) 	// sets wLine		
	endfor
//endif
	wave  /T	wLines	= $ksROOTUF_ + sFolder + ":keep:wLines"
	svar		gsCoScript	= $ksROOTUF_ + sFolder + ":gsCoScript"
if(  ItemsInList( gsCoScript, "\r" )  != numpnts( wLines )  ) 
	printf "INTERNAL ERROR\t\tCompactScript()  nLines at start neu: %d    alt:%d \r",  ItemsInList( gsCoScript, "\r" ) , numpnts( wLines ) 
endif
	return	sCompactScript
End

//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Note 060915 : The following functions  should be   but  are  unfortunately NOT generally useful  as  the folder  'ksEVAL'  is used.
// Todo : Generalise by keeping the main code by moving  ksEVAL  outside.  Then move the generic function to  FP_Notebooks.ipf !

static constant		YFREELO_FOR_SB_AND_CMDWND	= 140	// points
static constant		YNAMELINE						= 20		// points

Function		GetDefaultScriptOrStimWndLoc( sFolder,  bScriptOrStim, xl, yt, xr, yb ) 
// Compute a largely arbitrary window location and return the coordinates as parameters. nOfsX, nOfsY can be used to specify  TopRight  or  MidLeft etc...
	string  	sFolder
	variable	bScriptOrStim
	variable	&xl, &yt, &xr, &yb													// 	parameters changed by function
	variable	nOfsX = 0, nOfsY = 0
	if ( cmpstr( sFolder, ksfEVO ) == 0 )								// the script windows in  FPULSE  and in  Eval  are offset a bit... 
		nOfsX += 10											//...so that they don't cover each other completely  
		nOfsY += 20
	endif
	variable	rxMinPoints, rxMaxPoints, ryMinPoints, ryMaxPoints 						// ...compute default position 
	GetIgorAppPoints( rxMinPoints, rxMaxPoints, ryMinPoints, ryMaxPoints )					// 	parameters changed by function
	variable	 UsableYPoints = ryMaxPoints - ryMinPoints - YFREELO_FOR_SB_AND_CMDWND
	// or : if ( cmpstr( sSubFolder, ":stim" ) )
	if ( bScriptOrStim == kSTIM )												
		xl = 2  + nOfsX														// The upper screen half... 
		yt = kIGOR_YMIN_WNDLOC + nOfsY										// ...is for the stimulus graph
		xr = rxMaxPoints / 2  + nOfsX; 
		yb = kIGOR_YMIN_WNDLOC + UsableYPoints / 2+ nOfsY						
	elseif ( bScriptOrStim == kSCRIPT )
		xl = 2  + nOfsX														// The lower screen half...
		yt = kIGOR_YMIN_WNDLOC + UsableYPoints / 2 + YNAMELINE + nOfsY			// ...is for the script text
		xr = rxMaxPoints / 2  + nOfsX; 
		yb = kIGOR_YMIN_WNDLOC + UsableYPoints + YNAMELINE + nOfsY	
	endif
End

// 060915
Function		ConstructOrUpdateNotebook( bShow, sFolder, sSubFolder, sNoteBookWndNm, sText )
// Called  with  'nextFile' , 'PrevFile'  
	variable	bShow
	string  	sFolder, sSubFolder, sNoteBookWndNm, sText
	if (  WinType( sNoteBookWndNm ) != kNOTEBOOK )							// Only if the Notebook window does not  exist.. 
		variable	xl, yt, xr, yb
		GetDefaultScriptOrStimWndLoc( sFolder, kSCRIPT, xl, yt, xr, yb ) 				// 	parameters changed by function
		StoreWndLoc( sFolder + sSubFolder, xl, yt, xr, yb )
		NewNotebook  /F=0	/K=2  /V=(bShow) /W=(xl, yt, xr, yb)  /N=$sNoteBookWndNm // open visibly or invisibly (avoid flicker)   AND  disable the window close button
		Notebook	$sNoteBookWndNm   text = sText
		if ( ! bShow )
// Igor5 syntax, Igor 6 has  SetWindow $sNB, hide = 0/1
			MoveWindow 	/W=$sNoteBookWndNm   0 , 0 , 0 , 0					// hide the window by minimising it (even if it was invisible)  as  'DisplayHideNotebook'  depends on the minimised state
 		endif
	else
		Notebook 	$sNoteBookWndNm, selection={ startOfFile, endOfFile }			// Replacing the text is a bit cumbersome : Select the whole text...
		DoIgorMenu "Edit", "Paste"										// ...and replace it by invoking the Paste command from the Edit menu...
		Notebook	$sNoteBookWndNm , text = sText							// ...by the new file's extracted script text
		Notebook 	$sNoteBookWndNm,  selection={ (0,0) , (0,0 ) }					// To set the cursor at the beginning of the text  we must select the position...
		Notebook	$sNoteBookWndNm , text = ""								// ..in front of the first character and insert nothing (dummy operation)
	endif	
End

Function		DisplayHideNotebook( bShow, sFolder, sSubFolder, sNoteBookWndNm, sText )
// Called  when the  Show/Hide checkbox is changed
	variable	bShow
	string  	sFolder, sSubFolder, sNoteBookWndNm, sText
	variable	xl, yt, xr, yb
	if (  WinType( sNoteBookWndNm ) != kNOTEBOOK )							// Only if the Notebook window does not  exist.. 
		printf "++Internal error: Notebook '%s'  should  but does not exist. (DisplayHideNotebookText)\r", sNoteBookWndNm	// the user may have brutally killed it by having pressed 'Close' multiple times 
		ConstructOrUpdateNotebook( bShow, sFolder, sSubFolder, sNoteBookWndNm, sText )
	else
	
// Igor5 syntax, Igor 6 has  SetWindow $sNB, hide = 0/1
//		variable	bIsMinimized	=  IsMinimized( sNoteBookWndNm, xl, yt, xr, yb )		// also gets the current window coordinates (which are only useful if the windows was not minimised)
//		if ( bShow  &&  bIsMinimized )										// User wants to restore the minimized window ( x..y are dummies)
//			RetrieveWndLoc( sFolder + sSubFolder, xl, yt, xr, yb )					// parameters changed by function
//			MoveWindow 	/W=$sNoteBookWndNm   xl, yt, xr, yb
//		elseif ( ! bShow  &&  ! bIsMinimized )									// User wants to hide the visible window : minimize it (x..y are used)
//			StoreWndLoc( sFolder + sSubFolder, xl, yt, xr, yb )					// ...save the existing windows coordinates so they can be restored
//			MoveWindow 	/W=$sNoteBookWndNm   0 , 0 , 0 , 0					// hide window by minimizing it
//		endif
// Igor6
		GetWindow $sNoteBookWndNm, hide 
		variable	bIsHidden	= V_Value
		if ( bShow  &&  bIsHidden )												// User wants to restore the hidden window 
			SetWindow $sNoteBookWndNm, hide = 0	
			DoWindow /F $sNoteBookWndNm	
		elseif ( ! bShow  &&  ! bIsHidden )										// User wants to hide the visible window 
			SetWindow $sNoteBookWndNm, hide = 1
		endif

	endif
End




