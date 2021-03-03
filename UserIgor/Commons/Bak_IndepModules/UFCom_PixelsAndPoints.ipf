//
//  UFCom_PixelsAndPoints.ipf 
// 
#pragma rtGlobals=1							// Use modern global access method.

//#pragma IndependentModule=UFCom_		
#include "UFCom_Constants"


//===============================================================================================================================
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  PIXELS  AND  POINTS

// Igor uses two types of coordinate systems: pixel ( e.g. NewPanel, FontSizeStringWidth ) and points: ( e.g. MoveWindow, GetWindow, Display )
// For the conversion five empirically determined constants must be used (tested for 1024x768 , 1280x1024  and 1600x1200 pixel )  
static constant		kIGOR_POINTS72		= 72	// needed to convert from screen pixels to points
static constant		kIGOR_XMIN_WNDLOC	= 2	// needed to convert from screen pixels to points
constant		kIGOR_XMISSINGPIXEL	= 5	// needed to convert from screen pixels to points 
static constant		kIGOR_YMIN_WNDLOC	= 37	// needed to convert from screen pixels to points (=GetIgorAppPoints( ->YMinPoints ) )
constant		kIGOR_YMISSINGPIXEL	= 26	// needed to convert from screen pixels to points 

constant		kIGOR_YMIN_PANELLOC	= 43 // place panel just below the menu line (panel coords in pixel!) 
 									// value checked for (and exact for) 1280x1024, old value was 41 , smaller values are automatically increased to this value

Function		UFCom_GetIgorAppPoints( rxMinPoints, rxMaxPoints, ryMinPoints, ryMaxPoints )
// Extract the current IGOR application window size in POINTS from a string  of type "DEPTH=24,RECT=0,0,1276,932" 
// Convert to IGOR points giving the maximum IGOR window possible (coordinates in points) 
	variable	&rxMinPoints, &rxMaxPoints, &ryMinPoints, &ryMaxPoints
	variable	xMaxPixel	= UFCom_GetIgorAppPixelX() 
	variable	yMaxPixel	= UFCom_GetIgorAppPixelY() 
	rxMinPoints	= kIGOR_XMIN_WNDLOC
	rxMaxPoints	= kIGOR_XMIN_WNDLOC +  ( xMaxPixel - kIGOR_XMISSINGPIXEL ) * kIGOR_POINTS72 / screenresolution
	ryMinPoints	= kIGOR_YMIN_WNDLOC
	ryMaxPoints	= kIGOR_YMIN_WNDLOC +  ( yMaxPixel - kIGOR_YMISSINGPIXEL ) * kIGOR_POINTS72 / screenresolution
End


Function		UFCom_GetIgorAppPixelX()		
// Returns the right Igor main frame pixel value. Works only in Igor 5
// Tested and works on 1024x768, 1280x1024, 1600x1200 , maximized and windowed mode
// ++ takes into account moving the left and right window border
	string  	ctrlName	
	GetWindow kwFrameInner , wsize
	// printf "GetIgorAppPixelX()\tkwFrameInner\t\t\twsize/pts\tleft:\t%7d\tright:\t%7d\ttop:\t%7d\tbot:\t%7d\t  ScreenResolution: %d \r", V_left, V_right, V_top, V_bottom, ScreenResolution
	variable	left	= V_left	* screenresolution / kIGOR_POINTS72 	// Convert to pixels	
	variable	right	= V_right	* screenresolution / kIGOR_POINTS72 	
	variable	top	= V_top	* screenresolution / kIGOR_POINTS72 	// Convert to pixels
	variable	bot	= V_bottom* screenresolution / kIGOR_POINTS72 	
	// printf "GetIgorAppPixelX() \t\t\t\t\t\t\twsize/PIXEL\tleft:\t%7d\tright:\t%7d\ttop:\t%7d\tbot:\t%7d\t  \r", left, right, top, bot
	return	right - left
End


Function		UFCom_GetIgorAppPixelY()		
// Returns the bottom Igor main frame pixel value. Works only in Igor 5
// Tested and works on 1024x768, 1280x1024, 1600x1200 , maximized and windowed mode
// ++ takes into account moving the top and bottom window border
	string  	ctrlName	
	GetWindow kwFrameInner , wsize
	// printf "GetIgorAppPixelY()\tkwFrameInner\t\t\twsize/pts\tleft:\t%7d\tright:\t%7d\ttop:\t%7d\tbot:\t%7d\t  ScreenResolution: %d \r", V_left, V_right, V_top, V_bottom, ScreenResolution
	variable	left	= V_left	* screenresolution / kIGOR_POINTS72 	// Convert to pixels	
	variable	right	= V_right	* screenresolution / kIGOR_POINTS72 	
	variable	top	= V_top	* screenresolution / kIGOR_POINTS72 	// Convert to pixels
	variable	bot	= V_bottom* screenresolution / kIGOR_POINTS72 	
	// printf "GetIgorAppPixelY() \t\t\t\t\t\t\twsize/PIXEL\tleft:\t%7d\tright:\t%7d\ttop:\t%7d\tbot:\t%7d\tusable Pix X: %3d     Y : %3d \r", left, right, top, bot, right - left, bot - top
	return	bot - top
End

Function		UFCom_IgorMainVersion()
	string  	sIgorVersion	= StringByKey( "IGORVERS", IgorInfo( 0 ) )
	variable	nVersion		= str2num( sIgorVersion[ 0 ] )			// use only main version number, ignore letters e.g 4.09a   ->  4
	return	nVersion
End


static constant	YTOP2LINES			= 35		// valid for any screen resolution
static constant	XGRAPHBORDER 		= 5		// valid for any screen resolution
static constant	YGRAPHBORDER 		= 18 		// valid for any screen resolution
static constant   cMARGIN				= 20		// additional pixels around graphs ( there are already fixed margins) 

//static constant   	XPTS = 770, YPTS = 550	// for 1280 x 1024 pixel,	screenresolution=120, big  fonts, on 17" CRT   OK
Function		UFCom_GetAutoWindowCorners( row, nRows, col, nCols, rnLeft, rnTop, rnRight, rnBot, xL100, xR100 )
	variable	row, nRows, col, nCols
	variable	xL100, xR100							// part of the whole window in percent ( e.g. right third: 67,100) 
	variable	&rnLeft, &rnTop, &rnRight, &rnBot
	variable	XPTS = UFCom_GetIgorAppPixelX() *  0.6			// independent of screen resolution
	variable 	YPTS = UFCom_GetIgorAppPixelY() *  0.6	
	variable	dx	= ( XPTS - (2 * cMARGIN ) ) * ( xR100 - xL100 ) / 100 / nCols
	variable	x	= cMARGIN + col * dx  + ( XPTS - (2 * cMARGIN ) ) *  xL100  / 100 
	variable	dy	= ( YPTS - 2 * cMARGIN ) / nRows
	dy =  nRows == 2  ? 	dy * .75	:  dy			// 040122	if there are only 1 or 2 rows of windows, the automatic height using (almost) the complete screen gives very narrow windows...
	dy =  nRows == 1  ? 	dy * .5	:  dy			// ...so make the windows look nicer and at the same time gain screen space by decreasing their height
	variable	y	= YTOP2LINES + cMARGIN + row * dy 
	rnLeft	= x
	rnTop	= y
	rnRight	= x + dx - XGRAPHBORDER
	rnBot	= y + dy  - YGRAPHBORDER
End


