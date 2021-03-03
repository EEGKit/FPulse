//
//  UFCom_Timers.ipf 
// 
#pragma rtGlobals=1							// Use modern global access method.

//#pragma IndependentModule=UFCom_
#include "UFCom_Constants"

//===============================================================================================================================
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  DELAY  TIMER
 
 Function		UFCom_Delay( seconds )
	variable	seconds
 	variable	nTick = ticks 
	do
 	while ( ticks < nTick + 60 * seconds )
End


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//   MICROSECOND  TIMER  FUNCTIONS

Function		UFCom_KillAllTimers() 
	variable	n, dummy
	svar		sAllTimers	= root:uf:misc:sAllTimers
	for ( n = 0; n <= 9; n += 1)
		dummy = stopMSTimer( n )
	endfor	
	sAllTimers	= ""
End


Function		UFCom_ResetStartTimer( sTimerNm ) 
	string 	sTimerNm
	UFCom_ResetTimer( sTimerNm )
	UFCom_StartTimer( sTimerNm ) 
End

Function		UFCom_ResetTimer( sTimerNm ) 
	string 	sTimerNm
//	sAllTimers = RemoveByKey( sTimerNm, sAllTimers )
	SetTimerTime( sTimerNm, 0 )
End

Function		UFCom_StartTimer( sTimerNm ) 
// create and start an  IGOR timer, store the IGOR timer number in 'sAllTimers'
	string 	sTimerNm

	// we must first try to free the timer which possibly exists already  (e.g. when an error abort prevents the usual 'StopTimer() call ) .. 	 030912
	//.. in order to prevent that all timers get used up by forgotten timers
	if ( numType( GetTimerNumber( sTimerNm )  ) != UFCom_kNUMTYPE_NAN )
		UFCom_StopTimer( sTimerNm )
	endif
	variable	nTimerNumber	 = startMSTimer
	if ( nTimerNumber == -1 )
		printf "**** Internal error . Cannot  initialize '%s' because all timers are in use \r", sTimerNm
	else
		SetTimerNumber( sTimerNm, nTimerNumber )
		// printf "\tStartTimer(\t%s\t) has started  timer with number %d = %d  \r",  UFCom_pd( sTimerNm, 10 ), nTimerNumber, GetTimerNumber( sTimerNm )
	endif
End

Function		UFCom_StopTimer( sTimer ) 
// stop the IGOR timer, read and store its value in 'sAllTimers',  the IGOR timer is deleted automatically 
// Cave 0311: this function itself takes an appreciable amount of time (100us...1ms) so use it only outside of loops
	string 	sTimer
	SetTimerTime( sTimer, stopMSTimer( GetTimerNumber( sTimer ) ) + GetTimerTime( sTimer ) )
End

Function		UFCom_ReadTimer( sTimer ) 
// read the value stored in 'sAllTimers' and return this value in milliseconds
// Cave 0311: this function itself takes an appreciable amount of time (100us...1ms) so use it only outside of loops
   	string 	sTimer
	return	GetTimerTime( sTimer ) / 1000
End

Function		UFCom_PrintAllTimers( bON ) 
// reads out and prints all timers
	variable	 bON 
	svar		sAllTimers		= root:uf:misc:sAllTimers
//	variable   	PnDebgTim	= DebugSection() & kDBG_Timer		// TIM
//	if ( bON  ||  PnDebgTim )
	if ( bON )
		variable	n, nTimers = ItemsInList( sAllTimers )
		string 		sTimer_ms, bf = "\t\tTimer  (All, \tn:" + num2str( nTimers ) + ") " 
		for ( n = 0; n < nTimers; n +=1 )			 
			string 	sTimerNm	= GetTimerName( n )
			//sprintf  sTimer_ms, "%7.1lf", GetTimerTime( sTimerNm ) / 1000 
			sprintf  sTimer_ms, "%6.1lf", GetTimerTime( sTimerNm ) / 1000 
			//bf += sTimerNm[0,9] + ":" +  sTimer_ms + SelectString( n == nTimers-1, "\t", "\r" )
			bf += sTimerNm[0,4] + ":" +  sTimer_ms + SelectString( n == nTimers-1, "   ", "\r" )
		endfor	
		printf "%s", bf
	endif
End

Function		UFCom_PrintSelectedTimers( sSelectedTimers ) 
// reads out and prints as many timers as passed in list  'sTexts' 
   	string 	sSelectedTimers
	variable	n, nTimers = ItemsInList( sSelectedTimers )
	string 	sTimer_ms, bf = "\t\tTimer  (Sel, \tn:" + num2str( nTimers ) + ") "  
	for ( n = 0; n < nTimers; n +=1 )			 
		string 	sTimerNm	= StringFromList( n, sSelectedTimers )
		sprintf  sTimer_ms, "%7.1lf", GetTimerTime( sTimerNm ) / 1000 
		bf += sTimerNm[0,9] + ":" +  sTimer_ms + SelectString( n == nTimers-1, "\t", "\r" )
	endfor	
	printf "%s", bf
End

//---------------------------------------------------------------------------------------------------------------------
//   IMPLEMENTATION  of  the  TIMERS

static Function  /S	GetTimerName( n )
// returns timer name when list index (not timer number!) is given
	variable	n
	svar		sAllTimers	= root:uf:misc:sAllTimers
	string 	sOneTimer	= StringFromList( n,  sAllTimers )
	return	StringFromList( 0, sOneTimer, ":" )
End

static Function		SetTimerTime( sTimerNm , n_us )
	string 	sTimerNm
	variable	n_us
	svar		sAllTimers	= root:uf:misc:sAllTimers
	sAllTimers	= ReplaceStringByKey( sTimerNm, sAllTimers, num2str( GetTimerNumber( sTimerNm ) ) + "," + num2str( n_us ) )

End

static Function		SetTimerNumber( sTimerNm , nTimerNr )
	string 	sTimerNm
	variable	nTimerNr
	svar		sAllTimers	= root:uf:misc:sAllTimers
	sAllTimers	= ReplaceStringByKey( sTimerNm, sAllTimers, num2str( nTimerNr ) + "," + num2str( GetTimerTime( sTimerNm ) ) ) 
End

static Function		GetTimerTime( sTimerNm )
	string 	sTimerNm
	svar		sAllTimers	= root:uf:misc:sAllTimers
	string 	sTimerNr	="noNr ",	sTimerTime="noTime ", sOneTimer	= StringByKey( sTimerNm, sAllTimers )
	if ( strlen( sOneTimer ) )
		sTimerNr	= StringFromList( 0, sOneTimer, "," )
		sTimerTime	= StringFromList( 1, sOneTimer, "," )
	endif
	return	str2num( sTimerTime )
End

static Function		GetTimerNumber( sTimerNm )
	string 	sTimerNm
	svar		sAllTimers	= root:uf:misc:sAllTimers
	string 	sTimerNr	="noNr ",	sTimerTime="noTime ", sOneTimer	= StringByKey( sTimerNm, sAllTimers )
	if ( strlen( sOneTimer ) )
		sTimerNr		= StringFromList( 0, sOneTimer, "," )
		sTimerTime	= StringFromList( 1, sOneTimer, "," )
	endif
	return	str2num( sTimerNr )		// returns NaN  if timer does not exist
End


