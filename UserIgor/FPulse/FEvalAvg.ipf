// 
//  FEvalAvg.ipf	    Averaging  and    Moving Average Data section listbox

#pragma rtGlobals=1		// Use modern global access method.

static  strconstant	lstCOLUMNLABELS	= "MovAvg;"			// the column titles in the LB text wave
static constant		kLB_ADDY		= 18					// additional y pixel for window title, listbox column titles and 2 margins
	

Function		AvgDSDlg( xyOs, nWvKind )
	// Build the DataSectionsPanel
	variable	xyOs, nWvKind 
	variable	SctCnt	= DataSectionCnt_( nWvKind ) 

	variable	c, nCols	= ItemsInList( lstCOLUMNLABELS )

	// Possibly kill an old instance of the DataSectionsPanel and also kill the underlying waves
	string  	sDSPanelNm	= DSPanelNm_( nWvKind )
	DoWindow  /K	$sDSPanelNm
	KillWaves	  /Z	root:uf:evo:lb:wLBTxtA , root:uf:evo:lb:wLBFlagsA, root:uf:evo:lb:wColorsA 

	// Build the DataSectionsPanel . The y size of the listbox and of the panel  are adjusted to the number of data sections (up to maximum screen size) 
	variable	xPos	= 10
	if ( WinType( "de" ) == kPANEL ) 						// Retrieves the main evaluation panel's position from Igor	
		GetWindow     $"de" , wsize						// Only if the main evaluation panel exists retrieve its position from Igor..		
		xPos	= V_right * screenresolution / kIGOR_POINTS72 + 5	// ..and place the current panel just adjacent to the right
	endif
	xPos += xyOs
	variable	xSize		= 80 								// 80 is wide enough for 8 characters, 46 is for 3 characters in the listbox text field.  Must be adjusted when column width or column count changes
	variable	yPos		= 50 + xyOs
	variable	ySizeMax	= GetIgorAppPixelY() -  kY_MISSING_PIXEL_BOT - kY_MISSING_PIXEL_TOP - 85  // -85 leaves some space for the history window
// 051110c
	variable	ySizeNeed	= max( 2, SctCnt ) * kLB_CELLY			// the listbox can be created with 0 or 1 rows, but the minimum height (required for y scrollbar) is the height of a listbox with 2 rows		
	variable	ySize		= min( ySizeNeed , ySizeMax ) 
	NewPanel /W=( xPos, yPos, xPos + xSize + 4 , yPos + ySize + kLB_ADDY ) /K=1 as DSPanelTitle_( nWvKind )	// in pixel
	DoWindow  /C $sDSPanelNm

	// Create the 2D LB text wave	( Rows = data sections, Columns = Both, Avg, Tbl )
	make   	/T 	/N = ( SctCnt, nCols )	   root:uf:evo:lb:wLBTxtA		// the LB text wave
	wave   	/T		wLBTxtA		= root:uf:evo:lb:wLBTxtA

	// Create the 3D LB flag wave. 	Rows x Columns (as above)  x 3  : last index 0 is flags, 1 is fore- or background color, 2 is the remaining color 
	make   /U	/B  /N = ( SctCnt, nCols, 3 )   root:uf:evo:lb:wLBFlagsA		// byte wave is sufficient for up to 254 colors 
	wave   			wLBFlagsA	= root:uf:evo:lb:wLBFlagsA

	make /O	/W /U /N=(128,3) 		   root:uf:evo:lb:wDSColorsA 	// todo 64/128
	wave			wDSColorsA	= root:uf:evo:lb:wDSColorsA 		
	EvalColors( wDSColorsA )								// creates and sets  'root:uf:evo:lb:wColors' . This is the same for  'Org'  and  'Avg'	

	// Link the  indices  of  Foreground  and  Background  colors  to  their name strings which are later used to access the layer where the color is to be set
	variable	planeFore	= 1
	variable	planeBack	= 2
	SetDimLabel 2, planeBack,  $"backColors"	wLBFlagsA
	SetDimLabel 2, planeFore,   $"foreColors"	wLBFlagsA

	// Set the column titles in the LB text wave, take the entries from the fixed string list. 
	for ( c = 0; c < nCols; c += 1 )
		SetDimLabel 1, c, $StringFromList( c, lstCOLUMNLABELS ), wLBTxtA
	endfor

	// Fill the 	listbox column with the name of the moving avg data section : e.g. FirstDS_LastDS_NMovingAveraged
	SetListboxTxtAndColors( wLBTxtA, wLBFlagsA )

	// Build the panel controls 
	ListBox 	  lbDataSectionsA, 	win = $sDSPanelNm, 	pos = { 2, 0 },  size = { xSize, ySize + kLB_ADDY },  frame = 2
	ListBox	  lbDataSectionsA,	win = $sDSPanelNm, 	listWave			= root:uf:evo:lb:wLBTxtA
	ListBox 	  lbDataSectionsA, 	win = $sDSPanelNm, 	selWave 			= root:uf:evo:lb:wLBFlagsA,  editStyle = 1
	ListBox	  lbDataSectionsA, 	win = $sDSPanelNm, 	colorWave		= root:uf:evo:lb:wDSColorsA
	ListBox 	  lbDataSectionsA, 	win = $sDSPanelNm, 	mode 			= kLB_MODE					// normally 8, for debugging 5	
	ListBox 	  lbDataSectionsA, 	win = $sDSPanelNm, 	widths			= { 16 }						// adjust when columns change
	ListBox 	  lbDataSectionsA, 	win = $sDSPanelNm, 	proc 	 			= lbDataSectionsProc
	ListBox 	  lbDataSectionsA, 	win = $sDSPanelNm, 	UserData( nWvKind ) = num2str( nWvKind )

//	SetPrevRowInvalid() 
End


static Function		SetListboxTxtAndColors( wLBTxtA, wLBFlagsA )
	// Fill the 1. listbox column with the name of the moving avg data section : e.g. FirstDS_LastDS_NMovingAveraged
	wave  /T	wLBTxtA
	wave  	wLBFlagsA
	variable	ds, dsCnt	= DimSize( wLBTxtA, 0 )
//	svar		glstMovAvgDataSctB	= root:uf:evo:evl:glstMovAvgDataSctB				
//	svar		glstMovAvgDataSctE	= root:uf:evo:evl:glstMovAvgDataSctE				
//	if ( ItemsInList( glstMovAvgDataSctE ) != dsCnt )
//		InternalError ( "Moving average section count " + num2str( ItemsInList( glstMovAvgDataSctE ) ) + " != " + num2str( dsCnt ) )
//	endif
//	for ( ds = 0; ds < dsCnt; ds += 1 )
//		wLBTxtA[ ds ][ 0 ]	= StringFromList( ds, glstMovAvgDataSctB ) + "_" +  StringFromList( ds, glstMovAvgDataSctE ) 
//	endfor
	for ( ds = 0; ds < dsCnt; ds += 1 )
		wLBTxtA[ ds ][ 0 ]	= DsNm_( ds )
	endfor
End 

//====================================================================================================================================
//  WRITE  AVERAGE   controlled by DSSelect listbox
//  these functions seem to bear quite an amount of overhead but they have 2 distinct advantages:
//	- there are no global variables / strings / waves  concerning  the 'Average'  in the main function  'Analyse'  (which is already quite large), all data are 'hidden'
//	- there is extensive 'Existence' checking of waves and windows so no assumptions have to be made about the current state of the program (e.g. the user should not but may have deleted traces)

Static  Function		WriteAvgHeader( RefNum, sFilePath, ch )
	variable	RefNum, ch					// only for debugging
	string		sFilePath						// only for debugging
	string		sLine		= "      Time    Average        \r"
	// printf  "\t\t\tAddToAvg()  will add header writing into '%s'   :  %s", sFilePath, sLine	// sLine includes CR 
	fprintf 	RefNum,  sLine
End

Static  Function		WriteAvgData( RefNum, wWave, sFilePath, ch )
	variable	RefNum, ch					// ch is only for debugging
	string		sFilePath						// only for debugging
	wave	wWave
	variable	step	=1//100					// todo make step variable, average over data points
	variable	i, pts	= numPnts( wWave )
	variable	dltax	= deltaX( wWave )
	string		sLine
	for ( i = 0; i < pts; i += step )
		sprintf	sLine, "%12.6lf %8.3lf\r", i * dltax, wWave[ i ]	// %12.6lf  is needed to resolve 25 us sample rate
		fprintf 	RefNum, sLine					// Add data
		// printf  "\t\t\tAddToAvg( ch:%d )  will add average (pts:%d, dltax:%g)  writing into '%s'   :  %s", ch, pts, dltax, sFilePath, sLine
	endfor		
End

//------------------------------------------------------------------------------------------------------------------------------------------
//  Wave  and file name management for result average functions

static Function	/S	AvgWvNm( ch )
	variable	ch
	return	ksWAVG + num2str( ch )								// name must be unique for each channel  (ASSUMPTION: 4 chars...)
End

static Function	/S	FoAvgWvNm( ch )
	variable	ch
	return	"root:uf:evo:evl:" + ksWAVG + num2str( ch )				// name must be unique for each channel  (ASSUMPTION: 4 chars...)
End

//Function	/S	MovAvgWvNm( ch )
//	variable	ch
//	return	ksWMOVAVG_ + num2str( ch )					
//End

Function	/S	FoMovAvgWvNm_( ch )
	variable	ch
	return	"root:uf:evo:evl:" + ksWMOVAVG_ + num2str( ch )		
End

//------------------------------------------------------------------------------------------------------------------------------------------

Function		AvgCnt_( ch )
	variable	ch
	wave  /Z	wAvgCnt		= 	root:uf:evo:de:wAvgCnt
	return 	waveExists( wAvgCnt )  ?   wAvgCnt[ ch ]	:  SetAvgCnt_( ch, 0 ) 
End

Function		SetAvgCnt_( ch, cnt )
	variable	ch, cnt
	wave  /Z	wAvgCnt		= 	root:uf:evo:de:wAvgCnt
	if ( ! waveExists( wAvgCnt ) )
		make /N=( kMAXCHANS )	root:uf:evo:de:wAvgCnt
	endif
	wave  	wAvgCnt		= 	root:uf:evo:de:wAvgCnt
	wAvgCnt[ ch ]	= cnt		
	nvar		gAvgKeepCnt0	= root:uf:evo:de:gAvgKeepCnt0000				// Update the SetVariable 'Avg' counter in the main panel . Flaw: only channel 0 is displayed
	gAvgKeepCnt0	= cnt
	return	cnt													// return something for the conditional assignment in 'AvgCnt_()'
End

//------------------------------------------------------------------------------------------------------------------------------------------

// 051027  not yet used
//variable	nMAvgCnt	= NumberOfMovingAverages()					// number of moving averages which will be created . Each will contain  'MovingAvg()'  traces.

//Function		NumberOfMovingAverages()
//// return number of moving averages which will be created . Each will contain  'MovingAvg()'  traces.
//	return	DSSelectedCnt( wFlags, col ) - MovingAvg()					// number of moving averages which will be created . Each will contain  'MovingAvg()'  traces.
//End


Function		AllAverages_( nChannels, XaxisLeft, nAvgRemAdd, nStatePrv, nState, nDataPts, nCurSwp, nSize, AlignVal )
// Computes the 'normal' average ( = 1 resulting average over all  selected data units)   and  also computes the  'moving' average (= multiple resulting averages each over 'MovAvg' data units) 
	variable	nChannels, XaxisLeft, nAvgRemAdd, nStatePrv, nState, nDataPts, nCurSwp, nSize, AlignVal 
	variable	ch
	
	string  	sFoDrawDataNm

	// The  SIMPLE  (non-moving)  AVERAGE  (removing from average is also possible)
	// 050603 Scale the averaged wave : In    'Single'    mode the time scale displays the true time values of the currently viewed data unit. Position the averaged trace at the same time.
	// 050603 Scale the averaged wave : In  'Stacked'  mode all data units and the time scale start at time 0.  Position the averaged trace at the same time 0.
	variable	nSimpleAvgRemAdd	=   nAvgRemAdd == cAVG_ADD_START_MVG   ?   cAVG_ADD : nAvgRemAdd 	// Do  SIMPLE AVERAGING (even if  'InitStartMovingAverage'  is  passed, ignore the MovAvg part of the command )
	for ( ch = 0; ch < nChannels; ch += 1 )
		sFoDrawDataNm  		= FoOrgWvNm( ch, nCurSwp, nSize )			// = "root:uf:evo:cfsr:" + sDrawDataNm
		wave   	wDrawData	=  $sFoDrawDataNm
		DSDisplayAvg( ch, XaxisLeft )
		DSAddOrRemoveAvg_( nSimpleAvgRemAdd, nStatePrv, nState, ch, wDrawData, nDataPts )	// SIMPLE AVERAGING or removing (even if  'InitStartMovingAverage'  is  passed.......)
	endfor

	// The  MOVING  AVERAGE
	string  	sTxt			= "DSMovAvg"
	string  	sFoMovAvgNm
	variable	nm, nMovAvg	= MovingAvg()										// number of traces which are to be averaged in 1 average
	
	// Do the  'Moving average'  initialisation
	if ( nAvgRemAdd == cAVG_ADD_START_MVG  ||  nAvgRemAdd  ==  cAVG_ADD )
		variable	bDoInit, nCurrRingIdxRem, nCurrRingIdxAdd
		if ( nAvgRemAdd == cAVG_ADD_START_MVG )
			sTxt += "\tInit"													// 
			bDoInit		= TRUE
			nAvgRemAdd	= cAVG_ADD										// after we have extracted the initialisation condition we process (=add) the trace normally 
			variable	/G	root:uf:evo:evl:gnAvgIdx	= 0							// the index of the moving average. Each will contain  'nMovAvg'  traces. USED LIKE STATIC.
			variable	/G	root:uf:evo:evl:gMovAvgDataSections = 0					// will be less than the original data sections as the (not entirely averaged) border data sections are not created
			// Create the 2 string lists holding the first and the last DS index and the count of original data sections averaged into each moving average data section. Flaw: the information is only approximate e.g. '0 1  3 4'  and  '0 1 2 4' will both give '0_4_4'
			string  	/G	root:uf:evo:evl:glstMovAvgDataSctB	 = ""					// e.g. '0_4;1_4;4_4;5_4;6_4;...'   for  MovAvg=4  and selected data units 0 1 4 5 6
			string  	/G	root:uf:evo:evl:glstMovAvgDataSctE	 = ""					// e.g. '0_4;1_4;4_4;5_4;6_4;...'   for  MovAvg=4  and selected data units 0 1 4 5 6
			make /O /N=( nChannels, nDataPts, nMovAvg ) 	root:uf:evo:evl:wRing = 0		// create the ring wave .  Limitation: the  'nDataPts'  received here during initialisation will be valid for all averaging. No shrinking or growing is handled.
			make /O /N=( nChannels, nDataPts )   		root:uf:evo:evl:wAver = 0		// create the average wave . 
			for ( ch = 0; ch < nChannels; ch += 1 )
				sFoMovAvgNm	= FoMovAvgWvNm_( ch )
				make /O /N= 0 	$sFoMovAvgNm								// create the catenated moving average result wave which will be further accessed and processed through the 'MovAvg Data sections Listbox'
			endfor

			// 060213  Aligning averages

			variable	/G	root:uf:evo:evl:gAvgAlignNoShift = AlignVal					// store the latency of the first averaged data section as the 'zero' value with which all following latencies will be compared
			 printf "\t\tAllAverages()  Init  Aligning averages :%g \r", AlignVal
			
		endif

		// 060213  Aligning averages
		nvar		gAvgAlignNoShift	= root:uf:evo:evl:gAvgAlignNoShift				// store the latency of the first averaged data section as the 'zero' value with which all following latencies will be compared

		wave	wRing			= root:uf:evo:evl:wRing
		wave	wAver			= root:uf:evo:evl:wAver
		nvar		gnAvgIdx			= root:uf:evo:evl:gnAvgIdx
		nvar		gnMovAvgDataSects	= root:uf:evo:evl:gMovAvgDataSections
		svar		glstMovAvgDataSctB	= root:uf:evo:evl:glstMovAvgDataSctB				
		svar		glstMovAvgDataSctE	= root:uf:evo:evl:glstMovAvgDataSctE				

		// Build the 2 string lists holding the first and the last DS index and the count of original data sections averaged into each moving average data section. Flaw: the information is only approximate e.g. '0 1  3 4'  and  '0 1 2 4' will both give '0_4_4'
		glstMovAvgDataSctB +=  num2str( nCurSwp ) + ";"							// '0;1;4;5;7;8;...'   			for  MovAvg=4  and selected data units 0 1 4 5 6 7 8 9 11 15..
		if ( gnAvgIdx >= nMovAvg-1 )											// the first moving average has now been collected
			glstMovAvgDataSctE +=  num2str( nCurSwp ) + "_" + num2str( nMovAvg ) + ";"	// '5_4;7_4;8_4;9_4;11_4;15_4.' for  MovAvg=4  and selected data units 0 1 4 5 6 7 8 9 11 15...
		endif
		for ( ch = 0; ch < nChannels; ch += 1 )
			
			sFoMovAvgNm			= FoMovAvgWvNm_( ch )
			wave  	wCatMovAvg	= $sFoMovAvgNm				
	
			variable	nAdded		= min( gnAvgIdx+1, nMovAvg ) 						// average, don't add:  divide by the number of traces added so far e.g.  1,2,3,4,4,4,4,4,4,4...
			sFoDrawDataNm  		= FoOrgWvNm( ch, nCurSwp, nSize )					// = "root:uf:evo:cfsr:" + sDrawDataNm
			wave   	wDrawData	   =  $sFoDrawDataNm
	
			nCurrRingIdxRem	= gnAvgIdx >= nMovAvg  ?  mod( gnAvgIdx, nMovAvg ) : nan
			if ( numType( nCurrRingIdxRem ) != kNUMTYPE_NAN )						// removing starts delayed only after  'nMovAvg'  have been collected
				wAver[ ch ] =  ( wAver[ ch ][ q ] * ( nAdded - 1 ) - wRing[ ch ][ q ][ nCurrRingIdxRem ] ) / nAdded	// remove	wRing[ nCurrRingIdxRem ] from the moving average  !!!! cave
			endif
	
			nCurrRingIdxAdd	= mod( gnAvgIdx, nMovAvg )
			
			// the following line is not entirely valid this early, see below 
			// printf "\t\t%s\tch:%2d\t%s\tIdx:%4d\tRingIdxRem:%.0g\tRingIdxAdd:%4d\tnDaPts:\t%8d\t%s\tpt:\t%8d\t  \r", pd(sTxt,21), ch, pd(sFoDrawDataNm,26), gnAvgIdx, nCurrRingIdxRem, nCurrRingIdxAdd, nDataPts, sFoMovAvgNm, numpnts( $sFoMovAvgNm )
	
			variable n

			// 060213  Aligning averages: The shifted border points are ignored. On the underflowing side nothing (=0) is added, on the overflowing side Igor fills up with the value of the last legal point. Could be improved.
			variable xShiftPts	=   numType( AlignVal ) == kNUMTYPE_NAN  ?  0  :   Round( ( AlignVal - gAvgAlignNoShift ) * 1e6 / CfsSmpInt())
			// printf "\t\t\t\tAverage alignment  \tch:%2d/%2d\tsw:\t%3d\tLatency of first DS:\t%9.7lf\ts \tLatency of this DS:\t%9.7lf\ts \tDiff:\t%7.2lf\tus\tShift:\t%3d SI\t[SI:\t%5d us]\t \r", ch, nChannels, nCurSwp, gAvgAlignNoShift, AlignVal, (AlignVal - gAvgAlignNoShift)*1e6, xShiftPts, CfsSmpInt()
			for ( n = 0; n < nDataPts; n += 1 )											// a loop is needed here as wave arithmetics cannot convert from 3 to 1 dimension. Does NOT work : wRing[ ch ][ ][ nCurrRingIdxAdd ] = wDrawData[ p ]
				wRing[ ch ][ n ][ nCurrRingIdxAdd ]	= wDrawData[ n + xShiftPts ]			// OK : update	wRing[ nCurrRingIdxAdd ]
			endfor

	
			wAver[ ch ][]  		=   ( wAver[ ch ][ q ] * ( nAdded - 1 ) + wRing[ ch ][ q ][ nCurrRingIdxAdd ] ) / nAdded	// add	wRing[ nCurrRingIdxAdd ] to  the moving average  !!!! cave
		
	//		string  	sMovAvgNm	= MovAvgWvNm( ch )
	//		string  	sFoMovAvgNm	= FoMovAvgWvNm_( ch )
	//		wave  /Z	wCatMovAvg	= $sFoMovAvgNm				// will  NOT exist from the beginning
	//
	//		if ( gnAvgIdx == nMovAvg-1 )										// the first moving average has now been collected
	//			sTxt += "\tCreate"
	//			make /O /N= 0   		$sFoMovAvgNm		//wCatMovAvg//$sFoMovAvgNm						// create the catenated moving average result wave which will be further accessed and processed through the 'MovAvg Data sections Listbox'
	//			wave  /Z	wCatMovAvg	= $sFoMovAvgNm				// will  NOT exist from the beginning
	//		endif
			if ( gnAvgIdx >= nMovAvg-1 )										// the first moving average has now been collected
				sTxt += "\tAppend"
				variable	nMovAvgPts	= numPnts( wCatMovAvg ) //$sFoMovAvgNm )
				redimension /N=( nMovAvgPts + nDataPts )  wCatMovAvg //$sFoMovAvgNm  
				wCatMovAvg[nMovAvgPts, nMovAvgPts  + nDataPts - 1] = wAver[ ch ][ p - nMovAvgPts ]			//  1-dim  <--  2-dim wave assignment (extract row=ch)
				gnMovAvgDataSects += 1
			endif
	
//			if ( ch == 1 )
//				WaveStats /Q wDrawData
//				variable	nDDPts	= V_npnts
//				variable	nDDAvg	= V_avg
//				make /O /N=( nDDPts ) 	root:uf:evo:lb:wAver1Ch = 0		// create the average wave . 
//				wave	wAver1Ch	= root:uf:evo:lb:wAver1Ch
//				wAver1Ch			= wAver[ ch ][ p ]			//  1-dim  <--  2-dim wave assignment (extract row=ch)
//				WaveStats /Q wAver1Ch	
//				variable	nAvAvg	= V_avg
//				//if ( gnAvgIdx < 8 )
//	//				display /K=1 wAver1Ch					// makes it very slow as many graphs are accumulated	
//					printf "\t\t%s\tch:%2d\t%s\tIdx:%4d\tRingIdxRem:%.0g\tRingIdxAdd:%4d\tnDaPts:\t%8d\tnDDAvg:\t%8g\tnAvAvg:\t%8g\t%s\tpt:\t%8d\t  \r", pd(sTxt,21), ch, pd(sFoDrawDataNm,26), gnAvgIdx, nCurrRingIdxRem, nCurrRingIdxAdd, nDataPts, nDDAvg, nAvAvg, sFoMovAvgNm, numpnts( $sFoMovAvgNm )
//				// endif
//			endif
	
		endfor
	
		// printf "\t\t%s\tIdx:%4d\tRingIdxRem:%.0g\tRingIdxAdd:%4d\tCurSwp:\t%8d\t    \r", pd(sTxt,22), gnAvgIdx, nCurrRingIdxRem, nCurrRingIdxAdd, nCurSwp
		gnAvgIdx+=1
//		gnMovAvgDataSects /= nChannels
		// display wCatMovAvg, $FoMovAvgWvNm_( 0 )
	endif
End

Function		MovAvgDataSections_()
	nvar		gMovAvgDataSections	= root:uf:evo:evl:gMovAvgDataSections
	return	gMovAvgDataSections / CfsChannels_()
End
	
  Function		DSAddOrRemoveAvg_( nAvgRemAdd, nStatePrv, nState, ch, wData, nDataPts )
// Depending on the flag 'nAvgRemAdd'  and on the current and the previous state  addwave 'wData'  to  (or remove it from) average waves.  
// The average waves are different for each channel, they are distinct by the channel name postfix. The waves are automatically created if they do not exist.
// The average waves are saved or cleared by user commands elsewhere.
// If the channels were independent on/off-switchable (They are NOT in the current version) and if the user switched channels on/off during averaging the same averaging path may result in different indices from channel to channel
// writing averages could be realized somewhat simpler (header and data could be written in 1 step) but the framework used is here is more general and can be used similarly for 'AddDirectlyToFile()' 
	variable	nAvgRemAdd, nStatePrv, nState, ch, nDataPts
	wave  /Z	wData									// /Z a bit ugly: when only viewing but not averaging we will be here with an invalid 'wData' which will not be needed below
	string  	sWndNm

	// Tricky condition : 		add only if this trace has not been averaged already			OR  		remove only if this trace has been averaged already 		 (can perhaps be simplified)
	if ( ( ( nState & kST_AVG )  &&  ! ( nStatePrv & kST_AVG )  &&  nAvgRemAdd ==  cAVG_ADD  )   ||  ( ! ( nState & kST_AVG )  &&    ( nStatePrv & kST_AVG ) && nAvgRemAdd ==  cAVG_REMOVE ) ) 

		string		sAvgWvNm	= AvgWvNm( ch )
		string		sFoAvgWvNm	= FoAvgWvNm( ch )
		// Update the average wave
		wave  /Z	wAvg = $sFoAvgWvNm			
		if ( ! waveExists ( wAvg ) )									// trace may not (yet) exist or the user may have deleted it
			make  /O /N=(nDataPts)	$sFoAvgWvNm					// does not copy the wave scaling
			SetScale /P X, 0, deltax( wData ), ksXUNIT, $sFoAvgWvNm	// copy deltaX of the avg wave from the original wave but let the avg wave (in contrast to the original wave) start at 0  (cannot use 'duplicate' for this reason)	
			wave  	wAvg 	= 	$sFoAvgWvNm			
			wAvg	= 0
			string  /G	root:uf:evo:lstDataLen	= ""					// For shrinking wAvg again after the longest traces have been removed from wAvg...
		endif

		// To avoid Igor's handling of 'mismatched waves' (Igor will pad the shorter wave with the last value rather than with 0 which is wrong and confusing) we pad the shorter wave 'manually' with 0.
		// We also want to avoid long computing times and want to avoid filling the window with a zero-value-avg-trace.
		// Shrink wAvg again after the longest traces have been removed from wAvg (=all traces shorter than wAvg = wAvg  ending with zero unfortunately including rounding errors, so we cannot rely on this condition) 
		// Better approach (taken) : store length of each added data trace in string list and remove length from string list if data traces is removed from average, then truncate avg at maximum length found in list. 
		svar	/Z lstDataLen	= root:uf:evo:lstDataLen					// The list contains the lengths of all individual added traces 
		if ( ! svar_exists( lstDataLen ) )						
			string  /G	root:uf:evo:lstDataLen	= ""					// create list if it does not exist
		endif
		svar	lstDataLen	= root:uf:evo:lstDataLen
		variable	i
		if ( nAvgRemAdd ==  cAVG_ADD )
			lstDataLen	= AddListItem( num2str( nDataPts ), lstDataLen )		// no matter which trace index append length at the beginning of the list (end would work the same)
		else
			i = WhichListItem( num2str( nDataPts ), lstDataLen )			// the first length item having the desired length 'nDataPts' is replaced. This will usually not be the item whose trace is removed from the avg but this is OK
			lstDataLen	= RemoveListItem( i, lstDataLen )
		endif
		variable	nMaxLen= 0, nItems	= ItemsInList( lstDataLen )			// which is now the longest trace length?
		for ( i = 0; i < nItems; i += 1 )								
			nMaxLen	= max( str2num( StringFromList( i, lstDataLen ) ) , nMaxLen )
		endfor

		// printf "\t\t\tDSAddOrRemoveAvg\t%s\tch:%d\t%s\tnAvgd:%3d\tPts:%4d\tst:%2d\t%s\tdapts:%6d\t  avgpts:%6d\t->%6d\tlft:\t%6.2lf\tdlt:\t%6.2lf\t%d '%s' \r", pd(StringFromList( nAvgRemAdd, lstREM_ADD_),6), ch, sAvgWvNm, AvgCnt(ch), numPnts( wData ), nState, "              ", nDataPts, numPnts(wAvg), nMaxLen, leftx( wAvg), deltaX( wAvg ) , nItems, lstDataLen

		if ( numPnts( wAvg )  != nMaxLen )
			Redimension  	/N=(nMaxLen)	wAvg					// Igor sets all points behind the redimensioned range to 0, which is what we want. 
		endif													//
		duplicate	/O 	wData		  wDataLong					// this works although Igor normally requires that $STRING SYNTAX  is used. (see: duplicate in user functions in loops...)
		if ( nMaxLen > nDataPts )
			Redimension /N=(nMaxLen) wDataLong					// Igor sets all points behind the redimensioned range to 0, which is what we want.
		endif
		variable	nAddOrRemove	= nAvgRemAdd * 2 - 3				// Remove: 1 > -1 , Add: 2 > 1 
		SetAvgCnt_( ch, AvgCnt_( ch ) + nAddOrRemove )
		// The averaging works correctly only for segments of the same length, otherwise computations are OK but results look confusing
		//wAvg	= AvgCnt_( ch )  == 0  ?  		0  	  	:  wAvg  +  ( wDataLong - wAvg ) * nAddOrRemove / AvgCnt_( ch )  	// elegant short-hand notation (but potentially obscuring errors as wAvg is forcefully set to 0 
		wAvg	= AvgCnt_( ch )  == 0  ?  wAvg - wDataLong	:  wAvg  +  ( wDataLong - wAvg ) * nAddOrRemove / AvgCnt_( ch )  	// version to detect programming errors. Drawback : rounding errors also propagate.

		// The state of the various Average controls depends on whether there is an averaged trace. Disable the controls if there is none.
		string  	sWin = "de" 		// should be strconstant ksPN_DE,  but then to gain an advantage ALL control names in this panel must be converted to e.g. "root_uf_evo_" + ksPN_DE + "de_buEraseAvg0000" which would immensely blow up the code
		if ( AvgCnt_( ch ) == 0 )
			string  	sWNm	= EvalWndNm( ch )
			if ( WinType( sWNm ) == kGRAPH )						// the user may have killed the graph window
				RemoveFromGraph   /Z /W=$sWNm $sAvgWvNm		// /Z : do not generate an error if the avg trace is missing as the user may have removed the trace from the graph 
			endif

			// If all averages are subtracted and if there is no longer an average we must kill the avg wave (although its value is already 0) because Igor keeps the length of the wave which might confict with the next avg having a different length. 
			KillWaves	wAvg									// now that the trace is no longer in the graph we can finally delete the average wave

			EnableButton( 	  sWin, "root_uf_evo_de_buEraseAvg0000", kDISABLE )
			EnableButton( 	  sWin, "root_uf_evo_de_buSaveAvg0000",  kDISABLE )
			EnableCheckbox(sWin, "root_uf_evo_de_gbDispAvg0000",   kDISABLE )	
		else
			EnableButton( 	  sWin, "root_uf_evo_de_buEraseAvg0000", kENABLE )
			EnableButton( 	  sWin, "root_uf_evo_de_buSaveAvg0000",  kENABLE )
			EnableCheckbox(sWin, "root_uf_evo_de_gbDispAvg0000",   kENABLE )	
		endif
		// printf "\t\t\tDSAddOrRemoveAvg...done...\tch:%d ...\r", ch
	endif


End

Function	/S	DsNm_( ds )
	variable	ds
	svar		glstMovAvgDataSctB	= root:uf:evo:evl:glstMovAvgDataSctB				
	svar		glstMovAvgDataSctE	= root:uf:evo:evl:glstMovAvgDataSctE				
//	if ( ItemsInList( glstMovAvgDataSctE ) != dsCnt )
//		InternalError ( "Moving average section count " + num2str( ItemsInList( glstMovAvgDataSctE ) ) + " != " + num2str( dsCnt ) )
//	endif
	return	StringFromList( ds, glstMovAvgDataSctB ) + "_" +  StringFromList( ds, glstMovAvgDataSctE ) 
End


//static  Function		DSAddOrRemoveAvg_( nAvgRemAdd, nStatePrv, nState, ch, wData, nDataPts )
//// Depending on the flag 'nAvgRemAdd'  and on the current and the previous state  addwave 'wData'  to  (or remove it from) average waves.  
//// The average waves are different for each channel, they are distinct by the channel name postfix. The waves are automatically created if they do not exist.
//// The average waves are saved or cleared by user commands elsewhere.
//// If the channels were independent on/off-switchable (They are NOT in the current version) and if the user switched channels on/off during averaging the same averaging path may result in different indices from channel to channel
//// writing averages could be realized somewhat simpler (header and data could be written in 1 step) but the framework used is here is more general and can be used similarly for 'AddDirectlyToFile()' 
//	variable	nAvgRemAdd, nStatePrv, nState, ch, nDataPts
//	wave  /Z	wData									// /Z a bit ugly: when only viewing but not averaging we will be here with an invalid 'wData' which will not be needed below
//	string  	sWndNm
//
//	// Tricky condition : 		add only if this trace has not been averaged already			OR  		remove only if this trace has been averaged already 		 (can perhaps be simplified)
//	if ( ( ( nState & kST_AVG )  &&  ! ( nStatePrv & kST_AVG )  &&  nAvgRemAdd ==  cAVG_ADD  )   ||  ( ! ( nState & kST_AVG )  &&    ( nStatePrv & kST_AVG ) && nAvgRemAdd ==  cAVG_REMOVE  ) ) 
//
//		string		sAvgWvNm	= AvgWvNm( ch )
//		string		sFoAvgWvNm	= FoAvgWvNm( ch )
//		// Update the average wave
//		wave  /Z	wAvg = $sFoAvgWvNm			
//		if ( ! waveExists ( wAvg ) )									// trace may not (yet) exist or the user may have deleted it
//			make  /O /N=(nDataPts)	$sFoAvgWvNm					// does not copy the wave scaling
//			SetScale /P X, 0, deltax( wData ), ksXUNIT, $sFoAvgWvNm	// copy deltaX of the avg wave from the original wave but let the avg wave (in contrast to the original wave) start at 0  (cannot use 'duplicate' for this reason)	
//			wave  	wAvg 	= 	$sFoAvgWvNm			
//			wAvg	= 0
//			string  /G	root:uf:evo:lstDataLen	= ""					// For shrinking wAvg again after the longest traces have been removed from wAvg...
//		endif
//
//		// To avoid Igor's handling of 'mismatched waves' (Igor will pad the shorter wave with the last value rather than with 0 which is wrong and confusing) we pad the shorter wave 'manually' with 0.
//		// We also want to avoid long computing times and want to avoid filling the window with a zero-value-avg-trace.
//		// Shrink wAvg again after the longest traces have been removed from wAvg (=all traces shorter than wAvg = wAvg  ending with zero unfortunately including rounding errors, so we cannot rely on this condition) 
//		// Better approach (taken) : store length of each added data trace in string list and remove length from string list if data traces is removed from average, then truncate avg at maximum length found in list. 
//		svar	/Z lstDataLen	= root:uf:evo:lstDataLen					// The list contains the lengths of all individual added traces 
//		if ( ! svar_exists( lstDataLen ) )						
//			string  /G	root:uf:evo:lstDataLen	= ""					// create list if it does not exist
//		endif
//		svar	lstDataLen	= root:uf:evo:lstDataLen
//		variable	i
//		if ( nAvgRemAdd ==  cAVG_ADD )
//			lstDataLen	= AddListItem( num2str( nDataPts ), lstDataLen )		// no matter which trace index append length at the beginning of the list (end would work the same)
//		else
//			i = WhichListItem( num2str( nDataPts ), lstDataLen )			// the first length item having the desired length 'nDataPts' is replaced. This will usually not be the item whose trace is removed from the avg but this is OK
//			lstDataLen	= RemoveListItem( i, lstDataLen )
//		endif
//		variable	nMaxLen= 0, nItems	= ItemsInList( lstDataLen )			// which is now the longest trace length?
//		for ( i = 0; i < nItems; i += 1 )								
//			nMaxLen	= max( str2num( StringFromList( i, lstDataLen ) ) , nMaxLen )
//		endfor
//
//		// printf "\t\t\tDSAddOrRemoveAvg\t%s\tch:%d\t%s\tnAvgd:%3d\tPts:%4d\tst:%2d\t%s\tdapts:%6d\t  avgpts:%6d\t->%6d\tlft:\t%6.2lf\tdlt:\t%6.2lf\t%d '%s' \r", pd(StringFromList( nAvgRemAdd, lstREM_ADD_),6), ch, sAvgWvNm, AvgCnt(ch), numPnts( wData ), nState, "              ", nDataPts, numPnts(wAvg), nMaxLen, leftx( wAvg), deltaX( wAvg ) , nItems, lstDataLen
//
//		if ( numPnts( wAvg )  != nMaxLen )
//			Redimension  	/N=(nMaxLen)	wAvg					// Igor sets all points behind the redimensioned range to 0, which is what we want. 
//		endif													//
//		duplicate	/O 	wData		  wDataLong					// this works although Igor normally requires that $STRING SYNTAX  is used. (see: duplicate in user functions in loops...)
//		if ( nMaxLen > nDataPts )
//			Redimension /N=(nMaxLen) wDataLong					// Igor sets all points behind the redimensioned range to 0, which is what we want.
//		endif
//		variable	nAddOrRemove	= nAvgRemAdd * 2 - 3				// Remove: 1 > -1 , Add: 2 > 1 
//		SetAvgCnt_( ch, AvgCnt_( ch ) + nAddOrRemove )
//		// The averaging works correctly only for segments of the same length, otherwise computations are OK but results look confusing
//		//wAvg	= AvgCnt_( ch )  == 0  ?  		0  	  	:  wAvg  +  ( wDataLong - wAvg ) * nAddOrRemove / AvgCnt_( ch )  	// elegant short-hand notation (but potentially obscuring errors as wAvg is forcefully set to 0 
//		wAvg	= AvgCnt_( ch )  == 0  ?  wAvg - wDataLong	:  wAvg  +  ( wDataLong - wAvg ) * nAddOrRemove / AvgCnt_( ch )  	// version to detect programming errors. Drawback : rounding errors also propagate.
//
//		// The state of the various Average controls depends on whether there is an averaged trace. Disable the controls if there is none.
//		string  	sWin = "de" 		// should be strconstant ksPN_DE,  but then to gain an advantage ALL control names in this panel must be converted to e.g. "root_uf_evo_" + ksPN_DE + "de_buEraseAvg0000" which would immensely blow up the code
//		if ( AvgCnt_( ch ) == 0 )
//			string  	sWNm	= EvalWndNm( ch )
//			if ( WinType( sWNm ) == kGRAPH )						// the user may have killed the graph window
//				RemoveFromGraph   /Z /W=$sWNm $sAvgWvNm		// /Z : do not generate an error if the avg trace is missing as the user may have removed the trace from the graph 
//			endif
//
//			// If all averages are subtracted and if there is no longer an average we must kill the avg wave (although its value is already 0) because Igor keeps the length of the wave which might confict with the next avg having a different length. 
//			KillWaves	wAvg									// now that the trace is no longer in the graph we can finally delete the average wave
//
//			EnableButton( 	  sWin, "root_uf_evo_de_buEraseAvg0000", kDISABLE )
//			EnableButton( 	  sWin, "root_uf_evo_de_buSaveAvg0000",  kDISABLE )
//			EnableCheckbox(sWin, "root_uf_evo_de_gbDispAvg0000",   kDISABLE )	
//		else
//			EnableButton( 	  sWin, "root_uf_evo_de_buEraseAvg0000", kENABLE )
//			EnableButton( 	  sWin, "root_uf_evo_de_buSaveAvg0000",  kENABLE )
//			EnableCheckbox(sWin, "root_uf_evo_de_gbDispAvg0000",   kENABLE )	
//		endif
//		// printf "\t\t\tDSAddOrRemoveAvg...done...\tch:%d ...\r", ch
//	endif
//End


Function		DSDisplayAvgAllChans()
	variable	nChannels	= CfsChannels_()
	variable	ch
	for ( ch = 0; ch < nChannels; ch += 1 ) 
		variable	XaxisLeft	= 0
		DSDisplayAvg( ch, XaxisLeft )
	endfor
End


static Function		DSDisplayAvg( ch, XaxisLeft )
	variable	ch, XaxisLeft
	string  	sWNm = EvalWndNm( ch )
	nvar		gbDispAverage	= root:uf:evo:de:gbDispAvg0000
	string		sTNL, sAvgNm												// name of trace without folder
	//string  	sTxt	= "no  wave "
	wave  /Z	wAvg		= $FoAvgWvNm( ch )
	if ( waveExists ( wAvg ) )												// the user may have deleted the wave 
		if ( WinType( sWNm ) == kGRAPH )									// the user may have killed the graph window
			sTNL	= TraceNameList( sWNm, ";", 1 )						// the user may have removed the trace from the graph 
		  	sAvgNm	= AvgWvNm( ch )
			if ( WhichListItem( sAvgNm, sTNL, ";" )  == kNOTFOUND )				// only if  avg wave is not in graph then append it 
				AppendToGraph  /W=$sWNm 	wAvg						// wAvg does contain folder ,  sAvgNm does NOT contain folder.
			endif
			ModifyGraph /W=$sWNm  offset( $sAvgNm ) = { XaxisLeft, 0 }			// Shift the average trace so that it starts always together with the active data trace
			if ( gbDispAverage )
				ModifyGraph   /W=$sWNm  hideTrace( $sAvgNm ) = 0				// redisplay the possibly hidden trace
				ModifyGraph   /W=$sWNm  rgb( $sAvgNm ) = ( 43000, 33000, 0 ) 	// brown
				// sTxt	= "SHOW avg"
				// Put the average trace on top of the other traces so that it is always visible. This is especially important as it usually is thinner as the original traces due to less noise.
				sTNL	= RemoveFromList( sAvgNm, sTNL )
				variable	nt, nTraces	= ItemsInList( sTNL )
				for ( nt = 0; nt < nTraces; nt += 1 )
					ReorderTraces /W=$sWNm $sAvgNm,  { $StringFromList( nt, sTNL ) }	// todo: also cursors, evaluated data points and fits are ordered behind the average, this is not really required.
				endfor
					
			else
				ModifyGraph   /W=$sWNm  hideTrace( $sAvgNm ) = 1				// hide the trace 
				//ModifyGraph     /W=$sWNm  rgb( $sAvgNm ) = ( kBGCOLOR_, kBGCOLOR_, kBGCOLOR_)	// background color = invisible  (or nearly invisible for debugging)
				// sTxt	= "HIDE  avg"
			endif
		// printf "\t\t\tDSDisplayAvgAllChans( \tch:%d ) \t%s\t%s\t(exists) in W\t%s\t(exists)\tnAvgd:%3d\tPts:%4d\t \r", ch, sTxt, sAvgNm, sWNm, AvgCnt_(), numPnts( wAvg)
		endif
	endif
End


 Function	DSEraseAvgAllChans_()
// Remove all  'average-marked' (usually green or - in conjuntion with Tbl - cyan() data units from the data selection listbox  and erase the average wave for all channels.
	wave	wFlags		= root:uf:evo:lb:wLBFlagsA
	string  	sPlaneNm		= "BackColors" 
	variable	col, pl		= FindDimLabel( wFlags, 2, sPlaneNm )
	
	for ( col = 0; col <= kCOLM_PON; col += 1 )
		DSClearColumn( wFlags, col, pl, kST_AVG )								//					Set all data sections of the entire column to unaveraged state
	endfor

	// Emergeny , should never happen...
	variable	ch, nChannels	= CfsChannels_()
	for ( ch = 0; ch < nChannels; ch += 1 ) 							
		if ( AvgCnt_( ch ) )
			InternalError( "DSEraseAvgAllChans() should have erased all traces but there are "+ num2str( AvgCnt_( ch ) ) + " traces left in ch " + num2str( ch )  )
			string		sWNm	= EvalWndNm( ch )
			if ( WinType( sWNm ) == kGRAPH )						// the user may have killed the graph window
				RemoveFromGraph /Z /W=$sWNm  $AvgWvNm( ch )		// trace name contains no folder
				KillWaves   /Z	$FoAvgWvNm( ch )					// wave name contains folder
			endif
			SetAvgCnt_( ch, 0 )
		endif
	endfor
End


Function	DSSaveAvgAllChans_()
	svar		gsAvgNm		= root:uf:evo:de:gsAvgNm0000	
	string  	sFilePath		= ""
	variable	ch, nChannels	= CfsChannels_()
	for ( ch = 0; ch < nChannels; ch += 1 ) 
		wave  /Z	wAvg	= $FoAvgWvNm( ch )
		if ( ! waveExists ( wAvg ) )											// trace may not (yet) exist or the user may have deleted it
			Alert( kERR_LESS_IMPORTANT, "No averaged traces." )
			printf "\t\tDSSaveAvgAllChans(): No averaged traces.   '%s' does not exist \r", FoAvgWvNm( ch )
		else
			sFilePath		= gsAvgNm + ChannelSpecifier_( ch ) + "." + ksAVGEXT_	
			waveStats	/Q wAvg
			printf "\t\tDSSaveAvgAllChans(): Ch:%d   %s\t#Avg:%2d\tAvg:\t%g\tPts:\t%g\r", ch, sFilePath, AvgCnt_( ch ), mean( wAvg ), numPnts( wAvg )
			DSWriteAverage( ch, wAvg, sFilePath )							// Update  ( or create )  the average  file  by writing the  average wave data
		endif
	endfor
	gsAvgNm	= ConstructNextResultFileNmA_( gsAvgNm, ksAVGEXT_ )		// search next free avg file and display it in SetVariable input field
	// printf "\tDSSaveAvgAllChans() searched and displays next free file where the next AVG data will be written :\t%s  \r", gsAvgNm
End

static Function	DSWriteAverage( ch, wAvg, sFilePath )
// Update  ( or create )  the average  file  by writing the  average wave data
	variable	ch
	wave	wAvg
	string		sFilePath
	variable	nRefNum
	Open  	nRefNum  as sFilePath					// Open file  by  creating it
	if ( nRefNum ) 									// ...a new average always overwrites the whole file, it never appends
		WriteAvgHeader( nRefNum, sFilePath, ch )
		WriteAvgData( nRefNum, wAvg, sFilePath, ch )
		Close	nRefNum
	endif
End

