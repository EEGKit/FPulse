//
// UFCom_MultiButtonAlert.ipf
//
// Author		Ulrich Fröbe, Physiological Institute, University Freiburg
// Revisions	2009-06-04 
//

// TAKEN  from  UFST_OTHERS.ipf     but  there are the same globals, which must be avoided..  SEE  MBA below  which works............


#pragma rtGlobals=1						// Use modern global access method.


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Function		UFCom_Input1String( sMainText, sText1, rsInput )
	string		sMainText, sText1
	string  	&rsInput
	string  	sUserInput1 = rsInput
	Prompt	sUserInput1,  sText1
	DoPrompt	sMainText , sUserInput1
	if ( ! V_flag ) 
		rsInput = sUserInput1							// user did not cancel  
	endif
	return	V_flag								// 1 parameter can be returned directly
End

//Function		UFCom_InputNumber( sTitle, sTxt )
//	string  	sTitle, sTxt
//	variable	nNumber
//	Prompt	nNumber,	sTitle
//	DoPrompt	sTxt, nNumber
//	if ( V_flag )
//		print "\t\tInputNumber( '%s'  '%s' ): \t\tuser cancelled, returning", sTitle, sTxt, nNumber
//		return	-1												// user cancelled : return a negative number which is considered invalid 
//	endif
//	return	nNumber
//End
//
//static constant	kCANCEL_ILLEGAL	= -1
//
//// gn		strconstant sFont	= "\"MS Outlook\""
//
//Function		UFCom_InputNumberInvisibly( sWNm, sTitle )
//// todo : pass limits / nDigits rather than fixed 0..9999, 4 digits
//// todo : autosize panel (and controls) according to title text etc...
//	string  	sTitle
//	string  	sWNm
////	string  	sWNm	= "UF_TheOnlyInputNumberInvisibly"
//
//// gn 	string  	sFont	= "MS Outlook"
//// gn		string  	sFont	= "\"MS Outlook\""
//	UFCom_PossiblyCreateFolder( "root:uf" )
//	string  /G 	root:uf:gUF_InvisibleString = "****"	// The number of is an indicator of how many digits must be input. The special font used converts them (and any other character) to rectangles which effectively hides the input
//	variable	nLines = 1, xLen = 60
//
//	variable	XPnButMargin	= 6
//	variable	XPnMargin	= 0
//	variable	YPnMargin	= 25
//	variable	YPnLineHt		= 10
//	variable	YPnButtonHt	= 20
//	
//	variable	XPnSize	= max( 200, XPnMargin + 3 * XPnButMargin + xLen )
//	variable	YPnSize	= YPnMargin + YPnLineHt * nLines + YPnButtonHt
//
//	variable	XPnPos	= 250
//	variable	YPnPos	= 150
//
//	if ( WinType( sWNm ) == UFCom_WT_PANEL )
//		KillWindow $sWNm
//	endif
//
//	NewPanel 	/W=( XPnPos, YPnPos, XPnPos+XPnSize, YPnPos+YPnSize+4 ) /K=2  /N=$sWNm  as  sTitle	// K=2  disables the dialog box Close button because the user MUST make a choice.
//	ModifyPanel	/W=$sWNm	fixedSize= 1			// the panel cannot be resized by the user adjusting the grow box or frame nor maximized  but the window can be minimized  -> which must be prevented in the hook function 
//	Button		buUF_InputNumberInvisiblyOK,		win = $sWNm, pos = {   8, 36 }, 	size = { 60, 16 },	     title = "OK", 		proc = UFCom_InvisibleNumberOKProc
//	Button		buUF_InputNumberInvisiblyCancel,	win = $sWNm, pos = {100, 36 }, 	size = { 60, 16 },	     title = "Cancel", 	proc = UFCom_InvisibleNumberCancelProc
//	SetVariable	svUF_InputNumberInvisibly, 		win = $sWNm, pos = { 20 , 10 }, 	bodyWidth =xLen,  title = " ",		proc = UFCom_InvisibleNumberProc,	value= root:uf:gUF_InvisibleString
//	SetVariable	svUF_InputNumberInvisibly, 		win = $sWNm, fSize = 18, font = "MS Outlook"	// "Marlett"	"MS Outlook"	"MT Extra"	"Code 128"	
//	ControlUpdate	 /W=$sWNm svUF_InputNumberInvisibly									// !!! in this order
//	SetVariable	svUF_InputNumberInvisibly, 		win = $sWNm,  activate					// !!! in this order
//
////	svar	gCode	= root:uf:gUF_InvisibleString
//
//	PauseForUser $sWNm											// Loops internally in Igor  until  the panel is removed  when any button (or ENTER in the SetVariable) has been pressed.  
//	
//	svar	gsInput	= root:uf:gUF_InvisibleString
//	variable	nNumber	= str2num( UFCom_RemoveOuterWhiteSpace( gsInput ) )
//	if ( numType( nNumber ) == UFCom_kNUMTYPE_NAN )
//		nNumber = kCANCEL_ILLEGAL
//	endif
//	// printf "\t\tInputNumberInvisibly( '%s' )  -> '%s'  -> returns %g \r",  sTitle,  gsInput, nNumber
//	return	nNumber
//End
//	
//Function	UFCom_InvisibleNumberProc( s )
//	struct	WMSetvariableAction 	&s
//	if ( s.eventcode == UFCom_SVE_EnterKey )	
//		KillWindow	$s.win				// this will terminate the above  'PauseForUser'  loop  and   InputNumberInvisibly()  will be exited  returning the user input
//	endif
//End
//
//Function	UFCom_InvisibleNumberOKProc( s )
//	struct	WMButtonAction 	&s
//	if (  UFCom_ButtonPressed( s ) ) 				// exclude the event which is triggered when just moving the mouse over the button. 
//		KillWindow	$s.win				// this will terminate the above  'PauseForUser'  loop  and   InputNumberInvisibly()  will be exited  returning the user input
//	endif
//End
//
//Function	UFCom_InvisibleNumberCancelProc( s )
//	struct	WMButtonAction 	&s
//	if (  UFCom_ButtonPressed( s ) ) 				// exclude the event which is triggered when just moving the mouse over the button. 
//
//printf "TODO: introduce folder to avoid collisions....."
//		svar	gsInput	= root:uf:gUF_InvisibleString
//		gsInput		= num2str( kCANCEL_ILLEGAL )
//		KillWindow	$s.win				// this will terminate the above  'PauseForUser'  loop  and   InputNumberInvisibly()  will be exited  returning the user input
//	endif
//End
//


//Function		UFCom_InputMultipleStrings( sTitle, lstText, rlstInput )
//// Displays simple dialog box for the entry of multiple strings 'rlstInput' which is passed back as reference
//	string  	sTitle, lstText
//	string  	&rlstInput
//	variable	n, nItems	= ItemsInList( lstText )
//	for ( n = 0; n < nItems; n += 1 )
//		string   /G	$"root:uf:var" + num2str( n ) = StringFromList( n, rlstInput ) 				// supply input field defaults 
//		svar		var	= $"root:uf:var" + num2str( n ) 
////		Prompt	var ,  StringFromList( n, lstText ) + " :"
//		Prompt	$"root:uf:var" + num2str( n )  ,  StringFromList( n, lstText ) + " :"
//	endfor
//	if ( n = 1 )
//		DoPrompt	sTitle, wtInput[ 0 ]
//	elseif( n == 2 )
//		DoPrompt	sTitle, wtInput[ 0 ], wtInput[ 1 ]
//	elseif( n == 3 )
//		DoPrompt	sTitle, wtInput[ 0 ], wtInput[ 1 ], wtInput[ 2 ]
//	elseif( n == 4 )
//		DoPrompt	sTitle, wtInput[ 0 ], wtInput[ 1 ], wtInput[ 2 ], wtInput[ 3 ]
//	elseif( n == 5 )
//		DoPrompt	sTitle, wtInput[ 0 ], wtInput[ 1 ], wtInput[ 2 ], wtInput[ 3 ], wtInput[ 4 ]
//	elseif( n == 6 )
//		DoPrompt	sTitle, wtInput[ 0 ], wtInput[ 1 ], wtInput[ 2 ], wtInput[ 3 ], wtInput[ 4 ], wtInput[ 5 ]
//	else
//		Beep; Beep; Beep; Beep; Beep; 
//		printf "Developer Error: Only 6 input strings allowed..."
//	endif
//
//	if ( V_flag )
//		return	-1			// user cancelled
//	endif
//	for ( n = 0; n < nItems; n += 1 )
//		rlstInput	= AddListItem( wtInput[ n ], rlstInput, ";", inf )
//	endfor
//	printf "\t\tInputMultipleStrings() \t'%s'  '%s'   returns  '%s'  \r", sTitle, lstText, rlstInput
//	return	UFCom_kOK
//End	

//Function		UFCom_InputMultipleStrings( sTitle, lstText, rlstInput )
//// Displays simple dialog box for the entry of multiple strings 'rlstInput' which is passed back as reference
//	string  	sTitle, lstText
//	string  	&rlstInput
//	variable	n, nItems	= ItemsInList( lstText )
//	make /O /T /N=(nItems)	root:uf:wtInput
//	wave /T wtInput	= root:uf:wtInput
//	for ( n = 0; n < nItems; n += 1 )
//		wtInput[ n ] 	= StringFromList( n, rlstInput ) 				// supply input field defaults 
//		Prompt	wtInput[ n ] ,	StringFromList( n, lstText ) + " :"
//	endfor
//	Prompt	sFullName,	"Full name: "
//	Prompt	sAddrInst,		"Address or Inst: "
//	if ( n = 1 )
//		DoPrompt	sTitle, wtInput[ 0 ]
//	elseif( n == 2 )
//		DoPrompt	sTitle, wtInput[ 0 ], wtInput[ 1 ]
//	elseif( n == 3 )
//		DoPrompt	sTitle, wtInput[ 0 ], wtInput[ 1 ], wtInput[ 2 ]
//	elseif( n == 4 )
//		DoPrompt	sTitle, wtInput[ 0 ], wtInput[ 1 ], wtInput[ 2 ], wtInput[ 3 ]
//	elseif( n == 5 )
//		DoPrompt	sTitle, wtInput[ 0 ], wtInput[ 1 ], wtInput[ 2 ], wtInput[ 3 ], wtInput[ 4 ]
//	elseif( n == 6 )
//		DoPrompt	sTitle, wtInput[ 0 ], wtInput[ 1 ], wtInput[ 2 ], wtInput[ 3 ], wtInput[ 4 ], wtInput[ 5 ]
//	else
//		Beep; Beep; Beep; Beep; Beep; 
//		printf "Developer Error: Only 6 input strings allowed..."
//	endif
//
//	if ( V_flag )
//		return	-1			// user cancelled
//	endif
//	for ( n = 0; n < nItems; n += 1 )
//		rlstInput	= AddListItem( wtInput[ n ], rlstInput, ";", inf )
//	endfor
//	printf "\t\tInputMultipleStrings() \t'%s'  '%s'   returns  '%s'  \r", sTitle, lstText, rlstInput
//	return	UFCom_kOK
//End	
	



Function		UFCom_MultiButtonAlert( sFo, sWNm, sTitle, sTxt, lstChoices, nDefault )
	string  	sTitle, sTxt, lstChoices
	string  	sFo, sWNm
	//string  	sWNm	= "UF_TheOnlyMultiButtonAlert"
	variable	nDefault
	string  	sLine	= "", sChoice = ""
	variable	l, nLines, xLineLen = 0
	variable	c, nChoices, xChoiceLen = 0

	sTxt		= RemoveEnding( sTxt, "\r" ) + "\r"			// ensure that there is exactly 1 trailing CR 
	nLines	= ItemsInList( sTxt, "\r" )
	nChoices	= ItemsInList( lstChoices )
	for ( l = 0; l < nLines; l += 1 )
		sLine		= StringFromList( l, sTxt, "\r" ) 
		xLineLen	= max( xLineLen, FontSizeStringWidth( "default", 10, 0, sLine ) )
	endfor
	for ( c = 0; c < nChoices; c += 1 )
		sChoice	 = StringFromList( c, lstChoices ) 
		xChoiceLen= max( xChoiceLen, 1.15 * FontSizeStringWidth( "default", 10, 1, sChoice ) )	// supply space for bold font, magic factor of 1.15 is still needed
	endfor
	variable	XPnButMargin	= 6
	variable	XPnMargin	= 0
	variable	XPnFactor		= 1.2
	variable	YPnMargin	= 25
	variable	YPnLineHt		= 10
	variable	YPnButtonHt	= 20
	
	variable	XPnSize	= XPnMargin + XPnFactor * ( max( xLineLen, nChoices * ( 3 * XPnButMargin + xChoiceLen ) ) )
	variable	YPnSize	= YPnMargin + YPnLineHt * nLines + YPnButtonHt

	variable	XPnPos	= 300
	variable	YPnPos	= 200

	if ( WinType( sWNm ) == UFCom_WT_PANEL )
		KillWindow $sWNm
	endif

	NewPanel 	/W=( XPnPos, YPnPos, XPnPos+XPnSize, YPnPos+YPnSize+4 ) /K=2  /N=$sWNm  as  sTitle	// K=2  disables the dialog box Close button because the user MUST make a choice.
	ModifyPanel	/W=$sWNm	fixedSize= 1							// the panel cannot be resized by the user adjusting the grow box or frame nor maximized  but the window can be minimized  -> which must be prevented in the hook function 
	SetWindow	$sWNm, 	hook( UF_MBA )	 = fHook_UFCom_MBA 		// prevent the user to accidentally minimize, maximize or resize the panel  (using a named window hook)
	SetWindow   	$sWNm,	UserData(sDefButNm) = "buMBA"+num2str( nDefault )	// make the default button accessible in the window hook function so that we can call the appropriate button action procedure if the user presses ENTER
	SetWindow   	$sWNm,	UserData( sFo ) 		 = sFo					// subfolder for the global selected button to avoid conflicts when this MultipleButtonAlert box  is used in different programs
	for ( l = 0; l < nLines; l += 1 )
		sLine		= StringFromList( l, sTxt, "\r" ) 
		DrawText 	    /W=$sWNm	XPnMargin+5, YPnMargin + l * YPnLineHt, sLine
	endfor
	for ( c = 0; c < nChoices; c += 1 )
		variable	xButPos	= XPnMargin + XPnButMargin + c * ( 3 * XPnButMargin + xChoiceLen )
		variable	yButPos	= YPnMargin +  nLines * YPnLineHt
		variable	nStyle	= c == nDefault  ?  1 :  0						// could be 0...7 : 1 is bold, 2 is italic , 4 is underline
		sChoice	= StringFromList( c, lstChoices ) 
		Button	$"buMBA"+num2str(c),  win=$sWNm,  pos={xButPos, yButPos},  size={xChoiceLen + 2 * XPnButMargin,  YPnButtonHt},  title=sChoice,  fStyle=nStyle,  proc=$"fUFCom_MBA"
	endfor

	UFCom_PossiblyCreateFolder( "root:uf:" + sFo )
	variable	/G	   $"root:uf:" + sFo + ":gMBA" = -1
	nvar	gCode	= $"root:uf:" + sFo + ":gMBA"

	PauseForUser $sWNm											// Loops internally in Igor  until  the panel is removed  when any button has been pressed.  
																// Pressing the button also stores the index of the button which is returned.  
	return	gCode
End

 	 
Function 		fHook_UFCom_MBA( s )
//  Disable the dialog box  Minimise button because the user MUST make a choice.  Disabling the Close button is easier to do and done in 'NewPanel' .
//  Also handle the case when the user presses ENTER to select the default button  
	struct	WMWinHookStruct	&s
	if ( s.eventcode == UFCom_WHK_resize )
		MoveWindow /W=$s.winname	1, 1, 1, 1								// prevent the user to minimize the panel by restoring the old size immediately
	endif
	if ( s.eventcode == UFCom_WHK_keyboard )
		if ( s.keycode == 13 )												// the Enter / CR key has been pressed
			// print "fHook_UF_MBA  Enter", GetUserData( s.winName, "", "sDefButNm" )
			struct	WMButtonAction  structBuAction
			structBuAction.eventcode	= UFCom_CCE_mouseup					// so that 'ButtonPressed()' is recognised
			structBuAction.ctrlname	= GetUserData( s.winName, "", "sDefButNm" ) 	// simulate pressing the default button 
			fUFCom_MBA( structBuAction )										// Call the button action procedure with the appropriate parameters...
		endif															//...just as if the user had indeed pressed the default button
	endif			
	return 0
End 

Function		fUFCom_MBA( s )
	struct	WMButtonAction  &s
	if (  UFCom_ButtonPressed( s ) )
		variable  		len  						= strlen( s.CtrlName )
		string  		sFo						= GetUserData( s.win, "", "sFo" ) 
		variable   /G    $"root:uf:" + sFo + ":gMBA"= str2num( (s.CtrlName)[ len-1, len-1] ) 	// !!! At most  10 buttons...
		nvar	gCode = $"root:uf:" + sFo + ":gMBA"  
		 print	"\tfUFCom_MBA(1)   sFo:", sFo, "s.CtrlName:", s.CtrlName, s.win, "->", gCode
		KillWindow	$s.win
	endif			
End

//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

