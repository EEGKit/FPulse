//
// FP_MC700Tg.c 	XOP based on Igors sample WindowXOP needed to get Axons MultiClamp700 Telegraph data into FPulse


// History
// 060325 the string containing the gains which is transmitted to IGOR also contains dScaleFactor and uScaleFactorUnits

// 04feb27  this assertion fails regularly if the user presses 'Analysis' too fast after starting Igor
// If the user waits appr. 1 s after starting IGOR before pressing 'Analysis' the assertion is OK 		
// As everything seems to work correctly inspite of the assertion failing the message is removed.
//		ASSERT( uRetVal != 0, "Kill1 'Connect' timer " );
//		ASSERT( uRetVal != 0, "Kill1 'Reconnect' timer " );



/*
There were a bunch of problems regarding the 'software-controlled' telegraph connection between
Axons MultiClamp700  and  FPulse.
In response to the biggest problem I got 2 answers from the Igor mailing list.
It seems to work  but as I have not fully understood what's really going on 
I  will make some rather descriptive comments and remarks below..  

Problem 1 = Question: 
Can an XOP window receive any kind of message from another Windows application? 
The  MC700 sends 2 types of messages: the standard Windows 'WM_COPYDATA' 
messages and another custom type which uses the 'RegisterWindowsMessage()  
and 'PostMessage()'  functions. When using the 'WindowXOP' a
as a starting point I am able to receive the 'WM_COPYDATA' without problems but the other type 
does not appear in the message loop. I suppose this has to do with the fact that 
(according to Windows documentation)  'PostMessage()' does  NOT send to child windows whereas 
XOP windows MUST BE MDI child windows (according to the XOP Toolkit documentation).
I do receive both types of messages in a non-Igor Windows SDK- or MFC-based program 
(the sample 'MCTeleClient' as supplied by Axon).
What window do I have to use in IGOR to receive a message sent 
by  'RegisterWindowsMessage()  and 'PostMessage()'  ?


Reply 1:

I handle this problem by using a message hook.  The code I use looks something like this:

// {global variables}
HHOOK RegisteredMsgHook;

// {In your main procedure add}
RegisteredMsgHook = SetWindowsHookEx(WH_GETMESSAGE,&GetMsgFirstProc,NULL,GetCurrentThreadId());

//{Callback procedure}
LRESULT CALLBACK GetMsgFirstProc(int code,WPARAM wParam,LPARAM lParam)
{
   MSG *msgPtr;
   
   if( code < 0 ) 
		return CallNextHookEx(RegisteredMsgHook,code,wParam,lParam);
   msgPtr = (MSG*)lParam;
   if( msgPtr->message == MY_SPECIALMESSAGE )
	{
      // {handle the message here}
   }
   return 0;
}
 

Reply 2:

I have a similar problem with the scientific instrument we sell which uses
Igor.  I'm writing this message from home, so the exact function names might
be wrong, but here is the situation.


The one function that returns a window handle to you in the XOP toolkit 
called IgorClientHWNDindow() actually
returns the handle to the MDI Main Frame and not the actual main program
window that encompasses the entire application.  However, it is quite easy
to get to the master window handle.  Just use the Win32 function called
GetParent() on the handle that is given by Igor.  Once you have that main
handle, you can use this handle to register for events and then hijack
Igor's main message loop (I've done this with great success) and receive the
messages you are after.



Remarks to the code:

1. The code looks a bit clumsy. 
As described above the 'reconnect' message cannot be handled in Igors message loop,
so we introduce 'SetWindowsHookEx()', which works. 

To get rid of Igors message loop and window we use a 2. 'SetWindowsHookEx()'
with different parameters to handle 'WM_COPYDATA'. 

2. The hook function GetMsgFirstProc() is called very often, more often than needed, 
and it works although I cannot see if and where/when it is called in the
important place: in Igors XOP window.

3. As the 'Reconnect' message cannot be handled in Igors message loop, the Telegraph 
code sample cannot be taken as it is and might after changing behave differently.

4. The Telegraph sample is somehow strange: a reconnection is only attempted
when there has already been a connection. This leads to the user-non-friendly
consequence that turning on the MultiClamp700 after Igors FPULSE will never
get the connection working.  It would probably be better that FPULSE 
establishes the connection any time the MultiClamp700 is turned on no matter 
whether the MultiClamp700 was on or off before. 

5. Why is the WM_COPYDATA message received appr. 7 times when the MC700 is shut off?

6. The good news:
- The user does not have to establish the connection manually (e.g. pressing a button)
- There need not be an XOP function call, 
  everything is handled automatically once the XOP is loaded .
- There need not be an XOP window
  if there is an Igor XOP window to receive the 'WM_COPYDATA' it can be disposed immediately
  so the user does not see it. It does somehow sneak into one of the menus again, though.
  Also for this reason it is more elegant NOT to use the XOP window
- Igors XOP menu functions can be disposed of in any case


The big difference compared to Axons MCTeleClient Sample:

Axons MCTeleClient is MFC based. It uses a simple dialog class for connection.
Every instance of the class is ONE connection. There can be an unlimited number 
instances corresponding to different connections (diff. Ports, devices or channels)
or to the same connection.
In Igor (not having classes) we must handle things differently (and a bit clumsy):
We limit the number of connections to [ MAX_MC700CHANS ]
We must do the bookkeeping of channels and devices ourselves instead of letting 
the instances of the class do the job for us. Every member of the class must be 
indexed [ nMC ] ( nMC is combination of device, axobus and serial number ) .
Indexing is most important for the data structure containing the 
telegraphed data but also for the flags (e.g. bIsConnected)  and also the TimerIds.
(TimerIds are not really indexed but just 2 successive values).
*/

// History:
// 03April	also works without an XOP window (has much less overhead)  see the #define  in xxx.H
// 04Sept	recognise also MCC700B
//				detect when the MCC700 panel is turned on and off and react appropriately so that no user intervention is necessary
//				Flaw: program will fail when (in Demo mode) more than 1 700A panel or more than 1 700B panel is open.


#include <XOPStandardHeaders.h>

#include "XopMain.h"
#include "XopUtils.h" 

#include "FP_MC700Tg.h"			// sets MCTG_IGORMAINFRM: compile and link all code necessary for the MultiClamp telegraph connection	

#pragma pack(2)				// All structures are 2-byte-aligned for Igor Toolkit .


// SAME ORDER HERE IN  '(*sFunc[])' AND IN xxxWinCustom.RC

FUNC sFunc[] =
{

#ifdef MCTG_IGORMAINFRM			

	// START OF MULTICLAMP TELEGRAPH INTERFACE
   { xMCTgDebugMsg		},  
	{ xMCTgPickupInfo		},  
	// END   OF MULTICLAMP TELEGRAPH INTERFACE

#endif

   {    NULL       }			// End marker
};

////////////////////////////////////////////////////////////////////////

#pragma pack()					// All structures are default-aligned 


#ifdef MCTG_IGORMAINFRM			

#include "MCTelegraphs.h"

BOOL	gnDebugMsg = 0;				// determines whether MCTg debugging information is printed in Igors history area
											// set to 0...3 for DEBUG (to debug also startup code), set to 0 in the release version 
											// (can still be enabled  at run-time by calling from Igor xMCTgDebugMsg( 1 )  
HWND	gTheWindow = NULL;
HHOOK	gRegisteredMsgHook;
HHOOK	gCopydataMsgHook;

// UF   FOR  MCTELEGRAPH conversion to Igor ---------------------------------------------

#define  kTIMEOUT		1000		// was 1000

#define		 MAX_MC700CHANS					8		// 8 means 4 MultiClamps, as each unit has 2 channels 			
#define		 MAXSTRING_ALLCHAN			2048		// sufficient for 8 chs x 256 byte
#define		 kNOTFOUND						  -1
#define		 kSTRUCTURE_SIZE_700A		 128		// we use the new 700B structure size of 256 also for the 700A
#define		 k700A_HAS_NO_SERIAL_NUMBER  -1
#define		 nCOPYDATA_MESSAGES_WHEN_DISCONNECTING	4

void			 MCTgClientInitialize( UINT nMC );
void			 OnConnect( HWND m_hWnd, UINT nMC );
int			 ProcessReconnectMsg( HWND hwnd, LPARAM SignalID );
//int			 ProcessCloseMsg( HWND hwnd, LPARAM SignalID );
int			 ProcessIdMsg( HWND hwnd, LPARAM SignalId );
int			 ProcessTimerMsg( HWND hwnd, WPARAM TimerId );	//todo return TRUE,FALSE or break????
int			 ProcessCopydataMsg( HWND hwnd, LPARAM ptrCopydataStruct );	//todo return TRUE,FALSE or break????
void			 UpdateDisplay( HWND hwnd, UINT nMC );
int			 MarkDeadConnection(  HWND hwnd, int nMC );
int			 ChanPort2Index( int tp, int sn, int po, int ab, int ch );
void			 Index2ChanPort( int nMC, int* tp, int* sn, int* po, int* ab, int* ch );
void			 PrintIdx( char* sTxt, int nMC, char* sDir, int tp, int po, int ab, int ch, int sn );
char			*Flags( int nMC, char* sToCg, char* sToCd );
//void			 Flags1( char* sTxt, int nMC, char* sToCg, char* sToCd );

static       UINT nGOpenMessage          = 0;			// sent by	Client = Igor
static       UINT nGCloseMessage         = 0;			//				Client = Igor
static       UINT nGRequestMessage       = 0;			//				Client = Igor
static       UINT nGBroadcastMessage     = 0;			//				Client = Igor
static       UINT nGReconnectMessage     = 0;			//	sent by	Server = MC700
static       UINT nGIdMessage            = 0;			//				Server = MC700

static const UINT nBroadcastTimerEventID	 = 13377 - 1;	// arbitrary  (for Igor, only 1 needed )
static const UINT nBroadcastTimerInterval	 = kTIMEOUT;	//1000 testing 	// millisec

static const UINT nConnectionTimerEventID  = 13377;	// arbitrary  (for Igor +ch+ab.. : 13377..13396)
static const UINT nConnectionTimerInterval = kTIMEOUT;		//testing test  OK is:1000;		// millisec

static const UINT nReconnectTimerEventID	 = 13377 + 1 * MAX_MC700CHANS;		// arbitrary  (for Igor +ch+ab.. : 13377..13396)
static const UINT nReconnectTimerInterval  = kTIMEOUT;		//testing test  OK is:1000;		// millisec

static const UINT nCopydataTimerEventID	 = 13377 + 2* MAX_MC700CHANS;		// arbitrary  (for Igor +ch+ab.. : 13377..13396)
static const UINT nCopydataTimerInterval	 = kTIMEOUT;		//testing test  OK is:1000;		// millisec

static const UINT nRequestTimerEventID     = 13377 + 3 * MAX_MC700CHANS;	// arbitrary  (for Igor +ch+ab.. : 24488..24507)
static const UINT nRequestTimerInterval    = kTIMEOUT;		// testing millisec

BOOL bIsConnectionOpen[ MAX_MC700CHANS ];				// TRUE if connected to a RESPONDING MultiClamp telegraph server (must be ON!)
BOOL bIsConnected[		MAX_MC700CHANS ];				// TRUE if connected to a MultiClamp telegraph server (even if Server is momentarily shut off)
BOOL bIsConnecting[		MAX_MC700CHANS ];				// TRUE if attempting to connect to a MultiClamp telegraph server
BOOL bAllowReconnect[	MAX_MC700CHANS ];				// TRUE only after some time after the last 'Reconnect', masks out erroneous 'Reconnects'
BOOL bRequestPending[	MAX_MC700CHANS ];				// TRUE if waiting for a requested packet from a MultiClamp telegraph server
int  nCopydata[			MAX_MC700CHANS ];				// counts COPYDATA messages during the Copydata timer interval, if they are numerous we assume...
																	//...that the connection has just been closed (purely empirical observation!)

MC_TELEGRAPH_DATA MCState[ MAX_MC700CHANS ];			// UF for multiple channels

char	gsAllChan[MAXSTRING_ALLCHAN]	= "";


void  ASSERT( UINT bIsOK, LPSTR msg )
{
	char line[200] = "Assertion failed: " ;
	if ( !bIsOK )
	{
		strcat( line, msg );
		strcat( line, "\r" );
		XOPNotice( line );
	}
}


//   700A  Format for packed LPARAM of MultiClamp 700A signal identifiers
//   ------------------------------------------------------------------   
//   | Byte 3            | Byte 2           | Byte 1    | Byte 0      |	??????
//   ------------------------------------------------------------------
//   | Channel ID (High) | Channel ID (Low) | AxoBus ID | Com Port ID |
//   ------------------------------------------------------------------

LPARAM MCTG_PackSignalIDs( UINT uComPortID, UINT uAxoBusID, UINT uChannelID )
// Packs MultiClamp signal identifiers into an LPARAM suitable for transmission with a telegraph message.
{
   LPARAM lparamSignalIDs = 0;
   lparamSignalIDs |= ( uComPortID       );
   lparamSignalIDs |= ( uAxoBusID  <<  8 );
   lparamSignalIDs |= ( uChannelID << 16 );
   return lparamSignalIDs;
}

int	MCTG_UnpackSignalIDs( LPARAM lparamSignalIDs,UINT *puComPortID, UINT *puAxoBusID, UINT *puChannelID       )
// Unpacks MultiClamp signal identifiers from an LPARAM used for transmission with a telegraph message.
// returns kNOTFOUND or HardwareType
{
	char	sMsg[2000];
 	if( puComPortID == NULL || puAxoBusID == NULL || puChannelID == NULL )
      return kNOTFOUND;

   *puComPortID = ( (UINT) lparamSignalIDs       ) & 0x000000FF;
   *puAxoBusID  = ( (UINT) lparamSignalIDs >>  8 ) & 0x000000FF;
   *puChannelID = ( (UINT) lparamSignalIDs >> 16 ) & 0x0000FFFF;

	if ( *puComPortID == 0 || *puComPortID > 3 || *puAxoBusID >= 10 || *puChannelID == 0  || *puChannelID >= 3 )	// is 700B (having broken it's serial number)
	{
		if ( gnDebugMsg > 2 ) { XOPNotice( "\t\tUnpacking 700A signals: Failed...\r" ); }
		return kNOTFOUND;
	}
		
	if ( gnDebugMsg > 2 ) { sprintf( sMsg, "\t\tUnpacking 700A signals. Returning  tp:%d < po:%2d  ab:%2d  ch:%2d \r", MCTG_HW_TYPE_MC700A, *puComPortID, *puAxoBusID, *puChannelID );	XOPNotice( sMsg ); }

	return MCTG_HW_TYPE_MC700A;
}

BOOL   MCTG_MatchSignalIDs( UINT uComPortID, UINT uAxoBusID, UINT uChannelID, LPARAM lparamSignalIDs )
// Determines if the specified MultiClamp signal identifiers match those in the given packed LPARAM
// returns kNOTFOUND or HardwareType
{
   UINT uTelegraphedComPortID = 0;
   UINT uTelegraphedAxoBusID  = 0;
   UINT uTelegraphedChannelID = 0;

   if( MCTG_UnpackSignalIDs( lparamSignalIDs, &uTelegraphedComPortID, &uTelegraphedAxoBusID, &uTelegraphedChannelID ) == kNOTFOUND )
        return FALSE;
  
	if( ( uChannelID == uTelegraphedChannelID ) &&
		 ( uComPortID == uTelegraphedComPortID ) &&
       ( uAxoBusID  == uTelegraphedAxoBusID  ) )
      return TRUE;
   else
      return FALSE;
}


//   700B  Format for packed LPARAM of MultiClamp 700B signal identifiers
//   -------------------------------------------------------------------------   
//   | Byte 3 (high nibble) | Byte 3 (low nibble) | Byte 2 | Byte 1 | Byte 0 |
//   -------------------------------------------------------------------------
//   | Channel ID (4bits)   | Serial Number (28 bits)                        |
//   -------------------------------------------------------------------------

// FUNCTION:   MCTG_Pack700BSignalIDs
// PURPOSE:    Packs MultiClamp signal identifiers into an LPARAM suitable for transmission with a telegraph message.

LPARAM MCTG_Pack700BSignalIDs( UINT uSerialNum, UINT uChannelID  )
{
   LPARAM lparamSignalIDs = 0;
   lparamSignalIDs |= ( uSerialNum & 0x0FFFFFFF );
   lparamSignalIDs |= ( uChannelID << 28 );
   return lparamSignalIDs;
} 

// FUNCTION:   MCTG_Unpack700BSignalIDs
// PURPOSE:    Unpacks MultiClamp signal identifiers from an LPARAM used for transmission with a telegraph message.

int	MCTG_Unpack700BSignalIDs( LPARAM lparamSignalIDs, UINT *puSerialNum, UINT *puChannelID )
{
	char  sMsg[2000];
	if( puSerialNum == NULL || puChannelID == NULL )
      return kNOTFOUND;

   *puSerialNum = ( (UINT) lparamSignalIDs       ) & 0x0FFFFFFF;
   *puChannelID = ( (UINT) lparamSignalIDs >> 28 ) & 0x0000000F;

	if ( gnDebugMsg > 2 ) { sprintf( sMsg, "\t\tUnpacking 700B signals...found ch:%d and  sn:%016d  Returning tp:%d \r", *puChannelID, *puSerialNum, MCTG_HW_TYPE_MC700B );	XOPNotice( sMsg ); }

   return MCTG_HW_TYPE_MC700B;
}

// FUNCTION:   MCTG_Match700BSignalIDs
// PURPOSE:    Determines if the specified MultiClamp signal identifiers match those in the given packed LPARAM

BOOL   MCTG_Match700BSignalIDs( UINT uSerialNum, UINT uChannelID, LPARAM lparamSignalIDs )
{
   UINT uTelegraphedSerialNum = 0;
   UINT uTelegraphedChannelID = 0;

   if( MCTG_Unpack700BSignalIDs( lparamSignalIDs, &uTelegraphedSerialNum, &uTelegraphedChannelID ) == kNOTFOUND )
   {  
      return FALSE;
   }

   if( ( uSerialNum == uTelegraphedSerialNum ) && ( uChannelID == uTelegraphedChannelID ) )
   {
      return TRUE;
   }
   else
   {
      return FALSE;
   }
}


//---------------------------------------------------------------------------------
// TIMERNUMBER <--> Channel, AXOBUS, COM PORT

void	Timer2Chans( UINT TimerId, UINT TimerBase, UINT* nMC )
{
	*nMC	= ( TimerId - TimerBase );
}

UINT	Chans2Timer( UINT TimerBase, UINT nMC )
{
	return TimerBase + nMC;
}


//---------------------------------------------------------------------------------

void	MCTgClientRegisterMessages( void )
// called once in main()
{
	//char	sMsg[2000];
	int	nMC = 0;

   nGOpenMessage = RegisterWindowMessage( MCTG_OPEN_MESSAGE_STR );
   ASSERT( nGOpenMessage != 0, "open" );
   //sprintf ( sMsg, "\tMCTgClientRegisterMessages() Msg Open     :0x%08X \r",  nGOpenMessage ); XOPNotice( sMsg);

   nGCloseMessage = RegisterWindowMessage( MCTG_CLOSE_MESSAGE_STR );
   ASSERT( nGCloseMessage != 0, "close" );
	//sprintf ( sMsg, "\tMCTgClientRegisterMessages() Msg Close    :0x%08X \r",  nGCloseMessage ); XOPNotice( sMsg);

   nGRequestMessage = RegisterWindowMessage( MCTG_REQUEST_MESSAGE_STR );
   ASSERT( nGRequestMessage != 0, "Request" );
	//sprintf ( sMsg, "\tMCTgClientRegisterMessages() Msg Request  :0x%08X \r",  nGRequestMessage ); XOPNotice( sMsg);

   nGReconnectMessage = RegisterWindowMessage( MCTG_RECONNECT_MESSAGE_STR );
   ASSERT( nGReconnectMessage != 0, "Reconnect" );
	//sprintf ( sMsg, "\tMCTgClientRegisterMessages() Msg Reconnect:0x%08X \r",  nGReconnectMessage ); XOPNotice( sMsg);

   nGBroadcastMessage = RegisterWindowMessage( MCTG_BROADCAST_MESSAGE_STR );
   ASSERT( nGBroadcastMessage != 0, "Broadcast" );
	//sprintf ( sMsg, "\tMCTgClientRegisterMessages() Msg Broadcast:0x%08X \r",  nGBroadcastMessage ); XOPNotice( sMsg);

   nGIdMessage = RegisterWindowMessage( MCTG_ID_MESSAGE_STR );
   ASSERT( nGIdMessage != 0, "Id " );
	//sprintf ( sMsg, "\tMCTgClientRegisterMessages() Msg Id       :0x%08X \r",  nGIdMessage ); XOPNotice( sMsg);

/*
	// Initialisation
   for ( nMC = 0; nMC < MAX_MC700CHANS ; nMC += 1 )
	{
		bIsConnected[	  nMC ] = TRUE;			// TRUE triggers automatic connection process anytime when the server starts
		bAllowReconnect[ nMC ] = TRUE;			// TRUE only after some time after the last 'Reconnect', masks out erroneous 'Reconnects'
	}
*/
}


int	MCTgClientInitializeState( void )
{
	int	nMC;
   for ( nMC = 0; nMC < MAX_MC700CHANS ; nMC += 1 )
	{
		MCTgClientInitialize( nMC );
	}
 	strcpy( gsAllChan, "" );
	return MAX_MC700CHANS;
}


void	MCTgClientInitialize( UINT nMC )
{
	MC_TELEGRAPH_DATA* pmctd;
	// Initialize the current telegraph state. This bit will zero out the padding in the structure
	pmctd = &MCState[nMC];
	memset(pmctd, 0, sizeof(MC_TELEGRAPH_DATA));
}


int	MCTgResetFlags( void )
{
	int	nMC;
   for ( nMC = 0; nMC < MAX_MC700CHANS ; nMC += 1 )
	{
		bIsConnectionOpen[nMC]	= FALSE;
		bIsConnected[		nMC]	= FALSE;
		bIsConnecting[		nMC]	= FALSE;
		bAllowReconnect[	nMC]	= FALSE;
		bRequestPending[	nMC]	= FALSE;
	
	}
	return MAX_MC700CHANS;
}


//--------------------------------------------------------------------------------------------
// THE WINDOW HOOK FUNCTIONS WHICH catch the MESSAGES WE ARE INTERESTED IN

LRESULT CALLBACK GetMsgFirstProc( int code, WPARAM wParam, LPARAM lParam )
{
	MSG		*msgPtr;
   if( code < 0 ) 
		return CallNextHookEx( gRegisteredMsgHook, code, wParam, lParam );

	msgPtr = (MSG*)lParam;
	
	if( msgPtr->message == nGReconnectMessage )
	{
		// the right wnd handle to pass is gTheWindow , it is NOT msgPtr->hwnd !
		ProcessReconnectMsg( gTheWindow, msgPtr->lParam );	// process telegraph 'Reconnect' message
	}

	// process telegraph 'Id' message. Must be tested WITH REAL MultiClamp700, will not work in Demo mode.
	if ( msgPtr->message == nGIdMessage )
	{
		ProcessIdMsg( gTheWindow, msgPtr->lParam );			// display the identification details of the server.
	}

	/* Not useful : applicable only when Igor closes the connection. Needed: a signal sent when the MC is turned off.
	if ( msgPtr->message == nGCloseMessage )
	{
		ProcessCloseMsg( gTheWindow, msgPtr->wParam );
	}
	*/
	if ( msgPtr->message == WM_TIMER )
	{
		ProcessTimerMsg( gTheWindow, msgPtr->wParam );
	}

	return CallNextHookEx( gRegisteredMsgHook, code, wParam, lParam );		// recommended way to return
}


LRESULT CALLBACK CallWndProc( int code, WPARAM wParam, LPARAM lParam )
{
	CWPSTRUCT*				msgPtr;

   if( code < 0 ) 
		return CallNextHookEx( gCopydataMsgHook, code, wParam, lParam );

	// handle the WM_COPYDATA message (which does not appear in Igors XOP child windows wndproc)
	msgPtr = (CWPSTRUCT*)lParam;

	if ( msgPtr->message == WM_COPYDATA )
	{
		// the right wnd handle to pass is gTheWindow , it is NOT msgPtr->hwnd !
		ProcessCopydataMsg( gTheWindow, msgPtr->lParam );	//todo return TRUE,FALSE or break????
	}
	return CallNextHookEx( gCopydataMsgHook, code, wParam, lParam );		// recommended way to return
}


//-----------------------------------------------------------------------------------------------
// THE FUNCTIONS WHICH POST a MESSAGE TO THE QUEUE : Igor posts the message, MCC must respond

void	OnConnect( HWND hWnd, UINT nMC ) 
{
	char		sMsg[2000], sMsg1[200];
	LPARAM	lparamSignalIDs;
	UINT		uRetVal;
	int		tp, sn, ab, ch, po;

   ASSERT(hWnd != NULL, "Window handle in OnConnect() is NULL");

	Index2ChanPort( nMC, &tp, &sn, &po, &ab, &ch );
	MCState[nMC].uHardwareType	= tp;
	sprintf( MCState[nMC].szSerialNumber, "%016d", sn );
	MCState[nMC].uComPortID		= po + 1;					// zero-based -> one-based
	MCState[nMC].uAxoBusID		= ab;
	MCState[nMC].uChannelID		= ch + 1;					// zero-based -> one-based

	if ( tp == MCTG_HW_TYPE_MC700A )
		lparamSignalIDs = MCTG_PackSignalIDs( po + 1, ab, ch + 1 );
	else if (tp == MCTG_HW_TYPE_MC700B )
		lparamSignalIDs = MCTG_Pack700BSignalIDs( sn, ch + 1 );

	PrintIdx( sMsg1, nMC, " :", tp, po+1, ab, ch+1, sn );
	if ( gnDebugMsg > 1 ) { sprintf( sMsg, "\tOnConnect1(.. \t\t\t\t(%s)\t\t\t\t%s\t \r", sMsg1, Flags( nMC, "->1", "  " ) ); XOPNotice( sMsg ); }

	bIsConnecting[nMC] = TRUE;

	if( !PostMessage( HWND_BROADCAST, nGOpenMessage, (WPARAM)hWnd, lparamSignalIDs ) )
   {
		Index2ChanPort( nMC, &tp, &sn, &po, &ab, &ch );	
      sprintf( sMsg, "++Warning: Can't open MC TG\t(%s)\t\t\t\t%s\tconnection with OnConnect. ", sMsg1, Flags( nMC, "->0", "  " ) ); 
		ASSERT(FALSE, sMsg );
      bIsConnecting[nMC] = FALSE;
   }

   // Set a timer event for the connection timeout
   uRetVal = SetTimer( hWnd, Chans2Timer(nConnectionTimerEventID, nMC), nConnectionTimerInterval, (TIMERPROC) NULL );	
   ASSERT( uRetVal != 0, "Set 'Connect' timer" );

   // Set a timer event for the 'Reconnect' timeout
	// this is introduced to avoid errors resulting from a peculiar MC behavior:
	// the MC700 repeatedly sends the same 'Reconnect' msg even for channels which have already been connected
	// we must avoid responding to those messages with 'OnConnect', if not an error occurs 
	// we use the 'Reconnect' timer to mask out / skip the erroneous MC700 'Reconnect' messages
	uRetVal = SetTimer( hWnd, Chans2Timer(nReconnectTimerEventID, nMC), nReconnectTimerInterval, (TIMERPROC) NULL );	
   ASSERT( uRetVal != 0, "Set 'Reconnect' timer" );
   bAllowReconnect[nMC] = FALSE;
      
	if ( gnDebugMsg > 1 ) { sprintf( sMsg, "\tOnConnect2(.. \t\t\t\t(%s)\t\t\t\t%s.0\t \r", sMsg1, Flags( nMC, "  ", "  " ) ); XOPNotice( sMsg ); }

   // the window procedure will handle the rest
}

/*  unused 
void	OnClose( HWND hWnd, UINT nMC )			// UNTESTED
{
	char		msg[200];
   LPARAM	lparamSignalIDs;
	int		tp, sn, ab, ch, po;

	if( bIsConnected[nMC] )
   {
      ASSERT(hWnd != NULL, "Window handle in OnClose()" );

		Index2ChanPort( nMC, &tp, &sn, &po, &ab, &ch );	
		MCState[nMC].uHardwareType	= tp;
		sprintf( MCState[nMC].szSerialNumber, "%016d", sn );
      MCState[nMC].uComPortID		= po + 1;					// zero-based -> one-based
	   MCState[nMC].uChannelID		= ch + 1;					// zero-based -> one-based
		MCState[nMC].uAxoBusID		= ab;

		if ( tp == MCTG_HW_TYPE_MC700A )
			lparamSignalIDs = MCTG_PackSignalIDs( po + 1, ab, ch + 1 );
		else if (tp == MCTG_HW_TYPE_MC700B )
			lparamSignalIDs = MCTG_Pack700BSignalIDs( sn, ch + 1 );

      // post telegraph close message
 		sprintf( msg, "\t\tOnClo post'Clo'\t(nMC:%d po:%d ab:%d ch:%d)\t%08X\t%08X\t%s\t-> wnd proc handles rest.. \r", 
							nMC, po+1, ab, ch+1, hWnd, lparamSignalIDs, Flags( nMC, "  ", "  " ) ); 
		XOPNotice( msg );
      if( !PostMessage( HWND_BROADCAST, nGCloseMessage, (WPARAM)hWnd, lparamSignalIDs ) )
      {
         ASSERT(FALSE, "++Warning: Failed to close connection! ");
      }

      bIsConnected[nMC] = FALSE;
   }
}
*/

void	OnRequest( HWND hWnd, UINT nMC )
{
	char		sMsg[2000], sMsg1[1000];
	LPARAM	SignalID;
   UINT		tp, sn, po, ab, ch;
	UINT		uRetVal;


	ASSERT( hWnd != NULL, "Window handle in OnRequest() is NULL" );

	Index2ChanPort( nMC, &tp, &sn, &po, &ab, &ch );
	if ( tp == MCTG_HW_TYPE_MC700A )
		SignalID = MCTG_PackSignalIDs( po + 1, ab, ch + 1 );
	else if (tp == MCTG_HW_TYPE_MC700B )
		SignalID = MCTG_Pack700BSignalIDs( sn, ch + 1 );

	if ( gnDebugMsg > 1 )
	{ 
		PrintIdx( sMsg1, nMC, " :", tp, po+1, ab, ch+1, sn );
		sprintf( sMsg, "\tOnRequest posts Req.Msg \t(%s)\t%08X\t%s\t-> wnd proc handles rest.. \t\t%d  '%s'\r",
									sMsg1, SignalID, Flags( nMC, "  ", "  " ), ItemsInList(gsAllChan,";"), gsAllChan );
		XOPNotice( sMsg );
	}

	bRequestPending[nMC]	= TRUE;
 	if ( ! PostMessage( HWND_BROADCAST, nGRequestMessage, (WPARAM)hWnd, SignalID) )   
	{
		ASSERT( FALSE, "++Warning: Failed to request telegraph packet" );
	}
   // set a timer event for the 'Request' timeout
   uRetVal = SetTimer( hWnd, Chans2Timer(nRequestTimerEventID, nMC), nRequestTimerInterval, (TIMERPROC) NULL );	
   ASSERT( uRetVal != 0, "Set 'Request' Timer" );
   
   // the window procedure will handle the rest
}


void	OnBroadcast( HWND hWnd )  
{
	char		sMsg[2000];
//	LPARAM		lparamSignalIDs;
	UINT		uRetVal;

   ASSERT(hWnd != NULL, "Window handle in OnBroadcast is NULL " );

	if ( gnDebugMsg > 1 ) { sprintf( sMsg, "\tOnBroadcast  post.'Broadcast' msg\t%08X   \t\t\t\t\t\t-> wnd proc handles rest..(wait for ID msg..) \r", hWnd); XOPNotice( sMsg ); }
   if( !PostMessage( HWND_BROADCAST, nGBroadcastMessage, (WPARAM) hWnd, (LPARAM)0 ) )
   {
      ASSERT(FALSE, "++Warning: Failed to broadcast to telegraph servers! ");
   }
   // set a timer event for the 'Broadcast' timeout
   uRetVal = SetTimer( hWnd, nBroadcastTimerEventID, nBroadcastTimerInterval, (TIMERPROC) NULL );	
   ASSERT( uRetVal != 0, "Set 'Broadcast' Timer" );

	// the window procedure will handle the rest
}


//----------------------------------------------------------------------------------
// THE MESSAGE HANDLER FUNCTIONS : MCC has posted the message, Igor must process it

int	ProcessReconnectMsg( HWND hWnd, LPARAM SignalID )
{
	char	sMsg[2000] = "empty\r", sMsg1[1000]; 
	int	nMC = 0, tp, tpA=kNOTFOUND, tpB=kNOTFOUND, sn = 0, po = 0, ch = 0, ab = 0;
	
	if (    ( tpA = MCTG_UnpackSignalIDs( SignalID, &po, &ab, &ch ) ) == kNOTFOUND	// the order matters: first 700A, then 700B
		  && ( tpB = MCTG_Unpack700BSignalIDs( SignalID, &sn, &ch  ) ) == kNOTFOUND )	// get axobus device and channel
	{ 
		sprintf( sMsg1, "++Warning: Could not unpack signal Id 0x%x = %d in PossiblyReconnect()/nGReconnectMessage...\r", SignalID, SignalID );
		XOPNotice( sMsg1 );
		return TRUE;
	}
	tp	 = max( tpA, tpB );
	ch -= 1;															// one-based -> zero-based
	po -= 1;
	nMC	= ChanPort2Index( tp, sn, po, ab, ch );
	PrintIdx( sMsg1, nMC, " :", tp, po+1, ab, ch+1, sn );


	if( ! bIsConnected[nMC] )
	{

		if( !bIsConnecting[nMC] )
		{
			if ( gnDebugMsg > 1 )
			{
				sprintf( sMsg, "\t\tProcessReconnectMsg0\t(%s)\t%08X\t%s\t\t\t\t-> Attempt to connect...\t'%s' \r",
										sMsg1, SignalID, Flags( nMC, "  ", "  " ), gsAllChan );
				XOPNotice( sMsg );
			}
			OnConnect( hWnd, nMC );
		}
	}
	
	if( bAllowReconnect[nMC] )
	{
		// resend the open message to reestablish the connection to the requesting server
		if ( gnDebugMsg > 1 )
		{ 
			sprintf( sMsg, "\t\tProcessReconnectMsg3\t(%s)\t%08X\t%s\t-> resend 'Open' to recon. to req. server\t'%s'  \r", 
								sMsg1, SignalID, Flags( nMC, "  ", "->0" ), gsAllChan );
			XOPNotice( sMsg );
		}
		bIsConnected[nMC] = FALSE;
		OnConnect(  hWnd, nMC );
	}
	else 
	{
		if ( gnDebugMsg > 1 )
		{ 
			sprintf( sMsg, "\t\tprocessreconnectMsg4\t(%s)\t%08X\t%s\t-> not sending 'Open' (prob.err.'Recon')\t'%s' \r",
							sMsg1, SignalID, Flags( nMC, "  ", "  " ), gsAllChan  );
			XOPNotice( sMsg );
		}
	}
	return TRUE;
}


/* Not useful : applicable only when Igor closes the connection. Needed: a signal sent when the MC is turned off.
int	ProcessCloseMsg( HWND hWnd, LPARAM SignalID )
{
	char	sMsg[2000], sMsg1[200]; 
	int	nMC = 0, tp, tpA=kNOTFOUND, tpB=kNOTFOUND, sn = 0, po = 0, ch = 0, ab = 0;
	
	if (    ( tpA = MCTG_UnpackSignalIDs( SignalID, &po, &ab, &ch ) ) == kNOTFOUND
		  && ( tpB = MCTG_Unpack700BSignalIDs( SignalID, &sn, &ch  ) ) == kNOTFOUND )	// get axobus device and channel
	{
		XOPNotice( "++Warning: Could not unpack signal Id in ProcessCloseMsg()..\r" );
		return TRUE;
	}
	tp	 = max( tpA, tpB );
	ch -= 1;											// one-based -> zero-based
	po -= 1;
	nMC	= ChanPort2Index( tp, sn, po, ab, ch );	// 040927
	PrintIdx( sMsg1, nMC, " :", tp, po+1, ab, ch+1, sn );

	if ( gnDebugMsg > 1 )
	{ 
		sprintf( sMsg, "\t\tProcessCloseMsg \t\t(%s) \t\t\t%s\t  \r", sMsg1, Flags( nMC, "  ", "  " ) );
		XOPNotice( sMsg );
	}
	bIsConnected[nMC]			= FALSE;
	bIsConnectionOpen[nMC]	= FALSE;
  return TRUE;
}
*/


int	ProcessIdMsg( HWND hWnd, LPARAM SignalID )
// display the identification details of the server.
{
	int		nMC = 0, tpA=kNOTFOUND, tpB=kNOTFOUND, tp, sn = 0, po = 0, ab = 0, ch = 0;
	char		sMsg[2000], sMsg1[200];
	// OK: we got an answer to our broadcast. We are finished with this timer now and kill it to avoid the Time-Out error. 
	KillTimer( hWnd, nBroadcastTimerEventID );

	if (    ( tpA = MCTG_UnpackSignalIDs( SignalID, &po, &ab, &ch ) ) == kNOTFOUND	// the order matters: first 700A, then 700B
		  && ( tpB = MCTG_Unpack700BSignalIDs( SignalID, &sn, &ch  ) ) == kNOTFOUND )	// get axobus device and channel
	{
		sprintf( sMsg, "++Warning: Could not unpack signal Id in ProcessIdMsg(%08x)...\r", SignalID );
		XOPNotice( sMsg );
		return TRUE;
	}
	tp	 = max( tpA, tpB );
	ch -= 1;														// one-based -> zero-based
	po -= 1;
	nMC	= ChanPort2Index( tp, sn, po, ab, ch );

	PrintIdx( sMsg1, nMC, " :", tp, po+1, ab, ch+1, sn );
	
	if( !bIsConnecting[nMC] )
	{
		if ( gnDebugMsg > 1 )
		{ 
			sprintf( sMsg, "\t\tReceiving Telegraph ID   \t(%s)\t%08X\t%s\t-> Trying to connect..\t\t%d  '%s'\r",
									sMsg1, SignalID, Flags( nMC, "  ", "  " ), ItemsInList(gsAllChan,";"), gsAllChan );
			XOPNotice( sMsg );
		}
		OnConnect( hWnd, nMC );
	}
	else
	{
		if ( gnDebugMsg > 1 )
		{ 
			sprintf( sMsg, "\t\treceiving telegraph id   \t(%s)\t%08X\t%s\t-> Ignore (conn. in progr.)\t%d  '%s'\r",
									sMsg1, SignalID, Flags( nMC, "  ", "  " ), ItemsInList(gsAllChan,";"), gsAllChan );
			XOPNotice( sMsg );
		}
	}
	return TRUE;
}


int		ProcessTimerMsg( HWND hwnd, WPARAM TimerId )	//todo return TRUE,FALSE or break????
{
	int		nMC = 0;
	UINT		tp, sn, po, ab, ch;
	char		sMsg[2000],	sMsg1[2000];
	UINT		uRetVal;

	if ( nBroadcastTimerEventID == TimerId )
	{
      // 'Broadcast' timer has timed out without getting a response, we are no longer waiting for a response
		KillTimer( hwnd, nBroadcastTimerEventID );

		// Search all ComPorts and search all possible devices up to MAX_MC700CHANS
		// if only com port 1 is used in demo mode then searching com ports 2..4 is not necessary..
      //sprintf( sMsg, "Info (FPulseCed.xop): No AxoPatch MultiClamp found, starting in demo mode. Trying to connect.... \r" );
#ifdef _DEBUG
		sprintf( sMsg, "Info FP_MC700Tg.xop (debug): No AxoPatch MultiClamp found. \r" );
#else
		sprintf(sMsg, "Info FP_MC700Tg.xop (release): No AxoPatch MultiClamp found. \r");
#endif
		XOPNotice( sMsg );

		return TRUE;
	}


	if ( nConnectionTimerEventID <= TimerId && TimerId < nConnectionTimerEventID + MAX_MC700CHANS )
	{
      // connection timer has gone off, we are no longer attempting to connect
		Timer2Chans( TimerId, nConnectionTimerEventID, &nMC );
		bIsConnecting[nMC] = FALSE;
		uRetVal	= KillTimer( hwnd, TimerId );	//Chans2Timer( nConnectionTimerEventID, nMC ) );


	// 040227..040928  this assertion fails regularly if the user presses 'Analysis' too fast after starting Igor
	// If the user waits appr. 1 s after starting IGOR before pressing 'Analysis' the assertion is OK 		
	// As everything seems to work correctly inspite of the assertion failing the message is removed.
	ASSERT( uRetVal != 0, "Kill1 'Connect' timer " );
		
		if( !bIsConnected[nMC] )
		{
			// timed out without establishing a connection
			UINT		tp, sn, po, ab, ch;
			Index2ChanPort( nMC, &tp, &sn, &po, &ab, &ch );		
			PrintIdx( sMsg1, nMC, " :", tp, po+1, ab, ch+1, sn );

			sprintf( sMsg, "++Warning: Can't open MC700 TG\t(%s)\t\t\t\t%s\t[WM_TIMER:%d time out] \r", sMsg1, Flags( nMC, "  ", "  " ), TimerId  ); 
		   XOPNotice( sMsg );
		}
		return TRUE;
	}

	if ( nReconnectTimerEventID <= TimerId && TimerId < nReconnectTimerEventID + MAX_MC700CHANS )
	{
      // Reconnect timer has gone off, now we allow another 'Reconnect' attempt (hoping that all erroneous attempts are over by now)
		// this is introduced to avoid errors resulting from a peculiar MC behavior:
		// the MC700 repeatedly sends the same 'Reconnect' msg even for channels which have already been connected
		// we must avoid responding to those messages with 'OnConnect', if not an error occurs 
		// we use the 'Reconnect' timer to mask out / skip the erroneous MC700 'Reconnect' messages
		Timer2Chans( TimerId, nReconnectTimerEventID, &nMC );
      bAllowReconnect[nMC] = TRUE;
		uRetVal	= KillTimer( hwnd, TimerId );	//Chans2Timer( nReconnectTimerEventID, nMC ) );


		// 040227..040928  this assertion fails regularly if the user presses 'Analysis' too fast after starting Igor
		// If the user waits appr. 1 s after starting IGOR before pressing 'Analysis' the assertion is OK 		
		// As everything seems to work correctly inspite of the assertion failing the message is removed.
		ASSERT( uRetVal != 0, "Kill1 'Reconnect' timer " );

      // sprintf( sMsg, "\t\t\tReconnect timer \t[ab:%d ch:%d\tbAllowReconnect:%d %d ]\r", ab, ch+1, bAllowReconnect[nMC], TimerId ); XOPNotice( sMsg );
		return TRUE;
	}


	if ( nRequestTimerEventID <= TimerId && TimerId < nRequestTimerEventID + MAX_MC700CHANS )
   {
		// packet request timer has gone off  
		Timer2Chans( TimerId, nRequestTimerEventID, &nMC );
		KillTimer( hwnd, TimerId );	//Chans2Timer( nRequestTimerEventID, nMC ) );
      if( bRequestPending[nMC] )
		{
			// timed out without receiving requested packet
			Index2ChanPort( nMC, &tp, &sn, &po, &ab, &ch );	
			PrintIdx( sMsg1, nMC, " :", tp, po+1, ab, ch+1, sn );
			// Every channel which has been requested but not received is a channel which has been turned off...
			//...it was previously active but is now dead . 
			MarkDeadConnection( hwnd, nMC );

         //sprintf( sMsg, "++Warning: Requested packet not received (%s)! \t[request pending and packet request timer %d has gone off] \r", sMsg1, TimerId );
         sprintf( sMsg, "++Warning: Connection is dead. Requested data packet not received (%s). Time out %d.  \r", sMsg1, TimerId );
		   XOPNotice( sMsg );
		}
		return TRUE;
	}

   // Check for the Copydata timeout. This is an attempt to detect when the user closed a MCC connection 
	if ( nCopydataTimerEventID <= TimerId && TimerId < nCopydataTimerEventID + MAX_MC700CHANS )
   {
		// Copydata timer has gone off  
		Timer2Chans( TimerId, nCopydataTimerEventID, &nMC );
		KillTimer( hwnd, TimerId );	//Chans2Timer( nCopydataTimerEventID, nMC ) );

		Index2ChanPort( nMC, &tp, &sn, &po, &ab, &ch );	
		PrintIdx( sMsg1, nMC, " :", tp, po+1, ab, ch+1, sn );

		if ( nCopydata[ nMC ] > nCOPYDATA_MESSAGES_WHEN_DISCONNECTING ) 
		{
			if ( gnDebugMsg > 1 ) {
				sprintf( sMsg, "\t\t\tCopydata timer %d timed out  and  has  counted     ENOUGH  nCopydata[ nMC:%d ] = %d messages to assume that a connection has just been closed. Verifying with OnRequest()... \r", TimerId, nMC, nCopydata[ nMC ] );
				XOPNotice( sMsg );
			}
			// Double-check if connection 'nMC' is indeed closed by executing 'Onrequest()' . We are not interested in the gains which we receive.
			// Pressing e.g. the VC button often and fast may otherwise erroneously indicate a closed connection (which is actually OK) 
			OnRequest( gTheWindow, nMC );	
			
		} else {
			if ( gnDebugMsg > 2 ) {
	         sprintf( sMsg, "\t\t\tCopydata timer %d timed out without having counted enough  nCopydata[ nMC:%d ] = %d messages to assume that a conection has just been closed. Doing nothing special. ] \r", TimerId, nMC, nCopydata[ nMC ] );
				XOPNotice( sMsg );
			}
		}
		nCopydata[ nMC ] = 0;
		return TRUE;
	}
	return TRUE;
}


int	ProcessCopydataMsg( HWND hwnd, LPARAM ptrCopydataStruct )	//todo return TRUE,FALSE or break????
{
   int		po = 0;
	char		sMsg[2000], sMsg1[200];
	UINT		uRetVal;
	char		sSerialNumber[64];
	int		nSerialNumber;
	int		nMC;	
	BOOL		bIs700B;
	MC_TELEGRAPH_DATA* pmctdReceived;
	COPYDATASTRUCT*	 pcpds			= (COPYDATASTRUCT*) ptrCopydataStruct;

	// Message screening 1 : does this WM_COPYDATA message contain MC_TELEGRAPH_DATA ?
	if (	  pcpds->dwData == (DWORD) nGRequestMessage ) 
	{
		if ( gnDebugMsg > 2 )
		{
			sprintf( sMsg, "\t\tProcessCopydata RequestMessage received. Size of data struct received :%d, expected: %d (700A) or %d (700B) \r", 
									pcpds->cbData , kSTRUCTURE_SIZE_700A, sizeof( MC_TELEGRAPH_DATA )  );
			XOPNotice( sMsg);
		}
	}	else 
	{
		return  TRUE;																			// message is not for us
	}

	// Message screening 2 : does this WM_COPYDATA message contain MC_TELEGRAPH_DATA ?
	if ( pcpds->cbData != kSTRUCTURE_SIZE_700A  &&  pcpds->cbData != sizeof( MC_TELEGRAPH_DATA )	)
	{
		return  TRUE;																			// message is not for us
	} 

	// Get the Pointer into received data. 
	pmctdReceived	= (MC_TELEGRAPH_DATA*) pcpds->lpData;							// We must NOT try to access elements in the 700B-Only section...
	bIs700B			= (pmctdReceived->uHardwareType == MCTG_HW_TYPE_MC700B);	// ..when the smaller 700A structure has been passed.

	// SerialNumber convention:  All 700A get -1 , 700B Demo version has 'Demo Driver' which is atoi-converted to sn = 0 , real 700B keep their true sn.
	nSerialNumber	= ( bIs700B ) ? atoi( pmctdReceived->szSerialNumber ) : k700A_HAS_NO_SERIAL_NUMBER;
	strcpy( sSerialNumber, ( bIs700B ) ? pmctdReceived->szSerialNumber   : " *no sn - 700A*" );	// max 15 characters!

	nMC = ChanPort2Index(	pmctdReceived->uHardwareType, 
									nSerialNumber,							// The serial number 'Demo Driver' is converted to sn = 0 , 700A have sn = -1 
									pmctdReceived->uComPortID - 1, 
									pmctdReceived->uAxoBusID, 
									pmctdReceived->uChannelID - 1 );

	if ( gnDebugMsg > 1 ) {
		PrintIdx( sMsg1, nMC, "<", pmctdReceived->uHardwareType, pmctdReceived->uComPortID, 
											pmctdReceived->uAxoBusID,		pmctdReceived->uChannelID, nSerialNumber );
		sprintf ( sMsg, "\t\tProcessCopydataMsg \t(%s)\tretrieved.\t%s\tsn:'%s' converted to sn:%d \r", 
									sMsg1, Flags( nMC, "  ", "  " ), sSerialNumber, nSerialNumber );
		XOPNotice( sMsg); 
	}

	// Is it on our device / channel ?
	if (  (    (   pmctdReceived->uHardwareType	== MCTG_HW_TYPE_MC700A       )
		     && ( ( pmctdReceived->uComPortID		!= MCState[nMC].uComPortID ) ||
			 		 ( pmctdReceived->uAxoBusID		!= MCState[nMC].uAxoBusID  ) ||
					 ( pmctdReceived->uChannelID		!= MCState[nMC].uChannelID )    ) )
		 ||(      ( pmctdReceived->uHardwareType	== MCTG_HW_TYPE_MC700B     )
		     && ( ( nSerialNumber						!= atoi( MCState[nMC].szSerialNumber ) ) ||	// The serial number 'Demo Driver' is converted to sn = 0
					 ( pmctdReceived->uChannelID		!= MCState[nMC].uChannelID )    ) ) )
	{
		// this message is from another MultiClamp device / channel : ignore it
		sprintf ( sMsg, "++Warning: CopyData - Expecting Chan/AxoBus/Port: \t   --%02d%02d%02d[sn:%s:%d]...but receiving: --%02d%02d%02d[sn:%s:%d] -> Ignoring message...\r", 
							MCState[nMC].uChannelID,		
							MCState[nMC].uAxoBusID, 
							MCState[nMC].uComPortID, 
							MCState[nMC].szSerialNumber,	
							atoi( MCState[nMC].szSerialNumber),
							pmctdReceived->uChannelID, 
							pmctdReceived->uAxoBusID,	
							pmctdReceived->uComPortID, 
							sSerialNumber, 
							nSerialNumber  );
		XOPNotice( sMsg );
		return TRUE;
	}



   // Set a timer event for the Copydata timeout. This is an attempt to detect when the user closed a MCC connection 
	nCopydata[ nMC ] += 1;
   uRetVal = SetTimer( hwnd, Chans2Timer(nCopydataTimerEventID, nMC), nCopydataTimerInterval, (TIMERPROC) NULL );	
   ASSERT( uRetVal != 0, "Set 'Copydata' timer" );
	if ( gnDebugMsg > 1 )
		{ char sMsg2[100]; sprintf( sMsg2, "\t\t\tSet 'Copydata' timer nMC:%2d  set to %d \r", nMC, nCopydata[nMC] ); XOPNotice(sMsg2); }



	// It is our channel...
	MCState[nMC].uHardwareType			= pmctdReceived->uHardwareType;
	MCState[nMC].uOperatingMode		= pmctdReceived->uOperatingMode;
	MCState[nMC].uScaledOutSignal		= pmctdReceived->uScaledOutSignal;
	MCState[nMC].dAlpha					= pmctdReceived->dAlpha;
	MCState[nMC].dScaleFactor			= pmctdReceived->dScaleFactor;
	MCState[nMC].uScaleFactorUnits	= pmctdReceived->uScaleFactorUnits;
	MCState[nMC].dLPFCutoff				= pmctdReceived->dLPFCutoff;
	MCState[nMC].dMembraneCap			= pmctdReceived->dMembraneCap;
	MCState[nMC].dExtCmdSens			= pmctdReceived->dExtCmdSens;
	MCState[nMC].uRawOutSignal			= pmctdReceived->uRawOutSignal;
	MCState[nMC].dRawScaleFactor		= pmctdReceived->dRawScaleFactor;
	MCState[nMC].uRawScaleFactorUnits=pmctdReceived->uRawScaleFactorUnits;
	strcpy( MCState[nMC].szSerialNumber, sSerialNumber);
	
	if( bIsConnecting[nMC] )
	{
		// Our attempt to connect has succeeded before the timeout.
		uRetVal = KillTimer( hwnd, Chans2Timer(nConnectionTimerEventID, nMC) );// We are finished with this timer
      ASSERT( uRetVal != 0, "Kill 'Connect' timer" );

		if ( gnDebugMsg > 1 )
		{
			PrintIdx( sMsg1, nMC, " :", MCState[nMC].uHardwareType, MCState[nMC].uComPortID, MCState[nMC].uAxoBusID, MCState[nMC].uChannelID, atoi(MCState[nMC].szSerialNumber) );
			sprintf( sMsg, "\t\tProcessCopydata  \t\t(%s)\t\t\t\t%s\t->> Connection OK before timeout ->COPYDATA \r",
								  sMsg1, Flags( nMC, "->0", "->1" ) );
			XOPNotice( sMsg);
		}
		bIsConnecting[nMC] = FALSE;
		bIsConnected[nMC]  = TRUE;						// bIsConnected must be set before calling UpdateDisplay()
	}

	if( bRequestPending[nMC] )
	{
		// The requested packet has arrived before the timeout
		bRequestPending[nMC]  = FALSE;
		uRetVal = KillTimer( hwnd, Chans2Timer(nRequestTimerEventID, nMC) );// We are finished with this timer

		// This assertion fails regularly when a MCC700 panel is switched on when FPulse is already running. 
		// As everything seems to work properly  for the time being the assertion is disabled.
		// ASSERT( uRetVal != 0, "Kill 'Request' timer" );

		if ( gnDebugMsg > 1 )
		{
			sprintf( sMsg, "\t\tProcessCopydata\tbRequestPending (nMC:%d) \r", nMC );
			XOPNotice( sMsg);
		}
	}

	bIsConnectionOpen[nMC]	= TRUE;				// will be reset to FALSE when 'server is off' is detected....

	UpdateDisplay( hwnd, nMC );					// We found a MultiClamp so we store its identification 

	return TRUE;
}

			
void		UpdateDisplay( HWND hwnd, UINT nMC )
{
	char			sMsg[2000];
	char			sOneChan[400]	= "";
	extern char	gsAllChan[];				// Store all TG information in 1 global string to be retrieved by Igor.
	int			nMC_Changed		= nMC;

	// Store information about which comports, axobus and channels are used (=open) in a global string 'gsAllChan'..
	//	...which can be retrieved by an XOP function, so that 'xMCTgPickupGains( port,bus,ch) can be called.

	//Flaw : it is ineffective to rebuild the whole string with all Ports/bus/chans even if only 1 channel changed

	gsAllChan[ 0 ] = '\0';

	for ( nMC = 0; nMC < MAX_MC700CHANS ; nMC += 1 )
	{

		if ( bIsConnectionOpen[ nMC ] )
		{
			// ASSUMPTION: Same separators ',;' and same entries 'HWTyp, SerNum, Port, AxoBus, Chan, Mode, Alpha, ScaleFct, Units' as in IGOR 'BreakInfo()' 
			sprintf( sOneChan, "%d,%d,%d,%d,%d,%d,%lf,%lf,%s,;", 
									MCState[nMC].uHardwareType,						// 700B
									atoi( MCState[nMC].szSerialNumber ),			// The serial number 'Demo Driver' is converted to sn = 0
									MCState[nMC].uComPortID - 1,	
									MCState[nMC].uAxoBusID, 
									MCState[nMC].uChannelID - 1,
									MCState[nMC].uOperatingMode, 
									MCState[nMC].dAlpha,
									MCState[nMC].dScaleFactor, 
									MCTG_UNITS[ MCState[nMC].uScaleFactorUnits ] );

			if ( strlen( gsAllChan ) + strlen( sOneChan ) > MAXSTRING_ALLCHAN-10 )
			{
				sprintf( sMsg, "++++Error: Too many MultiClamp channels '%s' [string too long] \r", gsAllChan );
				XOPNotice( sMsg );
			}
			else {
				strcat( gsAllChan, sOneChan );
			}
		} 
	}

	if ( gnDebugMsg > 0 )	// the main message signaling a gain change 
	{ 
		// Break the MultiClamp Info string and print it formatted : 1 line per channel
		char	sIt[ 20 ][ 32 ];		// 20 : MAXITEMS, currently 9 
		int	n, nItems, nMC = 0, nMCCs	= ItemsInList( gsAllChan, ";" );

		char	sHd[100], sChg[10], sLine[400];// sFlags[100];

		for ( nMC = 0; nMC < nMCCs; nMC += 1 )
		{
			strcpy( sHd, (nMC == 0) ? "\t\t\tCOPYDATA\tbuilds PickupInfo:\t" : "\t\t\t\t\t\t\t\t\t\t" );
			strcpy( sChg, (nMC == nMC_Changed) ? " X " : "  " );

//			if ( bIsConnectionOpen[ nMC ] )
			{
				StringFromList( nMC, gsAllChan, ";", sOneChan );
				nItems = ItemsInList( sOneChan, "," );

				for ( n = 0; n < nItems; n += 1 )
					StringFromList( n, sOneChan, "," , sIt[ n ] );	

				sprintf( sLine, "%s\tn:%2d/%d\t%s\t%s\t%7d\t%s\t%s\t%s\t%s\t%7.1lf\t%7.1lf\t%s  \t\t\t%s\t%s\tch: %s  \t%s \r", 
										sHd, nMC, nMCCs, sChg, 
										sIt[0], atoi(sIt[1]), sIt[2], sIt[3], sIt[4], sIt[5], atof(sIt[6]), atof(sIt[7]), 
										strlen( sIt[8] ) == 0 ? "      " : sIt[8] ,		// units 
										Flags( nMC, "  ", "  " ), 
										( atoi(sIt[0]) == 0 ) ? "700A" : "700B" ,  
										sIt[4],														// channel
										MCTG_MODE_NAMES[ atoi(sIt[5]) ] );

				XOPNotice( sLine );
			}
		}
	}
}

	
int	MarkDeadConnection(  HWND hwnd, int nMC )
{
// Set gain to 0 as a marker that this channel is currently not active (the user has turned off a previously active MCC unit or panel)
	if ( bIsConnectionOpen[ nMC ] )
	{
		bIsConnectionOpen[nMC]	= FALSE;			// reset to FALSE  as 'server is off' is detected....
		UpdateDisplay( hwnd, nMC );

		if ( gnDebugMsg > 1 )	
			{ char	sMsg[100]; sprintf ( sMsg, "\t\t\tMarkDeadConnection( nMC: %d ) \r", nMC ); 	XOPNotice( sMsg );  }

	}
	return 0;
}


//------------------------------------------------------------------------------
// MULTICLAMP Index (0..7)  <-->  Channel(AB) , ComPort(A) , SerialNumber(B)

int	ChanPort2Index( int tp, int sn , int po, int ab, int ch )
{
	char		sMsg1[400];
	int		n;
	int		tpFnd, snFnd, abFnd, chFnd, poFnd; 
	for ( n = 0; n < MAX_MC700CHANS; n += 1 )
	{
		Index2ChanPort( n, &tpFnd, &snFnd, &poFnd, &abFnd, &chFnd );
		if (   (tpFnd == MCTG_HW_TYPE_MC700A  &&  tpFnd == tp  && abFnd == ab  &&  chFnd == ch  &&  poFnd==po )
			 || (tpFnd == MCTG_HW_TYPE_MC700B  &&  tpFnd == tp  && snFnd == sn  &&  chFnd == ch					 ) )
		{
			PrintIdx( sMsg1, n, "<", tp, po+1, ab, ch+1, sn );
			return n;					// We found the requested SerialNumber/Comport/Axobus/channel combination so we return its index
		}
	}
	// We have not found the requested SerialNumber/Comport/Axobus/channel combination so we build and insert it at the next first index
	for ( n = 0; n < MAX_MC700CHANS; n += 1 )
	{
		if ( ! bIsConnectionOpen[ n ] )
		{
			MCState[n].uHardwareType	= tp;
			if ( tp == MCTG_HW_TYPE_MC700B)
			{
				sprintf( MCState[n].szSerialNumber, "%016d" , sn );
			}
			if ( tp == MCTG_HW_TYPE_MC700A )
			{
				MCState[n].uComPortID	= po + 1;
				MCState[n].uAxoBusID	= ab;
			}
			MCState[n].uChannelID = ch + 1;
		
			bIsConnectionOpen[ n ]	= TRUE;				// will be reset to FALSE when 'server is off' is detected....
			return		n;
		}
//	PrintIdx( sMsg1, n, "<", tp, po+1, ab, ch+1, sn ); XOPNotice( "ChanPort2Index   " );  XOPNotice( sMsg1 );  XOPNotice( "\r" );
	}
	XOPNotice( "++++Warning: ChanPort2Index() reports connection of too many (8) MC channels...\r" );
	return MAX_MC700CHANS - 1;		// for testing , should only happen when 2 MC units are connected
}


void	Index2ChanPort( int nMC, int* tp, int* sn, int* po, int* ab, int* ch )
{
	char	sMsg1[200];
	*tp	= MCState[nMC].uHardwareType;
	if ( *tp == MCTG_HW_TYPE_MC700B)
	{
		*sn	= atoi( MCState[nMC].szSerialNumber );
	} else {
		*sn = -1 ;		// arbitrary
	}
	if ( *tp == MCTG_HW_TYPE_MC700A )
	{
		*po	= MCState[nMC].uComPortID - 1;
		*ab	= MCState[nMC].uAxoBusID;
	} else {
		*po	= 0;		// arbitrary
		*ab	= -1;		// arbitrary
	}
	*ch	= MCState[nMC].uChannelID - 1;
	PrintIdx( sMsg1, nMC, ">", *tp, *po+1, *ab, *ch+1, *sn );
}


void	PrintIdx( char* sTxt, int nMC, char* sDir, int tp, int po, int ab, int ch, int sn )
{
	sprintf( sTxt, "%s  MC:%d %s t:%d\tpo:%4d\tab:%4d\tch:%4d\tsn:%016d", (tp==0)? "A" : "B", nMC, sDir, tp, po, ab, ch, sn );
}


char *Flags( int nMC, char* sToCg, char* sToCd )
{
	static char	sTxt[256];
 	sprintf( sTxt, "Cg:%d%s\tCd:%d%s\tCo:%d   Ar:%d", bIsConnecting[nMC], sToCg, bIsConnected[nMC], sToCd, bIsConnectionOpen[nMC], bAllowReconnect[nMC] );
	return	sTxt;
}									

//==================================================================================================
// For interchanging telegraph data between the XOP and Igor 

int	xMCTgDebugMsg( struct { DOUBLE p1; DOUBLE result;	}*p )
{
	gnDebugMsg = (int)p->p1;	// turn debug messages in Igors history window on or off
	return(0);
}


int	xMCTgPickupInfo( struct { Handle sRes;	}*p )
// return mode and gain of all channels currently open (without sending a 'request message' to update the value)
// this is faster than a 'request message' but requires an open MC telegraph connection
{
	extern char gsAllChan[];
   Handle		str1 = NIL;
   char			errbuf[4000]; 
   int			len = strlen( gsAllChan );
   int			err = 0;
   if (( str1 = NewHandle( len )) == NIL )   // get output handle , do not provide space for '\0' 
   {
      sprintf( errbuf, "++++Error: xMCTgPickupInfo() Not enough memory. Aborted...\r");
      XOPNotice( errbuf );
      err = NOMEM;				               // out of memory
   }
   else                                      // string length is OK so return string 
		memcpy( *str1, gsAllChan, len );			// copy local temporary buffer WITHOUT \0 to persistent Igor output string 

	// *str1 has no string end : WE  CANNOT  SPRINTF.............
/*
	if ( gnDebugMsg > 1 )
	{
	   char		buf[4000]; 
		sprintf( buf, " xMCTgPickupInfo():  '%s' \r", *str1 );	// *str1 has no string end 
		buf[ len ] = '\0';							// *str1 has no string end so we append it just for the printing
		XOPNotice( buf );  
	}
*/
	p->sRes = str1;
   return 0;
}

#endif