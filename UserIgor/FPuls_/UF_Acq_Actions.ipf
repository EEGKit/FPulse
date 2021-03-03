// UF_acq_Actions
//
//	constant	UFPE_kCH	= 0,	UFPE_kRG	= 1, 	UFPE_kCT	= 2,  	UFPE_kNC	= 3, 	UFPE_kCURSOR = 4, UFPE_kXMOUSE = 5, UFPE_kYMOUSE = 6,  UFPE_kCURSWP = 7,  UFPE_kSIZE = 8,   UFPE_kMAXCURRG = 9	// index for wCurRegion and wPrevRegion
// 
// 
// 
// // Indexing for  wMnMx[]:
//// static constant    	UFPE_kMM_XMIN = 0, UFPE_kMM_XMAX = 1, UFPE_kMM_YMIN = 2, UFPE_kMM_YMAX = 3, UFPE_kMM_XYMAX = 4
//	 constant		UFPE_kMM_XMIN = 0, UFPE_kMM_XMAX = 1, UFPE_kMM_YMIN = 2, UFPE_kMM_YMAX = 3, UFPE_kMM_XYMAX = 4
//
//
//
//// Indexing for finally extracted evaluation parameters = the GENERAL part of   All  Computed Values (ACV) :
// 	constant		UFPE_kVAL = 0,  UFPE_kT = 1,  UFPE_kY = 2,  UFPE_kTB = 3,  UFPE_kYB = 4,  UFPE_kTE = 5,  UFPE_kYE = 6,  UFPE_kE_MAXTYP = 7
//	strconstant	UFPE_klstE_POST	= ";_T;_Y;_TB;_YB;_TE;_YE"
//	constant		UFPE_kE_PROT=0,   UFPE_kE_BLK=1,   UFPE_kE_FRM=2,   UFPE_kE_ANA=3,  UFPE_kE_AVE=4,        UFPE_kE_FIT=5,    UFPE_kE_CHNAME=6,   UFPE_kE_CATEGORY=7,   UFPE_kE_EVENT=8,   UFPE_kE_SINCE1DS=9,  UFPE_kE_FILE=10,        UFPE_kE_SCRIPT=11,    UFPE_kE_DATE=12,       UFPE_kE_TIME=13,     UFPE_kE_DS=14,   	UFPE_kE_DSMX=15,      UFPE_kE_BEG=16,        UFPE_kE_END=17,        UFPE_kE_PTS=18
//	constant		UFPE_kE_AMPL=19,  UFPE_kE_BASE=20, UFPE_kE_SDBASE=21, UFPE_kE_MEAN=22,  UFPE_kE_SDEV=23, UFPE_kE_BRISE=24,    UFPE_kE_RISE20=25,  UFPE_kE_RISE50=26,     UFPE_kE_RISE80=27,  UFPE_kE_RT2080=28,  UFPE_kE_RISSLP=29,  UFPE_kE_PEAK=30,  UFPE_kE_PEAKAREA=31,  UFPE_kE_EVVALID=32,	UFPE_kE_HALDU=33,  UFPE_kE_DEC50=34,  UFPE_kE_DECSLP=35,  UFPE_kE_RSER=36,   UFPE_kE_RESMAX=37
//
//	 strconstant	UFPE_klstEVL_RESULTS= "Prot;Blk;Frm;Ana;Ave;Fit;Ch;Category;Ev;Since1DS; 	Fi; 	Sc;	Da; 	Ti;	DS;  DMx;  Beg;End; Pts;	Ampl;Base;	SDBase;	Mean;	SDev; 	BsRise; 	RT20; 	RT50; 	RT80;	RT2080;	RiseSlp;	Peak; 	PeakArea; EvValid; 	HalfDur;	DT50;	DecSlp;	Rser;		"
//	 strconstant	UFPE_klstEVL_PRINT	 = "0;   0;	0;	0;	0; 0;	0;	0;	0;	0;		0;	0;	0;	0;	0;	0;	    0;	   0;	  0;	0;	0,3,5;	0;		0;		0;		1,2;		0;		0;		0;		0;		0,1;		0,1,3,5;	0;		0;		0;		0;		0,1;		0;			"
//	 strconstant	UFPE_klstEVL_IS_STRING= "  ;    ;	 ;	1;	1; 1;	1;	0;	0;	0;		1;	1;	1;	1;	1;	0;	    0;	   0;	  0;	0;	0;		0;		0;		0;		0;		0;		0;		0;		0;		0;		0;		0;		0;		0;		0;		0;		0;			"
//	 strconstant	UFPE_klstEVL_UNITS    	= " ;	    ;	 ;	 ;	  ;  ;	 ;	;	;	s;		;	;	;	;	;	;	    ms; ms;	  ;	au;	au;		au;		au;		au;		;		;		;		;		ms;		?;		au;		;		;		ms;		ms;		U2;		MO;			"
//	//			UFPE_klstEVL_QDPSRC is used to select the sources for  Quotients, Diffs and Products
//	 strconstant	UFPE_klstEVL_QDPSRC 	= " ;	    ;	 ;	 ;	 ;  ;	 ;	;	;	;		;	;	;	;	;	;	    ;	   ;	  ;	1;	1;		;		1;		;		1;		;		1;		;		;		1;		1;		;		;		;		;		;		;			"
//	//			UFPE_klstEVL_SHAPES is used to both select the results for the drawing AND ALSO for the OLA selection
//	 strconstant	UFPE_klstEVL_SHAPES	= " ;	    ;	 ;	 ;	 ;  ;	 ;	;	;	;		;	;	;	;	;	;	    ;	   ;	  ;	;	-2;		;		;		;		;		41;		50;		41;		-5;		1;		40;				;		-1;		47;		1;		0;			"
//	 strconstant	UFPE_klstEVL_COLORS 	= " ;	    ;	 ;	 ;	 ;  ;	 ;	;	;	;		;	;	;	;	;	;	    ;	   ;	  ;	;	Green;	;		;		;		;		DBlue;	Red;		DBlue;	DBlue;	DCyan;	Red;		;		;		Green;	Red;		DCyan;	Mag;			"
//
////	 strconstant	UFPE_klstEVL_RESULTS= "  Ch;Category;Ev;Since1DS; 	Fi; 	Sc;	Da; 	Ti;	DS;  DMx;  Beg;End; Pts;	Ampl;Base;	SDBase;	Mean;	SDev; 	BsRise; 	RT20; 	RT50; 	RT80;	RT2080;	RiseSlp;	Peak; 	PeakArea; EvValid; 	HalfDur;	DT50;	DecSlp;	Rser;		"
////	 strconstant	UFPE_klstEVL_PRINT	     =  "0;	0;	0;	0;		0;	0;	0;	0;	0;	0;	    0;	   0;	  0;	0;	0,3,5;	0;		0;		0;		1,2;		0;		0;		0;		0;		0,1;		0,1,3,5;	0;		0;		0;		0;		0,1;		0;			"
////	 strconstant	UFPE_klstEVL_IS_STRING    =	"1;	0;	0;	0;		1;	1;	1;	1;	1;	0;	    0;	   0;	  0;	0;	0;		0;		0;		0;		0;		0;		0;		0;		0;		0;		0;		0;		0;		0;		0;		0;		0;			"
////	 strconstant	UFPE_klstEVL_UNITS    	=	" ;	;	;	s;		;	;	;	;	;	;	    ms; ms;	  ;	au;	au;		au;		au;		au;		;		;		;		;		ms;		?;		au;		;		;		ms;		ms;		U2;		MO;			"
////	//			UFPE_klstEVL_QDPSRC is used to select the sources for  Quotients, Diffs and Products
////	 strconstant	UFPE_klstEVL_QDPSRC 	=	" ;	;	;	;		;	;	;	;	;	;	    ;	   ;	  ;	1;	1;		;		1;		;		1;		;		1;		;		;		1;		1;		;		;		;		;		;		;			"
////	//			UFPE_klstEVL_SHAPES is used to both select the results for the drawing AND ALSO for the OLA selection
////	 strconstant	UFPE_klstEVL_SHAPES	=	" ;	;	;	;		;	;	;	;	;	;	    ;	   ;	  ;	;	-2;		;		;		;		;		41;		50;		41;		-5;		1;		40;				;		-1;		47;		1;		0;			"
////	 strconstant	UFPE_klstEVL_COLORS 	=	" ;	;	;	;		;	;	;	;	;	;	    ;	   ;	  ;	;	Green;	;		;		;		;		DBlue;	Red;		DBlue;	DBlue;	DCyan;	Red;		;		;		Green;	Red;		DCyan;	Mag;			"
//
//// Possible drawing parameters using Igor's markers
// constant		UFPE_kS_HANTEL = -5, UFPE_kS_BOX = -4, UFPE_kS_LONGHORZ = -3, UFPE_kS_BASE = -2, UFPE_kS_LINE = -1, UFPE_kNO_MARKER = 0,  UFPE_kSCROSS = 0,  UFPE_kXCROSS = 1, UFPE_kS_HOURGLASS=3,  UFPE_kSLINEH = 9,  UFPE_kSLINEV = 10,  UFPE_kRECT = 13,  UFPE_kDIAMOND = 40,  UFPE_kCIRCLE = 41,  UFPE_kS_DELTA2 = 47 ,  UFPE_kS_DLT1 = 50 // , cFCROSS = 12, cLCROSS = 24	// some are Igor-defined markers
//
//
//
//// Indexing for phase/region ( also working for cursors which are sort of generalized/specialized regions ):
//constant							UFPE_kC_PHASE_BASE=0,  UFPE_kC_PHASE_PEAK=1,  UFPE_kC_PHASES_BASEplusPEAK=2				// The code relies on the fact that there is only 1 Base and only 1 Peak. If there were more functions 'BaseCnt( sFolders )' and 'PeakCnt( sFolders )' would be required.
//constant							UFPE_kCSR_BASE=0, 		UFPE_kCSR_PEAK=1,  	UFPE_kCSR_LAT=2, 		UFPE_kCSR_FIT=3		// ct indexing (cursor type)
//strconstant	UFPE_kCSR_NAME		= "	Base; 				Peak;				Latency;					Fit;"					// Any number of  Fits or Latencies are possible here, 3 are provided now. Supply additional action procs if you want more.
//strconstant	UFPE_kCSR_COLORS	= "	Green,;				Red,;				Blue,Brown,Black,;			Mag,Cyan,Orange,;"		// EVAL and ACQ may use different numbers of fits or latencies, sufficient values for the maximum number ( see FitCnt(), LatencyCnt() ) must be supplied here
//strconstant	UFPE_kCSR_COLORSDARK= "	DGreen,;			DRed,;				DBlue,Brown,Black,;			DMag,DCyan,Orange,;"	// EVAL and ACQ may use different numbers of fits or latencies, sufficient values for the maximum number ( see FitCnt(), LatencyCnt() ) must be supplied here
//strconstant	UFPE_kCSR_SHAPE		= " 	9,;				9,;					17,17,17,; 					8,8,8,;"				// e.g. UFPE_kCSR_VALSHORT + UFPE_kCSR_YSHORT = 9 
//
//
//static constant		UFPE_kCSR_VALSHORT 	= 1, UFPE_kCSR_VALMEDIUM = 2, UFPE_kCSR_VALFULL = 4, UFPE_kCSR_YSHORT = 8, UFPE_kCSR_YFULL = 16
//
//
//// Indexing for controls and values:
//// Indexing for ChannelRegion Evaluation ( UFPE_CN_BEG and  UFPE_CN_END  must be successive
// constant			UFPE_kLEFT_CSR = 0,	UFPE_kRIGHT_CSR = 1		// == UFPE_CN_BEG, UFPE_CN_END
//strconstant		UFPE_ksLR_CSR	="left;right"
//
//  constant	  		UFPE_CN_BEG = 0, UFPE_CN_END = 1,  UFPE_CN_SAVEBEG = 2,  UFPE_CN_SAVEEND = 3,  UFPE_CN_MAX = 4, UFPE_CN_SV = 2  // UFPE_CN_SV is the delta...
//static strconstant	UFPE_CN_TEXT	= "Beg;End;SvBeg;SvEnd;"
//
//
//// Popupmenu indexing for result printing into history 
// constant			UFPE_RP_HEADER = 1,  UFPE_RP_FITSTART = 2,  UFPE_RP_FIT = 4,  UFPE_RP_BASEPEAK1 = 8 				// only powers of 2 can be added to give arbitrary combinations
// strconstant		UFPE_ksPRINTRESULTS	= "nothing;Header;StimFit;Fit + Start;BasePeak;Print All"			//  Igor does not allow this to be static
// strconstant		UFPE_ksPRINTMASKS	= "   0	;   1	   ;  3      ; 	7     ;   	8           ; 15 ;"				//  Arbitrary combinations . Cannot be static as it is used in Window macro
// 

//===========================================================================================================================================
//  THE  CURSORS   OLD

Function		UFPE_Csr2Ph( sFolders, ct, nc, LatCnt )
// Order is important:  Base, Peak, Lats, Fits !
	string  	sFolders
	variable	ct, nc, LatCnt
	variable	ph = 0
	if ( ct < UFPE_kCSR_LAT )
		return	ct									// Base = 0, Peak = 1  (there is only 1 Base and 1 Peak) !
	elseif ( ct < UFPE_kCSR_FIT )
		return	UFPE_kC_PHASES_BASEplusPEAK + nc					// nc is latency index
	else
		return	UFPE_kC_PHASES_BASEplusPEAK + LatCnt + nc	// nc is  fit  index
	endif
End

static Function		Csr2Cnt( sFolders, ct, LatCnt, FitCnt  )
// Order is important:  Base, Peak, Lats, Fits !
	string  	sFolders
	variable	ct, LatCnt, FitCnt 
	variable	ph = 0
	if ( ct < UFPE_kCSR_LAT )
		return	1									// Base = 1, Peak = 1  (there is only 1 Base and 1 Peak) !
	elseif ( ct < UFPE_kCSR_FIT )
		return	LatCnt
	else
		return	FitCnt
	endif
End


//===================================================================================================================

 Function		UFPE_SpreadCursorsBE( sFolders, ch, rg, ct, nc, AxisRangeX, TimeLeftX, LatCnt, FitCnt )
// 2006-0328 spread cursors evenly.  Possible improvement: 1. Make Base cursor range wider than the other ranges. 
	string  	sFolders
	variable	ch, rg, ct, nc, AxisRangeX, TimeLeftX, LatCnt, FitCnt
	variable	nRegs	 = UFPE_RegionCnt( sFolders, ch )
	variable	ph		 = UFPE_Csr2Ph( sFolders, ct, nc, LatCnt )
	variable	nPhaseCnt = UFPE_kC_PHASES_BASEplusPEAK + LatCnt + FitCnt
	variable	Beg		 = ( rg  +  ph 	/ nPhaseCnt + .01 ) / nRegs
	variable	Ende		 = ( rg  + (ph+.8)	/ nPhaseCnt + .01 ) / nRegs
	UFPE_SetCursorX( sFolders, ch, rg, ph, UFPE_CN_BEG , Beg   * AxisRangeX + TimeLeftX )
	UFPE_SetCursorX( sFolders, ch, rg, ph, UFPE_CN_END, Ende * AxisRangeX + TimeLeftX )
End	


 Function		UFPE_SpreadCursor( sFolders, ch, rg, ct, nc, BegEnd, AxisRangeX, TimeLeftX, LatCnt, FitCnt )
// 2006-0328 spread cursors evenly.  Possible improvement: 1. Make Base cursor range wider than the other ranges. 
	string  	sFolders
	variable	ch, rg, ct, nc, BegEnd, AxisRangeX, TimeLeftX, LatCnt, FitCnt
	variable	nRegs	 = UFPE_RegionCnt( sFolders, ch )
	variable	ph		 = UFPE_Csr2Ph( sFolders, ct, nc, LatCnt )
	variable	nPhaseCnt = UFPE_kC_PHASES_BASEplusPEAK + LatCnt + FitCnt
	variable	BegOrEnd	 = ( rg  + ( ph + .8 * BegEnd )  / nPhaseCnt + .01 ) / nRegs
	UFPE_SetCursorX( sFolders, ch, rg, ph, BegEnd,  BegOrEnd * AxisRangeX + TimeLeftX )
End	

//===================================================================================================================


//=================================================================================================
//  THE  CURSORS   NEW

 Function		UFPE_CursorConstructWaves( sFolders, LatCnt, FitCnt )
// Already during initialisation we construct ALL possible waves for displaying ANY evaluated point, even if the point is never evaluated or displayed.
// This sacrifies some memory (appr. 8*4*30*6*4 = 25KB) but simplifies the code and speeds up the execution as we do not have to check during run-time whether a wave exists or not.
	string  	sFolders
	variable	LatCnt, FitCnt
	variable	ch, rg, ct, nc, ph, nCsr, CsrShape
	string  	sFoldr	= "root:uf" + ":" + sFolders + ":" + ksF_CSR				// e.g. 'root:uf:acq:pul:ors'
	UFCom_ConstructAndMakeCurFoldr( sFoldr )
	for ( ch = 0; ch < UFPE_kMAXCHANS; ch += 1 )
		for ( rg = 0; rg < UFPE_kRG_MAX; rg += 1 )
			for ( ct = 0; ct <= UFPE_kCSR_FIT; ct += 1 )
				for ( nc = 0; nc < Csr2Cnt( sFolders, ct, LatCnt, FitCnt ); nc += 1 )
					CsrShape	= str2num( UFCom_RemoveWhiteSpace( StringFromList( nc, StringFromList( ct, UFPE_kCSR_SHAPE ), "," ) ) )
					ph 		= UFPE_Csr2Ph( sFolders, ct, nc, LatCnt )
					for ( nCsr = 0; nCsr < 2; nCsr += 1 )
						string  	sYNm	= CursorNmY( ch, rg, ph, nCsr )
						string  	sFoXNm	= FoCursorNmX( sFolders, ch, rg, ph, nCsr )
						string  	sFoYNm	= FoCursorNmY( sFolders, ch, rg, ph, nCsr )		// e.g. 'root:uf:acq:pul:cs:cs.......Adc1BaseY0'
						//string  	sFoldr	= RemoveEnding(  RemoveFromList( sYNm, sFoYNm, ":" ) , ":" )	// e.g. 'root:uf:acq:pul:ors'
						// UFCom_ConstructAndMakeCurFoldr( sFoldr )


						// printf "\t\tUFPE_CursorConstructWaves()\tch:%2d  rg:%2d  ct:%2d  nc:%2d  [ ->ph:%2d]  nCsr:%2d  Constructing folder '%s'  for  '%s'  and  '%s' \tshape:%2d\t \r", ch, rg, ct, nc, ph, nCsr, sFoldr, sFoXNm, sFoYNm, CsrShape
						make /O /N= 4   $sFoXNm+"_Shp"	= 0						// the cursor X shape	 (the stub lengths)	!!! Assumption naming
						make /O /N= 4   $sFoYNm+"_Shp"	= 0						// the cursor Y shape					!!! Assumption naming
						make /O /N= 4   $sFoXNm			= Nan					// the cursor real X values (= cursor shape + Xoffset )
						make /O /N= 4   $sFoYNm			= Nan					// the cursor real Y values
						wave	wFoXCsrShape			= $sFoXNm+"_Shp"			// the cursor X shape					!!! Assumption naming
						wave	wFoYCsrShape			= $sFoYNm+"_Shp"			// the cursor Y shape					!!! Assumption naming

// 2006-0407 Demo for Latency Cursor shape variation in X (should be revamped!)    :  Latency cursors (having cursor shape =17) have no stubs  ( length would be difficult as there is no Left/right pair...)
//	variable	VertExt	= CsrShape  & UFPE_kCSR_YSHORT 		?  .25  :  .05		// make vertical lines longer ( 1 ~ Y full scale)
//			VertExt	= CsrShape  & UFPE_kCSR_YFULL 		?   1	  :  VertExt		// make vertical lines longer ( 1 ~ Y full scale)
//	variable	HrzValExt	= CsrShape  & UFPE_kCSR_VALSHORT  	?  .01  :  .04		// the middle stub : TURNED OFF AT THE MOMENT as the value is often out of range
//			HrzValExt	= CsrShape  & UFPE_kCSR_VALMEDIUM	?  .05  :  HrzValExt	
//			HrzValExt	= CsrShape  & UFPE_kCSR_VALFULL		?    1	  :  HrzValExt	

						if ( nCsr == UFPE_CN_BEG )										// left cursor : draw stubs to the right
							wFoXCsrShape[ 0 ]	= .5								// top stub length
							wFoXCsrShape[ 3 ]	= .2								// bottom stub length
							if ( CsrShape  &&  UFPE_kCSR_YFULL ) 
								wFoXCsrShape[ 0 ]	= 0							// top stub length  060407 Demo for Latency Cursor shape variation in X : Latency cursors (having cursor shape =17)  have no stubs
								wFoXCsrShape[ 3 ]	= 0							// 
							endif
						endif
						if ( nCsr == UFPE_CN_END )										// right cursor : draw stubs to the left
							wFoXCsrShape[ 0 ]	= -.2								// top stub length
							wFoXCsrShape[ 3 ]	= -.5								// bottom stub length
							if ( CsrShape  &&  UFPE_kCSR_YFULL ) 
								wFoXCsrShape[ 0 ]	= 0							// top stub length  060407 Demo for Latency Cursor shape variation in X : Latency cursors (having cursor shape =17)  have no stubs
								wFoXCsrShape[ 3 ]	= 0							// 
							endif
						endif
					endfor
				endfor
			endfor
		endfor
	endfor
	 printf "\t\tUFPE_CursorConstructWaves()\tch:0..%2d  rg:0..%2d  ct :...  nc:... -> ph:0..%2d  nCsr:0..2    Constructing folder '%s'  for  .....'%s'  and  .....'%s' \t \r", UFPE_kMAXCHANS-1, UFPE_kE_RESMAX-1, ph-1, sFoldr, sFoXNm, sFoYNm
End


Function		UFPE_CursorSetValues( sFolders, ch,   BegPt, SIFact, Top, Bottom, LatCnt, FitCnt  )
// Called whenever a cursor must be redrawn at another position on screen: During Analyse() when XOffset changes  OR  when the user moves a cursor in the cursor action procedure.
// Only the values of the cursor wave are recomputed here, Igor automatically takes care of the displaying the changed cursor.
// Different approach (not taken): Establish a dependency between the XOffset / Cursor display wave  and between  User cursor position / Cursor display wave   instead of calling this function at the appropriate times.

	string  	sFolders
	variable	ch,   BegPt, SIFact, Top, Bottom, LatCnt, FitCnt 
	variable	rg, ct, nc, ph, nCsr
	for ( rg = 0; rg < UFPE_kRG_MAX; rg += 1 )
		CursorSetValues1Rg( sFolders, ch, rg,  BegPt, SIFact, Top, Bottom, LatCnt, FitCnt )
	endfor
//	 printf "\t\tUFPE_CursorSetValues(b)\t\t\tch:%2d  rg:%2d  ct :%2d  nc:%2d -> ph:0..%2d  nCsr:0..2    Setting X offset \t%7g\t \r", ch, rg UFPE_kRG_MAX-1, ct, nc, ph,  BegPt * SIFact
End


static Function		CursorSetValues1Rg( sFolders, ch, rg,  BegPt, SIFact, Top, Bottom, LatCnt, FitCnt )
	string  	sFolders
	variable	ch, rg,  BegPt, SIFact, Top, Bottom, LatCnt, FitCnt
	variable	ct, nc, ph, nCsr
	for ( ct = 0; ct <= UFPE_kCSR_FIT; ct += 1 )
		for ( nc = 0; nc < Csr2Cnt( sFolders, ct, LatCnt, FitCnt ); nc += 1 )
			ph = UFPE_Csr2Ph( sFolders, ct, nc, LatCnt )
			for ( nCsr = 0; nCsr < 2; nCsr += 1 )
				UFPE_CursorSetValue( sFolders, ch, rg, ct, nc, nCsr,  BegPt, SIFact, Top, Bottom, LatCnt, FitCnt )
			endfor
		endfor
	endfor
//	 printf "\t\tCursorSetValues1Rg\t\t\tch:%2d  rg:%2d  ct :%2d  nc:%2d -> ph:0..%2d  nCsr:0..2    Setting X offset \t%7g\t \r", ch, rg UFPE_kRG_MAX-1, ct, nc, ph,  BegPt * SIFact
End


Function		UFPE_CursorSetValue( sFolders, ch, rg, ct, nc, nCsr,  BegPt, SIFact, Top, Bottom, LatCnt, FitCnt  )
// Called whenever a cursor must be redrawn at another position on screen: During Analyse() when XOffset changes  OR  when the user moves a cursor in the cursor action procedure.
// Only the values of the cursor wave are recomputed here, Igor automatically takes care of the displaying the changed cursor.
// Different approach (not taken): Establish a dependency between the XOffset / Cursor display wave  and between  User cursor position / Cursor display wave   instead of calling this function at the appropriate times.
	string  	sFolders
	variable	ch, rg, ct, nc, nCsr, BegPt, SIFact, Top, Bottom, LatCnt, FitCnt 
	variable	ph			= UFPE_Csr2Ph( sFolders, ct, nc, LatCnt )
	//string  	sXNm		= CursorNmX( ch, rg,ph, nCsr )				// e.g. 
	string  	sFoXNm		= FoCursorNmX( sFolders, ch, rg, ph, nCsr )
	string  	sFoYNm		= FoCursorNmY( sFolders, ch, rg, ph, nCsr )
	wave	wFoXCsrShape	= $sFoXNm+"_Shp"						// the cursor shape  (the stub lengths)		!!! Assumption naming
	wave	wFoXCsr		= $sFoXNm							// the cursor real X values (= cursor shape + Xoffset )
	wave	wFoYCsr		= $sFoYNm							// the cursor real Y values
	variable	XPos			= UFPE_CursorX( sFolders, ch, rg, ph, nCsr )			// the cursor position as set by the user (relative to trace begin = XOffset is subtracted)
	variable	XLeft			= UFPE_CursorX( sFolders, ch, rg, ph, UFPE_CN_BEG )		// the cursor position as set by the user (relative to trace begin = XOffset is subtracted)
	variable	XRight		= UFPE_CursorX( sFolders, ch, rg, ph, UFPE_CN_END )		// the cursor position as set by the user (relative to trace begin = XOffset is subtracted)
	variable	CsrDistance	= abs( XRight - XLeft )

	// Fill the cursor wave points so that Igor will draw the desired cursor shape at the desired position in the display
	if ( numType( CsrDistance ) != UFCom_kNUMTYPE_NAN ) 						//There is a Begin and an End cursor (e.g. Base, peak, Fits)  and both are valid. This allows us to draw stubs.
		wFoXCsr	= BegPt * SIFact  +  XPos  +  wFoXCsrShape * CsrDistance 		// 	the cursor real X values ( =  Xoffset + relative cursor position value + cursor stubs shape )
	else															// Only Begin OR End is valid because either the 2. Base/Peak/Fit cursor is still missing  OR  we have an (always single) Lat cursur, so we cannot draw stubs
		wFoXCsr	= BegPt * SIFact  +  XPos								// 	the cursor real X values ( =  Xoffset + relative cursor position value  )
	endif

//	if ( UFCom_TRUE )
	if ( numType( wFoXCsr[ 0 ] ) != UFCom_kNUMTYPE_NAN ) 
//	if ( numType( wFoXCsr[ 0 ] ) != UFCom_kNUMTYPE_NAN  &&  ch == 0   &&  rg == 0   &&  ct == 1   &&  nc == 0   ) 
		// printf "\t\tUFPE_CursorSetValue(a) \tch:%d rg:%d ct:%d nc:%d ph:%d Cs:%d\t%s\txos:\t%7g\t\t\t\t\tBegPt:\t%7g\t\t\t\t\t\tSF:\t%7.4lf\tx:\t%8.3lf\tDist:\t%7g\tCsrXLft[1]..[0] (=stub):\t%7g\t  ..\t%7g\t \r", ch, rg, ct, nc, ph, nCsr, UFCom_pd(sFoXNm[7,inf],23), UFPE_XCursrOs( sFolders, ch ), BegPt, SIFact, XPos, CsrDistance, wFoXCsr[1], wFoXCsr[0]
	endif
	if ( Top != Bottom )
		wFoYCsr[ 0 ] = Top
		wFoYCsr[ 1 ] = Top
		wFoYCsr[ 2 ] = Bottom
		wFoYCsr[ 3 ] = Bottom
	endif
End

 Function		CursorDisplay( sFolders, ch, rg, ct, nc, nCsr, sWnd, LatCnt )
// Display the cursor wave in the (ACQ or EVAL) traces window by appending it to the graph. Igor will automatically update the display of the cursor whenever we update the value(s) in the wave.
	string  	sFolders
	variable	ch, rg, ct, nc, nCsr, LatCnt									
	string  	sWnd
	wave	wRed = root:uf:acq:misc:Red, wGreen = root:uf:acq:misc:Green, wBlue = root:uf:acq:misc:Blue
	variable	ph		= UFPE_Csr2Ph( sFolders, ct, nc, LatCnt )
	string  	sXNm	= CursorNmX( ch, rg, ph, nCsr )				// e.g. 
	string  	sYNm	= CursorNmY( ch, rg, ph, nCsr )				// e.g. 
	string  	sFoXNm	= FoCursorNmX( sFolders, ch, rg, ph, nCsr )
	string  	sFoYNm	= FoCursorNmY( sFolders, ch, rg, ph, nCsr )
	wave  /Z	wFoXCsr	= $sFoXNm							// the cursor real X values (= cursor shape + Xoffset )
	wave  /Z	wFoYCsr	= $sFoYNm							// the cursor real Y values 
	string  	lstColors	= UFCom_RemoveWhiteSpace( UFCom_lstCOLORS )

	// Check if the cursor is already in the graph, only if it is yet missing then append it (this avoids multiple instances#1, #2...)
	string 		sTNL	= TraceNameList( sWnd, ";", 1 )
	if ( WhichListItem( sYNm, sTNL, ";" )  == UFCom_kNOTFOUND )				// ONLY if  wave is not in graph...

		variable	nColor	= WhichListItem( UFCom_RemoveWhiteSpace( StringFromList( nc, StringFromList( ct, UFPE_kCSR_COLORS ),  "," ) ) , lstColors )
		variable	CsrShape	= str2num( 	 UFCom_RemoveWhiteSpace( StringFromList( nc, StringFromList( ct, UFPE_kCSR_SHAPE ),     "," ) ) )
		variable	nDotting	= rg + 1								// 0 is line, rg 0 ~ 1 ~ very fine dots,  rg 1 ~ 2 ~ small dots,  rg 7 ~ 8 ~ coarse dotting

// 2007-0129
if ( waveExists( wFoYCsr )  &&  waveExists( wFoXCsr ) )

		 printf "\t\tCursorDisplay \t\tch:%d rg:%d ct:%d nc:%d ph:%d\t%s\t\t\t\t\t Shp:%2d\tCo: %3d\t APPENDING\t%s\t  %s\t'%s'\tX:%g %g\tY:%g %g \r", ch, rg, ct, nc, ph,  UFCom_pd( "???",9), CsrShape, nColor, sFoXNm, sYNm, sWnd, wFoXCsr[0], wFoYCsr[0], wFoXCsr[1], wFoYCsr[1]
		AppendToGraph /W=$sWnd wFoYCsr vs wFoXCsr
		ModifyGraph 	 /W=$sWnd  rgb( 	$sYNm )	= ( wRed[ nColor ], wGreen[ nColor ], wBlue[ nColor ] ) 
		ModifyGraph 	 /W=$sWnd  lstyle( 	$sYNm )	= nDotting
// 2006-0407 possible cursor shape modifications...
//		if ( CsrShape ==..... )
//			ModifyGraph 	 /W=$sWnd  mode( 	$sYNm )	= 0			// 0 : lines, 3 : markers ,  4 : lines + markers
//			ModifyGraph 	 /W=$sWnd  marker( 	$sYNm )	= shp
//		endif

// 2007-0129
endif

	 else
	// 	 printf "\t\tCursorDisplay\tch:%d  rg:%d  pt:%d %s\t  t:\t%8.3lf\t  y:\t%8.3lf\t  Shp:%2d\t%s\t(%d)\tWaves exist \t%s\t...%s\r", ch, rg, n, UFCom_pd( StringFromList(n, UFPE_klstEVL_RESULTS),9), x, y, shp, UFCom_pd(StringFromList( nColor, lstColors),5), nColor, "root:uf:eva" + sChRgNFolder + sXNm,  sYNm
		ModifyGraph  /Z /W=$sWnd	hidetrace( $sYNm ) = 0			// Display, don't hide
	endif
End


  Function		CursorHide( sFolders, ch, rg, ct, nc, nCsr, sWnd, LatCnt )
// Hide the evaluated data points wave in the (ACQ or EVAL) traces window (but not in the OLA window) . The trace is not removed but only hidden, which avoids the necessity to possibly append/reconstruct the trace later on.
	string  	sFolders, sWnd
	variable	ch, rg, ct, nc, nCsr, LatCnt									
	variable	ph			= UFPE_Csr2Ph( sFolders, ct, nc, LatCnt )
	string  	sYNm		= CursorNmY( ch, rg, ph, nCsr )				// e.g. 
	string  	sTNL		= TraceNameList( sWnd, ";", 1 )
	if ( WhichListItem( sYNm, sTNL, ";" )  != UFCom_kNOTFOUND )				// ONLY if  wave is  in graph (the user may have removed it)...
		// printf "\t\tCursorHide \t\tch:%d  rg:%d  ct:%2d  nc:%2d -> ph:%2d\t%s\t\t\t\t\t\t\t\t HIDING \t\t%s\t'%s'\t \r", ch, rg, ct, nc, ph, UFCom_pd( "???",9), sYNm, sWnd
		ModifyGraph  /Z /W=$sWnd	hidetrace( $sYNm ) = 1			// Hide, don't display
	endif
End

// 2006-0502 no longer used
//Function		CursorGetYAxis( sWnd, rTop, rBottom )
//// Get the current Y axis end values
//	string  	sWnd
//	variable	&rTop, &rBottom
//	GetAxis /W=$sWnd /Q left
//	rBottom	= V_min    //- .02 * ( V_max - V_min )
//	rTop		= V_max  //+ .02 * ( V_max - V_min )			// extend  over complete range
////   Making the cursors a bit longer than the data min/max is (at the moment) not so easy as 1. the Y axis seems fixed (extending the cursor Y will not extend the Y axis so the stubs vanish    2. even if the y axis would extend this effect would be cumulative ( the data would shrink every time ...)
// 
////	rBottom	= V_min   - .02 * ( V_max - V_min )
////	rTop		= V_max  + .02 * ( V_max - V_min )			// extend  over complete range
//End


//---------- Naming for small (=1 or 2 point)  cursor waves ----------------------------------------------------------

 strconstant	UFPE_ksCSR	= "wCsr"					// !!! ????? Cursor wave name MUST start with  'UFPE_ksCSR'  to avoid erasing of cursors ( --> EraseTracesInGraphExcept() ) 
static strconstant	ksF_CSR	= "csr"

static Function	/S	FoCursorNmX( sFolders, ch, rg, ph, nCsr )
	string  	sFolders								// e.g.  'acq:pul'  or  'eva:de'
	variable	ch, rg, ph, nCsr							// e.g.  
	return	"root:uf:" + sFolders + ":" + ksF_CSR + ":" +  CursorNmX( ch, rg, ph, nCsr )
End

static Function	/S	FoCursorNmY( sFolders, ch, rg, ph, nCsr )
	string  	sFolders								// e.g.  'acq:pul'  or  'eva:de'
	variable	ch, rg, ph, nCsr							// e.g. 
	return	"root:uf:" + sFolders + ":" + ksF_CSR + ":" +  CursorNmY( ch, rg, ph, nCsr )
End

static Function	/S	CursorNmX( ch, rg, ph, nCsr )
	variable	ch, rg, ph, nCsr							// e.g.  UFPE_kE_BASE  or  UFPE_kE_DT50 , todo implement fit results
	string  	sCursorNm		= UFPE_ksCSR + "X" + num2str( ch ) + "_r" + num2str( rg ) + "_p" + num2str( ph ) + "_n" + num2str( nCsr )
	// printf "\t\t\tCursorNmX( ch:%2d,  rg:%2d,  ph:%3d,  nCsr:%3d )  returns '%s'  \r", ch, rg, ph, nCsr, sCursorNm
	return 	sCursorNm
End

static Function	/S	CursorNmY( ch, rg, ph, nCsr )
	variable	ch, rg, ph, nCsr							// e.g.  UFPE_kE_BASE  or  UFPE_kE_DT50 , todo implement fit results
	string  	sCursorNm		= UFPE_ksCSR + "Y" +  num2str( ch ) + "_r" + num2str( rg ) + "_p" + num2str( ph ) + "_n" + num2str( nCsr )
	// printf "\t\t\tCursorNmX( ch:%2d,  rg:%2d,  ph:%3d,  nCsr:%3d )  returns '%s'  \r", ch, rg, ph, nCsr, sCursorNm
	return 	sCursorNm
End



//=================================================================================================
//  EVALUATED  POINTS  NEW

 Function		UFPE_EvPntConstructWaves( sFolders )
// Already during initialisation we construct ALL possible waves for displaying ANY evaluated point, even if the point is never evaluated or displayed.
// This sacrifies some memory (appr. 8*4*30*6*4 = 25KB) but simplifies the code and speeds up the execution as we do not have to check during run-time whether a wave exists or not.
	string  	sFolders
	variable	ch, rg, rtp
	for ( ch = 0; ch < UFPE_kMAXCHANS; ch += 1 )
		for ( rg = 0; rg < UFPE_kRG_MAX; rg += 1 )
			for ( rtp = 0; rtp < UFPE_kE_RESMAX; rtp += 1 )
				string  	sXNm	= AcqPtNmX( ch, rg, rtp )				// e.g. 'Dac0PeakX1
				string  	sYNm	= AcqPtNmY( ch, rg, rtp )				// e.g. 'Adc1BaseY0'
				string  	sFoXNm	= FoAcqPtNmX( sFolders, ch, rg, rtp )		// e.g. 'root:uf:acq:pul:ors:orsDac0PeakX1'
				string  	sFoYNm	= FoAcqPtNmY( sFolders, ch, rg, rtp )		// e.g. 'root:uf:acq:pul:ors:orsAdc1BaseY0'
				string  	sFoldr	= RemoveEnding(  RemoveFromList( sYNm, sFoYNm, ":" ) , ":" )	// e.g. 'root:uf:acq:pul:ors'
				// printf "\t\tUFPE_EvPntConstructWaves()\tch:%2d  rg:%2d  rtp:%2d  Constructing folder '%s'  for  '%s'  and  '%s' \t \r", ch, rg, rtp, sFoldr, sFoXNm, sFoYNm
				UFCom_ConstructAndMakeCurFoldr( sFoldr )
				make /O /N=6 	   $sFoXNm	= Nan					// the point (e.g. Peak)   or  a line (e.g. Base, HalfDur)   or  a bounding rectangle (e.g. Slope)
				make /O /N=6 	   $sFoYNm	= Nan
			endfor
		endfor
	endfor
	 printf "\t\tUFPE_EvPntConstructWaves  \tch:0..%2d  rg:0..%2d  rtp:0..%2d  Constructing folder '%s'  for  .....'%s'  and  .....'%s' \t \r", UFPE_kMAXCHANS-1, UFPE_kE_RESMAX-1, UFPE_kE_RESMAX-1, sFoldr, sFoXNm, sFoYNm
End


 static Function		EvPntSetValue( sFolders, ch, rg, rtp, BegPt, SIFact, x, y, xl, yt, xr, yb )
// Sets the computed value in the evaluated point which will be displayed in the (ACQ or EVAL) traces window (but not in the OLA window) .  There are enough values passed to allow drawing of a symbol, a horizontal or vertical line or a rectangle
// The evaluated data points wave must exists already (is constructed during initialisation).
// 2006-0411  Improvement: no need to pass BegPt=0  and  SIFact=1
	string  	sFolders
	variable	ch, rg, rtp			// e.g.  UFPE_kE_BASE  or  UFPE_kE_DT50 
	variable	BegPt, SIFact
	variable	x, y, xl, yt, xr, yb
	variable	shp		= str2num( StringFromList( rtp, UFPE_klstEVL_SHAPES ) )
	string  	sXNm	= AcqPtNmX( ch, rg, rtp )					// e.g. 'Dac0PeakX1
	string  	sYNm	= AcqPtNmY( ch, rg, rtp )					// e.g. 'Adc1BaseY0'
	string  	sFoXNm	= FoAcqPtNmX( sFolders, ch, rg, rtp )			// e.g. 'root:uf:acq:pul:ors:orsDac0PeakX1'
	string  	sFoYNm	= FoAcqPtNmY( sFolders, ch, rg, rtp )			// e.g. 'root:uf:acq:pul:ors:orsAdc1BaseY0'
	wave   /Z	wORsX	= $sFoXNm
	wave   /Z	wORsY	= $sFoYNm
	// printf "\t\tEvPntSetValue  \t\t%s\tshp:\t%2d\trtp:\t%2d\t\t%s\txos:\t%7g\t\t\t\t\tBegPt:\t%7d\t\t\t\t\t\tSF:\t%7.4lf\tx:\t%8.3lf\ty:\t%7g\t  \r", sFolders, shp, rtp, UFCom_pd(sFoXNm,23),  UFPE_XCursrOs( sFolders, ch ), BegPt, SIFact, x, y
	wORsX	= Nan
	wORsY	= Nan
	if ( shp == UFPE_kS_BOX )
		wORsX[ 1 ]		= ( xl - BegPt ) * SIFact
		wORsY[ 1 ]		= yt
		wORsX[ 2 ]		= ( xr - BegPt ) * SIFact
		wORsY[ 2 ]		= yt
		wORsX[ 3 ]		= ( xr - BegPt ) * SIFact
		wORsY[ 3 ]		= yb
		wORsX[ 4 ]		= ( xl - BegPt ) * SIFact
		wORsY[ 4 ]		= yb
		wORsX[ 5 ]		= ( xl - BegPt ) * SIFact
		wORsY[ 5 ]		= yt
	elseif ( shp == UFPE_kS_LINE )
		wORsX[ 1 ]		= ( xl - BegPt ) * SIFact
		wORsY[ 1 ]		= yt
		wORsX[ 2 ]		= ( xr - BegPt ) * SIFact
		wORsY[ 2 ]		= yb
	elseif ( shp == UFPE_kS_HANTEL )
		wORsX[ 1 ]		= ( xl - BegPt ) * SIFact
		wORsY[ 1 ]		= yt
		wORsX[ 2 ]		= ( xr - BegPt ) * SIFact
		wORsY[ 2 ]		= yb
	elseif ( shp == UFPE_kS_LONGHORZ  )
		wORsX[ 1 ]		= -inf
		wORsY[ 1 ]		= y
		wORsX[ 2 ]		=  inf
		wORsY[ 2 ]		= y
	elseif ( shp == UFPE_kS_BASE  )				// = { BaseRegBeg,  BaseRisePt,  BaseRegEnd,  Don't draw,  LeftScreenBorder=x=-inf,  RightScreenBorder=x=inf }  
		wORsX[ 0 ]		= ( xl - BegPt ) * SIFact
		wORsY[ 0 ]		= yt
		wORsX[ 1 ]		= (  x - BegPt ) * SIFact
		wORsY[ 1 ]		= y
		wORsX[ 2 ]		= ( xr - BegPt ) * SIFact
		wORsY[ 2 ]		= yb
//		wORsX[ 3 ]		= nan				// will not be drawn, drawing is also prevented through  zNumMrk / wMarker
//		wORsY[ 3 ]		= nan
		wORsX[ 4 ]		= -inf
		wORsY[ 4 ]		= y
		wORsX[ 5 ]		=  inf
		wORsY[ 5 ]		= y
	else							// any single point symbol ( circle, diamomd, small crosses )
		wORsX[ 0 ]		= ( x - BegPt ) * SIFact
		wORsY[ 0 ]		= y
	endif
	wORsX +=	  UFPE_XCursrOs( sFolders, ch )


End


 Function		UFPE_EvPntSetShape( sFolders, ch, rg, rtp, sWnd )
// Set color and shape of  the evaluated data points wave in the (ACQ or EVAL) traces window (but not in the OLA window) . 
// Use either Igor markers(=symbols) or draw simple shapes like a box (e.g. RT2880) or a line extending over the entire screen (e.g. base). 
// No drawing is done here, Igor will automatically update the display of the evaluated point whenever we update the value(s) in the wave.
	string  	sFolders
	variable	ch, rg, rtp										// e.g.  UFPE_kE_BASE  or  UFPE_kE_DT50 , todo implement fit results
	string  	sWnd
	wave	wRed = root:uf:acq:misc:Red, wGreen = root:uf:acq:misc:Green, wBlue = root:uf:acq:misc:Blue
	string  	sXNm	= AcqPtNmX( ch, rg, rtp )					// e.g. 'Dac0PeakX1
	string  	sYNm	= AcqPtNmY( ch, rg, rtp )					// e.g. 'Adc1BaseY0'
	string  	sFoXNm	= FoAcqPtNmX( sFolders, ch, rg, rtp )			// e.g. 'root:uf:acq:pul:ors:orsDac0PeakX1'
	string  	sFoYNm	= FoAcqPtNmY( sFolders, ch, rg, rtp )			// e.g. 'root:uf:acq:pul:ors:orsAdc1BaseY0'
	wave   /Z	wORsX	= $sFoXNm
	wave   /Z	wORsY	= $sFoYNm
	string  	lstColors	= UFCom_RemoveWhiteSpace( UFCom_lstCOLORS )
	// Check if the data point is already in the graph, only if it is yet missing then append it (this avoids multiple instances#1, #2...)
	string 		sTNL	= TraceNameList( sWnd, ";", 1 )
	if ( WhichListItem( sYNm, sTNL, ";" )  == UFCom_kNOTFOUND )			// ONLY if  wave is not in graph...

		variable	shp		= str2num( StringFromList( rtp, UFPE_klstEVL_SHAPES ) )
		variable	nColor	= WhichListItem( UFCom_RemoveWhiteSpace( StringFromList( rtp, UFPE_klstEVL_COLORS ) ), lstColors )
		 printf "\t\tEvPntSetShape \tch:%d  rg:%d  rtp:%d %s\t  t:\t%8.3lf\t  y:\t%8.3lf\t Shp:%2d\tCo:%2d\t APPENDING\t%s\t  %s\t'%s'\tX:%g %g\tY:%g %g \r", ch, rg, rtp, UFCom_pd( StringFromList(rtp, UFPE_klstEVL_RESULTS),9), x, y, shp, nColor, sFoXNm, sYNm, sWnd, wORsX[0], wORsY[0], wORsX[1], wORsY[1]
		AppendToGraph /W=$sWnd wORsY vs wORsX
		ModifyGraph 	 /W=$sWnd  rgb( 	$sYNm )	= ( wRed[ nColor ], wGreen[ nColor ], wBlue[ nColor ] ) 
		if ( shp == UFPE_kS_LINE  ||  shp == UFPE_kS_LONGHORZ  ||  shp == UFPE_kS_BOX )
			ModifyGraph 	 /W=$sWnd  mode( 	$sYNm )	= 0					// 0 : lines
		elseif ( shp == UFPE_kS_HANTEL )
			ModifyGraph 	 /W=$sWnd  mode( 	$sYNm )	= 4					// 4 : lines + markers
			ModifyGraph 	 /W=$sWnd  marker( 	$sYNm )	= UFPE_kCIRCLE
		elseif ( shp == UFPE_kS_BASE )
			ModifyGraph 	 /W=$sWnd  mode( 	$sYNm )	= 4					// 4 : lines + markers
			ModifyGraph 	 /W=$sWnd  lstyle( 	$sYNm )	= 1					// 1 : finest dottting,  2 : fine dotting,  3 : coarse dotting
			make /O /N=6  /B  /U  wMarker//	= { 10, UFPE_kS_HOURGLASS, 10, nan, 10, 10 }	// = { BaseRegBeg,  BaseRisePt,  BaseRegEnd,  Don't draw,  LeftScreenBorder=x=-inf,  RightScreenBorder=x=inf }  
			wMarker[ 0 ] = 10; wMarker[ 1 ] = UFPE_kS_HOURGLASS; 	wMarker[ 2 ] = 10; wMarker[ 3 ] = nan;  wMarker[ 4 ] = 10;  wMarker[ 5 ] = 10 
			//wMarker[ 0 ] = 10; wMarker[ 1 ] = cRECT;     		wMarker[ 2 ] = 10; wMarker[ 3 ] = nan;  wMarker[ 4 ] = 10;  wMarker[ 5 ] = 10 
			ModifyGraph 	 /W=$sWnd  zMrkNum( $sYNm)	= { wMarker }
		else
			ModifyGraph 	 /W=$sWnd  mode( 	$sYNm )	= 3					// 3 : markers	
			ModifyGraph 	 /W=$sWnd  marker( 	$sYNm )	= shp
			variable	size	= ( shp == UFPE_kSLINEH  ||  shp == UFPE_kSLINEV  ||  shp == UFPE_kSCROSS ||  shp == UFPE_kXCROSS ) ? 10 : 0	// Rect and Circle have automatic size = 0
			ModifyGraph 	 /W=$sWnd  msize( 	$sYNm )	= size
		endif
	 else
	// 	 printf "\t\tUFPE_EvPntSetShape\tch:%d  rg:%d  pt:%d %s\t  t:\t%8.3lf\t  y:\t%8.3lf\t  Shp:%2d\t%s\t(%d)\tWaves exist \t%s\t...%s\r", ch, rg, n, UFCom_pd( StringFromList(n, UFPE_klstEVL_RESULTS),9), x, y, shp, UFCom_pd(StringFromList( nColor, lstColors),5), nColor, "root:uf:eva" + sChRgNFolder + sXNm,  sYNm
		ModifyGraph  /Z /W=$sWnd	hidetrace( $sYNm ) = 0		// Display, don't hide
	endif
End



//
//#pragma rtGlobals=1		// Use modern global access method.
//#include "UF_Evalmain"
//Function test1()
//make jack=sin(x/8)
//Make/N=(128,3)/B/U jackrgb
//Make/N=(128) /B/U wMarker
//display jack
//ModifyGraph mode=3,marker=19
//jackrgb= enoise(128)+128
//wMarker= enoise(25)+25
//ModifyGraph zColor(jack)={jackrgb,*,*,directRGB}
//ModifyGraph zmrkNum(jack)={wMarker}
//end

 Function		UFPE_EvPntHide( sFolders, ch, rg, rtp , sWnd )
// Hide the evaluated data points wave in the (ACQ or EVAL) traces window (but not in the OLA window) . The trace is not removed but only hidden, which avoids the necessity to possibly append/reconstruct the trace later on.
	string  	sFolders, sWnd
	variable	ch, rg, rtp		
	string  	sYNm	= AcqPtNmY( ch, rg, rtp )				// e.g. 'Adc1BaseY0'
	string   sTNL	= TraceNameList( sWnd, ";", 1 )
	if ( WhichListItem( sYNm, sTNL, ";" )  != UFCom_kNOTFOUND )		// ONLY if  wave is  in graph (the user may have removed it)...
		 printf "\t\tUFPE_EvPntHide_\t\tch:%d  rg:%d  rtp:%d %s\t\t\t\t\t\t\t\t\t HIDING \t\t%s\t'%s'\t \r", ch, rg, rtp, UFCom_pd( StringFromList(rtp, UFPE_klstEVL_RESULTS),9), sYNm, sWnd
		ModifyGraph  /Z /W=$sWnd	hidetrace( $sYNm ) = 1		
	endif
// 2009-06-12
// should remove wave as in  EVAL   UFPE_EvPntHide_()

End


//---------- Naming for small (=1 or 2 point)  X-Y-waves containing the currently evaluated result (e.g. Peak, Base) which is drawn as a line (=Base)  or cross (=Peak) in the Acq window just over the original trace as a visual check  ------------

static Function	/S	FoAcqPtNmX( sFolders, ch, rg, rtp )
	string  	sFolders			// e.g.  'acq:pul'  or  'eva:de'
	variable	ch, rg, rtp			// e.g.  UFPE_kE_BASE  or  UFPE_kE_DT50 , todo implement fit results
	return	"root:uf:" + sFolders + ":" + UFPE_ksORS + ":" +  AcqPtNmX( ch, rg, rtp )
End

static Function	/S	FoAcqPtNmY( sFolders, ch, rg, rtp )
	string  	sFolders			// e.g.  'acq:pul'  or  'eva:de'
	variable	ch, rg, rtp			// e.g.  UFPE_kE_BASE  or  UFPE_kE_DT50 , todo implement fit results
	return	"root:uf:" + sFolders + ":" + UFPE_ksORS + ":" +  AcqPtNmY( ch, rg, rtp )
End

static Function	/S	AcqPtNmX( ch, rg, rtp )
	variable	ch, rg, rtp			// e.g.  UFPE_kE_BASE  or  UFPE_kE_DT50 , todo implement fit results
	//string  	sAcqPtNm	= RemoveWhiteSpace( StringFromList( rtp, UFPE_klstEVL_RESULTS ) ) + "_X_" + num2str( ch ) + "_" + num2str( rg )		// e.g. 'Base_X_0_1'
	string  	sAcqPtNm	= UFPE_ksORS + UFCom_RemoveWhiteSpace( StringFromList( rtp, UFPE_klstEVL_RESULTS ) ) + "_X_" + num2str( ch ) + "_" + num2str( rg )	// e.g. 'orBase_Y_0_1'
	// printf "\t\t\tAcqPtNmX( ch:%2d,  rg:%2d,  rtp:%3d )  returns '%s'  \r", ch, rg, rtp, sAcqPtNm
	return 	sAcqPtNm
End

static Function	/S	AcqPtNmY( ch, rg, rtp )
	variable	ch, rg, rtp			// e.g.  UFPE_kE_BASE  or  UFPE_kE_DT50 , todo implement fit results
	//string  	sAcqPtNm	= RemoveWhiteSpace( StringFromList( rtp, UFPE_klstEVL_RESULTS ) ) + "_Y_" + num2str( ch ) + "_" + num2str( rg )		// e.g. 'Base_Y_0_1'
	string  	sAcqPtNm	= UFPE_ksORS + UFCom_RemoveWhiteSpace( StringFromList( rtp, UFPE_klstEVL_RESULTS ) ) + "_Y_" + num2str( ch ) + "_" + num2str( rg )	// e.g. 'orBase_Y_0_1'
	// printf "\t\t\tAcqPtNmX( ch:%2d,  rg:%2d,  rtp:%3d )  returns '%s'  \r", ch, rg, rtp, sAcqPtNm
	return 	sAcqPtNm
End







//===================================================================================================================
//
//constant		kBASE_OFF = 0,  kBASE_MANUAL = 1,  kBASE_MEAN = 2,  kBASE_DRIFT = 3,  kBASE_SLOPE = 4,  kBASE_NS_CHK_USERLIM = 5,  kBASE_NS_CHK_AUTOLIM = 6  
//strconstant	klstBASE	= "off;manual;mean;drift;slope;user noise check;auto noise check;"		//  Igor does not allow this to be static!  

//Function		UFPE_fBaseOpPops( sControlNm, sFo, sWin )
//	string		sControlNm, sFo, sWin
//	PopupMenu	$sControlNm, win = $sWin,	 value = klstBASE
//End


//Function		UFPE_BaseOp_( sFolders, ch, rg )
//// Returns the currently selected base setting from the global variable underlying the 'BaseOp'  popupmenu 
//// Sample code: 'Peak dir' sets and gets value from control,  'BaseOp'  sets control and underlying variable  and  gets value from underlying variable  
//	string  	sFolders
//	variable	ch, rg
//	nvar	 /Z	nBaseOpt	= $"root:uf:" + sFolders + ":pmBaseOp" + num2str( ch ) + num2str( rg ) + "00"		//e.g. for ch 1  and  rg 0:  root:uf:eva:de:pmBaseOp1000
//	// printf "\t\t\tBaseOp_( ch:%d, rg:%d, from variable: %d \t->'%s'    \r", ch, rg, nBaseOpt-1 , StringFromList( nBaseOpt-1, klstBASE )
//	// Sample code: Handle the case when this control is missing in 1 panel  e.g.  this contol exists only in  EVAL  but not in  ACQ
//	if ( nvar_exists( nBaseOpt ) )			// If the 'BaseOp' popupmenu control exists only in  EVAL then use the control value
//		return	nBaseOpt -1 			// Only if the control and the corresponding variable exists then use the control value
//	else
//		return	kBASE_MEAN			// if there is no 'BaseOp' popupmenu control  (e.g. in  ACQ)  then we use the simplest BaseOptions case : compute single value from region given by base cursors
//	endif
//End
//
//Function		UFPE_SetBaseOp_( sFolders, ch, rg, nBaseMode )
//// Sets the base mode  in the popupmenu  (manual, mean, drift , slope...)
//// Sample code: 'Peak dir' sets and gets value from control,  'BaseOp'  sets control and underlying variable  and  gets value from underlying variable  
//	string  	sFolders
//	variable	ch, rg, nBaseMode
//	string  	sFol_ders	= ReplaceString( ":", sFolders, "_" )
//	string  	sCtrlNm	= "root_uf_" + sFol_ders + "_pmBaseOp" + num2str( ch )  + num2str( rg )  + "00"		// Set control.  (The phase in the control is (in contrast to fit phases) always 0
//	PopupMenu $sCtrlNm, win= $StringFromList( 1, sFol_ders, "_" ),   mode =  nBaseMode + 1				// 	the control setting is 1-based 
//	nvar	 /Z	nBaseOpt	= $"root:uf:" + sFolders + ":pmBaseOp" + num2str( ch ) + num2str( rg ) + "00"			// Set the underlying variable
//	nBaseOpt	= nBaseMode + 1
//End
//
//static Function		CheckNoise( sFolders, ch, rg )
//// Returns the currently selected   'Check noise'  setting from the global variable underlying the 'BaseOp'  popupmenu 
//	string  	sFolders
//	variable 	ch, rg
//	nvar		nBaseOpt		=  $"root:uf:" + sFolders + ":pmBaseOp" + num2str( ch ) + num2str( rg ) + "00"	//e.g. for ch 1  and  rg 0:  root:uf:eva:de:pmBaseOp1000
//	variable	bCheckNoise	=  nBaseOpt-1 >= kBASE_NS_CHK_USERLIM					// popmenu variables are 1-based
//	// printf "\t\t\tCheckNoise( ch:%d, rg:%d ) returns   %d    (nBaseOpt:%2d) \r", ch, rg, bCheckNoise, nBaseOpt
//	return	bCheckNoise
//End
//
//static Function		AutoUserLimit( sFolders, ch, rg )
//// Returns the currently selected    'Auto/User'   setting from the global variable underlying the 'BaseOp'  popupmenu 
//	string  	sFolders
//	variable 	ch, rg	
//	nvar		nBaseOpt		=  $"root:uf:" + sFolders + ":pmBaseOp" + num2str( ch ) + num2str( rg ) + "00"	//e.g. for ch 1  and  rg 0:  root:uf:eva:de:pmBaseOp1000
//	variable	bAutoUserLimit	=  nBaseOpt-1 == kBASE_NS_CHK_AUTOLIM					// popmenu variables are 1-based
//	// printf "\t\t\tAutoUserLimit( ch:%d, rg:%d ) returns   %d   (nBaseOpt:%2d) \r", ch, rg, bAutoUserLimit, nBaseOpt
//	return	bAutoUserLimit
//End
//
//
//static Function		BaseSlp( sFolders, ch, rg )
//// Returns the slope which determines the base value.
//	string  	sFolders
//	variable	ch, rg
//	nvar		BaseSlp	= $"root:uf:" + sFolders + ":svBaseSlp" + num2str( ch )  + num2str( rg )  + "00"	
//	 printf "\t\t\tBaseSlp( ch:%d, rg:%d ) returns: %d \t \r", ch, rg, BaseSlp
//	return	BaseSlp
//End
//
//
//static Function		SDevFactor( ch, rg )
//// Returns the factor with which the base standard deviation is multiplied  to  allow a comparison with the peak height  to determine whether the event is valid.
//	variable	ch, rg
//	nvar		SDevFct	= $"root:uf:eva:de:svSDevFact" + num2str( ch )  + num2str( rg )  + "00"	
//	// printf "\t\t\tSDevFactor( ch:%d, rg:%d ) returns: %d \t \r", ch, rg, SDevFct
//	return	SDevFct
//End

//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//constant		kPEAK_OFF = 0,  kPEAK_UP = 1,  kPEAK_DOWN = 2
//strconstant	klstPEAKDIR 	= "off;up;down;"								//  Igor does not allow this to be static!  

//Function		UFPE_fPkDirPops( sControlNm, sFo, sWin )
//	string		sControlNm, sFo, sWin
//	// printf "\t\tUFPE_fPkDirPops( sControlNm: '%s', sFo: '%s', sWin: '%s' ) \tklstPEAKDIR: '%s' \r", sControlNm, sFo, sWin, klstPEAKDIR
// 	PopupMenu	$sControlNm, win = $sWin,	 value = klstPEAKDIR
//End
//
//Function	/S	UFPE_PeakDirStr( nPeakDir )
//	variable	nPeakDir
//	return	StringFromList( nPeakDir, klstPEAKDIR )
//End


Function		UFPE_PeakDir( sFolders, ch, rg )
// Returns the currently selected peak direction  in the popupmenu : returns 0 for off, 1 for upward  and 2 for downward
// Sample code: 'Peak dir' sets and gets value from control,  'BaseOp'  sets and gets value from underlying variable  
	string  	sFolders
	variable	ch, rg
	string  	sFol_ders	= ReplaceString( ":", sFolders, "_" )
	string  	sCtrlNm	= "root_uf_" + sFol_ders + "_pmUpDn" + num2str( ch )  + num2str( rg )  + "00"		// the phase in the control is (in contrast to fit phases) always 0 (and not UFPE_kC_PHASE_PEAK) 
	ControlInfo /W= $StringFromList( 1, sFol_ders, "_" )  $sCtrlNm
	variable	nDir	= V_Value - 1							// 1-based 
	// printf "\t\t\tPeakDir( '%s', ch:%d, rg:%d, from Popupmenu( %s ): %d \t->'%s'  \r", sFolders, ch, rg, sCtrlNm, nDir , StringFromList( nDir, klstPEAKDIR )
	return	nDir
End

Function		UFPE_SetPeakDir( sFolders, ch, rg, nPeakDir )
// Sets the peak direction  in the popupmenu :  0 for off, 1 for upward  and 2 for downward
// Sample code: 'Peak dir' sets and gets value from control,  'BaseOp'  sets and gets value from underlying variable  
	string  	sFolders
	variable	ch, rg, nPeakDir
	string  	sFol_ders	= ReplaceString( ":", sFolders, "_" )
	string  	sCtrlNm	= "root_uf_" + sFol_ders + "_pmUpDn" + num2str( ch )  + num2str( rg )  + "00"		// the phase in the control is (in contrast to fit phases) always 0 (and not UFPE_kC_PHASE_PEAK) 
	PopupMenu $sCtrlNm, win= $StringFromList( 1, sFol_ders, "_" ),   mode =  nPeakDir + 1					// 1-based 
	// printf "\t\t\tUFPE_SetPeakDir( ch:%d, rg:%d, from Popupmenu( %s ): %d \t->'%s'  \r", ch, rg, sCtrlNm, nPeakDir , StringFromList( nPeakDir, klstPEAKDIR )
	// ControlUpdate /W= $ksDE $sCtrlNm												// seems not to be required	
End


static Function		PeakSidePts( sFolders, ch, rg )
// Returns the number of points on each side side of a peak over which is to be averaged.  0 means no averaging, 2 means average over 5 points
	string  	sFolders
	variable	ch, rg
	nvar		nPeakSidePts	= $"root:uf:" + sFolders + ":svSideP" + num2str( ch )  + num2str( rg )  + "00"	// the phase in the control is (in contrast to fit phases) always 0 (and not UFPE_kC_PHASE_PEAK) 
	// printf "\t\t\tPeakSidePts( '%s', ch:%d, rg:%d ) returns: %d \t \r", sFolders, ch, rg, nPeakSidePts
	return	nPeakSidePts
End

Function		UFPE_Rser_mV( sFolders, ch, rg )
// Returns the pulse amplitude of the Rseries measurement pulse  (usually 5 or 10 mV)
	string  	sFolders
	variable	ch, rg
	string  	sRserMvNm = "root:uf:" + sFolders + ":svRserMV" + num2str( ch )  + num2str( rg )  + "00"	
	nvar	  /Z	RserMV	   = $sRserMvNm
	// printf "\t\t\tRserMV( '%s', ch:%d, rg:%d )  exists:%d    -->  returns: %d  mV =   %g V  \t \r", sRserMvNm, ch, rg, nvar_exists( RserMV ), RserMV, RserMV / 1000
	return	RserMV / 1000
End

//===================================================================================================================

 Function	UFPE_QuitCursorPositioning( sFolders, sWnd, bSaveCursor, LatCnt, FitCnt )
// Finish positioning ONE cursor by shrinking the crosshair to normal cursor. Store the last cursor position in its corresponding region.
	string  	sFolders, sWnd
	variable	bSaveCursor, LatCnt, FitCnt
	wave	wPrevRegion	= $"root:uf:" + sFolders + ":wPrevRegion"
	variable	ch			= wPrevRegion[ UFPE_kCH ]				// has previously been stored during 'MoveCursor()'
	variable	rg			= wPrevRegion[ UFPE_kRG ]				// ...
	variable	ct			= wPrevRegion[ UFPE_kCT ]				// ...
	variable	nc			= wPrevRegion[ UFPE_kNC ]				// ...
	variable	nCsr			= wPrevRegion[ UFPE_kCURSOR ]			// ...
	string  	sCursorAorB	= SelectString( nCsr, "A", "B" )			// 0 is cursor A, 1 is cursor B 
variable	yPos= Nan

	if ( WinType( sWnd ) == UFCom_WT_GRAPH )							// the user may have killed the graph with the unfinished crosshair cursor
		variable CursorExists= strlen( CsrInfo( $sCursorAorB, sWnd ) ) > 0	// the 1. parameter (cursor A or B) is a name, not a string
		if ( CursorExists )
			variable	BegPt = 0, SIFact = 1, nCurSwpDummy = -1 	
			variable	Top = inf, Bottom = -inf
			if ( bSaveCursor )								// Only  CR  saves the new position. If the user had pressed  ESC then the previous position will not be changed. 
				variable	ph	= UFPE_Csr2Ph( sFolders, ct, nc, LatCnt )
				variable	xPos	= hcsr( $sCursorAorB, sWnd )
				// 2006-0502
				if ( UFPE_BaseOp_( sFolders, ch, rg ) == kBASE_MANUAL )
					yPos		= vcsr( $sCursorAorB, sWnd )
					UFPE_EvalSet( sFolders, ch, rg, UFPE_kE_BASE, UFPE_kY,		yPos )	
					UFPE_EvalSet( sFolders, ch, rg, UFPE_kE_BASE, UFPE_kVAL,		yPos )
					 printf "\tQuitCursorPositioning( bDoSave:%2d )  retrieves  \tch:%d   \trg:%d   \t %s\t%d\tCursor%2d %s \tSaving pos:%g (y:%g) [BASE=MANUAL] \r", bSaveCursor, ch, rg, UFCom_pd( UFCom_RemoveWhiteSpace( StringFromList( ct, UFPE_kCSR_NAME) ), 8), nc, nCsr, sCursorAorB, UFPE_CursorX( sFolders, ch, rg, ph, UFPE_CN_BEG + nCsr), yPos
				endif
				UFPE_SetCursorX( sFolders, ch, rg, ph, UFPE_CN_BEG + nCsr, xPos )	

// 2006-0510d
				// A peak/base evaluation can only succeed if both base and both peak cursors have beeen set before and are valid 
//				OnePeakBase( sFolders, ch, rg, BegPt, SIFact, nCurSwpDummy )	// 2006-05010   Do a peak/base determination immediately so that the effect of shifted cursors can visually be verified

			endif
			Cursor 	/W=$sWnd /K  $sCursorAorB				// Remove the crosshair cursor from the graph
			HideInfo	/W=$sWnd							// Remove the Cursor control box  (this control box is not mandatory for cursor usage) ...

// 2006-0502
//			CursorGetYAxis( sWnd, Top, Bottom )

			UFPE_CursorSetValue( 	sFolders, ch, rg, ct, nc, nCsr,  BegPt, SIFact, Top, Bottom, LatCnt, FitCnt )
			CursorDisplay( 		sFolders, ch, rg, ct, nc, nCsr, sWnd, LatCnt )		// Append the cursor wave to the graph if the graph does not yet contain this cursor . This is the ONLY location where the cursor is added to the graph so resist removing it!

			 printf "\tQuitCursorPositioning( bDoSave:%2d )  retrieves  \tch:%d   \trg:%d   \t %s\t%d\tCursor%2d %s \tSaving pos:%g (y:%g) \r", bSaveCursor, ch, rg, UFCom_pd( UFCom_RemoveWhiteSpace( StringFromList( ct, UFPE_kCSR_NAME) ), 8), nc, nCsr, sCursorAorB, UFPE_CursorX( sFolders, ch, rg, ph, UFPE_CN_BEG + nCsr), yPos
		else
			// printf "\tQuitCursorPositioning( bDoSave:%2d )  failed in graph '%s'  :  cursor  '%s'  does  not exist. ( May be OK! ) \t  \r", bSaveCursor, sWndNm, sCursorAorB
		endif
	else
		printf "\tQuitCursorPositioning( bDoSave:%2d )  failed as graph '%s'  could not be found. \t  \r", bSaveCursor, sWnd
	endif
End


//=================================================================================================================================================
//  LATENCIES

//constant		kLAT_OFF=0,  kLAT_MANUAL=1,  kLAT_BR=2,  kLAT_RT5=3,  kLAT_RSLP=4,  kLAT_PK=5,  kLAT_DT5=6
//strconstant	klstLATC = "off;ma;BR;R5;Sl;Pk;D5;"		// first letters must all differ as they are use to build the  Select-listbox-text 
//

Function		UFPE_fLatCsrPops( sControlNm, sFo, sWin )
	string		sControlNm, sFo, sWin
	// print "\t\tUFPE_fLatCsrPops()",  sControlNm, sFo, sWin
	PopupMenu	$sControlNm, win = $sWin,	 value = klstLATC
End

Function	/S	ListACVLat( sFolders, nThisCh, nThisRg, nChannels, latCnt )
// Returns list of all latencies specified by channel and region (the end value determines the channel and region)
// We need 2 steps because the latency index  and  BegEnd   are not ordered in respect to channel and region
	string  	sFolders	//= "eva:de"
	variable	nThisCh, nThisRg, nChannels
	variable	LatCnt
	string  	lst		= ""	
	variable	BegEnd, lc
	variable	ch, rg, rgCnt, nLatOp	
	string  	sLatOp

	make /O /T /N=( nChannels, UFPE_kRG_MAX, LatCnt, 2 )  $"root:uf:" + sFolders + ":wTmpLatNames" = ""
	wave      /T  wTmpLatNames =  $"root:uf:" + sFolders + ":wTmpLatNames"

	// Step 1: Store all extracted  popupmenu settings in a 4 dim temporary wave. Only after this pass we can be sure that all settings are valid. 
	for ( lc = 0; lc < LatCnt; lc += 1 )
		for ( BegEnd = UFPE_CN_BEG; BegEnd <=  UFPE_CN_END; BegEnd += 1 )
			for ( ch = 0; ch < nChannels; ch += 1)
				rgCnt	= UFPE_RegionCnt( sFolders, ch )
				for ( rg = 0; rg < rgCnt;  rg += 1 )	
					nLatOp	= UFPE_LatC( sFolders, ch, rg, lc, BegEnd )
					sLatOp	= StringFromList( nLatOp, klstLATC )
					if ( nLatOp != kLAT_OFF )
						wTmpLatNames[ ch ][ rg ][ lc ][ BegEnd ] = UFPE_LatNm( sFolders, lc, BegEnd, ch, rg ) 
						// printf "\t\tListACVLat( a  ch:%d, rg:%d )\tlat:%2d/%2d\t  ch:%d   rg:%d\t%s\tLatOp:%2d\t(%s) \tLatNm:%s\t  \r", nThisCh, nThisRg, lc, LatCnt, ch, rg,  SelectString( BegEnd, "Beg:    " , "  -> End:" ), nLatOp, sLatOp, UFCom_pd(wTmpLatNames[ ch ][ rg ][ lc ][ BegEnd ] ,12)
					endif
				endfor
			endfor
		endfor
	endfor
	
	// Step 2: Only after all extracted  popupmenu settings have been stored  in a 4 dim temporary wave we can extract them from there in any order.
	for ( lc = 0; lc < LatCnt; lc += 1 )
		for ( BegEnd = UFPE_CN_BEG; BegEnd <=  UFPE_CN_END; BegEnd += 1 )
			for ( ch = 0; ch < nChannels; ch += 1)
				rgCnt	= UFPE_RegionCnt( sFolders, ch )
				for ( rg = 0; rg < rgCnt;  rg += 1 )	
					// 2006-0314
					if ( strlen( wTmpLatNames[ ch ][ rg ][ lc ][ BegEnd ] ) )							 // most of them are empty strings  
						if (  BegEnd ==  UFPE_CN_BEG )	
							lst  += wTmpLatNames[ ch ][ rg ][ lc ][ BegEnd ] + UFPE_ChRgPostFix( nThisCh, nThisRg ) + ";" //  add a temporary postfix and list delimiter. This avoids that the text of the next cell  (e.g. 'Q0' ) is appended temporarily to the unfinished latency text. 
						endif
						// printf "\t\tListACVLat( b  ch:%d, rg:%d )\tlat:%2d/%2d\t  ch:%d   rg:%d\t%s\tlst: '%s' \t  \r", nThisCh, nThisRg, lc, LatCnt, ch, rg,  SelectString( BegEnd, "Beg:    " , "  -> End:" ), lst[0,200]
						if (  BegEnd ==  UFPE_CN_END )	
							lst  =  UFPE_ChRgPostFixStrip_( RemoveEnding( lst, ";" ) )							 //  remove the temporary postfix and list delimiter  added in the previous line  e.g. 'L0_R00_01;' -> 'L0_R00'
							lst  += wTmpLatNames[ ch ][ rg ][ lc ][ BegEnd ] + UFPE_ChRgPostFix( nThisCh, nThisRg ) + ";" //  add postfix and delimiter  e.g. 'L0_R00' -> 'L0_R00S00_01;''
						endif
						// printf "\t\tListACVLat( c  ch:%d, rg:%d )\tlat:%2d/%2d\t  ch:%d   rg:%d\t%s\tlst: '%s' \t  \r", nThisCh, nThisRg, lc, LatCnt, ch, rg,  SelectString( BegEnd, "Beg:    " , "  -> End:" ), lst[0,200]
					endif
				endfor
			endfor
		endfor
// 2006-0314
//		lst  +=  PostFix( nThisCh, nThisRg ) + ";"			//  add the list delimiter 
		// printf "\t\tListACVLat( d  ch:%d, rg:%d )\tlat:%2d/%2d\t lst: '%s' \r", nThisCh, nThisRg, lc, LatCnt,  lst[0,200]
	endfor

	KillWaves  $"root:uf:" + sFolders + ":wTmpLatNames"
	return	lst
End	


Function	/S	UFPE_LatNm( sFolders, lc, BegEnd, ch, rg )
// Builds partial  latency name (=first or second half)  e.g. for the begin  'Lat1m01'  but  for the end only   'R22'  . Both parts must be catenated elsewhere!
	string  	sFolders
	variable	lc, BegEnd, ch, rg
	variable	nLatOp	= UFPE_LatC( sFolders, ch, rg, lc, BegEnd )
	string		sLatOp	= StringFromList( nLatOp, klstLATC )
	// e.g. for the begin  'Lat1m01'  but  for the end only   'R22'  .  Both parts must be catenated elsewhere!
	return	SelectString( BegEnd, ksLAT_BASENM + num2str( lc ) + ksLAT_SEPAR + sLatOp[ 0, kLAT_DESC_LENGTH-1 ] + num2str( ch ) + num2str( rg ),   sLatOp[ 0, kLAT_DESC_LENGTH-1 ] + num2str( ch ) + num2str( rg ) )	
End

Function		UFPE_LatC( sFolders, ch, rg, lc, BegEnd )
// Returns the currently selected  latency setting from the global variable underlying the 'Latency'  popupmenu 
	string  	sFolders
	variable	ch, rg, lc, BegEnd
	nvar		nLatC	= $"root:uf:" + sFolders + ":pmLat" + num2str( lc )  + num2str( BegEnd )  + num2str( ch ) + num2str( rg ) + "00"	//e.g. for  LatC 0   and   End   and   ch 1   and   rg 0:  root:uf:eva:de:pmLat011000
	// printf "\t\t\tLatC( lc:%d, BegEnd:%d, ch:%d, rg:%d, from variable: %d \t->'%s'  \r", lc, BegEnd, ch, rg, nLatC-1 , StringFromList( nLatC-1, klstLATC )
	return	nLatC - 1		// popmenu variables are 1-based
End


Function	UFPE_AllLatenciesCheck( sFolders, nChans, LatCnt )
 // Check that the user makes only legal  selections in the popmenu (can only define the beginning or the end of a latency cursor once!)
// Todo: TurnRemainingLatenciesOff()  : If 1 latency option( lc, begEnd ) is is turned on, disable  those with the same (lc, begEnd)   in all other channels and regions. This automatically prevents the user error defining a latency twice.
// Todo: Possibly check for same setting beg = end (trivial and obvious case resulting in value 0)
 	string  	sFolders
 	variable	nChans, LatCnt
 	string  	sFolder	= StringFromList( 0, sFolders, ":" ) 		// 'eva:de' -> 'eva' ,  'acq:pul' -> 'acq'
	variable	BegEnd, lc
	variable	ch, rg, rgCnt, nLatOp, nFoundDoubleEntry	 = 0
	string  	sTxt
	make  /O	/I  /N=( LatCnt, 2 )  wLatCheckDoubleEntry = 0
	for ( lc = 0; lc < LatCnt; lc += 1 )
		for ( BegEnd= UFPE_CN_BEG; BegEnd <=  UFPE_CN_END; BegEnd += 1 )
			for ( ch = 0; ch < nChans; ch += 1)
				rgCnt	= UFPE_RegionCnt( sFolders, ch )
				for ( rg = 0; rg < rgCnt;  rg += 1 )	
					nLatOp	= UFPE_LatC( sFolders, ch, rg, lc, BegEnd )
					if ( nLatOp != kLAT_OFF )
						wLatCheckDoubleEntry[ lc ][ BegEnd ] += 1
						if ( wLatCheckDoubleEntry[ lc ][ BegEnd ]  > 1 )
							sprintf sTxt, "The %s of latency %d is defined multiple times.", SelectString( BegEnd, "beginning" , "end" ), lc 
							UFCom_Alert( UFCom_kERR_IMPORTANT, sTxt )
							nFoundDoubleEntry += 1
						endif						
						// printf "\t\tAllLatenciesCheck() \tl:%d/%d\t   BegEnd:%d   ch:%d   rg:%d\t%s Latc:%2d\t(%s)   \r", lc, LatCnt, BegEnd, ch, rg,  SelectString( BegEnd, "beg: " , "\t\t\t\t -> end: " ), nLatOp, StringFromList( nLatOp, klstLATC )
					endif
				endfor
			endfor
		endfor
	endfor
	if ( nFoundDoubleEntry == 0 )	// if  we had the above error (=double entries) we do not want to report this error again
		for ( lc = 0; lc < LatCnt; lc += 1 )
			variable	bMissing =  wLatCheckDoubleEntry[ lc ][ UFPE_CN_BEG ]  - wLatCheckDoubleEntry[ lc ][ UFPE_CN_END ] 	// should be 1-1 = 0
			if ( bMissing )		
				sprintf sTxt, "The %s of latency %d is missing while the %s is defined.", SelectString( bMissing, "beginning" , "", "end" ),  lc, SelectString( -bMissing, "beginning" , "", "end" ) 
				UFCom_Alert( UFCom_kERR_IMPORTANT, sTxt )
			endif
		endfor
	endif
	killWaves  wLatCheckDoubleEntry
End

// W W W W  W  W  W  W d   should be Ohm

//  NOT  YET WORKING
// Function		TurnRemainingLatenciesOff( sThisCtrlNm, nThisLat, nThisBegEnd, nThisCh, nThisRg )
//// Two advantages: 1. Prevent that the user accidentally redefines this latency in another channer or region.  2. Tidy up the panel. 
////..BUT does not work as all hidden popmenus are restored whenever tabs are clicked. -> must recognise hidden state then
//	string  	sThisCtrlNm
//	variable	nThisLat, nThisBegEnd, nThisCh, nThisRg
//	nvar		gChannels	= root:uf:cfsr:gChannels
//	variable	LatCnt	= LatencyCnt( )
//	variable	ch, rg, rgCnt, len = strlen( sThisCtrlNm )
//	string  	sCtrlBaseNm	= sThisCtrlNm[ 0, len - 7 ]
//	string  	sCtrlNm
//	variable	nLatOp	= UFPE_LatC( nThisCh, nThisRg,  nThisLat, nThisBegEnd )
//	for ( ch = 0; ch < gChannels; ch += 1)
//		rgCnt	= UFPE_RegionCnt( sFolders, ch )
//		for ( rg = 0; rg < rgCnt;  rg += 1 )	
//			sCtrlNm	= sCtrlBaseNm + num2str( nThisLat ) + num2str( nThisBegEnd ) + num2str( ch ) + num2str( rg ) + "00"
//
//			if ( ch == nThisCh  &&  rg == nThisRg )
//				 printf "\t\tTurnRemainingLatenciesOff( ON a )\tThisLat:%d/%d\t   ThisBegEnd:%d   ch:%d   rg:%d\tThisCNm:%s   OtherCNm:%s   \r", nThisLat, LatCnt, nThisBegEnd, ch, rg, sThisCtrlNm, sCtrlNm
//			else
//				if ( nLatOp != kLAT_OFF )
//					 printf "\t\tTurnRemainingLatenciesOff( OFF )\tThisLat:%d/%d\t   ThisBegEnd:%d   ch:%d   rg:%d\tThisCNm:%s   OtherCNm:%s   \r", nThisLat, LatCnt, nThisBegEnd, ch, rg, sThisCtrlNm, sCtrlNm
//					PopupMenu	$sCtrlNm disable = 1		// normal:0,  hide:1,  grey:2
//				else
//					 printf "\t\tTurnRemainingLatenciesOff( ON b )\tThisLat:%d/%d\t   ThisBegEnd:%d   ch:%d   rg:%d\tThisCNm:%s   OtherCNm:%s   \r", nThisLat, LatCnt, nThisBegEnd, ch, rg, sThisCtrlNm, sCtrlNm
//					PopupMenu	$sCtrlNm disable = 0		// normal:0,  hide:1,  grey:2
//				endif
//			endif
//		endfor
//	endfor
//End

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//   BIG   HELPERS

Function		UFPE_EvaluateMeanAndSDev( sFolders, wWave, ch, rg ) 
	string  	sFolders
	wave	wWave
	variable	ch, rg
	WaveStats /Q  wWave					// First get wave average and deviation in the given time interval 
	// printf "\t\tEvaluateMeanAndSDev() \t\tch:%2d  rg:%2d \tpts:%8d\t Mean: %g  sDev:%g \r", ch, rg, numpnts( wWave), V_avg, V_sdev
	UFPE_EvalSet( sFolders, ch, rg, UFPE_kE_MEAN, UFPE_kY,	V_avg )		
	UFPE_EvalSet( sFolders, ch, rg, UFPE_kE_MEAN, UFPE_kVAL,	V_avg )
	UFPE_EvalSet( sFolders, ch, rg, UFPE_kE_SDEV, UFPE_kY,	V_sdev )		
	UFPE_EvalSet( sFolders, ch, rg, UFPE_kE_SDEV, UFPE_kVAL,	V_sdev )
End

static Function		AutomaticBaseRegion( sFolders, wWave, ch, rg, BaseL, BaseR, rBaseT, rBaseB )
// guess the allowed baseline band from the noise in the given interval[ BaseL, BaseR ]
	string  	sFolders
	wave	wWave
	variable	ch, rg, BaseL, BaseR, &rBaseT, &rBaseB
	variable	HalfWidth, MinMaxY, Average
	WaveStats /Q  /R=( BaseL, BaseR ) wWave					// First get wave average and deviation in the given time interval 
	Average	= V_avg
	HalfWidth	= V_sdev	* 1									// arbitrarily assume a band based on the noise level found in the interval
	wave	wMnMx	= $"root:uf:" + sFolders + ":wMnMx"			// But when there is little or no noise the band is too small and must be widened...
	MinMaxY	= wMnMx[ ch ][ UFPE_kMM_YMAX ] - wMnMx[ ch ][ UFPE_kMM_YMIN ]	// TODO  Arbitrarily assume a band based on the minimum and maximum of complete wave...  
	HalfWidth	= max( HalfWidth, MinMaxY * .02 )					// ...which is wrong as it does not take into account whether there is a synaptic event or not.....
	// printf "\t\tAutomaticBaseRegion() \t%s\tBaseL:%5.1lf, BaseR:%5.1lf, ch:%d, MinMaxY:%5.1lf , HalfWidth:%5.1lf, Average:%5.1lf \r", sFolders, BaseL, BaseR, ch, MinMaxY, HalfWidth, Average
	rBaseT	= Average + HalfWidth
	rBaseB	= Average  - HalfWidth 
End


 Function		UFPE_EvaluateBase( sFolders, wWave, ch, rg, nCurSwp, BegPt, SIFact )//, bDoNoiseCheck )									
//	get the BASE value when time range is given. Check if base is too noisy and mark this record
// to do : more nSECTIONS -> more tests -> then allow 1 or 2 failures
//todo let slope also store BASE NOISE????
	string  	sFolders
	wave	wWave
	variable	ch, rg, nCurSwp
	variable	BegPt, SIFact
	variable	rTop, rBot
	variable	XaxisLeft		= UFPE_XaxisLft( sFolders, ch )
	variable	nPrintMask	=  UFPE_PrintMask_( sFolders )
	variable	nBaseOpt		= UFPE_BaseOp_( sFolders, ch, rg )
	variable	Beg			= UFPE_CursorX( sFolders, ch, rg, UFPE_kC_PHASE_BASE, UFPE_CN_BEG )	 // get the time range in which to evaluate the base 
	variable	Ende			= UFPE_CursorX( sFolders, ch, rg, UFPE_kC_PHASE_BASE, UFPE_CN_END )	 //
	string		sMsg
	variable	xOs			= UFPE_XCursrOs(sFolders,ch)
	variable	BaseX
	variable	TrigSlope, nPeakDir = 0, PeakTime = 0, MeanValue = 0	// for BASE_SLOPE
	
	variable	dltax			= deltax( wWave ) 							
	variable	pts			= ( Ende - Beg ) / dltax / SIFact - 1					// one point less because the last point may already be in the artefact
	variable	AvgValue

	WaveStats /Q  /R=( Beg / SIFact, 	Ende / SIFact ) wWave					// Measure  standard deviation of the entire base region
	variable	sDevValue 	= V_sdev

	WaveStats /Q  /R=( Beg / SIFact, 	( Beg + Ende ) / 2 / SIFact ) wWave			// Measure average of the left half of the base region
	variable	AvgValue1	 = V_avg

	WaveStats /Q  /R=( ( Beg + Ende ) / 2 / SIFact,	  Ende / SIFact ) wWave			// Measure average of the right half of the base region
	variable	AvgValue2	 = V_avg


Beg-=xOs	// 2006-0413 refer to peak onset
Ende-=xOs
	if ( nBaseOpt == kBASE_OFF )
		AvgValue	= Nan												// Nan  will  (later) prevent that the base line is drawn
	elseif ( nBaseOpt == kBASE_MANUAL )
		// 2006-0502
		AvgValue	= UFPE_EvY( sFolders, ch, rg, UFPE_kE_BASE )	
		AvgValue1=   AvgValue
		AvgValue2=   AvgValue
		BaseX	= ( Beg + Ende ) / 2
		// BaseX	=  Ende 				// 2006-0510b  test    not good.... weg
	elseif ( nBaseOpt == kBASE_MEAN )
		AvgValue	= ( AvgValue1 + AvgValue2 ) / 2
		AvgValue1=   AvgValue
		AvgValue2=   AvgValue
		BaseX	= ( Beg + Ende ) / 2
	elseif ( nBaseOpt == kBASE_DRIFT )
		AvgValue1= ( 3*AvgValue1 + - AvgValue2 ) / 2							// Extrapolate linearly through from the left avg value (t=1/4) over the right avg value (t=3/4)  to the left border  (t=0)
		AvgValue2= ( -AvgValue1 + 3 * AvgValue2 ) / 2							// Extrapolate linearly through from the left avg value (t=1/4) over the right avg value (t=3/4)  to the right border  (t=1)
		AvgValue	=  AvgValue2											// The extrapolated value at the right border
		BaseX	= Ende 
	elseif ( nBaseOpt == kBASE_SLOPE )
		nPeakDir	= UFPE_PeakDir( sFolders, ch, rg )
		PeakTime	= UFPE_EvT( sFolders, ch, rg, UFPE_kE_PEAK )
		MeanValue=UFPE_EvV( sFolders, ch, rg, UFPE_kE_MEAN )
		TrigSlope	= BaseSlp( sFolders, ch, rg )
		AvgValue	= Slope2Base( sFolders, wWave, ch, rg, nCurSwp, BegPt, SIFact, nPeakDir, PeakTime+xOs, TrigSlope, MeanValue, BaseX ) // sets BaseX
		AvgValue1=   AvgValue
		AvgValue2=   AvgValue
		UFPE_EvalSet( sFolders, ch, rg, UFPE_kE_BASE, UFPE_kT, 	BaseX  )
		UFPE_EvalSet( sFolders, ch, rg, UFPE_kE_BASE, UFPE_kY, 	AvgValue )
		UFPE_EvalSet( sFolders, ch, rg, UFPE_kE_BASE, UFPE_kVAL, 	AvgValue )
		// Ende = BaseX ???
	endif																// Different approach (not taken) : Fit the straight line 
		
	UFPE_EvalSet( sFolders, ch, rg, UFPE_kE_BASE, UFPE_kTB,		Beg )	
	UFPE_EvalSet( sFolders, ch, rg, UFPE_kE_BASE, UFPE_kTE,		Ende )
	UFPE_EvalSet( sFolders, ch, rg, UFPE_kE_BASE, UFPE_kYB,		AvgValue1 )	
	UFPE_EvalSet( sFolders, ch, rg, UFPE_kE_BASE, UFPE_kYE,		AvgValue2 )	
	UFPE_EvalSet( sFolders, ch, rg, UFPE_kE_BASE, UFPE_kY,			AvgValue )	
	UFPE_EvalSet( sFolders, ch, rg, UFPE_kE_BASE, UFPE_kVAL,		AvgValue )					// Version1: the base value is the value of the trailing base segment (which is right before the peak) 
	UFPE_EvalSet( sFolders, ch, rg, UFPE_kE_SDBASE, UFPE_kY,		SDevValue )	
	UFPE_EvalSet( sFolders, ch, rg, UFPE_kE_SDBASE, UFPE_kVAL,	SDevValue )	
//ltl
//	 printf "\t\tEvaluateBase( %s\tch:%d  rg:%d  FrSwp:\t%3d\tSl:%d\tBg:\t%5.3lfs\tEn:\t%5.3lf\t\txos:\t%7g\tPts(wO):\t%7d\tBegPt:\t%7g\tdltax:\t%8.6lf\tSF:\t%7.4lf\tx:\t%8.3lf\tBsVal:\t%7g\tPts:\t%7.2lf\tAxLft:\t%7g\t[PD:%d PT:%g] BX:%7g\t  \r", 
//sFolders, ch, rg, nCurSwp, UFPE_kBASE_SLICES, Beg, Ende, xOs, numPnts(wWave), BegPt, dltax, SIFact, Beg, AvgValue, Pts, XaxisLeft, nPeakDir, PeakTime, BaseX

// 2006-0411a	
//	EvPntSetValue( sFolders, ch, rg, UFPE_kE_BASE,  BegPt, SIFact,  (Beg/2 + Ende/2) / SIFact, 	AvgValue,  Beg / SIFact,  		AvgValue,  Ende / SIFact, 		AvgValue )	// !!! OK
	EvPntSetValue( sFolders, ch, rg, UFPE_kE_BASE, 0, 1,  		BaseX - BegPt*SIFact , AvgValue,  Beg - BegPt*SIFact,  AvgValue1,  Ende - BegPt*SIFact, AvgValue2 )	// !!! OK

	return	AvgValue
End


// 2006-0412a   LAST  VERSION  WHICH  INCLUDES  NOISE CHECK :  KEEP !!!

// Function		UFPE_EvaluateBase( sFolders, wWave, ch, rg, nCurSwp, BegPt, SIFact )//, bDoNoiseCheck )									
////	get the BASE value when time range is given. Check if base is too noisy and mark this record
//// to do : more nSECTIONS -> more tests -> then allow 1 or 2 failures
////todo let slope also store BASE NOISE????
//	string  	sFolders
//	wave	wWave
//	variable	ch, rg, nCurSwp
//	variable	BegPt, SIFact
//	variable	Beg, Ende, rTop, rBot
//	Beg		= UFPE_CursorX( sFolders, ch, rg, UFPE_kC_PHASE_BASE, UFPE_CN_BEG )	 // get the time range in which to evaluate the base 
//	Ende		= UFPE_CursorX( sFolders, ch, rg, UFPE_kC_PHASE_BASE, UFPE_CN_END )	 //
//
//// 2006-0412 here new       Code can be simplified   and   'bDoNoiseCheck'   can be avoided.....
//	variable	bDoNoiseCheck		
//	if ( CheckNoise( sFolders, ch, rg ) )		
//		if ( AutoUserLimit( sFolders, ch, rg ) )										// use automatically  determined limits for the noise check or use limits set by the user
////			AutomaticBaseRegion( sFolders, wOrg, ch, rg, msBeg, msEnd, rTop, rBot ) 		// guess the allowed baseline band from the noise in the given interval[ BaseL, BaseR ]
//			AutomaticBaseRegion( sFolders, wOrg, ch, rg, Beg, Ende, rTop, rBot ) 		// guess the allowed baseline band from the noise in the given interval[ BaseL, BaseR ]
//			SetBandY( sFolders, ch, rg, UFPE_kC_PHASE_BASE, rTop, rBot )
//		// else
//			// UserBaseBandY( sFolders, ch, rg, UFPE_kC_PHASE_BASE, rTop, rBot )			// UserBaseBandY( ) = BandY()   get the user's Hi and Lo values  (stored separately so that they don't get overwritten when the user..
//			// SetBandY( 	     sFolders, ch, rg, UFPE_kC_PHASE_BASE, rTop, rBot )			//...switches temporarily into 'auto' mode   and copy them into the evaluation region 
//		endif
//		bDoNoiseCheck	= ON
//	else
//		SetBandY( sFolders, ch, rg, UFPE_kC_PHASE_BASE, ( wWave(Beg) + wWave(Ende) ) / 2, ( wWave(Beg) + wWave(Ende) ) / 2  )	//around the trace
//		bDoNoiseCheck	= UFCom_kOFF
//	endif
//
//
//	variable	XaxisLeft		= UFPE_XaxisLft( sFolders, ch )
//	variable	nPrintMask	=  UFPE_PrintMask( sFolders )
//	string		sMsg
//	variable	AvgValue		= 0 
//	variable	SDevValue	= 0 
//	variable	BandAvgHi, BandAvgLo
//	string		sFolder		= StringFromList( 0, sFolders, ":" )
//	variable	dltax			= deltax( wWave ) 							
//	variable	n, pts		= ( Ende - Beg ) / dltax / SIFact - 1								// one point less because the last point may already be in the artefact
//
//	BandY( sFolders, ch, rg, UFPE_kC_PHASE_BASE, BandAvgHi, BandAvgLo )							// get the allowed band
//	if ( bDoNoiseCheck )
//	// todo : there could be rounding errors if   'pts / UFPE_kBASE_SLICES'  leaves a remainder   AND  check the inclusion/exclusion of thr last point  
//		variable	nSlicePts	= trunc ( pts / UFPE_kBASE_SLICES )
//		variable	DurSlice	= nSlicePts * dltax
//		variable	bTooNoisy		= 0
//		for ( n = 0; n < UFPE_kBASE_SLICES; n += 1 )
//			// Error occurs with empty channels (PATCH600!) . WavStats  error is mixed up with  FindLevel  error  .....
//			WaveStats /Q  /R=( Beg / SIFact + n * DurSlice, Beg / SIFact + ( n + 1 ) * DurSlice ) wWave		// Measure average and standard deviation of every slice...
//			if ( GetRTError(0) )
//				print "****Internal warning : UFPE_EvaluateBase() : " + GetRTErrMessage()
//				variable dummy = GetRTError(1)
//			endif
//			if ( V_avg  < BandAvgLo	||   BandAvgHi < V_avg )									// ...and check if average is within narrow average band
//				bTooNoisy	 += 1
//				sprintf sMsg, "In  ch:%d  baseline slice %d of %d \t(Dur %6.2lf ..%6.2lfms) \tthe average %.2lf \tis out of allowed avg band %.1lf ... %.1lf ", ch, n, UFPE_kBASE_SLICES, n * DurSlice*1000,  ( n + 1 ) * DurSlice*1000,  V_avg , BandAvgLo, BandAvgHi
//				UFCom_FoAlert( sFolder, UFCom_kERR_LESS_IMPORTANT,  sMsg )
//			endif		
//			AvgValue	 = ( n * AvgValue   + V_avg   ) / ( n + 1 )		
//			sDevValue = ( n * sDevValue + V_sdev ) / ( n + 1 )		
//			// printf "\t\tEvaluateBase %3d/%3d\tDur %6.2lf ..%6.2lfms\tPts:%4d\tAvg:%4.0lf\tDev:%4.1lf\trms:%4.0lf\tmiL:%4.0lf\tmi:%4.0lf\tmxL%4.0lf\tmx:%4.0lf\tdlt:%4.0lf\t->Avg:%4.0lf \r", n, UFPE_kBASE_SLICES, n * DurSlice*1000,  ( n + 1 ) * DurSlice*1000,  V_npnts,  V_avg , V_sdev, V_rms ,V_minloc,  V_min, V_maxloc, V_max , V_max-V_min, AvgValue 
//		endfor
//		// 2005-1013 why is this executed again?
//		for ( n = 0; n < UFPE_kBASE_SLICES; n += 1 )
//			if ( V_avg  < BandAvgLo	||   BandAvgHi < V_avg )	// check if average is within narrow average band
//				bTooNoisy	 += 1
//				sprintf sMsg, "In  ch:%d  baseline slice %d of %d \t(Dur %6.2lf ..%6.2lfms) \tthe average %.2lf \tis out of allowed avg band %.1lf ... %.1lf ", ch, n, UFPE_kBASE_SLICES, n * DurSlice*1000,  ( n + 1 ) * DurSlice*1000,  V_avg , BandAvgLo, BandAvgHi
//				UFCom_FoAlert( sFolder, UFCom_kERR_LESS_IMPORTANT,  sMsg )
//			endif		
//		endfor
//	else
//		WaveStats /Q  /R=( Beg / SIFact, Ende / SIFact ) wWave		// Measure average and standard deviation of the entire base region
//		AvgValue	 = V_avg
//		sDevValue = V_sdev
//	endif
//
//	AvgValue	= UFPE_BaseOp_( sFolders, ch, rg ) != kBASE_OFF  ?  AvgValue : nan 	// Nan  will  (later) prevent that the base line is drawn
//
//
//// 2005-0813 todo clarify BAS1, BAS2 and BASE   ,   set BASE right here
//	UFPE_EvalSet( sFolders, ch, rg, UFPE_kE_BAS1, kT,	Beg )
//	UFPE_EvalSet( sFolders, ch, rg, UFPE_kE_BAS1, kY,	AvgValue )		
//	UFPE_EvalSet( sFolders, ch, rg, UFPE_kE_BAS1, kVAL,	AvgValue )
//	UFPE_EvalSet( sFolders, ch, rg, UFPE_kE_BAS2, kT,	Ende )
//	UFPE_EvalSet( sFolders, ch, rg, UFPE_kE_BAS2, kY,	AvgValue )
//	UFPE_EvalSet( sFolders, ch, rg, UFPE_kE_BAS2, kVAL,	AvgValue )
//	UFPE_EvalSet( sFolders, ch, rg, UFPE_kE_BASE, kTB,	Beg )	
//	UFPE_EvalSet( sFolders, ch, rg, UFPE_kE_BASE, kTE,	Ende )
//	UFPE_EvalSet( sFolders, ch, rg, UFPE_kE_BASE, kY,	AvgValue )	
//	UFPE_EvalSet( sFolders, ch, rg, UFPE_kE_BASE, kVAL,	AvgValue )				// Version1: the base value is the value of the trailing base segment (which is right before the peak) 
//	UFPE_EvalSet( sFolders, ch, rg, UFPE_kE_SDBASE,kY,	SDevValue )	
//	UFPE_EvalSet( sFolders, ch, rg, UFPE_kE_SDBASE,kVAL,SDevValue )	
//printf "\t\tEvaluateBase( %s\tch:%d  rg:%d  FrSwp:\t%3d\tSl:%d\tBg:\t%5.3lfs\tEn:\t%5.3lf\t\txos:\t%7g\tPts(wO):\t%7d\tBegPt:\t%7g\tdltax:\t%8.6lf\tSF:\t%7.4lf\tx:\t%8.3lf\tBsVal:\t%7g\tPts:\t%7.2lf\tAxLft:\t%7g  \r", sFolders, ch, rg, nCurSwp, UFPE_kBASE_SLICES, Beg, Ende,  UFPE_XCursrOs( sFolders,ch), numPnts(wWave), BegPt, dltax, SIFact, Beg, AvgValue, Pts, XaxisLeft
//	if ( nPrintMask &  UFPE_RP_BASEPEAK1 )
//		if ( bTooNoisy ) 
//			printf "\t\t\tEvaluateBase( ch:%2d )\tBase region evaluated  in %2d slices from \t%7.3lf\t...\t%7.3lf\t: OK \t\tBaseline value:\t%7g\t[BegPt:\t%7g\tSiFact:\t%7g\tPts:\t%7g\t[dltax:\t%8.6lf\tAxLft:\t%7g  \r", ch, UFPE_kBASE_SLICES, Beg-XaxisLeft, Ende-XaxisLeft, AvgValue, BegPt, SiFact, Pts, dltax, XaxisLeft
//		else
//			printf "\t\t\tEvaluateBase(%d)\tBase region evaluated  in %d slices from %7.3lf ..%7.3lf :\t OK \t\tBaseline value: %.1lf \r", ch, UFPE_kBASE_SLICES, Beg-XaxisLeft, Ende-XaxisLeft, AvgValue
//		endif
//	endif
//
//// 2006-0411a		
////	EvPntSetValue( sFolders, ch, rg, UFPE_kE_BASE,  BegPt, SIFact,  (Beg/2 + Ende/2) / SIFact, 	AvgValue,  Beg / SIFact,  		AvgValue,  Ende / SIFact, 		AvgValue )	// !!! OK
//	EvPntSetValue( sFolders, ch, rg, UFPE_kE_BASE, 0, 1,  		Beg/2 + Ende/2 - BegPt*SIFact , AvgValue,  Beg - BegPt*SIFact,  AvgValue,  Ende - BegPt*SIFact, AvgValue )	// !!! OK
//
//	return	AvgValue
//End

//Function   	EvaluateMultipleBases( sFolders, ch, rg, nCurSwp, BegPt, SIFact )
//	string  	sFolders
//	variable	ch, rg, nCurSwp, BegPt, SIFact
//	string	  	sChan	= StringFromList( ch, LstChan_a(), UFCom_ksSEP_TAB )	// e.g.   'Adc1'
//	variable	w, wCnt	= AcqWndCnt()
//	for ( w = 0; w < wCnt; w += 1 )
//		string  	sWNm	= WndNm( w )		
//		string 	sTNL	= TraceNameList( sWNm, ";", 1 ) 
//		sTNL	= ListMatch( sTNL, sChan + "*" )
//		variable	t, tCnt	= ItemsInList( sTNL )	
//		for ( t = 0; t < tCnt; t += 1 )
//			string  	sTrace	= StringFromList( t, sTNL )
//			wave  /Z	wOrg		= TraceNameToWaveRef( sWNm, sTrace )
//
//			if ( WaveExists( wOrg ) )
//				UFPE_EvaluateBase( sFolders, wOrg, ch, rg, nCurSwp, BegPt, SIFact ) 
//				UFPE_ComputeBasePeakDependants( sFolders, wOrg, ch, rg, nCurSwp, BegPt, SIFact ) 
//				// printf "\t\tFindAllAcqWnd( sFolders:'%s' \tch:%2d\trg:%2d ) \tw:%2d\t'%s'\tTrace:%2d/%2d\t%s\tWaveExists:%2d\tL:%.3g\tR:%.3g\tsTNL:'%s...'  \r", sFolders, ch, rg, w, sWNm, t, tCnt, UFCom_pd(sTrace,22), WaveExists( wOrg ), rLeft, rRight, sTNL[0,120 ]	
//			else
//				// printf "\t???FindAllAcqWnd( sFolders:'%s' \tch:%2d\trg:%2d ) \tw:%2d\t'%s'\tTrace:%2d/%2d\t%s\tWaveExists:%2d\tsTNL:'%s...'  \r", sFolders, ch, rg, w, sWNm, t, tCnt, UFCom_pd(sTrace,22), WaveExists( wOrg ), sTNL[0,120 ]	
//			endif
//		endfor
//	endfor
//End


//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

 Function		UFPE_EvaluatePeak( sFolders, wWave, ch, rg, nCurSwp, BegPt, SIFact ) 	
// todo : value is OK, but time of sharp peak (=PEAK2) is not determined correctly (1/4 point late)  even if side points = 0.  Better wavestats????? (needs endloc!!)
	string  	sFolders
	wave	wWave
	variable	ch, rg, nCurSwp, BegPt, SIFact

	variable	Beg		= UFPE_CursorX( sFolders, ch, rg, UFPE_kC_PHASE_PEAK, UFPE_CN_BEG ) 			// get the time range in which to evaluate the peak 
	variable	Ende		= UFPE_CursorX( sFolders, ch, rg, UFPE_kC_PHASE_PEAK, UFPE_CN_END ) 			

	variable	PreciseLoc, PreciseValue 			
	string		sMsg
	variable	nSidePts	= PeakSidePts( sFolders, ch, rg )						// additional points on each side of a peak averaged to reduce noise errors 
	variable	nPrintMask=  UFPE_PrintMask_( sFolders )
	variable	dltax		= deltax( wWave ) 								// in seconds
	variable	nBoxPts	= nSidePts * 2 + 1
	variable	nPeakDir	= UFPE_PeakDir( sFolders, ch, rg ) 						// 0 : peak is off,  1 : up ,  2 : down
	string  	sPeakDir	= UFPE_PeakDirStr_( nPeakDir )
	string		sFolder	= StringFromList( 0, sFolders, ":" )					// 'eva:xxx'  ->  'eva'
	variable	xOs		= UFPE_XCursrOs(sFolders,ch)
	variable	PeakX

	// First find the absolute extremum, then smooth 'nSidePts' around this point to refine the values by reducing noise influence . 'nSidePts' is CRITICAL !
	// Problem 1 : if  'nSidePts'  is too small  and  if  peak is symmetric and noisy	:  Error: noise peaks are returned  instead of the correct smoothed values
	// Problem 2 : if  'nSidePts'  is too large  and  if  peak is asymmetric		:  Error: averaged (=too low and shifted) peak is returned  instead of the correct one-point-peak

	string			sTmpWvNm =  "root:uf:" + sFolders + ":wPeak" + num2str( ch )	// wPeak0, wPeak1, ...-

	duplicate /O 	/R=( 	Beg / SIFact, Ende / SIFact ) wWave  $sTmpWvNm		// () in the wave units , here in seconds
	wave		wPeakCopy	= $sTmpWvNm							// here :a smoothed copy of the Peak portion of 'wWave' 

	// AppendToGraph 		/Q /C=(65000,15000, 65000) wPeakCopy	// ONLY for testing : smoothed peak is magenta  

	// the evaluation interval set by user may be too short for smoothing  or  it may lie after the sweep end (then having 0 points)
	variable	CopyPts	= numPnts( wPeakCopy ) 
	variable	CopyDur	= min ( CopyPts * dltaX * SIFact  ,  (Ende - Beg) )
	if ( CopyDur <= nBoxPts * dltaX * SIFact  )
		sprintf sMsg, "Chan:%d, region:%d, FrSw:%3d : Interval for evaluation of  peak lies outside the sweep  or  is too short (%.2lfms) . Minimum duration needed is %d * %.3lfms. ", ch, rg,  nCurSwp, CopyDur*1000, nBoxPts , dltax*1000 
		UFCom_FoAlert( sFolder, UFCom_kERR_LESS_IMPORTANT,  sMsg )
	else  
		Smooth		/B ( nBoxPts ),	 wPeakCopy	
		WaveStats	/Q			 wPeakCopy	
		//WaveStats	/Q /R=( msBeg, msEnd )  wWave
		PreciseValue	= nPeakDir == kPEAK_UP  ?  V_max 	    :  ( nPeakDir == kPEAK_DOWN  ?  V_min	:  nan )	// peakDir = 0 means Peak is off,  this will set the values to Nan...
		PreciseLoc	= nPeakDir == kPEAK_UP  ?  V_maxloc :  ( nPeakDir == kPEAK_DOWN  ?  V_minloc   :  nan )	//...which will  (later) prevent that they are drawn
// 2006-0413 refer to peak onset
//		PeakX	= PreciseLoc
		PeakX	= PreciseLoc - xOs

	endif
	 printf "\t\tEvaluatePeak( %s\tch:%d  rg:%d  FrSwp:\t%3d\t%s\tBg:\t%5.3lfs\tEn:\t%5.3lf\t\txos:\t%7g\tPts(wO):\t%7d\tBegPt:\t%7g\tdltax:\t%8.6lf\tSF:\t%7.4lf\tx:\t%8.3lf\t?>? %6.4lf and Pts:\t%7.2lf\tPeakX:%d\tCpDu:\t%7g\r",sFolders,ch,rg,nCurSwp,sPeakDir[0,2],Beg,Ende, xOs,numPnts(wWave),BegPt,dltax,SIFact,Beg,nBoxPts*dltax*SIFact,CopyPts,PeakX,CopyDur
	// Problem 1 : May erroneously find local peak when using a too large range and too few nSidePts
	// Problem 2 : May erroneously shift the correctly found global peak when peak is asymmetric and when using too many nSidePts
	//	if ( bPeakIsUp )
	//		FindPeak /Q /B=(addedPts)  	/R = ( Beg, Ende )  wWave
	//	else
	//		FindPeak /Q /B=(addedPts)  /N /R = ( Beg, Ende )  wWave
	//	endif
	//	//string	sText		= SelectString( bPeakIsUp, "Minimum", "Maximum" )	// list order is 'down;up;'
	//	string		sText		= SelectString( bPeakIsUp, "Maximum", "Minimum" )	// list order is 'up;down;;'
	//	if ( V_flag )
	//		sprintf sMsg, "%s not found . Search started at %.4lfs (increasing time) .", sText, Beg
	//		UFCom_FoAlert( sFolder, UFCom_kERR_LESS_IMPORTANT,  sMsg )
	//	else
	//		PreciseLoc	= V_peakLoc
	//		PreciseValue	= V_peakVal
	//	endif

	UFPE_EvalSet( sFolders, ch, rg, UFPE_kE_PEAK, UFPE_kT,   PeakX )						// Nan  is a legal value which will  (later) prevent...
	UFPE_EvalSet( sFolders, ch, rg, UFPE_kE_PEAK, UFPE_kY,   PreciseValue )					//...that the evaluated peak is drawn
	UFPE_EvalSet( sFolders, ch, rg, UFPE_kE_PEAK, UFPE_kVAL, PreciseValue )
// 2006-0413 refer to peak onset
	UFPE_EvalSet( sFolders, ch, rg, UFPE_kE_PEAK, UFPE_kTB, Beg - xOs )
	UFPE_EvalSet( sFolders, ch, rg, UFPE_kE_PEAK, UFPE_kTE, Ende - xOs )							// 
	if ( nPrintMask &  UFPE_RP_BASEPEAK1 )
		printf "\t\t\tEvaluatePeak( ch:%2d  rg:%2d  FrSw:%3d )\tPeak\t%s     \tRange %.4lf to %.4lfs.\tLoc:%6.2lf \tPrecVal(avg over %d pts * %.3lfms = %.3lf ms) : %6.2lf\r", ch, rg, nCurSwp, UFPE_PeakDirStr_( nPeakDir ), Beg, Ende, PeakX, nBoxPts, dltax*1000, (nBoxPts-1)*dltax*1000, PreciseValue
	endif

// 2006-0411a		OK
//	EvPntSetValue( sFolders, ch, rg, UFPE_kE_PEAK, BegPt, SIFact, 	PeakX , 				PreciseValue, 0, 0, 0, 0 ) 
// 2006-0411b   also OK   :  BegPt = 0; SIFact = 1
	EvPntSetValue( sFolders, ch, rg, UFPE_kE_PEAK, 0, 1, 			(PeakX - BegPt) * SIFact,	PreciseValue, 0, 0, 0, 0 ) 

	return	PreciseValue
End


static constant	kBASEPEAK_MAXITER = 3

Function		UFPE_ComputeBasePeakDependants( sFolders, wWave, ch, rg, nCurSwp, BegPt, SIFact ) 
	string  	sFolders
	wave	wWave
	variable	ch, rg, nCurSwp, BegPt, SIFact
	string		sMsg
	variable	BaseErr, BasePeakIterCnt = 0
	variable	Val20, Val50, Val80, 	rLoc20, rLoc50, rLoc80
	variable	BaseMode				= UFPE_BaseOp_( sFolders, ch, rg )			// only the 'Drift' mode requires the iteration loop
	variable	PeakValue			= UFPE_EvY( sFolders, ch, rg, UFPE_kE_PEAK )
	variable	BaseValue, BaseRiseY	= UFPE_EvY( sFolders, ch, rg, UFPE_kE_BASE )		// starting condition for loop
	variable	xOs				 	= UFPE_XCursrOs( sFolders, ch )
	variable	BaseRiseT			= Nan

	// Only the 'Drift' mode requires the iteration loop: Although there is only 1 (constant slope) drift base line, the intersection point (with the RT2080 line) varies slightly (towards conversion) , because the RT2080 line itself depends slightly on the base value.
	do
		BaseValue	= BaseRiseY										// starting condition for loop

		Val20	=  BaseValue * 4 / 5  +  PeakValue * 1 / 5					// Compute the real levels in the rising and falling phases of an  UP  or  DOWN  peak
		Val50	=  BaseValue * 1 / 2  +  PeakValue * 1 / 2
		Val80	=  BaseValue * 1 / 5  +  PeakValue * 4 / 5
	
		//  Evaluation to find the BaseRise start location ( smoothed rise-baseline crossing next to peak location, exists always )
		variable	rLeft		= UFPE_CursorX( sFolders, ch, rg, UFPE_kC_PHASE_PEAK, UFPE_CN_BEG )
		variable	nPeakDir	= UFPE_PeakDir( sFolders, ch, rg )
		variable	PeakTime	= UFPE_EvT( sFolders, ch, rg, UFPE_kE_PEAK ) + xOs  // + xOs :  refer to peak onset
		UFPE_EvaluateCrossing( sFolders, wWave, ch, rg, nCurSwp, BegPt, SIFact, nPeakDir, "Rise",  rLeft, PeakTime, 20, Val20, UFPE_kE_RISE20 ) 
		UFPE_EvaluateCrossing( sFolders, wWave, ch, rg, nCurSwp, BegPt, SIFact, nPeakDir, "Rise",  rLeft, PeakTime, 50, Val50, UFPE_kE_RISE50 ) 
		UFPE_EvaluateCrossing( sFolders, wWave, ch, rg, nCurSwp, BegPt, SIFact, nPeakDir, "Rise",  rLeft, PeakTime, 80, Val80, UFPE_kE_RISE80 ) 
		UFPE_EvaluateSlope(	   sFolders, wWave, ch, rg, nCurSwp, BegPt, SIFact, nPeakDir, "Rise",  rLeft, PeakTime, UFPE_kE_RISSLP ) 
		
		// Evaluation of the Peak starting point which can be the intersection of  baseline and  line going through RT20 and RT80    or    a point of fixed slope (e.g. 20 mV/ms) 
		variable	BaseBeg	= UFPE_Eval(sFolders, ch, rg, UFPE_kE_BASE, UFPE_kTB ) ,	BaseBegY	= UFPE_Eval(sFolders, ch, rg, UFPE_kE_BASE, UFPE_kYB )
		variable	BaseEnd	= UFPE_Eval(sFolders, ch, rg, UFPE_kE_BASE, UFPE_kTE ) ,	BaseEndY	= UFPE_Eval(sFolders, ch, rg, UFPE_kE_BASE, UFPE_kYE )
		variable	RiseBeg	= UFPE_EvVexists( sFolders, ch, rg, UFPE_kE_RISE20 )  ?   UFPE_EvV(sFolders, ch, rg, UFPE_kE_RISE20)  : UFPE_EvV(sFolders, ch, rg, UFPE_kE_RISE50)	// the 20% crossing may not exist BUT the 50% CROSSING IS ASSUMED TO EXIST
		variable	RiseBegY	= UFPE_EvVexists( sFolders, ch, rg, UFPE_kE_RISE20 )  ?   UFPE_EvY(sFolders, ch, rg, UFPE_kE_RISE20)  : UFPE_EvY(sFolders, ch, rg, UFPE_kE_RISE50)	// the 20% crossing may not exist BUT the 50% CROSSING IS ASSUMED TO EXIST
		variable	RiseEnd	= UFPE_EvV(sFolders, ch, rg, UFPE_kE_RISE80) ,	RiseEndY	= UFPE_EvY(sFolders, ch, rg, UFPE_kE_RISE80)

		if  ( BaseMode != kBASE_SLOPE )		// in the 'Slope' mode the Base Y and time values have already been computed. They are _NOT_ derived from the intersection with the RT2080 line.
			if ( numtype( RiseBeg ) != UFCom_kNUMTYPE_NAN  &&  numtype( RiseEnd ) != UFCom_kNUMTYPE_NAN )	//  'RiseBeg' and  'RiseEnd'  are often  Nan  (e.g. when the crossing evaluation failed because the peak direction or base line value was wrong)....
																				//...but in this case the base line value should not set to nan (=invisible)    but should rather keep its Y value.  Time of BaseRise can then obviously not be computed. 
				FourPointXYIntersection(  BaseBeg, BaseBegY, BaseEnd, BaseEndY , RiseBeg, RiseBegY, RiseEnd, RiseEndY, BaseRiseT, BaseRiseY ) 	// BaseRiseT, BaseRiseY are changed
			endif
			UFPE_EvalSet( sFolders, ch, rg, UFPE_kE_BASE, UFPE_kT, 	BaseRiseT )
			UFPE_EvalSet( sFolders, ch, rg, UFPE_kE_BASE, UFPE_kY, 	BaseRiseY )
			UFPE_EvalSet( sFolders, ch, rg, UFPE_kE_BASE, UFPE_kVAL, 	BaseRiseY )
	 		EvPntSetValue( sFolders, ch, rg, UFPE_kE_BASE, 0, 1, (BaseRiseT - BegPt) * SIFact, BaseRiseY, (BaseBeg - BegPt) * SIFact,  BaseBegY, (BaseEnd - BegPt) * SIFact, BaseEndY )
		endif

		BasePeakIterCnt 	+= 1
		BaseErr			 =  abs( ( BaseValue - BaseRiseY ) / BaseRiseY ) 
		// printf "\t\tComputeBasePeakDependants( '%s' ch:%2d  rg:%2d )  IterCnt:%2d  BaseValue:\t%7g\t->\t%7g\tError:\t%8.6lf\t  \r", sFolders, ch, rg, BasePeakIterCnt, BaseValue, BaseRiseY, BaseErr
	while ( BaseMode == kBASE_DRIFT  &&  BaseErr > 1e-4  &&  BasePeakIterCnt < kBASEPEAK_MAXITER )	// only the 'Drift' mode requires the iteration loop. Arbitrary assumption of the aborting condition
	//while ( 	 BaseErr > 1e-4  &&  BasePeakIterCnt < kBASEPEAK_MAXITER )		// works also: when not in 'Drift' mode there will automatically only 1 iteration be executed. Arbitrary assumption of the aborting condition

	if ( BasePeakIterCnt == kBASEPEAK_MAXITER)
		UFCom_InternalError( "Could not find Base/Rise intersection within " + num2str( kBASEPEAK_MAXITER ) + " iterations. " ) 
	endif	

	// From now on use the  BaseRise  Y value  as the  base value . This is a very critical value  as  the peak amplitude  and  all  Rise/Decay times are referred to this value.
	UFPE_EvalSet( sFolders, ch, rg, UFPE_kE_AMPL, UFPE_kVAL, UFPE_EvY( sFolders, ch, rg, UFPE_kE_PEAK ) - BaseRiseY )					// Compute Amplitude value 	
	// 2005-0902 Problems computing the series resistance
	// 1. Works only in VC mode when Base/Peak/Amp  are in pA.  User responsibility 
	// 2. The PeakSidePoints must be set to 0 as a very asymmetric peak is expected. Also User responsibility  .
	// 3. Due to opening channels before and during the Rseries pulse the baseline right before the pulse might be noisy or (worse) steadily rising. In this case it is important to set only a narrow baseline region right before the pulse. Also User responsibility  
	//	Perhaps an improvement would be to also analyse the negative peak and to alert the user if there are large differences.  ??? TODO
	//	TODO  incorporate units  ( = pA here in VC mode ) , and convert to MegOhms. 
	UFPE_EvalSet( sFolders, ch, rg, UFPE_kE_RSER, UFPE_kVAL, UFPE_Rser_mV( sFolders, ch, rg ) / UFPE_EvV( sFolders, ch, rg, UFPE_kE_AMPL ) * 1e6 )	// Compute the series resistance from the peak amplitude . Todo : recognise 'MOhm' and 'pA' from 'UFPE_klstEVL_UNITS' to compute 1e6
	
	// Check EVENT VALIDITY : Check if there is an event within the peak window having an amplitude larger than  'user-defined-factor  x  Base Standard deviation'
	// Refinements:	1. check that base line is not extraordinary noisy which would prevent detection of a valid peak (compare  with SDev(whole trace)  or with previous SDBase values)
	// 			2. check that the detected peak is not a noise peak (compute peak area)
	// Different approach: Compute event validity not for every peak but only for those where a latency is defined. Maybe this has advantages but it is more complex.... 
	variable	bEvValid	= abs( UFPE_EvV( sFolders, ch, rg, UFPE_kE_AMPL ) )  > SDevFactor( ch, rg )  * UFPE_EvV( sFolders, ch, rg, UFPE_kE_SDBASE )
	//printf "\t\tEvent is valid  ch:%2d  rg:%2d   %g  ? > ?  %g   [%g  x %g]   -> bEventValid:%2d	\r", ch, rg, abs( UFPE_EvV( ch, rg, UFPE_kE_AMPL ) ) ,  UFPE_EvV( ch, rg, UFPE_kE_SDBASE ) * SDevFactor( ch, rg )  ,  SDevFactor( ch, rg )  ,  UFPE_EvV( ch, rg, UFPE_kE_SDBASE ) , bEvValid	
	UFPE_EvalSet( sFolders, ch, rg, UFPE_kE_EVVALID, UFPE_kVAL, bEvValid )

	//  Risetime 20 to 80 : Get intersection of  baseline  and  line going through RT20 and RT80 
	if ( UFPE_EvVexists( sFolders, ch, rg, UFPE_kE_RISE80 )  &&   UFPE_EvVexists( sFolders, ch, rg, UFPE_kE_RISE20 )  )
		variable	Rise20T		= UFPE_EvV( sFolders, ch, rg, UFPE_kE_RISE20 ) 
		variable	Rise80T		= UFPE_EvV( sFolders, ch, rg, UFPE_kE_RISE80 ) 
		UFPE_EvaluateRiseTime2080( sFolders, ch, rg, BegPt, SIFact, "RT2080", Rise20T,  Val20,  Rise80T, Val80 ) 
	endif
	
	//  Evaluation to find the decay end location ( smoothed decay-baseline crossing next to peak location, may not exist )
	variable	locEndDecay 
	variable	level	= UFPE_EvY(sFolders, ch, rg, UFPE_kE_BASE )
	FindLevel	/Q /R=( PeakTime, Inf)  wWave, level	// try to find time when decay crosses baseline ( may not exist )
	if ( V_flag )
		sprintf sMsg, "Decay (ch:%2d, region:%2d) did not find Base Level Crossing (level:%.1lf) after the peak time %.1lfms  (smoothing till end...) ", ch, rg, level, PeakTime
		UFCom_Alert( UFCom_kERR_LESS_IMPORTANT,  sMsg )
		locEndDecay = rightX( wWave )					// inf is wrong!
	else
		locEndDecay  = V_LevelX
	endif

	UFPE_EvaluateCrossing( sFolders, wWave, ch, rg, nCurSwp, BegPt, SIFact, nPeakDir, "Decay",  PeakTime, locEndDecay, 50, Val50, UFPE_kE_DEC50 ) 
	UFPE_EvaluateSlope(     sFolders, wWave, ch, rg, nCurSwp, BegPt, SIFact, nPeakDir, "Decay",  PeakTime, locEndDecay, UFPE_kE_DECSLP ) 

	//   Half duration
	if ( UFPE_EvVexists( sFolders, ch, rg, UFPE_kE_DEC50 )  &&   UFPE_EvVexists( sFolders, ch, rg, UFPE_kE_RISE50 )  )
		variable	HalfDurBeg	= UFPE_EvV( sFolders, ch, rg, UFPE_kE_RISE50 ) 
		variable	HalfDurEnd	= UFPE_EvV( sFolders, ch, rg, UFPE_kE_DEC50 )  
		variable	HalfDurY		= UFPE_EvY( sFolders, ch, rg, UFPE_kE_DEC50 ) 			// or  UFPE_EvY( sFolders, ch, rg, UFPE_kE_RISE50 ) )
		UFPE_EvaluateHalfDuration( sFolders, ch, rg, BegPt, SIFact, "HalfDur", HalfDurY, HalfDurBeg, HalfDurEnd ) 
	endif
End


 Function		UFPE_EvaluateCrossing( sFolders, wWave, ch, rg, nCurSwp, BegPt, SIFact, nPeakDir, sPhase, Beg, Ende, Percent, Val, nResultIndex ) 
// Evaluate the rising or the decaying phase
//  Find the time when the given 'Percent' level is crossed. Up till  060219: Use the smoothed data to reduce noise influence. ( 0% is baseline, 100% is precisePeak)
// 2006-02-19 No longer any smoothing as smoothing failed VERY OFTEN when there were too few points on the rising edge.  Could ONLY be re-implemented if it is made sure that there are enough points on the rising phase.
// Todo : possibly adjust search direction  e.g. always peak down...
	string  	sFolders
	wave	wWave
	variable	ch, rg, nCurSwp, BegPt, SIFact, nPeakDir	// evaluate pos or neg peak  or  no peak at all
	string		sPhase							// 'Rise'  or 'Decay'
	variable	Beg, Ende							// search range limits
	variable	Percent, Val, nResultIndex
	string		sMsg
	variable	CrossingX
	variable	xOs		= UFPE_XCursrOs( sFolders,ch)

//	variable	dltax			= deltax( wWave )
//	variable	nBoxPts	= 7			
//	// Alternate approach: one could evaluate short intervals without smoothing............ 
//	if ( ( Ende - Beg ) <= nBoxPts * dltax )
//		sprintf sMsg, "UFPE_EvaluateCrossing( ch:%2d  rg:%2d  Pk %s\t%s )\tInterval for evaluation of crossing is too short (%.3lfs .. %.3lfs = %.3lfms). Minimum duration needed is %d * %.3lfms. ", ch, rg, UFPE_PeakDirStr( nPeakDir ) , sPhase, Beg, Ende, (Ende - Beg)*1000 , nBoxPts , dltax*1000
//		printf "Error:\t%s\r", sMsg
//		Alert( UFCom_kERR_LESS_IMPORTANT,  sMsg )
//	elseif ( Beg < leftx( wWave )   ||   Ende  < leftx( wWave )   ||  Beg > rightx( wWave )   ||   Ende > rightx( wWave ) )
//		sprintf sMsg, "UFPE_EvaluateCrossing( ch:%2d  rg:%2d  Pk %s\t%s )\tAt least one of the interval borders ( %.3lf .. %.3lfs ) lies outside the wave borders ( %.3lf .. %.3lfs ) ", ch, rg, UFPE_PeakDirStr( nPeakDir ) , sPhase, Beg, Ende, leftx( wWave ), rightx( wWave ) 
//		printf "Error:\t%s\r", sMsg
//		Alert( UFCom_kERR_LESS_IMPORTANT,  sMsg )
//	else  
//		FindLevel	/Q /B = (nBoxPts) /R=( Ende, Beg )  wWave, Val	// search backward
//		if ( V_flag )
//			sprintf sMsg, "UFPE_EvaluateCrossing( ch:%2d  rg:%2d  Pk %s\t%s )\tFindLevel did not find %.0lf%% level crossing  (%.3lf) within interval %.3lf .. %.3lfs ", ch, rg, UFPE_PeakDirStr( nPeakDir ) ,sPhase, Percent, Val, Beg, Ende
//			printf "Error:\t%s\r", sMsg
//			Alert( UFCom_kERR_LESS_IMPORTANT,  sMsg )
//		else
//			 // printf "\t\tEvaluateCrossing( ch:%d   Pk %s  %s\t)  Found %.0lf%% level crossing (%7.2lf)\tat %7.2lfms \r", ch, UFCom_pad(UFPE_PeakDirStr( nPeakDir ),5) , UFCom_pad(sPhase,6), Percent, Val, V_levelX
//		endif
//		UFPE_EvalSet( ch, rg, nResultIndex, kT, V_levelX )		// marking this entry as non-existing  by setting it to Nan if not found 
//		UFPE_EvalSet( ch, rg, nResultIndex, kY, Val )
//	endif


	if ( Beg < leftx( wWave )   ||   Ende  < leftx( wWave )   ||  Beg > rightx( wWave )   ||   Ende > rightx( wWave ) )
		sprintf sMsg, "UFPE_EvaluateCrossing( ch:%2d  rg:%2d  FrSw:%3d  Pk %s\t%s )\tAt least one of the interval borders ( %.3lf .. %.3lfs ) lies outside the wave borders ( %.3lf .. %.3lfs ) ", ch, rg, nCurSwp, UFPE_PeakDirStr_( nPeakDir ) , sPhase, Beg, Ende, leftx( wWave ), rightx( wWave ) - deltaX( wWave )
		printf "Error:\t%s\r", sMsg
		UFCom_Alert( UFCom_kERR_LESS_IMPORTANT,  sMsg )
	endif

		FindLevel	/Q 				 /R=( Ende, Beg )  wWave, Val	// search backward
		if ( V_flag )
			sprintf sMsg, "UFPE_EvaluateCrossing( ch:%2d  rg:%2d  FrSw:%3d  Pk %s\t%s )\tFindLevel did not find %.0lf%% level crossing  (%.3lf) within interval %.3lf .. %.3lfs ", ch, rg, nCurSwp, UFPE_PeakDirStr_( nPeakDir ) ,sPhase, Percent, Val, Beg, Ende
			// printf "Error:\t%s\r", sMsg
			UFCom_Alert( UFCom_kERR_LESS_IMPORTANT,  sMsg )
			CrossingX	= nan								// mark this entry as non-existing  by setting it to Nan if no crossing could be found 
		else
			// printf "\t\tEvaluateCrossing( ch:%d   Pk %s  %s\t)  Found %.0lf%% level crossing (%7.2lf)\tat %7.2lfms \r", ch, UFCom_pad(UFPE_PeakDirStr( nPeakDir ),5) , UFCom_pad(sPhase,6), Percent, Val, V_levelX
			CrossingX	= V_levelX - xOs	// - xOs : refer to peak onset
		endif
		UFPE_EvalSet( sFolders, ch, rg, nResultIndex, UFPE_kVAL, CrossingX )		// mark this entry as non-existing  by setting it to Nan if no crossing could be not found 
		UFPE_EvalSet( sFolders, ch, rg, nResultIndex, UFPE_kT,   CrossingX )		// mark this entry as non-existing  by setting it to Nan if no crossing could be not found 
		UFPE_EvalSet( sFolders, ch, rg, nResultIndex, UFPE_kY,   Val )

// 2006-0411
//	EvPntSetValue( sFolders, ch, rg, nResultIndex, BegPt, SIFact, CrossingX, Val, nan, nan, nan, nan )
	EvPntSetValue( sFolders, ch, rg, nResultIndex, 0, 1, ( CrossingX - BegPt ) * SIFact, Val, nan, nan, nan, nan )

	return	V_levelX
End


 Function		UFPE_EvaluateSlope( sFolders, wWave, ch, rg, nCurSwp, BegPt, SIFact, nPeakDir, sPhase, Beg, Ende, nResultIndex  ) 
// Evaluate the rising or the decaying phase.  Search the steepest slope
// 2006-02-19 No longer any smoothing as smoothing failed VERY OFTEN when there were too few points on the rising edge.  Could ONLY be re-implemented if it is made sure that there are enough points on the rising phase.
// 2006-02-19 *Must* use *integer* indexes for for the wave points to obtain consistent results.  'Beg'  and  'Ende'  are float and Igor interpolates wave Y values if point index is not integer. So e.g. the difference wv[123] - wv[124]  differs from  wv[123.3] - wv[124.3]  leading to inconsistent slope results !!!!
	string  	sFolders
	wave	wWave
	variable	ch, rg, nCurSwp, BegPt, SIFact, nPeakDir	// evaluate pos or neg peak  or no peak at all
	string		sPhase							// 'Rise'  or 'Decay'
	variable	Beg, Ende							// search range limits
	variable	nResultIndex 
	variable	xOs		= UFPE_XCursrOs( sFolders,ch)
	string		sMsg		= ""

	variable	bSearchPosSlope = ( nPeakDir == kPEAK_UP  &&  !cmpstr( sPhase, "Rise" ) )  ||  ( nPeakDir == kPEAK_DOWN  &&  cmpstr( sPhase, "Rise" ) )  ?  1  :  -1   

	if ( Beg < leftx( wWave )   ||   Ende  < leftx( wWave )   ||   Beg > rightx( wWave )   ||   Ende > rightx( wWave ) )
		sprintf sMsg, "UFPE_EvaluateSlope(   \t ch:%2d\trg:%2d  FrSw:%3d  Pk %s  %s\t)  At least one of the interval borders ( %.3lf .. %.3lfs ) lies outside the wave borders ( %.3lf .. %.3lfs ) ", ch, rg, nCurSwp, UFCom_pad(UFPE_PeakDirStr_( nPeakDir ),5) , UFCom_pad(sPhase,6), Beg, Ende, leftx( wWave ), rightx( wWave ) - deltaX( wWave )
		printf "Error:\t%s\r", sMsg
		UFCom_Alert( UFCom_kERR_LESS_IMPORTANT,  sMsg )
	else  
		// Search the biggest y difference between adjacent points = steepest slope
		variable	n, Slope	= 0, SteepestSlope = 0, ptSlope
		variable	nBegPt	= round( ( Beg   - leftX( wWave ) ) / deltaX( wWave ) )
		variable	nEndPt	= round( ( Ende - leftX( wWave ) ) / deltaX( wWave ) )
		for ( n = nBegPt ; n < nEndPt; n += 1 )
			Slope	= bSearchPosSlope * ( wWave[ n + 1 ] - wWave[ n ] )
			if ( Slope > SteepestSlope )
				SteepestSlope = Slope
				ptSlope	= n
				// printf "\t\t\t%s found steeper %s slope between\t%10.6lf\t[pt:%4.1lf] \tand\t%10.6lf\t[pt:%4.1lf] \t pnt2x( n:%4.1lf ):\t%9.6lfs  -> Slope:\t%6.1lf\t(%.1lf/ms)\t[nPnts:%3.1lf]\r", UFCom_pd(sPhase,6), SelectString (bSearchPosSlope==1,"neg.","pos."),  wWave[ptSlope ], ptSlope, wWave[ ptSlope + 1 ], ptSlope + 1, n, pnt2x(wWave,n), SteepestSlope, SteepestSlope/deltaX(wWave)/1000, nEndPt-nBegPt
			endif
		endfor
		variable	SlopeX	=  ( ( pnt2x( wWave, ptSlope ) + pnt2x( wWave, ptSlope+1 ) ) / 2 - xOs	// - xOs : refer to peak onset .  Todo interpolate between this and next value
		variable	SlopeY	=  ( wWave[ ptSlope ] + wWave[ ptSlope+1 ]  ) / 2				// todo interpolate between this and next value
		UFPE_EvalSet( sFolders, ch, rg, nResultIndex, UFPE_kT, SlopeX )
		UFPE_EvalSet( sFolders, ch, rg, nResultIndex, UFPE_kY, SlopeY ) 	
		variable	SlopeInMs	= SteepestSlope/deltaX(wWave)/1000  						// in Y units / milliseconds		
		UFPE_EvalSet( sFolders, ch, rg, nResultIndex, UFPE_kVAL, SlopeInMs ) 
//ltl		// printf "\t\tEvaluateSlope( %s\tch:%d  rg:%d  FrSwp:%d\t%s\t%s\tBg:\t%5.3lfs\tEn:\t%5.3lf\t\txos:\t%7g\t%7g\tWave borders ( %.6lf .. %.6lfs )\tx:\t%8.4lf\r", 
//sFolders,ch,rg,nCurSwp,UFCom_pad(UFPE_PeakDirStr( nPeakDir),3) , UFCom_pad(sPhase,3), Beg, Ende, xOs, UFPE_EvV(sFolders,0,0,UFPE_kE_BEG), leftx( wWave ), pnt2x(wWave,numpnts(wWave)-1), SlopeX// WM: more accurate than rightx(wWave)-deltaX(wWave)
	endif

// 2006-0411
//	EvPntSetValue( sFolders, ch, rg, nResultIndex, BegPt, SIFact,  SlopeX, SlopeY, nan, nan, nan, nan )
	EvPntSetValue( sFolders, ch, rg, nResultIndex, 0, 1,  (SlopeX - BegPt) * SIFact , SlopeY, nan, nan, nan, nan )

	return	SlopeInMs
End


static Function		Slope2Base( sFolders, wWave, ch, rg, nCurSwp, BegPt, SIFact, nPeakDir, Ende, TriggerSlopePositive , MeanValue, SlopeX ) 
// Evaluate the rising or the decaying phase.  Search the position where  'TriggerSlopePositive'  occurs. Start at a higher slope (appr. half peak height) and go backwards until the slope value gets lower than 'TriggerSlopePositive'
// 2006-02-19 *Must* use *integer* indexes for for the wave points to obtain consistent results.  'Beg'  and  'Ende'  are float and Igor interpolates wave Y values if point index is not integer. So e.g. the difference wv[123] - wv[124]  differs from  wv[123.3] - wv[124.3]  leading to inconsistent slope results !!!!

// 2006-0425 NOT TESTED FOR NEGATIVE PEAKS ( bDirFactor = -1 )
	string  	sFolders
	wave	wWave
	variable	ch, rg, nCurSwp, BegPt, SIFact, nPeakDir	// evaluate pos or neg peak  or no peak at all
	variable	Ende								// the time of the peak	
	variable	TriggerSlopePositive					// the absolute slope value for which the time is to be found. This value is assumed positive also for down peaks.  
	variable	MeanValue 
	variable	&SlopeX							// time of found slope is returned
	variable	xOs		= UFPE_XCursrOs( sFolders,ch)
	variable	nPeakPt	= round( ( Ende   - leftX( wWave ) ) / deltaX( wWave ) )
	variable	n, YValue, Slope = 0
	variable	bDirFactor = ( nPeakDir == kPEAK_UP )  ?  1  :  -1   
	
	// Phase 1 : Start at peak and go backwards to approximately half height
	n 			= 	nPeakPt
	MeanValue	= ( MeanValue + wWave[ n ] ) * .3	// .3 is arbitrary and sets the level a bit below the half height to compensate the fact that 'meanvalue'  has been averaged not only over the base region but also over the peak
	do
		n 		-= 1
		// printf "\t\tSlope2Base(\t  %s\tch:%d  rg:%d  FrSwp:%d\t%s\t\tPP:%4d\t\tEn:\t%5.3lf\t\txos:\t%7g\tPhase1: Level\tn:%4d\t%7g\t >\t%7g\t ->\t%.6lfs  \r", sFolders, ch, rg, nCurSwp, UFCom_pad(UFPE_PeakDirStr( nPeakDir ),3) , nPeakPt, Ende, xOs, n,  wWave[ n ], MeanValue, ( pnt2x( wWave, n ) + pnt2x( wWave, n+1 ) ) / 2 - xOs	
	while ( bDirFactor * wWave[ n ]  >  bDirFactor * MeanValue   &&  n > 0 )

	// Phase 2 : Start at approximately half height and go backwards until the actual slope falls below the desired slope the first time. Return this value.
	do
		n 		-= 1
		Slope	 =  ( wWave[ n ] - wWave[ n - 1 ] ) / deltaX(wWave) / 1000  
		// printf "\t\tSlope2Base(\t  %s\tch:%d  rg:%d  FrSwp:%d\t%s\t\tPP:%4d\t\tEn:\t%5.3lf\t\txos:\t%7g\tPhase2: Slope\tn:%4d\t%7g\t >\t%7g\t ->\t%.6lfs   \r", sFolders, ch, rg, nCurSwp, UFCom_pad(UFPE_PeakDirStr( nPeakDir ),3) , nPeakPt, Ende, xOs, n,  Slope, TriggerSlopePositive, ( pnt2x( wWave, n ) + pnt2x( wWave, n+1 ) ) / 2 - xOs	
	while ( bDirFactor * Slope  > TriggerSlopePositive   &&  n > 0 )

	if ( n == 0 )
		UFCom_Alert( UFCom_kERR_IMPORTANT,  "Slope2Base():  Desired slope could not be found. " )
		SlopeX	= nan
		YValue	= nan
	else
		SlopeX	=   ( pnt2x( wWave, n ) + pnt2x( wWave, n+1 ) ) / 2 - xOs	
		YValue	=  ( wWave[ n ] + wWave[ n - 1 ] ) / 2
	endif
	 printf "\t\tSlope2Base(\t  %s\tch:%d  rg:%d  FrSwp:%d\t%s\t\tPP:%4d\t\tEn:\t%5.3lf\t\txos:\t%7g\tPhase2: Slope\tn:%4d\t%7g\t >\t%7g\t ->\t%.6lfs -> Val:%g   \r", sFolders, ch, rg, nCurSwp, UFCom_pad(UFPE_PeakDirStr_( nPeakDir ),3) , nPeakPt, Ende, xOs, n,  Slope, TriggerSlopePositive, SlopeX, YValue
	return	( wWave[ n ] + wWave[ n - 1 ] ) / 2
End

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  LITTLE  HELPERS 

//static	 Function		SetBandY( sFolders, ch, rg, ph, Top, Bot )
//// converts and stores the given coordinates of a region in  Y 
//// UFPE_kC_PHASE_PEAK is not handled....
//	string  	sFolders
//	variable	ch, rg, ph, Top, Bot
//	wave	wBandY	= $"root:uf:" + sFolders + ":wBandY"
//	wBandY[ ch ][ rg ][ ph ][ UFPE_CN_BEG ]		= Top
//	wBandY[ ch ][ rg ][ ph ][ UFPE_CN_END ]		= Bot		// for base and peak
//End
//
//static Function		BandY( sFolders, ch, rg, ph, rT, rB )
//// return a region's Y coordinates as references
//	string  	sFolders
//	variable	ch, rg, ph, &rT, &rB
//	wave	wBandY	= $"root:uf:" + sFolders + ":wBandY"
//	rT	= wBandY[ ch ][ rg ][ ph ][ UFPE_CN_BEG ]
//// 2006-0329
//rb=0
////	rB	= wBandY[ ch ][ rg ][ ph ][ UFPE_CN_END ]
//End

//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

 Function		UFPE_SetCursorX( sFolders, ch, rg, ph, typ, value)
// set a region's  X beginning or end   referred to time 0  ( after subtracting the start time offset = WITHOUT  start time offset )
// only in  EVAL    UFPE_XCursrOs()  is added/subtracted
	string  	sFolders
	variable	ch, rg, ph, typ, value
	wave	wCursor	= $"root:uf:" + sFolders + ":wCursor"
	wCursor[ ch ][ rg ][ ph ][ typ ]		= value - UFPE_XCursrOs( sFolders, ch )
	wCursor[ ch ][ rg ][ ph ][ typ + UFPE_CN_SV ]	= value - UFPE_XCursrOs( sFolders, ch )	
	// printf "\t\t\t\tSetCursorX( \tch:%d rg:%d \t\t  ph:%d , typ:%d, value:\t%8.3lf\t  ) Value -  UFPE_CN_XCSR_OS:\t%8.3lf\t = (and set to) \t%8.3lf\t \r", ch, rg, ph, typ, value, UFPE_XCursrOs( sFolders, ch ),  wCursor[ ch ][ rg ][ ph ][ typ ] 
End

 Function		UFPE_CursorX( sFolders, ch, rg, ph, typ )
// return a region's  X beginning or end  INCLUDING  the start time offset
// only in  EVAL    UFPE_XCursrOs()  is added/subtracted
	string  	sFolders
	variable	ch, rg, ph, typ
	wave	wCursor	= $"root:uf:" + sFolders + ":wCursor"
	// if ( ch == 0  &&  rg == 0  &&  ph == 0  &&  typ == UFPE_CN_BEG )  
	// // if ( ch == 0  &&  rg == 0  && ( ph == 0  || ph == 1 )  &&  typ == UFPE_CN_BEG )  
		// printf "\t\t\t\tCursorX(\t\tch:%d rg:%d  \t\t  ph:%d , typ:%d) return\t%8.3lf\t  =\t%8.3lf\t +  \t%8.3lf\t \r", ch, rg, ph, typ, wCursor[ ch ][ rg ][ ph ][ typ ]  + UFPE_XCursrOs( sFolders, ch )	, UFPE_XCursrOs( sFolders, ch ),  wCursor[ ch ][ rg ][ ph ][ typ ] 
	// endif
	return	wCursor[ ch ][ rg ][ ph ][ typ ]  + UFPE_XCursrOs( sFolders, ch )	
End

Function		UFPE_CursorsAreSetBE( sFolders, ch, rg, ct, nc, LatCnt )
	string  	sFolders
	variable	ch, rg, ct, nc, LatCnt
	return 	( UFPE_CursorIsSet( sFolders, ch, rg, ct, nc, UFPE_CN_BEG, LatCnt )  &&  UFPE_CursorIsSet( sFolders, ch, rg, ct, nc, UFPE_CN_END, LatCnt )  )
End

 Function		UFPE_CursorIsSet( sFolders, ch, rg, ct, nc, BegEnd, LatCnt )
	string  	sFolders
	variable	ch, rg, ct, nc, BegEnd, LatCnt
	variable	ph		= UFPE_Csr2Ph( sFolders, ct, nc, LatCnt )
	return 	numType( UFPE_CursorX( sFolders, ch, rg, ph, BegEnd ) ) != UFCom_kNUMTYPE_NAN 
End



Function		UFPE_RemoveCursorsBE( sFolders, ch, rg, ct, nc, LatCnt )
// Unset/remove a  cursor by setting the region's  X beginning  or  end  to NAN because the user switched Base, peak or Fit off.
	string  	sFolders
	variable	ch, rg, ct, nc, LatCnt
	UFPE_RemoveCursor( sFolders, ch, rg, ct, nc, UFPE_CN_BEG, LatCnt )
	UFPE_RemoveCursor( sFolders, ch, rg, ct, nc, UFPE_CN_END, LatCnt )
End

Function		UFPE_RemoveCursor( sFolders, ch, rg, ct, nc, BegEnd, LatCnt )
// Unset/remove a  cursor by setting the region's  X beginning  or  end  to NAN because the user switched Base, peak or Fit off.
	string  	sFolders
	variable	ch, rg, ct, nc, BegEnd, LatCnt
	variable	ph		= UFPE_Csr2Ph( sFolders, ct, nc, LatCnt )
	wave	wCursor	= $"root:uf:" + sFolders + ":wCursor"
	wCursor[ ch ][ rg ][ ph ][ BegEnd + UFPE_CN_SV ]	= wCursor[ ch ][ rg ][ ph ][ BegEnd ]
	wCursor[ ch ][ rg ][ ph ][ BegEnd ]		= nan
//	 printf "\t\t\tUFPE_RemoveCursor( ch:%d , rg:%d , ph:%d ,value:\t%8.3lf\t  ) \r", ch, rg, ph, nan
End


//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//
//Function		UFPE_EvalColor( sFolders, ct, nc, rRed, rGreen, rBlue )
//// return 3 color values for regions when channel and region type is given
//	string  	sFolders
//	variable	ct, nc
//	variable	&rRed, &rGreen, &rBlue 
//	string  	lstColors	= UFCom_RemoveWhiteSpace( UFCom_lstCOLORS )
//	variable	nColor	= WhichListItem( UFCom_RemoveWhiteSpace( StringFromList( nc, StringFromList( ct, UFPE_kCSR_COLORS ),  "," ) ) , lstColors )
//	wave	Red 		= root:uf:acq:misc:Red, Green = root:uf:acq:misc:Green, Blue = root:uf:acq:misc:Blue
//	rRed		= Red[ nColor ]
//	rGreen	= Green[ nColor ]
//	rBlue		= Blue[ nColor ]
//End
//
// Function		UFPE_EvalColorDark( sFolders, ct, nc, rRed, rGreen, rBlue )
//// return 3 color values for regions when channel and region type is given
//	string  	sFolders
//	variable	ct, nc
//	variable	&rRed, &rGreen, &rBlue 
//	string  	lstColors	= UFCom_RemoveWhiteSpace( UFCom_lstCOLORS )
//	variable	nColor	= WhichListItem( UFCom_RemoveWhiteSpace( StringFromList( nc, StringFromList( ct, UFPE_kCSR_COLORSDARK ),  "," ) ) , lstColors )
//	wave	Red 		= root:uf:acq:misc:Red, Green = root:uf:acq:misc:Green, Blue = root:uf:acq:misc:Blue
//	rRed		= Red[ nColor ]
//	rGreen	= Green[ nColor ]
//	rBlue		= Blue[ nColor ]
//End

//=================================================================================================
//  COMPUTING  INTERSECTIONS

static Function	FourPointXYIntersection( x1a, y1a, x1b, y1b, x2a, y2a, x2b, y2b, rx, ry )
// returns intersection given by 2 lines from 4 points (each x and y )   in rx  and  ry 
// todo : error checking , division by 0
	variable	x1a, y1a, x1b, y1b			// defines 1. line
	variable	x2a, y2a, x2b, y2b			// defines 2. line
	variable	&rx, &ry					// intersection : parameters are changed
	variable	slope1	= ( y1a - y1b ) / ( x1a - x1b )
	variable	const1	= y1a - slope1 * x1a
	variable	slope2	= ( y2a - y2b ) / ( x2a - x2b )
	variable	const2	= y2a - slope2 * x2a
 	rx = ( const2 - const1 ) / ( slope1 - slope2 ) 
	ry = slope1 * rx + const1
	// printf "\t\tx1a=%g      \ty1a=%g  ,  \tx1b=%g      \ty1b=%g      \tgives line1  y = %gx + %g \r\tx2a=%g      \ty2a=%g  ,  \tx2b=%g      \ty2b=%g    \tgives line2  y = %gx + %g . Intersection at x=%g, y=%g (=%g) \r", x1a, y1a, x1b, y1b, slope1, const1, x2a, y2a, x2b, y2b, slope2, const2, rx, ry , slope2 * rx + const2
End

static Function	TwoLineIntersection( slope1, const1, slope2, const2, rx, ry )
// todo : error checking , division by 0
	variable	slope1, const1				// defines 1. line   y = slope * x + const
	variable	slope2, const2				// defines 2. line   y = slope * x + const
	variable	&rx, &ry					// intersection : parameters are changed
 	rx = ( const2 - const1 ) / ( slope1 - slope2 ) 
	ry = slope1 * rx + const1
	// printf "\t\tx line1  y = %gx + %g \r\tx2a=%g      \tline2  y = %gx + %g . Intersection at x=%g, y=%g (=%g) \r", slope1, const1, slope2, const2, rx, ry , slope2 * rx + const2
End

//=================================================================================================

 Function		UFPE_XaxisLft( sFolders, ch )
	string  	sFolders
	variable	ch
	wave	wXAxisLeft	= $"root:uf:" + sFolders + ":wXAxisLeft"
	return	wXAxisLeft[ ch ]	
End

 Function		UFPE_SetXaxisLft( sFolders, ch, XaxisLeft )
	string  	sFolders
	variable	ch, XaxisLeft
	wave	wXAxisLeft	= $"root:uf:" + sFolders + ":wXAxisLeft"
			wXAxisLeft[ ch ]	= XaxisLeft
	// printf "\t\tSetXaxisLft( ch:%2d, XaxisLeft: %g) ->  %g \r", ch, XaxisLeft, UFPE_XaxisLft( sFolders, ch )
End


 Function		UFPE_XCursrOs( sFolders, ch )
	string  	sFolders
	variable	ch
	wave	wXCsrOS		= $"root:uf:" + sFolders + ":wXCsrOS"
	return	wXCsrOS[ ch ]
End
Function		UFPE_SetXCursrOs( sFolders, ch, XcursorOs )
	string  	sFolders
	variable	ch, XcursorOs
	wave	wXCsrOS		= $"root:uf:" + sFolders + ":wXCsrOS"
			wXCsrOS[ ch ]	= XcursorOs
	// printf "\t\tSetXCursrOs(  ch:%2d, XaxisLeft: %g) ->  %g \r", ch, XcursorOs, UFPE_XCursrOs( sFolders, ch )
End





//=================================================================================================
//   INTERFACE of  EVAL
//   IMPLEMENTATION of  EVAL

 Function		UFPE_EvT( sFolders, ch, rg, pt )
	string  	sFolders
	variable	ch, rg, pt
	wave	wEval	= $"root:uf:" + sFolders + ":wEval"
	return	wEval[ ch ][ rg ][ pt ][ UFPE_kT ]
End	

 Function		UFPE_EvY( sFolders, ch, rg, pt )
	string  	sFolders
	variable	ch, rg, pt
	wave	wEval	= $"root:uf:" + sFolders + ":wEval"
	return	wEval[ ch ][ rg ][ pt ][ UFPE_kY ]
End	

 Function		UFPE_EvV( sFolders, ch, rg, pt )
	string  	sFolders
	variable	ch, rg, pt
	wave	wEval	= $"root:uf:" + sFolders + ":wEval"
	return	wEval[ ch ][ rg ][ pt ][ UFPE_kVAL ]
End	

 Function		UFPE_Eval( sFolders, ch, rg, pt, nType )
	string  	sFolders
	variable	ch, rg, pt, nType
	wave	wEval	= $"root:uf:" + sFolders + ":wEval"
	// printf "\t\tEval( \t\tch:%d  rg:%d  pt:%d  nType:%d )  \tretrieves\t%g   \r", ch, rg, pt, nType, wEval[ ch ][ rg ][ pt ][ nType ]
	return	wEval[ ch ][ rg ][ pt ][ nType ]
End	

 Function		UFPE_EvalSet( sFolders, ch, rg, pt, nType, Value ) 
	string  	sFolders
	variable	ch, rg, pt,  nType, Value
	wave	wEval	= $"root:uf:" + sFolders + ":wEval"
	wEval[ ch ][ rg ][ pt ][ nType ] = Value
	// printf "\t\tUFPE_EvalSet( \tch:%d  rg:%d  pt:%d  nType:%d )  \tstores \t%g    =?= %g  =?= %g \r", ch, rg, pt, nType, value, UFPE_Eval( ch, rg, pt, nType ), wEval[ ch ][ rg ][ pt ][ nType ]
End	

 Function		UFPE_EvTexists( sFolders, ch, rg, pt )
	string  	sFolders
	variable	ch, rg, pt
	wave	wEval	= $"root:uf:" + sFolders + ":wEval"
	return	numtype( wEval[ ch ][ rg ][ pt ][ UFPE_kT ] ) != UFCom_kNUMTYPE_NAN
End	
Function		UFPE_EvYexists( sFolders, ch, rg, pt )
	string  	sFolders
	variable	ch, rg, pt
	wave	wEval	= $"root:uf:" + sFolders + ":wEval"
	return	numtype( wEval[ ch ][ rg ][ pt ][ UFPE_kY ] ) != UFCom_kNUMTYPE_NAN
End	
 Function		UFPE_EvVexists( sFolders, ch, rg, pt )
	string  	sFolders
	variable	ch, rg, pt
	wave	wEval	= $"root:uf:" + sFolders + ":wEval"
	return	numtype( wEval[ ch ][ rg ][ pt ][ UFPE_kVAL ] ) != UFCom_kNUMTYPE_NAN
End	



Function	/S	UFPE_EvalNm( pt )
	variable	pt
	return	UFCom_RemoveLeadingWhiteSpace( StringFromList( pt, UFPE_klstEVL_RESULTS ) )	// remove tabs which are there only for better readability during programming
End	


//-----------------------------------------------------------------------------------------------------------------------------

// 2005-12-19b
//Function		fPrintReslts( s )
//// History printing  needs an explicit action procedure to convert the index of the listbox entry (=pmPrRes0000)  into the print mask 'gPrintMask'
//	struct	WMPopupAction	&s
//	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
//	string  	sFo	 	= GetUserData( 	s.win,  s.ctrlName,  "sFo" )		// e.g.  'root:uf:eva:' 
//	string  	sSubDir	= ReplaceString( "root:uf:", sFo, "" )		  	// e.g.  'root:uf:eva:' -> 'eva:'
//	string  	sFolders	= sSubDir + s.win
////variable /G		$"root:uf:" + sFolders + ":gPrintMask"
//	nvar		gPrintMask	= $"root:uf:" + sFolders + ":gPrintMask"
//	gPrintMask			= str2num( StringFromList( s.popNum - 1, ksPRINTMASKS ) )	// Convert changed popup index into PrintMask bit field
//	// printf "\t%s\t%s\tpopnum%2d\t%s\tgPrintMask:%4d\t%s  \r",  UFCom_pd(sProcNm,15), UFCom_pd(s.ctrlName,23), s.popNum, UFCom_pd(s.popStr,11), gPrintMask, sFolders
//End

//Function		UFPE_fPrintResltsPops( sControlNm, sFo, sWin )
//	string		sControlNm, sFo, sWin
//	PopupMenu	$sControlNm, win = $sWin,	 value = UFPE_ksPRINTRESULTS
//End
//
//Function		 UFPE_PrintMask( sFolders )
//	string  	sFolders
//// 2005-12-19b
////	nvar		nPrintMask	= $"root:uf:" + sFolders + ":gPrintMask"
//	nvar		pmPrintResIdx	= $"root:uf:" + sFolders + ":pmPrRes0000" 					 // 1-based index of the popupmenu is extracted ....
//	variable	newPrintMask	=  str2num( StringFromList( pmPrintResIdx - 1, UFPE_ksPRINTMASKS ) )	// ...to avoid the use of the global  'gPrintMask'	
////	 printf "\t\t\t UFPE_PrintMask( '%s' ) returns: %d (=old)   new:%d \t \r", sFolders, nPrintMask, NewPrintMask
//	return	newPrintMask
//End

//-----------------------------------------------------------------------------------------------------------------------------


Function		UFPE_EvaluateHalfDuration( sFolders, ch, rg, BegPt, SIFact, sTxt, HalfDurY, HalfDurBeg, HalfDurEnd ) 
	string  	sFolders, sTxt
	variable	ch, rg, BegPt, SIFact, HalfDurY, HalfDurBeg, HalfDurEnd 
	variable	HalfDurMid	= ( HalfDurBeg + HalfDurEnd ) / 2 
	UFPE_EvalSet( sFolders, ch, rg, UFPE_kE_HALDU, UFPE_kVAL, HalfDurEnd - HalfDurEnd )
// 2006-0411
// 	EvPntSetValue( sFolders, ch, rg, UFPE_kE_HALDU, BegPt, SIFact,  HalfDurMid, HalfDurY, HalfDurBeg,  HalfDurY, HalfDurEnd, HalfDurY )
	EvPntSetValue( sFolders, ch, rg, UFPE_kE_HALDU, 0, 1,  (HalfDurMid - BegPt) * SIFact, HalfDurY, (HalfDurBeg- BegPt) * SIFact,  HalfDurY, (HalfDurEnd- BegPt) * SIFact, HalfDurY )
	return	HalfDurEnd - HalfDurEnd 
End 



Function		UFPE_EvaluateRiseTime2080( sFolders, ch, rg, BegPt, SIFact, sTxt,  Rise20T,  Val20,  Rise80T, Val80 ) 
	string  	sFolders, sTxt
	variable	ch, rg, BegPt, SIFact, Rise20T,  Val20,  Rise80T, Val80 
	variable	RiseTime	=   Rise80T -  Rise20T  
	variable	TimeMid	= ( Rise20T + Rise80T ) / 2 
	variable	ValMid	= (   Val20 	  +  Val80	  ) / 2 
	UFPE_EvalSet( sFolders, ch, rg, UFPE_kE_RT2080, UFPE_kVAL,  RiseTime )
	UFPE_EvalSet( sFolders, ch, rg, UFPE_kE_RT2080,  UFPE_kT,     TimeMid )
// 2006-0411
//	EvPntSetValue( sFolders, ch, rg, UFPE_kE_RT2080, BegPt, SIFact, TimeMid, ValMid,  Rise20T,   Val20,   Rise80T,  Val80 )
	EvPntSetValue( sFolders, ch, rg, UFPE_kE_RT2080, 0, 1, (TimeMid - BegPt) * SIFact, ValMid,  (Rise20T - BegPt) * SIFact,   Val20,   (Rise80T - BegPt) * SIFact,  Val80 )
	return	RiseTime
End 

//----------------------------------------------------------------------------------
// nach Panel???
//Function		UFPE_TurnDependingControlOnOff( sFolders, sCtrlName, sDependingBaseNm, bOnOff )
//// Depending on the state of the  'Fit'  checkbox, enable or disable the depending control  'FitFnc'  (which is in the same line)
//	string  	sFolders, sCtrlName, sDependingBaseNm
//	variable	bOnOff
//	string  	sWin			  = StringFromList( 1, sFolders, ":" )						//  e.g.  'eva:de'  ->  'de'
//	string  	sThisControl	  = UFCom_StripFoldersAnd4Indices( sCtrlName )					// remove all folders and the 4 trailing numbers e.g. 'root_uf_eva_de_buFitBCsr1000'  -> 'buFitBCsr' 
//	string  	sControlledCoNm = ReplaceString( sThisControl, sCtrlName, sDependingBaseNm )	// for this to work both the controlling control and the controlled (=enabled/disabled) control must reside in the same folder
//	 printf "\t\t\t\t\t\t%s\tb:%2d  =\t%d : from control \tUpdating:%s\t \r",  UFCom_pd(sCtrlName,26), bOnOff, UFCom_PnValC( sCtrlName ), sControlledCoNm 
//	// Display or hide the dependent control  'FitFnc' 
//	PopupMenu $sControlledCoNm, win = $sWin,  userdata( bVisib )	= num2str( bOnOff  )		// store the visibility state (depending here only on cbFit, not on the tab!) so that it can be retrieved in the tabcontrol action proc (~ShowHideTabControl3() )
//	PopupMenu $sControlledCoNm, win = $sWin,  disable	=  bOnOff  ?  0 :   UFCom_kCo_HIDE  			// : UFCom_kCo_DISABLE
//	// Bad:
//	ControlUpdate  /W = $sWin $sControlledCoNm	// BAD: should not be needed  but without this line  SOME!  popupmenu controls are not displayed/hidden when they should (when the Checkbox Fit is changed)
//End


//--------------------------------------------------------------

