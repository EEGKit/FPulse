//
//	UFmdt_Utils.c -- Utility routines 
//


// ANSI headers IgorXOP.h XOP.h XOPSupport.h
#include "\Programme\wavemetrics\IgorXOPs\XOPSupport\XOPStandardHeaders.h"

#include "UFmdt_Utils.h"
#include "XopMain.h"

#pragma pack(2)					// All structures are 4-byte-aligned. // for MCTG 4 instead of 2


// Forward declarations


// Global Variables (none) 

// 070223
//int UFmdt_UtilGetSystemDirectory(void * );  //

int UFmdt_UtilConvolve(				void * );  // 
int UFmdt_UtilWaveCopy(				void * );  // 
int UFmdt_UtilWaveExtract(			void * );  // 
int UFmdt_UtilRealWaveSet(			void * );  // 
int UFmdt_UtilRealWaveMultiply(	void * );  // 
int UFmdt_UtilRealWaveMultiplyAdd(void * );  // 
//int UFmdt_UtilCorrelation_(		void * );  // 
int UFmdt_UtilCorrelation(			void * );  // 
int UFmdt_UtilFileDialog(			void * );  // 
//int UFmdt_UtilIsValidString(		void * );  //
int UFmdt_UtilMemoryLoad(			void * );  //
int UFmdt_UtilTotalPhys(			void * );  //
int UFmdt_UtilAvailPhys(			void * );  //
int UFmdt_UtilTotalVirtual(		void * );  //
int UFmdt_UtilAvailVirtual(		void * );  //
int UFmdt_UtilContiguousMemory(	void * );  //
int UFmdt_UtilHeapCompact(			void * );  //


/////////////////////////////////////////////////////////////////////////////////////////

// SAME ORDER HERE IN  '(*sFunc[])' AND IN UFmdt_UtilsWinCustom.RC

FUNC sFunc[] =
  //  Der Name der      Direct Call method
  //  Funktion          or Message method	   Used that often
{
// 070223
//	{ UFmdt_UtilGetSystemDirectory		},		

	{ UFmdt_UtilConvolve						},
	{ UFmdt_UtilWaveCopy						},
	{ UFmdt_UtilWaveExtract					},
	{ UFmdt_UtilRealWaveSet					},
	{ UFmdt_UtilRealWaveMultiply			},
	{ UFmdt_UtilRealWaveMultiplyAdd		},
//	{ UFmdt_UtilCorrelation_				},
	{ UFmdt_UtilCorrelation					},
	{ UFmdt_UtilFileDialog					},
//	{ UFmdt_UtilIsValidString				},
	{ UFmdt_UtilMemoryLoad					},		
	{ UFmdt_UtilTotalPhys					},		
	{ UFmdt_UtilAvailPhys					},		
	{ UFmdt_UtilTotalVirtual				},		
	{ UFmdt_UtilAvailVirtual				},		
	{ UFmdt_UtilContiguousMemory			},		
	{ UFmdt_UtilHeapCompact					},

   {    NULL       }  // Endemarkierung
};

////////////////////////////////////////////////////////////////////////



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
// UFmdt_Util - UTILITIES

// 070223
/*
int 	UFmdt_UtilGetSystemDirectory( struct { Handle sRes; }* p)
{
	char			errbuf[MAX_PATH + 100];
	char			sDirPath[MAX_PATH + 20];
   int			len, err	= 0;
   Handle		str1		= NIL;
	
	GetSystemDirectory( sDirPath, MAX_PATH );		// Get the Windows\system path 

   len = strlen( sDirPath );
   if (( str1 = NewHandle( len )) == NIL )		// get output handle, do not provide space for '\0' 
   {
      sprintf( errbuf, "++++Error: UFmdt_UtilGetSystemDirectory() Not enough memory. Aborted...\r");
      XOPNotice( errbuf );
      err = NOMEM;										// out of memory
   }
   else														// string length is OK so return string 
      memcpy( *str1, sDirPath, len );				// copy local temporary buffer to persistent Igor output string
 
	sprintf( errbuf, "UFmdt_UtilGetSystemDirectory [len:%d]:  '%s' \r", len, sDirPath ); XOPNotice( errbuf );  
   p->sRes = str1;
   return err;
}
*/

#define DADIREC   0
#define ADDIREC   1

int UFmdt_UtilConvolve( struct {	double bStoreIt; double	nPnts; double	nChan; double	nChunk; double	nCompress; 
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

	//DebugPrintWaveProperties( "UFmdt_UtilConvolve   ", p->wRaw );		// 050128
	//DebugPrintWaveProperties( "UFmdt_UtilConvolve   ", p->wBigWave ); // 050128

   if ( p->wBigWave == NIL || p->wRaw == NIL )// check if wave handle is valid
   {
      sprintf( errBuf, "++++Error: UFmdt_UtilConvolve() received nonvalid wave \r" );
		XOPNotice( errBuf );
	   SetNaN64( &p->res );							// return NaN if wave is not valid   
	   return( NON_EXISTENT_WAVE );
   }
   if ( WaveType(p->wRaw)!= NT_I16 )			// check wave's numeric type  
   {
    	sprintf( errBuf, "++++Error: UFmdt_UtilConvolve() received non integer wave \r" );
		XOPNotice( errBuf );
	   SetNaN64( &p->res );							// return NaN if wave is not 2Byte int
      return( IS_NOT_2BYTE_INT_WAVE );
   }
   if ( WaveType(p->wBigWave )!= NT_FP32 )	// check wave's numeric type  
   {
    	sprintf( errBuf, "++++Error: UFmdt_UtilConvolve() received non float wave (4Byte) for wBigWave \r" );
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
				sprintf( buf, "\t\tUFmdt_UtilConvolve() \tDACs \t\tBeg/End\t%8d\t\t\tPt written:\t%8d\t\t\t\t\tDAIndex:\t%8d \r",
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
						sprintf( buf, "\t\tUFmdt_UtilConvolve() \tTrueADda\tBegPt:\t%8d\t\t\t\t\t\t FirstPt written:\t%8d\t \r", begPt, pt1 );
						XOPNotice( buf );
					}
					*/
				}
			}
			/* 050128
			sprintf( buf, "\t\tUFmdt_UtilConvolve() \tTrueADda\tEndPt:\t%8d\t\t\t\t\t\t Last Pt written:\t%8d\tInt?\t%8.3lf\tRdIndex:\t%8d \r",
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
						sprintf( buf, "\t\tUFmdt_UtilConvolve() \tcompress:%2d\tnPnts:\t%8d\tOrgPt:\t%8d\tPoint:\t%8d\tPt/Co(=written):\t%8d\tRawIdx(=read):\t%8d\tStoreIt:%2d\t  \r",
											nCompress,nPnts, pt+repOs, pt1, nBigWvIdx, nRawIdx, bStoreIt );
						XOPNotice( buf );
					}
					*/
					// Informs about a very nasty sporadic error. TG wave was just 1 too short, should now be OK: 050128
					if ( nRawIdx < 0  || nRawIdx >= nRawPts )
					{
						sprintf( buf, "++++Error\t\tUFmdt_UtilConvolve() Indices:   %d <= %d < %d ??? \r", 0, nRawIdx, nRawPts );
						XOPNotice( buf );
					}
					if ( nBigWvIdx < 0 || nBigWvIdx >= nBigWvPts )
					{
						sprintf( buf, "++++Error\t\tUFmdt_UtilConvolve() Indices:   %d <= %d < %d ??? \r", 0, nBigWvIdx, nBigWvPts );
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
						sprintf( buf, "\t\tUFmdt_UtilConvolve() \tcompress:%2d\tBegPt:\t%8d\t  EPt/Comp:\t%8d\t FirstPt written:\t%8d\t \r",
											nCompress, begPt, endPt/nCompress, pt1 / nCompress );
						XOPNotice( buf );
					}
					*/
				}
			}

			/* 050128
			sprintf( buf, "\t\tUFmdt_UtilConvolve() \tcompress:%2d\tEndPt:\t%8d\t  EPt/Comp:\t%8d\t Last Pt written:\t%8d\tInt?\t%8.3lf\tRdIndex:\t%8d \r",
									nCompress, endPt, endPt/nCompress, pt1 / nCompress, (double)PtsPerChunk / nCompress, nRawIdx );
			XOPNotice( buf );
			*/
		}
	}

	p->res = 0;
	return   0;                           // ..we don't want IGOR to do anything with the error (no error box, no debugger)
}

	
int UFmdt_UtilWaveCopy( struct { double scl; double nSourceOfs; double nPnts; waveHndl wFloatSource; waveHndl wIntTarget; double res; }* p)
// XOP because IGOR itself is too slow..
{
   long      nSourceOfs  = (long)p->nSourceOfs;
   long      nPnts       = (long)p->nPnts;
   long      i;
   char      errBuf[100]; 
   short    *wIntTarget;   
   float    *wFloatSource;   

	// DebugPrintWaveProperties( "UFmdt_UtilWaveCopy  ", p->wFloatSource );	// 050128
	// DebugPrintWaveProperties( "UFmdt_UtilWaveCopy  ", p->wIntTarget );		// 050128

   if ( p->wIntTarget == NIL || p->wFloatSource == NIL )                // check if wave handle is valid
   {
      sprintf( errBuf, "++++Error: UFmdt_UtilWaveCopy() received nonvalid wave \r" );
		XOPNotice( errBuf );
	   SetNaN64( &p->res );								// return NaN if wave is not valid   
	   return( NON_EXISTENT_WAVE );
   }
   if ( WaveType(p->wIntTarget)!= NT_I16 )		// check wave's numeric type  
   {
    	sprintf( errBuf, "++++Error: UFmdt_UtilWaveCopy() received non integer wave ( 2Byte) for wIntTarget \r" );
		XOPNotice( errBuf );
	   SetNaN64( &p->res );								// return NaN if wave is not 2Byte int
      return( IS_NOT_2BYTE_INT_WAVE );
   }

   if ( WaveType(p->wFloatSource )!= NT_FP32 )	// check wave's numeric type  
   {
    	sprintf( errBuf, "++++Error: UFmdt_UtilWaveCopy() received non float wave (4Byte) for wFloatSource \r" );
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


int UFmdt_UtilWaveExtract( struct { double scl; double nStep; double nSourceOfs; double nPnts; waveHndl wFloatSource; waveHndl wFloatTarget; double res; }* p)
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

	// DebugPrintWaveProperties( "UFmdt_UtilWaveExtract", p->wFloatSource ); // 050128
	// DebugPrintWaveProperties( "UFmdt_UtilWaveExtract", p->wFloatTarget ); // 050128

   if ( p->wFloatTarget == NIL || p->wFloatSource == NIL )  // check if wave handle is valid
   {
      sprintf( errBuf, "++++Error: UFmdt_UtilWaveExtract() received nonvalid wave \r" );
		XOPNotice( errBuf );
	   SetNaN64( &p->res );									// return NaN if wave is not valid   
	   return( NON_EXISTENT_WAVE );
   }
   if ( WaveType(p->wFloatTarget)!= NT_FP32 )		// check wave's numeric type  
   {
    	sprintf( errBuf, "++++Error: UFmdt_UtilWaveExtract() received non float wave ( 4Byte) for wFloatTarget \r" );
		XOPNotice( errBuf );
	   SetNaN64( &p->res );									// return NaN if wave is not 2Byte int
      return( IS_NOT_4BYTE_FLOAT_WAVE );	
   }

   if ( WaveType(p->wFloatSource )!= NT_FP32 )		// check wave's numeric type  
   {
    	sprintf( errBuf, "++++Error: UFmdt_UtilWaveExtract() received non float wave (4Byte) for wFloatSource \r" );
		XOPNotice( errBuf );
	   SetNaN64( &p->res );									// return NaN if wave is not 4Byte float
      return( IS_NOT_4BYTE_FLOAT_WAVE );
   }

   wFloatTarget	= WaveData( p->wFloatTarget );	//  char pointer to IGOR wave data 
   wFloatSource	= WaveData( p->wFloatSource );	//  char pointer to IGOR wave data 


	//for ( i = 0; i <  nPnts;			i += nStep ) {	// WRONG: wFloat tries to right into the next after the LAST element...which crashes
	for ( i = 0; i <= nPnts - nStep;	i += nStep ) {
		//sprintf( bf, "\tUFmdt_UtilWaveExtract()\tpts:\t%7d\tos:\t%7d\tstp:\t%7d\tscl:\t%10.4lf\ti:\t%7d\tItg:\t%7d\tIsc:\t%7d\t \r", 
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





int UFmdt_UtilRealWaveSet( struct { double value; double nEnd; double nBeg; waveHndl wFloatTarget; double res; }* p)
// XOP because IGOR itself is too slow..
{
   long      nBeg  = (long)p->nBeg;
   long      nEnd  = (long)p->nEnd;
   long      i;
   char      errBuf[100]; 
   float    *wFloatTarget;   

	// DebugPrintWaveProperties( "UFmdt_UtilRealWaveSet", p->wFloatTarget ); 	// 050128

   if ( p->wFloatTarget == NIL )                // check if wave handle is valid
   {
      sprintf( errBuf, "++++Error: UFmdt_UtilRealWaveSet() received nonvalid wave \r" );
		XOPNotice( errBuf );
	   SetNaN64( &p->res );								// return NaN if wave is not valid   
	   return( NON_EXISTENT_WAVE );
   }
   if ( WaveType(p->wFloatTarget )!= NT_FP32 )	// check wave's numeric type  
   {
    	sprintf( errBuf, "++++Error: UFmdt_UtilRealWaveSet() received non float wave (4Byte) for wFloatTarget \r" );
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


int UFmdt_UtilRealWaveMultiply( struct { waveHndl wFloatTgt; double nPts; double nBeg2; waveHndl wFloatSrc2; double nBeg1; waveHndl wFloatSrc1; double res; }* p)
// Multiply  wFloatSrc1[ nBeg1, nBeg1 + nPts -1 ]  by  wFloatSrc2[ nBeg2, nBeg2 + nPts -1 ]  and  pass back  all products in wFloatTgt.
// XOP because IGOR itself is too slow..
{
   long      nBeg1 = (long)p->nBeg1;
   long      nBeg2 = (long)p->nBeg2;
   long      nPts  = (long)p->nPts;
   long      i;
   char      errBuf[200]; 
   float    *wFloatSrc1, *wFloatSrc2, *wFloatTgt;   

	// DebugPrintWaveProperties( "UFmdt_UtilRealWaveMultiply", p->wFloatSrc1 ); 	// 050128
	// DebugPrintWaveProperties( "UFmdt_UtilRealWaveMultiply", p->wFloatSrc2 ); 	// 050128

   if ( p->wFloatSrc1 == NIL  ||  p->wFloatSrc2 == NIL ||  p->wFloatTgt == NIL )	// check if wave handles are valid
   {
      sprintf( errBuf, "++++Error: UFmdt_UtilRealWaveMultiply() received nonvalid wave \r" );
		XOPNotice( errBuf );
	   SetNaN64( &p->res );								// return NaN if wave is not valid   
	   return( NON_EXISTENT_WAVE );
   }
   if ( WaveType(p->wFloatSrc1 )!= NT_FP32  ||  WaveType(p->wFloatSrc2 )!= NT_FP32 ||  WaveType(p->wFloatTgt )!= NT_FP32 )	// check wave's numeric type  
   {
    	sprintf( errBuf, "++++Error: UFmdt_UtilRealWaveMultiply() received non float wave (4Byte) for source or target wave \r" );
		XOPNotice( errBuf );
	   SetNaN64( &p->res );								// return NaN if wave is not 4Byte float
      return( IS_NOT_4BYTE_FLOAT_WAVE );
   }

   wFloatSrc1 = WaveData( p->wFloatSrc1 );		//  char pointer to IGOR wave data 
   wFloatSrc2 = WaveData( p->wFloatSrc2 );		//  char pointer to IGOR wave data 
   wFloatTgt  = WaveData( p->wFloatTgt  );		//  char pointer to IGOR wave data 
   
	for ( i = 0; i < nPts; i += 1)
		wFloatTgt[ i ] = wFloatSrc1[ i + nBeg1 ] * wFloatSrc2[ i + nBeg2 ]; 
	
	p->res = 0;
   return   0;										      // ..we don't want IGOR to do anything with the error (no error box, no debugger)
}


int UFmdt_UtilRealWaveMultiplyAdd( struct { double nPts; double nBeg2; waveHndl wFloatSrc2; double nBeg1; waveHndl wFloatSrc1; double res; }* p)
// Multiply  wFloatSrc1[ nBeg1, nBeg1 + nPts -1 ]  by  wFloatSrc2[ nBeg2, nBeg2 + nPts -1 ]  and add all products.  Return this sum.
// XOP because IGOR itself is too slow..
{
   long      nBeg1 = (long)p->nBeg1;
   long      nBeg2 = (long)p->nBeg2;
   long      nPts  = (long)p->nPts;
   long      i;
   char      errBuf[100]; 
   float    *wFloatSrc1, *wFloatSrc2;   
	double	sum	= 0.;

	// DebugPrintWaveProperties( "UFmdt_UtilRealWaveMultiplyAdd", p->wFloatSrc1 ); 	// 050128
	// DebugPrintWaveProperties( "UFmdt_UtilRealWaveMultiplyAdd", p->wFloatSrc2 ); 	// 050128

   if ( p->wFloatSrc1 == NIL  ||  p->wFloatSrc2 == NIL )	// check if wave handles are valid
   {
      sprintf( errBuf, "++++Error: UFmdt_UtilRealWaveMultiplyAdd() received nonvalid wave \r" );
		XOPNotice( errBuf );
	   SetNaN64( &p->res );								// return NaN if wave is not valid   
	   return( NON_EXISTENT_WAVE );
   }
   if ( WaveType(p->wFloatSrc1 )!= NT_FP32  ||  WaveType(p->wFloatSrc2 )!= NT_FP32 )	// check wave's numeric type  
   {
    	sprintf( errBuf, "++++Error: UFmdt_UtilRealWaveMultiplyAdd() received non float wave (4Byte) for source wave \r" );
		XOPNotice( errBuf );
	   SetNaN64( &p->res );								// return NaN if wave is not 4Byte float
      return( IS_NOT_4BYTE_FLOAT_WAVE );
   }

   wFloatSrc1 = WaveData( p->wFloatSrc1 );	//  char pointer to IGOR wave data 
   wFloatSrc2 = WaveData( p->wFloatSrc2 );	//  char pointer to IGOR wave data 
   
	for ( i = 0; i < nPts; i += 1)
		sum += wFloatSrc1[ i + nBeg1 ] * wFloatSrc2[ i + nBeg2 ]; 
	
	p->res = sum;
   return   0;										      // ..we don't want IGOR to do anything with the error (no error box, no debugger)
}


// Order of values in wSums .   !!! Must be the same in  UF_MiniDetection.ipf  and in  UFmdt_Utils.c
#define	kMD_SumX		0
#define	kMD_SumX2	1
#define	kMD_SumY		2
#define	kMD_SumY2	3

/*
// Includes initialisation -> Only 1 line in Igor.   Big drawback: NO progressbar possible.

int UFmdt_UtilCorrelation_( struct { double nPrintIt; waveHndl wCorr; waveHndl wSums; double nTPts; waveHndl wTempl; double nDPts; waveHndl wData; double res; }* p)
// XOP because IGOR itself is too slow..
{
   long      nDPts	= (long)p->nDPts;
   long      nTPts	= (long)p->nTPts;
   long      nPrintIt= (long)p->nPrintIt;
	long		 MaskStart;
   long      i;
   long      n			= 0;
   char      errBuf[400]; 
   float    *wData, *wTempl, *wSums, *wCorr;   

	double	SumXY	= 0, SP = 0,  SQX = 0,  SQY = 0;
	double	B	= 0;		// steepness
	double	A	= 0;		// offset
	double	r	= 0;		// correlation
	// DebugPrintWaveProperties( "UFmdt_UtilCorrelation_  ", p->wData );		// 050128
	// DebugPrintWaveProperties( "UFmdt_UtilCorrelation_  ", p->wTemplate );	// 050128

   if ( p->wData == NIL || p->wTempl == NIL || p->wSums == NIL || p->wCorr == NIL )                // check if wave handle is valid
   {
      sprintf( errBuf, "++++Error: UFmdt_UtilCorrelation_() received nonvalid wave \r" );
		XOPNotice( errBuf );
	   SetNaN64( &p->res );								// return NaN if wave is not valid   
	   return( NON_EXISTENT_WAVE );
   }

   if ( WaveType(p->wData)!= NT_FP32 || WaveType(p->wTempl)!= NT_FP32 || WaveType(p->wSums)!= NT_FP32 || WaveType(p->wCorr)!= NT_FP32 )	// check wave's numeric type  
   {
    	sprintf( errBuf, "++++Error: UFmdt_UtilCorrelation_() received non float wave (4Byte) for wData, wTempl, wSums or wCorr \r" );
		XOPNotice( errBuf );
	   SetNaN64( &p->res );								// return NaN if wave is not 4Byte float
      return( IS_NOT_4BYTE_FLOAT_WAVE );
   }

   wData		= WaveData( p->wData );				//  char pointer to IGOR wave data 
   wTempl	= WaveData( p->wTempl );			//  char pointer to IGOR wave data 
	wSums		= WaveData( p->wSums );				//  char pointer to IGOR wave data 
	wCorr		= WaveData( p->wCorr );				//  char pointer to IGOR wave data 
 

	MaskStart	= (long)wSums[ kMD_MaskStart ];


	SpinProcess();		// (should???) spin the beachball cursor (and should also return non-zero value if the user pressed Ctrl-Break; this is not  evaluated here)


	// Correlation Initialisation
	n		= 0 ;
	SumXY	= 0.;
	for ( i = 0; i < nTPts; i += 1 ) {
		wSums[ kMD_SumY ]		+= wData[ i + n ];
		wSums[ kMD_SumY2 ]	+= wData[ i + n ] * wData[ i + n ];
		SumXY						+=						wTempl[ i ] * wData[ i + n ];
		if ( nPrintIt && ( i < 5 || i % 100 == 0 ) ) {
			sprintf( errBuf, "\tUFmdt_UtilCorrelation_ Initialising\tT:%3d/%6d  D:%6d/%6d  MSt:%d  SumX:%g  SumY:%g  SumXY:%g  %g  %g  %g  %g  %g r:%g \r", i, nTPts, n, nDPts, MaskStart, wSums[ kMD_SumX ], wSums[ kMD_SumY ], SumXY, SP, SQX, SQY, B, A, r );
			XOPNotice( errBuf );
		}
	}
	SP		= SumXY 						- ( wSums[ kMD_SumX ] * wSums[ kMD_SumY ] ) / nTPts;
	SQX	= wSums[ kMD_SumX2 ] 	- ( wSums[ kMD_SumX ] * wSums[ kMD_SumX ] ) / nTPts;
	SQY	= wSums[ kMD_SumY2 ] 	- ( wSums[ kMD_SumY ] * wSums[ kMD_SumY ] ) / nTPts;
	B		= SP / SQX;																		// this is steepness 
	A		= wSums[ kMD_SumY ] / nTPts - B * wSums[ kMD_SumX ] / nTPts;	// this is offset 
	r		= ( SQY > 0 )  ?  SP / sqrt( SQX * SQY )  :  0. ;					// correlation coefficient, Careful:  the variance of Y may be 0 and program may crash 

	wCorr[ MaskStart + n ]	= r;	

	
	// Correlation Main Computation
	for ( n = 0; n < nDPts - nTPts; n += 1 ) {
		if ( n > 0 ) {
			wSums[ kMD_SumY ]	+= ( wData[ n + nTPts - 1 ] - wData[ n - 1 ] ); 	// delete the first point from i loop with previous n and add the last point from i loop with this n 
			wSums[ kMD_SumY2 ]+= ( wData[ n + nTPts - 1 ] * wData[ n + nTPts - 1 ] - wData[ n - 1] * wData[ n - 1 ] );
		}

		SumXY	= 0.;
		for ( i = 0; i < nTPts; i += 1) {
			SumXY += wData[ i + n ] * wTempl[ i ]; 
			if (  nPrintIt && i < 3 && n%10000 == 0 ) {
				sprintf( errBuf, "\tUFmdt_UtilCorrelation_ Computing..\tT:%3d/%6d  D:%6d/%6d  MSt:%d  SumX:%g  SumY:%g  SumXY:%g  %g  %g  %g  %g  %g r:%g \r", i, nTPts, n, nDPts, MaskStart, wSums[ kMD_SumX ], wSums[ kMD_SumY ], SumXY, SP, SQX, SQY, B, A, r );
				XOPNotice( errBuf );
			}	
		}

		SP		= SumXY 						- ( wSums[ kMD_SumX ] * wSums[ kMD_SumY ] ) / nTPts;
		SQX	= wSums[ kMD_SumX2 ] 	- ( wSums[ kMD_SumX ] * wSums[ kMD_SumX ] ) / nTPts;
		SQY	= wSums[ kMD_SumY2 ] 	- ( wSums[ kMD_SumY ] * wSums[ kMD_SumY ] ) / nTPts;
		B		= SP / SQX;																	// this is steepness 
		A		= wSums[ kMD_SumY ] / nTPts - B * wSums[ kMD_SumX ] / nTPts;// this is offset 
		r		= ( SQY > 0 )  ?  SP / sqrt( SQX * SQY )  :  0. ;				// correlation coefficient, Careful:  the variance of Y may be 0 and program may crash 
	
		wCorr[ MaskStart + n ] = r;	
	}

	p->res = 0;
   return   0;												// ..we don't want IGOR to do anything with the error (no error box, no debugger)
}		
*/

int UFmdt_UtilCorrelation( struct { double nEnd; double nBeg; double nPrintIt; waveHndl wCorr; waveHndl wSums; double nMaskStart;  double nTPts; waveHndl wTempl; waveHndl wData; double res; }* p)
// XOP because IGOR itself is too slow..
{
   long      nTPts		= (long)p->nTPts;
   long      nMaskStart	= (long)p->nMaskStart;
   long      nPrintIt	= (long)p->nPrintIt;
	long      nBeg			= (long)p->nBeg;
	long      nEnd			= (long)p->nEnd;
   long      i;
   long      n				= 0;
   char      errBuf[300]; 
   float    *wData, *wTempl, *wSums, *wCorr;   

	double	SumXY	= 0, SP = 0,  SQX = 0,  SQY = 0;
	double	B	= 0;		// steepness
	double	A	= 0;		// offset
	double	r	= 0;		// correlation
	// DebugPrintWaveProperties( "UFmdt_UtilCorrelation  ", p->wData );		// 050128
	// DebugPrintWaveProperties( "UFmdt_UtilCorrelation  ", p->wTemplate );	// 050128

   if ( p->wData == NIL || p->wTempl == NIL || p->wSums == NIL || p->wCorr == NIL )                // check if wave handle is valid
   {
      sprintf( errBuf, "++++Error: UFmdt_UtilCorrelation() received nonvalid wave \r" );
		XOPNotice( errBuf );
	   SetNaN64( &p->res );								// return NaN if wave is not valid   
	   return( NON_EXISTENT_WAVE );
   }

   if ( WaveType(p->wData)!= NT_FP32 || WaveType(p->wTempl)!= NT_FP32 || WaveType(p->wSums)!= NT_FP32 || WaveType(p->wCorr)!= NT_FP32 )	// check wave's numeric type  
   {
    	sprintf( errBuf, "++++Error: UFmdt_UtilCorrelation() received non float wave (4Byte) for wData, wTempl, wSums or wCorr \r" );
		XOPNotice( errBuf );
	   SetNaN64( &p->res );								// return NaN if wave is not 4Byte float
      return( IS_NOT_4BYTE_FLOAT_WAVE );
   }

   wData		= WaveData( p->wData );				//  char pointer to IGOR wave data 
   wTempl	= WaveData( p->wTempl );			//  char pointer to IGOR wave data 
	wSums		= WaveData( p->wSums );				//  char pointer to IGOR wave data 
	wCorr		= WaveData( p->wCorr );				//  char pointer to IGOR wave data 
 

//	MaskStart	= (long)wSums[ kMD_MaskStart ];

	// Correlation Main Computation
	for ( n = nBeg; n < nEnd; n += 1 ) {
		if ( n > 0 ) {
			wSums[ kMD_SumY ]	+= ( wData[ n + nTPts - 1 ] - wData[ n - 1 ] ); 	// delete the first point from i loop with previous n and add the last point from i loop with this n 
			wSums[ kMD_SumY2 ]+= ( wData[ n + nTPts - 1 ] * wData[ n + nTPts - 1 ] - wData[ n - 1] * wData[ n - 1 ] );
		}

		SumXY	= 0.;
		for ( i = 0; i < nTPts; i += 1) {
			SumXY += wData[ i + n ] * wTempl[ i ]; 
			if (  nPrintIt == 1  && i < 3 && n%10000 == 0 ) {
				sprintf( errBuf, "\tUFmdt_UtilCorrelation Computing..\tT:%3d/%6d  D:%6d...%6d...%6d  MSt:%d  SumX:%g  SumY:%g  SumXY:%g  %g  %g  %g  %g  %g r:%g \r", 
																					i, nTPts, nBeg, n, nEnd, nMaskStart, wSums[ kMD_SumX ], wSums[ kMD_SumY ],	SumXY, SP, SQX, SQY, B, A, r );
				XOPNotice( errBuf );
			}	
		}

		SP		= SumXY 						- ( wSums[ kMD_SumX ] * wSums[ kMD_SumY ] ) / nTPts;
		SQX	= wSums[ kMD_SumX2 ] 	- ( wSums[ kMD_SumX ] * wSums[ kMD_SumX ] ) / nTPts;
		SQY	= wSums[ kMD_SumY2 ] 	- ( wSums[ kMD_SumY ] * wSums[ kMD_SumY ] ) / nTPts;
		B		= SP / SQX;																	// this is steepness 
		A		= wSums[ kMD_SumY ] / nTPts - B * wSums[ kMD_SumX ] / nTPts;// this is offset 
		r		= ( SQY > 0 )  ?  SP / sqrt( SQX * SQY )  :  0. ;				// correlation coefficient, Careful:  the variance of Y may be 0 and program may crash 
	
		wCorr[ nMaskStart + n ] =  r;	

		if (  nPrintIt == 2  &&  57300 < n  &&  n < 57500 ) {
			sprintf( errBuf, "\tUFmdt_UtilCorrelation Computing..\tD:%6d...%6d...%6d  MSt:%d  X:%g  X2:%g\tSY:\t%8.1g\tSY2:\t%10.2g\tSumXY:%g\tSP:\t%g\tSQX:\t%g\tSQY:\t%g\tB:\t%g\tA:\t%g\tr:\t%g \r", 
																				nBeg, n, nEnd, nMaskStart, wSums[ kMD_SumX ], wSums[ kMD_SumX2 ], wSums[ kMD_SumY ], wSums[ kMD_SumY2 ],	SumXY, SP, SQX, SQY, B, A, r );
			XOPNotice( errBuf );
		}	
	}

	p->res = 0;
   return   0;												// ..we don't want IGOR to do anything with the error (no error box, no debugger)
}		



//---------------------------------------------------------------------------------------------------------------------------------

#define	csREADMODE	"cREADMODE"								// must be the same in XOP  and in IGOR
  
int UFmdt_UtilFileDialog( struct { Handle FilePath; Handle DefExt; Handle InitDir; double Index; Handle Filter; Handle Prompt; Handle ReturnFilePath; }* p)
// Advantage 1 :	IGOR's command 'Open  /D...' is much simpler but not truely capable of selecting directories..
//						..because there seems to be no way to blank out files , which are confusing to the user
//						To select a directory call from IGOR like : gsDataPath = UFmdt_UtilFileDialog( "Select directory" , "Directories; ;;" ,  1, sPath,  "", "_" )	
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
	//sprintf ( errbuf, "\t\t\tUFmdt_UtilFileDialog(2) \tn:%2d lenFilter:%d\t'%s'  \r", n , lenFilter, *(p->Filter)  );	XOPNotice( errbuf );

   strFilter = IHC( p->Filter );
	//sprintf ( errbuf, "\t\t\tUFmdt_UtilFileDialog(3) \tstrFilter: \t\t'%s'   Index:%d \r", *strFilter, Index );	XOPNotice( errbuf );

   strInitDir = IHC( p->InitDir );
	//sprintf ( errbuf, "\t\t\tUFmdt_UtilFileDialog(4) \tstrInitDir: \t\t'%s' \r", *strInitDir );	XOPNotice( errbuf );

		
	// if we would use strInitDir (Mac syntax e.g.'C:Dir1:' ) instead of nativeInitDir, the dialog box would not accept it as a legal path and reset...
	GetNativePath( *strInitDir, nativeInitDir );		// convert to windows path (IGOR prefers Mac path syntax)
	//sprintf ( errbuf, "\t\t\tUFmdt_UtilFileDialog(5) \tnativeInitDir:\t\t'%s' \r", nativeInitDir );	XOPNotice( errbuf );
   strDefExt = IHC( p->DefExt );

	bReadMode	= !strcmp( *strDefExt, csREADMODE );
	//sprintf ( errbuf, "\t\t\tUFmdt_UtilFileDialog(6) \tstrDefExt: \t\t'%s' -> ReadMode:%2d \r", *strDefExt, bReadMode );	XOPNotice( errbuf );

   strFilePath = IHC( p->FilePath );
  //sprintf ( errbuf, "\t\t\tUFmdt_UtilFileDialog(7) \tstrFilePath:\t\t'%s' \r", *strFilePath );	XOPNotice( errbuf );

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
		sprintf( errbuf, "++++Error: UFmdt_UtilFileDialog() Not enough memory. Aborted...\r");
	   XOPNotice( errbuf );
		err = NOMEM;											// out of memory
	}
	else															// string length is OK so return string 
	{
		memcpy( *strReturnFilePath, TmpReturnFilePath, lenReturnFilePath );       // copy local temporary buffer WITHOUT \0 to persistent Igor output string 
	}
	p->ReturnFilePath = strReturnFilePath;				// this filepath string is returned to IGOR

	// strReturnFilePath' cannot be printed safely because it has no string end '\0'
	// XOPNotice( "\tUFmdt_UtilFileDialog() Out: strReturnFilePath:'" );	XOPNotice( *strReturnFilePath );	XOPNotice( "'\r" );

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


// 070329 WORKS (=detects NULL pointer) but does not avoid Igors error 'invalid string...' so it is useless
/*
#int 	UFmdt_UtilIsValidString( struct { Handle IsValidString; double res; }* p)
// Returns TRUE if 'IsValidString'  is the NULL pointer
{
	if ( !p->IsValidString )		// error:  input string does not exist == is NULL pointer
		p->res	= 0.;
	else
		p->res	= 1.;
	
   return 0;						    // 0 = OK, sonst XFunc error code 
}
*/


int 	UFmdt_UtilMemoryLoad( struct { double res; }* p)
// From MSVC Knowledge base, HOWTO: Determine the Amount of Physical Memory Installed, Article ID: Q117889  
{
	MEMORYSTATUS MemoryStatus;

   memset( &MemoryStatus, sizeof(MEMORYSTATUS), 0 );
   MemoryStatus.dwLength = sizeof(MEMORYSTATUS);

   GlobalMemoryStatus( &MemoryStatus );

   p->res = (double)MemoryStatus.dwMemoryLoad;
   return   0;		
}


int 	UFmdt_UtilTotalPhys( struct { double res; }* p)
// From MSVC Knowledge base, HOWTO: Determine the Amount of Physical Memory Installed, Article ID: Q117889  
{
	MEMORYSTATUS MemoryStatus;

   memset( &MemoryStatus, sizeof(MEMORYSTATUS), 0 );
   MemoryStatus.dwLength = sizeof(MEMORYSTATUS);

   GlobalMemoryStatus( &MemoryStatus );

   p->res = (double)MemoryStatus.dwTotalPhys;
   return   0;	
}


int 	UFmdt_UtilAvailPhys( struct { double res; }* p)
// From MSVC Knowledge base, HOWTO: Determine the Amount of Physical Memory Installed, Article ID: Q117889  
{
	MEMORYSTATUS MemoryStatus;

   memset( &MemoryStatus, sizeof(MEMORYSTATUS), 0 );
   MemoryStatus.dwLength = sizeof(MEMORYSTATUS);

   GlobalMemoryStatus( &MemoryStatus );

   p->res = (double)MemoryStatus.dwAvailPhys;
   return   0;											
}


int 	UFmdt_UtilTotalVirtual( struct { double res; }* p)
// From MSVC Knowledge base, HOWTO: Determine the Amount of Physical Memory Installed, Article ID: Q117889  
{
	MEMORYSTATUS MemoryStatus;

   memset( &MemoryStatus, sizeof(MEMORYSTATUS), 0 );
   MemoryStatus.dwLength = sizeof(MEMORYSTATUS);

   GlobalMemoryStatus( &MemoryStatus );

   p->res = (double)MemoryStatus.dwTotalVirtual;
   return   0;											
}


int 	UFmdt_UtilAvailVirtual( struct { double res; }* p)
// From MSVC Knowledge base, HOWTO: Determine the Amount of Physical Memory Installed, Article ID: Q117889  
{
	MEMORYSTATUS MemoryStatus;

   memset( &MemoryStatus, sizeof(MEMORYSTATUS), 0 );
   MemoryStatus.dwLength = sizeof(MEMORYSTATUS);

   GlobalMemoryStatus( &MemoryStatus );

   p->res = (double)MemoryStatus.dwAvailVirtual;
   return   0;											
}


int 	UFmdt_UtilContiguousMemory( struct { double nBytes; double res; }* p)
// Check if 'nBytes' can be allocated in a contiguous memory as waves need it. 'Make' cannot be used as it issues an error box when failing.
{
	waveHndl		waveHndPtr;
	char			*WaveNm		= "UF_Temp_UFmdt_UtilContiguousMemCheck";
   int			nType			= NT_FP32;					// arbitrary, make 4-byte wave
	long	      nPnts       = (long)p->nBytes / 4;	// assume			 4-byte wave
	int			bOverWrite	= TRUE;
	int			code;
	// char		errbuf[200];
	if ( ( code = MakeWave( &waveHndPtr, WaveNm, nPnts, nType, bOverWrite ) ) == 0 ) {
		KillWave( waveHndPtr );
	}
	// sprintf( errbuf, "UFmdt_UtilContiguousMemory( MegaPts: %.6lf ) returns %d (0=OK, 1=Fail)\r", nPnts * 4 / 1e6, code ); 
	// XOPNotice( errbuf ); 
	p->res = code;
   return   0;		
}


// 060206  does not work: does no compacting and returns always 638976 bytes
int 	UFmdt_UtilHeapCompact( struct { double res; }* p)
{
	HANDLE	hHeap			= GetProcessHeap();
	UINT		nHeapSize	= HeapCompact( hHeap, 0 );
   p->res = (double)nHeapSize;
   return   0;	
}



#pragma pack()    // All structures are 2-byte-aligned.


