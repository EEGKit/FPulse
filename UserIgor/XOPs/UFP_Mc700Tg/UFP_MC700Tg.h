//
//	  UFP_MC700Tg.h
//

// This flag is now obsolete as the telegraph functions are in a separate (= this UFP_Mc700Tg) XOP .
// It was useful for debugging purposes when the telegraph code needed to be removed temporarily from the big one and only FPulseCed XOP.
// It is still of some use to point out the big differences of this XOP (in XOPMain.c ) in contrast to all others. 

#define	MCTG_IGORMAINFRM 	// compile and link all code necessary for the MultiClamp telegraph connection
//#undef		MCTG_IGORMAINFRM 	// eliminate all code necessary for the MultiClamp telegraph connection

#ifdef MCTG_IGORMAINFRM			
// for interchanging telegraph data between the XOP and Igor 
int UFP_MCTgDebugMsg();
int UFP_MCTgPickupInfo();
#endif

