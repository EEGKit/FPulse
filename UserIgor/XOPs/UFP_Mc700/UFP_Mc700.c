//
// UFP_Mc700.c  XOP to control the Axon MultiClamp700A/B based Axon's  'TestBed' sample program

// History
// 040922
// 041010	Remarks:
//				This package 'UFP_Mc700' does with its original code not work perfectly.
//				The following 2 flaws are observed:
//				1. Commands which change the setting of the MCC700 return an error code (TimeOut error 6005).
//					This is obseved e.g. with SetMode()  or  setGain().  Commands which retrieve a setting are OK.
//				2.	Commands which change the setting are partially executed immediately but partially also delayed.
//					Example: SetMode() immediately chages the mode radio buttons in the MCC700 panel, but then waits
//					until TimeOut (Axon recommends 3 seconds for timeout), and finally also chanbes the mode tab 
//					(and issues the above mentioned error).
//					During this TimeOut period of 3 seconds the systems seems blocked.
//				These 2 flaws do not occur when Axon's  'TestBed' application is run directly without IGOR.
//				As long as the reason for this strange behavior is not resolved, the program is made to work
//				with the brute force method:
//				1. the errors are suppressed.
//				2.	the TimeOut is set to 1 millisecond.
//				Both should be corrected as soon as possible..............



#include <stdio.h>
#include <windows.h>					// defines BOOL, UINT, WINAPI etc. needed in AxMultiClampMsg.h

#include "C:\Program files\wavemetrics\IgorXOPs\XOPSupport\XOPStandardHeaders.h"// Include ANSI headers, Mac headers, IgorXOP.h, XOP.h and XOPSupport.h

#include "AxMultiClampMsg.h"		// (3 lines changed..) , also needed :  AxMultiClampMsg.lib
#include "XopMain.h"					// for IHC()



int UFP_MCCMSG_CheckAPIVersion();
int UFP_MCCMSG_CreateObject();
int UFP_MCCScanMultiClamps();
int UFP_MCCMSG_SelectMultiClamp();
int UFP_MCCMSG_SetMode();
int UFP_MCCMSG_GetMode();
int UFP_MCCMSG_SetPrimSignalGain();
int UFP_MCCMSG_GetPrimSignalGain();
int UFP_MCCMSG_GetSecoSignalGain();
int UFP_MCCMSG_Reset();
int UFP_MCCMSG_DestroyObject();


#pragma pack(4)					// All structures are 4-byte-aligned for MCTG


// GLEICHE REIHENFOLGE HIER IN  '(*sFunc[])' UND IN CED1401WinCustom.RC
// Eine neue Operation einfügen: exakt 4x (->Edit->Find)

FUNC sFunc[] =
{
	// START OF MULTICLAMP CONTROL INTERFACE
   { UFP_MCCMSG_CheckAPIVersion			},  
   { UFP_MCCMSG_CreateObject				},  
   { UFP_MCCScanMultiClamps				},  
   { UFP_MCCMSG_SelectMultiClamp			},  
   { UFP_MCCMSG_SetMode						},  
   { UFP_MCCMSG_GetMode						},  
   { UFP_MCCMSG_SetPrimSignalGain	},  
   { UFP_MCCMSG_GetPrimSignalGain	},  
   { UFP_MCCMSG_GetSecoSignalGain	},  
   { UFP_MCCMSG_Reset						},  
   { UFP_MCCMSG_DestroyObject				},  
	// END   OF MULTICLAMP CONTROL INTERFACE

   {    NULL       }					// end marker
};

////////////////////////////////////////////////////////////////////////


#pragma pack()						// All structures are 4-byte-aligned for MCTG.


//==============================================================================================
// FUNCTION: DisplayErrorMsg
// PURPOSE:  

void		DisplayErrorMsg( HMCCMSG hMCCmsg, int nError )
{
   char szError[256] = "";
   MCCMSG_BuildErrorText( hMCCmsg, nError, szError, sizeof(szError) );
	XOPNotice( "++Warning: " );
	XOPNotice( szError );
	XOPNotice( "\r" );
}


//==============================================================================================
// FUNCTION: UFP_MCCMSG_CheckAPIVersion
// PURPOSE:
  
int		UFP_MCCMSG_CheckAPIVersion( struct { DOUBLE nRes;	}*p )
{
	int	nCode	= MCCMSG_CheckAPIVersion( MCCMSG_APIVERSION_STR );
	if ( ! nCode )
		XOPNotice("Version mismatch: AXMULTICLAMPMSG.DLL\r" );
	p->nRes	= (DOUBLE)nCode;
	return 0;
}


//==============================================================================================
// FUNCTION: UFP_MCCMSG_CreateObject
// PURPOSE:  create the DLL handle

int		UFP_MCCMSG_CreateObject( struct { DOUBLE dRes;	}*p )
{
	int	nError	= 0;
	HMCCMSG hMCCmsg;
   UINT	uTimeOut = 1; // milliseconds, set timeout to 3 sec,

	if( !MCCMSG_CheckAPIVersion(MCCMSG_APIVERSION_STR) )
   {
		XOPNotice("Version mismatch: AXMULTICLAMPMSG.DLL\r" );
      return 0;
   }

	hMCCmsg  = MCCMSG_CreateObject( &nError );
	if( !hMCCmsg )
   {
		DisplayErrorMsg( hMCCmsg, nError );
      return 0;
   }
	p->dRes	= (DOUBLE)((UINT)hMCCmsg);					// convert pointer to struct HMCCMSG to Igor's double 

   // set timeout to 3 sec, default is also 3 sec
   if( !MCCMSG_SetTimeOut( hMCCmsg, uTimeOut, &nError) )
   {
		DisplayErrorMsg( hMCCmsg, nError );
      return 0;
   }

	return 0;
}

//==============================================================================================
// FUNCTION: UFP_MCCMSG_SelectMultiClamp
// PURPOSE:  select a MultiClamp defined by it's ID. The selection is invisible, there is no handle returned.

int		UFP_MCCMSG_SelectMultiClamp( struct { DOUBLE uChannelID; DOUBLE uDeviceID; DOUBLE uCOMPortID;
									 Handle sSerialNumber; DOUBLE uModel; DOUBLE hMCCmsg; DOUBLE nRes; }*p )
{
	HMCCMSG	hMCCmsg	= (void*)((UINT)p->hMCCmsg);		// convert Igor's double to pointer to struct HMCCMSG
	int		nError	= 0;
// 041203
// int		hState;
// Handle	szSerialNumber	= IHC2( p->sSerialNumber, &hState );	// get pointer to a C-type string
   Handle	szSerialNumber	= IHC( p->sSerialNumber );	// get pointer to a C-type string

	int	nCode = MCCMSG_SelectMultiClamp( hMCCmsg, (UINT)p->uModel, *szSerialNumber,
														(UINT)p->uCOMPortID, (UINT)p->uDeviceID, (UINT)p->uChannelID, &nError );
//	{ char sBuf[456]; sprintf( sBuf, "UFP_MCCMSG_SelectMultiClamp..   hMCCmsg:%d=0x%x sets nError:%d=0x%x , returns nCode:%d=0x%x mo:%d '%s' po:%d de:%d  ch:%d \r",
//		hMCCmsg, hMCCmsg, nError, nError, nCode , nCode, (UINT)p->uModel, *szSerialNumber, (UINT)p->uCOMPortID, (UINT)p->uDeviceID, (UINT)p->uChannelID ) ; XOPNotice( sBuf); }

	if ( ! nCode )
		DisplayErrorMsg( hMCCmsg, nError);

// 041203
//	IHCDisposeHandle2( szSerialNumber, &hState );		// avoid memory leak
	DisposeHandle( szSerialNumber );							// avoid memory leak
	p->nRes	= (DOUBLE)nCode;									// the return value of the XOP will be the error indicator
	return 0;
}

 		
//==============================================================================================
// FUNCTION: UFP_MCCMSG_SetMode
// PURPOSE:  set mode to voltage clamp or current clamp

int		UFP_MCCMSG_SetMode( struct { DOUBLE nMode; DOUBLE hMCCmsg; DOUBLE nRes; }*p )
{
	HMCCMSG	hMCCmsg  = (void*)((UINT)p->hMCCmsg);	// convert Igor's double to pointer to struct HMCCMSG
	int		nError	= 0;
	int		nCode		= MCCMSG_SetMode( hMCCmsg, (UINT)p->nMode, &nError );
	if ( ! nCode )
// Removed 040410 , see remarks above
//		DisplayErrorMsg( hMCCmsg, nError);
		;
	p->nRes	= TRUE;//(DOUBLE)nCode;
//	{ char sBuf[256]; sprintf( sBuf, "SetMode..   hMCCmsg:%d=0x%x sets nError:%d=0x%x , returns nCode:%d=0x%x \r",  hMCCmsg, hMCCmsg, nError, nError, nCode , nCode ) ; XOPNotice( sBuf); }
	return 0;
}
		
//==============================================================================================
// FUNCTION: UFP_MCCMSG_GetMode
// PURPOSE:  return the mode (voltage clamp or current clamp)

int		UFP_MCCMSG_GetMode( struct { DOUBLE hMCCmsg; DOUBLE nRes; }*p )
{
	HMCCMSG	hMCCmsg  = (void*)((UINT)p->hMCCmsg);	// convert Igor's double to pointer to struct HMCCMSG
	int		nError	= 0;
	int		nMode		= -1;
	int		nCode		= MCCMSG_GetMode( hMCCmsg, &nMode, &nError );
	if ( ! nCode )
		DisplayErrorMsg( hMCCmsg, nError);
	p->nRes	= (DOUBLE)nMode;								// the return value of the XOP will be VC or IC
	return 0;
}

		
//==============================================================================================
// FUNCTION: UFP_MCCMSG_SetPrimSignalGain
// PURPOSE:  return the Gain

int		UFP_MCCMSG_SetPrimSignalGain( struct { DOUBLE Gain; DOUBLE hMCCmsg; DOUBLE nRes; }*p )
{
	HMCCMSG	hMCCmsg  = (void*)((UINT)p->hMCCmsg);	// convert Igor's double to pointer to struct HMCCMSG
	int		nError	= 0;
	int		nCode		= MCCMSG_SetPrimarySignalGain( hMCCmsg, p->Gain, &nError );
	if ( ! nCode )
// Removed 040410 , see remarks above
//		DisplayErrorMsg( hMCCmsg, nError);
		;
	p->nRes	= (DOUBLE)nCode;								// the return value of the XOP will be the error indicator
	return 0;
}
		
//==============================================================================================
// FUNCTION: UFP_MCCMSG_GetPrimSignalGain
// PURPOSE:  get gain (voltage clamp or current clamp)

int		UFP_MCCMSG_GetPrimSignalGain( struct { DOUBLE hMCCmsg; DOUBLE dRes; }*p )
{
	HMCCMSG	hMCCmsg  = (void*)((UINT)p->hMCCmsg);	// convert Igor's double to pointer to struct HMCCMSG
	int		nError	= 0;
	double	Gain		= 0;
	int		nCode		= MCCMSG_GetPrimarySignalGain( hMCCmsg, &Gain, &nError );
	if ( ! nCode )
		DisplayErrorMsg( hMCCmsg, nError);
	p->dRes	= Gain;											// the return value of the XOP will be the Gain
	return 0;
}

//==============================================================================================
// FUNCTION: UFP_MCCMSG_GetSecoSignalGain
// PURPOSE:  get gain (voltage clamp or current clamp)

int		UFP_MCCMSG_GetSecoSignalGain( struct { DOUBLE hMCCmsg; DOUBLE dRes; }*p )
{
	HMCCMSG	hMCCmsg  = (void*)((UINT)p->hMCCmsg);	// convert Igor's double to pointer to struct HMCCMSG
	int		nError	= 0;
	double	Gain		= 0;
	int		nCode		= MCCMSG_GetSecondarySignalGain( hMCCmsg, &Gain, &nError );
	if ( ! nCode )
		DisplayErrorMsg( hMCCmsg, nError);
	p->dRes	= Gain;											// the return value of the XOP will be the Gain
	return 0;
}
		

//==============================================================================================
// FUNCTION: UFP_MCCMSG_Reset
// PURPOSE:  set mode to voltage clamp or current clamp

int		UFP_MCCMSG_Reset( struct { DOUBLE hMCCmsg; DOUBLE nRes; }*p )
{
	HMCCMSG	hMCCmsg  = (void*)((UINT)p->hMCCmsg);	// convert Igor's double to pointer to struct HMCCMSG
	int		nError	= 0;
	int		nCode		= MCCMSG_Reset( hMCCmsg, &nError );
// NOT Removed 040410 to trigger the error . See remarks above
	if ( ! nCode )
		DisplayErrorMsg( hMCCmsg, nError);
	p->nRes	= (DOUBLE)nCode;								// the return value of the XOP will be the error indicator
	return 0;
}
		
//==============================================================================================
// FUNCTION: UFP_MCCMSG_DestroyObject
// PURPOSE:  set mode to voltage clamp or current clamp

int		UFP_MCCMSG_DestroyObject( struct { DOUBLE hMCCmsg; DOUBLE nRes; }*p )
{
	extern char	gsAllMultiClamps[];
	HMCCMSG		hMCCmsg  = (void*)((UINT)p->hMCCmsg);	// compiling is ok
	MCCMSG_DestroyObject( hMCCmsg );
	hMCCmsg	= NULL;
	// clear previous MultiClamp identification list
	strcpy( gsAllMultiClamps, "" );
	p->nRes	= 1;
	return 0;
}
		
//==============================================================================================
// FUNCTION: UFP_MCCScanMultiClamps
// PURPOSE:  fill a global list containing all open MultiClamps (700A and 700B)

char		gsAllMultiClamps[ 1024 ]= "";

int		ScanMultiClamps( HMCCMSG hMCCmsg );

int		UFP_MCCScanMultiClamps( struct { DOUBLE hMCCmsg; Handle sRes;	}*p )
{
	extern char	gsAllMultiClamps[];
   Handle		str1		= NIL;
   char			errbuf[300]; 
   int			len, nCode	= 0;

	HMCCMSG		hMCCmsg  = (void*)((UINT)p->hMCCmsg);	// convert Igor's double value into a pointer/Handle

	nCode	= ScanMultiClamps( hMCCmsg );						// fills string list 'gsAllMultiClamps' with MC identification
	if ( ! nCode )
      XOPNotice( "++++Error: UFP_MCCScanMultiClamps(): TimeOut or no MultiClamp found. Aborted...\r");

	len	= strlen( gsAllMultiClamps );
   if (( str1 = NewHandle( len )) == NIL )				// get output handle , do not provide space for '\0' 
   {
      sprintf( errbuf, "++++Error: UFP_MCCScanMultiClamps(): Not enough memory. Aborted...\r");
      XOPNotice( errbuf );
      nCode = NOMEM;											 // out of memory
   }
   else															 // string length is OK so return string 
		memcpy( *str1, gsAllMultiClamps, len );			// copy local temporary buffer WITHOUT \0 to persistent Igor output string 

	// for debugging
	// sprintf( errbuf, " UFP_MCCScanMultiClamps():  '%s' \r", *str1 );
	// errbuf[ len ] = '\0';										// *str has no string end so we append it just for the printing
	// XOPNotice( errbuf );  

	p->sRes = str1;
   return 0;
}
	
	
int		ScanMultiClamps( HMCCMSG hMCCmsg )
{
	extern char	gsAllMultiClamps[];
	char	sOneMultiClamp[ 256 ]	= "";
	int	nError, nIndex = 0;
 
	char szError[256]		= "";
	char szSerialNum[16]	= "";
	int  uModel				= 0;
	UINT uCOMPortID		= 0;
	UINT uDeviceID			= 0;
	UINT uChannelID		= 0;


// Removed 040410 , see remarks above
/*
   // set timeout to 1 sec, all MultiClamps Commanders must respond within 1 sec 
	UINT uTimeOut = 1000; // milliseconds
   if( !MCCMSG_SetTimeOut( hMCCmsg, uTimeOut, &nError) )
   {
      DisplayErrorMsg( hMCCmsg, nError);
      return 0;
   }
*/
   // find first multiclamp
   if( !MCCMSG_FindFirstMultiClamp( hMCCmsg, &uModel, szSerialNum, sizeof(szSerialNum), &uCOMPortID, &uDeviceID, &uChannelID, &nError) )
   {
      DisplayErrorMsg( hMCCmsg, nError);
		return 0;
   }

	// clear previous MultiClamp identification list
	strcpy( gsAllMultiClamps, "" );

   // find next multiclamps until none are found
   while( 1 )
   {  
		
		sprintf( sOneMultiClamp, "%d;%s;%d;%d;%d;~", uModel, szSerialNum, uCOMPortID, uDeviceID, uChannelID );// Assumption: Order is MoSeCoDeCh (as in Igor) 
	
      // build string list from multiclamp details
		strcat( gsAllMultiClamps, sOneMultiClamp );
      nIndex++;

      // search for another multiclamp, break when FALSE
      if( !MCCMSG_FindNextMultiClamp(hMCCmsg, &uModel, szSerialNum, sizeof(szSerialNum), &uCOMPortID, &uDeviceID, &uChannelID, &nError) )
         break;
   }

// Removed 040410 , see remarks above
/*
   // restore timeout to 3 sec because some auto commands can take more than 2 secs.
   uTimeOut = 3000; // milliseconds
   if( !MCCMSG_SetTimeOut(hMCCmsg, uTimeOut, &nError) )
   {
      DisplayErrorMsg( hMCCmsg, nError);
      return 0;
   }
*/
	return 1;
}

