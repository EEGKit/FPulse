//
//	FPulseCed.c -- routines for CED1401 external functions
//
//	The syntax for CED1401 FUNCTIONS  is:
//    FuncSqrRootMessage( number )

// 2010-01-05...2010-02-03	
// 2010-01-05	The Ced handle is stored in Igor and passed to all Xop functions
//				rather than being a global variable within the Xop 
//  2010-01-05	The Open/Close functions return proper error codes but do no longer print message text, this must be done in Igor
//				New functions xCedGetErrorString



// ANSI headers IgorXOP.h XOP.h XOPSupport.h
#include <XOPStandardHeaders.h>

#include "FPulseCed.h"
#include "XopMain.h"
#include "Use1401.h"				// for the CED1401


#pragma pack(2)					// All structures are 4-byte-aligned. // for MCTG 4 instead of 2

/*
#define CFG "hj"
#ifdef MY
#endif
*/

// Forward declarations
//short		CEDOpen(		 );
short		CEDCloseAndOpen(	short OldHnd, short n1401 );
short		CEDClose(			short hnd );
int			CEDGetMemSize(		short hnd );
short		CEDLdErrOut(		short hnd, int ErrShow, LPSTR dir, LPSTR commands );

short		CEDSendStringErrOut(short hnd,int ErrShow, LPSTR str );

void		OutError(		short code, LPSTR sText, int ErrShow );  
void		DisplayError(	short code, LPSTR sText, LPSTR sOrg, int ErrShow );
void		OutCedErr(		short code, LPSTR sText );

 


// Global Variables (none) 

// Forward declarations of CED1401-XOP-Interface
//2021-03-22#if _DEBUG
int xUtilGetSystemDirectory(	void * );  //
//2021-03-22#endif

// 2010-01-05 unused
// int xCedOpen(					void * );  // dummy = 0
int xCedCloseAndOpen(			void * );  // dummy = 0
int xCedClose(					void * );  // ErrShow
int xCedState(					void * ); 
int xCedStateOf1401(			void * ); 
int xCedKillIO(					void * ); 
int xCedReset(					void * );   
int xCedDriverType(				void * );
int xCedTypeOf(					void * );
int xCedGetMemSize(				void * );
int xCedLdErrOut(				void * );
int xCedGetErrorString(			void * );

int xCedSendString(				void * );
int xCedSendStringErrOut(		void * );
int xCedGetResponse(			void * );
int xCedGetResponseTwoIntAsString(void * );
int xCedLastErrCode(			void * );  // MinKb, MaxKb, Printmode
int xCedWorkingSet(				void * );  // prepares memory for Ced1401 and checks expired-global in FPulse
int xCedSetTransferArea(		void * );  // hnd, nr, pts, RequestedMinPts, RequestedMaxPts, wave
int xCedUnSetTransferArea(		void * );  // hnd, nr......wave

int xUtilConvolve(				void * );  // 
int xUtilWaveCopy(				void * );  // 
int xUtilWaveExtract(			void * );  // 
int xUtilRealWaveSet(			void * );  // 
int xUtilFileDialog(			void * );  // 
int xUtilMemoryLoad(			void * );  //
int xUtilTotalPhys(				void * );  //
int xUtilAvailPhys(				void * );  //
int xUtilTotalVirtual(			void * );  //
int xUtilAvailVirtual(			void * );  //
int xUtilContiguousMemory(		void * );  //
int xUtilHeapCompact(			void * );  //

/////////////////////////////////////////////////////////////////////////////////////////
// START OF CFS INTERFACE  (in FPulseCfs.C)
int xCfsCreateFile(			void * );  // double Channels; double BlockSize; Handle Comment; Handle FName; Handle sRes; }* p)
int xCfsOpenFile(			void * );  // ...Handle FName; Handle sRes; }* p)
int xCfsCloseFile(			void * );  // double hnd;    Handle sRes; }* p)
int xCfsCommitFile(			void * );  // double hnd;    Handle sRes; }* p)
int xCfsGetGenInfo(        void * );  // ...
int xCfsGetFileInfo(       void * );  // ...
int xCfsGetFileChan(       void * );  // ...
int xCfsSetFileChan(       void * );  // double Other;  double Spacing;     double DataKind; double DataType; Handle xUnits; 
int xCfsSetDSChan(         void * );  // double xOffset;     double xScale;      double yOffset; double yScale; double Points;
int xCfsGetDSChan(         void * );  // ....
int xCfsGetChanData(       void * );  // ....
int xCfsInsertDS(          void * );  // double FlagSet; double DataSection; double hnd;    Handle sRes; }* p)
int xCfsWriteData(         void * );  // double xOffset;     double xScale;      double yOffset; double yScale; double Points;
int xCfsReadData(          void * );  // double xOffset;     double xScale;      double yOffset; double yScale; double Points;
int xCfsSetVarVal(         void * );  // double xOffset;     double xScale;      double yOffset; double yScale; double Points;
int xCfsGetVarVal(         void * );  // double xOffset;     double xScale;      double yOffset; double yScale; double Points;
int xCfsGetVarType(        void * );  // double xOffset;     double xScale;      double yOffset; double yScale; double Points;
int xCfsGetVarDesc(        void * );  // double xOffset;     double xScale;      double yOffset; double yScale; double Points;
int xCfsSetDescriptor(		void * );  // nType, nChans, FiveElements, //...int maxDSVar, int maxFileVar
// END   OF CFS INTERFACE
/////////////////////////////////////////////////////////////////////////////////////////

// SAME ORDER HERE IN  '(*sFunc[])' AND IN FPulseCedWinCustom.RC

FUNC sFunc[] =
  //  Der Name der      Direct Call method
  //  Funktion          or Message method	   Used that often
{
	{ xUtilGetSystemDirectory		},

	// 2010-01-05 unused
//	{ xCedOpen						}, 
   { xCedCloseAndOpen			    }, 
   { xCedClose						}, 
   { xCedState						}, 
   { xCedStateOf1401				}, 
   { xCedKillIO					    }, 
	{ xCedReset						}, 
   { xCedDriverType				    },	
   { xCedTypeOf					    },	
   { xCedGetMemSize				    },	
   { xCedLdErrOut					}, 
   { xCedGetErrorString				}, 

   { xCedSendString				    },  
   { xCedSendStringErrOut		    },  
   { xCedGetResponse				},  
   { xCedGetResponseTwoIntAsString},
   { xCedLastErrCode				},
   { xCedWorkingSet				    },		
   { xCedSetTransferArea		    },
   { xCedUnSetTransferArea			},

// Utilities
	{ xUtilConvolve					},
	{ xUtilWaveCopy					},
	{ xUtilWaveExtract				},
	{ xUtilRealWaveSet				},
	{ xUtilFileDialog				},
	{ xUtilMemoryLoad				},		
	{ xUtilTotalPhys				},		
	{ xUtilAvailPhys				},		
	{ xUtilTotalVirtual				},		
	{ xUtilAvailVirtual				},		
	{ xUtilContiguousMemory			},		
	{ xUtilHeapCompact				},

/////////////////////////////////////////////////////////////////////////////////////////
// START OF CFS INTERFACE  (in FPulseCfs.C)
   { xCfsCreateFile					},   
   { xCfsOpenFile						},   
   { xCfsCloseFile					},   
   { xCfsCommitFile					},
   { xCfsGetGenInfo					},   
   { xCfsGetFileInfo					},   
   { xCfsGetFileChan					},   
   { xCfsSetFileChan					},   
   { xCfsSetDSChan					},   
   { xCfsGetDSChan					},   
   { xCfsGetChanData					},   
   { xCfsInsertDS						},   
   { xCfsWriteData					},   
	{ xCfsReadData						},   
	{ xCfsSetVarVal					},   
	{ xCfsGetVarVal					},   
	{ xCfsGetVarType					},   
	{ xCfsGetVarDesc					},   
	{ xCfsSetDescriptor				},
// END   OF CFS INTERFACE

/////////////////////////////////////////////////////////////////////////////////////////

   {    NULL       }  // Endemarkierung
};

////////////////////////////////////////////////////////////////////////



int	xCedCloseAndOpen( void *ptr )
// p->n1401 should be 0  (see prog int lib 3.20, dec 99, p.5)
// avoid or show IGORs error message box, show it only in case of error, do not show it when a pos. handle has been returned
{
	struct { double OldHnd; double HndReturn; } *p = ptr;
	short		n1401	= 0;
	p->HndReturn = CEDCloseAndOpen( (short)p->OldHnd, n1401 ); 	// return 0 when OK or a negative error code
	// 2010-01-05
	// return ( ((int)p->ErrShow & ERR_AUTO_IGOR) && (int)p->HndReturn<0 ) ? (int)p->HndReturn : 0;
	// return 0;			// FPuls would have to process any errors
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
		//OutError( Hnd_, "CEDOpen", ErrShow );
		U14GetErrorString( Hnd_, stateText, 200 );
		Hnd_ = CED_NOT_OPEN;
		sprintf_s( bf, 500, "\t\t\txCedCloseAndOpen: Ced cannot be opened,  hnd is set to: %d (=CED_NOT_OPEN) '%s'\r", Hnd_, state ? stateText : "" ); XOPNotice(bf);
	} 
	//else 
	//	sprintf( bf, "\t\t\txCedCloseAndOpen: Ced has been opened with hnd: %d  \r", hnd ); XOPNotice(bf);

	// SEE ABOVE: a positive handle is almost always an indicator for an error, so we take it as an error...
	// ..and return the CED_NOT_OPEN error indicator  as PULSETRN depends on this value 
	if ( Hnd_ > 0 )
		Hnd_ = CED_NOT_OPEN;
	//sprintf( bf, "\t\txCedCloseAndOpen: leaving with  hnd:%d \r", Hnd_); XOPNotice(bf);
	return Hnd_;
}



int	xCedClose(void *ptr)
// returns 0 when OK or returns neg. error code
{
	struct { double hnd; double IgorReturn; } *p = ptr;
	p->IgorReturn = CEDClose( (short)p->hnd );			// return 0 when OK or a negative error code
	//return ( (int)p->ErrShow & ERR_AUTO_IGOR ) ? p->IgorReturn : 0;	// 0 avoids,  != 0 shows IGORs error message box 
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


int	xCedState( void *ptr )
// returns 0 when Ced is open and OK   or   returns   -1 (=CED_NOT_OPEN) if Ced was closed or otherwise inactive
{
	struct { double hnd; double IgorReturn; } *p = ptr;
	short code	= CED_NOT_OPEN;
	short hnd	= (short)p->hnd;

	// if 1401 has not been closed it should be open, but it could have been switched off accidentally..
	if ( hnd >= 0 ) {						// Handle says Ced should currently be open...
		code = U14StateOf1401( hnd );		// code=0 means OK : handle is 'open' and state is 'open'
		if ( code != 0 ) {					// not OK: handle is 'open' but state does not confirm 'open', probably because CED has been switched off..
			OutCedErr( code, "xCedState.  The 1401 has been on, but now " );	// print message to alert the user about problem with Ced
			code = CED_NOT_OPEN;
		}
	}	
	p->IgorReturn = code; 					// return 0 when OK or a negative error code
	return code;							// in case of error -1 is returned which will trigger Igors error reporting
	//return 0;								// returning 0 will avoid Igors error reporting even if there were erros
}


int	xCedStateOf1401( void *ptr )
// returns 0 when Ced is open and OK   or   returns specific negative error code if Ced was closed or otherwise inactive
{
	struct {  double hnd; double IgorReturn; } *p = ptr;
	p->IgorReturn = U14StateOf1401( (short)p->hnd );// return 0 when OK or a negative error code
	return 0;								// returning 0 will avoid Igors error reporting even if there were erros
	//return ( p->IgorReturn );				// in case of error a negative error code is returned which will trigger Igors error reporting
}


// 2010-02-03
int	xCedKillIO( void *ptr )
{
	struct {  double hnd; double IgorReturn; } *p = ptr;
	p->IgorReturn = U14KillIO1401( (short)p->hnd );				// return 0 when OK or a negative error code
	return 0;
}


// 2010-02-03
int	xCedReset( void *ptr )
{
	struct { double hnd; double IgorReturn; } *p = ptr;
	p->IgorReturn = U14Reset1401( (short)p->hnd );				// return 0 when OK or a negative error code
	return 0;
}



int	xCedDriverType( void *ptr )
//	Returns driver type of Ced
{
	struct { double type; } *p = ptr;
	p->type = (double)U14DriverType();
	return 0;
}



// 2010-02-03
int  xCedTypeOf( void *ptr )
//	Returns type of Ced if everything allright or negative error code otherwise.
{
	struct { double hnd; double type; } *p = ptr;
	p->type = (double)U14TypeOf1401( (short)p->hnd );
	return 0;
}



// 2010-02-03
int	xCedGetMemSize( void *ptr )
{
	struct { double hnd; double nSize; } *p = ptr;
	p->nSize = CEDGetMemSize((short)p->hnd );
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


int xCedLdErrOut( void *ptr )
// loads external CED commands and possibly prints error message
{
	struct { Handle CmdStr; Handle DirStr; double ErrShow; double hnd; double res; } *p = ptr;
	Handle    CmdStrH, DirStrH;
	int       err = 0;//lenC, lenD, err = 0;
	
	if ( !p->CmdStr )                        // error:  input string does not exist
		err = NO_INPUT_STRING;
	else 
	{
		DirStrH = IHC( p->DirStr);
		CmdStrH = IHC( p->CmdStr);
		// XOPNotice("LdErrOut a:  Dir:'"); XOPNotice( *DirStrH );  XOPNotice( "'    Cmd:'" ); XOPNotice( *CmdStrH ); XOPNotice( "'\r" );
   		p->res = CEDLdErrOut( (short)p->hnd,(int)p->ErrShow, *DirStrH, *CmdStrH );
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
			sprintf_s( bf, 300, "\t\t\tCed xCedLdErrOut()  hnd:%d  dir:'%s'  commands:'%s' \r", hnd, dir, commands );
			XOPNotice( bf );
		}
		lCode = U14Ld( hnd, dir, commands );								// Load commands
		if ( (code = (short)( lCode & 0xffff) ) != U14ERR_NOERROR )	// Get error code: low word is error 
		{
		   int nCmd = (short)( lCode >> 16 );								// Hi word is index of failed cmd
		   sprintf_s( bf, 300, "++++Error: Loading the %d. command of  '%s'  from  '%s'  failed. 'U14Ld() returns error %d / %d / 0x%08x \r", nCmd, commands, dir, code, lCode & 0x00ff, lCode );
			XOPNotice( bf );
			OutCedErr( code, "U14Ld()" );					// optionally translate the errorcode into an informational string and print it.
			return code;
	   }
   }
   return 0;
}


// LOAD SINGLE COMMANDS : TEST because xCedLdErrOut() FAILS SOMETIMES FOR UNKNOWN REASONS 
// DRAWBACK : directory cannot be specified (looks on current drive....)


int	xCedGetErrorString( void *ptr )
// returns human-readable error string when error code is passed
{
	struct { double code; Handle sRes; } *p = ptr;
	char	errBuf[100];
	char	errString[410];
	int		outlen, err = 0;
	Handle  sOut	= NIL;						

	U14GetErrorString( (short)p->code, errString, 400 );
	outlen	= strlen( errString );

	if (( sOut = NewHandle(outlen)) == NIL )// get output handle , do NOT provide space for '\0' 
	{
		sprintf_s( errBuf, 100,  "++++Error: xCedGetErrorString() Not enough memory. Aborted...\r");
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


int	xCedSendString( void *ptr )
// sends a command string to the CED
{
	struct { Handle str; double hnd; double res; } *p = ptr;
   Handle   str1;
// 060130 dispose ?
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


int xCedSendStringErrOut( void *ptr )
{
	struct { Handle str; double ErrShow; double hnd; double res; } *p = ptr;
	Handle   str1;
	int      err = 0;

	if ( !p->str )                    // error:  input string does not exist
		err = NO_INPUT_STRING;
	else 
	{
		str1 = IHC( p->str);
		CEDSendStringErrOut( (short)p->hnd, (int)p->ErrShow, *str1 );

		DisposeHandleIHC(str1);          // we need to get rid of ..

		p->res = 0.;
	}
	return err;                   // 0 = OK, sonst XFunc error code 
}

short CEDSendStringErrOut( short hnd, int ErrShow, LPSTR str )
// transmit command string 'str' to CED selected by 'hnd'. In case of error..
// ..return error code and make IGOR print error explanation into IGORs command window  
{
   short code = 0;
   char  sText[100] = "U14SendString-";
	if ( hnd >= 0 ) {
		strcat_s( sText, 100, str );
		code = U14SendString( hnd, str );
		OutError( code, sText, ErrShow );  
	}
	return code;
}


int CEDGetResponse( short hnd, LPSTR command, LPSTR text, int ErrMode )
// for CED commands which return 1 integer
// as this function is used in IGOR background task functions, we cannot wait for a response but ..  
// must return immediately (with value 0xcccccccc) if CED did not respond
{
	char	bf[256];    //031205 ?????  260 will make U14GetString() fail with error code -524 : string longer than buffer...
	char	errBuf[400];
	int		nResponse = 0xcccccccc; // 100102 in IGOR: 'hexCCCCCCCC'= 858993460 (is also compiler default anyway)
	int		code = 0;
 	if ( hnd >= 0 )
	{
		if ( ( code = U14SendString( hnd, command ) ) == 0 )
		{
		   if ( ErrMode & MSGLINE )
			{
				sprintf_s( errBuf, 400, "\t\t\tCEDGetResponse(%s)  after sending command:'%s'. Waiting lines: %d, chars: %d \r", text, command, U14LineCount(hnd), U14CharCount(hnd) ); XOPNotice( errBuf );
			}
			if ( ( code = U14GetString( hnd, bf, sizeof(bf)-2 ) ) == 0 )
			{
				return( atoi( bf ) ) ; // scanf( bf, "%d", &nResponse );
			}
			else
			{
				sprintf_s( errBuf, 400, "++++Error: CEDGetResponse(%s)  U14GetString() failed with error code:%d after sending command:'%s' . Returning %d (=0x%08x) \r", text, code, command, nResponse, nResponse ); XOPNotice( errBuf );
			}
		}
		else
		{
			sprintf_s( errBuf, 400, "++++Error: CEDGetResponse(%s)  U14SendString( hnd:%d, command:'%s' ) failed with error code:%d . Returning %d (=0x%08x) \r", text, hnd, command, code, nResponse, nResponse ); XOPNotice( errBuf );
		}
	}
	else
	{
		sprintf_s( errBuf, 400, "++++Error: CEDGetResponse(%s)  failed (invalid CED handle:%d )  command:'%s'. Returning %d (=0x%08x) \r", text, hnd, command, nResponse, nResponse ); XOPNotice( errBuf );
	}
   return nResponse;
}

int	xCedGetResponse( void *ptr )
{
	struct { double errMode; Handle sTxt; Handle sCmd; double hnd; double res; } *p = ptr;
	Handle	sTxt = IHC( p->sTxt );
	Handle	sCmd = IHC( p->sCmd );

	p->res = CEDGetResponse( (short)p->hnd, *sCmd, *sTxt, (int)p->errMode );

	DisposeHandleIHC(sTxt);									// we need to get rid of ..
	DisposeHandleIHC(sCmd);									// we need to get rid of ..
   return 0;												// 0 = OK, sonst XFunc error code 
}



int	xCedGetResponseTwoIntAsString( void *ptr )
// expects 2 integers as a response to 'instr' (e.g.'ERR;') from  the CED, returns these 2 integers as a string 
{
	struct { Handle sCmd; double hnd; Handle sRes; } *p = ptr;
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
				sprintf_s( tmp, 100, "%d %d", LongVal[0], LongVal[1] );
				//XOPNotice(tmp);
				outlen = strlen( tmp );
			   if (( sOut = NewHandle(outlen)) == NIL )// get output handle , do NOT provide space for '\0' 
				{
					sprintf_s( errbuf, 200, "++++Error: xCedGetResponseTwoIntAsString() Not enough memory. Aborted...\r");
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



int xCedLastErrCode( void *ptr )
// prints informational string for errCode
{
	struct { Handle sText; double hnd; double res; } *p = ptr;
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
//char sTxT[150];
	if ( code ) {
		if ( ErrShow & ERR_AUTO_IGOR ) { 
			// applicable when code is defined in xxxWinCustom.RC
			// take strings from the resource xxWinCustom.RC / FPulseCedError.H : can be a mixture of own and CED error strings
			// more flexible, but must be properly constructed: CED strings must be copied and converted from e.g. USE1401.H
			GetIgorErrorMessage( ErrorNrCEDtoIGOR(code), sOrg );	//SEE XOPENTRY()........
		//sprintf( sTxT, "ERR_AUTO_IGOR: len:%d '%s' \r", strlen( sOrg ), sOrg ); XOPNotice( sTxT );
			DisplayError( code, sText, sOrg, ERRLINE ); // print additional line when displaying IGORs automatic error box 
		}
		else {		
			if ( ErrShow & ERR_FROM_CED ) {
				// applicable for all Ced functions U14xxxx
				// take error strings from U14GetErrorString() : easy but ONLY CED error strings are possible
				U14GetErrorString( code, sOrg, 400 );
		//sprintf( sTxT, "ERR_FROM_CED: len:%d '%s' \r", strlen( sOrg ), sOrg ); XOPNotice( sTxT );
				DisplayError( code, sText, sOrg, ErrShow ); // print  line  or  box and line 
			}
			if ( ErrShow & ERR_FROM_IGOR ) { 
				// take strings from the resource xxWinCustom.RC / FPulseCedError.H : can be a mixture of own and CED error strings
				// more flexible, but must be properly constructed: CED strings must be copied and converted from e.g. USE1401.H
				GetIgorErrorMessage( ErrorNrCEDtoIGOR(code), sOrg );	//SEE XOPENTRY()........
		//sprintf( sTxT, "ERR_FROM_IGOR: len:%d '%s' \r", strlen( sOrg ), sOrg ); XOPNotice( sTxT );
				DisplayError( code, sText, sOrg, ErrShow ); // print  line  or  box and line 
			}
		}
	}
}


void DisplayError( short code, LPSTR sText, LPSTR sOrg, int ErrShow )  
{
	char sOut[410];
	if ( (ErrShow & ERRLINE) || (ErrShow & ERRBOX) ) {	// when showing error box, always show line also
		sprintf_s( sOut, 410, "++++Error while executing '%s':  %s (%d)\r", sText, sOrg, code );
		XOPNotice( sOut );
	}
	if ( ErrShow & ERRBOX ) {
		sprintf_s( sOut, 410, "Error while executing '%s':\r\r%s ", sText, sOrg );
		XOPOKAlert( "Error", sOut );
	}
}


//============================================================================================================================

// 04feb24 Tim Bergels recommendations:
// It looks as if the changes to Use1432 are OK, so I am sending you the new library to try out. The new function added is defined as:

	 U14API(short) U14WorkingSet(DWORD dwMinKb, DWORD dwMaxKb); // define here or in USE1401.H . Tim Bergel suggested values 800 and 4000

// it returns zero if all went well, otherwise an error code (currently a positive value unlike other functions). 
// To use it, you should call it once only at the start of your application - I'm not sure how that will apply to you. 
// I suggest using values of 800 and 4000 for the two memory size values, they are known to work fine with CED software.
// Best wishes, Tim Bergel


int xCedWorkingSet( void *ptr )
// Igor wrapper for Tim Bergels (CED) version to adjust the working set size of Win2000, NT, XP
// Needed for U14Ld() to succeed which fails without a previous call to this function if very larges waves (~100MB) have been defined before by Igor.
// Needed also for transfer areas > 64KB up to 1MB (test with scripts CCVIGN_MB.txt(456.3s, 18252kpts) and Spk50Hz_Gs.txt )
// The Windows documentation warns to set these values too high as this would decrease the overall..
// ..performance of the system but the example dates to 95..97 with an increase to 4MB on a 16MB system.
// FOR INCREASING THE ProcessWorkingSetSize TO WORK YOU MUST HAVE ADMINISTRATOR RIGHTS!
{
	struct {  double bMode; double MaxKb;  double MinKb; double res; }* p = ptr;
   int   nMinKb					= (int)p->MinKb;
   int   nMaxKb					= (int)p->MaxKb;
	int	bMode						= (int)p->bMode; 
	int   errCode;
   char  sMsg[200];

	if ( errCode = U14WorkingSet( nMinKb, nMaxKb ) ) {		// Tim Bergel suggested values min:800Kb and max:4000kB
			sprintf_s( sMsg, 200,  "++++Error: U14WorkingSet( min: %ld Kb , max: %ld Kb ) failed with error %d \r", nMinKb, nMaxKb, errCode );
			XOPNotice( sMsg );
	}	
	if ( bMode ) {
			sprintf_s( sMsg, 200, "\t\t\tU14WorkingSet( min: %ld Kb , max: %ld Kb ) returned code %d \r", nMinKb, nMaxKb, errCode );
			XOPNotice( sMsg );
	}	
   p->res = (double)errCode;
   return 0;
}


int xCedSetTransferArea( void *ptr)
// locks the memory area used for the transfers between CED and computer
// for transfer areas > 64KB up to 1MB 
{
	struct {  double ErrMode; waveHndl wRaw; double pts; double nr; double hnd; double res; }* p = ptr;
   short hnd			= (short)p->hnd;
   int   nr				= (int)p->nr;       // area nr must be 0 (although CED manual says in the range 0..7)
   int   nBytes		= (int)p->pts * 2;
	int	ErrMode		= (int)p->ErrMode; 
   void *Raw			= NULL;
   char  bf[200];
	int   errCode;
  
	//DebugPrintWaveProperties( "xCedSetTransferArea", p->wRaw ); 	// 050128

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

// 2021-03-12 to be removed for Toolkit6
//	ghState	= MoveLockHandle( p->wRaw );	// Lock wave handle in heap after moving it to the top so that fragmentation is avoided

   Raw		= WaveData( p->wRaw );			// char pointer to IGOR wave data 
	
	if ( errCode = U14SetTransArea( hnd, nr, Raw, nBytes, 0 ) ) {
	   sprintf_s( bf, 200, "U14SetTransferArea( hnd:%d  nr:%d  Raw Adr:%p Bytes:%d )", hnd, nr, Raw, nBytes ); 
      OutCedErr( errCode, bf );
 	}
   
   if ( ErrMode & MSGLINE ){
	   sprintf_s( bf, 200, "\t\t\tCed xCedSetTransferArea \thnd:%d  nr:%d  h:%p  p:%p  Adr:%p byt:%d=0x%x  code:%d \r",
		              hnd, nr, p->wRaw, *p->wRaw, Raw, nBytes, nBytes, errCode ); 
		XOPNotice( bf );
	}
		
   p->res = (double)errCode;
   return 0;
}


int xCedUnSetTransferArea( void *ptr)
// unlocks the memory used for the transfers between CED and computer
{
	struct {  double ErrMode; waveHndl wRaw; double nr; double hnd; double res; }* p = ptr;
   short hnd     = (short)p->hnd;
   int   nr      = (int)p->nr;       // area nr must be 0 (although CED manual says in the range 0..7)
   int   ErrMode = (int)p->ErrMode; 
   char  bf[200];
   int   errCode;

	// DebugPrintWaveProperties( "xCedUnSetTransferArea", p->wRaw ); 	// 050128

	// 031210   error -528 (Transfer area has not been set up) is NOT regarded as an error	
 	errCode = U14UnSetTransfer( hnd, nr );
	if ( errCode != 0  &&  errCode != -528 )// 031210   error -528 (Transfer area has not been set up) is NOT regarded as an error	
	{
	   sprintf_s( bf, 200, "U14UnSetTransfer( hnd:%d  nr:%d )", hnd, nr ); 
      OutCedErr( errCode, bf );
	}
	
	if ( errCode == 0 )
// 2021-03-12 must be removed for Toolkit6 !
//		HSetState( p->wRaw, ghState );				// let IGOR unlock wRaw 
	
   
   if ( ErrMode & MSGLINE )
   {
      sprintf_s( bf, 200,"\t\t\tCed xCedUnSetTransfer  \thnd:%d  nr:%d  h:%p  p:%p  code:%d\r", hnd, nr, p->wRaw, *p->wRaw, errCode ); 
      XOPNotice( bf );
   }
   p->res = (double)errCode;

   return 0;
}


// currently not used 04feb27

int IsWinNT2000XP()
// code from Article ID: Q92395  
{ 
   OSVERSIONINFO osvi;
   char  bf[200];
	int	version = -2;
   memset(&osvi, 0, sizeof(OSVERSIONINFO));
   osvi.dwOSVersionInfoSize = sizeof (OSVERSIONINFO);
   GetVersionEx (&osvi);

   if (osvi.dwPlatformId == VER_PLATFORM_WIN32s) {
      wsprintf (bf, "\t\tWin3.x (Win32s) %d.%d (Build %d)\r", osvi.dwMajorVersion, osvi.dwMinorVersion, osvi.dwBuildNumber & 0xFFFF);
		version = -1;
	}
   else if (osvi.dwPlatformId == VER_PLATFORM_WIN32_WINDOWS) {
      wsprintf (bf, "\t\tWin 95/98/ME %d.%d (Build %d)\r", osvi.dwMajorVersion, osvi.dwMinorVersion, osvi.dwBuildNumber & 0xFFFF);
		version = 0;
		// if (osvi.dwMajorVersion == 4) && (osvi.dwMinorVersion == 0)	// Win95
		// if (osvi.dwMajorVersion == 4) && (osvi.dwMinorVersion > 0)	// Win98
		// if (osvi.dwMajorVersion > 4)											// WinME?
	}
   else if (osvi.dwPlatformId == VER_PLATFORM_WIN32_NT) {
      wsprintf (bf, "\t\tWin NT/2000/XP %d.%d (Build %d)\r", osvi.dwMajorVersion, osvi.dwMinorVersion, osvi.dwBuildNumber & 0xFFFF);
		version = 1;
	}
	// 060602 one could turn this message automatically on via Errmode/MSGLINE...
	// XOPNotice( bf );
	return version;
}  


//////////////////////////////////////////////////////////////////////////////////////////////////////
// xUTIL - UTILITIES

void DebugPrintWaveProperties( char *sText, waveHndl wWave )
{ 
	char	buf[300];
	char	Nm[100];
	int	wt		= WaveType( wWave );
	int	pts		= WavePoints( wWave );
	int	Bytes	= wt & NT_I16 ? pts*2 :  wt & NT_I32 ? pts*4 : wt & NT_FP32 ? pts*4 : wt & NT_FP64 ? pts*8 : -1 ;
	WaveName( wWave, Nm );
	sprintf_s( buf, 300, "\tDebugPrintWaveProperties() \t%s\t0x%08x\t0x%08x\tType:%2d\t Pt:\t%7d\t By:\t%7d\t0x%08x\tName:\t%s \r", 
// 2021-03-13
//		sText, wWave, *wWave, wt, pts, Bytes, Bytes, Nm);
		sText, (unsigned int)wWave, (unsigned int)*wWave, wt, pts, Bytes, Bytes, Nm );
	XOPNotice( buf );
}



#define DADIREC   0
#define ADDIREC   1

int xUtilConvolve( void *ptr)
// XOP because IGOR itself is too slow..(2GHz: Igor~3us/pt, XOP~40ns/pt)
// ASSUMPTION: the channel order is at first ALL non-compressed true AD channels, then all telegraph channels which are compressed by the same factor
								  
{
	struct {double bStoreIt; double	nPnts; double	nChan; double	nChunk; double	nCompress;
		double yscl; double ofs;  double PtsPerChunk; double RepOs; double endPt; double begPt;
		double nTG;  double nTrueADorDA; double nDirec; waveHndl wRaw; waveHndl wBigWave; double res; }* p = ptr;
   long      ofs          = (long)p->ofs;
   long      PtsPerChunk  = (long)p->PtsPerChunk;
   long      repOs        = (long)p->RepOs;
   long      endPt        = (long)p->endPt;
   long      begPt        = (long)p->begPt;
   long      nTrueADorDA  = (long)p->nTrueADorDA;
   long      nTG          = (long)p->nTG;
   long      nDirec       = (long)p->nDirec;
	long		 nCompress	  = (long)p->nCompress;
	long		 nChunk		  = (long)p->nChunk;
   long		 c				  = (long)p->nChan;
   long		 nPnts		  = (long)p->nPnts;
   BOOL		 bStoreIt	  = (long)p->bStoreIt;
   long      pt, pt1;
   long      nChs         = nTrueADorDA + nTG;
   char      errBuf[200]; 
   short    *wRaw;   
   float    *wBigWave;   
	long		 nRawIdx	= -1, nBigWvIdx = -1;
	int		 nRawPts, nBigWvPts;
	char		 buf[400];															// 050128

	//DebugPrintWaveProperties( "xUtilConvolve   ", p->wRaw );		// 050128
	//DebugPrintWaveProperties( "xUtilConvolve   ", p->wBigWave ); // 050128

   if ( p->wBigWave == NIL || p->wRaw == NIL )// check if wave handle is valid
   {
      sprintf_s( errBuf, 200, "++++Error: xUtilConvolve() received nonvalid wave \r" );
		XOPNotice( errBuf );
	   SetNaN64( &p->res );							// return NaN if wave is not valid   
	   return( NON_EXISTENT_WAVE );
   }
   if ( WaveType(p->wRaw)!= NT_I16 )			// check wave's numeric type  
   {
    	sprintf_s( errBuf, 200,  "++++Error: xUtilConvolve() received non integer wave \r" );
		XOPNotice( errBuf );
	   SetNaN64( &p->res );							// return NaN if wave is not 2Byte int
      return( IS_NOT_2BYTE_INT_WAVE );
   }
   if ( WaveType(p->wBigWave )!= NT_FP32 )	// check wave's numeric type  
   {
    	sprintf_s( errBuf, 200, "++++Error: xUtilConvolve() received non float wave (4Byte) for wBigWave \r" );
		XOPNotice( errBuf );
	   SetNaN64( &p->res );							// return NaN if wave is not 4Byte float
      return( IS_NOT_4BYTE_FLOAT_WAVE );
   }

   wRaw     = WaveData( p->wRaw );				//  char pointer to IGOR wave data 
   wBigWave = WaveData( p->wBigWave );			//  char pointer to IGOR wave data 

	nRawPts	= WavePoints( p->wRaw );
	nBigWvPts= WavePoints( p->wBigWave );


	if ( nDirec == DADIREC )
	{
		for ( pt =   begPt;  pt < endPt;   pt += 1 )
		{
			pt1	= nPnts <= 1 ?  pt + repOs : ( pt + repOs ) % nPnts;	// 031010 nPnts>1:normal memory saving mode, nPnts=0,1 : Protocol aware

			nRawIdx	= (pt%(2*PtsPerChunk)) * nChs + ofs;
			wRaw[ nRawIdx ] = (short)( wBigWave[ pt1 ] * p->yscl +.5 );	// 031010
			
			/*  050128 
			if ( pt==begPt  ||  pt==endPt-1   || (pt+repOs)%nPnts==0  ||  (pt+repOs)%nPnts==1  ||  (pt+repOs)%nPnts==nPnts-1 )
			{
				sprintf( buf, "\t\txUtilConvolve() \tDACs \t\tBeg/End\t%8d\t\t\tPt written:\t%8d\t\t\t\t\tDAIndex:\t%8d \r",
							pt, pt1, nRawIdx );
				XOPNotice( buf );
			}
			*/
		}
	}

	if ( nDirec == ADDIREC )
	{

		if ( c < nTrueADorDA )				// the uncompressed true 'gnCntAD' AD channels
		{
			if ( bStoreIt )
			{
			//		C code COMPRESSING the transferred data, the telegraph waves (to save memory) and good transfer area usage (no gap between TA chunks)
				for ( pt =   begPt;  pt < endPt;   pt += 1 )
				{
					pt1		= nPnts <= 1 ?  pt + repOs : ( pt + repOs ) % nPnts;	// 031010 nPnts>1:normal memory saving mode, nPnts=0,1 : Protocol aware
					nRawIdx	= (nChunk%2) * ( nTrueADorDA *  PtsPerChunk  + nTG * ( PtsPerChunk / nCompress ) )
										+ c *  PtsPerChunk	+  ( pt - begPt )  + ofs;
//					wBigWave[pt1] = wRaw[nRawIdx] / p->yscl;
					wBigWave[pt1] = wRaw[nRawIdx] / (float)p->yscl;	// 2021-03-12
				}
			}
			else		// fill with fixed value to avoid erratic display
			{
				for ( pt =   begPt;  pt < endPt;   pt += 1 )
				{
					pt1	= nPnts <= 1 ?  pt + repOs : ( pt + repOs ) % nPnts;	// 031010 nPnts>1:normal memory saving mode, nPnts=0,1 : Protocol aware
					wBigWave[ pt1 ] = 0;

					/* 050128
					if ( pt==begPt){
						sprintf( buf, "\t\txUtilConvolve() \tTrueADda\tBegPt:\t%8d\t\t\t\t\t\t FirstPt written:\t%8d\t \r", begPt, pt1 );
						XOPNotice( buf );
					}
					*/
				}
			}
			/* 050128
			sprintf( buf, "\t\txUtilConvolve() \tTrueADda\tEndPt:\t%8d\t\t\t\t\t\t Last Pt written:\t%8d\tInt?\t%8.3lf\tRdIndex:\t%8d \r",
								endPt, pt1, (double)PtsPerChunk / nCompress, nRawIdx );
			XOPNotice( buf );
			*/

		}
			
		if ( c >= nTrueADorDA )				// the compressed 'gnCntTG' TG channels (ASSUMPTION: they follow the true AD channels)
		{
			if ( bStoreIt )
			{
				for ( pt =   begPt;  pt < endPt;   pt += nCompress )
				{
					pt1		= nPnts <= 1 ?  pt + repOs : ( pt + repOs ) % nPnts;	// 031010 nPnts>1:normal memory saving mode, nPnts=0,1 : Protocol aware
					nRawIdx	= ( (nChunk%2) *( nTrueADorDA * PtsPerChunk +  nTG * ( PtsPerChunk / nCompress ) ) ) 
										+ nTrueADorDA * PtsPerChunk 
										+ (( c - nTrueADorDA ) * PtsPerChunk ) / nCompress // nSrcStartOfChan
										+ ( pt - begPt ) / nCompress + ofs ;					//	nSrcIndexOfChan
					nBigWvIdx= pt1 / nCompress; 	
	//				wBigWave[nBigWvIdx] = wRaw[nRawIdx] / p->yscl;		
					wBigWave[nBigWvIdx] = wRaw[nRawIdx] / (float)p->yscl;	// 2021-03-12
					/* 050128
					if ( pt==begPt  ||  (pt>=endPt-2*nCompress && pt<endPt) || (pt+repOs)%nPnts==0  ||  (pt+repOs)%nPnts==1  ||  (pt+repOs)%nPnts==nPnts-1 )
					{
						sprintf( buf, "\t\txUtilConvolve() \tcompress:%2d\tnPnts:\t%8d\tOrgPt:\t%8d\tPoint:\t%8d\tPt/Co(=written):\t%8d\tRawIdx(=read):\t%8d\tStoreIt:%2d\t  \r",
											nCompress,nPnts, pt+repOs, pt1, nBigWvIdx, nRawIdx, bStoreIt );
						XOPNotice( buf );
					}
					*/
					// Informs about a very nasty sporadic error. TG wave was just 1 too short, should now be OK: 050128
					if ( nRawIdx < 0  || nRawIdx >= nRawPts )
					{
						sprintf_s( buf, 400, "++++Error\t\txUtilConvolve() Indices:   %d <= %d < %d ??? \r", 0, nRawIdx, nRawPts );
						XOPNotice( buf );
					}
					if ( nBigWvIdx < 0 || nBigWvIdx >= nBigWvPts )
					{
						sprintf_s( buf, 400, "++++Error\t\txUtilConvolve() Indices:   %d <= %d < %d ??? \r", 0, nBigWvIdx, nBigWvPts );
						XOPNotice( buf );
					}
				
				}
			}
			
			else		// fill with fixed value to avoid erratic display
			{
				for ( pt =   begPt;  pt < endPt;   pt += nCompress )
				{
					pt1	= nPnts <= 1 ?  pt + repOs : ( pt + repOs ) % nPnts;	// 031010 nPnts>1:normal memory saving mode, nPnts=0,1 : Protocol aware
					wBigWave[ pt1 / nCompress ] = 0;

					/* 050128
					if ( pt==begPt){
						sprintf( buf, "\t\txUtilConvolve() \tcompress:%2d\tBegPt:\t%8d\t  EPt/Comp:\t%8d\t FirstPt written:\t%8d\t \r",
											nCompress, begPt, endPt/nCompress, pt1 / nCompress );
						XOPNotice( buf );
					}
					*/
				}
			}

			/* 050128
			sprintf( buf, "\t\txUtilConvolve() \tcompress:%2d\tEndPt:\t%8d\t  EPt/Comp:\t%8d\t Last Pt written:\t%8d\tInt?\t%8.3lf\tRdIndex:\t%8d \r",
									nCompress, endPt, endPt/nCompress, pt1 / nCompress, (double)PtsPerChunk / nCompress, nRawIdx );
			XOPNotice( buf );
			*/
		}
	}

	p->res = 0;
	return   0;                           // ..we don't want IGOR to do anything with the error (no error box, no debugger)
}

	
int xUtilWaveCopy( void *ptr )
// XOP because IGOR itself is too slow..
{
   struct { double scl; double nSourceOfs; double nPnts; waveHndl wFloatSource; waveHndl wIntTarget; double res; }* p = ptr;
   long      nSourceOfs  = (long)p->nSourceOfs;
   long      nPnts       = (long)p->nPnts;
   long      i;
   char      errBuf[100]; 
   short    *wIntTarget;   
   float    *wFloatSource;   

	// DebugPrintWaveProperties( "xUtilWaveCopy  ", p->wFloatSource );	// 050128
	// DebugPrintWaveProperties( "xUtilWaveCopy  ", p->wIntTarget );		// 050128

   if ( p->wIntTarget == NIL || p->wFloatSource == NIL )                // check if wave handle is valid
   {
      sprintf_s( errBuf, 100, "++++Error: xUtilWaveCopy() received nonvalid wave \r" );
		XOPNotice( errBuf );
	   SetNaN64( &p->res );								// return NaN if wave is not valid   
	   return( NON_EXISTENT_WAVE );
   }
   if ( WaveType(p->wIntTarget)!= NT_I16 )		// check wave's numeric type  
   {
    	sprintf_s( errBuf, 100, "++++Error: xUtilWaveCopy() received non integer wave ( 2Byte) for wIntTarget \r" );
		XOPNotice( errBuf );
	   SetNaN64( &p->res );								// return NaN if wave is not 2Byte int
      return( IS_NOT_2BYTE_INT_WAVE );
   }

   if ( WaveType(p->wFloatSource )!= NT_FP32 )	// check wave's numeric type  
   {
    	sprintf_s( errBuf, 100, "++++Error: xUtilWaveCopy() received non float wave (4Byte) for wFloatSource \r" );
		XOPNotice( errBuf );
	   SetNaN64( &p->res );								// return NaN if wave is not 4Byte float
      return( IS_NOT_4BYTE_FLOAT_WAVE );
   }

   wIntTarget    = WaveData( p->wIntTarget );	//  char pointer to IGOR wave data 
   wFloatSource  = WaveData( p->wFloatSource );	//  char pointer to IGOR wave data 

	for ( i = 0; i < nPnts; i += 1) {
		wIntTarget[ i ] = (short)( p->scl * wFloatSource[ nSourceOfs + i ] + .5 ); 
	}
	p->res = 0;
   return   0;                           // ..we don't want IGOR to do anything with the error (no error box, no debugger)
}


int xUtilWaveExtract( void *ptr )
// XOP because IGOR itself is too slow..
// 040204 accepts also Float target, additional parameter step
{
	struct { double scl; double nStep; double nSourceOfs; double nPnts; waveHndl wFloatSource; waveHndl wFloatTarget; double res; }* p = ptr;
   long      nPnts       = (long)p->nPnts;
   long      nSourceOfs  = (long)p->nSourceOfs;
   long      nStep       = (long)p->nStep;
   long      i;
   char      errBuf[100]; 
   float    *wFloatTarget;   
   float    *wFloatSource;   
	//char		 bf[1000];

	// DebugPrintWaveProperties( "xUtilWaveExtract", p->wFloatSource ); // 050128
	// DebugPrintWaveProperties( "xUtilWaveExtract", p->wFloatTarget ); // 050128

   if ( p->wFloatTarget == NIL || p->wFloatSource == NIL )  // check if wave handle is valid
   {
      sprintf_s( errBuf, 100, "++++Error: xUtilWaveExtract() received nonvalid wave \r" );
		XOPNotice( errBuf );
	   SetNaN64( &p->res );									// return NaN if wave is not valid   
	   return( NON_EXISTENT_WAVE );
   }
   if ( WaveType(p->wFloatTarget)!= NT_FP32 )		// check wave's numeric type  
   {
    	sprintf_s( errBuf, 100, "++++Error: xUtilWaveExtract() received non float wave ( 4Byte) for wFloatTarget \r" );
		XOPNotice( errBuf );
	   SetNaN64( &p->res );									// return NaN if wave is not 2Byte int
      return( IS_NOT_4BYTE_FLOAT_WAVE );	
   }

   if ( WaveType(p->wFloatSource )!= NT_FP32 )		// check wave's numeric type  
   {
    	sprintf_s( errBuf, 100, "++++Error: xUtilWaveExtract() received non float wave (4Byte) for wFloatSource \r" );
		XOPNotice( errBuf );
	   SetNaN64( &p->res );									// return NaN if wave is not 4Byte float
      return( IS_NOT_4BYTE_FLOAT_WAVE );
   }

   wFloatTarget	= WaveData( p->wFloatTarget );	//  char pointer to IGOR wave data 
   wFloatSource	= WaveData( p->wFloatSource );	//  char pointer to IGOR wave data 


	//for ( i = 0; i <  nPnts;			i += nStep ) {	// WRONG: wFloat tries to right into the next after the LAST element...which crashes
	for ( i = 0; i <= nPnts - nStep;	i += nStep ) {
		//sprintf( bf, "\txUtilWaveExtract()\tpts:\t%7d\tos:\t%7d\tstp:\t%7d\tscl:\t%10.4lf\ti:\t%7d\tItg:\t%7d\tIsc:\t%7d\t \r", 
		//												nPnts, nSourceOfs, nStep, p->scl, i, i / nStep,  nSourceOfs + i );		XOPNotice( bf );
		wFloatTarget[ i/ nStep ] = (float)( p->scl * wFloatSource[ nSourceOfs + i ]); 
	}
	// correct  Igor code
	// for ( i = 0; i <= nPnts - nStep; i += nStep )
	//	  wOneDispWaveCur[ i / nStep ] = wOrgData[ BegPt + i ]	/  Gain
	//  endfor
	// wrong !  Igor code
	// for ( i = 0; i < nPnts; i += nStep )
	//	  wOneDispWaveCur[ i / nStep ] = wOrgData[ BegPt + i ]	/  Gain
	//  endfor

	p->res = 0;
	return	0;                           // ..we don't want IGOR to do anything with the error (no error box, no debugger)
}





int xUtilRealWaveSet( void *ptr )
// XOP because IGOR itself is too slow..
{
   struct { double value; double nEnd; double nBeg; waveHndl wFloatTarget; double res; }* p = ptr;
   long      nBeg  = (long)p->nBeg;
   long      nEnd  = (long)p->nEnd;
   long      i;
   char      errBuf[100]; 
   float    *wFloatTarget;   

	// DebugPrintWaveProperties( "xUtilRealWaveSet", p->wFloatTarget ); 	// 050128

   if ( p->wFloatTarget == NIL )                // check if wave handle is valid
   {
      sprintf_s( errBuf, 100, "++++Error: xUtilRealWaveSet() received nonvalid wave \r" );
		XOPNotice( errBuf );
	   SetNaN64( &p->res );								// return NaN if wave is not valid   
	   return( NON_EXISTENT_WAVE );
   }
   if ( WaveType(p->wFloatTarget )!= NT_FP32 )	// check wave's numeric type  
   {
    	sprintf_s( errBuf, 100, "++++Error: xUtilRealWaveSet() received non float wave (4Byte) for wFloatTarget \r" );
		XOPNotice( errBuf );
	   SetNaN64( &p->res );								// return NaN if wave is not 4Byte float
      return( IS_NOT_4BYTE_FLOAT_WAVE );
   }

   wFloatTarget = WaveData( p->wFloatTarget );	//  char pointer to IGOR wave data 
   
	for ( i = nBeg; i < nEnd; i += 1)
		wFloatTarget[ i ] = (float)p->value; 
	
	p->res = 0;
   return   0;										      // ..we don't want IGOR to do anything with the error (no error box, no debugger)
}


#define	csREADMODE	"cREADMODE"								// must be the same in XOP  and in IGOR
  
int xUtilFileDialog( void *ptr )
// Advantage 1 :	IGOR's command 'Open  /D...' is much simpler but not truely capable of selecting directories..
//						..because there seems to be no way to blank out files , which are confusing to the user
//						To select a directory call from IGOR like : gsDataPath = xUtilFileDialog( "Select directory" , "Directories; ;;" ,  1, sPath,  "", "_" )	
//						additionally there are some lines of IGOR code necessary as framework, see FPulse for sample code
// Advantage 2 :	custom file filters other than those IGOR provides can be used
{
   struct { Handle FilePath; Handle DefExt; Handle InitDir; double Index; Handle Filter; Handle Prompt; Handle ReturnFilePath; }* p = ptr;
   long		Index       = (long)p->Index;
   Handle   strFilePath, strDefExt, strInitDir, strFilter, strPrompt;
	Handle	strReturnFilePath;							// needed extra as XOP cannot receive AND return using the same pointer
	char	TmpReturnFilePath[ MAX_PATH_LEN + 1 ];
	int		lenReturnFilePath;
	int		n = 0, err = 0;
	char	errbuf[200];
	
	char	nativeInitDir[MAX_PATH_LEN+1];			// native path can be longer (C:My:data -> C:\\My\\Data)

	int		bReadMode;										// 'DefExt' is misused to encode the mode 

   strPrompt = IHC( p->Prompt );

	// Replace now the semicolon in the filter string by \0 . We have passed ';' instead of '\0' ... 
	// ...as we could not pass and handle the required syntax containing 'xxx\0yyy\0zzz\0\0' directly  
	// Replace each ';' by '\0'  until the  double ';' is found which is the end of the 'string'
	while ( ( *(*(p->Filter)+n) != ';'  ||  *(*(p->Filter)+n+1) != ';' ) &&  n<1000 )
	{
		if ( *(*(p->Filter)+n) == ';' )
		{	
			*(*(p->Filter)+n)		= '\0';
		}
		n += 1;
	 }
	*(*(p->Filter)+n)		= '\0';	// do not forget the replacement at the end 
	*(*(p->Filter)+n+1)	= '\0';
	n += 2;
	// Now the string is correctly terminated by '\0' and we can safely print it, not earlier
	// Only up to the first '\0' will be printed
	//sprintf ( errbuf, "\t\t\txUtilFileDialog(2) \tn:%2d lenFilter:%d\t'%s'  \r", n , lenFilter, *(p->Filter)  );	XOPNotice( errbuf );

   strFilter = IHC( p->Filter );
	//sprintf ( errbuf, "\t\t\txUtilFileDialog(3) \tstrFilter: \t\t'%s'   Index:%d \r", *strFilter, Index );	XOPNotice( errbuf );

   strInitDir = IHC( p->InitDir );
	//sprintf ( errbuf, "\t\t\txUtilFileDialog(4) \tstrInitDir: \t\t'%s' \r", *strInitDir );	XOPNotice( errbuf );

		
	// if we would use strInitDir (Mac syntax e.g.'C:Dir1:' ) instead of nativeInitDir, the dialog box would not accept it as a legal path and reset...
	GetNativePath( *strInitDir, nativeInitDir );		// convert to windows path (IGOR prefers Mac path syntax)
	//sprintf ( errbuf, "\t\t\txUtilFileDialog(5) \tnativeInitDir:\t\t'%s' \r", nativeInitDir );	XOPNotice( errbuf );
   strDefExt = IHC( p->DefExt );

	bReadMode	= !strcmp( *strDefExt, csREADMODE );
	//sprintf ( errbuf, "\t\t\txUtilFileDialog(6) \tstrDefExt: \t\t'%s' -> ReadMode:%2d \r", *strDefExt, bReadMode );	XOPNotice( errbuf );

   strFilePath = IHC( p->FilePath );
  //sprintf ( errbuf, "\t\t\txUtilFileDialog(7) \tstrFilePath:\t\t'%s' \r", *strFilePath );	XOPNotice( errbuf );

	// 'XOPSaveFileDialog()' uses just 1 char pointer 'filePath' for input  AND  output
	// as this style is impossible in IGOR we must split it into an input param and a return value
   strcpy_s(TmpReturnFilePath, MAX_PATH_LEN + 1, *strFilePath);

	// the dialog box appears...
	if ( bReadMode )
		XOPOpenFileDialog( *strPrompt, *strFilter, &Index, nativeInitDir, TmpReturnFilePath );
	else
		XOPSaveFileDialog( *strPrompt, *strFilter, &Index, nativeInitDir, *strDefExt, TmpReturnFilePath );
	// ...the dialog box vanishes
	
	// prepare and convert the char pointer to be returned from the XOP as an IGOR string 
	lenReturnFilePath = strlen( TmpReturnFilePath );
   if (( strReturnFilePath = NewHandle( lenReturnFilePath )) == NIL ) // get output handle , do not provide space for '\0' 
	{
		sprintf_s( errbuf, 200, "++++Error: xUtilFileDialog() Not enough memory. Aborted...\r");
	   XOPNotice( errbuf );
		err = NOMEM;											// out of memory
	}
	else															// string length is OK so return string 
	{
		memcpy( *strReturnFilePath, TmpReturnFilePath, lenReturnFilePath );       // copy local temporary buffer WITHOUT \0 to persistent Igor output string 
	}
	p->ReturnFilePath = strReturnFilePath;				// this filepath string is returned to IGOR

	// strReturnFilePath' cannot be printed safely because it has no string end '\0'
	// XOPNotice( "\txUtilFileDialog() Out: strReturnFilePath:'" );	XOPNotice( *strReturnFilePath );	XOPNotice( "'\r" );

	DisposeHandleIHC( strFilePath );							// we need to get rid of ..
	DisposeHandleIHC( strDefExt );							// we need to get rid of ..
	DisposeHandleIHC( strInitDir );							// we need to get rid of ..
	DisposeHandleIHC( strFilter );							// we need to get rid of ..
	DisposeHandleIHC( strPrompt );							// we need to get rid of ..

   return err;						    // 0 = OK, sonst XFunc error code 
}



int 	xUtilMemoryLoad( void *ptr )
// From MSVC Knowledge base, HOWTO: Determine the Amount of Physical Memory Installed, Article ID: Q117889  
{
	struct { double res; }* p = ptr;
	MEMORYSTATUS MemoryStatus;

   memset( &MemoryStatus, sizeof(MEMORYSTATUS), 0 );
   MemoryStatus.dwLength = sizeof(MEMORYSTATUS);

   GlobalMemoryStatus( &MemoryStatus );

   p->res = (double)MemoryStatus.dwMemoryLoad;
   return   0;		
}


int 	xUtilTotalPhys(void *ptr)
// From MSVC Knowledge base, HOWTO: Determine the Amount of Physical Memory Installed, Article ID: Q117889  
{
	struct { double res; }* p = ptr;
	MEMORYSTATUS MemoryStatus;

   memset( &MemoryStatus, sizeof(MEMORYSTATUS), 0 );
   MemoryStatus.dwLength = sizeof(MEMORYSTATUS);

   GlobalMemoryStatus( &MemoryStatus );

   p->res = (double)MemoryStatus.dwTotalPhys;
   return   0;	
}


int 	xUtilAvailPhys( void *ptr)
// From MSVC Knowledge base, HOWTO: Determine the Amount of Physical Memory Installed, Article ID: Q117889  
{
	struct { double res; }* p = ptr;
	MEMORYSTATUS MemoryStatus;

   memset( &MemoryStatus, sizeof(MEMORYSTATUS), 0 );
   MemoryStatus.dwLength = sizeof(MEMORYSTATUS);

   GlobalMemoryStatus( &MemoryStatus );

   p->res = (double)MemoryStatus.dwAvailPhys;
   return   0;											
}


int 	xUtilTotalVirtual( void *ptr)
// From MSVC Knowledge base, HOWTO: Determine the Amount of Physical Memory Installed, Article ID: Q117889  
{
	struct { double res; }* p = ptr;
	MEMORYSTATUS MemoryStatus;

   memset( &MemoryStatus, sizeof(MEMORYSTATUS), 0 );
   MemoryStatus.dwLength = sizeof(MEMORYSTATUS);

   GlobalMemoryStatus( &MemoryStatus );

   p->res = (double)MemoryStatus.dwTotalVirtual;
   return   0;											
}


int 	xUtilAvailVirtual( void *ptr)
// From MSVC Knowledge base, HOWTO: Determine the Amount of Physical Memory Installed, Article ID: Q117889  
{
	struct { double res; }* p = ptr;
	MEMORYSTATUS MemoryStatus;

   memset( &MemoryStatus, sizeof(MEMORYSTATUS), 0 );
   MemoryStatus.dwLength = sizeof(MEMORYSTATUS);

   GlobalMemoryStatus( &MemoryStatus );

   p->res = (double)MemoryStatus.dwAvailVirtual;
   return   0;											
}


int 	xUtilContiguousMemory( void *ptr )
// Check if 'nBytes' can be allocated in a contiguous memory as waves need it. 'Make' cannot be used as it issues an error box when failing.
{
	struct { double nBytes; double res; }* p = ptr;
	waveHndl		waveHndPtr;
	char			*WaveNm		= "UF_Temp_xUtilContiguousMemCheck";
   int			nType			= NT_FP32;					// arbitrary, make 4-byte wave
	long	      nPnts       = (long)p->nBytes / 4;	// assume			 4-byte wave
	int			bOverWrite	= TRUE;
	int			code;
	// char		errbuf[200];
	if ( ( code = MakeWave( &waveHndPtr, WaveNm, nPnts, nType, bOverWrite ) ) == 0 ) {
		KillWave( waveHndPtr );
	}
	// sprintf( errbuf, "xUtilContiguousMemory( MegaPts: %.6lf ) returns %d (0=OK, 1=Fail)\r", nPnts * 4 / 1e6, code ); 
	// XOPNotice( errbuf ); 
	p->res = code;
   return   0;		
}


// 060206  does not work: does no compacting and returns always 638976 bytes
int 	xUtilHeapCompact(void *ptr)
{
	struct { double res; }* p = ptr;
	HANDLE	hHeap			= GetProcessHeap();
	UINT		nHeapSize	= HeapCompact( hHeap, 0 );
   p->res = (double)nHeapSize;
   return   0;	
}


int 	xUtilGetSystemDirectory( void *ptr )
{
	struct { Handle sRes; }* p = ptr;
   char		errbuf[MAX_PATH + 100];
	char		sDirPath[MAX_PATH + 20];
   int			len, err	= 0;
   Handle		str1		= NIL;
	
	GetSystemDirectory( sDirPath, MAX_PATH );		// Get the Windows\system path 

   len = strlen( sDirPath );
   if (( str1 = NewHandle( len )) == NIL )		// get output handle, do not provide space for '\0' 
   {
      sprintf_s( errbuf, MAX_PATH + 100, "++++Error: xUtilGetSystemDirectory() Not enough memory. Aborted...\r");
      XOPNotice( errbuf );
      err = NOMEM;										// out of memory
   }
   else														// string length is OK so return string 
      memcpy( *str1, sDirPath, len );				// copy local temporary buffer to persistent Igor output string
 
	sprintf_s( errbuf, MAX_PATH + 100, "xUtilGetSystemDirectory [len:%d]:  '%s' \r", len, sDirPath ); XOPNotice( errbuf );
   p->sRes = str1;
   return err;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////


#pragma pack()    // All structures are 2-byte-aligned.


