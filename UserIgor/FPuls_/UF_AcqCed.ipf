//// UF_AcqCed.ipf
//
//
////	wave  	wG		= $"root:uf:" + sFo + ":" + UFPE_ksKPwg + ":wG"  	// This  'wG'  	is valid in FPulse ( Acquisition )
////	wave  /T	wIO		= $"root:uf:" + sFo + ":ar:wIO"  			// This  'wIO'   	is valid in FPulse ( Acquisition )
////	wave 	wRaw	= $"root:uf:" + sFo + ":" + UFPE_ksKEEPwr + ":wRaw"// This  'wRaw' 	is valid in FPulse ( Acquisition )
////	wave  /T	wVal		= $"root:uf:" + sFo + ":ar:wVal"  			// This  'wVal'  	is valid in FPulse ( Acquisition )
////	wave 	wFix		= $"root:uf:" + sFo + ":ar:wFix"  			// This  'wFix'  	is valid in FPulse ( Acquisition )
////	wave 	wE		= $"root:uf:" + sFo + ":ar:wE"  			// This  'wE'  	is valid in FPulse ( Acquisition )
////	wave 	wBFS	= $"root:uf:" + sFo + ":ar:wBFS" 			// This  'wBFS'  	is valid in FPulse ( Acquisition )
////
//// UF_AcqCed.ipf
//// 
//// Routines for 
////	continuos data acquisition and pulsing  using  CED hardware and IGORs background timer 
////	controlling the CED digital output 
////	measuring time durations spent in various program parts
////
//// For the acquisition to work there must be IGOR extensions (= CED1401.XOP)  and  a SHORTCUT  to Wavemetrics\Igor Pro Folder\IgorExtensions
//// CFS32.DLL  and  USE1432.DLL  must be accessible (copy to Windows\System directory)
//
//// History:
//// MAX. DATA RATES: ( 2xAD incl. TG, 2xDA, 1xDigOut), PCI interface
//// 1401POWER:  4 us works,   3 us does'nt work at all
//// 1401PLUS:     25 us works, 20 us does'nt work reliably (after changing to Eprom V3.22, previously much less)
//
//// 2003-0130	todo check why 16bit Power1401 +-5V range  makes  .9mV steps (should give .153mV steps!)
//// 2003-0313 wrapped  'Protocol' loop around the digital output (Digout pulses were output only in protocol 0 and were missing in all following protocols)
//// 2003-0320	periods between digout pulses can now be longer than 65535 sample intervals 
//// 2003-0707 major revision of digital output 
//// 2003-0805 major revision of acquisition 
//
//// 2004-0224	introduced  UFP_CedWorkingSet( 800, 4000, 0 )
//// Dear Ulrich,
//// It looks as if the changes to Use1432 are OK, so I am sending you the new library to try out. The new function added is defined as:
////
//// U14API(short) U14WorkingSet(DWORD dwMinKb, DWORD dwMaxKb);
////
//// it returns zero if all went well, otherwise an error code (currently a positive value unlike other functions). 
//// To use it, you should call it once only at the start of your application - I'm not sure how that will apply to you. 
//// I suggest using values of 800 and 4000 for the two memory size values, they are known to work fine with CED software.
//// Best wishes, Tim Bergel
//
//
//
////? todo the amplitude of the last blank is held appr. 1s until it is forced to zero (by StopADDA()?) . This is a problem only when the amp is not zero. Workaround: define a dummy frame thereafter.  
////? todo  is it necessary that DigOut times are integral multiples of smpint ....if yes then check.... 
//  
//#pragma rtGlobals=1								// Use modern global access method.
//
//	 strconstant ksTBL_ACQ = "tbAcq"
//
//static   constant    cDRIVERUNKNOWN 	= -1 ,  cDRIVER1401ISA	= 0 ,  cDRIVER1401PCI = 1 ,  cDRIVER1401USB = 2
//static strconstant  sCEDDRIVERTYPES	= "unknown;ISA;PCI;USB;unknown3" 
//static   constant    c1401UNKNOWN   	= -1 ,  c1401STANDARD	= 0 ,  c1401PLUS = 1 ,   c1401MICRO = 2 ,  c1401POWER = 3 ,  c1401MICRO_MK2 = 4 ,  c1401POWER_MK2 = 5 ,  c1401MICRO_3 = 6 ,   c1401UNUSED = 7
//static strconstant  sCEDTYPES			= "unknown;Standard 1401;1401 Plus;micro1401;Power1401;micro1401mkII;Power1401mkII;micro1401-3;unknown/unused"	//  -1 ... 4
//
//static constant	nTICKS				= 10			//20 		// wait nTICKS/60 s between calls to background function
//
//static constant	cMAX_TAREA_PTS 		= 0x080000 	// CED maximum transfer area size is 1MB under Win95. It must explicitly be enlarged under  Win2000
//
//static constant	cADDAWAIT			= 0
//static constant	cADDATRANSFER		= 1
//
//static	constant	cBKG_UNDEFINED		= 0
//static	constant	cBKG_IDLING			= 1			// defined but not running
//static	constant	cBKG_RUNNING		= 2
//
//static	constant	cBKG_RUN_ALWAYS	= 0			// 0 : normally in the SW trig mode (=Start) the Bkg task is turned on and off.  1 lets is run continuously as it does in the HW trig mode (=E3E4)
//
//static constant	cFAST_TG_COMPRESS	= 255		// set to >=255 for maximum compression , will be clipped and adjusted to the allowed range  1...255 / ( nAD + nTG ) 
//
////  CEDError.H  AND FPULSE.IPF : Error handling: where and how are error messages displayed
//constant		ERR_AUTO_IGOR		= 8			// IGORs automatic error box :lookup CED error string in xxxWinCustom.RC
//constant		ERR_FROM_IGOR		= 16			// custom error box: lookup CED error string in xxxWinCustom.RC
//constant		ERR_FROM_CED		= 32			// custom error box: get CED error string from U14GetString() 
//// combinations of the flags above:
//static constant		kMSGLINE_C			= 38			// 32 + 4 + 2 	// always: print  all 1401 messages and errors using  Ced strings but  displays no error box (for debug)
//static constant		kERRLINE_C			= 34			// 32 + 2 		// on error: error line using  Ced strings
//static constant		KERRLINE_I 			= 18			// 16 + 2		// on error: error line using IGOR xxxWinCustom.RC strings
//static constant		kERRBOX_C			= 33			// 32 + 1		// on error: error box  using  Ced strings
//static constant		kERRBOX_I 			= 17			// 16 + 1 		// on error: error box  using IGOR xxxWinCustom.RC strings
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////   ACQUISITION  FUNCTIONS
//
//
//strconstant	UFPE_ksCO	= "co"
//
//
//Function		StartActionProc( sFo, sSubFoC, sSubFoW )
//	string  	sFo, sSubFoC, sSubFoW
//	variable	bTrigMode		= TrigMode()
//	variable	bAppendData	= AppendData()
//	nvar		gbRunning	= $"root:uf:acq:" + UFPE_ksKEEP + ":gbRunning"
//
//	 printf "\t\tStartStopActionProc()   bTrigMode:%.0lf   cbAppndData:%.0lf    gbRunning:%.0lf  sFo:%s  sSubFoC:%s \r", 	bTrigMode, bAppendData, gbRunning, sFo, sSubFoC
//	StartStopFinishButtonTitles( sFo, sSubFoC )
//
//	if ( bTrigMode == 0 )	 	// SW triggered normal mode
//		if ( ! gbRunning )
//			StartStimulusAndAcquisition( sSubFoC, sSubFoW )
//		endif
//	endif
//End
//
//
//Function		FinishActionProc( sFo, sSubFoC, sSubFoW )
//	string  	sFo, sSubFoC, sSubFoW 
//	variable	bTrigMode		= TrigMode()
//	variable	bAppendData	= AppendData()
//	nvar		gbRunning 	= $"root:uf:acq:" + UFPE_ksKEEP + ":gbRunning"
//	nvar		gbAcquiring 	= $"root:uf:acq:" + sSubFoC + ":gbAcquiring"
//	nvar		bIncremFile 	= $"root:uf:acq:" + sSubFoC + ":gbIncremFile"
//
//	 printf "\t\tFinishActionProc(entry) \traTrigMode:%.0lf   AppendData:%.0lf    gbRunning:%.0lf   bIncremFile:%.0lf  \r", 	bTrigMode, bAppendData, gbRunning, bIncremFile
//	StartStopFinishButtonTitles( sFo, sSubFoC )
//
//	if ( bTrigMode == 0  )								// SW  triggered normal mode
//		FinishFiles()
//		if ( gbAcquiring )
//			StopADDA( "\tUSER ABORT1" , UFCom_FALSE, sSubFoC, sSubFoW  )		//  FALSE: do not invoke ApplyScript()
//			gbAcquiring = UFCom_FALSE						// normally this is set in 'CheckReadyDacPosition()'  but user abortion is not handled there correctly 
//		endif
//	endif
//	if ( bTrigMode == 1 )								// HW E3E4 trigger
//		FinishFiles()								// close CFS file so that next acquisition is written to a new file
//		if ( gbAcquiring )								// abort only when user pressed 'Finish' during the stimulus/acquisition phase,... not during the waiting phase: 
//			StopADDA(  "\tUSER ABORT2" , UFCom_FALSE, sSubFoC, sSubFoW )		//  FALSE: do not invoke ApplyScript()
//		endif
//	endif
//	if (  bAppendData )
//		bIncremFile	= UFCom_TRUE
//	endif
//	 printf "\t\tFinishActionProc( exit )  \traTrigMode:%.0lf   AppendData:%.0lf   gbRunning:%.0lf   bIncremFile:%.0lf  \r", 	bTrigMode, bAppendData, gbRunning, bIncremFile
//End
//
//
//Function		StartStimulusAndAcquisition( sSubFoC, sSubFoW )
//	string  	sSubFoC, sSubFoW
//	string  	sFo	= ksACQ
//	wave 	wG	= $"root:uf:" + sFo + ":" + sSubFoW + ":wG"  		
//	
//	variable	bTrigMode		= TrigMode()
//	variable	bAppendData	= AppendData()
//	nvar		bIncremFile	= $"root:uf:" + ksACQ + ":" + sSubFoC + ":gbIncremFile"
//	variable	code
//	string		bf
//// 2005-1201
//	wG[ UFPE_WG_SWPWRIT ]	= 0 
//	nvar	wgSwpWrit	= root:uf:acq:pul:svSwpsWrt0000
//	wgSwpWrit	= 0
//	
//	if ( wG[ UFPE_WG_PNTS ]  )
//		variable	nRadDebgGen	= UFCom_DebugDepthGen()
//		if ( nRadDebgGen )
//			printf "\tSTARTING ACQUISITION %s %s... \r", SelectString( bTrigMode, " ( after 'Start' , " , " ( waiting for trigger on E3E4, "  ),  SelectString( bAppendData, "writing separate files )", "appending to same file )" ) 
//		endif
//
//// 2007-0402   removed because it kills   UFCom_StartTimer( sFo, "LoadScr" )
////		UFCom_KillAllTimers()
//
//		// This function merely starts the sampling (=background task). This function is finished already at the BEGINNING of the sampling!
//// 2008-06-06	
////		code	= CedStartAcq()									// the error code is not yet used 
//		code	= CedStartAcq( sSubFoC )							// the error code is not yet used 
//
//	else
//		UFCom_FoAlert( sFo, UFCom_kERR_LESS_IMPORTANT,  "Empty stimulus file..... " ) 
//	endif
//	if ( ! CEDHandleIsOpen() )
//		UFCom_FoAlert( sFo, UFCom_kERR_IMPORTANT, "The CED 1401 is not open. " )			// acquisition will start but only in test mode with fake data
//	endif
//End	
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//
//
//
//
//Function		CEDInitialize( sFo )
//// The  CED initialization code must take care of special cases:				( new  031210 )
////	- ApplyScript()	with 1401 not present or switched off : go into test mode
////	- ApplyScript()	with 1401 just switched on
////	- ApplyScript()	after the user switched the 1401 off and on again (perhaps to recover from a severe error)
////  More elaborate code checking the interface type but avoiding unnecessary initialisations : 
//// ??? Logically the initialization every time even when the 1401 is already 'on' is NOT required, but for unknown reasons  ONLY the  Power1401  and ONLY with USB interface will not work without it ( will  abort with a 'DIGTIM,OB;' error in SetEvents() ) .
//	string  	sFo
//	wave  	wG		= $"root:uf:" + sFo + ":" + UFPE_ksKPwg + ":wG"  	// This  'wG'  	is valid in FPulse ( Acquisition )
//	wave  /T	wIO		= $"root:uf:" + sFo + ":ar:wIO" 		 	// This  'wIO'  	is valid in FPulse ( Acquisition )
//	variable	nRadDebgGen		= UFCom_DebugDepthGen()
//	variable	nRadDebgSel		= UFCom_DebugDepthSel()
////	variable	pnDebgCed		= UFCom_DebugVar( "Ced" )
//	nvar		gnReps			= root:uf:acq:co:gnReps
//	nvar		gPntPerChnk		= root:uf:acq:co:gPntPerChnk
//	nvar		gbRunning		= $"root:uf:acq:" + UFPE_ksKEEP + ":gbRunning" 
//	nvar		gCedMemSize		= root:uf:acq:co:gCedMemSize
//	nvar		gnCompressTG		= root:uf:acq:co:gnCompressTg
//	nvar		gbSearchStimTiming	= $"root:uf:"+sFo+":mis:ImprStimTim0000"
//	nvar		gbRequireCed1401	= $"root:uf:"+sFo+":mis:RequireCed0000"
////	variable	gShrinkCedMemMB	= ShrinkCedMem()
//	variable	nSmpInt			= UFPE_SmpInt( sFo )
//	variable	nCntAD			= wG[ UFPE_WG_CNTAD ]	
//	variable	nCntDA			= wG[ UFPE_WG_CNTDA ]	
//	variable	nCntTG			= wG[ UFPE_WG_CNTTG ]	
//	variable	nPnts			= wG[ UFPE_WG_PNTS ] 
//
//	svar		gsDigoutSlices		= $"root:uf:" + sFo + ":dig:gsDigoutSlices"
//	variable	nSlices			= ItemsInList( gsDigoutSlices )							
//
//	variable	state, code, nCEDMemPts, nTrfAreaPts //= 1
//	string		bf
//
//	variable	ShowMode = ( nRadDebgGen == 2 ||  ( nRadDebgSel > 1 &&  UFCom_DebugVar( "Ced" ) ) )    ? UFPE_MSGLINE : UFPE_ERRLINE	
//	variable	bMode	 = ( nRadDebgGen == 2  ||  ( nRadDebgSel > 1 &&  UFCom_DebugVar( "Ced" ) ) )    ? 	UFCom_TRUE  :  UFCom_FALSE
//
//	if ( UFCom_DebugDepthSel() > 0  &&  UFCom_DebugVar( "Ced" ) )
//		printf "\t\tCed CEDInitialize()  running: %d   \r", gbRunning
//	endif
//	//printf  "\t\tCed CEDInitialize()  running: %d   \r", gbRunning
//	
//	if ( nPnts  &&  ! gbRunning )
//
//		if ( UFCom_DebugDepthSel() > 0  &&  UFCom_DebugVar( "Ced" ) )
//			printf "\t\tCed CEDInitialize()  running: %d    before checking UFP_CedState() \t \tCEDHandleIsOpen() : %d \r", gbRunning, CEDHandleIsOpen()
//		endif
//		//  ShowMode = kMSGLINE_C	
//		state	= UFP_CedState() 										// Check if CEDHandle is consistent with current Ced state. Set CEDHandle 'off'  if Ced state says 'off'  (happens if 1401 had been on but has just been switched off) 
//		if ( UFCom_DebugDepthSel() > 0  &&  UFCom_DebugVar( "Ced" ) )
//			printf "\t\tCed CEDInitialize()  running: %d    Ced1401 is %s\t(1+ code:%d)  \tCEDHandleIsOpen() : %d \r", gbRunning, SelectString( state + 1, "closed", "open" ),  state+1 , CEDHandleIsOpen()
//		endif
//		// Initialization is only executed once at startup, not with every new script
//		if ( ! CEDHandleIsOpen() ) 
//			// UFP_CedOpen()										// reduced functionality for testing (does not open - close - open )
//			// UFP_CedCloseAndOpen(  ERRBOX+ERR_FROM_IGOR )		// IGORs error box stops execution
//
//// 2007-0401  TO  TEMPORARILY  SKIP THE  CED IS CLOSED ERROR : REACTIVATE AGAIN
////			UFP_CedCloseAndOpen(  kERRLINE_C )						// rather than kERRLINE_C    _temporarily_!  0 may be passed to skip the 'Ced is closed' error
//			UFP_CedCloseAndOpen(  0 )						
//
//			if ( CEDHandleIsOpen() ) 								
//				code		= CEDInit1401DACADC( ShowMode )				// The Ced was off and has just been switched on
//				if ( code )
//					UFP_CedClose( kMSGLINE_C )
//					return	code
//				endif
//				gCEDMemSize	= CEDGetMemSize( 0 )					// with the Ced connected and 'on' the actual memory size is used
//				SetShrinkCedMem( gCEDMemSize / UFPE_kMBYTE )			// Set the SetVariable  with the true Ced memory only once after switching the Ced on. The user may decrease this value later.
//			else
//				if ( FP_IsRelease()  &&  gbRequireCed1401 )	// 
//					UFCom_FoAlert( sFo, UFCom_kERR_FATAL,  "Ced  is not responding. The test mode does not require a Ced1401.  Uncheck  'Require Ced..'  in the  'Misc'  panel.  Aborting..." )
//					UFP_CedClose( kMSGLINE_C )
//					return	UFCom_kERROR
//				endif
//				gCEDMemSize	= UFPE_kTESTCEDMEMSIZE				// without Ced the default  UFPE_kTESTCEDMEMSIZE  is used  as upper limit for the SetVariable
//			endif
//			if ( ShrinkCedMem()  == 0 )									// true only during the VERY FIRST program start (CED may be off or on) : initially set the SetVariable...
//				SetShrinkCedMem( gCEDMemSize / UFPE_kMBYTE )			// ...with the true Ced memory size value or with TESTMEMSIZE. The user may decrease this value later.
//			endif													// in all further calls : use as memory size the value which the user has deliberately decreased...
//		endif
//
//		// Called  with every  'ApplyScript()'  :  react on a changed trigger mode
//		if ( CEDHandleIsOpen() ) 
//
//			// ??? Logically this initializing is NOT required, but for unknown reasons  ONLY the  Power1401 and ONLY with USB interface will not work without it ( will  abort with a 'DIGTIM,OB;' error in SetEvents() ) .
//			variable	nDriverType  = CEDDriverType( bMode )	
//			variable	nCedType	    = CEDType( bMode )	
//			if ( nCedType == c1401POWER  &&   nDriverType == cDRIVER1401USB )	// ONLY the  USB Power1401 needs (normally unnecessary)  reinitialisation
//				code	  = CEDInit1401DACADC( bMode )			
//			endif
//
//
//
//
//			code		= CedSetEvent( sFo, bMode )
//			if ( code )
//				UFP_CedClose( kMSGLINE_C )
//				return	code
//			endif
//		endif
//		
//		
//		// Called  with every  'ApplyScript()'  :  react on a changed memory size which the user may have deliberately decreased...
////		if ( gShrinkCedMemMB == 0 )								// 2005-1108  due to some error  'gShrinkCedMemMB'  was 0.  Now we recover from this error without requiring a new start of FPulse
////			gShrinkCedMemMB	= gCEDMemSize / UFPE_kMBYTE				// like above
////		endif
////		if ( ShrinkCedMem() == 0 )								// 2005-1108  due to some error  'gShrinkCedMemMB'  was 0.  Now we recover from this error without requiring a new start of FPulse
////			SetShrinkCedMem( gCEDMemSize / UFPE_kMBYTE )				// like above
////		endif
//		
//		nCEDMemPts	= ShrinkCedMem() * UFPE_kMBYTE / 2				// ..thereby improving loading speed  but unfortunately  making the maximum Windows interruption time much smaller...
//		
//		
//		if ( gbSearchStimTiming )			
//			SearchImprovedStimulusTiming( sFo, wG, nCEDMemPts, nPnts, nSmpInt, nCntDA, nCntAD, nCntTG, nSlices )
//		endif
//
//		nTrfAreaPts	= SetPoints( sFo, nCEDMemPts, nPnts, nSmpInt, nCntDA, nCntAD, nCntTG, nSlices, UFCom_kERR_IMPORTANT, UFCom_kERR_FATAL )	// all params are points not bytes	
//
//		if ( nTrfAreaPts <= 0 )
//			sprintf bf, "The number of stimulus data points (%d) could not be divided into CED memory without remainder. \r\tAdjust duration(s) in stimulus protocol slightly so that data points contains more small primes." , nPnts
//			string		lstPrimes	= UFCom_FPPrimeFactors( sFo, nPnts )			// list containing the prime numbers which give 'nPnts'
//			UFCom_FoAlert( sFo, UFCom_kERR_FATAL,  bf + "   " + lstPrimes[0,50] )
//			return UFCom_kERROR				
//		endif
//		// here 051108
//		if ( UFPE_kELIMINATE_BLANK )			
//			UFPE_StoreChunkSet( sFo, "co", wG )																			// after SetPoints() : needs nPnts and gnPntPerChk
//		endif
//
//		wave  /Z	wRaw	= $"root:uf:" + sFo + ":" + UFPE_ksKEEPwr + ":wRaw"	// 2004-1203 must be PERMANENT data folder, will give sporadic heap scramble problems if a regularly cleared folder (e.g.ar) is used	
//														// 2005-0128..050205 ????? why ??? was is this error....?
//		// printf "\t\tCEDInitialize(1 '%s' ) \texists wRawDDA: %d   points: \t%8d\t  TAPts: \t%8d \r", sFo, waveExists( wRaw ),  waveExists( wRaw ) ? numPnts(wRaw) : -1 , nTrfAreaPts // 2005-0128
//
//		if ( waveExists( wRaw ) )
//			if ( CEDHandleIsOpen() )
//				code	= UFP_CedUnsetTransferArea( 0, wRaw, ShowMode ) 	// the attempt to unset a non-existing transfer area  (=error -528)  will do no harm as it is caught in the XOP
//				if ( code != 0   &&   code != -528 )							// this error -528 will occur after having been in test mode and then switching the Ced on
//					UFP_CedClose( kMSGLINE_C )
//					KillWaves		wRaw
//					return	code
//				endif
//			endif
//			KillWaves		wRaw
//		endif
//		make  	/W /N=( nTrfAreaPts )  $"root:uf:" + sFo + ":" + UFPE_ksKEEPwr + ":wRaw" 		// allowed area 0, allowed size up to 512KWords=1MB , 16 bit integer
//		// print "050128 make  /W \twRaw",  nTrfAreaPts
//		wave	wRaw		= $"root:uf:" + sFo + ":" + UFPE_ksKEEPwr + ":wRaw"			// 2004-1203 must be PERMANENT data folder, will give sporadic heap scramble problems if a regularly cleared folder (e.g.ar) is used	
//
//		// Go into acquisition  either  without CED for the  test mode  or  with CED only when transfer buffers are ok, otherwise system hangs... 
//		// printf "\t\tCEDInitialize(2 '%s' ) \texists wRawDDA: %d   points: \t%8d\t  TAPts: \t%8d \r", sFo, waveExists( wRaw ),  waveExists( wRaw ) ? numPnts(wRaw) : -1 , nTrfAreaPts
//		if ( ! CEDHandleIsOpen()  ||  UFP_CedSetTransferArea( 0, nTrfAreaPts, wRaw , ShowMode ) == 0 ) 
//			// printf "\t\tCEDInitialize(3 '%s' ) \texists wRawDDA: %d   points: \t%8d\t  TAPts: \t%8d \r", sFo, waveExists( wRaw ),  waveExists( wRaw ) ? numPnts(wRaw) : -1 , nTrfAreaPts
//			if ( CEDInitializeDacBuffers( sFo, wRaw ) )						// ignore 'Transfer' and 'Convolve' times here during initialization as they have no effect on acquisition (only on load time)
//				return	UFCom_kERROR
//			endif
//		else
//			UFCom_FoAlert( sFo, UFCom_kERR_FATAL,  "Could not set transfer area. Try logging  in as Administrator. Aborting..." )
//			return	UFCom_kERROR
//		endif
//
//
//		if ( SupplyWavesADC( sFo, wG, wIO, nPnts ) )							// constructs 'AdcN' and 'AdcTGN' waves  AFTER  PointPerChunk  and  CompressTG  has been computed
//			return	UFCom_kERROR			
//		endif			
//		if ( SupplyWavesADCTG( sFo, wG, wIO, nPnts ) )
//			return	UFCom_kERROR			
//		endif			
//
//		TelegraphGainPreliminary( sFo, wG, wIO )		
//
//	else
//		UFCom_FoAlert( sFo, UFCom_kERR_LESS_IMPORTANT,  "Empty stimulus file  or  stimulus/acquisition is already running. " ) 
//	endif
//
//	return  0	
//End
//
//
//static Function		CEDInitializeDacBuffers( sFo, wRaw )
//	// Acquisition mode initialization with Timer and swinging buffer 
//	// Although the following variables are declared GLOBAL they should be used like STATIC (only  within this procedure file) !
//	// Global as they must be accessed in MyBkgTask()  and  as their access should be fast..(how slow/fast are access functions?) 
//	string  	sFo
//	wave	wRaw
//	wave  	wG		= $"root:uf:" + sFo + ":" + UFPE_ksKPwg + ":wG"  // This  'wG'  	is valid in FPulse ( Acquisition )
//	wave  /T	wIO		= $"root:uf:" + sFo + ":ar:wIO"  				// This  'wIO'   	is valid in FPulse ( Acquisition )
//	nvar		gnReps			= root:uf:acq:co:gnReps
//	nvar		gChnkPerRep		= root:uf:acq:co:gChnkPerRep
//	nvar		gPntPerChnk		= root:uf:acq:co:gPntPerChnk
//	nvar		gnCompressTG		= root:uf:acq:co:gnCompressTG
//	nvar		gMaxSmpPtspChan	= root:uf:acq:co:gMaxSmpPtspChan
//	variable	nSmpInt			= UFPE_SmpInt( sFo )
//	variable	nCntDA			= wG[ UFPE_WG_CNTDA ]	
//	variable	nCntAD			= wG[ UFPE_WG_CNTAD ]	
//	variable	nCntTG			= wG[ UFPE_WG_CNTTG ]	
//	variable	nPnts			= wG[ UFPE_WG_PNTS ] 
//	nvar	 	gnOfsDA			= root:uf:acq:co:gnOfsDA
//	nvar		gSmpArOfsDA		= root:uf:acq:co:gSmpArOfsDA
//	nvar		gnOfsAD			= root:uf:acq:co:gnOfsAD
//	nvar		gSmpArOfsAD		= root:uf:acq:co:gSmpArOfsAD	
//	nvar		gnOfsDO			= root:uf:acq:co:gnOfsDO
//	variable	nRadDebgSel		= UFCom_DebugDepthSel()
////	variable	pnDebgCed		= UFCom_DebugVar( "Ced" )
//	variable	SmpArStartByte,  TfHoArStartByte,  nPts,  	nChunk, code = 0
//	string		bf , buf, buf1
//
//	variable	TAused		= TAuse( gPntPerChnk, nCntDA, nCntAD, cMAX_TAREA_PTS ) 
//	variable	MemUsed		= MemUse(  gChnkPerRep, gPntPerChnk, gMaxSmpPtspChan )
//	variable	FoM			= FigureOfMerit( gChnkPerRep, gPntPerChnk, gMaxSmpPtspChan, nCntDA, nCntAD, nCntTG, gnCompressTG, cMAX_TAREA_PTS ) 
//	variable	ChunkTimeSec	= gPntPerChnk * nSmpInt /  1000000
//	variable	SysMB1Chan	= gnReps * gChnkPerRep * gPntPerChnk * 4 / 1024 / 1024
//	variable	SysMBAllChan	= SysMB1Chan * ( nCntDA + nCntAD + nCntTG / gnCompressTG )
//	variable	nTapePts 		= wG[ UFPE_WG_PNTS ] 				// or store in and retrieve from wG[ TPPTS ]  or  numpnts( wBigIO ).........
//
//	nvar		gbRunning	= $"root:uf:acq:" + UFPE_ksKEEP + ":gbRunning"
//	nvar		gbAcquiring	= root:uf:acq:co:gbAcquiring
//
//	// Script memory splitting and script load timing: store information in table  'ksTBL_ACQ'  ,  display and append information to table 
//	variable	LoadMs	= -12
//	variable	OverallMs	= -13
//	variable	DigoutMs	= trunc( UFCom_ReadTimer_( sFo, "DigOut" )/1000 )
//	variable	DisplayMs	= trunc( UFCom_ReadTimer_( sFo, "Display" )/1000 )
//	variable	CedInitMs	= -14
//	// 2007-0401 Bad code: must introduce wFix to retrieve the number of frames which is used ONLY for debug print
//	wave  	wFix	 = $"root:uf:" + sFo + ":ar:wFix"  		
//	variable	FCnt = UFPE_eFrames( wFix, 0 ), SCnt =UFPE_eSweeps( wFix, 0 )
//
//	string  	sTxt = ""
//	string  	sFormatString	= AcqTblFormat()	
//	sprintf sTxt, sFormatString,  UFCom_pd(ScriptPath(sFo),50), gnReps, gChnkPerRep, gPntPerChnk, nCntDA, nCntAD, nCntTG, nSmpInt,  gnCompressTG, ChunkTimeSec, TAUsed, MemUsed, FoM, SysMB1Chan, SysMBAllChan, ELIMINATE_BLANKS()+10, nPnts/1000, nTapePts/1000, nPnts*nSmpInt/1000000, Time(), LoadMs, OverallMs, DigoutMs, CedInitMs, DisplayMs
////	sprintf sTxt, klstACQTIME_TBLTITLES0 + klstACQTIME_TBLTITLES1,  UFCom_pd( ScriptPath( sFo ), 50), gnReps, gChnkPerRep, gPntPerChnk, nCntDA, nCntAD, nCntTG, nSmpInt,  gnCompressTG, ChunkTimeSec, TAUsed, MemUsed, FoM, SysMB1Chan, SysMBAllChan, FCnt, SCnt, nPnts/1000, nPnts/(FCnt * SCnt), Time(), LoadMs, OverallMs, DigoutMs, CedInitMs, DisplayMs
//	// print sTxt
//	string  	sTitle		= "Acq Ced"
//	variable	bDisplay	= 1
//	variable	RowOfs	= 1		// 0 : into last row , 1: create new row
//	string  	sTbl		= ksTBL_ACQ
//	string  	sTbWvNm	= AcqTblWvNm( sFo, sTbl )
//	UFCom_MyTable( sFo, sTbWvNm, sTbl, sTitle, bDisplay, RowOfs, sTxt, "=", "\t" )
//	FP_LstDelWindowsSet( AddListItem( sTbl, FP_LstDelWindows() ) )	
//
//
//	if ( UFCom_DebugDepthSel() > 0  &&   UFCom_DebugVar( "Ced" ) )
//		printf "\t\tCed CedStartAcq()   CEDInitializeDacBuffers() \tRunning:%2g  Acquiring:%2d \r", gbRunning, gbAcquiring
//	endif
//	if ( UFCom_DebugDepthSel() > 1  &&   UFCom_DebugVar( "Ced" ) )
//		printf "\t\t\tCed CedStartAcq()  Rps:%d  ChkpRep:%d  PtpChk:%d  DA:%d  AD:%d  TG:%d  SmpInt:%3dus  Cmpr:%d  ReactTm:%.1lfs  TA:%d%%  Mem:%d%%  FoM:%.1lf%%  [%5.1lf /%5.1lf MB ]  OsDA:%d  OsAD:%d  OsDO:%d \r", gnReps, gChnkPerRep, gPntPerChnk, nCntDA, nCntAD, nCntTG, nSmpInt,  gnCompressTG, ChunkTimeSec, TAUsed, MemUsed, FoM, SysMB1Chan, SysMBAllChan, gnOfsDA, gnOfsAD, gnOfsDO 
//	endif
//	
//	// printf "\t\t\t\tCed Cnv>DA14>Cpy\t  IgorWave \t>HoSB \t=HoSB \t>TASB \t>SASB \t DAPnts\r"
//	for ( nChunk = 0; nChunk < gChnkPerRep; nChunk += 1)		
////MarkPerfTestTime 612	// CEDInitialize: Start Loop chunks
//		ConvolveBuffersDA( sFo, wIO, nChunk, 0, gChnkPerRep, nCntDA, gPntPerChnk, wRaw, gnOfsDA/2, nPnts )		// not UFPE_kPROT_AWARE
////MarkPerfTestTime 614	// CEDInitialize: ConvolveDA
//		if ( CEDHandleIsOpen() ) 
//
//			nPts   			= gPntPerChnk * nCntDA 
//		 	TfHoArStartByte		= gnOfsDA		+ 2 * nPts * mod( nChunk, 2 ) //  only  2 swaps
//			SmpArStartByte		= gSmpArOfsDA		+ 2 * nPts * nChunk 
//		
//if ( UFPE_kELIMINATE_BLANK )
//			variable	begPt	= gPntPerChnk * nChunk					// BegPt and EndPt are points in the CED sampling area (typ. 16MB) ....
//			variable	endPt	= gPntPerChnk * ( nChunk + 1 )				// The same BegPt and EndPt are passed multiple times if nReps is >1 (=long scripts and/or many protocols)
//			variable	repOs	= 0									// BegPt and EndPt  PLUS the repetition offset 'repOs' gives the true point number in the DAC wave independently from the CED sampling area size
//			variable	bStoreIt	= UFPE_StoreChunkorNot( sFo, nChunk )				
//			variable	BlankAmp	= wRaw[ TfHoArStartByte / 2  ]			// use the first value of this chunk as amplitude for the whole chunk
//			//if ( ( nRadDebgSel ==1  ||  nRadDebgSel == 3 )  &&  UFCom_DebugVar( "AcqDA" )  )
//				printf "\t\tAcqDA TfHoA1\t%8d\t ->\tSmpAr:\t %11d \t(pts:%8d)  \tBg:\t%7d\tNd:\t%7d\tChunk:\t%7d\tStoring:%2d\tAmp:\t%7d\t   \r", TfHoArStartByte, SmpArStartByte, nPts, BegPt+repOs, EndPt+repOs, nChunk, bStoreIt, BlankAmp
//			//endif
//			if (	bStoreIt )
//				 sprintf buf, "TO1401,%d,%d,%d;", TfHoArStartByte, 2*nPts, TfHoArStartByte ;  UFP_CedSendString( buf )  // copy  Dac data from host to Ced transferArea. Ced TransferArea and HostArea start at the same point
//				 code	+= GetAndInterpretAcqErrors( "SmpStart", "TO1401", nChunk, gnReps * gChnkPerRep )
////MarkPerfTestTime 615	// CEDInitialize: GetErrors TO1401
//			else
//				 sprintf buf, "SS2,C,%d,%d,%d;", TfHoArStartByte, 2*nPts, BlankAmp;  UFP_CedSendString( buf )  		// fill Ced transferArea with constant 'Blank' amplitude. This is MUCH faster than the above 'TO1401' which is very slow
//				 code	+= GetAndInterpretAcqErrors( "SmpStart", "SS2    ", nChunk, gnReps * gChnkPerRep )
////MarkPerfTestTime 616	// CEDInitialize: GetErrors SS2
//			endif
//else
//			 sprintf buf, "TO1401,%d,%d,%d;", TfHoArStartByte, 2*nPts, TfHoArStartByte ;  UFP_CedSendString( buf ) 		 // copy  Dac data from host to Ced transferArea. Ced TransferArea and HostArea start at the same point
//			 code	+= GetAndInterpretAcqErrors( "SmpStart", "TO1401", nChunk, gnReps * gChnkPerRep )
//endif
//
//
//			 sprintf buf,  "SM2,C,%d,%d,%d;", SmpArStartByte, TfHoArStartByte, 2*nPts;   UFP_CedSendString( buf )  		 // copy  Dac data from Ced transfer area to large sample area
////MarkPerfTestTime 617	// CEDInitialize: SendString SM2 Dac
//			 code	+= GetAndInterpretAcqErrors( "SmpStart", "SM2 Dac", nChunk, gnReps * gChnkPerRep )
////MarkPerfTestTime 618	// CEDInitialize: GetErrors SM2 Dac
//
//// combining is faster and theoretically possible, but the error detection will suffer
//// gh			 // TO1401 : TransferArea and HostArea start at the same point.   SM2 : Copy  Dac data from transfer area to large sample area
////			sprintf buf, "TO1401,%d,%d,%d;SM2,C,%d,%d,%d;", TfHoArStartByte, 2*nPts, TfHoArStartByte,    SmpArStartByte, TfHoArStartByte, 2*nPts ;
////			UFP_CedSendString( bguf )				
////			code	 = GetAndInterpretAcqErrors( "SmpStart", "TO1401 + SM2 Dac", nChunk, gnReps * gChnkPerRep )
//		endif
//	endfor
//	return	code
//End
//
//
//// 2008-06-06	
////Function		CedStartAcq()
//Function		CedStartAcq( sSubFoC )
//	// Acquisition mode initialization with Timer and swinging buffer 
//	// Although the following variables are declared GLOBAL they should be used like STATIC (only  within this procedure file) !
//	// Global as they must be accessed in MyBkgTask()  and  as their access should be fast..(how slow/fast are access functions?) 
//	string  	sSubFoC
////	string  	sSubFoC	= UFPE_ksCOns
//	string  	sFolders	= ksF_ACQ_PUL		
//	string  	sFo	= ksACQ		
//	wave  	wG		= $"root:uf:" + sFo + ":" + UFPE_ksKPwg + ":wG"  	// This  'wG'  	is valid in FPulse ( Acquisition )
//	nvar		gnReps		= root:uf:acq:co:gnReps
//	nvar		gnRep		= root:uf:acq:co:gnRep
//	nvar		gChnkPerRep	= root:uf:acq:co:gChnkPerRep
//	nvar		gPntPerChnk	= root:uf:acq:co:gPntPerChnk
//	nvar		gnChunk		= root:uf:acq:co:gnChunk
//	nvar		gnLastDacPos	= root:uf:acq:co:gnLastDacPos
//	nvar		gnAddIdx		= root:uf:acq:co:gnAddIdx
//	nvar		gReserve		= root:uf:acq:co:gReserve
//	nvar		gMinReserve	= root:uf:acq:co:gMinReserve
//	nvar		gErrCnt		= root:uf:acq:co:gErrCnt
//	nvar		gbAcquiring	= root:uf:acq:co:gbAcquiring	
//	nvar		gbRunning	= $"root:uf:acq:" + UFPE_ksKEEP + ":gbRunning"
//	nvar		gnTicksStart	= $"root:uf:acq:" + UFPE_ksKEEP + ":gnTicksStart"
//
//	nvar		gBkPeriodTimer	= root:uf:acq:co:gBkPeriodTimer
//	nvar		gPrevBlk		= root:uf:acq:pul:svPrevBlk0000
//	nvar		gnOfsDA		= root:uf:acq:co:gnOfsDA,	gSmpArOfsDA	= root:uf:acq:co:gSmpArOfsDA
//	nvar		gnOfsAD		= root:uf:acq:co:gnOfsAD,	gSmpArOfsAD	= root:uf:acq:co:gSmpArOfsAD	
//	variable	nSmpInt		= UFPE_SmpInt( sFo )
//	variable	nCntDA		= wG[ UFPE_WG_CNTDA ]	
//	variable	nCntAD		= wG[ UFPE_WG_CNTAD ]	
//	variable	nCntTG		= wG[ UFPE_WG_CNTTG ]	
//	nvar		gnOfsDO		= root:uf:acq:co:gnOfsDO
//
//	variable	bTrigMode		= TrigMode()
//	string		bf
//
//	if ( ArmDAC( sFo, gSmpArOfsDA, gPntPerChnk * nCntDA * gChnkPerRep, gnReps ) == UFCom_kERROR )
//		return	UFCom_kERROR						//  Avoid  the user ignoring this error and continuing . This error happens very rarely and is not understood...
//	endif
//	if ( ArmADC( sFo, gSmpArOfsAD, gPntPerChnk * (nCntAD+nCntTG) * gChnkPerRep, gnReps ) == UFCom_kERROR ) 
//		return	UFCom_kERROR						//  Avoid  the user ignoring this error and continuing . This error happens very rarely and is not understood...
//	endif
//	if ( ArmDig( sFo, gnOfsDO ) == UFCom_kERROR )
//		return	UFCom_kERROR						//  Avoid  the user ignoring this error and continuing . This error happens very rarely and is not understood...
//	endif	
//
//	UFCom_ResetTimer( sFo, "Convolve" )
//	UFCom_ResetTimer( sFo, "Transfer" )		
//	UFCom_ResetTimer( sFo, "Graphics" )		
//	UFCom_ResetTimer( sFo, "OnlineAn" )		
//	UFCom_ResetTimer( sFo, "CFSWrite" )		
//	UFCom_ResetTimer( sFo, "Process" )		
//	UFCom_ResetTimer( sFo, "TotalADDA" )		
//
//	// Establish a dependency so that the current acquisition status (waiting for 'Start' to be pressed, waiting for trigger on E3E4, acquiring, finished acquisition) is reflected in a ColorTextField
//	SetFormula	$"root:uf:"+sFo+":pul:gnAcqStatus0000", "root:uf:acq:" + UFPE_ksKEEP + ":gbRunning + 2 * root:uf:acq:co:gbAcquiring"	
//	
//	gbRunning	= UFCom_TRUE 								// 2003-1030
//	StartStopFinishButtonTitles( sFo, sSubFoC )						// 2003-1030 reflect change of 'gbRunning'  (ugly here...button text should change automatically) 
//
//	//  Never allow to go into 'LoadScriptxx()' when acquisition is running, because 'LoadSc..' initializes the program: especially waves and transfer area
//	UFCom_EnableButton( "pul", "root_uf_acq_pul_ApplyScript0000",	UFCom_kCo_DISABLE )	//  Never allow to go into 'LoadScriptxx()' when acquisition is running..
//	UFCom_EnableButton( "pul", "root_uf_acq_pul_LoadScript0000",	UFCom_kCo_DISABLE )	//  ..because 'LoadSc..' initializes the program: especially waves and transfer area
//	UFCom_EnableSetVar( "pul", "root_uf_acq_pul_gnProts0000",		UFCom_kCo_NOEDIT_SV  )	// ..we cannot change the number of protocols as this would trigger 'ApplyScript()'
//	UFCom_EnableButton( "pul", "root_uf_acq_pul_buDelete0000",	UFCom_kCo_DISABLE )	// 2005-05-30 Never allow deletion of the file which is currently written
//
//	//StartStopFinishButtonTitles( sFo )					// ugly here...button text should change automatically 050207weg
//
//	// set globals needed in ADDASwing ( background task function takes no parameters )
//	gnTicksStart	= ticks			// save current  tick count  (in 1/60s since computer was started) 
//	gnRep		= 1    
//	gnChunk		= 0    
//	gnAddIdx		= 0
//	gnLastDacPos	= 0
//	gReserve		= Inf
//	gMinReserve	= Inf
//	gErrCnt		= 0
//
//	//  for initialization of display : initialize with every new block
//	gPrevBlk		= -1
//
//	Process( sFolders, sFo, -1 )			//  PULSE  specific: for initialization of CFS writing
//
//	UFCom_StartTimer( sFo, "TotalADDA" )		
//
//	gBkPeriodTimer 	= 	startMSTimer
//	if ( gBkPeriodTimer 	== -1 )
//		printf "*****************All timers are in use 5...\r" 
//	endif
//
//	// Interrupting longer  than 'MaxBkTime' leads to data loss
//	//variable	SetTimerMilliSec = ( gPntPerChnk * nSmpInt ) / 1000 
//	// printf "\t\tCed CedStartAcq()  SmpInt:%d  SetTimerMilliSec:%d   TimerTicks:%d  TimerTicks(period):%d   MaxBkTime:%6dms  Reps:%d \r", nSmpInt, SetTimerMilliSec, SetTimerMilliSec/1000*60, nTICKS, SetTimerMilliSec * ( gChnkPerRep - 1 ),  gnReps 
//
//	// printBackGroundInfo( "CedStartAcq(5)" , "")
//
//
//
//// Old code from version 223 (03 Oct) : E3E4 triggering working !!!  To be deleted again !
////
////	BackGroundInfo	// 2003-1025
////	// printf "\t\t\tBackGroundInfo   '%s'  , v_Flag:%d :  is  %s ,  next scheduled execution:%d  \r ", s_Value, v_Flag, SelectString( v_Flag-1, "not defined", "defined but not running (idle)", "running" ), v_NextRun 
////	if ( v_Flag != 1)		// 2003-1025   for  the hardware triggered E3E4 mode : We call this function from the BackGround task function ( StopADDA() -> buStart() -> 'StartStimulusAndAcquisition'  ->  'CedStartAcq()'  ... 
////		// printf "\t\t\tBackGroundInfo   '%s'  , v_Flag:%d :  is  %s ,  next scheduled execution:%d  \r ", s_Value, v_Flag, SelectString( v_Flag-1, "not defined", "defined but not running (idle)", "running" ), v_NextRun 
////		SetBackground MyBackgroundTask()		// ...but it is not allowed (and we must avoid) to change a BackGround task function from within a BackGround task function 
////	endif
////
////	// Interrupting longer  than 'MaxBkTime' leads to data loss
////	//printf "\t\tAcq CedStartAcq()  SmpInt:%d  SetTimerMilliSec:%d   TimerTicks:%d  TimerTicks(period):%d   MaxBkTime:%6dms  Reps:%d \r", SmpInt, SetTimerMilliSec, SetTimerMilliSec/1000*60, nBkgTicks,SetTimerMilliSec * ( ChunkspRep - 1 ),  nReps
////	sprintf bf, "\t\tAcq CedStartAcq()  SmpInt:%d  SetTimerMilliSec:%d   TimerTicks:%d  TimerTicks(period):%d   MaxBkTime:%6dms  Reps:%d \r", gnSmpInt, SetTimerMilliSec, SetTimerMilliSec/1000*60, nBkgTicks,SetTimerMilliSec * ( gChnkPerRep - 1 ),  gnReps 
////	Out( bf )
////
////	if ( gRadTrigMode == 0 ) 	// normal SW triggered mode
////		IMWArmClockStart( gnSmpInt, 1 )
////	endif
////
////	if ( radDEBPSel > 2  &&  PnDebgAcq )
////		printf  "\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\tAcq Cpy>ADHo>Cnv  \t ADPnts\t  SASB\t\t>TASb \t>HoSB \t   =HoSB \t IgorWave \t\t\t[+ch1,+ch2...] \r"
////	endif
////	nBkgTicks= nTICKS //? test
////	CtrlBackground start ,  period = nBkgTicks, noBurst=0//1 //? nB0=try to catch up, nB1=don't catch up
////
////	return 0	// todo: could also but does not return error code
//
//
//	BackGroundInfo	
//	if ( v_Flag == cBKG_UNDEFINED )		// 2003-1025   for  the hardware triggered E3E4 mode : We call this function from the BackGround task function ( StopADDA() -> buStartAcq() -> 'StartStimulusAndAcquisition'  ->  'CedStartAcq()'  ... 
//		// printf "\t\t\tBackGroundInfo   '%s'  , v_Flag:%d :  is  %s ,  next scheduled execution:%d  \r ", s_Value, v_Flag, SelectString( v_Flag-1, "not defined", "defined but not running (idle)", "running" ), v_NextRun 
//		SetBackground	  MyBkgTask()		// ...but it is not allowed (and we must avoid) to change a BackGround task function from within a BackGround task function 
//		CtrlBackground	  start ,  period = nTicks, noBurst=1//0//1 //? nB0=try to catch up, nB1=don't catch up
//		// printf "\t\t\tCedStartAcq(5a) \t\t\tBkg task: set and start \r "
//	endif
//	
//	if (  !  cBKG_RUN_ALWAYS )
//		if ( v_Flag == cBKG_IDLING )		// 2003-1025   for  the hardware triggered E3E4 mode : We call this function from the BackGround task function ( StopADDA() -> buStartAcq() -> 'StartStimulusAndAcquisition'  ->  'CedStartAcq()'  ... 
//			CtrlBackground	  start ,  period = nTicks, noBurst=1//0//1 //? nB0=try to catch up, nB1=don't catch up
//			 // printf "\t\t\tCedStartAcq(5b) \t\t\tBkg task: start \r "
//		endif
//	endif
//
//	if ( ArmClockStart( nSmpInt, bTrigMode ) )	
//printf "ERROR in ArmClockStart() \r"
////		return	UFCom_kERROR						//  Avoid  the user ignoring this error and continuing . This error happens very rarely and is not understood...
//	endif	
//
////	if ( UFCom_DebugDepthSel() > 2  &&  UFCom_DebugVar( "AcqDA" ) )
////		printf  "\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\tAcqDA Cpy>ADHo>Cnv  \t ADPnts\t  SASB\t\t>TASb \t>HoSB \t   =HoSB \t IgorWave \t\t\t[+ch1,+ch2...] \r"
////	endif
//
//	return 0	// todo: could also but does not return error code
//End
//
//
//
//// Old code from version 223 (03 Oct) : E3E4 triggering working !!!  To be deleted again !
////
////Function  IMWArmClockStart( SmpInt, nrep )
////	variable	SmpInt, nrep 
////	string		buf , bf
////	variable	code
////
////	nvar		gnPre	= root:cont:gnPre
////	if (  CEDHandleIsOpen() )
////		// divide 1MHz clock by two factors to get basic clock period in us, set clock (with same clock rate as DAC and ADC)
////		// start DigOut, DAC and  ADC 
////		sprintf buf, "DIGTIM,C,%d,%d,%d;", gnPre, trunc( SmpInt / gnPre ), nrep
////		sprintf  bf,  "\t\tAcq IMWArmClockStart sends  '%s'  \r", buf; Out( bf )
////		code = UFP_CedSendStringErrOut( UFPE_ERRLINE+ERR_FROM_CED, buf )
////
////	endif
////	return 0;
////End

//
//Function		PrintBackGroundInfo( sText1, sText2 )
//	string		sText1, sText2
//	BackGroundInfo	
//	printf "\t\t\t%s\tBkgInfo %s\tRunAlways:%d\t%s \tPeriod:%3d \tnext scheduled execution:%d  \tv_Flag:%d :  is  %s \r ", UFCom_pad( sText1, 18),  UFCom_pad( sText2, 10 ), cBKG_RUN_ALWAYS, UFCom_pd(s_Value,12), v_Period,  v_NextRun , v_Flag, SelectString( v_Flag-1, "not defined", "defined but not running (idle)", "running" )
//End

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//Function		MyBkgTask()
//// CONT mode routine with swinging buffer
//	// print "050128 Entering BKG task, swinging..."
//	variable	nCode
////	if ( NewStyle( ksACQ ) == kPULSE_OLD )
////		nCode = ADDASwing()
////	else
//		nCode = ADDASwing_ns()
////	endif
//	// print "050128 Leaving BKG task (0: keep running=wait , !=0 kill BKG task. Leaving with: ", nCode , "=?=" , UFCom_kERROR , " ->", nCode == UFCom_kERROR	
//	return	nCode == UFCom_kERROR			//  return 0 (=cADDAWAIT) if CED was not yet ready to keep the background task running, return !=0 to kill background task
//End
//

//static  Function	ClipCompressFactor( nAD, nTG,  PtpChk )
//	variable	nAD, nTG, PtpChk 
//	string		bf
//	variable	nCompression	= 1
//	// Start with maximum desired compression  'cCOMPRESST'  (e.g. 100), clip to allowed range 
//	nCompression	  =  trunc ( min( cFAST_TG_COMPRESS * ( nAD + nTG ) , 255 ) / ( nAD + nTG ) )// Ced allows a maximum step of 255 for extracting interleaved channels
//	// ...then possibly further decrease the allowed value so that it fits into the  'Points per Chunk' without remainder. If this is not done there will be 1 wrong value at the end of each chunk  
//	nCompression	+= 1
//	do
//		nCompression	-= 1
//	while (  PtpChk / nCompression != trunc( PtpChk / nCompression )  )
//	if ( UFCom_DebugDepthSel() > 2  &&  UFCom_DebugVar( "Ced" ) )
//		printf "\t\t\t\tCed SetPoints ClipCompressFactor( nAD:%d ,  nTG:%d ,  PtpChk:%d  )  desired TG compression:%d   computed TG compression:%d \r", nAD, nTG,  PtpChk , cFAST_TG_COMPRESS,  nCompression
//	endif
//	return	nCompression 
//End
//
//
//static Function	ADDASwing()
//	string  	sFolders	= ksF_ACQ_PUL		
//	string  	sFo	= ksACQ
//	string  	sSubFoC	= UFPE_ksCO	// 'co'
//	string  	sSubFoW	= UFPE_ksKPwg		// 'G'
//	wave  	wG		= $"root:uf:" + sFo + ":" + UFPE_ksKPwg + ":wG"  	// This  'wG'  	is valid in FPulse ( Acquisition )
//	wave  /T	wIO		= $"root:uf:" + sFo + ":ar:wIO"  			// This  'wIO'   	is valid in FPulse ( Acquisition )
//	wave 	wRaw	= $"root:uf:" + sFo + ":" + UFPE_ksKEEPwr + ":wRaw"// This  'wRaw' 	is valid in FPulse ( Acquisition )
//	variable	nProts		= UFPE_Prots( sFo )
//	nvar		gnReps		= root:uf:acq:co:gnReps
//	nvar		gnRep		= root:uf:acq:co:gnRep
//	nvar		gnChunk		= root:uf:acq:co:gnChunk
//	nvar		gChnkPerRep	= root:uf:acq:co:gChnkPerRep 
//	nvar		gPntPerChnk	= root:uf:acq:co:gPntPerChnk
//	nvar		gnOfsDA		= root:uf:acq:co:gnOfsDA,	gSmpArOfsDA	= root:uf:acq:co:gSmpArOfsDA
//	nvar		gnOfsAD		= root:uf:acq:co:gnOfsAD,	gSmpArOfsAD	= root:uf:acq:co:gSmpArOfsAD
//	variable	nSmpInt		= UFPE_SmpInt( sFo )
//	variable	nCntDA		= wG[ UFPE_WG_CNTDA ]	
//	variable	nCntAD		= wG[ UFPE_WG_CNTAD ]	
//	variable	nCntTG		= wG[ UFPE_WG_CNTTG ]	
//	variable	nPnts		= wG[ UFPE_WG_PNTS ] 
//	nvar		gnOfsDO		= root:uf:acq:co:gnOfsDO
//	nvar		gnCompress	= root:uf:acq:co:gnCompressTG
//	variable	bAppendData	= AppendData()
//	nvar		gBkPeriodTimer	= root:uf:acq:co:gBkPeriodTimer 
//	variable	nRadDebgSel	= UFCom_DebugDepthSel()
//	string		buf
//	// DAC timing (via PtpChk!) must render ADCBST flag checking unnecessary
//	
//	variable 	SmpArStartByte, TfHoArStartByte, nPts, nDacReady, code, nTruePt
//
//	// printf "\t\t\tADDASwing(1)  \tnChunk:%2d    nDacReady :%2d  \tticks:%d\r", gnChunk,  nDacReady, ticks 
//
//	if ( ! CEDHandleIsOpen() )						// MODE  WITHOUT  CED works well for testing
//
//		ConvolveBuffersDA( sFo, wIO, gnChunk, gnRep-1, gChnkPerRep, nCntDA, gPntPerChnk, wRaw, gnOfsDA/2, nPnts ) // not UFPE_kPROT_AWARE
//
//		// Although test copying (without CED) is much slower than TOHOST/TO1401 (6us compared to 1us / WORD) this mode without CED..
//		// ..works more reliably and/ or at faster rates. Why? Probably because the timing is more determinate (no waiting for the DAC to be ready) 
// 		TestCopyRawDAC_ADC( wG, gnChunk, gPntPerChnk, wRaw, gnOfsDA/2, gnOfsAD/2  )
//
//		// 2005-1201 only test to check the ValDisplay control, can be removed again
//		nvar		gPrediction  = root:uf:acq:pul:vdPredict0000
//		variable	n0to59 	  = str2num( time()[6,7] )			// extract the seconds 
//		gPrediction	=  ( n0to59 ) / 30					// will go from 0 to +2  within a minute
//
// 	else											// MODE  WITH  CED 
//		// printf "\t\tADDASwing(A)  gnRep:%d ?<? nReps:%d \r", gnRep, nReps
//		nDacReady =  CheckReadyDacPosition( sFo, wG, "MEMDAC,P;", gnRep, gnChunk ) 
//		if ( nDacReady == cADDATRANSFER ) 
//			 // printf "\t\tADDASwing(B)   gnRep:%d ?<? nReps:%d \r", gnRep, nReps
//
//			if (  		  gnRep < gnReps ) // DAC: don't transfer the last 'ChunkspRep' (appr. 250..500kByte, same as in  ADDAStart) as they are already transfered..
//				UFCom_StartTimer( sFo, "Convolve" )		
//				// printf "\t\tADDASwing(C)  gnRep:%d ?<? nReps:%d ConvDA \r", gnRep, nReps
//				// print "C", gnRep, "-", gnChunk, gnRep,	ChunkspRep, nCntDA, PtpChk, wRaw, OffsDA/2
//				// all Dac buffers have 'rollover' :  when the repetition index has passed the last  then we must use the data from the first (=0)
//				ConvolveBuffersDA( sFo, wIO, gnChunk, gnRep,	gChnkPerRep, nCntDA, gPntPerChnk, wRaw, gnOfsDA/2, nPnts )	// not UFPE_kPROT_AWARE
//				UFCom_StopTimer( sFo, "Convolve" )		
//				UFCom_StartTimer( sFo, "Transfer" )		
//				nPts				= gPntPerChnk * nCntDA 
//	 			TfHoArStartByte		= gnOfsDA	 	+ 2 * nPts * mod( gnChunk, 2 ) //  only  2 swaps
//				SmpArStartByte		= gSmpArOfsDA		+ 2 * nPts * gnChunk 
//
//				if ( UFPE_kELIMINATE_BLANK )	
//					variable	begPt	= gPntPerChnk * gnChunk					// BegPt and EndPt are points in the CED sampling area (typ. 16MB) ....
//					variable	endPt	= gPntPerChnk * ( gnChunk + 1 )				// The same BegPt and EndPt are passed multiple times if nReps is >1 (=long scripts and/or many protocols)
//					variable	repOs	= gnRep * gPntPerChnk * gChnkPerRep		// BegPt and EndPt  PLUS the repetition offset 'repOs' gives the true point number in the DAC wave independently from the CED sampling area size
//					variable	nBigChunk= ( BegPt + RepOs ) / gPntPerChnk 
//					variable	bStoreIt	= UFPE_StoreChunkorNot( sFo, nBigChunk )				
//					variable	BlankAmp	= wRaw[ TfHoArStartByte / 2  ]			// use the first value of this chunk as amplitude for the whole chunk
//					if ( ( nRadDebgSel == 1  ||  nRadDebgSel == 3 )  &&   UFCom_DebugVar( "AcqDA" ) )
//						printf "\t\tAcqDA TfHoA2\t%8d\t ->\tSmpAr:\t %11d \t(pts:%8d)  \tBg:\t%7d\tNd:\t%7d\tChunk:\t%7d\tStoring:%2d\tAmp:\t%7d\t  \r", TfHoArStartByte, SmpArStartByte, nPts, BegPt+repOs, EndPt+repOs, nBigChunk, bStoreIt, BlankAmp
//					endif
//					if (	bStoreIt )
//						sprintf buf, "TO1401,%d,%d,%d;", TfHoArStartByte, 2*nPts, TfHoArStartByte ;  UFP_CedSendString( buf );  // TransferArea and HostArea start at the same point
//						code		= GetAndInterpretAcqErrors( "Dac      ", "TO1401 ", gnRep * gChnkPerRep + gnChunk, gnReps * gChnkPerRep )
//	 				else
//						 sprintf buf, "SS2,C,%d,%d,%d;", TfHoArStartByte, 2*nPts, BlankAmp;  UFP_CedSendString( buf )  			// fill Ced transferArea with constant 'Blank' amplitude. This is MUCH faster than the above 'TO1401' which is very slow
//						 code	= GetAndInterpretAcqErrors( "SmpStart", "SS2    ", gnChunk, gnReps * gChnkPerRep )
//					endif
//				else	
//					 sprintf buf, "TO1401,%d,%d,%d;", TfHoArStartByte, 2*nPts, TfHoArStartByte ;  UFP_CedSendString( buf );  // TransferArea and HostArea start at the same point
//					 code		= GetAndInterpretAcqErrors( "Dac      ", "TO1401 ", gnRep * gChnkPerRep + gnChunk, gnReps * gChnkPerRep )
//				endif
//
//
//				sprintf buf,  "SM2,C,%d,%d,%d;", SmpArStartByte, TfHoArStartByte, 2*nPts;   UFP_CedSendString( buf );     // copy  Dac data from transfer area to large sample area
//				code		= GetAndInterpretAcqErrors( "Dac      ", "SM2,Dac", gnRep * gChnkPerRep + gnChunk, gnReps * gChnkPerRep )
// 				UFCom_StopTimer( sFo, "Transfer" )		
//			endif
//
//			UFCom_StartTimer( sFo, "Transfer" )	
//
//			nPts			= gPntPerChnk * ( nCntAD + nCntTG ) 
//			TfHoArStartByte		= gnOfsAD	 	+ round( 2 * nPts * mod( gnChunk, 2 ) * ( nCntAD + nCntTG / gnCompress ) / (  nCntAD + nCntTG ) )// only  2 swaps
//			SmpArStartByte		= gSmpArOfsAD		+ 2 * nPts * gnChunk
//			nTruePt			= ( ( gnRep - 1 ) * gChnkPerRep +  gnChunk ) * nPts 
//			// printf "\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\tAcqAD  \t%8d\t%10d\t%8d\t%10d \r", nPts,SmpArStartByte, TfHoArStartByte, nTruePt	// 
//
//			variable	c, nTGSrc, nTGDest, nTGPntsCompressed
//
//			// SEND   1  string to the 1401  for each command : should be slow but should be better as errors are indicated errors more precisely
//			// Extract interleaved  true AD channels without compression
//			for ( c = 0; c < nCntAD; c += 1 )							// ASSUMPTION: order of channels is first ALL AD, afterwards ALL TG
//				nTGSrc			= SmpArStartByte + 2 * c
//				nTGDest			= round( TfHoArStartByte + 2 * nPts *  		c 		 / ( nCntAD + nCntTG ) )	// rounding is OK here as there will be no remainder
//				nTGPntsCompressed	= round( nPts / ( nCntAD + nCntTG ) )									// rounding is OK here as there will be no remainder
//				sprintf buf,  "SN2,X,%d,%d,%d,%d;", nTGDest, nTGSrc, 2 * nTGPntsCompressed, 	(nCntAD + nCntTG);   UFP_CedSendString( buf );    // separate interleaved channels within large (~16MB) sample area to 1MB transfer area 
//				code		= GetAndInterpretAcqErrors( "ExtractAD", "SN2,X,Ad", gnRep * gChnkPerRep + gnChunk, gnReps * gChnkPerRep )
//				 // print buf, longBuf
//			endfor
//
//			// Extract interleaved Telegraph channel data  and compress them in 1 step
//			for ( c = nCntAD; c < nCntAD + nCntTG; c += 1 )			// ASSUMPTION: order of channels is first ALL AD, afterwards ALL TG
//				nTGSrc			= SmpArStartByte + 2 * c
//				nTGDest			= trunc( TfHoArStartByte + 2 * nPts * ( nCntAD + (c-nCntAD) / gnCompress ) / ( nCntAD + nCntTG ) )
//				nTGPntsCompressed	= trunc( nPts / ( nCntAD + nCntTG )   / gnCompress ) 
//				sprintf buf,  "SN2,X,%d,%d,%d,%d;", nTGDest, nTGSrc, 2 * nTGPntsCompressed, 	(nCntAD + nCntTG) * gnCompress;   UFP_CedSendString( buf );    // separate interleaved channels within large (~16MB) sample area to 1MB transfer area 
//				code		= GetAndInterpretAcqErrors( "ExtrCmpTG", "SN2,X,TG", gnRep * gChnkPerRep + gnChunk, gnReps * gChnkPerRep )
//			endfor
//
////			// 2003-0806  TEST : SEND ONLY  1  string to the 1401  containing multiple commands : does not speed up the acquisition and does not avoid any errors
////			// Extract interleaved  true AD channels without compression
////			string longbuf = ""
////			for ( c = 0; c < nCntAD; c += 1 )						// ASSUMPTION: order of channels is first ALL  AD, afterwards ALL TG
////				nTGSrc			= SmpArStartByte + 2 * c
////				nTGDest			= round( TfHoArStartByte + 2 * nPts *  		c 		 / ( nCntAD + nCntTG ) )	// rounding is OK here as there will be no remainder
////				nTGPntsCompressed	= round( nPts / ( nCntAD + nCntTG ) )									// rounding is OK here as there will be no remainder
////				sprintf buf,  "SN2,X,%d,%d,%d,%d;", nTGDest, nTGSrc, 2 * nTGPntsCompressed, 	(nCntAD + nCntTG)  	// separate interleaved channels within large (~16MB) sample area to 1MB transfer area 
////				longbuf += buf
////			endfor
////			// Extract interleaved Telegraph channel data  and compress them in 1 step
////			for ( c = nCntAD; c < nCntAD + nCntTG; c += 1 )		// ASSUMPTION: order of channels is first ALL  AD, afterwards ALL TG
////				nTGSrc			= SmpArStartByte + 2 * c
////				nTGDest			= trunc( TfHoArStartByte + 2 * nPts * ( nCntAD + (c-nCntAD) / gnCompress ) / ( nCntAD + nCntTG ) )
////				nTGPntsCompressed	= trunc( nPts / ( nCntAD + nCntTG )   / gnCompress ) 
////				sprintf buf,  "SN2,X,%d,%d,%d,%d;", nTGDest, nTGSrc, 2 * nTGPntsCompressed, 	(nCntAD + nCntTG) * gnCompress	// separate interleaved channels within large (~16MB) sample area to 1MB transfer area 
////				longbuf += buf
////			endfor
////			UFP_CedSendString( longbuf );    // separate interleaved channels within large (~16MB) sample area to 1MB transfer area 
////			code		= GetAndInterpretAcqErrors( "ExtrCmpTG", "SN2,X,TG", gnRep * gChnkPerRep + gnChunk, gnReps * gChnkPerRep )
//
//
//			variable nPntsCompressed	= round( nPts * ( nCntAD +  nCntTG / gnCompress ) / ( nCntAD + nCntTG ) ) 
//			//variable nPntsTest		= ( ( nPts / gnCompress ) * ( nCntAD * gnCompress  +  nCntTG) ) / ( nCntAD + nCntTG )	// same without rounding (if Igor recognizes paranthesis levels)
//
//			if ( UFPE_kELIMINATE_BLANK )				
//				begPt	= gPntPerChnk * gnChunk					// BegPt and EndPt are points in the CED sampling area (typ. 16MB) ....
//				endPt	= gPntPerChnk * ( gnChunk + 1 )				// The same BegPt and EndPt are passed multiple times if nReps is >1 (=long scripts and/or many protocols)
//				repOs	= ( gnRep - 1 ) * gPntPerChnk * gChnkPerRep	// BegPt and EndPt  PLUS the repetition offset 'repOs' gives the true point number in the DAC wave independently from the CED sampling area size
//				nBigChunk= ( BegPt + RepOs ) / gPntPerChnk 
//				bStoreIt	= UFPE_StoreChunkorNot( sFo, nBigChunk )				
//				if ( ( nRadDebgSel == 1  ||  nRadDebgSel == 3 )  &&  UFCom_DebugVar( "AcqAD" ) )
//					printf "\t\tAcqAD TfHoA3\t%8d\t ->\tSmpAr:\t %11d \t(pts:%8d)  \tBg:\t%7d\tNd:\t%7d\tChunk:\t%7d\tStoring:%2d\t  \r", TfHoArStartByte, SmpArStartByte, nPts, BegPt+repOs, EndPt+repOs, nBigChunk, bStoreIt
//				endif
//				if (	bStoreIt )
//					sprintf  buf, "TOHOST,%d,%d,%d;", TfHoArStartByte, 2 * nPntsCompressed, TfHoArStartByte ;  UFP_CedSendString( buf );  // TransferArea and HostArea start at the same point
//					// print "nPts", nPts, "nPntsCompressed ", nPntsCompressed ,  nPntsTest, "bytes", nPntsCompressed *2, "buf", buf
//					code		= GetAndInterpretAcqErrors( "Sampling", "TOHOST", gnRep * gChnkPerRep + gnChunk, gnReps * gChnkPerRep )
//				endif
//			else	
//				sprintf  buf, "TOHOST,%d,%d,%d;", TfHoArStartByte, 2 * nPntsCompressed, TfHoArStartByte ;  UFP_CedSendString( buf );  // TransferArea and HostArea start at the same point
//				// print "nPts", nPts, "nPntsCompressed ", nPntsCompressed ,  nPntsTest, "bytes", nPntsCompressed *2, "buf", buf
//				code		= GetAndInterpretAcqErrors( "Sampling", "TOHOST", gnRep * gChnkPerRep + gnChunk, gnReps * gChnkPerRep )
//
//			endif			
//			UFCom_StopTimer( sFo, "Transfer" )		
//
//		endif		
//	endif	
//// print nDacReady
//	if (  !CEDHandleIsOpen()   ||  nDacReady  == cADDATRANSFER )	// WITH  or  WITHOUT  CED
//
//		UFCom_StartTimer( sFo, "Convolve" )	
//		variable	ptAD
//		ptAD = DeconvolveBuffsAD( sFo, wG, wIO, gnChunk, gnRep, gChnkPerRep, gPntPerChnk, wRaw, gnOfsAD/2, nCntAD , nCntTG, gnCompress, nPnts )	// not UFPE_kPROT_AWARE
//
//		UFCom_StopTimer( sFo, "Convolve" )		
//
//		// HERE the real work is done : CFS Write, Display , PoverN correction
//		UFCom_StartTimer( sFo, "Process" )						// the current CED pointer is the only information this function gets
//		// printf "\tADDASwing()  calls Process( %4d )  \t%2d  gnRep:%2d/%2d \r", ptAD, nProts,  gnRep, nReps
//
//		Process( sFolders, sFo, ptAD )	// different approach: call CFSStore() and TDisplaySuperImposedSweeps() from WITHIN this function
//
//		UFCom_StopTimer( sFo, "Process" )		
//
//		// printf "\t\t\t\tADDASwing() next chunk   \tgnchunk\t:%3d\t/%3d\t ->%3d\t--> nrep\t:%3d\t/%3d\t\tticks:%d \r", gnChunk, gChnkPerRep, mod( gnChunk + 1, gChnkPerRep ), gnRep, gnReps, ticks
//		gnChunk	= mod( gnChunk + 1, gChnkPerRep )					// ..increment Chunk  or reset  Chunk to 0
//		if ( gnChunk == 0 )				 						// if  the inner  Chunk loop  has just been iinished.. 
//			gnRep += 1										// ..do next  Rep  (or first Rep again if  Rep has been reset above) and..
//			 // printf "\t\t\tADDASwing() next rep  \t\t\tgnChunk\t:%3d\t/%3d\t ->%3d\t--> nRep\t:%3d\t/%3d\t\tticks:%d \r", gnChunk, gChnkPerRep, mod( gnChunk + 1, gChnkPerRep ), gnRep, gnReps, ticks
//			if ( gnRep > gnReps )
//				if ( ! bAppendData )								// 2003-1028
//			 		FinishFiles()								// ..the job is done : the whole stimulus has been output and the Adc data have all been sampled..
//				endif
//				StopADDA( "\tFINISHED  ACQUISITION.." , UFCom_FALSE, sSubFoC,  sSubFoW  )		// ..then we stop the IGOR-timed periodical background task..  UFCom_FALSE: do NOT ApplyScript()
//			endif												// In the E3E4 trig mode StopADDA calls StartStimulus..() for which reps and chunks must already be set to their final value = StopAdda must be the last action
//		endif
//
//	endif
//
//	if ( nDacReady  == UFCom_kERROR )									// Currently never executed as currently the acquisition continues even in worst case of corrupted data 
//	 	FinishFiles()											// ...'CheckReadyDacPosition()'  must be changed if this code is to be executed
//		StopADDA( "\tABORTED  ACQUISITION.." , UFCom_FALSE, sSubFoC,  sSubFoW )			//  UFCom_FALSE: do NOT ApplyScript() 
//	endif														// returning   nDacReady = UFCom_kERROR  will kill the background task
//
//	return nDacReady
//End
//
//
//Static Function  CheckReadyDacPosition( sFo, wG, command, nRep, nChunk )
//	// Check buffer index to determine whether another chunk must be transferred.
//	// Moving or sizing windows interrupts the periodical task of transfering chunks leading to skipped chunks: LAGGING or LOST
//	// LAGGING: interrupted time is shorter than the  'ring buffer size'  times  'Sample Int'  -> catching up without data loss is possible
//	// LOST: 	     interrupted time is longer  than the  'ring buffer size'  times  'Sample Int'  -> data are lost (overwritten with newer data)
//	// The most effective way to discriminate between  LAGGING and LOST would be to check not only the point(DacPos) but also the chunk(DacPos)
//	// As the CED does not supply the latter information, the time between background task calls is measured and from this the number of skipped chunks is estimated
//	// Design issue:
//	// Even when chunks have been lost the ADDA process still continues.
//	// This gives at least a record of correct length and correct sample timing but containing corrupted data periods.
//	// One could as well abort the ADDA process .... 
//	string  	sFo
//	wave	wG
//	variable	nRep, nChunk
//	string		command 
//	string  	sSubFoC	= UFPE_ksCOns
//	variable	nProts			= UFPE_Prots( sFo )
//	nvar		gBkPeriodTimer		= root:uf:acq:co:gBkPeriodTimer
//	nvar		gnReps			= root:uf:acq:co:gnReps
//	nvar		gChnkPerRep		= root:uf:acq:co:gChnkPerRep 
//	nvar		gPntPerChnk		= root:uf:acq:co:gPntPerChnk
//	variable	nSmpInt			= UFPE_SmpInt( sFo )
//	variable	nCntDA			= wG[ UFPE_WG_CNTDA ]	
//	variable	nCntAD			= wG[ UFPE_WG_CNTAD ]	
//	variable	nCntTG			= wG[ UFPE_WG_CNTTG ]	
//	nvar		gnAddIdx			= root:uf:acq:co:gnAddIdx
//	nvar		gnLastDacPos		= root:uf:acq:co:gnLastDacPos
//	nvar		gReserve			= root:uf:acq:co:gReserve
//	nvar		gMinReserve		= root:uf:acq:co:gMinReserve
//	nvar		gPrediction		= root:uf:acq:pul:vdPredict0000
//	nvar		gMaxSmpPtspChan	= root:uf:acq:co:gMaxSmpPtspChan
//	nvar		gErrCnt			= root:uf:acq:co:gErrCnt
//	variable	nRadDebgSel		= UFCom_DebugDepthSel()
//	nvar		gbAcquiring		= root:uf:acq:co:gbAcquiring
//	variable	nPts 			=  2 * gPntPerChnk * nCntDA 
//	variable	nResult
//	string		sResult, ErrBuf
//
//	// measure elapsed time between background task calls
//	variable	BkPeriod	=  stopMSTimer( gBkPeriodTimer ) / 1000
//	gBkPeriodTimer 	=  startMSTimer									// timer to check time elapsed between Bkg task calls
//	if ( gBkPeriodTimer 	== -1 )
//		printf "*****************All timers are in use 5 ...\r" 
//	endif
//	
//	// check buffer rollover so that 'IsIdx' is increased monotonically even if 'nDacPos' resets itself periodically
//	variable	nDacPos	=  UFP_CedGetResponse( command, command, 0 )			// last param is 'ErrMode' : display messages or errors
//
//	// 2003-08 The following calls requesting the CED AD-pointer and AD-status are not mandatory. They have been introduced only for information..
//	// ...in an attempt to avoid the erroneous CED error  'Clock input overrun'  which unfortunately occurs already when the sampling is near (but still below) the limit.
//	// When removing these calls be sure that the remaining mandatory CED DA-pointer requests still work correctly. 
//	// It seemed (once) that DA- and AD-requests are not under all circumstances completely  as independent as they should be.
//	variable	nDAStat	= UFP_CedGetResponse( "MEMDAC,?;" , "MEMDACstatus",  0 )	// last param is 'ErrMode' : display messages or errors
//	variable	nADStat	= UFP_CedGetResponse( "ADCBST,?;", "ADCBSTstatus  ",  0 )	// last param is 'ErrMode' : display messages or errors
//	variable	nADPtr	= UFP_CedGetResponse( "ADCBST,P;", "ADCBSTpointer ",  0 )	// last param is 'ErrMode' : display messages or errors
//	nADPtr /=  ( nCntAD + nCntTG ) 
//
//	// We want the time during which the stimulus is output, not the pre-time possibly waiting for the E3E4 trigger and not the post-time when the stimulus is possibly reloaded (when nReps>1)  
//	// PnTest() -> Print options (Debug)  -> Everything ->  Acquisition reveals that  'nDacPos' , 'nADPtr'  and possibly 'nADStat' and 'nDAStat' can be used for that purpose 
//	// 'gbRunning' is here not a valid indicator as it not yet set to 0 here after a user abort
//	// 'nDacPos'    is here not always a valid indicator as it is not set to 0 after a user  abort
//	gbAcquiring	=   nAdPtr == 0   ||  nDacPos == 0   ?   0  :  1				// 2003-1030
//	StartStopFinishButtonTitles( sFo, sSubFoC )									// 2003-1030 reflect change of 'gbAcquiring' in buttons : enable or disable (=grey) them 
//
//	// 2003-1210  The  standard 1401   and the  1401plus / power1401 behave differently so that the code recognizing the normal FINISH  of a script fails :
//	// For the 1401plus and power1401 the  'nPredDacPos' -> 'gnAddIdx' -> 'IsIdx'  computation is effective in 2 cases:
//	//	1. during all but the last chunks ( Dacpos resets but AddIndex incrementing compensates for that )
//	//	2. after the last chunk: DacPos goes to  0   but AddIndex incrementing compensates for that  -> IsIndex increments a last time -> = SollIndex -> XFER is returned -> StopADDA() is called at the end of AddaSwing() 
//	// For the standard 1401  the  'nPredDacPos' -> 'gnAddIdx' -> 'IsIdx'  computation is effective in only in case 1. :  during acquisition but not after the last chunk 
//	//	It fails in case 2.  after the last as DacPos  does NOT go to 0  but instead stay fixed at the index of the last point MINUS 2 !  -> IsIndex would  NOT be incremented -> WAIT would be returned -> StopADDA() is never called
//	//	Solution : Check and use the Dac status ( which goes to 0 after finishing ) instead . The Adc status also goes to 0 after finishing but a script does not necessarily contain ADC channels so we do not use it.
//	// In principle this patch for the standard 1401 could also be used for the 1401plus and power1401, as their status flags go to 0 in the same manner after finishing...............
//
//	// 'nSkippedChnks' can be fairly good estimated (error < 0.1) .  
//	//  We must not count skipped chunks when waiting for a  HW E3E4 trigger, as in this case short scripts (shorter than Background time ~100ms)  would...
//	// ...erroneously increment  'nPredDacPos' -> 'gnAddIdx' -> 'IsIdx'  and then trigger the error case below. We avoid this error by setting  'nSkippedChnks=0' when not acquiring  
//	variable	nSkippedChnks	= ( BkPeriod / ( gPntPerChnk * nSmpInt * .001 ) ) * gbAcquiring
//	variable	nPredDacPos	= gnLastDacPos + nSkippedChnks * nPts			// Predicted Dac position can be greater than buffer!
//
//	
//	gnLastDacPos		=  nDacPos									// save value for next call
//	gnAddIdx		       += gChnkPerRep * trunc( ( nPredDacPos - nDacPos ) / ( nPts  * gChnkPerRep ) + .5 ) 
//	variable	IsIdx		=  trunc( nDacPos / nPts ) +  gnAddIdx
//	variable	SollIdx	=  nChunk + 1 + gChnkPerRep * ( nRep - 1 )
//	variable	TooHighIdx= SollIdx + gChnkPerRep - 1	
//
//	// if ( standard 1401 )    ....would be safer 		// 2003-1210
//	if ( nDAStat == 0 )
//		IsIdx = SollIdx		// 2003-1210 only for standard 1401 : return XFER after finishing (if it also works for 1401plus and power1401 we do not have to pass/check the type of the 1401...))
//	Endif
//
//	// We keep counting 'IsIdx' and 'TooHighIdx' up (proportionally to 'gProt') even in the case of 'nReps' == 1  &&  'nProts' == 1..
//	// ...when this is not really necessary, as these 'easy' scripts will always work making the 'Reserve/Prediction' concept useless.
//	// We keep counting 'IsIdx' and 'TooHighIdx' because this indicator might prove useful in later stages of program development.
//	// ...even if doing so complicates the 'Reserve/Prediction' computation in the 'nReps==1' case. 
//	gReserve		= TooHighIdx - IsIdx - 1
//	gMinReserve	= min( gMinReserve, gReserve )				// we are interested in the lowest value so we freeze it. Without error the value would increase again at the end.
//	if ( IsIdx < SollIdx )									//  OK : wait	( gReserve = maximum )
//		nResult	= cADDAWAIT					
//		sResult	= "WAIT  "
//	elseif ( SollIdx <= IsIdx   &&  IsIdx < TooHighIdx  - 1 ) 			//  OK: Transfer	( gReserve = 1...maximum-1 )
//		nResult	= cADDATRANSFER
//		sResult	= "XFER "
//		
//		variable	rNeeded, rCurrent
//		gPrediction	= PredictedAcqSuccess( nProts, gnReps, gChnkPerRep, gReserve, IsIdx , rNeeded, rCurrent )
//
//	else 				// if ( IsIdx > SollIdx + ChkpRep - 1 )		// UFCom_kERROR: more than one lap behind, data will be lost  ( gReserve = 0 )  if  at the same time nReps>1  
//		nResult	= cADDATRANSFER						// on error : continue
//		sResult	= "  ??? "								// more than one lap behind, but no data will be lost as nReps==1   031119
//
//	// the following 2 lines are to be ACTIVATED ONLY  FOR TEST  to break out of the inifinite  Background task loop.....  031111
//	//nResult	= UFCom_kERROR								// on error : stop acquisition
//	// printf "\t++++UFCom_kERROR in Test mode: abort prematurely in StopAdda() because of 'Loosing data error' , will also  stop  Background task. \r" 
//
//		if ( gnReps > 1  )	// scripts with only 1 repetition will never fail no matter how many protocols are output but the  'IsIdx - TooHighIdx' will erroneously indicate data loss if 'nProts>>1' 
//			sResult	= "LOOS'N"
//			if ( gErrCnt == 0 )								// issue this error only once
//				variable	TAused	= TAUse( gPntPerChnk, nCntDA, nCntAD, cMAX_TAREA_PTS )
//				variable	MemUsed	= MemUse( gChnkPerRep, gPntPerChnk, gMaxSmpPtspChan )
//				sprintf ErrBuf, "Data  in Chunk: %d / %d will probably be corrupted. Acquisition too fast, too many channels, too many or unfavorable number of data points.\r \t\t\tTA usage:%3d%%  Memory usage:%3d%%  Reps:%d  ChkPerRep:%d  PtsPerChunk:%d ", IsIdx, gnReps * gChnkPerRep, TAused, MemUsed, gnReps, gChnkPerRep, gPntPerChnk
//				UFCom_FoAlert( sFo, UFCom_kERR_SEVERE, ErrBuf )						// 2003-0716
//				gErrCnt	+= 1
//			endif
//		endif
//	endif
//
//	if ( nRadDebgSel > 3  &&  ( UFCom_DebugVar( "AcqDA" )  ||  UFCom_DebugVar( "AcqAD" ) ) )
//		printf "\ta:%d\tR:%2d/%2d\tChk:%3d/%3d\tAp:%8d\tDp:%8d\tPD:%8d\tTb:%4d", gbAcquiring, nRep, gnReps, (nRep-1) * gChnkPerRep + nChunk, gnReps * gChnkPerRep, nADPtr , nDacPos, nPredDacPos, BkPeriod
//		printf "\tsC:%4.1lf  AI:%4d\tIsI:%4.1lf\t[%3d\t|%3d.%3d\t|%3d\t] Rs\t:%3d\t/%3d\t/%3d\t%s\tStt:%4d\t|%5d", nSkippedChnks, gnAddIdx, IsIdx, SollIdx-1, SollIdx, TooHighIdx-1, TooHighIdx, gMinReserve, gReserve, gChnkPerRep, sResult, nDAStat, nADStat
//		// printf "\tPr:%5.2lf\t=sc:%5.1lf \t/sn:%5.1lf \r", gPrediction, rCurrent, rNeeded   	// display speeds (not good : range -1000...+1000)
//		printf "\tPr:%5.2lf\t= n %.2lf \t/  c %.2lf \r", gPrediction, rNeeded, rCurrent		// display inverse speeds ( good: range  -1...+1)
//	endif
//	return	nResult
//End
//
//Static Function		PredictedAcqSuccess( nProts, nReps, nChnkPerRep, nReserve, IsIdx, Needed, Current )
//// Returns (already during acquisition) a guess whether the acq will succeed ( > 1 ) or fail  ( < 1 ) .
//// This information is useful when the scripts takes very long and when the system is perhaps too slow for the  ambitious sampling rate and number of channels 
//	variable	nProts, nReps, nChnkPerRep, nReserve, IsIdx
//	variable	&Needed, &Current
//	variable	PredCurr
//	variable	PosReserveDifference			// if (in rare cases) the reserve increases during the acq  a neg. reserve diff is computed which gives a false 'Loosing data' indication 
//										// we avoid this by clipping to zero so that the correct Prediction = Inf = Success  is displaed
//	nvar		/Z 	gStaticPrevReserve			// used like static, should be hidden within this function but must keep its value between calls
//	nvar		/Z 	gStaticPrediction			// used like static, ...
//	nvar		/Z 	gStaticIsIdx				// used like static, ...
//	if ( ! nvar_Exists( gStaticPrevReserve	) )
//		variable   /G	gStaticPrevReserve	= 0	// used like static, should be hidden within this function but must keep its value between calls
//		variable   /G	gStaticIsIdx		= 0	// used like static, ...
//		variable   /G	gStaticPrediction	= 1	// used like static, ...
//	endif
//
//	if (  nProts * nReps * nChnkPerRep - IsIdx >= 1 )
//	  	if ( nReserve != gStaticPrevReserve  ||   nReserve ==  nChnkPerRep - 2 )			// update the value when 1.)  the reserve chunks change (then store the MINIMUM value) 2.) when reserve is at maximum (easy scripts...)
//	//	if ( nReserve != gStaticPrevReserve )			// update the value when 1.)  the reserve chunks change (then store the MINIMUM value) 2.) when reserve is at maximum (easy scripts...)
//	//	if ( nReserve != gStaticPrevReserve   &&  IsIdx != gStaticIsIdx )			// update the value when 1.)  the reserve chunks change (then store the MINIMUM value) 2.) when reserve is at maximum (easy scripts...)
//	//	if ( 							     IsIdx != gStaticIsIdx )			// update the value when 1.)  the reserve chunks change (then store the MINIMUM value) 2.) when reserve is at maximum (easy scripts...)
//			// Version1: process   speed
//			//Needed	= ( nProts * nReps * nChnkPerRep - IsIdx ) / max( .01, nReserve ) 	// speed : avoid infinite or negative speeds when reserve is 0 or negative
//			//Current	= ( IsIdx - gStaticIsIdx ) / max( .01, ( gStaticPrevReserve - nReserve ) ) 	// speed :  avoid infinite or negative speeds when reserve difference is 0 or negative
//			//PredCurr	= min( max( -99, Current / Needed ), 99 )
//			// Version2: process  1/speed
//	//		Needed	= nReserve / ( max( 1, nProts * nReps * nChnkPerRep - IsIdx ) )		// 1 / speed needed for the rest
//			Needed	=  nReserve / ( 		 nProts * nReps * nChnkPerRep - IsIdx )		// 1 / speed needed for the rest
//			PosReserveDifference = max( 0, gStaticPrevReserve - nReserve ) 			// if (in rare cases) the reserve increases during the acq  a neg. reserve diff is computed which gives a false 'Loosing data' indication 
//																		// we avoid this by clipping to zero so that the correct Prediction = Inf = Success  is displaed
//			Current	= PosReserveDifference / ( IsIdx - gStaticIsIdx ) 					// 1 / current speed		= current slow
//	//		Current	= 1 / max( 1, ( IsIdx - gStaticIsIdx ) ) 							// 1 / current speed		= current slow
//			PredCurr	= Needed / Current   
//			gStaticPrediction 	= PredCurr
//			gStaticPrevReserve	= nReserve
//			gStaticIsIdx	 	= IsIdx
//		endif
//	endif
//	if ( nReps == 1 &&  nProts == 1 )
//		gStaticPrediction = 2			// 2 or any other value indicating success. In this special case the 'gReserve' value is meaningless.
//	endif
//	return	gStaticPrediction
//End

//
//
//
//Function		FinishFiles()
//	FinishCFSFile()
//	FinishAnalysisFile()
//End

//Function		StopADDA( strExplain , bDoApplyScript, sSubFoC, sSubFoW )
//	string		strExplain, sSubFoC, sSubFoW 
//	variable	bDoApplyScript 
//
//	string  	sFo				= ksACQ
//	wave  	wRaw			= $"root:uf:" + sFo + ":" + UFPE_ksKEEPwr + ":wRaw"		
//
//	nvar		gBkPeriodTimer		= $"root:uf:acq:" + sSubFoC + ":gBkPeriodTimer"
//	nvar		gbRunning		= $"root:uf:acq:" + UFPE_ksKEEP + ":gbRunning"
//	nvar		gnTicksStop		= $"root:uf:acq:" + UFPE_ksKEEP + ":gnTicksStop"
//
//	variable	bTrigMode			= TrigMode()
//	nvar		gbQuickAcqCheck	= $"root:uf:"+sFo+":mis:AcqCheck0000"	
//	variable	nRadDebgGen		= UFCom_DebugDepthGen()
//	variable	nRadDebgSel		= UFCom_DebugDepthSel()
//	string		bf
//	variable	dummy			= stopMSTimer( gBkPeriodTimer )
//
//	// printBackGroundInfo( "StopADDA(1)" , "before Stop" )
//
//	if ( ! cBKG_RUN_ALWAYS )
//		if ( bTrigMode == 0  ) 	// 2003-1113
//			BackGroundInfo	
//			if ( v_Flag == cBKG_RUNNING )			// Only if the bkg task is running we can stop it.  We must rule out the case when it is not yet running for example when switching the trigger mode initially at program start .
//				// printf "\t\t\tStopADDA(2) \t\t\tstopping BackGround task \r "
//				CtrlBackGround stop				// end of data acquisition
//			endif
//		endif
//	endif
//	// PrintBackGroundInfo( "StopADDA(2)" , "after  Stop" )
//	
//	if (  CEDHandleIsOpen() )
//		variable	ShowMode = UFPE_ERRLINE
//		// ShowMode = ( nRadDebgGen == 2 ||  ( nRadDebgSel > 0 &&  ( UFCom_DebugVar( "AcqDA" )  ||  UFCom_DebugVar( "AcqAD" ) ) ) ) ? UFPE_MSGLINE : UFPE_ERRLINE // syntax not allowed for debug printing...	
//		if  ( nRadDebgGen == 2 ||  ( nRadDebgSel > 0 &&  ( UFCom_DebugVar( "AcqDA" )  ||  UFCom_DebugVar( "AcqAD" ) ) ) )
//			ShowMode = UFPE_MSGLINE 
//		endif
//
//		// Although it would seem safe we do NOT reset the CED1401 (nor use KillIO) because	1. the Power1401 would not start next acquisition.
//		//																2. there would be an undesired  1ms glitch on all digouts appr.500ms after end of stimulus (only on 1401plus) 
//		CEDSendStringCheckErrors( "ADCBST,K;" , 0 ) 						// 2003-1111 kill the sampling process
//		CEDSendStringCheckErrors( "MEMDAC,K;" , 0 ) 						// 2003-1111 kill the stimulation process
//		CEDSendStringCheckErrors( "DAC,0 1 2 3,0 0 0 0;" , 0 ) 				// 2003-1111 set all DACs to 0 when aborting 
//		CEDSendStringCheckErrors( "DIGTIM,K;" , 0 ) 						// 2003-1111 kill the digital output process
//		CEDSetAllDigOuts( 0 )										// 2003-1111 Initialize the digital output ports with 0 : set to LOW
//
//		nvar	gnReps	= $"root:uf:acq:" + sSubFoC + ":gnReps"
//		// printf "\t\t\tStopADDA(3) \t\t\tgnReps: %2d   \r ", gnReps
//		if ( gnReps > 1 )		
//			// 2003-1030 Unfortunately we cannot use 'gnAcqStatus'  to reflect the time spent in the following function  'CEDInitializeDacBuffers()'  in a  'STC/kSTC'  string color  field display,  neither  by setting the controlling..
//			// ..global 'gnAcqStatus' directly  nor  indirectly by a dependency relation 'gbAcqStatus :=  f( gbReloading )  as we are right now still in the background task, and controls are only updated when Igor is idling. 
//			// Workaround : It is possible  (even when in the middle of a background function)  to change directly  the title of a button, but this is not really what we want.
//			// Code (NOT working)  :		nvar gnAcqStatus=root:uf:"+sFo+":pul:gnAcqStatus; gnAcqStatus=2   
//			// Code (NOT working either) :  	nvar gbReloading=root:uf:acq:co:gbReloading; gbReloading=UFCom_TRUE ; do something; gbReloading=UFCom_FALSE;    and coded elsewhere	SetFormula root:uf:"+sFo+":pul:gnAcqStatus, "root:uf:acq:co:gbReloading * 2"
//			
//			// printf "\t\t\tStopADDA(4) \t\t\tgnReps: %2d \t-> CEDInitializeDacBuffers() \r ", gnReps
//
//			CEDInitializeDacBuffers( sFo, wRaw )			// Ignore (by NOT measuring)  'Transfer' and 'Convolve' times here after finishing as they have no effect on acquisition (only on load time)
//
//		endif
//		
//	endif
//
//	if ( nRadDebgGen <= 1 ||  UFCom_DebugVar( "AcqDA" )  ||  UFCom_DebugVar( "AcqAD" ) )
//		printf "%s  \r", strExplain
//	endif
//
//	if ( gbQuickAcqCheck )									//  for quick testing the integrity of acquired data including telegraph channels
//		QuickAcqCheck( sFo, wRaw )
//	endif
//
//	gbRunning	= UFCom_FALSE 									// 2003-1030
//	StartStopFinishButtonTitles( sFo , sSubFoC )							// 2003-1030 reflect change of 'gbRunning' 
//
//	gnTicksStop	= ticks 									// save current  tick count  (in 1/60s since computer was started) 
//
//	UFCom_EnableButton( "pul", 	"root_uf_acq_pul_ApplyScript0000",	UFCom_kCo_ENABLE )
//	UFCom_EnableSetVar( "pul", 	"root_uf_acq_pul_gnProts0000",	UFCom_kCo_ENABLE_SV )	// ..allow also changing the number of protocols ( which triggers 'ApplyScript()'  )
//	UFCom_EnableButton( "pul", 	"root_uf_acq_pul_LoadScript0000",	UFCom_kCo_ENABLE )
//	UFCom_EnableButton( "pul", 	"root_uf_acq_pul_buDelete0000",	UFCom_kCo_ENABLE )// 2005-05-30 Allow deletion of the current file only after acquisition has stopped
//
//	ShowTimingStatistics( sFo )
//
//	 printf "\t\tStopAdda( before  ApplyScript ) \tbTrigMode : %d     running: %d   bApplyScript:%2d   WaveExists(): wRaw:%d \r", bTrigMode, gbRunning, bDoApplyScript, WaveExists(wRaw)
//	if ( bDoApplyScript )
//		ApplyScript() 										// kills and rebuilds wIO, wVal, wFix, wE, wBFS ( wG is maintained in folder UFPE_ksKEEP )
//		// printf "\t\tStopAdda(  after   ApplyScript ) \tbTrigMode : %d     running: %d   bApplyScript:%2d   WaveExists(): wRaw:%d \r", bTrigMode, gbRunning, bDoApplyScript, WaveExists(wRaw)
//	endif
//
//	if ( bTrigMode == 1 ) 	// 2003-10-25 continuous hardware trig'd mode: (re)arm the trigger detection after a stimulus is finished so that each new trigger on E3E4 triggers the next acquisition run
//		// printf "\t\t\tStopADDA(6) \t\t\t-> StartStimulusAndAcquisition() \r "					// 2003-1119
//		StartStimulusAndAcquisition( sSubFoC, sSubFoW ) 	//  this will call  'CedStartAcq'  which will  set  'gbRunning'  UFCom_TRUE
//	endif
//End


//Function		StartStopFinishButtonTitles( sFo, sSubFoC )
//// Enables and disables 'Start/Stop/Finish/Trigger mode/Apppend data' related buttons depending on the control's settings  AND  on program state ('gbRunning, gbAcquiring')
//// For this to work this function must EXPLICITLY be called every time one of the input parameters changes. 
//// This easily done (without any negative impact) for the controls by putting a call to this function into the action procedure.
//// For reflecting the state of  non-control globals like 'gbRunning, gbAcquiring' a call to this function must be placed in the background procedure where  'gbRunning, gbAcquiring'  change .
//// This might possibly have a negative impact on program behaviour but actually it seems to work fine....   
//// TODO  031030   measure time needed for the execution of this function and then decide.....
//// Possible workaround : Ignore changes of  'gbRunning, gbAcquiring'  in the button title ,  instead place a  'STC/kSTC'  string color  field  in the vicinity of the button.
//// A  'STC/kSTC'  string color  field is updated automatically through a dependency and does not need an explicit call when an input parameter changes.
//
//// 2003-1031 flaw: In mode  HW trigger,  not appending, not acquiring the button 'Finish'  should be on  initially  but  should  be disabled after being pressed once and be enabled by the next 'Start'='gbAcquiring'
//	string  	sFo
//	string  	sSubFoC			// 'co'  or  'cons'
//
//	variable	bTrigMode		= TrigMode()
//	variable	bAppendData	= AppendData()
//	nvar		gbRunning 	= $"root:uf:acq:" + UFPE_ksKEEP + ":gbRunning"
//	nvar		gbAcquiring 	= $"root:uf:acq:" + sSubFoC + ":gbAcquiring"
//	string  	sPanel		= "pul"
//	string		sBuStartNm	= "root_uf_acq_pul_StartAcq0000"
//	string		sBuStopNm	= "root_uf_acq_pul_StopFinish0000"
//	string		sStartStop		= "S t a r t"
//
//	if ( bTrigMode == 0  &&   !  bAppendData  &&  ! gbRunning )		// normal  SW triggered mode, 
//		Button	$sBuStopNm 	win = $sPanel,	title = "Stop",	disable = UFCom_kCo_DISABLE
//		UFCom_EnableButton( sPanel, sBuStartNm,		UFCom_kCo_ENABLE )						//	 
//	endif
//	if ( bTrigMode == 0  &&   ! bAppendData	  &&    gbRunning )	// normal  SW triggered  mode, 
//		Button	$sBuStopNm	win=$sPanel,	 title = "Stop",	disable = UFCom_kCo_ENABLE	
//		UFCom_EnableButton( sPanel, sBuStartNm,		UFCom_kCo_DISABLE )						// 
//	endif
//	if ( bTrigMode == 0  &&    bAppendData	  &&  ! gbRunning )	// normal  SW triggered  mode, 
//		Button	$sBuStopNm	win=$sPanel,	 title = "Finish",	disable = UFCom_kCo_ENABLE
//		UFCom_EnableButton( sPanel, sBuStartNm,		UFCom_kCo_ENABLE )						// 
//	endif
//	if ( bTrigMode == 0  &&    bAppendData	  &&    gbRunning )	// normal  SW triggered  mode, 
//		Button	$sBuStopNm	win=$sPanel,	 title = "Stop",	disable = UFCom_kCo_ENABLE
//		UFCom_EnableButton( sPanel, sBuStartNm,		UFCom_kCo_DISABLE )						// 
//	endif
//
//	if ( bTrigMode == 1	&&  ! bAppendData	&&   ! gbAcquiring )				// HW E3E4 triggered mode, 
//		Button	$sBuStopNm	win=$sPanel,	 title = "Finish"
//		UFCom_EnableButton( sPanel, sBuStartNm,		UFCom_kCo_DISABLE )						// 
//	endif
//	if ( bTrigMode == 1	&&  ! bAppendData	&&     gbAcquiring )				// HW E3E4 triggered mode, 
//		Button	$sBuStopNm	win=$sPanel,	 title = "Stop",	disable = UFCom_kCo_ENABLE
//		UFCom_EnableButton( sPanel, sBuStartNm,		UFCom_kCo_DISABLE )						// 
//	endif
//	if ( bTrigMode == 1	&&    bAppendData	&&   ! gbAcquiring )				// HW E3E4 triggered mode, 
//		Button	$sBuStopNm	win=$sPanel,	 title = "Finish",	disable = UFCom_kCo_ENABLE
//		UFCom_EnableButton( sPanel, sBuStartNm,		UFCom_kCo_DISABLE )						// 
//	endif
//	if ( bTrigMode == 1	&&    bAppendData	&&     gbAcquiring )				// HW E3E4 triggered mode, 
//		Button	$sBuStopNm	win=$sPanel,	 title = "Stop",	disable = UFCom_kCo_ENABLE
//		UFCom_EnableButton( sPanel, sBuStartNm,		UFCom_kCo_DISABLE )						// 
//	endif
//
//End
//

//Function		QuickAcqCheck( sFo, wRaw )
//	// Extra window for detection of acquisition errors including telegraph channels.  'Display raw data after acq' also works but does not display the telegraph channels. 
//	// You must kill the window before each acquisition because to avoid graph updating which slows down the acquisition process appreciably.  
//	string  	sFo
//	wave	wRaw
//	wave  	wG		= $"root:uf:" + sFo + ":" + UFPE_ksKPwg + ":wG"  	// This  'wG'  	is valid in FPulse ( Acquisition )
//	wave  /T	wIO		= $"root:uf:" + sFo + ":ar:wIO"  			// This  'wIO'   	is valid in FPulse ( Acquisition )
//	nvar		gnCompress		= root:uf:acq:co:gnCompressTG	
//	variable	nSmpInt			= UFPE_SmpInt( sFo )
//	variable	nCntAD			= wG[ UFPE_WG_CNTAD ]	
//	variable	nCntTG			= wG[ UFPE_WG_CNTTG ]	
//	variable	c, red, green, blue
//	string		sWaveNm, sFolderWaveNm
//	string		sQuickAcqCheckNm	= "QuickCheck"		// cannot name it 'QuickAcqCheck' as this is the function name 
//
//	DoWindow	$sQuickAcqCheckNm				// check if the 'QuickAcqCheck' window exists
//	if ( V_Flag == 1 )									// ..if it exists then V_Flag will be true
//		DoWindow  /K	$sQuickAcqCheckNm			// ..kill it
//	endif 
//	display /K=1 									// allow killing by pressing the window close button
//	DoWindow  /C $sQuickAcqCheckNm					// rename window to  'QuickAcqCheck'
//
//	// this display order may not be optimal  in test mode without CED.  Adc2 is filled with much noise, Adc0 with little noise and  may be obscured by Adc2
//	for ( c = 0; c < nCntAD; c += 1)	
//		sWaveNm		 = ADTGNm( wG, wIO, c )
//		sFolderWaveNm = FldAcqioADTGNm( sFo, wG, wIO, c  )
//		red		= 64000 * ( c== 0 ) + 64000  * ( c== 3 ) + 64000  * ( c== 4 )
//		green	= 64000 * ( c== 1 ) + 64000  * ( c== 4 ) + 64000  * ( c== 5 )
//		blue		= 64000 * ( c== 2 ) + 64000  * ( c== 5 ) + 64000  * ( c== 3 ) 
//		AppendToGraph $sFolderWaveNm
//		ModifyGraph rgb( $sWaveNm )	= ( red, green, blue )
//		SetScale /I x , 0, numPnts( $sFolderWaveNm ) * nSmpInt / 1e6 , "s", $sFolderWaveNm
//	endfor
//	for ( c = nCntAD; c < nCntAD + nCntTG; c += 1)	
//		sWaveNm		 = ADTGNm( wG, wIO, c )
//		sFolderWaveNm = FldAcqioADTGNm( sFo, wG, wIO, c )
//		red		= 64000 * ( c== 0 ) + 64000  * ( c== 3 ) + 64000  * ( c== 4 )
//		green	= 64000 * ( c== 1 ) + 64000  * ( c== 4 ) + 64000  * ( c== 5 )
//		blue		= 64000 * ( c== 2 ) + 64000  * ( c== 5 ) + 64000  * ( c== 3 ) 
//		AppendToGraph $sFolderWaveNm
//		ModifyGraph rgb( $sWaveNm )	= ( red, green, blue )
//		SetScale /I x , 0, numPnts( $sFolderWaveNm ) * gnCompress * nSmpInt / 1e6 , "s" , $sFolderWaveNm
//	endfor
//	// printf "\t\tQuickAcqCheck(): displays window for acq error detection including telegraph channels. Kill this window before every acq for maximum speed.\r" 
//End
//
//
//static Function		TotalStorePoints( sFo, nSmpInt)
//	string  	sFo
//	variable	nSmpInt
//	variable	bl, l = 0, fr, sw, pts = 0
//	variable	pr	= 0				//  NOT  REALLY   PROTOCOL  AWARE  ..........
//	for ( bl  = 0; bl < UFPE_eBlocks( sFo ); bl += 1 )
//		for ( fr = 0; fr < UFPE_eFrames_( sFo, bl ); fr += 1 )
//			for ( sw = 0; sw < UFPE_eSweeps_( sFo, bl ); sw += 1 )
//				pts += UFPE_SweepEndSave( sFo, pr, bl, l, fr, sw ) - UFPE_SweepBegSave( sFo, pr, bl, l, fr, sw )	//  NOT  REALLY   PROTOCOL  AWARE  ..........
//			endfor
//		endfor
//	endfor
//	 print "TotalStorePoints()  ", pts 
//	return	pts
//End
//
//
//Function		ShowTimingStatistics( sFo )
//	string  	sFo
//	wave  	wG		= $"root:uf:" + sFo + ":" + UFPE_ksKPwg + ":wG"  	// This  'wG'  	is valid in FPulse ( Acquisition )
//	variable	nProts			= UFPE_Prots( sFo )
//	nvar		gnReps			= root:uf:acq:co:gnReps
//	nvar	 	gChnkPerRep		= root:uf:acq:co:gChnkPerRep
//	nvar		gPntPerChnk	 	= root:uf:acq:co:gPntPerChnk
//	variable	nSmpInt			= UFPE_SmpInt( sFo )
//	variable	nCntDA			= wG[ UFPE_WG_CNTDA ]	
//	variable	nCntAD			= wG[ UFPE_WG_CNTAD ]	
//	variable	nCntTG			= wG[ UFPE_WG_CNTTG ]	
//	nvar		gnCompress		= root:uf:acq:co:gnCompressTG
//	nvar		gReserve			= root:uf:acq:co:gReserve
//	nvar		gMinReserve		= root:uf:acq:co:gMinReserve
//	nvar		gMaxSmpPtspChan	= root:uf:acq:co:gMaxSmpPtspChan
//	nvar		gbShowTimingStats	= $"root:uf:"+sFo+":mis:TimeStats0000"
//	variable	nTransConvPtsPerCh	= gChnkPerRep * gPntPerChnk * gnReps
//	variable	nTransConvChs		= nCntAD+ nCntDA + nCntTG / gnCompress
//	variable	nTransferPts		= nTransConvPtsPerCh * nTransConvChs
//	variable	nConvolvePts		= nTransConvPtsPerCh * nTransConvChs
//	variable	nCFSWritePtsPerCh 	= TotalStorePoints( sFo, wG ) * nProts	// this number of points is valid for Writing AND Processing
//	variable	nGraphicsPtsPerCh 	= TotalStorePoints( sFo, wG ) * nProts	// todo not correct: superimposed sweeps not included
//	variable	nCFSWritePts		= nCFSWritePtsPerCh *  nCntAD 
//	variable	nGraphicsPts		= nGraphicsPtsPerCh *  nCntAD // todo not correct: DAC may also be displayed, superimposed sweeps not included 
//	variable	TransferTime		= UFCom_ReadTimer( sFo, "Transfer" )
//	variable	ConvolveTime		= UFCom_ReadTimer( sFo, "Convolve" )
//	variable	GraphicsTime		= UFCom_ReadTimer( sFo, "Graphics" )
//	variable	CFSWriteTime		= UFCom_ReadTimer( sFo, "CFSWrite" )
//	variable	OnlineAnTime		= UFCom_ReadTimer( sFo, "OnlineAn" )
//	//variable	FreeUseTime		= UFCom_ReadTimer( sFo, "FreeUse" )
//	variable	ProcessTime		= UFCom_ReadTimer( sFo, "Process" )
//	variable	InRoutinesTime		= TransferTime + ConvolveTime + CFSWriteTime + GraphicsTime + ProcessTime 	
//	variable	ProtocolTotalTime	= nTransConvPtsPerCh * nSmpInt / 1000
//	variable	ProtocolStoredTime	= nCFSWritePtsPerCh * nSmpInt / 1000
//	variable	AttemptedADRate	= 1000 * nCntAD / nSmpInt
//	variable	AttemptedFileSize	= AttemptedADRate * ProtocolStoredTime * 2 / 1024 / 1024
//	variable	TAused			= TAUse( gPntPerChnk, nCntDA, nCntAD, cMAX_TAREA_PTS )
//	variable	MemUsed			= MemUse( gChnkPerRep, gPntPerChnk, gMaxSmpPtspChan )
//
//	UFCom_StopTimer( sFo, "TotalADDA" )		
//	UFCom_PrintAllTimers( sFo, 1 )
//	if ( gbShowTimingStats )
//		printf "\t\tTIMING STATISTICS ( Prots:%2d , Rep:%2d ,  CpR:%2d , PtpChk:%6d / %d ,  %d us,  %.1lf MB,  Reserve:%d / %d / %d, TA:%d%%, Mem:%d%% ) \r", nProts, gnReps, gChnkPerRep, gPntPerChnk, gPntPerChnk * ( nCntAD + nCntTG ), nSmpInt, AttemptedFileSize, gMinReserve, gReserve, gChnkPerRep, TAUsed, MemUsed
//		printf  "\t\tTransfer:  \t\t%3.2lf\tch *\t %11d \t=%11d\tpts\t%8.0lf\tms  -> %5.2lf\t/ %5.2lf\tus / pt \t= %5.1lf\t%% of SI \r", nTransConvChs,   nTransConvPtsPerCh,   nTransferPts,   TransferTime,  TransferTime / nTransferPts * 1000,   TransferTime / nTransConvPtsPerCh * 1000 ,   TransferTime / nTransConvPtsPerCh / nSmpInt * 100000
//		printf  "\t\tConvolve:\t\t%3.2lf\tch *\t%7d\t=\t%7d\tpts \t%7d\tms  -> %5.2lf\t/ %5.2lf\tus / pt \t= %5.1lf\t%% of SI  \r",  nTransConvChs, nTransConvPtsPerCh, nConvolvePts, ConvolveTime, ConvolveTime / nConvolvePts * 1000, ConvolveTime / nTransConvPtsPerCh * 1000, ConvolveTime / nTransConvPtsPerCh / nSmpInt * 100000
//		printf  "\t\tGraphics: \t\t%3d \tch *\t%7d\t=\t%7d\tpts \t%7d\tms  -> %5.2lf\t/ %5.2lf\tus / pt \t= %5.1lf\t%% of SI  \r", nCntAD, nGraphicsPtsPerCh, nGraphicsPts, GraphicsTime, GraphicsTime / nGraphicsPts * 1000, GraphicsTime / nGraphicsPtsPerCh * 1000, GraphicsTime / nGraphicsPtsPerCh /nSmpInt * 100000
//		printf  "\t\tOnlineAnal: \t%3d \tch *\t %11d \t=%11d\tpts \t%7d\tms  -> %5.2lf\t/ %5.2lf\tus / pt \t= %5.1lf\t%% of SI  \r", nCntAD, nCFSWritePtsPerCh, nCFSWritePts, OnlineAnTime, OnlineAnTime / nCFSWritePts * 1000, OnlineAnTime / nCFSWritePtsPerCh * 1000, OnlineAnTime / nCFSWritePtsPerCh / nSmpInt * 100000 
//		printf  "\t\tCfsWrite:  \t\t%3d \tch *\t %11d \t=%11d\tpts \t%7d\tms  -> %5.2lf\t/ %5.2lf\tus / pt \t= %5.1lf\t%% of SI  \r", nCntAD, nCFSWritePtsPerCh, nCFSWritePts, CFSWriteTime, CFSWriteTime / nCFSWritePts * 1000, CFSWriteTime / nCFSWritePtsPerCh * 1000, CFSWriteTime / nCFSWritePtsPerCh / nSmpInt * 100000 
//		// printf"\t\tFreeUse:  \t%3d \tch *\t %11d \t=%11d\tpts \t%7d\tms  -> %5.2lf\t/ %5.2lf\tus / pt \t= %5.1lf\t%% of SI  \r", nCntAD, nCFSWritePtsPerCh, nCFSWritePts, FreeUseTime, FreeUseTime / nCFSWritePts * 1000, FreeUseTime / nCFSWritePtsPerCh * 1000, FreeUseTime / nCFSWritePtsPerCh / nSmpInt * 100000 
//		printf  "\t\tProcessing: \t%3d \tch *\t %11d \t=%11d\tpts \t%7d\tms  -> %5.2lf\t/ %5.2lf\tus / pt \t= %5.1lf\t%% of SI  \r", nCntAD, nCFSWritePtsPerCh, nGraphicsPts, ProcessTime, ProcessTime / nCFSWritePts * 1000, ProcessTime / nCFSWritePtsPerCh * 1000, ProcessTime / nCFSWritePtsPerCh / nSmpInt * 100000 
//		printf  "\t\tProtocol(total/stored):\t%d / %d ms  \tMeasured(routines): %d = %.1lf%% \t\tMeasured(overall): %d = %.1lf%% \r", ProtocolTotalTime,  ProtocolStoredTime, InRoutinesTime,  InRoutinesTime / ProtocolTotalTime * 100, UFCom_ReadTimer( sFo, "TotalADDA" ), UFCom_ReadTimer( sFo, "TotalADDA" )/ ProtocolTotalTime * 100
//	endif
//End
//
//constant		DADIREC = 0, ADDIREC = 1		// same as in XOP MWave.C
//
//static Function	ConvolveBuffersDA( sFo, wIO, nChunk, nRep, nChunksPerRep, nChs, PtpChk, wRaw, nHostOfs, nPnts )
//// mixes points of all  separate DAC-channel stimulus waves  together in small wave ' wRaw'  in transfer area 
//	string  	sFo
//	wave  /T	wIO
//	variable	nChunk, nRep, nChunksPerRep, nChs, PtpChk, nHostOfs, nPnts
//	wave	wRaw
//	variable	nRadDebgSel		= UFCom_DebugDepthSel()
//	variable	pt, begPt	  = PtpChk  * nChunk					// BegPt and EndPt are points in the CED sampling area (typ. 16MB) ....
//	variable	endPt	  = PtpChk * ( nChunk + 1 )				// The same BegPt and EndPt are passed multiple times if nReps is >1 (=long scripts and/or many protocols)
//	variable	repOs	  = nRep * PtpChk * nChunksPerRep		// BegPt and EndPt  PLUS the repetition offset 'repOs' gives the true point number in the DAC wave independently from the CED sampling area size
//	variable	DACRange = 10							// + - Volt
//	variable	c,	nIO	  = UFPE_IOT_DAC
//	if ( ( nRadDebgSel == 2  ||  nRadDebgSel == 3 )  &&   UFCom_DebugVar( "AcqDA" ) )
//		printf "\t\tConvDA( \tc:%d\t\t\tnChunk:%2d\tnRep:%2d\tCPRep:%2d\tnChs:%d\tPtpChk:%5d\tnHostOfs:%5d\tbeg:\t%8d\tend:\t%8d\trOs: %10d  \twRaw:%5dpts\tnPnts:\t%8d \r", c, nChunk, nRep, nChunksPerRep, nChs, PtpChk, nHostOfs, begpt, endpt, repOs, numPnts( wRaw ), nPnts
//	endif
//	for ( c = 0; c < nChs; c += 1 )
//		variable	ofs		= c + nHostOfs 
//		variable	yscl		=  UFPE_iov( wIO, nIO, c, UFPE_IO_GAIN ) * UFPE_kMAXAMPL / 1000 / DACRange					// scale  in mV
//		wave	wDacReal	= $UFPE_ioFldAcqioio( sFo, wIO, nIO, c, UFPE_IO_NM ) 								
//		// printf "\t\t\t\tAcqDA Cnv>DA14>Cpy\t %10d  \t%8d",  2*begPt, 2*(mod(begPt,(2*PtpChk))+ofs)	
//
//		variable	code	= UFCom_UtilConvolve( wDacReal, wRaw, DADIREC, nChs, 0, begPt, endPt, RepOs, PtpChk, ofs, yscl, 0, 0, 0, nPnts, 0 )	// ~ 40ns / data point
//		if ( code )
//			printf "****Error: UFCom_UtilConvolve() DA returns %d (%g)  \r", code, code
//		endif
////		 for ( pt =   begPt;  pt < endPt;   pt += 1 )
////			variable	pt1	= mod( pt + repOs, wG[ UFPE_WG_PNTS ] )									// Simple code without compression
////			wRaw[ mod( pt, (2*PtpChk)) * nChs + ofs ]  = wDacReal[ trunc( pt1 / SmpF ) ] * yscl			// ~ 4 us  / data point  (KEEP: including SmpF)
////		 endfor
//	endfor
//	return	endPt  + repOs
//End
//
//
//
//static Function	DeconvolveBuffsAD( sFo, wG, wIO, nChunk, nRep, nChunksPerRep, PtpChk, wRaw, nHostOfs, nCntAD, nCntTG, nCompress, nPnts )
//// extracts mixed points of all ADC -  and  TG - channels from ' wRaw' transfer area into separate IGOR AD waves
//	string  	sFo
//	wave	wG
//	wave  /T	wIO
//	variable	nChunk, nRep, nChunksPerRep, PtpChk, nHostOfs, nCntAD, nCntTG, nCompress, nPnts
//	wave	wRaw
//	variable	nRadDebgSel	= UFCom_DebugDepthSel()
//	variable	nChs			= nCntAD + nCntTG
//	variable	pt, BegPt		= PtpChk  * nChunk
//	variable	EndPt		= PtpChk * ( nChunk + 1 )
//	variable	RepOs		= ( nRep - 1 ) * PtpChk * nChunksPerRep
//
//variable	bStoreIt, nBigChunk= ( BegPt + RepOs ) / PtpChk 
//if ( UFPE_kELIMINATE_BLANK )
//	bStoreIt	= UFPE_StoreChunkorNot( sFo, nBigChunk )				
//else
//	bStoreIt	= 1
//endif
//
//	variable	c = 0, yscl	=  UFPE_kMAXAMPL / UFPE_kFULLSCL_mV			// scale in mV
//	variable	ofs, nSrcStartOfChan, nSrcIndexOfChan
//	string		sRealWvNm	= FldAcqioADTGNm( sFo, wG, wIO, c )
//
//	if ( ( nRadDebgSel == 2  ||  nRadDebgSel == 3 )  &&  UFCom_DebugVar( "AcqAD" ) ) 
//		printf "\t\tDeConvAD( \tc:%d\t'%s'\tnChunk:%2d\tnRep:%2d\tCPRep:%2d\tnChs:%d\tPtpChk:%5d\tnHostOfs:%5d\tbpt:\t%7d\tept:\t%7d\tBigChk:\t%7d\tStore: %d\t \r", c, sRealWvNm, nChunk, nRep, nChunksPerRep, nChs, PtpChk, nHostOfs, begpt, endpt, nBigChunk, bStoreIt
//	endif
//
//	for ( c = 0; c < nCntAD + nCntTG; c += 1 )				// ASSUMPTION: order of channels is first ALL AD, afterwards ALL TG in  UFCom_UtilConvolve()
//		sRealWvNm	= FldAcqioADTGNm( sFo, wG, wIO, c )
//		wave   wReal 	=  $sRealWvNm		
//		// printf "\t\tDeConvAD( \tc:%d\t'%s'\tnChunk: %3d\tnRep:%2d\tCPRep:%2d\tnChs:%d\tPtpChk:%5d\tnHostOfs:\t%9d\tbpt:\t%9d\tept:\t%9d\t np:\t%4d\tsto:%d\tad:%d\ttg:%d\tro:\t%4d\tco:%3d\t  \r", c, sRealWvNm, nChunk, nRep, nChunksPerRep, nChs, PtpChk, nHostOfs, begpt, endpt, nPnts, bStoreIt, nCntAD, nCntTG, RepOs, nCompress 
//		// UFCom_PrintWave( "PrintWave  a  DeConvAD  " + sRealWvNm, wReal )
//
//		// bStoreIt : Set  'Blank'  periods (=periods during which data were sampled but not transfered to host leading to erroneous data in the host area)  to  0  so that the displayed traces  look nice.  
//		variable	code	= UFCom_UtilConvolve( wReal, wRaw, ADDIREC, nCntAD, nCntTG, BegPt, EndPt, RepOs, PtpChk, nHostOfs, yscl, nCompress, nChunk, c, nPnts, bStoreIt )	// ~ 40ns / data point
//		if ( code )
//			printf "****Error: UFCom_UtilConvolve() AD returns %d (%g)  Is Nan:%d \r", code, code, numtype( code) == UFCom_kNUMTYPE_NAN
//		endif
//
//	endfor
//
//	return 	endPt  + repOs 
//End
//
//
//constant		FILTERING			= 10000	// 1 means ADC=DAC=no filtering,    200 means heavy filtering
//constant		NOISEAMOUNT		= 0.002	// 0 means no noise,   1 means noise is appr. as large as signal   (for channel 0 )
//constant		CHANGE_TG_SECS 	= 2			// gain switching by simulated telegraph channels will ocur with roughly this period
//
//
//static Function	TestCopyRawDAC_ADC( wG, nChunk, PtpChk, wRaw, nDACHostOfs, nADCHostOfs )
//// helper for test mode without CED1401: copies dac waves into adc waves
//// Multiple Dac channels are implemented but not tested...
//	wave	wG
//	variable	nChunk, PtpChk, nDACHostOfs, nADCHostOfs
//	wave	wRaw
//	variable	nCntDA		= wG[ UFPE_WG_CNTDA ]	
//	variable	nCntAD		= wG[ UFPE_WG_CNTAD ]	
//	variable	nCntTG		= wG[ UFPE_WG_CNTTG ]	
//	nvar		gnCompress	= root:uf:acq:co:gnCompressTG
//	variable	pt, ch, nChs 	= max( nCntDA, nCntAD ), indexADC, indexDAC, indexTG
//	variable	nFakeTGvalue	= 27000 + 5000 * mod( trunc( ticks / CHANGE_TG_SECS / 100), 2 ) // gain(27000):1, gain(32000):2,  gain(54000):gain50, gain(64000):200
//	//variable	ADCRange	= 10						// + - Volt
//	variable	yscl	=  UFPE_kMAXAMPL / UFPE_kFULLSCL_mV//1000 / ADCRange		// scale in mV
//
//	// printf "\t\tAcqDA TestCopyRawDAC_ADC()   nChunk:%d   PtpChk:%d   Compr:%d  nDA:%d   nAD:%d   nTG:%d    max() = nChs:%d  nFakeTGvalue:%d \r", nChunk, PtpChk, gnCompress, nCntDA, nCntAD, nCntTG, nChs, nFakeTGvalue
//	nChunk	= mod( nChunk, 2 ) 
//	// Fake the AD channels
//	for ( ch = 0; ch < nCntAD; ch += 1 )
//		// get average to add some noise (proportional to signal) to fake ADC data if no CED1401 is present
//		variable	nBegIndexDAC =  PtpChk * nChunk 	*	nCntDA + min( ch, nCntDA - 1 ) + nDACHostOfs
//		variable	nEndIndexDAC =  PtpChk * (nChunk+1)  *	nCntDA + min( ch, nCntDA - 1 ) + nDACHostOfs
//		wavestats /Q /R=(nBegIndexDAC, nEndIndexDAC) wRaw 
//		variable	ChanFct	= 10^ch									// Ch0: 1 ,  Ch1: 10  , Ch2: 100
//		for ( pt = PtpChk * nChunk;  pt < PtpChk * ( nChunk + 1 );   pt += 1 )		// if there are the same number of DA and AD they are mapped 1 : 1
//
//			indexDAC =  pt + (nChunk ) * min( ch, nCntDA - 1 ) * PtpChk +	nDACHostOfs	// it there is only 1 DA but more than 1 AD the DA is mapped to all ADs  with different amount of filtering and noise
//			indexADC =  pt + ( nChunk * ( nCntAD + nCntTG - 1 ) +  ch ) * PtpChk + nADCHostOfs	// if there is only 1 AD it is mapped to DA0
//	
//			// filtering is implemented here to see a difference between DAC and ADC data
//			//! integer arithmetic gives severe and very confusing rounding errors with amplitudes < 20
//			// chan 0 : little noise, heavy filtering , chan 1 : medium noise, medium filtering,  chan 2 : much noise , little filtering
//		 	wRaw[ indexADC ]  =  ChanFct / FILTERING * wRaw[  indexDAC ] + ( 1 - ChanFct / FILTERING ) * wRaw[ indexDAC - min( ch, nCntDA - 1 ) ]  + ChanFct * gNoise( V_avg  * NOISEAMOUNT)  
//		endfor
//	endfor
//
//	// Fake the telegraph channels
//	for ( ch = 0; ch < nCntTG; ch += 1 )
//		for ( pt = PtpChk * nChunk;  pt < PtpChk * ( nChunk + 1 );   pt +=  gnCompress )		
//			indexTG =  pt +  ( nChunk * ( nCntAD + nCntTG - 1 ) + ( ch  + nCntAD ) ) / gnCompress * PtpChk + nADCHostOfs	
//		 	wRaw[ indexTG /gnCompress ]   	=   ( ch + 1 ) * nFakeTGvalue / yscl
//		endfor
//	endfor
//	return 0
//End
//
//
//static Function	/S	FldAcqioADTGNm( sFo, wG, wIO, cio )
//// Returns wave name (including folder) for Adc or telegraph wave  when  index  cio = 0,1,2... is given. 	ASSUMPTION: order of channels is first ALL AD, afterwards ALL TG
//	string  	sFo
//	wave	wG
//	wave  /T	wIO
//	variable	cio
//	string  	sNm	= "root:uf:" + sFo + ":" + UFPE_ksF_IO + ":" + ADTGNm( wG, wIO, cio ) 
//	// printf "\t\t\tFldAcqioADTGNm( \t'%s' \tcio:%2d )  \t-> '%s' \r", sFo, cio, sNm
//	return	sNm
//End
//
//static Function	/S	ADTGNm( wG, wIO, cio )
//// Returns wave name for Adc or telegraph wave  when  index  c = 0,1,2... is given. 	ASSUMPTION: order of channels is first ALL AD, afterwards ALL TG
//	wave	wG
//	wave  /T	wIO
//	variable	cio
//	variable	nChanNr, nCntAD	= wG[ UFPE_WG_CNTAD ]	
//
//	if ( nCntAD == 0 )		// 2005-1202	 introduced to avoid hanging in infinite loop below for if there are no AD channels
//		return ""
//	endif
//
//	if ( cio < nCntAD )
//		nChanNr	= UFPE_iov( wIO, UFPE_IOT_ADC, cio, UFPE_IO_CHAN )
//		// printf "\t\t\tADTGNm( \tc:%2d /%2d AD, %2d TG ) \t-> is AD , true AD chan number  : %d   -> '%s' \r", cio, nCntAD, wG[ UFPE_WG_CNTTG ], nChanNr , AdcNm( nChanNr ) 	
//		return	AdcNm( nChanNr ) 					// The wave name of a true AD channel...
//	else											// ..must be different  from the wave name of a telegraph channel.
//
//		variable nWrongChanNr	=  UFPE_TGChan( wIO, UFPE_IOT_ADC, cio  - nCntAD )		// 2004-1201 WRONG
//		variable	cTG, nSkip = 0											// 2004-1201 Flaw : Seach every time. This searching could be avoided if a global list was created once......
//		for ( cTG	= nCntAD; cTG <= cio; cTG += 1 )								// for all TG channels starting at the TG index = 0   ~   True Adc index = nCntAd
//			nChanNr	= UFPE_iov( wIO, UFPE_IOT_ADC, cTG - nCntAD + nSkip, UFPE_IO_TGCH ) 		// loop through the true Ad channels and try to extract the accompanying  TG channel		
//			if ( numType( nChanNr ) == UFCom_kNUMTYPE_NAN )						// there may be true Adc chans without a TG chan...
//				nSkip += 1												// ...these have  Nan  as TG chan : skip them...
//				cTG	-= 1												// ...and check same channel again
//			endif
//		endfor
//
//		 printf "\t\t\tADTGNm( \t\t\tcio:%2d /%2d AD, %2d TG ) \t-> is TG , true AD chan number  : %d   -> '%s'   [nWrongChanNr:%2d] \r", cio, nCntAD, wG[ UFPE_WG_CNTTG ], nChanNr , TGNm( nChanNr ), nWrongChanNr
//		return	TGNm( nChanNr ) 					// This allows that the same telegraph channel is also sampled and processed.. 
//	endif											// ..independently as true AD channel. This is (at least) very useful for testing....
//End
//
//Function	/S	AdcNm( ch )
//// Returns wave name for Adc (not for telegraph, their name must differ!) wave when true channel number from script is given
//	variable	ch
//	return	"Adc" + num2str( ch  )
//End
//
//Function	/S	FldAcqioTgNm( sFo, ch )
//// Returns wave name  (including folder)  for  telegraph wave when true channel number from script is given. This name must be different from the name for the true Adc wave
//	string  	sFo
//	variable	ch
//	return	"root:uf:" + sFo + ":" + UFPE_ksF_IO + ":" + TGNm( ch ) 
//End
//
//Function	/S	TgNm( ch )
//// Returns wave name for  telegraph wave when true channel number from script is given. This name must be different from the name for the true Adc wave
//	variable	ch
//	return	AdcNm( ch ) + "T"
//End
//
//
//static Function		SupplyWavesADC( sFo, wG, wIO, nPts )
//	// supply  ADC channel waves (as REAL)  here 
//	string  	sFo
//	wave	wG
//	wave  /T	wIO
//	variable	nPts
//	variable	nProts	= UFPE_Prots( sFo )
//	variable	nCntAD	= wG[ UFPE_WG_CNTAD ]	
//	variable	c
//	string		bf
//	
//	for ( c = 0; c < nCntAD; c += 1)
//		string  	sWaveNm	= 	FldAcqioADTGNm( sFo, wG, wIO, c )
//		if ( UFCom_Make1( sWaveNm, nPts, UFCom_kREAL32, 0, UFPE_kbOVERWRITE_WAVE, UFCom_kERR_FATAL ) )	// construct the wave with unique name (data type is 4 byte real)..	
//			return 	UFCom_kERROR
//		endif
//		if ( UFCom_DebugDepthSel() > 1  &&  UFCom_DebugVar( "Ced" ) )
//			printf "\t\t\tCed SupplyWavesADC(  Adc  )  \t building  c:%2d/%2d  '%s' \tpts:%6d\r", c, nCntAD,  sWaveNm, numPnts( $sWaveNm ) 
//		endif
//	endfor
//	return	0
//End
//
//static Function		SupplyWavesADCTG( sFo, wG, wIO, nPts )
//	// supply  ADC telegraph channel waves (as REAL)  here 
//	string  	sFo
//	wave	wG
//	wave  /T	wIO
//	variable	nPts
//	variable	nProts		= UFPE_Prots( sFo )
//	variable	nCntAD		= wG[ UFPE_WG_CNTAD ]	
//	variable	nCntTG		= wG[ UFPE_WG_CNTTG ]	
//	nvar		gnCompress	= root:uf:acq:co:gnCompressTG
//	variable	c
//	string		bf
//	variable	nTestPnts		= nPts  / gnCompress
//	nPts		= ceil( nPts  / gnCompress )	// 2005-0128  Dimension 1 more instead of truncating. This last element is accessed in UFCom_UtilConvolve() . If not dimensioned sporadic crashes occur...
//	
//	for ( c = nCntAD; c < nCntAD + nCntTG; c += 1)	
//		string  	sWaveNm	= 	FldAcqioADTGNm( sFo, wG, wIO, c )
//		if ( UFCom_Make1( sWaveNm, nPts, UFCom_kREAL32, 0, UFPE_kbOVERWRITE_WAVE, UFCom_kERR_FATAL ) )	// construct the wave with unique name (data type is 4 byte real)..	
//			return 	UFCom_kERROR
//		endif
//		if ( UFCom_DebugDepthSel() > 3  &&  UFCom_DebugVar( "Ced" ) )
//			printf "\t\tCed SupplyWavesADCTG(AdcTG)\tbuild c:%d/%d\t%s\tshould have \t%5.1lf\tMB = \t%10d   \t pts , has been allocated \t%10d   \tpts:\t%s\tCompress:%3d \r", c, nCntAD+nCntTG, UFCom_pd(sWaveNm,19), nPts * 4 / 1024 / 1024, nPts, numpnts($sWaveNm), Time(), gnCompress 
//		endif
//	endfor
//	return	0
//End
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//static 	 constant	BYTES_PER_SLICE		 = 16
//
//// could be made static if  the call from PnTest() was included in this file
//static Function 		SetPoints( sFo, CedMaxSmpPts, nPnts, nSmpInt , nDA, nAD, nTG, nSlices, nErrorBad, nErrorFatal )
//	// Given the number of data points to be transferred (=nPnts) , the CED memory size and any channel combinations.. 
//	// ..we try to split 'nPnts'  into factors  'nReps'  *  'nChunkPerRep'  *  'xxx=CompPts'  *  'nCompress'
//	// The assumption (which makes splitting impossible in rare cases but life easy after a suitable split is found) is that all repetions have equal number of chunks (='nChunkPerRep' )
//	// The above split factors must meet certain conditions imposed by the available CED memory
//	//	 - the number of points per chunk must fits into the transfer area 
//	//	 - the number of points per chunk must fits into the sampling area
//	// To achieve high data rates it is very important to have optimum TA memory usage (>90%) 
//	// To achieve a long interruption time (possibly demanded by Windows and/or  mouse action by user)  a high sampling memory usage is required
//	//  An optimum telegraph data compression has been introduced which allows higher overall data rates  
//	// Flaws: It is not guaranteed that splitting is possible while all of the above conditions are met. 
//	//	- If the stimulus protocol consists mainly of large primes it may not be divisible without remainder in chunks small enough to fit into the transfer area
//	//	- This could be avoided by allowing remainders (the last repetition being different from all others), but as this would lead to multiple complications this approach is not taken.
//
//	// General considerations:
//	// We can optimize the program behaviour during acquisition in 2 directions: maximum data rates  or  fast reaction time
//	// Given the number of script data points we try to adjust the compression factor, the number of repetitions, the ChunksperRep and the PointsPerRep to find the optimum combination.
//	// A high compression factor is in principle favorable both for  maximum data rates  and  fast reaction time  as it decreases the overall amount of data to  be transfered.
//	// But still the highest compression factor found may not be the best because choosing a slightly lower factor may vastly improve the other factors leading to a much better overall performance.
//	// A low number of repetitions is always favorable both for  maximum data rates  and  fast reaction time  as it  makes optimum use of the CED memory leading to high  interruption times.
//	// So actually only ChunksperRep and PointsPerRep are left for controling the program behaviour :
//	 // To achieve  maximum data rates we would choose the minimum ChunksperRep and the maximum PointsPerRep : For  fast reaction time we would choose the opposite.
//	 // As searching and finding the optimum combination may take a considerable amount of time it is important to step the factors in the right direction:
//	 // The search should start at the optimum end of the allowed range so that the first value found is the best and inferior values have not to be tested.
//
//// Runs faster when a high gMaxReactnTime ( >=20 s ) is set.  One could possibly speed this up even for the commonly used  gMaxReactnTime ~ 2 s, ..
//// ...if the combinations having too high a reaction time are sorted out early..... 
//
//	string  	sFo
//	variable	CedMaxSmpPts, nPnts, nSmpInt, nDA, nAD, nTG, nSlices, nErrorBad, nErrorFatal
//	variable	gMaxReactnTime 	= MaxReactnTm() 
//	variable	nProts			= UFPE_Prots( sFo )
//	nvar		gnCompressTG		= root:uf:acq:co:gnCompressTG
//	nvar		gMaxSmpPtspChan	= root:uf:acq:co:gMaxSmpPtspChan
//	nvar		gnReps			= root:uf:acq:co:gnReps
//	nvar 		gChnkPerRep		= root:uf:acq:co:gChnkPerRep
//	nvar		gPntPerChnk		= root:uf:acq:co:gPntPerChnk
//	nvar	 	gnOfsDA			= root:uf:acq:co:gnOfsDA
//	nvar		gSmpArOfsDA		= root:uf:acq:co:gSmpArOfsDA
//	nvar 		gnOfsAD			= root:uf:acq:co:gnOfsAD
//	nvar		gSmpArOfsAD		= root:uf:acq:co:gSmpArOfsAD
//	nvar		gnOfsDO			= root:uf:acq:co:gnOfsDO
//	variable	nDAMem, nADMem,  SmpArEndDA,  SmpArEndAD, nDigoutMem, nTrfAreaBytes, TAUsed = 0, MemUsed = 0, FoM = 0, BestFoM = 0, nChunkTimeMS
//	variable	nReps, MinReps, nChnkPerRep, nPntPerChnk, nChunks, MinNrChunks, nSumChs, EffChsM, EffChsTA, PtpChkM, PtpChkTA,  c, nCompress, nCompPts, HasPoints
//	variable	bPrintIt	=   UFCom_FALSE
//	string		bf
//	variable	nRadDebgSel		= UFCom_DebugDepthSel()
////	variable	pnDebgCed		= UFCom_DebugVar( "Ced" )
//
//	gnCompressTG		= 255
//	gMaxSmpPtspChan	= 0
//	gnReps			= 0
//	gChnkPerRep		= 0
//	gPntPerChnk		= 0
//	// printf "\t\t\tCed SetPoints(a) nSlices:%d  CedMaxSmpPts:%d   gnOfsDO:%d  \r", nSlices,  CedMaxSmpPts,   gnOfsDO
//
//	nDigOutMem		= nSlices  * BYTES_PER_SLICE 
//	gnOfsDO			= floor( ( CedMaxSmpPts * 2 - nDigOutMem ) / BYTES_PER_SLICE ) * BYTES_PER_SLICE	// 16 byte boundary is sufficient at the top end of the CED memory
//	CedMaxSmpPts		= gnOfsDO / 2								// decrease sampling area by memory occupied by digout slices (=above gnOfsDO)
//	// printf "\t\t\tCed SetPoints(b) nSlices:%d  CedMaxSmpPts:%d   gnOfsDO:%d  \r", nSlices,  CedMaxSmpPts,   gnOfsDO
//
//	string		lstCompressFct
//	string		lstPrimes	
//
//	nPnts	= nPnts * nProts									//
//
//	lstCompressFct	= CompressionFactors( nPnts, nAD, nTG )			// list containing all allowed compression factors
//
//	if ( nRadDebgSel > 1  &&   UFCom_DebugVar( "Ced" ) )
//		printf "\t\t\tCed SetPoints() \t\t\t\t\tMxPts\t\tnPts\tSlc\t DA AD TG Cmp\tSum  MxPtpChan\t MinChk\tChunks\tMinRep\tREPS CHKpREP PTpCHK\t ChkTim\tTA%% M%% FoM \r"
//	endif
//
//	// Loop1(Compress): Divide  'nPnts'  by all possible compression factors to find those which leave no remainder
//	BestFoM = 0
//	for ( c = 0; c < ItemsInList( lstCompressFct ); c += 1 )
//
//		nCompress	= str2num( StringFromList( c, lstCompressFct ) )
//	
//		nSumChs		= nAD + nDA + nTG
//		EffChsM		= 2 * nDA + 2 * nAD + nTG + nTG / nCompress	// Determine the absolute minimum number of effective channels limited by the entire CED memory (= transfer area + sampling area )
//		PtpChkM		= trunc( CedMaxSmpPts / EffChsM / 2 )		// Determine the absolute maximum PtsPerChk considering the entire Ced memory,  2 reserves space for the 2 swinging buffers
//		EffChsTA		=  nDA + nAD + nTG / nCompress			// Determine the absolute minimum number of effective channels limited by the Transfer area
//		PtpChkTA		= trunc( cMAX_TAREA_PTS / EffChsTA / 2 )	// Determine the absolute maximum PtsPerChk considering only the Transfer area ,  2 reserves space for the 2 swinging buffers
//		nPntPerChnk	= min( PtpChkTA, PtpChkM )				// the lowest value of both and of the passed value is the new upper limit  for  PtsPerChk
//
//		MinNrChunks	= ceil( nPnts / nPntPerChnk )				// e.g. maximum value for  1 DA, 2AD, 2TG/Compress: 1 UFPE_kMBYTE =   appr.  80000 POINTSPerChunk * 3.1 Channels *  2 swap halfs
//		if ( nRadDebgSel > 1  &&   UFCom_DebugVar( "Ced" ) )
//			printf "\t\t\tCed SetPoints() \t\t\t\t\tMxPts\t\tnPts\tSlc\t DA AD TG Cmp\tSum  MxPtpChan\t MinChk\tChunks\tMinRep\tREPS CHKpREP PTpCHK\t ChkTim\tTA%% M%% FoM \r"
//		endif
//	
//		gMaxSmpPtspChan	= trunc(  ( CedMaxSmpPts -  ( nDA + nAD  + nTG / nCompress ) * 2 * nPntPerChnk ) / nSumChs )	// subtract memory used by transfer area
//	
//		// Get the starting value for the Repetitions loop
//		// the correct (=large enough) 'MinReps' value ensures that ALL possibilities found in the 'Rep' loop below are legal (=ALL fit into the CED memory) : none of them has later to be sorted out
//		MinReps			= ceil( nPnts / gMaxSmpPtspChan )	
//	
//		nCompPts	= nPnts / nCompress
//		// printf "old -> new \tCompress: %2d \tMinChunks:%2d \t-> %d \tMinReps:%2d \t-> %d  \r", nCompress, ceil( nPnts / nPntPerChnk ), ceil( nPnts*nProts / nPntPerChnk ),  ceil( nPnts / gMaxSmpPtspChan ), ceil( nPnts*nProts / gMaxSmpPtspChan )
//
//		// Loop2( nPnts reduced by compress ) 
//
//		//  Optimize for highest possible data rates while fulfilling the reaction time condition.
//		//  
//		// We start with (and increase) the minimum number of chunks until we find a combination of  nChunks and  PtpChk which fits nPnts without remainder
//		// When the FIRST combination is found their FigureOfMerit is compared to previous values (obtained with other compression values) and stored if  the current FoM is better, then the loop is left immediately.
//		// The  so found first combination will automatically have the lowest 'nChunks' value and consequently the highest 'PtsPerChunk'  /  TA-Mem_Usage / FoM  value.  
//		// Unfortunately it will also have a long reaction time,  even in the case of few data points (nReps=1) when high data rates would be are obtained automatically even with  a low number of 'PtsPerChunk' .
//		// To also  fulfill the reaction time condition we increase 'nChunks'  (which automatically decreases the reaction time)  until the reaction time condition is fulfilled. 
//		// The FigureOfMerit of this value just fulfilling the reaction time condition (one value for each compesssion factor)  is compared to those obtained for other compression factors: the best FoM is finally taken.
//	
//		do
//			nChunks		= FindNextDividerBetween( nCompPts, MinNrChunks, nCompPts )		// could be made faster as the prime splitting needs in principle only be done once...
//			if ( nChunks == UFCom_kNOTFOUND )
//				break								// Leave the loop as  'nCompPts'  was a prime number which cannot be processed. The 'FoM'  being 0  will  trigger an error to alert the user.
//			endif
//			nReps		= FindNextDividerBetween( nChunks, MinReps, nChunks / 3 )		// We use at least 3 chunks although we theoretically need only at least 2 chunks. We then avoid ChunksPerRep = 2 which works in principle but has in some cases too little 'gReserve'  for a reliable acquisition...
//			if ( nReps == UFCom_kNOTFOUND )
//				// printf "\t\t\t\tCed SetPoints(3) \tnCompTG:%3d , \tSum:%.3lf \tCmpPts:\t%7d\tnChunks: %.3lf \t-> %3d -> %3d , \t==Quot:\t%6d\tReps:%3d min\tCould not divide %3d / nReps \r", nCompress, EffChsTA, nCompPts, nPnts/ nPntPerChnk, MinNrChunks, nChunks, nCompPts / nChunks, MinReps, nChunks
//				MinNrChunks	= nChunks+1
//				continue								// Restart the loop
//			endif
//			nChnkPerRep	= nChunks / nReps				// we found a combination of  nReps and  ChnkPerRep which fits nChunks without remainder
//			nPntPerChnk	= nPnts / nChunks  
//
//			// printf "\t\t\t\tCed SetPoints(4) \tnCompTG:%3d , \tSum:%.3lf \tCmpPts:\t%7d\tnChunks: %.3lf \t\t   -> %3d , \t==Quot:\t%6d\tReps:%3d/%d\tChnk/Reps:\t%4d\t  PtpChk:%6d \r", nCompress, EffChsTA, nCompPts, nPnts/ nPntPerChnk,  nChunks, nCompPts / nChunks, MinReps, nReps, nChunks / nReps, nPntPerChnk	 
//
//			nChunkTimeMS	= nPntPerChnk * nSmpInt / 1000
//			MemUsed		= MemUse(  nChnkPerRep, nPntPerChnk, gMaxSmpPtspChan )
//			TAused		= TAuse( nPntPerChnk, nDA, nAD, cMAX_TAREA_PTS ) 
//			// Even when optimizing the reaction time  the FigureOfMerit  depends only on the memory usage. The reaction time is introduced as an  'too long' - 'OK' condition
//			FoM			= FigureOfMerit( nChnkPerRep, nPntPerChnk, gMaxSmpPtspChan, nDA, nAD, nTG,  nCompress, cMAX_TAREA_PTS ) 
//
//			if ( nRadDebgSel > 3  &&   UFCom_DebugVar( "Ced" ) )
//				printf "\t\t\t\t\tCed SetPoints(candi.)\t%10d\t%10d  %4d\t%4d%4d%5d%5d\t%5.3lf %10d\t%6d\t%6d\t%6d\t%6d\t%6d\t%6d\t%6d\t%3d\t%3d\t%6.1lf  \r", CedMaxSmpPts, nPnts, nSlices, nDA, nAD, nTG, nCompress, nDA+ nAD+nTG/nCompress,  gMaxSmpPtspChan, MinNrChunks, nReps * nChnkPerRep, MinReps, nReps, nChnkPerRep, nPntPerChnk, nChunkTimeMS, TAUsed, MemUsed, FoM
//			endif
//
//			MinNrChunks	= nChunks + 1					// When optimizing ONLY for high data rates: Comment out this line 
//
//			if ( nChunkTimeMS <= gMaxReactnTime * 1000 )	// When optimizing ONLY for high data rates: Always true
//				if ( FoM > BestFoM )
//					gnCompressTG	= nCompress
//					gnReps		= nReps	
//					gChnkPerRep	= nChnkPerRep	
//					gPntPerChnk	= nPntPerChnk  
//					BestFoM		= FoM
//				endif		
//				break		// Leave the loop. The first  'nChunks'  and  the  first  'nReps'  found  (both having the lowest possible value)  have  best (=biggest) chunk size AND best sampling area memory usage: No need to go through the rest of the possibilities
//			endif		
//
//		while ( UFCom_TRUE ) 
//
//	endfor	 		// next  smaller Compress factor
//
//	nChunkTimeMS	= gPntPerChnk * nSmpInt / 1000
//	MemUsed		= MemUse(  gChnkPerRep, gPntPerChnk, gMaxSmpPtspChan )
//	TAused		= TAuse( gPntPerChnk, nDA, nAD, cMAX_TAREA_PTS ) 
//	FoM			= FigureOfMerit( gChnkPerRep, gPntPerChnk, gMaxSmpPtspChan, nDA, nAD, nTG,  gnCompressTG, cMAX_TAREA_PTS ) 
//	if ( nRadDebgSel > 1  &&   UFCom_DebugVar( "Ced" ) )
//		sprintf  bf, "\t\t\tCed SetPoints(final)\t\t\t%10d\t%10d  %4d\t%4d%4d%5d%5d\t%5.3lf %10d\t%6d\t%6d\t%6d\t%6d\t%6d\t%6d\t%6d\t%3d\t%3d\t%6.1lf ( incl. %d nProts)  \r", CedMaxSmpPts, nPnts, nSlices, nDA, nAD, nTG, gnCompressTG, nDA+ nAD+nTG/gnCompressTG,  gMaxSmpPtspChan, MinNrChunks, gnReps * gChnkPerRep, MinReps, gnReps, gChnkPerRep, gPntPerChnk, nChunkTimeMS, TAUsed, MemUsed, FoM, nProts
//	endif
//
//	// The following warning sorts out bad combinations which result from the 'Minimum chunk time' condition (> 1000 ms)
//	// Example for bad splitting	: nPnts : 100000 -> many chunks : 10000  , few   pointsPerChk :       10 ,   ChunkTime : 2 ms . 
//	// Good (=normal) splitting	: nPnts : 100000 -> few   chunks :       10  , many pointsPerChk : 10000 ,   ChunkTime : 900 ms 
//	if ( gnReps * gChnkPerRep > gPntPerChnk   &&  gnReps > 1 ) 	// in the special case of few data points (=they fit with 1 repetition in the Ced memory) allow even few PtsPerChk in combination with many 'nChunk'
//		sprintf bf, "Script has bad number of data points (%d) leading to poor performance. \r\tAdjust duration(s) in stimulus protocol slightly so that data points contains more small primes." , nPnts
//		lstPrimes	= UFCom_FPPrimeFactors( sFo, nPnts )					// list containing the prime numbers which give 'nPnts'
//		UFCom_FoAlert( sFo, nErrorBad,  bf + "   " + lstPrimes[0,50] )
//		UFCom_Delay( 2 )										// time to read the message in the continuous test mode
//	endif
//	
//	HasPoints		= gnReps * gChnkPerRep * gPntPerChnk  
//	if ( HasPoints != nPnts )		
//		sprintf bf, "The number of stimulus data points (%d) could not be divided into CED memory without remainder. \r\tAdjust duration(s) in stimulus protocol slightly so that data points contains more small primes." , nPnts
//		lstPrimes	= UFCom_FPPrimeFactors( sFo, nPnts )					// list containing the prime numbers which give 'nPnts'
//		UFCom_FoAlert( sFo, nErrorFatal,  bf + "   " + lstPrimes[0,50] )
//		UFCom_Delay( 2 )										// time to read the message in the continuous test mode
//		return  0
//	endif
//
//	// Now that the number of chunks, the number of repetitions, the  ChnksPerRep and the ChunkSize are determined...
//	// ..we can split the available CED memory into the transfer area, the sampling area  and the area for the digout slices 
//	nDAMem		= 2 * nDA * gPntPerChnk
//	nADMem		= round( 2 * ( nAD + nTG / gnCompressTG ) * gPntPerChnk )
//	gnOfsDA		= 0
//	gnOfsAD		= 2 * ( gnOfsDA + nDAMem )	// *2 : swap buffers!!!					// the end of the DA transfer area is the start of the AD transfer area
//	nTrfAreaBytes	= 2 * ( gnOfsDA + nDAMem + nADMem )
//
//	if ( nRadDebgSel  > 2  &&   UFCom_DebugVar( "Ced" ) )
//		printf "\t\t\t\tCed SetPoints  DA-TrfArOs:%d  Mem:%d (chs:%d)    AD-TrfArOs:%d  Mem:%d (chs:%d+%d)    -> TABytes:%d   [DigOs:%d=0x%06X] \r", gnOfsDA, nDAMem, nDA, gnOfsAD, nADMem,  nAD, nTG,  nTrfAreaBytes, gnOfsDO, gnOfsDO
//	endif
//
//	// build the areas one behind the other 
//	gSmpArOfsDA	= nTrfAreaBytes												// if CED does not require sampling areas to start at 64KB borders
//	SmpArEndDA	= gSmpArOfsDA + round( 2 * gChnkPerRep * gPntPerChnk * nDA  )		// uses memory ~number of channels (=as little memory as possible)
//	gSmpArOfsAD	= SmpArEndDA												//  if CED does not require sampling areas to start at 64KB borders	
//	SmpArEndAD 	= gSmpArOfsAD + round( 2 * gChnkPerRep * gPntPerChnk * ( nAD + nTG ) )		
//
//	if ( nRadDebgSel > 2  &&   UFCom_DebugVar( "Ced" ) )
//		printf "\t\t\t\tCed SetPoints  TrArBytes:%d   SmpArDA:%d..%d=0x%06X..0x%06X  SmpArAD:%d..%d=0x%06X..0x%06X  gnOfsDO:%d \r", nTrfAreaBytes, gSmpArOfsDA, SmpArEndDA, gSmpArOfsDA, SmpArEndDA, gSmpArOfsAD, SmpArEndAD, gSmpArOfsAD, SmpArEndAD, gnOfsDO
//	endif
//	if ( nTrfAreaBytes > cMAX_TAREA_PTS * 2  ||  nTrfAreaBytes > gSmpArOfsDA  ||  SmpArEndDA > gSmpArOfsAD ||  SmpArEndAD > gnOfsDO )
//		sprintf bf, "Memory partition error: Transfer area / Sampling area /  Digout area overlap:  %d < (%d) %d < %d < %d < %d < %d",  nTrfAreaBytes, cMAX_TAREA_PTS * 2, gSmpArOfsDA, SmpArEndDA, gSmpArOfsAD,  SmpArEndAD, gnOfsDO
//		UFCom_InternalError( bf )
//		printf "\t\t\t\tCed SetPoints  TrArBytes:%d   SmpArDA:%d..%d=0x%06X..0x%06X  SmpArAD:%d..%d=0x%06X..0x%06X  gnOfsDO:%d \r", nTrfAreaBytes, gSmpArOfsDA, SmpArEndDA, gSmpArOfsDA, SmpArEndDA, gSmpArOfsAD, SmpArEndAD, gSmpArOfsAD, SmpArEndAD, gnOfsDO 
//		return	UFCom_kERROR
//	endif
//
//	return	nTrfAreaBytes / 2                       
//End
//
//
//static Function		FindNextDividerBetween( nBig, nMin, nMax )
//// factorizes  'nBig'  and returns the factor closest (equal or larger) to  'nMin'  and  smaller or equal  'nMax' 
//// Brute force: could be done easily by looping through numbers > nMin and checking if the remainder of  nBigs/numbers  is 0 . This is OK when  nBig <~ 1 000 000, otherwise is takes too long (>1 s)
//// In the approach  taken  'nBig'  is first split into factors (which requires splitting into primes), then from the resulting factor list the factor closest to but greater or equal  'nMin' is picked.  Much faster for large 'nBig' 
//	variable	nBig, nMin, nMax
//	variable 	f, nFactor
//	string		lstFactors	= UFCom_Factors( ksACQ, nBig )				// break  'nBig'  into factors, requires splitting into primes, lstFactors contains 'nBig'
//	//for	( f = 0; f < ItemsInList( lstFactors )		; f += 1 )	// Version1 :  allow returning  'nBig'  if no other factor is found
//	for 	( f = 0; f < ItemsInList( lstFactors ) - 1	; f += 1 )	// Version2 :  never return 'nBig'  even if no other factor is found (this option must be used when breaking 'nPnts' into 'chunks'  and  'Reps') 
//		nFactor	= str2num( StringFromList( f, lstFactors ) )
//		if ( nMin <= nFactor  &&  nFactor <= nMax )
//			// printf "\t\t\t\t\tNextDividerBetween( %5d, \tnMin:%5d, \tnMax:%5d\t) -> found divider:%d   in   %s \r", nBig, nMin,nMax, nFactor, lstFactors[0, 180]
//			return	nFactor
//		endif
//	endfor		
//	// printf "\t\t\t\t\tNextDividerBetween( %5d, \tnMin:%5d, \tnMax:%5d\t) -> could not find divider between %5d\tand %5d \tin   %s \r", nBig, nMin,nMax, nMin,nMax, lstFactors[0, 180]
//	return	UFCom_kNOTFOUND
//End	
//
//Static Function		TAUse( PtpChunk, nDA, nAD, MaxAreaPts )
//	variable	PtpChunk, nDA, nAD, MaxAreaPts 
//	return	PtpChunk * (nDA + nAD ) * 2 / MaxAreaPts * 100	// the compressed TG channels are NOT included here as more TG points would erroneously increase TAUsage and FoM while actually deteriorating performance
//End	
//
//Static Function		MemUse(  nChnkPerRep, nPntPerChnk, nMaxSmpPtspChan )
//	variable	nChnkPerRep, nPntPerChnk, nMaxSmpPtspChan
//	return	nChnkPerRep * nPntPerChnk / nMaxSmpPtspChan * 100 		
//End
//
//Static Function		FigureOfMerit( nChnkPerRep, PtpChunk, nMaxSmpPtspChan, nDA, nAD, nTG,  Compress, MaxAreaPts )
//// Computes value for the goodness of the memory usage 
//// Usually there are many possibilties to split the memory, if this is the case then this function helps to select the 'BEST' one
//// Also used to alert the user to change his script a tiny bit (changing  'nPnts'  by 1 or 2 is usually sufficient)  if the script achieves only a  'Bad'  FigureOfMerit
//// High  Transfer area useage is absolutely mandatory for high sampling rates, and high TG compression rates are always favorable to reduce the amount of transferred data...
//// ..so there is no question about those.  However, to what extent the Memory usage should influence the FoM can be argued about.
//// High Memory usage means long times during which Windows can interrupt its activities and sampling still continues.
//// As right now high sampling rates seem to be much more important than long interruption times  the memory area usage is included in the FoM only with a reduction factor. Could be changed. 
//	variable	nChnkPerRep, PtpChunk, nMaxSmpPtspChan, nDA, nAD, nTG,  Compress, MaxAreaPts 
//	variable	FoMFactorForMemoryUsage	= .3
//	variable	FoM	= PtpChunk * (nDA + nAD   -   nTG / Compress ) * 2 / MaxAreaPts * 100					// SUBTRACTION of compressed points favors high compression rates 
//	FoM		+= MemUse( nChnkPerRep, PtpChunk, nMaxSmpPtspChan ) * FoMFactorForMemoryUsage
//	// printf "\t\tFoM( nChnkPerRep:%3d \tPtpChk:\t%8d\tnMaxSmpPtspChan:\t%10d\t  nDA:%d   nAD:%d   nTG:%d   Compress:%4d\t MaxAreaPts:%6d\t->  FoM:%.1lf  \r"  , nChnkPerRep, PtpChunk, nMaxSmpPtspChan, nDA, nAD, nTG,  Compress, MaxAreaPts, FoM
//	return	FoM
//End
//
//
//Static Function  /S	CompressionFactors( nPnts, nAD, nTG )	
//// build list containing all allowed compression factors
//	variable	nPnts, nAD, nTG	
//	string		lstCompressFct	= ""
//	// Determine the absolute maximum limit for the compression factor
//	variable	n, nMaxCompressTG
//	if ( nAD + nTG == 0 )								// 2005-1202
//		nMaxCompressTG	= cFAST_TG_COMPRESS		// 2005-1202
//	else
//		nMaxCompressTG	= trunc ( min( cFAST_TG_COMPRESS * ( nAD + nTG ) , 255 ) / ( nAD + nTG ) )	
//	endif
//
//	// As the maximum compression factor is always small ( 127, 85, 63, 51,...) it is fast enough to compute it by trying all possibilities.
//	// This is not the cleanest solution (which would be building all possibilities from the factor list) but is progammatically much easier.
//	for ( n = nMaxCompressTG; n > 0; n -= 1 )
//		if ( nPnts / n == trunc( nPnts / n ) )
//			lstCompressFct	= AddListItem( num2str( n ), lstCompressFct, ";", Inf )	// list order: descending (start with the biggest value, this order is later assumed)
//		endif
//	endfor
//	// printf "\t\t\tCompressionFactors( n:%5d, nAD:%2d, nTG:%2d )  \tnMaxCompressTG:%4d \t-> factors: %s \r", nPnts, nAD, nTG, nMaxCompressTG, lstCompressFct[0,120]
//	return	lstCompressFct
//End
//
//
//static Function		SearchImprovedStimulusTiming( sFo, wG, nCEDMemPts, nPnts, nSmpInt, nDA, nAD, nTG, nSlices )
//	string  	sFo
//	wave	wG
//	variable	nCEDMemPts, nPnts, nSmpInt, nDA, nAD, nTG, nSlices
//	variable	Neighbors		= 100
//	printf "\t\tSearching improved stimulus timing within the range %d points * %d us = original script length = %.2lf ms to %.2lf ms ", nPnts, nSmpInt, nPnts * nSmpInt  / UFPE_kMILLITOMICRO, ( nPnts + Neighbors ) * nSmpInt / UFPE_kMILLITOMICRO
//	CheckNeighbors( sFo, wG, nCEDMemPts, nPnts, nSmpInt , nDA, nAD, nTG, nSlices, Neighbors )	
//End
//
//
//static Function		CheckNeighbors( sFo, wG, nCEDMemPts, nPnts, nSmpInt , nDA, nAD, nTG, nSlices, Neighbors )	
//	string  	sFo
//	wave	wG
//	variable	nCEDMemPts, nPnts, nSmpInt , nDA, nAD, nTG, nSlices, Neighbors	
//	nvar		gnReps			= root:uf:acq:co:gnReps
//	nvar 		gChnkPerRep		= root:uf:acq:co:gChnkPerRep
//	nvar		gPntPerChnk		= root:uf:acq:co:gPntPerChnk
//	nvar		gSmpArOfsDA		= root:uf:acq:co:gSmpArOfsDA
//	nvar 		gSmpArOfsAD		= root:uf:acq:co:gSmpArOfsAD
//	nvar		gnOfsDO			= root:uf:acq:co:gnOfsDO
//	nvar		gnCompressTG		= root:uf:acq:co:gnCompressTG
//	nvar		gMaxSmpPtspChan	= root:uf:acq:co:gMaxSmpPtspChan
//
//	variable	SmpArEndDA, SmpArEndAD, nChunkTimeMS, nTrfAreaPts				// are computed
//	variable	TAUsed, MemUsed, FoM, BestFoM, Pts
//
//	BestFoM = 0
//	// printf "\tSetPointsTestContNeighbors() checking points from  %d  to  %d \r",  nPnts - Neighbors, nPnts + Neighbors
//	printf "\r"
////	for ( Pts = nPnts - Neighbors; Pts < nPnts + Neighbors; Pts += 2 )
//	for ( Pts = nPnts; Pts < nPnts + Neighbors; Pts += 2 )
//		nTrfAreaPts	= SetPoints( sFo, nCEDMemPts, Pts, nSmpInt , nDA, nAD, nTG, nSlices, UFCom_kERR_MESSAGE, UFCom_kERR_MESSAGE )				// all params are points not bytes	
//		TAused		= TAuse( gPntPerChnk, nDA, nAD, cMAX_TAREA_PTS ) 
//		MemUsed		= MemUse(  gChnkPerRep, gPntPerChnk, gMaxSmpPtspChan )
//		FoM			= FigureOfMerit( gChnkPerRep, gPntPerChnk, gMaxSmpPtspChan, nDA, nAD, nTG, gnCompressTG, cMAX_TAREA_PTS ) 
//		if ( FoM > 1.001 * BestFoM )		// 1.001 prevents minimal useless improvement from being displayed
//			BestFoM = FoM
//			SmpArEndDA	= gSmpArOfsDA + trunc( 2 * gChnkPerRep * gPntPerChnk * nDA + .5 )			// like SetPoints ()	
//			SmpArEndAD 	= gSmpArOfsAD + trunc( 2 * gChnkPerRep * gPntPerChnk * ( nAD + nTG ) + .5 )	// like SetPoints ()	
//			// printf "\t %10d \t %10d \tSi:%4d\t%2d\t%2d\t%2d\tSl:%4d\t:Rep:%6d\t* Chk:%4d\t* PpC:%5d\tTA:%8d\t%7d\t%7d\t\t%7d\t%7d\t%10d\tFoM:%4.1lf \t \r", nCEDMemPts*2, Pts, nSmpInt , nDA, nAD, nTG, nSlices, gnReps, gChnkPerRep, gPntPerChnk, nTrfAreaPts, gSmpArOfsDA, SmpArEndDA, gSmpArOfsAD, SmpArEndAD, gnOfsDO, FoM
//			printf "\t %10d \t %10d \tSi:%4d\t%2d\t%2d\t%2d\tSl:%4d\tRep\t%7d\tChk\t%7d\tPpC\t%7d\tTA:\t%7d\t  TA:%3d%% \tMem:%3d%%\t FoM:%5.1lf\t \t \r", Pts, nCEDMemPts*2, nSmpInt , nDA, nAD, nTG, nSlices, gnReps, gChnkPerRep, gPntPerChnk, nTrfAreaPts, TAUsed, MemUsed, FoM
//		endif
//
//		if ( nTrfAreaPts == UFCom_kERROR )
//			return UFCom_kERROR
//		endif
//	endfor
//End
//
//
////Function		Random( nBeg, nEnd, nStep )
////// returns random integer from within the given range, divisible by 'nStep'
////	variable	nBeg, nEnd, nStep
////	variable	nRange	= ( nEnd - nBeg ) / nStep						// convert to Igors random range ( -nRange..+nRange )
////	variable	nRandom	= trunc ( abs( enoise( nRange ) ) ) * nStep + nBeg		// maybe not perfectly random but sufficient for our purposes
////	// printf "\tRandom( nBeg:%6d \tnEnd:%6d  \tStep:%6d \t) : %g \r", nBeg, nEnd, nStep, nRandom
////	return	nRandom
////End
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//// 2003-0612
//static Function		CEDInit1401DACADC( mode )
//	variable	mode
//	variable	hnd, nType, nSize, code, bMode = mode & UFPE_MSGLINE 
//	string		sBuf
//
//	hnd		= UFP_CedGetHandle();
//
//	if ( mode & UFPE_MSGLINE )
//		printf "\t\tCed CEDInit1401DACADC() : Ced is %s open.  Hnd:%d \r", SelectString( hnd == CED_NOT_OPEN, "", "NOT" ), hnd
//	endif
//	if ( hnd == CED_NOT_OPEN )
//		return	hnd
//	endif
//
//	// change memory map if the 1401 is equipped with 16 MByte RAM or more. See p. 20 of the 1999 family programming manual
//	if ( mode & UFPE_MSGLINE )
//		printf "\t\tCed CEDInit1401DACADC()  checking type :"
//	endif
//
//	nType	= CEDType( bMode )
//	
//	if ( mode & UFPE_MSGLINE )
//		printf "\t\tCed CEDInit1401DACADC()  checking memory size  \t\t\t\t\t\t\t : "
//	endif
//	nSize	= CEDGetMemSize( bMode )		
//	if (  nType  == 1 )   										// only 1=1401plus needs the MEMTOP,E command.  2=1401micro and  3=1401power (but not 0=1401standard..)
//
//		CEDSendStringCheckErrors( "MEMTOP,E;" , 0 ) 
//		if ( mode & UFPE_MSGLINE )
//			printf "\t\tCed CEDInit1401DACADC()  checking memory size   after \tsending 'MEMTOP,E;'  : "
//		endif
//		nSize = CEDGetMemSize( bMode )	
//	endif
//
//	// load these commands, 'KILL' (when loaded first) actually unloads all commands before reloading them to free occupied memory (recommendation of Tim Bergel, 2000 and 2003)
//	string		sCmdDir	= "c:\\1401\\"
////	string		sCmdDir	= "c:1401:"
//	string		sCmds	= "KILL,MEMDAC,ADCMEM,ADCBST,DIGTIM,SM2,SN2,SS2"	// the  Test/error led  should not flash unless commands are overwritten (which cannot occur bcause of 'KILL' above)
//
//	// print "UFP_CedLdErrOut( mode, sCmdDir, sCmds )"
//	code		= UFP_CedLdErrOut( mode, sCmdDir, sCmds )
//// reactivated  because of U14Ld()  error -544 with script  CCVIGN_MB.txt (456.3s, 18252000pts)
////	code		= UFP_CedLdErrOut2( mode, sCmdDir, sCmds )
//
//	// printf "\t\tCed CEDInit1401DACADC()  loading commands  '%s'  '%s' \treturns code:%d \r", sCmdDir, sCmds, code
//	if ( code  ||  ( mode & UFPE_MSGLINE ) )
//		printf "\t\tCed CEDInit1401DACADC()  loading commands  '%s'  '%s' \treturns code:%d \r", sCmdDir, sCmds, code
//	endif 
//	if ( code )
//		return	code
//	endif
//
//	// To be sure, occasionally there were some problems with strange values on DACs 
//	sBuf		= "DAC,0 1 2 3,0 0 0 0;" 
//	code		= CEDSendStringCheckErrors( sBuf , 0 ) 
//	if ( code  ||  ( mode & UFPE_MSGLINE ) )
//		printf "\t\tCed CEDInit1401DACADC()  sending %s \treturns code:%d \r", UFCom_pd( sBuf,18), code
//	endif
//	if ( code )
//		return	code
//	endif
//	return	code
//End
//
//static Function		CedSetEvent( sFo, bMode )
//	string  	sFo
//	variable	bMode
//	variable	bTrigMode		= TrigMode()
//	variable	code			= 0
//	variable	nCedType		= CEDType( bMode )	
//	string		sBuf
//
////// 2005-1206  only testing
//// sBuf		= "EVENT,P,63;"							// 63 : set polarity of events 0 ...5 to  low active  (normal setting)
//// 		 printf "\t\tSetEvent( %s , TrigMode:%2d )  '%s' \r",  sFo, bMode, sBuf  
////code		+= CEDSendStringCheckErrors( sBuf, 1 ) 
//
//
//// Old code from version 223 (03 Oct) : E3E4 triggering working !!!  To be deleted again !
////
////
////	if ( gRadTrigMode == 0 ) 	// normal SW triggered mode,  see p.48, 53 of the 1995 family programming manual for an example how to handle dig outputs and events 
////		sBuf		= "EVENT,D,28;"	// 'D'isable external events 2, 3 and 4;   4 + 8 + 16 = 28  i.e. trigger only on internal clock, but not on external signal on E input
////	else
////		sBuf		= "EVENT,D,4;" 	// 'D'isable external events 2   [ 2^2  = 4 ] , but  allow external trigger on events 3 and  4
////	endif
////
////	code		= UFP_CedSendStringErrOut( mode, sBuf ) 
////	if ( code  ||  ( mode & UFPE_MSGLINE ) )
////		printf "\t\tAcq CEDInit1401DACADC()  sending %s \treturns code:%d \r", UFCom_pd( sBuf,18), code
////	endif
////
////	sBuf		= "DIGTIM,OB;"		// use  'B'oth  digital outputs and internal events
////	code		= UFP_CedSendStringErrOut( mode, sBuf ) 
////	if ( code  ||  ( mode & UFPE_MSGLINE ) )
////		printf "\t\tAcq CEDInit1401DACADC()  sending %s \treturns code:%d \r", UFCom_pd( sBuf,18), code
////	endif
//
//
//
//	if ( bTrigMode == 0  ) 										// normal SW triggered mode,  see p.48, 53 of the 1995 family programming manual for an example how to handle dig outputs and events 
//		sBuf		= "DIGTIM,OB;"							// use  'B'oth  digital outputs and internal events
//		// printf "\t\tSetEvent( %s , TrigMode:%2d )  '%s' \r",  sFo, bMode, sBuf  
//		code		+= CEDSendStringCheckErrors( sBuf , 0 ) //1 ) 
//		sBuf		= "EVENT,D,28;"							// 'D'isable external events 2, 3 and 4;   4 + 8 + 16 = 28  i.e. trigger only on internal clock, but not on external signal on E input
//		// printf "\t\tSetEvent( %s , TrigMode:%2d )  '%s' \r",  sFo, bMode, sBuf  
//		code		+= CEDSendStringCheckErrors( sBuf, 0 )//1 ) 
//	endif	
//
//	if ( bTrigMode == 1 ) 										// HW E3E4 triggered mode
//		printf "\t\tIn this mode a  low-going TTL edge on  Events 2,3,4 (1401plus)  or on Trigger input (Power1401)  will trigger stimulus and acquisition. \r" 
//
//// 2006-0206   THIS IS NOT EXECUTED ????
//		sBuf		= "DIGTIM,OD;"							// use  only 'D'igital outputs, do not trigger on internal events
//		 printf "\t\tSetEvent( %s , TrigMode:%2d )  '%s' \r",  sFo, bMode, sBuf  
//		// 2005-1208
//		sBuf		= "EVENT,D,4;" 	// 'D'isable external events 2   [ 2^2  = 4 ] , but  allow external trigger on events 3 and  4
//		 printf "\t\tSetEvent( %s , TrigMode:%2d )  '%s' \r",  sFo, bMode, sBuf  
//		code		+= CEDSendStringCheckErrors( sBuf , 0 )//1 ) 
//		if (  nCedType  ==  c1401MICRO  ||  nCedType == c1401POWER ) // only   2=1401micro and  3=1401power (but not 0=1401standard or 1=1401plus)  need this linking command
//			sBuf = "EVENT,T,28;"							// Power1401 and micro1401 require explicit linking of E2, E3 and E4 to the front panel 'Trigger' input
//			 printf "\t\tSetEvent( %s , TrigMode:%2d )  '%s' \r",  sFo, bMode, sBuf  
//			code	+= CEDSendStringCheckErrors( sBuf, 0 )//1 ) 
//		endif
//	endif	
//	return	code
//End
//
//
//static Function  ArmClockStart( SmpInt, nTrigMode )
//	variable	SmpInt, nTrigMode 
//	string		buf , bf 
//	string		sMode	= SelectString( nTrigMode , "C", "CG" )	// start stimulus/acquisition right now or wait for low pulse on E2 in HW triggered E3E4 mode 
//	variable	rnPre1, rnPre2								// changed in function
//	variable	nRadDebgSel		= UFCom_DebugDepthSel()
////	variable	pnDebgCed		= UFCom_DebugVar( "Ced" )
//	if (  CEDHandleIsOpen() )
//		variable	nrep	= 1								// the true number of repetitions is set in ArmDig()
//		if ( SplitIntoFactors( SmpInt, rnPre1, rnPre2 ) )
//			return	UFCom_kERROR							// 2003-1126
//		endif
//		// divide 1MHz clock by two factors to get basic clock period in us, set clock (with same clock rate as DAC and ADC)  and  start DigOut, DAC and  ADC  OR  wait for low pulse 
//		sprintf buf, "DIGTIM,%s,%d,%d,%d;", sMode, rnPre1, rnPre2, nrep
//		if ( nRadDebgSel > 0  &&   UFCom_DebugVar( "Ced" ) )
//			printf "\t\tCed ArmClockStart sends  '%s'  \r", buf
//		endif
//		// 2003-1124 PROBLEM:  EVEN IF too ambitious sample rates are attempted the CED will  FIRST  start  the stimulus/acquisition and  THEN LATER  return an error code and an error dialog box.
//		// -> starting the stimulus/acquisition cannot be avoided  no matter whether the user acknowledges the error dialog box or not  leading almost inevitably to corrupted data.
//		// -> TODO   the stimulus/acquisition should NOT start in the error case .    STOPADDA   BEFORE   the error dialog opens.... 
//		if ( CEDSendStringCheckErrors( buf, 0 ) ) 
//			return	UFCom_kERROR						// 
//		endif
//	endif
//	return	0
//End
//
//
//static Function  ArmDAC( sFo, BufStart, BufPts, nrep )
//	string  	sFo
//	variable	BufStart, BufPts, nrep
//	wave 	wG			= $"root:uf:" + sFo + ":" + UFPE_ksKPwg + ":wG"	  		// This  'wG'  	is valid in FPulse ( Acquisition )
//	wave  /T	wIO			= $"root:uf:" + sFo + ":ar:wIO"  					// This  'wIO'	is valid in FPulse ( Acquisition )
//	string		buf, bf
//	variable	nRadDebgSel		= UFCom_DebugDepthSel()
////	variable	pnDebgCed		= UFCom_DebugVar( "Ced" )
//	variable	nSmpInt	= UFPE_SmpInt( sFo )
//	variable	nCntDA	= wG[ UFPE_WG_CNTDA ]	
//	variable	rnPre1, rnPre2							// changed in function
//	if (  CEDHandleIsOpen() )
//		if (  nCntDA )
//			if ( SplitIntoFactors( nSmpInt, rnPre1, rnPre2 ) )
//				return	UFCom_kERROR							// 2003-1126
//			endif
//			//string	sChans = ChannelList( "Dac", nCntDA )	//? depends on ordering..
//			string		sChans = ChannelList( wIO, UFPE_IOT_DAC, nCntDA )	//? depends on ordering..
//			// Load the DAC with clock setup: 'I'nterrupt mode, 2 byte, from gDACOffset BufSize bytes, 
//			// DAC2, nRepeats, 'C'lock 1 MHz/'T'riggered mode, and two factors for clock multiplier 
//			// after sending this command to the Ced the DAC will be waiting for a trigger to Event input E3 
//			sprintf  buf, "MEMDAC,I,2,%d,%d,%s,%d,CT,%d,%d;", BufStart, BufPts * 2, sChans, nrep, rnPre1, rnPre2
//			if ( nRadDebgSel > 0  &&   UFCom_DebugVar( "Ced" ) )
//				printf "\t\tCed ArmDAC() sends  '%s'  \r", buf
//			endif
//			// printf "\t\tCed ArmDAC() sends  '%s'  \r", buf
//
//			if ( CEDSendStringCheckErrors( buf, 0 ) )			// now DAC is waiting for a trigger to Event input E3 
//				return	UFCom_kERROR					// 
//			endif
//
//		endif
//	endif
//	return 0
//End
//
//
//static Function  ArmADC( sFo, BufStart, BufPts, nrep )
//	string  	sFo
//	variable	BufStart, BufPts, nrep
//	wave 	wG			= $"root:uf:" + sFo + ":" + UFPE_ksKPwg + ":wG"	  		// This  'wG'  	is valid in FPulse ( Acquisition )
//	wave  /T	wIO			= $"root:uf:" + sFo + ":ar:wIO"  					// This  'wIO'	is valid in FPulse ( Acquisition )
//	string		buf, bf
//	variable	nRadDebgSel		= UFCom_DebugDepthSel()
////	variable	pnDebgCed		= UFCom_DebugVar( "Ced" )
//	variable	nSmpInt		= UFPE_SmpInt( sFo )
//	variable	rnPre1, rnPre2							// changed in function
//	if ( CEDHandleIsOpen() )
//		string  	listADTG	= MakeListADTG( wIO )
//		variable	nAdcChs 	= ItemsInList( listADTG, " " )	// lstAD + lstTG
//		if ( nAdcChs )
//			// load the ADC  :   using  'ADCBST'  we get 'SmpInt' between each burst  ( using  'ADCMEM' we get 'SmpInt' between each channel and have to adjust it)
//			// parameters:  'I'nterrupt mode, 2 byte, from 'gADCOffset' 'BufSize' bytes,  ADC0 ,  1 repeat,  Clock 1 MHz / 'T'riggered mode, and two factors for clock multiplier 
//			// after sending this string to the Ced  the ADC will be  waiting for a trigger to Event input E4 
//			variable	nCedType	= CedType( 0 )
//
//			// 2004-0325  Using ADCMEM rather than ADCBST decreases the minimum sampling interval from  18..20   to 12 us  when using  the 1401 plus with  1 DA, 1 AD and 1 TG channel.
//			if ( nCedType == c1401STANDARD ) 								
//
//				if ( SplitIntoFactors( nSmpInt / nAdcChs, rnPre1, rnPre2 ) )
//					return	UFCom_kERROR							
//				endif
//				// SplitIntoFactors() will already alert about this error........
//				//if ( nSmpInt / nAdcChans != trunc( nSmpInt / nAdcChans ) )
//				//	UFCom_FoAlert( sFo, UFCom_kERR_IMPORTANT, "Sample interval of " + num2str( nSmpInt ) + " could not be divided without remainder through " + num2str( nAdcChans ) + " channels." )
//				//endif
//				sprintf buf, "ADCMEM,I,2,%d,%d,%s,%d,CT,%d,%d;", BufStart, BufPts * 2, listADTG, nrep, rnPre1, rnPre2
//			else
//				if ( SplitIntoFactors( nSmpInt, rnPre1, rnPre2 ) )
//					return	UFCom_kERROR							
//				endif
//				sprintf buf, "ADCBST,I,2,%d,%d,%s,%d,CT,%d,%d;", BufStart, BufPts * 2, listADTG, nrep, rnPre1, rnPre2
//			endif
//			if ( nRadDebgSel > 0  &&   UFCom_DebugVar( "Ced" ) )
//				printf "\t\tCed ArmADC() sends  '%s'    ( nAdcChans: %d , CedType: '%s' )\r", buf, nAdcChs, StringFromList( nCedType + 1, sCEDTYPES )
//			endif
//			 printf "\t\tCed ArmADC() sends  '%s'    ( nAdcChans: %d , CedType: '%s' )\r", buf, nAdcChs, StringFromList( nCedType + 1, sCEDTYPES )
//
//			if ( CEDSendStringCheckErrors( buf, 0 ) )						// now ADC is waiting for a trigger to Event input E4 
//				return	UFCom_kERROR						
//			endif
//		endif
//	endif
//	return 0
//End
//
//static Function  /S	MakeListADTG( wIO )
//	wave  /T	wIO
//	variable	Chan, TGChan
//	string  	lstAD = "", lstTG = ""
//	variable	nIO		= UFPE_IOT_ADC
//	variable	c, cCnt	= UFPE_ioUse( wIO, nIO )
//	for ( c = 0; c < cCnt; c += 1 )
//		Chan		= UFPE_iov( wIO, nIO, c, UFPE_IO_CHAN ) 
//		if (  UFPE_HasTG( wIO, nIO, c ) )
//			TGChan	= UFPE_iov( wIO, nIO, c, UFPE_IO_TGCH ) 
//			lstTG	= AddListItem( num2str( TGChan ), lstTG, " ", Inf )			// use space as separator so that CED can use this string in 'ADCBST' and 'ADCMEM' directly
//		endif
//		lstAD	= AddListItem( num2str( Chan ), lstAD, " ", Inf )				// use space as separator so that CED can use this string in 'ADCBST' directly
//	endfor
//	// printf "\t\tMakeListADTG( wIO ) -> '%s' \r", lstAD + lstTG
//	return	lstAD + lstTG
//End
//
//
//static Function		SplitIntoFactors( nNumber, rnFactor1, rnFactor2 )
//	variable	nNumber, &rnFactor1, &rnFactor2 						// changed in function
//	string		bf
//	rnFactor1	= FindNextDividerBetween( nNumber, 2, min( nNumber / 2, 65535 ) )	// As 2 is the minimum value for ADCBST( 1401plus ) , MEMDAC( 1401plus ) , DIGTIM( 1401plus and Power1401 )...
//	rnFactor2	= nNumber / rnFactor1									// ..it makes no sense to handle (theoretically possible) minimum of 1 for ADCBST +  MEMDAC( Power1401 ) separately
//	if ( rnFactor1 == UFCom_kNOTFOUND   ||   trunc( rnFactor1 ) * trunc( rnFactor2 )  != nNumber )
//		sprintf bf, "Sample interval of %g could not be divided into 2 integer factors between 2 and 65535. ", nNumber 
//		UFCom_FoAlert( ksACQ, UFCom_kERR_FATAL, bf )
//		return	UFCom_kERROR							
//	endif
//	return	0
//End
//
//
//static Function  		ArmDig( sFo, OffsDO )
//	string  	sFo
//	variable	OffsDO
//	wave 	wG			= $"root:uf:" + sFo + ":" + UFPE_ksKPwg + ":wG"	  		// This  'wG'  	is valid in FPulse ( Acquisition )
//	variable	nProts		= UFPE_Prots( sFo )
//	nvar		gnJumpBack	= $"root:uf:" + sFo + ":dig:gnJumpBack"
//	svar		gsDigoutSlices	= $"root:uf:" + sFo + ":dig:gsDigoutSlices"
//	variable	n, p
//	variable	nRadDebgSel		= UFCom_DebugDepthSel()
////	variable	pnDebgCed		= UFCom_DebugVar( "Ced" )
//	string		sErrorCodes, buf, bf
//	if ( CEDHandleIsOpen() )
//		variable	nSlices = ItemsInList( gsDigoutSlices )	
//
//		CEDSetAllDigOuts( 0 )												// 2003-1110  Initialize the digital output ports with 0 : set to LOW
//		
//		// book space for   'nSlices'  (=all slices contained in 'gsDigoutSlices' ) , each slice needs 16 Bytes 
//		sprintf  buf, "DIGTIM,S,%d,%d;", OffsDO, BYTES_PER_SLICE * nSlices
//		if ( nRadDebgSel > 0  &&   UFCom_DebugVar( "Ced" ) )
//			printf "\t\tCed ArmDig()   OffsDO:%d,  nSlices:%2d ,  nProts:%d -> '%s' \r", OffsDO, nSlices, nProts, buf 
//		endif
//		// printf "\t\tCed ArmDig()   OffsDO:%d,  nSlices:%2d ,  nProts:%d -> '%s' \r", OffsDO, nSlices, nProts, buf 
//
//		if ( CEDSendStringCheckErrors( buf, 0 ) ) //1 ) )		
//			return	UFCom_kERROR						
//		endif
//
//
//		for ( n = 0; n < nSlices - 1 ; n +=1 )						// do not yet send the last slice because we must append the number of repeats 					
//			 // printf "\t\tSl:%2d/%2d  %s\t'%s.... \r", n, nSlices, UFCom_pd( StringFromList( n, gsDigoutSlices ), 18), gsDigoutSlices[0,200] 
//			//UFP_CedSendStringErrOut( UFPE_ERRLINE+ERR_FROM_CED, StringFromList( n, gsDigoutSlices ) + ";" ) // each slice needs appr. 260 us to be sent 
//			CEDSendStringCheckErrors( StringFromList( n, gsDigoutSlices ) + ";" ,  0 ) // 1  ) // each slice needs appr. 260 us to be sent 
//		endfor
//
//		string		sLastSlice	= StringFromList( nSlices - 1 , gsDigoutSlices ) +  "," + num2str( -nSlices + gnJumpBack ) + "," + num2str( nProts )   // 2003-0627 do NOT repeat DAC/DAC-Trigger (skip first 2 slices)
//		if ( nRadDebgSel > 0  &&   UFCom_DebugVar( "Ced" ) )
//			printf "\t\tCed ArmDig()   Prot:%2d/%2d   \tSlice:%2d/%2d  \tLastSlice \tcontaining   jmp and rpt :'%s'    (JumpBack:%d)  \r", p, nProts, n, nSlices, sLastSlice, gnJumpBack
//		endif
//
//		if ( CEDSendStringCheckErrors( sLastSlice  + ";" ,  0 ) ) // 1 ) )	// sends last DIGTIM,A...	
//			return	UFCom_kERROR						
//		endif
//
//		if ( nRadDebgSel > 0  &&   UFCom_DebugVar( "Ced" ) )
//			printf  "\t\tCed ArmDig()   has sent %d  digout slices. Digital transitions OK.\r", nSlices
//		endif
//	//UFCom_StopTimer( sFo, "ArmDig" )
//	endif
//	return 0
//End
//
//static Function		CEDSendStringCheckErrors( buf, bPrintIt )
//	string		buf
//	variable	bPrintIt
//	variable	err	= 0
//	if ( bPrintIt )
//		printf "\tCEDSendStringCheckErrors( %s ) \r", buf 
//	endif
//	UFP_CedSendString( buf )
//	//err	= UFP_CedGetResponse( "ERR;" )//, buf, 0 )	// last param is 'ErrMode' : display messages or errors
//	err	= UFP_CedGetResponse( "ERR;", buf, 0 )	// last param is 'ErrMode' : display messages or errors
//	if ( err )
//		string	   bf
//		sprintf  bf,  "err1: %d  err2: %d   after sending   '%s'   (%d) ",  trunc( err / 256 ) , mod( err, 256 ), buf , err 
//		UFCom_FoAlert( ksACQ, UFCom_kERR_FATAL,  bf )
//// 2004-0619 test
//		err	= UFCom_kERROR					
//	endif
//	return	err
//End
//
//
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//// LITTLE HELPERS
//
//Function  /S 	ChannelList( wIO, nIO, nChs )
//	wave  /T	wIO
//	variable	nChs, nIO			// 'UFPE_IOT_ADC'  or  'UFPE_IOT_DAC'
//	variable	c
//	string		bf, sChans = ""
//	for ( c = 0; c < nChs;  c += 1 )
//		sChans += " "
//		sChans += num2str( UFPE_iov( wIO, nIO, c, UFPE_IO_CHAN ) )
//	endfor
//	// printf   "\t\tCed Channellist for %d '%s' channels '%s' \r", nChs, UFPE_ioTNm( nIO ), sChans
//	variable	nRadDebgGen	= UFCom_DebugDepthGen()
//	if ( nRadDebgGen )
//		printf "\t\tCed Channellist for %d '%s' channels '%s' \r", nChs,  UFPE_ioTNm( nIO ), sChans
//	endif
//	return 	sChans
//End
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//// 2009-03-26
////Function		LagTime( sFo )
////// returns how much longer than predicted the script will take due to too much data that are to be displayed (0 is ideal, value in %)
////	string  	sFo
////string  	sSubFoWg
////if ( NewStyle( sFo ) == kPULSE_OLD )
////	sSubFoWg	= UFPE_ksKPwg
////else
////	sSubFoWg	= UFPE_ksKPwgNs
////endif
////	wave  	wG			= $"root:uf:" + sFo + ":" + sSubFoWg + ":wG"  				// This  'wG'	is valid in FPulse ( Acquisition ). StatusBar will not work if  wG  ispassed....
////	variable 	LagTime
////	// Lagtime	= 100 * ( wG[ UFPE_WG_SWPTOT ] / wG[ UFPE_WG_SWPWRIT ] * TimeElapsed() / wG[ UFPE_WG_TOTAL_US ] * 1e6  - 1  )	// in % of total predicted time
////	Lagtime	= (   TimeElapsed() - wG[ UFPE_WG_TOTAL_US ]	 * wG[ UFPE_WG_SWPWRIT ] / wG[ UFPE_WG_SWPTOT ] / 1e6  )	// in seconds
////// 2005-1201
////	nvar		gLagTime	= root:uf:acq:pul:svLagTime0000
////	gLagTime	= LagTime
////	return	LagTime
////End
//
//
//Function		TimeElapsed()
//	string  	sFo		= ksACQ
//	nvar		gbRunning	= $"root:uf:acq:" + UFPE_ksKEEP + ":gbRunning"
//	nvar		gnTicksStop	= $"root:uf:acq:" + UFPE_ksKEEP + ":gnTicksStop"
//	nvar		gnTicksStart	= $"root:uf:acq:" + UFPE_ksKEEP + ":gnTicksStart"
//
//	variable	nStopTime 	= gbRunning ? ticks : gnTicksStop  
//// 2005-12-01
//	nvar		TimeElapsed	= root:uf:acq:pul:svTmElaps0000
//	TimeElapsed			= ( nStopTime - gnTicksStart ) / UFCom_kTICKS_PER_SEC	 // returns seconds elapsed since ...
//
//	return	( nStopTime - gnTicksStart ) / UFCom_kTICKS_PER_SEC		 		// returns seconds elapsed since ...
//End
//
//Function		GetAndInterpretAcqErrors( sText1, sText2, chunk, nMaxChunks )
//	string		sText1, sText2
//	variable	chunk, nMaxChunks
//	string		errBuf
//	variable	code	
//	string		sErrorCodes	= UFP_CedGetResponseTwoIntAsStr( "ERR;" )
//	code		= ExplainCEDError( sErrorCodes, sText1 +" | " +  sText2, chunk, nMaxChunks )
//	code		= trunc( code / 256 )			// 2003-0805 use only the first byte of the 2-byte errorcode (only temporarily to be compatible with the code below...) 
//	// printf "...( '%s' = '%d  '%d' )\t",  sErrorCodes, str2num( StringFromList( 0, sErrorCodes, " " ) ) , str2num( StringFromList( 1, sErrorCodes, " " ) )
//	return	code
//End
//
//
//Function		ExplainCEDError( sErrorCodes, sCmd, chunk, nMaxChunks )
//// prints error codes issued by the CED in a human readable form. See 1401 family programming manual, july 1999, page 17
//	string		sCmd, sErrorCodes
//	variable	chunk, nMaxChunks
//	string		sErrorText
//	variable	nErrorLevel	= UFCom_kERR_SEVERE					// valid for all errors (=mandatory beep)  except 'Clock input overrun', which may occur multiple times..
//	variable	er0	= str2num( StringFromList( 0, sErrorCodes, " " ) )	//.. in slightly too fast scripts while often not really being an error (=UFCom_kERR_IMPORTANT, beep can be turned off) 
//	variable	er1	= str2num( StringFromList( 1, sErrorCodes, " " ) )
//	if ( er0 == 0 )
//		return	0
//	elseif ( er0 == 255 )
//		sErrorText	= "Unknown command.   [" + sCmd  + "]"
//	elseif( er0 == 254 )
//		sErrorText	= "There is an error in the argument list  in field " + num2str( er1 / 16 ) + ".   [" + sCmd  + "]"
//	elseif( er0 == 253 )
//		sErrorText	= "Runtime error resulting probably from field " + num2str( er1 / 16 ) + ".   [" + sCmd  + "]"
//	elseif( er0 == 252 )
//		sErrorText	= "Error evaluating expression.   [" + sCmd  + "]"
//	elseif( er0 == 251 )
//		sErrorText	= "Division by zero during evaluation of an expression.   [" + sCmd  + "]"
//	elseif( er0 == 250 )
//		sErrorText	= "Unknown symbol.   [" + sCmd  + "]"
//	elseif( er0 == 249 )
//		sErrorText	= "Command too long.   [" + sCmd  + "]"
//	elseif( er0 == 248 )
//		sErrorText	= "End of line (CR character)  in a string field introduced by  ''  .   [" + sCmd  + "]"
//	elseif( er0 == 247 )
//		sErrorText	= "Memory reference was outside user memory area.   [" + sCmd  + "]"
//	elseif( er0 == 16 ||  er0 == 32 )
//		sErrorText	= "Inspite of Ced reporting 'Clock interrupt overrun : Sampling too fast or too many channels' :  THE DATA MAY BE OK. [\t" + UFCom_pad(sCmd,19)  + "\t]"
//		nErrorLevel = UFCom_kERR_IMPORTANT		// beep can be turned off when this error is triggered erroneously (which is unfortunately often the case)
//	else
//		sErrorText	= "Could not interpret this error :" + sErrorCodes + "   [" + sCmd  + "]"
//	endif
//	sErrorText = sErrorText + "  err:'" + sErrorCodes + "'  in chunk " + num2str( chunk )	 +  " / " + num2str( nMaxChunks )	
//	UFCom_FoAlert( ksACQ, nErrorLevel, sErrorText[0,220] )
//	return	er0 * 256 + er1							// 2003-0805  build and return  1  16 bit number from the 2 bytes 
//
//End
//
////==============================================================================================================================================
////  1401  TEST  FUNCTIONS
//
//Function		PanelTest1401( nMode )
//	variable	nMode
//	string  	sFBase		= "root:uf:"
//	string  	sFSub		= ksACQ_	
//	string  	sWin			= "ced" 
//	string		sPnTitle		= "Ced1401"
//	string		sDFSave		= GetDataFolder( 1 )									// The following functions do NOT restore the CDF so we remember the CDF in a string .
//	UFCom_PossiblyCreateFolder( sFBase + sFSub + sWin ) 
//	InitPanelTest1401( sFBase + sFSub, sWin )										// fills big text wave  'sPnOptions' (=tPn)  with all information about the controls necessary to build the panel
//
//	variable	xPosPercent = 80, yPosPercent = 2, xSzPts = 80, ySzPts = 150, rxPosPts, ryPosPts// Position the panel in percent of screen area. This is only approximately as (and as long as) the size of the panel  (=xSzPts, ySzPts)  is only guessed...
//	UFCom_Panel3PositionIt( xPosPercent, yPosPercent, xSzPts, ySzPts, rxPosPts, ryPosPts )	// Compute approximate panel position and pass it back in 'rxPosPts' and 'ryPosPts'		
//
//	UFCom_Panel3Sub_( sWin, sPnTitle, sFBase + sFSub, rxPosPts, ryPosPts, 1,  nMode ) 		// Compute the panel dimensions. Draw the panel displaying and hiding needed/unneeded controls
//	FP_LstDelWindowsSet( AddListItem( sWin, FP_LstDelWindows() ) )				// add this panel to global list so that we can remove in on Cleanup or Exit
//	SetDataFolder sDFSave									// Restore CDF from the string  value
//End
//
//Function		InitPanelTest1401( sF, sPnOptions )
//	string  	sF, sPnOptions
//	string		sPanelWvNm = sF + sPnOptions
//	variable	n = -1, nItems = 20
//	 printf "\t\tInitPanelTest1401( '%s',  '%s' ) \r", sF, sPnOptions 
//	make /O /T /N=(nItems)	$sPanelWvNm
//	wave  /T	tPn	=		$sPanelWvNm
//	//				Type	 NxL Pos MxPo OvS	Tabs		Blks		Mode		Name		RowTi				ColTi		ActionProc	XBodySz	FormatEntry	Initvalue	Visibility	HelpTopic
//	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	°:		,:		1,°:			buCurrntHnd:	Current handle:			:		fCurrentHnd():	:		:			:		:		Current handle 1401:	"
//	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	°:		,:		1,°:			buOpen1401:	Open 1401:			:		fOpen1401():	:		:			:		:		Open 1401:		"
//	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	°:		,:		1,°:			buReset1401:	Reset 1401:			:		fReset1401():	:		:			:		:		Reset 1401:		"
//	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	°:		,:		1,°:			buClose1401:	Close 1401:			:		fClose1401():	:		:			:		:		Close 1401:		"
//	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	°:		,:		1,°:			buType1401:	Type of1401:			:		fType1401():	:		:			:		:		Type of 1401:		"
//	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	°:		,:		1,°:			buMem1401:	Memory of 1401:		:		fMemory1401():	:		:			:		:		Memory of 1401:	"
//	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	°:		,:		1,°:			buStats1401:	Status of1401:			:		fStatus1401():	:		:			:		:		Status of 1401:		"
//	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	°:		,:		1,°:			buProps1401:	Properties of 1401:		:		fProperties1401()::		:			:		:		Properties of 1401:	"
//	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	°:		,:		1,°:			buResetDacs:	ResetDacs:			:		fResetDacs():	:		:			:		:		Reset Dacs:		"
//	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	°:		,:		1,°:			buSetDigOut:	Set digital outputs:		:		fSetDigOut():	:		:			:		:		Set digital outputs:	"
//	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	°:		,:		1,°:			buResDigOut:	Reset digital outputs:		:		fResetDigOut():	:		:			:		:		Reset digital outputs:	"
//
//	redimension  /N = ( n+1)	tPn
//End
//
//// To get all Helptopics for the above panel  execute   PnTESTAllTitlesOrHelptopics( "root:uf:acq:", "ced" ) 
////  ->   Current handle 1401;Open 1401;Reset 1401;Close 1401;Type of 1401;Memory of 1401;Status of 1401;Properties of 1401;Reset Dacs;Set digital outputs;Reset digital outputs;  
//
//
//Function		fCurrentHnd( s )
//	struct	WMButtonAction &s
//	 printf "\t\t%s\t \r",  s.ctrlName
//	printf "\tTest1401   Current   NEW  handle is %d \r", UFP_CedGetHandle()
//End
//
//Function		fOpen1401( s )
//	struct	WMButtonAction &s
//	 printf "\t\t%s\t \r",  s.ctrlName
//	UFP_CedCloseAndOpen( kMSGLINE_C )
//End
//
//Function		fReset1401( s )
//	struct	WMButtonAction &s
//	UFP_CedReset( kMSGLINE_C )
//End
//
//Function		fClose1401( s )
//	struct	WMButtonAction &s
//	UFP_CedClose( kMSGLINE_C )
//End
//
//
//Function		CedDriverType( mode )
//	variable	mode
//	variable	nCedDriverType	= UFP_CedDriverType()	
//	if ( mode )
//		printf "\t\t1401 driver type:\t'%s' \t\t(%d) \r", StringFromList( nCedDriverType +1 , sCEDDRIVERTYPES ), nCedDriverType	// the string list 'sCEDDRIVERTYPES 'starts with 'unknown' = -1
//	endif
//	return	nCedDriverType
//End
//
//Function		fType1401( s )
//	struct	WMButtonAction &s
//	printf "\t\t\tCEDType:"
//	variable	nType	   = CEDType( kMSGLINE_C )
//	printf "\t\t\tCEDDriver:"
//	variable	nDriverType = CEDDriverType( kMSGLINE_C )
//End
//
//static Function		CedType( mode )
//	variable	mode
//	variable	nCedType	= UFP_CedTypeOf()	
//	if ( mode )
//		printf "\t\t1401 type:\t\t'%s'  \t(%d) \r", StringFromList( nCedType + 1, sCEDTYPES ), nCedType	// the string list 'sCEDTYPES 'starts with 'unknown' = -1
//	endif
//	return	nCedType
//End
//
//Function		fMemory1401( s )
//	struct	WMButtonAction &s
//	variable	nCedType, nSize
//	printf "\tChecking memory size  before\tsending 'MEMTOP,E;'  : "
//	nSize	= CEDGetMemSize( kMSGLINE_C )	
//	nCedType	= CEDType( kMSGLINE_C )
//	if ( nCedType == c1401PLUS )					// only  1=1401plus needs 'MEMTOP,E;' command , but not 0=1401standard,  2=1401micro or  3=1401power
//		CEDSendStringCheckErrors(  "MEMTOP,E;" , 0 ) // 1 ) 
//		printf "\tChecking memory size   after \tsending 'MEMTOP,E;'  : "
//		nSize = CEDGetMemSize( kMSGLINE_C )		
//	endif
//End
//
//Function	CEDGetMemSize( mode )			
//	variable	mode
//	variable	nSize	= UFP_CedGetMemSize()
//	if ( mode )
//		printf "\t\t1401 has memory: %d Bytes = %.2lf MB \r", nSize, nSize/1024./1024.
//	endif
//	return	nSize
//End
//
//
//Function		fStatus1401( s )
//	struct	WMButtonAction &s
//	PrintCEDStatus( 0 )					// 0 disables the printing of 1401 type and memory 
//End
//
//Function		fProperties1401( s )
//	struct	WMButtonAction &s
//	PrintCEDStatus( kMSGLINE_C )			// kMSGLINE_C enables the printing of 1401 type and memory 
//End
// 
// 
//Function		fResetDacs( s )
//	struct	WMButtonAction &s
//	CEDSendStringCheckErrors(  "DAC,0 1 2 3,0 0 0 0;" , 1  ) 
//End
// 
//Function		fSetDigOut( s )
//	struct	WMButtonAction &s
//	CEDSetAllDigOuts(1 )					// 2003-1110  Initialize the digital output ports with 1 : set to HIGH
//End
//
//Function		fResetDigOut( s )
//	struct	WMButtonAction &s
//	CEDSetAllDigOuts( 0 )				// 2003-1110  Initialize the digital output ports with 0 : set to LOW
//End
// 
//Function		CEDSetAllDigOuts( value )
//	// 2003-1110  Initialize the digital output ports with 0 : set to LOW
//	variable	value 
//	variable	nDigoutBit
//	string		buf
//	for ( nDigoutBit = 8; nDigoutBit <= 15; nDigoutBit += 1 )
//		sprintf  buf, "DIG,O,%d,%d;", value, nDigoutBit
//		CEDSendStringCheckErrors( buf , 0 ) 
//	endfor
//End
//
//
//Function	   	PrintCEDStatus( ErrShow )
//// prints current CED status (missing or off, present, open=in use) and also (depending on 'ErrShow') the type and memory size of the 1401 
////! There is some confusion regarding the validity of CED handles  (CED Bug? ) : 
////  The manual says that positive values returned from 'CEDOpen()' are valid handles (at least numbers from 0..3, although only 0 is used presently)...
//// ..but actually the only valid handle number ever returned is 0. Handle 5 (sometimes 6?) is returned after the following actions (misuse but nevertheless possible) : 
//// 1401 is switched on and open, 1401 is switched off, 1401 is switched on again, 1401 is opened -> hnd 5 is returned indicating OK but 1401 is NOT OK and NOT OPEN. . 
//// This erroneous 'state 5' must be stored somewhere in the host as it is cleared by restarting the IGOR program  OR by  closing the 1401  with hnd=0 before attempting to open it.
//// Presently the XOPs CedOpen etc. do not process the 'switched off positive handle state' separately but handle it just like the closed state of the 1401.
// 	variable	ErrShow
// 	string	sText
//	variable	bCEDWasClosed, nHndAfter, nHndBefore = UFP_CedGetHandle()
//	if ( CEDHandleIsOpen() )				
//		bCEDWasClosed = UFCom_FALSE
//		sText = "\t1401 should be open  (old hnd:" + num2str( nHndBefore ) + ")"
//	else
//		bCEDWasClosed = UFCom_TRUE
//		sText = "\t1401 was closed or off  (old hnd:" + num2str( nHndBefore ) + ")"
//	endif
//	nHndAfter = UFP_CedCloseAndOpen( 0 ) 		// try to open it  independent of its state : open, closed, switched off or on (no messages!)
//	if ( CEDHandleIsOpen() )				
//		sText += ".... and has been (re)opened  (hnd = " + num2str( nHndAfter )+ ")"
//		
//		// we get 1401 type and memory size right here in the middle of  CEDGetStatus() because  1401 must be open.. 
//		// ..we also print 1401 type and memory right here (before the status line is printed) but we could also disable printing here (ErrShow=0) and print 'nSize' and 'nType' later
//		if ( ErrShow )
//			printf "\tCEDStatus: "
//			variable	nDriverType = CEDDriverType( ErrShow )			
//			printf "\tCEDStatus: "
//			variable	nType	   = CEDType( ErrShow )			
//			printf "\tCEDStatus: "
//			variable	nSize	   = CEDGetMemSize( ErrShow )	
//		endif
//	else
//		sText += ".... but cannot be opened: defective? off?  (new hnd:" + num2str( nHndAfter ) + ")  "// attempt to open  was not successfull..
//	endif
//	if ( bCEDWasClosed )								// CED was closed at  the beginning so close it again
//		UFP_CedClose( 0 )								// ..so restore previous closed state  (no messages!)
//		sText += ".... and has been closed again (hnd = " + num2str( UFP_CedGetHandle() ) + ")"
//	endif
//	printf "\tCEDStatus:\t%s \r", sText
//End
//
//static constant	CED_NOT_OPEN  	= -1		
//
//Function		CEDHandleIsOpen()
//// only the handle under program control (not the 1401 itself) is checked, if the open 1401 is accidentally turned off this function gives the wrong result 
//	return ( UFP_CedGetHandle()  !=  CED_NOT_OPEN )
//End 
//
//
