//	// UF_AcqCed4.ipf
//	
//	// 2008-04-20 new-style script
//	
//	// UF_AcqCed.ipf
//	// 
//	// Routines for 
//	//	continuos data acquisition and pulsing  using  CED hardware and IGORs background timer 
//	//	controlling the CED digital output 
//	//	measuring time durations spent in various program parts
//	//
//	// For the acquisition to work there must be IGOR extensions (= CED1401.XOP)  and  a SHORTCUT  to Wavemetrics\Igor Pro Folder\IgorExtensions
//	// CFS32.DLL  and  USE1432.DLL  must be accessible (copy to Windows\System directory)
//	
//	// History:
//	// MAX. DATA RATES: ( 2xAD incl. TG, 2xDA, 1xDigOut), PCI interface
//	// 1401POWER:  4 us works,   3 us does'nt work at all
//	// 1401PLUS:     25 us works, 20 us does'nt work reliably (after changing to Eprom V3.22, previously much less)
//	
//	// 2003-0130	todo check why 16bit Power1401 +-5V range  makes  .9mV steps (should give .153mV steps!)
//	// 2003-0313 wrapped  'Protocol' loop around the digital output (Digout pulses were output only in protocol 0 and were missing in all following protocols)
//	// 2003-0320	periods between digout pulses can now be longer than 65535 sample intervals 
//	// 2003-0707 major revision of digital output 
//	// 2003-0805 major revision of acquisition 
//	
//	// 2004-0224	introduced  UFP_CedWorkingSet( 800, 4000, 0 )
//	// Dear Ulrich,
//	// It looks as if the changes to Use1432 are OK, so I am sending you the new library to try out. The new function added is defined as:
//	//
//	// U14API(short) U14WorkingSet(DWORD dwMinKb, DWORD dwMaxKb);
//	//
//	// it returns zero if all went well, otherwise an error code (currently a positive value unlike other functions). 
//	// To use it, you should call it once only at the start of your application - I'm not sure how that will apply to you. 
//	// I suggest using values of 800 and 4000 for the two memory size values, they are known to work fine with CED software.
//	// Best wishes, Tim Bergel
//	
//	
//	
//	//? todo the amplitude of the last blank is held appr. 1s until it is forced to zero (by StopADDA()?) . This is a problem only when the amp is not zero. Workaround: define a dummy frame thereafter.  
//	//? todo  is it necessary that DigOut times are integral multiples of smpint ....if yes then check.... 
	  
	#pragma rtGlobals=1								// Use modern global access method.

// 2009-12-12
strconstant ksTBL_ACQ = "tbAcq"
	
	static   constant    cDRIVERUNKNOWN 	= -1 ,  cDRIVER1401ISA	= 0 ,  cDRIVER1401PCI = 1 ,  cDRIVER1401USB = 2
	static strconstant  sCEDDRIVERTYPES	= "unknown;ISA;PCI;USB;unknown3" 
	static   constant    c1401UNKNOWN   	= -1 ,  c1401STANDARD	= 0 ,  c1401PLUS = 1 ,   c1401MICRO = 2 ,  c1401POWER = 3 ,  c1401MICRO_MK2 = 4 ,  c1401POWER_MK2 = 5 ,  c1401MICRO_3 = 6 ,   c1401UNUSED = 7
	static strconstant  sCEDTYPES			= "unknown;Standard 1401;1401 Plus;micro1401;Power1401;micro1401mkII;Power1401mkII;micro1401-3;unknown/unused"	//  -1 ... 4
	
	static constant	nTICKS				= 10			//20 		// wait nTICKS/60 s between calls to background function
	
	static constant	cMAX_TAREA_PTS 		= 0x080000 	// CED maximum transfer area size is 1MB under Win95. It must explicitly be enlarged under  Win2000
	
	static constant	cADDAWAIT			= 0
	static constant	cADDATRANSFER		= 1
	
	static	constant	cBKG_UNDEFINED		= 0
	static	constant	cBKG_IDLING			= 1			// defined but not running
	static	constant	cBKG_RUNNING		= 2
	
	static constant	cFAST_TG_COMPRESS	= 255		// set to >=255 for maximum compression , will be clipped and adjusted to the allowed range  1...255 / ( nAD + nTG ) 
	
//	//  CEDError.H  AND FPULSE.IPF : Error handling: where and how are error messages displayed
//	constant		ERR_AUTO_IGOR		= 8			// IGORs automatic error box :lookup CED error string in xxxWinCustom.RC
//	constant		ERR_FROM_IGOR		= 16			// custom error box: lookup CED error string in xxxWinCustom.RC
//	constant		ERR_FROM_CED		= 32			// custom error box: get CED error string from U14GetString() 
	// combinations of the flags above:
	static constant		kMSGLINE_C			= 38			// 32 + 4 + 2 	// always: print  all 1401 messages and errors using  Ced strings but  displays no error box (for debug)
	static constant		kERRLINE_C			= 34			// 32 + 2 		// on error: error line using  Ced strings
	static constant		KERRLINE_I 			= 18			// 16 + 2		// on error: error line using IGOR xxxWinCustom.RC strings
	static constant		kERRBOX_C			= 33			// 32 + 1		// on error: error box  using  Ced strings
	static constant		kERRBOX_I 			= 17			// 16 + 1 		// on error: error box  using IGOR xxxWinCustom.RC strings

	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//   ACQUISITION  FUNCTIONS

Function	/S	fVdPrediction()
// ValDisplay sample code
// ValDisplay: can be used in panels or in controlbars in graphs, invalid arguments can be ignored by using #, updates automatically (no explicit dependencies neccessary)????
// e.g.  ValDisplay vd1,  title="Pred",  format="%4.2lf",  limits={ 0,2,1},  barmisc={0,32}, lowColor=(65535,0,0), highColor=(0,50000,0),   value= #"root:uf:acq:pul:vdPredict0000"
//	return "root:uf:acq:pul:vdPredict0000|%4.2lf|0,2,1,|0,32,|65535,0,0,|0,50000,0,|"	// value | format | limits | barmisc | lowColor | highColor
	return "%4.2lf|0,2,1,|0,32,|65535,0,0,|0,50000,0,|"				// format | limits | barmisc | lowColor | highColor
End

	
Function		StartActionProc_ns( sFo, sSubFoC )
	string  	sFo, sSubFoC
	variable	hnd			= CedHandle()
	variable	bTrigMode		= TrigMode()
	variable	bAppendData	= AppendData()
	nvar		gbRunning	= $"root:uf:acq:" + UFPE_ksKEEP + ":gbRunning"

	 printf "\t\tStartStopActionProc_ns()   bTrigMode:%.0lf   cbAppndData:%.0lf    gbRunning:%d  sFo:%s  \r", 	bTrigMode, bAppendData, gbRunning, sFo
	StartStopFinishButtonTitles( sFo, sSubFoC )

	if ( bTrigMode == 0 )	 	// SW triggered normal mode
		if ( ! gbRunning )
			StartStimulusAndAcquisition_ns()
			//StartStimulusAndAcquisition_ns( sSubFoC, sSubFoW )
		endif
	endif
End


Function		FinishActionProc_ns( sFo, sSubFoC )
	string  	sFo, sSubFoC
	variable	hnd			= CedHandle()
	variable	bTrigMode		= TrigMode()
	variable	bAppendData	= AppendData()
	nvar		gbRunning 	= $"root:uf:acq:" + UFPE_ksKEEP + ":gbRunning"
	nvar		gbAcquiring 	= $"root:uf:acq:" + sSubFoC + ":gbAcquiring"
	nvar		bIncremFile 	= $"root:uf:acq:" + sSubFoC + ":gbIncremFile"

	 printf "\t\tFinishActionProc_Ns(entry) \traTrigMode:%.0lf   AppendData:%.0lf    gbRunning:%.0lf   bIncremFile:%.0lf  \r", 	bTrigMode, bAppendData, gbRunning, bIncremFile
	StartStopFinishButtonTitles( sFo, sSubFoC )

// 2010-02-09  simplify the code.   E3E4  (stop/ finish)  works by selecting  Trig 'Start'   again
//	if ( bTrigMode == 0  )								// SW  triggered normal mode
//		FinishFiles()
//		if ( gbAcquiring )
//			StopADDA_ns( "\tUSER ABORT1" , UFCom_FALSE, hnd  )		//  FALSE: do not invoke ApplyScript()
//			gbAcquiring = UFCom_FALSE						// normally this is set in 'CheckReadyDacPosition()'  but user abortion is not handled there correctly 
//		endif
//	endif
//	if ( bTrigMode == 1 )								// HW E3E4 trigger
//		FinishFiles()								// close CFS file so that next acquisition is written to a new file
//		if ( gbAcquiring )								// abort only when user pressed 'Finish' during the stimulus/acquisition phase,... not during the waiting phase: 
//			StopADDA_ns(  "\tUSER ABORT2" , UFCom_FALSE, hnd )		//  FALSE: do not invoke ApplyScript()
//		endif
//	endif

	FinishFiles()
	if ( gbAcquiring )
		StopADDA_ns( "\tUSER ABORT1" , UFCom_FALSE, hnd  )		//  FALSE: do not invoke ApplyScript()
		if ( bTrigMode == 0  )									// only in SW  triggered normal mode, not in HW-triggered E3E4 mode
			gbAcquiring = UFCom_FALSE						// normally this is set in 'CheckReadyDacPosition()'  but user abortion is not handled there correctly 
		endif
	endif


	if (  bAppendData )
		bIncremFile	= UFCom_TRUE
	endif
	 printf "\t\tFinishActionProc_Ns( exit )  \traTrigMode:%.0lf   AppendData:%.0lf    gbRunning:%.0lf   bIncremFile:%.0lf  \r", 	bTrigMode, bAppendData, gbRunning, bIncremFile
End


Function		StartStimulusAndAcquisition_ns()
	string  	sFo			= ksACQ
	wave 	wG			= $FoWvNmWgNs( sFo )
	string  	sSubFoC		= UFPE_ksCOns
	variable	bTrigMode		= TrigMode()
	variable	bAppendData	= AppendData()
	nvar		bIncremFile	= $"root:uf:acq:" + sSubFoC + ":gbIncremFile"
	variable	code
	string		bf
// 2005-1201
	wG[ UFPE_WG_SWPWRIT ]	= 0 
	nvar	wgSwpWrit	= root:uf:acq:pul:svSwpsWrt0000
	wgSwpWrit	= 0
	
	if ( wG[ UFPE_WG_PNTS ]  )
		//variable	nRadDebgGen	= UFCom_DebugDepthGen()
		//if ( nRadDebgGen )
		if ( UFCom_DebugVar( sFo, "General" ) )
			printf "\tSTARTING ACQUISITION %s %s... \r", SelectString( bTrigMode, " ( after 'Start' , " , " ( waiting for trigger on E3E4, "  ),  SelectString( bAppendData, "writing separate files )", "appending to same file )" ) 
		endif

// 2007-0402   removed because it kills   UFCom_StartTimer( sFo, "LoadScr" )
//		UFCom_KillAllTimers()

		// This function merely starts the sampling (=background task). This function is finished already at the BEGINNING of the sampling!
//		code	= CedStartAcq()											// the error code is not yet used 	// 2008-06-06 
		code	= CedStartAcq( sSubFoC )									// the error code is not yet used 

	else
		UFCom_FoAlert( sFo, UFCom_kERR_LESS_IMPORTANT,  "Empty stimulus file..... " ) 
	endif
	if ( ! CEDHandleIsOpen_ns() )
		UFCom_FoAlert( sFo, UFCom_kERR_IMPORTANT, "The CED 1401 is not open. " )			// acquisition will start but only in test mode with fake data
	endif
End	

//==================================================================================================================================

Function		CEDInitialize_ns( sFo, sSubFoC, sc, lllstIO, lllstIOTG, llstBLF, lstTotdur, lllstTapeTimes, wG )
// The  CED initialization code must take care of special cases:				( new  031210 )
//	- ApplyScript()	with 1401 not present or switched off :  go into test mode
//	- ApplyScript()	with 1401 just switched on
//	- ApplyScript()	after the user switched the 1401 off and on again (perhaps to recover from a severe error)
//  More elaborate code checking the interface type but avoiding unnecessary initialisations : 
// ??? Logically the initialization every time even when the 1401 is already 'on' is NOT required, but for unknown reasons  ONLY the  Power1401  and ONLY with USB interface will not work without it ( will  abort with a 'DIGTIM,OB;' error in SetEvents() ) .
	string  	sFo, sSubFoC, lllstIO, lllstIOTG, llstBLF, lstTotdur, lllstTapeTimes
	variable 	sc
	wave  	wG		
	//variable	nRadDebgGen		= UFCom_DebugDepthGen()
	nvar		gnReps			= $"root:uf:" + sFo + ":" + sSubFoC + ":gnReps"
	nvar		gPntPerChnk		= $"root:uf:" + sFo + ":" + sSubFoC + ":gPntPerChnk"
	nvar		gbRunning		= $"root:uf:" + sFo + ":" + UFPE_ksKEEP + ":gbRunning" 
	nvar		gCedMemSize		= $"root:uf:" + sFo + ":" + sSubFoC + ":gCedMemSize"
	nvar		gnCompressTG		= $"root:uf:" + sFo + ":" + sSubFoC + ":gnCompressTg"
// 2009-??	removed the possibility to search an improved stimulus timing
//	nvar		gbSearchStimTiming	= $"root:uf:" + sFo + ":mis:ImprStimTim0000"
	nvar		gbRequireCed1401	= $"root:uf:" + sFo + ":mis:RequireCed0000"
	variable	nSmpInt			= wG[ UFPE_WG_SI ]
	variable	nCntAD			= wG[ UFPE_WG_CNTAD ]	
	variable	nCntDA			= wG[ UFPE_WG_CNTDA ]	
	variable	nCntTG			= wG[ UFPE_WG_CNTTG ]	
	variable	nPnts			= wG[ UFPE_WG_PNTS ] 

	string		sDigoutSlices		= DgoDigoutSlices( sFo )
	variable	nSlices			= ItemsInList( sDigoutSlices )							

	variable	state, code, nCEDMemPts, nTrfAreaPts //= 1
	string		bf

	variable	ShowMode = ( UFCom_DebugVar( "acq", "General" ) & 4  ||  UFCom_DebugVar( "acq", "Ced" ) & 2 )    ? UFPE_MSGLINE : UFPE_ERRLINE	
	variable	bMode	 = ( UFCom_DebugVar( "acq", "General" ) & 4   ||  UFCom_DebugVar( "acq", "Ced" ) & 2 )    ? 	UFCom_TRUE  :  UFCom_FALSE

	variable	hnd		= CedHandle()// 2010-01-05	old handle which can be valid or invalid
	 printf  "\t\tCed CEDInitialize    running: %.0lf   hnd:%d\r", gbRunning, hnd

	if ( nPnts  &&  ! gbRunning )

		// if ( UFCom_DebugDepthSel() > 0  &&  UFCom_DebugVar( 0, "acq", "Ced" ) )
			printf "\t\tCed CEDInitialize    running: %d    before checking UFP_CedState() \t \tCEDHandleIsOpen_ns() : %d\ttp:\t'%s' \r", gbRunning, CEDHandleIsOpen_ns(), lllstTapeTimes
		// endif
		//  ShowMode = kMSGLINE_C	
		if  ( hnd >= 0 )								// 0 is OK = Ced is open,  but  > 0 often means an error (e.g. Ced has been accidentally switched off and on)  
// 2010-01-05
//			hnd	= UFP_CedState( hnd ) 									// Check if CEDHandle is consistent with current Ced state. Set CEDHandle 'off'  if Ced state says 'off'  (happens if 1401 had been on but has just been switched off) 
//			if ( UFCom_DebugDepthSel() > 0  &&  UFCom_DebugVar( 0, "acq", "Ced" ) )
//				printf "\t\tCed CEDInitialize    running: %d    Ced1401 is %s\t(1+ code:%d)  \tCEDHandleIsOpen_ns() : %d \r", gbRunning, SelectString( state + 1, "closed", "open" ),  state+1 , CEDHandleIsOpen_ns()
//			endif
			state	= UFP_CedStateOf1401( hnd ) 									// Check if CEDHandle is consistent with current Ced state. Set CEDHandle 'off'  if Ced state says 'off'  (happens if 1401 had been on but has just been switched off) 
			if ( UFCom_DebugVar( "acq", "Ced" ) )
				printf "\t\tCed CEDInitialize    running: %d    Ced1401 state:%d\t\tCEDHandleIsOpen_ns() : %d \r", gbRunning, state, CEDHandleIsOpen_ns()
			endif
			if ( state )		// should have been 0
				hnd	= UFP_CedClose( hnd )
				CedHandleSet( CED_NOT_OPEN )
			endif
		endif

		// Initialization is only executed once at startup, not with every new script
		if ( ! CEDHandleIsOpen_ns() ) 

			hnd	= UFP_CedCloseAndOpen(  hnd )					
			CedHandleSet( hnd )

			if ( CEDHandleIsOpen_ns() ) 								
				code		= CEDInit1401DACADC( hnd, ShowMode )				// The Ced was off and has just been switched on
				if ( code )	
					hnd	= UFP_CedClose( hnd )
					CedHandleSet( CED_NOT_OPEN )
					return	code
				endif
				gCEDMemSize	= CEDGetMemSize( hnd, 0 )					// with the Ced connected and 'on' the actual memory size is used

// 2010-02-02	removed the possibility to shrink the Ced memory
// 2010-02-07	revived
				SetShrinkCedMem( gCEDMemSize / UFPE_kMBYTE )				// Set the SetVariable  with the true Ced memory only once after switching the Ced on. The user may decrease this value later.

			else
				if ( FP_IsRelease()  &&  gbRequireCed1401 )	
					UFCom_FoAlert( sFo, UFCom_kERR_FATAL,  "Ced  is not responding. Only in test mode a Ced1401 is not required. Uncheck  'Require Ced..'  in the  'Misc'  panel.  Aborting..." )
					hnd	= UFP_CedClose( hnd )
					CedHandleSet( CED_NOT_OPEN )
					return	UFCom_kERROR
				endif
				gCEDMemSize	= UFPE_kTESTCEDMEMSIZE					// without Ced the default  UFPE_kTESTCEDMEMSIZE  is used  as upper limit for the SetVariable
			endif

// 2010-02-02	removed the possibility to shrink the Ced memory
// 2010-02-07	revived
			if ( ShrinkCedMem()  == 0 )										// true only during the VERY FIRST program start (CED may be off or on) : initially set the SetVariable...
				SetShrinkCedMem( gCEDMemSize / UFPE_kMBYTE )				// ...with the true Ced memory size value or with TESTMEMSIZE. The user may decrease this value later.
			endif														// in all further calls : use as memory size the value which the user has deliberately decreased...

		endif

		// Called  with every  'ApplyScript()'  :  react on a changed trigger mode
		if ( CEDHandleIsOpen_ns() ) 

			// ??? Logically this initializing is NOT required, but for unknown reasons  ONLY the  Power1401 and ONLY with USB interface will not work without it ( will  abort with a 'DIGTIM,OB;' error in SetEvents() ) .
			variable	nDriverType  = CEDDriverType( bMode )	
			variable	nCedType	    = CEDType( hnd, bMode )	


// 2010-02-09  only test weg in the attempt to make E3E4 work
//			if ( nCedType == c1401POWER  &&   nDriverType == cDRIVER1401USB )	// ONLY the  USB Power1401 needs (normally unnecessary)  reinitialisation
//				code	  = CEDInit1401DACADC( hnd, bMode )			
//			endif
			code	  = CEDInit1401DACADC( hnd, bMode )						// 2010-02-09  in the E3E4 mode this initialisation is ALSO required for the 1401Plus :  EVERY  Ced type needs it.


			code		= CedSetEvent( sFo, hnd, bMode )
			if ( code )
				hnd	= UFP_CedClose( hnd )
				CedHandleSet( CED_NOT_OPEN )
				return	code
			endif
		endif
			
// 2010-02-02	removed the possibility to shrink the Ced memory
////		nCEDMemPts	= ShrinkCedMem() * UFPE_kMBYTE / 2					// ..thereby improving loading speed  but unfortunately  making the maximum Windows interruption time much smaller...
//		nCEDMemPts	= gCEDMemSize / 2									// ..thereby improving loading speed  but unfortunately  making the maximum Windows interruption time much smaller...NO LONGER
// 2010-02-07	revived
		nCEDMemPts	= ShrinkCedMem() * UFPE_kMBYTE / 2					// ..thereby improving loading speed  but unfortunately  making the maximum Windows interruption time much smaller...

		
// 2009-??	removed the possibility to search an improved stimulus timing
//		//if ( gbSearchStimTiming )		
//			//SearchImprovedStimulusTiming( sFo, wG, nCEDMemPts, nPnts, nSmpInt, nCntDA, nCntAD, nCntTG, nSlices )
//		//endif

		nTrfAreaPts	= SetPoints( sFo, nCEDMemPts, nPnts, nSmpInt, nCntDA, nCntAD, nCntTG, nSlices, UFCom_kERR_IMPORTANT, UFCom_kERR_FATAL )	// all params are points not bytes	

		if ( nTrfAreaPts <= 0 )
			sprintf bf, "The number of stimulus data points (%d) could not be divided into CED memory without remainder. \r\tAdjust duration(s) in stimulus protocol slightly so that data points contains more small primes." , nPnts
			string		lstPrimes	= UFCom_FPPrimeFactors( sFo, nPnts )				// list containing the prime numbers which give 'nPnts'
			UFCom_FoAlert( sFo, UFCom_kERR_FATAL,  bf + "   " + lstPrimes[0,50] )
			return UFCom_kERROR				
		endif

		if ( ELIMINATE_BLANKS() == 1 )			
			UFPE_StoreChunkSet_ns( sFo, llstBLF, lstTotdur, lllstTapeTimes, sSubFoC, wG )																			// after SetPoints : needs nPnts and gnPntPerChk
		endif
		if ( ELIMINATE_BLANKS() == 2 )			
			string  lllstChunkTimes=UFPE_StoreChunkSet_eb2( sFo, llstBLF, lllstTapeTimes, sSubFoC )		//...............?????												// after SetPoints : needs nPnts and gnPntPerChk
		endif

		wave  /Z	wRaw	= $"root:uf:" + sFo + ":" + UFPE_ksKEEPwr + ":wRaw"	// 2004-1203 must be PERMANENT data folder, will give sporadic heap scramble problems if a regularly cleared folder (e.g.ar) is used	
		 printf "\t\tCEDInitialize 1 '%s'   \texists wRawDDA: %d   points: \t%8d\t  TAPts: \t%8d \r", sFo + ":" + UFPE_ksKEEPwr , waveExists( wRaw ),  waveExists( wRaw ) ? numPnts(wRaw) : -1 , nTrfAreaPts // 2005-0128

		if ( waveExists( wRaw ) )
			if ( CEDHandleIsOpen_ns() )
				code	= UFP_CedUnsetTransferArea( hnd, 0, wRaw, ShowMode ) 		// the attempt to unset a non-existing transfer area  (=error -528)  will do no harm as it is caught in the XOP
				if ( code != 0   &&   code != -528 )								// this error -528 will occur after having been in test mode and then switching the Ced on
					hnd	= UFP_CedClose( hnd )	
					hnd	= CED_NOT_OPEN
					CedHandleSet( hnd )
					KillWaves		wRaw
					return	code
				endif
			endif
			KillWaves		wRaw
		endif
		make  	/W /N=( nTrfAreaPts )  $"root:uf:" + sFo + ":" + UFPE_ksKEEPwr + ":wRaw" 	// allowed area 0, allowed size up to 512KWords=1MB , 16 bit integer
		wave	wRaw			= $"root:uf:" + sFo + ":" + UFPE_ksKEEPwr + ":wRaw"	// 2004-1203 must be PERMANENT data folder, will give sporadic heap scramble problems if a regularly cleared folder (e.g.ar) is used	

		// Go into acquisition  either  without CED for the  test mode  or  with CED only when transfer buffers are ok, otherwise system hangs... 
		// printf "\t\tCEDInitialize 2 '%s'   \texists wRawDDA: %d   points: \t%8d\t  TAPts: \t%8d \r", sFo, waveExists( wRaw ),  waveExists( wRaw ) ? numPnts(wRaw) : -1 , nTrfAreaPts
		if ( ! CEDHandleIsOpen_ns()  ||  UFP_CedSetTransferArea( hnd, 0, nTrfAreaPts, wRaw , ShowMode ) == 0 ) 
			 printf "\t\tCEDInitialize 3 '%s'   \texists wRawDDA: %d   points: \t%8d\t  TAPts: \t%8d \r", sFo + ":" + UFPE_ksKEEPwr, waveExists( wRaw ),  waveExists( wRaw ) ? numPnts(wRaw) : -1 , nTrfAreaPts

			// 2008-07-29 eb2 Tape
			if ( ELIMINATE_BLANKS() <= 1 )			
				code = CEDInitializeDacBuffers( sFo, sSubFoC, sc, lllstIO, wRaw, wG, hnd )		// ignore 'Transfer' and 'Convolve' times here during initialization as they have no effect on acquisition (only on load time)
			elseif ( ELIMINATE_BLANKS() == 2 )			
				code = CEDInitializeDacBuffers_eb2( sFo, sSubFoC, sc, lllstIO, llstBLF, lllstTapeTimes, wRaw, wG, lllstChunkTimes, hnd )	// avoid BigIO waves entirely...
			endif			

			if ( code ) 
				return	UFCom_kERROR
			endif
		else
			UFCom_FoAlert( sFo, UFCom_kERR_FATAL,  "Could not set transfer area. Try logging  in as Administrator. Aborting..." )
			return	UFCom_kERROR
		endif

		if ( ELIMINATE_BLANKS() == 2 )			
			printf "\t\tCEDInitialize    \tEB:%d   -> AdcPoints PRELIMINARILY reduced from %d to %d \r", ELIMINATE_BLANKS(), nPnts, TotalTapePts( sFo, sc, llstBLF, lllstTapeTimes )	
			nPnts 		= TotalTapePts( sFo, sc, llstBLF, lllstTapeTimes )			
		endif
		if ( SupplyWavesADCandTG_ns( sFo, sc, wG, lllstIO, lllstIOTG, nPnts ) )			// constructs 'AdcN' and 'AdcTGN' waves  AFTER  PointPerChunk  and  CompressTG  has been computed
			return	UFCom_kERROR			
		endif			

		// UFCom_DisplayMultipleList_( "Before TelegraphGainPreliminary_ns   lllstIO",	  lllstIO, 	"~;,", 7, UFPE_ioTemplate( 0 ) )
		TelegraphGainPreliminary_ns( sFo, wG, lllstIO, hnd )							// changes  global lllstIO.      Could pass lllstIOTG...	
		// UFCom_DisplayMultipleList_( "After   TelegraphGainPreliminary_ns   lllstIO",	 LstIO(sFo), "~;,", 7, UFPE_ioTemplate( 0 ) )

	else
		UFCom_FoAlert( sFo, UFCom_kERR_LESS_IMPORTANT,  "Empty stimulus file  or  stimulus/acquisition is already running. " ) 
	endif

	return  0	
End



static Function	/S	UFPE_StoreChunkSet_eb2( sFo, llstBLF, lllstTapeTimes, sSubFo )												// after SetPoints : needs nPnts and gPntPerChnk
// Builds the information which sections of a given chunk must be stored. 
// Returns list of format  'bStoreIt, TruePtsBegin, points, TapePtsBegin,; .  ..same for next section in same chunk....   ;~   ...information about next chunk...   ~'  .  The list contains  only  STORED  sections.
// possible todo : convert list to wave ???
	string  	sFo, llstBLF, lllstTapeTimes, sSubFo
	variable	nProts		= UFPE_Prots( sFo )
	variable	sc			= 0		// todo_c
	variable	nSmpInt		= SmpIntDacUs( sFo )							// wG[ UFPE_WG_SI ] 
	variable	nPnts		= TotalTrueDurPts( sFo, sc, nSmpInt, llstBLF, lllstTapeTimes )// wG[ UFPE_WG_PNTS ] 
	nvar		gPntPerChnk	= $"root:uf:acq:" + sSubFo + ":gPntPerChnk" 
	variable	c, nChunks	= nProts * nPnts / gPntPerChnk

	variable	BegTrue,  BegTape,  BPoints				// references are passed back
	variable 	bStoreIt, nChunk, BegTruePrevNr = 0, BegTruePrevOfs = 0
 	variable	EndTrue, BegTrueChnkNr, BegTrueChnkOfs, EndTrueChnkNr, EndTrueChnkOfs
	variable	pr = 0,  gr,  sw,  tp	// todo_b ???
	variable	fr, nFrm, la, nLap, bl, nBlk	= UFPE_Blocks( llstBLF )
	variable	nTap1Blk
	string  	llst	= ""

	 printf "\t\tUFPE_StoreChunkSet_eb2 a  	nProts: %d  nPnts: %d  gPntPerChk: %d  -> nChunks: %d   \r", nProts, nPnts, gPntPerChnk, nChunks
	for ( bl = 0; bl < nBlk; bl += 1 )
		nLap		= UFPE_Laps(	 llstBLF, bl )
		nFrm		= UFPE_Frames( llstBLF, bl )	
		nTap1Blk	= UFPE_TapeCount( sFo, bl, lllstTapeTimes )
		for ( la = 0; la < nLap; la += 1 )
			for ( fr = 0; fr < nFrm; fr += 1 )
				for ( tp = 0; tp < nTap1Blk; tp += 1 )
				
					UFPE_Tape_Extract( sFo, sc, pr, bl, la, fr, tp, 1, 1, nSmpInt, lllstTapeTimes, llstBLF, BegTrue, BegTape, BPoints )	// for acquisition: BExpandLaps=1, bTrueTime=1
					EndTrue			= BegTrue + BPoints
					BegTrueChnkNr		= trunc( BegTrue / gPntPerChnk )
					BegTrueChnkOfs	= mod(  BegTrue ,  gPntPerChnk )
					EndTrueChnkNr		= trunc( EndTrue / gPntPerChnk )	
					EndTrueChnkOfs	= mod(  EndTrue ,  gPntPerChnk )
					// printf "\t\t\tUFPE_StoreChunkSet_eb2 \tsFo:'%s',\tp:%d b:%d l:%d f:%d s:%.0lf t:%.0lf )\t->\tBTr:\t%8d\tPts:\t%8d\tBTp:\t%8d\t \r", sFo, pr, bl, la, fr, sw, tp, BegTrue, BPoints, BegTape

					// Process  skip/nostore phase : Construct the skipped /nostore empty blocks (which do NOT exist in bigio)  in the TA  NOW  and then send them to the Ced so that the Dac waves are built correctly i.e.INCLUDING the skipped sections
					// Use pointers into  bigIO which take into account that bigIO does not contain the skipped sections
					bStoreIt	= 0	
					if ( BegTruePrevNr == BegTrueChnkNr )
						llst	+= PreConv( bStoreIt, gPntPerChnk, BegTruePrevNr, BegTruePrevOfs, 	BegTrueChnkOfs - BegTruePrevOfs, 	BegTape ) + ";"
					else
						llst	+= PreConv( bStoreIt, gPntPerChnk, BegTruePrevNr, BegTruePrevOfs, 	gPntPerChnk 	  - BegTruePrevOfs,	BegTape ) + ";~"
						for ( nChunk = BegTruePrevNr+1; nChunk <  BegTrueChnkNr; nChunk += 1 )
							llst	+= PreConv( bStoreIt, gPntPerChnk, 	nChunk, 		0, 		gPntPerChnk, 					BegTape ) + ";~"
						endfor
						llst	+= PreConv( bStoreIt, gPntPerChnk, BegTrueChnkNr, 		0, 		BegTrueChnkOfs, 				BegTape ) + ";"
					endif							

					// Process  store  phase : Copy  the  store  blocks (which are the only ones to exist in bigio)  into the TA  and then send them to the Ced so that the Dac waves are built correctly i.e.INCLUDING the skipped sections
					// Use pointers into  bigIO which take into account that bigIO does not contain the skipped sections
					bStoreIt	= 1	
					if ( BegTrueChnkNr == EndTrueChnkNr )
						llst	+= PreConv( bStoreIt, gPntPerChnk,  BegTrueChnkNr, BegTrueChnkOfs, 	EndTrueChnkOfs - BegTrueChnkOfs, 	BegTape ) + ";"	
					else
						llst	+= PreConv( bStoreIt, gPntPerChnk, BegTrueChnkNr, BegTrueChnkOfs, 	gPntPerChnk 	  - BegTrueChnkOfs, 	BegTape ) + ";~"	
						begTape	+= gPntPerChnk - BegTrueChnkOfs																	// if a chunk has split a store section the 'BegTape' of the second section section (=begin of new chunk)....
						for ( nChunk = BegTrueChnkNr+1; nChunk <  EndTrueChnkNr; nChunk += 1 )
							llst	+= PreConv( bStoreIt, gPntPerChnk, 	nChunk, 		0,		gPntPerChnk,					BegTape ) + ";~"
							begTape	+= gPntPerChnk 																			//....already includes the points already processed in the previous section (=the end of the previoud chunk) 
						endfor
						llst	+= PreConv( bStoreIt, gPntPerChnk, EndTrueChnkNr, 		0, 		EndTrueChnkOfs,				BegTape ) + ";"	
					endif							

					BegTruePrevNr	= EndTrueChnkNr
					BegTruePrevOfs= EndTrueChnkOfs

					// printf "\t\t\tUFPE_StoreChunkSet_eb2(.\tsFo:'%s',\tp:%d b:%d l:%d f:%d s:%.0lf t:%.0lf )\t->\tBTr:\t%8d\tPts:\t%8d\tBTp:\t%8d\t->\t%8d\t/%8d\t..%8d\t/%8d\t%s \r", sFo, pr, bl, la, fr, sw, tp, BegTrue, BPoints, BegTape, BegTrueChnkNr, BegTrueChnkOfs, EndTrueChnkNr, EndTrueChnkOfs, llst[100]
				
				endfor 
			endfor 
		endfor 
	endfor

	// 2009-02-09 Don't forget the trailing nostore periods which must be cleared/filled with 0 so that the DAC output will be quiet.   TODO_a:   NPROTS
// todo_a:  Check nprots>1
	 printf "\t\t\tUFPE_StoreChunkSet_eb2 .\tFilling trailing nostore period from [ %d * %d + %d = ] %d to nPnts: [ %d * %d  * NPROTS ??? = ] %d   BegTape:%d \r", EndTrueChnkNr, gPntPerChnk, EndTrueChnkOfs, EndTrueChnkNr * gPntPerChnk + EndTrueChnkOfs, nChunks, gPntPerChnk, nPnts, begTape
	string sChunkTimesTrailingNostore	= ""
	sprintf sChunkTimesTrailingNostore, "%d,%d,%d,%d,",  0, EndTrueChnkNr * gPntPerChnk + EndTrueChnkOfs, gPntPerChnk - EndTrueChnkOfs, BegTape +  EndTrueChnkOfs // prints integers, num2str()  would  print in undesired scientific format 
	llst += sChunkTimesTrailingNostore +";~"
	for ( c = EndTrueChnkNr+1;  c < nChunks; c += 1 )
	 sprintf sChunkTimesTrailingNostore, "%d,%d,%d,%d,",  0, c * gPntPerChnk , gPntPerChnk, BegTape +  EndTrueChnkOfs 		// BegTape will be ignored later because the DAC is filled with 0
		llst += sChunkTimesTrailingNostore +";~"
	endfor


	for ( c = 0; c < ItemsInList( llst, "~" ); c += 1 )
		// printf "\t\t\tUFPE_StoreChunkSet_eb2(b)\tc:%d\t%3d\tnChunks:\t%d\tstrlen:%d\t'%s'  \r", c, ItemsInList( llst, "~" ), nChunks, strlen( llst), StringFromList( c, llst, "~" )[0,250]
	endfor
	 printf "\t\t\tUFPE_StoreChunkSet_eb2 c \tItms:\t%3d\tnChunks:\t%d\tstrlen:%d\t'%s'  \r", ItemsInList( llst, "~" ), nChunks, strlen( llst), llst[0,250]
string /G 	 $"root:uf:" + sFo + ":" + "lllstChunkTimes" 	= llst		// todo_b	  store globally elsewhere

	return	llst
End


Function	/S	PreConv( bStoreIt, ppChk, TrueChunk, BegTrueOfs, pts, BegTape )
	variable	bStoreIt, ppChk, TrueChunk, BegTrueOfs, pts
	variable	BegTape   	// if a chunk has split a store section the 'BegTape' of the second section section (=begin of new chunk)  already includes the points already processed in the previous section (=the end of the previoud chunk) 
	string  	sChunkTimes	= ""
	sprintf sChunkTimes, "%d,%d,%d,%d,",  bStoreIt, TrueChunk * ppChk + BegTrueOfs, pts,  BegTape 	// prints integers, num2str()  would  print in undesired scientific format 
	return	sChunkTimes
End



static Function		UFPE_StoreChunkSet_ns( sFo, llstBLF, lstTotdur, lllstTapeTimes, sSubFo, wG )												// after SetPoints : needs nPnts and gPntPerChnk
// Builds  boolean wave containing the information if a given chunk must be stored .  
//  Chunks that need not be stored are not transfered between Host and Ced: Advantages : 1. Script load time is reduced   2. Higher acq data rates are possible
//  To keep the program simple only complete chunks are handled: only when the whole chunk is blank it will not be transfered. If there is just 1 point to be stored the whole chunk is transfered.
//  This behaviour could (at the expense of a rather large proramming effort) be improved by splitting chunks into Store=Transfer/NoStore=NoTransfer regions..(finer granularity). 
	string  	sFo, llstBLF, lstTotdur, lllstTapeTimes, sSubFo
	wave	wG
	variable	nProts		= UFPE_Prots( sFo )
	variable	nPnts		= wG[ UFPE_WG_PNTS ] 
	variable	nSmpInt		= wG[ UFPE_WG_SI ] 
	nvar		gPntPerChnk	= $"root:uf:acq:" + sSubFo + ":gPntPerChnk" 
	variable	c, nChunks	= nProts * nPnts / gPntPerChnk
	variable	sc			= 0		// todo_c
	variable	pr=0, gr=0, sw=0			// todo_b
		
	// Construct the boolean wave containing the information if a given chunk must be stored. Assume initially that it has not to be stored.
	make	/O    /B	/N=( nChunks )	$"root:uf:" + sFo + ":store:wStoreChunkOrNot"	= UFCom_FALSE	// Assume initially that no chunk has to be stored, correct this assumption below
	wave	wStoreChunkOrNot 	= 	$"root:uf:" + sFo + ":store:wStoreChunkOrNot"

	// Correct the above assumption if the conditions are met that a given chunk must be stored
	variable	fr, nFrm, la, nLap, bl, nBlk	= UFPE_Blocks( llstBLF )
	variable	tp, nTap1Blk,  tpBeg = 0,   tpEnd = 0, tpPts = 0, tpBegChnk = 0, tpEndChnk = 0, tpTotalPts = 0
	
	for ( bl = 0; bl < nBlk; bl += 1 )
		nLap		= UFPE_Laps(	 llstBLF, bl )
		nFrm		= UFPE_Frames( llstBLF, bl )	
		nTap1Blk	= UFPE_TapeCount( sFo, bl, lllstTapeTimes )				// e.g.  '0,600,0;1000,600,0;~0,2500,0;~' - ->	2		  1		
		for ( la = 0; la < nLap; la += 1 )
			for ( fr = 0; fr < nFrm; fr += 1 )
				for ( tp = 0; tp < nTap1Blk; tp += 1 )
					tpBeg	= UFPE_TapeTpBegPA( sFo, sc, pr, bl, la, fr, gr, sw, tp, nSmpInt, lllstTapeTimes, llstBLF, lstTotdur )
					tpEnd	= UFPE_TapeTpEndPA( sFo, sc, pr, bl, la, fr, gr, sw, tp, nSmpInt, lllstTapeTimes, llstBLF, lstTotdur )
					tpPts		= UFPE_TapeTpPtsPA( sFo,  bl, tp, nSmpInt, lllstTapeTimes )
					tpTotalPts += tpPts
					tpBegChnk= trunc(  tpBeg 		/ gPntPerChnk )			// indexing is such that the usual loop construct can be used...	
					tpEndChnk= trunc( (tpEnd - 1)	/ gPntPerChnk ) + 1		// e.g. from tpBegChnk  to < tpEndChnk     or   from tpEndChnk    to  < tpBegChnk
					// printf "\t\t\tUFPE_StoreChunkSet_ns   \tpr:%2d\tbl:%2d\tla:%2d\tfr:%2d\tgr:%2d\tsw:%2d  \tgPntPerChk: %d\tTapeBeg:\t%8d\tPts:\t%8d\tEnd:\t%8d\ttpBegChnk:\t%8d\tEnd:\t%8d   \r", pr, bl, la, fr, gr, sw, gPntPerChnk, TpBeg, TpPts, TpEnd, tpBegChnk, tpEndChnk
					for ( c = tpBegChnk; c < tpEndChnk; c += 1 )
						wStoreChunkOrNot[ c ] = UFCom_TRUE
					endfor 
				endfor 
			endfor 
		endfor 
	endfor
	variable	nStored	= 0
	for ( c = 0; c < nChunks; c += 1 )
		nStored	+=  wStoreChunkOrNot[ c ] 
		// printf "\t\t\tUFPE_StoreChunkSet_ns    \tChunk:\t%6d /%8d\tbStoreIt:%2d\t\tnStored:%6d \t ~ %d %% \r", c , nChunks, wStoreChunkOrNot[ c ], nStored , nStored * 100 / ( c + 1 )
	endfor 
	 printf "\t\tUFPE_StoreChunkSet_ns     	nProts: %d  nPnts: %d  gPntPerChk: %d  -> nChunks: %d  \t\tnStored:%6d \t ~ %d %%    [TapeTotalPts: %d  ~ %d %% ]\r", nProts, nPnts, gPntPerChnk, nChunks, nStored , nStored * 100 / nChunks, tpTotalPts, tpTotalPts * 100 / nPnts
End


static Function		UFPE_StoreChunkorNot_ns( sFo, nChunk )				
	string  	sFo
	variable	nChunk
	wave	wStoreChunkOrNot = $"root:uf:" + sFo + ":store:wStoreChunkOrNot"
	return	wStoreChunkOrNot[ nChunk ]
End
	

//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Script memory splitting and script load timing: store information in table  'ksTBL_ACQ'  ,  display and append information to table 
// also used in CedAcq 
// strconstant 	klstACQTIME_TBLTITLES0	= "Script=%s\tRps=%3d\tCkpR=%4d\t PtpCk=%5d\tDA=%d\tAD=%d\tTG=%d\tSI/us=%4d\tCmpr=%3d\tReact=%.1lf\tTA%%=%2d\tMem%%=%2d\tFoM=%4.1lf\tMb1Ch=%6.2lf\tMbAll=%6.2lf\t"		// !!! sprintf sTxt  in  CEDInitializeDacBuffers()  relies on this order
// strconstant 	klstACQTIME_TBLTITLES1	= "Kpts=%8d\tEB=%1d\tTime=%s\tLoad/ms=%6d\tOverall=%6d\tDigOut=%5d\tCedInit=%5d\tDisplay=%5d\t"													// !!! sprintf sTxt  in  CEDInitializeDacBuffers()  relies on this order


static strconstant 	klstACQTIME_TBLTITLES		= "Script;Rps;CkpR; PtpCk;DA;AD;TG;SI/us;Cmpr;React;TA%%;Mem%%;FoM;Mb1Ch;MbAll;EB;Kpts;KpStore;Dur/s;Time;Load/ms;Overall;DigOut;CedInit;Display;"	// !!! sprintf sTxt  in  CEDInitializeDacBuffers()  relies on this order
static strconstant 	klstACQTIME_TBLFORMAT	= "%s;    %3d;  %4d;   %5d;  %d;%d;%d; %4d;  %3d;  %.1lf;  %2d;    %2d;   %4.1lf;%6.2lf;%6.2lf; %d; %8d;  %8d;   %5d;   %s;   %6d;       %6d;     %5d;    %5d;    %5d;"

Function	/S 	AcqTblWvNm( sFo, sTbl )
	string  	sFo, sTbl
	return	UFCom_ksROOT_UF_ + sFo + ":" + sTbl
End

Function	/S 	 AcqTblFormat()
	string  	lstTitles	 = klstACQTIME_TBLTITLES
	string  	lstFormat	 = klstACQTIME_TBLFORMAT
	variable	nt, nTitles	 = ItemsInList( lstTitles )
	variable	nf, nFormat = ItemsInList( lstFormat )
	string  	sFormat	 = ""
	if ( nTitles != nFormat )
		printf "****Internal error [AcqTblFormat] : '%s' has %d items, '%s' has %d items.\r",  lstTitles, nTitles, lstFormat, nFormat
	endif
	for ( nt = 0; nt < nTitles; nt += 1 )
		sFormat += StringFromList( nt, lstTitles ) + "=" + UFCom_RemoveWhiteSpace( StringFromList( nt, lstFormat ) ) + "\t"		// e.g.  'Script=%s\tRps=%3d\t...'
	endfor
	return	sFormat
End

Function		AcqTblSetCell( sFo, sTbl, sValue, sKey )
	string  	sFo, sTbl, sValue, sKey	
	string  	sTbWvNm	 = AcqTblWvNm( sFo, sTbl )
	string  	lstTitles	 = klstACQTIME_TBLTITLES
	UFCom_MyTableSetCell( sFo, sTbWvNm, sTbl, sValue, sKey, lstTitles )
End		

static  Function		AcqTblBuild( sFo, sTbl, sTitle, bDisplay, RowOfs, sTxt, sKeySep, sListSep, sfHook )
	string  	sFo, sTbl	
	string  	sTitle	
	variable	bDisplay	
	variable	RowOfs							// 0 : into last row , 1: create new row
	string  	sTxt
	string  	sKeySep							// usually '='
	string  	sListSep							// usually '\t'
	string  	sfHook							// function name	
	string  	sSubFoIni  = "FPuls",   sKey = "Wnd"
	variable	bXYinPercent_NotPoints	= 0			//  0  if x and y are in points which is preferable if the window location is stored in an INI file (first used for 'tbAcq')  ,  1 if x and y are in percents of screen (old-esatblished behaviour)
	string  	sTbWvNm = AcqTblWvNm( sFo, sTbl )	
	UFCom_MyTable_( sFo, sTbWvNm, sTbl, sTitle, bDisplay, RowOfs, sTxt, sKeySep, sListSep, sfHook, sSubFoIni,  sKey, bXYinPercent_NotPoints)
End

//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



static	Function		CEDInitializeDacBuffers( sFo, sSubFoC, sc, lllstIO, wRaw, wG, hnd )
	// Acquisition mode initialization with Timer and swinging buffer 
	// Although the following variables are declared GLOBAL they should be used like STATIC (only  within this procedure file) !
	// Global as they must be accessed in MyBkgTask()  and  as their access should be fast..(how slow/fast are access functions?) 
	string  	sFo, sSubFoC, lllstIO
	variable	sc, hnd
	wave	wRaw, wG
	nvar		gnReps			= $"root:uf:" + sFo + ":" + sSubFoC + ":gnReps"
	nvar		gChnkPerRep		= $"root:uf:" + sFo + ":" + sSubFoC + ":gChnkPerRep"
	nvar		gPntPerChnk		= $"root:uf:" + sFo + ":" + sSubFoC + ":gPntPerChnk"
	nvar		gnCompressTG		= $"root:uf:" + sFo + ":" + sSubFoC + ":gnCompressTG"
	nvar		gMaxSmpPtspChan	= $"root:uf:" + sFo + ":" + sSubFoC + ":gMaxSmpPtspChan"
	variable	nSmpInt			= wG[ UFPE_WG_SI ]	
	variable	nCntDA			= wG[ UFPE_WG_CNTDA ]	
	variable	nCntAD			= wG[ UFPE_WG_CNTAD ]	
	variable	nCntTG			= wG[ UFPE_WG_CNTTG ]	
	variable	nPnts			= wG[ UFPE_WG_PNTS ] 
	nvar		gnOfsDA			= $"root:uf:" + sFo + ":" + sSubFoC + ":gnOfsDA"
	nvar		gSmpArOfsDA		= $"root:uf:" + sFo + ":" + sSubFoC + ":gSmpArOfsDA"
	nvar		gnOfsAD			= $"root:uf:" + sFo + ":" + sSubFoC + ":gnOfsAD"
	nvar		gSmpArOfsAD		= $"root:uf:" + sFo + ":" + sSubFoC + ":gSmpArOfsAD"
	nvar		gnOfsDO			= $"root:uf:" + sFo + ":" + sSubFoC + ":gnOfsDO"
	variable	SmpArStartByte,  TfHoArStartByte,  nPts,  	nChunk, code = 0
	string		bf , buf, buf1

	variable	TAused		= TAuse( gPntPerChnk, nCntDA, nCntAD, cMAX_TAREA_PTS ) 
	variable	MemUsed		= MemUse(  gChnkPerRep, gPntPerChnk, gMaxSmpPtspChan )
	variable	FoM			= FigureOfMerit( gChnkPerRep, gPntPerChnk, gMaxSmpPtspChan, nCntDA, nCntAD, nCntTG, gnCompressTG, cMAX_TAREA_PTS ) 
	variable	ChunkTimeSec	= gPntPerChnk * nSmpInt /  1000000
	variable	SysMB1Chan	= gnReps * gChnkPerRep * gPntPerChnk * 4 / 1024 / 1024
	variable	SysMBAllChan	= SysMB1Chan * ( nCntDA + nCntAD + nCntTG / gnCompressTG )
	variable	nTapePts 		= wG[ UFPE_WG_PNTS ] 

	nvar		gbRunning	= $"root:uf:acq:" + UFPE_ksKEEP + ":gbRunning"
	nvar		gbAcquiring	= $"root:uf:" + sFo + ":" + sSubFoC + ":gbAcquiring"

	// 2008-07-25 Fill
	variable	LoadMs	= -2
	variable	OverallMs	= -3
	variable	DigoutMs	= trunc( UFCom_ReadTimer_( sFo, "DigOut" )/1000 )
	variable	DisplayMs	= trunc( UFCom_ReadTimer_( sFo, "Display" )/1000 )
	variable	CedInitMs	= -4
	string  	sTxt 			= ""
	string  	sFormatString	= AcqTblFormat()	
	sprintf sTxt, sFormatString,  UFCom_pd(ScriptPath(sFo),60), gnReps, gChnkPerRep, gPntPerChnk, nCntDA, nCntAD, nCntTG, nSmpInt,  gnCompressTG, ChunkTimeSec, TAUsed, MemUsed, FoM, SysMB1Chan, SysMBAllChan, ELIMINATE_BLANKS(), nPnts/1000, nTapePts/1000, nPnts*nSmpInt/1000000, Time(), LoadMs, OverallMs, DigoutMs, CedInitMs, DisplayMs
	string  	sTitle		= "Acq Ced"
	variable	bDisplay	= 1
	variable	RowOfs	= 1		// 0 : into last row , 1: create new row
	AcqTblBuild( sFo, ksTBL_ACQ, sTitle, bDisplay, RowOfs, sTxt, "=", "\t", "fHookAcqTiming" )
// 2009-10-29
	UFCom_LstPanelsAdd( ksACQ, ksfACQVARS, ksTBL_ACQ )	

	// printf "\t\tCed CedStartAcq     CEDInitializeDacBuffers() \tRunning:%2g  Acquiring:%2d \r", gbRunning, gbAcquiring
	 printf "\t\t\tCed CedStartAcq    Rps:%d  ChkpRep:%d  PtpChk:%d  DA:%d  AD:%d  TG:%d  SmpInt:%3dus  Cmpr:%d  ReactTm:%.1lfs  TA:%d%%  Mem:%d%%  FoM:%.1lf%%  [%5.1lf /%5.1lf MB ]  OsDA:%d  OsAD:%d  OsDO:%d \r", gnReps, gChnkPerRep, gPntPerChnk, nCntDA, nCntAD, nCntTG, nSmpInt,  gnCompressTG, ChunkTimeSec, TAUsed, MemUsed, FoM, SysMB1Chan, SysMBAllChan, gnOfsDA, gnOfsAD, gnOfsDO 
	// printf "\t\t\t\tCed Cnv>DA14>Cpy\t  IgorWave \t>HoSB \t=HoSB \t>TASB \t>SASB \t DAPnts\r"

	for ( nChunk = 0; nChunk < gChnkPerRep; nChunk += 1)		

 		ConvolveBuffersDA_ns( sFo, sc, lllstIO, nChunk, 0, gnReps, gChnkPerRep, nCntDA, gPntPerChnk, wRaw, gnOfsDA/2, nPnts )	//  mixes points of all  separate DAC-channel stimulus waves  together in small transfer area wave ' wRaw' .  

		if ( CEDHandleIsOpen_ns() ) 

			nPts   			= gPntPerChnk * nCntDA 
		 	TfHoArStartByte		= gnOfsDA	   + 2 * nPts * mod( nChunk, 2 )		//  only  2 swaps
			SmpArStartByte		= gSmpArOfsDA   + 2 * nPts * nChunk 
		
			if (   ELIMINATE_BLANKS() == 1 )								
				variable	begPt	= gPntPerChnk * nChunk					// BegPt and EndPt are points in the CED sampling area (typ. 16MB) ....
				variable	endPt	= gPntPerChnk * ( nChunk + 1 )				// The same BegPt and EndPt are passed multiple times if nReps is >1 (=long scripts and/or many protocols)
				variable	repOs	= 0									// BegPt and EndPt  PLUS the repetition offset 'repOs' gives the true point number in the DAC wave independently from the CED sampling area size
				variable	bStoreIt	= UFPE_StoreChunkorNot_ns( sFo, nChunk )				
				variable	BlankAmp	= wRaw[ TfHoArStartByte / 2  ]				// use the first value of this chunk as amplitude for the whole chunk
				printf "\t\tAcqDA TfHoA1\t%8d\t ->\tSmpAr:\t %11d \t(pts:%8d)  \tBg:\t%7d\tNd:\t%7d\tChnk:\t%8d\tStoring:%2d\tAmp:\t%7d\t   \r", TfHoArStartByte, SmpArStartByte, nPts, BegPt+repOs, EndPt+repOs, nChunk, bStoreIt, BlankAmp
				if (	bStoreIt )
					 sprintf buf, "TO1401,%d,%d,%d;", TfHoArStartByte, 2*nPts, TfHoArStartByte ;  UFP_CedSendString( hnd, buf )	// copy  Dac data from host to Ced transferArea. Ced TransferArea and HostArea start at the same point
					 code	+= GetAndInterpretAcqErrors( hnd, "SmpStart", "TO1401", nChunk, gnReps * gChnkPerRep )
				else
					 sprintf buf, "SS2,C,%d,%d,%d;", TfHoArStartByte, 2*nPts, BlankAmp;  UFP_CedSendString( hnd, buf )  			// fill Ced transferArea with constant 'Blank' amplitude. This is MUCH faster than the above 'TO1401' which is very slow
					 code	+= GetAndInterpretAcqErrors( hnd, "SmpStart", "SS2    ", nChunk, gnReps * gChnkPerRep )
				endif
			elseif ( ELIMINATE_BLANKS() == 0 )								
				 sprintf buf, "TO1401,%d,%d,%d;", TfHoArStartByte, 2*nPts, TfHoArStartByte ;  UFP_CedSendString( hnd, buf ) 		 // copy  Dac data from host to Ced transferArea. Ced TransferArea and HostArea start at the same point
				 code	+= GetAndInterpretAcqErrors( hnd, "SmpStart", "TO1401", nChunk, gnReps * gChnkPerRep )
			endif

			 sprintf buf,  "SM2,C,%d,%d,%d;", SmpArStartByte, TfHoArStartByte, 2*nPts;   UFP_CedSendString( hnd, buf )  			 // copy  Dac data from Ced transfer area to large sample area
			 code	+= GetAndInterpretAcqErrors( hnd, "SmpStart", "SM2 Dac", nChunk, gnReps * gChnkPerRep )

		endif
	endfor
	return	code
End


// 2008-07-29 eb2 Tape
static	Function		CEDInitializeDacBuffers_eb2( sFo, sSubFoC, sc, lllstIO, llstBLF, lllstTapeTimes, wRaw, wG, llst, hnd )
	// Acquisition mode initialization with Timer and swinging buffer 
	// Although the following variables are declared GLOBAL they should be used like STATIC (only  within this procedure file) !
	// Global as they must be accessed in MyBkgTask()  and  as their access should be fast..(how slow/fast are access functions?) 
	string  	sFo, sSubFoC, lllstIO, llstBLF, lllstTapeTimes, llst
	variable	sc, hnd
	wave	wRaw, wG
	//wave	wG				= $FoWvNmWgNs( sFo )
	nvar		gnReps			= $"root:uf:" + sFo + ":" + sSubFoC + ":gnReps"
	nvar		gChnkPerRep		= $"root:uf:" + sFo + ":" + sSubFoC + ":gChnkPerRep"
	nvar		gPntPerChnk		= $"root:uf:" + sFo + ":" + sSubFoC + ":gPntPerChnk"
	nvar		gnCompressTG		= $"root:uf:" + sFo + ":" + sSubFoC + ":gnCompressTG"
	nvar		gMaxSmpPtspChan	= $"root:uf:" + sFo + ":" + sSubFoC + ":gMaxSmpPtspChan"
	variable	nSmpInt			= wG[ UFPE_WG_SI ]	
	variable	nCntDA			= wG[ UFPE_WG_CNTDA ]	
	variable	nCntAD			= wG[ UFPE_WG_CNTAD ]	
	variable	nCntTG			= wG[ UFPE_WG_CNTTG ]	
	variable	nPnts			= wG[ UFPE_WG_PNTS ] 
	nvar		gnOfsDA			= $"root:uf:" + sFo + ":" + sSubFoC + ":gnOfsDA"
	nvar		gSmpArOfsDA		= $"root:uf:" + sFo + ":" + sSubFoC + ":gSmpArOfsDA"
//	nvar		gnOfsAD			= $"root:uf:" + sFo + ":" + sSubFoC + ":gnOfsAD"
//	nvar		gSmpArOfsAD		= $"root:uf:" + sFo + ":" + sSubFoC + ":gSmpArOfsAD"
//	nvar		gnOfsDO			= $"root:uf:" + sFo + ":" + sSubFoC + ":gnOfsDO"
//	variable	SmpArStartByte,  TfHoArStartByte, nPts
//	string		bf , buf, buf1
//	nvar		gbRunning	= $"root:uf:acq:" + UFPE_ksKEEP + ":gbRunning"
//	nvar		gbAcquiring	= $"root:uf:" + sFo + ":" + sSubFoC + ":gbAcquiring"

	// Compute some memory usage values for  the  Script load statistics table
	variable	TAused		= TAuse( gPntPerChnk, nCntDA, nCntAD, cMAX_TAREA_PTS ) 
	variable	MemUsed		= MemUse(  gChnkPerRep, gPntPerChnk, gMaxSmpPtspChan )
	variable	FoM			= FigureOfMerit( gChnkPerRep, gPntPerChnk, gMaxSmpPtspChan, nCntDA, nCntAD, nCntTG, gnCompressTG, cMAX_TAREA_PTS ) 
	variable	ChunkTimeSec	= gPntPerChnk * nSmpInt /  1000000
	variable	SysMB1Chan	= gnReps * gChnkPerRep * gPntPerChnk * 4 / 1024 / 1024
	variable	SysMBAllChan	= SysMB1Chan * ( nCntDA + nCntAD + nCntTG / gnCompressTG )
	variable	nTapePts 		= TotalTapePts( sFo, sc, llstBLF, lllstTapeTimes )						// or store in and retrieve from wG[ TPPTS ]  or  numpnts( wBigIO ).........

	// Update the  Script load statistics table : fill in the last row the memory usage values  and  the measured loading times
	variable	LoadMs	= -22
	variable	OverallMs	= -23
	variable	DigoutMs	= trunc( UFCom_ReadTimer_( sFo, "DigOut" )/1000 )
	variable	DisplayMs	= trunc( UFCom_ReadTimer_( sFo, "Display" )/1000 )
	variable	CedInitMs	= -24
	string  	sTxt = ""
	string  	sFormatString	= AcqTblFormat()	// klstACQTIME_TBLTITLES0 + klstACQTIME_TBLTITLES1
	sprintf sTxt, sFormatString,  UFCom_pd(ScriptPath(sFo),50), gnReps, gChnkPerRep, gPntPerChnk, nCntDA, nCntAD, nCntTG, nSmpInt,  gnCompressTG, ChunkTimeSec, TAUsed, MemUsed, FoM, SysMB1Chan, SysMBAllChan, ELIMINATE_BLANKS(), nPnts/1000, nTapePts/1000, nPnts*nSmpInt/1000000, Time(), LoadMs, OverallMs, DigoutMs, CedInitMs, DisplayMs
	string  	sTitle		= "Acq Ced"
	variable	bDisplay	= 1
	variable	RowOfs	= 1				// 0 : into last row , 1: create new row
	AcqTblBuild( sFo, ksTBL_ACQ, sTitle, bDisplay, RowOfs, sTxt, "=", "\t", "fHookAcqTiming" )
// 2009-10-29
	UFCom_LstPanelsAdd( ksACQ, ksfACQVARS, ksTBL_ACQ )	
//	UFCom_LstPanelsSet( ksACQ, ksfACQVARS,  AddListItem( ksTBL_ACQ, UFCom_LstPanels( ksACQ, ksfACQVARS ) ) )	

	// printf "\t\tCed CedStartAcq     CEDInitializeDacBuffers() \tRunning:%2g  Acquiring:%2d \r", gbRunning, gbAcquiring
	 printf "\t\t\tCed CedStartAcq    Rps:%d  ChkpRep:%d  PtpChk:%d  DA:%d  AD:%d  TG:%d  SmpInt:%3dus  Cmpr:%d  ReactTm:%.1lfs  TA:%d%%  Mem:%d%%  FoM:%.1lf%%  [%5.1lf /%5.1lf MB ]  OsDA:%d  \r", gnReps, gChnkPerRep, gPntPerChnk, nCntDA, nCntAD, nCntTG, nSmpInt,  gnCompressTG, ChunkTimeSec, TAUsed, MemUsed, FoM, SysMB1Chan, SysMBAllChan, gnOfsDA
	 // printf "\t\t\t\tCed Cnv>DA14>Cpy\t  IgorWave \t>HoSB \t=HoSB \t>TASB \t>SASB \t DAPnts\r"

	variable	code = 0, bStoreEpi
	variable	nRep	= 0						// we use only repetion 0 as we are initialising
	variable	nChunk, BegTruePrevNr = 0, BegTruePrevOfs = 0,  BegTrueChnkNr//,  BegTrueChnkOfs,  EndTrueChnkNr,  EndTrueChnkOfs
	variable	EndTrue,     BegTrue,  BegTape,  BPoints						// references are passed back
	string  	sTxtStoreSkip	= ""		
	// printf "\t\tCEDInitializeDacBuffers_eb2 0 \tlllstTapeTimes:   '%s'  \r\t\t\t\t\t\t\t\t\t\t\t'%s' \r",  lllstTapeTimes, llst[0,200]

	for ( nChunk = 0; nChunk < gChnkPerRep; nChunk += 1)		
		string  	sChnkTime, sChunkTimes	= StringFromList( nChunk, llst, "~" )
		variable	ne, nEpis	= ItemsInList( sChunkTimes, ";" )
		for ( ne = 0; ne < nEpis; ne += 1 )
			sChnkTime	= StringFromList( ne, sChunkTimes, ";" )
			bStoreEpi		= str2num( UFCom_StringFromDoubleList( ne, 0, sChunkTimes, ";" , "," ) ) 
			BegTrue		= str2num( UFCom_StringFromDoubleList( ne, 1, sChunkTimes, ";" , "," ) ) 
			BPoints		= str2num( UFCom_StringFromDoubleList( ne, 2, sChunkTimes, ";" , "," ) ) 
			BegTape		= str2num( UFCom_StringFromDoubleList( ne, 3, sChunkTimes, ";" , "," ) ) 
			sTxtStoreSkip	= Selectstring( bStoreEpi, "skip:" , "store:" )
			BegTrueChnkNr		= trunc( BegTrue / gPntPerChnk )
			// printf "\t\tCEDInitializeDacBuffers_eb2 a \tc:%d\t%3d\t%3d\tne:%2d\t/%2d\t%s\tBTr:\t%8d\tPts:\t%8d\tBTp:\t%8d\tchk:%3d\t%s\t \r", nChunk, gChnkPerRep,  ItemsInList( llst, "~" ), ne, nEpis, UFCom_pd( sChnkTime,19), BegTrue, BPoints, BegTape, BegTrueChnkNr, sTxtStoreSkip
			ConvolveBuffersDA_eb2( sFo, sc, lllstIO, 	nChunk, 	nRep, gnReps, gChnkPerRep, nCntDA, gPntPerChnk, wRaw, gnOfsDA/2, nPnts,   BegTrue,  BPoints, gSmpArOfsDA, bStoreEpi, BegTape, hnd )
		endfor
	endfor
	return	code
End

//defined later..
//static strconstant	ksPN_INISUB		= "FPuls"				// The  INI subfolder  below folder 'acq'   and   the  INI file location (here in a subdirectory to FPulse=FPulseMain.ipf)
//static strconstant	ksPN_INIKEY		= "Wnd"				// The  keyword in the INI file (here always 'Wnd' as we are dealing with window positions and visibility)

Function		fHookAcqTiming( s )
// The window hook function detects when the user moves or resizes or hides the table window  and stores these settings in the INI file
	struct	WMWinHookStruct &s
	string  	sIniBasePath	= FunctionPath( ksFP_APP_NAME )	// the Ini file containing the window position will be written in a subdirectory parallel to UF_PulseMain.ipf 
	string  	sSubFo	= "" ,  sControlBase = ""				// only required if there were a corresponding button in the main panel which must adjust its state to the windows state
	UFCom_WndUpdateLocationHook( s, ksACQ, sSubFo, ksPN_INISUB, ksPN_INIKEY, sControlBase, sIniBasePath )
	//UFCom_Wnd_UpdateLocationHook( s, ksACQ, ksPN_INISUB, ksPN_INIKEY, sIniBasePath )
End


//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


Function		fStopBkg( s )
	struct	WMButtonAction &s
	printf "\r\tStopping and killing BackgroundTask V4 \r"
	BackgroundInfo
	if ( v_Flag == 2 )						// bkgtask is defined and running
		CtrlBackGround stop
		KillBackGround 
	elseif ( v_Flag == 1 )					// bkgtask is defined but not running
		KillBackGround 
	endif
	variable /G  root:uf:acq:pul:gbrunning = 0		//			ass  fixed folder = bad code
	variable /G  root:uf:acq:cons:gbacquiring = 0	// 2010-02-08	ass  fixed folder = bad code
End


//static	Function		CedStartAcq()	// 2008-06-06	
static	 Function		CedStartAcq( sSubFoC )
	// Acquisition mode initialization with Timer and swinging buffer 
	// Although the following variables are declared GLOBAL they should be used like STATIC (only  within this procedure file) !
	// Global as they must be accessed in MyBkgTask()  and  as their access should be fast..(how slow/fast are access functions?) 
	string  	sSubFoC	
	string  	sFolders	= ksF_ACQ_PUL		
	string  	sFo		= ksACQ
	wave  	wG		= $FoWvNmWgNs( sFo )
	variable	hnd		= CedHandle() 
	svar		lllstIO			= $"root:uf:" + sFo + ":" + "lllstIO" 	
	svar		lllstIOTG		= $"root:uf:" + sFo + ":" + "lllstIOTG" 	
	svar		lllstTapeTimes	= $"root:uf:" + sFo + ":" + "lllstTapeTimes" 	
	svar		llstBLF		= $"root:uf:" + sFo + ":" + "llstBLF" 	
	svar		lllstPoN		= $"root:uf:" + sFo + ":" + "lllstPoN" 	
	svar		lstTotdur		= $"root:uf:" + sFo + ":" + "lstTotdur" 	
	nvar		gnReps		= $"root:uf:" + sFo + ":" + sSubFoC + ":gnReps"
	nvar		gnRep		= $"root:uf:" + sFo + ":" + sSubFoC + ":gnRep"
	nvar		gChnkPerRep	= $"root:uf:" + sFo + ":" + sSubFoC + ":gChnkPerRep"
	nvar		gPntPerChnk	= $"root:uf:" + sFo + ":" + sSubFoC + ":gPntPerChnk"
	nvar		gnChunk		= $"root:uf:" + sFo + ":" + sSubFoC + ":gnChunk"
	nvar		gnLastDacPos	= $"root:uf:" + sFo + ":" + sSubFoC + ":gnLastDacPos"
	nvar		gnAddIdx		= $"root:uf:" + sFo + ":" + sSubFoC + ":gnAddIdx"
	nvar		gReserve		= $"root:uf:" + sFo + ":" + sSubFoC + ":gReserve"
	nvar		gMinReserve	= $"root:uf:" + sFo + ":" + sSubFoC + ":gMinReserve"
	nvar		gErrCnt		= $"root:uf:" + sFo + ":" + sSubFoC + ":gErrCnt"
	nvar		gbAcquiring	= $"root:uf:" + sFo + ":" + sSubFoC + ":gbAcquiring"	
	nvar		gbRunning	= $"root:uf:acq:" + UFPE_ksKEEP + ":gbRunning"
	nvar		gnTicksStart	= $"root:uf:acq:" + UFPE_ksKEEP + ":gnTicksStart"

	nvar		gBkPeriodTimer	= $"root:uf:" + sFo + ":" + sSubFoC + ":gBkPeriodTimer"
	nvar		gPrevBlk		= root:uf:acq:pul:svPrevBlk0000
	nvar		gnOfsDA		= $"root:uf:" + sFo + ":" + sSubFoC + ":gnOfsDA",	gSmpArOfsDA	= $"root:uf:" + sFo + ":" + sSubFoC + ":gSmpArOfsDA"
	nvar		gnOfsAD		= $"root:uf:" + sFo + ":" + sSubFoC + ":gnOfsAD",	gSmpArOfsAD	= $"root:uf:" + sFo + ":" + sSubFoC + ":gSmpArOfsAD"	
	variable	nSmpInt		= wG[ UFPE_WG_SI ]
	variable	nCntDA		= wG[ UFPE_WG_CNTDA ]	
	variable	nCntAD		= wG[ UFPE_WG_CNTAD ]	
	variable	nCntTG		= wG[ UFPE_WG_CNTTG ]	
	nvar		gnOfsDO		= $"root:uf:" + sFo + ":" + sSubFoC + ":gnOfsDO"

	variable	bTrigMode		= TrigMode()
	string		bf

	if ( ArmDAC_ns( sFo, lllstIO, gSmpArOfsDA, gPntPerChnk * nCntDA * gChnkPerRep, gnReps, hnd ) == UFCom_kERROR )
		return	UFCom_kERROR						//  Avoid  the user ignoring this error and continuing . This error happens very rarely and is not understood...
	endif
	if ( ArmADC( sFo, lllstIO, gSmpArOfsAD, gPntPerChnk * (nCntAD+nCntTG) * gChnkPerRep, gnReps, hnd ) == UFCom_kERROR ) 
		return	UFCom_kERROR						//  Avoid  the user ignoring this error and continuing . This error happens very rarely and is not understood...
	endif
	if ( ArmDig( sFo, gnOfsDO, hnd ) == UFCom_kERROR )
		return	UFCom_kERROR						//  Avoid  the user ignoring this error and continuing . This error happens very rarely and is not understood...
	endif	

	UFCom_ResetTimer( sFo, "Convolve" )
	UFCom_ResetTimer( sFo, "Transfer" )		
	UFCom_ResetTimer( sFo, "Graphics" )		
	UFCom_ResetTimer( sFo, "OnlineAn" )		
	UFCom_ResetTimer( sFo, "CFSWrite" )		
	UFCom_ResetTimer( sFo, "Process" )		
	UFCom_ResetTimer( sFo, "TotalADDA" )		

	// Establish a dependency so that the current acquisition status (waiting for 'Start' to be pressed, waiting for trigger on E3E4, acquiring, finished acquisition) is reflected in a ColorTextField
SetFormula	$"root:uf:"+sFo+":pul:gnAcqStatus0000", "root:uf:acq:" + UFPE_ksKEEP + ":gbRunning + 2 * root:uf:" + sFo + ":" + sSubFoC + ":gbAcquiring"	
	
	gbRunning	= UFCom_TRUE 								// 2003-1030
	StartStopFinishButtonTitles( sFo, sSubFoC )						// 2003-1030 reflect change of 'gbRunning'  (ugly here...button text should change automatically) 

	//  Never allow to go into 'LoadScriptxx()' when acquisition is running, because 'LoadSc..' initializes the program: especially waves and transfer area
	UFCom_EnableButton( "pul", "root_uf_acq_pul_ApplyScript0000",	UFCom_kCo_DISABLE )	//  Never allow to go into 'LoadScriptxx()' when acquisition is running..
	UFCom_EnableButton( "pul", "root_uf_acq_pul_LoadScript0000",	UFCom_kCo_DISABLE )	//  ..because 'LoadSc..' initializes the program: especially waves and transfer area
	UFCom_EnableSetVar( "pul", "root_uf_acq_pul_gnProts0000",		UFCom_kCo_NOEDIT_SV  )	// ..we cannot change the number of protocols as this would trigger 'ApplyScript()'
	UFCom_EnableButton( "pul", "root_uf_acq_pul_buDelete0000",	UFCom_kCo_DISABLE )	// 2005-05-30 Never allow deletion of the file which is currently written

	//StartStopFinishButtonTitles( sFo )					// ugly here...button text should change automatically 050207weg

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

	Process_ns( sFolders, sFo, -1, lllstIO,  lllstIOTG,  wG, lllstTapeTimes, llstBLF, lllstPoN, lstTotdur )			//  PULSE  specific: for initialization of CFS writing

	UFCom_StartTimer( sFo, "TotalADDA" )		

	gBkPeriodTimer 	= 	startMSTimer
	if ( gBkPeriodTimer 	== -1 )
		printf "*****************All timers are in use 5...\r" 
	endif

	// Interrupting longer  than 'MaxBkTime' leads to data loss
	//variable	SetTimerMilliSec = ( gPntPerChnk * nSmpInt ) / 1000 
	// printf "\t\tCed CedStartAcq    SmpInt:%d  SetTimerMilliSec:%d   TimerTicks:%d  TimerTicks(period):%d   MaxBkTime:%6dms  Reps:%d \r", nSmpInt, SetTimerMilliSec, SetTimerMilliSec/1000*60, nTICKS, SetTimerMilliSec * ( gChnkPerRep - 1 ),  gnReps 

	// PrintBackGroundInfo( "CedStartAcq(5)   V4" , "")



// Old code from version 223 (03 Oct) : E3E4 triggering working !!!  To be deleted again !
//
//	BackGroundInfo	// 2003-1025
//	// printf "\t\t\tBackGroundInfo   '%s'  , v_Flag:%d :  is  %s ,  next scheduled execution:%d  \r ", s_Value, v_Flag, SelectString( v_Flag-1, "not defined", "defined but not running (idle)", "running" ), v_NextRun 
//	if ( v_Flag != 1)		// 2003-1025   for  the hardware triggered E3E4 mode : We call this function from the BackGround task function ( StopADDA() -> buStart() -> 'StartStimulusAndAcquisition'  ->  'CedStartAcq'  ... 
//		// printf "\t\t\tBackGroundInfo   '%s'  , v_Flag:%d :  is  %s ,  next scheduled execution:%d  \r ", s_Value, v_Flag, SelectString( v_Flag-1, "not defined", "defined but not running (idle)", "running" ), v_NextRun 
//		SetBackground MyBackgroundTask()		// ...but it is not allowed (and we must avoid) to change a BackGround task function from within a BackGround task function 
//	endif
//
//	// Interrupting longer  than 'MaxBkTime' leads to data loss
//	//printf "\t\tAcq CedStartAcq    SmpInt:%d  SetTimerMilliSec:%d   TimerTicks:%d  TimerTicks(period):%d   MaxBkTime:%6dms  Reps:%d \r", SmpInt, SetTimerMilliSec, SetTimerMilliSec/1000*60, nBkgTicks,SetTimerMilliSec * ( ChunkspRep - 1 ),  nReps
//	sprintf bf, "\t\tAcq CedStartAcq    SmpInt:%d  SetTimerMilliSec:%d   TimerTicks:%d  TimerTicks(period):%d   MaxBkTime:%6dms  Reps:%d \r", gnSmpInt, SetTimerMilliSec, SetTimerMilliSec/1000*60, nBkgTicks,SetTimerMilliSec * ( gChnkPerRep - 1 ),  gnReps 
//	Out( bf )
//
//	if ( gRadTrigMode == 0 ) 	// normal SW triggered mode
//		IMWArmClockStart( gnSmpInt, 1 )
//	endif
//
//	if ( radDEBPSel > 2  &&  PnDebgAcq )
//		printf  "\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\tAcq Cpy>ADHo>Cnv  \t ADPnts\t  SASB\t\t>TASb \t>HoSB \t   =HoSB \t IgorWave \t\t\t[+ch1,+ch2...] \r"
//	endif
//	nBkgTicks= nTICKS //? test
//	CtrlBackground start ,  period = nBkgTicks, noBurst=0//1 //? nB0=try to catch up, nB1=don't catch up
//
//	return 0	// todo: could also but does not return error code



// 2010-02-09c	NEW:  we must KILL bkgtask  (from the other application V4)  before we start this bkgtask
	if ( bTrigMode == 0 )	// in the HW-triggered E3E4 mode the background task is automatically restarted after the script has finished (running quasi-continuously)  [is this really required???]  so we are HERE iwithin the bkg function: we are not allowed to KILL it 
		KillBackground
	endif

	BackGroundInfo	
	if ( v_Flag == cBKG_UNDEFINED )			// 031025   for  the hardware triggered E3E4 mode : We call this function from the BackGround task function ( StopADDA_ ->  'StartStimulusAndAcquisition'  ->  'CedStartAcq'  ... 
		 printf "\t\t\tBackGroundInfo V4  '%s'  , v_Flag:%d :  is  %s ,  next scheduled execution:%d  \r ", s_Value, v_Flag, SelectString( v_Flag-1, "not defined", "defined but not running (idle)", "running" ), v_NextRun 
		SetBackground	  MyBkgTask()			// ...but it is not allowed to change a BackGround task function from within a BackGround task function 
		CtrlBackground	  start ,  period = nTicks, noBurst=1//0 //? nB0=try to catch up, nB1=don't catch up
		 printf "\t\t\tCedStartAcq 5a  V4\t\t\tBkg task: set and start \r "
	elseif ( v_Flag == cBKG_IDLING )			// 031025   for  the hardware triggered E3E4 mode : We call this function from the BackGround task function ( StopADDA_ ->  'StartStimulusAndAcquisition'  ->  'CedStartAcq'  ... 
		CtrlBackground	  start ,  period = nTicks, noBurst=1//0 //? nB0=try to catch up, nB1=don't catch up
		 printf "\t\t\tCedStartAcq 5b  V4\t\t\tBkg task: start \r "
	endif

// 2010-02-09c	weg
//	BackGroundInfo	
//	if ( v_Flag == cBKG_UNDEFINED )		// 2003-1025   for  the hardware triggered E3E4 mode : We call this function from the BackGround task function ( StopADDA() -> buStartAcq() -> 'StartStimulusAndAcquisition'  ->  'CedStartAcq'  ... 
//		 printf "\t\t\tBackGroundInfo V4 '%s'  , v_Flag:%d :  is  %s ,  next scheduled execution:%d  \r ", s_Value, v_Flag, SelectString( v_Flag-1, "not defined", "defined but not running (idle)", "running" ), v_NextRun 
//		SetBackground	  MyBkgTask()		// ...but it is not allowed (and we must avoid) to change a BackGround task function from within a BackGround task function 
//		CtrlBackground	  start ,  period = nTicks, noBurst=1//0//1 //? nB0=try to catch up, nB1=don't catch up
//		 printf "\t\t\tCedStartAcq(5a) V4\t\t\tBkg task: set and start \r "
//	endif
//	
//	if ( v_Flag == cBKG_IDLING )		// 2003-1025   for  the hardware triggered E3E4 mode : We call this function from the BackGround task function ( StopADDA() -> buStartAcq() -> 'StartStimulusAndAcquisition'  ->  'CedStartAcq'  ... 
//		CtrlBackground	  start ,  period = nTicks, noBurst=1//0//1 //? nB0=try to catch up, nB1=don't catch up
//		  printf "\t\t\tCedStartAcq(5b) V4\t\t\tBkg task: start \r "
//	endif


	if ( ArmClockStart( nSmpInt, bTrigMode, hnd ) )	
		printf "ERROR in ArmClockStart   \r"
//		return	UFCom_kERROR						//  Avoid  the user ignoring this error and continuing . This error happens very rarely and is not understood...
	endif	

//	if ( UFCom_DebugDepthSel() > 2  &&  UFCom_DebugVar( 0, "acq", "AcqDA" ) )
//		printf  "\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\tAcqDA Cpy>ADHo>Cnv  \t ADPnts\t  SASB\t\t>TASb \t>HoSB \t   =HoSB \t IgorWave \t\t\t[+ch1,+ch2...] \r"
//	endif

	return 0	// todo: could also but does not return error code
End



// Old code from version 223 (03 Oct) : E3E4 triggering working !!!  To be deleted again !
//
//Function  IMWArmClockStart( SmpInt, nrep )
//	variable	SmpInt, nrep 
//	string		buf , bf
//	variable	code
//
//	nvar		gnPre	= root:cont:gnPre
//	if (  CEDHandleIsOpen_ns() )
//		// divide 1MHz clock by two factors to get basic clock period in us, set clock (with same clock rate as DAC and ADC)
//		// start DigOut, DAC and  ADC 
//		sprintf buf, "DIGTIM,C,%d,%d,%d;", gnPre, trunc( SmpInt / gnPre ), nrep
//		sprintf  bf,  "\t\tAcq IMWArmClockStart sends  '%s'  \r", buf; Out( bf )
//		code = UFP_CedSendStringErrOut( UFPE_ERRLINE+ERR_FROM_CED, buf )
//
//	endif
//	return 0;
//End



static	Function		PrintBackGroundInfo( sText1, sText2 )
	string		sText1, sText2
	BackGroundInfo	
	printf "\t\t\t%s\tBkgInfo V4 %s\t\t%s \tPeriod:%3d \tnext scheduled execution:%d  \tv_Flag:%d :  is  %s \tCedHnd:%d \r ", UFCom_pad( sText1, 17),  UFCom_pad( sText2, 10 ), UFCom_pd(s_Value,12), v_Period,  v_NextRun , v_Flag, SelectString( v_Flag-1, "not defined", "defined but not running (idle)", "running" ), CedHandle()
End

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function		MyBkgTask()
// CONT mode routine with swinging buffer.  If   AddaSwing  returns nCode =  kERROR (-1)    then  MyBkgTask_()   will return  1   and   will stop .   Warnings (e.g. Telegraph out of range) will return nCode = 1 and will NOT stop the BkgTask
	// print "050128 Entering BKG task, swinging..."
	variable	nCode = ADDASwing_ns()
	// print "050128 Leaving BKG task (0: keep running=wait , !=0 kill BKG task. Leaving with: ", nCode , "=?=" , UFCom_kERROR , " ->", nCode == UFCom_kERROR	
	return	nCode == UFCom_kERROR			//  return 0 (=cADDAWAIT) if CED was not yet ready to keep the background task running, return !=0 to kill background task
End


static  Function	ClipCompressFactor( nAD, nTG,  PtpChk )
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
	if ( UFCom_DebugVar( "acq", "Ced" ) & 4 )
		printf "\t\t\t\tCed SetPoints ClipCompressFactor( nAD:%d ,  nTG:%d ,  PtpChk:%d  )  desired TG compression:%d   computed TG compression:%d \r", nAD, nTG,  PtpChk , cFAST_TG_COMPRESS,  nCompression
	endif
	return	nCompression 
End


 Function		ADDASwing_ns()
	string  	sFolders	= ksF_ACQ_PUL		
	string  	sFo		= ksACQ
	string  	sSubFoC	= UFPE_ksCOns
	string  	sSubFoW	= UFPE_ksKPwgns
	variable	sc		= 0				// todo
	wave  	wG		= $FoWvNmWgNs( sFo )
	wave 	wRaw	= $"root:uf:" + sFo + ":" + UFPE_ksKEEPwr + ":wRaw"// This  'wRaw' 	is valid in FPulse ( Acquisition )
	svar		lllstIO			= $"root:uf:" + sFo + ":" + "lllstIO" 	
	svar		lllstIOTG		= $"root:uf:" + sFo + ":" + "lllstIOTG" 	
	svar		lllstTapeTimes	= $"root:uf:" + sFo + ":" + "lllstTapeTimes" 	
	svar		llstBLF		= $"root:uf:" + sFo + ":" + "llstBLF" 	
	svar		lllstPoN		= $"root:uf:" + sFo + ":" + "lllstPoN" 	
	svar		lstTotdur		= $"root:uf:" + sFo + ":" + "lstTotdur" 	
	svar		lllstChunkTimes	= $"root:uf:" + sFo + ":" + "lllstChunkTimes" 	
	variable	nProts		= UFPE_Prots( sFo )
	nvar		gnReps		= $"root:uf:" + sFo + ":" + sSubFoC + ":gnReps"
	nvar		gnRep		= $"root:uf:" + sFo + ":" + sSubFoC + ":gnRep"
	nvar		gnChunk		= $"root:uf:" + sFo + ":" + sSubFoC + ":gnChunk"
	nvar		gChnkPerRep	= $"root:uf:" + sFo + ":" + sSubFoC + ":gChnkPerRep" 
	nvar		gPntPerChnk	= $"root:uf:" + sFo + ":" + sSubFoC + ":gPntPerChnk"
	nvar		gnOfsDA		= $"root:uf:" + sFo + ":" + sSubFoC + ":gnOfsDA"
	nvar		gSmpArOfsDA	= $"root:uf:" + sFo + ":" + sSubFoC + ":gSmpArOfsDA"
	nvar		gnOfsAD		= $"root:uf:" + sFo + ":" + sSubFoC + ":gnOfsAD"
	nvar		gSmpArOfsAD	= $"root:uf:" + sFo + ":" + sSubFoC + ":gSmpArOfsAD"
	variable	nSmpInt		= wG[ UFPE_WG_SI ]
	variable	nCntDA		= wG[ UFPE_WG_CNTDA ]	
	variable	nCntAD		= wG[ UFPE_WG_CNTAD ]	
	variable	nCntTG		= wG[ UFPE_WG_CNTTG ]	
	variable	nPnts		= wG[ UFPE_WG_PNTS ] 
	nvar		gnOfsDO		= $"root:uf:" + sFo + ":" + sSubFoC + ":gnOfsDO"
	nvar		gnCompress	= $"root:uf:" + sFo + ":" + sSubFoC + ":gnCompressTG"
	variable	bAppendData	= AppendData()
	nvar		gBkPeriodTimer	= $"root:uf:" + sFo + ":" + sSubFoC + ":gBkPeriodTimer "

	string		buf
	// DAC timing (via PtpChk!) must render ADCBST flag checking unnecessary
	
	variable 	SmpArStartByte, TfHoArStartByte, nPts, nDacReady, code, nTruePt
	variable	ptAD

	// printf "\t\t\tADDASwing(1)  \tnChunk:%2d    nDacReady :%2d  \tticks:%d\r", gnChunk,  nDacReady, ticks 

	variable	bStoreIt, bStoreEpi, begPt, EndPt, repOs, nBigChunk, BlankAmp
	// Additional variables for   ELIMINATE_BLANKS()  == 2 
	variable	BegTrue = 0,  BegTape = 0,  BPoints = 0				// references are passed back
	string  	sTxtStoreSkip = "",  sChnkTime,  sChunkTimes
	variable	ne, nEpis
	variable	eb		= ELIMINATE_BLANKS() 

	variable	hnd		= CedHandle()


	if ( ! CEDHandleIsOpen_ns() )						// MODE  WITHOUT  CED works well for testing

		UFCom_StartTimer( sFo, "Convolve" )		

		if (   eb  <= 1 )							

			printf "\t\tADDASwing_ns a   EB=%d\tne:%2d\t/%2d\t\tBTr:\t%8d\tPts:\t%8d\tBTp:\t%8d\tr:%2d/%2d\tchk:%4d /%5d\t%3d\t%s\t\r", eb, ne, nEpis, BegTrue, BPoints, BegTape, gnRep, gnReps, gnChunk, gChnkPerRep, ItemsInList( lllstChunkTimes, "~" ), sTxtStoreSkip
			ConvolveBuffersDA_ns(   sFo, sc, lllstIO, gnChunk, gnRep-1, gnReps, gChnkPerRep, nCntDA, gPntPerChnk, wRaw, gnOfsDA/2, nPnts ) 

	 		TestCopyRawDAC_ADC( wG, gnChunk, gPntPerChnk, wRaw, gnOfsDA/2, gnOfsAD/2  )

			ptAD = DeconvolveBuffsADTG_ns( sFo, sc, lllstIOTG, gnChunk, gnRep, gnReps, gChnkPerRep, gPntPerChnk, wRaw, gnOfsAD/2, nCntAD , nCntTG, gnCompress, nPnts )		// ??? gnRep

		else	 // ElimBlanks == 2

			sChunkTimes	= StringFromList( (gnRep-1) * gChnkPerRep + gnChunk , lllstChunkTimes, "~" )		// BegTape exceeds SampleArea for gnRep>1 
			//sChunkTimes	= StringFromList( gnChunk, lllstChunkTimes, "~" )
			nEpis		= ItemsInList( sChunkTimes, ";" )
			for ( ne = 0; ne < nEpis; ne += 1 )
				sChnkTime	= StringFromList( ne, sChunkTimes, ";" )
				bStoreEpi		= str2num( UFCom_StringFromDoubleList( ne, 0, sChunkTimes, ";" , "," ) ) 
				BegTrue		= str2num( UFCom_StringFromDoubleList( ne, 1, sChunkTimes, ";" , "," ) ) 
				BPoints		= str2num( UFCom_StringFromDoubleList( ne, 2, sChunkTimes, ";" , "," ) ) 
				BegTape		= str2num( UFCom_StringFromDoubleList( ne, 3, sChunkTimes, ";" , "," ) ) 
				sTxtStoreSkip	= Selectstring( bStoreEpi, "skip:" , "store:" )
				ConvolveBuffersDA_eb2( sFo, sc, lllstIO, 	gnChunk, 	gnRep-1, gnReps, gChnkPerRep, nCntDA, gPntPerChnk, wRaw, gnOfsDA/2, nPnts, BegTrue, BPoints,  gSmpArOfsDA, bStoreEpi, BegTape, hnd )
				printf "\t\tADDASwing_ns b   EB=%d\tne:%2d\t/%2d\t\tBTr:\t%8d\tPts:\t%8d\tBTp:\t%8d\tr:%2d/%2d\tchk:%4d /%5d\t%3d\t%s\t\r", eb, ne, nEpis, BegTrue, BPoints, BegTape, gnRep, gnReps, gnChunk, gChnkPerRep, ItemsInList( lllstChunkTimes, "~" ), sTxtStoreSkip
			endfor
	
	 		TestCopyRawDAC_ADC( wG, gnChunk, gPntPerChnk, wRaw, gnOfsDA/2, gnOfsAD/2  )

			sChunkTimes	= StringFromList( (gnRep-1) * gChnkPerRep + gnChunk , lllstChunkTimes, "~" )		// BegTape exceeds SampleArea for gnRep>1 					// ??? gnRep-1
			//sChunkTimes	= StringFromList( gnChunk, lllstChunkTimes, "~" )
			nEpis		= ItemsInList( sChunkTimes, ";" )
			for ( ne = 0; ne < nEpis; ne += 1 )
				sChnkTime	= StringFromList( ne, sChunkTimes, ";" )
				bStoreEpi		= str2num( UFCom_StringFromDoubleList( ne, 0, sChunkTimes, ";" , "," ) ) 
				BegTrue		= str2num( UFCom_StringFromDoubleList( ne, 1, sChunkTimes, ";" , "," ) ) 
				BPoints		= str2num( UFCom_StringFromDoubleList( ne, 2, sChunkTimes, ";" , "," ) ) 
				BegTape		= str2num( UFCom_StringFromDoubleList( ne, 3, sChunkTimes, ";" , "," ) ) 
				sTxtStoreSkip	= Selectstring( bStoreEpi, "skip:" , "store:" )
				if (	bStoreEpi )
					ptAD = DeconvolveBuffsAD_eb2( sFo, sc, lllstIOTG, gnChunk, gnRep-1, gnReps, gChnkPerRep, gPntPerChnk, wRaw, gnOfsAD/2, nCntAD , nCntTG, gnCompress, nPnts, BegTrue, BPoints, BegTape, hnd )	// ??? gnRep-1
					printf "\t\tADDASwing_ns c   EB=%d\tne:%2d\t/%2d\t\tBTr:\t%8d\tPts:\t%8d\tBTp:\t%8d\tr:%2d/%2d\tchk:%4d /%5d\t%3d\t%s\t\r", eb, ne, nEpis, BegTrue, BPoints, BegTape, gnRep, gnReps, gnChunk, gChnkPerRep, ItemsInList( lllstChunkTimes, "~" ), sTxtStoreSkip
				endif
			endfor

		endif

		UFCom_StopTimer( sFo, "Convolve" )		
		UFCom_StartTimer( sFo, "Process" )						// the current CED pointer is the only information this function gets

		// printf "\tADDASwing()  calls Process( %4d )  \t%2d  gnRep:%2d/%2d \r", ptAD, nProts,  gnRep, nReps
		// HERE the real work is done : CFS Write, Display , PoverN correction
		Process_ns( sFolders, sFo, ptAD, lllstIO,  lllstIOTG, wG, lllstTapeTimes, llstBLF, lllstPoN, lstTotdur )	// different approach: call CFSStore() and TDisplaySuperImposedSweeps() from WITHIN this function

		UFCom_StopTimer( sFo, "Process" )		

		// printf "\t\t\t\tADDASwing() next chunk   \tgnchunk\t:%3d\t/%3d\t ->%3d\t--> nrep\t:%3d\t/%3d\t\tticks:%d \r", gnChunk, gChnkPerRep, mod( gnChunk + 1, gChnkPerRep ), gnRep, gnReps, ticks
		gnChunk	= mod( gnChunk + 1, gChnkPerRep )					// ..increment Chunk  or reset  Chunk to 0
		if ( gnChunk == 0 )				 						// if  the inner  Chunk loop  has just been finished.. 
			gnRep += 1										// ..do next  Rep  (or first Rep again if  Rep has been reset above) and..
			 // printf "\t\t\tADDASwing() next rep  \t\t\tgnChunk\t:%3d\t/%3d\t ->%3d\t--> nRep\t:%3d\t/%3d\t\tticks:%d \r", gnChunk, gChnkPerRep, mod( gnChunk + 1, gChnkPerRep ), gnRep, gnReps, ticks
			if ( gnRep > gnReps )
				if ( ! bAppendData )								// 2003-1028
			 		FinishFiles()								// ..the job is done : the whole stimulus has been output and the Adc data have all been sampled..
				endif
				StopADDA_ns( "\tFINISHED  ACQUISITION.." , UFCom_FALSE, hnd )		// ..then we stop the IGOR-timed periodical background task..  UFCom_FALSE: do NOT ApplyScript()
			endif												// In the E3E4 trig mode StopADDA calls StartStimulus..() for which reps and chunks must already be set to their final value = StopAdda must be the last action
		endif


 	else			//  Ced Handle is Open : REAL MODE  WITH  CED 

		// printf "\t\tADDASwing(A)  gnRep:%d ?<? nReps:%d \r", gnRep, nReps
		nDacReady =  CheckReadyDacPosition( sFo, wG, "MEMDAC,P;", gnRep, gnChunk, hnd ) 
		if ( nDacReady == cADDATRANSFER ) 
			 // printf "\t\tADDASwing(B)   gnRep:%d ?<? nReps:%d \r", gnRep, nReps

			if (  		  gnRep < gnReps ) // DAC: don't transfer the last 'ChunkspRep' (appr. 250..500kByte, same as in  ADDAStart) as they are already transfered..

				if (  ELIMINATE_BLANKS() == 0 )		

					UFCom_StartTimer( sFo, "Convolve" )		
					// printf "\t\tADDASwing(C)  gnRep:%d ?<? nReps:%d ConvDA \r", gnRep, gnReps
					// print "C", gnRep, "-", gnChunk, gnRep,	ChunkspRep, nCntDA, PtpChk, wRaw, OffsDA/2
					// all Dac buffers have 'rollover' :  when the repetition index has passed the last  then we must use the data from the first (=0)
					ConvolveBuffersDA_ns( sFo, sc, lllstIO, gnChunk, gnRep,	gnReps, gChnkPerRep, nCntDA, gPntPerChnk, wRaw, gnOfsDA/2, nPnts )
					UFCom_StopTimer( sFo, "Convolve" )		
					UFCom_StartTimer( sFo, "Transfer" )		
					nPts				= gPntPerChnk * nCntDA 
		 			TfHoArStartByte		= gnOfsDA	 	+ 2 * nPts * mod( gnChunk, 2 ) //  only  2 swaps
					SmpArStartByte		= gSmpArOfsDA		+ 2 * nPts * gnChunk 

					 sprintf buf, "TO1401,%d,%d,%d;", TfHoArStartByte, 2*nPts, TfHoArStartByte ;  UFP_CedSendString( hnd, buf );  	// TransferArea and HostArea start at the same point
					 code		= GetAndInterpretAcqErrors( hnd, "Dac      ", "TO1401 ", gnRep * gChnkPerRep + gnChunk, gnReps * gChnkPerRep )
					sprintf buf,  "SM2,C,%d,%d,%d;", SmpArStartByte, TfHoArStartByte, 2*nPts;   UFP_CedSendString( hnd, buf );   	// copy  Dac data from transfer area to large sample area
					code		= GetAndInterpretAcqErrors( hnd, "Dac      ", "SM2,Dac", gnRep * gChnkPerRep + gnChunk, gnReps * gChnkPerRep )
 					UFCom_StopTimer( sFo, "Transfer" )		

				elseif (   ELIMINATE_BLANKS() == 1 )								

					UFCom_StartTimer( sFo, "Convolve" )		
					// printf "\t\tADDASwing(D)  gnRep:%d ?<? nReps:%d ConvDA \r", gnRep, nReps
					// print "C", gnRep, "-", gnChunk, gnRep,	ChunkspRep, nCntDA, PtpChk, wRaw, OffsDA/2
					// all Dac buffers have 'rollover' :  when the repetition index has passed the last  then we must use the data from the first (=0)
					ConvolveBuffersDA_ns( sFo, sc, lllstIO, gnChunk, gnRep,	gnReps, gChnkPerRep, nCntDA, gPntPerChnk, wRaw, gnOfsDA/2, nPnts )
					UFCom_StopTimer( sFo, "Convolve" )		
					UFCom_StartTimer( sFo, "Transfer" )		
					nPts				= gPntPerChnk * nCntDA 
		 			TfHoArStartByte		= gnOfsDA	 	+ 2 * nPts * mod( gnChunk, 2 ) //  only  2 swaps
					SmpArStartByte		= gSmpArOfsDA		+ 2 * nPts * gnChunk 
	
					begPt	= gPntPerChnk * gnChunk					// BegPt and EndPt are points in the CED sampling area (typ. 16MB) ....
					endPt	= gPntPerChnk * ( gnChunk + 1 )				// The same BegPt and EndPt are passed multiple times if nReps is >1 (=long scripts and/or many protocols)
					repOs	= gnRep * gPntPerChnk * gChnkPerRep		// BegPt and EndPt  PLUS the repetition offset 'repOs' gives the true point number in the DAC wave independently from the CED sampling area size
					nBigChunk= ( BegPt + RepOs ) / gPntPerChnk 
					bStoreIt	= UFPE_StoreChunkorNot_ns( sFo, nBigChunk )				
					BlankAmp	= wRaw[ TfHoArStartByte / 2  ]				// use the first value of this chunk as amplitude for the whole chunk
					variable	nDbgSel	=  UFCom_DebugVar( "acq", "AcqDA" ) 
					if ( UFCom_DebugVar( "acq", "AcqDA" ) & 2  ||  UFCom_DebugVar( "acq", "AcqDA" ) & 8 )
						printf "\t\tAcqDA TfHoA2\t%8d\t ->\tSmpAr:\t %11d \t(pts:%8d)  \tBg:\t%7d\tNd:\t%7d\tChunk:\t%7d\tStoring:%2d\tAmp:\t%7d\t  \r", TfHoArStartByte, SmpArStartByte, nPts, BegPt+repOs, EndPt+repOs, nBigChunk, bStoreIt, BlankAmp
					endif
					if (	bStoreIt )
						sprintf buf, "TO1401,%d,%d,%d;", TfHoArStartByte, 2*nPts, TfHoArStartByte ;  UFP_CedSendString( hnd, buf );  // TransferArea and HostArea start at the same point
						code		= GetAndInterpretAcqErrors( hnd, "Dac      ", "TO1401 ", gnRep * gChnkPerRep + gnChunk, gnReps * gChnkPerRep )
	 				else
						 sprintf buf, "SS2,C,%d,%d,%d;", TfHoArStartByte, 2*nPts, BlankAmp;  UFP_CedSendString( hnd, buf )  		// fill Ced transferArea with constant 'Blank' amplitude. This is MUCH faster than the above 'TO1401' which is very slow
						 code	= GetAndInterpretAcqErrors( hnd, "SmpStart", "SS2    ", gnChunk, gnReps * gChnkPerRep )
					endif
					sprintf buf,  "SM2,C,%d,%d,%d;", SmpArStartByte, TfHoArStartByte, 2*nPts;   UFP_CedSendString( hnd, buf );   	// copy  Dac data from transfer area to large sample area
					code		= GetAndInterpretAcqErrors( hnd, "Dac      ", "SM2,Dac", gnRep * gChnkPerRep + gnChunk, gnReps * gChnkPerRep )
					UFCom_StopTimer( sFo, "Transfer" )		
	
				elseif (   ELIMINATE_BLANKS() == 2 )
	
//					UFCom_StartTimer( sFo, "Convolve" )		
					UFCom_StartTimer( sFo, "Transfer" )		
					sChunkTimes	= StringFromList( gnRep * gChnkPerRep + gnChunk , lllstChunkTimes, "~" )		// BegTape exceeds SampleArea for gnRep>1 
					nEpis		= ItemsInList( sChunkTimes, ";" )
					for ( ne = 0; ne < nEpis; ne += 1 )
						sChnkTime		= StringFromList( ne, sChunkTimes, ";" )
						bStoreEpi			= str2num( UFCom_StringFromDoubleList( ne, 0, sChunkTimes, ";" , "," ) ) 
						BegTrue			= str2num( UFCom_StringFromDoubleList( ne, 1, sChunkTimes, ";" , "," ) ) 
						BPoints			= str2num( UFCom_StringFromDoubleList( ne, 2, sChunkTimes, ";" , "," ) ) 
						BegTape			= str2num( UFCom_StringFromDoubleList( ne, 3, sChunkTimes, ";" , "," ) ) 
						sTxtStoreSkip		= Selectstring( bStoreEpi, "skip:" , "store:" )
						printf "\t\tADDASwing_ns a   EB=%d\tne:%2d\t/%2d\t\tBTr:\t%8d\tPts:\t%8d\tBTp:\t%8d\tr:%2d/%2d\tchk:%4d /%5d\t%3d\t%s\t\r", eb, ne, nEpis, BegTrue, BPoints, BegTape, gnRep, gnReps, gnChunk, gChnkPerRep, ItemsInList( lllstChunkTimes, "~" ), sTxtStoreSkip
						ConvolveBuffersDA_eb2( sFo, sc, lllstIO, gnChunk, gnRep, gnReps, gChnkPerRep, nCntDA, gPntPerChnk, wRaw, gnOfsDA/2, nPnts, BegTrue, BPoints,  gSmpArOfsDA, bStoreEpi, BegTape, hnd )
					endfor
//					UFCom_StopTimer( sFo, "Convolve" )		
					UFCom_StopTimer( sFo, "Transfer" )		

				endif		// Eliminate Blanks
	
			endif		// gnRep < gnReps  ( don't transfer the last DAC 'ChunkspRep' )

			UFCom_StartTimer( sFo, "Transfer" )	

			nPts				= gPntPerChnk * ( nCntAD + nCntTG ) 
			TfHoArStartByte		= gnOfsAD	 	+ round( 2 * nPts * mod( gnChunk, 2 ) * ( nCntAD + nCntTG / gnCompress ) / (  nCntAD + nCntTG ) )// only  2 swaps
			SmpArStartByte		= gSmpArOfsAD		+ 2 * nPts * gnChunk
			nTruePt			= ( ( gnRep - 1 ) * gChnkPerRep +  gnChunk ) * nPts 
			// printf "\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\tAcqAD  \t%8d\t%10d\t%8d\t%10d \r", nPts,SmpArStartByte, TfHoArStartByte, nTruePt	// 

			variable	c, nTGSrc, nTGDest, nTGPntsCompressed

			// Extract interleaved  true AD channels without compression
			for ( c = 0; c < nCntAD; c += 1 )							// ASSUMPTION: order of channels is first ALL AD, afterwards ALL TG
				nTGSrc			= SmpArStartByte + 2 * c
				nTGDest			= round( TfHoArStartByte + 2 * nPts *  		c 		 / ( nCntAD + nCntTG ) )	// rounding is OK here as there will be no remainder
				nTGPntsCompressed	= round( nPts / ( nCntAD + nCntTG ) )									// rounding is OK here as there will be no remainder
				sprintf buf,  "SN2,X,%d,%d,%d,%d;", nTGDest, nTGSrc, 2 * nTGPntsCompressed, 	(nCntAD + nCntTG);   UFP_CedSendString( hnd, buf );    // separate interleaved channels within large (~16MB) sample area to 1MB transfer area 
				code		= GetAndInterpretAcqErrors( hnd, "ExtractAD", "SN2,X,Ad", gnRep * gChnkPerRep + gnChunk, gnReps * gChnkPerRep )
			endfor

			// Extract interleaved Telegraph channel data  and compress them in 1 step
			for ( c = nCntAD; c < nCntAD + nCntTG; c += 1 )			// ASSUMPTION: order of channels is first ALL AD, afterwards ALL TG
				nTGSrc			= SmpArStartByte + 2 * c
				nTGDest			= trunc( TfHoArStartByte + 2 * nPts * ( nCntAD + (c-nCntAD) / gnCompress ) / ( nCntAD + nCntTG ) )
				nTGPntsCompressed	= trunc( nPts / ( nCntAD + nCntTG )   / gnCompress ) 
				sprintf buf,  "SN2,X,%d,%d,%d,%d;", nTGDest, nTGSrc, 2 * nTGPntsCompressed, 	(nCntAD + nCntTG) * gnCompress;   UFP_CedSendString( hnd, buf );    // separate interleaved channels within large (~16MB) sample area to 1MB transfer area 
				code		= GetAndInterpretAcqErrors( hnd, "ExtrCmpTG", "SN2,X,TG", gnRep * gChnkPerRep + gnChunk, gnReps * gChnkPerRep )
			endfor

			variable nPntsCompressed	= round( nPts * ( nCntAD +  nCntTG / gnCompress ) / ( nCntAD + nCntTG ) ) 
			//variable nPntsTest		= ( ( nPts / gnCompress ) * ( nCntAD * gnCompress  +  nCntTG) ) / ( nCntAD + nCntTG )	// same without rounding (if Igor recognizes paranthesis levels)

			if ( ELIMINATE_BLANKS() == 0 )						

				sprintf  buf, "TOHOST,%d,%d,%d;", TfHoArStartByte, 2 * nPntsCompressed, TfHoArStartByte ;  UFP_CedSendString( hnd, buf );  // TransferArea and HostArea start at the same point
				//	 print "\t\t\t\tADDASwing_ns()  EB=0  Adc2Host   nPts", nPts, "nPntsCompressed ", nPntsCompressed ,  "bytes", nPntsCompressed *2, "buf", buf
				code		= GetAndInterpretAcqErrors( hnd, "Sampling", "TOHOST", gnRep * gChnkPerRep + gnChunk, gnReps * gChnkPerRep )

				UFCom_StopTimer( sFo, "Transfer" )		
				UFCom_StartTimer( sFo, "Convolve" )	
	
				printf "\t\tADDASwing_ns d   EB=%d\tne:%2d\t/%2d\t\tBTr:\t%8d\tPts:\t%8d\tBTp:\t%8d\tr:%2d/%2d\tchk:%4d /%5d\t%3d\t%s\tTOHOST\t%d\t%d\t%d\r", eb, ne, nEpis, BegTrue, BPoints, BegTape, gnRep, gnReps, gnChunk, gChnkPerRep, ItemsInList( lllstChunkTimes, "~" ), sTxtStoreSkip, TfHoArStartByte, 2 * nPntsCompressed, TfHoArStartByte
				ptAD = DeconvolveBuffsADTG_ns( sFo, sc, lllstIOTG, gnChunk, gnRep, gnReps, gChnkPerRep, gPntPerChnk, wRaw, gnOfsAD/2, nCntAD , nCntTG, gnCompress, nPnts )	
	
				UFCom_StopTimer( sFo, "Convolve" )		

			elseif (   ELIMINATE_BLANKS() == 1 )					

				begPt	= gPntPerChnk * gnChunk					// BegPt and EndPt are points in the CED sampling area (typ. 16MB) ....
				endPt	= gPntPerChnk * ( gnChunk + 1 )				// The same BegPt and EndPt are passed multiple times if nReps is >1 (=long scripts and/or many protocols)
				repOs	= ( gnRep - 1 ) * gPntPerChnk * gChnkPerRep	// BegPt and EndPt  PLUS the repetition offset 'repOs' gives the true point number in the DAC wave independently from the CED sampling area size
				nBigChunk= ( BegPt + RepOs ) / gPntPerChnk 
				bStoreIt	= UFPE_StoreChunkorNot_ns( sFo, nBigChunk )				
				if (  UFCom_DebugVar( "acq", "AcqAD" )  & 2  ||  UFCom_DebugVar( "acq", "AcqAD" )  & 8 )
					printf "\t\tAcqAD TfHoA3\t%8d\t ->\tSmpAr:\t %11d \t(pts:%8d)  \tBg:\t%7d\tNd:\t%7d\tChunk:\t%7d\tStoring:%2d\t  \r", TfHoArStartByte, SmpArStartByte, nPts, BegPt+repOs, EndPt+repOs, nBigChunk, bStoreIt
				endif
				if (	bStoreIt )
					sprintf  buf, "TOHOST,%d,%d,%d;", TfHoArStartByte, 2 * nPntsCompressed, TfHoArStartByte ;  UFP_CedSendString( hnd, buf );  // TransferArea and HostArea start at the same point
					// print "EB=1  nPts", nPts, "nPntsCompressed ", nPntsCompressed ,  "bytes", nPntsCompressed *2, "buf", buf
					code		= GetAndInterpretAcqErrors( hnd, "Sampling", "TOHOST", gnRep * gChnkPerRep + gnChunk, gnReps * gChnkPerRep )
				endif

				UFCom_StopTimer( sFo, "Transfer" )		
				UFCom_StartTimer( sFo, "Convolve" )	
	
				//printf "\t\tADDASwing_ns(e)  EB=%d\tne:%2d\t/%2d\t\tBTr:\t%8d\tPts:\t%8d\tBTp:\t%8d\tr:%2d/%2d\tchk:%4d /%5d\t%3d\t%s\tTOHOST\t%d\t%d\t%d\r", eb, ne, nEpis, BegTrue, BPoints, BegTape, gnRep, gnReps, gnChunk, gChnkPerRep, ItemsInList( lllstChunkTimes, "~" ), sTxtStoreSkip, TfHoArStartByte, 2 * nPntsCompressed, TfHoArStartByte
				ptAD = DeconvolveBuffsADTG_ns( sFo, sc, lllstIOTG, gnChunk, gnRep, gnReps, gChnkPerRep, gPntPerChnk, wRaw, gnOfsAD/2, nCntAD , nCntTG, gnCompress, nPnts )	
	
				UFCom_StopTimer( sFo, "Convolve" )		

			elseif (   ELIMINATE_BLANKS() == 2 )					


				// Note:
				// The TG compression rate is independent of the store/nostore sections, i.e. even during nostore sections TG Adc points are sampled .
				// This is required by the fact that it would is impossible to compute a single compression rate (other than 1) valid for any combination of store/nostore where it is guaranteed that there are TG points in the store sections.
				// The negative consequence is that every chunk which contains a 'store' section has to be transfered ENTIRELY from the sampling area to the transfer area by the 'TOHOST' command, not only  the 'store' section.
				// Once in the sampling area the data can be deconvolved very effectively:  For the true ADC channels only 'store' sections are processed,  and for the  TG channels  only every 'nCompress' data point is preocessed. Here much time is gained.

				sChunkTimes	= StringFromList( (gnRep-1) * gChnkPerRep + gnChunk , lllstChunkTimes, "~" )		// BegTape exceeds SampleArea for gnRep>1 
				nEpis		= ItemsInList( sChunkTimes, ";" )
	
				// Only if this chunk contains 1 or more 'store' sections  we also extract and tranfer the TG information of the entire chunk to the host Transfer area as this 'TOHOST' operation is very time consuming. 
				variable	bHasStored	= UFCom_FALSE
				for ( ne = 0; ne < nEpis; ne += 1 )

					sChnkTime		= StringFromList( ne, sChunkTimes, ";" )
					bStoreEpi			= str2num( UFCom_StringFromDoubleList( ne, 0, sChunkTimes, ";" , "," ) ) 								// truth whether part of a chunk (=an episode) must be transfered from the CED sampling area to the host Tranfer area depending on the 'store/nostore' attribute
					BegTrue			= str2num( UFCom_StringFromDoubleList( ne, 1, sChunkTimes, ";" , "," ) ) 
					BPoints			= str2num( UFCom_StringFromDoubleList( ne, 2, sChunkTimes, ";" , "," ) ) 
					BegTape			= str2num( UFCom_StringFromDoubleList( ne, 3, sChunkTimes, ";" , "," ) ) 
					sTxtStoreSkip		= Selectstring( bStoreEpi, "skip:" , "store:" )
	
					if ( bStoreEpi )																							// this episode must be transfered from the CED sampling area to the host Tranfer area.  This 'TOHOST' operation is very time consuming and limits the max sample rate..  
			
						//printf "\t\tADDASwing_ns g   EB=%d\tne:%2d\t/%2d\t\tBTr:\t%8d\tPts:\t%8d\tBTp:\t%8d\tr:%2d/%2d\tchk:%4d /%5d\t%3d\tptc:\t%8d\t%s\t\r", eb, ne, nEpis, BegTrue, BPoints, BegTape, gnRep, gnReps, gnChunk, gChnkPerRep, ItemsInList( lllstChunkTimes, "~" ), nPntsCompressed, sTxtStoreSkip
	
						if ( ! bHasStored )																					// transfer the entire chunk from the CED sampling area to the host Tranfer area only ONCE if at least  1 episode is a 'store' section
							sprintf  buf, "TOHOST,%d,%d,%d;", TfHoArStartByte, 2 * nPntsCompressed, TfHoArStartByte ;  UFP_CedSendString( hnd, buf );  	// TransferArea and HostArea start at the same point
							code		= GetAndInterpretAcqErrors( hnd, "Sampling", "TOHOST", (gnRep-1) * gChnkPerRep + gnChunk, gnReps * gChnkPerRep )
							// print "EB=2  nPts", nPts, "nPntsCompressed ", nPntsCompressed ,  "bytes", nPntsCompressed *2, "buf", buf
				UFCom_StartTimer( sFo, "Convolve" )	
							DeconvolveBuffsTG_eb2( sFo, sc, lllstIOTG, gnChunk, gnRep-1, gnReps, gChnkPerRep, gPntPerChnk, wRaw, gnOfsAD/2, nCntAD , nCntTG, gnCompress, nPnts, BegTrue, BPoints, BegTape )	// ??? gnRep-1
						UFCom_StopTimer( sFo, "Convolve" )	
							bHasStored	= UFCom_TRUE																	// don't transfer the entire chunk a second time and don't deconvolve the TG channels again
						endif

						// Recognise the 'store/nostore' sections here and  extract the true Adc channels.  Transfer only 'store' sections from the Ced sampling area to the host transfer area  and deconcolve only 'store' sections into the 'BigIO' waves..
				UFCom_StartTimer( sFo, "Convolve" )	
						ptAD 	= DeconvolveBuffsAD_eb2( sFo, sc, lllstIOTG, gnChunk, gnRep-1, gnReps, gChnkPerRep, gPntPerChnk, wRaw, gnOfsAD/2, nCntAD , nCntTG, gnCompress, nPnts, BegTrue, BPoints, BegTape, hnd )	// ??? gnRep-1
						//printf "AddaSw PtAd: \t\t%d\r", ptAD

						UFCom_StopTimer( sFo, "Convolve" )	
					endif
	
				endfor

				UFCom_StopTimer( sFo, "Transfer" )		
			endif					


			UFCom_StartTimer( sFo, "Process" )						// the current CED pointer is the only information this function gets
			// printf "\tADDASwing()  calls Process( %4d )  \t%2d  gnRep:%2d/%2d \r", ptAD, nProts,  gnRep, nReps

			// HERE the real work is done : CFS Write, Display , PoverN correction
			Process_ns( sFolders, sFo, ptAD, lllstIO,  lllstIOTG, wG, lllstTapeTimes, llstBLF, lllstPoN, lstTotdur )	// different approach: call CFSStore() and TDisplaySuperImposedSweeps() from WITHIN this function
	
			UFCom_StopTimer( sFo, "Process" )		
	
			// printf "\t\t\t\tADDASwing() next chunk   \tgnchunk\t:%3d\t/%3d\t ->%3d\t--> nrep\t:%3d\t/%3d\t\tticks:%d \r", gnChunk, gChnkPerRep, mod( gnChunk + 1, gChnkPerRep ), gnRep, gnReps, ticks
			gnChunk	= mod( gnChunk + 1, gChnkPerRep )					// ..increment Chunk  or reset  Chunk to 0
			if ( gnChunk == 0 )				 						// if  the inner  Chunk loop  has just been finished.. 
				gnRep += 1										// ..do next  Rep  (or first Rep again if  Rep has been reset above) and..
				 // printf "\t\t\tADDASwing() next rep  \t\t\tgnChunk\t:%3d\t/%3d\t ->%3d\t--> nRep\t:%3d\t/%3d\t\tticks:%d \r", gnChunk, gChnkPerRep, mod( gnChunk + 1, gChnkPerRep ), gnRep, gnReps, ticks
				if ( gnRep > gnReps )
					if ( ! bAppendData )								// 2003-1028
				 		FinishFiles()								// ..the job is done : the whole stimulus has been output and the Adc data have all been sampled..
					endif
					StopADDA_ns( "\tFINISHED  ACQUISITION.." , UFCom_FALSE, hnd )		// ..then we stop the IGOR-timed periodical background task..  UFCom_FALSE: do NOT ApplyScript()
				endif												// In the E3E4 trig mode StopADDA calls StartStimulus..() for which reps and chunks must already be set to their final value = StopAdda must be the last action
			endif
	
		endif		// nDacReady == cADDATRANSFER

	endif		//  CEDHandleIsOpen

	if ( nDacReady  == UFCom_kERROR )								// Currently never executed as currently the acquisition continues even in worst case of corrupted data 
	 	FinishFiles()												// ...'CheckReadyDacPosition()'  must be changed if this code is to be executed
		StopADDA_ns( "\tABORTED  ACQUISITION.." , UFCom_FALSE, hnd )		//  UFCom_FALSE: do NOT ApplyScript() 
	endif															// returning   nDacReady = UFCom_kERROR  will kill the background task

	return nDacReady
End


static Function  CheckReadyDacPosition( sFo, wG, command, nRep, nChunk, hnd )
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
	string  	sFo
	wave	wG
	variable	nRep, nChunk, hnd
	string		command 

	string  	sSubFoC		= UFPE_ksCOns
	variable	nProts			= UFPE_Prots( sFo )
	nvar		gBkPeriodTimer		= $"root:uf:" + sFo + ":" + sSubFoC + ":gBkPeriodTimer"
	nvar		gnReps			= $"root:uf:" + sFo + ":" + sSubFoC + ":gnReps"
	nvar		gChnkPerRep		= $"root:uf:" + sFo + ":" + sSubFoC + ":gChnkPerRep" 
	nvar		gPntPerChnk		= $"root:uf:" + sFo + ":" + sSubFoC + ":gPntPerChnk"
	variable	nSmpInt			= wG[ UFPE_WG_SI ]
	variable	nCntDA			= wG[ UFPE_WG_CNTDA ]	
	variable	nCntAD			= wG[ UFPE_WG_CNTAD ]	
	variable	nCntTG			= wG[ UFPE_WG_CNTTG ]	
	nvar		gnAddIdx			= $"root:uf:" + sFo + ":" + sSubFoC + ":gnAddIdx"
	nvar		gnLastDacPos		= $"root:uf:" + sFo + ":" + sSubFoC + ":gnLastDacPos"
	nvar		gReserve			= $"root:uf:" + sFo + ":" + sSubFoC + ":gReserve"
	nvar		gMinReserve		= $"root:uf:" + sFo + ":" + sSubFoC + ":gMinReserve"
	nvar		gPrediction		= root:uf:acq:pul:vdPredict0000
	nvar		gMaxSmpPtspChan	= $"root:uf:" + sFo + ":" + sSubFoC + ":gMaxSmpPtspChan"
	nvar		gErrCnt			= $"root:uf:" + sFo + ":" + sSubFoC + ":gErrCnt"
	nvar		gbAcquiring		= $"root:uf:" + sFo + ":" + sSubFoC + ":gbAcquiring"
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
	variable	nDacPos	=  UFP_CedGetResponse( hnd, command, command, 0 )			// last param is 'ErrMode' : display messages or errors

	// 2003-08 The following calls requesting the CED AD-pointer and AD-status are not mandatory. They have been introduced only for information..
	// ...in an attempt to avoid the erroneous CED error  'Clock input overrun'  which unfortunately occurs already when the sampling is near (but still below) the limit.
	// When removing these calls be sure that the remaining mandatory CED DA-pointer requests still work correctly. 
	// It seemed (once) that DA- and AD-requests are not under all circumstances completely  as independent as they should be.
	variable	nDAStat	= UFP_CedGetResponse( hnd, "MEMDAC,?;" , "MEMDACstatus",  0 )	// last param is 'ErrMode' : display messages or errors
	variable	nADStat	= UFP_CedGetResponse( hnd, "ADCBST,?;", "ADCBSTstatus  ",  0 )	// last param is 'ErrMode' : display messages or errors
	variable	nADPtr	= UFP_CedGetResponse( hnd, "ADCBST,P;", "ADCBSTpointer ",  0 )	// last param is 'ErrMode' : display messages or errors
	nADPtr /=  ( nCntAD + nCntTG ) 

	// We want the time during which the stimulus is output, not the pre-time possibly waiting for the E3E4 trigger and not the post-time when the stimulus is possibly reloaded (when nReps>1)  
	// PnTest() -> Print options (Debug)  -> Everything ->  Acquisition reveals that  'nDacPos' , 'nADPtr'  and possibly 'nADStat' and 'nDAStat' can be used for that purpose 
	// 'gbRunning' is here not a valid indicator as it not yet set to 0 here after a user abort
	// 'nDacPos'    is here not always a valid indicator as it is not set to 0 after a user  abort
	gbAcquiring	=   nAdPtr == 0   ||  nDacPos == 0   ?   0  :  1				// 2003-1030
	StartStopFinishButtonTitles( sFo, sSubFoC )									// 2003-1030 reflect change of 'gbAcquiring' in buttons : enable or disable (=grey) them 

	// 2003-1210  The  standard 1401   and the  1401plus / power1401 behave differently so that the code recognizing the normal FINISH  of a script fails :
	// For the 1401plus and power1401 the  'nPredDacPos' -> 'gnAddIdx' -> 'IsIdx'  computation is effective in 2 cases:
	//	1. during all but the last chunks ( Dacpos resets but AddIndex incrementing compensates for that )
	//	2. after the last chunk: DacPos goes to  0   but AddIndex incrementing compensates for that  -> IsIndex increments a last time -> = SollIndex -> XFER is returned -> StopADDA() is called at the end of AddaSwing() 
	// For the standard 1401  the  'nPredDacPos' -> 'gnAddIdx' -> 'IsIdx'  computation is effective in only in case 1. :  during acquisition but not after the last chunk 
	//	It fails in case 2.  after the last as DacPos  does NOT go to 0  but instead stay fixed at the index of the last point MINUS 2 !  -> IsIndex would  NOT be incremented -> WAIT would be returned -> StopADDA() is never called
	//	Solution : Check and use the Dac status ( which goes to 0 after finishing ) instead . The Adc status also goes to 0 after finishing but a script does not necessarily contain ADC channels so we do not use it.
	// In principle this patch for the standard 1401 could also be used for the 1401plus and power1401, as their status flags go to 0 in the same manner after finishing...............

	// 'nSkippedChnks' can be fairly good estimated (error < 0.1) .  
	//  We must not count skipped chunks when waiting for a  HW E3E4 trigger, as in this case short scripts (shorter than Background time ~100ms)  would...
	// ...erroneously increment  'nPredDacPos' -> 'gnAddIdx' -> 'IsIdx'  and then trigger the error case below. We avoid this error by setting  'nSkippedChnks=0' when not acquiring  
	variable	nSkippedChnks	= ( BkPeriod / ( gPntPerChnk * nSmpInt * .001 ) ) * gbAcquiring
	variable	nPredDacPos	= gnLastDacPos + nSkippedChnks * nPts			// Predicted Dac position can be greater than buffer!

	
	gnLastDacPos		=  nDacPos									// save value for next call
	gnAddIdx		       += gChnkPerRep * trunc( ( nPredDacPos - nDacPos ) / ( nPts  * gChnkPerRep ) + .5 ) 
	variable	IsIdx		=  trunc( nDacPos / nPts ) +  gnAddIdx
	variable	SollIdx	=  nChunk + 1 + gChnkPerRep * ( nRep - 1 )
	variable	TooHighIdx= SollIdx + gChnkPerRep - 1	

	// if ( standard 1401 )    ....would be safer 		// 2003-1210
	if ( nDAStat == 0 )
		IsIdx = SollIdx		// 2003-1210 only for standard 1401 : return XFER after finishing (if it also works for 1401plus and power1401 we do not have to pass/check the type of the 1401...))
	endif

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
		gPrediction	= PredictedAcqSuccess( nProts, gnReps, gChnkPerRep, gReserve, IsIdx , rNeeded, rCurrent )

	else 				// if ( IsIdx > SollIdx + ChkpRep - 1 )		// UFCom_kERROR: more than one lap behind, data will be lost  ( gReserve = 0 )  if  at the same time nReps>1  
		nResult	= cADDATRANSFER						// on error : continue
		sResult	= "  ??? "								// more than one lap behind, but no data will be lost as nReps==1   031119

		// the following 2 lines are to be ACTIVATED ONLY  FOR TEST  to break out of the inifinite  Background task loop.....  031111
		//nResult	= UFCom_kERROR								// on error : stop acquisition
		// printf "\t++++UFCom_kERROR in Test mode: abort prematurely in StopAdda() because of 'Loosing data error' , will also  stop  Background task. \r" 

		if ( gnReps > 1  )	// scripts with only 1 repetition will never fail no matter how many protocols are output but the  'IsIdx - TooHighIdx' will erroneously indicate data loss if 'nProts>>1' 
			sResult	= "LOOS'N"
			if ( gErrCnt == 0 )								// issue this error only once
				variable	TAused	= TAUse( gPntPerChnk, nCntDA, nCntAD, cMAX_TAREA_PTS )
				variable	MemUsed	= MemUse( gChnkPerRep, gPntPerChnk, gMaxSmpPtspChan )
				sprintf ErrBuf, "Data  in Chunk: %d / %d will probably be corrupted. Acquisition too fast, too many channels, too many or unfavorable number of data points.\r \t\t\tTA usage:%3d%%  Memory usage:%3d%%  Reps:%d  ChkPerRep:%d  PtsPerChunk:%d ", IsIdx, gnReps * gChnkPerRep, TAused, MemUsed, gnReps, gChnkPerRep, gPntPerChnk
				UFCom_FoAlert( sFo, UFCom_kERR_SEVERE, ErrBuf )						// 2003-0716
				gErrCnt	+= 1
			endif
		endif
	endif

	if ( UFCom_DebugVar( "acq", "AcqDA" ) & 8  ||  UFCom_DebugVar( "acq", "AcqAD" ) & 8 )
		printf "\ta:%d\tR:%2d/%2d\tChk:%3d/%3d\tAp:%8d\tDp:%8d\tPD:%8d\tTb:%4d", gbAcquiring, nRep, gnReps, (nRep-1) * gChnkPerRep + nChunk, gnReps * gChnkPerRep, nADPtr , nDacPos, nPredDacPos, BkPeriod
		printf "\tsC:%4.1lf  AI:%4d\tIsI:%4.1lf\t[%3d\t|%3d.%3d\t|%3d\t] Rs\t:%3d\t/%3d\t/%3d\t%s\tStt:%4d\t|%5d", nSkippedChnks, gnAddIdx, IsIdx, SollIdx-1, SollIdx, TooHighIdx-1, TooHighIdx, gMinReserve, gReserve, gChnkPerRep, sResult, nDAStat, nADStat
		// printf "\tPr:%5.2lf\t=sc:%5.1lf \t/sn:%5.1lf \r", gPrediction, rCurrent, rNeeded   	// display speeds (not good : range -1000...+1000)
		printf "\tPr:%5.2lf\t= n %.2lf \t/  c %.2lf \r", gPrediction, rNeeded, rCurrent		// display inverse speeds ( good: range  -1...+1)
	endif
	return	nResult
End


static Function		PredictedAcqSuccess( nProts, nReps, nChnkPerRep, nReserve, IsIdx, Needed, Current )
// Returns (already during acquisition) a guess whether the acq will succeed ( > 1 ) or fail  ( < 1 ) .
// This information is useful when the scripts takes very long and when the system is perhaps too slow for the  ambitious sampling rate and number of channels 
	variable	nProts, nReps, nChnkPerRep, nReserve, IsIdx
	variable	&Needed, &Current
	variable	PredCurr
	variable	PosReserveDifference			// if (in rare cases) the reserve increases during the acq  a neg. reserve diff is computed which gives a false 'Loosing data' indication 
										// we avoid this by clipping to zero so that the correct Prediction = Inf = Success  is displaed
	nvar		/Z 	gStaticPrevReserve			// used like static, should be hidden within this function but must keep its value between calls
	nvar		/Z 	gStaticPrediction			// used like static, ...
	nvar		/Z 	gStaticIsIdx				// used like static, ...
	if ( ! nvar_Exists( gStaticPrevReserve	) )
		variable   /G	gStaticPrevReserve	= 0	// used like static, should be hidden within this function but must keep its value between calls
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
			PosReserveDifference = max( 0, gStaticPrevReserve - nReserve ) 			// if (in rare cases) the reserve increases during the acq  a neg. reserve diff is computed which gives a false 'Loosing data' indication 
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


Function		FinishFiles()
	FinishCFSFile()
	FinishAnalysisFile()
End


Function		StopADDA_ns( strExplain , bDoApplyScript, hnd )
	string		strExplain
	variable	bDoApplyScript, hnd 

//todo: 	
	variable	sc = 0	

	string  	sFo			= ksACQ
	string  	sSubFoC		= UFPE_ksCOns
	svar	/Z	lllstIO			= $"root:uf:" + sFo + ":" + "lllstIO"  						
	svar		lllstTapeTimes	= $"root:uf:" + sFo + ":" + "lllstTapeTimes" 	
	svar		llstBLF		= $"root:uf:" + sFo + ":" + "llstBLF" 	
	svar		lllstChunkTimes	= $"root:uf:" + sFo + ":" + "lllstChunkTimes" 	

	wave  	wRaw			= $"root:uf:" + sFo + ":" + UFPE_ksKEEPwr + ":wRaw"		

	nvar		gBkPeriodTimer		= $"root:uf:" + sFo + ":" + sSubFoC + ":gBkPeriodTimer"
	nvar		gbRunning		= $"root:uf:" + sFo + ":" + UFPE_ksKEEP + ":gbRunning"
	nvar		gnTicksStop		= $"root:uf:" + sFo + ":" + UFPE_ksKEEP + ":gnTicksStop"

	variable	bTrigMode			= TrigMode()
	nvar		gbQuickAcqCheck	= $"root:uf:"+sFo+":mis:AcqCheck0000"	
//	variable	nRadDebgGen		= UFCom_DebugDepthGen()
	string		bf
	variable	dummy			= stopMSTimer( gBkPeriodTimer )

	 PrintBackGroundInfo( "StopADDA(1) V4" , "before Stop" )


// 2010-02-09 only test to simplify the code.   E3E4  (stop/ finish)  works by selecting  Trig 'Start'   again
		BackGroundInfo	
		if ( v_Flag == cBKG_RUNNING )			// Only if the bkg task is running we can stop it.  We must rule out the case when it is not yet running for example when switching the trigger mode initially at program start .
			// printf "\t\t\tStopADDA(2) \t\t\tstopping BackGround task \r "
			CtrlBackGround stop				// end of data acquisition
		endif

//		if ( bTrigMode == 0  ) 	// 2003-1113
//			BackGroundInfo	
//			if ( v_Flag == cBKG_RUNNING )			// Only if the bkg task is running we can stop it.  We must rule out the case when it is not yet running for example when switching the trigger mode initially at program start .
//				// printf "\t\t\tStopADDA(2) \t\t\tstopping BackGround task \r "
//				CtrlBackGround stop				// end of data acquisition
//			endif
//		endif


	 PrintBackGroundInfo( "StopADDA(2) V4" , "after  Stop" )
	
	if (  CEDHandleIsOpen_ns() )
		variable	ShowMode = UFPE_ERRLINE
		// ShowMode = ( nRadDebgGen == 2 ||  UFCom_DebugVar( 0, "acq", "AcqDA" )   ||  UFCom_DebugVar( 0, "acq", "AcqAD" ) ) ? UFPE_MSGLINE : UFPE_ERRLINE // syntax not allowed for debug printing...	
		if  ( UFCom_DebugVar( "acq", "General" ) & 4  ||  UFCom_DebugVar( "acq", "AcqDA" )  ||  UFCom_DebugVar( "acq", "AcqAD" ) )
			ShowMode = UFPE_MSGLINE 
		endif

		// Although it would seem safe we do NOT reset the CED1401 (nor use KillIO) because	1. the Power1401 would not start next acquisition.
		//																2. there would be an undesired  1ms glitch on all digouts appr.500ms after end of stimulus (only on 1401plus) 
		CEDSendStringCheckErrors( hnd, "ADCBST,K;" , 0 ) 						// 2003-1111 kill the sampling process
		CEDSendStringCheckErrors( hnd, "MEMDAC,K;" , 0 ) 						// 2003-1111 kill the stimulation process
		CEDSendStringCheckErrors( hnd, "DAC,0 1 2 3,0 0 0 0;" , 0 ) 				// 2003-1111 set all DACs to 0 when aborting 
		CEDSendStringCheckErrors( hnd, "DIGTIM,K;" , 0 ) 						// 2003-1111 kill the digital output process
		CEDSetAllDigOuts( hnd, 0 )											// 2003-1111 Initialize the digital output ports with 0 : set to LOW

		nvar	gnReps	= $"root:uf:" + sFo + ":" + sSubFoC + ":gnReps"
		// printf "\t\t\tStopADDA(3) \t\t\tgnReps: %2d   \r ", gnReps
		if ( gnReps > 1 )		
			// 2003-1030 Unfortunately we cannot use 'gnAcqStatus'  to reflect the time spent in the following function  'CEDInitializeDacBuffers()'  in a  'STC/kSTC'  string color  field display,  neither  by setting the controlling..
			// ..global 'gnAcqStatus' directly  nor  indirectly by a dependency relation 'gbAcqStatus :=  f( gbReloading )  as we are right now still in the background task, and controls are only updated when Igor is idling. 
			// Workaround : It is possible  (even when in the middle of a background function)  to change directly  the title of a button, but this is not really what we want.
			// Code (NOT working)  :		nvar gnAcqStatus=root:uf:"+sFo+":pul:gnAcqStatus; gnAcqStatus=2   
			// Code (NOT working either) :  	nvar gbReloading=root:uf:acq:cons:gbReloading; gbReloading=UFCom_TRUE ; do something; gbReloading=UFCom_FALSE;    and coded elsewhere	SetFormula root:uf:"+sFo+":pul:gnAcqStatus, "root:uf:acq:cons:gbReloading * 2"
			
			// printf "\t\t\tStopADDA(4) \t\t\tgnReps: %2d \t-> CEDInitializeDacBuffers() \r ", gnReps

			wave	wG				= $FoWvNmWgNs( sFo )
			if ( ELIMINATE_BLANKS() <= 1 )		
				CEDInitializeDacBuffers( sFo, sSubFoC, sc, lllstIO, wRaw, wG, hnd )			// Ignore (by NOT measuring)  'Transfer' and 'Convolve' times here after finishing as they have no effect on acquisition (only on load time)
			elseif ( ELIMINATE_BLANKS() == 2 )			
				CEDInitializeDacBuffers_eb2( sFo, sSubFoC, sc, lllstIO, llstBLF, lllstTapeTimes, wRaw, wG, lllstChunkTimes, hnd )	// avoid BigIO waves entirely...
			endif			

		endif
		
	endif

	//if ( nRadDebgGen <= 1 ||  UFCom_DebugVar( "acq", "AcqDA" )  ||  UFCom_DebugVar( "acq", "AcqAD" ) )
	variable nDbgGen = UFCom_DebugVar( "acq", "General" )
	if ( nDbgGen & 1  ||  nDbgGen & 2  ||  UFCom_DebugVar( "acq", "AcqDA" )  ||  UFCom_DebugVar( "acq", "AcqAD" ) )
		printf "%s  \r", strExplain
	endif

	if ( gbQuickAcqCheck )									//  for quick testing the integrity of acquired data including telegraph channels
		QuickAcqCheck( sFo, wRaw, lllstIO )
	endif

	gbRunning	= UFCom_FALSE 									// 2003-1030
	StartStopFinishButtonTitles( sFo, sSubFoC )							// 2003-1030 reflect change of 'gbRunning' 

	gnTicksStop	= ticks 									// save current  tick count  (in 1/60s since computer was started) 

	UFCom_EnableButton( "pul", 	"root_uf_acq_pul_ApplyScript0000",	UFCom_kCo_ENABLE )
	UFCom_EnableSetVar( "pul", 	"root_uf_acq_pul_gnProts0000",	UFCom_kCo_ENABLE_SV )	// ..allow also changing the number of protocols ( which triggers 'ApplyScript()'  )
	UFCom_EnableButton( "pul", 	"root_uf_acq_pul_LoadScript0000",	UFCom_kCo_ENABLE )
	UFCom_EnableButton( "pul", 	"root_uf_acq_pul_buDelete0000",	UFCom_kCo_ENABLE )// 2005-05-30 Allow deletion of the current file only after acquisition has stopped

	ShowTimingStatistics_ns( sFo )

	 printf "\t\tStopAdda( before  ApplyScript ) \tbTrigMode : %d     running: %d   bApplyScript:%2d   WaveExists(): wRaw:%d \r", bTrigMode, gbRunning, bDoApplyScript, WaveExists(wRaw)
	if ( bDoApplyScript )
		ApplyScript() 										// kills and rebuilds wVal, wFix, wE, wBFS ( wG is maintained in folder UFPE_ksKEEP )
		// printf "\t\tStopAdda(  after   ApplyScript ) \tbTrigMode : %d     running: %d   bApplyScript:%2d   WaveExists(): wRaw:%d \r", bTrigMode, gbRunning, bDoApplyScript, WaveExists(wRaw)
	endif

	if ( bTrigMode == 1 ) 	// 2003-10-25 continuous hardware trig'd mode: (re)arm the trigger detection after a stimulus is finished so that each new trigger on E3E4 triggers the next acquisition run
		// printf "\t\t\tStopADDA(6) \t\t\t-> StartStimulusAndAcquisition() \r "					// 2003-1119
		StartStimulusAndAcquisition_ns() 	//  this will call  'CedStartAcq'  which will  set  'gbRunning'  UFCom_TRUE
	endif
End



static Function		StartStopFinishButtonTitles( sFo, sSubFoC )
// Enables and disables 'Start/Stop/Finish/Trigger mode/Apppend data' related buttons depending on the control's settings  AND  on program state ('gbRunning, gbAcquiring')
// For this to work this function must EXPLICITLY be called every time one of the input parameters changes. 
// This easily done (without any negative impact) for the controls by putting a call to this function into the action procedure.
// For reflecting the state of  non-control globals like 'gbRunning, gbAcquiring' a call to this function must be placed in the background procedure where  'gbRunning, gbAcquiring'  change .
// This might possibly have a negative impact on program behaviour but actually it seems to work fine....   
// TODO  031030   measure time needed for the execution of this function and then decide.....
// Possible workaround : Ignore changes of  'gbRunning, gbAcquiring'  in the button title ,  instead place a  'STC/kSTC'  string color  field  in the vicinity of the button.
// A  'STC/kSTC'  string color  field is updated automatically through a dependency and does not need an explicit call when an input parameter changes.

// 2003-1031 flaw: In mode  HW trigger,  not appending, not acquiring the button 'Finish'  should be on  initially  but  should  be disabled after being pressed once and be enabled by the next 'Start'='gbAcquiring'
	string  	sFo
	string  	sSubFoC			// 'co'  or  'cons'

	variable	bTrigMode		= TrigMode()
	variable	bAppendData	= AppendData()
	nvar		gbRunning 	= $"root:uf:acq:" + UFPE_ksKEEP + ":gbRunning"
	nvar		gbAcquiring 	= $"root:uf:acq:" + sSubFoC + ":gbAcquiring"
	string  	sPanel		= "pul"
	string		sBuStartNm	= "root_uf_acq_pul_StartAcq0000"
	string		sBuStopNm	= "root_uf_acq_pul_StopFinish0000"
	string		sStartStop		= "S t a r t"

	if ( bTrigMode == 0  &&   !  bAppendData  &&  ! gbRunning )		// normal  SW triggered mode, 
		Button	$sBuStopNm 	win = $sPanel,	title = "Stop",	disable = UFCom_kCo_DISABLE
		UFCom_EnableButton( sPanel, sBuStartNm,		UFCom_kCo_ENABLE )						//	 
	endif
	if ( bTrigMode == 0  &&   ! bAppendData	  &&    gbRunning )	// normal  SW triggered  mode, 
		Button	$sBuStopNm	win=$sPanel,	 title = "Stop",	disable = UFCom_kCo_ENABLE	
		UFCom_EnableButton( sPanel, sBuStartNm,		UFCom_kCo_DISABLE )						// 
	endif
	if ( bTrigMode == 0  &&    bAppendData	  &&  ! gbRunning )	// normal  SW triggered  mode, 
		Button	$sBuStopNm	win=$sPanel,	 title = "Finish",	disable = UFCom_kCo_ENABLE
		UFCom_EnableButton( sPanel, sBuStartNm,		UFCom_kCo_ENABLE )						// 
	endif
	if ( bTrigMode == 0  &&    bAppendData	  &&    gbRunning )	// normal  SW triggered  mode, 
		Button	$sBuStopNm	win=$sPanel,	 title = "Stop",	disable = UFCom_kCo_ENABLE
		UFCom_EnableButton( sPanel, sBuStartNm,		UFCom_kCo_DISABLE )						// 
	endif

	if ( bTrigMode == 1	&&  ! bAppendData	&&   ! gbAcquiring )				// HW E3E4 triggered mode, 
		Button	$sBuStopNm	win=$sPanel,	 title = "Finish"
		UFCom_EnableButton( sPanel, sBuStartNm,		UFCom_kCo_DISABLE )						// 
	endif
	if ( bTrigMode == 1	&&  ! bAppendData	&&     gbAcquiring )				// HW E3E4 triggered mode, 
		Button	$sBuStopNm	win=$sPanel,	 title = "Stop",	disable = UFCom_kCo_ENABLE
		UFCom_EnableButton( sPanel, sBuStartNm,		UFCom_kCo_DISABLE )						// 
	endif
	if ( bTrigMode == 1	&&    bAppendData	&&   ! gbAcquiring )				// HW E3E4 triggered mode, 
		Button	$sBuStopNm	win=$sPanel,	 title = "Finish",	disable = UFCom_kCo_ENABLE
		UFCom_EnableButton( sPanel, sBuStartNm,		UFCom_kCo_DISABLE )						// 
	endif
	if ( bTrigMode == 1	&&    bAppendData	&&     gbAcquiring )				// HW E3E4 triggered mode, 
		Button	$sBuStopNm	win=$sPanel,	 title = "Stop",	disable = UFCom_kCo_ENABLE
		UFCom_EnableButton( sPanel, sBuStartNm,		UFCom_kCo_DISABLE )						// 
	endif

End


Function		SwitchTriggerMode( sSubFoC, sSubFoW )
	string  	sSubFoC, sSubFoW
	variable	hnd	= CedHandle()
	string  	sFo			= ksACQ
	variable	bTrigMode		= TrigMode()
	nvar		gbRunning	= $"root:uf:acq:" + UFPE_ksKEEP + ":gbRunning"
	nvar		gbAcquiring	= $"root:uf:acq:" + sSubFoC + ":gbAcquiring"
	string		sMode		= SelectString( bTrigMode, 	 "  to normal SW " , "  to HW E3E4  " )
	string		sAcq			= SelectString( gbAcquiring, " during pause" , " during acquisition" )

 	 printf "\t\tSwitchTriggerMode()\tbTrigMode : %.0lf     running: %.0lf    acquiring : %.0lf   \r", bTrigMode, gbRunning, gbAcquiring
 	StartStopFinishButtonTitles( sFo, sSubFoC )								// As the user has switched a basic mode  the button titles are updated 
 	FinishFiles()												// As the user has switched a basic mode  a new file is started

 	variable	bApplyScript	= UFCom_TRUE
// 2009-12-12
//	StopADDA( "\tFINISHING ACQUISITION  by  switching trigger mode" + sMode + sAcq , bApplyScript, sSubFoC, sSubFoW )	//   invoke   ApplyScript() 
	StopADDA_ns( "\tFINISHING ACQUISITION  by  switching trigger mode" + sMode + sAcq , bApplyScript, hnd )	//   invoke   ApplyScript() 
End



	Function		QuickAcqCheck( sFo, wRaw, lllstIO )
		// Extra window for detection of acquisition errors including telegraph channels.  'Display raw data after acq' also works but does not display the telegraph channels. 
		// You must kill the window before each acquisition because to avoid graph updating which slows down the acquisition process appreciably.  
		string  	sFo, lllstIO
		wave	wRaw
//todo: 	
	variable	sc = 0	
		wave  	wG		= $FoWvNmWgNs( sFo )
// 2009-12-12
//		wave  /T	wIO		= $"root:uf:" + sFo + ":ar:wIO"  			// This  'wIO'   	is valid in FPulse ( Acquisition )
		nvar		gnCompress		= root:uf:acq:cons:gnCompressTG	
		variable	nSmpInt			= wG[ UFPE_WG_SI ]
		variable	nCntAD			= wG[ UFPE_WG_CNTAD ]	
		variable	nCntTG			= wG[ UFPE_WG_CNTTG ]	
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
// 2009-12-12
//			sWaveNm		 = ADTGNm( wG, wIO, c )
			sWaveNm		 = UFPE_FoAcqDA( sFo, sc, lllstIO, c )
			sFolderWaveNm = UFPE_FoAcqADTG( sFo, sc, lllstIO, c, nCntAD )
			red		= 64000 * ( c== 0 ) + 64000  * ( c== 3 ) + 64000  * ( c== 4 )
			green	= 64000 * ( c== 1 ) + 64000  * ( c== 4 ) + 64000  * ( c== 5 )
			blue		= 64000 * ( c== 2 ) + 64000  * ( c== 5 ) + 64000  * ( c== 3 ) 
			AppendToGraph $sFolderWaveNm
			ModifyGraph rgb( $sWaveNm )	= ( red, green, blue )
			SetScale /I x , 0, numPnts( $sFolderWaveNm ) * nSmpInt / 1e6 , "s", $sFolderWaveNm
		endfor
		for ( c = nCntAD; c < nCntAD + nCntTG; c += 1)	
// 2009-12-12
//			sWaveNm		 = ADTGNm( wG, wIO, c )
			sWaveNm		 = UFPE_FoAcqDA( sFo, sc, lllstIO, c )
			sFolderWaveNm = UFPE_FoAcqADTG( sFo, sc, lllstIO, c, nCntAD )
			red		= 64000 * ( c== 0 ) + 64000  * ( c== 3 ) + 64000  * ( c== 4 )
			green	= 64000 * ( c== 1 ) + 64000  * ( c== 4 ) + 64000  * ( c== 5 )
			blue		= 64000 * ( c== 2 ) + 64000  * ( c== 5 ) + 64000  * ( c== 3 ) 
			AppendToGraph $sFolderWaveNm
			ModifyGraph rgb( $sWaveNm )	= ( red, green, blue )
			SetScale /I x , 0, numPnts( $sFolderWaveNm ) * gnCompress * nSmpInt / 1e6 , "s" , $sFolderWaveNm
		endfor
		// printf "\t\tQuickAcqCheck(): displays window for acq error detection including telegraph channels. Kill this window before every acq for maximum speed.\r" 
	End

	
Function		ShowTimingStatistics_ns( sFo )
	string  	sFo
	string  	sFoCo	= UFPE_ksCOns
	wave  	wG		= $FoWvNmWgNs( sFo )
	variable	nProts			= UFPE_Prots( sFo )
//	nvar		gnReps			= $"root:uf:" + sFo + ":" + sFoCo + ":gnReps"
	nvar		gnReps			= $UFCom_ksROOT_UF_  + sFo + ":" + sFoCo + ":gnReps"
	nvar	 	gChnkPerRep		= $"root:uf:" + sFo + ":" + sFoCo + ":gChnkPerRep"
	nvar		gPntPerChnk	 	= $"root:uf:" + sFo + ":" + sFoCo + ":gPntPerChnk"
	variable	nSmpInt			= wG[ UFPE_WG_SI ]
	variable	nCntDA			= wG[ UFPE_WG_CNTDA ]	
	variable	nCntAD			= wG[ UFPE_WG_CNTAD ]	
	variable	nCntTG			= wG[ UFPE_WG_CNTTG ]	
	nvar		gnCompress		= $"root:uf:" + sFo + ":" + sFoCo + ":gnCompressTG"
	nvar		gReserve			= $"root:uf:" + sFo + ":" + sFoCo + ":gReserve"
	nvar		gMinReserve		= $"root:uf:" + sFo + ":" + sFoCo + ":gMinReserve"
	nvar		gMaxSmpPtspChan	= $"root:uf:" + sFo + ":" + sFoCo + ":gMaxSmpPtspChan"
	nvar		gbShowTimingStats	= $"root:uf:" + sFo + ":mis:TimeStats0000"
	variable	nTransConvPtsPerCh	= gChnkPerRep * gPntPerChnk * gnReps
	variable	nTransConvChs		= nCntAD+ nCntDA + nCntTG / gnCompress
	variable	nTransferPts		= nTransConvPtsPerCh * nTransConvChs
	variable	nConvolvePts		= nTransConvPtsPerCh * nTransConvChs
	svar		lllstTapeTimes		= $"root:uf:" + sFo + ":" + "lllstTapeTimes" 	
	svar		llstBLF			= $"root:uf:" + sFo + ":" + "llstBLF" 	
	variable	nCFSWritePtsPerCh 	= TotalTapePts_ns( sFo, nSmpInt, llstBLF, lllstTapeTimes ) * nProts	// this number of points is valid for Writing AND Processing
	variable	nGraphicsPtsPerCh 	= TotalTapePts_ns( sFo, nSmpInt, llstBLF, lllstTapeTimes ) * nProts
	variable	nCFSWritePts		= nCFSWritePtsPerCh *  nCntAD 
	variable	nGraphicsPts		= nGraphicsPtsPerCh *  nCntAD // todo not correct: DAC may also be displayed, superimposed sweeps not included 
	variable	TransferTime		= UFCom_ReadTimer( sFo, "Transfer" )
	variable	ConvolveTime		= UFCom_ReadTimer( sFo, "Convolve" )
	variable	GraphicsTime		= UFCom_ReadTimer( sFo, "Graphics" )
	variable	CFSWriteTime		= UFCom_ReadTimer( sFo, "CFSWrite" )
	variable	OnlineAnTime		= UFCom_ReadTimer( sFo, "OnlineAn" )
	//variable	FreeUseTime		= UFCom_ReadTimer( sFo, "FreeUse" )
	variable	ProcessTime		= UFCom_ReadTimer( sFo, "Process" )
	variable	InRoutinesTime		= TransferTime + ConvolveTime + CFSWriteTime + GraphicsTime + ProcessTime 	
	variable	ProtocolTotalTime	= nTransConvPtsPerCh * nSmpInt / 1000
	variable	ProtocolStoredTime	= nCFSWritePtsPerCh * nSmpInt / 1000
	variable	AttemptedADRate	= 1000 * nCntAD / nSmpInt
	variable	AttemptedFileSize	= AttemptedADRate * ProtocolStoredTime * 2 / 1024 / 1024
	variable	TAused			= TAUse( gPntPerChnk, nCntDA, nCntAD, cMAX_TAREA_PTS )
	variable	MemUsed			= MemUse( gChnkPerRep, gPntPerChnk, gMaxSmpPtspChan )

	UFCom_StopTimer( sFo, "TotalADDA" )		
	UFCom_PrintAllTimers( sFo, 0 )
	if ( gbShowTimingStats )
		printf "\t\tTIMING STATISTICS ( Prots:%2d , Rep:%2d ,  CpR:%2d , PtpChk:%6d / %d ,  %d us,  %.1lf MB,  Reserve:%d / %d / %d, TA:%d%%, Mem:%d%% ) \r", nProts, gnReps, gChnkPerRep, gPntPerChnk, gPntPerChnk * ( nCntAD + nCntTG ), nSmpInt, AttemptedFileSize, gMinReserve, gReserve, gChnkPerRep, TAUsed, MemUsed
		printf  "\t\tTransfer:  \t\t%3.2lf\tch *\t%7d\t=\t%7d\tpts\t%8.0lf\tms  -> %5.2lf\t/ %5.2lf\tus / pt \t= %5.1lf\t%% of SI \r", nTransConvChs,   nTransConvPtsPerCh,   nTransferPts,   TransferTime,  TransferTime / nTransferPts * 1000,   TransferTime / nTransConvPtsPerCh * 1000 ,   TransferTime / nTransConvPtsPerCh / nSmpInt * 100000
		printf  "\t\tConvolve:\t\t%3.2lf\tch *\t%7d\t=\t%7d\tpts\t%8.0lf\tms  -> %5.2lf\t/ %5.2lf\tus / pt \t= %5.1lf\t%% of SI  \r",  nTransConvChs, nTransConvPtsPerCh, nConvolvePts, ConvolveTime, ConvolveTime / nConvolvePts * 1000, ConvolveTime / nTransConvPtsPerCh * 1000, ConvolveTime / nTransConvPtsPerCh / nSmpInt * 100000
		printf  "\t\tGraphics: \t \t%3d \tch *\t%7d\t=\t%7d\tpts\t%8.0lf\tms  -> %5.2lf\t/ %5.2lf\tus / pt \t= %5.1lf\t%% of SI  \r", nCntAD, nGraphicsPtsPerCh, nGraphicsPts, GraphicsTime, GraphicsTime / nGraphicsPts * 1000, GraphicsTime / nGraphicsPtsPerCh * 1000, GraphicsTime / nGraphicsPtsPerCh /nSmpInt * 100000
		printf  "\t\tOnlineAnal: \t%3d \tch *\t%7d\t=\t%7d\tpts\t%8.0lf\tms  -> %5.2lf\t/ %5.2lf\tus / pt \t= %5.1lf\t%% of SI  \r", nCntAD, nCFSWritePtsPerCh, nCFSWritePts, OnlineAnTime, OnlineAnTime / nCFSWritePts * 1000, OnlineAnTime / nCFSWritePtsPerCh * 1000, OnlineAnTime / nCFSWritePtsPerCh / nSmpInt * 100000 
		printf  "\t\tCfsWrite:  \t\t%3d \tch *\t%7d\t=\t%7d\tpts\t%8.0lf\tms  -> %5.2lf\t/ %5.2lf\tus / pt \t= %5.1lf\t%% of SI  \r", nCntAD, nCFSWritePtsPerCh, nCFSWritePts, CFSWriteTime, CFSWriteTime / nCFSWritePts * 1000, CFSWriteTime / nCFSWritePtsPerCh * 1000, CFSWriteTime / nCFSWritePtsPerCh / nSmpInt * 100000 
		// printf"\t\tFreeUse:  \t%3d \tch *\t%7d\t=\t%7d\tpts\t%8.0lf\tms  -> %5.2lf\t/ %5.2lf\tus / pt \t= %5.1lf\t%% of SI  \r", nCntAD, nCFSWritePtsPerCh, nCFSWritePts, FreeUseTime, FreeUseTime / nCFSWritePts * 1000, FreeUseTime / nCFSWritePtsPerCh * 1000, FreeUseTime / nCFSWritePtsPerCh / nSmpInt * 100000 
		printf  "\t\tProcessing: \t%3d \tch *\t%7d\t=\t%7d\tpts\t%8.0lf\tms  -> %5.2lf\t/ %5.2lf\tus / pt \t= %5.1lf\t%% of SI  \r", nCntAD, nCFSWritePtsPerCh, nGraphicsPts, ProcessTime, ProcessTime / nCFSWritePts * 1000, ProcessTime / nCFSWritePtsPerCh * 1000, ProcessTime / nCFSWritePtsPerCh / nSmpInt * 100000 
		printf  "\t\tProtocol(total/stored):\t%d / %d ms  \tMeasured(routines): %d = %.1lf%% \t\tMeasured(overall): %d = %.1lf%% \r", ProtocolTotalTime,  ProtocolStoredTime, InRoutinesTime,  InRoutinesTime / ProtocolTotalTime * 100, UFCom_ReadTimer( sFo, "TotalADDA" ), UFCom_ReadTimer( sFo, "TotalADDA" )/ ProtocolTotalTime * 100
	endif
End

	constant		DADIREC = 0, ADDIREC = 1		// same as in XOP MWave.C

static Function	ConvolveBuffersDA_ns( sFo, sc, lllstIO, nChunk, nRep, nReps, nChunksPerRep, nChs, PtpChk, wRaw, nHostOfs, nPnts )
// mixes points of all  separate DAC-channel stimulus waves  together in small wave ' wRaw'  in transfer area 
	string  	sFo, lllstIO
	variable	sc
	variable	nChunk, nRep, nReps, nChunksPerRep, nChs, PtpChk, nHostOfs, nPnts
	wave	wRaw
	variable	pt, begPt	  	= PtpChk  * nChunk					// BegPt and EndPt are points in the CED sampling area (typ. 16MB) ....
	variable	endPt	 	= PtpChk * ( nChunk + 1 )				// The same BegPt and EndPt are passed multiple times if nReps is >1 (=long scripts and/or many protocols)
	variable	repOs	 	= nRep * PtpChk * nChunksPerRep		// BegPt and EndPt  PLUS the repetition offset 'repOs' gives the true point number in the DAC wave independently from the CED sampling area size
	variable	DACRange 	= 10								// + - Volt
	variable	c,	nIO	 	= kSC_DAC
	//printf "\t\tConvDA( \tEB:%d\tc:%d\t\tChnk:%2d\tnRep:%2d/%2d\tCPRep:%2d\tnChs:%d\tPtpChk:%5d\tnHostOfs:%5d\tbeg:\t%8d\tend:\t%8d\trOs: %10d  \twRaw:%5dpts\tnPnts:\t%8d \r", ELIMINATE_BLANKS(), c, nChunk, nRep, nReps, nChunksPerRep, nChs, PtpChk, nHostOfs, begpt, endpt, repOs, numPnts( wRaw ), nPnts
	for ( c = 0; c < nChs; c += 1 )
		variable	ofs		= c + nHostOfs 
		variable	yscl		=  UFPE_iov_ns( lllstIO, nio, c, kSC_IO_GAIN ) * UFPE_kMAXAMPL / 1000 / DACRange						// scale  in mV
		wave	wDacReal	= $UFPE_FoAcqDA( sFo, sc, lllstIO, c  ) 								
		// printf "\t\tConvolveBuffersDA_ns   \tc:%d\t%g\t%g\t%g\t%g\t%g\t%g\t%g\t%g\t\r", c, wDacReal[0],wDacReal[1],wDacReal[2],wDacReal[3],wDacReal[4],wDacReal[5],wDacReal[6],wDacReal[7]
		// printf "\t\t\t\tAcqDA Cnv>DA14>Cpy\t %10d  \t%8d",  2*begPt, 2*(mod(begPt,(2*PtpChk))+ofs)	

		variable	code		= UFCom_UtilConvolve( wDacReal, wRaw, DADIREC, nChs, 0, begPt, endPt, RepOs, PtpChk, ofs, yscl, 0, 0, 0, nPnts, 0 )// ~ 40ns / data point  (last params: ..., yscl, nCompress, nChunk, c, nPnts, bStoreIt )
		if ( code )
			printf "****Error: UFCom_UtilConvolve() DA returns %d (%g)  \r", code, code
		endif
//		 for ( pt =   begPt;  pt < endPt;   pt += 1 )
//			variable	pt1	= mod( pt + repOs, wG[ UFPE_WG_PNTS ] )									// Simple code without compression
//			wRaw[ mod( pt, (2*PtpChk)) * nChs + ofs ]  = wDacReal[ trunc( pt1 / SmpF ) ] * yscl					// ~ 4 us  / data point  (KEEP: including SmpF)
//		 endfor
	endfor
	return	endPt  + repOs
End


static Function	ConvolveBuffersDA_eb2( sFo, sc, lllstIO, nChunk, nRep, nReps, nChunksPerRep, nChs, PtpChk, wRaw, nHostOfs, nPnts, BegTrue, BPoints, SmpArOfsDA, bStoreEpi, begTape, hnd )
// mixes points of all  separate DAC-channel stimulus waves  together in small wave ' wRaw'  in transfer area.  wRaw is trueTime, it also contains nostore periods.
// the XOP requires ~30ns/pt, Igor loop ~500ns/pt (4GHz), Igor wave arithmetic??? (Xop drawback: if DA, AD and TG are all 3 Xops Igor does no longer update the 'Raw data display' during the acquisition
	string  	sFo, lllstIO
	variable	sc
	variable	nChunk		// 0...PtpChk-1  ,  is index in Sampling area.   The sampling area is looped  'nReps'  times  to deliver the entire stimulus,  so to access any point in the stimulus an index like   nReps * nChunksPerRep * PtpChk   is required 
	variable	nRep, nReps, nChunksPerRep, nChs, PtpChk, nHostOfs, nPnts, BegTrue, BPoints, SmpArOfsDA, bStoreEpi, begTape, hnd
	wave	wRaw

	variable	DACRange 		= 10							// + - Volt
	variable	c,  nIO	 		= kSC_DAC
	variable	pt, ptBigIO, nRawIdx, SmpF	= 1
	string  	buf	= ""

	variable	InChkBeg		= mod( BegTrue, PtpChk )				//
	variable	InChkEnd		= InChkBeg + BPoints				//
	variable	repOs	 	= nRep * PtpChk * nChunksPerRep		// BegPt and EndPt  PLUS the repetition offset 'repOs' gives the true point number in the DAC wave independently from the CED sampling area size

	//printf "\t\tConvDA( \tc:%d\t\t\tChnk:%2d\tnRep:%2d\tCPRep:%2d\tnChs:%d\tPtpChk:%5d\tnHostOfs:%5d\tbeg:%6d\tend:%6d\trOs: %10d  \twRaw:%5dpts\tnPnts:\t%8d\t%s\tpts:\t%8d\t \r", c, nChunk, nRep, nChunksPerRep, nChs, PtpChk, nHostOfs, begpt, endpt, repOs, numPnts( wRaw ), nPnts, sBigIo, numpnts( $sBigIO)
	//printf "\t\tConvDA( \tc:%d\t\t\tChnk:%2d\tnRep:%2d\tCPRep:%2d\tnChs:%d\tPtpChk:%5d\tnHostOfs:%5d\tbeg:%6d\tend:%6d\trOs: %10d  \twRaw:%5dpts\tnPnts:\t%8d\t%s\tpts:\t%8d\t \r", c, nChunk, nRep, nChunksPerRep, nChs, PtpChk, nHostOfs, BegTrue, endpt, repOs, numPnts( wRaw ), nPnts, sBigIo, numpnts( $sBigIO)
	// Mix points of all  separate DAC-channel stimulus waves  together in small transfer area  wave  'wRaw' 
	for ( c = 0; c < nChs; c += 1 )
		variable	ofs		=  c + nHostOfs 
		variable	yscl		=  UFPE_iov_ns( lllstIO, nio, c, kSC_IO_GAIN ) * UFPE_kMAXAMPL / 1000 / DACRange	// scale  in mV
		string  	sBigIO	=  UFPE_FoAcqDA( sFo, sc, lllstIO, c  ) 										// accesses 'bigio'
		wave	wBigIO	= $sBigIO
		variable	begPt	= PtpChk * nChunk  +  InChkBeg							// BegPt and EndPt are points in the CED sampling area (typ. 16MB) ....
		variable	endPt	= PtpChk * nChunk  +  InChkEnd							// The same BegPt and EndPt are passed multiple times if nReps is >1 (=long scripts and/or many protocols)
		 if ( c == 0 )
			//printf "\t\tConvDA  \tc:%d\t\t\tChnk:%2d\tnRep:%2d\tCPRep:%2d\tnChs:%d\tPtpChk:%5d\tnHostOfs:%5d\tbeg:\t%8d\tend:\t%8d\t[%7d]\tbio:\t%8d\tbtp:\t%8d\tst:%d\trOs: %10d  \trid:\t%8d\twRaw:%5dpts\tnPt:\t%8d\tpts:\t%8d\t%s\t \r",c,nChunk,nRep,nChunksPerRep,nChs,PtpChk, nHostOfs, begpt, endpt, BPoints, ptBigIO, begTape,bStoreEpi, repOs, nRawIdx, numPnts(wRaw), nPnts, numpnts($sBigIO),sBigIo
			//printf "\t\tConvDA  \tc:%d\t\t\tChnk:%2d\tnRep:%2d\tCPRep:%2d\tnChs:%d\tPtpChk:%5d\tnHostOfs:%5d\tbeg:\t%8d\tend:\t%8d\twBigIO:\t%g\t%g\t%g\t%g\t%g\t%g\t%g\t%g\t\r", c, nChunk,nRep,nChunksPerRep,nChs,PtpChk, nHostOfs, begpt, endpt, wBigIO[0],wBigIO[1],wBigIO[2],wBigIO[3],wBigIO[4],wBigIO[5],wBigIO[6],wBigIO[7]
		 endif
		if ( bStoreEpi ) 

			// Convolving fast using an XOP
			UFCom_UtilConvolveDA( wBigIO, wRaw, nChs, begPt, endPt, PtpChk, ofs, yscl, SmpF, nPnts, begTape )// ~ 40ns / data point  (last params: ..., yscl, nCompress, nChunk, c, nPnts, bStoreIt )

			// Convolving slowly using a loop (KEEP FOR DEBUGGING!)
			// for ( pt = begPt;  pt < endPt;   pt += 1 )									// Loop through the CED sampling area     
			//	ptBigIO		= begTape + ( pt - begPt )	
			//	nRawIdx		= mod( pt, 2*PtpChk ) * nChs + ofs 
			//	// if ( c == 0  &&  pt == begPt )
			//	//	printf "\t\tConvDA .\tc:%d\t\t\tChnk:%2d\tnRep:%2d\tCPRep:%2d\tnChs:%d\tPtpChk:%5d\tnHostOfs:%5d\tbeg:\t%8d\tend:\t%8d\t[%7d]\tbio:\t%8d\tbtp:\t%8d\tst:%d\trOs: %10d  \trid:\t%8d\twRaw:%5dpts\tnPt:\t%8d\tpts:\t%8d\t%s\t \r",c,nChunk,nRep,nChunksPerRep,nChs,PtpChk, nHostOfs, begpt, endpt, BPoints, ptBigIO, begTape,bStoreEpi, repOs, nRawIdx, numPnts(wRaw), nPnts, numpnts($sBigIO),sBigIo
			//	 //endif
			//	wRaw[ nRawIdx ]  = wBigIO[ trunc( ptBigIO / SmpF ) ] * yscl					// ~ 4 us  / data point  (KEEP: including SmpF)
			// endfor
			//if ( begPt < endPt )
			//	variable	bgRaw = mod(begPt,2*PtpChk )*nChs+ofs,   endRaw = mod( endPt-1,2*PtpChk )*nChs+ofs 
			//	 //printf "\t\t\t\t\t\t\t\t\tDA\tBTr:\t%8d\tPts:\t%8d\tBTp:\t%8d\tr:%2d/%2d\tchk:%4d /%5d\t\t\t\tChs:%d /%2d  Pts:\t%8d\tRO:\t%8d\tst:\t%d\tICB:\t%8d\tSAr:\t%10d\t...\t%8d\t ~  wRaw[\t%8d\t..%8d ]\t <- wBigIO[%8d...]\r", BegTrue,BPoints,BegTape,nRep, nReps, nChunk,nChunksPerRep,c,nChs,nPnts,repOs,bStoreEpi,InChkBeg,begPt,endPt,bgRaw, endRaw, ptBigIO+begPt-endpt+1
			//endif

		endif
	endfor

	// Copy small transfer area  wave 'wRaw' ........
	variable	code = 0,  nPts, TfHoArStartByte, SmpArStartByte
	if ( CEDHandleIsOpen_ns() ) 
		nPts   			= ( InChkEnd - InChkBeg ) * nChs 
		// 2009-02-09  was badly wrong....
		//TfHoArStartByte   	= nHostOfs * 2	 + 2 * PtpChk * nChs * mod( nChunk, 2 )	+ 2 * InChkBeg					//  only  2 swaps, in bytes not points
		//SmpArStartByte   	= SmpArOfsDA   + 2 * PtpChk * nChs *	 	nChunk 		+ 2 * InChkBeg
		TfHoArStartByte   	= nHostOfs * 2	 + 2 * nChs * ( PtpChk *  mod( nChunk, 2 )	+  InChkBeg )					//  only  2 swaps, in bytes not points
		SmpArStartByte   	= SmpArOfsDA	 + 2 * nChs * ( PtpChk * 	 	nChunk 	+  InChkBeg )
		if ( nPts )	// there are lots of periods with length 0 
			string  	sStore	= SelectString( bStoreEpi," skip","store" ) 
			// printf "\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t[r:%3d\t/%3d,\tcpr: %d]\t%s\t%4d\t/%8d..\t%8d\tHo:\t%8d\tSm:\t%8d\tnPts:\t%8d\tHO:%5d\tbeg:\t%8d\tend:\t%8d\tBgTp+:\t%8d\t%8d\trOs:%10d\twRawPts:%5d\r", nRep, nReps, nChunksPerRep, sStore,nChunk, InChkBeg, InChkEnd, TfHoArStartByte, SmpArStartByte, nPts, nHostOfs,begpt,endpt,begTape,begTape+InChkBeg,repOs,numPnts(wRaw)
			if (	bStoreEpi )
				sprintf buf, "TO1401,%d,%d,%d;", TfHoArStartByte, 2*nPts, TfHoArStartByte ;  UFP_CedSendString( hnd, buf )	// store: copy  Dac data from host to Ced transferArea. Ced TransferArea and HostArea start at the same point
				code	+= GetAndInterpretAcqErrors( hnd, "SmpStart", "TO1401", nChunk, nReps * nChunksPerRep )
				// 2010-02-01 
				variable /G	$UFCom_ksROOT_UF_  + sFo + ":" + UFPE_ksCOns + ":BlankAmp" = wRaw[ TfHoArStartByte / 2 + npts - 1 ]// store: memorise and use the last 'Store' value as amplitude for the whole chunk / = following nostore period -> User must supply a short stub with desired amplitude
				// nvar BlankAmp  =  $UFCom_ksROOT_UF_  + sFo + ":" + UFPE_ksCOns + ":BlankAmp";     print "BlankAmp",  BlankAmp
			else
				// 2010-02-01 improved code allowing arbitrary Dac output value during NoStore periods
				// Version1 (fixed value is not good, but could be user settable) :  The amplitude for any dac during all NoStore periods is this hard-coded value 'BlankAmp'  (only the value 0 is useful)
				// variable	BlankAmp	= 0											// skip: we have no value for skip=nostore periods... (due to EB=2)
				// Version2 ( preferable )  :  The amplitude applied during the NoStore period is (for any dac) the last value of the preceding Store period ( 1 data point = duration of 1 sample interval) is sufficient
				nvar 		BlankAmp  =  $UFCom_ksROOT_UF_  + sFo + ":" + UFPE_ksCOns + ":BlankAmp"																		// skip: we have no value for skip=nostore periods... (due to EB=2)
				sprintf buf, "SS2,C,%d,%d,%d;", 	   TfHoArStartByte, 2*nPts, BlankAmp;  	UFP_CedSendString( hnd, buf )  	// skip: fill Ced transferArea with constant 'Blank' amplitude as memorised above. This is MUCH faster than the above 'TO1401' which is very slow
				code	+= GetAndInterpretAcqErrors( hnd, "SmpStart", "SS2    ", nChunk, nReps * nChunksPerRep )
			endif
			 sprintf buf,  "SM2,C,%d,%d,%d;", SmpArStartByte, TfHoArStartByte, 2*nPts;   UFP_CedSendString( hnd, buf )  	 // store and skip: copy  Dac data from Ced transfer area to large sample area
			 code	+= GetAndInterpretAcqErrors( hnd, "SmpStart", "SM2 Dac", nChunk, nReps * nChunksPerRep )
		endif
	endif
	return	code
End


static Function	DeconvolveBuffsAD_eb2( sFo, sc, lllstIOTG, nChunk, nRep, nReps, nChunksPerRep, PtpChk, wRaw, nHostOfs, nCntAD, nCntTG, nCompress, nPnts, BegTrue, BPoints, BegTape, hnd )
// extracts mixed points of all true  AD channels from 'wRaw' transfer area into separate IGOR AD waves. .  AD extraction is different from TG extraction: AD recognises store/nostore sections, TG ignores store/nostore sections
// the XOP requires ~30ns/pt, Igor loop ~500ns/pt (4GHz), Igor wave arithmetic??? (Xop drawback: if DA,AD and TG are all 3 Xops Igor does no longer update the 'Raw data display' during the acquisition
	string  	sFo, lllstIOTG
	variable	sc, hnd
	variable	nChunk, nRep, nReps, nChunksPerRep, PtpChk, nHostOfs, nCntAD, nCntTG, nCompress, nPnts, BegTrue, BPoints, BegTape
	wave	wRaw
	variable	nChs			= nCntAD + nCntTG
	variable	InChkBeg		= mod( BegTrue, PtpChk )				//
	variable	InChkEnd		= InChkBeg + BPoints				// 
	variable	pt, BegPt		= PtpChk * nChunk + InChkBeg
	variable	EndPt		= PtpChk * nChunk + InChkEnd
	variable	nRawIdx,  ptBigIo
	variable	RepOs		= nRep * PtpChk * nChunksPerRep		// BegPt and EndPt  PLUS the repetition offset 'repOs' gives the true point number in the DAC wave independently from the CED sampling area size
	variable	c = 0,  yscl	=  UFPE_kMAXAMPL / UFPE_kFULLSCL_mV	// scale in mV
	variable	ofs = nHostOfs,  nSrcStartOfChan,  nSrcIndexOfChan
	string		sTxt = "ad..",  sRealWvNm	= ""
		
	for ( c = 0; c < nCntAD; c += 1 )								// ASSUMPTION: order of channels is first ALL AD, afterwards ALL TG in  UFCom_UtilConvolve()
		wave   wBigIO	= $UFPE_FoAcqADTG( sFo, sc, lllstIOTG, c, nCntAD )
		// Fast code using an XOP
		variable	code	= UFCom_UtilConvolveAD( wBigIO, wRaw, nCntAD, nCntTG, BegPt, EndPt, PtpChk, nHostOfs, yscl, nCompress, nChunk, c, nPnts, BegTape, InChkBeg )	// ~ 40ns / data point
		// Slow code using a loop (keep only for debugging)
		// for ( pt = begPt;  pt < endPt;   pt += 1 )											// Loop through the Transfer  area  
		 //	nRawIdx			=   mod( nChunk, 2 ) * ( nCntAD * PtpChk +  nCntTG * ( PtpChk / nCompress ) )   				+ c * PtpChk + ( pt - begPt ) + nHostOfs	+  InChkBeg
		//	ptBigIO			= begTape + ( pt - begPt )	
		//	wBigIO[ ptBigIO ]	= wRaw[ nRawIdx ] / yscl
		//	// printf "\t\t\t\t\t\t\t\t\t%s\tbTr:\t%8d\tpts:\t%8d\tbTp:\t%8d\tr:%2d/%2d\tchk:%4d /%5d\tchs:%d/%2d    pts:\t%8d\ticb:\t%8d\tsar:\t%10d\t...\t%8d\t hO:\t%8d\t-> ptIO:\t%8.1lf\tptR:\t%8.1lf\t\t\t\t%g \r",sTxt,BegTrue,BPoints,BegTape,nRep, nReps, nChunk,nChunksPerRep,c,nChs,nPnts,InChkBeg,begPt,endPt, nHostOfs, ptBigIO, nRawIdx, wBigIO[ptBigIO]	
		// endfor
		// printf "\t\t\t\t\t\t\t\t\t%s\tbTr:\t%8d\tpts:\t%8d\tbTp:\t%8d\tr:%2d/%2d\tchk:%4d /%5d\tchs:%d/%2d    pts:\t%8d\trpo:\t%8d\ticb:\t%8d\tsar:\t%10d\t...\t%8d\t hO:\t%8d\t-> ptIO:\t%8.1lf\tptR:\t%8.1lf\t\t\t\t%g\t->ptAD:%d \r",sTxt,BegTrue,BPoints,BegTape,nRep,nReps,nChunk,nChunksPerRep,c,nChs,nPnts,repOs,InChkBeg,begPt,endPt,nHostOfs,ptBigIO,nRawIdx,wBigIO[ptBigIO],endPt+repOs 
	endfor
	return 	endPt  + repOs 
End


static Function	DeconvolveBuffsTG_eb2( sFo, sc, lllstIOTG, nChunk, nRep, nReps, nChunksPerRep, PtpChk, wRaw, nHostOfs, nCntAD, nCntTG, nCompress, nPnts, BegTrue, BPoints, BegTape )
// extracts mixed points of all  TG channels from 'wRaw' transfer area into separate IGOR Tg waves.  TG extraction is different from AD extraction: AD recognises store/nostore sections, TG ignores store/nostore sections (no InCnkBeg)
// the XOP requires ~30ns/pt, Igor loop ~500ns/pt (4GHz), Igor wave arithmetic??? (Xop drawback: if DA,AD and TG are all 3 Xops Igor does no longer update the 'Raw data display' during the acquisition
	string  	sFo, lllstIOTG
	variable	sc
	variable	nChunk, nRep, nReps, nChunksPerRep, PtpChk, nHostOfs, nCntAD, nCntTG, nCompress, nPnts, BegTrue, BPoints, BegTape
	wave	wRaw
	variable	nChs			= nCntAD + nCntTG
	variable	pt, BegPt		= PtpChk * nChunk
	variable	EndPt		= PtpChk * (nChunk + 1)
	variable	nRawIdx,  ptBigIo, value
	variable	RepOs		= nRep * PtpChk * nChunksPerRep		// BegPt and EndPt  PLUS the repetition offset 'repOs' gives the true point number in the DAC wave independently from the CED sampling area size
	variable	c = 0,  yscl	=  UFPE_kMAXAMPL / UFPE_kFULLSCL_mV	// scale in mV
	variable	ofs = nHostOfs,  nSrcStartOfChan,  nSrcIndexOfChan
	string		sTxt= "tg.." , sRealWvNm	= ""
		
	for ( c = nCntAD; c < nCntAD + nCntTG; c += 1 )					// ASSUMPTION: order of channels is first ALL AD, afterwards ALL TG in  UFCom_UtilConvolve()
		wave   wBigIO	= $UFPE_FoAcqADTG( sFo, sc, lllstIOTG, c, nCntAD )
		// Decompress the few compressed TG values into the  full size BigIO  TG waves (same number of points as the true AD waves)
		// Fast code using an XOP
		variable	code	= UFCom_UtilConvolveTG( wBigIO, wRaw, nCntAD, nCntTG, BegPt, EndPt, PtpChk, nHostOfs, yscl, nCompress, nChunk, c, nPnts, BegTape )	// ~ 40ns / data point
		// Slow code using a loop (keep only for debugging)
		// for ( pt = begPt;  pt < endPt;   pt += 1 )											// Loop through the Transfer area 
		//	if ( mod( pt, nCompress ) == 0 )
		//	 	nRawIdx		= ( mod( nChunk, 2 ) * ( nCntAD * PtpChk +  nCntTG * ( PtpChk / nCompress ) ) ) +  nCntAD * PtpChk + ( ( c -  nCntAD ) * PtpChk ) / nCompress  +  ( pt - begPt ) / nCompress + nHostOfs 
		//		value		= wRaw[ nRawIdx ] / yscl
		//		//ptBigIO		=  ( begTape + ( pt - begPt ) ) 	// here ONLY for debug printing, remove together with following print line
		//		//wBigIO[ ptBigIO ] = value					// here ONLY for debug printing, remove together with following print line
		//		//printf "\t\t\t\t\t\t\t\t\t%s\tbTr:\t%8d\tpts:\t%8d\tbTp:\t%8d\tr:%2d/%2d\tchk:%4d /%5d\tchs:%d/%2d    pts:\t%8d\trpo:\t%8d\t\t\t\tsar:\t%10d\t...\t%8d\t hO:\t%8d\t-> ptIO:\t%8.1lf\tptR:\t%8.1lf\t%s\t%g\tpt:\t%8d\t \r",sTxt,BegTrue,BPoints,BegTape,nRep, nReps,nChunk,nChunksPerRep,c,nChs,nPnts,repOs,begPt,endPt,nHostOfs,ptBigIO,nRawIdx,sTxt,value,pt
		//	endif
		//	ptBigIO		=  ( begTape + ( pt - begPt ) ) 		// ptBigIo may exceed the array bounds which is  clipped automatically by Igor (but must be explicitly done in the XOP
		//	wBigIO[ ptBigIO ] = value
		// endfor
	// printf "\t\t\t\t\t\t\t\t\t%s\tbTr:\t%8d\tpts:\t%8d\tbTp:\t%8d\tr:%2d/%2d\tchk:%4d /%5d\tchs:%d/%2d    pts:\t%8d\trpo:\t%8d\t\t\t\tsar:\t%10d\t...\t%8d\t hO:\t%8d\t-> ptIO:\t%8.1lf\tptR:\t%8.1lf\t%s\t%g \r",sTxt,BegTrue,BPoints,BegTape,nRep, nReps,nChunk,nChunksPerRep,c,nChs,nPnts,repOs,begPt,endPt,nHostOfs,ptBigIO,nRawIdx,sTxt,value
	endfor
	return 	endPt  + repOs 
End


static Function	DeconvolveBuffsADTG_ns( sFo, sc, lllstIOTG, nChunk, nRep, nReps, nChunksPerRep, PtpChk, wRaw, nHostOfs, nCntAD, nCntTG, nCompress, nPnts )
// extracts mixed points of all ADC -  and  TG - channels from ' wRaw' transfer area into separate IGOR AD waves
	string  	sFo, lllstIOTG
	variable	sc
	variable	nChunk, nRep, nReps, nChunksPerRep, PtpChk, nHostOfs, nCntAD, nCntTG, nCompress, nPnts
	wave	wRaw
	variable	nChs			= nCntAD + nCntTG
	variable	pt, BegPt		= PtpChk  * nChunk
	variable	EndPt		= PtpChk * ( nChunk + 1 )
	variable	RepOs		= ( nRep - 1 ) * PtpChk * nChunksPerRep
	variable	nRawIdx,  ptBigIo = 0

	variable	bStoreIt, nBigChunk= ( BegPt + RepOs ) / PtpChk 
	if ( 	ELIMINATE_BLANKS() == 1 )								
		bStoreIt	= UFPE_StoreChunkorNot_ns( sFo, nBigChunk )				
	elseif ( ELIMINATE_BLANKS() == 0 )									
		bStoreIt	= 1
	endif

	variable	c = 0, yscl	=  UFPE_kMAXAMPL / UFPE_kFULLSCL_mV			// scale in mV
	variable	ofs =  nHostOfs,  nSrcStartOfChan, nSrcIndexOfChan
	string		sRealWvNm	= UFPE_FoAcqADTG( sFo, sc, lllstIOTG, c, nCntAD )
	string  	sTxt	= ""
	//printf "\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\tDeConvAD( \tc:%d\t'%s'\tnChunk:%2d\tnRep:%2d\tCPRep:%2d\tnChs:%d\tPtpChk:%5d\tnHostOfs:%5d\tbpt:\t%7d\tept:\t%7d\tBigChk:\t%7d\tStore: %d\t \r", c, sRealWvNm, nChunk, nRep, nChunksPerRep, nChs, PtpChk, nHostOfs, begpt, endpt, nBigChunk, bStoreIt
	//   printf "\t\t\t\t\t\t\t\t\t%s\tbTr:\t%8d\tpts:\t%8d\tbTp:\t%8d\tr:%2d/%2d\tchk:%4d /%5d\tbc:\t%4d\t\tchs:%d /%2d  pts:\t%8d\tro:\t%8d\tst:\t%d\ticb:\t%8d\tsar:\t%10d\t...\t%8d\t hostOfs:\t%8d\t\t\t\t%s \r", sTxt,0,0,0,nRep, nReps, nChunk,nChunksPerRep,nBigChunk,c,nChs,nPnts,repOs,bStoreIt,0,begPt,endPt, nHostOfs, sTxt

	// Fast code using an XOP
//	for ( c = 0; c < nCntAD + nCntTG; c += 1 )				// ASSUMPTION: order of channels is first ALL AD, afterwards ALL TG in  UFCom_UtilConvolve()
//		sRealWvNm	=  UFPE_FoAcqADTG( sFo, sc, lllstIOTG, c, nCntAD )
//		wave   wBigIO 	= $UFPE_FoAcqADTG( sFo, sc, lllstIOTG, c, nCntAD )	
//		sTxt	= SelectString( c < nCntAD, "tg.", "ad." )
//		   printf "\t\t\t\t\t\t\t\t\t%s\tbTr:\t%8d\tpts:\t%8d\tbTp:\t%8d\tr:%2d/%2d\tchk:%4d /%5d\tbc:\t%4d\t\tchs:%d /%2d  pts:\t%8d\tro:\t%8d\tst:\t%d\ticb:\t%8d\tsar:\t%10d\t...\t%8d\t hostOfs:\t%8d\t\t\t\t%s \r", sTxt,0,0,0,nRep, nReps, nChunk,nChunksPerRep,nBigChunk,c,nChs,nPnts,repOs,bStoreIt,0,begPt,endPt, nHostOfs, sTxt
//		// printf "\t\tDeConvAD_ns( \tc:%d\t'%s'\tnChunk: %3d\tnRep:%2d\tCPRep:%2d\tnChs:%d\tPtpChk:%5d\tnHostOfs:\t%9d\tbpt:\t%9d\tept:\t%9d\t np:\t%4d\tsto:%d\tad:%d\ttg:%d\tro:\t%4d\tco:%3d\t  \r", c, sRealWvNm, nChunk, nRep, nChunksPerRep, nChs, PtpChk, nHostOfs, begpt, endpt, nPnts, bStoreIt, nCntAD, nCntTG, RepOs, nCompress 
//		// UFCom_PrintWave( "PrintWave  a  DeConvAD  " + sRealWvNm, wReal )
//
//		// bStoreIt : Set  'Blank'  periods (=periods during which data were sampled but not transfered to host leading to erroneous data in the host area)  to  0  so that the displayed traces  look nice.  
//		variable	code	= UFCom_UtilConvolve( wBigIO, wRaw, ADDIREC, nCntAD, nCntTG, BegPt, EndPt, RepOs, PtpChk, nHostOfs, yscl, nCompress, nChunk, c, nPnts, bStoreIt )	// ~ 40ns / data point
//		if ( code )
//			printf "****Error: UFCom_UtilConvolve() AD returns %d (%g)  Is Nan:%d \r", code, code, numtype( code) == UFCom_kNUMTYPE_NAN
//		endif
//	endfor

	// Slow code using a loop (only for debugging)
	for ( c = 0; c < nCntAD + nCntTG; c += 1 )				// ASSUMPTION: order of channels is first ALL AD, afterwards ALL TG in  UFCom_UtilConvolve()
		wave   wBigIO	= $UFPE_FoAcqADTG( sFo, sc, lllstIOTG, c, nCntAD )
		// printf "\t\tDeConvAD_ns( \tc:%d\t'%s'\tnChunk: %3d\tnRep:%2d\tCPRep:%2d\tnChs:%d\tPtpChk:%5d\tnHostOfs:\t%9d\tbpt:\t%9d\tept:\t%9d\t np:\t%4d\tsto:%d\tad:%d\ttg:%d\tro:\t%4d\tco:%3d\t  \r", c, sRealWvNm, nChunk, nRep, nChunksPerRep, nChs, PtpChk, nHostOfs, begpt, endpt, nPnts, bStoreIt, nCntAD, nCntTG, RepOs, nCompress 
		//variable	code	= UFCom_UtilConvolve( wReal, wRaw, ADDIREC, nCntAD, nCntTG, BegPt, EndPt, RepOs, PtpChk, nHostOfs, yscl, nCompress, nChunk, c, nPnts, bStoreIt )	// ~ 40ns / data point
		if ( c < nCntAD )		// is true AD, not telegraph channel
			sTxt	= "ad."
			for ( pt = begPt;  pt < endPt;   pt += 1 )											// Loop through the CED sampling area      todo_b; waveform arithmetic or XOP
				ptBigIO			= mod( pt + repOs, nPnts )	
			 	nRawIdx			= mod( nChunk, 2 ) * ( nCntAD * PtpChk +  nCntTG * trunc( PtpChk / nCompress ) )   				+ c * PtpChk + ( pt - begPt ) + ofs  
				wBigIO[ ptBigIO ]	= wRaw[ nRawIdx ] / yscl
				// printf "\t\t\t\t\t\t\t\t\t%s\tbTr:\t%8d\tpts:\t%8d\tbTp:\t%8d\tr:%2d/%2d\tchk:%4d /%5d\tbc:\t%4d\t\tchs:%d /%2d  pts:\t%8d\tro:\t%8d\tst:\t%d\ticb:\t%8d\tsar:\t%10d\t...\t%8d\t hO:\t%8d\t-> ptIO:\t%8d\t?%8g\tptR:\t%8d \r",sTxt,0,0,0,nRep, nReps, nChunk,nChunksPerRep,nBigChunk,c,nChs,nPnts,repOs,bStoreIt,0,begPt,endPt, nHostOfs, ptBigIO, ptBigIO, nRawIdx
				// printf "\t\t\t\t\t\t\t\t\t%s\tbTr:\t%8d\tpts:\t%8d\tbTp:\t%8d\tr:%2d/%2d\tchk:%4d /%5d\tbc:\t%4d\t\tchs:%d /%2d  pts:\t%8d\tro:\t%8d\t\t%8d\tsar:\t%10d\t...\t%8d\t hostOfs:\t%8d\t\t\t -> wBigIO[%8g...]=%g \r",sTxt,BegTrue,BPoints,BegTape,nRep, nReps, nChunk,nChunksPerRep,nBigChunk,c,nChs,nPnts,repOs,begPt,endPt, nHostOfs, ptBigIO, wBigIO[ trunc( ptBigIO  ) ] 
			endfor
		else			// is  telegraph channel, not a true AD
			for ( pt = begPt;  pt < endPt;   pt += nCompress )											// Loop through the CED sampling area      todo_b; waveform arithmetic or XOP
				sTxt	= "tg."
				ptBigIO			= trunc( mod( pt + repOs, nPnts )	/ nCompress )
			 	nRawIdx			= ( mod( nChunk, 2 ) * ( nCntAD * PtpChk +  nCntTG * trunc( PtpChk / nCompress ) ) )  +  nCntAD * PtpChk + trunc( ( ( c - nCntAD ) * PtpChk ) / nCompress ) +  trunc( ( pt - begPt ) / nCompress ) + ofs 
				wBigIO[ ptBigIO ]	= wRaw[ nRawIdx ] / yscl
				 // printf "\t\t\t\t\t\t\t\t\t%s\tbTr:\t%8d\tpts:\t%8d\tbTp:\t%8d\tr:%2d/%2d\tchk:%4d /%5d\tbc:\t%4d\t\tchs:%d /%2d  pts:\t%8d\tro:\t%8d\tst:\t%d\ticb:\t%8d\tsar:\t%10d\t...\t%8d\t hO:\t%8d\t-> ptIO:\t%8d\t?%8g\tptR:\t%8d\t%s\t%g\r",sTxt,0,0,0,nRep, nReps,nChunk,nChunksPerRep,nBigChunk,c,nChs,nPnts,repOs,bStoreIt,0,begPt,endPt, nHostOfs, ptBigIO, ptBigIO, nRawIdx ,sTxt, wBigIO[ptBigIO]
				// printf "\t\t\t\t\t\t\t\t\t%s\tbTr:\t%8d\tpts:\t%8d\tbTp:\t%8d\tr:%2d/%2d\tchk:%4d /%5d\tbc:\t%4d\t\tchs:%d /%2d  pts:\t%8d\tro:\t%8d\t\t%8d\tsar:\t%10d\t...\t%8d\t hostOfs:\t%8d\t\t\t -> wBigIO[%8g...]=%g \r",sTxt,BegTrue,BPoints,BegTape,nRep, nReps, nChunk,nChunksPerRep,nBigChunk,c,nChs,nPnts,repOs,begPt,endPt, nHostOfs, ptBigIO, wBigIO[ trunc( ptBigIO  ) ] 
			endfor
		endif
	endfor

	return 	endPt  + repOs 
End




static constant		kFILTERING			= 10000	// 1 means ADC=DAC=no filtering,    200 means heavy filtering
static constant		kNOISEAMOUNT		= 0.002	// 0 means no noise,   1 means noise is appr. as large as signal   (for channel 0 )
static constant		kCHANGE_TG_SECS 	= 2		// gain switching by simulated telegraph channels will ocur with roughly this period


static Function	TestCopyRawDAC_ADC( wG, nChunk, PtpChk, wRaw, nDACHostOfs, nADCHostOfs )
// helper for test mode without CED1401: copies dac waves into adc waves
// Multiple Dac channels are implemented but not tested...
	wave	wG
	variable	nChunk, PtpChk, nDACHostOfs, nADCHostOfs
	wave	wRaw
	variable	nCntDA		= wG[ UFPE_WG_CNTDA ]	
	variable	nCntAD		= wG[ UFPE_WG_CNTAD ]	
	variable	nCntTG		= wG[ UFPE_WG_CNTTG ]	
	nvar		gnCompress	= root:uf:acq:cons:gnCompressTG
	variable	pt, ch, nChs 	= max( nCntDA, nCntAD ), indexADC, indexDAC, indexTG
	variable	nFakeTGvalue	= 27000 + 5000 * mod( trunc( ticks / kCHANGE_TG_SECS / 100), 2 ) // gain(27000):1, gain(32000):2,  gain(54000):gain50, gain(64000):200
	//variable	ADCRange	= 10						// + - Volt
	variable	yscl	=  UFPE_kMAXAMPL / UFPE_kFULLSCL_mV//1000 / ADCRange		// scale in mV

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

			indexDAC =  pt + (nChunk ) * min( ch, nCntDA - 1 ) * PtpChk +	nDACHostOfs		// it there is only 1 DA but more than 1 AD the DA is mapped to all ADs  with different amount of filtering and noise
			indexADC =  pt + ( nChunk * ( nCntAD + nCntTG - 1 ) +  ch ) * PtpChk + nADCHostOfs	// if there is only 1 AD it is mapped to DA0
	
			// filtering is implemented here to see a difference between DAC and ADC data
			//! integer arithmetic gives severe and very confusing rounding errors with amplitudes < 20
			// chan 0 : little noise, heavy filtering , chan 1 : medium noise, medium filtering,  chan 2 : much noise , little filtering
		 	wRaw[ indexADC ]  =  ChanFct / kFILTERING * wRaw[  indexDAC ] + ( 1 - ChanFct / kFILTERING ) * wRaw[ indexDAC - min( ch, nCntDA - 1 ) ]  + ChanFct * gNoise( V_avg  * kNOISEAMOUNT)  
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
	
	

static Function	/S	UFPE_FoAcqDA( sFo, sc, lllstIO, cio )
// Returns  wave name (including folder) for Dac  when  index  c = 0,1,2... (up to CntDA)  .   Accepts both  lllstIO  or  lllstIOTG
	string  	sFo, lllstIO
	variable	sc, cio
	variable	nio		= kSC_DAC
	string  	sIOType	= StringFromList( nio, klstSC_NIO )
	string  	sIONr	= StringFromList( kSC_IO_CHAN, StringFromList( cio, StringFromList( nio, lllstIO, "~" ) ) , "," ) 	
	return	WvNmOut( sFo, sIOType, sIONr, sc )
	//return	"root:uf:" + sFo + ":" + UFPE_ksF_IO + ":" + UFPE_ioItem( lllstIO, nIO, cio, nData )
End
	
Function	/S	UFPE_FoAcqADTG( sFo, sc, lllstIOTG, cio, nCntAD )
// Returns wave name (including folder) for Adc or telegraph wave  when  index  c = 0,1,2,3,4... (up to  CntAd+CntTG)  is given.   Accepts  ONLY  lllstIOTG	
// ASSUMPTION: order of channels is first ALL AD, afterwards ALL TG
	string  	sFo, lllstIOTG
	variable	sc, cio, nCntAD
	variable	nio		= kSC_ADC
	string  	sIOType	= StringFromList( nio, klstSC_NIO )
	string  	sIONr	= UFPE_ioItem( lllstIOTG, nio, cio, kSC_IO_CHAN ) + SelectString( cio < nCntAD,  "T", "" )		
	string  	sNm		= WvNmOut( sFo, sIOType, sIONr, sc ) 
	//  printf "\t\t\tUFPE_FoAcqADTG( \t'%s' \t\tcio:%d   sc:%2d )  \t->\tsIOType:'%s'  sIONr:'%s' \t->\t%s\t[%s]\r", sFo, cio, sc, sIOType, sIONr, UFCom_pd( sNm, 29), lllstIOTG 
	return	sNm
End
	
Function	/S	UFPE_FoAcqTg( sFo, sc, lllstIO, cio )
// Returns wave name (including folder) for telegraph wave  when  index  c = 0,1,2... (up to CntAD) of corresponding true AD wave  is given. 	 .   Accepts  only  lllstIO .  Accepts  lllstIOTG  only if  kSC_IO_TGCH is set.....
// ASSUMPTION: order of channels is first ALL AD without any TG in between
	string  	sFo, lllstIO
	variable	sc, cio
	variable	nio		= kSC_ADC
	string  	sIOType	= StringFromList( nio, klstSC_NIO )
	string  	sIONr	=  UFPE_ioItem( lllstIO, nio, cio, kSC_IO_TGCH ) + "T" 	
	string  	sNm		= WvNmOut( sFo, sIOType, sIONr, sc ) 
	// printf "\t\t\tUFPE_FoAcqTg( \t'%s' \t\tcio:%d   sc:%2d )  \t->\tsIOType:'%s'  sIONr:'%s' \t->\t%s\t[%s]\r", sFo, cio, sc, sIOType, sIONr, UFCom_pd( sNm, 29), lllstIO 
	return	sNm
End
	
static strconstant	sIOCHSEP			= "" 		// "_"	// separates Adc, Dac... and channel number ( only "_" or "", e.g. 'Dac_1' or 'Dac1' )

Function	/S	UFPE_FoAcqPoN( sFo, sc, lllstIO, cio, nCntAD )	 
 // Accepts only lllstIO ????		  (was UFPE_ioFldAcqioPoNio() )
 	string  	sFo, lllstIO
	variable	sc, cio, nCntAD
	variable	nio		= kSC_ADC
	string  	sIOType	= StringFromList( nio, klstSC_NIO )
//	string  	sIOType	="pon"
	string  	sIONr	=  UFPE_ioItem( lllstIO, nio, cio, kSC_IO_CHAN ) + "P" 	
	string  	sNm		= WvNmOut( sFo, sIOType, sIONr, sc ) 
//	string  	sNm		= "root:uf:" + sFo + ":" + UFPE_ksF_IO + ":" +  "PoN" + sIOCHSEP + UFPE_ioItem( lllstIO, nio, cio, kSC_IO_CHAN )
	// printf "\t\t\t\tUFPE_FoAcqPoN( \t'%s' \t\tcio:%d   sc:%2d )  \t->\tsIOType:'%s'  sIONr:'%s' \t->\t%s\t[%s]\r", sFo, cio, sc, sIOType, sIONr, UFCom_pd( sNm, 29), lllstIO 
	return	sNm
End

static Function		SupplyWavesADCandTG_ns( sFo, sc, wG, lllstIO, lllstIOTG, nPts )
	// supply  ADC and  ADC telegraph channel waves (as REAL)  here 
	string  	sFo, lllstIO, lllstIOTG
	wave	wG
	variable	nPts, sc
	variable	nProts		= UFPE_Prots( sFo )
	variable	nCntAD		= wG[ UFPE_WG_CNTAD ]	
	variable	nCntTG		= wG[ UFPE_WG_CNTTG ]	
	nvar		gnCompress	= root:uf:acq:cons:gnCompressTG
	variable	cio
	string		bf, sFoWvNm
	variable	nPnts
	nPnts	= ceil( nPts  / gnCompress )						// 2005-0128  Dimension 1 more instead of truncating. This last element is accessed in UFCom_UtilConvolve() . If not dimensioned sporadic crashes occur...
	
	for ( cio = 0; cio < nCntAD + nCntTG; cio += 1)	
if ( ELIMINATE_BLANKS() <= 1 )
		nPnts	= cio < nCntAD  ?  nPts  :   ceil( nPts  / gnCompress )	// 2005-0128  Dimension 1 more instead of truncating. This last element is accessed in UFCom_UtilConvolve() . If not dimensioned sporadic crashes occur...
else		// EB == 2
		nPnts	= nPts
endif
		sFoWvNm		= UFPE_FoAcqADTG( sFo, sc, lllstIOTG, cio, nCntAD )
		UFCom_PossiblyCreateFolder( UFCom_RemoveLastListItems( 1, sFoWvNm, ":" ) )	// the dac folder exists, but the adc folder does not yet exist
		if ( UFCom_Make1( sFoWvNm, nPnts, UFCom_kREAL32, 0, UFPE_kbOVERWRITE_WAVE, UFCom_kERR_FATAL ) )	// construct the wave with unique name (data type is 4 byte real)..	
			return 	UFCom_kERROR
		endif
//			if ( UFCom_DebugDepthSel() > 3  &&  UFCom_DebugVar( 0, "acq", "Ced" ) )
//			if ( UFCom_DebugVar( "acq", "Ced" ) > 8 )
			printf "\t\tCed SupplyWavesADCandTG: AdcTG \tbuild c:%d/%d\t%s\tshould have \t%5.1lf\tMB = \t%10d   \t pts , has been allocated \t%10d\tpts:\t%s\t[ Compressing:%3d \t(%3d) ] \r", cio, nCntAD+nCntTG, UFCom_pd(sFoWvNm,29), nPts * 4 / 1024 / 1024, nPts, numpnts($sFoWvNm), Time(), cio < nCntAD ? 1 : gnCompress, gnCompress 
//			endif
	endfor

	// Create the 'BigIO'  Pon waves
	for ( cio = 0; cio < nCntAD; cio += 1)	
 			if ( DoPoverN_ns( sFo, lllstIO, cio ) )
 			nPnts	= nPts
			sFoWvNm		= UFPE_FoAcqPon( sFo, sc, lllstIO, cio, nCntAD )
			UFCom_PossiblyCreateFolder( UFCom_RemoveLastListItems( 1, sFoWvNm, ":" ) )	// the dac folder exists, but the adc folder does not yet exist
			if ( UFCom_Make1( sFoWvNm, nPnts, UFCom_kREAL32, 0, UFPE_kbOVERWRITE_WAVE, UFCom_kERR_FATAL ) )	// construct the wave with unique name (data type is 4 byte real)..	
				return 	UFCom_kERROR
			endif
//			if ( UFCom_DebugDepthSel() > 3  &&  UFCom_DebugVar( 0, "acq", "Ced" ) )
//			if ( UFCom_DebugVar( "acq", "Ced" ) > 8 )
				printf "\t\tCed SupplyWavesADCandTG:    Pon   \tbuild c:%d/%d\t%s\tshould have \t%5.1lf\tMB = \t%10d   \t pts , has been allocated \t%10d\tpts:\t%s\t[ Compressing:%3d \t(%3d) ] \r", cio, nCntAD, 	UFCom_pd(sFoWvNm,29), nPts * 4 / 1024 / 1024, nPts, numpnts($sFoWvNm), Time(), cio < nCntAD ? 1 : gnCompress, gnCompress 
//			endif
		endif
	endfor




	return	0
End

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

static 	 constant	BYTES_PER_SLICE		 = 16
	
static	Function 		SetPoints( sFo, CedMaxSmpPts, nPnts, nSmpInt , nDA, nAD, nTG, nSlices, nErrorBad, nErrorFatal )
	// Given the number of data points to be transferred (=nPnts) , the CED memory size and any channel combinations.. 
	// ..we try to split 'nPnts'  into factors  'nReps'  *  'nChunkPerRep'  *  'xxx=CompPts'  *  'nCompress'
	// The assumption (which makes splitting impossible in rare cases but life easy after a suitable split is found) is that all repetions have equal number of chunks (='nChunkPerRep' )
	// The above split factors must meet certain conditions imposed by the available CED memory
	//	 - the number of points per chunk must fit into the transfer area 
	//	 - the number of points per chunk must fit into the sampling area
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

	string  	sFo
	variable	CedMaxSmpPts, nPnts, nSmpInt, nDA, nAD, nTG, nSlices, nErrorBad, nErrorFatal
	variable	gMaxReactnTime 	= MaxReactnTm() 
	variable	nProts			= UFPE_Prots( sFo )
	nvar		gnCompressTG		= root:uf:acq:cons:gnCompressTG
	nvar		gMaxSmpPtspChan	= root:uf:acq:cons:gMaxSmpPtspChan
	nvar		gnReps			= root:uf:acq:cons:gnReps
	nvar 		gChnkPerRep		= root:uf:acq:cons:gChnkPerRep
	nvar		gPntPerChnk		= root:uf:acq:cons:gPntPerChnk
	nvar	 	gnOfsDA			= root:uf:acq:cons:gnOfsDA
	nvar		gSmpArOfsDA		= root:uf:acq:cons:gSmpArOfsDA
	nvar 		gnOfsAD			= root:uf:acq:cons:gnOfsAD
	nvar		gSmpArOfsAD		= root:uf:acq:cons:gSmpArOfsAD
	nvar		gnOfsDO			= root:uf:acq:cons:gnOfsDO
	variable	nDAMem, nADMem,  SmpArEndDA,  SmpArEndAD, nDigoutMem, nTrfAreaBytes, TAUsed = 0, MemUsed = 0, FoM = 0, BestFoM = 0, nChunkTimeMS
	variable	nReps, MinReps, nChnkPerRep, nPntPerChnk, nChunks, MinNrChunks, nSumChs, EffChsM, EffChsTA, PtpChkM, PtpChkTA,  c, nCompress, nCompPts, HasPoints
	variable	bPrintIt	=   UFCom_FALSE
	string		bf

	gnCompressTG		= 255
	gMaxSmpPtspChan	= 0
	gnReps			= 0
	gChnkPerRep		= 0
	gPntPerChnk		= 0
	 printf "\t\t\tCed SetPoints(a) nSlices:%d  CedMaxSmpPts:%d   gnOfsDO:%d  \t \r", nSlices,  CedMaxSmpPts,   gnOfsDO

	nDigOutMem		= nSlices  * BYTES_PER_SLICE 
	gnOfsDO			= floor( ( CedMaxSmpPts * 2 - nDigOutMem ) / BYTES_PER_SLICE ) * BYTES_PER_SLICE	// 16 byte boundary is sufficient at the top end of the CED memory
	CedMaxSmpPts		= gnOfsDO / 2								// decrease sampling area by memory occupied by digout slices (=above gnOfsDO)
	 printf "\t\t\tCed SetPoints(b) nSlices:%d  CedMaxSmpPts:%d   gnOfsDO:%d  \t \r", nSlices,  CedMaxSmpPts,   gnOfsDO

	string		lstCompressFct
	string		lstPrimes	

// 2008-08-13 Is this correct  ????????????????????????????  todo_a 
	nPnts	= nPnts * nProts									//

	lstCompressFct	= CompressionFactors( nPnts, nAD, nTG )			// list containing all allowed compression factors

	if (  UFCom_DebugVar( "acq", "Ced" ) & 2 )
		printf "\t\t\tCed SetPoints   \t\t\t\t\tMxPts\t\tnPts\tSlc\t DA AD TG Cmp\tSum  MxPtpChan\t MinChk\tChunks\tMinRep\tREPS CHKpREP PTpCHK\t ChkTim\tTA%% M%% FoM \r"
	endif

	// Loop1(Compress): Divide  'nPnts'  by all possible compression factors to find those which leave no remainder
	BestFoM = 0
	for ( c = 0; c < ItemsInList( lstCompressFct ); c += 1 )

		nCompress	= str2num( StringFromList( c, lstCompressFct ) )
	
		// 2008-08-13
		if ( c > 0  &&  nCompress < MinCompression() )
			break
		endif
		
		nSumChs		= nAD + nDA + nTG
		EffChsM		= 2 * nDA + 2 * nAD + nTG + nTG / nCompress	// Determine the absolute minimum number of effective channels limited by the entire CED memory (= transfer area + sampling area )
		PtpChkM		= trunc( CedMaxSmpPts / EffChsM / 2 )		// Determine the absolute maximum PtsPerChk considering the entire Ced memory,  2 reserves space for the 2 swinging buffers
		EffChsTA		=  nDA + nAD + nTG / nCompress			// Determine the absolute minimum number of effective channels limited by the Transfer area
		PtpChkTA		= trunc( cMAX_TAREA_PTS / EffChsTA / 2 )	// Determine the absolute maximum PtsPerChk considering only the Transfer area ,  2 reserves space for the 2 swinging buffers
		nPntPerChnk	= min( PtpChkTA, PtpChkM )				// the lowest value of both and of the passed value is the new upper limit  for  PtsPerChk

		MinNrChunks	= ceil( nPnts / nPntPerChnk )				// e.g. maximum value for  1 DA, 2AD, 2TG/Compress: 1 UFPE_kMBYTE =   appr.  80000 POINTSPerChunk * 3.1 Channels *  2 swap halfs
		if (  UFCom_DebugVar( "acq", "Ced" ) & 2 )
			printf "\t\t\tCed SetPoints   \t\t\t\t\tMxPts\t\tnPts\tSlc\t DA AD TG Cmp\tSum  MxPtpChan\t MinChk\tChunks\tMinRep\tREPS CHKpREP PTpCHK\t ChkTim\tTA%% M%% FoM \r"
		endif
	
		gMaxSmpPtspChan	= trunc(  ( CedMaxSmpPts -  ( nDA + nAD  + nTG / nCompress ) * 2 * nPntPerChnk ) / nSumChs )	// subtract memory used by transfer area
	
		// Get the starting value for the Repetitions loop
		// the correct (=large enough) 'MinReps' value ensures that ALL possibilities found in the 'Rep' loop below are legal (=ALL fit into the CED memory) : none of them has later to be sorted out
		MinReps			= ceil( nPnts / gMaxSmpPtspChan )	
	
		nCompPts	= nPnts / nCompress
		// printf "old -> new \tCompress: %2d \tMinChunks:%2d \t-> %d \tMinReps:%2d \t-> %d  \r", nCompress, ceil( nPnts / nPntPerChnk ), ceil( nPnts*nProts / nPntPerChnk ),  ceil( nPnts / gMaxSmpPtspChan ), ceil( nPnts*nProts / gMaxSmpPtspChan )

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
			if ( nChunks == UFCom_kNOTFOUND )
				break								// Leave the loop as  'nCompPts'  was a prime number which cannot be processed. The 'FoM'  being 0  will  trigger an error to alert the user.
			endif
			nReps		= FindNextDividerBetween( nChunks, MinReps, nChunks / 3 )		// We use at least 3 chunks although we theoretically need only at least 2 chunks. We then avoid ChunksPerRep = 2 which works in principle but has in some cases too little 'gReserve'  for a reliable acquisition...
			if ( nReps == UFCom_kNOTFOUND )
				// printf "\t\t\t\tCed SetPoints(3) \tnCompTG:%3d , \tSum:%.3lf \tCmpPts:\t%7d\tnChunks: %.3lf \t-> %3d -> %3d , \t==Quot:\t%6d\tReps:%3d min\tCould not divide %3d / nReps \r", nCompress, EffChsTA, nCompPts, nPnts/ nPntPerChnk, MinNrChunks, nChunks, nCompPts / nChunks, MinReps, nChunks
				MinNrChunks	= nChunks+1
				continue								// Restart the loop
			endif
			nChnkPerRep	= nChunks / nReps				// we found a combination of  nReps and  ChnkPerRep which fits nChunks without remainder
			nPntPerChnk	= nPnts / nChunks  

			// printf "\t\t\t\tCed SetPoints(4) \tnCompTG:%3d , \tSum:%.3lf \tCmpPts:\t%7d\tnChunks: %.3lf \t\t   -> %3d , \t==Quot:\t%6d\tReps:%3d/%d\tChnk/Reps:\t%4d\t  PtpChk:%6d \r", nCompress, EffChsTA, nCompPts, nPnts/ nPntPerChnk,  nChunks, nCompPts / nChunks, MinReps, nReps, nChunks / nReps, nPntPerChnk	 

			nChunkTimeMS	= nPntPerChnk * nSmpInt / 1000
			MemUsed		= MemUse(  nChnkPerRep, nPntPerChnk, gMaxSmpPtspChan )
			TAused		= TAuse( nPntPerChnk, nDA, nAD, cMAX_TAREA_PTS ) 
			// Even when optimizing the reaction time  the FigureOfMerit  depends only on the memory usage. The reaction time is introduced as an  'too long' - 'OK' condition
			FoM			= FigureOfMerit( nChnkPerRep, nPntPerChnk, gMaxSmpPtspChan, nDA, nAD, nTG,  nCompress, cMAX_TAREA_PTS ) 

			if ( UFCom_DebugVar( "acq", "Ced" ) & 8 )
				printf "\t\t\t\t\tCed SetPoints(candi.)\t%10d\t%10d  %4d\t%4d%4d%5d%5d\t%5.3lf %10d\tminChunk:\t%6d\t%6d\t%6d\t%6d\t%6d\t%6d\tppc:\t%6d\tTA:\t%3.1lf\t%3d\t%6.1lf  \r", CedMaxSmpPts, nPnts, nSlices, nDA, nAD, nTG, nCompress, nDA+ nAD+nTG/nCompress,  gMaxSmpPtspChan, MinNrChunks, nReps * nChnkPerRep, MinReps, nReps, nChnkPerRep, nPntPerChnk, nChunkTimeMS, TAUsed, MemUsed, FoM
			endif

			MinNrChunks	= nChunks + 1					// When optimizing ONLY for high data rates: Comment out this line 

			if ( nChunkTimeMS <= gMaxReactnTime * 1000 )	// When optimizing ONLY for high data rates: Always true
				if ( FoM > BestFoM )
					gnCompressTG	= nCompress
					gnReps		= nReps	
					gChnkPerRep	= nChnkPerRep	
					gPntPerChnk	= nPntPerChnk  
					BestFoM		= FoM
				endif		
				break		// Leave the loop. The first  'nChunks'  and  the  first  'nReps'  found  (both having the lowest possible value)  have  best (=biggest) chunk size AND best sampling area memory usage: No need to go through the rest of the possibilities
			endif		

		while ( UFCom_TRUE ) 

	endfor	 		// next  smaller Compress factor

	nChunkTimeMS	= gPntPerChnk * nSmpInt / 1000
	MemUsed		= MemUse(  gChnkPerRep, gPntPerChnk, gMaxSmpPtspChan )
	TAused		= TAuse( gPntPerChnk, nDA, nAD, cMAX_TAREA_PTS ) 
	FoM			= FigureOfMerit( gChnkPerRep, gPntPerChnk, gMaxSmpPtspChan, nDA, nAD, nTG,  gnCompressTG, cMAX_TAREA_PTS ) 
	if ( UFCom_DebugVar( "acq", "Ced" ) & 2 )
		sprintf  bf, "\t\t\tCed SetPoints(final)\t\t\t%10d\t%10d  %4d\t%4d%4d%5d%5d\t%5.3lf %10d\t%6d\t%6d\t%6d\t%6d\t%6d\t%6d\t%6d\t%3d\t%3d\t%6.1lf ( incl. %d nProts)  \r", CedMaxSmpPts, nPnts, nSlices, nDA, nAD, nTG, gnCompressTG, nDA+ nAD+nTG/gnCompressTG,  gMaxSmpPtspChan, MinNrChunks, gnReps * gChnkPerRep, MinReps, gnReps, gChnkPerRep, gPntPerChnk, nChunkTimeMS, TAUsed, MemUsed, FoM, nProts
	endif

	// The following warning sorts out bad combinations which result from the 'Minimum chunk time' condition (> 1000 ms)
	// Example for bad splitting	: nPnts : 100000 -> many chunks : 10000  , few   pointsPerChk :       10 ,   ChunkTime : 2 ms . 
	// Good (=normal) splitting	: nPnts : 100000 -> few   chunks :       10  , many pointsPerChk : 10000 ,   ChunkTime : 900 ms 
	if ( gnReps * gChnkPerRep > gPntPerChnk   &&  gnReps > 1 ) 	// in the special case of few data points (=they fit with 1 repetition in the Ced memory) allow even few PtsPerChk in combination with many 'nChunk'
		sprintf bf, "Script has bad number of data points (%d) leading to poor performance. \r\tAdjust duration(s) in stimulus protocol slightly so that data points contains more small primes." , nPnts
		lstPrimes	= UFCom_FPPrimeFactors( sFo, nPnts )					// list containing the prime numbers which give 'nPnts'
		UFCom_FoAlert( sFo, nErrorBad,  bf + "   " + lstPrimes[0,50] )
		UFCom_Delay( 2 )										// time to read the message in the continuous test mode
	endif
	
	HasPoints		= gnReps * gChnkPerRep * gPntPerChnk  
	if ( HasPoints != nPnts )		
		sprintf bf, "The number of stimulus data points (%d) could not be divided into CED memory without remainder. \r\tAdjust duration(s) in stimulus protocol slightly so that data points contains more small primes." , nPnts
		lstPrimes	= UFCom_FPPrimeFactors( sFo, nPnts )					// list containing the prime numbers which give 'nPnts'
		UFCom_FoAlert( sFo, nErrorFatal,  bf + "   " + lstPrimes[0,50] )
		UFCom_Delay( 2 )										// time to read the message in the continuous test mode
		return  0
	endif

	// Now that the number of chunks, the number of repetitions, the  ChnksPerRep and the ChunkSize are determined...
	// ..we can split the available CED memory into the transfer area, the sampling area  and the area for the digout slices 
	nDAMem		= 2 * nDA * gPntPerChnk
	nADMem		= round( 2 * ( nAD + nTG / gnCompressTG ) * gPntPerChnk )
	gnOfsDA		= 0
	gnOfsAD		= 2 * ( gnOfsDA + nDAMem )	// *2 : swap buffers!!!					// the end of the DA transfer area is the start of the AD transfer area
	nTrfAreaBytes	= 2 * ( gnOfsDA + nDAMem + nADMem )

	if ( UFCom_DebugVar( "acq", "Ced" ) & 4 )
		printf "\t\t\t\tCed SetPoints  DA-TrfArOs:%d  Mem:%d (chs:%d)    AD-TrfArOs:%d  Mem:%d (chs:%d+%d)    -> TABytes:%d   [DigOs:%d=0x%06X] \r", gnOfsDA, nDAMem, nDA, gnOfsAD, nADMem,  nAD, nTG,  nTrfAreaBytes, gnOfsDO, gnOfsDO
	endif

	// build the areas one behind the other 
	gSmpArOfsDA	= nTrfAreaBytes												// if CED does not require sampling areas to start at 64KB borders
	SmpArEndDA	= gSmpArOfsDA + round( 2 * gChnkPerRep * gPntPerChnk * nDA  )		// uses memory ~number of channels (=as little memory as possible)
	gSmpArOfsAD	= SmpArEndDA												//  if CED does not require sampling areas to start at 64KB borders	
	SmpArEndAD 	= gSmpArOfsAD + round( 2 * gChnkPerRep * gPntPerChnk * ( nAD + nTG ) )		

	if ( UFCom_DebugVar( "acq", "Ced" ) & 4 )
		printf "\t\t\t\tCed SetPoints  TrArBytes:%d   SmpArDA:%d..%d=0x%06X..0x%06X  SmpArAD:%d..%d=0x%06X..0x%06X  gnOfsDO:%d \r", nTrfAreaBytes, gSmpArOfsDA, SmpArEndDA, gSmpArOfsDA, SmpArEndDA, gSmpArOfsAD, SmpArEndAD, gSmpArOfsAD, SmpArEndAD, gnOfsDO
	endif
	if ( nTrfAreaBytes > cMAX_TAREA_PTS * 2  ||  nTrfAreaBytes > gSmpArOfsDA  ||  SmpArEndDA > gSmpArOfsAD ||  SmpArEndAD > gnOfsDO )
		sprintf bf, "Memory partition error: Transfer area / Sampling area /  Digout area overlap:  %d < (%d) %d < %d < %d < %d < %d",  nTrfAreaBytes, cMAX_TAREA_PTS * 2, gSmpArOfsDA, SmpArEndDA, gSmpArOfsAD,  SmpArEndAD, gnOfsDO
		UFCom_InternalError( bf )
		printf "\t\t\t\tCed SetPoints  TrArBytes:%d   SmpArDA:%d..%d=0x%06X..0x%06X  SmpArAD:%d..%d=0x%06X..0x%06X  gnOfsDO:%d \r", nTrfAreaBytes, gSmpArOfsDA, SmpArEndDA, gSmpArOfsDA, SmpArEndDA, gSmpArOfsAD, SmpArEndAD, gSmpArOfsAD, SmpArEndAD, gnOfsDO 
		return	UFCom_kERROR
	endif

	return	nTrfAreaBytes / 2                       
End


static Function		FindNextDividerBetween( nBig, nMin, nMax )
// factorizes  'nBig'  and returns the factor closest (equal or larger) to  'nMin'  and  smaller or equal  'nMax' 
// Brute force: could be done easily by looping through numbers > nMin and checking if the remainder of  nBigs/numbers  is 0 . This is OK when  nBig <~ 1 000 000, otherwise is takes too long (>1 s)
// In the approach  taken  'nBig'  is first split into factors (which requires splitting into primes), then from the resulting factor list the factor closest to but greater or equal  'nMin' is picked.  Much faster for large 'nBig' 
	variable	nBig, nMin, nMax
	variable 	f, nFactor
	string		lstFactors	= UFCom_Factors( ksACQ, nBig )				// break  'nBig'  into factors, requires splitting into primes, lstFactors contains 'nBig'
	//for	( f = 0; f < ItemsInList( lstFactors )		; f += 1 )	// Version1 :  allow returning  'nBig'  if no other factor is found
	for 	( f = 0; f < ItemsInList( lstFactors ) - 1	; f += 1 )	// Version2 :  never return 'nBig'  even if no other factor is found (this option must be used when breaking 'nPnts' into 'chunks'  and  'Reps') 
		nFactor	= str2num( StringFromList( f, lstFactors ) )
		if ( nMin <= nFactor  &&  nFactor <= nMax )
			// printf "\t\t\t\t\tNextDividerBetween( %5d, \tnMin:%5d, \tnMax:%5d\t) -> found divider:%d   in   %s \r", nBig, nMin,nMax, nFactor, lstFactors[0, 180]
			return	nFactor
		endif
	endfor		
	// printf "\t\t\t\t\tNextDividerBetween( %5d, \tnMin:%5d, \tnMax:%5d\t) -> could not find divider between %5d\tand %5d \tin   %s \r", nBig, nMin,nMax, nMin,nMax, lstFactors[0, 180]
	return	UFCom_kNOTFOUND
End	

static Function		TAUse( PtpChunk, nDA, nAD, MaxAreaPts )
	variable	PtpChunk, nDA, nAD, MaxAreaPts 
	return	PtpChunk * (nDA + nAD ) * 2 / MaxAreaPts * 100	// the compressed TG channels are NOT included here as more TG points would erroneously increase TAUsage and FoM while actually deteriorating performance
End	

static Function		MemUse(  nChnkPerRep, nPntPerChnk, nMaxSmpPtspChan )
	variable	nChnkPerRep, nPntPerChnk, nMaxSmpPtspChan
	return	nChnkPerRep * nPntPerChnk / nMaxSmpPtspChan * 100 		
End

static Function		FigureOfMerit( nChnkPerRep, PtpChunk, nMaxSmpPtspChan, nDA, nAD, nTG,  Compress, MaxAreaPts )
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
	FoM		+= MemUse( nChnkPerRep, PtpChunk, nMaxSmpPtspChan ) * FoMFactorForMemoryUsage
	// printf "\t\tFoM( nChnkPerRep:%3d \tPtpChk:\t%8d\tnMaxSmpPtspChan:\t%10d\t  nDA:%d   nAD:%d   nTG:%d   Compress:%4d\t MaxAreaPts:%6d\t->  FoM:%.1lf  \r"  , nChnkPerRep, PtpChunk, nMaxSmpPtspChan, nDA, nAD, nTG,  Compress, MaxAreaPts, FoM
	return	FoM
End


static Function  /S	CompressionFactors( nPnts, nAD, nTG )	
// build list containing all allowed compression factors
	variable	nPnts, nAD, nTG	
	string		lstCompressFct	= ""
	// Determine the absolute maximum limit for the compression factor
	variable	n, nMaxCompressTG
	if ( nAD + nTG == 0 )								// 2005-1202
		nMaxCompressTG	= cFAST_TG_COMPRESS		// 2005-1202
	else
		nMaxCompressTG	= trunc ( min( cFAST_TG_COMPRESS * ( nAD + nTG ) , 255 ) / ( nAD + nTG ) )	
	endif

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


// 2009-??		removed the possibility to search an improved stimulus timing
//	Function		SearchImprovedStimulusTiming( sFo, wG, nCEDMemPts, nPnts, nSmpInt, nDA, nAD, nTG, nSlices )
//		string  	sFo
//		wave	wG
//		variable	nCEDMemPts, nPnts, nSmpInt, nDA, nAD, nTG, nSlices
//		variable	Neighbors		= 100
//		printf "\t\tSearching improved stimulus timing within the range %d points * %d us = original script length = %.2lf ms to %.2lf ms ", nPnts, nSmpInt, nPnts * nSmpInt  / UFPE_kMILLITOMICRO, ( nPnts + Neighbors ) * nSmpInt / UFPE_kMILLITOMICRO
//		CheckNeighbors( sFo, wG, nCEDMemPts, nPnts, nSmpInt , nDA, nAD, nTG, nSlices, Neighbors )	
//	End
//	
//	
//static 	Function		CheckNeighbors( sFo, wG, nCEDMemPts, nPnts, nSmpInt , nDA, nAD, nTG, nSlices, Neighbors )	
//		string  	sFo
//		wave	wG
//		variable	nCEDMemPts, nPnts, nSmpInt , nDA, nAD, nTG, nSlices, Neighbors	
//		nvar		gnReps			= root:uf:acq:cons:gnReps
//		nvar 		gChnkPerRep		= root:uf:acq:cons:gChnkPerRep
//		nvar		gPntPerChnk		= root:uf:acq:cons:gPntPerChnk
//		nvar		gSmpArOfsDA		= root:uf:acq:cons:gSmpArOfsDA
//		nvar 		gSmpArOfsAD		= root:uf:acq:cons:gSmpArOfsAD
//		nvar		gnOfsDO			= root:uf:acq:cons:gnOfsDO
//		nvar		gnCompressTG		= root:uf:acq:cons:gnCompressTG
//		nvar		gMaxSmpPtspChan	= root:uf:acq:cons:gMaxSmpPtspChan
//	
//		variable	SmpArEndDA, SmpArEndAD, nChunkTimeMS, nTrfAreaPts				// are computed
//		variable	TAUsed, MemUsed, FoM, BestFoM, Pts
//	
//		BestFoM = 0
//		// printf "\tSetPointsTestContNeighbors() checking points from  %d  to  %d \r",  nPnts - Neighbors, nPnts + Neighbors
//		printf "\r"
//	//	for ( Pts = nPnts - Neighbors; Pts < nPnts + Neighbors; Pts += 2 )
//		for ( Pts = nPnts; Pts < nPnts + Neighbors; Pts += 2 )
//			nTrfAreaPts	= SetPoints( sFo, nCEDMemPts, Pts, nSmpInt , nDA, nAD, nTG, nSlices, UFCom_kERR_MESSAGE, UFCom_kERR_MESSAGE )				// all params are points not bytes	
//			TAused		= TAuse( gPntPerChnk, nDA, nAD, cMAX_TAREA_PTS ) 
//			MemUsed		= MemUse(  gChnkPerRep, gPntPerChnk, gMaxSmpPtspChan )
//			FoM			= FigureOfMerit( gChnkPerRep, gPntPerChnk, gMaxSmpPtspChan, nDA, nAD, nTG, gnCompressTG, cMAX_TAREA_PTS ) 
//			if ( FoM > 1.001 * BestFoM )		// 1.001 prevents minimal useless improvement from being displayed
//				BestFoM = FoM
//				SmpArEndDA	= gSmpArOfsDA + trunc( 2 * gChnkPerRep * gPntPerChnk * nDA + .5 )			// like SetPoints ()	
//				SmpArEndAD 	= gSmpArOfsAD + trunc( 2 * gChnkPerRep * gPntPerChnk * ( nAD + nTG ) + .5 )	// like SetPoints ()	
//				// printf "\t %10d \t %10d \tSi:%4d\t%2d\t%2d\t%2d\tSl:%4d\t:Rep:%6d\t* Chk:%4d\t* PpC:%5d\tTA:%8d\t%7d\t%7d\t\t%7d\t%7d\t%10d\tFoM:%4.1lf \t \r", nCEDMemPts*2, Pts, nSmpInt , nDA, nAD, nTG, nSlices, gnReps, gChnkPerRep, gPntPerChnk, nTrfAreaPts, gSmpArOfsDA, SmpArEndDA, gSmpArOfsAD, SmpArEndAD, gnOfsDO, FoM
//				printf "\t %10d \t %10d \tSi:%4d\t%2d\t%2d\t%2d\tSl:%4d\tRep\t%7d\tChk\t%7d\tPpC\t%7d\tTA:\t%7d\t  TA:%3d%% \tMem:%3d%%\t FoM:%5.1lf\t \t \r", Pts, nCEDMemPts*2, nSmpInt , nDA, nAD, nTG, nSlices, gnReps, gChnkPerRep, gPntPerChnk, nTrfAreaPts, TAUsed, MemUsed, FoM
//			endif
//	
//			if ( nTrfAreaPts == UFCom_kERROR )
//				return UFCom_kERROR
//			endif
//		endfor
//	End


//Function		Random( nBeg, nEnd, nStep )
//// returns random integer from within the given range, divisible by 'nStep'
//	variable	nBeg, nEnd, nStep
//	variable	nRange	= ( nEnd - nBeg ) / nStep						// convert to Igors random range ( -nRange..+nRange )
//	variable	nRandom	= trunc ( abs( enoise( nRange ) ) ) * nStep + nBeg		// maybe not perfectly random but sufficient for our purposes
//	// printf "\tRandom( nBeg:%6d \tnEnd:%6d  \tStep:%6d \t) : %g \r", nBeg, nEnd, nStep, nRandom
//	return	nRandom
//End

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// 2003-0612
static	Function		CEDInit1401DACADC( hnd, mode )
	variable	hnd, mode
	variable	nType, nSize, code, bMode = mode & UFPE_MSGLINE 
	string		sBuf

	if ( mode & UFPE_MSGLINE )
		printf "\t\tCed CEDInit1401DACADC() : Ced is %s open.  Hnd:%d \r", SelectString( hnd == CED_NOT_OPEN, "", "NOT" ), hnd
	endif
	if ( hnd == CED_NOT_OPEN )
		return	hnd
	endif

	// change memory map if the 1401 is equipped with 16 MByte RAM or more. See p. 20 of the 1999 family programming manual
	if ( mode & UFPE_MSGLINE )
		printf "\t\tCed CEDInit1401DACADC()  checking type :"
	endif

	nType	= CEDType( hnd, bMode )
	
	if ( mode & UFPE_MSGLINE )
		printf "\t\tCed CEDInit1401DACADC()  checking memory size  \t\t\t\t\t\t\t : "
	endif
	nSize	= CEDGetMemSize( hnd, bMode )		
	if (  nType  == 1 )   										// only 1=1401plus needs the MEMTOP,E command.  2=1401micro and  3=1401power (but not 0=1401standard..)

		CEDSendStringCheckErrors( hnd, "MEMTOP,E;" , 0 ) 
		if ( mode & UFPE_MSGLINE )
			printf "\t\tCed CEDInit1401DACADC()  checking memory size   after \tsending 'MEMTOP,E;'  : "
		endif
		nSize = CEDGetMemSize( hnd, bMode )	
	endif

	// load these commands, 'KILL' (when loaded first) actually unloads all commands before reloading them to free occupied memory (recommendation of Tim Bergel, 2000 and 2003)
	string		sCmdDir	= "c:\\1401\\"
	string		sCmds	= "KILL,MEMDAC,ADCMEM,ADCBST,DIGTIM,SM2,SN2,SS2"	// the  Test/error led  should not flash unless commands are overwritten (which cannot occur bcause of 'KILL' above)

	// print "UFP_CedLdErrOut( hnd, mode, sCmdDir, sCmds )"
	code		= UFP_CedLdErrOut( hnd, mode, sCmdDir, sCmds )
// reactivated  because of U14Ld()  error -544 with script  CCVIGN_MB.txt (456.3s, 18252000pts)
//	code		= UFP_CedLdErrOut2( mode, sCmdDir, sCmds )

	// printf "\t\tCed CEDInit1401DACADC()  loading commands  '%s'  '%s' \treturns code:%d \r", sCmdDir, sCmds, code
	if ( code  ||  ( mode & UFPE_MSGLINE ) )
		printf "\t\tCed CEDInit1401DACADC()  loading commands  '%s'  '%s' \treturns code:%d \r", sCmdDir, sCmds, code
	endif 
	if ( code )
		return	code
	endif

	// To be sure, occasionally there were some problems with strange values on DACs 
	sBuf		= "DAC,0 1 2 3,0 0 0 0;" 
	code		= CEDSendStringCheckErrors(  hnd, sBuf , 0 ) 
	if ( code  ||  ( mode & UFPE_MSGLINE ) )
		printf "\t\tCed CEDInit1401DACADC()  sending %s \treturns code:%d \r", UFCom_pd( sBuf,18), code
	endif
	if ( code )
		return	code
	endif
	return	code
End

static Function		CedSetEvent( sFo, hnd, bMode )
	string  	sFo
	variable	hnd, bMode
	variable	bTrigMode		= TrigMode()
	variable	code			= 0
	variable	nCedType		= CEDType( hnd, bMode )	
	string		sBuf

//// 2005-1206  only testing
// sBuf		= "EVENT,P,63;"							// 63 : set polarity of events 0 ...5 to  low active  (normal setting)
// 		 printf "\t\tSetEvent( %s , TrigMode:%2d )  '%s' \r",  sFo, bMode, sBuf  
//code		+= CEDSendStringCheckErrors( sBuf, 1 ) 


// Old code from version 223 (03 Oct) : E3E4 triggering working !!!  To be deleted again !
//
//
//	if ( gRadTrigMode == 0 ) 	// normal SW triggered mode,  see p.48, 53 of the 1995 family programming manual for an example how to handle dig outputs and events 
//		sBuf		= "EVENT,D,28;"	// 'D'isable external events 2, 3 and 4;   4 + 8 + 16 = 28  i.e. trigger only on internal clock, but not on external signal on E input
//	else
//		sBuf		= "EVENT,D,4;" 	// 'D'isable external events 2   [ 2^2  = 4 ] , but  allow external trigger on events 3 and  4
//	endif
//
//	code		= UFP_CedSendStringErrOut( mode, sBuf ) 
//	if ( code  ||  ( mode & UFPE_MSGLINE ) )
//		printf "\t\tAcq CEDInit1401DACADC()  sending %s \treturns code:%d \r", UFCom_pd( sBuf,18), code
//	endif
//
//	sBuf		= "DIGTIM,OB;"		// use  'B'oth  digital outputs and internal events
//	code		= UFP_CedSendStringErrOut( mode, sBuf ) 
//	if ( code  ||  ( mode & UFPE_MSGLINE ) )
//		printf "\t\tAcq CEDInit1401DACADC()  sending %s \treturns code:%d \r", UFCom_pd( sBuf,18), code
//	endif



	if ( bTrigMode == 0  ) 										// normal SW triggered mode,  see p.48, 53 of the 1995 family programming manual for an example how to handle dig outputs and events 
		sBuf		= "DIGTIM,OB;"							// use  'B'oth  digital outputs and internal events
		// printf "\t\tSetEvent( %s , TrigMode:%2d )  '%s' \r",  sFo, bMode, sBuf  
		code		+= CEDSendStringCheckErrors(  hnd, sBuf , 0 ) //1 ) 
		sBuf		= "EVENT,D,28;"							// 'D'isable external events 2, 3 and 4;   4 + 8 + 16 = 28  i.e. trigger only on internal clock, but not on external signal on E input
		// printf "\t\tSetEvent( %s , TrigMode:%2d )  '%s' \r",  sFo, bMode, sBuf  
		code		+= CEDSendStringCheckErrors(  hnd, sBuf, 0 )//1 ) 
	endif	

	if ( bTrigMode == 1 ) 										// HW E3E4 triggered mode
		printf "\t\tIn this mode a  low-going TTL edge on  Events 2,3,4 (1401plus)  or on Trigger input (Power1401)  will trigger stimulus and acquisition. \r" 

// 2006-0206   THIS IS NOT EXECUTED ????
		sBuf		= "DIGTIM,OD;"							// use  only 'D'igital outputs, do not trigger on internal events
		 printf "\t\tSetEvent( %s , TrigMode:%2d )  '%s' \r",  sFo, bMode, sBuf  
		// 2005-1208
		sBuf		= "EVENT,D,4;" 	// 'D'isable external events 2   [ 2^2  = 4 ] , but  allow external trigger on events 3 and  4
		 printf "\t\tSetEvent( %s , TrigMode:%2d )  '%s' \r",  sFo, bMode, sBuf  
		code		+= CEDSendStringCheckErrors(  hnd, sBuf , 0 )//1 ) 
		if (  nCedType  ==  c1401MICRO  ||  nCedType == c1401POWER ) // only   2=1401micro and  3=1401power (but not 0=1401standard or 1=1401plus)  need this linking command
			sBuf = "EVENT,T,28;"							// Power1401 and micro1401 require explicit linking of E2, E3 and E4 to the front panel 'Trigger' input
			 printf "\t\tSetEvent( %s , TrigMode:%2d )  '%s' \r",  sFo, bMode, sBuf  
			code	+= CEDSendStringCheckErrors(  hnd, sBuf, 0 )//1 ) 
		endif
	endif	
	return	code
End


static Function  ArmClockStart( SmpInt, nTrigMode, hnd )
	variable	SmpInt, nTrigMode, hnd 
	string		buf , bf 
	string		sMode	= SelectString( nTrigMode , "C", "CG" )	// start stimulus/acquisition right now or wait for low pulse on E2 in HW triggered E3E4 mode 
	variable	rnPre1, rnPre2								// changed in function
	if (  CEDHandleIsOpen_ns() )
		variable	nrep	= 1								// the true number of repetitions is set in ArmDig 
		if ( SplitIntoFactors( SmpInt, rnPre1, rnPre2 ) )
			return	UFCom_kERROR							// 2003-1126
		endif
		// divide 1MHz clock by two factors to get basic clock period in us, set clock (with same clock rate as DAC and ADC)  and  start DigOut, DAC and  ADC  OR  wait for low pulse 
		sprintf buf, "DIGTIM,%s,%d,%d,%d;", sMode, rnPre1, rnPre2, nrep
		//if (  UFCom_DebugVar( 0, "acq", "Ced" ) )
			printf "\t\tCed ArmClockStart sends  '%s'  \r", buf
		//endif
		// 2003-1124 PROBLEM:  EVEN IF too ambitious sample rates are attempted the CED will  FIRST  start  the stimulus/acquisition and  THEN LATER  return an error code and an error dialog box.
		// -> starting the stimulus/acquisition cannot be avoided  no matter whether the user acknowledges the error dialog box or not  leading almost inevitably to corrupted data.
		// -> TODO   the stimulus/acquisition should NOT start in the error case .    STOPADDA   BEFORE   the error dialog opens.... 
		if ( CEDSendStringCheckErrors(  hnd, buf, 0 ) ) 
			return	UFCom_kERROR						// 
		endif
	endif
	return	0
End


static Function  ArmDAC_ns( sFo, lllstIO, BufStart, BufPts, nrep, hnd )
	string  	sFo, lllstIO
	variable	BufStart, BufPts, nrep, hnd
	wave 	wG			= $FoWvNmWgNs( sFo )
	string		buf, bf
	variable	nSmpInt	= wG[ UFPE_WG_SI ]
	variable	nCntDA	= wG[ UFPE_WG_CNTDA ]	
	variable	rnPre1, rnPre2							// changed in function
	if (  CEDHandleIsOpen_ns() )
		if (  nCntDA )
			if ( SplitIntoFactors( nSmpInt, rnPre1, rnPre2 ) )
				return	UFCom_kERROR							// 2003-1126
			endif
			string		sChans = ChannelList_ns( lllstIO, kSC_DAC, nCntDA )	//? depends on ordering..
			// Load the DAC with clock setup: 'I'nterrupt mode, 2 byte, from gDACOffset BufSize bytes, 
			// DAC2, nRepeats, 'C'lock 1 MHz/'T'riggered mode, and two factors for clock multiplier 
			// after sending this command to the Ced the DAC will be waiting for a trigger to Event input E3 
			sprintf  buf, "MEMDAC,I,2,%d,%d,%s,%d,CT,%d,%d;", BufStart, BufPts * 2, sChans, nrep, rnPre1, rnPre2
			if ( UFCom_DebugVar( "acq", "Ced" ) )
				printf "\t\tCed ArmDAC   sends  '%s'  \r", buf
			endif
			 printf "\t\tCed ArmDAC   sends  '%s'  \r", buf

			if ( CEDSendStringCheckErrors( hnd, buf, 0 ) )			// now DAC is waiting for a trigger to Event input E3 
				return	UFCom_kERROR					// 
			endif

		endif
	endif
	return 0
End


static	Function  /S 	ChannelList_ns( lllstIO, nio, nChs )
	string  	lllstIO
	variable	nChs, nio			// 'kSC_IO_ADC'  or  'kSC_IO_DAC'
	variable	cio
	string		bf, sChans = ""
	for ( cio = 0; cio < nChs;  cio += 1 )
		sChans += " "
		sChans += num2str( UFPE_iov_ns( lllstIO, nio, cio, kSC_IO_CHAN ) )
	endfor
	// printf   "\t\tCed Channellist_ns for %d '%s' channels '%s' \r", nChs, UFPE_ioTNm_ns( nio ), sChans
//	variable	nRadDebgGen	= UFCom_DebugDepthGen()
//	if ( nRadDebgGen )
	if ( UFCom_DebugVar( "acq", "General" ) )
		printf "\t\tCed Channellist for %d '%s' channels '%s' \r", nChs,  UFPE_ioTNm_ns( nio ), sChans
	endif
	return 	sChans
End


static Function  ArmADC( sFo, lllstIO, BufStart, BufPts, nrep, hnd )
	string  	sFo, lllstIO
	variable	BufStart, BufPts, nrep, hnd
	wave 	wG			= $FoWvNmWgNs( sFo )
	string		buf, bf
	variable	nSmpInt		= wG[ UFPE_WG_SI ]
	variable	rnPre1, rnPre2							// changed in function
	if ( CEDHandleIsOpen_ns() )
		string  	listADTG	= MakeListADTG_ns( lllstIO )
		variable	nAdcChs 	= ItemsInList( listADTG, " " )	// lstAD + lstTG
		if ( nAdcChs )
			// load the ADC  :   using  'ADCBST'  we get 'SmpInt' between each burst  ( using  'ADCMEM' we get 'SmpInt' between each channel and have to adjust it)
			// parameters:  'I'nterrupt mode, 2 byte, from 'gADCOffset' 'BufSize' bytes,  ADC0 ,  1 repeat,  Clock 1 MHz / 'T'riggered mode, and two factors for clock multiplier 
			// after sending this string to the Ced  the ADC will be  waiting for a trigger to Event input E4 
			variable	nCedType	= CedType( hnd, 0 )

			// 2004-0325  Using ADCMEM rather than ADCBST decreases the minimum sampling interval from  18..20   to 12 us  when using  the 1401 plus with  1 DA, 1 AD and 1 TG channel.
			if ( nCedType == c1401STANDARD ) 								

				if ( SplitIntoFactors( nSmpInt / nAdcChs, rnPre1, rnPre2 ) )
					return	UFCom_kERROR							
				endif
				// SplitIntoFactors() will already alert about this error........
				//if ( nSmpInt / nAdcChans != trunc( nSmpInt / nAdcChans ) )
				//	UFCom_FoAlert( sFo, UFCom_kERR_IMPORTANT, "Sample interval of " + num2str( nSmpInt ) + " could not be divided without remainder through " + num2str( nAdcChans ) + " channels." )
				//endif
				sprintf buf, "ADCMEM,I,2,%d,%d,%s,%d,CT,%d,%d;", BufStart, BufPts * 2, listADTG, nrep, rnPre1, rnPre2
			else
				if ( SplitIntoFactors( nSmpInt, rnPre1, rnPre2 ) )
					return	UFCom_kERROR							
				endif
				sprintf buf, "ADCBST,I,2,%d,%d,%s,%d,CT,%d,%d;", BufStart, BufPts * 2, listADTG, nrep, rnPre1, rnPre2
			endif
			if ( UFCom_DebugVar( "acq", "Ced" ) )
				printf "\t\tCed ArmADC   sends  '%s'    ( nAdcChans: %d , CedType: '%s' )\r", buf, nAdcChs, StringFromList( nCedType + 1, sCEDTYPES )
			endif
			 printf "\t\tCed ArmADC   sends  '%s'    ( nAdcChans: %d , CedType: '%s' )\r", buf, nAdcChs, StringFromList( nCedType + 1, sCEDTYPES )

			if ( CEDSendStringCheckErrors( hnd, buf, 0 ) )						// now ADC is waiting for a trigger to Event input E4 
				return	UFCom_kERROR						
			endif
		endif
	endif
	return 0
End



static Function  /S	MakeListADTG_ns( lllstIO )
	string	  	lllstIO
	variable	Chan, TGChan
	string  	lstAD = "", lstTG = ""
	variable	nio		= kSC_ADC
	variable	cio, cioCnt	= UFPE_ioUse_ns( lllstIO, nio )
	for ( cio = 0; cio < cioCnt; cio += 1 )
		Chan		= UFPE_iov_ns( lllstIO, nio, cio, kSC_IO_CHAN ) 
		if (  UFPE_ioHasTG( lllstIO, nio, cio ) )
			TGChan	= UFPE_iov_ns( lllstIO, nio, cio, kSC_IO_TGCH ) 
			lstTG		= AddListItem( num2str( TGChan ), lstTG, " ", Inf )		// use space as separator so that CED can use this string in 'ADCBST' and 'ADCMEM' directly
		endif
		lstAD	= AddListItem( num2str( Chan ), lstAD, " ", Inf )				// use space as separator so that CED can use this string in 'ADCBST' directly
	endfor
	 printf "\t\tMakeListADTG_ns( lllstIO  ) -> '%s'   \tlllstIO/lllstIOTG? :'%s'   \r", lstAD + lstTG, lllstIO
	return	lstAD + lstTG
End


static 	Function		SplitIntoFactors( nNumber, rnFactor1, rnFactor2 )
	variable	nNumber, &rnFactor1, &rnFactor2 						// changed in function
	string		bf
	rnFactor1	= FindNextDividerBetween( nNumber, 2, min( nNumber / 2, 65535 ) )	// As 2 is the minimum value for ADCBST( 1401plus ) , MEMDAC( 1401plus ) , DIGTIM( 1401plus and Power1401 )...
	rnFactor2	= nNumber / rnFactor1									// ..it makes no sense to handle (theoretically possible) minimum of 1 for ADCBST +  MEMDAC( Power1401 ) separately
	if ( rnFactor1 == UFCom_kNOTFOUND   ||   trunc( rnFactor1 ) * trunc( rnFactor2 )  != nNumber )
		sprintf bf, "Sample interval of %g could not be divided into 2 integer factors between 2 and 65535. ", nNumber 
		UFCom_FoAlert( ksACQ, UFCom_kERR_FATAL, bf )
		return	UFCom_kERROR							
	endif
	return	0
End


static	Function  		ArmDig( sFo, OffsDO, hnd )
	string  	sFo
	variable	OffsDO, hnd
	wave 	wG			= $FoWvNmWgNs( sFo )
	variable	nProts		= UFPE_Prots( sFo )
	variable	gnJumpBack	= DgoJumpBack( sFo )//"root:uf:" + sFo + ":dig:gnJumpBack"
	string		sDigoutSlices		= DgoDigoutSlices( sFo )
	variable	n, p
	string		buf, bf
	if ( CEDHandleIsOpen_ns() )
		variable	nSlices = ItemsInList( sDigoutSlices )	

		CEDSetAllDigOuts( hnd, 0 )												// 2003-1110  Initialize the digital output ports with 0 : set to LOW
		
		// book space for   'nSlices'  (=all slices contained in 'sDigoutSlices' ) , each slice needs 16 Bytes 
		sprintf  buf, "DIGTIM,S,%d,%d;", OffsDO, BYTES_PER_SLICE * nSlices
		if ( UFCom_DebugVar( "acq", "Ced" ) )
			printf "\t\tCed ArmDig     OffsDO:%d,  nSlices:%2d ,  nProts:%d -> '%s' \r", OffsDO, nSlices, nProts, buf 
		endif
		printf "\t\tCed ArmDig     OffsDO:%d,  nSlices:%2d ,  nProts:%d -> '%s' \r", OffsDO, nSlices, nProts, buf 


		if ( CEDSendStringCheckErrors(  hnd, buf, 0 ) ) //1 ) )		
			return	UFCom_kERROR						
		endif

		for ( n = 0; n < nSlices - 1 ; n +=1 )						// do not yet send the last slice because we must append the number of repeats 					
			 // printf "\t\tSl:%2d/%2d  %s\t'%s.... \r", n, nSlices, UFCom_pd( StringFromList( n, sDigoutSlices ), 18), sDigoutSlices[0,200] 
			//UFP_CedSendStringErrOut( UFPE_ERRLINE+ERR_FROM_CED, StringFromList( n, sDigoutSlices ) + ";" ) // each slice needs appr. 260 us to be sent 
			CEDSendStringCheckErrors( hnd, StringFromList( n, sDigoutSlices ) + ";" ,  0 ) // 1  ) // each slice needs appr. 260 us to be sent 
		endfor

		string		sLastSlice	= StringFromList( nSlices - 1 , sDigoutSlices ) +  "," + num2str( -nSlices + gnJumpBack ) + "," + num2str( nProts )   // 2003-0627 do NOT repeat DAC/DAC-Trigger (skip first 2 slices)
		//if (  UFCom_DebugVar( 0, "acq", "Ced" ) )
			printf "\t\tCed ArmDig     Prot:%2d/%2d   \tSlice:%2d/%2d  \tLastSlice \tcontaining   jmp and rpt :'%s'    (JumpBack:%d)  \r", p, nProts, n, nSlices, sLastSlice, gnJumpBack
		//endif

		if ( CEDSendStringCheckErrors(  hnd, sLastSlice  + ";" ,  0 ) ) // 1 ) )	// sends last DIGTIM,A...	
			return	UFCom_kERROR						
		endif

		//if (  UFCom_DebugVar( 0, "acq", "Ced" ) )
			printf  "\t\tCed ArmDig     has sent %d  digout slices. Digital transitions OK.\r", nSlices
		//endif
	//UFCom_StopTimer( sFo, "ArmDig" )
	endif
	return 0
End


// test 2010-02-06 e		Explain errors better :  if this works well   all similar code segments  'CEDSendStringCheckErrors'   should be changed....

//static Function		CEDSendStringCheckErrors( hnd, buf, bPrintIt )
////   Send  'sCommand'  to Ced with 'hnd'  and check for errors.  If an error occured then print the error number.
//	string		buf
//	variable	hnd, bPrintIt
//	if ( bPrintIt )
//		printf "\tCEDSendStringCheckErrors( %s ) \r", buf 
//	endif
//	UFP_CedSendString( hnd, buf )
//	variable	err	= UFP_CedGetResponse( hnd, "ERR;", buf, 0 )		// last param is 'ErrMode' : display messages or errors
//	if ( err )
//		string	   bf
//		sprintf  bf,  "err1: %d  err2: %d   after sending   '%s'   (%d) ",  trunc( err / 256 ) , mod( err, 256 ), buf , err 
//		UFCom_FoAlert( ksACQ, UFCom_kERR_FATAL,  bf )
//		err	= UFCom_kERROR					
//	endif
//	return	err
//End

static Function		CEDSendStringCheckErrors( hnd, sCommand, bPrintCommand )
// 2010-02-06  Send  'sCommand'  to Ced with 'hnd'  and check for errors.  If an error occured then explain the error.
	string		sCommand
	variable	hnd, bPrintCommand
	if ( bPrintCommand )
		printf "\tCEDSendStringCheckErrors_( hnd:%d, %s ) \r", hnd, sCommand 
	endif
	UFP_CedSendString( hnd, sCommand )
	string  	sErrorCodes	= UFP_CedGetResponseTwoIntAsStr( hnd, "ERR;" )
	variable	er0			= str2num( StringFromList( 0, sErrorCodes, " " ) )	
	if ( er0 )
		variable	nErrorlevel	= UFCom_kERR_FATAL
		string  	sExplain	=  ExplainCEDErr( sErrorCodes, StringFromList(0,sCommand,","),  nErrorlevel )
		string	   bf
		sprintf   bf, "++++ Error:  When sending to Ced (hnd:%d)  '%s'  the Ced returned the error codes '%s' :\r'%s'  \r", hnd, sCommand, sErrorCodes, sExplain
		UFCom_FoAlert( ksACQ, UFCom_kERR_FATAL,  bf )
		return   UFCom_kERROR						
	endif
	return	0
End


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function		TimeElapsed()
	string  	sFo		= ksACQ
	nvar		gbRunning	= $"root:uf:acq:" + UFPE_ksKEEP + ":gbRunning"
	nvar		gnTicksStop	= $"root:uf:acq:" + UFPE_ksKEEP + ":gnTicksStop"
	nvar		gnTicksStart	= $"root:uf:acq:" + UFPE_ksKEEP + ":gnTicksStart"

	variable	nStopTime 	= gbRunning ? ticks : gnTicksStop  
// 2005-12-01
	nvar		TimeElapsed	= root:uf:acq:pul:svTmElaps0000
	TimeElapsed			= ( nStopTime - gnTicksStart ) / UFCom_kTICKS_PER_SEC	 // returns seconds elapsed since ...

	return	( nStopTime - gnTicksStart ) / UFCom_kTICKS_PER_SEC		 		// returns seconds elapsed since ...
End

Function		GetAndInterpretAcqErrors( hnd, sText1, sText2, chunk, nMaxChunks )
	string		sText1, sText2
	variable	hnd, chunk, nMaxChunks
	string		errBuf
	variable	code	

	string		sErrorCodes	= UFP_CedGetResponseTwoIntAsStr( hnd, "ERR;" )
	code		= ExplainCEDError( sErrorCodes, sText1 +" | " +  sText2, chunk, nMaxChunks )
	code		= trunc( code / 256 )			// 2003-0805 use only the first byte of the 2-byte errorcode (only temporarily to be compatible with the code below...) 
	// printf "...( '%s' = '%d  '%d' )\t",  sErrorCodes, str2num( StringFromList( 0, sErrorCodes, " " ) ) , str2num( StringFromList( 1, sErrorCodes, " " ) )
	return	code
End


Function		ExplainCEDError( sErrorCodes, sCmd, chunk, nMaxChunks )
// prints error codes issued by the CED in a human readable form. See 1401 family programming manual, july 1999, page 17
	string		sCmd, sErrorCodes
	variable	chunk, nMaxChunks
	variable	nErrorLevel = UFCom_kERR_SEVERE				// valid for all errors (=mandatory beep)  except 'Clock input overrun', which may occur multiple times..
	variable	er0		 = str2num( StringFromList( 0, sErrorCodes, " " ) )	//.. in slightly too fast scripts while often not really being an error (=UFCom_kERR_IMPORTANT, beep can be turned off) 
	variable	er1	 	 = str2num( StringFromList( 1, sErrorCodes, " " ) )
	if ( er0 == 0 )
		return 0
	endif
	string  	sErrorText	 = ""
	sErrorText	 +=  ExplainCEDErr( sErrorCodes, sCmd, nErrorLevel )	// nErrorLevel is a reference and is passed back.  Prints error codes issued by the CED in a human readable form. See 1401 family programming manual, july 1999, page 17
	sErrorText  +=  "  err:'" + sErrorCodes + "'  in chunk " + num2str( chunk )	 +  " / " + num2str( nMaxChunks )	
	UFCom_FoAlert( ksACQ, nErrorLevel, sErrorText[0,220] )
	return	er0 * 256 + er1									// 2003-0805  build and return  1  16 bit number from the 2 bytes 
End


Function	/S	ExplainCEDErr( sErrorCodes, sCmd, nErrorLevel )
// prints error codes issued by the CED in a human readable form. See 1401 family programming manual, july 1999, page 17
	string  	sErrorCodes, sCmd
	variable	&nErrorLevel
	variable	er0		= str2num( StringFromList( 0, sErrorCodes, " " ) )	//.. in slightly too fast scripts while often not really being an error (=UFCom_kERR_IMPORTANT, beep can be turned off) 
	variable	er1	 	= str2num( StringFromList( 1, sErrorCodes, " " ) )
	string  	sErrorText	= ""
	if ( er0 == 0 )
		return	""			// no error , OK
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
		sErrorText	= "Inspite of Ced reporting 'Clock interrupt overrun : Sampling too fast or too many channels' :  THE DATA MAY BE OK. [\t" + UFCom_pad(sCmd,19)  + "\t]"
		nErrorLevel = UFCom_kERR_IMPORTANT		// beep can be turned off when this error is triggered erroneously (which is unfortunately often the case)
	else
		sErrorText	= "Could not interpret this error :" + sErrorCodes + "   [" + sCmd  + "]"
	endif
	return	sErrortext
End

//==============================================================================================================================================
//  SUBPANEL  1401  TEST  FUNCTIONS

static strconstant	ksPN_NAME		= "ced"			// Panel name   _and_  subfolder name  _and_  section keyword in INI file
static strconstant	ksPN_TITLE		= "Ced 1401"		// Panel title
static strconstant	ksPN_CTRLBASE	= "gbPnTst1401"	// The  button base name (without prefix root:uf... and postfix 0000) in the main panel displaying and hiding THIS subpanel
static strconstant	ksPN_INISUB		= "FPuls"			// The  INI subfolder  below folder 'acq'   and   the  INI file location (here in a subdirectory to FPulse=FPulseMain.ipf)
static strconstant	ksPN_INIKEY		= "Wnd"			// The  keyword in the INI file (here always 'Wnd' as we are dealing with window positions and visibility)

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Action procedure for displaying and hiding a subpanel

Function		fPnTest1401( s )
// The  Button action procedure of the button in the main panel displaying and hiding THIS subpanel.  Unfortunately we can not wrap this in a function because of the specific Panel creation function name below (due to hook function)
	struct	WMButtonAction	&s
	nvar		state		= $ReplaceString( "_", s.ctrlname, ":" )					// the underlying button variable name is derived from the control name
	// printf "\t\t\t\t%s\tvalue:%2d   \t\t%s\t%s\t%s\t \r",  UFCom_pd( s.ctrlname, 25),  state, UFCom_pd(ksPN_INISUB  ,9), UFCom_pd(ksPN_NAME ,9), UFCom_pd( ksPN_INIKEY ,9)	
	string  	sIniBasePath	= FunctionPath( ksFP_APP_NAME )					// the Ini file containing the window position will be written in a subdirectory parallel to UF_PulseMain.ipf 
	UFCom_WndVisibilitySetWrite_( ksACQ, ksPN_INISUB, ksPN_NAME, ksPN_INIKEY, state, sIniBasePath )
	if ( state )															// if we want to  _display_  the panel...
		if ( WinType( ksPN_NAME ) != UFCom_WT_PANEL )						// ...and only if the panel does not yet  exist ..
			PanelTest1401( UFCom_kPANEL_DRAW )							// *** specific ***...we must build the panel
		else
			UFCom_WndUnhide( ksPN_NAME )								//  display again the hidden panel 
		endif
	else
		UFCom_WndHide( ksPN_NAME )									//  hide the panel 
	endif
End

//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function		PanelTest1401( nMode )
// Create the panel.  Unfortunately we can not wrap this in a function because of the specific hook function name
	variable	nMode
	string  	sFBase		= "root:uf:"
	string  	sFSub		= ksACQ_	
	string		sDFSave		= GetDataFolder( 1 )								// The following functions do NOT restore the CDF so we remember the CDF in a string .
	UFCom_PossiblyCreateFolder( sFBase + sFSub + ksPN_NAME ) 
	InitPanelTest1401( sFBase + sFSub, ksPN_NAME )							// *** specific ***fills big text wave  'sPnOptions' (=wPn)  with all information about the controls necessary to build the panel
	UFCom_RestorePanel2Sub( ksACQ, ksFPUL, ksPN_NAME, ksPN_TITLE, sFBase, sFSub, ksPN_INISUB, ksPN_INIKEY, ksPN_CTRLBASE, nMode )
	SetWindow		$ksPN_NAME,  hook( $ksPN_NAME ) = fHook1401			// *** specific ***
	SetDataFolder sDFSave												// Restore CDF from the string  value
	UFCom_LstPanelsAdd( ksACQ, ksfACQVARS, ksPN_NAME )	
End


Function 		fHook1401( s )
// The window hook function detects when the user moves or resizes or hides the panel  and stores these settings in the INI file
	struct	WMWinHookStruct &s
	string  	sIniBasePath	= FunctionPath( ksFP_APP_NAME )					// the Ini file containing the window position will be written in a subdirectory parallel to UF_PulseMain.ipf 
	return	UFCom_WndUpdateLocationHook( s, ksACQ, ksFPUL, ksPN_INISUB, ksPN_INIKEY, ksPN_CTRLBASE, sIniBasePath )
End


Function		InitPanelTest1401( sF, sPnOptions )
	string  	sF, sPnOptions
	string		sPanelWvNm = sF + sPnOptions
	variable	n = -1, nItems = 20
	// printf "\t\tInitPanelTest1401( '%s',  '%s' ) \r", sF, sPnOptions 
	make /O /T /N=(nItems)	$sPanelWvNm
	wave  /T	tPn	=		$sPanelWvNm
	//				Type	 NxL Pos MxPo OvS	Tabs		Blks		Mode		Name		RowTi				ColTi		ActionProc	XBodySz	FormatEntry	Initvalue	Visibility	HelpTopic
	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	°:		,:		1,°:			buCurrntHnd:	Current handle:			:		fCurrentHnd():	:		:			:		:		Current handle 1401:	"
	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	°:		,:		1,°:			buOpen1401:	Open 1401:			:		fOpen1401():	:		:			:		:		Open 1401:		"
	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	°:		,:		1,°:			buReset1401:	Reset 1401:			:		fReset1401():	:		:			:		:		Reset 1401:		"
	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	°:		,:		1,°:			buClose1401:	Close 1401:			:		fClose1401():	:		:			:		:		Close 1401:		"
	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	°:		,:		1,°:			buType1401:	Type of1401:			:		fType1401():	:		:			:		:		Type of 1401:		"
	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	°:		,:		1,°:			buMem1401:	Memory of 1401:		:		fMemory1401():	:		:			:		:		Memory of 1401:	"
	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	°:		,:		1,°:			buStats1401:	Status of1401:			:		fStatus1401():	:		:			:		:		Status of 1401:		"
	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	°:		,:		1,°:			buStaOO1401:	OnOffStatus of1401:		:		fStatusOnOff1401()::		:			:		:		On Off Status of 1401:		"
	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	°:		,:		1,°:			buStaOp1401:	Open Status of1401:		:		fStatusOpen1401()::		:			:		:		Open Status of 1401:		"
	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	°:		,:		1,°:			buProps1401:	Properties of 1401:		:		fProperties1401()::		:			:		:		Properties of 1401:	"
	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	°:		,:		1,°:			buResetDacs:	ResetDacs:			:		fResetDacs():	:		:			:		:		Reset Dacs:		"
	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	°:		,:		1,°:			buSetDigOut:	Set digital outputs:		:		fSetDigOut():	:		:			:		:		Set digital outputs:	"
	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	°:		,:		1,°:			buResDigOut:	Reset digital outputs :		:		fResetDigOut():	:		:			:		:		Reset digital outputs:	"
	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:		,:		1,°:			dum20:		:					:		:			:		:			:		:		:	" 
	n += 1;	tPn[ n ] =	"BU:    1:	0:	1:	0:	°:		,:		1,°:			buStopBkg:	Stop background task:	:		fStopBkg():	:		:			:		:		:	"

	redimension  /N = ( n+1)	tPn
End

// To get all Helptopics for the above panel  execute   PnTESTAllTitlesOrHelptopics( "root:uf:acq:", "ced" ) 
//  ->   Current handle 1401;Open 1401;Reset 1401;Close 1401;Type of 1401;Memory of 1401;Status of 1401;Properties of 1401;Reset Dacs;Set digital outputs;Reset digital outputs;  


Function		fCurrentHnd( s )
	struct	WMButtonAction &s
	printf "\t\tfCurrentHnd  V4 \treturns: \t\t%d \r", CedHandle()
End

Function		fOpen1401( s )
	struct	WMButtonAction &s
	variable	hnd					
	hnd		= CedHandle()// 2010-01-05	old handle which can be valid or invalid
	hnd		= UFP_CedCloseAndOpen( hnd )
	CedHandleSet( hnd )
	printf "\t\tfOpen1401  \t\treturning hnd:\t%d =?= %d\r",  hnd, CedHandle()
End

Function		fReset1401( s )
	struct	WMButtonAction &s

//	// 1401 has not been closed and should be open, but it could have been switched off accidentally..
//	if ( hnd >= 0 &&  ( ( state = U14StateOf1401( hnd ) ) == 0 ) ) {	//! order or evaluation avoids printing stateText
//
//		code = U14Reset1401( hnd );		// ??? makes 200us HI-Puls on DIGOUT
//		OutError( code, "CEDReset", ErrShow );
//		if ( ErrShow & MSGLINE ) {
//			sprintf( bf, "\t\t\tUFP_CedReset: Ced was open with hnd:%d and has been reset \r", hnd ); XOPNotice(bf);
//		}
//	} else {
//		code = CED_NOT_OPEN;
//		if ( ErrShow & MSGLINE ) {
//			U14GetErrorString( state, stateText, 400 );
//			sprintf( bf, "\t\t\tCEDReset: Ced was not open (hnd:%d -> %d) '%s' \r", hnd, code, state ? stateText : "" ); XOPNotice(bf);
//		}
//		//CEDSetHandle( code ); // only open, close and reset set global handle

	variable	code, state, hnd		= CedHandle()// 2010-01-05
	if ( hnd >= 0 )
		state = UFP_CedStateOf1401( hnd ) 
		if ( state == 0 )
			code		= UFP_CedReset( hnd )
			printf "\t\t\tCedReset: \t1401 was open with hnd:%d and has been reset (state:%d, reset return code:%d) \r", hnd, state, code
		else
			printf "\t\t\tCedReset: \t1401 was open with hnd:%d but state:%d (should be 0) .  no reset  \r", hnd, state
//				U14GetErrorString( state, stateText, 400 );
//				printf "\t\t\tCEDReset: Ced was not open (hnd:%d -> %d) '%s' \r", hnd, code, state ? stateText : "" ); XOPNotice(bf);
		endif
	else
		printf "\t\t\tCEDReset: \1401 was not open (hnd:%d )  \r", hnd
	endif
End

Function		fClose1401( s )
	struct	WMButtonAction &s
	variable	code, hnd	
	hnd	= CedHandle()// 2010-01-05
	code	= UFP_CedClose( hnd )
	CedHandleSet( CED_NOT_OPEN )
	printf "\t\tfClose1401 \t\treturns code : \t%d\t%s \r", code, CedErrorString( code ) 
End


Function		CedDriverType( mode )
	variable	mode
	variable	nCedDriverType	= UFP_CedDriverType()	
	if ( mode )
		printf "\t\t1401 driver type:\t'%s'   \t\t(%d) \r", StringFromList( nCedDriverType +1 , sCEDDRIVERTYPES ), nCedDriverType	// the string list 'sCEDDRIVERTYPES 'starts with 'unknown' = -1
	endif
	return	nCedDriverType
End
	
Function		fType1401( s )
	struct	WMButtonAction &s
	variable	hnd		= CedHandle()// 2010-01-05
	if ( hnd >= 0 )
		printf "\t\tfType1401  \t\tCEDType:  "
		variable	nType	   = CEDType( hnd, kMSGLINE_C )
		printf "\t\tfType1401  \t\tCEDDriver: "
		variable	nDriverType = CEDDriverType( kMSGLINE_C )
	else
		printf "\t\tfType1401  \t\t1401 not open...\r"
	endif
End

static Function		CedType( hnd, mode )
variable		hnd, mode
variable	nCedType	= UFP_CedTypeOf( hnd )	
if ( mode )
	printf "\t\t1401 type:  \t\t'%s'  \t(%d) \r", StringFromList( nCedType + 1, sCEDTYPES ), nCedType	// the string list 'sCEDTYPES 'starts with 'unknown' = -1
endif
return	nCedType
End

Function		fMemory1401( s )
	struct	WMButtonAction &s
	variable	hnd		= CedHandle()// 2010-01-05
	if ( hnd >= 0 )
		variable	nCedType, nSize
		printf "\tChecking memory size  before\tsending 'MEMTOP,E;'  : "
		nSize	= CEDGetMemSize( hnd, kMSGLINE_C )	
		nCedType	= CEDType( hnd, kMSGLINE_C )
		if ( nCedType == c1401PLUS )					// only  1=1401plus needs 'MEMTOP,E;' command , but not 0=1401standard,  2=1401micro or  3=1401power
			CEDSendStringCheckErrors(  hnd, "MEMTOP,E;" , 0 ) // 1 ) 
			printf "\tChecking memory size   after \tsending 'MEMTOP,E;'  : "
			nSize = CEDGetMemSize( hnd, kMSGLINE_C )		
		endif
	else
		printf "\t\tfMemory1401     \t1401 not open...\r"
	endif
End

Function	CEDGetMemSize( hnd, mode )			
	variable	hnd, mode
	if ( hnd >= 0 )
		variable	nSize	= UFP_CedGetMemSize( hnd )
		if ( nSize < 0 )			// there was an error
			printf "Error: UFP_CedGetMemSize( hnd:%d) returned error:%d \r", hnd, nSize
		else
			if ( mode )
				printf "\t\t1401 has memory: %d Bytes = %.2lf MB \r", nSize, nSize/1024./1024.
			endif
			return	nSize
		endif
	endif
End


Function		fStatus1401( s )
	struct	WMButtonAction &s
	variable	hnd	= CedHandle()// 2010-01-05
	variable 	state	= UFP_CedStateOf1401( hnd ) 									// Check if CEDHandle is consistent with current Ced state. Set CEDHandle 'off'  if Ced state says 'off'  (happens if 1401 had been on but has just been switched off) 
	//printf "\t\tfStatus1401 \t\t1401 has state : %d   '%s' \r", state, UFP_CedGetErrorString( state )
	printf "\t\tfStatus1401 \t\t1401 has state :\t%d\t%s \r", state, CedErrorString( state ) 
End

Function		fStatusOnOff1401( s )
	struct	WMButtonAction &s
	variable	hnd	= CedHandle()// 2010-01-05
	variable 	state	= UFP_CedState( hnd ) 									// Check if CEDHandle is consistent with current Ced state. Set CEDHandle 'off'  if Ced state says 'off'  (happens if 1401 had been on but has just been switched off) 
	printf "\t\tfStatusOnOff1401 \t1401 has state :\t%d\t(%s) \r", state, SelectString( state+1, "Closed/Off", "Open/On" )
End

Function		fStatusOpen1401( s )
	struct	WMButtonAction &s
	PrintCEDStatus( 0 )					// 0 disables the printing of 1401 type and memory 
End

Function		fProperties1401( s )
	struct	WMButtonAction &s
	PrintCEDStatus( kMSGLINE_C )			// kMSGLINE_C enables the printing of 1401 type and memory 
End
 
 
Function		fResetDacs( s )
	struct	WMButtonAction &s
	variable	hnd		= CedHandle()// 2010-01-05
	if ( hnd >= 0 )
		CEDSendStringCheckErrors(  hnd, "DAC,0 1 2 3,0 0 0 0;" , 1  ) 
	else
		printf "\t\tfResetDacs  \t\t1401 not open...\r"
	endif
End
 
Function		fSetDigOut( s )
	struct	WMButtonAction &s
	variable	hnd		= CedHandle()// 2010-01-05
	if ( hnd >= 0 )
		CEDSetAllDigOuts( hnd, 1 )					// 2003-1110  Initialize the digital output ports with 1 : set to HIGH
	else
		printf "\t\tfSetDigOut \t\t1401 not open...\r"
	endif
End

Function		fResetDigOut( s )
	struct	WMButtonAction &s
	variable	hnd		= CedHandle()// 2010-01-05
	if ( hnd >= 0 )
		CEDSetAllDigOuts( hnd, 0 )				// 2003-1110  Initialize the digital output ports with 0 : set to LOW
	else
		printf "\t\tfResetDigOut \t\t1401 not open...\r"
	endif
End
 
Function		CEDSetAllDigOuts( hnd, value )
	// 2003-1110  Initialize the digital output ports with 0 : set to LOW
	variable	hnd, value 
	variable	nDigoutBit
	string		buf
	for ( nDigoutBit = 8; nDigoutBit <= 15; nDigoutBit += 1 )
		sprintf  buf, "DIG,O,%d,%d;", value, nDigoutBit
		CEDSendStringCheckErrors( hnd, buf , 0 ) 
	endfor
End


static 	Function	   	PrintCEDStatus( ErrShow )
// prints current CED status (missing or off, present, open=in use) and also (depending on 'ErrShow') the type and memory size of the 1401 
//! There is some confusion regarding the validity of CED handles  (CED Bug? ) : 
//  The manual says that positive values returned from 'CEDOpen()' are valid handles (at least numbers from 0..3, although only 0 is used presently)...
// ..but actually the only valid handle number ever returned is 0. Handle 5 (sometimes 6?) is returned after the following actions (misuse but nevertheless possible) : 
// 1401 is switched on and open, 1401 is switched off, 1401 is switched on again, 1401 is opened -> hnd 5 is returned indicating OK but 1401 is NOT OK and NOT OPEN. . 
// This erroneous 'state 5' must be stored somewhere in the host as it is cleared by restarting the IGOR program  OR by  closing the 1401  with hnd=0 before attempting to open it.
// Presently the XOPs CedOpen etc. do not process the 'switched off positive handle state' separately but handle it just like the closed state of the 1401.
 	variable	ErrShow
 	string	sText
	variable	bCEDWasClosed, nHndAfter, nHndBefore = CedHandle()	// old handle which can be valid or invalid
	if ( CEDHandleIsOpen_ns() )				
		bCEDWasClosed = UFCom_FALSE
		sText = "\t1401 should be open  (old hnd:" + num2str( nHndBefore ) + ")"
	else
		bCEDWasClosed = UFCom_TRUE
		sText = "\t1401 was closed or off  (old hnd:" + num2str( nHndBefore ) + ")"
	endif
	nHndAfter = UFP_CedCloseAndOpen( nHndBefore ) 		// try to open it  independent of its state : open, closed, switched off or on (no messages!)
	CedHandleSet( nHndAfter )
	if ( CEDHandleIsOpen_ns() )				
		sText += ".... and has been (re)opened  (hnd = " + num2str( nHndAfter )+ ")"
		
		// we get 1401 type and memory size right here in the middle of  CEDGetStatus() because  1401 must be open.. 
		// ..we also print 1401 type and memory right here (before the status line is printed) but we could also disable printing here (ErrShow=0) and print 'nSize' and 'nType' later
		if ( ErrShow )
			printf "\tCEDStatus: \t"
			variable	nDriverType = CEDDriverType( ErrShow )			
			printf "\tCEDStatus: \t"
			variable	nType	   = CEDType( nHndAfter, ErrShow )			
			printf "\tCEDStatus: \t"
			variable	nSize	   = CEDGetMemSize( nHndAfter, ErrShow )	
		endif
	else
		sText += ".... but cannot be opened: defective? off?  (new hnd:" + num2str( nHndAfter ) + ")  "// attempt to open  was not successfull..
	endif
	if ( bCEDWasClosed )								// CED was closed at  the beginning so close it again
		nHndAfter	= UFP_CedClose( nHndAfter )								// ..so restore previous closed state  (no messages!)
		CedHandleSet( CED_NOT_OPEN )
		sText += ".... and has been closed again (hnd = " + num2str( CedHandle() ) + ")"
	endif
	printf "\tCEDStatus:\t\t%s \r", sText
End


static Function /S 	CedErrorString( state ) 
	variable	state
	string  	sTxt	= "OK"
	if ( state )
		sTxt	= UFP_CedGetErrorString( state )
	endif
	return	sTxt
End


static constant	CED_NOT_OPEN  	= -1		

Function		CedHandleSet( hnd )
	variable	hnd
	variable /G root:uf:CedHnd = hnd	// store directly in root:uf so that it can also be accessed  from FPuls V3xx
End 

Function		CedHandle()
// only the handle under program control (not the 1401 itself) is checked, if the open 1401 is accidentally turned off this function gives the wrong result 
	nvar /Z hnd	= root:uf:CedHnd	// store directly in root:uf so that it can also be accessed  from FPuls V3xx
	if ( ! nvar_exists( hnd ) )
		return	CED_NOT_OPEN
	else
		return	hnd
	endif
End 
	
Function		CEDHandleIsOpen_ns()
// only the handle under program control (not the 1401 itself) is checked, if the open 1401 is accidentally turned off this function gives the wrong result 
	return ( CedHandle()  !=  CED_NOT_OPEN )
End 
	
	
