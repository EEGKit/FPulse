//
//  UF_AcqCfsWrite4.ipf 
// 
// CFS file write
//
// Comments:
//
// History:
 
#pragma rtGlobals=1									// Use modern global access method.
	
//#include "UFPE_Constants3"

	static constant		kEQUALSPACED	=  0
	static  constant		kCFS_NOT_OPEN	=  -1

constant bNEWFILEVARS =  1// 2005-02-05    set to 1 after testing   and eliminate.....

	
	Function		CreateGlobalsInFolder_CfsWrite()
	// creates all folder-specific variables. To be used once from CreateGlobals() as the current data folder is changed and not restored
		NewDataFolder  /O  /S root:uf:acq:cfsw
	
		variable	/G	gFileIndex			= -1					// 0..26x26-1..will be converted to AA, AB....ZY, ZZ. and stored in 7. and 8. character of file name
		variable	/G	gCFSHandle		= kCFS_NOT_OPEN		// for writing CFS file
		string		/G	gsXUnitsInCfs		=  "ms"				// Use 'millisecs'  only in Cfs files for compatibility with Pascal version. Use 'seconds'  elsewhere to prevent Igor from  labeling the axis e.g. 'kms'  (KiloMilliSeconds)
	End
	
	
	Function  		InitializeCFSDescriptors( sFo, sScript )
	// Define CFS data descriptor templates DSArray (data section descriptor)  and FileArray (file descriptor)  and reset all values. Must be called before UFPE_CfsCreateFile()
	// Store the script once in the file section.
		string  	sFo, sScript
		variable	i, l
		string  	UFPE_LstDS	= UFPE_LstDS0 + UFPE_LstDS1
		// printf  "\t\t\t InitializeDescriptors()	\r"   
	
		// Set  FILEVAR  file descriptors  -  the  FILEVAR  entries  in   InitializeCFSDescriptors()  and   CFSInitWrFile()  must match !
		UFPE_CfsSetDescriptor( UFPE_kFILEVAR, 0, "Data file from,INT2," +  ksFP_APP_NAME + ",0" )				//  Description, Type, Units, Size 
		UFPE_CfsSetDescriptor( UFPE_kFILEVAR, 1,  GetFileName() + UFPE_ksCFS_EXT + ",LSTR,file,20" )				// obsolete but kept for compatibility with Pascal programs...
		UFPE_CfsSetDescriptor( UFPE_kFILEVAR, 2,  "DataFile,LSTR,Data,20" )							// ...here is the current data file name stored, not above in the descriptor field
	
		UFPE_CfsSetDescriptor( UFPE_kFILEVAR, 3,  "StimFile,LSTR,Stim,30" ) 
		UFPE_CfsSetDescriptor( UFPE_kFILEVAR, 4,  "SwpPerFrm,LSTR,-,20" )	
		UFPE_CfsSetDescriptor( UFPE_kFILEVAR, 5,  "FrmPerProt,LSTR,-,20" )								// this is actually frames per block
		UFPE_CfsSetDescriptor( UFPE_kFILEVAR, 6,  "HasPoN,LSTR,-,20" )	
		UFPE_CfsSetDescriptor( UFPE_kFILEVAR, 7 , "Specific comment,LSTR,," + num2str( UFPE_kMAX_CFS_STRLEN ) )	// usable string length is one shorter
	
		// Store the script once in the file section : reserve space for storing the script lines
// 2009-12-12
//		for ( i = 8; i < SCRIPTBEGIN_IN_CFSHEADER; i += 1 )
		for ( i = 8; i < UFPE_kFV_SCRIPTBEGIN; i += 1 )
			UFPE_CfsSetDescriptor( UFPE_kFILEVAR, i, "Spare,INT2,none,0" )
	   	endfor
	
		variable	nLines
		// 2005-0205	
	if ( ! bNEWFILEVARS )
		nLines	= ItemsInList( sScript, "\r" )		// 1 script line = 1 UFPE_kFILEVAR line :  BAD space usage
		for ( l = 0; l < nLines; l += 1 )	
			i = UFPE_kFV_SCRIPTBEGIN + l
			UFPE_CfsSetDescriptor( UFPE_kFILEVAR, i , "Scriptline" + num2str( l ) + ",LSTR,," + num2str( UFPE_kMAX_CFS_STRLEN ) ) // usable string length is one shorter
	   	endfor
	   	
	else
		nLines	= ceil( strlen( sScript ) / ( UFPE_kMAX_CFS_STRLEN - 1 ) )
		for ( l = 0; l < nLines; l += 1 )	
			i = UFPE_kFV_SCRIPTBEGIN + l
			UFPE_CfsSetDescriptor( UFPE_kFILEVAR, i , "ScriptBlock" + num2str( l ) + ",LSTR,," + num2str( UFPE_kMAX_CFS_STRLEN ) ) // usable string length is one shorter
	   	endfor
	   	
	endif
	
	
		for ( i = UFPE_kFV_SCRIPTBEGIN + nLines; i < UFPE_kMAX_FILEVAR ; i += 1 )
			UFPE_CfsSetDescriptor( UFPE_kFILEVAR, i, "Spare,INT2,none,0" )
	   	endfor
	
		// Set  UFPE_kDSVAR  data section descriptors  -  the  UFPE_kDSVAR  entries  in   InitializeCFSDescriptors()  and  WriteHeader()  must match !  The order is defined in  'UFPE_LstDS' .
		for ( i = 0;  i < ItemsInList( UFPE_LstDS ); i += 1 )
			UFPE_CfsSetDescriptor( UFPE_kDSVAR,  i, StringFromList( i, UFPE_LstDS ) )				//  contains Description, Type, Units, Size 
		endfor
	
		for ( i =   ItemsInList( UFPE_LstDS );  i <  UFPE_kMAX_DSVAR; i += 1 )
			UFPE_CfsSetDescriptor( UFPE_kDSVAR, i, "Spare,INT2,none,0" )	
		endfor
	
	End      
	
// 2009-12-14	
//static	Function		WriteDataSection_ns( sFo, sc, pr, bl, lap, fr, gr, sw, wG, lllstIO, lllstIOTG, lllstBLF, lllstPoN, BegPt, nPtsSv )		// PROTOCOL  AWARE  031007
static	Function		WriteDataSection_ns( sFo, sc, pr, bl, lap, fr, gr, sw, wG, lllstIO, lllstIOTG, lllstBLF, lllstPoN, BegPt, nPtsSv, BegDisp, nPts )		// PROTOCOL  AWARE  031007
// break big waves (one per adc, all frames and sweeps together) into sections for  UFPE_CfsWriteData() (=into single sweeps) )
// Limitation....writes always / only 'Adc' channels
// could probably be done more elegantly...............
	string  	sFo, lllstIO,  lllstIOTG, lllstBLF, lllstPoN
	wave	wG
	variable	sc, pr, bl, lap, fr, gr, sw, BegPt, nPtsSv, BegDisp, nPts
	variable	bWriteMode	= WriteMode()
	nvar		gCFShnd		= root:uf:acq:cfsw:gCFSHandle		
	variable	nSmpInt		= SmpIntDacUs( sFo ) // OR =wG[]    
	variable	nCntAD		= wG[ UFPE_WG_CNTAD ]	

	svar		lllstTapeTimes	= $"root:uf:" + sFo + ":" + "lllstTapeTimes" 	
	svar		llstBLF		= $"root:uf:" + sFo + ":" + "llstBLF" 	
	svar		lstTotdur		= $"root:uf:" + sFo + ":" + "lstTotdur" 	
	svar		llstNewdsTimes	= $"root:uf:" + sFo + ":" + "llstNewdsTimes" 
	variable 	bExpLaps = 1, bTrueTime = 1,  BegDispTT = 0,  BegPtTT = 0

// 2009-12-14	
//	variable	BegDisp, tp = 0
	variable	eb			=  ELIMINATE_BLANKS()

	variable	OldHnd		= gCFSHnd				// for debug printing
	variable	cio, nio		= kSC_ADC	

	// STEP 1 :
	// Get the telegraph gain by reading the big wave and store the values in  wave 'lllstIO' , from which they can be retrieved with  'kSC_IO_GAINOLD'   and   ' YScale(cio) '
	// Note: to save processing time this is done only once for the first tape index 0.  If a finer time resolution of the gain switching is desired this could be done for every tape index (=additional tape index loop)
	for ( cio = 0; cio < nCntAD; cio += 1 )
		if ( UFPE_ioHasTG( lllstIO, nio, cio ) ) 															// This is a true Adc channel having a corresponding telegraph channel... 
			//print "todo_a: lst = UFPE_ioSet_ns()....WriteDataSection_..(a)  neu is OK"
			lllstIO	= UFPE_ioSet_ns( lllstIO, nio, cio, kSC_IO_GAIN, num2str(TelegraphGain_ns( sFo, sc, lllstIO, nio, cio, BegPt ) ) )	// ...so store the gain value (measured and computed from wBig) indexed by Adc index in script 
		elseif ( UFPE_ioHasTGMC( lllstIO, nio, cio ) ) 													// This is a true Adc channel having a corresponding MULTICLAMP telegraph channel...
			lllstIO	= UFPE_ioSet_ns( lllstIO, nio, cio, kSC_IO_GAIN, num2str(TelegraphGainMC_ns( sFo, lllstIO, nio, cio ) ) )		// ...so store the gain value  which the AxoPatch MultiClamp has given
		endif

		if ( UFPE_iov_ns( lllstIO, nio, cio, kSC_IO_GAIN ) != UFPE_iov_ns( lllstIO, nio, cio, kSC_IO_GAINOLD )	)		// Only if the gain has really changed do the time-consuming storage and update...
			SetAxoGainInPanel( cio, UFPE_iov_ns( lllstIO, nio, cio, kSC_IO_GAIN ) ) 							// Update the Gain Setvariable in the main Pulse panel
			PossiblyAdjstSliderInAllWind_ns( sFo )														// Can be commented out if it is too slow. Different approach would be to change YOfs slider like the YAxis  in DispDurAcq()  ???
			//print "todo_a: lst = UFPE_ioSet_ns()....WriteDataSection_..(b) neu is OK", lllstIO[0,200]
			lllstIO	= UFPE_ioSet_ns( lllstIO, nio, cio, kSC_IO_GAINOLD,  UFPE_ioItem( lllstIO, nio, cio, kSC_IO_GAIN ) )		// Remember that gain changes have been handled so that they will not be unnecessarily handled a 2. time 	
		endif
	endfor
	LstIoSet( sFo, lllstIO )							// make gain changes permanent by storing  'lllstIO'  globally

	// STEP 2 :  write the data into the CFS file
	if ( bWriteMode )			

		if ( gCFSHnd == kCFS_NOT_OPEN  )	
			variable	bAppendData	= AppendData()
			nvar		bIncremFile	= root:uf:acq:cons:gbIncremFile
			if ( bWriteMode )										// Do the automatic file name incrementation only when it is intended to really write a file, not when only in watch mode.
				if ( ! bAppendData )
					AutoBuildNextFilename( sFo )						// 	Increment the automatically built file name (= go to next  fileindex ) only if the user does not want to append 
				endif
				if (  bAppendData  &&  bIncremFile ) 						// 	...OR  increment  after having executed  'Finish'  (bIncremFile=UFCom_TRUE)    EVEN  if the user actually  does NOT want to incremenent
					AutoBuildNextFilename( sFo )						//  ( Only when a new file is to be written for each run then increment  even if the user actually  does wants to append )
					bIncremFile	= UFCom_FALSE
				endif
			endif
			gCFShnd = CFSInitWrFile_ns( sFo, lllstIO,  lllstIOTG, lllstBLF, lllstTapeTimes, lllstPoN, nCntAD, sc )			// also sets global handle internally
		endif

		if ( UFCom_DebugVar( "acq", "CfsWrite" ) & 4 )
			printf "\t\t\t\t\tCFSWriteDataSection  a\teb:%d\tp:%d b:%d l:%d f:%d    g.%2d s:%d\t\tFile WAS %s\tOPEN, CFSHnd before:%2d \t/ after:%2d\t  InitWrFile() ]\r", eb, pr, bl, lap, fr, gr, sw, SelectString(OldHnd == kCFS_NOT_OPEN,"    ", "NOT"), Oldhnd, gCFShnd
		endif

		if  ( gCFShnd != kCFS_NOT_OPEN )
			string		sBig	
			for ( cio = 0; cio < nCntAD; cio += 1 )
				sBig	= UFPE_FoAcqADTG( sFo, sc, lllstIOTG, cio, nCntAD )
// 2009-12-14	???
				Write64KBlocks_ns( sFo, lllstIO, lllstIOTG, lllstTapeTimes, lllstPoN, llstBLF, lstTotdur, gCFShnd, sBig, cio, sc, pr, bl, lap, fr, sw, BegPt, nPtsSv, nSmpInt, nCntAD ) 
			endfor
// 2009-12-14	OK
//			WriteHeader_ns( sFo, lllstBLF, lllstPoN, gCFShnd, BegPt, nPtsSv, nSmpInt, pr, bl, lap, fr, gr, sw, 0 )														
			WriteHeader_ns( sFo, lllstBLF, lllstPoN, gCFShnd, BegDisp, nPts,  BegPt, nPtsSv, nSmpInt, pr, bl, lap, fr, gr, sw, 0 )														
			FinishDataSection_ns( gCFShnd, gr )
			variable 	bPoB = UFPE_Pon( lllstPoN, bl, gr ) 					// Return whether P over N must be executed in this block.  Ignores whether Pon is specified for this ADC channel or not.
			if (  bPoB ) 											// write 'PoN' corrected data sweeps
// 2009-12-14	???
//				WriteDataPoN_ns( sFo, wG, lllstIO, lllstIOTG, lllstTapeTimes, lllstPoN, llstBLF, lstTotdur, gCfsHnd, sc, pr, bl, lap, fr, gr, sw, BegPt, nPtsSv, nSmpInt, nCntAD )
				WriteDataPoN_ns( sFo, wG, lllstIO, lllstIOTG, lllstTapeTimes, lllstPoN, llstBLF, lstTotdur, gCfsHnd, sc, pr, bl, lap, fr, gr, sw,  BegDisp, nPts,  BegPt, nPtsSv, nSmpInt, nCntAD )
			endif
			printf "\t\t\t\t\tCFSWriteDataSection   \teb:%d\tp:%d b:%d l:%d f:%d g:%2d s:%d poB:%d\tB:\t%10.0lf\t..%9.0lf\tPts:\t%10.0lf\t\t\t\t\t\t\t[lllstGrps:%s]\r",eb, pr, bl, lap, fr, gr, sw, bPoB, BegPt, BegPt+nPtsSv, nPtsSv, lllstPoN[0,200]
		endif			// gCFShnd  is  OPEN
																
	endif			// bWriteMode

	wG[ UFPE_WG_SWPWRIT ] += 1
// 2005-12-01
	nvar	wgSwpWrit	= root:uf:acq:pul:svSwpsWrt0000
	wgSwpWrit	 += 1
	
	return	gCFShnd
End


static	Function		WriteDataPoN_ns( sFo, wG, lllstIO, lllstIOTG, lllstTapeTimes, lllstPoN, llstBLF, lstTotdur, CfsHnd, sc, pr, bl, lap, fr, gr, sw,  BegDisp, nPts, BegPt, nPtsSv, nSmpInt, nChans )
	string  	sFo, lllstIO, lllstIOTG, lllstTapeTimes, lllstPoN, llstBLF, lstTotdur
	wave	wG
	variable	CFShnd, sc, pr, bl, lap, fr, gr, sw,  BegDisp, nPts,  BegPt, nPtsSv, nSmpInt,  nChans
	variable	cio, bPoC
	string		sBig
	variable	nCntAD		= wG[ UFPE_WG_CNTAD ]	
	if ( sw > 0  &&  sw == UFPE_Sweeps( lllstPoN, bl, gr ) - 1 )			// store 'PoN' only once after last sweep. If there is only 1 sweep, don't store PoN.  Better: catch this earlier... 
		for ( cio = 0; cio < nChans; cio += 1 )						// store 'PoN' data only of last sweep
			// Select wave to be stored depending on users choice: do PoverN for this channel or not (it is users responsibility that it is a true AD and not a telegraph..)
			// Design issue: To keep the CFS file rectangular, dummy data sections are inserted in all non-Pon ADC channels  at the locations where in the real Pon channel(s) the corrected Pon sweeps are inserted.  Could be handled differently...
			bPoC = DoPoverN_ns( sFo, lllstIO, cio )				// Is Pon specified for this ADC channel or not?  Ignores whether Pon is specified for this block.
			sBig	 = SelectString( bPoC,  UFPE_FoAcqADTG( sFo, sc, lllstIOTG, cio, nCntAD ),    UFPE_FoAcqPoN( sFo, sc, lllstIO, cio, nCntAD ) )	 
			//  printf "\t\t\t\t\tCFSW write Pon corrected DS\t\t\tf:%d      s:%d poC:%d\tB:\t%10.0lf\t..%9.0lf\tPts:\t%10.0lf\tcio:%d\t'%s' \r",  fr, sw, bPoC, BegPt, BegPt+nPtsSv, nPtsSv, cio, sBig
			//if (  UFCom_DebugVar( 2, "acq", "CfsWrite" ) & 4  )
				printf "\t\t\t\t\tCFSW write   corrected \t\tp:%d b:%d l:%d f:%d g:%2d s:%d  cio:%d   \tB:\t%10.0lf\t..%9.0lf\tPts:\t%10.0lf\t\t\t'%s' \r",  pr, bl, lap, fr, gr, sw, cio, BegPt, BegPt+nPtsSv, nPtsSv, sBig
			//endif
			Write64KBlocks_ns( sFo, lllstIO, lllstIOTG, lllstTapeTimes, lllstPoN, llstBLF, lstTotdur, CFShnd, sBig, cio, sc, pr, bl, lap, fr, sw, BegPt, nPtsSv, nSmpInt, nChans ) 
		endfor
		WriteHeader_ns( sFo, llstBLF, lllstPoN, CFShnd,  BegDisp, nPts,  BegPt, nPtsSv, nSmpInt, pr, bl, lap, fr, gr, sw, 1 )	// write PoverN corrected trailer after all channels have been processed 
		FinishDataSection_ns( CFShnd, 12345 )
	endif
End



static Function		Write64KBlocks_ns( sFo, lllstIO, lllstIOTG, lllstTapeTimes, lllstGrp, llstBLF, lstTotdur, CFShnd, sBig, cio, sc, pr, bl, lap, fr, sw, BegPt_, nPtsSv, nSmpInt, nChans ) 
// writes 1 datasection (= 1 sweep) to CFS file. Datasection can be larger than 64KB, it is then split into blocks 
// CFS handle, channel number, actual data section is used here,...
	string  	sFo, lllstIO, lllstIOTG, lllstTapeTimes, lllstGrp, llstBLF, lstTotdur
	variable	CFShnd, cio, sc, pr, bl, lap, fr, sw
	variable	nPtsSv, nSmpInt, nChans
	string		sBig
	variable	BegPt_									// includes (for historical reasons...) already the offset to the first 'store' period  (=the duration of the Nostore-PreSweepinterval) 

	variable	TapeBeg	= UFPE_TapeTimeBeg( sFo, bl, 0, lllstTapeTimes )

	wave	wBig			= $sBig						// this is 'AdcN', 'PoNN'...
	variable	nio			=  kSC_ADC
	variable	b, nBlocks, nBlockPts, nBlockBytes, nStartByteOffset	// offset in bytes from the start of the data section to the first byte of data for this channel...
	variable	code, nBytes
	variable	BegPt									// includes the offset given by TapeIdx to any store period (the beginning of the store period referred to the start of the sweep/Frame)

	// Copy catenated 'store' sections of 1 frame/sweep of the big wave 'wBig'  into  a temporary wave (can be larger than the 32KPoints limit imposed by CFS)
	make    /O /N = ( nPtsSv )	wTemp22

	variable  	Pts = 0,  TgtPt = 0,  TapeDur = 0,  TapeDurSum = 0
	variable	eb	=  ELIMINATE_BLANKS()
if ( eb <= 1	)
	variable	tp = 0, TapeCnt  = UFPE_TapeCount( sFo, bl, lllstTapeTimes )
	BegPt_  -=	TapeBeg * 1000 / nSmpInt						 // remove the offset to the first 'store' period  (=the duration of the Nostore-PreSweepinterval)  which is unfortunately for historical reasons already included in 'BegPt_'
	for ( tp = 0; tp < TapeCnt; tp += 1 )							// extract only 'store' sections
		TapeBeg		=  UFPE_TapeTimeBeg( sFo, bl, tp, lllstTapeTimes )
		TapeDur		=  UFPE_TapeTimeDur( sFo, bl, tp, lllstTapeTimes )
		Pts			=  TapeDur	* 1000 / nSmpInt														// ugly : better pass points

		// include the accumulated time of all previous blocks including all laps and frames  'Time1Block_LapsFrms'  in the computation of the begin point of the save period 
		BegPt		= BegPt_ + TapeBeg * 1000 / nSmpInt// ugly : better pass points

	 	wTemp22[ TgtPt, TgtPt  + Pts - 1] = wBig[ BegPt - TgtPt + p ] 			//  waveform arithmetic: fast and recognises nostore-blanks between segments

		// Old code, does not handle nostore-blanks between segments
		// Very old very slow code
		// for ( n = 0; n < nPts ; 	n += step )		// OK  but  slow
		// 	wTemp22[ ( TgtPt + n ) ] = wBig[ BegPt + n ] 
		// endfor

		 printf "\t\t\t\t\tCFSWrDS  Write64KBlocks_ns\teb:%d\tp:%d b:%d l:%d f:%d  \t\t\tB:\t%7d \t\t\t\t\tcio:%d\ttp:%2d\t/%2d\t\t\t\t\t\t\t\t\t\t\tDu:%g\tDuS:%8g\t->\ttDuSP:\t%8g\tbgpt_:%d\tpts:%d\tnPtsSv:\t%8g\tTgt:%10g\tSrc:%10g\t\t tpti:'%s'  \r", eb, p, bl, lap, fr, BegPt, cio, tp, TapeCnt, TapeDur, TapeDurSum, TapeDurSum  * 1000 / nSmpInt, BegPt_, Pts, nPtsSv, TgtPt, BegPt-TgtPt, lllstTapeTimes
		TapeDurSum	+= TapeDur
		TgtPt		 =  TapeDurSum * 1000 / nSmpInt		
	endfor
else 	// EB == 2
		TgtPt	= 0
		Pts		= nPtsSv
		BegPt	= BegPt_
	 	wTemp22[ TgtPt, TgtPt  + Pts - 1] = wBig[ BegPt - TgtPt + p ] 			//  waveform arithmetic: fast and recognises nostore-blanks between segments
		// printf "\t\t\t\t\tCFSWrDS  Write64KBlocks_ns\teb:%d\tp:%d b:%d l:%d f:%d  \t\t\tB:\t%10.0lf\t..%9.0lf\tPts:\t%10.0lf\tcio:%d\t\t\t\t\t\t\t\t\t\t\t\t\t\tDu:%g\tDuS:%8g\t->\ttDuSP:\t%9.0lf\tTgt:%10g\tSrc:%10g\t\t tpti:'%s'  \r", eb, p, bl, lap, fr, BegPt, BegPt+nPtsSv, nPtsSv, cio, TapeDur, TapeDurSum, TapeDurSum  * 1000 / nSmpInt, TgtPt, BegPt-TgtPt, lllstTapeTimes
endif

	// Break temporary catenated 'store' sections of 1 frame/sweep into blocks of maximum 32KPoints (limit imposed by CFS)
	BegPt	= 0

	make /O /W /N=( UFPE_kCFSMAXBYTE )	root:uf:acq:cfsw:wSmall				// 32K is largest CFS section
	wave	wSmall				= 	root:uf:acq:cfsw:wSmall

	nBytes	= nPtsSv * 2
	nBlocks 	= trunc( ( nBytes - 1) / UFPE_kCFSMAXBYTE ) + 1
	for ( b = 0; b < nBlocks; b += 1 )
		nBlockBytes	= ( b == nBlocks - 1 )  ?  nBytes - b * UFPE_kCFSMAXBYTE  :  UFPE_kCFSMAXBYTE
		nBlockPts		= nBlockBytes / 2
		code			= UFCom_UtilWaveCopy( wSmall,  wTemp22,  nBlockPts,  BegPt + b * UFPE_kCFSMAXBYTE/2,  UFPE_kMAXAMPL / UFPE_kFULLSCL_mV ) 
		if ( code )
			printf "****Error: UFCom_UtilWaveCopy() \r"
		endif

		nStartByteOffset 	= cio * nBytes + b * UFPE_kCFSMAXBYTE 
		variable	nCntAD	= cio+1	//dummy to exclude  TG chans
		if ( UFCom_DebugVar( "acq", "CfsWrite" ) & 8 )
			printf  "\t\t\t\t\tCFSWrDS  ADC[cio:%d] in CEDch:%d  '%s'  StartByteOfs:%d  Endbyte:%d  (=%dBytes)\r",  cio, UFPE_iov_ns( lllstIO, nio, cio, kSC_IO_CHAN ), UFPE_FoAcqADTG( sFo, sc, lllstIOTG, cio, nCntAD ),  nStartByteOffset, nStartByteOffset + nBytes, nBytes  
		endif
		//  0 = write to current data section, Byte offset, number of bytes to write, wave buffer. Channels are written one after the other
		UFPE_CfsWriteData( CFShnd, 0,  nStartByteOffset, nBlockBytes, wSmall, UFPE_ERRLINE ) 
		// killwaves wSmall			// can kill only  when wave is not displayed
	endfor

	// printf "\t\t\t\t\tCFSWrDS  Write64KBlocks_ns  \t\t\t\t\t\t\t\t\tPts:%4d\tcio:%d   internal name:'%s'   user name:'%s' \r", nPtsSv, cio, UFPE_FoAcqADTG( sFo, sc, lllstIOTG, cio, nCntAD ), UFPE_ioItem( lllstIO, nio, cio, kSC_IO_NAME )
	if ( UFCom_DebugVar( "acq", "CfsWrite" ) & 8 )
		 printf "\t\t\t\t\tCFSWrDS   cio:%d   internal name:'%s'   user name:'%s' \r", cio, UFPE_FoAcqADTG( sFo, sc, lllstIOTG, cio, nCntAD ), UFPE_ioItem( lllstIO, nio, cio, kSC_IO_NAME )
	endif

	// ..offset in bytes from the start of the data section to the first byte of data for this channel,  Points,  YScale,  YOffset,  XScale,  XOffset, print errors only or also infos
	UFPE_CfsSetDSChan( CFShnd, cio, 0, cio * nBytes, nPtsSv, YScale_ns( lllstIO, cio ), 0, nSmpInt / UFPE_kMILLITOMICRO, 0, UFPE_ERRLINE )
	if ( UFCom_DebugVar( "acq", "CfsWrite" ) & 8  ||  UFCom_DebugVar( "acq", "Telegraph" ) & 8 )
		printf "\t\t\t\t\tCFSWrDS   UFPE_CfsSetDSChan()   cio:%d  startbyte:\t%8d\t  endbyte:\t%8d\t   yScale (<Gain<Telegraph):%g \r", cio, cio * nBytes, ( cio + 1 ) * nBytes, YScale_ns( lllstIO, cio )
	endif
	// printf "\t\t\t\t\tCFSWrDS   UFPE_CfsSetDSChan()   cio:%d  startbyte:\t%8d\t  endbyte:\t%8d\t   yScale (<Gain<Telegraph):%g \r", cio, cio * nBytes, ( cio + 1 ) * nBytes, YScale_ns( lllstIO, cio )
End	

	
Function		CFSInitWrFile_ns( sFo, lllstIO,  lllstIOTG, llstBLF, lllstTapeTimes, lllstPoN, nCntAD, sc )
	string  	sFo, lllstIO,  lllstIOTG, llstBLF, lllstTapeTimes, lllstPoN
	variable	nCntAD				// number of channels without TG   (PascalPulse: 1 or 2,  IGOR: any number )
	variable	sc
	nvar		gCFSHandle	= root:uf:acq:cfsw:gCFSHandle
	nvar		gFileIndex		= root:uf:acq:cfsw:gFileIndex
	svar		gsXUnitsInCfs	= root:uf:acq:cfsw:gsXUnitsInCfs
	string		sGenComm	= GeneralComment()
	string  	sSpecComm	= SpecificComment()

	string		sScriptPath	= ScriptPath( sFo )
	string		bf, sChanName						// channel name,  used by SetFileChan from CFS
	string		sOChar		= "O"				// write 'O' for original data
	variable	cio
	string		sPath		= GetPathFileExt( gFileIndex )
	variable	bFileExists		= UFCom_FileExists( sPath )
	string		sBuf
	
	// Sould but does not control disk access, which is about 11..12 us/WORD for any value from 1 to 1024 (2001, Win95, 350MHz Pentium, file of 360KB) 
	variable	CFSBlockSize = 1 // 1=slow disk access , 1~11.5us/pt, 4~11.5, 16~ 11.8, 64~11.6, 128~11.8, 256~11.2, 512~12, 1024~12 )
	variable	CFShnd = UFPE_CfsCreateFile( sPath, sGenComm, CFSBlockSize , nCntAD, UFPE_kMAX_DSVAR, UFPE_kMAX_FILEVAR, UFPE_ERRLINE ) // sizes of fileArray and DSArray: all as in PatPul 
	if ( CFShnd > 0 )								// file creation was successful
		//printf  "\t\tCFSWr InitWrFile(Cfs/AdcChans:%d)    UFPE_CfsCreateFile() opens '%s' and returns CFSHandle %d . File did %s exist. \r", nCntAD, sPath, CFShnd, SelectString( bFileExists, "NOT", "" )
		gCFSHandle =  CFShnd 					// set global   AND  return  value (below)

		for ( cio = 0; cio < nCntAD; cio += 1 )
			variable	nio	= kSC_ADC
			// printf  "\t\t\t\tCFSWr InitWrFile()   ADC[idxch=ch:%d/%d] in CEDch:%d  internal name:'%s'   user name:'%s'   YUnits:'%s'   XUnitInCfs:'%s'\r", cio, nChans, UFPE_iov_ns( lllstIO, nio, cio, kSC_IO_CHAN ), UFPE_FoAcqADTG( sFo, sc, lllstIOTG, cio, nCntAD ),  UFPE_ioItem( lllstIO, nio, cio, kSC_IO_NAME ), UFPE_ioItem( lllstIO, nio, cio, kSC_IO_UNIT ),  gsXUnitsInCfs
			if ( UFCom_DebugVar( "acq", "CfsWrite" ) & 4 )
				printf  "\t\t\t\tCFSWr InitWrFile()   ADC[idxch=ch:%d/%d] in CEDch:%d  internal name:'%s'   user name:'%s'   YUnits:'%s'   XUnitInCfs:'%s'\r", cio, nCntAD, UFPE_iov_ns( lllstIO, nio, cio, kSC_IO_CHAN ), UFPE_FoAcqADTG( sFo, sc, lllstIOTG, cio, nCntAD ),  UFPE_ioItem( lllstIO, nio, cio, kSC_IO_NAME ), UFPE_ioItem( lllstIO, nio, cio, kSC_IO_UNIT ),  gsXUnitsInCfs
			endif
			// CFS handle, channel number, channelname, Y units (=current or voltage), X units (=time), data saved as 2 byte integers,...
			// ...equalspaced data (=not matrix), INT2 data with no intervening data (=2), last parameter is irrelevant in equalspaced mode (see PatPul)
			sChanName =  UFPE_ioItem( lllstIO, nio, cio, kSC_IO_NAME )  
			if ( strlen( sChanName ) == 0 )											//  If channel name is missing...
				sChanName	= UFPE_ioTNm_ns( nio ) + num2str( UFPE_iov_ns( lllstIO, nio, cio, kSC_IO_CHAN) )		// ..supply a default channel name because ReadCFS needs one
			endif
			UFPE_CfsSetFileChan( CFShnd, cio,  sChanName, UFPE_ioItem( lllstIO, nio, cio, kSC_IO_UNIT ), gsXUnitsInCfs, UFPE_kINT2, kEQUALSPACED, 2, 0, UFPE_ERRLINE )
		endfor

		//? The  UFPE_kFILEVAR  entries  in   InitializeCFSDescriptors()  and   CFSInitWrFile()  must match !
		UFPE_CfsSetVarVal( CFShnd, UFPE_kFV_DATAFILEFROM,	UFPE_kFILEVAR, 0, ksFP_VERSION, 				UFPE_ERRLINE)		// data section variable 0 stores version number	e.g. '301c'
		UFPE_CfsSetVarVal( CFShnd, UFPE_kFV_FILENM, 			UFPE_kFILEVAR, 0, sOChar, 						UFPE_ERRLINE)		// data section variable 1 stores 'O' for original data
		UFPE_CfsSetVarVal( CFShnd, UFPE_kFV_DATAFILE, 		UFPE_kFILEVAR, 0, DataFileW(), 					UFPE_ERRLINE )		// DataFile
		UFPE_CfsSetVarVal( CFShnd, UFPE_kFV_STIMFILE, 			UFPE_kFILEVAR, 0,  UFCom_StripPathAndExtension( sScriptPath ), UFPE_ERRLINE )	// StimFile

		variable	b = 0, gr=0		// the following values rather meaningless as they apply only to block 0 and PonGroup=0 . Values for all blocks are stored in 'WriteHeader_ns()'  
		UFPE_CfsSetVarVal( CFShnd, UFPE_kFV_SWPPERFRM, 		UFPE_kFILEVAR, 0, "0" ,UFPE_ERRLINE)	// num2str( UFPE_Sweeps( lllstPoN, b, gr)),	UFPE_ERRLINE ) 	// obsolete and useless as it applies only to block 0
		UFPE_CfsSetVarVal( CFShnd, UFPE_kFV_FRMPERBLK,		UFPE_kFILEVAR, 0, "0" ,UFPE_ERRLINE)	// num2str( UFPE_Frames( llstBLF,b ) ), 	UFPE_ERRLINE )	// obsolete and useless as it applies only to block 0
		UFPE_CfsSetVarVal( CFShnd, UFPE_kFV_HASPON, 			UFPE_kFILEVAR, 0, "0" ,UFPE_ERRLINE)	// num2str( UFPE_Pon( lllstPoN, b, gr ) ), 	UFPE_ERRLINE ) 	// obsolete and useless as it applies only to block 0
		UFPE_CfsSetVarVal( CFShnd, UFPE_kFV_SPECIFICCOMMENT,	UFPE_kFILEVAR, 0, sSpecComm, 					UFPE_ERRLINE ) 	// specific comment
// 2008-05-20
		UFPE_CfsSetVarVal( CFShnd, UFPE_kFV_LISTBLF,			UFPE_kFILEVAR, 0, llstBLF, 						UFPE_ERRLINE ) 	// the list containing the block/lap/frame structure of the script
		UFPE_CfsSetVarVal( CFShnd, UFPE_kFV_LISTTAPETIMES,	UFPE_kFILEVAR, 0, lllstTapeTimes, 					UFPE_ERRLINE ) 	// the list containing the beins and the lengths of the stored  episodes
		UFPE_CfsSetVarVal( CFShnd, UFPE_kFV_LISTPON,			UFPE_kFILEVAR, 0, lllstPoN, 						UFPE_ERRLINE ) 	// the list containing the block/lap/frame structure of the script
		
	   	// Store the script once in the file section : Fill in the data = store the script lines 
		variable	i, l, nLines
		string  	sLine
		string		sScriptTxt		= ScriptTxt( sFo )

if ( ! bNEWFILEVARS )
		// 1 script line = 1 UFPE_kFILEVAR line :  BAD space usage
		nLines	= ItemsInList( sScriptTxt, "\r" )
		for ( l = 0; l < nLines; l += 1 )	
			i 	= UFPE_kFV_SCRIPTBEGIN + l
			sLine	= StringFromList( l, sScriptTxt, "\r" )
			// printf  "\t\tCFSWr InitWrFile(chans:%d) \tl :%3d / %3d ->\t i :%3d    '%s'  \r", nChans, l,  nLines,  i, sLine
			if ( i < UFPE_kMAX_FILEVAR )										
	   			UFPE_CfsSetVarVal(  CFSHnd, i, UFPE_kFILEVAR, 0, sLine, UFPE_ERRLINE )	
			endif
		endfor
else
		nLines	= ceil( strlen( sScriptTxt ) / ( UFPE_kMAX_CFS_STRLEN - 1 ) )						// 2005-0205 store scripts in blocks..
		for ( l = 0; l < nLines; l += 1 )												// ..store multiple script lines in 1 UFPE_kFILEVAR line
			i 	= UFPE_kFV_SCRIPTBEGIN + l								// we can now store scripts up to appr. 16KB (64 lines x 252 bytes) 
			sLine = sScriptTxt[   l *  ( UFPE_kMAX_CFS_STRLEN - 1 ) ,  ( l + 1 ) *  ( UFPE_kMAX_CFS_STRLEN - 1 )  - 1 ] 
			// printf  "\t\tCFSWr InitWrFile(chans:%d) \tl :%3d / %3d ->\t i :%3d    '%s'  \r", nChans, l,  nLines,  i, sLine
			if ( i < UFPE_kMAX_FILEVAR )										
	   			UFPE_CfsSetVarVal(  CFSHnd, i, UFPE_kFILEVAR, 0, sLine, UFPE_ERRLINE )	
			endif
		endfor
endif

		if ( i >= UFPE_kMAX_FILEVAR )											
   			sprintf sBuf, "Scripts is too long to be stored entirely in CFS file. Truncated at line %d of %d . ", UFPE_kMAX_FILEVAR, i
   			 UFCom_FoAlert( sFo, UFCom_kERR_IMPORTANT, sBuf )
   		endif
   		
		if ( UFCom_DebugVar( "acq", "CfsWrite" ) & 4 )
			printf "\t\t\t\tWr CFSInitWrFile()    UFPE_CfsSetVarVal()  \r"
		endif	
	else
		 UFCom_FoAlert( sFo, UFCom_kERR_FATAL,  "Cannot open CFS path '" + sPath + "' " )
		CFShnd = kCFS_NOT_OPEN
	endif
	return CFShnd	// positive: file creation OK, negative: file creation error code ,   AND  also set global  (above)
End



static Function		WriteHeader_ns(  sFo, lllstBLF,  lllstGrp, hnd,  BegDisp, nPts, BegPt, nPtsSv, SmpInt, pr, bl, lap, fr, gr, sw, pon )
	string  	sFo, lllstBLF, lllstGrp
	variable	hnd,  BegDisp, nPts,  BegPt, nPtsSv, SmpInt, pr, bl, lap, fr, gr, sw, pon 
	string		bf
	variable	SampleFreq	= 1000 /  SmpInt 			// 2004-0202  SF =  Round( 1000 /  SmpInt ) 	was  wrong as it clips at SmpInt=1000us
	variable	Tim			= TimeElapsed()				// these are the actual ticks counted. Another possibility: Compute time of this sweep from script including blank section.
	variable	Duration		= Round( nPtsSv * SmpInt / 1000 )
	variable	Start			= 0
	variable	PreVal		= 2						// minimum CED1401 clock prescaler value. Useless but kept for compatibility
	variable	CountVal		= Round( 100 * SmpInt / 1000 )	//  Pulse / StimFit has 10 
	variable	Mode		= UFPE_ERRLINE

	// printf "\t\t\t\t\tCFSWriteHeader_ns \t\t\tp:%d b:%d l:%d f:%d g:%d s:%d po:%d\tB:\t%10.0lf\t..%9.0lf\tPts:\t%10.0lf\tfrms:%d\tswps:%d\tUF_po:%d\t\r", pr, bl, lap, fr, gr, sw, pon, BegPt, BegPt+nPtsSv, nPtsSv, UFPE_Frames(lllstBLF,bl), UFPE_Sweeps1( sFo, bl, gr), UFPE_Pon(lllstGrp, bl, gr ) 

	// The  UFPE_kDSVAR  entries  in   InitializeCFSDescriptors()  and  WriteHeader()  must match ! The order is defined in  'UFPE_LstDS' .
	// CFS handle, var number=index, which array, data section, string or variable value (as string) 
	UFPE_CfsSetVarVal( hnd,  UFPE_DS_SMPRATE, 	UFPE_kDSVAR, 0, num2str( SampleFreq ),				Mode )
	UFPE_CfsSetVarVal( hnd,  UFPE_DS_TIMEFRM1, 	UFPE_kDSVAR, 0, num2str( Tim ),					Mode )
	UFPE_CfsSetVarVal( hnd,  UFPE_DS_FRMDUR, 	UFPE_kDSVAR, 0, num2str( Duration ),				Mode )
	UFPE_CfsSetVarVal( hnd,  UFPE_DS_BEG1, 		UFPE_kDSVAR, 0, num2str( Start ),					Mode )
	UFPE_CfsSetVarVal( hnd,  UFPE_DS_DUR1, 		UFPE_kDSVAR, 0, num2str( Duration ),				Mode )
	UFPE_CfsSetVarVal( hnd,  UFPE_DS_PRE, 		UFPE_kDSVAR, 0, num2str( PreVal ),					Mode )
	UFPE_CfsSetVarVal( hnd,  UFPE_DS_COUNT, 		UFPE_kDSVAR, 0, num2str( CountVal ),				Mode )
	UFPE_CfsSetVarVal( hnd,  UFPE_DS_PROTO, 		UFPE_kDSVAR, 0, UFCom_FilenameOnly( ScriptPath(sFo)),	Mode )
	UFPE_CfsSetVarVal( hnd,  UFPE_DS_BLOCK,		UFPE_kDSVAR, 0, num2str( bl ),						Mode )		
	UFPE_CfsSetVarVal( hnd,  UFPE_DS_FRAME, 		UFPE_kDSVAR, 0, num2str( fr ),						Mode )			
	UFPE_CfsSetVarVal( hnd,	UFPE_DS_SWEEP, 		UFPE_kDSVAR, 0, num2str( sw ),					Mode )
	UFPE_CfsSetVarVal( hnd,	UFPE_DS_PON, 		UFPE_kDSVAR, 0, num2str( pon ),					Mode )		
	UFPE_CfsSetVarVal( hnd,	UFPE_DS_MAXBLOCK, 	UFPE_kDSVAR, 0, num2str( UFPE_Blocks( lllstBLF ) ),	 	Mode )	
	UFPE_CfsSetVarVal( hnd,	UFPE_DS_MAXFRAME,	UFPE_kDSVAR, 0, num2str( UFPE_Frames( lllstBLF, bl ) ),	Mode )		
	UFPE_CfsSetVarVal( hnd,	UFPE_DS_MAXSWEEP, 	UFPE_kDSVAR, 0, num2str( UFPE_Sweeps( lllstGrp, bl, gr)),	Mode )		
	UFPE_CfsSetVarVal( hnd,	UFPE_DS_HASPON, 	UFPE_kDSVAR, 0, num2str( UFPE_Pon( lllstGrp, bl, gr ) ),	Mode )		
// 2008-05-
	UFPE_CfsSetVarVal( hnd,	UFPE_DS_PROT, 		UFPE_kDSVAR, 0, num2str( pr ),					Mode )		
	UFPE_CfsSetVarVal( hnd,	UFPE_DS_MAXLAP, 	UFPE_kDSVAR, 0, num2str( UFPE_Laps( lllstBLF, bl ) ),	Mode )		
	UFPE_CfsSetVarVal( hnd,	UFPE_DS_LAP, 		UFPE_kDSVAR, 0, num2str( lap ),					Mode )		
	UFPE_CfsSetVarVal( hnd,	UFPE_DS_BEGPT, 		UFPE_kDSVAR, 0, num2str( BegDisp ) ,					Mode )		
	UFPE_CfsSetVarVal( hnd,	UFPE_DS_PNTS, 		UFPE_kDSVAR, 0, num2str( nPts ) ,					Mode )		
	UFPE_CfsSetVarVal( hnd,	UFPE_DS_BEGPT_SV,	UFPE_kDSVAR, 0, num2str( BegPt ) ,					Mode )		
	UFPE_CfsSetVarVal( hnd,	UFPE_DS_PNTS_SV,	UFPE_kDSVAR, 0, num2str( nPtsSv ) ,				Mode )		
End
	
	
	Function		FinishDataSection_ns( CFShnd, nStartIdx )
		variable	CFShnd, nStartIdx
		string		bf
		// write complete data section to disk, 0 means append to end of file,  don't care about 16 flags
		UFPE_CfsInsertDS( CFShnd, 0, UFPE_kNOFLAGS, UFPE_ERRLINE ) // 0: write complete data section to disk by appending to end of file, 
		//  printf  "\t\t\t\t\tCFSWr FinishDataSection_ns(CFShnd:%d)   UFPE_CfsInsertDS(). Idx:%d.  \r", CFShnd, nStartIdx 
	End


//==================================================================================================================================
//   TELEGRAPH  CHANNELS   DURING  CFS WRITE  .   THE  TG  INITIALIZATION is in  UFPE_Script6.ipf              NEW STYLE  FAST LOAD

static constant	TOLERANCE				= 0.2		// tolerance for acceptance of a value, z.B: ERR(5.2-5.3), OK(5.3-5.7) 
static constant	cADCGAIN_OUT_OF_TOLER	= 1.0		// returned when read value lies between the expected values 		(1.0001 could be used as marker) 
static constant	cADCGAIN_OUT_OF_RANGE	= 1.0		// returned to avoid horrible values when telegraph inputs not plugged	(1.0002 could be used as marker) 


static  Function	YScale_ns( lllstIO, cio )
// converts Gain( Adc channel number in script )  into  scale value( index is counted up 0,1,2.. ) .  Needed  in CFSWrite
	string  	lllstIO
	variable	cio
	return	UFPE_kFULLSCL_mV / UFPE_kMAXAMPL / UFPE_iov_ns( lllstIO, kSC_ADC, cio, kSC_IO_GAIN )

End	
	
Function		TelegraphGainPreliminary_ns( sFo, wG, lllstIO, hnd )
// Get all telegraph gains early before the acq starts so that the Y axis can also already be adjusted before the acq starts. 
	string  	sFo
	wave	wG
	string  	lllstIO										//&lllstIO could pass back changes
	variable	hnd
	string		bf
	variable	Chan, TGChan, TGMCChan					// true channel numbers
	variable	cio, nio	= kSC_ADC
	variable	nCntAD	= wG[ UFPE_WG_CNTAD ]	
	for ( cio = 0; cio < nCntAD; cio += 1 )
		Chan		= UFPE_iov_ns( lllstIO, nio, cio, kSC_IO_CHAN ) 
		if (  UFPE_ioHasTG( lllstIO, nio, cio ) )
			TGChan	= UFPE_iov_ns( lllstIO, nio, cio, kSC_IO_TGCH ) 
			// print "todo_a:    lst = UFPE_ioSet_ns()....TelegraphGainPreliminary_ns(a)   neu  is OK"
			lllstIO		= UFPE_ioSet_ns( lllstIO, nio, cio, kSC_IO_GAIN, num2str( TelegraphGainOnce_ns( sFo, lllstIO, nio, cio, hnd ) ) )	// Get the telegraph gain before the acq starts so that the y axis can be adjusted 
//			if ( UFCom_DebugVar( "acq", "Telegraph" ) )
				printf "\t\t\t\tTelegraphGainPreliminary() \tFound AD %d  with   \tTGChan %d.      \tSetting Gain: %s  \r",  Chan,  TGChan, UFPE_ioItem( lllstIO, nio, cio, kSC_IO_GAIN ) 
//			endif
		endif
		if (  UFPE_ioHasTGMC( lllstIO, nio, cio ) )
			TGMCChan = UFPE_iov_ns( lllstIO, nio, cio, kSC_IO_TGMCCH )
			//print "todo_a:    lst = UFPE_ioSet_ns()....TelegraphGainPreliminary_ns(b) neu is OK "
			lllstIO		= UFPE_ioSet_ns( lllstIO, nio, cio, kSC_IO_GAIN, num2str( TelegraphGainMC_ns( sFo, lllstIO, nio, cio ) ) )	// Get the MC telegraph gain before the acq starts so that the y axis can be adjusted 
//			if ( UFCom_DebugVar( "acq", "Telegraph" ) )
				printf "\t\t\t\tTelegraphGainPreliminary() \tFound AD %d  with   \tTGMCChan %d.  \tSetting Gain: %s  \r",  Chan,  TGMCChan, UFPE_ioItem( lllstIO, nio, cio, kSC_IO_GAIN )  
//			endif
		endif
	endfor
	LstIoSet( sFo, lllstIO )							// make gain changes permanent by storing  'lllstIO'  globally
End


static  Function	TelegraphGainOnce_ns( sFo, lllstIO, nio, cio, hnd )
// Get right now 1 value from the Adc so that the telegraph gains are known before the acq starts so that the Y axis can be adjusted before the acq starts. 
// This works for any true Adc channel having a corresponding voltage controlled telegraph channel (not for a MultiClamp!)  .  Gain is returned from  Axopatch in mV / pA or mV / mV 
	string  	sFo, lllstIO
	variable	nio, cio, hnd			 												// cio is linear index in script
	variable	nTGChan		= UFPE_ioTGChan( lllstIO, nio, cio )									//  nTGChan is true TG  channel number in script
	variable	ch			= UFPE_iov_ns( lllstIO, nio, cio, kSC_IO_CHAN )								// ch is true Adc channel number in script
	variable	AdcValue		= 0
	string 	command		= "ADC, " + num2str(  nTGChan ) + ";"						// get right now 1 value from the Adc
	if ( UFP_CedTypeOf(hnd)  != UFCom_kNOTFOUND )												// check if Ced is open
		AdcValue	= UFP_CedGetResponse( hnd, command, command, 0 ) * UFPE_kFULLSCL_mV / UFPE_kMAXAMPL	// last param is 'ErrMode' : display messages or errors
	endif
	variable	Gain 			= TGAdc2Gain_ns( sFo, AdcValue, nTGChan, ch, -1 )
	string	 	bf
//	if ( UFCom_DebugVar( "acq", "Telegraph" ) )
		printf "\t\t\t\tTelegraphGainOnce(\tnIO:%d  cio:%d  '%s' )\t\t\tAdc ch:%2d  is controlled by TG:%2d\t%.2lf V\tY:%8.3lf \t->TGGain:%7.2lf   \t \r", nio, cio, command, ch, nTGChan, AdcValue / 1000,  AdcValue,  Gain
//	endif
	return	Gain
End	


static Function	TelegraphGain_ns( sFo, sc, lllstIO, nio, cio, BegPt )
// This works for any true Adc channel having a corresponding voltage controlled telegraph channel (not for a MultiClamp!) . 
// Gain is returned from  Axopatch in mV / pA or mV / mV  . This function is to be called every time when any true AD channel (not a Telegraph) has sampled data ready..
	string  	sFo, lllstIO
	variable	sc, nio, cio, BegPt	 								// cio is linear index of true adc channels, the (higher) cio index of TG channels is NOT passed or processed here
	nvar		gnCompress	= $"root:uf:" + sFo + ":cons:gnCompressTG"
	variable	ch			= UFPE_iov_ns( lllstIO, nio, cio, kSC_IO_CHAN )	// ch is true Adc channel number in script
	variable	nTGChan		= UFPE_ioTGChan( lllstIO, nio, cio )			//  nTGChan is true TG  channel number in script
//	string		sTGNm		= FldAcqioTgNm( sFo, nTGChan ) 
	string		sTGNm		= UFPE_FoAcqTg( sFo, sc, lllstIO, cio ) 
	wave  	wBig 		= $sTGNm								// this is 'AdcN' but only for telegraph channels
if ( ELIMINATE_BLANKS()  <= 1	)
	variable	AdcValue		= wBig[ BegPt / gnCompress ]
else	//EB == 2
			AdcValue		= wBig[ BegPt ]
endif
	variable	Gain 			= TGAdc2Gain_ns( sFo, AdcValue, nTGChan, ch, BegPt )
	string	 	bf
	if ( UFCom_DebugVar( "acq", "Telegraph" ) )
		printf "\t\t\t\tTelegraphGain( \tnIO:%d cio:%d ) sTGNm:\t%s\tAdc ch:%2d  is controlled by TG:%2d\t%.2lf V\tY:%8.3lf \t->TGGain:%7.2lf   \tBgP\t:%11d \t/ %8.2lf \t \r", nio, cio, UFCom_pd( sTGNm,6), ch, nTGChan, AdcValue / 1000, AdcValue,  Gain, BegPt, BegPt/gnCompress
	endif
	return	Gain
End	


static Function	TGAdc2Gain_ns( sFo, AdcValue, nTGChan, ch, BegPt )
	string  	sFo
	variable	AdcValue, nTGChan, ch, BegPt 
	string		bf
	variable	GainVoltage	= AdcValue / 1000
	variable	index			= round( 2 * GainVoltage )
	//    corresponding signal in V; see Axopatch 200 manual for scaling of telegraph outputs
	//						Index		  0   1   2   3   4     5     6      7     8      9     10    11    12    13
	//						GainVoltage	  x   x    x    x  2.0  2.5  3.0  3.5  4.0  4.5   5.0   5.5   6.0   6.5		// Volt
	variable	Gain 	= str2num( StringFromList( index, " 1;  1;  1;  1;  .5;   1;    2;     5;   10;  20;   50;  100; 200; 500 " ) )	// mV / pA or mV / mV   
	if (  index < 4 || 13 < index )
		Gain = cADCGAIN_OUT_OF_RANGE
		if ( CEDHandleIsOpen_ns() )				// 2009-12-14 avoid unnecessary warnings if in test mode without a Ced
			sprintf bf, "TelegraphGainVoltage of TG chan %d (controlling Adc chan %d)  \t%.2lf V is out of allowed range ( %.1lf ...%.1lf V ). Gain %.1lf is returned. [BegPt:%d]", nTGChan, ch, GainVoltage, 2 -TOLERANCE, 6.5 +TOLERANCE, Gain, BegPt
			 UFCom_FoAlert( sFo, UFCom_kERR_IMPORTANT,  bf )
		endif
	elseif ( abs( index / 2 - GainVoltage ) > TOLERANCE ) 
		Gain = cADCGAIN_OUT_OF_TOLER
		sprintf bf, "TelegraphGainVoltage of TG chan %d (controlling Adc chan %d)  \t%.2lf V is out of tolerance ( %.1lf, %.1lf....%.1lf V +-%.1lf V ). Gain %.1lf is returned. [BegPt:%d]", nTGChan, ch, GainVoltage, 2, 2.5, 6.5, TOLERANCE, Gain, BegPt
		 UFCom_FoAlert( sFo, UFCom_kERR_IMPORTANT,  bf )
	endif
	return	Gain
End	

// 2004-0927 TG without MC700TG XOP: works only partly (to retrieve gain the MCC700 channel must be switched which is not acceptable)
//static constant        	kMC700_MODEL	= 0 ,   kMC700_SERIALNUM	= 1 ,  kMC700_COMPORT = 2 ,   kMC700_DEVICE = 3 ,  kMC700_CHANNEL = 4
//static strconstant    	lstMC700_ID		= "Model;Serial#;COMPort;Device;Channel;"	// Assumption : Order is MoSeCoDeCh (same as in XOP)
static constant		kMC700_A		= 0 , kMC700_B	= 1
static strconstant	kMC700_MODELS	= "700A;700B"
//static constant	kMC700_MODE_VC	= 0 ,   kMC700_MODE_CC	= 1
static strconstant	kMC700_MODES	= "VC;IC;I=0"

// ASSUMPTION: Same separators ',;' and same entries 'HWTyp, SerNum, Port, AxoBus, Chan, Mode, Alpha, ScaleFct, Units' as in IGOR 'BreakInfo()' 


Static Function	TelegraphGainMC_ns( sFo, lllstIO, nio, cio )		
//  Get and return the gain value  from the AxoPatch MultiClamp 
// ASSUMPTION: Same separators ' , ; ' and same entries 'HWTyp, SerNum, Port, AxoBus, Chan, Mode, Alpha, ScaleFct, Units' as in    'UFP_MCTgPickupInfo()/UpdateDisplay()'  

// If the user specified in the script simple channel specs e.g. '1'    then check that there are only 2 channels available (=1 MCC700) and use it
// If the user specified extended channel specs e.g. '1_700A_Port_X_AxoBus_Y'   or  '2_700B_SN_xxxx'    then compare them with the available units: if they match  OK , if not print the  desired and the available identifications
	string  	sFo
	string		lllstIO
	variable	nio, cio 																// ioch is linear index in script
	string  	sTGChan			= UFPE_ioTGMCChanS( lllstIO, nio, cio )								// e.g. '1'  or  '2'  or  '2_700A_Port_1_AxoBus_0'  or  '1_700B_SN_0'	// simple or extended spec
	variable	ch				= UFPE_iov_ns( lllstIO, nio, cio, kSC_IO_CHAN )								// ch is true channel number in script
	variable	Gain				= 0
	variable	nCode
	variable	MCTgChan 
string		sMCTgChannelInfo	= UFP_MCTgPickupInfo()
	variable	MCTgChansAvailable	= ItemsInList( sMCTgChannelInfo )
	// printf "\t\tTelegraphGainMC( ioch:%d = Adc%d ) \tPickupInfo returns Chans avail: %d   '%s' \r", ioch, ch, MCTgChansAvailable, sMCTgChannelInfo

	string		sOneChannelInfo, s700AB//, bf
	variable	rTyp, rSerNum, rComPort, rAxoBus, rChan, rMode, rMCGain, rSclFactor					// the specifiers which the MC700 has transmitted, extracted from  'PickUpInfo'
	string		rsSclFactorUnits
	variable	rScrTyp, rScrSerNum, rScrComPort, rScrAxoBus, rScrChan							// the specifiers extracted from script

	if ( CheckAvailableTelegraphChans_ns( sFo, sTGChan, MCTgChansAvailable ) == UFCom_kERROR )
		 UFCom_FoAlert( sFo, UFCom_kERR_SEVERE, "MultiClamp Telegraph channel error.  Gain = 1 is returned for channel  Adc " + num2str( ch )  + " and  'TGMCChan = " + sTGChan + "' . " ) 
		return	1		// this is the default gain
	endif

	nCode	= CheckSimpleSpecAgainstTGCnt_ns( sFo, sTGChan, rScrChan, MCTgChansAvailable ) 			// extract the only (= the channel) specifier  from script and  make sure that there are exactly 2 channels available

	if ( nCode  == UFCom_kERROR )															// there were not exactly 2 available telegraph channels : we don't know how to connect

		 UFCom_FoAlert( sFo, UFCom_kERR_SEVERE, "MultiClamp Telegraph channel error.  Gain = 1 is returned for channel  Adc " + num2str( ch )  + " and  'TGMCChan = " + sTGChan + "' . " ) 
		return	1		// this is the default gain

	elseif ( nCode == UFCom_TRUE )															// OK : we have found a simple spec and  exactly 2 available telegraph channels 

		for ( MCTGChan = 0;  MCTGChan < MCTgChansAvailable;  MCTgChan += 1 )
			sOneChannelInfo	= StringFromList( MCTGChan, sMCTgChannelInfo )
			if ( BreakInfo_ns( sOneChannelInfo, rTyp, rSerNum, rComPort, rAxoBus, rChan, rMode, rMCGain, rSclFactor, rsSclFactorUnits )  !=  9 )
				UFCom_DeveloperError( "Expected 9 entries in  MCTG info string '" + sOneChannelInfo + "' .  AllChans: " + sMCTgChannelInfo ) 
			endif	
			if ( rChan == rScrChan )													// it is sufficient to check the channel as there are only 2 channels 
				Gain	= rMCGain * rSclFactor
				if ( rTyp ==  kMC700_A )
					sprintf s700AB, "CP:%3d    AB:%3d  ", rComPort, rAxoBus
				else
					sprintf s700AB, "SN:%15d", rSerNum
				endif
//				if ( UFCom_DebugDepthSel() > 0   &&  DebugSection() & UFCom_kDBG_TELEGRAPH )
				if ( UFCom_DebugVar( "acq", "Telegraph" ) )
					printf "\t\tTelegraphGainMC( nio:%d, cio:%d = Adc%d, sTGChan:\t%s\t)  %s \t%s\tTGCh:%2d\t'%s'\t   Gn:\t%7.2lf\tSc: %.1lf %s\t -> Gain: %5.1lf\t... \r", nio, cio, ch, UFCom_pd( sTGChan, 22), StringFromList( rTyp, kMC700_MODELS),  s700AB, rChan, StringFromList( rMode,kMC700_MODES), rMCGain, rSclFactor, rsSclFactorUnits, Gain
				endif
			endif	
		endfor

	else																			// OK : we have found an extended spec 

		if ( BreakExtendedSpec_ns(sFo, sTGChan, rScrTyp, rScrSerNum, rScrComPort, rScrAxoBus, rScrChan ) == UFCom_TRUE )	// extract the specifiers  from script.  sTGChan is extended spec, simple specs have already been processed.

			variable	nFound	= 0
			for ( MCTGChan = 0;  MCTGChan < MCTgChansAvailable;  MCTgChan += 1 )
				sOneChannelInfo	= StringFromList( MCTGChan, sMCTgChannelInfo )
				if ( BreakInfo_ns( sOneChannelInfo, rTyp, rSerNum, rComPort, rAxoBus, rChan, rMode, rMCGain, rSclFactor, rsSclFactorUnits )  !=  9 )
					UFCom_DeveloperError( "Expected 9 entries in  MCTG info string '" + sOneChannelInfo + "' .  AllChans: " + sMCTgChannelInfo )  
				endif	
				
				if ( rTyp == rScrTyp  &&  rChan == rScrChan  && ( ( rTyp == kMC700_A  &&  rComPort == rScrComPort   &&  rAxoBus == rScrAxoBus )  ||  ( rTyp == kMC700_B  &&  rSerNum == rScrSerNum ) ) )
					if ( rTyp ==  kMC700_A )
						sprintf s700AB, "CP:%3d    AB:%3d  ", rComPort, rAxoBus
					else
						sprintf s700AB, "SN:%15d", rSerNum
					endif
					nFound	+= 1
					Gain		= rMCGain * rSclFactor
//					if ( UFCom_DebugDepthSel() > 0  &&  DebugSection() & UFCom_kDBG_TELEGRAPH )
					if ( UFCom_DebugVar( "acq", "Telegraph" ) )
						printf "\t\tTelegraphGainMC( nio:%d, cio:%d = Adc%d, sTGChan:\t%s\t)  %s \t%s\tTGCh:%2d\t'%s'\t   Gn:\t%7.2lf\tSc: %.1lf %s\t -> Gain: %5.1lf\t... \r", nio, cio, ch, UFCom_pd( sTGChan, 22), StringFromList( rTyp, kMC700_MODELS),  s700AB, rChan, StringFromList( rMode,kMC700_MODES), rMCGain, rSclFactor, rsSclFactorUnits, Gain
					endif
				endif	
			endfor
			if ( nFound  != 1 )  
				 UFCom_FoAlert( sFo, UFCom_kERR_SEVERE, "MultiClamp Telegraph channel not connected.  Gain = 1 is returned for channel  Adc " + num2str( ch )  + " and  'TGMCChan = " + sTGChan + "' . " ) 
				return	1		// this is the default gain
			endif

		else
			 UFCom_FoAlert( sFo, UFCom_kERR_SEVERE, "MultiClamp Telegraph channel error.  Gain = 1 is returned for channel  Adc " + num2str( ch )  + " and  'TGMCChan = " + sTGChan + "' . " ) 
			return	1		// this is the default gain
		endif

	endif


	variable	nTGChan		= UFPE_ioTGMCChan( lllstIO, nio, cio )
	if ( nTGChan != rScrChan )
		UFCom_InternalError( "nTGChan != rScrChan" ) 
	endif


//	// printf "\t\tTelegraphGainMC( ioch:%d = Adc%d ) \tPickupInfo returns Chans avail: %d   '%s' \r", ioch, ch, MCTgChansAvailable, sMCTgChannelInfo
//	if ( MCTgChansAvailable == 2 )
//		for ( MCTGChan = 0;  MCTGChan < MCTgChansAvailable;  MCTgChan += 1 )
//			sOneChannelInfo	= StringFromList( MCTGChan, sMCTgChannelInfo )
//			if ( BreakInfo( sOneChannelInfo, rTyp, rSerNum, rComPort, rAxoBus, rChan, rMode, rMCGain, rSclFactor, rsSclFactorUnits )  !=  9 )
//				UFCom_InternalError( "Expected 9 entries in  MCTG info string '" + sOneChannelInfo + "' ." ) 
//			endif	
//			if ( rChan == nTGChan )
//				Gain	= rMCGain * rSclFactor
//				printf "\t\tTelegraphGainMC( ioch:%d = Adc%d, sTGChan:'%s'  nTGChan:%d )  Pickup Typ:%s  SN:%d  CP:%d  AB:%d  TGCh: %d  Mode:%d  McGn:\t%7.2lf\tSc: %.1lf %s\t -> Gain: %5.1lf\t... \r", ioch, ch, sTGChan, nTGChan, StringFromList( rTyp, kMC700_MODELS), rSerNum,  rComPort, rAxoBus, rChan, rMode, rMCGain, rSclFactor, rsSclFactorUnits, Gain
//			endif	
//		endfor
//	elseif ( MCTgChansAvailable > 2 )
//		UFCom_InternalError( "Only 2 MCTG channels implemented. Extracted " + num2str( MCTgChansAvailable) + " from '" + sMCTgChannelInfo + "' ." ) 
//	else			// todo? discriminate between 0 and 1 
//		 UFCom_FoAlert( sFo, UFCom_kERR_IMPORTANT, "Script specifies to use MultiClamp Telegraph channels, but only " + num2str( MCTgChansAvailable) + " channel(s) could be extracted from '" + sMCTgChannelInfo + "' ." ) 
//	endif
//	if ( Gain == 0 )
//		 UFCom_FoAlert( sFo, UFCom_kERR_IMPORTANT, "Illegal MultiClamp Telegraph channel.  Gain = 1 is returned. " ) 
//		Gain = 1 		// returning 0 might possibly cause a crash (at least during testing....)
//	endif

	return	Gain
End
			

//
//static Function	IsConnectedTGChannel( sOneChannelInfo ) 
//	string  	sOneChannelInfo
//	return	strlen( StringFromList( 0, sOneChannelInfo, "," )  )								// Check the first entry which should be 0 or 1 (for type 700A or B). No spaces or letters are allowed
////	return	numtype( str2num( StringFromList( 0, sOneChannelInfo, "," ) )  ) != kNUMTYPE_NAN )	// Check the first entry which should be 0 or 1 (for type 700A or B). Safer but slower.		// entry in string list is not empty
//End


static Function	CheckAvailableTelegraphChans_ns( sFo, sTGChan, MCTgChansAvailable )
	string  	sFo, sTGChan
	variable	MCTgChansAvailable
	string  	sBuf1
	variable	nError	= 0
	if ( MCTgChansAvailable == 0 )
		sprintf sBuf1, "Failed to connect  'TGMCChan = %s' . There is currently  no  MC700 channel available. Turn on the MC700 and  'Apply'  again. ",  sTGChan 
		 UFCom_FoAlert( sFo, UFCom_kERR_SEVERE, sBuf1 )
		nError	= UFCom_kERROR
	endif
	return	nError
End 


static Function	CheckSimpleSpecAgainstTGCnt_ns( sFo, sTGChan, rScrChan, MCTgChansAvailable )
	string  	sFo, sTGChan
	variable	&rScrChan
	variable	MCTgChansAvailable
	string  	sBuf1, sBuf2
	variable	nError	= 0
	if ( strlen( sTGChan ) == 1  )
		if (  MCTgChansAvailable != 2 )
			sprintf sBuf1, "TGMCChan = %s  does not identify the MC700 uniquely. There are currently  %d  MC700 channels available. \r",  sTGChan ,  MCTgChansAvailable 
			sprintf sBuf2, "\t\t\tEither turn off all unnecessary  MC700s  or  use  specifiers e.g . 'TGMCChan =  1_700A_Port_X_AxoBus_Y'   or  'TGMCChan =  2_700B_SN_xxxx'  "
			 UFCom_FoAlert( sFo, UFCom_kERR_SEVERE, sBuf1 + sBuf2 )
			return	UFCom_kERROR
		endif
		rScrChan			= str2num( sTGChan[ 0,0 ] ) 			// use  the first digit : limits the channels to 0..9 .  In this special (=simple spec) case there is always only 1 digit. 
		return	UFCom_TRUE
	endif
	return	 UFCom_FALSE					// not a simple spec
End 


static Function	BreakExtendedSpec_ns( sFo, sTGChan, rScrTyp, rnSerNum, rnComPort, rnAxoBus, rScrChan )
// 'TGMCChan =  1_700A_Port_2_AxoBus_3'   or  'TGMCChan =  2_700B_SN_1234'
	string  	sFo, sTGChan
	variable	&rScrTyp, &rnSerNum, &rnComPort, &rnAxoBus, &rScrChan 
	string  	sBuf
	rScrChan	= str2num( sTGChan[ 0,0 ] )			// can be simple or extended spec  
	if ( strlen( sTGChan ) > 1 )						// it is an extended spec  
		if ( cmpstr( sTGChan[ 1, 4 ] , "_700" ) == 0 )
			if ( cmpstr( sTGChan[ 5,6 ] , "A_" ) == 0  ||   cmpstr( sTGChan[ 5,6 ] , "B_" ) == 0 )
				rScrTyp	=  ( cmpstr( sTGChan[ 5,6 ] , "B_" ) == 0 )						// 0 : 700A , 1 : 700B
				if ( rScrTyp == kMC700_A )
					if ( cmpstr( sTGChan[ 6,11 ] , "_Port_" ) == 0  &&  cmpstr( sTGChan[ 13,20 ] , "_AxoBus_" ) == 0 )
						rnComPort	= str2num(  sTGChan[ 12, 12 ] ) 
						rnAxoBus	= str2num(  sTGChan[ 21, 21 ] ) 
//						if ( UFCom_DebugDepthSel() > 2  &&  DebugSection() & UFCom_kDBG_TELEGRAPH )
						if ( UFCom_DebugVar( "acq", "Telegraph" ) )
							printf "\t\t\t\tTelegraphGainMC  BreakExtendedSpec(\t%s\t)   700A ,  Chan:%2d ,  Port:%2d ,  AxoBus:%2d  \r",   UFCom_pd( sTGChan,22) , rScrChan, rnComPort, rnAxoBus
						endif
					else
						sprintf sBuf, "TGMCChan = %s  is an illegal specification. Use  e.g .   'TGMCChan =  1_700A_Port_2_AxoBus_3''  ",  sTGChan 
						 UFCom_FoAlert( sFo, UFCom_kERR_SEVERE, sBuf )
						return	UFCom_kERROR	
					endif		
				else						// = 700B
					if ( cmpstr( sTGChan[ 6,9 ] , "_SN_" ) == 0 )
						rnSerNum	= str2num(  sTGChan[ 10, inf ] ) 
//						if ( UFCom_DebugDepthSel() > 2  &&  DebugSection() & UFCom_kDBG_TELEGRAPH )
						if ( UFCom_DebugVar( "acq", "Telegraph" ) )
							printf "\t\t\t\tTelegraphGainMC  BreakExtendedSpec(\t%s\t)  700B ,  Chan:%2d ,  SN: %d  \r",  UFCom_pd( sTGChan,22) , rScrChan, rnSerNum
						endif
					else
						sprintf sBuf, "TGMCChan = %s  is an illegal specification. Use  e.g .   'TGMCChan =  2_700B_SN_xxxx'  ",  sTGChan 
						 UFCom_FoAlert( sFo, UFCom_kERR_SEVERE, sBuf )
						return	UFCom_kERROR	
					endif		
				endif
			else
				sprintf sBuf, "TGMCChan = %s  is an illegal specification. Use  e.g . 'TGMCChan =  1_700A_Port_X_AxoBus_Y'   or  'TGMCChan =  2_700B_SN_xxxx'  ",  sTGChan 
				 UFCom_FoAlert( sFo, UFCom_kERR_SEVERE, sBuf )
				return	UFCom_kERROR	
			endif		
		else
			sprintf sBuf, "TGMCChan = %s  is an illegal specification. Use  e.g . 'TGMCChan =  1_700A_Port_X_AxoBus_Y'   or  'TGMCChan =  2_700B_SN_xxxx'  ",  sTGChan 
			 UFCom_FoAlert( sFo, UFCom_kERR_SEVERE, sBuf )
			return	UFCom_kERROR	
		endif		
	else
		UFCom_InternalError( "BreakExtendedSpec( '" + sTGChan + " )  is a simple spec. " ) 		// should never happen 
	endif
	return	UFCom_TRUE		// OK
End


static Function		BreakInfo_ns( sOneChannelInfo, rHWTyp, rSerNum, rComPort, rAxoBus, rChan, rMode, rMCGain, rSclFct, rsSclFctUnits )
// breaks MultiClamp telegraph 1-channel info string as given by XOP  'UFP_MCTgPickupInfo()'   into its components.
// ASSUMPTION: Same separators ' , ; ' and same entries 'HWTyp, SerNum, Port, AxoBus, Chan, Mode, Alpha, ScaleFct, Units' as in    'UFP_MCTgPickupInfo()/UpdateDisplay()'  
	string		sOneChannelInfo
	variable	&rHWTyp, &rSerNum, &rComPort, &rAxoBus, &rChan, &rMode, &rMCGain, &rSclFct
	string		&rsSclFctUnits
	variable	nEntries	= ItemsInList( sOneChannelInfo, "," )
	rHWTyp		= str2num( StringFromList( 0, sOneChannelInfo, "," ) ) 
	rSerNum		= str2num( StringFromList( 1, sOneChannelInfo, "," ) )		
	rComPort		= str2num( StringFromList( 2, sOneChannelInfo, "," ) ) + 1	// one-based : 1,2,3...
	rAxoBus		= str2num( StringFromList( 3, sOneChannelInfo, "," ) )		
	rChan		= str2num( StringFromList( 4, sOneChannelInfo, "," ) ) + 1	// one-based : 1,2
	rMode		= str2num( StringFromList( 5, sOneChannelInfo, "," ) )
	rMCGain		= str2num( StringFromList( 6, sOneChannelInfo, "," ) )
	rSclFct		= str2num( StringFromList( 7, sOneChannelInfo, "," ) )
	rsSclFctUnits	= StringFromList( 8, sOneChannelInfo, "," )
	// print "\t\tBreakInfo():", rComPort, rAxoBus, rChan, "Mode:", rMode, "\tGain:\t", rMCGain, "\tSclFactor:\t", rSclFct, "\t", rsSclFctUnits
	return	nEntries
End


Function		DisplayAvailMCTgChans_ns()
	string		sOneChannelInfo
	string		rsSclFactorUnits
	variable	rTyp, rSerNum, rComPort, rAxoBus, rChan, rMode, rMCGain, rSclFactor					// the specifiers which the MC700 has transmitted, extracted from  'PickUpInfo'
	variable	MCTGChan

	string  	sMCTgChannelInfo	= UFP_MCTgPickupInfo()

	variable	MCTgChansAvailable	=  ItemsInList( sMCTgChannelInfo )

	printf "\r\t\tDisplayAvailMCTgChans()  finds  %d   MCC700 channels. '%s' \r", MCTgChansAvailable, sMCTgChannelInfo
	for ( MCTGChan = 0;  MCTGChan < MCTgChansAvailable;  MCTgChan += 1 )
		sOneChannelInfo	= StringFromList( MCTGChan, sMCTgChannelInfo )

//		if (  IsConnectedTGChannel( sOneChannelInfo ) ) 

			if ( BreakInfo_ns( sOneChannelInfo, rTyp, rSerNum, rComPort, rAxoBus, rChan, rMode, rMCGain, rSclFactor, rsSclFactorUnits )  !=  9 )
				UFCom_DeveloperError( "Expected 9 entries in  MCTG info string '" + sOneChannelInfo + "' .  AllChans: " + sMCTgChannelInfo ) 
			endif	
			printf "\t\t\tDisplayAvailMCTgChans() \tMC:%d\t%s\ttp:%3d\tpo:%3d\tab:%3d\tch:%2d\tsn:%16d\tGn:\t%7.1lf\tScl:\t%3.1lf\t  U: %s\tMode: '%s' \r", MCTGChan, SelectString( rTyp==0, "700B", "700A"), rTyp, rComPort, rAxoBus, rChan,  rSerNum, rMCGain, rSclFactor, UFCom_pd(rsSclFactorUnits,6), StringFromList( rMode, kMC700_MODES )
//		endif
	endfor
End


//==================================================================================================================================
//   DISPLAY AND STORE FUNCTIONS CALLED BY TIMER DURING ACQUISITION
//   NEW  APPROACH 020218:    call processing functions (=CFSStore, DisplayDurAcq..) from WITHIN  Process()
//   usage: call Process()  repeatedly  from  ADDASwing()   and  once  from  CedStartAcq 

// todo PULSE stores 1 original  and  1 corrected sweep for each frame, ...
// ... so GetSweepsPerFrame() should return 2 HERE (and elsewhere, but not everywhere..) 

Function		Process_ns( sFolders, sFo, ptAD, lllstIO,  lllstIOTG,  wG, lllstTapeTimes, llstBLF, lllstPoN, lstTotdur )		// PROTOCOL  AWARE
//!  MAJOR CONCEPT ...recover underlying sweep / frame structure ....can be extended to other script types (here only PULSE) 
//  checks list with Frame / Sweeps end points (=index into ADC integer wave) built before the acquisition (in OutElems...()....)
//  only after a frame is completely acquired (=this point 'ptAD' is reached or passed) we can manipulate the data (=disk store or display)
// Version1 up to 031006:  the  array behind SwpEndSave() does NOT contain  'gnProt'  so  'gnProt'  is counted down in AddaSwing() 
//		and compared here against internal 'igLasProt' to decide if another Protocol must be processed. This was possible as nReps contained JUST ONE protocol..
// Version 2 : nRep no longer is 1 protocol so AddaSwing()  cannot directly control  'gnProt'  ( and should not in fact have to know anything about prots, blocks frames, sweeps )
// 	Solution:	extend   Get_Sweep/Frame/Start/End_Point()  so that it contains  'gnProt' . Clean but truely  PROTOCOL_AWARE  requires much space (times  gnProt !!!)
	string  	sFolders		// always 'acq:pul'
	string  	sFo			// always 'acq'			todo simplify
	variable	ptAD			// -1 : only initialize the internal globals, all further calls supply a value > 0 meaning real action 
	string  	lllstIO,  lllstIOTG, lllstTapeTimes, llstBLF, lllstPoN, lstTotdur  
	wave 	wG

variable 	sc= 0		// todo_c 
variable	nSmpInt		= SmpIntDacUs( sFo )		// ugly : better pass points
	string  	sTxt		= "\t\t\t\t\t\t"
	svar		llstNewdsTimes	= $"root:uf:" + sFo + ":" + "llstNewdsTimes" 
	// printf "\t\tProcess_ns(0 sFo : '%s' ) : llstNewdsTimes : '%s' \r", sFo, llstNewdsTimes[0,200] 

	variable	nProts		= UFPE_Prots( sFo )

	// printf "\t\tProcess_ns(0 sFo : '%s' ) : data folder : '%s'   ptAD: %d\r", sFo, GetDataFolder( 1 ) , ptAD
	// Initialization....
	if ( ptAD == -1 )
		UFCom_PossiblyCreateFolder( "root:uf:" + sFo + ":stim:" )
		variable  /G	$"root:uf:" + sFo + ":stim:igLastProt"	= 0	
		variable  /G	$"root:uf:" + sFo + ":stim:igLastB"	= 0
		variable  /G	$"root:uf:" + sFo + ":stim:igLastLap"	= 0
		variable  /G	$"root:uf:" + sFo + ":stim:igLastFrm"	= 0	// internal globals storing the number of the last...
		variable  /G	$"root:uf:" + sFo + ":stim:igLastGrp"	= 0	// internal globals storing the number of the last...
		variable  /G	$"root:uf:" + sFo + ":stim:igLastSwp"	= 0	// ..frame, sweep and protocol which have already been processed 
		return 0												
	else 
		nvar		 	igLastProt	= $"root:uf:" + sFo + ":stim:igLastProt"
		nvar			igLastB	= $"root:uf:" + sFo + ":stim:igLastB"
		nvar			igLastLap	= $"root:uf:" + sFo + ":stim:igLastLap"
		nvar			igLastFrm	= $"root:uf:" + sFo + ":stim:igLastFrm"
		nvar			igLastGrp	= $"root:uf:" + sFo + ":stim:igLastGrp"
		nvar			igLastSwp	= $"root:uf:" + sFo + ":stim:igLastSwp"
	endif
	// printf "\t\tProcess_ns(1 sFo : '%s' ) : data folder : '%s' \r", sFo, GetDataFolder( 1 ) 

	string		bf
	variable	pr, bl, la, fr, gr, sw, swpEnd
	variable	BegDisp, nPts, tp=0
	variable	BegPt, nPtsSv
	variable	eb	=  ELIMINATE_BLANKS() 

if ( eb  <= 1	)
	swpEnd	= UFPE_TapeSwpEndPrAw( sFo, sc, igLastProt, igLastB, igLastLap, igLastFrm, igLastGrp, igLastSwp, nSmpInt, lllstTapeTimes, llstBLF, lstTotdur )	// 2003-10-07  PROTOCOL  AWARE
	//printf "\t\ttodo Proc old swpEnd: %d  [pts:%d]    Tapecnt:%d   begdisp:%d \r", swpEnd, nPts, UFPE_TapeCount( sFo, bl, lllstTapeTimes ), BegDisp
endif

	// printf "\t\t\t\tCFSWr  PROcess receiv.swpEnd(\tp:%d b:%d l:%d f:%d g:%2d s:%d      \t%7d <=?%7d (ptAD)\t%s  igLastProt:%d \r",  igLastProt, igLastB, igLastLap, igLastFrm, igLastGrp, igLastSwp, swpEnd, ptAD, SelectString( swpEnd  <= ptAD , "START..   will return immediately..." , "START..allow processing" ), igLastProt 
	for ( pr =  igLastProt; pr < nProts; pr += 1 )
		for ( bl =  igLastB; bl < UFPE_Blocks1( sFo );  bl += 1 )
			for ( la =  igLastLap; la <  UFPE_Laps1( sFo, bl );  la += 1 )
				for ( fr =  igLastFrm; fr < UFPE_Frames1( sFo, bl );  fr += 1 )
					for ( gr = igLastGrp; gr < UFPE_PonGroups( sFo, bl ); gr += 1 )
						for ( sw = igLastSwp; sw < UFPE_Sweeps1( sFo, bl, gr ); sw += 1 )

							// 2009-03-20 revamped 
							if ( eb  <= 1 )
								swpEnd	= UFPE_TapeSwpEndPrAw( 	sFo, sc, pr, bl, la, fr, gr, sw, nSmpInt, lllstTapeTimes, llstBLF, lstTotdur )  		// For Loop condition in Process()   
								BegPt	= UFPE_TapeSwpBegPrAw( 	sFo, sc, pr, bl, la, fr, gr, sw, nSmpInt, lllstTapeTimes, llstBLF, lstTotdur )		// For WriteDataSaction() and ComputePon()
								nPtsSv	= UFPE_TapeSwpPtsPrAw( 	sFo, sc, pr, bl, la, fr, 		 nSmpInt, lllstTapeTimes ) 					// For WriteDataSaction() and ComputePon().  Extract only the sum of 'store' sections points
							else		// EB == 2
								swpEnd	= UFPE_Nds_Extract( sc, pr, bl, la, fr, gr, 1, llstNewdsTimes, llstBLF, BegDisp, nPts )					//  For Loop condition in Process().  		     BegDisp, nPts   are references which are computed and passed back (TRUE TIMES)
// 2009-03-25
//								swpEnd	= BegDisp + nPts																	//  For Loop condition in Process().  
								UFPE_Grp_Extract( sc, pr, bl, la, fr, gr, sw, 1, lllstPoN, llstBLF, BegPt, nPtsSv )								//  For WriteDataSaction() and ComputePon().  BegPt,   nPtsSv are references which are computed and passed back
								//UFPE_Tape_Extract( sFo, sc,  pr, bl, la, fr, tp, 1, 1, nSmpInt, lllstTapeTimes, llstBLF, BegDisp, BegPt, nPts )			//  BegDisp, BegPt, nPts are references which are passed back
								//nPts	= UFPE_TapePts1Fr( sFo, bl, nSmpInt, llstBLF, lllstTapeTimes )									// sum of all tape points of 1 frame (and 1 block, 1 lap) 
								//printf "\t\t\t\tProcess    \t\t\t\t\teb:%d\tp:%d b:%d l:%d f:%d g:%2d s:%d \t\tB:\t%10.0lf\t..%9.0lf\tPts:\t%10.0lf\tDisp:\t%10.0lf\tswE:\t%10.0lf <=?%6d\t%s\t[lllstNds:%s] \r",eb, pr, bl, la, fr, gr, sw, BegPt, BegPt+nPtsSv , nPts, BegDisp, swpEnd, ptAD, sTxt, llstNewdsTimes[0,200]
							endif

							igLastProt	=  pr		
							igLastB	=  bl		
							igLastLap	=  la		
							igLastFrm	=  fr		
							igLastGrp	=  gr		
							igLastSwp =  sw 		

							if ( ptAD < swpEnd )		
								// Main debugging line:
								sTxt	= "no:  RETURN..sweep not yet ready "
								//printf "\t\t\t\tProcess    \t\t\t\t\teb:%d\tp:%d b:%d l:%d f:%d g:%2d s:%d \t\tB:\t%10.0lf\t..%9.0lf\tPtD:\t%10.0lf\tDisp:\t%10.0lf\tswE:\t%10.0lf <=?%6d\t%s\t[lllstNds:%s] \r",eb, pr, bl, la, fr, gr, sw, BegPt, BegPt+nPtsSv , nPts, BegDisp, swpEnd, ptAD, sTxt, llstNewdsTimes[0,200]
								return swpEnd
							else
								// Main debugging line:
								sTxt	= "yes: Continue processing....\t"
								printf "\t\t\t\tProcess    \t\t\t\t\teb:%d\tp:%d b:%d l:%d f:%d g:%2d s:%d   \t\tB:\t%10.0lf\t..%9.0lf\tPtD:\t%10.0lf\tDisp:\t%10.0lf\tswE:\t%10.0lf <=?%6d\t%s\t[lllstNds:%s] \r",eb, pr, bl, la, fr, gr, sw, BegPt, BegPt+nPtsSv , nPts, BegDisp, swpEnd, ptAD, sTxt, llstNewdsTimes[0,200]
							endif
// 2009-03-24
							DispDuringAcq1_ns( sFo, pr, bl, la, fr, kRA_DS, BegPt, nPtsSv, BegDisp, nPts )			// range is DS = data section = smallest display range
			
							// PON SWEEP PROCESSING
							//if (  UFCom_DebugVar( 2, "acq", "CfsWrite" ) & 4 )
								//printf  "\t\t\t\tCFSWr  Process \t\t\t\tp:%d b:%d l:%d f:%d g:%2d s:%d/%g\t%7d <=?%6d\t\t\t\tPROCESSING SWP PON\r", pr, bl, la, fr, gr, sw,  UFPE_PonSwps1( sFo, bl, gr ) - 1, swpEnd, ptAD 
							//endif
							UFCom_StartTimer( sFo, "OnlineAn" )
							ComputePOverNCorrection_ns( sFo, sc, pr, bl, la, fr, gr, sw, wG, lllstIO, lllstIOTG, lllstPoN, BegPt, nPtsSv )		// 2003-10-08  !  PROTOCOL  AWARE			
							UFCom_StopTimer( sFo, "OnlineAn" )
					
							//	SWP_CFSWRITE
							UFCom_StartTimer( sFo, "CFSWrite" )
// 2009-12-14
							WriteDataSection_ns( sFo, sc, pr, bl, la, fr, gr, sw, wG, lllstIO,  lllstIOTG, llstBLF, lllstPoN, BegPt, nPtsSv, BegDisp, nPts )			
							UFCom_StopTimer( sFo, "CFSWrite" )
						endfor								// ..PonSweeps
						igLastSwp = 0						
					endfor								// ..PonGroups
			
					// FRAME PROCESSING
					// Main debugging line:
					sTxt	= "yes: PROCESSING FRAME \t"
					printf "\t\t\t\tProcess    \t\t\t\t\teb:%d\tp:%d b:%d l:%d f:%d g:%2d s:%d   \t\tB:\t%10.0lf\t..%9.0lf\tPtD:\t%10.0lf\tDisp:\t%10.0lf\tswE:\t%10.0lf <=?%6d\t%s\t \r",eb, pr, bl, la, fr, gr, sw, BegPt, BegPt+nPtsSv , nPts, BegDisp, swpEnd, ptAD, sTxt
					
					//UFCom_StartTimer( sFo, "OnlineAn" )
					//OnlineAnalysis( sFolders, p, b, f )						// 2003-10-08  !    NOT  YET  REALLY  PROTOCOL  AWARE				
					//UFCom_StopTimer( sFo, "OnlineAn" )
			
					//	FRM_DISPLAY
					UFCom_StartTimer( sFo, "Graphics" )
					variable BegPt_, nPtS_, BegDi_

					RangeToPoints( 	sFo, pr, bl, la, fr, kRA_FRAME, nSmpInt, llstBLF, lllstTapeTimes, BegPt_, nPtS_ )	
					BegDi_		= BegDisp + nPts - UFPE_NdsPts1Fr( bl, llstNewdsTimes )							//   BegDi_ shifts the time scale in 'TrueTime' mode
					DispDuringAcq1_ns( 	sFo, pr, bl, la, fr, kRA_FRAME, BegPt_, nPtS_, BegDi_, nPts )					//   BegDi_ shifts the time scale in 'TrueTime' mode

					UFCom_StopTimer( sFo, "Graphics" )
					DoUpdate											// Required in test mode without CED, when Igor runs through the code without any idle times.  In contrast in the Ced mode with the true ADDA timing in the Background task Igor finds time to update the display regularly.

					igLastSwp = 0						
					igLastGrp	= 0 					// ..
					// printf  "\t\t\t\tCFSWr \tProcess()  (last setting \tf:%d,s:%d) end of sweeps loop, next frame..\t\r", f, s-1
				endfor							// ..frames

				// LAP  PROCESSING
				// Main debugging line:
				sTxt	= "yes: PROCESSING LAP      \t"
				printf "\t\t\t\tProcess    \t\t\t\t\teb:%d\tp:%d b:%d l:%d      g:%2d s:%d   \t\tB:\t%10.0lf\t..%9.0lf\tPtD:\t%10.0lf\tDisp:\t%10.0lf\tswE:\t%10.0lf <=?%6d\t%s\t \r",eb, pr, bl, la,        gr, sw, BegPt, BegPt+nPtsSv , nPts, BegDisp, swpEnd, ptAD, sTxt
				
				//	LAP_DISPLAY
				UFCom_StartTimer( sFo, "Graphics" )
				RangeToPoints( 	sFo, pr, bl, la, 0, kRA_LAP, nSmpInt, llstBLF, lllstTapeTimes, BegPt_, nPtS_ )	
				BegDi_		= BegDisp + nPts - UFPE_NdsPts1Lap( bl, llstBLF, llstNewdsTimes )						//   BegDi_ shifts the time scale in 'TrueTime' mode
				DispDuringAcq1_ns( 	sFo, pr, bl, la, 0, kRA_LAP, BegPt_, nPtS_, BegDi_, nPts )							//   BegDi_ shifts the time scale in 'TrueTime' mode

				UFCom_StopTimer( sFo, "Graphics" )
				DoUpdate											// Required in test mode without CED, when Igor runs through the code without any idle times.  In contrast in the Ced mode with the true ADDA timing in the Background task Igor finds time to update the display regularly.

				igLastSwp	=  0					// depending on sweeps/frames/ptAd this function is sometimes called at the end  ( when or after finishing )....
				igLastGrp	= 0 					// ..
				igLastFrm	= 0 					// ..when nothing has to be stored or displayed. Because igLastFrm has been/ is set to the end value the function is left immediately.
			endfor							// ..laps

			igLastSwp	= 0					// depending on sweeps/frames/ptAd this function is sometimes called at the end  ( when or after finishing )....
			igLastGrp	= 0 					// ..
			igLastFrm	= 0 					// ..when nothing has to be stored or displayed. Because igLastFrm has been/ is set to the end value the function is left immediately.
			igLastLap	= 0					// depending on sweeps/frames/ptAd this function is sometimes called at the end  ( when or after finishing )....
		endfor							// ..blocks
		igLastSwp	= 0					// depending on sweeps/frames/ptAd this function is sometimes called at the end  ( when or after finishing )....
		igLastGrp	= 0 					// ..
		igLastFrm	= 0 					// ..when nothing has to be stored or displayed. Because igLastFrm has been/ is set to the end value the function is left immediately.
		igLastLap	= 0					// depending on sweeps/frames/ptAd this function is sometimes called at the end  ( when or after finishing )....
		igLastB	= 0					// depending on sweeps/frames/ptAd this function is sometimes called at the end  ( when or after finishing )....
	endfor							// ..prots
	igLastSwp	= 0					// depending on sweeps/frames/ptAd this function is sometimes called at the end  ( when or after finishing )....
	igLastGrp	= 0 					// ..
	igLastFrm	= 0 					// ..when nothing has to be stored or displayed. Because igLastFrm has been/ is set to the end value the function is left immediately.
	igLastLap	= 0					// depending on sweeps/frames/ptAd this function is sometimes called at the end  ( when or after finishing )....
	igLastB	= 0					// depending on sweeps/frames/ptAd this function is sometimes called at the end  ( when or after finishing )....
	igLastProt	= pr 					// ..when nothing has to be stored or displayed. Because igLastFrm has been/ is set to the end value the function is left immediately.

	//printf  "\t\t\t\t\tCFSWr  Process end frames. set\tp:%d -> igLastProt:%d , \tb:%d -> igLastB:%d , \tl:%d -> igLastLap:%d , \tf:%d -> igLastFrm:%d ,\tgr:%d -> igLastGrp:%d , igLastSwp:%d) ....???.......and return finally \r", pr, igLastProt, bl, igLastB, la, igLastLap, fr, igLastFrm, gr, igLastGrp, igLastSwp 

	// printf "\t\tProcess(2 sFo : '%s' ) : data folder : '%s' \r", sFo, GetDataFolder( 1 ) 
End
	

static Function	ComputePOverNCorrection_ns( sFo, sc, pr, bl, la, fr, gr, sw, wG, lllstIO, lllstIOTG, lllstPoN, BegPt, nPtsSv )			
// Computes PoverN corrected data sweeps only for those ADC channels where  'Pon' has been specified in the IO line.  Note: The 'Pon' corrected data sweeps are dummy-written also for non-Pon ADC channels to keep the CFS-file structure simple.
	string  	sFo, lllstIO, lllstIOTG, lllstPoN
	variable	sc, pr, bl, la, fr, gr, sw, BegPt, nPtsSv
	wave	wG

// 2009-03-23  new...
	variable 	bPoB = UFPE_Pon( lllstPoN, bl, gr ) 					// Return whether P over N must be executed in this block.  Ignores whether Pon is specified for this ADC channel or not.
	if ( bPoB )

		variable	nCntAD		= wG[ UFPE_WG_CNTAD ]	
		variable	eb			= ELIMINATE_BLANKS()
	
		variable	EndPt		= BegPt + nPtsSv
	
		variable	cio
		variable	PrevBegPt		= -1
		variable	LastBegPt		= -1
		string		bf
	
		variable	SweepsTimesCorrAmp = ( UFPE_Sweeps1( sFo, bl, gr ) - 1 ) * UFPE_PonCorrAmp( sFo, bl, gr )
		variable	nSmpInt			 = SmpIntDacUs( sFo ) 	// OR = wG[]    
		variable	BAvgBegPt		 = 0
		variable	BAvgEndPt		 = 0
		variable	/G root:uf:acq:cfsw:BaseSubtractOfs				// bad or wrong: creation may reset...	// Stores offset correction value of sweep 0 which is subtracted in following sweeps. Global to keep the value but used only locally. 
		nvar		BaseSubtractOfs= root:uf:acq:cfsw:BaseSubtractOfs								// Stores offset correction value of sweep 0 which is subtracted in following sweeps. Global to keep the value but used only locally. 
	
		// Approach1: Use temporary one-sweep-buffer for intermediary correction steps (=sweep addition) and copy this temporary buffer into the current sweep of 'PoNx'. Benefit: Intermediary correction steps can be displayed  at the cost of buffer copying time.
		// Approach2: Copy all intermediary correction steps directly into last sweep of 'PoNx'. Faster but no intermediary display (except when accessing last sweep in Display)
		// Approach3 (taken): Copy all intermediary correction steps (=sweep addition)  directly into current  AND into last sweep of 'PoNx'.  This is reasonably fast and intermediary display possible.
		
		// Add first sweep and the following correction sweeps (up to the last sweep of this frame)
		for ( cio = 0; cio < nCntAD; cio += 1 )										// cio  is  Adc index,  NOT  PoN index !
	
			variable	bPoC 		= DoPoverN_ns( sFo, lllstIO, cio )				// Is Pon specified for this ADC channel in the IO section of the script or not?   Ignores whether Pon is specified for this block or not.
			if ( bPoC )														// User wants PoverN for this ADC channel.  Note: It is users responsibility that it is a true AD and not a telegraph..
				string  	sBig		= UFPE_FoAcqADTG( sFo, sc, lllstIOTG, cio, nCntAD )	// old :get the source Adc channel directly
				wave	wBig 	= $sBig
				string		sPoN	= UFPE_FoAcqPoN( sFo, sc, lllstIO, cio, nCntAD ) 
				wave 	wPoN	= $sPoN
	
				if ( sw == 0 )
					wPoN[ BegPt, BegPt + nPtsSv ]	= wBig[ p ]						// data from first sweep initialize first sweep  ( clear frame is not necessary ) ...
	
					// Compute offset correction value of sweep 0  which will be subtracted in following sweeps.				 
					// Do not subtract the value in sweep 0 : if there was an offset it is kept throughout the PoN correction, but the offset does not increase with every sweep as it would be without  'BaseSubtractOfs'
	// 2009-03-23 old
	//				BAvgBegPt		= BegPt															// in points : the begin of the first (non-blank) segment (the point where the recorded section starts)
					// Use the first real segment for offset computation (one could also use a possible leading blank  OR  use a  leading  blank and the following segment) 
					// If the first element is a blank=nostore element  then use the second element.  It is the user's responsibility to ensure that it is segment (whose value is constant by definition).
	//				variable	nElement	= ( UFPE_eTyp( wE, wBFS,  cio, bl, 0 )  == UFPE_mI( "Blank" ) 	?  1  :  0			// for averaging the zero value to be subtracted  use element 0 , but in case  element 0 is not stored (being a 'Blank') then use the next element 1, which certainly is stored (in old-style scripts)
	//				BAvgEndPt		= BegPt + ( UFPE_eV( wE,wBFS,cio,bl,0,sw, nElement, UFPE_EV_DUR ) / nSmpInt)	// in points, nElement is normally 0 but 1 if element 0 is not stored = is a blank
	//				BaseSubtractOfs	= faverage( wPoN, pnt2x(  wPoN, BAvgBegPt ),  pnt2x(  wPoN, BAvgEndPt ) )  	

					// 2009-03-23 wrong gn (here we have no first element,  nPtsSv contains the entire Pon section...)
					//BAvgBegPt		= BegPt															// in points : the begin of the first (non-blank) segment (the point where the recorded section starts)
					//BAvgEndPt		= BegPt + nPtsSv  													//   ToManual   and  Design Issue: The entire first element of a Pon section is used for averaging the zero value to be subtracted  

	// 2009-03-23 new	ASS 100 points are used for zero value
					BAvgEndPt		= BegPt - 1  														//   ToManual   and  Design Issue: the last 100 points before a Pon section starts...
					BAvgBegPt		= BAvgEndPt - 100													// ... are used for averaging the zero value which will be subtracted  
	
					BaseSubtractOfs	= mean( wBig, pnt2x(  wBig, BAvgBegPt ),  pnt2x(  wBig, BAvgEndPt ) )  			// Points are taken from the original ADC as the Pon channel contains garbage outside the Pon section
		
				else
					// Copy previous  sweep intermediary corrected data into current sweep and then add current correction sweep
					PrevBegPt			= UFPE_TapeSwpBeg( sFo, sc, pr, bl, la, fr, gr, sw - 1 )	
	
					// Subtract  offset correction value computed in sweep 0  in all following sweeps
					wPoN[ BegPt, BegPt + nPtsSv ]	= wPoN[ PrevBegPt - BegPt + p ] + ( wBig[ p ] - BaseSubtractOfs )  / SweepsTimesCorrAmp	// 2004-08-06  recognises BaseSubtractOfs
	
				endif
	
				if ( sw < UFPE_Sweeps1( sFo, bl, gr ) - 1 )												// the last sweep needs not be copied as it is already at the right place
					LastBegPt			= UFPE_TapeSwpBeg( sFo, sc, pr, bl, la, fr, gr, UFPE_Sweeps1( sFo, bl, gr ) - 1 )	
					wPoN[ LastBegPt, LastBegPt + nPtsSv ]	=  wPoN[ BegPt  - LastBegPt + p ]					// copy current  corrected sweep into last sweep.
				endif
				// printf "\t\t\t\t\tComputePOverNCorrection\teb:%d\tp:%d b:%d l:%d f:%d g:%d s:%d poC:%d\tB:\t%10.0lf\t..%9.0lf\tPot:\t%10.0lf\tcio:%d\t'%s' pts:%4d \t'%s' pts:%4d \tPsp:%5d \tLsp:%5d \tBAv[\t  %6d\t..%6d\t] = \tAvg %6.3lf\t \r", eb,pr,bl,la,fr,gr,sw,bPoC,BegPt,EndPt,nPtsSv,cio, sBig, numPnts($sBig), sPoN, numPnts($sPoN), PrevBegPt,LastBegPt, BAvgBegPt,BAvgEndPt,BaseSubtractOfs
	
				if ( UFCom_DebugVar( "acq", "CfsWrite" ) & 4 )
					printf "\t\t\t\tCFSw  ComputePOverNCorr( \t\t\t        f:%d s:%d  \t    BegP:%5d \tEnd?:%5d\tPts:%4d \t'%s' pts:%4d \t'%s' pts:%4d \tPsp:%5d \tLsp:%5d \tBAv[\t/%6d\t..%6d\t] = \tAvg %g\tnElem=?? \r", fr, sw, BegPt, EndPt, nPtsSv, sBig, numPnts($sBig), sPoN,numPnts($sPoN), PrevBegPt,LastBegPt, BAvgBegPt, BAvgEndPt, BaseSubtractOfs
				endif
				// display wPoN;  UFCom_FoAlert( sFo, UFCom_kERR_FATAL,  "kuki6_ns" )
			endif
		endfor
	endif 	// poB
End
	
	
Function	DoPoverN_ns( sFo, lllstIO, cio )
// Is Pon specified for this ADC channel or not = must for the Adc channel with index 'cio'  the PoverN correction be done?    Ignores whether Pon is specified for this block.
	string  	sFo, lllstIO
	variable	cio
	//variable	bDoPoN	= UFPE_iov_ns( lllstIO, kSC_ADC, cio, kSC_IO_PON )  	//todo.....
	variable	bDoPoN	= UFPE_ioAdcHasPon( lllstIO, cio ) 
	//printf "\t\tDoPoverN_ns( sFo, lllstIO, cio:%2d ) returns  bDoPoN:%.1lf \r", cio, bDoPoN
	return	bDoPoN
End
	
	
	Function 		FinishCFSFile()
		string  	bf
		nvar		gCFSHandle	= root:uf:acq:cfsw:gCFSHandle
		nvar		gFileIndex		= root:uf:acq:cfsw:gFileIndex
		string		sPath		= GetPathFileExt( gFileIndex )
		if ( gCFSHandle	!= kCFS_NOT_OPEN )		
			UFPE_CfsCloseFile( gCFSHandle, UFPE_ERRLINE )
			gCFSHandle	= kCFS_NOT_OPEN 
			Backup()
			// printf "\t\tCFSWr  FinishCFSFile() closes CFS file '%s'    (hnd:%d) \r", sPath, gCFSHandle	
			if ( UFCom_DebugVar( "acq", "CfsWrite" ) )
				printf "\t\tCFSWr  FinishCFSFile() closes CFS file '%s'    (hnd:%d) \r", sPath, gCFSHandle	
			endif
		else
			// printf "\t\tCFSWr  FinishCFSFile():  no open CFS file  '%s'  \r", sPath
			if ( UFCom_DebugVar( "acq", "CfsWrite" ) )
				printf "\t\tCFSWr  FinishCFSFile():  no open CFS file  '%s'  \r", sPath
			endif
		endif
	End
	
	
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	AUTOMATIC  DATA  FILE  NAME GENERATION  SPECIFIC  TO  FPULSE
	//	Automatic file name generation	:	 Functions  relying on  globals  gCell, gFileIndex...  , which are valid and used only during acquisition
	
	static Function		AutoBuildNextFilename( sFo )	
	// Increment the automatically built file name = go to next  fileindex. Changes the globals  'gFileIndex'  and   'gsDataFileW' 
		string  	sFo
		nvar		gFileIndex		= root:uf:acq:cfsw:gFileIndex
		do 			
			gFileIndex	+= 1										// Increment the aut omatically built file name = go to next  fileindex
	
			if ( gFileIndex == UFCom_kANM_MAX_2LETTERS - 1 )
				 UFCom_FoAlert( sFo, UFCom_kERR_IMPORTANT,  " You are using the last file with current name and cell number ( " + GetPathFileExt( UFCom_kANM_MAX_2LETTERS-1) + " ). " )
			endif
			if ( gFileIndex == UFCom_kANM_MAX_2LETTERS  )
				 UFCom_FoAlert( sFo, UFCom_kERR_SEVERE,  " All files with current name and cell number from AA to ZZ have been used ( " + GetPathFileExt( 0 ) + "  to   " + GetPathFileExt( UFCom_kANM_MAX_2LETTERS-1) + " ). \r\tThe last file will be overwritten." )
			endif
			gFileIndex	= min( gFileIndex , UFCom_kANM_MAX_2LETTERS - 1 ) 
			DataFileWSet( GetFileName() + UFPE_ksCFS_EXT)
	
			// printf "\t\tbuStart()  AutoBuildNextFilename()  checking  '%s'\t:  File  does  %s \r",  GetPathFileExt( gFileIndex ), SelectString(  UFCom_FileExists(  GetPathFileExt( gFileIndex ) ), "NOT exist: creating it...", "exist: skipping it..." )
		while  (  UFCom_FileExists(  GetPathFileExt( gFileIndex ) )  &&  gFileIndex < UFCom_kANM_MAX_2LETTERS - 1 )	// skip existing files
	End
	

//	static Function	 /S	GetPathFileExt( nIndex )
//	// builds and returns automatic file name (including global dir and base filename and cell) by converting the passed  'index'  into two letters in the range from 0..26x26-1
//		variable	nIndex
//		variable	nCell		= Cell()
//		string		sFileBase	= FileBase()
//		string		sDataDir	= DataDir() 
//	
//		string 	sPath	= sDataDir + sFileBase + num2Str( nCell ) + UFCom_IdxToTwoLetters( nIndex ) + UFPE_ksCFS_EXT 
//		// printf "\tGetPathFileExt( nIndex:%3d )  returns   '%s',    \tthis file does %s exist. \r", nIndex, sPath, SelectString(  UFCom_FileExists( sPath ) , "NOT", "" )
//		return	sPath
//	End
	
//	Function  /S	GetFileName()					// everything before the dot 
//	// builds and returns automatic file name from implicit current index  and base filename and cell, but  excluding  directory
//		string		sFileBase	= FileBase()
//		variable	nCell		= Cell()
//		nvar		gFileIndex	= root:uf:acq:cfsw:gFileIndex
//		return	sFileBase + num2str( nCell ) + UFCom_IdxToTwoLetters( gFileIndex ) 
//	End
	
	//==============================================================================================================================================================

Function		SearchAndSetLastUsedFile()
	nvar		gFileIndex		= root:uf:acq:cfsw:gFileIndex
	gFileIndex		= GetLastUsedFileFromHead( -1 )					// start with  -1 (=AA-1), increment repeatedly until file exists, then return index of previous (=last used) file
	// gFileIndex  	= GetLastUsedFileFromTail( kMAXINDEX_2LETTERS )	// start with ZZ+1, decrement repeatedly until file exists, then return this index  (=last used) file
	DataFileWSet( GetFileName() + UFPE_ksCFS_EXT )
	// printf "\tSearchAndSetLastUsedFile()	has computed gFileIndex:%3d   and has set  gsDataFileW:'%s' \r", gFileIndex, DataFileW()
End

static Function	 	GetLastUsedFileFromHead( nIndex )		
// build automatic file name converting index to two letters in the range from 0..26x26-1
// start at AA (=0) and INCREMENT index skipping all existing files, return index of  last  file name already used
// -- can overwrite an existing file it it comes after a gap, because it starts at the first  gap -> WE MUST CHECK EVERY INDEX , if it is empty  or if this file (maybe after a gap) already exists
//++ fast  when only few files are used (most likely)
	variable	nIndex
	do
		nIndex	+= 1
	while (  UFCom_FileExists( GetPathFileExt( nIndex ) ) && nIndex < UFCom_kANM_MAX_2LETTERS ) 
	if ( nIndex == UFCom_kANM_MAX_2LETTERS )
		 UFCom_FoAlert( ksACQ, UFCom_kERR_FATAL,  " All files with current name and cell number from AA to ZZ have been used ( " + GetPathFileExt( 0 ) + "  to   " + GetPathFileExt( UFCom_kANM_MAX_2LETTERS-1) + " ). " )
	endif
	// printf "\tGetLastUsedFileFromHead()  searching by incrementing from AA and returning %d \r", nIndex - 1 
	return  nIndex  - 1	 // loop has been left with index of first existing file, decrease by one to get last used. Minimum  return is -1  -> Run writes next file 0=AA 
End

static Function	 	GetLastUsedFileFromTail( nIndex )		
// build automatic file name converting index to two letters in the range from 0..26x26-1
// start at ZZ and DECREMENT index skipping all non-existing files, return index of  last  file name already used
// ++ can never overwrite an existing file
// -- does NOT use existing gaps (e.g. if 1 file ..ZZ exists it will block 675 gaps ..AA  - ..ZY), --very slow the first time when only few files are used (most likely)
	variable	nIndex
	do
		nIndex	-= 1
	while ( nIndex >= 0  &&  !  UFCom_FileExists( GetPathFileExt( nIndex ) ) ) // minimum  return is -1  --> Run writes next file 0=AA
	printf "\tGetLastUsedFileFromTail()  searching by decrementing from ZZ and returning %d \r", nIndex 
	return  nIndex 
End

////Function	 	NextFreeFileInc( nIndex )		
////// build automatic file name converting index to two letters in the range from 0..26x26-1
////// start at AA (=0) and INCREMENT index skipping all existing files, return index of  first file name not yet used
////	variable	nIndex
////	do
////		nIndex	+= 1
////	while (  UFCom_FileExists( GetPathFileExt( nIndex ) ) )	
////	return  nIndex
////End


static Function	 /S	GetPathFileExt( nIndex )
// builds and returns automatic file name (including global dir and base filename and cell) by converting the passed  'index'  into two letters in the range from 0..26x26-1
	variable	nIndex
	variable	nCell		= Cell()
	string		sFileBase	= FileBase()
	string		sDataDir	= DataDir() 

	string 	sPath	= sDataDir + sFileBase + num2Str( nCell ) + UFCom_IdxToTwoLetters( nIndex ) + UFPE_ksCFS_EXT 
	// printf "\tGetPathFileExt( nIndex:%3d )  returns   '%s',    \tthis file does %s exist. \r", nIndex, sPath, SelectString(  UFCom_FileExists( sPath ) , "NOT", "" )
	return	sPath
End

Function  /S	GetFileName()					// everything before the dot 
// builds and returns automatic file name from implicit current index  and base filename and cell, but  excluding  directory
	string		sFileBase	= FileBase()
	variable	nCell		= Cell()
	nvar		gFileIndex	= root:uf:acq:cfsw:gFileIndex
	return	sFileBase + num2str( nCell ) + UFCom_IdxToTwoLetters( gFileIndex ) 
End



	//==============================================================================================================================================================
	
	static strconstant	sBAK_EXT			= ".bak"
	
	static Function	Backup()
		nvar		gFileIndex		= root:uf:acq:cfsw:gFileIndex
		variable	bAutoBackup	= AutoBackup()
		string 	sPathFileExt	= GetPathFileExt( gFileIndex )
		//( string 	sPathBak	= UFCom_StripPathAndExtension( sPathFileExt ) + sBAK_EXT // save BAK in current dir  (=Userigor\ced), not in data dir (=\epc\data)
		string 	sPathBak	= UFCom_StripExtension( sPathFileExt ) + sBAK_EXT[1,3] // only one dot! Save BAK in same dir as original, i.e. in data dir (=\epc\data)
		string 	bf
		if ( bAutoBackup )
	
			CopyFile	/O	sPathFileExt as sPathBak
	
			if ( UFCom_DebugVar( "acq", "CfsWrite" ) )
				printf  "\t\tCFSWr  Backup()    '%s'  > '%s' \r",  sPathFileExt, sPathBak
			endif
		else
			if ( UFCom_DebugVar( "acq", "CfsWrite" ) )
				printf  "\t\tCFSWr  Backup() is turned off. No Backup is made of  '%s' .\r",  sPathFileExt
			endif
		endif
	End
	
	
