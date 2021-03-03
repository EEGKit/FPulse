//
// UF_AcqDispCurves4.ipf
// 
// Routines for
//	080612 NEWstyle displaying traces during acquisition :  maintaining the display configuration as 'curves'
//

#pragma rtGlobals=1							// Use modern global access method.

//=====================================================================================================================================
//  PUBLIC  INTERFACE  :  ACQUISITION  DISPLAY CONFIGURATION : the quad global string list 'llllstDiac' containing all display acquisition window / trace arrangement variables

Function	/S	LstDiac()
// returns quadruple list containing all acquisition windows, window locations, curves and curve items
	string  	sFo		= ksACQ
	svar  /Z	lst	= $"root:uf:" + sFo + ":lllstDiac"
	if ( ! svar_exists( lst ) )
		string /G	   $"root:uf:" + sFo + ":lllstDiac" = ""
		svar  lst	= $"root:uf:" + sFo + ":lllstDiac"
	endif
//print "LstDiac():  '",lst, "'" 
	return	lst
End

Function	/S	LstDiacSet( lst )
	string  	lst
	string  	sFo		= ksACQ
	string  /G	$"root:uf:" + sFo + ":lllstDiac" = lst			
//print "LstDiacSet():  '",lst, "'" 
	return	lst									// returning the string just set simplifies debugging
End

Function	/S	DiacSeps()
	return	ksDIA_WNDSEP + ksDIA_TYPSEP + ksDIA_CVSEP  
End

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//  PUBLIC  INTERFACE  :  ACQUISITION  WINDOW  LOCATION and VISIBILITY of one window

Function		DiacWndCnt()
	string	 	llllst	= LstDiac()
	return	ItemsInList( llllst, ksDIA_WNDSEP )
End

Function		DiacWindowPositionDefault( wn, left, top, right, bot )
	variable	wn, &left, &top, &right, &bot
	variable	os	= 25
	left	= 30+wn*os;  top = 70+wn*os;  right = 400+wn*os;  bot = 250+wn*os	// 30, 70 leave room for the stimulus graph window in default position
End

//----------------------------------------------------------------------------------------------------------------------------

Function		DiacWindowPosition( sWNm, wn, left, top, right, bot )
// retrieve acquisition window position
	string  	sWNm
	variable	wn, &left, &top, &right, &bot
	string  	llllst	= LstDiac() //2009-04-02 KANN WEG
	left	= str2num(  Diac_Parameter( sWNm, wn, kDIA_TYP_LOC, 0, kDIA_WND_L ) )			// the unused 'cv' parameter is set to zero
	top	= str2num(  Diac_Parameter( sWNm, wn, kDIA_TYP_LOC, 0, kDIA_WND_T ) )			// ...
	right	= str2num(  Diac_Parameter( sWNm, wn, kDIA_TYP_LOC, 0, kDIA_WND_R ) )			
	bot	= str2num(  Diac_Parameter( sWNm, wn, kDIA_TYP_LOC, 0, kDIA_WND_B ) )
	// Handle invalid positions (should not happen)			
	if ( numType(left) == UFCom_kNUMTYPE_NAN  ||  numType(top) == 2  ||  numType(right) == 2  ||  numType(bot) == 2 )
		  DiacWindowPositionDefault( wn, left, top, right, bot )						// changes the references
	endif
End

Function		DiacWindowPositionSet( sFo, sWNm, wn, left, top, right, bot )
	string  	sFo, sWNm
	variable	wn, left, top, right, bot 
	string  	llllst	= ""
	llllst	=  Diac_ParameterSet( sWNm, wn, kDIA_TYP_LOC, 0, kDIA_WND_L, num2str( round( left  ) ) )	// the unused 'cv' parameter is set to zero
	llllst	=  Diac_ParameterSet( sWNm, wn, kDIA_TYP_LOC, 0, kDIA_WND_T, num2str( round( top  ) ) )	// ...
	llllst	=  Diac_ParameterSet( sWNm, wn, kDIA_TYP_LOC, 0, kDIA_WND_R, num2str( round( right) ) )	// ...
	llllst	=  Diac_ParameterSet( sWNm, wn, kDIA_TYP_LOC, 0, kDIA_WND_B, num2str( round( bot  ) ) )	// ...(rounding is only cosmetics)
End


Function		DiacWindowRange( sWNm, wn )
// retrieve acquisition window range (datasection, frame, lap)
	string  	sWNm
	variable	wn
	return	str2num(  Diac_Parameter( sWNm, wn, kDIA_TYP_LOC, 0, kDIA_WND_XRANGE ) )			// the unused 'cv' parameter is set to zero
End

Function		DiacWindowRangeSet( sFo, sWNm, wn, nRange )
	string  	sFo, sWNm
	variable	wn, nRange
	string  	llllst	= Diac_ParameterSet( sWNm, wn, kDIA_TYP_LOC, 0, kDIA_WND_XRANGE, num2str( nRange ) )// lllst only for debugging,  the unused 'cv' parameter is set to zero
End


Function		DiacWindowXShift( sWNm, wn )
// retrieve acquisition window X=time shift 
	string  	sWNm
	variable	wn
	return	str2num(  Diac_Parameter( sWNm, wn, kDIA_TYP_LOC, 0, kDIA_WND_XSHIFT ) )				// the unused 'cv' parameter is set to zero
End

Function		DiacWindowXShiftSet( sFo, sWNm, wn, xShift )
	string  	sFo, sWNm
	variable	wn, xShift
	string  	llllst	= Diac_ParameterSet( sWNm, wn, kDIA_TYP_LOC, 0, kDIA_WND_XSHIFT, num2str( xShift ) )	// lllst only for debugging,  the unused 'cv' parameter is set to zero
End


Function		DiacWindowXZoom( sWNm, wn )
// retrieve acquisition window X=time zoom 
	string  	sWNm
	variable	wn
	return	str2num(  Diac_Parameter( sWNm, wn, kDIA_TYP_LOC, 0, kDIA_WND_XZOOM ) )				// the unused 'cv' parameter is set to zero
End

Function		DiacWindowXZoomSet( sFo, sWNm, wn, xZoom )
	string  	sFo, sWNm
	variable	wn, xZoom
	string  	llllst	= Diac_ParameterSet( sWNm, wn, kDIA_TYP_LOC, 0, kDIA_WND_XZOOM, num2str( xZoom ) )	// lllst only for debugging,  the unused 'cv' parameter is set to zero
End


Function		DiacWindowXTrueTime( sWNm, wn )
// retrieve acquisition window Truetime setting (originally from the checkbox) 
	string  	sWNm
	variable	wn
	return	str2num(  Diac_Parameter( sWNm, wn, kDIA_TYP_LOC, 0, kDIA_WND_XTRUETIME ) )			// the unused 'cv' parameter is set to zero
End

Function		DiacWindowXTrueTimeSet( sFo, sWNm, wn, xTruetime )
	string  	sFo, sWNm
	variable	wn, xTruetime
	string  	llllst	= Diac_ParameterSet( sWNm, wn, kDIA_TYP_LOC, 0, kDIA_WND_XTRUETIME, num2str( xTruetime ) )// lllst only for debugging,  the unused 'cv' parameter is set to zero
End


// 2009-04-03
Function		DiacWindowNio( sWNm, wn )
// retrieve IOTyp of the currenly active trace (Dac=0, Adc=1...) in the acquisition window
	string  	sWNm
	variable	wn
	return	str2num(  Diac_Parameter( sWNm, wn, kDIA_TYP_LOC, 0, kDIA_WND_NIO ) )					// the unused 'cv' parameter is set to zero
End
Function		DiacWindowNioSet( sFo, sWNm, wn, nio )
	string  	sFo, sWNm
	variable	wn, nio
	string  	llllst	= Diac_ParameterSet( sWNm, wn, kDIA_TYP_LOC, 0, kDIA_WND_NIO, num2str( nio ) )		// lllst only for debugging,  the unused 'cv' parameter is set to zero
End


// 2009-04-03
Function		DiacWindowCio( sWNm, wn )
// retrieve the subindex of the currenly active IOTyp in the acquisition window
	string  	sWNm
	variable	wn
	return	str2num(  Diac_Parameter( sWNm, wn, kDIA_TYP_LOC, 0, kDIA_WND_CIO ) )					// the unused 'cv' parameter is set to zero
End
Function		DiacWindowCioSet( sFo, sWNm, wn, cio )
	string  	sFo, sWNm
	variable	wn, cio
	string  	llllst	= Diac_ParameterSet( sWNm, wn, kDIA_TYP_LOC, 0, kDIA_WND_CIO, num2str( cio ) )		// lllst only for debugging,  the unused 'cv' parameter is set to zero
End


// 2009-04-03
Function		DiacWindowCBarShow( sWNm, wn )
// retrieve whether the acquisition window Control bar is shown or hidden
	string  	sWNm
	variable	wn
	return	str2num(  Diac_Parameter( sWNm, wn, kDIA_TYP_LOC, 0, kDIA_WND_CBARSHOW ) )			// the unused 'cv' parameter is set to zero
End

// 2009-04-03
Function		DiacWindowCBarShowSet( sFo, sWNm, wn, bShow )
	string  	sFo, sWNm
	variable	wn, bShow
	string  	llllst	= Diac_ParameterSet( sWNm, wn, kDIA_TYP_LOC, 0, kDIA_WND_CBARSHOW, num2str( bShow ) )// lllst only for debugging,  the unused 'cv' parameter is set to zero
End

//----------------------------------------------------------------------------------------------------------------------------

Function  	/S	DiacWndTraces( wn )
// Return all curves of 1 window.  Only for debugging, the parameters should be read and set by special functions, but not with this function.
	variable	wn
	return	StringFromList( wn,  LstDiac(), ksDIA_WNDSEP )
End

Function  	/S	DiacWndRemove( wn )
// Removes entire window (location and traces)  from  DiacWnd  structure
	variable	wn
	string	 	llllst	= LstDiac()
			llllst	= LstDiacSet( RemoveListItem( wn, llllst, ksDIA_WNDSEP ) )
	return	llllst								// returning the string just set simplifies debugging
End

Function		DiacTypCnt( wn )
// counts and returns number of types (e.g dacs + digs + adc = 3 )
	variable	wn
	string	 	llllst	= LstDiac()
	return	ItemsInList( StringFromList( wn, llllst, ksDIA_WNDSEP ), ksDIA_TYPSEP ) - 1 							 // -1 skips window location
End

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//  PUBLIC  INTERFACE  :  ACQUISITION  WINDOW  TRACES 
						
// 2009-04-04  height and  SliderShow are missing ???
 Function	/S	DiacTraceAdd( sFo, sWNm, wn, nio, cio, sIOType, sIONr, sIONm, sUnits, bAutoscl, YOfs, YZoom, Gain )		
// ADD new trace to curves in window 'w' , return the index of the trace/curve which has just been added
	string  	sFo, sWNm, sIOType, sIONr, sIONm, sUnits
	variable	wn, nio, cio, bAutoscl, YOfs, YZoom, Gain
	string  	llllst	= ""
	llllst	=  Diac_ParameterSet_( sWNm, wn, nio, cio, kDIA_CV_IOTYP,	sIOType )			// 
	llllst	=  Diac_ParameterSet_( sWNm, wn, nio, cio, kDIA_CV_IONR,	sIONr )			// 
	llllst	=  Diac_ParameterSet_( sWNm, wn, nio, cio, kDIA_CV_IONM,	sIONm )			// 
	llllst	=  Diac_ParameterSet_( sWNm, wn, nio, cio, kDIA_CV_UNITS,	sUnits )			// 
	llllst	=  Diac_ParameterSet_( sWNm, wn, nio, cio, kDIA_CV_AUTOSCL,num2str( bAutoscl ) )	// 
	llllst	=  Diac_ParameterSet_( sWNm, wn, nio, cio, kDIA_CV_YOFS,	num2str( YOfs ) )	// 
	llllst	=  Diac_ParameterSet_( sWNm, wn, nio, cio, kDIA_CV_YZOOM,	num2str( YZoom ) )	//
	llllst	=  Diac_ParameterSet_( sWNm, wn, nio, cio, kDIA_CV_GAIN,	num2str( Gain ) )		//
	return	llllst
End

// 2009-04-04  height and  SliderShow are missing ???
Function	  	DiacTraceExtract( sWNm, wn, nio, cio, rsIOTyp, rsIONr, rsNm, rsUnits, rbAutoscl, rYOfs, rYZoom  )	
// Extracts all entries (IOTyp, IONr, IONm Units, rbAutoscl, rYOfs, rYZoom, rsRGB)  including the trace name when  1 curve  defined by window 'wn' , type 'nio'  and channel 'cio'  is given
	string  	sWNm
	variable	wn, nio, cio
	variable	&rbAutoscl, &rYOfs, &rYZoom
	string		&rsIOTyp, &rsIONr, &rsNm, &rsUnits
	rsIOTyp	= Diac_Parameter_( sWNm, wn, nio, cio, kDIA_CV_IOTYP )
	rsIONr	= Diac_Parameter_( sWNm, wn, nio, cio, kDIA_CV_IONR )	
	rsNm		= Diac_Parameter_( sWNm, wn, nio, cio, kDIA_CV_IONM ) 
	rsUnits	= Diac_Parameter_( sWNm, wn, nio, cio, kDIA_CV_UNITS ) 
	rbAutoscl	= str2num( Diac_Parameter_( sWNm, wn, nio, cio, kDIA_CV_AUTOSCL ) )
	rYOfs	= str2num( Diac_Parameter_( sWNm, wn, nio, cio, kDIA_CV_YOFS ) )
	rYZoom	= str2num( Diac_Parameter_( sWNm, wn, nio, cio, kDIA_CV_YZOOM ) )
End

Function  	/S	DiacTraceRemove( wn, nio, cio )
// Removes a single  Adc or Dac channel.   Note: The window location could be removed  by passing  nio = -1  and cio = 0
	variable	wn, nio, cio
	string	 	llllst	= LstDiac()
			llllst	= LstDiacSet( UFCom_RemoveTripleListItem( wn, nio+1, cio, llllst, ksDIA_WNDSEP, ksDIA_TYPSEP, ksDIA_CVSEP ) ) // nio+1 skips window location
	return	llllst								// returning the string just set simplifies debugging
End

Function		DiacTraceCnt( wn, nio )
// counts and returns number of channels in 1 type 'nio'  (e.g  1 dac  or  3 digs  or  2 adcs )
	variable	wn, nio
	string	 	llllst	= LstDiac()
	return	ItemsInList( StringFromList( nio+1, StringFromList( wn, llllst, ksDIA_WNDSEP ), ksDIA_TYPSEP ), ksDIA_CVSEP )	 // nio+1 skips window location
End


Function	/S	DiacTraceTyp( sWNm, wn, nio, cio )
	string  	sWNm		// not used
	variable	wn, nio, cio
	return	Diac_Parameter_( sWNm, wn, nio, cio, kDIA_CV_IOTYP ) 
End

Function	/S	DiacTraceNr( sWNm, wn, nio, cio )
	string  	sWNm		// not used
	variable	wn, nio, cio
	return	Diac_Parameter_( sWNm, wn, nio, cio, kDIA_CV_IONR ) 
End
	
// not used...
//Function	/S	DiacTraceNm( sWNm, wn, nio, cio )
//	string  	sWNm		// not used
//	variable	wn, nio, cio
//	return	Diac_Parameter_( sWNm, wn, nio, cio, kDIA_CV_IONM ) 
//End

Function		DiacTraceYOfs( sWNm, wn, nio, cio )
	string  	sWNm		// not used
	variable	wn, nio, cio
	return	str2num( Diac_Parameter_( sWNm, wn, nio, cio, kDIA_CV_YOFS ) ) 
End
Function	/S	DiacTraceYOfsSet( sWNm, wn, nio, cio, value )
	string  	sWNm		// not used
	variable	value, wn, nio, cio
	return	Diac_ParameterSet_( sWNm,  wn, nio, cio, kDIA_CV_YOFS, num2str( value ) )
End

Function		DiacTraceYZoom( sWNm, wn, nio, cio )
	string  	sWNm		// not used
	variable	wn, nio, cio
	return	str2num( Diac_Parameter_( sWNm, wn, nio, cio, kDIA_CV_YZOOM ) )
End
Function	/S	DiacTraceYZoomSet( sWNm, wn, nio, cio, value )
	string  	sWNm		// not used
	variable	value, wn, nio, cio
	return	Diac_ParameterSet_( sWNm,  wn, nio, cio, kDIA_CV_YZOOM, num2str( value ) )
End


// 2009-04-04
Function		DiacTraceAutoScl( sWNm, wn, nio, cio )
	string  	sWNm		// not used
	variable	wn, nio, cio
	return	str2num( Diac_Parameter_( sWNm, wn, nio, cio, kDIA_CV_AUTOSCL ) )
End
Function	/S	DiacTraceAutoSclSet( sWNm, wn, nio, cio, value )
	string  	sWNm		// not used
	variable	value, wn, nio, cio
	return	Diac_ParameterSet_( sWNm,  wn, nio, cio, kDIA_CV_AUTOSCL, num2str( value ) )
End


// 2009-04-04
Function		DiacTraceSliderShow( sWNm, wn, nio, cio )
	string  	sWNm		// not used
	variable	wn, nio, cio
	return	str2num( Diac_Parameter_( sWNm, wn, nio, cio, kDIA_CV_SLIDERSHOW ) )
End
Function	/S	DiacTraceSliderShowSet( sWNm, wn, nio, cio, value )
	string  	sWNm		// not used
	variable	value, wn, nio, cio
	return	Diac_ParameterSet_( sWNm,  wn, nio, cio, kDIA_CV_SLIDERSHOW, num2str( value ) )
End

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -	

Function	/S	DiacTraceChannel( sWNm, wn, nio, cio )
	string  	sWNm		// not used
	variable	wn, nio, cio
	return	DiacTraceTyp( sWNm, wn, nio, cio ) + DiacTraceNr( sWNm, wn, nio, cio )	// ass name
End

//=====================================================================================================================================
//  HIDDEN  IMPLEMENTATION  :  the DISPLAY CONFIGURATION 'llllstDiac'  containing all  display acquisition window / trace arrangement variables
//  llllstDiac is a quadruple list made of   windows (~),   types=locs or curves/channels (^),  curves/channels (;)   and items (,) .  Note: the window positions and scaling factors are stored only as a double list,  only the curves/channels are stored as a triple list

static strconstant	ksDIA_WNDSEP	= "^"				

static strconstant	ksDIA_TYPSEP		= "~"				

static constant		kDIA_TYP_LOC = 0//,  kDIA_TYP_CURVE = 1


static constant		kDIA_WND_L = 0,   kDIA_WND_T = 1,   kDIA_WND_R = 2,   kDIA_WND_B = 3,   kDIA_WND_XRANGE = 4,   kDIA_WND_XSHIFT = 5,   kDIA_WND_XZOOM = 6,   kDIA_WND_XTRUETIME = 7,   kDIA_WND_NIO = 8,   kDIA_WND_CIO = 9,   kDIA_WND_CBARSHOW = 10

static strconstant	ksDIA_CVSEP		= ";"		// also implicitly used as 	'ksDIA_LOCSEP'  which is not required as there is only 1  _LOC_ per window  (in contrast to _CV_ : there may be multilple curves per window)
static constant		kDIA_CV_IOTYP = 0,  kDIA_CV_IONR = 1,  kDIA_CV_IONM = 2,  kDIA_CV_YOFS = 3,  kDIA_CV_YZOOM = 4,  kDIA_CV_HEIGHT = 5,   kDIA_CV_UNITS = 6,  kDIA_CV_AUTOSCL = 7,  kDIA_CV_GAIN = 8,    kDIA_CV_SLIDERSHOW = 9

static strconstant	ksDIA_ITEMSEP	= ","				


static Function	/S	 Diac_Parameter( sSection, wn, typ, cv, item )
// elementary retrieving function for  Diac  window location 
	string  	sSection				// e.g. the window name 'AW0'   or   'AW1'
	variable	wn, typ, cv, item
	string  	sFo 		= ksACQ
	string	 	llllst		= LstDiac()
	string  	sValue	= UFCom_StringFromQuadList( wn, typ, cv, item , llllst,  ksDIA_WNDSEP, ksDIA_TYPSEP, ksDIA_CVSEP, ksDIA_ITEMSEP )
	//print "Diac_Parameter()   \t", sKey, sSection, svalue
	return	sValue
End

static Function	/S	Diac_Parameter_( sSection, wn, typ, cv, item )
// elementary retrieving function for Diac traces  
	string  	sSection				// e.g. the window name 'AW0'   or   'AW1'
	variable	wn, typ, cv, item
	string  	sFo 		= ksACQ
	string  	sValue	= Diac_Parameter( sSection, wn, typ+1, cv, item )
	//print "Diac_Parameter_()   \t", sKey, sSection, svalue
	return	sValue
End


static Function  	/S	 Diac_ParameterSet( sSection, wn, typ, cv, item, sValue )
// elementary storing function for any Diac  item ( window location and  traces )
	variable	wn, typ, cv, item
	string  	sSection				// e.g. the window name 'AW0'   or   'AW1'
	string  	sValue
	string  	sFo 		= ksACQ
	string	 	llllst	= LstDiac()
			llllst	= LstDiacSet( UFCom_ReplaceQuadListItem( sValue, wn, typ, cv, item, llllst, ksDIA_WNDSEP, ksDIA_TYPSEP, ksDIA_CVSEP, ksDIA_ITEMSEP ) )
	return	llllst										// returning the string just set simplifies debugging
End

static Function  	/S	 Diac_ParameterSet_( sSection, wn, typ, cv, item, sValue )
// derived storing function only for Diac traces  for which the index typ is offset by 1  because the window location occupies  index cv=0
	variable	wn, typ, cv, item
	string  	sSection				// e.g. the window name 'AW0'   or   'AW1'
	string  	sValue
	string  	sFo 		= ksACQ
	return	 Diac_ParameterSet( sSection, wn, typ+1, cv, item, sValue )	// returning the string just set simplifies debugging
End


//=====================================================================================================================================
//  LOADING  AND  SAVING THE  ACQUISITION  DISPLAY  CONFIGURATION

//  VERSION 1 :   THE  ACQUISITION  DISPLAY  CONFIGURATION  IS  STORED  IN  A  SEPARATE  'DIA'  FILE  (in a subdirectory of the scripts with the Extension  '.dia' )
// see and change also  'LoadDisplayCfgAcq()'

//static strconstant	ksDIA_EXT	= ".dia"
//
//Function	/S	DiacIniFile_Path( sFo, bCreate )
//	string  	sFo
//	variable	bCreate
//	return	UFPE_IniFile_PathFromScript( sFo, UFCom_ksINI_SUBDIR, ksDIA_EXT, bCreate )	// last param: Create file if it does not exist ?
//End
//
//Function	/S	DiacIniFile_Read( sFo )
//	string  	sFo
//	string  	sIniPath	= DiacIniFile_Path( sFo, UFCom_FALSE )	
//	string  	lst	= UFCom_ReadTxtFile( sIniPath ) 
//	return	lst
//End
//
//Function		DiacUpdateFile( sFo, llllst )
//	string  	sFo, llllst
//	string		sIniPath		= DiacIniFile_Path( sFo, UFCom_TRUE )	// last param: Create file if required
//	printf "\tDiacUpdateFile( '%s' ) :  wnds:%2d   llllstDiac: '%s...' \r",  sIniPath, DiacWndCnt(), llllst[0,300]
//	//UFCom_WriteTxtFile( sIniPath, llllst )
//	UFCom_WriteTxtFileDelayed( sIniPath, llllst )			// bad workaround to delay flushing the data to disk. Would be nice to avoid the settings file much too often when a window is moved or resized 
//End


//  VERSION 2 :   THE  ACQUISITION  DISPLAY  CONFIGURATION  IS  STORED  AS  AN  ENTRIY  IN THE HUGE  'INI'  FILE  (in a subdirectory of the scripts with the Extension  '.ini' )

Function	/S	DiacIniFile_Path( sFo, sSubFo, bCreate )
	string  	sFo
	string  	sSubFo		// e.g. 'Scrip'
	variable	bCreate
	string  	sIniBasePath	= ScriptPath( sFo )						// derive  IniPath  from Script path   as  sSubFoIni =  'Scrip'
	return	UFCom_IniFile_Path( sFo, sSubFo, sIniBasePath, bCreate )		// last param: Create file if required
End

Function	/S	DiacIniFile_Read( sFo, sSubFo )
	string  	sFo
	string  	sSubFo		// e.g. 'Scrip'
	string  	lst		= UFCom_Ini_Section( sFo, sSubFo, "Diac", "WndTraces" )
	return	lst
End

Function		DiacUpdateFile( sFo, sSubFo, llllst )
	string  	sFo, llllst
	string  	sSubFo		// e.g. 'Scrip'
	string		sIniPath	= DiacIniFile_Path( sFo, sSubFo, UFCom_TRUE )	// last param: Create file if required
	printf "\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\tDiacUpdateFile( '%s'   '%s'  -> '%s' ) :  wnds:%2d   llllstDiac: '%s...' \r",  sFo, sSubFo, sIniPath, DiacWndCnt(), llllst[0,300]

	string  	llllstIni	= UFCom_Ini_SectionSet( sFo, sSubFo, "Diac", "WndTraces", llllst )
	UFCom_WriteTxtFile( sIniPath, llllstIni )
	//UFCom_WriteTxtFileDelayed( sIniPath, llllst
//	string  	llllstIni	= UFCom_Ini_SectionSet( sFo, sSubFo, "Diac", "WndTraces", llllst )
//	UFCom_WriteTxtFile( sIniPath, llllstIni )
	//UFCom_WriteTxtFileDelayed( sIniPath, llllstIni )			// bad workaround to delay flushing the data to disk. Would be nice to avoid the settings file much too often when a window is moved or resized 
End
