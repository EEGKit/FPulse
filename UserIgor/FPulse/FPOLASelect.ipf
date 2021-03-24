#pragma rtGlobals=1		
Function		IsQDP( sFolders, sNm )
	string  	sFolders
	string  	sNm
	variable	ch	= 0 , rg	= 0							
	string  	lst	= ListACV_QDP( sFolders , ch, rg ) 	
	variable	n, nItems	= ItemsInList( lst )
	for ( n = 0; n < nItems; n += 1 )
		if ( cmpstr(  StripPostFix( StringFromList( n, lst ) ) , sNm ) == 0 )
			return	TRUE
		endif
	endfor
	return	FALSE
End
static constant		kQDP_QUOTS		= 2		
static constant		kQDP_DIFFS		= 1
static constant		kQDP_PRODS		= 1
static strconstant	ksQDP_QUOT_BASE= "Q"  	
static strconstant	ksQDP_DIFF_BASE	= "Di"  	
static strconstant	ksQDP_PROD_BASE= "P"  	
static strconstant	klstQDP_QUOT_EXT	= "e;d;"  	
static strconstant	klstQDP_DIFF_EXT	= "a;s;"  	
static strconstant	klstQDP_PROD_EXT	= "f;m;"  	
Function	/S	ListACV_QDP( sFolders, ch, rg )
	string  	sFolders
	variable	ch, rg
	string  	sPostfx	= Postfix( ch, rg )
	string  	lst		= ""	
	variable	n
	string  	sNm
	for ( n = 0; n < kQDP_QUOTS; n += 1 )
		sNm	 =  QDPNm( ksQDP_QUOT_BASE, n )
		lst	+= sNm + sPostfx + ";"
	endfor
	for ( n = 0; n < kQDP_DIFFS; n += 1 )
		sNm	 =  QDPNm( ksQDP_DIFF_BASE, n )
		lst	+= sNm + sPostfx + ";"
	endfor
	for ( n = 0; n < kQDP_PRODS; n += 1 )
		sNm	 =  QDPNm( ksQDP_PROD_BASE, n )
		lst	+= sNm + sPostfx + ";"
	endfor
	return	lst
End
Function	/S	QDPNmExt( sBaseNm, n, ne, lstExt )
	string  	sBaseNm, lstExt
	variable	n, ne
	return	QDPNm( sBaseNm, n ) + StringFromList( ne, lstExt )	
End
Function	/S	QDPNm( sBaseNm, n )
	string  	sBaseNm
	variable	n
	return	sBaseNm + num2str( n )		
End
Function	/S	QDPNm2Base( sNm )
	string  	sNm
	variable	len	= strlen( sNm )			
	return	sNm[ 0, len-2 ] 
End
Function		QDPNm2Nr( sNm )
	string  	sNm
	variable	len	= strlen( sNm )
	return	str2num( sNm[ len-1, len-1 ] )	
End
Function	/S	Col2Nm( col )
	variable	col						
	string  	sNm
End
Function	/S	SubCol2SubNm( subcol )
	variable	subcol					
	variable	n, be, sc	= 0
	for ( n = 0; n < kQDP_QUOTS; n += 1 )
		for ( be = 0; be < ItemsInList( klstQDP_QUOT_EXT ); be += 1 )
			if ( sc == subcol )
				return	QDPNmExt( ksQDP_QUOT_BASE, n, be, klstQDP_QUOT_EXT )
			endif
			sc += 1
		endfor
	endfor
	for ( n = 0; n < kQDP_DIFFS; n += 1 )
		for ( be = 0; be < ItemsInList( klstQDP_DIFF_EXT ); be += 1 )
			if ( sc == subcol )
				return	QDPNmExt( ksQDP_DIFF_BASE, n, be, klstQDP_DIFF_EXT )
			endif
			sc += 1
		endfor
	endfor
	for ( n = 0; n < kQDP_PRODS; n += 1 )
		for ( be = 0; be < ItemsInList( klstQDP_PROD_EXT ); be += 1 )
			if ( sc == subcol ) 
				return	QDPNmExt( ksQDP_PROD_BASE, n, be, klstQDP_PROD_EXT )
			endif
			sc += 1
		endfor
	endfor
	return	""		
End
Function		SubNm2SubCol( sSubNm )
	string  	sSubNm					
	variable	subcol					
End
static strconstant	ksLB_QDPSRC_WNM		= "PnSelQDPSrc" 
static strconstant	ksLB_QDPSRC_CNM		= "LbSelQDPSrc" 
static constant		kLB_QDPSRC_COLWID_MAIN	= 62				
static constant		kLB_QDP_CW				= 28				
Function		LBSelectQDPSources( sFolders )
	string  	sFolders				
	string  	lstQDPSrcAllChs=  ListQDPSrcAllChs( klstEVL_QDPSRC ) 						
	variable	len, n, nItems	= ItemsInList( lstQDPSrcAllChs )	

	string 	sColTitle, lstColTitles	= ""				
	string  	lstColItems = ""
	string  	lstColChRg  = ""			
	variable	nExtractCh, ch = -1
	variable	nExtractRg, rg = -1 
	string 	sOneItemIdx, sOneItem
	for ( n = 0; n < nItems; n += 1 )
		sOneItemIdx	= StringFromList( n, lstQDPSrcAllChs )					
		len			= strlen( sOneItemIdx )
		sOneItem		= sOneItemIdx[ 0, len-4 ] 							
		nExtractCh	= str2num( sOneItemIdx[ len-2, len-2 ] )					
		nExtractRg	= str2num( sOneItemIdx[ len-1, len-1 ] )					
		if ( ch != nExtractCh )											
			ch 		= nExtractCh
 			rg 		= -1 
		endif
		if ( rg != nExtractRg )											
			rg 		  =  nExtractRg
			sprintf sColTitle, "%s Rg%2d", StringFromList( ch, LstChAcq(), ksSEP_TAB ), rg	
			lstColTitles	  =  AddListItem( sColTitle, 	 lstColTitles,   ksCOL_SEP, inf )	
			lstColChRg += SetChRg( ch, rg )								
			lstColItems	 += ksCOL_SEP
		endif
		lstColItems	+= sOneItem + ";"
	endfor
	lstColItems	= lstColItems[ 1, inf ] + ksCOL_SEP							
	variable	c, nCols	= ItemsInList( lstColItems, ksCOL_SEP )				
	variable	nRows	= 0
	string  	lstItemsInColumn
	for ( c = 0; c < nCols; c += 1 )
		lstItemsInColumn  = StringFromList( c, lstColItems, ksCOL_SEP )	
		nRows		  = max( ItemsInList( lstItemsInColumn ), nRows )
	endfor
	variable	nSubCols	= ( kQDP_QUOTS + kQDP_DIFFS + kQDP_PRODS ) * 2							

	variable	xSize		= nCols * ( kLB_QDPSRC_COLWID_MAIN + nSubCols * kLB_QDP_CW )	+ 30 	
	variable	ySizeMax	= GetIgorAppPixelY() -  kMAGIC_Y_MISSING_PIXEL- 0	
	variable	ySizeNeed	= max( 2, nRows ) * kLB_CELLY + kLB_ADDY			
	variable	ySize		= min( ySizeNeed , ySizeMax ) 						
	ySize	 =  trunc( ( ySize -  kLB_ADDY ) / kLB_CELLY ) * kLB_CELLY + kLB_ADDY	
		string  	sWin	= ksLB_QDPSRC_WNM
		if ( WinType( sWin ) != kPANEL )								
			NewPanel1( sWin, kRIGHT, -200, xSize, kTOP, 0, ySize, kKILL_ALLOW, "QDP Sources" )	
			make  /O 	/T 	/N = ( nRows, nCols*(1+nSubCols) )	$"root:uf:" + sFolders + ":wQDPSrcTxt"	= ""	
			wave   	/T		wTxt					     =	$"root:uf:" + sFolders + ":wQDPSrcTxt"
			make   /O	/B  /N = ( nRows, nCols*(1+nSubCols), 3 )	$"root:uf:" + sFolders + ":wQDPSrcFlags"	
			wave   			wFlags				    = 	$"root:uf:" + sFolders + ":wQDPSrcFlags"
			make /O	/W /U /N=(128,3) 	   	   $"root:uf:" + sFolders + ":wQDPSrcColors" 		
			wave	wColors		 		= $"root:uf:" + sFolders + ":wQDPSrcColors" 		
			EvalColors( wColors )		
			variable	planeFore	= 1
			variable	planeBack	= 2
			SetDimLabel 2, planeBack,  $"backColors"	wFlags
			SetDimLabel 2, planeFore,   $"foreColors"	wFlags
		else													
			MoveWindow /W=$sWin	1,1,1,1						
			MoveWindow1( sWin, kRIGHT, -3, xSize, kTOP, 0, ySize )		
			wave   	/T		wTxt			= $"root:uf:" + sFolders + ":wQDPSrcTxt"
			wave   			wFlags	  	= $"root:uf:" + sFolders + ":wQDPSrcFlags"
			Redimension	/N = ( nRows, nCols*(1+nSubCols) )		wTxt
			Redimension	/N = ( nRows, nCols*(1+nSubCols), 3 )		wFlags
		endif
		variable	w, lbCol
		for ( c = 0; c < nCols; c += 1 )								
			for ( w = 0; w <= nSubCols; w += 1 )						
				lbCol	= c * (nSubCols+1) + w
				if ( w == 0 )
					sColTitle	= StringFromList( c, lstColTitles, ksCOL_SEP )	
				else
					sColTitle	= SubCol2SubNm( w - 1 )  				
				endif
				SetDimLabel 1, lbCol, $sColTitle, wTxt
			endfor
		endfor
		variable	r
		for ( c = 0; c < nCols; c += 1 )
			if ( c == 0 )
				ListBox   	$ksLB_QDPSRC_CNM,    win = $ksLB_QDPSRC_WNM, 	widths  =	{ kLB_QDPSRC_COLWID_MAIN,  kLB_QDP_CW,  kLB_QDP_CW,  kLB_QDP_CW, kLB_QDP_CW,  kLB_QDP_CW,  kLB_QDP_CW, kLB_QDP_CW,  kLB_QDP_CW }	
			else
				ListBox 	$ksLB_QDPSRC_CNM,    win = $ksLB_QDPSRC_WNM, 	widths +=	{ kLB_QDPSRC_COLWID_MAIN,  kLB_QDP_CW,  kLB_QDP_CW,  kLB_QDP_CW, kLB_QDP_CW,  kLB_QDP_CW,  kLB_QDP_CW,  kLB_QDP_CW,  kLB_QDP_CW }	
			endif
			lstItemsInColumn  = StringFromList( c, lstColItems, ksCOL_SEP )	
			for ( r = 0; r < ItemsInList( lstItemsInColumn ); r += 1 )
				for ( w = 0; w <= nSubCols; w += 1 )			
					lbCol	= c *(nSubCols+1) + w
					if ( w == 0 )
						wTxt[ r ][ lbCol ]	= StringFromList( r, lstItemsInColumn )				
					else
						wTxt[ r ][ lbCol ]	= ""
					endif
				endfor
			endfor
			for ( r = ItemsInList( lstItemsInColumn ); r < nRows; r += 1 )
				for ( w = 0; w <= nSubCols; w += 1 )
					lbCol	= c * (nSubCols+1) + w
					wTxt[ r ][ lbCol ]	= ""
				endfor
			endfor
		endfor
		ListBox 	  $ksLB_QDPSRC_CNM,    win = $ksLB_QDPSRC_WNM, 	pos = { 2, 0 },  size = { xSize, ySize + kLB_ADDY },  frame = 2
		ListBox	  $ksLB_QDPSRC_CNM,    win = $ksLB_QDPSRC_WNM, 	listWave 			= $"root:uf:" + sFolders + ":wQDPSrcTxt"
		ListBox 	  $ksLB_QDPSRC_CNM,    win = $ksLB_QDPSRC_WNM, 	selWave 			= $"root:uf:" + sFolders + ":wQDPSrcFlags",  editStyle = 1
		ListBox	  $ksLB_QDPSRC_CNM,    win = $ksLB_QDPSRC_WNM, 	colorWave		= $"root:uf:" + sFolders + ":wQDPSrcColors"				
		ListBox 	  $ksLB_QDPSRC_CNM,    win = $ksLB_QDPSRC_WNM, 	proc 	 		 	= LbSelQDPSrcProc
End
Function		LbSelQDPSrcProc( s ) : ListBoxControl
	struct	WMListboxAction &s
	string  	sFolders		= "acq:pul"
	wave	wFlags		= $"root:uf:" + sFolders + ":wQDPSrcFlags"
	wave   /T	wTxt			= $"root:uf:" + sFolders + ":wQDPSrcTxt"
	string  	sPlaneNm		= "BackColors" 
	variable	pl			= FindDimLabel( wFlags, 2, sPlaneNm )
	variable	nOldState		= State( wFlags, s.row, s.col, pl )					
	variable	nState		= Modifier2State( s.eventMod, lstMOD2STATE1)		

End
Function	/S	ListQDPSrcAllChs( lstGenSelect  )
	string  	lstGenSelect
	variable	ch
	variable	nChans		= ItemsInList( LstChAcq(), ksSEP_TAB )
	string 	lstACVAllCh	= ""
	for ( ch = 0; ch < nChans; ch += 1 )
		lstACVAllCh	+= ListQDPSrcOA( ch, lstGenSelect )
	endfor
	 printf "ListQDPSrcAllChs()  has %d items (%s...%s) \r", ItemsInList( lstACVAllCh ),  lstACVAllCh[0,80],  lstACVAllCh[ strlen( lstACVAllCh )-80, inf ]  
	return	lstACVAllCh
End
Function	/S	ListQDPSrcOA( ch, lstGenSelect )
	variable	ch
	string  	lstGenSelect
	string  	sFolders	= ksF_ACQ_PUL 
	variable	nRegs	= RegionCnt(  sFolders, ch )
	variable	rg
	string  	lstACV	= ""
	for ( rg = 0; rg < nRegs; rg += 1 )
		lstACV	+= ListQDPSrc1RegionOA( ch, rg, lstGenSelect )
	endfor

	return	lstACV
End
Function	/S	ListQDPSrc1RegionOA( ch, rg, lstGenSelect )
	variable	ch, rg
	string  	lstGenSelect
	string  	sFolders	= ksF_ACQ_PUL
	variable	nChans	= ItemsInList( LstChAcq(), ksSEP_TAB )
	variable	LatCnt	= LatencyCntA() 
	string  	lstACV	= ""
	lstACV	+= ListQDPSrcGenOLA( sFolders, ch, rg, lstGenSelect )			
	lstACV	+= ListQDPSrcFitOLA( sFolders, ch, rg )					

	return	lstACV
End
Function	/S	ListQDPSrcGenOLA( sFolders, ch, rg, lstGenSelect )
	string  	sFolders, lstGenSelect			
	variable	ch, rg
	string  	sPostfx		= Postfix( ch, rg )
	string		lst			= ""
	variable	shp, pt, nPts	= ItemsInList( klstEVL_RESULTS )
	for ( pt = 0; pt < nPts; pt += 1 )
		shp	= str2num( StringFromList( pt, lstGenSelect ) )					
		if ( numtype( shp ) != kNUMTYPE_NAN ) 								
			lst	= AddListItem( EvalNm( pt ) + sPostfx, lst, ";", inf )					
		endif
	endfor
	return	lst
End
Function	/S	ListQDPSrcFitOLA( sFolders, ch, rg )
	string  	sFolders			
	variable	ch, rg
	string  	lst		= ""	
	variable	fi, nFits	=  ItemsInList( ksPHASES ) - PH_FIT0
	for ( fi = 0; fi < nFits; fi += 1 )
		nvar		bFit		= $"root:uf:" + sFolders + ":cbFit" + num2str( ch ) + num2str( rg )  + num2str( fi ) + "0"	
		if ( bFit )
			lst	= ListQDPSrcFitOA( lst, sFolders, ch, rg, fi )
		endif
	endfor

	return	lst
End	
Function	/S	ListQDPSrcFitOA( lst, sFolders, ch, rg, fi )
	string  	lst, sFolders
	variable	ch, rg, fi
	variable	pa, nPars
	variable	nFitInfo, nFitInfos	= FitInfoCnt()
	variable	nFitFunc			= FitFnc( sFolders, ch, rg, fi )
	nPars	= ParCnt( nFitFunc )					
	for ( pa = 0; pa < nPars; pa += 1 )				
		lst	= AddListItem( FitParInLBNm( ch, rg, fi, pa, nFitFunc ),  lst, ";" , inf )			
	endfor
	variable nDerived = DerivedCnt( nFitFunc )
	for ( pa = 0; pa < nDerived; pa += 1 )				
		lst	= AddListItem( FitDerivedInLBNm( ch, rg, fi, pa, nFitFunc ),  lst, ";" , inf )			
	endfor

	return	lst
End
static constant	kQDP_DESC_LENGTH = 1
static strconstant	ksQDP_SEPAR = "_"
static strconstant ksDIFF_BASE	= "d"  	
constant		kOLA_DIFF_MAX	= 2
strconstant 	klstANYC	= "off;DE;FG;HI"
constant		kANY_OFF = 0
Function	/S	ListQDPSrcDiff( sFolders, nThisCh, nThisRg, nChannels, AnyCnt )
	string  	sFolders							
	variable	nThisCh, nThisRg, nChannels, AnyCnt 
	string  	lst		= ""	
	variable	BegEnd, lc
	variable	ch, rg, rgCnt, nAnyOp	
	string  	sAnyOp
	make /O /T /N=( nChannels, kRG_MAX, AnyCnt, 2 )  $"root:uf:" + sFolders + ":wTmpAnyNames" = ""
	wave      /T  wTmpAnyNames =  $"root:uf:" + sFolders + ":wTmpAnyNames"
	for ( lc = 0; lc < AnyCnt; lc += 1 )
		for ( BegEnd = CN_BEG; BegEnd <=  CN_END; BegEnd += 1 )
			for ( ch = 0; ch < nChannels; ch += 1)
				rgCnt	= RegionCnt( sFolders, ch )
				for ( rg = 0; rg < rgCnt;  rg += 1 )	
					nAnyOp	= 1 
					sAnyOp	= StringFromList( nAnyOp, klstANYC )		
					if ( nAnyOp != kANY_OFF )
						wTmpAnyNames[ ch ][ rg ][ lc ][ BegEnd ] = AnyNm( sFolders, lc, BegEnd, ch, rg ) 

					endif
				endfor
			endfor
		endfor
	endfor
	for ( lc = 0; lc < AnyCnt; lc += 1 )
		for ( BegEnd = CN_BEG; BegEnd <=  CN_END; BegEnd += 1 )
			for ( ch = 0; ch < nChannels; ch += 1)
				rgCnt	= RegionCnt( sFolders, ch )
				for ( rg = 0; rg < rgCnt;  rg += 1 )	
					lst  += wTmpAnyNames[ ch ][ rg ][ lc ][ BegEnd ] 	
				endfor
			endfor
		endfor
		lst  +=  PostFix( nThisCh, nThisRg ) + ";"			
	endfor
	KillWaves  $"root:uf:" + sFolders + ":wTmpAnyNames"

	return	lst
End	
Function	/S	AnyNm( sFolders, lc, BegEnd, ch, rg )
	string  	sFolders
	variable	lc, BegEnd, ch, rg
	variable	nAnyOp	= 1 	
	string		sAnyOp	= StringFromList( nAnyOp, klstANYC )
	return	SelectString( BegEnd, ksDIFF_BASE + num2str( lc ) + ksQDP_SEPAR + sAnyOp[ 0, kQDP_DESC_LENGTH-1 ] + num2str( ch ) + num2str( rg ),   sAnyOp[ 0, kQDP_DESC_LENGTH-1 ] + num2str( ch ) + num2str( rg ) )	
End
