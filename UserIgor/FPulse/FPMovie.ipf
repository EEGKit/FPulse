//
// FPMovie.ipf   :	Routines for	constructing and playing a QuickTime Movie (during evaluation)

// BAD  OLD  PANEL BUTTON  STYLE  -   DO NOT use this file for further development..........060712   (Use FPulse400m ++ instead)

#pragma rtGlobals=1										// Use modern global access method.
#pragma version=2

//=================================================================================================================================================================
//  MOVIES PANEL

strconstant	ksPN_MOVIE	= "movi"						// Cave :'Movie'  used in FEVAL new.  To gain full advantage of this string constant  ALL control names in this panel must be converted e.g. "root_uf_" + sFolder_ + " + ksPN_MOVIE + "_buStartMov0000" which  blows up the code quite a bit...

Function		fEvMoviesDlg_( s )
// Called when a button is pressed.  ALSO CALLED when moving the mouse over a button. 
	struct	WMButtonAction	&s
	if (  s.eventCode == kCCE_mouseup ) 
		MoviesPanel(  ksPN_MOVIE, 2, 70, kPN_DRAW ) 
	endif
End

Function		MoviesPanel( sWin, xPos , yPos, nMode  )
	string  	sWin	
	variable	xPos, yPos
	variable 	nMode	
	string  	sFBase		= "root:uf:"
	string  	sFSub		= ksfEVO_	
	string		sPnTitle		= "Movies"
	string		sDFSave	= GetDataFolder( 1 )							// The following functions do NOT restore the CDF so we remember the CDF in a string .
	PossiblyCreateFolder( sFBase + sFSub + sWin )
	stAdditionalMoviesVars( sWin )									// will construct additionally required variables and strings in the same folder as the panel variables. This in turn requires that  'MoviesPanel( .....kPANEL_INIT )' is called during initialisation.

	SetDataFolder sDFSave										// Restore CDF from the string  value
	InitMoviesPanel( sFBase + sFSub , sWin )							// fills big text wave  'sPnOptions' (=wPn)  with all information about the controls necessary to build the panel
	Panel3Sub(   sWin,	sPnTitle, 	sFBase + sFSub ,   xPos, yPos , nMode ) 	// Compute the location of panel controls and the panel dimensions. Draw the panel displaying and hiding needed/unneeded controls
	PnLstPansNbsAdd( ksfEVO,  sWin )
End


Function		InitMoviesPanel( sF, sPnOptions )
	string  	sF, sPnOptions
	string  	sPanelWvNm	= sF + sPnOptions 
	variable	n = -1, nItems = 35
	make /O /T /N=(nItems) 	$sPanelWvNm
	wave  /T	tPn		= 	$sPanelWvNm
	//				Type	 NxL Pos MxPo OvS	Tabs	Blks	Mode	Name		RowTi			ColTi			ActionProc	XBodySz	FormatEntry						Initval	Visibility	SubHelp
//	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:	,:	,:		dum4:		Movies:			:			:			:		:								:		:		:				"		
//	n += 1;	tPn[ n ] =	"BU:    1:	0:	6:	0:	°:	,:	1,°:		buMakeMov:	Make:			:			fMovieMake():	:		:								:		:		Make Movies:		"	//  	
//gh	n += 1;	tPn[ n ] =	"PM:	   1:	0:	9:	2:	°:	,:	1,°:		pmMovChan:	Chan:			Chn:			:			80:		fEvChanMovPops_():					~1:		:		Movie Channel:		"	// 	
//	n += 1;	tPn[ n ] =	"PM:	   1:	0:	9:	2:	°:	,:	1,°:		pmMovChan:	:				:			:			60:		fEvChanMovPops_():					~1:		:		Movie Channel:		"	// 	
	n += 1;	tPn[ n ] =	"PM:	   1:	0:	2:	0:	°:	,:	1,°:		pmMovChan:	:				Chan:		:			90:		fEvChanMovPops_):					~1:		:		Movie Channel:		"	// 	
	n += 1;	tPn[ n ] =	"SV:    0:	1:	2:	0:	°:	,:	1,°:		svBaseDur:	BaseDur/ms:		:			:			60:		%.1lf; 0,inf,0:						:		:		:				"	//
	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:	,:	,:		dum2:		:				:			:			:		:								:		:		:				"		
	n += 1;	tPn[ n ] =	"BU:    1:	0:	6:	0:	°:	,:	1,°:		buPlayMov:	Play:				:			fMoviePlay_():	:		:								:		:		Play Movies		"	//  	
	n += 1;	tPn[ n ] =	"BU:    0:	1:	6:	0:	°:	,:	1,°:		buStartMov:	Start:				:			fMovieStart_():	:		:								:		:		Start Movie:		"	//  	
	n += 1;	tPn[ n ] =	"BU:    0:	2:	6:	0:	°:	,:	1,°:		buStopMov:	Stop:				:			fMovieStop_():	:		:								:		:		Stop Movie:		"	//  	
	n += 1;	tPn[ n ] =	"BU:    0:	3:	6:	0:	°:	,:	1,°:		buRewdMov:	Rewind:			:			fMovieRewind_):	:		:								:		:		Start Movie:		"	//  	
	n += 1;	tPn[ n ] =	"BU:    0:	4:	6:	0:	°:	,:	1,°:		buInfoMov:	Info:				:			fMovieInfo_():	:		:								:		:		Movie Info:		"	//  	
	n += 1;	tPn[ n ] =	"BU:    0:	5:	6:	0:	°:	,:	1,°:		buKillMov:		Kill:				:			fMovieKill():	:		:								:		:		Kill Movie:			"	//  	

	redimension   /N=(n+1)	tPn
End


static Function		BaseDur( sFolders )
	string  	sFolders
	string  	sFolder1	= StringFromList( 0, sFolders, ":" ) + ":" + ksPN_MOVIE			// e.g.  'evo:de'  ->  'evo:'  ->  'evo:movi' 
	nvar		svBaseDur	= $"root:uf:" + sFolder1 + ":svBaseDur0000"	
	// printf "\t\t\tBaseDur( \t'%s' -> '%s' ) from variable: %gms \t-> %gs  \r", sFolders, sFolder1, svBaseDur, svBaseDur/1000
	return	svBaseDur/1000
End





static Function		stAdditionalMoviesVars( sWin )
// will construct additionally required variables and strings in the same folder as the panel variables 
	string  	sWin
	if ( WinType( sWin ) != kPANEL )
		variable	/G	bIsFirstMoviePict	= TRUE
		string  	/G	gsMoviePath		= ""
	endif
End


//=================================================================================================================================================================
//  MAKING  A  QUICKTIME  MOVIE  FROM  A  DAT-FILE

static strconstant	ksCTRLNAME_KILL	= "root_uf_evo_movi_buKillMov0000"				// !!! must contain 'movi' = ksPN_MOVIE
 	
 
Function		fEvChanMovPops_( sControlNm, sFo, sWin )
	string		sControlNm, sFo, sWin
	PopupMenu	$sControlNm,	win = $sWin,	value = ReplaceString( ksSEP_TAB, LstChan( "", "", "" ), ";" )
End

static Function		MovieChan( sFolders )
	string  	sFolders
	string  	sFolder1	= StringFromList( 0, sFolders, ":" ) + ":" + ksPN_MOVIE			// e.g.  'evo:de'  ->  'evo:'  ->  'evo:movi' 
	nvar		nMovieChan	= $"root:uf:" + sFolder1 + ":pmMovChan0000"	
	// printf "\t\t\tMovieChan( \t'%s' -> '%s' ) from variable: %d \t->'%s'  \r", sFolders, sFolder1, nMovieChan-1 , StringFromList( nMovieChan-1, ReplaceString( ksSEP_TAB, LstChan( sFolders ), ";" ) )
	return	nMovieChan - 1											// popmenu variables are 1-based
End

static Function	/S	MovieChanNm( sFolders )
	string  	sFolders
	string  	sFolder1	= StringFromList( 0, sFolders, ":" ) + ":" + ksPN_MOVIE						// e.g.  'evo:de'  ->  'evo:'  ->  'evo:movi' 
	nvar		nMovieChan	= $"root:uf:" + sFolder1 + ":pmMovChan0000"
	string  	sMovieChanNm	= StringFromList( nMovieChan-1, ReplaceString( ksSEP_TAB, LstChan( "", "", "" ), ";" ) )	
	// printf "\t\t\tMovieChanNm( \t'%s' -> '%s' ) from variable: %d \t->'%s'  \r", sFolders, sFolder1, nMovieChan-1 , sMovieChanNm
	return	sMovieChanNm
End


Function		fMoviePlay_( s )
	struct	WMButtonAction 	&s
	if (  s.eventCode == kCCE_mouseup ) 
		string  	sFolders		= ReplaceString( "root:uf:", GetUserData( s.win,  s.ctrlName,  "sFo" ), "" ) + s.win	// e.g.  'root:uf:evo:'  ->  'evo:'  ->  'evo:movi' 
		variable	ch			= MovieChan( sFolders )
		string  	sMoviePath	= SetMoviePath_( sFolders, ch )
		 printf "\t\tfMoviePlay()  \t%s\tch:%4d\t%s\t%s\t   \r", pd(sFolders,7), ch,  pd(s.ctrlName,29), pd(sMoviePath,29)
		PlayMovie		as sMoviePath	
		EnableButton( ksPN_MOVIE, ReplaceString( "Play", s.CtrlName, "Start" ), 	kENABLE )
		EnableButton( ksPN_MOVIE, ReplaceString( "Play", s.CtrlName, "Stop" ), 	kDISABLE )
		EnableButton( ksPN_MOVIE, ReplaceString( "Play", s.CtrlName, "Rewnd" ),  kDISABLE )
		EnableButton( ksPN_MOVIE, ReplaceString( "Play", s.CtrlName, "Info" ),  	kENABLE )
		EnableButton( ksPN_MOVIE, ReplaceString( "Play", s.CtrlName, "Kill" ),	kENABLE )
	endif
End

Function		fMovieStart_( s )
	struct	WMButtonAction 	&s
	if (  s.eventCode == kCCE_mouseup ) 
		string  	sMoviePath	= MoviePath_()
		PlayMovieAction	/Z	getID
		if ( V_Flag == 0 )									// only if there is a movie window
			variable 	nMovieID	= V_Value
			PlayMovieAction start
			 printf "\t\tfMovieStart() \t\t\t\t\t%s\t%s\tID: %2d\t   \r", pd(s.ctrlName,29),   pd(sMoviePath,39), nMovieID
			EnableButton( ksPN_MOVIE, ReplaceString( "Start", s.CtrlName, "Start" ),	kDISABLE )
			EnableButton( ksPN_MOVIE, ReplaceString( "Start", s.CtrlName, "Stop" ), 	kENABLE )
			EnableButton( ksPN_MOVIE, ReplaceString( "Start", s.CtrlName, "Rewnd" ),	kENABLE )
		endif
	endif
End

Function		fMovieStop_( s )
	struct	WMButtonAction 	&s
	if (  s.eventCode == kCCE_mouseup ) 
		string  	sMoviePath	= MoviePath_()
		PlayMovieAction	/Z	getID
		if ( V_Flag == 0 )									// only if there is a movie window
			variable 	nMovieID	= V_Value
			PlayMovieAction stop
			 printf "\t\tfMovieStop()  \t\t\t\t\t%s\t%s\tID: %2d\t   \r", pd(s.ctrlName,29),   pd(sMoviePath,39), nMovieID
		EnableButton( ksPN_MOVIE, ReplaceString( "Stop", s.CtrlName, "Start" ), kENABLE )
		EnableButton( ksPN_MOVIE, ReplaceString( "Stop", s.CtrlName, "Stop" ), kDISABLE )
		endif
	endif
End

Function		fMovieRewind_( s )
	struct	WMButtonAction 	&s
	if (  s.eventCode == kCCE_mouseup ) 
		string  	sMoviePath	= MoviePath_()
		PlayMovieAction	/Z	getID
		if ( V_Flag == 0 )									// only if there is a movie window
			variable 	nMovieID	= V_Value
			PlayMovieAction stop,gotoBeginning
			 printf "\t\tfMovieRewnd() \t\t\t\t\t%s\t%s\tID: %4d\t   \r", pd(s.ctrlName,29),  pd(sMoviePath,39), nMovieID
			EnableButton( ksPN_MOVIE, ReplaceString( "Rewnd",	s.CtrlName, "Start" ),		kENABLE )
			EnableButton( ksPN_MOVIE, ReplaceString( "Rewnd",	s.CtrlName, "Stop" ),		kDISABLE )
			EnableButton( ksPN_MOVIE, ReplaceString( "Rewnd",	s.CtrlName, "Rewnd" ),	kDISABLE )
		endif
	endif
End

Function		fMovieInfo_( s )
	struct	WMButtonAction 	&s
	if (  s.eventCode == kCCE_mouseup ) 
		// string  	sFolders	=   ReplaceString( "root:uf:", GetUserData( 	s.win,  s.ctrlName,  "sFo" )	, "" )  + s.win	// e.g.  'root:uf:evo:'  ->  'evo:'  ->  'evo:movi' 
		// nvar		state		= $ReplaceString( "_", s.ctrlName, ":" )								// the underlying button variable name is derived from the control name
		string  	sMoviePath	= MoviePath_()
		PlayMovieAction	/Z	getID
		if ( V_Flag == 0 )									// only if there is a movie window
			variable 	nMovieID	= V_Value
			PlayMovieAction stop,gotoEnd,getTime
			variable 	tEnd		= V_Value
			PlayMovieAction step=-1,getTime
			variable	tPict		= tEnd - V_value
			variable	nPicts	= tEnd / tPict
			// printf "\t\tfMovieInfo()  \t\t\t\t\t%s\t%s\tID: %4d\tDuration:%7.3lfs\t[%6.2lfms]\tFrames: %d\t   \r", pd(s.ctrlName,29),  pd(sMoviePath,39), nMovieID, tEnd, tPict*1000, nPicts
			printf "\tMovie Info  \t%s\tID: %4d\tDuration:%7.3lfs\t[%6.2lfms]\tFrames: %d\t   \r",  pd(sMoviePath,39), nMovieID, tEnd, tPict*1000, nPicts
		endif
	endif
End

Function		fMovieKill_( s )
	struct	WMButtonAction 	&s
	if (  s.eventCode == kCCE_mouseup ) 
		string  	sMoviePath	= MoviePath_()
		EnableButton( ksPN_MOVIE, ReplaceString( "Kill", s.CtrlName, "Start" ),  	kENABLE )	// after killing  movie n  we might land in the middle of movie  n-1....
		EnableButton( ksPN_MOVIE, ReplaceString( "Kill", s.CtrlName, "Rewnd" ),  	kENABLE )	// ...so we should allow the user to continue or rewind from this position
	
		if ( MovieKill_( s.CtrlName ) )													// Check if we just killed the LAST movie window.  0  means there is still a movie window left,    != 0 means  there is no movie window left
			EnableButton( ksPN_MOVIE, ReplaceString( "Kill", s.CtrlName, "Kill" ), 	  kDISABLE )	// We just killed the LAST movie window so we disable the Info, Start, Stop and Kill buttons which will be enabled again when a new movie is played. 
			EnableButton( ksPN_MOVIE, ReplaceString( "Kill", s.CtrlName, "Start" ),  kDISABLE )
			EnableButton( ksPN_MOVIE, ReplaceString( "Kill", s.CtrlName, "Stop" ),  kDISABLE )
			EnableButton( ksPN_MOVIE, ReplaceString( "Kill", s.CtrlName, "Rewnd"), kDISABLE )	 
			EnableButton( ksPN_MOVIE, ReplaceString( "Kill", s.CtrlName, "Info"  ),  kDISABLE )
		endif
	endif
End
	
Function		MovieKill_( sCtrlName )
	string  	sCtrlName
	PlayMovieAction /Z getID
	if ( V_Flag == 0 )									// only if there is a movie window	( ToDo?? similar to and possibly unify with  MovieExists_() )
		variable 	nMovieID	= V_Value
		 printf "\t\tfMovieKill()  \t\t\t\t\t%s\t\t\t\t\t\t\t\tID: %2d\tFlag: %d   \r", pd(sCtrlName,29),  nMovieID, V_Flag
		PlayMovieAction kill
		PlayMovieAction /Z getID						// Check if we just killed the LAST movie window. In this case we disable the Info, Start, Stop and Kill buttons which will be enabled again when a new movie is played. 
	endif
	return	V_Flag								// if   V_Flag == 0  there is still a movie window left,  if   V_Flag != 0  there is no movie window left
End

Function		MovieKillAll_( sCtrlNameKill )
	string  	sCtrlNameKill
	do
		;
	while ( ! MovieKill_( sCtrlNameKill ) )
	EnableButton( ksPN_MOVIE, ReplaceString( "Kill", sCtrlNameKill, "Kill" ),	kDISABLE )	// We just killed the LAST movie window so we disable the Info, Start, Stop and Kill buttons which will be enabled again when a new movie is played. 
	EnableButton( ksPN_MOVIE, ReplaceString( "Kill", sCtrlNameKill, "Start" ),	kDISABLE )
	EnableButton( ksPN_MOVIE, ReplaceString( "Kill", sCtrlNameKill, "Stop" ),	kDISABLE )
	EnableButton( ksPN_MOVIE, ReplaceString( "Kill", sCtrlNameKill, "Rewnd"),	kDISABLE )	 
	EnableButton( ksPN_MOVIE, ReplaceString( "Kill", sCtrlNameKill, "Info"  ), 	kDISABLE )
End

//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//Function		MovieAddGraph_( sFolders, ch, nCurSwp, nSize, dsFirst, dsLast )
//	string  	sFolders
//	variable	ch, nCurSwp, nSize, dsFirst, dsLast
//	string  	sMoviePath	= ""
//	string  	sTxt			= ""
//	variable	DataUnitDur	= 0
//	variable	PictureRate	= 0									// allowed are 1 ... 60 pictures / second
//	if ( ch == MovieChan( sFolders ) )
//
//		sMoviePath	= SetMoviePath_( sFolders, ch )
//
//		// Igor lets you play, open, start and stop multiple movies at a time.  However, all of them must be closed before Igor can only BUILD 1 movie at a time : calling  'AddMovieFrame'  with an open movie gives an error.
//		MovieKillAll_( ksCTRLNAME_KILL ) 											// This disables the buttons Start, Stop, Rewind and Info but we should also disable movie playing while we are constructing a new movie...
//		EnableButton( ksPN_MOVIE, ReplaceString( "Kill", ksCTRLNAME_KILL, "Play" ), kDISABLE )// ....Actually Igor prevents playing in this case but by disabling the button the user sees that this is impossible.
//		
//		// Now there is no movie open for display so we can now construct one.
//		// Make the selected channel the active window so that the selected data are added to the movie (without this always the last channel is active)
//		DoWindow /F	$EvalWndNm( ch )
//		GetAxis	 /Q	bottom
//		DataUnitDur	= V_max - V_min
//		PictureRate	= clip( 1, 1 / DataUnitDur, 60 )
//		if ( PictureRate  !=  1 / DataUnitDur )
//			Alert( kERR_IMPORTANT, "Only  picture rates from 1 to 60 /s are allowed. The desired picture rate of " + num2str( 1 / DataUnitDur ) + " has been adjusted to this range." )
//		endif
//		// Check if is the first picture of the movie (then we must open the movie) or if we are in the middle of the movie.  The first picture is often but not necessarily the first DAT file data unit.  
//		// Unfortunate this code CANNOT be located before 'DSDisplayAndAnalyse()'  (symmetrically to 'CloseMovie')  as the graph must have been constructed before 'NewMovie' can be called.
//		if ( GVar( "root:uf:evo:" + ksPN_MOVIE + ":bIsFirstMoviePict" ) )
//			NewMovie 	/Z	/O /F = (PictureRate)	as sMoviePath						// 	Skip		movie settings dialog
//			// NewMovie 	/Z /I	/O				as sMoviePath						// /I: Display	movie settings dialog
//			sTxt				= "First picture of the one and only movie"
//		else
//			sTxt				= "Additional picture of the one and only movie"
//		endif
//
//		SetGVar( "root:uf:evo:" + ksPN_MOVIE + ":bIsFirstMoviePict", FALSE )
//	
//		DoUpdate
//		AddMovieFrame
//
//		 printf "\t\tMovieAddGraph\t%s\tch:%2d\t cu:%4d\tFiLa:%3d/%3d\tsz:\t%6d\tMovieID+1:=%2d \t[=Id+1]\tDataUnitDur:\t%7g\t%s   \r",  pd(sFolders,7), ch, nCurSwp, dsFirst, dsLast, nSize, MovieID_()+1, DataUnitDur, sTxt
//	endif
//End

// 060821  base line
Function		MovieAddGraph_( sFolders, ch, nCurSwp, nSize, dsFirst, dsLast )
	string  	sFolders
	variable	ch, nCurSwp, nSize, dsFirst, dsLast
	string  	sMoviePath	= ""
	string  	sTxt			= ""
	variable	DataUnitDur	= 0
	variable	PictureRate	= 0									// allowed are 1 ... 60 pictures / second
	if ( ch == MovieChan( sFolders ) )

		sMoviePath	= SetMoviePath_( sFolders, ch )

		// Igor lets you play, open, start and stop multiple movies at a time.  However, all of them must be closed before Igor can only BUILD 1 movie at a time : calling  'AddMovieFrame'  with an open movie gives an error.
		MovieKillAll_( ksCTRLNAME_KILL ) 											// This disables the buttons Start, Stop, Rewind and Info but we should also disable movie playing while we are constructing a new movie...
		EnableButton( ksPN_MOVIE, ReplaceString( "Kill", ksCTRLNAME_KILL, "Play" ), kDISABLE )// ....Actually Igor prevents playing in this case but by disabling the button the user sees that this is impossible.
		
		// Now there is no movie open for display so we can now construct one.
		// Make the selected channel the active window so that the selected data are added to the movie (without this always the last channel is active)
		string  	sWNm	= EvalWndNm( ch )

		// To compute the base line we retrieve the data wave by first getting the data trace. For this we strip cursor and average traces.  !!! Possibly we have to strip additional traces !!!
		string  	sTNL 	= "", 	lstCursors 	= "", lstAvg = "", sDataTrc = ""
		variable	nTraces 	= 0, 	BaseVal 	= 0
		variable	BaseDuration	= BaseDur( sFolders )						//  in seconds , 0 means no subtraction of the base value
		if ( BaseDuration )
			sTNL		= TraceNameList( sWNm, ";", 1 )
			lstCursors		= ListMatch( sTNL, "wcY_*" )			// !!! Assumption cursor waves have the name 'wcY_...'
			lstAvg		= ListMatch( sTNL, "wAvg*" )			// !!! Assumption Average waves have the name 'wAvg...'
			sTNL		= RemoveFromList( lstCursors, sTNL )
			sTNL		= RemoveFromList( lstAvg, sTNL )
			nTraces		= ItemsInList( sTNL )
			if ( nTraces == 1 )
				sDataTrc	= StringFromList( 0, sTNL )
			else
				Alert( kERR_IMPORTANT, "There is more than 1 data trace in the window (= '" + sTNL + "' ). The base line is computed and subtracted from the first trace which may not be correct." )
			endif
					
			wave	wData	= TraceNameToWaveRef( sWNm, sDataTrc )
			BaseVal	= fAverage( wData, leftX( wData ) , leftX( wData ) + BaseDuration )
			wData	= wData - BaseVal
		endif

//		DoWindow /F	sWNm 
		DoWindow /F	$sWNm
		GetAxis	 /Q	bottom
		DataUnitDur	= V_max - V_min
		PictureRate	= clip( 1, 1 / DataUnitDur, 60 )
		if ( PictureRate  !=  1 / DataUnitDur )
			Alert( kERR_IMPORTANT, "Only  picture rates from 1 to 60 /s are allowed. The desired picture rate of " + num2str( 1 / DataUnitDur ) + " has been adjusted to this range." )
		endif
		// Check if is the first picture of the movie (then we must open the movie) or if we are in the middle of the movie.  The first picture is often but not necessarily the first DAT file data unit.  
		// Unfortunate this code CANNOT be located before 'DSDisplayAndAnalyse()'  (symmetrically to 'CloseMovie')  as the graph must have been constructed before 'NewMovie' can be called.
		if ( GVar( "root:uf:evo:" + ksPN_MOVIE + ":bIsFirstMoviePict" ) )
			NewMovie 	/Z	/O /F = (PictureRate)	as sMoviePath						// 	Skip		movie settings dialog
			// NewMovie 	/Z /I	/O				as sMoviePath						// /I: Display	movie settings dialog
			sTxt				= "First picture of the one and only movie"
		else
			sTxt				= "Additional picture of the one and only movie"
		endif

		SetGVar( "root:uf:evo:" + ksPN_MOVIE + ":bIsFirstMoviePict", FALSE )
	
		DoUpdate
		AddMovieFrame

		 printf "\t\tMovieAddGraph\t%s\tch:%2d\t cu:%4d\tFiLa:%3d/%3d\tsz:\t%6d\tMovieID+1:=%2d \t[=Id+1]\tDataUnitDur:\t%7g\t%s\t1=?=%d\t%s\tBase:%g\t  \r",  pd(sFolders,7), ch, nCurSwp, dsFirst, dsLast, nSize, MovieID_()+1, DataUnitDur, pd(sTxt,36), nTraces, sTNL[0,100], BaseVal
	endif
End


Function		MovieClose_()
	CloseMovie						
	SetGVar( "root:uf:evo:" + ksPN_MOVIE + ":bIsFirstMoviePict", TRUE )
	EnableButton( ksPN_MOVIE, ReplaceString( "Kill", ksCTRLNAME_KILL, "Play" ),	kENABLE )// Movie construction is finished so we allow playing again.
End


Function	/S	SetMoviePath_( sFolders, ch )
	string  	sFolders
	variable	ch
	string  	sMovieNm		= StripPathAndExtension( CfsRdDataPath() ) + "_" + MovieChanNm( sFolders )	// no extension!
	string  	sMoviePath	= ksEVOMOVIE_DIR + sMovieNm									// no extension!
	// printf "\t\t\tSetMoviePath( %s ) returns '%s' \r", sFolders, sMoviePath
	return	SetGString( "root:uf:evo:" + ksPN_MOVIE + ":gsMoviePath" ,  sMoviePath )
End

Function	/S	MoviePath_()
	return	GString( "root:uf:evo:" + ksPN_MOVIE + ":gsMoviePath" )
End


Function		MovieID_()
// Returns movie ID if there is a movie  or  else  -1 (kNOTFOUND)
// Assumption:  I assume that there is no valid movie ID -1.  	  If -1 is a valid movie ID then an additional function  'MovieExists_()'  returning the V_Flag is required.
	PlayMovieAction	/Z	getID
	if ( V_Flag == 0 )												// only if there is a movie window
		return	V_Value
	endif
	return	kNOTFOUND
End


Function		MovieExists_()
	variable	code	= MovieID_() == kNOTFOUND	?	FALSE	: TRUE
	return	code
End


// 060705	Currently not needed
//Function		MovieFileExists( sMoviePath )
//	string  	sMoviePath										// no extension!
//	if ( FileExists( sMoviePath + ".mov" )   &&  FileExists( sMoviePath + ".#res" ) )
//		return	TRUE
//	endif
//	return	FALSE
//End






//Macro MakeMovie(fcarier,fmod,mampMax,nframes,wAudio,showDialog)
//	Variable fcarier=NumVarOrDefault("gFCarier",500)
//	Variable fmod=NumVarOrDefault("gFmod",300)
//	Variable mampMax=NumVarOrDefault("gmampMax",4)
//	Variable nframes=NumVarOrDefault("gnframes",10)
//	Variable wAudio=NumVarOrDefault("gwAudio",2)
//	Variable showDialog=NumVarOrDefault("gshowDialog",1)
//	Prompt fcarier,"Carier frequency"
//	Prompt fmod,"Modulation frequency"
//	Prompt mampMax,"Max Modulation Index"
//	Prompt nframes,"Number of movie frames"
//	Prompt wAudio,"Sound:",popup "Off;On"
//	Prompt showDialog,"Compression Dialog:",popup "No;Yes"
//	
//	Variable/G gFCarier= fCarier
//	Variable/G gFmod= fmod
//	Variable/G gmampMax= mampMax
//	Variable/G gnframes= nframes
//	Variable/G gwAudio= wAudio
//	Variable/G gshowDialog= showDialog
//	
//	DoMakeMovie(fcarier,fmod,mampMax,nframes,wAudio-1,showDialog-1)
//end
//
//	
//
//Function DoMakeMovie(fcarier,fmod,mampMax,nframes,wAudio,showDialog)
//	Variable fcarier,fmod,mampMax,nframes,wAudio,showDialog
//	
//	if( wAudio)
//		if( showDialog )
//			NewMovie/Z/I/O/P=home/S=jack as "movie with audio2"
//		else
//			NewMovie/Z/O/P=home/S=jack as "movie with audio2"
//		endif
//	else
//		if( showDialog )
//			NewMovie/Z/I/O/P=home as "movie without audio1"
//		else
//			NewMovie/Z/O/P=home as "movie without audio1"
//		endif
//	endif
//	if( V_Flag!=0 )
//		return 0			// probably canceled
//	endif
//	variable mamp=0,minc= (mampMax-mamp)/nframes,i=0
//	fcarier *= 2*Pi; fmod *= 2*Pi
//	WAVE jack
//	do
//		jack=120*sin( fcarier*x + mamp*sin(fmod*x) )
//		Duplicate/o jack,fred
//		Hanning fred
//		Redimension/N=(2^ceil(log(numpnts(fred))/log(2))) fred
//		FFT fred
//		Wave/C fredC= fred
//		fredC=r2polar(fred)
//		Redimension/R fredC
//		DrawInset(mamp)
//		DoUpdate
//		AddMovieFrame
//		if( wAudio )
//			AddMovieAudio jack
//		endif
//		mamp += minc
//		i += 1
//	while(i<nframes)
//	CloseMovie
//	if( wAudio)
//		PlayMovie/P=home as "movie with audio2"
//	else
//		PlayMovie/P=home as "movie without audio1"
//	endif
//end
//
//
//Function DrawInset(mamp)
//	Variable mamp
//	
//	Variable x0=0.5,y0=0.1,x1=0.9,y1=0.4,npts=50
//	SetDrawLayer/K ProgFront
//	SetDrawEnv xcoord= rel,ycoord= rel,linefgc= (0,0,65535),fillfgc= (65535,54607,32768)
//	SetDrawEnv save
//	SetDrawEnv linethick= 0
//	DrawRect x0,y0,x1,y1
//	SetDrawEnv fillpat= 0
//	Duplicate/O/R=[0,npts] jack,sjack,sjackx
//	sjack= 0.8*(y0-y1)*(sjack/240)				// NOTE: wave offset does not matter. Set by DrawPoly origin
//	sjackx= (x1-x0)*P/npts
//	DrawPoly x0,(y1+y0)/2,1,1,sjackx,sjack	// we rely on first point being zero (sin(0))
//	SetDrawEnv fsize= 10
//	DrawText 0.51,0.081,"Inset: first few cycles"
//	String s
//	sprintf s,"Mod index: %.2f",mamp
//	DrawText 0.64,0.52,s
//	SetDrawLayer UserFront
//End
//
//Window Graph1() : Graph
//	PauseUpdate; Silent 1		// building window...
//	Display /W=(5.25,44,399.75,251.75) fred
//	ModifyGraph highTrip(left)=100000
//	Label left "Amplitude"
//	Label bottom "Frequency,\\U"
//	SetAxis left 0,40000
//	SetDrawLayer ProgFront
//	SetDrawEnv xcoord= rel,ycoord= rel,linefgc= (0,0,65535),fillfgc= (65535,54607,32768)
//	SetDrawEnv save
//	SetDrawEnv linethick= 0
//	DrawRect 0.5,0.1,0.9,0.4
//	SetDrawEnv fillpat= 0
//	DrawPoly 0.5,0.25,1,1,sjackx,sjack
//	SetDrawEnv fsize= 10
//	DrawText 0.51,0.081,"Inset: first few cycles"
//	DrawText 0.64,0.52,"Mod index: 3.60"
//	SetDrawLayer UserFront
//EndMacro

