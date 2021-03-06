//
// FPulseCfs.C
// CFS interface in IGOR
//
// UF 11.01
//
// Revision history
//
// Error handling in CFS and in XOPs:
// - the return value of the XOP determines the reaction of IGOR: 0 means OK = no reaction, other value means Error box and Debugger
// - the value passed in p->result is passed as (a second!) return value to the Igor calling function and can be ignored or handled there
// - the CFS functions return 0 for no error or an error code. The FileError() functions gives details of the error.

// To print only into the command window (NON CFS functions):
//  - from within the XOP: print with XOPNotice(), then return 0 from the XOP
//  - from IGOR user function: set p->result to the error code, return 0 from the XOP and check the return value of the XOP

// To print only into the command window ( CFS functions)
//  - from within the XOP: not a good solution....
//  - from IGOR user function: use PrintFileError(WND) after every CFS function (gives details on error), return 0 from the XOP

// To only let IGOR display an error box (NON CFS functions):
//  - return the error code and set p->result to the error code

// To only let IGOR display an error box ( CFS functions):
//  - use PrintFileError(BOX) after every CFS function (gives details on error), return 0 from the XOP

// To ignore the error:
//  - return 0 from the XOP


// 121201
// attempt to eliminate severe persistent error: string handles locked in xCfsCFS...ihc->IHC2 disposehandle->IHCdisposehandle2 (NO SUCCESS)
// ...not consequent: only in cfs and only strings .....
// 031216  my error revealed by Igor5 and pointed out by Howard Rodstein : there must be only the Igor bytes copied in IHC/IHC2, not the end character
//					...but the c handle must allocate one byte more (for the end) 


// 220702 removed trailing \0 from all XOP returning a string ! (maybe this resolved the above error?)

// 091002 q&d (not thoroughly tested) clip strings one character shorter than previously in xCfsSetVarVal()
// 030401 some temporary prints to check string size (removed again)

#include <XOPStandardHeaders.h>

#include "cfs.h"
#include "FPulseCed.h"

#include "XopMain.h"



#define   CFSDESC_SEP   ","	// to make SetCFSDesciptor() easily readable (accessed only by programmer...)
#define   CFSSEP        "|"	// here we cannot use ; or , or : as we cannot forbid this character in user comments, units, descriptors..

#define   ZEROBYTE        0
#define   MAXSTRING    1000
#define   MAXFILVARS     100              // limit 100 is set in CFS.C 
#define   MAXDSVARS      100              // limit 100 is set in CFS.C 
static    TVarDesc FileArray[MAXFILVARS]; // CFS.C sets the limit to 100, PULSE uses 10 
static    TVarDesc DSArray[ MAXDSVARS ];  // CFS.C sets the limit to 100, PULSE uses 49

int       SetCFSDescriptor( int nType, int nChan, char *FourElements, char *sep, int maxDSVar, int maxFileVar );
int       CountSepsInList( char *sString, char *sSep );
int       GetSepPosInList( int index, char *sString, char *sSep );
char     *StringFromList(  int index, char *sString, char *sSep );
int       ConvertVType( LPSTR sVType );
TDataType GetVarType( short hnd, short VarNo, TCFSKind VarKind, int ErrMode );
int       GetVarSize( short hnd, short VarNo, TCFSKind VarKind, int ErrMode );
int       PrintFileError( int ErrMode );

#define FILEERR -1

#pragma pack(2)

int xCfsCreateFile( void *ptr) {
   struct { double ErrMode;   double maxFileVar; double maxDSVar; double Channels;
            double BlockSize; Handle Comment;    Handle FileName; double res; }* p = ptr;
// IGOR wrapper for CreateCFSFile()
// Difference to CFS: as IGOR doesn't know stuctures the CFS data structures FileArray and DSArray cannot be passed but must be hidden  
// 121201 error in CreateCFSFile(): returns always positive handle, and never negative error code -> code fails later e.g in WriteData()

   int    maxDSVar   = (int)p->maxDSVar;
   int    maxFileVar = (int)p->maxFileVar;
   short  Channels   = (short)p->Channels;
   WORD   BlockSize  = (WORD)p->BlockSize;
// 050204
//   int    hState0, hState1;
//   Handle CComment   = IHC2( p->Comment, &hState0 );
//   Handle CFileName  = IHC2( p->FileName, &hState1 );
   Handle CComment   = IHC( p->Comment );
   Handle CFileName  = IHC( p->FileName );
   short  code;
   char buf[200];

	char nativePath[MAX_PATH_LEN+1];				// native path can be longer (C:My:data -> C:\\My\\Data)

	code = GetNativePath( *CFileName, nativePath ); // convert to windows path (IGOR prefers Mac path syntax)
	if ( code )
	{
      sprintf_s( buf, 200, "++++Error: Cannot open '%s' , (xCfsCreateFile / GetNativePath() return code=%d/0x%x) \r", *CFileName, code, code );
      XOPNotice( buf );                 // return ALWAYS A NEGATIVE error code to calling user function..
      DisposeHandleIHC( CComment );		// 050204
      DisposeHandleIHC( CFileName );	// 050204
      p->res = code < 0 ? code : -code; // ...as a positive code would be interpreted as a valid CFS file handle
      return code;                      // Let IGOR report the error (error box or debugger)
	}

 // WORKAROUND for the above error: check accessibility of desired path before erroneous CreateCFSFile() is called 
   code = XOPCreateFile( nativePath, TRUE, 0, 0 ); 
   if ( code )
   {
      sprintf_s( buf, 200, "++++Error: Cannot open '%s' , (xCfsCreateFile / XOPCreateFile return code=%d/0x%x) \r", nativePath, code, code );
      XOPNotice( buf );                 // return ALWAYS A NEGATIVE error code to calling user function..
      DisposeHandleIHC( CComment );		// 050204
      DisposeHandleIHC( CFileName );	// 050204
      p->res = code < 0 ? code : -code; // ...as a positive code would be interpreted as a valid CFS file handle
      return 0;                         // We don't want IGOR to do anything with the error (no error box, no debugger)
   // return code;                      // Let IGOR report the error (error box or debugger)
   }
   else
   {                                    // the file has been created: delete it again...
      XOPDeleteFile( nativePath );      // ..now CreateCFSFile() should have no problems  because it never sees an invalid path..
      code = CreateCFSFile( nativePath, *CComment, BlockSize, Channels, FileArray, DSArray, maxFileVar, maxDSVar ); 
      if ( (int)p->ErrMode & MSGLINE )
      {
         sprintf_s( buf, 200, "\t\txCfsCreateCFS...receives '%s' '%s' %d %d ptr ptr %d %d,  returns code=%d \r",
                          nativePath, *CComment, BlockSize, Channels, maxFileVar, maxDSVar, code ); 
         XOPNotice( buf ); 
      }
      if ( code < 0 )
         PrintFileError( (int)p->ErrMode );
      DisposeHandleIHC( CComment );
      DisposeHandleIHC( CFileName );
      p->res = (double)code;     // return a negative error code or a positive CFS file handle
      return 0;                  // ..we don't want IGOR to do anything with the error (no error box, no debugger)
   }
}

									  

int xCfsOpenFile(void *ptr) {
    struct { double ErrMode;   double memoryTable; double enableWrite; Handle FileName; double res; }* p = ptr;
// IGOR wrapper for OpenCFSFile()

   short  memoryTable	= (short)p->memoryTable;	// 1 store some 4 bytes / datasection in memory rather than on disk
   short  enableWrite	= (short)p->enableWrite;	// O allow no changes, 1 modifications are possible with Setxxx()
   Handle CFileName  = IHC( p->FileName );
   short  code;
	char buf[200];
	char nativePath[MAX_PATH_LEN+1];				// native path can be longer (C:My:data -> C:\\My\\Data)
	code = GetNativePath( *CFileName, nativePath ); // convert to windows path (IGOR prefers Mac path syntax)
	if ( code )
	{
      sprintf_s( buf, 200, "++++Error: Cannot open '%s' , (xCfsOpensFile / GetNativePath() return code=%d/0x%x) \r", *CFileName, code, code );
      XOPNotice( buf );                 // return ALWAYS A NEGATIVE error code to calling user function..
		DisposeHandleIHC( CFileName );	// 050203
      p->res = code < 0 ? code : -code; // ...as a positive code would be interpreted as a valid CFS file handle
      return 0;                         // Returning 0 prevents IGOR from doing anything with the error (no error box, no debugger)
   // return code;                      // Let IGOR report the error (error box or debugger)
	}
   else
   { 
      code = OpenCFSFile( nativePath, enableWrite, memoryTable ); 
      if ( (int)p->ErrMode & MSGLINE )
      {
         sprintf_s( buf, 200, "\t\txCfsOpenCFS...receives '%s' %d %d ,  returns code=%d \r",
                          nativePath, enableWrite, memoryTable, code ); 
         XOPNotice( buf ); 
      }
      if ( code < 0 ) {
         PrintFileError( (int)p->ErrMode );
		}
		DisposeHandleIHC( CFileName );
      p->res = (double)code;				// return a negative error code or a positive CFS file handle
      return 0;								// Returning 0 prevents IGOR from doing anything with the error (no error box, no debugger)
   }
}

							   
int xCfsCloseFile( void *ptr) {
   struct { double ErrMode; double hnd; double res; }* p = ptr;
// IGOR wrapper for CFS CloseCFSFile()
   short     hnd     = (short)p->hnd;
   short     code    = CloseCFSFile( hnd );
   if ( code < 0 )
      PrintFileError( (int)p->ErrMode ); // We handle the errors here, but for more error processing to take place..
   p->res = code;                        // ..we return the error code to the calling function. After having done all that...
   return 0;                             // ..we don't want IGOR to do anything with the error (no error box, no debugger)
}


int xCfsCommitFile( void *ptr) {
   struct { double ErrMode; double hnd; double res; }* p = ptr;
// IGOR wrapper for CFS CommitCFSFile()
   short     hnd     = (short)p->hnd;
   short     code    = CommitCFSFile( hnd );
   if ( code < 0 )
      PrintFileError( (int)p->ErrMode ); // We handle the errors here, but for more error processing to take place..
   p->res = code;                        // ..we return the error code to the calling function. After having done all that...
   return 0;                             // ..we don't want IGOR to do anything with the error (no error box, no debugger)
}


int xCfsGetGenInfo( void *ptr) {
   struct { double ErrMode;  double hnd; Handle sRes; }* p = ptr;
// IGOR wrapper for CFS GetGenInfo()
// Difference to CFS: as IGOR doesn't know pointers the 3 CFS strings are returned as string list   
// Flaw / Limitation: Neither 'time' nor 'date' nor 'comment' may contain the character 'CFSSEP' 
   short     hnd          = (short)p->hnd;
   char      time[10];
   char      date[10];
   TComment  comment;

   char      errbuf[300]; 
   char      tmp[300];							// CFS uses not more than 50 characters..
   size_t    len;
   int       err = 0;
   Handle    str1 = NIL;

   GetGenInfo( hnd, time, date, comment );
 
   sprintf_s( tmp, 300, "%s%s%s%s%s", time, CFSSEP, date, CFSSEP, comment );
   len = strlen( tmp );
   if (( str1 = NewHandle( len )) == NIL )	// get output handle, do not provide space for '\0' 
   {
      sprintf_s( errbuf, 300, "++++Error: xCfsGetGenInfo() Not enough memory. Aborted...\r");
      XOPNotice( errbuf );
      err = NOMEM;									// out of memory
   }
   else													// string length is OK so return string 
      memcpy( *str1, tmp, len );             // copy local temporary buffer to persistent Igor output string
 
	//sprintf( errbuf, "xCfsGetGenInfo [len:%d]:  '%s' \r", len, tmp ); XOPNotice( errbuf );  
   PrintFileError( (int)p->ErrMode ); // We must handle the errors here because we cannot return the error code to the calling function
   p->sRes = str1;
   return err;
}

				  
int xCfsGetFileInfo( void *ptr ) { 
   struct { double ErrMode; double hnd; Handle sRes; }* p = ptr;
// IGOR wrapper for CFS GetFileInfo()
// Difference to CFS: as IGOR doesn't know pointers the 4 CFS variable pointers are returned as string list   
   short     hnd          = (short)p->hnd;
   short     channels;
   short     fileVars;
   short     DSVars;
   short     dataSections;

   char      errbuf[300]; 
   char      tmp[300];							// CFS uses not more than 20 characters..
   size_t    len;
   int       err = 0;
   Handle    str1 = NIL;

   GetFileInfo( hnd, &channels, &fileVars, &DSVars, &dataSections );
 
   sprintf_s( tmp, 300, "%d%s%d%s%d%s%d", channels, CFSSEP, fileVars, CFSSEP, DSVars, CFSSEP, dataSections );
   len = strlen( tmp );
   if (( str1 = NewHandle( len )) == NIL ) // get output handle, do not provide space for '\0' 
   {
      sprintf_s( errbuf, 300, "++++Error: xCfsGetFileInfo() Not enough memory. Aborted...\r");
      XOPNotice( errbuf );
      err = NOMEM;				             // out of memory
   }
   else                                    // string length is OK so return string 
      memcpy( *str1, tmp, len );           // copy local temporary buffer to persistent Igor output string
 
	//sprintf( errbuf, "xCfsGetFileInfo [len:%d]:  '%s' \r", len, tmp ); XOPNotice( errbuf );  
   PrintFileError( (int)p->ErrMode ); // We must handle the errors here because we cannot return the error code to the calling function
   p->sRes = str1;
   return err;
}
				   

int xCfsGetFileChan( void *ptr) {
   struct { double ErrMode; double Channel;  double hnd; Handle sRes; }* p = ptr;
// IGOR wrapper for CFS GetFileChan()
// Difference to CFS: as IGOR doesn't know pointers the 3 strings and 4 CFS variable pointers are returned as string list   
// Flaw / Limitation: Neither 'Units' nor 'Description' may contain the character 'CFSSEP' 

   short     hnd          = (short)p->hnd;
   short     Channel      = (short)p->Channel;
   TDesc     ChannelName;
   TUnits    yUnits;
   TUnits    xUnits;
   TDataType DataType;             // one of 8 types allowed 
   TCFSKind  DataKind;
   short     Spacing;
   short     Other;

   char      errbuf[300]; 
   char      tmp[300];     // CFS uses not more than 50 characters..
   size_t    len;
   int       err = 0;
   Handle    str1 = NIL;

   GetFileChan( hnd, Channel, ChannelName, yUnits, xUnits, &DataType, &DataKind, &Spacing, &Other );
 
   sprintf_s( tmp, 300, "%s%s%s%s%s%s%d%s%d%s%d%s%d", ChannelName, CFSSEP, yUnits, CFSSEP, xUnits, CFSSEP, 
				                               DataType, CFSSEP, DataKind, CFSSEP, Spacing, CFSSEP, Other );
   len = strlen( tmp );
   if (( str1 = NewHandle( len )) == NIL ) // get output handle, do not provide space for '\0' 
   {
      sprintf_s( errbuf, 300, "++++Error: xCfsGetFileChan() Not enough memory. Aborted...\r");
      XOPNotice( errbuf );
      err = NOMEM;				             // out of memory
   }
   else                                    // string length is OK so return string 
      memcpy( *str1, tmp, len );           // copy local temporary buffer to persistent Igor output string
 
	//sprintf( errbuf, "xCfsGetFileChan [len:%d]:  '%s' \r", len, tmp ); XOPNotice( errbuf );  
   PrintFileError( (int)p->ErrMode ); // We must handle the errors here because we cannot return the error code to the calling function
   p->sRes = str1;
   return err;
}



int xCfsSetFileChan( void *ptr) {
   struct { double ErrMode; double Other;  double Spacing;     double DataKind; double DataType; Handle xUnits;
            Handle yUnits; Handle ChannelName; double Channel;  double hnd;      double res; }* p = ptr;
// IGOR wrapper for CFS SetFileChan()
   short     hnd          = (short)p->hnd;
   short     Channel      = (short)p->Channel;
   TDataType DataType     = (TDataType)p->DataType;
   TCFSKind  DataKind     = (TCFSKind)p->DataKind;
	Handle    CChannelName = IHC( p->ChannelName );
   Handle    CyUnits      = IHC( p->yUnits );
   Handle    CxUnits      = IHC( p->xUnits );
   short     Spacing      = (short)p->Spacing;
   short     Other        = (short)p->Other;
   int		 ErrMode      = (int)p->ErrMode; 
   SetFileChan( hnd, Channel, *CChannelName, *CyUnits, *CxUnits, DataType, DataKind, Spacing, Other );
	DisposeHandleIHC( CChannelName );                  // we need to get rid of copied string
   DisposeHandleIHC( CyUnits );                       // we need to get rid of copied string
   DisposeHandleIHC( CxUnits );                       // we need to get rid of copied string
   p->res = PrintFileError( ErrMode ); // We handle the errors here, but we also return the error code to the calling function
   return 0;                           // ..we don't want IGOR to do anything with the error (no error box, no debugger)
}


int xCfsSetDSChan( void *ptr) {
   struct { double ErrMode; double xOffset;     double xScale;      double yOffset; double yScale; double Points;
                           double StartOffset; double DataSection; double Channel; double hnd;    double res; }* p = ptr;
// IGOR wrapper for CFS SetDSChan(), no difference to CFS implementation
   short     hnd         = (short)p->hnd;
   short     Channel     = (short)p->Channel;
   WORD      DataSection = (WORD)p->DataSection;
   long      StartOffset = (long)p->StartOffset;
   long      Points      = (long)p->Points;
   float     yScale      = (float)p->yScale;
   float     yOffset     = (float)p->yOffset;
   float     xScale      = (float)p->xScale;
   float     xOffset     = (float)p->xOffset;
   int		 ErrMode     = (int)p->ErrMode; 
   SetDSChan( hnd, Channel, DataSection, StartOffset, Points, yScale, yOffset, xScale, xOffset );
   p->res = PrintFileError( ErrMode ); // We handle the errors here, but we also return the error code to the calling function
   return 0;                           // ..we don't want IGOR to do anything with the error (no error box, no debugger)
}


int xCfsGetDSChan( void *ptr) {
   struct { double ErrMode; double DataSection; double Channel; double hnd; Handle sRes; }* p = ptr;
// IGOR wrapper for CFS GetDSChan()
// Difference to CFS: the 6 CFS variabls are returned as string list

   short     hnd         = (short)p->hnd;
   short     Channel     = (short)p->Channel;
   WORD      DataSection = (WORD)p->DataSection;
   int		 ErrMode     = (int)p->ErrMode; 
   long      StartOffset,	Points;
   float     yScale,		yOffset, xScale, xOffset;

   char      errbuf[300]; 
   char      tmp[300];					// CFS uses not more than 20 characters..
   size_t    len;
   int       err = 0;
   Handle    str1 = NIL;

   GetDSChan( hnd, Channel, DataSection, &StartOffset, &Points, &yScale, &yOffset, &xScale, &xOffset );
 
   sprintf_s( tmp, 300, "%d%s%d%s%lf%s%lf%s%lf%s%lf", StartOffset, CFSSEP, Points, CFSSEP, yScale, CFSSEP, yOffset, CFSSEP, xScale, CFSSEP, xOffset );
   len = strlen( tmp );
   if (( str1 = NewHandle( len )) == NIL ) // get output handle, do not provide space for '\0' 
   {
      sprintf_s( errbuf, 300, "++++Error: xCfsGetDSChan() Not enough memory. Aborted...\r");
      XOPNotice( errbuf );
      err = NOMEM;				             // out of memory
   }
   else                                    // string length is OK so return string 
      memcpy( *str1, tmp, len );           // copy local temporary buffer to persistent Igor output string
 
	//sprintf( errbuf, "xCfsGetDSChan [len:%d]:  '%s' \r", len, tmp ); XOPNotice( errbuf );  
   PrintFileError( (int)p->ErrMode ); // We must handle the errors here because we cannot return the error code to the calling function
   p->sRes = str1;
   return err;
}


int xCfsGetChanData( void *ptr) {
   struct { double ErrMode;	double AreaSize;	waveHndl wDataADS;	double NumElements;
            double FirstElement; double DataSection; double Channel;		double hnd;    double res; }* p = ptr;
// IGOR wrapper for CFS GetChanData()
// Difference to CFS: as IGOR doesn't know pointers the CFS buffer is passed as a wave   
   short     hnd         = (short)p->hnd;
   short     Channel     = (short)p->Channel;
   WORD      DataSection = (WORD)p->DataSection;
   long      FirstElement= (long)p->FirstElement;
   WORD      NumElements = (WORD)p->NumElements;
   long      AreaSize    = (long)p->AreaSize;
   int		 ErrMode     = (int)p->ErrMode; 
   char      errBuf[300]; 
   void		*Raw;
   long  	 pts;

	// DebugPrintWaveProperties( "xCfsGetChanData", p->wDataADS ); 	// 050128

	if ( p->wDataADS == NIL )                // check if wave handle is valid
   {
      sprintf_s( errBuf, 300, "++++Error: xCfsGetChanData() received nonvalid wave \r" );
		XOPNotice( errBuf );
	   SetNaN64( &p->res );			           // return NaN if wave is not valid   
	   return( NON_EXISTENT_WAVE );
   }
   if (   WaveType(p->wDataADS) != NT_I16 ) // check wave's numeric type  
   {
    	sprintf_s( errBuf, 300, "++++Error: xCfsGetChanData() received non integer wave \r" );
		XOPNotice( errBuf );
	   SetNaN64( &p->res );				        // return NaN if wave is not 2Byte int
      return( IS_NOT_2BYTE_INT_WAVE );
   }

   Raw  = WaveData( p->wDataADS ); //  char pointer to IGOR wave data 

   // 2021-03-13  cast (int) to be done
   pts  = GetChanData( hnd, Channel, DataSection, FirstElement, NumElements, Raw, AreaSize );
	//sprintf( errBuf, "GetChanData( ... Elem1:%d, NumEle:%d ...) returns %d points. \r", FirstElement, NumElements, pts ); XOPNotice( errBuf ); 
   
	p->res = PrintFileError( ErrMode ); // We handle the errors here, but we also return the error code to the calling function
   
   return 0;                           // ..we don't want IGOR to do anything with the error (no error box, no debugger)
}


int xCfsInsertDS( void *ptr) {
   struct { double ErrMode; double FlagSet; double DataSection; double hnd; double res; }* p = ptr;
// IGOR wrappper for CFS InsertDS()

   short     hnd         = (short)p->hnd;
   WORD      DataSection = (WORD)p->DataSection;
   WORD      FlagSet     = (WORD)p->FlagSet;
   int		 code        = InsertDS( hnd, DataSection, FlagSet );
   if ( code < 0 )
      PrintFileError( (int)p->ErrMode );
   p->res = (double)code;              // We handle the errors here, but we also return the error code to the calling function
   return 0;                           // ..we don't want IGOR to do anything with the error (no error box, no debugger)
//	return p->res;		// THIS != 0 will instruct IGOR to print an error message 
}


int xCfsWriteData( void *ptr) {
   struct { double ErrMode; waveHndl wDataADS; double Bytes; double StartOffset; double DataSection; double hnd; double res; }* p = ptr;
// IGOR wrappper for CFS WriteData()
// Difference to CFS: as IGOR doesn't know pointers the CFS buffer is passed as a wave

   short     hnd         = (short)p->hnd;
   WORD      DataSection = (WORD)p->DataSection;
   long      StartOffset = (long)p->StartOffset;
   WORD      Bytes       = (WORD)p->Bytes;
   int		 ErrMode     = (int)p->ErrMode; 
   char		 errBuf[200];	
   short     code;
   void *Raw;
 
	// DebugPrintWaveProperties( "xCfsWriteData  ", p->wDataADS ); 	// 050128

	if ( p->wDataADS == NIL )                // check if wave handle is valid
   {
      sprintf_s( errBuf, 200, "++++Error: xCfsWriteData() received nonvalid wave \r" );
		XOPNotice( errBuf );
	   SetNaN64( &p->res );			           // return NaN if wave is not valid   
	   return( NON_EXISTENT_WAVE );
   }
   if (   WaveType(p->wDataADS) != NT_I16 ) // check wave's numeric type  
   {
    	sprintf_s( errBuf, 200, "++++Error: xCfsWriteData() received non integer wave \r" );
		XOPNotice( errBuf );
	   SetNaN64( &p->res );				        // return NaN if wave is not 2Byte int
      return( IS_NOT_2BYTE_INT_WAVE );
   }

   Raw  = WaveData( p->wDataADS ); //  char pointer to IGOR wave data 

   code = WriteData( hnd, DataSection, StartOffset, Bytes, Raw );
   if ( code < 0 )
      PrintFileError( ErrMode );

   if ( ErrMode & MSGLINE )
	{
	   sprintf_s( errBuf, 200, "\t\t\txCfsWriteData() has written %d bytes \r", Bytes );
		XOPNotice( errBuf );
	}

   p->res = (double)code;              // We handle the errors here, but we also return the error code to the calling function
   return 0;                           // ..we don't want IGOR to do anything with the error (no error box, no debugger)
}


int xCfsReadData( void *ptr ) {
   struct { double ErrMode; waveHndl wDataADS; double Bytes; double StartOffset; double DataSection; double hnd; double res; }* p = ptr;
// IGOR wrappper for CFS ReadData()
// Difference to CFS: as IGOR doesn't know pointers the CFS buffer is passed as a wave   
   short     hnd         = (short)p->hnd;
   WORD      DataSection = (WORD)p->DataSection;
   long      StartOffset = (long)p->StartOffset;
   WORD      Bytes       = (WORD)p->Bytes;
   short     code;
   void *Raw;

	// DebugPrintWaveProperties( "xCfsReadData    ", p->wDataADS ); 	// 050128

	if ( p->wDataADS == NIL )                // check if wave handle is valid
   {
		SetNaN64( &p->res );			           // return NaN if wave is not valid   
		return( NON_EXISTENT_WAVE );
	}
 	if (   WaveType(p->wDataADS) != NT_I16 ) // check wave's numeric type  
   {
  	   SetNaN64( &p->res );				        // return NaN if wave is not 2Byte int
		return( IS_NOT_2BYTE_INT_WAVE );
	}

   Raw  = WaveData( p->wDataADS ); //  char pointer to IGOR wave data 

   code = ReadData( hnd, DataSection, StartOffset, Bytes, Raw );
   if ( code < 0 )
      PrintFileError( (int)p->ErrMode );

   p->res = (double)code;              // We handle the errors here, but we also return the error code to the calling function
   return 0;                           // ..we don't want IGOR to do anything with the error (no error box, no debugger)
}


int xCfsSetVarVal( void *ptr) {
   struct { double ErrMode; Handle VarAsString; double DataSection; double VarKind; double VarNo; double hnd; double res; }* p = ptr;
// IGOR wrappper for CFS SetVarVal()
// Difference to CFS: as IGOR doesn't know pointers the CFS variable is passed as string even if it is a number   
// returns to IGOR the type which is expected by the array, NOT the type actually passed
   short     hnd          = (short)p->hnd;
   short     VarNo        = (short)p->VarNo;
   TCFSKind  VarKind      = (TCFSKind)p->VarKind;   // FILEVAR or DS VAR
   WORD      DataSection  = (WORD)p->DataSection;
   int		 ErrMode      = (int)p->ErrMode; 
   TDataType VarType      = GetVarType( hnd, VarNo, VarKind, (int)p->ErrMode );
   size_t    VarSize      = GetVarSize( hnd, VarNo, VarKind, (int)p->ErrMode );
   size_t    PassedSize   = GetHandleSize( p->VarAsString );

   Handle    CVarAsString = IHC( p->VarAsString );  // below we need a C style string

	char      CVarChar;
   short     CVarShort;
   long      CVarLong;
   float     CVarFloat;
   double    CVarDouble;
   char      errbuf[10000];

      if ( ErrMode & MSGLINE )
   	{
         sprintf_s( errbuf, 10000, "\t\t\txCfsSetVarVal(string) \t hnd:%d  varno:%2d \r", hnd, VarNo );   
         XOPNotice( errbuf );
      }

    if ( VarType == INT1 || VarType == WRD1 )       // 1 byte signed or unsigned
   {
      CVarChar   = atoi( *CVarAsString ); 
      SetVarVal( hnd, VarNo, VarKind, DataSection, &CVarChar );
   }
   if ( VarType == INT2 || VarType == WRD2 )       // 2 bytes signed or unsigned
   {
      CVarShort  = atoi( *CVarAsString ); 
      SetVarVal( hnd, VarNo, VarKind, DataSection, &CVarShort );
   }
   if ( VarType == INT4 )                          // 4 bytes signed 
   {
      CVarLong   = atoi( *CVarAsString ); 
      SetVarVal( hnd, VarNo, VarKind, DataSection, &CVarLong );
   }
   if ( VarType == RL4 )                           // 4 bytes real
   {
      CVarFloat  = (float)atof( *CVarAsString );
      SetVarVal( hnd, VarNo, VarKind, DataSection, &CVarFloat );
   }
   if ( VarType == RL8 )                           // 8 bytes real
   {
      CVarDouble = atof( *CVarAsString ); 
      SetVarVal( hnd, VarNo, VarKind, DataSection, &CVarDouble );
   }
   if ( VarType == LSTR )                          // String
   {
		if ( PassedSize >= VarSize )
		{
	      (*CVarAsString)[ VarSize-1 ]= '\0';          // same length or shorter than original string
	      sprintf_s( errbuf, 10000, "++++Error: xCfsSetVarVal() String too long, truncated from %d to %d chars: '%s'\r", (int)PassedSize, VarSize-1, *CVarAsString );
			XOPNotice( errbuf );
      } 
      SetVarVal( hnd, VarNo, VarKind, DataSection, *CVarAsString );

      if ( ErrMode & MSGLINE )
   	{
         sprintf_s( errbuf, 10000, "\t\t\txCfsSetVarVal(string) \t type:%d  len:%2d (max:%d)  string:'%s' \r", VarType, (int)PassedSize, VarSize, *CVarAsString );
         XOPNotice( errbuf );
      }
   }
   DisposeHandleIHC( CVarAsString );                  // we need to get rid of copied string

   PrintFileError( (int)p->ErrMode ); // We must handle the errors here because we cannot return the error code to the calling function
   p->res = (double)VarType;
   return 0;                           // ..we don't want IGOR to do anything with the error (no error box, no debugger)
}


int xCfsGetVarVal( void *ptr) {
   struct { double ErrMode; double DataSection; double VarKind; double VarNo; double hnd; Handle sRes; }* p = ptr;
// IGOR wrapper for CFS GetVarVal()
// Difference to CFS: as IGOR doesn't know pointers the CFS variable is not passed but returned as string   

//? lock handles ?...

//? two sorts of errors can occur: memory and CFS ...not all are handled correctly...
   short     hnd          = (short)p->hnd;
   short     VarNo        = (short)p->VarNo;
   TCFSKind  VarKind      = (TCFSKind)p->VarKind;   // FILEVAR or DS VAR
   WORD      DataSection  = (WORD)p->DataSection;
   TDataType VarType      = GetVarType( hnd, VarNo, VarKind, (int)p->ErrMode );
   size_t    VarSize      = GetVarSize( hnd, VarNo, VarKind, (int)p->ErrMode );
   char      CVarChar;
   short     CVarShort;
   long      CVarLong;
   float     CVarFloat;
   double    CVarDouble;
   int       err = 0;
   char      sValOrTxt[ MAXSTRING ];	//?? THIS limits the longest string we can handle
   char      errbuf[ 1000 ]; 
   Handle    str1 = NIL;
 
   // sprintf ( errbuf, "xCfsGetVarVal( any  )  expected vartype:%d  varsize:%d  \r", VarType, VarSize ); XOPNotice( errbuf );

   if ( VarType <= RL8 )                     // VARIABLE TO GET IS A NUMBER:.. 
   {                                         // .. get it and convert it into a string
      if ( VarType == INT1 || VarType == WRD1 )       // 1 byte signed or unsigned
      {
         GetVarVal( hnd, VarNo, VarKind, DataSection, &CVarChar );
         sprintf_s( sValOrTxt, MAXSTRING, "%d", CVarChar );
      }
      if ( VarType == INT2 || VarType == WRD2 )       // 2 bytes signed or unsigned
      {
         GetVarVal( hnd, VarNo, VarKind, DataSection, &CVarShort );
         sprintf_s( sValOrTxt, MAXSTRING, "%d", CVarShort );
      }
      if ( VarType == INT4 )                          // 4 bytes signed 
      {
         GetVarVal( hnd, VarNo, VarKind, DataSection, &CVarLong );
         sprintf_s( sValOrTxt, MAXSTRING, "%d", CVarLong );
      }
      if ( VarType == RL4 )                           // 4 bytes real
      {
         GetVarVal( hnd, VarNo, VarKind, DataSection, &CVarFloat );
         sprintf_s( sValOrTxt, MAXSTRING, "%f", CVarFloat );  //? exp
      }
      if ( VarType == RL8 )                           // 8 bytes real
      {
         GetVarVal( hnd, VarNo, VarKind, DataSection, &CVarDouble );
         sprintf_s( sValOrTxt, MAXSTRING, "%lf", CVarDouble );//? exp 
      }
	} 
	else
	{					// it is not a number but a string
     GetVarVal( hnd, VarNo, VarKind, DataSection, sValOrTxt ); // .. to persistent Igor output string
   }

   VarSize = strlen( sValOrTxt );						// this is NOT the CFS Varsize (1,2,4)
   
	// can be number or string...
  	if (( str1 = NewHandle( VarSize )) == NIL )		// get output handle, do NOT provide space for '\0' 
   {
      sprintf_s( errbuf, 1000, "++++Error: xCfsGetVarVal() Not enough memory. Aborted...\r");
      XOPNotice( errbuf );
      err = NOMEM;											// out of memory
   }
   else
		memcpy( *str1, sValOrTxt, VarSize);          // copy local temporary buffer to persistent Igor output string

   if ( (int)p->ErrMode & MSGLINE ) {
      sprintf_s( errbuf, 1000, "\t\t\t\t\txCfsGetVarVal(  any  )\t type:%d  len:%2d  varsize:%d  string:'%s'\r", VarType, (int)strlen(sValOrTxt), (int)VarSize, sValOrTxt ); 
      XOPNotice( errbuf );
	}
	err = 0;
	p->sRes = str1;                    // We return the desired value (as string)
   PrintFileError( (int)p->ErrMode ); // We must handle the errors here because we cannot return the error code to the calling function
   return err;                        // ..we want IGOR to alert us about memory errors!
}


int xCfsGetVarType( void *ptr) {
   struct { double ErrMode; double VarKind; double VarNo; double hnd; double res; }* p = ptr;
// returns to IGOR variable type as integer (INT1..LSTR) , no corrsesponding CFS function
   short     hnd          = (short)p->hnd;
   short     VarNo        = (short)p->VarNo;
   TCFSKind  VarKind      = (TCFSKind)p->VarKind;   // FILEVAR or DS VAR
   p->res = (double)GetVarType( hnd, VarNo, VarKind, (int)p->ErrMode );
   PrintFileError( (int)p->ErrMode ); // We must handle the errors here because we cannot return the error code to the calling function
   return 0;
}

TDataType GetVarType( short hnd, short VarNo, TCFSKind VarKind, int ErrMode )
// returns variable type as integer (INT1..LSTR) , no corrsesponding CFS function
{
   short     VarSize;
   TDataType VarType;
   TUnits    Units;
   TDesc     Description;
   GetVarDesc( hnd, VarNo, VarKind, &VarSize, &VarType, Units, Description );
   PrintFileError( ErrMode ); // We must handle the errors here because we cannot return the error code to the calling function
   return VarType;
}

int GetVarSize( short hnd, short VarNo, TCFSKind VarKind, int ErrMode )
// returns variable size (useful only when type is LSTR, numbers have fixed size) , no corrsesponding CFS function
{
   short     VarSize;
   TDataType VarType;
   TUnits    Units;
   TDesc     Description;
//030401
//   char      tmp[300];     // CFS uses not more than 50 characters..
 
	GetVarDesc( hnd, VarNo, VarKind, &VarSize, &VarType, Units, Description );
   PrintFileError( ErrMode ); // We must handle the errors here because we cannot return the error code to the calling function

//030401 ok
//	sprintf( tmp, "GetVarSize() '%s'  '%s  returns length %d  \r\n", Description, Units, VarSize); XOPNotice( tmp ) ;
  return VarSize;
}


int xCfsGetVarDesc( void *ptr) {
   struct { double ErrMode; double VarKind; double VarNo; double hnd; Handle sRes; }* p = ptr;
// IGOR wrapper for CFS GetVarDesc()
// Difference to CFS: as IGOR doesn't know pointers the 4 CFS variable pointers are returned as string list   
// Flaw / Limitation: Neither 'Units' nor 'Description' may contain the character 'CFSSEP' 
   short     hnd         = (short)p->hnd;
   short     VarNo       = (short)p->VarNo;
   short     VarKind     = (short)p->VarKind;   // FILEVAR or DS VAR
   short     VarSize;
   char      VarType;
   TUnits    Units;
   TDesc     Description;
   char      errbuf[300]; 
   char      tmp[300];     // CFS uses not more than 50 characters..
   size_t    len;
   int       err = 0;
   Handle    str1 = NIL;
 

   GetVarDesc( hnd, VarNo, VarKind, &VarSize, &VarType, Units, Description );

//030401	
//sprintf( tmp, "xCfsGetVarDesc() hnd:%d VarSize:%d %s VarType:%d %s Units:%s %s Description:%s \r", hnd, VarSize, CFSSEP, VarType, CFSSEP, Units, CFSSEP, Description ); XOPNotice( tmp );

   sprintf_s( tmp, 300, "%d%s%d%s%s%s%s", VarSize, CFSSEP, VarType, CFSSEP, Units, CFSSEP, Description );
   len = strlen( tmp );
   if (( str1 = NewHandle( len )) == NIL ) // get output handle , do not provide space for '\0' 
   {
      sprintf_s( errbuf, 300, "++++Error: xCfsGetVarDesc() Not enough memory. Aborted...\r");
      XOPNotice( errbuf );
      err = NOMEM;				               // out of memory
   }
   else                                      // string length is OK so return string 
		memcpy( *str1, tmp, len );              // copy local temporary buffer WITHOUT \0 to persistent Igor output string 
 
   //sprintf( buf, "xCfsGetVarDesc:  '%s' \r", *str1 ); XOPNotice( buf );  
   PrintFileError( (int)p->ErrMode ); // We must handle the errors here because we cannot return the error code to the calling function
   p->sRes = str1;
   return err;
}

int xCfsSetDescriptor( void *ptr) {
   struct { Handle sEle; double Chan; double Type; double res; }* p = ptr;
// sets CFS descriptor data in CFS structure with values passed as string list

   int       nChan      = (int)p->Chan;
   int       nType      = (int)p->Type;
	int       err   = 0;
   Handle    CEle = IHC( p->sEle);
   SetCFSDescriptor( nType, nChan, *CEle, CFSDESC_SEP, MAXDSVARS, MAXFILVARS );
   DisposeHandleIHC( CEle );                         // we need to get rid of copied string
	p->res = 0;
	return err;
}

#pragma pack()

/////////////////////////////////////////////////////////////////////////////
// TESTING CFS HELPERS


/////////////////////////////////////////////////////////////////////////////
// BIG CFS HELPERS


int SetCFSDescriptor( int nType, int nIdx, char *FourElements, char *sep, int maxDSVar, int maxFileVar )
// Sets CFS descriptor data in CFS structure with values passed as string list
// direct array access (without hnd) must be used because hnd is available..
// ..AFTER CreateCFSFile() establishes connection between hnd and arrays

//? arbitrary order of elements within FourElements
{
// char	buf[400];	// 050204
   if ( nType == DSVAR )
   {

      nIdx = min( max( 0, nIdx ), maxDSVar-1 );      
      strcpy( DSArray[ nIdx ].varDesc,      StringFromList( 0, FourElements, sep ));
      DSArray[ nIdx ].vType = ConvertVType( StringFromList( 1, FourElements, sep ));
      strcpy( DSArray[ nIdx ].varUnits,     StringFromList( 2, FourElements, sep ));
      DSArray[ nIdx ].vSize =         atoi( StringFromList( 3, FourElements, sep ));
      DSArray[ nIdx ].zeroByte = ZEROBYTE;

/* 050204
		sprintf( buf, "\tSetCFSDescriptor(%d, %d)\tSz:\t%6d\tTp:\t%d   %s  \t\t%-5s\t\t'%s'\r",
							nType, nIdx, DSArray[ nIdx ].vSize , DSArray[ nIdx ].vType, StringFromList( 1, FourElements, sep ),
							DSArray[ nIdx ].varUnits, DSArray[ nIdx ].varDesc );
		XOPNotice( buf );
*/
   }
   if ( nType == FILEVAR )
   {
      nIdx = min( max( 0, nIdx ), maxFileVar-1 );      
      strcpy( FileArray[ nIdx ].varDesc,      StringFromList( 0, FourElements, sep ));
      FileArray[ nIdx ].vType = ConvertVType( StringFromList( 1, FourElements, sep ));
      strcpy( FileArray[ nIdx ].varUnits,     StringFromList( 2, FourElements, sep ));
      FileArray[ nIdx ].vSize =         atoi( StringFromList( 3, FourElements, sep ));
      FileArray[ nIdx ].zeroByte = ZEROBYTE;

/* 050204
		sprintf( buf, "\tSetCFSDescriptor(%d, %d)\tSz:\t%6d\tTp:\t%d   %s  \t\t%-5s\t\t'%s'\r",
							nType, nIdx, FileArray[ nIdx ].vSize , DSArray[ nIdx ].vType, StringFromList( 1, FourElements, sep ),
							FileArray[ nIdx ].varUnits, FileArray[ nIdx ].varDesc );
		XOPNotice( buf );
*/
   }
   return 0;
}

/////////////////////////////////////////////////////////////////////////////
// LITTLE CFS HELPERS


char *StringFromList( int index, char *sString, char *sSep )
{
//? NOT GOOD....because of static can not use nested calls....... 
   static char  sExtracted[  MAXSTRING ] = "";
   static char  sStringCopy[ MAXSTRING ] = "";
   int   posBeg=-1, posEnd=-1, nSeps=-1;
   // char buf[100];

   int   len = (int)strlen( sString );
   if ( len == 0 || len > MAXSTRING - 3 || strlen( sSep ) == 0 )
      return sExtracted;

   strcpy( sStringCopy+1, sString );// leave first character empty (shift string by 1)
   sStringCopy[0]			= sSep[0];	// append leading separator
   sStringCopy[ len+1 ] = sSep[0];	// append trailing separator
   sStringCopy[ len+2 ] = '\0';		// append string end

   nSeps =  CountSepsInList( sStringCopy, sSep );
   index = min( max( 0, index ), nSeps-2 ); // 2 separators: only index 0

   posBeg = GetSepPosInList( index  , sStringCopy, sSep );
   posEnd = GetSepPosInList( index+1, sStringCopy, sSep ) - 1;

   strncpy( sExtracted, sStringCopy+posBeg+1, posEnd-posBeg );
   sExtracted[ posEnd-posBeg ] = '\0';    // append string end
   // sprintf( buf, "StringFromList() seps:%d  beg:%d  end:%d  sStringcopy:'%s' ->'%s' \r", nSeps, posBeg,  posEnd, sStringCopy, sExtracted );   XOPNotice( buf );  
   return sExtracted;
}
 
 
int CountSepsInList( char *sString, char *sSep )
{
   int cnt = 0, i, len = (int)strlen( sString );
   for ( i = 0; i < len; i += 1 )
      if ( sString[ i ] == sSep[ 0 ] )
         cnt += 1;
   return cnt;
}    

int GetSepPosInList( int index, char *sString, char *sSep )
{
   int cnt = 0, i, len = (int)strlen( sString );
   for ( i = 0; i < len; i += 1 ) {
      if ( sString[ i ] == sSep[ 0 ] ) {
         if ( cnt == index )
            return i;
         cnt += 1;
      }
   }
   return 0;
}

int  ConvertVType( LPSTR sVType ) 
{
   char  sVTypes[][5] =  {"INT1", "WRD1", "INT2", "WRD2", "INT4", "RL4", "RL8" ,"LSTR" };
   int   nVType, VTypeCnt = 8;
   char  buf[100];
 
   for ( nVType = 0; nVType < VTypeCnt;  nVType += 1 )
   {
      if ( strcmp( sVType, sVTypes[ nVType ] ) == 0 ) 
         break;
   } 
   if ( nVType == VTypeCnt )
   {
      sprintf_s( buf, 100, "++++Error: Unknown vType '%s' [use:INT1,WRD1,INT2,WRD2,INT4,RL4,RL8,LSTR] \r", sVType );
      XOPNotice( buf );
      nVType = LSTR; // default for minimum damage...
   }
   // sprintf( buf, "  sVType:'%s' = %d \r", sVType, nVType ); XOPNotice( buf );

   return nVType;
}

int PrintFileError( int ErrMode )
{
   short HndNo, ProcNo, ErrNo = 0;
   char  errBuf[200];
   static char  sProc[][20] = {
      "No function",   "SetFileChan",  "SetDSChan",    "SetWriteData",  "RemoveDS",       "SetVarVal",
      "GetGenInfo",    "GetFileInfo",  "GetVarDesc",   "GetVarVal",     "GetFileChan",    "GetDSChan",         
      "DSFlags",       "OpenCFSFile",  "GetChanData",  "SetComment",    "CommitCFSFile",  "InsertDS",
      "CreateCFSFile", "WriteData",    "ClearDS",      "CloseCFSFile",  "GetDSSize",      "ReadData",
      "CFSFileSize",   "AppendDS"  };
   static char  sError[][100] = {
      "No error", 
      "No spare file handles",  
      "File handle out of range 0..2",
      "File not open for writing",
      "File not open for editing/writing",
      "File not open for editing/reading",
      "File not open",
      "The specified file is not a version 2 filing system file",
      "Unable to allocate the memory needed for the filing system data",
      "",      // 9
      "",      // 10
      "Creation of file on disk failed (writing)",
      "Opening of file on disk failed (reading)",
      "Error reading from data file",
      "Error writing to data file",
      "Error reading from data section pointer file",
      "Error writing to data section pointer file",
      "Error seeking disk position",
      "Error inserting final data section of file",
      "Error setting file length",
      "Invalid variable description",  // 20
      "Parameter out of range 0..99",
      "Channel number out of range",
      "Too many data sections",
      "Invalid data section number (not in range 1 to total number of sections)",
      "Invalid variable kind (not 0 for file variable or 1 for DS variable)",
      "Invalid variable number",
      "Data size specified is out of the correct range",
      "",      // 28
      "",      // 29
      "Wrong CFS version number in file",
      "Wrong CFS version number in file",
      "Wrong CFS version number in file",
      "Wrong CFS version number in file",
      "Wrong CFS version number in file",
      "Wrong CFS version number in file",
      "Wrong CFS version number in file",
      "Wrong CFS version number in file",
      "Wrong CFS version number in file",
      "Wrong CFS version number in file"              };

   if ( FileError( &HndNo, &ProcNo, &ErrNo ) )
   {
      sprintf_s( errBuf, 200, "++++Error %d in %s() [CFS handle:%d]: %s. \r", ErrNo, sProc[ ProcNo ], HndNo, sError[ -ErrNo ] );  
      if ( ErrMode & ERRLINE )
         XOPNotice( errBuf );
      if ( ErrMode & ERRBOX )
         XOPOKAlert( "Error", errBuf );
   }
   return ErrNo;
}


// END   OF CFS INTERFACE
/////////////////////////////////////////////////////////////////////////////////////////


