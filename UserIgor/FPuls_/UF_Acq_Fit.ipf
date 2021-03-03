//  UF_Acq_Fit.ipf 

// TO BE REMOVED  ....(LatCnt muss weg)
//REPLACE		UFPE_DoFit( sFolders, ch, rg, fi, LatCnt )	by	UFPE_DoFit_( sFolders, ch, rg, fi... )
//REPLACE		UFPE_OneFit( ........				 )	by	UFPE_OneFit_(........)

// 

#pragma rtGlobals=1							// Use modern global access method.


//
//// Popupmenu indexing for the fit range
//static constant		FR_WINDOW	= 0, FR_CSR = 1, FR_PEAK = 2
//strconstant      	  	UFPE_klstFITRANGE	= "Windw;Cursor;Peak"										// Igor does not allow this to be static

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function		UFPE_DoFit( sFolders, ch, rg, fi, LatCnt )
// Returns the state of the   1. Fit -    or  2. Fit - checkbox.  Another approach: 'ControlInfo'
	string  	sFolders	
	variable 	ch, rg, fi, LatCnt
	variable	bFit	= UFPE_CursorIsSet( sFolders, ch, rg, UFPE_kCSR_FIT, fi, UFPE_CN_BEG, LatCnt )  &&  UFPE_CursorIsSet( sFolders, ch, rg, UFPE_kCSR_FIT, fi, UFPE_CN_END, LatCnt )
	return	bFit
End

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function		 UFPE_OneFit( sFolders, sWnd, wOrg, ch, rg, fi, BegPt, SIFact, rlstFitResults, LatCnt, FitCnt )
	string  	sFolders, sWnd
	wave	wOrg
	variable	ch, rg, fi
	variable	BegPt, SIFact
	variable	LatCnt, FitCnt 
	string  	&rlstFitResults				// will be returned
	variable	rLeft, rRight
	string  	sMsg, sTNL
	variable	bSuccessfulFit	= UFCom_TRUE											// will return UFCom_TRUE if fit is off but when it is on and only start values have been checked UFCom_FALSE will be returned

	variable	bFit	= UFPE_DoFit( sFolders, ch, rg, fi, LatCnt )
	if ( bFit )
		variable	nFitFunc	= UFPE_FitFnc_( sFolders, ch, rg, fi )
		//variable	nFitFunc	= FitFncFromPopup( ch, rg, fi )
		//variable	/G	root:uf:eva:de:fit:gFitFunc	= nFitFunc							// Igor requires this to be global for 'FitMultipleFunctionsEval()'  but to be used only locally
		//nvar			gFitFunc				= root:uf:eva:de:fit:gFitFunc

		// Construct additional waves for the fit start parameters and for derived parameters e.g. capacity
		variable	nPars			= UFPE_ParCnt( nFitFunc )
		variable	nFitInfos			= UFPE_FitInfoCnt()
		string  	sFoInfoNm			= FoInfoNm( sFolders, ch, rg, fi )
		string  	sFoParNm			= UFPE_FoParNm_( sFolders, ch, rg, fi )					// the wave name is indexed with channel, region and fit
		string  	sFoStaParNm		= FoStaParNm( sFolders, ch, rg, fi )
		string  	sFoDerParNm		= FoDerParNm( sFolders, ch, rg, fi )
		string  	sFitChanSubFolder	= FitChanSubFolderNm( ch )
		wave	/Z /D  wPar	= $sFoParNm									// the wave name is indexed with channel, region and fit
		wave	/Z /D  wStaPar	= $sFoStaParNm							
		wave	/Z /D  wDerPar	= $sFoDerParNm				

		// 2006-0410  We  MUST  check whether the number of parameters has changed (or if the user has changed the fitting function and the new function has a different number of params).
		// If true we MUST redimension 'wPar'  to the new value or the fit may often (not always) run wild. Note also: Evaluate 'numPnts( wPar )'  last, AFTER  the  existence of 'wPar' has been checked!
		// Another approach (not taken): Incorporate  'nFitFunc'  in  ' UFPE_FoParNm( sFolders, ch, rg, fi )'  ->  ' UFPE_FoParNm( sFolders, ch, rg, fi, nFitFunc )'  so that there is different name for each fit function. Then we would not have to check  the condition  'numPnts( wPar ) != nPars'
		// if ( ! waveExists( wPar )  ||  ! waveExists( wStaPar )   ||  ! waveExists( wDerPar ) )	// WRONG
		if (	! waveExists( wPar )  ||  ! waveExists( wStaPar )   ||  ! waveExists( wDerPar )    ||    numPnts( wPar ) != nPars  )
			UFCom_ConstructAndMakeCurFoldr( RemoveEnding( "root:uf:" + sFolders + sFitChanSubFolder, ":" ) )
			make /O  /D /N=( nPars )	$sFoParNm		= 0		
			make /O  /D /N=( nPars )	$sFoStaParNm		= nan	
			make /O  /D /N=( nPars )	$sFoDerParNm		= nan	
			make /O 	    /N=(nFitInfos)	$sFoInfoNm		= 0						// to hold   V_FitError, V_FitNumIters, V_FitMaxIters, V_chisq 
		endif
		wave	/D 	wPar	   	= 	$sFoParNm								// the wave name is indexed with channel, region and fit
		wave	/D 	wStaPar	= 	$sFoStaParNm				
		wave	/D 	wDerPar	= 	$sFoDerParNm				
		wave	 	wInfo	= 	$sFoInfoNm				

		// Construct additional waves for displaying the fitted function
		rLeft		= UFPE_CursorX( sFolders, ch, rg, UFPE_Csr2Ph( sFolders, UFPE_kCSR_FIT, fi, LatCnt ), UFPE_CN_BEG )		// get the beginning and the end of the Fit evaluation region (=rLeft and rRight)
		rRight	= UFPE_CursorX( sFolders, ch, rg, UFPE_Csr2Ph( sFolders, UFPE_kCSR_FIT, fi, LatCnt ), UFPE_CN_END )

		variable	bOnlyStartValsNoFit		= OnlyStartValsNoFit( sFolders )				// 0 : do the fit,  1 : display only starting values but do no fitting

		variable	PtLeft	= BegPt + rLeft   / SIFact								// in EVAL : BegPt=0 , nSFact=1
		variable	PtRight	= BegPt + rRight / SIFact
		duplicate /O /R=( PtLeft, PtRight )  wOrg   $"root:uf:" + sFolders + UFPE_ksF_FIT + ":wFitted"	// Extract the segment to be fitted. It extends still over the old xLeft..xRight. range.
		duplicate /O /R=( PtLeft, PtRight )  wOrg   $"root:uf:" + sFolders + UFPE_ksF_FIT + ":wPiece"	// Igor requires that wFitted has same length as source wave

		wave		wFitted	= $"root:uf:" + sFolders + UFPE_ksF_FIT + ":wFitted"
		wave		wPiece	= $"root:uf:" + sFolders + UFPE_ksF_FIT + ":wPiece"
		SetScale /I X, 0,  rRight - rLeft , "", wFitted									// Shift the wave so that it starts at 0. This makes fitting easier. Must be shifted back after fitting...
		SetScale /I X, 0,  rRight - rLeft , "", wPiece
		// printf "\t UFPE_OneFit(a '%s'\tleft:\t%6.3lf..\t%7.3lf\tch:%d  rg:%d  fi:%d)\tnFitFunc:%d  \t%s\tdxOrg:%g\tPts(wOrg):\t6d\tPts(fit):\t%6d\tFitRes:\t'%s' \r",sFolders, rLeft, rRight, ch, rg, fi, nFitFunc, UFCom_pd(  UFPE_FitFuncNm( nFitFunc ), 9 ) , deltax(wOrg), numPnts(wOrg), numPnts(wFitted), lstFitResults


		//  EVAL :   'UFPE_SetStartParams()' ,  'FuncFit FitMultipleFunctionsEval'  and  'wFitted'  work  with  TRUE TIMES
		bSuccessfulFit	= UFCom_FALSE												// will also return UFCom_FALSE if no fit has been done as only start values have been checked
		variable	bStartOK	= UFPE_SetStartParams( sFolders, wPar, wPiece, ch, rg, fi, nFitFunc, rLeft, rRight )	// stores results in  wPar
		if ( bStartOK )
			wStaPar	= wPar												// The fit will overwrite  wPar  but  we want to keep the starting values to check how good the initial guesses were.  See  PrintFitResults() below.  
		
// todo 060321 in acq:pul
			variable	FitMaxIters		= MaxIters( sFolders )							// used as an indicator whether the fit converged or not
			variable	FitNumIters	= 0
			variable	FitError		= 0										// do not stop or break into the debugger when fit fails
			variable	FitQuitReason
			variable 	FitOptions		= 4										// Bit 2: Suppresses the Curve Fit information window . This may speed things up a bit...
			variable	FitChisq		= 0

			if ( bOnlyStartValsNoFit )

// 2006-0321
//				FuncFit /O	/N/ Q 	FitMultipleFunctionsEval, wPar, wPiece  /D= wFitted	// display only starting values, do not fit	
				UFPE_FitMultipleFunctions( bOnlyStartValsNoFit, nFitFunc, wPar, wPiece, wFitted, FitOptions, FitMaxIters, FitNumIters, FitError, FitQuitReason, FitChisq )	// display only starting values, do not fit	

			else			
//				nvar		nMaxIter		= root:uf:" + sFolders + ":gFitMaxIter0000
//				variable	V_FitMaxIters	= nMaxIter								// used as an indicator whether the fit converged or not
//				variable	V_FitNumIters	= 0
//				variable	V_FitError		= 0									// do not stop or break into the debugger when fit fails
//				variable	V_FitQuitReason
	
// 2006-0321
//				FuncFit /N /Q /W=1 FitMultipleFunctionsEval, wPar, wPiece  /D= wFitted 	// do the fitting
				UFPE_FitMultipleFunctions( bOnlyStartValsNoFit, nFitFunc, wPar, wPiece, wFitted, FitOptions, FitMaxIters, FitNumIters, FitError, FitQuitReason, FitChisq  )	// do the fitting

				bSuccessfulFit	= FittingWasSuccessful( FitError, FitNumIters, FitMaxIters )
				if ( bSuccessfulFit )
					variable	Rser	= UFPE_Rser_mV( sFolders, ch, rg ) 
					UFPE_ComputeDerivedParams( sFolders, wPar, wDerPar, ch, rg, fi, nFitFunc, Rser )
				else
					// Design issue: keep the fitted values even if the fit failed (they may be close to the optimum values but can also be completely false)   OR  discard them by setting them to  Nan
					ResetFitResult( sFolders, ch, rg, fi ) 	// set the fitted values to  Nan  if the fit failed for any reason (even if the values may be acceptable)
					sprintf sMsg, "\tFit failed : ch:%2d,  rg:%2d,  fit:%2d,  Iterations: %d / %d ,\tV_FitError:%d,  V_FitQuitReason:%d [Bit0..3:Any error,SingMat,OutOfMem,NanOrInf]", ch, rg, fi, FitNumIters, FitMaxIters, FitError, FitQuitReason	
					string  sFo	= StringFromList( 0, sFolders, ":" ) 	// e.g  'eva:de'  -> 'eva' , 'acq:pul' -> 'acq'  
					UFCom_Alert( UFCom_kERR_IMPORTANT,  sMsg )
				endif
			endif
			if ( bOnlyStartValsNoFit  ||  bSuccessfulFit )

				string  	sFittedRangeNm	= "wF_r" + num2str( rg ) + "_p" + num2str( fi ) 
				string		sFoFittedRangeNm	= "root:uf:" + sFolders + sFitChanSubFolder + sFittedRangeNm	// Make new wave e.g. 'fit:c1:wF0_r1_p0'   and fill it with an extracted segment
				wave	/Z	wF			= $sFoFittedRangeNm
				if ( ! waveExists( wF ) )
					UFCom_ConstructAndMakeCurFoldr( RemoveEnding( "root:uf:" + sFolders + sFitChanSubFolder, ":" ) )
				endif

				duplicate /O 		wFitted	$sFoFittedRangeNm								//..(=the fitted range) of the fitted wave. In the new wave the fitted range starts with point 0 . 
				SetScale /I X, rLeft,  rRight , "",  $sFoFittedRangeNm								// Shift the wave back so that it starts again at  'rLeft'

				variable	rRed, rGreen, rBlue
				UFPE_EvalColor_( sFolders, UFPE_kCSR_FIT, fi , rRed, rGreen, rBlue )
				if ( WinType( sWnd ) == UFCom_WT_GRAPH ) 											// the user may have killed the window
					sTNL	= TraceNameList( sWnd, ";", 1 )
					if ( WhichListItem( sFittedRangeNm, sTNL, ";" )  == UFCom_kNOTFOUND )				// ONLY if  wave is not in graph...
						AppendToGraph /W=$sWnd	 /C=( rRed, rGreen, rBlue )	$sFoFittedRangeNm
					endif
				endif
			endif
			// Display  /K=1 wFitted, wPiece					// ONLY for testing
		endif
		UFPE_SetFitInfo( wInfo, nFitFunc, rLeft, rRight, FitNumIters, FitMaxIters, FitChisq )
		rlstFitResults	= ListOfFitResults( sFolders, wInfo, ch, rg, fi, nFitFunc, bStartOK, FitError )
		sMsg			= PrintFitResultsIntoHistory( sFolders, wInfo, ch, rg, fi, nFitFunc, bStartOK, FitError )
		if ( strlen( sMsg ) )
			printf "%s \r" , sMsg
		endif
		
//ltl		// printf "\t\t\t UFPE_OneFit(  f\t%s\tch:%d rg:%d  FrSwp:\t%3d\tfi:%d\tBg:\t%5.3lfs\tEn:\t%5.3lf\t\t\t\t\tPts(wO):\t%7d\tBegPt:\t%7g\tdltax:\t%8.6lf\tSF:\t%7.4lf\t\t\t\t\tE-B:\t %6.3lf\tFn:%d %s\tPts:\t%7.2lf\tFitRes:\t'%s'\r", 
//sFolders,ch,rg,123, fi, rLeft, rRight, numPnts(wOrg), BegPt, deltax(wOrg), SIFact, rRight-rLeft, nFitFunc, UFCom_pd( UFPE_FitFuncNm( nFitFunc),8), numPnts(wFitted), rlstFitResults

	endif			// fit checkbox 
	return	bSuccessfulFit
End		// OneFit

