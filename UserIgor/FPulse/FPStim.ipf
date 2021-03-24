//
// FPStim.ipf
// 
// Routines for
//	converting 'wVal'  text form stimulus data  into  'wEle'  stimulus data in number arrays
//	P over N sweep expansion
//	frame list expansion
//	stimulus display 
//
// History: 
// 161001 
// Syntax convention: Sweep starts with  the 'Sweeps: N=n' line and ends at the first 'Blank'  or the 'SweepEnd', whichever comes first.
// Syntax convention: Loops are allowed only within sweeps, but sweeps not within loops 
// Consequences: No 'Blanks'  within or before the 'Segments, etc' within a Sweep. No 'Blanks'  within a loop, as this would break the Sweep.

#pragma rtGlobals=1						// Use modern global access method.

static constant	BYTESPERPOINT	= 4		// IGOR stores all waves (Adc, Dac, Pon, Sum, DigOut...) as SP (single precision) 	
constant		cTYP   = 0, cMOD = 1, cDEL = 2, cCHA = 3, cBEG = 4, cDUR = 5, cDDU = 6
constant		cAMP = 7, cDAM = 8, cSCA_ = 9, cSIZE = 10
static constant	cAPP = 0, cFIX = 1, cREL = 2

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Stage : Advance from wVal to wE

Function		ExtractValSetEle( sFolder,  wG, wVal, wFix, wEinCB, wELine, maxDChs, maxEle )
// Step 5:  scan ' wVal'  taking into account the Frame/Sweep/Segment structure and set ' wEl'
//?  if channel number is missing a segment is ignored (reason: earlier, when chans/frames/elements are set)
	string		sFolder								// subfolder of root (root:'sF':...) used to discriminate between multiple instances of the  InterpretScript    e.g. from FPulse and from FEval
	wave  /T	wVal
	wave 	 wG, wFix, wEinCB, wELine								// contains wVal line number for  given frame and elememt
	variable	maxDChs, maxEle
	make  /O	/N = (  eBlocks( wG ), eMaxFrames( wG, wFix ), eMaxSweeps( wG, wFix ) ) $ksROOTUF_ + sFolder + ":ar:wBFS" = 0	// storing the block / frame / sweep combination in 1 number is a...
	wave	wBFS												=    $ksROOTUF_ + sFolder + ":ar:wBFS"		// ..memory saving approach to overcome IGORs limitation of 4 wave dimensions 

	variable	 c = 0, b = 0, f = 0, s = 0, e, k,  l, nType, nLine, nLastK

	make /O /T  /N = ( vMaxLines( wVal ) ) 		$ksROOTUF_ + sFolder + ":ar:wLineRef"				// stores channel, block and element number for a given wVal line number 
	wave      /T  wLineRef				= 	$ksROOTUF_ + sFolder + ":ar:wLineRef"

	//  Step 0: convert and store the block/frame/sweep combination in one number (=pointer)
	// blocks can have different numbers of frames and sweeps: increase linearly one by one 
	// this requires some bookkeeping but does not waste memory as a rectangular array (bMax * fMax * sMax) would 
	variable	bfsPtr	= 0
	for ( c = 0; c < maxDChs; c += 1 )				
 		for ( b  = 0; b < eBlocks( wG ); b += 1 )
	 		for ( f  = 0; f < eFrames( wFix, b ); f += 1 )
		 		for ( s  = 0; s < eSweeps( wFix, b ); s += 1 )
					wBFS[ b ] [ f ][ s ]  = bfsPtr
					bfsPtr += 1
					// printf "\t\teSetBFSPtr( \tb:%d\tf:%d\ts:%d ) = bfsPtr:%d   max:%d  \r",  b, f, s, wBFS[ b ][ f ][ s ], bfsPtr
				endfor
			endfor
		endfor
	endfor

	//  ' wE' is for storing and computing durations and amplitudes for stimulus segments
	// only from now on  eChans( wE )  and   eMaxBFS( wE )  are valid   (these are read as dimensions of wE)
	make  /O	/N = ( maxDChs, bfsPtr, maxEle, cSIZE )	$ksROOTUF_ + sFolder + ":ar:wE" =	0	
	wave	wE	= 							$ksROOTUF_ + sFolder + ":ar:wE" 																
	// printf "\t\tExtractValSetEle()  eChans( wE ):%d  bfsPtr:%d  maxele:%d \r ", eChans( wE ), bfsPtr, maxEle
	s = 0
	//  Step 1: extract numbers (=duration, begin...) from strings  (=Dac, Amp)
	for ( c = 0; c < eChans( wE ); c += 1 )
 		for ( b  = 0; b < eBlocks( wG ); b += 1 )
			for ( f  = 0; f < eFrames( wFix, b ); f += 1 )
				// printf "\t\tExtractValSetEle() f:%d   eElems( wEinCB, c, b ):%d \r", f, eElems( wEinCB, c, b )
				for ( e = 0; e < eElems( wEinCB, c, b ); e += 1 )
					nLine	= wELine[ c ][ b ][ e ]					// store original wVal line number for given frame and element
					nType	= str2num( vGE( wVal, wELine, c, b, 0, e, cTYP ) )	
					eSet( wE, wBFS,  c, b, f, 0, e, cTYP,  nType )					// k = 0 = cTYP : copy nType, e.g. index of 'Segment', 'Ramp'	
					//eSet( wE, wBFS,  c, b, f, 0, e, cSCA_, 1 ) 						// default for Expo (ScaleA is not an Expo user script entry and would be 0 otherwise)
					//eSet( wE, wBFS,  c, b, f, 0, e, cMOD, cAPP ) 					// default  is 'Append' mode if  'Abs'  and  'Rel'  subkeys are both missing
					// print "line1   ", nLine, "f:", f ,"c:", c , "b=", b , e , "storing type=", nType, "=?=", eVL( wE, wBFS, c, b, f, 0, e, cTYP), "=retrieved"
				 	 // printf "\t\t\tExtractValSetEle() c:%d\tb:%d\tf:%d\ts:%d\te:%2d/%2d\tl:%d\tType:%s\t'%s' \r", c, b, f, s, e, eElems( wEinCB, c, b ), nLine,  pad(mS( eVL( wE, wBFS, c, b,f,s,e, cTYP ) ),8) , GetScrLine( nLine ) 
					ExtractEValues( wVal, wELine, wE, wBFS, c, b, f, 0, e )	// break 'Dac' string into chan, dur, ddur, amp, damp
					stSetLineRef( wLineRef, nLine, c, b, e )
				endfor
			endfor
		endfor
	endfor

	// printf "\t\tExtractValSetEle()  starting step 3 \r "

	//  Step 3: copy from sweep 0 into all other sweeps
	for ( c = 0; c <  eChans( wE ); c += 1 )
 		for ( b  = 0; b < eBlocks( wG ); b += 1 )
		 	for ( f = 0; f <  eFrames( wFix, b ); f += 1)			
				for ( e = 0; e < eElems( wEinCB, c, b ); e += 1 )
					for ( k =0; k < eKeys( wE ); k += 1)					// copy all subkeys including nType..
						variable	value = eVL( wE, wBFS, c, b, f , 0 , e , k )			// ..from frame 0 / sweep 0.. 
					 	// printf "\t\t\tExtractValSetEle() \treading \tc:%d\tb:%d\tf:%d\ts:%d\te:%2d/%2d\tk:%2d\tType:%s\tvalue:%g    \r", c, b, f, 0, e, eElems( wEinCB, c, b ), k,  pd(mS( eVL( wE, wBFS, c, b, f, 0, e, cTYP ) ),8) , value
						for ( s = 0; s < eSweeps( wFix, b ); s += 1 )		
							eSet( wE, wBFS,  c, b, f , s , e , k , value )	
						 // printf "\t\t\t\t\t\t\t\tcopying \tc:%d\tb:%d\tf:%d\ts:%d\te:%2d/%2d\tk:%2d\tType:%s\t    \r", c, b, f, s, e, eElems( wEinCB, c, b ), k,  pd(mS( eVL( wE, wBFS, c, b, f, s, e, cTYP ) ),8)  
						endfor											
					endfor											
				endfor
			endfor
		endfor
	endfor
	// printf "\t\tExtractValSetEle()  finished step 3 \r "
	return 0	
End

Static Function	stSetLineRef( wLineRef, nLine, c, b, e )
// for every line in stim section of script  store the channel/block/element combination.
	wave  /T	wLineRef
	variable	nLine, c, b, e
	wLineRef[ nLine ]		= num2str( c ) + ";" + num2str( b ) + ";" + num2str( e )  
	// printf "\t\t\tSetLineRef() nLine:%2d  saving:\t  c:%d  b:%d e:%d   \t'%s' \r", nLine, c, b, e, wLineRef[ nLine ]
End

Static Function	stGetLineRef( wLineRef, nLine, c, b, e )
// used for multiple DACs 'relative' timing mode
	wave  /T	wLineRef
	variable	nLine
	variable	&c, &b, &e						// are returned
	c	= str2num( StringFromList( 0, wLineRef[ nLine ] ) )
	b	= str2num( StringFromList( 1, wLineRef[ nLine ] ) )
	e	= str2num( StringFromList( 2, wLineRef[ nLine ] ) )
	// printf "\t\t\tGetLineRef() nLine:%2d  retrieving:\t  c:%d  b:%d  e:%d   \t'%s' \r", nLine, c, b, e, wLineRef[ nLine ]
End

Function	/S	 RemoveBrackets( str )
	string	str
	return	str[ 1, strlen( str ) - 2 ] 
End	

//Function		ExtractModeOfs( c, b, f, s, e )	
//// break 'Abs'  and  'Rel'  string,  get time offset 
//	variable	c, b, f, s, e
//	string	sSubKeys	= "Abs;Rel"		// same order as cAPP = 0, cFIX = 1, cREL = 2
//	variable	n, nSubKeys	= ItemsInList( sSubKeys )
//	string	sScriptEntry
//
//variable nType =eVL( wE, wBFS, c, b, f, s, e, cTYP)
//	if (    nType  != mI( "Segment" ) && nType  != mI( "VarSegm" ) && nType  != mI( "Ramp" )  && nType  != mI( "Blank" )&& nType  != mI( "Expo" ) ) //0805
//
//	for ( n = 0; n < nSubKeys; n += 1 )
//		sScriptEntry	= vGES( wVal, wELine, c, b, f, e,  StringFromList( n, sSubKeys ) ) 
//		if ( cmpstr( sScriptEntry, "Nix" ) )
//			sScriptEntry = RemoveBrackets( sScriptEntry )
//			eSet( wE, wBFS,  c, b, f, s, e, cMOD, n + 1 )									// set mode number (cAPP = 0, cFIX = 1, cREL = 2)
//			eSet( wE, wBFS,  c, b, f, s, e, cDEL, str2num( sScriptEntry ) * kMILLITOMICRO )	// set time offset (applicable only when ABS or REL mode, zero in APPend mode) 
//			// print  "*****", c, b, f, s, e, "->", n, vG( wVal, nLine, nskidx+1, f ), "mode:", eVL( wE, wBFS, c, b, f, s, e, cMOD ), "del:", eVL( wE, wBFS, c, b, f, s, e, cDEL )
//		endif
//	endfor
//	
//	endif //0805
//End

Function		ExtractEValues( wVal, wELine, wE, wBFS, c, b, f, s, e )	
//  break 'Dac' string into chan, dur, ddur, amp, damp, read value from combined string, if missing (==Nan) the supply default  0
//!  THIS  FUNCTION  DETERMINES  THE  ORDER  OF  THE  ENTRIES  IN  THE  SCRIPT
	wave	/T	wVal
	wave	wELine, wE, wBFS
	variable	c, b, f, s, e
	variable	nType		= eVL( wE, wBFS, c, b, f, s, e, cTYP)	
	variable	Cha, Dur, Amp, DAm, DDu, SclA, Del, nMode
	string		sName		= "", sMode = ""
	string		sScriptEntry	= ""
variable	OfsA, SclX

	//  'Dac' string determines DAC channel number , element duration, delay mode and delay time. 
	//  It must occur in EVERY STIM  line (=Segment,Expo,Stimwave...), so we can break it here without checking the mainkey type 
//what if user forgets it???
	sScriptEntry	= vGES( wVal, wELine, c, b, f, e,  "Dac" )
	Cha		= str2num( StringFromList( 0, sScriptEntry, "," ) );				  eSet( wE, wBFS,  c, b, f, s, e, cCHA,	numType( Cha ) == kNUMTYPE_NAN ? 0 : Cha )						
	Dur		= str2num( StringFromList( 1, sScriptEntry, "," ) ) * kMILLITOMICRO; eSet( wE, wBFS,  c, b, f, s, e, cDUR,	numType( Dur )  == kNUMTYPE_NAN ? 0 : Dur  )						
	sMode	= StringFromList( 2, sScriptEntry, "," )
	nMode	= cmpstr( sMode, "A" ) == 0 ? cFIX : ( cmpstr( sMode, "R" ) == 0 ? cREL : cAPP ) 
	eSet( wE, wBFS,  c, b, f, s, e, cMOD, nMode )									// set mode number (cAPP = 0, cFIX = 1, cREL = 2)
	Del	  = str2num( StringFromList( 3, sScriptEntry, "," ) ) * kMILLITOMICRO;eSet( wE, wBFS,  c, b, f, s, e, cDEL,	numType( Del )  == kNUMTYPE_NAN ? 0 : Del  )						
	// set time offset (applicable only when ABS or REL mode, zero in APPend mode) 
	// printf  "\t\tExtractValSetEle\t %s\tc:%d\tf:%d\ts:%d\te:%d\t%s\t--> Cha:%2d\t%1s:%d\tDel:%6.1lf\tDur:%5.1lf", pad(mS( nType ),9), c, b, f, s, e, pad(sScriptEntry,9), eVL( wE, wBFS, c, b, f, s, e, cCHA ), sMode, eVL( wE, wBFS, c, b, f, s, e, cMOD ), eVL( wE, wBFS, c, b, f, s, e, cDEL ),eVL( wE, wBFS, c, b, f, s, e, cDUR )

	if (   nType  == mI( "Segment" ) ||  nType  == mI( "VarSegm" ) || nType  == mI( "Ramp" ) || nType  == mI( "Blank" )  ) 
		sScriptEntry	= vGES( wVal, wELine, c, b, f, e,  "Amp" )
		Amp	  = str2num( StringFromList( 0, sScriptEntry, "," ) );				  eSet( wE, wBFS,  c, b, f, s, e, cAMP,	numType( Amp ) == kNUMTYPE_NAN ? 0 : Amp )						
		SclA	  = str2num( StringFromList( 1, sScriptEntry, "," ) );				  eSet( wE, wBFS,  c, b, f, s, e, cSCA_,	numType( SclA )  == kNUMTYPE_NAN ? 1 : SclA  )						
		DAm  = str2num( StringFromList( 2, sScriptEntry, "," ) ) ;				  eSet( wE, wBFS,  c, b, f, s, e, cDAM,	numType( DAm ) == kNUMTYPE_NAN ? 0 : DAm )						
		DDu	  = str2num( StringFromList( 3, sScriptEntry, "," ) ) * kMILLITOMICRO; eSet( wE, wBFS,  c, b, f, s, e, cDDU,	numType( DDu ) == kNUMTYPE_NAN ? 0 : DDu )						
		// printf  "\tAmp:%5.1lf\tSca:%5.1lf \tDAm:%5.1lf\r ", eVL( wE, wBFS, c, b, f, s, e, cAMP ), eVL( wE, wBFS, c, b, f, s, e, cSCA_ ), eVL( wE, wBFS, c, b, f, s, e, cDAM )
	endif
	if (   nType  == mI( "Expo" )  )
		// printf  "  ...evaluation not yet here \r" 			// SclA=1 introduced for PoN correction to work
		SclA	  = 1;												eSet( wE, wBFS,  c, b, f, s, e, cSCA_,	numType( SclA )  == kNUMTYPE_NAN ? 1 : SclA  )						
	endif
	if (  ( nType  == mI( "StimWave" ) ) )
		sScriptEntry		= vGES( wVal, wELine, c, b, f, e,  "Wave" )

		// determine duration of stimwave by getting the number of points of the wave, which can differ from the duration requested in the script
		// Following line active: always use stimwave duration.  Following line commented: always use script duration 
		//Dur = SetNumberOfPointsFromReadWave( c, b, f, s, e ) ; 	eSet( wE, wBFS,  c, b, f, s, e, cDUR, Dur ) 	// store ZERO duration if  LoadWave failed so that  SetStimulusFromReadWave() can avoid trying  a 2. time

		SclA	= str2num( StringFromList( 1, sScriptEntry, "," ) );	eSet( wE, wBFS,  c, b, f, s, e, cSCA_,	numType( SclA )  == kNUMTYPE_NAN ? 1 : SclA  )						
		OfsA	= str2num( StringFromList( 2, sScriptEntry, "," ) );	eSet( wE, wBFS,  c, b, f, s, e, cDAM,	numType( OfsA )  == kNUMTYPE_NAN ? 0 : OfsA  )	// 040519 !!! Rather than introducing new constants cOFSA and cSCLX...					
		SclX	= str2num( StringFromList( 3, sScriptEntry, "," ) );	eSet( wE, wBFS,  c, b, f, s, e, cAMP,	numType( SclX )  == kNUMTYPE_NAN ? 1 : SclX  )	//...we misuse existing ones which are not used in StimWave (see SetStimulusFromReadWave() )				
		//   stimwave   name   is    entry    2  -> also  in  SetNumberOfPointsFromReadWave()  ->  ExtractStimwaveName)
		// printf  "\t\tExtractEValues( c, b, f, s, e ) StimWave \tDu1:%5.1lf \tSclA:\t%7.2lf\tOfsA:\t%7.2lf\tSclX:\t%7.2lf\t'%s' \r ", Dur, eVL( wE, wBFS, c, b, f, s, e, cSCA_), eVL( wE, wBFS, c, b, f, s, e, cDAM), eVL( wE, wBFS, c, b, f, s, e, cAMP), ExtractStimwaveName( c, b, f, s, e )
	endif
End

static   Function   /S	ExtractStimwaveName( wVal, wELine, c, b, f, s, e )
//!  THIS  FUNCTION  DETERMINES  THE  ORDER  OF  THE  ENTRIES  IN  THE  SCRIPT
	wave	/T	wVal
	wave 	wELine								// contains wVal line number for  given frame and elememt
	variable	c, b, f, s, e
	return	StringFromList( 0, vGES( wVal, wELine, c, b, f, e, "Wave" ), "," )				// stimwave name is entry 0
End


Function		AdjustInterFrameInterval(  wG, wFix, wEinCB, wE, wBFS )
// An InterBlockInterval  occurs  only  once for each frame: after the LAST element  of the LAST sweep. Set all others to 0 duration.
	wave	 wG, wFix, wEinCB, wE, wBFS
	variable	c = 0, b, f, s, e
	for ( b  = 0; b < eBlocks( wG ); b += 1 )
		for ( f = 0; f <  eFrames( wFix, b ); f += 1 )									// copy all frames 
			for ( s = 0; s < eSweeps( wFix, b ); s += 1 )		
				for ( e = 0; e < eElems( wEinCB, c, b ); e += 1 )
					if ( stIsInterFrameInterval( wEinCB, c, b, f, s, e ) && s < eSweeps( wFix, b ) - 1 )	// an InterFrmInt is appended only after the last sweep...
						eSet( wE, wBFS,  c, b, f, s, e, cDUR, 0 )						// ..of each frame, so we set  the duration of all ..
					endif												// ..others to zero to keep the array rectangular
				endfor											
			endfor
		endfor
	endfor
	return 0	
End

Function		AdjustInterBlockInterval(  wG, wFix, wEinCB, wE, wBFS )
// An InterBlockInterval  occurs  only  once for each block: after the LAST element  of the LAST sweep of the LAST frame. Set all others to 0 duration.
	wave	wG, wFix, wEinCB, wE, wBFS
	variable	c = 0, b, f, s, e
	for ( b  = 0; b < eBlocks( wG ); b += 1 )
		for ( f = 0; f <  eFrames( wFix, b ); f += 1 )										// copy all frames 
			for ( s = 0; s < eSweeps( wFix, b ); s += 1 )		
				for ( e = 0; e < eElems( wEinCB, c, b ); e += 1 )
					if ( stIsInterBlockInterval( wEinCB, c, b, f, s, e ) &&((s < eSweeps( wFix, b ) - 1)||( f < eFrames( wFix, b ) - 1)) )	// an InterBlockInt is appended only after the last frame...
						eSet( wE, wBFS,  c, b, f, s, e, cDUR, 0 )								// ..of each block, so we set  the duration of all ..
					endif													// ..others to zero to keep the array rectangular
				endfor											
			endfor
		endfor
	endfor
	return 0	
End

static Function	stIsInterFrameInterval( wEinCB, c, b, f, s, e )
// Definition: the InterFrmInterval is the the 'Blank' after the 'EndSweep' line
// the function PossiblyInsertInterFrameInterval() has made sure that there is always exactly...
// ..one InterFrameInterval (possibly of duration 0) 
	wave	wEinCB
	variable	c, b, f, s, e
	variable	code	= FALSE
	if ( e == eElems( wEinCB, c, b )  - 2 )
		// printf "\t\tFound  InterFrameInterval ( c:%d  b:%d   f:%d   s:%d  [=e:%d ] )  with Dur:%g    Amp:%g  \r", c, b, f, s, e,  eVL( wE, wBFS, c, b, f , s, e, cDUR ),  eVL( wE, wBFS, c, b, f , s, e, cAMP )
		code	= TRUE
	endif
	return code
End


static Function	stIsInterBlockInterval( wEinCB, c, b, f, s, e )
// Definition: the InterBlockInterval is the the 'Blank' after the 'EndFrame' line
// the function PossiblyInsertInterBlockInterval() has made sure that there is always exactly...
// ..one InterBlockInterval (possibly of duration 0)  
	wave	wEinCB
	variable	c, b, f, s, e
	variable	code	= FALSE
	if ( e == eElems( wEinCB, c, b )  - 1 )
		// printf "\t\tFound  InterBlockInterval ( c:%d  b:%d   f:%d   s:%d  [=e:%d ] )  with Dur:%g    Amp:%g  \r", c, b, f, s, e,  eVL( wE, wBFS, c, b, f , s, e, cDUR ),  eVL( wE, wBFS, c, b, f , s, e, cAMP )
		code	= TRUE
	endif
	return code
End
				

Function		ShowAmpTimes( wG, wFix, wEinCB, wE, wBFS, sText )
// preliminary check of sweep times
	wave	wG, wFix, wEinCB, wE, wBFS
	string 	sText	
	nvar		gRadDebgSel		= root:uf:dlg:gRadDebgSel
	nvar		PnDebgShowAmpTi	= root:uf:dlg:Debg:ShowAmpTim
	variable	nSmpInt			= wG[ kSI ]
	if ( gRadDebgSel > 0  &&  PnDebgShowAmpTi )	// we save (much!) time by skipping this function right here if it is turned off anyway
		make /O /N=( eChans( wE ) )	wSweepTime = 0
		printf  "\t\tShowAmpTimes( %s ) \r", sText
		variable	c, b, f, s, e, nType, Dur
		string 	bf, bf1, sAmp, sDur, sTime//, sBeg
		if ( gRadDebgSel > 1  &&  PnDebgShowAmpTi )	// we save (much!) time by skipping this function right here if it is turned off anyway
			for ( c = 0; c < eChans( wE ); c += 1 )
				printf "\r"
				for ( b  = 0; b < eBlocks( wG ); b += 1 )
					for ( f  = 0; f < eFrames( wFix, b ); f += 1 ) 
						for ( s = 0; s < eSweeps( wFix, b ); s += 1 )			
							//sprintf bf, "\t\t\tShowAmpTi  c:%d  f:%d s:%d\t", c, b, f, s
							sprintf bf, "\t\t\tShowAT c:%d b:%d f:%d s:%d\t%s", c, b, f, s, SelectString( eElems( wEinCB, c, b ) == 0, "", "\r" )
							for ( e = 0; e < eElems( wEinCB, c, b ); e += 1 )
								sprintf bf1, "%5s%s", mS( eTyp( wE, wBFS,  c, b, e ) )[0,5], SelectString( e == eElems( wEinCB, c, b ) - 1, "\t", "\r" )
								bf += bf1
							endfor
							printf "%s", bf 
							sprintf sAmp,  "\t\t\tShowAmpTi  Amp:\t\t"
							sprintf sDur,    "\t\t\tShowAmpTi  Dur: \t\t"
							sprintf sTime, "\t\t\tShowAmpTi  Tim: \t\t"
							//sprintf sBeg, 	"\t\t\tShowAmpTi  Beg: \t\t"
							for ( e = 0; e < eElems( wEinCB, c, b ); e += 1 )
								nType = eTyp( wE, wBFS,  c, b, e ) 
								Dur	   = eVL( wE, wBFS, c, b, f, s, e, cDUR ) /  nSmpInt
								wSweepTime[ c ] +=  Dur
								sAmp	+= num2str(  eVL( wE, wBFS, c, b, f, s, e, cAMP ) )+ "     \t"
								sDur	+= num2str(  Dur )+ "     \t"
								sTime	+= num2str( wSweepTime[ c ] ) + "   \t"
								//sBeg	+= num2str(  eVL( wE, wBFS, c, b, f, s, e, cBEG ) )+ "  \t"
							endfor
							printf "%s\r", sAmp
							printf "%s\r", sDur
							printf "%s\r", sTime
							// printf "%s\r", sBeg
						endfor
					endfor
				endfor
			endfor
		endif
		KillWaves	wSweepTime
	endif
End

Function 		ShowEle(  wG, wFix, wEinCB, wE, wBFS, sText )
// display stimulus data as wE (last stage before stimulus wave) 
// wE  has rectangular frame x sweep x elements data
	wave	wG, wFix, wEinCB, wE, wBFS
	string	  	sText
	nvar		gRadDebgSel		= root:uf:dlg:gRadDebgSel
	nvar		PnDebgShowEle	= root:uf:dlg:Debg:ShowEle
	variable	c, b = 0, f = 0, s, e, k, nType, kMax
	if ( gRadDebgSel > 0  &&  PnDebgShowEle )	// we save (much!) time by skipping this function right here if it is turned off anyway
		printf  "\t\tShowEle( %s ) \t\t wE[ Blocks:%d   maxFrm:%d  maxSwp:%d  maxChn:%d  maxBFS:%d  maxEle:%d  nKeys:%d] \r",  sText, eBlocks( wG ), eMaxFrames( wG, wFix ), eMaxSweeps( wG, wFix ), eChans( wE ), eMaxBFS( wE ), eMaxElems( wE ), eKeys( wE )
		string	bf, bf1
		for ( c = 0; c < eChans( wE ); c += 1 )
			for ( b  = 0; b < eBlocks( wG ); b += 1 )
				for ( f = 0; f < eFrames( wFix, b ); f += 1 )							// all Frames
					printf  "\t\t\tShowEle(Num)\tBlk %2d/%2d \tFrm %2d/%2d \t\t\t Sweep %2d/%2d\t\t\t\t\t\t\t\t\t\t\t\t\tSweep %2d/%2d \r", b, eBlocks( wG ), f, eFrames( wFix, b ), 0, eSweeps( wFix, b ), 1, eSweeps( wFix, b )
					for ( e = 0; e < eElems( wEinCB, c, b ); e += 1 )			// all wEl elements of sweep 0 (all sweeps have same number of elements, 
						nType	=  eTyp( wE, wBFS,  c, b, e )
						sprintf bf, "\t\t\tShowEle(N) c:%d\te:%d\tt:%d\t%-12s\t", c, e, nType, mS( nType )
						for ( s = 0; s < min( 2, eSweeps( wFix, b ) ); s += 1 )	// 2 Sweeps are enough because PoverN makes the 2., 3., 4..equal
							for ( k = 0; k <  eKeys( wE ); k += 1 )			// arrange all subkeys of sweep 0 and sweep 1 in one line
								sprintf  bf1, "%6.1lf\t ", eVL( wE, wBFS, c, b, f, s, e, k )
								bf += bf1
							endfor
							bf += "\t"								// tabulate columns of 2. sweep neatly
						endfor
						printf "%s\r", bf
					endfor
				endfor
			endfor
		endfor
	endif
	return 0	
End


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Stage : wE  refinement:  compute and fill in the automatic incs, decs  and  the PoN correction sweeps

Function 		ExpandFramesIncDec(  wG, wFix, wEinCB, wE, wBFS )
// Step 6:  take into account the DAmp and DDur entries: increment or decrement frames >= 1
//	only sweep 0 is set, sweeps >= 1 are still empty
	wave	wG, wFix, wEinCB, wE, wBFS
	nvar		gRadDebgSel	= root:uf:dlg:gRadDebgSel
	nvar		PnDebgExpand	= root:uf:dlg:Debg:Expand
	variable	c = 0, b = 0, f, e, value, nType 
	if ( gRadDebgSel > 0  &&  PnDebgExpand )
		printf  "\t\tExpandFramesIncDec() \t wE[ nFrm:%d  ?nSwp:%d  nChn:%d  nBFS:%d  nEle:%d  nKeys:%d] \r", eFrames(wFix, b), eSweeps(wFix, b), eChans( wE ), eMaxBFS( wE ), eMaxElems( wE ), eKeys( wE )
	endif

	for ( c = 0; c < eChans( wE ); c += 1 )						// loop through all dac channels
		for ( b  = 0; b < eBlocks( wG ); b += 1 )
			for ( f = 1; f < eFrames( wFix, b ); f += 1 )						// loop through all frames above frame 0, whose values are fixed
				for ( e = 0; e < eElems( wEinCB, c, b ); e += 1 )				// loop through all elements (=VarSegm,Segment,Ramp,StimWave..)
		
					nType = eTyp( wE, wBFS,  c, b, e )
					if ( nType == mI( "Blank" ) || nType == mI( "VarSegm" ) || nType == mI( "Segment" ) || nType == mI( "Ramp" ) ) // but use only Segments, Ramp....
						// 1210
						//	eSet( wE, wBFS,  c, b, f, 0, e, cAMP,			eVL( wE, wBFS, c, b, f, 0, e, cAMP )    +	f * eVL( wE, wBFS, c, b, f, 0, e, cDAM  ) )
						//	eSet( wE, wBFS,  c, b, f, 0, e, cDUR,   max( 0,	eVL( wE, wBFS, c, b, f, 0, e, cDUR )   +  f * eVL( wE, wBFS, c, b, f, 0, e, cDDU ) ) )	// durations must be positive
						
						if ( eVL( wE, wBFS, c, b, f, 0, e, cDAM ) != 0 )					// 121002 allow deltas to change from frame to frame by adding delta of current frame  to value of previous frame	 
							eSet( wE, wBFS,  c, b, f, 0, e, cAMP,		   eVL( wE, wBFS, c, b,  f - 1, 0, e, cAMP ) +  eVL( wE, wBFS, c, b, f, 0, e, cDAM ) )	// add current delta to 	 	
							// print  "PULSEExpandFramesIncDec()", c, b, f, 0, e, " : "	,   eVL( wE, wBFS, c, b,  f - 1, 0, e, cAMP ) ,"+ ",  eVL( wE, wBFS, c, b, f, 0, e, cDAM )   ,"->" , eVL( wE, wBFS, c, b, f, 0, e, cAMP )
						endif
						if ( eVL( wE, wBFS, c, b, f, 0, e, cDDU ) != 0 )					// 121002 allow deltas to change from frame to frame by adding delta of current frame  to value of previous frame	
							eSet( wE, wBFS,  c, b, f, 0, e, cDUR,   max( 0, eVL( wE, wBFS, c, b, f - 1, 0, e, cDUR) +  eVL( wE, wBFS, c, b, f, 0, e, cDDU ) ) )// durations must be positive
						endif
	
						// printf "\t\t\tExpandFramesIncDec() reads c:%d f:0 s:0 e:%d  eTyp:%d~%s\tand sets f:%d s:0 Amp:%5g\t->%5g \tDur:%5g\t->%5g \r", c, e, eTyp(c,0,0,e), pad(mS(eTyp(c,0,0,e)),9), f, eVL( wE, wBFS, c, 0, 0, e, cAMP ), eVL( wE, wBFS, c, b, f, 0, e, cAMP ), eVL( wE, wBFS, c, 0, 0, e, cDUR ), eVL( wE, wBFS, c, b, f, 0, e, cDUR )
					endif
					if ( nType == mI( "StimWave" ) )			 // ! must not set Amp
						//  DODel DODur...eliminated
						// printf "\t\t\tExpandFramesIncDec() reads c:%d f:0 s:0 e:%d  eTyp:%d~%s\tand sets f:%d s:0  \r ", c, e, eTyp(c,0,0,e), pad(mS(eTyp(c,0,0,e)),9), f
					endif
				endfor
			endfor
		endfor
	endfor
End


Function 		ExpandSweepsWithPoverN(  wG, wFix, wEinCB, wE, wBFS )
// Step 7:  copy values from wEl[ ] [ Sweep = 0 ] [ ] [ ]  into all other frames and sweeps
// adjust  Amp  values in sweeps 1..nSweeps so that P over N is satisfied . This is done indirectly by inverting the scale value.
	wave	wG, wFix, wEinCB, wE, wBFS
	nvar		gRadDebgSel	= root:uf:dlg:gRadDebgSel
	nvar		PnDebgExpand	= root:uf:dlg:Debg:Expand
	if ( gRadDebgSel > 0  &&  PnDebgExpand )
		printf "\t\tExpandSweepsWithPoverN() \r"
	endif
	variable	c = 0, b, f, s, e, k, value,nType

	for ( c = 0; c < eChans( wE ); c += 1 )											// loop through all dac channels
		for ( b  = 0; b < eBlocks( wG ); b += 1 )
			// printf "\t\tExpandSweepsWithPoverN( b:%d )  uses CorrAmp:%g \r", b, eCorrAmp( wFix, b )
			for ( f = 0; f < eFrames( wFix, b ); f += 1 )								// loop through all frames
				for ( s = 1; s < eSweeps( wFix, b ); s += 1 )							// compute all sweeps above the first from the first
					for ( e = 0; e < eElems( wEinCB, c, b ); e += 1 )						// loop through all elements (=Segments, Ramp..)
						nType = eTyp( wE, wBFS,  c, b, e )
						for ( k = 1; k <= eKeys( wE ); k += 1 )						// loop through all keys (=Dur, Amp, DDur.)..
							// special case: don't copy the InterFrmInt  and the InterBlockInterval because their lengths have already been corrected and set 
							if ( ! stIsInterFrameInterval( wEinCB, c, b, f, s, e )   &&   ! stIsInterBlockInterval( wEinCB, c, b, f, s, e )  )	
								eSet( wE, wBFS,  c, b, f, s, e, k,   eVL( wE, wBFS, c, b, f, 0, e, k ) )		// at first copy all keys of all sweeps of all frames... 
								// printf "\t\tNormal Interval:\tcopying   \tvalue( c:%d  b:%d   f:%d   s=%d   e:%d   k:%2d ) :%5g\t-> s=%d \t(value:%g) \r", c, b, f, 0, e, k , eVL( wE, wBFS, c, b, f, s, e, k ), s, eVL( wE, wBFS, c, b, f, s, e, k )
							else										// ....except the InterFrmInterval / InterBlockInterval ) ...
								// printf "\t\tIFrmInt  IBlkInt:\talready set\tvalue( c:%d  b:%d   f:%d   s=%d   e:%d   k:%2d ) :%5g\t-> s=%d \t(value:%g) \r", c, b, f, 0, e, k , eVL( wE, wBFS, c, b, f, s, e, k ), s, eVL( wE, wBFS, c, b, f, s, e, k )
							endif										// ....except the InterFrmInterval / InterBlockInterval ) ...
						endfor
						// Design issue: An InterSWEEPInterval   _IS_  'PoN-inverted' .  If this is not desired an ISI must be processed like an IBI or IFI.....
						if ( ePoN( wFix, b )  &&   ! stIsInterFrameInterval( wEinCB, c, b, f, s, e )   &&   ! stIsInterBlockInterval( wEinCB, c, b, f, s, e )  )	
							eSet( wE, wBFS,  c, b, f, s, e, cSCA_,   -eVL( wE, wBFS, c, b, f, 0, e, cSCA_ ) * eCorrAmp( wFix, b ) ) // then invert the scale key
							// printf "\t\tNormal with PoN\tinverting scl \tvalue( c:%d  b:%d   f:%d   s=%d   e:%d   k:%2d ) :%5g\t-> s=%d  \r", c, b, f, 0, e, cSCA_ , eVL( wE, wBFS, c, b, f, s, e, cSCA_ ), s
						endif
					endfor
				endfor
			endfor
		endfor
	endfor
End

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
Static Function  stCheckTimes( sFolder, wE, wBFS, c, b, f, s, e, SmpInt, DacMax, DacMin, DacGain )
// checks that all durations and times are integral multiples of sample interval
// late execution of this check allows using ' wEl' incorporating all deltas already, so the actual deltas have not to be checked
// if earlier execution of this check is desired, it must use ' wVal' and  the deltas must be checked too
// Amplitudes of Expo or Stimwave are not checked
	string  	sFolder
	wave	wE, wBFS
	variable	c, b, f, s, e, SmpInt, DacMax, DacMin, DacGain
	variable	n, vTime, vAmp
	string  	bf
	// printf "\tCheckTimes()  \tc:%d \tf:%d \ts:%d \te:%d  \tcDUR:\t%6.1lf \tcDDU:\t%6.1lf \tcOFS:\t%6.1lf \r", c, b, f, s, e, eVL( wE, wBFS,  c, b, f, s, e, cDUR ), eVL( wE, wBFS,  c, b, f, s, e, cDDU ), eVL( wE, wBFS,  c, b, f, s, e, cDEL )
	// printf "\tCheckTimes()  \tc:%d \tf:%d \ts:%d \te:%d  \tDacMax:\t%6.1lf \tDacMin:\t%6.1lf \tDacGain:\t%6.1lf \t=?= DG(cIOGAIN:\t%6.1lf \r", c, b, f, s, e,  DacMax, DacMin, DacGain , iov( wIO, kIO_DAC, c, cIOGAIN )

	make	/O /N = 3  		$ksROOTUF_ + sFolder + ":ar:wIndicesToCheck"
	wave	wIndicesToCheck  =	$ksROOTUF_ + sFolder + ":ar:wIndicesToCheck"
	wIndicesToCheck[ 0 ] = cDUR
	wIndicesToCheck[ 1 ] = cDDU
	wIndicesToCheck[ 2 ] = cDEL
	for ( n = 0; n < numPnts( wIndicesToCheck ); n += 1 )
		vTime = eVL( wE, wBFS, c, b, f, s, e, wIndicesToCheck[ n ] )
		if ( vTime / SmpInt != round( vTime / SmpInt) )
			sprintf  bf, " '%s' contains time %.3lf ms (%d us)  which is not integral multiple of sample interval %.1lf us. (Ch:%d  Blk:%d  Frm:%d  Swp:%d  Ele:%d)", mS( eTyp( wE, wBFS, c, b, e ) ),  vTime / kMILLITOMICRO, vTime, SmpInt, c, b, f, s, e
			Alert( kERR_FATAL,  bf )
KillWaves	wIndicesToCheck	// 041014
			return	kERROR	// returning kERROR is absolutely necessary to avoid endless loops where only IGOR ABORT button helps
		endif
	endfor
	vAmp = eVL( wE, wBFS, c, b, f, s, e, cAMP )
	if ( vAmp * DacGain < DACMin  ||   DACMax < vAmp * DacGain )
		sprintf  bf, " %s\trequests amplitude %.1lf mV (%.1lf * %.1lf) which exceeds DAC range (%d..%d). (Ch:%d, Blk:%d, Frm:%d, Swp:%d, Ele:%d)", pd( mS( eTyp( wE, wBFS,  c, b, e ) ), 8 ),  vAmp * DacGain, vAmp, DacGain, DacMin, DacMax, c, b, f, s, e
		// Alert( kERR_FATAL,  bf )  ;return	kERROR		// kERROR not neccessary: could also be ignored (but CED may then output inverse polarity)  or clipping could be implemented
		Alert( kERR_IMPORTANT,  bf )
		eSet( wE, wBFS,  c, b, f, s, e, cAMP, min( max( DacMin / DacGain, vAmp ), DacMax / DacGain ) )	// clip to the closest possible value
	endif
KillWaves	wIndicesToCheck	// 041014
	return	0
End

Function		ComputeTotalPoints( sFolder, wG, wIO, wFix, wEinCB, wELine, wE, wBFS, wLineRef )
// go through all elements of wEl in all frames and sweeps
// - reads and adds all  'Dur', sets 'BegPt'
// - checks  if  all times are multiples of sample interval
// - returns  total points = endpoint after last frame, last sweep, last element (maxpoints of all channels)
	string  	sFolder
	wave  /T	wIO, wLineRef
	wave	wG, wFix, wEinCB, wELine, wE, wBFS
	nvar		gRadDebgSel		= root:uf:dlg:gRadDebgSel
	nvar		PnDebgOutElems	= root:uf:dlg:Debg:OutElems
	nvar		pnDebgCed		= root:uf:dlg:Debg:CedInit
	variable	c, b, f, s, e, nMode, nLine, del, beg, dur, EndPt = 0, MaxPt = 0, nPass = 0, nWrongBegCnt = 0
	variable	c1, b1, f1, e1
	nvar		gnProts			= $ksROOTUF_ + sFolder + ":keep:gnProts"
	variable	nSmpInt			= wG[ kSI ]
	variable	DACRange		= 10								//+ -  Volt
	variable	DACMax			=   DacRange * 1000 * 32767 / 32768	//!  valid only for 12bit dac
 	variable	DACMin			=  -DacRange * 1000
	variable	DacGain		
	string		sBuf
	// Depending on channel order in scripts the 'Rel' offset gives wrong begin times if their channel is computed before the channel they refer to...
	// this error is corrected by passing through this function repeatedly until no time differences are reported any more. This may be one iteration too much, which does no harm..	
	do
		nWrongBegCnt = 0
		for ( c = 0; c < eChans( wE ); c += 1)
			DacGain		=  iov( wIO, kIO_DAC, c, cIOGAIN )
			EndPt = 0
			for ( b  = 0; b < eBlocks( wG ); b += 1 )
				for ( f = 0; f < eFrames( wFix, b ); f += 1 )							// loop through all frames
					for ( s = 0; s < eSweeps( wFix, b ); s += 1 )						// compute all sweeps above the first from the first
						for ( e = 0; e < eElems( wEinCB, c, b ); e += 1 )					// loop through all elements (=Segments, Ramp..)
							if ( stCheckTimes( sFolder, wE, wBFS, c, b, f, s, e, nSmpInt, DacMax, DacMin, DacGain  ) ) //    todo  1004   Digout    ,DODur,DODel,DODDur,DODDel" )
								return	kERROR
							endif
							nMode	= eVL( wE, wBFS, c, b, f, s, e, cMOD )
							dur		= eVL( wE, wBFS, c, b, f, s, e, cDUR ) 		// check if the current element has a subkey 'Dur'...
							del		= eVL( wE, wBFS, c, b, f, s, e, cDEL ) 		// check if the current element has a subkey ...
// 050609
//							nLine	= wELine[ c ][ f ][ e ]					// retrieve original wVal line number for given frame and element
							nLine	= wELine[ c ][ b ][ e ]					// retrieve original wVal line number for given frame and element

							if ( nMode == cAPP )
								Beg =EndPt
							 	// printf "\t\t\t\tComputeTotalPoints APP\t%s\tMode:%d\tnPass:%d\tc:%d\tf:%d\ts:%d\te:%d\tLine:%d\tOfs:%6d \tBeg:%6d\tDur:%6d \r", pad(mS( eTyp( wE, wBFS,  c, b, e ) ),8), nMode, nPass, c, b, f, s, e, nLine, del, Beg, dur / nSmpInt
							endif				
							if ( nMode == cFIX )
								Beg = del / nSmpInt 
							endif				
							if ( nMode == cREL )
								stGetLineRef( wLineRef, nLine - 1, c1, b1, e1 )										//  function changes c1, b1, e1
								Beg = eVL( wE, wBFS, c1, b1, f, s, e1, cBEG ) + ( eVL( wE, wBFS, c1, b1, f, s, e1, cDUR ) + del ) / nSmpInt 	// begin of preceding line  +  delay
								nWrongBegCnt = ( Beg != eVL( wE, wBFS, c, b, f, s, e, cBEG ) ) ? nWrongBegCnt + 1 :  nWrongBegCnt 
							 	  printf "\t\t\t\tComputeTotalPoints REL\t%s\tMode:%d\tnPass:%d\tc:%d\tb:%d\tf:%d\ts:%d\te:%d\tLine:%d\tOfs:%6d \tBeg:%6d \t=?=%6d\tDur:%6d   c1:%2d   f1:%2d   s:%2d   e1:%2d\r", pad(mS( eTyp( wE, wBFS,  c, b, e ) ),8), nMode, nPass, c, b, f, s, e, nLine, del, Beg, eVL( wE, wBFS, c, b, f, s, e, cBEG ) , dur / nSmpInt, c1, f1, s, e1
							endif				
							eSet( wE, wBFS,  c, b, f, s, e, cBEG,  Beg )
							EndPt = Beg + dur / nSmpInt												// set  the element begin point  to begin of next element
					 		// printf "\t\t\t\tComputeTotalPoints() \t\t%s\tMode:%d\tnPass:%d\tc:%d\tb:%d\tf:%d\ts:%d\te:%d\tLine:%d\tOfs:%6d \tBeg:%6d\tDur:%6d \r", pad(mS( eTyp( wE, wBFS,  c, b, e ) ),8), nMode, nPass, c, b, f, s, e, nLine, del, Beg, dur / nSmpInt
		
						endfor
					endfor
				endfor
			endfor
			// printf "\t\t\tComputeTotalPoints()  channel %d  counted %5d \tpoints per frame, MaxPoints was %5d \t -> new MaxPoints per frame : %5d \r", c, EndPt, MaxPt, max( EndPt, MaxPt )
			MaxPt = max( EndPt, MaxPt )
		endfor
		 // printf "\t\t\tComputeTotalPoints().. pass %d  counted %d  wrong begin times.\r", nPass, nWrongBegCnt 
		nPass += 1
	while ( nWrongBegCnt > 0 )

	wG[ kTOTAL_US ]	= MaxPt  * nSmpInt * gnProts


// 060419
	if ( mod( MaxPt, 2 )  == 1 )				// 060419  this is required by 'ADCBST' . The (rarely! occurring) violation of this condition issued a  Ced ADCBST error and prevented a script from running.....
		sprintf sBuf, "Unfortunately the script amounts to %d sample points, but an even number is required. Changing the duration of any segment (or blank etc.)  by %.3lfms will help.", MaxPt, nSmpInt/1000 
		Alert( kERR_FATAL,  sBuf )
		return	kERROR
	endif


	sprintf sBuf,  "ComputeTotalPoints()  computed %d points (= %.3lf s )  using a sample interval of  %g us  and  %d Protocol(s)   [Block(s):%d  Frames(bl0):%d  Sweeps(bl0):%d] ", MaxPt, gnProts * MaxPt  * nSmpInt / 1e6, nSmpInt, gnProts, eBlocks( wG ), eFrames(wFix, 0), eSweeps(wFix, 0)
	 printf  "\t\tOutElems  %s \r", sBuf
	// printf  "\t\tCed %s \r", sBuf
	if ( gRadDebgSel > 0  &&  PnDebgOutElems )
		printf  "\t\tOutElems  %s \r", sBuf
	endif
	if ( gRadDebgSel > 0  &&  pnDebgCed )
		printf  "\t\tCed %s \r", sBuf
	endif
	wG[ kPNTS ] 	= MaxPt
	return	MaxPt
End


Function		SupplyWavesCOMPChans( sFolder, wG, wIO )
// supply  waves for 'Sum,Aver,PoN...for display and computation
	string  	sFolder
	wave	wG
	wave  /T	wIO
	nvar		gRadDebgSel	   = root:uf:dlg:gRadDebgSel
	nvar		PnDebgOutElems = root:uf:dlg:Debg:OutElems
	variable	ioch
	string  	sWaveNm
	variable	nIO, c, cCnt
	for ( nIO = kIO_PON; nIO < kIO_MAX; nIO += 1 )					// for all Comp IO types
		cCnt	= ioUse( wIO, nIO )
		for ( c = 0; c < cCnt; c += 1 )
			sWaveNm	   = FldAcqioio( sFolder, wIO, nIO, c, cIONM )			// supply  real waves for 'Sum,Aver,PoN...for display and computation
			make  /O   	/N=	( wG[ kPNTS ]  )		$sWaveNm
			// printf "\t\t\tOutElems..SupplyWavesCompChans()    nIO:%2d   c:%2d\t%s \tPoints:%g  \r", nIO, c, pd( sWaveNm, 21), wG[ kPNTS ] 
			if ( gRadDebgSel > 1  &&  PnDebgOutElems )
				printf "\t\t\tOutElems..SupplyWavesCompChans()    nIO:%2d   c:%2d\t%s \tPoints:%g  \r", nIO, c, pd( sWaveNm, 21), wG[ kPNTS ] 
			endif
		endfor
	endfor
End


Function 		OutElemsAllToWaves( sFolder, wG, wIO, wVal, wFix, wEinCB, wELine, wE, wBFS )
// Step 9:  convert all elements of all  frames of all sweeps into one DAC wave  AND  store  SweepBeg/Len points in ioNr[ ][ ]
	string  	sFolder
	wave  /T	wIO, wVal
	wave	wG, wFix, wEinCB, wELine, wE, wBFS
	nvar		PnDebgOutElems	= root:uf:dlg:Debg:OutElems
	nvar		gRadDebgSel	 	= root:uf:dlg:gRadDebgSel
	nvar		gRadDebgGen		= root:uf:dlg:gRadDebgGen
	nvar		gnProts			= $ksROOTUF_ + sFolder + ":keep:gnProts"
	variable	nSmpInt			= wG[ kSI ]
	variable	nCntDA			= wG[ kCNTDA ]	
	variable	nPnts			= wG[ kPNTS ]
	variable	n, c, b = 0, f, s, e, nType


variable	nPts, nStoreCnt	= 0

	variable	nPntCnt		= 0
	variable	nSwpBegPt, nSwpBegInclBlank, nSwpEndPt

	wG[ kTOTAL_SWPS ]	= 0
	for ( b  = 0; b < eBlocks( wG ); b += 1 )								// we must loop through all blocks to count the total number of sweeps
		wG[ kTOTAL_SWPS ]	+= eFrames( wFix, b ) * eSweeps( wFix, b )
	endfor
	wG[ kTOTAL_SWPS ]	*=  gnProts


//	if ( gRadDebgSel > 0  &&  PnDebgOutElems )
		c = 0
		printf "\t\tOutElemsAllToWaves(2)\tc:%d \tTotDur[us]:%d    \t Swp00[us]:%d\t Frm0[us]:%d  TotalSweeps:%d    ( over %d Prots )\r", c, nPnts * nSmpInt, stGetDurSweep( wEinCB, wE, wBFS, c, b, 0, 0 ), stGetDurFrame( wFix, wEinCB, wE, wBFS, c, b, 0 ), wG[kTOTAL_SWPS], gnProts 
//	endif	

	// now (=very late) construct DAC stimulus  (as REAL) according to io data from script file
	if	( ! cPROT_AWARE )
		nPts	= nPnts
	else
		nPts	= nPnts * gnProts 
	endif
	
	// SupplyWaves... the primary DAC channel
	c = 0		
	make  /O  	/N=	( nPts )	$FldAcqioio( sFolder, wIO, kIO_DAC, c, cIONM ) 		// construct the wave with unique name..	
	wave  	wStimulus 	= 	$FldAcqioio( sFolder, wIO, kIO_DAC, c, cIONM ) 		// ..but use it here under an alias name 
// print "\t\t\tOutElemsAllToWaves  c=", c, "pts=", numpnts(wStimulus) 

	// copy data from the first protocol into all following protocols
	if (  cPROT_AWARE )	// 031006
		variable	pts 	= numPnts( wStimulus ) 
		if ( gnProts > 1 )
			wStimulus[  pts / gnProts, pts ] = wStimulus[ p - pts / gnProts] 	// TODO
		endif
	endif

	// Build the data structure which gives the point number for the beginning and the end of a certain protocol/block/frame/sweep
	// 041019  unused.... killwaves  /Z	root:uf:stim:wSwpTime				// we delete it as we must build it completely new in the first call to swSetTimes() below

	for ( b  = 0; b < eBlocks( wG ); b += 1 )									// loop through all blocks
		for ( f = 0; f < eFrames( wFix, b ); f += 1 )							// loop through all frames
			for ( s = 0; s < eSweeps( wFix, b ); s += 1 )						// loop through all sweeps 
	
				nSwpBegInclBlank	= nPntCnt							// will always include leading blank time
				nSwpBegPt		= nPntCnt							// will be changed to exclude leading blank time				
				stSwSetTimes( sFolder, wFix, b, f, s, SWPBEG, nSwpBegPt, gnProts, nPnts )	// set true sweep begin point including 'Blanks' . Protocol aware 031007 

				for ( e = 0; e < eElems( wEinCB, c, b ); e += 1 )				// loop through all elements (=Segments, Ramp..)
					nType = eTyp( wE, wBFS,  c, b, e ) 
		
					if ( e ==1  &&  eTyp( wE, wBFS,  c, b, 0 ) == mI( "Blank" )  &&  nType != mI( "Blank" ) )
						nSwpBegPt	= nPntCnt					// ..immediately following the 'Sweeps' keyword  (=the PreSweepInterval) 
						// printf  "\t\t\tOutElemsAllToWaves(pts:%d)  c:%d  b:%d  f:%d s:%d )  found PreSweepInterval \r", nTotalPts, c, b, f, s
					endif
					
					if ( gRadDebgSel > 2  &&  PnDebgOutElems ) // very slow : even if nothing is printed this line takes about  12 us to fill  the buffer and execute Out( bf ), with printing it takes 40 us ! 
						printf  "\t\t\t\tOutElemsAllToWaves(4) c:%d b:%d  f:%d s:%d e:%d\t%-12s\t starting at %6d \r", c, b, f, s, e, mS(nType),  nPntCnt
					endif
					// At  first we must  set.... then we  set  number of  buffer points ~ duration with amplitude of segment, ramp,...
					nPntCnt = stSetStimulus( wVal, wELine, wE, wBFS, nSmpInt, c, b, f, s, e , wStimulus ) 
					if ( nType  == mI( "Blank" ) )
						nSwpEndPt = max( nSwpBegPt, nSwpEndPt )	// ..we store the endpoint BEFORE SetStimulus() increases the point count 
						 // printf "\tOutElemsAllToWaves()  f:%d\ts:%d\te:%d   \t'%s'\tBg:\t%7d\tNd:\t%7d\t  \r ", f,s,e, mS( eTyp( wE, wBFS,  f,s,e )), nSwpBegPt, nSwpEndPt
					else										//... behind the continuously advancing BeginTime  / nSmpInt
						nSwpEndPt = nPntCnt
					endif
	
				endfor
	
				if ( gRadDebgSel > 1  &&  PnDebgOutElems )	// very slow : even if nothing is printed this line takes about  12 us to fill  the buffer and execute Out( bf ), with printing it takes 40 us ! 
					printf  "\t\t\tOutElemsAllToWaves(6)  c:%d  b:%d  f:%d s:%d \t\tStore Beg:%5d \tStore Len %5d \tStore End %5d  [ in points] \r", c, b, f, s, nSwpBegPt, nSwpEndPt - nSwpBegPt, nSwpEndPt
				endif
				stSwSetTimes( sFolder, wFix, b, f, s, SWPBEGSTORE, nSwpBegPt, gnProts, nPnts )		//  protocol aware 031007 
				stSwSetTimes( sFolder, wFix, b, f, s, SWPLENSTORE, nSwpEndPt - nSwpBegPt , 1, 0 ) 	// nProts is always 1 : this could be simplified    length is not protocol aware 031007 
				stSwSetTimes( sFolder, wFix, b, f, s, SWPLEN, nPntCnt - nSwpBegInclBlank, 1, 0 )		// nProts is always 1 : this could be simplified    length is not protocol aware 031007 

if ( cELIMINATE_BLANK )
				StoreTimesSet( sFolder, nStoreCnt, nSwpBegPt, nSwpEndPt )			// 031120
				nStoreCnt += 1
endif
			endfor 
		endfor
	endfor

if ( cELIMINATE_BLANK )
	if ( StoreTimesExpandAndRedim( sFolder, gnProts, nPnts, nStoreCnt ) )	// TODO: will not work yet with   cPROT_AWARE = 1							// 031120
		return	kERROR
	endif
endif

	//  SupplyWaves : process additional DAC channels ....now (=very late) construct DAC stimulus  according to io data from script file
	for ( c = 1; c < nCntDA; c += 1)	// or: eChans( wE ) 

		if	( ! cPROT_AWARE )
			nPts	= nPnts
		else
			nPts	=  nPnts * gnProts 
		endif

		// SupplyWaves... 
		make  /O  	/N=	( nPts )	$FldAcqioio( sFolder, wIO, kIO_DAC, c, cIONM ) 	// construct the wave with unique name (data type is real)..	
		wave  	wStimulus 	= 	$FldAcqioio( sFolder, wIO, kIO_DAC, c, cIONM )  	// ..but use it here under an alias name 

// print "\t\t\tOutElemsAllToWaves  c=", c, "pts=", numpnts(wStimulus) 

	// TODO ????  FOR  MULTIPLE DACS ALSO (see above for Dac0) ??? : copy data from the first protocol into all following protocols
//if (  cPROT_AWARE )	// 031006
//	variable	pts 	= numPnts( wStimulus ) 
//	printf " \t\t! cPROT_AWARE:  (only DAC0) copying prot 0 to prot 1.. %d  :  Dac wave has  %d * %d = %d  pts\r", gnProts, gnProts, pts / gnProts, pts  // 031006
//	if ( gnProts > 1 )
//		wStimulus[  pts / gnProts, pts ] = wStimulus[ p - pts / gnProts] 	// TODO
//	endif
//endif


		wStimulus	= 0										// clear old contents (only parts are overwritten by ADDITIONAL Dac channels)
		nPntCnt	= 0
		for ( b  = 0; b < eBlocks( wG ); b += 1 )
			for ( f = 0; f < eFrames( wFix, b ); f += 1 )					// loop through all frames
				for ( s = 0; s < eSweeps( wFix, b ); s += 1 )				// loop through all sweeps 
					for ( e = 0; e < eElems( wEinCB, c, b ); e += 1 )			// loop through all elements (=Segments, Ramp..)
						nType = eTyp( wE, wBFS,  c, b, e ) 
						if ( gRadDebgSel > 2  &&  PnDebgOutElems ) // very slow : even if nothing is printed this line takes about  12 us to fill  the buffer and execute Out( bf ), with printing it takes 40 us ! 
							printf  "\t\t\t\tOutElemsAllToWaves(8) c:%d b:%d f:%d s:%d e:%d\t%-12s\tstarting at %6d \tDur:%5d  \tAmp:%5.1lf \tx \r",c, b, f, s, e, mS(nType),  eVL( wE, wBFS, c, b, f, s, e, cBEG),  eVL( wE, wBFS, c, b, f, s, e, cDUR),  eVL( wE, wBFS, c, b, f, s, e, cAMP)
						endif
						nPntCnt = stSetStimulus( wVal, wELine, wE, wBFS, nSmpInt, c, b, f, s, e , wStimulus ) 
					endfor
				endfor 
			endfor
		endfor
	endfor


	if ( gRadDebgGen >= 1  || ( gRadDebgSel > 0  &&  PnDebgOutElems ) )
		// printf "\t\tOutElemsAllToWaves()\t WaveLists:%s      %s \r", WaveList( "Dac*", ";", "" ), WaveList( "Adc*", ";", "" )
		// printf "\t\tOutElemsAllToWaves()  computed  TotDur[us]:%d  SI:%d  TotPts:%d, \r", nPntCnt * nSmpInt, nSmpInt, nPntCnt
		// PoNx is not  yet ready .....
		// printf "\t\tOutElemsAllToWaves()  Points:%dk (%d)  SmpInt:%dus -> %.1lfs    Chans(incl.PoN....):%d  ->  Mem:%dMB   [ %s  %s  %s.....]\r", nPntCnt/1000, nPntCnt, nSmpInt, nPntCnt * nSmpInt /1e6, ioCnt( wIO ), ioCnt( wIO )*nPntCnt*BYTESPERPOINT/1e6, WaveList( "Dac*", ";", "" ), WaveList( "Adc*", ";", "" ), WaveList( "PoN*", ";", "" )
	endif


	// Check Dac order in IO part of script: the main Dac  MUST  be defined first, then the derived Dac. If not the swSetTimes() will store mixed-up numbers and CfsRead  may CRASH when trying to read a negative number of points.
	// Version 1
	if ( eVL( wE, wBFS, 0, 0, 0, 0, 0, cBEG ) > 0 ) 							// ch 0 = the first channel in the IO part ot the script must start at time 0
		Alert( kERR_FATAL,  "Dac lines must be reordered in IO section of the script so that the main Dac channel comes first." )
		return  kERROR
	endif
	//  Version 2 untested
	//for ( c = 1; c < nCntDA; c += 1)	// or: eChans( wE )     or:  root:uf:" + sFolder + ":nCntDA
	//	if ( eVL( wE, wBFS, c, 0, 0, 0, 0, cBEG ) <  eVL( wE, wBFS, 0, 0, 0, 0, 0, cBEG ) ) 	// ch 0 = the first channel in the IO part ot the script must have the earliest begin point of all Dac channels
	//		Alert( kERR_IMPORTANT,  "Dacs must be reordered in IO section of the script so that the main Dac channel comes first." )
	//	endif
	//endfor

End

// to do  display stimulus..


Function 		OutElemsSomeToWave( sFolder, wG, wIO, wVal, wELine, wE, wBFS, sSegList )
//  convert  segments passed as list to stimulus ( faster than OutElemsAllToWaves() which converts all segments) 
//  Differences and limitations compared to  OutElemsAllToWaves():
//  no digout is set  and no sweep times are set , so this works well for amplitudes but cannot  be used for times
	string  	sFolder
	wave  /T	wIO, wVal
	wave	wG, wELine, wE, wBFS
	string 	sSegList
	nvar		gRadDebgSel		= root:uf:dlg:gRadDebgSel
	nvar		PnDebgOutElems	= root:uf:dlg:Debg:OutElems
	variable	f, s, e, seg
	variable	nSegments	= ItemsInList( sSegList, sPSEP ) / 3
	variable	nSmpInt		= wG[ kSI ]
	wave  	wStimulus 		= $FldAcqioio( sFolder, wIO, kIO_DAC, 0, cIONM ) 					

	if ( gRadDebgSel > 0  &&  PnDebgOutElems )
		printf  "\t\tOutElemsSomeToWave(0) receives %g elements in '%s'.....\r", nSegments, sSegList[0,160] 
	endif
variable	c = 0		//? only first Dac
	for ( seg = 0; seg < nSegments; seg += 1 )				// loop through all passed segments
		f  = str2num( StringFromList( seg * 3 + 0, sSegList, sPSEP ) )
		s = str2num( StringFromList( seg * 3 + 1, sSegList, sPSEP ) )
		e = str2num( StringFromList( seg * 3 + 2, sSegList, sPSEP ) )
		//variable	SegBegPt = eVL( wE, wBFS, c, b, f, s, e, cBEG )
		// print f,s,e, SegBegPt
//?eblocks( wG )
variable	b = 0
		stSetStimulus( wVal, wELine, wE, wBFS, nSmpInt, c, b, f, s, e , wStimulus ) 
	endfor
End


static Function	stSetStimulus( wVal, wELine, wE, wBFS, nSmpInt, c, b, f, s, e , wStim ) 
	wave	/T	wVal
	wave	wELine, wE, wBFS
	variable	nSmpInt, c, b, f, s, e
	wave	wStim
	variable 	nType	= eTyp( wE, wBFS,  c, b, e )
	variable 	nPntCnt

	if ( nType == mI( "StimWave" ) ) 		// cannot use switch because switch needs constants...
		nPntCnt	=  stSetStimulusFromReadWave( wVal, wELine, wE, wBFS, c, b, f, s, e, nSmpInt, wStim )
	elseif ( nType  == mI( "Expo" ) )
		nPntCnt  = stSetStimulusFromExpo( wVal, wELine, wE, wBFS, c, b, f, s, e, nSmpInt, wStim )
	elseif ( nType  == mI( "Ramp" ) )
		nPntCnt	= stSetStimulusFromRamp( wE, wBFS, c, b, f, s, e, nSmpInt, wStim )
	else							// Segment, VarSegm, Blank
		nPntCnt	= stSetStimulusFromSegments( wE, wBFS, c, b, f, s, e, nSmpInt, wStim )
	endif
	return nPntCnt
End

static Function	stSetStimulusFromRamp( wE, wBFS, c, b, f, s, e, nSmpInt, wStim )
	wave	wE, wBFS
	variable	c, b, f, s, e, nSmpInt
	wave	wStim
	variable	scla		= eVL( wE, wBFS, c, b, f, s, e, cSCA_ )
	variable	amp		= eVL( wE, wBFS, c, b, f, s, e, cAMP ) 
	variable 	BegPt	= eVL( wE, wBFS, c, b, f, s, e, cBEG )
	variable 	pts		= eVL( wE, wBFS, c, b, f, s, e, cDUR ) / nSmpInt	
	variable	LastAmp	=  BegPt >= 1  ?  wStim[ BegPt - 1 ] : 0		// 1. no scla here as preceding segment has included scla already   2. use amp=0  if the first data point is ramp start
	if ( pts )												// Igor behaviour: even if  endpoint is before startpoint waveform arithmetic copies.....
		wStim[ BegPt, BegPt + pts - 1 ] = LastAmp + ( p - BegPt ) * ( amp * scla - LastAmp ) / pts	// waveform arithmetic is faster.. 
	endif
	return BegPt + pts
End

static Function	stSetStimulusFromSegments( wE, wBFS, c, b, f, s, e, nSmpInt, wStim )
	wave	wE, wBFS
	variable	c, b, f, s, e, nSmpInt
	wave	wStim
	variable	scla		= eVL( wE, wBFS, c, b, f, s, e, cSCA_ )
	variable	amp		= eVL( wE, wBFS, c, b, f, s, e, cAMP ) 
	variable 	BegPt	= eVL( wE, wBFS, c, b, f, s, e, cBEG )
	variable 	pts		= eVL( wE, wBFS, c, b, f, s, e, cDUR ) / nSmpInt	
	if ( pts )												// Igor behaviour: even if  endpoint is before startpoint waveform arithmetic copies.....
		wStim[ BegPt, BegPt + pts -1 ] = amp * scla					// waveform arithmetic	// for ( i = 0; i < pts; i += 1 ) wStim[ BegPt + i ] = amplitude * scla  
	endif
	// printf "\tSetStimulusFromSegments( c:%d, b:%d, f:%d, s:%d, e:%d, nSmpInt:%d, wStim ) ->scla:%g  \tamp:%7.3g\tBegPt:%5d  \tpts:%5d \r",  c, b, f, s, e, nSmpInt, scla, amp, BegPt ,pts
	return BegPt + pts
End


constant	AMPLI = 0, TRISE = 1, TDEC = 2, DELTAT = 3, SCLY = 4, EXPOSIZE = 5

Static Function 	stSetStimulusFromExpo( wVal, wELine, wE, wBFS,c, b, f, s, e, nSmpInt, wStim )
// Builds stimulus wave ' wStimul'  from values in ' wEl', 
//!  THIS  FUNCTION  DETERMINES  THE  ORDER  OF  THE  ENTRIES  IN  THE  SCRIPT
// test.... expo values are not bracketed.....but could be....
	wave	/T	wVal
	wave	wELine, wE, wBFS
	variable	c, b, f, s, e, nSmpInt
	wave	wStim
	nvar		gRadDebgSel 		= root:uf:dlg:gRadDebgSel
	nvar		PnDebgOutElems	= root:uf:dlg:Debg:OutElems
	string		sOneExpo, sExpo	= vGES( wVal, wELine, c, b, f,  e, "AmpTau" )
	variable	pt, tdt, n, 	nExpo	= ItemsInList( sExpo, "/"  )		// number of exponential functions to combine
	variable 	BegPt			= eVL( wE, wBFS, c, b, f, s, e, cBEG )
	variable 	pts				= eVL( wE, wBFS, c, b, f, s, e, cDUR ) / nSmpInt	

	variable	ScalePoN	= eVL( wE, wBFS, c, b, f, s, e, cSCA_ )
	// printf  "\t\tOutElems..SetStimulusFromExpo   BegPt:%6d \tb:%d  f:%d  s:%d  e:%d  nExpo:%d  PtsDA:%4d\tSclAPon:%g\t'%s'  \r",  BegPt, b, f, s, e, nExpo, pts, ScalePoN, sExpo

	if ( gRadDebgSel > 0  &&  PnDebgOutElems )
		printf  "\t\tOutElems..SetStimulusFromExpo   BegPt:%6d \tb:%d  f:%d  s:%d  e:%d  nExpo:%d  PtsDA:%4d\tSclAPon:%g\t'%s'  \r",  BegPt, b, f, s, e, nExpo, pts, ScalePoN, sExpo
	endif

	make  /O  /N=( nExpo, EXPOSIZE )	wExpo
	for ( n = 0; n < nExpo;  n += 1 )
		sOneExpo	= StringFromList( n, sExpo, "/" )
		// Step 1: try to read value from script.....
		wExpo[ n ][ AMPLI ]	= str2num( StringFromList( AMPLI, sOneExpo, "," ) )		// Amp
		wExpo[ n ][ TRISE ]	= str2num( StringFromList( TRISE, sOneExpo, "," ) )		// TauRise	 
		wExpo[ n ][ TDEC ]	= str2num( StringFromList( TDEC, sOneExpo, "," ) )		// TauDecay	 
		wExpo[ n ][DELTAT]	= str2num( StringFromList( DELTAT, sOneExpo, "," ) )		// Time difference between the exponentials	 
		wExpo[ n ][ SCLY ]	= str2num( StringFromList( SCLY, sOneExpo, "," ) )		// Scale factor for all exponentials
		// printf "\t\t\tSetStimulusFromExpo() c:%d  b:%d  f:%d  s:%d  e:%d \tnExpo:%2d/%2d\t'%s'\tReads:%6.1lf\t%6.1lf\t%6.1lf\t%6.1lf\t%6.1lf", c, b, f, s, e, n, nExpo, pad(sOneExpo,12),  wExpo[ n ][ AMPLI ] ,  wExpo[ n ][ TRISE ] ,  wExpo[ n ][ TDEC ], wExpo[ n ][ DELTAT ], wExpo[ n ][ SCLY ] 
		if ( gRadDebgSel > 1  &&  PnDebgOutElems )
			printf "\t\t\tSetStimulusFromExpo() c:%d  b:%d  f:%d  s:%d  e:%d \tnExpo:%2d/%2d\t'%s'\tReads:%6.1lf\t%6.1lf\t%6.1lf\t%6.1lf\t%6.1lf", c, b, f, s, e, n, nExpo, pad(sOneExpo,12),  wExpo[ n ][ AMPLI ] ,  wExpo[ n ][ TRISE ] ,  wExpo[ n ][ TDEC ], wExpo[ n ][ DELTAT ], wExpo[ n ][ SCLY ] 
		endif
		// Step 2: ...if script value is missing (this is OK for all but first exponential) :  take value of preceding exponential...
		wExpo[ n ][ AMPLI ]	= numType( wExpo[ n ][ AMPLI ] ) == kNUMTYPE_NAN ? wExpo[ n - 1 ][ AMPLI ] : wExpo[ n ][ AMPLI ]	
		wExpo[ n ][ TRISE ]	= numType( wExpo[ n ][ TRISE ] ) == kNUMTYPE_NAN ? wExpo[ n - 1 ][ TRISE ] : wExpo[ n ][ TRISE ]
		wExpo[ n ][ TDEC ]	= numType( wExpo[ n ][ TDEC ] )  == kNUMTYPE_NAN ? wExpo[ n - 1 ][ TDEC ] : wExpo[ n ][ TDEC ]	
		wExpo[ n ][DELTAT]	= numType( wExpo[ n ][DELTAT]) == kNUMTYPE_NAN ? wExpo[ n - 1 ][DELTAT] : wExpo[ n ][DELTAT]	
		wExpo[ n ][ SCLY ]	= numType( wExpo[ n ][ SCLY ] )	  == kNUMTYPE_NAN ? wExpo[ n - 1 ][ SCLY ] : wExpo[ n ][ SCLY ]	
		// Step 3: ...if  value of preceding exponential is missing (which is a script error) : use some default so that user sees at least some exponential
		wExpo[ n ][ AMPLI ]	= numType( wExpo[ n ][ AMPLI ] ) == kNUMTYPE_NAN ? 1000 : wExpo[ n ][ AMPLI ]	
		wExpo[ n ][ TRISE ]	= numType( wExpo[ n ][ TRISE ] ) == kNUMTYPE_NAN ? 2000 : wExpo[ n ][ TRISE ]	
		wExpo[ n ][ TDEC ]	= numType( wExpo[ n ][ TDEC ] ) == kNUMTYPE_NAN ? 3000 : wExpo[ n ][ TDEC ]	
		wExpo[ n ][DELTAT]	= numType( wExpo[ n ][DELTAT])== kNUMTYPE_NAN ? 4000 : wExpo[ n ][DELTAT]	
		wExpo[ n ][ SCLY ]	= numType( wExpo[ n ][ SCLY ] )	 == kNUMTYPE_NAN ?   1	   : wExpo[ n ][ SCLY ]	
		// printf "\tCompletes:\t%6.1lf\t%6.1lf\t%6.1lf\t%6.1lf\t%6.1lf \r", wExpo[ n ][ AMPLI ] ,  wExpo[ n ][ TRISE ] ,  wExpo[ n ][ TDEC ], wExpo[ n ][ DELTAT ], wExpo[ n ][ SCLY ] 
		if ( gRadDebgSel > 1  &&  PnDebgOutElems )
			printf "\tCompletes:\t%6.1lf\t%6.1lf\t%6.1lf\t%6.1lf\t%6.1lf \r", wExpo[ n ][ AMPLI ] ,  wExpo[ n ][ TRISE ] ,  wExpo[ n ][ TDEC ], wExpo[ n ][ DELTAT ], wExpo[ n ][ SCLY ] 
		endif
	endfor	
	wStim[ BegPt, BegPt + pts - 1 ]	 = 0								// 030403  clear exponential stimulus left over from previous sweep
	for ( pt = 0; pt < pts;  pt += 1 )
		for ( n = 0; n < nExpo;  n += 1 )
// 2009-12-22  why  n * expoDeltat ???  Like in V3  assume aequidistant expos
			tdt =  max( 0,  pt * nSmpInt  - n * wExpo[ n ][ DELTAT ] )		// clip values earlier than t=0 to zero
//			tdt =  max( 0,  pt * nSmpInt  -	wExpo[ n ][ DELTAT ] )		// clip values earlier than t=0 to zero
			// the combined multiple exponential function
			variable	ToAdd =( wExpo[ n ][ AMPLI ] * ( exp( -tdt / wExpo[ n ][ TRISE ] ) - exp( -tdt / wExpo[ n ][ TDEC ] ) ) ) * wExpo[ n ][ SCLY ]  
			//if ( pt < 5 )
			//	printf "\tExpo() c:%d  b:%d  f:%d  s:%d  e:%d  n:%d /%d \tpt:%2d/%2d \twStim[]:%6.2lf\tScP:%d \ttdt:%6.2lf \tBegPt:%4d\tampli:%6.2lf\trise:%6.2lf\tdec:%6.2lf\tscly:%6.2lf\ttoadd:%6.2lf\t  \r" c,b,f,s,e,n, nExpo, pt, pts, wStim[ BegPt + pt ], ScalePoN, tdt,  BegPt, wExpo[ n ][ AMPLI ] ,  wExpo[ n ][ TRISE ],  wExpo[ n ][ TDEC ], wExpo[ n ][ SCLY ] , ToAdd  
			//endif
			wStim[ BegPt + pt ] += ToAdd
		endfor
	endfor
	wStim[ BegPt, BegPt + pts - 1 ]	 *= ScalePoN						// make PoN correction work
	KillWaves	wExpo
	return	BegPt + pts
End


// Design issue:
// not needed when script duration entry ( and not actual stimwave points) determines stimwave intervall duration 
//
//static Function   stSetNumberOfPointsFromReadWave( c, b, f, s, e )
//// does not yet read wave file: reads only number of points of wave found  at location frame f, element e
////	Design issue:
////	A Stimwave is inserted point by point into the stimulus DAC wave, a stimwave time scaling (=deltaX) is ignored.
////	To produce meaningful results the SmpInt in the StimWave ( =SclD=deltaX(wav) ) must be equal to that of the DAC (=SmpInt)..
////	It is the users responsibility that the SmpInt in the StimWave ( =SclD=deltaX(wav) ) is equal to that of the DAC (=SmpInt)..
//// 	if one wanted to allow different sample rates, one has to incorporate some kind of  time interpolation. 
//
//	variable		c, b, f, s, e
//	variable		nPts = 0
//	variable		bPathExists	=  v_Flag
//	string		sFileNameExt = ExtractStimwaveName( c, b, f, s, e )
//	string		sWaveName	=  StripPathAndExtension( sFileNameExt )
//	PathInfo  /S	symbPath		// sets v_Flag  and  S_path
//	variable		bFileExists	=  PathAndFileExists( S_path, sFileNameExt  )
//	// printf  "\t\tSetNumberOfPointsFromReadWave()   f:%d  s:%d  e:%d   File name: '%s' -> '%s'  exists:%d, SymbPath '%s' exists:%d.  \r", f, s, e, sFileNameExt, sWaveName, bFileExists, S_path, bPathExists
//	if ( bPathExists  &&  bFileExists )
//		LoadWave  /Q  /O /P=symbPath sFileNameExt			// of type IBW  Igor Binary wave
//		// original wave names are saved by IGOR internally within xxx.IBW and restored on LoadWave, even if xxx.IBW has been renamed
//		sWaveName	= StringFromList( 0, S_waveNames, ";" )	// take first (=the only) entry and remove trailing ";"
//		nPts			= numPnts( $sWaveName )	
//	else
//		printf "++++Error: StimWave file '%s' (%s)  not found in '%s'  [ Frame:%d  Sweep:%d  Ele:%d ] . \r", sFileNameExt,  sWaveName, S_path, f, s, e 
//	endif
//	return nPts * nSmpInt
//End


static Function   stSetStimulusFromReadWave( wVal, wELine, wE, wBFS, c, b, f, s, e, nSmpInt, wStimulus )
// reads wave file: data  values of wave found in wEleNam and in wEl at location frame f, element e
	wave	/T	wVal
	wave	wELine, wE, wBFS
	wave	wStimulus
	variable	c, b, f, s, e, nSmpInt
	variable	pts		= eVL( wE, wBFS, c, b, f, s, e, cDUR ) / nSmpInt
	variable 	BegPt	= eVL( wE, wBFS, c, b, f, s, e, cBEG )
	string  	bf
	if ( pts )													// Zero has been stored in SetNumberOfPointsFromReadWave()  if  LoadWave has  failed at that time
		variable	SclA			= eVL( wE, wBFS, c, b, f, s, e, cSCA_ ) 
		variable	OfsA			= eVL( wE, wBFS, c, b, f, s, e, cDAM ) 				// 040519 !!! Rather than introducing new constants cOFSA and cSCLX...					
		variable	SclX			= eVL( wE, wBFS, c, b, f, s, e, cAMP ) 				//...we misuse existing ones which are not used in StimWave (see also  'ExtractEValues()'  )				
		string  	sFileNameExt	= ExtractStimwaveName( wVal, wELine, c, b, f, s, e )
		PathInfo  /S	symbPath									// sets v_Flag  and  S_path
		variable	bFileExists		=  PathAndFileExists( S_path, sFileNameExt  )
		if ( bFileExists )
			if ( FileHasExtension( sFileNameExt, ".IBW" ) )
				// printf  "\t\tSetStimulusFromReadWave()  c:%d\tb:%d\tf:%d\ts:%d\te:%d\tSymbPath and File name '%s' exist. \tSclA:\t%7.2lf\tOfsA:\t%7.2lf\tSclX:\t%7.2lf\tReading IgorBinaryWave \r", c, b, f, s, e, sFileNameExt, SclA, OfsA, SclX
				LoadWave  /Q  /O /P=symbPath sFileNameExt			// of type IBW  Igor Binary wave
				// original wave names are saved by IGOR internally within xxx.IBW and restored on LoadWave, even if xxx.IBW has been renamed
	
				wave	wav		= $StringFromList( 0, S_waveNames, ";" )	// take first (=the only) entry and remove trailing ";"
				variable	wavPts	= numPnts( wav )
		
				// The stimulus and the wave to be inserted can have different x scaling if the sample intervals are different (deltax~SmpInt) . 
				// If this is the case then interpolation is used so that the time course of the inserted wave is maintained ( points are inserted or deleted to make the sample intervals match ) .
				
				// The stimulus and the wave to be inserted can also have a different number of points. 
				//  If this is the case then the inserted wave is either truncated  or filled with 0  ( ? or with the value of the last data point ) so that the interval length required by the script is achieved.

				// Step 1: Possibly interpolate if the sample intervals do not match but do not change length				
				variable	StimulusDeltaX	= deltax( wStimulus ) * nSmpInt / kMILLITOMICRO / kMILLITOMICRO 
				 printf "\t\tSetStimulusFromReadWave()	wav: '%s'  has pts: %d  value[25]: %6.3lf \tStimulusDeltaX: %.6lf  \tdeltax( wStimulus ): %.6lf \r", StringFromList( 0, S_waveNames, ";" ), wavPts, wav[25], StimulusDeltaX,  deltax( wStimulus ) 

				if ( StimulusDeltaX != deltax( wav ) * SclX )
					variable	nRequiredWavePts	= round( wavPts * deltax( wav ) * SclX / StimulusDeltaX ) // keep length and x axis scaling from original wave....
					make	 /O	/N=(nRequiredWavePts)		wavIP
					interpolate2 	/N=(nRequiredWavePts)	/Y = wavIP   wav					   // ...but insert or delete points so that sample intervals are equal
					sprintf  bf, "X scaling Stimulus: %.6lf , StimWave: %.6lf  ( SmpInt: %.2lf , %.2lf us ). Adjusting points from %d to %d . [UserXScl:%g] ", StimulusDeltaX , deltax( wav ), nSmpInt, deltax( wav ) *  kMILLITOMICRO * kMILLITOMICRO, wavPts, nRequiredWavePts , SclX
					Alert( kERR_LESS_IMPORTANT,  bf )
					wavpts = 	nRequiredWavePts	
					// If the following line is active : Keep original time course = use the sample interval interpolation. If the following line is commented : Keep original number of points = resulting time course may be slower or faster than original
					Duplicate	/O 	wavIP	wav	          							// 040519 Keep original time course = use the sample interval interpolation. Comment out to keep original number of points (also disable user xScl ) 
				endif
				// printf "\t\t%s\r", bf
	
				// Step 2: Possibly truncate or fill up wave to be inserted if the lengths do not match				
				wStimulus[ BegPt, BegPt + wavPts - 1 ] = SclA * ( wav[ p-BegPt ] + OfsA )	// 
				if ( wavPts != pts )
					string  	sText	= "truncated"
					if ( wavPts < pts )
						sText	= "padded with 0 up"
						wStimulus[ BegPt + wavPts, BegPt + pts - 1 ] = 0		// pad the missing wave points with 0, (too many wave points are simply ignored)
					endif
					Alert( kERR_LESS_IMPORTANT,  "Stimwave file '" + sFileNameExt + "' having " + num2str(wavPts) + " points giving an interval of " + num2str(wavPts*nSmpInt/kMILLITOMICRO) + " ms is " + sText + " to " + num2str(pts*nSmpInt/kMILLITOMICRO) + " ms as specified in script." )
				endif
			else
				// Handle  two column  ASCII files  like  ApWave.xxx	(can have any extension)
				// printf  "\t\tSetStimulusFromReadWave()  c:%d\tf:%d\ts:%d\te:%d\tSymbPath and File name '%s' exist. \tReading ASCII file.\r", c, b, f, s, e, sFileNameExt
				stReadASCIIStimWave( sFileNameExt, nSmpInt, wStimulus, BegPt, pts, SclA, OfsA, SclX )	// 040519 !!! Rather than introducing new constants cOFSA and cSCLX we misuse existing ones which are not used in StimWave (see SetStimulusFrom...
			endif
		else
			Alert( kERR_IMPORTANT,  "Stimwave file '" + sFileNameExt + "' not found . Filling the missing data interval of " + num2str(pts*nSmpInt/kMILLITOMICRO) + " ms (" + num2str(pts) + " points) with 0. " ) 
			wStimulus[ BegPt, BegPt + pts - 1 ] = 0						// waveform arithmetic
		endif
	endif
	return BegPt + pts
End



constant		HELP_IGOR_TO_ROUND	= 1e-6			// try this on the command line : print .6 < 6/10;  print .6 == 6/10;  print .6 > 6/10


static Function  stReadASCIIStimWave( sFilePath, nSmpInt, wStimul, BegPt, pts, SclA, OfsA, SclX  )
	string  	sFilePath								// can be empty ...
	wave	wStimul
	variable	nSmpInt, BegPt, pts, SclA, OfsA, SclX 
	variable	nRefNum, nLines = 0, n, nWav, ScrTim, ScrVal, deltaY
	string	sLine = ""
	Open /Z=2 /R /P=symbPath  nRefNum  as sFilePath		// /Z = 2:	opens dialog box  if file is missing
	if ( nRefNum != 0 )									//  3 failure modes: script file missing, settings file containing script file is missing, user cancelled file open dialog
		// Pass 1 : Count the lines
		do 											// ..if  ReadPath was not an empty string
			FReadLine nRefNum, sLine
			// printf "ReadASCIIStimWave  was asked to open '%s'  and has read line:%d  (len:%d)   \t '%s' \r", sFilePath, nLines, strlen( sLine ), sLine

			nLines += 1
		while ( strlen( sLine ) > 0 ) 						//...is not yet end of file EOF

		// Pass 2 : Read the data in temporary waves
		FSetPos nRefNum, 0							// go back to begin of file				
		nLines -= 2									// do not count the first header line and do not count the last empty line
		make /O /N=( nLines )	wReadTim, wReadVal

		FReadLine nRefNum, sLine
		// printf "\t\tReadASCIIStimWave ('%s') has read the header line plus %d data lines.  Header: %s", sFilePath, nLines, sLine //includes trailing CR

		for ( n = 0; n < nLines; n += 1)
			FReadLine nRefNum, sLine
			sscanf  sLine, "%f %f ", ScrTim, Scrval			// try to read 2-column data even if it is only 1 column
			if ( V_flag == 2 )							// V_flag holds the number of items read
				wReadTim[ n ]	= ScrTim				// 2-column data: time, Yvalue
				wReadVal[ n ]	= ScrVal
			else										// 1-column data: Yvalue
				wReadTim[ n ]	= n * nSmpInt / kMILLITOMICRO
				wReadVal[ n ]	= ScrTim
			endif
			// printf "\t\t\tReadASCIIStimWave ('%s') Pass2  \t%d Cols\tn:%d\t\ttime:\t%g     \tValue:\t%g %s\r", sFilePath, V_Flag, n,  wReadTim[ n ], wReadVal[ n ], SelectString( n==nLines-1, "", "\r" ) 
		endfor
		Close nRefNum

		// Pass 3 : Let first wave point start a time 0 = remove time offset of wave data (but keep time interval of wave data)
		variable	WavTimeOfs = wReadTim[ 0 ]
		for ( n = 0; n < nLines; n += 1)
			wReadTim[ n ] = wReadTim[ n ] - WavTimeOfs
			// printf "\t\t\tReadASCIIStimWave ('%s') Pass3 \tn:%d\t\ttime:\t%g     \tValue:\t%g \r", sFilePath, n,  wReadTim[ n ], wReadVal[ n ] 
		endfor

		// Pass 4 : Scale  time and value of temporary waves so that it  fits into the stimulus
		for ( n = 0; n < pts; n += 1)
			string	sFlag = "   \t"
			ScrTim = n * nSmpInt / kMILLITOMICRO
			// printf "\t\t\tReadASCIIStimWave (pass4)  \tscrN:%3d/%3d\t scrTim:%.2lf\t  >=?   ReadTim[ %2d ]:%.2lf ", n, pts,  ScrTim,  nWav + 1,  wReadTim[ nWav + 1 ]	// line will be continued below...

			if ( ScrTim >= SclX * wReadTim[ nWav + 1 ] - HELP_IGOR_TO_ROUND )		

				do			// step over some read stimwave data if read time step is smaller than step to compute which is ~nSmpInt
		
					nWav += 1
					sFlag	= ">=\t"

				while ( ScrTim >= SclX * wReadTim[ nWav + 1 ] - HELP_IGOR_TO_ROUND   &&   nWav  <  numPnts( wReadTim )  )		

			endif

			deltaY = ( ScrTim - SclX * wReadTim[ nWav ] ) / SclX	/ ( wReadTim[ nWav  + 1 ] - wReadTim[ nWav ] ) *  ( wReadVal[ nWav  + 1 ] - wReadVal[ nWav ] )	// Do a linear interpolation
			wStimul[ BegPt + n ] = 	SclA * ( wReadVal[ nWav ] +  deltaY   + OfsA )	

			// printf "%sReadVal[ Idx:%2d\tTim:%.2lf ] \t= %.2lf\t+dy:%.3lf\t= %.2lf\t[SclA:\t%7g\tOfsA:\t%7g\tSclX:\t%7g] \r" , sFlag, nWav, wReadTim[ nWav ], wReadVal[ nWav ], deltaY, wStimul[ BegPt + n ] , SclA, OfsA, SclX	//..finalise line from above
		endfor

//... NOT THOROUGHLY  TESTED...
// to do 1... read first header line , extract  pA  and  ms   
// to do 3.. number point is too small  or too big: Nans.... or missing...
// to do 4.. IGOR spline is perhaps better than the linear interpolation done here


		KillWaves	wReadTim, wReadVal
	else
		Alert( kERR_FATAL,  "Could not open '" + sFilePath + "' " )	
	endif
End




Function   /S	ChangeAllOccurences( wG, wFix, wEinCB, wE, wBFS, sMainKey, sSubKey, Value )
// changes a value defined by its mainkey and its subkey in all frames and sweeps (e.g 'VarSegm', 'Amp' )
//  works well for amplitudes but if  used for times  then SwpTimes have again to be computed 
	wave	wG, wFix, wEinCB, wE, wBFS
	string 	sMainKey, sSubKey
	variable	Value 
	variable	c = 0, b, f, s, e, OldValue, cnt = 0
	string	sSegList = ""
	for ( b  = 0; b < eBlocks( wG ); b += 1 )
		for ( f  = 0; f < eFrames( wFix, b ); f += 1 )
			for ( s = 0; s < eSweeps( wFix, b ); s += 1 )
				for ( e = 0; e < eElems( wEinCB, c, b); e += 1 )
					if ( cmpstr( mS( eTyp( wE, wBFS,  c, b, e ) ), sMainKey ) == 0 )	// the mainkey matches... 			
						OldValue = eVL( wE, wBFS, c, b, f, s, e, cAMP ) 			// ..and the subkey...
						if ( OldValue != kNUMTYPE_NAN )				// ..matches also..
							eSet( wE, wBFS,  c, b, f, s, e, cAMP, Value )			// ..so replace OldValue by Value
							sSegList += num2str( f )+ sPSEP + num2str( s )+ sPSEP + num2str( e ) + sPSEP 		// only one separator
							// printf "\t\t\t\tChangeAllOccurences() changed '%s' in '%s' (c:%d f:%d s:%d e:%d) from %g to %g \r", sSubKey, sMainKey, c, b, f, s, e, OldValue, Value
							cnt += 1
						endif
					endif
				endfor
			endfor
		endfor
	endfor
	// printf "\t\tChangeAllOccurences( '%s', '%s', %g )  changed %d times \r", sMainKey, sSubKey, Value, cnt
	return sSegList	
End


static Function	stGetDurFrame( wFix, wEinCB, wE, wBFS, c, b, f )
// returns duration of one frame ' f ', i.e. original plus PoverN-Sweeps..
// plus 1 InterFrmInterval plus nSweeps * ( PreSwpInt + InterSwpInt )
	wave	wFix, wEinCB, wE, wBFS
	variable	c, b, f	
	variable	s, dur = 0
	for ( s = 0; s < eSweeps( wFix, b ); s += 1 )
		 dur += stGetDurSweep( wEinCB, wE, wBFS, c, b, f, s )
		 dur += stGetDurSweepBlank( wEinCB, wE, wBFS, c, b, f, s )
		 dur += stGetDurFrameBlank( wEinCB, wE, wBFS, c, b, f, s )
	endfor
	return  dur
End

static Function	stGetDurSweep( wEinCB, wE, wBFS, c, b, f, s )
// returns duration of one sweep 's' in one frame ' f ' (original-  or PoverN-sweep) without PreSwpInt without InterSwpInt
	wave	wEinCB, wE, wBFS
	variable	c, b, f, s		// frame, sweep
	nvar		gRadDebgSel 		= root:uf:dlg:gRadDebgSel
	nvar		PnDebgOutElems 	= root:uf:dlg:Debg:OutElems
	variable	e, dur = 0
	for ( e = 0; e < eElems( wEinCB, c, b ); e += 1 )			// loop through all elements (=Segments, Ramp..)
		if ( eTyp( wE, wBFS,  c, b, e )  != mI( "Blank" ) )				// the InterFrmInterval is 'Blank' so it is automatically excluded here
			dur += eVL( wE, wBFS, c, b, f, s, e, cDUR )
		endif							
	endfor
	if ( gRadDebgSel > 1  &&  PnDebgOutElems  )
		printf  "\t\t\tOutElems  GetDurSweep(elems:%d) \t\t\t c:%d\tb:%2d  f:%2d s:%2d  Dur %d us \r", eElems( wEinCB, c, b ), c, b, f, s, dur
	endif
	return  dur
End

static Function	stGetDurSweepBlank( wEinCB, wE, wBFS, c, b, f, s )
// returns duration of ....
//     F0-PSI  F0-psi  F0-psi  F0-psi   IntFI    F1-PSI  F1-psi  F1-psi  F1-psi   IntFI    F2-PSI  F2-psi ...  
	wave	wEinCB, wE, wBFS
	variable	c, b, f, s		// frame, sweep
	nvar		gRadDebgSel 		= root:uf:dlg:gRadDebgSel
	nvar		PnDebgOutElems 	= root:uf:dlg:Debg:OutElems
	variable	e, dur = 0
	for ( e = 0; e < eElems( wEinCB, c, b ); e += 1 )								// loop through all elements (=Segments, Ramp..)
		if ( eTyp( wE, wBFS,  c, b, e )  == mI( "Blank" ) &&  ! stIsInterFrameInterval( wEinCB, c, b, f, s, e ) )	// the InterFrmInterval does NOT belong... 
			dur += eVL( wE, wBFS, c, b, f, s, e, cDUR )									// ..to any sweep, it belongs to the frame
		endif							
	endfor
	if ( gRadDebgSel > 1  &&  PnDebgOutElems )
		printf  "\t\t\tOutElems  GetDurSweepBlank(elems:%d) \t\t c:%d\tb:%2d  \t f:%2d s:%2d  Dur %d us \r", eElems( wEinCB, c, b ), c, b, f, s, dur
	endif
	return  dur
End

static Function	stGetDurFrameBlank( wEinCB, wE, wBFS, c, b, f, s )
// returns duration of  InterFrmInterval.  The IFI  has already been set to zero length in all sweeps except the last, so we can add all sweeps as well....
//     F0-PSI  F0-psi  F0-psi  F0-psi   IntFI    F1-PSI  F1-psi  F1-psi  F1-psi   IntFI    F2-PSI  F2-psi ...  
	wave	wEinCB, wE, wBFS
	variable	c, b, f, s		// frame, sweep
	nvar		gRadDebgSel 		= root:uf:dlg:gRadDebgSel
	nvar		PnDebgOutElems 	= root:uf:dlg:Debg:OutElems
	variable	e, dur = 0
	for ( e = 0; e < eElems( wEinCB, c, b ); e += 1 )			// loop through all elements (=Segments, Ramp..)
		if ( stIsInterFrameInterval( wEinCB, c, b, f, s, e ) )
			dur += eVL( wE, wBFS, c, b, f, s, e, cDUR )
		endif							
	endfor
	if ( gRadDebgSel > 1  &&  PnDebgOutElems )
		printf "\t\t\tOutElems  GetDurFrameBlankDur(elems:%d)\t\t c:%d\tb:%2d  \t f:%2d s:%2d  Dur %d us (=InterFrameInterval) \r", eElems( wEinCB, c, b ), c, b, f, s, dur
	endif
	return  dur
End

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	INTERFACE  FOR   wE
//	these functions hide the ' wE'   implementation completely
//	' wE' : last stage of data refinement, element orientated
//	contains different frames, Loop expansion, PoverN, Inc/Decrement
//	only ' wE' can be used for final stimulus generation, e.g. 'Segment,Ramp,StimWave,Amp,Dur...' 

Function  		eTyp( wE, wBFS, c, b, e )
// returns value  from ' wE'[ nChan ][ nBlk ][ nFrm=0 ][ nSwp=0 ][ nEle ][ nKey=cTYP=0 ] which is the index of mainkey
	wave	wE, wBFS
	variable	c, b, e
	return	eVL( wE, wBFS, c, b, 0, 0, e, cTYP )	
End 

Function  		eChans( wE )
	wave	wE
	return	dimSize( wE, 0 )		// the number of DacChans in script    or    nCntDA    or     ioUse( "Dac" )
End 

Function  		eMaxBFS( wE )
// the sum of all sweeps of all frames of all blocks
	wave	wE
	return	dimSize( wE, 1 )
End 

Function  		eMaxElems( wE )
	wave	wE	
	return	dimSize( wE, 2 )
End 

Function  		eKeys( wE )
	wave	wE	
	return	dimSize( wE, 3 )
End 

Function   		eBlocks( wG )
	wave	wG
	return	wG[ kBLOCKS ]
End 

Function  		eMaxFrames( wG, wFix )
	// this value is stored after the last real value:  index = dimension
	wave	wG, wFix
	return	wFix[ eBlocks( wG ) ][ cFRM ]
End

Function  		eMaxSweeps( wG, wFix )
	// this value is stored after the last real value:  index = dimension
	wave	wG, wFix
	return	wFix[ eBlocks( wG ) ][ cSWP ]
End

Function  		eFrames( wFix, b )
// return the number of frames in this block
	wave	wFix
	variable	b
	return	wFix[ b ][ cFRM ]
End 

Function  		eSweeps( wFix, b )
// return the number of sweeps in this block
	wave	wFix
	variable	b
	return	wFix[ b ][ cSWP ]
End 

Function  		ePoN( wFix, b )
// return the whether P over N must be executed in this block 
	wave	wFix
	variable	b
	return	wFix[ b ][ cPON ]
End 

Function  		eCorrAmp( wFix, b )
// returns the P over N correction factor to be used in this block 
	wave	wFix
	variable	b
	return	wFix[ b ][ cCORA ]
End 

Function  		eCorrAmpSet( wFix, b, value )
// returns the P over N correction factor to be used in this block 
	wave	wFix
	variable	b, value
	wFix[ b ][ cCORA ] = value
End 


Function  		eElems( wEinCB, c, b )
	variable	c, b
	wave	wEinCB
	return	wEinCB[ c ][ b ]
End 

Function  		eVL( wE, wBFS, nChn, nBlk, nFrm, nSwp, nEle, nKey )
// returns value  from  wE[ nFrm ][ nSwp ][ nEle ][ nKey  ]
	wave	wE, wBFS	
	variable	nChn, nBlk, nFrm, nSwp, nEle, nKey 
	// variable	bfsPtr	= eGetBFSPtr( wBFS, nBlk, nFrm, nSwp )
	// printf "\t\teV(  \tc:%d   \tb:%d\tf:%d\ts:%d   \te:%d\tk:%d  \t)   \tretrieves \twE[ c:%d ]\t[ PTR:%d ]\t[ e:%d ]\t[ k:%d ] \twith %g \r",  nChn, nBlk, nFrm, nSwp, nEle, nKey,  nChn,  bfsPtr,  nEle, nKey, wE[ nChn ][   bfsPtr    ][ nEle ][ nKey  ] 
	return	wE[ nChn ][   wBFS[ nBlk ][ nFrm ][ nSwp ]   ][ nEle ][ nKey  ]
End 

Function  		eSet( wE, wBFS,  nChn, nBlk, nFrm, nSwp, nEle, nKey, value )
// sets value  wE[ nFrm ][ nSwp ][ nEle ][ nKey  ]
	wave	wE, wBFS
	variable	nChn, nBlk, nFrm, nSwp, nEle, nKey, value
	variable	bfsPtr	= eGetBFSPtr( wBFS, nBlk, nFrm, nSwp )
	wE[ nChn ][   bfsPtr    ][ nEle ][ nKey  ] = value
	// printf "\t\teSet( \tc:%d   \tb:%d\tf:%d\ts:%d   \te:%d\tk:%d  \tval:%g)  \t-> sets \twE[ c:%d ]\t[ PTR:%d ]\t[ e:%d ]\t[ k:%d ] \twith %g \r",  nChn, nBlk, nFrm, nSwp, nEle, nKey, value,   nChn,  bfsPtr,  nEle, nKey, wE[ nChn ][   bfsPtr   ][ nEle ][ nKey  ] 
	//  constant		HELP_IGOR_TO_ROUND	= 1e-6   // (used elsewhere..)	but try this on the command line : print .6 < 6/10;  print .6 == 6/10;  print .6 > 6/10
	// remove the following time consuming and still not exhaustive check in the release version....removed 030714
	// if ( abs(eVL( wE, wBFS, nChn, nBlk, nFrm, nSwp, nEle, nKey )) * .9999 >  abs(value)  || abs( value) > 1.0001 * abs(eVL( wE, wBFS, nChn, nBlk, nFrm, nSwp, nEle, nKey ) ) )
	//	string errBf; sprintf errBf, "Saving value [ c:%d   \tb:%d\tf:%d\ts:%d   \te:%d\tk:%d ] = %12.12g \tfailed,  retrieving %12.12g ... ",  nChn, nBlk, nFrm, nSwp, nEle, nKey, value, eVL( wE, wBFS, nChn, nBlk, nFrm, nSwp, nEle, nKey )
	//	InternalError( errBf )
	// endif
End 


Function  		eGetBFSPtr( wBFS, b, f, s )
// retrieve the one number (=pointer) corresponding to a particular block/frame/sweep combination
// wBFS is introduced for supplying in    wE    the 5. and 6	wave dimension missing in IGOR. As a side effect it saves memory...
// wBFS is introduced for supplying in  wDGO  the 5.		wave dimension missing in IGOR. As a side effect it saves memory...
	wave	wBFS
	variable	b, f, s
	return	wBFS[ b ][ f ][ s ]	//variable	bfsPtr = wBFS[ b ][ f ][ s ]; 	return bfsPtr
End

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	INTERFACE  FOR   wSwpTimeBlk...  to hide the  implementation completely
//	Display / Graph: which channel and which part of the data are displayed in which window
//	These sweep start and length points determine in the real time data acquisition which data are to be displayed and when they can be displayed ( by comparison to CED pointer)

constant	  SWPBEG = 0, 	SWPBEGSTORE = 1,  SWPLENSTORE = 2, SWPLEN = 3, SWPTIMEMAX = 4
strconstant  csSWEEPTIMES	= "Beg      ;BegStore;LenStore;Len      " 

static Function  stSwSetTimes( sFolder, wFix, nBlk, nFrm, nSwp, nType, value, nProts, nPnts )	// set true sweep begin point including 'Blanks'
//  031007 stores start and length of each sweep (in total points and in points to be stored (=without blanks) )   being protocol aware
	string  	sFolder
	wave	wFix
	variable	nBlk, nFrm, nSwp, nType, value, nProts, nPnts 
	variable	nProt

	string		wNm		= ksROOTUF_ + sFolder + ":ar:wSwpTimeBlk" + num2str( nBlk )
	wave  /Z	wSwpTimes = $wNm											// ignore wave reference checking failures

	if ( waveExists( wSwpTimes ) == 0 )
 		make /O /N = ( nProts, eFrames( wFix, nBlk ), eSweeps( wFix, nBlk ), SWPTIMEMAX ) $wNm	// the start of  each sweep in total stimulus
		wave  wSwpTimes = $wNm
	endif

	for ( nProt = 0; nProt < nProts; nProt += 1 )
		if ( nType <= SWPBEGSTORE )							//....could be simplified if ALWAYS nPROTS=1 is passed when nType is LEN   ...
				wSwpTimes[ nProt ][ nFrm ][ nSwp ][ nType ] = value + nProt * nPnts
		else
				wSwpTimes[ nProt ][ nFrm ][ nSwp ][ nType ] = value
		endif
		// printf  "\tswSetTimes( %s ) nProt:%d,  nBlk:%d, nFrm:%d, nSwp:%d, nType:%2d %2s\t= value:\t%8g\t->\t%8g\t=?=\t%8g\tnProts:%d  nPnts:%d   \r", wNm, nProt, nBlk, nFrm, nSwp, nType, StringFromList(nType, csSWEEPTIMES), value, value + nProt * nPnts, wSwpTimes[ nProt ][ nFrm ][ nSwp ][ nType ] , nProts, nPnts
	endfor
End

Function		swGetTimes( sFolder, nProt, nBlk, nFrm, nSwp, nType )
//    031007 retrieves previously stored start and length of each sweep (in total points and in points to be stored (=without blanks) )      being protocol aware
	string  	sFolder
	variable	nProt, nBlk, nFrm, nSwp, nType
	wave  	wSwpTimes = $ksROOTUF_ + sFolder + ":ar:wSwpTimeBlk" + num2str( nBlk )
	// printf  "swGetTimes ( nProt:%d,  nBlk:%d,  nFrm:%d,  nSwp:%d,  nType:%2d %2s\t=  %g \r",   nProt, nBlk, nFrm, nSwp, nType, StringFromList(nType, csSWEEPTIMES), wSwpTimes[ nProt ][ nFrm ][ nSwp ][ nType ]
	return	wSwpTimes[ nProt ][ nFrm ][ nSwp ][ nType ]
End


Function		ShowSwTimes( sFolder, wG, wFix )
// prints in a very raw fashion all data stored in 'wSwpTime'  : the start and length of each sweep  when  block, frame and sweep is given
	string  	sFolder
	wave	wG, wFix
	variable	bl, fr, sw, nType
	for ( bl = 0; bl < eBlocks( wG ); bl += 1 )
		for ( nType = 0; nType < SWPTIMEMAX; nType += 1 )
			for ( fr = 0; fr < eFrames( wFix, bl ); fr += 1 )
				printf  "\r\t\tShowSwTimes()  Folder:'%s'   nBlk:%d  \tnType:%d \tnFrm:%d \r\t\t\t", sFolder, bl, nType, fr
				for ( sw = 0; sw < eSweeps( wFix, bl ); sw += 1 )
					printf  "s:%2d\t%g \t",  sw, swGetTimes( sFolder, 0, bl, fr, sw, nType )	
				endfor
			endfor
		endfor
	printf "\r"
	endfor
End

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
static strconstant		cSTIMWNDNAME	= "Stimulus"

static constant		cAXISMARGIN		= .15			// space at the right plot area border for second, third...  Dac stimulus axis all of which can have different scales
static constant		cDGOWIDTH		= .04			// width of 1 Digout trace refered to whole window height
static constant		cDECIMATIONLIMIT = 20000		// 10000 to 50000 works well for IVK: 525000pts (135000 without blank), 15 frames, 5 sweeps
static constant		cMINIMUMSTEP	= 6			// as decimation has a considerable overhead  smaller steps make no sense


constant			cLINES = 0, cLINESandMARKERS = 4, cCITYSCAPE	= 6


// Reactivate the following 2 lines  if you want the display mode 'One frame, first sweep'
//static constant      	cAllFAllS = 0, cAllFOneS = 1,  cOneFAllS = 2, cOneFOneS = 3
//static strconstant	lstDISPSTIM_Title 	= " all frames, all sweeps; all frames, first sweep; one frame, all sweeps; one frame, first sweep "
static constant      	cAllFAllS = 0, cAllFOneS = 1,  cOneFAllS = 2, cOneFOneS = -1	//  -1 deactivates cOneFOneS right here so that there is no further change necessary in the code 
static strconstant	lstDISPSTIM_Title 	= " all frames; all sweeps, all frames; first sweep, one frame; all sweeps,"	// radio buttons need colon separators

// Reactivate the following 2 lines  if you want the display mode 'Stack frames and sweeps'
// static constant      	cCATFR_CATSW = 0, cSTACKFR_CATSW = 1 ,  cSTACKFR_STACKSW = 2
//static strconstant	lstCAT_STACK_Title 	= " catenate frames + swps; stack frames, cat swps; stack frames + sweeps"

static constant      	cCATFR_CATSW = 0, cSTACKFR_CATSW = 1 
static strconstant	lstCAT_STACK_Title 	= " catenate frames, stack frames"	// radio buttons need colon separators


 strconstant		ksPN_NAME_SDAO	= "sdao"			// Panel name   _and_  subfolder name  _and_  section keyword in INI file
static strconstant	ksPN_TITLE		= "Disp Stim Acqui"	// Panel title

Function		Dilg_DisplayOptionsStimulus_aco( xPos , yPos, nMode  )
	variable	xPos, yPos
	variable 	nMode
	string  	sFBase		= ksROOTUF_
//	string  	sFo			= ksfACO	
//	string  	sFSub		= sFo + ":"
	string  	sFSub		= ksfACO_
	string  	sWin		= ksPN_NAME_SDAO	 						
	string	sPnTitle		= ksPN_TITLE
	string	sDFSave		= GetDataFolder( 1 )							// The following functions do NOT restore the CDF so we remember the CDF in a string .
	PossiblyCreateFolder( sFBase + sFSub + sWin ) 
	SetDataFolder sDFSave												// Restore CDF from the string  value
	stInitPanelDisplayStimulus_aco( sFBase + sFSub, sWin )					// Fills both big text waves  'sPnOptions' (=wPn)  in 'root:uf:aco:'  and  in  'root:uf:evo:'  with all information about the controls necessary to build the panel
	Panel3Sub(   sWin,	sPnTitle, 	sFBase + sFSub,   xPos, yPos , nMode ) 	// Compute the location of panel controls and the panel dimensions. Draw the panel displaying and hiding needed/unneeded controls.  Prevents closing
	PnLstPansNbsAdd( ksfACO, sWin )
End

static Function		stInitPanelDisplayStimulus_aco( sF, sPnOptions )
// 	Same Function for  FPULSE  and  Eval .  The actions procs are also similar functions in  FPULSE  and  Eval , but the names differ... ( see  FPAcqScript.ipf  and  FPDispStim.ipf )
// 	Here are the samples united for  many  radio button  and  checkbox  varieties.....
	string  	sF, sPnOptions
	string  	sPanelWvNm	= sF + sPnOptions 
	variable	n = -1, nItems = 35
	make /O /T /N=(nItems) 	$sPanelWvNm
	wave  /T	tPn		= 	$sPanelWvNm
	//				Type	 NxL Pos MxPo OvS  Tabs Blks Mode Name		RowTi				ColTi	ActionProc			XBodySz	FormatEntry	Initval		Visibility	SubHelp
	n += 1;	tPn[ n ] =	"CB:	   1:	0:	2:	0:	°:	,:	1,°:	gbDisplay:	Display stimulus:		:		fDisplay_aco():		:		:			:			:		:	"		// 	
	n += 1;	tPn[ n ] =	"CB:	   1:	0:	2:	0:	°:	,:	1,°:	bAllBlocks:	All blocks:			:		fAllBlocks_aco():		:		:			:			:		:	"		// 	
	n += 1;	tPn[ n ] =	"SV:	   0:	1:	2:	0:	°:	,:	1,°:	gnDspBlock:	Block:				:		fDspBlock_aco():		40:		%2d; 0,99,1:	:			:		:	"		// 	
	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:	,:	,:	dum1b:		Range:				:		:					:		:			:			:		:	"		//	single separator needs ','  for 'Blks'  and 'dummy' for 'Name'
	n += 1;	tPn[ n ] =	"RAD: 1:	0:	1:	0:	°:	,:	1,°:	raRangeFS:	fRangeFSLst():		:		fRangeFS_aco():		:		:			0010_1;~0:	:		:	"		//	1-dim vert radios
	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:	,:	,:	dum1d:		Mode:				:		:					:		:			:			:		:	"		//	single separator needs ','  for 'Blks'  and 'dummy' for 'Name'
	n += 1;	tPn[ n ] =	"RAD: 1:	0:	1:	0:	°:	,:	1,°:	raCatStck:	fCatStckLst():			:		fCatStck_aco():		:		:			0000_1;~0:	:		:	"		//	1-dim vert radios
	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:	,:	,:	dum1f:		:					:		:					:		:			:			:		:	"		//	single separator needs ',' 
	n += 1;	tPn[ n ] =	"CB:	   1:	0:	1:	0:	°:	,:	1,°:	bShowBlank:	include blank periods:	:		fShowBlanks_aco():	:		:			:			:		:	"		// 	
	n += 1;	tPn[ n ] =	"CB:	   1:	0:	1:	0:	°:	,:	1,°:	gbSameYAx:	use same Y-axis for Dacs:	:	fSameYAx_aco():		:		:			:			:		:	"		// 	

	redimension   /N=(n+1)	tPn
End



//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function		fDisplay_aco( s )
	struct	WMCheckboxAction &s
	string  	sF		= ksfACO	
	string  	sWin		= ksPN_NAME_SDAO	
	 printf "\t\t\t%s\t%s\t%s\t-> val: %g\t  \r",  pd(s.CtrlName,31),	 pd(sF,9), pd(s.win,9),  s.checked
// 2009-12-18
//	if ( s.checked )
//		DisplayStimulus1( sF, sWin, kNOINIT )			
//	else
//		string  	sStimWndName	= StimWndNm( sF ) 
//		if ( WinType( sStimWndName ) == kGRAPH )				// only if a graph window with that name exists...
//			variable	xl, yt, xr, yb
//			IsMinimized( sStimWndName, xl, yt, xr, yb  )				// get the window coordinates
//			StoreWndLoc( sF + ":" + sWin,  xl, yt, xr, yb ) 
//// Igor5 syntax, Igor 6 has  SetWindow $sNB, hide = 0/1
//			MoveWindow 	/W=$sStimWndName   0 , 0 , 0 , 0		// hide window by minimizing it
//		endif
//	endif

// Igor6
	variable	bShow		= s.checked
	string  	sStimWndName	= StimWndNm( sF ) 
	if ( WinType( sStimWndName ) != kGRAPH )				// only if a graph window with that name exists...
		DisplayStimulus1( sF, sWin, kNOINIT )			
	else
		GetWindow $sStimWndName, hide 
		variable	bIsHidden	= V_Value
		if ( bShow  &&  bIsHidden )												// User wants to restore the hidden window 
			SetWindow $sStimWndName, hide = 0	
			DoWindow /F $sStimWndName
		elseif ( ! bShow  &&  ! bIsHidden )										// User wants to hide the visible window 
			SetWindow $sStimWndName, hide = 1
		endif
	endif
End

Function		fAllBlocks_aco( s )
// sample: action proc with auto_built generic name
	struct	WMCheckboxAction &s
	string  	sF		= ksfACO	
	string  	sWin		= ksPN_NAME_SDAO	
	// printf "\t\t%t%s\t%s\t%s\t-> val: %g\t  \r",   pd(s.CtrlName,31),	 pd(sF,9),  pd(s.win,9),  s.checked
	StoreRetrieveStimDispSettings( sF, ksPN_NAME_SDAO, s.checked )
	DisplayStimulus1( sF, sWin, kNOINIT )
	return	0
End

Function		fDspBlock_aco( s )	
//									// valid for  kbSUBFOLDER_IN_ACTIONPROC_NM_SV = 0 
//Function		std_gnDspBlock( s )									// valid for  kbSUBFOLDER_IN_ACTIONPROC_NM_SV = 1 
	struct	WMSetVariableAction   &s
	string  	sF		= ksfACO	
	string  	sWin		= ksPN_NAME_SDAO
	nvar		gnDspBlock = $ksROOTUF_ + sF + ":" + sWin + ":gnDspBlock0000"
	wave	wG	= $ksROOTUF_ + sF + ":keep:wG"
	gnDspBlock		 = min( gnDspBlock, eBlocks( wG ) - 1 )			// if the user attempted too high a value, correct the value shown in the dialog box 
	// print  "TODO........gnDspBlock( s )  " + ksROOTUF_ + sF + ":keep:wG"
	DisplayStimulus1( sF, sWin, kNOINIT )
	return	0
End

Function		fRangeFS_aco( s )
// Sample: if the proc field in a radio button in tPanel is empty then a proc with an auto-built name like this is called ( partial folder, underscore, variable base name)
// Advantage: Empty proc field in radio button in tPanel.  No explicit call to  'fRadio_struct( s )'  is necessary. 
	struct	WMCheckboxAction &s
 	string  	sF		= ksfACO	
	string  	sWin		= ksPN_NAME_SDAO	
	DisplayStimulus1( sF, sWin, kNOINIT )
End

Function		fCatStck_aco( s )
	struct	WMCheckboxAction &s
	string  	sF		= ksfACO	
	string  	sWin		= ksPN_NAME_SDAO	
	DisplayStimulus1( sF, sWin, kNOINIT )
End

Function		fShowBlanks_aco( s )					// SAMPLE : DO NOT DELETE
// sample: procedure with special name
	struct	WMCheckboxAction &s
	string  	sF		= ksfACO	
	string  	sWin		= ksPN_NAME_SDAO	
	// printf "\t\t\t%s\t%s\t%s\t-> val: %g\t  \r",   pd(s.CtrlName,31),	 pd(sF,9), pd(s.win,9),  s.checked
	fChkbox( s.ctrlName, s.checked )					// sets Help : needed here as this action proc name is NOT auto-derived from the control name
	DisplayStimulus1( sF, sWin, kNOINIT )
	return	0
End

Function		fSameYAx_aco( s )
// sample: action proc with auto_built generic name
	struct	WMCheckboxAction &s
	string  	sF		= ksfACO	
	string  	sWin		= ksPN_NAME_SDAO	
	// printf "\t\t\t%s\t%s\t%s\t-> val: %g\t  \r",  pd(s.CtrlName,31),	 pd(sF,9), pd(s.win,9),  s.checked
	DisplayStimulus1( sF , sWin, kNOINIT )
	return	0
End

//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function	/S	fRangeFSLst( sBaseNm, sFo, sWin )
// callled via 'fPopupListProc3()'
	string		sBaseNm, sFo, sWin
	return	lstDISPSTIM_Title
End

Function	/S	fCatStckLst( sBaseNm, sFo, sWin )
// callled via 'fPopupListProc3()'
	string		sBaseNm, sFo, sWin
	return	lstCAT_STACK_Title
End


//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function	/S	StimWndNm( sFolder )
	string  	sFolder
	return	cSTIMWNDNAME + "_" + sFolder
End


Function		StoreRetrieveStimDispSettings( sFolder, sWin, bValue )
// Called  when  'Display all blocks'  is switched on and off.  Store temporarily all panel settings which are OK in the  '1 block' mode but which make no sense in the 'all blocks' mode so that they can automatically be restored when the user switches back.
	string		sFolder
	string  	sWin			// 'sdeo'  or  'sdao'
	variable	bValue
	nvar		raRangeFS  	= $ksROOTUF_ + sFolder + ":" + sWin + ":raRangeFS00"				// The 'Range' setting  'All frames, all sweeps'  makes sense if the user wants to see all blocks so we automatically set it (although this is not required by the program)
	nvar		raCatStck	 	= $ksROOTUF_ + sFolder + ":" + sWin + ":raCatStck00"				// The 'Mode'   setting  'Cat frames + sweeps'  makes sense if the user wants to see all blocks so we automatically set it (although this is not required by the program)
	// Used like static, should be hidden within this function but must keep it's value between calls
	nvar	/Z 	 gPrevRangeFS = $ksROOTUF_ + sFolder + ":" + sWin + ":gPrevRangeFS00"			//  We also automatically set the 'Range' setting to 'All frames, all sweeps'  but we will restore the setting to the previous state if the user wants to see single blocks again
	nvar	/Z 	 gPrevCatStack	= $ksROOTUF_ + sFolder + ":" + sWin + ":gPrevCatStack00"			//  We also automatically set the 'Mode'  setting to 'catenate frames + sweeps'  but we will restore the setting to the previous state if the user wants to see single blocks again
	if ( ! nvar_Exists( gPrevRangeFS ) )			
		variable 	/G 		   $ksROOTUF_ + sFolder + ":" + sWin + ":gPrevRangeFS00" = raRangeFS// Used like static, should be hidden within this function but must keep it's value between calls
		variable	/G		   $ksROOTUF_ + sFolder + ":" + sWin + ":gPrevCatStack00" = raCatStck	// Used like static, ...
		//variable /G $ksROOTUF_ + sFolder + ":std:gPrevCatenation"	= gbCaten			// Used like static
		nvar	 gPrevRangeFS	 = $ksROOTUF_ + sFolder + ":" + sWin + ":gPrevRangeFS00"			//  We also automatically set the 'Range' setting to 'All frames, all sweeps'  but we will restore the setting to the previous state if the user wants to see single blocks again
		nvar	 gPrevCatStack	 = $ksROOTUF_ + sFolder + ":" + sWin + ":gPrevCatStack00"			//  We also automatically set the  'Mode'  setting to 'catenate frames + sweeps'  but we will restore the setting to the previous state if the user wants to see single blocks again
	endif
	if ( bValue )												// The user wants to see all blocks which requires catenation to be automatically turned on...
		gPrevRangeFS		= raRangeFS							// ...and we we store the current 'Range' setting and then turn the 'Range' setting  'All frames, all sweeps'  temporarily on as this setting makes sense...
		raRangeFS		= cAllFAllS								// ...but we do NOT prevent the user from changing this setting so we do NOT disable it
		gPrevCatStack		= raCatStck							// ...and we we store the current 'Mode' setting and then turn the 'Mode' setting  'catenate frames + sweeps'  temporarily on as this setting makes sense...
		raCatStck			= cCATFR_CATSW						// ...but we do NOT prevent the user from changing this setting so we do NOT disable it
		// gPrevCatenation	= gbCaten								// ...so we store the current catenation setting..
		// gbCaten		= TRUE								// ...we turn catenation (temporarily!) on...
		// EnableCheckbox( "MyPanel", "root_uf_"+sFolder+"_" + sWin + "_gbCaten", kDISABLE)	// ...and we grey the checkbox so that the user cannot turn it off
	else														// The user wants to see single blocks  again...
		raRangeFS		= gPrevRangeFS						// ...so we restore the 'Range' setting to its previous state
		raCatStck			= gPrevCatStack						// ...so we restore the 'Mode' setting to its previous state
		// gbCaten		= gPrevCatenation						// ...so we restore the 'Catenation' setting to its previous state
		// EnableCheckbox( "MyPanel", "root_uf_"+sFolder+"_" + sWin + "_gbCaten", bValue )	// ...and we make the checkbox work again
	endif

	//EnableSetVar( "PnDispStim" + sFolder , "gnDspBlock" , ! bValue )		// Either display a working control or hide it completely. We cannot use the NOEDIT mode as this only disables up/down but still allows an entry in the input field.
	EnableSetVar( sWin , "root_uf_" + sFolder + "_" + sWin + "_gnDspBlock0000" , ! bValue )		// Either display a working control or hide it completely. We cannot use the NOEDIT mode as this only disables up/down but still allows an entry in the input field.

	// Update the radio buttons ( this is unfortunately NOT done automatically )	
	string		sRadButtonsCommonBase	= "root_uf_" + sFolder + "_" + sWin + "_raRangeFS00"
	RadioCheckUncheck3new( sWin, sRadButtonsCommonBase, raRangeFS )
			sRadButtonsCommonBase	= "root_uf_" + sFolder + "_" + sWin + "_raCatStck00"
	RadioCheckUncheck3new( sWin, sRadButtonsCommonBase, raCatStck )
End


Function		DisplayStimulus1( sFolder, sWin, bDoInit )
	string  	sFolder, sWin
	variable	bDoInit
	wave  	wG		= $ksROOTUF_ + sFolder + ":keep:wG"  					// This  'wG'  	is valid in FPulse ( Acquisition )
	wave  /T	wIO		= $ksROOTUF_ + sFolder + ":ar:wIO"  					// This  'wIO'  	is valid in FPulse ( Acquisition )
	wave  	wFix		= $ksROOTUF_ + sFolder + ":ar:wFix" 					// This  'wFix'	is valid in FPulse ( Acquisition )
// Execute "SetIgorOption DebugTimer,Start=100000"	// the default size of 10000 is not enough to measure all nested loops
//	//ResetStartTimer( "DispStim" )	
	DisplayStimulus( sFolder, sWin, wG, wIO, wFix, bDoInit )
//	StopTimer( "DispStim" )	
// Execute "SetIgorOption DebugTimer,Stop"	// to see the results call from the command line  ' ProcessTest("test1...","Notebook1...") '
//	PrintSelectedTimers( "DispStim" )		
End

Function		DisplayStimulus( sFolder, sWin, wG, wIO, wFix, bDoInit )
// Step 10:  break  the complete  wStimulus (and Digout) wave  into  its sweeps and frames and display all of them in one graph
// sweeps can have different lengths, for that it  NEEDS  swpSetTime/swpGetTime

// Flaws and problems:
// 1. Letting IGOR draw ALL points (without any decimation) can be very slow:  appr. 5s / 10MPts   x   number of dacs, digout, Save/NoSave  can amount to 1 minute.
// 2. Decimation can improve this but must be used with care: Short spikes are prolonged on screen, considerable computing overhead, complicated code...
// 3. Drawing decimated traces in Cityscape mode is appropriate for Digout, but for Dac stimulus  only for segments, NOT for ramps, stimwave, expo where  'lines' mode would be better.
// 4. Drawing in Cityscape mode slows drawing down by a factor of 3. This is not so important when decimation is used but very annoying without (when drawing many points)  

// 9.	First DISPLAYED dac wave (even if it is the 2. in script because 1. is turned off) is always colored magenta (=default Dac color) to make time course of frames visible...(maybe annoying to user...)

// Todo: checkbox to allow the user to alternatively select a 'true-but-slow' drawing mode: no decimation = step is always 1 = pulses/spikes have and keep their correct duration even when zooming 
	string  	sFolder, sWin					// 'sdeo'  or  'sdao'
	wave  /T	wIO
	wave	wG, wFix
	variable	bDoInit
	variable	nSmpInt			= wG[ kSI ]
	variable	nCntDA			= wG[ kCNTDA ]

	nvar		gbDisplay			= $ksROOTUF_ + sFolder + ":" + sWin + ":gbDisplay0000"
	nvar		gbAllBlocks		= $ksROOTUF_ + sFolder + ":" + sWin + ":bAllBlocks0000"
	nvar		gnDspBlock		= $ksROOTUF_ + sFolder + ":" + sWin + ":gnDspBlock0000"		// the block which is to be displayed
	nvar		raRangeFS		= $ksROOTUF_ + sFolder + ":" + sWin + ":raRangeFS00"			// the radio button lin index variable is autobuilt by truncating the last 2 digits
	nvar		raCatStck			= $ksROOTUF_ + sFolder + ":" + sWin + ":raCatStck00"			// the radio button lin index variable is autobuilt by truncating the last 2 digits
	nvar		gbShowBlank		= $ksROOTUF_ + sFolder + ":" + sWin + ":bShowBlank0000"
	nvar		gbSameYAx		= $ksROOTUF_ + sFolder + ":" + sWin + ":gbSameYAx0000"
	svar		gsDigOutChans		= $ksROOTUF_ + sFolder + ":dig:gsDigOutChans"

	// printf "\tDisplayStimulus1()   bDoInit:%d    eBlocks( wG ) - 1: %d  -> nDspBlock: %d \r", bDoInit, eBlocks( wG ) - 1,  gnDspBlock
	if ( bDoInit )											// a new script has just been read so we must adjust the number of the displayed blocks to the number of available blocks
		gnDspBlock	= min( gnDspBlock, eBlocks( wG ) - 1 )		//  or = 0 
	endif

	if ( gbDisplay )

		variable	nIO			= kIO_DAC	
		variable	nRightAxisCnt, RightAxisPos, LastDataPos, ThisAxisPos, LowestTickToPlot
	
		variable	pr, c = 0, b, f, s,  nFrm, nSwp,  pt
		variable	nSwpPts = 0, nStartPos = 0
		variable	nBlkBeg, nBlkEnd			
		variable	nStoreStart, nStoreEnd
//		string		sDgoChans	= gsDigOutChans
		variable	nDgoChs		= ItemsInList( gsDigOutChans )
		variable	cd, nDgoCh, nHighestDgoCh = 0
		string		bf
		string		sWNm		= StimWndNm( sFolder )
		string		sDONm
		string		sDacNm										// Name with true channel number (without folder)  e.g. 'Dac0' , 'Dac2'
	
		// Check that at least 1 Dac channel is turned on (else AppendToGraph below will fail)
		if ( nCntDA == 0 )
			return	kERROR									// avoid failing of  AppendToGraph when all channels are off
		endif
		wave	wStimulus	=  $FldAcqioio( sFolder, wIO, nIO, c, cIONM )	// determine stimulus point number from 1. Dac (all Dacs have same number of points)	
		variable	nDacPts	= numpnts( wStimulus )
	
		if ( gbAllBlocks )
			nBlkBeg	= 0
			nBlkEnd	= eBlocks( wG ) 
		else
			nBlkBeg	= gnDspBlock								// use the block  set in the dialog box
			nBlkEnd	= gnDspBlock + 1 
		endif
	 	pr			= 0										// NOT  REALLY  PROTOCOL  AWARE
	
		// Possibly construct the stimulus window
		variable	xl, yt, xr, yb
		if (  WinType( sWNm ) != kGRAPH )											// Only if the Stimulus graph window does not  exist (this is normal at startup).. 
			// printf "++Internal error: Graph '%s'  should  but does not exist. (DisplayStimulus)\r", sWNm	// the user may have brutally killed it by having pressed 'Close' multiple times in fast succession 
			GetDefaultScriptOrStimWndLoc( sFolder, kSTIM, xl, yt, xr, yb ) 					// 	use defaults  (parameters changed by function)
			StoreWndLoc( sFolder + ":" + sWin, xl, yt, xr, yb )								// ...save the default window coordinates
			display /K=2 /W=( xl, yt, xr, yb )
			DoWindow  /C $sWNm 												// ...build an empty window and give it a meaningful name 
		else
			if (  IsMinimized( sWNm, xl, yt, xr, yb ) )										// User wants to restore the minimized window ( x..y are dummies)
				RetrieveWndLoc( sFolder + ":" + sWin , xl, yt, xr, yb )							// parameters changed by function
				MoveWindow 	/W=$sWNm   xl, yt, xr, yb
			endif
			RemoveAllTextBoxes( sWNm )
			EraseTracesInGraph( sWNm )											// ..and clear the contents 
		endif

		MarkPerfTestTime 800	// InterpretScript: DisplayStimulus Step2 start

		// Step 1a: Compute nSumDrawPts : the total  number of displayed data points  and the  step   ignoring blank periods if the display of blanks is turned off.
		variable	nSumDrawPts	= 0
		for ( b = nBlkBeg; b < nBlkEnd; b += 1 )
			nFrm			= ( raRangeFS == cOneFAllS  ||  raRangeFS == cOneFOneS ) ?  1 :  eFrames( wFix, b )
			nSwp		= ( raRangeFS == cAllFOneS  ||  raRangeFS == cOneFOneS ) ?  1 : eSweeps( wFix, b )
			for ( f = 0; f < nFrm; f += 1 )									// loop through all frames  
				for ( s = 0; s < nSwp; s += 1)							// loop through all sweeps 
					nSwpPts	= gbShowBlank ?  SweepLenAll( sFolder, pr, b, f, s ) : SweepLenSave( sFolder, pr, b, f, s )	// NOT  REALLY  PROTOCOL  AWARE
					nSumDrawPts	+= nSwpPts
				endfor
			endfor
		endfor
		variable	step 		= round( max( 1,  nSumDrawPts	/ cDECIMATIONLIMIT ) )		// decimation begins when wave points exceed this limit

		// Step 1b: Compute nSumSwpPts1 : the number of displayed data points  in 1 trace    ignoring blank periods if the display of blanks is turned off.
		variable	nSumSwpPts1	= 0
		for ( b = nBlkBeg; b < nBlkEnd; b += 1 )
			nFrm			= ( raRangeFS == cOneFAllS  ||  raRangeFS == cOneFOneS ) ?  1 :  eFrames( wFix, b )
			nSwp		= ( raRangeFS == cAllFOneS  ||  raRangeFS == cOneFOneS ) ?  1 : eSweeps( wFix, b )
			if ( raCatStck  !=  cCATFR_CATSW )
				nFrm  = 1								// adjust loop limits so that only ONE partial wave for all catenated frames or sweeps...
				// Reactivate the following 3 lines if you want the display mode 'Stack frames and sweeps'
				// if ( raCatStck == cSTACKFR_STACKSW )
				//	nSwp  = 1							// ..or  many smaller  waves (to be displayed superimposed) are built
				// endif
			endif

			for ( f = 0; f < nFrm; f += 1 )									// loop through all frames  
				for ( s = 0; s < nSwp; s += 1)							// loop through all sweeps 
					nSwpPts	= gbShowBlank ?  SweepLenAll( sFolder, pr, b, f, s ) : SweepLenSave( sFolder, pr, b, f, s )	// NOT  REALLY  PROTOCOL  AWARE
					nSumSwpPts1	+= nSwpPts
				endfor
			endfor
		endfor

		// printf "\t\tDisplayStimulus(1)  Pts (no blanks)  CatStack: %d   nDacPts: %d   nSumPts:\t%7d\tnSwpPts(last):\t%7d\t  step:%4d  \tFr:%3d\tSw:%3d\tnDrawPts:\t%7d   \r",  raCatStck, nDacPts, nSumSwpPts1, nSwpPts, step, nFrm, nSwp, nSumDrawPts

		// Supply the Save/NoSave wave
		//make  /O  /N = ( nDacPts )  	$ksROOTUF_ + sFolder + ":stim:" + stDispWave( "SV" )  =  Nan // wSvWv cannot be an integer wave as an integer wave does not have Nan needed to blank out points	
		make /O /N=( nDacPts / step ) 	$ksROOTUF_ + sFolder + ":stim:" + stDispWave( "SV" ) =  Nan // wSvWv cannot be an integer wave as an integer wave does not have Nan needed to blank out points	

		// Step 2: Set points which are not to be  displayed to Nan in  Save/NoSave    and   store minima and maxima
		make	/O /N=( MAXDACS, 2 )	$ksROOTUF_ + sFolder + ":stim:wDMinMax"
		wave	wDMinMax		= 	$ksROOTUF_ + sFolder + ":stim:wDMinMax"						
		for ( b = nBlkBeg; b < nBlkEnd; b += 1 )
			nFrm	  = ( raRangeFS == cOneFAllS  ||  raRangeFS == cOneFOneS ) ?  1 :  eFrames( wFix, b )
			nSwp = ( raRangeFS == cAllFOneS  ||  raRangeFS == cOneFOneS ) ?  1 : eSweeps( wFix, b )

			wave wSVWv	= $ksROOTUF_ + sFolder + ":stim:" + stDispWave( "SV" )		
			// printf "\t\tDispStimulus...'%s'    exists:%d  \r", ksROOTUF_ + sFolder + ":stim:" + DispWave( "SV" ), waveexists( 	wSVWv )	
			SetScale /P X, 0, nSmpInt / kXSCALE * step, ksXUNIT, wSvWv 					// expand in x by number AND prevent IGOR from scaling  11,12... kms  (..8000,9000 ms is OK )

			for ( f = 0; f < nFrm; f += 1 )											
				for ( s = 0; s < nSwp; s += 1)						
					nStoreStart	= SweepBegSave( sFolder, pr, b, f, s )
					nStoreEnd		= SweepBegSave( sFolder, pr, b, f, s ) + SweepLenSave( sFolder, pr, b, f, s ) 
//					wSVWv[ nStoreStart, nStoreEnd - 1 ] 	= 0  									// the SAVE / NOSAVE periods : mark as 'Save'  (default is nosave = Nan)
					wSVWv[ nStoreStart/step, nStoreEnd/step - 1 ] 	= 0  							// the SAVE / NOSAVE periods : mark as 'Save'  (default is nosave = Nan)
				endfor
			endfor
		MarkPerfTestTime 824	// InterpretScript: DisplayStimulus Step2 fill SV
		endfor


		for ( cd = 0; cd < nDgoChs; cd += 1 )	
			if ( step > 1 )
				sDONm		=  stDispWaveDgo( gsDigOutChans, cd )  
				make /O /B /N	= ( nDacPts / step ) 	$ksROOTUF_ + sFolder + ":stim:" + sDONm  				// BYTE wave
				wave  wDOWv	=  				$ksROOTUF_ + sFolder + ":stim:" + sDONm 				// ..for the display of the digital output
				SetScale /P X, 0, nSmpInt / kXSCALE * step , ksXUNIT, wDOWv				// expand in x by number AND prevent IGOR from scaling  11,12... kms  (..8000,9000 ms is OK )
			else
				SetScale /P X, 0, nSmpInt / kXSCALE * step , ksXUNIT, $ksROOTUF_ + sFolder + ":stim:" + DispWaveDgoFull( gsDigOutChans, cd )	//???!!!			// expand in x by number AND prevent IGOR from scaling  11,12... kms  (..8000,9000 ms is OK )
			endif
	MarkPerfTestTime 825	// InterpretScript: DisplayStimulus Step2 decimate DO
		endfor

		for ( c = 0; c < nCntDA; c += 1)		
			wave	wStimulus	=   $ FldAcqioio( sFolder, wIO, nIO,c, cIONM )
			waveStats  /Q 	wStimulus	
			// compute and store the minima and maxima for each channel so that identical scales can be drawn below 
			wDMinMax[ c ][ 0 ]	= min( wDMinMax[ c ][ 0 ],  V_min )   		
			wDMinMax[ c ][ 1 ]	= max( wDMinMax[ c ][ 1 ], V_max )   		
			// printf "\t\t\tDisplayStimulus(2a) \t(b:%2d/%2d\tf:%2d/%2d\ts:%2d/%2d) \tfrom\t%7d\tto\t%7d\t(pts:%6d )", b, nBlkEnd - nBlkBeg,  f, nFrm, s, nSwp,  nStartPos, nStartPos+nSwpPts, nSwpPts
			// 		printf "\tShwB:%d \tBg:\t%7d\t... (Stor:\t%7d\t...%7d) \t.En:\t%7d\tc:%d\tmi:\t%7.1lf\tmx:\t%7.1lf \r", gbShowBlank,   SweepBegAll( pr, b, f, s ), nStoreStart, nStoreEnd, SweepBegAll( pr, b, f, s )+SweepLenAll( pr, b, f, s ), c, wDMinMax[ c ][ 0 ], wDMinMax[ c ][ 1 ]
			if ( step > 1 )
				sDacNm			=   ios( wIO, nIO,c, cIONM ) 
				make /O /N=( nDacPts / step ) 	$ksROOTUF_ + sFolder + ":stim:" + sDacNm	 // wSvWv cannot be an integer wave as an integer wave does not have Nan needed to blank out points	
				wave	wStimulus		=   	$ksROOTUF_ + sFolder + ":stim:" + sDacNm 
			endif

			SetScale /P X, 0, nSmpInt / kXSCALE * step, ksXUNIT, wStimulus	//???!!!			// expand in x by number

	MarkPerfTestTime 826	// InterpretScript: DisplayStimulus Step2 decimate DA
		endfor

	
		// Step 3: Convert computed minima and maxima to a  string list  sorted by units  (multiple channels having the same units are merged to 1 minimum and maximum)
		string  /G					$ksROOTUF_ + sFolder + ":" + ksF_IO + ":sUnitsDacMin"	= ""
		string  /G					$ksROOTUF_ + sFolder + ":" + ksF_IO + ":sUnitsDacMax"	= ""
		svar	   	sUnitsDacMin	= 	$ksROOTUF_ + sFolder + ":" + ksF_IO + ":sUnitsDacMin"
		svar	   	sUnitsDacMax	=	$ksROOTUF_ + sFolder + ":" + ksF_IO + ":sUnitsDacMax"
		for ( c = 0; c < nCntDA; c += 1)		
			// printf "\t\t\t\tDisplayStimulus(3)   c:%d   \t%s\tmin:%g   \tmax%g \r", c, ios( wIO, nIO, c , cIOUNIT ), wDMinMax[ c ][ 0 ],  wDMinMax[ c ][ 1 ] 
			stSetDacMinMaxForSameUnits( sFolder, ios( wIO, nIO, c , cIOUNIT ), wDMinMax[ c ][ 0 ],  wDMinMax[ c ][ 1 ] )
		endfor

		for ( cd = 0; cd < nDgoChs; cd += 1 )	
			nDgoCh		= str2num( StringFromList( cd, gsDigOutChans ) )				// the true digout channel number
			nHighestDgoCh	= max( nDgoCh, nHighestDgoCh )						// is usually channel 4 ( Adc/Dac event)
		endfor
		MarkPerfTestTime 830	// InterpretScript: DisplayStimulus Step3 SetDacMinMax
				
		// Step 5: Display the  Save/NoSave ,  stimulus  and Digout  waves
		variable	rMin, rMax, nSeg, nSumSwpPts
		nSumSwpPts	= 0
		nSeg 		= -1
		for ( b = nBlkBeg; b < nBlkEnd; b += 1 )
			nFrm			= ( raRangeFS == cOneFAllS  ||  raRangeFS == cOneFOneS ) ?  1 :  eFrames( wFix, b )
			nSwp		= ( raRangeFS == cAllFOneS  ||  raRangeFS == cOneFOneS ) ?  1 : eSweeps( wFix, b )
	
			for ( f = 0; f < nFrm; f += 1 )										// loop through all frames   (only ONE for catenated wave mode)

				for ( s = 0; s < nSwp; s += 1)								// loop through all sweeps (only ONE for catenated wave mode)

					string		sSVNm, sSeg, sAxisNm
					variable	xos
					nSeg 	+= 1
					sSeg		=  SelectString( nSeg, "", "#" + num2str( nSeg ) )		// Igors appends #1, #2... to traces to discriminate them if multiple segments or instances of the same base trace are appended
					nSwpPts	= gbShowBlank ?  SweepLenAll( sFolder, pr, b, f, s ) : SweepLenSave( sFolder, pr, b, f, s )	// NOT  REALLY  PROTOCOL  AWARE
					nStartPos	= gbShowBlank ?  SweepBegAll( sFolder, pr, b, f, s ) : SweepBegSave( sFolder, pr, b, f, s )

					xos	=  ( trunc( nSumSwpPts / step ) - trunc( nStartPos / step ) ) * step * nSmpInt / kXSCALE	// ! nSumSwpPts shifts the starting positions of all segments to x=0 in the stacked (=non-catenated) mode

					// Display the  DigOut  segments 
					for ( cd = 0; cd < nDgoChs; cd += 1 )	
						nDgoCh		= str2num( StringFromList( cd, gsDigOutChans ) )			// the true channel number
						sDONm		=  DispWaveDgoFull( gsDigOutChans, cd ) 				// the full wave ( all points )
						if ( step > 1 )
							wave  wDOFull	=  $ksROOTUF_ + sFolder + ":stim:" + sDONm			// the name of the full wave ( all points )
							sDONm		=  stDispWaveDgo( gsDigOutChans, cd )  				// the name of the decimated wave 
							MyDecimate1( wDOFull,  ksROOTUF_ + sFolder + ":stim:" + sDONm , step, 2, TRUE, nStartPos, nStartPos + nSwpPts )
						endif

// 041111					sDONm		+=  sSeg
//						wave  wDOWv	=  $ksROOTUF_ + sFolder + ":stim:" + sDONm 					// ..for the display of the digital output
						wave  wDOWv	=  $ksROOTUF_ + sFolder + ":stim:" + sDONm 					// ..for the display of the digital output
						sDONm		+=  sSeg

						AppendToGraph /W=$sWNm /R= AxisDgo	  wDOWv[ nStartPos/step, (nStartPos + nSwpPts) /step ]	
						ModifyGraph	 /W=$sWNm 	offset( $sDONm ) = {  xos,  1 + nDgoCh*1.5  }	// stack the digout channels one above the other
						ModifyGraph	 /W=$sWNm 	rgb( $sDONm ) 	  = ( cd*15000, 50000-cd*15000, 0 ) 
						ModifyGraph	 /W=$sWNm	mode = cCITYSCAPE						// cityscape increases drawing time appr. 3 times ! 
						// printf "\t\tDisplayStimulus(5c)   ShowAllBlocks:%d\tc:%d  b:%d  f:%d  s:%d  -> %s  has %7d pts \r",  gbAllBlocks, c, b, f, s, sDONm , numPnts( wDOWv )
						// When displaying  the first   Digout    segment  then adjust the Y axis
						if (  b == nBlkBeg  &&  f == 0  &&  s == 0 )	// adjust during the LAST cd ( after nHighestDgoCh has been set )									
							SetAxis 		/W=$sWNm 	AxisDgo 0, 1+ nHighestDgoCh * 2	// Axis range  = 0 .. DigOut channels
							ModifyGraph	/W=$sWNm 	axisEnab( AxisDgo ) 	= {  1 - (nHighestDgoCh) * cDGOWIDTH, 1 }	//  Dgo traces are diplayed at the top
							ModifyGraph	/W=$sWNm 	axThick( AxisDgo ) = 0,  noLabel( AxisDgo ) =  2, tick( AxisDgo ) = 3 	// hide axis : suppress axis, ticks and labels 
							//ModifyGraph	/W=$sWNm 	freepos( AxisDgo )	= 100							// shift axis so many points outside the plot area : hide it
						endif	
					endfor

					// Display the Save/NoSave  segments , use hidden Dgo axis
					sSVNm 		=  stDispWave( "SV" ) + sSeg
					wave  wSVWv	= $ksROOTUF_ + sFolder + ":stim:" + stDispWave( "SV" ) 		
					AppendToGraph /W=$sWNm /R = AxisDgo   	wSvWv[ nStartPos/step, (nStartPos + nSwpPts)/step]	// first display  a short  Save/NoSave segment...
					ModifyGraph	 /W=$sWNm 	offset( $sSVNm ) = { xos, 0 }
					// When displaying  the first  Save/NoSave  segment  then adjust the Y axis
					if (  b == nBlkBeg  &&  f == 0  &&  s == 0 )									
						SetAxis 		/W=$sWNm  	bottom 0, nSumSwpPts1 * nSmpInt / kXSCALE			// ...then stretch the X axis to the finally needed range
						ModifyGraph	/W=$sWNm 	rgb( $sSVNm ) 	 = ( 50000, 0, 20000 ) 
					endif

					// Display the  stimulus  data  segments 
					for ( c = 0; c < nCntDA; c += 1)		
						variable	rnRed, rnGreen, rnBlue 
						string    	sRGB	= ios( wIO, nIO, c , cIORGB )
						ExtractColors( sRGB, rnRed, rnGreen, rnBlue )
						nRightAxisCnt	= max( 0, nCntDA - 2 )					// additional space is not needed for first and second Y axis

						sDacNm			= ios( wIO, nIO, c, cIONM ) 
						if (  step > 1 )
							wave   	wStimulusFull	= $FldAcqioio( sFolder, wIO, nIO, c, cIONM ) 
							wave	wStimulus		= $ksROOTUF_ + sFolder + ":stim:" + sDacNm 
							MyDecimate1( wStimulusFull,  ksROOTUF_ + sFolder + ":stim:" + sDacNm, step, 2, TRUE, nStartPos, nStartPos + nSwpPts )
							//MyDecimate1( wStimulusFull,  ksROOTUF_ + sFolder + ":stim:" + sDacNm, step, 2, FALSE, nStartPos, nStartPos + nSwpPts )
						else
							wave	wStimulus		= $FldAcqioio( sFolder, wIO, nIO, c, cIONM ) 
						endif
						sDacNm 			+=  sSeg
		
						if (  c == 0 )
							sAxisNm	= "left"
							AppendToGraph /W=$sWNm		wStimulus[ nStartPos/step, (nStartPos + nSwpPts)/step -1 ]
							// Stimulus color coding 1: Big pulse sweeps: from red to green, correction pulses same + blue: from magenta to cyan
							// AppendToGraph /C=( kCOLMX * ( 1- f / nFrm ), kCOLMX * f / nFrm, kCOLMX * s / nSwp ) wDAWv
							// Stimulus color coding 2: Big pulse sweeps: from Blue to Magenta, correction pulses are all Cyan
							//AppendToGraph /C=( (s==0)*kCOLMX * f / nFrm , (s>0)*kCOLMX * .7 , (s==0)*kCOLMX * ( 1 - f / ( nFrm +1) ) +(s>0)*(kCOLMX*.8)) wDAWv	
							// Stimulus color coding 3: Big pulse sweeps: from Magenta to Blue, correction pulses are all Cyan   (Magenta is Dac default color)
							variable	nRed =  (s==0)*45000 * ( 1 - f / nFrm ), nGreen = (s>0)*kCOLMX * .7 , nBlue = (s==0)*45000 *  f / nFrm +(s>0)*(kCOLMX*.8)
							// printf "\t\tDisplayStimulus(5c1)  c:%d  step:\t%7d\tnStartPos:\t%7d\tnSwpPts:\t%7d\t->nStartPos:\t%7.1lf\t  nEndPos:\t%7.1lf\txos:\t%7.2lf\tf:%d\ts:%d\tRGB:%7d\t%7d\t%7d\t%s %s \r", c, step,  nStartPos,nSwpPts, nStartPos/step,  (nStartPos + nSwpPts) / step, xos, f, s, nRed, nGreen, nBlue, sWNm, sDacNm
							ModifyGraph	 /W=$sWNm	rgb(  $sDacNm )	= ( (s==0)*45000 * ( 1 - f / nFrm ), (s>0)*kCOLMX * .7 , (s==0)*45000 *  f / nFrm +(s>0)*(kCOLMX*.8) ) 
						else
							sAxisNm	= "right" + num2str( c )
							AppendToGraph  /W=$sWNm 	/R= $sAxisNm  	wStimulus[ nStartPos/step, (nStartPos + nSwpPts)/step ]
							// printf "\t\tDisplayStimulus(5c2)  c:%d  step:\t%7d\tnStartPos:\t%7d\tnSwpPts:\t%7d\t->nStartPos:\t%7.1lf\t  nEndPos:\t%7.1lf\txos:\t%7.2lf\tf:%d\ts:%d\tRGB:%7d\t%7d\t%7d\t%s %s \r", c, step,  nStartPos,nSwpPts, nStartPos/step,  (nStartPos + nSwpPts) / step, xos, f, s, rnRed, rnGreen, rnBlue, sWNm, sDacNm
							ModifyGraph	  /W=$sWNm	rgb(  $sDacNm )	= (  rnRed, rnGreen, rnBlue ) 
						endif
						// printf "\t\tDisplayStimulus(5d)   c:%d  step:\t%7d\tnStartPos:\t%7d\tnSwpPts:\t%7d\t->nStartPos:\t%7.1lf\t  nEndPos:\t%7.1lf\txos:\t%7.2lf  \r", c, step,  nStartPos,nSwpPts, nStartPos/step,  (nStartPos + nSwpPts) / step, xos
						ModifyGraph	/W=$sWNm	mode = cCITYSCAPE						// cityscape increases drawing time appr. 3 times ! 
						//ModifyGraph	/W=$sWNm	mode = cLINESandMARKERS			// cityscape increases drawing time appr. 3 times ! 
						ModifyGraph	/W=$sWNm	offset( $sDacNm )	= { xos, 0 }
						ModifyGraph	/W=$sWNm	alblRGB( $sAxisNm )	= ( rnRed, rnGreen, rnBlue )				// use same color for axis label as for trace
					
						if (  b == nBlkBeg  &&  f == 0  &&  s == 0 )									
							// When displaying  the first  stimulus  data  segment  then adjust the Y axis
							ModifyGraph	/W=$sWNm	axisEnab( $sAxisNm ) = { 0, 1 - (nHighestDgoCh+1)*cDGOWIDTH }	//  the Dac traces are plotted in the lower part of the window
							//ModifyGraph	/W=$sWNm 	rgb( $sDacNm)= ( 45000,0,45000),	alblRGB( left ) = (45000,0,45000)	// Stimulus color coding 3: start with trace and axis label set to magenta	
							//ModifyGraph	/W=$sWNm	margin( left ) = 40							//? without this the axes are moved too much to the right by TextBox or SetScale y 
							if (  c == 0 )
								GetAxis		/W=$sWNm /Q	bottom
								LastDataPos	= v_Max  * ( 1 + .05 )    -   v_Min  * .05							// .05 shifts axis to the right so that Y axis label of right axis is not within plot area
								RightAxisPos	= v_Max  * ( 1 + .05 +  nRightAxisCnt * cAXISMARGIN )  - v_Min * ( .05 + nRightAxisCnt * cAXISMARGIN ) // .05 shifts axis...
								// printf "\t\tDisplayStimulus(5e)   c:%d  GetAxis( bottom) \tv_min:%g , v_Max:%g -> LastDataPos:%g  RightAxisPos:%g \r", c, v_Min, LastDataPos, v_Max, RightAxisPos
								SetAxis		/W=$sWNm 	bottom, v_Min, RightAxisPos						// make bottom axis longer if there are Y axis on the right (=multiple Dacs) to be drawn
							endif
							ModifyGraph	/W=$sWNm 	axisEnab( bottom ) 	= { 0, .96 }					//  1 -> .96 supplies a small margin to the right of the rightmost axis   
							ModifyGraph	/W=$sWNm 	tickEnab( bottom )	= { v_Min, v_Max }				// suppress bottom axis ticks on the right where multiple Y axis are to be positioned
						endif

						if (  c > 0 )
							if ( gbSameYAx )
								stGetDacMinMaxForSameUnits( sFolder, ios( wIO, nIO, c , cIOUNIT ), rMin, rMax )
							else
								rMin	= wDMinMax[ c ][ 0 ]											// each trace has its own y axis end points
								rMax	= wDMinMax[ c ][ 1 ]
							endif
							SetAxis	/W=$sWNm  $sAxisNm,	rMin, rMax
							ThisAxisPos	= nCntDA == 2 ? LastDataPos : LastDataPos + ( c - 1) / ( nCntDA-2) * (RightAxisPos - LastDataPos)	// here goes the new Y axis
							// printf "\t\tDisplayStimulus(5f)   c:%d   bottom axis   \t\tv_min:%g , v_Max:%g -> LastDataPos:%g ThisAxisPos:%g  RightAxisPos:%g \r", c, v_Min, v_Max, LastDataPos, ThisAxisPos, RightAxisPos
							ModifyGraph	/W=$sWNm	freePos( $sAxisNm ) = { ThisAxisPos, bottom }
							// GetAxis	/W=$"MultiChannel"	$sAxisNm;  print "GetAxis error", V_flag, sAxisNm, v_Min, v_max  //? IGOR bug: axis should be but is not known to IGOR???????
							if ( c > 0  &&  c < nCntDA - 1 ) 
								LowestTickToPlot	= rMin  + .1 * ( rMax - rMin )							// 10% above the lower y axis end point: do not plot ticks below
								// print "DisplayStimulus( )", c, rMin, rMax, "->", LowestTickToPlot
								ModifyGraph  /W=$sWNm   tickEnab( $sAxisNm ) = { LowestTickToPlot, 1.1 * rMax }		// suppress Y axis ticks where Y axis crosses bottom axis
							endif
						endif
			 			// printf "\t\tDisplayStimulus(5g) \tc:%d  b:%d  f:%d  s:%d[\t%7d\t ..\t%7d\t]has\t%7d\tpts\tnSeg:%2d\t%s\t%s\tcat:%d\tsumswp:\t%7d\t%7d\txos:\t%7.1lf\t    \r",  c, b, f, s,  nStartPos, nStartPos + nSwpPts , nSwpPts, nSeg, pd(sDacNm,8), pd(sSVNm,8), raCatStck, nSumSwpPts, nSumSwpPts1, xos


						// Draw  Axis Units  and  Axis name
						string 	rsName	=  ios( wIO, nIO, c , cIONAME ) 
						string		rsUnit  	=  ios( wIO, nIO, c , cIOUNIT ) 						
						//NameUnitsByNm( ios( wIO, nIO, c , cIONM ) , rsName, rsUnit )	
						// printf "\tDisplayStimulus()  \tNameUnitsByNm( \t%s\t)   old: \t'%s' \t-> \t'%s'  \told: \t'%s'  \t-> \t'%s'  \r", pd( ios( wIO, nIO, c , cIONM ), 6 ), sYName, rsName,  sYUnits, rsUnit
						// printf "\tDisplayStimulus()  \tNameUnitsByNm( \t%s\t)   old: \t'%s' \t-> \t'%s'  \told: \t'%s'  \t-> \t'%s'  \r", pd( ios( wIO, nIO, c , cIONM ), 6 ), rsName, ios( wIO, nIO, c , cIONAME ) ,  rsUnit, ios( wIO, nIO, c , cIOUNIT ) 
						
						SetScale /P y, 0,0,  rsUnit,   wStimulus							// Store the Y units of the wave within the wave to make it accessible for 'Scalebars()'...
						Label  /W=$sWNm $sAxisNm "\\u#2"									//..but prevent  IGOR  from drawing the units automatically (in most cases at ugly positions)
						//..instead draw the Y units manualy as a Textbox  just above the corresponding Y Axis  in the same color as the corresponding trace  
						// -54, 48, 10 are magic numbers which  are adjusted  so that the text is at the same  X as the axis. They SHOULD be   #defined......................
						// As it seems impossible to place the textbox automatically at the PERFECT position: not overlapping anithing else, not blowing up the graph too much...
						// (position depends on name length, units length, number of digout traces, graph size)  the user must possibly move it a bit (which is very fast and very easy)...
						variable	TbXPos	= c == 0 ? -54 :  48 - 10 * ( nCntDA - 1- c )				// left, left right,  left mid right...
						// the TextboxUnits has the same name as its corresponding axis: this allows easy deletion together with the axis (from the 'Axes and Scalebars' Panel)
						TextBox /W=$sWNm /C /N=$sAxisNm  /E=0 /A=MC /X=(TbXPos)  /Y=50  /F=0  /G=(rnRed, rnGreen, rnBlue)   rsName  + "\r" + rsUnit	// print YUnits horiz.  /E=0: rel. position as percentage of plot area size 
						// printf "\t\tDisplayStimulus( )   c:%2d/%2d \tTbXPos:%d \tGain:'%s'   \t%s   \t'%s'   \t'%s' \r", c, nScriptDacs, TbXPos, ios( wIO, nIO, c , cIOGAIN ), pd( sYName,12), rsUnit, sRGB
	
					endfor								// nScriptDacs
	
					if ( raCatStck == cCATFR_CATSW  ||  raCatStck == cSTACKFR_CATSW )
						nSumSwpPts	+= nSwpPts
					endif	

				endfor									// swp

				if ( raCatStck == cSTACKFR_CATSW )
					nSumSwpPts	= 0
				endif	

			endfor										// frm
		endfor
		KillWaves 	wDMinMax
		MarkPerfTestTime 840	// InterpretScript: DisplayStimulus Step5 display end

//		StimulusDecimationTest()
	endif													// gbDisplay

End		


static Function  /S  stDispWave( sIOType )
// 040410 no blocks, prots needed in name
	string 	sIOType
	return	sIOType
End	


static Function  /S  stDispWaveDgo( sDgoChans, cd )
	string 	sDgoChans
	variable	cd
	variable	nDgoCh	= str2num( StringFromList( cd, sDgoChans ) )	// the true channel number, not the index 0,1,2...
	return	"DO" + num2str( nDgoCh ) 
End	

Function  /S  DispWaveDgoFull( sDgoChans, cd )
	string 	sDgoChans
	variable	cd
	variable	nDgoCh	= str2num( StringFromList( cd, sDgoChans ) )	// the true channel number, not the index 0,1,2...
	return	"DOFull" + num2str( nDgoCh ) 
//	return	"DO" + num2str( nDgoCh ) 
End	


static Function	stSetDacMinMaxForSameUnits( sFolder, sUnits, vMin, vMax )
	string	  	sFolder, sUnits
	variable	vMin, vMax
//	svar	   	sUnitsDacMin	= $ksROOTUF_ + sFolder + ":sUnitsDacMin"
//	svar	   	sUnitsDacMax	= $ksROOTUF_ + sFolder + ":sUnitsDacMax"
	svar	   	sUnitsDacMin	= $ksROOTUF_ + sFolder + ":" + ksF_IO + ":sUnitsDacMin"
	svar	   	sUnitsDacMax	= $ksROOTUF_ + sFolder + ":" + ksF_IO + ":sUnitsDacMax"
	string	   	sMinStored	= StringByKey( sUnits, sUnitsDacMin )
	string	   	sMaxStored	= StringByKey( sUnits, sUnitsDacMax )
	sUnitsDacMin		= ReplaceStringByKey( sUnits, sUnitsDacMin, SelectString( strlen( sMinStored ), num2str( vMin ), num2str( min( vMin, str2num( sMinStored ) ) ) ) )
	sUnitsDacMax 		= ReplaceStringByKey( sUnits, sUnitsDacMax, SelectString( strlen( sMaxStored ), num2str( vMax ), num2str( max( vMax, str2num( sMaxStored ) ) ) ) )
	// printf "\t\tSetDacMinMaxForSameUnits() sUnits:%s  \tvMin:%g \tvMax:%g \t-> sUnitsDacMin:%s\tsUnitsDacMax:%s \r",  pd(sUnits,8), vMin, vMax, pd(sUnitsDacMin,25), sUnitsDacMax 
End 
	
static Function	stGetDacMinMaxForSameUnits( sFolder, sUnits, rMin, rMax )
	string	  	sFolder, sUnits
	variable	&rMin, &rMax
//	svar	   	sUnitsDacMin	= $ksROOTUF_ + sFolder + ":sUnitsDacMin"
//	svar	   	sUnitsDacMax	= $ksROOTUF_ + sFolder + ":sUnitsDacMax"
	svar	   	sUnitsDacMin	= $ksROOTUF_ + sFolder + ":" + ksF_IO + ":sUnitsDacMin"
	svar	   	sUnitsDacMax	= $ksROOTUF_ + sFolder + ":" + ksF_IO + ":sUnitsDacMax"
	rMin		= str2num( StringByKey( sUnits, sUnitsDacMin ) )
	rMax		= str2num( StringByKey( sUnits, sUnitsDacMax ) )
	// printf "\t\tGetDacMinMaxForSameUnits() sUnits:%s  \t->\tMin:%g \tMax:%g  \r",  pd(sUnits,8), rMin, rMax
End	




Function 		MyDecimate( wSource, sDestName, step, XPos, bKeepMinMaxInDecimation )
//  The code has been taken from the procedure file: "C:Programme:WaveMetrics:Igor Pro Folder:WaveMetrics Procedures:Analysis:Decimation.ipf"
//  This decimation function is adequate for stimulus or digout as amplitude is maintained independently of decimation 
	wave 	wSource
	string 	sDestName			// String contains name of dest which may or may not already exist
	variable 	step
	variable	bKeepMinMaxInDecimation// TRUE : adequate for stimulus or digout as amplitude is maintained independently of decimation 
	variable 	XPos					// 1 : X's are at left edge of decimation window (original FDecimate behavior),   2 : X's are in the middle;   3 : X's are at right edge
	XPos -= 1
	
	// Clone source so that source and dest can be identical
//	Duplicate/O wSource, decimateTmpSource
	
	variable 	nPts		= numpnts( wSource )		// number of points in input wave
	variable 	nDecPts	= floor( nPts / step )					// number of points in output wave
//	Duplicate/O	decimateTmpSource,	$sDestName			// keep same precision
//	Redimension	/N = ( nDecPts ) 		$sDestName		// set number of points to decreased value
	CopyScales	wSource,	$sDestName			// copy units

	// we'll need to fix the X scaling
	variable 	x0	= leftx( wSource )
	variable 	dx	= deltax( wSource )
	SetScale /P x, x0, dx * step, "",  $sDestName

	variable 	segWidth 	= ( step - 1 ) * dx 					// width of source wave segment
	wave 	dw 		= $sDestName						// Make compiler understand the next line as a wave assignment

	if ( ! bKeepMinMaxInDecimation )						
//		dw 	= mean( decimateTmpSource, x, x+segWidth )		// Original WM code : decimation decreases the amplitude 
	else
		variable	pt, nTargetPt = 0						// keep minimum and maximum within the interval
//		for ( pt = 0; pt < nPts; pt += 2 * step, nTargetPt += 2 )
		for ( pt = 0; pt < nPts - 2 * step; pt += 2 * step, nTargetPt += 2 )
			waveStats  /Q	/R=[ pt, pt + 2 * step - 1]	wSource	
			dw[ nTargetPt +  ( v_minLoc   > v_maxloc ) ]	= V_min	
			dw[ nTargetPt +  ( v_maxLoc >= v_minloc ) ]	= V_max
		endfor
	endif
	
	if ( XPos )
		dx	= deltax( dw )
		x0	= pnt2x( dw, 0 ) + ( segWidth ) * 0.5 * XPos
		SetScale	/P x x0, dx, dw
	endif
	
	KillWaves	/Z decimateTmpSource
End


Function 		MyDecimate1( wSource, sDestName, step, XPos, bKeepMinMaxInDecimation, nStartPt, nEndPt )
//  The code has been taken from the procedure file: "C:Programme:WaveMetrics:Igor Pro Folder:WaveMetrics Procedures:Analysis:Decimation.ipf"
//  This decimation function is adequate for stimulus or digout as amplitude is maintained independently of decimation 
	wave 	wSource
	string 	sDestName				// String contains name of dest which must already exist
	variable 	step
	variable	bKeepMinMaxInDecimation	// TRUE : adequate for stimulus or digout as amplitude is maintained independently of decimation 
	variable 	XPos						// ignored..........1 : X's are at left edge of decimation window (original FDecimate behavior),   2 : X's are in the middle;   3 : X's are at right edge
	variable 	nStartPt, nEndPt 

	XPos -= 1
	wave 	dw 		= $sDestName						// Make compiler understand the next line as a wave assignment

	variable	pt, nTargetPt = trunc( nStartPt / step )				// keep minimum and maximum within the interval
	if ( ! bKeepMinMaxInDecimation )						
		for ( pt = nStartPt; pt <= nEndPt -  step; pt +=  step, nTargetPt += 1 )
			waveStats  /Q /R=[ pt, pt + step - 1]	wSource	
			dw[ nTargetPt    ]	= V_avg	
		endfor
	else
		for ( pt = nStartPt; pt <= nEndPt ; pt += 2 * step, nTargetPt += 2 )		// pt <= nEndPt  must perhaps be refined to avoid (uncleared) garbage spikes in the traces 
			waveStats  /Q /R=[ pt, pt + 2 * step - 1]	wSource	
			dw[ nTargetPt +  ( v_minLoc   > v_maxloc ) ]	= V_min	
			dw[ nTargetPt +  ( v_maxLoc >= v_minloc ) ]	= V_max
		endfor
	endif
End


// Original WM functions are shorter but not very useful for stimulus or digout as decimation decreases the amplitude

Function 	MyFDecimate( wSource, sDestName, factor )
	wave 	wSource
	string 	sDestName		// String contains name of dest which may or may not already exist
	variable 	factor
	MyFDecimateXPos( wSource, sDestName, factor, 1)	// 1 is control of X positioning 
End

//JW- new version with control of X positioning. 6/21/96
Function 	MyFDecimateXPos( wSource, sDestName, factor, XPos)
	wave 	wSource
	string 	sDestName	// String contains name of dest which may or may not already exist
	variable 	factor
	variable 	XPos			//=1, X's are at left edge of decimation window (original FDecimate behavior)
						//=2, X's are in the middle; =3, X's are at right edge
	XPos -= 1
	
	// Clone source so that source and dest can be identical
	Duplicate/O wSource, decimateTmpSource
	
	variable 	nPts	= floor( numpnts( decimateTmpSource ) / factor ) // number of points in output wave
	Duplicate/O	decimateTmpSource,	$sDestName			// keep same precision
	Redimension	/N = ( nPts ) 		$sDestName			// set number of points to decreased value
	CopyScales	decimateTmpSource,	$sDestName			// copy units
	// we'll need to fix the X scaling
	variable 	x0	= leftx( decimateTmpSource )
	variable 	dx	= deltax( decimateTmpSource )
	SetScale/P x, x0, dx * factor, "", $sDestName
	
	variable 	segWidth 	= ( factor-1 ) * dx 					// width of source wave segment
	wave 	dw 		= $sDestName						// Make compiler understand the next line as a wave assignment
	dw 	= mean( decimateTmpSource, x, x+segWidth )
	
	if ( XPos )
		dx	= deltax( dw )
		x0	= pnt2x( dw, 0 ) + ( segWidth ) * 0.5 * XPos
		SetScale	/P x x0, dx, dw
	endif
	
	KillWaves	/Z decimateTmpSource
End


