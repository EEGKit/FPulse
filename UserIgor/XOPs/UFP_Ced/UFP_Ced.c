//
//	UFP_Ced.c -- routines for CED1401 external functions
//


/* Revision History
	2007-02-23	Completely new
				Requires a common library UFBd_LibBd.
	
				Perhaps another solution is to use Igor6 conditional compile.
				Then the original XOP  UFP_Ced  containing the 3 now separated functions again could be used 
				and 'UFBd_Projects()' could be removed.

				As long as 'UFBd_Projects()' is used and if it proves to be OK
				the #if_defined _DEBUG  could be straightened out (simplified)

  2010-01-05	The Ced handle is stored in Igor and passed to all Xop functions
				rather than being a global variable within the Xop 
  2010-01-05	The Open/Close functions return proper error codes but do no longer print message text, this must be done in Igor
				New functions: UFP_CedStateOf1401 and UFP_CedGetErrorString
*/


// ANSI headers IgorXOP.h XOP.h XOPSupport.h
#include "C:\Program files\wavemetrics\IgorXOPs\XOPSupport\XOPStandardHeaders.h"
//#include "C:\Programme\wavemetrics\IgorXOPs\XOPSupport\XOPStandardHeaders.h"

#include "UFP_Ced.h"
#include "XopMain.h"				// for Trial time definitions and Trial time globals
#include "Use1401.h"				// for the CED1401


#pragma pack(2)					// All structures are 4-byte-aligned. // for MCTG 4 instead of 2


// Forward declarations
short		CEDCloseAndOpen(short OldHnd, short n1401 );
short		CEDClose(		short hnd );
int			CEDGetMemSize(	short hnd );
short		CEDLdErrOut(	short hnd, int ErrShow, LPSTR dir, LPSTR commands );

void		OutError(		short code, LPSTR sText, int ErrShow );  
void		DisplayError(	short code, LPSTR sText, LPSTR sOrg, int ErrShow );
void		OutCedErr(		short code, LPSTR sText );



// Global Variables (none) 

// Forward declarations of CED1401-XOP-Interface
int UFP_CedCloseAndOpen(			void * );  // dummy = 0
int UFP_CedClose(					void * );  // ErrShow
int UFP_CedState(					void * ); 
int UFP_CedStateOf1401(				void * ); 
int UFP_CedKillIO(					void * ); 
int UFP_CedReset(					void * );   
int UFP_CedDriverType(				void * );
int UFP_CedTypeOf(					void * );
int UFP_CedGetMemSize(				void * );
int UFP_CedLdErrOut(				void * );
int UFP_CedGetErrorString(			void * );

int UFP_CedSendString(				void * );
int UFP_CedGetResponse(				void * );
int UFP_CedGetResponseTwoIntAsStr(	void * );
int UFP_CedLastErrCode(				void * );  // MinKb, MaxKb, Printmode
int UFP_CedWorkingSet(				void * );  // prepares memory for Ced1401 and checks expired-global in FPulse
int UFP_CedSetTransferArea(			void * );  // hnd, nr, pts, RequestedMinPts, RequestedMaxPts, wave
int UFP_CedUnSetTransferArea(		void * );  // hnd, nr......wave


// SAME ORDER HERE IN  '(*sFunc[])' AND IN UFP_CedWinCustom.RC

FUNC sFunc[] =
  //  Der Name der      Direct Call method
  //  Funktion          or Message method	   Used that often
{
   { UFP_CedCloseAndOpen				}, 
   { UFP_CedClose						}, 
   { UFP_CedState						}, 
   { UFP_CedStateOf1401					}, 
   { UFP_CedKillIO						}, 
   { UFP_CedReset						}, 
   { UFP_CedDriverType					},	
   { UFP_CedTypeOf						},	
   { UFP_CedGetMemSize					},	
   { UFP_CedLdErrOut					}, 
   { UFP_CedGetErrorString				}, 

   { UFP_CedSendString					},  
   { UFP_CedGetResponse					},  
   { UFP_CedGetResponseTwoIntAsStr		},
   { UFP_CedLastErrCode					},
   { UFP_CedWorkingSet					},		
   { UFP_CedSetTransferArea				},
   { UFP_CedUnSetTransferArea			},


   {    NULL       }  // Endemarkierung
};




//===================================================================================================================


/* 2010-01-05 unused

int	UFP_CedOpen( struct { double HndReturn; } *p )
// parameter should be 0  (see prog int lib 3.20, dec 99, p.5)
// avoid or show IGORs error message box, show it only in case of error, do not show it when a pos. handle has been returned
{
	short		n1401	= 0;
   p->HndReturn = CEDOpen( n1401 ); 	// return 0 when OK or a negative error code
	return 0;
}

// Version1: open unconditionally
//
//	short	CEDOpen( short n1401 )
//	// n1401 should be 0  (see prog int lib 3.20, dec 99, p.5)
//	// returns negative error code or valid handle = 0 or or valid handle > 0 
//	// CAVE: When 'Open' 1401 has been 'Opened', then switched off and then on again it returns on first U14Open1401()...
//	// ..an erroneous positive handle (e.g.5) which can only be eliminated by 'Close1401' with last valid handle (almost always=0)
//	{
//		short hnd;
//		if ( ( hnd = U14Open1401( n1401 ) ) < 0 ) {	// do not show valid positive handles as errors 
//			OutCedErr( hnd, "CEDOpen" );
//			hnd = CED_NOT_OPEN;
//		} 
//		return hnd;
//	}


// Version2: if handle says 'Ced is open' then close and re-open

short	CEDOpen( short n1401 )
// n1401 should be 0  (see prog int lib 3.20, dec 99, p.5)
// returns negative error code or valid handle = 0 or or valid handle > 0 
// CAVE: When 'Open' 1401 has been 'Opened', then switched off and then on again it returns on first U14Open1401()...
// ..an erroneous positive handle (e.g.5) which can only be eliminated by 'Close1401' with last valid handle (almost always=0)
{
	int	ErrShow	= MSGLINE;
	// 1401 has been closed and is not open so try to open it now
	// SEE ABOVE: to cope with switching the 1401 on/off we close it first silently 
	if ( hnd >= 0 )
	{
		CEDClose( hnd, ErrShow );			// first close 1401 with current handle. As this can be the valid handle..
	}
	// now open the 1401
	if ( ( hnd = U14Open1401( n1401 ) ) < 0 ) {	// do not show valid positive handles as errors 
		OutCedErr( hnd, "CEDOpen" );
		hnd = CED_NOT_OPEN;
	} 
	return hnd;
}
*/


int	UFP_CedCloseAndOpen( struct { double OldHnd; double HndReturn; } *p )
// p->n1401 should be 0  (see prog int lib 3.20, dec 99, p.5)
// avoid or show IGORs error message box, show it only in case of error, do not show it when a pos. handle has been returned
{
	short	n1401	= 0;
    p->HndReturn = CEDCloseAndOpen( (short)p->OldHnd, n1401 ); 	// return 0 when OK or a negative error code
	// 2010-01-05
	//return 0;			// FPuls would have to process any errors
	return p->HndReturn;
}

short	CEDCloseAndOpen( short Hnd_, short n1401 )
// n1401 should be 0  (see prog int lib 3.20, dec 99, p.5)
// returns negative error code or valid handle = 0 or or valid handle > 0 
// CAVE: When 'Open' 1401 has been 'Opened', then switched off and then on again it returns on first U14Open1401()...
// ..an erroneous pos. handle (e.g.5) which can only be eliminated by 'Close1401' with last valid handle (almost always=0)
{
	char  bf[500], stateText[210];
	short state = 0;

	// 1401 has been closed and is not open so try to open it now
	// SEE ABOVE: to cope with switching the 1401 on/off we close it first silently 
	CEDClose( Hnd_ );		// first close 1401 with current handle. Can be the valid handle but also any invalid value..
	CEDClose( 0 );			// ..so we close the 1401 again with the handle = 0 which works almost always.

	// now open the 1401
	if ( ( Hnd_ = U14Open1401( n1401 ) ) < 0 ) {	// do not show valid pos. handles as errors 
		//OutError( Hnd_, "CEDOpen", MSGLINE );
		U14GetErrorString( Hnd_, stateText, 200 );
		Hnd_ = CED_NOT_OPEN;
		sprintf( bf, "\t\t\tUFP_CedCloseAndOpen: Ced cannot be opened,  hnd is set to: %d (=CED_NOT_OPEN) '%s'\r", Hnd_, state ? stateText : "" ); XOPNotice(bf);
	} 
	//else 
	//	 sprintf( bf, "\t\t\tUFP_CedCloseAndOpen: Ced has been opened with hnd: %d  \r", Hnd_ ); XOPNotice(bf);

	// SEE ABOVE: a positive handle is almost always an indicator for an error, so we take it as an error...
	// ..and return the CED_NOT_OPEN error indicator  as FPULS depends on this value 
	if ( Hnd_ > 0 )
		Hnd_ = CED_NOT_OPEN;
	//sprintf( bf, "\t\tUFP_CedCloseAndOpen: leaving with  hnd:%d \r", Hnd_ ); XOPNotice(bf);
	return Hnd_;
}


/* 2010-01-07
int	UFP_CedClose( struct { double ErrShow; double hnd; double IgorReturn; } *p )
// returns 0 when OK or returns neg. error code
{
	p->IgorReturn = CEDClose( (short)p->hnd, (int)p->ErrShow );		// return 0 when OK or a negative error code
	// 2010-01-05
	//return 0;			// FPuls would have to process any errors
	return ( (int)p->ErrShow & ERR_AUTO_IGOR ) ? p->IgorReturn : 0;	// 0 avoids,  != 0 shows IGORs error message box 
}

short	CEDClose( short hnd, int ErrShow )
// returns 0 when OK or returns neg. error code
{
    short code, state = 0;		
	char  bf[200], stateText[200];

	// if 1401 has not been closed it should be open, but it could have been switched off accidentally..
	if ( hnd >= 0 &&  ( ( state = U14StateOf1401( hnd ) ) == 0 ) ) {	//! order or evaluation avoids printing stateText
		code = U14Close1401( hnd );
		OutError( code, "CEDClose",  ErrShow );	
		if ( code < 0 ) {
			if ( ErrShow & MSGLINE ) {
				sprintf( bf, "\t\t\tUFP_CedClose: Ced was open with hnd:%d but cannot be closed  (error code:%d)....\r", hnd, code ); XOPNotice(bf);
			}
			code = CED_NOT_OPEN;
		} 
		else {
			code = CED_NOT_OPEN;
			if ( ErrShow & MSGLINE ) {
				sprintf( bf, "\t\t\tUFP_CedClose: Ced was open and has been closed  (hnd:%d -> %d )....\r", hnd, code ); XOPNotice(bf);
			}
		}		


	} else {
		code = CED_NOT_OPEN;
		if ( ErrShow & MSGLINE ) {
			U14GetErrorString( state, stateText, 400 );
			sprintf( bf, "\t\t\tUFP_CedClose: Ced was not open (hnd:%d -> %d) '%s' \r", hnd, code, state ? stateText : "" ); XOPNotice(bf);
		}
	}
	return code;
}
*/
int	UFP_CedClose( struct { double hnd; double IgorReturn; } *p )
// returns 0 when OK or returns neg. error code
{
	p->IgorReturn = CEDClose( (short)p->hnd );		// return 0 when OK or a negative error code
	return 0;			// FPuls must process any errors
}

short	CEDClose( short hnd )
// returns 0 when OK or returns neg. error code
{
    short code = U14ERR_BADHAND;	// we assume as failure an invalid handle, this is then modified by  U14StateOf1401  and  U14Close1401	

	// if 1401 has not been closed it should be open, but it could have been switched off accidentally..
	if ( hnd >= 0  &&  ( code = U14StateOf1401( hnd ) ) == 0 ) 
		code = U14Close1401( hnd );
	return code;
}



int	UFP_CedState( struct {  double hnd; double IgorReturn; } *p )
// returns 0 when Ced is open and OK   or   returns   -1 (=CED_NOT_OPEN) if Ced was closed or otherwise inactive
{
	short code	= CED_NOT_OPEN;
	short hnd	= (short)p->hnd;

	// if 1401 has not been closed it should be open, but it could have been switched off accidentally..
	if ( hnd >= 0 ) {						// Handle says Ced should currently be open...
		code = U14StateOf1401( hnd );		// code=0 means OK : handle is 'open' and state is 'open'
		if ( code != 0 ) {					// not OK: handle is 'open' but state does not confirm 'open', probably because CED has been switched off..
			//OutCedErr( code, "UFP_CedState.  The 1401 has been on, but now " );	// print message to alert the user about problem with Ced
			code = CED_NOT_OPEN;
		}
	}	
	p->IgorReturn = code; 					// return 0 when OK or a negative error code
	return code;							// in case of error -1  is returned which will trigger Igors error reporting
	//return 0;								// returning 0 will avoid Igors error reporting even if there were erros
}


int	UFP_CedStateOf1401( struct {  double hnd; double IgorReturn; } *p )
// returns 0 when Ced is open and OK   or   returns specific negative error code if Ced was closed or otherwise inactive
{
	p->IgorReturn = U14StateOf1401( (short)p->hnd ); // return 0 when OK or a negative error code
//	p->IgorReturn = ErrorNrCEDtoIGOR(U14StateOf1401( (short)p->hnd )); // return 0 when OK or a negative error code
//	short	code = U14StateOf1401( (short)p->hnd );  // return 0 when OK or a negative error code
//	p->IgorReturn = ErrorNrCEDtoIGOR(code); // return 0 when OK or a negative error code
//	p->IgorReturn = code; // return 0 when OK or a negative error code
	
	// SAMPLE CODE 2010-01-07
	//OutError(	code, "CEDStateOf1401 code ERR_FROM_CED",  ERR_FROM_CED+ERRLINE );					//	OK:		ERR_FROM_CED: len:61 code:-510 'The application supplied an incorrect 1401 handle (code -510)' 	
	//OutError(	code, "CEDStateOf1401 code ERR_FROM_IGOR", ERR_FROM_IGOR+ERRLINE );					//	wrong:	ERR_FROM_IGOR:len:45 code:-510 'XOP is incompatible with this version of Igor' 
	//OutError(	code, "CEDStateOf1401 code ERR_AUTO_IGOR", ERR_AUTO_IGOR+ERRLINE );					//  wrong:	ERR_AUTO_IGOR:len:45 code:-510 'XOP is incompatible with this version of Igor' 
	//OutError(	ErrorNrCEDtoIGOR(code),"CEDStateOf1401 conv ERR_FROM_CED",  ERR_FROM_CED+ERRLINE );	//	wrong:	ERR_FROM_CED: len:50 code: 110 '1401 error code 110 returned; this code is unknown' 	
	//OutError(	ErrorNrCEDtoIGOR(code),"CEDStateOf1401 conv ERR_FROM_IGOR", ERR_FROM_IGOR+ERRLINE);	//	halfOK:	ERR_FROM_IGOR:len:19 code: 110 'system error #-510.' 	
	//OutError(	ErrorNrCEDtoIGOR(code),"CEDStateOf1401 conv ERR_AUTO_IGOR", ERR_AUTO_IGOR+ERRLINE);	//	halfOK:	ERR_AUTO_IGOR:len:19 code: 110 'system error #-510.' 

//	return ( code );				// in case of error a negative error code is returned which will trigger Igors error reporting
	return 0;						// returning 0 will avoid Igors error reporting even if there were erros
}


int	UFP_CedKillIO( struct { double hnd; double IgorReturn; } *p )
// only flushes IO buffers but does no selftest (like Reset does)
{
	p->IgorReturn = U14KillIO1401( (short)p->hnd );				// return 0 when OK or a negative error code
	return 0;
}


int	UFP_CedReset( struct { double hnd; double IgorReturn; } *p )
{
	p->IgorReturn = U14Reset1401( (short)p->hnd );				// return 0 when OK or a negative error code
	return 0;
}


int	UFP_CedDriverType(  struct { double drivertype; } *p )	
//	Returns driver type of Ced
{
	p->drivertype = (double)U14DriverType();
	return 0;
}


int  UFP_CedTypeOf(  struct { double hnd; double type; } *p )	
//	Returns type of Ced if everything allright or negative error code otherwise.
{
	p->type = (double)U14TypeOf1401( (short)p->hnd );
	return 0;
}


int	UFP_CedGetMemSize( struct { double hnd; double nSizeOrError; } *p )
{
    p->nSizeOrError = CEDGetMemSize((short)p->hnd );
	return 0;                   
}

int	CEDGetMemSize( short hnd )
// Returns CED memory size in Bytes or negative error code. No message in case 1401 is not open
{
	long  nSize = 0 ;				// return zero when 1401 is not open
	long  FAR* lpSize = &nSize;
	int	  errCode	= U14GetUserMemorySize( hnd, lpSize );
	return errCode != 0  ?  errCode  :  nSize;		// returns negative error code   or  positive memory size
}



int UFP_CedLdErrOut( struct { Handle CmdStr; Handle DirStr; double ErrShow; double hnd; double res; } *p )
// loads external CED commands and possibly prints error message
{
   Handle    CmdStrH, DirStrH;
	int       err = 0;//lenC, lenD, err = 0;
	
   if ( !p->CmdStr )                        // error:  input string does not exist
		err = NO_INPUT_STRING;
   else 
   {
      DirStrH = IHC( p->DirStr);
      CmdStrH = IHC( p->CmdStr);
		// XOPNotice("LdErrOut a:  Dir:'"); XOPNotice( *DirStrH );  XOPNotice( "'    Cmd:'" ); XOPNotice( *CmdStrH ); XOPNotice( "'\r" );
   	  p->res = CEDLdErrOut( (short)p->hnd, (int)p->ErrShow, *DirStrH, *CmdStrH );
		// XOPNotice("LdErrOut b:  Dir:'"); XOPNotice( *DirStrH );  XOPNotice( "'    Cmd:'" ); XOPNotice( *CmdStrH ); XOPNotice( "'\r" );
      DisposeHandleIHC(CmdStrH);               // we need to get rid of ..
      DisposeHandleIHC(DirStrH);               // we need to get rid of ..
      //p->res = 0.;
   }
   return err;                              // 0 = OK, sonst XFunc error code 
}

short CEDLdErrOut( short hnd, int ErrShow, LPSTR dir, LPSTR commands )
{
	long  lCode;
	short code;
	char  bf[300];
	if ( hnd >= 0 ) {
		if ( ErrShow & MSGLINE )
		{
			sprintf( bf, "\t\t\tCed UFP_CedLdErrOut()  hnd:%d  dir:'%s'  commands:'%s' \r", hnd, dir, commands );
			XOPNotice( bf );
		}
		lCode = U14Ld( hnd, dir, commands );								// Load commands
		if ( (code = (short)( lCode & 0xffff) ) != U14ERR_NOERROR )	// Get error code: low word is error 
		{
		   int nCmd = (short)( lCode >> 16 );								// Hi word is index of failed cmd
		   sprintf( bf, "++++Error: Loading the %d. command of  '%s'  from  '%s'  failed. 'U14Ld() returns error %d / %d / 0x%08x \r", nCmd, commands, dir, code, lCode & 0x00ff, lCode );
			XOPNotice( bf );
			OutCedErr( code, "U14Ld()" );					// optionally translate the errorcode into an informational string and print it.
			return code;
	   }
   }
   return 0;
}


// LOAD SINGLE COMMANDS : TEST because UFP_CedLdErrOut() FAILS SOMETIMES FOR UNKNOWN REASONS 
// DRAWBACK : directory cannot be specified (looks on current drive....)


int	UFP_CedGetErrorString( struct { double code; Handle sRes; } *p )
// returns human-readable error string when error code is passed
{
	char	errBuf[100];
	char	errString[410];
	int		outlen, err = 0;
	Handle  sOut	= NIL;						

	U14GetErrorString( (short)p->code, errString, 400 );
	outlen	= strlen( errString );

	if (( sOut = NewHandle(outlen)) == NIL )// get output handle , do NOT provide space for '\0' 
	{
		sprintf( errBuf, "++++Error: UFP_CedGetErrorString() Not enough memory. Aborted...\r");
		XOPNotice( errBuf );
		err = NOMEM;						// out of memory
	}
	else                                    // string length is OK so return string 
		memcpy( *sOut, errString, outlen );		// copy local temporary buffer WITHOUT \0 to persistent Igor output string 
 
	p->sRes = sOut;
	return err;								// 0 = OK, sonst XFunc error code 
}









int   CountSepsInList( char *sString, char *sSep );
char *StringFromList( int index, char *sString, char *sSep );



int	UFP_CedSendString( struct { Handle str;  double hnd; double res; } *p )
// sends a command string to the CED
{
	Handle   str1;
	int      err = 0;
	short	hnd	= (short)p->hnd;
	
	if ( !p->str )                    // error:  input string does not exist
		err = NO_INPUT_STRING;
	else 
	{
		str1 = IHC( p->str );
		if ( hnd >= 0 )
			U14SendString( hnd, *str1 );
	
		DisposeHandleIHC(str1);          // we need to get rid of ..

		p->res = 0.;
	}
	return err;                   // 0 = OK, sonst XFunc error code 
}


int CEDGetResponse( short hnd, LPSTR command, LPSTR text, int ErrMode )
// for CED commands which return 1 integer
// as this function is used in IGOR background task functions, we cannot wait for a response but ..  
// must return immediately (with value 0xcccccccc) if CED did not respond
{
   char	bf[256];    //031205 ?????  260 will make U14GetString() fail with error code -524 : string longer than buffer...
   char	errBuf[400];
	int	nResponse = 0xcccccccc; // 100102 in IGOR: 'hexCCCCCCCC'= 858993460 (is also compiler default anyway)
   int   code = 0;
 	if ( hnd >= 0 )
	{
		if ( ( code = U14SendString( hnd, command ) ) == 0 )
		{
		   if ( ErrMode & MSGLINE )
			{
				sprintf( errBuf, "\t\t\tCEDGetResponse(%s)  after sending command:'%s'. Waiting lines: %d, chars: %d \r", text, command, U14LineCount(hnd), U14CharCount(hnd) ); XOPNotice( errBuf );
			}
			if ( ( code = U14GetString( hnd, bf, sizeof(bf)-2 ) ) == 0 )
			{
				return( atoi( bf ) ) ; // scanf( bf, "%d", &nResponse );
			}
			else
			{
				sprintf( errBuf, "++++Error: CEDGetResponse(%s)  U14GetString() failed with error code:%d after sending command:'%s' . Returning %d (=0x%08x) \r", text, code, command, nResponse, nResponse ); XOPNotice( errBuf );
			}
		}
		else
		{
			sprintf( errBuf, "++++Error: CEDGetResponse(%s)  U14SendString( hnd:%d, command:'%s' ) failed with error code:%d . Returning %d (=0x%08x) \r", text, hnd, command, code, nResponse, nResponse ); XOPNotice( errBuf );
		}
	}
	else
	{
		sprintf( errBuf, "++++Error: CEDGetResponse(%s)  failed (invalid CED handle:%d )  command:'%s'. Returning %d (=0x%08x) \r", text, hnd, command, nResponse, nResponse ); XOPNotice( errBuf );
	}
   return nResponse;
}

int	UFP_CedGetResponse( struct { double errMode; Handle sTxt; Handle sCmd; double hnd; double res; } *p )
{
   Handle	sTxt = IHC( p->sTxt );
   Handle	sCmd = IHC( p->sCmd );

	p->res = CEDGetResponse( (short)p->hnd, *sCmd, *sTxt, (int)p->errMode );

	DisposeHandleIHC(sTxt);									// we need to get rid of ..
	DisposeHandleIHC(sCmd);									// we need to get rid of ..
   return 0;												// 0 = OK, sonst XFunc error code 
}



int	UFP_CedGetResponseTwoIntAsStr( struct { Handle sCmd; double hnd; Handle sRes; } *p )
// expects 2 integers as a response to 'instr' (e.g.'ERR;') from  the CED, returns these 2 integers as a string 
{
	short	sendErr, hnd	= (short)p->hnd;
	int		err		= 0;
	int		outlen;
	Handle   sOut		= NIL;						
    Handle	sCmd		= IHC( p->sCmd );
	if ( hnd >= 0 )
	{
		if ( ( sendErr = U14SendString( hnd, *sCmd ) ) == 0 )
		{
			long	LongVal[2];
			char	errbuf[200];
			char	tmp[100];
			if ( ( sendErr = U14LongsFrom1401( hnd, LongVal, 2 ) ) == 2 )// we expect 2 numbers
			{
				sprintf( tmp, "%d %d", LongVal[0], LongVal[1] );
				//XOPNotice(tmp);
				outlen = strlen( tmp );
			   if (( sOut = NewHandle(outlen)) == NIL )// get output handle , do NOT provide space for '\0' 
				{
					sprintf( errbuf, "++++Error: UFP_CedGetResponseTwoIntAsStr() Not enough memory. Aborted...\r");
			      XOPNotice( errbuf );
					err = NOMEM;				             // out of memory
				}
				else                                    // string length is OK so return string 
					memcpy( *sOut, tmp, outlen );			 // copy local temporary buffer WITHOUT \0 to persistent Igor output string 
 
			}
		}
	}
	p->sRes = sOut;
	DisposeHandleIHC(sCmd);					// we need to get rid of ..
	return err;								// 0 = OK, sonst XFunc error code 
}



int UFP_CedLastErrCode( struct { Handle sText; double hnd; double res; } *p )
// prints informational string for errCode
{
	short		errCode;
	short		hnd = (short)p->hnd;
	if ( hnd >= 0 )
	{
		if ( 	errCode	= U14LastErrCode( hnd ) )
		{
		   Handle	sText = IHC( p->sText );
			OutCedErr( errCode, *sText );

			DisposeHandleIHC(sText);					// we need to get rid of ..
		}
	}
	p->res	= (double)errCode;	
	return 0;	
}


/////////////////////////////////////////////////////////////////
//  LITTLE  HELPERS


void OutCedErr( short code, LPSTR sText )
{
	OutError( code, sText, ERRLINE + ERRBOX + ERR_FROM_CED );  
}

void	OutError( short code, LPSTR sText, int ErrShow )  
// get an error string from a CED error code: either directly or over IGOR (see below)..
// ..and show the error in a line in IGORs command window  or stop program execution by displaying an error box 
{
	char sOrg[410];
	char sTxT[500];
	if ( code ) {
		if ( ErrShow & ERR_AUTO_IGOR ) { 
			// applicable when code is defined in xxxWinCustom.RC
			// take strings from the resource xxWinCustom.RC / UFP_CedError.H : can be a mixture of own and CED error strings
			// more flexible, but must be properly constructed: CED strings must be copied and converted from e.g. USE1401.H
			GetIgorErrorMessage( ErrorNrCEDtoIGOR(code), sOrg );	//SEE XOPENTRY()........
			// test 2010-01-07
			// sprintf( sTxT, "ERR_AUTO_IGOR: len:%2d code:%4d  '%s' \r", strlen( sOrg ), code, sOrg ); XOPNotice( sTxT );
			DisplayError( code, sText, sOrg, ERRLINE ); // print additional line when displaying IGORs automatic error box 
		}
		else {		
			if ( ErrShow & ERR_FROM_CED ) {
				// applicable for all Ced functions U14xxxx
				// take error strings from U14GetErrorString() : easy but ONLY CED error strings are possible
				U14GetErrorString( code, sOrg, 400 );
				// test 2010-01-07
				// sprintf( sTxT, "ERR_FROM_CED:  len:%2d  code:%4d '%s' \r", strlen( sOrg ), code,  sOrg ); XOPNotice( sTxT );
				DisplayError( code, sText, sOrg, ErrShow ); // print  line  or  box and line 
			}
			if ( ErrShow & ERR_FROM_IGOR ) { 
				// take strings from the resource xxWinCustom.RC / UFP_CedError.H : can be a mixture of own and CED error strings
				// more flexible, but must be properly constructed: CED strings must be copied and converted from e.g. USE1401.H
				GetIgorErrorMessage( ErrorNrCEDtoIGOR(code), sOrg );	//SEE XOPENTRY()........
				// test 2010-01-07
				// sprintf( sTxT, "ERR_FROM_IGOR: len:%2d  code:%4d '%s' \r", strlen( sOrg ), code, sOrg ); XOPNotice( sTxT );
				DisplayError( code, sText, sOrg, ErrShow ); // print  line  or  box and line 
			}
		}
	}
}


void DisplayError( short code, LPSTR sText, LPSTR sOrg, int ErrShow )  
{
	char sOut[410];
	if ( (ErrShow & ERRLINE) || (ErrShow & ERRBOX) ) {	// when showing error box, always show line also
		sprintf( sOut, "++++Error while executing '%s':  %s (%d)\r", sText, sOrg, code );
		XOPNotice( sOut );
	}
	if ( ErrShow & ERRBOX ) {
		sprintf( sOut, "Error while executing '%s':\r\r%s ", sText, sOrg );
		XOPOKAlert( "Error", sOut );
	}
}


//============================================================================================================================

// 2004-02-24 Tim Bergels recommendations:
// It looks as if the changes to Use1432 are OK, so I am sending you the new library to try out. The new function added is defined as:

	 U14API(short) U14WorkingSet(DWORD dwMinKb, DWORD dwMaxKb); // define here or in USE1401.H . Tim Bergel suggested values 800 and 4000

// it returns zero if all went well, otherwise an error code (currently a positive value unlike other functions). 
// To use it, you should call it once only at the start of your application - I'm not sure how that will apply to you. 
// I suggest using values of 800 and 4000 for the two memory size values, they are known to work fine with CED software.
// Best wishes, Tim Bergel


int UFP_CedWorkingSet( struct {  double bMode; double MaxKb;  double MinKb; double res; }* p)
// Igor wrapper for Tim Bergels (CED) version to adjust the working set size of Win2000, NT, XP
// Needed for U14Ld() to succeed which fails without a previous call to this function if very larges waves (~100MB) have been defined before by Igor.
// Needed also for transfer areas > 64KB up to 1MB (test with scripts CCVIGN_MB.txt(456.3s, 18252kpts) and Spk50Hz_Gs.txt )
// The Windows documentation warns to set these values too high as this would decrease the overall..
// ..performance of the system but the example dates to 95..97 with an increase to 4MB on a 16MB system.
// FOR INCREASING THE ProcessWorkingSetSize TO WORK YOU MUST HAVE ADMINISTRATOR RIGHTS!
{
   int   nMinKb					= (int)p->MinKb;
   int   nMaxKb					= (int)p->MaxKb;
	int	bMode						= (int)p->bMode; 
   int   errCode, WinVersion;
   char  sMsg[200];

	if ( errCode = U14WorkingSet( nMinKb, nMaxKb ) ) {		// Tim Bergel suggested values min:800Kb and max:4000kB
			sprintf( sMsg, "++++Error: U14WorkingSet( min: %ld Kb , max: %ld Kb ) failed with error %d \r", nMinKb, nMaxKb, errCode );
			XOPNotice( sMsg );
	}	
	if ( bMode ) {
			sprintf( sMsg, "\t\t\tU14WorkingSet( min: %ld Kb , max: %ld Kb ) returned code %d \r", nMinKb, nMaxKb, errCode );
			XOPNotice( sMsg );
	}	
   p->res = (double)errCode;
   return 0;
}


int   ghState;      //is the wave  'wRaw' locked or unlocked

int UFP_CedSetTransferArea( struct {  double ErrMode; waveHndl wRaw; double pts; double nr; double hnd; double res; }* p)
// locks the memory area used for the transfers between CED and computer
// for transfer areas > 64KB up to 1MB 
{
	short hnd		= (short)p->hnd;
	int   nr		= (int)p->nr;       // area nr must be 0 (although CED manual says in the range 0..7)
	int   nBytes	= (int)p->pts * 2;
	int	ErrMode		= (int)p->ErrMode; 
	void *Raw		= NULL;
	char  bf[200];
	int   errCode;
  
	//DebugPrintWaveProperties( "UFP_CedSetTransferArea", p->wRaw ); 	// 050128

	// 050602 for Win2000   
	// char	sWinNr[4][20] =  { "Win:unknown?",	"Win3.x",  "Win9x",	"Win NT/2000/XP" }; // = WinVersion -2, -1, 0 , 1 
	// int Result, MinWorkSetSize, MaxWorkSetSize, NewMinWorkSetSize, NewMaxWorkSetSize;                
	// int RequestedMinWorkSetSize, RequestedMaxWorkSetSize, WinVersion;

	if ( p->wRaw == NIL )                  // check if wave handle is valid
   {
		SetNaN64( &p->res );			         // return NaN if wave is not valid   
		return( NON_EXISTENT_WAVE );
	}
 	if ( WaveType(p->wRaw) != NT_I16 )		// check wave's numeric type  
   {
  	   SetNaN64( &p->res );				      // return NaN if wave is not 2Byte int
		return( IS_NOT_2BYTE_INT_WAVE );
	}

	ghState	= MoveLockHandle( p->wRaw );	// Lock wave handle in heap after moving it to the top so that fragmentation is avoided

   Raw		= WaveData( p->wRaw );			// char pointer to IGOR wave data 
	
	if ( errCode = U14SetTransArea( hnd, nr, Raw, nBytes, 0 ) ) {
	   sprintf( bf,"U14SetTransferArea( hnd:%d  nr:%d  Raw Adr:%p Bytes:%d )", hnd, nr, Raw, nBytes ); 
      OutCedErr( errCode, bf );
 	}
   
   if ( ErrMode & MSGLINE ){
	   sprintf( bf,"\t\t\tCed UFP_CedSetTransferArea \thnd:%d  nr:%d  h:%p  p:%p  Adr:%p byt:%d=0x%x  stat:%d  code:%d \r",
		              hnd, nr, p->wRaw, *p->wRaw, Raw, nBytes, nBytes, ghState, errCode ); 
		XOPNotice( bf );
	}
		
   p->res = (double)errCode;
   return 0;
}


int UFP_CedUnSetTransferArea( struct {  double ErrMode; waveHndl wRaw; double nr; double hnd; double res; }* p)
// unlocks the memory used for the transfers between CED and computer
{
   short hnd	 = (short)p->hnd;
   int   nr      = (int)p->nr;       // area nr must be 0 (although CED manual says in the range 0..7)
   int   ErrMode = (int)p->ErrMode; 
   char  bf[200];
   int   errCode;

	// DebugPrintWaveProperties( "UFP_CedUnSetTransferArea", p->wRaw ); 	// 050128

	// 031210   error -528 (Transfer area has not been set up) is NOT regarded as an error	
 	errCode = U14UnSetTransfer( hnd, nr );
	if ( errCode != 0  &&  errCode != -528 )// 031210   error -528 (Transfer area has not been set up) is NOT regarded as an error	
	{
	   sprintf( bf,"U14UnSetTransfer( hnd:%d  nr:%d )", hnd, nr ); 
      OutCedErr( errCode, bf );
	}
	
	if ( errCode == 0 )
		HSetState( p->wRaw, ghState );				// let IGOR unlock wRaw 
	
   
   if ( ErrMode & MSGLINE )
   {
      sprintf( bf,"\t\t\tCed UFP_CedUnSetTransfer  \thnd:%d  nr:%d  h:%p  p:%p  stat:%d  code:%d\r", 
														        hnd, nr, p->wRaw, *p->wRaw, ghState, errCode ); 
      XOPNotice( bf );
   }
   p->res = (double)errCode;

// error -528 (Transfer area has not been set up) is regarded as an error	
/*  
	if ( errCode = U14UnSetTransfer( hnd, nr ) ) 
	{
	   sprintf( bf,"U14UnSetTransfer( hnd:%d  nr:%d )", hnd, nr ); 
      OutCedErr( errCode, bf );
	}

	HSetState( p->wRaw, ghState );					// let IGOR unlock wRaw
   
   if ( ErrMode & MSGLINE )
   {
      sprintf( bf,"\t\t\tCed UFP_CedUnSetTransfer    hnd:%d  nr:%d  h:%p  p:%p  stat:%d  code:%d\r", 
														        hnd, nr, p->wRaw, *p->wRaw, ghState, errCode ); 
      XOPNotice( bf );
   }
   p->res = (double)errCode;
*/
   return 0;
}



#pragma pack()    // All structures are 2-byte-aligned.


