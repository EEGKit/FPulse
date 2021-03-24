//  FEvalFit.ipf 

//  Fit functions to be edited by the userF

#pragma rtGlobals=1							// Use modern global access method.

// Popupmenu indexing for fit functions																																
static	 constant 					FT_LINE = 0,	FT_1EXP = 1,	FT_1EXPCONST=2,	FT_2EXP = 3,			FT_2EXPCONST=4,			FT_RISE = 5,		FT_RISECONST = 6,		   FT_RISDEC = 7,				FT_RISDECCONST = 8 
static strconstant	klstFITFUNC	= "Line;		1 Exp;		1 Exp+C;			2 Exp;				2 Exp+C;					Rise;				Rise+C;				   RiseDec;					RsDecC"											
static strconstant	kllstPARAMS	= "Co,au|Sl,?;	A0,au|T0,ms;	A0,au|T0,ms|Co,au;	A0,au|T0,ms|A1,au|T1,ms;	A0,au|T0,ms|A1,au|T1,ms|Co,au;	RT,ms|De,ms|Am,au;	RT,ms|De,ms|Am,au|Co,au;   RT,ms|De,ms|Am,au|Ta,ms|TS,ms;	RT,ms|De,ms|Am,au|Ta,ms|TS,ms|Co,au;"	// the name must consist of 2 characters for the automatic name-building/extracting to work
static strconstant	kllstDERIVEDU	= "	;			;			;			WTau,ms|Cap,pF;		WTau,ms|Cap,pF;			;				;					   ;							;			"
// 051011 Sample code for using different units e.g.   V, s, us, nF, pA, nA 
// static strconstant	kllstPARAMS	= "Co,au|Sl,?;	A0,au|T0,ms;	A0,au|T0,ms|Co,au;	A0,V|T0,us|A1,au|T1,s;	A0,pA|T0,ms|A1,nA|T1,ms|Co,au;	RT,ms|De,ms|Am,au;	RT,ms|De,ms|Am,au|Co,au;   RT,ms|De,ms|Am,au|Ta,ms|TS,ms;	RT,ms|De,ms|Am,au|Ta,ms|TS,ms|Co,au;"	// the name must consist of 2 characters for the automatic name-building/extracting to work
// static strconstant	kllstDERIVEDU	= "	;			;			;			WTau,s|Cap,nF;		WTau,ms|Cap,pF;			;				;					   ;							;			"


static	constant		FITINFO_FNC 	= 0, FITINFO_BEG = 1,  FITINFO_END = 2,  FITINFO_ITER = 3,  FITINFO_MAXITER = 4,  FITINFO_CHISQR = 5 	// indices for  'klstFITINFO'   and  for  'wInfo' 
static strconstant	klstFITINFO	= "Fnc;Beg;End;Iter;MxIter;Chisqr;"


//-----------  Extracting from klstFITFUNC  -----------------------------------------------------------------------------

Function	/S	ListFitFunctions()
// Return list with all fit function names. For improved code readability there are tabs and blanks inserted between the fit function names which must be removed before feeding the listbox, which is done here.
	variable	n
	string  	lstCleaned = ""
	for ( n = 0; n < ItemsInList( klstFITFUNC ); n += 1 )
		lstCleaned	= AddListItem( FitFuncNm_( n ), lstCleaned ,  ";" ,  inf )
	endfor
	return	lstCleaned
End

Function	/S	FitFuncNm_( nFitFunc )
	variable	nFitFunc
	return	RemoveLeadingWhiteSpace( StringFromList( nFitFunc, klstFITFUNC ) )		// Tabs and blanks inserted for improved code readability are removed here
End

//-----------  Extracting from kllstPARAMS  -----------------------------------------------------------------------------

Function	/S	ListParamNames( nFitFunc )			
	variable	nFitFunc
	return	RemoveLeadingWhiteSpace( StringFromList( nFitFunc, kllstPARAMS, ";" ) )	// !!! Assumption separator
End

Function		ParCnt( nFitFunc )		
	variable	nFitFunc
	return	ItemsInList( ListParamNames( nFitFunc ), "|" )						// !!! Assumption separator
End

Function	/S	ParAndUnit( nFitFunc, nPar )			
	variable	nFitFunc, nPar
	return	StringFromList( nPar, ListParamNames( nFitFunc ) , "|" )					// e.g.   'T0,ms'  or   'A0,au'	 !!! Assumption separator
End

Function	/S	ParName( nFitFunc, nPar )			
	variable	nFitFunc, nPar
	return	StringFromList( 0, ParAndUnit( nFitFunc, nPar ), "," )					// e.g.   'T0'  	or   'A0'		 !!! Assumption separator
End

Function	/S	ParUnit( nFitFunc, nPar )			
	variable	nFitFunc, nPar
	return	StringFromList( 1, ParAndUnit( nFitFunc, nPar ), "," )					// e.g.   'ms'  	or   'pF'		 !!! Assumption separator
End	

//-----------  Extracting from kllstDERIVEDU  -----------------------------------------------------------------------------

Function	/S	ListDerivedAndUnits( nFitFunc )			
	variable	nFitFunc
	return	RemoveLeadingWhiteSpace( StringFromList( nFitFunc, kllstDERIVEDU, ";" ) )// e.g.   'Tau,ms|Cap,pF|;		!!! Assumption separator
End

Function		DerivedCnt( nFitFunc )		
	variable	nFitFunc
	return	ItemsInList( ListDerivedAndUnits( nFitFunc ), "|" )						// !!! Assumption separator
End

Function	/S	DerivedAndUnit( nFitFunc, nPar )			
	variable	nFitFunc, nPar
	return	StringFromList( nPar, ListDerivedAndUnits( nFitFunc ) , "|" )				// e.g.   'Tau,ms'  or   'Cap,pF'	 !!! Assumption separator
End

Function	/S	DerName( nFitFunc, nPar )			
	variable	nFitFunc, nPar
	return	StringFromList( 0, DerivedAndUnit( nFitFunc, nPar ), "," )				// e.g.   'Tau'  	or   'Cap'		 !!! Assumption separator
End

Function	/S	DerUnit( nFitFunc, nPar )			
	variable	nFitFunc, nPar
	return	StringFromList( 1, DerivedAndUnit( nFitFunc, nPar ), "," )				// e.g.   'ms'  	or   'pF'		 !!! Assumption separator
End




Function	/S	Fit_Unit_( ch, pt, nFitFunc )
// return the 'units' string  including the unit separators   which  can be    '/' and ''  =  Peak/mV      or    '['  and  ']'   =  Peak[mV]
	variable	ch, pt, nFitFunc 
	
	// !!! Assumption: depends on ordering
	string  	sUnit	= ""
	variable nPar, nParBeg
	nParBeg	= FitInfoCnt() + 2 * ParCnt( nFitFunc ) 
	if ( pt >= nParBeg )
		nPar	   = pt - nParBeg									// The derived fit parameters
		sUnit	   = RemoveLeadingWhiteSpace( DerUnit( nFitFunc, nPar ) )  
	else
		nParBeg	= FitInfoCnt() + 1 * ParCnt( nFitFunc )   
		if ( pt >= nParBeg )
			nPar    = pt - nParBeg								// The fit start parameters
			sUnit	   = RemoveLeadingWhiteSpace( ParUnit( nFitFunc, nPar ) )  
		else
			nParBeg	= FitInfoCnt() 
			if ( pt >= nParBeg )					
				nPar    = pt - nParBeg							// The fit parameters
				sUnit	   = RemoveLeadingWhiteSpace( ParUnit( nFitFunc, nPar ) )  
			else
				nPar = kNOTFOUND							// The FitInfo has no units
				sUnit	   = ""								// The FitInfo has no units
				// return	""								// The FitInfo has no units
			endif
		endif
	endif

	// printf "\t\t\tFit_Unit_ a( ch:%2d  pt:%2d\tfnc:%2d )\t-> nPar :%2d\t'%s' \r", ch, pt, nFitFunc , nPar, sUnit	// 051010
	sUnit	= AutoUnit( sUnit, ch ) 								// convert  'au'  into  'pA'  or  'mV'

	// printf "\t\t\tFit_Unit_ b( ch:%2d  pt:%2d\tfnc:%2d )\t-> nPar :%2d\t'%s' \r", ch, pt, nFitFunc , nPar, sUnit	// 051010
	if ( strlen( sUnit ) )
		sUnit	= ksSEP_UNIT1 + sUnit + ksSEP_UNIT2 		// e.g. can be    '/' and ''  =  Peak/mV      or   '['  and  ']'   =  Peak[mV]
	endif
	// printf "\t\tEval_Unit__( ch:%2d , pt:%3d )\t->\t%s\t + '%s' \r", ch, pt, pd( EvalNm( pt ), 9 ), sUnit
	return	sUnit
End	

Function	/S	AutoUnit( sUnit, ch ) 
	string  	sUnit
	variable	ch
	if ( cmpstr( sUnit, "au" ) == 0 )
		sUnit		= FileChanYUnits( ch )				// mV  or  pA  depending on...
	elseif ( cmpstr( sUnit, "U2" ) == 0 )
		sUnit		= "u2"							// mV  or  pA  depending on...
	elseif ( cmpstr( sUnit, "MO" ) == 0 )
		sUnit		= "MOhm"
	endif
	return	sUnit
End


//-----------  Extracting from klstFITINFO  ------------------------------------------------------------------------------

 Function	/S	FitInfoNm( nFitInfo )
	variable	nFitInfo
	return	StringFromList( nFitInfo, klstFITINFO )
End

Function		FitInfoCnt()
	return	ItemsInList( klstFITINFO )
End

//------------  Extracting from kllstPARAMS  -----------------------------------------------------------------------------------

Function		SetFitInfo( wInfo, nFitFunc, Left, Right, NumIters, MaxIters, chisq )
	wave	wInfo
	variable	nFitFunc, Left, Right, NumIters, MaxIters, chisq
	wInfo[ FITINFO_FNC ]	  = nFitFunc
	wInfo[ FITINFO_BEG ]	  = Left
	wInfo[ FITINFO_END ]	  = Right
	wInfo[ FITINFO_ITER ]	  = NumIters
	wInfo[ FITINFO_MAXITER]  = MaxIters
	wInfo[ FITINFO_CHISQR ]	  = chisq
End 

Function		FitInfoNFnc( wInfo )
	wave	wInfo
	return	wInfo[ FITINFO_FNC ]
End 

Function		FitInfoNIter( wInfo )
	wave	wInfo
	return	wInfo[ FITINFO_ITER ]
End 

Function		FitInfoMaxIter( wInfo )
	wave	wInfo
	return	wInfo[ FITINFO_MAXITER ]
End 

Function		FitInfoChiSqr( wInfo )
	wave	wInfo
	return	wInfo[ FITINFO_CHISQR ]
End 

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

 Function		SetStartParams( wPar, w, ch, rg, fi, nFitFunc, Left, Right )
// Returns  whether  starting parameters could be computed
	wave  	/D wPar
	wave	w
	variable	ch, rg, fi, nFitFunc, Left, Right
	string  	sMsg
	
	variable	nSmoothPts	= 5
	variable	nPnts		= numPnts( w )		// the points in the range to be fitted 

	if ( nPnts < nSmoothPts )

		sprintf sMsg, "Cannot fit '%s'  (channel:%d  region:%d  Fit:%d) : range to be fitted is off screen or contains too few (%d)  points.", FitFuncNm_( nFitFunc ), ch, rg, fi, nPnts
		Alert( kERR_IMPORTANT,  sMsg )
		wPar	= Nan						// or return error code
		return	FALSE			
	else  

		// Compute the starting values right here.  Another approach would be to use previously computed values for  RT2080, Amp, ...
		if ( nFitFunc == FT_RISE  ||  nFitFunc == FT_RISECONST ||  nFitFunc == FT_RISDEC  ||  nFitFunc == FT_RISDECCONST )
			variable	x20, x80, RT2080, Delay, Amp, Dip, TauDecay, Level
			Wavestats  /Q	w											// Get minimum and maximum of wave
			if ( GetRTError( 0 ) )											// Workaround / cripple code : it seems that ( in other program locations )  the  WavStats  error is mixed up with the  FindLevel  error  .....
				print "****Internal warning : SetStartParams() : " + GetRTErrMessage()
				variable dummy = GetRTError( 1 )
				return	FALSE
			endif
	//		if ( V_Flag )
	//			sprintf sMsg, "While fitting '%s'  (channel:%d  region:%d  fit:%d)  WaveStats gave error in range %.2lf..%.2lfms .", pd( FitFuncNm_( nFitFunc ),9), ch, rg, fi, Left, Right
	//			Alert( kERR_IMPORTANT,  sMsg )
	//		endif
			Amp		= V_max
			Dip		= V_min
			Level	= .2
	
			FindLevel	  /Q			  /B=(nSmoothPts)  w  V_min + Level * ( Amp - Dip )		// Find the 20% crossing  going forward  (averaging box is 5 points wide) 
			x20		= PossiblyReportFindLevelError( V_Flag,  V_LevelX, ch, rg, fi, nFitFunc, Left, Right, Level, Dip, Amp ) 
			Level	= .8
			FindLevel	 /Q			  /B=(nSmoothPts)  w  V_min + Level * ( Amp - Dip )		// Find the 80% crossing  going forward  (averaging box is 5 points wide)
			x80		= PossiblyReportFindLevelError( V_Flag,  V_LevelX, ch, rg, fi, nFitFunc, Left, Right, Level, Dip, Amp ) 
			RT2080	= x80 - x20
			Delay	= x20  											// 	delay		TODO: better start value for  delay is intersection of RT2080 with baseline
		endif
		if ( nFitFunc == FT_RISDEC  ||  nFitFunc == FT_RISDECCONST )	
			Level	= .2
			FindLevel	 /Q  /R=( Inf, 0 )  /B=(nSmoothPts)  w   V_min + Level * ( Amp - Dip ) 		// Find the 20% crossing  going backward  (averaging box is 5 points wide)
			x20		= PossiblyReportFindLevelError( V_Flag,  V_LevelX, ch, rg, fi, nFitFunc, Left, Right, Level, Dip, Amp ) 
			Level	= .8
			FindLevel	 /Q  /R=( Inf, 0 )  /B=(nSmoothPts)  w   V_min + Level * ( Amp - Dip ) 		// Find the 80% crossing  going backward  (averaging box is 5 points wide)
			x80		= PossiblyReportFindLevelError( V_Flag,  V_LevelX, ch, rg, fi, nFitFunc, Left, Right, Level, Dip, Amp ) 
			TauDecay	= x20 - x80										// TauDecay		TODO: better start value for  TauDecay is intersection  with baseline
		endif
		
		// printf "\tSetStartParams()  \tnFitFunc:%d  %s \tParams:%d   L:%6.3lf  R:%6.3lf   w( 0.0 ) : %6.3lf\t w( R-L %6.3lf ) : %6.3lf\t \r", nFitFunc, pd( FitFuncNm_( nFitFunc ),9), numPnts( wPar ), Left, Right, w( 0 ), Right-Left, w( Right-Left ) 
	
		if ( 	nFitFunc   == FT_LINE )							// straight line
			wPar[ 0 ] = w[ 0 ]  								//	y value at left region border = intersection value with an y axis shifted to begin of region 
			wPar[ 1 ] = ( w( Right  - Left ) - w( 0 ) ) / ( Right - Left )		//	the slope
	
		elseif ( 	nFitFunc   == FT_1EXP )						// 1 exponential  without constant		(LSLIB.pas : 21)
			wPar[ 0 ] = w[ 0 ] 								// 	y value at left region border = intersection value with an y axis shifted to begin of region 
			wPar[ 1 ] =  ( Right - Left ) / 4 						// 	Tau
	
		elseif ( nFitFunc == FT_1EXPCONST )						// 1 exponential  	with	 constant		(LSLIB.pas : 20)
			wPar[ 0 ] = w( 0 ) - w( Right - Left )					// 	y value at left region border = intersection value with an y axis shifted to begin of region  with constant offset subtracted
			wPar[ 1 ] =  ( Right - Left ) / 4 						// 	Tau
			wPar[ 2 ] = w( Right - Left )							// 	const offset 
			
		elseif ( nFitFunc == FT_2EXP )							// 2 exponentials without constant		(LSLIB.pas : 21)
			wPar[ 0 ] =  w( 0 ) / 2								//	 y value at left region border = intersection value with an y axis shifted to begin of region 
			wPar[ 1 ] =  ( Right - Left ) / 10 						// 	TauFast
			wPar[ 2 ] = wPar[ 0 ] 								// 	AmpSlow
			wPar[ 3 ] = wPar[ 1 ] * 5							// 	TauSlow
	
		elseif ( nFitFunc == FT_2EXPCONST )						// 2 exponentials  	with	 constant		(LSLIB.pas : 20)
			wPar[ 0 ] = ( w( 0 ) - w( Right - Left ) ) / 2				// 	y value at left region border = intersection value with an y axis shifted to begin of region 
			wPar[ 1 ] =  ( Right - Left ) / 10 						// 	TauFast
			wPar[ 2 ] = wPar[ 0 ] 								// 	AmpSlow
			wPar[ 3 ] = wPar[ 1 ] * 5							// 	TauSlow
			wPar[ 4 ] = w( Right- Left ) 							// 	const offset 
	
		elseif ( nFitFunc == FT_RISE )							// Sigmoidal rise	  ~  I_K   with delay		(LSLIB.pas : 14)
			wPar[ 0 ] = RT2080								//	rise time
			wPar[ 1 ] = Delay
			wPar[ 2 ] = Amp									// 	the measured amplitude	
	
		elseif ( nFitFunc == FT_RISECONST )						// Sigmoidal rise	  ~  I_K   with delay and constant	(LSLIB.pas : 14)
			wPar[ 0 ] = RT2080								//	rise time
			wPar[ 1 ] = Delay								// 	delay
			wPar[ 2 ] = Amp// - w( Right - Left )					// 	the measured amplitude with constant offset	 subtracted
			wPar[ 3 ] =  0//w( Right - Left )						// 	const offset  
	
		elseif ( nFitFunc == FT_RISDEC )						// Rise and Decay  ~  I_Na with delay				(LSLIB.pas : 12,13)
			wPar[ 0 ] = RT2080								//	rise time
			wPar[ 1 ] = Delay								// 	delay
			wPar[ 2 ] = 15 *  Amp * ( 1 + exp( Delay / RT2080 ) ) 		//	 purely empirical........
			wPar[ 3 ] = TauDecay 							//	 TauDecay
			wPar[ 4 ] = 0					
	
		elseif ( nFitFunc == FT_RISDECCONST )					// Rise and Decay  ~  I_Na with delay and constant	(LSLIB.pas : 12,13)
			wPar[ 0 ] = RT2080								//	rise time
			wPar[ 1 ] = Delay								// 	delay
			wPar[ 2 ] = 15 *  Amp * ( 1 + exp( Delay / RT2080 ) ) 		//	 purely empirical........
			wPar[ 3 ] = TauDecay 							//	 TauDecay
			wPar[ 5 ] = w( Right - Left )							// 	const offset  
		endif
	
		// printf "\tSetStartParams( \tch:%d  rg:%d  fi:%d)  \tnFitFunc:%d  %s \tParams:%d \tRT2080:%6.2lf \tAmp:%6.2lf  \r", ch, rg, fi, nFitFunc, pd( FitFuncNm_( nFitFunc ),9), numpnts( wPar), RT2080, Amplitude

	endif
	if ( numtype( x20 ) == kNUMTYPE_NAN  ||  numtype( x80 ) == kNUMTYPE_NAN ) 
		return	FALSE
	endif
	return	TRUE
End


static Function		PossiblyReportFindLevelError( Flag, LevelX, ch, rg, fi, nFitFunc, Left, Right, Level, Dip, Amp ) 
	variable	Flag, LevelX, ch, rg, fi, nFitFunc, Left, Right, Level , Dip, Amp
	string  	sMsg
	if ( Flag )
		sprintf sMsg, "While fitting '%s'  (channel:%d  region:%d  Fit:%d)  %d%% level crossing in range %.2lf...%.2lfms could not be found (min:%.2lf, max:%.2lf)  [Flag:%d].", FitFuncNm_( nFitFunc ), ch, rg, fi, 100*Level, Left, Right, Dip, Amp, Flag
		Alert( kERR_IMPORTANT,  sMsg )
		return	Nan
	endif
	return	LevelX
End


Function		FitMultipleFunctionsEval( wPar, x ) : FitFunc			// Igor does not allow this to be static
	wave	wPar
	variable	x
	variable	y
	nvar		nFitFunc	= root:uf:evo:fit:gFitFunc				// Igor requires this to be global but to be used only locally

	if ( 	nFitFunc   == FT_LINE )							// 	straight line
		y = wPar[ 0 ] +  x * wPar[ 1 ]

	elseif ( nFitFunc == FT_1EXP )							// 	1 exponential  without constant		(LSLIB.pas : 21)
		y = wPar[ 0 ]  * exp( - x  / wPar[ 1 ] ) 
	
	elseif ( nFitFunc == FT_1EXPCONST )						//	1 exponential  	with	 constant		(LSLIB.pas : 20)
		y = wPar[ 0 ]  * exp( - x / wPar[ 1 ] ) + wPar[ 2 ] 

	elseif ( nFitFunc == FT_2EXP )							//	2 exponentials without constant		(LSLIB.pas : 21)
		y = wPar[ 0 ]  * exp( - x / wPar[ 1 ] ) + wPar[ 2 ]  * exp( - x / wPar[ 3 ] )

	elseif ( nFitFunc == FT_2EXPCONST )						//	2 exponentials  	with	 constant		(LSLIB.pas : 20)
		y = wPar[ 0 ]  * exp( -x / wPar[ 1 ] ) + wPar[ 2 ]  * exp( - x / wPar[ 3 ] ) + wPar[ 4 ]

	elseif ( nFitFunc == FT_RISE )							//	Sigmoidal rise	  ~  I_K   with delay				(LSLIB.pas : 14)
		y =  exp( 4 * ln( 1 - exp( - ( x - wPar[ 1 ] ) / wPar[ 0 ] ) ) ) * wPar[ 2 ] 
		y = numType( y ) == kNUMTYPE_NAN  ?  0  : y

	elseif ( nFitFunc == FT_RISECONST )						//	Sigmoidal rise	  ~  I_K   with delay and constant	(LSLIB.pas : 14)
		y =  exp( 4 * ln( 1 - exp( - ( x - wPar[ 1 ] ) / wPar[ 0 ] ) ) ) * wPar[ 2 ] + wPar[ 3 ] 
		y = numType( y ) == kNUMTYPE_NAN  ?  0  : y

	elseif ( nFitFunc == FT_RISDEC )						//	Rise and Decay	  ~  I_Na with delay				(LSLIB.pas : 12,13)
		y =  exp( 3 * ln( 1 - exp( - ( x - wPar[ 1 ] ) / wPar[ 0 ] ) ) ) * ( wPar[ 2 ] * exp( - x / wPar[ 3 ] ) + wPar[ 4 ] )
		y = numType( y ) == kNUMTYPE_NAN  ?  0  : y

	elseif ( nFitFunc == FT_RISDECCONST )					//	Rise and Decay	  ~  I_Na with delay and constant	(LSLIB.pas : 12,13)
		y =  exp( 3 * ln( 1 - exp( - ( x - wPar[ 1 ] ) / wPar[ 0 ] ) ) ) * ( wPar[ 2 ] * exp( - x / wPar[ 3 ] ) + wPar[ 4 ] )  + wPar[ 5 ] 
		y = numType( y ) == kNUMTYPE_NAN  ?  0  : y
	endif

	return	y
End


Function		ComputeDerivedParams( wPar, wDerPar, ch, rg, fi, nFitFunc )
	wave  /D	wPar, wDerPar
	variable	ch, rg, fi, nFitFunc
//todo constants....
	if ( nFitFunc == FT_2EXP )															// 2 exponentials without constant	
		wDerPar[ 0 ]	=  ( wPar[ 0 ]  * wPar[ 1 ]  + wPar[ 2 ]  * wPar[ 3 ] ) / (  wPar[ 0 ]  + wPar[ 2 ] )		//	WTau	=  ( A0 * T0 + A1 * T1 ) / ( A0 + A1 ) 
		wDerPar[ 1 ]	=  ( wPar[ 0 ]  * wPar[ 1 ]  + wPar[ 2 ]  * wPar[ 3 ] ) / RserMV( ch, rg ) * 1e-12		//	Cap		=  ( A0 * T0 + A1 * T1 ) / kRSERIES_VOLTAGE
	elseif ( nFitFunc == FT_2EXPCONST )													// 2 exponentials  	with	 constant	
		wDerPar[ 0 ]	=  ( wPar[ 0 ]  * wPar[ 1 ]  + wPar[ 2 ]  * wPar[ 3 ] ) / (  wPar[ 0 ]  + wPar[ 2 ] ) 		//	WTau	=  ( A0 * T0 + A1 * T1 ) / ( A0 + A1 ) 
		// 1e12 is inserted as the programs uses  'pA'  in the VC mode as a basic unit. It would be better to use 'A' .  (This capacitance measurement works only in the VC mode.) 
		wDerPar[ 1 ]	=  ( wPar[ 0 ]  * wPar[ 1 ]  + wPar[ 2 ]  * wPar[ 3 ] ) / RserMV( ch, rg ) * 1e-12		//	Cap		=  ( A0 * T0 + A1 * T1 ) / kRSERIES_VOLTAGE
	endif
End

