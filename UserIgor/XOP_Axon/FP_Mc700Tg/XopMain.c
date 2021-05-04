//	XopMain.c -- 

#include <XOPStandardHeaders.h>

#include "XopMain.h"

#include "FP_MC700Tg.h"		// sets MCTG_IGORMAINFRM:compile and link all code necessary for the MultiClamp telegraph connection	


#ifdef MCTG_IGORMAINFRM	

	// Global Variables
	extern HWND			gTheWindow;
	extern HHOOK		gRegisteredMsgHook;
	extern HHOOK		gCopydataMsgHook;

	// Prototypes 
	int					MCTgResetFlags( void );
	int					MCTgClientInitializeState( void );
	void					MCTgClientRegisterMessages( void );
	void 					OnBroadcast( HWND hWnd );	
	LRESULT CALLBACK	GetMsgFirstProc( int code, WPARAM wParam, LPARAM lParam );
	LRESULT CALLBACK	CallWndProc( int code, WPARAM wParam, LPARAM lParam );

#endif	// MCTG_IGORMAINFRM	


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
	int   funcIndex;
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
// 04sept using 'Direct method' only
	int funcIndex;

	funcIndex = GetXOPItem(0);	             // which function invoked ?

   if ( funcIndex > IndexOfLastFunction() )// more functions in xxx.RC
      return NIL;                          //  than in sFunc array
	return (long)sFunc[funcIndex].fnc;		 // the function adress is returned
}


#ifdef MCTG_IGORMAINFRM	
static void	XOPQuit(void)
//	Called to clean thing up when XOP is about to be disposed. This happens when Igor is quitting.
{	
	if (gTheWindow != NULL) {
		gTheWindow = NULL;
		UnhookWindowsHookEx( gRegisteredMsgHook );
		UnhookWindowsHookEx( gCopydataMsgHook );
	}
}
#endif


static void  XOPEntry(void)
//	This is the entry point from the host application to the XOP for all
//	  Messages after the INIT Message.
{	
	long result   = 0;
	int  type = GetXOPMessage();
 
   switch( type ) 
   {
		case FUNCTION:					    // our external function being invoked?
			result = DoFunction();
			break;
			
		case FUNCADDRS:
			result = RegisterFunction();
			break;

#ifdef MCTG_IGORMAINFRM	
		case CLEANUP:								// XOP about to be disposed of.
			XOPQuit();								// Do any necessary cleanup.
			break;
#endif

	}
	
	SetXOPResult( result );
}


HOST_IMPORT int 
XOPMain( IORecHandle ioRecHandle )
//	This is the initial entry point at which the host application calls XOP.
//	The MessMage sent by the host must be INIT.
//	main() does any necessary initialization and then sets the XOPEntry field of the
//	  ioRecHandle to the address to be called for future MessMages.
{	
	char	sMsg[300];

#ifdef XOP_GLOBALS_ARE_A4_BASED
		#ifdef __MWERKS__
			// For CodeWarrior 68K XOPs.
			SetCurrentA4();							// Set up correct A4. This allows globals to work.
			SendXOPA4ToIgor(ioRecHandle, GetA4());	// And communicate it to Igor.
		#endif
#endif
	
	// 2021-03-12 what is this? VC2015 complains in combination with Toolkit6, but is not mentionned in manual
//LoadXOPSegs();										// für Funktionen

	XOPInit(ioRecHandle);							// do standard XOP initialization 
	SetXOPEntry(XOPEntry);							// set entry point for future calls 


#ifdef MCTG_IGORMAINFRM	 		
	{
	//	SetXOPType((long)(RESIDENT | IDLES));		// Specify XOP to stick around and to receive IDLE messages.

	MCTgClientRegisterMessages();

	// 2021-04-23 GetParent() a reasonable value in Igor637 but NULL in Igor8 which will finally crash Igor 8.  GetAncestor() seems to work.
	// gTheWindow = GetParent(IgorClientHWND());			// gWindow is a reasonable value in Igor637  but NULL in Igor8 (will crash)
	gTheWindow = GetAncestor(IgorClientHWND(), GA_PARENT);//GA_PARENT, GA_ROOT and GA_ROOTOWNER: handles gTheWindow and IgorClientHWND() are same
	if (gTheWindow == NULL) {
		sprintf(sMsg, "*** FATAL ERROR *** while loading FP_Mc700Tg.xop (Axon MC7700 will not work) \r\tParent window handle is NULL IgorClientHWND:%08p  ->  gTheWindow:>%08p \r", IgorClientHWND(), gTheWindow);	XOPNotice(sMsg);
		return EXIT_FAILURE;
	}
	// Initialisation message may be confusing to the user so it can be removed
	sprintf(sMsg, "Loaded FP_Mc700Tg.xop (210421)\tWITHOUT XOP WINDOW (#ifdef MCTG_IGORMAINFRM) IgorClientHWND:%08p > %08p \r", IgorClientHWND(), gTheWindow);	XOPNotice(sMsg);

	// This hook is for the 'Registered' messages (Open, Close, Request, Broadcast, Reconnect, Id) and for WM_TIMER
	gRegisteredMsgHook = SetWindowsHookEx( WH_GETMESSAGE, &GetMsgFirstProc,NULL,GetCurrentThreadId());
	// This hook is for WM_COPYDATA
	gCopydataMsgHook	 = SetWindowsHookEx( WH_CALLWNDPROC, &CallWndProc,NULL,GetCurrentThreadId());

	MCTgClientInitializeState();	
	MCTgResetFlags();	
	OnBroadcast( gTheWindow );	
	// wait for the answer in 'OnBroadcastResponse and then (possibly) establish a connection..
	// ..so that Igor automatically receives MCTG messages instead of having to request them
	}
#endif
	
	// 2021-03-12
	if (igorVersion < 620) {							// for functions
		SetXOPResult(IGOR_OBSOLETE);
		return EXIT_FAILURE;
	}

	// Initialisation message to remind the programmer about the Release/Debug mode..
	// Better: Remind earlier, remind while releasing and not at program start...
#ifdef _DEBUG
	sprintf(sMsg, "Loaded FP_MC700Tg.xop (210421 debug)\r");
#else
	sprintf(sMsg, "Loaded FP_MC700Tg.xop (210421)\r");
#endif
	XOPNotice(sMsg);

	SetXOPResult(0L);//0L);// test: -1 has no effect
	return EXIT_SUCCESS;
}

//////////////////////////////////////////////////////////////////
