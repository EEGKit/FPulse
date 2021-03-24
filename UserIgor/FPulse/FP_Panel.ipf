//
// FP_Panel.ipf 
// 
// Very generic panel dialog routines
// 
// Remarks 0504:
// The row and column TITLE lists determine the existence of a control: When there is a row or column title there will be a control. If there is just 1 row or just 1 column this other title may be empty.
// BLocks are different: Even if there is a title the control can be missing (depending on 'lstMode'). This adds complexity to the code but adds flexibility to the panel design e.g. depending on the tab the 1.block may be missing, the 2. on.
// Without 'lstMode' the code would be simpler but the ON-blocks would have to be contiguous from block0, only trailing blocks could be missing. Additionally there would be 1 separator required everywhere where there is now an empty string.
//
// Todo: 	
//		initvals
//
// With Font = MS Sans Serif  and size = 9   tabs are aligned neatly in the procedure window(s)
//
// Remarks:

// History:
// Assumptions/Caveats:
// 	don't use the underscore '_'  , neither in a variable name nor in a folder name. The underscore is used internally to separate those items.
//	don't use too long names. Internally  the 'root', all folders, the variable name and the variable ending are catenated using underscores. The total length must be <= 31 !
//	if you have defined a special-name action procedure and if you have put it into the proc field, then do not define an auto-built-name proc ( which would additionallly be called )
 
#pragma rtGlobals=1									// Use modern global access method.


constant			kFONTSIZE 		= 12	 			// determines only the separator font size and the width of text space (inversely?) in panels, not the button or checkbox text...?

strconstant		ksFONT			= "MS Sans Serif" 	// the panels are designed for  "MS Sans Serif" 
strconstant		ksFONT_			= "\"MS Sans Serif\""// special syntax needed for   'DrawText , SetDrawEnv..'
// strconstant		ksFONT			= "Arial"			//  to use "Arial"  make all controls 1 pixel higher  (kYHEIGHT=16)  or  set FONTSIZE=11. Unfortunately controls using pictures are not scaled as easily.
// strconstant		ksFONT_			= "\"Arial\""		//  special syntax needed for   'DrawText , SetDrawEnv..'
// strconstant		ksFONT			= "Courier" 		// for extreme testing
// strconstant		ksFONT_			= "\"Courier\""		//  special syntax needed for   'DrawText , SetDrawEnv..'

 constant			kXMARGIN		= 2 				// horizontal margin between panel border and control ( 0..8 )
constant			kYHEIGHT		= 15				// vertical size of element (button) , useful range is 15..18
constant			kYLINEHEIGHT	= 20				// vertical distance between controls in a panel

 strconstant		ksTILDE_SEP		= "~"	// ","

constant			kY_MISSING_PIXEL_TOP	= 18	// 18 is the height of  the Igor title line and menu bar	(appr.)
constant			kY_MISSING_PIXEL_BOT	= 32	// 32 is the height of  status bar + windows 2 lines



strconstant		ksSEP_TBCO		= "$"				// Separates tabcontrols in panels
strconstant		ksSEP_TAB		= "°"				// Separates the tabs in a tabcontrol e.g. 'Adc0°Adc2'.  Using ^ is allowed. Do NOT use characters used in titles e.g. , .  ( ) [ ] =  .  Neither use Tilde '~' (is main sep) , colon ':' (is path sep)   or   '|'  (also used elsewhere) .
strconstant		ksSEP_CTRL		= "|"				// Separates controls in tabcontrols in panels
strconstant		ksSEP_STD		= ","				// standard separator e.g. for  row and column title lists
strconstant		ksSEP_WPN		= ":"				// Separator the specifying items of a control in a 'wPn' line 
strconstant		ksSEP_COMMONINIT= "~"			// Separates specific initialisation values from the common value which is applicable for the rest e.g. "0000_7;0001_1.5;~2.3"	


constant		kTYPE=0, kNXLN=1, kXPOS=2, kMXPO=3, kOVS=4, kTABS=5, kBLKS=6, 	kMODE=7,  kNAME=8,  kROWTI=9,   kCOLTI=10,  kACTPROC=11,  kXBODYSZ=12, kFORMENTRY=13, kINITVAL=14, kVISIB=15,  kHELPTOPIC=16

constant		kSEP = 0,  kCB = 1,  kRAD = 2,  kSV = 3,  kPM = 4,  kBU = 5,  kSTR = 6,  kBUP = 7,  kSTC = 8,  kVD = 9 
strconstant	lstTYPE ="SEP;CB;RAD;SV;PM;BU;STR;BUP;STC;VD;"

constant		kPANEL_INIT	= 1 ,  kPANEL_DRAW = 2
//=============================================================================================================
//  4dim dialog functions  	
constant		kRIGHT1 = 0//,  kLEFT = 1,  kBOTTOM = 0,  kTOP = 1
constant		kKILL_ALLOW = 1,  kKILL_DISABLE = 2
static constant	kMAGIC_Y_OFFSET_PIXEL = 50	// on 1600x1200 screen this is the topmost position where a window can be placed. ??? How can this value be computed???
	 constant	kMAGIC_Y_MISSING_PIXEL = 26	// on 1600x1200 screen that many y pixel are not available compared to what  'GetWindow kFrameInner' claims. ??? Is it the status line which must be taken into account???

Function		NewPanel1( sWin, bLeft, xOfs, xSize, bTop, yOfs, ySize, nKill, sTitle )
// Position a newly created panel precisely with or without an offset (in pixel) on any border of the Igor main window
	string  	sWin, sTitle
	variable	bLeft, bTop			// border onto which to place the panel
	variable	xOfs, yOfs				// offset from border in pixel. Positive values will move right or down
	variable	xSize, ySize			// the panel size in pixel
	variable	nKill					// 1 allows killing without asking questions, 2 prevents killing (brute force killing by clicking 5 times the panel close button in fast succession is possible though)
	variable	xL, xR, yT, yB
	xL	= 						xOfs	+ ( bLeft	?	0		:	GetIgorAppPixelX()  -	xSize - 4 )	
	xR	= 						xOfs	+ ( bLeft	?	xSize		:	GetIgorAppPixelX()  - 		4 )
//	yT	= kMAGIC_Y_OFFSET_PIXEL +	yOfs	+ ( bTop	?	0		:	GetIgorAppPixelY()  - 	kMAGIC_Y_MISSING_PIXEL - ySize	)
//	yB	= kMAGIC_Y_OFFSET_PIXEL +	yOfs	+ ( bTop	?	ySize		:	GetIgorAppPixelY()  -	kMAGIC_Y_MISSING_PIXEL	)
	yT	= kMAGIC_Y_OFFSET_PIXEL +	yOfs	+ ( 1 - bTop ) * (	GetIgorAppPixelY()  - 	kMAGIC_Y_MISSING_PIXEL - ySize	)
	yB	= kMAGIC_Y_OFFSET_PIXEL +	yOfs	+ ( 1 - bTop ) * ( GetIgorAppPixelY()  -	kMAGIC_Y_MISSING_PIXEL - ySize ) + ySize
	NewPanel /W=( xL, yT, xR, yB ) /K=( nKill)  /N=$sWin  as  sTitle			
End	
	
	 
Function		MoveWindow1( sWin, bLeft, xOfs, xSize, bTop, yOfs, ySize )
// Position an existing window precisely with or without an offset (in pixel) on any border of the Igor main window.  Derived from  'NewPanel1()'  and therefore mainly applicable but not limited to  panels 
	string  	sWin
	variable	bLeft, bTop			// border onto which to place the window
	variable	xOfs, yOfs				// offset from border in pixel. Positive values will move right or down
	variable	xSize, ySize			// the window size in pixel
	variable	xL, xR, yT, yB
	variable	xRmax, yBmax
	variable	Pix2pts	= kIGOR_POINTS72 / screenresolution
	
	// Version1 : Will possibly position parts of the panel off-screen if panel size increases
	 GetWindow 	    $sWin , wsize		// Extract previous window position and size. Keep only position and discard size as the size may have changed in the meantime due to more or less columns or rows.
	 MoveWindow /W=$sWin	V_Left ,  V_top , V_Left +  xSize * kIGOR_POINTS72/screenresolution ,  V_top + ySize * kIGOR_POINTS72/screenresolution

	// Version2: Will move panel top left corner so that no part of the panel will be positioned off-screen if panel size increases
//	GetWindow 	    $sWin , wsize		// Extract previous window position and size. Keep only position and discard size as the size may have changed in the meantime due to more or less columns or rows.
//	xL		= V_Left	/ Pix2Pts
//	xR		= V_Left	/ Pix2Pts + xSize
//	yT		= V_Top	/ Pix2Pts
//	yB		= V_Top	/ Pix2Pts + ySize 
//	xRmax	= 						xOfs	+ ( bLeft	?	xSize		:	GetIgorAppPixelX()  - 		4 )
//	yBmax	= kMAGIC_Y_OFFSET_PIXEL +	yOfs	+ ( bTop	?	ySize		:	GetIgorAppPixelY()  -	kMAGIC_Y_MISSING_PIXEL	)
//	if ( xR > xRmax )
//		xL	= 						xOfs	+ ( bLeft	?	0		:	GetIgorAppPixelX()  -	xSize - 4 )	
//		xR	= 						xOfs	+ ( bLeft	?	xSize		:	GetIgorAppPixelX()  - 		4 )
//	elseif ( yB > yBmax )
//		yT	= kMAGIC_Y_OFFSET_PIXEL +	yOfs	+ ( bTop	?	0		:	GetIgorAppPixelY()  - 	kMAGIC_Y_MISSING_PIXEL - ySize	)
//		yB	= kMAGIC_Y_OFFSET_PIXEL +	yOfs	+ ( bTop	?	ySize		:	GetIgorAppPixelY()  -	kMAGIC_Y_MISSING_PIXEL	)
//	endif
//	MoveWindow /W=$sWin	xL  * Pix2pts,  yT * Pix2pts,  xR * Pix2pts,  yB * Pix2pts
End	
	
	 
Function		Panel3Main( sWin, sPnTitle, sF, xPos, yPos )
// Builds and updates the main panels (e.g. FPulse, FEval ) . Checks whether panel exists already or not. The Panel window creation macro and the window itself have the same name
// Properties of the main panels:
// permanent, can not and should not be closed, can not and should not be minimised, are initialised and built in 1 step, often need recomputing/resizing/redrawing when e.g. the number of regions or fits changes  
	string  	sWin, sPnTitle, sF
	variable	xPos, yPos												// panel position in %
	variable	xLoc, xLocMax, yLoc, yLocMax									// panel position in pixel
	
	string		sPnWvNm = PanelWvNm( sF, sWin )								// 051115 required for the Help
	variable	xSize, ySize												// panel size
	string  	lstPosX 	= "", lstPosY 	= ""									// where the controls will be positioned. Index is control number.
	string  	lstTabGrp	= "", lstTabcoBeg= "", lstTabcoEnd	= ""					// where the tab frames will be positioned. These lists are indexed by TabGrp (including pseudo-tabs (end=-1) for which no tab frame is drawn)
	string  	llstTypes	= "", 	llstCNames	= ""
	string 	lllstTabTi	= "",  llstBlkTi	= "", lllstRowTi	= "", lllstColTi	= "", lllstVisibility = "", llstMode	= ""	
	variable	pt2pix	= screenresolution / kIGOR_POINTS72
	// Killing the whole panel is not necessary and should be avoided as it makes the screen flicker. It is sufficient to update the tabs and the 'Regions' panel area (either adjust size or just clear/fill this area).
	if ( WinType( sWin ) != kPANEL )											// only if the panel does not yet  exist ..

		NewPanel /W=( 5000, -20, 5100, 10 ) /K= 2 /N=$sWin  as  sPnTitle			// K=2 prevents closing. We build a preliminary panel (very small and off-screen) so that 'PnInitVars()' can construct the globals and the controls. Different approach: 1.check in'PnInitVars' existance of controls  2.pass parameter 'bDoBuildControl'
		stPnInitVars( sF, sWin, $sPnWvNm )
		stPnSize( sF, sWin, $sPnWvNm, xSize, ySize, lstPosX, lstPosY, lstTabGrp, lstTabcoBeg, lstTabcoEnd, llstTypes, llstCNames, lllstTabTi, llstBlkTi, lllstRowTi, lllstColTi, lllstVisibility, llstMode )	// most parameters are references 
		xLocMax	= GetIgorAppPixelX() -  Xsize - 4								// the rightmost panel position 
		xLoc 	= min( max( 0, XLocMax * xPos / 100 ), xLocMax )
		yLocMax 	= GetIgorAppPixelY() -  ySize - kY_MISSING_PIXEL_BOT			// the lowest panel position			// todo ???? ysize pixel
		yLoc	 	= kY_MISSING_PIXEL_TOP + min( max( 0, YLocMax * yPos / 100 ), YLocMax )

		MoveWindow /W = $sWin  xLoc / pt2pix,   yLoc / pt2pix,    (xLoc + xSize) / pt2pix, (yLoc + ySize) / pt2pix 	// now resize the preliminary panel to the correct position and size
		stPnDraw( sF, sWin, $sPnWvNm, xSize, ySize, lstPosX, lstPosY, lstTabGrp, lstTabcoBeg, lstTabcoEnd, llstTypes, llstCNames, lllstTabTi,  llstBlkTi, lllstRowTi, lllstColTi, lllstVisibility, llstMode )	// reconstruct the panel at its previous position	
	else																// only if the panel does already  exist then ignore the passed position..
		stPnInitVars( sF, sWin, $sPnWvNm )									// when increasing the number of blocks( e.g. =regions) or when loading another setting or script (number of chans=gains changes)  then create the additionally required controls (and their underlying variables) 
		stPnSize( sF, sWin, $sPnWvNm, xSize, ySize, lstPosX, lstPosY, lstTabGrp, lstTabcoBeg, lstTabcoEnd, llstTypes, llstCNames, lllstTabTi, llstBlkTi, lllstRowTi, lllstColTi, lllstVisibility, llstMode )	// most parameters are references 
		GetWindow     $sWin , wsize										// ...but get its current position		
		// printf "\t\tPanel3Main  Update\t%s    left:%4d  \t(>%.0lf) \t>%.1lf\t\ttop :%d \t(>%.0lf) \t->y %.1lf \r", sWin, V_left, V_left * screenresolution / kIGOR_POINTS72,  V_right * screenresolution / kIGOR_POINTS72*100/GetIgorAppPixelX(),  V_top, V_top * screenresolution / kIGOR_POINTS72, V_bottom * screenresolution / kIGOR_POINTS72*100/GetIgorAppPixelY()
		MoveWindow /W = $sWin V_left, V_top, V_left + xSize / pt2pix,  V_top + ySize / pt2pix 
		stPnDraw( sF, sWin, $sPnWvNm, xSize, ySize, lstPosX, lstPosY, lstTabGrp, lstTabcoBeg, lstTabcoEnd, llstTypes, llstCNames, lllstTabTi,  llstBlkTi, lllstRowTi, lllstColTi, lllstVisibility, llstMode )	// reconstruct the panel at its previous position	
		ControlUpdate /A /W = $sWin										// avoid that popupmenu and setvariable 'hangs' (=stays hidden)  until some next user action
	endif
End


Function		Panel3SubHide( sWinName )
	string  	sWinName
	MoveWindow /W = $sWinName  0, 0, 0, 0 						// minimise the panel to an icon
End


// 2021-03--10
Function		Panel3Sub( sWin, sPnTitle, sF, xPos, yPos, nMode )
// Builds and updates the sub panels (e.g. Misc, DispStimulus, ...) . Checks whether panel exists already or not. The Panel window creation macro and the window itself have the same name
// Properties of the sub panels:
// can be minimised, can not really be closed but are minimised instead, are initialised and built in 2 different steps, should remember their position when closed/minimised.  Up till now they don't need recomputing/resizing/redrawing....
	string  	sWin, sPnTitle, sF
	variable	xPos, yPos												// panel position in %
	variable	nMode			// nMode = kPANEL_INIT 	: build a preliminary panel (very small and off-screen=hidden) just to construct the underlying controls and global variables which might be needed even if the panel is never displayed. 
							// nMode = kPANEL_DRAW	: build the panel and the underlying controls and global variables and display the panel 
	variable	bAllowKill	  = 2	// 2 prevents closing,  1 allows closing.
	Panel3Sub_( sWin, sPnTitle, sF, xPos, yPos, nMode, bAllowKill )
End

Function		Panel3Sub_( sWin, sPnTitle, sF, xPos, yPos, nMode, bAllowKill )
// Builds and updates the sub panels (e.g. Misc, DispStimulus, ...) . Checks whether panel exists already or not. The Panel window creation macro and the window itself have the same name
// Properties of the sub panels:
// can be minimised, can not really be closed but are minimised instead, are initialised and built in 2 different steps, should remember their position when closed/minimised.  Up till now they don't need recomputing/resizing/redrawing....
	string  	sWin, sPnTitle, sF
	variable	xPos, yPos												// panel position in %
	variable	nMode			// nMode = kPANEL_INIT 	: build a preliminary panel (very small and off-screen=hidden) just to construct the underlying controls and global variables which might be needed even if the panel is never displayed. 
							// nMode = kPANEL_DRAW	: build the panel and the underlying controls and global variables and display the panel 
	variable	bAllowKill			//  = 1 	:  allows closing.
							//  = 2	:  prevents closing.

	variable	xLoc, xLocMax, yLoc, yLocMax									// panel position in pixel
	
	string		sPnWvNm = PanelWvNm( sF, sWin )
	variable	xSize, ySize												// panel size
	string  	lstPosX 	= "", lstPosY 	= ""									// where the controls will be positioned. Index is control number.
	string  	lstTabGrp	= "", lstTabcoBeg= "", lstTabcoEnd	= ""					// where the tab frames will be positioned. These lists are indexed by TabGrp (including pseudo-tabs (end=-1) for which no tab frame is drawn)
	string  	llstTypes	= "", 	llstCNames	= ""
	string 	lllstTabTi	= "",  llstBlkTi	= "", lllstRowTi	= "", lllstColTi	= "", lllstVisibility = "", llstMode	= ""	
	variable	pt2pix	= screenresolution / kIGOR_POINTS72
	variable	hidden	= TRUE

	// If the panel does not yet  exist  or if  invisible  'Initialising'  is specified..
	if (  WinType( sWin ) != kPANEL )											// PANEL does not yet exist
		//NewPanel /W=(5000, -20, 5100, 10  /K= 2 /N=$sWin  as  sPnTitle			// K=2 prevents closing. We build a nearly invisible panel (very small and mostly off-screen) so that 'PnInitVars()' can construct the globals and the controls. Different approach: 1.check in'PnInitVars' existance of controls  2.pass parameter 'bDoBuildControl'
		NewPanel /W=( 5000, -20, 5100, 10 ) /K=(bAllowKill) /N=$sWin  as  sPnTitle	// K=1 allows closing. We build a nearly invisible panel (very small and mostly off-screen) so that 'PnInitVars()' can construct the globals and the controls. Different approach: 1.check in'PnInitVars' existance of controls  2.pass parameter 'bDoBuildControl'
		// NewPanel /W=(  0,  2000, 30,  30 ) /K= 1 /N=$sWin  as  sPnTitle			// K=1 allows closing. We build a nearly invisible panel (very small and mostly off-screen) so that 'PnInitVars()' can construct the globals and the controls. Different approach: 1.check in'PnInitVars' existance of controls  2.pass parameter 'bDoBuildControl'
		stPnInitVars( sF, sWin, $sPnWvNm )
			
		stPnSize( sF, sWin, $sPnWvNm, xSize, ySize, lstPosX, lstPosY, lstTabGrp, lstTabcoBeg, lstTabcoEnd, llstTypes, llstCNames, lllstTabTi, llstBlkTi, lllstRowTi, lllstColTi, lllstVisibility, llstMode )	// most parameters are references 
		xLocMax	= GetIgorAppPixelX() -  Xsize - 4								// the rightmost panel position 
		xLoc 	= min( max( 0, XLocMax * xPos / 100 ), xLocMax )
		yLocMax 	= GetIgorAppPixelY() -  ySize - kY_MISSING_PIXEL_BOT			// the lowest panel position			// todo ???? ysize pixel
		yLoc	 	= kY_MISSING_PIXEL_TOP + min( max( 0, YLocMax * yPos / 100 ), YLocMax )
		// printf "\t\t\tPanel3Sub( mode: %d ) \t[Init:%d, Draw:%d]  \t Mode was  INIT or non-existant \t\t\tPanel  '%s' .\tSetting   \tHidden:%2d \txLoc:%3d \tyLoc:%3d\t \r", nMode, kPANEL_INIT, kPANEL_DRAW, sWin , hidden, xLoc, yLoc 
		ModifyPanel  /W=$sWin  fixedSize = 1								// the user cannot change the size, but closing and minimising cannot be prevented in this way
		MoveWindow /W = $sWin  xLoc / pt2pix,   yLoc / pt2pix,    (xLoc + xSize) / pt2pix, (yLoc + ySize) / pt2pix 	// now resize the preliminary panel to the correct position and size
		stPnDraw( sF, sWin, $sPnWvNm, xSize, ySize, lstPosX, lstPosY, lstTabGrp, lstTabcoBeg, lstTabcoEnd, llstTypes, llstCNames, lllstTabTi,  llstBlkTi, lllstRowTi, lllstColTi, lllstVisibility, llstMode )// construct the panel controls
		if (  nMode & kPANEL_INIT ) 
			// printf "\t\t\tPanel3Sub( mode: %d ) \t[Init:%d, Draw:%d]  \t Mode was  INIT   : Drawing  non-existant \tPanel  '%s' .\tRetrieving \tHidden:%2d \txLoc:%3d \tyLoc:%3d\t \r", nMode, kPANEL_INIT, kPANEL_DRAW, sWin , hidden, xLoc, yLoc
			// 2021-03--10
			//MoveWindow 	/W=$sWin  0 , 0 , 0 , 0						// hide the window 	// Igor5 syntax, Igor 6 has  SetWindow $sNB, hide = 0/1
			SetWindow $sWin, hide = 1									// hide the window 
		else
			// printf "\t\t\tPanel3Sub( mode: %d ) \t[Init:%d, Draw:%d]  \t Mode was DRAW : Drawing  non-existant \tPanel  '%s' .\tRetrieving \tHidden:%2d \txLoc:%3d \tyLoc:%3d\t \r", nMode, kPANEL_INIT, kPANEL_DRAW, sWin , hidden, xLoc, yLoc
		endif
	else																	// PANEL exists already
		if (  nMode & kPANEL_INIT ) 

			stPnInitVars( sF, sWin, $sPnWvNm )								// when increasing the number of blocks( e.g. =regions) or when loading another setting or script (number of chans=gains changes)  then create the additionally required controls (and their underlying variables) 
			stPnSize( sF, sWin, $sPnWvNm, xSize, ySize, lstPosX, lstPosY, lstTabGrp, lstTabcoBeg, lstTabcoEnd, llstTypes, llstCNames, lllstTabTi, llstBlkTi, lllstRowTi, lllstColTi, lllstVisibility, llstMode )	// most parameters are references 
			GetWindow     $sWin , wsize									// ...but get its current position		
			// printf "\t\tPanel3Main  Update\t%s    left:%4d  \t(>%.0lf) \t>%.1lf\t\ttop :%d \t(>%.0lf) \t->y %.1lf \r", sWin, V_left, V_left * screenresolution / kIGOR_POINTS72,  V_right * screenresolution / kIGOR_POINTS72*100/GetIgorAppPixelX(),  V_top, V_top * screenresolution / kIGOR_POINTS72, V_bottom * screenresolution / kIGOR_POINTS72*100/GetIgorAppPixelY()
			MoveWindow /W = $sWin V_left, V_top, V_left + xSize / pt2pix,  V_top + ySize / pt2pix 
			stPnDraw( sF, sWin, $sPnWvNm, xSize, ySize, lstPosX, lstPosY, lstTabGrp, lstTabcoBeg, lstTabcoEnd, llstTypes, llstCNames, lllstTabTi,  llstBlkTi, lllstRowTi, lllstColTi, lllstVisibility, llstMode )	// reconstruct the panel at its previous position	

			// printf "\t\t\tPanel3Sub( mode: %d ) \t[Init:%d, Draw:%d]  \t Mode was  INIT   : Drawing  existing \t\tPanel  '%s' .\tRetrieving \tHidden:%2d \txLoc:%3d \tyLoc:%3d\t \r", nMode, kPANEL_INIT, kPANEL_DRAW, sWin , hidden, xLoc, yLoc
			MoveWindow 	/W=$sWin  0 , 0 , 0 , 0						// hide the window  	// Igor5 syntax, Igor 6 has  SetWindow $sNB, hide = 0/1
		endif
		if (  nMode & kPANEL_DRAW )										// Now the panel exists.  Check if  ( also )  visible drawing is required.
			// printf "\t\t\tPanel3Sub( mode: %d ) \t[Init:%d, Draw:%d]  \t Mode was DRAW : Drawing  existing \t\tPanel  '%s' .\tRetrieving \tHidden:%2d \txLoc:%3d \tyLoc:%3d\t \r", nMode, kPANEL_INIT, kPANEL_DRAW, sWin , hidden, xLoc, yLoc
			// 2021-03--10
			//MoveWindow 	/W=$sWin  1 , 1 , 1 , 1						// restore the icon to original window size
			SetWindow $sWin, hide = 1									// hide the window 
			// 2009-10-16 b
			DoWindow /F   $sWin										//  hide or display the panel and move it to the front 
			//ControlUpdate /A /W = $sWin									// avoid that popupmenu and setvariable 'hangs' (=stays hidden)  until some next user action
		endif
	endif
End

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

static Function	stPnCreateTabcoVars( sFsPnWndNm, nTabco )
// Creates underlying shadow variables for  the tabcontrols needed for initialising the tabs as selected by the user
	string  	sFsPnWndNm										// the data folder for the variable  and  the panel name
	variable	nTabco											// the index of the Tabcontrol, not the tab
	string		sDFSave	= GetDataFolder( 1 )							// The following functions do NOT restore the CDF so we remember the CDF in a string .
	string  	sFoTabcoNmIdx  = stPnBuildFoTabcoNm( sFsPnWndNm, nTabco )
	nvar	/Z var	= $sFoTabcoNmIdx
	if ( ! nvar_Exists( var ) )
 		variable /G  $sFoTabcoNmIdx
	endif	
	// printf "\t\tPnCreateTabcoVars(    \t%s\t\t\t\t\t\t\t) \tconstructing (len:%3d):\tvar_tab :\t%s\t  \r", pd( sFsPnWndNm,24), strlen(sFoTabcoNmIdx)  ,  pd(sFoTabcoNmIdx,27)
	SetDataFolder sDFSave					// Restore CDF from the string  value
End

static Function	stPnTabcoIndex( sFsPnWndNm, nTabco )
// Returns currently selected tab 
	string  	sFsPnWndNm										// the data folder for the variable  and  the panel name
	variable	nTabco											// the index of the Tabcontrol, not the tab
	string  	sFoTabcoNmIdx  = stPnBuildFoTabcoNm( sFsPnWndNm, nTabco )
	nvar		TabIdx	= $sFoTabcoNmIdx
	// printf "\t\tPnTabcoIndex( \t%s\t %d ) ->\t%s\t =\tTabidx:%2d\t \r", sFsPnWndNm, nTabco, sFoTabcoNmIdx, TabIdx
	return	TabIdx
End

static Function	stPnTabcoIndexSet( sFsPnWndNm, nTabco, nTab )
// Sets currently selected tab 
	string  	sFsPnWndNm										// the data folder for the variable  and  the panel name
	variable	nTabco, nTab										// the index of the Tabcontrol   and  the tab
	string  	sFoTabcoNmIdx  = stPnBuildFoTabcoNm( sFsPnWndNm, nTabco )
	nvar		TabIdx	= $sFoTabcoNmIdx
	TabIdx	= nTab
	// printf "\t\tPnTabcoIndexSet( \t%s\t %d  %d ) ->setting  \t%s\t =\tTabidx:%2d\t \r", sFsPnWndNm, nTabco, nTab, sFoTabcoNmIdx, TabIdx
End

static Function	stPnCreateControls( nType, sF, sWin, sNm, lstTabTi, lstBlkTi, lstRowTi, lstColTi, lstInitVal, lstVisibility )
// Creates underlying shadow variables for   checkboxes,  radio buttons and popmenus. Set them with initial values.  Draw the controls.
	variable	nType
	string  	sF, sWin, sNm							// the variable base name without indices
	string  	lstTabTi, lstBlkTi, lstRowTi, lstColTi, lstInitVal
	string		lstVisibility								// each control stores itself its initial visibility as 'UserData'  
	string  	sFsSub	= sF + sWin
	variable	nTab, nBlk, nRow, nCol					// the number of entries in each dimension
	variable	nTabs	= stTabCnt( lstTabTi )
	string  	sFCNm
	variable	len, bVisib
	variable	nCreated	= 0
	string		sVarNmIdx, sFoVarNmIdx, sFoRadVar
	// printf "\t\t\tPnCreateControls( %s\t%s\t )\t%s\t%s\t%s\t%s\t%s\tvis:%s\t  \r", pd( sFsSub,15),  pd( sNm,9), pd(lstInitVal,32), pd(lstTabTi,18), pd(lstBlkTi, 18), pd( lstRowTi,18), pd( lstColTi,18) , lstVisibility[0,100]
	variable    mxTabs = max(  nTabs, 1 )		// Even if there are no tabs (TabCnt( lstTabTi )=0)  there are still controls which must be drawn so the inner loop is at least executed once
	for ( nTab = 0; nTab <  mxTabs; nTab += 1 )
		for ( nBlk = 0; nBlk < stBlkCnt( lstBlkTi, nTab ); nBlk += 1 )

			// We must create the ONE and ONLY global variable (with the last 2 indices truncated) only for Radio button arrays and for Checkbox arrays. It is not needed for single checkboxes but it is created here as well (could be improved...) 
			if ( nType == kCB  ||  nType == kRAD )										
				sVarNmIdx		= stPnBuildVNmIdx( sNm, nTab, nBlk, 0, 0 )			// this is not the final valid name as row and column is missing. Is is built only for readio button and checkbox arrays
				sFoVarNmIdx	= sFsSub + ":" + sVarNmIdx
				nvar	     /Z var	= $sFoVarNmIdx
				if ( ! nvar_exists( var ) )										// keep the settings when going to the next file, initialise only if there are no settings yet
					sFoRadVar	= RemoveEnding( RemoveEnding( sFoVarNmIdx ) )	// We also must create the ONE and ONLY global variable for the radio button group by stripping the last 2 indices...
					variable /G $sFoRadVar	= 0
					nvar	     nInitRadAndCbIdx	= $sFoRadVar
				endif
			endif

			for ( nRow = 0; nRow <  stRowCnt( lstRowTi ); nRow += 1 )
				for ( nCol = 0; nCol < stColCnt( lstColTi ); nCol += 1 )
					
					sVarNmIdx	= stPnBuildVNmIdx( sNm, nTab, nBlk, nRow, nCol )		// can be the name of a variable or of a string
					bVisib			= stInitValue( sVarNmIdx, lstVisibility, 1 )			// If initialisation values have been specified  in  'wPn[]' then use them , if not use the last parameter as default

					if ( nType == kSTR )										// only  for  SetVariable  in string mode 
						string    sFoVarNmIdxS = sFsSub + ":" + sVarNmIdx			// cannot use 'sFoVarNmIdx' also for a string
						len	= strlen(sFoVarNmIdxS)  
						svar	   /Z str	= $sFoVarNmIdxS
						if ( ! svar_exists( str ) )										// keep the settings when going to the next file, initialise only if there are no settings yet
					 		string   /G     	   $sFoVarNmIdxS
							svar		str    	= $sFoVarNmIdxS

							sFCNm		= ReplaceString( ":", sFoVarNmIdxS, "_" )			//  e.g.  root:uf:evo:evl:svVar000  ->  root_uf_evo_de_svVar000
							str			= stInitString( sVarNmIdx, lstInitVal, "" )				// If initialisation values have been specified  in  'wPn[]' then use them , if not use the last parameter as default
							SetVariable  $sFCNm,	win = $sWin,	value = strIdx
							SetVariable  $sFCNm,	win = $sWin, Userdata( bVisib ) = num2str( bVisib )//   each control stores itself its initial visibility as 'UserData'  	
							nCreated	+= 1
							// printf "\t\t\tPnCreateControls( %s\t%s\t) %2d\t%s\t%s:\t\tvi:%d\t%s\t%s\t%s\t%s\tSets to '%s'\r", pd( sFsSub,15),  pd( sNm,9),  len, "NEW S", pd(sFoVarNmIdxS,29) , bVisib,  pd(lstTabTi,18), pd(lstBlkTi, 18), pd( lstRowTi,18), pd( lstColTi,18) , str
						else
							// printf "\t\t\tPnCreateControls( %s\t%s\t) %2d\t%s\t%s:\t\tvi:%d\t%s\t%s\t%s\t%s\t  \r", pd( sFsSub,15),  pd( sNm,9),  len, "       S", pd(sFoVarNmIdxS,29) , bVisib,  pd(lstTabTi,18), pd(lstBlkTi, 18), pd( lstRowTi,18), pd( lstColTi,18)   
						endif
					else
						sFoVarNmIdx	= sFsSub + ":" + sVarNmIdx
						len	= strlen( sFoVarNmIdx )  
						nvar	     /Z var	= $sFoVarNmIdx
						if ( ! nvar_exists( var ) )									// keep the settings when going to the next file, initialise only if there are no settings yet
					 		variable /G	   $sFoVarNmIdx
							nvar		 var	= $sFoVarNmIdx
							sFCNm	= ReplaceString( ":", sFoVarNmIdx, "_" )			//  e.g.  root:uf:evo:evl:pmVar000  ->  root_uf_evo_de_pmVar000
							if ( nType == kSV )										
								var 	= stInitValue( sVarNmIdx, lstInitVal, 0 )				// If initialisation values have been specified  in  'wPn[]' then use them , if not use the default value of 0
								SetVariable  $sFCNm,	win = $sWin,	value = var
								SetVariable  $sFCNm,	win = $sWin, Userdata( bVisib ) = num2str( bVisib )	
							endif	
							if ( nType == kSTC )										
								var 	= stInitValue( sVarNmIdx, lstInitVal, 0 )				// If initialisation values have been specified  in  'wPn[]' then use them , if not use the default value of 0
								CustomControl $sFCNm, win = $sWin,	value = var
								CustomControl $sFCNm, win = $sWin, Userdata( bVisib ) = num2str( bVisib )	
							endif	

							if ( nType == kVD )										
								//var 	= stInitValue( sVarNmIdx, lstInitVal, 0 )				// If initialisation values have been specified  in  'wPn[]' then use them , if not use the default value of 0
								//ValDisplay	$sFCNm, win = $sWin,	value = var
								ValDisplay	$sFCNm, win = $sWin, Userdata( bVisib ) = num2str( bVisib )	
							endif	

							if ( nType == kPM )									// the default value of 0 (appropriate for other controls) would set a POPUPMENU to a locked state effectively disabling any input 
								var 	= stInitValue( sVarNmIdx, lstInitVal, 1 )				// If initialisation values have been specified  in  'wPn[]' then use them , if not use the first (=topmost) list entry having the index 1
								PopupMenu 	$sFCNm,	win = $sWin,	mode = var
								PopupMenu 	$sFCNm,	win = $sWin, Userdata( bVisib ) = num2str( bVisib )	
							endif	

							if ( nType == kBUP )										
								var 	= stInitValue( sVarNmIdx, lstInitVal, 0 )				// If initialisation values have been specified  in  'wPn[]' then use them , if not use the default value of 0
								Checkbox		$sFCNm,	win = $sWin,	value = var
								Checkbox		$sFCNm,	win = $sWin, Userdata( bVisib ) = num2str( bVisib )	
							endif	

							if ( nType == kBU )	
								var 	= stInitValue( sVarNmIdx, lstInitVal, 0 )				// 060510 buttons may be switched between states: they now have an initial value  and they may switch titles and colors depending on the state
								Button		$sFCNm,	win = $sWin, Userdata( bVisib ) = num2str( bVisib )	
							endif	


							if ( nType == kCB )										
								var 	= stInitValue( sVarNmIdx, lstInitVal, 0 )				// If initialisation values have been specified  in  'wPn[]' then use them , if not use the last parameter as default
								if ( var == 1 )													// This  Tab/Blk/Row/Col-combination  specifies the one radio button to be initalised with the 'ON' state, so we compute the linear index.
									nInitRadAndCbIdx += stCheckboxPowers3( nTab, nBlk, nRow, nCol, lstTabTi, lstBlkTi, lstRowTi, lstColTi ) //.store the state of the checkbox group in this ONE global linear index variable which must match nBlk/NRow/nCol
									// printf "\t\t\tPnCreateControls( %s\t%s\t) %2d\t%s\t%s:\t%g\tvi:%d\t%s\t%s\t%s\t%s\t-> %s:%2d <-LinIdx  \r", pd( sFsSub,15),  pd( sNm,9),  len, "new Cb", pd(sFoVarNmIdx,29) , var, bVisib, pd(lstTabTi,8), pd(lstBlkTi, 8), pd( lstRowTi,18), pd( lstColTi,18) , sFoRadVar, nInitRadAndCbIdx
								endif
								Checkbox	  $sFCNm,	win = $sWin,	value = var
								Checkbox	  $sFCNm,	win = $sWin, Userdata( bVisib ) = num2str( bVisib )	
							endif	

							if ( nType == kRAD )									// Radio buttons :  This can  be horizontal, vertical  or 2-dim arrays of radio buttons
								var	= stInitValue( sVarNmIdx, lstInitVal, 0 )				// If initialisation values have been specified  in  'wPn[]' then use them , if not use the last parameter as default
								if ( var == 1 )									// This  Tab/Blk/Row/Col-combination  specifies the one radio button to be initalised with the 'ON' state, so we compute the linear index.
									nInitRadAndCbIdx = stLinRadioButtonIndex3( nTab, nBlk, nRow, nCol, lstTabTi, lstBlkTi, lstRowTi, lstColTi )// store the state of the radio button group in this ONE global linear index variable which must match nBlk/NRow/nCol
									// printf "\t\t\tPnCreateControls( %s\t%s\t) %2d\t%s\t%s:\t%g\tvi:%d\t%s\t%s\t%s\t%s\t-> %s:%2d <-LinIdx  \r", pd( sFsSub,15),  pd( sNm,9),  len, "new Ra", pd(sFoVarNmIdx,29) , var, bVisib, pd(lstTabTi,18), pd(lstBlkTi, 8), pd( lstRowTi,8), pd( lstColTi,18) , sFoRadVar, nInitRadAndCbIdx
								endif
							endif	

							nCreated	+= 1
							
							// printf "\t\t\tPnCreateControls( %s\t%s\t) %2d\t%s\t%s:\t%g\tvi:%d\t%s\t%s\t%s\t%s\t  \r", pd( sFsSub,15),  pd( sNm,9),  len, "new V", pd(sFoVarNmIdx,29) , var, bVisib, pd(lstTabTi,18), pd(lstBlkTi, 18), pd( lstRowTi,18), pd( lstColTi,18)   
						else
							// printf "\t\t\tPnCreateControls( %s\t%s\t) %2d\t%s\t%s:\t%g\tvi:%d\t%s\t%s\t%s\t%s\t  \r", pd( sFsSub,15),  pd( sNm,9),  len, "       V", pd(sFoVarNmIdx,29) , var, bVisib,  pd(lstTabTi,18), pd(lstBlkTi, 18), pd( lstRowTi,18), pd( lstColTi,18)   
						endif			// nvar_exists( var )
					endif			// nType == kSTR
					
					if ( len  > 31 )
						DeveloperError( "Control name " + sFsSub + ":" + sVarNmIdx + " is too long (" + num2str( len ) + ") , allowed are 31 characters. " )
					endif

				endfor
			endfor
		endfor
	endfor
	return	nCreated
End



constant kXTRAPIX =3

static Function	stPnInitVars( sF, sWin, wPn )
//  
	string  	sF, sWin
	wave   /T	wPn
	variable	n, nCnt	= DimSize( wPn, 0 )
	string  	sType, sName, 	lstTabTi, lstBlkTi, lstRowTi, lstColTi, lstInitVal, lstVisibility
	variable	nType
	variable	nCreated	= 0
	// printf "\t\t\tPnInitVars( \t%s\t%s\t) \t-> PnCreateControls() \t  \r", pd( sF,15),  pd( sWin,15)
	for ( n = 0; n < nCnt; n += 1 )			// for each control in wPn[], no tab or any other expansions yet
		nType	= WhichListItem( RemoveWhiteSpace( StringFromList( kTYPE, wPn[ n ], ksSEP_WPN ) ), lstTYPE )
		sType	= StringFromList( nType, lstTYPE )
		sName	= RemoveWhiteSpace( StringFromList( kNAME,	wPn[ n ], ksSEP_WPN ) )
		lstTabTi	= ReplaceString( "\t", StringFromList( kTABS,	wPn[ n ], ksSEP_WPN ) , "" )
		lstBlkTi	= ReplaceString( "\t", StringFromList( kBLKS,	wPn[ n ], ksSEP_WPN ) , "" )
		lstRowTi	= ReplaceString( "\t", StringFromList( kROWTI,	wPn[ n ], ksSEP_WPN ) , "" )
		lstColTi	= ReplaceString( "\t", StringFromList( kCOLTI,	wPn[ n ], ksSEP_WPN ) , "" )
		lstInitVal	= ReplaceString( "\t", StringFromList( kINITVAL,	wPn[ n ], ksSEP_WPN ) , "" )
		lstVisibility	= ReplaceString( "\t", StringFromList( kVISIB,	wPn[ n ], ksSEP_WPN ) , "" )

		lstTabTi	= stPossiblyConvrtTitleFuncToList( sName, sF, sWin, lstTabTi )				// List of  tab 	 title lists no matter whether we had a function returning the titles or a direct list
		lstBlkTi	= stPossiblyConvrtTitleFuncToList( sName, sF, sWin, lstBlkTi )				// List of  block	 title lists no matter whether we had a function returning the titles or a direct list
		lstRowTi	= stPossiblyConvrtTitleFuncToList( sName, sF, sWin, lstRowTi )				// List of  row	 title lists no matter whether we had a function returning the titles or a direct list
		lstColTi	= stPossiblyConvrtTitleFuncToList( sName, sF, sWin, lstColTi )				// List of column title lists no matter whether we had a function returning the titles or a direct list
		lstInitVal	= stPossiblyConvrtTitleFuncToList( sName, sF, sWin, lstInitVal )				// List of initialisation values no matter whether we had a function returning the values or a direct list
		lstVisibility= stPossiblyConvrtTitleFuncToList( sName, sF, sWin, lstVisibility )				// List of visibilities no matter whether we had a function returning the values or a direct list
		// 051204 Note: A FormatEntry-function cannot be converted to a list right here as  the PopupMenu function executes code and requires parameters (win, controlname)  whereas SetVariable, ValDisplay etc only receive settings but do not execute code.
		// printf "\t\tPnInitVars( \t%d/%d\t'%s %s\t%s\t%s\t%s\t%s\t%s\tIV:%s\tVis:%s\t \r",  n, nCnt, sF,  pd( sWin,13),   pd( sName,19),  pd(lstTabTi,18), pd(lstBlkTi, 18), pd( lstRowTi,18), pd( lstColTi,18) , lstInitVal, lstVisibility
		nCreated	+= stPnCreateControls( nType, sF, sWin, sName, lstTabTi, lstBlkTi, lstRowTi, lstColTi, lstInitVal, lstVisibility )		
	endfor
	// printf "\t\t\tPnInitVars( \t%s\t%s\t) \thas created controls: %3d  \r", pd( sF,15),  pd( sWin,15) , nCreated
End



Function		PnUserWantsHelp( sWin, sCtrlname, nEventCode, sEventName, nEventMod, nControlType, bCbChecked, sHelpTopic )
	string  	sWin, sCtrlname, sEventName, sHelpTopic
	variable	nEventCode, nEventMod, nControlType, bCbChecked
	variable	bWantsHelp
//	if ( nControlType == kCI_SETVARIABLE )
//	 	bWantsHelp = ( nEventMod != 0  &&  nEventMod != 1 ) 			// For some reason SetVariable has a different EventModifier than all other controls. Anything but left mouse button, e.g. right mouse button or left mouse and  ALT, CTRL or SHIFT
//	else
	 	bWantsHelp = ( nEventMod != 0  &&  nEventMod != 1 ) 			// Anything but left mouse button, e.g. right mouse button or left mouse and  ALT, CTRL or SHIFT
//	endif
	// printf "\tPnUserWantsHelp() \t\t%s\t%s\tCod:%2d\t%s\tMod:%2d\tCType:%2d  (%s)\tbCbChecked:%2d\tbWantsHelp:%2d \tHT:'%s'\r", sWin, pd(sCtrlName,28), nEventCode, pd( sEventName, 8 ), nEventMod, nControlType, StringFromList( nControlType, klstCI_CONTROLTYPES ), bCbChecked, bWantsHelp, sHelpTopic
	if ( bWantsHelp )
		if (  nControlType == kCI_CHECKBOX )
			Checkbox $sCtrlName, win=$sWin , value = !bCbChecked	 	// as Igor inverts  the checkbox state even in the 'help' mode we must invert it a second time to restore the original state
		endif
		FDisplayHelpTopic( sHelpTopic )
	endif
	return	bWantsHelp
End

Function 		FDisplayHelpTopic( sHelpTopic )
// displays help topic but avoids error msg box when help topic is not found (prints warning instead)
        string 	sHelpTopic
//        variable 	prevErr	  = GetRTError( 0 )			// make sure that there is no error pending...
//        DisplayHelpTopic /K=1 sHelpTopic
// 	string  	sRTErrMsg  = GetRTErrMessage()
//        variable	err		  = GetRTError( prevErr == 0 )	 // clear error (by passing 1) only if it was caused by DisplayHelpTopic call.
//	if ( err )
//		// Alert(  kERR_LESS_IMPORTANT, StringFromList( 0, GetRTErrMessage() ) + " could not find the help topic  '" + sHelpTopic + "'  in any of the help files." )
//		// printf "Warn(err:%d) : %s could not find the help topic  '%s'  in any of the help files.  \r",  err, StringFromList( 0, GetRTErrMessage() ), sHelpTopic
//		printf "Warn(err:%d) : %s could not find the help topic  '%s'  in any of the help files.  \r",  err, StringFromList( 0, sRTErrMsg ), sHelpTopic
//		// InternalWarning( StringFromList( 0, GetRTErrMessage() ) + " could not find the help topic  '" + sHelpTopic + "'  in any of the help files." )
//		// InternalError( "Help topic '" + sHelpTopic + "' not found by " + StringFromList( 0, GetRTErrMessage() ) )
// 	endif
//        return err
	//  just print warning if helptopic is not found
        DisplayHelpTopic /Z /K=1 sHelpTopic
	if ( V_flag )
		Alert(  kERR_LESS_IMPORTANT, " Could not find the help topic  '" + sHelpTopic + "'  in any of the help files." )
 	endif
	return V_flag
End

// 051121
//static Function		PnUserWantsHelpCB( sWin, sCtrlname, nEventMod, bValue, sHelpTopic )
//	string  	sWin, sCtrlname, sHelpTopic
//	variable	nEventMod, bValue
//	 printf "\tPnUserWantsHelpCB() \t\t%s\t%s\tMod:%2d\tCType:%2d\tvalue:%2d\tTopic:'%s'  \r", sWin, pd(sCtrlName,28), nEventMod, kCI_CHECKBOX, bValue, sHelpTopic
//	variable	bWantsHelp = ( nEventMod != 1 ) 					// anything but left mouse button, e.g. right mouse button or left mouse and  ALT, CTRL or SHIFT
//	if ( bWantsHelp )
//		Checkbox $sCtrlName, win=$sWin , value = !bValue		 	// as Igor inverts  the checkbox state even in the 'help' mode we must invert it a second time to restore the original state
//		// string  	sHelpTopic	= PnHelpTopic( sCtrlname )
//		FDisplayHelpTopic( sHelpTopic )
//	endif
//	return	bWantsHelp
//End

//Function	/S	PnHelpTopic( sCtrlname )
//	string  	sCtrlname
//	variable	len, n, nNameParts	= ItemsInList( sCtrlName, "_" )
//	string  	sFolders, sWin, sBaseName, sHelpTopic
//	sBaseName	= StringFromList( nNameParts-1, sCtrlName, "_" )														// e.g. 'root_uf_evo_de_PrevFile0000'   ->  'PrevFile0000' 
//	len			= strlen( sBaseName )
//	sBaseName	= sBaseName[ 0, len - 5 ]									// !!!DIF								// e.g. 'PrevFile0000'    			   ->  'PrevFile' 
//	sWin			= StringFromList( nNameParts-2, sCtrlName, "_" )														// e.g. 'root_uf_evo_de_PrevFile0000'   ->  'de' 
//	sFolders		= ReplaceString( "_", RemoveListItem( nNameParts-2, RemoveListItem( nNameParts-1, sCtrlName, "_" ) , "_" ), ":" )	// e.g. 'root_uf_evo_de_PrevFile0000'   ->  'root:uf:evo:' 
//	 sHelpTopic	= PnHelpTopic_( sFolders, sWin, sBaseName )
//	return	 sHelpTopic
//End
//
//
// Function	/S	PnHelpTopic_( sF, sWin, sCtrlBaseNm )
////  Retrieve from the name of a panel control the panel control's helptopic, which can be the explicit helptopic if specified in wPn( column kHELP )  OR else the control's title.
//// 051116   PnHelpTopic_()   and   OSHelpTopic_()   are very similar, differences are:
//// PnHelpTopic_    1. index  kNAME, kHELPTOPIC... 2. separator ksSEP_WPN (:)    3.  lstRowTi + lstColTi   4. sName is control base name and does not contain folders
//// These differences could be overcome and  PnHelpTopic_() /  OSHelpTopic_()  could be unified but this is not done as  OS (OldStyle...) will be made obsolete 
//// When this is accomplished  then simply all occurrences of   'OSUserWantsHelpxxxx()'   must be replaced by    'PnUserWantsHelpxxxx()'
//	string  	sF, sWin, sCtrlBaseNm
//	wave   /T	wPn			= $PanelWvNm( sF, sWin )
//	variable	nMatch, n, nCnt	= DimSize( wPn, 0 )
//	string  	sName, lstRowTi = "",  lstColTi = "", sHelpTopic = ""
//	for ( n = 0; n < nCnt; n += 1 )			// for each control in wPn[], no tab or any other expansions yet
//		sName	= RemoveWhiteSpace( StringFromList( kNAME,		wPn[ n ], ksSEP_WPN ) )
//		//			!!!DIF
//		nMatch	= ! cmpstr( sCtrlBaseNm, sName ) 
//		if ( nMatch )
//			sHelpTopic	= ReplaceString( "\t", StringFromList( kHELPTOPIC, 	wPn[ n ], ksSEP_WPN ) , "" )
//			sHelpTopic	= RemoveTrailingWhiteSpace( RemoveLeadingWhiteSpace( sHelpTopic ) )
//			// If the  HelpTopic field  is empty then use a combination of the row and column titles as the  HelpTopic
//			if ( strlen( sHelpTopic ) == 0 )
//				lstRowTi		= ReplaceString( "\t", StringFromList( kROWTI,		wPn[ n ], ksSEP_WPN ) , "" )
//				lstColTi		= ReplaceString( "\t", StringFromList( kCOLTI,		wPn[ n ], ksSEP_WPN ) , "" )
//				lstRowTi		= PossiblyConvertTitleFuncToList( sName, sF, sWin, lstRowTi )			// List of  row	 title lists no matter whether we had a function returning the titles or a direct list
//				lstColTi		= PossiblyConvertTitleFuncToList( sName, sF, sWin, lstColTi )				// List of column title lists no matter whether we had a function returning the titles or a direct list
//				sHelpTopic	= RemoveTrailingWhiteSpace( RemoveLeadingWhiteSpace( lstRowTi + lstColTi ) )
//			endif
//			 printf "\t\tPnHelpTopic_( %2d/%2d\t'%s %s\t%s\t%s\t%s\t%s\tReturning HelpTopic: '%s' \r",  n, nCnt, sF,  pd( sWin,13),   pd( sCtrlBaseNm,19),  pd( sName,19),  pd( lstRowTi,18), pd( lstColTi,18), sHelpTopic
//			return	sHelpTopic
//		endif
//	endfor
//	  printf "\t\tPnHelpTopic_(%s\t%s\t%s\t) \thas NOT found matching control and returns ''  \r", pd( sF,15),  pd( sWin,15) , pd( sCtrlBaseNm,19)
//	return	""
//End


 Function	/S	PnTESTAllTitlesOrHelptopics( sF, sWin )
//  DEBUG FUNCTION New style panel. printing all control titles into the history area. This text can then be cut and pasted into the help file. This ensures that all controls have a HelpTopic.
// e.g.  execute from the command line   PnTESTAllTitlesOrHelptopics( 'root:uf:evo:', 'de' )    or  PnTESTAllTitlesOrHelptopics( 'root:uf:evo:', 'set' )   or    PnTESTAllTitlesOrHelptopics( "root:uf:aco:", "mis" ) 
// e.g.  execute from the command line   PnTESTAllTitlesOrHelptopics( 'root:uf:evo:', 'sde' )   or  PnTESTAllTitlesOrHelptopics( 'root:uf:aco:', 'sda' )   or    PnTESTAllTitlesOrHelptopics( ksROOTUF_ , "rec" )
	string  	sF, sWin	
	wave   /T	wPn		= $PanelWvNm( sF, sWin )
	variable	n, nCnt	= DimSize( wPn, 0 )
	variable	nLen
	string  	sName, lstRowTi = "",  lstColTi = "", sHelpTopic = "", lstAllHelpTopics = ""
	for ( n = 0; n < nCnt; n += 1 )											// for each control in wPn[], no tab or any other expansions yet
		sName	= RemoveWhiteSpace( StringFromList( kNAME,		wPn[ n ], ksSEP_WPN ) )
		sHelpTopic	= ReplaceString( "\t", StringFromList( kHELPTOPIC, 	wPn[ n ], ksSEP_WPN ) , "" )
		sHelpTopic	= RemoveTrailingWhiteSpace( RemoveLeadingWhiteSpace( sHelpTopic ) )
		// If the  HelpTopic field  is empty then use a combination of the row and column titles as the  HelpTopic
		if ( strlen( sHelpTopic ) == 0 )
			lstRowTi		= ReplaceString( "\t", StringFromList( kROWTI,		wPn[ n ], ksSEP_WPN ) , "" )
			lstColTi		= ReplaceString( "\t", StringFromList( kCOLTI,		wPn[ n ], ksSEP_WPN ) , "" )
			lstRowTi		= stPossiblyConvrtTitleFuncToList( sName, sF, sWin, lstRowTi )				// List of  row	 title lists no matter whether we had a function returning the titles or a direct list
			lstColTi		= stPossiblyConvrtTitleFuncToList( sName, sF, sWin, lstColTi )				// List of column title lists no matter whether we had a function returning the titles or a direct list
			sHelpTopic	= RemoveTrailingWhiteSpace( RemoveLeadingWhiteSpace( lstRowTi + lstColTi ) )
		endif
		// printf "\t\tPnTESTAllTitlesOrHelptopics( %2d/%2d\t'%s %s\t%s\t%s\t%s\tReturn HelpTopic: '%s' \r",  n, nCnt, sF,  pd( sWin,13),   pd( sName,19),  pd( lstRowTi,18), pd( lstColTi,18), sHelpTopic
		lstAllHelpTopics += sHelpTopic  + ";"
	endfor
	nLen = strlen( lstAllHelpTopics )
	printf "PnTESTAllTitlesOrHelptopics( %s %s ) returns (nItems: %d, len: %d)  '%s  ....  %s'  \r", sF, sWin, ItemsInList( lstAllHelpTopics ), nLen, lstAllHelpTopics[ 0, 80 ], lstAllHelpTopics[  nLen - 80, inf ]
	print lstAllHelpTopics					// print will ( in contrast to 'printf' )  automatically break the string into multiple lines if the string is too long for 1 line
	return	lstAllHelpTopics
End





Function	/S	PanelWvNm( sF, sWin )
	string  	sF, sWin
	return	sF + sWin
End


static Function	stPnSize( sF, sWin, wPn, width, height, lstCtrlBlkPosX, lstCtrlBlkPosY, lstTabGrp, lstTabcoBeg, lstTabcoEnd, llstTypes, llstCNames, lllstTabTi, llstBlkTi, lllstRowTi, lllstColTi, lllstVisibility, llstMode  )
//  Compute  Y position of each control taking into account  Tab and Block grouping. Things are a bit complicated as...
//   -	we want to position controls at the same location when going from tab to tab (even if there are blank spaces in some tabs). This reduces screen flicker when switching between tabs.
//   -	we want to position controls of the same block grouped together
//  -	we want to have an easy-to-grasp  and  easy-to-edit  programmer interface ( i.e. the text wave  in  InitPanelXXX( sFolder, sPnOptions ) )
// As a consequence the lines in text wave  in  InitPanelXXX( sFolder, sPnOptions )   cannot be converted simply in one step into controls and control positions.
// String lists are  used here to store intermediary positions between computing steps.
	string  	sF, sWin
	wave   /T	wPn
	variable	&width, &height
	string  	&lstCtrlBlkPosX,	&lstCtrlBlkPosY				// where the controls will be positioned. Index is control number.
	string  	&lstTabGrp, &lstTabcoBeg,	&lstTabcoEnd	// where the tab frames will be positioned. These lists are indexed by TabGrp (including pseudo-tabs  (end=-1) for which no tab frame is drawn)
	string  	&llstTypes, &llstCNames, &lllstTabTi,  &llstBlkTi, &lllstRowTi, &lllstColTi , &lllstVisibility, &llstMode 

	variable	n, nCnt	= DimSize( wPn, 0 )
	string  	sType, sName, lstRowTi, lstColTi, lstVisibility, sActProc, sFormEntry, sInitVal
	variable	nType, bNextLn, xPos, nCiL, nOvSz, xBodySz, nRowCnt

	string  	sPrevTabs		= "150352", llstTabTi = ""
	string  	sPrevBlks		= "150352", lstBlkGrp		= "",  lstBlksMax = ""
	string  	lstBlkHeight	= ""
	string  	lstBlksInTab	= ""
	string  	lstRowInBlkGrp	= ""
	string  	lstBlkPosX = "",  lstBlkPosY = ""			// The 2dim position list ( nControl, nBlk )  .   The control position is the same for all Tabs. 
	variable	TabGrp = -1,  nTab, nTabs, TabHt = 0			

	variable	BlkGrp   = -1, nBlk,  BlkCnt, BlkHt, BlkMx, nMode, m
	variable	yr	= 0
	variable	rXSz, rXSzMx  = 0
	string  	sLongTitle, sLongestControl = ""
	string  	lstTabTi, lstBlkTi, lstMode

	// Pass 1 : Extract Tab and Block grouping.  Get longest control title.  Convert all titles from functions into title lists which are returned as references.
	for ( n = 0; n < nCnt; n += 1 )

		nType	= WhichListItem( RemoveWhiteSpace( StringFromList( kTYPE, wPn[ n ], ksSEP_WPN ) ), lstTYPE )
		sType	= StringFromList( nType, lstTYPE )
		sName	= RemoveWhiteSpace( StringFromList( kNAME, wPn[ n ], ksSEP_WPN ) )
		bNextLn	= str2num( StringFromList( kNXLN, wPn[ n ], ksSEP_WPN ) )
		xPos		= str2num( StringFromList( kXPOS, wPn[ n ], ksSEP_WPN ) )
		nCiL		= str2num( StringFromList( kMXPO, wPn[ n ], ksSEP_WPN ) )
		nOvSz	= str2num( StringFromList( kOVS, wPn[ n ], ksSEP_WPN ) )
		xBodySz	= str2num( StringFromList( kXBODYSZ, wPn[ n ], ksSEP_WPN ) )
		xBodySz	= ( numType( xBodySz ) == kNUMTYPE_NAN )  ?  0 : xBodySz				// convert a missing entries's  NaN  into  Zero
		lstTabTi	= ReplaceString( "\t", StringFromList( kTABS,   wPn[ n ], ksSEP_WPN ) , "" )
		lstBlkTi	= ReplaceString( "\t", StringFromList( kBLKS,    wPn[ n ], ksSEP_WPN ) , "" )
		lstRowTi	= ReplaceString( "\t", StringFromList( kROWTI, wPn[ n ], ksSEP_WPN ) , "" )
		lstColTi	= ReplaceString( "\t", StringFromList( kCOLTI,   wPn[ n ], ksSEP_WPN ) , "" )
		lstVisibility= ReplaceString( "\t", StringFromList( kVISIB,    wPn[ n ], ksSEP_WPN ) , "" )
		lstMode	= ReplaceString( "\t", StringFromList( kMODE,  wPn[ n ], ksSEP_WPN ) , "" )

		lstTabTi	= stPossiblyConvrtTitleFuncToList( sName, sF, sWin, lstTabTi )				// List of  tab 	 title lists no matter whether we had a function returning the titles or a direct list
		lstBlkTi	= stPossiblyConvrtTitleFuncToList( sName, sF, sWin, lstBlkTi )				// List of  block	 title lists no matter whether we had a function returning the titles or a direct list
		lstRowTi	= stPossiblyConvrtTitleFuncToList( sName, sF, sWin, lstRowTi )				// List of  row	 title lists no matter whether we had a function returning the titles or a direct list
		lstColTi	= stPossiblyConvrtTitleFuncToList( sName, sF, sWin, lstColTi )				// List of column title lists no matter whether we had a function returning the titles or a direct list
		lstVisibility= stPossiblyConvrtTitleFuncToList( sName, sF, sWin, lstVisibility )			
		llstTabTi	= AddListItem( lstTabTi,  llstTabTi,	ksSEP_CTRL, inf ) 	// List of tab 	 title lists of ALL controls
		llstBlkTi	= AddListItem( lstBlkTi,   llstBlkTi,		ksSEP_CTRL, inf ) 	// List of block 	 title lists of ALL controls
		lllstRowTi	= AddListItem( lstRowTi, lllstRowTi,	ksSEP_CTRL, inf ) 	// List of  Row  	 title lists of ALL controls
		lllstColTi	= AddListItem( lstColTi,   lllstColTi,	ksSEP_CTRL, inf ) 	// List of column title lists of ALL controls
		lllstVisibility	= AddListItem( lstVisibility,lllstVisibility,	ksSEP_CTRL, inf ) 
		llstMode	= AddListItem( lstMode,  llstMode,	ksSEP_CTRL, inf ) 	// List of mode lists (for blk processing) of ALL controls

		nTabs		= stTabCnt( lstTabTi )							// Number of  tabs    in  this control  with index 'n' 
		BlkMx	= 1	// 1 is the minimum value   TODO???
		for ( nTab = 0; nTab < nTabs; nTab += 1 )
			lstBlksInTab	= StringFromList( nTab, lstBlkTi, ksSEP_TAB )
			BlkCnt		= ItemsInList( lstBlksInTab, ksSEP_STD )
			BlkMx 		= max( BlkCnt, BlkMx )	// todo???
			// print nTab, nTabs, "\t", pd( lstBlksInTab, 15), "\t", BlkCnt, BlkMx
		endfor
		
		// Allow half-height lines	
		nRowCnt	= stRowCnt( lstRowTi )
		if ( nType == kSEP  &&  strlen( lstRowTi ) == 0  &&  strlen( lstColTi ) == 0 )  
			nRowCnt -= .5 										// Allow half-height lines	
		endif
		// printf "\t\t\tPnSize 0 Y\t%2d/%2d\t%d  %s\t%s\tnxl:%d\txpo:%d/%d\tovs:%d\ttbgr:%2d\t%s\t[%2d ]\tblgr:%2d\t%s\t%s\tmo:%d\troCt:%.1lf\t<- '%s' \t%s \r", n,nCnt,nType,sType, pd(sName,9), bNextLn,xPos,nCiL,nOvSz,TabGrp, pd(lstTabTi,12), nTabs, BlkGrp, pd(lstBlkTi,12), pd(lstMode,9),nMode,nRowCnt, lstRowTi , wPn[n]  

	//todo: insert additional block title line if nMode >=2.....	
		if ( cmpstr( sPrevTabs, lstTabTi ) ) 
 			TabGrp	+= 1
			BlkGrp	 =  0
			BlkHt	 = nRowCnt
			TabHt 	 = BlkHt
			yr	  	 = 0
			stPnCreateTabcoVars( sF+ sWin, TabGrp )				// create variables which store the selected tabs. Needed to initialise user tab settings. 
		else
			if ( cmpstr( sPrevBlks, lstBlkTi ) ) 
				BlkGrp	+= 1
				BlkHt	 = nRowCnt
				TabHt	+= BlkHt
				yr		 = 0
			else
				if ( bNextLn )
					BlkHt	+= nRowCnt
					TabHt	+= BlkHt
				else
					yr		-= nRowCnt		
				endif
			endif
		endif
		sPrevTabs		 =  lstTabTi
		sPrevBlks		 =  lstBlkTi
		lstTabGrp		= AddListItem( num2str( TabGrp),	lstTabGrp, ";", inf )
		lstBlkGrp		= AddListItem( num2str( BlkGrp ),	lstBlkGrp,   ";", inf )
		lstBlkHeight	= AddListItem( num2str( BlkHt ),	lstBlkHeight,   ";", inf )
		lstBlksMax		= AddListItem( num2str( BlkMx ),	lstBlksMax,   ";", inf )
		lstRowInBlkGrp	= AddListItem( num2str( yr ),	lstRowInBlkGrp, ";", inf )

		yr 	+= nRowCnt

		// Get the highest mode in this line which will be used. Any lower modes will be igored.
		// Todo: the 3 block view modes are unfinished....
		nMode = 0
		string  	lstMixModes	= ReplaceString( ksSEP_TAB, lstMode, "" )
		 for ( m = 0; m < ItemsInList( lstMixModes, ksSEP_STD ); m += 1 )
		 	nMode = max( nMode, str2num( StringFromList( m, lstMixModes, ksSEP_STD ) ) )
		endfor
		// print "\t\tPnSize ", lstMixModes, nMode
	 	sLongTitle	= stGetLongestTitle3( lstBlkTi, lstRowTi, lstColTi, nMode )	//todo  3 blockviews..........  The title from which the length is computed here must be the same which is finally drawn in 'PnDraw()' ...
		variable	nTitlePixel	= stTextLenToPixel( sLongTitle ) 			
		rXSz		= ( ( nTitlePixel + xBodySz + kXTRAPIX 		 ) * nCiL ) / ( 1+ nOvSz ) + ( nCiL -1- nOvSz ) * 3 // Only PopMenu and SetVariable has a BodySz>0 .  3 pixels are inserted between horizontal controls
		// rXSz	= ( ( nTitlePixel + xBodySz + kXTRAPIX - 6 * nOvSz ) * nCiL ) / ( 1+ nOvSz ) + ( nCiL -1- nOvSz ) * 3 // Only PopMenu and SetVariable has a BodySz>0 .  3 pixels are inserted between horizontal controls
		if ( rXSz > rXSzMx )
			rXSzMx	= max( rXSz, rXSzMx )
			sLongestControl	= "***** in Panel '" + sWin + "' ***** : '" + sName + "'  (is number " + num2str( n ) + " ,  '" + sType + "'   " + sLongTitle +  "' )      control len: " + num2str( rXSz )
		endif
		//todo: add a few xpixel if the control is within a tabcontrol so that the tabcontrol border is not covered  OR (perhaps easier)  add 1 blank in front ot titles which are located within Tabcontrols
		// Debug Y:
		// printf "\t\t\tPnSize 1 Y\t%2d/%2d\t%d  %s\t%s\tnxl:%d\txpo:%d/%d\tovs:%d\ttbgr:%2d\t%s\t[%2d ]\tblgr:%2d\t%s\t%s\tmo:%d\troCt:%.1lf\t bH:%d  bM:%d\tyr:%2d\tSz:%3d\t%s\t%d\t%d\twP:\t%s\r", n,nCnt,nType,sType, pd(sName,9), bNextLn,xPos,nCiL,nOvSz,TabGrp, pd(lstTabTi,12), nTabs, BlkGrp, pd(lstBlkTi,12), pd(lstMode,9),nMode,nRowCnt, BlkHt,BlkMx, yr,xBodySz, pd(sLongTitle,12),rXSz,rXSzMx,wPn[n]  
		// Debug X:
		// printf "\t\t\tPnSize 1 X\t%2d/%2d\t%d  %s\t%s\tnxl:%d\txpo:%d/%d\tovs:%d\tSz:%3d\t%s\t%d\t%d\t( ( TiPix:%2d\t+ BoSz:%3d\t+ %d ) * Cil:%d ) / ( 1 + OvSz:%d ) + ( %d - 1 - %d ) / 3 \r", n,nCnt,nType,sType, pd(sName,9), bNextLn,xPos,nCiL,nOvSz,xBodySz, pd(sLongTitle,12),rXSz,rXSzMx ,  nTitlePixel, xBodySz, kXTRAPIX, nCiL,  nOvSz ,  nCiL ,  nOvSz
		 
	endfor
	
	// printf "\t\t\tPnSize 1b Controls    \t\t%s \r",	"0;1;2;3;4;5;6;7;8;9;A;B;C;D;E;F;"
	// printf "\t\t\tPnSize 1b lstTabGrp  \t\t%s \r",	lstTabGrp
	// printf "\t\t\tPnSize 1b lstBlkGrp  \t\t%s \r", 	lstBlkGrp
	// printf "\t\t\tPnSize 1b lstBlkHeight    \t%s \r", 	lstBlkHeight
	// printf "\t\t\tPnSize 1b lstBlksMax      \t%s \r",	lstBlksMax
	// printf "\t\t\tPnSize 1b lstRowInBlkGrp\t%s \r",	lstRowInBlkGrp
	// printf "\t\t\tPnSize 1b llstTabTi    \t\t%s \r",	llstTabTi
	// printf "\t\t\tPnSize 1b llstBlkTi     \t\t%s \r",	llstBlkTi
	// printf "\t\t\tPnSize 1b llstMode     \t\t%s \r",	llstMode
	// printf "\t\t\tPnSize 1b lllstRowTi   \t\t%s \r",	lllstRowTi[0,220]
	// printf "\t\t\tPnSize 1b lllstColTi     \t\t%s \r",	lllstColTi[0,220]
	// printf "\t\t\tPnSize 1b lllstVisibility \t\t%s \r",	lllstVisibility
	  printf "\t\t\tPnSize 1b sLongestControl: \t%s \r",	sLongestControl

	
	// Pass 2 : Copy the final  blockheight (determined from the last control in blockgroup) to all previous controls in the same blockgroup.
	// printf "\t\tPnSize  2 \t\t\t\t\toriginal\tlstBlkHeight:%s \r", lstBlkHeight
	for ( n = nCnt-1; n > 0;  n -= 1 )
		variable	TabGrpN		= str2num( StringFromList( n,    lstTabGrp ) )
		variable	TabGrpNminus1	= str2num( StringFromList( n-1, lstTabGrp ) )
		variable	BlkGrpN		= str2num( StringFromList( n,    lstBlkGrp  ) )
		variable	BlgGrpNminus1	= str2num( StringFromList( n-1, lstBlkGrp  ) )
		if (TabGrpN == TabGrpNminus1  &&  BlkGrpN == BlgGrpNminus1 )
			lstBlkHeight	= ReplaceListItem1(  StringFromList( n, lstBlkHeight ), lstBlkHeight, ";" , n-1 ) 
			// printf "\t\tPnSize  2a\tn:%2d\tTg(n):%2d\t == \tTg(n-1):%2d\t&&\tBg(n):%2d\t == \tBg(n-1):%2d \t\tcopying from n =%2d- >%2d \tlstBlkHeight:%s \r", n, TabGrpN, TabGrpNminus1, BlkGrpN, BlgGrpNminus1, n, n-1, lstBlkHeight
		else
			 // printf "\t\tPnSize  2b\tn:%2d\tTg(n):%2d\t != \tTg(n-1):%2d\t || \tBg(n):%2d\t != \tBg(n-1):%2d   NOT \tcopying from n =%2d ->%2d \tlstBlkHeight:%s \r", n, TabGrpN, TabGrpNminus1, BlkGrpN, BlgGrpNminus1, n, n-1, lstBlkHeight
		endif
	endfor


	// Pass 3 : Compute  Y position of each new tab group.  Position is stored in list lstTabcoBeg( index:tabgrp )
	variable	bWasTab = FALSE, bTrueTab, TabGrpBeg, TabGrpEnd
	string  	sPrevTabGrp = "-1", sPrevBlkGrp = "-1", sTxt
	TabHt = 0
	lstTabcoBeg	= ""
	for ( n = 0; n < nCnt; n += 1 )
		sName	= RemoveWhiteSpace( StringFromList( kNAME, wPn[ n ], ksSEP_WPN ) )
		lstTabTi	= StringFromList( n, llstTabTi, ksSEP_CTRL )
		lstBlkTi	= StringFromList( n, llstBlkTi, ksSEP_CTRL )							// needed only for debug printing
		TabGrp	= str2num( StringFromList( n, lstTabGrp ) )
		BlkGrp	= str2num( StringFromList( n, lstBlkGrp ) )

		bTrueTab	= stIsTrueTab( lstTabTi )											// FALSE if there is no title at all = all titles are empty strings.  TRUE if there is at least 1 tab with a non-empty title. Blanks are non-empty and considered as tabs!
		if ( cmpstr( sPrevTabGrp, StringFromList( n, lstTabGrp ) ) )				// new tab group

			TabGrpBeg	+=  TabHt + bTrueTab
			TabGrpEnd	 =  bWasTab	?  TabGrpBeg - bTrueTab   : -1			// -1 means this is not a true tab group, i.e. no tabs and no tab frame will be drawn. However for all other purposes it is a tab group. 
			lstTabcoBeg	+= num2str( TabGrpBeg ) + ";"
			if ( n > 0 )												// Skip the first value so that corresponding Begins and Ends have the same index. Otherwise the End would be 1 index later. 
				lstTabcoEnd	+= num2str( TabGrpEnd ) + ";"
			endif
			sTxt			= SelectString( bTrueTab > 0 , "TGBeg     :", "TGBeg __:" )
			// printf "\t\tPnSize  3a\tn:%2d/%2d\t%s\t%s\ttg:%2d\t%s\tbg:%2d\tBHt:%2d\t* BMx:%2d = THt:%2d\t+ bTTb:%2d\t%s\t%2d\t-> \t%s\twTb:%d\t%s\t \r", n, nCnt, pd( sName,9), pd( lstTabTi,12), TabGrp, pd( lstBlkTi,12), BlkGrp, str2num( StringFromList( n, lstBlkHeight ) ) , str2num( StringFromList( n, lstBlksMax ) ), TabHt, bTrueTab, pd(sTxt,9), TabGrpBeg, pd(lstTabcoBeg,9), bWasTab, pd(lstTabcoEnd,9) 
		else
			if ( cmpstr( sPrevBlkGrp, StringFromList( n, lstBlkGrp ) ) ) 			// new block group
				TabGrpBeg	+=  TabHt
			endif		
		endif
		TabHt	= str2num( StringFromList( n, lstBlkHeight ) ) * str2num( StringFromList( n, lstBlksMax ) )
		sPrevTabGrp	= StringFromList( n, lstTabGrp )
		sPrevBlkGrp	= StringFromList( n, lstBlkGrp )
		sTxt	= "   "
		// printf "\t\tPnSize  3 \tn:%2d/%2d\t%s\t%s\ttg:%2d\t%s\tbg:%2d\tBHt:%2d\t* BMx:%2d = THt:%2d\t+ bTTb:%2d\t%s\t%2d\t-> \t%s\twTb:%d\t%s\t \r", n, nCnt, pd( sName,9), pd( lstTabTi,12), TabGrp, pd( lstBlkTi,12), BlkGrp, str2num( StringFromList( n, lstBlkHeight ) ) , str2num( StringFromList( n, lstBlksMax ) ), TabHt, bTrueTab, pd(sTxt,9), TabGrpBeg, pd(lstTabcoBeg,9), bWasTab, pd(lstTabcoEnd,9) 
		bWasTab		= bTrueTab
	endfor
	TabGrpBeg	+=  TabHt + bTrueTab
	TabGrpEnd	 =  bWasTab	?  TabGrpBeg - bTrueTab   : -1			// Append the last value so that corresponding Begins and Ends have the same index. Otherwise the End would be 1 index later. (-1 means this is not a true tab group )
	lstTabcoEnd	+= num2str( TabGrpEnd ) + ";"
	// printf "\t\tPnSize  3ex\tn:%2d/%2d\t%s\t%s\ttg:%2d\t%s\tbg:%2d\tBHt:%2d\t* BMx:%2d = THt:%2d\t+ bTTb:%2d\t%s\t%2d\t-> \t%s\twTb:%d\t%s\t \r", n, nCnt, pd( sName,9), pd( lstTabTi,12), TabGrp, pd( lstBlkTi,12), BlkGrp, str2num( StringFromList( n, lstBlkHeight ) ) , str2num( StringFromList( n, lstBlksMax ) ), TabHt, bTrueTab, pd(sTxt,9), TabGrpBeg, pd(lstTabcoBeg,9), bWasTab, pd(lstTabcoEnd,9) 


	// Pass 4 : Compute  Y position of each control taking into account  Tab and Block grouping.  Insert the TabGroup/TabControl separator '$'  into the title lists.
	variable	yt = 0, yb = 0, yy = 0, PrevBlkGrp = 0, PrevTabGrp = 0
	variable	yPos	= 0
	for ( n = 0; n < nCnt; n += 1 )
		nType	= WhichListItem( RemoveWhiteSpace( StringFromList( kTYPE, wPn[ n ], ksSEP_WPN ) ), lstTYPE )
		sType	= StringFromList( nType, lstTYPE )
		sName	= RemoveWhiteSpace( StringFromList( kNAME, wPn[ n ], ksSEP_WPN ) )
		bNextLn	= str2num( StringFromList( kNXLN, wPn[ n ], ksSEP_WPN ) )					// needed only for debug printing
		xPos		= str2num( StringFromList( kXPOS, wPn[ n ], ksSEP_WPN ) )
		nCiL		= str2num( StringFromList( kMXPO, wPn[ n ], ksSEP_WPN ) )
		nOvSz	= str2num( StringFromList( kOVS, wPn[ n ], ksSEP_WPN ) )
		xBodySz	= str2num( StringFromList( kXBODYSZ, wPn[ n ], ksSEP_WPN ) )
		lstTabTi	= StringFromList( n, llstTabTi,  ksSEP_CTRL )								// title functions possibly have already been executed, so we now have title lists...
		lstBlkTi	= StringFromList( n, llstBlkTi,   ksSEP_CTRL )								// ...but without tab grouping yet, which will be added  now ( ksSEP_TBCO) 
		lstMode	= StringFromList( n, llstMode,   ksSEP_CTRL )		
		lstRowTi	= StringFromList( n, lllstRowTi, ksSEP_CTRL )							
		lstColTi	= StringFromList( n, lllstColTi,   ksSEP_CTRL )							
		TabGrp	= str2num( StringFromList( n, lstTabGrp ) )
		BlkGrp	= str2num( StringFromList( n, lstBlkGrp ) )
		yr		= str2num( StringFromList( n, lstRowInBlkGrp ) )

		if ( PrevTabGrp != TabGrp )
			yy 	          =  0
			llstTypes  	+= ksSEP_TBCO							// Insert TabGroup/TabControl separator '$'  which adds the information where a new tabcontrol starts...
			llstCNames+= ksSEP_TBCO							// ...These title lists are passed by reference into  'PnDraw()'... 
			lllstTabTi	+= ksSEP_TBCO							// ...and from there by  'UserData'  into the Tabcontrol action proc... 
			llstBlkTi	+= ksSEP_TBCO							// ...where they are needed to adjust the the panel depending on other control settings
			llstMode	+= ksSEP_TBCO
			lllstRowTi	+= ksSEP_TBCO
			lllstColTi	+= ksSEP_TBCO
		endif
		if ( PrevBlkGrp != BlkGrp   &&   PrevTabGrp == TabGrp     )
			yy += BlkHt * BlkMx
		endif
		llstTypes	+= num2str( nType) 	+ ksSEP_CTRL					// Contains  catenated  types    of all controls within this tabcontrol.  Inserts separator  '|'
		llstCNames+= sName			+ ksSEP_CTRL		
		lllstTabTi	+= lstTabTi		+ ksSEP_CTRL		
		llstBlkTi	+= lstBlkTi			+ ksSEP_CTRL		
		llstMode	+= lstMode		+ ksSEP_CTRL		
		lllstRowTi	+= lstRowTi		+ ksSEP_CTRL		
		lllstColTi	+= lstColTi    		+ ksSEP_CTRL		
		BlkHt		= str2num( StringFromList( n, lstBlkHeight ) )
		BlkMx		= str2num( StringFromList( n, lstBlksMax ) )

		nTabs	= stTabCnt( lstTabTi )
	
		lstBlkPosX = ""
		lstBlkPosY = ""
		for ( nTab = 0; nTab < nTabs; nTab += 1 )
			lstBlksInTab	= StringFromList( nTab, lstBlkTi, ksSEP_TAB )
			BlkCnt		= ItemsInList( lstBlksInTab, ksSEP_STD )
			// Only this 1 case (of 4 cases)  is needed when there are no empty strings  in the 'Tabs'  and  'Blks'  .  There must at least  be separators. 
			for ( nBlk = 0; nBlk < BlkCnt; nBlk += 1 )
				yt	= str2num( StringFromList( TabGrp, lstTabcoBeg ) ) 
				yb	= nBlk * BlkHt 
				yPos = yt + yb + yy + yr
				// printf "\t\tPnSize  4d\t%2d/%2d\t%d  %s\t%s\tnxl:%d\txpo:%d/%d\tovs:%d\t%s\ttbgr:%2d\ttab:%d/%d\t%s\tblgr:%2d\tblk:%2d/%2d\tmo:%d\tblkHt:%d\tyt:%2d\t+ yb:%2d\t+ yy:%2d\t+ yr:%.1lf\t= yPo:%.1lf\t \r", n, nCnt, nType, sType, pd( sName, 9 ), bNextLn, xPos, nCiL, nOvSz, pd(lstTabTi,15), TabGrp, nTab, nTabs, pd(lstBlkTi,15), BlkGrp, nBlk, BlkCnt, nMode, BlkHt, yt, yb, yy, yr, yPos

				lstBlkPosX	= ReplaceListItem1( num2str( xPos * rXSzMx/nCiL ), lstBlkPosX, ",", nBlk ) 		
				
				lstBlkPosY	= ReplaceListItem1( num2str( yPos ), lstBlkPosY, ",", nBlk ) 
				// print "blk:", nBlk, lstBlkPos, "\t\t->", lstCtrlBlkPos
			endfor
		endfor		// tabs in 1 tabcontrol

		PrevTabGrp	= TabGrp
		PrevBlkGrp	= BlkGrp
		lstCtrlBlkPosX	= ReplaceListItem1( lstBlkPosX, lstCtrlBlkPosX, ";", n ) 
		lstCtrlBlkPosY	= ReplaceListItem1( lstBlkPosY, lstCtrlBlkPosY, ";", n ) 

	endfor		// controls = lines in  'wPn'		

	width		= rXSzMx										// returned as reference  ( old : return	MaxXLen( twPanel ) + 2 * kXMARGIN )
//	variable BlkHtAdd = BlkHt; string sTx = "Without LastLine : panel 3 too large     With Last line: Panel OK      With last Multiblock: panel OK"
//////			BlkHtAdd = 1; 	sTx = "Without LastLine : panel  OK    	   With LastLine : panel  OK    With last Multiblock: panel  1 too small "
//	printf "PnSize  5  BlkHt:%3d  .  \tAdding for position  BlkHtAdd:%3d   %s \r", BlkHt , BlkHtAdd , sTx
	height	= ( yPos + BlkHt - yr ) *  kYLINEHEIGHT				// returned as reference

	// printf "\t\t\tPnSize  5  returning width:\t%3d    height:%3d   = (%3d +%2d -%2d ) * %2d \t \r", width, height, ypos, BlkHt, yr, kYLINEHEIGHT
	// printf "\t\t\tPnSize  5  lstCtrlBlkPosX:\t%s\t  \r",	lstCtrlBlkPosX
	// printf "\t\t\tPnSize  5  lstCtrlBlkPosY:\t%s\t  \r",	lstCtrlBlkPosY
	// printf "\t\t\tPnSize  5  TabcoBeg:     \t%s\t  \r",	lstTabcoBeg
	// printf "\t\t\tPnSize  5  TabcoEnd:     \t%s\t  \r",	lstTabcoEnd
	// printf "\t\t\tPnSize  5  llstTypes:       \t%s\t  \r",	llstTypes
	// printf "\t\t\tPnSize  5  llstCNames:   \t%s\t  \r",	llstCNames[0,220]
	// printf "\t\t\tPnSize  5  llstTabTi:       \t%s\t  \r", 	llstTabTi
	// printf "\t\t\tPnSize  5  lllstTabTi:      \t%s\t  \r", 	lllstTabTi
	// printf "\t\t\tPnSize  5  lstBlkTitls:     \t%s\t   \r", 	lstBlkTi
	// printf "\t\t\tPnSize  5  llstBlkTi:       \t%s \t  \r", 	llstBlkTi
	// printf "\t\t\tPnSize  5  lstMode:      \t%s\t   \r", 	lstMode
	// printf "\t\t\tPnSize  5  llstMode:      \t%s \t  \r", 	llstMode[0,220]
	// printf "\t\t\tPnSize  5  lllstRowTi:    \t%s\t   \r", 	lllstRowTi[ 0, 220 ]
	// printf "\t\t\tPnSize  5  lllstColT:       \t%s\t   \r", 	lllstColTi[ 0, 220 ]
//	  printf "\t\t\tPnSize 1=5 lstVi=lllstVisibility  \t%s\t  \r",	lllstVisibility			
End


static Function	stPnDraw( sF, sWin, wPn, xPnSz, ySize, lstPosX, lstPosY, lstTabGrp, lstTabcoBeg, lstTabcoEnd, llstTypes, llstCNames, lllstTabTi,  llstBlkTi, lllstRowTi, lllstColTi, lllstVisibility, llstMode )
//  Draw the panel and the controls taking into account  Tab and Block grouping which was computed in  'PnSize()' . 
	wave   /T	wPn
	variable	xPnSz, ySize
	string		sF, sWin
	string  	lstPosX, lstPosY								// where the controls will be positioned. Index is control number.
	string  	lstTabGrp, lstTabcoBeg, lstTabcoEnd					// where the tab frames will be positioned. These lists are indexed by TabGrp (including pseudo-tabs  (end=-1) for which no tab frame is drawn)
	string  	llstTypes, llstCNames, lllstTabTi, llstBlkTi, lllstRowTi, lllstColTi, lllstVisibility,  llstMode 
	
	// Kill all controls.  This is only required when the panel size changes and when controls which are no longer necessary are to be removed. If the same controls are used all the time killing them here is not mandatory.
	// As it is quite complex to filter out if and which controls must be removed, we remove all although we introduce some screen flicker this way.  
	variable	n, nCnt
	string  	lstControls	= ControlNameList( sWin )
	nCnt	= 	ItemsInList( lstControls )
	for ( n = 0; n < nCnt; n += 1 )											// for all controls (=all controls actually found in the panel)
		KillControl	/W = $sWin  $StringFromList( n, lstControls )
	endfor

	// printf "\t\t\tPnDraw( %s  %s ... ) \r", sF, sWin
 	string  	lstTabTi, lstBlkTi, lstMode
 	variable	nTabco, nTab, nTabs, nSelectedTab
 	

	// Draw the controls within the tabcontrols but do not draw the tabcontrols yet

	string  	sType, sName, lstRowTi, lstColTi, sActProc, sFormEntry, lstVisibility, sHelpTopic//, lstInitVal,
	variable	nType, nCiL, nOvSz, xBodySz, xPos, xOs, yPos, yOs, xSize
	string  	sBlkTi, lstBlksInTab, lstModeInTab, sTitle, sCNmIdx, sFoCNmIdx
	variable	nBlk,  BlkCnt, nMode
	variable	nRow, mxRow, nCol, mxCol
	variable 	bVisib

	nCnt	= DimSize( wPn, 0 )
	for ( n = 0; n < nCnt; n += 1 )											// for all controls (=all lines in 'wPn' )

		nType	= WhichListItem( RemoveWhiteSpace( StringFromList( kTYPE, wPn[ n ], ksSEP_WPN ) ), lstTYPE )
		sType	= StringFromList( nType, lstTYPE )										// or from llstTypes
		sName	= RemoveWhiteSpace( StringFromList( kNAME, wPn[ n ], ksSEP_WPN ) )			// or from llstCNames

		lstTabTi	= StringFromList( n, ReplaceString( ksSEP_TBCO, lllstTabTi,  "" ), ksSEP_CTRL )		// remove the tabgroup separator q&d, then extract titles for this control
		lstBlkTi	= StringFromList( n, ReplaceString( ksSEP_TBCO, llstBlkTi,    "" ), ksSEP_CTRL )		// remove the tabgroup separator q&d, then extract titles for this control
		lstRowTi	= StringFromList( n, ReplaceString( ksSEP_TBCO, lllstRowTi, "" ), ksSEP_CTRL ) 		// remove the tabgroup separator q&d, then extract titles for this control
		lstColTi	= StringFromList( n, ReplaceString( ksSEP_TBCO, lllstColTi,   "" ), ksSEP_CTRL ) 
		lstMode	= StringFromList( n, ReplaceString( ksSEP_TBCO, llstMode,   "" ), ksSEP_CTRL ) 
		lstVisibility	= StringFromList( n, lllstVisibility, ksSEP_CTRL ) 								// lstVisibility is processed simpler than lstColTi

		sActProc	= RemoveWhiteSpace( StringFromList( kACTPROC, wPn[ n ], ksSEP_WPN ) )
		nCiL		= str2num( StringFromList( kMXPO, wPn[ n ], ksSEP_WPN ) )
		nOvSz	= str2num( StringFromList( kOVS, wPn[ n ], ksSEP_WPN ) )
		xBodySz	= str2num( StringFromList( kXBODYSZ, wPn[ n ], ksSEP_WPN ) )

		// 051204 Note: A FormatEntry-function HAS NOT ALREADY BEEN converted to a list ... as  the PopupMenu function executes code and requires parameters (win, controlname)  whereas SetVariable, ValDisplay etc only receive settings but do not execute code.
		sFormEntry= RemoveWhiteSpace( StringFromList( kFORMENTRY, wPn[ n ], ksSEP_WPN ) )
		
		// printf "\t\t\tPnDraw() %2d/%2d\tNm:\t%s\tVis:\tlvis:%s\tllvis:%s\tFe:'%s'  \r", n, nCnt, pd( sName,18), pd( lstVisibility , 29), pd( lllstVisibility , 49), sFormEntry

		sHelpTopic= ReplaceString( "\t", StringFromList( kHELPTOPIC, wPn[ n ], ksSEP_WPN ) , "" )

		nTabs		= stTabCnt( lstTabTi )						// Number of  tabs    in  this control  with index 'n' 

		// Cave: Simple code - No empty strings are allowed  in the 'Tabs'  and  'Blks'  .  There must at least  be separators. 

		nTabco		= str2num( StringFromList( n, lstTabGrp ) )
		nSelectedTab	= stPnTabcoIndex( sF + sWin, nTabco )  //0// todo:  must be stored dependant on panel and tabgroup

		// Avoid   nSelectedTab = -1 ( which is introduced and probably should be avoided in RecallAllFolderVars()  ??? )
		nSelectedTab = max( 0, nSelectedTab )
		// printf "\t\t\tPnDraw  \tn:%d\t%s\t%s\tTabco:%2d\t->\tSelected Tab:%2d\t'%s'\t    \r", n, pd(sType,6),  pd( sName,9), nTabco, nSelectedTab, sF + sWin

		for ( nTab = 0; nTab < nTabs; nTab += 1 )								// For all tabs in 1 tabcontrol
			lstBlksInTab	= StringFromList( nTab, lstBlkTi, ksSEP_TAB )
			lstModeInTab	= StringFromList( nTab, lstMode, ksSEP_TAB )
			BlkCnt		= ItemsInList( lstBlksInTab, ksSEP_STD )
			for ( nBlk = 0; nBlk < BlkCnt; nBlk += 1 )
				sBlkTi	= StringFromList( nBlk, lstBlksInTab, ksSEP_STD )
				nMode	= str2num( StringFromList( nBlk, lstModeInTab, ksSEP_STD ) )
				xPos 	= str2num( StringFromList( nBlk, StringFromList( n, lstPosX, ";" ), "," ) )
				yPos 	= str2num( StringFromList( nBlk, StringFromList( n, lstPosY, ";" ), "," ) )

				variable	bTabDisable	= ! ( nSelectedTab == nTab )
				variable	bDisable		=  bTabDisable  ||  ( nMode == 0 )
				// printf"\t\tPnDraw()\ttab:%d\tBlk:%d/%d\tbTabDisable:%d\tnMode:%d\t -> disable:%d \tn:%d ->\tyPos:%3.1lf\t'%s'  \r", nTab, nBlk, BlkCnt, bTabDisable,  nMode, bDisable, n, yPos, lstPosY 

				mxRow	= stRowCnt( lstRowTi )						// ??? here half-height rows are ignored???
				for ( nRow = 0; nRow < mxRow; nRow += 1 )
				
					mxCol	= stRowCnt( lstColTi ) 
					for ( nCol = 0; nCol < mxCol; nCol += 1 )

						sCNmIdx 		= stPnBuildVNmIdx( sName, nTab, nBlk, nRow, nCol )
						sFoCNmIdx	= ReplaceString( ":", sF + sWin + ":",  "_" ) + sCNmIdx

						bVisib		= stInitValue( sCNmIdx, lstVisibility, 1 )			// If visibility 	values have been specified  in  'wPn[]' then use them , if not use 1 
						// printf "\t\t\tPnDraw()  \tNm:\t%s\t%s\t%s\tbVisib:%.0lf\tbDis:%d -> %d  \r", pd( sName,18),  pd( sCNmIdx,18), sFoCNmIdx, bVisib, bDisable, bDisable || ! bVisib
						sTitle			= sBlkTi + StringFromList( nRow, lstRowTi, ksSEP_STD )  + StringFromList( nCol, lstColTi, ksSEP_STD ) 

						if ( strlen( sHelpTopic ) == 0 )									// If the helptopic field is empty  then  use  the title for connecting a help topic to the control
							sHelpTopic = RemoveLeadingWhiteSpace( RemoveTrailingWhiteSpace( sTitle ) )
						endif
		
						if ( 	nType == kSEP )
							xOs		= 3 * stIsTrueTab( lstTabTi )								// indent a few pixels (3)  to make room for the tabcontrol border line
							yOs		= nRow
							stPanelSepar3(  	bDisable, bVisib, xPos + xOs,  yPos + yOs, sWin, sTitle, sFoCNmIdx, xPnSz )
						elseif ( nType == kBU )
							xOs		= nCol * xPnSz / nCiL + 2	
							yOs		= nRow
							variable width = xPnSz * ( 1 + nOvSz )  / nCiL - 2 
							// 060510 buttons may be switched between states: they now have an initial value  and they may switch titles and colors depending on the state
							string  	sBuVarNm	= ReplaceString( "_", sFoCNmIdx, ":" )					// the underlying button variable name is derived from the control name
							nvar		state		= $sBuVarNm
							sTitle				= sBlkTi + StringFromList( state, StringFromList( nRow, lstRowTi, ksSEP_STD ), ksTILDE_SEP )  + StringFromList( state, StringFromList( nCol, lstColTi, ksSEP_STD ), ksTILDE_SEP ) 
							stPanelButton3(	bDisable, bVisib, xPos + xOs, yPos + yOs, sTitle, sActProc, sF, sWin, sFoCNmIdx, sCNmIdx, width, lstRowTi, sFormEntry, sHelpTopic )	// 060510 'sFormEntry' colorises the button
							// PanelButton3(bDisable, bVisib, xPos + xOs, yPos + yOs, sWin, sTitle, sActProc, sF, sFoCNmIdx, sCNmIdx, width, 					sHelpTopic )	

						elseif ( nType == kBUP )					// looks like a button with 2 states, acts like a checkbox  but is actually a CustomControl  with 2 programmed titles and colors 
							xOs		= nCol * xPnSz / nCiL + 2	
							yOs		= nRow
							width = xPnSz * ( 1 + nOvSz )  / nCiL - 2 
// 060515
//							PanelButtonPict3(	bDisable, bVisib, xPos + xOs, yPos + yOs, sWin, sTitle, sActProc, sF+sWin+":", sFoCNmIdx, sCNmIdx, width, lstTabTi, lstBlkTi, lstRowTi, lstColTi, sFormEntry, sHelpTopic  )	
							PanelButtonPict3(	bDisable, bVisib, xPos + xOs, yPos + yOs, sTitle, sActProc, sF, sWin, sFoCNmIdx, sCNmIdx, width, lstTabTi, lstBlkTi, lstRowTi, lstColTi, sFormEntry, sHelpTopic  )	

						elseif ( nType == kCB )
							xOs		= nCol * xPnSz / nCiL + 2
							yOs		= nRow
// 060515
//							stPanelChkbx3(	bDisable, bVisib, xPos + xOs,  yPos + yOs, sWin, sTitle, sActProc, sF+sWin+":", sFoCNmIdx, sCNmIdx, lstTabTi, lstBlkTi, lstRowTi, lstColTi, sHelpTopic )
							stPanelChkbx3(	bDisable, bVisib, xPos + xOs,  yPos + yOs, sTitle, sActProc, sF, sWin, sFoCNmIdx, sCNmIdx, lstTabTi, lstBlkTi, lstRowTi, lstColTi, sHelpTopic )
						elseif ( nType == kRAD )
							xOs		= nCol * xPnSz / nCiL + 2
							yOs		= nRow
// 060515
//							stPanelRadio3(	bDisable, bVisib, xPos + xOs, yPos + yOs, sWin, sTitle, sActProc, sF+sWin+":", sFoCNmIdx, sCNmIdx, lstTabTi, lstBlkTi, lstRowTi, lstColTi, sHelpTopic )
							stPanelRadio3(	bDisable, bVisib, xPos + xOs, yPos + yOs, sTitle, sActProc, sF, sWin, sFoCNmIdx, sCNmIdx, lstTabTi, lstBlkTi, lstRowTi, lstColTi, sHelpTopic )
						elseif ( nType == kSV  ||  nType == kSTR )
							xOs		= nCol * xPnSz / nCiL + 2 
							yOs		= nRow
							xSize	= stSetvarFieldX( xPnSz, nOvSz, nCiL ) 
							stPanelSetvar3( nType, bDisable, bVisib, xPos + xOs, xSize, yPos + yOs, sTitle, sActProc, sF, sWin, sFoCNmIdx, sCNmIdx, lstTabTi, lstBlkTi, lstRowTi, lstColTi, xBodySz, sFormEntry, sHelpTopic )	

						elseif ( nType == kSTC )					//  Colorise a field and set field text  which will AUTOMATICALLY change dependent on a global variable (using  CustomControl )  
							xOs		= nCol * xPnSz / nCiL + 2 
							yOs		= nRow
							xSize	= stSetvarFieldX( xPnSz, nOvSz, nCiL ) 
							stPanelColorField3( nType, bDisable, bVisib, xPos + xOs, xSize, yPos + yOs, sTitle, sActProc, sF, sWin, sFoCNmIdx, sCNmIdx, lstTabTi, lstBlkTi, lstRowTi, lstColTi, sFormEntry, sHelpTopic )	

						elseif ( nType == kVD )
							xOs		= nCol * xPnSz / nCiL + 2 
							yOs		= nRow
							xSize	= stSetvarFieldX( xPnSz, nOvSz, nCiL ) 
							stPanelValDisplay3( nType, bDisable, bVisib, xPos + xOs, xSize, yPos + yOs, sTitle, sActProc, sF, sWin, sFoCNmIdx, sCNmIdx, lstTabTi, lstBlkTi, lstRowTi, lstColTi, sFormEntry, sHelpTopic )	

						elseif ( nType == kPM )
							// xOs = (nCol +1) * xPnSz / nCiL + 2 - xBodySz + 3 * IsTrueTab( lstTabTi )	// todo: check that this is OK for ANY screen resolution...   Indent a few pixels (8)  to make room for the tabcontrol border line
							// xOs = (nCol +1) * xPnSz / nCiL + 2 - xBodySz 						// todo: check that this is OK for ANY screen resolution...   Seems to work without indentation seems even when in a tabcontrol?
							xOs		=  nCol  * xPnSz / nCiL + 2									// todo:    Seems to work without indentation seems even when in a tabcontrol?
							yOs		= nRow
							xSize	= stSetvarFieldX( xPnSz, nOvSz, nCiL ) 
							stPanelPopup3(	bDisable, bVisib, xPos + xOs, xSize, yPos + yOs, sTitle, sActProc, sF, sWin, sFoCNmIdx, sCNmIdx, lstTabTi, lstBlkTi, lstRowTi, lstColTi, xBodySz, sFormEntry, sHelpTopic )	
						endif

					endfor		// cols
				endfor		// rows
			endfor		// blks
		endfor		// tabs in 1 tabcontrol
		// printf "\t\tPnDraw [cnt]\t%2d/%2d\t%d  %s\t%s\t%2d\t%s\t%s\ttab:%d/%d\t\t\t\t\t%s\tblk:%d/%d\t%s\txSz:%2d\tCol:%2d\tCiL:%2d\txPo:%2d\t+Os:%2d\tyPo:%2d\t    %s\r", n, nCnt, nType, sType, pd( sName, 9 ), xBodySz, pd(sTitle,9), pd(lstTabTi,15), nTab, nTabs, pd(lstBlkTi,15), nBlk, BlkCnt, pd( sBlkTi,7), xPnSz, nCol, nCiL, xPos, xOs, yPos, wPn[ n ]  
	endfor		// controls = lines in  'wPn'		


	// Draw the tabcontrols: the frame and the tabs

	variable	TabGroups	= ItemsInList( lstTabcoBeg ) 
	variable	TabBeg, TabEnd								// of a Tab group
 	string  	sCleanName				
	for ( nTabco = 0; nTabco < TabGroups; nTabco += 1 )
		TabBeg		= str2num( StringFromList(  nTabco, lstTabcoBeg ) )
		TabEnd		= str2num( StringFromList(  nTabco, lstTabcoEnd ) )
	 	lstTabTi		= StringFromList(  0, StringFromList(  nTabco, lllstTabTi, ksSEP_TBCO ), ksSEP_CTRL )
		nTabs		= stTabCnt( lstTabTi )
		//sCleanName	= "fTC"+ CleanupName(sPanelTitle, 0) + num2str( TabBeg )		// Generate an automatic unique name for the tabcontrol ( flaw: theoretically there could be 2 panels with the same title...)
		sCleanName	=  sWin + "_" + num2str( nTabco )						// Generate an automatic unique name for the tabcontrol 
 sCleanName	= ReplaceString( ":", stPnBuildFoTabcoNm( sF + sWin, nTabco )	, "_" )
 // printf "\t\tPnDraw [tab]\t%s\ttg:%2d/%2d\tBeg:%2d\tEnd:%2d\tTabs:%2d\t%s\t%s\t%s\t  bl:\t%s\t \r", pd(sCleanName,18), nTabco, TabGroups, TabBeg, TabEnd, nTabs, pd(lstTabTi,9), pd(lstTabcoBeg,13), pd(lstTabcoEnd,13), pd(llstBlkTi,29)
		if ( TabEnd != kNOTFOUND )
			TabControl  $sCleanName,	win = $sWin,	proc 	= fTabControl3						// First call a standard  TabControl  procedure which enables/disables buttons groups according to the selected tab...
																	// ...then from there attempt to call  a special  TabControl  procedure  with  name derived form  control name. (This proc can be missing)
			for ( nTab = 0; nTab < nTabs; nTab += 1 )
				TabControl $sCleanName,	win = $sWin,	tablabel( nTab )	= StringFromList( nTab, lstTabTi, ksSEP_TAB ) 
			endfor
			TabControl  $sCleanName,	win = $sWin,	tablabel( nTab)	= ""						// end marker for last tab 

			nSelectedTab = min( stPnTabcoIndex( sF + sWin, nTabco ), nTabs-1 )	// The possibly clipped value (e.g. too few channels) will not change  global  user tab as the value is not passed back	  
			// PnTabcoIndexSet( sF, sWin, nTabco, nSelectedTab )			// Version1/2 : Only if this line is enabled then the possibly clipped value (e.g. too few channels) will be permanent.	  
	
			TabControl  $sCleanName,	win = $sWin,	value = nSelectedTab					// Select any tab to be the actice tab  TODO save activetab( panel, tg )  so that the panel stays the same when going to the next data

			TabControl  $sCleanName,	win = $sWin,	userdata( sTabcoNr ) 	= num2str( nTabco )		// The following  'userData' parameters are needed...
			TabControl  $sCleanName,	win = $sWin,	userdata( sF ) 	  	= sF					//...in the TabControl action proc  'fTabControl3()'   for showing and hiding the tabs 
			TabControl  $sCleanName,	win = $sWin,	userdata( llstTypes )	= llstTypes				// Contains  catenated  types    of all controls within this tabcontrol. 
			TabControl  $sCleanName,	win = $sWin,	userdata( llstCNames)	= llstCNames			// Contains  catenated  names  of all controls within this tabcontrol.
			TabControl  $sCleanName,	win = $sWin,	userdata( lllstTabTi ) 	= lllstTabTi				// 
			TabControl  $sCleanName,	win = $sWin,	userdata( llstBlkTi )	= llstBlkTi				// Contains  catenated  list of  block    titlelists   of all controls within this tabcontrol. 
			TabControl  $sCleanName,	win = $sWin,	userdata( llstMode )	= llstMode				// Contains  catenated  list of  block    modelists   of all controls within this tabcontrol. 

			TabControl  $sCleanName,	win = $sWin,	userdata( lllstRowTi )	= lllstRowTi			// ??? Contains  catenated  row    titlelists  of all controls within this tabcontrol. 
			TabControl  $sCleanName,	win = $sWin,	userdata( lllstColTi )	= lllstColTi				// ??? List of lists of column titles of ALL controls...
			TabControl  $sCleanName,	win = $sWin,	pos = { 	0,	 (TabBeg-1) * kYLINEHEIGHT }
			TabControl  $sCleanName,	win = $sWin,	size = { xPnSz+1, (TabEnd-TabBeg+1) * kYLINEHEIGHT} 
		endif
	endfor

End

static Function	stIsTrueTab( lstTabTi )	
	string  	lstTabTi 
	return	strlen( ReplaceString( ksSEP_TAB, lstTabTi, "" ) ) > 0					// FALSE if there is no title at all = all titles are empty strings.  TRUE if there is at least 1 tab with a non-empty title. Blanks are non-empty and considered as tabs!
	// return	strlen( RemoveWhiteSpace( ReplaceString( ksSEP_TAB, lstTabTi, "" ) ) ) > 0// FALSE if there is no title at all = all titles are empty or blank strings.  TRUE if there is at least 1 tab with a non-empty-non-blank title.
End


static Function	/S	stPossiblyConvrtTitleFuncToList( sBsName, sF, sWin, lstTi )			
// Possibly convert a  title function into a title list.   Returns list of tab/block/row or column  title list no matter whether we had a function returning the titles or a direct list
// Internal error : If the debugger indicates that  'lstTi'  is the <null> string  then  the function  'lstTi() / fttPrc() '  receives the wrong number of parameters  OR  it is returning a number but it must return a string  
	string	  	 sBsName, sF, sWin, lstTi
	if ( strsearch( lstTi, "()", 0 ) != kNOTFOUND )						// If there  is  ()   in  'lstTi'  then we have a function returning the list but not a direct list...
		string  	lstTmp	= ReplaceString( "()", lstTi, "" )
		// printf "\t\tPossiblyConvertTitleFuncToList \t%s\t'%s'  \t%s\t%s:\tExists as:%2d     . Exists as user defined function:%2d \r",  pd( sBsName, 12), sF, sWin, pd( lstTi,15),  exists( lstTmp ), exists( lstTmp )==6 
		FUNCREF   fTitlesProc    fTTPrc = $ReplaceString( "()", lstTi, "" )		//...so remove the ()  and get the list entries from this function.  
//gn
//		if ( exists( lstTmp ) != 6 )									// check if user defined function exists
//			InternalError ( "PossiblyConvertTitleFuncToList( sName, sF, sWin,) : Could not find function definition of '" + lstTmp + "' . " )	// catch spelling or coding errors : there should be a function returning a list but this function is not found and  the 'Null string '  is returned 
//		endif
//gn
//		if ( strlen( lstTi ) == 0 )
//			InternalError ( "Could not find function definition of '" + lstTmp + "' . " )				// catch spelling or coding errors : there should be a function returning a list but this function is not found and  the 'Null string '  is returned 
//		endif
//		print "Ti1\t", sF, sWin, sBsName, "\t\t", exists( lstTi ), "\t\t", lstTi
		lstTi			=    fTTPrc( sBsName, sF, sWin )								// Indirect entries in a function are useful if the string list is too long or if the entries must be built on demand.
//gn
//		print "Fn\t", sF, sWin, sBsName, "\t\t", exists( fTTPrc( sBsName, sF, sWin )		 )
//		print "Ti2\t", sF, sWin, sBsName, "\t\t", exists( lstTi ), "\t\t", lstTi
//		if ( exists( lstTi ) != 6 )									// check if user defined function exists
//			InternalError ( "PossiblyConvertTitleFuncToList( sName, sF, sWin,) : Could not find function definition for '" + sBsName + "' . " )	// catch spelling or coding errors : there should be a function returning a list but this function is not found and  the 'Null string '  is returned 
//		endif
	endif														// If there is  no  ()   in  'lstTi'  then assume it is a direct list
	return	lstTi
End

Function	/S	fTitlesProc( sBsName, sF, sWin )
	string  	sBsName, sF, sWin							// Dummy function prototype for tabcontrol title lists returning tab, block, row and column titles
	 printf "\t\tfTitlesProc()  \t%s\t  '%s'  '%s' \r",   pd( sBsName, 12), sF, sWin
End								


static Function	/S	stGetLongestTitle3( lstBlkTi, lstRowTi, lstColTi, nMode )
// todo : nMode = 2: extra leading column with block title but  narrower following columns because they don't contain the block title,  
// todo : nMode = 3: extra leading row for each block with block title, but narrower columns because they don't contain the block title,  
// 060510	switching button titles and colors  e.g.  2 rows with 2 switch states   'Row0 off~Row0 ON~,Row1 off~Row1 ON~,' 
	// Get the longest title.  
	string  	lstBlkTi, lstRowTi, lstColTi 
	variable	nMode
	// print  	lstBlkTi, "\t\t", lstRowTi, "\t\t", lstColTi , "\t\t", sSep
	string  	lstSwitchTitles, sTitle, sMxBlkTitle = "", sMxRowTitle = "", sMxColTitle = ""
	variable	nSw, nSwitchTitles, n, nTitles
	lstBlkTi	= ReplaceString( ksSEP_TAB, lstBlkTi, "" )	// ignore tab information, just get the longest of all block titles
	nTitles	= ItemsInList( lstBlkTi, ksSEP_STD )
	for ( n = 0; n < nTitles; n += 1 )
		sTitle		= StringFromList( n, lstBlkTi, ksSEP_STD )
		if ( IsLonger( sTitle, sMxBlkTitle ) )	
			sMxBlkTitle	=  sTitle
		endif
	endfor
	nTitles	= ItemsInList( lstRowTi, ksSEP_STD )
	for ( n = 0; n < nTitles; n += 1 )

// 060510 buttons may be switched between states: they now have an initial value  and they may switch titles and colors depending on the state
//			sTitle		= StringFromList( n, lstRowTi, ksSEP_STD )
//			if ( IsLonger( sTitle, sMxRowTitle ) )	
//				sMxRowTitle	=  sTitle
//			endif
		lstSwitchTitles	= StringFromList( n, lstRowTi, ksSEP_STD )
		nSwitchTitles	= ItemsInList( lstSwitchTitles, ksTILDE_SEP )
		for ( nSw = 0; nSw < nSwitchTitles; nSw += 1 )
			sTitle		= StringFromList( nSw, lstSwitchTitles, ksTILDE_SEP )
			if ( IsLonger( sTitle, sMxRowTitle ) )	
				sMxRowTitle	=  sTitle
			endif
		endfor


	endfor
	nTitles	= ItemsInList( lstColTi, ksSEP_STD )
	for ( n = 0; n < nTitles; n += 1 )

// 060510 buttons may be switched between states: they now have an initial value  and they may switch titles and colors depending on the state
//			sTitle		= StringFromList( n, lstColTi, ksSEP_STD )
//			if ( IsLonger( sTitle, sMxColTitle ) )	
//				sMxColTitle	=  sTitle
//			endif
		lstSwitchTitles	= StringFromList( n, lstColTi, ksSEP_STD )
		nSwitchTitles	= ItemsInList( lstSwitchTitles, ksTILDE_SEP )
		for ( nSw = 0; nSw < nSwitchTitles; nSw += 1 )
			sTitle		= StringFromList( nSw, lstSwitchTitles, ksTILDE_SEP )
			if ( IsLonger( sTitle, sMxColTitle ) )	
				sMxColTitle	=  sTitle
			endif
		endfor


	endfor
if ( nMode == 2  ||  nMode == 3 )
	print "GetLongestTitle3()  (and elsewhere:  mode =2   and  mode = 3 unfinished....)\r"
	sMxBlkTitle	= ksSEP_STD
endif
	return	sMxBlkTitle + sMxRowTitle + sMxColTitle
End

Function		IsLonger( sThisString, sOldString )	
	string  	sThisString, sOldString	
//	return	strlen( sThisString ) > strlen( sOldString )															// Version1: works but is not very precise
	return	FontSizeStringWidth( ksFONT, kFONTSIZE, 0, sThisString ) > FontSizeStringWidth( ksFONT, kFONTSIZE, 0, sOldString )// Version2: FontSizeStringWidth() should probably be more precise, especially when the specific font is passed (which is not yet done)
End

Static Function	stTextLenToPixel( sTxt )
	string 	sTxt
	 // print  "TextLenToPixel() FontSizeStringWidth()" , ksFONT,  "->", FontSizeStringWidth( ksFONT, kFONTSIZE, 0, sTxt ), sTxt
	//return  		FontSizeStringWidth( ksFONT,  kFONTSIZE, 0, sTxt ) 	//040322  too small for  panels and too small for online analysis with many  WAx columns    
	return  4 + 1.04 * FontSizeStringWidth( ksFONT, kFONTSIZE, 0, sTxt ) 	//040322  OK for panels , still too small for online analysis  
End	

static Function	stSetvarFieldX( xPnSz, nOvSz, nCiL ) 
	variable	xPnSz, nOvSz, nCiL
	variable	kMARGIN 	 = 2

	// empirical 051127
	variable	kFIELDMARGIN = 2
	variable	nXSize		 = ( xPnSz - kMARGIN ) / nCiL* ( nOvSz + 1 )  - kFIELDMARGIN
//	variable	nXSize		 = ( xPnSz - kMARGIN ) / nCiL* ( nOvSz + 1 )  - kFIELDMARGIN-1

//	variable	kFIELDMARGIN = 2
//	variable	nXSize		 = ( xPnSz - kMARGIN ) / nCiL* ( nOvSz + 1 )  

//	variable	kFIELDMARGIN = 2
//	variable	nXSize		 = ( xPnSz - kMARGIN ) / nCiL* ( nOvSz + 1 )  + kFIELDMARGIN * ( nOvSz - 0 ) 

//	variable	kFIELDMARGIN = 5
//	variable	nXSize		 = ( xPnSz - kMARGIN ) / nCiL* ( nOvSz + 1 )  + kFIELDMARGIN * ( nOvSz - 1 ) 

//	variable	nXSize		 = ( xPnSz - kMARGIN ) / nCiL* ( nOvSz + 1 )  + kFIELDMARGIN * (  - 1 ) 
//	variable	nXSize		 = ( xPnSz    ) / nCiL* ( nOvSz + 1 )  + kFIELDMARGIN * (  nOvSz  - 1 ) 
	// printf "\t\t\t\tSetvarFieldX( xPnSize:%4d \tnOvSz:%2d \tnCiL:%2d \tkMARGIN:%2d \tkFIELDMARGIN:%2d )\t -> nXSize:%4d  \r", xPnSz, nOvSz, nCiL, kMARGIN, kFIELDMARGIN, nXSize
	return	nXSize
End

 Function		FormatSetvarPopup( sTxt, xs, bodyw )
// Format SetVariable and Popupmenu so that they are neatly columnised. For this the title is padded with blanks  or truncated if too long.
// Result: Right justified, left justified, and exact input field width. Without this the left margin is undefined as the title is just in front of the input field...
	string  	&sTxt				// the control title
 	variable	xs					// the total control width 
 	variable	&bodyw				// the input field width 
 	string  	sPad			= sTxt
	variable	nPixel1Blank	= FontSizeStringWidth( ksFONT, kFONTSIZE, 0, " " ) 
	variable 	nStringPixels	= 4 + FontSizeStringWidth( ksFONT, kFONTSIZE, 0, sPad ) 	
	variable 	nBlankPixels	= xs - bodyw	-  nStringPixels
	if ( nBlankPixels < 0  && strlen( sPad ) > 0 ) 
		do 															// if title + input field exceed control size...
			sPad			= RemoveEnding( sPad )							// ...then truncate the title until it fits
		 	nStringPixels	= 4 + FontSizeStringWidth( ksFONT, kFONTSIZE, 0, sPad ) // 4 is magical....	
		 	nBlankPixels	= xs - bodyw	-  nStringPixels
		while ( nBlankPixels < 0  && strlen( sPad ) > 0 )							// if title + input field exceed control size...
	endif
	variable	bw	= min( bodyw, xs )		// possibly clip input field size to control size
	variable 	nBlanks			= nBlankPixels / nPixel1Blank
	// empirical 051127
	variable 	nActualBlanks		=  trunc( nBlanks )
	//variable 	nActualBlanks		=  round( nBlanks )
	variable 	nActualBlankPixels	 = nActualBlanks * nPixel1Blank
	 sPad  		= PadString( sPad, strlen( sPad ) + nActualBlanks, 0x20 )
	// printf "\t\tFormatSetvarPopup(\tPx/Blnk:%3.1lf\tBwIn:%4d\t xs:%4d\t%s\t) strPx:%3d\t+ BlnkPx: [%3d\t >%4.1lf\t >%3d\t>%4d\t] + BwOut:%4d\t = %4d\tFSSW:%4d\t [xs:%4d] \t->pad: '%s'\r", nPixel1Blank, bodyw, xs, pd(sTxt,18), nStringPixels, nBlankPixels, nBlanks, nActualBlanks, nActualBlankPixels, bw, nStringPixels+nBlankPixels+bw, FontSizeStringWidth( ksFONT,kFONTSIZE,0,sPad ) + bw, xs, sPad
	sTxt		= sPad
	bodyw	= bw	
End

Function		ButtonPressed( s )
// A button event occurs not only when pressing a button, but also when just moving the mouse over a button. We must exclude these events from 'normal' button press handling.
	struct	WMButtonAction	&s
	variable	nCode	=  ( s.eventCode == kCCE_mouseup )		// 060120 advice from LH , Wavemetrics 
	// printf "\tButtonPressed()\t\t\t%s\tEvent:%2d\t%s   \tMod:%2d\t%s\treturns %d %s \r", pd(s.ctrlName,28), s.eventCode, pd( StringFromList( s.eventCode, lstEVENTCODES ), 8 ),  s.eventMod, pd(s.win,8), nCode, SelectString( nCode , "-", "PRESSED" )
	return 	nCode
End		

Function		fButton_struct3( s )
// Called when a button is pressed.  ALSO CALLED when moving the mouse over a button.
	struct	WMButtonAction	&s
	string  	sProcNm			= GetUserData(	s.win,  s.ctrlName,  "sProcNm" )
	string  	sHelpTopic		= GetUserData(	s.win,  s.ctrlName,  "sHelpTopic" )
	string  	sEventName		= ""
	 if (  s.eventCode != kCCE_idle  &&  s.eventCode != kCCE_mousemoved ) 
		// printf "\tfButton_Struct3(a)\tEvent:%2d\t%s   \tMod:%2d\t%s\t%s\tsecs:%d \r", s.eventCode, pd( StringFromList( s.eventCode, lstEVENTCODES ), 8 ),   s.eventMod,  pd(s.win,8) , pd(s.ctrlName,24), mod( DateTime,10000)
	 endif	
	if (  ButtonPressed( s ) ) 													// exclude the event which is triggered when just moving the mouse over the button. 
		// 060510 buttons may be switched between states: they now have an initial value  and they may switch titles and colors depending on the state
		variable	row			= RowIdx(	 s.CtrlName )	// todo : extend this for columns
		string  	sBuVarNm		= ReplaceString( "_", s.CtrlName, ":" )					// the underlying button variable name is derived from the control name
		nvar		state			= $sBuVarNm
		string  	lstTitles 		= GetUserData( 	s.win,  s.ctrlName,  "titles" )				// e.g.  'Row0 off~Row0 ON~,Row1 off~Row1 ON~,' 
		string  	lstRowTitles	= StringFromList( row, lstTitles, ksSEP_STD )			// e.g.  'Row0 off~Row0 ON~' 
		string  	lstColors 		= GetUserData( 	s.win,  s.ctrlName,  "colors" )			// Get UD colors
		variable	nStates		= max( ItemsInList( lstRowTitles, ksTILDE_SEP ), ItemsInList( lstColors, ksTILDE_SEP ) )		// There can be any number of states for the button (usuallly 1 or 2)
		state 	= mod( state + 1, nStates )																// Toggle the button BEFORE the action proc is entered
		string  	sTitle			= StringFromList( state, lstRowTitles, ksTILDE_SEP )		// e.g.  'Row0 ON' 
		Button 	$s.CtrlName, win = $s.Win, title = sTitle
		string  	sOneColor		= StringFromList( state, lstColors, ksTILDE_SEP )
		if ( strlen( sOneColor ) )
			Button 	$s.CtrlName, win = $s.Win, fcolor = ( str2num( StringFromList( 0, sOneColor, "," ) ), str2num( StringFromList( 1, sOneColor, "," ) ), str2num( StringFromList( 2, sOneColor, "," ) ) )		//  colored 
		endif
		// printf "\tfButton_Struct3(b)\tMod:%2d\t%s\t%s\tProc:'%s()' \trow:%2d\tstate:%2d/%2d\t%s\t%s\t%s\t%s\t->\t%s \r", s.eventMod, pd(s.win,8) , pd(s.ctrlName,25) , sProcNm, row, state, nStates, pd(sTitle,12),  pd( lstRowTitles, 28),  pd( lstTitles, 30), lstColors, sOneColor

		if ( ! PnUserWantsHelp( s.win, s.ctrlName, s.eventcode, sEventName, s.eventmod, kCI_BUTTON, -1, sHelpTopic ) )	// anything else but left mouse button, e.g. right mouse button or left mouse and  ALT, CTRL or SHIFT
			FUNCREF   fBuProc_struct3  fBuPrc = $( sProcNm  )		// ...execute the action procedure ...
			fBuPrc( s )										// ...if there is one defined, it can also be missing ( sProcNm =  "" ) 
		endif
	endif
End

Function		fBuProc_struct3( s )								// dummy function  prototype
	struct	WMButtonAction	&s
End


Function		fSetvar_struct3( s ) 
	struct	WMSetvariableAction   &s

// 2009-10-26 ??????
//	if ( s.eventcode != 6 ) 	// Holzhammer  to prevent that the following code is called many times in succession if only the mouse is moved in another window (e.g. Eval window).  6 means  Value changed by dependency update.
	if ( s.eventcode != 6  && s.eventcode != -1 ) 	// Holzhammer  to prevent that the following code is called many times in succession if only the mouse is moved in another window (e.g. Eval window).  6 means  Value changed by dependency update.

		string  	sProcNm		= GetUserData(	s.win,  s.ctrlName,  "sProcNm" )
		string  	sHelpTopic	= GetUserData(	s.win,  s.ctrlName,  "sHelpTopic" )
		string  	sEventName	= StringFromList( s.eventcode, "none;MouseUp;EnterKey;LiveUpd;NONE" )
	
		if ( ! PnUserWantsHelp( s.win, s.ctrlName, s.eventcode, sEventName, s.eventmod, kCI_SETVARIABLE, -1, sHelpTopic ) )	// anything else but left mouse button, e.g. right mouse button or left mouse and  ALT, CTRL or SHIFT
			 printf "\t\tfSetvar_struct3( sControlNm:\t%s\t  Value:%g , sVarName:\t%s\t[will call if found: %s  ]\tEventCode:%2d\t%s \r", pd( s.ctrlname,26), s.dval,  pd(s.vname,26),   pd(sProcNm+"()",26) ,s.eventcode, sEventName
			FUNCREF   fSvProc_struct3  fSvPrc = $( sProcNm )				// Eexecute the action procedure... 
			fSvPrc( s )												//...if there is one defined, it can also be missing 
		endif
	endif
End

Function		fSvProc_struct3( s ) 								// dummy function  prototype
	struct	WMSetvariableAction    &s
End


Function		fPopup_struct3( s )
// executed when the user selected an item from the listbox
	struct	WMPopupAction	&s
	string  	sProcNm		= GetUserData(	s.win,  s.ctrlName,  "sProcNm" )
	string  	sHelpTopic	= GetUserData(	s.win,  s.ctrlName,  "sHelpTopic" )
	string  	sEventName	= StringFromList( s.eventcode, "none;???;MouseUp;NONE" )

	variable	bWantsHelp	= PnUserWantsHelp( s.win, s.ctrlName, s.eventcode, sEventName, s.eventmod, kCI_POPUPMENU, -1, sHelpTopic )	// anything else but left mouse button, e.g. right mouse button or left mouse and  ALT, CTRL or SHIFT
	if ( ! bWantsHelp  &&  s.eventcode == 2 ) //kPME_mouseup )				// 2009-07-02	React only on documented events. Otherwise e.g. unloading the application (e.g. UnloadSecuTst())  would  trigger all popupmenus (e.g. Customer, Inspector and PIN)
		string  	sFoPmVar	= ReplaceString( "_", s.ctrlName, ":" )   	//  e.g. root_uf_evo_de_gpopupVar000 -> root:uf:evo:evl:gpopupVar000
		nvar	 /Z	nTmp	= $sFoPmVar 						// set the global variable with the popup value to store state
		if ( nvar_Exists( nTmp ) )
			nTmp	= s.popNum							// the global variable has already been constructed previously
	 		// printf "\t\tfPopup_struct3 :\t'%s' ->\t%s\t exists and has been set \tto %d... \t[will call proc if found: '%s()' <--todo possibly strip indices\tHelp: '%s' ]\r", s.ctrlName, sFoPmVar, nTmp, sProcNm, sHelpTopic
		else
			variable	/G	$sFoPmVar = 1						// the global variable is constructed now and set to refelect the first list entry.  Setting it to 0 would lock and effectively disable the popmemu 
			printf "\t\tfPopup_struct3 :\t'%s' ->\t%s\t does not exist. Initialised \tto %d... \t[will call proc if found: '%s()' <--todo possibly strip indices\tHelp: '%s' ]\r", s.ctrlName, sFoPmVar, nTmp, sProcNm, sHelpTopic
		endif	
		FUNCREF   fPoProc_struct3  fPoPrc = $( sProcNm  )			// ...execute the action procedure ...
		fPoPrc( s )											// ...if there is one defined, it can also be missing ( sProcNm =  "" ) 
	endif
End

Function		fPoProc_struct3( s )								// dummy function  prototype
	struct	WMPopupAction  &s
End


Function		fChkbox_struct3( s )
	struct	WMCheckboxAction	&s
	string  	sProcNm		= GetUserData(	s.win,  s.ctrlName,  "sProcNm" )
	string  	sHelpTopic	= GetUserData(	s.win,  s.ctrlName,  "sHelpTopic" )
	string  	sEventName	= StringFromList( s.eventCode, "none;???;MouseUp;NONE" )

	variable	bWantsHelp 	= PnUserWantsHelp( s.win, s.ctrlName, s.eventcode, sEventName, s.eventmod, kCI_CHECKBOX, s.checked, sHelpTopic )// anything else but left mouse button, e.g. right mouse button or left mouse and  ALT, CTRL or SHIFT
	// printf "\t\tfChkbox_struct3 :  \t\t%s\thas been set to %d... \t\t[will call if found: %s \tHelpTopic: '%s' ]\r", pd(s.CtrlName,26), s.checked, pd(sProcNm+"()",26),  sHelpTopic
	if ( ! bWantsHelp  &&  s.eventcode == 2 ) //_CBE_mouseup )								// 2009-07-02	React only on documented events. Otherwise e.g. this killing the control (as in PnDraw) would  trigger the action procedure 
		stSetTheSingleRadioCBGlobal( s.ctrlname, s.checked )
		FUNCREF   fCbProc_struct3  fCbPrc = $( sProcNm ) 								// ...execute the action procedure ...
		fCbPrc( s )																// ...if there is one defined, it can also be missing ( sProcNm =  "" ) 
	endif
End


static Function	stSetTheSingleRadioCBGlobal( sCtrlname, bChecked )
// Build  the one and only global number  e.g. sVarNm = 'root:uf:rec:gPrintMode00'  consisting of powers of 2 from the panel checkbox array  which will control how much is printed.
// 'DebugPrintOptions()'  does the same thing but uses 1 visible variable for every option, here those multiple variables also exist but they are automatical and have not to be accessed directly
// see also: SetTheSingleRadioCBGlobal()
	string  	sCtrlname
	variable	bChecked
	string  	sOneCBVarNm 	= ReplaceString( "_", (sCtrlname), ":" )				// build base name  e.g.  root_uf_rec_gnPrintMode0030 ->  root:uf:rec:gnPrintMode0030 
	nvar		bValue		= $sOneCBVarNm							// can be 0 or 1 depending on checkbox state
// 060517a	
			bValue		= bChecked

	variable	len			= strlen( sOneCBVarNm )
	string  	sVarNm 		= sOneCBVarNm[ 0, len-3 ] 					// truncate the last 2 indices (=row,col)  and build base name  e.g.  root:uf:rec:gnPrintMode0030  	->  root:uf:rec:gnPrintMode00 
	nvar	/Z	gAnyVar		= $sVarNm 
//if ( ! nvar_exists( gAnyVar ) ) 
//	variable	/G  $sVarNm 
//	nvar		gAnyVar		= $sVarNm 
//endif
	variable	row			= DigitLetterToIdx( sOneCBVarNm[ len-2, len-2 ] )		// the row 		for vertical		checkboxes
	variable	col			= DigitLetterToIdx( sOneCBVarNm[ len-1, len-1 ] )		// the column    for horizontal	checkboxes
	
	gAnyVar	=   bValue == 0	?   gAnyVar - ( 2 ^ (row+col) )    :   gAnyVar + ( 2 ^ (row+col) ) 

	// printf "\t\tSetTheSingleRadioCBGlobal( %s, checked:%2d )\t'%s':%2d\t%s \trow:%2d   col:%2d  adding: %d  -> finally computes  %d \r",  sCtrlname, bChecked, sOneCBVarNm, bValue, sVarNm, row, col, bValue == 0 ?  - ( 2 ^ (row+col) )   :  ( 2 ^ (row+col) )  , gAnyVar
End

Function		fCbProc_struct3( s )										// dummy function  prototype
	struct	WMCheckboxAction	&s 
End



Function		fRadio_struct3( s )
// each radio button group  consists of multiple indexed buttons (=sControlNm)   but  there is only 1 global variable (=sControlNmBase)...
// ...and there is only one action procedure  and there is only one help topic ....................................which is connected separately to each button
	struct	WMCheckboxAction	&s
	string  	sThis 		= GetUserData(	s.win,  s.ctrlName,  "sThisF" )
	string  	sProcNm		= GetUserData(	s.win,  s.ctrlName,  "sProcNm" )
	string  	sHelpTopic	= GetUserData(	s.win,  s.ctrlName,  "sHelpTopic" )
	string  	sEventName	= ""
// 2009-10-26	make independent of future event codes.	
	if ( s.eventcode == kCBE_MouseUp )
		stRadioCheckUncheck3( s ) 											// check / uncheck all the radio buttons of this group
	
		// printf "\t\tfRadio_struct3(  \t\t\t%s\t\t )\t-> \t-> [ will call if found: %s  ]  HT:'%s' \tEvCode:%2d\tEvNm:\t%s \r", pd( s.ctrlname, 27) , pd( sProcNm+"()", 23) , sHelpTopic,  s.eventcode, StringFromList( s.eventcode, lstCBE_EVENTS )
		if ( ! PnUserWantsHelp( s.win, s.ctrlName, s.eventcode, sEventName, s.eventmod, kCI_CHECKBOX, s.checked, sHelpTopic ) )// anything else but left mouse button, e.g. right mouse button or left mouse and  ALT, CTRL or SHIFT
// 2009-10-26	make independent of future event codes.	
			// if ( s.eventcode != kEV_ABOUT_TO_BE_KILLED )						// without this killing the panel (which kills the control) would  trigger the action procedure 
			FUNCREF   fCbProc_struct3  fCbPrc = $sProcNm	// 041101
			fCbPrc( s )													// ..execute the action procedure (if there is one defined, it can also be missing) 
			//endif
		endif
	endif
End


static Function	stRadioCheckUncheck3( s ) 
// check and uncheck the radio buttons of this group  and also create and set the single global variable which describes the state of this radio button group
	struct	WMCheckboxAction	&s
	string		ctrlName	= s.ctrlName
	string  	lstTabTi 	= GetUserData(	s.win, s.ctrlName, "lstTabTi" )		// 
	string  	lstBlkTi 	= GetUserData(	s.win, s.ctrlName, "lstBlkTi" )		// 
	string  	lstRowTi 	= GetUserData(	s.win, s.ctrlName, "lstRowTi" )		// 
	string  	lstColTi 	= GetUserData(	s.win, s.ctrlName, "lstColTi" )		// 

	// printf "\t\tRadioCheckUncheck3\t%s\t%s\r", pd(ctrlName,31), lstBlkTi
	variable	nBlk, nRow, nCol, nTab, nLinIdx
	string  	sFoRadVar, sFoNmIdx, sFoNm	= ctrlName[ 0, strlen( ctrlName ) - 4 - 1 ]	

	nTab	=  TabIdx( ctrlName )						
	nBlk	=  BlkIdx( ctrlName )														// Version 1 : there is 1 radio button setting for each block, each tab
	// for ( nBlk = 0; nBlk < BlkCnt( lstBlkTi, nTab   ); nBlk += 1 )								// Version 2 : Radio button group extends over multiple blocks
		for ( nRow = 0; nRow < stRowCnt( lstRowTi ); nRow += 1 )
			for ( nCol = 0; nCol < stColCnt( lstColTi ); nCol += 1 )
				sFoNmIdx = stPnBuildVNmIdx( sFoNm, nTab, nBlk, nRow, nCol ) 
				if ( cmpstr( sFoNmIdx, ctrlName ) == 0 )								// check (=turn on) the one clicked button... 
					CheckBox $ctrlName, value = 1									// ONLY NECESSARY when button is set indirectly (e.g. shape from trace,ana,stage..)

					// Version 1 : There is 1 unique radio button for each tabs / block.  
					nLinIdx	 = stLinRadioButtonIndex3( 0, 0, nRow, nCol, lstTabTi, lstBlkTi, lstRowTi, lstColTi ) 
					sFoRadVar = sFoNmIdx[ 0, strlen( sFoNmIdx ) - 4 - 1 + 2 ]		 		// Create ONE global variable for the radio button group : strip the last 2 indices

					// Version 2 : Obsolete,  impractical and unfinished: there is only 1 radio button for all tabs, blocks rows and columns
					//nLinIdx	 = LinRadioButtonIndex( nTab, nBlk, nRow, nCol, lstDims ) 
					//sFoRadVar = sFoNmIdx[ 0, strlen( sFoNmIdx ) - nDims - 1 	]			// Create ONE global variable for the radio button group : strip the last 4 indices

					sFoRadVar = ReplaceString( "_", sFoRadVar, ":" ) 					// Create ONE global variable for the radio button group...
					variable /G $sFoRadVar 	= nLinIdx								// ... and store state of radio button group in this ONE global variable

					// printf "\t\tRadioCheckUncheck3\t%s\t%s\tOne global var:\t'%s'\tIndex of checked:%d \r", pd(ctrlName,31),  lstBlkTi, sFoRadVar, nLinIdx 	
				else
					CheckBox $sFoNmIdx, value = 0									// ...reset all other radio buttons of this group
				endif
			endfor
		endfor
	// endfor
End

static Function	stLinRadioButtonIndex3( nTab, nBlk, nRow, nCol, lstTabTi, lstBlkTi, lstRowTi, lstColTi )
// Returns the index of the 'turned-ON' checkbox button of a radio button array . For a Radio button array this is just one button and one index.
// For a checkbox array this may be zero, one or multiple buttons. In this case the return values must be added.
	string  	lstTabTi, lstBlkTi, lstRowTi, lstColTi
	variable	nTab, nBlk, nRow, nCol  
	variable	mxTabs	= stTabCnt( lstBlkTi )
	return	( ( nTab * stBlkMax( lstBlkTi, mxTabs )  + nBlk ) * stRowCnt( lstRowTi ) + nRow ) * stColCnt( lstColTi ) + nCol 
End

static Function	stCheckboxPowers3( nTab, nBlk, nRow, nCol, lstTabTi, lstBlkTi, lstRowTi, lstColTi )
// Returns the power of the index (2^index) of the 'turned-ON' checkbox button of a checkbox array. In a checkbox array 0, 1 or multiple buttons may be 'ON', ...
// ...so  the powers of the 'turned-on' indices must be summed (outside this function) so that we can be extract the indices later on from the sum.
	string  	lstTabTi, lstBlkTi, lstRowTi, lstColTi
	variable	nTab, nBlk, nRow, nCol
	variable	mxTabs	= stTabCnt( lstBlkTi )
	variable	nLinIdx	= stLinRadioButtonIndex3( nTab, nBlk, nRow, nCol, lstTabTi, lstBlkTi, lstRowTi, lstColTi )	
	// printf "\t\t\t\tCheckboxPowers3(  r:'%s'   c:'%s )  -> LinIdx=%2d  -> return %d \r", lstRowTi, lstColTi , nLinIdx, 2^nLinIdx
	return	2^nLinIdx
End

Function		RadioCheckUncheck3new( sWin, sRadButtonsCommonBase, index )
	string		sWin, sRadButtonsCommonBase
	variable	index
	string  	lstRadios	= ControlNameList( sWin, ";", sRadButtonsCommonBase + "*" )
	//print lstRadios
	variable	n, nRadios	= ItemsInList( lstRadios )
	for( n = 0; n < nRadios; n += 1 )
		Checkbox $StringFromList( n, lstRadios ), value = 0
	endfor
	Checkbox  $sRadButtonsCommonBase + IdxToDigitLetter( index ) + "0" , win=$sWin, value = 1	// Assumption/Flaw : works only for VERTICAL radio buttons...
End																			// ...Code for horz : $sRadButtonsCommonBase + "0" + num2str( IdxToDigitLetter )     

Function		PnRadioCheck( sWin, sFCNmSel ) 
	string  	sWin, sFCNmSel
	variable	len		= strlen( sFCNmSel )
	string  	lstTitles	= GetUserData( sWin,   sFCNmSel,   "lstRowTi" ) 		// Assumption:  vertical control 
	//string  	lstTitles	= GetUserData( sWin,   sFCNmSel,   "lstColTi" ) 			// Assumption:  horizontal control 
	variable	n, nItems	= ItemsInList( lstTitles, ksSEP_STD ) 
	for ( n = 0; n < nItems; n += 1 ) 
		string  	sFCNm	= sFCNmSel[ 0, len-3 ] + IdxToDigitLetter( n ) + "0"	// Assumption:  vertical control 
		//string  	sFCNm	= sFCNmSel[ 0, len-2 ] + IdxToDigitLetter( n ) + ""		// Assumption:  horizontal control 
		CheckBox  $sFCNm, win = $sWin, value = 0						// After resetting  all  radio buttons of this group...
	endfor		
	CheckBox  $sFCNmSel, win = $sWin, value = 1							// ...turn on just  this 1 radio button
	// Also set the single variable which contains the index  of the  turned-on  radio button which describes the state of the entire radio button group
	string  	sTheSingleVarNm	= ReplaceString( "_", sFCNmSel[ 0, len-3 ] , ":" )	// strip the last 2 indices  and  convert the control name to a variable name  _ -> :
	variable/G $sTheSingleVarNm	= DigitLetterToIdx( sFCNmSel[ len-2 ] )			// Assumption:  vertical control 
	//variable/G $sTheSingleVarNm	= DigitLetterToIdx( sFCNmSel[ len-1 ] )			// Assumption:  horizontal control 
End

Function		PnChkboxSetAll(   sWin, sFCNmSel, bValue ) 
	string  	sWin, sFCNmSel										// can be any checkbox of this group
	variable	bValue
	variable	len		= strlen( sFCNmSel )
	string  	lstTitles	= GetUserData( sWin,   sFCNmSel,   "lstRowTi" ) 		// Assumption:  vertical control 
	//string  	lstTitles	= GetUserData( sWin,   sFCNmSel,   "lstColTi" ) 			// Assumption:  horizontal control 
	variable	n, nItems	= ItemsInList( lstTitles, ksSEP_STD ) 
	for ( n = 0; n < nItems; n += 1 ) 
		string  	sFCNm	= sFCNmSel[ 0, len-3 ] + IdxToDigitLetter( n ) + "0"	// Assumption:  vertical control 
		//string  	sFCNm	= sFCNmSel[ 0, len-2 ] + IdxToDigitLetter( n ) + ""		// Assumption:  horizontal control 
		CheckBox  $sFCNm, win = $sWin, value = bValue					// Set / Reset  all  checkboxes of this group...
	endfor		
	// Also set the single variable consisting of powers of the individual checkbox states which describes the state of the entire checkbox group
	string  	sTheSingleVarNm	= ReplaceString( "_", sFCNmSel[ 0, len-3 ] , ":" )	// strip the last 2 indices  and  convert the control name to a variable name  _ -> :
	if ( bValue == 0 )
		variable /G $sTheSingleVarNm = 0
	else
		variable /G $sTheSingleVarNm = 2^nItems - 1 
	endif
End




////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


static Function	stPanelSepar3(  bDisable, bVisib, xPos,  yPos, sWin, sTitle, sFCNm, width )
// Process 1 line with or without separating text. If there is no text the separator will only be half-height. This is handled in 'Pnsize()'.
	variable	bDisable, bVisib, xPos,  yPos, width
	string		sWin, sTitle, sFCNm
	if ( strlen( sTitle ) ) 
		//DrawText /W = $sWin	xPos, yPos * kYLINEHEIGHT + 18, sTitle				// +18 aligns text between buttons . DrawText is not a control and is not handled correcty (is not erased by killcontrol)) 
		Groupbox	$sFCNm, win = $sWin,	disable			= bDisable  ||  ! bVisib				
		Groupbox	$sFCNm, win = $sWin,	pos				= { xPos + kXMARGIN, yPos * kYLINEHEIGHT }	
		Groupbox	$sFCNm, win = $sWin,	size				= { width - 2 * kXMARGIN, 13}				// 13 : narrow line, not a box in conjunction with frame = 1 , or 12 if frame = 1
		Groupbox	$sFCNm, win = $sWin,	title				= sTitle 
		Groupbox	$sFCNm, win = $sWin,	frame			= 1  
		Groupbox	$sFCNm, win = $sWin,	userdata( bVisib )	= num2str( bVisib )
	endif
End


static Function	stPanelButton3( bDisable, bVisib, xPos,  yPos, sTitle, sProc, sFo, sWin, sFCNm, sName, width, lstRowTi, lstColors, sHelpTopic )
	variable	bDisable, bVisib, xPos,  yPos, width
	string		sTitle, sProc, sFCNm, sFo, sWin, sName, lstRowTi, lstColors, sHelpTopic

	// 060510 buttons may be switched between states: they now have an initial value  and they may switch titles and colors depending on the state
	string  	sBuVarNm		= ReplaceString( "_", sFCNm, ":" )							// the underlying button variable name is derived from the control name
	nvar		state			= $sBuVarNm
	// 060518
	if ( strsearch( lstColors, "()", 0 ) != kNOTFOUND )
		FUNCREF   fColoredButtonProc  fColButPrc = $ReplaceString( "()", lstColors, "" )			// get the color entries of a color field from a function (one could also get the button's changing text from here, as in PanelColorField3 )
		lstColors	= fColButPrc()										
	endif
	string  	sOneColor		= StringFromList( state, lstColors, ksTILDE_SEP )
	if ( strlen( sOneColor ) ) 
		Button 	$sFCNm, win = $sWin, fcolor = ( str2num( StringFromList( 0, sOneColor, "," ) ), str2num( StringFromList( 1, sOneColor, "," ) ), str2num( StringFromList( 2, sOneColor, "," ) ) )		//  colored 
	endif
	// printf "\t\t\tPanelButton3  \t%s\t%s\tCtrlNm:\t%s\t%s\tBw:%3d\t%s\t%s\tHT: '%s'\tstate:%2d\t   \r", pd(sFo,18),  pd(sName,18),  pd(sFCNm,30), pd(sProc,15), width, pd(lstRowTi,18), pd(lstColors,18), sHelpTopic, state

	Button	$sFCNm, win = $sWin,	disable			= bDisable  ||  ! bVisib				
	Button	$sFCNm, win = $sWin,	pos				= { xPos, yPos * kYLINEHEIGHT }	
	Button	$sFCNm, win = $sWin,	size				= { width, kYHEIGHT }
	Button	$sFCNm, win = $sWin,	title				= sTitle 

	Button	$sFCNm, win = $sWin,	proc				= fButton_struct3				// Call this action procedure whether there is a user-defined action proc or not. Possibly call user-defined action proc additionally.
	Button	$sFCNm, win = $sWin,	userdata( titles )		= lstRowTi						// Set UD titles
	Button	$sFCNm, win = $sWin,	userdata( colors )	= lstColors						// Set UD colors
	Button	$sFCNm, win = $sWin,	userdata( sProcNm )	=  ReplaceString( "()", sProc, "" )	// Can also be empty. If the PRC field is not empty then call this proc in addition to and from 'fButton_struct3' 
	Button	$sFCNm, win = $sWin,	userdata( sFo )		= sFo	
	Button	$sFCNm, win = $sWin,	userdata( sHelpTopic)= sHelpTopic
	Button	$sFCNm, win = $sWin,	userdata( bVisib )	= num2str( bVisib )
End

Function	/S	fColoredButtonProc()	
	// prototype dummy : get the title and color entries of a color field from a function
End



Function		PanelButtonPict3( bDisable, bVisib, xPos, yPos, sTitle, sProc, sFo, sWin, sFCNm, sName, xSize, lstTabTi, lstBlkTi, lstRowTi, lstColTi, sPicture, sHelpTopic )
// Control which  looks like a button with 2 states but  actually  is  and acts as    a CheckBox with  titles and colors  retrieved from a picture 
// Colorize a  button  and change its title between 2 states like a checkbox  dependent on its global variable ( using  Checkbox ) 
// In this approach color and titles are passed  as predefined pictures to the control.  Shorter code, less parameters passed, no action proc   but   less flexible . Changing a picture is a mess.
// Another approach ( = PanelButtonCol3() ) : color and titles are passed as strings to the control.   A lot of code, many parameters and an action proc is needed but this approach is more flexible.
	variable	bDisable, bVisib, xPos, yPos, xSize
	string  	sTitle, sProc, sFo, sWin, sFCNm, sName, lstTabTi, lstBlkTi, lstRowTi, lstColTi , sPicture, sHelpTopic	// not all are used 

	CheckBox	$sFCNm,	win = $sWin,	disable		= bDisable  ||  ! bVisib
	CheckBox	$sFCNm,	win = $sWin,	pos			= { xPos, yPos* kYLINEHEIGHT }	
	CheckBox	$sFCNm,	win = $sWin,	title			= " "	
	CheckBox $sFCNm,	win = $sWin,	proc			= fChkbox_struct3
// 060515
//	CheckBox	$sFCNm,	win = $sWin,	variable		= $( sFo + sName ) 					// connect to global variable			
	CheckBox	$sFCNm,	win = $sWin,	variable		= $( sFo + sWin + ":" + sName ) 			// connect to global variable			
//	CheckBox	$sFCNm,	win = $sWin,	value		= FolderGetV( sFo, sName, OFF)	// check/uncheck the checkbox
	Checkbox 	$sFCNm,	win = $sWin,	picture		=$sPicture
CheckBox	$sFCNm, win = $sWin,	userdata( sFo ) 	= sFo	
//	CheckBox	$sFCNm,	win = $sWin,	userdata( lstMode )	= lstMode
	CheckBox	$sFCNm,	win = $sWin,	userdata( lstTabTi )	= lstTabTi
	CheckBox	$sFCNm,	win = $sWin,	userdata( lstBlkTi )	= lstBlkTi
	CheckBox	$sFCNm,	win = $sWin,	userdata( lstRowTi )	= lstRowTi
	CheckBox	$sFCNm,	win = $sWin,	userdata( lstColTi )	= lstColTi
	CheckBox $sFCNm,	win = $sWin,	userdata( sProcNm )	=  ReplaceString( "()", sProc, "" ) // if the PRC field is not empty then call this proc in addition to and from 'fChkbox_struct3' 
	CheckBox $sFCNm,	win = $sWin,	userdata( sHelpTopic)= sHelpTopic
	CheckBox $sFCNm,	win = $sWin,	userdata( bVisib )	= num2str( bVisib )
	//print "\t\tPanelButtonPict3", 	bDisable, bVisib, xSize,  sWin, sTitle, sProc
	// printf "\t\t\tPanelButtonPict3\t%s\t%s\tCtrlNm:\t%s\t%s\tx:%3d\ty:%3d\t%s\t%s\t%s\tro:\t%s\t  \r", pd(sFo,15),  pd(sName,15),  pd(sFCNm,26), pd(sTitle,8), xPos, yPos,  pd( lstTabTi,19),  pd( lstBlkTi,19),  pd( lstColTi, 9), pd( lstRowTi,19)
End				


static Function	stPanelChkbx3(  bDisable, bVisib, xPos,  yPos, sTitle, sProc, sFo, sWin, sFCNm, sName, lstTabTi, lstBlkTi, lstRowTi, lstColTi, sHelpTopic )
	variable	bDisable, bVisib, xPos,  yPos
	string		sTitle, sProc, sFCNm, sFo, sWin, sName, lstTabTi, lstBlkTi, lstRowTi, lstColTi, sHelpTopic 
//	 printf "\t\t\tPanelChkbx3\t\t%s\t%s\tCtrlNm:\t%s\t%s\tx:%3d\ty:%3d\t%s\t%s\t%s\tro:\t%s\t \r", pd(sFo,15),  pd(sName,15),  pd(sFCNm,26), pd(sTitle,10), xPos, yPos,  pd( lstTabTi,19),  pd( lstBlkTi,19),  pd( lstColTi, 9), pd( lstRowTi,19)
	CheckBox	$sFCNm, win = $sWin,	disable			= bDisable  ||  ! bVisib
	CheckBox	$sFCNm, win = $sWin,	pos				= { xPos,  yPos * kYLINEHEIGHT }	
	CheckBox	$sFCNm, win = $sWin,	title				= sTitle	
	CheckBox	$sFCNm, win = $sWin,	mode			= 0							// default checkbox appearance, not radio button appearance
	CheckBox $sFCNm, win = $sWin,	proc				= fChkbox_struct3				// Call this action procedure whether there is a user-defined action proc or not. Possibly call user-defined action proc additionally.
// 060515
//	CheckBox	$sFCNm, win = $sWin,	variable			= $( sFo  + sName ) 				// make checkbox state depend on this global shadow variable (name can be derived from checkbox name and vice versa)
	CheckBox	$sFCNm, win = $sWin,	variable			= $( sFo + sWin + ":" + sName ) 				// make checkbox state depend on this global shadow variable (name can be derived from checkbox name and vice versa)
CheckBox	$sFCNm, win = $sWin,	userdata( sFo ) 	= sFo	
//	CheckBox	$sFCNm, win = $sWin,	userdata( lstMode )	= lstMode
	CheckBox	$sFCNm, win = $sWin,	userdata( lstTabTi )	= lstTabTi
	CheckBox	$sFCNm, win = $sWin,	userdata( lstBlkTi )	= lstBlkTi
	CheckBox	$sFCNm, win = $sWin,	userdata( lstRowTi )	= lstRowTi
	CheckBox	$sFCNm, win = $sWin,	userdata( lstColTi )	= lstColTi

	CheckBox $sFCNm, win = $sWin,	userdata( sProcNm )	= ReplaceString( "()", sProc, "" )	// can also be empty. If the PRC field is not empty then call this proc in addition to and from 'fChkbox_struct3' 
	CheckBox $sFCNm, win = $sWin,	userdata( sHelpTopic)= sHelpTopic
	CheckBox $sFCNm, win = $sWin,	userdata( bVisib )	= num2str( bVisib )
	// printf "\tCHKBOX3-Checkbox  %s\tFo:%s\tProc:%s\tsFo:'%s'\t \r", pd(sFo + sName,30), pd(sFo,13), pd( sProc, 30), sFo
End


static Function	stPanelRadio3( bDisable, bVisib, xPos,  yPos, sTitle, sProc, sFo, sWin, sFCNm, sName, lstTabTi, lstBlkTi, lstRowTi, lstColTi, sHelpTopic )
	variable	bDisable, bVisib, xPos,  yPos
	string		sTitle, sProc, sFCNm, sFo, sWin, sName, lstTabTi, lstBlkTi, lstRowTi, lstColTi, sHelpTopic 

	// printf "\t\t\tPanelRadio3 \t\t\t\t%s\t%s\tCtrlNm:\t%s\t%s\t%s\t%s\t%s\t  \r",  pd(sFo,15),  pd(sName,15),  pd(sCNm,26), pd( lstTabTi,19),  pd( lstBlkTi,19), pd( lstRowTi,19),  pd( lstColTi,19)
	CheckBox	$sFCNm, win = $sWin,	disable			= bDisable  ||  ! bVisib	
	CheckBox	$sFCNm, win = $sWin,	pos				= { xPos,  yPos * kYLINEHEIGHT }	
	CheckBox	$sFCNm, win = $sWin,	title				= sTitle	
	CheckBox	$sFCNm, win = $sWin,	mode			= 1							// radio button appearance, not default checkbox appearance
	CheckBox $sFCNm, win = $sWin,	proc				= fRadio_struct3			
// 060515
//	CheckBox	$sFCNm, win = $sWin,	variable			= $( sFo + sName ) 				// make radio button state depend on this global shadow variable (name can be derived from checkbox name and vice versa)
	CheckBox	$sFCNm, win = $sWin,	variable			= $( sFo + sWin + ":" + sName ) 				// make radio button state depend on this global shadow variable (name can be derived from checkbox name and vice versa)
CheckBox	$sFCNm, win = $sWin,	userdata( sFo ) 	= sFo	
//	CheckBox	$sFCNm, win = $sWin,	userdata( sThisF ) 	= sThisF	
	CheckBox	$sFCNm, win = $sWin,	userdata( lstTabTi )	= lstTabTi
	CheckBox	$sFCNm, win = $sWin,	userdata( lstBlkTi )	= lstBlkTi
	CheckBox	$sFCNm, win = $sWin,	userdata( lstRowTi )	= lstRowTi
	CheckBox	$sFCNm, win = $sWin,	userdata( lstColTi )	= lstColTi
	CheckBox $sFCNm, win = $sWin,	userdata( sProcNm )	= ReplaceString( "()", sProc, "" )		// can also be empty. If the PRC field is not empty then call this proc in addition to and from 'fRadio_struct3' 
	CheckBox $sFCNm, win = $sWin,	userdata( sHelpTopic)= sHelpTopic
	CheckBox $sFCNm, win = $sWin,	userdata( bVisib )	= num2str( bVisib )
	 // printf "\tRadio3-Checkbox  %s\tFolder:%s\tProc:%s\t%s\tHelpTp:'%s[%s]' \r", pd(sFo_Name,28), pd(sF,10), pd( sProcNm, 26), sPnTi, sTitleLists, sHelpSubTopic	
End


static Function	stPanelSetVar3( nType, bDisable, bVisib, xPos, xSize, yPos, sTitle, sProc, sFo, sWin, sFCNm, sName, lstTabTi, lstBlkTi, lstRowTi, lstColTi, nBodyWidth, lstFormatLimits, sHelpTopic )
	variable	nType, bDisable, bVisib, xPos, xSize, yPos, nBodyWidth
	string		sTitle, sProc, sFo, sWin, sFCNm, sName, lstTabTi, lstBlkTi, lstRowTi, lstColTi, lstFormatLimits, sHelpTopic

	// printf "\t\t\tPanelSetVar3\t%s\t%s\tCtrlNm:\t%s\t%s\tBw:%3d\t%s\txSize:%4d\t  \r", pd(sFo,17),  pd(sName,17),  pd(sFCNm,27), pd(sProc,15), nBodyWidth, lstFormatLimits, xSize
 
	FormatSetvarPopup( sTitle, xSize, nBodyWidth )		// references are changed
 
 	SetVariable  $sFCNm,  win = $sWin,	disable			= bDisable  ||  ! bVisib						// cleaning is only necessary when string contains blanks, tabs etc.
	SetVariable  $sFCNm,  win = $sWin,	pos				= { xPos ,  yPos * kYLINEHEIGHT }
	SetVariable  $sFCNm,  win = $sWin,	size				= { xSize , 0 }							// height is ignored
	SetVariable  $sFCNm,  win = $sWin,	bodywidth   		= nBodyWidth							//  set and align field size, but give up left alignment of field text (unless FormatSetvarPopup() is used..)
	SetVariable  $sFCNm,  win = $sWin,	title				= sTitle
	SetVariable  $sFCNm,  win = $sWin,	proc				= fSetvar_struct3	
 	SetVariable  $sFCNm,  win = $sWin,	value			= $sFo + sWin + ":" + sName 							// get name of global number variable to be changed

	// 051204 Note: Could process a function like PanelColorField3 (CustomControl)  or  PanelValDisplay3 (ValDisplay)   .   However,  a PopupMenu is processed differently.
//	string		sFormat		= StringFromList( 0, lstFormatLimits )				// number format  e.g.  %d   or  %3.1lf
//	if ( strlen( sFormat ) )
//	 	SetVariable  $sFCNm, win = $sWin, format			= sFormat								// cleaning is only necessary when string contains blanks, tabs etc.
//	endif
//	string		sLim			= StringFromList( 1, lstFormatLimits )				// variable limits   min,max,step
//	if ( strlen( sLim ) )
//	 	SetVariable  $sFCNm, win = $sWin, limits			= { str2num( StringFromList( 0, sLim, "," ) ),str2num( StringFromList( 1, sLim, "," ) ),str2num( StringFromList( 2, sLim, "," ) ) }
//	endif
	variable	n, nParams	= ItemsInList( lstFormatLimits )
	string  	sParam
	for ( n = 0; n < nParams; n +=1 )
		sParam	= RemoveWhiteSpace(  StringFromList( n, lstFormatLimits ) )  	
		if ( strlen( sParam ) )
			if ( n == 0 ) 											// n=0 :  number format  e.g.  %d   or  %3.1lf 
			 	SetVariable  $sFCNm, win = $sWin, format	= sParam		
			elseif ( n == 1 )											 // n=1 : variable limits   min,max,step
			 	SetVariable  $sFCNm, win = $sWin, limits	= { str2num( StringFromList( 0, sParam, "," ) ),str2num( StringFromList( 1, sParam, "," ) ),str2num( StringFromList( 2, sParam, "," ) ) }
			endif
		endif
	endfor

	SetVariable  $sFCNm,  win = $sWin,	userdata( sFo )		= sFo	
	SetVariable  $sFCNm,  win = $sWin,	userdata( lstTabTi )	= lstTabTi
	SetVariable  $sFCNm,  win = $sWin,	userdata( lstBlkTi )	= lstBlkTi
	SetVariable  $sFCNm,  win = $sWin,	userdata( lstRowTi )	= lstRowTi						// Set UD lstRowTi
	SetVariable  $sFCNm,  win = $sWin,	userdata( lstColTi )	= lstColTi
	SetVariable  $sFCNm,  win = $sWin,	userdata( sProcNm )	= ReplaceString( "()", sProc, "" )		// can also be empty. If the PRC field is not empty then call this proc in addition to and from 'fSetvar_struct3' 
	SetVariable  $sFCNm,  win = $sWin,	userdata( sHelpTopic)= sHelpTopic
	SetVariable  $sFCNm,  win = $sWin,	userdata( bVisib )	= num2str( bVisib )
End



static Function	stPanelColorField3( nType, bDisable, bVisib, xPos, xSize, yPos, sTitle, sProc, sFo, sWin, sFCNm, sName, lstTabTi, lstBlkTi, lstRowTi, lstColTi, lstColors, sHelpTopic )
// Color of a field and text AUTOMATICALLY changing dependent on a global variable ( using  CustomControl ) .  
// This is  NOT used  as a real control as it accepts no user action, so it makes no sense to use the  'sProc'  field  and  the  'HelpTopic'  field.  
// However, they could be used : the  'ccColorFieldProc()'  IS executed when moving over the control..... 
// In this approach color and titles are passed to the control.   A lot of code, many parameters and an action proc is needed but this approach is more flexible.
// Another approach:  make a pictures from the colors and the titles and pass the picture name. Shorter code, less parameters passed, no action proc   but   less flexible . Changing a picture is a mess.
	variable	nType, bDisable, bVisib, xPos, xSize, yPos
	string		sTitle, sProc, sFo, sWin, sFCNm, sName, lstTabTi, lstBlkTi, lstRowTi, lstColTi, lstColors, sHelpTopic	// the column titles are used as colors (the 'InitVal' column should also work for colors, but the 'FormatEntry' column will NOT work for colors) 

//  051118  this is from  SetVariable - Do we need it here for the color field which resembles a SetVariable WITHOUT user interaction  although it is a CustomControl ????
//	SetVariable  $sFCNm,  win = $sWin,	userdata( sFo )		= sFo	
//	SetVariable  $sFCNm,  win = $sWin,	userdata( lstTabTi )	= lstTabTi
//	SetVariable  $sFCNm,  win = $sWin,	userdata( lstBlkTi )	= lstBlkTi
//	SetVariable  $sFCNm,  win = $sWin,	userdata( lstRowTi )	= lstRowTi
//	SetVariable  $sFCNm,  win = $sWin,	userdata( lstColTi )	= lstColTi
//	SetVariable  $sFCNm,  win = $sWin,	userdata( sProcNm )	= sProcNm
//	SetVariable  $sFCNm,  win = $sWin,	userdata( bVisib )	= num2str( bVisib )

//  051118  this is from  the  old  Color field :  Do we need to rename the userdata names ????
	CustomControl 	$sFCNm,  win = $sWin,	pos 			= { xPos ,  yPos * kYLINEHEIGHT }
	CustomControl 	$sFCNm,  win = $sWin,	size			= { 7,7 }	// omitting size or setting it to ( 0,0 ) does NOT work (fragments of a button will be drawn which must be covered by the rectangle drawn in the action proc)
	CustomControl 	$sFCNm,  win = $sWin,	proc			= ccColorFieldProc
	CustomControl	$sFCNm,  win = $sWin,	userdata( xsize ) = num2str( xSize )
	CustomControl	$sFCNm,  win = $sWin,	userdata( ysize ) = num2str( kYHEIGHT )

	// 051118
	if ( strsearch( lstColors, "()", 0 ) != kNOTFOUND )
		FUNCREF   fColorFieldProc3  fColFldPrc = $ReplaceString( "()", lstColors, "" )		// get the title and color entries of a color field from a function
		string  lstTitleColors	= fColFldPrc()										
	endif
	lstRowTi	= StringFromList( 0, lstTitleColors, "|" )
	lstColors	= StringFromList( 1, lstTitleColors, "|" )

	CustomControl	$sFCNm,	win = $sWin,	userdata( titles )	 	= lstRowTi
	CustomControl	$sFCNm,	win = $sWin,	userdata( colors ) 	= lstColors					//
	CustomControl	$sFCNm,	win = $sWin,	userdata( sProcNm )	= ReplaceString( "()", sProc, "" )	// see above. Can also be empty. If the PRC field is not empty then call this proc in addition to and from 'ccColorFieldProc' 
	CustomControl	$sFCNm,	win = $sWin,	userdata( sHelpTopic)= sHelpTopic				//  see above. 
	CustomControl	$sFCNm,	win = $sWin,	userdata( bVisib )	= num2str( bVisib )
	CustomControl	$sFCNm,	win = $sWin,	value		  	= $sFo + sWin + ":" + sName 	// get name of global number variable on which the control's color and text depends

	// printf "\t\t\tPanelColorField3\t%s\t%s\tCtrlNm:\t%s\t%s\tRoTi:%s\tColumn titles = Colors:%s\t  \r", pd(sFo,18),  pd(sName,18),   pd(sFCNm,30),  pd( sFo + sWin + ":" + sName, 30),  lstRowTi, lstColors
End

Function	/S	fColorFieldProc3()	
	// prototype dummy : get the title and color entries of a color field from a function
End

Function		ccColorFieldProc( s )
	struct	WMCustomControlAction 	&s
	if (  s.eventCode != kCCE_idle  &&  s.eventCode != kCCE_mousemoved ) 
		// this is executed even if other controls in other panels are clicked.......
		// printf "\tccColorFieldProc()\t\t\tnVal:%d \tEventCode:%2d    \t%s   \t'%s'\t'%s'\r ", s.nVal,  s.eventCode, pd( StringFromList( s.eventCode, lstEVENTCODES ), 8 ), s.win,  s.ctrlName
	endif	
	if (  s.eventCode == kCCE_draw ) 
		// SetDrawLayer UserBack
		variable	xSize 	= str2num( GetUserData( 	s.win,  s.ctrlName, "xsize" ) )
		variable	ySize 	= str2num( GetUserData( 	s.win,  s.ctrlName, "ysize" ) )
		string  	lstTitles 	= GetUserData( 			s.win,  s.ctrlName,  "titles" )
		string  	lstColors 	= GetUserData( 			s.win,  s.ctrlName,  "colors" )
		string	  	sTitle		= StringFromList( s.nVal, lstTitles, ksTILDE_SEP )
		string  	sOneColor	= StringFromList( s.nVal, lstColors, ksTILDE_SEP )
		SetDrawEnv  	fillfgc	= ( str2num( StringFromList( 0, sOneColor, "," ) ), str2num( StringFromList( 1, sOneColor, "," ) ), str2num( StringFromList( 2, sOneColor, "," ) ) )
		DrawRRect 	-1, 0, xSize, ySize - 1					// fragments of a button must be covered by the rectangle drawn
		// The default font taken from 'ExecuteDefaultFont'  can be overridden by uncommenting the following line  
		// Execute "SetDrawEnv  	fname = " + ksFONT_		//  special syntax and formatting required e.g  ksFONT_ =  "\"Arial\""  or   "\"Ms Sans Serif\""
		DrawText 		4, ySize - 2, sTitle
	endif
	return 0
End





static Function	stPanelPopup3( bDisable, bVisib, xPos,  xSize, yPos, sTitle, sProc, sFo, sWin, sFCNm, sName, lstTabTi, lstBlkTi, lstRowTi, lstColTi, nBodyWidth, sFormEntry, sHelpTopic )
	variable	bDisable, bVisib, xPos, xSize, yPos, nBodyWidth
	string		sTitle, sProc, sFo, sWin, sFCNm, sName, lstTabTi, lstBlkTi, lstRowTi, lstColTi, sFormEntry, sHelpTopic

	string  	sFoPmVar		= ReplaceString( "_", sFCNm, ":" )		//  e.g. root_uf_evo_de_gpopupVar000 -> root:uf:evo:evl:gpopupVar000
	nvar		nInitialValue	= $sFoPmVar 							// restore the popupvalue from the the global variable 
	PopupMenu $sFCNm,	win = $sWin,	mode= nInitialValue

	// printf "\t\t\tPanelPopup3a \t%s\t%s\tCtrlNm:\t%s\t%s\tBw:%3d\tIV:%2d\txpo:%3d\txsz:%3d\tbwi:%3d\t   \r", pd(sFo,17),  pd(sName,17),  pd(sFCNm,27), pd(sProc,15), nBodyWidth, nInitialValue, xPos, xSize, nBodyWidth
	FormatSetvarPopup( sTitle, xSize, nBodyWidth )		// references are changed
	// printf "\t\t\tPanelPopup3b \t%s\t%s\tCtrlNm:\t%s\t%s\tBw:%3d\tIV:%2d\txpo:%3d\txsz:%3d\tbwi:%3d\typos:%d\t   \r", pd(sFo,17),  pd(sName,17),  pd(sFCNm,27), pd(sProc,15), nBodyWidth, nInitialValue, xPos, xSize, nBodyWidth, yPos

	PopupMenu $sFCNm,	win = $sWin,	disable			= bDisable  ||  ! bVisib				
	if ( xPos+1 < 0  ||  yPos * kYLINEHEIGHT  < 0 )
		DeveloperError( "Position clipping control " + sFCNm + " .   x : " + num2str( xPos ) + ",  y: "  + num2str( yPos * kYLINEHEIGHT ) )
	endif	
	PopupMenu $sFCNm,	win = $sWin,	pos				= {  max( 0, xPos+1 ), max( 0, yPos * kYLINEHEIGHT - 1 ) }	// clip to 0 as the topmost control cannot start at -2 
	PopupMenu $sFCNm,	win = $sWin,	size				= { xSize , 0 } 									// the y height parameter is ignored...
	PopupMenu $sFCNm,	win = $sWin,	bodywidth			= nBodyWidth				
	PopupMenu $sFCNm,	win = $sWin,	title				= sTitle 
	PopupMenu $sFCNm,	win = $sWin,	proc				= fPopup_struct3	
	PopupMenu $sFCNm,	win = $sWin,	userdata( sFo )		= sFo	
	PopupMenu $sFCNm,	win = $sWin,	userdata( lstTabTi )	= lstTabTi
	PopupMenu $sFCNm,	win = $sWin,	userdata( lstBlkTi )	= lstBlkTi
	PopupMenu $sFCNm,	win = $sWin,	userdata( lstRowTi )	= lstRowTi
	PopupMenu $sFCNm,	win = $sWin,	userdata( lstColTi )	= lstColTi
	PopupMenu $sFCNm,	win = $sWin,	userdata( sProcNm )	= ReplaceString( "()", sProc, "" )	// can also be empty. If the PRC field is not empty then call this proc in addition to and from 'fPopup_struct3' 
	PopupMenu $sFCNm,	win = $sWin,	userdata( sHelpTopic)= sHelpTopic
// 060428 cbFit removed....?
	PopupMenu $sFCNm,	win = $sWin,	userdata( bVisib )	= num2str( bVisib  )		// store the visibility state (depending here only on cbFit, not on the tab!) so that it can be retrieved in the tabcontrol action proc (~ShowHideTabControl3() )

	FUNCREF   fPopupListProc3  fPopListPrc = $ReplaceString( "()", sFormEntry, "" )			// get the listbox entries from a function. This is the generalized form of simple call ' PopupMenu $sName, value = "Item1;Item2;..." '
	fPopListPrc( sFCNm, sFo, sWin )												// Unfortunately this code is not really generic. New popupmenus may require additional parameters which must be added as dummies to existing functions....
End																		// ...OR (untested but better) : possibly pass additional required parameters using 'UserData' 

Function		fPopupListProc3( sFCNm, sFo, sPnWin )	
// Prototype dummy :	Needed to get the listbox entries from a function with auto-built name. This is the generalized form of the much simpler but limited call ' PopupMenu $sName, value = "Item1;Item2;..." '
// 				Unfortunately this code is not really generic. New popupmenus may require additional parameters which must be added as dummies to existing functions.
	string  	sFCNm, sFo, sPnWin
End

End
static Function	stPanelValDisplay3( nType, bDisable, bVisib, xPos, xSize, yPos, sTitle, sProc, sFo, sWin, sFCNm, sName, lstTabTi, lstBlkTi, lstRowTi, lstColTi, lstParams, sHelpTopic )
// Color of a field and text AUTOMATICALLY changing dependent on a global variable ( using  ValDisplay ) .  
// e.g.  ValDisplay vd1,  title="Pred",  format="%4.2lf",  limits={ 0,2,1},  barmisc={0,32}, lowColor=(65535,0,0), highColor=(0,50000,0),   value= #"root:uf:aco:pul:vdPredict0000"
	variable	nType, bDisable, bVisib, xPos, xSize, yPos
	string		sTitle, sProc, sFo, sWin, sFCNm, sName, lstTabTi, lstBlkTi, lstRowTi, lstColTi, lstParams, sHelpTopic	// the column titles are used as colors (the 'InitVal' column should also work for colors, but the 'FormatEntry' column will NOT work for colors) 

	ValDisplay 	$sFCNm,  win = $sWin,	pos 			= { xPos ,  yPos * kYLINEHEIGHT }
	ValDisplay 	$sFCNm,  win = $sWin,	size			= { xSize, kYHEIGHT }
	ValDisplay 	$sFCNm,  win = $sWin,	title			= sTitle

// 	Igor ValDisplay sample code
//	Execute "ValDisplay DispNumPolys value = #\"root:Packages:WMCurveFitControl:"+GraphName+":ROINumPolys\""
//	Execute "ValDisplay valdispX"+suf+",value="+xval
//	Execute "ValDisplay DispNumPolys value = #\""+GetDatafolder(1)+"ROINumPolys\""
//	Execute "ValDisplay testEqn value=#\""+expr+"\""


	if ( strsearch( lstParams, "()", 0 ) != kNOTFOUND )
		FUNCREF   fValDisplayProc  fValDispPrc = $ReplaceString( "()", lstParams, "" )		// get the title and color entries of a color field from a function
		lstParams	= fValDispPrc()										
	endif
	// Get the format, limits, barmisc, lowColor and highColor  entries  of/for  a  ValDisplay  from a function
	// should read the first parameter up to delimiter '|'  but also  to ':'   if there is only this one entry
//	string  	sFormat	= RemoveWhiteSpace( StringFromList( 0, lstParams, "|" ) )
//	if ( strlen ( sFormat ) )	
//		ValDisplay	$sFCNm,	win = $sWin,	format 	= sFormat
//	endif
//	string  	sLimits	= RemoveWhiteSpace( StringFromList( 1, lstParams, "|" ) )
//	if ( strlen ( sLimits ) )	
//		ValDisplay	$sFCNm,	win = $sWin,	limits	 	= {	str2num(StringFromList( 0, sLimits,     "," ) ) ,	str2num(StringFromList( 1, sLimits,     "," ) ) ,	str2num(StringFromList( 2, sLimits,     "," ) )  }
//	endif
//	string  	sBarmisc	= RemoveWhiteSpace( StringFromList( 2, lstParams, "|" ) )
//	if ( strlen ( sBarmisc ) )	
//		ValDisplay	$sFCNm,	win = $sWin,	barmisc 	= {	str2num(StringFromList( 0, sBarmisc, "," ) ) ,	str2num(StringFromList( 1, sBarmisc, "," ) ) }
//	endif
//	string  	sLowColor	= RemoveWhiteSpace( StringFromList( 3, lstParams, "|" ) )
//	if ( strlen ( sLowColor ) )	
//		ValDisplay	$sFCNm,	win = $sWin,	lowColor 	= (	str2num(StringFromList( 0, sLowColor, "," ) ),	 str2num(StringFromList( 1, sLowColor, "," ) ),	 str2num(StringFromList( 2, sLowColor, "," ) ) )
//	endif
//	string  	sHighColor	= RemoveWhiteSpace( StringFromList( 4, lstParams, "|" ) )
//	if ( strlen ( sHighColor ) )	
//		ValDisplay	$sFCNm,	win = $sWin,	highColor 	= (	str2num(StringFromList( 0, sHighColor, "," ) ), str2num(StringFromList( 1, sHighColor, "," ) ), str2num(StringFromList( 2, sHighColor, "," ) ) )
//	endif

	variable	n, nParams	= ItemsInList( lstParams, "|" )
	string  	sParam
	for ( n = 0; n < nParams; n +=1 )
		sParam	= RemoveWhiteSpace(  StringFromList( n, lstParams, "|" ) )  	
		if ( strlen( sParam ) )
			if ( n == 0 ) 											// n=0 :  Number format  e.g.  %d   or  %3.1lf 
			 	ValDisplay   $sFCNm, win = $sWin, format	= sParam		
			elseif ( n == 1 )											 // n=1 : Limits  
			 	ValDisplay   $sFCNm, win = $sWin, limits	= { str2num( StringFromList( 0, sParam, "," ) ), str2num( StringFromList( 1, sParam, "," ) ), str2num( StringFromList( 2, sParam, "," ) ) }
			elseif ( n == 2 )											 // n=2 : Barmisc  
			 	ValDisplay   $sFCNm, win = $sWin, barmisc	= { str2num( StringFromList( 0, sParam, "," ) ), str2num( StringFromList( 1, sParam, "," ) ) }
			elseif ( n == 3 )											 // n=3 : LowColor  
			 	ValDisplay   $sFCNm, win = $sWin, lowColor= ( str2num( StringFromList( 0, sParam, "," ) ), str2num( StringFromList( 1, sParam, "," ) ), str2num( StringFromList( 2, sParam, "," ) ) )
			elseif ( n == 4 )											 // n=4 : HighColor  
			 	ValDisplay   $sFCNm, win = $sWin, highColor=( str2num( StringFromList( 0, sParam, "," ) ), str2num( StringFromList( 1, sParam, "," ) ), str2num( StringFromList( 2, sParam, "," ) ) )
			endif
		endif
	endfor
	// string  	sValue	= StringFromList( 6, lstParams, "|" )




	string  	sValue	= sFo + sWin + ":" + sName 
	Execute "ValDisplay " + sFCNm + ", win = " +sWin + ", value = #" + sValue		// also OK
	ValDisplay	$sFCNm,	win = $sWin,	userdata( sHelpTopic)= sHelpTopic	
	ValDisplay	$sFCNm,	win = $sWin,	userdata( bVisib )	= num2str( bVisib )

	// printf "\t\t\tPanelValDisplay3\t%s\t%s\tCtrlNm:\t%s\t%s\t%s\t   \r", pd(sFo,11),  pd(sName,16),   pd(sFCNm,27),  sValue, lstParams
End

Function	/S	fValDisplayProc()	
	// Get the format, limits, barmisc, lowColor and highColor  entries  of/for  a  ValDisplay  from a function
End




//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function	/S	fInitValProc()
End									// Dummy function prototype
Function	/S	fVisibilityProc()
End									// Dummy function prototype

//=========================================================================================================================
//  N-Dimensional  array  of  checkboxes,  radio buttons,  popupmenus  in  a  panel   with  or  without  a  tabcontrol

Function		PossiblyCreateFolder( sNestedFolder )
// If necessary build all  intermediate folders up to  'sF', which must be a full path starting with 'root' . If an empty folder is specified nothing is done.
// The final folder will be the current folder after the function is left, so  objects can be added conveniently, but the previous folder must be restored outside this function. 
// Returns 0 if the folder already existed ,  returns 1 if the folder has been created
	string  	sNestedFolder
	variable	n, nFolders = ItemsInList( sNestedFolder, ":" )
	variable	code		 = 0 				// assume that the desired folder already exists
	string  	sF
	if ( nFolders )
		sF	 = StringFromList( 0, sNestedFolder, ":" )
		if ( cmpstr( sF, "root" ) )
			DeveloperError( "Folder must start 'root' " )
		else
			for ( n = 1; n < nFolders; n += 1 )
				sF	+= 	":" + StringFromList( n, sNestedFolder, ":" )
				if ( ! DataFolderExists( sF ) )
					NewDataFolder  /S $sF				// folders are created one after the other starting below 'root' 
					code	 = 1							// the desired folder did not exist and has been created
				endif
			endfor
		endif
	endif
	// printf "\t\t\tPossiblyCreateFolder( %s ) returns %d ( the folder %s ) \r", sNestedFolder, code, SelectString( code, "already existed", "has been created" )
	return code
End

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

// Count the dimensions of 1 tabcontrol : how many tabs, how many blocks in each tab, how many rows and colunms in each tab and block ?

static Function	stTabCnt( lstTabTi )
	string  	lstTabTi
	return	ItemsInList( lstTabTi, ksSEP_TAB ) 
End



static Function	stBlkMax( lstBlkTi, MaxTabs )
// Returns the maximum number of blocks in any tab. Needed for the panel to keep its size if the number of blocks differs from tab to tab. 
	string  	lstBlkTi
	variable	MaxTabs 
	variable	nTab, MaxBlocks = 0
	for ( nTab = 0; nTab < MaxTabs; nTab += 1 )
		MaxBlocks	= max( MaxBlocks, stBlkCnt( lstBlkTi, nTab ) )
	endfor
//	// printf "\t\t\t\tBlkMax( \t%s\tmxTab:%2d ) \t-> \t%d \t \r",  pd(lstBlkTi,14),  MaxTabs, MaxBlocks
	return	MaxBlocks
End

static Function	stBlkCnt( lstBlkTi, nTab )
// Returns the number of blocks in  tab  'nTab' . 
	string  	lstBlkTi				// e.g......................................... 'b0;°b0;b1;b2;°'  will return 1 (nTab=0)  and  3 (nTab=1)
	variable	nTab
//	// printf "\t\t\t\tBlkCnt( \t%s\tnTab:%2d ) \t-> \t'%s'\t%s\t'%s' \t%d \t \r",  pd(lstBlkTi,14),  nTab, ksSEP_TAB, StringFromList( nTab, lstBlkTi, ksSEP_TAB ), ksTAB_B_SEP, ItemsInList( StringFromList( nTab, lstBlkTi, ksSEP_TAB ), ksTAB_B_SEP )
	return	ItemsInList( StringFromList( nTab, lstBlkTi, ksSEP_TAB ), ksSEP_STD )	// Mx( lstDims, kID_BLK )
End

static Function	stRowCnt( lstRowTi )
	string  	lstRowTi
	return	max( 1, ItemsInList( lstRowTi, ksSEP_STD ) )		// no separator or blank required in wPn
End

static Function	stColCnt( lstColTi )
	string  	lstColTi
	return	max( 1, ItemsInList( lstColTi, ksSEP_STD ) )			// no separator or blank required in wPn
End
 

//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//  TABCONTROL3    ( CheckBox ,  Radio button, SetVariable  and  Popupmenu  is handled )

Function		fTabControl3( s )
	struct	WMTabControlAction   &s
// 2009-10-26	make independent of future event codes
//	if ( s.eventcode != kEV_ABOUT_TO_BE_KILLED )				// 2007-0310		without this killing the control (as in PnDraw) would  trigger the action procedure 
	if ( s.eventcode == 2 )										// todo define ...._TAB_mouseup
		TabControl3( s.win, s.ctrlName, s.tab )
		FUNCREF   fTcProc3  fTcPrc = $( s.ctrlName )				//This action proc will only be executed when tabs are CLICKED, it will not be executed if tabs are changed indirectly by clicking into the window (as 's' is unknown).
		fTcPrc( s )											// Execute the action procedure (if there is one defined, it can also be missing) . Used in Eval  to activate the graph window corresponding to the clicked tab.
	endif
End


Function	TabControl3( sWin, sCtrlName, nTab )
	string  	sWin	, sCtrlName
	variable	nTab		

	string  	sF 			= GetUserData( 	sWin,  sCtrlName,  "sF" )
	string  	llstTypes		= GetUserData( 	sWin,  sCtrlName,  "llstTypes" )
	string  	llstCNames 	= GetUserData( 	sWin,  sCtrlName,  "llstCNames" )
	string  	lllstTabTi		= GetUserData( 	sWin,  sCtrlName,  "lllstTabTi" )
	string  	llstBlkTi		= GetUserData( 	sWin,  sCtrlName,  "llstBlkTi" )
	string  	llstMode		= GetUserData( 	sWin,  sCtrlName,  "llstMode" )
	string  	lllstRowTi		= GetUserData( 	sWin,  sCtrlName,  "lllstRowTi" )
	string  	lllstColTi		= GetUserData( 	sWin,  sCtrlName,  "lllstColTi" )
	string  	sTabcoNr		= GetUserData( 	sWin,  sCtrlName,  "sTabcoNr" )

	variable	tgCnt		= ItemsInList(  llstTypes, ksSEP_TBCO )			// needed only for debug printing
	variable	nTabco	= str2num( sTabcoNr )						// the clicked tabcontrol
	// printf "\t\tfTabControl3 a\ttg:%2d/%2d\tTb:%d\t %s\t%s\t%s \r",  nTabco, tgCnt, nTab, pd(sF,16), pd(sWin,13), pd(sCtrlName,23)
	// printf "\t\tfTabControl3 b\ttgCnt:%2d\tTb:%d\t Ty:\t%s\t%s\tta:\t%s\tbl:\t%s \tro:\t%s\tco:\t%s\t \r",  tgCnt, nTab, pd(llstTypes,13), pd(llstCNames,26), pd(lllstTabTi,17), pd(llstBlkTi,21),  pd(lllstRowTi,19),  pd(lllstColTi,19)
	string  	lstTypes, lstCNames, lstTabTi, lstBlkTi, lstMode, llstRowTi, llstColTi
	lstTypes	= StringFromList( nTabco, llstTypes,	ksSEP_TBCO )
	lstCNames	= StringFromList( nTabco, llstCNames,	ksSEP_TBCO )			// Contains  catenated  names  of all controls within this tabcontrol.
	lstTabTi	= StringFromList( 0, StringFromList( nTabco, lllstTabTi, ksSEP_TBCO ) ,  ksSEP_CTRL )  // the list-list contains the same entry for each control (of 1 tg) , use the first
	lstBlkTi	= StringFromList( nTabco, llstBlkTi,	ksSEP_TBCO )  
	lstMode	= StringFromList( nTabco, llstMode,	ksSEP_TBCO )  
	llstRowTi	= StringFromList( nTabco, lllstRowTi,	ksSEP_TBCO )
	llstColTi	= StringFromList( nTabco, lllstColTi,	ksSEP_TBCO )
	// printf "\t\tfTabControl3 c\ttg:%2d/%2d\tTb:%d\t %s\t%s\t%s\tl \r",  nTabco, tgCnt, s.tab, pd(sF,16), pd(sWin,13), pd(sCtrlName,23)
	// printf "\t\tfTabControl3 e\tnTabco:%2d\tTb:%d\t Ty:\t%s\t%s\tta:\t%s\tbl:\t%s \t%s\tro:\t%s\tco:\t%s\t \r", tgCnt, s.tab, pd(lstTypes,13), pd(lstCNames,28), pd(lstTabTi,24),  pd(lstBlkTi,21),  pd( lstMode,19),  pd(llstRowTi,19),  pd(llstColTi,19)
	// Turn on and off the controls belonging to the tabs which are drawn one on top of each other. Only the control of the active tab is shown and enabled, the others are hidden and off. 
	stShowHideTabControl3( sCtrlName, nTab, sF, sWin, lstTypes, lstCNames, lstTabTi, lstBlkTi, lstMode, llstRowTi, llstColTi ) 
	stPnTabcoIndexSet( sF + sWin, nTabco, nTab )			// store the currently selected tab as the active tab

// test
//	ControlUpdate /A /W = $s.win	// BAD: makes screen flicker  but without this line  SOME!  popupmenu and setvariable  are not displayed  when changing tabs
End

Function		fTcProc3( s )							// dummy function  prototype
	struct	WMTabControlAction &s
End

static Function	stShowHideTabControl3(  sTabCtrlNm, nSelectedTab, sF, sWin, lstTypes, lstCNames, lstTabTi, llstBlkTi, llstMode, llstRowTi, llstColTi ) 
// Turn on and off the CheckBox controls belonging to the tabs which are drawn one on top of each other. Only the control of the active tab is shown and enabled, the others are hidden and off. 
//  to to ? pass and evaluate the window...
	string  	sTabCtrlNm							// not used			
	string  	sF, sWin, lstTypes, lstCNames, lstTabTi, llstBlkTi, llstMode, llstRowTi, llstColTi
	variable	nSelectedTab
	string  	sTitleLists, sCNm, lstBlkTi, lstMode, lstRowTi, lstColTi, lstBlkTi1Ctrl, lstMode1Ctrl

	string  	sFsSub	= sF + sWin + ":"
	string  	sCNmIdx, sFoCNmIdx
	variable	nBlk, nRow, nCol, nTab, nType, nMode
	variable	c, nControlsInTab	= ItemsInList( lstTypes, ksSEP_CTRL) 
	variable 	bVisib, bDisableVis

	// printf "\t\t\tShowHideTabControl3\t%s\tTb:%d\t Ty:\t%s\t%s\tta:\t%s\tbl:\t%s \t%s\tro:\t%s\tco:\t%s\t \r",sTabCtrlNm , nSelectedTab, pd(lstTypes,13), pd(lstCNames,21), pd(lstTabTi,13),  pd(llstBlkTi,13),  pd( llstMode,13),  pd(llstRowTi,13),  pd(llstColTi,13)
	for ( c = 0; c < nControlsInTab; c += 1 )
		nType	= str2num(  StringFromList( c, lstTypes, ksSEP_CTRL ) ) 
		sCNm	= StringFromList( c, lstCNames, 	ksSEP_CTRL )  

		lstBlkTi1Ctrl= StringFromList( c, llstBlkTi, 	ksSEP_CTRL ) 
		lstMode1Ctrl= StringFromList( c, llstMode, 	ksSEP_CTRL ) 

		lstRowTi	= StringFromList( c, llstRowTi,	ksSEP_CTRL ) 
		lstColTi	= StringFromList( c, llstColTi,	ksSEP_CTRL )

		variable	TabMax, BlkMax, RowMax, ColMax
		TabMax	= stTabCnt( lstTabTi )
		for ( nTab = 0; nTab < TabMax; nTab += 1 )				

			lstBlkTi		= StringFromList( nTab, lstBlkTi1Ctrl, ksSEP_TAB )
			lstMode		= StringFromList( nTab, lstMode1Ctrl, ksSEP_TAB )	// allows blanking out specific blocks

			BlkMax	= stBlkCnt( lstBlkTi1Ctrl, nTab )
			for ( nBlk = 0; nBlk < BlkMax; nBlk += 1 )

				lstBlkTi	= StringFromList( nBlk, lstBlkTi, ksSEP_STD )
				nMode	= str2num( StringFromList( nBlk, lstMode, ksSEP_STD ) )

				variable	bTabDisable	= ! ( nSelectedTab == nTab )
				variable	bDisable		= bTabDisable  ||  ( nMode == 0 )
				// printf "\t\t\tShowHideTabControl3\t%s\t%s\tTyp:%d\t%s\tTab:%d/%d  SelTb:%d\tDisable:%d\tblk:%d/%d\tnMode:%d\t->dis:%d\t-> %s\t-> %s\t \r",  pd(sTabCtrlNm,15), pd(lstTypes,9), nType, pd( sCNm,9), nTab, TabMax, nSelectedTab, bTabDisable, nBlk, BlkMax, nMode,  bDisable, pd(lstBlkTi1Ctrl,19), pd(lstBlkTi,13)

	
				RowMax = stRowCnt( lstRowTi )
				for ( nRow = 0; nRow < RowMax; nRow += 1 )
					ColMax = stColCnt( lstColTi )
					for ( nCol = 0; nCol < ColMax; nCol += 1 )
						sCNmIdx 	  = stPnBuildVNmIdx( sCNm, nTab, nBlk, nRow, nCol )
						sFoCNmIdx  = ReplaceString( ":", sFsSub, "_" ) + sCNmIdx
	
						// Version 1 : eliminate  dummy blank lines which have no associated control
						// ControlInfo $sWin $sFoCNmIdx
						// if ( V_Flag )
						//	bVisib 	  = str2num( GetUserData( sWin, sFoCNmIdx, "bVisib" ) )
						//	bDisableVis = bDisable  ||  ! bVisib
						 //	printf "\t\t\tShowHideTabControl3\t%s\t%s\tTyp:%d\tTab:%d/%d  SelTb:%d\tDisable:%d ||  !\tVis:%.0lf =\tDisVi:%d\tblk:%d/%d\trow:%d/%d\tcol:%d/%d\t%s\t%s\t \r", pd(sFoCNmIdx,27), pd(sCNmIdx,13), nType, nTab, TabMax, nSelectedTab, bDisable, bVisib, bDisableVis, nBlk, BlkMax, nRow, RowMax, nCol, ColMax, pd(sF,15), pd(sCNm,9)
						//endif
//						if ( nType == kSEP )
//						elseif ( nType == kCB )
//							bVisib 	  = str2num( GetUserData( sWin, sFoCNmIdx, "bVisib" ) )
//							bDisableVis = bDisable  ||  ! bVisib
//							Checkbox	  $sFoCNmIdx,	win = $sWin,	disable = bDisableVis	
//						elseif ( nType == kRAD )
//							Checkbox	  $sFoCNmIdx,	win = $sWin,	disable = bDisableVis	
//						elseif ( nType == kSV  ||  nType == kSTR )
//							SetVariable  $sFoCNmIdx,	win = $sWin,	disable = bDisableVis	
//						elseif ( nType == kPM )
//							PopupMenu $sFoCNmIdx,	win = $sWin,	disable = bDisableVis
//						elseif ( nType == kBU )
//							Button	 $sFoCNmIdx,	win = $sWin,	disable = bDisableVis
//						endif

						// Version 2 : eliminate  dummy blank lines which have no associated control
						if ( nType == kSEP )
						else
							bVisib 	  = str2num( GetUserData( sWin, sFoCNmIdx, "bVisib" ) )
							bDisableVis = bDisable  ||  ! bVisib
							// printf "\t\t\tShowHideTabControl3\t%s\t%s\tTyp:%d\tTab:%d/%d  SelTb:%d\tDisable:%d ||  !\tVis:%.0lf =\tDisVi:%d\tblk:%d/%d\trow:%d/%d\tcol:%d/%d\t%s\t%s\t \r", pd(sFoCNmIdx,27), pd(sCNmIdx,13), nType, nTab, TabMax, nSelectedTab, bDisable, bVisib, bDisableVis, nBlk, BlkMax, nRow, RowMax, nCol, ColMax, pd(sF,15), pd(sCNm,9)
							if ( nType == kCB )
								Checkbox	  $sFoCNmIdx,	win = $sWin,	disable = bDisableVis	
							elseif ( nType == kBUP )
								Checkbox	  $sFoCNmIdx,	win = $sWin,	disable = bDisableVis
							elseif ( nType == kRAD )
								Checkbox	  $sFoCNmIdx,	win = $sWin,	disable = bDisableVis	
							elseif ( nType == kSV  ||  nType == kSTR )
								SetVariable  $sFoCNmIdx,	win = $sWin,	disable = bDisableVis	
							elseif ( nType == kPM )
								PopupMenu $sFoCNmIdx,	win = $sWin,	disable = bDisableVis
							elseif ( nType == kBU )
								Button	 $sFoCNmIdx,	win = $sWin,	disable = bDisableVis
							elseif ( nType == kSTC )
								CustomControl	$sFoCNmIdx, win = $sWin,	disable = bDisableVis
							elseif ( nType == kVD )
								ValDisplay		$sFoCNmIdx, win = $sWin,	disable = bDisableVis
							endif
						endif
if ( ! bDisableVis ) 
	ControlUpdate  /W = $sWin $sFoCNmIdx	// BAD: makes a little screen flicker  but without this line  SOME!  popupmenu and setvariable  are not displayed  when changing tabs
endif
					endfor
				endfor
			endfor
		endfor
	endfor
End


////----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

static Function	stInitValue( sCNm, lstInitVal, nInitVal )	
// Extracts initial value from list for control  'sCNm' .  Control can be  PopMenu, SetVariable , Checkbox or Button.  Accepts integers, negative integers, floats.  Also tolerates strings but cannot process them as a number is returned.
// Initial setting	T0 B0 R? C0 : 3, 	T0 B0 R? C1 : 2.5,	T1 B0 R? C0 : -7     all the rest: 2.3	is coded	'0000_3;0001_2.5;1000_-7;~2.3'  .  Uses   ksSEP_COMMONINIT '~'
// tab,blk,row,col are coded in the string: ++ Is easy to read and modify, any order and missing entries are allowed.  -- Needs more space, handling takes longer as complete list is scanned, 
	string  	sCNm, lstInitVal
	variable	nInitVal												// return this value if no value could be extracted from the list
	variable	len 			= strlen( sCNm )
	string  	sCNmIdx		= sCNm[ len - 4 , len - 1 ]						// Extract the indices of the control  e.g. 'svName0102' 	-> '0102'
	string  	lstSpecificInitVal	= StringFromList( 0, lstInitVal, ksSEP_COMMONINIT )	//  e.g. '0000_3;0001_2.5;1000_-7;~2.3' 				->  '0000_3;0001_2.5;1000_-7'
	string  	sCommonInitVal	= StringFromList( 1, lstInitVal, ksSEP_COMMONINIT )	//  e.g. '0000_3;0001_2.5;1000_-7;~2.3' 				->  '2.3'
	variable	nCommonInitVal	= str2num( sCommonInitVal )
	nInitVal	= numType( nCommonInitVal ) == kNUMTYPE_NAN ? 	nInitVal : nCommonInitVal	// only if no common value could be extracted from the list (=the value after the ~)  then use the passed value

	variable	i, nItems	= ItemsInList( lstSpecificInitVal )						//  e.g. '0000_3;0001_2.5;1000_-7;'		-> 3
	for ( i = 0; i < nItems; i += 1 )		
// 051119
//		string  	sSpecInitIdx_Val = StringFromList( i, lstInitVal )				//  e.g. '0000_3;0001_2.5;1000_-7;~2.3'	-> '0000_3'
		string  	sSpecInitIdx_Val = StringFromList( i, lstSpecificInitVal )			//  e.g. '0000_3;0001_2.5;1000_-7;'		-> '0000_3'
		string  	sSpecInitIdx	 = StringFromList( 0, sSpecInitIdx_Val, "_" )		//  e.g. '0000_3'						-> '0000'
		string  	sSpecInitVal	 = StringFromList( 1, sSpecInitIdx_Val, "_" )		//  e.g. '0000_3'						-> '3'
		if ( cmpstr( sCNmIdx, sSpecInitIdx ) == 0 )							//  e.g. '0000'  ?  '0000' : matching		-> extract '3' 
			variable	nSpecInitVal	= str2num( sSpecInitVal )	
			nInitVal	= numType( nSpecInitVal ) == kNUMTYPE_NAN ? nInitVal : nSpecInitVal	// no specific value could be extracted from the list so use the passed value
			// printf "\t\t\tInitValue(\t%s\t%s\t%.2g )\tComIV:\t%.2g\t%2d/%2d\t%s\tSpecIV:\t%.2g\t->Return:\t%.2g  \r", pd(sCNm,15),  pd(lstInitVal,31), nInitVal, nCommonInitVal, i, nItems,  sSpecInitIdx_Val, nSpecInitVal, nInitVal
			return	nInitVal
		endif
	endfor
	return	nInitVal
End

static Function	/S	stInitString( sCNm, lstInitVal, sInitVal )	
// Extracts initial value from list for control  'sCNm' .  Control can be  SetVariable  used  with strings  ( "STR" / kSTR  but not "SV" / kSV ).  
// Initial setting	T0 B0 R? C0 : X, 	T0 B0 R? C1 : Y,	T1 B0 R? C0 : Z     all the rest: AllRest	is coded	'0000_X;0001_Y;1000_Z;~AllRest'  .  Uses   ksSEP_COMMONINIT '~'
// tab,blk,row,col are coded in the string: ++ Is easy to read and modify, any order and missing entries are allowed.  -- Needs more space, handling takes longer as complete list is scanned, 
	string  	sCNm, lstInitVal, sInitVal									// return  'sInitVal'  if no value could be extracted from the list
	variable	len 			= strlen( sCNm )
	string  	sCNmIdx		= sCNm[ len - 4 , len - 1 ]						// Extract the indices of the control  e.g. 'svName0102' 	-> '0102'
	string  	lstSpecificInitVal	= StringFromList( 0, lstInitVal, ksSEP_COMMONINIT )	//  e.g. '0000_X;0001_roW;1000_Y;~AllRest' 		->  '0000_rOw;0001_roW;1000_rOW'
	string  	sCommonInitVal	= StringFromList( 1, lstInitVal, ksSEP_COMMONINIT )	//  e.g. '0000_X;0001_roW;1000_Y;~AllRest' 		->  'AllRest'
	sInitVal	= SelectString( strlen(sCommonInitVal)==0  , sCommonInitVal, sInitVal ) 	// only if no common string could be extracted from the list (=the string after the ~) then use the passed value

	variable	i, nItems	= ItemsInList( lstSpecificInitVal )						//  e.g. '0000_X;0001_Y;1000_Z;'	-> 3
	for ( i = 0; i < nItems; i += 1 )		
		string  	sSpecInitIdx_Val = StringFromList( i, lstSpecificInitVal )			//  e.g. '0000_X;0001_Y;1000_Z;'	-> '0000_X'
		string  	sSpecInitIdx	 = StringFromList( 0, sSpecInitIdx_Val, "_" )		//  e.g. '0000_X'				-> '0000'
		string  	sSpecInitVal	 = StringFromList( 1, sSpecInitIdx_Val, "_" )		//  e.g. '0000_X'				-> 'X'
		if ( cmpstr( sCNmIdx, sSpecInitIdx ) == 0 )							//  e.g. '0000'  ?  '0000' : matching	-> extract 'X' 
			// printf "\t\t\tInitString(\t%s\t%s\t%s )\tComIV:\t%s\t%2d/%2d\t%s\t\t->Return:\t%s  \r", pd(sCNm,15),  pd(lstInitVal,31), sInitVal, sCommonInitVal, i, nItems,  sSpecInitIdx_Val, sSpecInitVal
			return	sSpecInitVal									// found matching specific value : return it  e.g. 'X'
		endif
	endfor
	return	sInitVal												// return common value if found ( e.g. 'AllRest' )   or if not found then return the PASSED string parameter 'sInitVal'
End

//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

static  constant	kID_TAB = 0,  kID_BLK = 1,  kID_ROW = 2,  kID_COL = 3	// This is the order of the indices for the automatic control variables.


static Function  /S	stPnBuildFoTabcoNm( sFsPnWndNm, nTabco )
	string  	sFsPnWndNm
	variable	nTabCo
	string  	sFoTabcoNm	= sFsPnWndNm + ":" + "tc" + num2str( nTabco )		// e.g. root:uf:evo:de:tc1
	// printf "\t\t\t\tPnBuildFoTabcoNm() \t'%s'\t  \r", 	sFoTabcoNm
	return						sFoTabcoNm
End

static Function  /S	stPnBuildVNmIdx( sBsNm, nTab, nBlk, nRow, nCol )
	string  	sBsNm
	variable	nBlk, nRow, nCol, nTab
	// this implementation  allows indices from 0 to 35  using just 1 character / index. Total characters used are  4
	string  	sIndexedNm	= sBsNm + IdxToDigitLetter(nTab)  +  IdxToDigitLetter(nBlk) +  IdxToDigitLetter(nRow) + IdxToDigitLetter(nCol)
	return	sIndexedNm
End	

Function		TabIdx( sCNm )
// returns index of the tabcontrol where the control  'sCNm'  resides
	string  	sCNm					
	variable	len = strlen( sCNm )								
//	return	str2num( sCNm[ len - 4 + kID_TAB, len - 4 + kID_TAB ] )		// range is 0 .. 9 , could be extended to range 0..35, see  'DigitLetterToIdx()'
	return	DigitLetterToIdx( sCNm[ len - 4 + kID_TAB, len - 4 + kID_TAB ] )	// range is 0..35
End

Function		BlkIdx( sCNm )
// returns index of the  block  where the control  'sCNm'  resides
	string  	sCNm					
	variable	len = strlen( sCNm )				
//	return	str2num( sCNm[ len - 4 + kID_BLK, len - 4 + kID_BLK ] )		// range is 0 .. 9 , could be extended to range 0..35, see  'DigitLetterToIdx()'
	return	DigitLetterToIdx( sCNm[ len - 4 + kID_BLK, len - 4 + kID_BLK ] )	// range is 0..35
End

Function		RowIdx( sCNm )
// returns index of the  row  where the control  'sCNm'  resides
	string  	sCNm					
	variable	len = strlen( sCNm )				
	return	DigitLetterToIdx( sCNm[ len - 4 + kID_ROW, len - 4 + kID_ROW ] )// range is 0..35
End

Function		ColIdx( sCNm )
// returns index of the  column where the control  'sCNm'  resides
	string  	sCNm					
	variable	len = strlen( sCNm )				
	return	DigitLetterToIdx( sCNm[ len - 4 + kID_COL, len - 4 + kID_COL ] )	// range is 0..35
End



// Function		LinRadioButtonIndex( nTab, nBlk, nRow, nCol, lstTabTi, lstBlkTi, lstRowTi, lstColTi )
// Version 2 : Obsolete,  impractical and unfinished: if this is used then  there is only 1 radio button for all tabs, blocks rows and columns
//	string  	lstTabTi, lstBlkTi, lstRowTi, lstColTi
//	variable	nTab, nBlk, nRow, nCol
//	variable	mxTabs = TabCnt( lstBlkTi )
//	return	( ( nTab * BlkMax( lstBlkTi, mxTabs )  + nBlk ) * RowCnt( lstRowTi, nTab, nBlk  ) + nRow ) * ColCnt( lstColTi, nTab, nBlk  ) + nCol 
//End



//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Function		PnValC( sFoVarNmIdx )
// Get  the value from the variable specified by  the  control name  (which includes the folder and  the indexed variable name)
	string  	sFoVarNmIdx									// e.g.  'root_uf_tst_MyVar032'
	nvar		value	= $ReplaceString( "_", sFoVarNmIdx, ":" )	// e.g.  'root:uf:tst:MyVar032'	==	Control2Wave()
	return	value
End

//Function		PnValS( sF, sVarNmIdx )
//// Get  and  set  the value from the variable specified by  the folder  and  the indexed variable name
//	string  	sF, sVarNmIdx								// e.g.  'root:uf:tst'   and   'MyVar032'       'MyVar011312'
//	nvar		value	= $"sF:" + sVarNmIdx 
//	return	value
//End
//
//Function		PnSetValS( sF, sVarNmIdx, value )
//// Get  and  set  the value from the variable specified by  the folder  and  the indexed variable name
//	string  	sF, sVarNmIdx								// e.g.  'root:uf:tst'   and   'MyVar032'       'MyVar011312'
//	variable	value
//	nvar		var		= $"sF:" + sVarNmIdx 
//	var	= value
//End

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Get  and  set  the value from the variable specified by the folder, the base name and  the indices
Function		PnVal( sF, sBsNm, nTab, nBlk, nRow, nCol  )
	string  	sF, sBsNm								// e.g.  'root:uf:tst'   and   'MyVar'
	variable	nTab, nBlk, nRow, nCol
	nvar		value   = $sF + ":" + stPnBuildVNmIdx( sBsNm, nTab, nBlk, nRow, nCol ) 
	return	value
End

////Function		PnSetVal3( sF, sBsVNm, nBlk, nRow, nCol, value )
////	string  	sF, sBsVNm								// e.g.  'root:uf:tst'   and   'MyVar'
////	variable	nBlk, nRow, nCol, value
////	nvar		var	   = $"sF:" + PnBuildVNm3( sBsVNm, nBlk, nRow, nCol ) 
////	var	= value
////End


//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//  Save  and  recall  panel settings

Function		SaveAllFolderVars( sFolder, sPanel, sPath, sFileBase, sFileExt )
//  'SaveRegionsAndCursors()'  and  'SaveAllFolderVars()'  are companion functions
	string  	sFolder, sPanel, sPath,  sFileBase, sFileExt 

	string  	sFilePath, sObjName, lstAllVars = ""
	variable	index, nVars	= CountObjects( sFolder + sPanel + ":", kIGOR_VARIABLE )
	variable	Checksum = 0

	// Loop through all control variables in this folder
	for ( index = 0; index < nVars; index += 1 )
		sObjName = GetIndexedObjName( sFolder + sPanel + ":",  kIGOR_VARIABLE, index )
		nvar	value	= $sFolder + sPanel + ":" +  sObjName

		// Build the control name from the variable name and check that the control exists.  This is necessary as (at the moment) there are variables in the folder without control
		string  	sFoCoNm	= ReplaceString( ":", sFolder + sPanel + ":" +  sObjName, "_" )
		ControlInfo		/W=$sPanel	$sFoCoNm			// Check that the control exists, as there are variables in the folder without control e.g. buttons, separators, the single-radio-var  or  false tabcontrol (no tabs)  
		variable	bDisable	=  V_flag  ?  V_Disable  : TRUE		// when there is a variable but no corresponding control  the flag for this non-existant control is set to 'disabled'

		lstAllVars	= AddListItem( sObjName + "=" + num2str( value ) +  "=" + num2str( bDisable ), lstAllVars, "\r", inf )	// assumption : control name without folder = value = bDisable
		Checksum	+= value
		// printf "\t\t\tGetVarsInFolder   \t%s\t%s\t-> \tvariable %3d/%3d\t%s\tvalue:%6.2g\tco:\t%s\tdisable:\t%d\t \r",  pd(sFolder,17), pd(sPanel,9), index, nVars, pd(sObjName,19), value, pd( sFoCoNm, 29), bDisable	
	endfor
	
	PossiblyCreatePath( sPath )
	//Function	/S	PanelSettingPath()

	sFilePath	= sPath + ":" + sFileBase + "." + sFileExt
	  printf "\t\t\tGetVarsInFolder  \t\t%s\t%s\t %2d\tvariables (sum %6.2lf)\t'%s'\tlen:% 3d\t%s... \r", pd(sFolder,17), pd(sPanel,9), nVars, Checksum, sFilePath, strlen(lstAllVars),  ReplaceString( "\r", lstAllVars[0,150], "    " ) 
	string		sNBName	= "Nb" 		// = 'NbPn'	

	if (  WinType( sNBName ) != kNOTEBOOK )					// Only if the Notebook window does not  exist.. 
		NewNotebook  /N=$sNBName	/F=0  /K=1 /V=0		// plain text and invisibly
	endif
	Notebook $sNBName, selection={startOfFile, endOfFile}, text="\r", selection={startOfFile, startOfFile}	// delete old stuff
	Notebook $sNBName, text		= lstAllVars
	SaveNoteBook  /O /S=2	$sNBName  as  sFilePath			// save any changes in the script the user may have made in the same file (will not work without /S=2 = Save as)
	DoWindow /K $sNBName 								// kill notebook window. Until this is done the corresponding file is open and locked.

End


Function		RecallAllFolderVars( sFolder, sWin, sPath, sFileName, sThisControl )
// Reads  PanelSettings file .   Data must be delimited by CR. 
	string		sFolder, sWin, sPath, sFileName, sThisControl
	variable	nRefNum, nLine = 0, LineLen, index = -1, Checksum = 0
	string		sLine		= ""
	string  	sCoNm, sFoCoNm, sFoVarNm	= "", sType
	string  	sFilePath	= sPath + ":"  + sFileName 

	ClearFolderVars( sFolder + sWin + ":" )
	Open /Z=2 /R  nRefNum  as sFilePath							// /Z = 2: opens dialog box  if file is missing,  /Z = 1: no dialog / does nothing if file is missing
	// OpenNotebook might be more elegant. Read into string list, then extract from string list ???
	if ( nRefNum != 0 )							
		do 										
			FReadLine nRefNum, sLine				
			LineLen	= strlen( sLine )								// Empty lines contain CR or LF: their length is >= 1...
			if ( LineLen > 3 )										//  is a valid line, the only invalid line has len=1 and  must be EOF 	
				index   += 1
				sCoNm	= StringFromList( 0, sLine, "=" )				// assumption : control name without folder = value = bDisable	

				sFoVarNm	= sFolder + sWin + ":"  + sCoNm						// e.g.   root:uf:evo: +  Set:  +   tc0, svA0000, cbB1000				
				variable	/G	   $sFoVarNm	= str2num( StringFromList( 1, sLine, "=" ) )
				nvar	value	= $sFoVarNm	
				variable			bDisable	= str2num( StringFromList( 2, sLine, "=" ) )

				Checksum += value
				sFoCoNm	= ReplaceString( ":", sFoVarNm, "_" )			// e.g.  root_uf_evo_svA0000,  root_uf_evo_cbB1000

				ControlInfo		/W=$sWin	$sFoCoNm			// Check that the control exists.  This is necessary as (at the moment) there are variables in the folder without control e.g. buttons, separators, the single-radio-var  or  false tabcontrol (no tabs)  
				switch ( V_flag )
					case kCI_BUTTON:							// no setting needed (but we must avoid running into 'default:' )
						Button		$sFoCoNm, win = $sWin,  			disable = bDisable
						break
					case kCI_CHECKBOX:
						Checkbox		$sFoCoNm, win = $sWin, value = value, disable = bDisable	// This only sets the checkbox but does not adjust the single underlying radio buttons variable.

						// Bad code:		TODO
						// After the checkbox has been set we must adjust the single underlying radio buttons variable.		// 051109
						// 1.	is especially arranged for  and  will  (most probably) work only for 1 dimensional horizontal radio buttons 
						// 2. relies on the control name starting with  'ra'   e.g.  'raStartVal'
						// Possible solution: avoid radio buttons altogether  and replace them by popupmenus	
						SetTheSingleGlobalRadioVariable( sFoVarNm, "ra", value )
						// sType = "CB"
						// printf "\t\t\tRecallAllFolderVars \t%s\t%s\t %2d (sum %6.2lf)\t'%s'\t  Ty:%2d  %s\t%s\t%s\t%.2g\t[%d]\t  \r", pd(sFolder,17), pd(sWin,9), index+1, Checksum, sFilePath, V_Flag, sType, pd(sFoVarNm,27), pd(sFoCoNm,28),  value, bDisable

						break
					case kCI_POPUPMENU:
						// Do NOT update the 'Recall/Load' popupmenu which has just been executed  for a new file.  All other variables are OK and must be updated but this one contains the old index pointing to the file which was valid at 'save' time.
						// Also the old index will be wrong (and of no use) if files have been deleted between saving  and  recalling.
						if ( cmpstr( sCoNm, sThisControl ) )  	
							Popupmenu	$sFoCoNm, win = $sWin, mode =  max( 1, value ), disable = bDisable		// avoid the mode=0 , as this makes the popmenu unchangeable (should/could be prevented earlier)
							//  printf "\t\t\tRecallAllFolderVars()\tSetting: \t%s\t%s\t ->\t%d\t->\t%d\tdisable:%2d\t \r", sCoNm, sFoCoNm, value, max( 1, value ), bDisable
//ControlUpdate /W=$sWin $sFoCoNm//
						else
							// printf "\t\t\tRecallAllFolderVars()\tIgnoring:\t%s\t%s\t \r", sCoNm, sThisControl
						endif
						break
					case kCI_SETVARIABLE:						
						SetVariable	$sFoCoNm, win = $sWin, 			disable = bDisable	// no setting needed as the control itself displays the current value
						break
					case kCI_TABCONTROL:
						Tabcontrol		$sFoCoNm, win = $sWin, value = value, disable = bDisable
						break
					default:
						value	= 0

//						value	= -1
						// do NOT set value to -1: this will permanently hide all controls in a false tabcontrol as nSelectedTab will be set to -1.....// value 	= -1
						sFoVarNm	= " NOT a true control ..."				// this is not an error, at the moment there are variables in the folder without control e.g. buttons, separators, the single-radio-var  or  false tabcontrol (no tabs)  
				endswitch
				sType	=  StringFromList( V_Flag, klstCI_CONTROLTYPES )			// e.g.  tb,  sv,  cb  
				// Enable the next line to check whether a panel control is stored and recalled correctly.
				// printf "\t\t\tRecallAllFolderVars \t%s\t%s\t %2d (sum %6.2lf)\t'%s'\t  Ty:%2d  %s\t%s\t%s\t%.2g\t[%d]\t  \r", pd(sFolder,17), pd(sWin,9), index+1, Checksum, sFilePath, V_Flag, sType, pd(sFoVarNm,27), pd(sFoCoNm,28),  value, bDisable
			endif
		while ( LineLen > 0 )     							//...is not yet end of file EOF
		Close nRefNum								// Close the script file... but reopen as a Notebook  below....
		  printf "\t\t\tRecallAllFolderVars() \t\t%s\t%s\t %2d (sum %6.2lf)\trecalled from\t'%s'\t  \r", pd(sFolder,17), pd(sWin,9), index+1, Checksum, sFilePath
	else
		FoAlert( sFolder, kERR_FATAL,  " RecallAllFolderVars()  could not open '" + sFilePath + "' " )	
	endif

End

Function		ClearFolderVars( sFolder )
	string  	sFolder
	string 	sDFSave	= GetDataFolder( 1 )		// Remember CDF in a string.
	SetDataFolder	$sFolder	
	//printf "\t\t\tRecallAllFolderVars bef. clear\tFo:\t%s.\t %2d\tvariables\r", pd(sFolder,19),  CountObjects( sFolder, kIGOR_VARIABLE )
	KillVariables  /A  /Z
	//printf "\t\t\tRecallAllFolderVars after clear\tFo:\t%s. \t %2d\tvariables\r", pd(sFolder,19),  CountObjects( sFolder, kIGOR_VARIABLE )
	SetDataFolder sDFSave 	
End


Function	/S	StripFolders( sFolderCtrlName )
// remove all folders e.g. 'root_uf_evo_Set_cbAlDel0000'  -> 'cbAlDel0000' 
	string  	sFolderCtrlName
	variable	nNmParts			= ItemsInList( sFolderCtrlName, "_" )
	string  	sThisControl		= StringFromList( nNmParts - 1, sFolderCtrlName, "_" )	// remove all folders e.g. 'root_uf_evo_Set_cbAlDel0000'  -> 'cbAlDel0000' 
	return	sThisControl
End	

Function	/S	StripFoldersAnd4Indices( sFolderCtrlName )
// remove all folders and the 4 trailing 'tab/blk/row/col' indices e.g. 'root_uf_evo_Set_cbAlDel0000'  -> 'cbAlDel' 
	string  	sFolderCtrlName
	string  	sThisControl		= StripFolders( sFolderCtrlName )					// remove all folders e.g. 'root_uf_evo_Set_cbAlDel0000'  -> 'cbAlDel0000' 
	return	sThisControl[ 0, strlen( sThisControl ) - 1 - 4 ]							// e.g. 'cbAlDel0000'  -> 'cbAlDel' 
End	

Function		SetTheSingleGlobalRadioVariable( sFoVarNm, sRadioNameStartsWith, value )
// see also: SetTheSingleRadioCBGlobal
	string		sFoVarNm, sRadioNameStartsWith
	variable	value
	// 051109  Bad code  as  	 1. is especially arranged for  and  will  (most probably) work only for 1 dimensional horizontal radio buttons 	2. relies on the control name starting with  'ra'   e.g.  'raStartVal'
	variable	nNameParts	= ItemsInList( sFoVarNm, ":" )							// e.g. 'root:uf:evo:de:raStVal0000'  or   'root:uf:evo:de:raStVal0001'
	string		sBaseNm		= StringFromList( nNameParts-1, sFoVarNm, ":" )				// e.g. 'raStVal0000'  or   'raStVal0001'
	variable	len			= strlen( sRadioNameStartsWith )
	string  	sTheSingleGlobalRadioVariable
	if ( cmpstr( sBaseNm[ 0, len-1 ], sRadioNameStartsWith ) == 0 )						// the checkbox belongs to a radio button group 
		if ( value == 1 )														// it is the selected radio button
			len	= strlen( sFoVarNm )
			sTheSingleGlobalRadioVariable = RemoveEnding( RemoveEnding( sFoVarNm ) )	// e.g. 'root:uf:evo:de:raStVal00'  TODO ALWAYS REMOVES JUST 2 NUMBERS, COULD BE 1 OR 3  DEPENDING ON RADIO DIMENSIONS
			variable /G   $sTheSingleGlobalRadioVariable	// for some (uninvestigated) reason the 'sTheSingleGlobalRadioVariable'  is sometimes recalled before and sometimes after the radio buttons, so we construct it right now and do not wait until it is automatically constructed later  
			nvar	val	= $sTheSingleGlobalRadioVariable
			val		= str2num( sFoVarNm[ len-1, len-1 ] )							// the last digit of the name of the turned-on button is the value with which the single underlying global radio button variable must be set
			printf "\t\t\tSetTheSingleGlobalRadioVariable(\t%s\t'%s'  %g )\t ->\t%s\t= %d  \r", pd(sFoVarNm,27), sRadioNameStartsWith, value, pd(sTheSingleGlobalRadioVariable,27), val 
		endif
	endif
End

//===========================================================================================================================================
//  ENABLE  OR  kDISABLE  A  BUTTON ,  A  CHECK BOX   OR  A  POPUPMENU

Function		TurnButton( sWin, sCtrlName, bState )
// Set the underlying variable   AND  change the button's appearance accordingly
	string		sWin, sCtrlName
	variable	bState
	if ( WinType( sWin ) == kPANEL ) 									// avoid error when panel does not yet exist (e.g. PnPuls when loading script at startup)
		// 1. Set the underlying variable 
		nvar		bVisib  = $ReplaceString( "_", sCtrlName, ":" )				// the underlying button variable name is derived from the control name
		bVisib		   = bState	
		// 2. Change the button's appearance accordingly
		string  	lstTitles 	= GetUserData( 		sWin,  sCtrlName,  "titles" )		// get UD titles
		string  	sTitle		= StringFromList( bState, lstTitles, ksTILDE_SEP )
		Button	$sCtrlName, win = $sWin,	title	= sTitle 
		string  	lstColors 	= GetUserData( 		sWin,  sCtrlName,  "colors" )	// get UD colors
		string  	sOneColor	= StringFromList( bState, lstColors, ksTILDE_SEP )
		if ( strlen( sOneColor ) ) 
			Button  $sCtrlName, win = $sWin, fcolor = ( str2num( StringFromList( 0, sOneColor, "," ) ), str2num( StringFromList( 1, sOneColor, "," ) ), str2num( StringFromList( 2, sOneColor, "," ) ) )	//  colored 
		endif
		// printf "\t\t\tTurnButton  \t%s\t%s\t%d\t ? \t%d\t%d\t%s\t%s\t  \r", pd(sPanelNm,11),  pd(sControlNm,27),  WinType( sPanelNm ), kPANEL, bState, sTitle, sOneColor
	endif
End

Function		EnableButton( sPanelNm, sControlNm, EnableDisable )
	string		sPanelNm, sControlNm							// e.g. 'Secu' ,  'root_uf_secu_buNew0000'
	variable	EnableDisable
	// printf "\t\t  panel   enable/kDISABLE button  \t%s\t%s\t%d\t ? \t%d\t%d  \r", pd(sPanelNm,11),  pd(sControlNm,27),  WinType( sPanelNm ), kPANEL, EnableDisable
	if ( WinType( sPanelNm ) == kPANEL ) 			// avoid error when panel does not yet exist (e.g. PnPuls when loading script at startup)
		Button	$sControlNm	win = $sPanelNm,	disable = EnableDisable	// kENABLE = 0, kDISABLE = 2
	endif
End

//Function		EnableButtn( sPanelNm, sControlNm, EnableDisable )
//	string		sPanelNm, sControlNm
//	variable	EnableDisable
//	// print "\t\tpanel   enable/kDISABLE button",  pd(sPanelNm,11),  pd(sControlNm,27), WinType( sPanelNm ),"?", kPANEL, EnableDisable
//	if ( WinType( sPanelNm ) == kPANEL ) 			// avoid error when panel does not yet exist (e.g. PnPuls when loading script at startup)
//		Button	$sControlNm	win = $sPanelNm,	disable = !EnableDisable*2	// kENABLE = 0, kDISABLE = 2
//	endif
//End

Function		EnableChkbox( sPanelNm, sControlNm, EnableDisable )
	string		sPanelNm, sControlNm
	variable	EnableDisable
	// print "\t\tpanel  enable/kDISABLE  chkbox",  pd(sPanelNm,11),  pd(sControlNm,27),  WinType( sPanelNm ),"=?=", kPANEL, EnableDisable
	if ( WinType( sPanelNm ) == kPANEL ) 			// avoid error when panel does not yet exist (e.g. PnPuls when loading script at startup)
		Checkbox	$sControlNm	win = $sPanelNm,	disable = EnableDisable
	endif
End

Function		EnableSetVar( sPanelNm, sControlNm, EnableDisable )
	string		sPanelNm, sControlNm
	variable	EnableDisable
	 // print "\t\tpanel  enable/kDISABLE  SetVariable",  pd(sPanelNm,11),  pd(sControlNm,27), WinType( sPanelNm ),"?", kPANEL, EnableDisable
	if ( WinType( sPanelNm ) == kPANEL ) 			// avoid error when panel does not yet exist (e.g. PnPuls when loading script at startup)
		if ( EnableDisable == kNOEDIT_SV )
			SetVariable  $sControlNm	win = $sPanelNm,	disable = 0,			noedit = 1				// pass kNOEDIT_SV=3 : display the control but do not let the user change the value
			// SetVariable  $sControlNm	win = $sPanelNm,	frame   = 0									// no white box so the user does not even attempt to edit the value but readability is bad
		else
			SetVariable  $sControlNm	win = $sPanelNm,	disable = !EnableDisable,	noedit = !EnableDisable	// pass 1 : enable and allow editing;  pass 0 : disable and no editing
		endif
	endif
End

Function		EnablePopup( sPanelNm, sControlNm, EnableDisable )
	string		sPanelNm, sControlNm
	variable	EnableDisable
	// print "\t\tpanel   enable/kDISABLE popup",  pd(psPanelNm,11),  pd(sControlNm,27), WinType( sPanelNm ),"?", kPANEL, EnableDisable
	if ( WinType( sPanelNm ) == kPANEL ) 			// avoid error when panel does not yet exist (e.g. PnPuls when loading script at startup)
		PopupMenu	$sControlNm	win = $sPanelNm,	disable = EnableDisable	// kENABLE = 0, kDISABLE = 2
	endif
End

//===========================================================================================================================================

Static Function		stFolderGetV( sF,  sGlobalName, DefaultValue )
// returns contents of global variable, when the variable name and folder are passed as strings 
// if the variable does not yet exist, it will be created and set to the 'DefaultValue' 
	string 		sF, sGlobalName
	variable		DefaultValue
	nvar		/Z	gValue = $( sF + sGlobalName )
	return  nvar_exists( gValue ) ? gValue :  stFolderSetV( sF, sGlobalName, DefaultValue )	
End

Static Function  		stFolderSetV( sF, sNameofGlobalNumber, Value )
// constructs global variable with name 'sNameofGlobalNumber'  in folder 'sF' , sets it to Value, returns value
	string 		sF, sNameofGlobalNumber
	variable		Value							 
	variable	/G	$( sF + sNameofGlobalNumber ) = Value	 
	return		Value								// this redundant line makes the corresponding FolderGetV() function shorter
End
