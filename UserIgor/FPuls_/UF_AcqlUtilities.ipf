//
// UF_Utilities.Ipf   :	Routines for	Filtering data
//							Cutting out and storing episodes
//							AXIS  and  SCALEBARS

#include <Axis Utilities>

#pragma rtGlobals=1								// Use modern global access method.
#pragma version=2

// 060504  todo   in EVAL   GaussFFT does not work  ( scaling ?? SclFct, BegPoint??? )

// 070228 make independent of Eval/Acq
static strconstant	ksACQ			= "acq"			// the subfolder for the  'acquisition'  variables. Do not change as action proc names (and globals in panels) depend on it.
static strconstant	ksEVAL_			= "eva:"			// the subfolder for the  'evaluation'  variables. Do not change as action proc names rely on it. At most 3 letters or else control action proc names will be too long)
static strconstant	ksEVAL			= "eva"


//=================================================================================================================================================================
//  DATA  UTILITIES  PANEL

strconstant	ksPN_UTILS	= "util"				// To gain full advantage of this string constant  ALL control names in this panel must be converted e.g. "root_uf_" + sFolder_ + " + ksPN_UTILS + "_buStartMov0000" which  blows up the code quite a bit...

Function		DataUtilitiesPanel( sWin, xPos , yPos, nMode  )
	string  	sWin	
	variable	xPos, yPos
	variable 	nMode	
	string  	sFBase		= "root:uf:"
	string  	sFSub		= ksEVAL_	
	string		sPnTitle		= "DataUtilities"
	string		sDFSave	= GetDataFolder( 1 )							// The following functions do NOT restore the CDF so we remember the CDF in a string .
	UFCom_PossiblyCreateFolder( sFBase + sFSub + sWin )
	SetDataFolder sDFSave										// Restore CDF from the string  value
	InitDataUtilitiesPanel( sFBase + sFSub , sWin )						// fills big text wave  'sPnOptions' (=wPn)  with all information about the controls necessary to build the panel
	UFCom_Panel3Sub(   sWin,	sPnTitle, 	sFBase + sFSub ,   xPos, yPos , nMode ) 	// Compute the location of panel controls and the panel dimensions. Draw the panel displaying and hiding needed/unneeded controls
End


Function		InitDataUtilitiesPanel( sF, sPnOptions )
	string  	sF, sPnOptions
	string  	sPanelWvNm	= sF + sPnOptions 
	variable	n = -1, nItems = 35
	make /O /T /N=(nItems) 	$sPanelWvNm
	wave  /T	tPn		= 	$sPanelWvNm
	//				Type	 NxL Pos MxPo OvS	Tabs	Blks	Mode	Name		RowTi			ColTi			ActionProc	XBodySz	FormatEntry						Initval	Visibility	SubHelp
	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:	,:	,:		dum1:		Filtering:			:			:			:		:								:		:		:				"		
	n += 1;	tPn[ n ] =	"BU:    1:	0:	3:	0:	°:	,:	1,°:		buFiltAppl:		fFilterTitles():		:			fFilterApply():	:		42000,42000,42000~56000,56000,56000:	~0:		:		Apply or Remove Filter:"	//  	
	n += 1;	tPn[ n ] =	"PM:	   0:	1:	3:	0:	°:	,:	1,°:		pmFiltType:	:				:			:			80:		fFilterTypePops():					~3:		:		Filter Type:		"	// 	
	n += 1;	tPn[ n ] =	"SV:    0:	2:	3:	0:	°:	,:	1,°:		svFiltFreq:		Freq:				:			:	  		50:		%5.0lf; .01,99000,1000:				~1000:	:		Filter frequency:		"
	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:	,:	,:		dum2:		Cutting stimulus data:	:			:			:		:								:		:		:				"		
	n += 1;	tPn[ n ] =	"BU:    1:	0:	3:	0:	°:	,:	1,°:		gbCursrCut:	Cursors Set~Cursors Cut::			fCursorSetCut():	:		42000,42000,46000~60000,57000,57000:	~0:		:		Cutting:			"	//  	
//	n += 1;	tPn[ n ] =	"BU:    1:	0:	3:	0:	°:	,:	1,°:		gbCursrCut:	Cursors Set~Cursors Cut::			fCursorSetCut():	:		42000,42000,46000~60000,56000,56000:	~1:		:		Cutting:			"	//  	
//NO!n += 1;	tPn[ n ] =	"BU:    1:	0:	3:	0:	°:	,:	1,°:		gbCursrCut:	Cursors Set~Cursors Cut::			fCursorSetCut():	:		fCursorColorLst():					~1:		:		Cutting:			"	//  	
	n += 1;	tPn[ n ] =	"STR:  0:	1:	3:	1:	°:	,:	1,°:		gsCutPath:	 :				:			:			:		:								:		:		Cut Data path:		"	//
	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:	,:	,:		dum8:		:				:			:			:		:								:		:		:				"		
	n += 1;	tPn[ n ] =	"BU:    1:	0:	3:	0:	°:	,:	1,°:		buAxSclbar: 	Axes and  Scalebars:	:			fAxisScalebars()::		:								:		:		Axes and  Scalebars:	"	//  	

	redimension   /N=(n+1)	tPn
End


//=================================================================================================================================================================
//	FILTERING  and  SMOOTHING

constant		kFILTERTYPE_GAUSS = 0 ,  kFILTERTYPE_GAUSSFFT = 1 ,  kFILTERTYPE_SMOOTH1= 2,  kFILTERTYPE_SMOOTH2= 3,  kFILTERTYPE_SMOOTH3 = 4,  kFILTERTYPE_SMOOTH5 = 5
strconstant	lstFILTERTYPE	= "Gauss;Gauss FFT;Smooth1;Smooth2;Smooth3;Smooth5;"	// popmenus need semicolon separators

strconstant	ksFILTERED		= "Filtered=TRUE"								// marker string stored in wave's note


Function	/S	fFilterTitles( sBaseNm, sF, sWin )
	string  	sBaseNm, sF, sWin 
	return	"Apply Filter" + UFCom_ksSEP_TILDE + "Remove Filter"
End

Function		FilterFreq( sFolders )
	string  	sFolders
	nvar		gFilterFreq	= $"root:uf:" + sFolders + ":svFiltFreq0000"
	return	gFilterFreq
End

Function		FilterType( sFolders )
	string  	sFolders
	nvar		nFilterType	= $"root:uf:" + sFolders + ":pmFiltType0000"	
	// printf "\t\t\tFilterType( from variable: %d \t->'%s'  \r", nFilterType-1 , StringFromList( nFilterType-1, lstFILTERTYPE )
	return	nFilterType - 1		// popmenu variables are 1-based
End

Function		fFilterApply( s )
	struct	WMButtonAction 	&s
	string  	sFolders	= ReplaceString( "root:uf:", GetUserData( 	s.win,  s.ctrlName,  "sFo" )	, "" )  + s.win	// e.g.  'root:uf:eva:'  ->  'eva:'  ->  'eva:util' 
	nvar		state		= $ReplaceString( "_", s.CtrlName, ":" )									// the underlying button variable name is derived from the control name
	 printf "\t\tfFilterApply(a)\tstate:%2d\t%s\t%s\t%s\t \r" , state,  time(), UFCom_pd(s.win,8) , UFCom_pd(s.ctrlName,27)
	variable	CutoffFreq
	string  	sWvNm, lstWaves	= ""
	string  	sTNm, sTNL		=TraceNameList( "", ";", 1 )
	variable	t, tCnt			= ItemsInList( sTNL )
	variable	nFilterType		= FilterType( sFolders )					// Get the filter type from the PopupMenu ( Gauss, Smooth,...)  

	printf "\t\tfFilterApply(b)\tstate:%2d\t%s\t%s\tCutofffreq:\t%7.1lf\tFTyp%2d %s)\tTraces:\t%2d\tTNL\t%s  \r", state, time(), UFCom_pd(s.win,8) , CutoffFreq, nFilterType, UFCom_pd(StringFromList( nFilterType, lstFILTERTYPE),9) , tCnt, UFCom_pd( sTNL, 180 )
	for ( t = 0; t < tCnt; t += 1 )
		sTNm		= StringFromList( t, sTNL )						
		wave      wData	= TraceNameToWaveRef( "", sTNm )
		variable  dltax	= deltax( wData )
		sWvNm		= GetWavesDataFolder( wData, 2 ) 					// 2 : include full path and wave name
		if ( WhichListItem( sWvNm, lstWaves ) == UFCom_kNOTFOUND )				// One  wave can be displayed as multiple traces xxx#1, xxx#2 , but we need the wave name only once so we add it to the new list only if it is not yet a member...
			variable	lenDO	= strlen( "root:uf:" + ksACQ + ":stim:DOFull" )	// ...AND we never filter the Digout and the Save/NoSave wave..
			variable	lenSV	= strlen( "root:uf:" + ksACQ + ":stim:SV" )		// This is cosmetics / design issue, we might just as well filter those too
			if ( cmpstr( sWvNm[ 0 , lenDO - 1 ] ,"root:uf:" + ksACQ + ":stim:DOFull" )  && cmpstr( sWvNm[ 0, lenSV - 1 ] ,"root:uf:" + ksACQ + ":stim:SV" ) )	// ...AND we never filter the Digout and the Save/NoSave wave..
				lstWaves	+= sWvNm + ";"															
				CutoffFreq	= FilterFreq( sFolders ) 
				printf "\t\tfFilterApply(c)\tstate:%2d\t%s\tCutofffreq:\t%7.1lf\tFTyp%2d %s)\tdx=SI*step:\t%12.6lf\tTrace:\t%2d/\t%2d\tTnm\t%s\twvs:\t%s  \r", state, UFCom_pd( sWvNm,16), CutoffFreq, nFilterType, UFCom_pd(StringFromList( nFilterType, lstFILTERTYPE),9) , dltax, t, tCnt, UFCom_pd( sTNm, 12 ), UFCom_pd( lstWaves, 180 )

				FPGeneralFilter( sWvNm, CutoffFreq, nFilterType, state )

			endif
		endif
	endfor
End


// 060504  cannot / does not work  ??? because PopupMenu is expected???  see  'fFilterTypePops'
Function	/S	fCursorColorLst( sControlNm, sFo, sWin )
	string		sControlNm, sFo, sWin
	return	"40000,40000,50000" + UFCom_ksSEP_TILDE + "64000,54000,54000"
End

Function		fFilterTypePops( sControlNm, sFo, sWin )
	string		sControlNm, sFo, sWin
	PopupMenu	$sControlNm,	win = $sWin,	value = lstFILTERTYPE
End

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function		FPGeneralFilter( sWvNm, CutoffFreq, nFilterType, bDoFilter )
// Replaces data with the filtered result but also stores original data so that unfiltered data can be restored. 
// The state (filtered or unfiltered) is stored in the wave's note
	string  	sWvNm
	variable 	CutoffFreq,  bDoFilter, nFilterType 
	
	string		sOrigWvNm	= sWvNm + "Org"

	// printf "\t\tFPGeneralFilter(  \t%d\t%s\tCutofffreq:\t%7.1lf\tFTyp%2d %s)\tIsFiltered:%4d\t \r", bDoFilter, UFCom_pd( sWvNm,16), CutoffFreq, nFilterType, UFCom_pd(StringFromList( nFilterType, lstFILTERTYPE),9) ,  IsFiltered( sWvNm )
	if ( bDoFilter == UFCom_TRUE )  

		if (  ! IsFiltered( sWvNm )  )									// Filter the original wave
			duplicate	/O	 $sWvNm		$sOrigWvNm				//		...first store the original
		else													// Refilter : filter with another setting : restore and use the original wave for filtering
			duplicate	/O	 $sOrigWvNm	$sWvNm					//		...first retrieve the original
		endif
		SetFiltered( sWvNm, UFCom_TRUE )

		wave	wData	= $sWvNm
		if ( kFILTERTYPE_SMOOTH1 <= nFilterType   &&  nFilterType <=  kFILTERTYPE_SMOOTH5 )
			if ( ( WaveType( wData ) & 0x02 )  || ( WaveType( wData ) & 0x04 )  )	// wave is  float 4byte  or  float 8byte (could also handle complex...)
				variable 	nPts		=  numpnts( wData )
				variable	dltax		= deltax( wData) 
				if ( nFilterType == kFILTERTYPE_SMOOTH1 )
					smooth		1 , wData		
				endif
				if ( nFilterType == kFILTERTYPE_SMOOTH2 )
					smooth		2 , wData		
				endif
				if ( nFilterType == kFILTERTYPE_SMOOTH3 )
					// Just for demonstrating the artefact use  ( see 'Smooth' for explanation ) : /E=2   = zero method	(not good)	
					//smooth /E=2	3 , wData		
					smooth		3 , wData		
				endif
				if ( nFilterType == kFILTERTYPE_SMOOTH5 )
					smooth		5 , wData		
				endif
				printf "\t\tSmoothing Filter( \tstate:%2d\t%s\tCutofffreq:\t%7.1lf\tFTyp%2d %s)\tdx=SI*step:\t%12.6lf\t->\tScaled cutoff frq:\t%7.4lf\tPts:%5d\t  \r", bDoFilter, UFCom_pd( sWvNm,16), CutoffFreq, nFilterType, UFCom_pd(StringFromList( nFilterType, lstFILTERTYPE),9) , dltax, CutoffFreq * dltax, nPts
			else
				UFCom_Alert( UFCom_kERR_MESSAGE, "Cannot smooth wave  '" + sWvNm + "'  as it is neither float nor double type. WaveType is  " + num2str( WaveType( wData ) ) )
			endif
		endif

		if ( nFilterType == kFILTERTYPE_GAUSSFFT )
			FPGaussianFilterWithFFT( sWvNm, CutoffFreq, nFilterType )
		endif
		if ( nFilterType == kFILTERTYPE_GAUSS )
			FPGaussianFilter( sWvNm, CutoffFreq , nFilterType )
		endif

	endif

	if ( bDoFilter == UFCom_FALSE  &&    IsFiltered( sWvNm )  )					// remove the filter from a filtered wave : restore the original wave
		duplicate	/O	 $sOrigWvNm	$sWvNm
		SetFiltered( sWvNm, UFCom_FALSE )
	endif

	if ( bDoFilter == UFCom_FALSE  &&   ! IsFiltered( sWvNm )  )					// remove the filter from an unfiltered wave : do nothing
	endif

End

Function		SetFiltered( sWvNm, bState )
// Store the state of the wave (filtered or unfiltered)  in the wave's note. Must be refined if additional  items are also stored here...
	string  	sWvNm
	variable	bState
	if ( bState )
		Note $sWvNm ,	ksFILTERED
	else
		Note /K  $sWvNm 	// , ksUNFILTERED		// or remove  'filtered' line
	endif
End

Function		IsFiltered( sWvNm )
// Retrieve the state of the wave (filtered or unfiltered)  from the wave's note. Must be refined if additional  items are also stored here...
	string  	sWvNm
	string  	sNote	= note( $sWvNm )
	return	strsearch( ksFILTERED, sNote, 0 )  != UFCom_kNOTFOUND
End


//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//    GAUSSIAN  FILTER : WaveMetrics version using  FFT  and  IFFT

Function		FPGaussianFilterWithFFT( sWvNm, CutoffFreq, nFilterType )
// replaces data with the filtered result
	string  	sWvNm  		
	variable 	CutoffFreq
	variable	nFilterType 						// only for printing

	wave	wData		= $sWvNm
	variable	CutoffAmplitude	= 1 / sqrt( 2 ) 							//  0.707 = 1/sqrt( 2 )  = -3db  for half-power ,  0.5 = -6db for half-voltage

	if ( ( WaveType( wData ) & 0x02 )  || ( WaveType( wData ) & 0x04 ) )		// wave is  float 4byte  or  float 8byte (could also handle complex...)
		variable 	nPts		=  numpnts( wData )
		variable	dltax		= deltax( wData) 

		// printf "\t\tFPGaussianFilter( \t%s\tCutofffreq:\t%7.1lf\tFTyp%2d %s)\tdx=SI*step:\t%12.6lf\t->\tScaled cutoff frq:\t%7.4lf\tPts:%5d\t  \r", UFCom_pd( sWvNm,16), CutoffFreq, nFilterType, UFCom_pd(StringFromList( nFilterType, lstFILTERTYPE),9) , dltax, CutoffFreq * dltax, nPts
		// Original code has been coomented out as it lead to end effect artefacts. Without the following line  ( see 'Smooth' for explanation ) : /E=3   = fill method	(   good  )	is imitated.
		//		Redimension /N = ( nPts*2 ) wData					// eliminate end-effects

		FFT 		wData
		wave  /C	cfiltered =  wData
		 FPApplyGaussFilterResponseCmplx( cfiltered, CutoffFreq, CutoffAmplitude )
		 IFFT 	cfiltered

		// Original code has been coomented out as it lead to end effect artefacts. Without the following line  ( see 'Smooth' for explanation ) : /E=3   = fill method	(   good  )	is imitated.
		//		Redimension /N = ( nPts ) wData

	else
		UFCom_Alert(  UFCom_kERR_MESSAGE, "Cannot filter wave  '" + sWvNm + "'  as it is neither float nor double type. WaveType is  " + num2str( WaveType( wData ) ) )
	endif

End

Function 		FPApplyGaussFilterResponse( w, CutoffFreq, cutoffAmplitude )
	wave 	w
	variable 	CutoffFreq
	variable 	cutoffAmplitude 				//  0.707 = 1/sqrt( 2 )  = -3db  for half-power ,  0.5 = -6db for half-voltage 
	
	variable 	gaussWidth =  CutoffFreq/sqrt( -ln( cutoffAmplitude ) )
	
	w *=  exp( -( x*x/( gaussWidth*gaussWidth ) ) )
End


Function 		FPApplyGaussFilterResponseCmplx( w, CutoffFreq, cutoffAmplitude )
	wave /C 	w
	variable 	CutoffFreq
	variable 	cutoffAmplitude			 // use 0.5 for half-voltage,  1/( sqrt( 2 ) ) for half-power
	
	variable 	gaussWidth =  CutoffFreq/sqrt( -ln( cutoffAmplitude ) )
	
	w *=  cmplx( exp( -( x*x/( gaussWidth*gaussWidth ) ) ), 0 )
End

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//     GAUSSIAN  FILTER   after Sigworth & Colquhoun, Single Channel Recording, App.3

constant		kMAXFILTERCOEFFS = 500//220

Function		FPGaussianFilter( sWvNm, CutoffFreq, nFilterType )
// Replaces data with the filtered result.  Real 'freq' is corner CutoffFreq in units of the sample frequency. 
// Integer 'compression' shrinks 'out' array size.  Number of 'out' points is number of 'in' points divided by compression. 
	string  	sWvNm 
	variable	CutoffFreq
	variable	nFilterType 						// only for printing

	wave	wData		= $sWvNm
	variable	compression	= 1					// we disable this filter-internal compression, as FPulse already provides compressed data 
	
	variable	i0, i, j, jj, jmax, jmin;
	variable	vsum, vcentral;
	variable	nInPts		= numPnts( wData )
	duplicate	/O  	wData ,  wTmp					// construct temporary result wave with same size and scaling as original data				

	make /O /N=( kMAXFILTERCOEFFS + 1 )	wCoeffs	= 0
	variable	dltax		= deltax( wData) 
	variable     numCoeffs	=  SetGaussFilter( CutoffFreq * dltax, wCoeffs )	// not counting Coeff[ 0 ] , there is really one more coefficient
	printf "\t\tFPGaussianFilter( \t%s\tCutofffreq:\t%7.1lf\tFTyp%2d %s)\tdx=SI*step:\t%12.6lf\t->\tScaled cutoff frq:\t%7.4lf\tPts:%5d\t->\tCoeffs:%3d\t[Cmax:%4d]\t \t\r", UFCom_pd( sWvNm,16), CutoffFreq, nFilterType, UFCom_pd(StringFromList( nFilterType, lstFILTERTYPE),9) , dltax, CutoffFreq * dltax, nInPts, numCoeffs, kMAXFILTERCOEFFS
	compression = max( 1, compression )

	for ( i0 = 0; i0 < nInPts / compression; i0 += 1 ) 
    
    		i = i0 * compression

		jmin		= numCoeffs
		jmax		= numCoeffs
      
		vsum = 0

		// Modification to handle edge effects satisfactorily : to avoid edge errors (by the clipping below) insert virtual points beyond array bounds having the value of the first/last point
		// Without	this code  ( see 'Smooth' for explanation ) : /E=2   = zero method	(not good)	is used	( /E=1  = wrap	   method is no good  either)	
		// With 	this code  ( see 'Smooth' for explanation ) : /E=3   = fill	 method	(   good  )	is used	( /E=0  = bounce  method is also acceptable, this is Smooth default)  
		if ( i < jmin )
			jj = jmin
			do
				vsum	+= wCoeffs[ jj ] * wData[ i ] 
				jj -= 1
			while ( jj - i > 0 )
		endif
		if ( i  >  nInPts - jmax - 1 )
			jj = jmax
			do
				vsum	+= wCoeffs[ jj ] * wData[ i ] 
				jj -= 1
			while ( jj + i - nInPts + 1 > 0 )
		endif
		// ...	end of	/E=3   = fill	 method

		// Original code again : Make sure we stay within bounds of the input array  (this clipping is responsible for the erraneous edge effects...)
		jmin 		= ( i < jmin ) ? i : jmin

		jmax 		= ( jmax >= nInPts - i ) ? nInPts - i - 1 : jmax

		vsum  	+= wCoeffs[ 0 ] * wData[ i ]			// central point
		vcentral	= vsum						// only for printing
		for ( j = 1; j <= jmin; j += 1 ) 
			vsum += wCoeffs[ j ] * wData[ i - j ]		// early points =  left of / before central point
			// printf "\t\t\t\tFPGaussianFilter(early)\ti:%4d\tj:%4d\ti-j:\t%6d\twData[i-j]:\t%g\tVcentral:\t%g\t->\tVsum:\t%g\t\tCoeff[ j:%d ]:\t%g  \r", i, j, i - j, wData[ i - j ], vcentral, vsum , j, wCoeffs[ j ] 
		endfor

		for ( j = 1; j <= jmax; j += 1 ) 
			vsum += wCoeffs[ j ] * wData[ i + j ]		// late  points = right of / after central point
			// printf "\t\t\t\tFPGaussianFilter(late)\ti:%4d\tj:%4d\ti+j:\t%6d\twData[i+j]:\t%g\tVcentral:\t%g\t->\tVsum:\t%g\t\tCoeff[ j:%d ]:\t%g  \r", i, j, i + j, wData[ i + j ], vcentral, vsum  , j, wCoeffs[ j ] 
		endfor

		wTmp[ i0 ] = vsum						// Assign the output value
	endfor

	duplicate	/O  	wTmp , wData 					// overwrite original wave with filtered wave

End


Function		SetGaussFilter( CutoffFreq, wCoeffs )
// Load the filter coefficient values according to the cutoff CutoffFreq (in units of the sample frequency) given
	variable	CutoffFreq
	wave	wCoeffs
	variable	b, normSum, sigma = 0.132505 / CutoffFreq
	variable   	i, numCoeffs
	string  	sErrBuf

	if ( sigma < 0.62 )				// light filtering
   		wCoeffs[ 1 ]	= 0.5 * sigma * sigma
   		wCoeffs[ 0 ]	=  1.  - sigma * sigma
   		numCoeffs 	= 1
	else							// normal filtering
		numCoeffs		= trunc( 4. * sigma )
 		if ( numCoeffs > kMAXFILTERCOEFFS ) 
			sprintf sErrBuf, "SetGaussFilter: Desired cutoff frequency is too low. It requires too many coefficients: %d (max %d) . ", numCoeffs , kMAXFILTERCOEFFS  
			UFCom_Alert( UFCom_kERR_SEVERE, sErrBuf )
			numCoeffs	= kMAXFILTERCOEFFS
		endif
		b = -1. / ( 2. * sigma * sigma )

		// First make the sum for normalization..
		normSum = .5
		for ( i = 1; i <= numCoeffs; i += 1 ) 
			normSum += exp( b * i * i )
		endfor
		normSum *= 2.
   	      	// Now compute the actual coefficients
   	      	wCoeffs[ 0 ] = 1. / normSum
		for ( i = 1; i <= numCoeffs; i += 1 ) 
			wCoeffs[ i ] = exp( b * i * i ) / normSum
		endfor
	endif
	return	numCoeffs
End


//=================================================================================================================================================================
//	CUTTING  and  STORING  EPISODES

Function		fCursorSetCut( s )
	struct	WMButtonAction 	&s
	string  	sFolders	= ReplaceString( "root:uf:", GetUserData( 	s.win,  s.ctrlName,  "sFo" )	, "" )  + s.win	// e.g.  'root:uf:eva:'  ->  'eva:'  ->  'eva:util' 
	variable	rxl, rxr
	nvar		state		= $ReplaceString( "_", s.ctrlName, ":" )					// the underlying button variable name is derived from the control name
	string   	sName	= CursorSetCut( sFolders, state, rxl , rxr )
	 printf "\t\tfCursorSetCut()\tstate:%2d\t%s\t%s\t%s\t%s\tX = %.3lf  and  %.3lf ,   \tsName: \t%s\t    \r", state, UFCom_pd(sFolders,8), time(), UFCom_pd(s.win,8) , UFCom_pd(s.ctrlName,24) , rxl , rxr, UFCom_pd( sName, 16)
	if ( rxl - rxr != 0 )
		printf "\t\tCursorSetCut()\t\t\treturns  \tX = %.3lf  and  %.3lf ,   \tsName: \t%s\t   \r", rxl , rxr, UFCom_pd( sName, 16)
		rxl	= min( rxl, rxr )
		rxr	= max( rxl, rxr )
		SaveStimWaveAsIBW( sFolders, sName, rxl, rxr )
	endif
End


Function	/S	CursorSetCut( sFolders, state, rxl , rxr )
	string  	sFolders
	variable	state
	variable	&rxl , &rxr 
	rxl = 0													// error return
	rxr = 0
	string	 	sName	= "NoName"
	string  	sTNL, sTrace, sTopGraphWndNm	=  WinName( 0, 1 )		// look only for graphs, if found return the top graph
	if ( strlen( sTopGraphWndNm ) )									// there is a top graph
// 060504
//		if ( state == 0 ) 		???????								// we are in State 0 = starting : no cursors have been set, so we display them for the user to adjust
		if ( state )												// SET: we were in State 0, but are now in 1: no cursors have been set, so we display them for the user to adjust
			sTNL 	= TraceNameList( sTopGraphWndNm, ";", 1 )
			sTrace	= StringFromList( 0, sTNL )						// we place the cursors on the first trace found
			if ( strlen( sTrace ) ) 
				wave  /Z	wTrace	= TraceNameToWaveRef( sTopGraphWndNm, sTrace )
				Cursor 	/W= $sTopGraphWndNm /A=1  /H=1 /S=1 /L=1   /C=( 64000, 0, 0 )	A, $sTrace, ( 3 * leftx( wTrace ) + 1 * rightx( wTrace ) ) / 4 	// we place the cursors at 1/4  and  3/4
				Cursor 	/W= $sTopGraphWndNm /A=1  /H=1 /S=1 /L=1   /C=( 0, 0, 56000 )	B, $sTrace, ( 1 * leftx( wTrace ) + 3 * rightx( wTrace ) ) / 4
				ShowInfo	/W= $sTopGraphWndNm 					// Display the small cursor control box. This is not mandatory for cursor usage.
				string 	sTimeStamp	= UFCom_TimeStamp()
				SetCutPath( sFolders, sTrace + sTimeStamp )					// Name of the cut out wave
				printf "\t\tCursorSetCut(a)\tstate:%2d\t has set cursors on trace \t%s\t in graph \t%s\t leftX: %.3lf  , rightX: %.3lf \tTimeStamp:%s \r", state, UFCom_pd(sTrace,8), UFCom_pd(sTopGraphWndNm,18),  leftx( wTrace ) , rightx( wTrace ), sTimeStamp
			else
				UFCom_Alert(  UFCom_kERR_LESS_IMPORTANT,  "There are no traces in graph '" + sTopGraphWndNm + "' ." )
			endif
		else													// CUT : we are in State 1 = finishing : the user has adjusted the cursors so we evaluate them
			Wave/Z wA = CsrWaveRef( A, sTopGraphWndNm ) 			// Make sure both cursors are on the same wave.
			Wave/Z wB = CsrWaveRef( B, sTopGraphWndNm )	 	
			if (  WaveExists( wA )  &&  WaveExists( wB ) )				// OK : Both cursors are on the graph
				String dfA = GetWavesDataFolder( wA, 2 )				// get the path (folder and wave name) of  wave  as a string
				String dfB = GetWavesDataFolder( wB, 2 )
				if ( cmpstr( dfA, dfB ) == 0 )							// OK : Both cursors are on the same wave
					sName	= dfA
					rxl	= xcsr( A )
					rxr	= xcsr( B )
					printf "\t\tCursorSetCut(b)\tstate:%2d\t has cut  trace \t%s\t in graph \t%s\t between X = %.3lf  and  %.3lf .\r", state, UFCom_pd( dfA,16), UFCom_pd(sTopGraphWndNm,18), rxr, rxl
					HideInfo	/W= $sTopGraphWndNm 				// Removes cursor control box but leaves cursor on the trace.  This is not mandatory for cursor usage
					Cursor 	/W=$sTopGraphWndNm /K  A			// Remove cursor  A  if on trace
					Cursor 	/W=$sTopGraphWndNm /K  B			// Remove cursor  B  if on trace
				else
					UFCom_Alert(  UFCom_kERR_LESS_IMPORTANT,  "Both cursors must be on the same wave." )
				endif
			else
				UFCom_Alert( UFCom_kERR_LESS_IMPORTANT,  "Both cursors must be on the graph." )
			endif
		endif													// Button state = 0  or  1
	else
		UFCom_Alert(  UFCom_kERR_LESS_IMPORTANT,  "There are no graphs. " )
	endif
	return	sName
End


Function		SaveStimWaveAsIBW( sFolders, sWvFolderNm, xl, xr ) 
// store the wave part  which the user has cut out as an IBW (Igor binary wave) to be used as a stimwave in a script file
	string 	sFolders, sWvFolderNm
	variable	xl, xr
	variable	nPathParts	= ItemsInList( sWvFolderNm, ":" )
	string		sCutPath		= CutPath( sFolders )						// Name of the cut out wave
	string  	sFile			= ksSCRIPTS_DRIVE + ksSCRIPTS_DIR + ":" + sCutPath + ".ibw"	// C:UserIgor:Scripts: + wave name (the folders being stripped off)
	string  	sCutFoWaveNm= sWvFolderNm + "_"
	duplicate /O /R=(xl, xr) 	$sWvFolderNm , $sCutFoWaveNm
	variable	nPts	= numPnts( $sCutFoWaveNm )

	printf "\t\tSaveStimWave()\tsaves between  \tx = %.3lf  and  %.3lf , (pts:%3d) \tsName: \t%s\t  ,   sFile: '%s'  \r", xl , xr, nPts,  UFCom_pd( sCutFoWaveNm, 26), sFile 

	save /O /C $sCutFoWaveNm			as sFile 					// store to disk 
	killWaves	  $sCutFoWaveNm

End


Function		SetCutPath( sFolders, sCutPath )
	string  	sFolders, sCutPath
	svar		gsCutPath	= $"root:uf:" + sFolders + ":gsCutPath0000"
	gsCutPath	= sCutPath
End

Function	/S	CutPath( sFolders )
	string  	sFolders
	svar		gsCutPath	= $"root:uf:" + sFolders + ":gsCutPath0000"
	return	gsCutPath
End

//=================================================================================================================================================================
//  	AXIS  and  SCALEBARS  030530
//	Panel and functions taken from  Igor4.07   'Append Scalebar.ipf'   and modified for  and  integrated into  FPULSE  
//
// Append Scalebar.ipf    from  Igor V4.7
// Modernized LH000705
// Revised JP010315 - works when axes are reversed, opens the drawing tools.
// Rewritten JP010402 - uses panel, has color and digits parameters.
//
// Choose Scalebar... from Graph menu to open a panel that appends Scalebar bars to the top graph. 
//
// The procedure uses the drawing tools to create the Scalebar as one grouped object. 
// To make changes to the Scalebar  you will usually first ungroup it with the drawing tools "bulldozer" menu.

//	Remarks: 
//	When  'AxisScalebarsDlg()'  is called  a  panel with scalebar settings is opened just below the currently active graph.
//	When another is window is made the active graph, the previous panel is removed and the panel is rebuilt with the other
//	graphs settings below the other graph. This means each graph keeps track of its panel settings.
//	This is done by automaticaly creating and naming variables and folders for each graph. 	 (The panel allows to select 
//	different axes in each graph and to draw different scalebars for each axis, but these are NOT stored . Only the last recently 
//	drawn scalebar settings are stored. This limitation could easily be overcome by introducing an additional folder level 'AxisName' ).
//
//	BIG advantage of this (=WaveMetrics's) programming style  :
//	The creation and naming of the variables is completely contained in this function.
//	This function (and this functionality) works on any graph without making any assumption about the graph names and 
//	without the need to define globals externally to this function: data hiding and modularity are achieved !
//
//	Disadvantage:
//	Although WaveMetrics's programming style is in principle highly advantageous, it cannot be readily combined with
//	my 'Dialog' functions which are (NOT regarding the fact that they rely on externally defined globals) vastly superior when 
//	building panels...
//
//	Goal  / TODO:
//	Check if  WaveMetrics's programming style can be perhaps be modified and applied  to my 'Dialog' functions 
//	to get the best of two worlds... but be sure to check EVERY instance if it can be modified because finally there should be no mixup 
//	between the two styles.
//	( It must handle variables arranged as waves e.g. 'wGain' (..NOT ANY MORE...),  it must be able to apply to different waves in a graph,  for this the introduction
//	of another folder level is probably sufficient)
//
//	As long  these questions are not answered, we keep this SINGLE INSTANCE of a  'WaveMetrics style' panel.

constant	kNORMAL_LABELS	= 0,	kNOLABELS	= 2
constant	cTICKS_OUTSIDE 	= 0,	kNOTICKS	= 3

Function		fAxisScalebars( s ) 
	struct	WMButtonAction	&s
	AxisScalebarsDlg()
End

Function		AxisScalebarsDlg()
	DoWindow   /K ScalebarPn
	NewPanel   /W=(392,42,645,392)/K=1 as "Axes and Scalebars"
	DoWindow  /C ScalebarPn
	ModifyPanel /W=ScalebarPn fixedSize=1
	
	string graphName= WinName(0,1)
	if ( strlen(graphName) )
		AutoPositionWindow/E/M=1/R=$graphName	// position the panel below the graph in which scalebars are to be drawn
	else
		AutoPositionWindow/E/M=1
	endif

	// orientation decorations
//	// 				     1
//	// Orientation style	1 I~~  		upperLeft
//	//
//	SetDrawEnv gstart
//	SetDrawEnv linethick= 2
//	DrawLine 64,122,64,107
//	SetDrawEnv linethick= 2
//	DrawLine 85,107,65,107
//	DrawText 69,104,"1"
//	DrawText 54,122,"1"
//	SetDrawEnv gstop
//	// 				  1
//	// Orientation style	~~I 1  		upperRight
//	//
//	SetDrawEnv gstart
//	SetDrawEnv linethick= 2
//	DrawLine 172,124,172,109
//	SetDrawEnv linethick= 2
//	DrawLine 172,109,152,109
//	DrawText 174,124,"1"
//	DrawText 157,108,"1"
//	SetDrawEnv gstop
	//
	// Orientation style	1 L  		lowerLeft
	// 				   1
	SetDrawEnv gstart
	SetDrawEnv linethick= 2
	DrawLine 64,170,64,155
	SetDrawEnv linethick= 2
	DrawLine 	85,170,65,170
	DrawText 	70,185,"1"		// x
	DrawText 	54,169,"1"		// y
	SetDrawEnv gstop
	//
	// Orientation style	J 1  		lowerRight
	// 				1
	SetDrawEnv gstart
	SetDrawEnv linethick= 2
	DrawLine 	172,170,172,155
	SetDrawEnv linethick= 2
	DrawLine 	172,170,152,170
	DrawText 	158,185,"1"	// x
	DrawText 	174,169,"1"	// y
	SetDrawEnv gstop
	//
	// Orientation style	   L1 		lowerLftInside
	// 				   1
	SetDrawEnv gstart
	SetDrawEnv linethick= 2
	DrawLine 	64,210,64,195
	SetDrawEnv linethick= 2
	DrawLine 	85,210,65,210
	DrawText 	70,225,"1"		// x
	DrawText 	67,206,"1"		// y
	SetDrawEnv gstop
	//
	// Orientation style	  J  		lowerRghtBelow
	// 				1  1	
	SetDrawEnv gstart
	SetDrawEnv linethick= 2
	DrawLine 	172,210,172,195
	SetDrawEnv linethick= 2
	DrawLine 	172,210,152,210
	DrawText 	150,225,"1 / 1"
	SetDrawEnv gstop

	// Axes selection
	//		x
	PopupMenu xAxis,		win=ScalebarPn, pos={ 9,	10},		size={170,16},	title="Horizontal Axis X:",	proc=FPScalebarPopMenuProc
	CheckBox   xShowAxis,	win=ScalebarPn, pos={16,	31},		size={62,14},	title="X Axis",			proc=FPScalebarShowAxisCheckProc
	CheckBox   xShowBar,	win=ScalebarPn, pos={16,	51},		size={62,14},	title="X Scalebar",		proc=FPScalebarCheckProc
	SetVariable xLength,		win=ScalebarPn, pos={96,	50},		size={78,15},	title="Value:",	limits={-Inf,Inf,0}
	Button	  xNiceVal,		win=ScalebarPn, pos={188,51},		size={58,14},	title="AutoValue",		proc=FPScalebarAutoValueButtonProc
	//		y
	PopupMenu yAxis,		win=ScalebarPn, pos={ 9,	 80},		size={62,16},	title="Vertical  Axis Y : ",	proc=FPScalebarPopMenuProc
	CheckBox   yShowAxis,	win=ScalebarPn, pos={16,	101},		size={62,14},	title="Y Axis",			proc=FPScalebarShowAxisCheckProc
	CheckBox   yShowBar,	win=ScalebarPn, pos={16,	121},		size={62,14},	title="Y Scalebar",		proc=FPScalebarCheckProc
	SetVariable yLength,		win=ScalebarPn, pos={96,	120},		size={78,15},	title="Value:",	limits={-Inf,Inf,0}
	Button	  yNiceVal,		win=ScalebarPn, pos={188,121},	size={58,14},	title="AutoValue",		proc=FPScalebarAutoValueButtonProc


	// orientation
//	CheckBox upperLeft		win=ScalebarPn, pos={ 35,	104},		size={30,14},	title=" ",	mode=1,		proc=FPScalebarPositionRadio
//	CheckBox upperRight	win=ScalebarPn,pos={123,	104},		size={30,14},	title=" ",	mode=1,		proc=FPScalebarPositionRadio
	CheckBox lowerLeft		win=ScalebarPn, pos={ 35,	158},		size={30,14},	title=" ",	mode=1,		proc=FPScalebarPositionRadio
	CheckBox lowerRight		win=ScalebarPn, pos={123,158},	size={30,14},	title=" ",	mode=1,		proc=FPScalebarPositionRadio
	CheckBox lowerLftInside	win=ScalebarPn, pos={ 35,	198},		size={30,14},	title=" ",	mode=1,		proc=FPScalebarPositionRadio
	CheckBox lowerRghtBelow	win=ScalebarPn, pos={123,198},	size={30,14},	title=" ",	mode=1,		proc=FPScalebarPositionRadio

//	// units : print units
//	PopupMenu units, 	win=ScalebarPn, pos={ 2,	185},		size={245,20},	title="units:", value="",proc=FPScalebarNumPopMenuProc
//	// number of digits 
//	PopupMenu digits,		win=ScalebarPn, pos={ 17,	208},		size={73,20},	title="Digits:",			proc=FPScalebarStr2NumPopMenuProc

	// color
	PopupMenu color,		win=ScalebarPn, pos={ 20,	231},		size={85,20},	title="Color:",	mode=1,	proc=FPScalebarColorPop
	PopupMenu color,		win=ScalebarPn, popColor= (0,0,0),	value= #"\"*COLORPOP*\""
	// line size
	PopupMenu lineSize,		win=ScalebarPn, pos={120,231},	size={88,20},	title="Line Size:",		proc=FPScalebarStr2NumPopMenuProc

//	// layer		buttons arranged vertically
//	GroupBox 	   layerGroup,	win=ScalebarPn, pos={ 23,	259},  	size={204,85},	title="Drawing Layer"
//	PopupMenu layer,		win=ScalebarPn, pos={117,258},	size={97,20},	title=" ",				proc=FPScalebarPopMenuProc
//	Button 	   EraseAllSclbar, 			 pos={ 39,	287},		size={99,20},	title="Erase Scalebars",	proc=FPScalebarEraseAllSclbarProc
//	Button	   AddSclbar,				 pos={ 39,	315},		size={99,20},	title="Add Scalebar",		proc=FPScalebarAddSclbarProc

	// layer		buttons arranged horizontally
	GroupBox 	   layerGroup,	win=ScalebarPn, pos={ 14,	260},  	size={224,55},	title="Drawing Layer"
	PopupMenu layer,		win=ScalebarPn, pos={117,260},	size={97,20},	title=" ",				proc=FPScalebarPopMenuProc
	Button	   AddSclbar,				 pos={ 24,	288},		size={99,18},	title="Add Scalebar",		proc=FPScalebarAddSclbarProc
	Button 	   EraseAllSclbar, 			 pos={ 128,288},	size={99,18},	title="Erase Scalebars",	proc=FPScalebarEraseAllSclbarProc


	CheckBox   ShowTools,	win=ScalebarPn, pos={16, 324},		size={62,14},	title="Show drawing tools",	proc=FPScalebarShowToolsProc

	FPScalebarUpdateForGraph("")
	
	SetWindow ScalebarPn hook=FPScalebarPnHook
End


Function		FPScalebarPnHook( infoStr )
	string		infoStr
	string		event	= StringByKey( "EVENT" , infoStr )
	strswitch( event )
		case "activate":
			FPScalebarUpdateForGraph("")
			break
	endswitch
	return 0				// 0 if nothing done, else 1 or 2
End


Function		FPScalebarUpdateForGraph( graphName )
	string		graphName
	
	if ( strlen( graphName ) == 0 )
		graphName	= WinName( 0, 1 )
		if ( strlen( graphName ) == 0 )
			return 0
		endif
	endif
	
	string 	oldDF	= FPScalebarSetDF(graphName)
	string 	df		= GetDataFolder( 1 )				// full path to the current data folder has trailing ":"

	// set up defaults or load current values
	// NOTE: the control name must match the name of the global variable  or string  in the data folder.
	string		str, path, list
	variable	var, whichOne
	variable	disable = 0		// disable everything if no axes.

	//  X	Axis selection : xAxis
	list		= HVAxisList(graphName,1)	// horizontal axes, if any
	if ( strlen(list) == 0 )
		list	= "missing X axis"
		disable=2	// shown, but disabled.
	endif
	str		= StrVarOrDefault(df+"xAxis",StringFromList(0,list))
	whichOne	= WhichListItem(str, list)+1	// note: the axis could have been removed
	if ( whichOne == 0 )	// not in list
		str		= StringFromList(0,list)
		whichOne	= 1
	endif
	string/G xAxis 	= str
	PopupMenu xAxis, win=ScalebarPn, disable=disable, mode=whichOne, popvalue=str, value= #"HVAxisList(\"\",1)+\"_none_;\""

	//  X Axis labels and ticks : xShowAxis
	path	= df + "xShowAxis"
	var	= NumVarOrDefault(path,1)
	variable/G xShowAxis = var
	CheckBox xShowAxis, win=ScalebarPn, disable=disable, variable=$path
	
	//  X Scalebar show/hide : xShowBar
	path	= df + "xShowBar"
	var	= NumVarOrDefault(path,1)
	variable/G xShowBar=var
	CheckBox xShowBar, win=ScalebarPn, disable=disable, variable=$path
	
	//  X Scalebar length : xLength
	path	= df + "xLength"
	var	= FPScalebarGetAutoValueLength( graphName,1 )	// isX, requires xAxis set up already.
	var	= NumVarOrDefault(path,var)
	variable/G xLength=var
	SetVariable xLength, win=ScalebarPn, disable=disable, value= $path
	Button xNiceVal win=ScalebarPn, disable=disable


	//  Y	Axis selection : yAxis
	list	= HVAxisList(graphName,0)	// vertical axes, if any
	if ( strlen(list) == 0 )
		list	= "missing Y axis"
	endif
	str		= StrVarOrDefault( df + "yAxis", StringFromList( 0, list ) )
	whichOne	= WhichListItem( str, list ) + 1
	if ( whichOne == 0 )	// not in list
		str		= StringFromList(0,list)
		whichOne	= 1
	endif
	string/G yAxis 	= str
	PopupMenu yAxis, win=ScalebarPn,disable=disable,mode=whichOne,popvalue=str,value= #"HVAxisList(\"\",0)+\"_none_;\""

	//  Y Axis labels and ticks : yShowAxis
	path	= df + "yShowAxis"
	var	= NumVarOrDefault(path,1)
	variable/G yShowAxis = var
	CheckBox  yShowAxis, win=ScalebarPn, disable=disable, variable=$path
	
	//  Y Scalebar show/hide : yShowBar
	path	= df + "yShowBar"
	var	= NumVarOrDefault( path, 1 )
	variable/G yShowBar=var
	CheckBox	 yShowBar,	win=ScalebarPn, disable=disable, variable=$path

	//  Y Scalebar length : yLength
	path	= df + "yLength"
	var	= FPScalebarGetAutoValueLength(graphName,0)	// !isX, requres yAxis set up already.
	var	= NumVarOrDefault( path, var )
	variable/G yLength=var
	SetVariable	yLength,	win=ScalebarPn, disable=disable, value= $path
	Button		yNiceVal	win=ScalebarPn, disable=disable

//	// orientation
	path	= df + "orientation"
	str	= StrVarOrDefault( path, "lowerLeft" )
	FPScalebarPositionRadio( str, 1 )
//	Checkbox upperLeft		win=ScalebarPn, disable=disable
//	Checkbox upperRight		win=ScalebarPn, disable=disable
	Checkbox lowerLeft		win=ScalebarPn, disable=disable
	Checkbox lowerRight		win=ScalebarPn, disable=disable
	Checkbox lowerLftInside	win=ScalebarPn, disable=disable
	Checkbox lowerRghtBelow	win=ScalebarPn, disable=disable

//	// units
//	list		= "don't print;print without units;print with units;print with units, K, m, etc"
//	whichOne	= NumVarOrDefault(df+"units",3)// popup number, 1 is the first item (item 0) in list, default to "print with units"
	variable/G units	= 3//whichOne
//	str		= StringFromList( whichOne - 1, list )
//	PopupMenu units,win=ScalebarPn,disable=disable, mode=whichOne,popvalue=str,value="don't print;print without units;print with units;print with units, K, m, etc"
//	FPScalebarHideShowDigits( whichOne == 1 )
//	
//	// digits
//	var		= NumVarOrDefault( df + "digits" , 6 )// popup number, 1 is the first item in the list.
	variable/G digits		= 6//var
//	whichOne	= var+1
//	str		= num2str( digits )
//	PopupMenu digits,win=ScalebarPn,disable=disable,mode=whichOne,popvalue=str,value= #"\"0;1;2;3;4;5;6;7;8;9;10;11;12;13;14;15;16;\""

	// color
	variable/G lineRed, lineGreen, lineBlue // default is conveniently 0,0,0 (black)
	PopupMenu color, win=ScalebarPn, disable=disable, popColor= (lineRed, lineGreen, lineBlue)
	
	// lines
	//		line size
	list		= "0.25;0.5;1;1.5;2;3;4;5;6;7;8;9;10;"
	var		= NumVarOrDefault( df + "lineSize", 2 )
	variable/G lineSize = 2//var
	str		= num2str( var )
	whichOne	= WhichListItem( str, list ) + 1
	PopupMenu lineSize, win=ScalebarPn, disable=disable, mode=whichOne, popvalue=str, value="0.25;0.5;1;1.5;2;3;4;5;6;7;8;9;10;"
	
	// layer
	list		= "window background;ProgBack;UserBack;axes;ProgAxes;UserAxes;traces;ProgFront;UserFront;annotations"
	str		= StrVarOrDefault( df + "layer" , "UserFront" )// popup string
	string/G layer = str
	whichOne	= WhichListItem(str, list)+1
	PopupMenu layer,win=ScalebarPn,mode=whichOne,popvalue=str,value= #"\"\\M1:(:window background;ProgBack;UserBack;\\M1:(:axes;ProgAxes;UserAxes;\\M1:(:traces;ProgFront;UserFront;\\M1:(:annotations\""

	// buttons
	Button 	AddSclBar 	win=ScalebarPn,disable=disable

	SetDataFolder oldDF
End


//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function		FPScalebarShowAxisCheckProc( ctrlName, bChecked ) : CheckBoxControl
// a generic routine which processes all  checkboxes of type 'Show/Hide axis'  = works for X and Y
	string		ctrlName
	variable	bChecked
	FPScalebarShowHideAxis( "", stringmatch( ctrlName, "xShowAxis" ), bChecked )		// isX
End


Function		FPScalebarShowHideAxis( graphName, isX , bChecked )		// isX
	string		graphName
	variable	isX, bChecked
	
	if ( strlen( graphName ) == 0 )			// if no graphName  has been passed... 
		graphName	= WinName( 0, 1 )	//...try to use the top graph
		if ( strlen( graphName ) == 0 )		// if there is no top graph..
			return 0					//...do nothing
		endif
	endif

	string		axisVarName
	if ( isX )
		axisVarName	= "xAxis"
	else
		axisVarName	= "yAxis"
	endif
	string		axes		= HVAxisList( graphName, isX ) + "_none_;"		// e.g. 'left;right1;right2;_none_;'  could be the list of the current vertical axes
	// the 'yAxis' listbox/popupmenu  should have stored  in the string 'root:Packages:FPScalebar:" + graphName + ":yAxis'  the currently selected...
	//...vertical axis e.g. 'right1' or 'left'  . If the axis name has not yet been stored there we use the first entry in the axis list e.g. 'left' or '_none_' 
	string		axis		= StrVarOrDefault( FPScalebarDF_Var( graphName, axisVarName ), StringFromList( 0, axes ) )

	GetAxis/W=$graphName/Q $axis			// check if axis exists
	// printf "\tFPScalebarShowHideAxis( '%s', isX:%d )\taxes:%s\taxis:%s  does %s exist \r",  graphName, isX,  UFCom_pd(axes,20),  UFCom_pd(axis,7), SelectString( V_Flag, "", "NOT" )
	if ( V_Flag == 0 ) 						// axis does exist
		if ( bChecked  == 0 )
		// todo  2. save settings
			ModifyGraph	noLabel( $axis )	= kNOLABELS	// remove the axis units (for the rare case when they have not been hidden before, because they are displayed as a textbox) 
			ModifyGraph	tick( $axis )	= kNOTICKS	// remove the axis ticks
			ModifyGraph	axThick( $axis )	= 0			// another way to remove the axis
			// printf "\tFPScalebarShowHideAxis( '%s', isX:%d )  :  AnnotationList(=Axes names): '%s' \r", graphName, isX, AnnotationList( "")
			TextBox  /C /V=0 /N=$axis					// make the textbox invisible. It must have the same name as the axis and it contains the units (and possibly the channel name)

		else
		// todo  2. restore settings
			ModifyGraph	noLabel( $axis )	= kNORMAL_LABELS
			ModifyGraph	tick( $axis )	= cTICKS_OUTSIDE
			ModifyGraph	axThick( $axis )	= 1
			TextBox  /C /V=1 /N=$axis					// make the textbox visible again
		endif
	endif
End


Function		FPScalebarShowToolsProc( ctrlName, bChecked ) : CheckBoxControl
	string		ctrlName
	variable	bChecked
	string		sTopGraph	= WinName( 0, 1 )
	if ( strlen( sTopGraph ) == 0 )
		return 0
	endif
	if ( bChecked )
		ShowTools /W=$sTopGraph /A arrow	
	else
		HideTools	/W=$sTopGraph  /A 
	endif
End

//Function		FPScalebarNumPopMenuProc( ctrlName, popNum, popStr ) : PopupMenuControl
//	string 	ctrlName
//	variable 	popNum
//	string 	popStr
//	FPScalebarHideShowDigits( popNum==1 )
//	FPScalebarSetGlobalFromCtrl( ctrlName, popNum, popStr )
//End

//Function		FPScalebarHideShowDigits( hideDigits )
//	variable	hideDigits
//	DoWindow ScalebarPn
//	if ( V_Flag )
//		PopupMenu digits, win=ScalebarPn, disable=hideDigits	
//	endif
//End

Function		FPScalebarColorPop(ctrlName,popNum,popStr) : PopupMenuControl
	string 	ctrlName
	variable 	popNum
	string 	popStr
	string		topGraph	= WinName( 0, 1)
	if ( strlen( topGraph ) == 0 )
		return 0
	endif
	ControlInfo/W=ScalebarPn $ctrlName
	if ( V_Flag )
		// update the global color variables
		variable/G $FPScalebarDF_Var(topGraph,"lineRed")	= V_Red
		variable/G $FPScalebarDF_Var(topGraph,"lineGreen")	= V_Green
		variable/G $FPScalebarDF_Var(topGraph,"lineBlue")	= V_Blue
	endif
End


//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//   GENERIC  dialog  routines

Function		FPScalebarPopMenuProc( ctrlName, popNum, popStr) : PopupMenuControl
// a GENERIC routine which processes all popmenus : will update the string  'folder:ctrlName'  with 'popStr'  or the variable 'folder:ctrlName'  with 'popNum'  
	string		ctrlName
	variable	popNum
	string		popStr
	FPScalebarSetGlobalFromCtrl( ctrlName, popNum, popStr )	// update the global string or variable with the same name as ctrlName with either popNum or popStr
	
End

Function		FPScalebarStr2NumPopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
// a generic routine which processes all popmenus : will update the variable 'folder:ctrlName'  with the numeric value of the 'popStr' 
	string		ctrlName
	variable	popNum
	string		popStr
	FPScalebarSetGlobalFromCtrl( ctrlName, str2num( popStr ), popStr )
End


Function		FPScalebarCheckProc( ctrlName, bChecked ) : CheckBoxControl
// a generic routine which processes all checkboxes
	string		ctrlName
	variable	bChecked
	FPScalebarSetGlobalFromCtrl( ctrlName, bChecked, num2str( bChecked ) )	// update the global string or variable with the same name as ctrlName with either popNum or popStr
End

Function		FPScalebarSetGlobalFromCtrl( ctrlName, num, str )
// update the global string or variable with the same name as ctrlName with either popNum or popStr
	string		ctrlName
	variable	num
	string		str
	string 	topGraph	= WinName( 0, 1 )
	if ( strlen( topGraph ) == 0 )
		return 0
	endif
	string		path	= FPScalebarDF_Var( topGraph, ctrlName )
	svar	/Z 	sv	= $path
	nvar	/Z	vr	= $path
	if ( svar_Exists( sv ) )
		sv	= str
	elseif ( nvar_Exists( vr ) )
		vr	= num
	endif
End

Function		FPScalebarPositionRadio( ctrlName, checked ) : CheckBoxControl
	string	ctrlName
	variable	checked

//	Checkbox upperLeft 		win=ScalebarPn, value=stringmatch( ctrlName,"upperLeft")
//	Checkbox upperRight 	win=ScalebarPn, value=stringmatch( ctrlName,"upperRight")
	Checkbox lowerLeft		win=ScalebarPn, value=stringmatch( ctrlName, "lowerLeft" )
	Checkbox lowerRight		win=ScalebarPn, value=stringmatch( ctrlName, "lowerRight" )
	Checkbox lowerLftInside	win=ScalebarPn, value=stringmatch( ctrlName, "lowerLftInside" )	// must not contain 'lowerLeft'	
	Checkbox lowerRghtBelow	win=ScalebarPn, value=stringmatch( ctrlName, "lowerRghtBelow" )// must not contain 'lowerRight'	

	string		topGraph= WinName( 0, 1 )
	if ( strlen( topGraph ) == 0 )
		return 0
	endif
	string/G $FPScalebarDF_Var( topGraph, "orientation" ) = ctrlName // store name of control clicked last.
End

Function		FPScalebarAutoValueButtonProc( ctrlName ) : ButtonControl
	string		ctrlName
	FPScalebarSetAutoValueLength( "", stringmatch( ctrlName, "xNiceVal" ) )	// isX
End


Function		FPScalebarSetAutoValueLength( graphName, isX )
	string		graphName
	variable	isX
	if ( strlen( graphName ) == 0 )			// if no graphName  has been passed... 
		graphName	= WinName( 0, 1 )	//...try to use the top graph
		if ( strlen( graphName ) == 0 )		// if there is no top graph..
			return 0					//...do nothing
		endif
	endif
	variable	length	= FPScalebarGetAutoValueLength( graphName, isX )
	string		lengthVarName
	if ( isX )
		lengthVarName	= "xLength"
	else
		lengthVarName	= "yLength"
	endif
	variable/G $FPScalebarDF_Var( graphName, lengthVarName ) = length		// create and initialize an auto-named global variable, in this case 'xLength' or 'yLength'...
	return	length											// ...buried in the folder  'root:Packages:FPScalebar:" + graphName + ":" 
End


Function		FPScalebarGetAutoValueLength( graphName, isX )
	string		graphName				// must exist
	variable	isX

	string		lengthVarName, axisVarName
	if ( isX )
		lengthVarName	= "xLength"
		axisVarName	= "xAxis"
	else
		lengthVarName	= "yLength"
		axisVarName	= "yAxis"
	endif

	variable	length	= 0
	string		axes		= HVAxisList( graphName, isX ) + "_none_;"		// e.g. 'left;right1;right2;_none_;'  could be the list of the current vertical axes
	// the 'yAxis' listbox/popupmenu  should have stored  in the string 'root:Packages:FPScalebar:" + graphName + ":yAxis'  the currently selected...
	//...vertical axis e.g. 'right1' or 'left'  . If the axis name has not yet been stored there we use the first entry in the axis list e.g. 'left' or '_none_' 
	string		axis		= StrVarOrDefault( FPScalebarDF_Var( graphName, axisVarName ), StringFromList( 0, axes ) )
	GetAxis/W=$graphName/Q $axis
	if ( V_Flag == 0 ) 						// axis exists
		length		= FPScalebarNiceNumber( abs( V_max - V_min ) / 5 )
		// printf "\tFPScalebarGetAutoValueLength( '%s', isX:%d )\taxes:%s\taxis:%s  Max:%d   \tMin:%d  -> NiceValue:%d  \r",  graphName, isX, UFCom_pd(axes,20), UFCom_pd(axis,7), V_max, V_min, length
	else
		// printf "\tFPScalebarGetAutoValueLength( '%s', isX:%d )\taxes:%s\taxis:%s  does NOT exist \r",  graphName, isX,  UFCom_pd(axes,20),  UFCom_pd(axis,7)
	endif
	return	length
End


Function		FPScalebarEraseAllSclbarProc( ctrlName ) : ButtonControl
	string		ctrlName
	ControlInfo/W=ScalebarPn layer
	// printf "\tFPScalebarEraseProc( '%s' )    erases  '%s'   in top graph '%s' \r",  ctrlName ,  S_Value ,  WinName( 0, 1 ) 
	FPScalebarEraseLayer( WinName( 0, 1 ), S_Value )
End

Function		FPScalebarEraseLayer( win, layerName )
	string		win, layerName
	if ( strlen(win) )
		DoWindow $win
		if ( V_Flag )
			string oldLayerName= FPScalebarCurrentDrawLayer( win )
			SetDrawLayer/K/W=$win $layerName
			SetDrawLayer/W=$win $oldLayerName
		endif
	endif
End


Function		FPScalebarAddSclbarProc(ctrlName) : ButtonControl
	string		ctrlName
	string		topGraph	= WinName( 0, 1 )
	if ( strlen( topGraph ) == 0 )
		return 0
	endif
	FPScalebarAddNewInGraph( topGraph )
End


Function		FPScalebarAddNewInGraph( graphName )
	string		graphName
	DoWindow $graphName
	if ( V_Flag == 0 )
		return 0
	endif
	// gather the parameters from the graph's data folder rather than fron the controls
	string 	oldDF	= FPScalebarSetDF(graphName)
	svar		xAxis, yAxis
	nvar		xShowBar, yShowBar
	nvar		xLength, yLength
	svar		orientation
	nvar		units, digits
	nvar		lineRed, lineGreen, lineBlue
	nvar		lineSize
	svar		layer
	
	SetDataFolder oldDF

	string		oldLayerName= FPScalebarCurrentDrawLayer( graphName )
	SetDrawLayer/W=$graphName $layer

	FPScalebarAddNew( graphName, xAxis, yAxis,xShowBar ? xLength : 0,yShowBar ? yLength : 0,orientation,units,digits, lineSize, lineRed, lineGreen, lineBlue )
	
	// ShowTools/W=$graphName/A arrow			// commented out by UF
	// SetDrawLayer/W=$graphName $oldLayerName	// nope, we want the user to be able to edit the layer the Scalebar is in. (has been commented out by WM)
End


Function	/S	FPScalebarCurrentDrawLayer(win)
	string		win
	
	string		layer	="UserFront" 			// graph default
	if ( WinType(win) == 7 )				// panel
		layer= "ProfFront"				//??????????????  ProgFront?????????panel default
	endif
	string		code	= WinRecreation( win, 4 )	// don't revert to normal mode
	variable	lines	= ItemsInList( code, "\r" )
	variable	line
	for( line=0; line < lines; line+=1)
		string		cmd	= StringFromList(line,code,"\r")
		// look for a line like "	SetDrawLayer ProgAxes"
		variable	pos	= strsearch(cmd,"SetDrawLayer",0)
		if ( pos > 0 )
			pos= strsearch(cmd," ",pos)
			layer=cmd[pos+1,999]		// keep going, we get the last (current layer)
		endif	
	endfor
	return layer
End


// Usage:	nvar foo= $FPScalebarDF_Var(graphName,varName)
// 		svar foo= $FPScalebarDF_Var(graphName,varName)
Function	/S	FPScalebarDF_Var( graphName, varName )
	string		graphName, varName
	return 	"root:Packages:FPScalebar:" + graphName + ":" + varname
End

// returns the old data folder
Function	/S	FPScalebarSetDF( graphName )
	string		graphName
	
	string		oldDF= GetDataFolder(1)
	NewDataFolder/O root:Packages
	NewDataFolder/O/S root:Packages:FPScalebar
	NewDataFolder/O/S $graphName
	return	oldDF
End

Function		FPScalebarAddNew( graphName, xaxis, yaxis, dx, dy, orientation, units, digits, penSize, red, green, blue )
	string		graphName
	string		xaxis,yaxis
	variable/D	dx,dy
	string		orientation	// "upperLeft", etc.
	variable	units	// 	menu popup item:"don't print;print without units;print with units;print with units, K, m, etc"
	variable	digits
	variable	penSize
	variable	red,green,blue
	
	if ( strlen( graphName ) == 0 )
		graphName	= WinName( 0 ,1 )
		if ( strlen( graphName ) == 0 )
			return 0
		endif
	endif
	// Put Scalebar in upper right corner of graph
	variable xorig,yorig	// corner of Scalebar
	variable px,py		// polygon origin
	variable hx,hy,vx,vy	// text origins
	variable sf=0.15		// inset from upper-right corner
	variable tmp
	GetAxis/W=$graphName/Q $xaxis		// V_Min is actually the left value, V_Max the right value
	xorig		= V_max - (V_max - V_min) * sf
	variable	xReversed = V_Max < V_Min	// that is, right value < left value
	if ( xReversed )
		dx= -dx
	endif
	
	GetAxis/W=$graphName/Q $yaxis		// V_Min is actually the bottom value, V_Max the top value
	yorig	= V_max-(V_max-V_min)*sf
	variable yReversed = V_Max < V_Min	// that is, top value < bottom value
	if ( yReversed )
		dy= -dy
	endif

	GraphNormal/W=$graphName			// Forces deselection
	SetDrawEnv/W=$graphName gstart		// gstart can't be on next line!
	SetDrawEnv/W=$graphName xcoord= $xaxis, ycoord= $yaxis, fillpat=0, linethick=penSize, linefgc=(red,green,blue)
	strswitch ( orientation )
//		case "upperLeft":
//			xorig -= dx
//			hx= xorig + dx/2
//			vy= yorig - dy/2
//			px= xorig;py=yorig-dy
//			DrawPoly/W=$graphName px,py, 1, 1, {0,0,0,dy,dx,dy}
//			break
//		case "upperRight":
//			hx= xorig - dx/2
//			vy= yorig - dy/2
//			px= xorig-dx;py=yorig
//			DrawPoly/W=$graphName px,py, 1, 1, {0,0,dx,0,dx,-dy}
//			break
		case "lowerRight":
			yorig -= dy
			hx	= xorig - dx/2
			vy	= yorig + dy/2
			px	= xorig;py=yorig+dy
			DrawPoly/W=$graphName px,py, 1, 1, {0,0,0,-dy,-dx,-dy}
			break
		case "lowerLeft":
			xorig -= dx
			yorig -= dy
			hx	= xorig + dx/2
			vy	= yorig + dy/2
			px	= xorig+dx;py=yorig
			DrawPoly/W=$graphName px,py, 1, 1, {0,0,-dx,0,-dx,dy}
			break
		case "lowerRghtBelow":
			yorig -= dy
			hx	= xorig - dx/2
			vy	= yorig + dy/2
			px	= xorig;py=yorig+dy
			DrawPoly/W=$graphName px,py, 1, 1, {0,0,0,-dy,-dx,-dy}
			break
		case "lowerLftInside":
			xorig -= dx
			yorig -= dy
			hx	= xorig + dx * .5
			vy	= yorig + dy * .7		// dy * .7  instead of  dy * .5  leaves room for 2 lines
			px	= xorig+dx;py=yorig
			DrawPoly/W=$graphName px,py, 1, 1, {0,0,-dx,0,-dx,dy}
			break
	endswitch
	
	string		sXLabelVal = "", sYLabelVal = "", fmt, sUnits
	// vertical Scalebar value	must be computed first as it is used together with the horizontal value in the 'lowerRghtBelow' mode
	if ( ( dy != 0 )   &   ( units > 1 ) )						// (bitwise AND, not logical AND)
		fmt	= FPScalebarNumberFormat( graphName, yaxis, units, digits )
		sprintf sYLabelVal, fmt, abs(dy)
		vx	= xorig
		variable xj = 0, rot = 0							// left aligned text  , 	use rot= -90 for top-to-bottom
		if ( stringmatch( orientation, "*left" ) )
			xj	= 2								// right aligned text ,	use rot=90 for bottom-to-top
		endif
		if ( stringmatch( orientation, "*lftInside" ) )
			xj	= 0								// left aligned text  ,	use rot=90 for bottom-to-top
		endif
		if ( ! stringmatch( orientation, "lowerRghtBelow" ) )	
			SetDrawEnv/W=$graphName xcoord= $xaxis, ycoord= $yaxis, textxjust= xj, textyjust=1, textrot=rot, textrgb=(red,green,blue)
			DrawText/W=$graphName vx, vy,  " " + sYLabelVal + " "	// extra spaces to keep label away from line
		endif
	endif
	// horizontal Scalebar value
	if ( ( dx != 0 )   &   ( units > 1 ) )						// units == 1  means  don't print,  (bitwise AND, not logical AND)
		fmt	= FPScalebarNumberFormat( graphName, xaxis, units, digits )
		sprintf sXLabelVal, fmt, abs(dx)
		hy 	= yorig
		variable yj = 0								// bottom aligned text  ,
		if ( stringmatch( orientation, "lower*" ) )				// 'upperLeft; upperRight; lowerRight; lowerLeft; lowerRghtBelow; lowerLftInside"
			yj	= 2								// top  aligned text  ,
		endif
		SetDrawEnv/W=$graphName xcoord= $xaxis, ycoord= $yaxis, textxjust= 1, textyjust=yj, textrgb=(red,green,blue)
		if ( stringmatch( orientation, "lowerRghtBelow" ) )	
			DrawText/W=$graphName hx,hy, sXLabelVal + " / " + sYLabelVal
		else
			DrawText/W=$graphName hx,hy, sXLabelVal
		endif
	endif
	SetDrawEnv/W=$graphName gstop
End


Function	/S	FPScalebarNumberFormat( graphName, axis, units, digits )
	string		graphName, axis
	variable	units						// menu popup item:"don't print;print without units;print with units;print with units, K, m, etc"
	variable	digits

	string		fmt
	sprintf	fmt, "%%.%dg", digits				// "%.6g", usually
	
	string		sUnits	= FPScalebarAxisUnits( graphName, axis )
		
	if ( ( units == 3 )  &  ( strlen( sUnits ) > 0 ) )		// 3 is print with units	(bitwise AND)
		fmt +=  " " + sUnits
	endif
	if ( units == 4 )						// 4 is print with units and prefixes
		sprintf	fmt, "%%.%gW1P%s", digits, sUnits
	endif
	return fmt
End


Function	/S	FPScalebarAxisUnits( graphName, axis )
	string		graphName
	string		axis
	string		sInfo, sUnits = ""
	variable	pos, en
	
	sInfo	= AxisInfo( graphName, axis )
	pos	= strsearch( sInfo, "UNITS:", 0 )
	if ( pos >= 0 )
		en	= strsearch( sInfo, ";" , pos )
		if ( en > pos )
			sUnits	= sInfo[ pos + 6, en - 1]
		endif
	endif
	// printf "\tFPScalebarAxisUnits( %s\t%s\t):  pos:%3d\tUnits:%s\tsInfo:'%s' \r", UFCom_pd( graphName, 7), UFCom_pd( axis,6 ), pos, UFCom_pd( sUnits,12 ),  sInfo[0,170]
	return	sUnits
End


// round to 1, 2, or 5 * 10eN, non-rigorously
Function		FPScalebarNiceNumber( num )
	variable	num
	
	if ( num == 0 )
		return 0
	endif
	variable	theSign	= sign(num)
	num				= abs(num)
	variable	lg		= log(num)
	variable	decade	= floor(lg)
	variable	frac		= lg - decade
	variable	mant
	if ( frac < log(1.5) )		// above 1.5, choose 2
		mant= 1
	else
		if ( frac < log(4) )		// above 4, choose 5
			mant= 2
		else
			if ( frac < log(8) )	// above 8, choose 10
				mant= 5
			else
				mant= 10
			endif
		endif
	endif
	num	= theSign * mant * 10^decade
	return num
End


