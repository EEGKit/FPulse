//
//  UCom_DebugPrint.ipf 
//
 
#pragma rtGlobals=1							// Use modern global access method.

//===============================================================================================================================
//
// 	Allows to turn all debug print statements belonging to a specific code section ON and OFF.
// 	Works for any application / project.
//	In the application(s) just 1 simple line is required to construct AND retrieve the global variable  e.g.  if ( UFCom_DebugVar( "ShowStep1" ) ) 


// How it works:
// 	During the application initialisation there should be a call to  PanelDebugPrint( "PanelName" )  .  The panel may be initially hidden.
//	This calls  'UFCom_DebugCollectVars()   which loops through all source files (including Common files), finds all calls to 'UFCom_DebugVar()' ...
//	...and extracts the parameters from which the vertical checkbox array is built  e.g. 'gMaxControlWidth' .
// 	This checkbox is used to turn debug print statements on and off.
//	If there is no automatical call to PanelDebugPrint( "PanelName" )  during the application initialisation there must be a button for this purpose...
//	...or this function must be executed by the command line.
//	At this stage the framework is set up and additional debug prints can be added at any time at any place by inserting lines like
//		if ( UFCom_DebugVar( "ShowStep1" ) ) 
//			printf "\t\t variabvle1: %g \r", var1
//		endif 
//	To introduce the new debug variable   "ShowStep1"  the button  'Update Vars'  in the debug panel must be executed.

// Note:
// 	There is only 1 debug print panel for all applications.
//	If applications are added their debug print variables are appended to this one-and-only debug print panel.  
//	Some kind of a naming convention for the variable should be used to avoid confusion e.g  'FEvalVar1, FEvalVar2, FPVar1, FPVar2, FPVar3....   
//	Having  only 1 debug print panel for all applications simplifies the code considerably. 
// 	Having a separate debug print panel for every application would require passing a second parameter (the folder, see below kPARAMS=2). 
//	The problem with this approach is that the folder should be coded as a string constant, which would have to be parsed and dereferenced HERE. 
//	Could be done but it a lot of work...

// Flaw / Limitation
//	Does not handle syntax introducing a variable   like	variable DebgDigout = UFCom_DebugVar( "DigOut" )         if ( DebgDigout )....  Must use directly   if ( UFCom_DebugVar( "DigOut" ) )    



#include "UFCom_ColorsAndGraphs" 		// UFCom_PossiblyKillPanel()
#include "UFCom_DataFoldersAndGlobals"// UFCom_PossiblyCreateFolder()
#include "UFCom_Panel" 				

static strconstant	ksF_DEBUGPRINT	= "dbgprint"

static strconstant	ksDEBUG			= "Debg"			// Panel  AND  Folder name  ,   gn	"debug" 

static constant		kPARAMS			= 1				// 2 is NOT realised: set to 2 only after MAJOR rebuilding of the program to also pass application-specific folders


static  strconstant  csDEBUG_DEPTHALL	= " Nothing, Modules, Functions,"
static  strconstant  csDEBUG_DEPTHSEL	= " Nothing, Functions, Loops, Details, Everything,"


Function		fDbgPrint( s ) 
	struct	WMButtonAction	&s
	 nvar	state		= $ReplaceString( "_", s.ctrlname, ":" )	// the underlying button variable name is derived from the control name
	 printf "\t\t\t\t%s\tvalue:%2d   \t \r",  s.ctrlname, state		
	if ( state )
		PanelDebugPrint( ksDEBUG )					// rebuild the DebugPrint panel
	else
		UFCom_PossiblyKillPanel( ksDEBUG ) 
	endif
End

static Function		PanelDebugPrint( sWin )
	string  	sWin			//= ksDEBUG 
	string  	sFBase		= UFCom_ksROOT_UF_
	string		sPnTitle		= "Debug Print"

string  	sFSub_ = ""
	UFCom_DebugCollectVars()

	InitPanelDebugPrint(  UFCom_ksROOT_UF_ + sFSub_,  sWin )								// normally this code is required here but in this case it has already been executed in  'CreateGlobals()'  above

//	variable	xPosPercent = 80, yPosPercent = 90, xSzPts = 50, ySzPts = 450, rxPosPts, ryPosPts		// Position the panel in percent of screen area. This is only approximately as long as the size of the panel  (=xSzPts, ySzPts)  is only guessed...
	variable	xPosPercent = 80, yPosPercent = 0, xSzPts = 50, ySzPts = 450, rxPosPts, ryPosPts		// Position the panel in percent of screen area. This is only approximately as long as the size of the panel  (=xSzPts, ySzPts)  is only guessed...
	UFCom_Panel3PositionIt( xPosPercent, yPosPercent, xSzPts, ySzPts, rxPosPts, ryPosPts )			// Compute approximate panel position and pass it back in 'rxPosPts' and 'ryPosPts'		
	UFCom_Panel3Sub_( sWin, sPnTitle, sFBase+sFSub_, rxPosPts, ryPosPts, 1, UFCom_kPANEL_DRAW)	// Compute the panel dimensions. Draw the panel displaying and hiding needed/unneeded controls
End

static Function	InitPanelDebugPrint( sF, sPnOptions )
	string  	sF, sPnOptions
	string		sDFSave		= GetDataFolder( 1 )					// The following functions do NOT restore the CDF so we remember the CDF in a string .
	UFCom_PossiblyCreateFolder( sF + sPnOptions ) 	
	SetDataFolder sDFSave									// Restore CDF from the string  value
	string		sPanelWvNm = sF + sPnOptions
	variable	n = -1, nItems = 100
	 printf "\t\tInitPanelDebugPrint( '%s',  '%s' ) \r", sF, sPnOptions 
	make /O /T /N=(nItems)	$sPanelWvNm
	wave  /T	tPn	=		$sPanelWvNm
	
	//				Type	 NxL Pos MxPo OvS	Tabs		Blks		Mode		Name			RowTi			ColTi		ActionProc		XBodySz	FormatEntry	Initval		Visibility	SubHelp
	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:		,:		,:			dum0:			Depth(all) :			:		:				3:		:			:			:		Debug print depth all:	"		// single separator needs ',' 
	n += 1;	tPn[ n ] =	"RAD: 1:	0:	1:	0:	°:		,:		1,°:			raDebgGen:		fDebgGenLst_():	:		:				:		:			0010_1~0:	:		Debug print depth all:	"		// single button
	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:		,:		,:			dum2:			Depth(selected):	:		:				5:		:			:			:		Debug print depth selected:"	// 
	n += 1;	tPn[ n ] =	"RAD: 1:	0:	1:	0:	°:		,:		1,°:			raDebgSel:		fDebgSelLst_():		:		:				:		:			0020_1~0:	:		Debug print depth selected:"	// single button
	n += 1;	tPn[ n ] =	"SEP:  1:	0:	1:	0:	°:		,:		,:			dum6:			:				:		:				:		:			:			:		Debug print depth selected:"	//

	n += 1;	tPn[ n ] =	"CB:	   1:	0:	1:	0:	°:		,:		1,°:			DbgPrt:			UFCom_DbgLst():	:		UFCom_DbgCB():	:		:			~0:			:		Specific Debug print:	"		// multi-row checkboxes, initial values must be zero to correspond with global vars
	n += 1;	tPn[ n ] =	"BU:	   1:	0:	2:	0:	°:		,:		1,°:			DbgAllOn:			All On:			:		UFCom_fAllOn():	:		:			~0:			:		Turn all  debug variables on:"	//
	n += 1;	tPn[ n ] =	"BU:	   0:	1:	2:	0:	°:		,:		1,°:			DbgAllOff:			All Off:			:		UFCom_fAllOff():	:		:			~0:			:		Turn all  debug variables off:"	//
	n += 1;	tPn[ n ] =	"BU:	   1:	0:	1:	0:	°:		,:		1,°:			DbgCollect:		Update panel variables::		UFCom_fUpdateVars()::		:			~0:			:		Update debug variables:	"	// 
	redimension  /N = (n+1)	tPn
End


Function	/S	fDebgGenLst_( sBaseNm, sF, sWin )
	string  	sBaseNm, sF, sWin  
	return	csDEBUG_DEPTHALL
End

Function		UFCom_DebugDepthGen()
	nvar	  /Z	DepthGen	= root:uf:debg:raDebgGen00
	variable	bDebg	= nvar_exists( DepthGen )
	return	bDebg  ?  DepthGen  :  0 
End


Function	/S	fDebgSelLst_( sBaseNm, sF, sWin )
	string  	sBaseNm, sF, sWin 
	return	csDEBUG_DEPTHSEL
End

Function		UFCom_DebugDepthSel()
	nvar	  /Z	DepthSel	= root:uf:debg:raDebgSel00
	variable	bDebg	= nvar_exists( DepthSel )
	return	bDebg  ?  DepthSel  :  0 
End


Function		UFCom_fUpdateVars( s )
	struct	WMButtonAction	&s
//	UFCom_PossiblyKillPanel( ksDEBUG ) 
	PanelDebugPrint( ksDEBUG )					// rebuild the DebugPrint panel
End


Function		UFCom_fAllOff( s )
	struct	WMButtonAction	&s
	string 	sFolder 	= ksDEBUG
	UFCom_AllSet( UFCom_kOFF )
End

Function		UFCom_fAllOn( s )
	struct	WMButtonAction	&s
	string 	sFolder 	= ""
	UFCom_AllSet( UFCom_kON )
End

Function		UFCom_AllSet( bState )
	variable	bState
	string  	sWin		= ksDEBUG
string sFolder = ""
	string 	sFoCtrlNm		= ""
	string 	sCtrlBsNm		= "DbgPrt"					// the name of the checkbox group is defined in the panel initialisation wave
	string  	sVarNm, lstVars	= UFCom_DbgLst( "", UFCom_ksROOT_UF_ + sFolder, "" )
	variable	n, nVars		= ItemsInList( lstVars, "," )
	for ( n = 0; n < nVars; n += 1 )
//		sVarNm		= UFCom_RemoveLeadingWhiteSpace( StringFromList( n, lstVars, "," ) )
//		nvar	gValue	= $UFCom_ksROOT_UF_ + sFolder + ksF_DEBUGPRINT + ":" + sVarNm
		sVarNm		= UFCom_ksROOT_UF_ + sFolder + ksF_DEBUGPRINT + ":" + UFCom_RemoveLeadingWhiteSpace( StringFromList( n, lstVars, ","  ) )
		nvar	gValue	= $sVarNm
		gValue		= bState
		// Construct the control name and set the control (=Checkbox)
		sFoCtrlNm		= ReplaceString( ":", UFCom_ksROOT_UF_ + ksDEBUG + "_" + sCtrlBsNm + "00" + UFCom_IdxToDigitLetter( n ) + "0" , "_" )	// Assumption:  vertical control 
		CheckBox  $sFoCtrlNm, win = $sWin, value = bState					// Set / Reset  all  checkboxes of this group...
		// printf "\t\tUFCom_AllSet( bState:%2d ) \tsVarNm:\t%s\tsFoCtrlNm:\t%s\t \r", bState, UFCom_pd(sVarNm,28), UFCom_pd(sFoCtrlNm,28)

	endfor
End



Function		UFCom_DebugCollectVars()
// Find all occurrences of  'sPattern'  e.g. 'UFCom_DebugVar'  in all source files of this project.  
// Extracts parameters and stores them in a special folder, from which they are retrieved to build the  DebugOptions panel.
// Parameter of  'UFCom_DebugVar( param )' can only be a literal string  (e.g. "com") ..................BUT NOT   or  a strconstant (e.g. ksF_REC), but NOT a string variable (e.g. sFolder) because it is evaluated  BEFORE runtime.
// Code is a bit fragile.  Time will show if it works the desired way...

//	string  	sPattern	= "UFCom_DebugVar"		// the name of the one and only DebugPrint function
	string  	sPattern	= "UFCom_"+"DebugVar"		// TRICK: the name of the one and only DebugPrint function is divided into 2 parts so that THIS dumb parser will not detect this line 
	
	// Loop through all user functions and build a list of source file which contains them.  This is a complete path list of all functions.  Functions contained in the files but not called are included.
	string  	sUserFunction	  = ""
	string  	lstUserFunctions  = FunctionList( "*", ";", "KIND=10" )
	variable	n, nFuncs		  =  ItemsInList( lstUserFunctions )
	// printf "\t\tUFCom_DebugCollectVars(a)    UsrFuncs: %3d,  [%s .... %s] \r", nFuncs,  lstUserFunctions[0,80], lstUserFunctions[ strlen(lstUserFunctions) - 80, inf ]
	string  	sFuncPath, lstFuncPaths	= ""
	for ( n = 0; n < nFuncs; n += 1 )
		sUserFunction	= StringFromList( n, lstUserFunctions )
		sFuncPath		= FunctionPath( sUserFunction )
		if ( WhichListItem( sFuncPath, lstFuncPaths ) == UFCom_kNOTFOUND )
			lstFuncPaths += sFuncPath + ";"
			// printf "\t\tUFCom_DebugCollectVars(b)   Fnc:\t%s\tPath:\t%s\t Funcs: %3d,  [%s .... %s] \r", UFCom_pd(sUserFunction,24), UFCom_pd( sFuncPath,36), nFuncs,  lstUserFunctions[0,80], lstUserFunctions[ strlen(lstUserFunctions) - 80, inf ]
		endif
	endfor

	// 2007-0406 IGOR Bug ???  : 
	// On my machine  FunctionList( "*", ";", "KIND=10" )  returns (unused?)  function  'GetBrowserSelection()' for which  FunctionPath() returns EMPTY path
	// 2007-0406 Workaround for IGOR Bug ???  : Remove empty path
	lstFuncPaths	= ReplaceString( ";;" , lstFuncPaths , ";" )

	// Loop through all files and extract all lines containing 'sPattern'  e.g. 'UFCom_DebugVar' .   This also include occurrences in comment lines.
	// Build a string list of the extracted lines.
	string  	sGrep, lstGrepsNoComment = ""
	variable	nAllGreps = 0
	variable	pa, nPaths		  =  ItemsInList( lstFuncPaths )
	string  	sPath	
	// printf "\t\tUFCom_DebugCollectVars(c)    UsFncPaths: %2d,  [%s .... %s] \r", nPaths,  lstFuncPaths[0,80], lstFuncPaths[ strlen(lstFuncPaths) - 80, inf ]
	for ( pa = 0; pa < nPaths; pa += 1 )
		sPath	= StringFromList( pa, lstFuncPaths )	
		// printf "******\t\tUFCom_DebugCollectVars(Grep) \tPath: \t%3d /%3d\t%s \r", pa, nPaths, sPath 
		Grep	/E= sPattern /LIST=";" /Q  sPath		// !!! possible problem: the separator ';' must not occur in any line (not even in a comment) 
		string		lstGreps	= S_Value
		variable	nPos, g, nGreps	= ItemsInList( lstGreps )		// !!! possible problem: the separator ';' must not occur in any line (not even in a comment) 
		nAllGreps	+= nGreps
		lstGreps	= ReplaceString( "\t" ,    lstGreps, "" )			// Removing the tabs is not required but makes debugging easier			
	if ( UFCom_DebugVar( "ComDebugPrinting" ) )
		//printf "\t\tUFCom_DebugCollectVars(e)    Greps: %3d  [%s ....] \r", nGreps,  lstGreps[0,300]
	endif
		// Remove all comments as we are not interested in finding  'sPattern'  iin comments
		for ( g = 0; g < nGreps; g += 1 )
			sGrep	= StringFromList( g, lstGreps )
			nPos		= strsearch( sGrep, "//", 0 )
			if ( nPos > 0 )
				sGrep	= sGrep[ 0, nPos-1 ]				// line has code AND comment: keep code, truncate comment
				nPos		= strsearch( sGrep, sPattern, 0 )
				if ( nPos >= 0 )
					lstGrepsNoComment	+= sGrep	+";"		// the code (not the comment) contains 'sPattern' :  keep the line
	if ( UFCom_DebugVar( "ComDebugPrinting" ) )
					 printf "\t\tUFCom_DebugCollectVars(d)\tAll Greps: %3d /%3d \t\t%s\t%s\t  \r", g, nGreps, UFCom_pd( sPath, 35), sGrep
	endif
				endif
			elseif ( nPos == UFCom_kNOTFOUND )
				lstGrepsNoComment	+= sGrep + ";"			// line has only code but no comment : keep code
	if ( UFCom_DebugVar( "ComDebugPrinting" ) )
				 printf "\t\tUFCom_DebugCollectVars(e)\tAll Greps: %3d /%3d \t\t%s\t%s\t  \r", g, nGreps, UFCom_pd( sPath, 35), sGrep
	endif
			endif										// this implicitly excludes lines starting with a comment which have nPos==0
		endfor
	endfor

	if ( UFCom_DebugVar( "ComDebugPrinting" ) )
	 printf "\t\tUFCom_DebugCollectVars(f)\tAll Greps: %3d \t\tGreps without comment: %3d [%s....]\r", nAllGreps,  ItemsInList( lstGrepsNoComment ), lstGrepsNoComment[0,200]
	 printf "\t\tUFCom_DebugCollectVars(f)\tAll Greps: %3d \t\tGreps without comment: %3d [...%s]\r", nAllGreps,  ItemsInList( lstGrepsNoComment ), lstGrepsNoComment[strlen(lstGrepsNoComment)-200, inf]
	 printf "\t\tUFCom_DebugCollectVars(f).....\r"
	 print lstGrepsNoComment
	 printf "\t\t.......UFCom_DebugCollectVars(f)\r"
	endif
	
	// Loop through list of all extracted lines containing 'sPattern'  e.g. 'UFCom_DebugVar( "sName" )'   and extract the parameters
	// Bad code............
	lstGrepsNoComment	= ReplaceString( "||" ,    lstGrepsNoComment, ";" )
	lstGrepsNoComment	= ReplaceString( "&&" , lstGrepsNoComment, ";" )
	lstGrepsNoComment	= UFCom_RemoveWhiteSpace( lstGrepsNoComment )
	lstGrepsNoComment	= ReplaceString( "Function" + sPattern,   lstGrepsNoComment, "" )	// Mutilate the function definition  so that it will not be recognised and removed below
	lstGrepsNoComment	= ReplaceString( "if(" ,   lstGrepsNoComment, "" )					// do not remove  'if'  within the parameters !
	lstGrepsNoComment	= ReplaceString( "(UFCom_" , lstGrepsNoComment, "UFCom_" )
	lstGrepsNoComment	= ReplaceString( ")" ,   lstGrepsNoComment, "" )

	nGreps	= ItemsInList( lstGrepsNoComment )
	if ( UFCom_DebugVar( "ComDebugPrinting" ) )
	 printf "\t\tUFCom_DebugCollectVars(g)\tReplacing '||' and '&&'\tGreps without comment: %3d [%s....]\r",  nGreps, lstGrepsNoComment[0,200]
	endif	
	// Loop through list and remove all items which do not contain 'sPattern'
	string  	lstParams	= ""							
	string  	sParam		= ""
	for ( g = 0; g < nGreps; g += 1 )
		sGrep	= StringFromList( g, lstGrepsNoComment )
		// printf "\t\tUFCom_DebugCollectVars(h)\t %d/ %d\t%s\t%s\t  \r", g, nGreps, UFCom_pd( sPattern, 22 ), UFCom_pd( sGrep, 52 )
		if ( strsearch( sGrep, sPattern, 0 ) > UFCom_kNOTFOUND )
			sGrep	= ReplaceString( sPattern,   sGrep, "" )
			sGrep	= ReplaceString( "(" ,   sGrep, "" )
			variable	nParams	= ItemsInList( sGrep, "," )
			if ( nParams != kPARAMS ) 
				 UFCom_DeveloperError( "Should contain exactly " + num2str( kPARAMS ) + " parameters : '" + sGrep + "' . " )	// Ignore 	string spattern = "UFCom_DebugVar"   .....ignore   'UFCom_DebugCollectVars("UFCom_DebugVar" )'         
			else				
				lstParams += sGrep + ";"
	if ( UFCom_DebugVar( "ComDebugPrinting" ) )
				 printf "\t\tUFCom_DebugCollectVars(i)\t %d/ %d\t%s\t%s\t  \r", g, nGreps, UFCom_pd( sPattern, 19 ), UFCom_pad( sGrep, 28 ) 
	endif
			endif
		endif
	endfor
	

//// Version1: Avoid/skip the first folder parameter (=the strconstant) entirely
//	// Loop through the double list ( , ; , ; ) e.g.  'ksFOLDER,"FileName";"com","PanelWidth";.......'   and remove doublettes
//	lstGreps		= lstParams
//	lstParams	= ""
//	variable	par, nPars	= ItemsInList( lstGreps )
//	for ( par = 0; par < nPars; par += 1 )
//		sGrep 	= StringFromList( par, lstGreps )
//		if ( WhichListItem( sGrep, lstParams ) == UFCom_kNOTFOUND )
//			lstParams += sGrep + ";"
//			sParam	= sGrep
//			if ( UFCom_DebugVar( "ComDebugPrinting" ) )
//				 printf "\t\tUFCom_DebugCollectVars(k)\t %d/ %d\t%s\t%s\t%s\t  \r", par, nPars, UFCom_pd( sPattern, 19 ), UFCom_pad( sGrep, 28 ), UFCom_pad( sParam, 20 ) 
//			endif	
//			if ( strsearch( sParam, "\"", 0 ) > UFCom_kNOTFOUND )
//				sParam	= ReplaceString( "\"", sParam, "" )			// remove all  double quotes "
//			endif
//			UFCom_CreateDebugVar( sParam )
//
//		endif
//	endfor

	// Version with just 1: parameter ( no application-specific folder)
	// Loop through the e.g.  "FileName";"PanelWidth";.......'   and remove doublettes
	lstGreps	= lstParams
	lstParams	= ""
	variable	par, nPars	= ItemsInList( lstGreps )
	for ( par = 0; par < nPars; par += 1 )
		sGrep 	= StringFromList( par, lstGreps )
		sGrep	= ReplaceString( "\"", sGrep, "" )			// remove all  double quotes "
		if ( WhichListItem( sGrep, lstParams ) == UFCom_kNOTFOUND )
			lstParams += sGrep + ";"
			if ( UFCom_DebugVar( "ComDebugPrinting" ) )
				 printf "\t\tUFCom_DebugCollectVars(k)\tAll:\t %d/ %d\tNo doublettes:\t%3d\t%s\t%s\t%s\t  \r", par, nPars, ItemsInList( lstParams ), UFCom_pd( sPattern, 16 ), UFCom_pad( sGrep, 20 ), lstParams[0,200]
			endif	
		endif
	endfor

	// Finally sort the parameter list  and create the variables which will build up the debug print options panel and control how much  debugging info is printed
	// Flaw1: The sorting is not 100% : Any variable encountered BEFORE THIS function is executed is placed in the list so early that no ordering is applied. 
	// Flaw2: The sorting is not 100% : Variables added later during programming are not sorted in but placed at the end of the list.
	// Flaw3: THIS  UFCom_DebugVar( "ComDebugPrinting" ) )  seems not always to be recognised correctly....
	nPars	= ItemsInList( lstParams )
	lstParams	= SortList( lstParams )
	if ( UFCom_DebugVar( "ComDebugPrinting" ) )
		 printf "\t\tUFCom_DebugCollectVars(o)\t %d/ %d\t%s\t  \r", nPars, nPars, lstParams
	endif
	for ( par = 0; par < nPars; par += 1 )
		sParam	= StringFromList( par, lstParams )
		UFCom_CreateDebugVar( sParam )
	endfor

End


Function		UFCom_CreateDebugVar( sVarNm )
// Create the global debug variable and set its initial value to zero. 
// This is coded an extra function to simplify parsing by avoiding  the call  'UFCom_DebugVar( sVarNm )' .  See below.
	string  	sVarNm
	variable	nValue	= 0		// initial value if the variable does not yet exist
	string		sDFSave	= GetDataFolder( 1 )										// The following functions do NOT restore the CDF so we remember the CDF in a string .
	UFCom_PossiblyCreateFolder( UFCom_ksROOT_UF_ +  ksF_DEBUGPRINT ) 
	variable /G   $UFCom_ksROOT_UF_ + ksF_DEBUGPRINT + ":" + sVarNm	= nValue
	SetDataFolder sDFSave													// Restore CDF from the string  value
End


Function		UFCom_DebugVar( sVarNm )
// Retrieve the value of the global debug variable.  If the variable has not yet been created then create it and set its initial value to zero.  
// However, the debug folder must already exist as 'UFCom_PossiblyCreateFolder()'  would impose a big speed penalty.
// Note: 
// For building the DebugPrint panel  ( ->UFCom_DebugCollectVars() ) the code is parsed BEFORE runtime and the parameters are automatically  extracted.
// This works only if the parameters are literal strings  (e.g. "com")   or  a strconstants (e.g. ksF_REC) .  It will fail if string variable (e.g. sFolder) are passed!
	string  	sVarNm
	variable	nValue	= 0		// initial value if the variable does not yet exist

	nvar /Z	gVar	= $UFCom_ksROOT_UF_ +  ksF_DEBUGPRINT + ":" + sVarNm

	if ( nvar_exists( gVar ) )
		return	gVar
	else
		string		sDFSave		= GetDataFolder( 1 )								// The following functions do NOT restore the CDF so we remember the CDF in a string .

		UFCom_PossiblyCreateFolder( UFCom_ksROOT_UF_ +  ksF_DEBUGPRINT ) 		// We accept the speed penalty as the variables are created seldom.
		variable /G   $UFCom_ksROOT_UF_ +  ksF_DEBUGPRINT + ":" + sVarNm	= nValue

		//UFCom_InternalWarning( "Global variable does not exist : '" +  UFCom_ksROOT_UF_ + sFolder + ":" + ksF_DEBUGPRINT + ":" + sVarNm + "' .  Returning " + num2str( nValue ) + " ." )
		SetDataFolder sDFSave												// Restore CDF from the string  value
		return	nValue
	endif
End 


Function	/S	UFCom_DbgLst( sBaseNm, sF, sWin )
	string  	sBaseNm, sF, sWin  

	string		sVarNm, lstVars = ""
	variable 	index = 0
	do
		sVarNm = GetIndexedObjName( sF + ksF_DEBUGPRINT, 2, index)	// 2 : find only variables
		if ( strlen( sVarNm ) == 0 )
			break
		endif
		lstVars += " " + sVarNm + "," 
		index += 1
	while( 1 )
	if ( UFCom_DebugVar( "ComDebugPrinting" ) )
		printf "\t\tUFCom_DbgLst(\t\t%s\t%s\t%s\t)  -> '%s'  returns %d items : [%s...] \r", UFCom_pd( sBaseNm,10), UFCom_pd( sF,10), UFCom_pd( sWin,7), UFCom_ksROOT_UF_ + ksF_DEBUGPRINT, index, lstVars[0,200]
	endif
	return	lstVars
End


Function		UFCom_DbgCB( s )
	struct	WMCheckboxAction	&s
	variable	len		= strlen( s.Ctrlname )
	variable	row		= UFCom_DigitLetterToIdx(  (s.Ctrlname)[ len-2, len-2 ] )

	string   	sFolder	= ""//StringFromList( 2, s.Ctrlname, "_" ) + ":"				// e.g  'root_uf_secu_debST_DbgPrint0000'  ->  'secu:'
	string  	sVarNm	= UFCom_RemoveWhiteSpace( StringFromList( row, UFCom_DbgLst( "", UFCom_ksROOT_UF_ + sFolder, "" ) , "," ) )
	nvar		gValue	= $UFCom_ksROOT_UF_ + sFolder + ksF_DEBUGPRINT + ":" + sVarNm

	gValue	= s.checked
	if ( UFCom_DebugVar( "ComDebugPrinting" ) )
		printf "\t\tUFCom_DbgCB() \t\t%s  -> index:row:%d , sFolder : '%s' \t-> VarNm: '%s' -> value:%2d  \r", s.Ctrlname, row, sFolder, sVarNm, gValue
	endif
End

// ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//function tst()
//string  str = "ksF_REC"
//string  str1= ReplaceString( "\"", str, "")
//print "tst", str, ReplaceString( "\"", str, ""), str1
//end