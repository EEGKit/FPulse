//
// FPAcqCed.ipf
// 
// Routines for 
//	continuos data acquisition and pulsing  using  CED hardware and IGORs background timer 
//	controlling the CED digital output 
//	measuring time durations spent in various program parts
//
// For the acquisition to work there must be IGOR extensions (= CED1401.XOP)  and  a SHORTCUT  to Wavemetrics\Igor Pro Folder\IgorExtensions
// CFS32.DLL  and  USE1432.DLL  must be accessible (copy to Windows\System directory)

// History:
// MAX. DATA RATES: ( 2xAD incl. TG, 2xDA, 1xDigOut), PCI interface
// 1401POWER:  4 us works,   3 us does'nt work at all
// 1401PLUS:     25 us works, 20 us does'nt work reliably (after changing to Eprom V3.22, previously much less)

// 030130	todo check why 16bit Power1401 +-5V range  makes  .9mV steps (should give .153mV steps!)
// 030313 wrapped  'Protocol' loop around the digital output (Digout pulses were output only in protocol 0 and were missing in all following protocols)
// 030320	periods between digout pulses can now be longer than 65535 sample intervals 
// 030707 major revision of digital output 
// 030805 major revision of acquisition 

// 040224	introduced  xCEDWorkingSet( 800, 4000, 0 )
// Dear Ulrich,
// It looks as if the changes to Use1432 are OK, so I am sending you the new library to try out. The new function added is defined as:
//
// U14API(short) U14WorkingSet(DWORD dwMinKb, DWORD dwMaxKb);
//
// it returns zero if all went well, otherwise an error code (currently a positive value unlike other functions). 
// To use it, you should call it once only at the start of your application - I'm not sure how that will apply to you. 
// I suggest using values of 800 and 4000 for the two memory size values, they are known to work fine with CED software.
// Best wishes, Tim Bergel



//? todo the amplitude of the last blank is held appr. 1s until it is forced to zero (by StopADDA_?) . This is a problem only when the amp is not zero. Workaround: define a dummy frame thereafter.  
//? todo  is it necessary that DigOut times are integral multiples of smpint ....if yes then check.... 
  
#pragma rtGlobals=1								// Use modern global access method.



// 060711	


 constant	bCRASH_ON_REDIM_TEST14	= 0		// 051105
// Redimension  error  +  crash :   to provoke the error set  bCRASH_ON_REDIM_TEST14 = TRUE , execute 'Pntest()  and  'test14'
// Observations and workaround: the crash occurs within 10 secs when all of the following conditions are met:
// 	0. Must be PowerCed  with 32 MB .  The error could not be provoked on a 1401Plus with 16MB   (trying different script combinations for 2 hours) 
// 	1. Ced must be on (=normal case which cannot be avoided)  
//	2. wRaw must be redimensioned to different sizes when going from Script to Script  (=normal case which cannot be avoided, except for letting wRaw keep a fixed size )   DONE 2010-03-29
// 	3. Folders with redimensioned waves are killed (e.g.  ...aco:dig   and  ... aco:store) when going from Script to Script 
// 	4. Waves are killed and created and redimensioned  (e.g.  ...aco:dig:wDgoCh etc.   and  ... aco:store:wStoreTimes ) when going from Script to Script 
// 	->  redimensioning  wRaw ( XOP SetTransferArea()  and  killing folders (and possibly waves)  when waves must be redimensioned leads to the crash.... 
// Workaround:  Avoid conditions 3  and 4 :  Do NOT kill the folders,  do  NOT kill  the waves , but rather recreate the waves with overwrite flag /O 
// But.... see  butest12  for sample code how it could be made working WITH killing folders.  (Killing folders is not desirable by itself, but it is allowed, and if something allowed (sometimes) crashes this is a hint that there is a bad, bad bug somewhere...)

static   constant    cDRIVERUNKNOWN 	= -1 ,  cDRIVER1401ISA	= 0 ,  cDRIVER1401PCI = 1 ,  cDRIVER1401USB = 2
static strconstant  sCEDDRIVERTYPES	= "unknown;ISA;PCI;USB;unknown3" 
// 2009-12-11 (see use1401.h for these constants)
//static   constant    c1401UNKNOWN   	= -1 ,  c1401STANDARD	= 0 ,  c1401PLUS = 1 ,   c1401MICRO = 2 ,   c1401POWER = 3 ,  c1401UNUSED = 4			
//static strconstant  sCEDTYPES			= "unknown;Standard 1401;1401 Plus;micro1401;Power1401;unknown/unused"	//  -1 ... 4
static   constant    c1401UNKNOWN   	= -1 ,  c1401STANDARD	= 0 ,  c1401PLUS = 1 ,   c1401MICRO = 2 ,   c1401POWER = 3 ,   c1401MICRO_MK2 = 4 ,   c1401POWER_MK2 = 4,   c1401MICRO_3 = 6,   c1401UNUSED = 7			
static strconstant  sCEDTYPES			= "unknown;Standard 1401;1401 Plus;micro1401;Power1401;micro1401mk2;Power1401mk2;micro1401-3;unknown/unused"	//  -1 ... 4

static constant	nTICKS				= 10			//20 		// wait nTICKS/60 s between calls to background function

// 2010-03-29 d   empirical finding :  CED complains when using a TA size of  1004000   which should be allowed......
// static constant  cMAX_TAREA_PTS   	= 0x080000 	// CED maximum transfer area size is 1MB under Win95.  It must explicitly be enlarged under  Win2000
static constant	cMAX_TAREA_PTS 		= 480000 		// CED maximum transfer area size should be  1MB under Win95.  It must explicitly be enlarged under  Win2000

static constant	cADDAWAIT			= 0
static constant	cADDATRANSFER		= 1
static constant	TESTCEDMEMSIZE		= 0x5000000	// This is the maximum value used for testing the memory partitioning if no Ced is present.  It can be decreased  with the SetVariable  'gnShrinkCedMemMB'
											// Decrease 1401 memory for testing arbitrarily. Normal setting: larger than actual memory (CED has typically 16 or 32 MB)
//static	 constant	MAX_REACTIONTIME	= 1.5			// Adjust chunk size  and repetitions such that the interval between display update is not longer than this seconds (if possible) 
	 constant	MAX_REACTIONTIME	= 1.5			// Adjust chunk size  and repetitions such that the interval between display update is not longer than this seconds (if possible) 
											//...typical value 1 .. 3 . Bigger values improve overall performance as fewer chunks have to be processed.
											// Set this to a very high value to obtain maximum data rates ( this also decreases the 'Apply' time somewhat )

static	constant	cBKG_UNDEFINED		= 0
static	constant	cBKG_IDLING			= 1			// defined but not running
static	constant	cBKG_RUNNING		= 2

static constant	cFAST_TG_COMPRESS	= 255		// set to >=255 for maximum compression , will be clipped and adjusted to the allowed range  1...255 / ( nAD + nTG ) 

//  CEDError.H  AND FPULSE.IPF : Error handling: where and how are error messages displayed
constant		cERR_AUTO_IGOR		= 8			// IGORs automatic error box :lookup CED error string in xxxWinCustom.RC
constant		cERR_FROM_IGOR		= 16			// custom error box: lookup CED error string in xxxWinCustom.RC
constant		cERR_FROM_CED		= 32			// custom error box: get CED error string from U14GetString() 
// combinations of the flags above:
constant		MSGLINE_C			= 38			// 32 + 4 + 2 	// always: print  all 1401 messages and errors using  Ced strings but  displays no error box (for debug)
constant		ERRLINE_C			= 34			// 32 + 2 		// on error: error line using  Ced strings
constant		ERRLINE_I 			= 18			// 16 + 2		// on error: error line using IGOR xxxWinCustom.RC strings
constant		ERRBOX_C			= 33			// 32 + 1		// on error: error box  using  Ced strings
constant		ERRBOX_I 			= 17			// 16 + 1 		// on error: error box  using IGOR xxxWinCustom.RC strings

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//Function		CreateGlobalsInFolder_Acq( sFolder )
//// creates all folder-specific variables. To be used once from CreateGlobals() as the current data folder is changed and not restored
//	string  	sFolder
//	NewDataFolder  /O  /S  $ksROOTUF_ + sFolder							// acquisition: create a new data folder and use as CDF,  clear everything
//	make /O  /N = ( kMAX )  	wG  = 0						// for all general acquisition variables	e.g. SmpInt, CntAD, Prots, Pnts
//	wG[ kPROTS ] = 1
//End


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//   ACQUISITION  FUNCTIONS

Function		StartStimulusAndAcquisition_() 
	string  	sFolder	= ksfACO
	wave 	wG	= $ksROOTUF_ + sFolder + ":keep:wG"  	 					// This  'wG'  	is valid in FPulse ( Acquisition )
	nvar		raTrigMode	= $ksROOTUF_+sFolder+":dlg:raTrigMode"
	nvar		bAppendData	= $ksROOTUF_+sFolder+":dlg:gbAppendData"
	//nvar	gbIncremFile	= root:uf:aco:co:gbIncremFile
	//variable	nPnts		= wG[ kPNTS ] 
	variable	code
	string		bf
	wG[ kSWPS_WRITTEN ]	= 0 

	if ( wG[ kPNTS ]  )
		sprintf bf, "\tSTARTING ACQUISITION (V3) %s %s... \r", SelectString( raTrigMode, " ( after 'Start' , " , " ( waiting for trigger on E3E4, "  ),  SelectString( bAppendData, "writing separate files )", "appending to same file )" )
		Out( bf ) 
		stNewStatusBar( ksSB_WNDNAME, "Status Bar Acquisition" )	//  change message line on bottom depending on prg part			
		//KillAllTimers()

		// This function merely starts the sampling (=background task). This function is finished already at the BEGINNING of the sampling!
		code	= CedStartAcq_() 								// the error code is not yet used 
	else
		Alert( kERR_LESS_IMPORTANT,  "Empty stimulus file..... " ) 
	endif
	if ( ! stCEDHandleIsOpen() )
		Alert( kERR_IMPORTANT, "The CED 1401 is not open. " )			// acquisition will start but only in test mode with fake data
	endif
End	

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function		CEDInitialize_( sFolder) 
// The  CED initialization code must take care of special cases:				( new  031210 )
//	- ApplyScript()	with 1401 not present or switched off : depending on 'kbIS_RELEASE'   exit or go into test mode
//	- ApplyScript()	with 1401 just switched on
//	- ApplyScript()	after the user switched the 1401 off and on again (perhaps to recover from a severe error)
//  More elaborate code checking the interface type but avoiding unnecessary initialisations : 
// ??? Logically the initialization every time even when the 1401 is already 'on' is NOT required, but for unknown reasons  ONLY the  Power1401  and ONLY with USB interface will not work without it ( will  abort with a 'DIGTIM,OB;' error in SetEvents() ) .
	string  	sFolder
	wave 	wG		= $ksROOTUF_ + sFolder + ":keep:wG"  	 					// This  'wG'  	is valid in FPulse ( Acquisition )
	wave  /T	wIO		= $ksROOTUF_ + sFolder + ":ar:wIO" 		 	// This  'wIO'  	is valid in FPulse ( Acquisition )
	nvar		gRadDebgGen		= root:uf:dlg:gRadDebgGen
	nvar		gRadDebgSel		= root:uf:dlg:gRadDebgSel
	nvar		pnDebgCed		= root:uf:dlg:Debg:CedInit
	nvar		gnReps			= root:uf:aco:co:gnReps
	nvar		gPntPerChnk		= root:uf:aco:co:gPntPerChnk
//	nvar		gbRunning		= root:uf:aco:co:gbRunning 
	nvar		gbRunning		= root:uf:aco:keep:gbRunning 
	nvar		gCedMemSize		= root:uf:aco:co:gCedMemSize
	nvar		gnCompressTG		= root:uf:aco:co:gnCompressTg
	nvar		gbSearchStimTiming	= $ksROOTUF_+sFolder+":misc:ImprStimTi0000"
	nvar		gbRequireCed1401	= $ksROOTUF_+sFolder+":misc:RequireCed0000"
	nvar		gShrinkCedMemMB	= $ksROOTUF_+sFolder+":dlg:gShrinkCedMemMB"
	variable	nSmpInt			= wG[ kSI ]
	variable	nCntAD			= wG[ kCNTAD ]	
	variable	nCntDA			= wG[ kCNTDA ]	
	variable	nCntTG			= wG[ kCNTTG ]	
	variable	nPnts			= wG[ kPNTS ] 

	svar		gsDigoutSlices		= $ksROOTUF_ + sFolder + ":dig:gsDigoutSlices"
	variable	nSlices			= ItemsInList( gsDigoutSlices )							

	variable	state, code, nCEDMemPts, nTrfAreaPts //= 1
	string		bf

	variable	ShowMode = ( gRadDebgGen == 2 ||  ( gRadDebgSel > 1 &&  pnDebgCed ) ) ? MSGLINE : ERRLINE	
	variable	bMode	 = ( gRadDebgGen == 2  ||  ( gRadDebgSel > 1 &&  pnDebgCed ) )    ? 	TRUE  :	FALSE
	//ShowMode = MSGLINE_C			// 041202

	variable	hnd		= CedHandle_()// 2010-01-05	old handle which can be valid or invalid
	sprintf bf,  "\t\tCed CEDInitialize()  running: %d    hnd:%d \r", gbRunning, hnd;  Out1( bf, 0 ) 
	
	if ( nPnts  &&  ! gbRunning )
		sprintf bf,  "\t\tCed CEDInitialize()  running: %d    before checking xCedState() \t \tCEDHandleIsOpen() : %d \r", gbRunning, stCEDHandleIsOpen()
		 Out1( bf, 0 ) 
		//  ShowMode = MSGLINE_C	

		if ( hnd >= 0 )
// 2010-01-05
			state	= xCedState( hnd ) 										// Check if CEDHandle is consistent with current Ced state. Set CEDHandle 'off'  if Ced state says 'off'  (happens if 1401 had been on but has just been switched off) 
			sprintf bf,  "\t\tCed CEDInitialize()  running: %d    Ced1401 is %s\t(1+ code:%d)  \tCEDHandleIsOpen() : %d \r", gbRunning, SelectString( state + 1, "closed", "open" ),  state+1 , stCEDHandleIsOpen()
			Out1( bf, 0 ) 
			if ( state )		// should have been 0
				hnd	= xCedClose( hnd )
				stCedHandleSet( CED_NOT_OPEN )
			endif
	
		endif

		// Initialization is only executed once at startup, not with every new script
		if ( ! stCEDHandleIsOpen() ) 

			hnd = xCEDCloseAndOpen(  hnd )						//
			stCedHandleSet( hnd )

			if ( stCEDHandleIsOpen() ) 								
				code		= stCEDInit1401DACADC( hnd, ShowMode )			// The Ced was off and has just been switched on
				if ( code )
					hnd	= xCedClose( hnd )
					stCedHandleSet( CED_NOT_OPEN )
					return	code
				endif
				gCEDMemSize	= stCEDGetMemSize( hnd, 0 )				// with the Ced connected and 'on' the actual memory size is used
				gShrinkCedMemMB	= gCEDMemSize / MBYTE			// Set the SetVariable  with the true Ced memory only once after switching the Ced on. The user may decrease this value later.
			else
				if ( kbIS_RELEASE  &&  gbRequireCed1401 )	// 
					Alert( kERR_FATAL,  "1401  is not responding. The test mode does not require a Ced1401.  Uncheck  'Require Ced..'  in the  'Misc'  panel.  Aborting..." )
					hnd 		= xCEDClose( hnd )
					stCedHandleSet( CED_NOT_OPEN )
					return	kERROR
				endif
				gCEDMemSize	= TESTCEDMEMSIZE				// without Ced the default  TESTCEDMEMSIZE  is used  as upper limit for the SetVariable
			endif
			if ( gShrinkCedMemMB == 0 )							// true only during the VERY FIRST program start (CED may be off or on) : initially set the SetVariable...
				gShrinkCedMemMB	= gCEDMemSize / MBYTE			// ...with the true Ced memory size value or with TESTMEMSIZE. The user may decrease this value later.
			endif												// in all further calls : use as memory size the value which the user has deliberately decreased...
		endif

		// Called  with every  'ApplyScript()'  :  react on a changed trigger mode
		if ( stCEDHandleIsOpen() ) 

			// ??? Logically this initializing is NOT required, but for unknown reasons  ONLY the  Power1401 and ONLY with USB interface will not work without it ( will  abort with a 'DIGTIM,OB;' error in SetEvents() ) .
			variable	nDriverType  = stCEDDriverType( bMode )	
			variable	nCedType	= stCEDType( hnd, bMode )	

			code	  	= stCEDInit1401DACADC( hnd, bMode )			// 2010-02-09  in the E3E4 mode this is required for  EVERY  Ced type.

			code		= stCedSetEvent( sFolder, hnd, bMode )
			if ( code )
				hnd 	= xCEDClose( hnd )
				stCedHandleSet( CED_NOT_OPEN )
				return	code
			endif
		endif
		
		
		// Called  with every  'ApplyScript()'  :  react on a changed memory size which the user may have deliberately decreased...
		if ( gShrinkCedMemMB == 0 )								// 051108  due to some error  'gShrinkCedMemMB'  was 0.  Now we recover from this error without requiring a new start of FPulse
			gShrinkCedMemMB	= gCEDMemSize / MBYTE				// like above
		endif
		
		nCEDMemPts	= gShrinkCedMemMB * MBYTE / 2				// ..thereby improving loading speed  but unfortunately  making the maximum Windows interruption time much smaller...
		
		
		if ( gbSearchStimTiming )			// 030916
			SearchImprovedStimulusTiming( sFolder, wG, nCEDMemPts, nPnts, nSmpInt, nCntDA, nCntAD, nCntTG, nSlices )
		endif

		nTrfAreaPts	= SetPoints( sFolder, wG, nCEDMemPts, nPnts, nSmpInt, nCntDA, nCntAD, nCntTG, nSlices, kERR_IMPORTANT, kERR_FATAL )	// all params are points not bytes	

		if ( nTrfAreaPts <= 0 )
			sprintf bf, "The number of stimulus data points (%d) could not be divided into CED memory without remainder. \r\tAdjust duration(s) in stimulus protocol slightly so that data points contains more small primes." , nPnts
			string		lstPrimes	= FPPrimeFactors( sFolder, nPnts )			// list containing the prime numbers which give 'nPnts'
			Alert( kERR_FATAL,  bf + "   " + lstPrimes[0,50] )
			return kERROR				
		endif
	
		if ( cELIMINATE_BLANK )			// 031120,  here 051108
			StoreChunkSet( sFolder, wG )																			// after SetPoints : needs nPnts and gnPntPerChk
		endif




		// 2010-03-29
		// Old code:  Make a Transfer Area  of the exact the size required by the script.  (The maximum allowed size has been made smaller, though).  NOT GOOD, STILL gives  sporadically 'Can not Set Transfer Area ERROR !
		// KillWaves /Z $ksROOTUF_ + sFolder + ":keep:wRaw" 							// without this Igor will complain (..can not change wave in the middle of assignment...)
		// make  	/O /W /N=(nTrfAreaPts)  		$ksROOTUF_ + sFolder + ":keep:wRaw" 		// allowed area 0, allowed size up to 512KWords=1MB , 16 bit integer

		// New code: MAKE  A  MAXIMAL=FIXED SIZE   TRANSFER AREA  wRAW    AND  OVERWRITE   WITH EVERY NEW SCRIPT (but keeping the same MAXIMAL size).    It follows that  size(TransferArea(computer))  >  size(TransferArea(CED) )
		make  	/O /W /N=(cMAX_TAREA_PTS)  $ksROOTUF_ + sFolder + ":keep:wRaw" 	// allowed area 0, allowed size up to 512KWords=1MB , 16 bit integer


		wave	wRaw				     	= $ksROOTUF_ + sFolder + ":keep:wRaw"	// 041203 must be PERMANENT data folder, will give sporadic heap scramble problems if a regularly cleared folder (e.g.ar) is used	
																		// 050128..050205 ????? why ??? was is this error....?
		// printf "\t\tCEDInitialize 1 '%s'   \texists wRawDDA: %d   points: \t%8d\t  TAPts: \t%8d\tmean:%8.3lf\tCed is open:%2d\t \r", sFolder + ":keep", waveExists( wRaw ),  waveExists( wRaw ) ? numPnts(wRaw) : -1 , nTrfAreaPts , waveExists( wRaw ) ? mean(wRaw) : 0 , CEDHandleIsOpen()// 050128

		if ( stCEDHandleIsOpen() )

			code	= xCEDUnsetTransferArea( hnd, 0, wRaw, ShowMode ) 				// the attempt to unset a non-existing transfer area  (=error -528)  will do no harm as it is caught in the XOP
			// printf "\t\tCEDInitialize 1.'%s'   \t\t\t\t\tUnsetTransferArea returns code:%3d\tAlso killing wRawDDA   \r", sFolder + ":keep", code
	
 			if ( code != 0   &&   code != -528 )										// ignore this error -528  (=area or grab1401 not set up)  which will occur after having been in test mode and then switching the Ced on
				hnd	= xCEDClose( hnd )
				hnd	= CED_NOT_OPEN	
				stCedHandleSet( hnd )
				KillWaves		wRaw
				 printf "Error \tCEDInitialize  '%s'   \t\t\t\t\tUnsetTransferArea returns code:%3d\tAlso killing wRawDDA   \r", sFolder + ":keep", code
				return	code
			endif

			// Go into acquisition  either  without CED for the  test mode  or  with CED only when transfer buffers are ok, otherwise system hangs... 
			// printf "\t\tCEDInitialize 2 '%s'   \texists wRawDDA: %d   points: \t%8d\t  TAreaPts:\t%8d\tmean:%8.3lf\tCed is open:%2d\t \r", sFolder + ":keep", waveExists( wRaw ),  waveExists( wRaw ) ? numPnts(wRaw) : -1 , nTrfAreaPts, waveExists( wRaw ) ? mean(wRaw ): 0 , CEDHandleIsOpen()
			code	=  xCEDSetTransferArea( hnd, 0, nTrfAreaPts, wRaw , ShowMode ) 
			if ( code )
				Alert( kERR_FATAL,  "Could not set transfer area on 1. try.  Code=" +num2str(code) + ".  Try logging  in as Administrator. Aborting..." )
				return	kERROR
			endif
		endif







//  ORIGINAL  CODE  up to 2010-03-28
//		wave  /Z	wRaw	= $ksROOTUF_ + sFolder + ":keep:wRaw"				// 041203 must be PERMANENT data folder, will give sporadic heap scramble problems if a regularly cleared folder (e.g.ar) is used	
//																	// 050128..050205 ????? why ??? was is this error....?
//		// printf "\t\tCEDInitialize 1 '%s'   \texists wRawDDA: %d   points: \t%8d\t  TAPts: \t%8d\tmean:%8.3lf\tCed is open:%2d\t \r", sFolder + ":keep", waveExists( wRaw ),  waveExists( wRaw ) ? numPnts(wRaw) : -1 , nTrfAreaPts , waveExists( wRaw ) ? mean(wRaw) : 0 , CEDHandleIsOpen()// 050128
//
//		if ( waveExists( wRaw ) )
//			variable	nOldPts	= numPnts(wRaw)
//			if ( CEDHandleIsOpen() )
//
//				code	= xCEDUnsetTransferArea( hnd, 0, wRaw, ShowMode ) 		// the attempt to unset a non-existing transfer area  (=error -528)  will do no harm as it is caught in the XOP
//				// printf "\t\tCEDInitialize 1.'%s'   \t\t\t\t\tUnsetTransferArea returns code:%3d\tAlso killing wRawDDA   \r", sFolder + ":keep", code
//
//	 			if ( code != 0   &&   code != -528 )								// ignore this error -528  (=area or grab1401 not set up)  which will occur after having been in test mode and then switching the Ced on
//					hnd	= xCEDClose( hnd )
//					hnd	= CED_NOT_OPEN	
//					CedHandleSet( hnd )
//					KillWaves		wRaw
//					 printf "Error \tCEDInitialize  '%s'   \t\t\t\t\tUnsetTransferArea returns code:%3d\tAlso killing wRawDDA   \r", sFolder + ":keep", code
//					return	code
//				endif
//			endif
//			KillWaves		wRaw
//		endif
//		make  	/W /N=( nTrfAreaPts )  $ksROOTUF_ + sFolder + ":keep:wRaw" 		// allowed area 0, allowed size up to 512KWords=1MB , 16 bit integer
//		wave	wRaw			= $ksROOTUF_ + sFolder + ":keep:wRaw"		// 041203 must be PERMANENT data folder, will give sporadic heap scramble problems if a regularly cleared folder (e.g.ar) is used	
//
//		// Go into acquisition  either  without CED for the  test mode  or  with CED only when transfer buffers are ok, otherwise system hangs... 
//		 printf "\t\tCEDInitialize 2 '%s'   \texists wRawDDA: %d   points: \t%8d\t  OldPts: \t%8d\t>>%2d\tmean:%8.3lf\tCed is open:%2d\t \r", sFolder + ":keep", waveExists( wRaw ),  waveExists( wRaw ) ? numPnts(wRaw) : -1 , nOldPts,  nOldPts<nTrfAreaPts, waveExists( wRaw ) ? mean(wRaw ): 0 , CEDHandleIsOpen()
//		if ( CEDHandleIsOpen() )
//			code	=  xCEDSetTransferArea( hnd, 0, nTrfAreaPts, wRaw , ShowMode ) 
//			if ( code )
//				Alert( kERR_FATAL,  "Could not set transfer area on 1. try.  Code=" +num2str(code) + ".  Try logging  in as Administrator. Aborting..." )
//				return	kERROR
//			endif
//		endif







//		wave  /Z	wRaw	= $ksROOTUF_ + sFolder + ":keep:wRaw"	// 041203 must be PERMANENT data folder, will give sporadic heap scramble problems if a regularly cleared folder (e.g.ar) is used	
//														// 050128..050205 ????? why ??? was is this error....?
//		// printf "\t\tCEDInitialize 1 '%s'   \texists wRawDDA: %d   points: \t%8d\t  TAPts: \t%8d\tmean:%8.3lf\tCed is open:%2d\t \r", sFolder + ":keep", waveExists( wRaw ),  waveExists( wRaw ) ? numPnts(wRaw) : -1 , nTrfAreaPts , waveExists( wRaw ) ? mean(wRaw) : 0 , CEDHandleIsOpen()// 050128
//
//		if ( waveExists( wRaw ) )
//			variable	nOldPts	= numPnts(wRaw)
//			if ( CEDHandleIsOpen() )
//
//				code	= xCEDUnsetTransferArea( hnd, 0, wRaw, ShowMode ) 	// the attempt to unset a non-existing transfer area  (=error -528)  will do no harm as it is caught in the XOP
//				// printf "\t\tCEDInitialize 1.'%s'   \t\t\t\t\tUnsetTransferArea returns code:%3d\tAlso killing wRawDDA   \r", sFolder + ":keep", code
//
//// 2010-03-29 c  no effect,   if 1. try failed then the 2. try will also fail....
////				if (  code == -528 )	
////					 printf "Error \tCEDInitialize  '%s'   \t\t1.Try\tUnsetTransferArea returns code:%3d   \r", sFolder + ":keep", code
////					code	= xCEDUnsetTransferArea( hnd, 0, wRaw, ShowMode ) 	// the attempt to unset a non-existing transfer area  (=error -528)  will do no harm as it is caught in the XOP
////					if (  code == -528 )	
////						 printf "Error \tCEDInitialize  '%s'   \t\t2.Try\tUnsetTransferArea returns code:%3d   \r", sFolder + ":keep", code
////						code	= xCEDUnsetTransferArea( hnd, 0, wRaw, ShowMode ) 	// the attempt to unset a non-existing transfer area  (=error -528)  will do no harm as it is caught in the XOP
////						if (  code == -528 )	
////							 printf "Error \tCEDInitialize  '%s'   \t\t3.Try\tUnsetTransferArea returns code:%3d   \r", sFolder + ":keep", code
////							code	= xCEDUnsetTransferArea( hnd, 0, wRaw, ShowMode ) 	// the attempt to unset a non-existing transfer area  (=error -528)  will do no harm as it is caught in the XOP
////						endif
////					endif
////				endif		
//
//	 			if ( code != 0   &&   code != -528 )							// ignore this error -528  (=area or grab1401 not set up)  which will occur after having been in test mode and then switching the Ced on
//					hnd	= xCEDClose( hnd )
//					hnd	= CED_NOT_OPEN	
//					CedHandleSet( hnd )
//					KillWaves		wRaw
//					 printf "Error \tCEDInitialize  '%s'   \t\t\t\t\tUnsetTransferArea returns code:%3d\tAlso killing wRawDDA   \r", sFolder + ":keep", code
//					return	code
//				endif
//			endif
//			KillWaves		wRaw
//		endif
//		make  	/W /N=( nTrfAreaPts )  $ksROOTUF_ + sFolder + ":keep:wRaw" 		// allowed area 0, allowed size up to 512KWords=1MB , 16 bit integer
//		wave	wRaw			= $ksROOTUF_ + sFolder + ":keep:wRaw"		// 041203 must be PERMANENT data folder, will give sporadic heap scramble problems if a regularly cleared folder (e.g.ar) is used	
//
//// 2010-03-29
////		// Go into acquisition  either  without CED for the  test mode  or  with CED only when transfer buffers are ok, otherwise system hangs... 
////		// printf "\t\tCEDInitialize 2 '%s'   \texists wRawDDA: %d   points: \t%8d\t  TAPts: \t%8d\tmean:%8.3lf\tCed is open:%2d\t \r", sFolder + ":keep", waveExists( wRaw ),  waveExists( wRaw ) ? numPnts(wRaw) : -1 , nTrfAreaPts,  waveExists( wRaw ) ? mean(wRaw ): 0 , CEDHandleIsOpen()
////		if ( ! CEDHandleIsOpen()  ||  xCEDSetTransferArea( hnd, 0, nTrfAreaPts, wRaw , ShowMode ) == 0 ) 
////			// printf "\t\tCEDInitialize 3 '%s'   \texists wRawDDA: %d   points: \t%8d\t  TAPts: \t%8d\tmean:%8.3lf\tCed is open:%2d\t  \r", sFolder+ ":keep", waveExists( wRaw ),  waveExists( wRaw ) ? numPnts(wRaw) : -1 , nTrfAreaPts, waveExists( wRaw ) ? mean(wRaw) :0 , CEDHandleIsOpen()
////			if ( CEDInitializeDacBuffers( sFolder, wRaw, hnd ) ) 					// ignore 'Transfer' and 'Convolve' times here during initialization as they have no effect on acquisition (only on load time)
////				return	kERROR
////			endif
////			// printf "\t\tCEDInitialize 4 '%s'   \texists wRawDDA: %d   points: \t%8d\t  TAPts: \t%8d\tmean:%8.3lf\tCed is open:%2d\t  \r", sFolder+ ":keep", waveExists( wRaw ),  waveExists( wRaw ) ? numPnts(wRaw) : -1 , nTrfAreaPts,  waveExists( wRaw ) ? mean(wRaw) : 0 , CEDHandleIsOpen()
////		else
////			Alert( kERR_FATAL,  "Could not set transfer area. Try logging  in as Administrator. Aborting..." )
////			return	kERROR
////		endif
//
//
//		// Go into acquisition  either  without CED for the  test mode  or  with CED only when transfer buffers are ok, otherwise system hangs... 
//		 printf "\t\tCEDInitialize 2 '%s'   \texists wRawDDA: %d   points: \t%8d\t  OldPts: \t%8d\t>>%2d\tmean:%8.3lf\tCed is open:%2d\t \r", sFolder + ":keep", waveExists( wRaw ),  waveExists( wRaw ) ? numPnts(wRaw) : -1 , nOldPts,  nOldPts<nTrfAreaPts, waveExists( wRaw ) ? mean(wRaw ): 0 , CEDHandleIsOpen()
//		if ( CEDHandleIsOpen() )
//			code	=  xCEDSetTransferArea( hnd, 0, nTrfAreaPts, wRaw , ShowMode ) 
//			if ( code )
//				Alert( kERR_FATAL,  "Could not set transfer area on 1. try.  Code=" +num2str(code) + ".  Try logging  in as Administrator. Aborting..." )
//// 2010-03-29 b  no effect,   if 1. try failed then the 2. try will also fail....
////				code	=  xCEDSetTransferArea( hnd, 0, nTrfAreaPts, wRaw , ShowMode ) 
////				if ( code )
////					Alert( kERR_FATAL,  "Could not set transfer area on 2. try.  Code=" +num2str(code) + ".  Try logging  in as Administrator. Aborting..." )
//					return	kERROR
////				endif
//			endif
//		endif
//







		// printf "\t\tCEDInitialize 3 '%s'   \texists wRawDDA: %d   points: \t%8d\t  TAPts: \t%8d\tmean:%8.3lf\tCed is open:%2d\t  \r", sFolder+ ":keep", waveExists( wRaw ),  waveExists( wRaw ) ? numPnts(wRaw) : -1 , nTrfAreaPts, waveExists( wRaw ) ? mean(wRaw) :0 , CEDHandleIsOpen()
		if ( CEDInitializeDacBuffers( sFolder, wRaw, hnd ) ) 					// ignore 'Transfer' and 'Convolve' times here during initialization as they have no effect on acquisition (only on load time)
			return	kERROR
		endif
		// printf "\t\tCEDInitialize 4 '%s'   \texists wRawDDA: %d   points: \t%8d\t  TAPts: \t%8d\tmean:%8.3lf\tCed is open:%2d\t  \r", sFolder+ ":keep", waveExists( wRaw ),  waveExists( wRaw ) ? numPnts(wRaw) : -1 , nTrfAreaPts,  waveExists( wRaw ) ? mean(wRaw) : 0 , CEDHandleIsOpen()


		SupplyWavesADC( sFolder, wG, wIO, nPnts )							// constructs 'AdcN' and 'AdcTGN' waves  AFTER  PointPerChunk  and  CompressTG  has been computed
		SupplyWavesADCTG( sFolder, wG, wIO, nPnts )

		TelegraphGainPreliminary_( wG, wIO, hnd )		

	else
		Alert( kERR_LESS_IMPORTANT,  "Empty stimulus file  or  stimulus/acquisition is already running. " ) 
	endif

	return  0	
End


Function		CEDInitializeDacBuffers( sFolder, wRaw, hnd ) 
	// Acquisition mode initialization with Timer and swinging buffer 
	// Although the following variables are declared GLOBAL they should be used like STATIC (only  within this procedure file) !
	// Global as they must be accessed in MyBkgTask_()  and  as their access should be fast..(how slow/fast are access functions?) 
	string  	sFolder
	wave	wRaw
	variable	hnd
	wave  	wG		= $ksROOTUF_ + sFolder + ":keep:wG"  	// This  'wG'  	is valid in FPulse ( Acquisition )
	wave  /T	wIO		= $ksROOTUF_ + sFolder + ":ar:wIO"  			// This  'wIO'   	is valid in FPulse ( Acquisition )
	nvar		gnReps			= root:uf:aco:co:gnReps
	nvar		gChnkPerRep		= root:uf:aco:co:gChnkPerRep
	nvar		gPntPerChnk		= root:uf:aco:co:gPntPerChnk
	nvar		gnCompressTG		= root:uf:aco:co:gnCompressTG
	nvar		gMaxSmpPtspChan	= root:uf:aco:co:gMaxSmpPtspChan
	variable	nSmpInt			= wG[ kSI ]
	variable	nCntDA			= wG[ kCNTDA ]	
	variable	nCntAD			= wG[ kCNTAD ]	
	variable	nCntTG			= wG[ kCNTTG ]	
	variable	nPnts			= wG[ kPNTS ] 
	nvar	 	gnOfsDA			= root:uf:aco:co:gnOfsDA
	nvar		gSmpArOfsDA		= root:uf:aco:co:gSmpArOfsDA
	nvar		gnOfsAD			= root:uf:aco:co:gnOfsAD
	nvar		gSmpArOfsAD		= root:uf:aco:co:gSmpArOfsAD	
	nvar		gnOfsDO			= root:uf:aco:co:gnOfsDO
	nvar		gRadDebgSel		= root:uf:dlg:gRadDebgSel
	nvar		pnDebgCed		= root:uf:dlg:Debg:CedInit
	nvar		pnDebgAcqDA		= root:uf:dlg:Debg:AcqDA
	variable	SmpArStartByte,  TfHoArStartByte,  nPts,  	nChunk, code = 0
	string		bf , buf, buf1

	variable	TAused		= stTAuse( gPntPerChnk, nCntDA, nCntAD, cMAX_TAREA_PTS ) 
	variable	MemUsed	= stMemUse(  gChnkPerRep, gPntPerChnk, gMaxSmpPtspChan )
	variable	FoM			= stFigureOfMerit( gChnkPerRep, gPntPerChnk, gMaxSmpPtspChan, nCntDA, nCntAD, nCntTG, gnCompressTG, cMAX_TAREA_PTS ) 
	variable	ChunkTimeSec	= gPntPerChnk * nSmpInt /  1000000
//	nvar		gbRunning	= root:uf:aco:co:gbRunning
	nvar		gbRunning	= root:uf:aco:keep:gbRunning
	nvar		gbAcquiring	= root:uf:aco:co:gbAcquiring	// 031024 
//2010-03-27
//	sprintf bf, "\t\tCed CedStartAcq     CEDInitializeDacBuffers() \tRunning:%2g  Acquiring:%2d \r", gbRunning, gbAcquiring
//	Out1( bf, 0 )
//	sprintf bf, "\t\tCed CedStartAcq     nReps:%d  ChnkpRep:%d  PtpChk:%d  DA:%d  AD:%d  TG:%d  SmpInt:%dus  Cmpr:%d  ReactTm:%.1lfs  TA:%d%%  Mem:%d%%  FoM:%.1lf%% \r", gnReps, gChnkPerRep, gPntPerChnk, nCntDA, nCntAD, nCntTG, nSmpInt,  gnCompressTG, ChunkTimeSec, TAUsed, MemUsed, FoM
//	Out1( bf, 1 )

	// if ( gRadDebgSel > 1  &&   pnDebgCed ) 
		printf "\t\t\tCed CedStartAcq  CEDInitializeDacBuffers\tRps:%d  ChkpRep:%2d  PtpChk:%d  DA:%d  AD:%d  TG:%d  SmpInt:%dus  Cmpr:%d  ReactTm:%.1lfs  TA:%d%%  Mem:%d%%  FoM:%.1lf%%  OsDA:%d  OsAD:%d  OsDO:%d  Running:%2g  Acquiring:%2d\r",gnReps,gChnkPerRep,gPntPerChnk,nCntDA,nCntAD,nCntTG,nSmpInt,gnCompressTG,ChunkTimeSec,TAUsed,MemUsed,FoM,gnOfsDA, gnOfsAD,gnOfsDO,gbRunning,gbAcquiring
	// endif
	
	//sprintf bf, "\t\t\t\tCed Cnv>DA14>Cpy\t  IgorWave \t>HoSB \t=HoSB \t>TASB \t>SASB \t DAPnts\r"; Out( bf )
	for ( nChunk = 0; nChunk < gChnkPerRep; nChunk += 1)		
//MarkPerfTestTime 612	// CEDInitialize: Start Loop chunks
if ( cPROT_AWARE )
		stConvolveBuffersDA( sFolder, wIO, nChunk, 0, gChnkPerRep, nCntDA, gPntPerChnk, wRaw, gnOfsDA/2, 1 )			// ~ 3ms
else
		stConvolveBuffersDA( sFolder, wIO, nChunk, 0, gChnkPerRep, nCntDA, gPntPerChnk, wRaw, gnOfsDA/2, nPnts )		// ~ 3ms
endif
//MarkPerfTestTime 614	// CEDInitialize: ConvolveDA
		if ( stCEDHandleIsOpen() ) 

			nPts   			= gPntPerChnk * nCntDA 
		 	TfHoArStartByte		= gnOfsDA		+ 2 * nPts * mod( nChunk, 2 ) //  only  2 swaps
			SmpArStartByte		= gSmpArOfsDA		+ 2 * nPts * nChunk 
		
			// 031120
if ( cELIMINATE_BLANK )
			variable	begPt	= gPntPerChnk * nChunk					// BegPt and EndPt are points in the CED sampling area (typ. 16MB) ....
			variable	endPt	= gPntPerChnk * ( nChunk + 1 )				// The same BegPt and EndPt are passed multiple times if nReps is >1 (=long scripts and/or many protocols)
			variable	repOs	= 0									// BegPt and EndPt  PLUS the repetition offset 'repOs' gives the true point number in the DAC wave independently from the CED sampling area size
			variable	bStoreIt	= StoreChunkornot( sFolder, nChunk )				
			variable	BlankAmp	= wRaw[ TfHoArStartByte / 2  ]			// use the first value of this chunk as amplitude for the whole chunk
			if ( ( gRadDebgSel ==1  ||  gRadDebgSel == 3 )  &&  pnDebgAcqDA )
				printf "\t\tAcqDA TfHoA1\t%8d\t ->\tSmpAr:\t %11d \t(pts:%8d)  \tBg:\t%7d\tNd:\t%7d\tChunk:\t%7d\tStoring:%2d\tAmp:\t%7d\t   \r", TfHoArStartByte, SmpArStartByte, nPts, BegPt+repOs, EndPt+repOs, nChunk, bStoreIt, BlankAmp
			endif
			if (	bStoreIt )
				 sprintf buf, "TO1401,%d,%d,%d;", TfHoArStartByte, 2*nPts, TfHoArStartByte ;  xCEDSendString( hnd, buf )  // copy  Dac data from host to Ced transferArea. Ced TransferArea and HostArea start at the same point
				 code	+= stGetAndInterpretAcqErrors( hnd, "SmpStart", "TO1401", nChunk, gnReps * gChnkPerRep )
//MarkPerfTestTime 615	// CEDInitialize: GetErrors TO1401
			else
				 sprintf buf, "SS2,C,%d,%d,%d;", TfHoArStartByte, 2*nPts, BlankAmp;  xCEDSendString( hnd, buf )  		// fill Ced transferArea with constant 'Blank' amplitude. This is MUCH faster than the above 'TO1401' which is very slow
				 code	+= stGetAndInterpretAcqErrors( hnd, "SmpStart", "SS2    ", nChunk, gnReps * gChnkPerRep )
//MarkPerfTestTime 616	// CEDInitialize: GetErrors SS2
			endif
			// ..  031120
else
			 sprintf buf, "TO1401,%d,%d,%d;", TfHoArStartByte, 2*nPts, TfHoArStartByte ;  xCEDSendString( hnd, buf ) 		 // copy  Dac data from host to Ced transferArea. Ced TransferArea and HostArea start at the same point
			 code	+= stGetAndInterpretAcqErrors( hnd, "SmpStart", "TO1401", nChunk, gnReps * gChnkPerRep )
//			 MarkPerfTestTime 615	// CEDInitialize: GetErrors TO1401
endif


			 sprintf buf,  "SM2,C,%d,%d,%d;", SmpArStartByte, TfHoArStartByte, 2*nPts;   xCEDSendString( hnd, buf )  		 // copy  Dac data from Ced transfer area to large sample area
//MarkPerfTestTime 617	// CEDInitialize: SendString SM2 Dac
			 code	+= stGetAndInterpretAcqErrors( hnd, "SmpStart", "SM2 Dac", nChunk, gnReps * gChnkPerRep )
//MarkPerfTestTime 618	// CEDInitialize: GetErrors SM2 Dac

// combining is faster and theoretically possible, but the error detection will suffer
// gh			 // TO1401 : TransferArea and HostArea start at the same point.   SM2 : Copy  Dac data from transfer area to large sample area
//			sprintf buf, "TO1401,%d,%d,%d;SM2,C,%d,%d,%d;", TfHoArStartByte, 2*nPts, TfHoArStartByte,    SmpArStartByte, TfHoArStartByte, 2*nPts ;
//			xCEDSendString( bguf )				
//			code	 = GetAndInterpretAcqErrors( "SmpStart", "TO1401 + SM2 Dac", nChunk, gnReps * gChnkPerRep )
		endif
	endfor
	return	code
End


Function		CedStartAcq_() 
	// Acquisition mode initialization with Timer and swinging buffer 
	// Although the following variables are declared GLOBAL they should be used like STATIC (only  within this procedure file) !
	// Global as they must be accessed in MyBkgTask_()  and  as their access should be fast..(how slow/fast are access functions?) 
	string  	sFolder	= ksfACO		
	wave  	wG		= $ksROOTUF_ + sFolder + ":keep:wG"  	// This  'wG'  	is valid in FPulse ( Acquisition )
	variable	hnd		= CedHandle_() 

	nvar		gnReps		= root:uf:aco:co:gnReps
	nvar		gnRep		= root:uf:aco:co:gnRep
	nvar		gChnkPerRep	= root:uf:aco:co:gChnkPerRep
	nvar		gPntPerChnk	= root:uf:aco:co:gPntPerChnk
	nvar		gnChunk		= root:uf:aco:co:gnChunk
	nvar		gnLastDacPos	= root:uf:aco:co:gnLastDacPos
	nvar		gnAddIdx		= root:uf:aco:co:gnAddIdx
	nvar		gReserve		= root:uf:aco:co:gReserve
	nvar		gMinReserve	= root:uf:aco:co:gMinReserve
	nvar		gErrCnt		= root:uf:aco:co:gErrCnt
	nvar		gbAcquiring	= root:uf:aco:co:gbAcquiring	// 031024 
	nvar		gbRunning	= root:uf:aco:keep:gbRunning
	nvar		gnTicksStart	= root:uf:aco:keep:gnTicksStart

	nvar		gBkPeriodTimer	= root:uf:aco:co:gBkPeriodTimer
	nvar		gPrevBlk		= root:uf:aco:disp:gPrevBlk
	nvar		gnOfsDA		= root:uf:aco:co:gnOfsDA,	gSmpArOfsDA	= root:uf:aco:co:gSmpArOfsDA
	nvar		gnOfsAD		= root:uf:aco:co:gnOfsAD,	gSmpArOfsAD	= root:uf:aco:co:gSmpArOfsAD	
	variable	nSmpInt		= wG[ kSI ]
	variable	nCntDA		= wG[ kCNTDA ]	
	variable	nCntAD		= wG[ kCNTAD ]	
	variable	nCntTG		= wG[ kCNTTG ]	
	nvar		gnOfsDO		= root:uf:aco:co:gnOfsDO

	nvar		raTrigMode	= $ksROOTUF_+sFolder+":dlg:raTrigMode"
	nvar		gRadDebgSel	= root:uf:dlg:gRadDebgSel
	nvar		pnDebgAcqDA	= root:uf:dlg:Debg:AcqDA
	string		bf


	if ( stArmDAC( sFolder, gSmpArOfsDA, gPntPerChnk * nCntDA * gChnkPerRep, gnReps, hnd ) == kERROR )
		return	kERROR						// 031016 Avoid  the user ignoring this error and continuing . This error happens very rarely and is not understood...
	endif
	if ( stArmADC( sFolder, gSmpArOfsAD, gPntPerChnk * (nCntAD+nCntTG) * gChnkPerRep, gnReps, hnd ) == kERROR ) 
		return	kERROR						// 031016 Avoid  the user ignoring this error and continuing . This error happens very rarely and is not understood...
	endif

// print "must revive ArmDig"
	if ( stArmDig( sFolder, gnOfsDO, hnd ) == kERROR )
		return	kERROR						// 031016 Avoid  the user ignoring this error and continuing . This error happens very rarely and is not understood...
	endif	

	//ResetTimer( "Convolve" )
	//ResetTimer( "Transfer" )		
	//ResetTimer( "OnlineAn" )		
	//ResetTimer( "CFSWrite" )		
	//ResetTimer( "Process" )		
	//ResetTimer( "TotalADDA" )		

	// Establish a dependency so that the current acquisition status (waiting for 'Start' to be pressed, waiting for trigger on E3E4, acquiring, finished acquisition) is reflected in a ColorTextField
	//SetFormula	root:uf:aco:dlg:gnAcqStatus, "root:uf:aco:co:gbRunning + 2 * root:uf:aco:co:gbAcquiring"		// 031024

//	SetFormula	$ksROOTUF_+sFolder+":dlg:gnAcqStatus", "root:uf:aco:co:gbRunning + 2 * root:uf:aco:co:gbAcquiring"	// 041022
	SetFormula	$ksROOTUF_+sFolder+":dlg:gnAcqStatus", "root:uf:aco:keep:gbRunning + 2 * root:uf:aco:co:gbAcquiring"	// 041022
	
	gbRunning	= TRUE 								// 031030
	StartStopFinishButtonTitles_( sFolder )						// 031030 reflect change of 'gbRunning'  (ugly here...button text should change automatically) 
	//  Never allow to go into 'LoadScriptxx()' when acquisition is running, because 'LoadSc..' initializes the program: especially waves and transfer area
	EnableButton( "PnPuls", "buApplyScript",	kDISABLE )		//  Never allow to go into 'LoadScriptxx()' when acquisition is running..
	EnableButton( "PnPuls", "buLoadScript",	kDISABLE )		//  ..because 'LoadSc..' initializes the program: especially waves and transfer area
	EnableSetVar( "PnPuls", "root_uf_aco_keep_gnProts",kNOEDIT)// ..we cannot change the number of protocols as this would trigger 'ApplyScript()'
	EnableButton( "PnPuls", "buDelete",		kDISABLE )		//  050530 Never allow deletion of the file which is currently written
	//StartStopFinishButtonTitles_( sFolder )					// ugly here...button text should change automatically 050207weg

	// set globals needed in ADDASwing ( background task function takes no parameters )
	gnTicksStart	= ticks			// save current  tick count  (in 1/60s since computer was started) 
	gnRep		= 1    
	gnChunk		= 0    
	gnAddIdx		= 0
	gnLastDacPos	= 0
	gReserve		= Inf
	gMinReserve	= Inf
	gErrCnt		= 0

	//  for initialization of display : initialize with every new block
	gPrevBlk		= -1

	Process_( sFolder, -1) 			//  PULSE  specific: for initialization of CFS writing

	//StartTimer( "TotalADDA" )		

	gBkPeriodTimer 	= 	startMSTimer
	if ( gBkPeriodTimer 	== -1 )
		printf "*****************All timers are in use 5...\r" 
	endif

	// Interrupting longer  than 'MaxBkTime' leads to data loss
	//variable	SetTimerMilliSec = ( gPntPerChnk * nSmpInt ) / 1000 
	//sprintf bf, "\t\tCed CedStartAcq    SmpInt:%d  SetTimerMilliSec:%d   TimerTicks:%d  TimerTicks(period):%d   MaxBkTime:%6dms  Reps:%d \r", nSmpInt, SetTimerMilliSec, SetTimerMilliSec/1000*60, nTICKS, SetTimerMilliSec * ( gChnkPerRep - 1 ),  gnReps 
	//Out1( bf, 1 )

	// PrintBackGroundInfo_( "CedStartAcq 5  V3" , "")

// 2010-02-09c	NEW:  we must KILL bkgtask  (from the other application V4)  before we start this bkgtask
	if ( raTrigMode == 0 )	// in the HW-triggered E3E4 mode the background task is automatically restarted after the script has finished (running quasi-continuously)  [is this really required???]  so we are HERE iwithin the bkg function: we are not allowed to KILL it 
		KillBackground
	endif

	BackGroundInfo	
	if ( v_Flag == cBKG_UNDEFINED )			// 031025   for  the hardware triggered E3E4 mode : We call this function from the BackGround task function ( StopADDA_ ->  'StartStimulusAndAcquisition'  ->  'CedStartAcq'  ... 
		// printf "\t\t\tBackGroundInfo_  '%s'  , v_Flag:%d :  is  %s ,  next scheduled execution:%d  \r ", s_Value, v_Flag, SelectString( v_Flag-1, "not defined", "defined but not running (idle)", "running" ), v_NextRun 
		SetBackground	  MyBkgTask_()			// ...but it is not allowed to change a BackGround task function from within a BackGround task function 
		CtrlBackground	  start ,  period = nTicks, noBurst=1//0 //? nB0=try to catch up, nB1=don't catch up
		// printf "\t\t\tCedStartAcq 5a  V3\t\t\tBkg task: set and start \r "
	elseif ( v_Flag == cBKG_IDLING )			// 031025   for  the hardware triggered E3E4 mode : We call this function from the BackGround task function ( StopADDA_ ->  'StartStimulusAndAcquisition'  ->  'CedStartAcq'  ... 
		CtrlBackground	  start ,  period = nTicks, noBurst=1//0 //? nB0=try to catch up, nB1=don't catch up
		// printf "\t\t\tCedStartAcq 5b  V3\t\t\tBkg task: start \r "
	endif

// 2010-02-09c	weg
//	BackGroundInfo	
//	if ( v_Flag == cBKG_UNDEFINED )			// 031025   for  the hardware triggered E3E4 mode : We call this function from the BackGround task function ( StopADDA_ ->  'StartStimulusAndAcquisition'  ->  'CedStartAcq'  ... 
//		 printf "\t\t\tBackGroundInfo_  '%s'  , v_Flag:%d :  is  %s ,  next scheduled execution:%d  \r ", s_Value, v_Flag, SelectString( v_Flag-1, "not defined", "defined but not running (idle)", "running" ), v_NextRun 
//		SetBackground	  MyBkgTask_()			// ...but it is not allowed to change a BackGround task function from within a BackGround task function 
//		CtrlBackground	  start ,  period = nTicks, noBurst=1//0 //? nB0=try to catch up, nB1=don't catch up
//		 printf "\t\t\tCedStartAcq 5a  V3\t\t\tBkg task: set and start \r "
//	endif
//	
//	if ( v_Flag == cBKG_IDLING )			// 031025   for  the hardware triggered E3E4 mode : We call this function from the BackGround task function ( StopADDA_ ->  'StartStimulusAndAcquisition'  ->  'CedStartAcq'  ... 
//		CtrlBackground	  start ,  period = nTicks, noBurst=1//0 //? nB0=try to catch up, nB1=don't catch up
//		 printf "\t\t\tCedStartAcq 5b  V3\t\t\tBkg task: start \r "
//	endif


 //print "must revive ArmDig"
	if ( stArmClockStart( nSmpInt, raTrigMode, hnd ) )	
		printf "ERROR in ArmClockStart   \r"
		//return	kERROR					// 031016 Avoid  the user ignoring this error and continuing . This error happens very rarely and is not understood...
	endif	

//	if ( gRadDebgSel > 2  &&  pnDebgAcqDA )
//		printf  "\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\tAcqDA Cpy>ADHo>Cnv  \t ADPnts\t  SASB\t\t>TASb \t>HoSB \t   =HoSB \t IgorWave \t\t\t[+ch1,+ch2...] \r"
//	endif

	return 0	// todo: could also but does not return error code
End


Function		PrintBackGroundInfo_( sText1, sText2 )
	string		sText1, sText2
	nvar	gbRunning	= root:uf:aco:keep:gbrunning
	nvar	gbAcquiring	= root:uf:aco:co:gbacquiring 
	BackGroundInfo	
	printf "\t\t\t%s\tBkgInfo_ V3 %s\t\t%s \tPeriod:%3d \tnext scheduled execution:%d  \tv_Flag:%d :  is  %s\tgbRunning:%2d\tgbAcquiring:%2d \r ", pad( sText1, 18),  pad( sText2, 10 ), pd(s_Value,12), v_Period,  v_NextRun , v_Flag, SelectString( v_Flag-1, "not defined", "idling     ", "running " ), gbRunning , gbAcquiring
	//variable /G  root:uf:aco:co:gbacquiring = 0	// 2010-02-08	ass  fixed folder = bad code
End


//==================================================================================================================================================

Function		MyBkgTask_()
// CONT mode routine with swinging buffer.  If   AddaSwing  returns nCode =  kERROR (-1)    then  MyBkgTask_()   will return  1   and   will stop .   Warnings (e.g. Telegraph out of range) will return nCode = 1 and will NOT stop the BkgTask
	 //print "\t050128 Entering BKG task, swinging..."
	variable	nCode = stADDASwing() 
	// print "\t050128 Leaving BKG task (0: keep running=wait , !=0 kill BKG task. Leaving with: ", nCode , "=?=" , kERROR , " ->", nCode == kERROR	
	return	nCode == kERROR			//  return 0 (=cADDAWAIT) if CED was not yet ready to keep the background task running, return !=0 to kill background task
End


Function		fStopBkg_( s )
// Only available in the Misc panel in DEBUG mode
	struct	WMButtonAction &s
	printf "\r\tStopBkg_ \tStopping and killing BackgroundTask V3\r"
	BackgroundInfo
	if ( v_Flag == 2 )						// bkgtask is defined and running
		CtrlBackGround stop
		KillBackGround 
	elseif ( v_Flag == 1 )					// bkgtask is defined but not running
		KillBackGround 
	endif
	variable /G  root:uf:aco:keep:gbrunning = 0	// 			ass  fixed folder = bad code
	variable /G  root:uf:aco:co:gbacquiring = 0	// 2010-02-08	ass  fixed folder = bad code
End


static Function	stClipCompressFactor( nAD, nTG,  PtpChk )
	variable	nAD, nTG, PtpChk 
	string		bf
	variable	nCompression	= 1
	// Start with maximum desired compression  'cCOMPRESST'  (e.g. 100), clip to allowed range 
	nCompression	  =  trunc ( min( cFAST_TG_COMPRESS * ( nAD + nTG ) , 255 ) / ( nAD + nTG ) )// Ced allows a maximum step of 255 for extracting interleaved channels
	// ...then possibly further decrease the allowed value so that it fits into the  'Points per Chunk' without remainder. If this is not done there will be 1 wrong value at the end of each chunk  
	nCompression	+= 1
	do
		nCompression	-= 1
	while (  PtpChk / nCompression != trunc( PtpChk / nCompression )  )
	sprintf bf, "\t\t\t\tCed SetPoints ClipCompressFactor( nAD:%d ,  nTG:%d ,  PtpChk:%d  )  desired TG compression:%d   computed TG compression:%d \r", nAD, nTG,  PtpChk , cFAST_TG_COMPRESS,  nCompression
	Out1( bf, 0 )
	return	nCompression 
End


static Function	stADDASwing() 
	string  	sFolder	= ksfACO
	wave  	wG		= $ksROOTUF_ + sFolder + ":keep:wG"  	// This  'wG'  	is valid in FPulse ( Acquisition )
	wave  /T	wIO		= $ksROOTUF_ + sFolder + ":ar:wIO"  			// This  'wIO'   	is valid in FPulse ( Acquisition )
	wave 	wRaw	= $ksROOTUF_ + sFolder + ":keep:wRaw"// This  'wRaw' 	is valid in FPulse ( Acquisition )

	nvar		gnProts		= $ksROOTUF_ + sFolder + ":keep:gnProts"
	nvar		gnReps		= root:uf:aco:co:gnReps
	nvar		gnRep		= root:uf:aco:co:gnRep
	nvar		gnChunk		= root:uf:aco:co:gnChunk
	nvar		gChnkPerRep	= root:uf:aco:co:gChnkPerRep 
	nvar		gPntPerChnk	= root:uf:aco:co:gPntPerChnk
	nvar		gnOfsDA		= root:uf:aco:co:gnOfsDA,	gSmpArOfsDA	= root:uf:aco:co:gSmpArOfsDA
	nvar		gnOfsAD		= root:uf:aco:co:gnOfsAD,	gSmpArOfsAD	= root:uf:aco:co:gSmpArOfsAD
	variable	nSmpInt		= wG[ kSI ]
	variable	nCntDA		= wG[ kCNTDA ]	
	variable	nCntAD		= wG[ kCNTAD ]	
	variable	nCntTG		= wG[ kCNTTG ]	
	variable	nPnts		= wG[ kPNTS ] 
	nvar		gnOfsDO		= root:uf:aco:co:gnOfsDO
	nvar		gnCompress	= root:uf:aco:co:gnCompressTG
	nvar		bAppendData_	= $ksROOTUF_+sFolder+":dlg:gbAppendData"
	nvar		gBkPeriodTimer	= root:uf:aco:co:gBkPeriodTimer 
	nvar		gRadDebgSel	= root:uf:dlg:gRadDebgSel
	nvar		pnDebgAcqDA	= root:uf:dlg:Debg:AcqDA
	nvar		pnDebgAcqAD	= root:uf:dlg:Debg:AcqAD
	string		buf
	// DAC timing (via PtpChk!) must render ADCBST flag checking unnecessary
	
	variable 	SmpArStartByte, TfHoArStartByte, nPts, nDacReady, code, nTruePt

	variable	hnd		= CedHandle_()

	// printf "\t\t\tADDASwing(1)  \tnChunk:%2d    nDacReady :%2d  \tticks:%d    hnd:%d\r", gnChunk,  nDacReady, ticks, hnd

	if ( ! stCEDHandleIsOpen() )						// MODE  WITHOUT  CED works well for testing
		//StartTimer( "Convolve" )		

		if ( cPROT_AWARE )
			stConvolveBuffersDA( sFolder, wIO, gnChunk, gnRep-1, gChnkPerRep, nCntDA, gPntPerChnk, wRaw, gnOfsDA/2, 1 ) 
		else
			stConvolveBuffersDA( sFolder, wIO, gnChunk, gnRep-1, gChnkPerRep, nCntDA, gPntPerChnk, wRaw, gnOfsDA/2, nPnts ) 
		endif
		//StopTimer(  "Convolve" )		
		//StartTimer( "Transfer" )		
		// although test copying (missing CED) is much slower than TOHOST/TO1401 (6us compared to 1us / WORD) this mode without CED..
		// ..works more reliably and/ or at faster rates. Why? Probably because the timing is more determinate (no waiting for the DAC to be ready) 

		// 2011-11-23a  debug graph
		//string  sWn="ADDASwing_wRaw_TestCopy"; stPossiblyKillGraph( sWn );    Display /K=1 /W=(30,520,430,740)  /N=$sWn  wRaw;   Textbox /W=$sWn "wRaw before TestCopy"; DoUpdate /W=$sWn;  DoAlert 0, "Before TestCopy.  Hit any key to continue"
 		stTestCopyRawDAC_ADC( wG, gnChunk, gPntPerChnk, wRaw, gnOfsDA/2, gnOfsAD/2  )
		// 2011-11-23a  debug graph
		//stPossiblyKillGraph( sWn );    Display /K=1 /W=( 30,520,430,740)  /N=$sWn  wRaw; Textbox  /W=$sWn "wRaw after TestCopy ";  DoUpdate /W=$sWn;    DoAlert 0, "After TestCopy.  Hit any key to continue"	// 2011-11-23a  debug graph

		//StopTimer(  "Transfer" )		
 	else											// MODE  WITH  CED 
		// printf "\t\tADDASwing(A)  gnRep:%d ?<? nReps:%d \r", gnRep, nReps
		nDacReady =  stCheckReadyDacPosition( sFolder, wG, "MEMDAC,P;", gnRep, gnChunk, hnd ) 
		if ( nDacReady == cADDATRANSFER ) 
			 // printf "\t\tADDASwing(B)   gnRep:%d ?<? nReps:%d \r", gnRep, nReps

			if (  		  gnRep < gnReps ) // DAC: don't transfer the last 'ChunkspRep' (appr. 250..500kByte, same as in  ADDAStart) as they are already transfered..
				//StartTimer( "Convolve" )		
				// printf "\t\tADDASwing(C)  gnRep:%d ?<? nReps:%d ConvDA \r", gnRep, nReps
				// print "C", gnRep, "-", gnChunk, gnRep,	ChunkspRep, nCntDA, PtpChk, wRaw, OffsDA/2
				// all Dac buffers have 'rollover' :  when the repetition index has passed the last  then we must use the data from the first (=0)
				if ( cPROT_AWARE )
					stConvolveBuffersDA( sFolder, wIO, gnChunk, gnRep,	gChnkPerRep, nCntDA, gPntPerChnk, wRaw, gnOfsDA/2, 1 )	
				else
					stConvolveBuffersDA( sFolder, wIO, gnChunk, gnRep,	gChnkPerRep, nCntDA, gPntPerChnk, wRaw, gnOfsDA/2, nPnts )	
				endif
				//StopTimer(  "Convolve" )		
				//StartTimer( "Transfer" )		
				nPts				= gPntPerChnk * nCntDA 
	 			TfHoArStartByte		= gnOfsDA	 	+ 2 * nPts * mod( gnChunk, 2 ) //  only  2 swaps
				SmpArStartByte		= gSmpArOfsDA		+ 2 * nPts * gnChunk 

				if ( cELIMINATE_BLANK )	// 031120
					variable	begPt	= gPntPerChnk * gnChunk					// BegPt and EndPt are points in the CED sampling area (typ. 16MB) ....
					variable	endPt	= gPntPerChnk * ( gnChunk + 1 )				// The same BegPt and EndPt are passed multiple times if nReps is >1 (=long scripts and/or many protocols)
					variable	repOs	= gnRep * gPntPerChnk * gChnkPerRep		// BegPt and EndPt  PLUS the repetition offset 'repOs' gives the true point number in the DAC wave independently from the CED sampling area size
					variable	nBigChunk= ( BegPt + RepOs ) / gPntPerChnk 
					variable	bStoreIt	= StoreChunkornot( sFolder, nBigChunk )				
					variable	BlankAmp	= wRaw[ TfHoArStartByte / 2  ]			// use the first value of this chunk as amplitude for the whole chunk
					if ( ( gRadDebgSel == 1  ||  gRadDebgSel == 3 )  &&  pnDebgAcqDA )
						printf "\t\tAcqDA TfHoA2\t%8d\t ->\tSmpAr:\t %11d \t(pts:%8d)  \tBg:\t%7d\tNd:\t%7d\tChunk:\t%7d\tStoring:%2d\tAmp:\t%7d\t  \r", TfHoArStartByte, SmpArStartByte, nPts, BegPt+repOs, EndPt+repOs, nBigChunk, bStoreIt, BlankAmp
					endif
					if (	bStoreIt )
						sprintf buf, "TO1401,%d,%d,%d;", TfHoArStartByte, 2*nPts, TfHoArStartByte ;  xCEDSendString( hnd, buf );  // TransferArea and HostArea start at the same point
						code		= stGetAndInterpretAcqErrors( hnd, "Dac      ", "TO1401 ", gnRep * gChnkPerRep + gnChunk, gnReps * gChnkPerRep )
	 				else
						 sprintf buf, "SS2,C,%d,%d,%d;", TfHoArStartByte, 2*nPts, BlankAmp;  xCEDSendString( hnd, buf )  			// fill Ced transferArea with constant 'Blank' amplitude. This is MUCH faster than the above 'TO1401' which is very slow
						 code	= stGetAndInterpretAcqErrors( hnd, "SmpStart", "SS2    ", gnChunk, gnReps * gChnkPerRep )
					endif
					// ...031120
				else	
					 sprintf buf, "TO1401,%d,%d,%d;", TfHoArStartByte, 2*nPts, TfHoArStartByte ;  xCEDSendString( hnd, buf );  // TransferArea and HostArea start at the same point
					 code		= stGetAndInterpretAcqErrors( hnd, "Dac      ", "TO1401 ", gnRep * gChnkPerRep + gnChunk, gnReps * gChnkPerRep )
				endif


				sprintf buf,  "SM2,C,%d,%d,%d;", SmpArStartByte, TfHoArStartByte, 2*nPts;   xCEDSendString( hnd, buf );     // copy  Dac data from transfer area to large sample area
				code		= stGetAndInterpretAcqErrors( hnd, "Dac      ", "SM2,Dac", gnRep * gChnkPerRep + gnChunk, gnReps * gChnkPerRep )
 				//StopTimer(  "Transfer" )		
			endif

			//StartTimer( "Transfer" )	

			nPts			= gPntPerChnk * ( nCntAD + nCntTG ) 
			TfHoArStartByte		= gnOfsAD	 	+ round( 2 * nPts * mod( gnChunk, 2 ) * ( nCntAD + nCntTG / gnCompress ) / (  nCntAD + nCntTG ) )// only  2 swaps
			SmpArStartByte		= gSmpArOfsAD		+ 2 * nPts * gnChunk
			nTruePt			= ( ( gnRep - 1 ) * gChnkPerRep +  gnChunk ) * nPts 
			// printf "\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\tAcqAD  \t%8d\t%10d\t%8d\t%10d \r", nPts,SmpArStartByte, TfHoArStartByte, nTruePt	// 

			variable	c, nTGSrc, nTGDest, nTGPntsCompressed

			// SEND   1  string to the 1401  for each command : should be slow but should be better as errors are indicated errors more precisely
			// Extract interleaved  true AD channels without compression
			for ( c = 0; c < nCntAD; c += 1 )							// ASSUMPTION: order of channels is first ALL AD, afterwards ALL TG
				nTGSrc			= SmpArStartByte + 2 * c
				nTGDest			= round( TfHoArStartByte + 2 * nPts *  		c 		 / ( nCntAD + nCntTG ) )	// rounding is OK here as there will be no remainder
				nTGPntsCompressed	= round( nPts / ( nCntAD + nCntTG ) )									// rounding is OK here as there will be no remainder
				sprintf buf,  "SN2,X,%d,%d,%d,%d;", nTGDest, nTGSrc, 2 * nTGPntsCompressed, 	(nCntAD + nCntTG);   xCEDSendString( hnd, buf );    // separate interleaved channels within large (~16MB) sample area to 1MB transfer area 
				code		= stGetAndInterpretAcqErrors( hnd, "ExtractAD", "SN2,X,Ad", gnRep * gChnkPerRep + gnChunk, gnReps * gChnkPerRep )
				 // print buf, longBuf
			endfor

			// Extract interleaved Telegraph channel data  and compress them in 1 step
			for ( c = nCntAD; c < nCntAD + nCntTG; c += 1 )			// ASSUMPTION: order of channels is first ALL AD, afterwards ALL TG
				nTGSrc			= SmpArStartByte + 2 * c
				nTGDest			= trunc( TfHoArStartByte + 2 * nPts * ( nCntAD + (c-nCntAD) / gnCompress ) / ( nCntAD + nCntTG ) )
				nTGPntsCompressed	= trunc( nPts / ( nCntAD + nCntTG )   / gnCompress ) 
				sprintf buf,  "SN2,X,%d,%d,%d,%d;", nTGDest, nTGSrc, 2 * nTGPntsCompressed, 	(nCntAD + nCntTG) * gnCompress;   xCEDSendString( hnd, buf );    // separate interleaved channels within large (~16MB) sample area to 1MB transfer area 
				code		= stGetAndInterpretAcqErrors( hnd, "ExtrCmpTG", "SN2,X,TG", gnRep * gChnkPerRep + gnChunk, gnReps * gChnkPerRep )
			endfor

//			// 030806  TEST : SEND ONLY  1  string to the 1401  containing multiple commands : does not speed up the acquisition and does not avoid any errors
//			// Extract interleaved  true AD channels without compression
//			string longbuf = ""
//			for ( c = 0; c < nCntAD; c += 1 )						// ASSUMPTION: order of channels is first ALL  AD, afterwards ALL TG
//				nTGSrc			= SmpArStartByte + 2 * c
//				nTGDest			= round( TfHoArStartByte + 2 * nPts *  		c 		 / ( nCntAD + nCntTG ) )	// rounding is OK here as there will be no remainder
//				nTGPntsCompressed	= round( nPts / ( nCntAD + nCntTG ) )									// rounding is OK here as there will be no remainder
//				sprintf buf,  "SN2,X,%d,%d,%d,%d;", nTGDest, nTGSrc, 2 * nTGPntsCompressed, 	(nCntAD + nCntTG)  	// separate interleaved channels within large (~16MB) sample area to 1MB transfer area 
//				longbuf += buf
//			endfor
//			// Extract interleaved Telegraph channel data  and compress them in 1 step
//			for ( c = nCntAD; c < nCntAD + nCntTG; c += 1 )		// ASSUMPTION: order of channels is first ALL  AD, afterwards ALL TG
//				nTGSrc			= SmpArStartByte + 2 * c
//				nTGDest			= trunc( TfHoArStartByte + 2 * nPts * ( nCntAD + (c-nCntAD) / gnCompress ) / ( nCntAD + nCntTG ) )
//				nTGPntsCompressed	= trunc( nPts / ( nCntAD + nCntTG )   / gnCompress ) 
//				sprintf buf,  "SN2,X,%d,%d,%d,%d;", nTGDest, nTGSrc, 2 * nTGPntsCompressed, 	(nCntAD + nCntTG) * gnCompress	// separate interleaved channels within large (~16MB) sample area to 1MB transfer area 
//				longbuf += buf
//			endfor
//			xCEDSendString( longbuf );    // separate interleaved channels within large (~16MB) sample area to 1MB transfer area 
//			code		= GetAndInterpretAcqErrors( "ExtrCmpTG", "SN2,X,TG", gnRep * gChnkPerRep + gnChunk, gnReps * gChnkPerRep )


			variable nPntsCompressed	= round( nPts * ( nCntAD +  nCntTG / gnCompress ) / ( nCntAD + nCntTG ) ) 
			//variable nPntsTest		= ( ( nPts / gnCompress ) * ( nCntAD * gnCompress  +  nCntTG) ) / ( nCntAD + nCntTG )	// same without rounding (if Igor recognizes paranthesis levels)

			if ( cELIMINATE_BLANK )				// 031120
				begPt	= gPntPerChnk * gnChunk					// BegPt and EndPt are points in the CED sampling area (typ. 16MB) ....
				endPt	= gPntPerChnk * ( gnChunk + 1 )				// The same BegPt and EndPt are passed multiple times if nReps is >1 (=long scripts and/or many protocols)
				repOs	= ( gnRep - 1 ) * gPntPerChnk * gChnkPerRep	// BegPt and EndPt  PLUS the repetition offset 'repOs' gives the true point number in the DAC wave independently from the CED sampling area size
				nBigChunk= ( BegPt + RepOs ) / gPntPerChnk 
				bStoreIt	= StoreChunkornot( sFolder, nBigChunk )				
				if ( ( gRadDebgSel == 1  ||  gRadDebgSel == 3 )  &&  pnDebgAcqAD )
					printf "\t\tAcqAD TfHoA3\t%8d\t ->\tSmpAr:\t %11d \t(pts:%8d)  \tBg:\t%7d\tNd:\t%7d\tChunk:\t%7d\tStoring:%2d\t  \r", TfHoArStartByte, SmpArStartByte, nPts, BegPt+repOs, EndPt+repOs, nBigChunk, bStoreIt
				endif
				if (	bStoreIt )
					sprintf  buf, "TOHOST,%d,%d,%d;", TfHoArStartByte, 2 * nPntsCompressed, TfHoArStartByte ;  xCEDSendString( hnd, buf );  // TransferArea and HostArea start at the same point
					// print "nPts", nPts, "nPntsCompressed ", nPntsCompressed ,  nPntsTest, "bytes", nPntsCompressed *2, "buf", buf
					code		= stGetAndInterpretAcqErrors( hnd, "Sampling", "TOHOST", gnRep * gChnkPerRep + gnChunk, gnReps * gChnkPerRep )
				endif
			else					// ....031120

				sprintf  buf, "TOHOST,%d,%d,%d;", TfHoArStartByte, 2 * nPntsCompressed, TfHoArStartByte ;  xCEDSendString( hnd, buf );  // TransferArea and HostArea start at the same point
				// print "nPts", nPts, "nPntsCompressed ", nPntsCompressed ,  nPntsTest, "bytes", nPntsCompressed *2, "buf", buf
				code		= stGetAndInterpretAcqErrors( hnd, "Sampling", "TOHOST", gnRep * gChnkPerRep + gnChunk, gnReps * gChnkPerRep )

			endif					// ....031120.....

			//StopTimer(  "Transfer" )		

		endif		
	endif	
// print nDacReady
	if (  ! stCEDHandleIsOpen()   ||  nDacReady  == cADDATRANSFER )	// WITH  or  WITHOUT  CED

		//StartTimer( "Convolve" )	
		variable	ptAD
if (  cPROT_AWARE )
		ptAD = stDeconvolveBuffsAD( sFolder, wG, wIO, gnChunk, gnRep, gChnkPerRep, gPntPerChnk, wRaw, gnOfsAD/2, nCntAD , nCntTG, gnCompress, 1  )	//? 221002 gnRep=nReps ->0???
else
		ptAD = stDeconvolveBuffsAD( sFolder, wG, wIO, gnChunk, gnRep, gChnkPerRep, gPntPerChnk, wRaw, gnOfsAD/2, nCntAD , nCntTG, gnCompress, nPnts )	//? 221002 gnRep=nReps ->0???
endif

		//StopTimer(  "Convolve" )		

		// HERE the real work is done : CFS Write, Display , PoverN correction
		//StartTimer( "Process" )								// the current CED pointer is the only information this function gets
		// printf "\tADDASwing()  calls Process( %4d )  \t%2d  gnRep:%2d/%2d \r", ptAD, gnProts,  gnRep, nReps

		Process_( sFolder, ptAD) 								// different approach: call CFSStore() and TDisplaySuperImposedSweeps() from WITHIN this function

		//StopTimer(  "Process" )		

		// printf "\t\t\t\tADDASwing() next chunk   \tgnchunk\t:%3d\t/%3d\t ->%3d\t--> nrep\t:%3d\t/%3d\t\tticks:%d \r", gnChunk, gChnkPerRep, mod( gnChunk + 1, gChnkPerRep ), gnRep, gnReps, ticks
		gnChunk	= mod( gnChunk + 1, gChnkPerRep )				// ..increment Chunk  or reset  Chunk to 0
		if ( gnChunk == 0 )				 					// if  the inner  Chunk loop  has just been iinished.. 
			gnRep += 1									// ..do next  Rep  (or first Rep again if  Rep has been reset above) and..
			 // printf "\t\t\tADDASwing() next rep  \t\t\tgnChunk\t:%3d\t/%3d\t ->%3d\t--> nRep\t:%3d\t/%3d\t\tticks:%d \r", gnChunk, gChnkPerRep, mod( gnChunk + 1, gChnkPerRep ), gnRep, gnReps, ticks
			if ( gnRep > gnReps )
				if ( ! bAppendData_ )							// 031028
			 		FinishFiles_( sFolder )						// ..the job is done : the whole stimulus has been output and the Adc data have all been sampled..
				endif
				StopADDA_( "\tFINISHED  ACQUISITION.." , FALSE, hnd )	// ..then we stop the IGOR-timed periodical background task..  FALSE: do NOT ApplyScript()
			endif											// In the E3E4 trig mode StopADDA calls StartStimulus..() for which reps and chunks must already be set to their final value = StopAdda must be the last action
		endif

	endif

	if ( nDacReady  == kERROR )								// Currently never executed as currently the acquisition continues even in worst case of corrupted data 
	 	FinishFiles_( sFolder )									// ...'CheckReadyDacPosition()'  must be changed if this code is to be executed
		StopADDA_( "\tABORTED  ACQUISITION.." , FALSE, hnd )	//  FALSE: do NOT ApplyScript() 
	endif													// returning   nDacReady = kERROR  will kill the background task

	return nDacReady
End														// of ADDASwing_()


static Function	stPossiblyKillGraph( sWndNm )
// Attempts to delete a Graph from screen. Does nothing if the Graph does not exist. 
	string  	sWndNm
	return	stPossiblyKillWindow( sWndNm, 1 )
End	

static Function	stPossiblyKillWindow( sWndNm, nWndType )
// Attempts to delete any window from screen. Does nothing if the window does not exist.  
	string  	sWndNm
	variable	nWndType
	if ( WinType( sWndNm ) == nWndType )
		KillWindow	$sWndNm
		return 	1
	endif
	return	0
End	


Static Function  stCheckReadyDacPosition( sFolder, wG, command, nRep, nChunk, hnd )
	// Check buffer index to determine whether another chunk must be transferred.
	// Moving or sizing windows interrupts the periodical task of transfering chunks leading to skipped chunks: LAGGING or LOST
	// LAGGING: interrupted time is shorter than the  'ring buffer size'  times  'Sample Int'  -> catching up without data loss is possible
	// LOST: 	     interrupted time is longer  than the  'ring buffer size'  times  'Sample Int'  -> data are lost (overwritten with newer data)
	// The most effective way to discriminate between  LAGGING and LOST would be to check not only the point(DacPos) but also the chunk(DacPos)
	// As the CED does not supply the latter information, the time between background task calls is measured and from this the number of skipped chunks is estimated
	// Design issue:
	// Even when chunks have been lost the ADDA process still continues.
	// This gives at least a record of correct length and correct sample timing but containing corrupted data periods.
	// One could as well abort the ADDA process .... 
	string  	sFolder
	wave	wG
	variable	nRep, nChunk, hnd
	string		command 
	nvar		gnProts			= $ksROOTUF_ + sFolder + ":keep:gnProts"
	nvar		gBkPeriodTimer		= root:uf:aco:co:gBkPeriodTimer
	nvar		gnReps			= root:uf:aco:co:gnReps
	nvar		gChnkPerRep		= root:uf:aco:co:gChnkPerRep 
	nvar		gPntPerChnk		= root:uf:aco:co:gPntPerChnk
	variable	nSmpInt			= wG[ kSI ]
	variable	nCntDA			= wG[ kCNTDA ]	
	variable	nCntAD			= wG[ kCNTAD ]	
	variable	nCntTG			= wG[ kCNTTG ]	
	nvar		gnAddIdx			= root:uf:aco:co:gnAddIdx
	nvar		gnLastDacPos		= root:uf:aco:co:gnLastDacPos
	nvar		gReserve			= root:uf:aco:co:gReserve
	nvar		gMinReserve		= root:uf:aco:co:gMinReserve
	nvar		gPrediction		= root:uf:aco:keep:gPrediction
	nvar		gMaxSmpPtspChan	= root:uf:aco:co:gMaxSmpPtspChan
	nvar		gErrCnt			= root:uf:aco:co:gErrCnt
	nvar		gRadDebgSel		= root:uf:dlg:gRadDebgSel
	nvar		pnDebgAcqDA 		= root:uf:dlg:Debg:AcqDA
	nvar		pnDebgAcqAD 		= root:uf:dlg:Debg:AcqAD
	nvar		gbAcquiring		= root:uf:aco:co:gbAcquiring	// 031024 
	variable	nPts 			=  2 * gPntPerChnk * nCntDA 
	variable	nResult
	string		sResult, ErrBuf

	// measure elapsed time between background task calls
	variable	BkPeriod	=  stopMSTimer( gBkPeriodTimer ) / 1000
	gBkPeriodTimer 	=  startMSTimer									// timer to check time elapsed between Bkg task calls
	if ( gBkPeriodTimer 	== -1 )
		printf "*****************All timers are in use 5 ...\r" 
	endif
	
	// check buffer rollover so that 'IsIdx' is increased monotonically even if 'nDacPos' resets itself periodically
	variable	nDacPos	=  xCEDGetResponse( hnd, command, command, 0 )			// last param is 'ErrMode' : display messages or errors

	// 0308 The following calls requesting the CED AD-pointer and AD-status are not mandatory. They have been introduced only for information..
	// ...in an attempt to avoid the erroneous CED error  'Clock input overrun'  which unfortunately occurs already when the sampling is near (but still below) the limit.
	// When removing these calls be sure that the remaining mandatory CED DA-pointer requests still work correctly. 
	// It seemed (once) that DA- and AD-requests are not under all circumstances completely  as independent as they should be.
	variable	nDAStat	= xCEDGetResponse( hnd, "MEMDAC,?;" , "MEMDACstatus",  0 )	// last param is 'ErrMode' : display messages or errors
	variable	nADStat	= xCEDGetResponse( hnd, "ADCBST,?;", "ADCBSTstatus  ",  0 )	// last param is 'ErrMode' : display messages or errors
	variable	nADPtr	= xCEDGetResponse( hnd, "ADCBST,P;", "ADCBSTpointer ",  0 )	// last param is 'ErrMode' : display messages or errors
	nADPtr /=  ( nCntAD + nCntTG ) 

	// We want the time during which the stimulus is output, not the pre-time possibly waiting for the E3E4 trigger and not the post-time when the stimulus is possibly reloaded (when nReps>1)  
	// PnTest() -> Print options (Debug)  -> Everything ->  Acquisition reveals that  'nDacPos' , 'nADPtr'  and possibly 'nADStat' and 'nDAStat' can be used for that purpose 
	// 'gbRunning' is here not a valid indicator as it not yet set to 0 here after a user abort
	// 'nDacPos'    is here not always a valid indicator as it is not set to 0 after a user  abort
	gbAcquiring	=   nAdPtr == 0   ||  nDacPos == 0   ?   0  :  1				// 031030
	StartStopFinishButtonTitles_( sFolder )									// 031030 reflect change of 'gbAcquiring' in buttons : enable or disable (=grey) them 

	// 031210  The  standard 1401   and the  1401plus / power1401 behave differently so that the code recognizing the normal FINISH  of a script fails :
	// For the 1401plus and power1401 the  'nPredDacPos' -> 'gnAddIdx' -> 'IsIdx'  computation is effective in 2 cases:
	//	1. during all but the last chunks ( Dacpos resets but AddIndex incrementing compensates for that )
	//	2. after the last chunk: DacPos goes to  0   but AddIndex incrementing compensates for that  -> IsIndex increments a last time -> = SollIndex -> XFER is returned -> StopADDA_ is called at the end of AddaSwing() 
	// For the standard 1401  the  'nPredDacPos' -> 'gnAddIdx' -> 'IsIdx'  computation is effective in only in case 1. :  during acquisition but not after the last chunk 
	//	It fails in case 2.  after the last as DacPos  does NOT go to 0  but instead stay fixed at the index of the last point MINUS 2 !  -> IsIndex would  NOT be incremented -> WAIT would be returned -> StopADDA_ is never called
	//	Solution : Check and use the Dac status ( which goes to 0 after finishing ) instead . The Adc status also goes to 0 after finishing but a script does not necessarily contain ADC channels so we do not use it.
	// In principle this patch for the standard 1401 could also be used for the 1401plus and power1401, as their status flags go to 0 in the same manner after finishing...............

	// 'nSkippedChnks' can be fairly good estimated (error < 0.1) .  
	// 031126 We must not count skipped chunks when waiting for a  HW E3E4 trigger, as in this case short scripts (shorter than Background time ~100ms)  would...
	// ...erroneously increment  'nPredDacPos' -> 'gnAddIdx' -> 'IsIdx'  and then trigger the error case below. We avoid this error by setting  'nSkippedChnks=0' when not acquiring  
	variable	nSkippedChnks	= ( BkPeriod / ( gPntPerChnk * nSmpInt * .001 ) ) * gbAcquiring	// 031126
	//variable	nSkippedChnks	= ( BkPeriod / ( gPntPerChnk * nSmpInt * .001 ) ) 
	variable	nPredDacPos	= gnLastDacPos + nSkippedChnks * nPts			// Predicted Dac position can be greater than buffer!

	
	gnLastDacPos		=  nDacPos									// save value for next call
	gnAddIdx		       += gChnkPerRep * trunc( ( nPredDacPos - nDacPos ) / ( nPts  * gChnkPerRep ) + .5 ) 
	variable	IsIdx		=  trunc( nDacPos / nPts ) +  gnAddIdx
	variable	SollIdx	=  nChunk + 1 + gChnkPerRep * ( nRep - 1 )
	variable	TooHighIdx= SollIdx + gChnkPerRep - 1	

	// if ( standard 1401 )    ....would be safer 		// 031210
	if ( nDAStat == 0 )
		IsIdx = SollIdx		// 031210 only for standard 1401 : return XFER after finishing (if it also works for 1401plus and power1401 we do not have to pass/check the type of the 1401...))
	Endif

	// We keep counting 'IsIdx' and 'TooHighIdx' up (proportionally to 'gProt') even in the case of 'nReps' == 1  &&  'nProts' == 1..
	// ...when this is not really necessary, as these 'easy' scripts will always work making the 'Reserve/Prediction' concept useless.
	// We keep counting 'IsIdx' and 'TooHighIdx' because this indicator might prove useful in later stages of program development.
	// ...even if doing so complicates the 'Reserve/Prediction' computation in the 'nReps==1' case. 
	gReserve		= TooHighIdx - IsIdx - 1
	gMinReserve	= min( gMinReserve, gReserve )				// we are interested in the lowest value so we freeze it. Without error the value would increase again at the end.
	if ( IsIdx < SollIdx )									//  OK : wait	( gReserve = maximum )
		nResult	= cADDAWAIT					
		sResult	= "WAIT  "
	elseif ( SollIdx <= IsIdx   &&  IsIdx < TooHighIdx  - 1 ) 			//  OK: Transfer	( gReserve = 1...maximum-1 )
		nResult	= cADDATRANSFER
		sResult	= "XFER "
		
		variable	rNeeded, rCurrent
		gPrediction	= stPredictedAcqSuccess( gnProts, gnReps, gChnkPerRep, gReserve, IsIdx , rNeeded, rCurrent )

	else 				// if ( IsIdx > SollIdx + ChkpRep - 1 )		// kERROR: more than one lap behind, data will be lost  ( gReserve = 0 )  if  at the same time nReps>1  
		nResult	= cADDATRANSFER						// on error : continue
		sResult	= "  ??? "								// more than one lap behind, but no data will be lost as nReps==1   031119

	// the following 2 lines are to be ACTIVATED ONLY  FOR TEST  to break out of the inifinite  Background task loop.....  031111
	//nResult	= kERROR								// on error : stop acquisition
	// printf "\t++++kERROR in Test mode: abort prematurely in StopADDA_ because of 'Loosing data error' , will also  stop  Background task. \r" 

		if ( gnReps > 1  )	// scripts with only 1 repetition will never fail no matter how many protocols are output but the  'IsIdx - TooHighIdx' will erroneously indicate data loss if 'gnProts>>1' 
			sResult	= "LOOS'N"
			if ( gErrCnt == 0 )								// issue this error only once
				variable	TAused	= stTAUse( gPntPerChnk, nCntDA, nCntAD, cMAX_TAREA_PTS )
				variable	MemUsed	= stMemUse( gChnkPerRep, gPntPerChnk, gMaxSmpPtspChan )
				sprintf ErrBuf, "Data  in Chunk: %d / %d will probably be corrupted. Acquisition too fast, too many channels, too many or unfavorable number of data points.\r \t\t\tTA usage:%3d%%  Memory usage:%3d%%  Reps:%d  ChkPerRep:%d  PtsPerChunk:%d ", IsIdx, gnReps * gChnkPerRep, TAused, MemUsed, gnReps, gChnkPerRep, gPntPerChnk
				Alert( kERR_SEVERE, ErrBuf )						// 030716
				gErrCnt	+= 1
			endif
		endif
	endif

	if ( gRadDebgSel == 4  &&  ( pnDebgAcqDA  ||   pnDebgAcqAD ) )
		printf "\ta:%d\tR:%2d/%2d\tChk:%3d/%3d\tAp:%8d\tDp:%8d\tPD:%8d\tTb:%4d", gbAcquiring, nRep, gnReps, (nRep-1) * gChnkPerRep + nChunk, gnReps * gChnkPerRep, nADPtr , nDacPos, nPredDacPos, BkPeriod
		printf "\tsC:%4.1lf  AI:%4d\tIsI:%4.1lf\t[%3d\t|%3d.%3d\t|%3d\t] Rs\t:%3d\t/%3d\t/%3d\t%s\tStt:%4d\t|%5d", nSkippedChnks, gnAddIdx, IsIdx, SollIdx-1, SollIdx, TooHighIdx-1, TooHighIdx, gMinReserve, gReserve, gChnkPerRep, sResult, nDAStat, nADStat
		// printf "\tPr:%5.2lf\t=sc:%5.1lf \t/sn:%5.1lf \r", gPrediction, rCurrent, rNeeded   	// display speeds (not good : range -1000...+1000)
		printf "\tPr:%5.2lf\t= n %.2lf \t/  c %.2lf \r", gPrediction, rNeeded, rCurrent		// display inverse speeds ( good: range  -1...+1)
	endif
	return	nResult
End

Static Function		stPredictedAcqSuccess( nProts, nReps, nChnkPerRep, nReserve, IsIdx, Needed, Current )
// Returns (already during acquisition) a guess whether the acquis will succeed ( > 1 ) or fail  ( < 1 ) .
// This information is useful when the scripts takes very long and when the system is perhaps too slow for the  ambitious sampling rate and number of channels 
	variable	nProts, nReps, nChnkPerRep, nReserve, IsIdx
	variable	&Needed, &Current
	variable	PredCurr
	variable	PosReserveDifference			// if (in rare cases) the reserve increases during the acquis  a neg. reserve diff is computed which gives a false 'Loosing data' indication 
										// we avoid this by clipping to zero so that the correct Prediction = Inf = Success  is displaed
	nvar		/Z 	gStaticPrevReserve			// used like static, should be hidden within this function but must keep it's value between calls
	nvar		/Z 	gStaticPrediction			// used like static, ...
	nvar		/Z 	gStaticIsIdx				// used like static, ...
	if ( ! nvar_Exists( gStaticPrevReserve	) )
		variable   /G	gStaticPrevReserve	= 0	// used like static, should be hidden within this function but must keep it's value between calls
		variable   /G	gStaticIsIdx		= 0	// used like static, ...
		variable   /G	gStaticPrediction	= 1	// used like static, ...
	endif

	if (  nProts * nReps * nChnkPerRep - IsIdx >= 1 )
	  	if ( nReserve != gStaticPrevReserve  ||   nReserve ==  nChnkPerRep - 2 )			// update the value when 1.)  the reserve chunks change (then store the MINIMUM value) 2.) when reserve is at maximum (easy scripts...)
	//	if ( nReserve != gStaticPrevReserve )			// update the value when 1.)  the reserve chunks change (then store the MINIMUM value) 2.) when reserve is at maximum (easy scripts...)
	//	if ( nReserve != gStaticPrevReserve   &&  IsIdx != gStaticIsIdx )			// update the value when 1.)  the reserve chunks change (then store the MINIMUM value) 2.) when reserve is at maximum (easy scripts...)
	//	if ( 							     IsIdx != gStaticIsIdx )			// update the value when 1.)  the reserve chunks change (then store the MINIMUM value) 2.) when reserve is at maximum (easy scripts...)
			// Version1: process   speed
			//Needed	= ( nProts * nReps * nChnkPerRep - IsIdx ) / max( .01, nReserve ) 	// speed : avoid infinite or negative speeds when reserve is 0 or negative
			//Current	= ( IsIdx - gStaticIsIdx ) / max( .01, ( gStaticPrevReserve - nReserve ) ) 	// speed :  avoid infinite or negative speeds when reserve difference is 0 or negative
			//PredCurr	= min( max( -99, Current / Needed ), 99 )
			// Version2: process  1/speed
	//		Needed	= nReserve / ( max( 1, nProts * nReps * nChnkPerRep - IsIdx ) )		// 1 / speed needed for the rest
			Needed	=  nReserve / ( 		 nProts * nReps * nChnkPerRep - IsIdx )		// 1 / speed needed for the rest
			PosReserveDifference = max( 0, gStaticPrevReserve - nReserve ) 			// if (in rare cases) the reserve increases during the acquis  a neg. reserve diff is computed which gives a false 'Loosing data' indication 
																		// we avoid this by clipping to zero so that the correct Prediction = Inf = Success  is displaed
			Current	= PosReserveDifference / ( IsIdx - gStaticIsIdx ) 					// 1 / current speed		= current slow
	//		Current	= 1 / max( 1, ( IsIdx - gStaticIsIdx ) ) 							// 1 / current speed		= current slow
			PredCurr	= Needed / Current   
			gStaticPrediction 	= PredCurr
			gStaticPrevReserve	= nReserve
			gStaticIsIdx	 	= IsIdx
		endif
	endif
	if ( nReps == 1 &&  nProts == 1 )
		gStaticPrediction = 2			// 2 or any other value indicating success. In this special case the 'gReserve' value is meaningless.
	endif
	return	gStaticPrediction
End


Function		FinishFiles_( sFolder )
	string  	sFolder
	FinishCFSFile_( sFolder )
	FinishAnalysisFile_()
End


Function		StopADDA_( strExplain , bDoApplyScript, hnd )
	string		strExplain
	variable	bDoApplyScript 
	variable 	hnd

	string  	sFolder			= ksfACO
	wave  	wRaw			= $ksROOTUF_ + sFolder + ":keep:wRaw"		
	wave  	wG		= $ksROOTUF_ + sFolder + ":keep:wG"  								// This  'wG'	is valid in FPulse ( Acquisition )
	wave  /T	wIO		= $ksROOTUF_ + sFolder + ":ar:wIO"  			// This  'wIO'   	is valid in FPulse ( Acquisition )

	nvar		gBkPeriodTimer		= root:uf:aco:co:gBkPeriodTimer
	nvar		gbRunning		= root:uf:aco:keep:gbRunning
	nvar		gnTicksStop		= root:uf:aco:keep:gnTicksStop

	nvar		raTrigMode		= $ksROOTUF_+sFolder+":dlg:raTrigMode"
	nvar		gbQuickAcqCheck	= $ksROOTUF_+sFolder+":misc:AcqCheck0000"	
	nvar		gRadDebgGen		= root:uf:dlg:gRadDebgGen
	nvar		gRadDebgSel		= root:uf:dlg:gRadDebgSel
	nvar		pnDebgAcqDA		= root:uf:dlg:Debg:AcqDA
	nvar		pnDebgAcqAD		= root:uf:dlg:Debg:AcqAD
	string		bf
	variable	dummy			= stopMSTimer( gBkPeriodTimer )


	// PrintBackGroundInfo_( "StopADDA 1    V3" , "before Stop" )


// 2010-02-09 only test to simplify the code.   E3E4  (stop/ finish)  works by selecting  Trig 'Start'   again
		BackGroundInfo	
		if ( v_Flag == cBKG_RUNNING )			// Only if the bkg task is running we can stop it.  We must rule out the case when it is not yet running for example when switching the trigger mode initially at program start .
			// printf "\t\t\tStopADDA 2  \t\t\tstopping BackGround task \r "
			CtrlBackGround stop				// end of data acquisition
		endif

//		if ( raTrigMode == 0  ) 	// 031113
//			BackGroundInfo	
//			if ( v_Flag == cBKG_RUNNING )			// Only if the bkg task is running we can stop it.  We must rule out the case when it is not yet running for example when switching the trigger mode initially at program start .
//				// printf "\t\t\tStopADDA 2  \t\t\tstopping BackGround task \r "
//				CtrlBackGround stop				// end of data acquisition
//			endif
//		endif


	// PrintBackGroundInfo_( "StopADDA 2    V3" , " after   Stop" )

	
	if (  stCEDHandleIsOpen() )
		variable	ShowMode = ( gRadDebgGen == 2 ||  ( gRadDebgSel > 0 &&  ( pnDebgAcqDA || pnDebgAcqAD ) ) ) ? MSGLINE : ERRLINE	

		// Although it would seem safe we do NOT reset the CED1401 (nor use KillIO) because	1. the Power1401 would not start next acquisition.
		//																2. there would be an undesired  1ms glitch on all digouts appr.500ms after end of stimulus (only on 1401plus) 
		stCEDSendStringCheckErrors( hnd, "ADCBST,K;" , 0 ) 						// 031111 kill the sampling process
		stCEDSendStringCheckErrors( hnd, "MEMDAC,K;" , 0 ) 						// 031111 kill the stimulation process
		stCEDSendStringCheckErrors( hnd, "DAC,0 1 2 3,0 0 0 0;" , 0 ) 				// 031111 set all DACs to 0 when aborting 
		stCEDSendStringCheckErrors( hnd, "DIGTIM,K;" , 0 ) 						// 031111 kill the digital output process
		stCEDSetAllDigOuts( hnd, 0 )											// 031111 Initialize the digital output ports with 0 : set to LOW

		nvar	gnReps	= root:uf:aco:co:gnReps
		// printf "\t\t\tStopADDA 3  \t\t\tgnReps: %2d   \r ", gnReps
		if ( gnReps > 1 )		
			// 031030 Unfortunately we cannot use 'gnAcqStatus'  to reflect the time spent in the following function  'CEDInitializeDacBuffers()'  in a PN_DICOLTXT color text field display,  neither  by setting the controlling..
			// ..global 'gnAcqStatus' directly  nor  indirectly by a dependency relation 'gbAcqStatus :=  f( gbReloading )  as we are right now still in the background task, and controls are only updated when Igor is idling. 
			// Workaround : It is possible  (even when in the middle of a background function)  to change directly  the title of a button, but this is not really what we want.
			// Code (NOT working)  :		nvar gnAcqStatus=root:uf:"+sFolder+":dlg:gnAcqStatus; gnAcqStatus=2   
			// Code (NOT working either) :  	nvar gbReloading=root:uf:aco:co:gbReloading; gbReloading=TRUE ; do something; gbReloading=FALSE;    and coded elsewhere	SetFormula root:uf:"+sFolder+":dlg:gnAcqStatus, "root:uf:aco:co:gbReloading * 2"
			
			// printf "\t\t\tStopADDA 4  \t\t\tgnReps: %2d \t-> CEDInitializeDacBuffers() \r ", gnReps
			CEDInitializeDacBuffers( sFolder, wRaw, hnd ) 		// Ignore (by NOT measuring)  'Transfer' and 'Convolve' times here after finishing as they have no effect on acquisition (only on load time)
		endif
		
	endif
	sprintf bf, "%s  \r", strExplain; Out( bf )
//	sprintf bf, "%s (hnd=%d) \r", strExplain,  xCEDGetHandle() ; Out( bf )

	if ( gbQuickAcqCheck )								//  for quick testing the integrity of acquired data including telegraph channels
		stQuickAcqCheck_( sFolder, wG, wIO, wRaw )
	endif

	gbRunning	= FALSE 								// 031030
	StartStopFinishButtonTitles_( sFolder )						// 031030 reflect change of 'gbRunning' 

	gnTicksStop	= ticks 								// save current  tick count  (in 1/60s since computer was started) 
	EnableButton( "PnPuls", "buApplyScript",	kENABLE )
	EnableSetVar( "PnPuls", "root_uf_aco_keep_gnProts",TRUE )	// ..allow also changing the number of protocols ( which triggers 'ApplyScript()'  )
	EnableButton( "PnPuls", "buLoadScript",	kENABLE )
	EnableButton( "PnPuls", "buDelete",		kENABLE )		//  050530 Allow deletion of the current file only after acquisition has stopped


	// 060206 ShowTimingStatistics_( sFolder, wG, wFix )			// 2012-02-09

	if ( bDoApplyScript )
		ApplyScript_( kbKEEP_ACQ_DISP )
	endif

	if ( raTrigMode == 1 ) 	//  031025 continuous hardware trig'd mode: (re)arm the trigger detection after a stimulus is finished so that each new trigger on E3E4 triggers the next acquisition run
		// printf "\t\t\tStopADDA 6  \t\t\t-> StartStimulusAndAcquisition() \r "					// 031119
		StartStimulusAndAcquisition_() 	//  this will call  'CedStartAcq'  which will  set  'gbRunning'  TRUE
	endif
End


Function		StartStopFinishButtonTitles_( sFolder )
// Enables and disables 'Start/Stop/Finish/Trigger mode/Apppend data' related buttons depending on the control's settings  AND  on program state ('gbRunning, gbAcquiring')
// For this to work this function must EXPLICITLY be called every time one of the input parameters changes. 
// This easily done (without any negative impact) for the controls by putting a call to this function into the action procedure.
// For reflecting the state of  non-control globals like 'gbRunning, gbAcquiring' a call to this function must be placed in the background procedure where  'gbRunning, gbAcquiring'  change .
// This might possibly have a negative impact on program behaviour but actually it seems to work fine....   
// TODO  031030   measure time needed for the execution of this function and then decide.....
// Possible workaround : Ignore changes of  'gbRunning, gbAcquiring'  in the button title ,  instead place a  PN_DICOLTXT  with color field and text in the vicinity of the button.
// A PN_DICOLTXT field is updated automatically through a dependency and does not need an explicit call when an input parameter changes.

// 031031 flaw: In mode  HW trigger,  not appending, not acquiring the button 'Finish'  should be on  initially  but  should  be disabled after being pressed once and be enabled by the next 'Start'='gbAcquiring'
	string  	sFolder

	nvar		raTrigMode	= $ksROOTUF_+sFolder+":dlg:raTrigMode"
	nvar		bAppendData	= $ksROOTUF_+sFolder+":dlg:gbAppendData"
//	nvar		gbRunning 	= root:uf:aco:co:gbRunning
	nvar		gbRunning 	= root:uf:aco:keep:gbRunning
	nvar		gbAcquiring 	= root:uf:aco:co:gbAcquiring
	string		sBuStartNm	= "buStart"
	string		sBuStopNm	= "buStopFinish"
	string		sStartStop		= "S t a r t"
	if ( raTrigMode == 0  &&   !  bAppendData  &&  ! gbRunning )		// normal  SW triggered mode, 
		Button	$sBuStopNm 	win = PnPuls,	title = "Stop",	disable = kDISABLE
		EnableButton( "PnPuls", sBuStartNm,		kENABLE )						//	 
	endif
	if ( raTrigMode == 0  &&   ! bAppendData	  &&    gbRunning )	// normal  SW triggered  mode, 
		Button	$sBuStopNm	win=PnPuls,	 title = "Stop",	disable = kENABLE	
		EnableButton( "PnPuls", sBuStartNm,		kDISABLE )						// 
	endif
	if ( raTrigMode == 0  &&    bAppendData	  &&  ! gbRunning )	// normal  SW triggered  mode, 
		Button	$sBuStopNm	win=PnPuls,	 title = "Finish",	disable = kENABLE
		EnableButton( "PnPuls", sBuStartNm,		kENABLE )						// 
	endif
	if ( raTrigMode == 0  &&    bAppendData	  &&    gbRunning )	// normal  SW triggered  mode, 
		Button	$sBuStopNm	win=PnPuls,	 title = "Stop",	disable = kENABLE
		EnableButton( "PnPuls", sBuStartNm,		kDISABLE )						// 
	endif

	if ( raTrigMode == 1	&&  ! bAppendData	&&   ! gbAcquiring )				// HW E3E4 triggered mode, 
		Button	$sBuStopNm	win=PnPuls,	 title = "Finish"
		EnableButton( "PnPuls", sBuStartNm,		kDISABLE )						// 
	endif
	if ( raTrigMode == 1	&&  ! bAppendData	&&     gbAcquiring )				// HW E3E4 triggered mode, 
		Button	$sBuStopNm	win=PnPuls,	 title = "Stop",	disable = kENABLE
		EnableButton( "PnPuls", sBuStartNm,		kDISABLE )						// 
	endif
	if ( raTrigMode == 1	&&    bAppendData	&&   ! gbAcquiring )				// HW E3E4 triggered mode, 
		Button	$sBuStopNm	win=PnPuls,	 title = "Finish",	disable = kENABLE
		EnableButton( "PnPuls", sBuStartNm,		kDISABLE )						// 
	endif
	if ( raTrigMode == 1	&&   bAppendData	&&     gbAcquiring )				// HW E3E4 triggered mode, 
		Button	$sBuStopNm	win=PnPuls,	 title = "Stop",	disable = kENABLE
		EnableButton( "PnPuls", sBuStartNm,		kDISABLE )						// 
	endif

End


static Function		stQuickAcqCheck_( sFolder, wG, wIO, wRaw )
	// Extra window for detection of acquisition errors including telegraph channels.  'Display raw data after Acq' also works but does not display the telegraph channels. 
	// You must kill the window before each acquisition because to avoid graph updating which slows down the acquisition process appreciably.  
	string  	sFolder
	wave	wG
	wave  /T	wIO
	wave	wRaw
	nvar		gnCompress		= root:uf:aco:co:gnCompressTG	
	variable	nSmpInt			= wG[ kSI ]
	variable	nCntAD			= wG[ kCNTAD ]	
	variable	nCntTG			= wG[ kCNTTG ]	
	variable	c, red, green, blue
	string		sWaveNm, sFolderWaveNm
	string		sQuickAcqCheckNm	= "QuickCheck"		// cannot name it 'QuickAcqCheck' as this is the function name 

	DoWindow	$sQuickAcqCheckNm				// check if the 'QuickAcqCheck' window exists
	if ( V_Flag == 1 )									// ..if it exists then V_Flag will be true
		DoWindow  /K	$sQuickAcqCheckNm			// ..kill it
	endif 
	display /K=1 									// allow killing by pressing the window close button
	DoWindow  /C $sQuickAcqCheckNm					// rename window to  'QuickAcqCheck'

	// this display order may not be optimal  in test mode without CED.  Adc2 is filled with much noise, Adc0 with little noise and  may be obscured by Adc2
	for ( c = 0; c < nCntAD; c += 1)	
		sWaveNm		 = ADTGNm( wG, wIO, c )
		sFolderWaveNm = FldAcqioADTGNm( sFolder, wG, wIO, c  )
		red		= 64000 * ( c== 0 ) + 64000  * ( c== 3 ) + 64000  * ( c== 4 )
		green	= 64000 * ( c== 1 ) + 64000  * ( c== 4 ) + 64000  * ( c== 5 )
		blue		= 64000 * ( c== 2 ) + 64000  * ( c== 5 ) + 64000  * ( c== 3 ) 
		AppendToGraph $sFolderWaveNm
		ModifyGraph rgb( $sWaveNm )	= ( red, green, blue )
		SetScale /I x , 0, numPnts( $sFolderWaveNm ) * nSmpInt / 1e6 , "s", $sFolderWaveNm
	endfor
	for ( c = nCntAD; c < nCntAD + nCntTG; c += 1)	
		sWaveNm		 = ADTGNm( wG, wIO, c )
		sFolderWaveNm = FldAcqioADTGNm( sFolder, wG, wIO, c )
		red		= 64000 * ( c== 0 ) + 64000  * ( c== 3 ) + 64000  * ( c== 4 )
		green	= 64000 * ( c== 1 ) + 64000  * ( c== 4 ) + 64000  * ( c== 5 )
		blue		= 64000 * ( c== 2 ) + 64000  * ( c== 5 ) + 64000  * ( c== 3 ) 
		AppendToGraph $sFolderWaveNm
		ModifyGraph rgb( $sWaveNm )	= ( red, green, blue )
		SetScale /I x , 0, numPnts( $sFolderWaveNm ) * gnCompress * nSmpInt / 1e6 , "s" , $sFolderWaveNm
	endfor
	// printf "\t\tQuickAcqCheck(): displays window for acquis error detection including telegraph channels. Kill this window before every acquis for maximum speed.\r" 
End

// 2012-02-09
//Function		ShowTimingStatistics_( sFolder, wG, wFix )
//	string  	sFolder
//	wave	wG, wFix
//	nvar		gnProts			= $ksROOTUF_ + sFolder + ":keep:gnProts"
//	nvar		gnReps			= root:uf:aco:co:gnReps
//	nvar	 	gChnkPerRep		= root:uf:aco:co:gChnkPerRep
//	nvar		gPntPerChnk	 	= root:uf:aco:co:gPntPerChnk
//	variable	nSmpInt			= wG[ kSI ]
//	variable	nCntDA			= wG[ kCNTDA ]	
//	variable	nCntAD			= wG[ kCNTAD ]	
//	variable	nCntTG			= wG[ kCNTTG ]	
//	nvar		gnCompress		= root:uf:aco:co:gnCompressTG
//	nvar		gReserve			= root:uf:aco:co:gReserve
//	nvar		gMinReserve		= root:uf:aco:co:gMinReserve
//	nvar		gMaxSmpPtspChan	= root:uf:aco:co:gMaxSmpPtspChan
//	nvar		gbShowTimingStats	= $ksROOTUF_+sFolder+":misc:TimeStats0000"
//	variable	nTransConvPtsPerCh	= gChnkPerRep * gPntPerChnk * gnReps
//	variable	nTransConvChs		= nCntAD+ nCntDA + nCntTG / gnCompress
//	variable	nTransferPts		= nTransConvPtsPerCh * nTransConvChs
//	variable	nConvolvePts		= nTransConvPtsPerCh * nTransConvChs
//	variable	nCFSWritePtsPerCh 	= TotalStorePoints( sFolder, wG, wFix ) * gnProts	// this number of points is valid for Writing AND Processing
//	variable	nGraphicsPtsPerCh 	= TotalStorePoints( sFolder, wG, wFix ) * gnProts	// todo not correct: superimposed sweeps not included
//	variable	nCFSWritePts		= nCFSWritePtsPerCh *  nCntAD 
//	variable	nGraphicsPts		= nGraphicsPtsPerCh *  nCntAD // todo not correct: DAC may also be displayed, superimposed sweeps not included 
//	variable	TransferTime		= 0 //ReadTimer( "Transfer" )
//	variable	ConvolveTime		= 0 //ReadTimer( "Convolve" )
//	variable	GraphicsTime		= 0 //ReadTimer( "Graphics" )
//	variable	CFSWriteTime		= 0 //ReadTimer( "CFSWrite" )
//	variable	OnlineAnTime		= 0 //ReadTimer( "OnlineAn" )
//	variable	ProcessTime		= 0 //ReadTimer( "Process" )
//	variable	InRoutinesTime		= TransferTime + ConvolveTime + CFSWriteTime + GraphicsTime + ProcessTime 	
//	variable	ProtocolTotalTime	= nTransConvPtsPerCh * nSmpInt / 1000
//	variable	ProtocolStoredTime	= nCFSWritePtsPerCh * nSmpInt / 1000
//	variable	AttemptedADRate	= 1000 * nCntAD / nSmpInt
//	variable	AttemptedFileSize	= AttemptedADRate * ProtocolStoredTime * 2 / 1024 / 1024
//	variable	TAused			= TAUse( gPntPerChnk, nCntDA, nCntAD, cMAX_TAREA_PTS )
//	variable	MemUsed			= MemUse( gChnkPerRep, gPntPerChnk, gMaxSmpPtspChan )
//
//	//StopTimer(  "TotalADDA" )		
//	//PrintAllTimers( 0 )
//	if ( gbShowTimingStats )
//		printf "\t\tTIMING STATISTICS ( Prots:%2d , Rep:%2d ,  CpR:%2d , PtpChk:%6d / %d ,  %d us,  %.1lf MB,  Reserve:%d / %d / %d, TA:%d%%, Mem:%d%% ) \r", gnProts, gnReps, gChnkPerRep, gPntPerChnk, gPntPerChnk * ( nCntAD + nCntTG ), nSmpInt, AttemptedFileSize, gMinReserve, gReserve, gChnkPerRep, TAUsed, MemUsed
//		printf  "\t\tTransfer:  \t%3.2lf\tch *\t %11d \t=%11d\tpts\t %11d \tms  -> %5.2lf\t/ %5.2lf\tus / pt \t= %5.1lf\t%% of SI \r", nTransConvChs,   nTransConvPtsPerCh,   nTransferPts,   TransferTime,  TransferTime / nTransferPts * 1000,   TransferTime / nTransConvPtsPerCh * 1000 ,   TransferTime / nTransConvPtsPerCh / nSmpInt * 100000
//		printf  "\t\tConvolve:\t%3.2lf\tch *\t %11d \t=%11d\tpts \t %11d \tms  -> %5.2lf\t/ %5.2lf\tus / pt \t= %5.1lf\t%% of SI  \r",  nTransConvChs, nTransConvPtsPerCh, nConvolvePts, ConvolveTime, ConvolveTime / nConvolvePts * 1000, ConvolveTime / nTransConvPtsPerCh * 1000, ConvolveTime / nTransConvPtsPerCh / nSmpInt * 100000
//		printf  "\t\tGraphics: \t%3d \tch *\t %11d \t=%11d\tpts \t %11d \tms  -> %5.2lf\t/ %5.2lf\tus / pt \t= %5.1lf\t%% of SI  \r", nCntAD, nGraphicsPtsPerCh, nGraphicsPts, GraphicsTime, GraphicsTime / nGraphicsPts * 1000, GraphicsTime / nGraphicsPtsPerCh * 1000, GraphicsTime / nGraphicsPtsPerCh /nSmpInt * 100000
//		printf  "\t\tOnlineAnal:\t%3d \tch *\t %11d \t=%11d\tpts \t %11d \tms  -> %5.2lf\t/ %5.2lf\tus / pt \t= %5.1lf\t%% of SI  \r", nCntAD, nCFSWritePtsPerCh, nCFSWritePts, OnlineAnTime, OnlineAnTime / nCFSWritePts * 1000, OnlineAnTime / nCFSWritePtsPerCh * 1000, OnlineAnTime / nCFSWritePtsPerCh / nSmpInt * 100000 
//		printf  "\t\tCfsWrite:  \t%3d \tch *\t %11d \t=%11d\tpts \t %11d \tms  -> %5.2lf\t/ %5.2lf\tus / pt \t= %5.1lf\t%% of SI  \r", nCntAD, nCFSWritePtsPerCh, nCFSWritePts, CFSWriteTime, CFSWriteTime / nCFSWritePts * 1000, CFSWriteTime / nCFSWritePtsPerCh * 1000, CFSWriteTime / nCFSWritePtsPerCh / nSmpInt * 100000 
//		printf  "\t\tProcessing:\t%3d \tch *\t %11d \t=%11d\tpts \t %11d \tms  -> %5.2lf\t/ %5.2lf\tus / pt \t= %5.1lf\t%% of SI  \r", nCntAD, nCFSWritePtsPerCh, nGraphicsPts, ProcessTime, ProcessTime / nCFSWritePts * 1000, ProcessTime / nCFSWritePtsPerCh * 1000, ProcessTime / nCFSWritePtsPerCh / nSmpInt * 100000 
//		//printf  "\t\tProtocol(total/stored):\t%d / %d ms  \tMeasured(routines): %d = %.1lf%% \t\tMeasured(overall): %d = %.1lf%% \r", ProtocolTotalTime,  ProtocolStoredTime, InRoutinesTime,  InRoutinesTime / ProtocolTotalTime * 100,ReadTimer( "TotalADDA" ),ReadTimer( "TotalADDA" )/ ProtocolTotalTime * 100
//		printf  "\t\tProtocol(total/stored):\t%d / %d ms  \tMeasured(routines): %d = %.1lf%% \t\tMeasured(overall):??? \r", ProtocolTotalTime,  ProtocolStoredTime, InRoutinesTime,  InRoutinesTime / ProtocolTotalTime * 100//,ReadTimer( "TotalADDA" ),ReadTimer( "TotalADDA" )/ ProtocolTotalTime * 100
//	endif
//End

constant		cDADIREC = 0, cADDIREC = 1		// same as in XOP MWave.C

static Function	stConvolveBuffersDA( sFolder, wIO, nChunk, nRep, nChunksPerRep, nChs, PtpChk, wRaw, nHostOfs, nPnts )
// mixes points of all  separate DAC-channel stimulus waves  together in small wave ' wRaw'  in transfer area 
	string  	sFolder
	wave  /T	wIO
	variable	nChunk, nRep, nChunksPerRep, nChs, PtpChk, nHostOfs, nPnts
	wave	wRaw
	nvar		gRadDebgSel		= root:uf:dlg:gRadDebgSel
	nvar		pnDebgAcqDA		= root:uf:dlg:Debg:AcqDA
	variable	pt, begPt	  = PtpChk  * nChunk					// BegPt and EndPt are points in the CED sampling area (typ. 16MB) ....
	variable	endPt	  = PtpChk * ( nChunk + 1 )				// The same BegPt and EndPt are passed multiple times if nReps is >1 (=long scripts and/or many protocols)
	variable	repOs	  = nRep * PtpChk * nChunksPerRep		// BegPt and EndPt  PLUS the repetition offset 'repOs' gives the true point number in the DAC wave independently from the CED sampling area size
	variable	DACRange = 10							// + - Volt
	variable	c,	nIO	  = kIO_DAC
	if ( ( gRadDebgSel == 2  ||  gRadDebgSel == 3 )  &&  pnDebgAcqDA )
		// 2010-03-29  numPnts( wRaw ) gives no longer number of data points but fixed maximum size 
		printf "\t\tConvDA \t \tc:%d\t\t\t\t\tChnk:%2d\tnRep:%2d\tCPRep:%2d\tnChs:%d\tPtpChk:%5d\tnHostOfs:%5d\tbeg:\t%10d\tend:\t%10d\t\t\t\t\t\t\trOs: %10d  \twRaw:%5dpts\tnPnts:\t%8d \r", c, nChunk, nRep, nChunksPerRep, nChs, PtpChk, nHostOfs, begpt, endpt, repOs, numPnts( wRaw ), nPnts
	endif
	for ( c = 0; c < nChs; c += 1 )
		variable	ofs		= c + nHostOfs 
		variable	yscl		=  iov( wIO, nIO, c, cIOGAIN ) * kMAXAMPL / 1000 / DACRange					// scale  in mV
		wave	wDacReal	= $FldAcqioio( sFolder, wIO, nIO, c, cIONM ) 								
		// printf "\t\t\t\tAcqDA Cnv>DA14>Cpy\t %10d  \t%8d",  2*begPt, 2*(mod(begPt,(2*PtpChk))+ofs)	

		variable	code	= xUtilConvolve( wDacReal, wRaw, cDADIREC, nChs, 0, begPt, endPt, RepOs, PtpChk, ofs, yscl, 0, 0, 0, nPnts, 0 )	// ~ 40ns / data point
		if ( code )
			printf "****Error: xUtilConvolve() DA returns %d (%g)  \r", code, code
		endif
//		 for ( pt =   begPt;  pt < endPt;   pt += 1 )
//			variable	pt1	= mod( pt + repOs, wG[ kPNTS ] )									// Simple code without compression
//			wRaw[ mod( pt, (2*PtpChk)) * nChs + ofs ]  = wDacReal[ trunc( pt1 / SmpF ) ] * yscl			// ~ 4 us  / data point  (KEEP: including SmpF)
//		 endfor
	endfor
	return	endPt  + repOs
End



Static Function	stDeconvolveBuffsAD( sFolder, wG, wIO, nChunk, nRep, nChunksPerRep, PtpChk, wRaw, nHostOfs, nCntAD, nCntTG, nCompress, nPnts )
// extracts mixed points of all ADC -  and  TG - channels from ' wRaw' transfer area into separate IGOR AD waves
	string  	sFolder
	wave	wG
	wave  /T	wIO
	variable	nChunk, nRep, nChunksPerRep, PtpChk, nHostOfs, nCntAD, nCntTG, nCompress, nPnts
	wave	wRaw
	nvar		gRadDebgSel	= root:uf:dlg:gRadDebgSel
	nvar		pnDebgAcqAD	= root:uf:dlg:Debg:AcqAD
	variable	nChs			= nCntAD + nCntTG
	variable	pt, BegPt		= PtpChk  * nChunk
	variable	EndPt		= PtpChk * ( nChunk + 1 )
	variable	RepOs		= ( nRep - 1 ) * PtpChk * nChunksPerRep

// 031120
variable	bStoreIt, nBigChunk= ( BegPt + RepOs ) / PtpChk 
if ( cELIMINATE_BLANK )	// 031120
	bStoreIt	= StoreChunkornot( sFolder, nBigChunk )				
else
	bStoreIt	= 1
endif

	variable	c = 0, yscl	=  kMAXAMPL / kFULLSCL_mV			// scale in mV
	variable	ofs, nSrcStartOfChan, nSrcIndexOfChan
	string		sRealWvNm	= FldAcqioADTGNm( sFolder, wG, wIO, c )

	if ( ( gRadDebgSel == 2  ||  gRadDebgSel == 3 )  &&  pnDebgAcqAD )
		printf "\t\tDeConvAD  \tc:%d\t'%s'\tChnk:%2d\tnRep:%2d\tCPRep:%2d\tnChs:%d\tPtpChk:%5d\tnHostOfs:%5d\tbeg:\t%10d\tend:\t%10d\tBigChk:\t%8d\tStore: %d\t \r", c, sRealWvNm, nChunk, nRep, nChunksPerRep, nChs, PtpChk, nHostOfs, begpt, endpt, nBigChunk, bStoreIt
	endif

	for ( c = 0; c < nCntAD + nCntTG; c += 1 )				// ASSUMPTION: order of channels is first ALL AD, afterwards ALL TG in  xUtilConvolve()
		// printf "\t\tDeConvAD( \tc:%d\t'%s'\tnChunk:%2d\tnRep:%2d\tCPRep:%2d\tnChs:%d\tPtpChk:%5d\tnHostOfs:%5d\tbpt:\t%7d\tept:\t%7d \r", c, sRealWvNm, nChunk, nRep, nChunksPerRep, nChs, PtpChk, nHostOfs, begpt, endpt
		sRealWvNm	= FldAcqioADTGNm( sFolder, wG, wIO, c )
		wave   wReal 	=  $sRealWvNm		

		// bStoreIt : Set  'Blank'  periods (=periods during which data were sampled but not transfered to host leading to erroneous data in the host area)  to  0  so that the displayed traces  look nice.  // 031120
		variable	code	= xUtilConvolve( wReal, wRaw, cADDIREC, nCntAD, nCntTG, BegPt, EndPt, RepOs, PtpChk, nHostOfs, yscl, nCompress, nChunk, c, nPnts, bStoreIt )	// ~ 40ns / data point
		if ( code )
			printf "****Error: xUtilConvolve() AD returns %d (%g)  Is Nan:%d \r", code, code, numtype( code) == kNUMTYPE_NAN
		endif

	endfor

	return 	endPt  + repOs 
End


constant		cFILTERING			= 10000	// 1 means ADC=DAC=no filtering,    200 means heavy filtering
constant		cNOISEAMOUNT		= 0.002	// 0 means no noise,   1 means noise is appr. as large as signal   (for channel 0 )
constant		cCHANGE_TG_SECS 	= 2			// gain switching by simulated telegraph channels will ocur with roughly this period


static Function	stTestCopyRawDAC_ADC( wG, nChunk, PtpChk, wRaw, nDACHostOfs, nADCHostOfs )
// helper for test mode without CED1401: copies dac waves into adc waves
// Multiple Dac channels are implemented but not tested...
	wave	wG
	variable	nChunk, PtpChk, nDACHostOfs, nADCHostOfs
	wave	wRaw
	variable	nCntDA		= wG[ kCNTDA ]	
	variable	nCntAD		= wG[ kCNTAD ]	
	variable	nCntTG		= wG[ kCNTTG ]	
	nvar		gnCompress	= root:uf:aco:co:gnCompressTG
	variable	pt, ch, nChs 	= max( nCntDA, nCntAD ), indexADC, indexDAC, indexTG
	variable	nFakeTGvalue	= 27000 + 5000 * mod( trunc( ticks / cCHANGE_TG_SECS / 100), 2 ) // gain(27000):1, gain(32000):2,  gain(54000):gain50, gain(64000):200
	//variable	ADCRange	= 10						// + - Volt
	variable	yscl	=  kMAXAMPL / kFULLSCL_mV//1000 / ADCRange		// scale in mV

	// printf "\t\tAcqDA TestCopyRawDAC_ADC()   nChunk:%d   PtpChk:%d   Compr:%d  nDA:%d   nAD:%d   nTG:%d    max() = nChs:%d  nFakeTGvalue:%d \r", nChunk, PtpChk, gnCompress, nCntDA, nCntAD, nCntTG, nChs, nFakeTGvalue
	nChunk	= mod( nChunk, 2 ) 
	// Fake the AD channels
	for ( ch = 0; ch < nCntAD; ch += 1 )
		// get average to add some noise (proportional to signal) to fake ADC data if no CED1401 is present
		variable	nBegIndexDAC =  PtpChk * nChunk 	*	nCntDA + min( ch, nCntDA - 1 ) + nDACHostOfs
		variable	nEndIndexDAC =  PtpChk * (nChunk+1)  *	nCntDA + min( ch, nCntDA - 1 ) + nDACHostOfs
		wavestats /Q /R=(nBegIndexDAC, nEndIndexDAC) wRaw 
		variable	ChanFct	= 10^ch									// Ch0: 1 ,  Ch1: 10  , Ch2: 100
		for ( pt = PtpChk * nChunk;  pt < PtpChk * ( nChunk + 1 );   pt += 1 )		// if there are the same number of DA and AD they are mapped 1 : 1

			indexDAC =  pt + (nChunk ) * min( ch, nCntDA - 1 ) * PtpChk +	nDACHostOfs	// it there is only 1 DA but more than 1 AD the DA is mapped to all ADs  with different amount of filtering and noise
			indexADC =  pt + ( nChunk * ( nCntAD + nCntTG - 1 ) +  ch ) * PtpChk + nADCHostOfs	// if there is only 1 AD it is mapped to DA0
	
			// filtering is implemented here to see a difference between DAC and ADC data
			//! integer arithmetic gives severe and very confusing rounding errors with amplitudes < 20
			// chan 0 : little noise, heavy filtering , chan 1 : medium noise, medium filtering,  chan 2 : much noise , little filtering
		 	wRaw[ indexADC ]  =  ChanFct / cFILTERING * wRaw[  indexDAC ] + ( 1 - ChanFct / cFILTERING ) * wRaw[ indexDAC - min( ch, nCntDA - 1 ) ]  + ChanFct * gNoise( V_avg  * cNOISEAMOUNT)  
		endfor
	endfor

	// Fake the telegraph channels
	for ( ch = 0; ch < nCntTG; ch += 1 )
		for ( pt = PtpChk * nChunk;  pt < PtpChk * ( nChunk + 1 );   pt +=  gnCompress )		
			indexTG =  pt +  ( nChunk * ( nCntAD + nCntTG - 1 ) + ( ch  + nCntAD ) ) / gnCompress * PtpChk + nADCHostOfs	
		 	wRaw[ indexTG /gnCompress ]   	=   ( ch + 1 ) * nFakeTGvalue / yscl
		endfor
	endfor
	return 0
End


Function	/S	FldAcqioADTGNm( sFolder, wG, wIO, c )
// Returns wave name (including folder) for Adc or telegraph wave  when  index  c = 0,1,2... is given. 	ASSUMPTION: order of channels is first ALL AD, afterwards ALL TG
	string  	sFolder
	wave	wG
	wave  /T	wIO
	variable	c
	string  	sNm	= ksROOTUF_ + sFolder + ":" + ksF_IO + ":" + ADTGNm( wG, wIO, c ) 
	// printf "\t\t\tFldAcqioADTGNm( \t'%s' \tc:%d )  \t-> '%s' \r", sFolder, c, sNm
	return	sNm
End

Function	/S	ADTGNm( wG, wIO, c )
// Returns wave name for Adc or telegraph wave  when  index  c = 0,1,2... is given. 	ASSUMPTION: order of channels is first ALL AD, afterwards ALL TG
	wave	wG
	wave  /T	wIO
	variable	c
	variable	nChanNr, nCntAD	= wG[ kCNTAD ]	
	if ( c < nCntAD )
		nChanNr	= iov( wIO, kIO_ADC, c, cIOCHAN )
		// printf "\t\t\tADTGNm( \tc:%2d /%2d AD, %2d TG ) \t-> is AD , true AD chan number  : %d   -> '%s' \r", c, nCntAD, wG[ kCNTTG ], nChanNr , AdcNm_( nChanNr ) 	
		return	AdcNm_( nChanNr ) 					// The wave name of a true AD channel...
	else											// ..must be different  from the wave name of a telegraph channel.

//		nChanNr	=  TGChan( wIO, kIO_ADC, c  - nCntAD )		// 041201 WRONG
		variable	cTG, nSkip = 0											// 041201 Flaw : Seach every time. This searching could be avoided if a global list was created once......
		for ( cTG	= nCntAD; cTG <= c; cTG += 1 )								// for all TG channels starting at the TG index = 0   ~   True Adc index = nCntAd
			nChanNr	= iov( wIO, kIO_ADC, cTG - nCntAD + nSkip, cIOTGCH ) 		// loop through the true Ad channels and try to extract the accompanying  TG channel		
			if ( numType( nChanNr ) == kNUMTYPE_NAN )						// there may be true Adc chans without a TG chan...
				nSkip += 1												// ...these have  Nan  as TG chan : skip them...
				cTG	-= 1												// ...and check same channel again
			endif
		endfor


		// printf "\t\t\tADTGNm( \tc:%2d /%2d AD, %2d TG ) \t-> is TG , true AD chan number  : %d   -> '%s' \r", c, nCntAD, wG[ kCNTTG ], nChanNr , TGNm( nChanNr )
		return	TGNm_( nChanNr ) 					// This allows that the same telegraph channel is also sampled and processed.. 
	endif											// ..independently as true AD channel. This is (at least) very useful for testing....
End

Function	/S	AdcNm_( ch )
// Returns wave name for Adc (not for telegraph, their name must differ!) wave when true channel number from script is given
	variable	ch
	return	"Adc" + num2str( ch  )
End

Function	/S	FldAcqioTgNm_( sFolder, ch )
// Returns wave name  (including folder)  for  telegraph wave when true channel number from script is given. This name must be different from the name for the true Adc wave
	string  	sFolder
	variable	ch
	return	ksROOTUF_ + sFolder + ":" + ksF_IO + ":" + TGNm_( ch ) 
End

Function	/S	TgNm_( ch )
// Returns wave name for  telegraph wave when true channel number from script is given. This name must be different from the name for the true Adc wave
	variable	ch
	return	AdcNm_( ch ) + "T"
End


Function		SupplyWavesADC( sFolder, wG, wIO, nPnts )
	// supply  ADC channel waves (as REAL)  here 
	string  	sFolder
	wave	wG
	wave  /T	wIO
	variable	nPnts
	nvar		gnProts	= $ksROOTUF_ + sFolder + ":keep:gnProts"
	variable	nCntAD	= wG[ kCNTAD ]	
	variable	c
	string		bf
	
	if ( cPROT_AWARE )
		nPnts *= gnProts
	endif
	for ( c = 0; c < nCntAD; c += 1)
		string  	sNm	= 	FldAcqioADTGNm( sFolder, wG, wIO, c )
		// print "050128 make    \t", sNm, "  \t", nPnts
		make  /O   	/N=	( nPnts)	$sNm
		sprintf bf, "\t\t\tCed SupplyWavesADC(  Adc  )  \t building  c:%2d/%2d  '%s' \tpts:%6d\r", c, nCntAD,  sNm, numPnts( $sNm ) 
		Out1( bf, 1)//0 )
	endfor
End

Function		SupplyWavesADCTG( sFolder, wG, wIO, nPnts )
	// supply  ADC telegraph channel waves (as REAL)  here 
	string  	sFolder
	wave	wG
	wave  /T	wIO
	variable	nPnts
	nvar		gnProts		= $ksROOTUF_ + sFolder + ":keep:gnProts"
	variable	nCntAD		= wG[ kCNTAD ]	
	variable	nCntTG		= wG[ kCNTTG ]	
	nvar		gnCompress	= root:uf:aco:co:gnCompressTG
	variable	c
	string		bf
	variable	nTestPnts		= nPnts  / gnCompress
	//nPnts	= nPnts  / gnCompress		// 050128
	nPnts	= ceil( nPnts  / gnCompress )	// 050128  Dimension 1 more instead of truncating. This last element is accessed in xUtilConvolve() . If not dimensioned sporadic crashes occur...
	
	if (  cPROT_AWARE )
		nPnts *= gnProts				// 050128 untested with  ceil( nPnts  / gnCompress )
	endif
	for ( c = nCntAD; c < nCntAD + nCntTG; c += 1)	
		string  	sNm	= 	FldAcqioADTGNm( sFolder, wG, wIO, c )
		 printf "\t\t\tSupplyWavesADCTG() make    \t%s[ %d ]    (possibly wrong truncation: %d <- %g)  \r", sNm,  nPnts, trunc( nTestPnts ) , nTestPnts	// 050128
		make  /O   	/N=	( nPnts)	$sNm
		sprintf bf, "\t\t\tCed SupplyWavesADCTG(AdcTG)\t building  c:%d  '%s' \tpts:%6d \t=?= %.3lf %s\tCompress:%3d \r", c,  sNm, numPnts( $sNm ) , nPnts, SelectString(  numPnts( $sNm ) != nPnts , " OK ", " ??????????????????????????????????" ) , gnCompress
		Out1( bf, 1)//0 )
	endfor
End

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function 		SetPoints( sFolder, wG, CedMaxSmpPts, nPnts, nSmpInt , nDA, nAD, nTG, nSlices, nErrorBad, nErrorFatal )
	// Given the number of data points to be transferred (=nPnts) , the CED memory size and any channel combinations.. 
	// ..we try to split 'nPnts'  into factors  'nReps'  *  'nChunkPerRep'  *  'xxx=CompPts'  *  'nCompress'
	// The assumption (which makes splitting impossible in rare cases but life easy after a suitable split is found) is that all repetions have equal number of chunks (='nChunkPerRep' )
	// The above split factors must meet certain conditions imposed by the available CED memory
	//	 - the number of points per chunk must fits into the transfer area 
	//	 - the number of points per chunk must fits into the sampling area
	// To achieve high data rates it is very important to have optimum TA memory usage (>90%) 
	// To achieve a long interruption time (possibly demanded by Windows and/or  mouse action by user)  a high sampling memory usage is required
	//  An optimum telegraph data compression has been introduced which allows higher overall data rates  
	// Flaws: It is not guaranteed that splitting is possible while all of the above conditions are met. 
	//	- If the stimulus protocol consists mainly of large primes it may not be divisible without remainder in chunks small enough to fit into the transfer area
	//	- This could be avoided by allowing remainders (the last repetition being different from all others), but as this would lead to multiple complications this approach is not taken.

	// General considerations:
	// We can optimize the program behaviour during acquisition in 2 directions: maximum data rates  or  fast reaction time
	// Given the number of script data points we try to adjust the compression factor, the number of repetitions, the ChunksperRep and the PointsPerRep to find the optimum combination.
	// A high compression factor is in principle favorable both for  maximum data rates  and  fast reaction time  as it decreases the overall amount of data to  be transfered.
	// But still the highest compression factor found may not be the best because choosing a slightly lower factor may vastly improve the other factors leading to a much better overall performance.
	// A low number of repetitions is always favorable both for  maximum data rates  and  fast reaction time  as it  makes optimum use of the CED memory leading to high  interruption times.
	// So actually only ChunksperRep and PointsPerRep are left for controling the program behaviour :
	 // To achieve  maximum data rates we would choose the minimum ChunksperRep and the maximum PointsPerRep : For  fast reaction time we would choose the opposite.
	 // As searching and finding the optimum combination may take a considerable amount of time it is important to step the factors in the right direction:
	 // The search should start at the optimum end of the allowed range so that the first value found is the best and inferior values have not to be tested.

// Runs faster when a high gMaxReactnTime ( >=20 s ) is set.  One could possibly speed this up even for the commonly used  gMaxReactnTime ~ 2 s, ..
// ...if the combinations having too high a reaction time are sorted out early..... 

	string  	sFolder
	wave	wG
	variable	CedMaxSmpPts, nPnts, nSmpInt, nDA, nAD, nTG, nSlices, nErrorBad, nErrorFatal
	nvar		gMaxReactnTime 	= $ksROOTUF_ + sFolder + ":dlg:gMaxReactnTime" 
	nvar		gnProts			= $ksROOTUF_ + sFolder + ":keep:gnProts"
	nvar		gnCompressTG	= root:uf:aco:co:gnCompressTG
	nvar		gMaxSmpPtspChan	= root:uf:aco:co:gMaxSmpPtspChan
	nvar		gnReps			= root:uf:aco:co:gnReps
	nvar 	gChnkPerRep		= root:uf:aco:co:gChnkPerRep
	nvar		gPntPerChnk		= root:uf:aco:co:gPntPerChnk
	nvar	 	gnOfsDA			= root:uf:aco:co:gnOfsDA
	nvar		gSmpArOfsDA		= root:uf:aco:co:gSmpArOfsDA
	nvar 	gnOfsAD			= root:uf:aco:co:gnOfsAD
	nvar		gSmpArOfsAD		= root:uf:aco:co:gSmpArOfsAD
	nvar		gnOfsDO			= root:uf:aco:co:gnOfsDO
	variable	nDAMem, nADMem,  SmpArEndDA,  SmpArEndAD, nDigoutMem, nTrfAreaBytes, TAUsed = 0, MemUsed = 0, FoM = 0, BestFoM = 0, nChunkTimeMS
	variable	nReps, MinReps, nChnkPerRep, nPntPerChnk, nChunks, MinNrChunks, nSumChs, EffChsM, EffChsTA, PtpChkM, PtpChkTA,  c, nCompress, nCompPts, HasPoints, Quot, bOK
	variable	bPrintIt	=   TRUE//FALSE
	string		bf

	gnCompressTG	= 255
	gMaxSmpPtspChan	= 0
	gnReps			= 0
	gChnkPerRep		= 0
	gPntPerChnk		= 0

	nDigOutMem		= nSlices  * BYTES_PER_SLICE 
	gnOfsDO			= floor( ( CedMaxSmpPts * 2 - nDigOutMem ) / BYTES_PER_SLICE ) * BYTES_PER_SLICE	// 16 byte boundary is sufficient at the top end of the CED memory
	CedMaxSmpPts	= gnOfsDO / 2								// decrease sampling area by memory occupied by digout slices (=above gnOfsDO)

	string		lstCompressFct
	string		lstPrimes	

	nPnts	= nPnts * gnProts								//

	lstCompressFct	= stCompressionFactors( nPnts, nAD, nTG )			// list containing all allowed compression factors

	//sprintf  bf, "\t\t\t\t\tCed SetPoints( ProtAw:%d)\tMxPts\t\tnPts\tSlc\t DA AD TG Cmp\tSum  MxPtpChan\t MinChk\tChunks\tMinRep\tREPS CHKpREP PTpCHK\t ChkTim\tTA%% M%% FoM \r", cPROT_AWARE
// 2021-08-01 reformated to better align columns.  Must be adjusted depending on screen resolution, font and font size
//	sprintf  bf, "\t\t\tCed SetPoints( ProtAw:%d)\t\t\tMxPts\t\tnPts\tSlc\t DA AD TG Cmp\tSum  MxPtpChan\t MinChk\tChunks\tMinRep\tREPS CHKpREP PTpCHK\t ChkTim\tTA%% M%% FoM \r", cPROT_AWARE
	sprintf  bf, "\t\t\tCed SetPoints( ProtAw:%d)\t\t\tMxPts\t\tnPts\tSlc\t DA AD TG Cmp  Sum  MxPtpChan\t MinChk  Chks  MinRp  REPS  CHKpREP  PTpCHK  ChkTim     TA%%     M%%     FoM   Prots    Quot   OK\r", cPROT_AWARE
	Out1( bf, bPrintIt )

	// Loop1(Compress): Divide  'nPnts'  by all possible compression factors to find those which leave no remainder
	BestFoM = 0
	for ( c = 0; c < ItemsInList( lstCompressFct ); c += 1 )

		nCompress	= str2num( StringFromList( c, lstCompressFct ) )
	
		nSumChs		= nAD + nDA + nTG
		EffChsM		= 2 * nDA + 2 * nAD + nTG + nTG / nCompress	// Determine the absolute minimum number of effective channels limited by the entire CED memory (= transfer area + sampling area )
		PtpChkM		= trunc( CedMaxSmpPts / EffChsM / 2 )		// Determine the absolute maximum PtsPerChk considering the entire Ced memory,  2 reserves space for the 2 swinging buffers
		EffChsTA		=  nDA + nAD + nTG / nCompress			// Determine the absolute minimum number of effective channels limited by the Transfer area
		PtpChkTA	= trunc( cMAX_TAREA_PTS / EffChsTA / 2 )	// Determine the absolute maximum PtsPerChk considering only the Transfer area ,  2 reserves space for the 2 swinging buffers
		nPntPerChnk	= min( PtpChkTA, PtpChkM )				// the lowest value of both and of the passed value is the new upper limit  for  PtsPerChk

		MinNrChunks	= ceil( nPnts / nPntPerChnk )				// e.g. maximum value for  1 DA, 2AD, 2TG/Compress: 1 MBYTE =   appr.  80000 POINTSPerChunk * 3.1 Channels *  2 swap halfs
		sprintf  bf, "\t\t\tCed SetPoints(tried..)\t%10d\t%10d  %4d\t%4d%4d%5d%5d\t%5.3lf \t%5.3lf \t%6d\tMxPpCM:%6d\tMxPpCT:%6d >%6d \r", CedMaxSmpPts, nPnts, nSlices, nDA, nAD, nTG, nCompress, EffChsTA, EffChsM, MinNrChunks, PtpChkM, PtpChkTA, nPntPerChnk
		Out1( bf, 0 ) 
	
		gMaxSmpPtspChan	= trunc(  ( CedMaxSmpPts -  ( nDA + nAD  + nTG / nCompress ) * 2 * nPntPerChnk ) / nSumChs )	// subtract memory used by transfer area
	
		// Get the starting value for the Repetitions loop
		// the correct (=large enough) 'MinReps' value ensures that ALL possibilities found in the 'Rep' loop below are legal (=ALL fit into the CED memory) : none of them has later to be sorted out
		MinReps			= ceil( nPnts / gMaxSmpPtspChan )	
	
		nCompPts	= nPnts / nCompress
		// printf "old -> new \tCompress: %2d \tMinChunks:%2d \t-> %d \tMinReps:%2d \t-> %d  \r", nCompress, ceil( nPnts / nPntPerChnk ), ceil( nPnts*gnProts / nPntPerChnk ),  ceil( nPnts / gMaxSmpPtspChan ), ceil( nPnts*gnProts / gMaxSmpPtspChan )

		// Loop2( nPnts reduced by compress ) 

		//  Optimize for highest possible data rates while fulfilling the reaction time condition.
		//  
		// We start with (and increase) the minimum number of chunks until we find a combination of  nChunks and  PtpChk which fits nPnts without remainder
		// When the FIRST combination is found their FigureOfMerit is compared to previous values (obtained with other compression values) and stored if  the current FoM is better, then the loop is left immediately.
		// The  so found first combination will automatically have the lowest 'nChunks' value and consequently the highest 'PtsPerChunk'  /  TA-Mem_Usage / FoM  value.  
		// Unfortunately it will also have a long reaction time,  even in the case of few data points (nReps=1) when high data rates would be are obtained automatically even with  a low number of 'PtsPerChunk' .
		// To also  fulfill the reaction time condition we increase 'nChunks'  (which automatically decreases the reaction time)  until the reaction time condition is fulfilled. 
		// The FigureOfMerit of this value just fulfilling the reaction time condition (one value for each compesssion factor)  is compared to those obtained for other compression factors: the best FoM is finally taken.
	
		do
			nChunks		= FindNextDividerBetween( nCompPts, MinNrChunks, nCompPts )		// could be made faster as the prime splitting needs in principle only be done once...
			if ( nChunks == kNOTFOUND )
				break								// Leave the loop as  'nCompPts'  was a prime number which cannot be processed. The 'FoM'  being 0  will  trigger an error to alert the user.
			endif
			 // nReps		= FindNextDividerBetween( nChunks, MinReps, nChunks / 2 )		// 031125 we need al least 2 chunks, but then ChunksPerRep = 2 may result which works in principle but has in some cases too little 'gReserve'  for a reliable acquisition...
			nReps		= FindNextDividerBetween( nChunks, MinReps, nChunks / 3 )		// 031125 / 3 : we use at least 3 chunks although we theoretically need only at least 2 chunks. We then avoid ChunksPerRep = 2 which works in principle but has in some cases too little 'gReserve'  for a reliable acquisition...
			if ( nReps == kNOTFOUND )
				// printf "\t\t\t\tCed SetPoints(3) \tnCompTG:%3d , \tSum:%.3lf \tCmpPts:\t%7d\tnChunks: %.3lf \t-> %3d -> %3d , \t==Quot:\t%6d\tReps:%3d min\tCould not divide %3d / nReps \r", nCompress, EffChsTA, nCompPts, nPnts/ nPntPerChnk, MinNrChunks, nChunks, nCompPts / nChunks, MinReps, nChunks
				MinNrChunks	= nChunks+1
				continue								// Restart the loop
			endif
			nChnkPerRep	= nChunks / nReps				// we found a combination of  nReps and  ChnkPerRep which fits nChunks without remainder


			// 2021-08-01  Peipeng.  Prevent possible scrambling of data sometimes occurring with certain combinations of script duration and sample interval when Protocols>1
			Quot		= nChnkPerRep / gnProts
			bOK			= ( Quot == trunc( Quot ) )
			if ( ! bOK )
				MinNrChunks	= nChunks+1
				continue								// Restart the loop
			endif


			nPntPerChnk	= nPnts / nChunks  
			// printf "\t\t\t\tCed SetPoints(4) \tnCompTG:%3d , \tSum:%.3lf \tCmpPts:\t%7d\tnChunks: %.3lf \t\t   -> %3d , \t==Quot:\t%6d\tReps:%3d/%d\tChnk/Reps:\t%4d\t  PtpChk:%6d \r", nCompress, EffChsTA, nCompPts, nPnts/ nPntPerChnk,  nChunks, nCompPts / nChunks, MinReps, nReps, nChunks / nReps, nPntPerChnk	 

			nChunkTimeMS= nPntPerChnk * nSmpInt / 1000
			MemUsed	= stMemUse(  nChnkPerRep, nPntPerChnk, gMaxSmpPtspChan )
			TAused		= stTAuse( nPntPerChnk, nDA, nAD, cMAX_TAREA_PTS ) 
			// Even when optimizing the reaction time  the FigureOfMerit  depends only on the memory usage. The reaction time is introduced as an  'too long' - 'OK' condition
			FoM			= stFigureOfMerit( nChnkPerRep, nPntPerChnk, gMaxSmpPtspChan, nDA, nAD, nTG,  nCompress, cMAX_TAREA_PTS ) 
		
			// 2021-08-01  Peipeng
			//sprintf  bf, "\t\t\t\t\tCed SetPoints(candi.)\t%10d\t%10d  %4d\t%4d%4d%5d%5d\t%5.3lf %10d\t%6d\t%6d\t%6d\t%6d\t%6d\t%6d\t%6d\t%3d\t%3d\t%6.1lf  \r", CedMaxSmpPts, nPnts, nSlices, nDA, nAD, nTG, nCompress, nDA+ nAD+nTG/nCompress,  gMaxSmpPtspChan, MinNrChunks, nReps * nChnkPerRep, MinReps, nReps, nChnkPerRep, nPntPerChnk, nChunkTimeMS, TAUsed, MemUsed, FoM
			//Out( bf )
			sprintf  bf, "\t\t\t\t\tCed SetPoints(candi.)\t%10d\t%10d  %4d\t%4d%4d%5d%5d\t%5.3lf %10d\t%6d\t%6d\t\t%6d\t%6d\t\t%6d\t\t%6d\t %6d\t%3d\t%3d\t%5.1f\t%8d\t%4.1f\t %2d\r", CedMaxSmpPts, nPnts, nSlices, nDA, nAD, nTG, nCompress, nDA+ nAD+nTG/nCompress,  gMaxSmpPtspChan, MinNrChunks, nReps * nChnkPerRep, MinReps, nReps, nChnkPerRep, nPntPerChnk, nChunkTimeMS, TAUsed, MemUsed, FoM, gnProts, Quot, bOK
			Out1( bf, 0 )

			MinNrChunks	= nChunks + 1					// When optimizing ONLY for high data rates: Comment out this line 

			if ( nChunkTimeMS <= gMaxReactnTime * 1000 )	// When optimizing ONLY for high data rates: Skip condiition = set always to true
				if ( FoM > BestFoM )
					gnCompressTG	= nCompress
					gnReps		= nReps	
					gChnkPerRep	= nChnkPerRep	
					gPntPerChnk	= nPntPerChnk  
					BestFoM		= FoM
				endif		
				break		// Leave the loop. The first  'nChunks'  and  the  first  'nReps'  found  (both having the lowest possible value)  have  best (=biggest) chunk size AND best sampling area memory usage: No need to go through the rest of the possibilities
			endif		

		while ( TRUE ) 

	endfor	 		// next  smaller Compress factor

	nChunkTimeMS	= gPntPerChnk * nSmpInt / 1000
	MemUsed		= stMemUse(  gChnkPerRep, gPntPerChnk, gMaxSmpPtspChan )
	TAused			= stTAuse( gPntPerChnk, nDA, nAD, cMAX_TAREA_PTS ) 
	FoM				= stFigureOfMerit( gChnkPerRep, gPntPerChnk, gMaxSmpPtspChan, nDA, nAD, nTG,  gnCompressTG, cMAX_TAREA_PTS ) 
	Quot			= gChnkPerRep / gnProts
	bOK				= ( Quot == trunc( Quot ) )
	sprintf  bf, "\t\t\tCed SetPoints( final )\t\t\t%10d\t%10d  %4d\t%4d%4d%5d%5d\t%5.3lf %10d\t%6d\t%6d\t\t%6d\t%6d\t\t%6d\t\t%6d\t %6d\t%3d\t%3d\t%5.1f\t%8d\t%4.1f\t %2d\r", CedMaxSmpPts, nPnts, nSlices, nDA, nAD, nTG, gnCompressTG, nDA+ nAD+nTG/gnCompressTG,  gMaxSmpPtspChan, MinNrChunks, gnReps * gChnkPerRep, MinReps, gnReps, gChnkPerRep, gPntPerChnk, nChunkTimeMS, TAUsed, MemUsed, FoM, gnProts, Quot, bOK
	Out1( bf, bPrintIt )

	// The following warning sorts out bad combinations which result from the 'Minimum chunk time' condition (> 1000 ms)
	// Example for bad splitting	: nPnts : 100000 -> many chunks : 10000  , few   pointsPerChk :       10 ,   ChunkTime : 2 ms . 
	// Good (=normal) splitting	: nPnts : 100000 -> few   chunks :       10  , many pointsPerChk : 10000 ,   ChunkTime : 900 ms 
	if ( gnReps * gChnkPerRep > gPntPerChnk   &&  gnReps > 1 ) 	// in the special case of few data points (=they fit with 1 repetition in the Ced memory) allow even few PtsPerChk in combination with many 'nChunk'
		sprintf bf, "Script has bad number of data points (%d) leading to poor performance. \r\tAdjust duration(s) in stimulus protocol slightly so that data points contains more small primes." , nPnts
		lstPrimes	= FPPrimeFactors( sFolder, nPnts )					// list containing the prime numbers which give 'nPnts'
		Alert( nErrorBad,  bf + "   " + lstPrimes[0,50] )
		Delay( 2 )										// time to read the message in the continuous test mode
	endif
	
	HasPoints		= gnReps * gChnkPerRep * gPntPerChnk  
	if ( HasPoints != nPnts )		
		sprintf bf, "The number of stimulus data points (%d) could not be divided into CED memory without remainder. \r\tAdjust duration(s) in stimulus protocol slightly so that data points contains more small primes." , nPnts
		lstPrimes	= FPPrimeFactors( sFolder, nPnts )					// list containing the prime numbers which give 'nPnts'
		Alert( nErrorFatal,  bf + "   " + lstPrimes[0,50] )
		Delay( 2 )										// time to read the message in the continuous test mode
		return  0
	endif

	// Now that the number of chunks, the number of repetitions, the  ChnksPerRep and the ChunkSize are determined...
	// ..we can split the available CED memory into the transfer area, the sampling area  and the area for the digout slices 
	nDAMem		= 2 * nDA * gPntPerChnk
	nADMem		= round( 2 * ( nAD + nTG / gnCompressTG ) * gPntPerChnk )
	gnOfsDA		= 0
	gnOfsAD		= 2 * ( gnOfsDA + nDAMem )	// *2 : swap buffers!!!					// the end of the DA transfer area is the start of the AD transfer area
	nTrfAreaBytes	= 2 * ( gnOfsDA + nDAMem + nADMem )

	sprintf bf, "\t\t\t\tCed SetPoints  DA-TrfArOs:%d  Mem:%d (chs:%d)    AD-TrfArOs:%d  Mem:%d (chs:%d+%d)    -> TABytes:%d   [DigOs:%d=0x%06X] \r", gnOfsDA, nDAMem, nDA, gnOfsAD, nADMem,  nAD, nTG,  nTrfAreaBytes, gnOfsDO, gnOfsDO
	Out1( bf, bPrintIt )//0 )

	// build the areas one behind the other 
	gSmpArOfsDA	= nTrfAreaBytes												// if CED does not require sampling areas to start at 64KB borders
	SmpArEndDA	= gSmpArOfsDA + round( 2 * gChnkPerRep * gPntPerChnk * nDA  )		// uses memory ~number of channels (=as little memory as possible)
	gSmpArOfsAD	= SmpArEndDA												//  if CED does not require sampling areas to start at 64KB borders	
	SmpArEndAD 	= gSmpArOfsAD + round( 2 * gChnkPerRep * gPntPerChnk * ( nAD + nTG ) )		

	sprintf bf, "\t\t\t\tCed SetPoints  TrArBytes:%d   SmpArDA:%d..%d=0x%06X..0x%06X  SmpArAD:%d..%d=0x%06X..0x%06X  gnOfsDO:%d \r", nTrfAreaBytes, gSmpArOfsDA, SmpArEndDA, gSmpArOfsDA, SmpArEndDA, gSmpArOfsAD, SmpArEndAD, gSmpArOfsAD, SmpArEndAD, gnOfsDO
	Out1( bf, 0 )
	if ( nTrfAreaBytes > cMAX_TAREA_PTS * 2  ||  nTrfAreaBytes > gSmpArOfsDA  ||  SmpArEndDA > gSmpArOfsAD ||  SmpArEndAD > gnOfsDO )
		sprintf bf, "Memory partition error: Transfer area / Sampling area /  Digout area overlap:  %d < (%d) %d < %d < %d < %d < %d",  nTrfAreaBytes, cMAX_TAREA_PTS * 2, gSmpArOfsDA, SmpArEndDA, gSmpArOfsAD,  SmpArEndAD, gnOfsDO
		InternalError( bf )
		sprintf bf, "\t\t\t\tCed SetPoints  TrArBytes:%d   SmpArDA:%d..%d=0x%06X..0x%06X  SmpArAD:%d..%d=0x%06X..0x%06X  gnOfsDO:%d \r", nTrfAreaBytes, gSmpArOfsDA, SmpArEndDA, gSmpArOfsDA, SmpArEndDA, gSmpArOfsAD, SmpArEndAD, gSmpArOfsAD, SmpArEndAD, gnOfsDO 
		Out1( bf, 1 )
		return	kERROR
	endif

	return	nTrfAreaBytes / 2                       
End

Function		FindNextDividerBetween( nBig, nMin, nMax )
// factorizes  'nBig'  and returns the factor closest (equal or larger) to  'nMin'  and  smaller or equal  'nMax' 
// Brute force: could be done easily by looping through numbers > nMin and checking if the remainder of  nBigs/numbers  is 0 . This is OK when  nBig <~ 1 000 000, otherwise is takes too long (>1 s)
// In the approach  taken 'nBig' is first split into factors (which requires splitting into primes), then from the resulting factor list the factor closest to but greater or equal  'nMin' is picked.  Much faster for large 'nBig' 
	variable	nBig, nMin, nMax
	variable 	f, nFactor
	string		lstFactors	= stFactors( nBig )				// break  'nBig'  into factors, requires splitting into primes, lstFactors contains 'nBig'
	//for	( f = 0; f < ItemsInList( lstFactors )		; f += 1 )	// Version1 :  allow returning  'nBig'  if no other factor is found
	for 	( f = 0; f < ItemsInList( lstFactors ) - 1	; f += 1 )	// Version2 :  never return 'nBig'  even if no other factor is found (this option must be used when breaking 'nPnts' into 'chunks'  and  'Reps') 
		nFactor	= str2num( StringFromList( f, lstFactors ) )
		if ( nMin <= nFactor  &&  nFactor <= nMax )
			// printf "\t\t\t\t\tNextDividerBetween( %5d, \tnMin:%5d, \tnMax:%5d\t) -> found divider:%d   in   %s \r", nBig, nMin,nMax, nFactor, lstFactors[0, 180]
			return	nFactor
		endif
	endfor		
	// printf "\t\t\t\t\tNextDividerBetween( %5d, \tnMin:%5d, \tnMax:%5d\t) -> could not find divider between %5d\tand %5d \tin   %s \r", nBig, nMin,nMax, nMin,nMax, lstFactors[0, 180]
	return	kNOTFOUND
End	


static Function  /S	stFactors( nPnts )	
// build list containing all possible factors
	variable	nPnts	
	string 	lstFct		= ""
	string 	lstPrimes	= ""
	string  	sFolder	= ksfACO
	lstPrimes	= FPPrimeFactors( sFolder, nPnts )
	lstFct		= ""
	lstFct		= AddListItem( num2strDec( nPnts ), lstFct )		// include  'nPnts' in the list
	
	// printf "\t\t\tFactorsFast( n:%5d ) \t\t\t\t\t\t-> Primes: %s... \r", nPnts, lstPrimes
	variable	pr, f
	for ( pr = 0; pr < ItemsInList( lstPrimes ); pr += 1 )
		variable	Prime	= str2num( StringFromList( pr, lstPrimes ) )
		variable	nFct		= ItemsInList( lstFct )
		for ( f = 0; f < nFct; f += 1 )
			variable	Fct	= str2num( StringFromList( f, lstFct ) )
			if ( Fct / Prime  == trunc( Fct / Prime ) )
				if ( WhichListItem( num2strDec( Fct / Prime ), lstFct ) == kNOTFOUND )
					lstFct		= AddListItem( num2strDec( Fct / Prime ), lstFct, ";", Inf )
					// printf "\t\t\t\tFactors\tPrime( pr:%2d ) :%4d\tFct( f:%2d ) : %4d\t->Factors: %s \r", pr, Prime, f, Fct, lstFct
				endif
			endif
		endfor
	endfor
	lstFct		= SortList( lstfct, ";", 2 ) 		// 1: descending, 2:numerical sort
	// printf "\t\t\tFactors( n:%5d ) \tfactors:%3d\tlen:%4d\t-> factors: %s.....%s \r", nPnts, ItemsInList(lstFct), strlen( lstFct), lstFct[0,40], lstFct[ strlen( lstFct ) - 55, strlen( lstFct ) ]
	return	lstFct
End




Static Function		stTAUse( PtpChunk, nDA, nAD, MaxAreaPts )
	variable	PtpChunk, nDA, nAD, MaxAreaPts 
	return	PtpChunk * (nDA + nAD ) * 2 / MaxAreaPts * 100	// the compressed TG channels are NOT included here as more TG points would erroneously increase TAUsage and FoM while actually deteriorating performance
End	

Static Function		stMemUse(  nChnkPerRep, nPntPerChnk, nMaxSmpPtspChan )
	variable	nChnkPerRep, nPntPerChnk, nMaxSmpPtspChan
	return	nChnkPerRep * nPntPerChnk / nMaxSmpPtspChan * 100 		
End

Static Function		stFigureOfMerit( nChnkPerRep, PtpChunk, nMaxSmpPtspChan, nDA, nAD, nTG,  Compress, MaxAreaPts )
// Computes value for the goodness of the memory usage 
// Usually there are many possibilties to split the memory, if this is the case then this function helps to select the 'BEST' one
// Also used to alert the user to change his script a tiny bit (changing  'nPnts'  by 1 or 2 is usually sufficient)  if the script achieves only a  'Bad'  FigureOfMerit
// High  Transfer area useage is absolutely mandatory for high sampling rates, and high TG compression rates are always favorable to reduce the amount of transferred data...
// ..so there is no question about those.  However, to what extent the Memory usage should influence the FoM can be argued about.
// High Memory usage means long times during which Windows can interrupt its activities and sampling still continues.
// As right now high sampling rates seem to be much more important than long interruption times  the memory area usage is included in the FoM only with a reduction factor. Could be changed. 
	variable	nChnkPerRep, PtpChunk, nMaxSmpPtspChan, nDA, nAD, nTG,  Compress, MaxAreaPts 
	variable	FoMFactorForMemoryUsage	= .3
	variable	FoM	= PtpChunk * (nDA + nAD   -   nTG / Compress ) * 2 / MaxAreaPts * 100					// SUBTRACTION of compressed points favors high compression rates 
	FoM		+= stMemUse( nChnkPerRep, PtpChunk, nMaxSmpPtspChan ) * FoMFactorForMemoryUsage
	// printf "\t\tFoM( nChnkPerRep:%3d \tPtpChk:\t%8d\tnMaxSmpPtspChan:\t%10d\t  nDA:%d   nAD:%d   nTG:%d   Compress:%4d\t MaxAreaPts:%6d\t->  FoM:%.1lf  \r"  , nChnkPerRep, PtpChunk, nMaxSmpPtspChan, nDA, nAD, nTG,  Compress, MaxAreaPts, FoM
	return	FoM
End


Static Function  /S	stCompressionFactors( nPnts, nAD, nTG )	
// build list containing all allowed compression factors
	variable	nPnts, nAD, nTG	
	string		lstCompressFct	= ""
	// Determine the absolute maximum limit for the compression factor
	variable	n, nMaxCompressTG	= trunc ( min( cFAST_TG_COMPRESS * ( nAD + nTG ) , 255 ) / ( nAD + nTG ) )	//todo nAD=0, nTG =0
	// As the maximum compression factor is always small ( 127, 85, 63, 51,...) it is fast enough to compute it by trying all possibilities.
	// This is not the cleanest solution (which would be building all possibilities from the factor list) but is progammatically much easier.
	for ( n = nMaxCompressTG; n > 0; n -= 1 )
		if ( nPnts / n == trunc( nPnts / n ) )
			lstCompressFct	= AddListItem( num2str( n ), lstCompressFct, ";", Inf )	// list order: descending (start with the biggest value, this order is later assumed)
		endif
	endfor
	// printf "\t\t\tCompressionFactors( n:%5d, nAD:%2d, nTG:%2d )  \tnMaxCompressTG:%4d \t-> factors: %s \r", nPnts, nAD, nTG, nMaxCompressTG, lstCompressFct[0,120]
	return	lstCompressFct
End


Function		SearchImprovedStimulusTiming( sFolder, wG, nCEDMemPts, nPnts, nSmpInt, nDA, nAD, nTG, nSlices )
	string  	sFolder
	wave	wG
	variable	nCEDMemPts, nPnts, nSmpInt, nDA, nAD, nTG, nSlices
	variable	Neighbors		= 100
	printf "\t\tSearching improved stimulus timing within the range %d points * %d us = original script length = %.2lf ms to %.2lf ms ", nPnts, nSmpInt, nPnts * nSmpInt  / kMILLITOMICRO, ( nPnts + Neighbors ) * nSmpInt / kMILLITOMICRO
	CheckNeighbors( sFolder, wG, nCEDMemPts, nPnts, nSmpInt , nDA, nAD, nTG, nSlices, Neighbors )	
End


Function		CheckNeighbors( sFolder, wG, nCEDMemPts, nPnts, nSmpInt , nDA, nAD, nTG, nSlices, Neighbors )	
	string  	sFolder
	wave	wG
	variable	nCEDMemPts, nPnts, nSmpInt , nDA, nAD, nTG, nSlices, Neighbors	
	nvar		gnReps			= root:uf:aco:co:gnReps
	nvar 		gChnkPerRep		= root:uf:aco:co:gChnkPerRep
	nvar		gPntPerChnk		= root:uf:aco:co:gPntPerChnk
	nvar		gSmpArOfsDA		= root:uf:aco:co:gSmpArOfsDA
	nvar 		gSmpArOfsAD		= root:uf:aco:co:gSmpArOfsAD
	nvar		gnOfsDO			= root:uf:aco:co:gnOfsDO
	nvar		gnCompressTG		= root:uf:aco:co:gnCompressTG
	nvar		gMaxSmpPtspChan	= root:uf:aco:co:gMaxSmpPtspChan

	variable	SmpArEndDA, SmpArEndAD, nChunkTimeMS, nTrfAreaPts				// are computed
	variable	TAUsed, MemUsed, FoM, BestFoM, Pts

	BestFoM = 0
	// printf "\tSetPointsTestContNeighbors() checking points from  %d  to  %d \r",  nPnts - Neighbors, nPnts + Neighbors
	printf "\r"
//	for ( Pts = nPnts - Neighbors; Pts < nPnts + Neighbors; Pts += 2 )
	for ( Pts = nPnts; Pts < nPnts + Neighbors; Pts += 2 )
		nTrfAreaPts	= SetPoints( sFolder, wG, nCEDMemPts, Pts, nSmpInt , nDA, nAD, nTG, nSlices, kERR_MESSAGE, kERR_MESSAGE )				// all params are points not bytes	
		TAused		= stTAuse( gPntPerChnk, nDA, nAD, cMAX_TAREA_PTS ) 
		MemUsed	= stMemUse(  gChnkPerRep, gPntPerChnk, gMaxSmpPtspChan )
		FoM			= stFigureOfMerit( gChnkPerRep, gPntPerChnk, gMaxSmpPtspChan, nDA, nAD, nTG, gnCompressTG, cMAX_TAREA_PTS ) 
		if ( FoM > 1.001 * BestFoM )		// 1.001 prevents minimal useless improvement from being displayed
			BestFoM = FoM
			SmpArEndDA	= gSmpArOfsDA + trunc( 2 * gChnkPerRep * gPntPerChnk * nDA + .5 )			// like SetPoints ()	
			SmpArEndAD 	= gSmpArOfsAD + trunc( 2 * gChnkPerRep * gPntPerChnk * ( nAD + nTG ) + .5 )	// like SetPoints ()	
			// printf "\t %10d \t %10d \tSi:%4d\t%2d\t%2d\t%2d\tSl:%4d\t:Rep:%6d\t* Chk:%4d\t* PpC:%5d\tTA:%8d\t%7d\t%7d\t\t%7d\t%7d\t%10d\tFoM:%4.1lf \t \r", nCEDMemPts*2, Pts, nSmpInt , nDA, nAD, nTG, nSlices, gnReps, gChnkPerRep, gPntPerChnk, nTrfAreaPts, gSmpArOfsDA, SmpArEndDA, gSmpArOfsAD, SmpArEndAD, gnOfsDO, FoM
			printf "\t %10d \t %10d \tSi:%4d\t%2d\t%2d\t%2d\tSl:%4d\tRep\t%7d\tChk\t%7d\tPpC\t%7d\tTA:\t%7d\t  TA:%3d%% \tMem:%3d%%\t FoM:%5.1lf\t \t \r", Pts, nCEDMemPts*2, nSmpInt , nDA, nAD, nTG, nSlices, gnReps, gChnkPerRep, gPntPerChnk, nTrfAreaPts, TAUsed, MemUsed, FoM
		endif

		if ( nTrfAreaPts == kERROR )
			return kERROR
		endif
	endfor
End


Function		Random( nBeg, nEnd, nStep )
// returns random integer from within the given range, divisible by 'nStep'
	variable	nBeg, nEnd, nStep
	variable	nRange	= ( nEnd - nBeg ) / nStep						// convert to Igors random range ( -nRange..+nRange )
	variable	nRandom	= trunc ( abs( enoise( nRange ) ) ) * nStep + nBeg	// maybe not perfectly random but sufficient for our purposes
	// printf "\tRandom( nBeg,:%6d \tnEnd:%6d  \tStep:%6d \t) : %g \r", nBeg, nEnd, nStep, nRandom
	return	nRandom
End


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  CHUNKS

// 050128
constant	cSTORE_INITIALSIZE	= 1000						// choose initially not too small a value so that (potentially slow) redimensioning has to be done only seldom or never


// 2010-03-27  VERY OLD BUG : does not redimension to a bigger wave 
//Function		StoreTimesSet( sFolder, n, nSwpBegPt, nSwpEndPt )
//// Store begin and end point of the 'Cfs store' periods (= the non-Blank periods) in an array. 
//// In contrast to 'swSetTimes()'  this is not ordered by prot/block/frame/sweep . Here 1 period is stored in 1 index.
//	string  	sFolder
//	variable	n, nSwpBegPt, nSwpEndPt 
//	wave  /Z	wStoreTimes		= 	$ksROOTUF_ + sFolder + ":store:wStoreTimes"		// ignore wave reference checking failures
//	if (  ! waveExists( wStoreTimes ) )
//		variable	/G				$ksROOTUF_ + sFolder + ":store:gnStoreCnt"	= cSTORE_INITIALSIZE
//		nvar		gnStoreCnt	=	$ksROOTUF_ + sFolder + ":store:gnStoreCnt"
// 		make /O /I /N = (gnStoreCnt, 2)	$ksROOTUF_ + sFolder + ":store:wStoreTimes"		// the begin and the end  of  each 'Store' period  in total stimulus  given as a point index
//		wave	wStoreTimes	= 	$ksROOTUF_ + sFolder + ":store:wStoreTimes"	
//		 printf "\t\t\tStoreTimesSet  \tn:\t%6d\tMAKE /I \twStoreTimes  [ %d , 2 ]\tgnStoreCnt:%d  \r", n, DimSize( wStoreTimes, 0 ), gnStoreCnt	
//	endif
//	nvar		gnStoreCnt	= $ksROOTUF_ + sFolder + ":store:gnStoreCnt"		// THIS IS WRONG : MUST USE CURRENT SIZE
//	wave	wStoreTimes	= $ksROOTUF_ + sFolder + ":store:wStoreTimes"	
//	if ( n == gnStoreCnt )													// there are more times to store than the wave can currently hold: increase wave size
//		gnStoreCnt	+= cSTORE_INITIALSIZE
//		redimension /N = ( gnStoreCnt, -1 ) wStoreTimes	
//		 printf "\t\t\tStoreTimesSet  \tn:\t%6d\tREDIM  \twStoreTimes[ gnStoreCnt:%d , -1 ]  \r", n, gnStoreCnt	// 050128
//	endif
//	wStoreTimes[ n ][ 0 ]	= nSwpBegPt
//	wStoreTimes[ n ][ 1 ]	= nSwpEndPt
//	 printf "\t\t\tStoreTimesSet  \tn:%3d\tSETTING\tnSwpBegPt:\t %11d \tnSwpEndPt:\t %11d \t )   Current dimension=[%d, 2]   \t gnStoreCnt: %d \r", n, nSwpBegPt, nSwpEndPt , DimSize( wStoreTimes, 0 ),gnStoreCnt
//End


Function		StoreTimesSet( sFolder, n, nSwpBegPt, nSwpEndPt )
// Store begin and end point of the 'Cfs store' periods (= the non-Blank periods) in an array. 
// In contrast to 'swSetTimes()'  this is not ordered by prot/block/frame/sweep . Here 1 period is stored in 1 index.
	string  	sFolder
	variable	n, nSwpBegPt, nSwpEndPt 
	variable	nStoreCnt
	wave  /Z	wStoreTimes		= 	$ksROOTUF_ + sFolder + ":store:wStoreTimes"		// ignore wave reference checking failures
	if (  ! waveExists( wStoreTimes ) )
		nStoreCnt	= cSTORE_INITIALSIZE
 		make /O /I /N = (nStoreCnt, 2)	$ksROOTUF_ + sFolder + ":store:wStoreTimes"		// the begin and the end  of  each 'Store' period  in total stimulus  given as a point index
		wave	wStoreTimes	= 	$ksROOTUF_ + sFolder + ":store:wStoreTimes"	
		// printf "\t\t\tStoreTimesSet  \tn:\t%6d\tMAKE /I \twStoreTimes  [ %d , 2 ]\tgnStoreCnt:%d  \r", n, DimSize( wStoreTimes, 0 ), nStoreCnt	
	endif
	nStoreCnt	= DimSize( wStoreTimes, 0 )
	if ( n == nStoreCnt )													// there are more times to store than the wave can currently hold: increase wave size
		nStoreCnt	+= cSTORE_INITIALSIZE
		redimension /N = ( nStoreCnt, -1 ) wStoreTimes	
		nStoreCnt	= DimSize( wStoreTimes, 0 )
		// printf "\t\t\tStoreTimesSet  \tn:\t%6d\tREDIM to\twStoreTimes[ %d , -1 ]  \r", n, nStoreCnt	// 050128
	endif
	wStoreTimes[ n ][ 0 ]	= nSwpBegPt
	wStoreTimes[ n ][ 1 ]	= nSwpEndPt
	// printf "\t\t\tStoreTimesSet  \tn:\t%6d\tSETTING\tnSwpBegPt:\t %11d \tnSwpEndPt:\t %11d \t )   Current dimension=[%d, 2]   \t nStoreCnt: %d \r", n, nSwpBegPt, nSwpEndPt , DimSize( wStoreTimes, 0 ),nStoreCnt
End


Function		StoreTimesExpandAndRedim(  sFolder, nProts, nPnts, nStoreCnt )
// Set the currently overdimensioned wave to exact size. The following program function 'StoreChunkSet()'  relies on this fact (and additionally we save memory)
	string  	sFolder
	variable	nProts, nPnts, nStoreCnt
	wave	wStoreTimes	= $ksROOTUF_ + sFolder + ":store:wStoreTimes" 
	variable	nProt, nSTime
	string  	sTxt

	// printf "\t\tStoreTimesExpandAndRedim  1\t'%s' \tnProts:\t%3d\tnPnts:\t%6d\tnStoreCnt:%d )\t   wStoreTimes has dims\t[ %3d , %3d ] \twill redim to\t [ %3d , %3d ] \r", sFolder, nProts, nPnts, nStoreCnt , dimSize( wStoreTimes, 0 ) , dimSize( wStoreTimes, 1 ) , nProts * nStoreCnt, dimSize( wStoreTimes, 1 )
	redimension	/N = ( nProts * nStoreCnt, -1 ) wStoreTimes	
	// print "050128 redim     \twStoreTimes  ",  nProts , "*", nStoreCnt, "=",  nProts * nStoreCnt, -1
	if ( nProts * nStoreCnt != dimSize( wStoreTimes, 0 ) )
		sprintf sTxt, "StoreTimesExpandAndRedim    Redimension  should be = %d =?= %d = is",  nProts * nStoreCnt , dimSize( wStoreTimes, 0 ) 
		InternalError( sTxt )
		return	kERROR
	endif
	// printf "\t\tStoreTimesExpandAndRedim  2\t'%s' \tnProts:\t%3d\tnPnts:\t%6d\tnStoreCnt:%4d)\t  wStoreTimes has dims\t[ %3d , %3d ]  \r", sFolder, nProts, nPnts, nStoreCnt , dimSize( wStoreTimes, 0 ) , dimSize( wStoreTimes, 1 ) 

	for ( nProt = 1; nProt < nProts; nProt += 1 )
		for ( nSTime = 0; nSTime < nStoreCnt; nSTime += 1 )
			wStoreTimes[ nSTime + nProt * nStoreCnt ][ 0 ]	= wStoreTimes[ nSTime ][ 0 ] + nProt * nPnts 	
			wStoreTimes[ nSTime + nProt * nStoreCnt ][ 1 ]	= wStoreTimes[ nSTime ][ 1 ] + nProt * nPnts 
			// printf "\t\tStoreTimesExpandAndRedim \tnProt:\t%3d/%3d\twStoreTimes[ %3d/%3d ] =\t%11d  \t..%11d\t ->\twStoreTimes[ %3d/%3d ] =\t%11d  \t..%11d\t \r", nProt, nProts, nSTime, nStoreCnt, wStoreTimes[ nSTime ][ 0 ] , wStoreTimes[ nSTime ][ 1 ] ,  nSTime + nProt * nStoreCnt, nProts * nStoreCnt, wStoreTimes[ nSTime + nProt * nStoreCnt ][ 0 ], wStoreTimes[ nSTime + nProt * nStoreCnt ][ 1 ]
		endfor
	endfor
	return	kOK
End


Function		StoreChunkSet( sFolder, wG )												// after SetPoints() : needs nPnts and gPntPerChnk
// Builds  boolean wave containing the information if a given chunk must be stored .  
//  Chunks that need not be stored are not transfered between Host and Ced: Advantages : 1. Script load time is reduced   2. Higher acquis data rates are possible
//  To keep the program simple only complete chunks are handled: only when the whole chunk is blank it will not be transfered. If there is just 1 point to be stored the whole chunk is transfered.
//  This behaviour could (at the expense of a rather large proramming effort) be improved by splitting chunks into Store=Transfer/NoStore=NoTransfer regions..(finer granularity). 
	string  	sFolder
	wave	wG
	nvar		gnProts		= $ksROOTUF_ + sFolder + ":keep:gnProts"
	variable	nPnts		= wG[ kPNTS ] 
	nvar		gPntPerChnk	= root:uf:aco:co:gPntPerChnk 

	// Construct the boolean wave containing the information if a given chunk must be stored. Assume initially that it has not to be stored.
	make	/O    /W	/N=( gnProts * nPnts / gPntPerChnk )	$ksROOTUF_ + sFolder + ":store:wStoreChunkOrNot	"
	// print "050128 make /W \twStoreChunkOrNot x..",  gnProts ,  " * ", nPnts, " / ", gPntPerChnk, " ->",  gnProts * nPnts / gPntPerChnk 
	wave	wStoreChunkOrNot 					= 	$ksROOTUF_ + sFolder + ":store:wStoreChunkOrNot"
	wStoreChunkOrNot		= FALSE									// Assume initially that no chunk has to be stored, correct this assumption below
	variable	nChunks		= DimSize( wStoreChunkOrNot, 0 )

	// Correct the above assumption if the conditions are met that a given chunk must be stored
	wave	wStoreTimes	= $ksROOTUF_ + sFolder + ":store:wStoreTimes"
	variable	nStoreTimes	= DimSize( wStoreTimes, 0 )
	// printf "\t\t\tStoreChunkSet  a   	nProts: %d  nPnts: %d  gPntPerChk: %d  -> nChunks: %d    (Initial StoreCnt: %d ) \r", gnProts, nPnts, gPntPerChnk, nChunks, nStoreTimes
	variable	t, c
	for ( t = 0; t < nStoretimes; t += 1 )
		variable	nEarlyOn	= trunc(  wStoreTimes[ t ][ 0 ] 	/ gPntPerChnk )		// indexing is such that the usual loop construct can be used...
		variable	nLateOff	= trunc( (wStoreTimes[ t ][ 1 ] - 1)	/ gPntPerChnk ) + 1	// e.g. from EarlyOn  to < LateOff     or   from LateOff   to  < EarlyOn
		 //printf "\t\t\tStoreChunkSet  b\tTimes \tt:\t%6d\t/%6d\tBg:\t%8d\tNd:\t%8d\tnEarlyOn:\t%6d\tnLateOff:\t%6d    \r", t , nStoretimes, wStoreTimes[ t ][ 0 ], wStoreTimes[ t ][ 1 ] , nEarlyOn, nLateOff 		
		for ( c = nEarlyOn; c < nLateOff; c += 1 )
			wStoreChunkOrNot[ c ] = TRUE
		endfor 
	endfor 
	for ( c = 0; c < nChunks; c += 1 )
		 //printf "\t\t\tStoreChunkSet  ..  \tChunks \tc:\t%6d\t/%6d\tStoreIt:\t%7d\t  \r", c , nChunks, wStoreChunkOrNot[ c ] 
	endfor 
End

Function		StoreChunkornot( sFolder, nChunk )				
	string  	sFolder
	variable	nChunk
	wave	wStoreChunkOrNot = $ksROOTUF_ + sFolder + ":store:wStoreChunkOrNot"
	return	wStoreChunkOrNot[ nChunk ]
End
	

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// 030612
static Function		stCEDInit1401DACADC( hnd, mode )
	variable	hnd, mode
	variable	nType, nSize, code, bMode = mode & MSGLINE 
	string		sBuf

	if ( mode & MSGLINE )
		printf "\t\tCed CEDInit1401DACADC() : Ced is %s open.  Hnd:%d \r", SelectString( hnd == CED_NOT_OPEN, "", "NOT" ), hnd
	endif
	if ( hnd == CED_NOT_OPEN )
		return	hnd
	endif

	// change memory map if the 1401 is equipped with 16 MByte RAM or more. See p. 20 of the 1999 family programming manual
	if ( mode & MSGLINE )
		printf "\t\tCed CEDInit1401DACADC()  checking type :"
	endif 

	nType	= stCEDType( hnd, bMode )
	
	if ( mode & MSGLINE )
		printf "\t\tCed CEDInit1401DACADC()  checking memory size  \t\t\t\t\t\t\t : "
	endif
	nSize	= stCEDGetMemSize( hnd, bMode )		
	if (  nType  == 1 )   										// only 1=1401plus needs the MEMTOP,E command.  2=1401micro and  3=1401power (but not 0=1401standard..)

		stCEDSendStringCheckErrors( hnd, "MEMTOP,E;" , 0 ) 
		if ( mode & MSGLINE )
			printf "\t\tCed CEDInit1401DACADC()  checking memory size   after \tsending 'MEMTOP,E;'  : "
		endif
		nSize = stCEDGetMemSize( hnd, bMode )	
	endif

	// load these commands, 'KILL' (when loaded first) actually unloads all commands before reloading them to free occupied memory (recommendation of Tim Bergel, 2000 and 2003)
	string		sCmdDir	= "c:\\1401\\"
//	string		sCmdDir	= "c:1401:"
	string		sCmds	= "KILL,MEMDAC,ADCMEM,ADCBST,DIGTIM,SM2,SN2,SS2"	// the  Test/error led  should not flash unless commands are overwritten (which cannot occur bcause of 'KILL' above)

	// print "xCEDLdErrOut( mode, sCmdDir, sCmds )"
	code		= xCEDLdErrOut( hnd, mode, sCmdDir, sCmds )
// reactivated  because of U14Ld()  error -544 with script  CCVIGN_MB.txt (456.3s, 18252000pts)
//	code		= xCEDLdErrOut2( mode, sCmdDir, sCmds )

	// printf "\t\tCed CEDInit1401DACADC()  loading commands  '%s'  '%s' \treturns code:%d \r", sCmdDir, sCmds, code
	if ( code  ||  ( mode & MSGLINE ) )
		printf "\t\tCed CEDInit1401DACADC()  loading commands  '%s'  '%s' \treturns code:%d \r", sCmdDir, sCmds, code
	endif 
	if ( code )
		return	code
	endif

	// To be sure, occasionally there were some problems with strange values on DACs 
	sBuf		= "DAC,0 1 2 3,0 0 0 0;" 
	code	= stCEDSendStringCheckErrors( hnd, sBuf , 0 ) 
	if ( code  ||  ( mode & MSGLINE ) )
		printf "\t\tCed CEDInit1401DACADC()  sending %s \treturns code:%d \r", pd( sBuf,18), code
	endif
	if ( code )
		return	code
	endif
	return	code
End


static Function		stCedSetEvent( sFolder, hnd, bMode )
	string  	sFolder
	variable	hnd, bMode
	nvar		raTrigMode	= $ksROOTUF_+sFolder+":dlg:raTrigMode"
	variable	code			= 0
	variable	nCedType		= stCEDType( hnd, bMode )	
	string		sBuf

	// sBuf		= "EVENT,P,63;"							// 63 : set polarity of events 0 ...5 to  low active  (normal setting)
	// code		+= CEDSendStringCheckErrors( sBuf, 1 ) 
	if ( raTrigMode == 0  ) 									// normal SW triggered mode,  see p.48, 53 of the 1995 family programming manual for an example how to handle dig outputs and events 
		sBuf		= "DIGTIM,OB;"							// use  'B'oth  digital outputs and internal events
		code		+= stCEDSendStringCheckErrors( hnd, sBuf , 0 ) //1 ) 
		sBuf		= "EVENT,D,28;"							// 'D'isable external events 2, 3 and 4;   4 + 8 + 16 = 28  i.e. trigger only on internal clock, but not on external signal on E input
		code		+= stCEDSendStringCheckErrors( hnd, sBuf, 0 )//1 ) 
	endif	

	if ( raTrigMode == 1 ) 										// HW E3E4 triggered mode
		printf "\t\tIn this mode a  low-going TTL edge on  Events 2,3,4 (1401plus)  or on Trigger input (Power1401)  will trigger stimulus and acquisition. \r" 

		sBuf		= "DIGTIM,OD;"							// use  only 'D'igital outputs, do not trigger on internal events
		// printf "\t\tSetEvent( %s , TrigMode:%2d )  '%s' \r",  sFolder, bMode, sBuf  

		// 051208	 HWE3E4 Trigger
		sBuf		= "EVENT,D,4;" 							// 'D'isable external events 2   [ 2^2  = 4 ] , but  allow external trigger on events 3 and  4
		// printf "\t\tSetEvent( %s , TrigMode:%2d )  '%s' \r",  sFolder, bMode, sBuf  
		code		+= stCEDSendStringCheckErrors( hnd, sBuf , 0 )//1 ) 
		if ( nCedType == c1401MICRO  ||  nCedType == c1401POWER )	// only   2=1401micro and  3=1401power (but not 0=1401standard or 1=1401plus)  need this linking command
			sBuf = "EVENT,T,28;"							// Power1401 and micro1401 require explicit linking of E2, E3 and E4 to the front panel 'Trigger' input
			// printf "\t\tSetEvent( %s , TrigMode:%2d )  '%s' \r",  sFolder, bMode, sBuf  
			code	+= stCEDSendStringCheckErrors( hnd, sBuf, 0 )//1 ) 
		endif
	endif	
	return	code
End



static Function  stArmClockStart( SmpInt, nTrigMode, hnd )
	variable	SmpInt, nTrigMode, hnd 
	string		buf , bf 
	string		sMode	= SelectString( nTrigMode , "C", "CG" )	// start stimulus/acquisition right now or wait for low pulse on E2 in HW triggered E3E4 mode 
	variable	rnPre1, rnPre2								// changed in function
	if (  stCEDHandleIsOpen() )
		variable	nrep	= 1								// the true number of repetitions is set in ArmDig
		if ( stSplitIntoFactors( SmpInt, rnPre1, rnPre2 ) )
			return	kERROR							// 031126
		endif
		// divide 1MHz clock by two factors to get basic clock period in us, set clock (with same clock rate as DAC and ADC)  and  start DigOut, DAC and  ADC  OR  wait for low pulse 
		sprintf buf, "DIGTIM,%s,%d,%d,%d;", sMode, rnPre1, rnPre2, nrep
		sprintf  bf,  "\t\tCed ArmClockStart sends  '%s'  \r", buf; Out1( bf, 0 )
printf "\t%s", bf
		// 031124 PROBLEM:  EVEN IF too ambitious sample rates are attempted the CED will  FIRST  start  the stimulus/acquisition and  THEN LATER  return an error code and an error dialog box.
		// -> starting the stimulus/acquisition cannot be avoided  no matter whether the user acknowledges the error dialog box or not  leading almost inevitably to corrupted data.
		// -> TODO   the stimulus/acquisition should NOT start in the error case .    STOPADDA   BEFORE   the error dialog opens.... 
		if ( stCEDSendStringCheckErrors( hnd, buf, 0 ) ) 
			return	kERROR						// 031016
		endif
	endif
	return	0
End


static Function  stArmDAC( sFolder, BufStart, BufPts, nrep, hnd )
//	wave  	wG
//	wave  /T	wIO
	string  	sFolder
	variable	BufStart, BufPts, nrep, hnd
	wave 	wG			= $ksROOTUF_ + sFolder + ":keep:wG"	  		// This  'wG'  	is valid in FPulse ( Acquisition )
	wave  /T	wIO			= $ksROOTUF_ + sFolder + ":ar:wIO"  					// This  'wIO'	is valid in FPulse ( Acquisition )

	string		buf, bf
	variable	nSmpInt	= wG[ kSI ]
	variable	nCntDA	= wG[ kCNTDA ]	
	variable	rnPre1, rnPre2							// changed in function
	if (  stCEDHandleIsOpen() )
		if (  nCntDA )
			if ( stSplitIntoFactors( nSmpInt, rnPre1, rnPre2 ) )
				return	kERROR							// 031126
			endif
			//string	sChans = ChannelList_( "Dac", nCntDA )	//? depends on ordering..
			string		sChans = ChannelList_( wIO, kIO_DAC, nCntDA )	//? depends on ordering..
			// Load the DAC with clock setup: 'I'nterrupt mode, 2 byte, from gDACOffset BufSize bytes, 
			// DAC2, nRepeats, 'C'lock 1 MHz/'T'riggered mode, and two factors for clock multiplier 
			// after sending this command to the Ced the DAC will be waiting for a trigger to Event input E3 
			sprintf  buf, "MEMDAC,I,2,%d,%d,%s,%d,CT,%d,%d;", BufStart, BufPts * 2, sChans, nrep, rnPre1, rnPre2
			sprintf  bf,  "\t\tCed ArmDAC  sends  '%s'  \r", buf; Out1( bf, 0 )
printf "\t%s", bf

			if ( stCEDSendStringCheckErrors( hnd, buf, 0 ) )			// now DAC is waiting for a trigger to Event input E3 
				return	kERROR					// 031016
			endif

		endif
	endif
	return 0
End


static Function  stArmADC(  sFolder, BufStart, BufPts, nrep, hnd )
//	wave	wG
//	wave  /T	wIO
	string  	sFolder
	variable	BufStart, BufPts, nrep, hnd
	wave 	wG			= $ksROOTUF_ + sFolder + ":keep:wG"	  		// This  'wG'  	is valid in FPulse ( Acquisition )
	wave  /T	wIO			= $ksROOTUF_ + sFolder + ":ar:wIO"  					// This  'wIO'	is valid in FPulse ( Acquisition )
	string		buf, bf
	variable	nSmpInt		= wG[ kSI ]
	variable	rnPre1, rnPre2							// changed in function
	if ( stCEDHandleIsOpen() )
		string  	listADTG	= stMakeListADTG( wIO )
		variable	nAdcChs 	= ItemsInList( listADTG, " " )	// lstAD + lstTG
		if ( nAdcChs )
			// load the ADC  :   using  'ADCBST'  we get 'SmpInt' between each burst  ( using  'ADCMEM' we get 'SmpInt' between each channel and have to adjust it)
			// parameters:  'I'nterrupt mode, 2 byte, from 'gADCOffset' 'BufSize' bytes,  ADC0 ,  1 repeat,  Clock 1 MHz / 'T'riggered mode, and two factors for clock multiplier 
			// after sending this string to the Ced  the ADC will be  waiting for a trigger to Event input E4 
			variable	nCedType	= stCedType( hnd, 0 )

// 040325  Using ADCMEM rather than ADCBST decreases the minimum sampling interval from  18..20   to 12 us  when using  the 1401 plus with  1 DA, 1 AD and 1 TG channel.
			if ( nCedType == c1401STANDARD ) 							// 040202

				if ( stSplitIntoFactors( nSmpInt / nAdcChs, rnPre1, rnPre2 ) )
					return	kERROR								// 031126
				endif
				// SplitIntoFactors() will already alert about this error........
				//if ( nSmpInt / nAdcChans != trunc( nSmpInt / nAdcChans ) )
				//	Alert( kERR_IMPORTANT, "Sample interval of " + num2str( nSmpInt ) + " could not be divided without remainder through " + num2str( nAdcChans ) + " channels." )
				//endif
				sprintf buf, "ADCMEM,I,2,%d,%d,%s,%d,CT,%d,%d;", BufStart, BufPts * 2, listADTG, nrep, rnPre1, rnPre2
			else
				if ( stSplitIntoFactors( nSmpInt, rnPre1, rnPre2 ) )
					return	kERROR								// 031126
				endif
				sprintf buf, "ADCBST,I,2,%d,%d,%s,%d,CT,%d,%d;", BufStart, BufPts * 2, listADTG, nrep, rnPre1, rnPre2
			endif
			sprintf  bf, "\t\tCed ArmADC   sends  '%s'    ( nAdcChans: %d , CedType: '%s' )\r", buf, nAdcChs, StringFromList( nCedType + 1, sCEDTYPES )
printf "\t%s", bf
			Out1( bf, 0 ) // 1 )
			if ( stCEDSendStringCheckErrors( hnd, buf, 0 ) )						// now ADC is waiting for a trigger to Event input E4 
				return	kERROR						
			endif
		endif
	endif
	return 0
End

static Function  /S	stMakeListADTG( wIO )
	wave  /T	wIO
	variable	Chan, TGChan
	string  	lstAD = "", lstTG = ""
	variable	nIO		= kIO_ADC
	variable	c, cCnt	= ioUse( wIO, nIO )
	for ( c = 0; c < cCnt; c += 1 )
		Chan		= iov( wIO, nIO, c, cIOCHAN ) 
		if (  HasTG( wIO, nIO, c ) )
			TGChan	= iov( wIO, nIO, c, cIOTGCH ) 
			lstTG	= AddListItem( num2str( TGChan ), lstTG, " ", Inf )			// use space as separator so that CED can use this string in 'ADCBST' and 'ADCMEM' directly
		endif
		lstAD	= AddListItem( num2str( Chan ), lstAD, " ", Inf )				// use space as separator so that CED can use this string in 'ADCBST' directly
	endfor
	// printf "\t\tMakeListADTG( wIO ) -> '%s' \r", lstAD + lstTG
	return	lstAD + lstTG
End


static Function	stSplitIntoFactors( nNumber, rnFactor1, rnFactor2 )
	variable	nNumber, &rnFactor1, &rnFactor2 					// changed in function
	string		bf
	rnFactor1	= FindNextDividerBetween( nNumber, 2, min( nNumber / 2, 65535 ) )	// As 2 is the minimum value for ADCBST( 1401plus ) , MEMDAC( 1401plus ) , DIGTIM( 1401plus and Power1401 )...
	rnFactor2	= nNumber / rnFactor1									// ..it makes no sense to handle (theoretically possible) minimum of 1 for ADCBST +  MEMDAC( Power1401 ) separately
	if ( rnFactor1 == kNOTFOUND   ||   trunc( rnFactor1 ) * trunc( rnFactor2 )  != nNumber )
		sprintf bf, "Sample interval of %g could not be divided into 2 integer factors between 2 and 65535. ", nNumber 
		Alert( kERR_FATAL, bf )
		return	kERROR							// 031126
	endif
	return	0
End


//	procedure ArmDig(Dig : DigType; NrOfDigPulses : Integer);
//	   ............
//	    { bit 8 and 9 can be used for external triggering }
//	    { bit 10 .. 12 used for internal triggering (events) }
//	    WriteLn(COut, 'DIGTIM,S,', IntToStr(DigOffset), ',320'); { book space for 20 slices, *16 }
//	
//	    WriteLn(COut, 'DIGTIM,A,28,28,10'); { set event 3 and 4 to high for 10 time units }
//	    WriteLn(COut, 'DIGTIM,A,31,0,10');  { set back to low for 10 time units }
//	    { this is for triggering DAC, ADC, and timer2 }
//	    WriteLn(COut, 'DIGTIM,A,3,', IntToStr(Dig.Out[1]), ',', IntToStr(Dig.Tim[1]-20));
//	    for i := 2 to NrOfDigPulses do begin
//	      WriteLn(COut, 'DIGTIM,A,3,', IntToStr(Dig.Out[i]), ',', IntToStr(Dig.Tim[i]-Dig.Tim[i-1]));
//	      { set digital outputs specified }
//	    end;
//	    { now digital outputs are waiting for a trigger to Event input E2 }
//	  end;                                                { of procedure ArmDig }


static Function  	stArmDig( sFolder, OffsDO, hnd )
	string  	sFolder
//	wave	wG
	variable	OffsDO, hnd
	wave 	wG			= $ksROOTUF_ + sFolder + ":keep:wG"	  		// This  'wG'  	is valid in FPulse ( Acquisition )

	nvar		gnProts		= $ksROOTUF_ + sFolder + ":keep:gnProts"
	nvar		gnJumpBack	= $ksROOTUF_ + sFolder + ":dig:gnJumpBack"
	svar		gsDigoutSlices	= $ksROOTUF_ + sFolder + ":dig:gsDigoutSlices"
	variable	n, p
	string		sErrorCodes, buf, bf
	if ( stCEDHandleIsOpen() )
		variable	nSlices = ItemsInList( gsDigoutSlices )	

		stCEDSetAllDigOuts( hnd, 0 )												// 031110  Initialize the digital output ports with 0 : set to LOW
		
		// book space for   'nSlices'  (=all slices contained in 'gsDigoutSlices' ) , each slice needs 16 Bytes 
		sprintf  buf, "DIGTIM,S,%d,%d;", OffsDO, BYTES_PER_SLICE * nSlices
		sprintf bf, "\t\tCed ArmDig     OffsDO:%d,  nSlices:%2d ,  gnProts:%d -> '%s' \r", OffsDO, nSlices, gnProts, buf 
		Out1( bf,  0 ) // 1 )
printf "\t%s", bf

		if ( stCEDSendStringCheckErrors( hnd, buf, 0 ) ) //1 ) )		
			return	kERROR						
		endif


		for ( n = 0; n < nSlices - 1 ; n +=1 )						// do not yet send the last slice because we must append the number of repeats 					
			 // printf "\t\tSl:%2d/%2d  %s\t'%s.... \r", n, nSlices, pd( StringFromList( n, gsDigoutSlices ), 18), gsDigoutSlices[0,200] 
			//xCEDSendStringErrOut( ERRLINE+cERR_FROM_CED, StringFromList( n, gsDigoutSlices ) + ";" ) // each slice needs appr. 260 us to be sent 
			stCEDSendStringCheckErrors( hnd, StringFromList( n, gsDigoutSlices ) + ";" ,  0 ) // 1  ) // each slice needs appr. 260 us to be sent 
		endfor

		string		sLastSlice	= StringFromList( nSlices - 1 , gsDigoutSlices ) +  "," + num2str( -nSlices + gnJumpBack ) + "," + num2str( gnProts )   // 030627 do NOT repeat DAC/DAC-Trigger (skip first 2 slices)
		sprintf bf, "\t\tCed ArmDig     Prot:%2d/%2d   \tSlice:%2d/%2d  \tLastSlice \tcontaining   jmp and rpt :'%s'    (JumpBack:%d)  \r", p, gnProts, n, nSlices, sLastSlice, gnJumpBack
		Out1( bf , 0 )
printf "\t%s", bf

		if ( stCEDSendStringCheckErrors( hnd, sLastSlice  + ";" ,  0 ) ) // 1 ) )	// sends last DIGTIM,A...	
			return	kERROR						
		endif

		sprintf  bf, "\t\tCed ArmDig     has sent %d  digout slices. Digital transitions OK.\r", nSlices ; Out1( bf, 0 ) //  1)
	//StopTimer( "ArmDig" )
printf "\t%s", bf
	endif
	return 0
End

static Function	stCEDSendStringCheckErrors( hnd, buf, bPrintIt )
	string		buf
	variable	hnd, bPrintIt
	if ( bPrintIt )
		printf "\tCEDSendStringCheckErrors( %s ) \r", buf 
	endif
	xCEDSendString( hnd, buf )
	variable	err	= xCEDGetResponse( hnd, "ERR;", buf, 0 )	// last param is 'ErrMode' : display messages or errors
	if ( err )
		string	   bf
		sprintf  bf,  "err1: %d  err2: %d   after sending   '%s'   (%d) ",  trunc( err / 256 ) , mod( err, 256 ), buf , err 
		Alert( kERR_FATAL,  bf )
		err	= kERROR					
	endif
	return	err
End

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//    DIGITAL  OUTPUT  FUNCTIONS
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// 030707	Notes regarding the digital output pulses
// Goals:
// 1. There should be no lag (apart from the inevitable 1.6us) between digital output and Dac output  (and both should of course be displayed equally exactly in the stimulus display)  	
// 2. Dac must always start at time zero, digital output should also be allowed to start at time zero
// 3. There should be a (preferably positive) trigger pulse with its rising or (preferably) falling edge at time zero   
// Accomplished:
// 1. OK
// 2. Dac does always start at time zero, but for the digital output this is not possible because of 2 Ced1401 limitations:
//	the minimum time slice duration is 2  AND  there is a digital to dac output lag of 1 time slice -> the first digital output pulse cannot start earlier than time zero + 2 time slices
//	( this limitation can perhaps be loosened by using very short time slices  or  by using a dac interval length which is not equal to the digital output time slice )
// 3. Cannot output any edge at time zero (see 2.)  but can output a positive pulse entirely before time zero (see 3.)
// Ideas:
// 5. A programmed pulse can start at t0+1time slice by combining the 2. and 3. slice. This leads to complications when multiple protocols jump back because the initialization slices are no longer clearly separated.
// 6. Make the digital time slice half as long as the Dac interval: This avoids the limitation that digital time slices must be a minimum of 2 Dac intervals. (But resulting time may be too short for Ced, limit is 10..15us?)
// 7. Design issue: there is no default trigger pulse issued just once on digital output 2 because this would  block output 2 (it could no longer be SAFELY used as there would be a mixup between the 1 automatic and the n  user pulses).
//	Instead digital output 2 is free to be programmed by the user. (The pulse will repeat every frame.)  Advantage: this channel and all others can start at time slice -1 (=1 sample interval before t0 which is very useful for triggering.

// For testing use script  'DemoDigout1401Types.txt'

// 030627..030707
// CAVE : cTIME_DAC_TRIGGER  MUST  BE  <  cCEDMAXSLICELEN + 2    ( just to keep the program simple it is assumed that the first slice (=DAC_TRIGGER_SLICE) needs NO DIGTIM branches )
static constant	cCEDMAXSLICELEN		 = 65532	//65532 , actually 65535 but we must leave space for the extra 2 sample intervals added in the last slice 
static constant	cTIME_DAC_TRIGGER	 = 2		// this number of time slices (at least 2) at start of stimulus trigger the Adc and DAC (=Event3,4). 
										// the begin of this pulse (at -1 SI) starts the protocol ->  Pulse should be as short as Ced allows :  2 , it could in principle  be as long as protocol, but this makes no sense
static constant	cTIME_DAC_TO_DIGOUT = 1		// this is exactly 1 time slice and compensates the Dac lagging the digout
static constant	BYTES_PER_SLICE		 = 16

// 2010-03-29  Increased MAXDIGOUT from 2000 to 10000
//static constant	MAXDIGOUT 		 = 2000
static constant	MAXDIGOUT 			 = 10000

//!  THIS  FUNCTION  DETERMINES  THE  ORDER  OF  THE  ENTRIES  IN  THE  SCRIPT
static constant	DOCHA = 0, DODUR = 1, DODEL = 2, DODDUR = 3, DODDEL = 4, DOBEG = 5, DOSIZE = 6	// order of entries in script
  
Function		ProcessDigitalOutputs( sFolder, wG, wVal, wFix, wEinCB, wELine, wE, wBFS, nEle )
	string  	sFolder
	wave  /T	wVal
	wave	wG, wFix, wEinCB, wELine, wE, wBFS
	variable	nEle
	variable	nPnts	= wG[ kPNTS ] 
	variable	nCode	= kOK
	//ResetStartTimer( "Digout" )
	DigoutExtractChs( sFolder, wG, wVal, wFix, wEinCB, wELine, wE, wBFS, nEle )				
	DigoutExpandFramesIncDec( sFolder, wG, wFix, wEinCB, wE, wBFS )				
	nCode += DigoutMakeDisplayWaves( sFolder, wG, wFix, wEinCB, wE, wBFS, nPnts )			
	nCode += stDigoutMakeCEDString( 	sFolder, wG, wFix, wEinCB, wE, wBFS, nPnts )				
	//StopTimer(  "Digout" )
	return	nCode
End


Function	/S	InsertAdcDacDigoutTrigger( wG, sDigout )
// This inserts the Adc/Dac-trigger pulse into the stimulus protocol. These are the 'hidden digital events 3 and 4' which trigger the Adc/Dac/Digout pulses
// this is called twice
	wave	wG
	string		sDigout
	variable	nSmpInt			= wG[ kSI ]
	string		sAdcDacDigoutTrigger
	variable	TriggerDuration	= cTIME_DAC_TRIGGER * nSmpInt / kMILLITOMICRO
	// Version 1 :  insert only Event 3 and 4 = Adc/Dac-trigger pulse : insert  "4,1/3,1/" 
	sprintf	sAdcDacDigoutTrigger, "%d,%lf/%d,%lf/", 4, TriggerDuration, 3, TriggerDuration		// Assumption:separators  ','  and  '/'
	// Version 2 :  insert Event 3 and 4 and additionally automatic digout 2 pulse  (not very useful, can better be inserted in  script)
	// sAdcDacDigoutTrigger = "4,1/3,1/2,1/"	// insert Event 3 and 4 and additionally automatic digout 2 pulse
	return	sAdcDacDigoutTrigger + sDigout
End


Function  		DigoutExtractChs( sFolder, wG, wVal, wFix, wEinCB, wELine, wE, wBFS, nEle )
	string  	sFolder
	wave  /T	wVal
	wave	wG, wFix, wEinCB, wELine, wE, wBFS
	variable	nEle 
	nvar		gRadDebgSel	= root:uf:dlg:gRadDebgSel
	nvar		PnDebgDigout	= root:uf:dlg:Debg:Digout
	svar		gsDigOutChans	= 	$ksROOTUF_ + sFolder + ":dig:gsDigOutChans"
	gsDigOutChans	= ""
	string		bf, sDigOut, sOneChInLine, sCh//, sDgoChans	= ""
	variable	c = 0, b, f, e, k, nType, ciDgo, nChansInThisLine, nIdxDGO
	//  Step1: count  and get channel number of all DigOuts from  'wEl', build list of used digout channels 'sDgoChans'
	for ( b  = 0; b < eBlocks( wG ); b += 1 )
		for ( f = 0; f < eFrames( wFix, b ); f += 1 )							// loop through all frames above frame 0, whose values are fixed
			for ( e = 0; e < eElems( wEinCB, c, b ); e += 1 )						// loop through all elements (=VarSegm,Segment,Ramp,StimWave..)
				nType = eTyp( wE, wBFS, c, b, e )
				sDigout	=  vGES( wVal, wELine, c, b, f, e, "Dig" )

				if ( numType( str2num( sDigout ) ) == kNUMTYPE_NAN )	// 040121 Dig subkey was missing: convert Nan to empty string so that Nan is not counted as 1 digout channel
					sDigout = ""
				endif
				
				if ( b==0  &&  f ==0  &&  e == 0 ) 	
					sDigout	= InsertAdcDacDigoutTrigger( wG, sDigout )	// This inserts the 'hidden digital events 3 and 4' which trigger the Adc/Dac/Digout pulses
				endif											// they are inserted here erroneously in every sweep: we must later remove all inserts but the last   
	
				if ( numType( str2num( sDigout ) ) != kNUMTYPE_NAN )		// Dig subkey was missing in script: skip  ( Empty string  is a Nan just like string 'Nan' )
	
					nChansInThisLine	= ItemsInList( sDigout, "/" )			//! assumption  separator 
					for ( ciDgo = 0; ciDgo < nChansInThisLine; ciDgo += 1 )
						sOneChInLine	= StringFromList( ciDgo, sDigout, "/" )	//! assumption  separator 
						sCh			= StringFromList( 0,  sOneChInLine, "," )			
						if ( WhichListItem(  sCh, gsDigOutChans ) == kNOTFOUND )
							gsDigOutChans	= AddListItem( sCh, gsDigOutChans, ";", Inf )
						endif
						 if ( gRadDebgSel > 1  &&  PnDebgDigout )
							printf  "\t\t\tDigoutExtractChs(1.) \t%-12s\tb:%2d\tf:%2d\te:%2d\tc:%d \tsCh:'%s'     \tsDGOChList:'%s'   \tsChInLine:'%s' \tsDigOut:%s \t  \r", mS( nType ), b, f, e, ciDgo, sCh, gsDigOutChans, sOneChInLine, sDigOut
						 endif
					endfor
				endif
			endfor
		endfor
	endfor
//	if (  1|| gRadDebgSel > 1  &&  PnDebgDigout )
		printf "\t\t\tDigoutExtractChs(1.)  has built  sDgoChans:'%s'  containing %d  Digout channels \r", gsDigOutChans, ItemsInList( gsDigOutChans )
//	endif

	//  Step2: build array 'wDGO'  to hold  digout numbers (needed because inc / dec computations are more easily done in an array than in a string list)
	variable	nDGOChans	= ItemsInList( gsDigOutChans )
	make	/O 	/N=( nDGOChans, eMaxBFS( wE ),  nEle, DOSIZE ) $ksROOTUF_ + sFolder + ":stim:wDGO" = Nan	// Nan is marker for non-filled elements
	// print "050128 make      \twDGO ",  nDGOChans, eMaxBFS( wE ),  nEle, DOSIZE, "->", nDGOChans * eMaxBFS( wE ) *  nEle * DOSIZE 

	wave	wDGO									=   $ksROOTUF_ + sFolder + ":stim:wDGO"
//	if (  1|| gRadDebgSel > 1  &&  PnDebgDigout )
		printf "\t\t\tExtractDigoutChs(2.)  has built  wDGO[ DGOch:%d ][ maxBFS: %d ][ nEle:%d ][ DGOkeys:%d ] \r",  nDGOChans, eMaxBFS( wE ), nEle, DOSIZE
//	endif

	//  Step3: extract numbers of all DigOuts from  'wEl'  and store them in 'wDGO'
	variable	value
	variable	bfsPtr		
	for ( b  = 0; b < eBlocks( wG ); b += 1 )
		for ( f = 0; f < eFrames( wFix, b ); f += 1 )							// loop through all frames above frame 0, whose values are fixed
			bfsPtr	= eGetBFSPtr( wBFS, b, f, 0 )						// only information of sweep 0 is used for construction of the DigOut wave  
			for ( e = 0; e < eElems( wEinCB, c, b ); e += 1 )						// loop through all elements (=VarSegm,Segment,Ramp,StimWave..)
				nType	= eTyp( wE, wBFS, c, b, e )
				sDigout	=  vGES( wVal, wELine, c, b, f, e, "Dig" )

				if ( numType( str2num( sDigout ) ) == kNUMTYPE_NAN )	// 040121 Dig subkey was missing: convert Nan to empty string so that Nan is not counted as 1 digout channel
					sDigout = ""
				endif

				if ( b==0 && f ==0  && e == 0 ) 	
					sDigout	= InsertAdcDacDigoutTrigger( wG, sDigout )	// This inserts the 'hidden digital events 3 and 4' which trigger the Adc/Dac/Digout pulses
				endif											// they are inserted here erroneously in every sweep: we must later remove all inserts but the last   
				
				if ( numType( str2num( sDigout ) ) != kNUMTYPE_NAN )		// Dig subkey was missing in script: skip  ( Empty string  is a Nan just like string 'Nan' )
					nChansInThisLine	= ItemsInList( sDigout, "/" )			//! assumption  separator 
					for ( ciDgo = 0; ciDgo < nChansInThisLine; ciDgo += 1 )
						sOneChInLine= StringFromList( ciDgo, sDigout, "/" )	//! assumption  separator 
						sCh		= StringFromList( 0,  sOneChInLine, "," )	// first list item in script is true channel number
						nIdxDGO	= WhichListItem( sCh, gsDigOutChans )		// the order of channels in channel list determines order in wDGO, first item in wDGO is true chan number 
						for ( k = 0; k < dimSize( wDGO, 3 ); k += 1)
							value	= str2num( StringFromList( k,  sOneChInLine, "," ) )
							if ( k != DOCHA   &&  numtype( value ) == kNUMTYPE_NAN )	
								value = 0							// keep Nan as marker for missing channels... 
							endif									// ..but set missing durations and delays to zero
							wDGO[ nIdxDGO ][ bfsPtr ][ e ][ k ]	= value
						endfor
						// check the numbers stored in 'wDGO'
						string		sNumbers = ""
						for ( k = 0; k < dimSize( wDGO, 3 ); k += 1)
							sNumbers += "\t" + num2str( wDGO[ nIdxDGO ][ bfsPtr ][ e ][ k ] )
						endfor
						if (  gRadDebgSel > 1  &&  PnDebgDigout )
							printf  "\t\t\tDigoutExtractChs(3.) \t%-12s\tb:%2d\tf:%2d\tff:%2d\te:%2d\tc:%d \t\tchecking wDGO:'%s' \t\tsChInLine:'%s' \r", mS( nType ), b, f, bfsPtr, e, ciDgo, sNumbers, sOneChInLine 
						endif
					endfor
				endif
			endfor
		endfor
	endfor
	//gsDigOutChans	= sDgoChans
//	if (  1|| gRadDebgSel > 0  &&  PnDebgDigout )
		printf "\t\tDigoutExtractChs(4.)  has built  sDgoChans:'%s'  containing %d  Digout channels \r", gsDigOutChans, ItemsInList( gsDigOutChans ) 
//	endif
End


Function 		DigoutExpandFramesIncDec( sFolder, wG, wFix, wEinCB, wE, wBFS )
// Step 6:  take into account the DAmp and DDur entries: increment or decrement frames >= 1
//	only sweep 0 is set, sweeps >= 1 are still empty
	string  	sFolder
	wave	wG, wFix, wEinCB, wE, wBFS
	nvar		gRadDebgSel	= root:uf:dlg:gRadDebgSel
	nvar		PnDebgDigout	= root:uf:dlg:Debg:Digout
	variable	b=0, f=0, e, value, nType 
//	if (  1|| gRadDebgSel > 0  &&  PnDebgDigout )
		printf "\t\tDigoutExpandFramesIncDec(10.) \t wE[ nChn:%d  maxBFS:%d , nEle:%d, nKeys:%d]   (maxFrm:%d, maxSwp:%d )\r", eChans( wE ), eMaxBFS( wE ), eMaxElems( wE ), eKeys( wE ), eMaxFrames( wG, wFix ), eMaxSweeps( wG, wFix )
//	endif

	wave	wDGO		=   $ksROOTUF_ + sFolder + ":stim:wDGO"
	variable	k, c = 0, ciDgo, nDgoChs = dimsize( wDGO, 0 )
	for ( ciDgo = 0; ciDgo < nDgoChs; ciDgo += 1)
		if (  gRadDebgSel > 2  &&  PnDebgDigout )
			 printf "\t\t\t\tDigoutExtractChs(11a.) Check inc/dec wDGO  before\tciDgo:%2d   \tchan:%2d  \tdur:%5.3lf \r", ciDgo, wDGO[ ciDgo ][ 0  ][ 0 ][ DOCHA ], wDGO[ ciDgo ][ 0  ][ 0 ][ DODUR ]
		endif			
		for ( b  = 0; b < eBlocks( wG ); b += 1 )
			for ( f = 0; f < eFrames( wFix, b ); f += 1 )			
				variable	bfsPtr	= eGetBFSPtr( wBFS, b, f, 0 )			// only information of sweep 0 is used for construction of the DigOut wave  
				for ( e = 0; e < eElems( wEinCB, c, b ); e += 1 )					// loop through all elements (=VarSegm,Segment,Ramp,StimWave..)
				
//						// Commentize the following 7 lines in the release version :
//						if ( gRadDebgSel > 3  &&  PnDebgDigout )
//							 string 	sNumBers = ""
//							 string 	sNewNumBers = ""
//							 for ( k = 0; k <  dimsize( wDGO, 3 ); k += 1 )
//								sNumbers += "\t\t" + num2str( wDGO[ ciDgo ][ bfsPtr ][ e ][ k ] )
//							 endfor		
//						endif	 
	
					if ( numtype(  wDGO[ ciDgo ][ bfsPtr ][ e ][ DOCHA ] )  !=  kNUMTYPE_NAN )							// true channel number 
						wDGO[ ciDgo ][ bfsPtr  ][ e ][ DODEL ]	   = wDGO[ ciDgo ][ bfsPtr ][ e ][ DODEL ]  +  f *  wDGO[ ciDgo ][ bfsPtr ][ e ][ DODDEL ]	// increment Delay
						wDGO[ ciDgo ][ bfsPtr  ][ e ][ DODUR ]  = wDGO[ ciDgo ][ bfsPtr ][ e ][ DODUR ] +  f *  wDGO[ ciDgo ][ bfsPtr ][ e ][ DODDUR ]	// increment Duration
					endif			
//						// Commentize the following 6 lines in the release version
//						if ( gRadDebgSel > 3  &&  PnDebgDigout )
//							 for ( k = 0; k <  dimsize( wDGO, 3 ); k += 1 )
//								sNewNumbers += "\t\t" + num2str( wDGO[ ciDgo ][ bfsPtr ][ e ][ k ] )
//							 endfor		
//							 printf "\t\tCheck ++/-- wDGO 11b.\tciDgo:%2d   \tc:%2d  \tb:%2d  \tf:%2d  \tff:%2d  \te:%2d  \t%s ->\t%s \r", ciDgo, c, b, f, bfsPtr, e, sNumbers, sNewNumbers
//						endif			
				endfor		
			endfor		
		endfor		
		if (  gRadDebgSel > 2  &&  PnDebgDigout )
			 printf "\t\t\t\tDigoutExtractChs(11c.) Check inc/dec wDGO  after \tciDgo:%2d   \tchan:%2d  \tdur:%5.3lf \r", ciDgo, wDGO[ ciDgo ][ 0  ][ 0 ][ DOCHA ], wDGO[ ciDgo ][ 0  ][ 0 ][ DODUR ]
		endif			
	endfor
End

Function	 	DigoutMakeDisplayWaves( sFolder, wG, wFix, wEinCB, wE, wBFS, nPnts )
//  build digout display wave,  needs  wEl   and wDGO
//  the control structure  (=the loops) of  'DigoutMakeDisplayWaves'  and  'DigoutMakeCEDString'  must be the same ensuring that digout pulses are actually constructed exactly as displayed on the screen...
	string  	sFolder
	wave	wG, wFix, wEinCB, wE, wBFS
 	variable	nPnts
	nvar		gRadDebgSel	= root:uf:dlg:gRadDebgSel
	nvar		PnDebgDigout	= root:uf:dlg:Debg:Digout
	svar		gsDigOutChans	= $ksROOTUF_ + sFolder + ":dig:gsDigOutChans"
	string		sTxt//, sDgoChans= gsDigOutChans
	wave	wDGO		=   $ksROOTUF_ + sFolder + ":stim:wDGO"
	variable	nSmpInt		= wG[ kSI ]
	variable	ciDgo, nDgoChs = dimSize( wDGO, 0 )	// or: ItemsInList( sDgoChs )
	variable	c, b, f, s, e, BegPt, l, n, nElemCnt = 0
//0412a
//	make  /O /I /N=( MAXDIGOUT ) wDgoCh, wDgoBeg, wDgoDur						// 32bit integer for Dig wave
if (  bCRASH_ON_REDIM_TEST14 )				// 051105   
	make  	/I /N=( MAXDIGOUT ) $ksROOTUF_ + sFolder + ":dig:wDgoCh"   ;	wave  wDgoCh	= $ksROOTUF_ + sFolder + ":dig:wDgoCh"	// 32bit integer for Dig wave
	make  	/I /N=( MAXDIGOUT ) $ksROOTUF_ + sFolder + ":dig:wDgoBeg" ;	wave  wDgoBeg= $ksROOTUF_ + sFolder + ":dig:wDgoBeg"	// 32bit integer for Dig wave
	make  	/I /N=( MAXDIGOUT ) $ksROOTUF_ + sFolder + ":dig:wDgoDur"  ;	wave  wDgoDur	= $ksROOTUF_ + sFolder + ":dig:wDgoDur"	// 32bit integer for Dig wave
else
	make  /O	/I /N=( MAXDIGOUT ) $ksROOTUF_ + sFolder + ":dig:wDgoCh"   =0;wave  wDgoCh	= $ksROOTUF_ + sFolder + ":dig:wDgoCh"	// 32bit integer for Dig wave
	make  /O	/I /N=( MAXDIGOUT ) $ksROOTUF_ + sFolder + ":dig:wDgoBeg" =0;wave  wDgoBeg= $ksROOTUF_ + sFolder + ":dig:wDgoBeg"	// 32bit integer for Dig wave
	make  /O	/I /N=( MAXDIGOUT ) $ksROOTUF_ + sFolder + ":dig:wDgoDur" =0 ;wave  wDgoDur= $ksROOTUF_ + sFolder + ":dig:wDgoDur"	// 32bit integer for Dig wave
	// print "050128 make  /I \twDgoCh, wDgoBeg, wDgoDur", MAXDIGOUT
endif

	// Step 1: General  ->  reads 'BegPt'  and completes wDGO:  BegPoint of Digout  is BegPt of  Dac of current line + Digout Delay 
	for ( b  = 0; b < eBlocks( wG ); b += 1 )
		for ( f = 0; f < eFrames( wFix, b ); f += 1 )				// loop through all frames..
			variable	bfsPtr	= eGetBFSPtr( wBFS, b, f, 0 )	// only information of sweep 0 is used for construction of the DigOut wave  
			for ( s = 0; s < eSweeps( wFix, b ); s += 1 )			// ..through all sweeps..
				for ( e = 0; e < eElems( wEinCB, c, b ); e += 1 )		// ..through all elements (=Segments, Ramp..)
					BegPt = eVL( wE, wBFS, c, b, f, s, e, cBEG ) 		// here also use sweeps >0, check if the current element has a subkey 'BegPt'...
					if ( numtype( BegPt ) != kNUMTYPE_NAN )		//  ..(if this is not checked, empty lines containing no digout information are processed...)	 030513
						for ( ciDgo = 0; ciDgo < nDgoChs; ciDgo += 1)
							variable	nChan	= wDGO[ ciDgo ][ bfsPtr ][ e ][ DOCHA ]
							if ( numtype(  nChan )  !=  kNUMTYPE_NAN )									// true channel number 

								variable	DgoDur	= round( wDGO[ ciDgo ][ bfsPtr ][ e ][ DODUR ] * kMILLITOMICRO / nSmpInt )  
								variable	DgoDel	= round( wDGO[ ciDgo ][ bfsPtr ][ e ][ DODEL  ] * kMILLITOMICRO / nSmpInt )  
								variable	DgoBegPt	= BegPt  +  DgoDel

								wDGO[ ciDgo ][ bfsPtr ][ e ][ DOBEG ] =  DgoBegPt 	// BegPoint of Digout  is BegPt of  Dac of current line + Digout Delay

								// Event 3 and 4 trigger the Adc / Dac : Pass the automatic (=InsertAdcDacDigoutTrigger)  pulse only once in 1.bl, 1.fr, 1.sweep (e==0, must be in 1.line) . 
								if ( ( nChan == 3  ||  nChan == 4 )   &&   ( b == 0  &&  f == 0  &&  s == 0  &&  e == 0 )  )
									nElemCnt = stFillDigDispArrays( "AutoTrig", nSmpInt, nElemCnt, nChan, DgoBegPt-cTIME_DAC_TO_DIGOUT, DgoDur,  f, s, bfsPtr, e, BegPt, DgoDel, wDgoCh, wDgoBeg, wDgoDur )  
								// Event 3 and 4 trigger the Adc / Dac : Pass user pulses in chan 3 and 4 ((e>0, not in 1. line) in every block, frame, sweep
								elseif ( ( nChan == 3  ||  nChan == 4 )   &&     e > 0   )	
									nElemCnt = stFillDigDispArrays( "UserTrig", nSmpInt, nElemCnt, nChan, DgoBegPt, 						DgoDur, f, s, bfsPtr, e, BegPt, DgoDel,  wDgoCh, wDgoBeg, wDgoDur  )  
								// Pass all other channels in every block, frame, sweep
								elseif ( ! ( nChan == 3  ||  nChan == 4 ) )									
									nElemCnt  = stFillDigDispArrays( "normal  ", nSmpInt, nElemCnt,  nChan, DgoBegPt, 						DgoDur, f, s, bfsPtr, e, BegPt, DgoDel,  wDgoCh, wDgoBeg, wDgoDur  )  
								endif			
							endif			
						endfor			
					endif
				endfor
			endfor
		endfor
	endfor

	if ( nElemCnt >= MAXDIGOUT )
		Alert( kERR_FATAL,  "Too many (" + num2str( nElemCnt ) + ") Digouts used, maximum is " + num2str( MAXDIGOUT ) + " . " )
	endif

// 051105   bCRASH_ON_REDIM_TEST14
//	redimension  /I	/N=( nElemCnt ) wDgoDur 					// for  Digout wave for display
//	redimension  /I	/N=( nElemCnt ) wDgoBeg 					// for  Digout wave for display
//	redimension  /I	/N=( nElemCnt ) wDgoCh 					// for  Digout wave for display
	redimension  	/N=( nElemCnt ) wDgoDur, wDgoBeg, wDgoCh	// for  Digout wave for display

	if ( nElemCnt != numPnts( wDgoCh )  ||  nElemCnt != numPnts( wDgoBeg )  ||  nElemCnt != numPnts( wDgoDur ) )
		sprintf sTxt, "DigoutMakeDisplayWaves()  Redimension  should be %d .  Is %d  ?= %d  ?= %d  ", nElemCnt, numPnts( wDgoCh ), numPnts( wDgoBeg ), numPnts( wDgoDur ) 
		InternalError( sTxt )
		return	kERROR
	endif

	// Step 2: Display Digout wave  ->  sort   channel number, duration  and BegPt  by  BegPt
	sort	 wDgoBeg, wDgoBeg, wDgoCh, wDgoDur 
	
	for ( n = 0; n < nElemCnt; n += 1)
		if (  gRadDebgSel > 2  &&  PnDebgDigout )
			printf "\t\t\t\tDigoutMakeDisplayWaves(22.) after sorting Beg \tn:%3d/%3d \tch:%3d \tBeg:%7d \tDur:%7d \r", n, nElemCnt,  wDgoCh[ n ], wDgoBeg[ n ], wDgoDur[ n ]  
		endif
	endfor

	// Step 3:  Display Digout wave  ->  fill  digout waves (only for display in stimulus window) 
	for ( ciDgo = 0; ciDgo< nDgoChs; ciDgo += 1)
		if (  gRadDebgSel > 2  &&  PnDebgDigout )
			printf  "\t\t\t\tDigoutMakeDisplayWaves(23.) \tfilling Digout waves (pts excluding trigger duration :%d)...\tsDgoChs:'%s' \r",  nPnts, gsDigOutChans 
		endif
		make /O /B /N=(  nPnts )  $ksROOTUF_ + sFolder + ":stim:" + DispWaveDgoFull( gsDigOutChans, ciDgo ) =  0// ..for the display of the digital output (BYTE wave)
		// print "050128 make  /B  \t'",  DispWaveDgoFull( gsDigOutChans, ciDgo ) , nPnts
	endfor
	for ( n = 0; n < nElemCnt; n += 1)
		for ( ciDgo = 0; ciDgo < nDgoChs; ciDgo += 1)
			wave	wDOFull	= $( ksROOTUF_ + sFolder + ":stim:" + DispWaveDgoFull( gsDigOutChans, ciDgo ) )
			variable	nDgoCh		=  str2num( StringFromList( ciDgo, gsDigOutChans ) ) 
			if ( wDgoCh[ n ] == nDgoCh )
				// printf  "\t\t\t\tDigoutMakeDisplayWaves(24.) \tfilling Digout waves with 'On' : ch:%2d   slice:%2d  from %6.3lf  to %6.3lf  \r",  wDgoCh[ n ] , n, wDgoBeg[ n ],  wDgoBeg[ n ] + wDgoDur[ n ]
				for ( l = wDgoBeg[ n ]; l < wDgoBeg[ n ] + wDgoDur[ n ];  l += 1)
					wDOFull[  l ] = 1
				endfor	
			endif
		endfor	
	endfor	
if (  bCRASH_ON_REDIM_TEST14 )				// 051105   
	KillWaves wDgoDur, wDgoBeg, wDgoCh
endif
	return	kOK
End	
	

static Function 	stDigoutMakeCEDString( sFolder, wG, wFix, wEinCB, wE, wBFS, nPnts )
//  build  CED-Digout string  'gsDigoutSlices',  needs  wEl   and wDGO
//  the control structure (=the loops) of  'DigoutMakeDisplayWaves'  and  'DigoutMakeCEDString'  must be the same ensuring that digout pulses are actually constructed exactly as displayed on the screen...
	string  	sFolder
	wave	wG, wFix, wEinCB, wE, wBFS
	variable	nPnts
	variable	nSmpInt		= wG[ kSI ]
	nvar		gRadDebgSel 	= root:uf:dlg:gRadDebgSel
	nvar		PnDebgDigout	= root:uf:dlg:Debg:Digout
	nvar		gnJumpBack	=  $ksROOTUF_ + sFolder + ":dig:gnJumpBack"
	svar		gsDigoutSlices	=  $ksROOTUF_ + sFolder + ":dig:gsDigoutSlices"
	string		sTxt
	variable	c = 0, b, f, s, e, BegPt, l, n, nSlices = 0		
	wave	wDGO		=   $ksROOTUF_ + sFolder + ":stim:wDGO"
	variable	ciDgo, nDgoChs = dimSize( wDGO, 0 )	// or: ItemsInList( sDgoChs )
//0412a
//	make  /O /I /N=( MAXDIGOUT ) wDgoTime, wDgoChan, wDgoChange	// integer 32 bit  for Digout CED string
if (  bCRASH_ON_REDIM_TEST14 )				// 051105   
	make   	/I /N=( MAXDIGOUT ) $ksROOTUF_ + sFolder + ":dig:wDgoTime"	;	wave  wDgoTime	= $ksROOTUF_ + sFolder + ":dig:wDgoTime"	// 32bit integer for Dig wave
	make   	/I /N=( MAXDIGOUT ) $ksROOTUF_ + sFolder + ":dig:wDgoChan"	;	wave  wDgoChan	= $ksROOTUF_ + sFolder + ":dig:wDgoChan"	// 32bit integer for Dig wave
	make   	/I /N=( MAXDIGOUT ) $ksROOTUF_ + sFolder + ":dig:wDgoChange" ;	wave  wDgoChange	= $ksROOTUF_ + sFolder + ":dig:wDgoChange"// 32bit integer for Dig wave
else
	make  /O  	/I /N=( MAXDIGOUT ) $ksROOTUF_ + sFolder + ":dig:wDgoTime"	=0;	wave  wDgoTime	= $ksROOTUF_ + sFolder + ":dig:wDgoTime"	// 32bit integer for Dig wave
	make  /O 	/I /N=( MAXDIGOUT ) $ksROOTUF_ + sFolder + ":dig:wDgoChan"	=0;	wave  wDgoChan	= $ksROOTUF_ + sFolder + ":dig:wDgoChan"	// 32bit integer for Dig wave
	make  /O	/I /N=( MAXDIGOUT ) $ksROOTUF_ + sFolder + ":dig:wDgoChange" =0;	wave  wDgoChange	= $ksROOTUF_ + sFolder + ":dig:wDgoChange"// 32bit integer for Dig wave
	// print "050128 make  /I \twDgoTime, wDgoChan, wDgoChange",  MAXDIGOUT
endif
	// Step : CED-DIGTIM-String  ->  The first and last DIGTIM command ( =OuterDIGTIM) need all channels for a proper Set / Reset state
	variable	nAllChans = 0

	// bit 8 and 9 can be used for external triggering,  bit 10 .. 12 are used for internal triggering (events) 
	// Set event  3 and 4 to high for   2  time slices,  then set back to low for same time (2 time slices is shortest pulse allowed by Ced)
	// This is for triggering DAC, ADC, and timer2 

	// Step 1: General  ->  reads 'BegPt'  and completes wDGO:  BegPoint of Digout  is BegPt of  Dac of current line + Digout Delay 
	for ( b  = 0; b < eBlocks( wG ); b += 1 )
		for ( f = 0; f < eFrames( wFix, b ); f += 1 )				// loop through all frames..
			variable	bfsPtr  = eGetBFSPtr( wBFS, b, f, 0 )		// only information of sweep 0 is used for construction of the DigOut wave  
			for ( s = 0; s < eSweeps( wFix, b ); s += 1 )			// ..through all sweeps..
				for ( e = 0; e < eElems( wEinCB, c, b ); e += 1 )		// ..through all elements (=Segments, Ramp..)
					BegPt = eVL( wE, wBFS, c, b, f, s, e, cBEG ) 		// here also use sweeps >0, check if the current element has a subkey 'BegPt'...
					if ( numtype(BegPt)  != kNUMTYPE_NAN )		//  ..(if this is not checked, empty lines containing no digout information are processed...)  030513
						for ( ciDgo = 0; ciDgo < nDgoChs; ciDgo += 1)
							variable	nChan	= wDGO[ ciDgo ][ bfsPtr ][ e ][ DOCHA ]
							if ( numtype(  nChan )  !=  kNUMTYPE_NAN )										// true channel number 

								variable	DgoDur	= wDGO[ ciDgo ][ bfsPtr ][ e ][ DODUR ] * kMILLITOMICRO / nSmpInt  
								variable	DgoDel	= wDGO[ ciDgo ][ bfsPtr ][ e ][ DODEL  ] * kMILLITOMICRO / nSmpInt   
								variable	DgoBegPt	= BegPt  +  DgoDel 

								wDGO[ ciDgo ][ bfsPtr ][ e ][ DOBEG ] =  DgoBegPt 	// BegPoint of Digout  is BegPt of  Dac of current line + Digout Delay
								// This handles the 'hidden digout events 3 and 4'  which trigger the Adc/Dac/Digout
								//  to compensate for the delay until the digital output pulse is actually output  all slices except for the first are shifted 'cTIME_DAC_TO_DIGOUT' slices to later times
								// the criterion ' b == 0  &&  f == 0  &&  s == 0  &&  e == 0'  is not exactly what we want: we mean the hidden event but also act on user programmed events in the same (1.) line
								// -> the user MUST NOT program pulses on channel 3 or 4 in the first line, but must use the second line and a negative delay instead
								// Event 3 and 4 trigger the Adc / Dac : Pass the automatic (=InsertAdcDacDigoutTrigger)  pulse only once in 1.bl, 1.fr, 1.sweep (e==0, must be in 1.line) . 
								if ( ( nChan == 3  ||  nChan == 4 )   &&   ( b == 0  &&  f == 0  &&  s == 0  &&  e == 0 )  )
									nSlices  = stFillDigTimArrays( "AutoTrig", nSmpInt, nSlices, nChan, DgoBegPt, 					   DgoDur, f, s, bfsPtr, e, BegPt, DgoDel, nPnts,wDgoTime, wDgoChan, wDgoChange )  
								// Event 3 and 4 trigger the Adc / Dac : Pass user pulses in chan 3 and 4 ((e>0, not in 1. line) in every block, frame, sweep
								elseif ( ( nChan == 3  ||  nChan == 4 )   &&     e > 0   )	
									nSlices  = stFillDigTimArrays( "UserTrig", nSmpInt, nSlices, nChan, DgoBegPt + cTIME_DAC_TO_DIGOUT, DgoDur, f, s, bfsPtr, e, BegPt, DgoDel, nPnts, wDgoTime, wDgoChan, wDgoChange )  
								elseif ( ! ( nChan == 3  ||  nChan == 4 ) )									// Pass all other channels in every block, frame, sweep
									nSlices  = stFillDigTimArrays( "normal   ", nSmpInt, nSlices, nChan, DgoBegPt + cTIME_DAC_TO_DIGOUT, DgoDur, f, s, bfsPtr, e, BegPt, DgoDel, nPnts, wDgoTime, wDgoChan, wDgoChange )  
								endif			
							endif			
						endfor		// ciDgo	
					endif
				endfor		// elems
			endfor		// sweeps
		endfor		// frames
	endfor		// blks

	// the last interval from end of last digout pulse to end of last sweep of last frame 
	wDgoTime[ nSlices ]	= nPnts		
	wDgoChan[ nSlices ]	= nAllChans
	nSlices += 1

	if ( nSlices >= MAXDIGOUT )
		Alert( kERR_FATAL,  "Too many (" + num2str( nSlices ) + ") Digouts used, maximum is " + num2str( MAXDIGOUT ) + " . " )
	endif
	
// bCRASH_ON_REDIM_TEST14				// 051105   
//	redimension	/N=( nSlices ) wDgoChange 								// for CED DIGTIM string
//	redimension	/N=( nSlices ) wDgoChan			 						// for CED DIGTIM string
//	redimension	/N=( nSlices ) wDgoTime
	redimension	/N=( nSlices ) wDgoTime, wDgoChan, wDgoChange 				// for CED DIGTIM string
	// print "050128 redim     \twDgoTime, wDgoChan, wDgoChange",  nSlices
	
	if ( nSlices != numPnts( wDgoTime )  ||  nSlices != numPnts( wDgoChan )  ||  nSlices != numPnts( wDgoChange ) )
		sprintf sTxt, "DigoutMakeCEDString    Redimension  should be %d .  Is %d  ?= %d  ?= %d  ", nSlices, numPnts( wDgoTime ), numPnts( wDgoChan ), numPnts( wDgoChange ) 
		InternalError( sTxt )
		return 	kERROR
	endif

	// Step : CED-DIGTIM-String  ->  sort  wDgoChange(=channel number + changing state)  and wDgoTime (=Beg or end)  by   wDgoTime
	sort	 wDgoTime, wDgoTime, wDgoChan, wDgoChange 
	for ( n = 0; n < nSlices; n += 1)
		if (  gRadDebgSel > 2  &&  PnDebgDigout )
			printf "\t\t\t\tDigoutMakeCEDString 34   after sorting Time (=Beg or End) \t n:%3d/%3d \tTime:%7d \tChan:%7d \tChange:%7d \r", n, nSlices,  wDgoTime[ n ], wDgoChan[ n ], wDgoChange[ n ] 
		endif
			// printf "\t\t\t\tDigoutMakeCEDString 34   after sorting Time (=Beg or End) \t n:%3d/%3d \tTime:%7d \tChan:%7d \tChange:%7d \r", n, nSlices,  wDgoTime[ n ], wDgoChan[ n ], wDgoChange[ n ] 
	endfor

	// Step : CED-DIGTIM-String  ->  combine identical times into 1 slice
	variable	nn
	for ( n = 0; n < nSlices; n += 1)
		if ( n > 0  &&   wDgoTime[ n ]  ==  wDgoTime[ n - 1 ] )
			wDgoChan[ n - 1 ]	+= wDgoChan[ n ]
			wDgoChange[ n - 1 ]	+= wDgoChange[ n ]
			for ( nn = n + 1; nn < nSlices; nn += 1 )
				wDgoTime[ nn - 1 ]	= wDgoTime[ nn ]
				wDgoChan[ nn - 1 ]	= wDgoChan[ nn ]
				wDgoChange[ nn - 1 ]= wDgoChange[ nn ]
			endfor
			if (  gRadDebgSel > 2  &&  PnDebgDigout )
				printf "\t\t\t\tDigoutMakeCEDString 35    combining identical times  \t\t n:%3d,%3d   \tTime:%7d \tChan:%7d \tChange:%7d \r", n-1, n,  wDgoTime[ n-1 ], wDgoChan[ n-1 ] , wDgoChange[ n-1 ] 
			endif
			nSlices -= 1
			n = 0
			continue
		else
			if ( gRadDebgSel > 2  &&  PnDebgDigout )
				 printf "\t\t\t\tDigoutMakeCEDString 36       normal checking                 \t n:%3d/%3d \tTime:%7d  \t( is != %7d   or  n == 0 )\r", n, nSlices,  wDgoTime[ n ], wDgoTime[ n - 1 ]
			endif
		endif
	endfor
	nSlices	-= 1				// up till now we actually counted times (which is 1 more than slices) , from now on we count the real slices


	// Step : CED-DIGTIM-String  ->  CONSTRUCT  IT
	variable	nDgoTime	= 0
	string		sDgoSlices = ""

	// set digital outputs specified  	
	nDgoTime	=    wDgoTime[ 0 ] 

	// When multiple protocols are output the last slice of the prot makes a jump back to the 3. slice right AFTER the initialization. 
	// This interval between 2 prots would be too short because the initialization duration is not executed again. To compensate for this we add a slice after the last slice.
	string		sText	= "building normal slice"
	variable	CorrectionForMultipleProts

	// if first user digital output pulse starts at the ending edge of Dac-Adc-Trigger pulse the slice 3 is merged into slice 3 ..
	//..(e.g. DIGTIM,A,28,28,2;DIGTIM,A,28,0,2;DIGTIM,A,1,1,2;...  ->  DIGTIM,A,28,28,2;DIGTIM,A,29,1,2;..  then we must jump back to 2. slice instead of 3. slice
	if ( wDgoChange[ 1 ] != 0 )
		gnJumpBack 			= 2
		CorrectionForMultipleProts	= 0
	else
		gnJumpBack			= 3
		CorrectionForMultipleProts	= 2	
	endif
	// printf  "\t\t\t\tDigoutMakeCEDString 37   get info for last slice\t n:%3d/%3d \tChange[ 1 ] :%d ->gnJumpBack:%d \tCorrectionForMultipleProts:%d \r", n, nSlices,  wDgoChange[ 1 ], gnJumpBack, CorrectionForMultipleProts

	for ( n = 0; n < nSlices + 1; n += 1)										// we can ignore here additional slices introduced by DIGTIM branches
		nDgoTime  	=   n == 0	?    2  :  wDgoTime[ n ] - nDgoTime

		// Compensate for missing initialization time when multiple protocols are output by PROLONGING the last time slice
		// Do NOT generally prolong the last slice, this would erroneously lengthen a pulse which is possibly still on :  Leading to timing errors
		//	This prolonging approach is not yet introduced because it is too dangerous/time-consuming/elaborate to be done right now  and also  because....
		//	...It is only the handling of 1 last time slice which makes sense to improve: more than 1 would also work but they would extend into the next protocol which should be forbidden anyway
		//e.g.     DIGTIM,A,24,24,2;DIGTIM,A,24,0,6;DIGTIM,A,1,1,13;DIGTIM,A,1,0,7;DIGTIM,A,1,1,13;     DIGTIM,A,1,0,1;DIGTIM,A,1,0,6;  -->   DIGTIM,A,1,0,7;	 	//t=6.5
		if ( n == nSlices  &&  CorrectionForMultipleProts )
			if ( 0 )	// prolong = !append					// STUB  NEVER EXECUTED  =  NOT  YET  PROGRAMMED
				nDgoTime += CorrectionForMultipleProts
				sText	= "prolonging the last"
			endif
		endif

		sDgoSlices 	+= BuildSlice( sText, wDgoChan[ n ], wDgoChange[ n ],  nDgoTime, wDgoTime[ n ] * nSmpInt / kMILLITOMICRO )

		// Compensate for missing initialization time when multiple protocols are output by APPENDING a time slice with level 0
		// See above: Do NOT simply prolong the last slice, this would erroneously lengthen a pulse which is possibly still on :  Leading to timing errors
		// 	Disadvantage: a slice length of  1 of the last slice having level 0  (which in this special could be prolonged to 3 ) leads to 'severe error' and cannot be executed
		if ( n == nSlices  &&  CorrectionForMultipleProts )
			if ( 1 )	// ! prolong = append
				sText		= "APPEND after last"
				sDgoSlices	+= BuildSlice( sText, wDgoChan[ n ], 0,  CorrectionForMultipleProts, wDgoTime[ n ] * nSmpInt / kMILLITOMICRO )
			endif
		endif

		nDgoTime  	 =  wDgoTime[ n ] 
	endfor

	gsDigoutSlices	= sDgoSlices	

	// FOR TESTING: Here the constructed DIGTIM-string can be checked , then manually changed  and finally inserted again to check if the desired output is achieved:
		// printf "\t%s\tbuilt(j:%d)\t%s \r", pd( sType1401,9 ), gnJumpBack, gsDigoutSlices[ 0,220 ]
		// printf "\tbuilt     \t%s \r", gsDigoutSlices[ 0,220 ]		
	 	 //gsDigoutSlices = "DIGTIM,A,24,24,2;DIGTIM,A,24,0,6;DIGTIM,A,1,1,15;DIGTIM,A,1,0,5;DIGTIM,A,1,1,15;DIGTIM,A,1,0,5"					//t=7.5
	 	 //gsDigoutSlices = "DIGTIM,A,24,24,2;DIGTIM,A,24,0,6;DIGTIM,A,1,1,16;DIGTIM,A,1,0,4;DIGTIM,A,1,1,16;DIGTIM,A,1,0,4"					//t=8
		 //gsDigoutSlices = "DIGTIM,A,24,24,2;DIGTIM,A,24,0,6;DIGTIM,A,1,1,17;DIGTIM,A,1,0,3;DIGTIM,A,1,1,17;DIGTIM,A,1,0,3;"				//t=8.5
		 //gsDigoutSlices = "DIGTIM,A,24,24,2;DIGTIM,A,24,0,6;DIGTIM,A,1,1,18;DIGTIM,A,1,0,2;DIGTIM,A,1,1,18;DIGTIM,A,1,0,2;"				//t=9
	
		//j=3	DIGTIM,A,24,24,2;DIGTIM,A,24,0,2;DIGTIM,A,1,1,2;	DIGTIM,A,1,0,8;DIGTIM,A,1,1,12;DIGTIM,A,1,0,8;DIGTIM,A,0,0,8;DIGTIM,A,0,0,2;   //gt 2
		//j=2	DIGTIM,A,24,24,2;DIGTIM,A,25,1,4;				DIGTIM,A,1,0,8;DIGTIM,A,1,1,12;DIGTIM,A,1,0,8;DIGTIM,A,0,0,10;DIGTIM,A,0,0,2; //gn4
		//j=2	DIGTIM,A,24,24,2;DIGTIM,A,1,1,4;DIGTIM,A,24,0,2;	DIGTIM,A,1,0,6;DIGTIM,A,1,1,12;DIGTIM,A,1,0,8;DIGTIM,A,0,0,12;DIGTIM,A,0,0,2; //gn6
		//	DIGTIM,A,24,24,2;DIGTIM,A,1,1,4;DIGTIM,A,24,0,4;	DIGTIM,A,1,0,4;DIGTIM,A,1,1,12;DIGTIM,A,1,0,8;DIGTIM,A,0,0,14;DIGTIM,A,0,0,2; //gn8
		
		//    	built(j:3)	DIGTIM,A,24,24,2;DIGTIM,A,24,0,2;DIGTIM,A,1,1,2;	DIGTIM,A,1,0,10;DIGTIM,A,1,1,10;DIGTIM,A,1,0,10;DIGTIM,A,0,0,6;DIGTIM,A,0,0,2; //gt2
		//   	built(j:2)	DIGTIM,A,24,24,2;DIGTIM,A,25,1,4;				DIGTIM,A,1,0,10;DIGTIM,A,1,1,10;DIGTIM,A,1,0,10;DIGTIM,A,0,0,6;DIGTIM,A,0,0,2; //gn4
		//  	built(j:2)	DIGTIM,A,24,24,2;DIGTIM,A,1,1,4;DIGTIM,A,24,0,2;	DIGTIM,A,1,0,8;  DIGTIM,A,1,1,10;DIGTIM,A,1,0,10;DIGTIM,A,0,0,6;DIGTIM,A,0,0,2; //gn6  	
		//  	built(j:2)	DIGTIM,A,24,24,2;DIGTIM,A,1,1,4;DIGTIM,A,24,0,4;	DIGTIM,A,1,0,6;  DIGTIM,A,1,1,10;DIGTIM,A,1,0,10;DIGTIM,A,0,0,6;DIGTIM,A,0,0,2; //gn8
	
  		// printf "\toutput   \t%s \r", gsDigoutSlices[ 0,220 ]		
	nSlices 		= ItemsInList( gsDigoutSlices )  

	// printf  "\t\tDigoutMakeCEDString 40   slices:%d  strlen:%4d ) '%s...' \r", nSlices, strlen( sDgoSlices ), sDgoSlices[0,212] 
//	if (  1|| gRadDebgSel > 0  &&  PnDebgDigout )
		printf  "\t\tDigoutMakeCEDString 40   slices:%d  strlen:%4d ) '%s...' \r", nSlices, strlen( sDgoSlices ), sDgoSlices[0,212] 
//	endif

if (  bCRASH_ON_REDIM_TEST14 )				// endif
	KillWaves  wDgoChange, wDgoChan, wDgoTime
endif
	// now digital outputs are waiting for a trigger to Event input E2 
	return	kOK
End


static Function	stFillDigDispArrays( sText, nSmpInt, nElemCnt, nChan, DgoBegPt, DgoDur, f, s, bfsPtr, e, BegPt, DgoDel, wDgoCh, wDgoBeg, wDgoDur  )  
	string		sText
	variable	nSmpInt, nElemCnt, nChan, DgoBegPt, DgoDur, f, s, bfsPtr, e, BegPt, DgoDel
	wave	wDgoCh, wDgoBeg, wDgoDur

	nvar		gRadDebgSel 	= root:uf:dlg:gRadDebgSel
	nvar		PnDebgDigout	= root:uf:dlg:Debg:Digout
	string		bf
	wDgoBeg[ nElemCnt ]		= round ( DgoBegPt )
	wDgoDur[ nElemCnt ]			= DgoDur   
	wDgoCh[ nElemCnt ]			= nChan
	if (  gRadDebgSel > 2  &&  PnDebgDigout )
		printf "\t\t\t\tDigoutMakeDisplayWaves 21    %s \tel:%2d  \tf:%d\ts:%d\tff:%d\te:%d\tch:%d\tBegPt:\t%8d\tDgoDel:%5d\t -> DgoBegPt:\t%8d \tDgoDur:%5d \r", sText, nElemCnt, f, s, bfsPtr, e, nChan, BegPt , DgoDel, DgoBegPt, DgoDur 
	endif
	if ( DgoBegPt < -1  )	
		Alert( kERR_SEVERE, "Digital Out pulse (ch:" + num2str( wDgoCh[ nElemCnt ] ) + ") cannot start at times more negative than 1 time slice (= sample interval) . Must start at  -" + num2str( nSmpInt ) + " us or later. (Starts at " + num2str( DgoBegPt ) + " time slices)" )
	endif
	if ( DgoBegPt == -1 &&  !( nChan == 3  ||  nChan == 4 ) )	// do not complain about Events 3 and 4 which always start at time zero - 1 sample interval
		Alert( kERR_IMPORTANT, "Digital Out pulse (ch:" + num2str( wDgoCh[ nElemCnt ] ) + ") starting at -" + num2str( nSmpInt ) + " us will only be output in the 1. protocol") 
	endif
	nElemCnt += 1
	return	nElemCnt
End	


static Function	stFillDigTimArrays( sText, nSmpInt, nSlices, nChan, DgoBegPt, DgoDur,  f, s, bfsPtr, e, BegPt, DgoDel, nPnts, wDgoTime, wDgoChan, wDgoChange )  
	string		sText
	variable	nSmpInt, nSlices, nChan, DgoBegPt, DgoDur, f, s, bfsPtr, e, BegPt, DgoDel, nPnts
	wave	wDgoTime, wDgoChan, wDgoChange

	nvar		gRadDebgSel 	= root:uf:dlg:gRadDebgSel
	nvar		PnDebgDigout	= root:uf:dlg:Debg:Digout
	string		bf
	wDgoTime[ nSlices ]		=  round( DgoBegPt ) 						// not rounding here produces sporadically very ugly errors
	wDgoTime[ nSlices + 1 ]	=  round( DgoBegPt + DgoDur )					//..   
	wDgoChange[ nSlices ]	=  2 ^ nChan
	wDgoChange[ nSlices + 1 ]	=  0
	wDgoChan[ nSlices ]		=  2 ^ nChan
	wDgoChan[ nSlices + 1 ]	=  2 ^ nChan
	// printf "\t\t\t\tDigoutMakeCEDString 31    %s\tsl:%3d  \tf:%d\ts:%d\tff:%d\te:%d\tch:%d\tBegPt:\t%8d\tDel:%5d\t -> Beg:\t%8d \tDur:%5d\t-> %5d ..%5d \r", sText, nSlices, f, s, bfsPtr, e, nChan, BegPt , DgoDel , DgoBegPt, DgoDur, wDgoTime[ nSlices ], wDgoTime[ nSlices+1 ]
	if ( gRadDebgSel > 2  &&  PnDebgDigout )
		printf "\t\t\t\tDigoutMakeCEDString 31    %s\tsl:%3d  \tf:%d\ts:%d\tff:%d\te:%d\tch:%d\tBegPt:\t%8d\tDel:%5d\t -> Beg:\t%8d \tDur:%5d\t-> %5d ..%5d \r", sText, nSlices, f, s, bfsPtr, e, nChan, BegPt , DgoDel , DgoBegPt, DgoDur, wDgoTime[ nSlices ], wDgoTime[ nSlices+1 ]
	endif
	if ( wDgoTime[ nSlices + 1 ] >   nPnts  )	// 030707	 (the more stringent condition >= does not seem to be necessary....)
		sprintf bf, "Digital output pulse close to or extending over end of stimulus. (%d>%d) ", wDgoTime[ nSlices + 1 ] , nPnts 
		Alert( kERR_IMPORTANT, bf )
	endif
	nSlices += 2
	return	nSlices
End	


Function	/S	BuildSlice( sText, nChan, nChange,  nDuration, nAbsoluteTime )
	string		sText
	variable	nChan, nChange,  nDuration, nAbsoluteTime 
	nvar		gRadDebgSel 	= root:uf:dlg:gRadDebgSel
	nvar		PnDebgDigout	= root:uf:dlg:Debg:Digout
	string		sDgoDIGTIM, bf

		if ( nDuration  < cCEDMAXSLICELEN + 2 )					// cCEDMAXSLICELEN is small enough to allow for the extra 2 slices (required as minimum by 1401 hardware)
			sprintf sDgoDIGTIM, "DIGTIM,A,%d,%d,%d;", nChan, nChange, nDuration
			if  ( nDuration < 2 )								// maybe this error could and should be caught earlier...
				sprintf bf, "Digital output pulse conflict at %.3lf ms resulting in time slices < 2 sample intervals which the Ced1401 cannot process.  (Ch:%d, change to:%d, dur:%d) ", nAbsoluteTime, nChan, nChange,  nDuration 
				Alert( kERR_SEVERE, bf )
			endif
		else												// Break a slice which is longer than 65532 sample intervals into shorter slices and catenate them
			variable	SmallEnoughSlice, Repeats, Rest, jmp = 0
			FactorizeSlice( nDuration, SmallEnoughSlice, Repeats, Rest )	// always returns a rest >= 2 which is required by the CED
			// loop 'Repeats' times the maximum SI cnt (=65532) with the previous value (=no change), then just once the rest SI cnt with the changes
			sprintf sDgoDIGTIM, "DIGTIM,A,%d,%d,%d,%d,%d;DIGTIM,A,%d,%d,%d;", 0 , 0 ,  SmallEnoughSlice, jmp, Repeats, nChan,  nChange,  Rest	
		endif									// side effect : nSlices is  increased 1 one more than expected but we must NOT increase it here explicitly

		if (  gRadDebgSel > 1  &&  PnDebgDigout )
			printf  "\t\t\tDigoutMakeCEDString 38   %s\t%s \tDur:\t %8d\t(fact. with max = %d ) -> %3d x %3d  +  %3d \t\r",  pad( sText,16), pd(sDgoDIGTIM,36), nDuration, cCEDMAXSLICELEN, Repeats, SmallEnoughSlice, Rest
		endif
		// printf  "\t\t\tDigoutMakeCEDString 38  .%s\t%s \tDur:\t %8d\t(fact. with max = %d ) -> %3d x %3d  +  %3d \t\r",  pad( sText,16), pd(sDgoDIGTIM,36), nDuration, cCEDMAXSLICELEN, Repeats, SmallEnoughSlice, Rest

		return	sDgoDIGTIM
End


Function		FactorizeSlice( nDgoTime, SmallEnoughSlice, Repeats, Rest )
	variable	nDgoTime
	variable	&SmallEnoughSlice, &Repeats, &Rest
	nDgoTime			-= 2		// ensure that the last slice returned  has at least 2 sample intervals as required by the CED
	Repeats			= trunc ( nDgoTime / cCEDMAXSLICELEN )
	SmallEnoughSlice	= cCEDMAXSLICELEN
	Rest				= nDgoTime -  Repeats * SmallEnoughSlice + 2
	// printf "\t\tFactorizeSlice( %d with max = %d ) -> %d x %d  +  %d \r", nDgoTime+2, cCEDMAXSLICELEN, Repeats, SmallEnoughSlice, Rest
End
	

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// LITTLE HELPERS

Function  /S 	ChannelList_( wIO, nIO, nChs )
	wave  /T	wIO
	variable	nChs, nIO			// 'kIO_ADC'  or  'kIO_DAC'
	variable	c
	string		bf, sChans = ""
	for ( c = 0; c < nChs;  c += 1 )
		sChans += " "
		sChans += num2str( iov( wIO, nIO, c, cIOCHAN ) )
	endfor
	// printf   "\t\tCed Channellist for %d '%s' channels '%s' \r", nChs, ioTNm( nIO ), sChans
	sprintf  bf, "\t\tCed Channellist for %d '%s' channels '%s' \r", nChs,  ioTNm( nIO ), sChans ; Out( bf )
	return 	sChans
End

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function		LaggingTime()
// returns how much longer than predicted the script will take due to too much data that are to be displayed (0 is ideal, value in %)
	string  	sFolder		= ksfACO
	wave  	wG			= $ksROOTUF_ + sFolder + ":keep:wG"  				// This  'wG'	is valid in FPulse ( Acquisition ). StatusBar will not work if  wG  ispassed....
//	return	100 * ( wG[ kTOTAL_SWPS ] / wG[ kSWPS_WRITTEN ] * TimeElapsed_() / wG[ kTOTAL_US ] * 1e6  - 1  )	// in % of total predicted time
	return	(   TimeElapsed_() - wG[ kTOTAL_US ]	 * wG[ kSWPS_WRITTEN ] / wG[ kTOTAL_SWPS ] / 1e6  )			// in seconds
End

Function		TimeElapsed_()
	string  	sFolder		= ksfACO
	nvar		gbRunning	= root:uf:aco:keep:gbRunning
	nvar		gnTicksStop	= root:uf:aco:keep:gnTicksStop
	nvar		gnTicksStart	= root:uf:aco:keep:gnTicksStart

	variable	nStopTime 	= gbRunning ? ticks : gnTicksStop  
	return	( nStopTime - gnTicksStart ) / kTICKS_PER_SEC		 // returns seconds elapsed since ...
End


static Function	stGetAndInterpretAcqErrors( hnd, sText1, sText2, chunk, nMaxChunks )
	string		sText1, sText2
	variable	hnd, chunk, nMaxChunks
	string		errBuf
	variable	code	

	string		sErrorCodes	= xCEDGetResponseTwoIntAsString( hnd, "ERR;" )
	code		= stExplainCEDError( sErrorCodes, sText1 +" | " +  sText2, chunk, nMaxChunks )
	code		= trunc( code / 256 )			// 030805 use only the first byte of the 2-byte errorcode (only temporarily to be compatible with the code below...) 
	// printf "...( '%s' = '%d  '%d' )\t",  sErrorCodes, str2num( StringFromList( 0, sErrorCodes, " " ) ) , str2num( StringFromList( 1, sErrorCodes, " " ) )

	// 2011-01-11 If the Debugger complains about a 'Null string error' here,  it might well be that you are using an inadequate USB cable !  Be sure to use a Hi-Speed USB cable of top quality !

	return	code
End


static Function	stExplainCEDError( sErrorCodes, sCmd, chunk, nMaxChunks )
// prints error codes issued by the CED in a human readable form. See 1401 family programming manual, july 1999, page 17
	string		sCmd, sErrorCodes
	variable	chunk, nMaxChunks
	string		sErrorText
	variable	nErrorLevel	= kERR_SEVERE					// valid for all errors (=mandatory beep)  except 'Clock input overrun', which may occur multiple times..
	variable	er0	= str2num( StringFromList( 0, sErrorCodes, " " ) )	//.. in slightly too fast scripts while often not really being an error (=kERR_IMPORTANT, beep can be turned off) 
	variable	er1	= str2num( StringFromList( 1, sErrorCodes, " " ) )
	if ( er0 == 0 )
		return	0
	elseif ( er0 == 255 )
		sErrorText	= "Unknown command.   [" + sCmd  + "]"
	elseif( er0 == 254 )
		sErrorText	= "There is an error in the argument list  in field " + num2str( er1 / 16 ) + ".   [" + sCmd  + "]"
	elseif( er0 == 253 )
		sErrorText	= "Runtime error resulting probably from field " + num2str( er1 / 16 ) + ".   [" + sCmd  + "]"
	elseif( er0 == 252 )
		sErrorText	= "Error evaluating expression.   [" + sCmd  + "]"
	elseif( er0 == 251 )
		sErrorText	= "Division by zero during evaluation of an expression.   [" + sCmd  + "]"
	elseif( er0 == 250 )
		sErrorText	= "Unknown symbol.   [" + sCmd  + "]"
	elseif( er0 == 249 )
		sErrorText	= "Command too long.   [" + sCmd  + "]"
	elseif( er0 == 248 )
		sErrorText	= "End of line (CR character)  in a string field introduced by  ''  .   [" + sCmd  + "]"
	elseif( er0 == 247 )
		sErrorText	= "Memory reference was outside user memory area.   [" + sCmd  + "]"
	elseif( er0 == 16 ||  er0 == 32 )
		sErrorText	= "Inspite of Ced reporting 'Clock interrupt overrun : Sampling too fast or too many channels' :  THE DATA MAY BE OK. [\t" + pad(sCmd,19)  + "\t]"
		nErrorLevel = kERR_IMPORTANT		// beep can be turned off when this error is triggered erroneously (which is unfortunately often the case)
	else
		sErrorText	= "Could not interpret this error :" + sErrorCodes + "   [" + sCmd  + "]"
	endif
	sErrorText = sErrorText + "  err:'" + sErrorCodes + "'  in chunk " + num2str( chunk )	 +  " / " + num2str( nMaxChunks )	
	Alert( nErrorLevel, sErrorText[0,220] )
	return	er0 * 256 + er1							// 030805  build and return  1  16 bit number from the 2 bytes 

End

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  1401  TEST  FUNCTIONS

// 2021-03-10 new-style		(CHANGE:  changed wave location from   uf:aco:dlg:tPnT14001   ->  uf:aco:PnT21401 )
Function		Dilg_Test1401( nMode )
	variable	nMode					//  kPN_INIT  or  kPN_DRAW
	string  	sFBase		= ksROOTUF_
	string  	sFSub		= ksfACO_	
	string  	sWin		= "PnT1401" 
	string	sPnTitle		= "Ced1401 V3"
	string	sDFSave		= GetDataFolder( 1 )					// The following functions do NOT restore the CDF so we remember the CDF in a string .
	PossiblyCreateFolder( sFBase + sFSub + sWin ) 
	SetDataFolder sDFSave										// Restore CDF from the string  value
	stInitPanelTest1401( sFBase + sFSub, sWin )					// fills big text wave  'sPnOptions' (=wPn)  with all information about the controls necessary to build the panel
	Panel3Sub_(   sWin, 	sPnTitle, 	sFBase + sFSub,  90, 80,  nMode, 1 ) 	// Compute the location of panel controls and the panel dimensions. Draw the panel displaying and hiding needed/unneeded controls.  Last par:1 allows closing
	PnLstPansNbsAdd( ksfACO,  sWin )
End

static Function	stInitPanelTest1401( sF, sPnOptions )
	string  	sF, sPnOptions
	string	sPanelWvNm = sF + sPnOptions
	variable	n = -1, nItems = 20
	// printf "\tstInitPanelTest1401( '%s',  '%s' ) \r", sF, sPnOptions 
	make /O /T /N=(nItems)	$sPanelWvNm
	wave  /T	tPn	=		$sPanelWvNm
	// Cave / Flaw :   No tabcontrol = empty  'Tabs'  must have   different number of spaces (no Tab, not the empty string )  to be recognised correctly
	// Cave / Flaw :   For each item in  'Tabs'   there must be a  corresponding  'Blks'  entry  even if empty
	// Cave / Flaw :	   Only tabulators can be used  for aligning the following columns, do not use spaces.... (maybe they are allowed...)
	//					Type  NxL Pos MxPo OvS Tabs 	Blks	Mode	Name	RowTi					ColTi  ActionProc			XBodySz	FormatE	Initval	Visibility	SubHelp
	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	?:		,:	1,?:		bu1:		Current Handle:			:	fCurrentHandle():		:		:		:		:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    1:0:	2:	0:	?:		,:	1,?:		bu2:		Open 1401:				:	fOpen1401():			:		:		:		:		:	"		
	n += 1;	tPn[ n ] =	"BU:    0:1:	2:	0:	?:		,:	1,?:		bu3:		Reset 1401:				:	fReset1401():			:		:		:		:		:	"		
	n += 1;	tPn[ n ] =	"BU:    1:	0:	2:	0:	?:		,:	1,?:		bu4:		Close 1401:				:	fClose1401():			:		:		:		:		:	"		
	n += 1;	tPn[ n ] =	"BU:    0:1:	2:	0:	?:		,:	1,?:		bu5:		Type 1401:				:	fType1401():			:		:		:		:		:	"		
	n += 1;	tPn[ n ] =	"BU:    1:	0:	2:	0:	?:		,:	1,?:		bu6:		Memory 1401:			:	fMemory1401():		:		:		:		:		:	"		
	n += 1;	tPn[ n ] =	"BU:    0:1:	2:	0:	?:		,:	1,?:		bu7:		Status 1401:				:	fStatus1401():		:		:		:		:		:	"		
	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	?:		,:	1,?:		bu8:		On-Off  Status  of 1401:	:	fStatusOnOff1401():	:		:		:		:		:	"		
	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	?:		,:	1,?:		bu9:		Open Status  of 1401:		:	fStatusOpen1401():	:		:		:		:		:	"		
	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	?:		,:	1,?:		bu10:	Properties of 1401:		:	fProperties1401():		:		:		:		:		:	"		
	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	?:		,:	1,?:		bu11:	Reset Dacs:				:	fResetDacs():			:		:		:		:		:	"		
	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	?:		,:	1,?:		bu12:	Set digital outputs:		:	fSetDigOut():			:		:		:		:		:	"		
	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	?:		,:	1,?:		bu13:	Reset digital outputs:		:	fResetDigOut():		:		:		:		:		:	"		
	redimension  /N = ( n+1)	tPn
End

Function		fCurrentHandle( s )	// Called when a button is pressed.  ALSO CALLED when moving the mouse over a button.  See  'fButtonProc_struct()'  on how to avoid this event.
	struct	WMButtonAction &s
	if (  s.eventCode == kCCE_mouseup ) 
		// print s.ctrlName
		printf "\tTest1401 \t\tV3   Current   NEW  handle is %d \r", CedHandle_()
	endif
End

Function		fOpen1401( s )		// Called when a button is pressed.  ALSO CALLED when moving the mouse over a button.  See  'fButtonProc_struct()'  on how to avoid this event.
	struct	WMButtonAction &s
	if (  s.eventCode == kCCE_mouseup ) 
		variable	hnd	= CedHandle_()		// 2010-01-05	old handle which can be valid or invalid
		hnd	= xCEDCloseAndOpen( hnd )
		stCedHandleSet( hnd )
		printf "\t\tfOpen1401  \tV3\treturning hnd:\t%d =?= %d\r",  hnd, CedHandle_()
	endif
End

Function		fReset1401( s )		// Called when a button is pressed.  ALSO CALLED when moving the mouse over a button.  See  'fButtonProc_struct()'  on how to avoid this event.
	struct	WMButtonAction &s
	if (  s.eventCode == kCCE_mouseup ) 
		variable	code, state, hnd		= CedHandle_()// 2010-01-05
		if ( hnd >= 0 )
			state = xCedStateOf1401( hnd ) 
			if ( state == 0 )
				code		= xCedReset( hnd )
				printf "\t\t\tCedReset: Ced was open with hnd:%d and has been reset (state:%d, reset return code:%d) \r", hnd, state, code
			else
				printf "\t\t\tCedReset: Ced was open with hnd:%d but state:%d (should be 0) .  no reset  \r", hnd, state
	//				U14GetErrorString( state, stateText, 400 );
	//				printf "\t\t\tCEDReset: Ced was not open (hnd:%d -> %d) '%s' \r", hnd, code, state ? stateText : "" ); XOPNotice(bf);
			endif
		else
			printf "\t\t\tCEDReset: Ced was not open (hnd:%d )  \r", hnd
		endif
	endif
End

Function		fClose1401( s )		// Called when a button is pressed.  ALSO CALLED when moving the mouse over a button.  See  'fButtonProc_struct()'  on how to avoid this event.
	struct	WMButtonAction &s
	if (  s.eventCode == kCCE_mouseup ) 
		variable	code, hnd = CedHandle_()// 2010-01-05
		code	= xCedClose( hnd )
		stCedHandleSet( CED_NOT_OPEN )
		printf "\tV3\tfClose1401 \t\treturns code : \t%d\t%s \r", code, stCedErrorString( code ) 
	endif
End

Function		fType1401( s )		// Called when a button is pressed.  ALSO CALLED when moving the mouse over a button.  See  'fButtonProc_struct()'  on how to avoid this event.
	struct	WMButtonAction &s
	if (  s.eventCode == kCCE_mouseup ) 
		variable	hnd		= CedHandle_()// 2010-01-05
		printf "\t\t\tCEDType:  "
		variable	nType	   = stCEDType( hnd, MSGLINE_C )
		printf "\t\t\tCEDDriver:"
		variable	nDriverType = stCEDDriverType( MSGLINE_C )
	endif
End

Function		fMemory1401( s )		// Called when a button is pressed.  ALSO CALLED when moving the mouse over a button.  See  'fButtonProc_struct()'  on how to avoid this event.
	struct	WMButtonAction &s
	if (  s.eventCode == kCCE_mouseup ) 
		variable	hnd		= CedHandle_()// 2010-01-05
		variable	nCedType, nSize
		printf "\tChecking memory size  before\tsending 'MEMTOP,E;'  : "
		nSize	= stCEDGetMemSize( hnd, MSGLINE_C )	
		nCedType	= stCEDType( hnd, MSGLINE_C )
		if ( nCedType == c1401PLUS )					// only  1=1401plus needs 'MEMTOP,E;' command , but not 0=1401standard,  2=1401micro or  3=1401power
			stCEDSendStringCheckErrors(  hnd, "MEMTOP,E;" , 0 ) // 1 ) 
			printf "\tChecking memory size   after \tsending 'MEMTOP,E;'  : "
			nSize = stCEDGetMemSize( hnd, MSGLINE_C )		
		endif
	endif
End

Function		fStatus1401( s )		// Called when a button is pressed.  ALSO CALLED when moving the mouse over a button.  See  'fButtonProc_struct()'  on how to avoid this event.
	struct	WMButtonAction &s
	if (  s.eventCode == kCCE_mouseup ) 
		string		ctrlName
		variable	hnd	= CedHandle_()// 2010-01-05
		variable 	state	= xCedStateOf1401( hnd ) 									// Check if CEDHandle is consistent with current Ced state. Set CEDHandle 'off'  if Ced state says 'off'  (happens if 1401 had been on but has just been switched off) 
		//printf "\t\tfStatus1401 \t\t1401 has state : %d   '%s' \r", state, xCedGetErrorString( state )
		printf "\t\tfStatus1401 \tV3\t1401 has state :\t%d\t%s \r", state, stCedErrorString( state ) 
	endif
End

Function		fStatusOnOff1401( s )	// Called when a button is pressed.  ALSO CALLED when moving the mouse over a button.  See  'fButtonProc_struct()'  on how to avoid this event.
	struct	WMButtonAction &s
	if (  s.eventCode == kCCE_mouseup ) 
		variable	hnd	= CedHandle_()// 2010-01-05
		variable 	state	= xCedState( hnd ) 									// Check if CEDHandle is consistent with current Ced state. Set CEDHandle 'off'  if Ced state says 'off'  (happens if 1401 had been on but has just been switched off) 
		printf "\t\tfStatusOnOff1401 \t1401 has state :\t%d\t(%s) \r", state, SelectString( state+1, "Closed/Off", "Open/On" )
	endif
End

Function		fStatusOpen1401( s )	// Called when a button is pressed.  ALSO CALLED when moving the mouse over a button.  See  'fButtonProc_struct()'  on how to avoid this event.
	struct	WMButtonAction &s
	if (  s.eventCode == kCCE_mouseup ) 
		stPrintCEDStatus( 0 )					// 0 disables the printing of 1401 type and memory 
	endif
End

Function		fProperties1401( s )	// Called when a button is pressed.  ALSO CALLED when moving the mouse over a button.  See  'fButtonProc_struct()'  on how to avoid this event.
	struct	WMButtonAction &s
	if (  s.eventCode == kCCE_mouseup ) 
		stPrintCEDStatus( MSGLINE_C )			// MSGLINE_C enables the printing of 1401 type and memory 
	endif
End

Function		fResetDacs( s )		// Called when a button is pressed.  ALSO CALLED when moving the mouse over a button.  See  'fButtonProc_struct()'  on how to avoid this event.
	struct	WMButtonAction &s
	if (  s.eventCode == kCCE_mouseup ) 
		variable	hnd		= CedHandle_()// 2010-01-05
		if ( hnd >= 0 )
			stCEDSendStringCheckErrors(  hnd, "DAC,0 1 2 3,0 0 0 0;" , 1  ) 
		else
			printf "\t\tfResetDacs  \t\tCed not open...\r"
		endif
	endif
End

Function		fSetDigOut( s )		// Called when a button is pressed.  ALSO CALLED when moving the mouse over a button.  See  'fButtonProc_struct()'  on how to avoid this event.
	struct	WMButtonAction &s
		if (  s.eventCode == kCCE_mouseup ) 
		variable	hnd		= CedHandle_()// 2010-01-05
		if ( hnd >= 0 )
			stCEDSetAllDigOuts( hnd, 1 )					// 2003-1110  Initialize the digital output ports with 1 : set to HIGH
		else
			printf "\t\tfSetDigOut \t\tCed not open...\r"
		endif
	endif
End

Function		fResetDigOut( s )		// Called when a button is pressed.  ALSO CALLED when moving the mouse over a button.  See  'fButtonProc_struct()'  on how to avoid this event.
	struct	WMButtonAction &s
	if (  s.eventCode == kCCE_mouseup ) 
		variable	hnd		= CedHandle_()// 2010-01-05
		if ( hnd >= 0 )
			stCEDSetAllDigOuts( hnd, 0 )				// 2003-1110  Initialize the digital output ports with 0 : set to LOW
		else
			printf "\t\tfResetDigOut \t\tCed not open...\r"
		endif
	endif
End


//-------------------------------------------------------------------------------------------------------------
// 2021-03-10 old-style
//Function		Test1401Dlg()
//	string  	sFolder		= ksfACO
//	string  	sPnOptions	= ":dlg:tPnT1401" 
//	string  	sWin		= "PnTestCed1401" 
//	InitPanelTest1401_( sFolder, sPnOptions )
//	ConstructOrDisplayPanel(  sWin, "Ced1401 V3" , sFolder, sPnOptions,  90, 80 )
//	PnLstPansNbsAdd( ksfACO,  sWin )
//End
//
//Function		InitPanelTest1401_( sFolder, sPnOptions )
//	string  	sFolder, sPnOptions
//	string		sPanelWvNm = ksROOTUF_ + sFolder + sPnOptions
//	variable	n = -1, nItems = 20
//	make /O /T /N=(nItems)	$sPanelWvNm
//	wave  /T	tPn		= 	$sPanelWvNm
//	n += 1;	tPn[ n ] =	"PN_BUTTON;	buCurrentHandle	;Current handle"		
//	n += 1;	tPn[ n ] =	"PN_BUTTON;	buOpen1401		;Open 1401"			
//	n += 1;	tPn[ n ] =	"PN_BUTTON; 	buReset1401		;Reset 1401"			
//	n += 1;	tPn[ n ] =	"PN_BUTTON;	buClose1401		;Close 1401"			
//	n += 1;	tPn[ n ] =	"PN_BUTTON;	buType1401		;Type of 1401"			
//	n += 1;	tPn[ n ] =	"PN_BUTTON;	buMemory1401	;Memory of 1401"		
//	n += 1;	tPn[ n ] =	"PN_BUTTON;	buStatus1401		;Status of 1401"		
//	n += 1;	tPn[ n ] =	"PN_BUTTON;	buStatusOnOff1401;On-Off  Status  of 1401"		
//	n += 1;	tPn[ n ] =	"PN_BUTTON;	buStatusOpen1401;Open  Status  of 1401"		
//	n += 1;	tPn[ n ] =	"PN_BUTTON;	buProperties1401	;Properties of 1401"	
//	n += 1;	tPn[ n ] =	"PN_BUTTON;	buResetDacs		;Reset Dacs"
//	n += 1;	tPn[ n ] =	"PN_BUTTON;	buSetDigOut		;Set digital outputs"
//	n += 1;	tPn[ n ] =	"PN_BUTTON;	buResetDigOut	;Reset digital outputs"
//	redimension  /N = (n+1)	tPn
//End
//
//
//Function		buCurrentHandle( ctrlName ) : ButtonControl
//	string		ctrlName
//	printf "\tTest1401 \t\tV3   Current   NEW  handle is %d \r", CedHandle_()
//End
//
//Function		buOpen1401( ctrlName ) : ButtonControl
//	string		ctrlName
//	variable	hnd
//	hnd	= CedHandle_()		// 2010-01-05	old handle which can be valid or invalid
//	hnd	= xCEDCloseAndOpen( hnd )
//	stCedHandleSet( hnd )
//	printf "\t\tfOpen1401  \tV3\treturning hnd:\t%d =?= %d\r",  hnd, CedHandle_()
//End
//
//Function		buReset1401( ctrlName ) : ButtonControl
//	string		ctrlName
//	variable	code, state, hnd		= CedHandle_()// 2010-01-05
//	if ( hnd >= 0 )
//		state = xCedStateOf1401( hnd ) 
//		if ( state == 0 )
//			code		= xCedReset( hnd )
//			printf "\t\t\tCedReset: Ced was open with hnd:%d and has been reset (state:%d, reset return code:%d) \r", hnd, state, code
//		else
//			printf "\t\t\tCedReset: Ced was open with hnd:%d but state:%d (should be 0) .  no reset  \r", hnd, state
////				U14GetErrorString( state, stateText, 400 );
////				printf "\t\t\tCEDReset: Ced was not open (hnd:%d -> %d) '%s' \r", hnd, code, state ? stateText : "" ); XOPNotice(bf);
//		endif
//	else
//		printf "\t\t\tCEDReset: Ced was not open (hnd:%d )  \r", hnd
//	endif
//End
//
//Function		buClose1401( ctrlName ) : ButtonControl
//	string		ctrlName
//	variable	code, hnd	
//	hnd	= CedHandle_()// 2010-01-05
//	code	= xCedClose( hnd )
//	stCedHandleSet( CED_NOT_OPEN )
//	printf "\tV3\tfClose1401 \t\treturns code : \t%d\t%s \r", code, stCedErrorString( code ) 
//End
//
//
//Function		buType1401( ctrlName ) : ButtonControl
//	string		ctrlName
//	variable	hnd		= CedHandle_()// 2010-01-05
//	printf "\t\t\tCEDType:  "
//	variable	nType	   = stCEDType( hnd, MSGLINE_C )
//	printf "\t\t\tCEDDriver:"
//	variable	nDriverType = stCEDDriverType( MSGLINE_C )
//End
//
//Function		buMemory1401( ctrlName ) : ButtonControl
//	string		ctrlName
//	variable	hnd		= CedHandle_()// 2010-01-05
//	variable	nCedType, nSize
//	printf "\tChecking memory size  before\tsending 'MEMTOP,E;'  : "
//	nSize	= stCEDGetMemSize( hnd, MSGLINE_C )	
//	nCedType	= stCEDType( hnd, MSGLINE_C )
//	if ( nCedType == c1401PLUS )					// only  1=1401plus needs 'MEMTOP,E;' command , but not 0=1401standard,  2=1401micro or  3=1401power
//		stCEDSendStringCheckErrors(  hnd, "MEMTOP,E;" , 0 ) // 1 ) 
//		printf "\tChecking memory size   after \tsending 'MEMTOP,E;'  : "
//		nSize = stCEDGetMemSize( hnd, MSGLINE_C )		
//	endif
//End
//
//Function		buStatus1401( ctrlName ) : ButtonControl
//	string		ctrlName
//	variable	hnd	= CedHandle_()// 2010-01-05
//	variable 	state	= xCedStateOf1401( hnd ) 									// Check if CEDHandle is consistent with current Ced state. Set CEDHandle 'off'  if Ced state says 'off'  (happens if 1401 had been on but has just been switched off) 
//	//printf "\t\tfStatus1401 \t\t1401 has state : %d   '%s' \r", state, xCedGetErrorString( state )
//	printf "\t\tfStatus1401 \tV3\t1401 has state :\t%d\t%s \r", state, stCedErrorString( state ) 
//End
//
//Function		buStatusOnOff1401( ctrlName ) : ButtonControl
//	string		ctrlName
//	variable	hnd	= CedHandle_()// 2010-01-05
//	variable 	state	= xCedState( hnd ) 									// Check if CEDHandle is consistent with current Ced state. Set CEDHandle 'off'  if Ced state says 'off'  (happens if 1401 had been on but has just been switched off) 
//	printf "\t\tfStatusOnOff1401 \t1401 has state :\t%d\t(%s) \r", state, SelectString( state+1, "Closed/Off", "Open/On" )
//End
//
//Function		buStatusOpen1401( ctrlName ) : ButtonControl
//	string		ctrlName
//	stPrintCEDStatus( 0 )					// 0 disables the printing of 1401 type and memory 
//End
//	
//Function		buProperties1401( ctrlName ) : ButtonControl
//	string		ctrlName
//	stPrintCEDStatus( MSGLINE_C )			// MSGLINE_C enables the printing of 1401 type and memory 
//End
// 
//Function		buResetDacs( ctrlName ) : ButtonControl
//	string		ctrlName
//	variable	hnd		= CedHandle_()// 2010-01-05
//	if ( hnd >= 0 )
//		stCEDSendStringCheckErrors(  hnd, "DAC,0 1 2 3,0 0 0 0;" , 1  ) 
//	else
//		printf "\t\tfResetDacs  \t\tCed not open...\r"
//	endif
//End
// 
//Function		buSetDigOut( ctrlName ) : ButtonControl
//	string		ctrlName
//	variable	hnd		= CedHandle_()// 2010-01-05
//	if ( hnd >= 0 )
//		stCEDSetAllDigOuts( hnd, 1 )					// 2003-1110  Initialize the digital output ports with 1 : set to HIGH
//	else
//		printf "\t\tfSetDigOut \t\tCed not open...\r"
//	endif
//End
//
//Function		buResetDigOut( ctrlName ) : ButtonControl
//	string		ctrlName
//	variable	hnd		= CedHandle_()// 2010-01-05
//	if ( hnd >= 0 )
//		stCEDSetAllDigOuts( hnd, 0 )				// 2003-1110  Initialize the digital output ports with 0 : set to LOW
//	else
//		printf "\t\tfResetDigOut \t\tCed not open...\r"
//	endif
//End

//------------------------------------------------------------------------
 
// 2021 made static
//Function		CedType( hnd, mode )
static Function	stCedType( hnd, mode )
	variable	hnd, mode
	variable	nCedType	= xCEDTypeOf( hnd )	
	if ( mode )
		printf "\t\t1401 type:\t\t  '%s'  \t(%d) \r", StringFromList( nCedType + 1, sCEDTYPES ), nCedType	// the string list 'sCEDTYPES 'starts with 'unknown' = -1
	endif
	return	nCedType
End

static Function	stCedDriverType( mode )
	variable	mode
	variable	nCedDriverType	= xCEDDriverType()	
	if ( mode )
		printf "\t\t1401 driver type:  '%s' \t\t(%d) \r", StringFromList( nCedDriverType +1 , sCEDDRIVERTYPES ), nCedDriverType	// the string list 'sCEDDRIVERTYPES 'starts with 'unknown' = -1
	endif
	return	nCedDriverType
End

static Function	stCEDGetMemSize( hnd, mode )			
	variable	hnd, mode
	if ( hnd >= 0 )
		variable	nSize	= xCEDGetMemSize( hnd )
		if ( nSize < 0 )			// there was an error
			printf "Error: xCedGetMemSize( hnd:%d) returned error:%d \r", hnd, nSize
		else
			if ( mode )
				printf "\t\t1401 has memory: %d Bytes = %.2lf MB \r", nSize, nSize/1024./1024.
			endif
			return	nSize
		endif
	endif
End

static Function	stCEDSetAllDigOuts( hnd, value )
	// 031110  Initialize the digital output ports with 0 : set to LOW
	variable	hnd, value 
	variable	nDigoutBit
	string		buf
	for ( nDigoutBit = 8; nDigoutBit <= 15; nDigoutBit += 1 )
		sprintf  buf, "DIG,O,%d,%d;", value, nDigoutBit
		stCEDSendStringCheckErrors( hnd, buf , 0 ) 
	endfor
End


static Function	stPrintCEDStatus( ErrShow )
// prints current CED status (missing or off, present, open=in use) and also (depending on 'ErrShow') the type and memory size of the 1401 
//! There is some confusion regarding the validity of CED handles  (CED Bug? ) : 
//  The manual says that positive values returned from 'CEDOpen()' are valid handles (at least numbers from 0..3, although only 0 is used presently)...
// ..but actually the only valid handle number ever returned is 0. Handle 5 (sometimes 6?) is returned after the following actions (misuse but nevertheless possible) : 
// 1401 is switched on and open, 1401 is switched off, 1401 is switched on again, 1401 is opened -> hnd 5 is returned indicating OK but 1401 is NOT OK and NOT OPEN. . 
// This erroneous 'state 5' must be stored somewhere in the host as it is cleared by restarting the IGOR program  OR by  closing the 1401  with hnd=0 before attempting to open it.
// Presently the XOPs CedOpen etc. do not process the 'switched off positive handle state' separately but handle it just like the closed state of the 1401.
 	variable	ErrShow
 	string	sText
	variable	bCEDWasClosed, nHndAfter, nHndBefore = CedHandle_()
	if ( stCEDHandleIsOpen() )				
		bCEDWasClosed = FALSE
		sText = "\t1401 should be open  (old hnd:" + num2str( nHndBefore ) + ")"
	else
		bCEDWasClosed = TRUE
		sText = "\t1401 was closed or off  (old hnd:" + num2str( nHndBefore ) + ")"
	endif
	nHndAfter = xCEDCloseAndOpen( nHndBefore ) 		// try to open it  independent of its state : open, closed, switched off or on (no messages!)
	stCedHandleSet( nHndAfter )
	if ( stCEDHandleIsOpen() )				
		sText += ".... and has been (re)opened  (hnd = " + num2str( nHndAfter )+ ")"
		
		// we get 1401 type and memory size right here in the middle of  CEDGetStatus() because  1401 must be open.. 
		// ..we also print 1401 type and memory right here (before the status line is printed) but we could also disable printing here (ErrShow=0) and print 'nSize' and 'nType' later
		if ( ErrShow )
			printf "\tCEDStatus: "
			variable	nDriverType = stCEDDriverType( ErrShow )			
			printf "\tCEDStatus: "
			variable	nType	   = stCEDType( nHndAfter, ErrShow )			
			printf "\tCEDStatus: "
			variable	nSize	   = stCEDGetMemSize( nHndAfter, ErrShow )	
		endif
	else
		sText += ".... but cannot be opened: defective? off?  (new hnd:" + num2str( nHndAfter ) + ")  "// attempt to open  was not successfull..
	endif
	if ( bCEDWasClosed )								// CED was closed at  the beginning so close it again
		nHndAfter	= xCedClose( nHndAfter )								// ..so restore previous closed state  (no messages!)
		stCedHandleSet( CED_NOT_OPEN )
		sText += ".... and has been closed again (hnd = " + num2str( CedHandle_() ) + ")"
	endif
	printf "\tCEDStatus:\t%s \r", sText
End


static Function /S 	stCedErrorString( state ) 
	variable	state
	string  	sTxt	= "OK"
	if ( state )
		sTxt	= xCedGetErrorString( state )
	endif
	return	sTxt
End


static constant	CED_NOT_OPEN  	= -1		

static Function	stCedHandleSet( hnd )
	variable	hnd
	variable /G root:uf:CedHnd = hnd	// store directly in root:uf so that it can also be accessed  from FPuls V3xx and from V4xx
End 

Function		CedHandle_()
// only the handle under program control (not the 1401 itself) is checked, if the open 1401 is accidentally turned off this function gives the wrong result 
	nvar /Z hnd	= root:uf:CedHnd	// store directly in root:uf so that it can also be accessed  from FPuls V3xx
	if ( ! nvar_exists( hnd ) )
		return	CED_NOT_OPEN
	else
		return	hnd
	endif
End 


static Function	stCEDHandleIsOpen()
// only the handle under program control (not the 1401 itself) is checked, if the open 1401 is accidentally turned off this function gives the wrong result 
//	return ( xCEDGetHandle()  !=  CED_NOT_OPEN )
	return ( CedHandle_()  !=  CED_NOT_OPEN )
End 

//==================================================================================================================================================
//    STATUS  BAR   ( FUNCTION  VERSION  WITH  DEPENDENCIES )

static Function	stNewStatusBar( sSBNm, sSBTitle )	
// Implemented as kGRAPH (not panel! ) for TextBox to work .   Implemented as function .  kGRAPH WINDOW coordinates are POINTS
	string 	sSBNm, sSBTitle
	if ( winType( sSBNm ) != kGRAPH )								// The desired status bar does not exist....
		KillGraphs( ksSB_WNM + "*", ksW_WNM )						// ..so kill any other status bar that might exist...
		PauseUpdate; Silent 1									// ..and build the desired status bar 
		variable	Ysize		= 31 									//?  has minimum of about 20..
		variable	YControlBar	= 22								// if not desired set to 0  AND  comment out  'ControlBar  YControlBar'  below
		variable	rxMinPoints, rxMaxPoints, ryMinPoints, ryMaxPoints 
	 	GetIgorAppPoints( rxMinPoints, rxMaxPoints, ryMinPoints, ryMaxPoints )	// parameters changed by function
		// print  "NewStatusBar(" , sSBNm, ")  points  X..",   rxMinPoints, "..XR",  rxMaxPoints,  "Y...",  ryMinPoints, "...YB",  ryMaxPoints,  "appPixX", GetIgorAppPixel( "X" ),  "appPixY", GetIgorAppPixel( "Y" )
	
		Display	 	/K=1   /W=( rxMinPoints,     ryMaxPoints - ySize + 2, rxMaxPoints, ryMaxPoints + 2 ) as sSBTitle
// 080503 : ???? the following line  with  YControlBar  is not needed??? ( statusbar in readcfs worked without??? )
		ControlBar 	YControlBar
		DoWindow	/C $sSBNm
	
		// SetFormula gVar1, "gVar + 1"		// creates a dependency in a function, in Macro gVar1 := gVar + 1
		
		// TextBox: can only be used in graphs (not in panels), updates automatically (no explicit dependencies necessary)
		// Write the Cursor/Point/Region values into the LOWER statusbar line = one TextBox   (not here: upper=ValDisplay)
	
		// Igor requires to split the statusline into multiple textboxes because of the 400 characters per line limit  ( 3 with /MC is not good as it overwrites the end of the preceding field on 800x600)
		// Igor requires to split the statusline into multiple textboxes because of the 400 characters per line limit: Splitting into 2 instead of 3  blocks does not look very nice but avoids overwriting text...
		TextBox /A=LC /X=0 /F=0 "  Stim: \\{root:uf:aco:script:gsScriptPath}     Data: \\{root:uf:aco:cfsw:gsDataPath}\\{root:uf:aco:cfsw:gsDataFileW}     Pred:\\{\"%4.2lf\",root:uf:aco:keep:gPrediction}    Lag:\\{\"%2ds\", LaggingTime()}    Blk:\\{root:uf:aco:disp:gPrevBlk} / \\{root:uf:aco:keep:wG[kBLOCKS]}    Swp:\\{root:uf:aco:keep:wG[kSWPS_WRITTEN]} / \\{ root:uf:aco:keep:wG[kTOTAL_SWPS] } "
	
		TextBox /A=RC /X=0 /F=0 " Time:\\{\"%2d / %2d  \", TimeElapsed_(), root:uf:aco:keep:wG[kTOTAL_US]/1e6 }   \\{root:uf:aco:cfsw:gsAllGains} "	// Cannot use access function as this would inhibit the automatical update ??? how does LaggingTime() work???
		//TextBox /A=RC /X=0 /F=0 " Time:\\{\"%2d / %2d  \", TimeElapsed_(), root:uf:stim:gTotalStimMicroSc/1e6 }   \\{AllGainsInfo() } "	// Cannot use access function as this would inhibit the automatical update ??? how does LaggingTime() work???
	
		// ValDisplay: can be used in panels or in controlbars in graphs, invalid arguments can be ignored by using #, updates automatically (no explicit dependencies neccessary)????
		ValDisplay vd1,  pos={0,2},  size={120,15},  title="Pred",  format="%4.2lf",  limits={ 0,2,1},  barmisc={0,32},  value= #"root:uf:aco:keep:gPrediction", lowColor=(65535,0,0), highColor=(0,50000,0)
	
		StatusBarLiveDisplays( sSBNm )
	endif
End
 
Function		StatusBarLiveDisplays( sSBNm )
	string 	sSBNm
	// update region location in status bar 
	// Write the Cursor/Point/Region values into the UPPER statusbar line = multiple ValDisplay m   (not here: lower=TextBox)
//	ValDisplay sbCursX,		win = $sSBNm,  pos={200,3},   size={110,14}, title= "Cursor:X",	format= "%.1lf",  value= #"root:uf:aco:disp:gCursX"
	ValDisplay sbCursX,		win = $sSBNm,  pos={200,3},   size={110,14}, title= "Cursor:X",	format= "%.3lf",  value= #"root:uf:aco:disp:gCursX"	// 04mar02 ms -> s
	ValDisplay sbCursY,		win = $sSBNm,  pos={280,3},   size={80,14},   title= "       Y",		format= "%.1lf",  value= #"root:uf:aco:disp:gCursY"
	ValDisplay sbWaveY,		win = $sSBNm,  pos={360,3},   size={80,14},   title= "W: Y",		format= "%.1lf",  value= #"root:uf:aco:disp:gWaveY"
	ValDisplay sbWaveMin,	win = $sSBNm,  pos={460,3},   size={80,14},   title= "W: min",	format= "%.1lf",  value= #"root:uf:aco:disp:gWaveMin"
	ValDisplay sbWaveMax,	win = $sSBNm,  pos={560,3},   size={80,14},   title= "W: max",	format= "%.1lf",  value= #"root:uf:aco:disp:gWaveMax"
	ValDisplay sbPntX,		win = $sSBNm,  pos={700,3},   size={100,14}, title= "Point:X",	format= "%.1lf",  value= #"root:uf:aco:disp:gPx"
	ValDisplay sbPntY,		win = $sSBNm,  pos={780,3},   size={80,14},   title= "       Y",		format= "%.1lf",  value= #"root:uf:aco:disp:gPy"
	ValDisplay sbRegLeft,	win = $sSBNm,  pos={900,3},   size={90,14},   title= "Reg:left",	format= "%.1lf",  value= #"root:V_left"
	ValDisplay sbRegRight,	win = $sSBNm,  pos={990,3},   size={80,14},   title= " right",		format= "%.1lf",  value= #"root:V_right"
	ValDisplay sbRegTop,	win = $sSBNm,  pos={1060,3}, size={80,14},   title= "     top",	format= "%.1lf",  value= #"root:V_top"
	ValDisplay sbRegBot,		win = $sSBNm,  pos={1140,3}, size={80,14},   title= "     bot",	format= "%.1lf",  value= #"root:V_bottom"
	ValDisplay sbCursX,		win = $sSBNm,  help={"Shows the current  X  coordinate of the cursor."}, 			limits={0,0,0}, barmisc={0,1000}
	ValDisplay sbCursY,		win = $sSBNm,  help={"Shows the current  Y  coordinate of the cursor."}, 			limits={0,0,0}, barmisc={0,1000}
	ValDisplay sbPntX,		win = $sSBNm,  help={"Shows the  X  coordinate of the last recently clicked point."},	limits={0,0,0}, barmisc={0,1000}
	ValDisplay sbPntY,		win = $sSBNm,  help={"Shows the  Y  coordinate of the last recently clicked point."},	limits={0,0,0}, barmisc={0,1000}
	ValDisplay sbRegLeft,	win = $sSBNm,  help={"Shows the  left  coordinate of the last recently active region."}, 	limits={0,0,0}, barmisc={0,1000}
	ValDisplay sbRegRight,	win = $sSBNm,  help={"Shows the right coordinate of the last recently active region."},	limits={0,0,0}, barmisc={0,1000}
	ValDisplay sbRegTop,	win = $sSBNm,  help={"Shows the  top  coordinate of the last recently active region."}, 	limits={0,0,0}, barmisc={0,1000}
	ValDisplay sbRegBot,		win = $sSBNm,  help={"Shows the bottom coordinate of the last recently active region."},limits={0,0,0}, barmisc={0,1000}
End


//==================================================================================================================================================
//  TEST  FUNCTIONS

// 2010-03-29
Function		fTestAcq_( s )
// Only available in the Misc panel in DEBUG mode
	struct	WMButtonAction &s
	printf "\r\tTestAcq_ \tHeapScramble_ V3\r"
	stHeapScramble_()
End

static Function	stHeapScramble_()
// Try to reproduce the 'Can not SetTranferArea' Error.  This error occured multiple times within 1 loop (~2 minutes)   before the code was changed to 1.FIXED  and 2. SMALLER  TranferArea size  ( 2010-03-29 )

	string  	sDir		= "D:UserIgor:FPuls_:Scripts:ErrorAndUserScripts:"			// 36 scripts
	//string  	sDir		= "D:UserIgor:FPuls_:Scripts:ErrorScripts:"				// 73 scripts
	//string  	sDir		= "D:UserIgor:FPuls_:Scripts:AllUserScripts:"			// 36 scripts

	string  	lstScripts	= ListOfMatchingFiles( sDir, "*.txt", FALSE )
	string  	sTxt	= "\rTestAcq_ :  Heap scramble + AutoLoadScripts\r'" + sDir + "'\r************Can only be stopped with  'Abort' *************"
	DoAlert 0, sTxt
	printf "\r%s\rWill continuously load %d scripts from '%s'  '%s' \r", sTxt, ItemsInList(lstScripts), sDir, lstScripts[ 0, 200 ]
	
	variable	n, nScripts	= ItemsInList( lstScripts )
	variable	cnt	= 0

	// Load all files once in predefined order. This ALWAYS triggered the 'Can not SetTranferArea' Error  (before changing the code to 1.FIXED  and 2. SMALLER  TranferArea size 2010-03-29 )
	for ( n = 0; n < nScripts; n += 1 )
		LoadScriptFromList( n, lstScripts, sDir, cnt )
		cnt += 1
	endfor
		
	// Now  load all files in Random order  and try to trigger the error
	do
		n = round( abs( enoise( nScripts ) ) )
		n = max( 0, n )
		n = min( n, nScripts-1)

		LoadScriptFromList( n, lstScripts, sDir, cnt )
		cnt += 1
	while ( 1  )			// User may exit with  'Abort'  
End


Function		LoadScriptFromList( n, lstScripts, sDir, cnt )
	variable	n, cnt
	string  	lstScripts, sDir
	variable	nScripts	= ItemsInList( lstScripts )
	string  	sScript	= sDir + StringFromList( n, lstScripts ) 
	string  	sFileName	= StripPathAndExtension( sScript )

	// It would be more reliable to exclude file containing the keyword 'FPULS4'
	if ( strlen( sFileName ) == strlen( RemoveEnding( sFileName, "_" ) )	 )			// exclude FPULS4  files  which end with  '_' (only when auto-converted from V3 to V4 )

		printf "\t%3d/%3d/%3d \t", n, nScripts, cnt							// 'LoadScript_'  below will append the script file name
		svar		gsScriptPath	= root:uf:aco:script:gsScriptPath
		variable	rCode
		gsScriptPath	= LoadScript_(  sScript, rCode, kbKEEP_ACQ_DISP)		
	endif
End
	

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

