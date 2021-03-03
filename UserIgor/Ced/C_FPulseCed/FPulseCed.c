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
#include "C:\Program files\wavemetrics\IgorXOPs\XOPSupport\XOPStandardHeaders.h"
//#include "C:\Programme\wavemetrics\IgorXOPs\XOPSupport\XOPStandardHeaders.h"

#include "FPulseCED.h"
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

// 2009-10-22  remove birthday 
/*
int		UtilBD( int flag );//, LPSTR sExt );
#ifdef _DEBUG
double	UtilBdMake( double days, LPSTR sVersion, LPSTR sTgtDir );
int		CodingTest1( int nCnt );
int		CodingTest2( int nCnt );
#endif
int		UtilNm( LPSTR nm );
int		UtilV( LPSTR sFilePath, LPSTR sV );
void		UtilV2N( LPSTR n, LPSTR v );
char		Sc1( char nOrg );
int		Code12( double number, LPSTR sCoded );
double	Decode12( unsigned char *sCoded );
int		FormatDate( CONST FILETIME *lpFT, LPSTR sFormatted );
int		DateToFileTime( FILETIME *lpFT, UINT year, UINT month, UINT day, UINT hour, UINT minute, UINT second  );
double	FileTimeToSecs( FILETIME *lpFT );
int		SecsToFileTime( FILETIME *lpFT, double secs );
double	DateToSecs( UINT year, UINT month, UINT day, UINT hour, UINT minute, UINT second );
void		SecsToFormated( double secs, LPSTR sDateTime );

// Globals
char	gsVersion[32];
int	TrialTimeExpired;
int	SessionStartSecs	= 0;
*/
 


// Global Variables (none) 

// Forward declarations of CED1401-XOP-Interface
// 2009-10-22  remove birthday 
/*
int xUtilError(					void * );  // checks the global variable which holds the expired-state in FEVAL
*/
#if _DEBUG
// 2009-10-22  remove birthday 
/*
int xUtilRemaining(				void * );  // checks trial time expiry by HD file and returns seconds left, 0=infinite, neg=expired
int xUtilBdMake(					void * );  // creates trial time expiry file. Days, version and target dir must be specified.
int xUtilProlong(					void * );  // creates trial time expiry file. Days must be specified, version and target dir are automatic. 
*/
int xUtilGetSystemDirectory(	void * );  //
#endif

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
int xUtilError(				void * );  // checks expired-global in FEVAL
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
	// 2009-10-22  remove birthday 
/*
	{ xUtilError					},			// ... THESE MUST BE THE FIRST ...
*/
#ifdef _DEBUG
	// 2009-10-22  remove birthday 
/*
	{ xUtilRemaining				},		
	{ xUtilBdMake					},			
	{ xUtilProlong					},			
*/
	{ xUtilGetSystemDirectory		},		
#endif
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

/*
static short	globalCEDHnd = CED_NOT_OPEN;

int	xCedGetHandle(struct { double HndReturn; } *p )
{
	p->HndReturn = CEDGetHandle();
	return 0;
}

short	CEDGetHandle()
{ 

// 2009-10-22  remove birthday 
//
//	// 041111 Trial time expired : Usually the program will not reach this point, except in the case when the user tried to break the expire code...
//		if ( TrialTimeExpired < 0 )
//			globalCEDHnd	= CED_NOT_OPEN;

	return	globalCEDHnd;
}

void	CEDSetHandle( short hnd )
{ 

// 2009-10-22  remove birthday 
//
//	// 041111 Trial time expired : Usually the program will not reach this point, except in the case when the user tried to break the expire code...
//		if ( TrialTimeExpired < 0 )
//			hnd	= CED_NOT_OPEN;// or rand()

	globalCEDHnd = hnd;
}
*/


/* 2010-01-05 unused

int	xCedOpen( struct { double HndReturn; } *p )
// parameter should be 0  (see prog int lib 3.20, dec 99, p.5)
// avoid or show IGORs error message box, show it only in case of error, do not show it when a pos. handle has been returned
{
	short		n1401	= 0;
   p->HndReturn = CEDOpen( n1401 ); 	// return 0 when OK or a negative error code
	return 0;
}

// Version1: open unconditionally

//short	CEDOpen( short n1401 )
// n1401 should be 0  (see prog int lib 3.20, dec 99, p.5)
// returns negative error code or valid handle = 0 or or valid handle > 0 
// CAVE: When 'Open' 1401 has been 'Opened', then switched off and then on again it returns on first U14Open1401()...
// ..an erroneous pos. handle (e.g.5) which can only be eliminated by 'Close1401' with last valid handle (almost always=0)
//{
//	short hnd;
//	if ( ( hnd = U14Open1401( n1401 ) ) < 0 ) {	// do not show valid pos. handles as errors 
//		OutCedErr( hnd, "CEDOpen" );
//		hnd = CED_NOT_OPEN;
//	} 
//	CEDSetHandle( hnd );	 // only open, close and reset set global handle
//	return hnd;
//}

// Version2: if handles says 'it is open' then close and re-open


short	CEDOpen( short n1401 )
// n1401 should be 0  (see prog int lib 3.20, dec 99, p.5)
// returns negative error code or valid handle = 0 or or valid handle > 0 
// CAVE: When 'Open' 1401 has been 'Opened', then switched off and then on again it returns on first U14Open1401()...
// ..an erroneous pos. handle (e.g.5) which can only be eliminated by 'Close1401' with last valid handle (almost always=0)
{
	short hnd;
	int	ErrShow	= MSGLINE;
	// 1401 has been closed and is not open so try to open it now
	// SEE ABOVE: to cope with switching the 1401 on/off we close it first silently 
	if ( hnd = CEDGetHandle() >= 0 )
	{
		CEDClose( ErrShow );			// first close 1401 with current handle. As this can be the valid handle..
	}
	// now open the 1401
	if ( ( hnd = U14Open1401( n1401 ) ) < 0 ) {	// do not show valid pos. handles as errors 
		OutCedErr( hnd, "CEDOpen" );
		hnd = CED_NOT_OPEN;
	} 
	CEDSetHandle( hnd );	 // only open, close and reset set global handle
	return hnd;
}
*/

int	xCedCloseAndOpen( struct { double OldHnd; double HndReturn; } *p )
// p->n1401 should be 0  (see prog int lib 3.20, dec 99, p.5)
// avoid or show IGORs error message box, show it only in case of error, do not show it when a pos. handle has been returned
{
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
		sprintf( bf, "\t\t\txCedCloseAndOpen: Ced cannot be opened,  hnd is set to: %d (=CED_NOT_OPEN) '%s'\r", Hnd_, state ? stateText : "" ); XOPNotice(bf);
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



int	xCedClose( struct { double hnd; double IgorReturn; } *p )
// returns 0 when OK or returns neg. error code
{
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


int	xCedState( struct { double hnd; double IgorReturn; } *p )
// returns 0 when Ced is open and OK   or   returns   -1 (=CED_NOT_OPEN) if Ced was closed or otherwise inactive
{
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


int	xCedStateOf1401( struct {  double hnd; double IgorReturn; } *p )
// returns 0 when Ced is open and OK   or   returns specific negative error code if Ced was closed or otherwise inactive
{
	p->IgorReturn = U14StateOf1401( (short)p->hnd );// return 0 when OK or a negative error code
	return 0;								// returning 0 will avoid Igors error reporting even if there were erros
	//return ( p->IgorReturn );				// in case of error a negative error code is returned which will trigger Igors error reporting
}


// 2010-02-03
int	xCedKillIO( struct { double hnd; double IgorReturn; } *p )
{
	p->IgorReturn = U14KillIO1401( (short)p->hnd );				// return 0 when OK or a negative error code
	return 0;
}


// 2010-02-03
int	xCedReset( struct { double hnd; double IgorReturn; } *p )
{
	p->IgorReturn = U14Reset1401( (short)p->hnd );				// return 0 when OK or a negative error code
	return 0;
}



int	xCedDriverType(  struct { double type; } *p )	
//	Returns driver type of Ced
{
   p->type = (double)U14DriverType();
	return 0;
}



// 2010-02-03
int  xCedTypeOf(  struct { double hnd; double type; } *p )	
//	Returns type of Ced if everything allright or negative error code otherwise.
{
	p->type = (double)U14TypeOf1401( (short)p->hnd );
	return 0;
}



// 2010-02-03
int	xCedGetMemSize( struct { double hnd; double nSize; } *p )
{
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


int xCedLdErrOut( struct { Handle CmdStr; Handle DirStr; double ErrShow; double hnd; double res; } *p )
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
			sprintf( bf, "\t\t\tCed xCedLdErrOut()  hnd:%d  dir:'%s'  commands:'%s' \r", hnd, dir, commands );
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


// LOAD SINGLE COMMANDS : TEST because xCedLdErrOut() FAILS SOMETIMES FOR UNKNOWN REASONS 
// DRAWBACK : directory cannot be specified (looks on current drive....)


int	xCedGetErrorString( struct { double code; Handle sRes; } *p )
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
		sprintf( errBuf, "++++Error: xCedGetErrorString() Not enough memory. Aborted...\r");
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



int	xCedSendString( struct { Handle str; double hnd; double res; } *p )
// sends a command string to the CED
{
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


int xCedSendStringErrOut( struct { Handle str; double ErrShow; double hnd; double res; } *p )
{
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
		strcat( sText, str );
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

int	xCedGetResponse( struct { double errMode; Handle sTxt; Handle sCmd; double hnd; double res; } *p )
{
	Handle	sTxt = IHC( p->sTxt );
	Handle	sCmd = IHC( p->sCmd );

	p->res = CEDGetResponse( (short)p->hnd, *sCmd, *sTxt, (int)p->errMode );

	DisposeHandleIHC(sTxt);									// we need to get rid of ..
	DisposeHandleIHC(sCmd);									// we need to get rid of ..
   return 0;												// 0 = OK, sonst XFunc error code 
}



int	xCedGetResponseTwoIntAsString( struct { Handle sCmd; double hnd; Handle sRes; } *p )
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
					sprintf( errbuf, "++++Error: xCedGetResponseTwoIntAsString() Not enough memory. Aborted...\r");
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



int xCedLastErrCode( struct { Handle sText; double hnd; double res; } *p )
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
		sprintf( sOut, "++++Error while executing '%s':  %s (%d)\r", sText, sOrg, code );
		XOPNotice( sOut );
	}
	if ( ErrShow & ERRBOX ) {
		sprintf( sOut, "Error while executing '%s':\r\r%s ", sText, sOrg );
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


int xCedWorkingSet( struct {  double bMode; double MaxKb;  double MinKb; double res; }* p)
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

int xCedSetTransferArea( struct {  double ErrMode; waveHndl wRaw; double pts; double nr; double hnd; double res; }* p)
// locks the memory area used for the transfers between CED and computer
// for transfer areas > 64KB up to 1MB 
{
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

	ghState	= MoveLockHandle( p->wRaw );	// Lock wave handle in heap after moving it to the top so that fragmentation is avoided

   Raw		= WaveData( p->wRaw );			// char pointer to IGOR wave data 
	
	if ( errCode = U14SetTransArea( hnd, nr, Raw, nBytes, 0 ) ) {
	   sprintf( bf,"U14SetTransferArea( hnd:%d  nr:%d  Raw Adr:%p Bytes:%d )", hnd, nr, Raw, nBytes ); 
      OutCedErr( errCode, bf );
 	}
   
   if ( ErrMode & MSGLINE ){
	   sprintf( bf,"\t\t\tCed xCedSetTransferArea \thnd:%d  nr:%d  h:%p  p:%p  Adr:%p byt:%d=0x%x  stat:%d  code:%d \r",
		              hnd, nr, p->wRaw, *p->wRaw, Raw, nBytes, nBytes, ghState, errCode ); 
		XOPNotice( bf );
	}
		
   p->res = (double)errCode;
   return 0;
}


int xCedUnSetTransferArea( struct {  double ErrMode; waveHndl wRaw; double nr; double hnd; double res; }* p)
// unlocks the memory used for the transfers between CED and computer
{
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
	   sprintf( bf,"U14UnSetTransfer( hnd:%d  nr:%d )", hnd, nr ); 
      OutCedErr( errCode, bf );
	}
	
	if ( errCode == 0 )
		HSetState( p->wRaw, ghState );				// let IGOR unlock wRaw 
	
   
   if ( ErrMode & MSGLINE )
   {
      sprintf( bf,"\t\t\tCed xCedUnSetTransfer  \thnd:%d  nr:%d  h:%p  p:%p  stat:%d  code:%d\r", 
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
      sprintf( bf,"\t\t\tCed xCedUnSetTransfer    hnd:%d  nr:%d  h:%p  p:%p  stat:%d  code:%d\r", 
														        hnd, nr, p->wRaw, *p->wRaw, ghState, errCode ); 
      XOPNotice( bf );
   }
   p->res = (double)errCode;
*/
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
	int	pts	= WavePoints( wWave );
	int	Bytes	= wt & NT_I16 ? pts*2 :  wt & NT_I32 ? pts*4 : wt & NT_FP32 ? pts*4 : wt & NT_FP64 ? pts*8 : -1 ;
	WaveName( wWave, Nm );
	sprintf( buf, "\tDebugPrintWaveProperties() \t%s\t0x%08x\t0x%08x\tType:%2d\t Pt:\t%7d\t By:\t%7d\t0x%08x\tName:\t%s \r", 
							sText, wWave, *wWave, wt, pts, Bytes, Bytes, Nm );
	XOPNotice( buf );
}



#define DADIREC   0
#define ADDIREC   1

int xUtilConvolve( struct {	double bStoreIt; double	nPnts; double	nChan; double	nChunk; double	nCompress; 
										double yscl; double ofs;  double PtsPerChunk; double RepOs; double endPt; double begPt; 
										double nTG;  double nTrueADorDA; double nDirec; waveHndl wRaw; waveHndl wBigWave; double res; }* p)
// XOP because IGOR itself is too slow..(2GHz: Igor~3us/pt, XOP~40ns/pt)
// ASSUMPTION: the channel order is at first ALL non-compressed true AD channels, then all telegraph channels which are compressed by the same factor
								  
{
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
      sprintf( errBuf, "++++Error: xUtilConvolve() received nonvalid wave \r" );
		XOPNotice( errBuf );
	   SetNaN64( &p->res );							// return NaN if wave is not valid   
	   return( NON_EXISTENT_WAVE );
   }
   if ( WaveType(p->wRaw)!= NT_I16 )			// check wave's numeric type  
   {
    	sprintf( errBuf, "++++Error: xUtilConvolve() received non integer wave \r" );
		XOPNotice( errBuf );
	   SetNaN64( &p->res );							// return NaN if wave is not 2Byte int
      return( IS_NOT_2BYTE_INT_WAVE );
   }
   if ( WaveType(p->wBigWave )!= NT_FP32 )	// check wave's numeric type  
   {
    	sprintf( errBuf, "++++Error: xUtilConvolve() received non float wave (4Byte) for wBigWave \r" );
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
						wBigWave[ pt1 ] = wRaw[ nRawIdx ] / p->yscl;		
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
					wBigWave[ nBigWvIdx ] = wRaw[ nRawIdx ] / p->yscl;		
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
						sprintf( buf, "++++Error\t\txUtilConvolve() Indices:   %d <= %d < %d ??? \r", 0, nRawIdx, nRawPts );
						XOPNotice( buf );
					}
					if ( nBigWvIdx < 0 || nBigWvIdx >= nBigWvPts )
					{
						sprintf( buf, "++++Error\t\txUtilConvolve() Indices:   %d <= %d < %d ??? \r", 0, nBigWvIdx, nBigWvPts );
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

	
int xUtilWaveCopy( struct { double scl; double nSourceOfs; double nPnts; waveHndl wFloatSource; waveHndl wIntTarget; double res; }* p)
// XOP because IGOR itself is too slow..
{
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
      sprintf( errBuf, "++++Error: xUtilWaveCopy() received nonvalid wave \r" );
		XOPNotice( errBuf );
	   SetNaN64( &p->res );								// return NaN if wave is not valid   
	   return( NON_EXISTENT_WAVE );
   }
   if ( WaveType(p->wIntTarget)!= NT_I16 )		// check wave's numeric type  
   {
    	sprintf( errBuf, "++++Error: xUtilWaveCopy() received non integer wave ( 2Byte) for wIntTarget \r" );
		XOPNotice( errBuf );
	   SetNaN64( &p->res );								// return NaN if wave is not 2Byte int
      return( IS_NOT_2BYTE_INT_WAVE );
   }

   if ( WaveType(p->wFloatSource )!= NT_FP32 )	// check wave's numeric type  
   {
    	sprintf( errBuf, "++++Error: xUtilWaveCopy() received non float wave (4Byte) for wFloatSource \r" );
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


int xUtilWaveExtract( struct { double scl; double nStep; double nSourceOfs; double nPnts; waveHndl wFloatSource; waveHndl wFloatTarget; double res; }* p)
// XOP because IGOR itself is too slow..
// 040204 accepts also Float target, additional parameter step
{
   long      nPnts       = (long)p->nPnts;
   long      nSourceOfs  = (long)p->nSourceOfs;
   long      nStep       = (long)p->nStep;
   long      i;
   char      errBuf[100]; 
   float    *wFloatTarget;   
   float    *wFloatSource;   
	char		 bf[1000];

	// DebugPrintWaveProperties( "xUtilWaveExtract", p->wFloatSource ); // 050128
	// DebugPrintWaveProperties( "xUtilWaveExtract", p->wFloatTarget ); // 050128

   if ( p->wFloatTarget == NIL || p->wFloatSource == NIL )  // check if wave handle is valid
   {
      sprintf( errBuf, "++++Error: xUtilWaveExtract() received nonvalid wave \r" );
		XOPNotice( errBuf );
	   SetNaN64( &p->res );									// return NaN if wave is not valid   
	   return( NON_EXISTENT_WAVE );
   }
   if ( WaveType(p->wFloatTarget)!= NT_FP32 )		// check wave's numeric type  
   {
    	sprintf( errBuf, "++++Error: xUtilWaveExtract() received non float wave ( 4Byte) for wFloatTarget \r" );
		XOPNotice( errBuf );
	   SetNaN64( &p->res );									// return NaN if wave is not 2Byte int
      return( IS_NOT_4BYTE_FLOAT_WAVE );	
   }

   if ( WaveType(p->wFloatSource )!= NT_FP32 )		// check wave's numeric type  
   {
    	sprintf( errBuf, "++++Error: xUtilWaveExtract() received non float wave (4Byte) for wFloatSource \r" );
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





int xUtilRealWaveSet( struct { double value; double nEnd; double nBeg; waveHndl wFloatTarget; double res; }* p)
// XOP because IGOR itself is too slow..
{
   long      nBeg  = (long)p->nBeg;
   long      nEnd  = (long)p->nEnd;
   long      i;
   char      errBuf[100]; 
   float    *wFloatTarget;   

	// DebugPrintWaveProperties( "xUtilRealWaveSet", p->wFloatTarget ); 	// 050128

   if ( p->wFloatTarget == NIL )                // check if wave handle is valid
   {
      sprintf( errBuf, "++++Error: xUtilRealWaveSet() received nonvalid wave \r" );
		XOPNotice( errBuf );
	   SetNaN64( &p->res );								// return NaN if wave is not valid   
	   return( NON_EXISTENT_WAVE );
   }
   if ( WaveType(p->wFloatTarget )!= NT_FP32 )	// check wave's numeric type  
   {
    	sprintf( errBuf, "++++Error: xUtilRealWaveSet() received non float wave (4Byte) for wFloatTarget \r" );
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
  
int xUtilFileDialog( struct { Handle FilePath; Handle DefExt; Handle InitDir; double Index; Handle Filter; Handle Prompt; Handle ReturnFilePath; }* p)
// Advantage 1 :	IGOR's command 'Open  /D...' is much simpler but not truely capable of selecting directories..
//						..because there seems to be no way to blank out files , which are confusing to the user
//						To select a directory call from IGOR like : gsDataPath = xUtilFileDialog( "Select directory" , "Directories; ;;" ,  1, sPath,  "", "_" )	
//						additionally there are some lines of IGOR code necessary as framework, see FPulse for sample code
// Advantage 2 :	custom file filters other than those IGOR provides can be used
{
   long		Index       = (long)p->Index;
   Handle   strFilePath, strDefExt, strInitDir, strFilter, strPrompt;
	Handle	strReturnFilePath;							// needed extra as XOP cannot receive AND return using the same pointer
	char		TmpReturnFilePath[ MAX_PATH_LEN + 1 ];
	int		lenReturnFilePath;
	int		n = 0, err = 0;
	char		errbuf[200];
	
	char		nativeInitDir[MAX_PATH_LEN+1];			// native path can be longer (C:My:data -> C:\\My\\Data)

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
	strcpy( TmpReturnFilePath, *strFilePath );

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
		sprintf( errbuf, "++++Error: xUtilFileDialog() Not enough memory. Aborted...\r");
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


/*
How do I display a Choose Directory dialog, instead of a Choose File dialog?

// Works only if we're Windows 95 capable 
if (afxData.bWin4)
{
    LPMALLOC pMalloc;
    // Gets the Shell's default allocator 
    if (::SHGetMalloc(&pMalloc) == NOERROR)
    {
        BROWSEINFO bi;
        char pszBuffer[MAX_PATH];
        LPITEMIDLIST pidl;
        // Get help on BROWSEINFO struct - it's got all the bit settings.
        bi.hwndOwner = GetSafeHwnd();
        bi.pidlRoot = NULL;
        bi.pszDisplayName = pszBuffer;
        bi.lpszTitle = _T("Select a Starting Directory");
        bi.ulFlags = BxCfsRETURNFSANCESTORS | BxCfsRETURNONLYFSDIRS;
        bi.lpfn = NULL;
        bi.lParam = 0;
        // This next call issues the dialog box.
        if ((pidl = ::SHBrowseForFolder(&bi)) != NULL)
        {
            if (::SHGetPathFromIDList(pidl, pszBuffer))
            { 
            // At this point pszBuffer contains the selected path 
                DoingSomethingUseful(pszBuffer);
            }
            // Free the PIDL allocated by SHBrowseForFolder.
            pMalloc->Free(pidl);
        }
        // Release the shell's allocator.
        pMalloc->Release();
    }
} 
*/


int 	xUtilMemoryLoad( struct { double res; }* p)
// From MSVC Knowledge base, HOWTO: Determine the Amount of Physical Memory Installed, Article ID: Q117889  
{
	MEMORYSTATUS MemoryStatus;

   memset( &MemoryStatus, sizeof(MEMORYSTATUS), 0 );
   MemoryStatus.dwLength = sizeof(MEMORYSTATUS);

   GlobalMemoryStatus( &MemoryStatus );

   p->res = (double)MemoryStatus.dwMemoryLoad;
   return   0;		
}


int 	xUtilTotalPhys( struct { double res; }* p)
// From MSVC Knowledge base, HOWTO: Determine the Amount of Physical Memory Installed, Article ID: Q117889  
{
	MEMORYSTATUS MemoryStatus;

   memset( &MemoryStatus, sizeof(MEMORYSTATUS), 0 );
   MemoryStatus.dwLength = sizeof(MEMORYSTATUS);

   GlobalMemoryStatus( &MemoryStatus );

   p->res = (double)MemoryStatus.dwTotalPhys;
   return   0;	
}


int 	xUtilAvailPhys( struct { double res; }* p)
// From MSVC Knowledge base, HOWTO: Determine the Amount of Physical Memory Installed, Article ID: Q117889  
{
	MEMORYSTATUS MemoryStatus;

   memset( &MemoryStatus, sizeof(MEMORYSTATUS), 0 );
   MemoryStatus.dwLength = sizeof(MEMORYSTATUS);

   GlobalMemoryStatus( &MemoryStatus );

   p->res = (double)MemoryStatus.dwAvailPhys;
   return   0;											
}


int 	xUtilTotalVirtual( struct { double res; }* p)
// From MSVC Knowledge base, HOWTO: Determine the Amount of Physical Memory Installed, Article ID: Q117889  
{
	MEMORYSTATUS MemoryStatus;

   memset( &MemoryStatus, sizeof(MEMORYSTATUS), 0 );
   MemoryStatus.dwLength = sizeof(MEMORYSTATUS);

   GlobalMemoryStatus( &MemoryStatus );

   p->res = (double)MemoryStatus.dwTotalVirtual;
   return   0;											
}


int 	xUtilAvailVirtual( struct { double res; }* p)
// From MSVC Knowledge base, HOWTO: Determine the Amount of Physical Memory Installed, Article ID: Q117889  
{
	MEMORYSTATUS MemoryStatus;

   memset( &MemoryStatus, sizeof(MEMORYSTATUS), 0 );
   MemoryStatus.dwLength = sizeof(MEMORYSTATUS);

   GlobalMemoryStatus( &MemoryStatus );

   p->res = (double)MemoryStatus.dwAvailVirtual;
   return   0;											
}


int 	xUtilContiguousMemory( struct { double nBytes; double res; }* p)
// Check if 'nBytes' can be allocated in a contiguous memory as waves need it. 'Make' cannot be used as it issues an error box when failing.
{
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
int 	xUtilHeapCompact( struct { double res; }* p)
{
	HANDLE	hHeap			= GetProcessHeap();
	UINT		nHeapSize	= HeapCompact( hHeap, 0 );
   p->res = (double)nHeapSize;
   return   0;	
}



// 2009-10-22  remove birthday 
/*
//===========================================================================================================================
//  TRIAL TIME  FUNCTIONS

// MAGIC DATES : 
//		DateToFileTime( &ftTouch, 2052, 3, 15, 0, 0, 0 );		// magic date meaning first start of FP during trial
//		DateToFileTime( &ftTouch, 1988, 3, 15, 0, 0, 0 );		// = 12218860800 = magic date meaning unlimited usage time

// How it works:
//		At the very start of Igor Igor loads the XOPs. Among others FPulseCed.xop is loaded . 
//		At the beginning of the XOP loader (before any Xop functions are installed and before any IPFs are loaded)..
//		..the trial time is checked. If expired most Xop functions will never be enabled rendering FPulse useless.
//		To check the trial time the location of 'FPulse.ipf' is determined (->UtilNm()) from the registry entry
//		..where FPulse has been installed.
//		FPulse.ipf which contains the strconstant ksVERSION is parsed and ksVERSION is extracted.
//		From ksVERSION the name of the file containing the expiry information is derived.
//		This file is named cryptbdXXXX.dll and has been stored by InnoSetup in the  Windows\System32 directory.
//		This file is loaded and the expiry information is extracted/decoded.
//    Advantages:
//		Each FPulse version has an expiry date independent of the others. (Only one FPulse can be installed at a time.)
//		When the version is changed no Xop compilation is necessary. A version change is frequent in the development phase.   

#include <time.h>

#define	ksWORKINGDIR			"C:\\UserIgor\\Ced"	// must be the  SAME  in  FPRelease.ipf  in  FPulseCed.c
#define	ksCRYPT_BASE			"\\cryptbd"				// must be the  SAME  in  FPRelease.ipf  in  FPulseCed.c
#define	ksCRYPT_EXT				".dll"
#define	ksIGOR_VERSION_FILE	"FPulse.ipf"
#define	kFILESIZE				3780						// should be more than 3000 (and divisible by kENTRYSIZE=12)

#define	kSECS_PER_DAY			(24.*3600.)
#define	kENTRYSIZE				12
#define	kFACT						23
#define	kOFS						20					// do not use string end or formating characters 0..20
#define	kEPS						1e-12				// no problem as we have at most 12 digits, tested and OK up to 1e-40 
#define	knTEST					1000

int xUtilError( struct { double flag; double res; }* p)
{
	char		sTxt[1000];
	p->res	= 0.;
// 041111 Trial time expired 
	if ( TrialTimeExpired < 0 )		// This return code must be checked in the FPulse Igor code..
		p->res	= -1;						// ..and FPulse must be terminated to avoid crashes as all XOPs are missing
	//sprintf( sTxt, "\tUE->%.0lf   sys hours: =%.1lf \r", p->res, GetTickCount()/3600000. );
	//XOPNotice( sTxt );
  	return	0;						// ..we don't want IGOR to do anything with the error (no error box, no debugger)
}


#ifdef _DEBUG
int xUtilRemaining( struct { double flag; double res; }* p)
// We need a global for storing the time at FPulse start as we cannot compute the remaining time directly..
//..as we do at FPulse start as this would require accessing 'FPulse.ipf' which is impossible as Igor has grabbed it. 
{
	char		sTxt[1000];
	int		NowTickSecs	=	GetTickCount()/1000;
	int		RemainSecs	=	TrialTimeExpired + SessionStartSecs - NowTickSecs;
	sprintf( sTxt, "\txUtilRemaining(%d)	TTE: %d + Now: %d - SessStart: %d -> Remaining: %ds (~%.1lfm ~%.1lfh ~%.1lfd) \r",
						(int)p->flag, TrialTimeExpired, NowTickSecs, SessionStartSecs, RemainSecs, RemainSecs/60., RemainSecs/3600., RemainSecs/86400. );
	XOPNotice( sTxt );
	return	0;						// ..we don't want IGOR to do anything with the error (no error box, no debugger)
}


int xUtilBdMake( struct { Handle sTgtDir; Handle sVersion; double Days; double res; }* p)
{
   Handle   pCTgtDir, pCVersion;
	int      err = 0;
	char		nativePath[MAX_PATH];	

   if ( !p->sVersion || !p->sTgtDir )					// error:  input string does not exist
		err = NO_INPUT_STRING;
   else 
   {
		pCTgtDir		= IHC( p->sTgtDir ); 
		pCVersion	= IHC( p->sVersion ); 
		GetNativePath( *pCTgtDir, nativePath );	// convert to windows path (IGOR prefers Mac path syntax)

		{
			char sTxt[1000];
			sprintf( sTxt, "\tNativePath: '%s'  ->  '%s'  \r", *pCTgtDir, nativePath );
			XOPNotice( sTxt );
		}

		p->res	= UtilBdMake( p->Days, *pCVersion, nativePath );
	
      DisposeHandleIHC(pCVersion);							// we need to get rid of the C string
      DisposeHandleIHC(pCTgtDir);							// we need to get rid of ..
   }
   return	err;												// 0 = OK, sonst XFunc error code 
}


int xUtilProlong( struct { double Days; double res; }* p)
{
	int			err = 0;
	char			sDirPath[MAX_PATH + 20];
	GetSystemDirectory( sDirPath, MAX_PATH );			// Get the Windows\system path 
	p->res	= UtilBdMake( p->Days, gsVersion, sDirPath );
   return	err;												// 0 = OK, sonst XFunc error code 
}
*/

int 	xUtilGetSystemDirectory( struct { Handle sRes; }* p)
{
	char			errbuf[MAX_PATH + 100];
	char			sDirPath[MAX_PATH + 20];
   int			len, err	= 0;
   Handle		str1		= NIL;
	
	GetSystemDirectory( sDirPath, MAX_PATH );		// Get the Windows\system path 

   len = strlen( sDirPath );
   if (( str1 = NewHandle( len )) == NIL )		// get output handle, do not provide space for '\0' 
   {
      sprintf( errbuf, "++++Error: xUtilGetSystemDirectory() Not enough memory. Aborted...\r");
      XOPNotice( errbuf );
      err = NOMEM;										// out of memory
   }
   else														// string length is OK so return string 
      memcpy( *str1, sDirPath, len );				// copy local temporary buffer to persistent Igor output string
 
	sprintf( errbuf, "xUtilGetSystemDirectory [len:%d]:  '%s' \r", len, sDirPath ); XOPNotice( errbuf );  
   p->sRes = str1;
   return err;
}

// 2009-10-22  remove birthday 
/*
//==========================================================================================================
//	BIG HELPERS


  double	UtilBdMake( double days, LPSTR sVersion, LPSTR sTgtDir )
// Creates Trial Time Expiry file, 'days' is (positive) trial time or 0 for unlimited version or negative for debug tests
// days > 0. : build limited version , days = 0. : build unlimited version . 
// The user cannot access this function as it's XOP wrapper is only defined in DEBUG mode.
// This function is called only in FPulseRelease()
{
	char				sNm[20];
	int				n;
	char				sTxt[1000];
	char				sFilePath[MAX_PATH + 20] = "";
	UINT				nBytes, nBytesRW, nRandomBytes;
	HANDLE			fh;
	char				sCoded[20];
	char				sDateTime[32]	= "", sDateTime3[32]	= "";
	BYTE				sBuf[ kFILESIZE ];
	FILETIME			ftCreate, ftAccess, ftModify;	// buffers for converted file times
	double			secs;
	int				err;

	if ( days < 0. )
	{
		CodingTest1(120);
		CodingTest2( knTEST );
		return	days;
	}
	// Build path
	strcpy( sFilePath, sTgtDir );
//	strcpy( sFilePath, ksWORKINGDIR );
	strcat( sFilePath, ksCRYPT_BASE );	
	UtilV2N( sNm, sVersion );
	strcat( sFilePath, sNm );
	strcat( sFilePath, ksCRYPT_EXT );

	// Create or overwrite file
	if ( fh	= (HANDLE) CreateFile (sFilePath, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, 0, NULL) )
	{ 
		// Fill the file with random data. Actually for the time stamps only 36 bytes are needed but this would be too short for a DLL.
		//srand(1);															// we want the same sequence every time
		srand( (unsigned)time( NULL ) );								// we want another  sequence every time
		
		nRandomBytes	= kFILESIZE;
		for ( n = 0; n < nRandomBytes; n += 1 )
		{
			sBuf[n] = kOFS + ( rand() * ( 255 - kOFS ) ) / RAND_MAX;
			//sprintf( sTxt, "%3d\t%u \r", n, sBuf[n] );	XOPNotice( sTxt );
		}
		WriteFile( fh, sBuf, nRandomBytes, &nBytesRW, NULL );

		// Now overwrite the first 36 bytes with 3 time stamps
		SetFilePointer( fh, 0, NULL, FILE_BEGIN ); 
		if ( days > 0.)
			secs	= DateToSecs( 2052, 3, 15, 0, 0, 0 );			// this magic date  means Trial version
		if ( days == 0.)
			secs	= DateToSecs( 1988, 3, 15, 0, 0, 0 );			// this magic date  means UNLIMITED version

		SecsToFormated( secs, sDateTime );
		Code12( secs, sCoded );	
		WriteFile( fh, sCoded, kENTRYSIZE, &nBytesRW, NULL );	
		WriteFile( fh, sCoded, kENTRYSIZE, &nBytesRW, NULL );

		SecsToFormated( secs + days * kSECS_PER_DAY, sDateTime3 );
		Code12( secs + days * kSECS_PER_DAY, sCoded );			// the trial period is coded as the difference to.. the Trial magic date
		WriteFile( fh, sCoded, kENTRYSIZE, &nBytesRW, NULL );	// .. the Trial magic date e.g. 2052, 6, 15, 0, 0, 0 means 3 months

		sprintf( sTxt, "\tUtilBdMake(Days:%.4lf=%.0lfsecs)\tWriting %d bytes : \t%s  \t%s  \t%s  to '%s' '%s' '%s' \r",// (V: '%s') \r",
									days, days*kSECS_PER_DAY, kFILESIZE, sDateTime, sDateTime, sDateTime3, sTgtDir, sFilePath, sVersion );
		XOPNotice( sTxt );

		// Manipulate the file time so that the user gets no hint that about the difference between a trial and a final installation
		DateToFileTime( &ftCreate, 2003, 10, 11, 12,  8, 11 );	// y m d h min s 
		DateToFileTime( &ftModify, 2003, 10, 11, 12,  8, 12 );
		DateToFileTime( &ftAccess, 2003, 13, 12, 10, 13,  0 );
		SetFileTime( fh, &ftCreate, &ftModify, &ftModify );	// we use ftModify rather than ftAccess as ftAccess increases 			
		CloseHandle( fh );
	}
	return 1;
}
#endif

//--------------------------------------------------------------------------------------------------------

int		UtilNm( LPSTR sResult )
// build scrambled TTF postfix from version. Similar to Igor 'ScrambleLetterDigit()'
{
	char			sV[600]				= "";		// longer than a line is playing safe
	int			TrialTimeExpired	= 0;
	char			sFilePath[ MAX_PATH ];

#ifdef _DEBUG
	// Get the location of the file containing the version from my fixed development path
	strcpy( sFilePath, ksWORKINGDIR );		// e.g.  'C:\\UserIgor\\Ced'
	strcat( sFilePath, "\\" );					// e.g.  'C:\\UserIgor\\Ced\\'
#else	
	// Get the location of the file containing the version from the installation path from the registry
	HKEY hKey		= NULL;
	DWORD nLength	= MAX_PATH;
	memset(sFilePath, 0, MAX_PATH);
	// 'FPulse_FEval'		IS SAME IN  FPULSE.ISS  and in  FPulseCed.C
	if (RegOpenKeyEx( HKEY_LOCAL_MACHINE, "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\FPulse_FEval_is1", 0, KEY_EXECUTE, &hKey) == ERROR_SUCCESS)
	{
		DWORD dwError = RegQueryValueEx( hKey, "InstallLocation", NULL, NULL, (LPBYTE)sFilePath, &nLength);
               
		if (hKey)
			RegCloseKey(hKey);
	}
#endif

	strcat( sFilePath, ksIGOR_VERSION_FILE );

	TrialTimeExpired	= UtilV( sFilePath, sV );	// Read the IPF file containing the version

	strcpy( gsVersion, sV );
	UtilV2N( sResult, sV );								// Do the scrambling
	return	TrialTimeExpired;							// 0 = OK
}


int	UtilV( LPSTR sFilePath, LPSTR sV )
{
// Attempt to open the IGOR ipf file containing the version and get it's version number 
// Check if the file exists. As the installation routine creates the file it must exist.
	int			len;
	char			sTxt[1000];
	FILE			*fp;	
	char			sLine[512];
	int			nAssigned;
	int			bFound	= FALSE;
	if( (fp = fopen( sFilePath, "r+t" )) != NULL )
	{
		do 
		{
			if ( fgets( sLine, 500, fp ) != NULL )
			{
				// strcat( sLine, "\r" ); XOPNotice( sLine );
				if ( ( nAssigned = sscanf( sLine, "strconstant ksVERSION = \"%s  ", sV ) ) == 1 )
				{
					int	err = 0;
					len	= strlen( sV );	// e.g. 300a"
					sV[ len-1 ] = 0;			// remove trailing  " , e.g. 300a
#ifdef _DEBUG
					sprintf( sTxt, "\tUtilNm() UtilV() : %s  -> extracted  '%s'  from  '%s' \r", sLine, sV, sFilePath );
					XOPNotice( sTxt );
#endif
					bFound	= TRUE;
					break;
				}
			}
			else
				break;
			
		}
		while ( TRUE );
      fclose( fp );
   }

	if ( bFound	== FALSE )
	{
		TrialTimeExpired = -4;			// or kDELETED
		sprintf( sTxt, "*** Fatal FPulse/FEval error. Reinstall the package....\r" );
#ifdef _DEBUG
		sprintf( sTxt, "*** Fatal FPulse/FEval error. Reinstall the package....  (Version Datei '%s' not found)\tRet:%d \r",
									sFilePath, TrialTimeExpired );
#endif
		XOPNotice( sTxt );
	}
	return	TrialTimeExpired;
}

	
void	UtilV2N( LPSTR sn, LPSTR v )
{
	int	n, len	= strlen( v );
	for ( n = 0; n < len; n += 1 )
		sn[n] = Sc1( v[len-1 - n] );					// also reverse order
	sn[n]	= 0;												// string end
}


char		Sc1( char nOrg )
// Only letters and digits are allowed, but no underscore
{
	if ( '0' <= nOrg  &&  nOrg	<= '9' ) 
		nOrg	= nOrg - '0';								// map '0'...'9'  to number  0..9
	else if ( 'a' <= nOrg  &&  nOrg	<= 'z')
		nOrg	= nOrg - 'a' + 10;						// map 'a'...'z'  to number 10..36
	else if ( 'A' <= nOrg  &&  nOrg	<= 'Z')
		nOrg	= nOrg - 'A' + 10;						// map 'A'...'Z'  to number 10..36
	else
		nOrg	= '_';
//	nOrg	= ( '0' <= nOrg  &&  	nOrg	<= '9' ) ?  nOrg - '0'		:  nOrg;	// map '0'...'9'  to number  0..9
//	nOrg	= ( 'a' <= nOrg  &&  	nOrg	<= 'z')  ?  nOrg - 'a'+10	:  nOrg;	// map 'a'...'z'  to number 10..36
//	nOrg	= ( 'A' <= nOrg  &&  	nOrg	<= 'Z')  ?  nOrg - 'A'+10	:  nOrg;	// map 'A'...'Z'  to number 10..36
	// Add 18 and compute the remainder when dividing by 36
	nOrg	+= 18;				// must be half of 36
	nOrg	= nOrg % 36;
	if ( nOrg < 10 )
		return	nOrg + '0';
	else
		return	nOrg - 10 + 'a';
}


int	UtilP( int nFlag, int SecondsLeft )
{
	char			sTxt[1000];
	UINT	days, hours, minutes;
	if ( nFlag > 0 )
	{
		// This computes the remaining trial time. 
		// As a disk access is used it seems unsafe (though theoretically possible) to incorporate this call in various XOP functions.
		// Rather the remaining time is computed just once at program start and the stored in a global.
		// It is accepted that bypassing the trial version is made easier this way.
		if ( ( days	= SecondsLeft / ( 24 * 3600 ) ) >= 1 )
			sprintf( sTxt, "*** Trial time left: %d days\r", days );
		else 
			if ( ( hours = SecondsLeft / 3600 ) >= 1 ) 
				sprintf( sTxt, "*** Trial time left: %d hours\r", hours );
			else 
				if ( ( minutes = SecondsLeft / 60 ) >= 1 ) 
					sprintf( sTxt, "*** Trial time left: %d minutes\r", minutes );
				else 
					if ( SecondsLeft > 0 ) 
						sprintf( sTxt, "*** Trial time left: %d seconds\r", SecondsLeft );
					else
						sprintf( sTxt, "*** Trial time expired. \r" );
		XOPNotice( sTxt );
	}
	return	0;
}

//--------------------------------------------------------------------------------------------------------------------------

int		UtilBD( int nFlag )
// Checks whether the trial version has expired. Returns negative code if expired, seconds left if OK. Flag controls how much is printed. 
// Ways to fool this function:
// 1.	make the clock run slower, stop it or reset it to the time just after the last time stamp: this prolongs the trial time  
// 2. keep the computer and FPulse running without ever quitting: this prevents checking the expire date
// 3. copy the the 'initialisation' ksCRYPT file before the first start of FPulse and use this initialisation version each time FPulse expires...
// 4. disassemble and / or debug the XOP and make the expire code inactive
// Simply setting the clock back (by more than the time elapsed since the last time stamp) will NOT fool this function.
// Potential problems:
// If the system clock was wrong during the first start and is then set correctly later, the trial time computation will fail
// Possible solution: Check clock during first start and let the user acccept the correct setting.

// nFlag = 0 : no info print, nFlag > 0 : print remaining trial time.  This is used just once at startup.
// The user cannot access this function as it's XOP wrapper is only defined in DEBUG mode.
// This function is called during the XOP initialisation in XOPMain 
{
	char			sNm[20];
	char			sTxt[1000];
	char			sDirPath[MAX_PATH + 20];
	char			sFilePath[MAX_PATH + 20];
	FILETIME		ft, ftCreate, ftAccess, ftModify, ftTouch;	// buffers for converted file times
	FILETIME		ftSystem;												// buffer for converted system time in file time format
	double		SystemSecs, secs,	days;								// the trial time
	double		StampSecs, StampSecs2, StampSecs3, ElapsedSecs = 0.;
	int			SecondsLeft = 0;
	UINT			nBytes, nBytesRW;
	HANDLE		fh;
	DWORD			FileLen;
	char			sCoded[20];
	char			sCreate[100], sAccess[100], sModify[100], sDateTime[32], sDateTime2[32], sDateTime3[32];
	int			RemainSecs = 0, RemainMinutes = 0, RemainHours = 0, RemainDays = 0;
	int			err;
	
	// Get the Windows\system path  and the  current time
	GetSystemDirectory( sDirPath, MAX_PATH );
	GetSystemTimeAsFileTime( &ftSystem );
	SystemSecs			= FileTimeToSecs( &ftSystem );
	SessionStartSecs	= GetTickCount()/1000;// for computing the remaining TT  DURING a session

	// Build path
	strcpy( sFilePath, sDirPath );
	strcat( sFilePath, ksCRYPT_BASE );
	err	= UtilNm( sNm );
	strcat( sFilePath, sNm );
	strcat( sFilePath, ksCRYPT_EXT );

	// Attempt to open the file and get it's time stamp
	if ( fh	= (HANDLE) CreateFile( sFilePath, GENERIC_READ|GENERIC_WRITE, 0, NULL, OPEN_EXISTING, 0, NULL) )
	{ 
		// Check if the file exists. As the installation routine creates the file it must exist.
		// If it is missing then either the user has deleted it or there was an incorrect installation.
		FileLen	= GetFileSize( fh, NULL );
		if ( FileLen == 0xffffffff  ||  FileLen % kENTRYSIZE  ||  FileLen == 0 )
		{
			TrialTimeExpired = -3;			// or kDELETED
#ifdef _DEBUG
			{
			LPVOID lpMsgBuf;
			FormatMessage( FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM |FORMAT_MESSAGE_IGNORE_INSERTS,
							    NULL,  GetLastError(),  MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), (LPTSTR) &lpMsgBuf, 0, NULL );
			// Process any inserts in lpMsgBuf.  ............
			//MessageBox( NULL, (LPCTSTR)lpMsgBuf, "Error", MB_OK | MB_ICONINFORMATION );	// Display the string.
			sprintf( sTxt, "*** Fatal FPulse/FEval error. Reinstall the package..  (TimeKeepingDatei '%s' deleted) \tFileLen:%d \r%s\tRet:%d \r",
										sFilePath, FileLen, lpMsgBuf, TrialTimeExpired );
			XOPNotice( sTxt );
			LocalFree( lpMsgBuf );																			// Free the buffer.
			}
#endif
			sprintf( sTxt, "*** Fatal FPulse/FEval error. Reinstall the package..\r" );
			XOPNotice( sTxt );
			CloseHandle( fh );
			return TrialTimeExpired;				
		}

		GetFileTime( fh, &ftCreate, &ftAccess, &ftModify );
		FormatDate( &ftCreate, sCreate );
		FormatDate( &ftAccess, sAccess );
		FormatDate( &ftModify, sModify );
		
#ifdef _DEBUG
		FormatDate( &ftSystem, sDateTime );
		sprintf( sTxt, "\tUtilBD(%d)\t'%s'  l:%d  Syst:\t%s\tCr:\t%s\tAc:\t%s\tMo:\t%s\r", 
									nFlag, sFilePath, FileLen, sDateTime, sCreate, sAccess, sModify );
		XOPNotice( sTxt );
#endif

		// Extract the time stamps (the dates of the first and the last start of FPulse/FEval)
		ReadFile( fh, sCoded, kENTRYSIZE, &nBytesRW, NULL );
		sCoded[ kENTRYSIZE ]		= 0;									// string end
		StampSecs	= Decode12( sCoded ) ;
		SecsToFormated( StampSecs, sDateTime );

		ReadFile( fh, sCoded, kENTRYSIZE, &nBytesRW, NULL );
		sCoded[ kENTRYSIZE ]		= 0;									// string end
		StampSecs2	= Decode12( sCoded ) ;
		SecsToFormated( StampSecs2, sDateTime2 );

		ReadFile( fh, sCoded, kENTRYSIZE, &nBytesRW, NULL );
		sCoded[ kENTRYSIZE ]		= 0;									// string end
		StampSecs3	= Decode12( sCoded ) ;
		SecsToFormated( StampSecs3, sDateTime3 );


		// Check for the magic unlimited usage date 1988/march/15. If found then return 0 meaning no trial time limit.
		if ( StampSecs == DateToSecs( 1988, 3, 15, 0, 0, 0 ) )
		{
			TrialTimeExpired = 0 ;
#ifdef _DEBUG
			sprintf( sTxt, "\tUtilBD(%d)\tNo trial time limits for FPulse/FEval\tSecs:%.0lf \t%s  \t%s  \t%s  \t%s \tRet:%d[s] \r",
											nFlag, StampSecs, sDateTime, sDateTime2, sDateTime3, sCoded, TrialTimeExpired );
			XOPNotice( sTxt );
#endif
			CloseHandle( fh );
			return TrialTimeExpired;
		}

		// Check for the magic initialisation date 2052/march/15. If found then replace it by the systemdate. 
		// This is done just ONCE at the very first FPulse start. From then on the trial timer runs...
		if ( StampSecs == DateToSecs( 2052, 3, 15, 0, 0, 0 ) )
		{
			SetFilePointer( fh, 0, NULL, FILE_BEGIN ); 

			Code12( SystemSecs, sCoded );										// write the date of the first start (will never be overwritten)
			WriteFile( fh, sCoded, kENTRYSIZE, &nBytesRW, NULL );		//

			Code12( SystemSecs, sCoded );										// write the date of every start (will be updated every time FPulse is started)
			WriteFile( fh, sCoded, kENTRYSIZE, &nBytesRW, NULL );		// this is necessary to detect tinkering with the clock
	
			Code12( SystemSecs + StampSecs3 - StampSecs2, sCoded );	// write the expiry date (will never be overwritten)
			WriteFile( fh, sCoded, kENTRYSIZE, &nBytesRW, NULL );		// write the expiry date (will never be overwritten)

			// Manipulate the file time so that it is not obvious that we have just written to the file
			SetFileTime( fh, &ftCreate, &ftModify, &ftModify );		// we use ftModify rather than ftAccess as ftAccess increases 			
			TrialTimeExpired =	(int)(StampSecs3 - StampSecs2);		// here at initialisation this is the full trialtime
#ifdef _DEBUG
			sprintf( sTxt, "\tUtilBD(%d)\tInitialisation \t\t\t\tSecs:%.0lf \t%s  \t%s  \t%s  \t%s \tRet:%d[s] \r",
											nFlag, StampSecs, sDateTime, sDateTime2, sDateTime3, sCoded, TrialTimeExpired );
			XOPNotice( sTxt );
#endif
			UtilP( nFlag, (int)(StampSecs3 - StampSecs2) );		// print the remaining trial time
			CloseHandle( fh );
			return	TrialTimeExpired;
		}

		// We have neither an unlimited version  nor  are we initialising a trial version: 
		// We are within the trial period so we check how much time is left 
		ElapsedSecs		= SystemSecs - StampSecs;
		SecondsLeft		= (int)(StampSecs3 - SystemSecs);
		TrialTimeExpired =	SecondsLeft;
#ifdef _DEBUG
		sprintf( sTxt, "\tUtilBD(%d)\tChecking trial period  \t\tSecs:%.0lf \t%s  \t%s  \t%s  \t%s \tRet:%4d[s]\tElapsedSecs:%8.0lf \tRemainSecs: %d \r",
											nFlag, StampSecs, sDateTime, sDateTime2, sDateTime3, sCoded, TrialTimeExpired, ElapsedSecs, SecondsLeft );
		XOPNotice( sTxt );
#endif
			
		// Check if expired
		if ( SecondsLeft < 0 )	
		{
			TrialTimeExpired =	-1;		// or kEXPIRED
			XOPNotice( "*** Trial time for FPulse/FEval expired.. \r" );
			CloseHandle( fh );
		   return TrialTimeExpired;										      // ..we don't want IGOR to do anything with the error (no error box, no debugger)
		}

		// Check if the system clock has been manipulated (potential flaw: summer/winter change?)
		if ( StampSecs > SystemSecs || StampSecs2 > SystemSecs )	
		{
			TrialTimeExpired =	-2;		// or kTINKERED
#ifdef _DEBUG
			sprintf( sTxt, "*** Trial time for FPulse/FEval expired....(Clock manipulation?)\tTotalSecs:%14.1lf > \tSystemSecs:%14.1lf  ElapsedSecs:%.lf are negative!  Ret:%d \r", 
							StampSecs, SystemSecs,StampSecs-SystemSecs, TrialTimeExpired );
			XOPNotice( sTxt );
#endif
			XOPNotice( "*** Trial time for FPulse/FEval expired....\r" );
			CloseHandle( fh );
		   return TrialTimeExpired;			
		}


		// Update the file by overwriting the time of the last start by the current system time
		Code12( SystemSecs, sCoded );
		SetFilePointer( fh, kENTRYSIZE, NULL, FILE_BEGIN );		// overwrite the 2. entry 
		WriteFile( fh, sCoded, kENTRYSIZE, &nBytesRW, NULL );

		TrialTimeExpired = SecondsLeft;

#ifdef _DEBUG
		RemainSecs		= SecondsLeft;
		RemainDays		= RemainSecs / kSECS_PER_DAY;
		RemainSecs	  -= RemainDays * kSECS_PER_DAY;
		RemainHours		= RemainSecs / 3600;
		RemainSecs	  -= RemainHours * 3600;
		RemainMinutes	= RemainSecs / 60;
		RemainSecs		= RemainSecs % 60;
		SecsToFormated( SystemSecs, sDateTime );
		sprintf( sTxt, "\tUtilBD(%d)\tOK : Trial time for FPulse/FEval\tElapsedSecs:%.0lf / %.0lf (%.0lf%%)   Left:%d d  %d h  %d m %d s  Ret:%d[s] "
							"\tWriting %d bytes '%s' . [ %s = secs:%15.0lf =%15.0lf ]\r",
									nFlag, ElapsedSecs, StampSecs3 - StampSecs, ElapsedSecs *100 / (StampSecs3 - StampSecs), 
									RemainDays, RemainHours, RemainMinutes, RemainSecs, TrialTimeExpired,
									nBytesRW, sCoded, sDateTime, SystemSecs, Decode12( sCoded ) );
		XOPNotice( sTxt );
#endif

		UtilP( nFlag, SecondsLeft );		// print the remaining trial time

		// Manipulate the file time so that it is not obvious that we have just written to the file
		//DateToFileTime( &ftCreate, 2004, 3, 15, 15, 0, 0 );	// enable  these 2 lines to put a fixed time stamp on the file
		//DateToFileTime( &ftModify, 2004, 3, 15, 15, 0, 0 );	// disable these 2 lines to restore the old file time (file time always stays the same)
		SetFileTime( fh, &ftCreate, &ftModify, &ftModify );	// we use ftModify rather than ftAccess as ftAccess increases 			
		CloseHandle( fh );
		return 1;

	}
	return -4;		// Should not occur : Attempt to open the file returned 0. (If opening failed then the code is -1 which is handled above.)
}

//----------------------------------------------------------------------------------------------------------------------------------

UINT		Code( int digit )
{
	int		offset	= min( max( 0, rand() / ( RAND_MAX / 10 ) ), 9 ); 
	return	kFACT * digit + offset + kOFS;
}


UINT		Decode( UINT character )
{
	return	( character - (UINT)kOFS ) / (UINT)kFACT;
}


int		Code12( double number, LPSTR sCoded )
{
	char		sNumber[16];
	char		sText[120];
	int		n, len;
	sprintf( sNumber, "%012.0lf", number );
	len	= strlen( sNumber );
	for ( n = 0; n < len; n += 1)
	{
		sprintf( sCoded + n, "%c" , Code( sNumber[n] - '0' ) );		
		//sprintf( sText, "Code12( %012.0lf = %s )  \t\tn:%d\t'%c'\t(%3d) \t->\t'%c'\t'%s' \r", 
		//				number, sNumber, n, sNumber[n], Code( sNumber[n] - '0'), sCoded[ n ], sCoded + n );
		//XOPNotice( sText );
	}
	return	0;
}

double	Decode12( unsigned char *sCoded )
{
	int		n, len;
	double	dblDecoded	= 0.;
	UINT		DecodedChar;
	char		sText[120];
	len	= strlen( sCoded );
	for ( n = 0; n < len; n += 1)
	{
		DecodedChar	= sCoded[ n ];
		dblDecoded	= 10.* dblDecoded + Decode( DecodedChar );
		//sprintf( sText, "Decode12( %s )\tn:%d\t(%3u)\t%d\t->\t%015.1lf \r", 
		//						sCoded, n, DecodedChar, Decode( DecodedChar ), dblDecoded );
		//XOPNotice( sText );
	}
	return	dblDecoded;
}


int		FormatDate( CONST FILETIME *lpFT, LPSTR sFormatted )
{
	WORD			FatDate, FatTime;		// variable for MS-DOS date and time
   int			year, month, day, hour, minute, second;
	FileTimeToDosDateTime( lpFT, &FatDate, &FatTime );
//	double		Secs	= ( pow(2., 32.) * lpFT->dwHighDateTime + lpFT->dwLowDateTime ) / 1e7; // 100ns -> seconds
	year			= (( 0xfe00 & FatDate ) >> 9) + 1980;
	month			=  ( 0x01e0 & FatDate ) >> 5;
	day			=    0x001f & FatDate;
	
	hour			=  ( 0xf800 & FatTime ) >> 11;
	minute		=  ( 0x07f0 & FatTime ) >> 5;
	second		=    0x001f & FatTime;

	sprintf( sFormatted, "%4d %02d %02d , %02d:%02d:%02d", year, month, day, hour, minute, second );
//	sprintf( sFormatted, "\t\t\t%s\tDate and time: %4d %02d %02d , %02d:%02d:%02d  \t(H:%10u\tL:%10u\ts:%14.1lf)\r", 
//								sHeader, year, month, day, hour, minute, second, lpFT->dwHighDateTime, lpFT->dwLowDateTime, TotalSecs );
	return	0;
}


int		DateToFileTime( FILETIME *lpFT, UINT year, UINT month, UINT day, UINT hour, UINT minute, UINT second  )
{
	WORD		FatDate	= ((year-1980) << 9) + (month << 5) + day;	// variable for MS-DOS date and time
	WORD		FatTime	=  (hour << 11) + (minute << 5) + second;		// variable for MS-DOS date and time
	DosDateTimeToFileTime( FatDate, FatTime, lpFT );
	return	0;
}


double	FileTimeToSecs( FILETIME *lpFT )
{
	double	HiPartSecs	= pow(2,32) * 1e-7;	// 32bit counting 100 ns time slices
	return	HiPartSecs * lpFT->dwHighDateTime + lpFT->dwLowDateTime * 1e-7;
}	


int		SecsToFileTime( FILETIME *lpFT, double secs )
{
	double	HiPartSecs	= pow(2,32) * 1e-7;	// 32bit counting 100 ns
	lpFT->dwHighDateTime	=  (UINT)(   secs / HiPartSecs );
	lpFT->dwLowDateTime	=	(UINT)( ( secs - lpFT->dwHighDateTime * HiPartSecs ) * 1e7 );
	return	0;
}	


double	DateToSecs( UINT year, UINT month, UINT day, UINT hour, UINT minute, UINT second )
// Converts year, month, day, hour, minute and second  into structure FILETIME, then to secs( returned )
{
	FILETIME ft;
	DateToFileTime( &ft, year, month, day, hour, minute, second );
	return	FileTimeToSecs( &ft );		// seconds as double
}

void		SecsToFormated( double secs, LPSTR sDateTime )
// Converts seconds (computed from FILETIME) into date/time string
{
	FILETIME ft;
	SecsToFileTime( &ft, secs );
	FormatDate( &ft, sDateTime );
}

//----------------------------------------------------------------------------------------------------------------------------------

#ifdef _DEBUG

int		CodingTest1( int nCnt )
{
	int		d, n;
	char		bufCoded[1000+10];
	char		bufDecod[1000+10];
	UINT		cCoded;
	UINT		Decoded;
	char		sText[120];
	nCnt	= min( nCnt, 1000 );
	srand( (unsigned)time( NULL ) );
	sprintf( sText, "CodingTest1( %d ) \r", nCnt );
	XOPNotice( sText );
	for ( d = 0; d < 10; d += 1)
	{
		for ( n = 0; n < nCnt; n += 1)
		{
			cCoded	= Code( d );
			sprintf( bufCoded+n, "%c", cCoded ); 
			Decoded	= Decode( cCoded );
			sprintf( bufDecod+n, "%d", Decoded ); 
		}
		strcat( bufCoded, "\r" );
		strcat( bufDecod, "\r" );
		XOPNotice( bufCoded );
		XOPNotice( bufDecod );
	}
	return	0;
}


int		CodingTest2( int nCnt )
{
	int		n;
	double	number;
	char		sCoded[40];
	char		sTxt[120];
	double	dblNumber;
	sprintf( sTxt, "CodingTest2( %d ) \r", nCnt );
	XOPNotice( sTxt );
	srand( (unsigned)time( NULL ) );
	for ( n = 0; n < nCnt; n += 1)
	{
		number	= rand() * 64123457. ;	
		Code12( number, sCoded );
		dblNumber	= Decode12( sCoded );
		sprintf( sTxt, "CodingTest2(%3d/%3d)\t%015.1lf\t= %015.1lf\t OK\t(%s)\r", 
										n, nCnt, number, dblNumber, sCoded );
		XOPNotice( sTxt );
		if( abs( number / dblNumber - 1. ) > kEPS )
		{
			sprintf( sTxt, "\r******* Codingtest2 ERROR : %015.1lf and %015.1lf differ by %g (> %g) \r", number, dblNumber,  abs( number / dblNumber - 1. ), kEPS );
			XOPNotice( sTxt );
			return	-1;
		}
	}
	return	0;
}

#endif
// 2009-10-22  remove birthday 
*/

//////////////////////////////////////////////////////////////////////////////////////////////////////


#pragma pack()    // All structures are 2-byte-aligned.


