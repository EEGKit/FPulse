//
//  FEvalCfsRead.IPF 
// 
// CFS file read 
//
// Comments:
//
// History:
 
#pragma rtGlobals=1							// Use modern global access method.

constant			kWV_ORG_ =  0,   kWV_AVG_ = 1,   kWV_KINDCNT_ = 2	

strconstant		ksSCRIPTEXTRACTED_NB_WNDNAME_	= "ExtractedScript"


static constant		cSAMEFILE	= 0,	cSELFILE		= 1,	cPREVFILE	= 2,	cNEXTFILE	= 3, cCURACQFILE = 4
static constant		cPREVDATA	= 0,	cSAMEDATA	= 1,	cNEXTDATA	= 2,	cFIRSTDATA	= 3,	cLASTDATA	= 4,	cMOVETO	= 5

constant			kPROT = 0,   kBLK = 1,   kFRM = 2,   kSWP = 3,   kPON = 4,   kPBFS_MAX = 5


// we must use very special separators so as not to interfere with Mac path separators and with characters users write in comments (no = , : ;  ! ?)
static strconstant	ksCFSSEP			=	"|"	// CAVE:	 This must be the same separator as in "C:UserIgor:Ced:CFSFunc.c"

// indexing of root:uf:evo:cfsr:wBlkDSBeg
static constant		PDS_BEG = 0, PDS_PTS = 1, PDS_TIMEFR1 = 2, PDS_MAX = 3
 
Function		CreateGlobalsInFolder_CfsRd_()		// .... READING CFS 
// creates all folder-specific variables. To be used once from CreateGlobals() as the current data folder is changed and not restored
	NewDataFolder  /O  /S root:uf:evo:cfsr				
	string		/G	gsDataFileR		= ""		// storing the following variables once in globals avoids repeated calls to GetCFSVar()...		
	string		/G	gsStimFile			= ""		// ...and allows to read the CFS file once while displaying multiple times..(not yet realized..)
	string		/G	gsPrgAndVersion	= ""		// e.g. PATCH600, IgorPlsT205, FPULSE208
	string		/G	gsDate			= ""		// 
	string		/G	gsTime			= ""		// 
	string		/G	gsComment		= ""		// 
	variable	/G	gbIsIgor  			= 1		// who wrote the CFS file ?
	variable	/G	gDSVars			= 0
	variable	/G	gFileVars			= 0
	variable	/G	gDataSections		= 1
	variable	/G	gChannels			= 0		// zero is used as an indicator that there is no file loaded yet    

	variable	/G	gDataSctPerPro		= 1		//
	variable	/G	gFrmPerBlk		= 1		// mainly for StatusBar: number frames for the (current) protocol in the CFS file
	variable	/G	gSwpPerFrm		= 1		// mainly for StatusBar: number sweeps for the (current) protocol in the CFS file
	variable	/G	gbHasPoN		= TRUE	// does CFS file contain PoverN (=Netto) sweeps?

	variable	/G	gFrameDuration				// ...the number of points per frame as PATCH truncates frames...
	variable	/G	gProtLast			= 1		// 031020		last data section's protocol	number
	variable	/G	gBlkLast			= 1		// 			last data section's  block	number
	variable	/G	gFrmLast			= 1		// 			last data section's  frame	number
	variable	/G	gSwpLast			= 1		// 			last data section's  sweep	number
	variable	/G	gOfs				= 0		
	
	variable	/G	gbDispAllPnts	= 1					// displaying every point without data decimation can be slow with MB waves 

// 050607
	variable	/G	gPrevRowFi		= 0					// first data section oc current data unit	
	variable	/G	gPrevRowLa		= 0					// last data section oc current data unit
	variable	/G	gPrevRowCu		= 0					// the data section previously displayed (and possibly processed) . Used as a starting point to offfer the next data section.
	variable	/G	gPrevColumn

	string		/G	gsRdDataFilter		= "*"	//"No_Nm*"		// stores the users preferred file group selection e.g. 'NoNm123*'  or  'ExpMarch15*.*'
	string		/G	gsLastPathAndFile 	= ""					// the last CFS file which has been read (used as static)

	make /O /T /N=(kMAXCHANS) wFileChan					// FileChan data of the CFS file stored as strings

End

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//   CFS  READ  FUNCTIONS

//Function		fPrevFile( ctrlName ) : ButtonControl
Function		fPrevFile( s )
	struct	WMButtonAction	&s
	if (  s.eventCode == kCCE_mouseup ) 
		ReadCfsFile( ksfEVO, cPREVFILE, cFIRSTDATA )
	endif
End

//Function		fNextFile( ctrlName ) : ButtonControl
Function		fNextFile( s )
	struct	WMButtonAction	&s
	if (  s.eventCode == kCCE_mouseup ) 
		ReadCfsFile( ksfEVO, cNEXTFILE, cFIRSTDATA )
	endif
End


//Function		fCurAcqFile( ctrlName ) : ButtonControl
Function		fCurAcqFile( s ) 
	struct	WMButtonAction	&s
		if (  s.eventCode == kCCE_mouseup ) 
		ReadCfsFile( ksfEVO, cCURACQFILE, cFIRSTDATA )
	endif
End

//Function		fSelFile( ctrlName ) : ButtonControl
Function		fSelFile( s ) 
	struct	WMButtonAction	&s
	if (  s.eventCode == kCCE_mouseup ) 
		svar	gsLastPathAndFile = root:uf:evo:cfsr:gsLastPathAndFile	// the last CFS file which has been read must be cleared ...
		gsLastPathAndFile = ""							// ...because the user intends to open the 'MissingParametersBox' when rereading the same file again
		ReadCfsFile( ksfEVO, cSELFILE, cFIRSTDATA )
	endif
End

//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function	ReadCfsFile( sFolder, nFile, nMovetoData )
	string  	sFolder
	variable	nFile, nMovetoData
	// printf "\t\tReadCfsFile( nFile:%d, nMovetoData:%d  ) \r", nFile, nMovetoData
	svar		gsRdDataFilter	= root:uf:evo:cfsr:gsRdDataFilter
	svar		gsReadDPath	= root:uf:evo:de:gsReadDPath0000
	// build the file filter selection string so that only files matching  'gsRdDataFilter'  are displayed  ( '.dat'  could be replaced by ksCFS_EXT )
	string		sMyFilter	= "Data files (" + gsRdDataFilter + ".dat);" + gsRdDataFilter + ".dat;"  +  "Data files (*.dat);*.dat;Result files (*.fit);*.fit;Average files (*.avg);*.avg;All files (*.*);*.*;;"
	if ( nFile == cSELFILE )
		// Invokes FileOpen Dialog if first parameter is not a valid file (e.g. only a directory)
		  printf "\t\tReadCfsFile(  SELECTFILE 1)    gsReadDPath: '%s' ,  gsRdDataFilter: '%s'  ->  sMyFilter: '%s'  \r", gsReadDPath, gsRdDataFilter, sMyFilter
		// 051018
		if ( strlen( gsReadDPath ) == 0 )	// only once at program start
			gsReadDPath	= ksDEF_DATAPATH
			  printf "\t\tReadCfsFile(  SELECTFILE 2)    gsReadDPath: '%s' ,  gsRdDataFilter: '%s'  ->  sMyFilter: '%s'  \r", gsReadDPath, gsRdDataFilter, sMyFilter
		endif

		gsReadDPath	= FileDialog( gsReadDPath, sMyFilter )

		 // printf "\t\tReadCfsFile(  SELECTFILE 2)    gsReadDPath:'%s' \r", gsReadDPath
	elseif ( nFile == cPREVFILE )
		gsReadDPath	= GetNextFileNm( sFolder, gsReadDPath, kSEARCH_EXISTING, kDOWN, kTWOLETTER )
	elseif ( nFile == cNEXTFILE )
		gsReadDPath	= GetNextFileNm( sFolder, gsReadDPath, kSEARCH_EXISTING,  kUP, kTWOLETTER )
	elseif ( nFile == cCURACQFILE )
	
		gsReadDPath	= SearchCurAcqFile( gsReadDPath, ksCFS_EXT )			// Search for the youngest file. Does not use globals like 'SearchAndSetLastUsedFile()' .

	else		//   == cSAMEFILE
		;	//   == cSAMEFILE
	endif	

	if ( strlen( gsReadDPath ) )												// file was valid from the start or user selected a valid file  (did NOT Cancel)
		ReadDispCfs( sFolder, gsReadDPath, nMovetoData )
	else
		Alert( kERR_MESSAGE,  "No CFS file selected....." )						// user clicked Cancel  or  no further file with matching base name and cell number found.
	endif		

End


static Function	/S	SearchCurAcqFile( sPath, sExt )	
// Finds and returns complete path of youngest file in directory/path  'sPath'  which matches  'sExt'
	string  	sPath, sExt
	if ( strlen( sPath ) == 0 )
		sPath	= ksDEF_DATAPATH										//  'C:Epc:data:'
	endif
	sPath		= StripFileAndExtension( sPath	)							// Possibly remove filename and file extension
	string  	lstFiles	= ListOfMatchingFiles( RemoveEnding( sPath, ":" ) ,  "*" + sExt ,  FALSE )
	variable	n, nCnt	= ItemsInList( lstFiles ) 
	variable	OldSeconds	= 0
	for ( n = 0; n < nCnt; n += 1 )
		string  	sFileNm		= StringFromList( n, lstFiles )
		GetFileFolderInfo  /Q	sPath + sFileNm
		if ( V_modificationDate > OldSeconds )
			OldSeconds	= V_modificationDate
			string  	sReturnPath	= sPath + sFileNm
			// printf "\t\t\t\tSearchCurAcqFile(  '%s' , '%s' ) finds younger \t%s \tDate: %s \r", sPath, sExt, pd( sPath + sFileNm, 30 ) , Secs2Date( V_modificationDate, 2 )
		endif			
	endfor
	// printf "\t\tSearchCurAcqFile( '%s' , '%s' ) returns '%s' . FileCnt:%3d  [ %s ..... %s ] \r", sPath, sExt, sReturnPath, nCnt, lstFiles[ 0, 60 ], lstFiles[ strlen( lstFiles) - 60 , Inf ]
	return	sReturnPath
End


static Function		ReadDispCfs( sFolder, sPathAndFile, nMovetoData )
//  'sPathAndFile'  is read only if it differs from the last file read (stored globally internally) . If it is the same file it is only displayed.
	string		sFolder, sPathAndFile 
	variable	nMovetoData
	svar		gsLastPathAndFile = root:uf:evo:cfsr:gsLastPathAndFile	// the last CFS file which has been read
	nvar		gDataSections	= root:uf:evo:cfsr:gDataSections
	nvar		gDataSctPerPro	= root:uf:evo:cfsr:gDataSctPerPro
	nvar		gChannels		= root:uf:evo:cfsr:gChannels
	nvar		gFrmPerBlk 	= root:uf:evo:cfsr:gFrmPerBlk
	nvar		gSwpPerFrm	= root:uf:evo:cfsr:gSwpPerFrm
	nvar		gbHasPoN	= root:uf:evo:cfsr:gbHasPoN
	nvar		gFrameDuration = root:uf:evo:cfsr:gFrameDuration
	svar		gsDate		= root:uf:evo:cfsr:gsDate		
	svar		gsTime		= root:uf:evo:cfsr:gsTime		
	svar		gsPrgAndVersion= root:uf:evo:cfsr:gsPrgAndVersion	
	string		bf

	// Save the currently acquired average (if there is one) before processing a new file
	if ( AvgCnt_( 0 ) )
		DSSaveAvgAllChans_()								// auto-build the average file name and save the data
		DSEraseAvgAllChans_()								//
	endif

	variable	CFSHndIn, ch
	// printf "\tReadDispCfs( %s )  \tReading CFS..  [ Last file was:'%s' ] \r", sPathAndFile, gsLastPathAndFile
	
	CFSHndIn = CFSOpenReadFile( sPathAndFile )	

	// The following Try-Catch-EndTry is necessary to trap a possible User Abort during the time-consuming  ReadCfs  operation.  
	// Without  this code the aborted file would still be open and could not be reopened. (Trying to close the file later during Reopen does not work! )
	// 041012 the drawback with this approach is that an infinite loop in CFSDisplayAllChan(=old)  [e.g. programming error but within the same file]  can  NOT be aborted. This is in effect a crash....
	// 		Todo : code should discriminate between these 2 failure modes...
	try

		if ( CFSHndIn > 0 )									// valid handles are positive, negative or zero means error
			if ( cmpstr( sPathAndFile, gsLastPathAndFile ) )			// Do the time consuming reading only once, do not reread the file if we are still moving within the same file

				CFSInitializeReadFile( CFSHndIn, sPathAndFile )		// reads and sets  gChannels, gFileVars, gDSVars, gDataSections

				PanelEvaluation_()											// rebuild the panel as the channel count or the channel numbers may have changed			

				CFSHeaderOverview( sFolder, CFSHndIn )
				// printf "\tReadDispCfs()   [previous file was:'%s]    \tNow reading CFS file '%s'   \r", gsLastPathAndFile, sPathAndFile
				// printf    "\tREADING  CFS  FILE  %s\t%s   %s    '%s' \tChs:%d \tDSc:%3d\tDSpP:%3d\tPr:%3d\tFpB:%2d\tSpF:%2d\tPoN:%d\tFrDu:%6.1lf\t- \r", pd(sPathAndFile,26),  gsDate, gsTime, gsPrgAndVersion, gChannels, gDataSections,  gDataSctPerPro, gDataSections/gDataSctPerPro, gFrmPerBlk, gSwpPerFrm, gbHasPoN, gFrameDuration
				sprintf bf, "\tREADING  CFS  FILE  %s\t%s   %s    '%s' \tChs:%d \tDSc:%3d\tDSpP:%3d\tPr:%3d\tFpB:%2d\tSpF:%2d\tPoN:%d\tFrDu:%6.1lf\t- \r", pd(sPathAndFile,26),  gsDate, gsTime, gsPrgAndVersion, gChannels, gDataSections,  gDataSctPerPro, gDataSections/gDataSctPerPro, gFrmPerBlk, gSwpPerFrm, gbHasPoN, gFrameDuration
				Out( bf )
	
				for ( ch = 0; ch < gChannels; ch += 1)
					CFSReadSections( CFSHndIn, ch, sPathAndFile, kWV_ORG_ )
				endfor		

				DSDlg( 0, kWV_ORG_ )							// Build or resize the Data sections selection listbox

				// Now that the listbox panel is constructed we open the graph windows (still empty) and place them to the right of the listbox
				CFSDisplayAllChanInit( ksfEVO, gChannels )
				
				svar		gsAvgNm		= root:uf:evo:de:gsAvgNm0000	
				gsAvgNm	= ConstructNextResultFileNmA_( CfsRdDataPath(), ksAVGEXT_ )		// the next free avg file where avg data will be written is displayed in SetVariable input field
				svar		gsTblNm		= root:uf:evo:de:gsTblNm0000					// todo ??? includes  extension  .fit  but  .tbl  is also  meant (???  remove extension ???...no...)
				gsTblNm	= ConstructNextResultFileName_( CfsRdDataPath(), "", ksTBLEXT_ )	// the next free  tbl   file where  tbl  data will be written is displayed in SetVariable input field but without specifier 'Org' or ' Avg'

			endif

			xCFSCloseFile( CFSHndIn, ERRLINE )
			gsLastPathAndFile = sPathAndFile
		endif

	catch
		printf "User abort while loading file '%s' .   (Abort code:%d  CfsHnd:%d ) \r", sPathAndFile, V_Abortcode, CFSHndIn
		xCFSCloseFile( CFSHndIn, ERRLINE )
	endtry

	if ( gChannels )															// Only after a successful reading of data we can ...???....allow the user to turn the evaluation details panel on...
		EnableButton( 	   "de", "root_uf_"+sFolder+"_de_buEvStimDlg0000",  kENABLE )	// ..as we immediately start an evaluation for which there must be data
		EnableCheckbox( "de", "root_uf_"+sFolder+"_de_gbShwScr0000", kENABLE )		// wait till after the first data have been read
	endif
End


static Function		CFSOpenReadFile( sPathAndFile )
// returns positive CFS file handle if file opening was successful, zero or negative code if not 
	string		sPathAndFile 
	nvar		gRadDebgSel	= root:uf:dlg:gRadDebgSel
	nvar	   /Z	PnDebgCFSR 	= root:uf:dlg:Debg:CfsRd								// may not exist, exists only after panel PnTest() has been built 
	variable	ShowMode 	= gRadDebgSel > 1  &&  PnDebgCFSR  ? MSGLINE : ERRLINE	
	variable	CFSHndIn
	CFSHndIn 	= xCFSOpenFile( sPathAndFile, FALSE, TRUE, ShowMode ) 			// not enable write, speed up memory table 
	if ( CFSHndIn <= 0 )
		Alert( kERR_FATAL,  "Cannot open '" + sPathAndFile + "' on 1. attempt  [hnd:" + num2str( CFSHndIn ) + "] . " )
	endif
	return	CFSHndIn
End


static Function		CFSInitializeReadFile( CFSHndIn, sPathAndFile )
	variable	CFSHndIn
	string		sPathAndFile 
	nvar		gFileVars 			= root:uf:evo:cfsr:gFileVars
	nvar	 	gDSVars 	  		= root:uf:evo:cfsr:gDSVars
	nvar		gChannels			= root:uf:evo:cfsr:gChannels
	nvar	 	gDataSections		= root:uf:evo:cfsr:gDataSections
	svar		gsDate			= root:uf:evo:cfsr:gsDate		
	svar		gsTime			= root:uf:evo:cfsr:gsTime		
	svar		gsComment		= root:uf:evo:cfsr:gsComment		
	variable	nCfsHeaderInfo		= CfsHeaderInfo()	
	string		sChanName, sYUnits, sXUnits				
	variable	ch, DataType, DataKind, Spacing, Other			

	GetGenInfo( CFSHndIn )							// reads time, date, comment
	// print "CFSOpenReadFile1 gDataSections:" , gDataSections
	GetFileInfo( CFSHndIn )							// reads and set preliminary gChannels, gFileVars, gDSVars, gDataSections
	// print "CFSOpenReadFile2 gDataSections:" , gDataSections
	GetMissingDataParams( CFSHndIn )					// e.g. correct erroneous channel count in PATCH data, insert missing 'SwpPerFrame' in PULSE100 data

	if ( nCfsHeaderInfo )
		printf  "\r\tGENERAL INFORMATION    for   '%s' \t\t(hnd=%d) \r", sPathAndFile , CFSHndIn
		printf "\t\tCFSR1 \t GenInfo() \tDate: \t%s\t Time: \t   %s \t\tComment: '%s' \r",  gsDate, gsTime, gsComment
		printf "\t\tCFSR1 \t FileInfo() \tChans:\t%d \t\t FileVars: %3d \t\t\tDSVars: %d \t\tDataSections: %d \r", gChannels, gFileVars, gDSVars, gDataSections 
	endif
	for ( ch = 0; ch  < gChannels; ch += 1 )					// if ( ChannelsToUse == 2  &&  ChannelsAvail > 1)
		SetFileChan( CFSHndIn, ch )					
		FileChan( ch, sChanName, sYUnits, sXUnits, DataType, DataKind, Spacing, Other )	// passed parameters are changed!
		if ( nCfsHeaderInfo )
			printf "\t\tCFSR1 \t FileChan() \tChan:\t%d / %d  \t ChName: %s \tYUnits:  %s \tXUnits: %s  \t\tDaT:%d  DaK:%d  Spcg:%d  Other:%d  \r", ch, gChannels, pd(sChanName, 10) , pd(sYUnits,5), pd(sXUnits,5) , DataType, DataKind, Spacing, Other 
		endif				
	endfor
End


static Function		CFSHeaderOverview(  sFolder, CFSHndIn )
	string  	sFolder
	variable	CFSHndIn
	nvar		gRadDebgSel		= root:uf:dlg:gRadDebgSel
	nvar	   /Z	PnDebgCFSR 		= root:uf:dlg:Debg:CfsRd			// may not exist, exists only after panel PnTest() has been built 
	nvar		gDataSections		= root:uf:evo:cfsr:gDataSections		// 031202
	nvar		gFileVars 			= root:uf:evo:cfsr:gFileVars
	nvar		gDSVars 			= root:uf:evo:cfsr:gDSVars
	nvar		gbIsIgor			= root:uf:evo:cfsr:gbIsIgor
	nvar		gChannels 		= root:uf:evo:cfsr:gChannels
	nvar		gFrameDuration		= root:uf:evo:cfsr:gFrameDuration
	variable	nCfsHeaderInfo 		= CfsHeaderInfo()	
 	variable	ch, VarNo, VarKind, DataSection
	variable	rnVarSize, rnVarType
	string		rsUnits, rsDescription, sVarVal
	variable	rnStartOffset, rnPoints,  rYScale, rvVoltageOffset, rvXScale, rvXOffset
	//variable	ShowMode = gRadDebgSel > 1  &&  PnDebgCFSR  ? MSGLINE : ERRLINE	// 031202	
	variable	ShowMode =  PnDebgCFSR  ? max( ERRLINE, gRadDebgSel )  :  ERRLINE	

	string  	sRawScript	= ""				// holds the script to be read from the CFS file  050205

	// print descriptors and values  for  file section  and extract script lines
	VarKind = FILEVAR		
	if ( nCfsHeaderInfo )
		printf  "\tFILE INFORMATION \r" 
	endif
	for ( VarNo = 0; VarNo < gFileVars; VarNo += 1)
		GetVarDesc( CFSHndIn, VarNo, FILEVAR, rnVarSize, rnVarType, rsUnits, rsDescription )// passed parameters are changed!
		sVarVal = xCFSGetVarVal( CFSHndIn, VarNo, FILEVAR, -1 , ShowMode )   			// 031208 was 1 = DataSection, ShowMode )		

		if ( cmpstr( rsUnits, "none" ) != 0 )										// skip empty descriptors...

			if ( nCfsHeaderInfo )
				if ( gbIsIgor  &&  cmpstr( rsDescription[ 0 ,10 ], "ScriptBlock" ) == 0 )
					if ( strlen( sVarVal ) ==   MAX_CFS_STRLEN - 1 )	
						printf  "%s", sVarVal									// all lines are simply catenated without informational text ...
					else													// ..except the last after which the  informational text is appended once
						printf  "%s\r\r  \t\tCFSR2 \t[v:%2d/%2d\tvk:%d  vs:%3d\tvt:%2d] \t%s\t%s\t \r", RemoveTrailingWhiteSpace( sVarVal ), VarNo, gFileVars, VarKind, rnVarSize, rnVarType, pd(rsDescription,15), pd( rsUnits,12)
					endif
				else
					printf  "\t\tCFSR2 \t[v:%2d/%2d\tvk:%d  vs:%3d\tvt:%2d] \t%s\t%s\t%s\r", VarNo, gFileVars, VarKind, rnVarSize, rnVarType, pd(rsDescription,15), pd( rsUnits,12), sVarVal
				endif
			endif
			// printf  "\t\tCFSR2 \t[v:%2d/%2d\tvk:%d  vs:%3d\tvt:%2d] \t%s\t%s\t%s\r", VarNo, gFileVars, VarKind, rnVarSize, rnVarType, pd(rsDescription,15), pd( rsUnits,12), sVarVal

			// Fill  'sRawScript'  with those lines from the CFS file which contain the script data
			if ( gbIsIgor )													// 041012  if there is a script stored then extract it
				if ( cmpstr( rsDescription[ 0 ,9 ], "Scriptline" ) == 0 )
					sRawScript	+= sVarVal  + "\r"							// 050205	
				endif
				if ( cmpstr( rsDescription[ 0 ,10 ], "ScriptBlock" ) == 0 )					// 050206
					sRawScript	+= sVarVal 		
				endif
			endif

		endif
	endfor

	//  Extract sample rate  and  gFrameDuration
	DataSection	= 1							//ASSUMPTION : all datasections  have the same   SmpInt   and   gFrameDuration
	SetCfsSmpInt( CFSHndIn, DataSection )			// set global  CfsSmpInt  		    so that later neither a Cfs handle nor a time-consuming search is required when accessing this variable
	gFrameDuration = CfsVal( CFSHndIn, DSVAR, DataSection, "Frame duration" )

		
	// print descriptors and values for data section only  if the user is interested in viewing the data section information ,  otherwise skip this time consuming step .
	if ( nCfsHeaderInfo )
		VarKind = DSVAR			
		if ( nCfsHeaderInfo  ||  ( gRadDebgSel >= 3  &&  PnDebgCFSR ) )
			printf  "\tDATA SECTION INFORMATION\r" 
			printf "\t\tCFSR3c\t DataSect()\tSmpInt: \t%d\t Frame duration (section 1) : %.1lf \r",  CfsSmpInt(), gFrameDuration
		endif
		if ( nCfsHeaderInfo == 1   ||  nCfsHeaderInfo == 2 )
			printf  "\t\tCFSR3\t DaSect\t\tSmpRt\tTimeFr1\tFrmDur\tSmp1St\tSmp1Du\tPreScl\tCount\tBlock\tFrame\tSweep\tPoN   \tMaxBlk\tMaxFrm\tMaxSwp\tHasPoN\t \r"
		endif
		string		sAllVars, sProtoNm
		for ( DataSection = 1; DataSection < 1 + gDataSections; DataSection += 1 )	// 031202
			sAllVars	= ""
			for ( VarNo = 0; VarNo < gDSVars; VarNo += 1)
				GetVarDesc( CFSHndIn, VarNo, DSVAR, rnVarSize, rnVarType, rsUnits, rsDescription )
				sVarVal = xCFSGetVarVal( CFSHndIn, VarNo, DSVAR, DataSection, ShowMode )	
		
				if ( VarNo == 7 )  				// 030207 should be entry 'Proto'  TODO  search this item instead of relying on index 7
					sProtoNm	= sVarVal
				endif
		
				if ( cmpstr( rsUnits, "none" ) )						// skip empty descriptors...
					if (  rnVarType == RL4  ||   rnVarType == RL8 )
						sprintf sVarVal, "%.2lf", str2num( sVarVal )		// 6 digits after the decimal point are too much...
					endif
					if ( nCfsHeaderInfo == 3 )
						 printf  "\t\tCFSR3a\tSc:%4d\t/%7d\tVarN:%2d/%2d  \tVK:%d   VS:%3d \tVT:%d\t%s\t%s \t%s \r", DataSection, gDataSections, VarNo, gDSVars, VarKind, rnVarSize, rnVarType,  pad( rsDescription,19), pad( sVarVal, 8) , pad(rsUnits, 8 )  
					endif	 
					if ( gRadDebgSel >= 3  &&  PnDebgCFSR )
						if ( rnVarType == LSTR )
							printf  "\t\tCFSR3b\tSc:%4d\t/%7d\tVar:%2d/%2d  \t%s\t%s \t%s \r", DataSection, gDataSections, VarNo,  gDSVars, pad( rsDescription,19), sVarVal, rsUnits	// strings can be very long : formating is not possible
						else
							printf  "\t\tCFSR3b\tSc:%4d\t/%7d\tVar:%2d/%2d  \t%s\t%s \t%s \r", DataSection, gDataSections, VarNo,  gDSVars, pad( rsDescription,19), pad( sVarVal, 8) , pad(rsUnits, 8 ) 
						endif	 
					endif	 
		
					if ( VarNo != 7 )  				// skip the name as it is redundant and as the length is indeterminate (or put it at the end)   030207 should be entry '...Scriptname'  TODO  search this item instead of relying on index 7
						 sAllVars = sAllVars + pad(sVarVal, 6) + " \t"		//??? for some reason this does not work : gives string too long
					endif
				endif
			endfor
			sAllVars	= sAllVars + sProtoNm
		
			if ( nCfsHeaderInfo == 2   ||   ( nCfsHeaderInfo == 1  &&  ( CfsVal( CFSHndIn, DSVAR, DataSection, "Frame" )  <= 1  &&   CfsVal( CFSHndIn, DSVAR, DataSection, "Sweep" )  <= 1 ) ) )	// in 'Short Info' mode display only sweep 0,1  (or fr==sw=0,1) for every block,  many lines, little information....
				printf  "\t\tCFSR3\t%7d\t/%7d\t%s \r", DataSection, gDataSections, sAllVars[0,240]
			endif
		endfor		
	endif

	if ( nCfsHeaderInfo )
		printf  "\tSCALING FACTORS AND OFFSET VALUES\r" 
		printf  "\t\tCFSR4 \t\t DaSect\t\t Chan\t StOfs \tPoints  \t VScale \t\t(±full range)  \t VOfs \tXScale\t XOfs \r"
		for ( DataSection = 1; DataSection < 1 + gDataSections; DataSection += 1 )	// 031202
			for ( ch = 0; ch  < gChannels; ch += 1 )					
				GetDSChan( CFSHndIn, ch, DataSection, rnStartOffset, rnPoints,  rYScale, rvVoltageOffset, rvXScale, rvXOffset )
				if ( ( nCfsHeaderInfo == 1  &&  DataSection <= 3  )   ||   nCfsHeaderInfo >= 2 )
					//printf  "\t\tCFSR4 \t%7d\t/%7d\t%2d /%2d\t%7d\t%7d\t%9.5lf\t%10.3lf\t%6g\t%6g\t%6g \r", DataSection, gDataSections, ch, gChannels, rnStartOffset, rnPoints,  rYScale, rYScale * kMAXAMPL,  rvVoltageOffset, rvXScale, rvXOffset  
					//printf  "\tTEST high prec\tCFSR4 \t%7d\t/%7d\t%2d /%2d\t%7d\t%7d\t%12.8lf\t%12.8lf\t%12.8lf\t%12.8lf\t%12.8lf \r", DataSection, gDataSections, ch, gChannels, rnStartOffset, rnPoints,  rYScale, rYScale * kMAXAMPL,  rvVoltageOffset, rvXScale, rvXOffset  
					// printf  "\t\t\t\t\tXScl: %10g \tXOfs: %11.5lf \r", rvXScale, rvXOffset  
				endif
			endfor
		endfor
	endif

	// Process the script extracted from the acquired data (in EVAL) the same way as script in FPULS: fill a notebook with this string, display it, and convert to global script string
	if ( gbIsIgor )	
		string  	sWin			= ksPN_NAME_SDEO 					// 'sdeo'
		nvar	 /Z	gbDisplay		=  $"root:uf:" + sFolder + ":" + sWin + ":gbDisplay0000"
		nvar		bShowScript	=  $"root:uf:" + sFolder + ":de:gbShwScr0000"
		ConstructOrUpdateNotebook( bShowScript, sFolder , ":script" , ksSCRIPTEXTRACTED_NB_WNDNAME_, sRawScript )	// fill a notebook with the original script

		CompactScript( sFolder, sRawScript )								// 050205  sets  globals  'gsScript'  and  'gsCoScript'  (original  and compacted script without comments)
		if ( nvar_exists( gbDisplay )  &&  gbDisplay )							// Possibly (depending on the state of the show/hide control) display the notebook  
			InterpretScript_( sFolder, sWin, kNOACQ )							// Includes DisplayStimulus1()
		endif
		// todo: Enable / disable the controls. Use parameter 2 to initially position the windows so that they do not completely cover the acquisition stimulus windows.
	endif
	return rnPoints
End


static Function		GetMissingDataParams( CFSHndIn )
	variable	CFSHndIn
	nvar		gbIsIgor		= root:uf:evo:cfsr:gbIsIgor
	nvar		gDataSections	= root:uf:evo:cfsr:gDataSections
	nvar		gChannels 	= root:uf:evo:cfsr:gChannels
	nvar		gFrmPerBlk	= root:uf:evo:cfsr:gFrmPerBlk
	nvar		gSwpPerFrm	= root:uf:evo:cfsr:gSwpPerFrm
	nvar		gbHasPoN	= root:uf:evo:cfsr:gbHasPoN
	svar		gsDataFileR	= root:uf:evo:cfsr:gsDataFileR
	svar		gsStimFile		= root:uf:evo:cfsr:gsStimFile
	svar		gsPrgAndVersion= root:uf:evo:cfsr:gsPrgAndVersion	
	variable	channels, sweeps, swpPerFrm

	gsPrgAndVersion   = CFSVarUnits( CFSHndIn, FILEVAR, "Data file from" )  + CFSStr( CFSHndIn, FILEVAR, 0, "Data file from" ) // e.g  FPulse212			

	gbIsIgor		= FALSE
	gsStimFile		= ""
	gsDataFileR		= ""
	gFrmPerBlk	= 1
	gSwpPerFrm	= 1
	gbHasPoN	= FALSE

	// data are from program 'PULSE (Pascal) '...
	if( cmpstr( gsPrgAndVersion[ 0, 4 ], "PULSE" ) == 0 )
		gbHasPoN= 1
		channels	= gChannels
		sweeps	= 5								// todo : a better guess for the number of sweeps per frame....
		UserInput2( "Enter the correct values. Data are from " + gsPrgAndVersion, "Number of channels:" , channels, "Sweeps per frame (counting primary+correction sweeps, but not resulting P over N)", sweeps )
		gChannels = channels
		gSwpPerFrm= sweeps
		gFrmPerBlk= trunc ( gDataSections / ( gSwpPerFrm + gbHasPoN ) )
		CFSReadSectionStructure211Lower( CFSHndIn )	// 030401a

	// data are from program 'PATCH'...
	elseif ( cmpstr( gsPrgAndVersion[ 0, 4 ], "PATCH" ) == 0 )
		//channels = min ( 2, gChannels ) 				// PATCH (most probably) lies saying there are 4 channels, usually there are only 1 or 2 
		channels 	=  2 								// PATCH (most probably) lies saying there are 4 channels, usually there are only 1 or 2 
		swpPerFrm= 1 // gSwpPerFrm					// interleaved data (e.g. file 080702AH.dat) needs 2   
		UserInput2( "Enter the correct value. Data are from " + gsPrgAndVersion, "Number of channels:" , channels, "Number of sweeps per frame:", swpPerFrm )
		gChannels 		= min( channels, gChannels)  	// workaround for old CFS files (from PATCH600) having erroneous channel numbers
		gSwpPerFrm		= swpPerFrm				// 
		gFrmPerBlk		= trunc( gDataSections / gSwpPerFrm ) 
		CFSReadSectionStructure211Lower( CFSHndIn )	// 030401a

	// data are from program 'TRAIN'...
	elseif( cmpstr( gsPrgAndVersion[ 0, 4 ], "TRAIN" ) == 0 )
		gbHasPoN	= UserInput1(  "Enter the correct value. Data are from " + gsPrgAndVersion, "Do the data contain an 'P over N' corrected sweep (no=0, yes=1) ?" , 0 )
		CFSReadSectionStructure211Lower( CFSHndIn )	// 030401a

	// data are from program 'DYNCLAMP'...
	elseif( cmpstr( gsPrgAndVersion[ 0, 4 ], "DYNCL" ) == 0 )
		gbHasPoN	= UserInput1(  "Enter the correct value. Data are from " + gsPrgAndVersion, "Do the data contain an 'P over N' corrected sweep (no=0, yes=1) ?" , 0 )
		CFSReadSectionStructure211Lower( CFSHndIn )	// 030401a

	// data are from IGOR:  IgorPlsT (till 0301)   or   FPULSE (from 0302  ...up to Version 211)
	elseif( cmpstr( gsPrgAndVersion[ 0, 7 ], "IgorPlsT" ) == 0   ||  ( cmpstr( gsPrgAndVersion[ 0, 5 ], "FPulse" ) == 0  &&  CFSVal( CFSHndIn, FILEVAR, 0, "Data file from" )  <= 211 ) )
		// print "old",  CFSStr( CFSHndIn, FILEVAR, 0, "Data file from" ) 
		gbIsIgor		= TRUE
		gsDataFileR	= CFSStr( CFSHndIn, FILEVAR, 0, "DataFile" ) 
		gsStimFile		= CFSStr( CFSHndIn, FILEVAR, 0, "StimFile" ) 
		gFrmPerBlk	= CFSVal( CFSHndIn, FILEVAR, 0, "FrmPerProt" )		// 030919 this is actually frames per block

		// 030728 special case for very old data written with IgorPlsT200 , e.g. '0682e0aa.dat' . 
		if ( numType( gFrmPerBlk ) == kNUMTYPE_NAN )
			gFrmPerBlk		= trunc( gDataSections / gSwpPerFrm ) 
		endif

		gSwpPerFrm	= CFSVal( CFSHndIn, FILEVAR, 0, "SwpPerFrm" )

		gbHasPoN	= CFSVal( CFSHndIn, FILEVAR, 0, "HasPoN" )
		// 030728 special case for very old data written with IgorPlsT200 , e.g. '0682e0aa.dat' . 
		if ( numType( gbHasPoN ) == kNUMTYPE_NAN )
			gbHasPoN	= UserInput1(  "Enter the correct value. Data are from " + gsPrgAndVersion, "Do the data contain an 'P over N' corrected sweep (no=0, yes=1) ?" , 0 )
		endif
		
//Improvement / todo : interpret script  to get frame/sweep/segment structure for Cfs file with multiple different blocks
		CFSReadSectionStructure211Lower( CFSHndIn )	// 030401a

	// data are from IGOR:  FPULSE ( Version 212 or higher (processes multiple blocks) )
	elseif( cmpstr( gsPrgAndVersion[ 0, 5 ], "FPulse" ) == 0  &&  CFSVal( CFSHndIn, FILEVAR, 0, "Data file from" )  >= 212 ) 
		// print "new", CFSStr( CFSHndIn, FILEVAR, 0, "Data file from" ) 
		gbIsIgor		= TRUE
		gsDataFileR	= CFSStr( CFSHndIn, FILEVAR, 0, "DataFile" ) 
		gsStimFile		= CFSStr( CFSHndIn, FILEVAR, 0, "StimFile" ) 
		gFrmPerBlk	= CFSVal( CFSHndIn, FILEVAR, 0, "FrmPerProt" )		// 030919 this is actually frames per block
		gSwpPerFrm	= CFSVal( CFSHndIn, FILEVAR, 0, "SwpPerFrm" )
		gbHasPoN	= CFSVal( CFSHndIn, FILEVAR, 0, "HasPoN" )
		CFSReadSectionStructure212AndUp( CFSHndIn )	// 030401a

	else
		Alert( kERR_IMPORTANT,  "Data are from unknown source '" + gsPrgAndVersion + "' " )
	endif

	// 031212
	//  For testing : Step through PROT/BLK/FRM/SWP  and  check that only valid used sections are found ( cave1: blocks may contain different numbers of frames and sweeps, cave2: if the last protocol is truncated it may contain any numbers...
	//  The present code relies heavily on checking if we are in the last (possibly truncated) protocol. The advantage is that  wPbfs2Sct  and   wBlkFrmSwp  has few dimensions
	//  Another approach would be to extend  wPbfs2Sct  and  wBlkFrmSwp  by  the index 'Protocol'   (and possibly wBlkFrmSwp also by 'Frame' )  and store the   gXXXLast information there.  
//	nvar		gProtLast		= root:uf:evo:cfsr:gProtLast			// is always == CfsProts()  -1  ?????
//	nvar		gBlkLast		= root:uf:evo:cfsr:gBlkLast	
//	nvar		gFrmLast		= root:uf:evo:cfsr:gFrmLast	
//	nvar		gSwpLast		= root:uf:evo:cfsr:gSwpLast	
//	variable	pr, bl, fr, sw, sct = 0, SctBeg, SctEnd, SectionsInFrm, BlkLast, FrmLast, SwpLast
//	for ( pr = 0; pr < CfsProts(); pr += 1 )	
//		BlkLast	= pr < gProtLast  ?  CfsBlocks()  :  gBlkLast +1							// if the last protocol is truncated it will probably have less blocks than all previous complete protocols
//		for ( bl = 0; bl < BlkLast; bl += 1 )
//			FrmLast	=  pr ==  gProtLast  &&  bl == gBlkLast 	?   gFrmLast+1 : CfsFrames( bl )		// if the last protocol is truncated it will probably have less frames than all previous complete protocols
//			SctBeg	= sct
//			for ( fr = 0; fr < FrmLast; fr += 1 )
//				SwpLast	=  pr ==  gProtLast  &&  bl == gBlkLast 	&&  fr == gFrmLast 	?   gSwpLast+1 : CfsSweeps( bl )// if the last protocol is truncated it will probably have less sweeps than all previous complete protocols
//				SectionsInFrm =   SwpLast  + CfsHasPon( bl ) 							// 031212 todo  what if truncation is exactly at = before/after pon section??????????????
//				sct	+= SectionsInFrm
//			endfor
//			SctEnd	= sct - 1
//			if ( pr == 0  ||  pr == gProtLast )
//				printf "\t\t\tCFSInitializeReadFile() GetMissingDataParams()\tpr:%2d/%2d\tbl:%2d/%2d\tFrames:%2d \tx %d\t ( Sweeps:%2d\t + PoN:%2d ) \t-> Section: %4d\t...%4d \r", pr, CfsProts(), bl, BlkLast,  FrmLast, SectionsInFrm, SwpLast, CfsHasPon( bl ),  SctBeg, SctEnd
//			elseif ( pr == 1  &&  bl == 0 )
//				printf "\t\t\t\t . . . \r"	
//			endif
//		endfor
//	endfor
End


static Function		CFSReadSectionStructure211Lower( CFSHndIn )
// 030404	expand the simple block/frame/sweep structure of files written before 0403 (before FPulse V211)  into the elaborate b/f/s structure of FPulse V212 so that only 1 ReadCfs  will handle both file types
// 		..Convert	gFrmPerBlk, gSwpPerFrm, gbHasPoN  -> root:uf:evo:cfsr:wBlkDSBeg[], root:uf:evo:cfsr:wBlk2Sect[], root:uf:evo:cfsr:wBlkFrmSwp[]
	variable	CFSHndIn 
	nvar		gDataSections	= root:uf:evo:cfsr:gDataSections
	nvar		gDataSctPerPro	= root:uf:evo:cfsr:gDataSctPerPro
	nvar		gFrmPerBlk	= root:uf:evo:cfsr:gFrmPerBlk
	nvar		gSwpPerFrm	= root:uf:evo:cfsr:gSwpPerFrm
	nvar		gbHasPoN	= root:uf:evo:cfsr:gbHasPoN

	nvar		gProtLast		= root:uf:evo:cfsr:gProtLast		// 031212
	nvar		gBlkLast		= root:uf:evo:cfsr:gBlkLast	
	nvar		gFrmLast		= root:uf:evo:cfsr:gFrmLast	
	nvar		gSwpLast		= root:uf:evo:cfsr:gSwpLast	

	variable	sct, ch = 0		// todo ?? does cfs always start with ch 0 ??
	variable	rnStartOffset, rnPoints,  rYScale, rvVoltageOffset, rvXScale, rvXOffset	// NOTE : the range used by the CFS Files is +-32768, not +-2048 

	// Construct the wave containing the number of points and the begin point frames for every data section 
	killwaves	/Z						root:uf:evo:cfsr:wBlkDSBeg
	make	/I /N=( gDataSections+1, PDS_MAX )	root:uf:evo:cfsr:wBlkDSBeg	// 1 element more allows storage of (pseudo) start of block behind last (32bit int)
	wave	wBlkDSBeg	=	root:uf:evo:cfsr:wBlkDSBeg	

	// get the number of PROTOCOLS		( V211 has only 1 block )
	gDataSctPerPro	=  gFrmPerBlk * ( gSwpPerFrm + gbHasPon )
	variable	pr, bl = 0, fr, sw, nSumPts = 0
	variable	nMaxProt	= ceil( gDataSections / gDataSctPerPro ) 
	// printf "\t\tCFSReadSectionStructure211(1) gDataSections:%d  , gFrmPerBlk:%d   gSwpPerFrm:%d   gbHasPon:%d\t-> gDataSctPerPro:%d \t-> nMaxProt:%5.2lf \t-> %5d \r",  gDataSections,  gFrmPerBlk,  gSwpPerFrm,  gbHasPon,  gDataSctPerPro, gDataSections / gDataSctPerPro , nMaxProt
	variable	nMaxBlock	= 1					// V211 has only 1 block 

	// Construct the wave containing the number of frames and sweeps for every block 
// 051114 removed
//	redimension /N = ( nMaxProt, cMAXFrmSwpPon )	   		root:uf:evo:cfsr:wBlkFrmSwp
	make /O /I /N = ( nMaxProt, cMAXFrmSwpPon )	   		root:uf:evo:cfsr:wBlkFrmSwp
	wave   wBlkFrmSwp	= root:uf:evo:cfsr:wBlkFrmSwp
	wBlkFrmSwp		= 0

	// Step 2 : construct the wave containing the section number for every block/frame/sweep combination 
// todo
	make /O /I /N = ( nMaxProt,  nMaxBlock,   gFrmPerBlk, gSwpPerFrm+1 )	root:uf:evo:cfsr:wPbfs2Sct = -1	// V211 has only 1 block  .  Sweeps have 1 more swp for PoN, -1 indicates unused/empty
	wave	wPbfs2Sct	=	root:uf:evo:cfsr:wPbfs2Sct
	// printf "\t\t\tCFSReadSectionStructure211(1a)\thas built wPbfs2Sct[ maxProt:%2d ][ maxblock:%2d ][ maxfrm:%2d ][ maxswp:%2d (+1)] \r", dimSize( wPbfs2Sct, 0 ),  dimSize( wPbfs2Sct, 1 ), dimSize( wPbfs2Sct, 2 ), dimSize( wPbfs2Sct, 3 ) - 1

	// 	Step 3a : Store information which data sections corresponds to which protocol / block / frame / sweep / pon 	 in  'wSct2Pbfs'  		041210 / 051114
	make /O /U /I /N = ( gDataSections, kPBFS_MAX )	    root:uf:evo:cfsr:wSct2Pbfs	  = 0		//  	32 bit unsigned int

	// Step 1 : get maximum frames, sweeps
	variable	Pon, HasPon, SwpCnt, FrmCnt
	wBlkDSBeg[ 0 ][ PDS_BEG ]  =   0 
	for ( sct = 0; sct < gDataSections; sct += 1 )

		GetDSChan( CFSHndIn, ch, sct + 1, rnStartOffset, rnPoints, rYScale, rvVoltageOffset, rvXScale, rvxOffset )// DataSection channel info, passed parameters are changed !
		// printf  "\t\t\tCFSReadSectionStructure211(0)\t GetDSChan() \tch:%d  Sc:%d/%d  StOfs:%4d\tPoints:%4d  \tVSc:%g  VOf:%g  XSc:%g  XOf:%g \r", ch, sct+1, gDataSections,rnStartOffset, rnPoints,  rYScale, rvVoltageOffset, rvXScale, rvXOffset  
		if ( rnPoints < 0 )			// 030325  could previously happen when multiple dac channels were in wrong order in IO section in script
			Alert( kERR_IMPORTANT,  "Corrupted  CFS file.  Aborting..." )
			return	kERROR
			rnPoints = 0
		endif

		wBlkDSBeg[ sct     ][ PDS_TIMEFR1 ]	=  CFSVal( CFSHndIn, DSVAR, sct+1, "Time since first fr" )  // 050920 - 051114  sct, "Time since first fr" ) 
		wBlkDSBeg[ sct     ][ PDS_PTS ]  	=  rnPoints	// todo eliminate  PDS_PTS.............
		wBlkDSBeg[ sct+1 ][ PDS_BEG ]  	=  wBlkDSBeg[ sct ][ PDS_BEG ] +  wBlkDSBeg[ sct ][ PDS_PTS ]	// start of (non-existing) block behind last block is stored in wBlkDSBeg[ gDataSection ][ PDS_BEG ]  
	
		pr		= floor( sct / ( gFrmPerBlk * ( gSwpPerFrm + gbHasPon ) ) )
		bl		= 0					// V211 has only 1 block 
		fr		= floor( ( sct - pr * gFrmPerBlk  * ( gSwpPerFrm + gbHasPon ) ) / ( gSwpPerFrm + gbHasPon ) )
		sw		= sct - ( pr * gFrmPerBlk  +  fr ) * ( gSwpPerFrm + gbHasPon )
		Pon		= 0													//  041210 - 051114	todo

		SetSct2Pbfs( sct, kPROT,	pr )										//  041210 - 051114	
		SetSct2Pbfs( sct, kBLK,	bl )										//  041210 - 051114	
		SetSct2Pbfs( sct, kFRM,	fr )										//  041210 - 051114	
		SetSct2Pbfs( sct, kSWP,	sw )										//  041210 - 051114	
		SetSct2Pbfs( sct, kPON,	Pon )										//  041210 - 051114	

		wPbfs2Sct[ pr ][ bl ][ fr ][ sw ]	= sct	

		wBlkFrmSwp [ pr ][ cFRM ]	= gFrmPerBlk
		wBlkFrmSwp [ pr ][ cSWP ]	= gSwpPerFrm
		wBlkFrmSwp [ pr ][ cPON ]	= gbHasPon
		// printf "\t\t\tCFSReadSectionStructure211(3)\tsct:%4d/%4d\twBlk2Sct  \tbeg:%7d/%7d    \tPr:%2d/%2d\tbl:%2d/%2d\tfr:%2d/%2d \tsw:%2d/%2d \tPoN:%2d \r",sct ,gDataSections, DSBegin_( sct ), wPbfs2Sct[ pr ][ bl ][ fr ][ sw ],  pr , nMaxProt,  bl , nMaxBlock, fr , CfsFrames( pr ), sw , CfsSweeps( pr )  + CfsHasPon( pr ),  CfsHasPon( pr )
	endfor

	gProtLast		= pr					// 031212
	gBlkLast		= 0					// V211 has only 1 block 
	gFrmLast		= fr	
	gSwpLast		= sw	
	// printf "\t\t\tCFSReadSectionStructure211(3b)\thas counted		\tProtLast: %2d   \tBlockLast: %2d  \tFrmLast:  %2d   \tSwpLast: %2d   [nMaxBlock:%d]   \r", gProtLast, gBlkLast, gFrmLast, gSwpLast, nMaxBlock

//	// Step 3 : fill the wave containing the section number for every block/frame/sweep combination 
//	for ( sct = 0; sct < gDataSections; sct += 1 )
//		GetDSChan( CFSHndIn, ch, sct + 1, rnStartOffset, rnPoints, rYScale, rvVoltageOffset, rvXScale, rvxOffset )// DataSection channel info, passed parameters are changed !
//		pr		= floor( sct / ( gFrmPerBlk * ( gSwpPerFrm + gbHasPon ) ) )
//		fr		= floor( ( sct - pr * gFrmPerBlk  * ( gSwpPerFrm + gbHasPon ) ) / ( gSwpPerFrm + gbHasPon ) )
//		sw		= sct - ( pr * gFrmPerBlk  +  fr ) * ( gSwpPerFrm + gbHasPon )
//		wPbfs2Sct[ pr ][ bl ][ fr ][ sw ]	= sct	
//		printf "\t\t\tCFSReadSectionStructure211(3)\tsct:%4d/%4d\twBlk2Sct  \tbeg:%7d/%7d    \tPr:%2d/%2d\tfr:%2d/%2d \tsw:%2d/%2d \tPoN:%2d \r",sct ,gDataSections, wBlkDSBeg[sct][PDS_BEG], wPbfs2Sct[ pr ][ bl ][ fr ][ sw ],  pr , nMaxProt, fr , wBlkFrmSwp [ pr ][ cFRM ], sw+pon , wBlkFrmSwp [ pr ][ cSWP ]  + wBlkFrmSwp [ pr ][ cPON ],wBlkFrmSwp [ pr ][ cPON ]
//	endfor
End

static Function		CFSReadSectionStructure212AndUp( CFSHndIn )
// 030326c	manage different numbers of points in different datasections (needed as different blocks will generally not contain the same number of points) 
	variable	CFSHndIn 
	nvar		gDataSections	= root:uf:evo:cfsr:gDataSections
	nvar		gDataSctPerPro	= root:uf:evo:cfsr:gDataSctPerPro

// 031020 
// Handle unfinished truncated blocks/frames/sweeps occuring when reading CFS when the user had prematurely stopped acquisition.
// One could  extend the data structure wBlkFrmSwp [ bl ][ cFRM ]     ->    wBlkFrmSwp [  protocol  ] [ bl ][ cFRM ] , but this approach is not taken.
// The information needed is 
// 	1.) the maximum values for prot/block/frame/sweep = the rectangular dimensions of the  wPbfs2Sct data structure	= the block/frame/sweep values of all completed protocols		= dimsize( wPbfs2Sct, x )
// 	2.) the      last	values for prot/block/frame/sweep = the indices of the last recorded data section				= the block/frame/sweep values of the last unfinished protocols	= gXXXLast
// Todo:
// Tested for handling of truncated frames (1 block case), but not extensively tested for handling of multiple truncated blocks or sweeps
// Not yet modified  (and not at all tested) for the case PoN = TRUE

	nvar		gProtLast		= root:uf:evo:cfsr:gProtLast		// 031020
	nvar		gBlkLast		= root:uf:evo:cfsr:gBlkLast	
	nvar		gFrmLast		= root:uf:evo:cfsr:gFrmLast	
	nvar		gSwpLast		= root:uf:evo:cfsr:gSwpLast	

	variable	sct, ch = 0		// todo ?? does cfs always start with ch 0 ??
	variable	rnStartOffset, rnPoints,  rYScale, rvVoltageOffset, rvXScale, rvXOffset	// NOTE : the range used by the CFS Files is +-32768, not +-2048 
	string		bf

	// Construct the wave containing the number of points and the begin point frames for every data section 
	killwaves	/Z							root:uf:evo:cfsr:wBlkDSBeg
	make	/I /N=( gDataSections+1, PDS_MAX )	root:uf:evo:cfsr:wBlkDSBeg		// 1 element more allows storage of (pseudo) start of block behind last
	wave	wBlkDSBeg				=	root:uf:evo:cfsr:wBlkDSBeg	

	// get the number of  BLOCKS
	variable	nMaxProt
	variable	bl, fr, sw, nMaxSwp = 0, nMaxFrm = 0, nSumPts = 0
	variable	nMaxBlock	= CfsVal( CFSHndIn, DSVAR, 1, "MaxBlock" )		// can be retrieved from any section

	// Construct the wave containing the number of frames and sweeps for every block 
// 051114 removed
//	redimension /N = ( nMaxBlock, cMAXFrmSwpPon )	   root:uf:evo:cfsr:wBlkFrmSwp
	make /O /I  /N = ( nMaxBlock, cMAXFrmSwpPon )	   root:uf:evo:cfsr:wBlkFrmSwp
	wave   	wBlkFrmSwp						= root:uf:evo:cfsr:wBlkFrmSwp
	wBlkFrmSwp		= 0

	// Step 1 : get maximum frames, sweeps
	variable	MaxPr	= 0, pr	= 0, nDsPerProtLast	= 0				  // 030918 
	variable	Pon, HasPon, SwpCnt, FrmCnt
	gDataSctPerPro		= 0
	wBlkDSBeg[ 0 ][ PDS_BEG ]  =   0 
	for ( sct = 0; sct < gDataSections; sct += 1 )

		GetDSChan( CFSHndIn, ch, sct + 1, rnStartOffset, rnPoints, rYScale, rvVoltageOffset, rvXScale, rvxOffset )// DataSection channel info, passed parameters are changed !
//		printf  "\t\t\tCFSReadSectionStructure212\t GetDSChan() \tch:%d  Sc:%d/%d  StOfs:%4d\tPoints:%4d  \tVSc:%g  VOf:%g  XSc:%g  XOf:%g \r", ch, sct+1, gDataSections,rnStartOffset, rnPoints,  rYScale, rvVoltageOffset, rvXScale, rvXOffset  
//		if ( rnPoints < 0 )			// 030325  could previously happen when multiple dac channels were in wrong order in IO section in script
//			Alert( kERR_IMPORTANT,  "Corrupted  CFS file.  Aborting..." )
//			return	kERROR
//			rnPoints = 0
//		endif

		wBlkDSBeg[ sct     ][ PDS_TIMEFR1 ]	=  CFSVal( CFSHndIn, DSVAR, sct+1, "Time since first fr" )  // 050920 sct, "Time since first fr" ) 
		wBlkDSBeg[ sct     ][ PDS_PTS ]  	=  rnPoints	// todo eliminate  PDS_PTS.............
		wBlkDSBeg[ sct+1 ][ PDS_BEG ]  	=  wBlkDSBeg[ sct ][ PDS_BEG ] +  wBlkDSBeg[ sct ][ PDS_PTS ]	// start of (non-existing) block behind last block is stored in wBlkDSBeg[ gDataSection ][ PDS_BEG ]  

		// 040324 much faster than previous version but assumes DS_xxx ordering which was introduced with Version2.12 (2003 April)
		bl		= str2num( xCFSGetVarVal( CFSHndIn, DS_BLOCK,	 	DSVAR, sct+1, ERRLINE ) )
		fr		= str2num( xCFSGetVarVal( CFSHndIn, DS_FRAME, 		DSVAR, sct+1, ERRLINE ) )
		sw		= str2num( xCFSGetVarVal( CFSHndIn, DS_SWEEP, 		DSVAR, sct+1, ERRLINE ) )
		pon		= str2num( xCFSGetVarVal( CFSHndIn, DS_PON, 		DSVAR, sct+1, ERRLINE ) )	// this sweep is the PoN-corrected sweep
		nMaxBlock= str2num( xCFSGetVarVal( CFSHndIn, DS_MAXBLOCK, 	DSVAR, sct+1, ERRLINE ) )
		FrmCnt	= str2num( xCFSGetVarVal( CFSHndIn, DS_MAXFRAME, 	DSVAR, sct+1, ERRLINE ) )
		SwpCnt	= str2num( xCFSGetVarVal( CFSHndIn, DS_MAXSWEEP, 	DSVAR, sct+1, ERRLINE ) )
		HasPon	= str2num( xCFSGetVarVal( CFSHndIn, DS_HASPON, 		DSVAR, sct+1, ERRLINE ) )	// to this block PoN-correction was applied: this block has PoN-corrected sweeps

		nMaxSwp	= max( nMaxSwp, SwpCnt )
		nMaxFrm	= max( nMaxFrm,  FrmCnt )

		wBlkFrmSwp [ bl ][ cFRM ]	= FrmCnt
		wBlkFrmSwp [ bl ][ cSWP ]	= SwpCnt
		wBlkFrmSwp [ bl ][ cPON ]	= HasPon
		// printf "\t\t\tCFSReadSectionStructure212(1)\tsct:%4d/%4d\twBlkDSBeg \tbeg:%7d\t\t\tpr:%2d\tbl:%2d/%2d\tfr:%2d/%2d \tsw:%2d/%2d \tPoN:%2d/%2d  \r", sct, gDataSections, DSBegin_( sct ), pr, bl , nMaxBlock, fr , FrmCnt, sw , SwpCnt, HasPon, Pon

//		if ( bl == nMaxBlock-1  &&  fr ==  FrmCnt-1  &&  sw == SwpCnt-1 )    		// 030918 this is the normal end of a protocol (user did NOT prematurely abort) 
// 060414
//		if ( bl == nMaxBlock-1  &&  fr ==  FrmCnt-1  &&  sw == SwpCnt - 1 + 		HasPon )				// This is the normal end of a protocol (user did NOT prematurely abort) 
		if ( bl == nMaxBlock-1  &&  fr ==  FrmCnt-1  &&  sw == SwpCnt - 1  &&  pon == HasPon )				// This is the normal end of a protocol (user did NOT prematurely abort) 
			if ( pr == 0 )
				gDataSctPerPro	= sct + 1						
			endif
			pr += 1
		endif

	endfor
	
	// 031017 This file's acquisition has been aborted prematurely already during the first protocol: 
	// ..the Blk, Frm, Swp numbers in the file header are not consistent with the actual  data sections found in the file and must be adjusted
	if ( pr == 0 )								
		gDataSctPerPro	= gDataSections			// ..we have just 1 unfinished protocol

// 051005  todo
// still not exhaustively finished and tested.  Todo think and test cases with truncated frames/sweeps and more than 1 protocol
//		nMaxFrm		= gDataSections / nMaxSwp	// ..with a lower number of frames than expected from the file header . .....Will fail in the case of too few sweeps  and 1 frame

if ( nMaxFrm == 1 )
	nMaxSwp		= gDataSections 				// ..with a lower number of sweeps than expected from the file header 
	wBlkFrmSwp [ bl ][ cSWP ]	= gDataSections		// tested with  'dummydye0AM.dat'    1 Protocol, 1 Block, 1 Frame  truncated after 13 of 100 sweeps
else
		nMaxFrm		= gDataSections / nMaxSwp	// ..with a lower number of frames than expected from the file header 
endif


		// sprintf bf, "CFSRead : Acquisition has been aborted prematurely already during the first protocol %d . ", pr 	// for testing: display this warning until program handles this case correctly
		// Alert( kERR_LESS_IMPORTANT, bf )
		pr += 1
	endif

	nDsPerProtLast	= mod( gDataSections-1, gDataSctPerPro ) + 1		//  the last protocol will have a smaller number of data sections if the user aborted the acquisition prematurely
	if ( nDsPerProtLast != gDataSctPerPro )
		// sprintf bf, "CFSRead : Acquisition has been aborted prematurely in protocol %d . ", pr// for testing: display this warning until program handles this case correctly
		// Alert( kERR_LESS_IMPORTANT, bf )
		pr += 1
	endif

	nMaxProt	= pr

	// Step 2 : construct the wave containing the section number for every block/frame/sweep combination 
// 051114
//	redimension /N = ( nMaxProt, nMaxBlock, nMaxFrm, nMaxSwp+1 )  root:uf:evo:cfsr:wPbfs2Sct	// 1 more swp for PoN
	make  /O /I /N = ( nMaxProt, nMaxBlock, nMaxFrm, nMaxSwp+1 )  root:uf:evo:cfsr:wPbfs2Sct	// 1 more swp for PoN
	wave	wPbfs2Sct	=	root:uf:evo:cfsr:wPbfs2Sct		
	wPbfs2Sct	= -1															// default value must be is -1 to indicate unused/empty
	// printf "\t\t\tCFSReadSectionStructure212(2a)\thas built wPbfs2Sct[ ProtDim:%2d ][ BlockDim:%2d ][ FrmDim:%2d ][ SwpDim:%2d (+1) ]    Datasections per Prot(normal/last): %d / %d \r", dimSize( wPbfs2Sct, 0 ),  dimSize( wPbfs2Sct, 1 ), dimSize( wPbfs2Sct, 2 ), dimSize( wPbfs2Sct, 3 ) - 1, gDataSctPerPro, nDsPerProtLast 
	// printf "\t\t\tCFSReadSectionStructure212(2a)\tonly for dummydye...AM/AI   nmaxfrm= %g   nmaxswp= %g                wPbfs2Sct[ 0 ][ 0 ][ 0 ][ 0 ] = %g    (should be 0 )\r", nMaxFrm, nMaxSwp, wPbfs2Sct[ 0 ][ 0 ][ 0 ][ 0 ] 

	
	// Step 3 : Step through SECTIONS  and  fill the wave containing the section number for every block/frame/sweep combination   and   vice versa

	// 	Step 3a : Store information which data sections corresponds to which protocol / block / frame / sweep / pon 	 in  'wSct2Pbfs'  		041210
	make /O /U /I /N = ( gDataSections, kPBFS_MAX )	    root:uf:evo:cfsr:wSct2Pbfs	  = 0		//  	32 bit unsigned int
	// wave	wSct2Pbfs	=	root:uf:evo:cfsr:wSct2Pbfs		

	// 	Step 3b:  Store information which  protocol / block / frame / sweep / pon combination  corresponds to which  data section  in  'wPbfs2Sct'
	pr	= 0										  		// 030918  
	for ( sct = 0; sct < gDataSections; sct += 1 )
		GetDSChan( CFSHndIn, ch, sct + 1, rnStartOffset, rnPoints, rYScale, rvVoltageOffset, rvXScale, rvxOffset )// DataSection channel info, passed parameters are changed !

		// 040324 much faster than previous version but assumes DS_xxx ordering which was introduced with Version2.12 (2003 April)
		bl		= str2num( xCFSGetVarVal( CFSHndIn, DS_BLOCK,	 	DSVAR, sct+1, ERRLINE ) )
		fr		= str2num( xCFSGetVarVal( CFSHndIn, DS_FRAME, 		DSVAR, sct+1, ERRLINE ) )
		sw		= str2num( xCFSGetVarVal( CFSHndIn, DS_SWEEP, 		DSVAR, sct+1, ERRLINE ) )
		pon		= str2num( xCFSGetVarVal( CFSHndIn, DS_PON, 		DSVAR, sct+1, ERRLINE ) )	// this sweep is the PoN-corrected sweep
		FrmCnt	= str2num( xCFSGetVarVal( CFSHndIn, DS_MAXFRAME, 	DSVAR, sct+1, ERRLINE ) )
		SwpCnt	= str2num( xCFSGetVarVal( CFSHndIn, DS_MAXSWEEP, 	DSVAR, sct+1, ERRLINE ) )
		HasPon	= str2num( xCFSGetVarVal( CFSHndIn, DS_HASPON, 		DSVAR, sct+1, ERRLINE ) )	// to this block PoN-correction was applied: this block has PoN-corrected sweeps 041012

		SetSct2Pbfs( sct, kPROT,	pr )	// wSct2Pbfs[ sct ][ kPROT ]	= pr												//  041210	
		SetSct2Pbfs( sct, kBLK,	bl )	// wSct2Pbfs[ sct ][ kBLK ]		= bl												//  041210	
		SetSct2Pbfs( sct, kFRM,	fr )	// wSct2Pbfs[ sct ][ kFRM ]	= fr												//  041210	
		SetSct2Pbfs( sct, kSWP,	sw )	// wSct2Pbfs[ sct ][ kSWP ]	= sw												//  041210	
		SetSct2Pbfs( sct, kPON,	pon )	// wSct2Pbfs[ sct ][ kPON ]	= pon											//  041210	

		wPbfs2Sct[ pr ][ bl ][ fr ][ sw + pon ]	= sct	

		gProtLast	= pr				// 031020  Handle unfinished blocks/frames occuring when the user prematurely stops acquisition.
		gBlkLast	= bl
		gFrmLast	= fr
		gSwpLast	= sw

		// printf "\t\t\tCFSReadSectionStructure212(3)\tsct:%4d/%4d\t  wPbfs2Sct \tbeg:\t%7d\t%7d\tpr:%2d/%2d\tbl:%2d/%2d\tfr:%2d/%2d \tsw:%2d/%2d \tPoN:%2d/%2d \r", sct, gDataSections, DSBegin_( sct ), wPbfs2Sct[ pr] [ bl ][ fr ][ sw ],  pr, nMaxProt, bl, nMaxBlock, fr,  CfsFrames( bl ), sw+pon ,  CfsSweeps( bl )  +  CfsHasPon( bl ),  CfsHasPon( bl ), pon
		//if ( bl == nMaxBlock-1  &&  fr ==  FrmCnt-1  &&  sw == SwpCnt - 1 )			// 030918  
// 060414
//		if ( bl == nMaxBlock-1  &&  fr ==  FrmCnt-1  &&  sw == SwpCnt - 1 + 		HasPon )				// This is the normal end of a protocol (user did NOT prematurely abort) 
		if ( bl == nMaxBlock-1  &&  fr ==  FrmCnt-1  &&  sw == SwpCnt - 1  &&  pon == HasPon )				// This is the normal end of a protocol (user did NOT prematurely abort) 
			pr += 1
		endif
	endfor

// 031208
	// printf "\t\t\tCFSReadSectionStructure212(3a)\thas built wPbfs2Sct[\tProtDim: %2d ][\tBlockDim: %2d ][\tFrmDim:  %2d ][\tSwpDim: %2d (+1) ]    Datasections per Prot(normal/last): %d / %d \r", dimSize( wPbfs2Sct, 0 ),  dimSize( wPbfs2Sct, 1 ), dimSize( wPbfs2Sct, 2 ), dimSize( wPbfs2Sct, 3 ) - 1, gDataSctPerPro, nDsPerProtLast 
	// printf "\t\t\tCFSReadSectionStructure212(3b)\thas counted		\tProtLast: %2d   \tBlockLast: %2d  \tFrmLast:  %2d   \tSwpLast: %2d   [nMaxBlock:%d]   \r", gProtLast, gBlkLast, gFrmLast, gSwpLast, nMaxBlock
	// printf "\t\t\tCFSReadSectionStructure212(3b)\tonly for dummydye...AM/AI   wPbfs2Sct[ 0 ][ 0 ][ 0 ][ 0 ] = %g    (should be 0 )\r", wPbfs2Sct[ 0 ][ 0 ][ 0 ][ 0 ] 
End


// 051114
Function		SetSct2Pbfs( sct , nType, nValue )
	variable	sct, nType, nValue
	wave	wSct2Pbfs		= root:uf:evo:cfsr:wSct2Pbfs		
	wSct2Pbfs[ sct ][ nType ]	= nValue	
End

// 051114
Function		Sct2Pbfs( sct , nType )
	variable	sct, nType
	wave	wSct2Pbfs		= root:uf:evo:cfsr:wSct2Pbfs		
	return	wSct2Pbfs[ sct ][ nType ]
End

// 051114
Function		Pbfs2Sct( pr, bl, fr, sw_pon )
	variable	pr, bl, fr, sw_pon
	wave	wPbfs2Sct		= root:uf:evo:cfsr:wPbfs2Sct		
	return	wPbfs2Sct[ pr ][ bl ][ fr ][ sw_pon ]
End



Function		CfsProts()
	wave	wPbfs2Sct	=	root:uf:evo:cfsr:wPbfs2Sct
	// print "CfsProts()", dimSize( wPbfs2Sct, 0 )
	return	dimSize( wPbfs2Sct, 0 )
End 
Function		CfsBlocks()
	wave	wPbfs2Sct	=	root:uf:evo:cfsr:wPbfs2Sct
	return	dimSize( wPbfs2Sct, 1 )
End 
Function		CfsFrames( bl )
	variable	bl
	wave	wBlkFrmSwp	= root:uf:evo:cfsr:wBlkFrmSwp
	// printf "\t\t\t\tCfsFrames(bl:%d) \t:%d \r",  bl, wBlkFrmSwp [ bl ][ cFRM ]
	return	wBlkFrmSwp [ bl ][ cFRM ]
End 
Function		CfsSweeps( bl )
	variable	bl
	wave	wBlkFrmSwp	= root:uf:evo:cfsr:wBlkFrmSwp
	return	wBlkFrmSwp [ bl ][ cSWP ]
End 
Function		CfsHasPoN( bl )
	variable	bl
	wave	wBlkFrmSwp	= root:uf:evo:cfsr:wBlkFrmSwp
	return	wBlkFrmSwp [ bl ][ cPON ]
End 

Function		DSBegin_( sw )
	variable	sw
	wave	wBlkDSBeg	= root:uf:evo:cfsr:wBlkDSBeg
	return	wBlkDSBeg[ sw ][ PDS_BEG ]
End
Function		DSPoints_( sw )
	variable	sw
	wave	wBlkDSBeg	= root:uf:evo:cfsr:wBlkDSBeg
	return	wBlkDSBeg[ sw ][ PDS_PTS ]
End
Function		DSTimeSinceFr1_( sw )
	variable	sw
	wave	wBlkDSBeg	= root:uf:evo:cfsr:wBlkDSBeg
	return	wBlkDSBeg[ sw ][ PDS_TIMEFR1 ]
End


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function	/S	WaveNm( nWvKind, ch )
	variable	nWvKind, ch 
	switch ( nWvKind )
		case	kWV_ORG_:
			return	"root:uf:evo:cfsr:wCfsBig" + num2str( ch )
		break
		case	kWV_AVG_:
			return	FoMovAvgWvNm_( ch )
//			return	"root:uf:evo:cfsr:wCfsAvg" + num2str( ch )
		break
		default:
			return ""
	endswitch
End

Function	/S	DSPanelNm_( nWvKind )
	variable	nWvKind
	return	"DSPanel" + num2str( nWvKind )
End	

Function	/S	DSPanelTitle_( nWvKind )
	variable	nWvKind
	switch ( nWvKind )
		case	kWV_ORG_:
			return	"Data sections" 
		break
		case	kWV_AVG_:
			return	"MAv"
		break
		default:
			return ""
	endswitch
End	


Function		DataSectionCnt_( nWvKind ) 
	variable	nWvKind
	switch ( nWvKind )
		case	kWV_ORG_:
			return	DataSections()
		break
		case	kWV_AVG_:
			return	MovAvgDataSections_()
		break
		default:
			return 0
	endswitch
End



static Function		CFSReadSections( CFSHndIn, ch, sPathAndFile, nWvKind )
// fills 'wRdBig' with complete file data of 1 channel
	variable	CFSHndIn, ch, nWvKind  
	string		sPathAndFile
	nvar		gChannels			= root:uf:evo:cfsr:gChannels
	nvar		gDataSections		= root:uf:evo:cfsr:gDataSections
	nvar		gRadDebgSel 		= root:uf:dlg:gRadDebgSel
	nvar	   /Z	PnDebgCFSR 		= root:uf:dlg:Debg:CfsRd			// may not exist, exists only after panel PnTest() has been built 
	svar		gsPrgAndVersion	= root:uf:evo:cfsr:gsPrgAndVersion	

	variable	Section
	
	string  	sWaveNm	= WaveNm( nWvKind, ch )
	make	/O  /N=0	$sWaveNm							// construct big wave (one per AdcChan) with 0 points and a unique name  e.g.  "root:uf:evo:cfsr:wCfsBig" + num2str( ch )	
	wave  	wRdBig  =	$sWaveNm							// ..but use it here under an alias name 


	if (  gRadDebgSel == 2   &&  PnDebgCFSR )
		printf  "\tREADING SECTIONS \t\t%s  Ch:%2d/%2d  Sections:%d \r", sPathAndFile, ch, gChannels, gDataSections 
		printf  "\t\tCFSR5\tChan\tDaSect\tfilling Big[    ]\t from pt\t   to pt\t(=BlkPts)   blk \trnPoints\tCfsMxB\t  StOfs \t VScale \t\t(±full range)  \t VOfs \tXScale\t XOfs  \r"
	endif

	variable	bIsIgorPlsT205		=  ! cmpstr( gsPrgAndVersion, "IgorPlsT205" )
	if ( bIsIgorPlsT205 )
		Alert( kERR_LESS_IMPORTANT, "As data are from  'IgorPlsT205'   their  Y scaling is corrected by multiplication with 3.2768 " )
	endif
	variable	BigStartPt  = 0
	variable	rnStartOffset, rnPoints,  rYScale, rvVoltageOffset, rvXScale, rvXOffset	// NOTE : the range used by the CFS Files is +-32768, not +-2048 
	variable	nBlockBytes, b, nBlocks
	// Doing the data section reading in 3 steps (Read all for counting, dimension, read all for data)  is MUCH faster than doing it in 1 step (Read + count +  dimension all )..
	// .. as  Redimension often (but not always)  takes up to 20 ms while all the rest of the code together takes less than 1 ms
	// Step 1 : Loop through all data sections just for counting the data points
	for ( Section = 1; Section <= gDataSections; Section += 1 )
		
		GetDSChan( CFSHndIn, ch, Section, rnStartOffset, rnPoints, rYScale, rvVoltageOffset, rvXScale, rvxOffset )// DataSection channel info, passed parameters are changed !

		if ( rnPoints < 0 )			// 030325  could previously happen when multiple dac channels were in wrong order in IO section in script
			Alert( kERR_IMPORTANT,  "Corrupted  CFS file.  Aborting..." )
			return	kERROR
			rnPoints = 0
		endif

		nBlocks = trunc( ( rnPoints*2 - 1) / kCFSMAXBYTE ) + 1
			
		// this loop allows reading more than 64KBytes from one datasection (rnPoints need not be the same for all sections)
		for ( b = 0; b < nBlocks; b += 1 )
			nBlockBytes = ( b == nBlocks - 1 ) ? rnPoints*2 - b * kCFSMAXBYTE : kCFSMAXBYTE
			//if ( ( Section <= 25  &&  b < 10 )  || ( Section > gDataSections - 25 && b > nBlocks - 10 ) )
			//	printf  "\tCFSReadSec GetDSChan( a )\t%s\tch:%d\tSc:%3d\t/%4d\tStOfs:%4d\tPts:\t%7d\tVSc:%.3g\t\t\t\tVOf:%g  XSc:%g  XOf:%g   blocks:%3d\tBlockBytes:\t%7d\tRedim N:\t%7d\t  \r", pd(gsPrgAndVersion,10), ch, Section, gDataSections,rnStartOffset, rnPoints,  rYScale,  rvVoltageOffset, rvXScale, rvXOffset , nBlocks, nBlockBytes,  BigStartPt + nBlockBytes / 2	 	
			//endif
			BigStartPt += nBlockBytes / 2 												// sections can have differerent 'rnPoints'
		endfor
	endfor		// sections 

	// Step 2 : Redimension the big  wave just once. This 3 step process is MUCH faster than redimensioning once for every data section.
	redimension	/N=( BigStartPt ) 	wRdBig	 				// 040917	corrected....
	// print "\tCFSReadSections()  RIGHT !!!  gDataSections:", gDataSections, "Pts(cfsbig):", numpnts( wRdBig )

	// Step 3 : Loop through all data sections again for reading the data
	BigStartPt  = 0
	for ( Section = 1; Section <= gDataSections; Section += 1 )
		
		GetDSChan( CFSHndIn, ch, Section, rnStartOffset, rnPoints, rYScale, rvVoltageOffset, rvXScale, rvxOffset )// DataSection channel info, passed parameters are changed !

		// 030611	Attempt to correct the wrong scaling  caused by a programming error in 'IgorPlsT205' 
		//		Useful when reading old data.  Could easily be extended to other program version which did not scale correctly
		//		Cave: The CFS file has wrong scaling: when the old data are read by  'Pascal StimFit' the error will persist.
		variable	PossiblyWrongScale	= rYScale
		if ( bIsIgorPlsT205 )
			 rYScale	=  PossiblyWrongScale * kMAXAMPL /  kFULLSCL_mV 
		endif

		make /O /W /N=( kCFSMAXBYTE / 2 )	$("root:uf:evo:cfsr:wCFSsmall" + num2str( ch ) )	// construct the wave with unique name..	
		wave  		wCFSsmall 	= 		$("root:uf:evo:cfsr:wCFSsmall" + num2str( ch ) )	// ..but use it here under an alias name 

		nBlocks = trunc( ( rnPoints*2 - 1) / kCFSMAXBYTE ) + 1
			
		// this loop allows reading more than 64KBytes from one datasection (rnPoints need not be the same for all sections)
		for ( b = 0; b < nBlocks; b += 1 )
			nBlockBytes = ( b == nBlocks - 1 ) ? rnPoints*2 - b * kCFSMAXBYTE : kCFSMAXBYTE
			//if ( ( Section <= 25  &&  b < 10 )  || ( Section > gDataSections - 25 && b > nBlocks - 10 ) )
			//	printf  "\tCFSReadSec GetDSChan( b )\t%s\tch:%d\tSc:%3d\t/%4d\tStOfs:%4d\tPts:\t%7d\tVSc:%.3g (%g?)\tVOf:%g  XSc:%g  XOf:%g   blocks:%3d\tBlockBytes:\t%7d\tRedim N:\t%7d\t  \r", pd(gsPrgAndVersion,10), ch, Section, gDataSections,rnStartOffset, rnPoints,  rYScale, 	PossiblyWrongScale, rvVoltageOffset, rvXScale, rvXOffset , nBlocks, nBlockBytes,  BigStartPt + nBlockBytes / 2	 	
			//endif

			//  file handle, channel required, DS required, LONG data point in channel at which to start, WORD points wanted, wave to transfer to, LONG bytes allocated for transfer	
			xCFSGetChanData( CFSHndIn, ch, Section, b * kCFSMAXBYTE / 2, nBlockBytes / 2,  wCFSsmall,  2 * rnPoints, ERRLINE ) //  gn MSGLINE )
			// put all sections together to one big wave per channel (=the whole experiment = up to some MByte)
			if ( gRadDebgSel == 2   &&  PnDebgCFSR )
				printf  "\t\tCFSR5\t%2d /%2d\t%3d /%3d\t\t%7d\t%7d\t%7d\t%7d\t %3d /%3d\t%7d\t%7d\t%7d\t%9.5lf\t%10.3lf\t%6g\t%6g\t%6g\r", ch, gChannels, Section, gDataSections, numpnts( wRdBig) , BigStartPt, BigStartPt+nBlockBytes/2,  nBlockBytes/2,  b,  nBlocks, rnPoints, kCFSMAXBYTE, rnStartOffset, rYScale, rYScale * kMAXAMPL, rvVoltageOffset, rvXScale, rvXOffset  
			endif	
			wRdBig[ BigStartPt,  BigStartPt + nBlockBytes / 2 ] = wCFSsmall[ p - BigStartPt ] * rYScale	// datasections start at 1, waveform arithmetic
			BigStartPt += nBlockBytes / 2 												// sections can have differerent 'rnPoints'
	
		endfor
	endfor		// sections 

End	



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  GENERAL APPROACH  :  Get  any cfs variable by its description ..CFSVal(), CFSStr(), CfsVarUnits()
//   Read the desired  cfs variable from cfs file any  time it is needed 
//   ANOTHER APPROACH / Not realized ..(partly realized 170902....)
//   ....if there are only  few variables which are needed (e.g. sample rate) it  might be easier....
//   ...to store them once  in globals the first time they are retrieved in  CFSInitializeReadFile()....
  
static Function		CfsVal( CFSHndIn, VarKind, Section, sVarDesc )
 	variable	CFSHndIn, VarKind, Section 
 	string		sVarDesc
	return	str2num( CfsStr( CFSHndIn, VarKind, Section, sVarDesc ) )	// returns Nan if not found
End

static Function	/S	CfsStr( CFSHndIn, VarKind, Section, sVarDesc )
// 030401 returns string or number as string of  'sVarDesc'  if  'sVarDesc'  is found among the data/file section variables of the CFS file, returns empty string  if not found  which will be the case if the Cfs file was written by a previous version of FPulse or by another program 
// 030401 potential problems:  may be too slow 
 	variable	CFSHndIn, VarKind, Section 
 	string		sVarDesc
	nvar		gFileVars = root:uf:evo:cfsr:gFileVars, gDSVars = root:uf:evo:cfsr:gDSVars
	variable	VarNo, nVars  = VarKind == DSVAR ? gDSVars : gFileVars
	variable	rnVarSize, rnVarType												// these passed 'rn..' parameters are changed!
	string		sVarVal, rsUnits, rsDescription										// these passed 'rs..' parameters are changed!
	// we look through all variables (in datasection or in file section)  OF THE CFS FILE to see if we find one matching to 'sVarDesc'.  Accidentally other programs could use the same variable name.
	for ( VarNo = 0; VarNo < nVars; VarNo += 1 )	
		GetVarDesc( CFSHndIn, VarNo, VarKind, rnVarSize, rnVarType, rsUnits, rsDescription)	// these passed 'r..' parameters are changed!
		if ( cmpstr( sVarDesc, RemoveTrailingWhiteSpace( rsDescription ) ) == 0 )			// 030208 remove the trailing space  'Data file from '
			if ( VarKind == 1 &&  Section == 0 )
				InternalError( "CfsStr() : Data section 0 is illegal with VarKind 1" )
			endif
			sVarVal	= xCFSGetVarVal( CFSHndIn, VarNo, VarKind, Section, ERRLINE )
			 // if ( Section < 3 )
			// 	printf "\t\t\t\tCfsStr()\t Kind:%d  Sec:%2d\tVD:\t%s\tVV:\t%s\tUnits:%s\tDescr:\t%s\t[VarNo:%2d\t%s\tis useless/wrong/version dependent] \r",  VarKind, Section,  pd( sVardesc,12), sVarVal, pd(rsUnits,6),  pd(rsDescription,12), VarNo, pd( StringFromList( VarNo, lstDS_TEXT ), 16 )
			 // endif
			return	sVarVal
		else
			continue
		endif
	endfor
	// printf "\t\t\t\tVarVal()\tSect:%2d\tVarDesc:%s\t-> not found \r",  Section,  pd( sVarDesc,10)
	return	""
End

static Function	/S	CfsVarUnits( CFSHndIn, VarKind, sVarDesc )
// 030401 returns Units of  'sVarDesc'  if  'sVarDesc'  is found among the data/file section variables of the CFS file, returns empty string  if not found  which will be the case if the Cfs file was written by a previous version of FPulse or by another program 
// 030401 potential problems:  may be too slow
 	variable	CFSHndIn, VarKind
 	string		sVarDesc
	nvar		gFileVars = root:uf:evo:cfsr:gFileVars, gDSVars = root:uf:evo:cfsr:gDSVars
	variable	VarNo, nVars  = VarKind == DSVAR ? gDSVars : gFileVars	
	variable	rnVarSize, rnVarType												// these passed 'rn..' parameters are changed!
	string		sVarVal, rsUnits, rsDescription										// these passed 'rs..' parameters are changed!
	// we look through all variables (in datasection or in file section)  OF THE CFS FILE to see if we find one matching to 'sVarDesc'. Accidentally other programs could use the same variable name.
	for ( VarNo = 0; VarNo < nVars; VarNo += 1 )	
		GetVarDesc( CFSHndIn, VarNo, VarKind, rnVarSize, rnVarType, rsUnits, rsDescription)	// these passed 'r..' parameters are changed!
		if ( cmpstr( sVarDesc, RemoveTrailingWhiteSpace( rsDescription ) ) == 0 )			// 030208 remove the trailing space  'Data file from '
			// printf "\t\t\t\tVarUnits()  \tVarDesc:%s\tUnits:%s\tDescr:%s\t[VarNo:%2d\t%s\tis useless/wrong/version dependent] \r",  pd( sVardesc,10), pd(rsUnits,6),  pd(rsDescription,12), VarNo, pd( StringFromList( VarNo, DS_TEXT ), 18 )
			return	rsUnits
		else
			continue
		endif
	endfor
	// printf "\t\t\t\tVarUnits()  \tVarDesc:%s\t-> not found \r",  pd( sVarDesc,10)
	return	""
End


static Function		UserInput1( sMainText, sText1, Value1 )
	string		sMainText, sText1
	variable	Value1
	variable	vUserInput1 = Value1
	Prompt	vUserInput1,  sText1
	DoPrompt	sMainText , vUserInput1
	if ( !V_flag ) 
		Value1 = vUserInput1							// user did not cancel  
	endif
	return	Value1								// 1 parameter can be returned directly
End

static Function		UserInput2( sMainText, sText1, rValue1, sText2, rValue2 )
	string		sMainText, sText1, sText2
	variable	&rValue1, &rValue2						// 2 or more parameters must be returned as references
	variable	vUserInput1 = rValue1, vUserInput2 = rValue2
	Prompt	vUserInput1,  sText1 ; Prompt	vUserInput2,  sText2
	DoPrompt	sMainText , vUserInput1 , vUserInput2
	if ( !V_flag ) 
		rValue1 = vUserInput1 ;  rValue2 = vUserInput2		// user did not cancel  
	endif											// 2 or more parameters must be returned as references
End

static Function		UserInput3( sMainText, sText1, rValue1, sText2, rValue2 , sText3, rValue3 )
	string		sMainText, sText1, sText2, sText3
	variable	&rValue1, &rValue2, &rValue3				// 2 or more parameters must be returned as references
	variable	vUserInput1 = rValue1, vUserInput2 = rValue2, vUserInput3 = rValue3
	Prompt	vUserInput1,  sText1 ;  Prompt	vUserInput2,  sText2 ;  Prompt	vUserInput3,  sText3
	DoPrompt	sMainText , vUserInput1 , vUserInput2 , vUserInput3
	if ( !V_flag ) 
		rValue1 = vUserInput1 ;  rValue2 = vUserInput2 ;  rValue3 = vUserInput3
	endif											// 2 or more parameters must be returned as references
End


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

static Function		SetCFSSmpInt( CFSHndIn, section )
// store CFS sample interval  as extracted from the Cfs file  in a global variable
	variable	CFSHndIn, section
	variable	CFSSmpRate  = CFSVal( CFSHndIn, DSVAR, section, "Sample rate" ) 
	// printf "\t\tSetCFSSmpInt(1)  CfsSmpRate:%g	\r",  CFSSmpRate
	if ( cmpstr( CFSVarUnits( CFSHndIn, DSVAR, "Sample rate" ), "kHz" ) == 0 )
		CFSSmpRate *= 1000
	endif
	nvar		nCFSSmpInt	= root:uf:evo:de:gReadSmpInt0000		// The global variable belongs to a SetVariable control which is automatically updated by Igor.  
	nCFSSmpInt = 1000000 / CFSSmpRate						// Hz -> us
	// printf "\t\tSetCFSSmpInt(2)  CfsSmpRate:%g	->  CfsSmpInt:%g \r",  CFSSmpRate, nCFSSmpInt
End

Function		CfsSmpInt()
// retrieve CFS sample interval as extracted from the Cfs file  from a global variable. The global variable belongs to a SetVariable control which is automatically updated by Igor.  
	nvar		nCFSSmpInt	= root:uf:evo:de:gReadSmpInt0000
	// printf "\t\tCFSSmpInt()  returning  %g \r",  nCFSSmpInt
	return	nCFSSmpInt
End


Function	/S	GetCFSChanName( ch )
	variable	ch 
	string		sChanName, sYUnits, sXUnits				
	variable	DataType, DataKind, Spacing, Other			
	FileChan( ch, sChanName, sYUnits, sXUnits, DataType, DataKind, Spacing, Other )	// passed parameters are changed!
	return	sChanName
End


Function		CfsChannels_()
	nvar		gChannels		= root:uf:evo:cfsr:gChannels
	return	gChannels
End


//Function	/S	GetCFSYUnits( ch )
//	variable	ch 
//	string		sChanName, sYUnits, sXUnits				
//	variable	DataType, DataKind, Spacing, Other			
//	FileChan( ch, sChanName, sYUnits, sXUnits, DataType, DataKind, Spacing, Other )	// passed parameters are changed!
//	return	sYUnits
//End


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

static Function		GetGenInfo( CFSHnd )
// gets the 3 'general' variables from the CFS file and stores them in global string 
	variable	CFSHnd
	string		sString = xCFSGetGenInfo( CFSHnd, MSGLINE )	
	svar		gsDate		= root:uf:evo:cfsr:gsDate		
	svar		gsTime		= root:uf:evo:cfsr:gsTime		
	svar		gsComment	= root:uf:evo:cfsr:gsComment		
	gsTime	= StringFromList( 0, sString, ksCFSSEP ) 
	gsDate	= StringFromList( 1, sString, ksCFSSEP ) 
	gsComment= StringFromList( 2, sString, ksCFSSEP ) 
	// printf "\t\tGetGenInfo() \t\t '%s'  \t-> sTime:'%s' \t sDate:'%s' \t sComment:'%s' \r", sString, gsTime, gsDate, gsComment
End

static Function		GetFileInfo( CFSHnd )
// gets the 4 'file' variables from the CFS file and stores them in globals
	variable	CFSHnd
	nvar		gFileVars		= root:uf:evo:cfsr:gFileVars
	nvar	 	gDSVars		= root:uf:evo:cfsr:gDSVars
	nvar		gChannels		= root:uf:evo:cfsr:gChannels
	nvar		gDataSections	= root:uf:evo:cfsr:gDataSections
	string		sString	= xCFSGetFileInfo( CFSHnd, MSGLINE )	
	gChannels		= str2num( StringFromList( 0, sString, ksCFSSEP ) ) 
	gFileVars		= str2num( StringFromList( 1, sString, ksCFSSEP ) ) 
	gDSVars		= str2num( StringFromList( 2, sString, ksCFSSEP ) ) 
	gDataSections	= str2num( StringFromList( 3, sString, ksCFSSEP ) ) 
	// printf "\t\tGetFileInfo() \t\t '%s'  \t-> Channels:%d \t\t FileVars:%d \t\t DSVars:%d \t DataSections:%d \r",  sString, gChannels, gFileVars, gDSVars, gDataSections
End

static Function		SetFileChan( CFSHnd, Channel )
// gets the 'file chan' variables from the CFS file  and stores them in global text wave (channel is index)
	variable	CFSHnd, Channel 
	wave  /T	wFileChan	= root:uf:evo:cfsr:wFileChan
	string		sString = xCFSGetFileChan( CFSHnd, Channel, MSGLINE )	
	// printf "\t\tSetFileChan() \t Hnd:%d   Channel:%d \t\t sFileChan:'%s'   \r",  CFSHnd, Channel, sString
	wFileChan[ Channel ] = sString
End

static Function		FileChan( Channel, sChanName, sYUnits, sXUnits, DataType, DataKind, Spacing, Other )
// gets the 'file chan' variables from the global text wave and returns them as references to the calling function
	variable	Channel 
	string		&sChanName, &sYUnits, &sXUnits				// passed parameters are changed!
	variable	&DataType, &DataKind, &Spacing, &Other			// passed parameters are changed!
	wave  /T	wFileChan	= root:uf:evo:cfsr:wFileChan
	string		sString 	= wFileChan[ Channel ]
	sChanName	= StringFromList( 0, sString, ksCFSSEP ) 
	sYUnits		= StringFromList( 1, sString, ksCFSSEP ) 
	sXUnits		= StringFromList( 2, sString, ksCFSSEP ) 
	DataType		= str2num( StringFromList( 3, sString, ksCFSSEP ) ) 
	DataKind		= str2num( StringFromList( 4, sString, ksCFSSEP ) ) 
	Spacing		= str2num( StringFromList( 5, sString, ksCFSSEP ) ) 
	Other		= str2num( StringFromList( 6, sString, ksCFSSEP ) ) 
	// printf "\t\tFileChan() \t '%s'   Channel:%d \t\t sChanName:'%s' \t sYUnits:'%s'  sXUnits:'%s'  DataType:%d  DataKind:%d  Spacing:%d  Other:%d  \r",  sString, Channel, sChanName, sYUnits, sXUnits, DataType, DataKind, Spacing, Other 
End

Function	/S	FileChanYUnits( Channel )
// gets the 'file chan' variables from the global text wave, extracts and returns the YUnits
	variable	Channel 
	string		sYUnits
	wave  /T	wFileChan	= root:uf:evo:cfsr:wFileChan
	string		sString 	= wFileChan[ Channel ]
	sYUnits		= StringFromList( 1,  sString, ksCFSSEP ) 
	// printf "\t\tFileChanYUnits() \t '%s'   Channel:%d \tt\t\t\t sYUnits:'%s' \r",  sString, Channel, sYUnits
	return	sYUnits
End

static Function		GetVarDesc( CFSHnd, VarNo, VarKind, rnVarSize, rnVarType, rsUnits, rsDescription )
	variable	CFSHnd, VarNo, VarKind
	variable	&rnVarSize,	&rnVarType				// passed parameters are changed!
	string		&rsUnits,		&rsDescription				// passed parameters are changed!
	string		sString	= xCFSGetVarDesc( CFSHnd, VarNo, VarKind, ERRLINE )	
 	// printf "\t\tGetVarDesc() \t Hnd:%d   VarNo:%d \t\t VarKind:%d \t sString:'%s'   \r",  CFSHnd, VarNo, VarKind, sString
	rnVarSize		= str2num( StringFromList( 0, sString, ksCFSSEP ) ) 
	rnVarType		= str2num( StringFromList( 1, sString, ksCFSSEP ) ) 
	rsUnits		= StringFromList( 2, sString, ksCFSSEP ) 
	rsDescription	= StringFromList( 3, sString, ksCFSSEP ) 
	// printf "\t\tGetVarDesc() \t Hnd:%d   VarNo:%d \t VarKind:%d \t VarSize:%2d  VarType:%d  Units:'%s' \t Description:'%s'   \r",  CFSHnd, VarNo, VarKind, rnVarSize, rnVarType, rsUnits, rsDescription
End

static Function		GetDSChan( CFSHnd, ch, DataSection, rnStartOffset, rnPoints,  rvYScale, rvYOffset, rvXScale, rvXOffset )
	variable	CFSHnd, ch, DataSection
	variable	&rnStartOffset, &rnPoints,  &rvYScale, &rvYOffset, &rvXScale, &rvXOffset	// passed parameters are changed!
	string		sString	= xCFSGetDSChan( CFSHnd, ch, DataSection, ERRLINE )	
	// printf "\t\tGetDSChan() \t Hnd:%d   ch:%d  DaSc:%d \t sString:'%s'   \r",  CFSHnd, ch, DataSection, sString
	rnStartOffset	= str2num( StringFromList( 0, sString, ksCFSSEP ) ) 
	rnPoints		= str2num( StringFromList( 1, sString, ksCFSSEP ) ) 
	rvYScale		= str2num( StringFromList( 2, sString, ksCFSSEP ) ) 
	rvYOffset		= str2num( StringFromList( 3, sString, ksCFSSEP ) ) 
	rvXScale		= str2num( StringFromList( 4, sString, ksCFSSEP ) ) 
	rvXOffset		= str2num( StringFromList( 5, sString, ksCFSSEP ) ) 
	// printf "\t\tGetDSChan() \t Hnd:%d   ch:%d  DaSc:%d \t rnStOfs:%d  rnPoints:%d   rvYScale:%g  rvYOffset:%g  rvXScale:%g  rvXOffset:%g  \r",  CFSHnd, ch, DataSection, rnStartOffset, rnPoints,  rvYScale, rvYOffset, rvXScale, rvXOffset
End	


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  TRACE  ACCESS  FUNCTIONS  FOR  THE  USER  AFTER  CFSREAD
//  the trace data are _NOT_ taken directly from the drawn wave but extracted here from the original wave in an extra step for a variety of reasons:
//  -	screen traces may be 'stepped'  meaning some points are skipped  but here the user wants ALL points
//  -	only data actually displayed on screen could be accessed which would only in 'superimposed' mode allow to access all sweeps
//  The extraction here avoids these difficulties but has drawbacks also:
//  -	extra time needed for copying  and extra memory space needed.  If the constructed waves are never deleted  (->killwaves)  it is eventually possible to run out of memory


Function		DataSections()
	nvar		gDataSections =  root:uf:evo:cfsr:gDataSections  
	return	gDataSections
End


Function	/S	TrcExp( nWvIndex, bPrintIt )
	variable	nWvIndex, bPrintIt
	return	TrcSwp( nWvIndex, cCFS_EXP, 0, 0, 0, 0, bPrintIt )
End

Function	/S	TrcProt( nWvIndex, nProt, bPrintIt )
	variable	nWvIndex, nProt, bPrintIt
	return	TrcSwp( nWvIndex, cCFS_PRO, nProt, 0, 0, 0, bPrintIt )
End

Function	/S	TrcBlock( nWvIndex, nProt, nBlk, bPrintIt )
	variable	nWvIndex, nProt, nBlk, bPrintIt
	return	TrcSwp( nWvIndex, cCFS_BLK, nProt, nBlk, 0, 0, bPrintIt )
End

Function	/S	TrcFrame( nWvIndex, nProt, nBlk, nFrm, bPrintIt )
	variable	nWvIndex, nProt, nBlk, nFrm, bPrintIt
	return	TrcSwp( nWvIndex, cCFS_FRM, nProt, nBlk, nFrm, 0, bPrintIt )
End

Function	/S	TrcPrimary( nWvIndex, nProt, nBlk, nFrm, bPrintIt )
	variable	nWvIndex, nProt, nBlk, nFrm, bPrintIt
	return	TrcSwp( nWvIndex, cCFS_PRIM, nProt, nBlk, nFrm, 0, bPrintIt )
End

Function	/S	TrcPrimCorr( nWvIndex, nProt, nBlk, nFrm, bPrintIt )
	variable	nWvIndex, nProt, nBlk, nFrm, bPrintIt
	return	TrcSwp( nWvIndex, cCFS_PCO, nProt, nBlk, nFrm, 0, bPrintIt )
End

Function	/S	TrcCorrFirst( nWvIndex, nProt, nBlk, nFrm, bPrintIt )
	variable	nWvIndex, nProt, nBlk, nFrm, bPrintIt
	return	TrcSwp( nWvIndex, cCFS_COR, nProt, nBlk, nFrm, 0, bPrintIt )
End

Function	/S	TrcCorrAll( nWvIndex, nProt, nBlk, nFrm, bPrintIt )
	variable	nWvIndex, nProt, nBlk, nFrm, bPrintIt
	return	TrcSwp( nWvIndex, cCFS_CORA, nProt, nBlk, nFrm, 0, bPrintIt )
End

Function	/S	TrcResult( nWvIndex, nProt, nBlk, nFrm, bPrintIt )
	variable	nWvIndex, nProt, nBlk, nFrm, bPrintIt
	return	TrcSwp( nWvIndex, cCFS_RES, nProt, nBlk, nFrm, 0, bPrintIt )
End

Function	/S	TrcSweep( nWvIndex, nProt, nBlk, nFrm, nSwp, bPrintIt )
	variable	nWvIndex, nProt, nBlk, nFrm, nSwp, bPrintIt
	return	TrcSwp( nWvIndex, cCFS_SWP, nProt, nBlk, nFrm, nSwp, bPrintIt )
End


// todo : TrcSwp  ->  manual
Function	/S	TrcSwp( nWvIndex, nMode, nProt, nBlk, nFrm, nSwp, bPrintIt )
// Return the name of the extracted segment from the big wave which contains the desired data 
	variable	nWvIndex, nMode, nProt, nBlk, nFrm, nSwp, bPrintIt

	// Check if the wave with the desired channel exists
	string		sBigWvNm  = WaveNm( kWV_ORG_, nWvIndex )  //"root:uf:evo:cfsr:wCfsBig" + num2str( nWvIndex )
	wave	/Z	wRdBig	  = $sBigWvNm
	if ( ! waveExists( wRdBig ) )
		Alert( kERR_IMPORTANT,  "Cfs wave data do not exist  (" + sBigWvNm + ")" )
		return ""	//kERROR
	endif
	variable	pts	= numPnts( wRdBig )

	// Check if the desired Protocol/Block/Frame/Sweep combination exists, if not issue a warning and clip to the next legal combination
	variable	nError		= FALSE
	wave	wPbfs2Sct		= root:uf:evo:cfsr:wPbfs2Sct
	nvar		gDataSections 	= root:uf:evo:cfsr:gDataSections
	nvar		gDataSctPerPro	= root:uf:evo:cfsr:gDataSctPerPro
	variable	rSwp, rSize, rOfs

	// Set size and offset (in sweeps) according to desired mode (e.g. Block, Primary, Result)
	DispCFSSize( nMode, nBlk, gDataSections, gDataSctPerPro, rSwp, rSize, rOfs ) 
	
	if ( 0 > nProt  ||  nProt >= CfsProts() ) 
		nError	= TRUE
		nProt		= min( max( 0, nProt ), CfsProts() - 1 ) 
	endif
	if ( 0 > nBlk  ||  nBlk >= CfsBlocks() ) 
		nError	= TRUE
		nBlk		= min( max( 0, nBlk ), CfsBlocks() - 1 ) 
	endif
	if ( 0 > nFrm  ||  nFrm >= CfsFrames( nBlk ) ) 
		nError	= TRUE
		nFrm		= min( max( 0, nFrm ), CfsFrames( nBlk ) - 1 ) 
	endif
	if ( 0 > nSwp  ||  nSwp >= CfsSweeps( nBlk ) + CfsHasPoN( nBlk ) ) 
		nError	= TRUE
		nSwp	= min( max( 0, nSwp ), CfsSweeps( nBlk ) - 1 ) 
	endif

	// Compute first and last point of desired range referred to 'Big' wave containing the whole experiment
	variable	nLinSwp, nLinSwpEnd, PointFirst, PointLast, nTrcPoints
	nLinSwp  			= wPbfs2Sct[ nProt ][ nBlk ][ nFrm ][ nSwp ]		+ rOfs
	nLinSwpEnd		= nLinSwp + rSize - 1
	PointFirst			= DSBegin_( nLinSwp )
	PointLast			= DSBegin_( nLinSwpEnd ) + DSPoints_( nLinSwpEnd ) 	//   or   -1   
	nTrcPoints			= PointLast - PointFirst
	variable	nSmpInt	= CfsSmpInt() 	
	string	    sTrcWvNm	= "root:uf:evo:cfsr:Trc" + num2str( nWvIndex ) + "_" + num2str( nProt )  + "_" + num2str( nBlk )  + "_" + num2str( nFrm )  + "_" + num2str( nSwp ) + "_" + num2str( nMode )  
	if ( nError )
		string  	sBuf
		sprintf	sBuf, "TrcSwp() : Illegal Prot/Block/Frame/Sweep combination. Clipped to Prot:%d  Block:%d  Frame:%d  Sweep:%d  (->LinSweep:%d) ", nProt, nBlk, nFrm, nSwp, nLinSwp
		//Alert( kERR_IMPORTANT, sBuf )
	else
		if ( bPrintIt )
			printf "\t\tTrcSwp(\t%s\twIdx:%2d\tpr:%2d  bl:%2d  fr:%2d\tsw:%2d )\t%s\tPts:\t%7d\t(%8d  ..\t%7d)\t LS:\t%3d ..%3d\t /%6d\tSw:%3d\tSiz:%3d\tOs:%3d\tSI:%3dus\t%s\t%8d \r", pd(StringFromList( nMode, sDICFSRANGE ),12), nWvIndex, nProt, nBlk, nFrm, nSwp, pd(sTrcWvNm, 24), nTrcPoints,  PointFirst, PointLast,  nLinSwp,  nLinSwpEnd, gDataSections, rSwp, rSize, rOfs, nSmpInt, pd(sBigWvNm,17), pts
		endif
	endif

	// Extract the desired segment  and  return wave name   or   begin / end points
	make	/O /N=(nTrcPoints)  	$sTrcWvNm
	wave	wTrc			= 	$sTrcWvNm
	SetScale /P X, 0, nSmpInt / kXSCALE, ksXUNIT, wTrc

	wTrc[ 0, nTrcPoints - 1 ] = wRdBig[ PointFirst + p ]

//	if ( ! nError )
//		display /K=1 $sTrcWvNm
//	endif
	return	sTrcWvNm
End

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//  Helper

static  constant		cCFS_EXP = 0, cCFS_PRO = 1, cCFS_BLK = 2, cCFS_FRM = 3,  cCFS_PRIM = 4,  cCFS_PCO = 5,  cCFS_COR = 6,  cCFS_CORA = 7,  cCFS_RES = 8,  cCFS_SWP = 9
static strconstant	sDICFSRANGE = "Experiment;   Protocol;      Block;         Frame;         Primary;         Prim+Corr;         Corr (first);         Corr (all);         Result;            Sweep"


Function		DispCFSSize( nMode, Blk, DataSections, DataSctPerPro, rSwp, rSize, rOfs ) 
// When the display mode (=display sweep, frame, protocol..  and  passed parameters  Blk , DataSections and  DataSctPerPro ) are given,...
//...change data size, data offset (all in sweeps)  and  start sweep referred to frame beg    .   Neither  uses nor changes globals .
	variable	nMode, Blk, DataSections, DataSctPerPro
	variable	&rSwp, &rSize, &rOfs						// references are changed  
	variable	FrmPerBlk		= CfsFrames( Blk )
	variable	SwpPerFrm 	= CfsSweeps( Blk )
	variable	bHasPoN		= CfsHasPoN( Blk )
	if ( nMode == cCFS_SWP )							// every sweep 
		rOfs		= 0
		rSize 	= 1
	elseif ( nMode == cCFS_PRIM )						// primary sweep
		rSwp 	= 0								// move to sweep 0 in current  frame in current protocol 
		rOfs		= 0
		rSize 	= 1
	elseif ( nMode == cCFS_COR )						// the first correction sweep
		rSwp 	= 0								// move to sweep 0 in current  frame in current protocol
		rOfs		= 1
		rSize 	= SwpPerFrm  >= 2  ?  1  : 0			// if there is only 1 sweep per frame there is no correction sweep: return zero length  
	elseif ( nMode == cCFS_CORA )						// all correction sweeps
		rSwp 	= 0								// move to sweep 0 in current  frame in current protocol
		rOfs		= 1
		rSize	= SwpPerFrm - 1
	elseif ( nMode == cCFS_RES )						// Result : PoN
		rSwp 	= 0								// move to sweep 0 in current  frame in current protocol 
		rOfs 		= SwpPerFrm			
		rSize 	= bHasPoN
	elseif ( nMode == cCFS_PCO )
		rSwp 	= 0								// move to sweep 0 in current  frame in current protocol 
		rOfs		= 0
		rSize 	= SwpPerFrm						// Prim + Corr
	elseif ( nMode == cCFS_FRM )
		rSwp 	= 0								// move to sweep 0 in current  frame in current protocol 
		rOfs		= 0
		rSize 	= SwpPerFrm + bHasPoN 				// Frame : Prim + Corr + possibly PoN
	elseif ( nMode == cCFS_BLK )
		rSwp 	= 0								// move to sweep 0 in frame 0 in current protocol 
		rOfs		= 0
		rSize 	= FrmPerBlk * ( SwpPerFrm + bHasPoN ) 	// 1 block
	elseif ( nMode == cCFS_PRO )
		rSwp 	= 0								// move to sweep 0 in frame 0 in current protocol 
		rOfs		= 0
		rSize 	= DataSctPerPro				 	// 1 protocol
	elseif ( nMode == cCFS_EXP )
		rSwp 	= 0								// move to sweep 0 in frame 0 in protocol 0 
		rOfs		= 0
		rSize 	= DataSections						// the whole experiment
	else
		InternalError( "DispCFSSize() " )
	 	rSize 	= 0
		rSwp 	= 0								// move to sweep 0 in frame 0 in protocol 0 
		return	kERROR
	endif
	return	0
End

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//  Test

//	Function		Test( nWvIndex )
//		variable	nWvIndex
//		variable	p,b,f,s, nEnd=5//????????????
//		variable	nMode
//	
//		TrcExp( nWvIndex, TRUE )
//	
//		for ( p=0; p < nend; p+= 1 )
//			TrcProt( nWvIndex, p, TRUE )
//		endfor
//	
//		for ( p=0; p < nend; p+= 1 )
//			for ( b=0; b < nend; b+= 1 )
//				TrcBlock( nWvIndex, p, b, TRUE )
//			endfor
//		endfor
//	
//		for ( p=0; p < nend; p+= 1 )
//			for ( b=0; b < nend; b+= 1 )
//				for ( f=0; f < nend; f+= 1 )
//					TrcFrame( nWvIndex, p, b, f, TRUE )
//					TrcPrimary( nWvIndex, p, b, f, TRUE )
//					TrcPrimCorr( nWvIndex, p, b, f, FALSE )
//					TrcCorrFirst( nWvIndex, p, b, f, FALSE )
//					TrcCorrAll( nWvIndex, p, b, f , TRUE )
//					TrcResult( nWvIndex, p, b, f, TRUE )
//				endfor
//			endfor
//		endfor
//	
//		for ( p=0; p < nend; p+= 1 )
//			for ( b=0; b < nend; b+= 1 )
//				for ( f=0; f < nend; f+= 1 )
//					for ( s=0; s < nend; s+= 1 )
//						TrcSweep( nWvIndex, p, b, f, s, TRUE)//FALSE )
//					endfor
//				endfor
//			endfor
//		endfor
//	
//	End


//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// 040410  OBSOLETE but kept for compatibility  for some time........
		Function	/S	TraceCfsTest()
			printf "\r\tTraceCfsTest \r"
			 TraceCfs( 0, 0 )
			 TraceCfs( 0, 1 )
			 TraceCfs( 0, 2 )
			 TraceCfs( 1, 0 )
			 TraceCfs( 1, 1 )
			 TraceCfs( 1, 2 )
			 TraceCfs( 2, 0 )
			 TraceCfs( 2, 1 )
			 TraceCfs( 3, 0 )
			 TraceCfs( 3, 1 )
		End
		
		Function	/S	TraceCfs( nWvIndex, nLinSwp )
		// return wave name string for user access of waves after ReadCfs
		// Flaw1: returns complete frames, should discriminate 'Sweep' , 'Primary' , 'Result' etc.
			variable	nWvIndex, nLinSwp
			string		sBigWvNm	= WaveNm( kWV_ORG_, nWvIndex )	// "root:uf:evo:cfsr:wCfsBig" + num2str( nWvIndex )
			wave	/Z	wRdBig	= $sBigWvNm
			if ( ! waveExists( wRdBig ) )
				Alert( kERR_IMPORTANT,  "Cfs wave data do not exist  (" + sBigWvNm + ")" )
				return ""	//kERROR
			endif
		
			nvar		gDataSections 	= root:uf:evo:cfsr:gDataSections
			if  ( ! ( 0 <= nLinSwp  &&  nLinSwp < gDataSections ) ) 
				Alert( kERR_IMPORTANT,  "Sweep number must be be in the range   0  to " + num2str( gDataSections-1 )  )
				return ""	//kERROR
			endif
			
			variable	nAllPts		= numPnts( wRdBig )
			variable	PointFirst		= DSBegin_( nLinSwp )
			variable	PointLast		= DSBegin_( nLinSwp ) + DSPoints_( nLinSwp ) 	//   or   -1   
			variable	nSweepPts	= PointLast - PointFirst
			variable	nSmpInt		= CfsSmpInt() 	
		
			variable	nBegPt		= 0
			string		sSweepWvNm	= "root:uf:evo:cfsr:wSweep" + num2str( nWvIndex ) + "_" + num2str( nLinSwp )  
			make	/O /N=(nSweepPts)  $sSweepWvNm
			wave	wSweep	= 		$sSweepWvNm
			SetScale /P X, 0, nSmpInt / kXSCALE, ksXUNIT, wSweep
			printf "\tTraceCfs(index:%d  sweep:%d)\t%s  \tSI:%d \tAllPts:%6d  = dsec:%4d * \t%7d \t|%7d\tsweepPts\t->%s \r", nWvIndex, nLinSwp, pd(sBigWvNm,19), nSmpInt, nAllPts, gDataSections, nSweepPts, numpnts( wSweep), pd( sSweepWvNm, 20)
		
			wSweep[ 0, nSweepPts - 1 ] = wRdBig[ nLinSwp * nSweepPts + p ]
			return	sSweepWvNm
		End
// 040410 ..........obsolete but kept for compatibility for some time



//=============================================================================================================================
//   Convert  new-style DAT files (containing entire script)  into old-style DAT files which contain only short partial script but can be read by Pascal StimFit

Function		ConvertDatToOld_()
	svar		gsRdDataFilter	= root:uf:evo:cfsr:gsRdDataFilter
	svar		gsReadDPath	= root:uf:evo:de:gsReadDPath0000
	// Build the file filter selection string so that only files matching  'gsRdDataFilter'  are displayed  ( '.dat'  could be replaced by ksCFS_EXT )
	string		sMyFilter	= "Data files (" + gsRdDataFilter + ".dat);" + gsRdDataFilter + ".dat;"  +  "Data files (*.dat);*.dat;All files (*.*);*.*;;"

	if ( strlen( gsReadDPath ) == 0 )	// only once at program start
		gsReadDPath	= ksDEF_DATAPATH
		//  printf "\t\tConvertDatToOld()    gsReadDPath: '%s' ,  gsRdDataFilter: '%s'  ->  sMyFilter: '%s'  \r", gsReadDPath, gsRdDataFilter, sMyFilter
	endif
	gsReadDPath	= FileDialog( gsReadDPath, sMyFilter )

	if ( strlen( gsReadDPath ) )													// file was valid from the start or user selected a valid file  (did NOT Cancel)

		string  	sWritePathOldStyle	= ReplaceString( ".dat", gsReadDPath, "_SF.dat" )	// Assumption naming....
		 printf "\tConvertDatToOld( \t%s\t ) \tReading CFS and converting to old-style  '%s' ] \r", pd(gsReadDPath,23), sWritePathOldStyle

		variable	CFSHndIn 	= xCFSOpenFile( gsReadDPath, FALSE, TRUE, ERRLINE ) // read-only, speed up memory table, print only errors 
		if ( CFSHndIn > 0 )

			string  	LstTimeDateComm	 = xCFSGetGenInfo( CFSHndIn, MSGLINE )		// reads time, date, comment
			string  	sGenComm		 = StringFromList( 2, LstTimeDateComm, ksCFSSEP )  
		
			string  	LstChanFvarDSvarDS = xCFSGetFileInfo( CFSHndIn, MSGLINE )		// reads and set preliminary gChannels, gFileVars, gDSVars, gDataSections
			variable	nChans			 = str2num( StringFromList( 0, LstChanFvarDSvarDS, ksCFSSEP ) ) 

			CfsCopyHeaderFileAndDSVarDescs_( CFSHndIn, LstChanFvarDSvarDS )		// Get the File and DS var descriptors. The same table is used for the input and for the output file. 
																		// This table is Cfs-internal and has no CfsHandle as it must be and has been set up befores 'xCFSCreateFile(output)'
			variable	CFSHndOut = xCFSCreateFile( sWritePathOldStyle, sGenComm, 1, nChans, MAX_DSVAR, MAX_FILEVAR, ERRLINE ) 
			if ( CFSHndOut > 0 )
	
				CfsCopyFileChan_( CFSHndIn, CFSHndOut, nChans )					// copy for each channel:  sChanName, sYUnits, sXUnits, DataType, DataKind, Spacing, Other 

				CfsCopyHeaderFileVars_( CFSHndIn, CFSHndOut, LstChanFvarDSvarDS)	// + WRITE File vars
		
				CfsCopyReadSections_( CFSHndIn, CFSHndOut, LstChanFvarDSvarDS )	// + WRITE channel data
	
				xCFSCloseFile( CFSHndOut, ERRLINE )
			else
				Alert( kERR_FATAL,  "Cannot open converted output file for writing '" + sWritePathOldStyle + "' ." )
			endif
			
			xCFSCloseFile( CFSHndIn,    ERRLINE )
		else
			Alert( kERR_FATAL,  "Cannot open read file'" + gsReadDPath + "' ." )
		endif

	else
		 printf "Error : ConvertDatToOld()  could not copy file '%s' to old-style '%s' \r", gsReadDPath, sWritePathOldStyle
	endif

End


static Function	CfsCopyFileChan_( CFSHnd, CFSHndOut, nChans )
// gets the 'file chan' variables from the CFS file copy them into output file
	variable	CFSHnd, CFSHndOut, nChans
	variable	ch
	string  	sLstChanLst	= ""
	for ( ch = 0; ch < nChans; ch += 1 )
		sLstChanLst  = xCFSGetFileChan( CFSHnd, ch, MSGLINE ) 
		string  	sChanNm	= StringFromList( 0, sLstChanLst, ksCFSSEP )
		string  	sYUnits	= StringFromList( 1, sLstChanLst, ksCFSSEP )
		string  	sXUnits	= StringFromList( 2, sLstChanLst, ksCFSSEP )
		variable  	nDataType= str2num( StringFromList( 3, sLstChanLst, ksCFSSEP ) )
		variable  	nDataKind	= str2num( StringFromList( 4, sLstChanLst, ksCFSSEP ) )
		variable  	nSpacing	= str2num( StringFromList( 5, sLstChanLst, ksCFSSEP ) )
		variable  	nOther	= str2num( StringFromList( 6, sLstChanLst, ksCFSSEP ) )
		// printf "\t\tFileChan_() \t Hnd:%d   ch:%2d /%2 d \t\t sFileChan:'%s'   \r",  CFSHnd, ch, nChans, sLstChanLst
		xCFSSetFileChan( CFSHndOut, ch,  sChanNm, sYUnits, sXUnits, nDataType, nDataKind, nSpacing, nOther, ERRLINE )
	endfor
End


static Function		CfsCopyHeaderFileAndDSVarDescs_(  CFSHnd, LstChanFvarDSvarDS )
// Get the File var descriptors. The same table is used for the input and for the output file. This table is Cfs-internal and has no CfsHandle as it must be and has been set up befores 'xCFSCreateFile(output)'
	string  	LstChanFvarDSvarDS
	variable	CFSHnd
	variable	nFileVar, nFileVars	= str2num( StringFromList( 1, LstChanFvarDSvarDS, ksCFSSEP ) ) 
	variable	nDSVar, nDSVars	= str2num( StringFromList( 2, LstChanFvarDSvarDS, ksCFSSEP ) ) 
 	variable	sct, nDataSections	= str2num( StringFromList( 3, LstChanFvarDSvarDS, ksCFSSEP ) ) 
	variable	rnVarSize, rnVarType
	string		rsUnits, rsDescription, sVarVal 

	for ( nFileVar = 0; nFileVar < nFileVars; nFileVar += 1)

		// Get the File var descriptors. 
		GetVarDesc( CFSHnd, nFileVar, FILEVAR, rnVarSize, rnVarType, rsUnits, rsDescription )

		//Set the File var descriptors in the same table for the output file. 
		xCFSSetDescriptor( FILEVAR, nFileVar,  rsDescription + "," + StringFromList( rnVarType, klstCFS_DATATYPES ) + "," + rsUnits + "," + num2str( rnVarSize ) ) 	// e.g. "StimFile,LSTR,Stim,30"
		
		// The variable value  'sVarVal'  is here actually not needed, it is extracted only for the following debug print line
		sVarVal	= xCFSGetVarVal( CFSHnd, nFileVar, FILEVAR, -1 , ERRLINE )   			
		// printf  "\t\tCfsCopyHeaderFileAndDSDescVars_( FileVar ) \t\t[v:%2d/%2d\tvk:%d  vs:%3d\tvt:%2d] \t%s\t%s\t%s\r", nFileVar, nFileVars, FILEVAR, rnVarSize, rnVarType, pd(rsDescription,15), pd( rsUnits,12), sVarVal
	endfor

	// Get and Set  DSVAR  data section descriptors  ( originally from 'lstDS_TEXT' )
	for ( sct = 0; sct < nDataSections; sct += 1 )
		for ( nDSVar = 0;  nDSVar < nDSVars; nDSVar += 1 )
	
			// Get the Data Section var descriptors. 
			GetVarDesc( CFSHnd, nDSVar, DSVAR, rnVarSize, rnVarType, rsUnits, rsDescription )

			//Set the Data Section var descriptors in the same table for the output file. 
			xCFSSetDescriptor( DSVAR,  nDSVar,  rsDescription + "," + StringFromList( rnVarType, klstCFS_DATATYPES ) + "," + rsUnits + "," + num2str( rnVarSize ) )	//  contains Description, Type, Units, Size 

			// The variable value  'sVarVal'  is here actually not needed, it is extracted only for the following debug print line
			sVarVal	= xCFSGetVarVal( CFSHnd, nDSVar, DSVAR, sct+1, ERRLINE )   			
			// printf  "\t\tCfsCopyHeaderFileAndDSDescVars_( DS:%4d/%4d)\t[v:%2d/%2d\tvk:%d  vs:%3d\tvt:%2d] \t%s\t%s\t%s\r", sct, nDataSections, nDSVar, nDSVars, DSVAR, rnVarSize, rnVarType, pd(rsDescription,15), pd( rsUnits,12), sVarVal
		endfor
	endfor
End




static Function		CfsCopyHeaderFileVars_(  CFSHnd, CFSHndOut, LstChanFvarDSvarDS )
	string  	LstChanFvarDSvarDS
	variable	CFSHnd
	variable	CFSHndOut		// valid positive handle or  kNOTFOUND (=-1) when the output file is not to be written
	nvar		gbIsIgor			= root:uf:evo:cfsr:gbIsIgor
	nvar		gFrameDuration		= root:uf:evo:cfsr:gFrameDuration
	variable	nChans 			= str2num( StringFromList( 0, LstChanFvarDSvarDS, ksCFSSEP ) ) 
	variable	nFileVars 			= str2num( StringFromList( 1, LstChanFvarDSvarDS, ksCFSSEP ) ) 
//	variable	nDSVars 			= str2num( StringFromList( 2, LstChanFvarDSvarDS, ksCFSSEP ) ) 
//	variable	nDataSections		= str2num( StringFromList( 3, LstChanFvarDSvarDS, ksCFSSEP ) ) 
 	variable	ch, VarNo, VarKind, DataSection
	variable	rnVarSize, rnVarType
	string		rsUnits, rsDescription, sVarVal = ""
	variable	rnStartOffset, rnPoints,  rYScale, rvVoltageOffset, rvXScale, rvXOffset
	variable	ShowMode	= 0
	string  	sRawScript	= ""				// holds the script to be read from the CFS file  050205

	// print descriptors and values  for  file section  and extract script lines
	VarKind = FILEVAR		
	for ( VarNo = 0; VarNo < nFileVars; VarNo += 1)
		GetVarDesc( CFSHnd, VarNo, FILEVAR, rnVarSize, rnVarType, rsUnits, rsDescription )	// passed parameters are changed!
		sVarVal	= xCFSGetVarVal( CFSHnd, VarNo, FILEVAR, -1 , ShowMode )   			// 031208 was 1 = DataSection, ShowMode )		


		// Simple method: throw away the entire line , do not even try to convert to old style.  Consquence : script is lost
		if ( cmpstr( rsDescription[ 0 ,10 ], "ScriptBlock" ) == 0 )				
			sVarVal	= "// Sorry, but the Script had to be deleted for the sake of 'StimFit' compatibility.\r"
			print sVarVal
		endif

		// Elaborate method:	Put together 'ScriptBlocks', break into 'ScriptLines'  lines, remove white spaces until line is shorter than limit allowed by 'StimFit' (78?), break if impossible, store 'ScripLines' 
		//				Although StimFit allows rnVarSize = 254  it will fail when lines are longer tham the above mentioned limit. 
		// 				Unfortunately there will be more 'ScriptLines'  than there were 'ScriptBlocks'  we have to go back to the start and initialise the descriptors again.......

		xCFSSetVarVal(  CFSHndOut, VarNo, FILEVAR, 0, sVarVal, ERRLINE )				// COPY  to  OUTPUT FILE
		// printf  "\t\tCfsCopyHeaderFileVars_()\t[v:%2d/%2d\tvk:%d  vs:%3d\tvt:%2d] \t%s\t%s\t%s\r", VarNo, nFileVars, VarKind, rnVarSize, rnVarType, pd(rsDescription,15), pd( rsUnits,12), sVarVal


//		if ( cmpstr( rsUnits, "none" ) != 0 )										// skip empty descriptors...
//			// Fill  'sRawScript'  with those lines from the CFS file which contain the script data
//			if ( gbIsIgor )													// 041012  if there is a script stored then extract it
//				if ( cmpstr( rsDescription[ 0 ,9 ], "Scriptline" ) == 0 )
//					sRawScript	+= sVarVal  + "\r"							// 050205	
//				endif
//				if ( cmpstr( rsDescription[ 0 ,10 ], "ScriptBlock" ) == 0 )					// 050206
//					sRawScript	+= sVarVal 		
//// here no effect
////		xCFSSetDescriptor( FILEVAR, i , "ScriptBlock" + num2str( l ) + ",LSTR,," + num2str( MAX_CFS_STRLEN ) ) // usable string length is one shorter
////		xCFSSetDescriptor( FILEVAR, VarNo , "ScriptBlock" + num2str( VarNo - SCRIPTBEGIN_IN_CFSHEADER ) + ",LSTR,," + num2str( MAX_CFS_STRLEN ) ) // usable string length is one shorter
////		   			xCFSSetVarVal(  CFSHndOut, VarNo, FILEVAR, 0, "-----------------------------------------------------------------+++++++++++++++++++++++++++++++++++++++++++++++++++++++********************************************************+++++++++++++++++++++++--------------------------------------------------0123456789", ERRLINE )	
//				endif
//			endif
//		endif

	endfor
	return rnPoints
End


static Function		CfsCopyReadSections_( CFSHndIn, CFSHndOut, LstChanFvarDSvarDS )
	variable	CFSHndIn, CFSHndOut
	string		LstChanFvarDSvarDS
	variable	nChans 			= str2num( StringFromList( 0, LstChanFvarDSvarDS, ksCFSSEP ) ) 
	variable	nDataSections		= str2num( StringFromList( 3, LstChanFvarDSvarDS, ksCFSSEP ) ) 
	
	variable	rnStartOffset, rnPoints,  rYScale, rvVoltageOffset, rvXScale, rvXOffset	
	variable	ch, Section, nBlockBytes, b, nBlocks

	for ( Section = 1; Section <= nDataSections; Section += 1 )
		for ( ch = 0; ch < nChans; ch += 1 )
			
			GetDSChan( CFSHndIn, ch, Section, rnStartOffset, rnPoints, rYScale, rvVoltageOffset, rvXScale, rvxOffset )			// DataSection channel info, passed parameters are changed !
			xCFSSetDSChan( CFSHndOut, ch, 0, rnStartOffset, rnPoints, rYScale, rvVoltageOffset, rvXScale, rvxOffset, ERRLINE )	// COPY  to  OUTPUT FILE, 0 means write into current data section
	
			make /O /W /N=( kCFSMAXBYTE / 2 )	$("root:uf:evo:cfsr:wCFSsmall" + num2str( ch ) )		// construct the wave with unique name..	
			wave  		wCFSsmall 	= 		$("root:uf:evo:cfsr:wCFSsmall" + num2str( ch ) )		// ..but use it here under an alias name 
	
			nBlocks = trunc( ( rnPoints*2 - 1) / kCFSMAXBYTE ) + 1
				
			for ( b = 0; b < nBlocks; b += 1 )												// this loop allows reading more than 64KBytes from one datasection (rnPoints need not be the same for all sections)
				nBlockBytes = ( b == nBlocks - 1 ) ? rnPoints * 2 - b * kCFSMAXBYTE : kCFSMAXBYTE
	
				//  file handle, channel required, DS required, LONG data point in channel at which to start, WORD points wanted, wave to transfer to, LONG bytes allocated for transfer	
				xCFSGetChanData( CFSHndIn, ch, Section, b * kCFSMAXBYTE/2, nBlockBytes/2,  wCFSsmall,  2 * rnPoints, ERRLINE)	//  numbers are WORDs

				//variable 	nStartByteOffset = b * kCFSMAXBYTE	// wrong writes only 1 channel
				variable 	nStartByteOffset = ch * 2 * rnPoints + b * kCFSMAXBYTE 
				xCFSWriteData( CFSHndOut, 0, nStartByteOffset, nBlockBytes, wCFSSmall, ERRLINE ) 						// COPY  to  OUTPUT FILE, 0 means write into current data section, numbers are bytes 
	
			endfor

		endfor		// nChans

		WriteHeader_( CFSHndIn, CFSHndOut, LstChanFvarDSvarDS, Section )														
		FinishDataSection_( CFSHndOut )

	endfor		// sections 

End	


Function		WriteHeader_(  CFSHndIn, CFSHndOut, LstChanFvarDSvarDS, sct )
// Get the File var descriptors. The same table is used for the input and for the output file. This table is Cfs-internal and has no CfsHandle as it must be and has been set up befores 'xCFSCreateFile(output)'
	string  	LstChanFvarDSvarDS
	variable	CFSHndIn, CFSHndOut, sct
	variable	nDSVar, nDSVars	= str2num( StringFromList( 2, LstChanFvarDSvarDS, ksCFSSEP ) ) 
	variable	 nDataSections	= str2num( StringFromList( 3, LstChanFvarDSvarDS, ksCFSSEP ) ) 
	variable	rnVarSize, rnVarType
	string		rsUnits, rsDescription, sVarVal 

	// Get and Set  DSVAR  data section descriptors  ( originally from 'lstDS_TEXT' )
	for ( nDSVar = 0;  nDSVar < nDSVars; nDSVar += 1 )
		// Get the Data Section var descriptors. 
		GetVarDesc( CFSHndIn, nDSVar, DSVAR, rnVarSize, rnVarType, rsUnits, rsDescription )
		sVarVal	= xCFSGetVarVal( CFSHndIn, nDSVar, DSVAR, sct, ERRLINE )   			
		xCFSSetVarVal( CFSHndOut, nDSVar, DSVAR, sct, sVarVal, ERRLINE )		
		// printf  "\t\tWriteHeader_(DS:%3d/%3d)\t[v:%2d/%2d\tvk:%d  vs:%3d\tvt:%2d] \t%s\t%s\t%s\r", sct, nDataSections, nDSVar, nDSVars, DSVAR, rnVarSize, rnVarType, pd(rsDescription,15), pd( rsUnits,12), sVarVal
	endfor
End


Function		FinishDataSection_( CFSHndOut )
	variable	CFSHndOut
	// write complete data section to disk, 0 means append to end of file,  don't care about 16 flags
	xCFSInsertDS( CFSHndOut, 0, kNOFLAGS, ERRLINE ) // 0: write complete data section to disk by appending to end of file, 
End

