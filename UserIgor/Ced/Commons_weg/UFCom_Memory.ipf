//
//  UFCom_Memory.ipf 
// 
#pragma rtGlobals=1							// Use modern global access method.

#pragma IndependentModule=UFCom_

//#include "UFCom_Constants"					// for MBYTE
static constant	MBYTE = 0x10000

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//===============================================================================================================================
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// ATTEMPTS  TO  AVOID  MEMORY  FRAGMENTATION     ( keep  'GrowN()' functions  although currently not used...)

constant		kBYTE8 = 0,  kUBYTE8 = 1,  kINT16 = 2,  kUINT16 = 3,  kINT32 = 4,  kUINT32 = 5,  kREAL32 = 6,  kDOUBLE64 = 7  
strconstant	lstNUMTYP			= "Byte8;UByte8;Int16;UInt16;Int32;UInt32;Real32;Double64;"
strconstant	lstNUMTYP_MEM		= "1;1;2;2;4;4;4;8;"
constant		bPRINT_ALL_MAKES 	= 0//1			// for debugging : will print all memory allocations for waves ( only those called over 'MakeN()'  )

Function		UFCom_Grow1( n0, sWvNm, InitVal, nErrorLevel )
// Attempt to avoid memory fragmentation
// Ensures that a sufficiently large 1-dimensional  number wave exists. The wave will be created or will grow, but will never shrink.  Returns 0 when successful  or -1 when failing.
	variable	n0, InitVal
	variable	nErrorLevel			// determines action in case of error: kERR_FATAL will stop program by opening dialog box.  ONLY FOR TESTING : kERR_IMPORTANT (and less) allows proceeding 
	string  	sWvNm				// contains folders
	wave  /Z	wv = $sWvNm
	if ( waveExists( $sWvNm ) )
		variable	numPts	= DimSize( $sWvNm, 0 ) 
		if ( n0 > numPts )
			Redimension /N=( n0 )  $sWvNm
		endif
	else
		make  	/N = ( n0 )	$sWvNm
	endif
	wave  	wv = $sWvNm
	wv		= InitVal
	numPts	= DimSize( wv, 0 ) 	

	if ( numPts < n0 )
		string  	sMessage
		sprintf sMessage, "Grow1() could not construct '%s' ( %d points ) because the required memory ( %.1lf MB ) could not be allocated. [Total free mem: %.1lf MB]", sWvNm, n0, n0 * 4 / 1024 /1024, str2num( StringByKey( "FREEMEM", IgorInfo( 0 ) ) ) / 1024 / 1024
		UFCom_Alert( nErrorLevel, sMessage )
		return	kNOTFOUND
	endif
		printf "Grow1() : \t%s\t ( should have at least \t   %12d \tpoints, has now \t   %12d \t ) is OK.\r",  UFCom_pd( sWvNm,33), n0, numPts
	return	0
End 

Function		UFCom_Grow4( n0, n1, n2, n3, sWvNm, InitVal, nErrorLevel )
// Attempt to avoid memory fragmentation
// Ensures that a sufficiently large 1-dimensional  number wave exists. The wave will be created or will grow, but will never shrink.  Returns 0 when successful  or -1 when failing.
	variable	n0, n1, n2, n3, InitVal
	variable	nErrorLevel			// determines action in case of error: kERR_FATAL will stop program by opening dialog box.  ONLY FOR TESTING : kERR_IMPORTANT (and less) allows proceeding 
	string  	sWvNm				// contains folders
	
	variable	numPts0, numPts1, numPts2, numPts3
	wave  /Z	wv = $sWvNm
	if ( waveExists( $sWvNm ) )
		numPts0	= DimSize( $sWvNm, 0 ) 
		if ( n0 > numPts0 )
			Redimension /N=( n0, -1, -1, -1 )  $sWvNm
		endif
		numPts1	= DimSize( $sWvNm, 1 ) 
		if ( n1 > numPts1 )
			Redimension /N=( -1, n1, -1, -1 )  $sWvNm
		endif
		numPts2	= DimSize( $sWvNm, 2 ) 
		if ( n2 > numPts2 )
			Redimension /N=( -1, -1, n2, -1 )  $sWvNm
		endif
		numPts3	= DimSize( $sWvNm, 3 ) 
		if ( n3 > numPts3 )
			Redimension /N=( -1, -1, -1, n3 )  $sWvNm
		endif
	else
		make  	/N = ( n0, n1, n2, n3  ) $sWvNm
	endif
	wave  	wv = $sWvNm
	wv		= InitVal
	numPts0	= DimSize( wv, 0 ) 	
	numPts1	= DimSize( wv, 1 ) 	
	numPts2	= DimSize( wv, 2 ) 	
	numPts3	= DimSize( wv, 3 ) 	

	if ( numPts0 < n0 )
		string  	sMessage
		sprintf sMessage, "Grow4() could not construct '%s' ( %d  %d  %d  %d points ) because the required memory ( %.1lf MB ) could not be allocated. [Total free mem: %.1lf MB]", sWvNm, n0, n1, n2, n3,  n0 *n1*n2*n3 * 4 / 1024 /1024, str2num( StringByKey( "FREEMEM", IgorInfo( 0 ) ) ) / 1024 / 1024
		UFCom_Alert( nErrorLevel, sMessage )
		return	kNOTFOUND
	endif
		printf "Grow4() : \t%s\t ( should have at least \t%8d\t%8d\t%8d\t%8d\tpoints, has now \t%8d\t%8d\t%8d\t%8d\t\t ) is OK.\r",  UFCom_pd( sWvNm,33), n0, n1, n2, n3, numPts0, numPts1, numPts2, numPts3
	return	0
End 


Function		UFCom_Make1( sWvNm, n0, nType, InitVal, bOverwrite, nErrorLevel )
// Constructs  1-dimensional  number wave.  Returns 0 when successful  or -1 when failing.
	string  	sWvNm					// contains folders
	variable	n0, nType, InitVal, bOverwrite
	variable	nErrorLevel				// determines action in case of error: kERR_FATAL will stop program by opening dialog box.  ONLY FOR TESTING : kERR_IMPORTANT (and less) allows proceeding 
	if ( bOverwrite )
		switch ( nType )
			case kBYTE8:
				make  /O	/B	/N = ( n0 )	$sWvNm	= InitVal
				break
			case kUBYTE8:
				make  /O	/B/U/N = ( n0 )	$sWvNm	= InitVal
				break
			case kINT16:
				make  /O	/W	/N = ( n0 )	$sWvNm	= InitVal
				break
			case kUINT16:
				make  /O	/W/U/N =	( n0 )	$sWvNm	= InitVal
				break
			case kINT32:
				make  /O	/I	/N = ( n0 )	$sWvNm	= InitVal
				break
			case kUINT32:
				make  /O	/I /U	/N = ( n0 )	$sWvNm	= InitVal
				break
			case kDOUBLE64:
				make  /O	/D	/N = ( n0 )	$sWvNm	= InitVal
				break
			case kREAL32:
			default:
				make  /O	/R	/N = ( n0 )	$sWvNm	= InitVal		// real wave
		endswitch	
	else
		switch ( nType )
			case kBYTE8:
				make  	/B	/N = ( n0 )	$sWvNm	= InitVal
				break
			case kUBYTE8:
				make  	/B/U/N = ( n0 )	$sWvNm	= InitVal
				break
			case kINT16:
				make  	/W	/N = ( n0 )	$sWvNm	= InitVal
				break
			case kUINT16:
				make  	/W/U/N=	( n0 )	$sWvNm	= InitVal
				break
			case kINT32:
				make  	/I	/N = ( n0 )	$sWvNm	= InitVal
				break
			case kUINT32:
				make  	/I /U	/N = ( n0 )	$sWvNm	= InitVal
				break
			case kDOUBLE64:
				make  	/D	/N = ( n0 )	$sWvNm	= InitVal
				break
			case kREAL32:
			default:
				make  	/R	/N = ( n0 )	$sWvNm	= InitVal		// real wave
		endswitch	
	endif
	if ( DimSize( $sWvNm, 0 ) != n0 )
		string  	sMessage
		sprintf sMessage, "Make1 could not construct '%s' ( \t%s,\t%10d\tpoints ) because the required memory ( %.1lf MB ) could not be allocated. [Total free mem: %.1lf MB]", sWvNm, StringFromList( nType, lstNUMTYP), n0, n0 *  str2num( StringFromList( nType, lstNUMTYP_MEM) ) / 1024 /1024, str2num( StringByKey( "FREEMEM", IgorInfo( 0 ) ) ) / 1024 / 1024
		UFCom_Alert( nErrorLevel, sMessage )
		return	kNOTFOUND
	endif
	if ( bPRINT_ALL_MAKES )
		printf "\t\t\tMake1 has constructed\t%s\t( %s,\tpts:\t%10d\t = %.3lf MB ) \r",  UFCom_pd(sWvNm,25),  StringFromList( nType, lstNUMTYP), n0, n0 * str2num( StringFromList( nType, lstNUMTYP_MEM) ) / 1024 /1024
	endif
	return	0
End 



Function		UFCom_Make4( sWvNm, n0, n1, n2, n3, nType, InitVal, bOverwrite, nErrorLevel )
// Constructs  4-dimensional  number wave.  Returns 0 when successful  or -1 when failing.
	string  	sWvNm					// contains folders
	variable	n0, n1, n2, n3, nType, InitVal, bOverwrite
	variable	nErrorLevel				// determines action in case of error: kERR_FATAL will stop program by opening dialog box.  ONLY FOR TESTING : kERR_IMPORTANT (and less) allows proceeding 
	if ( bOverwrite )
		switch ( nType )
			case kBYTE8:
				make  /O	/B	/N = ( n0, n1, n2, n3 )	$sWvNm	= InitVal
				break
			case kUBYTE8:
				make  /O	/B/U/N = ( n0, n1, n2, n3 )	$sWvNm	= InitVal
				break
			case kINT16:
				make  /O	/W	/N = ( n0, n1, n2, n3 )	$sWvNm	= InitVal
				break
			case kUINT16:
				make  /O	/W/U/N =	( n0, n1, n2, n3 )$sWvNm	= InitVal
				break
			case kINT32:
				make  /O	/I	/N = ( n0, n1, n2, n3 )	$sWvNm	= InitVal
				break
			case kUINT32:
				make  /O	/I /U	/N = ( n0, n1, n2, n3 )	$sWvNm	= InitVal
				break
			case kDOUBLE64:
				make  /O	/D	/N = ( n0, n1, n2, n3 )	$sWvNm	= InitVal
				break
			case kREAL32:
			default:
				make  /O	/R	/N = ( n0, n1, n2, n3 )	$sWvNm	= InitVal		// real wave
		endswitch	
	else
		switch ( nType )
			case kBYTE8:
				make  	/B	/N = ( n0, n1, n2, n3 )	$sWvNm	= InitVal
				break
			case kUBYTE8:
				make  	/B/U/N = ( n0, n1, n2, n3 )	$sWvNm	= InitVal
				break
			case kINT16:
				make  	/W	/N = ( n0, n1, n2, n3 )	$sWvNm	= InitVal
				break
			case kUINT16:
				make  	/W/U/N=	( n0, n1, n2, n3 )$sWvNm	= InitVal
				break
			case kINT32:
				make  	/I	/N = ( n0, n1, n2, n3 )	$sWvNm	= InitVal
				break
			case kUINT32:
				make  	/I /U	/N = ( n0, n1, n2, n3 )	$sWvNm	= InitVal
				break
			case kDOUBLE64:
				make  	/D	/N = ( n0, n1, n2, n3 )	$sWvNm	= InitVal
				break
			case kREAL32:
			default:
				make  	/R	/N = ( n0, n1, n2, n3 )	$sWvNm	= InitVal		// real wave
		endswitch	
	endif
	if ( DimSize( $sWvNm, 0 ) != n0  ||  DimSize( $sWvNm, 1 ) != n1  ||  DimSize( $sWvNm, 2 ) != n2  ||  DimSize( $sWvNm, 3 ) != n3  )
		string  	sMessage
		sprintf sMessage, "Make4 could not construct '%s' ( \t%s,\t%7d,\t%7d,\t%7d,\t%7d\tpoints ) because the required memory ( %.1lf MB ) could not be allocated. [Total free mem: %.1lf MB]", sWvNm, StringFromList( nType, lstNUMTYP),  n0, n1, n2, n3,   n0*n1*n2*n3*  str2num( StringFromList( nType, lstNUMTYP_MEM) ) / 1024 /1024, str2num( StringByKey( "FREEMEM", IgorInfo( 0 ) ) ) / 1024 / 1024
		UFCom_Alert( nErrorLevel, sMessage )
		return	kNOTFOUND
	endif
	if ( bPRINT_ALL_MAKES )
		printf "\t\t\tMake4 has constructed  '%s' ( \t%s,\t%7d,\t%7d,\t%7d,\t%7d )\t[pts = %d ~ %.3lf MB ] \r", sWvNm, StringFromList( nType, lstNUMTYP), n0, n1, n2, n3,  n0*n1*n2*n3,  n0*n1*n2*n3* str2num( StringFromList( nType, lstNUMTYP_MEM) ) / 1024 /1024
	endif
	return	0
End 


constant		kMEM_GRANULARITY	= 50000		// No attempt is made to measure the memory more precise than this. Do not make this smaller than 200K because each computation step may take as long as 1 minute (if virtual memory is accessed) 

Function		UFCom_BiggestContiguousMemory( sTxt )
// Measure the biggest contiguous memory segment to check fragmentation.
// Needs (depending on kMEM_GRANULARITY) about 10 to 20 steps.
// Typical values with Win2k, 512MB RAM:  When Igor (and no other programs)  has been running for some minutes : 100 MB, computation time ~2 seconds  
// 								 After a reboot virtual memory seems to be accessed				 :  960 MB but computation time ~ 5 minutes (and the disk heavily working). 
	string  	sTxt					// only if sTxt is not empty then all of the memory sizes will be printed (and sTxt also)
	string  	sWvNM		= "tmp"
	variable	cnt = 0
	variable	nMem, bMemFail
	variable	nMemOK 		= 0
	variable	nVirtualMem	= str2num( StringByKey( "FREEMEM", IgorInfo( 0 ) ) )			// or   = xUtilAvailVirtual()
	variable	nMemFail, nTotalVirtual, nAvailVirtual, nTotalPhys, nAvailPhys, bIsVirtualMemory
	
	// nMemFail			= 4096 * MBYTE	// Maxinum memory check starting value. Maximum allowed number is 4096MB, more cannot be detected. 
	//But using a value this high as a starting value will return finally the virtual memory and will take some minutes for computing (heavy disk access!)...
	//...so it makes sense to use the amount of physical memory as a starting value.
	nAvailVirtual	= xUtilAvailVirtual()	//
	nTotalPhys	= xUtilTotalPhys()	//
	nAvailPhys	= xUtilAvailPhys()	//

	//nMemFail    	= 2 * nTotalPhys	// We are not interested in virtual memory so we start with the physical memory when determining the biggest contiguous memory
	nMemFail    	= 2 * nAvailPhys		// We are not interested in virtual memory so we start with the physical memory when determining the biggest contiguous memory
	nMemFail    	= 	nAvailVirtual	// We   are     interested in virtual memory so we start with the available virtual memory when determining the biggest contiguous memory


	nMemOK		= 0
	// printf "\t\tPhysicalMemoryMemory() returns: %.3lf MB (Virtual memory: %.3lf MB) \r", nPhysicalMemory / 1024 / 1024, str2num( StringByKey( "FREEMEM", IgorInfo( 0 ) ) ) / 1024 / 1024

	do
		nMem	= ( nMemOK + nMemFail ) / 2 
		bMemFail	= xUtilContiguousMemory( nMem )				// returns 0 on success
		if ( bMemFail )
			nMemFail = nMem
		else
			nMemOK = nMem
		endif
		cnt	+= 1
		// printf "\t\tBiggestContiguousMemory( in MB )   It:\t%3d\tTrying to allocate:\t%5.1lf\tMB\t%s\tMemOK:\t%5.1lf\tMemFail:\t%5.1lf\tNext test:\t%5.1lf\t%s\t \r", cnt, nMem/MBYTE, SelectString( bMemFail, " OK " , "FAIL" ), nMemOK/MBYTE, nMemFail/MBYTE, ( nMemOK + nMemFail ) / 2/MBYTE, Time()
		bIsVirtualMemory	=  nMemOK >= nAvailPhys
	while ( nMemFail - nMemOK > kMEM_GRANULARITY  &&  !bIsVirtualMemory   &&  cnt < 30 )					// emergeny bail out 

	if ( strlen( sTxt ) )
		string  	sText			= SelectString( bIsVirtualMemory, "- Probably in physical memory: OK" , "- In virtual memory, not useful ! " ) 
		printf "\t\tBiggestContiguousMemory(\t%s\t)  Gran: %d\tIters:%3d\tAlloc:\t%7.2lf\tMB\tPhysAv: %7.2lf\t/%7.2lf\tVirtAv: %7.2lf \t%s\t \r",  UFCom_pd( sTxt, 19), kMEM_GRANULARITY, cnt, nMemOK/MBYTE, nAvailPhys/MBYTE, nTotalPhys/MBYTE, nAvailVirtual/MBYTE, sText 
	endif
//	// Now check and watch the task manager. Wait 10 seconds
//	Make /O /N=( nMemOK/4 )  $sWvNm								// assume 4-byte-real waves
//	printf "\r\tNow check and watch the task manager. Wait 10 seconds. \r" 
//	Delay( 10 )
//	KillWaves /Z $sWvNm
	return	nMemOK									// returns number of bytes of biggest contiguous memory
End


