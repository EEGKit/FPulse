// PCONTCED.IPF
// 
// Routines for 
//	continuos data acquisition and pulsing  using  CED hardware and IGORs background timer 
//	controlling the CED digital output 
//	measuring time durations spent in various program parts
//
// For the acquisition to work there must be IGOR extensions (= CED1401.XOP)  and  a SHORTCUT  to Wavemetrics\Igor Pro Folder\IgorExtensions
// CFS32.DLL  and  USE1432.DLL  must be accessible (copy to Windows\System directory)

// History:
// 010701 MAX. DATA RATES: ( 2xAD incl. TG, 2xDA, 1xDigOut), PCI interface
// 010701 1401POWER:  4 us works,   3 us does'nt work at all
// 010503 1401PLUS:     25 us works, 20 us does'nt work reliably (after changing to Eprom V3.22, previously much less)

// 030130	todo check why 16bit Power1401 +-5V range  makes  .9mV steps (should make .153mV steps!)
// 030313 wrapped  'Protocol' loop around the digital output (Digout pulses were output only in protocol 0 and were missing in all following protocols)
// 030320	periods between digout pulses can now be longer than 65535 sample intervals 
// 030707 major revision of digital output 
// 030805 major revision of acquisition 

//? todo the amplitude of the last blank is held appr. 1s until it is forced to zero (by StopADDA()?) . This is a problem only when the amp is not zero. Workaround: define a dummy frame thereafter.  
//? todo  is it necessary that DigOut times are integral multiples of smpint ....if yes then check.... 
  
#pragma rtGlobals=1								// Use modern global access method.

constant		MBYTE				= 0x100000

static constant	nTICKS				= 10			//20 		// wait nTICKS/60 s between calls to background function

//static constant	PRE				= 1			// CED1401 clock prescaler value
static constant	cMAX_TAREA_PTS 		= 0x080000 	// CED maximum transfer area size is 1MB under Win95. It must explicitly be enlarged under  Win2000

static constant	cADDAWAIT			= 0
static constant	cADDATRANSFER		= 1
static constant	TESTCEDMEMSIZE		= 80000000	// This is the maximum value used for testing the memory partitioning if no Ced is present.  It can be decreased  with the SetVariable  'gnShrinkCedMemMB'
											// Decrease 1401 memory for testing arbitrarily. Normal setting: larger than actual memory (CED has typically 16 or 32 MB)
static	 constant	MAX_REACTIONTIME	= 1.5			// Adjust chunk size  and repetitions such that the interval between display update is not longer than this seconds (if possible) 
											//...typical value 1 .. 3 . Bigger values improve overall performance as fewer chunks have to be processed.
											// Set this to a very high value to obtain maximum data rates ( this also decreases the 'Apply' time somewhat )

static	constant	cBKG_UNDEFINED		= 0
static	constant	cBKG_IDLING			= 1			// defined but not running
static	constant	cBKG_RUNNING		= 2

static	constant	cBKG_RUN_ALWAYS	= 0			// 0 : normally in the SW trig mode (=Start) the Bkg task is turned on and off.  1 lets is run continuously as it does in the HW trig mode (=E3E4)

// These constants are all to be eliminated.................030723....030804
static constant	cFAST_TG_COMPRESS	= 255		// set to >=255 for maximum compression , will be clipped and adjusted to the allowed range  1...255 / ( nAD + nTG ) 

//static constant	c1401WITH64KB		= 1 			// test : attempt to make FPULSE run with  very old 1401 having only 64KByte


Function		CreateGlobalsInFolder_Cont()
// creates all folder-specific variables. To be used once from CreateGlobals() as the current data folder is changed and not restored
	NewDataFolder  /O  /S root:cont							// acquisition: make a new data folder and use as CDF,  clear everything
	variable	/G	gnSmpInt
	variable	/G	gnCedType		= 0 
	variable	/G	gnAddIdx
	variable	/G	gnLastDacPos
	variable	/G	gReserve			= Inf
	variable	/G	gMinReserve		= Inf
	variable	/G	gPrediction		= 1
	variable	/G	gErrCnt			= 0
	variable	/G	gbRunning		= 0
	variable	/G	gbAcquiring		= 0 						// 031024
	variable	/G	gnProts			= 1  
	variable	/G	gnSmpInt
	variable	/G	gnPnts									// the number DA points (= AD points as there is only 1 sample rate, of 1 protocol) . There will be less TG points
	variable	/G	gnRep, gnReps
	variable	/G	gnChunk
	variable	/G	gPntPerChnk
	variable	/G	gChnkPerRep
	variable	/G	gnCntDA, gnOfsDA, gSmpArOfsDA
	variable	/G	gnCntAD, gnOfsAD, gSmpArOfsAD
	variable	/G	gnOfsDO
	variable	/G	gnCntTG
	variable	/G	gnCompressTG
	variable	/G	gMaxSmpPtspChan
	variable	/G	gbSearchStimTiming							// 030916
	variable	/G	gMaxReactionTime	= MAX_REACTIONTIME		// 031016
	variable	/G	gCedMemSize		= TESTCEDMEMSIZE		// 031030
	variable	/G	gShrinkCedMemMB	= 0						// 031030	 must  0  as this is used as a 'firsttime' indicator
	variable	/G	gRadTrigMode		= 0						// 031027  0 : normal SW trigger ('Start' button) ,    1 : HW trigger by E3E4 mode: Acq starts with HI pulse on CED Event4  ,    2 : timer triggered
	variable	/G	gbAppendData		= 0						// 031028  0 : open and write new file for each trigger   1 : keep writing into the same file until user selects 'Finish file' 
	variable	/G	gbIncFile
	variable	/G	gAcqStatus		= 0						// 031023  0 : waiting for 'Start',   1: 'Start' has been pressed (but Acq not yet started, waiting for E3E4 trigger),  2 : Acq is running
	string		/G	glstTG, glstAD, glstSingleAD
	string		/G	gsAllGains	
	make /O /N=(cMAXADCCHANS) wGain	= { 1, 1, 1, 1, 1, 1, 1, 1 }	// gain from either gain panel or from telegraph outputs, index is real channel nr, allow a maximum of 8 Adc channels
	make /O /N=(cMAXADCCHANS) wAD2TG	= {-2,-2,-2,-2,-2,-2,-2,-2 }	// must be initialized with 'AD_NOT_USED' . Later filled with either corresponding telegraph channel  or  'AD_HASNO_TG_CHAN'
	variable	/G	gBkPeriodTimer
	variable	/G	gnStartTicks		= 0		
	variable	/G	gnStopTicks		= 0		
	string		/G	sAllTimers					// list of  arbitrary timer names, numbers (0..9) and values
	if ( cUNDER_CONSTRUCTION )
	endif
End

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//   ACQUISITION  FUNCTIONS

Function		StartStimulusAndAcquisition()
	nvar		gSwpsWritten	= root:cfs:gSwpsWritten
	nvar		gbWriteMode	= root:cfs:gbWriteMode
	nvar		gRadTrigMode	= root:cont:gRadTrigMode
	nvar		gbAppendData	= root:cont:gbAppendData
	nvar		gbIncFile		= root:cont:gbIncFile
	nvar		gnPnts		= root:cont:gnPnts 
	variable	code
	string		bf
	gSwpsWritten =  0

	if ( gnPnts )
		sprintf bf, "\tSTARTING ACQUISITION %s %s... \r", SelectString( gRadTrigMode, " ( after 'Start' , " , " ( waiting for trigger on E3E4, "  ),  SelectString( gbAppendData, "writing separate files )", "appending to same file )" )
		Out( bf ) 
		NewStatusBar( "SB_ACQUISITION" , "Status Bar Acquisition" )	//  change message line on bottom depending on prg part
		KillAllTimers()
		InitializeCFSDescriptors()								// called late because wLines must be known
		// This function merely starts the sampling (=background task). This function is finished already at the BEGINNING of the sampling!
		code	= CedStartAcq()									// the error code is not yet used 
	else
		Alert( cLESSIMPORTANT,  "Empty stimulus file..... " ) 
	endif
	if ( ! CEDHandleIsOpen() )
		Alert( cIMPORTANT, "The CED 1401 is not open. " )			// acquisition will start but only in test mode with fake data
	endif
End	

Function		AutoBuildNextFilename()	
// Increment the automatically built file name = go to next  fileindex. Changes the globals  'gFileIndex'  and   'gsDataFile' 
	nvar		gFileIndex		= root:cfs:gFileIndex
	svar		gsDataFile		= root:cfs:gsDataFile
	do 			// 030617
		gFileIndex	+= 1										// Increment the automatically built file name = go to next  fileindex

		if ( gFileIndex ==  MAXINDEX_2LETTERS - 1 )
			Alert( cIMPORTANT,  " You are using the last file with current name and cell number ( " + GetPathFileExt( MAXINDEX_2LETTERS-1) + " ). " )
		endif
		if ( gFileIndex ==  MAXINDEX_2LETTERS  )
			Alert( cSEVERE,  " All files with current name and cell number from AA to ZZ have been used ( " + GetPathFileExt( 0 ) + "  to   " + GetPathFileExt( MAXINDEX_2LETTERS-1) + " ). \r\tThe last file will be overwritten." )
		endif
		gFileIndex	= min( gFileIndex , MAXINDEX_2LETTERS - 1 ) 
		gsDataFile	= GetFileName() + sCFS_EXT

		//printf "\t\tbuStart()  AutoBuildNextFilename()  checking  '%s'\t:  File  does  %s \r",  GetPathFileExt( gFileIndex ), SelectString( FileExists(  GetPathFileExt( gFileIndex ) ), "NOT exist: creating it...", "exist: skipping it..." )
	while  ( FileExists(  GetPathFileExt( gFileIndex ) )  &&  gFileIndex < MAXINDEX_2LETTERS - 1 )	// 030617 skip existing files
End

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  030723  NEW VERSION - FAST START

Function		CEDInitialize()
	nvar		gRadDebgGen		= root:dlg:gRadDebgGen
	nvar		gRadDebgSel		= root:dlg:gRadDebgSel
	nvar		pnDebgCed		= root:dlg:pnDebgCed
	nvar		gnPnts			= root:cont:gnPnts 
	nvar		gnSmpInt			= root:cont:gnSmpInt
	nvar		gnReps			= root:cont:gnReps
	nvar		gPntPerChnk		= root:cont:gPntPerChnk
	nvar		gbRunning		= root:cont:gbRunning 
	nvar		gbSearchStimTiming	= root:cont:gbSearchStimTiming
	nvar		gCedMemSize		= root:cont:gCedMemSize
	nvar		gShrinkCedMemMB	= root:cont:gShrinkCedMemMB
	nvar		gnCntTG			= root:cont:gnCntTg
	nvar		gnCntAD			= root:cont:gnCntAD
	nvar		gnCntDA			= root:cont:gnCntDA
	nvar		gnCompressTG		= root:cont:gnCompressTg

	svar		gsDigoutSlices		= root:stim:gsDigoutSlices
	variable	nSlices			= ItemsInList( gsDigoutSlices )							

	variable	code, nCEDMemPts, nTrfAreaPts	= 1
	string		bf

MarkPerfTestTime 600	// CEDInitialize: Begin
	variable	ShowMode = ( gRadDebgGen == 2 ||  ( gRadDebgSel > 1 &&  pnDebgCed ) ) ? MSGLINE : ERRLINE	

	sprintf bf,  "\t\tCed CEDInitialize()  running: %d  \r", gbRunning ;  Out1( bf, 0 ) 
	
	gnSmpInt  		= GetSmpIntFromStimFolder()					// this is an attempt to keep the data in the script/stimulus section and in the acquisition section separated 

	if ( gnPnts  &&  ! gbRunning )
		
		// Initialization is only executed once at startup, not with every new script
		//printf "\tCEDInitialize() \tCEDHandleIsOpen() : %d \r", 	CEDHandleIsOpen() 
		if ( ! CEDHandleIsOpen() ) 
			// xCEDOpen1( 0 )								// reduced functionality for testing (does not open - close - open )
			// xCEDOpen( 0, ERRBOX+ERR_FROM_IGOR )		// IGORs error box stops execution
			xCEDOpen( 0,  ERRLINE_C )						// do NOT show error box  ( Parameter1 = n1401 should be 0, see prog int lib 3.20, dec 99, p.5)
			if ( CEDHandleIsOpen() ) 
				code		= CEDInit1401DACADC( ShowMode )		// MSGLINE_C : print messages and possibly errors.  ERRLINE_C : print only errors .
				if ( code )
					xCEDClose( MSGLINE_C )
					return	code
				endif
			else
				if ( ! cUNDER_CONSTRUCTION )				// 031017
					Alert( cFATAL,  "Ced  is not responding. Aborting..." )
					xCEDClose( MSGLINE_C )
					return	cERROR
				endif
			endif
		endif

		if ( CEDHandleIsOpen() ) 
			code		= CedSetEvent( ShowMode )
			if ( code )
				xCEDClose( MSGLINE_C )
				return	code
			endif
			gCEDMemSize	= xCEDGetUserMemSize( ERRLINE_C )	// without Ced the default  TESTCEDMEMSIZE  would be used
		endif

		if ( gShrinkCedMemMB == 0 )							// true only during the very first program start : set the SetVariable with the Ced's memory size value 
			gShrinkCedMemMB	= gCEDMemSize / MBYTE
		endif												// in all further calls : use as memory size the value which the user has deliberately decreased...
		nCEDMemPts	= gShrinkCedMemMB * MBYTE / 2			// ..thereby improving loading speed  but unfortunately  making the maximum Windows interruption time much smaller...
		
		if ( gbSearchStimTiming )			// 030916
			SearchImprovedStimulusTiming( nCEDMemPts, gnPnts, gnSmpInt, gnCntDA, gnCntAD, gnCntTG, nSlices )
		endif

		nTrfAreaPts	= SetPoints( nCEDMemPts, gnPnts, gnSmpInt, gnCntDA, gnCntAD, gnCntTG, nSlices, cIMPORTANT, cFATAL )	// all params are points not bytes	

		if ( cELIMINATE_BLANK )			// 031120
			StoreChunkSet()																				// after SetPoints() : needs gnPnts and gnPntPerChk
		endif
		if ( nTrfAreaPts <= 0 )
			sprintf bf, "The number of stimulus data points (%d) could not be divided into CED memory without remainder. \r\tAdjust duration(s) in stimulus protocol slightly so that data points contains more small primes." , gnPnts
			string		lstPrimes	= BreakIntoPrimes( gnPnts )		// list containing the prime numbers which make up 'nPnts'
			Alert( cFATAL,  bf + "   " + lstPrimes[0,50] )
			return cERROR				
		endif

		wave  /Z	wRawADDA		= root:cont:wRawADDA		// 030723

		if ( waveExists( wRawADDA ) )
			if ( CEDHandleIsOpen() )
				code	= xCEDUnsetTransferArea( 0, wRawADDA, ShowMode ) 
				if ( code )
					xCEDClose( MSGLINE_C )
					KillWaves		wRawADDA
					return	code
				endif
			endif
			KillWaves		wRawADDA
		endif
		make  	/W /N=( nTrfAreaPts )  root:cont:wRawADDA 		// allowed area 0, allowed size up to 512KWords=1MB , 16 bit integer
		wave	wRawADDA		= root:cont:wRawADDA

MarkPerfTestTime 610	// CEDInitialize: Init

		// Go into acquisition without CED for the  test mode, with CED only when transfer buffers are ok, otherwise system hangs... 
		if ( ! CEDHandleIsOpen()  ||  xCEDSetTransferArea( 0, nTrfAreaPts, wRawADDA , ShowMode ) == 0 ) 
			if ( CEDInitializeDacBuffers() )						// ignore 'Transfer' and 'Convolve' times here during initialization as they have no effect on acquisition (only on load time)
				return	cERROR
			endif
		else
			Alert( cFATAL,  "Could not set transfer area. Try logging  in as Administrator. Aborting..." )
			return	cERROR
		endif

		SupplyWavesADC( gnPnts )							// 030804  constructs 'AdcN' and 'AdcTGN' waves  AFTER  PointPerChunk  and  CompressTG  has been computed
		SupplyWavesADCTG( gnPnts )

	else
		Alert( cLESSIMPORTANT,  "Empty stimulus file  or  stimulus/acquisition is already running. " ) 
	endif
MarkPerfTestTime 620	// CEDInitialize: Init
	return  0	//  030912 nPnts
End


// 030723
Function		CEDInitializeDacBuffers()
	// Acquisition mode initialization with Timer and swinging buffer 
	// Although the following variables are declared GLOBAL they should be used like STATIC (only  within this procedure file) !
	// Global as they must be accessed in MyBkgTask()  and  as their access should be fast..(how slow/fast are access functions?) 
	wave	wRawADDA		= root:cont:wRawADDA
	nvar	 	gnSmpInt			= root:cont:gnSmpInt
	nvar 		gnPnts			= root:cont:gnPnts
	nvar		gnReps			= root:cont:gnReps
	nvar		gChnkPerRep		= root:cont:gChnkPerRep
	nvar		gPntPerChnk		= root:cont:gPntPerChnk
	nvar		gnCompressTG		= root:cont:gnCompressTG
	nvar		gMaxSmpPtspChan	= root:cont:gMaxSmpPtspChan
	nvar		gnCntDA			= root:cont:gnCntDA,	 	gnOfsDA		= root:cont:gnOfsDA,	gSmpArOfsDA	= root:cont:gSmpArOfsDA
	nvar		gnCntAD			= root:cont:gnCntAD, 		gnOfsAD		= root:cont:gnOfsAD,	gSmpArOfsAD	= root:cont:gSmpArOfsAD	
	nvar		gnCntTG			= root:cont:gnCntTG
	nvar		gnOfsDO			= root:cont:gnOfsDO
	nvar		gRadDebgSel		= root:dlg:gRadDebgSel
	nvar		pnDebgCed		= root:dlg:pnDebgCed
	nvar		pnDebgAcqDA		= root:dlg:pnDebgAcqDA
	variable	SmpArStartByte,  TfHoArStartByte,  nPnts,  	nChunk, code = 0
	string		bf , buf, buf1

	variable	TAused		= TAuse( gPntPerChnk, gnCntDA, gnCntAD, cMAX_TAREA_PTS ) 
	variable	MemUsed		= MemUse(  gChnkPerRep, gPntPerChnk, gMaxSmpPtspChan )
	variable	FoM			= FigureOfMerit( gChnkPerRep, gPntPerChnk, gMaxSmpPtspChan, gnCntDA, gnCntAD, gnCntTG, gnCompressTG, cMAX_TAREA_PTS ) 
	variable	ChunkTimeSec	= gPntPerChnk * gnSmpInt /  1000000
	nvar		gbRunning	= root:cont:gbRunning
	nvar		gbAcquiring	= root:cont:gbAcquiring	// 031024 
	sprintf bf, "\t\tCed CedStartAcq()   CEDInitializeDacBuffers() \tRunning:%2g  Acquiring:%2d \r", gbRunning, gbAcquiring
	Out1( bf, 0 ) //1 )
	sprintf bf, "\t\tCed CedStartAcq()   nReps:%d  ChnkpRep:%d  PtpChk:%d  DA:%d  AD:%d  TG:%d  SmpInt:%dus  Cmpr:%d  ReactTm:%.1lfs  TA:%d%%  Mem:%d%%  FoM:%.1lf%% \r", gnReps, gChnkPerRep, gPntPerChnk, gnCntDA, gnCntAD, gnCntTG, gnSmpInt,  gnCompressTG, ChunkTimeSec, TAUsed, MemUsed, FoM
	Out1( bf, 1 )
	if ( gRadDebgSel > 1  &&   pnDebgCed ) 
		printf "\t\t\tCed CedStartAcq()  Rps:%d  ChkpRep:%d  PtpChk:%d  DA:%d  AD:%d  TG:%d  SmpInt:%dus  Cmpr:%d  ReactTm:%.1lfs  TA:%d%%  Mem:%d%%  FoM:%.1lf%%  OsDA:%d  OsAD:%d  OsDO:%d \r", gnReps, gChnkPerRep, gPntPerChnk, gnCntDA, gnCntAD, gnCntTG, gnSmpInt,  gnCompressTG, ChunkTimeSec, TAUsed, MemUsed, FoM, gnOfsDA, gnOfsAD, gnOfsDO 
	endif
	
	//sprintf bf, "\t\t\t\tCed Cnv>DA14>Cpy\t  IgorWave \t>HoSB \t=HoSB \t>TASB \t>SASB \t DAPnts\r"; Out( bf )
MarkPerfTestTime 611	// CEDInitialize: Before Loop chunks
	for ( nChunk = 0; nChunk < gChnkPerRep; nChunk += 1)		
MarkPerfTestTime 612	// CEDInitialize: Start Loop chunks
if ( cPROT_AWARE )
		ConvolveBuffersDA( nChunk, 0, gChnkPerRep, gnCntDA, gPntPerChnk, wRawADDA, gnOfsDA/2, 1 )			// ~ 3ms
else
		ConvolveBuffersDA( nChunk, 0, gChnkPerRep, gnCntDA, gPntPerChnk, wRawADDA, gnOfsDA/2, gnPnts )		// ~ 3ms
endif
MarkPerfTestTime 614	// CEDInitialize: ConvolveDA
		if ( CEDHandleIsOpen() ) 

			nPnts   			= gPntPerChnk * gnCntDA 
		 	TfHoArStartByte		= gnOfsDA		+ 2 * nPnts * mod( nChunk, 2 ) //  only  2 swaps
			SmpArStartByte		= gSmpArOfsDA		+ 2 * nPnts * nChunk 
		
			// 031120
if ( cELIMINATE_BLANK )
			variable	begPt	= gPntPerChnk * nChunk					// BegPt and EndPt are points in the CED sampling area (typ. 16MB) ....
			variable	endPt	= gPntPerChnk * ( nChunk + 1 )				// The same BegPt and EndPt are passed multiple times if nReps is >1 (=long scripts and/or many protocols)
			variable	repOs	= 0									// BegPt and EndPt  PLUS the repetition offset 'repOs' gives the true point number in the DAC wave independently from the CED sampling area size
			variable	bStoreIt	= StoreChunkOrNotOrNot( nChunk )				
			variable	BlankAmp	= wRawAdda[ TfHoArStartByte / 2  ]			// use the first value of this chunk as amplitude for the whole chunk
			if ( ( gRadDebgSel ==1  ||  gRadDebgSel == 3 )  &&  pnDebgAcqDA )
				printf "\t\tAcqDA TfHoA1\t%8d\t ->\tSmpAr:\t %11d \t(pts:%8d)  \tBg:\t%7d\tNd:\t%7d\tChunk:\t%7d\tStoring:%2d\tAmp:\t%7d\t   \r", TfHoArStartByte, SmpArStartByte, nPnts, BegPt+repOs, EndPt+repOs, nChunk, bStoreIt, BlankAmp
			endif
			if (	bStoreIt )
				 sprintf buf, "TO1401,%d,%d,%d;", TfHoArStartByte, 2*nPnts, TfHoArStartByte ;  xCEDSendString( buf )  // copy  Dac data from host to Ced transferArea. Ced TransferArea and HostArea start at the same point
				 code	+= GetAndInterpretAcqErrors( "SmpStart", "TO1401", nChunk, gnReps * gChnkPerRep )
MarkPerfTestTime 615	// CEDInitialize: GetErrors TO1401
			else
				 sprintf buf, "SS2,C,%d,%d,%d;", TfHoArStartByte, 2*nPnts, BlankAmp;  xCEDSendString( buf )  		// fill Ced transferArea with constant 'Blank' amplitude. This is MUCH faster than the above 'TO1401' which is very slow
				 code	+= GetAndInterpretAcqErrors( "SmpStart", "SS2    ", nChunk, gnReps * gChnkPerRep )
MarkPerfTestTime 616	// CEDInitialize: GetErrors SS2
			endif
			// ..  031120
else
			 sprintf buf, "TO1401,%d,%d,%d;", TfHoArStartByte, 2*nPnts, TfHoArStartByte ;  xCEDSendString( buf ) 		 // copy  Dac data from host to Ced transferArea. Ced TransferArea and HostArea start at the same point
			 code	+= GetAndInterpretAcqErrors( "SmpStart", "TO1401", nChunk, gnReps * gChnkPerRep )
			 MarkPerfTestTime 615	// CEDInitialize: GetErrors TO1401
endif


			 sprintf buf,  "SM2,C,%d,%d,%d;", SmpArStartByte, TfHoArStartByte, 2*nPnts;   xCEDSendString( buf )  		 // copy  Dac data from Ced transfer area to large sample area
MarkPerfTestTime 617	// CEDInitialize: SendString SM2 Dac
			 code	+= GetAndInterpretAcqErrors( "SmpStart", "SM2 Dac", nChunk, gnReps * gChnkPerRep )
MarkPerfTestTime 618	// CEDInitialize: GetErrors SM2 Dac

// combining is faster and theoretically possible, but the error detection will suffer
// gh			 // TO1401 : TransferArea and HostArea start at the same point.   SM2 : Copy  Dac data from transfer area to large sample area
//			sprintf buf, "TO1401,%d,%d,%d;SM2,C,%d,%d,%d;", TfHoArStartByte, 2*nPnts, TfHoArStartByte,    SmpArStartByte, TfHoArStartByte, 2*nPnts ;
//			xCEDSendString( bguf )				
//			code	 = GetAndInterpretAcqErrors( "SmpStart", "TO1401 + SM2 Dac", nChunk, gnReps * gChnkPerRep )
		endif
	endfor
MarkPerfTestTime 619	// CEDInitialize: After  Loop chunks 
	return	code
End


// 030723
Function		CedStartAcq()
	// Acquisition mode initialization with Timer and swinging buffer 
	// Although the following variables are declared GLOBAL they should be used like STATIC (only  within this procedure file) !
	// Global as they must be accessed in MyBkgTask()  and  as their access should be fast..(how slow/fast are access functions?) 
	nvar		gnReps		= root:cont:gnReps
	nvar		gnRep		= root:cont:gnRep
	nvar		gChnkPerRep	= root:cont:gChnkPerRep
	nvar		gPntPerChnk	= root:cont:gPntPerChnk
	nvar		gnSmpInt		= root:cont:gnSmpInt
	nvar		gnChunk		= root:cont:gnChunk
	nvar		gnLastDacPos	= root:cont:gnLastDacPos
	nvar		gnAddIdx		= root:cont:gnAddIdx
	nvar		gReserve		= root:cont:gReserve
	nvar		gMinReserve	= root:cont:gMinReserve
	nvar		gErrCnt		= root:cont:gErrCnt
	nvar		gbRunning	= root:cont:gbRunning
	nvar		gbAcquiring	= root:cont:gbAcquiring	// 031024 
	nvar		gnStartTicks	= root:cont:gnStartTicks, 	gBkPeriodTimer	= root:cont:gBkPeriodTimer
	nvar		gPrevBlk		= root:disp:gPrevBlk
	nvar		gnCntDA		= root:cont:gnCntDA,	 	gnOfsDA		= root:cont:gnOfsDA,	gSmpArOfsDA	= root:cont:gSmpArOfsDA
	nvar		gnCntAD		= root:cont:gnCntAD, 		gnOfsAD		= root:cont:gnOfsAD,	gSmpArOfsAD	= root:cont:gSmpArOfsAD	
	nvar		gnCntTG		= root:cont:gnCntTG
	nvar		gnOfsDO		= root:cont:gnOfsDO
	svar		glstAD		= root:cont:glstAD
	svar		glstTG		= root:cont:glstTG

	nvar		gRadTrigMode	= root:cont:gRadTrigMode
	nvar		gRadDebgSel	= root:dlg:gRadDebgSel
	nvar		pnDebgAcqDA	= root:dlg:pnDebgAcqDA
	string		bf

	if ( ArmDAC( gSmpArOfsDA, gPntPerChnk * gnCntDA * gChnkPerRep, gnReps ) == cERROR )
		return	cERROR						// 031016 Avoid  the user ignoring this error and continuing . This error happens very rarely and is not understood...
	endif
	if ( ArmADC( gSmpArOfsAD, gPntPerChnk * (gnCntAD+gnCntTG) * gChnkPerRep, gnReps, glstAD + glstTG ) == cERROR )
		return	cERROR						// 031016 Avoid  the user ignoring this error and continuing . This error happens very rarely and is not understood...
	endif
	if ( ArmDig( gnOfsDO ) == cERROR )
		return	cERROR						// 031016 Avoid  the user ignoring this error and continuing . This error happens very rarely and is not understood...
	endif	

	ResetTimer( "Convolve" )
	ResetTimer( "Transfer" )		
	ResetTimer( "Graphics" )		
	ResetTimer( "OnlineAn" )		
	ResetTimer( "CFSWrite" )		
	ResetTimer( "Process" )		
	ResetTimer( "TotalADDA" )		

	// Establish a dependency so that the current acquisition status (waiting for 'Start' to be pressed, waiting for trigger on E3E4, acquiring, finished acquisition) is reflected in a ColorTextField
	SetFormula	root:cont:gAcqStatus, "root:cont:gbRunning + 2 * root:cont:gbAcquiring"		// 031024
	
	gbRunning	= TRUE 							// 031030
	StartStopFinishButtonTitles()						// 031030 reflect change of 'gbRunning'   
	//  Never allow to go into 'LoadScriptxx()' when acquisition is running, because 'LoadSc..' initializes the program: especially waves and transfer area
	EnableButton( "PnPuls", "buApplyScript",	DISABLE )		//  Never allow to go into 'LoadScriptxx()' when acquisition is running..
	EnableButton( "PnPuls", "buLoadScript",	DISABLE )		//  ..because 'LoadSc..' initializes the program: especially waves and transfer area
	EnableSetVariable( "PnPuls", "gnProts",	cNOEDIT )	// ..we cannot change the number of protocols as this would trigger 'ApplyScript()'
	StartStopFinishButtonTitles()						// ugly here...button text should change automatically

	// set globals needed in ADDASwing ( background task function takes no parameters )
	gnStartTicks	= ticks			// save current  tick count  (in 1/60s since computer was started) 
	gnRep		= 1    
	gnChunk		= 0    
	gnAddIdx		= 0
	gnLastDacPos	= 0
	gReserve		= Inf
	gMinReserve	= Inf
	gErrCnt		= 0

	//  for initialization of display : initialize with every new block
	gPrevBlk		= -1

	Process( -1 )			//  PULSE  specific: for initialization of CFS writing

	StartTimer( "TotalADDA" )		

	gBkPeriodTimer 	= 	startMSTimer
	if ( gBkPeriodTimer 	== -1 )
		printf "*****************All timers are in use 5...\r" 
	endif

	// Interrupting longer  than 'MaxBkTime' leads to data loss
	//variable	SetTimerMilliSec = ( gPntPerChnk * gnSmpInt ) / 1000 
	//sprintf bf, "\t\tCed CedStartAcq()  SmpInt:%d  SetTimerMilliSec:%d   TimerTicks:%d  TimerTicks(period):%d   MaxBkTime:%6dms  Reps:%d \r", gnSmpInt, SetTimerMilliSec, SetTimerMilliSec/1000*60, nTICKS, SetTimerMilliSec * ( gChnkPerRep - 1 ),  gnReps 
	//Out1( bf, 1 )


	//PrintBackGroundInfo( "CedStartAcq(5)" , "")
	BackGroundInfo	
	if ( v_Flag == cBKG_UNDEFINED )		// 031025   for  the hardware triggered E3E4 mode : We call this function from the BackGround task function ( StopADDA() -> buStart() -> 'StartStimulusAndAcquisition'  ->  'CedStartAcq()'  ... 
		// printf "\t\t\tBackGroundInfo   '%s'  , v_Flag:%d :  is  %s ,  next scheduled execution:%d  \r ", s_Value, v_Flag, SelectString( v_Flag-1, "not defined", "defined but not running (idle)", "running" ), v_NextRun 
		SetBackground	  MyBkgTask()		// ...but it is not allowed (and we must avoid) to change a BackGround task function from within a BackGround task function 
		CtrlBackground	  start ,  period = nTicks, noBurst=1//0//1 //? nB0=try to catch up, nB1=don't catch up
		// printf "\t\t\tCedStartAcq(5a) \t\t\tBkg task: set and start \r "
	endif
	
	if (  !  cBKG_RUN_ALWAYS )
		if ( v_Flag == cBKG_IDLING )		// 031025   for  the hardware triggered E3E4 mode : We call this function from the BackGround task function ( StopADDA() -> buStart() -> 'StartStimulusAndAcquisition'  ->  'CedStartAcq()'  ... 
			CtrlBackground	  start ,  period = nTicks, noBurst=1//0//1 //? nB0=try to catch up, nB1=don't catch up
			 // printf "\t\t\tCedStartAcq(5b) \t\t\tBkg task: start \r "
		endif
	endif

	if ( ArmClockStart( gnSmpInt, gRadTrigMode ) )	
printf "ERROR in ArmClockStart() \r"
//		return	cERROR						// 031016 Avoid  the user ignoring this error and continuing . This error happens very rarely and is not understood...
	endif	

//	if ( gRadDebgSel > 2  &&  pnDebgAcqDA )
//		printf  "\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\tAcqDA Cpy>ADHo>Cnv  \t ADPnts\t  SASB\t\t>TASb \t>HoSB \t   =HoSB \t IgorWave \t\t\t[+ch1,+ch2...] \r"
//	endif

	return 0	// todo: could also but does not return error code
End

Function		PrintBackGroundInfo( sText1, sText2 )
	string		sText1, sText2
	BackGroundInfo	
	printf "\t\t\t%s\tBkgInfo %s\tRunAlways:%d\t%s \tPeriod:%3d \tnext scheduled execution:%d  \tv_Flag:%d :  is  %s \r ", pad( sText1, 18),  pad( sText2, 10 ), cBKG_RUN_ALWAYS, pd(s_Value,12), v_Period,  v_NextRun , v_Flag, SelectString( v_Flag-1, "not defined", "defined but not running (idle)", "running" )
End

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function		MyBkgTask()
// CONT mode routine with swinging buffer
	variable	nCode = ADDASwing()
	return	nCode == cERROR			//  return 0 (=cADDAWAIT) if CED was not yet ready to keep the background task running, return !=0 to kill background task
End


Static  Function	ClipCompressFactor( nAD, nTG,  PtpChk )
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


Static Function  ADDASwing()
	nvar		gnSmpInt		= root:cont:gnSmpInt
	nvar		gnProts		= root:cont:gnProts
	nvar 		gnPnts		= root:cont:gnPnts
	nvar		gnReps		= root:cont:gnReps
	nvar		gnRep		= root:cont:gnRep
	nvar		gnChunk		= root:cont:gnChunk
	nvar		gChnkPerRep	= root:cont:gChnkPerRep 
	nvar		gPntPerChnk	= root:cont:gPntPerChnk
	nvar		gnCntDA		= root:cont:gnCntDA,	 	gnOfsDA		= root:cont:gnOfsDA,	gSmpArOfsDA	= root:cont:gSmpArOfsDA
	nvar		gnCntAD		= root:cont:gnCntAD, 		gnOfsAD		= root:cont:gnOfsAD,	gSmpArOfsAD	= root:cont:gSmpArOfsAD
	nvar		gnOfsDO		= root:cont:gnOfsDO
	nvar		gnCntTG		= root:cont:gnCntTG
	nvar		gnCompress	= root:cont:gnCompressTG
	nvar		gbAppendData	= root:cont:gbAppendData
	nvar		gBkPeriodTimer	= root:cont:gBkPeriodTimer 
	nvar		gRadDebgSel	= root:dlg:gRadDebgSel
	nvar		pnDebgAcqDA	= root:dlg:pnDebgAcqDA
	nvar		pnDebgAcqAD	= root:dlg:pnDebgAcqAD
	wave	wRawADDA	= root:cont:wRawADDA
	string		buf
	// DAC timing (via PtpChk!) must make ADCBST flag checking unnecessary
	
	variable 	SmpArStartByte, TfHoArStartByte, nPnts, nDacReady, code, nTruePt

	//printf "\t\t\tADDASwing(1)  \tnChunk:%2d    nDacReady :%2d  \tticks:%d\r", gnChunk,  nDacReady, ticks 

	if ( !CEDHandleIsOpen() )						// MODE  WITHOUT  CED works well for testing
		StartTimer( "Convolve" )		

		if ( cPROT_AWARE )
			ConvolveBuffersDA( gnChunk, gnRep-1, gChnkPerRep, gnCntDA, gPntPerChnk, wRawADDA, gnOfsDA/2, 1 ) 
		else
			ConvolveBuffersDA( gnChunk, gnRep-1, gChnkPerRep, gnCntDA, gPntPerChnk, wRawADDA, gnOfsDA/2, gnPnts ) 
		endif
		StopTimer( "Convolve" )		
		StartTimer( "Transfer" )		
		// although test copying (missing CED) is much slower than TOHOST/TO1401 (6us compared to 1us / WORD) this mode without CED..
		// ..works more reliably and/ or at faster rates. Why? Probably because the timing is more determinate (no waiting for the DAC to be ready) 
 		TestCopyRawDAC_ADC( gnChunk, gPntPerChnk, wRawADDA, gnOfsDA/2, gnOfsAD/2  )
		StopTimer( "Transfer" )		
 	else											// MODE  WITH  CED 
		//printf "\t\tADDASwing(A)  gnRep:%d ?<? nReps:%d \r", gnRep, nReps
		nDacReady =  CheckReadyDacPosition( "MEMDAC,P;", gnRep, gnChunk ) 
		if ( nDacReady == cADDATRANSFER ) 
			 //printf "\t\tADDASwing(B)   gnRep:%d ?<? nReps:%d \r", gnRep, nReps

			if (  		  gnRep < gnReps ) // DAC: don't transfer the last 'ChunkspRep' (appr. 250..500kByte, same as in  ADDAStart) as they are already transfered..
				StartTimer( "Convolve" )		
				//printf "\t\tADDASwing(C)  gnRep:%d ?<? nReps:%d ConvDA \r", gnRep, nReps
				//print "C", gnRep, "-", gnChunk, gnRep,	ChunkspRep, gnCntDA, PtpChk, wRawADDA, OffsDA/2
				// all Dac buffers have 'rollover' :  when the repetition index has passed the last  then we must use the data from the first (=0)
				if ( cPROT_AWARE )
					ConvolveBuffersDA( gnChunk, gnRep,	gChnkPerRep, gnCntDA, gPntPerChnk, wRawADDA, gnOfsDA/2, 1 )	
				else
					ConvolveBuffersDA( gnChunk, gnRep,	gChnkPerRep, gnCntDA, gPntPerChnk, wRawADDA, gnOfsDA/2, gnPnts )	
				endif
				StopTimer( "Convolve" )		
				StartTimer( "Transfer" )		
				nPnts			= gPntPerChnk * gnCntDA 
	 			TfHoArStartByte		= gnOfsDA	 	+ 2 * nPnts * mod( gnChunk, 2 ) //  only  2 swaps
				SmpArStartByte		= gSmpArOfsDA		+ 2 * nPnts * gnChunk 

				if ( cELIMINATE_BLANK )	// 031120
					variable	begPt	= gPntPerChnk * gnChunk					// BegPt and EndPt are points in the CED sampling area (typ. 16MB) ....
					variable	endPt	= gPntPerChnk * ( gnChunk + 1 )				// The same BegPt and EndPt are passed multiple times if nReps is >1 (=long scripts and/or many protocols)
					variable	repOs	= gnRep * gPntPerChnk * gChnkPerRep		// BegPt and EndPt  PLUS the repetition offset 'repOs' gives the true point number in the DAC wave independently from the CED sampling area size
					variable	nBigChunk= ( BegPt + RepOs ) / gPntPerChnk 
					variable	bStoreIt	= StoreChunkOrNotOrNot( nBigChunk )				
					variable	BlankAmp	= wRawAdda[ TfHoArStartByte / 2  ]			// use the first value of this chunk as amplitude for the whole chunk
					if ( ( gRadDebgSel == 1  ||  gRadDebgSel == 3 )  &&  pnDebgAcqDA )
						printf "\t\tAcqDA TfHoA2\t%8d\t ->\tSmpAr:\t %11d \t(pts:%8d)  \tBg:\t%7d\tNd:\t%7d\tChunk:\t%7d\tStoring:%2d\tAmp:\t%7d\t  \r", TfHoArStartByte, SmpArStartByte, nPnts, BegPt+repOs, EndPt+repOs, nBigChunk, bStoreIt, BlankAmp
					endif
					if (	bStoreIt )
						sprintf buf, "TO1401,%d,%d,%d;", TfHoArStartByte, 2*nPnts, TfHoArStartByte ;  xCEDSendString( buf );  // TransferArea and HostArea start at the same point
						code		= GetAndInterpretAcqErrors( "Dac      ", "TO1401 ", gnRep * gChnkPerRep + gnChunk, gnReps * gChnkPerRep )
	 				else
						 sprintf buf, "SS2,C,%d,%d,%d;", TfHoArStartByte, 2*nPnts, BlankAmp;  xCEDSendString( buf )  			// fill Ced transferArea with constant 'Blank' amplitude. This is MUCH faster than the above 'TO1401' which is very slow
						 code	= GetAndInterpretAcqErrors( "SmpStart", "SS2    ", gnChunk, gnReps * gChnkPerRep )
					endif
					// ...031120
				else	
					 sprintf buf, "TO1401,%d,%d,%d;", TfHoArStartByte, 2*nPnts, TfHoArStartByte ;  xCEDSendString( buf );  // TransferArea and HostArea start at the same point
					 code		= GetAndInterpretAcqErrors( "Dac      ", "TO1401 ", gnRep * gChnkPerRep + gnChunk, gnReps * gChnkPerRep )
				endif


				sprintf buf,  "SM2,C,%d,%d,%d;", SmpArStartByte, TfHoArStartByte, 2*nPnts;   xCEDSendString( buf );     // copy  Dac data from transfer area to large sample area
				code		= GetAndInterpretAcqErrors( "Dac      ", "SM2,Dac", gnRep * gChnkPerRep + gnChunk, gnReps * gChnkPerRep )
 				StopTimer( "Transfer" )		
			endif

			StartTimer( "Transfer" )	

			nPnts			= gPntPerChnk * ( gnCntAD + gnCntTG ) 
			TfHoArStartByte		= gnOfsAD	 	+ round( 2 * nPnts * mod( gnChunk, 2 ) * ( gnCntAD + gnCntTG / gnCompress ) / (  gnCntAD + gnCntTG ) )// only  2 swaps
			SmpArStartByte		= gSmpArOfsAD		+ 2 * nPnts * gnChunk
			nTruePt			= ( ( gnRep - 1 ) * gChnkPerRep +  gnChunk ) * nPnts 
			//printf "\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\tAcqAD  \t%8d\t%10d\t%8d\t%10d \r", nPnts,SmpArStartByte, TfHoArStartByte, nTruePt	// 

			variable	c, nTGSrc, nTGDest, nTGPntsCompressed


			// SEND   1  string to the 1401  for each command : should be slow but should be better as errors are indicated errors more precisely
			// Extract interleaved  true AD channels without compression
			for ( c = 0; c < gnCntAD; c += 1 )						// ASSUMPTION: order of channels is first ALL AD, afterwards ALL TG
				nTGSrc			= SmpArStartByte + 2 * c
				nTGDest			= round( TfHoArStartByte + 2 * nPnts *  		c 		 / ( gnCntAD + gnCntTG ) )	// rounding is OK here as there will be no remainder
				nTGPntsCompressed	= round( nPnts / ( gnCntAD + gnCntTG ) )									// rounding is OK here as there will be no remainder
				sprintf buf,  "SN2,X,%d,%d,%d,%d;", nTGDest, nTGSrc, 2 * nTGPntsCompressed, 	(gnCntAD + gnCntTG);   xCEDSendString( buf );    // separate interleaved channels within large (~16MB) sample area to 1MB transfer area 
				code		= GetAndInterpretAcqErrors( "ExtractAD", "SN2,X,Ad", gnRep * gChnkPerRep + gnChunk, gnReps * gChnkPerRep )
				 //print buf, longBuf
			endfor

			// Extract interleaved Telegraph channel data  and compress them in 1 step
			for ( c = gnCntAD; c < gnCntAD + gnCntTG; c += 1 )		// ASSUMPTION: order of channels is first ALL AD, afterwards ALL TG
				nTGSrc			= SmpArStartByte + 2 * c
				nTGDest			= trunc( TfHoArStartByte + 2 * nPnts * ( gnCntAD + (c-gnCntAD) / gnCompress ) / ( gnCntAD + gnCntTG ) )
				nTGPntsCompressed	= trunc( nPnts / ( gnCntAD + gnCntTG )   / gnCompress ) 
				sprintf buf,  "SN2,X,%d,%d,%d,%d;", nTGDest, nTGSrc, 2 * nTGPntsCompressed, 	(gnCntAD + gnCntTG) * gnCompress;   xCEDSendString( buf );    // separate interleaved channels within large (~16MB) sample area to 1MB transfer area 
				code		= GetAndInterpretAcqErrors( "ExtrCmpTG", "SN2,X,TG", gnRep * gChnkPerRep + gnChunk, gnReps * gChnkPerRep )
			endfor


//			// 030806  TEST : SEND ONLY  1  string to the 1401  containing multiple commands : does not speed up the acquisition and does not avoid any errors
//			// Extract interleaved  true AD channels without compression
//			string longbuf = ""
//			for ( c = 0; c < gnCntAD; c += 1 )						// ASSUMPTION: order of channels is first ALL AD, afterwards ALL TG
//				nTGSrc			= SmpArStartByte + 2 * c
//				nTGDest			= round( TfHoArStartByte + 2 * nPnts *  		c 		 / ( gnCntAD + gnCntTG ) )	// rounding is OK here as there will be no remainder
//				nTGPntsCompressed	= round( nPnts / ( gnCntAD + gnCntTG ) )									// rounding is OK here as there will be no remainder
//				sprintf buf,  "SN2,X,%d,%d,%d,%d;", nTGDest, nTGSrc, 2 * nTGPntsCompressed, 	(gnCntAD + gnCntTG)  	// separate interleaved channels within large (~16MB) sample area to 1MB transfer area 
//				longbuf += buf
//			endfor
//			// Extract interleaved Telegraph channel data  and compress them in 1 step
//			for ( c = gnCntAD; c < gnCntAD + gnCntTG; c += 1 )		// ASSUMPTION: order of channels is first ALL AD, afterwards ALL TG
//				nTGSrc			= SmpArStartByte + 2 * c
//				nTGDest			= trunc( TfHoArStartByte + 2 * nPnts * ( gnCntAD + (c-gnCntAD) / gnCompress ) / ( gnCntAD + gnCntTG ) )
//				nTGPntsCompressed	= trunc( nPnts / ( gnCntAD + gnCntTG )   / gnCompress ) 
//				sprintf buf,  "SN2,X,%d,%d,%d,%d;", nTGDest, nTGSrc, 2 * nTGPntsCompressed, 	(gnCntAD + gnCntTG) * gnCompress	// separate interleaved channels within large (~16MB) sample area to 1MB transfer area 
//				longbuf += buf
//			endfor
//			xCEDSendString( longbuf );    // separate interleaved channels within large (~16MB) sample area to 1MB transfer area 
//			code		= GetAndInterpretAcqErrors( "ExtrCmpTG", "SN2,X,TG", gnRep * gChnkPerRep + gnChunk, gnReps * gChnkPerRep )


			variable nPntsCompressed	= round( nPnts * ( gnCntAD +  gnCntTG / gnCompress ) / ( gnCntAD + gnCntTG ) ) 
			//variable nPntsTest		= ( ( nPnts / gnCompress ) * ( gnCntAD * gnCompress  +  gnCntTG) ) / ( gnCntAD + gnCntTG )	// same without rounding (if Igor recognizes paranthesis levels)


			if ( cELIMINATE_BLANK )				// 031120
				begPt	= gPntPerChnk * gnChunk					// BegPt and EndPt are points in the CED sampling area (typ. 16MB) ....
				endPt	= gPntPerChnk * ( gnChunk + 1 )				// The same BegPt and EndPt are passed multiple times if nReps is >1 (=long scripts and/or many protocols)
				repOs	= ( gnRep - 1 ) * gPntPerChnk * gChnkPerRep	// BegPt and EndPt  PLUS the repetition offset 'repOs' gives the true point number in the DAC wave independently from the CED sampling area size
				nBigChunk= ( BegPt + RepOs ) / gPntPerChnk 
				bStoreIt	= StoreChunkOrNotOrNot( nBigChunk )				
				if ( ( gRadDebgSel == 1  ||  gRadDebgSel == 3 )  &&  pnDebgAcqAD )
					printf "\t\tAcqAD TfHoA3\t%8d\t ->\tSmpAr:\t %11d \t(pts:%8d)  \tBg:\t%7d\tNd:\t%7d\tChunk:\t%7d\tStoring:%2d\t  \r", TfHoArStartByte, SmpArStartByte, nPnts, BegPt+repOs, EndPt+repOs, nBigChunk, bStoreIt
				endif
				if (	bStoreIt )
					sprintf  buf, "TOHOST,%d,%d,%d;", TfHoArStartByte, 2 * nPntsCompressed, TfHoArStartByte ;  xCEDSendString( buf );  // TransferArea and HostArea start at the same point
					// print "nPnts", nPnts, "nPntsCompressed ", nPntsCompressed ,  nPntsTest, "bytes", nPntsCompressed *2, "buf", buf
					code		= GetAndInterpretAcqErrors( "Sampling", "TOHOST", gnRep * gChnkPerRep + gnChunk, gnReps * gChnkPerRep )
				endif
			else					// ....031120

				sprintf  buf, "TOHOST,%d,%d,%d;", TfHoArStartByte, 2 * nPntsCompressed, TfHoArStartByte ;  xCEDSendString( buf );  // TransferArea and HostArea start at the same point
				// print "nPnts", nPnts, "nPntsCompressed ", nPntsCompressed ,  nPntsTest, "bytes", nPntsCompressed *2, "buf", buf
				code		= GetAndInterpretAcqErrors( "Sampling", "TOHOST", gnRep * gChnkPerRep + gnChunk, gnReps * gChnkPerRep )

			endif					// ....031120.....

			StopTimer( "Transfer" )		

		endif		
	endif	
//print nDacReady
	if (  !CEDHandleIsOpen()   ||  nDacReady  == cADDATRANSFER )	// WITH  or  WITHOUT  CED

		StartTimer( "Convolve" )	
		variable	ptAD
if (  cPROT_AWARE )
		ptAD = DeconvolveBuffsAD( gnChunk, gnRep, gChnkPerRep, gPntPerChnk, wRawADDA, gnOfsAD/2, gnCntAD , gnCntTG, gnCompress, 1  )	//? 221002 gnRep=nReps ->0???
else
		ptAD = DeconvolveBuffsAD( gnChunk, gnRep, gChnkPerRep, gPntPerChnk, wRawADDA, gnOfsAD/2, gnCntAD , gnCntTG, gnCompress, gnPnts )	//? 221002 gnRep=nReps ->0???
endif

		StopTimer( "Convolve" )		

		// HERE the real work is done : CFS Write, Display , PoverN correction
		StartTimer( "Process" )						// the current CED pointer is the only information this function gets
		//printf "\tADDASwing()  calls Process( %4d )  \t%2d  gnRep:%2d/%2d \r", ptAD, gnProts,  gnRep, nReps

		Process( ptAD )	// different approach: call CFSStore() and TDisplaySuperImposedSweeps() from WITHIN this function

		StopTimer( "Process" )		

		// printf "\t\t\t\tADDASwing() next chunk   \tgnchunk\t:%3d\t/%3d\t ->%3d\t--> nrep\t:%3d\t/%3d\t\tticks:%d \r", gnChunk, gChnkPerRep, mod( gnChunk + 1, gChnkPerRep ), gnRep, gnReps, ticks
		gnChunk	= mod( gnChunk + 1, gChnkPerRep )					// ..increment Chunk  or reset  Chunk to 0
		if ( gnChunk == 0 )				 						// if  the inner  Chunk loop  has just been iinished.. 
			gnRep += 1										// ..do next  Rep  (or first Rep again if  Rep has been reset above) and..
			 //printf "\t\t\tADDASwing() next rep  \t\t\tgnChunk\t:%3d\t/%3d\t ->%3d\t--> nRep\t:%3d\t/%3d\t\tticks:%d \r", gnChunk, gChnkPerRep, mod( gnChunk + 1, gChnkPerRep ), gnRep, gnReps, ticks
			if ( gnRep > gnReps )
				if ( ! gbAppendData )								// 031028
			 		FinishFiles()									// ..the job is done : the whole stimulus has been output and the Adc data have all been sampled..
				endif
				StopADDA( "\tFINISHED  ACQUISITION.." , FALSE )		// ..then we stop the IGOR-timed periodical background task..  FALSE: do NOT ApplyScript()
			endif												// In the E3E4 trig mode StopADDA calls StartStimulus..() for which reps and chunks must already be set to their final value = StopAdda must be the last action
		endif

	endif

	if ( nDacReady  == cERROR )									// Currently never executed as currently the acquisition continues even in worst case of corrupted data 
	 	FinishFiles()											// ...'CheckReadyDacPosition()'  must be changed if this code is to be executed
		StopADDA(  "\tABORTED  ACQUISITION.." , FALSE )			//  FALSE: do NOT ApplyScript() 
	endif														// returning   nDacReady = cERROR  will kill the background task

	return nDacReady
End


Static Function  CheckReadyDacPosition( command, nRep, nChunk )
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
	variable	nRep, nChunk
	string		command 
	nvar		gBkPeriodTimer		= root:cont:gBkPeriodTimer
	nvar		gnSmpInt			= root:cont:gnSmpInt
	nvar		gnProts			= root:cont:gnProts
	nvar		gnReps			= root:cont:gnReps
	nvar		gChnkPerRep		= root:cont:gChnkPerRep 
	nvar		gPntPerChnk		= root:cont:gPntPerChnk
	nvar		gnCntDA			= root:cont:gnCntDA
	nvar		gnCntAD			= root:cont:gnCntAD
	nvar		gnCntTG			= root:cont:gnCntTG
	nvar		gnAddIdx			= root:cont:gnAddIdx
	nvar		gnLastDacPos		= root:cont:gnLastDacPos
	nvar		gReserve			= root:cont:gReserve
	nvar		gMinReserve		= root:cont:gMinReserve
	nvar		gPrediction		= root:cont:gPrediction
	nvar		gMaxSmpPtspChan	= root:cont:gMaxSmpPtspChan
	nvar		gErrCnt			= root:cont:gErrCnt
	nvar		gRadDebgSel		= root:dlg:gRadDebgSel
	nvar		pnDebgAcqDA 		= root:dlg:pnDebgAcqDA
	nvar		pnDebgAcqAD 		= root:dlg:pnDebgAcqAD
	nvar		gbAcquiring		= root:cont:gbAcquiring	// 031024 
	variable	nPnts 			=  2 * gPntPerChnk * gnCntDA 
	variable	nResult
	string		sResult, ErrBuf

	// measure elapsed time between background task calls
	variable	BkPeriod	=  stopMSTimer( gBkPeriodTimer ) / 1000
	gBkPeriodTimer 	=  startMSTimer									// timer to check time elapsed between Bkg task calls
	if ( gBkPeriodTimer 	== -1 )
		printf "*****************All timers are in use 5 ...\r" 
	endif
	
	// check buffer rollover so that 'IsIdx' is increased monotonically even if 'nDacPos' resets itself periodically
	variable	nDacPos	=  xCEDGetResponse( command, command, 0 )			// last param is 'ErrMode' : display messages or errors
//	variable	nDacPos	=  xCEDGetResponse( command )			// last param is 'ErrMode' : display messages or errors

	// 03 August the following calls requesting the CED AD-pointer and AD-status are not mandatory. They have been introduced only for information..
	// ...in an attempt to avoid the erroneous CED error  'Clock input overrun'  which unfortunately occurs already when the sampling is near (but still below) the limit.
	// When removing these calls make sure that the remaining mandatory CED DA-pointer requests still work correctly. 
	// It seemed (once) that DA- and AD-requests are not under all circumstances completely  as independent as they should be.
	variable	nDAStat	= xCEDGetResponse( "MEMDAC,?;" , "MEMDACstatus",  0 )	// last param is 'ErrMode' : display messages or errors
	variable	nADStat	= xCEDGetResponse( "ADCBST,?;", "ADCBSTstatus  ",  0 )	// last param is 'ErrMode' : display messages or errors
	variable	nADPtr	= xCEDGetResponse( "ADCBST,P;", "ADCBSTpointer ",  0 )	// last param is 'ErrMode' : display messages or errors
//	variable	nDAStat	= xCEDGetResponse( "MEMDAC,?;" )//, "MEMDACstatus",  0 )	// last param is 'ErrMode' : display messages or errors
//	variable	nADStat	= xCEDGetResponse( "ADCBST,?;" )//, "ADCBSTstatus  ",  0 )	// last param is 'ErrMode' : display messages or errors
//	variable	nADPtr	= xCEDGetResponse( "ADCBST,P;" )//, "ADCBSTpointer ",  0 )	// last param is 'ErrMode' : display messages or errors
	nADPtr /=  ( gnCntAD + gnCntTG ) 

	// We want the time during which the stimulus is output, not the pre-time possibly waiting for the E3E4 trigger and not the post-time when the stimulus is possibly reloaded (when nReps>1)  
	// PnTest() -> Print options (Debug)  -> Everything ->  Acquisition reveals that  'nDacPos' , 'nADPtr'  and possibly 'nADStat' and 'nDAStat' can be used for that purpose 
	// 'gbRunning' is here not valid indicator as it not yet set to 0 here after a user abort
	// 'nDacPos'    is here not always a valid indicator as it is not set to 0 after a user  abort
	gbAcquiring	=   nAdPtr == 0   ||  nDacPos == 0   ?   0  :  1				// 031030
	StartStopFinishButtonTitles()										// 031030 reflect change of 'gbAcquiring' in buttons : enable or disable (=grey) them 

	// 031210  The  standard 1401   and the  1401plus / power1401 behave differently so that the code recognizing the normal FINISH  of a script fails :
	// For the 1401plus and power1401 the  'nPredDacPos' -> 'gnAddIdx' -> 'IsIdx'  computation is effective in 2 cases:
	//	1. during all but the last chunks ( Dacpos resets but AddIndex incrementing compensates for that )
	//	2. after the last chunk: DacPos goes to  0   but AddIndex incrementing compensates for that  -> IsIndex increments a last time -> = SollIndex -> XFER is returned -> StopADDA() is called at the end of AddaSwing() 
	// For the standard 1401  the  'nPredDacPos' -> 'gnAddIdx' -> 'IsIdx'  computation is effective in only in case 1. :  during acquisition but not after the last chunk 
	//	It fails in case 2.  after the last as DacPos  does NOT go to 0  but instead stay fixed at the index of the last point MINUS 2 !  -> IsIndex would  NOT be incremented -> WAIT would be returned -> StopADDA() is never called
	//	Solution : Check and use the Dac status ( which goes to 0 after finishing ) instead . The Adc status also goes to 0 after finishing but a script does not necessarily contain ADC channels so we do not use it.
	// In principle this patch for the standard 1401 could also be used for the 1401plus and power1401, as their status flags go to 0 in the same manner after finishing...............

	// 'nSkippedChnks' can be fairly good estimated (error < 0.1) .  
	// 031126 We must not count skipped chunks when waiting for a  HW E3E4 trigger, as in this case short scripts (shorter than Background time ~100ms)  would...
	// ...erroneously increment  'nPredDacPos' -> 'gnAddIdx' -> 'IsIdx'  and then trigger the error case below. We avoid this error by setting  'nSkippedChnks=0' when not acquiring  
	variable	nSkippedChnks	= ( BkPeriod / ( gPntPerChnk * gnSmpInt * .001 ) ) * gbAcquiring	// 031126
	//variable	nSkippedChnks	= ( BkPeriod / ( gPntPerChnk * gnSmpInt * .001 ) ) 
	variable	nPredDacPos	= gnLastDacPos + nSkippedChnks * nPnts			// Predicted Dac position can be greater than buffer!

	
	gnLastDacPos		=  nDacPos									// save value for next call
	gnAddIdx		       += gChnkPerRep * trunc( ( nPredDacPos - nDacPos ) / ( nPnts  * gChnkPerRep ) + .5 ) 
	variable	IsIdx		=  trunc( nDacPos / nPnts ) +  gnAddIdx
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
		gPrediction	= PredictedAcqSuccess( gnProts, gnReps, gChnkPerRep, gReserve, IsIdx , rNeeded, rCurrent )

	else 				// if ( IsIdx > SollIdx + ChkpRep - 1 )		// cERROR: more than one lap behind, data will be lost  ( gReserve = 0 )  if  at the same time nReps>1  
		nResult	= cADDATRANSFER						// on error : continue
		sResult	= "  ??? "								// more than one lap behind, but no data will be lost as nReps==1   031119

	// the following 2 lines are to be ACTIVATED ONLY  FOR TEST  to break out of the inifinite  Background task loop.....  031111
	//nResult	= cERROR								// on error : stop acquisition
	//printf "\t++++cERROR in Test mode: abort prematurely in StopAdda() because of 'Loosing data error' , will also  stop  Background task. \r" 

		if ( gnReps > 1  )	// scripts with only 1 repetition will never fail no matter how many protocols are output but the  'IsIdx - TooHighIdx' will erroneously indicate data loss if 'gnProts>>1' 
			sResult	= "LOOS'N"
			if ( gErrCnt == 0 )								// issue this error only once
				variable	TAused	= TAUse( gPntPerChnk, gnCntDA, gnCntAD, cMAX_TAREA_PTS )
				variable	MemUsed	= MemUse( gChnkPerRep, gPntPerChnk, gMaxSmpPtspChan )
				sprintf ErrBuf, "Data  in Chunk: %d / %d will probably be corrupted. Acquisition too fast, too many channels, too many or unfavorable number of data points.\r \t\t\tTA usage:%3d%%  Memory usage:%3d%%  Reps:%d  ChkPerRep:%d  PtsPerChunk:%d ", IsIdx, gnReps * gChnkPerRep, TAused, MemUsed, gnReps, gChnkPerRep, gPntPerChnk
				Alert( cSEVERE, ErrBuf )						// 030716
				gErrCnt	+= 1
			endif
		endif
	endif

	if ( gRadDebgSel == 4  &&  ( pnDebgAcqDA  ||   pnDebgAcqAD ) )
		printf "\t\t\ta:%d\tR:%2d/%2d\tChk:%3d/%3d\tAp:%8d\tDp:%8d\tPD:%8d\tTb:%4d", gbAcquiring, nRep, gnReps, (nRep-1) * gChnkPerRep + nChunk, gnReps * gChnkPerRep, nADPtr , nDacPos, nPredDacPos, BkPeriod
		printf "\tsC:%4.1lf  AI:%4d\tIsI:%4.1lf\t[%3d\t|%3d.%3d\t|%3d\t] Rs\t:%3d\t/%3d\t/%3d\t%s\tStt:%4d\t|%5d", nSkippedChnks, gnAddIdx, IsIdx, SollIdx-1, SollIdx, TooHighIdx-1, TooHighIdx, gMinReserve, gReserve, gChnkPerRep, sResult, nDAStat, nADStat
		//printf "\tPr:%5.2lf\t=sc:%5.1lf \t/sn:%5.1lf \r", gPrediction, rCurrent, rNeeded   	// display speeds (not good : range -1000...+1000)
		printf "\tPr:%5.2lf\t= n %.2lf \t/  c %.2lf \r", gPrediction, rNeeded, rCurrent		// display inverse speeds ( good: range  -1...+1)
	endif
	return	nResult
End

Static Function		PredictedAcqSuccess( nProts, nReps, nChnkPerRep, nReserve, IsIdx, Needed, Current )
// Returns (already during acquisition) a guess whether the acq will succeed ( > 1 ) or fail  ( < 1 ) .
// This information is useful when the scripts takes very long and when the system is perhaps too slow for the  ambitious sampling rate and number of channels 
	variable	nProts, nReps, nChnkPerRep, nReserve, IsIdx
	variable	&Needed, &Current
	variable	PredCurr
	variable	PosReserveDifference			// if (in rare cases) the reserve increases during the acq  a neg. reserve diff is computed which gives a false 'Loosing data' indication 
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


//Static Function		PredictedAcqSuccess( nProts, nProt, nRep, nReps, nChunk, nChnkPerRep, nReserve, IsIdx )
//// Returns (already during acquisition) a guess whether the acq will succeed ( > 1 ) or fail  ( < 1 ) .
//// This information is useful when the scripts takes very long and when the system is perhaps too slow for the  ambitious sampling rate and number of channels 
//	variable	nProts, nProt, nRep, nReps, nChunk, nChnkPerRep, nReserve, IsIdx
//	nvar		/Z 	gStaticPrevReserve			// used like static, should be hidden but must keep it's value between calls
//	nvar		/Z 	gStaticPrediction			// used like static, ...
//	if ( ! nvar_Exists( gStaticPrevReserve	) )
//		variable   /G	gStaticPrevReserve	= 0	// used like static, should be hidden but must keep it's value between calls
//		variable   /G	gStaticPrediction	= 1	// used like static, ...
//	endif
//	if ( nReserve != gStaticPrevReserve   ||   nReserve ==  nChnkPerRep - 2 )	// update the value when 1.)  the reserve chunks change (storing the MIN value) 2.) when reserve is at maximum (easy scripts...)
//		gStaticPrediction =  nReserve * nReps / max( 1, ( nReps  -  nRep  ) * nChnkPerRep - nChunk ) 
//	endif
//variable nChnksLeft = ( nProt - 1 )  * nReps *  nChnkPerRep + ( nReps  -  nRep  ) * nChnkPerRep - nChunk
////variable pred	= nReserve / nChnksLeft   *   ( nChnkPerRep / nProts / nReps )
//variable pred	= nReserve *  nReps / max( 1, nChnksLeft )
////printf "CL:%3d\txx:%3d\t: %4.2lf \t", nChnksLeft, ( nReps  -  nRep  ) * nChnkPerRep - nChunk, pred
//// for short easy scripts...
//	if ( nReps == 1 )
//		gStaticPrediction =  2
//	endif
//	gStaticPrevReserve	 = nReserve
//	return	gStaticPrediction
//End

//Static Function		PredictedAcqSuccess( nProts, nReps, nChnkPerRep, nReserve, IsIdx )
//// Returns (already during acquisition) a guess whether the acq will succeed ( > 1 ) or fail  ( < 1 ) .
//// This information is useful when the scripts takes very long and when the system is perhaps too slow for the  ambitious sampling rate and number of channels 
//	variable	nProts, nReps, nChnkPerRep, nReserve, IsIdx
//	nvar		/Z 	gStaticPrevReserve			// used like static, should be hidden but must keep it's value between calls
//	nvar		/Z 	gStaticPrediction			// used like static, ...
//	nvar		/Z 	gStaticIsIdx				// used like static, ...
//	if ( ! nvar_Exists( gStaticPrevReserve	) )
//		variable   /G	gStaticPrevReserve	= 0	// used like static, should be hidden but must keep it's value between calls
//		variable   /G	gStaticPrediction	= 1	// used like static, ...
//		variable   /G	gStaticIsIdx		= 0	// used like static, ...
//	endif
////	if ( nReserve != gStaticPrevReserve )			// update the value when 1.)  the reserve chunks change (then store the MINIMUM value) 2.) when reserve is at maximum (easy scripts...)
//		variable	RestSl	= nReserve / ( 		 nProts * nReps * nChnkPerRep - IsIdx )	// 1 / speed needed for the rest
//		variable	CurrSl	= 1 / 	(	IsIdx - gStaticIsIdx ) 						// 1 / current speed		= current slow
////		variable	RestSl	= nReserve / ( max( 1, nProts * nReps * nChnkPerRep - IsIdx ) )	// 1 / speed needed for the rest
////		variable	CurrSl	= 1 / max( 1, ( IsIdx - gStaticIsIdx ) ) 						// 1 / current speed		= current slow
//		variable	PredCurr	= RestSl / CurrSl   
//		gStaticPrediction =  PredCurr
//		gStaticIsIdx	 = IsIdx
//		printf "r:%.2lf\tc:%.2lf\t", RestSl, CurrSl
////	else
////		printf "\t\t\t\t"
////	endif
//	gStaticPrevReserve	= nReserve
//	if ( nReps == 1 )
//		gStaticPrediction = 2			// 2 or any other value indicating success. In this special case the 'gReserve' value is meaningless.
//	endif
//	return	gStaticPrediction
//End
//



Function		FinishFiles()
	FinishCFSFile()
	FinishAnalysisFile()
End


Function		StopADDA( strExplain , bDoApplyScript )
	string		strExplain
	variable	bDoApplyScript 
	nvar		gbRunning		= root:cont:gbRunning
	nvar		gBkPeriodTimer		= root:cont:gBkPeriodTimer
	nvar		gnStopTicks		= root:cont:gnStopTicks
	nvar		gRadTrigMode		= root:cont:gRadTrigMode
	nvar		gbQuickAcqCheck	= root:dlg:gbQuickAcqCheck	
	nvar		gRadDebgGen		= root:dlg:gRadDebgGen
	nvar		gRadDebgSel		= root:dlg:gRadDebgSel
	nvar		pnDebgAcqDA		= root:dlg:pnDebgAcqDA
	nvar		pnDebgAcqAD		= root:dlg:pnDebgAcqAD
	string		bf
	variable	dummy			= stopMSTimer( gBkPeriodTimer )

	//PrintBackGroundInfo( "StopADDA(1)" , "before Stop" )

	if ( ! cBKG_RUN_ALWAYS )
		if ( gRadTrigMode == 0  ) 	// 031113
			BackGroundInfo	
			if ( v_Flag == cBKG_RUNNING )			// Only if the bkg task is running we can stop it.  We must rule out the case when it is not yet running for example when switching the trigger mode initially at program start .
				// printf "\t\t\tStopADDA(2) \t\t\tstopping BackGround task \r "
				CtrlBackGround stop				// end of data acquisition
			endif
		endif
	endif
	// PrintBackGroundInfo( "StopADDA(2)" , "after  Stop" )
	
	if (  CEDHandleIsOpen() )
		variable	ShowMode = ( gRadDebgGen == 2 ||  ( gRadDebgSel > 0 &&  ( pnDebgAcqDA || pnDebgAcqAD ) ) ) ? MSGLINE : ERRLINE	

		// Although it would seem safe we do NOT reset the CED1401 (nor use KillIO) because	1. the Power1401 would not start next acquisition.
		//																2. there would be an undesired  1ms glitch on all digouts appr.500ms after end of stimulus (only on 1401plus) 
		CEDSendStringCheckErrors( "ADCBST,K;" , 0 ) 						// 031111 kill the sampling process
		CEDSendStringCheckErrors( "MEMDAC,K;" , 0 ) 						// 031111 kill the stimulation process
		CEDSendStringCheckErrors( "DAC,0 1 2 3,0 0 0 0;" , 0 ) 				// 031111 set all DACs to 0 when aborting 
		CEDSendStringCheckErrors( "DIGTIM,K;" , 0 ) 						// 031111 kill the digital output process
		CEDSetAllDigOuts( 0 )										// 031111 Initialize the digital output ports with 0 : set to LOW

		nvar	gnReps	= root:cont:gnReps
		// printf "\t\t\tStopADDA(3) \t\t\tgnReps: %2d   \r ", gnReps
		if ( gnReps > 1 )		
			// 031030 Unfortunately we cannot use 'gAcqStatus'  to reflect the time spent in the following function  'CEDInitializeDacBuffers()'  in a PN_DICOLTXT color text field display,  neither  by setting the controlling..
			// ..global 'gAcqStatus' directly  nor  indirectly by a dependency relation 'gbAcqStatus :=  f( gbReloading )  as we are right now still in the background task, and controls are only updated when Igor is idling. 
			// Workaround : It is possible  (even when in the middle of a background function)  to change directly  the title of a button, but this is not really what we want.
			// Code (NOT working)  :		nvar gAcqStatus=root:cont:gAcqStatus; gAcqStatus=2   
			// Code (NOT working either) :  	nvar gbReloading=root:cont:gbReloading; gbReloading=TRUE ; do something; gbReloading=FALSE;    and coded elsewhere	SetFormula root:cont:gAcqStatus, "root:cont:gbReloading * 2"
			// printf "\t\t\tStopADDA(4) \t\t\tgnReps: %2d \t-> CEDInitializeDacBuffers() \r ", gnReps
			CEDInitializeDacBuffers()			// Ignore (by NOT measuring)  'Transfer' and 'Convolve' times here after finishing as they have no effect on acquisition (only on load time)
		endif
		
	endif
	sprintf bf, "%s  \r", strExplain; Out( bf )
//	sprintf bf, "%s (hnd=%d) \r", strExplain,  xCEDGetHandle() ; Out( bf )

	if ( gbQuickAcqCheck )						// 030804  for quick testing the integrity of acquired data including telegraph channels
		QuickAcqCheck()
	endif

	gbRunning	= FALSE 		// 031030
	StartStopFinishButtonTitles()	// 031030 reflect change of 'gbRunning' 

	gnStopTicks	= ticks 						// save current  tick count  (in 1/60s since computer was started) 
	EnableButton( "PnPuls", "buApplyScript",	ENABLE )
	EnableSetVariable( "PnPuls", "gnProts",	TRUE )	// ..allow also changing the number of protocols ( which triggers 'ApplyScript()'  )
	EnableButton( "PnPuls", "buLoadScript",	ENABLE )
// 031030 obsolete,,,,??????
//StartStopFinishButtonTitles()	// ugly here...button text should change automatically
	ShowTimingStatistics()

	if ( bDoApplyScript )
		ApplyScript()
	endif

	if ( gRadTrigMode == 1 ) 	//  031025 continuous hardware trig'd mode: (re)arm the trigger detection after a stimulus is finished so that each new trigger on E3E4 triggers the next acquisition run
		//printf "\t\t\tStopADDA(6) \t\t\t-> StartStimulusAndAcquisition() \r "					// 031119
		StartStimulusAndAcquisition() 	//  this will call  'CedStartAcq'  which will  set  'gbRunning'  TRUE
	endif
End


Function		QuickAcqCheck()
	// Extra window for detection of acquisition errors including telegraph channels.  'Display raw data after acq' also works but does not display the telegraph channels. 
	// You must kill the window before each acquisition because to avoid graph updating which slows down the acquisition process appreciably.  
	wave	wRawADDA		= root:cont:wRawADDA
	nvar		gnCntAD			= root:cont:gnCntAD	
	nvar		gnCntTG			= root:cont:gnCntTG	
	nvar		gnCompress		= root:cont:gnCompressTG	
	nvar		gnSmpInt			= root:cont:gnSmpInt
	variable	c, red, green, blue
	string		sWaveNm
	string		sQuickAcqCheckNm	= "QuickCheck"		// cannot name it 'QuickAcqCheck' as this is the function name 

	DoWindow	$sQuickAcqCheckNm				// check if the 'QuickAcqCheck' window exists
	if ( V_Flag == 1 )									// ..if it exists then V_Flag will be true
		DoWindow  /K	$sQuickAcqCheckNm			// ..kill it
	endif 
	display /K=1 									// allow killing by pressing the window close button
	DoWindow  /C $sQuickAcqCheckNm					// rename window to  'QuickAcqCheck'

	// this display order may not be optimal  in test mode without CED.  Adc2 is filled with much noise, Adc0 with little noise and nay be obscured by Adc2
	for ( c = 0; c < gnCntAD; c += 1)	
		sWaveNm	= ADTGNm( c )
		red		= 64000 * ( c== 0 ) + 64000  * ( c== 3 ) + 64000  * ( c== 4 )
		green	= 64000 * ( c== 1 ) + 64000  * ( c== 4 ) + 64000  * ( c== 5 )
		blue		= 64000 * ( c== 2 ) + 64000  * ( c== 5 ) + 64000  * ( c== 3 ) 
		AppendToGraph $sWaveNm
		ModifyGraph rgb( $sWaveNm )	= ( red, green, blue )
		SetScale /I x , 0, numPnts( $sWaveNm ) * gnSmpInt / 1e6 , "s", $sWaveNm
	endfor
	for ( c = gnCntAD; c < gnCntAD + gnCntTG; c += 1)	
		sWaveNm	= ADTGNm( c )
		red		= 64000 * ( c== 0 ) + 64000  * ( c== 3 ) + 64000  * ( c== 4 )
		green	= 64000 * ( c== 1 ) + 64000  * ( c== 4 ) + 64000  * ( c== 5 )
		blue		= 64000 * ( c== 2 ) + 64000  * ( c== 5 ) + 64000  * ( c== 3 ) 
		AppendToGraph $sWaveNm
		ModifyGraph rgb( $sWaveNm )	= ( red, green, blue )
		SetScale /I x , 0, numPnts( $sWaveNm ) * gnCompress * gnSmpInt / 1e6 , "s" , $sWaveNm
	endfor
	//printf "\t\tQuickAcqCheck(): displays window for acq error detection including telegraph channels. Kill this window before every acq for maximum speed.\r" 
End


Function		ShowTimingStatistics()
	nvar		gnProts			= root:cont:gnProts
	nvar		gnReps			= root:cont:gnReps
	nvar	 	gChnkPerRep		= root:cont:gChnkPerRep
	nvar		gPntPerChnk	 	= root:cont:gPntPerChnk
	nvar		gnCntAD			= root:cont:gnCntAD
	nvar	 	gnCntDA			= root:cont:gnCntDA
	nvar		gnCntTG			= root:cont:gnCntTG 		
	nvar		gnSmpInt			= root:cont:gnSmpInt
	nvar		gnCompress		= root:cont:gnCompressTG
	nvar		gReserve			= root:cont:gReserve
	nvar		gMinReserve		= root:cont:gMinReserve
	nvar		gMaxSmpPtspChan	= root:cont:gMaxSmpPtspChan
	nvar		gbShowTimingStats	= root:dlg:gbShowTimingStats
//	variable	nTransConvPtsPerCh	= gChnkPerRep * gPntPerChnk * gnReps * gnProts	// 031015
	variable	nTransConvPtsPerCh	= gChnkPerRep * gPntPerChnk * gnReps
	variable	nTransConvChs		= gnCntAD+ gnCntDA + gnCntTG / gnCompress
	variable	nTransferPts		= nTransConvPtsPerCh * nTransConvChs
	variable	nConvolvePts		= nTransConvPtsPerCh * nTransConvChs
	variable	nCFSWritePtsPerCh 	= TotalStorePoints() * gnProts	// this number of points is valid for Writing AND Processing
	variable	nGraphicsPtsPerCh 	= TotalStorePoints() * gnProts	// todo not correct: superimposed sweeps not included
	variable	nCFSWritePts		= nCFSWritePtsPerCh *  gnCntAD 
	variable	nGraphicsPts		= nGraphicsPtsPerCh *  gnCntAD // todo not correct: DAC may also be displayed, superimposed sweeps not included 
	variable	TransferTime		= ReadTimer( "Transfer" )
	variable	ConvolveTime		= ReadTimer( "Convolve" )
	variable	GraphicsTime		= ReadTimer( "Graphics" )
	variable	CFSWriteTime		= ReadTimer( "CFSWrite" )
	variable	OnlineAnTime		= ReadTimer( "OnlineAn" )
	//variable	FreeUseTime		= ReadTimer( "FreeUse" )
	variable	ProcessTime		= ReadTimer( "Process" )
	variable	InRoutinesTime		= TransferTime + ConvolveTime + CFSWriteTime + GraphicsTime + ProcessTime 	
	variable	ProtocolTotalTime	= nTransConvPtsPerCh * gnSmpInt / 1000
	variable	ProtocolStoredTime	= nCFSWritePtsPerCh * gnSmpInt / 1000
	variable	AttemptedADRate	= 1000 * gnCntAD / gnSmpInt
	variable	AttemptedFileSize	= AttemptedADRate * ProtocolStoredTime * 2 / 1024 / 1024
	variable	TAused			= TAUse( gPntPerChnk, gnCntDA, gnCntAD, cMAX_TAREA_PTS )
	variable	MemUsed			= MemUse( gChnkPerRep, gPntPerChnk, gMaxSmpPtspChan )

	StopTimer( "TotalADDA" )		
	PrintAllTimers()
	if ( gbShowTimingStats )
		printf "\t\tTIMING STATISTICS ( Prots:%2d , Rep:%2d ,  CpR:%2d , PtpChk:%6d / %d ,  %d us,  %.1lf MB,  Reserve:%d / %d / %d, TA:%d%%, Mem:%d%% ) \r", gnProts, gnReps, gChnkPerRep, gPntPerChnk, gPntPerChnk * ( gnCntAD + gnCntTG ), gnSmpInt, AttemptedFileSize, gMinReserve, gReserve, gChnkPerRep, TAUsed, MemUsed
		printf  "\t\tTransfer:  \t%3.2lf\tch *\t %11d \t=%11d\tpts\t %11d \tms  -> %5.2lf\t/ %5.2lf\tus / pt \t= %5.1lf\t%% of SI \r", nTransConvChs,   nTransConvPtsPerCh,   nTransferPts,   TransferTime,  TransferTime / nTransferPts * 1000,   TransferTime / nTransConvPtsPerCh * 1000 ,   TransferTime / nTransConvPtsPerCh / gnSmpInt * 100000
		printf  "\t\tConvolve:\t%3.2lf\tch *\t %11d \t=%11d\tpts \t %11d \tms  -> %5.2lf\t/ %5.2lf\tus / pt \t= %5.1lf\t%% of SI  \r",  nTransConvChs, nTransConvPtsPerCh, nConvolvePts, ConvolveTime, ConvolveTime / nConvolvePts * 1000, ConvolveTime / nTransConvPtsPerCh * 1000, ConvolveTime / nTransConvPtsPerCh / gnSmpInt * 100000
		printf  "\t\tGraphics: \t%3d \tch *\t %11d \t=%11d\tpts \t %11d \tms  -> %5.2lf\t/ %5.2lf\tus / pt \t= %5.1lf\t%% of SI  \r", gnCntAD, nGraphicsPtsPerCh, nGraphicsPts, GraphicsTime, GraphicsTime / nGraphicsPts * 1000, GraphicsTime / nGraphicsPtsPerCh * 1000, GraphicsTime / nGraphicsPtsPerCh /gnSmpInt * 100000
		printf  "\t\tOnlineAnal:\t%3d \tch *\t %11d \t=%11d\tpts \t %11d \tms  -> %5.2lf\t/ %5.2lf\tus / pt \t= %5.1lf\t%% of SI  \r", gnCntAD, nCFSWritePtsPerCh, nCFSWritePts, OnlineAnTime, OnlineAnTime / nCFSWritePts * 1000, OnlineAnTime / nCFSWritePtsPerCh * 1000, OnlineAnTime / nCFSWritePtsPerCh / gnSmpInt * 100000 
		printf  "\t\tCfsWrite:  \t%3d \tch *\t %11d \t=%11d\tpts \t %11d \tms  -> %5.2lf\t/ %5.2lf\tus / pt \t= %5.1lf\t%% of SI  \r", gnCntAD, nCFSWritePtsPerCh, nCFSWritePts, CFSWriteTime, CFSWriteTime / nCFSWritePts * 1000, CFSWriteTime / nCFSWritePtsPerCh * 1000, CFSWriteTime / nCFSWritePtsPerCh / gnSmpInt * 100000 
		//printf"\t\tFreeUse:  \t%3d \tch *\t %11d \t=%11d\tpts \t %11d \tms  -> %5.2lf\t/ %5.2lf\tus / pt \t= %5.1lf\t%% of SI  \r", gnCntAD, nCFSWritePtsPerCh, nCFSWritePts, FreeUseTime, FreeUseTime / nCFSWritePts * 1000, FreeUseTime / nCFSWritePtsPerCh * 1000, FreeUseTime / nCFSWritePtsPerCh / gnSmpInt * 100000 
		printf  "\t\tProcessing:\t%3d \tch *\t %11d \t=%11d\tpts \t %11d \tms  -> %5.2lf\t/ %5.2lf\tus / pt \t= %5.1lf\t%% of SI  \r", gnCntAD, nCFSWritePtsPerCh, nGraphicsPts, ProcessTime, ProcessTime / nCFSWritePts * 1000, ProcessTime / nCFSWritePtsPerCh * 1000, ProcessTime / nCFSWritePtsPerCh / gnSmpInt * 100000 
		printf  "\t\tProtocol(total/stored):\t%d / %d ms  \tMeasured(routines): %d = %.1lf%% \t\tMeasured(overall): %d = %.1lf%% \r", ProtocolTotalTime,  ProtocolStoredTime, InRoutinesTime,  InRoutinesTime / ProtocolTotalTime * 100, ReadTimer( "TotalADDA" ), ReadTimer( "TotalADDA" )/ ProtocolTotalTime * 100
	endif
End

constant		DADIREC = 0, ADDIREC = 1		// same as in XOP MWave.C

Static Function ConvolveBuffersDA( nChunk, nRep, nChunksPerRep, nChs, PtpChk, wRaw, nHostOfs, nPnts )
// mixes points of all  separate DAC-channel stimulus waves  together in small wave ' wRaw'  in transfer area 
	variable	nChunk, nRep, nChunksPerRep, nChs, PtpChk, nHostOfs, nPnts
	wave	wRaw
	nvar		gRadDebgSel		= root:dlg:gRadDebgSel
	nvar		pnDebgAcqDA		= root:dlg:pnDebgAcqDA
	variable	pt, begPt	  = PtpChk  * nChunk					// BegPt and EndPt are points in the CED sampling area (typ. 16MB) ....
	variable	endPt	  = PtpChk * ( nChunk + 1 )				// The same BegPt and EndPt are passed multiple times if nReps is >1 (=long scripts and/or many protocols)
	variable	repOs	  = nRep * PtpChk * nChunksPerRep		// BegPt and EndPt  PLUS the repetition offset 'repOs' gives the true point number in the DAC wave independently from the CED sampling area size
	variable	DACRange = 10								// Volt
	variable	c,	nIO	  = ioT( "Dac")
	//nvar gnPnts= root:cont:gnPnts; nPnts = gnPnts
	if ( ( gRadDebgSel == 2  ||  gRadDebgSel == 3 )  &&  pnDebgAcqDA )
		printf "\t\tConvDA( \tc:%d\t\t\tnChunk:%2d\tnRep:%2d\tCPRep:%2d\tnChs:%d\tPtpChk:%5d\tnHostOfs:%5d\tbeg:%6d\tend:%6d\trOs: %10d  \twRaw:%5dpts\tnPnts:\t%8d \r", c, nChunk, nRep, nChunksPerRep, nChs, PtpChk, nHostOfs, begpt, endpt, repOs, numPnts( wRaw ), nPnts
	endif
	for ( c = 0; c < nChs; c += 1 )
		variable	ofs		= c + nHostOfs 
		variable	yscl		=  iov1( nIO, c, cIOGAIN ) * MAXAMPL / 1000 / DACRange					// scale  in mV
		wave	wDacReal	= $ios1( nIO, c, cIONM ) 								
		//printf "\t\t\t\tAcqDA Cnv>DA14>Cpy\t %10d  \t%8d",  2*begPt, 2*(mod(begPt,(2*PtpChk))+ofs)	

		xUtilConvolve( wDacReal, wRaw, DADIREC, nChs, 0, begPt, endPt, RepOs, PtpChk, ofs, yscl, 0, 0, 0, nPnts, 0 )	// ~ 40ns / data point

//		 for ( pt =   begPt;  pt < endPt;   pt += 1 )
//			variable	pt1	= mod( pt + repOs, gnPnts )									// Simple code without compression
//			wRaw[ mod( pt, (2*PtpChk)) * nChs + ofs ]  = wDacReal[ trunc( pt1 / SmpF ) ] * yscl	// ~ 4 us  / data point  (KEEP: including SmpF)
//		 endfor
	endfor
	return	endPt  + repOs
End



Static Function	DeconvolveBuffsAD( nChunk, nRep, nChunksPerRep, PtpChk, wRaw, nHostOfs, nCntAD, nCntTG, nCompress, nPnts )
// extracts mixed points of all ADC -  and  TG - channels from ' wRaw' transfer area into separate IGOR AD waves
	variable	nChunk, nRep, nChunksPerRep, PtpChk, nHostOfs, nCntAD, nCntTG, nCompress, nPnts
	wave	wRaw
	nvar		gRadDebgSel		= root:dlg:gRadDebgSel
	nvar		pnDebgAcqAD		= root:dlg:pnDebgAcqAD
	variable	nChs		= nCntAD + nCntTG
	variable	pt, BegPt	= PtpChk  * nChunk
	variable	EndPt	= PtpChk * ( nChunk + 1 )
	variable	RepOs	= ( nRep - 1 ) * PtpChk * nChunksPerRep

// 031120
variable	bStoreIt, nBigChunk= ( BegPt + RepOs ) / PtpChk 
if ( cELIMINATE_BLANK )	// 031120
	bStoreIt	= StoreChunkOrNotOrNot( nBigChunk )				
else
	bStoreIt	= 1
endif

	variable	ADCRange= 10								// Volt
	variable	c = 0, yscl	=  MAXAMPL / 1000 / ADCRange		// scale in mV
	variable	ofs, nSrcStartOfChan, nSrcIndexOfChan
	string		sRealWvNm	= ADTGNm( c )

	if ( ( gRadDebgSel == 2  ||  gRadDebgSel == 3 )  &&  pnDebgAcqAD )
		printf "\t\tDeConvAD( \tc:%d\t'%s'\tnChunk:%2d\tnRep:%2d\tCPRep:%2d\tnChs:%d\tPtpChk:%5d\tnHostOfs:%5d\tbpt:\t%7d\tept:\t%7d\tBigChk:\t%7d\tStore: %d\t \r", c, sRealWvNm, nChunk, nRep, nChunksPerRep, nChs, PtpChk, nHostOfs, begpt, endpt, nBigChunk, bStoreIt
	endif
	for ( c = 0; c < nCntAD + nCntTG; c += 1 )				// ASSUMPTION: order of channels is first ALL AD, afterwards ALL TG
		//printf "\t\tDeConvAD( \tc:%d\t'%s'\tnChunk:%2d\tnRep:%2d\tCPRep:%2d\tnChs:%d\tPtpChk:%5d\tnHostOfs:%5d\tbpt:\t%7d\tept:\t%7d \r", c, sRealWvNm, nChunk, nRep, nChunksPerRep, nChs, PtpChk, nHostOfs, begpt, endpt
		sRealWvNm	= ADTGNm( c )
		wave   wReal 	=  $sRealWvNm		

		// bStoreIt : Set  'Blank'  periods (=periods during which data were sampled but not transfered to host leading to erroneous data in the host area)  to  0  so that the displayed traces  look nice.  // 031120
		xUtilConvolve( wReal, wRaw, ADDIREC, nCntAD, nCntTG, BegPt, EndPt, RepOs, PtpChk, nHostOfs, yscl, nCompress, nChunk, c, nPnts, bStoreIt )	// ~ 40ns / data point

	endfor
	return 	endPt  + repOs 
End


constant		FILTERING			= 10000	// 1 means ADC=DAC=no filtering,    200 means heavy filtering
constant		NOISEAMOUNT		= 0.002	// 0 means no noise,   1 means noise is appr. as large as signal   (for channel 0 )
constant		CHANGE_TG_SECS 	= 2			// gain switching by simulated telegraph channels will ocur with roughly this period


Static Function TestCopyRawDAC_ADC( nChunk, PtpChk, wRaw, nDACHostOfs, nADCHostOfs )
// helper for test mode without CED: copies dac waves into adc waves
// Multiple Dac channels are implemented but not tested...
	variable	nChunk, PtpChk, nDACHostOfs, nADCHostOfs
	wave	wRaw
	nvar		gnCntDA		= root:cont:gnCntDA
	nvar		gnCntAD		= root:cont:gnCntAD
	nvar		gnCntTG		= root:cont:gnCntTG
	nvar		gnCompress	= root:cont:gnCompressTG
	variable	pt, ch, nChs 	= max( gnCntDA, gnCntAD ), indexADC, indexDAC, indexTG
	variable	nFakeTGvalue	= 27000 + 5000 * mod( trunc( ticks / CHANGE_TG_SECS / 100), 2 ) // gain(27000):1, gain(32000):2,  gain(54000):gain50, gain(64000):200
	variable	ADCRange	= 10						// Volt
	variable	yscl	=  MAXAMPL / 1000 / ADCRange		// scale in mV

	 printf "\t\tAcqDA TestCopyRawDAC_ADC()   nChunk:%d   PtpChk:%d   Compr:%d  nDA:%d   nAD:%d   nTG:%d    max() = nChs:%d  nFakeTGvalue:%d \r", nChunk, PtpChk, gnCompress, gnCntDA, gnCntAD, gnCntTG, nChs, nFakeTGvalue
	nChunk	= mod( nChunk, 2 ) 
	// Fake the AD channels
	for ( ch = 0; ch < gnCntAD; ch += 1 )
		// get average to add some noise (proportional to signal) to fake ADC data if no CED1401 is present
		variable	nBegIndexDAC =  PtpChk * nChunk 	*	gnCntDA + min( ch, gnCntDA - 1 ) + nDACHostOfs
		variable	nEndIndexDAC =  PtpChk * (nChunk+1)  *	gnCntDA + min( ch, gnCntDA - 1 ) + nDACHostOfs
		wavestats /Q /R=(nBegIndexDAC, nEndIndexDAC) wRaw 
		variable	ChanFct	= 10^ch									// Ch0: 1 ,  Ch1: 10  , Ch2: 100
		for ( pt = PtpChk * nChunk;  pt < PtpChk * ( nChunk + 1 );   pt += 1 )		// if there are the same number of DA and AD they are mapped 1 : 1

			indexDAC =  pt + (nChunk ) * min( ch, gnCntDA - 1 ) * PtpChk +	nDACHostOfs	// it there is only 1 DA but more than 1 AD the DA is mapped to all ADs  with different amount of filtering and noise
			indexADC =  pt + ( nChunk * ( gnCntAD + gnCntTG - 1 ) +  ch ) * PtpChk + nADCHostOfs	// if there is only 1 AD it is mapped to DA0
	
			// filtering is implemented here to see a difference between DAC and ADC data
			//! integer arithmetic gives severe and very confusing rounding errors with amplitudes < 20
			// chan 0 : little noise, heavy filtering , chan 1 : medium noise, medium filtering,  chan 2 : much noise , little filtering
		 	wRaw[ indexADC ]  =  ChanFct / FILTERING * wRaw[  indexDAC ] + ( 1 - ChanFct / FILTERING ) * wRaw[ indexDAC - min( ch, gnCntDA - 1 ) ]  + ChanFct * gNoise( V_avg  * NOISEAMOUNT)  
		endfor
	endfor

	// Fake the telegraph channels
	for ( ch = 0; ch < gnCntTG; ch += 1 )
		for ( pt = PtpChk * nChunk;  pt < PtpChk * ( nChunk + 1 );   pt +=  gnCompress )		
			indexTG =  pt +  ( nChunk * ( gnCntAD + gnCntTG - 1 ) + ( ch  + gnCntAD ) ) / gnCompress * PtpChk + nADCHostOfs	
		 	wRaw[ indexTG /gnCompress ]   	=   ( ch + 1 ) * nFakeTGvalue / yscl
		endfor
	endfor
	return 0
End

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
constant			AD_NOT_USED		= -2
constant			AD_HASNO_TG_CHAN	= -1
 
Function		TelegraphConnect()
// Store the AD-Telegraph-connection information  in wave 'wAD2TG'  , in  'glstAD' , in  'glstTG' 
// Store the number od AD channels  in  'gnCntAD'  and in  'gnCntTG' 
	variable	bPrintIt		= 0	// 0 or 1 
	string		sMainKey		= "Adc"
	wave	wAD2TG		= root:cont:wAD2TG	
	nvar		gnCntAD		= root:cont:gnCntAD	
	nvar		gnCntTG		= root:cont:gnCntTG		// only telegraph channels to be sampled are counted , MultiClamp TG channels are NOT counted
	svar		glstTG		= root:cont:glstTG
	svar		glstAD		= root:cont:glstAD	
	svar		glstSingleAD	= root:cont:glstSingleAD	
	glstTG	= "", glstAD = "" , glstSingleAD = ""
	string		bf
	variable	l, ADChan, TGChan, TGMCChan
	gnCntAD	= 0
	gnCntTG	= 0
	wAD2TG	= AD_NOT_USED						// 030804 reset all telegraph connection
	for ( l = 0; l < nLines(); l += 1 )
		if ( cmpstr( StringFromList( 0, GetScrLine( l ), sMAINKEYSEP ), sMainKey ) == 0 )	// does Line contain the first expected key ?
			ADChan	= GetScrValS( GetScrLine( l ), "Chan" )
			if ( numtype( ADChan ) != NUMTYPE_NAN )						// 'Chan' is misspelled or missing
				if ( numtype( GetScrVal( l, "TGChan" ) ) != NUMTYPE_NAN )
					TGChan	= GetScrVal( l, "TGChan" )
					sprintf bf, "\t\t\t\tTelegraphConnect().. Found AD %d  with   \tTGChan %d  \r",  ADChan,  TGChan; Out1( bf, bPrintIt )
					//wAD2TG[ ADChan ]	=TGChan
					SetTG( wAD2TG, ADChan, TGChan ) 
					glstTG	= AddListItem( num2str( TGChan ), glstTG, " ", Inf )	// use space as separator so that CED can use this string in 'ADCBST' directly
					gnCntTG	+= 1
				elseif ( numtype( GetScrVal( l, "TGMCChan" ) ) != NUMTYPE_NAN )
					TGMCChan	= GetScrVal( l, "TGMCChan" )
					sprintf bf, "\t\t\t\tTelegraphConnect().. Found AD %d  with   \tTGMCChan %d  \r",  ADChan,  TGMCChan; Out1( bf, bPrintIt )
					//wAD2TG[ ADChan ]	=TGMCChan + cMAXADCCHANS	// a channel above  'cMAXADCCHANS'  means we have a  MultiClamp TG channel 
					SetTG( wAD2TG, ADChan, TGMCChan + cMAXADCCHANS )	// a channel above  'cMAXADCCHANS'  means we have a  MultiClamp TG channel 
 				else
					sprintf bf,  "\t\t\t\tTelegraphConnect().. Found AD %d  without \tTGChan  \r",  ADChan; Out1( bf, bPrintIt )
					//wAD2TG[ ADChan ]	=AD_HASNO_TG_CHAN
					SetTG( wAD2TG, ADChan, AD_HASNO_TG_CHAN ) 
					glstSingleAD  = AddListItem( num2str( ADChan ), glstSingleAD, " ", Inf )	// use space as separator so that CED can use this string in 'ADCBST' directly
				endif
				glstAD	= AddListItem( num2str( ADChan ), glstAD, " ", Inf )			// use space as separator so that CED can use this string in 'ADCBST' directly
				gnCntAD	+= 1
			else
				Alert( cFATAL, "Expected keyword   'Chan'   after  'Adc :' " )
				return	cERROR
			endif
		endif
	endfor
	sprintf  bf, "\t\t\tTelegraphConnect( )       Single AD : '%s'   glstAD : '%s'    gnCntAD:%d    glstTG : '%s'    gnCntTG:%d \r", MakeSingleADList(),  glstAD, gnCntAD, glstTG, gnCntTG
	Out1( bf, bPrintIt )
	//PrintWave( "\t\t\tTelegraphConnect( 'wAD2TG' )", wAD2TG )
End

Function		SetTG( wAD2TG, TrueADChan, TGChan ) 
	wave	wAD2TG		= root:cont:wAD2TG	
	variable	TrueADChan, TGChan
	if ( wAD2TG[ TrueADChan ] == AD_NOT_USED )		// should still be empty
		wAD2TG[ TrueADChan ]	= TGChan
	else
		Alert( cIMPORTANT, "Adc channel " + num2str( TrueADChan ) + " is defined multiple times. Last definition will be used. " ) 
	endif
End

Function		PrintWave( sText, wNumbers )
// prints any 1dim wave
	string		sText
	wave	wNumbers
	variable	n
	printf "%s", sText
	for ( n = 0; n < numPnts( wNumbers ); n += 1 )
		printf "\t%d", wNumbers[ n ]
	endfor
	printf "\r"
End




Function	/S	MakeSingleADList()
// Makes a  list containing the names of all true AD channels which are not controlled by a telegraph channel. Used in the 'Gain' panel.
	svar		glstSingleAD		= root:cont:glstSingleAD	
	string		lstSingleADNames	= ""
	variable	c
	for ( c = 0; c < ItemsInList( glstSingleAD, " " ); c += 1 )
		lstSingleADNames	= AddListItem( AdcNm( str2num( StringFromList( c, glstSingleAD, " " ) ) ) , lstSingleADNames, ";" , Inf )
	endfor
	//printf  "\t\t\tTelegraphGain( MakeSingleADList( glstSingleAD: '%s' ) ->\tlstSingleADNames: '%s' \r", glstSingleAD, lstSingleADNames
	return	lstSingleADNames
End


Function		GetSmpIntFromStimFolder()
	nvar		gnSmpInt	= root:stim:gnSmpInt	
	return	gnSmpInt	
End


Function	/S	ADTGNm( c )
// returns wave name for Adc or telegraph wave  when  index  c = 0,1,2... is given
	variable	c
	svar		glstAD	= root:cont:glstAD
	svar		glstTG	= root:cont:glstTG
	nvar		gnCntAD	= root:cont:gnCntAD
	variable	nChanNr	= str2num( StringFromList( c, glstAD + glstTG, " " ) ) 
	if ( c < gnCntAD )
		return	AdcNm( nChanNr ) 			// The wave name of a true AD channel...
	else									// ..must be different  from the wave name of a telegraph channel.
		return	TGNm( nChanNr ) 			// This allows that the same telegraph channel is also sampled and processed.. 
	endif									// ..independently as as true AD channel. This is (at least) very useful for testing....
End

Function	/S	AdcNm( ch )
// returns wave name for Adc (not for telegraph, their name must differ!) wave when true channel number from script is given
	variable	ch
	return	"Adc" + num2str( ch  )
End
Function	/S	TgNm( ch )
// returns wave name for  telegraph wave when true channel number from script is given. This name must be different from the name for the true Adc wave
	variable	ch
	return	AdcNm( ch ) + "T"
End


Function		SupplyWavesADC( nTotalPts )
	// supply  ADC channel waves (as REAL)  here 
	variable	nTotalPts
	nvar		nSmpInt	= root:stim:gnSmpInt
	nvar		nSmpIAD	= root:stim:gnSmpInt
	nvar		gnCntAD	= root:cont:gnCntAD
	variable	c, nPnts	= nTotalPts  * nSmpInt / nSmpIAD
	string		bf

	if ( cPROT_AWARE )
		nvar		gnProts	= root:cont:gnProts
		nPnts *= gnProts
	endif

	for ( c = 0; c < gnCntAD; c += 1)	
		make  /O   	/N=	( nPnts)	$ADTGNm( c )
		sprintf bf, "\t\t\tCed SupplyWavesADC(  Adc  )  \t building  c:%d  '%s' \tpts:%6d\r", c,  ADTGNm( c ), numPnts( $ADTGNm( c ) ) 
		Out1( bf, 0 )
	endfor
End

Function		SupplyWavesADCTG( nTotalPts )
	// supply  ADC telegraph channel waves (as REAL)  here 
	variable	nTotalPts
	nvar		nSmpInt		= root:stim:gnSmpInt
	nvar		nSmpIAD		= root:stim:gnSmpInt
	nvar		gnCntAD		= root:cont:gnCntAD
	nvar		gnCntTG		= root:cont:gnCntTG
	nvar		gnCompress	= root:cont:gnCompressTG
	variable	c, nPnts		= nTotalPts  * nSmpInt / nSmpIAD
	string		bf
	nPnts	= nTotalPts  * nSmpInt / nSmpIAD / gnCompress

	if (  cPROT_AWARE )
		nvar		gnProts	= root:cont:gnProts
		nPnts *= gnProts
	endif
	for ( c = gnCntAD; c < gnCntAD + gnCntTG; c += 1)	
		make  /O   	/N=	( nPnts)	$ADTGNm( c )
		sprintf bf, "\t\t\tCed SupplyWavesADCTG(AdcTG)\t building  c:%d  '%s' \tpts:%6d \tCompress:%3d \r", c,  ADTGNm( c ), numPnts( $ADTGNm( c ) ) , gnCompress
		Out1( bf, 0 )
	endfor
End

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function SetPoints( CedMaxSmpPts, nPnts, nSmpInt , nDA, nAD, nTG, nSlices, nErrorBad, nErrorFatal )
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

// Runs faster when a high gMaxReactionTime ( >=20 s ) is set.  One could possibly speed this up even for the commonly used  gMaxReactionTime ~ 2 s, ..
// ...if the combinations having too high a reaction time are sorted out early..... 

	variable	CedMaxSmpPts, nPnts, nSmpInt, nDA, nAD, nTG, nSlices, nErrorBad, nErrorFatal
	nvar		gnCompressTG		= root:cont:gnCompressTG
	nvar		gMaxSmpPtspChan	= root:cont:gMaxSmpPtspChan
	nvar		gnReps			= root:cont:gnReps
	nvar 		gChnkPerRep		= root:cont:gChnkPerRep
	nvar		gPntPerChnk		= root:cont:gPntPerChnk
	nvar	 	gnOfsDA			= root:cont:gnOfsDA,		gSmpArOfsDA	= root:cont:gSmpArOfsDA
	nvar 		gnOfsAD			= root:cont:gnOfsAD,		gSmpArOfsAD	= root:cont:gSmpArOfsAD
	nvar		gnOfsDO			= root:cont:gnOfsDO
	nvar		gMaxReactionTime 	= root:cont:gMaxReactionTime 
	variable	nDAMem, nADMem,  SmpArEndDA,  SmpArEndAD, nDigoutMem, nTrfAreaBytes, TAUsed = 0, MemUsed = 0, FoM = 0, BestFoM = 0, nChunkTimeMS
	variable	nReps, MinReps, nChnkPerRep, nPntPerChnk, nChunks, MinNrChunks, nSumChs, EffChsM, EffChsTA, PtpChkM, PtpChkTA,  c, nCompress, nCompPts, HasPoints
	variable	bPrintIt	=   FALSE
	string		bf

	gnCompressTG		= 255
	gMaxSmpPtspChan	= 0
	gnReps			= 0
	gChnkPerRep		= 0
	gPntPerChnk		= 0

	nDigOutMem	= nSlices  * BYTES_PER_SLICE 
	gnOfsDO		= floor( ( CedMaxSmpPts * 2 - nDigOutMem ) / BYTES_PER_SLICE ) * BYTES_PER_SLICE	// 16 byte boundary is sufficient at the top end of the CED memory
	CedMaxSmpPts	= gnOfsDO / 2								// decrease sampling area by memory occupied by digout slices (=above gnOfsDO)
//if ( ! c1401WITH64KB )
//	CedMaxSmpPts	-= 0xFFFE									// worst case: decrease sampling area by TWICE 64KB-1 (BYTES) as CED requires sampling areas to start at 64KB boundaries (often wasting memory)
//endif														// possibly we waste here deliberately up to 128KB sampling area memory to simplify the following calculations (could be regained..)
	//string	lstFactors		= BreakIntoPrimes( nPnts )				// list containing the prime numbers which make up 'nPnts'
	//string	lstFactors		= Factors( nPnts )					// list containing integral dividers of  'nPnts'

	nvar		gnProts		= root:cont:gnProts
	string		lstCompressFct
	string		lstPrimes	

	nPnts	= nPnts * gnProts								//

	lstCompressFct	= CompressionFactors( nPnts, nAD, nTG )			// list containing all allowed compression factors

//	sprintf  bf, "\t\t\t\t\tCed SetPoints( ProtAw:%d)\tMxPts\t\tnPts\tSlc\t DA AD TG Cmp\tSum  MxPtpChan\t MinChk\tChunks\tMinRep\tREPS CHKpREP PTpCHK\t ChkTim\tTA%% M%% FoM \r", cPROT_AWARE
	sprintf  bf, "\t\t\tCed SetPoints( ProtAw:%d)\t\t\tMxPts\t\tnPts\tSlc\t DA AD TG Cmp\tSum  MxPtpChan\t MinChk\tChunks\tMinRep\tREPS CHKpREP PTpCHK\t ChkTim\tTA%% M%% FoM \r", cPROT_AWARE
	Out1( bf, 0 )

	// Loop1(Compress): Divide  'nPnts'  by all possible compression factors to find those which leave no remainder
	BestFoM = 0
	for ( c = 0; c < ItemsInList( lstCompressFct ); c += 1 )

		nCompress	= str2num( StringFromList( c, lstCompressFct ) )
	
		nSumChs		= nAD + nDA + nTG
		EffChsM		= 2 * nDA + 2 * nAD + nTG + nTG / nCompress	// Determine the absolute minimum number of effective channels limited by the entire CED memory (= transfer area + sampling area )
		PtpChkM		= trunc( CedMaxSmpPts / EffChsM / 2 )		// Determine the absolute maximum PtsPerChk considering the entire Ced memory,  2 reserves space for the 2 swinging buffers
		EffChsTA		=  nDA + nAD + nTG / nCompress			// Determine the absolute minimum number of effective channels limited by the Transfer area
		PtpChkTA		= trunc( cMAX_TAREA_PTS / EffChsTA / 2 )	// Determine the absolute maximum PtsPerChk considering only the Transfer area ,  2 reserves space for the 2 swinging buffers
		nPntPerChnk	= min( PtpChkTA, PtpChkM )				// the lowest value of both and of the passed value is the new upper limit  for  PtsPerChk

		MinNrChunks	= ceil( nPnts / nPntPerChnk )				// e.g. maximum value for  1 DA, 2AD, 2TG/Compress: 1 MBYTE =   appr.  80000 POINTSPerChunk * 3.1 Channels *  2 swap halfs
		//sprintf  bf, "\t\t\tCed SetPoints(tried..)\t%10d\t%10d  %4d\t%4d%4d%5d%5d\t%5.3lf \t%5.3lf \t%6d\tMxPpCM:%6d\tMxPpCT:%6d >%6d \r", CedMaxSmpPts, nPnts, nSlices, nDA, nAD, nTG, nCompress, EffChsTA, EffChsM, MinNrChunks, PtpChkM, PtpChkTA, nPntPerChnk
		//Out1( bf, 0 ) 
	
		gMaxSmpPtspChan	= trunc(  ( CedMaxSmpPts -  ( nDA + nAD  + nTG / nCompress ) * 2 * nPntPerChnk ) / nSumChs )	// subtract memory used by transfer area
	
		// Get the starting value for the Repetitions loop
		// the correct (=large enough) 'MinReps' value ensures that ALL possibilities found in the 'Rep' loop below are legal (=ALL fit into the CED memory) : none of them has later to be sorted out
		MinReps			= ceil( nPnts / gMaxSmpPtspChan )	
	
		nCompPts	= nPnts / nCompress
		//printf "old -> new \tCompress: %2d \tMinChunks:%2d \t-> %d \tMinReps:%2d \t-> %d  \r", nCompress, ceil( nPnts / nPntPerChnk ), ceil( nPnts*gnProts / nPntPerChnk ),  ceil( nPnts / gMaxSmpPtspChan ), ceil( nPnts*gnProts / gMaxSmpPtspChan )

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
			if ( nChunks == NOTFOUND )
				break								// Leave the loop as  'nCompPts'  was a prime number which cannot be processed. The 'FoM'  being 0  will  trigger an error to alert the user.
			endif
			 // nReps		= FindNextDividerBetween( nChunks, MinReps, nChunks / 2 )		// 031125 we need al least 2 chunks, but then ChunksPerRep = 2 may result which works in principle but has in some cases too little 'gReserve'  for a reliable acquisition...
			nReps		= FindNextDividerBetween( nChunks, MinReps, nChunks / 3 )		// 031125 / 3 : we use at least 3 chunks although we theoretically need only at least 2 chunks. We then avoid ChunksPerRep = 2 which works in principle but has in some cases too little 'gReserve'  for a reliable acquisition...
			if ( nReps == NOTFOUND )
				//printf "\t\t\t\tCed SetPoints(3) \tnCompTG:%3d , \tSum:%.3lf \tCmpPts:\t%7d\tnChunks: %.3lf \t-> %3d -> %3d , \t==Quot:\t%6d\tReps:%3d min\tCould not divide %3d / nReps \r", nCompress, EffChsTA, nCompPts, nPnts/ nPntPerChnk, MinNrChunks, nChunks, nCompPts / nChunks, MinReps, nChunks
				MinNrChunks	= nChunks+1
				continue								// Restart the loop
			endif
			nChnkPerRep	= nChunks / nReps				// we found a combination of  nReps and  ChnkPerRep which fits nChunks without remainder
			nPntPerChnk	= nPnts/ nChunks  
			//printf "\t\t\t\tCed SetPoints(4) \tnCompTG:%3d , \tSum:%.3lf \tCmpPts:\t%7d\tnChunks: %.3lf \t\t   -> %3d , \t==Quot:\t%6d\tReps:%3d/%d\tChnk/Reps:\t%4d\t  PtpChk:%6d \r", nCompress, EffChsTA, nCompPts, nPnts/ nPntPerChnk,  nChunks, nCompPts / nChunks, MinReps, nReps, nChunks / nReps, nPntPerChnk	 

			nChunkTimeMS	= nPntPerChnk * nSmpInt / 1000
			MemUsed		= MemUse(  nChnkPerRep, nPntPerChnk, gMaxSmpPtspChan )
			TAused		= TAuse( nPntPerChnk, nDA, nAD, cMAX_TAREA_PTS ) 
			// Even when optimizing the reaction time  the FigureOfMerit  depends only on the memory usage. The reaction time is introduced as an  'too long' - 'OK' condition
			FoM			= FigureOfMerit( nChnkPerRep, nPntPerChnk, gMaxSmpPtspChan, nDA, nAD, nTG,  nCompress, cMAX_TAREA_PTS ) 
		
			sprintf  bf, "\t\t\t\t\tCed SetPoints(candi.)\t%10d\t%10d  %4d\t%4d%4d%5d%5d\t%5.3lf %10d\t%6d\t%6d\t%6d\t%6d\t%6d\t%6d\t%6d\t%3d\t%3d\t%6.1lf  \r", CedMaxSmpPts, nPnts, nSlices, nDA, nAD, nTG, nCompress, nDA+ nAD+nTG/nCompress,  gMaxSmpPtspChan, MinNrChunks, nReps * nChnkPerRep, MinReps, nReps, nChnkPerRep, nPntPerChnk, nChunkTimeMS, TAUsed, MemUsed, FoM
			Out( bf )

			MinNrChunks	= nChunks + 1					// When optimizing ONLY for high data rates: Comment out this line 

			if ( nChunkTimeMS <= gMaxReactionTime * 1000 )	// When optimizing ONLY for high data rates: Always true
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
	MemUsed		= MemUse(  gChnkPerRep, gPntPerChnk, gMaxSmpPtspChan )
	TAused		= TAuse( gPntPerChnk, nDA, nAD, cMAX_TAREA_PTS ) 
	FoM			= FigureOfMerit( gChnkPerRep, gPntPerChnk, gMaxSmpPtspChan, nDA, nAD, nTG,  gnCompressTG, cMAX_TAREA_PTS ) 
	sprintf  bf, "\t\t\tCed SetPoints(final)\t\t\t%10d\t%10d  %4d\t%4d%4d%5d%5d\t%5.3lf %10d\t%6d\t%6d\t%6d\t%6d\t%6d\t%6d\t%6d\t%3d\t%3d\t%6.1lf ( incl. %d nProts)  \r", CedMaxSmpPts, nPnts, nSlices, nDA, nAD, nTG, gnCompressTG, nDA+ nAD+nTG/gnCompressTG,  gMaxSmpPtspChan, MinNrChunks, gnReps * gChnkPerRep, MinReps, gnReps, gChnkPerRep, gPntPerChnk, nChunkTimeMS, TAUsed, MemUsed, FoM, gnProts
	Out1( bf, bPrintIt )

	// The following warning sorts out bad combinations which result from the 'Minimum chunk time' condition (> 1000 ms)
	// Example for bad splitting	: nPnts : 100000 -> many chunks : 10000  , few   pointsPerChk :       10 ,   ChunkTime : 2 ms . 
	// Good (=normal) splitting	: nPnts : 100000 -> few   chunks :       10  , many pointsPerChk : 10000 ,   ChunkTime : 900 ms 
	if ( gnReps * gChnkPerRep > gPntPerChnk   &&  gnReps > 1 ) 	// in the special case of few data points (=they fit with 1 repetition in the Ced memory) allow even few PtsPerChk in combination with many 'nChunk'
		sprintf bf, "Script has bad number of data points (%d) leading to poor performance. \r\tAdjust duration(s) in stimulus protocol slightly so that data points contains more small primes." , nPnts
		lstPrimes	= BreakIntoPrimes( nPnts )					// list containing the prime numbers which make up 'nPnts'
		Alert( nErrorBad,  bf + "   " + lstPrimes[0,50] )
		Delay( 2 )										// time to read the message in the continuous test mode
	endif
	
	HasPoints		= gnReps * gChnkPerRep * gPntPerChnk  
	if ( HasPoints != nPnts )		
		sprintf bf, "The number of stimulus data points (%d) could not be divided into CED memory without remainder. \r\tAdjust duration(s) in stimulus protocol slightly so that data points contains more small primes." , nPnts
		lstPrimes	= BreakIntoPrimes( nPnts )					// list containing the prime numbers which make up 'nPnts'
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
	Out1( bf, 0 )

	// build the areas one behind the other 
//if ( ! c1401WITH64KB )
//	gSmpArOfsDA	= ceil( nTrfAreaBytes / 0x10000 ) * 0x10000							// CED requires sampling areas to start at 64KB borders
//	SmpArEndDA	= gSmpArOfsDA + round( 2 * gChnkPerRep * gPntPerChnk * nDA  )		// uses memory ~number of channels (=as little memory as possible)
//	gSmpArOfsAD	= ceil( SmpArEndDA / 0x10000 ) * 0x10000							// CED requires sampling areas to start at 64KB borders	
//	SmpArEndAD 	= gSmpArOfsAD + round( 2 * gChnkPerRep * gPntPerChnk * ( nAD + nTG ) )		
//endif
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
		return	cERROR
	endif

	return	nTrfAreaBytes / 2                       
End

Function		FindNextDividerBetween( nBig, nMin, nMax )
// factorizes  'nBig'  and returns the factor closest (equal or larger) to  'nMin'  and  smaller or equal  'nMax' 
// Brute force: could be done easily by looping through numbers > nMin and checking if the remainder of  nBigs/numbers  is 0 . This is OK when  nBig <~ 1 000 000, otherwise is takes too long (>1 s)
// In the approach  taken 'nBig' is first split into factors (which requires splitting into primes), then from the resulting factor list the factor closest to but greater or equal  'nMin' is picked.  Much faster for large 'nBig' 
	variable	nBig, nMin, nMax
	variable 	f, nFactor
	string		lstFactors	= Factors( nBig )				// break  'nBig'  into factors, requires splitting into primes, lstFactors contains 'nBig'
	//for	( f = 0; f < ItemsInList( lstFactors )		; f += 1 )	// Version1 :  allow returning  'nBig'  if no other factor is found
	for 	( f = 0; f < ItemsInList( lstFactors ) - 1	; f += 1 )	// Version2 :  never return 'nBig'  even if no other factor is found (this option must be used when breaking 'nPnts' into 'chunks'  and  'Reps') 
		nFactor	= str2num( StringFromList( f, lstFactors ) )
		if ( nMin <= nFactor  &&  nFactor <= nMax )
			//printf "\t\t\t\t\tNextDividerBetween( %5d, \tnMin:%5d, \tnMax:%5d\t) -> found divider:%d   in   %s \r", nBig, nMin,nMax, nFactor, lstFactors[0, 180]
			return	nFactor
		endif
	endfor		
	//printf "\t\t\t\t\tNextDividerBetween( %5d, \tnMin:%5d, \tnMax:%5d\t) -> could not find divider between %5d\tand %5d \tin   %s \r", nBig, nMin,nMax, nMin,nMax, lstFactors[0, 180]
	return	NOTFOUND
End	

Static Function		TAUse( PtpChunk, nDA, nAD, MaxAreaPts )
	variable	PtpChunk, nDA, nAD, MaxAreaPts 
	return	PtpChunk * (nDA + nAD ) * 2 / MaxAreaPts * 100	// the compressed TG channels are NOT included here as more TG points would erroneously increase TAUsage and FoM while actually deteriorating performance
End	

Static Function		MemUse(  nChnkPerRep, nPntPerChnk, nMaxSmpPtspChan )
	variable	nChnkPerRep, nPntPerChnk, nMaxSmpPtspChan
	return	nChnkPerRep * nPntPerChnk / nMaxSmpPtspChan * 100 		
End

Static Function		FigureOfMerit( nChnkPerRep, PtpChunk, nMaxSmpPtspChan, nDA, nAD, nTG,  Compress, MaxAreaPts )
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
	//printf "\t\tFoM( nChnkPerRep:%3d \tPtpChk:\t%8d\tnMaxSmpPtspChan:\t%10d\t  nDA:%d   nAD:%d   nTG:%d   Compress:%4d\t MaxAreaPts:%6d\t->  FoM:%.1lf  \r"  , nChnkPerRep, PtpChunk, nMaxSmpPtspChan, nDA, nAD, nTG,  Compress, MaxAreaPts, FoM
	return	FoM
End


Static Function  /S	CompressionFactors( nPnts, nAD, nTG )	
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
	//printf "\t\t\tCompressionFactors( n:%5d, nAD:%2d, nTG:%2d )  \tnMaxCompressTG:%4d \t-> factors: %s \r", nPnts, nAD, nTG, nMaxCompressTG, lstCompressFct[0,120]
	return	lstCompressFct
End


Function		SetPointsTestOnce()		// 030724
// for testing  problematic combinations of nCEDMemPts, nPnts, nSmpInt, nDa, nAD, nTG, nSlices   which have been found with  'SetPointsTestCont()'
	nvar		gnReps		= root:cont:gnReps			// these..
	nvar 		gChnkPerRep	= root:cont:gChnkPerRep		// are
	nvar		gPntPerChnk	= root:cont:gPntPerChnk		// all
	nvar		gSmpArOfsDA	= root:cont:gSmpArOfsDA		// set
	nvar 		gSmpArOfsAD	= root:cont:gSmpArOfsAD		// by
	nvar		gnOfsDO		= root:cont:gnOfsDO			// SetPoints ()
	string		bf
	variable	SmpArEndDA, SmpArEndAD, nChunkTimeMS, nTrfAreaPts				// are computed
   	variable	nCEDMemPts, nPnts, nSmpInt, nDA, nAD, nTG, nSlices, OptChkTimeMs	// input parameters
//	nCEDMemPts	=   500000;	nPnts	= 446140;		nSmpInt	= 105;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	= 3710
//	nCEDMemPts	= 1500000;	nPnts	= 395320;		nSmpInt	= 105;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	= 2830
//	nCEDMemPts	= 2000000;	nPnts	= 197324;		nSmpInt	=  40;	nDA	= 2;	nAD	= 3;	nTG	= 1;	nSlices	=  410
//	nCEDMemPts	= 6000000;	nPnts	= 854884;		nSmpInt	=  65;	nDA	= 1;	nAD	= 3;	nTG	= 3;	nSlices	=  3690
//	nCEDMemPts	= 3000000;	nPnts	= 8844448;	nSmpInt	= 115;	nDA	= 2;	nAD	= 1;	nTG	= 2;	nSlices	=  4530	// gives warning
//	nCEDMemPts	= 3000000;	nPnts	= 8844458;	nSmpInt	= 115;	nDA	= 2;	nAD	= 1;	nTG	= 2;	nSlices	=  4530	// corrected
//	nCEDMemPts	= 3000000;	nPnts	= 8844548;	nSmpInt	= 115;	nDA	= 2;	nAD	= 1;	nTG	= 2;	nSlices	=  4530	// corrected
//	nCEDMemPts	= 3000000;	nPnts	= 8845448;	nSmpInt	= 115;	nDA	= 2;	nAD	= 1;	nTG	= 2;	nSlices	=  4530	// corrected
//	nCEDMemPts	= 13000000;	nPnts	= 4483984;	nSmpInt	=  95;	nDA	= 1;	nAD	= 2;	nTG	= 1;	nSlices	=  1630	// gives warning
//	nCEDMemPts	= 13000000;	nPnts	= 4483990;	nSmpInt	=  95;	nDA	= 1;	nAD	= 2;	nTG	= 1;	nSlices	=  1630	// corrected
//	nCEDMemPts	= 13000000;	nPnts	= 4484000;	nSmpInt	=  95;	nDA	= 1;	nAD	= 2;	nTG	= 1;	nSlices	=  1630	// corrected
//	nCEDMemPts	=     500000;	nPnts	= 4484000;	nSmpInt	=  95;	nDA	= 1;	nAD	= 1;	nTG	= 0;	nSlices	=  1630	// corrected

//	nCEDMemPts	=  8000000;	nPnts	= 560010;		nSmpInt	=  50;	nDA	= 1;	nAD	= 2;	nTG	= 2;	nSlices	=  1630	// 030901

	nCEDMemPts	=  8000000;	nPnts	= 1024*1024-29800;	nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// 030902 test to provoke TA > 1MB error
	nCEDMemPts	=  8000000;	nPnts	= 1046821;	nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// 030902  131x131x61 test to provoke TA > 1MB error
	nCEDMemPts	=  8000000;	nPnts	= 1081143;	nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// 030902  131x131x63 test to provoke TA > 1MB error
	nCEDMemPts	=  80000000;	nPnts	= 1081143;	nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// 030902  131x131x63 test to provoke TA > 1MB error
	nCEDMemPts	=  80000000;	nPnts	= 131*131*7*11;	nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// 030902test to provoke TA > 1MB error
	nCEDMemPts	=  80000000;	nPnts	= 131*131*7*13;	nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// 030902test to provoke TA > 1MB error
	nCEDMemPts	=  80000000;	nPnts	= 131*131*7*17;	nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// 030902test to provoke TA > 1MB error
	nCEDMemPts	=  80000000;	nPnts	= 131*131*7*19;	nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// 030902test to provoke TA > 1MB error
	nCEDMemPts	=  80000000;	nPnts	= 131*131*11*13;	nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// 030902test to provoke TA > 1MB error
	nCEDMemPts	=  80000000;	nPnts	= 131*131*11*17;	nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// 030902test to provoke TA > 1MB error
	nCEDMemPts	=  80000000;	nPnts	= 131*131*11*19;	nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// 030902test to provoke TA > 1MB error
	nCEDMemPts	=  8000000;	nPnts	= 131*131*7*19*11;	nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// 030902test to provoke TA > 1MB error

	nCEDMemPts	=  8000000;	nPnts	= 131*137*2*29;	nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// 030902test to provoke TA > 1MB error
	nCEDMemPts	=  8000000;	nPnts	= 131*137*2*31;	nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// 030902test to provoke TA > 1MB error
	nCEDMemPts	=  8000000;	nPnts	= 131*137*3*19;	nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// 030902test to provoke TA > 1MB error
	nCEDMemPts	=  8000000;	nPnts	= 131*137*4*14;	nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// 030902test to provoke TA > 1MB error
	nCEDMemPts	=  8000000;	nPnts	= 131*139*7*9;		nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// 030902test to provoke TA > 1MB error
	nCEDMemPts	=  8000000;	nPnts	= 137*139*7*9;		nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// 030902test to provoke TA > 1MB error
	nCEDMemPts	=  8000000;	nPnts	= 131*149*7*9;		nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// 030902test to provoke TA > 1MB error
	nCEDMemPts	=  8000000;	nPnts	= 151*149*7*7;		nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// 030902test to provoke TA > 1MB error
	nCEDMemPts	=  8000000;	nPnts	= 151*149*7*9;		nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// 030902test to provoke TA > 1MB error
	nCEDMemPts	=  8000000;	nPnts	= 151*151*7*9;		nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// 030902test to provoke TA > 1MB error
	nCEDMemPts	=  8000000;	nPnts	= 151*151*5*9;		nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// 030902test to provoke TA > 1MB error
	nCEDMemPts	=  8000000;	nPnts	= 151*157*5*9;		nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// +++030902test to provoke TA > 1MB error
//	nCEDMemPts	=  8000000;	nPnts	= 149*157*5*9;		nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// +++030902test to provoke TA > 1MB error
//	nCEDMemPts	=  8000000;	nPnts	= 151*157*5*9;		nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// +++030902test to provoke TA > 1MB error
//	nCEDMemPts	=  8000000;	nPnts	= 151*167*5*9;		nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// +++030902test to provoke TA > 1MB error
//	nCEDMemPts	=  8000000;	nPnts	= 167*131*5*9;		nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// +++030902test to provoke TA > 1MB error
//	nCEDMemPts	=  8000000;	nPnts	= 131*151*5*9;		nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// +++030902test to provoke TA > 1MB error
//	nCEDMemPts	=  8000000;	nPnts	= 131*157*3*17;	nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// +++030902test to provoke TA > 1MB error
//	nCEDMemPts	=  8000000;	nPnts	= 131*149*5*11;	nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// +++030902test to provoke TA > 1MB error
//	nCEDMemPts	=  8000000;	nPnts	= 131*299*3*9;		nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// +++030902test to provoke TA > 1MB error
//	nCEDMemPts	=  8000000;	nPnts	= 131*131*5*7;		nSmpInt	=  50;	nDA	= 1;	nAD	= 2;	nTG	= 2;	nSlices	=  1630	// +++030902test to provoke TA > 1MB error
//	nCEDMemPts	=  8000000;	nPnts	= 67*67*13*17;		nSmpInt	=  50;	nDA	= 1;	nAD	= 2;	nTG	= 2;	nSlices	=  1630	// +++030902test to provoke TA > 1MB error
//	nCEDMemPts	=  8000000;	nPnts	= 67*67*11*19;		nSmpInt	=  50;	nDA	= 1;	nAD	= 2;	nTG	= 2;	nSlices	=  1630	// +++030902test to provoke TA > 1MB error
//	nCEDMemPts	=  8000000;	nPnts	= 67*83*11*17*19;	nSmpInt	=  50;	nDA	= 1;	nAD	= 2;	nTG	= 2;	nSlices	=  1630	// +++030902test to provoke TA > 1MB error
//	nCEDMemPts	=  8000000;	nPnts	= 67*83*10*17*20;	nSmpInt	=  50;	nDA	= 1;	nAD	= 2;	nTG	= 2;	nSlices	=  1630	// +++030902test to provoke TA > 1MB error
//	nCEDMemPts	=  1406546;	nPnts	=  5684200;		nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 2;	nSlices	=  10		// +++030902test to provoke TA > 1MB error
//	nCEDMemPts	=  5400306;	nPnts	=  8038600;		nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 2;	nSlices	=  10		// +++030902test to provoke TA > 1MB error
//	nCEDMemPts	=  1984802;	nPnts	=   6144400;		nSmpInt	=  50;	nDA	= 2;	nAD	= 3;	nTG	= 1;	nSlices	=  10		// +++040902test
//	nCEDMemPts	=  5000000 ;	nPnts	=   8111800;		nSmpInt	=  50;	nDA	= 3;	nAD	= 2;	nTG	= 1;	nSlices	= 0		// +++040902test
//	nCEDMemPts	=  6996000 ;	nPnts	=   9773800;		nSmpInt	=  50;	nDA	= 1;	nAD	= 3;	nTG	= 2;	nSlices	= 2270	// +++040902test
//	nCEDMemPts	=  8000000;	nPnts	=  10009 * 10037;	nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 2;	nSlices	=  10		// Product of 2 primes
	nCEDMemPts	=  8000000;	nPnts	=    1019 *   1021;	nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 2;	nSlices	=  10		// Product of 2 primes
//	nCEDMemPts	=  9999997;	nPnts	=  1048583;		nSmpInt	=  50;	nDA	= 1;	nAD	= 1;	nTG	= 2;	nSlices	=  10		// Prime number will fail
//	nCEDMemPts	=  100000;		nPnts	=   2 * 3 * 3 * 3 * 5 * 5 * 19;	nSmpInt=  50;	nDA	= 1;	nAD	= 1;	nTG	= 1;	nSlices	=  1630	// +++030902test to provoke TA > 1MB error


  	OptChkTimeMs =10000 // 1000 030901	

	nTrfAreaPts	= SetPoints( nCEDMemPts, nPnts, nSmpInt , nDA, nAD, nTG, nSlices, cIMPORTANT, cIMPORTANT )	// all params are points not bytes	

	SmpArEndDA	= gSmpArOfsDA + trunc( 2 * gChnkPerRep * gPntPerChnk * nDA + .5 )			// like SetPoints ()	
	SmpArEndAD 	= gSmpArOfsAD + trunc( 2 * gChnkPerRep * gPntPerChnk * ( nAD + nTG ) + .5 )	// like SetPoints ()		
	nChunkTimeMS	= gPntPerChnk * nSmpInt /  1000
	printf "\t%8d\t%8d\tSi:%4d\t%2d\t%2d\t%2d\tSl:%4d\t: Rep:%4d\t* Chk:%4d\t* PpC:%5d\tTA:%8d\t%7d\t%7d\t\t%7d\t%7d\t%10d\t[%4d /\t%4dms]\t \r", nCEDMemPts, nPnts, nSmpInt , nDA, nAD, nTG, nSlices, gnReps, gChnkPerRep, gPntPerChnk, nTrfAreaPts, gSmpArOfsDA, SmpArEndDA, gSmpArOfsAD, SmpArEndAD, gnOfsDO, nChunkTimeMS, OptChkTimeMs

End

Function		SetPointsTestCont()		// 030724
// for finding problematic combinations of nCEDMemPts, nPnts, nSmpInt, nDa, nAD, nTG, nSlices, e.g. nReps > 100,  nChunksPerRep > 100,  Chunktime < 100 ms
	variable	SmpArEndDA, SmpArEndAD, nChunkTimeMS, nTrfAreaPts				// are computed
   	variable	nCEDMemPts, nPnts, nSmpInt, nDA, nAD, nTG, nSlices, OptChkTimeMs	// input parameters
	string		bf
	printf "\r\tSetPointsTestCont()	[ stop with 'Abort', turn on Print options debug ,  Loops ,  Acq ] \r"
	delay( 1 )
	nvar		gnReps		= root:cont:gnReps
	nvar 		gChnkPerRep	= root:cont:gChnkPerRep
	nvar		gPntPerChnk	= root:cont:gPntPerChnk
	nvar		gSmpArOfsDA	= root:cont:gSmpArOfsDA
	nvar 		gSmpArOfsAD	= root:cont:gSmpArOfsAD
	nvar		gnOfsDO		= root:cont:gnOfsDO
	do
		nCEDMemPts	= Random( 500000, 8000000, 500000 )
		nPnts		= Random( 200, 10000000, 2 )			// decreasing the step size to 2..8 will issue more 'Data points' warnings and errors
		nSmpInt		= Random( 20, 220, 5 )
		nDA			= Random( 1, 3, 1 )
		nAD			= Random( 1, 4, 1 )
		nTG			= Random( 0, 3, 1 )
		nSlices		= Random( 10, 5000, 20 )

		nTrfAreaPts	= SetPoints( nCEDMemPts, nPnts, nSmpInt , nDA, nAD, nTG, nSlices, cIMPORTANT, cIMPORTANT )	// all params are points not bytes	

		SmpArEndDA	= gSmpArOfsDA + trunc( 2 * gChnkPerRep * gPntPerChnk * nDA + .5 )			// like SetPoints ()	
		SmpArEndAD 	= gSmpArOfsAD + trunc( 2 * gChnkPerRep * gPntPerChnk * ( nAD + nTG ) + .5 )	// like SetPoints ()	
		nChunkTimeMS	= gPntPerChnk * nSmpInt / 1000
//		printf "\t %10d \t %10d \tSi:%4d\t%2d\t%2d\t%2d\tSl:%4d\t:Rep:%6d\t* Chk:%4d\t* PpC:%5d\tTA:%8d\t%7d\t%7d\t\t%7d\t%7d\t%10d\t[%4d /\t%4dms]\t \r", nCEDMemPts*2, nPnts, nSmpInt , nDA, nAD, nTG, nSlices, gnReps, gChnkPerRep, gPntPerChnk, nTrfAreaPts, gSmpArOfsDA, SmpArEndDA, gSmpArOfsAD, SmpArEndAD, gnOfsDO, nChunkTimeMS, OptChkTimeMs

		if ( nTrfAreaPts == cERROR )
			break
		endif
	while ( TRUE )
End


Function		SetPointsTestContNeighbors()		// 030724
// for finding problematic combinations of nCEDMemPts, nPnts, nSmpInt, nDa, nAD, nTG, nSlices, e.g. nReps > 100,  nChunksPerRep > 100,  Chunktime < 100 ms
   	variable	nCEDMemPts, nPnts, nSmpInt, nDA, nAD, nTG, nSlices, OptChkTimeMs	// input parameters
	variable	Neighbors		= 50
	printf "\r\tSetPointsTestCont  checking + %d neighbors()	[ stop with 'Abort' ]  \r", Neighbors
	delay( 1 )
	do
		nCEDMemPts	= Random( 500000, 8000000, 500000 )
		nPnts		= Random( 100, 10000000, 2 )			// decreasing the step size to 2..8 will issue more 'Data points' warnings and errors
		nSmpInt		= Random( 20, 220, 5 )
		nDA			= Random( 1, 3, 1 )
		nAD			= Random( 1, 4, 1 )
		nTG			= Random( 0, 3, 1 )
		nSlices		= Random( 10, 5000, 20 )
		CheckNeighbors( nCEDMemPts, nPnts, nSmpInt , nDA, nAD, nTG, nSlices, Neighbors )	
	while ( TRUE )
End


Function		SearchImprovedStimulusTiming( nCEDMemPts, nPnts, nSmpInt, nDA, nAD, nTG, nSlices )
	variable	nCEDMemPts, nPnts, nSmpInt, nDA, nAD, nTG, nSlices
	variable	Neighbors		= 100
	printf "\t\tSearching improved stimulus timing within the range %d points * %d us = original script length = %.2lf ms to %.2lf ms ", nPnts, nSmpInt, nPnts * nSmpInt  / MILLITOMICRO, ( nPnts + Neighbors ) * nSmpInt / MILLITOMICRO
	CheckNeighbors( nCEDMemPts, nPnts, nSmpInt , nDA, nAD, nTG, nSlices, Neighbors )	
End


Function		CheckNeighbors( nCEDMemPts, nPnts, nSmpInt , nDA, nAD, nTG, nSlices, Neighbors )	
	variable	nCEDMemPts, nPnts, nSmpInt , nDA, nAD, nTG, nSlices, Neighbors	
	nvar		gnReps			= root:cont:gnReps
	nvar 		gChnkPerRep		= root:cont:gChnkPerRep
	nvar		gPntPerChnk		= root:cont:gPntPerChnk
	nvar		gSmpArOfsDA		= root:cont:gSmpArOfsDA
	nvar 		gSmpArOfsAD		= root:cont:gSmpArOfsAD
	nvar		gnOfsDO			= root:cont:gnOfsDO
	nvar		gnCompressTG		= root:cont:gnCompressTG
	nvar		gMaxSmpPtspChan	= root:cont:gMaxSmpPtspChan

	variable	SmpArEndDA, SmpArEndAD, nChunkTimeMS, nTrfAreaPts				// are computed
	variable	TAUsed, MemUsed, FoM, BestFoM, Pts

	BestFoM = 0
	//printf "\tSetPointsTestContNeighbors() checking points from  %d  to  %d \r",  nPnts - Neighbors, nPnts + Neighbors
	printf "\r"
//	for ( Pts = nPnts - Neighbors; Pts < nPnts + Neighbors; Pts += 2 )
	for ( Pts = nPnts; Pts < nPnts + Neighbors; Pts += 2 )
		nTrfAreaPts	= SetPoints( nCEDMemPts, Pts, nSmpInt , nDA, nAD, nTG, nSlices, cMESSAGE, cMESSAGE )				// all params are points not bytes	
		TAused		= TAuse( gPntPerChnk, nDA, nAD, cMAX_TAREA_PTS ) 
		MemUsed		= MemUse(  gChnkPerRep, gPntPerChnk, gMaxSmpPtspChan )
		FoM			= FigureOfMerit( gChnkPerRep, gPntPerChnk, gMaxSmpPtspChan, nDA, nAD, nTG, gnCompressTG, cMAX_TAREA_PTS ) 
		if ( FoM > 1.001 * BestFoM )		// 1.001 prevents minimal useless improvement from being displayed
			BestFoM = FoM
			SmpArEndDA	= gSmpArOfsDA + trunc( 2 * gChnkPerRep * gPntPerChnk * nDA + .5 )			// like SetPoints ()	
			SmpArEndAD 	= gSmpArOfsAD + trunc( 2 * gChnkPerRep * gPntPerChnk * ( nAD + nTG ) + .5 )	// like SetPoints ()	
			//printf "\t %10d \t %10d \tSi:%4d\t%2d\t%2d\t%2d\tSl:%4d\t:Rep:%6d\t* Chk:%4d\t* PpC:%5d\tTA:%8d\t%7d\t%7d\t\t%7d\t%7d\t%10d\tFoM:%4.1lf \t \r", nCEDMemPts*2, Pts, nSmpInt , nDA, nAD, nTG, nSlices, gnReps, gChnkPerRep, gPntPerChnk, nTrfAreaPts, gSmpArOfsDA, SmpArEndDA, gSmpArOfsAD, SmpArEndAD, gnOfsDO, FoM
			printf "\t %10d \t %10d \tSi:%4d\t%2d\t%2d\t%2d\tSl:%4d\tRep\t%7d\tChk\t%7d\tPpC\t%7d\tTA:\t%7d\t  TA:%3d%% \tMem:%3d%%\t FoM:%5.1lf\t \t \r", Pts, nCEDMemPts*2, nSmpInt , nDA, nAD, nTG, nSlices, gnReps, gChnkPerRep, gPntPerChnk, nTrfAreaPts, TAUsed, MemUsed, FoM
		endif

		if ( nTrfAreaPts == cERROR )
			return cERROR
		endif
	endfor
End


Function		Random( nBeg, nEnd, nStep )
// returns random integer from within the given range, divisible by 'nStep'
	variable	nBeg, nEnd, nStep
	variable	nRange	= ( nEnd - nBeg ) / nStep						// convert to Igors random range ( -nRange..+nRange )
	variable	nRandom	= trunc ( abs( enoise( nRange ) ) ) * nStep + nBeg		// maybe not perfectly random but sufficient for our purposes
	//printf "\tRandom( nBeg:%6d \tnEnd:%6d  \tStep:%6d \t) : %g \r", nBeg, nEnd, nStep, nRandom
	return	nRandom
End

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// 031120
constant	cSTORE_INITIALSIZE	= 1000						// choose initially not too small a value so that (potentially slow) redimensioning has to be done only seldom or never

Function		StoreTimesSet( n, nSwpBegPt, nSwpEndPt )
// Store begin and end point of the 'Cfs store' periods (= the non-Blank periods) in an array. In contrast to 'swSetTimes()'  this is not ordered by prot/block/frame/sweep . Here 1 period is stored in 1 index.
	variable	n, nSwpBegPt, nSwpEndPt 
	wave  /Z	wStoreTimes	= root:stim:wStoreTimes		 		// ignore wave reference checking failures
	if (  ! waveExists( wStoreTimes ) )
		variable	/G	root:stim:nStoreCnt	= cSTORE_INITIALSIZE
		nvar			nStoreCnt			= root:stim:nStoreCnt
 		make /O /I /N = ( nStoreCnt, 2 ) root:stim:wStoreTimes			// the begin and the end  of  each 'Store' period  in total stimulus  given as a point index
	endif
	nvar		nStoreCnt		= root:stim:nStoreCnt
	wave	wStoreTimes	= root:stim:wStoreTimes	
	if ( n == nStoreCnt )										// there are more times to store than the wave can currently hold: increase wave size
		nStoreCnt	+= cSTORE_INITIALSIZE
		redimension /N = ( nStoreCnt, -1 ) wStoreTimes	
	endif
	wStoreTimes[ n ][ 0 ]	= nSwpBegPt
	wStoreTimes[ n ][ 1 ]	= nSwpEndPt
	//printf "\t\tStoreTimesSet( \tn:%3d\tnSwpBegPt:\t %11d \tnSwpEndPt:\t %11d \t )   Current dimension: %d \r", n, nSwpBegPt, nSwpEndPt , nStoreCnt
End

Function		StoreTimesExpandAndRedim(  nProts, nPnts, nStoreCnt )
// Set the currently overdimensioned wave to exact size. The following program function 'StoreChunkSet()'  relies on this fact (and additionally we save memory)
	variable	nProts, nPnts, nStoreCnt
	wave	wStoreTimes	= root:stim:wStoreTimes 
	variable	nProt, nSTime

	redimension	/N = ( nProts * nStoreCnt, -1 ) wStoreTimes

	for ( nProt = 1; nProt < nProts; nProt += 1 )
		for ( nSTime = 0; nSTime < nStoreCnt; nSTime += 1 )
			wStoreTimes[ nSTime + nProt * nStoreCnt ][ 0 ]	= wStoreTimes[ nSTime ][ 0 ] + nProt * nPnts 	
			wStoreTimes[ nSTime + nProt * nStoreCnt ][ 1 ]	= wStoreTimes[ nSTime ][ 1 ] + nProt * nPnts 
			//printf "\t\tStoreTimesExpandAndRedim(\tnProt:\t%3d/%3d\twStoreTimes[ %3d/%3d ] =\t%11d  \t..%11d\t ->\twStoreTimes[ %3d/%3d ] =\t%11d  \t..%11d\t \r", nProt, nProts, nSTime, nStoreCnt, wStoreTimes[ nSTime ][ 0 ] , wStoreTimes[ nSTime ][ 1 ] ,  nSTime + nProt * nStoreCnt, nProts * nStoreCnt, wStoreTimes[ nSTime + nProt * nStoreCnt ][ 0 ], wStoreTimes[ nSTime + nProt * nStoreCnt ][ 1 ]
		endfor
	endfor
End

//Function		StoreTimesExpandAndRedim( dummy1, dummy2, nStoreCnt )
//// Set the currently overdimensioned wave to exact size. The following program function 'StoreChunkSet()'  relies on this fact (and additionally we save memory)
//	variable	dummy1, dummy2, nStoreCnt
//	wave	wStoreTimes	= root:stim:wStoreTimes 
//	redimension	/N = ( nStoreCnt, -1 ) wStoreTimes
//End

Function		StoreChunkSet()												// after SetPoints() : needs gnPnts and gPntPerChnk
// Builds  boolean wave containing the information if a given chunk must be stored .  
//  Chunks that need not be stored are not transfered between Host and Ced: Advantages : 1. Script load time is reduced   2. Higher acq data rates are possible
//  To keep the program simple only complete chunks are handled: only when the whole chunkk is blank it will not be transfered. If there is just 1 point to be stored the whole chunk is transfered.
//  This behaviour could (at the expense of a rather large proramming effort) be improved by splitting chunks into Store=Transfer/NoStore=NoTransfer regions..(finer granularity). 

	nvar		gnProts		= root:cont:gnProts
	nvar		gnPnts		= root:cont:gnPnts
	nvar		gPntPerChnk	= root:cont:gPntPerChnk 

	// Construct the boolean wave containing the information if a given chunk must be stored. Assume initially that it has not to be stored.
	make	/O    /W	/N=( gnProts * gnPnts / gPntPerChnk )	root:cont:wStoreChunkOrNot	
	wave	wStoreChunkOrNot = root:cont:wStoreChunkOrNot
	wStoreChunkOrNot		= FALSE									// Assume initially that no chunk has not to be stored, correct this assumption below
	variable	nChunks		= DimSize( wStoreChunkOrNot, 0 )

	// Correct the above assumption if the conditions are met that a given chunk must be stored
	wave	wStoreTimes	= root:stim:wStoreTimes
	variable	nStoreTimes	= DimSize( wStoreTimes, 0 )
	//printf "\t\tStoreChunkSet()   	gnProts: %d  gnPnts: %d  gPntPerChk: %d  -> nChunks: %d    (Initial StoreCnt: %d ) \r", gnProts, gnPnts, gPntPerChnk, nChunks, nStoreTimes
	variable	t, c
	for ( t = 0; t < nStoretimes; t += 1 )
		variable	nEarlyOn	= trunc(  wStoreTimes[ t ][ 0 ] 	/ gPntPerChnk )		// indexing is such that the usual loop construct can be used...
		variable	nLateOff	= trunc( (wStoreTimes[ t ][ 1 ] - 1)	/ gPntPerChnk ) + 1	// e.g. from EarlyOn  to < LateOff     or   from LateOff   to  < EarlyOn
		//printf "\t\t\tStoreChunkSet()  \tTimes \tt:\t%7d\tBg:\t%7d\tNd:\t%7d\tnEarlyOn:\t%7d\tnLateOff:\t%7d    \r", t , wStoreTimes[ t ][ 0 ], wStoreTimes[ t ][ 1 ] , nEarlyOn, nLateOff 		
		for ( c = nEarlyOn; c < nLateOff; c += 1 )
			wStoreChunkOrNot[ c ] = TRUE
		endfor 
	endfor 
	for ( c = 0; c < nChunks; c += 1 )
		//printf "\t\t\tStoreChunkSet()  \tChunks \tc:\t%7d\tStoreIt:\t%7d\t  \r", c , wStoreChunkOrNot[ c ] 
	endfor 
End

Function		StoreChunkOrNotOrNot( nChunk )				
	variable	nChunk
	wave	wStoreChunkOrNot = root:cont:wStoreChunkOrNot
	return	wStoreChunkOrNot[ nChunk ]
End
	

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// 030612
Function		CEDInit1401DACADC( mode )
	variable	mode
	variable	hnd, nType, nSize, code
	string		sBuf

	hnd		= xCEDGetHandle();

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
	nType	= xCEDTypeOf( mode )							// the  XOP prints the type
	if ( mode & MSGLINE )
		printf "\t\tCed CEDInit1401DACADC()  checking memory size  \t\t\t\t\t\t\t : "
	endif
	nSize	= xCEDGetUserMemSize( mode )					// the  XOP prints the memory value 
	if (  nType  == 1 )   										// only 1=1401plus needs the MEMTOP,E command.  2=1401micro and  3=1401power (but not 0=1401standard..)

		CEDSendStringCheckErrors( "MEMTOP,E;" , 0 ) 
//		xCEDSendString( "MEMTOP,E;" ) 
//xCedLastErrCode( "MEMTOP,E;" )
		if ( mode & MSGLINE )
			printf "\t\tCed CEDInit1401DACADC()  checking memory size   after \tsending 'MEMTOP,E;'  : "
		endif
		nSize = xCEDGetUserMemSize( mode )					// the  XOP prints the memory value 
	endif

	// load these commands, 'KILL' (when loaded first) actually unloads all commands before reloading them to free occupied memory (recommendation of Tim Bergel, 2000 and 2003)
	string		sCmdDir	= "c:\\1401\\"
	string		sCmds	= "KILL,MEMDAC,ADCMEM,ADCBST,DIGTIM,SM2,SN2,SS2"	// the  Test/error led  should not flash unless commands are overwritten (which cannot occur bcause of 'KILL' above)
	code		= xCEDLdErrOut( mode, sCmdDir, sCmds )
	if ( code  ||  ( mode & MSGLINE ) )
		printf "\t\tCed CEDInit1401DACADC()  loading commands  '%s'  '%s' \treturns code:%d \r", sCmdDir, sCmds, code
	endif 
	if ( code )
		return	code
	endif

	// to be sure, occasionally there were some problems with strange values on DACs 
	sBuf		= "DAC,0 1 2 3,0 0 0 0;" 
	code		= CEDSendStringCheckErrors( sBuf , 0 ) 
//	xCEDSendString( sBuf ) 
	if ( code  ||  ( mode & MSGLINE ) )
		printf "\t\tCed CEDInit1401DACADC()  sending %s \treturns code:%d \r", pd( sBuf,18), code
	endif
	if ( code )
		return	code
	endif

//	code		= CedSetEvent( mode )
	return	code
End


Function		CedSetEvent( mode )
	variable	mode
	nvar		gRadTrigMode	= root:cont:gRadTrigMode
	variable	code			= 0
	variable	nType		= xCEDTypeOf( mode )							// the  XOP prints the type
	string		sBuf

	// sBuf		= "EVENT,P,63;"						// 63 : set polarity of events 0 ...5 to  low active  (normal setting)
	// code		+= CEDSendStringCheckErrors( sBuf, 1 ) 
	if ( gRadTrigMode == 0  ) 								// normal SW triggered mode,  see p.48, 53 of the 1995 family programming manual for an example how to handle dig outputs and events 
		sBuf		= "DIGTIM,OB;"						// use  'B'oth  digital outputs and internal events
//		xCEDSendString( sBuf ) 
		code		+= CEDSendStringCheckErrors( sBuf , 0 ) //1 ) 
		sBuf		= "EVENT,D,28;"						// 'D'isable external events 2, 3 and 4;   4 + 8 + 16 = 28  i.e. trigger only on internal clock, but not on external signal on E input
		//xCEDSendString( sBuf ) 
		code		+= CEDSendStringCheckErrors( sBuf, 0 )//1 ) 
	endif	

	if ( gRadTrigMode == 1 ) 								// HW E3E4 triggered mode
		printf "\t\tIn this mode a  low-going TTL edge on  Events 2,3,4 (1401plus)  or on Trigger input (Power1401)  will trigger stimulus and acquisition. \r" 
		sBuf		= "DIGTIM,OD;"						// use  only 'D'igital outputs, do not trigger on internal events
		//xCEDSendString( sBuf ) 
		code		+= CEDSendStringCheckErrors( sBuf , 0 )//1 ) 
		if (  nType  == 2  ||  nType == 3 )  					// only   2=1401micro and  3=1401power (but not 0=1401standard or 1=1401plus)  need this linking command
			sBuf = "EVENT,T,28;"						// Power1401 requires explicit linking of E2, E3 and E4 to the front panel 'Trigger' input
		//xCEDSendString( sBuf ) 
		code		+= CEDSendStringCheckErrors( sBuf, 0 )//1 ) 
		endif
	endif	
	return	code
End


Static Function  ArmClockStart( SmpInt, nTrigMode )
	variable	SmpInt, nTrigMode 
	string		buf , bf 
	string		sMode	= SelectString( nTrigMode , "C", "CG" )	// start stimulus/acquisition right now or wait for low pulse on E2 in HW triggered E3E4 mode 
	variable	rnPre1, rnPre2								// changed in function
	if (  CEDHandleIsOpen() )
		variable	nrep	= 1								// the true number of repetitions is set in ArmDig()
		if ( SplitIntoFactors( SmpInt, rnPre1, rnPre2 ) )
			return	cERROR							// 031126
		endif
		// divide 1MHz clock by two factors to get basic clock period in us, set clock (with same clock rate as DAC and ADC)  and  start DigOut, DAC and  ADC  OR  wait for low pulse 
		sprintf buf, "DIGTIM,%s,%d,%d,%d;", sMode, rnPre1, rnPre2, nrep
		sprintf  bf,  "\t\tCed ArmClockStart sends  '%s'  \r", buf; Out1( bf, 0 )
		// 031124 PROBLEM:  EVEN IF too ambitious sample rates are attempted the CED will  FIRST  start  the stimulus/acquisition and  THEN LATER  return an error code and an error dialog box.
		// -> starting the stimulus/acquisition cannot be avoided  no matter whether the user acknowledges the error dialog box or not  leading almost inevitably to corrupted data.
		// -> TODO   the stimulus/acquisition should NOT start in the error case .    STOPADDA   BEFORE   the error dialog opens.... 
		if ( CEDSendStringCheckErrors( buf, 0 ) ) 
			return	cERROR						// 031016
		endif
	endif
	return	0
End


Static Function  ArmDAC( BufStart, BufPts, nrep )
	variable	BufStart, BufPts, nrep
	string		buf, bf
	nvar		gnSmpInt	= root:cont:gnSmpInt
	nvar		gnCntDA	= root:cont:gnCntDA
	variable	rnPre1, rnPre2							// changed in function
	if (  CEDHandleIsOpen() )
		if (  gnCntDA )
			if ( SplitIntoFactors( gnSmpInt, rnPre1, rnPre2 ) )
				return	cERROR							// 031126
			endif
			string		sChans = ChannelList( "Dac", gnCntDA )	//? depends on ordering..
			// Load the DAC with clock setup: 'I'nterrupt mode, 2 byte, from gDACOffset BufSize bytes, 
			// DAC2, nRepeats, 'C'lock 1 MHz/'T'riggered mode, and two factors for clock multiplier 
			// after sending this command to the Ced the DAC will be waiting for a trigger to Event input E3 
			sprintf  buf, "MEMDAC,I,2,%d,%d,%s,%d,CT,%d,%d;", BufStart, BufPts * 2, sChans, nrep, rnPre1, rnPre2
			sprintf  bf,  "\t\tCed ArmDAC() sends  '%s'  \r", buf; Out1( bf, 0 )

			if ( CEDSendStringCheckErrors( buf, 0 ) )			// now DAC is waiting for a trigger to Event input E3 
				return	cERROR					// 031016
			endif

		endif
	endif
	return 0
End


Static Function  ArmADC(  BufStart, BufPts, nrep, listADTG )
	variable	BufStart, BufPts, nrep
	string		listADTG
	string		buf, bf
	nvar		gnSmpInt	= root:cont:gnSmpInt
	variable	rnPre1, rnPre2							// changed in function
	if ( CEDHandleIsOpen() )
		if ( ItemsInList( listADTG, " " ) )
			if ( SplitIntoFactors( gnSmpInt, rnPre1, rnPre2 ) )
				return	cERROR							// 031126
			endif
			// load the ADC  :   using  'ADCBST'  we get 'SmpInt' between each burst  ( using  'ADCMEM' we get 'SmpInt' between each channel and have to adjust it)
			// parameters:  'I'nterrupt mode, 2 byte, from 'gADCOffset' 'BufSize' bytes,  ADC0 ,  1 repeat,  Clock 1 MHz / 'T'riggered mode, and two factors for clock multiplier 
			// after sending this string to the Ced  the ADC will be  waiting for a trigger to Event input E4 
			sprintf buf, "ADCBST,I,2,%d,%d,%s,%d,CT,%d,%d;", BufStart, BufPts * 2, listADTG, nrep, rnPre1, rnPre2
			sprintf  bf, "\t\tCed ArmADC() sends  '%s'  \r",  buf; Out1( bf, 0 )
			if ( CEDSendStringCheckErrors( buf, 0 ) )					// now ADC is waiting for a trigger to Event input E4 
				return	cERROR						
			endif
		endif
	endif
	return 0
End


Function		SplitIntoFactors( nNumber, rnFactor1, rnFactor2 )
	variable	nNumber, &rnFactor1, &rnFactor2 					// changed in function
	string		bf
	rnFactor1	= FindNextDividerBetween( nNumber, 2, min( nNumber / 2, 65535 ) )	// As 2 is the minimum value for ADCBST( 1401plus ) , MEMDAC( 1401plus ) , DIGTIM( 1401plus and Power1401 )...
	rnFactor2	= nNumber / rnFactor1									// ..it makes no sense to handle (theoretically possible) minimum of 1 for ADCBST +  MEMDAC( Power1401 ) separately
	if ( rnFactor1 == NOTFOUND   ||   trunc( rnFactor1 ) * trunc( rnFactor2 )  != nNumber )
		sprintf bf, "Sample interval of %g could not be divided into 2 integer factors between 2 and 65535. ", nNumber 
		Alert( cFATAL, bf )
		return	cERROR							// 031126
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


Function  ArmDig( OffsDO )
	variable	OffsDO
	nvar		gnProts		= root:cont:gnProts
	nvar		gnJumpBack	= root:stim:gnJumpBack
	svar		gsDigoutSlices	= root:stim:gsDigoutSlices
	variable	n, p
	string		sErrorCodes, buf, bf
	if ( CEDHandleIsOpen() )
		variable	nSlices = ItemsInList( gsDigoutSlices )	

		CEDSetAllDigOuts( 0 )												// 031110  Initialize the digital output ports with 0 : set to LOW
		
		// book space for   'nSlices'  (=all slices contained in 'gsDigoutSlices' ) , each slice needs 16 Bytes 
		sprintf  buf, "DIGTIM,S,%d,%d;", OffsDO, BYTES_PER_SLICE * nSlices
		sprintf bf, "\t\tCed ArmDig()   OffsDO:%d,  nSlices:%2d ,  gnProts:%d -> '%s' \r", OffsDO, nSlices, gnProts, buf 
		Out1( bf, 0 ) // 1 )

		if ( CEDSendStringCheckErrors( buf, 0 ) ) //1 ) )		
			return	cERROR						
		endif


		for ( n = 0; n < nSlices - 1 ; n +=1 )						// do not yet send the last slice because we must append the number of repeats 					
			 //printf "\t\tSl:%2d/%2d  %s\t'%s.... \r", n, nSlices, pd( StringFromList( n, gsDigoutSlices ), 18), gsDigoutSlices[0,200] 
			//xCEDSendStringErrOut( ERRLINE+ERR_FROM_CED, StringFromList( n, gsDigoutSlices ) + ";" ) // each slice needs appr. 260 us to be sent 
			CEDSendStringCheckErrors( StringFromList( n, gsDigoutSlices ) + ";" ,  0 ) // 1  ) // each slice needs appr. 260 us to be sent 
		endfor

		string		sLastSlice	= StringFromList( nSlices - 1 , gsDigoutSlices ) +  "," + num2str( -nSlices + gnJumpBack ) + "," + num2str( gnProts )   // 030627 do NOT repeat DAC/DAC-Trigger (skip first 2 slices)
		sprintf bf, "\t\tCed ArmDig()   Prot:%2d/%2d   \tSlice:%2d/%2d  \tLastSlice \tcontaining   jmp and rpt :'%s'    (JumpBack:%d)  \r", p, gnProts, n, nSlices, sLastSlice, gnJumpBack
		Out1( bf , 0 )

		if ( CEDSendStringCheckErrors( sLastSlice  + ";" ,  0 ) ) // 1 ) )	// sends last DIGTIM,A...	
			return	cERROR						
		endif

		sprintf  bf, "\t\tCed ArmDig()   has sent %d  digout slices. Digital transitions OK.\r", nSlices ; Out1( bf, 0 ) //  1)
	//StopTimer( "ArmDig" )
	endif
	return 0
End

Function		CEDSendStringCheckErrors( buf, bPrintIt )
	string		buf
	variable	bPrintIt
	variable	err	= 0
	if ( bPrintIt )
		printf "\tCEDSendStringCheckErrors( %s ) \r", buf 
	endif
	xCEDSendString( buf )
	//err	= xCEDGetResponse( "ERR;" )//, buf, 0 )	// last param is 'ErrMode' : display messages or errors
	err	= xCEDGetResponse( "ERR;", buf, 0 )	// last param is 'ErrMode' : display messages or errors
	if ( err )
		string	   bf
		sprintf  bf,  "err1: %d  err2: %d   after sending   '%s'   (%d) ",  trunc( err / 256 ) , mod( err, 256 ), buf , err 
		Alert( cFATAL,  bf )
		err	= cERROR					
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
static constant	MAXDIGOUT 			 = 2000

//!  THIS  FUNCTION  DETERMINES  THE  ORDER  OF  THE  ENTRIES  IN  THE  SCRIPT
static constant	DOCHA = 0, DODUR = 1, DODEL = 2, DODDUR = 3, DODDEL = 4, DOBEG = 5, DOSIZE = 6	// order of entries in script
  
Function		ProcessDigitalOutputs( nEle )
	variable	nEle
	nvar		nPnts	= root:cont:gnPnts 
	ResetStartTimer( "Digout" )
	DigoutExtractChs( nEle )				
	DigoutExpandFramesIncDec()				
	DigoutMakeDisplayWaves( nPnts )			
	DigoutMakeCEDString( nPnts )				
	StopTimer( "Digout" )
End


Function	/S	InsertAdcDacDigoutTrigger( sDigout )
// This inserts the Adc/Dac-trigger pulse into the stimulus protocol. These are the 'hidden digital events 3 and 4' which trigger the Adc/Dac/Digout pulses
// this is called twice
	string		sDigout
	nvar		nSmpInt		= root:stim:gnSmpInt
	string		sAdcDacDigoutTrigger
	variable	TriggerDuration	= cTIME_DAC_TRIGGER * nSmpInt / MILLITOMICRO
	// Version 1 :  insert only Event 3 and 4 = Adc/Dac-trigger pulse : insert  "4,1/3,1/" 
	sprintf	sAdcDacDigoutTrigger, "%d,%lf/%d,%lf/", 4, TriggerDuration, 3, TriggerDuration		// Assumption:separators  ','  and  '/'
	// Version 2 :  insert Event 3 and 4 and additionally automatic digout 2 pulse  (not very useful, can better be inserted in  script)
	// sAdcDacDigoutTrigger = "4,1/3,1/2,1/"	// insert Event 3 and 4 and additionally automatic digout 2 pulse
	return	sAdcDacDigoutTrigger + sDigout
End


Function  	DigoutExtractChs( nEle )
	variable	nEle 
	nvar		gRadDebgSel	= root:dlg:gRadDebgSel
	nvar		PnDebgDigout	= root:dlg:PnDebgDigout
	string	  /G	root:stim:sDigOutChans
	svar		sDigOutChans	= root:stim:sDigOutChans
	string		bf, sDigOut, sOneChInLine, sCh, sDgoChans	= ""
	variable	c = 0, b, f, e, k, nType, ciDgo, nChansInThisLine, nIdxDGO
	//  Step1: count  and get channel number of all DigOuts from  'wEl', build list of used digout channels 'sDgoChans'
	for ( b  = 0; b < eBlocks(); b += 1 )
		for ( f = 0; f < eFrames( b ); f += 1 )						// loop through all frames above frame 0, whose values are fixed
			for ( e = 0; e < eElems( c, b ); e += 1 )					// loop through all elements (=VarSegm,Segment,Ramp,StimWave..)
				nType = eTyp( c, b, e )
				sDigout	=  vGES( c, b, f, e, "Dig" )

				if ( b==0  &&  f ==0  &&  e == 0 ) 	
					sDigout	= InsertAdcDacDigoutTrigger( sDigout )// This inserts the 'hidden digital events 3 and 4' which trigger the Adc/Dac/Digout pulses
				endif										// they are inserted here erroneously in every sweep: we must later remove all inserts but the last   
	
				if ( numType( str2num( sDigout ) ) != NUMTYPE_NAN )		// Dig subkey was missing in script: skip
	
					nChansInThisLine	= ItemsInList( sDigout, "/" )			//! assumption  separator 
					for ( ciDgo = 0; ciDgo < nChansInThisLine; ciDgo += 1 )
						sOneChInLine	= StringFromList( ciDgo, sDigout, "/" )	//! assumption  separator 
						sCh			= StringFromList( 0,  sOneChInLine, "," )			
						if ( WhichListItem(  sCh, sDgoChans ) == NOTFOUND )
							sDgoChans	= AddListItem( sCh, sDgoChans, ";", Inf )
						endif
						 if ( gRadDebgSel > 1  &&  PnDebgDigout )
							printf  "\t\t\tDigoutExtractChs(1.) \t%-12s\tb:%2d\tf:%2d\te:%2d\tc:%d \tsCh:'%s'     \tsDGOChList:'%s'   \tsDigOut:%s \tsChInLine:'%s' \r", mS( nType ), b, f, e, ciDgo, sCh, sDgoChans, pd(sDigOut,15), sOneChInLine
						 endif
					endfor
				endif
			endfor
		endfor
	endfor
	if ( gRadDebgSel > 1  &&  PnDebgDigout )
		printf "\t\t\tDigoutExtractChs(1.)  has built  sDgoChans:'%s'  containing %d  Digout channels \r", sDgoChans, ItemsInList( sDgoChans )
	endif

	//  Step2: build array 'wDGO'  to hold  digout numbers (needed because inc / dec computations are more easily done in an array than in a string list)
	variable	nDGOChans	= ItemsInList( sDgoChans )
	make	/O 	/N=( nDGOChans, eMaxBFS(),  nEle, DOSIZE ) root:stim:wDGO = Nan	// Nan is marker for non-filled elements
	wave	wDGO		= root:stim:wDGO
	if ( gRadDebgSel > 1  &&  PnDebgDigout )
		printf "\t\t\tExtractDigoutChs(2.)  has built  wDGO[ DGOch:%d ][ maxBFS: %d ][ nEle:%d ][ DGOkeys:%d ] \r",  nDGOChans, eMaxBFS(), nEle, DOSIZE
	endif

	//  Step3: extract numbers of all DigOuts from  'wEl'  and store them in 'wDGO'
	variable	value
	variable	bfsPtr		
	for ( b  = 0; b < eBlocks(); b += 1 )
		for ( f = 0; f < eFrames( b ); f += 1 )						// loop through all frames above frame 0, whose values are fixed
			bfsPtr	= eGetBFSPtr( b, f, 0 )					// only information of sweep 0 is used for construction of the DigOut wave  
			for ( e = 0; e < eElems( c, b ); e += 1 )					// loop through all elements (=VarSegm,Segment,Ramp,StimWave..)
				nType	= eTyp( c, b, e )
				sDigout	=  vGES( c, b, f, e, "Dig" )

				if ( b==0 && f ==0  && e == 0 ) 	
					sDigout	= InsertAdcDacDigoutTrigger( sDigout )// This inserts the 'hidden digital events 3 and 4' which trigger the Adc/Dac/Digout pulses
				endif										// they are inserted here erroneously in every sweep: we must later remove all inserts but the last   
				
				if ( numType( str2num( sDigout ) ) != NUMTYPE_NAN )		// Dig subkey was missing in script: skip
					nChansInThisLine	= ItemsInList( sDigout, "/" )			//! assumption  separator 
					for ( ciDgo = 0; ciDgo < nChansInThisLine; ciDgo += 1 )
						sOneChInLine= StringFromList( ciDgo, sDigout, "/" )	//! assumption  separator 
						sCh		= StringFromList( 0,  sOneChInLine, "," )	// first list item in script is true channel number
						nIdxDGO	= WhichListItem( sCh, sDgoChans )		// the order of channels in channel list determines order in wDGO, first item in wDGO is true chan number 
						for ( k = 0; k < dimSize( wDGO, 3 ); k += 1)
							value	= str2num( StringFromList( k,  sOneChInLine, "," ) )
							if ( k != DOCHA   &&  numtype( value ) == NUMTYPE_NAN )	
								value = 0								// keep Nan as marker for missing channels... 
							endif									// ..but set missing durations and delays to zero
							wDGO[ nIdxDGO ][ bfsPtr ][ e ][ k ]	= value
						endfor
						// check the numbers stored in 'wDGO'
						string		sNumbers = ""
						for ( k = 0; k < dimSize( wDGO, 3 ); k += 1)
							sNumbers += "\t" + num2str( wDGO[ nIdxDGO ][ bfsPtr ][ e ][ k ] )
						endfor
						if ( gRadDebgSel > 1  &&  PnDebgDigout )
							printf  "\t\t\tDigoutExtractChs(3.) \t%-12s\tb:%2d\tf:%2d\tff:%2d\te:%2d\tc:%d \t\tchecking wDGO:'%s' \t\tsChInLine:'%s' \r", mS( nType ), b, f, bfsPtr, e, ciDgo, sNumbers, sOneChInLine 
						endif
					endfor
				endif
			endfor
		endfor
	endfor
	sDigOutChans	= sDgoChans
	if ( gRadDebgSel > 0  &&  PnDebgDigout )
		printf "\t\tDigoutExtractChs(4.)  has built  sDgoChans:'%s'  containing %d  Digout channels \r", sDigOutChans, ItemsInList( sDigOutChans ) 
	endif
End


Function DigoutExpandFramesIncDec()
// Step 6:  take into account the DAmp and DDur entries: increment or decrement frames >= 1
//	only sweep 0 is set, sweeps >= 1 are still empty
	nvar		gRadDebgSel	= root:dlg:gRadDebgSel
	nvar		PnDebgDigout	= root:dlg:PnDebgDigout
	variable	b=0, f=0, e, value, nType 
	if ( gRadDebgSel > 0  &&  PnDebgDigout )
		printf "\t\tDigoutExpandFramesIncDec(10.) \t wE[ nChn:%d  maxBFS:%d , nEle:%d, nKeys:%d]   (maxFrm:%d, maxSwp:%d )\r", eChans(), eMaxBFS(), maxElements(), eKeys(), eMaxFrames(), eMaxSweeps()
	endif

	wave	wDGO		= root:stim:wDGO
	variable	k, c = 0, ciDgo, nDgoChs = dimsize( wDGO, 0 )
	string		sNumbers, sNewNumbers
	for ( ciDgo = 0; ciDgo < nDgoChs; ciDgo += 1)
		// printf "\t\tDigoutExtractChs(11a.) Check inc/dec wDGO  before\tciDgo:%2d   \tchan:%2d  \tdur:%5.3lf \r", ciDgo, wDGO[ ciDgo ][ 0  ][ 0 ][ DOCHA ], wDGO[ ciDgo ][ 0  ][ 0 ][ DODUR ]
		for ( b  = 0; b < eBlocks(); b += 1 )
			for ( f = 0; f < eFrames( b ); f += 1 )			
				variable	bfsPtr	= eGetBFSPtr( b, f, 0 )			// only information of sweep 0 is used for construction of the DigOut wave  
				for ( e = 0; e < eElems( c, b ); e += 1 )					// loop through all elements (=VarSegm,Segment,Ramp,StimWave..)
						// commentize in release version
						// sNumBers = ""
						// sNewNumBers = ""
						// for ( k = 0; k <  dimsize( wDGO, 3 ); k += 1 )
						//	sNumbers += "\t\t" + num2str( wDGO[ ciDgo ][ bfsPtr ][ e ][ k ] )
						// endfor		
					if ( numtype(  wDGO[ ciDgo ][ bfsPtr ][ e ][ DOCHA ] )  !=  NUMTYPE_NAN )							// true channel number 
						wDGO[ ciDgo ][ bfsPtr  ][ e ][ DODEL ]	   = wDGO[ ciDgo ][ bfsPtr ][ e ][ DODEL ]  +  f *  wDGO[ ciDgo ][ bfsPtr ][ e ][ DODDEL ]	// increment Delay
						wDGO[ ciDgo ][ bfsPtr  ][ e ][ DODUR ]  = wDGO[ ciDgo ][ bfsPtr ][ e ][ DODUR ] +  f *  wDGO[ ciDgo ][ bfsPtr ][ e ][ DODDUR ]	// increment Duration
					endif			
						// commentize in release version
						// for ( k = 0; k <  dimsize( wDGO, 3 ); k += 1 )
						//	sNewNumbers += "\t\t" + num2str( wDGO[ ciDgo ][ bfsPtr ][ e ][ k ] )
						// endfor		
						// printf "\t\tCheck inc/dec wDGO  \tciDgo:%2d   \tc:%2d  \tb:%2d  \tf:%2d  \tff:%2d  \te:%2d  \t%s ->\t%s \r", ciDgo, c, b, f, bfsPtr, e, sNumbers, sNewNumbers
				endfor		
			endfor		
		endfor		
		// printf "\t\tDigoutExtractChs(11b.) Check inc/dec wDGO  after \tciDgo:%2d   \tchan:%2d  \tdur:%5.3lf \r", ciDgo, wDGO[ ciDgo ][ 0  ][ 0 ][ DOCHA ], wDGO[ ciDgo ][ 0  ][ 0 ][ DODUR ]
	endfor
End

Function	 	DigoutMakeDisplayWaves( nPnts )
//  build digout display wave,  needs  wEl   and wDGO
//  the control structure of  'DigoutMakeDisplayWaves()'  and  'DigoutMakeCEDString()'  must be the same ensuring that digout pulses are actually constructed exactly as displayed on the screen...
 	variable	nPnts
	nvar		gRadDebgSel	= root:dlg:gRadDebgSel
	nvar		PnDebgDigout	= root:dlg:PnDebgDigout
	svar		sDigOutChans	= root:stim:sDigOutChans
	string		bf, sDgoChans	= sDigOutChans
	nvar		nSmpInt		= root:stim:gnSmpInt
	variable	c, b, f, s, e, BegPt, l, n, nElemCnt = 0
	wave	wDGO		= root:stim:wDGO
	variable	ciDgo, nDgoChs = dimSize( wDGO, 0 )	// or: ItemsInList( sDgoChs )
//	make  /O	/N=( MAXDIGOUT ) wDgoCh, wDgoBeg, wDgoDur						// for Dig wave
	make  /O /I /N=( MAXDIGOUT ) wDgoCh, wDgoBeg, wDgoDur						// 32bit integer for Dig wave

	// Step 1: General  ->  reads 'BegPt'  and completes wDGO:  BegPoint of Digout  is BegPt of  Dac of current line + Digout Delay 
	for ( b  = 0; b < eBlocks(); b += 1 )
		for ( f = 0; f < eFrames( b ); f += 1 )				// loop through all frames..
			variable	bfsPtr	= eGetBFSPtr( b, f, 0 )	// only information of sweep 0 is used for construction of the DigOut wave  
			for ( s = 0; s < eSweeps( b ); s += 1 )			// ..through all sweeps..
				for ( e = 0; e < eElems( c, b ); e += 1 )		// ..through all elements (=Segments, Ramp..)
					BegPt = eV( c, b, f, s, e, cBEG ) 		// here also use sweeps >0, check if the current element has a subkey 'BegPt'...
					if ( numtype( BegPt ) != NUMTYPE_NAN )		//  ..(if this is not checked, empty lines containing no digout information are processed...)	 030513
						for ( ciDgo = 0; ciDgo < nDgoChs; ciDgo += 1)
							variable	nChan	= wDGO[ ciDgo ][ bfsPtr ][ e ][ DOCHA ]
							if ( numtype(  nChan )  !=  NUMTYPE_NAN )									// true channel number 
								variable	nDur	= round( wDGO[ ciDgo ][ bfsPtr ][ e ][ DODUR ] * MILLITOMICRO / nSmpInt )  
								variable	nDel	= round( wDGO[ ciDgo ][ bfsPtr ][ e ][ DODEL  ] * MILLITOMICRO / nSmpInt )  
								variable	nBeg	= BegPt  +  nDel ;  wDGO[ ciDgo ][ bfsPtr ][ e ][ DOBEG ] =  nBeg 	// BegPoint of Digout  is BegPt of  Dac of current line + Digout Delay

								// Event 3 and 4 trigger the Adc / Dac : Pass the automatic (=InsertAdcDacDigoutTrigger)  pulse only once in 1.bl, 1.fr, 1.sweep (e==0, must be in 1.line) . 
								if ( ( nChan == 3  ||  nChan == 4 )   &&   ( b == 0  &&  f == 0  &&  s == 0  &&  e == 0 )  )
									nElemCnt = FillDigDispArrays( "AutoTrig", nElemCnt, nChan, nBeg-cTIME_DAC_TO_DIGOUT, nDur, b, f, s, bfsPtr, e, BegPt, nDel, nPnts )  
								// Event 3 and 4 trigger the Adc / Dac : Pass user pulses in chan 3 and 4 ((e>0, not in 1. line) in every block, frame, sweep
								elseif ( ( nChan == 3  ||  nChan == 4 )   &&     e > 0   )	
									nElemCnt = FillDigDispArrays( "UserTrig", nElemCnt, nChan, nBeg, nDur, b, f, s, bfsPtr, e, BegPt, nDel, nPnts )  
								// Pass all other channels in every block, frame, sweep
								elseif ( ! ( nChan == 3  ||  nChan == 4 ) )									
									nElemCnt  = FillDigDispArrays( "normal  ", nElemCnt,  nChan, nBeg, nDur, b, f, s, bfsPtr, e, BegPt, nDel, nPnts )  
								endif			

							endif			
						endfor			
					endif
				endfor
			endfor
		endfor
	endfor

	if ( nElemCnt >= MAXDIGOUT )
		Alert( cFATAL,  "Too many (" + num2str( nElemCnt ) + ") Digouts used, maximum is " + num2str( MAXDIGOUT ) + " . " )
	endif
	redimension	/N=( nElemCnt ) wDgoCh, wDgoBeg, wDgoDur 			// for  Digout wave for display

	// Step 2: Display Digout wave  ->  sort   channel number, duration  and BegPt  by  BegPt
	sort	 wDgoBeg, wDgoBeg, wDgoCh, wDgoDur 
	for ( n = 0; n < nElemCnt; n += 1)
		if ( gRadDebgSel > 2  &&  PnDebgDigout )
			printf "\t\t\t\tDigoutMakeDisplayWaves(22.) after sorting Beg \tn:%3d/%3d \tch:%3d \tBeg:%7d \tDur:%7d \r", n, nElemCnt,  wDgoCh[ n ], wDgoBeg[ n ], wDgoDur[ n ]  
		endif
	endfor

	// Step 3:  Display Digout wave  ->  fill  digout waves (only for display in stimulus window) 
	for ( ciDgo = 0; ciDgo< nDgoChs; ciDgo += 1)
		if ( gRadDebgSel > 2  &&  PnDebgDigout )
			printf  "\t\t\t\tDigoutMakeDisplayWaves(23.) \tfilling Digout waves (pts excluding trigger duration :%d)...\tsDgoChs:'%s' \r",  nPnts, sDgoChans 
		endif
		make /O /N=(  nPnts )  $( "root:stim:" + DispWaveDgoFull( sDgoChans, ciDgo ) ) =  0	// ..for the display of the digital output
		//display  $( "root:stim:" + DispWaveDgoFull( sDgoChans, ciDgo  ) ) // ..for the display of the digital output	endfor	
	endfor
	for ( n = 0; n < nElemCnt; n += 1)
		for ( ciDgo = 0; ciDgo < nDgoChs; ciDgo += 1)
			wave	wDOFull	= $( "root:stim:" + DispWaveDgoFull( sDgoChans, ciDgo ) )
			variable	nDgoCh		=  str2num( StringFromList( ciDgo, sDgoChans ) ) 
			if ( wDgoCh[ n ] == nDgoCh )
				//printf  "\t\t\t\tDigoutMakeDisplayWaves(24.) \tfilling Digout waves with 'On' : ch:%2d   slice:%2d  from %6.3lf  to %6.3lf  \r",  wDgoCh[ n ] , n, wDgoBeg[ n ],  wDgoBeg[ n ] + wDgoDur[ n ]
				for ( l = wDgoBeg[ n ]; l < wDgoBeg[ n ] + wDgoDur[ n ]; l += 1)
					wDOFull[  l ] = 1
				endfor	
			endif
		endfor	
	endfor	
End	
	

Function	 	DigoutMakeCEDString( nPnts )
//  build  CED-Digout string  'gsDigoutSlices',  needs  wEl   and wDGO
//  the control structure of  'DigoutMakeDisplayWaves()'  and  'DigoutMakeCEDString()'  must be the same ensuring that digout pulses are actually constructed exactly as displayed on the screen...
	variable	nPnts
	nvar		nSmpInt		= root:stim:gnSmpInt
	nvar		gRadDebgSel 	= root:dlg:gRadDebgSel
	nvar		PnDebgDigout	= root:dlg:PnDebgDigout
	variable/G	root:stim:gnJumpBack
	nvar		gnJumpBack	= root:stim:gnJumpBack
	string   /G	root:stim:gsDigoutSlices
	svar		gsDigoutSlices	= root:stim:gsDigoutSlices
	svar 		sDigOutChans	= root:stim:sDigOutChans
	string		bf, sDgoChans	= sDigOutChans
	variable	c = 0, b, f, s, e, BegPt, l, n, nSlices = 0		
	wave	wDGO		= root:stim:wDGO
	variable	ciDgo, nDgoChs = dimSize( wDGO, 0 )	// or: ItemsInList( sDgoChs )
	make  /O /I /N=( MAXDIGOUT ) wDgoTime, wDgoChan, wDgoChange	// integer 32 bit  for Digout CED string

	// Step : CED-DIGTIM-String  ->  The first and last DIGTIM command ( =OuterDIGTIM) need all channels for a proper Set / Reset state
	variable	nAllChans = 0

	// bit 8 and 9 can be used for external triggering,  bit 10 .. 12 are used for internal triggering (events) 
	// Set event  3 and 4 to high for   2  time slices,  then set back to low for same time (2 time slices is shortest pulse allowed by Ced)
	// This is for triggering DAC, ADC, and timer2 

// 031204 weg ?????????????????????????????
//	if ( !CedHandleIsOpen() )
//		xCEDOpen( 0, 0 ) 		// try to open it  independent of its state : open, closed, switched off or on (no messages!)
//	endif

	// Step 1: General  ->  reads 'BegPt'  and completes wDGO:  BegPoint of Digout  is BegPt of  Dac of current line + Digout Delay 
	for ( b  = 0; b < eBlocks(); b += 1 )
		for ( f = 0; f < eFrames( b ); f += 1 )				// loop through all frames..
			variable	bfsPtr  = eGetBFSPtr( b, f, 0 )		// only information of sweep 0 is used for construction of the DigOut wave  
			for ( s = 0; s < eSweeps( b ); s += 1 )			// ..through all sweeps..
				for ( e = 0; e < eElems( c, b ); e += 1 )		// ..through all elements (=Segments, Ramp..)
					BegPt = eV( c, b, f, s, e, cBEG ) 		// here also use sweeps >0, check if the current element has a subkey 'BegPt'...
					if ( numtype(BegPt)  != NUMTYPE_NAN )		//  ..(if this is not checked, empty lines containing no digout information are processed...)  030513
						for ( ciDgo = 0; ciDgo < nDgoChs; ciDgo += 1)
							variable	nChan	= wDGO[ ciDgo ][ bfsPtr ][ e ][ DOCHA ]
							if ( numtype(  nChan )  !=  NUMTYPE_NAN )										// true channel number 
								variable	nDur	= wDGO[ ciDgo ][ bfsPtr ][ e ][ DODUR ] * MILLITOMICRO / nSmpInt  
								variable	nDel	= wDGO[ ciDgo ][ bfsPtr ][ e ][ DODEL  ] * MILLITOMICRO / nSmpInt   
								variable	nBeg	= BegPt  +  nDel ;  wDGO[ ciDgo ][ bfsPtr ][ e ][ DOBEG ] =  nBeg 	// BegPoint of Digout  is BegPt of  Dac of current line + Digout Delay
								// This handles the 'hidden digout events 3 and 4'  which trigger the Adc/Dac/Digout
								//  to compensate for the delay until the digital output pulse is actually output  all slices except for the first are shifted 'cTIME_DAC_TO_DIGOUT' slices to later times
								// the criterion ' b == 0  &&  f == 0  &&  s == 0  &&  e == 0'  is not exactly what we want: we mean the hidden event but also act on user programmed events in the same (1.) line
								// -> the user MUST NOT program pulses on channel 3 or 4 in the first line, but must use the second line and a negative delay instead
								// Event 3 and 4 trigger the Adc / Dac : Pass the automatic (=InsertAdcDacDigoutTrigger)  pulse only once in 1.bl, 1.fr, 1.sweep (e==0, must be in 1.line) . 
								if ( ( nChan == 3  ||  nChan == 4 )   &&   ( b == 0  &&  f == 0  &&  s == 0  &&  e == 0 )  )
									nSlices  = FillDigTimArrays( "AutoTrig", nSlices, nChan, nBeg, nDur, b, f, s, bfsPtr, e, BegPt, nDel, nPnts )  
								// Event 3 and 4 trigger the Adc / Dac : Pass user pulses in chan 3 and 4 ((e>0, not in 1. line) in every block, frame, sweep
								elseif ( ( nChan == 3  ||  nChan == 4 )   &&     e > 0   )	
									nSlices  = FillDigTimArrays( "UserTrig", nSlices, nChan, nBeg + cTIME_DAC_TO_DIGOUT, nDur, b, f, s, bfsPtr, e, BegPt, nDel, nPnts )  
								elseif ( ! ( nChan == 3  ||  nChan == 4 ) )									// Pass all other channels in every block, frame, sweep
									nSlices  = FillDigTimArrays( "normal   ", nSlices, nChan, nBeg + cTIME_DAC_TO_DIGOUT, nDur, b, f, s, bfsPtr, e, BegPt, nDel, nPnts )  
								endif			
							endif			
						endfor			
					endif
				endfor
			endfor
		endfor
	endfor

	// the last interval from end of last digout pulse to end of last sweep of last frame 
	wDgoTime[ nSlices ]	= nPnts		
	wDgoChan[ nSlices ]	= nAllChans
	nSlices += 1

	if ( nSlices >= MAXDIGOUT )
		Alert( cFATAL,  "Too many (" + num2str( nSlices ) + ") Digouts used, maximum is " + num2str( MAXDIGOUT ) + " . " )
	endif
	redimension	/N=( nSlices ) wDgoTime, wDgoChan, wDgoChange 		// for CED DIGTIM string

	// Step : CED-DIGTIM-String  ->  sort  wDgoChange(=channel number + changing state)  and wDgoTime (=Beg or end)  by   wDgoTime
	sort	 wDgoTime, wDgoTime, wDgoChan, wDgoChange 
	for ( n = 0; n < nSlices; n += 1)
		if ( gRadDebgSel > 2  &&  PnDebgDigout )
			printf "\t\t\t\tDigoutMakeCEDString(34.) after sorting Time (=Beg or End) \t n:%3d/%3d \tTime:%7d \tChan:%7d \tChange:%7d \r", n, nSlices,  wDgoTime[ n ], wDgoChan[ n ], wDgoChange[ n ] 
		endif
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
			if ( gRadDebgSel > 2  &&  PnDebgDigout )
				printf "\t\t\t\tDigoutMakeCEDString(35.)  combining identical times     \t\t n:%3d,%3d   \tTime:%7d \tChan:%7d \tChange:%7d \r", n-1, n,  wDgoTime[ n-1 ], wDgoChan[ n-1 ] , wDgoChange[ n-1 ] 
			endif
			nSlices -= 1
			n = 0
			continue
		else
			if ( gRadDebgSel > 2  &&  PnDebgDigout )
				 printf "\t\t\t\tDigoutMakeCEDString(36.)     normal checking                 \t n:%3d/%3d \tTime:%7d  \t( is != %7d   or  n == 0 )\r", n, nSlices,  wDgoTime[ n ], wDgoTime[ n - 1 ]
			endif
		endif
	endfor
	nSlices	-= 1				// up till now we actually counted times (which is 1 more than slices) , from now on we count the real slices


	// Step : CED-DIGTIM-String  ->  CONSTRUCT  IT
	variable	nDgoTime	= 0
	string		sDgoDIGTIM	= "", 	sDgoSlices = ""

	// set digital outputs specified  	
	sDgoDIGTIM = ""
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
	//printf  "\t\t\t\tDigoutMakeCEDString(37.) get info for last slice\t n:%3d/%3d \tChange[ 1 ] :%d ->gnJumpBack:%d \tCorrectionForMultipleProts:%d \r", n, nSlices,  wDgoChange[ 1 ], gnJumpBack, CorrectionForMultipleProts

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

		sDgoSlices 	+= BuildSlice( sText, wDgoChan[ n ], wDgoChange[ n ],  nDgoTime, wDgoTime[ n ] * nSmpInt / MILLITOMICRO )

		// Compensate for missing initialization time when multiple protocols are output by APPENDING a time slice with level 0
		// See above: Do NOT simply prolong the last slice, this would erroneously lengthen a pulse which is possibly still on :  Leading to timing errors
		// 	Disadvantage: a slice length of  1 of the last slice having level 0  (which in this special could be prolonged to 3 ) leads to 'severe error' and cannot be executed
		if ( n == nSlices  &&  CorrectionForMultipleProts )
			if ( 1 )	// ! prolong = append
				sText		= "APPEND after last"
				sDgoSlices	+= BuildSlice( sText, wDgoChan[ n ], 0,  CorrectionForMultipleProts, wDgoTime[ n ] * nSmpInt / MILLITOMICRO )
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

	//printf  "\t\tDigoutMakeCEDString(40.) slices:%d  strlen:%4d ) '%s...' \r", nSlices, strlen( sDgoSlices ), sDgoSlices[0,212] 
	if ( gRadDebgSel > 0  &&  PnDebgDigout )
		printf  "\t\tDigoutMakeCEDString(40.) slices:%d  strlen:%4d ) '%s...' \r", nSlices, strlen( sDgoSlices ), sDgoSlices[0,212] 
	endif

	KillWaves wDgoCh, wDgoBeg, wDgoDur, wDgoTime, wDgoChan, wDgoChange

	// now digital outputs are waiting for a trigger to Event input E2 

End


Function		FillDigDispArrays( sText, nElemCnt, nChan, nBeg, nDur, b, f, s, bfsPtr, e, BegPt, nDel, nPnts )  
	string		sText
	variable	nElemCnt, nChan, nBeg, nDur, b, f, s, bfsPtr, e, BegPt, nDel, nPnts
	string		bf
	nvar		nSmpInt		= root:stim:gnSmpInt
	nvar		gRadDebgSel 	= root:dlg:gRadDebgSel
	nvar		PnDebgDigout	= root:dlg:PnDebgDigout
	wave	wDgoBeg, wDgoDur, wDgoCh
	
	wDgoBeg[ nElemCnt ]		= round ( nBeg )
	wDgoDur[ nElemCnt ]			= nDur   
	wDgoCh[ nElemCnt ]			= nChan
	if ( gRadDebgSel > 2  &&  PnDebgDigout )
		printf "\t\t\t\tDigoutMakeDisplayWaves(21.)  %s \tel:%2d  \tf:%d\ts:%d\tff:%d\te:%d\tch:%d\tBegPt:\t%8d\tDgoDel:%5d\t -> DgoBegPt:\t%8d \tDgoDur:%5d \r", sText, nElemCnt, f, s, bfsPtr, e, nChan, BegPt , nDel, nBeg, nDur 
	endif
	// 0300702
	if ( nBeg < -1  )	
		Alert( cSEVERE, "Digital Out pulse (ch:" + num2str( wDgoCh[ nElemCnt ] ) + ") cannot start at times more negative than 1 time slice (= sample interval) . Must start at  -" + num2str( nSmpInt ) + " us or later. (Starts at " + num2str( nBeg ) + " time slices)" )
	endif
	if ( nBeg == -1 &&  !( nChan == 3  ||  nChan == 4 ) )	// do not complain about Events 3 and 4 which always start at time zero - 1 sample interval
		Alert( cIMPORTANT, "Digital Out pulse (ch:" + num2str( wDgoCh[ nElemCnt ] ) + ") starting at -" + num2str( nSmpInt ) + " us will only be output in the 1. protocol") 
	endif
	nElemCnt += 1
	return	nElemCnt
End	


Function		FillDigTimArrays( sText, nSlices, nChan, nBeg, nDur, b, f, s, bfsPtr, e, BegPt, nDel, nPnts )  
	string		sText
	variable	nSlices, nChan, nBeg, nDur, b, f, s, bfsPtr, e, BegPt, nDel, nPnts
	string		bf
	nvar		nSmpInt		= root:stim:gnSmpInt
	nvar		gRadDebgSel 	= root:dlg:gRadDebgSel
	nvar		PnDebgDigout	= root:dlg:PnDebgDigout
	wave	wDgoTime, wDgoChan, wDgoChange
	
	wDgoTime[ nSlices ]		=  round( nBeg ) 						// not rounding here produces sporadically very ugly errors
	wDgoTime[ nSlices + 1 ]	=  round( nBeg + nDur )					//..   
	wDgoChange[ nSlices ]	=  2 ^ nChan
	wDgoChange[ nSlices + 1 ]	=  0
	wDgoChan[ nSlices ]		=  2 ^ nChan
	wDgoChan[ nSlices + 1 ]	=  2 ^ nChan
	//printf "\t\t\t\tDigoutMakeCEDString(31.)  %s\tsl:%2d  \tf:%d\ts:%d\tff:%d\te:%d\tch:%d\tBegPt:\t%8d\tDel:%5d\t -> Beg:\t%8d \tDur:%5d\t-> %5d ..%5d \r", sText, nSlices, f, s, bfsPtr, e, nChan, BegPt , nDel , nBeg, nDur, wDgoTime[ nSlices ], wDgoTime[ nSlices+1 ]
	if ( gRadDebgSel > 2  &&  PnDebgDigout )
		printf "\t\t\t\tDigoutMakeCEDString(31.)  %s\tsl:%2d  \tf:%d\ts:%d\tff:%d\te:%d\tch:%d\tBegPt:\t%8d\tDel:%5d\t -> Beg:\t%8d \tDur:%5d\t-> %5d ..%5d \r", sText, nSlices, f, s, bfsPtr, e, nChan, BegPt , nDel , nBeg, nDur, wDgoTime[ nSlices ], wDgoTime[ nSlices+1 ]
	endif
	if ( wDgoTime[ nSlices + 1 ] >   nPnts  )	// 030707	 (the more stringent condition >= does not seem to be necessary....)
		sprintf bf, "Digital output pulse close to or extending over end of stimulus. (%d>%d) ", wDgoTime[ nSlices + 1 ] , nPnts 
		Alert( cIMPORTANT, bf )
	endif
	nSlices += 2
	return	nSlices
End	


Function	/S	BuildSlice( sText, nChan, nChange,  nDuration, nAbsoluteTime )
	string		sText
	variable	nChan, nChange,  nDuration, nAbsoluteTime 
	nvar		gRadDebgSel 	= root:dlg:gRadDebgSel
	nvar		PnDebgDigout	= root:dlg:PnDebgDigout
	string		sDgoDIGTIM, bf

		if ( nDuration  < cCEDMAXSLICELEN + 2 )					// cCEDMAXSLICELEN is small enough to allow for the extra 2 slices (required as minimum by 1401 hardware)
			sprintf sDgoDIGTIM, "DIGTIM,A,%d,%d,%d;", nChan, nChange, nDuration
			if  ( nDuration < 2 )								// maybe this error could and should be caught earlier...
				sprintf bf, "Digital output pulse conflict at %.2lf ms resulting in time slices < 2 sample intervals which the Ced1401 cannot process.  (Ch:%d, change to:%d, dur:%d) ", nAbsoluteTime, nChan, nChange,  nDuration 
				Alert( cSEVERE, bf )
			endif
		else												// Break a slice which is longer than 65532 sample intervals into shorter slices and catenate them
			variable	SmallEnoughSlice, Repeats, Rest, jmp = 0
			FactorizeSlice( nDuration, SmallEnoughSlice, Repeats, Rest )	// always returns a rest >= 2 which is required by the CED
			// loop 'Repeats' times the maximum SI cnt (=65532) with the previous value (=no change), then just once the rest SI cnt with the changes
			sprintf sDgoDIGTIM, "DIGTIM,A,%d,%d,%d,%d,%d;DIGTIM,A,%d,%d,%d;", 0 , 0 ,  SmallEnoughSlice, jmp, Repeats, nChan,  nChange,  Rest	
		endif									// side effect : nSlices is  increased 1 one more than expected but we must NOT increase it here explicitly

		if ( gRadDebgSel > 1  &&  PnDebgDigout )
			printf  "\t\t\tDigoutMakeCEDString(38.) %s\t%s \tDur:%7d\t(fact. with max = %d ) -> %3d x %3d  +  %3d \t\r",  pad( sText,16), pd(sDgoDIGTIM,36), nDuration, cCEDMAXSLICELEN, Repeats, SmallEnoughSlice, Rest
		endif
		//printf  "\t\t\tDigoutMakeCEDString(38.) %s\t%s \tDur:%7d\t(fact. with max = %d ) -> %3d x %3d  +  %3d \t\r",  pad( sText,16), pd(sDgoDIGTIM,36), nDuration, cCEDMAXSLICELEN, Repeats, SmallEnoughSlice, Rest

		return	sDgoDIGTIM
End


Function		FactorizeSlice( nDgoTime, SmallEnoughSlice, Repeats, Rest )
	variable	nDgoTime
	variable	&SmallEnoughSlice, &Repeats, &Rest
	nDgoTime			-= 2		// ensure that the last slice returned  has at least 2 sample intervals as required by the CED
	Repeats			= trunc ( nDgoTime / cCEDMAXSLICELEN )
	SmallEnoughSlice	= cCEDMAXSLICELEN
	Rest				= nDgoTime -  Repeats * SmallEnoughSlice + 2
	//printf "\t\tFactorizeSlice( %d with max = %d ) -> %d x %d  +  %d \r", nDgoTime+2, cCEDMAXSLICELEN, Repeats, SmallEnoughSlice, Rest
End
	

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// LITTLE HELPERS

Function  /S ChannelList( sIO, nChs )
	string		sIO			// 'Adc' or 'Dac'
	variable	nChs
	variable	c
	string		bf, sChans = ""
	for ( c = 0; c < nChs;  c += 1 )
		sChans += " "
		sChans += num2str( iov1( ioT( sIO ), c, cIOCHAN ) )
	endfor
	//printf   "\t\tCed Channellist for %d '%s' channels '%s' \r", nChs, sIO, sChans
	sprintf  bf, "\t\tCed Channellist for %d '%s' channels '%s' \r", nChs, sIO, sChans ; Out( bf )
	return 	sChans
End

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function		LaggingTime()
// returns how much longer than predicted the script will take due to too much data that are to be displayed (0 is ideal, value in %)
 	nvar		gSwpsWritten		= root:cfs:gSwpsWritten
	nvar		gTotalSweeps		= root:stim:gTotalSweeps
	nvar		gTotalStimMicroSc	= root:stim:gTotalStimMicroSc
//	return	100 * ( gTotalSweeps / gSwpsWritten * TimeElapsed() / gTotalStimMicroSc * 1e6  - 1  )	// in % of total predicted time
	return	(   TimeElapsed() - gTotalStimMicroSc * gSwpsWritten / gTotalSweeps / 1e6  )			// in seconds
End

static constant			TICKS_PER_SEC		= 60 		// Igor fixed, do not change

Function		TimeElapsed()
	nvar		gbRunning	= root:cont:gbRunning
	nvar		gnStopTicks	= root:cont:gnStopTicks, gnStartTicks	= root:cont:gnStartTicks
	variable	nStopTime 	= gbRunning ? ticks : gnStopTicks  
	return	( nStopTime - gnStartTicks ) / TICKS_PER_SEC		 // returns seconds elapsed since ...
End


Function		GetAndInterpretAcqErrors( sText1, sText2, chunk, nMaxChunks )
	string		sText1, sText2
	variable	chunk, nMaxChunks
	string		errBuf
	variable	code	

// 030805
	string		sErrorCodes	= xCEDGetResponseTwoIntAsString( "ERR;" )
	code		= ExplainCEDError( sErrorCodes, sText1 +" | " +  sText2, chunk, nMaxChunks )
	code		= trunc( code / 256 )			// 030805 use only the first byte of the 2-byte errorcode (only temporarily to be compatible with the code below...) 
	//printf "...( '%s' = '%d  '%d' )\t",  sErrorCodes, str2num( StringFromList( 0, sErrorCodes, " " ) ) , str2num( StringFromList( 1, sErrorCodes, " " ) )


// 030805
//	code		= xCEDGetResponse( "ERR;" , sText1+ " / " + sText2, 0 )			// last param is 'ErrMode' : display messages or errors
//	if ( code == 0 )			// OK , no error
//		return	code
//	elseif ( code < 0 )		// catches  error -8.58e-8  =  0xCCCCCCCC
//		sprintf errBuf, "%s \tis too fast.   \tData will be corrupted.\t[%s\tchunk:%d, err:%d ]", pd(sText1,8), sText2, chunk, code
//		Alert( cSEVERE, errBuf )	//
//	elseif ( code == 16 )		// catches  error 16
//		sprintf errBuf, "%s \tis rather fast.\tData may still be OK.\t[%s\tchunk:%d, err:%d ]",  pd(sText1,8), sText2, chunk, code
//		Alert( cIMPORTANT, errBuf )
//	else
//		sprintf errBuf, "%s \terror...\t[%s\tchunk:%d, err:%d ]",  pd(sText1,8), sText2, chunk, code
//		Alert( cIMPORTANT, errBuf )
//	endif

	return	code
End


Function		ExplainCEDError( sErrorCodes, sCmd, chunk, nMaxChunks )
// prints error codes issued by the CED in a human readable form. See 1401 family programming manual, july 1999, page 17
	string		sCmd, sErrorCodes
	variable	chunk, nMaxChunks
	string		sErrorText
	variable	nErrorLevel	= cSEVERE					// valid for all errors (=mandatory beep)  except 'Clock input overrun', which may occur multiple times..
	variable	er0	= str2num( StringFromList( 0, sErrorCodes, " " ) )	//.. in slightly too fast scripts while often not really being an error (=cIMPORTANT, beep can be turned off) 
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
		nErrorLevel = cIMPORTANT		// beep can be turned off when this error is triggered erroneously (which is unfortunately often the case)
	else
		sErrorText	= "Could not interpret this error :" + sErrorCodes + "   [" + sCmd  + "]"
	endif
	sErrorText = sErrorText + "  err:'" + sErrorCodes + "'  in chunk " + num2str( chunk )	 +  " / " + num2str( nMaxChunks )	// 030805
	Alert( nErrorLevel, sErrorText[0,220] )
	return	er0 * 256 + er1							// 030805  build and return  1  16 bit number from the 2 bytes 

End

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  1401  TEST  FUNCTIONS

Function		Test1401Dlg()
	ConstructOrDisplayPanel(  "PnTestCed1401" )
End

Window		PnTestCed1401()
	PauseUpdate; Silent 1							// building window...
	string	sFolderPnText = "root:dlg:tPnT1401"
	InitTest1401Dlg( sFolderPnText )					// initialize the panel controls 'tPnT1401'
	variable	XSize = PnXsize( $sFolderPnText ) 
	variable	XLoc	= GetIgorAppPixel( "X" ) - XSize - 100
	variable 	YLoc	= 140						// Panel location in pixel from upper side
	DrawPanel( $sFolderPnText, XSize,  XLoc, YLoc, "Ced1401" )	
EndMacro
 
 
Function		InitTest1401Dlg( sFolderPnText )
	string	sFolderPnText
	variable	n = -1, nItems = 20
	make /O /T /N=(nItems)	$sFolderPnText
	wave  /T	tPn		= 	$sFolderPnText
	//				TYPE	;   FLEN;FORM;LIM	;PRC;  	NAM					; TXT		// when Xxx is element=variable name, this element needs...
	n += 1;	tPn[ n ] =	"PN_BUTTON;	CurrentHandle		;Current handle"		
	n += 1;	tPn[ n ] =	"PN_BUTTON;	Open1401			;Open 1401"			
	n += 1;	tPn[ n ] =	"PN_BUTTON; Reset1401			;Reset 1401"			
	n += 1;	tPn[ n ] =	"PN_BUTTON;	Close1401			;Close 1401"			
	n += 1;	tPn[ n ] =	"PN_BUTTON;	Type1401			;Type of 1401"			
	n += 1;	tPn[ n ] =	"PN_BUTTON;	Memory1401		;Memory of 1401"		
	n += 1;	tPn[ n ] =	"PN_BUTTON;	Status1401		;Status of 1401"		
	n += 1;	tPn[ n ] =	"PN_BUTTON;	Properties1401		;Properties of 1401"	
	n += 1;	tPn[ n ] =	"PN_BUTTON;	ResetDacs		;Reset Dacs"
	n += 1;	tPn[ n ] =	"PN_BUTTON;	SetDigOut			;Set digital outputs"
	n += 1;	tPn[ n ] =	"PN_BUTTON;	ResetDigOut		;Reset digital outputs"
	redimension  /N = (n+1)	tPn
End


Function		CurrentHandle( ctrlName ) : ButtonControl
	string		ctrlName
	printf "\tTest1401   Current   NEW  handle is %d \r", xCEDGetHandle()
End

Function		Open1401( ctrlName ) : ButtonControl
	string		ctrlName
	xCEDOpen( 0, MSGLINE_C )
End

Function		Reset1401( ctrlName ) : ButtonControl
	string		ctrlName
	xCEDReset( MSGLINE_C )
End

Function		Close1401( ctrlName ) : ButtonControl
	string		ctrlName
	xCEDClose( MSGLINE_C )
End

Function		Type1401( ctrlName ) : ButtonControl
	string		ctrlName
	variable	nType = xCEDTypeOf( MSGLINE_C )
End

Function		Memory1401( ctrlName ) : ButtonControl
	string		ctrlName
	variable	nType, nSize
	printf "\tChecking memory size  before\tsending 'MEMTOP,E;'  : "
	nSize	= xCEDGetUserMemSize( MSGLINE_C )			// the  XOP prints the memory value 
	nType	= xCEDTypeOf( MSGLINE_C )
//	if ( 1 <= nType  && nType <=3 )   							// 1=1401plus, 2=1401micro and  3=1401power (but not 0=1401standard..)
	if ( 1 == nType  )   									// only  1=1401plus needs 'MEMTOP,E;' command ,  2=1401micro and  3=1401power (but not 0=1401standard..)
		CEDSendStringCheckErrors(  "MEMTOP,E;" , 0 ) // 1 ) 
		printf "\tChecking memory size   after \tsending 'MEMTOP,E;'  : "
		nSize = xCEDGetUserMemSize( MSGLINE_C )			// the  XOP prints the memory value 
	endif
End

Function		Status1401( ctrlName ) : ButtonControl
	string		ctrlName
	PrintCEDStatus( 0 )					// 0 disables the printing of 1401 type and memory 
End

Function		Properties1401( ctrlName ) : ButtonControl
	string		ctrlName
	PrintCEDStatus( MSGLINE_C )			// MSGLINE_C enables the printing of 1401 type and memory 
End
 
Function		ResetDacs( ctrlName ) : ButtonControl
	string		ctrlName
	CEDSendStringCheckErrors(  "DAC,0 1 2 3,0 0 0 0;" , 1  ) 
End
 
Function		SetDigOut( ctrlName ) : ButtonControl
	string		ctrlName
	CEDSetAllDigOuts(1 )					// 031110  Initialize the digital output ports with 1 : set to HIGH
End

Function		ResetDigOut( ctrlName ) : ButtonControl
	string		ctrlName
	CEDSetAllDigOuts( 0 )				// 031110  Initialize the digital output ports with 0 : set to LOW
End
 
Function		CEDSetAllDigOuts( value )
	// 031110  Initialize the digital output ports with 0 : set to LOW
	variable	value 
	variable	nDigoutBit
	string		buf
	for ( nDigoutBit = 8; nDigoutBit <= 15; nDigoutBit += 1 )
		sprintf  buf, "DIG,O,%d,%d;", value, nDigoutBit
		CEDSendStringCheckErrors( buf , 0 ) 
	endfor
End


Function	   	PrintCEDStatus( ErrShow )
// prints current CED status (missing or off, present, open=in use) and also (depending on 'ErrShow') the type and memory size of the 1401 
//! There is some confusion regarding the validity of CED handles  (CED Bug? ) : 
//  The manual says that positive values returned from 'CEDOpen()' are valid handles (at least numbers from 0..3, although only 0 is used presently)...
// ..but actually the only valid handle number ever returned is 0. Handle 5 (sometimes 6?) is returned after the following actions (misuse but nevertheless possible) : 
// 1401 is switched on and open, 1401 is switched off, 1401 is switched on again, 1401 is opened -> hnd 5 is returned indicating OK but 1401 is NOT OK and NOT OPEN. . 
// This erroneous 'state 5' must be stored somewhere in the host as it is cleared by restarting the IGOR program  OR by  closing the 1401  with hnd=0 before attempting to open it.
// Presently the XOPs CedOpen etc. do not process the 'switched off positive handle state' separately but handle it just like the closed state of the 1401.
 	variable	ErrShow
 	string	sText
	variable	bCEDWasClosed, nHndAfter, nHndBefore = xCEDGetHandle()
	if ( CEDHandleIsOpen() )				
		bCEDWasClosed = FALSE
		sText = "1401 should be open  (old hnd:" + num2str( nHndBefore ) + ")"
	else
		bCEDWasClosed = TRUE
		sText = "1401 was closed or off  (old hnd:" + num2str( nHndBefore ) + ")"
	endif
	nHndAfter = xCEDOpen( 0, 0 ) 		// try to open it  independent of its state : open, closed, switched off or on (no messages!)
	if ( CEDHandleIsOpen() )				
		sText += ".... and has been (re)opened  (hnd = " + num2str( nHndAfter )+ ")"
		
		// we get 1401 type and memory size right here in the middle of  CEDGetStatus() because  1401 must be open.. 
		// ..we also print 1401 type and memory right here (before the status line is printed) but we could also disable printing here (ErrShow=0) and print 'nSize' and 'nType' later
		if ( ErrShow )
			printf "\tCEDStatus: "
			variable	nType = xCEDTypeOf( ErrShow )			// ErrShow:  enable / disable  the XOP printing  the message string..
			printf "\tCEDStatus: "
			variable	nSize = xCEDGetUserMemSize( ErrShow )		// ErrShow:  enable / disable  the XOP printing  the message string..
		endif
	else
		sText += ".... but cannot be opened: defective? off?  (new hnd:" + num2str( nHndAfter ) + ")  "// attempt to open  was not successfull..
	endif
	if ( bCEDWasClosed )								// CED was closed at  the beginning so close it again
		xCEDClose( 0 )								// ..so restore previous closed state  (no messages!)
		sText += ".... and has been closed again (hnd = " + num2str( xCEDGetHandle() ) + ")"
	endif
	printf "\tCEDStatus:\t%s \r", sText
End

static constant	CED_NOT_OPEN  	= -1		// using the CED error code (instead of -1) ................................simplifies the code // 120602      -1
//constant		CED_NOT_OPEN  	= -510	// using the CED error code (instead of -1) ..........no..............simplifies the code // 120602      -1

Function		CEDHandleIsOpen()
// only the handle under program control (not the 1401 itself) is checked, if the open 1401 is accidentally turned off this function gives the wrong result 
	return ( xCEDGetHandle()  !=  CED_NOT_OPEN )
End 



