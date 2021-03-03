//
//  UFCom_Notebooks.ipf 
// 

#include "UFCom_Constants"

//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

// 2008-04-23  This code should be made obsolete.....  (used in Stim3.ipf  oldstyle)   and in EVAL

static constant		YFREELO_FOR_SB_AND_CMDWND	= 140	// points
static constant		YNAMELINE						= 20		// points

Function		UFCom_GetDefaultScrptStimWndLoc(  xl, yt, xr, yb, bSmallOs, bLowerHalf ) 
// Compute a largely arbitrary window location and return the coordinates as parameters. nOfsX, nOfsY can be used to specify  TopRight  or  MidLeft etc...
	variable	&xl, &yt, &xr, &yb													// 	parameters changed by function
	variable	bSmallOs, bLowerHalf
	variable	nOfsX	= 10 * bSmallOs											//...so that they don't cover each other completely  
	variable	nOfsY	= 20 * bSmallOs
	variable	rxMinPoints, rxMaxPoints, ryMinPoints, ryMaxPoints 						// ...compute default position 
	UFCom_GetIgorAppPoints( rxMinPoints, rxMaxPoints, ryMinPoints, ryMaxPoints )			// 	parameters changed by function
	variable	 UsableYPoints = ryMaxPoints - ryMinPoints - YFREELO_FOR_SB_AND_CMDWND
// 2008-07-24 too big
//	xl = 2  + nOfsX															// The upper screen half is for the stimulus graph, the lower half is for the script text. 
//	yt = UFCom_kIGOR_YMIN_WNDLOC + nOfsY				  + bLowerHalf * (UsableYPoints/2 + YNAMELINE)									
//	xr = rxMaxPoints / 2  + nOfsX; 
//	yb = UFCom_kIGOR_YMIN_WNDLOC + nOfsY+ UsableYPoints/2 + bLowerHalf * (UsableYPoints/2 + YNAMELINE)								
	xl = 2  + nOfsX															// The upper screen half is for the stimulus graph, the lower half is for the script text. 
	yt = UFCom_kIGOR_YMIN_WNDLOC + nOfsY				  + bLowerHalf * (UsableYPoints/2 + YNAMELINE)									
	xr = rxMaxPoints / 6  + nOfsX; 
	yb = UFCom_kIGOR_YMIN_WNDLOC + nOfsY+ UsableYPoints/4 + bLowerHalf * (UsableYPoints/2 + YNAMELINE)								
End

Function		UFCom_ConstructOrUpdateNotebook( bShow, sFolder, sSubFolder, sNoteBookWndNm, sText, bSmallOs, bLowerHalf  )
// Called  with  'nextFile' , 'PrevFile'  
	variable	bShow
	string  	sFolder, sSubFolder, sNoteBookWndNm, sText
	variable	bSmallOs, bLowerHalf
	if (  WinType( sNoteBookWndNm ) != UFCom_WT_NOTEBOOK )					// Only if the Notebook window does not  exist.. 
		variable	xl, yt, xr, yb
		UFCom_GetDefaultScrptStimWndLoc( xl, yt, xr, yb, bSmallOs, bLowerHalf ) 		// 	parameters changed by function
// only for Igor5
//		UFCom_StoreWndLoc( sFolder + sSubFolder, xl, yt, xr, yb )
		NewNotebook /F=0 /K=2 /V=(bShow) /W=(xl, yt, xr, yb)  /N=$sNoteBookWndNm	// open visibly or invisibly (avoid flicker)   AND  disable the window close button
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

Function		UFCom_DisplayHideNotebook( bShow, sFolder, sSubFolder, sNoteBookWndNm, sText, bSmallOs, bLowerHalf  )
// Called  when the  Show/Hide checkbox is changed
	variable	bShow
	string  	sFolder, sSubFolder, sNoteBookWndNm, sText
	variable	bSmallOs, bLowerHalf
	variable	xl, yt, xr, yb
	if (  WinType( sNoteBookWndNm ) != UFCom_WT_NOTEBOOK )						// Only if the Notebook window does not  exist.. 
		printf "++Internal error: Notebook '%s'  should  but does not exist. (DisplayHideNotebookText)\r", sNoteBookWndNm	// the user may have brutally killed it by having pressed 'Close' multiple times 
		UFCom_ConstructOrUpdateNotebook( bShow, sFolder, sSubFolder, sNoteBookWndNm, sText, bSmallOs, bLowerHalf  )
	else
// Igor5
//		variable	bIsMinimized	= UFCom_IsMinimized( sNoteBookWndNm, xl, yt, xr, yb )	// also gets the current window coordinates (which are only useful if the windows was not minimised)
//		if ( bShow  &&  bIsMinimized )											// User wants to restore the minimized window ( x..y are dummies)
//			UFCom_RetrieveWndLoc( sFolder + sSubFolder, xl, yt, xr, yb )				// parameters changed by function
//			MoveWindow 	/W=$sNoteBookWndNm   xl, yt, xr, yb
//		elseif ( ! bShow  &&  ! bIsMinimized )										// User wants to hide the visible window : minimize it (x..y are used)
//			UFCom_StoreWndLoc( sFolder + sSubFolder, xl, yt, xr, yb )					// ...save the existing windows coordinates so they can be restored
//			MoveWindow 	/W=$sNoteBookWndNm   0 , 0 , 0 , 0						// hide window by minimizing it

// Igor6
		GetWindow $sNoteBookWndNm, hide 
		variable	bIsHidden	= V_Value
		if ( bShow  &&  bIsHidden )												// User wants to restore the hidden window 
			SetWindow $sNoteBookWndNm, hide = 0	
// 2009-12-12 might be required if window is behind...
//			DoWindow /F $sNoteBookWndNm	
		elseif ( ! bShow  &&  ! bIsHidden )										// User wants to hide the visible window 
			SetWindow $sNoteBookWndNm, hide = 1
		endif
	endif
End


// 2008-04-23  ...................This code should be made obsolete


//=================================================================================================================
//  FORMAT and PRINT  SIMPLE  NOTEBOOKS  mainly for  DOCUMENTING COMPUTATIONAL RESULTS

Function		UFCom_PossiblyPrintNotebook( sNB, sText )
	string  	sNB, sText
	UFCom_PossiblyKillNotebook( sNB )
	NewNotebook /F=0 /K=1  /N=$sNb /W=(100, 50, 400, 600)
	Notebook  $sNb	text = sText
	DoAlert 1, "Do you want to print '" + sNb + "' ?"
	if ( V_Flag == 1 )
		PrintNotebook $sNb
	endif
End


Function	/S	UFCom_Results2Nb( sTitle, sFolder, lstInp, sInp00, lstMid, sMid00, lstOut, sOut00, nWidth )
	string  	sTitle, sFolder, lstInp, sInp00, lstMid, sMid00, lstOut, sOut00
	variable	nWidth

	string		sItem, sVal
	variable	n, nItems
	string  	sText = "\t" + sTitle + "\t\t" + Secs2Date( DateTime, 2 ) + "    " + Secs2Time( DateTime, 2 ) + "\r"
	sText	+= ResultSection( "Input Values",    sFolder, lstInp,  sInp00, nWidth )
	sText	+= ResultSection( "Intermediary Values",    sFolder, lstMid,  sMid00, nWidth )
	sText	+= ResultSection( "Output Values", sFolder, lstOut, sOut00, nWidth )
	return	sText
End


static Function  /S	ResultSection( sSectionTitle, sFolder, lst, sBsNm00, nWidth )
	string  	sSectionTitle, sFolder, lst, sBsNm00
	variable	nWidth 

	string		sItem, sVal, sText = ""
	variable	n, nItems	= ItemsInList( lst, "," )
	if ( nItems ) 
		sText	+= "\r\r\t   " + sSectionTitle + "\r\r"
		for ( n = 0; n < nItems; n += 1 )
			sItem	  	 =  StringFromList( n, lst, "," )  
			nvar	val	=   $"root:uf:" + sFolder + sBsNm00 + UFCom_IdxToDigitLetter( n )	+ "0"
			sText	+= "\t\t" + UFCom_pad( sItem, nWidth )  + "\t" + num2str( val ) + "\r"
		endfor
	endif
	return	sText
End
