//
//	XopMain.c -- 

#include "C:\Program files\wavemetrics\IgorXOPs\XOPSupport\XOPStandardHeaders.h" //..ANSI headers IgorXOP.h XOP.h XOPSupport.h

#include "XopMain.h"

#pragma pack(2)    //  all structures are 2-byte-Aligned for Igor Tollkit , 4-byte-aligned for MCTG.


#define REQUIRES_IGOR_200          1 + FIRST_XOP_ERR
#define UNKNOWN_XFUNC              2 + FIRST_XOP_ERR


///////////////////////////////////////////////////////////////////////////////////
// Fnction-ROUTINEN

int IndexOfLastFunction()
{
   int fCnt = 0;
   while ( sFunc[fCnt].fnc )
      fCnt++;
   return fCnt-1;
}



static int  DoFunction()
{
	int   funcIndex, n;
//	void *p;												// ptr to struc containing function params and result
	int   err = 0;										// error code returned by function

	funcIndex = GetXOPItem(0);						// which function invoked ?
//	p = (void *)GetXOPItem(1);					   // get pointer to params and result

   if ( funcIndex > IndexOfLastFunction() )  // more functions in xxx.RC
      err = UNKNOWN_XFUNC;                   //   than in sFunc array
  return err;
}


static long RegisterFunction()
{
// 0409 using 'Direct method' only
	int funcIndex;

	funcIndex = GetXOPItem(0);						// which function invoked ?

   if ( funcIndex > IndexOfLastFunction() )	// more functions in xxx.RC
      return NIL;										//  than in sFunc array
  return (long)sFunc[funcIndex].fnc;			// the function adress is returned
}



static void  XOPEntry( void )
//	This is the entry point from the host application to the XOP for all messages after the INIT message.
{	
   int  cmdIndex;
	long result = 0;
	int  type	= GetXOPMessage();
 
   switch( type ) 
   {
/* 040924
		case CMD:									// command passed to XOP ? 
			result = DoOperation();				// examine parameters and process them 
			SetXOPType((long)TRANSIENT);		// XOP has done its job, so discard it 
			break;
*/
		case FUNCTION:								// our external function being invoked?
			result = DoFunction();
			break;
			
		case FUNCADDRS:
			result = RegisterFunction();
			break;

	}

/*	
	// CED error codes from -500..-611 (s. prog int lib dec 1999, p34)
   // ..are renumbered into the range 100..211   (see UFp2_CfsWinCustom.RC)
   if ( -611 <= result && result <= -500 )
      //result = FIRST_XOP_ERR - result - 400; 
      result = ErrorNrCEDtoIGOR( result );
*/
	
	SetXOPResult( result );

}



HOST_IMPORT void  main( IORecHandle ioRecHandle )
//	This is the initial entry point at which the host application calls XOP.
//	The MessMage sent by the host must be INIT.
//	main() does any necessary initialization and then sets the XOPEntry field of the
//	  ioRecHandle to the address to be called for future messages.
{	
	char	sMsg[128];

	#ifdef XOP_GLOBALS_ARE_A4_BASED
		#ifdef __MWERKS__
			// For CodeWarrior 68K XOPs.
			SetCurrentA4();								// Set up correct A4. This allows globals to work.
			SendXOPA4ToIgor(ioRecHandle, GetA4());	// And communicate it to Igor.
		#endif
	#endif
	
   LoadXOPSegs();											// for functions
	XOPInit(ioRecHandle);								// do standard XOP initialization 
	SetXOPEntry(XOPEntry);								// set entry point for future calls 

	
	if (igorVersion < 200)								// for functions
		SetXOPResult(REQUIRES_IGOR_200);				// ..
	else														// ..
		SetXOPResult(0L);//0L);// test: -1 has no effect

	// Initialisation message to remind the programmer about the Release/Debug mode..
	// Better: Remind earlier, remind while releasing and not at program start...
#ifdef _DEBUG
//	sprintf( sMsg, "************************\r***** D E B U G *****\r************************\r" );
	sprintf( sMsg, "Loaded UFp2_Cfs.xop (debug) \r" );
	XOPNotice( sMsg );
#else
	sprintf( sMsg, "Loaded UFp2_Cfs.xop\r" );
	XOPNotice( sMsg );
#endif

}



/////////////////////////////////////////////////////////////////////////////
// SOME  UTILTIES

// 041126
Handle	IHC( Handle sIgorString )
//  converts Igor string handle to C style string --- WITHOUT  memory locking
//  returns C string or 0 in case of error meaning NO_INPUT_STRING or NOMEM 
//! after being finished with the C string you MUST REMOVE it with  DisposeHandle( Cstring ); 
{ 
	int		len;
   Handle	pCStr;

//	char buf[1000];		//050203	
	
	if ( !sIgorString )								// error:  input string does not exist
	{
		XOPNotice( "***** Error: NULL string handle received in 'CStringHandle()' \r" );
		return	(Handle)0;//NO_INPUT_STRING;	//  ..IGOR passed an empty string or a NULL string
	}
	len	= GetHandleSize( sIgorString );		// length of string is just one too short for..
	if ( !( pCStr	= NewHandle(len + 1) ) )	// ..string end \0  so make longer new string..
	{
		XOPNotice( "***** Error: Not enough memory in 'CStringHandle()' \r" );
		DisposeHandle( sIgorString );				// we need to get rid of the original Igor string
		return	(Handle)0;
	}
	
	memcpy( *pCStr, *sIgorString, len );		// ..fill with passed data..

	*(*pCStr+len) = '\0';							// ..append string end

	//050203	
/*	sprintf( buf, "\t050128 IHC    \t\t0x%08x\t0x%08x\t\t\t\tlen:%3d \t", sIgorString, pCStr, len );
	if ( len < 1000-100 )	
		strcat( buf, 	*pCStr );
	strcat( buf, 	"\r" );
	XOPNotice( buf );
*/
   DisposeHandle( sIgorString );					// we need to get rid of the original Igor string

	
	return	pCStr;									// Return POINTER to 0-terminated C string
}




int DisposeHandleIHC( Handle pCStr )
{
// 050128
/*
	char buf[1000];
	sprintf( buf, "\t050128 IHCDispose \t\t\t\t0x%08x\t0x%08x \r", pCStr, *pCStr );
	XOPNotice( buf );
*/
	DisposeHandle( pCStr );               // we need to get rid of the C handle (= memory of C string)
	return 0;
}




#pragma pack()   

