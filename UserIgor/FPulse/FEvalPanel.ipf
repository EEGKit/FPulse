//
//  FEvalPanel.ipf	The main evaluation panel

#pragma rtGlobals=1		// Use modern global access method.

//=======================================================================================================================
// THE  NEW  DS-EVALUATION PANEL

Function		PanelEvaluation_()
	string  	sFBase		= "root:uf:"
	string  	sFSub		= ksfEVO_	
	string  	sWin			= "de" 
	string		sPnTitle
	sprintf	sPnTitle, "%s %s", "Evaluation - Read Cfs " ,  FormatVersion()
	string		sDFSave		= GetDataFolder( 1 )						// The following functions do NOT restore the CDF so we remember the CDF in a string .
	PossiblyCreateFolder( sFBase + sFSub + sWin ) 	
	SetDataFolder sDFSave										// Restore CDF from the string  value
	InitPanelDSEvalDetails3( sFBase + sFSub, sWin )					// fills big text wave  'sPnOptions' (=wPn)  with all information about the controls necessary to build the panel
	Panel3Main(   sWin, 		sPnTitle, 		sFBase + sFSub,  0, 0 )	// Compute the location of panel controls and the panel dimensions. Draw the panel displaying and hiding needed/unneeded controls
	ModifyPanel /W=$sWin fixedSize= 1					// prevent the user to.... maximize the panel by disabling the Maximize button

	PnLstPansNbsAdd( ksfEVO,  sWin )

	EnableSetVar(  sWin,  "root_uf_evo_de_gsReadDPath0000",  kNOEDIT )	// read-only, but could also be made to allow file name entry
	EnableSetVar(  sWin,  "root_uf_evo_de_gReadSmpInt0000",   kNOEDIT )	// read-only

	// Handle the status info
	EnableSetVar(  sWin,  "root_uf_evo_de_gsStatusInf0000",      kNOEDIT )	// make the  'status info'  SetVariable field read-only
	SetFormula $"root:uf:evo:de:gsStatusInf0000",  "num2str( root:uf:evo:evl:wCurRegion[ kCURSWP ] ) + Spaces3_() + num2str( root:uf:evo:cfsr:gDataSections) "

	EnableButton( 	  sWin, "root_uf_evo_de_buEvStimDlg0000",  kDISABLE )	// wait till after the first data have been read
	EnableCheckbox(sWin, "root_uf_evo_de_gbShwScr0000",      kDISABLE )	

//	UpdateDependent_Of_AllowDelete( sWin, "root_uf_evo_de_cbAlDel0000" )	
//	UpdateDependent_Of_AllowDelete( sWin, "root_uf_evo_set_cbAlDel0000" )	
End

Function	/S	Spaces3_()
	return " / "
End


Function		InitPanelDSEvalDetails3( sF, sPnOptions )
	string  	sF, sPnOptions
	string		sPanelWvNm = sF + sPnOptions
	variable	n = -1, nItems = 100
	printf "\tInitPanelDSEvalDetails3( '%s',  '%s' ) \r", sF, sPnOptions 
	make /O /T /N=(nItems)	$sPanelWvNm
	wave  /T	tPn	=		$sPanelWvNm
	// Cave / Flaw :   No tabcontrol = empty  'Tabs'  must have   different number of spaces (no Tab, not the empty string )  to be recognised correctly
	// Cave / Flaw :   For each item in  'Tabs'   there must be a  corresponding  'Blks'  entry  even if empty
	// Cave / Flaw :	   Only tabulators can be used  for aligning the following columns, do not use spaces.... (maybe they are allowed...)
	// Cave :	Supply as many row title separators for dependent controls as there are row titles for the leading control. See   'Fit' / 'FitFunc' / 'FitRng' control   and  the functions 'fFitRowTitles()' /  'fFitRowDums()' for an example.
	
	//				Type	 NxL Pos MxPo OvS	Tabs		Blks		Mode		Name		RowTi		ColTi			ActionProc	XBodySz	FormatEntry	Initval		Visibility	SubHelp
	n += 1;	tPn[ n ] =	"BU:    1:	0:	4:	0:	°:		,:		1,°:			PrevFile:		< Prev file:		:			fPrevFile():		:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	1:	4:	0:	°:		,:		1,°:			NextFile:		Next file >:		:			fNextFile:		:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	2:	4:	0:	°:		,:		1,°:			bCurAcqFile:	Current Acq:	:			fCurAcqFile():	:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	3:	4:	0:	°:		,:		1,°:			SelFile:		Select file:		:			fSelFile():		:		:			:			:		:	"		//	single button
// 050607a
//gn	n += 1;	tPn[ n ] =	"STR:  1:	0:	4:	1:	°:		,:		1,°:			gsReadDPath:	 Path:		:			:			202:		:			:c_epc_data	:		:	"		//  	single  SetVariable for String display
	n += 1;	tPn[ n ] =	"STR:  1:	0:	4:	2:	°:		,:		1,°:			gsReadDPath:	 Path:		:			:			202:		:			:			:		:	"		//  	single  SetVariable for String display
	n += 1;	tPn[ n ] =	"SV:    0:	3:	4:	0:	°:		,:		1,:			gReadSmpInt:	 SI/us:		:			:	  		40:		%4d; 0,0,0:	:			:		:	"

	n += 1;	tPn[ n ] =	"STR:  1:	0:	3:	2:	°:		,:		1,°:			gsStatusInf:	 Info:			:			:			270:		:			:			:		:	"		//  	single  SetVariable for String display
	n += 1;	tPn[ n ] =	"PM:	   1:	0:	3:	0:	°:		,:		,:			gDspMode:	:			 Display:		fDispMode():	66:		fDispModeLst():	0000_1:		:		:	"		// 	1-dim  popmenu (1 row)
	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:		,:		,:			dum1g:		:			:			:			:		:			:			:		:	"		//	single separator needs ',' 

	// TabGroup :Tabcontrol with 1dim controls
// Version1 : horz PMs are OK
//	n += 1;	tPn[ n ] =	"PM:	   0:	1:	3:	0:	LstChan():	,°,°,°,°,°,°:	1°1°1°1°1°1°:	pmYAxis:		:	Y axis Max,Y axis Min,:	fYaxis():		55:		fYaxisLst():		:			:		:	"		// 	1-dim  popmenu (1 row)
// Version2 : vert PMs are 1 positioned too high  when there is no CR  (=PM: 0: ...) ???
	// n += 1;	tPn[ n ] =	"PM:	   1:	0:	3:	0:	LstChan():	,°,°,°,°,°,°:	1°1°1°1°1°1°:	pmYAxis:		Yax top,Yax bot,:	:		fYaxisPM():	55:		fYaxisLstPM():	fYaxisInitPM():	:		:	"		// 	1-dim  popmenu (1 column)

	n += 1;	tPn[ n ] =	"SV:	   1:	0:	4:	0:	LstChan():	,°,°,°,°,°,°:	1°1°1°1°1°1°:	svYAxis:		Y top,Y bot,:	:			fYaxis():		55:		%.3lf;-inf,inf,0:	fYaxisInit():		:		:	"		// 	1-dim  SetVariable (1 column)
	n += 1;	tPn[ n ] =	"SV:	   0:	1:	4:	0:	LstChan():	,°,°,°,°,°,°:	1°1°1°1°1°1°:	svXAxis:		:			X left,right:		fXAxis():		55:		%.3lf;0,inf,0:	fXaxisInit():		:		:	"		//  	1 dim  SetVariable( 1 row)
	n += 1;	tPn[ n ] =	"CB:	   1:	0:	4:	0:	LstChan(): ,°,°,°,°,°,°:	1°1°1°1°1°1°:	cbAutoSclY:	Autoscl Y:		:			fAutoSclY():	:		:			~1:			:		:	"		// todo ??? cannot position this control on the 2 preceding lines ???
	n += 1;	tPn[ n ] =	"BU:    0:	1:	4:	0:	LstChan(): ,°,°,°,°,°,°:	1°1°1°1°1°1°:	buSpreadC:	spread cursors:	:			fSpreadCurs():	:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	2:	4:	0:	LstChan(): ,°,°,°,°,°,°:	1°1°1°1°1°1°:	buAutoSetC:	autoset cursors:	:			fAutoSetCurs():	:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	3:	4 :	0:	LstChan(): ,°,°,°,°,°,°:	1°1°1°1°1°1°:	buRescale:	rescale:		:			fRescale():		:		:			:			:		:	"		//	single button
//	n += 1;	tPn[ n ] =	"SEP:  0:	0:	1:	0:	LstChan():	,:		,:			dum2a:		:			:			:			:		:			:			:		:	"		//	single separator needs ',' 
	n += 1;	tPn[ n ] =	"BU:    1:	0:	8:	0:	LstChan(): ,°,°,°,°,°,°:	1°1°1°1°1°1°:	buYShrink:	y Shr:		:			fYShrink__():	:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	1:	8:	0:	LstChan(): ,°,°,°,°,°,°:	1°1°1°1°1°1°:	buYExpand:	Y exp:		:			fYExpand__():	:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	2:	8:	0:	LstChan(): ,°,°,°,°,°,°:	1°1°1°1°1°1°:	buYUp:		y Up:			:			fYUp__():		:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	3:	8:	0:	LstChan(): ,°,°,°,°,°,°:	1°1°1°1°1°1°:	buYDown:		y Dwn:		:			fYDown__():	:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	4:	8:	0:	LstChan(): ,°,°,°,°,°,°:	1°1°1°1°1°1°:	buXCompress:	x Cmp:		:			fXCompress__():	:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	5:	8:	0:	LstChan(): ,°,°,°,°,°,°:	1°1°1°1°1°1°:	buXExpand:	X exp:		:			fXExpand__():	:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	6:	8:	0:	LstChan(): ,°,°,°,°,°,°:	1°1°1°1°1°1°:	buXAdvance:	x Adv:		:			fXAdvance__():	:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	7:	8:	0:	LstChan(): ,°,°,°,°,°,°:	1°1°1°1°1°1°:	buXReverse:	x Rev:		:			fXReverse__():	:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    1:	0:	8:	0:	LstChan(): ,°,°,°,°,°,°:	1°1°1°1°1°1°:	buBaseLCsr:	[ base:		:			buBaseBegCsr()::		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	1:	8:	0:	LstChan(): ,°,°,°,°,°,°:	1°1°1°1°1°1°:	buBaseRCsr:	Base ]:		:			buBaseEndCsr()::		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	2:	8:	0:	LstChan(): ,°,°,°,°,°,°:	1°1°1°1°1°1°:	buPeakBCsr:	[ peak:		:			buPeakBegCsr()::		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	3:	8:	0:	LstChan(): ,°,°,°,°,°,°:	1°1°1°1°1°1°:	buPeakECsr:	Peak ]:		:			buPeakEndCsr()::		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	4:	8:	0:	LstChan(): ,°,°,°,°,°,°:	1°1°1°1°1°1°:	buFit0BCsr:	[ fit:			:			buFit0BegCsr():	:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	5:	8:	0:	LstChan(): ,°,°,°,°,°,°:	1°1°1°1°1°1°:	buFit0ECsr:	Fit ]:			:			buFit0EndCsr():	:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	6:	8:	0:	LstChan(): ,°,°,°,°,°,°:	1°1°1°1°1°1°:	buFit1BCsr:	[ g fit:		:			buFit1BegCsr():	:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	7:	8:	0:	LstChan(): ,°,°,°,°,°,°:	1°1°1°1°1°1°:	buFit1ECsr:	G fit ]	:		:			buFit1EndCsr():	:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    1:	0:	8:	0:	LstChan(): ,°,°,°,°,°,°:	1°1°1°1°1°1°:	buLat0BCsr:	[ lat0:		:			buLat0BegCsr():	:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	1:	8:	0:	LstChan(): ,°,°,°,°,°,°:	1°1°1°1°1°1°:	buLat0ECsr:	Lat0 ]:		:			buLat0EndCsr():	:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	2:	8:	0:	LstChan(): ,°,°,°,°,°,°:	1°1°1°1°1°1°:	buLat1BCsr:	[ m lat1:		:			buLat1BegCsr():	:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	3:	8:	0:	LstChan(): ,°,°,°,°,°,°:	1°1°1°1°1°1°:	buLat1ECsr:	M lat1 ]:		:			buLat1EndCsr():	:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	4:	8:	0:	LstChan(): ,°,°,°,°,°,°:	1°1°1°1°1°1°:	buLat2BCsr:	[ n lat2:		:			buLat2BegCsr():	:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	5:	8:	0:	LstChan(): ,°,°,°,°,°,°:	1°1°1°1°1°1°:	buLat2ECsr:	N lat2 ]:		:			buLat2EndCsr():	:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"CB:	   0:	6:	8:	1:	LstChan(): ,°,°,°,°,°,°:	1°1°1°1°1°1°:	cbSmeTm:		Same Time:	:			fSameTime():	:		:			:			:		:	"		// 	1-dim  popmenu (1 row)



	n += 1;	tPn[ n ] =	"SV:	   1:	0:	3:	0:	LstChan():	,°,°,°,°,°,°:	1°1°1°1°1°1°:	svReg:		:			Eval Regions:	fReg():		35:		%2d;0,"+num2str(kRG_MAX)+",1:~1::		:	"		//  	upper limit = kRG_MAX

// 051109
//	n += 1;	tPn[ n ] =	"PM:	   1:	0:	4:	0:	LstChan():	LstReg():	1,1,1,°1,1,1,°:	pmBaseOp:	:			Bs:			fBaseOp():		65:		fBaseOpLst():	~2:			:		:	"		// 	1-dim  popmenu (1 col)
//	n += 1;	tPn[ n ] =	"PM:	   0:	1:	4:	0:	LstChan():	LstReg():	1,1,1,°1,1,1,°:	pmUpDn:		:			Pk:			fPkDir():		65:		fPkDirLst():	0000_3;1000_2~1:	:	:	"		// 	1-dim  popmenu (1 col)
//	n += 1;	tPn[ n ] =	"SV:	   0:	2:	4:	0:	LstChan():	LstReg():	1°1°1°1°1°1°:	svSideP:		:			Pts 1side:		fSidePts():		35:		%2d;0,20,1:	0000_3:		:		:	"		//  single  SetVariable
//	n += 1;	tPn[ n ] =	"SV:	   0:	3:	4:	0:	LstChan():	LstReg():	1°1°1°1°1°1°:	svSDevFact:	SDevF:		:			:			40:		%.1lf;1,100,0:	~2:			:		:	"		//  	1 dim  SetVariable( 1 row)
	n += 1;	tPn[ n ] =	"PM:	   1:	0:	3:	0:	LstChan():	LstReg():	1,1,1,°1,1,1,°:	pmBaseOp:	:			Bs:			fBaseOp():		65:		fBaseOpLst():	~2:			:		:	"		// 	1-dim  popmenu (1 col)
	n += 1;	tPn[ n ] =	"SV:	   0:	1:	3:	0:	LstChan():	LstReg():	1°1°1°1°1°1°:	svSDevFact:	SDevF:		:			:			40:		%.1lf;1,100,0:	~2:			:		:	"		//  	1 dim  SetVariable( 1 row)

	// 060213  Aligning averages
	n += 1;	tPn[ n ] =	"PM:	   0:	2:	3:	0:	LstChan():	LstReg():	1,1,1,°1,1,1,°:	pmAvgAlign:	Avg Align:		:			fAvgAlign():	56:		fAvgAlignLst_():	:			:		:	"		// 	1-dim  popmenu (1 row)

	n += 1;	tPn[ n ] =	"PM:	   1:	0:	3:	0:	LstChan():	LstReg():	1,1,1,°1,1,1,°:	pmUpDn:		:			Pk:			fPkDir():		65:		fPkDirLst():	0000_3;1000_2~1:	:	:	"		// 	1-dim  popmenu (1 col)
	n += 1;	tPn[ n ] =	"SV:	   0:	1:	3:	0:	LstChan():	LstReg():	1°1°1°1°1°1°:	svSideP:		:			Pts 1side:		fSidePts():		35:		%2d;0,20,1:	0000_3:		:		:	"		//  single  SetVariable
	n += 1;	tPn[ n ] =	"SV:	   0:	2:	3:	0:	LstChan():	LstReg():	1°1°1°1°1°1°:	svRserMV:	Rser/mV:		:			:			32:		%3d;1,1000,0:	~10:			:		:	"		//  	1 dim  SetVariable( 1 row)

	n += 1;	tPn[ n ] =	"PM:	   1:	0:	6:	0:	LstChan():	LstReg():	1,1,1,°1,1,1,°:	pmLat00:		:			L0:			fLat0B():		38:		fLatCLst():		~1:			:		:	"		// 	1-dim  popmenu (1 col)
	n += 1;	tPn[ n ] =	"PM:	   0:	1:	6:	0:	LstChan():	LstReg():	1,1,1,°1,1,1,°:	pmLat01:		:			 >:			fLat0E():		38:		fLatCLst():		~1:			:		:	"		// 	1-dim  popmenu (1 col)
	n += 1;	tPn[ n ] =	"PM:	   0:	2:	6:	0:	LstChan():	LstReg():	1,1,1,°1,1,1,°:	pmLat10:		:			L1:			fLat1B():		38:		fLatCLst():		~1:			:		:	"		// 	1-dim  popmenu (1 col)
	n += 1;	tPn[ n ] =	"PM:	   0:	3:	6:	0:	LstChan():	LstReg():	1,1,1,°1,1,1,°:	pmLat11:		:			 >:			fLat1E():		38:		fLatCLst():		~1:			:		:	"		// 	1-dim  popmenu (1 col)
	n += 1;	tPn[ n ] =	"PM:	   0:	4:	6:	0:	LstChan():	LstReg():	1,1,1,°1,1,1,°:	pmLat20:		:			L2:			fLat2B():		38:		fLatCLst():		~1:			:		:	"		// 	1-dim  popmenu (1 col)
	n += 1;	tPn[ n ] =	"PM:	   0:	5:	6:	0:	LstChan():	LstReg():	1,1,1,°1,1,1,°:	pmLat21:		:			 >:			fLat2E():		38:		fLatCLst():		~1:			:		:	"		// 	1-dim  popmenu (1 col)

	// The initial visibility of  'FiFnc'  and  'FiRng'   must be the same as the initial values of the  'Fit'  checkbox
	n += 1;	tPn[ n ] =	"CB:	   1:	0:	3:	0:	LstChan():	LstReg():	1,1,1,°1,1,1,°:	cbFit:		fFitRowTitles():	:			fFit_e():			:		:			fFitOnOff():		:		:	"		// !!! the # of row titles ~ # of fits
	n += 1;	tPn[ n ] =	"PM:	   0:	1:	3:	0:	LstChan():	LstReg():	1,°:			pmFiFnc:		fFitRowDums():	Fn:			fFitFnc():		65:		fFitFncLst():	fFitFncInit():	fFitOnOff():	:	"		// 	1-dim  popmenu (1 col)
	n += 1;	tPn[ n ] =	"PM:	   0:	2:	3:	0:	LstChan():	LstReg():	1,1,1,°1,1,1,°:	pmFiRng:		fFitRowDums():	Rng:			fFitRng():		58:		fFitRngLst():	fFitRngInit():	fFitOnOff()::	"		// 	1-dim  popmenu (1 col)
	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	LstChan():	,:		1,°:			dum2b:		:			:			:			:		:			:			:		:	"		//	single separator needs ','

	// TabGroup: One untabbed  separator
//	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:		,:		,:			dum2d:		:			:			:			:		:			:			:		:	"		//	single separator needs ','  for 'Blks'  and 'dummy' for 'Name'
//	n += 1;	tPn[ n ] =	"BU:    1:	0:	8:	0:	°:		,:		1°:			buYShrink:	y Shr:		:			fYShrink():		:		:			:			:		:	"		//	single button
//	n += 1;	tPn[ n ] =	"BU:    0:	1:	8:	0:	°:		,:		1°:			buYExpand:	Y exp:		:			fYExpand():	:		:			:			:		:	"		//	single button
//	n += 1;	tPn[ n ] =	"BU:    0:	2:	8:	0:	°:		,:		1°:			buYUp:		y Up:			:			fYUp():		:		:			:			:		:	"		//	single button
//	n += 1;	tPn[ n ] =	"BU:    0:	3:	8:	0:	°:		,:		1°:			buYDown:		y Dwn:		:			fYDown():		:		:			:			:		:	"		//	single button
//	n += 1;	tPn[ n ] =	"BU:    0:	4:	8:	0:	°:		,:		1°:			buXCompress:	x Cmp:		:			fXCompress():		:		:			:			:		:	"		//	single button
//	n += 1;	tPn[ n ] =	"BU:    0:	5:	8:	0:	°:		,:		1°:			buXExpand:	X exp:		:			fXExpand():	:		:			:			:		:	"		//	single button
//	n += 1;	tPn[ n ] =	"BU:    0:	6:	8:	0:	°:		,:		1°:			buXAdvance:	x Adv:		:			fXAdvance():	:		:			:			:		:	"		//	single button
//	n += 1;	tPn[ n ] =	"BU:    0:	7:	8:	0:	°:		,:		1°:			buXReverse:	x Rev:		:			fXReverse():	:		:			:			:		:	"		//	single button
//	n += 1;	tPn[ n ] =	"BU:    1:	0:	8:	0:	°:		,:		1,°:			buBaseLCsr:	[ base:		:			buBaseBegCsr()::		:			:			:		:	"		//	single button
//	n += 1;	tPn[ n ] =	"BU:    0:	1:	8:	0:	°:		,:		1,°:			buBaseRCsr:	Base ]:		:			buBaseEndCsr()::		:			:			:		:	"		//	single button
//	n += 1;	tPn[ n ] =	"BU:    1:	2:	8:	0:	°:		,:		1,°:			buPeakBCsr:	[ peak:		:			buPeakBegCsr()::		:			:			:		:	"		//	single button
//	n += 1;	tPn[ n ] =	"BU:    0:	3:	8:	0:	°:		,:		1,°:			buPeakECsr:	Peak ]:		:			buPeakEndCsr()::		:			:			:		:	"		//	single button
//	n += 1;	tPn[ n ] =	"BU:    0:	4:	8:	0:	°:		,:		1,°:			buFit0BCsr:	[ fit:			:			buFit0BegCsr():	:		:			:			:		:	"		//	single button
//	n += 1;	tPn[ n ] =	"BU:    0:	5:	8:	0:	°:		,:		1,°:			buFit0ECsr:	Fit ]:			:			buFit0EndCsr():	:		:			:			:		:	"		//	single button
//	n += 1;	tPn[ n ] =	"BU:    0:	6:	8:	0:	°:		,:		1,°:			buFit1BCsr:	[ g fit:		:			buFit1BegCsr():	:		:			:			:		:	"		//	single button
//	n += 1;	tPn[ n ] =	"BU:    0:	7:	8:	0:	°:		,:		1,°:			buFit1ECsr:	G fit ]	:		:			buFit1EndCsr():	:		:			:			:		:	"		//	single button
//	n += 1;	tPn[ n ] =	"BU:    1:	0:	8:	0:	°:		,:		1,°:			buLat0BCsr:	[ lat0:		:			buLat0BegCsr():	:		:			:			:		:	"		//	single button
//	n += 1;	tPn[ n ] =	"BU:    0:	1:	8:	0:	°:		,:		1,°:			buLat0ECsr:	Lat0 ]:		:			buLat0EndCsr():	:		:			:			:		:	"		//	single button
//	n += 1;	tPn[ n ] =	"BU:    0:	2:	8:	0:	°:		,:		1,°:			buLat1BCsr:	[ m lat1:		:			buLat1BegCsr():	:		:			:			:		:	"		//	single button
//	n += 1;	tPn[ n ] =	"BU:    0:	3:	8:	0:	°:		,:		1,°:			buLat1ECsr:	M lat1 ]:		:			buLat1EndCsr():	:		:			:			:		:	"		//	single button
//	n += 1;	tPn[ n ] =	"BU:    0:	4:	8:	0:	°:		,:		1,°:			buLat2BCsr:	[ n lat2:		:			buLat2BegCsr():	:		:			:			:		:	"		//	single button
//	n += 1;	tPn[ n ] =	"BU:    0:	5:	8:	0:	°:		,:		1,°:			buLat2ECsr:	N lat2 ]:		:			buLat2EndCsr():	:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:		,:		,:			dum4:		:			:			:			:		:			:			:		:	"		//	single separator needs ',' 

	// TabGroups...: Some untabbed  1dim..3dim controls
	n += 1;	tPn[ n ] =	"CB:	   1:	0:	8:	1:	°:		,:		1,°:			cbResTB:		Results:		:			fResultTxtbox():	:		:			~1:			:		:	"		// 	1-dim  checkbox(1 row)
//	n += 1;	tPn[ n ] =	"CB:	   0:	2:	8:	1:	°:		,:		1,:			cbSmeTm:		Same Time:	:			fSameTime():	:		:			:			:		:	"		// 	1-dim  popmenu (1 row)
	n += 1;	tPn[ n ] =	"RAD: 0:	4:	8:	0:	°:		,:		1,°:			raStVal:		:			InitV,Fit,:		fStartVa_():	:		:			0001_1;~0:	:		:	"		//	1-dim horz radios
	n += 1;	tPn[ n ] =	"SV:    0:	6:	8:	1:	°:		,:		1,:			gFitMaxIter:	MaxIter:		:			:	  		42:		%3d; 10,999,1:	0000_50:		:		:	"

 
	n += 1;	tPn[ n ] =	"CB:	   1:	0:	3:	0:	°:		,:		1,°:			gbDispSkip:	Disp skipped:	:			fDispSkipped():	:		:			:			:		:	"		// 	1-dim  checkbox(1 row)
	n += 1;	tPn[ n ] =	"PM:	   0:	1:	3:	0:	°:		,:		,:			pmAutoSel:	:			AutoSel:		fAutoSelect():	72:		fAutoSelectLst():	:			:		:	"		// 	1-dim  popmenu (1 row)
	n += 1;	tPn[ n ] =	"PM:	   0:	2:	3:	0:	°:		,:		,:			pmPrRes:		:			Print:			fPrintReslts():	72:		fPrintResltsLst():	:			:		:	"		// 	1-dim  popmenu (1 row)

//	n += 1;	tPn[ n ] =	"CB:	   0:	1:	3:	0:	°:		,:		1,°:			cbDispCsr:		Disp Cursors:	:			fDispCurs():	:		:			;~1:			:		:	"		// 	1-dim  checkbox(1 row)

	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:		,:		1,:			dum6a:		   Averages:	:			:			:		:			:			:		:	"		//	single separator needs ','
//	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:		,:		,°:			dum6a:		:			:			:			:		:			:			:		:	"		//	single separator needs ','
//	n += 1;	tPn[ n ] =	"SV:    1:	0:	3:	0:	°:		,:		1,:			gAvgKeepCnt:	# Averaged:	:			:	  		40:		%4d; 0,0,0:	:			:		:	"
//	n += 1;	tPn[ n ] =	"STR:  0:	1:	3:	1:	°:		,:		1,°:			gsAvgNm:		Avg:			:			fAvgNm_():	210:		:			:			:		:	"		//  	single  SetVariable inputing a String
	n += 1;	tPn[ n ] =	"SV:    1:	0:	4:	0:	°:		,:		1,:			gAvgKeepCnt:	# Aver'd:		:			:	  		30:		%4d; 0,0,0:	:			:		:	"
	n += 1;	tPn[ n ] =	"STR:  0:	1:	4:	2:	°:		,:		1,°:			gsAvgNm:		 Avg:			:			fAvgNm_():	236:		:			:			:		:	"		//  	single  SetVariable inputing a String
	n += 1;	tPn[ n ] =	"CB:	   1:	0:	8:	1:	°:		,:		1,°:			gbDispAvg:	Disp average:	:			fDispAvg():	:		:			:			:		:	"		// 	1-dim  checkbox(1 row)
	n += 1;	tPn[ n ] =	"BU:    0:	2:	8:	0:	°:		,:		1,°:			buEraseAvg:	Erase:		:			fEraseAvg_():	:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	3:	8:	0:	°:		,:		1,°:			buSaveAvg:	save:		:			fSaveAvg_():	:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"SV:    0:	4:	8:	1:	°:		,:		1,:			svMovAvg:	 MovAv:		:			fMovAvg_():	48:		%3d; 2,10000,1:	~5:			:		:	"

	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:		,:		,°:			dum6d:		:			:			:			:		:			:			:		:	"		//	single separator needs ','
	n += 1;	tPn[ n ] =	"SV:    1:	0:	4:	0:	°:		,:		1,:			gEvaluatCnt:	# Eval'd:		:			:	  		30:		%4d; 0,0,0:	:			:		:	"		//	single SetVariable
	n += 1;	tPn[ n ] =	"STR:  0:	1:	4:	2:	°:		,:		1,°:			gsTblNm:		 Tbl:			:			:			236:		:			:			:		:	"		//  	single  SetVariable inputing a String
	n += 1;	tPn[ n ] =	"CB:	   1:	0:	4:	0:	°:		,:		1,°:			gbDispTbl:		disp table:		:			fDispTbl_():		:		:			:			:		:	"		// 	single checkbox
	n += 1;	tPn[ n ] =	"BU:    0:	1:	4:	0:	°:		,:		1,°:			buResetTbl:	reset tbl:		:			fResetTbl_():	:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	2:	4:	0:	°:		,:		1,°:			buSaveTbl:	save tbl:		:			fSaveTbl_():	:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	3:	4:	0:	°:		,:		1,°:			buConvTbl:	conv tbl > XY:	:			fConvTbl_():	:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"CB:    1:	0:	4:	0:	°:		,:		1,°:			cbResSelDr:	draw selection:	:			fResSelectDraw():	:	:			:			:		:	"		//	single checkbox
	n += 1;	tPn[ n ] =	"BU:    0:	1:	4:	0:	°:		,:		1,°:			buClrRSelDr:	clear draw sel:	:			fClearResSelDraw_():	:	:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"CB:    0:	2:	4:	0:	°:		,:		1,°:			cbResSelTb:	table selection:	:			fResSelectTable():	:		:			:			:		:	"		//	single checkbox
	n += 1;	tPn[ n ] =	"BU:    0:	3:	4:	0:	°:		,:		1,°:			buClrRSelTb:	clear table sel:	:			fClearResSelTable_():	:	:			:			:		:	"		//	single button

	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:		,:		,°:			dum6j:		:			:			:			:		:			:			:		:	"		//	single separator needs ','
//	n += 1;	tPn[ n ] =	"BU:    1:	0:	3:	0:	°:		,:		1,°:			buResActCol:	Reset Column:	:			fResActColumn()::		:			:			:		:	"		//	single button
//	n += 1;	tPn[ n ] =	"BU:    1:	0:	3:	0:	°:		,:		1,°:			buClearWindow:ClearWindow:	:			fClearWindow():	:		:			:			:		:	"		//	single button

	// Script and stimulus reconstruction
//	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:		,:		,:			dum7a:		Script and stimulus reconstruction:	:	:	:		:			:			:		:	"		//	single separator needs ','  for 'Blks'  and 'dummy' for 'Name'
//	n += 1;	tPn[ n ] =	"BU:    1:	0:	3:	0:	°:		,:		1,°:			buEvStimDlg:	Display stimulus:	:			fEvStimDlg():	:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"CB:	   1:	0:	5:	0:	°:		,:		1,°:			gbShwScr:	Script:		:			fShowScript_():	:		:			:			:		:	"		// 	1-dim  popmenu (1 row)
	n += 1;	tPn[ n ] =	"RAD: 0:	1:	5:	0:	°:		,:		1,°:			raCfsHeadr:	:			fCfsHeaderLst():	fCfsHeader():	:		:			0000_1;~0:	:		:	"		//	1-dim horz radios
	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:		,:		,°:			dum7c:		:			:			:			:		:			:			:		:	"		//	single separator needs ','

//	// Saving and recalling panel settings
//	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:		,:		,:			dum8a:		Save and recall settings:	:	:			:		:			:			:		:	"		//	single separator needs ','  for 'Blks'  and 'dummy' for 'Name'
//	n += 1;	tPn[ n ] =	"STR:  1:	0:	4:	1:	°:		,:		1,°:			svSave:		Save:		:			fSaveSets():	120:		:			:			:		:	"		//  	single  SetVariable inputing a String
//	n += 1;	tPn[ n ] =	"PM:	   0:	2:	4:	1:	°:		,:		1,°:			pmRecal:		:			Recall:		fRecallSets():	120:		fRecallSetsLst():	:			:		:	"		// 	1-dim  popmenu (1 row)
//	n += 1;	tPn[ n ] =	"BU:    1:	0:	4:	0:	°:		,:		1,°:			buDeflt:		Defaults:		:			fDefaults():		:		:			:			:		:	"		//	single button
//	n += 1;	tPn[ n ] =	"CB:	   0:	1:	4:	1:	°:		,:		1,°:			cbAlDel:		Allow delete:	:			fCbAllowDelete()::		:			:			:		:	"		// 	1-dim  popmenu (1 row)
//	n += 1;	tPn[ n ] =	"PM:	   0:	2:	4:	1:	°:		,:		1,°:			pmDelet:		Delete:		:			fDeleteSets():	120:		fRecallSetsLst():	:			:		:	"		// 	1-dim  popmenu (1 row)
//	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:		,:		,:			dum8e:		More panels and options:	:	:			:		:			:			:		:	"		//	single separator needs ','  for 'Blks'  and 'dummy' for 'Name'
	n += 1;	tPn[ n ] =	"BU:    1:	0:	4:	0:	°:		,:		1,°:			buPreferDlg:	Pn Preferences:	:			fEvPreferDlg():	:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	1:	4:	0:	°:		,:		1,°:			buDatUtlDlg:	Pn Data utilities:	:			fEvDataUtilDlg()::		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	2:	4:	0:	°:		,:		1,°:			buEvStimDlg:	Pn Stimulus:	:			fEvStimDlg():	:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	3:	4:	0:	°:		,:		1,°:			buSettings:	Pn Settings:	:			fSettingsDlg():	:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    1:	0:	4:	0:	°:		,:		1,°:			buHelp:		Help:			:			fEvHelp_():	:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"BU:    0:	1:	4:	0:	°:		,:		1,°:			buMovieDlg:	Movies:		:			fEvMoviesDlg_()::		:			:			:		Movies panel:"
	n += 1;	tPn[ n ] =	"BU:    0:	3:	4:	0:	°:		,:		1,°:			buDat2Old:	Conv Dat2Old:	:			fEvDat2Old():	:		:			:			:		:	"		//	single button
	if ( n >= nItems )
		DeveloperError( "Wave in panel " + sPnOptions + " needs more (at least " + num2str( n+1 )  + " ) elements. " )
	endif

	redimension  /N = ( n+1)	tPn
End

Function		fEvDat2Old( s )
	struct	WMButtonAction	&s
//	if (  s.eventCode != kCCE_idle  &&  s.eventCode != kCCE_mousemoved  &&  s.eventCode != kCCE_leave  &&  s.eventCode != kCCE_enter  &&  s.eventCode != kCCE_mouseup ) 
	if (  s.eventCode == kCCE_mouseup ) 
		ConvertDatToOld_()
	endif
End


//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function	/S	CfsRdDataPath()
	svar		sPath	= root:uf:evo:de:gsReadDPath0000
	return	sPath
End

Function 		fDispMode( s )
// display  'stacked'  or  'catenated'
	struct	WMPopupAction	&s
	printf "\t%s : setting to %d  (single:1, stacked:2, catenated:3) \r", s.ctrlname, s.popnum
	fPopup_struct1( s )											// sets the global variable
	RedrawWindows()
End

Function		fDispModeLst( sControlNm, sFo, sWin )
	string		sControlNm, sFo, sWin
	PopupMenu	$sControlNm, win = $sWin,	 value = lstDISPMODE		// e.g. "single;stack;catenate;"
End


Function 		fDispSkipped( s )
// display or hide unselected traces (=data units)
	struct	WMCheckboxAction	&s
	RedrawWindows()
End

//--------------------------------------------------------------------------------------------------------------------------------------------

Function 		fDispAvg( s )
	struct	WMCheckboxAction	&s
	DSDisplayAvgAllChans()
End


Function		fEraseAvg_( s ) 
// Called when a button is pressed.  ALSO CALLED when moving the mouse over a button.  See  'fButtonProc_struct()'  on how to avoid this event.
	struct	WMButtonAction	&s
	if (  s.eventCode == kCCE_mouseup ) 
//	if (  s.eventCode != kCCE_idle  &&  s.eventCode != kCCE_mousemoved  &&  s.eventCode != kCCE_leave  &&  s.eventCode != kCCE_enter  &&  s.eventCode != kCCE_mouseup ) 
		print 		s.ctrlname
		DSEraseAvgAllChans_()
	endif
End

Function		fSaveAvg_( s )
// Called when a button is pressed.  ALSO CALLED when moving the mouse over a button.  See  'fButtonProc_struct()'  on how to avoid this event.
	struct	WMButtonAction	&s
	if (  s.eventCode == kCCE_mouseup ) 
//	if (  s.eventCode != kCCE_idle  &&  s.eventCode != kCCE_mousemoved  &&  s.eventCode != kCCE_leave  &&  s.eventCode != kCCE_enter  &&  s.eventCode != kCCE_mouseup ) 
		print 		s.ctrlname
		DSSaveAvgAllChans_()
	endif
End

Function		fMovAvg_( s )
	struct	WMSetvariableAction   &s
	variable	nSctCnt	= DataSectionCnt_( kWV_ORG_ ) 
	string  	sFoVar	= ReplaceString( "_", s.ctrlName, ":" )   		//  e.g. root_uf_evo_de_svMovAvg0000 -> root:uf:evo:de:svMovAvg0000
	nvar		nTmp	= $sFoVar	 							// set the global variable (which has already been constructed) for the setvariable..
	nTmp	= min( s.dVal, nSctCnt )								// ..clipping the VARIABLE will automatically clip the value displayed in the control
	 printf "\t\t\tfMovAvg(  %s    min( s.dVal:%.1lf , SctCnt:%d ) \t ->\t%s -> %.1lf \r", s.CtrlName, s.dVal, nSctCnt, sFoVar, nTmp
End


Function		fAvgNm_( s )
	struct	WMSetvariableAction    &s

// 	...............WITHOUT fSetvar_struct1( s )	
//	fSetvar_struct1( s )											// sets the global variable

	svar		gsAvgNm	= root:uf:evo:de:gsAvgNm0000					// If the user entered a file name including the index, then strip the index and..
	variable	nPathParts= ItemsInList( s.sVal, ":" )
	string  	sDriveDir	= RemoveEnding( RemoveListItem( nPathParts-1, s.sVal, ":" ), ":" )
	if ( ! FPDirectoryExists( sDriveDir ) )
		PossiblyCreatePath( sDriveDir )
	endif
	gsAvgNm	= ConstructNextResultFileNmA_( s.sVal, ksAVGEXT_ )			// ..search the next free avg file index and display it in the SetVariable input field
	// printf "%s   %s    ->  %s \r", s.CtrlName, s.sVal, gsAvgNm
End

Function		MovingAvg()
// Returns the number of traces to be averaged 
	nvar		nMovingAvg	= $"root:uf:evo:de:svMovAvg0000"			// same for all channels and regions
	// printf "\t\t\tMovingAvg( ch:%d, rg:%d ) returns: %d \t \r", nMovingAvg
	return	nMovingAvg
End


//--------------------------------------------------------------------------------------------------------------------------------------------

Function		EvaluationCnt( ch )
	variable	ch
	wave  /Z	wEvalTblCnt		= 	root:uf:evo:de:wEvalTblCnt
	return 	waveExists( wEvalTblCnt )  ?   wEvalTblCnt[ ch ]	:  SetEvaluationCnt( ch, 0 ) 
End

Function		SetEvaluationCnt( ch, cnt )
	variable	ch, cnt
	wave  /Z	wEvalTblCnt		= root:uf:evo:de:wEvalTblCnt			// 0 means start a new result file xxx_n.fit
	if ( ! waveExists( wEvalTblCnt ) )
		make /N=( kMAXCHANS )	   root:uf:evo:de:wEvalTblCnt
		wave  wEvalTblCnt		= root:uf:evo:de:wEvalTblCnt
	endif
	wEvalTblCnt[ ch ]	= cnt		
	nvar		gEvaluatCnt0		= root:uf:evo:de:gEvaluatCnt0000		// Update the SetVariable 'Tbl' counter in the main panel . Flaw: only channel 0 is displayed
	gEvaluatCnt0	= cnt
	return	cnt												// return something for the conditional assignment in  'EvaluationCnt()'  to work 
End


//Function		EvaluationCnt()
//	nvar		nEvaluationCnt	= root:uf:evo:de:gEvaluatCnt0000			// 0 means start a new result file xxx_n.fit
//	return	nEvaluationCnt
//End
//
//Function		SetEvaluationCnt( n )
//	variable	n
//	nvar		nEvaluationCnt	= root:uf:evo:de:gEvaluatCnt0000			// 0 means start a new result file xxx_n.fit
//	nEvaluationCnt	= n
//End


//--------------------------------------------------------------------------------------------------------------------------------------------


Function		DisplayTable()
	nvar		gbDispTbl	= root:uf:evo:de:gbDispTbl0000
	return	gbDispTbl
End

Function 		fDispTbl_( s )
	struct	WMCheckboxAction	&s
// 051111 Route results from original data and from averaged data into different waves, tables and files
	variable	nWvKind 		// kWV_ORG_	  or  kWV_AVG 
	string  	sTblNm
	for ( nWvKind = 0; nWvKind < kWV_KINDCNT_; nWvKind += 1 )
		sTblNm	= ResultTableNm_( kLB_SELECT, nWvKind )
		if ( WinType( sTblNm ) == kTABLE )						// the user may have forcefully closed the table by having pressed the window close button 5 times in fast succession
			if ( s.Checked )
				MoveWindow /W=$sTblNm	1, 1, 1, 1			// restore table from minimised to old size
			else
				MoveWindow /W=$sTblNm	0, 0, 0, 0			// minimise table (table killing must be and is prevented  by Edit /K=2)
			endif
		endif
	endfor
End

Function		fResetTbl_( s ) 
// Called when a button is pressed.  ALSO CALLED when moving the mouse over a button.  See  'fButtonProc_struct()'  on how to avoid this event.
	struct	WMButtonAction	&s
	if (  s.eventCode == kCCE_mouseup ) 
//	if (  s.eventCode != kCCE_idle  &&  s.eventCode != kCCE_mousemoved  &&  s.eventCode != kCCE_leave  &&  s.eventCode != kCCE_enter  &&  s.eventCode != kCCE_mouseup ) 
		// print 		s.ctrlname
		SaveTblFile_( kLB_SELECT, kWV_ORG_ )					// Save the table with an automatic name. The next save will not overwite this file as the next automatic name will be used.
		EraseTbl_(     kLB_SELECT, kWV_ORG_ )
		SaveTblFile_( kLB_SELECT, kWV_AVG_ )					// Save the table with an automatic name. The next save will not overwite this file as the next automatic name will be used.
		EraseTbl_(     kLB_SELECT, kWV_AVG_ )

		SaveTblFile_( kLB_ALL,	kWV_ORG_ )					// Save the table with an automatic name. The next save will not overwite this file as the next automatic name will be used.
		EraseTbl_(     kLB_ALL,	kWV_ORG_ )
		SaveTblFile_( kLB_ALL,	kWV_AVG_ )					// Save the table with an automatic name. The next save will not overwite this file as the next automatic name will be used.
		EraseTbl_(     kLB_ALL,	kWV_AVG_ )
		nvar		gChans	= root:uf:evo:cfsr:gChannels
		variable	ch
		for ( ch = 0; ch < gChans; ch += 1 )
			SetEvaluationCnt( ch, 0 )
		endfor
	endif
End

Function		fSaveTbl_( s )
// Called when a button is pressed.  ALSO CALLED when moving the mouse over a button.  See  'fButtonProc_struct()'  on how to avoid this event.
	struct	WMButtonAction	&s
	if (  s.eventCode == kCCE_mouseup ) 
//	if (  s.eventCode != kCCE_idle  &&  s.eventCode != kCCE_mousemoved  &&  s.eventCode != kCCE_leave  &&  s.eventCode != kCCE_enter  &&  s.eventCode != kCCE_mouseup ) 
		// print 		s.ctrlname
		SaveTblFile_( kLB_SELECT, kWV_ORG_ )			// Save the table with an automatic name. The next save will not overwite this file as the next automatic name will be used.
		SaveTblFile_( kLB_SELECT, kWV_AVG_ )			// Save the table with an automatic name. The next save will not overwite this file as the next automatic name will be used.
		SaveTblFile_( kLB_ALL,	 kWV_ORG_ )			// Save the table with an automatic name. The next save will not overwite this file as the next automatic name will be used.
		SaveTblFile_( kLB_ALL,	 kWV_AVG_ )			// Save the table with an automatic name. The next save will not overwite this file as the next automatic name will be used.
	endif
End

Function		fConvTbl_( s )
// Convert multidimensional (ch, rg, fit, type) wEval wave into single XY waves
// Called when a button is pressed.  ALSO CALLED when moving the mouse over a button.  See  'fButtonProc_struct()'  on how to avoid this event.
	struct	WMButtonAction	&s
	if (  s.eventCode == kCCE_mouseup ) 
//	if (  s.eventCode != kCCE_idle  &&  s.eventCode != kCCE_mousemoved  &&  s.eventCode != kCCE_leave  &&  s.eventCode != kCCE_enter  &&  s.eventCode != kCCE_mouseup ) 
		 print 		s.ctrlname
		ConvTbl_( kLB_SELECT, kWV_ORG_ )				// Convert multidimensional (ch, rg, fit, type)  original   	wEval wave into single XY waves
		ConvTbl_( kLB_SELECT, kWV_AVG_ )				// Convert multidimensional (ch, rg, fit, type)  averaged	wEval wave into single XY waves
	endif
End

// 060216..............
Function 		fHookResults_( s )
// This code defines the user interface : Basically - What actions are taken in response to mouse clicks in the Results table.
// Possible actions (not yet implemented) : delete result line
// Any changes here must also be documented in 'EvalHelp.txt' 
	struct	WMWinHookStruct &s

	variable	row = inf, col = inf
	string  	sNBText = ""

	// GetTableRowCol( s, row, col )
	// printf "\tfHookResults()\t%s\tmX:%4d\tcol: %4d  \tmY:%4d\tROW: %4d  \tE:%2d\t%s   \tMod:%4d\tkey:%4d \r", s.winName, s.mouseLoc.h, col, s.mouseLoc.v, row, s.eventCode, pd( StringFromList( s.eventCode, lstWINHOOKCODES ), 8 ),  s.eventMod, s.keycode

	if (  s.eventCode != kWHK_mousemoved ) 
		 GetTableRowCol( s, row, col )

		// This is the main debug print line
		 // printf "\tfHookResults()\t%s\tmX:%4d\tcol: %4d  \tmY:%4d\tROW: %4d  \tE:%2d\t%s   \tMod:%4d\tkey:%4d \r", s.winName, s.mouseLoc.h, col, s.mouseLoc.v, row, s.eventCode, pd(  s.eventName, 8 ),  s.eventMod, s.keycode

		// Open a context menu on a right mouse click.....
		if (  s.eventCode == kWHK_mousedown   &&   s.eventMod == 16 )   		// right mouse  (mouseUp does not work in this context)
	
			GetTableRowCol( s, row, col )
			printf "\tfHookResults()\t%s\tmX:%4d\tcol: %4d  \tmY:%4d\tROW: %4d  \tE:%2d\t%s   \tMod:%4d\tkey:%4d \r", s.winName, s.mouseLoc.h, col, s.mouseLoc.v, row, s.eventCode, pd( s.eventName, 8 ),  s.eventMod, s.keycode

			if ( row == -1  ||  row == - 2 )					// Clicked into the column header 
				PopupContextualMenu/C=( s.mouseLoc.h, s.mouseLoc.v ) "Cnt and Mean excluding nan;---;Cnt and Mean including nan as 0;"
		
				strswitch( S_selection )
		
					case "Cnt and Mean excluding nan" :
						PrintColumnMean_( s.WinName, "->  Cnt and Mean excluding nan   \t", 0 )
						break;
					case "---" :
						break;
					case "Cnt and Mean including nan as 0" :
						PrintColumnMean_( s.WinName, "->  Cnt and Mean including nan as 0\t", 1 )
						break;
				endswitch
				return	1				// 0 : allow Igor to do further processing (will open Igor's context menu) 
			endif
		endif


		if (  s.eventCode == kWHK_mouseup  &&  ! ( s.eventMod & 2 ) &&  ! ( s.eventMod & 4 ) &&  ! ( s.eventMod & 8 )  ) 		// we use MouseUp as MouseDown is missing sometimes (e.g. when having been in a different *overlapping* window)
			GetTableRowCol( s, row, col )
			//printf "\tfHookResults()\t%s\tmX:%4d\tcol: %4d  \tmY:%4d\tROW: %4d  \tE:%2d\t%s   \tMod:%4d\tkey:%4d \r", s.winName, s.mouseLoc.h, col, s.mouseLoc.v, row, s.eventCode, pd( s.eventName, 8 ),  s.eventMod, s.keycode

//			if ( row == -1  ||  row == - 2 )					// Clicked into the column header 
//				printf "\t\tfHookResults() \tAveraging  column: %d ( Clicked row: %d ) \r", col, row	
//			endif
//			return	0

		endif	
	
//		if ( ( s.eventCode == kWHK_mouseup  || s.eventCode == kWHK_mousedown ) &&  ! ( s.eventMod & 2 ) &&  ! ( s.eventMod & 4 ) &&  ! ( s.eventMod & 8 )  ) // we use MouseUp as MouseDown is missing sometimes (e.g. when having been in a different *overlapping* window)
//
//			GetTableRowCol( s, row, col )
//			//printf "\tfHookResults()\t%s\tmX:%4d\tcol: %4d  \tmY:%4d\tROW: %4d  \tE:%2d\t%s   \tMod:%4d\tkey:%4d \r", s.winName, s.mouseLoc.h, col, s.mouseLoc.v, row, s.eventCode, pd( s.eventName, 8 ),  s.eventMod, s.keycode
//	
//			//  Clicked into  'Name'  column in Recipe data base : Open the  recipe  from the data base  (final form)  for editing
//			if ( col == kR_TITLE  &&  0 <= row   &&  row < nMaxRows )		
//				printf "\t\tfHookResults() \tEditing row: %d ( Clicked col: %d )  \r", row, col	
//				ConstructOrUpdateRecDBNotebook( wtRec, ksF_DOC, ":script" , ksNB_WNDNAME, row, kQUAL_FINAL )	
//			endif

//			//  Clicked into  'Character'  column in Recipe data base : Print recipe header in history window 
//			if ( col == kR_CHAR  &&    0 <= row   &&  row < nMaxRows )			
//				printf "\t\tfHookResults() \tPrint header into history.  \tRow: %d ( Clicked col: %d )  \r", row, col	
//				PrintRecipeHeaderIntoHistory( wtRec, row )	
//			endif
//			return	0
//		endif	
//
////		if (  s.eventCode == kWHK_mouseup  &&  ! ( s.eventMod & 4 )  &&  ( s.eventMod & 8 )  ) 			//  Shift:2 , Alt:4, Ctrl:8    we use MouseUp as MouseDown is missing sometimes (e.g. when having been in a different *overlapping* window)
//		if (  s.eventCode == kWHK_mousedown  &&  ! ( s.eventMod & 4 )  &&  ( s.eventMod & 8 )  ) 			//  Shift:2 , Alt:4, Ctrl:8   MouseDown is sometimes  missing...??? 
//
//			GetTableRowCol( s, row, col )
//			printf "\tfHookResults()\t%s\tmX:%4d\tcol: %4d  \tmY:%4d\tROW: %4d  \tE:%2d\t%s   \tMod:%4d\tkey:%4d \r", s.winName, s.mouseLoc.h, col, s.mouseLoc.v, row, s.eventCode, pd( s.eventName, 8 ),  s.eventMod, s.keycode
//
//			// Control clicked  int  'Row'  column : Delete this recipe in data base
////			printf "\tfHookResults()\t%s\tmX:%4d\tcol: %4d  \tmY:%4d\tROW: %4d  \tE:%2d\t%s   \tMod:%4d\tkey:%4d \r", s.winName, s.mouseLoc.h, col, s.mouseLoc.v, row, s.eventCode, pd( s.eventName, 8 ),  s.eventMod, s.keycode
//			if ( col == -1 &&  row >= 0  &&  row < nMaxRows )
//				DoWindow /K	$ksNB_WNDNAME
//				DeleteDatabaseEntry( ksF_DOC_ , ksREC_DBNM , row  )
//			endif
//			return	0
//		endif
	endif	
	
	return	0
End


Function		PrintColumnMean_( sWin, sInfo, bIncludeNanAsZero )
	string  	sWin, sInfo
	variable	bIncludeNanAsZero
	
	string  	sTblInfo, sWvNm
	sTblInfo	= tableinfo( sWin, 0 )
	sWvNm	= StringByKey( "WAVE" , sTblInfo ) 
	sTblInfo	= tableinfo( sWin, -2 )
	//print "sTblInfo", sTblInfo
	variable	nFirstRow	= str2num( StringFromList( 0, StringByKey( "SELECTION" , sTblInfo ) , "," ) )	
	variable	nFirstCol	= str2num( StringFromList( 1, StringByKey( "SELECTION" , sTblInfo ) , "," ) )	
	variable	nLastRow	= str2num( StringFromList( 2, StringByKey( "SELECTION" , sTblInfo ) , "," ) )	
	wave /T wv = $sWvNm
	variable nRow, MeanVal = 0, Val, cnt = 0
	for ( nRow = nFirstRow; nRow <= nLastRow; nRow += 1 )
		Val		= str2num(wv[nRow ][ nFirstCol ])
		if ( numType( Val ) == kNUMTYPE_NAN )
			if ( bIncludeNanAsZero )
				cnt += 1
			endif
		else
			MeanVal += Val
			cnt += 1
		endif
		//print cnt, wv[ nRow ][ nFirstCol ]
	endfor
	MeanVal	 /= cnt
	printf "\t%s\t[%s]\trow:%3d ... %3d \tcol:%3d  [Count:%3d]  Mean: %g  \r", sInfo, sWin, nFirstRow, nLastRow, nFirstCol, cnt, MeanVal 
	return	0
End




// should go into MISC.ipf
static Function		GetTableRowCol( s, r, c )
// Computes from mouse position and table coordinates which cell has been clicked. The  'TableInfo' string returns directly the selected cell but only if...
// ..it is a true inner table cell. The  'TableInfo' string does not return info about outer cells ('Row' column and the 2 headlines) which we are especially interested in...
	struct	WMWinHookStruct &s
	variable	&r, &c
//	print  	TableInfo( s.WinName, -2 ) ; print "\r"
//	print  	TableInfo( s.WinName, -1 );  print "\r"
//	print  	TableInfo( s.WinName, 0 );   print "\r"
//	print  	TableInfo( s.WinName, 1 );   print "\r"
	string  	sTblInfo	= TableInfo( s.WinName, -2 )
	variable	nFirstRow	= str2num( StringFromList( 0, StringByKey( "FIRSTCELL" , sTblInfo ) , "," ) )	
	variable	nFirstCol	= str2num( StringFromList( 1, StringByKey( "FIRSTCELL" , sTblInfo ) , "," ) )	
	variable	nTgtRow	= str2num( StringFromList( 0, StringByKey( "TARGETCELL" , sTblInfo ) , "," ) )	
	variable	nTgtCol	= str2num( StringFromList( 1, StringByKey( "TARGETCELL" , sTblInfo ) , "," ) )	
	variable	xp 	 	= NumberByKey( "WIDTH" , 	TableInfo( s.WinName, -1 ) )				// the width of the 1. column (= the 'row' column having the index -1 )
	variable	nCols	= NumberByKey( "COLUMNS" ,	TableInfo( s.WinName,  0 ) )	
	variable	nRows	= NumberByKey( "ROWS" ,	TableInfo( s.WinName, -2 ) )	
	string  	sColOutOfRange = "", sRowOutOfRange = ""


                GetSelection table, $s.WinName, 1    //Gets the selection I made on this table               
                variable PointLocation = V_startRow                      //record the cell of interest.
 
	// print "GetTableRowCol() row from tableinfo ", nTgtRow, "   and from GetSelection : ", V_startRow, "   and from s.row : " // , s.row
	// print s
	if (  s.mouseLoc.h <= xp * screenresolution / kIGOR_POINTS72  )//||  c >= nCols )
		c	= -1
		sColOutOfRange	= "> C: 'Row'\t"
	else
		c 	= nFirstCol
		do
			// Cave: Although multiple unused right columns are drawn by Igor they cannot get selected. Igor allows only to select the first unused column.
			xp 	+=   NumberByKey( "WIDTH" , 	TableInfo( s.WinName, c ) )	
			if ( s.mouseLoc.h <= xp * screenresolution / kIGOR_POINTS72  ||  c >=  nCols )		//  allow and monitor clicking into unused right columns 
				sColOutOfRange	= SelectString( c >= nCols , " \t\t" , "> C: unused" )
				break
			endif
			c	+= 1
		while ( TRUE )
	endif
	
	 variable	kTBL_ROWHEIGHT		= 22				// Unfortunately this depends on screen resolution, empirical values are 20 for 1280x1024, 22 for 1600x1200 . 
												// Perhaps it depends on font size, perhaps it can be retrieved somehow.
//	r	= trunc( s.mouseLoc.v / kTBL_ROWHEIGHT )
//	if (  r < 3 )
//		sRowOutOfRange	= "> R: Header\t"
//		r	= r - 3
//	else
//		sRowOutOfRange	=  " \t \t"
//		r	= r - 3 + nFirstRow
//	endif
	if ( nTgtRow == 0 )								// this can be the true row 0 or one of the 2 header lines
		r	= trunc( s.mouseLoc.v / kTBL_ROWHEIGHT ) - 3	// Inspite of the uncertainty in  kTBL_ROWHEIGHT it is precise enough to discriminate between the 3 lines on top
		sRowOutOfRange	= "> R: Header\t"
	else
		r	= nTgtRow				// ??? TARGETROW is computes delayed when the window is entered. Incorrect at the 1., works only at the 2. mouse action
		sRowOutOfRange	=  " \t \t"
variable rowByMouse = trunc( s.mouseLoc.v / kTBL_ROWHEIGHT ) - 3 + nFirstRow
	endif
	
	// print	TableInfo( s.WinName, -2 )	
	// print	TableInfo( s.WinName, -1 )	
	// print	TableInfo( s.WinName,  0 )	
	string  	sEvTxt = pad( s.eventName, 8 )
	//  printf "\t\txp:%4d\txSc:%4d\t >? xmo:%4d\tnCols:%3d\tc1:%d\tc:%3d\t[=%2d]\t%s\tyMouse:%4d\tnRows:%4d \tr1: %3d\tr:%3d\t[=%2d]\tOldRbM:%4d\t%s\tE:%2d\t%s\tMod:%4d\tkey:%4d \t \r", xp, xp * screenresolution / kIGOR_POINTS72, s.mouseLoc.h, nCols, nFirstCol, c, nTgtCol, sColOutOfRange, s.MouseLoc.v, nRows, nFirstRow, r, nTgtRow,rowByMouse,sRowOutOfRange, s.eventCode,sEvTxt, s.eventMod, s.keycode
End
// ............060216 




Function 		fClearWindow( s )
// Only for testing.  Normally traces are cleared  ONLY  by  resetting them in the listbox as only then the correspondence between traces in listbox / on screen / analysed  is maintained. 
	struct	WMButtonAction	&s
	if (  s.eventCode == kCCE_mouseup ) 
		ClearWindows()
	endif
End


Function	/S	LstChan( sBaseNm, sFo, sWin )
	string		sBaseNm, sFo, sWin
	nvar		gChans	= root:uf:evo:cfsr:gChannels
	variable	ch
	string  	lstChans	= ""
	for ( ch = 0; ch < gChans; ch += 1 )
		lstChans	+= CfsIONm_( ch ) + ksSEP_TAB
	endfor
	return	lstChans
End	
	
Function	/S	LstReg( sBaseNm, sFo, sWin )
	string		sBaseNm, sFo, sWin
// Builds a region list consisting entirely of channel and region separators. From this list the number of regions in each channel can easily be derived.
	string  	lstRegs		= ""
	string  	lstChans		= LstChan( "", "", "" )
	variable	r, ch, nChans	= ItemsInList( lstChans, ksSEP_TAB )
	for ( ch = 0; ch < nChans; ch += 1 )
		variable	nRegs	= RegionCnt( ch )
		for ( r = 0; r < nRegs; r += 1 )
			lstRegs	   +=  ksSEP_STD  				//	the block prefix for the title may be empty only containing separators (to determine the number of regions/blocks)
		endfor
		lstRegs	   +=  ksSEP_TAB
	endfor
	// printf "\t\t\t\tLstReg():\t'%s'  \r", lstRegs
	return	lstRegs
End

Function		root_uf_evo_de_tc1( s )
// Special tabcontrol action procedure. Called through	fTabControl3( s ) and  fTcPrc( s ).  This function name is derived from 'PnBuildFoTabcoNm()' 
// 051110  Clicking  on a tab activates the corresponding graph window
	struct	WMTabControlAction   &s
	DoWindow  /F   $EvalWndNm( s.tab )						// Bring eval window corresponding to the tab-clicked channel to front and make it the active window 
	// printf "\t\troot_uf_evo_de_tc1() \r"
End



//   The Y-axis limit control implemented as a popupmenu.  Disadvantage:  The control cannot be updated with arbitrary values resulting from setting  Y Expand  Shrink  Up  Down . For this reason a Setvariable is chosen.
//	Function		fYAxisPM( s )
//		struct	WMPopupAction	&s
//		fPopup_struct1( s )											// sets the global variable
//		string  	sPath	= ksEVOCFG_DIR 							// e.g.  'C:Epc:Data:EvalCfg:'   or   'C:UserIgor:Ced:'  , must contain drive letter
//		string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
//		string  	sFo	 	= GetUserData( 	s.win,  s.ctrlName,  "sFo" )			// e.g.  'root:uf:evo:' 
//		string  	sSubDir	= ReplaceString( "root:uf:", sFo, "" )		  		// e.g.  'root:uf:evo:' -> 'evo:'
//	
//		string		sFolderWave	= "root:uf:evo:evl:wChanOpts"
//		wave	wWave		= $sFolderWave						// ASSUMPTION: wave name MUST NOT contain underscores 
//		variable	ch			= TabIdx( s.ctrlName )
//		string		sWNm		= CfsWndNm( ch )
//		variable	typ	= RowIdx( s.ctrlName ) 
//		if ( typ == 0 )
//			 typ	= 3		// 3 is Yax max/top control.
//		elseif ( typ == 1 )
//			typ = 2		// 2 is Yax min/bott control.  		Old: +2 obsolete  to skip 'OnOff;RgCnt;'  in  "OnOff;RgCnt;YAxMin;YAxMax;"
//		endif
//		wWave[ ch ][ typ ]= s.popnum-1
//	
//		GetAxis	/Q	/W=$sWNm  left
//		variable	yBott	= typ == 2 ? str2num(  s.popStr ) : V_min			// also the global variable is set e.g. for ch 0 :	$"root:uf:evo:de:pmYAxis0010"
//		variable	yTop	= typ == 3 ? str2num(  s.popStr ) : V_max			// also the global variable is set e.g. for ch 1 :	$"root:uf:evo:de:pmYAxis1000"
//		SetAxis	/W=$sWNm  left, yBott, yTop		// change the graph immediately. Without this line the change would come into effect only later on the next  RescaleAxisX()
//	
//		  printf "\t%s\t%s\t%s\tAdapted:\tch:%d\tty:%d\t%s\t%s\t%g\tyBot: %g\tyTop: %g\t  \r",  pd(sProcNm,15), pd(s.CtrlName,31), sWNm, ch, typ, pd( s.popStr,9), pd(sFolderWave,23), wWave[ ch ][ typ ], yBott, yTop
//	End
//	
//	Function		fYaxisLstPM( sControlNm, sFo, sWin )
//		string		sControlNm, sFo, sWin
//		PopupMenu	$sControlNm, win = $sWin,	 value = ksYAXIS_
//	End
//	
//	Function	/S	fYaxisInitPM()
//		return "0000_4;0010_16;1000_3;1010_15;"	// Syntax: tab blk row col 1-based-index; ...
//	End


Function		fYAxis( s )
// Change the Y-axis limits according to the users entries in the input field. Also adjust  wMagn[ ch ][ cYEXP ]  and  wMagn[ ch ][ cYSHIFT ]	
// RescaleAxisY()   and   fYAxis()  are interdependent  and must be changed together
	struct	WMSetvariableAction    &s
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	variable	ch		= TabIdx( s.ctrlName )
	variable	typ		= RowIdx( s.ctrlName ) 
	string		sWNm	= CfsWndNm( ch )
	if ( typ == 0 )
		 typ	= 3		// 3 is Yax max/top control.
	elseif ( typ == 1 )
		typ = 2		// 2 is Yax min/bott control.  		Old: +2 obsolete  to skip 'OnOff;RgCnt;'  in  "OnOff;RgCnt;YAxMin;YAxMax;"
	endif

	GetAxis	/Q	/W=$sWNm  left
	variable	yBott	= typ == 2 ? s.dVal : V_min			// also the global variable is set e.g. for ch 0 :	$"root:uf:evo:de:svYAxis0010"
	variable	yTop	= typ == 3 ? s.dVal : V_max			// also the global variable is set e.g. for ch 1 :	$"root:uf:evo:de:svYAxis1000"

	RescaleClipSetAxisY( ch,  yBott, yTop, sWNm )	// sets and possibly clips 'wMagn[ ch ][ cYSHIFT ]'

	// printf "\t%s\t%s\t%s\tch:%d\tty:%d\t%g\tyBot: %g\tyTop: %g\t  \r",  pd(sProcNm,15), pd(s.CtrlName,31), sWNm, ch, typ, s.dVal, yBott, yTop
	 // printf "\t\t\tfYAxis()\t\tch:%2d \tty:%d\t val: %g \t bott:\t%g\ttop: %g\t->YEXP: %g \t YSHIFT: %g \r", ch, typ, s.dVal, yBott, yTop, wMagn[ ch ][ cYEXP ], wMagn[ ch ][ cYSHIFT ]
End

Function	/S	fYaxisInit( sBaseNm, sFo, sWin )
// callled via 'fPopupListProc3()'
	string		sBaseNm, sFo, sWin
	return "0000_100;0010_-300;"					// Syntax: tab blk row col _ value
End


Function		fXAxis( s )
// Change the X-axis limits according to the users entries in the input field. Also adjust  wMagn[ ch ][ cXEXP ]  and  wMagn[ ch ][ cXSHIFT ]	
// RescaleAxisX()   and   fXAxis()  are interdependent  and must be changed together
	struct	WMSetvariableAction    &s
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	variable	ch		= TabIdx( s.ctrlName )
	variable	typ		= ColIdx( s.ctrlName ) 					// 0 means the minimum value and 1 means the maximum value
	string		sWNm	= CfsWndNm( ch )
	//  printf "\t%s\t\t\t\t\t%s\tch:%d\tty:%d\t%s\t%s\t%g\t  \r",  pd(sProcNm,13), s.CtrlName, ch, typ, pd( s.popStr,9), pd(sFolderWave,23), wWave[ ch ][ typ ]
	 //  printf "\t%s\t%s\t%s\tch:%2d\tty:%2d\t%.2lf\t  \r",   pd(sProcNm,15), pd(s.CtrlName,31), sWNm, ch, typ,  s.dval
	GetAxis	/Q	/W=$sWNm  bottom
	variable	xLeft	     =	typ == 0 ? s.dVal : V_min				// also the global variable is set e.g. for ch 0 :	$"root:uf:evo:de:svXAxis0000"
	variable	xRight    =	typ == 1 ? s.dVal : V_max				// also the global variable is set e.g. for ch 1 :	$"root:uf:evo:de:svXAxis1001"

	RescaleClipSetAxisX( ch, xLeft, xRight, sWNm )				// sets and possibly clips 'wMagn[ ch ][ cXSHIFT ]'
End


Function	/S	fXaxisInit( sBaseNm, sFo, sWin )
// callled via 'fPopupListProc3()'
	string		sBaseNm, sFo, sWin
//	return "0000_0;0001_500;1000_10;~1000;"	// Syntax: tab blk row col _ value
	return "0000_0;1000_1.5;"					// Syntax: tab blk row col _ value
End

Function		fAutoSclY( s )
// Checkbox action proc....
	struct	WMCheckboxAction	&s
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	 // printf "\t\t%s(s)\t\t%s\tb:%2d  =\t%d : from control \r",  sProcNm, pd(s.CtrlName,26), s.checked, PnValC( s.CtrlName )
	AutoSclY( s.checked )
End

Function		fSpreadCurs( s )
// Called when a button is pressed.  ALSO CALLED when moving the mouse over a button.  See  'fButtonProc_struct()'  on how to avoid this event.
	struct	WMButtonAction	&s
	if (  s.eventCode == kCCE_mouseup ) 
		string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
		variable	ch		= TabIdx( s.ctrlName )
		// printf "\t\t%s(s)\t\t%s\tch:%2d\ttime:%d\t \r",  sProcNm, pd(s.CtrlName,26), ch, mod( DateTime,10000)
		SpreadCursors( ch ) 
	endif
End

Function		fAutoSetCurs( s )
// Called when a button is pressed.  ALSO CALLED when moving the mouse over a button.  See  'fButtonProc_struct()'  on how to avoid this event.
	struct	WMButtonAction	&s
	if (  s.eventCode == kCCE_mouseup ) 
		string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
		variable	ch		= TabIdx( s.ctrlName )
		 printf "\t\t%s(s)\t\t%s\tch:%2d\ttime:%d\t \r",  sProcNm, pd(s.CtrlName,26), ch, mod( DateTime,10000)
		AutoSetCursors( ch ) 
	endif
End

Function		fRescale( s ) 
// Called when a button is pressed.  ALSO CALLED when moving the mouse over a button.  See  'fButtonProc_struct()'  on how to avoid this event.
	struct	WMButtonAction	&s
	if (  s.eventCode == kCCE_mouseup ) 
		string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
		variable	ch		= TabIdx( s.ctrlName )
		// printf "\t\t%s(s)\t\t%s\tch:%2d\ttime:%d\t \r",  sProcNm, pd(s.CtrlName,26), ch, mod( DateTime,10000)
		Rescale( ch )
	endif
End



//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function		fReg( s ) 
// Demo: this  SetVariable control  changes the number of blocks. Consequently the Panel must be rebuilt  OR  it must have a constant large size providing space for the maximum number of blocks.
	struct	WMSetvariableAction    &s
//	fSetvar_struct1( s )										// sets the global variable
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	variable	ch		= TabIdx( s.ctrlName )
	string  	lstRegs	= LstReg( "", "", "")
	  printf "\t%s\t\t\t\t\t%s\tvar:%g\t-> \tch:%d\tLstBlk3:\t%s\t  \r",  pd(sProcNm,13), pd(s.CtrlName,26), s.dval,ch, pd( lstRegs, 19)

	Panel3Main(   "de", "Evaluation Details3", "root:uf:" + ksfEVO_, 2, 95 ) // Compute the location of panel controls and the panel dimensions. Draw the panel displaying and hiding needed/unneeded controls
//	UpdateDependent_Of_AllowDelete( s.Win, "root_uf_evo_de_cbAlDel0000" )	
//	UpdateDependent_Of_AllowDelete( s.Win, "root_uf_evo_set_cbAlDel0000" )	

	DisplayCursors_Peak( ch )
	DisplayCursors_Base( ch )
	DisplayCursors_Lat( ch )
	DisplayCursors_UsedFit( ch )					// Display the used fit cursors and hide the unused fit cursors immediately depending on the state of the region and fit checkboxes to give the user a feedback which parts of the data will be fitted in the next analysis
	PanelRSUpdateDraw_()							// update the 'Select results' panel whose size has changed
	PanelRSUpdateTable_()							// update the 'Select results' panel whose size has changed
// 051018
	AllLatenciesCheck()		// If a region which has been turned off still contains a latency option this will be flagged as an error
End
	
//Function		fDispCurs( s )
//// Checkbox action proc....
//	struct	WMCheckboxAction	&s
//	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
//	  printf "\t\t%s(s)\t\t%s\tb:%2d  =\t%d : from control \r",  sProcNm, pd(s.CtrlName,26), s.checked, PnValC( s.CtrlName )
//	variable	ch
//	nvar		gChans		= root:uf:evo:cfsr:gChannels					
//	for ( ch = 0; ch < gChans; ch += 1 )
//		DisplayCursors_Base( ch )
//		DisplayCursors_Peak( ch )
//		DisplayCursors_Lat( ch )
//		DisplayCursors_UsedFit( ch )
//	endfor
//End

Function		DisplayCursors_Base( ch )
	variable	ch
	variable	rg
	for ( rg = 0; rg < kRG_MAX; rg += 1 )						
		DisplayCursor_Base( ch, rg )
	endfor
End

Function		DisplayCursor_Base( ch, rg )
	variable	ch, rg
	string		sWnd 	= CfsWndNm( ch )
	for ( rg = 0; rg < kRG_MAX; rg += 1 )	
		variable	bOn	=  rg < RegionCnt( ch )  &&  BaseOp( ch, rg ) != kBASE_OFF	// order is vital: check region first  and avoid so the evaluation of BaseOp() for unused regions which is illegal 
		DisplayHideCursors( ch, rg, PH_BASE, sWnd, bOn )					// Display the base cursors only if they are 'on'  and if their region is 'on'...
	endfor
End

Function		DisplayCursors_Peak( ch )
	variable	ch
	variable	rg
	for ( rg = 0; rg < kRG_MAX; rg += 1 )						
		DisplayCursor_Peak( ch, rg )
	endfor
End

Function		DisplayCursor_Peak( ch, rg )
	variable	ch, rg
	string		sWnd 	= CfsWndNm( ch )
	variable	bOn		= rg < RegionCnt( ch )  &&  PeakDir( ch, rg ) != kPEAK_OFF_	// order is vital: check region first  and avoid so the evaluation of PeakDir() for unused regions which is illegal 
	DisplayHideCursors( ch, rg, PH_PEAK, sWnd, bOn )						// Display the peak cursors only if the peak is up or down and if their region is on and hide them if the peak is off or the region is off
End	

Function		DisplayCursors_Lat( ch )
	variable	ch
	variable	rg, BegEnd, lc, LatCnt	= LatencyCnt()
	for ( lc = 0; lc < LatCnt; lc += 1 )
		for ( BegEnd= CN_BEG; BegEnd <=  CN_END; BegEnd += 1 )
			for ( rg = 0; rg < kRG_MAX; rg += 1 )						
				DisplayCursor_Lat( ch, rg, lc, BegEnd )										// will also hide cursors if checkbox control is off
			endfor
		endfor
	endfor
End

Function		DisplayCursor_Lat( ch, rg, lc, BegEnd )
	variable	ch, rg, lc, BegEnd
	string		sWnd 	= CfsWndNm( ch )
//	variable	bOn	=  rg < RegionCnt( ch )  &&  ( LatC( ch, rg, lc ) == kLAT_MANCSR  ||  LatC( ch, rg, lc ) == kLAT_E_MANCSR	 )	// order is vital: check region first  and avoid so the evaluation of LatCsr() for unused regions which is illegal
	variable	bOn	=  rg < RegionCnt( ch )  &&   LatC( ch, rg, lc, BegEnd) == kLAT_MANUAL_// order is vital: check region first  and avoid so the evaluation of LatCsr() for unused regions which is illegal
	DisplayHideCursor( ch, rg, PH_LATC0 + lc, BegEnd, sWnd, bOn )					  // will also hide cursors if checkbox control is off
End


Function		DisplayCursors_UsedFit( ch )
	// Display the used fit cursors and hide the unused fit cursors immediately depending on the state of the region and fit checkboxes to give the user a feedback which parts of the data will be fitted in the next analysis
	variable	ch
	variable	rg, fi, nFits
	string		sWnd 		= CfsWndNm( ch )
	for ( rg = 0; rg < kRG_MAX; rg += 1 )							
		nFits	= ItemsInList( ksPHASES ) - PH_FIT0
		for ( fi = 0; fi < nFits; fi += 1 )
			variable	bOn	= rg  < RegionCnt( ch )  &&  DoFit( ch, rg, fi )   		// order is vital: check region first  and avoid so the evaluation of DoFit() for unused regions which is illegal 
			DisplayHideCursors( ch, rg, fi + PH_FIT0, sWnd, bOn )				// Display only the used fit cursors,  hide the cursors if the fit is not user or if the region is off 
		endfor
	endfor
End


Function		RegionCnt( ch )
	variable	ch
	// string  	sCtrlNm  = "root_uf_evo_de_svReg" + num2str( ch ) + "000" // Version1: get value from ControlInfo which might be slow
	// ControlInfo /W= $"de" $sCtrlNm
	// variable	cnt	= V_Value	
	nvar		cnt	= $"root:uf:evo:de:svReg" + num2str( ch ) + "000"	 // Version2: get value from underlying variable which should be faster than getting it from the ControlInfo
	// printf "\t\t\tRegionCnt( ch:%d ) : %d \t \r", ch, cnt
	return	cnt
End


//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

static constant		kBASE_OFF = 0,  kBASE_ON = 1,  kBASE_NS_CHK_USERLIM = 2,  kBASE_NS_CHK_AUTOLIM = 3  
strconstant	klstBASE_	= "off;on;user noise check;auto noise check;"		//  Igor does not allow this to be static!  

Function		fBaseOpLst( sControlNm, sFo, sWin )
	string		sControlNm, sFo, sWin
	PopupMenu	$sControlNm, win = $sWin,	 value = klstBASE_
End

Function		fBaseOp( s )
	struct	WMPopupAction	&s
	fPopup_struct1( s )										// sets the global variable
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	string  	sFo	 	= GetUserData( 	s.win,  s.ctrlName,  "sFo" )		// e.g.  'root:uf:evo:' 
	string  	sSubDir	= ReplaceString( "root:uf:", sFo, "" )		  	// e.g.  'root:uf:evo:' -> 'evo:'

	variable	ch	= TabIdx( s.ctrlName )
	variable	rg	= BlkIdx( s.ctrlName )
	 printf "\t%s\t%s\tch:%d  \trg:%d  \t%s\t%g\t  \r",  pd(sProcNm,15), pd(s.CtrlName,31), ch, rg, pd( s.popStr,9), (s.popnum-1)
	DisplayCursor_Base( ch, rg )
	if ( s.popnum-1 != kBASE_OFF )
	// OneBase( ch, rg )										// Do a Base determination immediately. 
	endif
End

Function		BaseOp( ch, rg )
// Returns the currently selected base setting from the global variable underlying the 'BaseOp'  popupmenu 
	variable	ch, rg
	nvar		nBaseOpt	= $"root:uf:evo:de:pmBaseOp" + num2str( ch ) + num2str( rg ) + "00"		//e.g. for ch 1  and  rg 0:  root:uf:evo:de:pmBaseOp1000
	// printf "\t\t\tBaseOp( ch:%d, rg:%d, from variable: %d \t->'%s'  \r", ch, rg, nBaseOpt , StringFromList( nBaseOpt, klstBASE )
	return	nBaseOpt -1 			// popmenu variables are 1-based
End

Function		CheckNoise( ch, rg )
// Returns the currently selected   'Check noise'  setting from the global variable underlying the 'BaseOp'  popupmenu 
	variable 	ch, rg
	nvar		nBaseOpt		=  $"root:uf:evo:de:pmBaseOp" + num2str( ch ) + num2str( rg ) + "00"	//e.g. for ch 1  and  rg 0:  root:uf:evo:de:pmBaseOp1000
	variable	bCheckNoise	=  nBaseOpt-1 >= kBASE_NS_CHK_USERLIM					// popmenu variables are 1-based
	// printf "\t\t\tCheckNoise( ch:%d, rg:%d ) returns   %d    (nBaseOpt:%2d) \r", ch, rg, bCheckNoise, nBaseOpt
	return	bCheckNoise
End

Function		AutoUserLimit( ch, rg )
// Returns the currently selected    'Auto/User'   setting from the global variable underlying the 'BaseOp'  popupmenu 
	variable 	ch, rg	
	nvar		nBaseOpt		=  $"root:uf:evo:de:pmBaseOp" + num2str( ch ) + num2str( rg ) + "00"	//e.g. for ch 1  and  rg 0:  root:uf:evo:de:pmBaseOp1000
	variable	bAutoUserLimit	=  nBaseOpt-1 == kBASE_NS_CHK_AUTOLIM					// popmenu variables are 1-based
	// printf "\t\t\tAutoUserLimit( ch:%d, rg:%d ) returns   %d   (nBaseOpt:%2d) \r", ch, rg, bAutoUserLimit, nBaseOpt
	return	bAutoUserLimit
End

//Function		fChkNoise( s )
//// Checkbox action proc....
//	struct	WMCheckboxAction	&s
//	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
//	  printf "\t\t%s(s)\t\t%s\tb:%2d  =\t%d : from control \r",  sProcNm, pd(s.CtrlName,26), s.checked, PnValC( s.CtrlName )
//End
//
//Function		CheckNoise( ch, rg )
//// Returns the state of the   'Check noise' - checkbox.  Another approach: 'ControlInfo'
//	variable 	ch, rg
//	nvar		bCheckNoise	= $"root:uf:evo:de:cbChkNs" + num2str( ch ) + num2str( rg ) + "00"	//e.g. for ch 0  and  rg 1:  root:uf:evo:de:cbChkNs0100
//	// printf "\t\t\tCheckNoise( ch:%d, rg:%d ) returns   %d \r", ch, rg, bCheckNoise
//	return	bCheckNoise
//End
//
//Function		fAutoUser( s )
//// Checkbox action proc....
//	struct	WMCheckboxAction	&s
//	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
//	  printf "\t\t%s(s)\t\t%s\tb:%2d  =\t%d : from control \r",  sProcNm, pd(s.CtrlName,26), s.checked, PnValC( s.CtrlName )
//End
//
//Function		AutoUserLimit( ch, rg )
//// Returns the state of the   'Auto/User' - checkbox.  Another approach: 'ControlInfo'
//	variable 	ch, rg	
//	nvar		bAutoUserLimit	= $"root:uf:evo:de:cbAutUs" + num2str( ch ) + num2str( rg ) + "00"	//e.g. for ch 1  and  rg 0:  root:uf:evo:de:cbAutUs1000
//	// printf "\t\t\tAutoUserLimit( ch:%d, rg:%d ) returns   %d \r", ch, rg, bAutoUserLimit
//	return	bAutoUserLimit
//End

Function		SDevFactor_( ch, rg )
// Returns the factor with which the base standard deviation is multiplied  to  allow a comparioson with the peak height  to determine whether the event is valid.
	variable	ch, rg
	nvar		SDevFct	= $"root:uf:evo:de:svSDevFact" + num2str( ch )  + num2str( rg )  + "00"	
	// printf "\t\t\tSDevFactor( ch:%d, rg:%d ) returns: %d \t \r", ch, rg, SDevFct
	return	SDevFct
End


//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// ALIGNMENT  OF AVERAGES :

// 060213  Aligning averages

static constant		kALIGN_NONE=0,  kALIGN_BR=1,  kALIGN_RT5=2,  kALIGN_RSLP=3,  kALIGN_PK=4,  kALIGN_DT5=5
strconstant	klstALIGN_ = "off;BR;R5;SL;Pk;D5;"


Function		fAvgAlignLst_( sControlNm, sFo, sWin )
	string		sControlNm, sFo, sWin
	PopupMenu	$sControlNm, win = $sWin,	 value = klstALIGN_
End

Function		fAvgAlign( s )
	struct	WMPopupAction	&s
	fPopup_struct1( s )											// sets the global variable
	variable	ch	= TabIdx( s.ctrlName )
	variable	rg	= BlkIdx( s.ctrlName )
	TurnOffRemainingAlignPM( ch, rg )
End

Function		SetAlignOpt( ch, rg, nSetAlign )
// Set the 'Alignment' setting in the 'Alignment'  popupmenu  and also set the underlying global variable. It is hidden to the user that Popupmenus are 1-based.
	variable	ch, rg, nSetAlign
	nvar		nAlign	= $"root:uf:evo:de:pmAvgAlign" 	  + num2str( ch ) + num2str( rg ) + "00"	//e.g. for  nAlign  and   ch 1   and   rg 0:  root:uf:evo:de:pmnAlign1000
	string  	sCtrlNm	=  "root_uf_evo_de_pmAvgAlign" + num2str( ch ) + num2str( rg )  + "00"	
	nAlign 	= nSetAlign + 1										// popmenu variables are 1-based
	PopupMenu	$sCtrlNm   mode = nSetAlign + 1						// popmenu mode=selection is 1-based.
	// printf "\t\t\tSetAlignOpt( ch:%d, rg:%d, from variable: %d \t->'%s'  \r", ch, rg, nAlign-1 , StringFromList( nAlign-1, klstALIGN_ )
End

static Function		AlignOpt( ch, rg )
// Returns the currently selected  'Alignment' setting from the global variable underlying the 'Alignment'  popupmenu 
	variable	ch, rg
	nvar		nAlign	= $"root:uf:evo:de:pmAvgAlign" + num2str( ch ) + num2str( rg ) + "00"	//e.g. for  nAlign  and   ch 1   and   rg 0:  root:uf:evo:de:pmnAlign1000
	// printf "\t\t\tAlignOpt( ch:%d, rg:%d, from variable: %d \t->'%s'  \r", ch, rg, nAlign-1 , StringFromList( nAlign-1, klstALIGN_ )
	return	nAlign - 1		// popmenu variables are 1-based
End

Function		TurnOffRemainingAlignPM( chOn, rgOn )
// If the user sets an 'Alignment' popupmenu then all others are set to 'No align' as there can be only 1 alignment . It is hidden to the user that Popupmenus are 1-based.
	variable	chOn, rgOn
 	nvar		gChannels	= root:uf:evo:cfsr:gChannels
	variable	ch, rg, rgCnt
	for ( ch = 0; ch < gChannels; ch += 1)
		rgCnt	= RegionCnt( ch )
		for ( rg = 0; rg < rgCnt;  rg += 1 )	
			if ( ch != chOn  ||  rg != rgOn )
				SetAlignOpt( ch, rg, 0 )				// set all others to 'No align' 
				// Disabling all other PMs  automatically  would require an additional step for the user: He would have to set the previously selected PM to 'No align' before being able to change another PM.
				// Additional programming would be required too: Not implemented...  
				//	PopupMenu	$sCtrlNm   mode = 1, disable = 2		// mode=selection is 1-based.  Disable  normal:0,  hide:1,  grey:2
			endif
		endfor
	endfor
End

Function		Alignment()
// Computes the alignment time according to the user settings in the 'Alignment' popupmenu
 	nvar		gChannels	= root:uf:evo:cfsr:gChannels
	variable	ch, rg, rgCnt, nAlign, chAl = nan, rgAl = nan
	variable	Val	= nan						// nan is marker for 'no alignment' . This may be changed only once: By the (only) channel in which the user has... 
	for ( ch = 0; ch < gChannels; ch += 1)				// ...selected a setting different from 'no align' . For this reason  'kALIGN_NONE'  must  NOT  appear in the 'if cascade!'
		rgCnt	= RegionCnt( ch )
		for ( rg = 0; rg < rgCnt;  rg += 1 )	
			nAlign	= AlignOpt( ch, rg )
			if 	( nAlign == kALIGN_BR )
				Val	= EvT( ch, rg, kE_BRISE ) -   Evalu( 0, 0, kE_BEG, kVAL ) 	; chAl = ch	; rgAl = rg 
			elseif ( nAlign == kALIGN_RT5 )
				Val	= EvT( ch, rg, kE_RISE50 ) -  Evalu( 0, 0, kE_BEG, kVAL ) 	; chAl = ch	; rgAl = rg  
			elseif ( nAlign == kALIGN_PK )
				Val	= EvT( ch, rg, kE_PEAK )	 -  Evalu( 0, 0, kE_BEG, kVAL ) 	; chAl = ch	; rgAl = rg  
			elseif ( nAlign == kALIGN_DT5 ) 	
				Val	= EvT( ch, rg, kE_DEC50 )	 -  Evalu( 0, 0, kE_BEG, kVAL ) 	; chAl = ch	; rgAl = rg  
			elseif ( nAlign == kALIGN_RSLP )
				Val	= EvT( ch, rg, kE_RISSLP ) -  Evalu( 0, 0, kE_BEG, kVAL ) 	; chAl = ch	; rgAl = rg  
			endif	
		endfor
	endfor
	// printf "\t\t\tAlignment() \tchAl:%.0lf\trgAl:%.0lf\tnAlign :%2d \t-> \t[ Beg:] \t%7g\t%g ms  \r", chAl, rgAl, nAlign,  Evalu( 0, 0, kE_BEG, kVAL )  * 1000, Val * 1000
	return 	Val
End

//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

 constant		kPEAK_OFF_ = 0,  kPEAK_UP_ = 1,  kPEAK_DOWN_ = 2
strconstant	klstPEAKDIR_ 	= "off;up;down;"								//  Igor does not allow this to be static!  

Function		fPkDirLst( sControlNm, sFo, sWin )
	string		sControlNm, sFo, sWin
	PopupMenu	$sControlNm, win = $sWin,	 value = klstPEAKDIR_
End

Function	/S	PeakDirStr( nPeakDir )
	variable	nPeakDir
	return	StringFromList( nPeakDir, klstPEAKDIR_ )
End

Function		fPkDir( s )
	struct	WMPopupAction	&s
	fPopup_struct1( s )											// sets the global variable
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	string  	sFo	 	= GetUserData( 	s.win,  s.ctrlName,  "sFo" )			// e.g.  'root:uf:evo:' 
	string  	sSubDir	= ReplaceString( "root:uf:", sFo, "" )		  		// e.g.  'root:uf:evo:' -> 'evo:'

	variable	ch	= TabIdx( s.ctrlName )
	variable	rg	= BlkIdx( s.ctrlName )
	// printf "\t%s\t%s\tch:%d  \trg:%d  \t%s\t%g\t  \r",  pd(sProcNm,15), pd(s.CtrlName,31), ch, rg, pd( s.popStr,9), (s.popnum-1)
	EnableSetVar(  s.win,  "root_uf_evo_de_svSideP" + num2str( ch )  + num2str( rg )  + "00", (s.popnum-1 == kPEAK_OFF_  ?  kENABLE :  kDISABLE) )  // seems to be inversed but is OK	
	DisplayCursor_Peak( ch, rg )
	if ( s.popnum-1 != kPEAK_OFF_ )
		OnePeak( ch, rg )										// Do a peak determination immediately. 
	endif
End

Function		PeakDir( ch, rg )
// Returns the currently selected peak direction  in the popupmenu : returns 0 for off, 1 for upward  and 2 for downward
	variable	ch, rg
	string  	sCtrlNm	  = "root_uf_evo_de_pmUpDn" + num2str( ch )  + num2str( rg )  + "00"		// the phase in the control is (in contrast to fit phases) always 0 (and not PH_PEAK) 
	ControlInfo /W= $"de" $sCtrlNm
	variable	nDir	= V_Value - 1							// 1-based 
	// printf "\t\t\tPeakDir( ch:%d, rg:%d, from Popupmenu( %s ): %d \t->'%s'  \r", ch, rg, sCtrlNm, nDir , StringFromList( nDir, klstPEAKDIR_ )
	return	nDir
End


Function		SetPeakDir( ch, rg, nPeakDir )
// Sets the peak direction  in the popupmenu :  0 for off, 1 for upward  and 2 for downward
	variable	ch, rg, nPeakDir
	string  	sCtrlNm	  = "root_uf_evo_de_pmUpDn" + num2str( ch )  + num2str( rg )  + "00"		// the phase in the control is (in contrast to fit phases) always 0 (and not PH_PEAK) 
	PopupMenu $sCtrlNm, win= $"de", mode =  nPeakDir + 1								// 1-based 
	// printf "\t\t\tSetPeakDir( ch:%d, rg:%d, from Popupmenu( %s ): %d \t->'%s'  \r", ch, rg, sCtrlNm, nPeakDir , PeakDirString( nPeakDir )
	// ControlUpdate /W= $"de" $sCtrlNm												// seems not to be required	
End



Function		fSidePts( s ) 
//  SetVariable action proc for the points around a peak over which the peak value is averaged. Single sided points are assumed ranging from 0 .. 20 so the true range is 1..41
	struct	WMSetvariableAction    &s
//	fSetvar_struct1( s )											// sets the global variable
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	variable	ch		= TabIdx( s.ctrlName )
	variable	rg		= BlkIdx( s.ctrlName )

 printf "\t%s\t%s\tch:%2d\trg:%2d\tvar:%g\tEvCd:%d\tEvMod:%d\r",  pd(sProcNm,13), pd(s.CtrlName,31), ch, rg, s.dval, s.eventcode, s.eventmod
	OnePeak( ch, rg )											// Do determination of the corresponding  peak immediately.  
End

Function		PeakSidePts( ch, rg )
// Returns the number of points on each side side of a peak over which is to be averaged.  0 means no averaging, 2 means average over 5 points
	variable	ch, rg
	nvar		nPeakSidePts	= $"root:uf:evo:de:svSideP" + num2str( ch )  + num2str( rg )  + "00"	// the phase in the control is (in contrast to fit phases) always 0 (and not PH_PEAK) 
	// printf "\t\t\tPeakSidePts( ch:%d, rg:%d ) returns: %d \t \r", ch, rg, nPeakSidePts
	return	nPeakSidePts
End

Function		RserMV( ch, rg )
// Returns the pulse amplitude of the Rseries measurement pulse  (usually 5 or 10 mV)
	variable	ch, rg
	nvar		RserMV	= $"root:uf:evo:de:svRserMV" + num2str( ch )  + num2str( rg )  + "00"	
	// printf "\t\t\tRserMV( ch:%d, rg:%d ) returns: %d  mV =   %g V  \t \r", ch, rg, RserMV, RserMV / 1000
	return	RserMV / 1000
End

//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// 	Action  procs  for  Latencies

//constant		kLAT_OFF=0,  kLAT_MANUAL=1,  kLAT_BR=2,  kLAT_RT5=3,  kLAT_PK=4,  kLAT_DT5=5	//, kLAT_E_MANCSR=6,  kLAT_E_BR=7,  kLAT_E_RT5=8,  kLAT_E_PK=9,  kLAT_E_DT5=10 
//strconstant	klstLATC = "off;B ManC;B BsRs;B RT50;B Peak;B DT50;E ManC;E BsRs;E RT50;E Peak;E DT50;"
//strconstant	klstLATC = "off;ma;BR;R5;Pk;D5;"

// 060109 Latency RiseSlp
constant		kLAT_OFF_=0,  kLAT_MANUAL_=1,  kLAT_BR_=2,  kLAT_RT5_=3,  kLAT_RSLP_=4,  kLAT_PK_=5,  kLAT_DT5_=6
strconstant	klstLATC_ = "off;ma;BR;R5;SL;Pk;D5;"


Function		fLatCLst( sControlNm, sFo, sWin )
	string		sControlNm, sFo, sWin
	PopupMenu	$sControlNm, win = $sWin,	 value = klstLATC_
End

Function		fLat0B( s )
	struct	WMPopupAction	&s
	fPopup_struct1( s )										// sets the global variable
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	variable	ch	= TabIdx( s.ctrlName )
	variable	rg	= BlkIdx( s.ctrlName )
	variable	lc	= 0, 	BegEnd = CN_BEG
	 printf "\t%s\t%s\tch:%d  \trg:%d  lc:%d  BegEnd:%d \t%s\t%g\t  \r",  pd(sProcNm,15), pd(s.CtrlName,31), ch, rg, lc, BegEnd, pd( s.popStr,9), (s.popnum-1)
	// TurnRemainingLatenciesOff( s.CtrlName, lc, BegEnd, ch, rg )	// Two advantages: 1. Prevent that the user accidentally redefines this latency in another channer or region.  2. Tidy up the panel. 
	AllLatenciesCheck()									//...BUT does not work as all hidden popmenus are restored whenever tabs are clicked. -> must recognise hidden state then
	DisplayCursor_Lat( ch, rg, lc, BegEnd )
	PanelRSUpdateTable_()								// update the 'Select results' panel whose contents may have changed
End

Function		fLat0E( s )
	struct	WMPopupAction	&s
	fPopup_struct1( s )										// sets the global variable
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	variable	ch	= TabIdx( s.ctrlName )
	variable	rg	= BlkIdx( s.ctrlName )
	variable	lc	= 0, 	BegEnd = CN_END
	 printf "\t%s\t%s\tch:%d  \trg:%d  lc:%d  BegEnd:%d \t%s\t%g\t  \r",  pd(sProcNm,15), pd(s.CtrlName,31), ch, rg, lc, BegEnd, pd( s.popStr,9), (s.popnum-1)
	// TurnRemainingLatenciesOff( s.CtrlName, lc, BegEnd, ch, rg )	// Two advantages: 1. Prevent that the user accidentally redefines this latency in another channer or region.  2. Tidy up the panel. 
	AllLatenciesCheck()									//...BUT does not work as all hidden popmenus are restored whenever tabs are clicked. -> must recognise hidden state then
	DisplayCursor_Lat( ch, rg, lc, BegEnd )
	PanelRSUpdateTable_()								// update the 'Select results' panel whose contents may have changed
End

Function		fLat1B( s )
	struct	WMPopupAction	&s
	fPopup_struct1( s )										// sets the global variable
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	variable	ch	= TabIdx( s.ctrlName )
	variable	rg	= BlkIdx( s.ctrlName )
	variable	lc	= 1, 	BegEnd = CN_BEG
	 printf "\t%s\t%s\tch:%d  \trg:%d  lc:%d  BegEnd:%d \t%s\t%g\t  \r",  pd(sProcNm,15), pd(s.CtrlName,31), ch, rg, lc, BegEnd, pd( s.popStr,9), (s.popnum-1)
	AllLatenciesCheck()
	DisplayCursor_Lat( ch, rg, lc, BegEnd )
	PanelRSUpdateTable_()								// update the 'Select results' panel whose contents may have changed
End

Function		fLat1E( s )
	struct	WMPopupAction	&s
	fPopup_struct1( s )										// sets the global variable
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	variable	ch	= TabIdx( s.ctrlName )
	variable	rg	= BlkIdx( s.ctrlName )
	variable	lc	= 1, 	BegEnd = CN_END
	 printf "\t%s\t%s\tch:%d  \trg:%d  lc:%d  BegEnd:%d \t%s\t%g\t  \r",  pd(sProcNm,15), pd(s.CtrlName,31), ch, rg, lc, BegEnd, pd( s.popStr,9), (s.popnum-1)
	AllLatenciesCheck()
	DisplayCursor_Lat( ch, rg, lc, BegEnd )
	PanelRSUpdateTable_()								// update the 'Select results' panel whose contents may have changed
End

Function		fLat2B( s )
	struct	WMPopupAction	&s
	fPopup_struct1( s )										// sets the global variable
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	variable	ch	= TabIdx( s.ctrlName )
	variable	rg	= BlkIdx( s.ctrlName )
	variable	lc	= 2, 	BegEnd = CN_BEG
	 printf "\t%s\t%s\tch:%d  \trg:%d  lc:%d  BegEnd:%d \t%s\t%g\t  \r",  pd(sProcNm,15), pd(s.CtrlName,31), ch, rg, lc, BegEnd, pd( s.popStr,9), (s.popnum-1)
	AllLatenciesCheck()
	DisplayCursor_Lat( ch, rg, lc, BegEnd )
	PanelRSUpdateTable_()								// update the 'Select results' panel whose contents may have changed
End

Function		fLat2E( s )
	struct	WMPopupAction	&s
	fPopup_struct1( s )										// sets the global variable
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	variable	ch	= TabIdx( s.ctrlName )
	variable	rg	= BlkIdx( s.ctrlName )
	variable	lc	= 2, 	BegEnd = CN_END
	 printf "\t%s\t%s\tch:%d  \trg:%d  lc:%d  BegEnd:%d \t%s\t%g\t  \r",  pd(sProcNm,15), pd(s.CtrlName,31), ch, rg, lc, BegEnd, pd( s.popStr,9), (s.popnum-1)
	AllLatenciesCheck()
	DisplayCursor_Lat( ch, rg, lc, BegEnd )
	PanelRSUpdateTable_()								// update the 'Select results' panel whose contents may have changed
End


Function		LatC( ch, rg, lc, BegEnd )
// Returns the currently selected  latency setting from the global variable underlying the 'Latency'  popupmenu 
	variable	ch, rg, lc, BegEnd
	nvar		nLatC	= $"root:uf:evo:de:pmLat" + num2str( lc )  + num2str( BegEnd )  + num2str( ch ) + num2str( rg ) + "00"	//e.g. for  LatC 0   and   End   and   ch 1   and   rg 0:  root:uf:evo:de:pmLat011000
	// printf "\t\t\tLatC( lc:%d, BegEnd:%d, ch:%d, rg:%d, from variable: %d \t->'%s'  \r", lc, BegEnd, ch, rg, nLatC-1 , StringFromList( nLatC-1, klstLATC_ )
	return	nLatC - 1		// popmenu variables are 1-based
End

//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// 	Action  procs  for  FITTING

Function	/S	fFitOnOff( sBaseNm, sFo, sWin )
	string		sBaseNm, sFo, sWin
// Initial state of the  'Fit' checkboxes.   This same state must also be used for the initial visibility of the dependent  'FitFunc'  and  'FitRange' controls
// Syntax: tab blk row col 1-based-index;  (Tab0: Window,Peak  Tab2: Window,Cursor,  Tab3...: Window (=default)
//	return  "0010_1;0100_1;~0"		// Test init: Tab~ch~0, blk~reg~0, row~2.fit~1 will be ON=1 ;  Tab~ch~0, blk~reg~1, row~1.fit~0 will be ON=1 ;  all others will be off = 0 
	return  "0000_1;~0"		// Test init: Tab~ch~0, blk~reg~0, row~1.fit~0 will be ON=1 ;  all others will be off = 0 
End


// Version 1 : will print  'Fit 0   CR   Fit 1  CR...'
Function	/S	fFitRowTitles( sBaseNm, sF, sWin )
	string  	sBaseNm, sF, sWin 
	variable	fi, nFits	= ItemsInList( ksPHASES ) - PH_FIT0 
	string  	lstTitles	= ""
	for ( fi = 0; fi <  nFits; fi += 1 )
		lstTitles	+=  "Fit " + num2str( fi ) + ","  	// e.g.   'Fit 0,Fit 1,Fit 2,'
	endfor 
	// printf "\t\t\tfFitRowTitles1() / fFitRowDums() :'%s' \r", lstTitles
	return	lstTitles
End

// Version 2 : will print  '1. Fit   CR  2. Fit  CR...'     if  there is  also  'Fit'  in the panel textwave in the columntitles column
//Function	/S	fFitRowTitles( sBaseNm, sF, sWin )
//	string  	sBaseNm, sF, sWin 
//	variable	fi, nFits	= ItemsInList( ksPHASES ) - PH_FIT0 
//	string  	lstTitles	= ""
//	for ( fi = 0; fi <  nFits; fi += 1 )
//		lstTitles	+=  num2str( fi + 1 ) + ". ,"  	// e.g.   '1. ,2. ,3. ,'
//	endfor 
//	// printf "\t\t\tfFitRowTitles() / fFitRowDums() :'%s' \r", lstTitles
//	return	lstTitles
//End

sBaseNm, sF, sWin )
	string  	sBaseNm, sF, sWin 

Function	/S	fFitRowDums( sBaseNm, sF, sWin )
	string  	sBaseNm, sF, sWin 
// Supplies as many separators as there are titles in the controlling 'Fit' checkbox. They are needed for  'RowCnt()'  to preserve panel geometry, otherwise 'Fit' checkbox and 'FitFunc'/'FitRng' controls will appear in different lines. 
	variable	fi, nFits	= ItemsInList( ksPHASES ) - PH_FIT0 
	string  	lstTitles	= ""
	for ( fi = 0; fi <  nFits; fi += 1 )
		lstTitles	+=  ","  					// e.g.   ',,,'
	endfor 
	// printf "\t\t\tfFitRowTitles() / fFitRowDums :'%s' \r", lstTitles
	return	lstTitles
End


Function		fFit_e( s )
// Checkbox action proc....
	struct	WMCheckboxAction	&s
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	// printf "\t\t%s(s)\t\t%s\tb:%2d  =\t%d : from control \r",  sProcNm, pd(s.CtrlName,26), s.checked, PnValC( s.CtrlName )
	string  	sThisControl, sControlledCoNm
	
	sThisControl		= StripFoldersAnd4Indices( s.CtrlName )			// remove all folders and the 4 trailing numbers e.g. 'root_uf_evo_de_cbFit0000'  -> 'cbFit' 

	// Depending on the state of the  'Fit'  checkbox, enable or disable the depending control  'FitFnc'  (which is in the same line)
	sControlledCoNm	= ReplaceString( sThisControl, s.CtrlName, "pmFiFnc" )	// for this to work both the controlling control and the controlled (=enabled/disabled) control must reside in the same folder
	 printf "\t\t%s(s)\t\t%s\tb:%2d  =\t%d : from control \tUpdating:%s\t \r",  sProcNm, pd(s.CtrlName,26), s.checked, PnValC( s.CtrlName ), sControlledCoNm 
	// Display or hide the dependent control  'FitFnc' 
	PopupMenu $sControlledCoNm, win = $s.win,  userdata( bVisib )	= num2str( s.checked  )	// store the visibility state (depending here only on cbFit, not on the tab!) so that it can be retrieved in the tabcontrol action proc (~ShowHideTabControl3() )
	PopupMenu $sControlledCoNm, win = $s.win,  disable	=  s.checked  ?  0 :   kHIDE  // : kDISABLE
	// Bad:
	ControlUpdate  /W = $s.win $sControlledCoNm	// BAD: should not be needed  but without this line  SOME!  popupmenu controls are not displayed/hidden when they should (when the Checkbox Fit is changed)

	// Depending on the state of the  'Fit'  checkbox, enable or disable the depending control  'FitRng'  (which is in the same line)
	sControlledCoNm	= ReplaceString( sThisControl, s.CtrlName, "pmFiRng" )// for this to work both the controlling control and the controlled (=enabled/disabled) control must reside in the same folder
	 printf "\t\t%s(s)\t\t%s\tb:%2d  =\t%d : from control \tUpdating:%s\t \r",  sProcNm, pd(s.CtrlName,26), s.checked, PnValC( s.CtrlName ), sControlledCoNm 
	// Display or hide the dependent control  'FitRng'
	PopupMenu $sControlledCoNm, win = $s.win,  userdata( bVisib )	= num2str( s.checked  )	// store the visibility state (depending here only on cbFit, not on the tab!) so that it can be retrieved in the tabcontrol action proc (~ShowHideTabControl3() )
	PopupMenu $sControlledCoNm, win = $s.win,  disable	=  s.checked  ?  0 :   kHIDE  // : kDISABLE
	// Bad:
	ControlUpdate  /W = $s.win $sControlledCoNm	// BAD: should not be needed  but without this line  SOME!  popupmenu controls are not displayed/hidden when they should (when the Checkbox Fit is changed)


	// Turn the fit cursors on and off
	variable	ch		= TabIdx( s.ctrlName )
	variable	rg		= BlkIdx( s.ctrlName )
	variable	fi		= RowIdx( s.ctrlName )
	variable	ph		= RowIdx( s.ctrlName ) + PH_FIT0 
	string		sWnd 	= CfsWndNm( ch )
	//  printf "\t%s\t%s\tch:%d\trg:%d\tph:%d\t on:%d\tbVis:%d\t  \r",  pd(sProcNm,15), pd(s.CtrlName,25), ch, rg, ph, s.Checked, bVisib
	DisplayHideCursors( ch, rg, ph, sWnd, s.checked )

	// Do a fit immediately. 
	string		sFoldOrgWvNm		= GetOnlyOrAnyDataTrace( ch )
	wave  /Z	wOrg				= $sFoldOrgWvNm
	if ( waveExists( wOrg ) )							// exists only after the user has clicked into the data sections listbox to view, analyse or average a data section
		OneFit( wOrg, ch, rg, fi )						// will fit only if  'Fit' checkbox is 'ON'
	endif
// 051019 weg
//	PanelRSUpdateDraw_()							// update the 'Select results' panel whose size has changed
	PanelRSUpdateTable_()							// update the 'Select results' panel whose size has changed
End


	 Function	/S	GetOnlyOrAnyDataTrace( ch )
	variable	ch
	// Version 1 : Get the current sweep. ++ Gets  even in  'stacked' display mode the current trace, ignores all others.  -- Needs global current sweep and  global current size. 
	wave	wCurRegion	= root:uf:evo:evl:wCurRegion
	variable  	nCurSwp		= wCurRegion[ kCURSWP ]	
	variable  	nSize		= wCurRegion[ kSIZE ]	
	string		sTrc			= FoOrgWvNm( ch, nCurSwp, nSize )		// CAVE : RETURNS wave name including folder  -->  wOrg = $ sTrc
	//  printf "\tGetOnlyOrAnyDataTrace( ch:%d )  '%s' \r", ch, sTrc	
	return	sTrc											// CAVE : RETURNS wave name including folder  -->  wOrg = $ sTrc
End

//Function	/S	GetOnlyOrAnyDataTrace( ch, sWNm )
//	// Version 2 : Get any data sweep.  If the display mode is 'single'  this will be the current sweep.  If the display mode is 'stacked'  it can be any sweep, ...
//	// ..which is also OK as this function is thought to only give some feedback to the user when he changed the fit settings (called only in an 'Fit' action procedures) . 
//	string		sPointsMatch	= "wpY_"  		// the points waves
//	string		sCursorsMatch	= "wcY_"  		// the cursors waves
//	string		sFitsMatch		= "wF_"  			// the fit waves
//	string		sDummyMatch	= "wDummy"  		// dummy wave introduced as a workaround in  'EraseTracesInGraphExcept()'  , should not be necessary and should be removed...
//	string 	sTNL		= TraceNameList( sWNm, ";", 1 )
//	
//	 printf "\tGetOnlyOrAnyDataTrace( ch:%d )  original :\t\ttraces:%d  TrcNmList:%s \r", ch, ItemsInList( sTNL ), sTNL[0,160]	
//	sTNL			= ListMatch( sTNL, "!" + sPointsMatch + "*" )
//	 printf "\tGetOnlyOrAnyDataTrace( ch:%d )  after cleaning p:\ttraces:%d  TrcNmList:%s \r", ch, ItemsInList( sTNL ), sTNL[0,160]	
//	sTNL			= ListMatch( sTNL, "!" + sCursorsMatch + "*" )
//	 printf "\tGetOnlyOrAnyDataTrace( ch:%d )  after cleaning c:\ttraces:%d  TrcNmList:%s \r", ch, ItemsInList( sTNL ), sTNL[0,160]	
//	sTNL			= ListMatch( sTNL, "!" + sFitsMatch + "*" )
//	 printf "\tGetOnlyOrAnyDataTrace( ch:%d )  after cleaning c:\ttraces:%d  TrcNmList:%s \r", ch, ItemsInList( sTNL ), sTNL[0,160]	
//	sTNL			= ListMatch( sTNL, "!" + sDummyMatch + "*" )
//	 printf "\tGetOnlyOrAnyDataTrace( ch:%d )  after cleaning c:\ttraces:%d  TrcNmList:%s \r", ch, ItemsInList( sTNL ), sTNL[0,160]	
//	return	StringFromList( 0, sTNL )			// CAVE : RETURNS wave name  without   folder  -->  wOrg = TraceNameToWaveRef( sWNm, sFoldOrgWvNm )
//End



Function		DoFit( ch, rg, fi )
// Returns the state of the   1. Fit -    or  2. Fit - checkbox.  Another approach: 'ControlInfo'
	variable 	ch, rg, fi
	nvar		bFit	= $"root:uf:evo:de:cbFit" + num2str( ch ) + num2str( rg ) + num2str( fi ) + "0"	//e.g. for ch 0  and  rg 0  and  fit 1:  root:uf:evo:de:cbFit0010
	return	bFit
End


Function		fFitFnc( s )
// Action proc of the fit function popupmenu
	struct	WMPopupAction	&s
	fPopup_struct1( s )											// sets the global variable
	string  	sPath	= ksEVOCFG_DIR 							// e.g.  'C:Epc:Data:EvalCfg:'   or   'C:UserIgor:Ced:'  , must contain drive letter
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	variable	ch		= TabIdx( s.ctrlName )
	variable	rg		= BlkIdx( s.ctrlName )
	variable	fi		= RowIdx( s.ctrlName )
	variable	nFitFunc	= s.popnum - 1								// the popnumber is 1-based
	// printf "\t%s\t%s\tch:%d \trg:%d \tfi:%d \tnFitFnc:%d = '%s'\t \r",  pd(sProcNm,15), pd(s.CtrlName,25), ch, rg, fi, nFitFunc, FitFuncNm_( nFitFunc )

	// Do a fit immediately.
	string		sFoldOrgWvNm		= GetOnlyOrAnyDataTrace( ch )
	wave	wOrg				= $sFoldOrgWvNm 
	OneFit( wOrg, ch, rg, fi )							// will fit only if  'Fit' checkbox is 'ON'

// 051019 weg
//	PanelRSUpdateDraw_()							// update the 'Select results' panel whose size may have changed
	PanelRSUpdateTable_()								// update the 'Select results' panel whose size may have changed
End


//Function		FitFncFromPopup( ch, rg, fi )
//// Returns the index of the fit function currently selected in the popupmenu.  ??? Similar: FitFncFromPopup(), FitFnc()
//	variable	ch, rg, fi
//	string  	sCtrlNm	  = "root_uf_evo_de_pmFiFnc" + num2str( ch )  + num2str( rg )  + num2str( fi ) + "0"
//	ControlInfo /W= $"de" $sCtrlNm
//	variable	nFitFunc	= V_Value	- 1					// the popnumber is 1-based
//	 printf "\t\tFitFncFromPopup( \t\t\t\tch:%d, rg:%d, fi:%d (was ph:%d) ) from Popupmenu( %s ): \t%d \t \r", ch, rg, fi, fi + PH_FIT0, sCtrlNm, nFitFunc
//	return	nFitFunc
//End

Function		FitFnc( ch, rg, fi )
// the value was 1-based as it was the popnumber, it is 0-based now . Do NOT change  'nFitFunc'  as this would change the global  '...pmFiFnc...' 
	variable ch, rg, fi
	nvar		nFitFunc	= $"root:uf:evo:de:pmFiFnc" + num2str( ch ) + num2str( rg )  + num2str( fi ) + "0"
	// printf "\t\tFitFnc(\tch:%d, rg:%d, fi:%d (was ph:%d) ) from Variable \t  'root:uf:evo:de:pmFiFncxxx' :   \t%d \t \r", ch, rg, fi, fi + PH_FIT0, nFitFunc-1
	return	nFitFunc-1									
End

Function		fFitFncLst( sControlNm, sFo, sWin )
	string		sControlNm, sFo, sWin
	PopupMenu	$sControlNm, win = $sWin,	   value = 	ListFitFunctions()
End

Function	/S	fFitFncInit( sBaseNm, sFo, sWin )
	string		sBaseNm, sFo, sWin
// The panel listbox is initially filled with the default fit functions given here. Syntax:   tab=ch  blk  row col  _ 1-based-index;  repeat n times;  ~ 1-based-index for all remaining controls; 
// only test :string		sInitialFitFuncs	=  "0000_2;0010_1;1000_1;1010_1;1000_1;1010_1;1000_1;1010_1;~4;"	// e.g. : ( Tab=ch=0: Line,none  Tab=ch=1..3:none,none, other tabs and blocks>1: value 4 = 1exp+con
	string		sInitialFitFuncs	=  "0000_4;~2;"	// e.g. : ( Tab=ch=0: Line,none  Tab=ch=1..3:none,none, other tabs and blocks>1: value 2 = line,  value 3 = exp, value 4 = 1exp+con
	// print "\t\tsInitialFitFuncs:", sInitialFitFuncs
	return	sInitialFitFuncs
End



Function		fFitRng( s )
	struct	WMPopupAction	&s
	fPopup_struct1( s )											// sets the global variable
	string  	sPath	= ksEVOCFG_DIR 							// e.g.  'C:Epc:Data:EvalCfg:'   or   'C:UserIgor:Ced:'  , must contain drive letter
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	string  	sFo	 	= GetUserData( 	s.win,  s.ctrlName,  "sFo" )			// e.g.  'root:uf:evo:' 
	string  	sSubDir	= ReplaceString( "root:uf:", sFo, "" )		  		// e.g.  'root:uf:evo:' -> 'evo:'
	variable	ch		= TabIdx( s.ctrlName )
	variable	rg		= BlkIdx( s.ctrlName )
	variable	fi		= RowIdx( s.ctrlName ) 
	variable	nFitRng	= s.popnum - 1
	  printf "\t%s\t%s\tch:%d  \trg:%d  \tfi:%d  \t%s\t%g\t= '%s' \t  \r",  pd(sProcNm,15), pd(s.CtrlName,23), ch, rg, fi, pd( s.popStr,9), nFitRng,  StringFromList( nFitRng, klstFITRANGE )
	// Do a fit immediately. 
	string		sFoldOrgWvNm		= GetOnlyOrAnyDataTrace( ch )
	wave	wOrg				= $sFoldOrgWvNm
	OneFit( wOrg, ch, rg, fi )
End

Function		fFitRngLst( sControlNm, sFo, sWin )
	string		sControlNm, sFo, sWin
	PopupMenu	$sControlNm, win = $sWin,	  value = klstFITRANGE
End

Function	/S	fFitRngInit( sBaseNm, sFo, sWin )
	string		sBaseNm, sFo, sWin
//	return "0000_1;0010_3;1000_1;1010_2;"	// Syntax: tab blk row col 1-based-index;  (Tab0: Window,Peak  Tab2: Window,Cursor,  Tab3...: Window (=default)
// Initialise all fit ranges with 2, which is the 2. value in the 1-based listbox 'window,cursor,peak'  = 'Cursor'
	return "~2;"						// Syntax: remaining values (in this case all values) 
End

//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function		fStartVal_( s )
	struct	WMCheckboxAction	&s
// 2009-10-22 modify for Igor6  (remove endless loop)
//	fRadio_struct3( s )											// Check / uncheck all the radio buttons of this group
	FitAllChansAllRegions_()										// Do all fits immediately.
End

 Function		OnlyStartValsNoFit_()	
// 0 : do the fit,  1 : display only starting values but do no fitting
//	nvar		bOnlyStartValsNoFit	= root:uf:evo:de:raStVal0000			// Special code working only with 2 buttons. Depends on button order: must be the boolean value of the  'Start Val'  button (which is the 1. button = xxx:yyy:nnn0)
//	return	bOnlyStartValsNoFit
	nvar		bDoFit			= root:uf:evo:de:raStVal00				// General code handling any number of buttons. Depends on button order. As it is a radio button the last 2 indices are stripped.
	return	bDoFit ? 0 : 1										// invert the  'bDoFit' value to return 'bOnlyStartValsNoFit'
End


Function		fPrintReslts( s )
// History printing  needs an explicit action procedure to convert the index of the listbox entry into the print mask
	struct	WMPopupAction	&s
	fPopup_struct1( s )												// sets the global variable
	string  	sPath	= ksEVOCFG_DIR 								// e.g.  'C:Epc:Data:EvalCfg:'   or   'C:UserIgor:Ced:'  , must contain drive letter
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	string  	sFo	 	= GetUserData( 	s.win,  s.ctrlName,  "sFo" )				// e.g.  'root:uf:evo:' 
	string  	sSubDir	= ReplaceString( "root:uf:", sFo, "" )		  			// e.g.  'root:uf:evo:' -> 'evo:'

	nvar		gPrintMask	= root:uf:evo:evl:gprintMask
	gPrintMask			= str2num( StringFromList( s.popNum - 1, ksPRINTMASKS ) )	// Convert changed popup index into PrintMask bit field

	  printf "\t%s\t%s\tpopnum%2d\t%s\tgPrintMask:%4d\t  \r",  pd(sProcNm,15), pd(s.ctrlName,23), s.popNum, pd(s.popStr,11), gPrintMask
End

Function		fPrintResltsLst( sControlNm, sFo, sWin )
	string		sControlNm, sFo, sWin
	PopupMenu	$sControlNm, win = $sWin,	 value = ksPRINTRESULTS
End



Function		fAutoSelect( s )
//  Auto Selection of Print Results needs an explicit action procedure to convert the index of the listbox entry into the print mask
	struct	WMPopupAction	&s
	fPopup_struct1( s )												// sets the global variable
	string  	sPath	= ksEVOCFG_DIR 								// e.g.  'C:Epc:Data:EvalCfg:'   or   'C:UserIgor:Ced:'  , must contain drive letter
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	string  	sFo	 	= GetUserData( 	s.win,  s.ctrlName,  "sFo" )				// e.g.  'root:uf:evo:' 
	string  	sSubDir	= ReplaceString( "root:uf:", sFo, "" )		  			// e.g.  'root:uf:evo:' -> 'evo:'

	// Set a default combination of selected results  e.g. 'Standard' , 'StimFit' , 'PeakAmp'...
	string  	lstAutoSel	= StringFromList( s.popNum - 1, lstlstAUTOSELECT, "~" )	// Convert changed popup index into list of selected results
	variable	n, nItems	= ItemsInList( lstAutoSel, "," )	// !!! Assumption separator
	variable	nState 	= kRS_PRINT

	// Set a default combination of selected results  e.g. 'Standard' , 'StimFit' , 'PeakAmp'...
	  printf "\t%s\t%s\tpopnum%2d\t%s\tItems:%d\tgAutoSelMask: '%s' \t  \r",  pd(sProcNm,15), pd(s.ctrlName,23), s.popNum, pd(s.popStr,11), nItems, lstAutoSel
	wave /Z	wFlags		= root:uf:evo:lb:wSRFlagsPr
	// 050831
	if ( ! WaveExists( wFlags ) ) 								// or if the 'Select Print Results' panel does not exist
		// Turn the panel on ...   1. as wFlags  will only be built in 'PanelRSUpdateTable_()'  if the panel  is visible.   2. as the user wants to see which results are selected   3. as the user will usually want to add some results in the panel
		nvar		bVisib	= root:uf:evo:de:cbResSelTb0000					// The ON/OFF state ot the 'Select Results' checkbox
		bVisib	= TRUE
		PanelRSUpdateTable_()									// build  wFlags and by building the panel
		wave 	wFlags	= root:uf:evo:lb:wSRFlagsPr
	endif
	string  	sPlaneNm		= "BackColors" 
	variable	pl			= FindDimLabel( wFlags, 2, sPlaneNm )

	nvar		gChans	= root:uf:evo:cfsr:gChannels					// 				
	variable	nIndex, nMaxIndex								// stores whether we found an item matching  'sItem'  or not
	variable	col, ch, rg, nRegs
	string  	sItem, lst
	for ( n = 0; n < nItems; n += 1 )
		sItem		 = StringFromList( n, lstAutoSel, "," )				// e.g.  Peak_01  (ch=0, rg=1)   !!! Assumption separator
		col 		 = 0
		nMaxIndex = kNOTFOUND
		for ( ch = 0; ch < gChans; ch += 1 )						// loop through all chans and all regions...
			nRegs	= RegionCnt( ch )						// ... in the same order as the listbox columns have been built earlier...
			for ( rg = 0; rg < nRegs; rg += 1 )						// ... and increment the column counter				
				lst		= ListACV1RegionTable_( ch, rg )
				nIndex	= WhichListItem( sItem, lst )
				if ( nIndex != kNOTFOUND )
					// printf "\t\t\tGetChRg\t%s\tfound in Print Select Results listbox in  col:%2d   index:%3d\t \r", pd(sItem,12), col, nIndex
					DSSet5( wFlags, nIndex, nIndex, col, pl, nState )
					nMaxIndex	= max( nIndex, nMaxIndex )	// remember any found index which will be a positive number larger than kNOTFOUND (=-1)
					break								// process next chan (it would be better to process the next item, but 'break' does not work that way...)
				endif
				col   += 1
			endfor		
		endfor		
		// Todo:  Finds true developer errors (e.g. misspellings in the AutoSelection list 'Amp_10' instead of 'Ampl_10' ) ...
		//  but also finds user errors e.g. the list requires chan 2 and region 1  (e.g. Ampl_21)  but the user has turned this region  and/or  the evaluation of this channel off !    
		if ( nMaxIndex == kNOTFOUND )
			DeveloperError( "fAutoSelect() : Could not find '" + sItem + "' in the Print Select Results listbox." )
		endif	
	endfor		

End

Function		fAutoSelectLst( sControlNm, sFo, sWin )
	string		sControlNm, sFo, sWin
	PopupMenu	$sControlNm, win = $sWin,	 value = ksAUTOSELECT
End


//static Function		GetColumn( sItem, lstAllChansAllRegs )
//// Returns column of  'lstAllChansAllRegs'  where  'sItem'  e.g.  'Peak_01'   is found
//	string  	sItem, lstAllChansAllRegs
//	variable	chan, reg, col = 0
//	GetChRg( sItem, chan, reg )				// chan  and  reg  are references which are changed
//	
//	nvar		gChans	= root:uf:evo:cfsr:gChannels	// 				
//	variable	ch, rg
//	for ( ch = 0; ch < gChans; ch += 1 )			// loop through all chans and all regions...
//		variable	nRegs	= RegionCnt( ch )	// ... in the same order as the listbox columns have been built earlier...
//		for ( rg = 0; rg < nRegs; rg += 1 )			// ... and increment the column counter				
//			// printf "\t\tGetColumn( \t%s\tch:%2d \tchan:%2d\trg:%2d \treg:%2d \r", sItem, ch, chan, rg, reg
//			if ( chan == ch  &&  reg == rg )		// If the looped  chan  and  reg   match the passed  'sItem'...  
//				return	col				// ...we found the column where  'sItem'  is displayed
//			endif
//			col += 1
//		endfor
//	endfor
//	return	kNOTFOUND		// here we return kNOTFOUND which should never happen as we checked the existence of 'sItem' in 'lst' before calling this function	
//End	
//
//
//static Function		GetChRg( sItem, ch, rg )
//	string  	sItem
//	variable	&ch, &rg
//	variable	len	=strlen( sItem )
//	ch	= str2num( sItem[ len-2, len-2 ] )
//	rg	= str2num( sItem[ len-1, len-1 ] )		// !!! Assumption naming :   'name_ChRg'
//End	


//strconstant	klstDSP_TRACES	= "Only traces;traces + avg;only average"
//
//Function		fDspTraces( s )
//	struct	WMPopupAction	&s
//	fPopup_struct1( s )											// sets the global variable
//	string  	sPath	= ksEVOCFG_DIR 							// e.g.  'C:Epc:Data:EvalCfg:'   or   'C:UserIgor:Ced:'  , must contain drive letter
//	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
//	string  	sFo	 	= GetUserData( 	s.win,  s.ctrlName,  "sFo" )			// e.g.  'root:uf:evo:' 
//	string  	sSubDir	= ReplaceString( "root:uf:", sFo, "" )		  		// e.g.  'root:uf:evo:' -> 'evo:'
//	  printf "\t%s\t\t\t\t\  \r",  pd(sProcNm,13)
//End
//
//Function		fDspTracesLst( sControlNm, sFo, sWin )
//	string		sControlNm, sFo, sWin
//	PopupMenu	$sControlNm, win = $sWin,  	 value = klstDSP_TRACES
//End


Function 		fResultTxtbox( s )
	struct	WMCheckboxAction	&s
	print s.CtrlName, s.checked
	DispHideEvalTextboxAllChans()					// displays or hides the already existing evaluation results in the textbox in the graph window
End


// 060216
static strconstant		ksfEVO_HELP_WND	= "Eval Help"   
static strconstant		ksfEVO_HELP_PATH	= "FEvalHelp.txt"

Function		fEvHelp_( s )
	struct	WMButtonAction	&s
	if (  s.eventCode == kCCE_mouseup ) 
		string  	sPath = FunctionPath( "" )						// Path to file containing this function.
		if ( cmpstr( sPath[0], ":" ) == 0 )
			InternalError( "Could not locate file '" + ksfEVO_HELP_PATH + "' ." )
			return -1										// This is the built-in procedure window or a packed procedure (not a standalone file)   OR  procedures are not compiled.
		endif
		
		sPath = ParseFilePath( 1, sPath, ":", 1,0 ) + ksfEVO_HELP_PATH// Create path to the help file.
		printf "\t\tfEvHelp( s ) \thelp path: '%s' \r", sPath
	
		OpenNotebook	/K=1	/V=1	/N=$ksfEVO_HELP_WND   sPath	// visible, could also use /P=symbpath...
		MoveWindow /W=$ksfEVO_HELP_WND	1, 1, 1, 1			// restore from minimised to old size

	endif
End
// ......... 060216


Function	fClearResSelDraw_( s )
// Called when a button is pressed.  ALSO CALLED when moving the mouse over a button.  See  'fButtonProc_struct()'  on how to avoid this event.
	struct	WMButtonAction	&s
	if (  s.eventCode == kCCE_mouseup ) 
		string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
		printf "\t\t%s(s)\t\t%s\t%d\t \r",  sProcNm, pd(s.CtrlName,26), mod( DateTime,10000)
		wave	wFlags		= root:uf:evo:lb:wSRFlagsDr
		ClearResultSelection( wFlags )
	endif
End

Function		fResSelectDraw( s )
// Displays and hides the Draw Result selection listbox panel
	struct	WMCheckboxAction	&s
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	printf "\t\t%s(s)\t\t%s\tchecked:%d\t \r",  sProcNm, pd(s.CtrlName,26), s.checked
	if (  s.checked ) 
		PanelRSUpdateDraw_()
	else
		PanelRSHideDraw_()
	endif
End

Function	fClearResSelTable_( s )
// Called when a button is pressed.  ALSO CALLED when moving the mouse over a button.  See  'fButtonProc_struct()'  on how to avoid this event.
	struct	WMButtonAction	&s
	if (  s.eventCode == kCCE_mouseup ) 
		string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
		printf "\t\t%s(s)\t\t%s\t%d\t \r",  sProcNm, pd(s.CtrlName,26), mod( DateTime,10000)
		wave	wFlags		= root:uf:evo:lb:wSRFlagsPr
		ClearResultSelection( wFlags )
	endif
End

Function		fResSelectTable( s )
// Displays and hides the Print/ToFile Result selection listbox panel
	struct	WMCheckboxAction	&s
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	printf "\t\t%s(s)\t\t%s\tchecked:%d\t \r",  sProcNm, pd(s.CtrlName,26), s.checked
	if (  s.checked ) 
		PanelRSUpdateTable_()									// Bebuild the panel completely as in meantime while the panel perhaps was invisible e.g the number of channels may have changed
	else
		PanelRSHideTable_()
	endif
End



//---------------------------------------------------------------------------------------------------------------------------------------------------------------------


Function		fShowScript_( s )
	struct	WMCheckboxAction	&s
	// print 	s.ctrlname, s.checked
	string  	sFolder	= ksfEVO
	svar		gsScript	= $"root:uf:" + sFolder + ":gsScript"
	DisplayHideNotebook( s.checked, sFolder , ":script", ksSCRIPTEXTRACTED_NB_WNDNAME_, gsScript )		// 050205
End



Function		fEvPreferDlg( s )
// Called when a button is pressed.  ALSO CALLED when moving the mouse over a button.  See  'fButtonProc_struct()'  on how to avoid this event.
	struct	WMButtonAction	&s
	if (  s.eventCode == kCCE_mouseup ) 
		PreferencesEvalDlg()
	endif
End

Function		PreferencesEvalDlg()	
	string  	sFolder	= ksfEVO
	string  	sWin		= "PanelPrefEval"
	InitPanelPreferencesEval( sFolder, ":dlg:tPnPref" )	// constructs the text wave  'root:uf:evo:dlg:tPnPref'  defining the panel controls
	ConstructOrDisplayPanel(  sWin, "Preferences-Eval" , sFolder,  ":dlg:tPnPref",  100, 95 )
	PnLstPansNbsAdd( ksfEVO,  sWin )
End

Function		InitPanelPreferencesEval( sFolder, sPnOptions )
	string  	sFolder, sPnOptions
	string		sPanelWvNm = "root:uf:" + sFolder + sPnOptions
	variable	n = -1, nItems = 30
	make /O /T /N=(nItems)	$sPanelWvNm
	wave  /T	tPn	=		$sPanelWvNm
	//					TYPE		NAM						TXT			
	n += 1;	tPn[ n ] =	"PN_CHKBOX;	root:uf:evo:cfsr:gbDispAllPnts		;Display all points;	"
	n += 1;	tPn[ n ] =	"PN_SETVAR;	root:uf:dlg:gnWarningLevel		;Warning level (none:1, all:4); 	20; 	%1d ;1,4,1;	"			
	n += 1;	tPn[ n ] =	"PN_CHKBOX;	root:uf:dlg:gbWarningBeep		;Warning beep"
	redimension  /N = (n+1)	tPn 
End



Function		fEvDataUtilDlg( s )
// Called when a button is pressed.  ALSO CALLED when moving the mouse over a button.  See  'fButtonProc_struct()'  on how to avoid this event.
	struct	WMButtonAction	&s
	if (  s.eventCode == kCCE_mouseup ) 
		DataUtilitiesDlg_evo()
	endif
End


Function		fEvStimDlg( s )
// Called when a button is pressed.  ALSO CALLED when moving the mouse over a button.  See  'fButtonProc_struct()'  on how to avoid this event.
	struct	WMButtonAction	&s
	if (  s.eventCode == kCCE_mouseup ) 
		print 	s.ctrlname
//		string  	sFolder	= ksfEVO		
//		DisplayOptionsStimulus( sFolder, 25, 0, kPN_DRAW )
		DisplayOptionsStimulus_evo(  25, 0, kPN_DRAW )
	endif
End



//---------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Saving and recalling panel settings

Function		fSettingsDlg( s )
// Called when a button is pressed.  ALSO CALLED when moving the mouse over a button.  See  'fButtonProc_struct()'  on how to avoid this event.
	struct	WMButtonAction	&s
	if (  s.eventCode == kCCE_mouseup ) 
		SettingsPanel(  30, 0, kPN_DRAW ) 
	endif
End




Function		SettingsPanel( xPos , yPos, nMode  )
	variable	xPos, yPos
	variable 	nMode
	string  	sFBase		= "root:uf:"
	string  	sFSub		= ksfEVO_	
	string  	sWin			= "set"
	string		sPnTitle		= "Settings: Save and recall "
	string		sDFSave	= GetDataFolder( 1 )							// The following functions do NOT restore the CDF so we remember the CDF in a string .
	PossiblyCreateFolder( sFBase + sFSub + sWin )
	SetDataFolder sDFSave										// Restore CDF from the string  value
	InitSettingsPanel( sFBase + sFSub , sWin )							// fills big text wave  'sPnOptions' (=wPn)  with all information about the controls necessary to build the panel
	Panel3Sub(   sWin,	sPnTitle, 	sFBase + sFSub ,   xPos, yPos , nMode ) 	// Compute the location of panel controls and the panel dimensions. Draw the panel displaying and hiding needed/unneeded controls
	PnLstPansNbsAdd( ksfEVO,  sWin )
End


Function		InitSettingsPanel( sF, sPnOptions )
// 	Same Function for  FPULS  and  Eval .  The actions procs are also similar functions in  FPULS  and  Eval , but the names differ... ( see  FPAcqScript.ipf  and  FPDispStim.ipf )
// 	Here are the samples united for  many  radio button  and  checkbox  varieties.....
	string  	sF, sPnOptions
	string  	sPanelWvNm	= sF + sPnOptions 
	variable	n = -1, nItems = 35
	make /O /T /N=(nItems) 	$sPanelWvNm
	wave  /T	tPn		= 	$sPanelWvNm

	//				Type	 NxL Pos MxPo OvS	Tabs	Blks	ModeName		RowTi			ColTi			ActionProc	XBodySz	FormatEntry	Initval	Visibility	SubHelp

//	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:		,:		,:			dum8a:		Save and recall settings:	:	:			:		:			:			:		:	"		//	single separator needs ','  for 'Blks'  and 'dummy' for 'Name'
	n += 1;	tPn[ n ] =	"STR:  1:	0:	4:	1:	°:		,:		1,°:			svSave:		Save:		:			fSaveSets():	120:		:			:			:		:	"		//  	single  SetVariable inputing a String
	n += 1;	tPn[ n ] =	"PM:	   0:	2:	4:	1:	°:		,:		1,°:			pmRecal:		:			Recall:		fRecallSets():	120:		fRecallSetsLst():	:			:		:	"		// 	1-dim  popmenu (1 row)
	n += 1;	tPn[ n ] =	"BU:    1:	0:	4:	0:	°:		,:		1,°:			buDeflt:		Defaults:		:			fDefaults():		:		:			:			:		:	"		//	single button
	n += 1;	tPn[ n ] =	"CB:	   0:	1:	4:	1:	°:		,:		1,°:			cbAlDel:		Allow delete:	:			fCbAllowDelete()::		:			:			:		:	"		// 	1-dim  popmenu (1 row)
	n += 1;	tPn[ n ] =	"PM:	   0:	2:	4:	1:	°:		,:		1,°:			pmDelet:		Delete:		:			fDeleteSets():	120:		fRecallSetsLst():	:			:		:	"		// 	1-dim  popmenu (1 row)
//	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:		,:		,:			dum8e:		More panels and options:	:	:			:		:			:			:		:	"		//	single separator needs ','  for 'Blks'  and 'dummy' for 'Name'

	redimension   /N=(n+1)	tPn
End


Function		fDefaults( s )
// Called when a button is pressed.  ALSO CALLED when moving the mouse over a button.  See  'fButtonProc_struct()'  on how to avoid this event.
	struct	WMButtonAction	&s
	if (  s.eventCode == kCCE_mouseup ) 
		string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
		string  	sFo	 	= GetUserData( 	s.win,  s.ctrlName,  "sFo" )			// e.g.  'root:uf:evo:' 
		 printf "\t\t%s(s)\t\t%s\t%s\t%s\t\t \r",  pd(sProcNm,15),  pd(s.CtrlName,31), pd(sFo,17), pd(s.win,9)

		string  	sWin		= s.win
		string  	sSavePn	= "de"
		ClearFolderVars( sFo + sWin + ":" )				// first kill all variables so that they do not exist in 'PnInitVars()' . If they existed the panel could never shrink again. Different approach: Overwrite variables in 'PnInitVars()' without existance-checking (->other problems..)
		Panel3Main(   sSavePn, "Evaluation Details3", "root:uf:" + ksfEVO_, 2, 95 ) // Compute the location of panel controls and the panel dimensions. Draw the panel displaying and hiding needed/unneeded controls

//		UpdateDependent_Of_AllowDelete( s.Win, "root_uf_evo_de_cbAlDel0000" )	
//		UpdateDependent_Of_AllowDelete( s.Win, "root_uf_evo_set_cbAlDel0000" )	

//		ControlUpdate	/A /W = $s.win

// todo : also  reset  regions and cursors  = wCRegion
	endif
End


static strconstant 	sEVALCFG_REGION_EXT	= "ecf"
static strconstant 	sEVALCFG_PANEL_EXT	= "txt"

Function		fSaveSets( s ) 
// Demo: this  SetVariable control  for inputing a string	...............WITHOUT fSetvar_struct1( s )	
	struct	WMSetvariableAction    &s
//	fSetvar_struct1( s )											// sets the global variable
	string  	sPath	= ksEVOCFG_DIR							// e.g.  "C:Epc:Data:EvalCfg:"   or   "C:UserIgor:Ced:" , must contain drive letter
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	string  	sFo	 	= GetUserData( 	s.win,  s.ctrlName,  "sFo" )			// e.g.  'root:uf:evo:' 
	string  	sSubDir	= ReplaceString( "root:uf:", sFo, "" )		  		// e.g.  'root:uf:evo:' -> 'evo:'
	string  	sSavePn	= "de"
	string  	sLoadPath	= ksEVOCFG_DIR + sSubDir + s.Win				// e.g.  'C:Epc:Data:EvalCfg:' + 'Eval:' + 'Set'    or   'C:UserIgor:Ced:' + 'Acq' + 'PnMisc'  , must contain drive letter

	string  	sFileBase	= s.sval
	//printf "\t\t%s(s)\t\tCo:\t%s\tFo:%s\tWi:\t%s\tPa:\t%s\tSu:\t%s\tFi:\t'%s' '%s' \r",   pd(sProcNm,15), pd(s.CtrlName,31), pd(sFo,17), pd(sWin,9), pd(sPath,17), pd(sSubDir,17), sFileBase, "txt + ecf"

	SaveAllFolderVars( 		sFo, sSavePn, sPath + sSubDir + s.Win, sFileBase, sEVALCFG_PANEL_EXT )		// .txt
	SaveRegionsAndCursors( 	sFo, sSavePn, sPath + sSubDir + s.Win, sFileBase, sEVALCFG_REGION_EXT )		// .ecf

	string  /G	$"root:uf:glstPnSvFilesEvDet3" = ListOfMatchingFiles( sLoadPath, "*."+ sEVALCFG_PANEL_EXT, FALSE )	// Add this new file name entry to the global list of the PanelSave-files so that this file is included in the popupmenu already on ENTRY of the next fRecallSets()	

End

Function		SaveRegionsAndCursors( sFolder, sPanel, sPath, sFileBase, sFileExt )
//  'SaveRegionsAndCursors()'  and  'SaveAllFolderVars()'  are companion functions
	string  	sFolder, sPanel, sPath, sFileBase, sFileExt 
	PossiblyCreatePath( sPath )
	string  	sFilePath	= sPath + ":" + sFileBase + "." + sFileExt 
	save /O /T root:uf:evo:evl:wCRegion	as sFilePath 					// store all cursor region variables to disk under the name 'wCRegion' 
End	



Function		fDeleteSets( s )
	struct	WMPopupAction	&s
	fPopup_struct1( s )											// sets the global variable
	string  	sPath	= ksEVOCFG_DIR 							// e.g.  'C:Epc:Data:EvalCfg:'   or   'C:UserIgor:Ced:'  , must contain drive letter
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	string  	sFo	 	= GetUserData( 	s.win,  s.ctrlName,  "sFo" )			// e.g.  'root:uf:evo:' 
	string  	sSubDir	= ReplaceString( "root:uf:", sFo, "" )		  		// e.g.  'root:uf:evo:' -> 'evo:'
//	string  	sSavePn	= "de"
	string  	sLoadPath	= ksEVOCFG_DIR + sSubDir + s.Win				// e.g.  'C:Epc:Data:EvalCfg:' + 'Eval:' + 'Set'    or   'C:UserIgor:Ced:' + 'Acq' + 'PnMisc'  , must contain drive letter
	string  	sFileNm	= StringFromList( s.popNum-1, ListOfMatchingFiles( sLoadPath, "*." + sEVALCFG_PANEL_EXT, FALSE ) )
	printf "\t\t%s(s)\t\tCo:\t%s\tFo:%s\tWi:\t%s\tPa:\t%s\tSu:\t%s\t->\t%s -> Sel:%2d ~ %s \r",  sProcNm, pd(s.CtrlName,29), pd(sFo,17), pd(s.Win,9), pd(sPath,17), pd(sSubDir,9), sLoadPath, s.popNum, sFileNm

	DeleteFile	sPath + sSubDir + s.Win + ":" + sFileNm 					// Delete the file containing the panel variables.  The file has the extension  'txt' .
	string sFileNmEcf = StripExtensionAndDot( sFileNm ) + "." + sEVALCFG_REGION_EXT
	DeleteFile	sPath + sSubDir + s.Win + ":" + sFileNmEcf 					// Delete the file containing the cursors and regions in wave wCRegion.  The file has the extension  'ecf' .

	string  /G	$"root:uf:glstPnSvFilesEvDet3" = ListOfMatchingFiles( sLoadPath, "*."+ sEVALCFG_PANEL_EXT, FALSE )// Remove the deleted entry from the global list of the PanelSave-files so that this file is excluded from the popupmenu already on ENTRY of the next fRecallSets()	
	PopupMenu	$s.ctrlName, win = $s.Win, mode = 0 					//display the title ('Delete') in the box but not any of the files . (Even better would be '---' or blank).
End

Function		fRecallSets( s )
	struct	WMPopupAction	&s
	fPopup_struct1( s )											// sets the global variable
	string  	sPath	= ksEVOCFG_DIR 							// e.g.  'C:Epc:Data:EvalCfg:'   or   'C:UserIgor:Ced:'  , must contain drive letter
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	string  	sFo	 	= GetUserData( 	s.win,  s.ctrlName,  "sFo" )			// e.g.  'root:uf:evo:' 
	string  	sSubDir	= ReplaceString( "root:uf:", sFo, "" )		  		// e.g.  'root:uf:evo:' -> 'evo:'
	string  	sSavePn	= "de"
	string  	sLoadPath	= ksEVOCFG_DIR + sSubDir + s.Win				// e.g.  'C:Epc:Data:EvalCfg:' + 'Eval:' + 'Set'    or   'C:UserIgor:Ced:' + 'Acq' + 'PnMisc'  , must contain drive letter

	string  	sFileNm	= StringFromList( s.popNum-1, ListOfMatchingFiles( sLoadPath, "*." + sEVALCFG_PANEL_EXT, FALSE ) )	
	string  	sThisControl = StripFolders( s.ctrlName )

	// Recall the panel variables.	  The file has the extension  'txt' .
	ClearFolderVars( sFo + sSavePn + ":" )				// first kill all variables so that they do not exist in 'PnInitVars()' . If they existed the panel could never shrink again. Different approach: Overwrite variables in 'PnInitVars()' without existance-checking (->other problems..)
	RecallAllFolderVars( sFo, sSavePn, sPath + sSubDir + s.Win, sFileNm, sThisControl )	// ...and update panel with user settings
	Panel3Main(   sSavePn, "Evaluation Details3", "root:uf:" + ksfEVO_, 2, 95 ) // Compute the location of panel controls and the panel dimensions. Draw the panel displaying and hiding needed/unneeded controls

	// Recall the cursors and regions.  The file has the extension  'ecf' .
	string sFileNmEcf = StripExtensionAndDot( sFileNm ) + "." + sEVALCFG_REGION_EXT
	RecallRegionsAndCursors( sFo, sSavePn, sPath + sSubDir + s.Win, sFileNmEcf )	// 
	 printf "\t\t%s(s)\t\tCo:\t%s\tFo:%s\tWi:\t%s\tPa:\t%s\tSu:\t%s\t->\t%s -> Sel:%2d ~ %s + %s [%s] \r",  sProcNm, pd(s.CtrlName,29), pd(sFo,17), pd(s.Win,9), pd(sPath,17), pd(sSubDir,9), sLoadPath, s.popNum, sFileNm, sFileNmEcf, sThisControl

//	UpdateDependent_Of_AllowDelete(  sWin, "root_uf_evo_de_cbAlDel0000" )	
//	UpdateDependent_Of_AllowDelete(  sWin, "root_uf_evo_set_cbAlDel0000" )	
End


Function		fRecallSetsLst( sControlNm, sFo, sWin )
// callled via 'fPopupListProc3()'
	string		sControlNm, sFo, sWin
	string  	sSubDir	= ReplaceString( "root:uf:", sFo, "" )		  		// e.g.  'root:uf:evo:' -> 'evo:'
	string  	sLoadPath	=  ksEVOCFG_DIR + sSubDir + sWin		
	 print "\t\t\tfRecallSetsLst()", sControlNm, sFo , sWin, "->", sLoadPath
	svar	/Z	lstFiles	= $"root:uf:glstPnSvFilesEvDet3"	
	if ( ! svar_Exists( lstFiles ) )										// Fill list once when/before the panel is constructed for the first time. Later the existing list is updated by 'Save' and 'Delete' 
		string  /G	$"root:uf:glstPnSvFilesEvDet3" = ListOfMatchingFiles( sLoadPath, "*."+ sEVALCFG_PANEL_EXT, FALSE )// Construct the current file list.
	endif
	PopupMenu	$sControlNm, win = $sWin,  value =  #"root:uf:glstPnSvFilesEvDet3"	// Retrieve the current list as updated and stored by 'Save' and 'Delete'
End


static Function		RecallRegionsAndCursors( sFolder, sWin, sPath, sFileName )
// Reads regions and cursors from  settings  file
	string		sFolder, sWin, sPath, sFileName
	string  	sFilePath	= sPath + ":"  + sFileName 
	  printf "\t\t\tRecallRegionsAndCursors()\t%s\t%s\trecalled from\t'%s'\t  \r", pd(sFolder,17), pd(sWin,9), sFilePath
	loadwave /O /T /A  /Q 				 sFilePath					// read all cursor region variables from disk keeping the wave name 'wCRegion' 
	if ( V_Flag == 1 )					// the number of waves loaded
		duplicate	/O 	wCRegion			root:uf:evo:evl:wCRegion
		killWaves	wCRegion
		RescaleAllCursors()
	else
		Alert( kERR_FATAL,  " RecallRegionsAndCursors()  could not load wCRegion from '" + sFilePath + "' " )	
	endif
End


Function		fCbAllowDelete( s )
// Checkbox action proc enabling or graying the 'Delete'-Popupmenu in the same tabgroup. Disabling by default prevents that the user accidentally erases his saved panel settings
	struct	WMCheckboxAction	&s
	string  	sProcNm 	= GetUserData( 	s.win,  s.ctrlName,  "sProcNm" )
	  printf "\t\t%s(s)\t\t%s\tb:%2d  =\t%d : from control  [s.win:%s] \r",  sProcNm, pd(s.CtrlName,26), s.checked, PnValC( s.CtrlName ), s.win
	UpdateDependent_Of_AllowDelete(  s.win, s.CtrlName )	
End

Function		UpdateDependent_Of_AllowDelete(  sWin, sCtrlName )	
	string		sWin, sCtrlName
	ControlInfo	/W = $sWin $sCtrlName
	variable	bChecked			= V_Value
	string  	sThisControl		= StripFolders( sCtrlName )
	string  	sTheOtherControl	= "pmDelet0000"						// the control to be modified without folders
	string  	sCoNm   = ReplaceString( sThisControl, sCtrlName, sTheOtherControl )	// for this to work both controls must reside in the same folder
	PopupMenu  	$sCoNm, win = $sWin, mode = 0 						//display the title ('Delete') in the box but not any of the files . (Even better would be '---' or blank).
																// without this  'fRecallSetsLstT()'  will pop up the first entry of the files list in the 'Delete' box
	PopupMenu	$sCoNm, win = $sWin,  disable	=  bChecked  ?  0 :  kDISABLE // : kHIDE  // : kDISABLE
End

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function		fCfsHeader( s )
	struct	WMCheckboxAction	&s
// 2009-10-22 modify for Igor6  (remove endless loop)
//	fRadio_struct3( s )											// Check / uncheck all the radio buttons of this group
End

Function		CfsHeaderInfo()
	nvar		nCfsHeaderInfo		=  root:uf:evo:de:raCfsHeadr00	// as it is a radio button the last 2 indices are stripped
	return	nCfsHeaderInfo
End

static  strconstant	lstCFSHEADER	= "no info,short,long,full info,"	// "no info;short;long;full info;"

Function	/S	fCfsHeaderLst( sBaseNm, sF, sWin )
	string  	sBaseNm, sF, sWin 
	return	lstCFSHEADER
End


//====================================================================================================================================
//  Common file name management for result (=average and table) functions
//  the idea is to use as few globals as possible and to hide as much of the internals to the calling functions (like 'AddToAverage() '  or  'AddDirectlyToFile() ' )

		 Function	/S	ConstructNextResultFileNmA_( sCfsPath, sExt )
// Check if  ANY of the channels has already a result file with this name, if yes skip this name for ALL channels (just to avoid confusion, theoretically it could be used for other channels)
// Flaw  / limit  : channels 0-9  and  36 indices
	string		sCfsPath, sExt
	variable	NamingMode	= kDIGITLETTER							// 2 naming modes are allowed.   kDIGITLETTER is prefered to avoid confusion with the already used mode kTWOLETTER (used for Cfs file naming) 
	string		sFilePath, sFilePathShort 

	if ( ItemsInList( sCfsPath, "." ) == 2 ) 									// or check if there is an extension 'dat'								
		sFilePathShort	= StripExtensionAndDot( sCfsPath )					// Has dot : is the original  CFS.dat filepath. Convert to average file name by removing the dot and the 1..3 letters...
	else
		sFilePathShort	= RemoveIndexFromFileNm( sCfsPath )				// Has no dot : is an average filepath containing the index of the average but no channnel and no file extension
	endif

	 printf "\r\t\tConstructNextResultFileNmA(1 '%s', '%s' )\tstripping to \t\t%s \r",  sCfsPath, sExt, sFilePathShort
	variable	ch, n = 0, bFileNmFree
	do
		for ( ch = 0; ch <= 9; ch += 1 )									// !!!! limited to channels 0 to 9
			sFilePath	= BuildFileNm( sFilePathShort, ch, n, sExt, NamingMode )	// ..there can be multiple table files for each cfs file so we append a postfix
			if ( FileExists( sFilePath ) )
				bFileNmFree = FALSE
				// printf "\t\tConstructNextResultFileNmA(2 '%s'\t  )\talready used    \t%s \r",  sCfsPath, sFilePath
				break
			endif	
			bFileNmFree = TRUE
		endfor
		n += 1													// try the next auto-built file name
	while ( bFileNmFree == FALSE )
		
	 printf "\t\tConstructNextResultFileNmA(   '%s', '%s' )\tbuilding  \t\t%s \r",  sCfsPath, sExt, sFilePath
	string  	sFilePathIdx	= RemoveChanFromFileNm( StripExtensionAndDot( sFilePath ) )	// !!!  xxx_7_ch1.avg  ->  xxx_7
	 printf "\t\tConstructNextResultFileNmA(3 '%s'\t     )\treturns next free\t%s \r",  sCfsPath, sFilePathIdx

	return	sFilePathIdx
End

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//  Auto-building  filenames  e.g.  for  Average files
//  Limitation:  there is only 1 character reserved for indexing so there are at most 36 files 

static strconstant	ksCHSEP	= "_ch"
static strconstant	ksIDXSEP	= "#"

static Function   /S	BuildFileNm( sCfsFileBase, ch, n, sExt, NamingMode )
// builds  result file name (e.g. average, table) when  path, file and dot (but no extension)  of CFS data  is given (and channel and index) 
// 2 naming modes are allowed.  kDIGITLETTER is prefered to avoid confusion with the already used mode kTWOLETTER (used for Cfs file naming) 
// e.g.  Cfsdata.dat, ch:1, n:6 -> Cfsdata_1f.avg  or  Cfsdata_1f.fit
	string		sCfsFileBase, sExt
	variable	ch, n, NamingMode
	string		sIndexString	= SelectString( NamingMode == kDIGITLETTER,  IdxToTwoLetters( n ),  IdxToDigitLetter( n ) ) 
	return	sCfsFileBase + ksIDXSEP + sIndexString + ChannelSpecifier_( ch ) + "." + sExt	// channel number as  _1 digit  in name  e.g.  Cfsdata.dat, ch:1, n:6  ->	Cfsdata_f_ch1.avg	or  Cfsdata_f_ch1.fit
End

	 Function   /S	ChannelSpecifier_( ch )
	variable	ch
	return	ksCHSEP + num2str( ch )
End

static Function   /S	RemoveChanFromFileNm( sFilePathWithChan )	
// sFilePathWithChan   is the leading part of an auto-built filepath containing  drive, dir, basename, index and channel  but no file extension
// The index part (including the index separator) will be removed .   Must match  'ChannelSpecifier_()'
	string  	sFilePathWithChan
	string  	sFilePathNoChan	= RemoveEnding( RemoveEnding( sFilePathWithChan ), ksCHSEP )	
	return	sFilePathNoChan
End

static Function   /S	RemoveIndexFromFileNm( sFilePathWithIndex )	
// sFilePathWithIndex   is the leading part of an auto-built filepath containing  drive, dir, basename and possibly an index but no channel and no file extension
// The index part (including the index separator) will be removed .   Must match  'BuildFileNm()'
// !!! Assumes that the actual index is just ONE character (  NamingMode = kDIGITLETTER  -> index = IdxToDigitLetter()    )
	string  	sFilePathWithIndex
	variable	len	= strlen( sFilePathWithIndex )
	string  	sFilePathNoIndex
	if ( cmpstr( sFilePathWithIndex[ len-2, len-2 ], ksIDXSEP ) == 0 )							// only if there is an index at the end...
	  	sFilePathNoIndex	= RemoveEnding( RemoveEnding( sFilePathWithIndex ), ksIDXSEP )	//..we remove it
	else
	  	sFilePathNoIndex	= sFilePathWithIndex										// if no index is recognised the path is returned unchanged
	endif
	return	sFilePathNoIndex
End

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// 2009-10-23
Function		fPopup_struct1( s )
// executed when the user selected an item from the listbox
	struct	WMPopupAction	&s
	string  	sFoPmVar	= ReplaceString( "_", s.ctrlName, ":" )   	//  e.g. root_uf_evo_evl_gpopupVar000 -> root:uf:evo:evl:gpopupVar000
	nvar	 /Z	nTmp	= $sFoPmVar 							// set the global variable with the popup value to store state
	if ( nvar_Exists( nTmp ) )
		nTmp	= s.popNum									// the global variable has already been constructed previously
 		// printf "\t\tfPopup_struct1 :\t'%s' ->\t%s\t exists and has been set \tto %d... \t[will call proc if found: '%s()' <--todo possibly strip indices\tHelp: '%s' ]\r", s.ctrlName, sFoPmVar, nTmp, s.ctrlName, s.ctrlName
	else
		variable	/G	$sFoPmVar = 1								// the global variable is constructed now and set to refelect the first list entry.  Setting it to 0 would lock and effectively disable the popmemu 
		printf "\t\tfPopup_struct1 :\t'%s' ->\t%s\t does not exist. Initialised \tto %d... \t[will call proc if found: '%s()' <--todo possibly strip indices\tHelp: '%s' ]\r", s.ctrlName, sFoPmVar, nTmp, s.ctrlName, s.ctrlName
	endif	

	// ControlInfo		/W=$s.win	$s.ctrlName	; 		print "\t\t\t\t\t\t", s.ctrlName , sFoPmVar, V_flag ,  V_Disable , S_recreation

End



