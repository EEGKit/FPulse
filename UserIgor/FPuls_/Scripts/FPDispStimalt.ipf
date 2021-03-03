//
// FPDISPSTIM.IPF  :	STIMULUS  DISPLAY  FUNCTIONS
//

#pragma rtGlobals=1						// Use modern global access method.

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	DIALOG: DISPLAY OPTIONS  FOR STIMULUS

strconstant		cSTIMWNDNAME	= "Stimulus"
static  strconstant	sSTIMDAC_BASE	= "gbStim"
static constant		cAXISMARGIN		= .15			// space at the right plot area border for second, third...  Dac stimulus axis all of which can have different scales
static constant		cDGOWIDTH		= .04			// width of 1 Digout trace refered to whole window height
static constant		cDECIMATIONLIMIT = 20000		// 10000 to 50000 works well for IVK: 525000pts (135000 without blank), 15 frames, 5 sweeps
static constant		cMINIMUMSTEP	= 6			// as decimation has a considerable overhead  smaller steps make no sense

constant			cLINES = 0, cLINESandMARKERS = 4, cCITYSCAPE	= 6

// Reactivate the following 2 lines  if you want the display mode 'One frame, first sweep'
//static constant      	cAllFAllS = 0, cAllFOneS = 1,  cOneFAllS = 2, cOneFOneS = 3
//static strconstant	sDISPSTIM_Title 	= " all frames, all sweeps; all frames, first sweep; one frame, all sweeps; one frame, first sweep "
static constant      	cAllFAllS = 0, cAllFOneS = 1,  cOneFAllS = 2, cOneFOneS = -1	//  -1 deactivates cOneFOneS right here so that there is no further change necessary in the code 
static strconstant	sDISPSTIM_Title 	= " all frames, all sweeps; all frames, first sweep; one frame, all sweeps"

// Reactivate the following 2 lines  if you want the display mode 'Stack frames and sweeps'
// static constant      	cCATFR_CATSW = 0, cSTACKFR_CATSW = 1 ,  cSTACKFR_STACKSW = 2
//static strconstant	sCAT_STACK_Title 	= " catenate frames + swps; stack frames, cat swps; stack frames + sweeps"
static constant      	cCATFR_CATSW = 0, cSTACKFR_CATSW = 1 
static strconstant	sCAT_STACK_Title 	= " catenate frames; stack frames"


Function		CreateGlobalsInFolder_DispStim()
// creates all folder-specific variables. To be used once from CreateGlobals() as the current data folder is changed and not restored

// 040902
//	NewDataFolder  /O  /S root:uf:dspStimmmmmmmmmm			// for display stimulus : 	make a new data folder and use as CDF,  clear everything

	variable	/G	gbSameYAx	= 0
	variable	/G	gnDspBlock		= 0 		// the block/protocol to be displayed in DisplayStimulus( )
	variable	/G	gbShowBlank	= 1
	variable	/G	gbAllBlocks		= 0	
	variable	/G	gbDisplay		= 1		// stimulus display can be turned off to save script loading time and screen space
	variable	/G	raRangeFS		= 0		// Radio button startup value: 0 is all frames, all sweeps
	variable	/G	raCatStck		= 1		// Radio button startup value: 1 is stack frames and catenate sweeps

	if ( ! cIS_RELEASE_VERSION )
		gbDisplay		= 0				// 031113 normal setting 1, but 0 saves time when during testing the same script is loaded over and over
	endif

End


Function		DisplayOptionsStimulus()
	ConstructOrDisplayPanel(  "PnDispStim" )
End

Window		PnDispStim()
	PauseUpdate; Silent 1						// building window...
	string  	sPanelWvNm = "root:dlg:tPnDispStim"
	InitDisplayStimulusOpt(  sPanelWvNm )			// constructs the text wave  'tDispOptST'  defining the panel controls
	variable	XSize = PnXsize( $sPanelWvNm ) 
	variable	XLoc = GetIgorAppPixelX() -  Xsize - 140 - 8	// put this panel on the right side just above the status bar
	variable 	YLoc	= 180						// Panel location in pixel from upper side
	DrawPanel( $sPanelWvNm, XSize, XLoc, YLoc, "Disp Stimulus" )
EndMacro

Function		InitDisplayStimulusOpt( sPanelWvNm )
// here are the samples united for all radio button  and  checkbox  varieties.....
	string  	sPanelWvNm
	variable	n = -1, nItems = 35
	make /O /T /N=(nItems) $sPanelWvNm
	wave  /T	tPn		= 	$sPanelWvNm
	//				TYPE	;FLEN;FORM;  LIM;	PRC;  	NAM							; TXT					
	n += 1;		tPn[ n ]	= 	"PN_CHKBOX;	root:stim:gbDisplay		;Display stimulus"
	n += 1;		tPn[ n ] 	= 	"PN_CHKBOX;	root:stim:gbAllBlocks		;All blocks;		| PN_SETVAR;	root:stim:gnDspBlock		;Block  ;   	40 ; %2d ;0,99,1  	;	"	//? max =99 is arbitrary	
	
	// Sample 1 PN_RADIO buttons : checkbox title text comes from list, checkbox variables are automatically indexed, only one helptopic for all 
	n = PnControl(	tPn, n, 1, ON, 	"PN_RADIO", cVERT, "Range", 			 "root:stim:raRangeFS",  	sDISPSTIM_Title,   	"",  		"" , kWIDTH_NORMAL )	// sample
	n = PnControl(	tPn, n, 1, ON, 	"PN_RADIO", cVERT, "Mode", 				 "root:stim:raCatStck", 	sCAT_STACK_Title,	"",  		"" , kWIDTH_NORMAL )	// sample

	// Sample 2 PN_RADIO buttons : checkbox title text is right here, checkbox variables are indexed by hand, unique helptopic for each checkbox possible 
	// n += 1;		tPn[ n ] 	= 	"PN_SEPAR;							;Range"					
	// n += 1;		tPn[ n ] 	= 	"PN_RADIO;	root:stim:raRangeFS_0_4	;all frames,  all sweeps;   ;  ;  ;  ;Range1"   
	// n += 1;		tPn[ n ]	= 	"PN_RADIO;	root:stim:raRangeFS_1_4	;all frames,  first sweep;   ;  ;  ;  ;all frames,  first sweep"
	// n += 1;		tPn[ n ] 	= 	"PN_RADIO;	root:stim:raRangeFS_2_4	;one frame,  all sweeps;   ;  ;  ;SampleSpecialNameProc;one frame,  all sweeps"
	// n += 1;		tPn[ n ] 	= 	"PN_RADIO;	root:stim:raRangeFS_3_4	;one frame,  first sweep;   ;  ;  ;SampleSpecialNameProc;Range1"

	n += 1;		tPn[ n ] 	= 	"PN_SEPAR;							;"
	n += 1;		tPn[ n ] 	= 	"PN_CHKBOX;	root:stim:gbShowBlank ;include blank periods;  ;  ;  ;StimShowBlanksProc"	// sample: procedure with special name
	n += 1;		tPn[ n ]	= 	"PN_CHKBOX;	root:stim:gbSameYAx ;use same Y-axis for Dacs"   
	redimension   /N=(n+1)	tPn
End


Function		gnDspBlock( ctrlName, varNum, varStr, varName ) : SetVariableControl
	string		ctrlName, varStr, varName
	variable	varNum
	nvar		gnDspBlock = root:stim:gnDspBlock
	gnDspBlock		 = min( gnDspBlock, eBlocks() - 1 )	// if the user attempted too high a value, correct the value shown in the dialog box 
	DisplayStimulus( 0 )
End

Function		root_stim_raRangeFS( sControlNm, nValue )
// Sample: if the proc field in a radio button in tPanel is empty then a proc with an auto-built name like this is called ( folder, underscore, variable base name)
// Advantage: Empty proc field in radio button in tPanel.  No explicit call to  'fRadio( sControlNm, bValue )'  is necessary. 
// Disadvantage: long function name containing folder is necessary
	string		sControlNm
	variable	nValue
	nvar  raRangeFS = root:stim:raRangeFS; printf "\tProc (RADIO)\tauto-built name \troot_stim_raRangeFS()    button is '%s'    nValue:%d  -> %d\r", sControlNm, nValue, raRangeFS
	DisplayStimulus( 0 )
End

Function		root_stim_raCatStck( sControlNm, nValue )
	string		sControlNm
	variable	nValue
	nvar  raCatStck = root:stim:raCatStck; printf "\tProc (RADIO)\tauto-built name \troot_stim_raCatStck()    button is '%s'    nValue:%d  -> %d\r", sControlNm, nValue, raCatStck
	DisplayStimulus( 0 )
End

//Function		SampleSpecialNameProc( sControlNm, bValue )
//// Sample: if the proc field in a radio button in tPanel contains this function name this proc is called when a radio button is pressed
//// Advantage: Any procedure name is possible (multiple controls may share the same procedure!)
//// Disadvantage: proc field in radio button in tPanel must be filled.  An explicit call to  'fRadio( sControlNm, bValue )'  is necessary to check/uncheck the buttons.
//	string  	sControlNm
//	variable	bValue
//	// printf "\tProc (RADIO)\tspecial name \tSampleSpecialNameProc()    control is '%s'    bValue:%d \r", sControlNm, bValue
//	fRadio( sControlNm, bValue )	// sets Help and checks/unchecks radio,buttons: needed here as this action proc name is NOT derived from the control name
//	DisplayStimulus( 0 )
//End


Function		root_stim_gbAllBlocks( sControlNm, bValue )
// Store and retrieve special checkbox and radio button settings if and while the user temporarily changes a general setting, here the number of blocks to be displayed
// ( There is at the moment no checkbox to be handled in this panel, how it is done is shown in the commented lines...) 
	string		sControlNm
	variable	bValue
	//printf "\r\tProc (BOOLE)\tauto-built name \troot_stim_gbAllBlocks()    control is '%s'    bValue:%d \r", sControlNm, bValue
	nvar		raRangeFS	= root:stim:raRangeFS				// The 'Range' setting  'All frames, all sweeps'  makes sense if the user wants to see all blocks so we automatically set it (although this is not required by the program)
	nvar		raCatStck		= root:stim:raCatStck				// The 'Mode'   setting  'Cat frames + sweeps'  makes sense if the user wants to see all blocks so we automatically set it (although this is not required by the program)
	// nvar  	gbCaten	= root:stim:gbCaten						// 'Catenation' must be on if the user wants to see all blocks (this makes sense and also the program requires it)... 
	// nvar	/Z 	 gStaticPrevCatenationStatus					// ..so we automatically turn it on  but  we will restore the previous state if the user wants to see single blocks again
	nvar		/Z 	 gStaticPrevRangeFrSwStatus					//  We also automatically set the 'Range' setting to 'All frames, all sweeps'  but we will restore the setting to the previous state if the user wants to see single blocks again
	nvar		/Z 	 gStaticPrevCatStackStatus					//  We also automatically set the 'Mode'  setting to 'catenate frames + sweeps'  but we will restore the setting to the previous state if the user wants to see single blocks again
	if ( ! nvar_Exists( gStaticPrevRangeFrSwStatus ) )			
		variable /G gStaticPrevRangeFrSwStatus	= raRangeFS		// Used like static, should be hidden within this function but must keep it's value between calls
		variable /G gStaticPrevCatStackStatus	= raCatStck		// Used like static, ...
		// variable /G gStaticPrevCatenationStatus	= gbCaten			// Used like static
	endif
	if ( bValue )											// The user wants to see all blocks which requires catenation to be automatically turned on...
		gStaticPrevRangeFrSwStatus	= raRangeFS				// ...and we we store the current 'Range' setting and then turn the 'Range' setting  'All frames, all sweeps'  temporarily on as this setting makes sense...
		raRangeFS				= cAllFAllS					// ...but we do NOT prevent the user from changing this setting so we do NOT disable it
		gStaticPrevCatStackStatus		= raCatStck				// ...and we we store the current 'Mode' setting and then turn the 'Mode' setting  'catenate frames + sweeps'  temporarily on as this setting makes sense...
		raCatStck					= cCATFR_CATSW			// ...but we do NOT prevent the user from changing this setting so we do NOT disable it
		// gStaticPrevCatenationStatus	= gbCaten					// ...so we store the current catenation setting..
		// gbCaten			= TRUE						// ...we turn catenation (temporarily!) on...
		// EnableCheckbox( "MyPanel", "root_stim_gbCaten", DISABLE)	// ...and we grey the checkbox so that the user cannot turn it off
	else													// The user wants to see single blocks  again...
		raRangeFS				= gStaticPrevRangeFrSwStatus	// ...so we restore the 'Range' setting to its previous state
		raCatStck					= gStaticPrevCatStackStatus	// ...so we restore the 'Mode' setting to its previous state
		// gbCaten				= gStaticPrevCatenationStatus	// ...so we restore the 'Catenation' setting to its previous state
		// EnableCheckbox( "MyPanel", "root_stim_gbCaten" , bValue )	// ...and we make the checkbox work again
	endif
	EnableSetVariable( "PnDispStim" , "gnDspBlock" , ! bValue )			// Either display a working control or hide it completely. We cannot use the NOEDIT mode as this only disables up/down but still allows an entry in the input field.

	// Update the radio buttons ( this is unfortunately NOT done automatically )
	string		sRadButFullNameDispStim	= RadioButtonFullName( "root_stim_raRangeFS", raRangeFS, ItemsInList( sDISPSTIM_Title ) )
	RadioCheckUncheck( sRadButFullNameDispStim, 1) 
	string		sRadButFullNameCatStack	= RadioButtonFullName( "root_stim_raCatStck", raCatStck, ItemsInList( sCAT_STACK_Title ) )
	RadioCheckUncheck( sRadButFullNameCatStack, 1) 

	DisplayStimulus( 0 )
End

Function		StimShowBlanksProc( sControlNm, bValue )
// Sample: if the proc field in a checkbox in tPanel contains this function name this proc is called when the checkbox is changed
// Advantage: Any procedure name is possible (multiple controls may share the same procedure!)
// Disadvantage: proc field in radio button in tPanel must be filled.  An explicit call to  'fChkbox( sControlNm, bValue )'  is necessary to check/uncheck the buttons.
	string		sControlNm
	variable	bValue
	fChkbox( sControlNm, bValue )	// sets Help : needed here as this action proc name is NOT auto-derived from the control name
	printf "\tProc (BOOLE)\tspecial name  \tStimShowBlanksProc()    control is '%s'    bValue:%d \r", sControlNm, bValue
	DisplayStimulus( 0 )
End

Function		root_stim_gbSameYAx( ctrlName, bValue )
	string		ctrlName
	variable	bValue
	DisplayStimulus( 0 )
End

Function		root_stim_gbDisplay( sControlNm, bValue )
	string		sControlNm
	variable	bValue
	//printf "\tProc (BOOLE)\tauto-built name \troot_stim_gbDisplay()    control is '%s'    bValue:%d \r", sControlNm, bValue
	if ( bValue )
		DisplayStimulus( 0 )
	else
		DoWindow /K	$cSTIMWNDNAME 		// kill the stimulus window
	endif
End

Static Function	/S	lstTitleDacs() 
	string		sDac
	string		sList= ""
	variable	ioch

	wave	wUsed	= root:cont:wUsed
	variable	nCntDA	= ioUse( ioT( "Dac" ) ) 	
	for ( ioch = 0; ioch < nCntDA; ioch += 1 )						// Assumption: Order is Dac,Adc, PoNComp . All Dac channels from script
		sDac	= ios( ioch, cIONM ) 		
		sList = AddListItem( sDac , sList, ";", Inf )
	endfor				
	printf "\tlstTitleDacs()  items:%d    \tsTitleList='%s' \r", ItemsInList( sList ), sList
	return	sList
End

Static Function  /S	DacVarNm( sDac )
	string 	sDac
	return	sSTIMDAC_BASE + "_" + sDac				//   e.g.  Dac1 -> gbStim_Dac1
End

Static Function  /S	DacFromVarNm( sDacVarName )
	string 	sDacVarName
	return	sDacVarName[ strlen( sSTIMDAC_BASE ) + 1, Inf ]	//   remove the 'gbStim' and the  '_'  added above  e.g.  gbStim_Dac1 -> Dac1
End



Function		DisplayStimulus( bDoInit )
	variable	bDoInit
// Execute "SetIgorOption DebugTimer,Start=100000"	// the default size of 10000 is not enough to measure all nested loops
//	ResetStartTimer( "DispStim" )	
	DisplayStimulus1( bDoInit )
//	StopTimer( "DispStim" )	
// Execute "SetIgorOption DebugTimer,Stop"	// to see the results call from the command line  ' ProcessTest("test1...","Notebook1...") '
//	PrintSelectedTimers( "DispStim" )		
End

Function		DisplayStimulus1( bDoInit )
// Step 10:  break  the complete  wStimulus (and Digout) wave  into  its sweeps and frames and display all of them in one graph
// sweeps can have different lengths, for that it  NEEDS  swpSetTime/swpGetTime

// Flaws and problems:
// 1. Letting IGOR draw ALL points (without any decimation) can be very slow:  appr. 5s / 10MPts   x   number of dacs, digout, Save/NoSave  can amount to 1 minute.
// 2. Decimation can improve this but must be used with care: Short spikes are prolonged on screen, considerable computing overhead, complicated code...
// 3. Drawing decimated traces in Cityscape mode is appropriate for Digout, but for Dac stimulus  only for segments, NOT for ramps, stimwave, expo where  'lines' mode would be better.
// 4. Drawing in Cityscape mode slows drawing down by a factor of 3. This is not so important when decimation is used but very annoying without (when drawing many points)  

// 9.	First DISPLAYED dac wave (even if it is the 2. in script because 1. is turned off) is always colored magenta (=default Dac color) to make time course of frames visible...(maybe annoying to user...)

// Todo: checbox to allow the user to alternatively select a 'true-but-slow' drawing mode: no decimation = step is always 1 = pulses/spikes have and keep their correct duration even when zooming 
	variable	bDoInit
	wave	wUsed			= root:cont:wUsed
	variable	nCntDA			= ioUse( ioT( "Dac" ) ) 	
	svar		gsDigOutChans		= root:stim:gsDigOutChans
	nvar		nSmpInt			= root:stim:gnSmpInt
	nvar		raRangeFS		= root:stim:raRangeFS
	nvar		raCatStck			= root:stim:raCatStck
	nvar		gbAllBlocks		= root:stim:gbAllBlocks
	nvar		gbShowBlank		= root:stim:gbShowBlank
	nvar		gbDisplay			= root:stim:gbDisplay	
	nvar		gbSameYAx		= root:stim:gbSameYAx
	nvar		gnDspBlock		= root:stim:gnDspBlock				// the block which is to be displayed

	//printf "\tDisplayStimulus1()\r"

	if ( bDoInit )											// a new script has just been read so we must adjust the number of the displayed blocks to the number of available blocks
		gnDspBlock	= min( gnDspBlock, eBlocks() - 1 )				//  or = 0 
	endif

	if ( gbDisplay )

		variable	nIO			= ioT( "Dac" )
		variable	nRightAxisCnt, RightAxisPos, LastDataPos, ThisAxisPos, LowestTickToPlot
	
		variable	pr, c, b, f, s,  nFrm, nSwp,  pt
		variable	nSwpPts = 0, nStartPos = 0
		variable	nBlkBeg, nBlkEnd			
		variable	nStoreStart, nStoreEnd
		nvar		nSmpInt		= root:stim:gnSmpInt
		string		sDgoChans	= gsDigOutChans
		variable	nDgoChs		= ItemsInList( sDgoChans )
		variable	cd, nDgoCh, nHighestDgoCh = 0
		string		bf
		string		sWNm		= cSTIMWNDNAME
		string		sDONm
	
		// Check that at least 1 Dac channel is turned on (else AppendToGraph below will fail)
		if ( nCntDA == 0 )
			return	cERROR								// avoid failing of  AppendToGraph when all channels are off
		endif
		string		sDacNm	= iov2( nIO, 0, cIONM ) 				// determine stimulus point number from 1. Dac (all Dacs have same number of points)	
		variable	nDacPts	= numpnts( $sDacNm )
	
		if ( gbAllBlocks )
			nBlkBeg	= 0
			nBlkEnd	= eBlocks() 
		else
			nBlkBeg	= gnDspBlock							// use the block  set in the dialog box
			nBlkEnd	= gnDspBlock + 1 
		endif
	 	pr			= 0									// NOT  REALLY  PROTOCOL  AWARE
	
		// Possibly construct the stimulus window
		if ( ! WinType( sWNm ) ) 											// If there is no previous instance of this window...
			// Construct stimulus window and position it neatly between menu line and scripttext (if script is open for editing)	
			variable	UsableYPoints, rxMinPoints, rxMaxPoints, ryMinPoints, ryMaxPoints 
			GetIgorAppPoints( rxMinPoints, rxMaxPoints, ryMinPoints, ryMaxPoints )		// parameters are changed by function
		 	UsableYPoints = ryMaxPoints - ryMinPoints - YFREELO_FOR_SB_AND_CMDWND
			display /K=1 /W=( 2, IGOR_YMIN_WNDLOC, rxMaxPoints / 2,  IGOR_YMIN_WNDLOC+ UsableYPoints  / 2 )
			DoWindow  /C $sWNm 										// ...build an empty window and give it a meaningful name 
		else
			DoWindow  /F $sWNm										// If the window exists already bring the window to the front..
			RemoveAllTextBoxes( sWNm )
			EraseTracesInGraph( sWNm )									// ..and clear the contents
		endif

		MarkPerfTestTime 800	// InterpretScript: DisplayStimulus Step2 start


		// Step 1a: Compute nSumDrawPts : the total  number of displayed data points  and the  step   ignoring blank periods if the display of blanks is turned off.
		variable	nSumDrawPts	= 0
		for ( b = nBlkBeg; b < nBlkEnd; b += 1 )
			nFrm			= ( raRangeFS == cOneFAllS  ||  raRangeFS == cOneFOneS ) ?  1 :  eFrames( b )
			nSwp		= ( raRangeFS == cAllFOneS  ||  raRangeFS == cOneFOneS ) ?  1 : eSweeps( b )
			for ( f = 0; f < nFrm; f += 1 )									// loop through all frames  
				for ( s = 0; s < nSwp; s += 1)							// loop through all sweeps 
					nSwpPts	= gbShowBlank ?  SweepLenAll( pr, b, f, s ) : SweepLenSave( pr, b, f, s )	// NOT  REALLY  PROTOCOL  AWARE
					nSumDrawPts	+= nSwpPts
				endfor
			endfor
		endfor
		variable	step 		= round( max( 1,  nSumDrawPts	/ cDECIMATIONLIMIT ) )		// decimation begins when wave points exceed this limit

		// Step 1b: Compute nSumSwpPts1 : the number of displayed data points  in 1 trace     ignoring blank periods if the display of blanks is turned off.
		variable	nSumSwpPts1	= 0
		for ( b = nBlkBeg; b < nBlkEnd; b += 1 )
			nFrm			= ( raRangeFS == cOneFAllS  ||  raRangeFS == cOneFOneS ) ?  1 :  eFrames( b )
			nSwp		= ( raRangeFS == cAllFOneS  ||  raRangeFS == cOneFOneS ) ?  1 : eSweeps( b )
			if ( raCatStck  !=  cCATFR_CATSW )
				nFrm  = 1								// adjust loop limits so that only ONE partial wave for all catenated frames or sweeps...
				// Reactivate the following 3 lines if you want the display mode 'Stack frames and sweeps'
				// if ( raCatStck == cSTACKFR_STACKSW )
				//	nSwp  = 1							// ..or  many smaller  waves (to be displayed superimposed) are built
				// endif
			endif

			for ( f = 0; f < nFrm; f += 1 )									// loop through all frames  
				for ( s = 0; s < nSwp; s += 1)							// loop through all sweeps 
					nSwpPts	= gbShowBlank ?  SweepLenAll( pr, b, f, s ) : SweepLenSave( pr, b, f, s )	// NOT  REALLY  PROTOCOL  AWARE
					nSumSwpPts1	+= nSwpPts
				endfor
			endfor
		endfor

		// printf "\t\tDisplayStimulus(1)  Pts (no blanks)  CatStack: %d   nDacPts: %d   nSumPts:\t%7d\tnSwpPts(last):\t%7d\t  step:%4d  \tFr:%3d\tSw:%3d\tnDrawPts:\t%7d   \r",  raCatStck, nDacPts, nSumSwpPts1, nSwpPts, step, nFrm, nSwp, nSumDrawPts


		// Supply the Save/NoSave wave
		//make  /O  /N = ( nDacPts )  $( "root:stim:" + DispWave( "SV" ) )  =  Nan // wSvWv cannot be an integer wave as an integer wave does not have Nan needed to blank out points	
		make /O /N=( nDacPts / step ) $( "root:stim:" + DispWave( "SV" ) ) =  Nan // wSvWv cannot be an integer wave as an integer wave does not have Nan needed to blank out points	

		// Step 2: Set points which are not to be  displayed to Nan in  Save/NoSave    and   store minima and maxima
		make	/O /N=( MAXDACS, 2 )	root:stim:wDMinMax
		wave	wDMinMax	= root:stim:wDMinMax						
		for ( b = nBlkBeg; b < nBlkEnd; b += 1 )
			nFrm	  = ( raRangeFS == cOneFAllS  ||  raRangeFS == cOneFOneS ) ?  1 :  eFrames( b )
			nSwp = ( raRangeFS == cAllFOneS  ||  raRangeFS == cOneFOneS ) ?  1 : eSweeps( b )

			wave wSVWv	= $( "root:stim:" + DispWave( "SV" ) )		
			SetScale /P X, 0, nSmpInt / cXSCALE * step, cXUnit, wSvWv 					// expand in x by number AND prevent IGOR from scaling  11,12... kms  (..8000,9000 ms is OK )

			for ( f = 0; f < nFrm; f += 1 )											
				for ( s = 0; s < nSwp; s += 1)						
					nStoreStart	= SweepBegSave( pr, b, f, s )
					nStoreEnd		= SweepBegSave( pr, b, f, s ) + SweepLenSave( pr, b, f, s ) 
//					wSVWv[ nStoreStart, nStoreEnd - 1 ] 	= 0  									// the SAVE / NOSAVE periods : mark as 'Save'  (default is nosave = Nan)
					wSVWv[ nStoreStart/step, nStoreEnd/step - 1 ] 	= 0  							// the SAVE / NOSAVE periods : mark as 'Save'  (default is nosave = Nan)
				endfor
			endfor
		MarkPerfTestTime 824	// InterpretScript: DisplayStimulus Step2 fill SV
		endfor


		for ( cd = 0; cd < nDgoChs; cd += 1 )	
			if ( step > 1 )
				sDONm		=  DispWaveDgo( sDgoChans, cd )  
				make /O /B /N	= ( nDacPts / step ) $( "root:stim:" + sDONm ) 				// BYTE wave
				wave  wDOWv	=  		$( 	"root:stim:" + sDONm )					// ..for the display of the digital output
				SetScale /P X, 0, nSmpInt / cXSCALE * step , cXUnit, wDOWv				// expand in x by number AND prevent IGOR from scaling  11,12... kms  (..8000,9000 ms is OK )
			else
				SetScale /P X, 0, nSmpInt / cXSCALE * step , cXUnit, $("root:stim:" + DispWaveDgoFull( sDgoChans, cd ) )	//???!!!			// expand in x by number AND prevent IGOR from scaling  11,12... kms  (..8000,9000 ms is OK )
			endif
	MarkPerfTestTime 825	// InterpretScript: DisplayStimulus Step2 decimate DO
		endfor

		for ( c = 0; c < nCntDA; c += 1)		
			sDacNm			=   iov2( nIO,c, cIONM ) 
			wave	wStimulus	=   $sDacNm 
			waveStats  /Q 	wStimulus	
			// compute and store the minima and maxima for each channel so that identical scales can be drawn below 
			wDMinMax[ c ][ 0 ]	= min( wDMinMax[ c ][ 0 ],  V_min )   		
			wDMinMax[ c ][ 1 ]	= max( wDMinMax[ c ][ 1 ], V_max )   		
			// printf "\t\t\tDisplayStimulus(2a) \t(b:%2d/%2d\tf:%2d/%2d\ts:%2d/%2d) \tfrom\t%7d\tto\t%7d\t(pts:%6d )", b, nBlkEnd - nBlkBeg,  f, nFrm, s, nSwp,  nStartPos, nStartPos+nSwpPts, nSwpPts
			 //		printf "\tShwB:%d \tBg:\t%7d\t... (Stor:\t%7d\t...%7d) \t.En:\t%7d\tc:%d\tmi:\t%7.1lf\tmx:\t%7.1lf \r", gbShowBlank,   SweepBegAll( pr, b, f, s ), nStoreStart, nStoreEnd, SweepBegAll( pr, b, f, s )+SweepLenAll( pr, b, f, s ), c, wDMinMax[ c ][ 0 ], wDMinMax[ c ][ 1 ]
			if ( step > 1 )
				make /O /N=( nDacPts / step ) $( "root:stim:" + sDacNm ) // wSvWv cannot be an integer wave as an integer wave does not have Nan needed to blank out points	
				wave	wStimulus		=   $( "root:stim:" + sDacNm ) 
// 040831
//				SetScale /P X, 0, nSmpInt / cXSCALE * step, cXUnit, wStimulus					// expand in x by number
//			else
//				SetScale /P X, 0, nSmpInt / cXSCALE * step, cXUnit, wStimulus	//???!!!			// expand in x by number
			endif
			SetScale /P X, 0, nSmpInt / cXSCALE * step, cXUnit, wStimulus					// expand in x by number


	MarkPerfTestTime 826	// InterpretScript: DisplayStimulus Step2 decimate DA
		endfor

	
		// Step 3: Convert computed minima and maxima to a  string list  sorted by units  (multiple channels having the same units are merged to 1 minimum and maximum)
		string  /G	root:stim:sUnitsDacMin	= ""
		string  /G	root:stim:sUnitsDacMax	= ""
		svar		sUnitsDacMin	= root:stim:sUnitsDacMin
		svar 		sUnitsDacMax	= root:stim:sUnitsDacMax
		for ( c = 0; c < nCntDA; c += 1)		
			// printf "\t\t\t\tDisplayStimulus(3)   c:%d   \t%s\tmin:%g   \tmax%g \r", c, iov2( nIO, c , cIOUNIT ), wDMinMax[ c ][ 0 ],  wDMinMax[ c ][ 1 ] 
			SetDacMinMaxForSameUnits( iov2( nIO, c , cIOUNIT ), wDMinMax[ c ][ 0 ],  wDMinMax[ c ][ 1 ] )
		endfor

		for ( cd = 0; cd < nDgoChs; cd += 1 )	
			nDgoCh		= str2num( StringFromList( cd, sDgoChans ) )				// the true digout channel number
			nHighestDgoCh	= max( nDgoCh, nHighestDgoCh )						// is usually channel 4 ( Adc/Dac event)
		endfor
		MarkPerfTestTime 830	// InterpretScript: DisplayStimulus Step3 SetDacMinMax
				
		// Step 5: Display the  Save/NoSave ,  stimulus  and Digout  waves
		variable	rMin, rMax, nSeg, nSumSwpPts
		nSumSwpPts	= 0
		nSeg 		= -1
		for ( b = nBlkBeg; b < nBlkEnd; b += 1 )
			nFrm			= ( raRangeFS == cOneFAllS  ||  raRangeFS == cOneFOneS ) ?  1 :  eFrames( b )
			nSwp		= ( raRangeFS == cAllFOneS  ||  raRangeFS == cOneFOneS ) ?  1 : eSweeps( b )
	
			for ( f = 0; f < nFrm; f += 1 )										// loop through all frames   (only ONE for catenated wave mode)

				for ( s = 0; s < nSwp; s += 1)								// loop through all sweeps (only ONE for catenated wave mode)

					string		sSVNm, sSeg, sAxisNm
					variable	xos
					nSeg 	+= 1
					sSeg		=  SelectString( nSeg, "", "#" + num2str( nSeg ) )		// Igors appends #1, #2... to traces to discriminate them if multiple segments or instances of the same base trace are appended
					nSwpPts	= gbShowBlank ?  SweepLenAll( pr, b, f, s ) : SweepLenSave( pr, b, f, s )	// NOT  REALLY  PROTOCOL  AWARE
					nStartPos	= gbShowBlank ?  SweepBegAll( pr, b, f, s ) : SweepBegSave( pr, b, f, s )

					xos	=  ( trunc( nSumSwpPts / step ) - trunc( nStartPos / step ) ) * step * nSmpInt / cXSCALE	// ! nSumSwpPts shifts the starting positions of all segments to x=0 in the stacked (=non-catenated) mode

					// Display the  DigOut  segments 
					for ( cd = 0; cd < nDgoChs; cd += 1 )	
						nDgoCh		= str2num( StringFromList( cd, sDgoChans ) )			// the true channel number
						sDONm		=  DispWaveDgoFull( sDgoChans, cd ) 				// the full wave ( all points )
						if ( step > 1 )
							wave  wDOFull	=  $( 	"root:stim:" + sDONm )					// the name of the full wave ( all points )
							sDONm		=  DispWaveDgo( sDgoChans, cd )  				// the name of the decimated wave 
							MyDecimate1( wDOFull,  "root:stim:" + sDONm , step, 2, TRUE, nStartPos, nStartPos + nSwpPts )
						endif
						sDONm		+=  sSeg
						
						wave  wDOWv	=  $( "root:stim:" + sDONm )							// ..for the display of the digital output
						AppendToGraph /W=$sWNm /R= AxisDgo	  wDOWv[ nStartPos/step, (nStartPos + nSwpPts) /step ]	
						ModifyGraph	 /W=$sWNm 	offset( $sDONm ) = {  xos,  1 + nDgoCh*1.5  }	// stack the digout channels one above the other
						ModifyGraph	 /W=$sWNm 	rgb( $sDONm ) 	  = ( cd*15000, 50000-cd*15000, 0 ) 
						ModifyGraph	 /W=$sWNm	mode = cCITYSCAPE						// cityscape increases drawing time appr. 3 times ! 
						// printf "\t\tDisplayStimulus(5c)   ShowAllBlocks:%d\tc:%d  b:%d  f:%d  s:%d  -> %s  has %7d pts \r",  gbAllBlocks, c, b, f, s, sDONm , numPnts( wDOWv )
						// When displaying  the first   Digout    segment  then adjust the Y axis
						if (  b == nBlkBeg  &&  f == 0  &&  s == 0 )	// adjust during the LAST cd ( after nHighestDgoCh has been set )									
							SetAxis 		/W=$sWNm 	AxisDgo 0, 1+ nHighestDgoCh * 2	// Axis range  = 0 .. DigOut channels
							ModifyGraph	/W=$sWNm 	axisEnab( AxisDgo ) 	= {  1 - (nHighestDgoCh) * cDGOWIDTH, 1 }	//  Dgo traces are diplayed at the top
							ModifyGraph	/W=$sWNm 	axThick( AxisDgo ) = 0,  noLabel( AxisDgo ) =  2, tick( AxisDgo ) = 3 	// hide axis : suppress axis, ticks and labels 
							//ModifyGraph	/W=$sWNm 	freepos( AxisDgo )	= 100							// shift axis so many points outside the plot area : hide it
						endif	
					endfor

					// Display the Save/NoSave  segments , use hidden Dgo axis
					sSVNm 		=  DispWave( "SV" ) + sSeg
					wave  wSVWv	= $( "root:stim:" + DispWave( "SV" ) )		
					AppendToGraph /W=$sWNm /R = AxisDgo   	wSvWv[ nStartPos/step, (nStartPos + nSwpPts)/step]	// first display  a short  Save/NoSave segment...
					ModifyGraph	 /W=$sWNm 	offset( $sSVNm ) = { xos, 0 }
					// When displaying  the first  Save/NoSave  segment  then adjust the Y axis
					if (  b == nBlkBeg  &&  f == 0  &&  s == 0 )									
						SetAxis 		/W=$sWNm  	bottom 0, nSumSwpPts1 * nSmpInt / cXSCALE	// ...then stretch the X axis to the finally needed range
						ModifyGraph	/W=$sWNm 	rgb( $sSVNm ) 	 = ( 50000, 0, 20000 ) 
					endif

					// Display the  stimulus  data  segments 
					for ( c = 0; c < nCntDA; c += 1)		
						variable	rnRed, rnGreen, rnBlue 
						string    	sRGB	= iov2( nIO, c , cIORGB )
						ExtractColors( sRGB, rnRed, rnGreen, rnBlue )
						nRightAxisCnt	= max( 0, nCntDA - 2 )					// additional space is not needed for first and second Y axis

						sDacNm			= iov2( nIO, c, cIONM ) 
						if (  step > 1 )
							wave wStimulusFull	= $sDacNm
							wave	wStimulus	= $( "root:stim:" + sDacNm )
							MyDecimate1( wStimulusFull,  "root:stim:" + sDacNm, step, 2, TRUE, nStartPos, nStartPos + nSwpPts )
							//MyDecimate1( wStimulusFull,  "root:stim:" + sDacNm, step, 2, FALSE, nStartPos, nStartPos + nSwpPts )
						else
							wave	wStimulus	= $sDacNm
						endif
						sDacNm 			+=  sSeg
		
						if (  c == 0 )
							sAxisNm	= "left"
							AppendToGraph /W=$sWNm		wStimulus[ nStartPos/step, (nStartPos + nSwpPts)/ step-1]
							// Stimulus color coding 1: Big pulse sweeps: from red to green, correction pulses same + blue: from magenta to cyan
							// AppendToGraph /C=( COLMX * ( 1- f / nFrm ), COLMX * f / nFrm, COLMX * s / nSwp ) wDAWv
							// Stimulus color coding 2: Big pulse sweeps: from Blue to Magenta, correction pulses are all Cyan
							//AppendToGraph /C=( (s==0)*COLMX * f / nFrm , (s>0)*COLMX * .7 , (s==0)*COLMX * ( 1 - f / ( nFrm +1) ) +(s>0)*(COLMX*.8)) wDAWv	
							// Stimulus color coding 3: Big pulse sweeps: from Magenta to Blue, correction pulses are all Cyan   (Magenta is Dac default color)
							ModifyGraph	 /W=$sWNm	rgb(  $sDacNm )	= ( (s==0)*45000 * ( 1 - f / nFrm ), (s>0)*COLMX * .7 , (s==0)*45000 *  f / nFrm +(s>0)*(COLMX*.8) ) 
						else
							sAxisNm	= "right" + num2str( c )
							AppendToGraph  /W=$sWNm 	/R= $sAxisNm  	wStimulus[ nStartPos/step, (nStartPos + nSwpPts)/step ]
							ModifyGraph	  /W=$sWNm	rgb(  $sDacNm )	= (  rnRed, rnGreen, rnBlue ) 
						endif
						//printf "\t\tDisplayStimulus(5d)   c:%d  step:\t%7d\tnStartPos:\t%7d\tnSwpPts:\t%7d\t->nStartPos:\t%7.1lf\t  nEndPos:\t%7.1lf\txos:\t%7.2lf  \r", c, step,  nStartPos,nSwpPts, nStartPos/step,  (nStartPos + nSwpPts) / step, xos
						ModifyGraph	/W=$sWNm	mode = cCITYSCAPE						// cityscape increases drawing time appr. 3 times ! 
						//ModifyGraph	/W=$sWNm	mode = cLINESandMARKERS			// cityscape increases drawing time appr. 3 times ! 
						ModifyGraph	/W=$sWNm	offset( $sDacNm )	= { xos, 0 }
						ModifyGraph	/W=$sWNm	alblRGB( $sAxisNm )	= ( rnRed, rnGreen, rnBlue )				// use same color for axis label as for trace
					
						if (  b == nBlkBeg  &&  f == 0  &&  s == 0 )									
							// When displaying  the first  stimulus  data  segment  then adjust the Y axis
							ModifyGraph	/W=$sWNm	axisEnab( $sAxisNm ) = { 0, 1 - (nHighestDgoCh+1)*cDGOWIDTH }	//  the Dac traces are plotted in the lower part of the window
							//ModifyGraph	/W=$sWNm 	rgb( $sDacNm)= ( 45000,0,45000),	alblRGB( left ) = (45000,0,45000)	// Stimulus color coding 3: start with trace and axis label set to magenta	
							//ModifyGraph	/W=$sWNm	margin( left ) = 40							//? without this the axes are moved too much to the right by TextBox or SetScale y 
							if (  c == 0 )
								GetAxis		/W=$sWNm /Q	bottom
								LastDataPos	= v_Max  * ( 1 + .05 )    -   v_Min  * .05							// .05 shifts axis to the right so that Y axis label of right axis is not within plot area
								RightAxisPos	= v_Max  * ( 1 + .05 +  nRightAxisCnt * cAXISMARGIN )  - v_Min * ( .05 + nRightAxisCnt * cAXISMARGIN ) // .05 shifts axis...
								//printf "\t\tDisplayStimulus(5e)   c:%d  GetAxis( bottom) \tv_min:%g , v_Max:%g -> LastDataPos:%g  RightAxisPos:%g \r", c, v_Min, LastDataPos, v_Max, RightAxisPos
								SetAxis		/W=$sWNm 	bottom, v_Min, RightAxisPos						// make bottom axis longer if there are Y axis on the right (=multiple Dacs) to be drawn
							endif
							ModifyGraph	/W=$sWNm 	axisEnab( bottom ) 	= { 0, .96 }					//  1 -> .96 supplies a small margin to the right of the rightmost axis   
							ModifyGraph	/W=$sWNm 	tickEnab( bottom )	= { v_Min, v_Max }				// suppress bottom axis ticks on the right where multiple Y axis are to be positioned
						endif

						if (  c > 0 )
							if ( gbSameYAx )
								GetDacMinMaxForSameUnits( iov2( nIO, c , cIOUNIT ), rMin, rMax )
							else
								rMin	= wDMinMax[ c ][ 0 ]											// each trace has its own y axis end points
								rMax	= wDMinMax[ c ][ 1 ]
							endif
							SetAxis	/W=$sWNm  $sAxisNm,	rMin, rMax
							ThisAxisPos	= nCntDA == 2 ? LastDataPos : LastDataPos + ( c - 1) / ( nCntDA-2) * (RightAxisPos - LastDataPos)	// here goes the new Y axis
							// printf "\t\tDisplayStimulus(5f)   c:%d   bottom axis   \t\tv_min:%g , v_Max:%g -> LastDataPos:%g ThisAxisPos:%g  RightAxisPos:%g \r", c, v_Min, v_Max, LastDataPos, ThisAxisPos, RightAxisPos
							ModifyGraph	/W=$sWNm	freePos( $sAxisNm ) = { ThisAxisPos, bottom }
							// GetAxis	/W=$"MultiChannel"	$sAxisNm;  print "GetAxis error", V_flag, sAxisNm, v_Min, v_max  //? IGOR bug: axis should be but is not known to IGOR???????
							if ( c > 0  &&  c < nCntDA - 1 ) 
								LowestTickToPlot	= rMin  + .1 * ( rMax - rMin )							// 10% above the lower y axis end point: do not plot ticks below
								// print "DisplayStimulus( )", c, rMin, rMax, "->", LowestTickToPlot
								ModifyGraph  /W=$sWNm   tickEnab( $sAxisNm ) = { LowestTickToPlot, 1.1 * rMax }		// suppress Y axis ticks where Y axis crosses bottom axis
							endif
						endif
			 			//printf "\t\tDisplayStimulus(5g) \tc:%d  b:%d  f:%d  s:%d[\t%7d\t ..\t%7d\t]has\t%7d\tpts\tnSeg:%2d\t%s\t%s\tcat:%d\tsumswp:\t%7d\t%7d\txos:\t%7.1lf\t    \r",  c, b, f, s,  nStartPos, nStartPos + nSwpPts , nSwpPts, nSeg, pd(sDacNm,8), pd(sSVNm,8), raCatStck, nSumSwpPts, nSumSwpPts1, xos


						// Draw  Axis Units  and  Axis name
						string 	rsName, rsUnit  							
						NameUnitsByNm( iov2( nIO, c , cIONM ) , rsName, rsUnit )	
						//printf "\tDisplayStimulus()  \tNameUnitsByNm( \t%s\t)   old: \t'%s' \t-> \t'%s'  \told: \t'%s'  \t-> \t'%s'  \r", pd( iov2( nIO, c , cIONM ), 6 ), sYName, rsName,  sYUnits, rsUnit
						
						SetScale /P y, 0,0,  rsUnit,   wStimulus							// Store the Y units of the wave within the wave to make it accessible for 'Scalebars()'...
						Label  /W=$sWNm $sAxisNm "\\u#2"									//..but prevent  IGOR  from drawing the units automatically (in most cases at ugly positions)
						//..instead draw the Y units manualy as a Textbox  just above the corresponding Y Axis  in the same color as the corresponding trace  
						// -54, 48, 10 are magic numbers which  are adjusted  so that the text is at the same  X as the axis. They SHOULD be   #defined......................
						// As it seems impossible to place the textbox automatically at the PERFECT position: not overlapping anithing else, not blowing up the graph too much...
						// (position depends on name length, units length, number of digout traces, graph size)  the user must possibly move it a bit (which is very fast and very easy)...
						variable	TbXPos	= c == 0 ? -54 :  48 - 10 * ( nCntDA - 1- c )				// left, left right,  left mid right...
						// the TextboxUnits has the same name as its corresponding axis: this allows easy deletion together with the axis (from the 'Axes and Scalebars' Panel)
						TextBox /W=$sWNm /C /N=$sAxisNm  /E=0 /A=MC /X=(TbXPos)  /Y=50  /F=0  /G=(rnRed, rnGreen, rnBlue)   rsName  + "\r" + rsUnit	// print YUnits horiz.  /E=0: rel. position as percentage of plot area size 
						//printf "\t\tDisplayStimulus( )   c:%2d/%2d \tTbXPos:%d \tGain:'%s'   \t%s   \t'%s'   \t'%s' \r", c, nScriptDacs, TbXPos, iov2( nIO, c , cIOGAIN ), pd( sYName,12), rsUnit, sRGB
	
					endfor								// nScriptDacs
	
					if ( raCatStck == cCATFR_CATSW  ||  raCatStck == cSTACKFR_CATSW )
						nSumSwpPts	+= nSwpPts
					endif	

				endfor									// swp

				if ( raCatStck == cSTACKFR_CATSW )
					nSumSwpPts	= 0
				endif	

			endfor										// frm
		endfor
		KillWaves wDMinMax
		MarkPerfTestTime 840	// InterpretScript: DisplayStimulus Step5 display end

//		StimulusDecimationTest()
	endif													// gbDisplay

End		


Static  Function  /S  DispWave( sIOType )
// 040410 no blocks, prots needed in name
	string 	sIOType
	return	sIOType
End	


Function  /S  DispWaveDgo( sDgoChans, cd )
	string 	sDgoChans
	variable	cd
	variable	nDgoCh	= str2num( StringFromList( cd, sDgoChans ) )	// the true channel number, not the index 0,1,2...
	return	"DO" + num2str( nDgoCh ) 
End	

Function  /S  DispWaveDgoFull( sDgoChans, cd )
	string 	sDgoChans
	variable	cd
	variable	nDgoCh	= str2num( StringFromList( cd, sDgoChans ) )	// the true channel number, not the index 0,1,2...
	return	"DOFull" + num2str( nDgoCh ) 
//	return	"DO" + num2str( nDgoCh ) 
End	


Static Function		SetDacMinMaxForSameUnits( sUnits, vMin, vMax )
	string	sUnits
	variable	vMin, vMax
	svar	   sUnitsDacMin	= root:stim:sUnitsDacMin, 	sUnitsDacMax	= root:stim:sUnitsDacMax
	string	   sMinStored	= StringByKey( sUnits, sUnitsDacMin )
	string	   sMaxStored	= StringByKey( sUnits, sUnitsDacMax )
	sUnitsDacMin		= ReplaceStringByKey( sUnits, sUnitsDacMin, SelectString( strlen( sMinStored ), num2str( vMin ), num2str( min( vMin, str2num( sMinStored ) ) ) ) )
	sUnitsDacMax 		= ReplaceStringByKey( sUnits, sUnitsDacMax, SelectString( strlen( sMaxStored ), num2str( vMax ), num2str( max( vMax, str2num( sMaxStored ) ) ) ) )
	//printf "\t\tSetDacMinMaxForSameUnits() sUnits:%s  \tvMin:%g \tvMax:%g \t-> sUnitsDacMin:%s\tsUnitsDacMax:%s \r",  pd(sUnits,8), vMin, vMax, pd(sUnitsDacMin,25), sUnitsDacMax 
End 
	
Static Function		GetDacMinMaxForSameUnits( sUnits, rMin, rMax )
	string	sUnits
	variable	&rMin, &rMax
	svar		sUnitsDacMin	= root:stim:sUnitsDacMin, 	sUnitsDacMax	= root:stim:sUnitsDacMax
	rMin		= str2num( StringByKey( sUnits, sUnitsDacMin ) )
	rMax		= str2num( StringByKey( sUnits, sUnitsDacMax ) )
	// printf "\t\tGetDacMinMaxForSameUnits() sUnits:%s  \t->\tMin:%g \tMax:%g  \r",  pd(sUnits,8), rMin, rMax
End	




Function 		MyDecimate( wSource, sDestName, step, XPos, bKeepMinMaxInDecimation )
//  The code has been taken from the procedure file: "C:Programme:WaveMetrics:Igor Pro Folder:WaveMetrics Procedures:Analysis:Decimation.ipf"
//  This decimation function is adequate for stimulus or digout as amplitude is maintained independently of decimation 
	wave 	wSource
	string 	sDestName			// String contains name of dest which may or may not already exist
	variable 	step
	variable	bKeepMinMaxInDecimation// TRUE : adequate for stimulus or digout as amplitude is maintained independently of decimation 
	variable 	XPos					// 1 : X's are at left edge of decimation window (original FDecimate behavior),   2 : X's are in the middle;   3 : X's are at right edge
	XPos -= 1
	
	// Clone source so that source and dest can be identical
//	Duplicate/O wSource, decimateTmpSource
	
	variable 	nPts		= numpnts( wSource )		// number of points in input wave
	variable 	nDecPts	= floor( nPts / step )					// number of points in output wave
//	Duplicate/O	decimateTmpSource,	$sDestName			// keep same precision
//	Redimension	/N = ( nDecPts ) 		$sDestName		// set number of points to decreased value
	CopyScales	wSource,	$sDestName			// copy units

	// we'll need to fix the X scaling
	variable 	x0	= leftx( wSource )
	variable 	dx	= deltax( wSource )
	SetScale /P x, x0, dx * step, "",  $sDestName

	variable 	segWidth 	= ( step - 1 ) * dx 					// width of source wave segment
	wave 	dw 		= $sDestName						// Make compiler understand the next line as a wave assignment

	if ( ! bKeepMinMaxInDecimation )						
//		dw 	= mean( decimateTmpSource, x, x+segWidth )		// Original WM code : decimation decreases the amplitude 
	else
		variable	pt, nTargetPt = 0						// keep minimum and maximum within the interval
//		for ( pt = 0; pt < nPts; pt += 2 * step, nTargetPt += 2 )
		for ( pt = 0; pt < nPts - 2 * step; pt += 2 * step, nTargetPt += 2 )
			waveStats  /Q	/R=[ pt, pt + 2 * step - 1]	wSource	
			dw[ nTargetPt +  ( v_minLoc   > v_maxloc ) ]	= V_min	
			dw[ nTargetPt +  ( v_maxLoc >= v_minloc ) ]	= V_max
		endfor
	endif
	
	if ( XPos )
		dx	= deltax( dw )
		x0	= pnt2x( dw, 0 ) + ( segWidth ) * 0.5 * XPos
		SetScale	/P x x0, dx, dw
	endif
	
	KillWaves	/Z decimateTmpSource
End


Function 		MyDecimate1( wSource, sDestName, step, XPos, bKeepMinMaxInDecimation, nStartPt, nEndPt )
//  The code has been taken from the procedure file: "C:Programme:WaveMetrics:Igor Pro Folder:WaveMetrics Procedures:Analysis:Decimation.ipf"
//  This decimation function is adequate for stimulus or digout as amplitude is maintained independently of decimation 
	wave 	wSource
	string 	sDestName			// String contains name of dest which must already exist
	variable 	step
	variable	bKeepMinMaxInDecimation// TRUE : adequate for stimulus or digout as amplitude is maintained independently of decimation 
	variable 	XPos					// ignored..........1 : X's are at left edge of decimation window (original FDecimate behavior),   2 : X's are in the middle;   3 : X's are at right edge
	variable 	nStartPt, nEndPt 

	XPos -= 1
	wave 	dw 		= $sDestName						// Make compiler understand the next line as a wave assignment

	variable	pt, nTargetPt = trunc( nStartPt / step )				// keep minimum and maximum within the interval
	if ( ! bKeepMinMaxInDecimation )						
		for ( pt = nStartPt; pt <= nEndPt -  step; pt +=  step, nTargetPt += 1 )
			waveStats  /Q /R=[ pt, pt + step - 1]	wSource	
			dw[ nTargetPt    ]	= V_avg	
		endfor
	else
//		for ( pt = 0; pt < nPts; pt += 2 * step, nTargetPt += 2 )
//		for ( pt = nStartPt; pt <   nEndPt - 4 * step-2; pt += 2 * step, nTargetPt += 2 )
//		for ( pt = nStartPt; pt <   nEndPt - 2 * step; pt += 2 * step, nTargetPt += 2 )
//		for ( pt = nStartPt; pt <   nEndPt ; pt += 2 * step, nTargetPt += 2 )
		for ( pt = nStartPt; pt <= nEndPt ; pt += 2 * step, nTargetPt += 2 )		// pt <= nEndPt  must perhaps be refined to avoid (uncleared) garbage spikes in the traces 
			waveStats  /Q /R=[ pt, pt + 2 * step - 1]	wSource	
			dw[ nTargetPt +  ( v_minLoc   > v_maxloc ) ]	= V_min	
			dw[ nTargetPt +  ( v_maxLoc >= v_minloc ) ]	= V_max
		endfor
	endif
End


// Original WM functions are shorter but not very useful for stimulus or digout as decimation decreases the amplitude

Function 	MyFDecimate( wSource, sDestName, factor )
	wave 	wSource
	string 	sDestName		// String contains name of dest which may or may not already exist
	variable 	factor
	MyFDecimateXPos( wSource, sDestName, factor, 1)	// 1 is control of X positioning 
End

//JW- new version with control of X positioning. 6/21/96
Function 	MyFDecimateXPos( wSource, sDestName, factor, XPos)
	wave 	wSource
	string 	sDestName	// String contains name of dest which may or may not already exist
	variable 	factor
	variable 	XPos			//=1, X's are at left edge of decimation window (original FDecimate behavior)
						//=2, X's are in the middle; =3, X's are at right edge
	XPos -= 1
	
	// Clone source so that source and dest can be identical
	Duplicate/O wSource, decimateTmpSource
	
	variable 	nPts	= floor( numpnts( decimateTmpSource ) / factor ) // number of points in output wave
	Duplicate/O	decimateTmpSource,	$sDestName			// keep same precision
	Redimension	/N = ( nPts ) 		$sDestName			// set number of points to decreased value
	CopyScales	decimateTmpSource,	$sDestName			// copy units
	// we'll need to fix the X scaling
	variable 	x0	= leftx( decimateTmpSource )
	variable 	dx	= deltax( decimateTmpSource )
	SetScale/P x, x0, dx * factor, "", $sDestName
	
	variable 	segWidth 	= ( factor-1 ) * dx 					// width of source wave segment
	wave 	dw 		= $sDestName						// Make compiler understand the next line as a wave assignment
	dw 	= mean( decimateTmpSource, x, x+segWidth )
	
	if ( XPos )
		dx	= deltax( dw )
		x0	= pnt2x( dw, 0 ) + ( segWidth ) * 0.5 * XPos
		SetScale	/P x x0, dx, dw
	endif
	
	KillWaves	/Z decimateTmpSource
End

