//
// UF_Utilities.Ipf   :	Routines for	Filtering data
//							Cutting out and storing episodes
//							AXIS  and  SCALEBARS

#pragma rtGlobals=1								// Use modern global access method.

#include <Axis Utilities>

// General  'Includes'
#include "UFCom_Constants"
#include "UFCom_Panel"

//#include "UFPE_Constants3"

//=================================================================================================================================================================
//  DATA  UTILITIES  PANEL

static strconstant	ksPN_NAME		= "uta"			// Panel name   _and_   subfolder name   _and_  section keyword in INI file
static strconstant	ksPN_TITLE		= "DataUtilities"		// Panel title
static strconstant	ksPN_CTRLBASE	= "DataUtils"		// The  button base name (without prefix root:uf... and postfix 0000) in the main panel displaying and hiding THIS subpanel
static strconstant	ksPN_INISUB		= "FPuls"			// The  INI subfolder  below folder 'acq'   and   the  INI file location (here in a subdirectory to FPulse=FPulseMain.ipf)
static strconstant	ksPN_INIKEY		= "Wnd"			// The  keyword in the INI file (here always 'Wnd' as we are dealing with window positions and visibility)


Function		fDataUtils_a( s ) 
// The  Button action procedure of the button in the main panel displaying and hiding THIS subpanel.  Unfortunately we can not wrap this in a function because of the specific Panel creation function name below (due to hook function)
	struct	WMButtonAction	&s
	nvar		state		= $ReplaceString( "_", s.ctrlname, ":" )					// the underlying button variable name is derived from the control name
	// printf "\t\t\t\t%s\tvalue:%2d   \t\t%s\t%s\t%s\t \r",  UFCom_pd( s.ctrlname, 25),  state, UFCom_pd(ksPN_INISUB  ,9), UFCom_pd(ksPN_NAME ,9), UFCom_pd( ksPN_INIKEY ,9)	
	string  	sIniBasePath	= FunctionPath( ksFP_APP_NAME )					// the Ini file containing the window position will be written in a subdirectory parallel to UF_PulseMain.ipf 
	UFCom_WndVisibilitySetWrite_( ksACQ, ksPN_INISUB, ksPN_NAME, ksPN_INIKEY, state, sIniBasePath )
	if ( state )															// if we want to  _display_  the panel...
		if ( WinType( ksPN_NAME ) != UFCom_WT_PANEL )						// ...and only if the panel does not yet  exist ..
			PanelDataUtilities_a( UFCom_kPANEL_DRAW )						// *** specific ***...we must build the panel
		else
			UFCom_WndUnhide( ksPN_NAME )								//  display again the hidden panel 
		endif
	else
		UFCom_WndHide( ksPN_NAME )									//  hide the panel 
	endif
End


Function		PanelDataUtilities_a( nMode  )
// Create the panel.  Unfortunately we can not wrap this in a function because of the specific hook function name
	variable	nMode
	string  	sFBase		= "root:uf:"
	string  	sFSub		= ksACQ_	
	string		sDFSave		= GetDataFolder( 1 )								// The following functions do NOT restore the CDF so we remember the CDF in a string .
	UFCom_PossiblyCreateFolder( sFBase + sFSub + ksPN_NAME ) 
	InitDataUtilitiesPanel_a( sFBase + sFSub , ksPN_NAME )						// *** specific***: fills big text wave  'sPnOptions' (=wPn)  with all information about the controls necessary to build the panel
	UFCom_RestorePanel2Sub( ksACQ, ksFPUL, ksPN_NAME, ksPN_TITLE, sFBase, sFSub, ksPN_INISUB, ksPN_INIKEY, ksPN_CTRLBASE, nMode )
	SetWindow		$ksPN_NAME,  hook( $ksPN_NAME ) = fHookUta			// *** specific *** 
	SetDataFolder sDFSave												// Restore CDF from the string  value
	//UFCom_LstPanelsSet( ksACQ, ksfACQVARS , AddListItem( ksPN_NAME, UFCom_LstPanels( ksACQ, ksfACQVARS ) ) )					// add this panel to global list so that we can remove in on Cleanup or Exit
	UFCom_LstPanelsAdd( ksACQ, ksfACQVARS, ksPN_NAME )	
End


Function 		fHookUta( s )
// The window hook function detects when the user moves or resizes or hides the panel  and stores these settings in the INI file
	struct	WMWinHookStruct &s
	string  	sIniBasePath	= FunctionPath( ksFP_APP_NAME )					// the Ini file containing the window position will be written in a subdirectory parallel to UF_PulseMain.ipf 
	return	UFCom_WndUpdateLocationHook( s, ksACQ, ksFPUL, ksPN_INISUB, ksPN_INIKEY, ksPN_CTRLBASE, sIniBasePath )
End


Function		InitDataUtilitiesPanel_a( sF, sPnOptions )
	string  	sF, sPnOptions
	string  	sPanelWvNm	= sF + sPnOptions 
	variable	n = -1, nItems = 35
	make /O /T /N=(nItems) 	$sPanelWvNm
	wave  /T	tPn		= 	$sPanelWvNm
	//				Type	 NxL Pos MxPo OvS	Tabs	Blks	Mode	Name		RowTi			ColTi			ActionProc		XBodySz	FormatEntry						Initval	Visibility	SubHelp
	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:	,:	,:		dum1:		Filtering:			:			:				:		:								:		:		:				"		
	n += 1;	tPn[ n ] =	"BU:    1:	0:	3:	0:	°:	,:	1,°:		buFiltAppl:		UFPE_fFilterTitles():	:			fFilterApply_a():		:		42000,42000,42000~56000,56000,56000:	~0:		:		Apply or Remove Filter:"	//  	
	n += 1;	tPn[ n ] =	"PM:	   0:	1:	3:	0:	°:	,:	1,°:		pmFiltType:	:				:			:				80:		UFPE_fFilterTypePops():				~3:		:		Filter Type:		"	// 	
	n += 1;	tPn[ n ] =	"SV:    0:	2:	3:	0:	°:	,:	1,°:		svFiltFreq:		Freq:				:			:	  			50:		%5.0lf; .01,99000,1000:				~1000:	:		Filter frequency:		"
	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:	,:	,:		dum2:		Cutting stimulus data:	:			:				1:		:								:		:		:				"		
	n += 1;	tPn[ n ] =	"BU:    1:	0:	3:	0:	°:	,:	1,°:		gbCursrCut:	Cursors Set~Cursors Cut::			 UFPE_fCursorSetCut()::		42000,42000,46000~60000,57000,57000:	~0:		:		Cutting:			"	//  	
//	n += 1;	tPn[ n ] =	"BU:    1:	0:	3:	0:	°:	,:	1,°:		gbCursrCut:	Cursors Set~Cursors Cut::			 UFPE_fCursorSetCut()::		42000,42000,46000~60000,56000,56000:	~1:		:		Cutting:			"	//  	
//NO!n += 1;	tPn[ n ] =	"BU:    1:	0:	3:	0:	°:	,:	1,°:		gbCursrCut:	Cursors Set~Cursors Cut::			 UFPE_fCursorSetCut()::		UFPE_fCursorColorLst():				~1:		:		Cutting:			"	//  	
	n += 1;	tPn[ n ] =	"STR:  0:	1:	3:	1:	°:	,:	1,°:		gsCutPath:	 :				:			:				:		:								:		:		Cut Data path:		"	//
	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:	,:	,:		dum8:		:				:			:				:		:								:		:		:				"		
	n += 1;	tPn[ n ] =	"BU:    1:	0:	3:	0:	°:	,:	1,°:		buAxSclbar: 	Axes and  Scalebars:	:			UFPE_fAxisScalebars()::		:								:		:		Axes and  Scalebars:	"	//  	

	redimension   /N=(n+1)	tPn
End

//=================================================================================================================================================================
//	FILTERING  and  SMOOTHING

Function		fFilterApply_a( s )
	struct	WMButtonAction 	&s
	string  	sFolders	= ReplaceString( "root:uf:", GetUserData( 	s.win,  s.ctrlName,  "sFo" )	, "" )  + s.win	// e.g.  'root:uf:eva:'  ->  'eva:'  ->  'eva:util' 
	nvar		state		= $ReplaceString( "_", s.CtrlName, ":" )									// the underlying button variable name is derived from the control name
	 printf "\t\tfFilterApply_a\tstate:%2d\t%s\t%s\t%s\t \r" , state,  time(), UFCom_pd(s.win,8) , UFCom_pd(s.ctrlName,27)
	variable	CutoffFreq
	string  	sWvNm, lstWaves	= ""
	string  	sTNm, sTNL		=TraceNameList( "", ";", 1 )
	variable	t, tCnt			= ItemsInList( sTNL )
	variable	nFilterType		= UFPE_FilterType( sFolders )					// Get the filter type from the PopupMenu ( Gauss, Smooth,...)  

	printf "\t\tfFilterApply(b)\tstate:%2d\t%s\t%s\tCutofffreq:\t%7.1lf\tFTyp%2d %s)\tTraces:\t%2d\tTNL\t%s  \r", state, time(), UFCom_pd(s.win,8) , CutoffFreq, nFilterType, UFCom_pd(StringFromList( nFilterType, UFPE_lstFILTERTYPE),9) , tCnt, UFCom_pd( sTNL, 180 )
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
				CutoffFreq	= UFPE_FilterFreq( sFolders ) 
				printf "\t\tfFilterApply(c)\tstate:%2d\t%s\tCutofffreq:\t%7.1lf\tFTyp%2d %s)\tdx=SI*step:\t%12.6lf\tTrace:\t%2d/\t%2d\tTnm\t%s\twvs:\t%s  \r", state, UFCom_pd( sWvNm,16), CutoffFreq, nFilterType, UFCom_pd(StringFromList( nFilterType, UFPE_lstFILTERTYPE),9) , dltax, t, tCnt, UFCom_pd( sTNm, 12 ), UFCom_pd( lstWaves, 180 )

				UFPE_GeneralFilter( sWvNm, CutoffFreq, nFilterType, state )

			endif
		endif
	endfor
End

