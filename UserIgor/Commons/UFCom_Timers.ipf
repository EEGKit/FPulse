//
//  UFCom_Timers.ipf 
// 
#pragma rtGlobals=1							// Use modern global access method.

//#pragma IndependentModule=UFCom_
#include "UFCom_Constants"

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


//===============================================================================================================================
//   NEW  ELABORATE  MICROSECOND  TIMER  FUNCTIONS  (080725)

Function	/S	List10Timers( sFo )
	string  	sFo
	svar	/Z lst		= $"root:uf:" + sFo + ":misc:lst10timers"
	if ( ! svar_exists( lst ) )
		string /G	   $"root:uf:" + sFo + ":misc:lst10timers" = ""
		svar	 lst	= $"root:uf:" + sFo + ":misc:lst10timers"
	endif
	return	lst
End

Function	/S	List10TimersSet( sFo, lst )
	string  	sFo, lst
	string /G	   $"root:uf:" + sFo + ":misc:lst10timers" = lst
End


Function		UFCom_ResetStartTimer_( sFo, sTimerNm ) 
	string 	sFo, sTimerNm
	variable	nTimerRef	= startMSTimer
	if ( nTimerRef == - 1 )
		printf "**** Internal error[UFCom_ResetStartTimer_] . Cannot  initialize '%s' because all timers are in use \r", sTimerNm
	else
		string  	lstTimers	= List10Timers( sFo )
		lstTimers	= ReplaceStringByKey( sTimerNm, lstTimers, num2str( nTimerRef ) + "~" + "0" )	// subindex 0 is timer name,  1 is timer time
		List10TimersSet( sFo, lstTimers )
		//printf "\tUFCom_ResetStartTimer_(\t%s\t ) \t%s\t \r", UFCom_pd( sTimerNm,7 ),  List10Timers()
	endif
End


Function		UFCom_StopTimer_( sFo, sTimerNm ) 
// Kills the timer but keeps the timer in the list where it it is removed on UFCom_ReadTimer_(). 
// Note: After the timer is killed but before it is read its number is may not be unique because a new timer may be assigned the same number by Igor but this is OK.
	string 	sFo, sTimerNm
	string  	lstTimers	= List10Timers( sFo )
	string	  	sNr_Value	= StringByKey( sTimerNm, lstTimers )					// subindex 0 is timer name,  1 is timer time
	if ( strlen( sNr_Value ) == 0 )
		printf "**** Internal error [UFCom_StopTimer_]. Timer '%s' not found  in '%s' \r", sTimerNm, lstTimers
	else
		variable nTimer	= str2num( StringFromList( 0, sNr_Value, "~" ) )			// kill the physical timer   but  keep the list entry
		variable us		= stopMSTimer( nTimer )
		sNr_Value		= num2str( nTimer ) + "~" +  num2str( us )				// subindex 0 is timer name,  1 is timer time
		lstTimers		= ReplaceStringByKey( sTimerNm, lstTimers, sNr_Value )	
		List10TimersSet( sFo, lstTimers )
		//printf "\tUFCom_StopTimer_( \t\t%s\t ) \t%s\t \r", UFCom_pd( sTimerNm,7 ),  List10Timers()
	endif
End


Function		UFCom_ReadTimer_( sFo, sTimerNm ) 
// Read the timer value (stored globally on  UFCom_StopTimer_() )  from the global list.  Then delete  this timer from the list.
	string 	sFo, sTimerNm
	string  	lstTimers	= List10Timers( sFo )
	string	  	sNr_Value	= StringByKey( sTimerNm, lstTimers )					// subindex 0 is timer name,  1 is timer time
	if ( strlen( sNr_Value ) == 0 )
		printf "**** Warning [UFCom_ReadTimer_]. Timer '%s' not found in '%s' \r", sTimerNm, lstTimers
		return -1
	else
		variable us		= str2num( StringFromList( 1, sNr_Value, "~" ) )			// subindex 0 is timer name,  1 is timer time
		lstTimers		= RemoveByKey( sTimerNm, lstTimers )
		List10TimersSet( sFo, lstTimers )
		//printf "\tUFCom_ReadTimer_(\t7\t%s\t ) \t%s\t\t\treturns %d millisecs \r", UFCom_pd( sTimerNm,7 ),  List10Timers(), us/1000
		return us
	endif
End





//===============================================================================================================================
//   SIMPLE  MICROSECOND  TIMER  FUNCTIONS

Function		UFCom_StartSimpleTimer() 
// create and start an  IGOR timer and  return the IGOR timer number 
	variable	nTimerNumber	 = startMSTimer
	if ( nTimerNumber == -1 )
		printf "**** Internal error . Cannot  initialize Microsecond timer because all timers are in use.   Returning invalid nTimerNumber = %d \r", nTimerNumber
	endif
	return	nTimerNumber
End

Function		UFCom_StopSimpleTimer( nTimerNumber ) 
// stop and read and kill the IGOR timer and  return the elapsed microseconds
	variable	nTimerNumber
	if ( nTimerNumber != -1 )
		variable microSeconds = stopMSTimer( nTimerNumber )
		// printf "\t\tMicrosecond timer %d  returns %d usecs.\r", nTimerNumber, microSeconds
	endif
	return	microSeconds
End



//===============================================================================================================================
//   ELABORATE MICROSECOND  TIMER  FUNCTIONS

// 2008-07-25 probably wrong ..........see above.......................should ELIMINATE.....

Function		UFCom_ResetStartTimer( sFo, sTimerNm ) 
	string 	sFo, sTimerNm
	UFCom_ResetTimer( sFo, sTimerNm )
	UFCom_StartTimer( sFo, sTimerNm ) 
End

Function		UFCom_ResetTimer( sFo, sTimerNm ) 
	string 	sFo, sTimerNm
//	sAllTimers = RemoveByKey( sTimerNm, sAllTimers )
	SetTimerTime( sFo, sTimerNm, 0 )
End

Function		UFCom_StartTimer( sFo, sTimerNm ) 
// create and start an  IGOR timer, store the IGOR timer number in 'sAllTimers'
	string 	sFo, sTimerNm

	// we must first try to free the timer which possibly exists already  (e.g. when an error abort prevents the usual 'StopTimer() call ) .. 	 030912
	//.. in order to prevent that all timers get used up by forgotten timers
	if ( numType( GetTimerNumber( sFo, sTimerNm )  ) != UFCom_kNUMTYPE_NAN )
		UFCom_StopTimer( sFo, sTimerNm )
	endif
	variable	nTimerNumber	 = startMSTimer
	if ( nTimerNumber == -1 )
		printf "**** Internal error . Cannot  initialize '%s' because all timers are in use \r", sTimerNm
	else
		SetTimerNumber( sFo, sTimerNm, nTimerNumber )
		// printf "\tStartTimer(\t%s\t) has started  timer with number %d = %d  \r",  UFCom_pd( sTimerNm, 10 ), nTimerNumber, GetTimerNumber( sTimerNm )
	endif
End

Function		UFCom_StopTimer( sFo, sTimer ) 
// stop the IGOR timer, read and store its value in 'sAllTimers',  the IGOR timer is deleted automatically 
// Cave 0311: this function itself takes an appreciable amount of time (100us...1ms) so use it only outside of loops
	string 	sFo, sTimer
	SetTimerTime( sFo, sTimer, stopMSTimer( GetTimerNumber( sFo, sTimer ) ) + GetTimerTime( sFo, sTimer ) )
End

Function		UFCom_ReadTimer( sFo, sTimer ) 
// read the value stored in 'sAllTimers' and return this value in milliseconds
// Cave 0311: this function itself takes an appreciable amount of time (100us...1ms) so use it only outside of loops
   	string 	sFo, sTimer
	return	GetTimerTime( sFo, sTimer ) / 1000
End

// ...........................080725 probably wrong ...........see above.......................


Function		UFCom_PrintAllTimers( sFo, bON ) 
// reads out and prints all timers
	string  	sFo
	variable	 bON 
	svar		sAllTimers		= $"root:uf:" + sFo + ":misc:sAllTimers"
	if ( bON )
		variable	n, nTimers = ItemsInList( sAllTimers )
		string 		sTimer_ms, bf = "\t\tTimer  (All, \tn:" + num2str( nTimers ) + ") " 
		for ( n = 0; n < nTimers; n +=1 )			 
			string 	sTimerNm	= GetTimerName( sFo, n )
			//sprintf  sTimer_ms, "%7.1lf", GetTimerTime( sTimerNm ) / 1000 
			sprintf  sTimer_ms, "%6.1lf", GetTimerTime( sFo, sTimerNm ) / 1000 
			//bf += sTimerNm[0,9] + ":" +  sTimer_ms + SelectString( n == nTimers-1, "\t", "\r" )
			bf += sTimerNm + ":" +  sTimer_ms + SelectString( n == nTimers-1, "   ", "\r" )
		endfor	
		printf "%s", bf
	endif
	// print sAllTimers
End

Function		UFCom_PrintSelectedTimers( sFo, sSelectedTimers ) 
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

Function		UFCom_KillAllTimers( sFo ) 
	string  	sFo
	variable	n, dummy
	svar		sAllTimers	= $"root:uf:" + sFo + ":misc:sAllTimers"
	for ( n = 0; n <= 9; n += 1)
		dummy = stopMSTimer( n )
	endfor	
	sAllTimers	= ""
End

//---------------------------------------------------------------------------------------------------------------------
//   IMPLEMENTATION  of  the  TIMERS

static Function  /S	GetTimerName( sFo, n )
// returns timer name when list index (not timer number!) is given
	string  	sFo
	variable	n
	svar		sAllTimers	= $"root:uf:" + sFo + ":misc:sAllTimers"
	string 	sOneTimer	= StringFromList( n,  sAllTimers )
	return	StringFromList( 0, sOneTimer, ":" )
End

static Function		SetTimerTime( sFo, sTimerNm , n_us )
	string  	sFo
	string 	sTimerNm
	variable	n_us
	svar		sAllTimers	= $"root:uf:" + sFo + ":misc:sAllTimers"
	sAllTimers	= ReplaceStringByKey( sTimerNm, sAllTimers, num2str( GetTimerNumber( sFo, sTimerNm ) ) + "," + num2str( n_us ) )

End

static Function		SetTimerNumber( sFo, sTimerNm , nTimerNr )
	string  	sFo
	string 	sTimerNm
	variable	nTimerNr
	svar		sAllTimers	= $"root:uf:" + sFo + ":misc:sAllTimers"
	sAllTimers	= ReplaceStringByKey( sTimerNm, sAllTimers, num2str( nTimerNr ) + "," + num2str( GetTimerTime( sFo, sTimerNm ) ) ) 
End

static Function		GetTimerTime( sFo, sTimerNm )
	string  	sFo
	string 	sTimerNm
	svar		sAllTimers	= $"root:uf:" + sFo + ":misc:sAllTimers"
	string 	sTimerNr	="noNr ",	sTimerTime="noTime ", sOneTimer	= StringByKey( sFo, sTimerNm, sAllTimers )
	if ( strlen( sOneTimer ) )
		sTimerNr	= StringFromList( 0, sOneTimer, "," )
		sTimerTime	= StringFromList( 1, sOneTimer, "," )
	endif
	return	str2num( sTimerTime )
End

static Function		GetTimerNumber( sFo, sTimerNm )
	string  	sFo
	string 	sTimerNm
	svar		sAllTimers	= $"root:uf:" + sFo + ":misc:sAllTimers"
	string 	sTimerNr	="noNr ",	sTimerTime="noTime ", sOneTimer	= StringByKey( sTimerNm, sAllTimers )
	if ( strlen( sOneTimer ) )
		sTimerNr		= StringFromList( 0, sOneTimer, "," )
		sTimerTime	= StringFromList( 1, sOneTimer, "," )
	endif
	return	str2num( sTimerNr )		// returns NaN  if timer does not exist
End


