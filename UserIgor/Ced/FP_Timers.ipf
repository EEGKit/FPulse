//
//  FP_Timers.ipf 
// 
#pragma rtGlobals=1							// Use modern global access method.

//===============================================================================================================================
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//===============================================================================================================================
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  DELAY  TIMER
 
 Function		Delay( seconds )
	variable	seconds
 	variable	nTick = ticks 
	do
 	while ( ticks < nTick + 60 * seconds )
End


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//   MICROSECOND  TIMER  FUNCTIONS

Function		KillAllTimers( sFo ) 
	string  	sFo
	variable	n, dummy
// 2009-12-10
	svar		sAllTimers	= $"root:uf:" + sFo + ":misc:sAllTimers"
//	svar		sAllTimers	= root:uf:aco:misc:sAllTimers
	for ( n = 0; n <= 9; n += 1)
		dummy = stopMSTimer( n )
	endfor	
	sAllTimers	= ""
End


Function		ResetStartTimer( sFo, sTimerNm ) 
	string 	sFo, sTimerNm
	ResetTimer( sFo, sTimerNm )
	StartTimer( sFo, sTimerNm ) 
End

Function		ResetTimer( sFo, sTimerNm ) 
	string  	sFo
	string 	sTimerNm
//	sAllTimers = RemoveByKey( sTimerNm, sAllTimers )
	SetTimerTime( sFo, sTimerNm, 0 )
End

Function		StartTimer( sFo, sTimerNm ) 
// create and start an  IGOR timer, store the IGOR timer number in 'sAllTimers'
	string 	sFo, sTimerNm

	// we must first try to free the timer which possibly exists already  (e.g. when an error abort prevents the usual 'StopTimer() call ) .. 	 030912
	//.. in order to prevent that all timers get used up by forgotten timers
	if ( numType( GetTimerNumber( sFo, sTimerNm )  ) != kNUMTYPE_NAN )
		StopTimer( sFo, sTimerNm )
	endif
	variable	nTimerNumber	 = startMSTimer
	if ( nTimerNumber == -1 )
		printf "**** Internal error . Cannot  initialize '%s' because all timers are in use \r", sTimerNm
	else
		SetTimerNumber( sFo, sTimerNm, nTimerNumber )
		// printf "\tStartTimer(\t%s\t) has started  timer with number %d = %d  \r",  pd( sTimerNm, 10 ), nTimerNumber, GetTimerNumber( sTimerNm )
	endif
End

Function		StopTimer( sFo, sTimer ) 
// stop the IGOR timer, read and store its value in 'sAllTimers',  the IGOR timer is deleted automatically 
// Cave 0311: this function itself takes an appreciable amount of time (100us...1ms) so use it only outside of loops
	string 	sFo, sTimer
	SetTimerTime( sFo, sTimer, stopMSTimer( GetTimerNumber( sFo, sTimer ) ) + GetTimerTime( sFo, sTimer ) )
End

Function		ReadTimer( sFo, sTimer ) 
// read the value stored in 'sAllTimers' and return this value in milliseconds
// Cave 0311: this function itself takes an appreciable amount of time (100us...1ms) so use it only outside of loops
   	string 	sFo, sTimer
	return	GetTimerTime( sFo, sTimer ) / 1000
End

Function		PrintAllTimers( sFo, bUncondtionallyON ) 
// reads out and prints all timers
	string  	sFo
	variable	 bUncondtionallyON 
// 2009-12-10
	svar		sAllTimers	= $"root:uf:" + sFo + ":misc:sAllTimers"
//	svar		sAllTimers	= root:uf:aco:misc:sAllTimers

// 2009-10-28 remove debug printing
//	if ( bUncondtionallyON )
	variable   	PnDebgTim	= DebugSection() & kDBG_Timer		// TIM
	if ( bUncondtionallyON  ||  PnDebgTim )
		variable	n, nTimers = ItemsInList( sAllTimers )
		string 		sTimer_ms, bf = "\t\tTimer  (All, \tn:" + num2str( nTimers ) + ") " 
		for ( n = 0; n < nTimers; n +=1 )			 
			string 	sTimerNm	= GetTimerName(sFo, n )
			//sprintf  sTimer_ms, "%7.1lf", GetTimerTime( sTimerNm ) / 1000 
			sprintf  sTimer_ms, "%6.1lf", GetTimerTime( sFo, sTimerNm ) / 1000 
			//bf += sTimerNm[0,9] + ":" +  sTimer_ms + SelectString( n == nTimers-1, "\t", "\r" )
			bf += sTimerNm[0,4] + ":" +  sTimer_ms + SelectString( n == nTimers-1, "   ", "\r" )
		endfor	
		printf "%s", bf
	endif
End

Function		PrintSelectedTimers( sFo, sSelectedTimers ) 
// reads out and prints as many timers as passed in list  'sTexts' 
   	string 	sFo, sSelectedTimers
	variable	n, nTimers = ItemsInList( sSelectedTimers )
	string 	sTimer_ms, bf = "\t\tTimer  (Sel, \tn:" + num2str( nTimers ) + ") "  
	for ( n = 0; n < nTimers; n +=1 )			 
		string 	sTimerNm	= StringFromList( n, sSelectedTimers )
		sprintf  sTimer_ms, "%7.1lf", GetTimerTime( sFo, sTimerNm ) / 1000 
		bf += sTimerNm[0,9] + ":" +  sTimer_ms + SelectString( n == nTimers-1, "\t", "\r" )
	endfor	
	printf "%s", bf
End

//---------------------------------------------------------------------------------------------------------------------
//   IMPLEMENTATION  of  the  TIMERS

Function  /S	GetTimerName( sFo, n )
// returns timer name when list index (not timer number!) is given
	string  	sFo
	variable	n
// 2009-12-10
	svar		sAllTimers	= $"root:uf:" + sFo + ":misc:sAllTimers"
//	svar		sAllTimers	= root:uf:aco:misc:sAllTimers
	string 	sOneTimer	= StringFromList( n,  sAllTimers )
	return	StringFromList( 0, sOneTimer, ":" )
End

Function		SetTimerTime( sFo, sTimerNm , n_us )
	string  	sFo
	string 	sTimerNm
	variable	n_us
// 2009-12-10
	svar		sAllTimers	= $"root:uf:" + sFo + ":misc:sAllTimers"
//	svar		sAllTimers	= root:uf:aco:misc:sAllTimers
	sAllTimers	= ReplaceStringByKey( sTimerNm, sAllTimers, num2str( GetTimerNumber( sFo, sTimerNm ) ) + "," + num2str( n_us ) )

End

Function		SetTimerNumber( sFo, sTimerNm , nTimerNr )
	string  	sFo
	string 	sTimerNm
	variable	nTimerNr
// 2009-12-10
	svar		sAllTimers	= $"root:uf:" + sFo + ":misc:sAllTimers"
//	svar		sAllTimers	= root:uf:aco:misc:sAllTimers
	sAllTimers	= ReplaceStringByKey( sTimerNm, sAllTimers, num2str( nTimerNr ) + "," + num2str( GetTimerTime( sFo, sTimerNm ) ) ) 
End

Function		GetTimerTime( sFo, sTimerNm )
	string  	sFo
	string 	sTimerNm
// 2009-12-10
	svar		sAllTimers	= $"root:uf:" + sFo + ":misc:sAllTimers"
//	svar		sAllTimers	= root:uf:aco:misc:sAllTimers
	string 	sTimerNr	="noNr ",	sTimerTime="noTime ", sOneTimer	= StringByKey( sTimerNm, sAllTimers )
	if ( strlen( sOneTimer ) )
		sTimerNr	= StringFromList( 0, sOneTimer, "," )
		sTimerTime	= StringFromList( 1, sOneTimer, "," )
	endif
	return	str2num( sTimerTime )
End

Function		GetTimerNumber( sFo, sTimerNm )
	string  	sFo
	string 	sTimerNm
// 2009-12-10
	svar		sAllTimers	= $"root:uf:" + sFo + ":misc:sAllTimers"
//	svar		sAllTimers	= root:uf:aco:misc:sAllTimers
	string 	sTimerNr	="noNr ",	sTimerTime="noTime ", sOneTimer	= StringByKey( sTimerNm, sAllTimers )
	if ( strlen( sOneTimer ) )
		sTimerNr		= StringFromList( 0, sOneTimer, "," )
		sTimerTime	= StringFromList( 1, sOneTimer, "," )
	endif
	return	str2num( sTimerNr )		// returns NaN  if timer does not exist
End


