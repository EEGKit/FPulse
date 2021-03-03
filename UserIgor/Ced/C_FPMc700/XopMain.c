//	XopMain.c -- 

#include "\Program files\wavemetrics\IgorXOPs\XOPSupport\XOPStandardHeaders.h" //..ANSI headers IgorXOP.h XOP.h XOPSupport.h

#include "XopMain.h"


#pragma pack(4)    //  all structures are 4-byte-aligned for MCTG.


#define REQUIRES_IGOR_200          1 + FIRST_XOP_ERR
#define UNKNOWN_XFUNC              2 + FIRST_XOP_ERR

// Forward declarations



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
	void *p;          // ptr to struc containing function params and result
	int   err = 0;    // error code returned by function

	funcIndex = GetXOPItem(0);      // which function invoked ?
	p = (void *)GetXOPItem(1);	     // get pointer to params and result

   if ( funcIndex > IndexOfLastFunction() )  // more functions in xxx.RC
      err = UNKNOWN_XFUNC;                   //   than in sFunc array
	return err;
}


static long RegisterFunction()
{
// 0409 using 'Direct method' only
	int funcIndex;

	funcIndex = GetXOPItem(0);	             // which function invoked ?

   if ( funcIndex > IndexOfLastFunction() )// more functions in xxx.RC
      return NIL;                          //  than in sFunc array
	return (long)sFunc[funcIndex].fnc;		 // the function adress is returned
}


static void  XOPEntry(void)
//	This is the entry point from the host application to the XOP for all
//	  Messages after the INIT Message.
{	
	long result   = 0;
   int  cmdIndex;
	int  type = GetXOPMessage();
 
   switch( type ) 
   {
/* 040924
		case CMD:						    // command passed to XOP ? 
			result = DoOperation();     // examine parameters and process them 
			SetXOPType((long)TRANSIENT);// XOP has done its job, so discard it 
			break;
*/
		case FUNCTION:					    // our external function being invoked?
			result = DoFunction();
			break;
			
		case FUNCADDRS:
			result = RegisterFunction();
			break;


	}
	
	SetXOPResult( result );
}



HOST_IMPORT void  main( IORecHandle ioRecHandle )
//	This is the initial entry point at which the host application calls XOP.
//	The MessMage sent by the host must be INIT.
//	main() does any necessary initialization and then sets the XOPEntry field of the
//	  ioRecHandle to the address to be called for future MessMages.
{	
	#ifdef XOP_GLOBALS_ARE_A4_BASED
		#ifdef __MWERKS__
			// For CodeWarrior 68K XOPs.
			SetCurrentA4();							// Set up correct A4. This allows globals to work.
			SendXOPA4ToIgor(ioRecHandle, GetA4());	// And communicate it to Igor.
		#endif
	#endif
	
   LoadXOPSegs();										// für Funktionen

	XOPInit(ioRecHandle);							// do standard XOP initialization 
	SetXOPEntry(XOPEntry);							// set entry point for future calls 

	
	if (igorVersion < 200)              // für Funktionen
		SetXOPResult(REQUIRES_IGOR_200); // ..
	else                                // ..
		SetXOPResult(0L);

}

//////////////////////////////////////////////////////////////////


//#define   MAXSTRING    1000
//#define	 NO_INPUT_STRING            3 + FIRST_XOP_ERR


/////////////////////////////////////////////////////////////////////////////
// SOME  UTILTIES

/*
// WITHOUT MEMORY LOCKING.......
Handle IHC( Handle sIgor )
//Handle IgorHandleToCString( Handle sIgor )
//  converts Igor string handle to C style string
//  returns C string or 0 in case of error meaning NO_INPUT_STRING or NOMEM 
//! after being finished with the C string you MUST REMOVE it with  DisposeHandle( Cstring ); 
//? no memory locking implemented ( hState would have to be passed...and later resetted...) 
{
   // char buf[1000];
   Handle sCopy;
   int    len, err = 0;
 	if ( !sIgor )                         // error:  input string does not exist
		return 0;//NO_INPUT_STRING;        //         ..IGOR passed an empty string
   len = GetHandleSize( sIgor );         // length of passed IGOR string
   if ( !( sCopy = NewHandle( len + 1 )))// allocate space for copied string..
      return 0;//NOMEM
   memcpy( *sCopy, *sIgor, len ); // 031216  + 1);     // copy string and..
      *(*sCopy + len) = '\0';            // ..append string end
   // sprintf( buf, "IHC:  '%s' \r", *sCopy ); XOPNotice( buf );  
   DisposeHandle( sIgor );               // we need to get rid of the original Igor string
   return sCopy;
}
*/




// 041126
Handle	IHC( Handle sIgorString )
//  converts Igor string handle to C style string --- WITHOUT  memory locking
//  returns C string or 0 in case of error meaning NO_INPUT_STRING or NOMEM 
//! after being finished with the C string you MUST REMOVE it with  DisposeHandle( Cstring ); 
{ 
	int		len;
   Handle	pCStr;
 	if ( !sIgorString )								// error:  input string does not exist
	{
		XOPNotice( "***** Error: NULL string handle received in 'CStringHandle()' \r" );
		return	(Handle)0;//NO_INPUT_STRING;	//         ..IGOR passed an empty string or a NULL string
	}
	len	= GetHandleSize( sIgorString );		// length of string is just one too short for..
	if ( !( pCStr	= NewHandle(len + 1) ) )	// ..string end \0  so make longer new string..
	{
		XOPNotice( "***** Error: Not enough memory in 'CStringHandle()' \r" );
		return	(Handle)0;
	}
	memcpy( *pCStr, *sIgorString, len );		// ..fill with passed data..
   DisposeHandle( sIgorString );					// we need to get rid of the original Igor string
	*(*pCStr+len) = '\0';							// ..append string end
	return	pCStr;									// Return POINTER to 0-terminated C string
}


/*
// WITH MEMORY LOCKING.......
Handle IHC2( Handle sIgor, int *pHState )

//Handle IgorHandleToCString( Handle sIgor, ...
//  converts Igor string handle to C style string
//  returns C string or 0 in case of error meaning NO_INPUT_STRING or NOMEM 
//! after being finished with the C string you MUST REMOVE it with  DisposeHandle2( Cstring ); 
//! memory locking is implemented,  hState is passed...and later resetted...
{
   // char buf[1000];
   Handle sCopy;
   int    len, err = 0;
 	if ( !sIgor )									// error:  input string does not exist
		return 0;//NO_INPUT_STRING;			//         ..IGOR passed an empty string
   len = GetHandleSize( sIgor );				// length of passed IGOR string
   if ( !( sCopy = NewHandle( len + 1 )))	// allocate space for copied string..
      return 0;//NOMEM
   *pHState = MoveLockHandle( sCopy );
   memcpy( *sCopy, *sIgor, len ); // 031216  + 1);		// copy string and..
   *(*sCopy + len) = '\0';						// ..append string end
   // sprintf( buf, "IHC:  '%s' \r", *sCopy ); XOPNotice( buf );  
   DisposeHandle( sIgor );						// we need to get rid of the original Igor string
   return sCopy;
}

int IHCDisposeHandle2( Handle sCopy, int *pHState )
{
   HSetState( sCopy, *pHState );
   DisposeHandle( sCopy );               // we need to get rid of the C handle (= memory of C string)
   return 0;
}
*/

#pragma pack()    // All structures are 4-byte-aligned for MCTG.

