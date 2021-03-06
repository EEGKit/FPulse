//
//  FP_Numbers.ipf 
// 
// rounding errors / real to int conversion errors lead lead to Pon error between 0...1,  should be -.5..+.5 
// IGOR number precision demo: printf " 50 / .1 =%lf, (50*10)/(.1*10)= %lf, 123456780 / 10 =%lf, 987654320 / 10 =%lf \r",  50 / .1, (50*10)/(.1*10), 123456780 / 10, 987654320 / 10

#pragma rtGlobals=1							// Use modern global access method.

//===============================================================================================================================
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//===============================================================================================================================
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//   PRIMES


Function	/S	FPPrimeFactors( sFo, nNumber )
// Returns string list containing the prime factors of 'nNumber'
// Comparison with Igor's built-in PrimeFactors (see PnTest()  Primes()  Test10) :	
// 1. takes appr. up to 1 second if number approaches	2^31 ~ 2 000 000 000, Igor is much faster ( takes < 1ms )  
// 2. can handle numbers greater than the Igor limit of 	2^31 ~ 2 000 000 000, but becomes really slow in this range.  Breaking  ~ 200 000 000 000 takes about 100 seconds.
// As long  FPPrimeFactors()  is used as seldom  as it is adapting to Igor's much faster implementation has no advantage.....
	string  	sFo
	variable	nNumber							// number to be broken into factors
	variable	n
	string  	lstFactors	= ""

//	// FPulse implementation ( greater range but much slower ) 
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
//			lstFactors	= AddListItem( num2strDec( Prime ), lstFactors, ";", Inf )
//			continue
//		endif
//	endfor
//	if ( n != 1 )
//		lstFactors	= AddListItem( num2strDec( n ), lstFactors, ";", Inf )	//
//	endif
//	// printf "\t\t\tBreakIntoPrimes2( n:\t%9d )  \t\t\t\t\tnMaxPrime:\t\t%8d \t-> factors: %s \r", nNumber, nMaxPrime, lstFactors[ strlen( lstFactors ) - 200, strlen( lstFactors ) ]

	// Igor's implementation ( much faster but limited to appr. 2 000 000 000 )
	string 	savedDF= GetDataFolder( 1 )		// Remember CDF in a string.
// 2009-12-10
//	SetDataFolder root:uf:aco:misc 	
	SetDataFolder $ksROOTUF_ + sFo + ":misc" 	
	PrimeFactors 	/Q  nNumber		
// 2009-12-10
//	wave	W_PrimeFactors	= root:uf:aco:misc:W_PrimeFactors
	wave	W_PrimeFactors	= $ksROOTUF_ + sFo + ":misc:W_PrimeFactors"
	for ( n = 0; n < numPnts( W_PrimeFactors ); n += 1 )
		lstFactors	= AddListItem( num2strDec( W_PrimeFactors[ n ] ), lstFactors, ";", Inf )	
	endfor
	SetDataFolder savedDF 	

	
	return	lstFactors
End

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//   NUMBERS

Function	/S	num2strDec( n )
// convert number into string  keeping the decimal notation. The Igor function num2str( 123456 )  would give '1.23456e+05' 
	variable	n
	string 		bf
	sprintf bf, "%d", n
	return	bf
End

Function	/S 	ListPowers( n )
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

Function		RandomInt( nBeg, nEnd )
// returns random integers in the range and including nBeg..nEnd
	variable	nBeg, nEnd
	nEnd		+= 1
	variable	nRandomInt	= trunc ( nBeg + ( nEnd - nBeg + enoise( nEnd - nBeg ) ) / 2  )
	// print "RandomInt(", nBeg, nEnd-1, ") = ", nRandomInt
	return	nRandomInt
End 


Function		clip( minimum, value, maximum )
	variable	minimum, value, maximum
	return	max( minimum, min( value, maximum ) )			 
End
 
