//
// FPDIALOG.IPF 
// 
// Dialog routines
//
// With Font = MS Sans Serif  and size = 9   tabs are aligned neatly in the procedure window(s)
//
// Remarks:
//? 1. Dialog data cannot only be stored as strings (which would be much simpler), as this would inhibit IGORs SetVariable() formating
//      For  IGORs SetVariable() formating to work dialog variables must  be stored as variables.
//? 2. IGORs SetVariable() %d formating acts only on what is shown in the control field. The internal float representation...
//     ..(including trailing digits) is conserved even if the dialog control is left with the (desired and expected) integer. 
//     To save only the desired integer additional formating is necessary in the SaveDialog() function.
//? 3. IGORs SetVariable() %n.mlf formating is OK, trailing digits are truncated correctly also in the internal representation.   
//? 4. IGORs SetVariable() %s string formating does not work at all, although according to manual it  should !

// History:
// Assumptions/Caveats:
// 	don't use the underscore '_'  , neither in a variable name nor in a folder name. The underscore is used internally to separate those items.
//	don't use too long names. Internally  the 'root', all folders, the variable name and the variable ending are catenated using underscores. The total length must be <= 31 !
//	if you have defined a special-name action procedure and if you have put it into the proc field, then do not define an auto-built-name proc ( which would additionallly be called )
 
#pragma rtGlobals=1									// Use modern global access method.

// 041131
constant	kbSUBFOLDER_IN_ACTIONPROC_NM_SV	= 0	// SetVariable :	if the variable is e.g.  'dlg:myvar'   then the action proc name must be either  'myvar()'  [0]   or  'dlg_myvar()'  [1] 
constant	kbSUBFOLDER_IN_ACTIONPROC_NM_CB	= 1	// Checkbox :	if the variable is e.g.  'dlg:myvar'   then the action proc name must be either  'myvar()'  [0]   or  'dlg_myvar()'   [1]

constant			kYMARGIN			= 5				// vertical margin between buttons
constant			kVERT			= 0				// for Radio or checkbox groups: draw vertically. Number > 0 means draw so many items horizontally.
static constant		kTABCONTROL_EXTRAY	= 3
static strconstant	ksRADIOSEP		= "_"				// Do NOT change. Separates radio and checkbox button basename parts, index and count in this group
static strconstant	ksTITLEBLANK		= " "				// " "  or "" . The checkbox or radio button title as displayed in the panel may contain blanks between (but not within) the parts to improve readability

constant			kWIDTH_SLIM = 0, kWIDTH_NORMAL = 1, kWIDTH_WIDE = 2
	//strconstant	ksTCRAD		= "TcRad"				// the deepest folder  of a Radio button group located in a TabControl must start with this string so that the controls are recognized properly. To be used in  'PnControlTab()'
static strconstant	ksPREFIX_CCBUT 	= "ccb_"

// 050201
strconstant		ksTAB_SEP		= "°"				// Use °  or ^ .   Separates the tabs e.g. 'Adc0°Adc2'. Do NOT use characters used in titles e.g. , .  ( ) [ ] =  .  Neither use Tilde '~' (is main sep) , colon ':' (is path sep)   or   '|'  (also used elsewhere) .
strconstant		ksTAB_V_SEP		= "^"				// Separates single controls or control groups if they are placed in the next line
strconstant		ksTAB_H_SEP		= "|"				// Separates single controls or control groups in 1 line e.g.    'Checkbox    SEP   Popmenu   SEP   horizontal radio group'
// 050225
strconstant		ksTAB_DIM_SEP	= "$"				// ........no .......Separates array dimensions
strconstant		ksTAB_B_SEP		= "&"				// Separates  Blocks 	  within   Tabcontrols
strconstant		ksTAB_R_SEP		= "^"				// Separates  Rows	  within   Blocks 		within   Tabcontrols
strconstant		ksTAB_C_SEP		= "|"				// Separates  Columns within   Rows		within   Blocks 		within   Tabcontrols

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	COMMON  DIALOG  FUNCTIONS
static constant		TYPE = 0,		NAM = 1,		TXT = 2,			FLEN =3,		FORM = 4,	LIM = 5,		PRC = 6,	HELPTOPIC = 7, kDLG_DISABLE = 8
// constant NAM = 1 must be same as in FPulse.ipf !	
// also used for :						title or info text list	# of poss. for global	nOverSize 	3 colors

Function	PnXsize( twPanel )
	wave /T	twPanel
	return	MaxXLen( twPanel ) + 2 * kXMARGIN
End

Function	PnYsize( twPanel )
	wave /T	twPanel
	variable	nEmptySeps	= CountEmptySeparators( twPanel )	
	variable	yTotalTcHeight	=TotalHeightOfAllTabControls( twPanel )
	// if there is no separator text we make it lower to gain screen space
	variable	ControlCntNoTC	= ControlCntNoTabControl( twPanel )
	variable	yPixHeight	= ControlCntNoTC * ( kYHEIGHT + kYMARGIN ) - DecreaseSeparatorHeight( nEmptySeps ) + yTotalTcHeight + kYMARGIN		// if there is no separator text we make it lower to gain screen space
	// printf "PnYsize(1)  \tControlCntNoTC:%2d\tnEmptySeps:%2d\t   \tyTotalTcHeight:%3d  \t-> height:%3d \r", ControlCntNoTC, nEmptySeps,  yTotalTcHeight, yPixHeight
	return	yPixHeight
End

	
Static  Function		TotalHeightOfAllTabControls( tw )	
	wave  /T	tw
	variable	i, nHeight = 0, nLines	= numpnts( tw )
	for ( i = 0; i < nLines; i += 1 )
		string 	sControl	=  tw[ i ]
		string 	sType	= ExtractAndClean( TYPE, sControl )	
		if (  cmpstr( sType, "PN_TABCTRL" ) == 0 ) 
			nHeight	+= ( str2num( StringFromList( LIM, sControl ) )  - 2*( kYHEIGHT+ kYMARGIN ) - kTABCONTROL_EXTRAY )
		endif	
	endfor
	return nHeight 
End	


Static  Function		ControlCntNoTabControl( tw )	
// count all entries in panel wave except  CheckBoxes  and  Radio Buttons  located in TabControls   
	wave  /T	tw
	variable	i, nCnt = 0, nLines	= numpnts( tw )
	for ( i = 0; i < nLines; i += 1 )
		string 	sControl	=  tw[ i ]
		string 	sType	= ExtractAndClean( TYPE, sControl )	
//		if (  cmpstr( sType, "PN_CHKBOXT" )  != 0   &&  cmpstr( sType, "PN_RADIOT" )  != 0 ) 
		if (  cmpstr( sType, "PN_CHKBOXT" )  != 0   &&  cmpstr( sType, "PN_RADIOT" )  != 0  &&  cmpstr( sType, "kCHKBOXT" )  != 0   &&  cmpstr( sType, "kRADIOT" )  != 0 ) 
			nCnt += 1
		endif	
		// printf "\t\tPnY ControlCntNoTabControl()\tline:%2d/%2d\t%s    \t%s \r", i, nLines, sType, sControl 
	endfor
	return nCnt 
End	


Static  Function		CountEmptySeparators( tw )	
	wave  /T	tw
	variable	i, nEmptySeps = 0, nLines	= numpnts( tw )
	for ( i = 0; i < nLines; i += 1 )
		string 	sControl	=  tw[ i ]
		string 	sType	= ExtractAndClean( TYPE, sControl )	
		string 	sTitle		= ExtractAndClean( TXT, sControl ) 				// the text in the separator
		if ( ( cmpstr( sType, "PN_SEPAR" ) == 0   ||   cmpstr( sType, "kSEPAR" ) == 0  )  &&  strlen( sTitle )  == 0 ) 
			nEmptySeps += 1
		endif	
	endfor
	return nEmptySeps 
End	

Static  Function	DecreaseSeparatorHeight( nEmptySeps )
	variable	nEmptySeps 
	// print "\tEmptySepPixels:", nEmptySeps * kYHEIGHT * 3 / 4
	return	nEmptySeps * kYHEIGHT * 2 / 3 
End

Static  Function	TextLenToPixel( sTxt )
	string 	sTxt
	 // print  "TextLenToPixel() FontSizeStringWidth()" , ksFONT,  "->", FontSizeStringWidth( ksFONT, kFONTSIZE, 0, sTxt ), sTxt
	//return  		FontSizeStringWidth( ksFONT,  kFONTSIZE, 0, sTxt ) 	//040322  too small for  panels and too small for online analysis with many  WAx columns    
	return  4 + 1.04 * FontSizeStringWidth( ksFONT, kFONTSIZE, 0, sTxt ) 	//040322  OK for panels , still too small for online analysis  
End	

Static  Function	GetXSize( sText  ) 
// returns  length of this Panel line in pixels. If there is more than 1 control in the line the longest is taken and multiplied by the number
	string		sText
	string		sControl, sType
	variable  c, ControlsInLine, nFldLen, nTitleLen, maxControlLen = 0
	ControlsInLine = ItemsInList( sText, "|" )						// 050222 may interfere: 	ksTAB_V_SEP	   ksTAB_H_SEP
	for ( c = 0; c < ControlsInLine; c += 1 )
		sControl		=  StringFromList( c, sText, "|" )

// 031027  TODO (minor importance) : the field size of the PN_DICOLTXT  field  (and consequently the total line length) is not in all cases adjusted properly to the strlen of the 1. text item in the possibility list 
		nTitleLen		= TextLenToPixel( StringFromList( 0, StringFromList( TXT, sControl ), ksTILDE_SEP ) )	// the text in the button  or  the 1. string item (up to ksTILDE_SEP ~ ) in the possibility list
		//nTitleLen	= TextLenToPixel( StringFromList( TXT, sControl ) )							// the text in the button  or  total length of all string items in the possibility list  // 031027 old

		// 040323
		sType		=   ExtractAndClean( TYPE, sControl )	
		//if ( cmpstr( sType, "PN_RADIO" )  == 0   ||  cmpstr( sType, "PN_RADIOT" )  == 0   ||  cmpstr( sType, "PN_CHKBOX" )  == 0  ||  cmpstr( sType, "PN_CHKBOXT" )  == 0  )
		if ( !cmpstr( sType, "PN_RADIO" )  ||  !cmpstr( sType, "PN_RADIOT" )  ||  !cmpstr( sType, "PN_CHKBOX" )  ||  !cmpstr( sType, "PN_CHKBOXT" )  ||  !cmpstr( sType, "kRADIO" )  ||  !cmpstr( sType, "kRADIOT" )  ||  !cmpstr( sType, "kCHKBOX" )  ||  !cmpstr( sType, "kCHKBOXT" )  == 0  )
			nTitleLen += 10  	// the width of the checkbox or radio button
		endif
		if ( cmpstr( sType, "PN_TABCTRL" )  == 0 )					
			string		sTabs	= StringFromList( FORM, sControl )
			variable	nTabs 	= ItemsInList( sTabs, ksTAB_SEP )
			nTitleLen = TextLenToPixel( sTabs ) + nTabs * 18			// supply extra X width for the tabs
		endif

		nFldLen		= str2num( StringFromList( FLEN, sControl ) )
		nFldLen		= ( numType( nFldLen ) == kNUMTYPE_NAN )  ?  0  :  nFldLen	// field can be empty
		maxControlLen	= max( nTitleLen + nFldLen, maxControlLen )
		// printf "\t\tGetXSize() Len:%3d \t+ %3d \t=%3d  \tmaxControlLen:%3d \t'%s' \r", nTitleLen, nFldLen, nTitleLen + nFldLen, maxControlLen, sText[0,180]
	endfor
	// Decommentize the following line if the panel seems to be too big and you want to know which panel entry is responsable for the size 
	// printf "\tGetXSize()  nControls:%2d * %3d\t+%3d   \t(inner margins) = %3d \t'%s' \r", ControlsInLine,  maxControlLen,  ( ControlsInLine -1 ) *3,  maxControlLen * ControlsInLine + ( ControlsInLine -1 ) *3 , sText[0,160]
	return  maxControlLen * ControlsInLine + ( ControlsInLine -1 ) *3//+ 3 pixel in between
End		

static Function		MaxXLen( tw ) 
// return  length of longest control  in x  (in pixels)
	wave  /T	tw
	variable	iLongest, len, maxlen = 0, i,  nItems = numPnts( tw )
	for ( i = 0; i < nItems; i += 1 )
		len = GetXSize( tw[ i ] ) 
		if ( len > maxlen )
			maxlen 	= len
			iLongest	= i
		endif
		// printf "\t\tMaxXLen(   all    ) \t i:%3d /%3d /%3d \tlen:%4d\tmaxlen:%4d \t'%s' \r", i, iLongest, nItems, len, maxlen, (tw[ i ])[0,200]
	endfor
	// printf "\t\tMaxXLen( longest ) \t i:%3d /%3d \tlen:%4d\tmaxlen:%4d \t'%s' \r", iLongest, nItems, len, maxlen, (tw[ iLongest ])[0,200]
	return	maxlen
End		
		
//   Functions  for  expandable  dialog boxes  with buttons and with SetVals...
//	Features:
//	- sets and changes global variables and strings, name is taken from entry in text wave
//	- global variables are accessed via  hidden Set.. and Get.. functions which also take care of creation and default value
//	- input fields for integer, double and  string   with   number  formating  and  limit  values
//	- Buttons
//	- text wave containing all the above parameters  is still easy to understand
//	- each variable has its own (small) procedure: very flexible but  still readable
//	not yet (correctly) implemented : horizontal mode  ( eliminate separators to make line shorter..???)
//
//   Minimum requirements for expansion:
//	-  one line entry  in  the text wave  (specifying the name and all properties of the dialog element)
//!	For the button text update mechanism to work, a button can (and should) have the same name  as the variable which it  INDIRECTLY controls, although a button never DIRECTLY controls a variable. 


// DO NOT use _underscores_  in checkboxes as this interferes with the converted folder separator _  (=ksRADIOSEP) used in sFo_Name

// 060914
// 2009-10-23
//constant		kY_MISSING_PIXEL_TOP	= 18	// 18 is the height of  the Igor title line and menu bar	(appr.)
//constant		kY_MISSING_PIXEL_BOT	= 32	// 32 is the height of  status bar + windows 2 lines

Function		ConstructOrDisplayPanel( sPnWndNm, sPnTitle, sF, sPnOptions, xPos, yPos )
// Checks whether panel exists already or not. The Panel window creation macro and the window itself have the same name
	string  	sPnWndNm, sPnTitle, sF, sPnOptions
	variable	xPos, yPos
	if ( WinType( sPnWndNm ) != kPANEL )		
		Panel_( sPnWndNm, sPnTitle, sF, sPnOptions, xPos, yPos )		// if panel does not yet exist then construct it
	else
		DoWindow /F $sPnWndNm							//  if panel does already exist  bring it to front
	endif
End

Function		UpdatePanel(  sPnWndNm, sPnTitle, sF, sPnOptions )
	string  	sPnWndNm, sPnTitle, sF, sPnOptions
	if ( WinType( sPnWndNm ) == kPANEL )							// only if the panel does already exist then ...
		GetWindow     $sPnWndNm , wsize							// ...get its current position		
		// printf "\t\tUpdatePanel\t%s    left:%4d  \t(>%.0lf) \t>%.1lf\t\ttop :%d \t(>%.0lf) \t->y %.1lf \r", sPnWndNm, V_left, V_left * screenresolution / kIGOR_POINTS72,  V_right * screenresolution / kIGOR_POINTS72*100/GetIgorAppPixelX(),  V_top, V_top * screenresolution / kIGOR_POINTS72, V_bottom * screenresolution / kIGOR_POINTS72*100/GetIgorAppPixelY()
		DoWindow /K $sPnWndNm								// ...remove it ...
		string		sPanelWvNm = "root:uf:" + sF + sPnOptions
		variable	XSize 	= PnXsize( $sPanelWvNm ) 
		variable	XLoc		= V_left * screenresolution / kIGOR_POINTS72
		variable	YLoc		= V_top * screenresolution / kIGOR_POINTS72
		DrawPanel( sF, $sPanelWvNm, XSize, XLoc, YLoc, sPnTitle )		// ...and then reconstruct it at it's previous position	
		DoWindow /C $sPnWndNm								//  rename it
	endif
End


Function		Panel_( sPanelWndNm, sPnTitle, sF, sPnOptions, xPos, yPos )	
	string  	sPanelWndNm, sPnTitle, sF, sPnOptions
	variable	xPos, yPos									// relative panel positions within the range  0 ... 100  
	string		sPanelWvNm = "root:uf:" + sF + sPnOptions
	variable	XSize 	= PnXsize( $sPanelWvNm ) 

	variable	XLocMax	= GetIgorAppPixelX() -  Xsize - 4										// the rightmost panel position 
	variable	XLoc 	= min( max( 0, XLocMax * xPos / 100 ), xLocMax )
	variable	YLocMax 	= GetIgorAppPixelY() -  PnYsize( $sPanelWvNm ) - kY_MISSING_PIXEL_BOT - kY_MISSING_PIXEL_TOP// the lowest panel position
	variable	YLoc	 	= kY_MISSING_PIXEL_TOP + min( max( 0, YLocMax * yPos / 100 ), YLocMax )
	
	// Version 1: put this panel on the right side just above the status bar
	//	variable	XLoc = GetIgorAppPixelX() -  Xsize - 4						// put this panel on the right side just above the status bar
	//	variable	YLoc	 = GetIgorAppPixelY() -  PnYsize( $sPanelWvNm ) - yPos	// 42 is the height of  status bar + windows 2 lines
	// Version 2: put this panel somewhere in the middle of the screen to the left of the main  panel 
	// variable  XLoc	= GetIgorAppPixelX() - PnXsize( $sPanelWvNm ) - 140
	// variable  YLoc	= 300									// Panel location in pixel from upper side
	// printf "\t\tPanel( \t\t%s )  left:\t\t\t   %4d  \t(>%.1lf)\t\ttop : \t>%4d \t->y %.1lf \r", sPanelWndNm, XLoc, xPos, YLoc, yPos 
	DrawPanel( sF, $sPanelWvNm, XSize, XLoc, YLoc, sPnTitle )
	DoWindow /C $sPanelWndNm			//  rename it
End


Function  /S	ExtractAndClean( nType, sLine )
// eliminate all spaces, tabs, CRs so that a legal IGOR object name is constructed and returned
	variable	nType
	string  	sLine
// 050112	As we allow comma within control titles we must remove it 
//	return	RemoveWhiteSpace( StringFromList( nType, sLine ) )
	return	RemoveWhiteSpace1( StringFromList( nType, sLine ) )
End

Function  /S	ExtractCleanName( nType, sLine )
// eliminate all spaces, tabs, CRs so that a legal IGOR object name is constructed and return the part after the folder
	variable	nType
	string		sLine
// 050112	As we allow comma within control titles we must remove it 
//	string		sFolderAndName	= RemoveWhiteSpace( StringFromList( nType, sLine ) )
	string		sFolderAndName	= RemoveWhiteSpace1( StringFromList( nType, sLine ) )
	variable	n		= ItemsInList( sFolderAndName, ":" )
	string  	sName	= StringFromList( n - 1, sFolderAndName, ":" )
	// printf "\t\tExtractCleanName  len:%d   %s    %d  %s  \r", strlen( sFolderAndName ), sFolderAndName, strlen( sName ), sName
	return	sName
End

Function  /S	ExtractCleanFolder( nType, sLine )
// eliminate all spaces, tabs, CRs so that a legal IGOR object name is constructed and return the part before the name (including trailing :)
	variable	nType
	string		sLine
// 050112	As we allow comma within control titles we must remove it 
//	string		sFolderAndName	= RemoveWhiteSpace( StringFromList( nType, sLine ) )
	string		sFolderAndName	= RemoveWhiteSpace1( StringFromList( nType, sLine ) )
	variable	n	= ItemsInList( sFolderAndName, ":" )
	return	RemoveListItem( n - 1, sFolderAndName, ":" )
End

Function		DrawPanel( sF, tw, XSize, xLoc, yLoc, sPanelTitle )
	wave  /T	tw
	variable	XSize, xLoc, yLoc
	string		sF, sPanelTitle
	NewPanel /W=( XLoc, YLoc, XLoc + XSize, YLoc + PnYsize( tw ) ) /K= 1 as  sPanelTitle	// in pixel
	// print "DrawPanel NewPanel ", S_name, " has title: ", sPanelTitle
	DrawPanelControls( sF, tw, XSize - 2 * kXMARGIN, sPanelTitle )
End


Static  Function		DrawPanelControls( sThisF, tw, nXsize, sPanelTitle )
//? todo  could be split into 1. drawing  (needed often)   and    2.  proc linkage (needed only once)....
//? todo  combine     PN_DICOLTXT and  PN_DISPVAR   or   PN_SETVAR,PN_DISPVAR    or    PN_DISPSTR, PN_DISPVAR...  (ValDisplay does not take strings)
// 030115 Automatic connection of every control to the help system (manual connection (=SetHelpTopic() is no longer necessary)
//			 Disadvantages / problems compared to manual connection:
//			Changing button titles : Start   ... Start / Stop
//			Abbreviated button titles :	Acquis window options
//			Topic/subtopic Hierarchy : Links  button  Read CFS file   to   FPulse[Read CFS File] , better would be  Read CFS file   = Topic
// CAVE   pd()  is sometimes not padding correctly here........
	wave  /T	tw
	variable	nXsize
	string		sThisF				// ksCOM , ksACOld  or  ksEVAL
	string	  	sPanelTitle
	variable	nXmargin	= kXMARGIN
	variable	nYmargin	= kYMARGIN
	variable	nYsize	= kYHEIGHT
	variable	nXpos 	= nXmargin	//    040511   = nXmargin/2
	variable	nYpos	= nYmargin, nXBodyWidth
	variable	i, nLines	= numpnts( tw )
	variable	c, ControlsInLine
	string		sFullProcName, sHelpSubTopic = ""
	string		sFoNmIdx					// name of control must be unique so we add the wave elements index ( when control is controlled by a wave )
	variable	itemCnt = 0, nTotalItems=0		// for TabControl
	string  	sFullFolder, sCNm
	
	for ( i = 0; i < nLines; i += 1 )
		// printf "\t\tLine:%2d/%2d\t\t\t '%s' \r", i, nLines,  tw[ i ] 
		ControlsInLine = ItemsInList( tw[ i ], "|" )
		for ( c = 0; c < ControlsInLine; c += 1 )
			string		sControl		= StringFromList( c, tw[ i ] , "|" )
			string		sType		= ExtractAndClean( TYPE, sControl )	
			string		sCleanName 	= ExtractAndClean( NAM, sControl )		// e.g. 'root:uf:dlg:VarName_0_2' , blanks and tabs have been removed
			// build legal varname containing folder separated with '_'			// e.g. 'root_uf_dlg_VarName_0_2' 
			string		sFo_Name		= ReplaceString( ":", sCleanName, ksRADIOSEP )	
			string		sName		= ExtractCleanName( NAM, sControl )		// e.g. 'VarName_0_2' 
			string		sF		= ExtractCleanFolder( NAM, sControl )		// e.g. 'root:uf:dlg:'  
			string		sProc		= ExtractAndClean( PRC, sControl )		// e.g. 'MySpecial'
			string		sTitle			= StringFromList( TXT, sControl ) 			// the text in the button
			string		sLim			= StringFromList( LIM, sControl ) 			// variable limits   min,max,step  used only in PN_SETVAR  and  PN_DISPVAR   or  3 colors combined     
			string		sLen			= StringFromList( FLEN, sControl ) 		// field length
			string		sForm		= ExtractAndClean( FORM, sControl )		// number format   or  oversize 
string  	sDisable		= ExtractAndClean( kDLG_DISABLE, sControl )	// 050221
			variable	nOverSize		= str2num( sForm ) 					// make PN_SETSTR and PN_DISPSTR longer (1..3). You must also insert addititonal '|'  in the panel text wave
			nOverSize	= ( numType( nOverSize  ) == kNUMTYPE_NAN )  ?  0  :  nOverSize	// if field is empty use no oversize
			// printf "\t\tFolder %s  \tsName %s \tsCleanName:%s \tsFo_Name:%s  \r", pd(sF,10), pd(sName,23) , pd(sCleanName,29) , pd(sFo_Name,28) 
			// printf "\t\tLine:%2d/%2d\t# %2d/%2d\t '%s' \r", i, nLines, c, ControlsInLine, sControl
	
			if ( cmpstr( sType, "PN_BUTTON" )  == 0 )
				PanelButton( c, ControlsInLine, nXpos,  nYpos, nXsize, nYsize, nOverSize, sCleanName, sTitle, sPanelTitle, sProc, sThisF, sType, "fButtonProc" )
			
			elseif ( cmpstr( sType, "kBUTTON" )  == 0 )
				PanelButton( c, ControlsInLine, nXpos,  nYpos, nXsize, nYsize, nOverSize, sCleanName, sTitle, sPanelTitle, sProc, sThisF, sType, "fButtonProc_struct" )
	
 			//  040506  PN_BUTCOL		( looks like a button with 2 states but is actually a CustomControl  with 2 programmed titles and colors )
			elseif ( cmpstr( sType, "PN_BUTCOL" )  == 0 )										
				PanelColorButton( c, ControlsInLine, nXpos,  nYpos, nXsize, nYsize, nOverSize, sCleanName, sFo_Name, sTitle, sLim, sPanelTitle )
	
			//  Color of a field and text AUTOMATICALLY changing dependent on a global variable (using  CustomControl ) 	// 040430 
			elseif ( cmpstr( sType, "PN_DICOLTXT" )  == 0 )										
				PanelColorField( c, ControlsInLine, nXpos,  nYpos, nXsize, nYsize, nOverSize, sCleanName, sFo_Name, sTitle, sLim, sPanelTitle )

			// PN_TABCTRL
			// todo: help  and   tabcontrol title   or   external title  as  PN_SEPHORZ
			elseif ( cmpstr( sType, "PN_TABCTRL" ) == 0 )	

				TabControl	$sCleanName,	proc 	= fTabControl			// first call a standard  TabControl  procedure which enables/kDISABLEs buttons groups according to the selected tab...
																// ...then from there attempt to call  a special  TabControl  procedure  with  name derived form  control name. (This proc can be missing)
				TabControl	$sCleanName,	userdata( AllVars )  = sTitle		// sAllVars  is needed  in the TabControl action proc for showing and hiding the tabs
				TabControl	$sCleanName,	userdata( AllTabs ) = sForm		// sAllTabs is needed  in the TabControl action proc for showing and hiding the tabs
				TabControl	$sCleanName,	userdata( AllItems ) = sLen 		// sLen  is  the number of  Radio buttons in this group. Deliberate misuse of this variable, must be much smaller than any pixel length ...
				TabControl	$sCleanName,	pos 	= { nXpos-2, nYpos }
				TabControl	$sCleanName,	size	= { nXsize+4, nYsize + str2num( sLim ) }
				variable		nt, nTabs = ItemsInList( sForm, ksTAB_SEP )
				for ( nt = 0; nt < nTabs; nt += 1 )
					TabControl	$sCleanName,	tablabel( nt )	= StringFromList( nt, sForm, ksTAB_SEP )
				endfor
				TabControl	$sCleanName,	tablabel( nT)	= ""			// end marker
				TabControl	$sCleanName,	value = ItemsInList( sForm, ksTAB_SEP ) -1 // Select the last tab. Without this the 1. tab is displayed topmost but input is directed to the last tab.  
				// printf "\tPN_TABCTRL  '%s'   sCN:'%s' \tFolder:%s\tsTitle:%s...\tsLim:'%s'\tsLen:'%s'\tsForm:'%s'\tHelpTp:'%s[%s]'  xpos:%d   ypos:%d  xs:%d  ys:%d\r", sFo_Name, sCleanName, pd(sF,10), pd(sTitle,43), sLim, sLen, sForm, sPanelTitle, sHelpSubTopic, nXpos, nYpos, nXsize, nYsize
	
			// PN_POPUP   constructs a  popupmenu
			elseif ( cmpstr( sType, "PN_POPUP" ) == 0 )	
				// 030303 help implemented like Checkbox but not tested......
				// print "\t\tPN_POPUP sTitle:", sTitle, "Proc:", sProc, "sLim:", sLim
				if ( strlen( sProc ) == 0 )								//....no............ if the PRC field is empty  then  use  a button proc for connecting a help topic to the button...  
					sFullProcName	= "fPopup"						//...................and (if defined) additionally use a special button procedure with an automatic name derived from button name
				else												//  if the PRC field is not empty then use ...
					sFullProcName	= sProc 							// ..the string in the PRC field as a special button procedure
		 		endif
				sHelpSubTopic	= StringFromList( HELPTOPIC, sControl )		// for the help to work there must be an EXPLICIT call  'DisplayHelpTopicFor ( sControlNm )' in the action procedure !
				if ( strlen( sHelpSubTopic ) == 0 )							// if the subtopic field is empty  then  use  the title for connecting a help topic to the checkbox  
					sHelpSubTopic = sTitle
		 		endif
				nvar /Z		PopupVal	= $ReplaceString( "_", sFo_Name, ":" )
				// printf "\t\tPN_POPUP popup  %s\tFolder:%s\tProc:%s\tHelpTp:%s[%s]\tsForm:%s\tPopVal:\t%s\t exists:%d\tvalue:%g \r", pd(sFo_Name,29), pd(sF,10), pd( sFullProcName, 15), pd(sPanelTitle,9), pd(sHelpSubTopic,9),  sForm, pd(ReplaceString( "_", sFo_Name, ":" ),29), nvar_exists( PopupVal ), PopupVal
				ConnectControlToHelpTopic( sFo_Name, sPanelTitle, sHelpSubTopic )
				PopupMenu	$sFo_Name,	bodywidth	= str2num( sLen)	// very magical numbers empirically determined for one screen resolution...
				PopupMenu	$sFo_Name,	pos		= {  - 53 +nXpos + ( c + 1 ) * nXSize / ControlsInLine + 2,  nYpos -3 }	
				PopupMenu	$sFo_Name,	proc		= $sFullProcName	
				if ( strlen(  ExtractAndClean( FORM, sControl ) ) )
			  		PopupMenu	$sFo_Name,	mode= str2num( ExtractAndClean( FORM, sControl ) )	// entry to start with (counted from 1)  is  parameter in  4  from  POPUP line 
				else
			  		PopupMenu	$sFo_Name,	mode= PopupVal + 1							// entry to start with (counted from 1)  is initial value from  'CreateXXXGlobals()'   as  parameter in  4  from  POPUP line is empty 
				endif
		 		PopupMenu	$sFo_Name,	title	= sTitle 
				FUNCREF   fPopupListProc  fPopPrc = $sLim				// get the listbox entries from a function with auto-built name. This is the generalized...
				fPopPrc( sFo_Name )									//...form of the much simpler but limited call ' PopupMenu $sName, value = "Item1;Item2;..." '


			// 040429  PN_BUTPICT		( looks like a button with 2 states but is actually   a CheckBox with  titles and colors  retrieved from a picture  )
			// Colorize a  button  and change its title between 2 states like a checkbox  dependent on its global variable ( using  Checkbox ) 
			// In this approach color and titles are passed  as predefined pictures to the control.  Shorter code, less parameters passed, no action proc   but   less flexible . Changing a picture is a mess.
			// Another approach (=PN_BUTCOL) : color and titles are passed as strings to the control.   A lot of code, many parameters and an action proc is needed but this approach is more flexible.
			elseif ( cmpstr( sType, "PN_BUTPICT" )  == 0 )										
				if ( strlen( sProc ) == 0 )							// if the PRC field is empty  then  use  a button proc for connecting a help topic to the button...  
					sFullProcName	= "fChkbox"					// ..and (if defined) additionally use a special button procedure with an automatic name derived from button name
				else											//  if the PRC field is not empty then use ...
					sFullProcName	= sProc 						// ..the string in the PRC field as a special button procedure
		 		endif
				sHelpSubTopic	= StringFromList( HELPTOPIC, sControl )	// for the help to work there must be an EXPLICIT call  'DisplayHelpTopicFor ( sControlNm )' in the action procedure !
				if ( strlen( sHelpSubTopic ) == 0 )						// if the subtopic field is empty  then  use  the title for connecting a help topic to the checkbox  
					sHelpSubTopic = sTitle
		 		endif
				// printf "\tPN_PICSWITCH-Checkbox  %s\tFolder:%s\tProc:%s\tLen:%s\tPict/Form: %s\tHelpTp:'%s[%s]' \r", pd(sFo_Name,28), pd(sF,10), pd( sFullProcName, 16), pd(sLen,4), pad(sForm,32),sPanelTitle, sHelpSubTopic	
				ConnectControlToHelpTopic( sFo_Name, sPanelTitle, sHelpSubTopic )
				CheckBox	$sFo_Name,	pos		= { nXpos + c * nXSize / ControlsInLine + 2,  nYpos }	
				CheckBox	$sFo_Name,	title		= " "	
				CheckBox $sFo_Name,	proc		= $sFullProcName			
				CheckBox	$sFo_Name,	variable	= $( sF + sName ) 			
				CheckBox	$sFo_Name,	value	= FolderGetV( sF, sName, OFF )
				Checkbox 	$sFo_Name,	picture	=$sForm
	

			// PN_CHKBOX 	a single check box  is controlled by 1 global variable				// We need an explicit  PN_CHKBOX keyword although it is used like a number..
			// PN_CHKBOXT 	a single check box  inside a TabControl
			 elseif (  cmpstr( sType, "PN_CHKBOX" ) == 0  ||  cmpstr( sType, "PN_CHKBOXT" ) == 0 ) 	// ..because we want a Checkbox and not a SetVariable
				PanelCheckbox( c, ControlsInLine, nXpos,  nYpos, nXsize, nYsize, nOverSize, sCleanName, sTitle, sPanelTitle, sProc, sThisF, sF, sFo_Name, sControl, sType, "fChkbox" )

			// kCHKBOX 	a single check box  is controlled by 1 global variable	using  structures.      We need an explicit  kCHKBOX keyword although it is used like a number..
			// kCHKBOXT 	a single check box  inside a TabControl			using  structures.  
			elseif (  cmpstr( sType, "kCHKBOX" ) == 0  ||  cmpstr( sType, "kCHKBOXT" ) == 0 ) 	// ..because we want a Checkbox and not a SetVariable
				sFullFolder		= ksROOTUF_ + sThisF + ":" + sF			// e.g.  Root:uf:  +  evo   +   :  +   std:
				sCNm		= SelectString( kbSUBFOLDER_IN_ACTIONPROC_NM_CB, sName, sFo_Name )
				PanelCheckbox( c, ControlsInLine, nXpos,  nYpos, nXsize, nYsize, nOverSize, sCleanName, sTitle, sPanelTitle, sProc, sThisF, sFullFolder, sCNm, sControl, sType, "fChkbox_struct" )

 			//  PN_RADIO  buttons are a group of PN_CHKBOX  
			elseif (  cmpstr( sType, "PN_RADIO" ) == 0  ||  cmpstr( sType, "PN_RADIOT" ) == 0 ) 		 
				PanelRadio( c, ControlsInLine, nXpos,  nYpos, nXsize, nYsize, nOverSize, sCleanName, sTitle, sPanelTitle, sProc, sThisF, sF, sFo_Name, sControl, sType, "fRadio" )

			elseif (  cmpstr( sType, "kRADIO" ) == 0  	||  cmpstr( sType, "kRADIOT" ) == 0 ) 		 
				PanelRadio( c, ControlsInLine, nXpos,  nYpos, nXsize, nYsize, nOverSize, sCleanName, sTitle, sPanelTitle, sProc, sThisF, sF, sFo_Name, sControl, sType, "fRadio_struct" )


			elseif ( cmpstr( sType, "PN_SETVAR") == 0 ) 		
				PanelSetVar( c, ControlsInLine, nXpos,  nYpos, nXsize, nYsize, nOverSize, sCleanName, sTitle, sPanelTitle, sProc, sThisF, sF, sFo_Name, sControl, sType, "fSetvar" )

			elseif ( cmpstr( sType, "kSETVAR") == 0 ) 		
			  	sFullFolder		= ksROOTUF_ + sThisF + ":" + sF			// e.g.  Root:uf:  +  evo   +   :  +   std:
				sCNm		= SelectString( kbSUBFOLDER_IN_ACTIONPROC_NM_SV, sName, sFo_Name )
				PanelSetVar( c, ControlsInLine, nXpos,  nYpos, nXsize, nYsize, nOverSize, sCleanName, sTitle, sPanelTitle, sProc, sThisF, sFullFolder, sCNm, sControl, sType, "fSetvar_struct" )


			//  PN_SETSTR  SetVariable: STRING 		%s		
			elseif ( cmpstr( sType, "PN_SETSTR") == 0 ) 		
				SetVariable $sName,   proc		= fSetvar  						// PRC field is not but could easily be evaluated  like above in 'PN_SETVAR'  or 'PN_CHKBOX'
				ConnectControlToHelpTopic( sName, sPanelTitle, sTitle )
		 		SetVariable  $sName,	 value	= $( sF + sName )			// get name of global string variable to be changed
	 	 		SetVariable  $sName,	pos		= { nXPos + kXMARGIN/2 + 2 + c * nXSize / ControlsInLine + 2,  nYPos }
// printf "PN_SETSTR  %s  c:%2d/%2d    nOverSize:%d /%g \r",  sName, c, ControlsInLine, nOverSize, nOverSize
				SetVariable  $sName,	size		= { nXSize * ( 1 + nOverSize ) / ControlsInLine-7, 0 }
		 		SetVariable  $sName,	title		= pad( sTitle, (nXSize/ ControlsInLine-7 -str2num( sLen ) ) /8 ) // 7..8 is best empirical fit to achieve CORRECT right and left alignment and field size
				// SetVariable	$sName, bodyWidth= str2num( StringFromList( FLEN, sControl))	//  set and align field size, but give up left alignment of field text

	
			// Display variables: we use a Setvariable control (with editing kDISABLEd) and not DrawText because we want to access the control via their name '$sCleanName' 
			elseif ( strsearch( StringFromList( TYPE, sControl ), "PN_DISPVAR", 0 ) > -1 )			// 1010 datafolder aware
				SetVariable $sName,	noproc, limits = {0,0,0}, noedit = 1
//				SetVariable $sName,	bodywidth	= str2num( sLen)// very magical numbers empirically determined for one screen resolution...
	 	 		SetVariable  $sName,	pos		= { nXPos + kXMARGIN/2 + 2+ c * nXSize / ControlsInLine + 2,  nYPos }
				SetVariable  $sName,	size		= { nXSize / ControlsInLine-7, 0 }
// CAVE   pd()  is sometimes not padding correctly here........
// print "kika", sLen, nXSize,nXSize/ ControlsInLine,(nXSize/ ControlsInLine-7 -str2num( sLen ) ) /3, pd( sTitle, (nXSize/ ControlsInLine-7 -str2num( sLen ) ) /3 ) 
		 		SetVariable  $sName,	title		= pd( sTitle, (nXSize/ ControlsInLine-7 -str2num( sLen ) ) /8 ) // 7..8 is best empirical fit to achieve CORRECT right and left alignment and field size

		 		SetVariable $sName,	title		= sTitle 
		 		SetVariable $sName,	value	= $( sF + sName )					// get name of global string variable to be displayed
		 		SetVariable $sName,	format	= sForm

		 
			// Display strings: we use a Setvariable control (with editing kDISABLEd) and not DrawText because we want to access the control via their name '$sCleanName' 
			elseif ( cmpstr( sType , "PN_DISPSTR" ) == 0 )						// 1010 datafolder aware
				SetVariable  $sName,	noproc, limits = {0,0,0}, noedit = 1
	 	 		SetVariable  $sName,	pos		= { nXPos + kXMARGIN/2 + 2+ c * nXSize / ControlsInLine + 2,  nYPos }
				// printf "PN_DISPSTR  %s  c:%2d/%2d    nOverSize:%d /%g \r", sName, c, ControlsInLine, nOverSize, nOverSize
				SetVariable  $sName,	size		= { nXSize * ( 1 + nOverSize ) / ControlsInLine-7, 0 }
		 		SetVariable  $sName,	title		=  sTitle 
		 		SetVariable  $sName,	value	= $( sF + sName )				// get name of global string variable to be displayed
		
			elseif (  cmpstr( sType, "PN_SEPAR" ) == 0  ||  cmpstr( sType, "kSEPAR" ) == 0 )		
				if ( strlen( RemoveWhiteSpace( sTitle ) ) ) 
					DrawText		nXPos, nYpos+18, sTitle							// +18 aligns text between buttons
				else
					nYpos	= nYpos - DecreaseSeparatorHeight( 1 )					// if there is no separator text then make it lower
				endif	

			elseif (  cmpstr( sType, "PN_SEPHORZ" ) == 0 )								// text or empty field between horizontal entries
				DrawText		nXpos + c * nXSize / ControlsInLine + 2, nYpos+16, sTitle
		 

			///////////////////////////////////////////////////
			//  WAVE  CONTROLS
	
			//  PN_WVSETVAR   SetVariable:	GLOBAL 1- DIM  to  4-DIM  WAVE  ( like PN_SETVAR, but in FORMAT field are the 1..4 indices )
			elseif ( cmpstr( sType, "PN_WVSETVAR" ) == 0 ) 		
				sFoNmIdx	= sFo_Name + RemoveWhiteSpace1( sForm )
				if ( strlen( sProc ) == 0 )										// if the PRC field is empty  then use a standard procedure name...  
					SetVariable $sFoNmIdx,   proc	= fSetvar  						// ...for connecting a help topic to the control
					sHelpSubTopic = sTitle
				else														//  if the PRC field is not empty then use ...
					sFullProcName	= sProc  									// ..the string in the PRC field  to build a special procedure name
					SetVariable $sFoNmIdx,	proc	= $sFullProcName				// for the help to work there must be an EXPLICIT call ... 
					sHelpSubTopic	= StringFromList( HELPTOPIC, sControl ) 		 	//..'DisplayHelpTopicFor ( sControlNm )' in the action procedure !
					// printf "\tSpecial  PN_SETVAR  '%s'  with proc name '%s'  and help topic '%s' \r", sName, sFullProcName	,sHelpSubTopic	
		 		endif
				ConnectControlToHelpTopic( sFo_Name, sPanelTitle, sHelpSubTopic )
	 	 		SetVariable  $sFoNmIdx,	pos	= { nXPos + kXMARGIN/2 + 2+ c * nXSize / ControlsInLine + 2,  nYPos }
				SetVariable  $sFoNmIdx,	size	= { nXSize / ControlsInLine-7, 0 }
		 		SetVariable  $sFoNmIdx,	title	= pad( sTitle, (nXSize/ ControlsInLine-7 -str2num( sLen ) ) /8 ) // 8 is best empirical fit to achieve CORRECT right and left alignment and field size
		 		SetVariable  $sFoNmIdx,	limits	= { str2num( StringFromList( 0, sLim, "," ) ),str2num( StringFromList( 1, sLim, "," ) ),str2num( StringFromList( 2, sLim, "," ) ) }
			
				// Retrieve the value to be displayed in the panel control from the multi-dimensional master wave
				// General version for 1..4 dimensions requiring extra global variables
				variable  /G  $sF + sFoNmIdx   = Pn_IndexToWave( sF, sName, sForm )	// global shadow variable has the same name as SetVariable control..  
				nvar	SetVarVal				    = $sF + sFoNmIdx					// ...and resides in same folder as SetVarWave
				SetVariable  $sFoNmIdx,	value    = SetVarVal	
				// Special  version for only 1 dimension acting directly on the wave (unfortunately Igor does not allow multidim. waves here)
				// wave	w = $sF+sName
				// SetVariable  $sFoNmIdx,	value    = w[ str2num( sForm ) ]					// 1 dim version: use wave value directly (Igor does not allow  w[ ][ ] etc)
				
				// printf  "\t\tPN_WVSETVAR sForm:%s   sF:%s   sName:%s   sFo_Name:%s   sFoNmIdx:%s   value:%g   \r", sForm, sF, sName, sFo_Name, sFoNmIdx, SetVarVal
		
	
			// PN_WVCHKBOX 	a single check box  is controlled by a wave element	
			 elseif (  cmpstr( sType, "PN_WVCHKBOX" ) == 0 ) 				
				sFoNmIdx	= sFo_Name + RemoveWhiteSpace1( sForm )
				if ( strlen( sProc ) == 0 )							// if the PRC field is empty  then  use  a button proc for connecting a help topic to the button...  
					sFullProcName	= "fChkbox"				// ..and (if defined) additionally use a special button procedure with an automatic name derived from button name
				else											//  if the PRC field is not empty then use ...
					sFullProcName	= sProc						// ..the string in the PRC field as a special button procedure
		 		endif
				sHelpSubTopic	= StringFromList( HELPTOPIC, sControl )	// for the help to work there must be an EXPLICIT call  'DisplayHelpTopicFor ( sControlNm )' in the action procedure !
				if ( strlen( sHelpSubTopic ) == 0 )						// if the subtopic field is empty  then  use  the title for connecting a help topic to the checkbox  
					sHelpSubTopic = sTitle
		 		endif
				// printf "\tPN_CHKBOXCheckbox  %s\tFolder:%s\tProc:%s\tHelpTp:'%s[%s]' \r", pd(sFo_Name,24), pd(sF,10), pd( sFullProcName, 15), sPanelTitle, sHelpSubTopic	
				ConnectControlToHelpTopic( sFo_Name, sPanelTitle, sHelpSubTopic )
				CheckBox	$sFoNmIdx,	pos	 = { nXpos + c * nXSize / ControlsInLine + 2,  nYpos + 1 }	
				CheckBox	$sFoNmIdx,	title 	 = sTitle	
				CheckBox	$sFoNmIdx,	mode = 0				// default checkbox appearance, not radio button
//				CheckBox	$sFoNmIdx,	disable = str2num( sLen )  	// 050216 the 'length' field (also usable: 'limit' field) is used to store normal(=0) , hide(=1) and kDISABLE(=2) information
				CheckBox	$sFoNmIdx,	disable = str2num( sDisable)// 050221 the 8. field  is used to store normal(=0) , hide(=1) and kDISABLE(=2) information
				CheckBox $sFoNmIdx,	proc	 = $sFullProcName			
				// Retrieve the value to be displayed in the panel control from the multi-dimensional master wave
				CheckBox	$sFoNmIdx,	value  =  Pn_IndexToWave( sF, sName, sForm ) 
				// print  "PN_CHKBOX2", sForm, sF, sName, sFo_Name, sFoNmIdx
		
	
			// PN_WVPOPUP   constructs  listboxes controlled by a  1-dim  to 4-dimensional wave
			elseif ( cmpstr( sType, "PN_WVPOPUP" ) == 0 )	
				sFoNmIdx	= sFo_Name + RemoveWhiteSpace1( sForm )
				if ( strlen( sProc ) == 0 )							//....no............ if the PRC field is empty  then  use  a button proc for connecting a help topic to the button...  
					sFullProcName	= "fPopup"					//...................and (if defined) additionally use a special button procedure with an automatic name derived from button name
				else											//  if the PRC field is not empty then use ...
					sFullProcName	= sProc						// ..the string in the PRC field as a special button procedure
		 		endif

				PopupMenu	$sFoNmIdx,	bodywidth	= str2num( sLen)	// very magical numbers empirically determined for one screen resolution...
				PopupMenu	$sFoNmIdx,	pos		= {  - 53 +nXpos + ( c + 1 ) * nXSize / ControlsInLine + 2,  nYpos -3 }	
				PopupMenu	$sFoNmIdx,	proc		= $sFullProcName	
		 		PopupMenu	$sFoNmIdx,	title		= sTitle 
				PopupMenu	$sFoNmIdx,	disable	= str2num( sDisable )	// 050221		normal:0,  hide:1,  grey:2

				FUNCREF   fPopupListProc  fPopPrc = $RemoveWhiteSpace1(sLim)// get the listbox entries from a function with auto-built name. This is the generalized...
				fPopPrc( sFoNmIdx )									//...form of the much simpler but limited call ' PopupMenu $sName, value = "Item1;Item2;..." '
				// Retrieve the value to be displayed in the panel control from the multi-dimensional master wave
				PopupMenu	$sFoNmIdx,	mode =  Pn_IndexToWave( sF, sName, sForm ) +1 //wWave[ nIdx0][ nIdx1 ][ nIdx2 ] + 1
				// print  "PN_WVPOPUP", sForm, sF, sName, sFo_Name
			endif	
		endfor
		// 040511 nXpos	= nXmargin				

		// Draw  Checkboxes of a TabControl over each other = do not advance nYPos  as usual but go back and forth  for all  nTabs  of the TabControl
		//if ( cmpstr( sType, "PN_CHKBOXT" ) == 0  ||  cmpstr( sType, "PN_RADIOT" ) == 0 )	
		if ( cmpstr( sType, "PN_CHKBOXT" ) == 0  ||  cmpstr( sType, "PN_RADIOT" ) == 0  || cmpstr( sType, "kCHKBOXT" ) == 0  ||  cmpstr( sType, "kRADIOT" ) == 0 )	
			variable	bIsVertical	=  ( ControlsInLine == 1 )
			variable	nCtrlLine
			if ( nTotalItems == 0 )
				variable	CtrlBegYPos	= nYPos
			endif
			nTotalItems += 1
	
			if ( bIsVertical )
				ItemCnt	= str2num( sLim )
				nCtrlLine	=  ItemCnt * ( nTotalItems == ItemCnt * nTabs ) + mod ( nTotalItems, ItemCnt ) 
				nYPos	= CtrlBegYPos + nCtrlLine * ( nYsize + nYmargin )		
				if ( nTotalItems == ItemCnt * nTabs )
					nTotalItems = 0 
				endif	
			else
				if ( nTotalItems ==  nTabs )
					nYPos	= CtrlBegYPos + ( nYsize + nYmargin )		
					nTotalItems = 0 
				endif
			endif			 			
			 // printf "\t%s  %s\ti:%2d\tnTbs:%2d\tnCL:%d\titcnt:%d\ttotIt:%2d\tsLim: %s\t  YPos:%3d\t%s\t%s\t%s \r", pd(sType,12), SelectString(bIsVertical, "horiz", " vert "), i, nTabs, nCtrlLine, itemCnt, nTotalItems, sLim, nYPos, pd(sF,16), pd(sName,13), (tw[i] )[0,200]
		else
			nYpos	= nYpos + nYsize + nYmargin		
			 if ( cmpstr( sType, "PN_SEPAR" ) == 0   ||   cmpstr( sType, "kSEPAR" ) == 0 )	
				// printf "\tPN_SEPAR(    )    \ti:%2d \t\t\t\t\t\t\t\t\t\t\t  YPos:%3d\t'%s' \t%s\t%s \r", i, nYPos, pd(sF,16), pd(sName,13),  (tw[i] )[0,200]
			 endif
		endif


	endfor
End	



Function	/S	Idx2Str( idx )	
	variable	idx	
	//return	num2char( idx + char2num("a") ) 			// Version 1 : code 0 .. 25	into	'a'  ..  'z' 
	if ( idx < 10 )
		return	num2str( idx )
	elseif ( idx < 36 )
		return	num2char( idx - 10 + char2num("a") ) 		// Version 2 :  code 0 .. 9 , 10  ..  35	into	'0'  ..  '9' , 'a'  ..  'z' 
	else
		InternalWarning ( "Idx2Str()		Number  " + num2str( idx ) + " cannot be converted into string." )
	endif
End

Function		Str2Idx( sOneChar )	
	string		sOneChar
	//variable	idx	=	char2num( sOneChar ) - char2num("a")		// Version 1 :  decode   'a'  ..  'z' 			into	0  ..  25
	variable	idx	=	str2num( sOneChar ) 						// Version 2 :  decode  '0'  ..  '9' , 'a'  ..  'z'  	into	0 .. 9 , 10  ..  35
	if ( numType( idx ) == kNUMTYPE_NAN )						// 		..it was not a digit, so it should be a (small) letter 
		idx	=	char2num( sOneChar ) - char2num("a") + 10
	endif					
	return	idx
End

Function	/S	IndexToStr1( i0 )	
	variable	i0						
	return	Idx2Str( i0 )
End

Function	/S	IndexToStr2( i0, i1 )	
	variable	i0, i1			
	return	Idx2Str( i0 ) + Idx2Str( i1 )  
End

Function	/S	IndexToStr3( i0, i1, i2 )	
	variable	i0, i1, i2				
print "IndexToStr3()",  i0, i1, i2 , "->", Idx2Str( i0 ) + Idx2Str( i1 ) +  Idx2Str( i2 ) 
	return	Idx2Str( i0 ) + Idx2Str( i1 ) +  Idx2Str( i2 ) 
End

Function	/S	IndexToStr4( i0, i1, i2, i3 )	
	variable	i0, i1, i2, i3				
	return	Idx2Str( i0 ) + Idx2Str( i1 ) +  Idx2Str( i2 )  + Idx2Str( i3 ) 
End

// removed 050803
//Function		StrToIndex1( sControlNm, i0 )	
//	string		sControlNm
//	variable	&i0
//	variable	len	= strlen( sControlNm )
//	i0		= str2idx( sControlNm[ len-1 , len-1 ] )
//End
//
//Function		StrToIndex2( sControlNm, i0, i1 )	
//	string		sControlNm
//	variable	&i0, &i1
//	variable	len	= strlen( sControlNm )
//	i0		= Str2Idx( sControlNm[ len-2 , len-2 ] ) 
//	i1		= Str2Idx( sControlNm[ len-1 , len-1 ] ) 
//	// print	"StrToIndex2( sControlNm, i0, i1 )", sControlNm, "->",  i0, i1 "->ch=i0:", i0, "rg=i1:", i1
//End
//
//Function		StrToIndex3( sControlNm, i0, i1, i2 )	
//	string		sControlNm
//	variable	&i0, &i1, &i2
//	variable	len	= strlen( sControlNm )
//	i0		= Str2Idx( sControlNm[ len-3 , len-3 ] ) 
//	i1		= Str2Idx( sControlNm[ len-2 , len-2 ] ) 
//	i2		= Str2Idx( sControlNm[ len-1 , len-1 ] ) 
//	// print	"StrToIndex3( sControlNm, i0, i1, i2 )", sControlNm, "->",  i0, i1, i2, "->ch=i0:", i0, "rg=i1:", i1,  StringFromList( i2, ksPHASES )
//End
//
//Function		StrToIndex4( sControlNm, i0, i1, i2, i3 )	
//	string		sControlNm
//	variable	&i0, &i1, &i2, &i3
//	variable	len	= strlen( sControlNm )
//	i0		= Str2Idx( sControlNm[ len-4 , len-4 ] ) 
//	i1		= Str2Idx( sControlNm[ len-3 , len-3 ] ) 
//	i2		= Str2Idx( sControlNm[ len-2 , len-2 ] ) 
//	i3		= Str2Idx( sControlNm[ len-1 , len-1 ] ) 
//	// print	"StrToIndex4( sControlNm, i0, i1, i2, i3 )", sControlNm, "->",  i0, i1, i2, i3, "->ch=i0:", i0, "rg=i1:", i1,  StringFromList( i2, ksPHASES ), StringFromList( i3, sCN_TEXT )
//End


Function		Pn_IndexToWave( sF, sName, sForm ) 
	string		sF, sName, sForm
	variable	nIdx0, nIdx1, nIdx2, nIdx3						
	wave	wWave	= $( sF + sName )
	variable	WvDim	= WaveDims( wWave )
	if( WvDim != strlen( sForm ) )
		InternalWarning( "Wave '" + sF + sName + "' has " + num2str( WvDim ) + " dimensions , which is not compatible to  sForm: " + sForm  )
	endif												// works for dimension 1 to 4 
	nIdx0	= Str2Idx( RemoveWhiteSpace1( sForm )[0,0] )		// get 1. index of global  wave element 
	nIdx1	= Str2Idx( RemoveWhiteSpace1( sForm )[1,1] )		// get 2. index of global  wave element 
	nIdx2	= str2Idx( RemoveWhiteSpace1( sForm )[2,2] )		// get 3. index of global  wave element
	nIdx3	= str2Idx( RemoveWhiteSpace1( sForm )[3,3] )		// get 4. index of global  wave element 
	variable	value = WvDim == 1 ?  wWave[ nIdx0 ] : WvDim == 2 ?  wWave[ nIdx0][ nIdx1 ]  : WvDim == 3 ?  wWave[ nIdx0][ nIdx1 ][ nIdx2 ] :  wWave[ nIdx0][ nIdx1 ][ nIdx2 ] [ nIdx3 ] 
	// printf  "\t\tPn_IndexToWave()  sF:%s   sName:\t%s\tsForm:\t%s\t ->\tnIdx0:%d   nIdx1:%d   nIdx2:%d   nIdx3:%d   -> value:%g \r", sF, pd(sName,9), pd(sForm,5), nIdx0, nIdx1, nIdx2, nIdx3, value
	return	value
End 

//===============================================================================================================

//Function		PanelButton( c, ControlsInLine, nXpos,  nYpos, nXsize, nYsize, nOverSize, sCleanName, sTitle, sPanelTitle, sProc )
//	variable	c, ControlsInLine, nXpos,  nYpos, nXsize, nYsize, nOverSize
//	string		sCleanName, sTitle, sPanelTitle, sProc 
//	string		sProcName
//	if ( strlen( sProc ) == 0 )								// if the PRC field is empty then call a standard button procedure which auto-builds...
//		sProcName	= "fButtonProc" 					// ...the name of button proc unique to the button name and execute this proc 
//	else												//  if the PRC field is not empty then use the string in the PRC field ...
//		sProcName	= sProc							// ..as a special button procedure. Advantage: a single proc serves multiple buttons
//	endif										
//	Button	$sCleanName, 	proc	= $sProcName				// a button always resides in the root as it needs no folders as it has no variable	
//	// printf "\t\tPN_BUTTON  clean/controlname = '%s'   \t\t\t\t\t  title:'%s'   Proc = '%s' \r", sCleanName,   sTitle, sProcName
//	ConnectControlToHelpTopic( sCleanName, sPanelTitle, sTitle )
//	Button	$sCleanName,	pos = { nXpos + c * nXSize / ControlsInLine + 2,  nYpos }
//	Button	$sCleanName,	size = { nXsize * ( 1 + nOverSize )  / ControlsInLine - 2, nYsize }
//	// use the fixed text supplied within 'tw..'  or  build  special text string which can be changed
//	if ( strlen( RemoveWhiteSpace( sTitle ) ) )					// if the text field (=entry after name) is not blank..
//		Button	$sCleanName,	title = sTitle				// ..we use this string directly and allow no modifications..
//	else
//		FUNCREF   fBuTitle  fBuTi = $( sCleanName + "_Title" )	// if the text field is blank a special function draws (changing) text..
//	 	fBuTi( sCleanName )								// these are the  buXxxTitle()  functions which draw the button title (defined below)
//	endif
//End				


Function		PanelButton( c, ControlsInLine, nXpos,  nYpos, nXsize, nYsize, nOverSize, sCleanName, sTitle, sPanelTitle, sProc, sThisF, sType, sDefProc )
	variable	c, ControlsInLine, nXpos,  nYpos, nXsize, nYsize, nOverSize 
	string		sCleanName, sTitle, sPanelTitle, sProc, sThisF, sType, sDefProc 
	string		sProcNm
	if ( strlen( sProc ) == 0 )								// if the PRC field is empty then call a standard button procedure which auto-builds...
		sProcNm	= sDefProc		 				// ...the name of button proc unique to the button name and execute this proc 
		// printf "\t\t%s\tclean/controlname = '%s'   \t\t\t\t\t  title:'%s'   Proc = '%s'   (=generic ! ) \tsThisF:'%s' \r", sType, sCleanName,   sTitle, sProcName, sThisF
	else												//  if the PRC field is not empty then use the string in the PRC field ...
		sProcNm	= sProc							// ..as a special button procedure. Advantage: a single proc serves multiple buttons
	endif										
	// printf "\t\t%s\tclean/controlname = '%s'   \t\t\t\t\t  title:'%s'\tsThisF:'%s'  \tProc:\t%s\t%s\t ->\t%s\t\r", sType, sCleanName,   sTitle, sThisF, pd( sProc, 15), pd( sDefProc, 15), pd( sProcNm, 15)
	Button	$sCleanName, 	proc	= $sProcNm				// a button always resides in the root as it needs no folders as it has no variable	
	ConnectControlToHelpTopic( sCleanName, sPanelTitle, sTitle )
	Button	$sCleanName,	pos = { nXpos + c * nXSize / ControlsInLine + 2,  nYpos }
	Button	$sCleanName,	size = { nXsize * ( 1 + nOverSize )  / ControlsInLine - 2, nYsize }
	if ( cmpstr( sType, "kBUTTON" )  == 0 )		// ???
		Button $sCleanName,	userdata( sThisF )= sThisF	
	endif									// ???

	// use the fixed text supplied within 'tw..'  or  build  special text string which can be changed
	if ( strlen( RemoveWhiteSpace1( sTitle ) ) )					// if the text field (=entry after name) is not blank..
		Button	$sCleanName,	title = sTitle				// ..we use this string directly and allow no modifications..
	else
		FUNCREF   fBuTitle  fBuTi = $( sCleanName + "_Title" )	// if the text field is blank a special function draws (changing) text..
	 	fBuTi( sCleanName )								// these are the  buXxxTitle()  functions which draw the button title (defined below)
	endif
End				


Function		PanelSetVar( c, ControlsInLine, nXpos,  nYpos, nXsize, nYsize, nOverSize, sCleanName, sTitle, sPanelTitle, sProc, sThisF, sF, sCNm, sControl, sType, sDefProc  )
	variable	c, ControlsInLine, nXpos,  nYpos, nXsize, nYsize, nOverSize
	string		sCleanName, sTitle, sPanelTitle, sProc, sThisF, sCNm, sF, sControl, sType, sDefProc 

	string		sProcNm		= sDefProc								// if the PRC field is empty  then use a standard procedure name for connecting a help topic to the control  and (if defined) additionally use a special  action proc  with an automatic name
	string		sName		= ExtractCleanName( NAM, sControl )				// e.g. 'VarName_0_2' 
	string 	sHelpSubTopic	= StringFromList( HELPTOPIC, sControl )			// for the help to work there must be an EXPLICIT call  'DisplayHelpTopicFor ( sControlNm )' in the action procedure !
	string		sLen			= StringFromList( FLEN, sControl ) 				// field length
	string		sLim			= StringFromList( LIM, sControl ) 					// variable limits   min,max,step  used only in PN_SETVAR  and  PN_DISPVAR   or  3 colors combined     
	string		sForm		= ExtractAndClean( FORM, sControl )				// number format   or  oversize 

	if ( strlen( sProc ) )												// if the PRC field is not empty then use the string in the PRC field  to build a special procedure name
		sProcNm	= sProc 											// if the PRC field is not empty then use the string in the PRC field as a special  action procedure
		// printf "\tSpecial  %s  '%s'  with proc name '%s'  and help topic '%s' \r", sType, sCNm, sProcNm, sHelpSubTopic	
 	endif
	if ( strlen( sProc ) == 0 )		// ????								// if the PRC field is empty  then use a standard procedure name  for connecting a help topic to the control...  
		sHelpSubTopic = sTitle
	endif
	ConnectControlToHelpTopic( sName, sPanelTitle, sHelpSubTopic )
	// printf "PanelSetVar_struct\tCleanNm:\t%s\tFo_Nm:\t%s\t%s\tFolder:\t%s\tNm:\t%s\tCtrlNm:\t%s\t  \r", pd(sCleanName,15), pd(sFo_Name,15), pd(sF,15),  pd(sName,15),  pd(sCNm,23)

 	SetVariable  $sCNm,	pos		= { nXPos + kXMARGIN/2 + 2 + c * nXSize / ControlsInLine + 2,  nYPos }
	SetVariable  $sCNm,	size		= { nXSize / ControlsInLine-7, 0 }
 	SetVariable  $sCNm,	title		= pad( sTitle, (nXSize/ ControlsInLine-7 -str2num( sLen ) ) /8 ) // 7..8 is best empirical fit to achieve CORRECT right and left alignment and field size
	SetVariable $sCNm,	proc		= $sProcNm						
 	SetVariable  $sCNm,	value	= $( sF + sName )					// get name of global number variable to be changed
 	// SetVariable	$sCNm, bodyWidth= str2num( StringFromList( FLEN, sControl))	//  set and align field size, but give up left alignment of field text
 	SetVariable  $sCNm,	limits	= { str2num( StringFromList( 0, sLim, "," ) ),str2num( StringFromList( 1, sLim, "," ) ),str2num( StringFromList( 2, sLim, "," ) ) }
 	SetVariable  $sCNm,	format	= sForm								// cleaning is only necessary when string contains blanks, tabs etc.
	SetVariable  $sCNm,	userdata( sThisF )= sThisF	
End


Function		PanelCheckbox( c, ControlsInLine, nXpos,  nYpos, nXsize, nYsize, nOverSize, sCleanName, sTitle, sPanelTitle, sProc, sThisF, sF, sCNm, sControl, sType, sDefProc )
	variable	c, ControlsInLine, nXpos,  nYpos, nXsize, nYsize, nOverSize
	string		sCleanName, sTitle, sPanelTitle, sProc, sThisF, sCNm, sF, sControl, sType, sDefProc

	string		sProcNm		= sDefProc								// if the PRC field is empty  then use a standard procedure name for connecting a help topic to the control  and (if defined) additionally use a special  action proc with an automatic name
	string		sName		= ExtractCleanName( NAM, sControl )				// e.g. 'VarName_0_2' 
	string		sHelpSubTopic	= StringFromList( HELPTOPIC, sControl )			// for the help to work there must be an EXPLICIT call  'DisplayHelpTopicFor ( sControlNm )' in the action procedure !

	if ( strlen( sProc ) )												// if the PRC field is not empty then use ...
		sProcNm		= sProc 										// if the PRC field is not empty then use the string in the PRC field as a special  action procedure
	endif
	if ( strlen( sHelpSubTopic ) == 0 )										// if the subtopic field is empty  then  use  the title for connecting a help topic to the checkbox  
		sHelpSubTopic = sTitle
	endif
	ConnectControlToHelpTopic( sCNm, sPanelTitle, sHelpSubTopic )
	// printf "PanelCheckbox_str.\tCln:\t%s\tThisF: %s\tFldr:%s\tNm:\t%s\tCtrlNm:\t%s\t  \r", pd(sCleanName,16), pd(sThisF,6),  pd(sF,15),  pd(sName,15),  pd(sCNm,23)
	
	CheckBox	$sCNm,	pos		= { nXpos + c * nXSize / ControlsInLine + 2,  nYpos + 1 }	
	CheckBox	$sCNm,	title		= sTitle	
	CheckBox	$sCNm,	mode	= 0							// default checkbox appearance, not radio button appearance
	CheckBox $sCNm,	proc		= $sProcNm			
	CheckBox	$sCNm,	variable	= $( sF + sName ) 			
	CheckBox	$sCNm,	value	= FolderGetV( sF, sName, OFF )
	CheckBox	$sCNm,	userdata( sThisF )= sThisF				// !!!  'sThisF'  is the name by which  GetUserData()  retrieves the string 'sThisF'
	// printf "\tkCHKBOX-Checkbox  %s\tFolder:%s\tProc:%s\tHelpTp:'%s[%s]' \r", pd(sName,28), pd(sF,10), pd( sProcNm, 26), sPanelTitle, sHelpSubTopic	
	 // printf "\tkCHKBOX-Checkbox \t%s \r", sControl[0,220]
End


Function		PanelRadio( c, ControlsInLine, nXpos,  nYpos, nXsize, nYsize, nOverSize, sCleanName, sTitle, sPanelTitle, sProc, sThisF, sF, sCNm, sControl, sType, sDefProc )
	variable	c, ControlsInLine, nXpos,  nYpos, nXsize, nYsize, nOverSize
	string		sCleanName, sTitle, sPanelTitle, sProc, sThisF, sCNm, sF, sControl, sType, sDefProc

	string		sProcNm		= sDefProc								// if the PRC field is empty  then use a standard procedure name for connecting a help topic to the control  and (if defined) additionally use a special  action proc with an automatic name
	string		sName		= ExtractCleanName( NAM, sControl )				// e.g. 'VarName_0_2' 
	string		sHelpSubTopic	= StringFromList( HELPTOPIC, sControl )			// for the help to work there must be an EXPLICIT call  'DisplayHelpTopicFor ( sControlNm )' in the action procedure !

	if ( strlen( sProc ) == 0 )											// if the PRC field is empty  then call a standard checkbox procedure which first checks/unchecks the radio buttons...
		sProcNm	= sDefProc 										// ...and then calls special checkbox with auto-built name (if it exists, it can be missing)
	else															//  if the PRC field is not empty then use ...
		sProcNm	= sProc											// ..the string in the PRC field as a special button procedure which must exist...
	endif															// ...and must contain a call to  'fRadio'  at the beginning
	sHelpSubTopic	= StringFromList( HELPTOPIC, sControl ) 					//..'DisplayHelpTopicFor ( sControlNm )' in the action procedure !

	// printf "\t%s     \t Checkbox  %s\tsFldr:%s\tProc:%s\tHelpTp:%s[%s]  sName:%s\r", sType, pd(sCNm,28), pd(sF,15), pd( sProcNm, 16), pd(sPanelTitle,15), pd(sHelpSubTopic,23), pd(sName ,15)
	ConnectControlToHelpTopic( sCNm, sPanelTitle, sHelpSubTopic )
	CheckBox	$sCNm,	pos		= { nXpos + c * nXSize / ControlsInLine + 2,  nYpos +2 }	// Vertical  and Horizontal buttons	
	CheckBox	$sCNm,	title		= sTitle 
	CheckBox	$sCNm,	mode	= 1									// radio button appearance, not default checkbox appearance
	CheckBox $sCNm,	proc		= $sProcNm	
	CheckBox	$sCNm,	value 	= RadioButtonBoolValue( sCNm )// sFo_Name )
	CheckBox	$sCNm,	userdata( sThisF )= sThisF	
End


static strconstant	ksTILDE_SEP	= "~"	// ","

Function		PanelColorButton( c, ControlsInLine, nXpos,  nYpos, nXsize, nYsize, nOverSize, sCleanName, sFo_Name, sTitle, sColors, sPanelTitle )		// 040430  
// Colorize a  button  and change its title between 2 states like a checkbox  dependent on its global variable ( using  CustomControl  and  'PN_BUTCOL' ) 
// In this approach color and titles are passed as strings to the control.   A lot of code, many parameters and an action proc is needed but this approach is more flexible.
// Another approach (=PN_BUTPICT) :  make a pictures from the colors and the titles and pass the picture name. Shorter code, less parameters passed, no action proc   but   less flexible . Changing a picture is a mess.
	variable	c, ControlsInLine, nXpos,  nYpos, nXsize, nYsize, nOverSize
	string		sCleanName, sFo_Name, sTitle, sColors, sPanelTitle 
	variable	xPos, xSize
	string		sCleanPanelNm	= CleanupName( sPanelTitle, 0 )					// e.g. FPulse 2.22 -> FPulse222
	variable	nColors		= ItemsInList( sColors, ksTILDE_SEP )
	variable	nTitles		= ItemsInList( sTitle, ksTILDE_SEP )

	xPos		= nXPos + kXMARGIN/2 + 2 + c * nXSize / ControlsInLine  -1//+6
	xSize		= nXSize * ( 1 + nOverSize ) 		     / ControlsInLine - 2//11
	string		    sCustomControlName	= ksPREFIX_CCBUT + sFo_Name		//  the name of the CustomControl  is 'ccb_FolderVariableName'			

	CustomControl 	$sCustomControlName,	pos 	= { xPos, nYpos }, size={ xSize, nYsize }// this custom control initially looks like a button
	CustomControl 	$sCustomControlName,	proc	= ccColorButtonProc
	CustomControl	$sCustomControlName,	userdata( titles )		= sTitle
	CustomControl	$sCustomControlName,	userdata( colors )	= sColors
// 050821 does not work
//	CustomControl	$sCustomControlName,	userdata( CtrlNm )	= sCustomControlName
//	CustomControl	$sCustomControlName,	userdata( WinNm )	= sPanelNm			// todo


	CustomControl	$sCustomControlName,	value		  = $sCleanName
	variable	len	= strlen( sCustomControlName )
	if ( len > 31  )															// allow _98_99  (6 characters after the base nmae)
		 printf "++++Internal error : Control name  '%s'  is too long (%d) . Must be <= 31 . \r", sCustomControlName, len
	endif
	
	// printf "\t\tPN_BUTCOL   nCo:%d   nTi:%d  nOverSize:%2d  ccCoNm:\t%s\t%d\tClnNm:\t%s\tFo_Nm:%s\tTitle:%s \tPT:%s\t-> %s\tColors:'%s' \r", nColors, nTitles, nOverSize, pd(sCustomControlName,27), len, pd(sCleanName,23), pd(sFo_Name,23), pd(sTitle,18), pd(sPanelTitle,14), pd(sCleanPanelNm,14) , sColors
End				


static constant	kWINDOWS_LIKE_BUTTON	= 1


Function		ccColorButtonProc( s )
	struct	WMCustomControlAction 	&s

// 050821  does not work
//	string  	sCtrlName	= GetUserData( 			s.win,  s.ctrlName,  "CtrlNm" )
//	print sCtrlName, s.ctrlName		// the same....
//return -1

	string		sProcNm	=  (s.ctrlName)[ strlen( ksPREFIX_CCBUT ) , Inf ]			// eliminate the leading  'ccb_'

	// The following variables are principally bad and fragile code as we have to store and retrieve them at appropriate times
	// The problem is that Igor sends a 'Draw' after 'Enter'  and  'Leave'  which in effect erases all previous changes drawn in 'Enter' or 'Leave' . Drawing in   'Enter' or 'Leave' works but additional offsets  s.ctrlRect.left  and  s.ctrlRect.top  are needed 
	// only  needed for  kWINDOWS_LIKE_BUTTON
	variable	nTextShift	= 0
	nvar	/Z	bOverControl	= root:uf:dlg:bOverControl
	if ( !nvar_Exists( bOverControl ) )
		variable	/G		   root:uf:dlg:bOverControl = FALSE
		nvar		bOverControl= root:uf:dlg:bOverControl
	endif
	nvar	/Z	bPressed		= root:uf:dlg:bPressed
	if ( !nvar_Exists( bPressed ) )
		variable	/G		   root:uf:dlg:bPressed	= FALSE
		nvar		bPressed 	= root:uf:dlg:bPressed
	endif
	svar  	/Z	sCtrlNm	= root:uf:dlg:sCtrlNm	
	if ( !svar_Exists( sCtrlNm ) )
		string  	/G		   root:uf:dlg:sCtrlNm	= ""
		svar  	sCtrlNm 	= root:uf:dlg:sCtrlNm	
	endif

	if ( s.eventCode == kCCE_mouseup )
		s.nVal	= mod( s.nVal + 1, 2 )		// switch between 2 states
		variable	xSize, ySize
		string  	lstTitles, lstColors, sTitle, sOneColor//, sColor0
		if ( kWINDOWS_LIKE_BUTTON )
			bPressed		= FALSE
		endif


	elseif ( s.eventCode == kCCE_mousedown )
		if ( kWINDOWS_LIKE_BUTTON )
			//s.needAction	= 1			// we want to redraw the control when the mouse moves across it
			bPressed		= TRUE
			sCtrlNm		= s.ctrlName
		endif
	elseif (  s.eventCode == kCCE_leave ) 
		if ( kWINDOWS_LIKE_BUTTON )
			s.needAction	= 1			// we want to redraw the control when the mouse moves across it
			bOverControl 	= FALSE
			//sCtrlNm		= ""
		endif
	elseif (  s.eventCode == kCCE_enter) 
		if ( kWINDOWS_LIKE_BUTTON )
			s.needAction	= 1			// we want to redraw the control when the mouse moves across it
			bOverControl	= TRUE
			sCtrlNm		= s.ctrlName
		endif


	elseif (  s.eventCode == kCCE_draw ) 
 		xSize		= s.ctrlRect.right - s.ctrlRect.left
 		ySize		= s.ctrlRect.bottom - s.ctrlRect.top  	
 		lstTitles 	= GetUserData( 			s.win,  s.ctrlName,  "titles" )
		lstColors 	= GetUserData( 			s.win,  s.ctrlName,  "colors" )
		sTitle		= StringFromList( s.nVal, lstTitles, ksTILDE_SEP )
		sOneColor	= StringFromList( s.nVal, lstColors, ksTILDE_SEP )
		
		SetDrawEnv  	linethick = 0 ,  fillfgc = ( str2num( StringFromList( 0, sOneColor, "," ) ), str2num( StringFromList( 1, sOneColor, "," ) ), str2num( StringFromList( 2, sOneColor, "," ) ) )
		DrawRect 		2, 1, xSize-2, ySize - 2				// the rectangle drawn covers only the interior of the button

		nTextShift	= 0
		if ( kWINDOWS_LIKE_BUTTON )
	
			// Problem: 		  We act only on a SINGLE PN_BUTCOL-control but Igor redraws ALL of them : this leads to an annoying flicker and also the original Igor rounded shaded button is restored, which is not intended 	
			// Workaround step1:  Cover ALL PN_BUTCOL-controls, not only the button where the mouse is over (better would be to inhibit Igors redrawing all...) 
			SetDrawEnv  	linethick = 1 ,  linefgc = ( 58000, 58000, 58000 ), fillfgc = ( str2num( StringFromList( 0, sOneColor, "," ) ), str2num( StringFromList( 1, sOneColor, "," ) ), str2num( StringFromList( 2, sOneColor, "," ) ) ) , save
			DrawRect   	0, 0, xSize,   ySize     				// the rectangle drawn covers the button completely
			//DrawRect   	1, 1, xSize-1, ySize - 1			// the rectangle drawn covers the most of the inside but leaves a margin
			//DrawRect   	1, 0, xSize-1, ySize - 1			// the rectangle drawn covers the most of the inside but leaves a margin
			//DrawRect   	2, 1, xSize-2, ySize - 2			// the rectangle drawn covers only the interior of the button
			if ( s.nVal )
				ColorButtonDrawLeftTop( xSize, ySize, 40000 )
				ColorButtonDrawRightBot( xSize, ySize, 60000 )
			else
				ColorButtonDrawLeftTop( xSize, ySize, 60000 )
				ColorButtonDrawRightBot( xSize, ySize, 40000 )
			endif
	
			// Workaround step2:  Redraw only the button where the mouse is over with special features (e.g. 3 dimensional shading...)
			if ( cmpstr( sCtrlNm, s.ctrlName ) == 0 )				// for unknown reasons  all controls are drawn without this code, so we must mask out all controls except the one we are interested in
				if ( bOverControl  &&  s.nVal )				// !!! this is bad and fragile code as we have to store and retrieve the control's (global) name at appropriate times
					sOneColor	= StringFromList( 0, lstColors, ksTILDE_SEP )
					SetDrawEnv  	linethick = 0 ,  fillfgc = ( str2num( StringFromList( 0, sOneColor, "," ) ), str2num( StringFromList( 1, sOneColor, "," ) ), str2num( StringFromList( 2, sOneColor, "," ) ) )
					DrawRect   	1, 1, xSize-1,   ySize-1     				// the rectangle drawn covers the most of the inside but leaves a margin
					ColorButtonDrawLeftTop( xSize, ySize, 20000 )
					ColorButtonDrawRightBot( xSize, ySize, 64000 )
				endif
				if ( bOverControl  &&  !s.nVal )
					ColorButtonDrawLeftTop( xSize, ySize, 64000 )
					ColorButtonDrawRightBot( xSize, ySize, 20000 )
				endif
				if ( bPressed )
					ColorButtonDrawLeftTop( xSize, ySize, 20000 )
					ColorButtonDrawRightBot( xSize, ySize, 64000 )
					nTextShift	= 1
				endif
			endif
		endif

		// The default font taken from 'Execute DefaultFont'  can be overridden by uncommenting the following line  
		// Execute "SetDrawEnv  	fname = " + ksFONT_			//  special syntax and formatting required e.g  ksFONT_ =  "\"Arial\""  or   "\"Ms Sans Serif\""
		DrawText 		3 + nTextShift, ySize - 2 + nTextShift, sTitle 		// TextShift  imitates the pressing of the button

	endif

	if (  s.eventCode != kCCE_idle  &&  s.eventCode != kCCE_mousemoved ) 
		// ??? This is executed even if other controls in other panels are clicked.......
		// printf "\tccColorButtonProc()\tV:%d\tO:%d\tP:%d\tEvent:%2d\t%s   \t%s\t%s\t%s \r", s.nVal,  bOverControl, bPressed, s.eventCode, pd( StringFromList( s.eventCode, lstEVENTCODES ), 8 ),  pd(s.win,8) , pd(s.ctrlName,24) , pd(sProcNm,24)  
	endif	

	FUNCREF   fCbbProc  fCbbPrc = $( sProcNm  )				//..
	fCbbPrc( s )										//..
	return 0
End

Static  Function	ColorButtonDrawLeftTop( xSize, ySize, nColor )
	variable	xSize, ySize, nColor
	SetDrawEnv  	linethick = 1 ,  linefgc = ( nColor, nColor, nColor ) , save
//	DrawLine		0,			0,				0,			ySize	   			// left	outer full	 	(linewidth=1)
//	DrawLine		0,			0, 				xSize,		0	   			// top	outer	 full	

	DrawLine		0,			1,				0,			ySize	-1   			// left	outer shorter	(linewidth=2)	
	DrawLine		1,			0, 				xSize-1,		0	   			// top	outer shorter		
	DrawLine		1,			1,				1,			ySize	-1   			// left	inner full	
	DrawLine		1,			1,				xSize-1,		1	   			// top	inner full		

End

Static  Function	ColorButtonDrawRightBot( xSize, ySize, nColor )
	variable	xSize, ySize, nColor
	SetDrawEnv  	linethick = 1 ,  linefgc = ( nColor, nColor, nColor ) , save
//	DrawLine		0,			ySize	-1,			xSize,		ySize-1			// bottom	outer full		(linewidth=1)
//	DrawLine		xSize	-1,		0,				xSize-1,		ySize				// right	outer full	

	DrawLine		1,			ySize	-1,			xSize-1,		ySize-1			// bottom	outer shorter	(linewidth=2)
	DrawLine		xSize	-1,		1,				xSize-1,		ySize-1			// right	outer shorter		
	DrawLine		0,			ySize	-2,			xSize,		ySize-2			// bottom	inner full			
	DrawLine		xSize	-2,		0,				xSize-2,		ySize				// right	inner full	
End

Function		fCbbProc( s )								// dummy function  prototype
	struct	WMCustomControlAction 	&s
End


Function		PanelColorField( c, ControlsInLine, nXpos,  nYpos, nXsize, nYsize, nOverSize, sCleanName, sFo_Name, sTitle, sColors, sPanelTitle )		// 040430  
// Color of a field and text AUTOMATICALLY changing dependent on a global variable ( using  CustomControl ) 
// In this approach color and titles are passed to the control.   A lot of code, many parameters and an action proc is needed but this approach is more flexible.
// Another approach:  make a pictures from the colors and the titles and pass the picture name. Shorter code, less parameters passed, no action proc   but   less flexible . Changing a picture is a mess.
	variable	c, ControlsInLine, nXpos,  nYpos, nXsize, nYsize, nOverSize
	string		sCleanName, sFo_Name, sTitle, sColors, sPanelTitle 
	variable	xPos, xSize
	string		sCleanPanelNm	= CleanupName( sPanelTitle, 0 )					// e.g. FPulse 2.22 -> FPulse222
	variable	nColors		= ItemsInList( sColors, ksTILDE_SEP )
	variable	nTitles		= ItemsInList( sTitle, ksTILDE_SEP )

	xPos		= nXPos + kXMARGIN/2 + 2 + c * nXSize / ControlsInLine + 6
	xSize		= nXSize * ( 1 + nOverSize ) 		     / ControlsInLine - 11
	string		    sCustomControlName	= "cc_" + sFo_Name			 		//  the name of the CustomControl  is 'cc_FolderVariableName'			

	CustomControl 	$sCustomControlName,	pos 	= { xPos, nYpos }, size={ 7,7 }	// omitting size or setting it to ( 0,0 ) does NOT work (fragments of a button will be drawn which must be covered by the rectangle drawn in the action proc)
	CustomControl 	$sCustomControlName,	proc	= ccColorFieldProc
	CustomControl	$sCustomControlName,	userdata( xsize ) = num2str( xSize )
	CustomControl	$sCustomControlName,	userdata( ysize ) = num2str( nYsize )
	CustomControl	$sCustomControlName,	userdata( titles )	 = sTitle
	CustomControl	$sCustomControlName,	userdata( colors ) = sColors
	CustomControl	$sCustomControlName,	value		  = $sCleanName

	// printf "\t\tPN_DICOLTXT nCo:%d   nTi:%d  nOverSize:%2d  ccCoNm:'%s'  CleanNm:'%s' \tFo_Nm:'%s' \tTitle:%s \tPT:%s\t-> %s\tColors:'%s' \r", nColors, nTitles, nOverSize, sCustomControlName, sCleanName, sFo_Name, pd(sTitle,18), pd(sPanelTitle,14), pd(sCleanPanelNm,14) , sColors
End				


Function	/S	StringFromksTILDE_SEParatedList( nIndex, sList )
	variable	nIndex
	string		sList
	return	StringFromList( nIndex, sList,  ksTILDE_SEP )
End




////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//   CONTEXT SENSITIVE HELP  =   AUTOMATICALLY  CONNECTING  CONTROLS TO HELP TOPICS

// 2009-12-10	In EVAL  and in ACQ  there is still a common data folder 'dlg'  .  Unfortunately it seems not easy to distribute to  'aco' and 'evo' ...

Function		DisplayHelpTopicFor( sControlNm )
// displays help topic when control name is given. The control and the help topic must already have been connected...
// ..either by  'ConnectControlToHelpTopic()'  or manually by 'SetHelpTopicToButtonLinks()'
	string		sControlNm
	variable	nHelpIndex
	string		sHelpTopic
	nvar		gbHelpMode	= $(ksDF_DLG + "gbHelpMode" )
	svar		gsHelpLinks	= $(ksDF_DLG + "gsHelpLinks") 
	if ( gbHelpMode )
		nHelpIndex = WhichListItem( sControlNm, gsHelpLinks )
		if ( nHelpIndex != kNOTFOUND )
			sHelpTopic = StringFromList( nHelpIndex + 1, gsHelpLinks )
			// printf "\t\tControl '%s' has help link '%s' .\r", sControlNm, sHelpTopic
			FDisplayHelpTopic( sHelpTopic )
		else
			printf "***Control '%s' has not yet a help link.\r", sControlNm
		endif
	endif
	//MoveWindow  /P=FPulse 0, 0, 300, 400 
End


Function		 ConnectControlToHelpTopic( sCleanName, sPanelTitle, sTitle )
// automatically establishes the connection between any control and its corresponding help topic in stringlist 'gsHelpLinks'
// truncates variable name after 32 characters (Igors limit)
	string		sCleanName, sPanelTitle, sTitle 
	//svar  	gsHelpLinks		= root:uf:dlg:gsHelpLinks
	//nvar  	gbHelpConnShow	= root:uf:dlg:gbHelpConnShow
	svar		gsHelpLinks		= $(ksDF_DLG + "gsHelpLinks") 
	nvar		gbHelpConnShow	= $(ksDF_DLG + "gbHelpConnShow")
	string		sTopicSubtopic	= sPanelTitle + "[" + sTitle + "]"		// use Igors  Topic[Subtopic]  syntax
	sCleanName = sCleanName[ 0, 31]
	if ( WhichListItem( sCleanName, gsHelpLinks ) == kNOTFOUND ) 	// the connection may already exist if a panel has been closed and is reopened now: don't connect twice	
		gsHelpLinks = AddListItem( sCleanName + ";" + sTopicSubtopic, gsHelpLinks )	// another approach (not taken): remove connection when closing a panel
		if ( gbHelpConnShow )
			// printf "\t\tConnectControlToHelpTopic()  n:%2d \tlen:%4d\t%s  \t-> '%s' \r", ItemsInList(gsHelpLinks)/2,strlen( gsHelpLinks ),pd(sCleanName,30) , sTopicSubtopic
		endif
	endif
End




////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	FUNCTION	PROTOTYPES  and  DUMMY  FUNCTIONS

// 041101
Function		fButtonProc_struct( s )
// Called when a button is pressed.  ALSO CALLED when moving the mouse over a button: can be used to colorise the button......
	struct	WMButtonAction	&s
	string		sControlNm	= s.ctrlname
	//	if (  s.eventCode != kCCE_idle  &&  s.eventCode != kCCE_mousemoved ) 
	//		printf "\tfButtonStructProc() \tEvent:%2d\t%s   \t%s\t%s\tsecs:%d \r", s.eventCode, pd( StringFromList( s.eventCode, lstEVENTCODES ), 8 ),  pd(s.win,8) , pd(s.ctrlName,24), mod( DateTime,10000),
	//	endif	
// 2009-10-24
//	if (  s.eventCode != kCCE_idle  &&  s.eventCode != kCCE_mousemoved  &&  s.eventCode != kCCE_leave  &&  s.eventCode != kCCE_enter  &&  s.eventCode != kCCE_mouseup ) 
	if (  s.eventCode == kCCE_mouseup ) 
		// printf "\tfButtonStructProc() \tEvent:%2d\t%s   \t%s\t%s \r", s.eventCode, pd( StringFromList( s.eventCode, lstEVENTCODES ), 8 ),  pd(s.win,8) , pd(s.ctrlName,24) 
		DisplayHelpTopicFor( sControlNm )
		FUNCREF   fBuProc_struct  fBuPrc = $( sControlNm  )		// the default action proc has the same name as the button
		fBuPrc( s )										//..
	endif
End

Function		fBuProc_struct( s )							// dummy function  prototype
	struct	WMButtonAction	&s
End


Function		fButtonProc( sControlNm )
	string		sControlNm
	// printf "\t\tButton '%s' has been pressed...\r", sControlNm
	DisplayHelpTopicFor( sControlNm )
	FUNCREF   fBuProc  fBuPrc = $( sControlNm  )				// the default action proc has the same name as the button
	fBuPrc( sControlNm )									//..
End

Function		fBuProc( ctrlName )							// dummy function  prototype
	string		ctrlName
End


Function		fBuTitle( ctrlName )							// dummy function  prototype
	string		ctrlName
End

Function		fPopupListProc( sControlNm )						//..
// needed to get the listbox entries from a function with auto-built name. This is the generalized...
//...form of the much simpler but limited call ' PopupMenu $sName, value = "Item1;Item2;..." '
	string		sControlNm 							
End


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	COMMON  PN_RADIO  BUTTON  FUNCTIONS

Function		PnControlTab( tPn, n, bState, sName, sTabsTitle, lstTabs, sTabControlEntries, sF )
// 050222 Introduced separate horizontal controls ( and additionally needing: hg, nHorzGroups, sTCEntryH, ksTAB_H_SEP )  
	// todo:  Generalize for Radios, popups etc...
	wave   /T	tPn
	variable	n, bState
	string		sName, sTabsTitle, lstTabs, sTabControlEntries, sF
	variable	nTcEntry, nTabControlEntries	= ItemsInList( sTabControlEntries, ksTAB_V_SEP )
	string  	sTcEntry, sTcEntryH, sTyp, sTit, sVarNm, sItems
	variable	nHV, hg, nHorzGroups
	string	  	lstTabsComma	= ReplaceString( ";" ,  lstTabs, ksTAB_SEP )			// new separator  °  as we cannot use  semicolon  as this is the  tPanel separator
	variable	nTabs		= ItemsInList( lstTabs )	
	variable 	nOld			= n
	variable	nScreenLines	= 0, nArrayLines = 0
	string	  	lstAllVars	= ""												// sAllVars is needed  in the TabControl action proc for showing and hiding the tabs
	string	  	lstAllItems	= ""												// sAllVars is needed  in the TabControl action proc for showing and hiding the tabs

	for ( nTcEntry = 0; nTcEntry < nTabControlEntries; nTcEntry += 1 )
		sTcEntry	= StringFromList( nTcEntry, sTabControlEntries, ksTAB_V_SEP )

		//050222
		nHorzGroups	= ItemsInList( sTCEntry, ksTAB_H_SEP )
		for ( hg = 0; hg < nHorzGroups; hg += 1 )
		  	sTcEntryH	= StringFromList( hg, sTcEntry, ksTAB_H_SEP )
			sTyp		= RemoveWhiteSpace( StringFromList( 0, sTcEntryH, ksTILDE_SEP ) )
			nHV		= str2num( RemoveWhiteSpace( StringFromList( 1, sTcEntryH, ksTILDE_SEP ) ) )
			sTit		= StringFromList( 2, sTcEntryH, ksTILDE_SEP ) 
			sVarNm	= StringFromList( 3, sTcEntryH, ksTILDE_SEP ) 
			lstAllVars	= AddListItem( sVarNm, lstAllVars, ksTILDE_SEP, Inf )								// any separator except _ ; | ° ^
			sItems	= StringFromList( 4, sTcEntryH, ksTILDE_SEP ) 
			lstAllItems	= AddListItem( ReplaceString( ";", sItems, ksTAB_SEP), lstAllItems, ksTILDE_SEP, Inf )		// any separator except _ ; | ° ^
		endfor
		nScreenLines	+=  ( nHV == kVERT ? ItemsInList( sItems ) : 1 ) + (strlen( RemoveWhiteSpace( sTit ) ) > 0) 
		// printf "\tPnControlTab( '%s' \tnTc:%d/%d\t %s\tHG:%d/%d\tnHV:%2d\tnScLn:%2d\tVN:\t%s\tItm:\t%s\tAIt:\t%s\tAV:\t%s\t\r",  sName, nTcEntry, nTabControlEntries,  pd(sTyp,13),  hg, nHorzGroups, nHV, nScreenLines, pd(sVarNm,19), pd(sItems,19), pd( lstAllItems,26 ), lstAllVars
	endfor
	variable	nTabControlYSize	= nScreenLines * ( kYHEIGHT + kYMARGIN ) + kTABCONTROL_EXTRAY	
	// printf "\tPnControlTab( '%s'     '%s'     '%s'     [ -> %s]  \r",  sName, sTabsTitle , lstTabs, lstTabsComma	
	
	if ( strlen( sTabsTitle ) )
		nOld += 1					//  directly counting  'n'  as it is done with all other controls will fail with TabControls
		n += 1;	tPn[ n ] 	=	"PN_SEPAR; ; " + sTabsTitle 															// sTabsTitle is handled outside a tabcontrol as it does not work within a TabControl...
	endif
	n += 1;		tPn[ n ] 	=	"PN_TABCTRL;" + sName + ";" + lstAllVars + ";" + lstAllItems + ";" + lstTabsComma + ";" + num2str( nTabControlYSize )// lstAllVars and lstAllItems are needed  in the TabControl action proc for showing and hiding the tabs
	nArrayLines	= nOld + 1			// 1 is for the line with the tabs
	// printf "\tPnControlTab( '%s' ) -> '%s' \r", sName, tPn[ n ]

	for ( nTcEntry = 0; nTcEntry < nTabControlEntries; nTcEntry += 1 )
		sTcEntry	= StringFromList( nTcEntry, sTabControlEntries, ksTAB_V_SEP )

		//050222
		nHorzGroups	= ItemsInList( sTCEntry, ksTAB_H_SEP )
		sItems	= ""
		for ( hg = 0; hg < nHorzGroups; hg += 1 )
		  	sTcEntryH	= StringFromList( hg, sTcEntry, ksTAB_H_SEP )
			sTyp		= RemoveWhiteSpace( StringFromList( 0, sTcEntryH, ksTILDE_SEP ) )
			nHV		= str2num( RemoveWhiteSpace( StringFromList( 1, sTcEntryH, ksTILDE_SEP ) ) )
			sTit		= StringFromList( 2, sTcEntryH, ksTILDE_SEP ) 
			sVarNm	= StringFromList( 3, sTcEntryH, ksTILDE_SEP ) 
			sItems	+= StringFromList( 4, sTcEntryH, ksTILDE_SEP )											// as we are a TabControl we pass "" rather than 'sTabsTitle' which does not work anyway
			if ( hg > 0  &&  hg < nHorzGroups - 1 )
				sItems	+= ";"
			endif
// 050223  for PN_POPMENU
//			sItems	+= RemoveWhiteSpace( StringFromList( 5, sTcEntryH, ksTILDE_SEP )	)		//   for PN_POPMENU  the action proc name   AFTER the TitleProc

		endfor

		nArrayLines	+=  nTabs *  ( nHV == kVERT ? ItemsInList( sItems ) : 1 ) + (strlen( RemoveWhiteSpace( sTit ) ) > 0) 	// ...and we pass kWIDTH_SLIM rather than kWIDTH_NORMAL
		// printf "\tPnControlTab( '%s'  '%s'  '%s'  [~%s] )  nTcEntry:%d\t ->\t%s\t  nHV:%d \t%s\t%s\t%s\t '%s'  \r",  sName, sTabsTitle , lstTabs, lstTabsComma, nTcEntry, pd(sTyp,12), nHV, pd(sVarNm,23), pd(sItems,23), lstAllItems, sTit

		n = PnControl(	tPn, n, 2, bState, 	sTyp, nHV,  sTit, sVarNm, sItems, "", lstTabs , kWIDTH_SLIM, sF )			// as we are a TabControl we pass PN_CHKBOXT rather than PN_CHKBOX
	endfor
	return	nArrayLines			//  directly counting  'n'  as it is done with all other controls will fail with TabControls
End

// How to use  PnControl()
// 1. sType = "PN_RADIO"  or   "PN_CHKBOX"      and    sSubHelpTopic :
// 	if sSubHelpTopic is not empty it is used 
//	if sSubHelpTopic is empty   sSepText is used instead 
//	if sSepText is empty (=no whiteSpaces)  then main Helptopic will be used
//	if sSepText has  whiteSpaces then no helptopic will be found and an error will be flagged (to be avoided)
// 2. sType = "PN_RADIO"      and    sProc :	(multiple buttons)
//	...........no .................if the sProc field is not  empty it will be used ( the standard  Check/uncheck proc must explicitly be called!)
//	if the sProc field  is empty  and  if  the single auto-built-name  (built from base name!)  procedure exists  the latter will be executed automatically calling the standard  Check/uncheck proc
//	if the sProc field  is empty  and  if  the auto-built-name  procedure does not exist either  only the standard  Check/uncheck proc will be executed
// 3. sType = "PN_CHKBOX"      and    sProc :	(multiple buttons e.g. gbStimDac0, gbStimDac1 ) 
//	..........no.....................if the sProc field is not  empty it will be used ( the standard proc  'fChkbox1Dim...2Dim'  must explicitly be called!)
//	if the sProc field  is empty  and  if  the single auto-built-name  (built from base name!)  procedure exists  the latter will be executed automatically 
//	if the sProc field  is empty  and  if  the auto-built-name  does not exist only the standard proc  'fChkbox1Dim...2Dim' will be executed
// 4. sType = "PN_CHKBOX"      and    sProc :	( single buttons )
//	...........no...................if the sProc field is not  empty it will be used ( the standard  proc  'fChkBox'  must explicitly be called!)
//	if the sProc field  is empty  and  if  the auto-built-name  (built from FULL name) procedure exists  the latter will be executed automatically calling the standard  Check/uncheck proc
//	if the sProc field  is empty  and  if  the auto-built-name  procedure does not exist either  only the standard   proc  'fChkBox'  will be executed


Function		PnControl(  tPanel, n, nDims, bState, sType2,  VertOrCnt2, sSepText, sFolderVarNmBase, sTitleListHV, sSbHelpT, sTitleList, nkWidth, sF ) 
// Special version of PnContrl( )  extended to 2 dimensions = 2 levels of PnControl()  nested 
//  PnContrl( ) 	adds a number of vertical  or horizontal  radio buttons  (=PN_RADIO)  or checkboxes  (=PN_CHKBOX)  to a control panel.  
//  PnControl() 	adds a number of lines to a panel (like PnContrl( 1.dim) limited to VERT mode) , each line consists of another PnContrl( 2.dim) adding multiple vertical  or horizontal  radio buttons  (=PN_RADIO)  or checkboxes  (=PN_CHKBOX)  to a control panel.  
// So : the outer level is the usual PnContrl( ) limited to vertical mode whose parameters are passed first. The inner PnContrl( ) is a full sized version whose parameters are passed last.
	wave   /T	tPanel
	variable	n, nDims, bState, VertOrCnt2				// 0 : draw 2.dim (=inner level)  vertically. Number > 0 means draw so many items horizontally.
	variable	nkWidth								// 0 is slim (only for 2 dims, only for TABCONTROLs): omit both array dimensions as they are in the tabs , 1 is normal = only for 2 dims = omit the 1. array dimension , 2 is wide = only for 2 dims
	string		sType2, sSepText, sFolderVarNmBase, sTitleListHV, sSbHelpT, sTitleList, sF
	string		sTitle, sTitleHV, sFullTitle, sVarNm, sProc	
	string		sItemSep 	= 	SelectString( VertOrCnt2 == kVERT, "|" , "" )
	variable	h, i, j, cnt, cntHV, nLineIdx	= -1 				// 040221 if there are no items, draw no line

	// print "\t\tPnControl(a)", n, nDims, bState, sType2,  VertOrCnt2, sSepText, sFolderVarNmBase, sTitleListHV, sSbHelpT, sTitleList, nkWidth, sF 

	sSbHelpT	= Selectstring( strlen( RemoveWhiteSpace1( sSbHelpT ) ), sSepText, sSbHelpT )	// if helptopic is missing use sSepText as helptopic (sSepText should not consist of whitespace)
// does not work: the auto-build proc (whose name is built HERE)  MUST exist, if not an error is issued.  It may be missing if the name is built in fRadio or fChkbox
// print"\t\tPnContrl( )",sProc
//	sProc	= Selectstring( strlen( RemoveWhiteSpace( sProc ) ), sFolderVarNmBase+"", sProc )// if procedure is missing auto-build a procedure name
// print"\t\tPnContrl( ) \t\t\t->\t ",sProc
	
	// insert a separator line between vertical entries
	n 	= PnSeparator( tPanel, n, sSepText  ) 

	cnt 	=    nDims == 1	?   1	:  ItemsInList( sTitleList )			//  if TitleList is empty then assume 1 entry if it is a  1-dimensional control, but assume NO entry if it is a 2-dimensional control
	for ( i = 0; i < cnt;  i += 1 )								// 050223 if sType2 == PN_POPUP  then  1 function name is passed instead of  sTitleList !!!
		sTitle	= StringFromList( i, sTitleList ) 		
		j	= 0
		nLineIdx	=  VertOrCnt2 == kVERT  ?  i * ItemsInList( sTitleListHV) + j  :  i
		tPanel[ n + nLineIdx + 1 ]  = "" 													// clear line (1. dim is always in vertical mode) 

		// Sample taken from OLA panel showing the effect of  nkWidth
		//			nkWidth =  kWIDTH_WIDE									nkWidth =  kWIDTH_NORMAL
		//  kWIDTH_NORMAL does not save space when in 1 dimensional mode
		// 	| X Axis							   |				> > >		| X Axis										|		
		// 	| o frames		o seconds		o minutes	   |				> > >		|			o frames		o seconds		o minutes	| 
	
		// kWIDTH_NORMAL  does not save space when using only 2  horizontal entries in 2 dimensional mode (but still the panel is better readable)
		// 	| o Adc0 Peak Up	o Adc0 Peak Down |					> > >		| Adc0 Peak o Up		o Down		|		
		// 	| o Adc1 Peak Up	o Adc1 Peak Down |					> > >		| Adc1 Peak o Up		o Down		|
	
		// kWIDTH_NORMAL  does save space when using 3 or more horizontal entries in 2 dimensional mode
		// 	| o Adc0 Peak Up	o Adc0 Peak Down	o Adc0 Peak Both |	> > >		| Adc0 Peak o Up		o Down		o Both		|
		// 	| o Adc1 Peak Up	o Adc1 Peak Down	o Adc1 Peak Both |	> > >		| Adc1 Peak o Up		o Down		o Both		|

		// kWIDTH_SLIM      is for   TabControls only.  TabControls always have 2 dimensions  and  the selected  item is shown in the tab so we can omit it in the control. We even MUST omit it as initially they are all drawn (none hidden) on top of each other
		// 	| o Adc0 Peak Up	o Adc0 Peak Down	o Adc0 Peak Both |	> > >		|  o Up		o Down		o Both		|

		if ( nkWidth == kWIDTH_NORMAL  && nDims == 2 )
			tPanel[ n + nLineIdx + 1 ]  = "PN_SEPHORZ;	;" + sTitle + "; |" 						// clear line (1. dim is always in vertical mode) 
		endif
		if ( nkWidth == kWIDTH_SLIM  && nDims == 2 )
			tPanel[ n + nLineIdx + 1 ]  = "" 													// clear line (1. dim is always in vertical mode) 
		endif
		cntHV	= ItemsInList( sTitleListHV )
		for ( j = 0; j < cntHV; j += 1 )
			nLineIdx	=  VertOrCnt2 == kVERT  ?  i * ItemsInList( sTitleListHV) + j  :  i
			tPanel[ n + nLineIdx + 1 ]  = SelectString(  VertOrCnt2 == kVERT, tPanel[ n + nLineIdx + 1 ], "" )	// clear line (only in vertical mode) before first entry is appended below

			sTitleHV	= StringFromList( j, sTitleListHV )
			sFullTitle	= sTitle + ksTITLEBLANK +  sTitleHV					// the checkbox or radio button title as displayed in the panel may contain blanks to improve readability
			if ( nkWidth <= kWIDTH_NORMAL  && nDims == 2 )
				sFullTitle	= sTitleHV									// ..has no 1. title and no blank before the 2. title
			endif
			if ( nDims == 1 )											// only 1-dimensional control .. 
				sFullTitle	= sTitleHV									// ..has no 1. title and no blank before the 2. title
			endif

			if ( cmpstr( sType2, "PN_CHKBOX" ) == 0  ||  cmpstr( sType2, "PN_CHKBOXT" ) == 0 )
				sProc  = SelectString( nDims - 1, "fChkbox1Dim" , "fChkbox2Dim" )					// all checkbox controls of a group share a single auto-named action procedure..	// ...e.g.  root_uf_stimDsp_gbstim_Dac0  and  root_uf_stimDsp_gbstim_Dac0  may have the proc root_uf_stimDsp_gbstim() 
				sVarNm	= ChkBoxVarNm( nDims,  sFolderVarNmBase, sTitle, RemoveWhiteSpace1(sTitleHV) )
				PossiblyBuild1SubFolderAndVar( sVarNm , TRUE, bState )
			elseif (cmpstr( sType2, "PN_RADIO" ) == 0  ||  cmpstr( sType2, "PN_RADIOT" ) == 0 ) 	
				sProc  = SelectString( nDims - 1, "fRadio1Dim" , "fRadio2Dim" )						//all   radio   controls of a group share a single auto-named action procedure..
				sVarNm	= RadButVarNm( nDims, j, sFolderVarNmBase , sTitle, ItemsInList( sTitleListHV ) ) // double indexing: the 1.dim of 2  is stored in the base name,  thus the old functions processing only 1 dim can be used
			elseif (cmpstr( sType2, "kRADIO" ) == 0  ||  cmpstr( sType2, "kRADIOT" ) == 0 ) 
				sProc  = SelectString( nDims - 1, "fRadio1Dim_struct" , "fRadio2Dim_struct" )			//all   radio   controls of a group share a single auto-named action procedure..
				//sVarNm	= RadButVarNm( nDims, j, sFolderVarNmBase , sTitle, ItemsInList( sTitleListHV ) ) 	// double indexing: the 1.dim of 2  is stored in the base name,  thus the old functions processing only 1 dim can be used
				sVarNm	= ksROOTUF_ +  sF + ":"  + RadButVarNm( nDims, j, sFolderVarNmBase , sTitle, ItemsInList( sTitleListHV ) ) 	// double indexing: the 1.dim of 2  is stored in the base name,  thus the old functions processing only 1 dim can be used
			endif

//// 050223
////			if (cmpstr( sType2, "PN_POPUP" ) != 0 ) 	// for all  the  RADIO   and  CHECKBOXES   above
				tPanel[ n + nLineIdx + 1 ]   +=  sType2 + ";" + sVarNm + ";" + sFullTitle + ";  ;  ;" + num2str( ItemsInList(sTitleListHV) )  + ";" + sProc  + ";" + sSbHelpT  + sItemSep	// we pass the number of dim1 entries in the sLim field  as the tabcontrol needs it
				// printf "\t\tPnControl(c)  i:%d, n:%2d  + LineIdx:%d + 1 = %2d\tLen:%3d \tsVarNm:\t%s\t%s \r", i, n, nLineIdx, n+nLineIdx+1, strlen( tPanel[ n + nLineIdx + 1 ] ),  pd(sVarNm,33),  (tPanel[ n + nLineIdx + 1  ])[0,200]
////			endif
//
//// 050223
//			if (cmpstr( sType2, "PN_POPUP" ) == 0 ) 
////				sProc		= StringFromList( 5, sTitleListHV )
//				
//				sProc  = SelectString( nDims - 1, "pmPopTest" , "pmPopTest" )									// TODO..........
//				sVarNm	= ChkBoxVarNm( nDims,  sFolderVarNmBase, sTitle, "" )//RemoveWhiteSpace1(sTitleHV) )	// TODO..........
//				sVarNm	= RemoveEnding( ChkBoxVarNm( nDims,  sFolderVarNmBase, sTitle, "" ), "_" )//RemoveWhiteSpace1(sTitleHV) )	// TODO..........
//				PossiblyBuild1SubFolderAndVar( sVarNm , TRUE, bState )
//				tPanel[ n + nLineIdx + 1 ]   +=  sType2 + ";" + sVarNm + ";  ; 80 ;  ;" + sFullTitle + "; " + sProc + ";" + sItemSep	// we pass the  name of the function which returns the list of entries  in the sLim field  as the tabcontrol needs it
//				// printf "\t\tPnControl(d)  i:%d, n:%2d  + LineIdx:%d + 1 = %2d\tLen:%3d \tsVarNm:\t%s\t%s \r", i, n, nLineIdx, n+nLineIdx+1, strlen( tPanel[ n + nLineIdx + 1 ] ),  pd(sVarNm,33),  (tPanel[ n + nLineIdx + 1  ])[0,200]
//			endif
		endfor	



		// possibly add horizontal empty items so that horizontal entries do not necessarily take up all space but can be made smaller  
		for ( h = cntHV; h < VertOrCnt2; h += 1 ) 
			tPanel[ n + nLineIdx + 1 ]  +=	"PN_SEPHORZ |"
		endfor

//		if ( cmpstr( sType2, "PN_RADIO" ) == 0  ||  cmpstr( sType2, "PN_RADIOT" ) == 0 )	
		if ( cmpstr( sType2, "PN_RADIO" ) == 0  ||  cmpstr( sType2, "PN_RADIOT" ) == 0  ||  cmpstr( sType2, "kRADIO" ) == 0  ||  cmpstr( sType2, "kRADIOT" ) == 0 )	
			PossiblyBuild1SubFolderAndVar( sVarNm , FALSE, bState )			// do NOT build the variable and ignore  'bState'
			string	  	sRadioButtonBaseNm =  RadioButtonBaseName( sVarNm )	// construct the one and only radio button group variable..
			variable /G $sRadioButtonBaseNm							// ..by including folder, name base and name parts built from list entries..
			nvar	 tmp =  $sRadioButtonBaseNm							// ..strip only trailing radio button index and radio button count
			if ( ! nvar_exists( tmp ) )
				printf "Internal error: PnControl( )    Radio ( not CB )  button  \t\t\tsVarNm:\t%s\tconstructing global:\t%s FAILED ! \r",  pd(sVarNm,33), pd(sRadioButtonBaseNm,23)
			endif
			// !!! sRadioButtonBaseNm  remembers its last state (= which is the 'ON' radio button) . It is not reset by loading a script , clearing the graph..etc. This is a feature, but can lead to confusion...
			// printf "\t\tPnControl( )    Radio ( not CB )  button  \t\t\tsVarNm:\t%s\tconstructing global:\t%s\tand set to: %d \r",  pd(sVarNm,33), pd(sRadioButtonBaseNm,23),  tmp
		endif
	endfor												

	return	n  + nLineIdx +1		
End


Static  Function		PossiblyBuild1SubFolderAndVar( sVarNm , bBuildVariable, bState )
// the folder above the one to be constructed must exist already. Could be extended to construct nested folders...
	string  	sVarNm
	variable	 bBuildVariable, bState							// build folder AND variable for checkbox, but for radio button only the folder
	if ( Exists( sVarNm ) != 2 ) 									// does the variable or string including folder already exist ?
		variable	nSubFolders	= ItemsInList( sVarNm, ":" ) -1
		string  	sF		= RemoveListItem( nSubFolders, sVarNm, ":" )
		sF	= sF[ 0, strlen( sF ) - 2 ]
		string		sDFSave	= GetDataFolder( 1 )					// The following functions do NOT restore the CDF so we remember the CDF in a string .
		NewDataFolder  /O  /S $sF							// make a new data folder and use as CDF,  clear everything
		SetDataFolder sDFSave								// Restore CDF from the string  value
 		if ( bBuildVariable )
	 		variable /G $sVarNm = bState						// dynamically construct the multiple checkbox variables all in  'bState'   (sVarNm contains folderpath)
			nvar	/Z newVar	= $sVarNm
			// printf "\t\tPnControl(1)    PossiblyConstruct1SubFolder( \t\tsVarNm:\t%s\t)  \tconstructing folder:\t%s \tbBuildVariable: %d \texists: %d   value = %.1lf  =?= %d \r",  pd(sVarNm,29), pd(sF,22), bBuildVariable, nvar_exists( newvar ), newvar, bState
		else
			// printf "\t\tPnControl(2)    PossiblyConstruct1SubFolder( \t\tsVarNm:\t%s\t) \tconstructing folder:\t%s \tbBuildVariable: %d \r",  pd(sVarNm,29), pd(sF,22), bBuildVariable
		endif
	endif
End

// must be Interface : is being used once in  'Recipes.ipf'
Function	/S	ChkBoxVarNm( nDims, sFolderVarNmBase, sTitle, sTitleHV )
//Static Function	/S	ChkBoxVarNm( nDims, sFolderVarNmBase, sTitle, sTitleHV )
	string		sFolderVarNmBase, sTitle, sTitleHV
	variable	nDims
	string  	sChkBoxVarNm
	if ( nDims == 1 )
		sChkBoxVarNm	= sFolderVarNmBase + ":" + sTitleHV
	else
		sChkBoxVarNm	= sFolderVarNmBase + ":"  + RemoveWhiteSpace1( sTitle ) + ksRADIOSEP + sTitleHV
	endif
	// printf "\t\t\tChkBoxVarNm( \tdim: %d\t\t\t%s\t%s\t%s)\t-> \t%s \r",  nDims, pd(sFolderVarNmBase, 22),  pd( sTitle,21), pd(sTitleHV,9), pd(sChkBoxVarNm,27) 
	return	sChkBoxVarNm
End


Static Function	/S	RadButVarNm( nDims, i, sFolderVarNmBase, sVTitle, cnt )
	string		sFolderVarNmBase, sVTitle
	variable	nDims, i, cnt
	string  	sRadButVarNm
	if ( nDims == 1 )
		sRadButVarNm	 = sFolderVarNmBase +  ksRADIOSEP + num2str( i ) + ksRADIOSEP + num2str( cnt )	
	else
		sRadButVarNm	 = sFolderVarNmBase +  ":" + RemoveWhiteSpace1( sVTitle ) + ksRADIOSEP + num2str( i ) + ksRADIOSEP + num2str( cnt )	
	endif
	// printf "\t\t\tRadButVarNm( \tdim: %d \ti:%d/%d\t%s\t%s )\t-> \t%s \r", nDims, i, cnt, pd( sFolderVarNmBase, 22) , pd( sVTitle, 7) , sRadButVarNm
	return	sRadButVarNm
	//return	sFolderVarNmBase +  ksRADIOSEP + num2str( i ) + ksRADIOSEP + num2str( cnt )	//!Assumption : MY RADIO INDEXING...............
End	


Function		fPopup( sControlNm, popNum, popStr ) : PopupMenuControl
// executed when the user selected an item from the listbox
	string		sControlNm, popStr
	variable	popNum
	nvar		value	= $ReplaceString( ksRADIOSEP, sControlNm, ":" )		// e.g. root_uf_evo_evl_gpopupVar -> root:uf:evo:evl:gpopupVar
	value	= popNum - 1
	// printf "\t\tfPopup :\t'%s' has been set to %d... \t[will call proc if found: '%s()'\tHelp: '%s' ]\r", sControlNm, popNum, sControlNm, sControlNm

// 030303 help implemented like Checkbox but not tested......
	DisplayHelpTopicFor( sControlNm )							//  should work for both a checkbox and a popupmenu
	FUNCREF   fCbProc  fCbPrc = $( sControlNm )					// after  (possibly) displaying  this listbox's helptopic... 
	fCbPrc( sControlNm, Value )								// ..execute the action procedure (if there is one defined, it can also be missing) 
End

Function		fChkbox1Dim( sControlNm, Value )
// 0403012 allows all checkbox controls of a 2 dimensional group to share a single auto-named action procedure e.g.  root_uf_stimDsp_gbstim_Dac0  and  root_uf_stimDsp_gbstim_Dac1  have the proc root_uf_stimDsp_gbstim() // 
	string		sControlNm
	variable	Value
	variable	nDims	= 1
	fChkbox12Dim( sControlNm, Value, nDims )
End

Function		fChkbox2Dim( sControlNm, Value )
// 0403012 allows all checkbox controls of a 2 dimensional group to share a single auto-named action procedure e.g.  root_uf_stimDsp_gbstim_Dac0  and  root_uf_stimDsp_gbstim_Dac1  have the proc root_uf_stimDsp_gbstim() // 
	string		sControlNm
	variable	Value
	variable	nDims	= 2
	fChkbox12Dim( sControlNm, Value, nDims )
End

Static Function		fChkbox12Dim( sControlNm, Value, nDims )
// 0403012 allows all checkbox controls of a 2 dimensional group to share a single auto-named action procedure e.g.  root_uf_stimDsp_gbstim_Dac0  and  root_uf_stimDsp_gbstim_Dac1  have the proc root_uf_stimDsp_gbstim() // 
	string		sControlNm
	variable	Value, nDims
	string 	sProc
	variable	NmPartCnt	  = ItemsInList( sControlNm, ksRADIOSEP )			// split into folder, base name part, specific name part  (e.g.  root_uf_stimDsp_gbstim_Dac0 )

	sProc	= RemoveListItem( NmPartCnt - 1 , sControlNm, ksRADIOSEP  ) 	// 	remove everything behind the last  '_' 
	if ( nDims == 2 )
		sProc	= RemoveListItem( NmPartCnt - 2 , sProc, ksRADIOSEP )	// 	remove everything behind the pre last  '_' 
	endif
	sProc	= sProc[ 0, strlen( sProc ) - 2 ]							// remove trailing separator '_'   e.g  root_uf_stimDsp_gbstim
	// printf "\t\tfChkbox12Dim(   dim: %d\t%s )\t->\t%s\t[ will call if found: %s\tHelp: '%s' ]\r",nDims,  pd(sControlNm,26), pd(sProc,20), pad(sProc+"()",20), sControlNm
	
	DisplayHelpTopicFor( sControlNm )								// after  (possibly) displaying  this checkbox's helptopic... 
	FUNCREF   fCbProc  fCbPrc = $( sProc )							// ..
	fCbPrc( sControlNm, Value )									// ..execute the action procedure (if there is one defined, it can also be missing) 
End


// 041101
Function		fChkbox_struct( s )
	struct	WMCheckboxAction	&s
	 printf "\t\tfChkbox_struct :  \t%s\thas been set to %d... \t\t[will call if found: %s \tHelp: '%s' ]\r", pd(s.CtrlName,26), s.checked, pd(s.CtrlName+"()",26),  s.CtrlName
	DisplayHelpTopicFor( s.CtrlName )							//  should work for both a checkbox and a popupmenu 
	FUNCREF   fCbProc_struct  fCbPrc = $( s.CtrlName ) 					// after  (possibly) displaying  this checkbox's helptopic...
	fCbPrc( s )								// ..execute the action procedure (if there is one defined, it can also be missing) 
End

Function		fCbProc_struct( s )							// dummy function  prototype
	struct	WMCheckboxAction	&s
End



Function		fChkbox( sControlNm, Value )
	string		sControlNm
	variable	Value
	// printf "\t\tfChkbox :  \t%s\thas been set to %d... \t[will call if found: %s \tHelp: '%s' ]\r", pd(sControlNm,26), Value, pd(sControlNm+"()",26),  sControlNm

	DisplayHelpTopicFor( sControlNm )							//  should work for both a checkbox and a popupmenu 
	FUNCREF   fCbProc  fCbPrc = $( sControlNm ) 					// after  (possibly) displaying  this checkbox's helptopic...
	fCbPrc( sControlNm, Value )								// ..execute the action procedure (if there is one defined, it can also be missing) 
End

Function		fCbProc( ctrlName, Value )						// dummy function  prototype
	string		ctrlName
	variable	Value
End

	
// 041101	
Function		fRadio1Dim_struct( s ) 
// each radio button group  consists of multiple indexed buttons (=sControlNm)   but  there is only 1 global variable (=sControlNmBase)...
// ...and there is only one action procedure (= sControlNmBase + "" )...
// ...and there is only one help topic (=the sSepText line above the buttons) which is connected separately to each button
	struct	WMCheckboxAction	&s
	variable	nDims	= 1			
	fRadio12Dim_struct( s, nDims) 
End

Function		fRadio2Dim_struct( s ) 
// each radio button group  consists of multiple indexed buttons (=sControlNm)   but  there is only 1 global variable (=sControlNmBase)...
// ...and there is only one action procedure (= sControlNmBase + "" )...
// ...and there is only one help topic (=the sSepText line above the buttons) which is connected separately to each button
	struct	WMCheckboxAction	&s
	variable	nDims	= 2			
	fRadio12Dim_struct( s, nDims) 
End

Static Function		fRadio12Dim_struct( s, nDims ) 
// each radio button group  consists of multiple indexed buttons (=sControlNm)   but  there is only 1 global variable (=sControlNmBase)...
// ...and there is only one action procedure (= sControlNmBase + "" )...
// ...and there is only one help topic (=the sSepText line above the buttons) which is connected separately to each button
	struct	WMCheckboxAction	&s
	variable	nDims
	string		sControlNm	= s.ctrlname
	variable	Value		= s.checked			
	string  	sThis 	= GetUserData(		s.win,  s.ctrlName,  "sThisF" )
	variable	nSkipPos	= strlen( ksROOTUF_ + sThis + "_" )			// 041101
	RadioCheckUncheck( sControlNm, Value ) 						// check / uncheck all the radio buttons of this group
	string  	sProc	= RadioButtonProcNm( sControlNm, nDims )
	// printf "\t\tfRadio12Dim_struct(  \t\t\t\t%s\tbVal:%d )\t-> \tnDims:%d\t-> [ will call if found: %s ]\tlen:%3d \r", pd( sControlNm, 27) , Value, nDims, pad( sProc[ nSkipPos,inf]+"()", 23 ), strlen(sProc[ nSkipPos,inf])
	DisplayHelpTopicFor( sControlNm )							// after  (possibly) displaying  this checkbox's helptopic... 
	FUNCREF   fCbProc_struct  fCbPrc = $( sProc[ nSkipPos,inf] )						// ..
	fCbPrc( s )								// ..execute the action procedure (if there is one defined, it can also be missing) 
End



Function		fRadio1Dim( sControlNm, Value ) 
// each radio button group  consists of multiple indexed buttons (=sControlNm)   but  there is only 1 global variable (=sControlNmBase)...
// ...and there is only one action procedure (= sControlNmBase + "" )...
// ...and there is only one help topic (=the sSepText line above the buttons) which is connected separately to each button
	string		sControlNm
	variable	Value			
	variable	nDims	= 1			
	fRadio12Dim( sControlNm, Value , nDims) 
End

Function		fRadio2Dim( sControlNm, Value ) 
// each radio button group  consists of multiple indexed buttons (=sControlNm)   but  there is only 1 global variable (=sControlNmBase)...
// ...and there is only one action procedure (= sControlNmBase + "" )...
// ...and there is only one help topic (=the sSepText line above the buttons) which is connected separately to each button
	string		sControlNm
	variable	Value			
	variable	nDims	= 2			
	fRadio12Dim( sControlNm, Value , nDims) 
End

Static Function		fRadio12Dim( sControlNm, Value, nDims ) 
// each radio button group  consists of multiple indexed buttons (=sControlNm)   but  there is only 1 global variable (=sControlNmBase)...
// ...and there is only one action procedure (= sControlNmBase + "" )...
// ...and there is only one help topic (=the sSepText line above the buttons) which is connected separately to each button
	string		sControlNm
	variable	Value, nDims
	string 	sProc 
	RadioCheckUncheck( sControlNm, Value ) 						// check / uncheck all the radio buttons of this group
	sProc		    = RadioButtonProcNm( sControlNm, nDims )
	// printf "\t\tfRadio12Dim(   \t\t\t\t\t%s\tbVal:%d )\t-> \tnDims:%d\t-> [ will call if found: %s ]\tlen:%3d \r", pd( sControlNm, 27) , Value, nDims, pad( sProc+"()", 23 ), strlen(sProc)
	DisplayHelpTopicFor( sControlNm )							// after  (possibly) displaying  this checkbox's helptopic... 
	FUNCREF   fCbProc  fCbPrc = $( sProc )						// ..
	fCbPrc( sControlNm, Value )								// ..execute the action procedure (if there is one defined, it can also be missing) 
End


// 041101
Function		fRadio_struct( s )
// each radio button group  consists of multiple indexed buttons (=sControlNm)   but  there is only 1 global variable (=sControlNmBase)...
// ...and there is only one action procedure (= sControlNmBase + "" )...
// ...and there is only one help topic (=the sSepText line above the buttons) which is connected separately to each button
	struct	WMCheckboxAction	&s
	string		sCtrlNm	= s.ctrlname
	variable	Value	= s.checked			
	string  	sThis 	= GetUserData(		s.win,  s.ctrlName,  "sThisF" )
	variable	len		= strlen( sCtrlNm )
	if ( len > 30 )
		 printf "++++Internal error : Control name  '%s'  is too long (%d) . Must be <= 30 . \r", sCtrlNm, len
	endif
	RadioCheckUncheck( sCtrlNm, Value ) 							// check / uncheck all the radio buttons of this group

	// Designe issue: The variable name includes  'root:uf:sThis:'  , the control name also includes  'root_uf_sThis_'   but the action proc name is without  (only in the _struct version).
	string 	sControlNmBase = RadioButtonBaseName( sCtrlNm )
	variable	nSkipPos		= strlen( ksROOTUF_ + sThis + "_" )			// 041101

	// printf "\t\tfRadio_struct(  \t\t\t\t\t\t%s\tbVal:%d )\t-> \t%s\t-> [ will call if found: %s  ]  (len:%d)\r", pd( sCtrlNm, 31) , Value, pd( sControlNmBase, 23 ), pd( sControlNmBase[nSkipPos,inf]+"()", 23) , len

	DisplayHelpTopicFor( sCtrlNm )									// after  (possibly) displaying  this checkbox's helptopic... 
	FUNCREF   fCbProc_struct  fCbPrc = $( sControlNmBase[nSkipPos,inf] )	// 041101
	fCbPrc( s )													// ..execute the action procedure (if there is one defined, it can also be missing) 
End

Function		fRadio( sCtrlNm, Value ) 
// each radio button group  consists of multiple indexed buttons (=sControlNm)   but  there is only 1 global variable (=sControlNmBase)...
// ...and there is only one action procedure (= sControlNmBase + "" )...
// ...and there is only one help topic (=the sSepText line above the buttons) which is connected separately to each button
	string		sCtrlNm
	variable	Value			
	variable	len	= strlen( sCtrlNm )
	if ( len > 30 )
		 printf "++++Internal error : Control name  '%s'  is too long (%d) . Must be <= 30 . \r", sCtrlNm, len
	endif
	RadioCheckUncheck( sCtrlNm, Value ) 							// check / uncheck all the radio buttons of this group
	string 	sControlNmBase = RadioButtonBaseName( sCtrlNm )

	// printf "\t\tfRadio( \t\t\t\t\t\t\t%s\tbVal:%d )\t-> \t%s\t-> [ will call if found: %s  ]  (len:%d)\r", pd( sCtrlNm, 31) , Value, pd( sControlNmBase, 23 ), pd( sControlNmBase+"()", 23) , len

	DisplayHelpTopicFor( sCtrlNm )									// after  (possibly) displaying  this checkbox's helptopic... 
	FUNCREF   fCbProc  fCbPrc = $( sControlNmBase )					// ..
	fCbPrc( sControlNmBase, Value )									// ..execute the action procedure (if there is one defined, it can also be missing) 
End





Static Function  	 	RadioButtonCnt( sFolderIndexedCtrlName )
	string		sFolderIndexedCtrlName
	variable	n	= ItemsInList( sFolderIndexedCtrlName, ksRADIOSEP )
	variable	cnt	= str2num( StringFromList( n - 1, sFolderIndexedCtrlName, ksRADIOSEP ) )	// the number after the last separator "_"	
	return	cnt
End

Static Function 	  	RadioButtonIndex( sFolderIndexedCtrlName )
// extract the index of the selected button , ignore folder, varname, number of buttons which are also coded in  'sFolderIndexedCtrlName'
	string		sFolderIndexedCtrlName
	variable	n	   = ItemsInList( sFolderIndexedCtrlName, ksRADIOSEP )
	variable	index  = str2num( StringFromList( n - 2, sFolderIndexedCtrlName, ksRADIOSEP ) )// the number after the second to last separator "_"
	// printf "\t\t\t\tRadioButtonIndex( sFolderIndexedCtrlName:'%s' ) -> %d \r", sFolderIndexedCtrlName, index
	return	index
End


//Static  Function  /S	RadioButtonBaseName( sCtrlNm )		// 041101  used in FPSTIM.ipf  just for testing...........
	  Function  /S	RadioButtonBaseName( sCtrlNm )		// 041101  used in FPSTIM.ipf  just for testing...........
// delete the indices of the radio button checkboxes: extract the one and only global variable (including folder)  for this radio button group (=the index of the ON button)  
	string  	sCtrlNm
	string  	sFolderBaseName
	variable	NmPartCnt = ItemsInList( sCtrlNm, ksRADIOSEP )							// split into folder, base name part, specific name part  (e.g.  root_uf_stimDsp_gbstim_Dac0 )
	sFolderBaseName	= RemoveListItem( NmPartCnt - 1 , sCtrlNm, ksRADIOSEP )			// remove the last index : the number of buttons
	sFolderBaseName	= RemoveListItem( NmPartCnt - 2 , sFolderBaseName, ksRADIOSEP )	// remove the second to last index : the index of the button
	sFolderBaseName	= sFolderBaseName[ 0, strlen( sFolderBaseName ) - 2 ]				// remove trailing separator '_'   e.g  root_uf_stimDsp_gbstim
	variable	len	= strlen( sCtrlNm )
	if ( len > 30  )															// allow _98_99  (6 characters after the base nmae)
		 printf "++++Internal error : Control name  '%s'  is too long (%d) . Must be <= 30 . \r", sCtrlNm, len
	endif
	// printf "\t\t\tRadioButtonBaseName( \t\t%s\t\t )\t->\t%s\t len:%d (Must be <= 30)\r", pd(sCtrlNm,26), pd(sFolderBaseName,23), len 
	return	sFolderBaseName
End

Static  Function  /S	RadioButtonProcNm( sControlNm, nDims )
// delete the indices of the radio button checkboxes: extract the one and only global variable(including folder)  for this radio button group (=the index of the ON button)  
	string  	sControlNm
	variable	nDims
	string  	sFolderBaseName
	variable	NmPartCnt = ItemsInList( sControlNm, ksRADIOSEP )						// split into folder, base name part, specific name part  (e.g.  root_uf_stimDsp_gbstim_Dac0 )
	sFolderBaseName	= RemoveListItem( NmPartCnt - 1 , sControlNm, ksRADIOSEP )		// remove the last index : the number of buttons
	sFolderBaseName	= RemoveListItem( NmPartCnt - 2 , sFolderBaseName, ksRADIOSEP )	// remove the second to last index : the index of the button
	if ( nDims == 2 )
		sFolderBaseName	= RemoveListItem( NmPartCnt - 3 , sFolderBaseName, ksRADIOSEP )	// remove the third to last index : the variable name (but leave the folder)
	endif
	sFolderBaseName	= sFolderBaseName[ 0, strlen( sFolderBaseName ) - 2 ]				// remove trailing separator '_'   e.g  root_uf_stimDsp_gbstim
	// printf "\t\t\tRadioButtonProcNm( dim: %d\t%s\t\t )\t->\t%s\t \r", nDims, pd(sControlNm,31), pd(sFolderBaseName,23)
	return	sFolderBaseName
End


//Static  Function  	SplitBaseIntoFolderandVar( sFolderVar, rsFolder, rsVar )		// 041101  used in FPSTIM.ipf  just for testing...........
		Function  	SplitBaseIntoFolderandVar( sFolderVar, rsFolder, rsVar )		// 041101  used in FPSTIM.ipf  just for testing...........
// breaks base name by splitting into folder, base name part, specific name part   e.g.  'root_uf_stimDsp_radRng' into its components   'root:uf:stim:'     'radRng'  
	string 	sFolderVar
	string 	&rsFolder, &rsVar
	string 	sFolderAndName
	
	sFolderAndName	= ReplaceString( ksRADIOSEP, sFolderVar, ":" )
	variable	n	= ItemsInList( sFolderAndName, ":" )
	rsVar		= StringFromList( n - 1, sFolderAndName, ":" )
	rsFolder	= RemoveListItem( n - 1, sFolderAndName, ":" )
	// printf "\t\t\tSplitBaseIntoFolderandVar(\t%s\t\t )\t->\t%s\t-> '%s' + '%s'  \r", pd(sFolderVar,31), pd(sFolderAndName,23), rsFolder, rsVar 
End


Static  Function 		RadioButtonBoolValue( sFolderIndexedCtrlName )
// returns boolean value for each radio checkbox: e.g.  0 for test_0_3 ,   1 for test_1_3 ,   0 for test_2_3 = 0    if   test = 1 
// used in the main panel function to set the checkboxes correctly
	string	sFolderIndexedCtrlName
	string	sF, sVarNm
	variable	n, nIndex,   nCnt
	n		= ItemsInList( sFolderIndexedCtrlName, ksRADIOSEP )
	nCnt		= str2num( StringFromList( n - 1, sFolderIndexedCtrlName, ksRADIOSEP ) )
	nIndex	= str2num( StringFromList( n - 2, sFolderIndexedCtrlName, ksRADIOSEP ) )
	sVarNm	= StringFromList( n - 3, sFolderIndexedCtrlName, ksRADIOSEP )
	sF	= RemoveListItem( n - 1, sFolderIndexedCtrlName, ksRADIOSEP )		// remove from end 'cnt'
	sF	= sF[ 0, strlen( sF ) - 2 ]								// remove from end ksRADIOSEP ( '_' )
	sF	= RemoveListItem( n - 2, sF, ksRADIOSEP )					// remove from end 'index'
	sF	= sF[ 0, strlen( sF ) - 2 ]								// remove from end ksRADIOSEP ( '_' )
	sF	= RemoveListItem( n - 3, sF, ksRADIOSEP )					// remove from end varname
	sF	= ReplaceString( ksRADIOSEP, sF, ":" )		// _  -> : 
	nvar	baseValue = $( sF + sVarNm ) 
	// printf "\t\t\tRadioButtonBoolValue( \t\t%s\t\t) \t-> \t%s\t    \t%s\t   value: %d\r", pd(sFolderIndexedCtrlName,25),  pd(sF,12),  pd(sVarNm,12) ,  nIndex == baseValue
	return ( nIndex == baseValue )
End

//Function  	SplitIndexedIntoFolderVarIndex( sFolderAndName, rsFolder, rsVar, rnIndex, rnCnt )
//// breaks indexed checkbox control name e.g.	'root_uf_stimDsp_radRng_2_4'  	into its components   'root:uf:stim:'  'radRng'  2   4 
//	string	sFolderAndName
//	string	&rsFolder, &rsVar
//	variable	&rnIndex,   &rnCnt
//	variable	n	= ItemsInList( sFolderAndName, ksRADIOSEP )
//	rnCnt	= str2num( StringFromList( n - 1, sFolderAndName, ksRADIOSEP ) )
//	rnIndex	= str2num( StringFromList( n - 2, sFolderAndName, ksRADIOSEP ) )
//	rsVar	= StringFromList( n - 3, sFolderAndName, ksRADIOSEP )
//	rsFolder	= RemoveListItem( n - 1, sFolderAndName, ksRADIOSEP )			// remove from end 'cnt'
//	rsFolder	= rsFolder[ 0, strlen( rsFolder ) - 2 ]							// remove from end ksRADIOSEP ( '_' )
//	rsFolder	= RemoveListItem( n - 2, rsFolder, ksRADIOSEP )					// remove from end 'index'
//	rsFolder	= rsFolder[ 0, strlen( rsFolder ) - 2 ]							// remove from end ksRADIOSEP ( '_' )
//	rsFolder	= RemoveListItem( n - 3, rsFolder, ksRADIOSEP )					// remove from end varname
//	rsFolder	= ReplaceCharWithString( rsFolder, ksRADIOSEP, ":" )		// _  -> : 
//	// printf "\t\t\tSplitIndexedIntoFolderVarIndex( '%s' ) -> '%s'  '%s'  %d %d \r", sFolderAndName, rsFolder, rsVar, rnIndex, rnCnt
//End


//---------------------------------------------------------------------------------------------------------------------------------------
//   		TABCONTROL  ( only CheckBoxes and  Radio buttons are handled)

Function		fTabControl( s )
	struct	WMTabControlAction   &s
	string  	lstAllVars 	= GetUserData( 	s.win,  s.ctrlName,  "AllVars" )
	string  	lstAllTabs 	= GetUserData( 	s.win,  s.ctrlName,  "AllTabs" )
	string  	lstAllItems 	= GetUserData( 	s.win,  s.ctrlName,  "AllItems" )
	variable	nItems	= str2num( lstAllItems )
	// printf "\t\tfTabControl()  %s  %s  %d  %s  %s      %s \t will call if found  '%s()'  \r", s.win, s.ctrlName, s.tab, lstAllVars, lstAllTabs, lstAllItems, s.ctrlName
	// Turn on and off the CheckBox controls belonging to the tabs which are drawn one on top of each other. Only the control of the active tab is shown and enabled, the others are hidden and off. 
	ShowHideControlsInTab( s.ctrlName, s.tab, lstAllTabs, lstAllVars, lstAllItems ) 
	FUNCREF   fTcProc  fTcPrc = $( s.ctrlName )			// ..
	fTcPrc( s )										// ..execute the action procedure (if there is one defined, it can also be missing) 
End

Function		fTcProc( s )							// dummy function  prototype
	struct	WMTabControlAction &s
End

Function		ShowHideControlsInTab(  sTabCtrlNm, nSelectedTab, sTabTitles, lstAllVars, lstAllItems ) 
// Turn on and off the CheckBox controls belonging to the tabs which are drawn one on top of each other. Only the control of the active tab is shown and enabled, the others are hidden and off. 
//  to to ? pass and evaluate the window...
	string  	sTabCtrlNm							// not used			
	string  	sTabTitles, lstAllVars, lstAllItems
	variable	nSelectedTab
	string  	sTab, sF, sVarNm, sCtrlNm
	variable	v , vCnt	= ItemsInList( lstAllVars, ksTILDE_SEP )
	for ( v = 0; v < vCnt; v += 1 )
		variable	d, dCnt	= ItemsInList( StringFromList( v, lstAllItems, ksTILDE_SEP ) , ksTAB_SEP )
		// print  "\t\tShowHideControlsInTab   ", sTabCtrlNm, nSelectedTab, "\tTabTitles:", sTabTitles, "\tLstAllVars:", lstAllVars, "\tLstAllItems:", lstAllItems 
		sF	= StringFromList( v, lstAllVars, ksTILDE_SEP ) 
		variable	nTab, nTabs	= ItemsInList( sTabTitles, ksTAB_SEP )
		for ( nTab = 0; nTab < nTabs; nTab += 1 )
			sTab		= StringFromList( nTab, sTabTitles, ksTAB_SEP )
			for ( d = 0; d < dCnt; d += 1 )
				// We do not know whether we are dealing with a CheckBox group  or a  Radio button  group (which unfortunately  have different naming conventions) so we check both and  try it out:

				// Try a  CheckBox  group 
				string  	sDim1	= RemoveWhiteSpace( StringFromList( d, StringFromList( v, lstAllItems, ksTILDE_SEP ) , ksTAB_SEP ) )
				sVarNm	= sF + ":" + sTab + ksRADIOSEP + sDim1
				sCtrlNm	= ReplaceString( ":" , sVarNm, ksRADIOSEP )
				ControlInfo		$sCtrlNm
				if ( V_flag == 2 ) 									// the  CheckBox  'sCtrlNm'  exists
					nvar valueC	= $sVarNm					// not used		
					// printf "\t\t\t ShowHideControlsInTab(  cb\t%s\tSelTb:%d\tdim:%d/%d\tvl:%d\tsFolder:%s\tsVarNm:%s\tsCtrlNm:%s \r",   pd(sTab,6), nSelectedTab, d, dCnt, valueC, pd(sF,16), pd(sVarNm,27), sCtrlNm
					ModifyControl $sCtrlNm disable = ( nTab != nSelectedTab )
				endif

				// Try a  Radio button  group 
				sVarNm	= sF + ":" + sTab + ksRADIOSEP + num2str( d ) + ksRADIOSEP + num2str( dCnt )
				sCtrlNm	= ReplaceString( ":" , sVarNm, ksRADIOSEP )
				ControlInfo		$sCtrlNm
				if ( V_flag == 2 ) 									// the  CheckBox  'sCtrlNm'  exists (is radio button)
					variable value	= RadioButtonValue( sCtrlNm )		// not used		 
					// printf "\t\t\t ShowHideControlsInTab(  rb\t%s\tSelTb:%d\tdim:%d/%d\tvl:%d\tsFolder:%s\tsVarNm:%s\tsCtrlNm:%s \r",   pd(sTab,6), nSelectedTab, d, dCnt, value, pd(sF,16), pd(sVarNm,27), sCtrlNm
					ModifyControl $sCtrlNm disable = ( nTab != nSelectedTab )
				endif

			endfor
		endfor
	endfor
End


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	I N T E R F A C E
//
//-------------------------------------------------------------------------------------------------------------------------
//   		TABCONTROL  with CheckBoxes

Function	/S	CheckedBoxIndicesInTabControl( sTab, sF, sDim1Titles )
// Return  for  the  CheckBox group  'sDim1Titles'  of  tab  'sTab'  of a  TabControl  the  list of  'turned on'  CheckBox   indices  ( e.g  0;2;3;)
	string		sTab, sF, sDim1Titles
	variable	nDim1, nMax	= ItemsInList( sDim1Titles )
	string  	sIndices =  ""
	for ( nDim1 = 0; nDim1 <nMax;  nDim1 += 1)
		if ( IsCheckedInTabControlN( sTab, sF, sDim1Titles, nDim1 ) )
			sIndices 	= AddListItem( num2str( nDim1 ), sIndices, ";", Inf )			// makes list e.g. '0;1;3'
		endif
		 // printf "\t\tCheckedBoxIndicesInTabControl( \t%s\t%s\t%s\t\t)\tnDim:%d/%d  \t- > \t'%s'  \r", sTab, pd(sF,16), pd(sDim1Titles,32), nDim1, nMax, sIndices
	endfor
	return	sIndices
End

Function		IsCheckedInTabControlN( sTab, sF, sDim1Titles, nDim1 )
// Return  the state  of  the  'nDim1'th   CheckBox  of the  CheckBox group  'sDim1Titles'   in tab  'sTab'  of a TabControl 
	string		sTab, sF, sDim1Titles
	variable	nDim1
	return	IsCheckedInTabControlS( sTab, sF, RemoveWhiteSpace1( StringFromList( nDim1, sDim1Titles ) ) )
End

Function		IsCheckedInTabControlS( sTab, sF, sDim1Title )
// Return  the state  of  the CheckBox  'sDim1Title'  of  the group  of CheckBoxes  in tab  'sTab'  of a TabControl 
	string		sTab, sF, sDim1Title
	string  	sGlobalVarNm
	sGlobalVarNm	= sF + ":" + sTab + ksRADIOSEP + sDim1Title
	nvar	value	= $sGlobalVarNm
	// printf "\t\t\tIsCheckedInTabControlS( \t\t%s\t%s\t%s\t\t)\t%s\t=%2d \r", sTab, pd(sF,16), pd(sDim1Title,32), pd(sGlobalVarNm,32), value
	return	value 
End

//--------------------------------------------------------------------------------
//   		RADIO BUTTONS

// Interface (used once)
Function		RadioCheckUncheck( ctrlName, bValue ) 
// check and uncheck the radio buttons of this group 
	string		ctrlName
	variable	bValue			
	variable 	n, cnt = RadioButtonCnt( ctrlName )
	// printf "\t\tRadioCheckUncheck(   \ta ctlNm:\t%s\tbVal:%d )\t-> \tcnt:%d \r", pd(ctrlName,26), bValue, cnt	
	string 	sGlobalRadioVar  = RadioButtonBaseName( ctrlName )	
	for ( n = 0; n < cnt; n += 1 )
		string 	sRadio		  = RadioButtonFullName( sGlobalRadioVar, n, cnt )
		if ( cmpstr( sRadio, ctrlName ) == 0 )						// check (=turn on) the one clicked button... 
			string		rsFolder, rsVar
		  	SplitBaseIntoFolderandVar( sGlobalRadioVar, rsFolder, rsVar ) 
			// printf "\t\t\tRadioCheckUncheck(\tb ctlNm:\t%s\tbVal:%d )\t->\t%s\t-> '%s' +\t%s\tset to %d (of %d) \tsRadio:%s\r", pd(ctrlName,27), bValue, pd(sGlobalRadioVar,23), rsFolder, pd(rsVar,12), n, cnt, sRadio	
			FolderSetV( rsFolder, rsVar, n )						// store state of radio button group in ONE global variable
			CheckBox $sRadio, value = 1						// ONLY NECESSARY when button is set indirectly (e.g. shape from trace,ana,stage..)
		else
			// printf "\t\t\tRadioCheckUncheck(\tc ctlNm:\t%s\tbVal:%d )\t->\t%s\t-> unchecking '%s'   \r", pd(ctrlName,26), bValue, pd(sGlobalRadioVar,23), sRadio	
			CheckBox $sRadio, value = 0						// ...reset all other radio buttons of this group
		endif
	endfor
End

Function		ChkBoxValDim1( sControlNm )
// returns the checkbox value when the control name is given . We need global shadow variables including folders to be independent of panel names 
 	string		sControlNm
 	variable	len
	string		sFolderVarNm	= ReplaceString(  ksRADIOSEP , sControlNm, ":" )
	nvar		value		= $ sFolderVarNm
	// printf "\t\t\tChkBoxValDim1( \t\t\t%s )\t\t-> \t%s\tvalue: %d  \r",  pd(sControlNm, 27), pd( sFolderVarNm, 22) , value
End

Function		ChkBoxVarNmExtractDim1( sName, rsFolderVarNmBase, rsTitleHV )
// Splits  and converts  'root_uf_aco_ola_wa_Adc0Peak_WA0'    into  'root:uf:aco:ola:wa'  ,  'Adc0Peak'  ,  'WA0'
// could also return value like ChkBoxValDim1()
 	string		sName, &rsFolderVarNmBase,  &rsTitleHV
	variable	len
	variable	NmPartCnt	= ItemsInList( sName, ksRADIOSEP )	
	rsTitleHV			= StringFromList( NmPartCnt - 1 , sName, ksRADIOSEP  )			//	save everything behind the last  '_'
	rsFolderVarNmBase	= RemoveListItem( NmPartCnt - 1 , sName, ksRADIOSEP  ) 			// 	remove everything behind the last  '_' 
	len				= strlen( rsFolderVarNmBase )
	rsFolderVarNmBase	= rsFolderVarNmBase[ 0, len-2 ]								// Remove the now trailing   '_' 
	rsFolderVarNmBase	= ReplaceString(  ksRADIOSEP , rsFolderVarNmBase, ":" )			// 
	// printf "\t\t\tChkBoxVarNmExtractDim1(\t%s )\t\t-> \t%s\tTitleHV:\t%s \r",  pd(sName, 27), pd(rsFolderVarNmBase,12) , pd(rsTitleHV,12)
End

Function		ChkBoxValDim2( sControlNm )
// returns the checkbox value when the control name is given . We need global shadow variables including folders to be independent of panel names 
 	string		sControlNm
 	variable	len
	variable	NmPartCnt		= ItemsInList( sControlNm, ksRADIOSEP )	
	string		sFolderVarNm	= ReplaceString(  ksRADIOSEP , sControlNm, ":", 0, NmPartCnt-2 )	// replace  '_'  by  ':'  except at the last occasion which separate the 2 name parts
	nvar		value		= $ sFolderVarNm
	// printf "\t\t\tChkBoxValDim2( \t\t\t%s )\t\t-> \t%s\tvalue: %d  \r",  pd(sControlNm, 37), pd( sFolderVarNm,37) , value
	return	value
End

Function		ChkBoxVarNmExtractDim2( sName, rsFolderVarNmBase, rsTitle, rsTitleHV )
// Splits  and converts  'root_uf_aco_ola_wa_Adc0Peak_WA0'    into  'root:uf:aco:ola:wa'  ,  'Adc0Peak'  ,  'WA0'
// could also return value like ChkBoxValDim2()
 	string		sName, &rsFolderVarNmBase, &rsTitle, &rsTitleHV
	variable	len
	variable	NmPartCnt	= ItemsInList( sName, ksRADIOSEP )	
	rsTitleHV			= StringFromList( NmPartCnt - 1 , sName, ksRADIOSEP  )			//	save everything behind the last  '_'
	rsTitle			= StringFromList( NmPartCnt - 2 , sName, ksRADIOSEP  )			// 	save everything behind the pre last  '_'  and  in front of  the last  '_'
	rsFolderVarNmBase	= RemoveListItem( NmPartCnt - 1 , sName, ksRADIOSEP  ) 			// 	remove everything behind the last  '_' 
	rsFolderVarNmBase	= RemoveListItem( NmPartCnt - 2 , rsFolderVarNmBase, ksRADIOSEP )	// 	remove everything behind the pre last  '_' 
	len				= strlen( rsFolderVarNmBase )
	rsFolderVarNmBase	= rsFolderVarNmBase[ 0, len-2 ]								// Remove the pre last (and now trailing)   '_' 
	rsFolderVarNmBase	= ReplaceString(  ksRADIOSEP , rsFolderVarNmBase, ":" )			// 
	// printf "\t\t\tChkBoxVarNmExtractDim2(\t%s )\t\t-> \t%s\tTitle:\t%s\tTitleHV:\t'%s' \r",  pd(sName, 27), pd(rsFolderVarNmBase,12) , pd(rsTitle,12), rsTitleHV
End


Function  /S	RadioButtonExtractDim2Nm( sControlNm )
// Extracts   'Adc0Peak'  from  'root_uf_aco_ola_Radi_Adc0Peak_1 _3' 
	string  	sControlNm
	variable	NmPartCnt	= ItemsInList( sControlNm, "_" )
	string  	sVarNm	= StringFromList( NmPartCnt - 3 , sControlNm, "_" )				// Assumption :  naming convention
	// printf "\t\t\tRadioButtonExtractDim2Nm( \t%s\t\t )\t->\t'%s' \r",  pd(sControlNm,26), sVarNm
	return	sVarNm
End

Function   /S	RadioButtonFullName( sFolderVar, n, nButtons )
// combines passed parameters to the button name (=variable name), one unique name per button, used only locally
// sFolderVar can contain either ksRADIOSEP or ":" ( e.g. 'root:uf:stim:varname'   or  'root_uf_stim_varname' )  . This is left unchanged, only index and cnt are appended. 
	string		sFolderVar
	variable	n, nButtons
	string		sRadioButtonFullName	= sFolderVar + ksRADIOSEP+ num2str( n ) + ksRADIOSEP + num2str( nButtons )
	// printf "\t\t\tRadioButtonFullName( \t\t%s\tn:%d , nBut:%d )\t\t->\t'%s' \r", pd(sFolderVar,26), n, nButtons ,  sRadioButtonFullName
	return	sRadioButtonFullName
End

Function   		RadioButtonValue( sFolderVar )
// returns the state of the radio buttons (=the index of the checked button) when the control name in the form 'root_folder_varname_X_Y'  is passed.
	string 	sFolderVar
	string 	sFolderBaseName
	variable	NmPartCnt	  = ItemsInList( sFolderVar, ksRADIOSEP )							// split into folder, base name part, specific name part  (e.g.  root_uf_stimDsp_gbstim_Dac0 _1_2)
	sFolderBaseName	= RemoveListItem( NmPartCnt - 1 , sFolderVar, ksRADIOSEP )			// remove the last index : the number of buttons
	sFolderBaseName	= RemoveListItem( NmPartCnt - 2 , sFolderBaseName, ksRADIOSEP )		// remove the second to last index : the index of the button
	sFolderBaseName	= RemoveEnding( sFolderBaseName )								// remove trailing separator '_'   e.g  root_uf_stimDsp_gbstim
	sFolderBaseName	= ReplaceString( ksRADIOSEP, sFolderBaseName , ":")//":" , 0 , NmPartCnt - 3 )	// convert all but the last  separator  _  into  :  (only  those separating folders) 
	nvar	  /Z	value	= $sFolderBaseName
	// printf "\t\t\tRadioButtonValue( \t\t\t%s\t\t )\t->\t%s\t(exists:%d)   \t-> %d  \r", pd( sFolderVar,26),  pd(sFolderBaseName,23),  nvar_exists( value ), value
	return	value
End


Function   		RadioButtonValueFromBaseNm( sFolderVarBase )
// returns the state of the radio buttons (=the index of the checked button) when the control name in the form 'root_folder_varname'  (without indices) is passed.
	string 	sFolderVarBase
	string 	sFolderBaseName
	sFolderBaseName	= ReplaceString( ksRADIOSEP, sFolderVarBase , ":")
	nvar	  /Z	value	= $sFolderBaseName
	// printf "\t\t\tRadioButtonValueFromBaseNm( \t\t\t%s\t\t )\t->\t%s\t(exists:%d)   \t-> %d  \r", pd( sFolderVarNase,26),  pd(sFolderBaseName,23),  nvar_exists( value ), value
	return	value
End


Function		ChkBoxValFromIndex1Dim( i, sFolderVarNmBase, lstTitlesHV )
	variable	i
	string		sFolderVarNmBase, lstTitlesHV
	string  	sChkBoxVarNm	= sFolderVarNmBase + ":"  + RemoveWhiteSpace1( StringFromList( i, lstTitlesHV ) )
	nvar		value		= $sChkBoxVarNm
	// printf "\t\t\tChkBoxValFromIndex1Dim( \ti:%d\t%s ) \t-> \t%s \t = %d  \t(%s) \r", i,  pd(sFolderVarNmBase,27),  pd(sChkBoxVarNm,32),  value, lstTitlesHV
	return	value
End

Function		ChkBoxValFromString1Dim( sFolderVarNmBase , sTitleHV )
// 'ChkBoxValFromString1Dim()'  and  'FolderGetV()'   are similar 
	string		sFolderVarNmBase, sTitleHV
	string  	sChkBoxVarNm	= sFolderVarNmBase + ":"  + RemoveWhiteSpace1( sTitleHV )
	nvar		value		= $sChkBoxVarNm
	// printf "\t\t\tChkBoxValFromString1Dim( %s\t%s ) \t-> \t%s \t = %d  \r", pd( sTitleHV,4),  pd(sFolderVarNmBase,27),  pd(sChkBoxVarNm,32),  value
	return	value
End

Function		ChkboxValFromString2Dim( sFolderVarNmBase, sVarNm1, sVarNm2 )
	string  	sFolderVarNmBase,  sVarNm1, sVarNm2
	string  	sChkBoxVarNm	 = sFolderVarNmBase + ":" + sVarNm1 + ksRADIOSEP + sVarNm2
	nvar 	  /Z	value	 = $sChkBoxVarNm
// printf "\t\t\tChkBoxValFromString2Dim( %s\t%s\t%s ) \t-> \t%s \texists: %d  \t = %d  \r",  pd(sFolderVarNmBase,27), sVarNm1, sVarNm2,  pd(sChkBoxVarNm,32),  nvar_exists( value ) , value
	if ( ! nvar_exists( value ) )
		printf "Warning: Variable '%s' does not exist. [ChkboxValFromString2Dim()] \r", sChkBoxVarNm
	endif
	return	value
End	

Function		ChkboxSetAll(  sFolderVarNmBase, bValue )
// Sets all checkboxes whose name is derived from 'sF_VarNm_Base'  ( i.e. all  whose underlying global variables reside in 'sF:VarNm:Base' )   to  'bValue'
//  Advantage: The underlying global variables are automatically set.  Disdadvantage:  The panel and the checkbox must already exist.
	string  	sFolderVarNmBase
	variable	bValue
	string 	sObjName, sControlNm
	string 	sControlNmBase	= ReplaceString( ":", sFolderVarNmBase, ksRADIOSEP )	// convert  ':'  into  '_'  i.e. from folder into controlname
	variable	index = 0
	// Loop through all checkbox controls which belong to this folder by accessing all variables located in this folder
	do
		sObjName = GetIndexedObjName( sFolderVarNmBase,  kIGOR_VARIABLE, index )
		if ( strlen( sObjName ) == 0 )
			break
		endif
		sControlNm	= sControlNmBase + ksRADIOSEP + sObjName
		Checkbox	  $sControlNm	value = bValue
		// printf "\t\t\tChkBoxSetAll(\t\t\t%s\tbValue: %d ) \t-> \tcontains %d variables \t%s\tset to %d   \r",  pd(sFolderVarNmBase,27), bValue, CountObjects( sFolderVarNmBase, kIGOR_VARIABLE ), pd( sControlNm, 27), bValue	
		index += 1
	while( TRUE )
End

Function		ChkboxUnderlyingVariablesSetAll(  sFolderVarNmBase, bValue )
// 050530 Sets all underlying global checkbox variables  whose name is derived from 'sF_VarNm_Base'  ( i.e. all  whose underlying global variables reside in 'sF:VarNm:Base' )   to  'bValue'
//  Advantage: The panel and the checkbox may not yet already exist.
	string  	sFolderVarNmBase
	variable	bValue
	string 	sObjName, sVarNm
	variable	index = 0
	// Loop through all checkbox controls which belong to this folder by accessing all variables located in this folder
	do
		sObjName = GetIndexedObjName( sFolderVarNmBase,  kIGOR_VARIABLE, index )
		if ( strlen( sObjName ) == 0 )
			break
		endif
		sVarNm	= ReplaceString(  ksRADIOSEP, sFolderVarNmBase, ":" ) + ":" + sObjName
		nvar	tmp	= $sVarNm 
		tmp		= bValue
		// printf "\t\t\tChkboxUnderlyingVariablesSetAll(\t\t\t%s\tbValue: %d ) \t-> \tcontains %d variables \t%s\tset to %d   \r",  pd(sFolderVarNmBase,27), bValue, CountObjects( sFolderVarNmBase, kIGOR_VARIABLE ), pd( sVarNm, 27), bValue	
		index += 1
	while( TRUE )
End

//Function		SetChkboxVal( sControlNm, bState )
//	Checkbox	  $sControlNm	value = bState
//End

Static Function		FolderGetV( sF,  sGlobalName, DefaultValue )
// returns contents of global variable, when the variable name and folder are passed as strings 
// if the variable does not yet exist, it will be created and set to the 'DefaultValue' 
// used for variables where direct access is not possible, mainly those which are constructed automatically  e.g. gbStim_Dac0 
// 'ChkBoxValFromString1Dim()'  and  'FolderGetV()'   are similar 
	string 		sF, sGlobalName
	variable		DefaultValue
	nvar		/Z	gValue = $( sF + sGlobalName )
	return  nvar_exists( gValue ) ? gValue :  FolderSetV( sF, sGlobalName, DefaultValue )	
End

Static Function  		FolderSetV( sF, sNameofGlobalNumber, Value )
// constructs global variable with name 'sNameofGlobalNumber'  in folder 'sF' , sets it to Value, returns value
	string 		sF, sNameofGlobalNumber
	variable		Value								// 
	variable	/G	$( sF + sNameofGlobalNumber ) = Value	// 
	return		Value								// this redundant line makes the corresponding FolderGetV() function shorter
End

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  ENABLE  OR  kDISABLE  A  PUSH  PN_BUTTON or  CHECK BOX  ( NOT a PN_RADIO-BUTTON )    or  a  popupmenu

// 060914
// 2009-10-23
//Function		EnableButton( sPanelNm, sControlNm, EnableDisable )
//	string		sPanelNm, sControlNm
//	variable	EnableDisable
//	// print "\t\t  panel   enable/kDISABLE button", sPanelNm, sControlNm, WinType( sPanelNm ),"?", kPANEL, EnableDisable
//	if ( WinType( sPanelNm ) == kPANEL ) 			// avoid error when panel does not yet exist (e.g. PnPuls when loading script at startup)
//		Button	$sControlNm	win = $sPanelNm,	disable = EnableDisable	// kENABLE = 0, kDISABLE = 2
//	endif
//End
//
//Function		EnableButtn( sPanelNm, sControlNm, EnableDisable )
//	string		sPanelNm, sControlNm
//	variable	EnableDisable
//	// print "\t\tpanel   enable/kDISABLE button", sPanelNm, sControlNm, WinType( sPanelNm ),"?", kPANEL, EnableDisable
//	if ( WinType( sPanelNm ) == kPANEL ) 			// avoid error when panel does not yet exist (e.g. PnPuls when loading script at startup)
//		Button	$sControlNm	win = $sPanelNm,	disable = !EnableDisable*2	// kENABLE = 0, kDISABLE = 2
//	endif
//End

Function		EnableCheckbox( sPanelNm, sControlNm, EnableDisable )
	string		sPanelNm, sControlNm
	variable	EnableDisable
	// print "\t\tpanel  enable/kDISABLE  checkbox", sPanelNm, sControlNm, WinType( sPanelNm ),"=?=", kPANEL, EnableDisable
	if ( WinType( sPanelNm ) == kPANEL ) 			// avoid error when panel does not yet exist (e.g. PnPuls when loading script at startup)
		Checkbox	$sControlNm	win = $sPanelNm,	disable = EnableDisable
	endif
End

// 060914
// 2009-10-23
//Function		EnableSetVar( sPanelNm, sControlNm, EnableDisable )
//	string		sPanelNm, sControlNm
//	variable	EnableDisable
//	 // print "\t\tpanel  enable/kDISABLE  SetVariable", sPanelNm, sControlNm, WinType( sPanelNm ),"?", kPANEL, EnableDisable
//	if ( WinType( sPanelNm ) == kPANEL ) 			// avoid error when panel does not yet exist (e.g. PnPuls when loading script at startup)
//		if ( EnableDisable == kNOEDIT )
//			SetVariable  $sControlNm	win = $sPanelNm,	disable = 0,			noedit = 1				// pass kNOEDIT=3 : display the control but do not let the user change the value
//		else
//			SetVariable  $sControlNm	win = $sPanelNm,	disable = !EnableDisable,	noedit = !EnableDisable	// pass 1 : enable and allow editing;  pass 0 : disable and no editing
//		endif
//	endif
//End

// 060914 
//Function		EnablePopup( sPanelNm, sControlNm, EnableDisable )
//	string		sPanelNm, sControlNm
//	variable	EnableDisable
//	// print "\t\tpanel   enable/kDISABLE popup", sPanelNm, sControlNm, WinType( sPanelNm ),"?", kPANEL, EnableDisable
//	if ( WinType( sPanelNm ) == kPANEL ) 			// avoid error when panel does not yet exist (e.g. PnPuls when loading script at startup)
//		PopupMenu	$sControlNm	win = $sPanelNm,	disable = EnableDisable	// kENABLE = 0, kDISABLE = 2
//	endif
//End

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  PN_SETSTR  ,  PN_SETVAR  and  MULTIPLE  SETVARs

// 041101
Function		fSetvar_struct( s ) 
	struct	WMSetvariableAction   &s
	// printf "\t\tfSetvar_struct( sControlNm:'%s'   Value:%g , sVarName:'%s'  \t[will call if found: %s  ]\r", s.ctrlname, s.dval, s.vname,  pd(s.CtrlName+"()",26) 
	DisplayHelpTopicFor( s.ctrlname )							// after  (possibly) displaying  this checkbox's helptopic... 
	FUNCREF   fSvProc_struct  fSvPrc = $( s.ctrlname )				// ..
	fSvPrc( s )												// ..execute the action procedure (if there is one defined, it can also be missing) 
End

Function		fSvProc_struct( s ) 								// dummy function  prototype
	struct	WMSetvariableAction    &s
End


Function		fSetvar( sControlNm , Value, sValue, sVarName ) 
	string		 sControlNm, sValue, sVarName 
	variable	Value
	// printf "\t\tfSetvar( sControlNm:'%s'   Value:%g , sValue:'%s'  sVarName:'%s'  ) \r", sControlNm , Value, sValue, sVarName 
	DisplayHelpTopicFor( sControlNm )							// after  (possibly) displaying  this checkbox's helptopic... 
	FUNCREF   fSvProc  fSvPrc = $( sControlNm )					// ..
	fSvPrc( sControlNm, Value, sValue, sVarName )					// ..execute the action procedure (if there is one defined, it can also be missing) 
End

Function		fSvProc( sControlNm , Value, sValue, sVarName ) 		// dummy function  prototype
	string 	sControlNm, sValue, sVarName 
	variable	Value
End



Function		PnSeparator( tPanel, n, sSepText  ) 
	wave   /T	tPanel
	variable	n
	string		sSepText
	if ( strlen( sSepText ) )
		n += 1;	tPanel[ n ] =	"PN_SEPAR;	;" + sSepText
	endif	
	return	n
End
	