//
//  FPWriteCfs.ipf 
// 
// CFS file write
//
// Comments:
//
// History:
 
#pragma rtGlobals=1									// Use modern global access method.

static strconstant	ksDEF_FILEBASE5	= "No_Nm"	


Function		CreateGlobalsInFolder_CfsWrite_()
// creates all folder-specific variables. To be used once from CreateGlobals() as the current data folder is changed and not restored
	NewDataFolder  /O  /S root:uf:aco:cfsw
	string		/G	gsDataFileW		= ""				
	string		/G	gsDataPath		= ksDEF_DATAPATH
	string		/G	gsTmpDataPath		= ksDEF_DATAPATH	// only used for text input directory selection
	string  	/G	gsFileBase			= ksDEF_FILEBASE5
	variable	/G	gCell				= 0

	string  	/G	gsGenComm		= ksNoGeneralComment
	string  	/G	gsSpecComm		= "no specific comment"	

	variable	/G	gFileIndex			= -1				// 0..26x26-1..will be converted to AA, AB....ZY, ZZ. and stored in 7. and 8. character of file name
	variable	/G	gCFSHandle		= kCFS_NOT_OPEN	// for writing CFS file

	variable	/G	gbWriteMode		= 1				// write CFS file or watch only when starting an acquisition 

	variable	/G	gbAutoDelSpCom	= 0

	string		/G	gsXUnitsInCfs		=  "ms"			// Use 'millisecs'  only in Cfs files for compatibility with Pascal version. Use 'seconds'  elsewhere to prevent Igor from  labeling the axis e.g. 'kms'  (KiloMilliSeconds)
End


Function  		InitializeCFSDescriptors_( sFolder, sScript )
// Define CFS data descriptor templates DSArray (data section descriptor)  and FileArray (file descriptor)  and reset all values. Must be called before xCFSCreateFile()
// Store the script once in the file section.
	string  	sFolder, sScript
	variable	i, l
	// printf  "\t\t\t InitializeDescriptors()	\r"   

	// Set  FILEVAR  file descriptors  -  the  FILEVAR  entries  in   InitializeCFSDescriptors_()  and   CFSInitWrFile()  must match !
	xCFSSetDescriptor( FILEVAR, 0, "Data file from,INT2," +  ksAPP_NAME + ",0" )				//  Description, Type, Units, Size 
	xCFSSetDescriptor( FILEVAR, 1,  GetFileName_() + ksCFS_EXT + ",LSTR,file,20" )				// obsolete but kept for compatibility with Pascal programs...
	xCFSSetDescriptor( FILEVAR, 2,  "DataFile,LSTR,Data,20" )							// ...here is the current data file name stored, not above in the descriptor field

	xCFSSetDescriptor( FILEVAR, 3,  "StimFile,LSTR,Stim,30" ) 
	xCFSSetDescriptor( FILEVAR, 4,  "SwpPerFrm,LSTR,-,20" )	
	xCFSSetDescriptor( FILEVAR, 5,  "FrmPerProt,LSTR,-,20" )								// this is actually frames per block
	xCFSSetDescriptor( FILEVAR, 6,  "HasPoN,LSTR,-,20" )	
	xCFSSetDescriptor( FILEVAR, 7 , "Specific comment,LSTR,," + num2str( MAX_CFS_STRLEN ) )	// usable string length is one shorter

	// Store the script once in the file section : reserve space for storing the script lines
	for ( i = 8; i < SCRIPTBEGIN_IN_CFSHEADER; i += 1 )
		xCFSSetDescriptor( FILEVAR, i, "Spare,INT2,none,0" )
   	endfor

	variable	nLines
	// 050205	
if ( ! bNEWFILEVARS_ )
	nLines	= ItemsInList( sScript, "\r" )		// 1 script line = 1 FILEVAR line :  BAD space usage
	for ( l = 0; l < nLines; l += 1 )	
		i = SCRIPTBEGIN_IN_CFSHEADER + l
		xCFSSetDescriptor( FILEVAR, i , "Scriptline" + num2str( l ) + ",LSTR,," + num2str( MAX_CFS_STRLEN ) ) // usable string length is one shorter
   	endfor
   	
else
	nLines	= ceil( strlen( sScript ) / ( MAX_CFS_STRLEN - 1 ) )
	for ( l = 0; l < nLines; l += 1 )	
		i = SCRIPTBEGIN_IN_CFSHEADER + l
		xCFSSetDescriptor( FILEVAR, i , "ScriptBlock" + num2str( l ) + ",LSTR,," + num2str( MAX_CFS_STRLEN ) ) // usable string length is one shorter
   	endfor
   	
endif


	for ( i = SCRIPTBEGIN_IN_CFSHEADER + nLines; i < MAX_FILEVAR ; i += 1 )
		xCFSSetDescriptor( FILEVAR, i, "Spare,INT2,none,0" )
   	endfor

	// Set  DSVAR  data section descriptors  -  the  DSVAR  entries  in   InitializeCFSDescriptors_()  and  WriteHeader()  must match !  The order is defined in  'lstDS_TEXT' .
	for ( i = 0;  i < ItemsInList( lstDS_TEXT ); i += 1 )
		xCFSSetDescriptor( DSVAR,  i, StringFromList( i, lstDS_TEXT ) )				//  contains Description, Type, Units, Size 
	endfor

	for ( i =   ItemsInList( lstDS_TEXT );  i <  MAX_DSVAR; i += 1 )
		xCFSSetDescriptor( DSVAR, i, "Spare,INT2,none,0" )	
	endfor

End      


Function		WriteDataSection( sFolder, wG, wIO, wVal, wFix, pr, bl, fr, sw )		// PROTOCOL  AWARE  031007
// break big waves (one per adc, all frames and sweeps together) into sections for  xCFSWriteData() (=into single sweeps) )
// Limitation....writes always / only 'Adc' channels
// 030312b TelegraphGain() made independent of WriteMode
// could probably be done more elegantly...............
	string  	sFolder
	wave  /T	wIO, wVal
	wave	wG, wFix
	variable	pr, bl, fr, sw
	nvar		gbWriteMode	= root:uf:aco:cfsw:gbWriteMode
	nvar		gCFShnd		= root:uf:aco:cfsw:gCFSHandle		// 030312 global , was local
	nvar		gRadDebgSel	= root:uf:dlg:gRadDebgSel
	nvar		PnDebgCFSw	= root:uf:dlg:Debg:CfsWr 
	variable	nSmpInt		= wG[ kSI ]
	variable	nCntAD		= wG[ kCNTAD ]	
	variable	BegPt		= SweepBegSave( sFolder, pr, bl, fr, sw )	
	variable	EndPt		= SweepEndSave( sFolder, pr, bl, fr, sw )
	variable	nPts			= EndPt - BegPt
	variable	OldHnd		= gCFSHnd				// for debug printing
	variable	c, nIO		= kIO_ADC	

	// STEP 1 :
	// Get the telegraph gain by reading the big wave and store the values in  wave 'wIO' , from which they can be retrieved with  'cIOGAINOLD'   and   ' YScale(c) '
	for ( c = 0; c < nCntAD; c += 1 )
		if ( HasTG( wIO, nIO, c ) ) 												// This is a true Adc channel having a corresponding telegraph channel... 
			ioSet( wIO, nIO, c, cIOGAIN, num2str(TelegraphGain( sFolder, wIO, nIO, c, BegPt ) ) )// ...so store the gain value (measured and computed from wBig) indexed by Adc index in script 
		elseif ( HasTGMC( wIO, nIO, c ) ) 										// This is a true Adc channel having a corresponding MULTICLAMP telegraph channel...
			ioSet( wIO, nIO, c, cIOGAIN, num2str(TelegraphGainMC( wIO, nIO, c ) ) )		// ...so store the gain value  which the AxoPatch MultiClamp has given
		endif

		if ( iov( wIO, nIO, c, cIOGAIN ) != iov( wIO, nIO, c, cIOGAINOLD )	)				// Only if the gain has really changed do the time-consuming storage and update...
			BuildGainInfo( wG, wIO, cGAININFO )									// The gain info string is displayed at the right edge of the status bar
			PossiblyAdjstSliderInAllWindow_( wIO )								// Can be commented out if it is too slow. Different approach would be to change YOfs slider like the YAxis  in DispDurAcq()  ???
			ioSet( wIO, nIO, c, cIOGAINOLD,  ios( wIO, nIO, c, cIOGAIN ) )				// Remember that gain changes have been handled so that they will not be unnecessarily handled a 2. time 	
		endif
	endfor

	// STEP 2 :  write the data into the CFS file
	if ( gbWriteMode )			

// 060511f   Append mode comments  and renaming
		if ( gCFSHnd == kCFS_NOT_OPEN  )	
			nvar		bAppendData_	= $"root:uf:"+sFolder+":dlg:gbAppendData"
			nvar		bIncremFile	= root:uf:aco:co:gbIncremFile
			if ( gbWriteMode )										// Do the automatic file name incrementation only when it is intended to really write a file, not when only in watch mode.
				if ( ! bAppendData_ )
					AutoBuildNextFilename()							// 	Increment the automatically built file name (= go to next  fileindex ) only if the user does not want to append 
				endif
				if (  bAppendData_  &&  bIncremFile ) 						// 	...OR  increment  after having executed  'Finish'  (bIncremFile=TRUE)    EVEN  if the user actually  does NOT want to incremenent
					AutoBuildNextFilename()							//  ( Only when a new file is to be written for each run then increment  even if the user actually  does wants to append )
					bIncremFile	= FALSE
				endif
			endif
			gCFShnd = CFSInitWrFile( sFolder, wIO, wFix, nCntAD )			// also sets global handle internally
		endif
		if ( gRadDebgSel > 2  &&  PnDebgCFSw )
			printf "\t\t\t\tCFSWriteDataSection( p:%2d\tb:%2d\tf:%2d\ts:%2d\t-> BegP:%5d \tEndP:%5d\tPts:%4d)  File WAS %s\tOPEN, CFSHnd before:%2d \t/ after:%2d\t  InitWrFile()\r", pr, bl, fr, sw, BegPt, EndPt, nPts, SelectString(OldHnd == kCFS_NOT_OPEN,"    ", "NOT"), Oldhnd , gCFShnd  
		endif

		if  ( gCFShnd != kCFS_NOT_OPEN )

			for ( c = 0; c < nCntAD; c += 1 )
				string 	sBig	=  FldAcqioio( sFolder, wIO, kIO_ADC, c, cIONM )
				WriteBlocks( sFolder, wIO, gCFShnd, sBig, c, BegPt, nPts, nSmpInt, nCntAD ) 
			endfor
																
			WriteHeader( wG, wVal, wFix, gCFShnd, nPts, nSmpInt, bl, fr, sw, 0 )														
			FinishDataSection( gCFShnd )
	
			if (  ePoN( wFix, bl ) ) 		
				// write 'PoN' corrected data sweeps
				WriteDataPoN( sFolder, wG, wIO, wVal, wFix, gCfsHnd, bl, fr, sw, BegPt, nPts, nSmpInt, nCntAD  )
			endif
																
		endif
																
	endif

	wG[ kSWPS_WRITTEN ] += 1
	return	gCFShnd
End


static Function		WriteDataPoN( sFolder, wG, wIO, wVal, wFix, CfsHnd, bl, fr, sw, BegPt, nPts, SmpInt, nChans )
// 030312b  making the TelegraphGain() independent of WriteMode  seems here (=PoN trace) unnecessary
	string  	sFolder
	wave  /T	wIO, wVal
	wave	wG, wFix
	variable	CFShnd, bl, fr, sw,BegPt, nPts, SmpInt,  nChans
	nvar		gRadDebgSel	= root:uf:dlg:gRadDebgSel
	nvar		PnDebgCFSw	= root:uf:dlg:Debg:CfsWr 
	variable	c
	string		sBig
	if ( sw > 0  &&  sw == eSweeps( wFix, bl ) - 1 )				// store 'PoN' only once after last sweep. If there is ony 1 sweep, don't store PoN.  Better: catch this earlier...) 
		for ( c = 0; c < nChans; c += 1 )					// store 'PoN' data only of last sweep
			// select wave to be stored depending on users choice: do PoverN for this channel or not (it is users responsibility that it is a true AD and not a telegraph..)
			//sBig	= SelectString( DoPoverN( c ),  io( "Adc", c, cIONM ),    "PoN" + sIOCHSEP + io( "Adc", c, cIOCHAN ) )	 
			sBig	= SelectString( DoPoverN( wIO, c ),  FldAcqioio( sFolder, wIO, kIO_ADC, c, cIONM ),    FldAcqioPoNio( sFolder, wIO, kIO_ADC, c, cIOCHAN ) )	 
			// printf "\t\t\t\tCFSW write   corrected \tDS(\tfr:%d, sw:%d)   c:%d   BegPt:%d   nPts:%d  '%s' \r",  fr, sw, c, BegPt, nPts, sBig
			if ( gRadDebgSel > 2  &&  PnDebgCFSw )
				printf "\t\t\t\tCFSW write   corrected \tDS(\tfr:%d, sw:%d)   c:%d   BegPt:%d   nPts:%d  '%s' \r",  fr, sw, c, BegPt, nPts, sBig
			endif
			WriteBlocks( sFolder, wIO, CFShnd, sBig, c, BegPt, nPts, SmpInt, nChans ) 
		endfor
		WriteHeader( wG, wVal, wFix, CFShnd, nPts, SmpInt,  bl, fr, sw, 1 )	// write PoverN corrected trailer after all channels have been processed 
		FinishDataSection( CFShnd )
	endif
End


static Function		WriteBlocks( sFolder, wIO, CFShnd, sBig, c, BegPt, nPts, SmpInt, nChans ) 
// writes 1 datasection (= 1 sweep) to CFS file. Datasection can be larger than 64KB, it is then split into blocks 
// CFS handle, channel number, actual data section is used here,...
	string  	sFolder
	wave  /T	wIO
	variable	CFShnd, c, BegPt, nPts, SmpInt, nChans
	string		sBig
	wave	wBig			= $sBig					// this is 'AdcN', 'PoNN'...
	nvar		gRadDebgSel	= root:uf:dlg:gRadDebgSel
	nvar		PnDebgCFSw	= root:uf:dlg:Debg:CfsWr
	nvar		PnDebgTeleg	= root:uf:dlg:Debg:Telegraph 
	variable	nStartByteOffset							// offset in bytes from the start of the data section to the first byte of data for this channel...
	variable	nBytes		= nPts * 2
	variable	nBlockBytes, b, nBlocks = trunc( ( nBytes - 1) / kCFSMAXBYTE ) + 1
	variable	nIO			=  kIO_ADC

	for ( b = 0; b < nBlocks; b += 1 )
		// Avoid memory consuming multiple unique names for each 'wSmall' , allow only temporarily for the Test display below 
		// make /O /W /N=( kCFSMAXBYTE )	$SmallWav( c, b, BegPt )	// 32K is largest CFS section...constructing the partial wave with...
		// wave  	wSmall 		=		 	$SmallWav( c, b, BegPt )	// ..unique name is necessary only for the test display below
		// print "\t each smallwav consumes 128KB : ", SmallWav( c, b, BegPt )
		make /O /W /N=( kCFSMAXBYTE )	root:uf:aco:cfsw:wSmall				// 32K is largest CFS section
		wave	wSmall	= root:uf:aco:cfsw:wSmall
		nBlockBytes = ( b == nBlocks - 1 ) ? nBytes - b * kCFSMAXBYTE : kCFSMAXBYTE
		variable	code	= xUtilWaveCopy( wSmall, wBig, nBlockBytes / 2, BegPt + b * kCFSMAXBYTE / 2, kMAXAMPL / kFULLSCL_mV ) 	// 030525
		if ( code )
			printf "****Error: xUtilWaveCopy() \r"
		endif

		nStartByteOffset = c * 2 * nPts + b * kCFSMAXBYTE 
		if (  gRadDebgSel > 3  &&  PnDebgCFSw )
			printf  "\t\t\t\t\tCFSWrDS   ADC[c:%d] in CEDch:%d  '%s'  StartByteOfs:%d  Endbyte:%d  (=%dBytes)\r",  c, iov( wIO, nIO, c, cIOCHAN ), FldAcqioio( sFolder, wIO, nIO,c, cIONM ),  nStartByteOffset, nStartByteOffset + nBytes, nBytes  
		endif
		// Avoid memory consuming multiple unique names for each 'wSmall' , allow only temporarily for the Test display below 
		// print "\tUnique name is needed for wSmall", ch, b, BegPt, nPts;	dowindow /K $SmallWnd( c, b, BegPt );	display wsmall;	dowindow /C $SmallWnd( c, b, BegPt )
		//  0 = write to current data section, Byte offset, number of bytes to write, wave buffer. Channels are written one after the other
		xCFSWriteData( CFShnd, 0,  nStartByteOffset, nBlockBytes, wSmall, ERRLINE ) 
		// killwaves wSmall			// can kill only  when wave is not displayed
	endfor
		
	// printf "\t\t\t\t\tCFSWrDS   c:%d   internal name:'%s'   user name:'%s' \r", c, FldAcqioIov2( nIO, c, cIONM ), ios(  nIO, c, cIONAME )
	if ( gRadDebgSel > 3  &&  PnDebgCFSw )
		 printf "\t\t\t\t\tCFSWrDS   c:%d   internal name:'%s'   user name:'%s' \r", c, FldAcqioio( sFolder, wIO, nIO, c, cIONM ), ios( wIO, nIO, c, cIONAME )
	endif

	// ..offset in bytes from the start of the data section to the first byte of data for this channel,  Points,  YScale,  YOffset,  XScale,  XOffset, print errors only or also infos
	xCFSSetDSChan( CFShnd, c, 0, c * 2  *nPts, nPts, YScale( wIO, c ), 0, SmpInt / kMILLITOMICRO, 0, ERRLINE )
	if ( gRadDebgSel > 3  &&  ( PnDebgCFSw || PnDebgTeleg ) )
		printf "\t\t\t\t\tCFSWrDS   xCFSSetDSChan()   c:%d  startbyte:\t%8d\t  endbyte:\t%8d\t   yScale (<Gain<Telegraph):%g \r", c, c *2*nPts, c * 2*nPts + 2*nPts, YScale( wIO, c )
	endif
         // printf "\t\t\t\t\tCFSWrDS   xCFSSetDSChan()   c:%d  startbyte:\t%8d\t  endbyte:\t%8d\t   yScale (<Gain<Telegraph):%g \r", c, c *2*nPts, c * 2*nPts + 2*nPts, YScale( c )
	// xCFSCommitFile( CFShnd, ERRLINE )	// takes ~2us / data , removed because it  decreases maximum data rate by about 30% (very rough estimate) 
End	

// Avoid memory consuming multiple unique names for each 'wSmall' , allow only temporarily for the Test display below 
// Static	Function   /S	SmallWav( ch, bl, BegPt )
//	variable	ch, bl, BegPt
//	return	"WavSmall_ch_" + num2str( ch ) + "_bl" + num2str( bl ) + "_bg" + num2str( BegPt ) 
// End
// Static	Function   /S	SmallWnd( ch, bl, BegPt )
//	variable	ch, bl, BegPt
//	return	"WndSmall_ch_" + num2str( ch ) + "_bl" + num2str( bl ) + "_bg" + num2str( BegPt )	
// End


constant bNEWFILEVARS_ =  1//     050205    set to 1 after testing   and eliminate.....

static Function		CFSInitWrFile( sFolder, wIO, wFix, nChans )
	string  	sFolder
	wave  /T	wIO
	wave	wFix
	variable	nChans				// number of channels (PascalPulse: 1 or 2,  IGOR: any number )
	nvar		gCFSHandle	= root:uf:aco:cfsw:gCFSHandle
	nvar		gFileIndex		= root:uf:aco:cfsw:gFileIndex
	svar		gsGenComm	= root:uf:aco:cfsw:gsGenComm
	svar		gsSpecComm	= root:uf:aco:cfsw:gsSpecComm
	svar		gsDataFileW	= root:uf:aco:cfsw:gsDataFileW
	nvar		gRadDebgSel	= root:uf:dlg:gRadDebgSel
	nvar		PnDebgCFSw	= root:uf:dlg:Debg:CfsWr 
	svar		gsXUnitsInCfs	= root:uf:aco:cfsw:gsXUnitsInCfs
	svar		gsScriptPath	= root:uf:aco:script:gsScriptPath
	string		bf, sChanName						// channel name,  used by SetFileChan from CFS
	string		sOChar		= "O"				// write 'O' for original data
	variable	c
	string		sPath		= GetPathFileExt( gFileIndex )
	variable	bFileExists		= FileExists( sPath )
	string		sBuf
	
	// Sould but does not control disk access, which is about 11..12 us/WORD for any value from 1 to 1024 (2001, Win95, 350MHz Pentium, file of 360KB) 
	variable	CFSBlockSize = 1 // 1=slow disk access , 1~11.5us/pt, 4~11.5, 16~ 11.8, 64~11.6, 128~11.8, 256~11.2, 512~12, 1024~12 )
	variable	CFShnd = xCFSCreateFile( sPath, gsGenComm, CFSBlockSize , nChans, MAX_DSVAR, MAX_FILEVAR, ERRLINE ) // sizes of fileArray and DSArray: all as in PatPul 
	if ( CFShnd > 0 )								// file creation was successful
		if ( gRadDebgSel > 0  &&  PnDebgCFSw )
			printf  "\t\tCFSWr InitWrFile(Cfs/AdcChans:%d)    xCFSCreateFile() opens '%s' and returns CFSHandle %d . File did %s exist. \r", nChans, sPath, CFShnd, SelectString( bFileExists, "NOT", "" )
		endif
		gCFSHandle =  CFShnd 					// set global   AND  return  value (below)

		for ( c = 0; c < nChans; c += 1 )
			variable	nIO	= kIO_ADC
			// printf  "\t\t\t\tCFSWr InitWrFile()   ADC[idxch=ch:%d/%d] in CEDch:%d  internal name:'%s'   user name:'%s'   YUnits:'%s'   XUnitInCfs:'%s'\r", c, nChans, iov( wIO, nIO, c, cIOCHAN ), FldAcqioio( wIO, nIO,c, cIONM ),  ios( wIO, nIO, c, cIONAME ), ios( wIO, nIO, c, cIOUNIT ),  gsXUnitsInCfs
			if ( gRadDebgSel > 2  &&  PnDebgCFSw )
				printf  "\t\t\t\tCFSWr InitWrFile()   ADC[idxch=ch:%d/%d] in CEDch:%d  internal name:'%s'   user name:'%s'   YUnits:'%s'   XUnitInCfs:'%s'\r", c, nChans, iov( wIO, nIO, c, cIOCHAN ), FldAcqioio( sFolder, wIO, nIO,c, cIONM ),  ios( wIO, nIO, c, cIONAME ), ios( wIO, nIO, c, cIOUNIT ),  gsXUnitsInCfs
			endif
			// CFS handle, channel number, channelname, Y units (=current or voltage), X units (=time), data saved as 2 byte integers,...
			// ...equalspaced data (=not matrix), INT2 data with no intervening data (=2), last parameter is irrelevant in equalspaced mode (see PatPul)
			sChanName =  ios( wIO, nIO, c, cIONAME )  
			if ( strlen( sChanName ) == 0 )											//  If channel name is missing...
				sChanName	= ioTNm( nIO ) + num2str( iov( wIO, nIO, c, cIOCHAN) )		// ..supply a default channel name because ReadCFS needs one
			endif
			xCFSSetFileChan( CFShnd, c,  sChanName, ios( wIO, nIO, c, cIOUNIT ), gsXUnitsInCfs, INT2, kEQUALSPACED, 2, 0, ERRLINE )
		endfor

		//? The  FILEVAR  entries  in   InitializeCFSDescriptors_()  and   CFSInitWrFile()  must match !
		xCFSSetVarVal( CFShnd, 0, FILEVAR, 0, ksVERSION , ERRLINE)					// data section variable 0 stores version number	e.g. '301c'
		xCFSSetVarVal( CFShnd, 1, FILEVAR, 0, sOChar, ERRLINE)						// data section variable 1 stores 'O' for original data
		xCFSSetVarVal( CFShnd, 2, FILEVAR, 0, gsDataFileW, ERRLINE )					// DataFile
		xCFSSetVarVal( CFShnd, 3, FILEVAR, 0, StripPathAndExtension( gsScriptPath ), ERRLINE )	// StimFile
// ?eBlocks( wG )
		variable	b = 0
		xCFSSetVarVal( CFShnd, 4, FILEVAR, 0, num2str( eSweeps( wFix, b ) ), ERRLINE ) 		// SwpPerFrame

		variable	bHasPoN, nFrmPerBlk = eFrames( wFix, b )
		xCFSSetVarVal( CFShnd, 5, FILEVAR, 0, num2str( nFrmPerBlk ), ERRLINE ) 				// FrmPerBlk

		bHasPoN	= ePoN( wFix, b ) 												// 030312 since the script is stored in the CFS file it is possible (and more reliably) to extract 'HasPon?' directly from script

		xCFSSetVarVal( CFShnd, 6, FILEVAR, 0, num2str( bHasPoN ), ERRLINE ) 				// HasPoN
		xCFSSetVarVal( CFShnd, 7, FILEVAR, 0, gsSpecComm, ERRLINE ) 					// specific comment
		
	   	// Store the script once in the file section : Fill in the data = store the script lines 
		variable	i, l, nLines
		string  	sLine
		svar		gsScript		= $"root:uf:" + sFolder + ":gsScript"						// 050205

if ( ! bNEWFILEVARS_ )
		// 1 script line = 1 FILEVAR line :  BAD space usage
		nLines	= ItemsInList( gsScript, "\r" )
		for ( l = 0; l < nLines; l += 1 )	
			i 	= SCRIPTBEGIN_IN_CFSHEADER + l
			sLine	= StringFromList( l, gsScript, "\r" )
			// printf  "\t\tCFSWr InitWrFile(chans:%d) \tl :%3d / %3d ->\t i :%3d    '%s'  \r", nChans, l,  nLines,  i, sLine
			if ( i < MAX_FILEVAR )										
	   			xCFSSetVarVal(  CFSHnd, i, FILEVAR, 0, sLine, ERRLINE )	
			endif
		endfor
else
		nLines	= ceil( strlen( gsScript ) / ( MAX_CFS_STRLEN - 1 ) )						// 050205 store scripts in blocks..
		for ( l = 0; l < nLines; l += 1 )												// ..store multiple script lines in 1 FILEVAR line
			i 	= SCRIPTBEGIN_IN_CFSHEADER + l								// we can now store scripts up to appr. 16KB (64 lines x 252 bytes) 
			sLine = gsScript[   l *  ( MAX_CFS_STRLEN - 1 ) ,  ( l + 1 ) *  ( MAX_CFS_STRLEN - 1 )  - 1 ] 
			// printf  "\t\tCFSWr InitWrFile(chans:%d) \tl :%3d / %3d ->\t i :%3d    '%s'  \r", nChans, l,  nLines,  i, sLine
			if ( i < MAX_FILEVAR )										
	   			xCFSSetVarVal(  CFSHnd, i, FILEVAR, 0, sLine, ERRLINE )	
			endif
		endfor
endif

		if ( i >= MAX_FILEVAR )											
   			sprintf sBuf, "Scripts is too long to be stored entirely in CFS file. Truncated at line %d of %d . ", MAX_FILEVAR, i
   			Alert( kERR_IMPORTANT, sBuf )
   		endif
   		
		if ( gRadDebgSel > 2  &&  PnDebgCFSw )
			printf "\t\t\t\tWr CFSInitWrFile()    xCFSSetVarVal()  \r"
		endif	
	else
		Alert( kERR_FATAL,  "Cannot open CFS path '" + sPath + "' " )
		CFShnd = kCFS_NOT_OPEN
	endif
	return CFShnd	// positive: file creation OK, negative: file creation error code ,   AND  also set global  (above)
End

 constant	SCRIPTBEGIN_IN_CFSHEADER = 15	

static Function		WriteHeader(  wG, wVal, wFix, hnd, nPts, SmpInt, bl, fr, sw, pon )
	wave	/T	wVal
	wave	 wG, wFix
	variable	hnd, nPts, SmpInt, bl, fr, sw, pon 
	string		bf
	variable	SampleFreq	= 1000 /  SmpInt 			// 040202  SF =  Round( 1000 /  SmpInt ) 	was  wrong as it clips at SmpInt=1000us
	variable	Tim			= TimeElapsed_()				// these are the actual ticks counted. Another possibility: Compute time of this sweep from script including blank section.
	variable	Duration		= Round( nPts * SmpInt / 1000 )
	variable	Start			= 0
	variable	PreVal		= 2						// minimum CED1401 clock prescaler value. Useless but kept for compatibility
	variable	CountVal		= Round( 100 * SmpInt / 1000 )	//  Pulse / StimFit has 10 
	variable	Mode		= ERRLINE
	// printf  "\t\t\t\tCFSWriteHeader(   hnd:%d  nPts:%d   SmpInt%g  blk:%2d/%2d   fr:%2d/%2d    sw:%2d/%2d  PoN:%d/%d )   xCFSSetVarVal   18x  \r", hnd, nPts, SmpInt, bl, eBlocks( wG ), fr, eFrames(bl), sw,eSweeps(bl), pon, ePon(bl)  

	// The  DSVAR  entries  in   InitializeCFSDescriptors_()  and  WriteHeader()  must match ! The order is defined in  'lstDS_TEXT' .
	// CFS handle, var number=index, which array, data section, string or variable value (as string) 
	xCFSSetVarVal( hnd,  0, DSVAR, 0, num2str( SampleFreq ),			Mode )
	xCFSSetVarVal( hnd,  1, DSVAR, 0, num2str( Tim ),				Mode )
	xCFSSetVarVal( hnd,  2, DSVAR, 0, num2str( Duration ),			Mode )
	xCFSSetVarVal( hnd,  3, DSVAR, 0, num2str( Start ),				Mode )
	xCFSSetVarVal( hnd,  4, DSVAR, 0, num2str( Duration ),			Mode )
	xCFSSetVarVal( hnd,  5, DSVAR, 0, num2str( PreVal ),				Mode )
	xCFSSetVarVal( hnd,  6, DSVAR, 0, num2str( CountVal ),	 		Mode )
	xCFSSetVarVal( hnd,  7, DSVAR, 0, vGetS( wVal, "Protocol", "Name" ), Mode )
	xCFSSetVarVal( hnd,  8, DSVAR, 0, num2str( bl ),					Mode )		
	xCFSSetVarVal( hnd,  9, DSVAR, 0, num2str( fr ),					Mode )			
	xCFSSetVarVal( hnd, 10, DSVAR, 0, num2str( sw ),				Mode )
	xCFSSetVarVal( hnd, 11, DSVAR, 0, num2str( pon ),				Mode )		
	xCFSSetVarVal( hnd, 12, DSVAR, 0, num2str( eBlocks( wG ) ), 		Mode )	
	xCFSSetVarVal( hnd, 13, DSVAR, 0, num2str( eFrames(wFix, bl) ),		Mode )		
	xCFSSetVarVal( hnd, 14, DSVAR, 0, num2str( eSweeps(wFix, bl) ),	Mode )		
	xCFSSetVarVal( hnd, 15, DSVAR, 0, num2str( ePon(wFix, bl) ),		Mode )		
End


static Function		FinishDataSection( CFShnd )
	variable	CFShnd
	nvar		gRadDebgSel	= root:uf:dlg:gRadDebgSel
	nvar		PnDebgCFSw	= root:uf:dlg:Debg:CfsWr
	string		bf
	// write complete data section to disk, 0 means append to end of file,  don't care about 16 flags
	xCFSInsertDS( CFShnd, 0, kNOFLAGS, ERRLINE ) // 0: write complete data section to disk by appending to end of file, 
	if ( gRadDebgSel > 1  &&  PnDebgCFSw )
	       printf  "\t\t\tCFSWr FinishDataSection(CFShnd:%d)   xCFSInsertDS()..  \r", CFShnd 
	endif
	// xCFSCommitFile( CFShnd, ERRLINE )	// takes ~2us / data , removed because it  decreases maximum data rate by about 30% (very rough estimate) 
End


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//   TELEGRAPH  CHANNELS  during  CFSWrite

static constant	TOLERANCE				= 0.2		// tolerance for acceptance of a value, z.B: ERR(5.2-5.3), OK(5.3-5.7) 
static constant	cADCGAIN_OUT_OF_TOLER	= 1.0		// returned when read value lies between the expected values 		(1.0001 could be used as marker) 
static constant	cADCGAIN_OUT_OF_RANGE	= 1.0		// returned to avoid horrible values when telegraph inputs not plugged	(1.0002 could be used as marker) 


Static  Function	YScale( wIO, c )
// converts Gain( Adc channel number in script )  into  scale value( index is counted up 0,1,2.. ) .  Needed  in CFSWrite
	wave  /T	wIO
	variable	c
	return	kFULLSCL_mV / kMAXAMPL / iov( wIO, kIO_ADC, c, cIOGAIN )

End	
	
Function		BuildGainInfo( wG, wIO, nAmount )
// Constructs and returns gain info string to be used in the Statusbar
	wave	wG
	wave  /T	wIO
	variable	nAmount		// controls how much is printed :  only Adc gains  or   Dac + Adc gains
	variable	ch								// c : index in script 0,1,2...,  ch : true channel number
	string		/G	root:uf:aco:cfsw:gsAllGains	= ""	
	svar		gsAllGains	= root:uf:aco:cfsw:gsAllGains
	string  	sCh
	gsAllGains	= ""	
	variable	nCntAD	= wG[ kCNTAD ]	
	variable	nCntDA	= wG[ kCNTDA ]	
	variable	c, nIO	= kIO_DAC
	if ( nAmount == 1 )
		for ( c = 0; c < nCntDA; c += 1 )
			gsAllGains	+= ios( wIO, nIO, c, cIONM ) + ": " + ios( wIO, nIO, c, cIOGAIN ) + "   " 	
		endfor
	endif	
	nIO	= kIO_ADC
	for ( c = 0; c < nCntAD; c += 1 )
		sCh	= ios( wIO, nIO, c, cIOCHAN )
		if ( TGChan( wIO, nIO, c )  !=  kNOTFOUND )									// this is a true Adc channel having a corresponding telegraph channel 
			gsAllGains	+= "Gn" + sCh + "(tg" + num2str( TGChan( wIO, nIO, c ) ) + "): " +  ios( wIO, nIO, c, cIOGAIN ) + "   " 
		elseif ( TGMCChan( wIO, nIO, c )  !=  kNOTFOUND )								// this is a true Adc channel having a corresponding MULTICLAMP telegraph channel
			gsAllGains	+= "Gn" + sCh + "(mc" + num2str( TGMCChan( wIO, nIO, c ) ) + "): " +  ios( wIO, nIO, c, cIOGAIN ) + "   " 
		else																	// this is a true Adc channel  without  a corresponding telegraph channel
			gsAllGains	+= "Gn" + sCh + "(fix): " +  ios( wIO, nIO, c, cIOGAIN ) + "   " 	
		endif
	endfor
	// printf "\t\t\t\t\tBuildGainInfo()  '%s'    nCntDA:%d  nCntAD:%d \r", gsAllGains, nCntDA, nCntAD
End
  
// 040116  Unfortunately we cannot use this access function as this would inhibit the automatical update in the status bar ??? How does LaggingTime() work???
//Function	/S	AllGainsInfo()
//	string		/G	root:uf:aco:cfsw:gsAllGains	
//	svar		gsAllGains		= root:uf:aco:cfsw:gsAllGains
//	return	gsAllGains
//End


Function		TelegraphGainPreliminary_( wG, wIO, hnd )
// Get all telegraph gains early before the acq starts so that the Y axis can also already be adjusted before the acq starts. 
	wave	wG
	wave  /T	wIO
	variable	hnd
	string		bf
	variable	Chan, TGChan, TGMCChan					// true channel numbers
	variable	c, nIO	= kIO_ADC
	variable	nCntAD	= wG[ kCNTAD ]	
	for ( c = 0; c < nCntAD; c += 1 )
		Chan		= iov( wIO, nIO, c, cIOCHAN ) 
		if (  HasTG( wIO, nIO, c ) )
			TGChan	= iov( wIO, nIO, c, cIOTGCH ) 
			ioSet( wIO, nIO, c, cIOGAIN, num2str( TelegraphGainOnce( wIO, nIO, c, hnd ) ) )			// Get the telegraph gain before the acq starts so that the y axis can be adjusted 
			sprintf bf, "\t\t\t\tTelegraphGainPreliminary() \tFound AD %d  with   \tTGChan %d.      \tSetting Gain: %s  \r",  Chan,  TGChan, ios( wIO, nIO, c, cIOGAIN )  ; Out1( bf, 0 )
		endif
		if (  HasTGMC( wIO, nIO, c ) )
			TGMCChan	= iov( wIO, nIO, c, cIOTGMCCH )
			ioSet( wIO, nIO, c, cIOGAIN, num2str( TelegraphGainMC( wIO, nIO, c ) ) )					// Get the MC telegraph gain before the acq starts so that the y axis can be adjusted 
			sprintf bf, "\t\t\t\tTelegraphGainPreliminary() \tFound AD %d  with   \tTGMCChan %d.  \tSetting Gain: %s  \r",  Chan,  TGMCChan, ios( wIO, nIO, c, cIOGAIN )  ; Out1( bf, 0 )
		endif
	endfor
End


Static  Function	TelegraphGainOnce( wIO, nIO, c, hnd )
// Get right now 1 value from the Adc so that the telegraph gains are known before the acq starts so that the Y axis can be adjusted before the acq starts. 
// This works for any true Adc channel having a corresponding voltage controlled telegraph channel (not for a MultiClamp!)  .  Gain is returned from  Axopatch in mV / pA or mV / mV 
	wave  /T	wIO
	variable	nIO, c, hnd			 											// ioch is linear index in script
	variable	nTGChan		= TGChan( wIO, nIO, c )									//  nTGChan is true TG  channel number in script
	variable	ch			= iov( wIO, nIO, c, cIOCHAN )								// ch is true Adc channel number in script
	variable	AdcValue		= 0
	string 	command		= "ADC, " + num2str(  nTGChan ) + ";"						// get right now 1 value from the Adc
	if ( xCedTypeOf( hnd )  != kNOTFOUND )												// check if Ced is open
		AdcValue	= xCEDGetResponse( hnd, command, command, 0 ) * kFULLSCL_mV / kMAXAMPL	// last param is 'ErrMode' : display messages or errors
	endif
	variable	Gain 			= TGAdc2Gain( AdcValue, nTGChan, ch )
	string	 	bf
	sprintf bf,  "\t\t\t\tTelegraphGainOnce(\tnIO:%d  c:%d  '%s' )\t\t\tAdc ch:%2d  is controlled by TG:%2d\t%.2lf V\tY:%8.3lf \t->TGGain:%7.2lf   \t \r", nIO, c, command, ch, nTGChan, AdcValue / 1000,  AdcValue,  Gain
	Out1( bf, 0 )
	return	Gain
End	


static Function	TelegraphGain( sFolder, wIO, nIO, c, BegPt )
// This works for any true Adc channel having a corresponding voltage controlled telegraph channel (not for a MultiClamp!) . 
// Gain is returned from  Axopatch in mV / pA or mV / mV  . This function is to be called every time when any true AD channel (not a Telegraph) has sampled data ready..
	string  	sFolder
	wave  /T	wIO
	variable	nIO, c, BegPt	 									// ioch is linear index in script
	nvar		gnCompress	= $"root:uf:" + sFolder + ":co:gnCompressTG"
	variable	ch			= iov( wIO, nIO, c, cIOCHAN )				// ch is true Adc channel number in script
	variable	nTGChan		= TGChan( wIO, nIO, c )					//  nTGChan is true TG  channel number in script
	string		sTGNm		= FldAcqioTgNm_( sFolder, nTGChan ) 
	wave  	wBig 		= $sTGNm								// this is 'AdcN' but only for telegraph channels
	variable	AdcValue		= wBig[ BegPt / gnCompress ]
	variable	Gain 			= TGAdc2Gain( AdcValue, nTGChan, ch )
	string	 	bf
	sprintf bf,  "\t\t\t\tTelegraphGain( \tnIO:%d c:%d ) sTGNm:\t%s\tAdc ch:%2d  is controlled by TG:%2d\t%.2lf V\tY:%8.3lf \t->TGGain:%7.2lf   \tBgP\t:%11d \t/ %8.2lf \t \r", nIO, c, pd( sTGNm,6), ch, nTGChan, AdcValue / 1000, AdcValue,  Gain, BegPt, BegPt/gnCompress
	Out1( bf, 0 )
	return	Gain
End	


static Function	TGAdc2Gain( AdcValue, nTGChan, ch )
	variable	AdcValue, nTGChan, ch 
	string		bf
	variable	GainVoltage	= AdcValue / 1000
	variable	index			= round( 2 * GainVoltage )
	//    corresponding signal in V; see Axopatch 200 manual for scaling of telegraph outputs
	//						Index		  0   1   2   3   4     5     6      7     8      9     10    11    12    13
	//						GainVoltage	  x   x    x    x  2.0  2.5  3.0  3.5  4.0  4.5   5.0   5.5   6.0   6.5		// Volt
	variable	Gain 	= str2num( StringFromList( index, " 1;  1;  1;  1;  .5;   1;    2;     5;   10;  20;   50;  100; 200; 500 " ) )	// mV / pA or mV / mV   
	if (  index < 4 || 13 < index )
		Gain = cADCGAIN_OUT_OF_RANGE
		sprintf bf, "TelegraphGainVoltage of TG chan %d (controlling Adc chan %d)  \t%.2lf V is out of allowed range ( %.1lf ...%.1lf V ). Gain %.1lf is returned. ", nTGChan, ch, GainVoltage, 2 -TOLERANCE, 6.5 +TOLERANCE, Gain
		Alert( kERR_IMPORTANT,  bf )
	elseif ( abs( index / 2 - GainVoltage ) > TOLERANCE ) 
		Gain = cADCGAIN_OUT_OF_TOLER
		sprintf bf, "TelegraphGainVoltage of TG chan %d (controlling Adc chan %d)  \t%.2lf V is out of tolerance ( %.1lf, %.1lf....%.1lf V +-%.1lf V ). Gain %.1lf is returned. ", nTGChan, ch, GainVoltage, 2, 2.5, 6.5, TOLERANCE, Gain
		Alert( kERR_IMPORTANT,  bf )
	endif
	return	Gain
End	

// 040927 TG without MC700TG XOP: works only partly (to retrieve gain the MCC700 channel must be switched which is not acceptable)
//static constant        	kMC700_MODEL	= 0 ,   kMC700_SERIALNUM	= 1 ,  kMC700_COMPORT = 2 ,   kMC700_DEVICE = 3 ,  kMC700_CHANNEL = 4
//static strconstant    	lstMC700_ID		= "Model;Serial#;COMPort;Device;Channel;"	// Assumption : Order is MoSeCoDeCh (same as in XOP)
static constant		kMC700_A		= 0 , kMC700_B	= 1
static strconstant	kMC700_MODELS	= "700A;700B"
//static constant	kMC700_MODE_VC	= 0 ,   kMC700_MODE_CC	= 1
static strconstant	kMC700_MODES	= "VC;IC;I=0"

// ASSUMPTION: Same separators ',;' and same entries 'HWTyp, SerNum, Port, AxoBus, Chan, Mode, Alpha, ScaleFct, Units' as in IGOR 'BreakInfo()' 


Static Function	TelegraphGainMC( wIO, nIO, c )		
//  Get and return the gain value  from the AxoPatch MultiClamp 
// ASSUMPTION: Same separators ' , ; ' and same entries 'HWTyp, SerNum, Port, AxoBus, Chan, Mode, Alpha, ScaleFct, Units' as in    'xMCTgPickupInfo()/UpdateDisplay()'  

// If the user specified in the script simple channel specs e.g. '1'    then check that there are only 2 channels available (=1 MCC700) and use it
// If the user specified extended channel specs e.g. '1_700A_Port_X_AxoBus_Y'   or  '2_700B_SN_xxxx'    then compare them with the available units: if they match  OK , if not print the  desired and the available identifications
	wave  /T	wIO
	variable	 nIO, c 															// ioch is linear index in script
	string  	sTGChan			= TGMCChanS_( wIO, nIO, c )								// e.g. '1'  or  '2'  or  '2_700A_Port_1_AxoBus_0'  or  '1_700B_SN_0'	// simple or extended spec
	variable	ch				= iov( wIO, nIO, c, cIOCHAN )						// ch is true channel number in script
	variable	Gain				= 0
	variable	nCode
	variable	MCTgChan 
string		sMCTgChannelInfo	= xMCTgPickupInfo()
	variable	MCTgChansAvailable	= ItemsInList( sMCTgChannelInfo )
	// printf "\t\tTelegraphGainMC( ioch:%d = Adc%d ) \tPickupInfo returns Chans avail: %d   '%s' \r", ioch, ch, MCTgChansAvailable, sMCTgChannelInfo

	string		sOneChannelInfo, s700AB, bf
	variable	rTyp, rSerNum, rComPort, rAxoBus, rChan, rMode, rMCGain, rSclFactor					// the specifiers which the MC700 has transmitted, extracted from  'PickUpInfo'
	string		rsSclFactorUnits
	variable	rScrTyp, rScrSerNum, rScrComPort, rScrAxoBus, rScrChan							// the specifiers extracted from script

	if ( CheckAvailableTelegraphChans( sTGChan, MCTgChansAvailable ) == kERROR )
		Alert( kERR_SEVERE, "MultiClamp Telegraph channel error.  Gain = 1 is returned for channel  Adc " + num2str( ch )  + " and  'TGMCChan = " + sTGChan + "' . " ) 
		return	1		// this is the default gain
	endif

	nCode	= CheckSimpleSpecAgainstTGCnt( sTGChan, rScrChan, MCTgChansAvailable ) 			// extract the only (= the channel) specifier  from script and  make sure that there are exactly 2 channels available

	if ( nCode  == kERROR )															// there were not exactly 2 available telegraph channels : we don't know how to connect

		Alert( kERR_SEVERE, "MultiClamp Telegraph channel error.  Gain = 1 is returned for channel  Adc " + num2str( ch )  + " and  'TGMCChan = " + sTGChan + "' . " ) 
		return	1		// this is the default gain

	elseif ( nCode == TRUE )															// OK : we have found a simple spec and  exactly 2 available telegraph channels 

		for ( MCTGChan = 0;  MCTGChan < MCTgChansAvailable;  MCTgChan += 1 )
			sOneChannelInfo	= StringFromList( MCTGChan, sMCTgChannelInfo )
			if ( BreakInfo( sOneChannelInfo, rTyp, rSerNum, rComPort, rAxoBus, rChan, rMode, rMCGain, rSclFactor, rsSclFactorUnits )  !=  9 )
				DeveloperError( "Expected 9 entries in  MCTG info string '" + sOneChannelInfo + "' .  AllChans: " + sMCTgChannelInfo ) 
			endif	
			if ( rChan == rScrChan )													// it is sufficient to check the channel as there are only 2 channels 
				Gain	= rMCGain * rSclFactor
				if ( rTyp ==  kMC700_A )
					sprintf s700AB, "CP:%3d    AB:%3d  ", rComPort, rAxoBus
				else
					sprintf s700AB, "SN:%15d", rSerNum
				endif
				sprintf bf, "\t\tTelegraphGainMC( nIO:%d, c:%d = Adc%d, sTGChan:\t%s\t)  %s \t%s\tTGCh:%2d\t'%s'\t   Gn:\t%7.2lf\tSc: %.1lf %s\t -> Gain: %5.1lf\t... \r", nIO, c, ch, pd( sTGChan, 22), StringFromList( rTyp, kMC700_MODELS),  s700AB, rChan, StringFromList( rMode,kMC700_MODES), rMCGain, rSclFactor, rsSclFactorUnits, Gain
				Out1( bf, 0 )
			endif	
		endfor

	else																			// OK : we have found an extended spec 

		if ( BreakExtendedSpec( sTGChan, rScrTyp, rScrSerNum, rScrComPort, rScrAxoBus, rScrChan ) == TRUE )	// extract the specifiers  from script.  sTGChan is extended spec, simple specs have already been processed.

			variable	nFound	= 0
			for ( MCTGChan = 0;  MCTGChan < MCTgChansAvailable;  MCTgChan += 1 )
				sOneChannelInfo	= StringFromList( MCTGChan, sMCTgChannelInfo )
				if ( BreakInfo( sOneChannelInfo, rTyp, rSerNum, rComPort, rAxoBus, rChan, rMode, rMCGain, rSclFactor, rsSclFactorUnits )  !=  9 )
					DeveloperError( "Expected 9 entries in  MCTG info string '" + sOneChannelInfo + "' .  AllChans: " + sMCTgChannelInfo )  
				endif	
				
				if ( rTyp == rScrTyp  &&  rChan == rScrChan  && ( ( rTyp == kMC700_A  &&  rComPort == rScrComPort   &&  rAxoBus == rScrAxoBus )  ||  ( rTyp == kMC700_B  &&  rSerNum == rScrSerNum ) ) )
					if ( rTyp ==  kMC700_A )
						sprintf s700AB, "CP:%3d    AB:%3d  ", rComPort, rAxoBus
					else
						sprintf s700AB, "SN:%15d", rSerNum
					endif
					nFound	+= 1
					Gain		= rMCGain * rSclFactor
					sprintf bf, "\t\tTelegraphGainMC( nIO:%d, c:%d = Adc%d, sTGChan:\t%s\t)  %s \t%s\tTGCh:%2d\t'%s'\t   Gn:\t%7.2lf\tSc: %.1lf %s\t -> Gain: %5.1lf\t... \r", nIO, c, ch, pd( sTGChan, 22), StringFromList( rTyp, kMC700_MODELS),  s700AB, rChan, StringFromList( rMode,kMC700_MODES), rMCGain, rSclFactor, rsSclFactorUnits, Gain
					Out1( bf, 0 )
				endif	
			endfor
			if ( nFound  != 1 )  
				Alert( kERR_SEVERE, "MultiClamp Telegraph channel not connected.  Gain = 1 is returned for channel  Adc " + num2str( ch )  + " and  'TGMCChan = " + sTGChan + "' . " ) 
				return	1		// this is the default gain
			endif

		else
			Alert( kERR_SEVERE, "MultiClamp Telegraph channel error.  Gain = 1 is returned for channel  Adc " + num2str( ch )  + " and  'TGMCChan = " + sTGChan + "' . " ) 
			return	1		// this is the default gain
		endif

	endif


	variable	nTGChan		= TGMCChan( wIO, nIO, c )
	if ( nTGChan != rScrChan )
		InternalError( "nTGChan != rScrChan" ) 
	endif


//	// printf "\t\tTelegraphGainMC( ioch:%d = Adc%d ) \tPickupInfo returns Chans avail: %d   '%s' \r", ioch, ch, MCTgChansAvailable, sMCTgChannelInfo
//	if ( MCTgChansAvailable == 2 )
//		for ( MCTGChan = 0;  MCTGChan < MCTgChansAvailable;  MCTgChan += 1 )
//			sOneChannelInfo	= StringFromList( MCTGChan, sMCTgChannelInfo )
//			if ( BreakInfo( sOneChannelInfo, rTyp, rSerNum, rComPort, rAxoBus, rChan, rMode, rMCGain, rSclFactor, rsSclFactorUnits )  !=  9 )
//				InternalError( "Expected 9 entries in  MCTG info string '" + sOneChannelInfo + "' ." ) 
//			endif	
//			if ( rChan == nTGChan )
//				Gain	= rMCGain * rSclFactor
//				printf "\t\tTelegraphGainMC( ioch:%d = Adc%d, sTGChan:'%s'  nTGChan:%d )  Pickup Typ:%s  SN:%d  CP:%d  AB:%d  TGCh: %d  Mode:%d  McGn:\t%7.2lf\tSc: %.1lf %s\t -> Gain: %5.1lf\t... \r", ioch, ch, sTGChan, nTGChan, StringFromList( rTyp, kMC700_MODELS), rSerNum,  rComPort, rAxoBus, rChan, rMode, rMCGain, rSclFactor, rsSclFactorUnits, Gain
//			endif	
//		endfor
//	elseif ( MCTgChansAvailable > 2 )
//		InternalError( "Only 2 MCTG channels implemented. Extracted " + num2str( MCTgChansAvailable) + " from '" + sMCTgChannelInfo + "' ." ) 
//	else			// todo? discriminate between 0 and 1 
//		Alert( kERR_IMPORTANT, "Script specifies to use MultiClamp Telegraph channels, but only " + num2str( MCTgChansAvailable) + " channel(s) could be extracted from '" + sMCTgChannelInfo + "' ." ) 
//	endif
//	if ( Gain == 0 )
//		Alert( kERR_IMPORTANT, "Illegal MultiClamp Telegraph channel.  Gain = 1 is returned. " ) 
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


static Function	CheckAvailableTelegraphChans( sTGChan, MCTgChansAvailable )
	string  	sTGChan
	variable	MCTgChansAvailable
	string  	sBuf1
	variable	nError	= 0
	if ( MCTgChansAvailable == 0 )
		sprintf sBuf1, "Failed to connect  'TGMCChan = %s' . There is currently  no  MC700 channel available. Turn on the MC700 and  'Apply'  again. ",  sTGChan 
		Alert( kERR_SEVERE, sBuf1 )
		nError	= kERROR
	endif
	return	nError
End 


static Function	CheckSimpleSpecAgainstTGCnt( sTGChan, rScrChan, MCTgChansAvailable )
	string  	sTGChan
	variable	&rScrChan
	variable	MCTgChansAvailable
	string  	sBuf1, sBuf2
	variable	nError	= 0
	if ( strlen( sTGChan ) == 1  )
		if (  MCTgChansAvailable != 2 )
			sprintf sBuf1, "TGMCChan = %s  does not identify the MC700 uniquely. There are currently  %d  MC700 channels available. \r",  sTGChan ,  MCTgChansAvailable 
			sprintf sBuf2, "\t\t\tEither turn all unnecessary  MC700s  or  use  specifiers e.g . 'TGMCChan =  1_700A_Port_X_AxoBus_Y'   or  'TGMCChan =  2_700B_SN_xxxx'  "
			Alert( kERR_SEVERE, sBuf1 + sBuf2 )
			return	kERROR
		endif
		rScrChan			= str2num( sTGChan[ 0,0 ] ) 			// use  the first digit : limits the channels to 0..9 .  In this special (=simple spec) case there is always only 1 digit. 
		return	TRUE
	endif
	return	FALSE					// not a simple spec
End 


static Function	BreakExtendedSpec( sTGChan, rScrTyp, rnSerNum, rnComPort, rnAxoBus, rScrChan )
// 'TGMCChan =  1_700A_Port_2_AxoBus_3'   or  'TGMCChan =  2_700B_SN_1234'
	variable	&rScrTyp, &rnSerNum, &rnComPort, &rnAxoBus, &rScrChan 
	string  	sTGChan
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
						sprintf  sBuf, "\t\t\t\tTelegraphGainMC  BreakExtendedSpec(\t%s\t)   700A ,  Chan:%2d ,  Port:%2d ,  AxoBus:%2d  \r",   pd( sTGChan,22) , rScrChan, rnComPort, rnAxoBus
						Out1( sBuf, 0 )
					else
						sprintf sBuf, "TGMCChan = %s  is an illegal specification. Use  e.g .   'TGMCChan =  1_700A_Port_2_AxoBus_3''  ",  sTGChan 
						Alert( kERR_SEVERE, sBuf )
						return	kERROR	
					endif		
				else						// = 700B
					if ( cmpstr( sTGChan[ 6,9 ] , "_SN_" ) == 0 )
						rnSerNum	= str2num(  sTGChan[ 10, inf ] ) 
						sprintf  sBuf, "\t\t\t\tTelegraphGainMC  BreakExtendedSpec(\t%s\t)  700B ,  Chan:%2d ,  SN: %d  \r",  pd( sTGChan,22) , rScrChan, rnSerNum
						Out1( sBuf, 0 )
					else
						sprintf sBuf, "TGMCChan = %s  is an illegal specification. Use  e.g .   'TGMCChan =  2_700B_SN_xxxx'  ",  sTGChan 
						Alert( kERR_SEVERE, sBuf )
						return	kERROR	
					endif		
				endif
			else
				sprintf sBuf, "TGMCChan = %s  is an illegal specification. Use  e.g . 'TGMCChan =  1_700A_Port_X_AxoBus_Y'   or  'TGMCChan =  2_700B_SN_xxxx'  ",  sTGChan 
				Alert( kERR_SEVERE, sBuf )
				return	kERROR	
			endif		
		else
			sprintf sBuf, "TGMCChan = %s  is an illegal specification. Use  e.g . 'TGMCChan =  1_700A_Port_X_AxoBus_Y'   or  'TGMCChan =  2_700B_SN_xxxx'  ",  sTGChan 
			Alert( kERR_SEVERE, sBuf )
			return	kERROR	
		endif		
	else
		InternalError( "BreakExtendedSpec( '" + sTGChan + " )  is a simple spec. " ) 		// should never happen 
	endif
	return	TRUE		// OK
End


static Function		BreakInfo( sOneChannelInfo, rHWTyp, rSerNum, rComPort, rAxoBus, rChan, rMode, rMCGain, rSclFct, rsSclFctUnits )
// breaks MultiClamp telegraph 1-channel info string as given by XOP  'xMCTgPickupInfo()'   into its components.
// ASSUMPTION: Same separators ' , ; ' and same entries 'HWTyp, SerNum, Port, AxoBus, Chan, Mode, Alpha, ScaleFct, Units' as in    'xMCTgPickupInfo()/UpdateDisplay()'  
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


Function		DisplayAvailMCTgChans_()
	string		sOneChannelInfo
	string		rsSclFactorUnits
	variable	rTyp, rSerNum, rComPort, rAxoBus, rChan, rMode, rMCGain, rSclFactor					// the specifiers which the MC700 has transmitted, extracted from  'PickUpInfo'
	variable	MCTGChan

	string  	sMCTgChannelInfo	= xMCTgPickupInfo()

	variable	MCTgChansAvailable	=  ItemsInList( sMCTgChannelInfo )

	printf "\r\t\tDisplayAvailMCTgChans()  finds  %d   MCC700 channels. '%s' \r", MCTgChansAvailable, sMCTgChannelInfo
	for ( MCTGChan = 0;  MCTGChan < MCTgChansAvailable;  MCTgChan += 1 )
		sOneChannelInfo	= StringFromList( MCTGChan, sMCTgChannelInfo )

//		if (  IsConnectedTGChannel( sOneChannelInfo ) )

			if ( BreakInfo( sOneChannelInfo, rTyp, rSerNum, rComPort, rAxoBus, rChan, rMode, rMCGain, rSclFactor, rsSclFactorUnits )  !=  9 )
				DeveloperError( "Expected 9 entries in  MCTG info string '" + sOneChannelInfo + "' .  AllChans: " + sMCTgChannelInfo ) 
			endif	
			printf "\t\t\tDisplayAvailMCTgChans() \tMC:%d\t%s\ttp:%3d\tpo:%3d\tab:%3d\tch:%2d\tsn:%16d\tGn:\t%7.1lf\tScl:\t%3.1lf\t  U: %s\tMode: '%s' \r", MCTGChan, SelectString( rTyp==0, "700B", "700A"), rTyp, rComPort, rAxoBus, rChan,  rSerNum, rMCGain, rSclFactor, pd(rsSclFactorUnits,6), StringFromList( rMode, kMC700_MODES )
//		endif
	endfor
End


// 040927 VERSION   TG without MC700TG XOP: works only partly (to retrieve gain the MCC700 channel must be switched which is not acceptable)=
// Static	Function	TelegraphGainMC( ioch )		
////  Get and return the gain value  from the AxoPatch MultiClamp 
//// ASSUMPTION: Same separators ' , ; ' and same entries 'HWTyp, SerNum, Port, AxoBus, Chan, Mode, Alpha, ScaleFct, Units' as in    'xMCTgPickupInfo()/UpdateDisplay()'  
//// If user has specified Comport and Axobus   and   if the specified unit exists : use it , if not use MC demo
//// count MCs: if it is just 1 use it, if there is none use MC demo, if there are more than 1 the user must have specified Comport and Axobus
//	variable	ioch											// ioch is linear index in script
//	variable	ch				= str2num( iosOld( ioch, cIOCHAN ) )	// ch is true channel number in script
//	variable	Gain				= 0
//	string		sMCTgChannelInfo	= xMCTgPickupInfo()
//	variable	MCTgChansAvailable	= ItemsInList( sMCTgChannelInfo )
//	// printf "\t\tTelegraphGainMC( ioch:%d = Adc%d ) \tPickupInfo returns Chans avail: %d   '%s' \r", ioch, ch, MCTgChansAvailable, sMCTgChannelInfo
//	variable	MCTgChan 
//	variable	rHWTyp, rSerNum, rComPort, rAxoBus, rChan, rMode, rMCGain, rSclFactor
//	string		rsSclFactorUnits
//	if ( MCTgChansAvailable == 2 )
//		for ( MCTGChan = 0;  MCTGChan < MCTgChansAvailable;  MCTgChan += 1 )
//			string		sOneChannelInfo	= StringFromList( MCTGChan, sMCTgChannelInfo )
//			if ( BreakInfo( sOneChannelInfo, rHWTyp, rSerNum, rComPort, rAxoBus, rChan, rMode, rMCGain, rSclFactor, rsSclFactorUnits )  !=  9 )
//				InternalError( "Expected 9 entries in  MCTG info string '" + sOneChannelInfo + "' ." ) 
//			endif	
//			variable	nTGChan		= TGMCChan( ioch )
//			if ( rChan == nTGChan )
//				Gain	= rMCGain * rSclFactor
//
//				// 040927 TG without MC700TG XOP: works only partly (to retrieve gain the MCC700 channel must be switched which is not acceptable)
//				//variable	nModel		= 0
//				//string  	sSerialNumber	= ""
//				//variable	nCOMPort		= 1
//				//variable	nDevice		= 0
//				//variable	nChannel		= nTGChan
//				//MC700SelectMultiClamp( nModel, sSerialNumber, nCOMPort, nDevice, nChannel )
//				//
//				//variable	NewGain	= MC700GetGain() 
//				//variable	NewMode	= MC700GetMode() 
//				//variable	NewScale	= ( NewMode == kMC700_MODE_VC )  ?  0.5  :  1.0	// Scaling is different in VC and CC. Value can also be retrieved directly but then the Telegraph interfacemust be used.
//				//variable	NewGainScaled	= NewGain * NewScale 
//				// printf "\t\tTelegraphGainMC( ioch:%d = Adc%d, nTGChan:%d )  Pickup CP:%d  AB:%d  TGCh: %d  Mode:%d  McGn:\t%7.2lf\tSc: %.1lf %s\t -> Gain: %5.1lf\t=?=\t%7.1lf\t%7.1lf  %s\r", ioch, ch, nTGChan,  rComPort, rAxoBus, rChan, rMode, rMCGain, rSclFactor, rsSclFactorUnits, Gain, NewGainScaled, NewGain, StringFromList( NewMode, kMC700_MODES )
//
//				printf "\t\tTelegraphGainMC( ioch:%d = Adc%d, nTGChan:%d )  Pickup Typ:%s  SN:%d  CP:%d  AB:%d  TGCh: %d  Mode:%d  McGn:\t%7.2lf\tSc: %.1lf %s\t -> Gain: %5.1lf\t... \r", ioch, ch, nTGChan, StringFromList( rHWTyp, kMC700_MODELS), rSerNum,  rComPort, rAxoBus, rChan, rMode, rMCGain, rSclFactor, rsSclFactorUnits, Gain
//			endif	
//		endfor
//	elseif ( MCTgChansAvailable > 2 )
//		InternalError( "Only 2 MCTG channels implemented. Extracted " + num2str( MCTgChansAvailable) + " from '" + sMCTgChannelInfo + "' ." ) 
//	else			// todo? discriminate between 0 and 1 
//		Alert( kERR_IMPORTANT, "Script specifies to use MultiClamp Telegraph channels, but only " + num2str( MCTgChansAvailable) + " channel(s) could be extracted from '" + sMCTgChannelInfo + "' ." ) 
//	endif
//	if ( Gain == 0 )
//		Alert( kERR_IMPORTANT, "Illegal MultiClamp Telegraph channel.  Gain = 1 is returned. " ) 
//		Gain = 1 		// returning 0 might possibly cause a crash (at least during testing....)
//	endif
//	return	Gain
//End

			
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	DIALOG PANEL  FOR  GAINS

Function		GainDlg()
	string  	sFolder		= ksACOld
	string  	sPnOptions	= ":dlg:tPnGain" 
	string  	sWin			= "PanelGain" 
	InitPanelGain( sFolder, sPnOptions )
	ConstructOrDisplayPanel(  sWin, "Gain" , sFolder, sPnOptions,  95, 75 )	// same params as in  UpdatePanel()
//.....	variable	XLoc = GetIgorAppPixelX() -  Xsize - 4 - 8	// for this panel a wrong size ( too large by 8 XPixel) is returned which is corrected here
	LstPanels_Fp3Set( AddListItem( sWin, LstPanels_Fp3() ) )	// ??? todo_c could prevent adding more than once....
End

Function		InitPanelGain( sFolder, sPnOptions )
	string		sFolder, sPnOptions
	string		sPanelWvNm = 	  "root:uf:" + sFolder + sPnOptions
	wave 	wG		= 	$"root:uf:" + sFolder + ":keep:wG"  				// This  'wG'  	is valid in FPulse ( Acquisition )
	wave  /T	wIO		= 	$"root:uf:" + sFolder + ":ar:wIO"  				// This  'wIO'	is valid in FPulse ( Acquisition )
	string		lstSingleADNames	= MakeSingleADList( wG, wIO )
	variable	n = -1

	make /O /T /N=(30)	$sPanelWvNm
	wave  /T	tPn	=	$sPanelWvNm
	// The Panel displays only those AD channels which are not telegraph controled
	//  'PanelSetMultipleVars(()'  constructs automatically  variable names needed for the panel lines.
	n = 	PanelSetMultipleVars( n, tPn,  "AxoPatch Gain" , 50,  ".5,1000,0" , "GainProc" , lstSingleADNames )	
	//					TYPE	;  	NAM			; TXT;   FLEN ;FORM;     LIM		;    PRC		
	n += 1;	tPn[ n ] =	"PN_SETVAR;	root:uf:"+sFolder+":dlg:CCpAStep	;CC step; 50	;	;  -3000,3000,100;       	" //CC +-100pA : "	
	redimension  /N = (n+1)	tPn
End

// 040210 this should be but is unfortunately not a general function (which should be placed in Dialog.ipf) because of the FPulse specific  'Nm2NioC( sText ) '
Function		PanelSetMultipleVars( n, tPanel, sTitle, nWid, sLim, sProcNm, sVarIndexNm ) 
// Adds a number of similar variables  (= a wave )  to a panel using multiple SETVARs  using  folders
// Constructs automatically  variable names and function names based on  the parameter 'sTitle' .
	variable	n, nWid
	string		sTitle,  sProcNm, sVarIndexNm, sLim
	wave   /T	tPanel
	n = PnSeparator( tPanel, n, sTitle ) 
	variable	i, nStartLine = n
	variable	nItems	= ItemsInList( sVarIndexNm )
	string  	sText, sCleanNm
	
	variable	ioch
	for ( i = 0; i < nItems; i += 1 )
		variable	nIO = kIO_ADC, c
		sText	= StringFromList( i, sVarIndexNm )				// the text in the panel has an arbitrary user-defined index appended or is the index, e.g. '5;0;2..' or  'Adc5;Adc0;PoN2'

		string  	sFolder	= ksACOld
		wave  /T	wIO		= $"root:uf:" + sFolder + ":ar:wIO" 						// This  'wIO'  is valid in FPulse ( Acquisition )
		Nm2NioC( wIO, sText, nIO, c )							// Cave : only 10 channels are allowed  from 0 to 9.  Could easily be extended to bigger numbers...
		// Only Adc is processed as it should always be an Adc.  Could easily be extended to Dac etc....
		sCleanNm	= CleanupName( "_" + sTitle, 0 ) +  num2str( c )		// the appended number are the indices in script of the Adc channel  e.g. 5, 0, 7,...
		variable	/G $sCleanNm								// Igor requires a 'SetVariable' to be global but it is used only locally
		nvar		tmp		= $sCleanNm 
		tmp				= iov( wIO, nIO, c, cIOGAIN )

		//?  TODO  the action procedure only triggered (=the variable in the field is only transferred to the wave) if the field is left with CR...
		// ...NOT if the field is just left.( but a dark broad margin aroung the input field shows that it still is selected/focused and waiting for CR .. 

		tPanel[ nStartLine + i + 1 ] =	"PN_SETVAR;" + sCleanNm + ";" + sText + ";" + num2str(nWid) + ";   ;"  + sLim + ";" + sProcNm  + ";" + sTitle// adjust spaces for alignment of fields (only vert mode)
		// printf "\t\tPanelSetWave()  '%s' \r", tPanel[ nStartLine + i + 1 ]
	endfor
	return	nStartLine + nItems
End



Function	GainProc( sControlNm, Gn, varStr, varName ) : SetVariableControl
// todo 040118   when editing the 2. input field after having left the 1. without  ENTER , the Setvariable control appears  erroneously  in  some  graph window. IS THIS BECAUSE OF 'DisplayOffLine()'  BELOW ???
	string		sControlNm, varStr, varName
	variable	Gn

//	variable	ioch	= TrailingDigit( varName )	// ioch : the linear index in script passed with the variable name as postfix
//	// Step 1 : Store the gain just set by the user in 'wIO' . This is needed  in WriteCFS .
//	ioSet( wIO, ioch, cIOGAIN, num2str( Gn ) )						
//	printf "\t\tGainProc(.) sControlNm: %s, varStr:%s, varName:%s   \t: setting wIO[ ioch:%d, cIOGAIN ] =%g  =?= %g \r", sControlNm, varStr, varName , ioch, Gn, str2num( iosOld( ioch, cIOGAIN ) )
// 041015
	variable	nIO		= kIO_ADC
	variable	c		= TrailingDigit( varName )		// c : the linear Adc index in script passed with the variable name as postfix
	// Step 1 : Store the gain just set by the user in 'wIO' . This is needed  in WriteCFS .
	string  	sFolder	= ksACOld
	wave  	wG		= $"root:uf:" + sFolder + ":keep:wG"  						// This  'wG'	is valid in FPulse ( Acquisition )
	wave  /T	wIO		= $"root:uf:" + sFolder + ":ar:wIO"  						// This  'wIO'	is valid in FPulse ( Acquisition )
	wave  	wFix		= $"root:uf:" + sFolder + ":ar:wFix"  						// This  'wFix'	is valid in FPulse ( Acquisition )
	ioSet( wIO, nIO, c, cIOGAIN, num2str( Gn ) )						
	printf "\t\tGainProc()  sControlNm: %s, varStr:%s, varName:%s   \t:setting wIO[ nIO:%d, c:%dcIOGAIN ] =%g  =?= %g \r", sControlNm, varStr, varName , nIO, c, Gn, iov( wIO, nIO, c, cIOGAIN )
	

	// The new Gain has now been set and will be effective during the next acquisition, but for the user to see immediately that his change has been accepted....
	BuildGainInfo( wG, wIO, cGAININFO )			//....we change the Gain info string in the status bar
	PossiblyAdjstSliderInAllWindow_( wIO )		//....we change the slider limits in all windows which contain this AD channel   ( this is optional and could be commented out )
	DisplayOffLineAllWindows( sFolder, wG, wIO, wFix )				// This is to display a changed Y axis in all windows which contain this AD channel   ( could probably be done simpler and more directly.....)

	DisplayHelpTopicFor( sControlNm )			// help display EXPLICITLY called here as this action proc name is NOT derived from the control name (multiple controls have same proc)
End


Static  Function	/S	MakeSingleADList( wG, wIO )
// Makes a  list containing the names of all true AD channels which are not controlled by a telegraph channel, e.g. '2 0 '  -> 'Adc2;Adc0;'.   Used in the 'Gain' panel.
	wave	wG
	wave  /T	wIO
	string 	lstSingleADNames	= ""
	variable	nCntAD	= wG[ kCNTAD ]	
	variable	nIO = kIO_ADC, c, cCnt
	cCnt	= ioUse( wIO, nIO )
	for ( c = 0; c < cCnt; c += 1 )
		if ( ! HasTG( wIO, nIO, c )  &&  ! HasTGMC( wIO, nIO, c ) )	
			lstSingleADNames	= AddListItem( ios( wIO, nIO, c, cIONM ), lstSingleADNames, ";" , Inf )
		endif
	endfor
	// printf  "\t\t\tTelegraphGain( MakeSingleADList() \t'%s'  \r", lstSingleADNames
	return	lstSingleADNames
End

Function		root_uf_aco_dlg_CCpAStep( ctrlName, varNum, varStr, varName ) : SetVariableControl
	string		ctrlName, varStr, varName
	variable	varNum
	// print ctrlName
	string  	sFolder	= ksACOld
	string  	sWin		= ksPN_NAME_SDAO	
	wave  	wG		= $"root:uf:" + sFolder + ":keep:wG" 					// This  'wG'  	is valid in FPulse ( Acquisition )
	wave  /T	wIO		= $"root:uf:" + sFolder + ":ar:wIO"  					// This  'wIO'  	is valid in FPulse ( Acquisition )
	wave  /T	wVal		= $"root:uf:" + sFolder + ":ar:wVal"  					// This  'wVal'  	is valid in FPulse ( Acquisition )
	wave 	wFix		= $"root:uf:" + sFolder + ":ar:wFix" 		 			// This  'wFix'	is valid in FPulse ( Acquisition )
	wave 	wEinCB	= $"root:uf:" + sFolder + ":ar:wEinCB" 		 			// This  'wEinCB'is valid in FPulse ( Acquisition )
	wave 	wELine	= $"root:uf:" + sFolder + ":ar:wELine" 					// This  'wELine' is valid in FPulse ( Acquisition )
	wave 	wE		= $"root:uf:" + sFolder + ":ar:wE"  					// This  'wE'  	is valid in FPulse ( Acquisition )
	wave 	wBFS	= $"root:uf:" + sFolder + ":ar:wBFS" 					// This  'wBFS'  	is valid in FPulse ( Acquisition )
	string		sSegList = ChangeAllOccurences( wG, wFix, wEinCB, wE, wBFS, "VarSegm", "Amp", varnum/10 )  //? todo   scaling...
	OutElemsSomeToWave( sFolder, wG, wIO, wVal, wELine, wE, wBFS, sSegList )
	DisplayStimulus1( sFolder, sWin, kNOINIT )
End

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//   DISPLAY AND STORE FUNCTIONS CALLED BY TIMER DURING ACQUISITION
//   NEW  APPROACH 180202:    call processing functions (=CFSStore, DisplayDurAcq..) from WITHIN  Process()
//   usage: call Process()  repeatedly  from  ADDASwing()   and  once  from  CedStartAcq 

// todo PULSE stores 1 original  and  1 corrected sweep for each frame, ...
// ... so GetSweepsPerFrame() should return 2 HERE (and elsewhere, but not everywhere..) 

Function		Process_( sFolder, ptAD) 		// PROTOCOL  AWARE
//!  MAJOR CONCEPT ...recover underlying sweep / frame structure ....can be extended to other script types (here only PULSE) 
//  checks list with Frame / Sweeps end points (=index into ADC integer wave) built before the acquisition (in OutElems...()....)
//  only after a frame is completely acquired (=this point 'ptAD' is reached or passed) we can manipulate the data (=disk store or display)
// Version1 up to 031006:  the  array behind SwpEndSave() does NOT contain  'gnProt'  so  'gnProt'  is counted down in AddaSwing() 
//		and compared here against internal 'igLasProt' to decide if another Protocol must be processed. This was possible as nReps contained JUST ONE protocol..
// Version 2 : nRep no longer is 1 protocol so AddaSwing()  cannot directly control  'gnProt'  ( and should not in fact have to know anything about prots, blocks frames, sweeps )
// 	Solution:	extend   Get_Sweep/Frame/Start/End_Point()  so that it contains  'gnProt' . Clean but truely  PROTOCOL_AWARE  requires much space (times  gnProt !!!)
	string  	sFolder
	variable	ptAD			// -1 : only initialize the internal globals, all further calls supply a value > 0 meaning real action 

	wave 	wG			= $"root:uf:" + sFolder + ":keep:wG"	  		// This  'wG'  	is valid in FPulse ( Acquisition )
	wave  /T	wIO			= $"root:uf:" + sFolder + ":ar:wIO"  					// This  'wIO'	is valid in FPulse ( Acquisition )
	wave  /T	wVal			= $"root:uf:" + sFolder + ":ar:wVal"  					// This  'wVal'	is valid in FPulse ( Acquisition )
	wave 	wFix			= $"root:uf:" + sFolder + ":ar:wFix" 					// This  'wFix'  	is valid in FPulse ( Acquisition )
	wave 	wE			= $"root:uf:" + sFolder + ":ar:wE"  					// This  'wE'  	is valid in FPulse ( Acquisition )
	wave 	wBFS		= $"root:uf:" + sFolder + ":ar:wBFS" 					// This  'wBFS'  	is valid in FPulse ( Acquisition )

	nvar		gRadDebgSel	= root:uf:dlg:gRadDebgSel
	nvar		PnDebgCFSw	= root:uf:dlg:Debg:CfsWr
	nvar		gnProts		= $"root:uf:" + sFolder + ":keep:gnProts"
	//StartTimer( "Process1" )		

	// printf "\t\tProcess(0 sFolder : '%s' ) : data folder : '%s' \r", sFolder, GetDataFolder( 1 ) 
	// Initialization....
	if ( ptAD == -1 )
		variable  /G	$"root:uf:" + sFolder + ":stim:igLastProt"	= 0	
		variable  /G	$"root:uf:" + sFolder + ":stim:igLastB"		= 0
		variable  /G	$"root:uf:" + sFolder + ":stim:igLastSwp"	= 0	// internal globals storing the number of the last...
		variable  /G	$"root:uf:" + sFolder + ":stim:igLastFrm"	= 0	// ..frame, sweep and protocol which have already been processed 
		return 0												
	else 
		nvar		 	igLastProt	= $"root:uf:" + sFolder + ":stim:igLastProt"
		nvar			igLastB	= $"root:uf:" + sFolder + ":stim:igLastB"
		nvar			igLastSwp	= $"root:uf:" + sFolder + ":stim:igLastSwp"
		nvar			igLastFrm	= $"root:uf:" + sFolder + ":stim:igLastFrm"
	endif
	// printf "\t\tProcess(1 sFolder : '%s' ) : data folder : '%s' \r", sFolder, GetDataFolder( 1 ) 

	string		bf
	variable	p, b, f, s
	variable	swpEnd	= SweepEndSaveProtAware( sFolder, igLastProt, igLastB, igLastFrm, igLastSwp ) 	// 031007  PROTOCOL  AWARE
	// printf "\t\t\t\tCFSWr  PROcess receiv.swpEnd(\tb:%d,f:%d,s:%d):\t\t%7d <=?%7d (ptAD)\t%s  igLastProt:%d \r",  igLastB, igLastFrm, igLastSwp, swpEnd, ptAD, SelectString( swpEnd  <= ptAD , "START..   will return immediately..." , "START..allow processing" ), igLastProt 
	if ( gRadDebgSel > 2  &&  PnDebgCFSw )
		printf "\t\t\t\tCFSWr  PROcess receiv.swpEnd(\tp:%d,b:%d,f:%d,s:%d):\t\t%7d <=?%7d (ptAD)\t%s  igLastProt:%d \r",  igLastProt, igLastB, igLastFrm, igLastSwp, swpEnd, ptAD, SelectString( swpEnd  <= ptAD , "START..   will return immediately..." , "START..allow processing" ), igLastProt 
	endif
	//StopTimer( "Process1" )	
	for ( p =  igLastProt; p < gnProts; p += 1 )
		for ( b =  igLastB; b < eBlocks( wG ); b += 1 )
			for ( f =  igLastFrm; f < eFrames( wFix, b ); f += 1 )
				for ( s = igLastSwp; s < eSweeps( wFix, b ); s += 1 )
					swpEnd	= SweepEndSaveProtAware( sFolder, p, b, f, s ) 	// 031007  PROTOCOL  AWARE
					igLastProt	=  p		
					igLastB	=  b		
					igLastFrm	=  f		
					igLastSwp = s 		
					if ( ptAD < swpEnd )
						if ( gRadDebgSel > 2  &&  PnDebgCFSw )
							printf "\t\t\t\tCFSWr  Process checks swpEnd(\tp:%d,b:%d,f:%d,s:%d):\t\t%7d <=?%6d\t\t\t\tRETURN..sweep not yet ready \r",  p, b, f, s, swpEnd, ptAD
						endif
						return swpEnd
					endif
	
					// SWEEP PROCESSING
					if ( gRadDebgSel > 2  &&  PnDebgCFSw )
						printf  "\t\t\t\tCFSWr  Process \t\t\t\t\tp:%d,b:%d,f:%d,s:%d /%2d :\t%7d <=?%6d\t\t\t\tPROCESSING SWEEP\r", p, b, f, s,  eSweeps( wFix, b ) - 1, swpEnd, ptAD 
					endif
					//	SWP_COMPUTATION
					// do specific computations for all mainkeys allowed in script (=provided in w_MK, w_SK )
					// StartTimer( "Process1" )		
//nvar		gnTicksStart	= root:uf:aco:co:gnTicksStart
// print "\t\tticks Process()", ( ticks - gnTicksStart )  / kTICKS_PER_SEC
					StartTimer( sFolder, "OnlineAn" )
					ComputePOverNCorrection( sFolder, wG, wIO, wFix, wE, wBFS, p, b, f, s )		// 031008  !  PROTOCOL  AWARE			
					// StopTimer( "Process1" )		
					// ComputeAverage( p, b, f, s )			// 040123 removed,   031008  !  PROTOCOL  AWARE		
					// ComputeSum( p, b, f, s )				// 040123 removed,   031008  !  PROTOCOL  AWARE		
					StopTimer( sFolder, "OnlineAn" )
			
					//	SWP_DISPLAY
					StartTimer( sFolder, "Graphics" )
					DispDuringAcqCheckLag_( sFolder, wG, wIO, wFix, p, b, f, s )		// 031008  !  PROTOCOL  AWARE			
					StopTimer( sFolder, "Graphics" )
		
					//	SWP_CFSWRITE
					StartTimer( sFolder, "CFSWrite" )
			
					WriteDataSection( sFolder, wG, wIO, wVal, wFix, p, b, f, s )			
					StopTimer( sFolder, "CFSWrite" )
					
				endfor								// ..sweeps
		
				// FRAME PROCESSING
				if ( gRadDebgSel > 2  &&  PnDebgCFSw )
					printf "\t\t\t\tCFSWr  Process\t\t\t\t\tp:%d,b:%d f:%d \t\t:\t%7d <=?%6d\t\t\t\tPROCESSING FRAME\r", p, b, f,  swpEnd, ptAD 
				endif
				
				StartTimer( sFolder, "OnlineAn" )
				OnlineAnalysis_( sFolder, wG, wIO, p, b, f )					// 031008  !    NOT  YET  REALLY  PROTOCOL  AWARE				
				StopTimer( sFolder, "OnlineAn" )
		
				//	FRM_DISPLAY
				StartTimer( sFolder, "Graphics" )
				DispDuringAcqCheckLag_( sFolder, wG, wIO, wFix, p, b, f, kDISP_FRAME )	// 031008  !  PROTOCOL  AWARE	
				DispDuringAcqCheckLag_( sFolder, wG, wIO, wFix, p, b, f, kDISP_PRIM )	// 	
				DispDuringAcqCheckLag_( sFolder, wG, wIO, wFix, p, b, f, kDISP_RESULT)// 	
				StopTimer( sFolder, "Graphics" )
				igLastSwp = 0						
			 // sprintf bf, "\t\t\t\tCFSWr \tProcess()  (last setting \tf:%d,s:%d) end of sweeps loop, next frame..\t\r", f, s-1 ; Out( bf )
			endfor							// ..frames
			igLastSwp	=  0					// depending on sweeps/frames/ptAd this function is sometimes called at the end  ( when or after finishing )....
			igLastFrm	= 0 					// ..when nothing has to be stored or displayed. Because igLastFrm has been/ is set to the end value the function is left immediately.
		endfor							// ..blocks
		igLastSwp	= 0					// depending on sweeps/frames/ptAd this function is sometimes called at the end  ( when or after finishing )....
		igLastFrm	= 0 					// ..when nothing has to be stored or displayed. Because igLastFrm has been/ is set to the end value the function is left immediately.
		igLastB	= 0					// depending on sweeps/frames/ptAd this function is sometimes called at the end  ( when or after finishing )....
	endfor							// ..blocks
	igLastSwp	= 0					// depending on sweeps/frames/ptAd this function is sometimes called at the end  ( when or after finishing )....
	igLastFrm	= 0 					// ..when nothing has to be stored or displayed. Because igLastFrm has been/ is set to the end value the function is left immediately.
	igLastB	= 0					// depending on sweeps/frames/ptAd this function is sometimes called at the end  ( when or after finishing )....
	igLastProt	= p 					// ..when nothing has to be stored or displayed. Because igLastFrm has been/ is set to the end value the function is left immediately.

	if ( gRadDebgSel > 3  &&  PnDebgCFSw )
		printf  "\t\t\t\t\tCFSWr  Process end frames. set\tp:%d -> igLastProt:%d , \tb:%d -> igLastB:%d , \tf:%d -> igLastFrm:%d , igLastSwp:%d) ....???.......and return finally \r", p, igLastProt, b, igLastB, f, igLastFrm, igLastSwp 
	endif

	// printf "\t\tProcess(2 sFolder : '%s' ) : data folder : '%s' \r", sFolder, GetDataFolder( 1 ) 
End


static Function	ComputePOverNCorrection( sFolder, wG, wIO, wFix, wE, wBFS, pr, bl, fr, sw )			//  PROTOCOL  AWARE		BUT  NOT YET  TESTED   TODO
// for PULSE : computes and writes PoverN corrected data sweeps
	string  	sFolder
	wave  /T	wIO
	wave	wG, wFix, wE, wBFS
	variable	pr, bl, fr, sw
	nvar		gRadDebgSel	= root:uf:dlg:gRadDebgSel
	nvar		PnDebgCFSw	= root:uf:dlg:Debg:CfsWr
	variable	nCntAD		= wG[ kCNTAD ]	
	variable	BegPt		= SweepBegSave( sFolder, pr, bl, fr, sw )	
	variable	EndPt		= SweepEndSave( sFolder, pr, bl, fr, sw )
	variable	c, nPts		= EndPt - BegPt
	variable	PrevBegPt		= -1
	variable	LastBegPt		= -1
	string		bf

	variable	SweepsTimesCorrAmp = ( eSweeps( wFix, bl ) - 1 ) * eCorrAmp( wFix, bl )

	variable	BAvgBegPt	= 0
	variable	BAvgEndPt	= 0
	variable	/G root:uf:aco:cfsw:BaseSubtractOfs						// Stores offset correction value of sweep 0 which is subtracted in following sweeps. Global to keep the value but used only locally. 
	nvar		BaseSubtractOfs= root:uf:aco:cfsw:BaseSubtractOfs				// Stores offset correction value of sweep 0 which is subtracted in following sweeps. Global to keep the value but used only locally. 
	variable	nSmpInt			= wG[ kSI ]

	// Approach1: Use temporary one-sweep-buffer for intermediary correction steps (=sweep addition) and copy this temporary... 
	// ..buffer into the current sweep of 'PoNx'. Benefit: Intermediary correction steps can be displayed  at the cost of buffer copying time.
	// Approach2: Copy all intermediary correction steps directly into last sweep of 'PoNx'. Faster but no intermediary display (except when accessing last sweep in Display)
	// Approach3 (taken): Copy all intermediary correction steps (=sweep addition)  directly into current  AND into last sweep of 'PoNx'.
	// Reasonably fast and intermediary display possible.
	
	// add first sweep and the following correction sweeps (up to the last sweep of this frame)
	for ( c = 0; c < nCntAD; c += 1 )							// c  is  Adc index,  NOT  PoN index !
		wave	wBig = $( FldAcqioio( sFolder, wIO, kIO_ADC, c, cIONM ) )				// old :get the source Adc channel directly
		if ( DoPoverN( wIO, c ) )								// user wants PoverN  (it is users responsibility that it is a true AD and not a telegraph..)
			//string		sPoN	= "PoN" + sIOCHSEP +  io( "Adc", c, cIOCHAN ) 
			string		sPoN	= FldAcqioPoNio( sFolder, wIO, kIO_ADC, c, cIOCHAN ) 
			wave 	wPoN	= $sPoN

			if ( sw == 0 )
				wPoN[ BegPt, BegPt+nPts ]	= wBig[  p ]		// data from first sweep initialize first sweep  ( clear frame is not necessary ) ...

				// Compute offset correction value of sweep 0  which will be subtracted in following sweeps.			// 040806 
				// Do not subtract the value in sweep 0 : if there was an offset it is kept throughout the PoN correction, but the offset does not increase with every sweep as it would be without  'BaseSubtractOfs'
				BAvgBegPt=  BegPt																// in points : the begin of the first (non-blank) segment (the point where the recorded section starts)
				// print "ComputePOverNCorrection()   Blank / segment",  eTyp( wE, wBFS,  c, bl,  0 ), eTyp( wE, wBFS,  c, bl, 1 ) , mI( "Blank" ), mI( "Segment" ) 
				// Use the first real segment for offset computation (one could also use a possible leading blank  OR  use a  leading  blank and the following segment) 
				// If the first element is blank then use the second element. It is the user's responsibility to ensure that it is segment (whose value is constant by definition).
				variable	nElement	= ( eTyp( wE, wBFS,  c, bl, 0 )  == mI( "Blank" ) 	?  1  :  0	
				BAvgEndPt=  BegPt + ( eV( wE, wBFS, c, bl, 0, sw, nElement, cDUR ) / nSmpInt) 						// in points
				//BaseSubtractOfs	= mean( wPoN, BAvgBegPt ,  BAvgEndPt )  							// !!! in this special case pnt2x has been omitted as the wave has x scaling = 1 : x = points (mean and faverage yield same result)
				BaseSubtractOfs	= faverage( wPoN, pnt2x(  wPoN, BAvgBegPt ),  pnt2x(  wPoN, BAvgEndPt ) )  	// !!! in this special case pnt2x  could be omitted as the wave has x scaling = 1 : x = points (mean and faverage yield same result)


			else
				// Copy previous  sweep intermediary corrected data into current sweep and then add current correction sweep
				PrevBegPt		= SweepBegSave( sFolder, pr, bl, fr, sw - 1 )	

				// Subtract  offset correction value computed in sweep 0  in all following sweeps
				// wPoN[ BegPt, BegPt + nPts ]	= wPoN[ PrevBegPt - BegPt + p ] + wBig[ p ] / SweepsTimesCorrAmp					// 040806 
				wPoN[ BegPt, BegPt + nPts ]	= wPoN[ PrevBegPt - BegPt + p ] + ( wBig[ p ] - BaseSubtractOfs )  / SweepsTimesCorrAmp	// 040806 

			endif
			

			if ( sw < eSweeps( wFix, bl ) - 1 )							// the last sweep need not be copied as it is already at the right place
				LastBegPt	= SweepBegSave( sFolder, pr, bl, fr, eSweeps( wFix, bl ) - 1 )	
				wPoN[ LastBegPt, LastBegPt + nPts ]	=  wPoN[ BegPt  - LastBegPt + p ]	// copy current  corrected sweep into last sweep.
			endif
			// printf "\t\t\t\tCFSw  ComputePOverNCorr( \tfr:%d, sw:%d)  \tBP:\t%7d\tEP:\t%7d\tPts:%4d \t'%s' pts:%4d \t'%s' pts:%4d \tPsp:%5d \tLsp:%5d \tBAv[\t/%6d\t..%6d\t] = \tAvg %g \r",  fr, sw, BegPt, EndPt , nPts,  FldAcqioio( sFolder, wIO, kIO_ADC, c, cIONM), numPnts($FldAcqioio( sFolder, wIO, kIO_ADC,c, cIONM )), sPoN, numPnts( $sPoN), PrevBegPt,LastBegPt,BAvgBegPt,BAvgEndPt,BaseSubtractOfs
			if ( gRadDebgSel > 2  &&  PnDebgCFSw )
				printf "\t\t\t\tCFSw  ComputePOverNCorr( \tfr:%d, sw:%d)  \tBP:\t%7d\tEP:\t%7d\tPts:%4d \t'%s' pts:%4d \t'%s' pts:%4d \tPsp:%5d \tLsp:%5d \tBAv[\t/%6d\t..%6d\t] = \tAvg %g \r",  fr, sw, BegPt, EndPt , nPts,  FldAcqioio(sFolder,wIO,kIO_ADC,c,cIONM), numPnts($FldAcqioio(sFolder,wIO,kIO_ADC,c,cIONM)),sPoN,numPnts($sPoN), PrevBegPt,LastBegPt,    BAvgBegPt, BAvgEndPt, BaseSubtractOfs
			endif
			// display wPoN;  Alert( kERR_FATAL,  "kuki" )
		endif
	endfor
End


Static   	Function	DoPoverN( wIO, c )
// must for the Adc channel with index 'c'  the PoverN correction be done? 
	wave  /T	wIO
	variable	c
	variable	nPoN, nPoNCh, nAdcCh
	//  'PoN'  is  mainkey	(c is Adc index) : must search for a corresponding channel number in 'PoN' lines 
	nAdcCh	= iov( wIO, kIO_ADC , c, cIOCHAN ) 
	for ( nPoN = 0; nPoN < ioUse( wIO, kIO_PON ); nPoN += 1 )
		nPoNCh = iov( wIO, kIO_PON , nPoN, cIOSRC )  
		if ( nPoNCh == nAdcCh )
			return TRUE
		endif	
	endfor
	return	 FALSE
End


Function 		FinishCFSFile_( sFolder )
	string  	sFolder
	string  	bf
	nvar		gRadDebgSel	= root:uf:dlg:gRadDebgSel
	nvar		PnDebgCFSw	= root:uf:dlg:Debg:CfsWr
	nvar		gCFSHandle	= root:uf:aco:cfsw:gCFSHandle
	nvar		gFileIndex		= root:uf:aco:cfsw:gFileIndex
	string		sPath		= GetPathFileExt( gFileIndex )
	if ( gCFSHandle	!= kCFS_NOT_OPEN )		
		xCFSCloseFile( gCFSHandle, ERRLINE )
		gCFSHandle	= kCFS_NOT_OPEN 
		Backup( sFolder )
		// printf "\t\tCFSWr  FinishCFSFile() closes CFS file '%s'    (hnd:%d) \r", sPath, gCFSHandle	
		if ( gRadDebgSel > 0  &&  PnDebgCFSw )
			printf "\t\tCFSWr  FinishCFSFile() closes CFS file '%s'    (hnd:%d) \r", sPath, gCFSHandle	
		endif
	else
		// printf "\t\tCFSWr  FinishCFSFile():  no open CFS file  '%s'  \r", sPath
		if ( gRadDebgSel > 0  &&  PnDebgCFSw )
			printf "\t\tCFSWr  FinishCFSFile():  no open CFS file  '%s'  \r", sPath
		endif
	endif
End


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	AUTOMATIC  DATA  FILE  NAME GENERATION  SPECIFIC  TO  FPULSE
//	Automatic file name generation	:	 Functions  relying on  globals  gCell, gFileIndex...  , which are valid and used only during acquisition

static Function		AutoBuildNextFilename()	
// Increment the automatically built file name = go to next  fileindex. Changes the globals  'gFileIndex'  and   'gsDataFileW' 
	nvar		gFileIndex		= root:uf:aco:cfsw:gFileIndex
	svar		gsDataFileW		= root:uf:aco:cfsw:gsDataFileW
	do 			// 030617
		gFileIndex	+= 1										// Increment the automatically built file name = go to next  fileindex

		if ( gFileIndex ==  kMAXINDEX_2LETTERS - 1 )
			Alert( kERR_IMPORTANT,  " You are using the last file with current name and cell number ( " + GetPathFileExt( kMAXINDEX_2LETTERS-1) + " ). " )
		endif
		if ( gFileIndex ==  kMAXINDEX_2LETTERS  )
			Alert( kERR_SEVERE,  " All files with current name and cell number from AA to ZZ have been used ( " + GetPathFileExt( 0 ) + "  to   " + GetPathFileExt( kMAXINDEX_2LETTERS-1) + " ). \r\tThe last file will be overwritten." )
		endif
		gFileIndex	= min( gFileIndex , kMAXINDEX_2LETTERS - 1 ) 
		gsDataFileW	= GetFileName_() + ksCFS_EXT

		// printf "\t\tbuStart()  AutoBuildNextFilename()  checking  '%s'\t:  File  does  %s \r",  GetPathFileExt( gFileIndex ), SelectString( FileExists(  GetPathFileExt( gFileIndex ) ), "NOT exist: creating it...", "exist: skipping it..." )
	while  ( FileExists(  GetPathFileExt( gFileIndex ) )  &&  gFileIndex < kMAXINDEX_2LETTERS - 1 )	// 030617 skip existing files
End


Function		SearchAndSetLastUsedFile_()
	nvar		gFileIndex		= root:uf:aco:cfsw:gFileIndex
	svar		gsDataFileW	= root:uf:aco:cfsw:gsDataFileW
	gFileIndex		= GetLastUsedFileFromHead( -1 )				// start with  -1 (=AA-1), increment repeatedly until file exists, then return index of previous (=last used) file
	// gFileIndex  	= GetLastUsedFileFromTail( kMAXINDEX_2LETTERS )	// start with ZZ+1, decrement repeatedly until file exists, then return this index  (=last used) file
	gsDataFileW	= GetFileName_() + ksCFS_EXT 
	// printf "\tSearchAndSetLastUsedFile()	has computed gFileIndex:%3d   and has set gsDataFileW:'%s' \r", gFileIndex, gsDataFileW
End

static Function	 	GetLastUsedFileFromHead( nIndex )		
// build automatic file name converting index to two letters in the range from 0..26x26-1
// start at AA (=0) and INCREMENT index skipping all existing files, return index of  last  file name already used
// -- can overwrite an existing file it it comes after a gap, because it starts at the first  gap -> WE MUST CHECK EVERY INDEX , if it is empty  or if this file (maybe after a gap) already exists
//++ fast  when only few files are used (most likely)
	variable	nIndex
	do
		nIndex	+= 1
	while ( FileExists( GetPathFileExt( nIndex ) ) && nIndex < kMAXINDEX_2LETTERS ) 
	if ( nIndex == kMAXINDEX_2LETTERS )
		Alert( kERR_FATAL,  " All files with current name and cell number from AA to ZZ have been used ( " + GetPathFileExt( 0 ) + "  to   " + GetPathFileExt( kMAXINDEX_2LETTERS-1) + " ). " )
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
	while ( nIndex >= 0  &&  ! FileExists( GetPathFileExt( nIndex ) ) ) // minimum  return is -1  --> Run writes next file 0=AA
	printf "\tGetLastUsedFileFromTail()  searching by decrementing from ZZ and returning %d \r", nIndex 
	return  nIndex 
End

//Function	 	NextFreeFileInc( nIndex )		
//// build automatic file name converting index to two letters in the range from 0..26x26-1
//// start at AA (=0) and INCREMENT index skipping all existing files, return index of  first file name not yet used
//	variable	nIndex
//	do
//		nIndex	+= 1
//	while ( FileExists( GetPathFileExt( nIndex ) ) )	
//	return  nIndex
//End


static Function	 /S	GetPathFileExt( nIndex )
// builds and returns automatic file name (including global dir and base filename and cell) by converting the passed  'index'  into two letters in the range from 0..26x26-1
	variable	nIndex
	nvar		gCell		  = root:uf:aco:cfsw:gCell
	svar		gsFileBase  = root:uf:aco:cfsw:gsFileBase
	svar		gsDataPath = root:uf:aco:cfsw:gsDataPath
	string 	sPath	  = gsDataPath + gsFileBase + num2Str( gCell ) + IdxToTwoLetters( nIndex ) + ksCFS_EXT 
	// printf "\tGetPathFileExt( nIndex:%3d )  returns   '%s',    \tthis file does %s exist. \r", nIndex, sPath, SelectString( FileExists( sPath ) , "NOT", "" )
	return	sPath
End

//Function	 /S	GetWriteDataPath()
//	svar		gsDataPath = root:uf:aco:cfsw:gsDataPath
//	return	gsDataPath
//End

Function  /S	GetFileName_()					// everything before the dot 
// builds and returns automatic file name from implicit current index  and base filename and cell, but  excluding  directory
	svar		gsFileBase	= root:uf:aco:cfsw:gsFileBase
	nvar		gCell		= root:uf:aco:cfsw:gCell
	nvar		gFileIndex	= root:uf:aco:cfsw:gFileIndex
	return	gsFileBase + num2str( gCell ) + IdxToTwoLetters( gFileIndex ) 
End

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

static strconstant	sBAK_EXT			= ".bak"

static Function	Backup( sFolder )
	string  	sFolder
	nvar		gFileIndex		= root:uf:aco:cfsw:gFileIndex
	nvar		gbAutoBackup	= $"root:uf:"+sFolder+":dlg:gbAutoBackup"
	nvar		gRadDebgSel	= root:uf:dlg:gRadDebgSel
	nvar		PnDebgCFSw	= root:uf:dlg:Debg:CfsWr
	string 	sPathFileExt	= GetPathFileExt( gFileIndex )
	//( string 	sPathBak	= StripPathAndExtension( sPathFileExt ) + sBAK_EXT // save BAK in current dir  (=Userigor\ced), not in data dir (=\epc\data)
	string 	sPathBak	= StripExtension( sPathFileExt ) + sBAK_EXT[1,3] // only one dot! Save BAK in same dir as original, i.e. in data dir (=\epc\data)
	string 	bf
	if ( gbAutoBackup )

		CopyFile	/O	sPathFileExt as sPathBak

		if ( gRadDebgSel > 0  &&  PnDebgCFSw )
			printf  "\t\tCFSWr  Backup()    '%s'  > '%s' \r",  sPathFileExt, sPathBak
		endif
	else
		if ( gRadDebgSel > 0  &&  PnDebgCFSw )
			printf  "\t\tCFSWr  Backup() is turned off. No Backup is made of  '%s' .\r",  sPathFileExt
		endif
	endif
End



//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	ACTION    PROCS  FOR   PULSE  DIALOG

Function		gsFileBase( ctrlName, varNum, varStr, varName ) : SetVariableControl
	string		ctrlName, varStr, varName
	variable	varNum
	// printf "\t\tgsFileBase(%s, %g, %s , %s)  \r", ctrlName, varNum, varStr, varName 
	SearchAndSetLastUsedFile_()		// if the filebase changes we must again discriminate between used and unused files (update also "gsDataFileW") 
End

Function		root_uf_aco_cfsw_gCell( ctrlName, varNum, varStr, varName ) : SetVariableControl
//Function		gCell( ctrlName, varNum, varStr, varName ) : SetVariableControl
	string		ctrlName, varStr, varName
	variable	varNum
	// printf "\t\t...root_uf_aco_cfsw_gCell(%s, %g, %s , %s)  \r", ctrlName, varNum, varStr, varName 
	SearchAndSetLastUsedFile_()		// if the   cell   changes we must again discriminate between used and unused files (update also "gsDataFileW")
End


Function		root_uf_aco_cfsw_gbWriteMode( ctrlName, bValue ) : CheckboxControl
	string		ctrlName
	variable	bValue
	nvar		gbWriteMode	= root:uf:aco:cfsw:gbWriteMode
	// printf "\t\troot_uf_aco_cfsw_gbWriteMode() \t\thas set global  gbWriteMode to %d \t \r",  gbWriteMode	
End


Function		buDataPath( ctrlName ) : ButtonControl
// We must use a temporary global to be able to restore the old directory if the user entered an invalid path or cancelled...
	string		ctrlName
	svar		gsDataPath	= root:uf:aco:cfsw:gsDataPath
	svar		gsTmpDataPath	= root:uf:aco:cfsw:gsTmpDataPath
	gsDataPath		= DirectoryDialog( gsDataPath ) 
	gsTmpDataPath		= gsDataPath				// The text input field should always reflect the currently active directory (the dialog box may have changed it after the input field has been left)
	SearchAndSetLastUsedFile_()					//  030617 if the  directory  changes we must again discriminate between used and unused files (update also 'gsDataFileW' )
	// printf "\t\tbuDataPath() \t\thas set global gsDataPath: '%s' \t \r",   gsDataPath	
End

Function		gsTmpDataPath( ctrlName, varNum, varStr, varName ) : SetVariableControl
// Using   PN_SETSTR  to select a directory
// Called  AFTER  the user has entered  a string into the text input field of the temporary global  'gsTmpDataPath' . 
// This string may or may not be a valid directory. The string is passed to the 'DirectoryCheckAndPossiblyDialog()'.  
// 'DirectoryCheckAndPossiblyDialog()' opens a generic dialog box  for selecting (and returning) a valid directory if the string was initially invalid.... 
// ...but if the user cancelled an empty (invalid) directory is returned.
// 'DirectoryCheckAndPossiblyDialog()' does nothing with the string and returns it unchanged  if it was initially already a valid directory.
// The the real global 'gsDataPath' is updated only if the path returned by  ' DirectoryCheckAndPossiblyDialog()'  is valid.
// We must use a temporary global to be able to restore the old directory if the user entered an invalid path or cancelled...
	string		ctrlName, varStr, varName
	variable	varNum
	svar		gsDataPath	= root:uf:aco:cfsw:gsDataPath 
	svar		gsTmpDataPath	= root:uf:aco:cfsw:gsTmpDataPath
	// printf "\t\tgsTmpDataPath1( cNm: '%s'  vNm: '%s'  num:%2d  vStr:%s )  \r", ctrlName, varName,  varNum, varStr
	string		sNewDir	= DirectoryCheckAndPossiblyDialog( varStr ) 
	if ( FPDirectoryExists( sNewDir ) )					// Check if the directory returned by the dialog box is valid....
		gsDataPath	= sNewDir 				//..only if it is valid (NOT cancelled) we update the global directory
	endif
	gsTmpDataPath		= gsDataPath				// The text input field should always reflect the currently active directory (the dialog box may have changed it after the input field has been left)
	SearchAndSetLastUsedFile_()					// 030617 if the  directory  changes we must again discriminate between used and unused files (update also 'gsDataFileW' )
	// printf "\t\tgsTmpDataPath2() \thas set global gsDataPath: '%s' \t \r",   gsDataPath	
End

Function		buDelete( ctrlName ) : ButtonControl
//? todo  : only allowed when  WriteMode is on,  or is off,  or MessageBox "About to delete...."....
	string		ctrlName
	nvar		gCell			= root:uf:aco:cfsw:gCell
	nvar		gFileIndex		= root:uf:aco:cfsw:gFileIndex
	svar		gsDataFileW	= root:uf:aco:cfsw:gsDataFileW
	svar		gsFileBase		= root:uf:aco:cfsw:gsFileBase
// 030617	 Actually do delete the file. Necessary because now existing files are NOT overwritten, previously  they were  if  gFileIndex  pointed to them
	svar		gsDataPath	= root:uf:aco:cfsw:gsDataPath
	WMDeleteFile( gsDataPath+gsDataFileW )			// erase the current data file
// 051103	newer code....... DeleteFile  gsDataPath+gsDataFileW		// erase the current data file
	
	gFileIndex	= max( -1, gFileIndex - 1 )				// go back one fileindex (can be -1=__=no file yet)
	gsDataFileW	= GetFileName_() + ksCFS_EXT			// autoupdates the SetVariable/PN_DISPSTR control	
End


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	DIALOG PANEL  FOR  COMMENTS

Function 		CommentDlg()
	string  	sFolder		= ksACOld
	string  	sPnOptions	= ":dlg:tPnComm" 
	string  	sWin			= "PanelComment" 
	InitPanelComment( sFolder, sPnOptions )
	ConstructOrDisplayPanel(  sWin, "Comments" , sFolder, sPnOptions, 100, 0 )
	LstPanels_Fp3Set( AddListItem( sWin, LstPanels_Fp3() ) )	// ??? todo_c could prevent adding more than once....
End

static Function		InitPanelComment(sFolder, sPnOptions )
	string  	sFolder, sPnOptions
	string		sPanelWvNm = "root:uf:" + sFolder + sPnOptions
	variable	n = -1, nItems = 10
	make /O /T /N=(nItems)	$sPanelWvNm
	wave  /T	tPn		=	$sPanelWvNm
	//				TYPE		FLEN FRM LIM PRC NAM					; TXT	
	n += 1;	tPn[ n ] =	"PN_SETSTR; root:uf:aco:cfsw:gsGenComm	;General;	500	"
	n += 1;	tPn[ n ] =	"PN_SETSTR; root:uf:aco:cfsw:gsSpecComm	;Specific;	500	"

	n += 1;	tPn[ n ] =	"PN_CHKBOX; 	root:uf:aco:cfsw:gbAutoDelSpCom;Automatically delete specific comment (--)"
	redimension  /N = (n+1)	tPn
End

Function		root_uf_aco_cfsw_gbAutoDelSpCom( ctrlName, bValue ) 
	string		ctrlName
	variable	bValue	
	Alert( kERR_LESS_IMPORTANT,  "Not yet implemented   \t\t(bAutoDelSpCom   " + ctrlName + " : " +  num2str( bValue ) + " ) " )
End



