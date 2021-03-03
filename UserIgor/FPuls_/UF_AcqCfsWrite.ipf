////
////  UF_AcqCfsWrite.ipf 
//// 
//// CFS file write
////
//// Comments:
////
//// History:
// 
//#pragma rtGlobals=1									// Use modern global access method.
//
//#include "UFPE_Constants4"
//
//static constant		kEQUALSPACED	=  0
//static  constant		kCFS_NOT_OPEN	=  -1

//
//Function		CreateGlobalsInFolder_CfsWrite()
//// creates all folder-specific variables. To be used once from CreateGlobals() as the current data folder is changed and not restored
//	NewDataFolder  /O  /S root:uf:acq:cfsw
//
//	variable	/G	gFileIndex			= -1					// 0..26x26-1..will be converted to AA, AB....ZY, ZZ. and stored in 7. and 8. character of file name
//	variable	/G	gCFSHandle		= kCFS_NOT_OPEN		// for writing CFS file
//	string		/G	gsXUnitsInCfs		=  "ms"				// Use 'millisecs'  only in Cfs files for compatibility with Pascal version. Use 'seconds'  elsewhere to prevent Igor from  labeling the axis e.g. 'kms'  (KiloMilliSeconds)
//End
//

//Function  		InitializeCFSDescriptors( sFolder, sScript )
//// Define CFS data descriptor templates DSArray (data section descriptor)  and FileArray (file descriptor)  and reset all values. Must be called before UFPE_CfsCreateFile()
//// Store the script once in the file section.
//	string  	sFolder, sScript
//	variable	i, l
//	string  	llstDSDescriptors	= UFPE_LstDS0 + UFPE_LstDS1
//	// printf  "\t\t\t InitializeDescriptors()	\r"   
//
//	// Set  FILEVAR  file descriptors  -  the  FILEVAR  entries  in   InitializeCFSDescriptors()  and   CFSInitWrFile()  must match !
//	UFPE_CfsSetDescriptor( UFPE_kFILEVAR, UFPE_kFV_DATAFILEFROM,	"Data file from,INT2," +  ksFP_APP_NAME + ",0" )	//  Description, Type, Units, Size 
//	UFPE_CfsSetDescriptor( UFPE_kFILEVAR, UFPE_kFV_FILENM,  		GetFileName() + UFPE_ksCFS_EXT + ",LSTR,file,20")	// obsolete but kept for compatibility with Pascal programs...
//	UFPE_CfsSetDescriptor( UFPE_kFILEVAR, UFPE_kFV_DATAFILE,		"DataFile,LSTR,Data,20" )						// ...here is the current data file name stored, not above in the descriptor field
//
//	UFPE_CfsSetDescriptor( UFPE_kFILEVAR, UFPE_kFV_STIMFILE,  		"StimFile,LSTR,Stim,30" ) 
//	UFPE_CfsSetDescriptor( UFPE_kFILEVAR, UFPE_kFV_SWPPERFRM,	"SwpPerFrm,LSTR,-,20" )	
//	UFPE_CfsSetDescriptor( UFPE_kFILEVAR, UFPE_kFV_FRMPERBLK, 	"FrmPerProt,LSTR,-,20" )									// this is actually frames per block
//	UFPE_CfsSetDescriptor( UFPE_kFILEVAR, UFPE_kFV_HASPON, 		"HasPoN,LSTR,-,20" )	
//	UFPE_CfsSetDescriptor( UFPE_kFILEVAR, UFPE_kFV_SPECIFICCOMMENT,"Specific comment,LSTR,,"+ num2str(UFPE_kMAX_CFS_STRLEN) )	// usable string length is one shorter
//	UFPE_CfsSetDescriptor( UFPE_kFILEVAR, UFPE_kFV_LISTBLF,		"ListBLF,LSTR,," 		 + num2str( UFPE_kMAX_CFS_STRLEN ) )	// usable string length is one shorter
//	UFPE_CfsSetDescriptor( UFPE_kFILEVAR, UFPE_kFV_LISTTAPETIMES,	"ListTapeTimes,LSTR,," 	 + num2str( UFPE_kMAX_CFS_STRLEN ) )	// usable string length is one shorter
//	UFPE_CfsSetDescriptor( UFPE_kFILEVAR, UFPE_kFV_LISTPON,		"ListPoN,LSTR,," 		 + num2str( UFPE_kMAX_CFS_STRLEN ) )	// usable string length is one shorter
//
//	// Store the script once in the file section : reserve space for storing the script lines
//	for ( i = UFPE_kFV_FIRSTFREE; i < UFPE_kFV_SCRIPTBEGIN; i += 1 )
//		UFPE_CfsSetDescriptor( UFPE_kFILEVAR, i, "Spare,INT2,none,0" )
//   	endfor
//
//	variable	nLines
//	// 2005-0205	
//if ( ! bNEWFILEVARS )
//	nLines	= ItemsInList( sScript, "\r" )		// 1 script line = 1 UFPE_kFILEVAR line :  BAD space usage
//	for ( l = 0; l < nLines; l += 1 )	
//		i = UFPE_kFV_SCRIPTBEGIN + l
//		UFPE_CfsSetDescriptor( UFPE_kFILEVAR, i , "Scriptline" + num2str( l ) + ",LSTR,," + num2str( UFPE_kMAX_CFS_STRLEN ) ) // usable string length is one shorter
//   	endfor
//   	
//else
//	nLines	= ceil( strlen( sScript ) / ( UFPE_kMAX_CFS_STRLEN - 1 ) )
//	for ( l = 0; l < nLines; l += 1 )	
//		i = UFPE_kFV_SCRIPTBEGIN + l
//		UFPE_CfsSetDescriptor( UFPE_kFILEVAR, i , "ScriptBlock" + num2str( l ) + ",LSTR,," + num2str( UFPE_kMAX_CFS_STRLEN ) ) // usable string length is one shorter
//   	endfor
//   	
//endif
//
//
//	for ( i = UFPE_kFV_SCRIPTBEGIN + nLines; i < UFPE_kMAX_FILEVAR ; i += 1 )
//		UFPE_CfsSetDescriptor( UFPE_kFILEVAR, i, "Spare,INT2,none,0" )
//   	endfor
//
//	// Set  UFPE_kDSVAR  data section descriptors  -  the  UFPE_kDSVAR  entries  in   InitializeCFSDescriptors()  and  WriteHeader()  must match !  The order is defined in  'UFPE_LstDS' .
//	for ( i = 0;  i < ItemsInList( llstDSDescriptors ); i += 1 )
//		UFPE_CfsSetDescriptor( UFPE_kDSVAR,  i, StringFromList( i, llstDSDescriptors ) )				//  contains Description, Type, Units, Size 
//	endfor
//
//	for ( i =   ItemsInList( llstDSDescriptors );  i <  UFPE_kMAX_DSVAR; i += 1 )
//		UFPE_CfsSetDescriptor( UFPE_kDSVAR, i, "Spare,INT2,none,0" )	
//	endfor
//
//End      
//
//
//static Function		WriteDataSection( sFolder, wG, wIO, wVal, pr, bl, lap, fr, sw )		// PROTOCOL  AWARE  031007
//// break big waves (one per adc, all frames and sweeps together) into sections for  UFPE_CfsWriteData() (=into single sweeps) )
//// Limitation....writes always / only 'Adc' channels
//// 2003-0312b TelegraphGain() made independent of WriteMode
//// could probably be done more elegantly...............
//	string  	sFolder
//	wave  /T	wIO, wVal
//	wave	wG
//	variable	pr, bl, lap, fr, sw
//	variable	bWriteMode	= WriteMode()
//	nvar		gCFShnd		= root:uf:acq:cfsw:gCFSHandle		// 2003-0312 global , was local
//	variable	nRadDebgSel	= UFCom_DebugDepthSel()
//	variable	nSmpInt		= UFPE_SmpInt( sFolder )
//	variable	nCntAD		= wG[ UFPE_WG_CNTAD ]	
//	variable	BegPt		= UFPE_SweepBegSave( sFolder, pr, bl, lap, fr, sw )	
//	variable	EndPt		= UFPE_SweepEndSave( sFolder, pr, bl, lap, fr, sw )
//	variable	nPts			= EndPt - BegPt
//	variable	OldHnd		= gCFSHnd				// for debug printing
//	variable	c, nIO		= UFPE_IOT_ADC	
//
//	// STEP 1 :
//	// Get the telegraph gain by reading the big wave and store the values in  wave 'wIO' , from which they can be retrieved with  'UFPE_IO_GAINOLD'   and   ' YScale(c) '
//	for ( c = 0; c < nCntAD; c += 1 )
//		if ( UFPE_HasTG( wIO, nIO, c ) ) 												// This is a true Adc channel having a corresponding telegraph channel... 
//			UFPE_ioSet( wIO, nIO, c, UFPE_IO_GAIN, num2str(TelegraphGain(sFolder,wIO,nIO,c,BegPt)))// ...so store the gain value (measured and computed from wBig) indexed by Adc index in script 
//		elseif ( UFPE_HasTGMC( wIO, nIO, c ) ) 											// This is a true Adc channel having a corresponding MULTICLAMP telegraph channel...
//			UFPE_ioSet( wIO, nIO, c, UFPE_IO_GAIN, num2str(TelegraphGainMC( sFolder,wIO,nIO,c) ) )	// ...so store the gain value  which the AxoPatch MultiClamp has given
//		endif
//
//		if ( UFPE_iov( wIO, nIO, c, UFPE_IO_GAIN ) != UFPE_iov( wIO, nIO, c, UFPE_IO_GAINOLD )	)// Only if the gain has really changed do the time-consuming storage and update...
//			SetAxoGainInPanel( c, UFPE_iov( wIO, nIO, c, UFPE_IO_GAIN ) ) 					// Update the Gain Setvariable in the main Pulse panel
//			PossiblyAdjstSliderInAllWindows( sFolder )										// Can be commented out if it is too slow. Different approach would be to change YOfs slider like the YAxis  in DispDurAcq()  ???
//			UFPE_ioSet( wIO, nIO, c, UFPE_IO_GAINOLD,  UFPE_ios( wIO, nIO, c, UFPE_IO_GAIN ) )	// Remember that gain changes have been handled so that they will not be unnecessarily handled a 2. time 	
//		endif
//	endfor
//
//	// STEP 2 :  write the data into the CFS file
//	if ( bWriteMode )			
//
//		if ( gCFSHnd == kCFS_NOT_OPEN  )	
//			variable	bAppendData	= AppendData()
//			nvar		bIncremFile	= root:uf:acq:co:gbIncremFile
//			if ( bWriteMode )										// Do the automatic file name incrementation only when it is intended to really write a file, not when only in watch mode.
//				if ( ! bAppendData )
//					AutoBuildNextFilename( sFolder )						// 	Increment the automatically built file name (= go to next  fileindex ) only if the user does not want to append 
//				endif
//				if (  bAppendData  &&  bIncremFile ) 						// 	...OR  increment  after having executed  'Finish'  (bIncremFile=UFCom_TRUE)    EVEN  if the user actually  does NOT want to incremenent
//					AutoBuildNextFilename( sFolder )						//  ( Only when a new file is to be written for each run then increment  even if the user actually  does wants to append )
//					bIncremFile	= UFCom_FALSE
//				endif
//			endif
//			gCFShnd = CFSInitWrFile( sFolder, wIO, nCntAD )			// also sets global handle internally
//		endif
//			printf "\t\t\t\tCFSWriteDataSection( \t\t\tp:%d b:%d f:%d s:%d\t\tB:%7d \t~%7d\tPts:%4d   File WAS %s\tOPEN, CFSHnd before:%2d \t/ after:%2d\t  InitWrFile()\r", pr, bl, fr, sw, BegPt, EndPt, nPts, SelectString(OldHnd == kCFS_NOT_OPEN,"    ", "NOT"), Oldhnd , gCFShnd  
//		if ( nRadDebgSel > 2  &&  UFCom_DebugVar( "CfsWrite" ) )
//			printf "\t\t\t\tCFSWriteDataSection( p:%2d\tb:%2d\tf:%2d\ts:%2d\t-> BegP:%5d \tEndP:%5d\tPts:%4d)  File WAS %s\tOPEN, CFSHnd before:%2d \t/ after:%2d\t  InitWrFile()\r", pr, bl, fr, sw, BegPt, EndPt, nPts, SelectString(OldHnd == kCFS_NOT_OPEN,"    ", "NOT"), Oldhnd , gCFShnd  
//		endif
//
//		if  ( gCFShnd != kCFS_NOT_OPEN )
//
//			for ( c = 0; c < nCntAD; c += 1 )
//				string 	sBig	=  UFPE_ioFldAcqioio( sFolder, wIO, UFPE_IOT_ADC, c, UFPE_IO_NM )
//				WriteBlocks( sFolder, wIO, gCFShnd, sBig, c, BegPt, nPts, nSmpInt, nCntAD ) 
//			endfor
//																
//			WriteHeader( sFolder, wVal, gCFShnd, nPts, nSmpInt, bl, fr, sw, 0 )														
//			FinishDataSection( gCFShnd )
//	
//			if (  UFPE_ePon_( sFolder, bl ) ) 		
//				// write 'PoN' corrected data sweeps
//				WriteDataPoN( sFolder, wG, wIO, wVal, gCfsHnd, bl, fr, sw, BegPt, nPts, nSmpInt, nCntAD  )
//			endif
//																
//		endif
//																
//	endif
//
//	wG[ UFPE_WG_SWPWRIT ] += 1
//// 2005-1201
//	nvar	wgSwpWrit	= root:uf:acq:pul:svSwpsWrt0000
//	wgSwpWrit	 += 1
//	
//	return	gCFShnd
//End
//
//
//Function		WriteDataPoN( sFolder, wG, wIO, wVal, CfsHnd, bl, fr, sw, BegPt, nPts, SmpInt, nChans )
//// 2003-0312b  making the TelegraphGain() independent of WriteMode  seems here (=PoN trace) unnecessary
//	string  	sFolder
//	wave  /T	wIO, wVal
//	wave	wG
//	variable	CFShnd, bl, fr, sw,BegPt, nPts, SmpInt,  nChans
//	variable	nRadDebgSel	= UFCom_DebugDepthSel()
//	variable	c
//	string		sBig
//	if ( sw > 0  &&  sw == UFPE_eSweeps_( sFolder, bl ) - 1 )			// store 'PoN' only once after last sweep. If there is ony 1 sweep, don't store PoN.  Better: catch this earlier...) 
//		for ( c = 0; c < nChans; c += 1 )					// store 'PoN' data only of last sweep
//			// select wave to be stored depending on users choice: do PoverN for this channel or not (it is users responsibility that it is a true AD and not a telegraph..)
//			sBig	= SelectString( DoPoverN( sFolder, wIO, c ),  UFPE_ioFldAcqioio( sFolder, wIO, UFPE_IOT_ADC, c, UFPE_IO_NM ),    UFPE_ioFldAcqioPoNio( sFolder, wIO, UFPE_IOT_ADC, c, UFPE_IO_CHAN ) )	 
//			// printf "\t\t\t\tCFSW write   corrected \tDS(\tfr:%d, sw:%d)   c:%d   BegPt:%d   nPts:%d  '%s' \r",  fr, sw, c, BegPt, nPts, sBig
//			if ( nRadDebgSel > 2  &&  UFCom_DebugVar( "CfsWrite" ) )
//				printf "\t\t\t\tCFSW write   corrected \tDS(\tfr:%d, sw:%d)   c:%d   BegPt:%d   nPts:%d  '%s' \r",  fr, sw, c, BegPt, nPts, sBig
//			endif
//			WriteBlocks( sFolder, wIO, CFShnd, sBig, c, BegPt, nPts, SmpInt, nChans ) 
//		endfor
//		WriteHeader( sFolder, wVal, CFShnd, nPts, SmpInt,  bl, fr, sw, 1 )	// write PoverN corrected trailer after all channels have been processed 
//		FinishDataSection( CFShnd )
//	endif
//End
//
//
//Function		WriteBlocks( sFolder, wIO, CFShnd, sBig, c, BegPt, nPts, SmpInt, nChans ) 
//// writes 1 datasection (= 1 sweep) to CFS file. Datasection can be larger than 64KB, it is then split into blocks 
//// CFS handle, channel number, actual data section is used here,...
//	string  	sFolder
//	wave  /T	wIO
//	variable	CFShnd, c, BegPt, nPts, SmpInt, nChans
//	string		sBig
//	wave	wBig			= $sBig					// this is 'AdcN', 'PoNN'...
//	variable	nRadDebgSel	= UFCom_DebugDepthSel()
//	variable	nStartByteOffset							// offset in bytes from the start of the data section to the first byte of data for this channel...
//	variable	nBytes		= nPts * 2
//	variable	nBlockBytes, b, nBlocks = trunc( ( nBytes - 1) / UFPE_kCFSMAXBYTE ) + 1
//	variable	nIO			=  UFPE_IOT_ADC
//
//	for ( b = 0; b < nBlocks; b += 1 )
//		// Avoid memory consuming multiple unique names for each 'wSmall' , allow only temporarily for the Test display below 
//		// make /O /W /N=( UFPE_kCFSMAXBYTE )	$SmallWav( c, b, BegPt )	// 32K is largest CFS section...constructing the partial wave with...
//		// wave  	wSmall 		=		 	$SmallWav( c, b, BegPt )	// ..unique name is necessary only for the test display below
//		// print "\t each smallwav consumes 128KB : ", SmallWav( c, b, BegPt )
//		make /O /W /N=( UFPE_kCFSMAXBYTE )	root:uf:acq:cfsw:wSmall				// 32K is largest CFS section
//		wave	wSmall				= 	root:uf:acq:cfsw:wSmall
//		nBlockBytes = ( b == nBlocks - 1 ) ? nBytes - b * UFPE_kCFSMAXBYTE : UFPE_kCFSMAXBYTE
//		variable	code	= UFCom_UtilWaveCopy( wSmall, wBig, nBlockBytes / 2, BegPt + b * UFPE_kCFSMAXBYTE / 2, UFPE_kMAXAMPL / UFPE_kFULLSCL_mV ) 	// 2003-0525
//		if ( code )
//			printf "****Error: UFCom_UtilWaveCopy() \r"
//		endif
//
//			printf  "\t\t\t\t\tCFSWrDS   WriteBlocks       \t\t\t\t\tB:%7d \t\t\t\t\t\tADC[c:%d] in CEDch:%d  '%s'  StartByteOfs:%d  Endbyte:%d  (=%dBytes)\t \r",  BegPt, c, UFPE_iov( wIO, nIO, c, UFPE_IO_CHAN ), UFPE_ioFldAcqioio( sFolder, wIO, nIO,c, UFPE_IO_NM ),  nStartByteOffset, nStartByteOffset + nBytes, nBytes 
//		nStartByteOffset = c * 2 * nPts + b * UFPE_kCFSMAXBYTE 
//		if (  nRadDebgSel > 3  &&  UFCom_DebugVar( "CfsWrite" ) )
//			printf  "\t\t\t\t\tCFSWrDS   ADC[c:%d] in CEDch:%d  '%s'  StartByteOfs:%d  Endbyte:%d  (=%dBytes)\r",  c, UFPE_iov( wIO, nIO, c, UFPE_IO_CHAN ), UFPE_ioFldAcqioio( sFolder, wIO, nIO,c, UFPE_IO_NM ),  nStartByteOffset, nStartByteOffset + nBytes, nBytes
//		endif
//		// Avoid memory consuming multiple unique names for each 'wSmall' , allow only temporarily for the Test display below 
//		// print "\tUnique name is needed for wSmall", ch, b, BegPt, nPts;	dowindow /K $SmallWnd( c, b, BegPt );	display wsmall;	dowindow /C $SmallWnd( c, b, BegPt )
//		//  0 = write to current data section, Byte offset, number of bytes to write, wave buffer. Channels are written one after the other
//		UFPE_CfsWriteData( CFShnd, 0,  nStartByteOffset, nBlockBytes, wSmall, UFPE_ERRLINE ) 
//		// killwaves wSmall			// can kill only  when wave is not displayed
//	endfor
//		
//	 printf "\t\t\t\t\tCFSWrDS   WriteBlocks       \t\t\t\t\tB:%7d \t\t\tPts:%4d\tcio:%d   internal name:'%s'   user name:'%s' \r",  BegPt, nPts, c, UFPE_ioFldAcqioio( sFolder, wIO, nIO, c, UFPE_IO_NM ), UFPE_ios( wIO, nIO, c, UFPE_IO_NAME )
//	if ( nRadDebgSel > 3  &&  UFCom_DebugVar( "CfsWrite" ) )
//		 printf "\t\t\t\t\tCFSWrDS   c:%d   internal name:'%s'   user name:'%s' \r", c, UFPE_ioFldAcqioio( sFolder, wIO, nIO, c, UFPE_IO_NM ), UFPE_ios( wIO, nIO, c, UFPE_IO_NAME )
//	endif
//
//	// ..offset in bytes from the start of the data section to the first byte of data for this channel,  Points,  YScale,  YOffset,  XScale,  XOffset, print errors only or also infos
//	UFPE_CfsSetDSChan( CFShnd, c, 0, c * 2  *nPts, nPts, YScale( wIO, c ), 0, SmpInt / UFPE_kMILLITOMICRO, 0, UFPE_ERRLINE )
//	if ( nRadDebgSel > 3  &&  ( UFCom_DebugVar( "CfsWrite" )  ||  UFCom_DebugVar( "Telegraph" ) ) )
//		printf "\t\t\t\t\tCFSWrDS   UFPE_CfsSetDSChan()   c:%d  startbyte:\t%8d\t  endbyte:\t%8d\t   yScale (<Gain<Telegraph):%g \r", c, c *2*nPts, c * 2*nPts + 2*nPts, YScale( wIO, c )
//	endif
//         // printf "\t\t\t\t\tCFSWrDS   UFPE_CfsSetDSChan()   c:%d  startbyte:\t%8d\t  endbyte:\t%8d\t   yScale (<Gain<Telegraph):%g \r", c, c *2*nPts, c * 2*nPts + 2*nPts, YScale( c )
//	// UFPE_CfsCommitFile( CFShnd, UFPE_ERRLINE )	// takes ~2us / data , removed because it  decreases maximum data rate by about 30% (very rough estimate) 
//End	
//
//// Avoid memory consuming multiple unique names for each 'wSmall' , allow only temporarily for the Test display below 
//// Static	Function   /S	SmallWav( ch, bl, BegPt )
////	variable	ch, bl, BegPt
////	return	"WavSmall_ch_" + num2str( ch ) + "_bl" + num2str( bl ) + "_bg" + num2str( BegPt ) 
//// End
//// Static	Function   /S	SmallWnd( ch, bl, BegPt )
////	variable	ch, bl, BegPt
////	return	"WndSmall_ch_" + num2str( ch ) + "_bl" + num2str( bl ) + "_bg" + num2str( BegPt )	
//// End
//
//
//constant bNEWFILEVARS =  1// 2005-02-05    set to 1 after testing   and eliminate.....
//
//Function		CFSInitWrFile( sFolder, wIO, nChans )
//	string  	sFolder
//	wave  /T	wIO
//	variable	nChans				// number of channels (PascalPulse: 1 or 2,  IGOR: any number )
//	nvar		gCFSHandle	= root:uf:acq:cfsw:gCFSHandle
//	nvar		gFileIndex		= root:uf:acq:cfsw:gFileIndex
//	svar		gsXUnitsInCfs	= root:uf:acq:cfsw:gsXUnitsInCfs
//	string		sGenComm	= GeneralComment()
//	string  	sSpecComm	= SpecificComment()
//	variable	nRadDebgSel	= UFCom_DebugDepthSel()
//	string		sScriptPath	= ScriptPath( sFolder )
//	string		bf, sChanName						// channel name,  used by SetFileChan from CFS
//	string		sOChar		= "O"				// write 'O' for original data
//	variable	c
//	string		sPath		= GetPathFileExt( gFileIndex )
//	variable	bFileExists		= UFCom_FileExists( sPath )
//	string		sBuf
//	
//	// Sould but does not control disk access, which is about 11..12 us/WORD for any value from 1 to 1024 (2001, Win95, 350MHz Pentium, file of 360KB) 
//	variable	CFSBlockSize = 1 // 1=slow disk access , 1~11.5us/pt, 4~11.5, 16~ 11.8, 64~11.6, 128~11.8, 256~11.2, 512~12, 1024~12 )
//	variable	CFShnd = UFPE_CfsCreateFile( sPath, sGenComm, CFSBlockSize , nChans, UFPE_kMAX_DSVAR, UFPE_kMAX_FILEVAR, UFPE_ERRLINE ) // sizes of fileArray and DSArray: all as in PatPul 
//	if ( CFShnd > 0 )								// file creation was successful
//		if ( nRadDebgSel > 0  &&  UFCom_DebugVar( "CfsWrite" ) )
//			printf  "\t\tCFSWr InitWrFile(Cfs/AdcChans:%d)    UFPE_CfsCreateFile() opens '%s' and returns CFSHandle %d . File did %s exist. \r", nChans, sPath, CFShnd, SelectString( bFileExists, "NOT", "" )
//		endif
//		gCFSHandle =  CFShnd 					// set global   AND  return  value (below)
//
//		for ( c = 0; c < nChans; c += 1 )
//			variable	nIO	= UFPE_IOT_ADC
//			// printf  "\t\t\t\tCFSWr InitWrFile()   ADC[idxch=ch:%d/%d] in CEDch:%d  internal name:'%s'   user name:'%s'   YUnits:'%s'   XUnitInCfs:'%s'\r", c, nChans, UFPE_iov( wIO, nIO, c, UFPE_IO_CHAN ), UFPE_ioFldAcqioio( wIO, nIO,c, UFPE_IO_NM ),  UFPE_ios( wIO, nIO, c, UFPE_IO_NAME ), UFPE_ios( wIO, nIO, c, UFPE_IO_UNIT ),  gsXUnitsInCfs
//			if ( nRadDebgSel > 2  &&  UFCom_DebugVar( "CfsWrite" ) )
//				printf  "\t\t\t\tCFSWr InitWrFile()   ADC[idxch=ch:%d/%d] in CEDch:%d  internal name:'%s'   user name:'%s'   YUnits:'%s'   XUnitInCfs:'%s'\r", c, nChans, UFPE_iov( wIO, nIO, c, UFPE_IO_CHAN ), UFPE_ioFldAcqioio( sFolder, wIO, nIO,c, UFPE_IO_NM ),  UFPE_ios( wIO, nIO, c, UFPE_IO_NAME ), UFPE_ios( wIO, nIO, c, UFPE_IO_UNIT ),  gsXUnitsInCfs
//			endif
//			// CFS handle, channel number, channelname, Y units (=current or voltage), X units (=time), data saved as 2 byte integers,...
//			// ...equalspaced data (=not matrix), INT2 data with no intervening data (=2), last parameter is irrelevant in equalspaced mode (see PatPul)
//			sChanName =  UFPE_ios( wIO, nIO, c, UFPE_IO_NAME )  
//			if ( strlen( sChanName ) == 0 )											//  If channel name is missing...
//				sChanName	= UFPE_ioTNm( nIO ) + num2str( UFPE_iov( wIO, nIO, c, UFPE_IO_CHAN) )		// ..supply a default channel name because ReadCFS needs one
//			endif
//			UFPE_CfsSetFileChan( CFShnd, c,  sChanName, UFPE_ios( wIO, nIO, c, UFPE_IO_UNIT ), gsXUnitsInCfs, UFPE_kINT2, kEQUALSPACED, 2, 0, UFPE_ERRLINE )
//		endfor
//
//		//? The  UFPE_kFILEVAR  entries  in   InitializeCFSDescriptors()  and   CFSInitWrFile()  must match !
//		UFPE_CfsSetVarVal( CFShnd, UFPE_kFV_DATAFILEFROM,	UFPE_kFILEVAR, 0, ksFP_VERSION , UFPE_ERRLINE)				// data section variable 0 stores version number	e.g. '301c'
//		UFPE_CfsSetVarVal( CFShnd, UFPE_kFV_FILENM,			UFPE_kFILEVAR, 0, sOChar, UFPE_ERRLINE)						// data section variable 1 stores 'O' for original data
//		UFPE_CfsSetVarVal( CFShnd, UFPE_kFV_DATAFILE, 		UFPE_kFILEVAR, 0, DataFileW(), UFPE_ERRLINE )					// DataFile
//		UFPE_CfsSetVarVal( CFShnd, UFPE_kFV_STIMFILE,			UFPE_kFILEVAR, 0,  UFCom_StripPathAndExtension( sScriptPath ), UFPE_ERRLINE )	// StimFile
//		variable	b = 0
//		UFPE_CfsSetVarVal( CFShnd, UFPE_kFV_SWPPERFRM,		UFPE_kFILEVAR, 0, num2str( UFPE_eSweeps_( sFolder, b ) ), UFPE_ERRLINE ) 	// obsolete and useless as it applies only to block 0
//
//		variable	nFrmPerBlk = UFPE_eFrames_( sFolder, b )
//		UFPE_CfsSetVarVal( CFShnd, UFPE_kFV_FRMPERBLK,		UFPE_kFILEVAR, 0, num2str( nFrmPerBlk ), UFPE_ERRLINE ) 			// obsolete and useless as it applies only to block 0
//
//		variable	bHasPoN	 = UFPE_ePon_( sFolder, b ) 												// 2003-0312 since the script is stored in the CFS file it is possible (and more reliably) to extract 'HasPon?' directly from script
//		UFPE_CfsSetVarVal( CFShnd, UFPE_kFV_HASPON, 			UFPE_kFILEVAR, 0, num2str( bHasPoN ), UFPE_ERRLINE ) 			// obsolete and useless as it applies only to block 0
//		UFPE_CfsSetVarVal( CFShnd, UFPE_kFV_SPECIFICCOMMENT,	UFPE_kFILEVAR, 0, sSpecComm, UFPE_ERRLINE ) 					// specific comment
//		
//	   	// Store the script once in the file section : Fill in the data = store the script lines 
//		variable	i, l, nLines
//		string  	sLine
//		string		sScriptTxt		= ScriptTxt( sFolder )
//
//if ( ! bNEWFILEVARS )
//		// 1 script line = 1 UFPE_kFILEVAR line :  BAD space usage
//		nLines	= ItemsInList( sScriptTxt, "\r" )
//		for ( l = 0; l < nLines; l += 1 )	
//			i 	= UFPE_kFV_SCRIPTBEGIN + l
//			sLine	= StringFromList( l, sScriptTxt, "\r" )
//			// printf  "\t\tCFSWr InitWrFile(chans:%d) \tl :%3d / %3d ->\t i :%3d    '%s'  \r", nChans, l,  nLines,  i, sLine
//			if ( i < UFPE_kMAX_FILEVAR )										
//	   			UFPE_CfsSetVarVal(  CFSHnd, i, UFPE_kFILEVAR, 0, sLine, UFPE_ERRLINE )	
//			endif
//		endfor
//else
//		nLines	= ceil( strlen( sScriptTxt ) / ( UFPE_kMAX_CFS_STRLEN - 1 ) )						// 2005-0205 store scripts in blocks..
//		for ( l = 0; l < nLines; l += 1 )												// ..store multiple script lines in 1 UFPE_kFILEVAR line
//			i 	= UFPE_kFV_SCRIPTBEGIN + l								// we can now store scripts up to appr. 16KB (64 lines x 252 bytes) 
//			sLine = sScriptTxt[   l *  ( UFPE_kMAX_CFS_STRLEN - 1 ) ,  ( l + 1 ) *  ( UFPE_kMAX_CFS_STRLEN - 1 )  - 1 ] 
//			// printf  "\t\tCFSWr InitWrFile(chans:%d) \tl :%3d / %3d ->\t i :%3d    '%s'  \r", nChans, l,  nLines,  i, sLine
//			if ( i < UFPE_kMAX_FILEVAR )										
//	   			UFPE_CfsSetVarVal(  CFSHnd, i, UFPE_kFILEVAR, 0, sLine, UFPE_ERRLINE )	
//			endif
//		endfor
//endif
//
//		if ( i >= UFPE_kMAX_FILEVAR )											
//   			sprintf sBuf, "Scripts is too long to be stored entirely in CFS file. Truncated at line %d of %d . ", UFPE_kMAX_FILEVAR, i
//   			 UFCom_FoAlert( sFolder, UFCom_kERR_IMPORTANT, sBuf )
//   		endif
//   		
//		if ( nRadDebgSel > 2  &&  UFCom_DebugVar( "CfsWrite" ) )
//			printf "\t\t\t\tWr CFSInitWrFile()    UFPE_CfsSetVarVal()  \r"
//		endif	
//	else
//		 UFCom_FoAlert( sFolder, UFCom_kERR_FATAL,  "Cannot open CFS path '" + sPath + "' " )
//		CFShnd = kCFS_NOT_OPEN
//	endif
//	return CFShnd	// positive: file creation OK, negative: file creation error code ,   AND  also set global  (above)
//End
//
//
//Function		WriteHeader(  sFo, wVal, hnd, nPts, SmpInt, bl, fr, sw, pon )
//	string  	sFo
//	wave	/T	wVal
//	variable	hnd, nPts, SmpInt, bl, fr, sw, pon 
//	string		bf
//	variable	SampleFreq	= 1000 /  SmpInt 			// 2004-0202  SF =  Round( 1000 /  SmpInt ) 	was  wrong as it clips at SmpInt=1000us
//	variable	Tim			= TimeElapsed()				// these are the actual ticks counted. Another possibility: Compute time of this sweep from script including blank section.
//	variable	Duration		= Round( nPts * SmpInt / 1000 )
//	variable	Start			= 0
//	variable	PreVal		= 2						// minimum CED1401 clock prescaler value. Useless but kept for compatibility
//	variable	CountVal		= Round( 100 * SmpInt / 1000 )	//  Pulse / StimFit has 10 
//	variable	Mode		= UFPE_ERRLINE
//	// printf  "\t\t\t\tCFSWriteHeader(   hnd:%d  nPts:%d   SmpInt%g  blk:%2d/%2d   fr:%2d/%2d    sw:%2d/%2d  PoN:%d/%d )   UFPE_CfsSetVarVal   18x  \r", hnd, nPts, SmpInt, bl, UFPE_eBlocks( sFo ), fr, eFrames(bl), sw,eSweeps(bl), pon, ePon(bl)  
//
//	// The  UFPE_kDSVAR  entries  in   InitializeCFSDescriptors()  and  WriteHeader()  must match ! The order is defined in  'UFPE_LstDS' .
//	// CFS handle, var number=index, which array, data section, string or variable value (as string) 
//	UFPE_CfsSetVarVal( hnd,  UFPE_DS_SMPRATE, 	UFPE_kDSVAR, 0, num2str( SampleFreq ),				Mode )
//	UFPE_CfsSetVarVal( hnd,  UFPE_DS_TIMEFRM1, 	UFPE_kDSVAR, 0, num2str( Tim ),					Mode )
//	UFPE_CfsSetVarVal( hnd,  UFPE_DS_FRMDUR, 	UFPE_kDSVAR, 0, num2str( Duration ),				Mode )
//	UFPE_CfsSetVarVal( hnd,  UFPE_DS_BEG1, 		UFPE_kDSVAR, 0, num2str( Start ),					Mode )
//	UFPE_CfsSetVarVal( hnd,  UFPE_DS_DUR1, 		UFPE_kDSVAR, 0, num2str( Duration ),				Mode )
//	UFPE_CfsSetVarVal( hnd,  UFPE_DS_PRE, 		UFPE_kDSVAR, 0, num2str( PreVal ),					Mode )
//	UFPE_CfsSetVarVal( hnd,  UFPE_DS_COUNT, 		UFPE_kDSVAR, 0, num2str( CountVal ),		 		Mode )
//	UFPE_CfsSetVarVal( hnd,  UFPE_DS_PROTO, 		UFPE_kDSVAR, 0, UFPE_vGetS( sFo, wVal, "Protocol", "Name" ), Mode )
//	UFPE_CfsSetVarVal( hnd,  UFPE_DS_BLOCK, 		UFPE_kDSVAR, 0, num2str( bl ),						Mode )		
//	UFPE_CfsSetVarVal( hnd,  UFPE_DS_FRAME, 		UFPE_kDSVAR, 0, num2str( fr ),						Mode )			
//	UFPE_CfsSetVarVal( hnd, UFPE_DS_SWEEP, 		UFPE_kDSVAR, 0, num2str( sw ),					Mode )
//	UFPE_CfsSetVarVal( hnd, UFPE_DS_PON, 		UFPE_kDSVAR, 0, num2str( pon ),					Mode )		
//	UFPE_CfsSetVarVal( hnd, UFPE_DS_MAXBLOCK,	UFPE_kDSVAR, 0, num2str( UFPE_eBlocks( sFo ) ), 		Mode )	
//	UFPE_CfsSetVarVal( hnd, UFPE_DS_MAXFRAME, 	UFPE_kDSVAR, 0, num2str( UFPE_eFrames_( sFo, bl) ),	Mode )		
//	UFPE_CfsSetVarVal( hnd, UFPE_DS_MAXSWEEP, 	UFPE_kDSVAR, 0, num2str( UFPE_eSweeps_( sFo, bl) ),	Mode )		
//	UFPE_CfsSetVarVal( hnd, UFPE_DS_HASPON, 		UFPE_kDSVAR, 0, num2str( UFPE_ePon_( sFo, bl) ),		Mode )	// 15	
//End
//
//
//Function		FinishDataSection( CFShnd )
//	variable	CFShnd
//	variable	nRadDebgSel	= UFCom_DebugDepthSel()
//	string		bf
//	// write complete data section to disk, 0 means append to end of file,  don't care about 16 flags
//	UFPE_CfsInsertDS( CFShnd, 0, UFPE_kNOFLAGS, UFPE_ERRLINE ) // 0: write complete data section to disk by appending to end of file, 
//	//if ( nRadDebgSel > 1  &&  UFCom_DebugVar( "CfsWrite" ) )
//	       printf  "\t\t\t\t\tCFSWr FinishDataSection(CFShnd:%d)   UFPE_CfsInsertDS()..  \r", CFShnd 
//	//endif
//End
//
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////   TELEGRAPH  CHANNELS  during  CFSWrite
//
//static constant	TOLERANCE				= 0.2		// tolerance for acceptance of a value, z.B: ERR(5.2-5.3), OK(5.3-5.7) 
//static constant	cADCGAIN_OUT_OF_TOLER	= 1.0		// returned when read value lies between the expected values 		(1.0001 could be used as marker) 
//static constant	cADCGAIN_OUT_OF_RANGE	= 1.0		// returned to avoid horrible values when telegraph inputs not plugged	(1.0002 could be used as marker) 
//
//
//Static  Function	YScale( wIO, c )
//// converts Gain( Adc channel number in script )  into  scale value( index is counted up 0,1,2.. ) .  Needed  in CFSWrite
//	wave  /T	wIO
//	variable	c
//	return	UFPE_kFULLSCL_mV / UFPE_kMAXAMPL / UFPE_iov( wIO, UFPE_IOT_ADC, c, UFPE_IO_GAIN )
//
//End	
//	
//Function		TelegraphGainPreliminary( sFolder, wG, wIO )
//// Get all telegraph gains early before the acq starts so that the Y axis can also already be adjusted before the acq starts. 
//	string  	sFolder
//	wave	wG
//	wave  /T	wIO
//	string		bf
//	variable	Chan, TGChan, TGMCChan					// true channel numbers
//	variable	c, nIO	= UFPE_IOT_ADC
//	variable	nCntAD	= wG[ UFPE_WG_CNTAD ]	
//	for ( c = 0; c < nCntAD; c += 1 )
//		Chan		= UFPE_iov( wIO, nIO, c, UFPE_IO_CHAN ) 
//		if (  UFPE_HasTG( wIO, nIO, c ) )
//			TGChan	= UFPE_iov( wIO, nIO, c, UFPE_IO_TGCH ) 
//			UFPE_ioSet( wIO, nIO, c, UFPE_IO_GAIN, num2str( TelegraphGainOnce( sFolder, wIO, nIO, c ) ) )			// Get the telegraph gain before the acq starts so that the y axis can be adjusted 
//			//if ( UFCom_DebugDepthSel() > 2  &&  DebugSection() & UFCom_kDBG_TELEGRAPH )
//			if ( UFCom_DebugVar( "Telegraph" ) )
//				printf "\t\t\t\tTelegraphGainPreliminary() \tFound AD %d  with   \tTGChan %d.      \tSetting Gain: %s  \r",  Chan,  TGChan, UFPE_ios( wIO, nIO, c, UFPE_IO_GAIN ) 
//			endif
//		endif
//		if (  UFPE_HasTGMC( wIO, nIO, c ) )
//			TGMCChan	= UFPE_iov( wIO, nIO, c, UFPE_IO_TGMCCH )
//			UFPE_ioSet( wIO, nIO, c, UFPE_IO_GAIN, num2str( TelegraphGainMC( sFolder, wIO, nIO, c ) ) )					// Get the MC telegraph gain before the acq starts so that the y axis can be adjusted 
//			//if ( UFCom_DebugDepthSel() > 2  &&  DebugSection() & UFCom_kDBG_TELEGRAPH )
//			if ( UFCom_DebugVar( "Telegraph" ) )
//				printf "\t\t\t\tTelegraphGainPreliminary() \tFound AD %d  with   \tTGMCChan %d.  \tSetting Gain: %s  \r",  Chan,  TGMCChan, UFPE_ios( wIO, nIO, c, UFPE_IO_GAIN )  
//			endif
//		endif
//	endfor
//End
//
//
//Static  Function	TelegraphGainOnce( sFolder, wIO, nIO, c )
//// Get right now 1 value from the Adc so that the telegraph gains are known before the acq starts so that the Y axis can be adjusted before the acq starts. 
//// This works for any true Adc channel having a corresponding voltage controlled telegraph channel (not for a MultiClamp!)  .  Gain is returned from  Axopatch in mV / pA or mV / mV 
//	string  	sFolder
//	wave  /T	wIO
//	variable	nIO, c			 												// ioch is linear index in script
//	variable	nTGChan		= UFPE_TGChan( wIO, nIO, c )									//  nTGChan is true TG  channel number in script
//	variable	ch			= UFPE_iov( wIO, nIO, c, UFPE_IO_CHAN )								// ch is true Adc channel number in script
//	variable	AdcValue		= 0
//	string 	command		= "ADC, " + num2str(  nTGChan ) + ";"						// get right now 1 value from the Adc
//	if ( UFP_CedTypeOf()  != UFCom_kNOTFOUND )												// check if Ced is open
//		AdcValue	= UFP_CedGetResponse( command, command, 0 ) * UFPE_kFULLSCL_mV / UFPE_kMAXAMPL	// last param is 'ErrMode' : display messages or errors
//	endif
//	variable	Gain 			= TGAdc2Gain( sFolder, AdcValue, nTGChan, ch )
//	string	 	bf
////	if ( UFCom_DebugDepthSel() > 2  &&  DebugSection() & UFCom_kDBG_TELEGRAPH )
//	if ( UFCom_DebugVar( "Telegraph" ) )
//		printf "\t\t\t\tTelegraphGainOnce(\tnIO:%d  c:%d  '%s' )\t\t\tAdc ch:%2d  is controlled by TG:%2d\t%.2lf V\tY:%8.3lf \t->TGGain:%7.2lf   \t \r", nIO, c, command, ch, nTGChan, AdcValue / 1000,  AdcValue,  Gain
//	endif
//	return	Gain
//End	
//
//
//static Function	TelegraphGain( sFolder, wIO, nIO, c, BegPt )
//// This works for any true Adc channel having a corresponding voltage controlled telegraph channel (not for a MultiClamp!) . 
//// Gain is returned from  Axopatch in mV / pA or mV / mV  . This function is to be called every time when any true AD channel (not a Telegraph) has sampled data ready..
//	string  	sFolder
//	wave  /T	wIO
//	variable	nIO, c, BegPt	 									// ioch is linear index in script
//	nvar		gnCompress	= $"root:uf:" + sFolder + ":co:gnCompressTG"
//	variable	ch			= UFPE_iov( wIO, nIO, c, UFPE_IO_CHAN )				// ch is true Adc channel number in script
//	variable	nTGChan		= UFPE_TGChan( wIO, nIO, c )					//  nTGChan is true TG  channel number in script
//	string		sTGNm		= FldAcqioTgNm( sFolder, nTGChan ) 
//	wave  	wBig 		= $sTGNm								// this is 'AdcN' but only for telegraph channels
//	variable	AdcValue		= wBig[ BegPt / gnCompress ]
//	variable	Gain 			= TGAdc2Gain( sFolder, AdcValue, nTGChan, ch )
//	string	 	bf
////	if ( UFCom_DebugDepthSel() > 2  &&  DebugSection() & UFCom_kDBG_TELEGRAPH )
//	if ( UFCom_DebugVar( "Telegraph" ) )
//		printf "\t\t\t\tTelegraphGain( \tnIO:%d c:%d ) sTGNm:\t%s\tAdc ch:%2d  is controlled by TG:%2d\t%.2lf V\tY:%8.3lf \t->TGGain:%7.2lf   \tBgP\t:%11d \t/ %8.2lf \t \r", nIO, c, UFCom_pd( sTGNm,6), ch, nTGChan, AdcValue / 1000, AdcValue,  Gain, BegPt, BegPt/gnCompress
//	endif
//	return	Gain
//End	
//
//
//static Function	TGAdc2Gain( sFolder, AdcValue, nTGChan, ch )
//	string  	sFolder
//	variable	AdcValue, nTGChan, ch 
//	string		bf
//	variable	GainVoltage	= AdcValue / 1000
//	variable	index			= round( 2 * GainVoltage )
//	//    corresponding signal in V; see Axopatch 200 manual for scaling of telegraph outputs
//	//						Index		  0   1   2   3   4     5     6      7     8      9     10    11    12    13
//	//						GainVoltage	  x   x    x    x  2.0  2.5  3.0  3.5  4.0  4.5   5.0   5.5   6.0   6.5		// Volt
//	variable	Gain 	= str2num( StringFromList( index, " 1;  1;  1;  1;  .5;   1;    2;     5;   10;  20;   50;  100; 200; 500 " ) )	// mV / pA or mV / mV   
//	if (  index < 4 || 13 < index )
//		Gain = cADCGAIN_OUT_OF_RANGE
//		sprintf bf, "TelegraphGainVoltage of TG chan %d (controlling Adc chan %d)  \t%.2lf V is out of allowed range ( %.1lf ...%.1lf V ). Gain %.1lf is returned. ", nTGChan, ch, GainVoltage, 2 -TOLERANCE, 6.5 +TOLERANCE, Gain
//		 UFCom_FoAlert( sFolder, UFCom_kERR_IMPORTANT,  bf )
//	elseif ( abs( index / 2 - GainVoltage ) > TOLERANCE ) 
//		Gain = cADCGAIN_OUT_OF_TOLER
//		sprintf bf, "TelegraphGainVoltage of TG chan %d (controlling Adc chan %d)  \t%.2lf V is out of tolerance ( %.1lf, %.1lf....%.1lf V +-%.1lf V ). Gain %.1lf is returned. ", nTGChan, ch, GainVoltage, 2, 2.5, 6.5, TOLERANCE, Gain
//		 UFCom_FoAlert( sFolder, UFCom_kERR_IMPORTANT,  bf )
//	endif
//	return	Gain
//End	
//
//// 2004-0927 TG without MC700TG XOP: works only partly (to retrieve gain the MCC700 channel must be switched which is not acceptable)
////static constant        	kMC700_MODEL	= 0 ,   kMC700_SERIALNUM	= 1 ,  kMC700_COMPORT = 2 ,   kMC700_DEVICE = 3 ,  kMC700_CHANNEL = 4
////static strconstant    	lstMC700_ID		= "Model;Serial#;COMPort;Device;Channel;"	// Assumption : Order is MoSeCoDeCh (same as in XOP)
//static constant		kMC700_A		= 0 , kMC700_B	= 1
//static strconstant	kMC700_MODELS	= "700A;700B"
////static constant	kMC700_MODE_VC	= 0 ,   kMC700_MODE_CC	= 1
//static strconstant	kMC700_MODES	= "VC;IC;I=0"
//
//// ASSUMPTION: Same separators ',;' and same entries 'HWTyp, SerNum, Port, AxoBus, Chan, Mode, Alpha, ScaleFct, Units' as in IGOR 'BreakInfo()' 
//
//
//Static Function	TelegraphGainMC( sFolder, wIO, nIO, c )		
////  Get and return the gain value  from the AxoPatch MultiClamp 
//// ASSUMPTION: Same separators ' , ; ' and same entries 'HWTyp, SerNum, Port, AxoBus, Chan, Mode, Alpha, ScaleFct, Units' as in    'UFP_MCTgPickupInfo()/UpdateDisplay()'  
//
//// If the user specified in the script simple channel specs e.g. '1'    then check that there are only 2 channels available (=1 MCC700) and use it
//// If the user specified extended channel specs e.g. '1_700A_Port_X_AxoBus_Y'   or  '2_700B_SN_xxxx'    then compare them with the available units: if they match  OK , if not print the  desired and the available identifications
//	string  	sFolder
//	wave  /T	wIO
//	variable	 nIO, c 																// ioch is linear index in script
//	string  	sTGChan			= TGMCChanS( wIO, nIO, c )								// e.g. '1'  or  '2'  or  '2_700A_Port_1_AxoBus_0'  or  '1_700B_SN_0'	// simple or extended spec
//	variable	ch				= UFPE_iov( wIO, nIO, c, UFPE_IO_CHAN )								// ch is true channel number in script
//	variable	Gain				= 0
//	variable	nCode
//	variable	MCTgChan 
//string		sMCTgChannelInfo	= UFP_MCTgPickupInfo()
//	variable	MCTgChansAvailable	= ItemsInList( sMCTgChannelInfo )
//	// printf "\t\tTelegraphGainMC( ioch:%d = Adc%d ) \tPickupInfo returns Chans avail: %d   '%s' \r", ioch, ch, MCTgChansAvailable, sMCTgChannelInfo
//
//	string		sOneChannelInfo, s700AB//, bf
//	variable	rTyp, rSerNum, rComPort, rAxoBus, rChan, rMode, rMCGain, rSclFactor					// the specifiers which the MC700 has transmitted, extracted from  'PickUpInfo'
//	string		rsSclFactorUnits
//	variable	rScrTyp, rScrSerNum, rScrComPort, rScrAxoBus, rScrChan							// the specifiers extracted from script
//
//	if ( CheckAvailableTelegraphChans( sFolder, sTGChan, MCTgChansAvailable ) == UFCom_kERROR )
//		 UFCom_FoAlert( sFolder, UFCom_kERR_SEVERE, "MultiClamp Telegraph channel error.  Gain = 1 is returned for channel  Adc " + num2str( ch )  + " and  'TGMCChan = " + sTGChan + "' . " ) 
//		return	1		// this is the default gain
//	endif
//
//	nCode	= CheckSimpleSpecAgainstTGCnt( sFolder, sTGChan, rScrChan, MCTgChansAvailable ) 			// extract the only (= the channel) specifier  from script and  make sure that there are exactly 2 channels available
//
//	if ( nCode  == UFCom_kERROR )															// there were not exactly 2 available telegraph channels : we don't know how to connect
//
//		 UFCom_FoAlert( sFolder, UFCom_kERR_SEVERE, "MultiClamp Telegraph channel error.  Gain = 1 is returned for channel  Adc " + num2str( ch )  + " and  'TGMCChan = " + sTGChan + "' . " ) 
//		return	1		// this is the default gain
//
//	elseif ( nCode == UFCom_TRUE )															// OK : we have found a simple spec and  exactly 2 available telegraph channels 
//
//		for ( MCTGChan = 0;  MCTGChan < MCTgChansAvailable;  MCTgChan += 1 )
//			sOneChannelInfo	= StringFromList( MCTGChan, sMCTgChannelInfo )
//			if ( BreakInfo( sOneChannelInfo, rTyp, rSerNum, rComPort, rAxoBus, rChan, rMode, rMCGain, rSclFactor, rsSclFactorUnits )  !=  9 )
//				UFCom_DeveloperError( "Expected 9 entries in  MCTG info string '" + sOneChannelInfo + "' .  AllChans: " + sMCTgChannelInfo ) 
//			endif	
//			if ( rChan == rScrChan )													// it is sufficient to check the channel as there are only 2 channels 
//				Gain	= rMCGain * rSclFactor
//				if ( rTyp ==  kMC700_A )
//					sprintf s700AB, "CP:%3d    AB:%3d  ", rComPort, rAxoBus
//				else
//					sprintf s700AB, "SN:%15d", rSerNum
//				endif
////				if ( UFCom_DebugDepthSel() > 0   &&  DebugSection() & UFCom_kDBG_TELEGRAPH )
//				if ( UFCom_DebugVar( "Telegraph" ) )
//					printf "\t\tTelegraphGainMC( nIO:%d, c:%d = Adc%d, sTGChan:\t%s\t)  %s \t%s\tTGCh:%2d\t'%s'\t   Gn:\t%7.2lf\tSc: %.1lf %s\t -> Gain: %5.1lf\t... \r", nIO, c, ch, UFCom_pd( sTGChan, 22), StringFromList( rTyp, kMC700_MODELS),  s700AB, rChan, StringFromList( rMode,kMC700_MODES), rMCGain, rSclFactor, rsSclFactorUnits, Gain
//				endif
//			endif	
//		endfor
//
//	else																			// OK : we have found an extended spec 
//
//		if ( BreakExtendedSpec(sFolder, sTGChan, rScrTyp, rScrSerNum, rScrComPort, rScrAxoBus, rScrChan ) == UFCom_TRUE )	// extract the specifiers  from script.  sTGChan is extended spec, simple specs have already been processed.
//
//			variable	nFound	= 0
//			for ( MCTGChan = 0;  MCTGChan < MCTgChansAvailable;  MCTgChan += 1 )
//				sOneChannelInfo	= StringFromList( MCTGChan, sMCTgChannelInfo )
//				if ( BreakInfo( sOneChannelInfo, rTyp, rSerNum, rComPort, rAxoBus, rChan, rMode, rMCGain, rSclFactor, rsSclFactorUnits )  !=  9 )
//					UFCom_DeveloperError( "Expected 9 entries in  MCTG info string '" + sOneChannelInfo + "' .  AllChans: " + sMCTgChannelInfo )  
//				endif	
//				
//				if ( rTyp == rScrTyp  &&  rChan == rScrChan  && ( ( rTyp == kMC700_A  &&  rComPort == rScrComPort   &&  rAxoBus == rScrAxoBus )  ||  ( rTyp == kMC700_B  &&  rSerNum == rScrSerNum ) ) )
//					if ( rTyp ==  kMC700_A )
//						sprintf s700AB, "CP:%3d    AB:%3d  ", rComPort, rAxoBus
//					else
//						sprintf s700AB, "SN:%15d", rSerNum
//					endif
//					nFound	+= 1
//					Gain		= rMCGain * rSclFactor
////					if ( UFCom_DebugDepthSel() > 0  &&  DebugSection() & UFCom_kDBG_TELEGRAPH )
//					if ( UFCom_DebugVar( "Telegraph" ) )
//						printf "\t\tTelegraphGainMC( nIO:%d, c:%d = Adc%d, sTGChan:\t%s\t)  %s \t%s\tTGCh:%2d\t'%s'\t   Gn:\t%7.2lf\tSc: %.1lf %s\t -> Gain: %5.1lf\t... \r", nIO, c, ch, UFCom_pd( sTGChan, 22), StringFromList( rTyp, kMC700_MODELS),  s700AB, rChan, StringFromList( rMode,kMC700_MODES), rMCGain, rSclFactor, rsSclFactorUnits, Gain
//					endif
//				endif	
//			endfor
//			if ( nFound  != 1 )  
//				 UFCom_FoAlert( sFolder, UFCom_kERR_SEVERE, "MultiClamp Telegraph channel not connected.  Gain = 1 is returned for channel  Adc " + num2str( ch )  + " and  'TGMCChan = " + sTGChan + "' . " ) 
//				return	1		// this is the default gain
//			endif
//
//		else
//			 UFCom_FoAlert( sFolder, UFCom_kERR_SEVERE, "MultiClamp Telegraph channel error.  Gain = 1 is returned for channel  Adc " + num2str( ch )  + " and  'TGMCChan = " + sTGChan + "' . " ) 
//			return	1		// this is the default gain
//		endif
//
//	endif
//
//
//	variable	nTGChan		= UFPE_TGMCChan( wIO, nIO, c )
//	if ( nTGChan != rScrChan )
//		UFCom_InternalError( "nTGChan != rScrChan" ) 
//	endif
//
//
////	// printf "\t\tTelegraphGainMC( ioch:%d = Adc%d ) \tPickupInfo returns Chans avail: %d   '%s' \r", ioch, ch, MCTgChansAvailable, sMCTgChannelInfo
////	if ( MCTgChansAvailable == 2 )
////		for ( MCTGChan = 0;  MCTGChan < MCTgChansAvailable;  MCTgChan += 1 )
////			sOneChannelInfo	= StringFromList( MCTGChan, sMCTgChannelInfo )
////			if ( BreakInfo( sOneChannelInfo, rTyp, rSerNum, rComPort, rAxoBus, rChan, rMode, rMCGain, rSclFactor, rsSclFactorUnits )  !=  9 )
////				UFCom_InternalError( "Expected 9 entries in  MCTG info string '" + sOneChannelInfo + "' ." ) 
////			endif	
////			if ( rChan == nTGChan )
////				Gain	= rMCGain * rSclFactor
////				printf "\t\tTelegraphGainMC( ioch:%d = Adc%d, sTGChan:'%s'  nTGChan:%d )  Pickup Typ:%s  SN:%d  CP:%d  AB:%d  TGCh: %d  Mode:%d  McGn:\t%7.2lf\tSc: %.1lf %s\t -> Gain: %5.1lf\t... \r", ioch, ch, sTGChan, nTGChan, StringFromList( rTyp, kMC700_MODELS), rSerNum,  rComPort, rAxoBus, rChan, rMode, rMCGain, rSclFactor, rsSclFactorUnits, Gain
////			endif	
////		endfor
////	elseif ( MCTgChansAvailable > 2 )
////		UFCom_InternalError( "Only 2 MCTG channels implemented. Extracted " + num2str( MCTgChansAvailable) + " from '" + sMCTgChannelInfo + "' ." ) 
////	else			// todo? discriminate between 0 and 1 
////		 UFCom_FoAlert( sFolder, UFCom_kERR_IMPORTANT, "Script specifies to use MultiClamp Telegraph channels, but only " + num2str( MCTgChansAvailable) + " channel(s) could be extracted from '" + sMCTgChannelInfo + "' ." ) 
////	endif
////	if ( Gain == 0 )
////		 UFCom_FoAlert( sFolder, UFCom_kERR_IMPORTANT, "Illegal MultiClamp Telegraph channel.  Gain = 1 is returned. " ) 
////		Gain = 1 		// returning 0 might possibly cause a crash (at least during testing....)
////	endif
//
//	return	Gain
//End
//			
//
////
////static Function	IsConnectedTGChannel( sOneChannelInfo ) 
////	string  	sOneChannelInfo
////	return	strlen( StringFromList( 0, sOneChannelInfo, "," )  )								// Check the first entry which should be 0 or 1 (for type 700A or B). No spaces or letters are allowed
//////	return	numtype( str2num( StringFromList( 0, sOneChannelInfo, "," ) )  ) != kNUMTYPE_NAN )	// Check the first entry which should be 0 or 1 (for type 700A or B). Safer but slower.		// entry in string list is not empty
////End
//
//
//static Function	CheckAvailableTelegraphChans( sFolder, sTGChan, MCTgChansAvailable )
//	string  	sFolder, sTGChan
//	variable	MCTgChansAvailable
//	string  	sBuf1
//	variable	nError	= 0
//	if ( MCTgChansAvailable == 0 )
//		sprintf sBuf1, "Failed to connect  'TGMCChan = %s' . There is currently  no  MC700 channel available. Turn on the MC700 and  'Apply'  again. ",  sTGChan 
//		 UFCom_FoAlert( sFolder, UFCom_kERR_SEVERE, sBuf1 )
//		nError	= UFCom_kERROR
//	endif
//	return	nError
//End 
//
//
//static Function	CheckSimpleSpecAgainstTGCnt( sFolder, sTGChan, rScrChan, MCTgChansAvailable )
//	string  	sFolder, sTGChan
//	variable	&rScrChan
//	variable	MCTgChansAvailable
//	string  	sBuf1, sBuf2
//	variable	nError	= 0
//	if ( strlen( sTGChan ) == 1  )
//		if (  MCTgChansAvailable != 2 )
//			sprintf sBuf1, "TGMCChan = %s  does not identify the MC700 uniquely. There are currently  %d  MC700 channels available. \r",  sTGChan ,  MCTgChansAvailable 
//			sprintf sBuf2, "\t\t\tEither turn off all unnecessary  MC700s  or  use  specifiers e.g . 'TGMCChan =  1_700A_Port_X_AxoBus_Y'   or  'TGMCChan =  2_700B_SN_xxxx'  "
//			 UFCom_FoAlert( sFolder, UFCom_kERR_SEVERE, sBuf1 + sBuf2 )
//			return	UFCom_kERROR
//		endif
//		rScrChan			= str2num( sTGChan[ 0,0 ] ) 			// use  the first digit : limits the channels to 0..9 .  In this special (=simple spec) case there is always only 1 digit. 
//		return	UFCom_TRUE
//	endif
//	return	 UFCom_FALSE					// not a simple spec
//End 
//
//
//static Function	BreakExtendedSpec( sFolder, sTGChan, rScrTyp, rnSerNum, rnComPort, rnAxoBus, rScrChan )
//// 'TGMCChan =  1_700A_Port_2_AxoBus_3'   or  'TGMCChan =  2_700B_SN_1234'
//	string  	sFolder, sTGChan
//	variable	&rScrTyp, &rnSerNum, &rnComPort, &rnAxoBus, &rScrChan 
//	string  	sBuf
//	rScrChan	= str2num( sTGChan[ 0,0 ] )			// can be simple or extended spec  
//	if ( strlen( sTGChan ) > 1 )						// it is an extended spec  
//		if ( cmpstr( sTGChan[ 1, 4 ] , "_700" ) == 0 )
//			if ( cmpstr( sTGChan[ 5,6 ] , "A_" ) == 0  ||   cmpstr( sTGChan[ 5,6 ] , "B_" ) == 0 )
//				rScrTyp	=  ( cmpstr( sTGChan[ 5,6 ] , "B_" ) == 0 )						// 0 : 700A , 1 : 700B
//				if ( rScrTyp == kMC700_A )
//					if ( cmpstr( sTGChan[ 6,11 ] , "_Port_" ) == 0  &&  cmpstr( sTGChan[ 13,20 ] , "_AxoBus_" ) == 0 )
//						rnComPort	= str2num(  sTGChan[ 12, 12 ] ) 
//						rnAxoBus	= str2num(  sTGChan[ 21, 21 ] ) 
////						if ( UFCom_DebugDepthSel() > 2  &&  DebugSection() & UFCom_kDBG_TELEGRAPH )
//						if ( UFCom_DebugVar( "Telegraph" ) )
//							printf "\t\t\t\tTelegraphGainMC  BreakExtendedSpec(\t%s\t)   700A ,  Chan:%2d ,  Port:%2d ,  AxoBus:%2d  \r",   UFCom_pd( sTGChan,22) , rScrChan, rnComPort, rnAxoBus
//						endif
//					else
//						sprintf sBuf, "TGMCChan = %s  is an illegal specification. Use  e.g .   'TGMCChan =  1_700A_Port_2_AxoBus_3''  ",  sTGChan 
//						 UFCom_FoAlert( sFolder, UFCom_kERR_SEVERE, sBuf )
//						return	UFCom_kERROR	
//					endif		
//				else						// = 700B
//					if ( cmpstr( sTGChan[ 6,9 ] , "_SN_" ) == 0 )
//						rnSerNum	= str2num(  sTGChan[ 10, inf ] ) 
////						if ( UFCom_DebugDepthSel() > 2  &&  DebugSection() & UFCom_kDBG_TELEGRAPH )
//						if ( UFCom_DebugVar( "Telegraph" ) )
//							printf "\t\t\t\tTelegraphGainMC  BreakExtendedSpec(\t%s\t)  700B ,  Chan:%2d ,  SN: %d  \r",  UFCom_pd( sTGChan,22) , rScrChan, rnSerNum
//						endif
//					else
//						sprintf sBuf, "TGMCChan = %s  is an illegal specification. Use  e.g .   'TGMCChan =  2_700B_SN_xxxx'  ",  sTGChan 
//						 UFCom_FoAlert( sFolder, UFCom_kERR_SEVERE, sBuf )
//						return	UFCom_kERROR	
//					endif		
//				endif
//			else
//				sprintf sBuf, "TGMCChan = %s  is an illegal specification. Use  e.g . 'TGMCChan =  1_700A_Port_X_AxoBus_Y'   or  'TGMCChan =  2_700B_SN_xxxx'  ",  sTGChan 
//				 UFCom_FoAlert( sFolder, UFCom_kERR_SEVERE, sBuf )
//				return	UFCom_kERROR	
//			endif		
//		else
//			sprintf sBuf, "TGMCChan = %s  is an illegal specification. Use  e.g . 'TGMCChan =  1_700A_Port_X_AxoBus_Y'   or  'TGMCChan =  2_700B_SN_xxxx'  ",  sTGChan 
//			 UFCom_FoAlert( sFolder, UFCom_kERR_SEVERE, sBuf )
//			return	UFCom_kERROR	
//		endif		
//	else
//		UFCom_InternalError( "BreakExtendedSpec( '" + sTGChan + " )  is a simple spec. " ) 		// should never happen 
//	endif
//	return	UFCom_TRUE		// OK
//End
//
//
//static Function		BreakInfo( sOneChannelInfo, rHWTyp, rSerNum, rComPort, rAxoBus, rChan, rMode, rMCGain, rSclFct, rsSclFctUnits )
//// breaks MultiClamp telegraph 1-channel info string as given by XOP  'UFP_MCTgPickupInfo()'   into its components.
//// ASSUMPTION: Same separators ' , ; ' and same entries 'HWTyp, SerNum, Port, AxoBus, Chan, Mode, Alpha, ScaleFct, Units' as in    'UFP_MCTgPickupInfo()/UpdateDisplay()'  
//	string		sOneChannelInfo
//	variable	&rHWTyp, &rSerNum, &rComPort, &rAxoBus, &rChan, &rMode, &rMCGain, &rSclFct
//	string		&rsSclFctUnits
//	variable	nEntries	= ItemsInList( sOneChannelInfo, "," )
//	rHWTyp		= str2num( StringFromList( 0, sOneChannelInfo, "," ) ) 
//	rSerNum		= str2num( StringFromList( 1, sOneChannelInfo, "," ) )		
//	rComPort		= str2num( StringFromList( 2, sOneChannelInfo, "," ) ) + 1	// one-based : 1,2,3...
//	rAxoBus		= str2num( StringFromList( 3, sOneChannelInfo, "," ) )		
//	rChan		= str2num( StringFromList( 4, sOneChannelInfo, "," ) ) + 1	// one-based : 1,2
//	rMode		= str2num( StringFromList( 5, sOneChannelInfo, "," ) )
//	rMCGain		= str2num( StringFromList( 6, sOneChannelInfo, "," ) )
//	rSclFct		= str2num( StringFromList( 7, sOneChannelInfo, "," ) )
//	rsSclFctUnits	= StringFromList( 8, sOneChannelInfo, "," )
//	// print "\t\tBreakInfo():", rComPort, rAxoBus, rChan, "Mode:", rMode, "\tGain:\t", rMCGain, "\tSclFactor:\t", rSclFct, "\t", rsSclFctUnits
//	return	nEntries
//End
//
//
//Function		DisplayAvailMCTgChans()
//	string		sOneChannelInfo
//	string		rsSclFactorUnits
//	variable	rTyp, rSerNum, rComPort, rAxoBus, rChan, rMode, rMCGain, rSclFactor					// the specifiers which the MC700 has transmitted, extracted from  'PickUpInfo'
//	variable	MCTGChan
//
//	string  	sMCTgChannelInfo	= UFP_MCTgPickupInfo()
//
//	variable	MCTgChansAvailable	=  ItemsInList( sMCTgChannelInfo )
//
//	printf "\r\t\tDisplayAvailMCTgChans()  finds  %d   MCC700 channels. '%s' \r", MCTgChansAvailable, sMCTgChannelInfo
//	for ( MCTGChan = 0;  MCTGChan < MCTgChansAvailable;  MCTgChan += 1 )
//		sOneChannelInfo	= StringFromList( MCTGChan, sMCTgChannelInfo )
//
////		if (  IsConnectedTGChannel( sOneChannelInfo ) ) 
//
//			if ( BreakInfo( sOneChannelInfo, rTyp, rSerNum, rComPort, rAxoBus, rChan, rMode, rMCGain, rSclFactor, rsSclFactorUnits )  !=  9 )
//				UFCom_DeveloperError( "Expected 9 entries in  MCTG info string '" + sOneChannelInfo + "' .  AllChans: " + sMCTgChannelInfo ) 
//			endif	
//			printf "\t\t\tDisplayAvailMCTgChans() \tMC:%d\t%s\ttp:%3d\tpo:%3d\tab:%3d\tch:%2d\tsn:%16d\tGn:\t%7.1lf\tScl:\t%3.1lf\t  U: %s\tMode: '%s' \r", MCTGChan, SelectString( rTyp==0, "700B", "700A"), rTyp, rComPort, rAxoBus, rChan,  rSerNum, rMCGain, rSclFactor, UFCom_pd(rsSclFactorUnits,6), StringFromList( rMode, kMC700_MODES )
////		endif
//	endfor
//End
//
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////   DISPLAY AND STORE FUNCTIONS CALLED BY TIMER DURING ACQUISITION
////   NEW  APPROACH 020218:    call processing functions (=CFSStore, DisplayDurAcq..) from WITHIN  Process()
////   usage: call Process()  repeatedly  from  ADDASwing()   and  once  from  CedStartAcq() 
//
//// todo PULSE stores 1 original  and  1 corrected sweep for each frame, ...
//// ... so GetSweepsPerFrame() should return 2 HERE (and elsewhere, but not everywhere..) 
//
//Function		Process( sFolders, sFo, ptAD )		// PROTOCOL  AWARE
////!  MAJOR CONCEPT ...recover underlying sweep / frame structure ....can be extended to other script types (here only PULSE) 
////  checks list with Frame / Sweeps end points (=index into ADC integer wave) built before the acquisition (in OutElems...()....)
////  only after a frame is completely acquired (=this point 'ptAD' is reached or passed) we can manipulate the data (=disk store or display)
//// Version1 up to 031006:  the  array behind SwpEndSave() does NOT contain  'gnProt'  so  'gnProt'  is counted down in AddaSwing() 
////		and compared here against internal 'igLasProt' to decide if another Protocol must be processed. This was possible as nReps contained JUST ONE protocol..
//// Version 2 : nRep no longer is 1 protocol so AddaSwing()  cannot directly control  'gnProt'  ( and should not in fact have to know anything about prots, blocks frames, sweeps )
//// 	Solution:	extend   Get_Sweep/Frame/Start/End_Point()  so that it contains  'gnProt' . Clean but truely  PROTOCOL_AWARE  requires much space (times  gnProt !!!)
//	string  	sFolders		// always 'acq:pul'
//	string  	sFo			// always 'acq'			todo simplify
//	variable	ptAD			// -1 : only initialize the internal globals, all further calls supply a value > 0 meaning real action 
//	wave 	wG			= $"root:uf:" + sFo + ":" + UFPE_ksKPwg + ":wG"	  		// This  'wG'  	is valid in FPulse ( Acquisition )
//	wave  /T	wIO			= $"root:uf:" + sFo + ":ar:wIO"  					// This  'wIO'	is valid in FPulse ( Acquisition )
//	wave  /T	wVal			= $"root:uf:" + sFo + ":ar:wVal"  					// This  'wVal'	is valid in FPulse ( Acquisition )
//	wave 	wE			= $"root:uf:" + sFo + ":ar:wE"  					// This  'wE'  	is valid in FPulse ( Acquisition )
//	wave 	wBFS		= $"root:uf:" + sFo + ":ar:wBFS" 					// This  'wBFS'  	is valid in FPulse ( Acquisition )
//	variable	nRadDebgSel	= UFCom_DebugDepthSel()
////	variable	PnDebgCFSw	=  UFCom_DebugVar( "CfsWrite" ) 
//	variable	nProts		= UFPE_Prots( sFo )
//	//UFCom_StartTimer( sFo, "Process1" )		
//
//	// printf "\t\tProcess(0 sFolder : '%s' ) : data folder : '%s' \r", sFolder, GetDataFolder( 1 ) 
//	// Initialization....
//	if ( ptAD == -1 )
//		variable  /G	$"root:uf:" + sFo + ":stim:igLastProt"	= 0	
//		variable  /G	$"root:uf:" + sFo + ":stim:igLastB"	= 0
//		variable  /G	$"root:uf:" + sFo + ":stim:igLastSwp"	= 0	// internal globals storing the number of the last...
//		variable  /G	$"root:uf:" + sFo + ":stim:igLastFrm"	= 0	// ..frame, sweep and protocol which have already been processed 
//		return 0												
//	else 
//		nvar		 	igLastProt	= $"root:uf:" + sFo + ":stim:igLastProt"
//		nvar			igLastB	= $"root:uf:" + sFo + ":stim:igLastB"
//		nvar			igLastSwp	= $"root:uf:" + sFo + ":stim:igLastSwp"
//		nvar			igLastFrm	= $"root:uf:" + sFo + ":stim:igLastFrm"
//	endif
//	// printf "\t\tProcess(1 sFolder : '%s' ) : data folder : '%s' \r", sFolder, GetDataFolder( 1 ) 
//
//	string		bf
//	variable	p, b, f, s
//variable	lap=0
//	variable	swpEnd	= UFPE_SweepEndSaveProtAware( sFo, igLastProt, igLastB, igLastFrm, igLastSwp ) 	// 2003-10-07  PROTOCOL  AWARE
//	printf "\t\t\t\tCFSWr  PROcess receiv.swpEnd(\tp:%d b:%d f:%d s:%d):\t\t%7d <=?%7d (ptAD)\t%s  igLastProt:%d \r",  igLastProt, igLastB, igLastFrm, igLastSwp, swpEnd, ptAD, SelectString( swpEnd  <= ptAD , "START..   will return immediately..." , "START..allow processing" ), igLastProt 
//	if ( nRadDebgSel > 2  &&   UFCom_DebugVar( "CfsWrite" ) )//PnDebgCFSw )
//		printf "\t\t\t\tCFSWr  PROcess receiv.swpEnd(\tp:%d b:%d f:%d s:%d):\t\t%7d <=?%7d (ptAD)\t%s  igLastProt:%d \r",  igLastProt, igLastB, igLastFrm, igLastSwp, swpEnd, ptAD, SelectString( swpEnd  <= ptAD , "START..   will return immediately..." , "START..allow processing" ), igLastProt 
//	endif
//	//UFCom_StopTimer( sFo, "Process1" )	
//	for ( p =  igLastProt; p < nProts; p += 1 )
//		for ( b =  igLastB; b < UFPE_eBlocks( sFo ); b += 1 )
//			for ( f =  igLastFrm; f < UFPE_eFrames_( sFo, b ); f += 1 )
//				for ( s = igLastSwp; s < UFPE_eSweeps_( sFo, b ); s += 1 )
//					swpEnd	= UFPE_SweepEndSaveProtAware( sFo, p, b, f, s ) 	// 2003-10-07  PROTOCOL  AWARE
//					igLastProt	=  p		
//					igLastB	=  b		
//					igLastFrm	=  f		
//					igLastSwp = s 		
//					if ( ptAD < swpEnd )
//				//	if ( nRadDebgSel > 2  &&   UFCom_DebugVar( "CfsWrite" ) )//PnDebgCFSw )
//						printf "\t\t\t\tCFSWr  Process checks swpEnd(\tp:%d,b:%d,f:%d,s:%d):\t\t%7d <=?%6d\t\t\t\tRETURN..sweep not yet ready \r",  p, b, f, s, swpEnd, ptAD
//				//	endif
//						return swpEnd
//					endif
//	
//					// SWEEP PROCESSING
//				//	if ( nRadDebgSel > 2  &&   UFCom_DebugVar( "CfsWrite" ) )//PnDebgCFSw )
//						printf  "\t\t\t\tCFSWr  Process \t\t\t\tp:%d,b:%d,f:%d,s:%d /%2d :\t%7d <=?%6d\t\t\t\tPROCESSING SWEEP\r", p, b, f, s,  UFPE_eSweeps_( sFo, b ) - 1, swpEnd, ptAD 
//				//	endif
//					//	SWP_COMPUTATION
//					// do specific computations for all mainkeys allowed in script (=provided in w_MK, w_SK )
//					// UFCom_StartTimer( sFo, "Process1" )		
//					UFCom_StartTimer( sFo, "OnlineAn" )
//					ComputePOverNCorrection( sFo, wG, wIO, wE, wBFS, p, b, lap, f, s )		// 2003-1008  !  PROTOCOL  AWARE			
//					// UFCom_StopTimer( sFo, "Process1" )		
//					// ComputeAverage( p, b, f, s )			// 2004-0123 removed,   031008  !  PROTOCOL  AWARE		
//					// ComputeSum( p, b, f, s )				// 2004-0123 removed,   031008  !  PROTOCOL  AWARE		
//					UFCom_StopTimer( sFo, "OnlineAn" )
//			
//					//	SWP_DISPLAY
//					UFCom_StartTimer( sFo, "Graphics" )
//					DispDuringAcqCheckLag( sFo, p, b, lap, f, s, kSWEEP )		// 2003-1008  !  PROTOCOL  AWARE			
//					UFCom_StopTimer( sFo, "Graphics" )
//		
//					//	SWP_CFSWRITE
//					UFCom_StartTimer( sFo, "CFSWrite" )
//			
//					WriteDataSection( sFo, wG, wIO, wVal, p, b, lap, f, s )			
//					UFCom_StopTimer( sFo, "CFSWrite" )
//					
//				endfor								// ..sweeps
//		
//				// FRAME PROCESSING
//			//	if ( nRadDebgSel > 2  &&   UFCom_DebugVar( "CfsWrite" ) )//PnDebgCFSw )
//					printf "\t\t\t\tCFSWr  Process\t\t\t\tp:%d,b:%d f:%d \t\t:\t%7d <=?%6d\t\t\t\tPROCESSING FRAME\r", p, b, f,  swpEnd, ptAD 
//			//	endif
//				
//				UFCom_StartTimer( sFo, "OnlineAn" )
//				OnlineAnalysis( sFolders, p, b, lap, f )					// 2003-1008  !    NOT  YET  REALLY  PROTOCOL  AWARE				
//				UFCom_StopTimer( sFo, "OnlineAn" )
//		
//				//	FRM_DISPLAY
//				UFCom_StartTimer( sFo, "Graphics" )
//				DispDuringAcqCheckLag( sFo, p, b, lap, f, 0, kFRAME	)	// 2003-1008  !  PROTOCOL  AWARE	
//				DispDuringAcqCheckLag( sFo, p, b, lap, f, 0, kPRIM	)	// 	
//				DispDuringAcqCheckLag( sFo, p, b, lap, f, 0, kRESULT)	// 	
//				UFCom_StopTimer( sFo, "Graphics" )
//				igLastSwp = 0						
//				if ( nRadDebgSel > 2  &&   UFCom_DebugVar( "CfsWrite" ) )//PnDebgCFSw )
//				 	// printf  "\t\t\t\tCFSWr \tProcess()  (last setting \tf:%d,s:%d) end of sweeps loop, next frame..\t\r", f, s-1
//				endif
//			endfor							// ..frames
//			igLastSwp	=  0					// depending on sweeps/frames/ptAd this function is sometimes called at the end  ( when or after finishing )....
//			igLastFrm	= 0 					// ..when nothing has to be stored or displayed. Because igLastFrm has been/ is set to the end value the function is left immediately.
//		endfor							// ..blocks
//		igLastSwp	= 0					// depending on sweeps/frames/ptAd this function is sometimes called at the end  ( when or after finishing )....
//		igLastFrm	= 0 					// ..when nothing has to be stored or displayed. Because igLastFrm has been/ is set to the end value the function is left immediately.
//		igLastB	= 0					// depending on sweeps/frames/ptAd this function is sometimes called at the end  ( when or after finishing )....
//	endfor							// ..blocks
//	igLastSwp	= 0					// depending on sweeps/frames/ptAd this function is sometimes called at the end  ( when or after finishing )....
//	igLastFrm	= 0 					// ..when nothing has to be stored or displayed. Because igLastFrm has been/ is set to the end value the function is left immediately.
//	igLastB	= 0					// depending on sweeps/frames/ptAd this function is sometimes called at the end  ( when or after finishing )....
//	igLastProt	= p 					// ..when nothing has to be stored or displayed. Because igLastFrm has been/ is set to the end value the function is left immediately.
//
//	if ( nRadDebgSel > 3  &&   UFCom_DebugVar( "CfsWrite" ) )//PnDebgCFSw )
//		printf  "\t\t\t\t\tCFSWr  Process end frames. set\tp:%d -> igLastProt:%d , \tb:%d -> igLastB:%d , \tf:%d -> igLastFrm:%d , igLastSwp:%d) ....???.......and return finally \r", p, igLastProt, b, igLastB, f, igLastFrm, igLastSwp 
//	endif
//
//	// printf "\t\tProcess(2 sFolder : '%s' ) : data folder : '%s' \r", sFolder, GetDataFolder( 1 ) 
//End
//
//
//Function	ComputePOverNCorrection( sFo, wG, wIO, wE, wBFS, pr, bl, lap, fr, sw )			//  PROTOCOL  AWARE		BUT  NOT YET  TESTED   TODO
//// for PULSE : computes and writes PoverN corrected data sweeps
//	string  	sFo
//	wave  /T	wIO
//	wave	wG, wE, wBFS
//	variable	pr, bl, lap, fr, sw
//	variable	nRadDebgSel	= UFCom_DebugDepthSel()
//	variable	nCntAD		= wG[ UFPE_WG_CNTAD ]	
//
//	variable	BegPt		= UFPE_SweepBegSave( sFo, pr, bl, lap, fr, sw )	
//	variable	EndPt		= UFPE_SweepEndSave( sFo, pr, bl, lap, fr, sw )
//
//	variable	c, nPts		= EndPt - BegPt
//	variable	PrevBegPt		= -1
//	variable	LastBegPt		= -1
//	string		bf
//
//
//	variable	SweepsTimesCorrAmp = ( UFPE_eSweeps_( sFo, bl ) - 1 ) * UFPE_eCorrAmp_( sFo, bl )
//	variable	nSmpInt			 = UFPE_SmpInt( sFo )
//	variable	BAvgBegPt		 = 0
//	variable	BAvgEndPt		 = 0
//	variable	/G root:uf:acq:cfsw:BaseSubtractOfs										// Stores offset correction value of sweep 0 which is subtracted in following sweeps. Global to keep the value but used only locally. 
//	nvar		BaseSubtractOfs= root:uf:acq:cfsw:BaseSubtractOfs							// Stores offset correction value of sweep 0 which is subtracted in following sweeps. Global to keep the value but used only locally. 
//
//	// Approach1: Use temporary one-sweep-buffer for intermediary correction steps (=sweep addition) and copy this temporary buffer into the current sweep of 'PoNx'. Benefit: Intermediary correction steps can be displayed  at the cost of buffer copying time.
//	// Approach2: Copy all intermediary correction steps directly into last sweep of 'PoNx'. Faster but no intermediary display (except when accessing last sweep in Display)
//	// Approach3 (taken): Copy all intermediary correction steps (=sweep addition)  directly into current  AND into last sweep of 'PoNx'.  Reasonably fast and intermediary display possible.
//	
//	// Add first sweep and the following correction sweeps (up to the last sweep of this frame)
//	for ( c = 0; c < nCntAD; c += 1 )														// c  is  Adc index,  NOT  PoN index !
//		string  	sBig	= UFPE_ioFldAcqioio( sFo, wIO, UFPE_IOT_ADC, c, UFPE_IO_NM ) 		// old :get the source Adc channel directly
//		wave	wBig = $sBig	
//		if ( DoPoverN( sFo, wIO, c ) )													// user wants PoverN  (it is users responsibility that it is a true AD and not a telegraph..)
//			//string		sPoN	= "PoN" + sIOCHSEP +  io( "Adc", c, UFPE_IO_CHAN ) 
//			string		sPoN	= UFPE_ioFldAcqioPoNio( sFo, wIO, UFPE_IOT_ADC, c, UFPE_IO_CHAN ) 
//			wave 	wPoN	= $sPoN
//
//			if ( sw == 0 )
//				wPoN[ BegPt, BegPt+nPts ]	= wBig[  p ]								// data from first sweep initialize first sweep  ( clear frame is not necessary ) ...
//
//				// Compute offset correction value of sweep 0  which will be subtracted in following sweeps.			// 2004-08-06 
//				// Do not subtract the value in sweep 0 : if there was an offset it is kept throughout the PoN correction, but the offset does not increase with every sweep as it would be without  'BaseSubtractOfs'
//				BAvgBegPt=  BegPt																// in points : the begin of the first (non-blank) segment (the point where the recorded section starts)
//				// print "ComputePOverNCorrection()   Blank / segment",  UFPE_eTyp( wE, wBFS,  c, bl,  0 ), UFPE_eTyp( wE, wBFS,  c, bl, 1 ) , UFPE_mI( "Blank" ), UFPE_mI( "Segment" ) 
//				// Use the first real segment for offset computation (one could also use a possible leading blank  OR  use a  leading  blank and the following segment) 
//				// If the first element is blank then use the second element. It is the user's responsibility to ensure that it is segment (whose value is constant by definition).
//				variable	nElement	= ( UFPE_eTyp( wE, wBFS,  c, bl, 0 )  == UFPE_mI( sFo, "Blank" ) 	?  1  :  0	
//				BAvgEndPt=  BegPt + ( UFPE_eV( wE, wBFS, c, bl, 0, sw, nElement, UFPE_EV_DUR ) / nSmpInt) 						// in points
//				//BaseSubtractOfs	= mean( wPoN, BAvgBegPt ,  BAvgEndPt )  							// !!! in this special case pnt2x has been omitted as the wave has x scaling = 1 : x = points (mean and faverage yield same result)
//				BaseSubtractOfs	= faverage( wPoN, pnt2x(  wPoN, BAvgBegPt ),  pnt2x(  wPoN, BAvgEndPt ) )  	// !!! in this special case pnt2x  could be omitted as the wave has x scaling = 1 : x = points (mean and faverage yield same result)
//
//
//			else
//				// Copy previous  sweep intermediary corrected data into current sweep and then add current correction sweep
//				PrevBegPt		= UFPE_SweepBegSave( sFo, pr, bl, lap, fr, sw - 1 )	
//
//				// Subtract  offset correction value computed in sweep 0  in all following sweeps
//				// wPoN[ BegPt, BegPt + nPts ]	= wPoN[ PrevBegPt - BegPt + p ] + wBig[ p ] / SweepsTimesCorrAmp					// 2004-08-06 
//				wPoN[ BegPt, BegPt + nPts ]	= wPoN[ PrevBegPt - BegPt + p ] + ( wBig[ p ] - BaseSubtractOfs )  / SweepsTimesCorrAmp	// 2004-08-06 recognises BaseSubtractOfs
//
//			endif
//			
//
//			if ( sw < UFPE_eSweeps_( sFo, bl ) - 1 )									// the last sweep need not be copied as it is already at the right place
//				LastBegPt	= UFPE_SweepBegSave( sFo, pr, bl, lap, fr, UFPE_eSweeps_( sFo, bl ) - 1 )	
//				wPoN[ LastBegPt, LastBegPt + nPts ]	=  wPoN[ BegPt  - LastBegPt + p ]		// copy current  corrected sweep into last sweep.
//			endif
//			 printf "\t\t\t\tCFSw  ComputePOverNCorr( \t\t\t   f:%d s:%d  \t\tB:%7d \t~%7d\tPts:%4d \t'%s' pts:%4d \t'%s' pts:%4d \tPsp:%5d \tLsp:%5d \tBAv[\t/%6d\t..%6d\t] = \tAvg %g\tnElm:%2d \r", fr, sw, BegPt, EndPt , nPts,  sBig, numPnts($sBig), sPoN, numPnts( $sPoN), PrevBegPt,LastBegPt,BAvgBegPt,BAvgEndPt,BaseSubtractOfs, nElement
//
//			if ( nRadDebgSel > 2  &&  UFCom_DebugVar( "CfsWrite" ) )
//				 printf "\t\t\t\tCFSw  ComputePOverNCorr( \tfr:%d, sw:%d)  \tBP:\t%7d\tEP:\t%7d\tPts:%4d \t'%s' pts:%4d \t'%s' pts:%4d \tPsp:%5d \tLsp:%5d \tBAv[\t/%6d\t..%6d\t] = \tAvg %g\tnElm:%2d \r", fr, sw, BegPt, EndPt , nPts,  sBig, numPnts($sBig), sPoN, numPnts( $sPoN), PrevBegPt,LastBegPt,BAvgBegPt,BAvgEndPt,BaseSubtractOfs, nElement
//			endif
//			// display wPoN;  UFCom_FoAlert( sFo, UFCom_kERR_FATAL,  "kuki" )
//		endif
//	endfor
//End
//
//
//static Function	DoPoverN( sFo, wIO, c )
//// must for the Adc channel with index 'c'  the PoverN correction be done? 
//	string  	sFo
//	wave  /T	wIO
//	variable	c
//	variable	nPoN, nPoNCh, nAdcCh
//	//  'PoN'  is  mainkey	(c is Adc index) : must search for a corresponding channel number in 'PoN' lines 
//	nAdcCh	= UFPE_iov( wIO, UFPE_IOT_ADC , c, UFPE_IO_CHAN ) 
//	for ( nPoN = 0; nPoN < UFPE_ioUse( wIO, UFPE_IOT_PON ); nPoN += 1 )
//		nPoNCh = UFPE_iov( wIO, UFPE_IOT_PON , nPoN, UFPE_IO_SRC )  
//		if ( nPoNCh == nAdcCh )
//			return UFCom_TRUE
//		endif	
//	endfor
//	return	  UFCom_FALSE
//End


//Function 		FinishCFSFile()
//	string  	bf
//	variable	nRadDebgSel	= UFCom_DebugDepthSel()
////	variable	PnDebgCFSw	= UFCom_DebugVar( "CfsWrite" )
//	nvar		gCFSHandle	= root:uf:acq:cfsw:gCFSHandle
//	nvar		gFileIndex		= root:uf:acq:cfsw:gFileIndex
//	string		sPath		= GetPathFileExt( gFileIndex )
//	if ( gCFSHandle	!= kCFS_NOT_OPEN )		
//		UFPE_CfsCloseFile( gCFSHandle, UFPE_ERRLINE )
//		gCFSHandle	= kCFS_NOT_OPEN 
//		Backup()
//		// printf "\t\tCFSWr  FinishCFSFile() closes CFS file '%s'    (hnd:%d) \r", sPath, gCFSHandle	
//		if ( nRadDebgSel > 0  &&   UFCom_DebugVar( "CfsWrite" ) )//PnDebgCFSw )
//			printf "\t\tCFSWr  FinishCFSFile() closes CFS file '%s'    (hnd:%d) \r", sPath, gCFSHandle	
//		endif
//	else
//		// printf "\t\tCFSWr  FinishCFSFile():  no open CFS file  '%s'  \r", sPath
//		if ( nRadDebgSel > 0  &&   UFCom_DebugVar( "CfsWrite" ) )//PnDebgCFSw )
//			printf "\t\tCFSWr  FinishCFSFile():  no open CFS file  '%s'  \r", sPath
//		endif
//	endif
//End
//

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////	AUTOMATIC  DATA  FILE  NAME GENERATION  SPECIFIC  TO  FPULSE
////	Automatic file name generation	:	 Functions  relying on  globals  gCell, gFileIndex...  , which are valid and used only during acquisition
//
//static Function		AutoBuildNextFilename( sFolder )	
//// Increment the automatically built file name = go to next  fileindex. Changes the globals  'gFileIndex'  and   'gsDataFileW' 
//	string  	sFolder
//	nvar		gFileIndex		= root:uf:acq:cfsw:gFileIndex
//	do 			
//		gFileIndex	+= 1										// Increment the automatically built file name = go to next  fileindex
//
//		if ( gFileIndex == UFCom_kANM_MAX_2LETTERS - 1 )
//			 UFCom_FoAlert( sFolder, UFCom_kERR_IMPORTANT,  " You are using the last file with current name and cell number ( " + GetPathFileExt( UFCom_kANM_MAX_2LETTERS-1) + " ). " )
//		endif
//		if ( gFileIndex == UFCom_kANM_MAX_2LETTERS  )
//			 UFCom_FoAlert( sFolder, UFCom_kERR_SEVERE,  " All files with current name and cell number from AA to ZZ have been used ( " + GetPathFileExt( 0 ) + "  to   " + GetPathFileExt( UFCom_kANM_MAX_2LETTERS-1) + " ). \r\tThe last file will be overwritten." )
//		endif
//		gFileIndex	= min( gFileIndex , UFCom_kANM_MAX_2LETTERS - 1 ) 
//		DataFileWSet( GetFileName() + UFPE_ksCFS_EXT )
//
//		// printf "\t\tbuStart()  AutoBuildNextFilename()  checking  '%s'\t:  File  does  %s \r",  GetPathFileExt( gFileIndex ), SelectString(  UFCom_FileExists(  GetPathFileExt( gFileIndex ) ), "NOT exist: creating it...", "exist: skipping it..." )
//	while  (  UFCom_FileExists(  GetPathFileExt( gFileIndex ) )  &&  gFileIndex < UFCom_kANM_MAX_2LETTERS - 1 )	// skip existing files
//End


//Function		SearchAndSetLastUsedFile()
//	nvar		gFileIndex		= root:uf:acq:cfsw:gFileIndex
//	gFileIndex		= GetLastUsedFileFromHead( -1 )					// start with  -1 (=AA-1), increment repeatedly until file exists, then return index of previous (=last used) file
//	// gFileIndex  	= GetLastUsedFileFromTail( kMAXINDEX_2LETTERS )	// start with ZZ+1, decrement repeatedly until file exists, then return this index  (=last used) file
//	DataFileWSet( GetFileName() + UFPE_ksCFS_EXT )
//	// printf "\tSearchAndSetLastUsedFile()	has computed gFileIndex:%3d   and has set  gsDataFileW:'%s' \r", gFileIndex, DataFileW()
//End
//
//static Function	 	GetLastUsedFileFromHead( nIndex )		
//// build automatic file name converting index to two letters in the range from 0..26x26-1
//// start at AA (=0) and INCREMENT index skipping all existing files, return index of  last  file name already used
//// -- can overwrite an existing file it it comes after a gap, because it starts at the first  gap -> WE MUST CHECK EVERY INDEX , if it is empty  or if this file (maybe after a gap) already exists
////++ fast  when only few files are used (most likely)
//	variable	nIndex
//	do
//		nIndex	+= 1
//	while (  UFCom_FileExists( GetPathFileExt( nIndex ) ) && nIndex < UFCom_kANM_MAX_2LETTERS ) 
//	if ( nIndex == UFCom_kANM_MAX_2LETTERS )
//		 UFCom_FoAlert( ksACQ, UFCom_kERR_FATAL,  " All files with current name and cell number from AA to ZZ have been used ( " + GetPathFileExt( 0 ) + "  to   " + GetPathFileExt( UFCom_kANM_MAX_2LETTERS-1) + " ). " )
//	endif
//	// printf "\tGetLastUsedFileFromHead()  searching by incrementing from AA and returning %d \r", nIndex - 1 
//	return  nIndex  - 1	 // loop has been left with index of first existing file, decrease by one to get last used. Minimum  return is -1  -> Run writes next file 0=AA 
//End
//
//static Function	 	GetLastUsedFileFromTail( nIndex )		
//// build automatic file name converting index to two letters in the range from 0..26x26-1
//// start at ZZ and DECREMENT index skipping all non-existing files, return index of  last  file name already used
//// ++ can never overwrite an existing file
//// -- does NOT use existing gaps (e.g. if 1 file ..ZZ exists it will block 675 gaps ..AA  - ..ZY), --very slow the first time when only few files are used (most likely)
//	variable	nIndex
//	do
//		nIndex	-= 1
//	while ( nIndex >= 0  &&  !  UFCom_FileExists( GetPathFileExt( nIndex ) ) ) // minimum  return is -1  --> Run writes next file 0=AA
//	printf "\tGetLastUsedFileFromTail()  searching by decrementing from ZZ and returning %d \r", nIndex 
//	return  nIndex 
//End
//
//////Function	 	NextFreeFileInc( nIndex )		
//////// build automatic file name converting index to two letters in the range from 0..26x26-1
//////// start at AA (=0) and INCREMENT index skipping all existing files, return index of  first file name not yet used
//////	variable	nIndex
//////	do
//////		nIndex	+= 1
//////	while (  UFCom_FileExists( GetPathFileExt( nIndex ) ) )	
//////	return  nIndex
//////End
//
//
//static Function	 /S	GetPathFileExt( nIndex )
//// builds and returns automatic file name (including global dir and base filename and cell) by converting the passed  'index'  into two letters in the range from 0..26x26-1
//	variable	nIndex
//	variable	nCell		= Cell()
//	string		sFileBase	= FileBase()
//	string		sDataDir	= DataDir() 
//
//	string 	sPath	= sDataDir + sFileBase + num2Str( nCell ) + UFCom_IdxToTwoLetters( nIndex ) + UFPE_ksCFS_EXT 
//	// printf "\tGetPathFileExt( nIndex:%3d )  returns   '%s',    \tthis file does %s exist. \r", nIndex, sPath, SelectString(  UFCom_FileExists( sPath ) , "NOT", "" )
//	return	sPath
//End
//
//Function  /S	GetFileName()					// everything before the dot 
//// builds and returns automatic file name from implicit current index  and base filename and cell, but  excluding  directory
//	string		sFileBase	= FileBase()
//	variable	nCell		= Cell()
//	nvar		gFileIndex	= root:uf:acq:cfsw:gFileIndex
//	return	sFileBase + num2str( nCell ) + UFCom_IdxToTwoLetters( gFileIndex ) 
//End
//
//


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//static strconstant	sBAK_EXT			= ".bak"
//
//static Function	Backup()
//	nvar		gFileIndex		= root:uf:acq:cfsw:gFileIndex
//	variable	bAutoBackup	= AutoBackup()
//	variable	nRadDebgSel	= UFCom_DebugDepthSel()
////	variable	PnDebgCFSw	= UFCom_DebugVar( "CfsWrite" ) 
//	string 	sPathFileExt	= GetPathFileExt( gFileIndex )
//	//( string 	sPathBak	= UFCom_StripPathAndExtension( sPathFileExt ) + sBAK_EXT // save BAK in current dir  (=Userigor\ced), not in data dir (=\epc\data)
//	string 	sPathBak	= UFCom_StripExtension( sPathFileExt ) + sBAK_EXT[1,3] // only one dot! Save BAK in same dir as original, i.e. in data dir (=\epc\data)
//	string 	bf
//	if ( bAutoBackup )
//
//		CopyFile	/O	sPathFileExt as sPathBak
//
//		if ( nRadDebgSel > 0  &&   UFCom_DebugVar( "CfsWrite" ) )//PnDebgCFSw )
//			printf  "\t\tCFSWr  Backup()    '%s'  > '%s' \r",  sPathFileExt, sPathBak
//		endif
//	else
//		if ( nRadDebgSel > 0  &&  UFCom_DebugVar( "CfsWrite" ) )// PnDebgCFSw )
//			printf  "\t\tCFSWr  Backup() is turned off. No Backup is made of  '%s' .\r",  sPathFileExt
//		endif
//	endif
//End
//
//
