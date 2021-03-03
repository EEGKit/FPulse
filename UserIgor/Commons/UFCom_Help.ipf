//
//  UFCom_Help.ipf 
// 
#pragma rtGlobals=1							// Use modern global access method.

//#pragma IndependentModule=UFCom_
#include "UFCom_Constants"

//  HELP FILES / CHECKING LINKS
// This example uses the topic[subtopic] form.
// DisplayHelpTopic "Waves[Waveform Arithmetic and Assignment]"
//	Checking Links	chapter 1 volume II-18
//	You can get Igor to check your links as follows:
//	1. Open your Igor help file and any other help files that you link to.
//	2. Activate your help window and click at the very start of the help text.
//	3. Press Ctrl+Shift+Alt+H (Windows ). Igor will check your links from where you clicked to the 
//	    end of the file and note any problems by writing diagnostics to the history area of the command window.
//	4. When Igor finishes checking, if it found bad links, kill the help file and open it as a notebook.
//	5. Use the diagnostics that Igor has written in the history to find and fix any link errors.
//	6. Save the notebook and kill it.
//	7. Open the notebook as a help file. Igor will compile it.
//	8. Repeat the check by going back to step 1 until you have no bad links.
//
//	You can abort the check by pressing command-period ) or Ctrl-Break ) and holding it for a second.
//	The diagnostic that Igor writes to the history in case of a bad link is in the form:
//		Notebook $nb selection={(33,292), (33,334)} …
//	This is set up so that you can execute it to find the bad link. At this point, you have opened
//	the help file as a notebook. Assuming that it is named Notebook0, execute
//		string /G nb = "Notebook0"
//	Now, you can execute the diagnostic commands to find the bad link and activate the notebook.
//	Fix the bad link and then proceed to the next diagnostic. It is best to do this in reverse order, 
//		starting with the last diagnostic and cutting it from the history when you have fixed the problem.
//	When fixing a bad link, check the following:
//		A link is the name of a topic or subtopic in a currently open help file. Check spelling.
//		There are no extraneous blue/underlined characters, such as tabs or spaces, before or after the link. 
//		(You can not identify the text format of spaces and tabs by looking at them. 
//		Check them by selecting them and then using the Set Text Format dialog.)
//		There are no duplicate topics. If you specify a link in topic[subtopic] form and there
//		are two topics with the same topic name, Igor may not find the subtopic.
 
// todo:	make a backup of the help file just in case the user inadvertently deletes the help file instead of killing the help window
//		cosmetics: auto-remove the subtopic marker dot and blank   '. '
//		cosmetics: button for compiling 
//		cosmetics: button for checking the help links
//		make it work with Igor5

//to do   însert 'ToManual' entries automatically

// My  HELP CYCLE
//		Edit the help entries in the panel (the last column).  These will be the subtopics.
//		Insert the  EditHelp and SaveHelp  buttons in the panel  to which help is to be added
//		Press   EditHelp   and edit the help notebook
//		Save the help notebook by pressing    SaveHelp   or    save the entire experiment
//		Kill the help notebook by pressing the window close button [X ]
//		Open the notebook as a read-only help file.  Igor will compile it.
//		Press Ctrl+Shift+Alt+H (Windows ). Igor will check your links from where you clicked to the 
//			end of the file and note any problems by writing diagnostics to the history area of the command window.
//		Check that  CTRL left clicking   and/or   ALT and/or right clicking on a panel control jumps to the appropriate help subtopic.
//		Kill the help notebook by pressing the close box and ALT.
//		Open the notebook as a read-only help file.  Igor will compile it.
//		Press  the  EditHelp  button  again to open the editable help file and make your changes. 







Function		UFCom_PnUserWantsHelp( sWin, sCtrlname, nEventCode, sEventName, nEventMod, nControlType, bCbChecked, sHelpTopic )
	string  	sWin, sCtrlname, sEventName, sHelpTopic
	variable	nEventCode, nEventMod, nControlType, bCbChecked
	variable	bWantsHelp
	// EventModifiers:     LM1   LmShift3    LmAlt5    LmCtrl9           RM16    RmShift18    RmAlt4 (should be 20)   RmCtrl24
 	bWantsHelp = ( nEventMod != 0  &&  nEventMod != 1 ) 		// Anything but left mouse button, e.g. right mouse button or left mouse and  ALT, CTRL or SHIFT.  Could be changed to more specific help calling e,g, only  RM o r onyl RM+Shift.
	// printf "\tUFCom_PnUserWantsHelp\t%s\t%s\t\t\t\t\t\t\t\t\t\tevCo:%2d\t%s\tevMo:%2d\tbWantsHelp:%2d\tCType:%2d  (%s)\tbCbChecked:%2d\tHT:'%s'\r", sWin, UFCom_pd(sCtrlName,28), nEventCode, UFCom_pd( sEventName, 8 ), nEventMod, bWantsHelp, nControlType, StringFromList( nControlType, UFCom_kCI_lstCONTROLTYPES ), bCbChecked,  sHelpTopic
	if ( bWantsHelp )
		if (  nControlType == UFCom_kCI_CHECKBOX )
			Checkbox $sCtrlName, win=$sWin , value = !bCbChecked	// as Igor inverts  the checkbox state even in the 'help' mode we must invert it a second time to restore the original state
		endif
		UFCom_FDisplayHelpTopic( sHelpTopic )
	endif
	return	bWantsHelp
End


Function 		UFCom_FDisplayHelpTopic( sHelpTopic )
// displays help topic but avoids error msg box when help topic is not found (prints warning instead)
        string 	sHelpTopic

//  Igor5  jumps into Debugger if helptopic is not found
//        variable 	prevErr	  = GetRTError( 0 )			// make sure that there is no error pending...
//        DisplayHelpTopic /K=1 sHelpTopic
//	string  	sRTErrMsg  = GetRTErrMessage()
//        variable	err		  = GetRTError( prevErr == 0 )	 // clear error (by passing 1) only if it was caused by DisplayHelpTopic call.
//	if ( err )
//		// UFCom_Alert(  UFCom_kERR_LESS_IMPORTANT, StringFromList( 0, GetRTErrMessage() ) + " could not find the help topic  '" + sHelpTopic + "'  in any of the help files." )
//		printf "Warn(err:%d) : %s could not find the help topic  '%s'  in any of the help files.  \r",  err, StringFromList( 0, sRTErrMsg ), sHelpTopic
//		// InternalWarning( StringFromList( 0, GetRTErrMessage() ) + " could not find the help topic  '" + sHelpTopic + "'  in any of the help files." )
//		// InternalError( "Help topic '" + sHelpTopic + "' not found by " + StringFromList( 0, GetRTErrMessage() ) )
// 	endif
//	return err

//  Igor6  just prints warning if helptopic is not found
        DisplayHelpTopic /Z /K=1 sHelpTopic
	if ( V_flag )
		UFCom_Alert(  UFCom_kERR_LESS_IMPORTANT, " Could not find the help topic  '" + sHelpTopic + "'  in any of the help files." )
 	endif
	return V_flag

End


static strconstant  	ksTOPIC_MARKER		= "\r•\t"						// Igors Topic convention assumes the bullet character followed by a tabulator.  
																// The leading CR is not necessarily required in all help files but in mine I use it to make Topic detection more reliable

Function		UFCom_HelpSave( sNB, sHelpPathFile )
	string  	sNB, sHelpPathFile										
	if (  WinType( sNB ) == UFCom_WT_NOTEBOOK )						// Only if the Notebook window exists.. 

		// First save a copy of the help file in a BAK subdirectory. This copy is time-stamped so it will never be overwritten. Drawback: Help bak files accumulate which the user should delete from time to time.
		string  	sFilePath		= UFCom_FilePathOnly( sHelpPathFile )
		string  	sFileName		= UFCom_FileNameOnly( sHelpPathFile )
		string  	sFileExt		= UFCom_FileExtension( sHelpPathFile )
		string  	sBakDir		= sFilePath + "Bak" + ":"
		string  	sBakFilePath	= sBakDir + sFileName + UFCom_TimeStamp1Min() + sFileExt	// e.g. 'C:UserIgor:SecuCheck:SecuCheck.ihf'  ->  'C:UserIgor:SecuCheck:Bak:SecuCheck060315_1503.ihf'  
		UFCom_PossiblyCreatePath( sBakDir )
		SaveNotebook /S=2 /O 	$sNB  	as sBakFilePath 	
		// print sHelpPathFile, sFilePath, sFileName, sBakDir, "->", sBakFilePath
		// After having saved the BAK file we save the original file.  Saving in this order maintains the original file name, saving in reversed order would keep the Bak notebook open for editing...
		SaveNotebook /S=2 /O 	$sNB  	as sHelpPathFile 				
	else
		Beep; printf "Warning : Cannot save HelpPathFile '%s'  as Notebook '%s'  is not open. \r",  sHelpPathFile, sNB
	endif
End


Function	/S	UFCom_FindSubTopics( sNB, sHelpPathFile )
	string  	sNB, sHelpPathFile

	variable	refnum
	string  	sSubtopic = "", lstSubtopics = ""

	if ( UFCom_FileExists( sHelpPathFile ) )									// ...check if the notebook file exists
		Open 	/R refnum	as sHelpPathFile
		FStatus	refnum
		variable	n, nBytes	= V_logEOF
		make	/O /N=(nBytes) /U /B	wTmp
		FBinRead  /F=1 /U  refnum, wTmp
		Close	refnum

		variable	p, pos, len, cnt = 0
		for ( n = 0; n < nBytes - 4; n += 1 )
			//if (	wTmp[n]==0x24  &&  wTmp[n+1]==0  &&  wTmp[n+2]==0x14  &&  wTmp[n+3]==0 )  // the empirically determined subtopic marker is 0x24 0x00 0x14 0x00
			//if ( 	wTmp[n]==0x12  &&  wTmp[n+1]==0  &&  wTmp[n+2]==0x14  &&  wTmp[n+3]==0 )  // bold : 	 the empirically determined subtopic marker is 0x12 0x00 0x14 0x00
			//if ( 	wTmp[n]==0x00  &&  wTmp[n+1]==0  &&  wTmp[n+2]==0x16  &&  wTmp[n+3]==0 )  // not bold: the empirically determined subtopic marker is 0x00 0x00 0x14 0x00
			if (  ( ( wTmp[n]==0x00  && wTmp[n+2]==0x16 )  ||  ( wTmp[n]==0x12  && wTmp[n+2]==0x14 ) )   &&  wTmp[n+1]==0   &&  wTmp[n+3]==0 )  // not bold: the empirically determined subtopic marker is 0x12 0x00 0x14 0x00
				cnt += 1
				pos	= n + 4
				len	= -1 + wTmp[n-2] // + 256 *  wTmp[n-1]  ???

				sSubtopic = ""
				for ( p = pos; p < pos + len; p += 1 )
					sSubTopic	 += num2char( wTmp[p] )
				endfor

				//printf "\t\t\tFindSubTopics() \tn:%5d\t/%6d\tCnt:%4d\pos:%5d\tlen:%3d\t'%s'  \t   \r", n, nBytes, cnt, pos, len, sSubtopic
				lstSubtopics	= AddListItem( sSubtopic, lstSubtopics, ";", inf )
			endif
		endfor
	endif
	// printf "\r\t\tFindSubTopics(): \t%3d\t'%s' \r", ItemsInList( lstSubTopics ), UFCom_BegEnd( lstSubTopics, 110 )
	return	lstSubtopics
End


Function		UFCom_HelpEdit( sBaseFolder, sNB, sHelpPathFile, sPanel, sMainTopic )
// Open help file as editable notebook ( just for the programmer in development/debug mode )
// Unfortunately this is not completely automatic: The user must manually delete the help file  by pressing  ALT and the window Close button.  It would be more elegant if this closing could be done programmatically... 	
	string  	sBaseFolder, sNB, sHelpPathFile							// the help file is assumed to reside in the same directory as the Igor Procedure Files e.g. 'C:UserIgor:FPulse:FPulseHelp.ihf'
	string  	sPanel, sMainTopic
	string  	lstSubTopics	= ""

	if (  WinType( sNB ) != UFCom_WT_NOTEBOOK )					// Only if the Notebook window does not  exist.. 

		if ( UFCom_FileExists( sHelpPathFile ) )							// ...check if the notebook file exists

			OpenNotebook /Z /K=1 	/N =	$sNB	as sHelpPathFile 	// try to open notebook quietly as the notebook file may exist as a non-editable compiled help file which we cannot use

			if ( V_Flag )										// there was an error although the notebook file exists, probably because the notebook exists as a non-editable compiled help file
				DoAlert 0, "You first must kill the Help window \r      '" + sHelpPathFile + "'\rby pressing [ALT + Close Button]. \rThen try 'Edit Help' again"

				// It would be more elegant but I don't know how to  switch  programmatically from the non-editable compiled help file to the  editable notebook file which I need 

				// todo:  make a backup of the help file just in case the user inadvertently deletes the help file instead of killing the help window
				return -1

			endif

		else													// notebook file does not exist
			// works only in Igor6
			OpenNotebook /K=1 /N =	$sNB /P=Igor /T=".ifn" as 	":More Help Files:Igor Help File Template.ifn" 	// use Igors Template as a starting point only the first time before the NB has been saved
			SaveNotebook /S=2 /O 	$sNB  		as sHelpPathFile 	// e.g. 'C:UserIgor:SecuCheck:SecuCheck.ihf'
		endif	

	endif
		
	// Search for SubTopics in the help file.  
	lstSubTopics	= UFCom_FindSubTopics( sNB, sHelpPathFile )

	// Construct a list of all Topics and Subtopics found in the Help notebook  and compare against the Topics extracted from the panel.
	// When both lists differ then remind the programmers to update the Help notebook.
	Notebook 	$sNB	selection = {startOfFile, endOfFile}	// select all text in notebook
	GetSelection  notebook, $sNB, 2
	string  	sAllText	= "\r" + S_selection				// To recognise a Topic there must be an empty line just before the bullet. Insert a missing dummy CR before the first line so that the first bullet is not forgotten. 
	variable	nPos, len	= strlen( sAllText )
	Notebook 	$sNB 	selection = {endOfFile, endOfFile}	// move selection to the end of the notebook
	// print "fEditHelp() NBText: ", S_selection

	// Search for Main Topics in the help file. This is easy as we know that they start with a bullet character followed by a tab.
	string  	sTopic, lstTopics	= ""
	nPos		= -1
	do
		nPos 	+= 1
		nPos	= strsearch( sAllText, ksTOPIC_MARKER, nPos )				
		if ( nPos != UFCom_kNOTFOUND )											// eliminate again the last item which has NOT been correctly found
			sTopic	= StringFromList( 0, sAllText[ nPos+strlen(ksTOPIC_MARKER), inf ], "\r" )		// extract till end of line
			lstTopics	= AddListItem( sTopic, lstTopics, ";", inf )
			// printf "\t\t\tTopic: \tPos:\t%8d\tlen:\t%8d\t'%s' \r", nPos, len, sTopic
		endif
	while ( nPos != UFCom_kNOTFOUND )
	

	// Add the one and only main topic  and  all subtopics (as found in the panel)  to the help file  if they are not yet contained in the help file.
	// Step1: Extract all potential subtopics from the panel.  As the user may select any of them for help each ot these should finally contain some help text.
	 printf "\t\t\r"
	string  	lstHelpTopics	= UFCom_Panel2Helptopics( sBaseFolder, sPanel )
	variable	n, nHelpTopics	= ItemsInList( lstHelpTopics )
	string  	sHelpTopic

	Notebook	$sNB,  selection	= { endOfFile, endOfFile }		// Anything to be added will be appended  at the end of the notebook 

	// Possibly add the one and only main topic
	if ( WhichListItem( sMainTopic, lstTopics ) == UFCom_kNOTFOUND )
		NBTopicAppend( sNB, sMainTopic )
	endif

	for ( n = 0; n < nHelpTopics; n += 1)
		sHelpTopic	= StringFromList( n, lstHelpTopics )

		// Tests formating by appending various topis and subtopics
		//	string  	sTopicBody	= "TopicBody"
		//	if ( mod(n,5) == 0 )
		//		NBTopicAppend( sNB, sHelpTopic )
		//	elseif ( mod(n,5) == 1 )
		//		NBSubTopicAppend( sNB, sHelpTopic, "helptext" )
		//	elseif ( mod(n,5) == 2 )
		//		NBTopicBody( sNB, sTopicBody )
		//	elseif ( mod(n,5) == 3 )
		//		NBSeeAlso( sNB, sHelpTopic )
		//	elseif ( mod(n,5) == 4 )
		//		NBRelatedTopics( sNB, sHelpTopic )
		//	endif

		if ( WhichListItem( sHelpTopic, lstSubTopics ) == UFCom_kNOTFOUND )
			NBSubTopicAppend( sNB, sHelpTopic, "helptext" )		
		endif
	endfor

	// Step2: Extract all potential subtopics from the '_ToManual'  entries in the procedure files.  These contain help on  key combinations used in panels/panel hook functions.
	string  sAll = UFCom_HelpCollectToManual( sNB )
	
	variable s, nSubtopics	= ItemsInList( sAll, ksEND2MAN_SEP )
	for ( s = 0; s < nSubtopics; s += 1 )
		string  sSubtopicPlusText	= StringFromList( s, sAll, ksEND2MAN_SEP )
		string  sSubtopic		= StringFromList( 0, sSubtopicPlusText, "\r" )
		string  sSubtopicText		= RemoveListItem( 0, sSubtopicPlusText, "\r" )
		if ( WhichListItem( sSubtopic, lstSubTopics ) == UFCom_kNOTFOUND )
			NBSubTopicAppend( sNB, sSubtopic, sSubtopicText )		
		endif
		// print sSubtopic, sSubtopicText
	endfor

	// Debug Print only  STEP1 subtopics
	printf "\t\tTopics in file: \t\t%3d\t'%s' \r", ItemsInList( lstTopics ), UFCom_BegEnd( lstTopics, 120 )
	printf "\t\tSubTopics: \t\t%3d\t'%s' \r", ItemsInList( lstSubTopics ), UFCom_BegEnd( lstSubTopics, 120 )
	string  	lstSubTopicOrphans	= RemoveFromList( lstHelpTopics, lstSubTopics )				// exist in help file but not in panel: 	Have probably been renamed....
	printf "\t\tSubTopicOrphans:\t%3d\t'%s' \r", ItemsInList( lstSubTopicOrphans ), UFCom_BegEnd( lstSubTopicOrphans,120)
	string  	lstSubTopicsMissing	= RemoveFromList( lstSubTopics, lstHelpTopics )				// exist in Panel but not yet in help file:	Add in Help file
	printf "\t\tSubTopicsMissing:\t%3d\t'%s' \r", ItemsInList( lstSubTopicsMissing ), UFCom_BegEnd( lstSubTopicsMissing,120)

	UFCom_HelpSave( sNB, sHelpPathFile )
	
End


// Note: Although the Igor documentation warns NOT to mix the 'ruler' keyword with other  keywords I found out that Mixing the keywords is the only way to make it work understandably and reliably..... 

static Function		NBTopicAppend( sNB, sText )
	string  	sNB, sText
	Notebook	$sNB, 	ruler	= TopicBody,	 textRGB = (0,0,0),	fStyle = 0, 	text	= "\r" 							// LEADING EMPTY TOPIC BODY line must not be edited, must stay empty as it is used as a Topic delimiter/marker
	Notebook	$sNB, 	ruler	= Topic,		 textRGB = (0,0,0),	fStyle = 0,  text = "•\t",  fStyle = 1+4,	text	= sText  + "\r"	// TOPIC: bullet, bold + underlined
	Notebook	$sNB, 	ruler	= TopicBody,	 textRGB = (0,0,0),	fStyle = 0, 	text	= "\r" 							// trailing empty TOPIC BODY line
End

static Function		NBSubTopicAppend( sNB, sTitle, sText )
	string  	sNB, sTitle, sText
	Notebook  $sNB, 	ruler	= Subtopic,	 textRGB = (0,0,0),   	fStyle = 1+4, text	= sTitle + "\r" 	// SUBTOPIC: bold and underlined
	Notebook	$sNB, 	ruler	= TopicBody,	 textRGB = (0,0,0),	fStyle = 0,     text	= sText + "\r\r" 	// trailing TOPIC BODY line is to be filled : here starts the help text
End

static Function		NBTopicBody( sNB, sText )
	string  	sNB, sText
	Notebook	$sNB, 	ruler	= TopicBody,	 textRGB = (0,0,0),	fStyle = 0, 	text	= sText + "\r" 		// TOPIC BODY
End

static Function		NBSeeAlso( sNB, sText )
	string  	sNB, sText
	Notebook	$sNB, 					 textRGB = (0,0,0),   	fStyle = 0,	text = "See also:\t" 		// 
	Notebook	$sNB, 	ruler	= SeeAlso	,	 textRGB=(0,0,65535),fStyle = 4,	text = sText + "\r" 		// blue and underlined
End

static Function		NBRelatedTopics( sNB, sText )
	string  	sNB, sText
	Notebook	$sNB, 					 textRGB = (0,0,0),   	fStyle = 0,	text = "Related Topics:\t" 	// 
	Notebook	$sNB, 	ruler	= RelatedTopics,textRGB=(0,0,65535),fStyle = 4,	text = sText + "\r" 		//  blue and underlined
End


//===========================================================================================================================================================
// MINI HELP  USING  A  SIMPLE  TEXT FILE

Function		UFCom_GenericMiniHelp( sCtrlname, sHelpWnd, sHelpDir, sHelpFile )
	string  	sCtrlname, sHelpWnd, sHelpDir, sHelpFile
	nvar		bState		= $ReplaceString( "_", sCtrlname, ":" )				// the underlying button variable name is derived from the control name
	return	UFCom_GenericMiniHelp_( bState, sHelpWnd, sHelpDir, sHelpFile )
End

Function		UFCom_GenericMiniHelp_( bState, sHelpWnd, sHelpDir, sHelpFile )
	string  	sHelpWnd, sHelpDir, sHelpFile
	variable	bState
	if ( bState )
		// printf "\t\tUFCom_GenericMiniHelp . \tbState:%d,  Wnd: %s    Dir: %s    File: %s )  \r", bState, sHelpWnd, sHelpDir, sHelpFile
		if ( cmpstr( sHelpDir[ 0 ], ":" ) == 0 )
			UFCom_InternalError( "Could not locate file '" + sHelpFile + "' ." )
			return UFCom_kNOTFOUND								// ????This is the built-in procedure window or a packed procedure (not a standalone file)   OR  procedures are not compiled.
		endif
		
		string   sHelpPath = ParseFilePath( 1, sHelpDir, ":", 1,0 ) + sHelpFile		// Create path to the help file.
		 printf "\t\tUFCom_GenericMiniHelp ..\tbState:%d,  Wnd: %s    Dir: %s    File: %s ) \tHelp path: '%s' \r", bState, sHelpWnd, sHelpDir, sHelpFile, sHelpPath
	
		// 2009-06-24
		if ( ! UFCom_FileExists( sHelpPath ) )
			UFCom_Alert( UFCom_kERR_LESS_IMPORTANT,  "Help file does not exist and is created '" + sHelpPath + "' ." )
			UFCom_WriteTxtFile( sHelpPath, sHelpFile + "\r\r" )
		endif
		OpenNotebook	/K=1	/V=1	/N=$sHelpWnd   sHelpPath				// visible, could also use /P=MySymbpath...
	 	SetWindow	$sHelpWnd , hook( HelpText )      = fHookHelpText		// the processing in response to user actions in the notebook window : here a context menu to simplify saving the help file.

		MoveWindow /W=$sHelpWnd	1, 1, 1, 1							// restore from minimised to old size
	else
		if ( WinType( sHelpWnd ) == UFCom_WT_NOTEBOOK )
			MoveWindow /W=$sHelpWnd	0, 0, 0, 0						// minimise the Notebook  to an icon
		endif
	endif
	return	UFCom_kOK
End


Function 		fHookHelpText( s )
	struct	WMWinHookStruct &s
	
	string  	sNBWndNm	= s.winName		// the notebook name is also the file name
	// printf "\t\t\t\fHookHelpText  \t%s\tmX:%4d\tmY:%4d\t\t\tE:%2d\t%s   \tMod:%4d\tkey:%4d\t%s\t \r", s.winName, s.mouseLoc.h, s.mouseLoc.v, s.eventCode, UFCom_pd( StringFromList( s.eventCode, UFCom_WHK_lstWINHOOKCODES ), 8 ),  s.eventMod, s.keycode,sNBWndNm

	// Open a context menu on a right mouse click.....
	if (  s.eventCode == UFCom_WHK_mousedown   &&   s.eventMod == 16 )   		// right mouse

		PopupContextualMenu/C=( s.mouseLoc.h, s.mouseLoc.v ) "Save;"

		strswitch( S_selection )

			case "Save":
				 printf "\t\tSaving Help file '%s' \r", sNBWndNm
				SaveNotebook $sNBWndNm
				break;

		endswitch
		return	1							// 0 : allow Igor to do further processing (will open Igor's context menu) 
	endif
End


//===========================================================================================================================================================
//  EXTRACTING   ToManual / EndToManual  DIRECTIVES

strconstant 	ksTOMANUAL		= "//_ToManual_"
strconstant 	ksENDTOMANUAL	= "//_EndToManual"
strconstant	ksEND2MAN_SEP	= "^"

Function	/S		UFCom_HelpCollectToManual( sNB )
// Find all occurrences of  'sPattern'  e.g. '_ToManual'  in all source files of this project.  
	string  	sNB

	// Loop through all user functions and build a list of source file which contains them.  This is a complete path list of all functions.  Functions contained in the files but not called are included.
	string  	sUserFunction	  = ""
	string  	lstUserFunctions  = FunctionList( "*", ";", "KIND=10" )
	variable	n, nFuncs		  =  ItemsInList( lstUserFunctions )
	 printf "\t\tUFCom_HelpCollectToManual(a)    UsrFuncs: %3d,  [%s .... %s] \r", nFuncs,  lstUserFunctions[0,80], lstUserFunctions[ strlen(lstUserFunctions) - 80, inf ]
	string  	sFuncPath, lstFuncPaths	= ""
	for ( n = 0; n < nFuncs; n += 1 )
		sUserFunction	= StringFromList( n, lstUserFunctions )
		sFuncPath		= FunctionPath( sUserFunction )
		if ( WhichListItem( sFuncPath, lstFuncPaths ) == UFCom_kNOTFOUND )
			lstFuncPaths += sFuncPath + ";"
			// printf "\t\tUFCom_HelpCollectToManual(b)   Fnc:\t%s\tPath:\t%s\t Funcs: %3d,  [%s .... %s] \r", UFCom_pd(sUserFunction,24), UFCom_pd( sFuncPath,36), nFuncs,  lstUserFunctions[0,80], lstUserFunctions[ strlen(lstUserFunctions) - 80, inf ]
		endif
	endfor

	// 2007-0406 IGOR Bug ???  : 
	// On my machine  FunctionList( "*", ";", "KIND=10" )  returns (unused?)  function  'GetBrowserSelection()' for which  FunctionPath() returns EMPTY path
	// 2007-0406 Workaround for IGOR Bug ???  : Remove empty path
	lstFuncPaths	= ReplaceString( ";;" , lstFuncPaths , ";" )

	// Loop through all files and extract all lines containing 'sPattern'  e.g. 'UFCom_DebugVar' .   This also include occurrences in comment lines.
	// Build a string list of the extracted lines.
	string  	sGrep, lstGrepsNoComment = ""
	variable	nAllGreps = 0
	variable	pa, nPaths		  =  ItemsInList( lstFuncPaths )
	string  	sPath, sAll = ""	
	 printf "\t\tUFCom_HelpCollectToManual(c)    UsFncPaths: %2d,  [%s .... %s] \r", nPaths,  lstFuncPaths[0,80], lstFuncPaths[ strlen(lstFuncPaths) - 80, inf ]
	for ( pa = 0; pa < nPaths; pa += 1 )
		sPath	 =  StringFromList( pa, lstFuncPaths )	
		sAll		+= ExtractToManual( sNB, sPath )
		//  printf "******\t\tUFCom_HelpCollectToManual(Grep) \tPath: \t%3d /%3d\t'%s'\t'%s' \r%s\r", pa, nPaths, sPath, sNB, sAll 
	endfor
	return	sAll
End


static Function	/S	ExtractToManual( sNB, sFilePath )
// Reads  procedure  file  xxx.ipf.   Data must be delimited by CR, LF or both.  Removes comments starting with  // 
// Does  NOT remove  after // when in  Picture  or in  " string " 
// Returns number of removed 'debug print lines'
	string		sNB, sFilePath								// can be empty ...
	variable	nRefNum, nLine = 0
	string		sLine			= ""
	variable	bIsInToManual	= UFCom_FALSE
	string  	sBegToManual	= ksTOMANUAL  + sNB			// !!! Assumption
	string  	sEndToManual	= ksENDTOMANUAL
	variable	lenB	= strlen( sBegToManual )
	variable	lenE	= strlen( sEndToManual )
	string  	sAll	= ""//, sSubtopic	= ""
	
	Open /Z=2 /R	nRefNum  	   as	sFilePath					// /Z = 2: opens dialog box  if file is missing,  /Z = 1: no dialog / does nothing if file is missing
	if ( nRefNum != 0 )									// file could be missing  or  user cancelled file open dialog
		do 											// ..if  ReadPath was not an empty string
			FReadLine nRefNum, sLine
			if ( strlen( sLine ) == 0 )						// Only at file end the line length is 0 . Empty lines have line length 1 due to the CR
				break
			endif

			if ( ! bIsInToManual )
				if ( cmpstr( UFCom_RemoveLeadingWhiteSpace( sLine )[0, lenB-1] , sBegToManual ) == 0  )		
					sLine	 		= UFCom_RemoveLeadingWhiteSpace( ReplaceString( sBegToManual, sLine, "" ) )		
					bIsInToManual 	= UFCom_TRUE
				endif
			else
				if ( cmpstr( UFCom_RemoveLeadingWhiteSpace( sLine )[0, lenE-1] , sEndToManual ) == 0  )				
					bIsInToManual	= UFCom_FALSE
					sAll			+= ksEND2MAN_SEP
				else
//					sLine	 		= "\t" + UFCom_RemoveLeadingWhiteSpace( ReplaceString( "//", sLine, "" ) )		
					sLine	 		= UFCom_RemoveLeadingWhiteSpace( ReplaceString( "//", sLine, "" ) )		
				endif
			endif

			if ( bIsInToManual )
				// printf "\tExtractToManual() \tInMan:%d \t%s\t%s ",  bIsInToManual, UFCom_pd( sFilePath, 31), sLine
				sAll	+= sLine
			endif

			nLine += 1
		while ( UFCom_TRUE )     							//...is not yet end of file EOF
		Close nRefNum									// Close the input file
	else
		printf "++++Error: Could not open input file '%s' . (ExtractToManual) \r", sFilePath
	endif
//	 printf "\t\tExtractToManual() \tSrc:\t%s\t ->\t%s\t (Lines:%5d) .\tHas removed\t%4d\tdebug print lines \r", UFCom_pd(sFilePath,49) ,  UFCom_pd(sTgtPath,54), nLine, nRemovedDbg
	return	sAll
End

