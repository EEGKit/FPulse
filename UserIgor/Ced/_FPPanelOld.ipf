//
// FPPANEL.IPF 
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




strconstant		ksSEP_TBCO		= "$"				// Separates tabcontrols in panels
strconstant		ksSEP_TAB		= "°"				// Separates the tabs in a tabcontrol e.g. 'Adc0°Adc2'.  Using ^ is allowed. Do NOT use characters used in titles e.g. , .  ( ) [ ] =  .  Neither use Tilde '~' (is main sep) , colon ':' (is path sep)   or   '|'  (also used elsewhere) .
strconstant		ksSEP_CTRL		= "|"				// Separates controls in tabcontrols in panels
strconstant		ksSEP_STD		= ","				// standard separator
strconstant		ksSEP_WPN		= ":"				// Separator the specifying items of a control in a 'wPn' line 
strconstant		ksSEP_COMMONINIT= "~"			// Separates specific initialisation values from the common value which is applicable for the rest e.g. "0000_7;0001_1.5;~2.3"	


constant		kTYPE=0, kNXLN=1, kXPOS=2, kMXPO=3, kOVS=4, kTABS=5, kBLKS=6, 	kMODE=7,  kNAME=8,  kROWTI=9,   kCOLTI=10,  kACTPROC=11,  kXBODYSZ=12, kFORMENTRY=13, kINITVAL=14, kVISIB=15,  kHELPSUB=16

constant		kSEP = 0,  kCB = 1,  kRAD = 2,  kSV = 3,  kPM = 4,  kBU = 5,  kSTR = 6  
strconstant	lstTYPE ="SEP;CB;RAD;SV;PM;BU;STR;"

//constant		kPN_INIT	= 1 ,  kPN_DRAW = 2
constant		kPANEL_INIT	= 1 ,  kPANEL_DRAW = 2


//=============================================================================================================
//  4dim dialog functions  	
//constant		kRIGHT = 0,  kLEFT = 1,  kBOTTOM = 0,  kTOP = 1
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
	yT	= kMAGIC_Y_OFFSET_PIXEL +	yOfs	+ ( bTop	?	0		:	GetIgorAppPixelY()  - 	kMAGIC_Y_MISSING_PIXEL - ySize	)
	yB	= kMAGIC_Y_OFFSET_PIXEL +	yOfs	+ ( bTop	?	ySize		:	GetIgorAppPixelY()  -	kMAGIC_Y_MISSING_PIXEL	)
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
	// GetWindow 	    $sWin , wsize		// Extract previous window position and size. Keep only position and discard size as the size may have changed in the meantime due to more or less columns or rows.
	// MoveWindow /W=$sWin	V_Left ,  V_top , V_Left +  xSize * kIGOR_POINTS72/screenresolution ,  V_top + ySize * kIGOR_POINTS72/screenresolution

	// Version2: Will move panel top left corner so that no part of the panel will be positioned off-screen if panel size increases
	GetWindow 	    $sWin , wsize		// Extract previous window position and size. Keep only position and discard size as the size may have changed in the meantime due to more or less columns or rows.
	xL		= V_Left	/ Pix2Pts
	xR		= V_Left	/ Pix2Pts + xSize
	yT		= V_Top	/ Pix2Pts
	yB		= V_Top	/ Pix2Pts + ySize 
	xRmax	= 						xOfs	+ ( bLeft	?	xSize		:	GetIgorAppPixelX()  - 		4 )
	yBmax	= kMAGIC_Y_OFFSET_PIXEL +	yOfs	+ ( bTop	?	ySize		:	GetIgorAppPixelY()  -	kMAGIC_Y_MISSING_PIXEL	)
	if ( xR > xRmax )
		xL	= 						xOfs	+ ( bLeft	?	0		:	GetIgorAppPixelX()  -	xSize - 4 )	
		xR	= 						xOfs	+ ( bLeft	?	xSize		:	GetIgorAppPixelX()  - 		4 )
	elseif ( yB > yBmax )
		yT	= kMAGIC_Y_OFFSET_PIXEL +	yOfs	+ ( bTop	?	0		:	GetIgorAppPixelY()  - 	kMAGIC_Y_MISSING_PIXEL - ySize	)
		yB	= kMAGIC_Y_OFFSET_PIXEL +	yOfs	+ ( bTop	?	ySize		:	GetIgorAppPixelY()  -	kMAGIC_Y_MISSING_PIXEL	)
	endif
	MoveWindow /W=$sWin	xL  * Pix2pts,  yT * Pix2pts,  xR * Pix2pts,  yB * Pix2pts
End	
	
	 
Function		Panel3Main( sWin, sPnTitle, sF, xPos, yPos )
// Builds and updates the main panels (e.g. FPulse, FEval ) . Checks whether panel exists already or not. The Panel window creation macro and the window itself have the same name
// Properties of the main panels:
// permanent, can not and should not be closed, can not and should not be minimised, are initialised and built in 1 step, often need recomputing/resizing/redrawing when e.g. the number of regions or fits changes  
	string  	sWin, sPnTitle, sF
	variable	xPos, yPos												// panel position in %
	variable	xLoc, xLocMax, yLoc, yLocMax									// panel position in pixel
	
	string		sPnWvNm = sF + sWin
	variable	xSize, ySize												// panel size
	string  	lstPosX 	= "", lstPosY 	= ""									// where the controls will be positioned. Index is control number.
	string  	lstTabGrp	= "", lstTabcoBeg= "", lstTabcoEnd	= ""					// where the tab frames will be positioned. These lists are indexed by TabGrp (including pseudo-tabs (end=-1) for which no tab frame is drawn)
	string  	llstTypes	= "", 	llstCNames	= ""
	string 	lllstTabTi	= "",  llstBlkTi	= "", lllstRowTi	= "", lllstColTi	= "", lllstVisibility = "", llstMode	= ""	
	variable	pt2pix	= screenresolution / kIGOR_POINTS72
	// Killing the whole panel is not necessary and should be avoided as it makes the screen flicker. It is sufficient to update the tabs and the 'Regions' panel area (either adjust size or just clear/fill this area).
	if ( WinType( sWin ) != kPANEL )										// only if the panel does not yet  exist ..

		NewPanel /W=( 5000, -20, 5100, 10 ) /K= 2 /N=$sWin  as  sPnTitle			// K=2 prevents closing. We build a preliminary panel (very small and off-screen) so that 'PnInitVars()' can construct the globals and the controls. Different approach: 1.check in'PnInitVars' existance of controls  2.pass parameter 'bDoBuildControl'
		PnInitVars( sF, sWin, $sPnWvNm )
		PnSize( sF, sWin, $sPnWvNm, xSize, ySize, lstPosX, lstPosY, lstTabGrp, lstTabcoBeg, lstTabcoEnd, llstTypes, llstCNames, lllstTabTi, llstBlkTi, lllstRowTi, lllstColTi, lllstVisibility, llstMode )	// most parameters are references 
		xLocMax	= GetIgorAppPixelX() -  Xsize - 4							// the rightmost panel position 
		xLoc 	= min( max( 0, XLocMax * xPos / 100 ), xLocMax )
		yLocMax 	= GetIgorAppPixelY() -  ySize - kY_MISSING_PIXEL_BOT		// the lowest panel position			// todo ???? ysize pixel
		yLoc	 	= kY_MISSING_PIXEL_TOP + min( max( 0, YLocMax * yPos / 100 ), YLocMax )

		MoveWindow /W = $sWin  xLoc / pt2pix,   yLoc / pt2pix,    (xLoc + xSize) / pt2pix, (yLoc + ySize) / pt2pix 	// now resize the preliminary panel to the correct position and size
		PnDraw( sF, sWin, sPnTitle, $sPnWvNm, xSize, ySize, lstPosX, lstPosY, lstTabGrp, lstTabcoBeg, lstTabcoEnd, llstTypes, llstCNames, lllstTabTi,  llstBlkTi, lllstRowTi, lllstColTi, lllstVisibility, llstMode )	// reconstruct the panel at it's previous position	
	else															// only if the panel does already  exist then ignore the passed position..
		PnInitVars( sF, sWin, $sPnWvNm )								// when increasing the number of blocks( e.g. =regions) or when loading another setting then create the additionally required controls (and their underlying variables) 
		PnSize( sF, sWin, $sPnWvNm, xSize, ySize, lstPosX, lstPosY, lstTabGrp, lstTabcoBeg, lstTabcoEnd, llstTypes, llstCNames, lllstTabTi, llstBlkTi, lllstRowTi, lllstColTi, lllstVisibility, llstMode )	// most parameters are references 
		GetWindow     $sWin , wsize									// ...but get its current position		
		// printf "\t\tPanel3Main  Update\t%s    left:%4d  \t(>%.0lf) \t>%.1lf\t\ttop :%d \t(>%.0lf) \t->y %.1lf \r", sWin, V_left, V_left * screenresolution / kIGOR_POINTS72,  V_right * screenresolution / kIGOR_POINTS72*100/GetIgorAppPixelX(),  V_top, V_top * screenresolution / kIGOR_POINTS72, V_bottom * screenresolution / kIGOR_POINTS72*100/GetIgorAppPixelY()
		MoveWindow /W = $sWin V_left, V_top, V_left + xSize / pt2pix,  V_top + ySize / pt2pix 
		PnDraw( sF, sWin, sPnTitle, $sPnWvNm, xSize, ySize, lstPosX, lstPosY, lstTabGrp, lstTabcoBeg, lstTabcoEnd, llstTypes, llstCNames, lllstTabTi,  llstBlkTi, lllstRowTi, lllstColTi, lllstVisibility, llstMode )	// reconstruct the panel at it's previous position	
		ControlUpdate /A /W = $sWin									// avoid that popupmenu and setvariable 'hangs' (=stays hidden)  until some next user action
	endif
End


Function		Panel3SubHide( sWinName )
	string  	sWinName
	MoveWindow /W = $sWinName  0, 0, 0, 0 						// minimise the panel to an icon
End


Function		Panel3Sub( sWin, sPnTitle, sF, xPos, yPos, nMode )
// Builds and updates the sub panels (e.g. Misc, DispStimulus, ...) . Checks whether panel exists already or not. The Panel window creation macro and the window itself have the same name
// Properties of the sub panels:
// can be minimised, can not really be closed but are minimised instead, are initialised and built in 2 different steps, should remember their posistion when closed/minimised.  Up till now they don't need recomputing/resizing/redrawing....
	string  	sWin, sPnTitle, sF
	variable	nMode			// nMode = kPN_INIT 	: build a preliminary panel (very small and off-screen=hidden) just to construct the underlying controls and global variables which might be needed even if the panel is never displayed. 
							// nMode = kPN_DRAW	: build the panel and the underlying controls and global variables and display the panel 
	variable	xPos, yPos												// panel position in %
	variable	xLoc, xLocMax, yLoc, yLocMax									// panel position in pixel
	
	string		sPnWvNm = sF + sWin
	variable	xSize, ySize												// panel size
	string  	lstPosX 	= "", lstPosY 	= ""									// where the controls will be positioned. Index is control number.
	string  	lstTabGrp	= "", lstTabcoBeg= "", lstTabcoEnd	= ""					// where the tab frames will be positioned. These lists are indexed by TabGrp (including pseudo-tabs (end=-1) for which no tab frame is drawn)
	string  	llstTypes	= "", 	llstCNames	= ""
	string 	lllstTabTi	= "",  llstBlkTi	= "", lllstRowTi	= "", lllstColTi	= "", lllstVisibility = "", llstMode	= ""	
	variable	pt2pix	= screenresolution / kIGOR_POINTS72
	variable	hidden	= TRUE

	// If the panel does not yet  exist  or if  invisible 'Initialising'  is specified..
	if ( WinType( sWin ) != kPANEL  ||   nMode & kPN_INIT  )	
		// NewPanel /W=( 300+RandomInt(0,80),40+RandomInt(0,80), 400, 200 ) /K= 2 /N=$sWin  as  sPnTitle	// K=2 prevents closing. We build a nearly invisible panel (very small and mostly off-screen) so that 'PnInitVars()' can construct the globals and the controls.
		//NewPanel /W=( 5000, -20, 5100, 10 ) /K= 2 /N=$sWin  as  sPnTitle			// K=2 prevents closing. We build a nearly invisible panel (very small and mostly off-screen) so that 'PnInitVars()' can construct the globals and the controls. Different approach: 1.check in'PnInitVars' existance of controls  2.pass parameter 'bDoBuildControl'
		NewPanel /W=( 5000, -20, 5100, 10 ) /K= 2 /N=$sWin  as  sPnTitle			// K=1 allows closing. We build a nearly invisible panel (very small and mostly off-screen) so that 'PnInitVars()' can construct the globals and the controls. Different approach: 1.check in'PnInitVars' existance of controls  2.pass parameter 'bDoBuildControl'
		// NewPanel /W=( 0, 2000, 30, 30 ) /K= 1 /N=$sWin  as  sPnTitle			// we build a nearly invisible panel (very small and mostly off-screen) so that 'PnInitVars()' can construct the globals and the controls. Different approach: 1.check in'PnInitVars' existance of controls  2.pass parameter 'bDoBuildControl'
		PnInitVars( sF, sWin, $sPnWvNm )
			
		PnSize( sF, sWin, $sPnWvNm, xSize, ySize, lstPosX, lstPosY, lstTabGrp, lstTabcoBeg, lstTabcoEnd, llstTypes, llstCNames, lllstTabTi, llstBlkTi, lllstRowTi, lllstColTi, lllstVisibility, llstMode )	// most parameters are references 
		xLocMax	= GetIgorAppPixelX() -  Xsize - 4							// the rightmost panel position 
		xLoc 	= min( max( 0, XLocMax * xPos / 100 ), xLocMax )
		yLocMax 	= GetIgorAppPixelY() -  ySize - kY_MISSING_PIXEL_BOT		// the lowest panel position			// todo ???? ysize pixel
		yLoc	 	= kY_MISSING_PIXEL_TOP + min( max( 0, YLocMax * yPos / 100 ), YLocMax )
		// printf "\t\tPanel3Sub( mode: %d ) \t[Init:%d, Draw:%d]  \t Mode was INIT or non-existant\tPanel  '%s' .\tSetting  \tHidden:%2d \txLoc:%3d \tyLoc:%3d\t \r", nMode, kPN_INIT, kPN_DRAW, sWin , hidden, xLoc, yLoc 
		ModifyPanel  /W=$sWin  fixedSize = 1							// the user cannot change the size, but closing and minimising cannot be prevented in this way
		MoveWindow /W = $sWin  xLoc / pt2pix,   yLoc / pt2pix,    (xLoc + xSize) / pt2pix, (yLoc + ySize) / pt2pix 	// now resize the preliminary panel to the correct position and size
		PnDraw( sF, sWin, sPnTitle, $sPnWvNm, xSize, ySize, lstPosX, lstPosY, lstTabGrp, lstTabcoBeg, lstTabcoEnd, llstTypes, llstCNames, lllstTabTi,  llstBlkTi, lllstRowTi, lllstColTi, lllstVisibility, llstMode )// construct the panel controls
		MoveWindow 	/W=$sWin  0 , 0 , 0 , 0							// hide the window by minimising it to an icon
	endif
	if (  nMode & kPN_DRAW )											// Now the panel exists.  Check if  ( also )  visible drawing is required.
		 printf "\t\tPanel3Sub( mode: %d ) \t[Init:%d, Draw:%d]  \t Mode was DRAW : Drawing   \tPanel  '%s'  .\tRetrieving \tHidden:%2d \txLoc:%3d \tyLoc:%3d\t \r", nMode, kPN_INIT, kPN_DRAW, sWin , hidden, xLoc, yLoc
		MoveWindow 	/W=$sWin  1 , 1 , 1 , 1							// restore the icon to original window size
//		ControlUpdate /A /W = $sWin									// avoid that popupmenu and setvariable 'hangs' (=stays hidden)  until some next user action
	endif
End

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

static Function		PnCreateTabcoVars( sFsPnWndNm, nTabco )
// Creates underlying shadow variables for  the tabcontrols needed for initialising the tabs as selected by the user
	string  	sFsPnWndNm										// the data folder for the variable  and  the panel name
	variable	nTabco											// the index of the Tabcontrol, not the tab
	string		sDFSave	= GetDataFolder( 1 )							// The following functions do NOT restore the CDF so we remember the CDF in a string .
	string  	sFoTabcoNmIdx  = PnBuildFoTabcoNm( sFsPnWndNm, nTabco )
	nvar	/Z var	= $sFoTabcoNmIdx
	if ( ! nvar_Exists( var ) )
 		variable /G  $sFoTabcoNmIdx
	endif	
	// printf "\t\tPnCreateTabcoVars(    \t%s\t\t\t\t\t\t\t) \tconstructing (len:%3d):\tvar_tab :\t%s\t  \r", pd( sFsPnWndNm,24), strlen(sFoTabcoNmIdx)  ,  pd(sFoTabcoNmIdx,27)
	SetDataFolder sDFSave					// Restore CDF from the string  value
End

static Function		PnTabcoIndex( sFsPnWndNm, nTabco )
// Returns currently selected tab 
	string  	sFsPnWndNm										// the data folder for the variable  and  the panel name
	variable	nTabco											// the index of the Tabcontrol, not the tab
	string  	sFoTabcoNmIdx  = PnBuildFoTabcoNm( sFsPnWndNm, nTabco )
	nvar		TabIdx	= $sFoTabcoNmIdx
	// printf "\t\tPnTabcoIndex( \t%s\t %d ) ->\t%s\t =\tTabidx:%2d\t \r", sFsPnWndNm, nTabco, sFoTabcoNmIdx, TabIdx
	return	TabIdx
End

static Function		PnTabcoIndexSet( sFsPnWndNm, nTabco, nTab )
// Sets currently selected tab 
	string  	sFsPnWndNm										// the data folder for the variable  and  the panel name
	variable	nTabco, nTab										// the index of the Tabcontrol   and  the tab
	string  	sFoTabcoNmIdx  = PnBuildFoTabcoNm( sFsPnWndNm, nTabco )
	nvar		TabIdx	= $sFoTabcoNmIdx
	TabIdx	= nTab
	// printf "\t\tPnTabcoIndexSet( \t%s\t %d  %d ) ->setting  \t%s\t =\tTabidx:%2d\t \r", sFsPnWndNm, nTabco, nTab, sFoTabcoNmIdx, TabIdx
End

static Function		PnCreateControls( nType, sF, sWin, sNm, lstTabTi, lstBlkTi, lstRowTi, lstColTi, lstInitVal, lstVisibility )
// Creates underlying shadow variables for   checkboxes,  radio buttons and popmenus. Set them with initial values.  Draw the controls.
	variable	nType
	string  	sF, sWin, sNm							// the variable base name without indices
	string  	lstTabTi, lstBlkTi, lstRowTi, lstColTi, lstInitVal
	string		lstVisibility								//  050805 each control stores itself its initial visibility as 'UserData'  
	string  	sFsSub	= sF + sWin
	variable	nTab, nBlk, nRow, nCol					// the number of entries in each dimension
	variable	nTabs	= TabCnt( lstTabTi )
	string  	sCNm
	variable	len, bVisib
	variable	nCreated	= 0
	// printf "\t\t\tPnCreateControls( %s\t%s\t )\t%s\t%s\t%s\t%s\t%s\tvis:%s\t  \r", pd( sFsSub,15),  pd( sNm,9), pd(lstInitVal,32), pd(lstTabTi,18), pd(lstBlkTi, 18), pd( lstRowTi,18), pd( lstColTi,18) , lstVisibility[0,100]
	variable    mxTabs = max(  nTabs, 1 )		// Even if there are no tabs (TabCnt( lstTabTi )=0)  there are still controls which must be drawn so the inner loop is at least executed once
	for ( nTab = 0; nTab <  mxTabs; nTab += 1 )
		for ( nBlk = 0; nBlk < BlkCnt( lstBlkTi, nTab ); nBlk += 1 )
			for ( nRow = 0; nRow <  RowCnt( lstRowTi ); nRow += 1 )
				for ( nCol = 0; nCol < ColCnt( lstColTi ); nCol += 1 )
					
					string    sVarNmIdx	= PnBuildVNmIdx( sNm, nTab, nBlk, nRow, nCol )// can be the name of a variable or of a string
					bVisib			= InitValue( sVarNmIdx, lstVisibility, 1 )			// If initialisation values have been specified  in  'wPn[]' then use them , if not use the last parameter as default

					if ( nType == kSTR )										// only  for  SetVariable  in string mode 
						string    sFoVarNmIdxS = sFsSub + ":" + sVarNmIdx			// cannot use 'sFoVarNmIdx' also for a string
						len	= strlen(sFoVarNmIdxS)  
						svar	   /Z str	= $sFoVarNmIdxS
						if ( ! svar_exists( str ) )
					 		string   /G     	   $sFoVarNmIdxS
							svar		str    	= $sFoVarNmIdxS

						// 050805 DOES an InitValue make sense for an INPUT STRING ????  Remove this code  OR allow   string initialisations .  TODO ...........
							sCNm		= ReplaceString( ":", sFoVarNmIdxS, "_" )	//  e.g.  root:uf:eva:evl:svVar000  ->  root_uf_eva_evl_svVar000
							variable strIdx	= InitValue( sVarNmIdx, lstInitVal, 1 )		// If initialisation values have been specified  in  'wPn[]' then use them , if not use the last parameter as default
							SetVariable  $sCNm,	win = $sWin,	value = strIdx
							SetVariable  $sCNm,	win = $sWin, Userdata( bVisib ) = num2str( bVisib )//  050805 each control stores itself its initial visibility as 'UserData'  	
						//........//
						
							nCreated	+= 1
							// printf "\t\t\tPnCreateControls( %s\t%s\t) %2d\t%s\t%s:\t\tvi:%d\t%s\t%s\t%s\t%s\t??? Sets to %d ???  \r", pd( sFsSub,15),  pd( sNm,9),  len, "NEW S", pd(sFoVarNmIdxS,29) , bVisib,  pd(lstTabTi,18), pd(lstBlkTi, 18), pd( lstRowTi,18), pd( lstColTi,18) , strIdx
						else
							 // printf "\t\t\tPnCreateControls( %s\t%s\t) %2d\t%s\t%s:\t\tvi:%d\t%s\t%s\t%s\t%s\t  \r", pd( sFsSub,15),  pd( sNm,9),  len, "       S", pd(sFoVarNmIdxS,29) , bVisib,  pd(lstTabTi,18), pd(lstBlkTi, 18), pd( lstRowTi,18), pd( lstColTi,18)   
						endif
					else
						string    sFoVarNmIdx	= sFsSub + ":" + sVarNmIdx
						len	= strlen(sFoVarNmIdx)  
						nvar	     /Z var	= $sFoVarNmIdx
						if ( ! nvar_exists( var ) )
					 		variable /G	   $sFoVarNmIdx
							nvar		 var	= $sFoVarNmIdx
							sCNm	= ReplaceString( ":", sFoVarNmIdx, "_" )		//  e.g.  root:uf:eva:evl:pmVar000  ->  root_uf_eva_evl_pmVar000
							if ( nType == kSV )										
								var 	= InitValue( sVarNmIdx, lstInitVal, 0 )				// If initialisation values have been specified  in  'wPn[]' then use them , if not use the default value of 0
								SetVariable  $sCNm,	win = $sWin,	value = var
								SetVariable  $sCNm,	win = $sWin, Userdata( bVisib ) = num2str( bVisib )	
							endif	
							if ( nType == kPM )									// the default value of 0 (appropriate for other controls) would set a POPUPMENU to a locked state effectively disabling any input 
								var 	= InitValue( sVarNmIdx, lstInitVal, 1 )				// If initialisation values have been specified  in  'wPn[]' then use them , if not use the first (=topmost) list entry having the index 1
								PopupMenu $sCNm,	win = $sWin,	mode = var
								PopupMenu $sCNm,	win = $sWin, Userdata( bVisib ) = num2str( bVisib )	
							endif	
							if ( nType == kCB )										
								var 	= InitValue( sVarNmIdx, lstInitVal, 0 )				// If initialisation values have been specified  in  'wPn[]' then use them , if not use the last parameter as default
								Checkbox	  $sCNm,	win = $sWin,	value = var
								Checkbox	  $sCNm,	win = $sWin, Userdata( bVisib ) = num2str( bVisib )	
							endif	

							if ( nType == kRAD )													// Radio buttons :  This can  be horizontal, vertical  or 2-dim arrays of radio buttons
								var 					     = InitValue( sVarNmIdx, lstInitVal, 0 )			// If initialisation values have been specified  in  'wPn[]' then use them , if not use the last parameter as default
								if ( var == 1 )													// This  Tab/Blk/Row/Col-combination  specifies the one radio button to be initalised with the 'ON' state, so we compute the linear index.
									string		sFoRadVar     = RemoveEnding( RemoveEnding( sFoVarNmIdx ) )	// We also must create the ONE and ONLY global variable for the radio button group by stripping the last 2 indices...
									variable	nInitLinIdx 	     = LinRadioButtonIndex3( nTab, nBlk, nRow, nCol, lstTabTi, lstBlkTi, lstRowTi, lstColTi )
									variable /G $sFoRadVar = nInitLinIdx								// ... and store the state of radio button group in this ONE global linear index variable which must match nBlk/NRow/nCol
									// printf "\t\t\tPnCreateControls( %s\t%s\t) %2d\t%s\t%s:\t%g\tvi:%d\t%s\t%s\t%s\t%s\t-> %s:%2d <-LinIdx  \r", pd( sFsSub,15),  pd( sNm,9),  len, "new Ra", pd(sFoVarNmIdx,29) , var, bVisib, pd(lstTabTi,8), pd(lstBlkTi, 8), pd( lstRowTi,18), pd( lstColTi,18) , sFoRadVar, nInitLinIdx
								endif
							endif	

							nCreated	+= 1
							
							// printf "\t\t\tPnCreateControls( %s\t%s\t) %2d\t%s\t%s:\t%g\tvi:%d\t%s\t%s\t%s\t%s\t  \r", pd( sFsSub,15),  pd( sNm,9),  len, "new V", pd(sFoVarNmIdx,29) , var, bVisib, pd(lstTabTi,18), pd(lstBlkTi, 18), pd( lstRowTi,18), pd( lstColTi,18)   
						else
							 // printf "\t\t\tPnCreateControls( %s\t%s\t) %2d\t%s\t%s:\t%g\tvi:%d\t%s\t%s\t%s\t%s\t  \r", pd( sFsSub,15),  pd( sNm,9),  len, "       V", pd(sFoVarNmIdx,29) , var, bVisib,  pd(lstTabTi,18), pd(lstBlkTi, 18), pd( lstRowTi,18), pd( lstColTi,18)   
						endif
					endif
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

static Function		PnInitVars( sF, sWin, wPn )
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

		lstTabTi	= PossiblyConvertTitleFuncToList( sName, sF, sWin, lstTabTi )				// List of  tab 	 title lists no matter whether we had a function returning the titles or a direct list
		lstBlkTi	= PossiblyConvertTitleFuncToList( sName, sF, sWin, lstBlkTi )				// List of  block	 title lists no matter whether we had a function returning the titles or a direct list
		lstRowTi	= PossiblyConvertTitleFuncToList( sName, sF, sWin, lstRowTi )			// List of  row	 title lists no matter whether we had a function returning the titles or a direct list
		lstColTi	= PossiblyConvertTitleFuncToList( sName, sF, sWin,  lstColTi )				// List of column title lists no matter whether we had a function returning the titles or a direct list
		lstInitVal	= PossiblyConvertTitleFuncToList( sName, sF, sWin, lstInitVal )			// List of initialisation values no matter whether we had a function returning the values or a direct list
		lstVisibility	= PossiblyConvertTitleFuncToList( sName, sF, sWin, lstVisibility )			// List of visibilities no matter whether we had a function returning the values or a direct list
		// printf "\t\tPnInitVars( \t\t\t\t'%s %s\t%s\t%s\t%s\t%s\t%s\tIV:%s\tVis:%s\t \r",  sF,  pd( sWin,13),   pd( sName,19),  pd(lstTabTi,18), pd(lstBlkTi, 18), pd( lstRowTi,18), pd( lstColTi,18) , lstInitVal, lstVisibility
		nCreated	+= PnCreateControls( nType, sF, sWin, sName, lstTabTi, lstBlkTi, lstRowTi, lstColTi, lstInitVal, lstVisibility )		
	endfor
	// printf "\t\t\tPnInitVars( \t%s\t%s\t) \thas created controls: %3d  \r", pd( sF,15),  pd( sWin,15) , nCreated
End



//===========================================================================================================================================================
//  HELP  ( perhaps -> FP_HELP.ipf ??)

 Function	/S	PnTESTAllTitlesOrHelptopics( sF, sWin )
//  DEBUG FUNCTION New style panel. printing all control titles into the history area. This text can then be cut and pasted into the help file. This ensures that all controls have a HelpTopic.
// e.g.  execute from the command line   PnTESTAllTitlesOrHelptopics( "root:uf:eva:", "de" )    or  PnTESTAllTitlesOrHelptopics( "root:uf:eva:", "set" )   or    PnTESTAllTitlesOrHelptopics( "root:uf:acq:", "mis" ) 
// e.g.  execute from the command line   PnTESTAllTitlesOrHelptopics( "root:uf:eva:", "sde" )   or  PnTESTAllTitlesOrHelptopics( "root:uf:acq:", "sda" )   or    PnTESTAllTitlesOrHelptopics( "root:uf:" , "rec" )
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
			lstRowTi		= PossiblyConvertTitleFuncToList( sName, sF, sWin, lstRowTi )				// List of  row	 title lists no matter whether we had a function returning the titles or a direct list
			lstColTi		= PossiblyConvertTitleFuncToList( sName, sF, sWin, lstColTi )				// List of column title lists no matter whether we had a function returning the titles or a direct list
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


static strconstant  	ksTOPIC_MARKER		= "\r•\t"						// Igors Topic convention assumes the bullet character followed by a tabulator.  The leading CR is not necessarily required in all help files but in mine I use it to make Topic detection more reliable

Function		SaveHelp( sNB, sHelpPathFile )
	string  	sNB, sHelpPathFile										// the help file is assumed to reside in the same directory as the Igor Procedure Files e.g. 'C:UserIgor:SecuTest:SecuTest_Help.ihf'
	if (  WinType( sNB ) == kNOTEBOOK )								// Only if the Notebook window does exist.. 
		SaveNotebook /S=2 /O 	$sNB  	as sHelpPathFile 				// e.g. 'C:UserIgor:SecuTest:SecuTest_Help.ihf'
	endif
End

Function		EditHelp( sBaseFolder, sNB, sHelpPathFile, sPanel, sMainTopic, sSubtopicMarker )
	string  	sBaseFolder, sNB, sHelpPathFile										// the help file is assumed to reside in the same directory as the Igor Procedure Files e.g. 'C:UserIgor:Ced:FPulseHelp.ihf'
	string  	sPanel, sMainTopic, sSubtopicMarker

	if (  WinType( sNB ) != kNOTEBOOK )									// Only if the Notebook window does not  exist.. 

		if ( FileExists( sHelpPathFile ) )									// ...check if the notebook file exists

			OpenNotebook /Z /K=1 	/N =	$sNB	as sHelpPathFile 	// try to open notebook quietly as the notebook file may exist as a non-editable compiled help file which we cannot use

			if ( V_Flag )											// there was an error although the notebook file exists, probably because the notebook exists as a non-editable compiled help file
				DoAlert 0, "You first must kill the Help window \r      '" + sHelpPathFile + "'\rby pressing [ALT + Close Button]. \rThen try 'Edit Help' again"

				// It would be more elegant but I don't know how to  switch  programmatically from the non-editable compiled help file to the  editable notebook file which I need 

				// todo:  make a backup of the help file just in case the user inadvertently deletes the help file instead of killing the help window
				return -1

			endif

		else														// notebook file does not exist
// works only in Igor6
			OpenNotebook /K=1 /N =	$sNB /P=Igor /T=".ifn" as 	":More Help Files:Igor Help File Template.ifn" 	// use Igors Template as a starting point only the first time before the NB has been saved
			SaveNotebook /S=2 /O 	$sNB  		as sHelpPathFile 	// e.g. 'C:UserIgor:SecuTest:SecuTest_Help.ihf'
		endif	

	endif
		
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
		if ( nPos != kNOTFOUND )											// eliminate again the last item which has NOT been correctly found
			sTopic	= StringFromList( 0, sAllText[ nPos+strlen(ksTOPIC_MARKER), inf ], "\r" )		// extract till end of line
			lstTopics	= AddListItem( sTopic, lstTopics, ";", inf )
			// printf "\t\t\tTopic: \tPos:\t%8d\tlen:\t%8d\t'%s' \r", nPos, len, sTopic
		endif
	while ( nPos != kNOTFOUND )
	printf "\t\tTopics:  \t\t\t%3d\t'%s...' \r", ItemsInList( lstTopics ), lstTopics[0,300]
	

	// Search for SubTopics in the help file.  As a workaround to be able to detect a SubTopic  I let the Subtopic line start with a  SubtopicMarker.  It would be easier and more elegant if I could detect a Subtopic as it is  without the need to use a marker
	string  	sSubTopic, lstSubTopics	= ""
	nPos		= -1
	do
		nPos 	+= 1
		nPos	= strsearch( 	sAllText, sSubtopicMarker, nPos )
		if ( nPos != kNOTFOUND )									// eliminate again the last item which has NOT been correctly found
			sSubTopic		= StringFromList( 0, sAllText[ nPos+strlen( sSubtopicMarker), inf ], "\r" )		// extract till end of line
			lstSubTopics	= AddListItem( sSubTopic, lstSubTopics, ";", inf )
			// printf "\t\t\tSubTopic:\tPos:\t%8d\tlen:\t%8d\t'%s' \r", nPos, len, sSubTopic
		endif
	while ( nPos != kNOTFOUND )
	printf "\t\tSubTopics:  \t\t%3d\t'%s...' \r", ItemsInList( lstSubTopics ), lstSubTopics[0,300]


	// Add the one and only main topic  and  all subtopics (as found in the panel)  to the help file  if they are not yet contained in the help file.
	// Extract all potential subtopics from the panel.  As the user may select any of them for help each ot these should finally contain some help text.
	string  	lstHelpTopics	= PnTESTAllTitlesOrHelptopics( sBaseFolder, sPanel )
	variable	n, nHelpTopics	= ItemsInList( lstHelpTopics )
	string  	sHelpTopic

	Notebook	$sNB,  selection	= { endOfFile, endOfFile }		// Anything to be added will be appended  at the end of the notebook 

	// Possibly add the one and only main topic
	if ( WhichListItem( sMainTopic, lstTopics ) == kNOTFOUND )
		NBTopicAppend( sNB, sMainTopic )
	endif

	for ( n = 0; n < nHelpTopics; n += 1)
		sHelpTopic	= StringFromList( n, lstHelpTopics )

		// Tests formating by appending various topis and subtopics
		//	string  	sTopicBody	= "TopicBody"
		//	if ( mod(n,5) == 0 )
		//		NBTopicAppend( sNB, sHelpTopic )
		//	elseif ( mod(n,5) == 1 )
		//		NBSubTopicAppend( sNB, sHelpTopic, sSubtopicMarker )
		//	elseif ( mod(n,5) == 2 )
		//		NBTopicBody( sNB, sTopicBody )
		//	elseif ( mod(n,5) == 3 )
		//		NBSeeAlso( sNB, sHelpTopic )
		//	elseif ( mod(n,5) == 4 )
		//		NBRelatedTopics( sNB, sHelpTopic )
		//	endif

		if ( WhichListItem( sHelpTopic, lstSubTopics ) == kNOTFOUND )
			NBSubTopicAppend( sNB, sHelpTopic, sSubtopicMarker )		
		endif

	endfor

	string  	lstSubTopicOrphans	= RemoveFromList( lstHelpTopics, lstSubTopics )				// exist in help file but not in panel: 	Have probably been renamed....
	printf "\t\tSubTopicOrphans:\t%3d\t'%s...' \r", ItemsInList( lstSubTopicOrphans ), lstSubTopicOrphans[0,300]
	string  	lstSubTopicsMissing	= RemoveFromList( lstSubTopics, lstHelpTopics )				// exist in Panel but not yet in help file:	Add in Help file
	printf "\t\tSubTopicsMissing:\t%3d\t'%s...' \r", ItemsInList( lstSubTopicsMissing ), lstSubTopicsMissing[0,300]
	
End


// Note: Although the Igor documentation warns NOT to mix the 'ruler' keyword with other  keywords I found out that Mixing the keywords is the only way to make it work understandably and reliably..... 

static Function		NBTopicAppend( sNB, sText )
	string  	sNB, sText
	Notebook	$sNB, 	ruler	= TopicBody,	 textRGB = (0,0,0),	fStyle = 0, 	text	= "\r" 							// LEADING EMPTY TOPIC BODY line must not be edited, must stay empty as it is used as a Topic delimiter/marker
	Notebook	$sNB, 	ruler	= Topic,		 textRGB = (0,0,0),	fStyle = 0,  text = "•\t",  fStyle = 1+4,	text	= sText  + "\r"	// TOPIC: bullet, bold + underlined
	Notebook	$sNB, 	ruler	= TopicBody,	 textRGB = (0,0,0),	fStyle = 0, 	text	= "\r" 							// trailing empty TOPIC BODY line
End

static Function		NBSubTopicAppend( sNB, sText, sSubtopicMarker )
	string  	sNB, sText, sSubtopicMarker

	Notebook	$sNB, 	ruler	= TopicBody,	 textRGB = (0,0,0),	fStyle = 0, 	text	= "\r" 			// LEADING EMPTY TOPIC BODY line must not be edited, must stay empty as it is used as a Subtopic delimiter/marker
	// Workaround to be able to detect a SubTopic:  let the Subtopic line start with a  SubtopicMarker  (e.g. after the empty line a dot and a blank)

	// Notebook  $sNB, 	ruler	= Subtopic,	 textRGB = (0,0,0),   	fStyle = 0,  text = sSubtopicMarker, fStyle = 4,	  text	= sText + "\r" 	// SUBTOPIC: underlined
	Notebook  $sNB, 	ruler	= Subtopic,	 textRGB = (0,0,0),   	fStyle = 0,  text = sSubtopicMarker, fStyle = 1+4, text	= sText + "\r" 	// SUBTOPIC: bold and underlined
	Notebook	$sNB, 	ruler	= TopicBody,	 textRGB = (0,0,0),	fStyle = 0, 	text	= "help text" 		// trailing TOPIC BODY line is to be filled : here starts the help text

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

static Function		PnSize( sF, sWin, wPn, width, height, lstCtrlBlkPosX, lstCtrlBlkPosY, lstTabGrp, lstTabcoBeg, lstTabcoEnd, llstTypes, llstCNames, lllstTabTi, llstBlkTi, lllstRowTi, lllstColTi, lllstVisibility, llstMode  )
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
		lstVisibility	= ReplaceString( "\t", StringFromList( kVISIB,    wPn[ n ], ksSEP_WPN ) , "" )
		lstMode	= ReplaceString( "\t", StringFromList( kMODE,  wPn[ n ], ksSEP_WPN ) , "" )

		lstTabTi	= PossiblyConvertTitleFuncToList( sName, sF, sWin, lstTabTi )				// List of  tab 	 title lists no matter whether we had a function returning the titles or a direct list
		lstBlkTi	= PossiblyConvertTitleFuncToList( sName, sF, sWin, lstBlkTi )				// List of  block	 title lists no matter whether we had a function returning the titles or a direct list
		lstRowTi	= PossiblyConvertTitleFuncToList( sName, sF, sWin,  lstRowTi )			// List of  row	 title lists no matter whether we had a function returning the titles or a direct list
		lstColTi	= PossiblyConvertTitleFuncToList( sName, sF, sWin, lstColTi )				// List of column title lists no matter whether we had a function returning the titles or a direct list
		lstVisibility	= PossiblyConvertTitleFuncToList( sName, sF, sWin,  lstVisibility )			
		llstTabTi	= AddListItem( lstTabTi,  llstTabTi,	ksSEP_CTRL, inf ) 	// List of tab 	 title lists of ALL controls
		llstBlkTi	= AddListItem( lstBlkTi,   llstBlkTi,		ksSEP_CTRL, inf ) 	// List of block 	 title lists of ALL controls
		lllstRowTi	= AddListItem( lstRowTi, lllstRowTi,	ksSEP_CTRL, inf ) 	// List of  Row  	 title lists of ALL controls
		lllstColTi	= AddListItem( lstColTi,   lllstColTi,	ksSEP_CTRL, inf ) 	// List of column title lists of ALL controls
		lllstVisibility	= AddListItem( lstVisibility,lllstVisibility,	ksSEP_CTRL, inf ) 
		llstMode	= AddListItem( lstMode,  llstMode,	ksSEP_CTRL, inf ) 	// List of mode lists (for blk processing) of ALL controls

		nTabs		= TabCnt( lstTabTi )							// Number of  tabs    in  this control  with index 'n' 
		BlkMx	= 1	// 1 is the minimum value   TODO???
		for ( nTab = 0; nTab < nTabs; nTab += 1 )
			lstBlksInTab	= StringFromList( nTab, lstBlkTi, ksSEP_TAB )
			BlkCnt		= ItemsInList( lstBlksInTab, ksSEP_STD )
			BlkMx 		= max( BlkCnt, BlkMx )	// todo???
			// print nTab, nTabs, "\t", pd( lstBlksInTab, 15), "\t", BlkCnt, BlkMx
		endfor
		
		// Allow half-height lines	
		nRowCnt	= RowCnt( lstRowTi )
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
			PnCreateTabcoVars( sF+ sWin, TabGrp )				// create variables which store the selected tabs. Needed to initialise user tab settings. 
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
	 	sLongTitle	= GetLongestTitle3( lstBlkTi, lstRowTi, lstColTi, nMode )	//todo  3 blockviews..........  The title from which the length is computed here must be the same which is finally drawn in 'PnDraw()' ...
		variable	nTitlePixel	= TextLenToPixel( sLongTitle ) 			
		rXSz		= ( ( nTitlePixel + xBodySz + kXTRAPIX 		 ) * nCiL ) / ( 1+ nOvSz ) + ( nCiL -1- nOvSz ) * 3 // Only PopMenu and SetVariable has a BodySz>0 .  3 pixels are inserted between horizontal controls
		// rXSz	= ( ( nTitlePixel + xBodySz + kXTRAPIX - 6 * nOvSz ) * nCiL ) / ( 1+ nOvSz ) + ( nCiL -1- nOvSz ) * 3 // Only PopMenu and SetVariable has a BodySz>0 .  3 pixels are inserted between horizontal controls
		if ( rXSz > rXSzMx )
			rXSzMx	= max( rXSz, rXSzMx )
			sLongestControl	= "'" + sName + "'  (is number " + num2str( n ) + " ,  '" + sType + "'   " + sLongTitle +  "' )      control len: " + num2str( rXSz )
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

		bTrueTab	= IsTrueTab( lstTabTi )											// FALSE if there is no title at all = all titles are empty strings.  TRUE if there is at least 1 tab with a non-empty title. Blanks are non-empty and considered as tabs!
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

		nTabs	= TabCnt( lstTabTi )
	
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

	  printf "\t\t\tPnSize  5  returning width:\t%3d    height:%3d   = (%3d +%2d -%2d ) * %2d \t \r", width, height, ypos, BlkHt, yr, kYLINEHEIGHT
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
End


static Function		PnDraw( sF, sWin, sPnTitle, wPn, xPnSz, ySize, lstPosX, lstPosY, lstTabGrp, lstTabcoBeg, lstTabcoEnd, llstTypes, llstCNames, lllstTabTi,  llstBlkTi, lllstRowTi, lllstColTi, lllstVisibility, llstMode )
//  Draw the panel and the controls taking into account  Tab and Block grouping which was computed in  'PnSize()' . 
	wave   /T	wPn
	variable	xPnSz, ySize
	string		sF, sWin, sPnTitle
	string  	lstPosX, lstPosY								// where the controls will be positioned. Index is control number.
	string  	lstTabGrp, lstTabcoBeg, lstTabcoEnd					// where the tab frames will be positioned. These lists are indexed by TabGrp (including pseudo-tabs  (end=-1) for which no tab frame is drawn)
	string  	llstTypes, llstCNames, lllstTabTi, llstBlkTi, lllstRowTi, lllstColTi, lllstVisibility,  llstMode 
	
// Version1 + 2  050427  flickers less
	// NewPanel /W=( xLoc, yLoc, xLoc + xPnSz, yLoc + ySize ) /K= 1 /N=$sWin  as  sPnTitle

	// Kill all controls.  This is only required when the panel size changes and when controls which are no longer necessary are to be removed. If the same controls are used all the time killing them here is not mandatory.
	// As it is quite complex to filter out if and which controls must be removed, we remove all although we introduce some screen flicker this way.  
	variable	n, nCnt
	string  	lstControls	= ControlNameList( sWin )
	nCnt	= 	ItemsInList( lstControls )
	for ( n = 0; n < nCnt; n += 1 )											// for all controls (=all controls actually found in the panel)
		KillControl	/W = $sWin  $StringFromList( n, lstControls )
	endfor

	 printf "\t\t\tPnDraw()....  \r"
 	string  	lstTabTi, lstBlkTi, lstMode
 	variable	nTabco, nTab, nTabs, nSelectedTab
 	

	// Draw the controls within the tabcontrols but do not draw the tabcontrols yet

	string  	sType, sName, lstRowTi, lstColTi, sActProc, sFormEntry, lstVisibility, sHelpSubT//, lstInitVal,
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
		lstVisibility	= StringFromList( n, lllstVisibility, ksSEP_CTRL ) 								// 050806 lstVisibility is processed simpler than lstColTi

		sActProc	= RemoveWhiteSpace( StringFromList( kACTPROC, wPn[ n ], ksSEP_WPN ) )
		nCiL		= str2num( StringFromList( kMXPO, wPn[ n ], ksSEP_WPN ) )
		nOvSz	= str2num( StringFromList( kOVS, wPn[ n ], ksSEP_WPN ) )
		xBodySz	= str2num( StringFromList( kXBODYSZ, wPn[ n ], ksSEP_WPN ) )
		sFormEntry= ReplaceString( "\t", StringFromList( kFORMENTRY, wPn[ n ], ksSEP_WPN )  , "" )
		// printf "\t\t\tPnDraw() %2d/%2d\tNm:\t%s\tVis:\tlvis:%s\tllvis:%s\t  \r", n, nCnt, pd( sName,18), pd( lstVisibility , 29), pd( lllstVisibility , 49)

		sHelpSubT= ReplaceString( "\t", StringFromList( kHELPSUB, wPn[ n ], ksSEP_WPN ) , "" )

		nTabs		= TabCnt( lstTabTi )						// Number of  tabs    in  this control  with index 'n' 

		// Cave: Simple code - No empty strings are allowed  in the 'Tabs'  and  'Blks'  .  There must at least  be separators. 

		nTabco		= str2num( StringFromList( n, lstTabGrp ) )
		nSelectedTab	= PnTabcoIndex( sF + sWin, nTabco )  //0// todo:  must be stored dependant on panel and tabgroup

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

				mxRow	= RowCnt( lstRowTi )						// ??? here half-height rows are ignored???
				for ( nRow = 0; nRow < mxRow; nRow += 1 )
				
					mxCol	= RowCnt( lstColTi ) 
					for ( nCol = 0; nCol < mxCol; nCol += 1 )

						sCNmIdx 		= PnBuildVNmIdx( sName, nTab, nBlk, nRow, nCol )
						sFoCNmIdx	= ReplaceString( ":", sF + sWin + ":",  "_" ) + sCNmIdx

						bVisib		= InitValue( sCNmIdx, lstVisibility, 1 )			// If visibility 	values have been specified  in  'wPn[]' then use them , if not use 1 
						// printf "\t\t\tPnDraw()  \tNm:\t%s\t%s\t%s\tbVisib:%.0lf\tbDis:%d -> %d  \r", pd( sName,18),  pd( sCNmIdx,18), sFoCNmIdx, bVisib, bDisable, bDisable || ! bVisib

						sTitle			= sBlkTi + StringFromList( nRow, lstRowTi, ksSEP_STD )  + StringFromList( nCol, lstColTi, ksSEP_STD ) 
		
						if ( strlen( sHelpSubT ) == 0 )									// If the subtopic field is empty  then  use  the title for connecting a help topic to the control
							sHelpSubT = sTitle
						endif
					//	ConnectControlToHelpTopic( sCNmIdx, sPnTi, sHelpSubT )
		
						if ( 	nType == kSEP )
							xOs		= 3 * IsTrueTab( lstTabTi )								// indent a few pixels (3)  to make room for the tabcontrol border line
							yOs		= nRow
//050805
//							PanelSepar3(  	bDisable, nVisib, xPos + xOs,  yPos + yOs, sWin, sTitle, sCNmIdx, xPnSz )
							PanelSepar3(  	bDisable, bVisib, xPos + xOs,  yPos + yOs, sWin, sTitle, sFoCNmIdx, xPnSz )
						elseif ( nType == kBU )
							xOs		= nCol * xPnSz / nCiL + 2	
							yOs		= nRow
							variable width = xPnSz * ( 1 + nOvSz )  / nCiL - 2 
							PanelButton3(	bDisable, bVisib, xPos + xOs, yPos + yOs, sWin, sTitle, sActProc, sF, sFoCNmIdx, sCNmIdx, width )	
						elseif ( nType == kCB )
							xOs		= nCol * xPnSz / nCiL + 2
							yOs		= nRow
							PanelChkbx3(	bDisable, bVisib, xPos + xOs,  yPos + yOs, sWin, sTitle, sActProc, sF+sWin+":", sFoCNmIdx, sCNmIdx, lstTabTi, lstBlkTi, lstRowTi, lstColTi )
						elseif ( nType == kRAD )
							xOs		= nCol * xPnSz / nCiL + 2
							yOs		= nRow
							PanelRadio3(	bDisable, bVisib, xPos + xOs, yPos + yOs, sWin, sTitle, sActProc, sF+sWin+":", sFoCNmIdx, sCNmIdx, lstTabTi, lstBlkTi, lstRowTi, lstColTi )
						elseif ( nType == kSV  ||  nType == kSTR )
							xOs		= nCol * xPnSz / nCiL + 2 
							yOs		= nRow
							xSize	= SetvarFieldX( xPnSz, nOvSz, nCiL ) 
							PanelSetvar3( nType, bDisable, bVisib, xPos + xOs, xSize, yPos + yOs, sTitle, sActProc, sF, sWin, sFoCNmIdx, sCNmIdx, lstTabTi, lstBlkTi, lstRowTi, lstColTi, xBodySz, sFormEntry )	
						elseif ( nType == kPM )
							// xOs = (nCol +1) * xPnSz / nCiL + 2 - xBodySz + 3 * IsTrueTab( lstTabTi )	// todo: check that this is OK for ANY screen resolution...   Indent a few pixels (8)  to make room for the tabcontrol border line
							// xOs = (nCol +1) * xPnSz / nCiL + 2 - xBodySz 						// todo: check that this is OK for ANY screen resolution...   Seems to work without indentation seems even when in a tabcontrol?
							xOs		=  nCol  * xPnSz / nCiL + 2									// todo:    Seems to work without indentation seems even when in a tabcontrol?
							yOs		= nRow
							xSize		= SetvarFieldX( xPnSz, nOvSz, nCiL ) 
							PanelPopup3(	bDisable, bVisib, xPos + xOs, xSize, yPos + yOs, sTitle, sActProc, sF, sWin, sFoCNmIdx, sCNmIdx, lstTabTi, lstBlkTi, lstRowTi, lstColTi, xBodySz, sFormEntry )	
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
		nTabs		= TabCnt( lstTabTi )
		//sCleanName	= "fTC"+ CleanupName(sPanelTitle, 0) + num2str( TabBeg )		// Generate an automatic unique name for the tabcontrol ( flaw: theoretically there could be 2 panels with the same title...)
		sCleanName	=  sWin + "_" + num2str( nTabco )						// Generate an automatic unique name for the tabcontrol 
 sCleanName	= ReplaceString( ":", PnBuildFoTabcoNm( sF + sWin, nTabco )	, "_" )
 // printf "\t\tPnDraw [tab]\t%s\ttg:%2d/%2d\tBeg:%2d\tEnd:%2d\tTabs:%2d\t%s\t%s\t%s\t  bl:\t%s\t \r", pd(sCleanName,18), nTabco, TabGroups, TabBeg, TabEnd, nTabs, pd(lstTabTi,9), pd(lstTabcoBeg,13), pd(lstTabcoEnd,13), pd(llstBlkTi,29)
		if ( TabEnd != kNOTFOUND )
			TabControl  $sCleanName,	win = $sWin,	proc 	= fTabControl3						// First call a standard  TabControl  procedure which enables/disables buttons groups according to the selected tab...
																	// ...then from there attempt to call  a special  TabControl  procedure  with  name derived form  control name. (This proc can be missing)
			for ( nTab = 0; nTab < nTabs; nTab += 1 )
				TabControl $sCleanName,	win = $sWin,	tablabel( nTab )	= StringFromList( nTab, lstTabTi, ksSEP_TAB ) 
			endfor
			TabControl  $sCleanName,	win = $sWin,	tablabel( nTab)	= ""						// end marker for last tab 

			nSelectedTab = min( PnTabcoIndex( sF + sWin, nTabco ), nTabs-1 )	// The possibly clipped value (e.g. too few channels) will not change  global  user tab as the value is not passed back	  
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

static Function	IsTrueTab( lstTabTi )	
	string  	lstTabTi 
	return	strlen( ReplaceString( ksSEP_TAB, lstTabTi, "" ) ) > 0					// FALSE if there is no title at all = all titles are empty strings.  TRUE if there is at least 1 tab with a non-empty title. Blanks are non-empty and considered as tabs!
	// return	strlen( RemoveWhiteSpace( ReplaceString( ksSEP_TAB, lstTabTi, "" ) ) ) > 0// FALSE if there is no title at all = all titles are empty or blank strings.  TRUE if there is at least 1 tab with a non-empty-non-blank title.
End


static Function	/S	PossiblyConvertTitleFuncToList( sBsName, sF, sWin, lstTi )			
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




static Function	/S	GetLongestTitle3( lstBlkTi, lstRowTi, lstColTi, nMode )
// todo : nMode = 2: extra leading column with block title but  narrower following columns because they don't contain the block title,  
// todo : nMode = 3: extra leading row for each block with block title, but narrower columns because they don't contain the block title,  
	// Get the longest title.  
	string  	lstBlkTi, lstRowTi, lstColTi 
	variable	nMode
	// print  	lstBlkTi, "\t\t", lstRowTi, "\t\t", lstColTi , "\t\t", sSep
	string  	sTitle, sMxBlkTitle = "", sMxRowTitle = "", sMxColTitle = ""
	variable	n, nTitles
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
		sTitle		= StringFromList( n, lstRowTi, ksSEP_STD )
		if ( IsLonger( sTitle, sMxRowTitle ) )	
			sMxRowTitle	=  sTitle
		endif
	endfor
	nTitles	= ItemsInList( lstColTi, ksSEP_STD )
	for ( n = 0; n < nTitles; n += 1 )
		sTitle		= StringFromList( n, lstColTi, ksSEP_STD )
		if ( IsLonger( sTitle, sMxColTitle ) )	
			sMxColTitle	=  sTitle
		endif
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

Static  Function	TextLenToPixel( sTxt )
	string 	sTxt
	 // print  "TextLenToPixel() FontSizeStringWidth()" , ksFONT,  "->", FontSizeStringWidth( ksFONT, kFONTSIZE, 0, sTxt ), sTxt
	//return  		FontSizeStringWidth( ksFONT,  kFONTSIZE, 0, sTxt ) 	//040322  too small for  panels and too small for online analysis with many  WAx columns    
	return  4 + 1.04 * FontSizeStringWidth( ksFONT, kFONTSIZE, 0, sTxt ) 	//040322  OK for panels , still too small for online analysis  
End	

Function		SetvarFieldX( xPnSz, nOvSz, nCiL ) 
	variable	xPnSz, nOvSz, nCiL
	variable	kMARGIN 	 = 2
	variable	kFIELDMARGIN = 5
	return	( xPnSz - kMARGIN ) / nCiL* ( nOvSz + 1 )  + kFIELDMARGIN * ( nOvSz - 1 ) 
//	return	( xPnSz - kMARGIN ) / nCiL* ( nOvSz + 1 )  + kFIELDMARGIN * (  - 1 ) 
//	return	( xPnSz    ) / nCiL* ( nOvSz + 1 )  + kFIELDMARGIN * (  nOvSz  - 1 ) 
End

Function		FormatSetvarPopup( sTxt, xs, bodyw )
// Format SetVariable and Popupmenu so that they are neatly columnised. For this the title is padded with blanks  or truncated if too long.
// Result: Right justified, left justified, and exact input field width. Without this the left margin is undefined as the title is just in front of the input field...
	string  	&sTxt				// the control title
 	variable	xs					// the total control width 
 	variable	&bodyw				// the iput field width 
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
	variable 	nActualBlanks		=  trunc( nBlanks )
	variable 	nActualBlankPixels	 = nActualBlanks * nPixel1Blank
	sPad			= PadString( sPad, strlen( sPad ) + round(nBlanks), 0x20 )
	// sPad  		= PadString( sPad, strlen( sPad ) + trunc(nBlanks), 0x20 )
	// printf "\t\tFormatSetvarPopup(\tPx/Blnk:%3.1lf\t%3d\t%3d\t%s\t)  strPx:%4d\t + BlnPx: [%3d\t >%4.1lf\t >%3d\t>%4d\t] + Body:%3d\t = %4d\t/%4d\t[%4d] \t'%s'\r", nPixel1Blank, bodyw, xs, pd(sTxt,22), nStringPixels, nBlankPixels, nBlanks, nActualBlanks, nActualBlankPixels, bw, nStringPixels + nBlankPixels + bw,  FontSizeStringWidth( ksFONT, kFONTSIZE, 0, sPad ) + bw, xs, sPad
	sTxt		= sPad
	bodyw	= bw	
End


//Function		fChkbox_struct3( s )
//	struct	WMCheckboxAction	&s
//	 printf "\t\tfChkbox_struct3 :  \t%s\thas been set to %d... \t\t[will call if found: %s \tHelp: '%s' ]\r", pd(s.CtrlName,26), s.checked, pd(s.CtrlName+"()",26),  s.CtrlName
//	DisplayHelpTopicFor( s.CtrlName )							//  should work for both a checkbox and a popupmenu 
//	FUNCREF   fCbProc_struct3  fCbPrc = $( s.CtrlName ) 					// after  (possibly) displaying  this checkbox's helptopic...
//	fCbPrc( s )								// ..execute the action procedure (if there is one defined, it can also be missing) 
//End
//
//Function		fCbProc_struct3( s )							// dummy function  prototype
//	struct	WMCheckboxAction	&s
//End
//
Function		fRadio_struct3( s )
// each radio button group  consists of multiple indexed buttons (=sControlNm)   but  there is only 1 global variable (=sControlNmBase)...
// ...and there is only one action procedure (= sControlNmBase + "" )...
// ...and there is only one help topic (=the sSepText line above the buttons) which is connected separately to each button
	struct	WMCheckboxAction	&s
	string		sCtrlNm	= s.ctrlname
	string  	sThis 	= GetUserData(		s.win,  s.ctrlName,  "sThisF" )
	variable	len		= strlen( sCtrlNm )
	if ( len > 30 )
		 printf "++++Internal error : Control name  '%s'  is too long (%d) . Must be <= 30 . \r", sCtrlNm, len
	endif
	RadioCheckUncheck3( s ) 										// check / uncheck all the radio buttons of this group

// 050823 obsolete and wrong :   fRadio_struct3( s ) is called by the action procedure  and  NOT vice versa
//	// Design issue: The variable name includes  'root:uf:sThis:'  , the control name also includes  'root_uf_sThis_'   but the action proc name is without  (only in the _struct version).
//	string 	sControlNmBase = RadioButtonBaseName( sCtrlNm )
//	variable	nSkipPos		= strlen( ksROOTUF_ + sThis + "_" )			// 041101
//
//	 printf "\t\tfRadio_struct3(  \t\t\t%s\t\t )\t-> \t%s\t-> [ will call if found: %s  ]  (len:%d)\r", pd( sCtrlNm, 27) , pd( sControlNmBase, 23 ), pd( sControlNmBase[nSkipPos,inf]+"()", 23) , len
//
//	DisplayHelpTopicFor( sCtrlNm )									// after  (possibly) displaying  this checkbox's helptopic... 
//	FUNCREF   fCbProc_struct1  fCbPrc = $( sControlNmBase[nSkipPos,inf] )	// 041101
//	fCbPrc( s )													// ..execute the action procedure (if there is one defined, it can also be missing) 
	DisplayHelpTopicFor( sCtrlNm )									// after  (possibly) displaying  this checkbox's helptopic... 
End


static Function		RadioCheckUncheck3( s ) 
// check and uncheck the radio buttons of this group  and also create and set the single global variable which describes the state of this radio button group
	struct	WMCheckboxAction	&s
	string		ctrlName	= s.ctrlName
	string  	lstTabTi 	= GetUserData(	s.win, s.ctrlName, "lstTabTi" )		// 
	string  	lstBlkTi 	= GetUserData(	s.win, s.ctrlName, "lstBlkTi" )		// 
	string  	lstRowTi 	= GetUserData(	s.win, s.ctrlName, "lstRowTi" )		// 
	string  	lstColTi 	= GetUserData(	s.win, s.ctrlName, "lstColTi" )		// 

	 printf "\t\tRadioCheckUncheck3\t%s\t%s\r", pd(ctrlName,31), lstBlkTi
	variable	nBlk, nRow, nCol, nTab, nLinIdx
	string  	sFoRadVar, sFoNmIdx, sFoNm	= ctrlName[ 0, strlen( ctrlName ) - 4 - 1 ]	

	nTab	=  TabIdx( ctrlName )						
	nBlk	=  BlkIdx( ctrlName )														// Version 1 : there is 1 radio button setting for each block, each tab
	// for ( nBlk = 0; nBlk < BlkCnt( lstBlkTi, nTab   ); nBlk += 1 )								// Version 2 : Radio button group extends over multiple blocks
		for ( nRow = 0; nRow < RowCnt( lstRowTi ); nRow += 1 )
			for ( nCol = 0; nCol < ColCnt( lstColTi ); nCol += 1 )
				sFoNmIdx = PnBuildVNmIdx( sFoNm, nTab, nBlk, nRow, nCol ) 
				if ( cmpstr( sFoNmIdx, ctrlName ) == 0 )								// check (=turn on) the one clicked button... 
					CheckBox $ctrlName, value = 1									// ONLY NECESSARY when button is set indirectly (e.g. shape from trace,ana,stage..)

					// Version 1 : There is 1 unique radio button for each tabs / block.  
					nLinIdx	 = LinRadioButtonIndex3( 0, 0, nRow, nCol, lstTabTi, lstBlkTi, lstRowTi, lstColTi ) 
					sFoRadVar = sFoNmIdx[ 0, strlen( sFoNmIdx ) - 4 - 1 + 2 ]		 		// Create ONE global variable for the radio button group : strip the last 2 indices

					// Version 2 : Obsolete,  impractical and unfinished: there is only 1 radio button for all tabs, blocks rows and columns
					//nLinIdx	 = LinRadioButtonIndex( nTab, nBlk, nRow, nCol, lstDims ) 
					//sFoRadVar = sFoNmIdx[ 0, strlen( sFoNmIdx ) - nDims - 1 	]			// Create ONE global variable for the radio button group : strip the last 4 indices

					sFoRadVar = ReplaceString( "_", sFoRadVar, ":" ) 					// Create ONE global variable for the radio button group...
					variable /G $sFoRadVar 	= nLinIdx								// ... and store state of radio button group in this ONE global variable

					 printf "\t\tRadioCheckUncheck3\t%s\t%s\tOne global var:\t'%s'\tIndex of checked:%d \r", pd(ctrlName,31),  lstBlkTi, sFoRadVar, nLinIdx 	
				else
					CheckBox $sFoNmIdx, value = 0									// ...reset all other radio buttons of this group
				endif
			endfor
		endfor
	// endfor
End

static Function		LinRadioButtonIndex3( nTab, nBlk, nRow, nCol, lstTabTi, lstBlkTi, lstRowTi, lstColTi )
	string  	lstTabTi, lstBlkTi, lstRowTi, lstColTi
	variable	nTab, nBlk, nRow, nCol
	variable	mxTabs = TabCnt( lstBlkTi )
	return	( ( nTab * BlkMax( lstBlkTi, mxTabs )  + nBlk ) * RowCnt( lstRowTi ) + nRow ) * ColCnt( lstColTi ) + nCol 
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
	Checkbox  $sRadButtonsCommonBase + num2str( index ) + "0" , win=$sWin, value = 1		// Assumption/Flaw : works only for VERTICAL radio buttons. Code for horz : $sRadButtonsCommonBase + "0" + num2str( index )     
End

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


static Function		PanelSepar3(  bDisable, bVisib, xPos,  yPos, sWin, sTitle, sCNm, width )
// Process 1 line with or without separating text. If there is no text the separator will only be half-height. This is handled in 'Pnsize()'.
	variable	bDisable, bVisib, xPos,  yPos, width
	string		sWin, sTitle, sCNm
	if ( strlen( sTitle ) ) 
		//DrawText /W = $sWin	xPos, yPos * kYLINEHEIGHT + 18, sTitle				// +18 aligns text between buttons . DrawText is not a control and is not handled correcty (is not erased by killcontrol)) 
		Groupbox	$sCNm, win = $sWin,	disable			= bDisable  ||  ! bVisib				
		Groupbox	$sCNm, win = $sWin,	pos				= { xPos + kXMARGIN, yPos * kYLINEHEIGHT }	
		Groupbox	$sCNm, win = $sWin,	size				= { width - 2 * kXMARGIN, 13}				// 13 : narrow line, not a box in conjunction with frame = 1 , or 12 if frame = 1
		Groupbox	$sCNm, win = $sWin,	title				= sTitle 
		Groupbox	$sCNm, win = $sWin,	frame			= 1  
		Groupbox	$sCNm, win = $sWin,	userdata( bVisib )	= num2str( bVisib )
	endif
End


static Function		PanelButton3( bDisable, bVisib, xPos,  yPos, sWin, sTitle, sProc, sFo, sCNm, sName, width )
	variable	bDisable, bVisib, xPos,  yPos, width
	string		sWin, sTitle, sProc, sCNm, sFo, sName

	string  	sProcNm	=  "fButtonProc_struct" 	// if the PRC field is empty then call a standard button procedure which auto-builds the name and then executes the button proc unique to the button name
	if ( strlen( sProc ) )						
		sProcNm	= ReplaceString( "()", sProc, "" )	// if the PRC field is not empty then use the string in the PRC field as a special button procedure.  Advantage: a single proc serves multiple buttons
	endif										
	// printf "\t\t\tPanelButton3  \t%s\t%s\tCtrlNm:\t%s\t%s\tBw:%3d\t  \r", pd(sFo,17),  pd(sName,17),  pd(sCNm,29), pd(sProcNm,15), width

	Button	$sCNm, win = $sWin,	disable			= bDisable  ||  ! bVisib				
	Button	$sCNm, win = $sWin,	pos				= { xPos, yPos * kYLINEHEIGHT }	
	Button	$sCNm, win = $sWin,	size				= { width, kYHEIGHT }
	Button	$sCNm, win = $sWin,	title				= sTitle 
	Button	$sCNm, win = $sWin,	proc				= $sProcNm	
	Button	$sCNm, win = $sWin,	userdata( sFo )		= sFo	
	Button	$sCNm, win = $sWin,	userdata( sProcNm )	= sProcNm
	Button	$sCNm, win = $sWin,	userdata( bVisib )	= num2str( bVisib )
End


static Function		PanelChkbx3(  bDisable, bVisib, xPos,  yPos, sWin, sTitle, sProc, sFo, sCNm, sName, lstTabTi, lstBlkTi, lstRowTi, lstColTi )
	variable	bDisable, bVisib, xPos,  yPos
	string		sWin, sTitle, sProc, sCNm, sFo, sName, lstTabTi, lstBlkTi, lstRowTi, lstColTi 

	string		sProcNm	=  "fChkbox_struct1" 								// if the PRC field is empty  then use a standard procedure name for connecting a help topic to the control  and (if defined) additionally use a special  action proc with an automatic name
	if ( strlen( sProc ) )												// if the PRC field is not empty then use ...
		sProcNm		= ReplaceString( "()", sProc, "" )						// if the PRC field is not empty then use the string in the PRC field as a special  action procedure
	endif

// this clears the state
//	nvar		bIsInitialCb	= $sF + sName 									// Get the name of the global shadow checkbox variable.
//	bIsInitialCb 		= InitValueCB( sCNm, lstInitVal )						// The checkbox state will be taken care of automatically by Igor once the global shadow variable is set.
	// printf "\t\t\tPanelChkbx3\t\t%s\t%s\tCtrlNm:\t%s\t%s\tx:%3d\ty:%3d\t%s\t%s\t%s\tro:\t%s\t  \r", pd(sFo,15),  pd(sName,15),  pd(sCNm,26), pd(sTitle,9), xPos, yPos,  pd( lstTabTi,19),  pd( lstBlkTi,19),  pd( lstColTi, 9), pd( lstRowTi,19)


	CheckBox	$sCNm, win = $sWin,	disable			= bDisable  ||  ! bVisib
	CheckBox	$sCNm, win = $sWin,	pos				= { xPos,  yPos * kYLINEHEIGHT }	
	CheckBox	$sCNm, win = $sWin,	title				= sTitle	
	CheckBox	$sCNm, win = $sWin,	mode			= 0							// default checkbox appearance, not radio button appearance
	CheckBox $sCNm, win = $sWin,	proc				= $sProcNm			
	CheckBox	$sCNm, win = $sWin,	variable			= $( sFo + sName ) 				// make checkbox state depend on this global shadow variable (name can be derived from checkbox name and vice versa)
CheckBox	$sCNm, win = $sWin,	userdata( sFo ) 	= sFo	
//	CheckBox	$sCNm, win = $sWin,	userdata( lstMode )	= lstMode
	CheckBox	$sCNm, win = $sWin,	userdata( lstTabTi )	= lstTabTi
	CheckBox	$sCNm, win = $sWin,	userdata( lstBlkTi )	= lstBlkTi
	CheckBox	$sCNm, win = $sWin,	userdata( lstRowTi )	= lstRowTi
	CheckBox	$sCNm, win = $sWin,	userdata( lstColTi )	= lstColTi

	CheckBox $sCNm, win = $sWin,	userdata( sProcNm )	= sProcNm
	CheckBox $sCNm, win = $sWin,	userdata( bVisib )	= num2str( bVisib )
	// printf "\tCHKBOX3-Checkbox  %s\tFolder:%s\tProc:%s\tsFo:'%s'\t \r", pd(sFo + sName,28), pd(sFo,10), pd( sProcNm, 26), sFo

End


static Function		PanelRadio3( bDisable, bVisib, xPos,  yPos, sWin, sTitle, sProc, sFo, sCNm, sName, lstTabTi, lstBlkTi, lstRowTi, lstColTi )
	variable	bDisable, bVisib, xPos,  yPos
	string		sWin, sTitle, sProc, sCNm, sFo, sName, lstTabTi, lstBlkTi, lstRowTi, lstColTi 

	string		sProcNm	=  "fRadio_struct3" 								// if the PRC field is empty  then use a standard procedure name for connecting a help topic to the control  and (if defined) additionally use a special  action proc with an automatic name
	if ( strlen( sProc ) )												// if the PRC field is not empty then use ...
		sProcNm		= ReplaceString( "()", sProc, "" )						// if the PRC field is not empty then use the string in the PRC field as a special  action procedure
	endif
	// printf "\t\t\tPanelRadio3 \t\t\t\t%s\t%s\tCtrlNm:\t%s\t%s\t%s\t%s\t%s\t  \r",  pd(sFo,15),  pd(sName,15),  pd(sCNm,26), pd( lstTabTi,19),  pd( lstBlkTi,19), pd( lstRowTi,19),  pd( lstColTi,19)
	
	CheckBox	$sCNm, win = $sWin,	disable			= bDisable  ||  ! bVisib	
	CheckBox	$sCNm, win = $sWin,	pos				= { xPos,  yPos * kYLINEHEIGHT }	
	CheckBox	$sCNm, win = $sWin,	title				= sTitle	
	CheckBox	$sCNm, win = $sWin,	mode			= 1							// radio button appearance, not default checkbox appearance
	CheckBox $sCNm, win = $sWin,	proc				= $sProcNm			
	CheckBox	$sCNm, win = $sWin,	variable			= $( sFo + sName ) 				// make radio button state depend on this global shadow variable (name can be derived from checkbox name and vice versa)
CheckBox	$sCNm, win = $sWin,	userdata( sFo ) 	= sFo	
//	CheckBox	$sCNm, win = $sWin,	userdata( sThisF ) 	= sThisF	
	CheckBox	$sCNm, win = $sWin,	userdata( lstTabTi )	= lstTabTi
	CheckBox	$sCNm, win = $sWin,	userdata( lstBlkTi )	= lstBlkTi
	CheckBox	$sCNm, win = $sWin,	userdata( lstRowTi )	= lstRowTi
	CheckBox	$sCNm, win = $sWin,	userdata( lstColTi )	= lstColTi
	CheckBox $sCNm, win = $sWin,	userdata( sProcNm )	= sProcNm
	CheckBox $sCNm, win = $sWin,	userdata( bVisib )	= num2str( bVisib )
	 // printf "\tRadio3-Checkbox  %s\tFolder:%s\tProc:%s\t%s\tHelpTp:'%s[%s]' \r", pd(sFo_Name,28), pd(sF,10), pd( sProcNm, 26), sPnTi, sTitleLists, sHelpSubTopic	
End

static Function		PanelSetVar3( nType, bDisable, bVisib, xPos, xSize, yPos, sTitle, sProc, sFo, sWin, sCNm, sName, lstTabTi, lstBlkTi, lstRowTi, lstColTi, nBodyWidth, lstFormatLimits )
	variable	nType, bDisable, bVisib, xPos, xSize, yPos, nBodyWidth
	string		sTitle, sProc, sFo, sWin, sCNm, sName, lstTabTi, lstBlkTi, lstRowTi, lstColTi, lstFormatLimits

	string  	sProcNm	= "fSetvar_struct1"								// if the PRC field is empty  then  use  a standard action procedure
	if ( strlen( sProc ) )												// if the PRC field is not empty  then use...
		sProcNm		= ReplaceString( "()", sProc, "" )						// ..the string in the PRC field as a special action procedure
 	endif	

if ( nType == kSV )
//????????????
	nvar	  nInitialSV  = $sFo + sWin + ":" + sName 									// Find the underlying global shadow variable for the  Setvariable  control  and set it
////	nInitialSV 	   = InitValuePM( sCNm, lstInitVal, 2 )							// The Setvariable value will be taken care of automatically by Igor once the global shadow variable is set.
	// printf "\t\t\tPanelSetVar3\t%s\t%s\tCtrlNm:\t%s\t%s\tBw:%3d\tIV:%2d\t%s\t  \r", pd(sFo,17),  pd(sName,17),  pd(sCNm,27), pd(sProcNm,15), nBodyWidth, nInitialSV, lstFormatLimits
endif
//elseif ( nType == kSTR )

	string		sFormat		= StringFromList( 0, lstFormatLimits )				// number format  e.g.  %d   or  %3.1lf
	string		sLim			= StringFromList( 1, lstFormatLimits )				// variable limits   min,max,step  used only in PN_SETVAR  and  PN_DISPVAR   or  3 colors combined     
 
	FormatSetvarPopup( sTitle, xSize, nBodyWidth )		// references are changed
 
 	SetVariable  $sCNm,  win = $sWin,	disable			= bDisable  ||  ! bVisib						// cleaning is only necessary when string contains blanks, tabs etc.
	SetVariable  $sCNm,  win = $sWin,	pos				= { xPos ,  yPos * kYLINEHEIGHT }
	SetVariable  $sCNm,  win = $sWin,	size				= { xSize , 0 }							// height is ignored
	SetVariable  $sCNm,  win = $sWin,	bodywidth   		= nBodyWidth							//  set and align field size, but give up left alignment of field text (unless FormatSetvarPopup() is used..)
	SetVariable  $sCNm,  win = $sWin,	title				= sTitle
	SetVariable  $sCNm,  win = $sWin,	proc				= $sProcNm	
 	SetVariable  $sCNm,  win = $sWin,	value			= $sFo + sWin + ":" + sName 							// get name of global number variable to be changed

 	SetVariable  $sCNm,  win = $sWin,	format			= sFormat								// cleaning is only necessary when string contains blanks, tabs etc.
 	SetVariable  $sCNm,  win = $sWin,	limits				= { str2num( StringFromList( 0, sLim, "," ) ),str2num( StringFromList( 1, sLim, "," ) ),str2num( StringFromList( 2, sLim, "," ) ) }
	SetVariable  $sCNm,  win = $sWin,	userdata( sFo )		= sFo	
	SetVariable  $sCNm,  win = $sWin,	userdata( lstTabTi )	= lstTabTi
	SetVariable  $sCNm,  win = $sWin,	userdata( lstBlkTi )	= lstBlkTi
	SetVariable  $sCNm,  win = $sWin,	userdata( lstRowTi )	= lstRowTi
	SetVariable  $sCNm,  win = $sWin,	userdata( lstColTi )	= lstColTi
	SetVariable  $sCNm,  win = $sWin,	userdata( sProcNm )	= sProcNm
	SetVariable  $sCNm,  win = $sWin,	userdata( bVisib )	= num2str( bVisib )
End

static Function		PanelPopup3( bDisable, bVisib, xPos,  xSize, yPos, sTitle, sProc, sFo, sWin, sCNm, sName, lstTabTi, lstBlkTi, lstRowTi, lstColTi, nBodyWidth, sFormEntry )
	variable	bDisable, bVisib, xPos, xSize, yPos, nBodyWidth
	string		sTitle, sProc, sFo, sWin, sCNm, sName, lstTabTi, lstBlkTi, lstRowTi, lstColTi, sFormEntry

	string  	sProcNm	= "fPopup_struct1"								// if the PRC field is empty  then  use  a standard action procedure
	if ( strlen( sProc ) )												// if the PRC field is not empty then use ...
		sProcNm		= ReplaceString( "()", sProc, "" )						// if the PRC field is not empty then use the string in the PRC field as a special  action procedure
	endif

////	variable	nInitialValue	= 1										// entry to start with (counted from 1)  is fixed and is the first entry 
////	if ( strlen( lstInitVal ) ) 
////		nInitialValue	= InitValuePM( sCNm, lstInitVal, kNOTFOUND )			// entry to start with (counted from 1)  is initial value from parameter  in  'wPn[]'  
//// 	endif

	string  	sFoPmVar		= ReplaceString( "_", sCNm, ":" )		//  e.g. root_uf_eva_evl_gpopupVar000 -> root:uf:eva:evl:gpopupVar000
	nvar		nInitialValue	= $sFoPmVar 							// restore the popupvalue from the the global variable 
	PopupMenu $sCNm,	win = $sWin,	mode= nInitialValue

//	variable	nInitialValue	= 1										// entry to start with (counted from 1)  is fixed and is the first entry 
//	if ( strlen( lstInitVal ) ) 
//		nInitialValue	= InitValuePM( sCNm, lstInitVal, kNOTFOUND )		// entry to start with (counted from 1)  is initial value from parameter  in  'wPn[]'  
//	else
//		string  	sFoPmVar		= ReplaceString( "_", sCNm, ":" )		//  e.g. root_uf_eva_evl_gpopupVar000 -> root:uf:eva:evl:gpopupVar000
//		nvar		nInitialVal		= $sFoPmVar 							// restore the popupvalue from the the global variable 
//		nInitialValue	= nInitialVal
//  	endif
//	PopupMenu $sCNm,	win = $sWin,	mode= nInitialValue


//////	nvar /Z		nInitialPm	= $ReplaceString( "_", sCNm, ":" )
//////	if ( strlen( lstInitVal ) ) 
//////		PopupMenu $sCNm,	win = $sWin,	mode= InitValuePM( sCNm, lstInitVal )		// set entry to start with
//////	else
//////  		PopupMenu $sCNm,	win = $sWin,	mode= nInitialPm + 1					// entry to start with (counted from 1)  is initial value from  'CreateXXXGlobals()'   as  nInitialValue=0
//////  	endif


	
	// printf "\t\t\tPanelPopup3a \t%s\t%s\tCtrlNm:\t%s\t%s\tBw:%3d\tIV:%2d\txpo:%3d\txsz:%3d\tbwi:%3d\t   \r", pd(sFo,17),  pd(sName,17),  pd(sCNm,27), pd(sProcNm,15), nBodyWidth, nInitialValue, xPos, xSize, nBodyWidth
	FormatSetvarPopup( sTitle, xSize, nBodyWidth )		// references are changed
	// printf "\t\t\tPanelPopup3b \t%s\t%s\tCtrlNm:\t%s\t%s\tBw:%3d\tIV:%2d\txpo:%3d\txsz:%3d\tbwi:%3d\typos:%d\t   \r", pd(sFo,17),  pd(sName,17),  pd(sCNm,27), pd(sProcNm,15), nBodyWidth, nInitialValue, xPos, xSize, nBodyWidth, yPos

	PopupMenu $sCNm,	win = $sWin,	disable			= bDisable  ||  ! bVisib				
	if ( xPos+1 < 0  ||  yPos * kYLINEHEIGHT  < 0 )
		DeveloperError( "Position clipping control " + sCNm + " .   x : " + num2str( xPos ) + ",  y: "  + num2str( yPos * kYLINEHEIGHT ) )
	endif	
	PopupMenu $sCNm,	win = $sWin,	pos				= {  max( 0, xPos+1 ), max( 0, yPos * kYLINEHEIGHT - 1 ) } // clip to 0 as the topmost control cannot start at -2 
	PopupMenu $sCNm,	win = $sWin,	size				= { xSize , 0 } //kYLINEHEIGHT+ 4 }					// the y height parameter is ignored...
	PopupMenu $sCNm,	win = $sWin,	bodywidth			= nBodyWidth				
	PopupMenu $sCNm,	win = $sWin,	title				= sTitle 
	PopupMenu $sCNm,	win = $sWin,	proc				= $sProcNm	
	PopupMenu $sCNm,	win = $sWin,	userdata( sFo )		= sFo	
	PopupMenu $sCNm,	win = $sWin,	userdata( lstTabTi )	= lstTabTi
	PopupMenu $sCNm,	win = $sWin,	userdata( lstBlkTi )	= lstBlkTi
	PopupMenu $sCNm,	win = $sWin,	userdata( lstRowTi )	= lstRowTi
	PopupMenu $sCNm,	win = $sWin,	userdata( lstColTi )	= lstColTi
	PopupMenu $sCNm,	win = $sWin,	userdata( sProcNm )	= sProcNm
	PopupMenu $sCNm,  win = $sWin,	userdata( bVisib )	= num2str( bVisib  )	// store the visibility state (depending here only on cbFit, not on the tab!) so that it can be retrieved in the tabcontrol action proc (~ShowHideTabControl3() )

	FUNCREF   fPopupListProc3  fPopPrc = $ReplaceString( "()", sFormEntry, "" )		// get the listbox entries from a function. This is the generalized form of simple call ' PopupMenu $sName, value = "Item1;Item2;..." '
	fPopPrc( sCNm, sFo, sWin )											// Unfortunately this code is not really generic. New popupmenus may require additional parameters which must be added as dummies to existing functions.
End

Function		fPopupListProc3( sCNm, sFo, sPnWin )	
// Needed to get the listbox entries from a function with auto-built name. This is the generalized form of the much simpler but limited call ' PopupMenu $sName, value = "Item1;Item2;..." '
// Unfortunately this code is not really generic. New popupmenus may require additional parameters which must be added as dummies to existing functions.
	string  	sCNm, sFo, sPnWin
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
	  printf "\t\t\tPossiblyCreateFolder( %s ) returns %d ( the folder %s ) \r", sNestedFolder, code, SelectString( code, "already existed", "has been created" )
	return code
End

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

// Count the dimensions of 1 tabcontrol : how many tabs, how many blocks in each tab, how many rows and colunms in each tab and block ?

static  Function	TabCnt( lstTabTi )
	string  	lstTabTi
	return	ItemsInList( lstTabTi, ksSEP_TAB ) 
End



static  Function	BlkMax( lstBlkTi, MaxTabs )
// Returns the maximum number of blocks in any tab. Needed for the panel to keep it's size if the number of blocks differs from tab to tab. 
	string  	lstBlkTi
	variable	MaxTabs 
	variable	nTab, MaxBlocks = 0
	for ( nTab = 0; nTab < MaxTabs; nTab += 1 )
		MaxBlocks	= max( MaxBlocks, BlkCnt( lstBlkTi, nTab ) )
	endfor
//	// printf "\t\t\t\tBlkMax( \t%s\tmxTab:%2d ) \t-> \t%d \t \r",  pd(lstBlkTi,14),  MaxTabs, MaxBlocks
	return	MaxBlocks
End

static  Function	BlkCnt( lstBlkTi, nTab )
// Returns the number of blocks in  tab  'nTab' . 
	string  	lstBlkTi				// e.g......................................... 'b0;°b0;b1;b2;°'  will return 1 (nTab=0)  and  3 (nTab=1)
	variable	nTab
//	// printf "\t\t\t\tBlkCnt( \t%s\tnTab:%2d ) \t-> \t'%s'\t%s\t'%s' \t%d \t \r",  pd(lstBlkTi,14),  nTab, ksSEP_TAB, StringFromList( nTab, lstBlkTi, ksSEP_TAB ), ksTAB_B_SEP, ItemsInList( StringFromList( nTab, lstBlkTi, ksSEP_TAB ), ksTAB_B_SEP )
	return	ItemsInList( StringFromList( nTab, lstBlkTi, ksSEP_TAB ), ksSEP_STD )	// Mx( lstDims, kID_BLK )
End

static  Function	RowCnt( lstRowTi )
	string  	lstRowTi
	return	max( 1, ItemsInList( lstRowTi, ksSEP_STD ) )		// no separator or blank required in wPn
End

static  Function	ColCnt( lstColTi )
	string  	lstColTi
	return	max( 1, ItemsInList( lstColTi, ksSEP_STD ) )			// no separator or blank required in wPn
End
 

//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//  TABCONTROL3    ( CheckBox ,  Radio button, SetVariable  and  Popupmenu  is handled )

Function		fTabControl3( s )
	struct	WMTabControlAction   &s
	TabControl3( s.win, s.ctrlName, s.tab )
	FUNCREF   fTcProc3  fTcPrc = $( s.ctrlName )				//This action proc will only be executed when tabs are CLICKED, it will not be executed if tabs are changed indirectly by clicking into the window (as 's' is unknown).
	fTcPrc( s )											// Execute the action procedure (if there is one defined, it can also be missing) . Used in Eval  to activate the graph window corresponding to the clicked tab.
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
	ShowHideTabControl3( sCtrlName, nTab, sF, sWin, lstTypes, lstCNames, lstTabTi, lstBlkTi, lstMode, llstRowTi, llstColTi ) 
	PnTabcoIndexSet( sF + sWin, nTabco, nTab )			// store the currently selected tab as the active tab

// test
//	ControlUpdate /A /W = $s.win	// BAD: makes screen flicker  but without this line  SOME!  popupmenu and setvariable  are not displayed  when changing tabs
End

Function		fTcProc3( s )							// dummy function  prototype
	struct	WMTabControlAction &s
End

static Function		ShowHideTabControl3(  sTabCtrlNm, nSelectedTab, sF, sWin, lstTypes, lstCNames, lstTabTi, llstBlkTi, llstMode, llstRowTi, llstColTi ) 
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
		TabMax	= TabCnt( lstTabTi )
		for ( nTab = 0; nTab < TabMax; nTab += 1 )				

			lstBlkTi		= StringFromList( nTab, lstBlkTi1Ctrl, ksSEP_TAB )
			lstMode		= StringFromList( nTab, lstMode1Ctrl, ksSEP_TAB )	// allows blanking out specific blocks

			BlkMax	= BlkCnt( lstBlkTi1Ctrl, nTab )
			for ( nBlk = 0; nBlk < BlkMax; nBlk += 1 )

				lstBlkTi	= StringFromList( nBlk, lstBlkTi, ksSEP_STD )
				nMode	= str2num( StringFromList( nBlk, lstMode, ksSEP_STD ) )

				variable	bTabDisable	= ! ( nSelectedTab == nTab )
				variable	bDisable		= bTabDisable  ||  ( nMode == 0 )
				// printf "\t\t\tShowHideTabControl3\t%s\t%s\tTyp:%d\t%s\tTab:%d/%d  SelTb:%d\tDisable:%d\tblk:%d/%d\tnMode:%d\t->dis:%d\t-> %s\t-> %s\t \r",  pd(sTabCtrlNm,15), pd(lstTypes,9), nType, pd( sCNm,9), nTab, TabMax, nSelectedTab, bTabDisable, nBlk, BlkMax, nMode,  bDisable, pd(lstBlkTi1Ctrl,19), pd(lstBlkTi,13)

	
				RowMax = RowCnt( lstRowTi )
				for ( nRow = 0; nRow < RowMax; nRow += 1 )
					ColMax = ColCnt( lstColTi )
					for ( nCol = 0; nCol < ColMax; nCol += 1 )
						sCNmIdx 	  = PnBuildVNmIdx( sCNm, nTab, nBlk, nRow, nCol )
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
							elseif ( nType == kRAD )
								Checkbox	  $sFoCNmIdx,	win = $sWin,	disable = bDisableVis	
							elseif ( nType == kSV  ||  nType == kSTR )
								SetVariable  $sFoCNmIdx,	win = $sWin,	disable = bDisableVis	
							elseif ( nType == kPM )
								PopupMenu $sFoCNmIdx,	win = $sWin,	disable = bDisableVis
							elseif ( nType == kBU )
								Button	 $sFoCNmIdx,	win = $sWin,	disable = bDisableVis
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

Function		fPopup_struct1( s )
// executed when the user selected an item from the listbox
	struct	WMPopupAction	&s
	string  	sFoPmVar	= ReplaceString( "_", s.ctrlName, ":" )   	//  e.g. root_uf_eva_evl_gpopupVar000 -> root:uf:eva:evl:gpopupVar000
	nvar	 /Z	nTmp	= $sFoPmVar 							// set the global variable with the popup value to store state
	if ( nvar_Exists( nTmp ) )
		nTmp	= s.popNum									// the global variable has already been constructed previously
 		// printf "\t\tfPopup_struct1 :\t'%s' ->\t%s\t exists and has been set \tto %d... \t[will call proc if found: '%s()' <--todo possibly strip indices\tHelp: '%s' ]\r", s.ctrlName, sFoPmVar, nTmp, s.ctrlName, s.ctrlName
	else
		variable	/G	$sFoPmVar = 1								// the global variable is constructed now and set to refelect the first list entry.  Setting it to 0 would lock and effectively disable the popmemu 
		printf "\t\tfPopup_struct1 :\t'%s' ->\t%s\t does not exist. Initialised \tto %d... \t[will call proc if found: '%s()' <--todo possibly strip indices\tHelp: '%s' ]\r", s.ctrlName, sFoPmVar, nTmp, s.ctrlName, s.ctrlName
	endif	

	// ControlInfo		/W=$s.win	$s.ctrlName	; 		print "\t\t\t\t\t\t", s.ctrlName , sFoPmVar, V_flag ,  V_Disable , S_recreation

// 030303 help implemented like Checkbox but not tested......
//	DisplayHelpTopicFor( sControlNm )								//  should work for both a checkbox and a popupmenu
//	FUNCREF   fCbProc  fCbPrc = $( sControlNm )						// after  (possibly) displaying  this popupmenu's helptopic... 
//	fCbPrc( sControlNm, Value )									// ..execute the action procedure (if there is one defined, it can also be missing) 
End


static Function		InitValue( sCNm, lstInitVal, nInitVal )	
// Extracts initial value from list for control  'sCNm' .  Control can be  PopMenu, SetVariable or Checkbox.  Accepts integers, negative integers, floats.  Also tolerates strings but cannot process them as a number is returned.
// Initial setting	T0 B0 R? C0 : 3, 	T0 B0 R? C1 : 2.5,	T1 B0 R? C0 : -7     all the rest: 2.3	is coded	'0000_3;0001_2.5;1000_-7;~2.3'  .  Uses   ksSEP_COMMONINIT '~'
// tab,blk,row,col are coded in the string: ++ Is easy to read and modify, any order and missing entries are allowed.  -- Needs more space, handling takes longer as complete list is scanned, 
	string  	sCNm, lstInitVal
	variable	nInitVal												// return this value if no value could be extracted from the list
	variable	len 			= strlen( sCNm )
	string  	sCNmIdx		= sCNm[ len - 4 , len - 1 ]						// Extract the indices of the control  e.g. 'svName0102' 	-> '0102'
	string  	lstSpecificInitVal	= StringFromList( 0, lstInitVal, ksSEP_COMMONINIT )	//  e.g. '0000_3;0001_2.5;1000_-7;~2.3' 				->  '0000_3;0001_2.5;1000_-7'
	string  	sCommonInitVal	= StringFromList( 1, lstInitVal, ksSEP_COMMONINIT )	//  e.g. '0000_3;0001_2.5;1000_-7;~2.3' 				->  '2.3'
	variable	nCommonInitVal	= str2num( sCommonInitVal )
	nInitVal	= numType( nCommonInitVal ) == kNUMTYPE_NAN ? 	nInitVal : nCommonInitVal	// no common value could be extracted from the list so use the passed value

	variable	i, nItems	= ItemsInList( lstSpecificInitVal )						//  e.g. '0000_3;0001_2.5;1000_-7;'		-> 3
	for ( i = 0; i < nItems; i += 1 )		
		string  	sSpecInitIdx_Val = StringFromList( i, lstInitVal )				//  e.g. '0000_3;0001_2.5;1000_-7;'		-> '0000_3'
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


Function		fChkbox_struct1( s )
	struct	WMCheckboxAction	&s
	 printf "\t\tfChkbox_struct1 :  \t%s\thas been set to %d... \t\t[will call if found: %s \tHelp: '%s' ]\r", pd(s.CtrlName,26), s.checked, pd(s.CtrlName+"()",26),  s.CtrlName
	DisplayHelpTopicFor( s.CtrlName )							//  should work for both a checkbox and a popupmenu 
	FUNCREF   fCbProc_struct1  fCbPrc = $( s.CtrlName ) 					// after  (possibly) displaying  this checkbox's helptopic...
	fCbPrc( s )								// ..execute the action procedure (if there is one defined, it can also be missing) 
End

Function		fCbProc_struct1( s )							// dummy function  prototype
	struct	WMCheckboxAction	&s
End


Function		fSetvar_struct1( s ) 
	struct	WMSetvariableAction   &s
	printf "\t\tfSetvar_struct1( sControlNm:'%s'   Value:%g , sVarName:'%s'  \t[will call if found: %s  ]\r", s.ctrlname, s.dval, s.vname,  pd(s.CtrlName+"()",26) 

//	string  	sFoPmVar		= ReplaceString( "_", s.ctrlName, ":" )   	//  e.g. root_uf_eva_evl_gpopupVar000 -> root:uf:eva:evl:gpopupVar000
//	nvar		nTmp		= $sFoPmVar 							// set the global variable (which has already been constructed) for the popmenu with the popup value to store state
//	nTmp	= s.popNum
//	printf "\t\tfPopup_struct1 :\t'%s' ->\t%s\t has been set to %d... \t[will call proc if found: '%s()' <--todo possibly strip indices\tHelp: '%s' ]\r", s.ctrlName, sFoPmVar, s.popNum, s.ctrlName, s.ctrlName


	DisplayHelpTopicFor( s.ctrlname )							// after  (possibly) displaying  this checkbox's helptopic... 
	FUNCREF   fSvProc_struct1  fSvPrc = $( s.ctrlname )				// ..
	fSvPrc( s )												// ..execute the action procedure (if there is one defined, it can also be missing) 
End

Function		fSvProc_struct1( s ) 								// dummy function  prototype
	struct	WMSetvariableAction    &s
End

//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

static  constant	kID_TAB = 0,  kID_BLK = 1,  kID_ROW = 2,  kID_COL = 3	// This is the order of the indices for the automatic control variables.


static Function  /S	PnBuildFoTabcoNm( sFsPnWndNm, nTabco )
	string  	sFsPnWndNm
	variable	nTabCo
	string  	sFoTabcoNm	= sFsPnWndNm + ":" + "tc" + num2str( nTabco )		// e.g. root:uf:eva:de:tc1
	// printf "\t\t\t\tPnBuildFoTabcoNm() \t'%s'\t  \r", 	sFoTabcoNm
	return						sFoTabcoNm
End

static Function  /S	PnBuildVNmIdx( sBsNm, nTab, nBlk, nRow, nCol )
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


//Function		InitValueCB( sCNm, lstInitVal )
//// returns truth if  'sCNm'  should be  turned on  initially
//	string  	sCNm, lstInitVal
//	variable	len 		= strlen( sCNm )										// e.g.  'Namexyz0102'
//	variable	i, nItems	= ItemsInList( lstInitVal )
//	string  	sInitVal
//	for ( i = 0; i < nItems; i += 1 )		
//		sInitVal	= StringFromList( i, lstInitVal )								// e.g. '0102'
//		if ( cmpstr( sCNm[ len - 4 , len - 1 ], sInitVal ) == 0 )
//			// print "\t\t\tInitValueCB  ", i, nItems,  lstInitVal, sInitVal, sCNm, "->  is ON"
//			return	TRUE
//		endif
//		// print "\t\t\tInitValueCB  ", i, nItems,  lstInitVal, sInitVal, sCNm, "->  is OFF"
//	endfor
//	return	FALSE
//End



//Function		LinRadioButtonIndex( nTab, nBlk, nRow, nCol, lstTabTi, lstBlkTi, lstRowTi, lstColTi )
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
	nvar		value   = $sF + ":" + PnBuildVNmIdx( sBsNm, nTab, nBlk, nRow, nCol ) 
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
	string		sNBName	= "Nb" //		ksPN_NB_WNDNAME 		// = 'NbPn'	

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

				sFoVarNm	= sFolder + sWin + ":"  + sCoNm						// e.g.   root:uf:eva: +  Set:  +   tc0, svA0000, cbB1000				
				variable	/G	   $sFoVarNm	= str2num( StringFromList( 1, sLine, "=" ) )
				nvar	value	= $sFoVarNm	
				variable			bDisable	= str2num( StringFromList( 2, sLine, "=" ) )

				Checksum += value
				sFoCoNm	= ReplaceString( ":", sFoVarNm, "_" )			// e.g. root_uf_eva_tbPnEvalDetails3,  root_uf_eva_svA0000,  root_uf_eva_cbB1000

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
		Alert( kERR_FATAL,  " RecallAllFolderVars()  could not open '" + sFilePath + "' " )	
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
// remove all folders e.g. 'root_uf_eva_Set_cbAlDel0000'  -> 'cbAlDel0000' 
	string  	sFolderCtrlName
	variable	nNmParts			= ItemsInList( sFolderCtrlName, "_" )
	string  	sThisControl		= StringFromList( nNmParts - 1, sFolderCtrlName, "_" )	// remove all folders e.g. 'root_uf_eva_Set_cbAlDel0000'  -> 'cbAlDel0000' 
	return	sThisControl
End	

Function	/S	StripFoldersAnd4Indices( sFolderCtrlName )
// remove all folders and the 4 trailing 'tab/blk/row/col' indices e.g. 'root_uf_eva_Set_cbAlDel0000'  -> 'cbAlDel' 
	string  	sFolderCtrlName
	string  	sThisControl		= StripFolders( sFolderCtrlName )					// remove all folders e.g. 'root_uf_eva_Set_cbAlDel0000'  -> 'cbAlDel0000' 
	return	sThisControl[ 0, strlen( sThisControl ) - 1 - 4 ]							// e.g. 'cbAlDel0000'  -> 'cbAlDel' 
End	

Function		SetTheSingleGlobalRadioVariable( sFoVarNm, sRadioNameStartsWith, value )
	string		sFoVarNm, sRadioNameStartsWith
	variable	value
	// 051109  Bad code  as  	 1. is especially arranged for  and  will  (most probably) work only for 1 dimensional horizontal radio buttons 	2. relies on the control name starting with  'ra'   e.g.  'raStartVal'
	variable	nNameParts	= ItemsInList( sFoVarNm, ":" )							// e.g. 'root:uf:eva:de:raStVal0000'  or   'root:uf:eva:de:raStVal0001'
	string		sBaseNm		= StringFromList( nNameParts-1, sFoVarNm, ":" )				// e.g. 'raStVal0000'  or   'raStVal0001'
	variable	len			= strlen( sRadioNameStartsWith )
	string  	sTheSingleGlobalRadioVariable
	if ( cmpstr( sBaseNm[ 0, len-1 ], sRadioNameStartsWith ) == 0 )						// the checkbox belongs to a radio button group 
		if ( value == 1 )														// it is the selected radio button
			len	= strlen( sFoVarNm )
			sTheSingleGlobalRadioVariable = RemoveEnding( RemoveEnding( sFoVarNm ) )	// e.g. 'root:uf:eva:de:raStVal00'  TODO ALWAYS REMOVES JUST 2 NUMBERS, COULD BE 1 OR 3  DEPENDING ON RADIO DIMENSIONS
			variable /G   $sTheSingleGlobalRadioVariable	// for some (uninvestigated) reason the 'sTheSingleGlobalRadioVariable'  is sometimes recalled before and sometimes after the radio buttons, so we construct it right now and do not wait until it is automatically constructed later  
			nvar	val	= $sTheSingleGlobalRadioVariable
			val		= str2num( sFoVarNm[ len-1, len-1 ] )							// the last digit of the name of the turned-on button is the value with which the single underlying global radio button variable must be set
			printf "\t\t\tSetTheSingleGlobalRadioVariable(\t%s\t'%s'  %g )\t ->\t%s\t= %d  \r", pd(sFoVarNm,27), sRadioNameStartsWith, value, pd(sTheSingleGlobalRadioVariable,27), val 
		endif
	endif
End