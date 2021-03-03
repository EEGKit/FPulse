//
//  UFCom_Numbers.ipf 
// 
// rounding errors / real to int conversion errors lead lead to Pon error between 0...1,  should be -.5..+.5 
// IGOR number precision demo: printf " 50 / .1 =%lf, (50*10)/(.1*10)= %lf, 123456780 / 10 =%lf, 987654320 / 10 =%lf \r",  50 / .1, (50*10)/(.1*10), 123456780 / 10, 987654320 / 10
// Igors rounding in num2istr() is only approximate: print num2istr( 12345678912345679) yields   12345678912345680  (Igor6.01)



#pragma rtGlobals=1							// Use modern global access method.

//#pragma IndependentModule=UFCom_	
#include "UFCom_Constants"


// Never change the following constants which are defined by Igor 
// General
//static constant		UFCom_kNOTFOUND		=  -1					

Function		UFCom_IsNumber( value )
	variable	value
	return	( numType( value ) != UFCom_kNUMTYPE_NAN )
End

//===============================================================================================================================
//   PRIMES

Function  /S	UFCom_Factors( sFo, nPnts )	
// build list containing all possible factors
	string  	sFo
	variable	nPnts	
	string 	lstFct		= ""
	string 	lstPrimes	= ""
	lstPrimes	= UFCom_FPPrimeFactors( sFo, nPnts )
	lstFct		= ""
	lstFct		= AddListItem( UFCom_num2strDec( nPnts ), lstFct )		// include  'nPnts' in the list
	
	// printf "\t\t\tFactorsFast( n:%5d ) \t\t\t\t\t\t-> Primes: %s... \r", nPnts, lstPrimes
	variable	pr, f
	for ( pr = 0; pr < ItemsInList( lstPrimes ); pr += 1 )
		variable	Prime	= str2num( StringFromList( pr, lstPrimes ) )
		variable	nFct		= ItemsInList( lstFct )
		for ( f = 0; f < nFct; f += 1 )
			variable	Fct	= str2num( StringFromList( f, lstFct ) )
			if ( Fct / Prime  == trunc( Fct / Prime ) )
				if ( WhichListItem( UFCom_num2strDec( Fct / Prime ), lstFct ) == UFCom_kNOTFOUND )
					lstFct		= AddListItem( UFCom_num2strDec( Fct / Prime ), lstFct, ";", Inf )
					// printf "\t\t\t\tFactors\tPrime( pr:%2d ) :%4d\tFct( f:%2d ) : %4d\t->Factors: %s \r", pr, Prime, f, Fct, lstFct
				endif
			endif
		endfor
	endfor
	lstFct		= SortList( lstfct, ";", 2 ) 		// 1: descending, 2:numerical sort
	// printf "\t\t\tFactors( n:%5d ) \tfactors:%3d\tlen:%4d\t-> factors: %s.....%s \r", nPnts, ItemsInList(lstFct), strlen( lstFct), lstFct[0,40], lstFct[ strlen( lstFct ) - 55, strlen( lstFct ) ]
	return	lstFct
End


Function	/S	UFCom_FPPrimeFactors( sFo, nNumber )
// Returns string list containing the prime factors of 'nNumber'
// Comparison with Igor's built-in PrimeFactors (see PnTest()  Primes()  Test10) :	
// 1. takes appr. up to 1 second if number approaches	2^31 ~ 2 000 000 000, Igor is much faster ( takes < 1ms )  
// 2. can handle numbers greater than the Igor limit of 	2^31 ~ 2 000 000 000, but becomes really slow in this range.  Breaking  ~ 200 000 000 000 takes about 100 seconds.
// As long  FPPrimeFactors()  is used as seldom  as it is adapting to Igor's much faster implementation has no advantage.....
	string  	sFo
	variable	nNumber							// number to be broken into factors
	variable	n
	string  	lstFactors	= ""

//	// FPuls implementation ( greater range but much slower ) 
//	variable	nMaxPrime = sqrt( nNumber )			// Search primes only up to this limit....
//	// Step 1: build string  list containing all primes (up to a limit) to be used when breaking  'n'  into factors
//	string 	lstPrimes	= Primes( nMaxPrime )		// returns all prime numbers up to  'nMax'  as string  list  using the Sieve of Erasthothenes (takes 1s for nMax=100000, but >2 min for nMax=1000000 ???)
//	variable	nPrimes	=  ItemsInList( lstPrimes)
//	// print		"\t\tBreakIntoPrimes1(", nMaxPrime, nPrimes, lstPrimes[ strlen( lstPrimes ) - 200, strlen( lstPrimes ) ]
//
//	// Step 2:
//	variable	Prime, pr, pStart = 0
//	n = nNumber
//	for ( pr = pStart; pr < nPrimes; pr += 1 )
//		Prime	= str2num( StringFromList( pr, lstPrimes ) )
//		if ( n / Prime == trunc( n / Prime ) )
//			n	= n / Prime
//			pr	= pStart - 1				// the prime just found may be contained multiple times 
//			lstFactors	= AddListItem( UFCom_num2strDec( Prime ), lstFactors, ";", Inf )
//			continue
//		endif
//	endfor
//	if ( n != 1 )
//		lstFactors	= AddListItem( UFCom_num2strDec( n ), lstFactors, ";", Inf )	//
//	endif
//	// printf "\t\t\tBreakIntoPrimes2( n:\t%9d )  \t\t\t\t\tnMaxPrime:\t\t%8d \t-> factors: %s \r", nNumber, nMaxPrime, lstFactors[ strlen( lstFactors ) - 200, strlen( lstFactors ) ]

	// Igor's implementation ( much faster but limited to appr. 2 000 000 000 )
	string 	savedDF= GetDataFolder( 1 )		// Remember CDF in a string.
	SetDataFolder $"root:uf:" + sFo + ":misc" 	
	PrimeFactors 	/Q  nNumber		
	wave	W_PrimeFactors	= $"root:uf:" + sFo + ":misc:W_PrimeFactors"
	for ( n = 0; n < numPnts( W_PrimeFactors ); n += 1 )
		lstFactors	= AddListItem( UFCom_num2strDec( W_PrimeFactors[ n ] ), lstFactors, ";", Inf )	
	endfor
	SetDataFolder savedDF 	

	
	return	lstFactors
End

//static Function	/S	Primes( nMax )
//// returns all prime numbers up to  'nMax'  as string  list  using the Sieve of Erasthothenes (takes 1s for nMax=100000, but >2 min for nMax=1000000 ???)
//	variable	nMax
//	variable	n, i, nCheckLimit = sqrt( nMax )				// checking up to the root is enough
//	string 	lstPrimes	= ""
//
//	make  /O  /B  /N=( nMax+1 )	root:uf: sFo :  misc:bIsPrime = UFCom_TRUE	// initially assume every number to be a prime
//	wave	bIsPrime 	= root:uf:  sFo  misc:bIsPrime 
//	for ( n = 2; n < nCheckLimit; n += 1 )				// checking up to the root is enough
//		if ( bIsPrime[ n ] )
//			for ( i = 2 * n ; i <= nMax; i += n ) 			// multiplies of a prime cannot be a prime..
//				bIsPrime[ i ] = UFCom_FALSE				// ..so we sort them out
//			endfor
//		endif
//	endfor
//	for ( n = 2; n <= nMax; n += 1 )					// build string  list containing all the primes
//		if ( bIsPrime[ n ] )
//			lstPrimes	= AddListItem( UFCom_num2strDec( n ), lstPrimes, ";", Inf )
//		endif
//	endfor
//	// printf "\t\t\tPrimes( up to\t%8d\t ) : finds \t%8d\tprimes   '%s..........%s' \r", nMax, ItemsInList( lstPrimes), lstPrimes[ 0, 24 ], lstPrimes[ strlen( lstPrimes ) - 70, strlen( lstPrimes ) ]
//	killwaves	bIsPrime
//	return	lstPrimes
//End

// 2004-0831  Currently not used
// static Function	BreakIntoFactorsForTimer2( nTotalMicroSecs, rPre1, rPre2, rCount )
//// Break the passed number into 3 factors all between 2 and 65535. This constrain is imposed by the Ced Timer2.
//	variable	nTotalMicroSecs
//	variable	&rPre1, &rPre2, &rCount
//	// nTotalMicroSecs= 65537*8*17*1021	// test for an invalid case
//
//	// Step 1 : Check that the breaking into primes is not impossible from the beginning
//	string		lstPrimes		= FPPrimeFactors( nTotalMicroSecs )
//	variable	nPrimes		= ItemsInList( lstPrimes )
//	variable	BiggestPrime	= str2num( StringFromList( nPrimes-1, lstPrimes ) ) 		// sorting enforces that the last is the biggest
//	string		sBuf
//	// printf "\t\tBreakIntoFactorsForTimer2( nTotalMicroSecs :\t%10d\t)   Step 1 \tPrimeCnt:%3d  \tlstPrimes: '%s'  Last prime:%d  \r",  nTotalMicroSecs, nPrimes, lstPrimes[0,150], BiggestPrime
//	if ( nPrimes < 3  ||  BiggestPrime > 65535 )
//		sprintf sBuf, "Total stimulus time of %d us is not divisible into at least 3 factors each between 2 and 65535. [%s] . Adjust stimulus duration slightly and try again...\r", nTotalMicroSecs,  lstPrimes[0,150]
//		FoAlert( sFolder, UFCom_kERR_SEVERE, sBuf )
//	endif
//
//	// Step 2 : Combine smallest and largest prime (=first and last in the list)  to find the biggest factor below 65535.  This approach  may  NOT  find  the best factor. For this one would have to combine the largest with all others, not only with the first...
//	variable	IndexFirstPrime	= 0
//	variable	SmallestPrime
//	variable	BigFactor		= BiggestPrime 
//	variable	Rest
//	do 
//		if ( nPrimes == 3 )
//			break
//		endif
//		SmallestPrime	= str2num( StringFromList( IndexFirstPrime, lstPrimes ) )  	
//		BigFactor		*=  SmallestPrime
//		if ( BigFactor > 65535 )
//			BigFactor	/= SmallestPrime
//			break
//		endif
//		IndexFirstPrime	+= 1
//		nPrimes		-= 1
//	while ( UFCom_TRUE )
//	Rest	= nTotalMicroSecs / BigFactor
//	// printf "\t\tBreakIntoFactorsForTimer2( nTotalMicroSecs :\t%10d\t)   Step 2 \tbig factor: %d , rest: %.3lf \r",  nTotalMicroSecs, BigFactor, Rest
//	rCount	= BigFactor
//
//	// Step 3 : Break the 'Rest'  into 2 factors
//	// printf "\t\tBreakIntoFactorsForTimer2( nTotalMicroSecs :\t%10d\t)   Step 3 \tbreaking the rest: %.3lf \r",  nTotalMicroSecs, Rest
//	lstPrimes		= FPPrimeFactors( Rest )
//	nPrimes		= ItemsInList( lstPrimes )
//	BiggestPrime	= str2num( StringFromList( nPrimes-1, lstPrimes ) ) 		// sorting enforces that the last is the biggest
//
//	// printf "\t\tBreakIntoFactorsForTimer2( \t Rest\t\t :\t%10d \t)   Step 4 \tPrimeCnt:%3d  \tlstPrimes: '%s'  Last prime:%d  \r",  Rest, nPrimes, lstPrimes[0,150], BiggestPrime
//	// Step 4 : Combine smallest and largest prime (=first and last in the list)  to find the biggest factor below 65535.  This approach  may  NOT  find  the best factor. For this one would have to combine the largest with all others, not only with the first...
//	IndexFirstPrime	= 0
//	BigFactor		= BiggestPrime 
//	do 
//		if ( nPrimes == 2 )			// 2 not 3
//			break
//		endif
//		SmallestPrime	= str2num( StringFromList( IndexFirstPrime, lstPrimes ) )  	
//		BigFactor		*=  SmallestPrime
//		if ( BigFactor > 65535 )
//			BigFactor	/= SmallestPrime
//			break
//		endif
//		IndexFirstPrime	+= 1
//		nPrimes		-= 1
//	while ( UFCom_TRUE )
//	rPre1	= Rest / BigFactor
//	rPre2	= BigFactor
//	// printf "\t\tBreakIntoFactorsForTimer2(  \t Rest\t\t :\t%10d \t)   Step 5 \tbig factor: %d , rest: %.3lf \r",  Rest, BigFactor, rPre1
//
//	// Security check....
//	if ( rPre1 < 2 || rPre1 >65535 || rPre2 < 2 || rPre2 >65535 || rCount < 2 || rCount >65535 ||  nTotalMicroSecs != rPre1 * rPre2 * rCount )
//		printf "****Internal error: BreakIntoFactorsForTimer2( nTotalMicroSecs :\t%10d\t)  -> %d  =  %d * %d * %d  \r",  nTotalMicroSecs, rPre1 * rPre2 * rCount, rPre1, rPre2, rCount
//	endif
//	printf "\t\tBreakIntoFactorsForTimer2( nTotalMicroSecs :\t%10d\t)  -> %d  =  %d * %d * %d  \r",  nTotalMicroSecs, rPre1 * rPre2 * rCount, rPre1, rPre2, rCount
//End



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//   NUMBERS

Function	/S	UFCom_num2strDec( n )
// Convert number into string  keeping the decimal notation (and avoiding the exponential notation). The Igor function num2str( 123456 )  would give '1.23456e+05' 
	variable	n
//	string 		bf
//	sprintf bf, "%d", n
//	return	bf
// 2007-0724
	return	num2istr( n )
End

Function	/S	UFCom_num2strDecDigits( value, nDigits )
// Convert  'value'  into string  formatting  'nDigits'  after the decimal point.   Igors num2str  function has only a very limited precision of 1e-5
	variable	value, nDigits
	string 	bf
	string		sFormatString
	sprintf sFormatString, "%%.%dlf", nDigits  	// e.g.  '%.2lf'
	sprintf bf, sFormatString, value
	return	bf
End

Function	/S 	UFCom_ListPowers( n )
// Returns a stringlist containing the powers of 2 in which  'n'  can be broken. Does not handle negative numbers or infinity
	variable	n
	variable	nPow = 0
	string  	lstPowers	= ""
	do
		if ( mod( n, 2 ) )							// dividing n by 2 leaves a remainder
			lstPowers	+= num2str( nPow ) + ";"
		endif
		nPow  += 1
		n	    = trunc( n / 2 )	
	while ( n > 0 )
	return	lstPowers
End


Function		UFCom_RandomInt( nBeg, nEnd )
// returns random integers in the range and including nBeg..nEnd
	variable	nBeg, nEnd
	nEnd		+= 1
	variable	nRandomInt	= trunc ( nBeg + ( nEnd - nBeg + enoise( nEnd - nBeg ) ) / 2  )
	// print "UFCom_RandomInt(", nBeg, nEnd-1, ") = ", nRandomInt
	return	nRandomInt
End 


Function		UFCom_Random( nBeg, nEnd, nStep )
// returns random integer from within the given range, divisible by 'nStep'
	variable	nBeg, nEnd, nStep
	variable	nRange	= ( nEnd - nBeg ) / nStep						// convert to Igors random range ( -nRange..+nRange )
	variable	nRandom	= trunc ( abs( enoise( nRange ) ) ) * nStep + nBeg		// maybe not perfectly random but sufficient for our purposes
	// printf "\tUFCom_Random( nBeg:%6d \tnEnd:%6d  \tStep:%6d \t) : %g \r", nBeg, nEnd, nStep, nRandom
	return	nRandom
End

 
Function		UFCom_clip( minimum, value, maximum )
	variable	minimum, value, maximum
	return	max( minimum, min( value, maximum ) )			 
End


//==================================================================================================================================
 //  SHUFFLING  A  WAVE
 
Function	/S 	UFCom_ShuffledWaveNm( cnt, seed  )
// returns the folder wave name of an index wave containing 'cnt' shuffled values
// seed = 0 will return a different shuffling on every call, any other value <= 1 will return the same sequence 
	variable	cnt
	variable	seed		
	if ( seed )
		SetRandomSeed( seed )
	endif	
        Make	 /O/N=(cnt)	wShuffled  = p
        Make	 /O/N=(cnt)	wRandom   = enoise(1)
        Sort		   wRandom, wShuffled
        KillWaves/Z wRandom
        return GetWavesDataFolder(wShuffled,2)
End 


Function UFCom_Shuffle( wShuffled, seed )
// Shuffles  the indexwave 'wShuffled' , which in turn can be used to shuffle ....  
// 'wShuffled' must have been constructed constructed beforehand  e.g.  Make/N=100 wShuffled=p   (or =p+ofs if you want values in the range ofs...100+ofs)
// seed = 0 will return a different shuffling on every call, any other value <= 1 will return the same sequence 
        wave 	wShuffled
	variable	seed	
	if ( seed )
		SetRandomSeed( seed )
	endif	
  	Make /O/N=( numPnts( wShuffled ) )	wRandom = enoise(1)
        Sort 		   wRandom, wShuffled
        KillWaves/Z wRandom
End


//==================================================================================================================================
 //  COMPUTING  NICE  TICK  NUMBERS
 
Function	UFCom_ComputeNiceTicks( nTicks, BegVal, EndVal, rTickBaseNice, rTickExpNice, rTickDigits )
// Computes and passes back  the tick distance  and the  tick exponent.  To be used e.g. ModifyGraph  manTick( $sAxis )  = {0, rTickBaseNice, rTickExpNice, 1},
	variable	nTicks, BegVal, EndVal
	variable	&rTickBaseNice, &rTickExpNice, &rTickDigits 

	variable	TickStep		= ( EndVal - BegVal ) / nTicks
	variable	TickLog		= log( Tickstep )
	variable	TickExp		= floor( TickLog )
	variable	TickBase		= TickLog - TickExp
	rTickBaseNice	= 10^TickBase

	if ( rTickBaseNice <= 2 )
		rTickBaseNice = 2
	elseif ( rTickBaseNice <= 5 )  
		rTickBaseNice = 5 
	else
		rTickBaseNice = 10
	endif 

	if ( mod( TickExp, 3 ) == -2 )			// e.g. -5	-> 100/200/500 * 10^-6
		rTickExpNice	 = TickExp - 1
		rTickBaseNice 	*= 10
		rTickDigits 	 =  0
	elseif ( mod( TickExp, 3 ) == -1 )			// e.g. -4	-> 0.1/0.2/0.5	* 10^-3
		rTickExpNice	= TickExp + 1
		rTickBaseNice 	/= 10
		rTickDigits 	 =  2
	elseif ( mod( TickExp, 3 ) == 1 )			// e.g. 4	-> 10/20/50	* 10^3
		rTickExpNice	= TickExp - 1
		rTickBaseNice 	*= 10
		rTickDigits 	 =  0
	elseif ( mod( TickExp, 3 ) == 2 )			// e.g. 5	-> 100/200/500	* 10^3
		rTickExpNice	= TickExp + 1
		rTickBaseNice 	/= 10
		rTickDigits 	 =  0
	elseif ( mod( TickExp, 3 ) == 0 )			// e.g. 3	-> 1/2/5		* 10^3
		rTickExpNice	= TickExp 
		rTickDigits 	 =  1
	endif
	// printf "\t\tUFCom_ComputeNiceTicks   \tnTicks:\t%8.2lf\tBeg:\t%g\tEnd:\t%g\tTickStep:\t%8g  \t1/ tickstep:\t%8g\tlogar:\t%8g\t->\tTickBase:\t%8.3lf\tTickExp:\t%8.1lf\tmod:\t%6.2lf\t->\t%8.2lf x 10^ %.0lf    \tDigits:%d\t \r", nTicks, BegVal, EndVal, TickStep, 1/ tickstep, TickLog, TickBase, TickExp, mod( TickExp, 3 ), rTickBaseNice, rTickExpNice, rTickDigits 
End

