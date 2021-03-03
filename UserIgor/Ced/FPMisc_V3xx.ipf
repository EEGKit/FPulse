// FPMisc_V3xx.IPF 


// 060914 for 319
strconstant	ksCOM			= "com"			// th

constant 		kNOEDIT	= 3						// IGOR defined (except kNOEDIT=3)  .  In  Button  and  SetVariable  the constants have slightly different meanings...

strconstant	ksDF_DLG		= "root:uf:dlg:"		// this special folder must contain colon ! Do not change until  ALL occurrences of 'root:uf:dlg:' and of  'root_uf_dlg_' have been replaced by ksDF_DLG

strconstant	ksSB_WNM 		= "SB"			// StatusBar 
strconstant	ksSB_WNDNAME	= "SB_ACQUISITION"// StatusBar 

constant		cGAININFO			= 1 			// 0 : print only  Adc  gains in statusbar	1 : print  Dac  and  Adc  gains in statusbar


// 2009-10-23
// ...???...
constant		kRIGHT = 0,  kLEFT = 1,  kBOTTOM = 0,  kTOP = 1
constant		kPN_INIT	= 1 ,  kPN_DRAW = 2

// 060914 for 319 was off on again
constant	kbKEEP_ACQ_DISP = 0,  kbNEW_ACQ_DISP = 1



// 2009-10-28 remove debug printing

//Function	Out1( bf, bQuickPrint )
//	string		bf
//	variable	bQuickPrint	// not used
//	printf "%s", bf			// prints everything and fast
//End
//Function	Out( bf )
//	string		bf
//	printf "%s", bf			// prints everything and fast
//End

// 2009-10-28 remove debug printing

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//   OUT  FUNCTIONS  needed  for DEBUG  PRINTING  ( belong to  FPTest.ipf   but are included here to avoid linker errors when  FPTest.ipf  is not included  in the Release version

Function	Out1( bf, bQuickPrint )
	string		bf
	variable	bQuickPrint
	if ( bQuickPrint )
		printf "%s", bf	// prints everything and fast
	else
		Out( bf )		// printing depends on the 'Debug print options' : much slower but amount of data to be printed can be adjusted 
	endif
End

static constant			NAM = 1		// must be same as in Dialog.ipf !	

Function	Out( bf )
// elaborate version of 'printf'  to control the amount of printed information (mainly debug information) 
// the begin of 'bf'  together with the settings in 'twPrintDebug' controls whether  'bf'  is printed or not
// there are two criteria: the number of tabs and  the first word following the tabs: these are checked against  'twPrintDebug' 
// if  any selections have to be checked the program execution is slowed down, but is acceptably fast with all selection OFF
// ---The advantage of this approach is that there is minimal additional code for each printed line: sprint bf  + Out(bf)  instead of  printf  
// ---The DISADVANTAGE of this approach is that it is slow ---> the function call takes 100..200us EVEN IF NOTHING IS PRINTED
//     this is OK when this function is called sparsely, but not when this function is called often (e.g in nested loops).....
//    .....whereever it is  time critical this function call  it must be (and has been) replaced by ugly code like...
//	if ( gRadDebgSel  > 3  &&   PnDebgOutElems ) 
//		printf ".........."
//	endif
// 	the function call takes 100..200us EVEN IF NOTHING IS PRINTED
// 
//return 0 // speed advantage < 5% compared to all selections off (eliminating all sprintf bf, "....." might save much time  but code will get ugly and blown up...  

	string		bf 
	nvar		gRadDebgGen	= root:uf:dlg:gRadDebgGen
	nvar		gRadDebgSel	= root:uf:dlg:gRadDebgSel
	variable	i, nTabs = 0, GenTabLimit = 0, SelTabLimit = 0			// default if none is selected

	GenTabLimit	= gRadDebgGen 

	SelTabLimit	= gRadDebgSel 	//? gRadDebgSel + 2 : 0	//  0 2 3 4 5 (skip the 1) 
	
	if ( strlen( bf )  > kIGOR_MAXSTRING )				// IGOR can only print a limited number of characters
		bf = bf[ 0, kIGOR_MAXSTRING - 2 -3 ] + "\r"	// reserve 2 for CR, 3 for line start markers below (e.g. * : .  - )
	endif
	do										// count  tabs at the line begin, which control the  depth of the display
		nTabs += 1
	while ( cmpstr( bf[ nTabs-1, nTabs -1 ], "\t" ) == 0 )
	nTabs -= 1 	

	if ( nTabs <= GenTabLimit )						// Printing  everything above a certain general depth and..
		printf " %s", bf							// ..not caring about selections is much faster (these lines are printed when 'Depth(all):  = Functions'  is selected
	endif	 

	variable 	len, index = 0
	string  	sFolderVarNmBase	=  "root:uf:dlg:Debg"
	string   	sShowSel , sCleanBuf, sFullVarNm

	// Although the following code is general, universal and useful   it is seldom called (e.g. for Telegraph, ShowLines) as it is slow...
	if ( SelTabLimit != 0 )							// we must check every single selection and are much slower

		// Get the state of all checkbox controls which belong to this folder by looping through all variables located in this folder
		do	
			sShowSel = GetIndexedObjName( sFolderVarNmBase,  kIGOR_VARIABLE, index )
			len 		=  strlen( sShowSel )
			if ( len == 0 )
				break
			else
				sCleanBuf		= RemoveWhiteSpace( bf )
				sFullVarNm	= sFolderVarNmBase + ":" + sShowSel
				nvar		bVarState		= $sFullVarNm
				if (  nTabs < SelTabLimit + 2 &&  cmpstr( sShowSel, sCleanBuf[ 0, len - 1 ] ) == 0  && bVarState )
					printf ". %s", bf
					// printf "...%d\t%s\t%s\t%s", len, pd(sShowSel,10) , pd(sCleanBuf,40),  bf
				endif
			endif	 
			// printf "\t\t\tOut()  \tTabs: %d\t%s\t-> \t%s\t%s\tbValue: %d )  \r",  nTabs, pd(sFolderVarNmBase,27), pd(sShowSel,12), pd(sFullVarNm, 32 ), bVarState
			index += 1
		while( TRUE )
	endif
End

// 2009-10-28 remove debug printing

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//   NOTE 	:   TEST  AND  DEBUG  FUNCTIONS  can only be  accessed by developer and  power user  by entering  'DebugPrintOptions()'   or  'PnDebugPrint()'   in the command line
//
// 050530  To avoid  NVAR checking errors this code is required not only in DEBUG but also in RELEASE mode  so it can unfortunately not be placed in FPTest.ipf  but is placed here in FPulseMain.ipf  instead. It is NOT needed in EVAL. 
//		  Consequence: Although the panel should not be accessible in RELEASE mode it actually is accessible  but only indirectly by entering  'DebugPrintOptions()'   or  'PnDebugPrint()'   in the command line. Also the code is but should not be visible.

static  strconstant  csDEBUG_DEPTHALL	= " Nothing; Modules; Functions"
static  strconstant  csDEBUG_DEPTHSEL	= " Nothing; Functions; Loops; Details; Everything"
static  strconstant  csDEBUG_SECTIONS	= " Timer; CfsRd; ShowLines; ShowKeys; ShowIO; ShowVal; ShowAmpTim; ShowEle; Expand; Digout; OutElems; Telegraph; CedInit; AcqDA; AcqAD; CfsWr; DispDurAcq; WndArrange" 

//Function		PnDebugPrint()
//	DebugPrintOptions()
//End
	
Function		DebugPrintOptions()
// 2009-10-27
//	string  	sFolder	= ksCOM						// 050530 must work in  Acq  with all variables from  'csDEBUG_SECTIONS'    but  in  Eval  it needs only a few variables ( for DisplayStimulus()... )
	string  	sFolder	= ksACOld
	string  	sPnOptions	= ":dlg:tDebugPrint"			
	// InitPanelDebugPrintOptions(  sFolder, sPnOptions )		// normally this code is required here but in this case it has already been executed in  'CreateGlobals()'  above
	ConstructOrDisplayPanel(  "PnDebug",  "Debug Print Options" , sFolder, sPnOptions, 90, 0 )
	// DebugPrintDeselectAll()							// Start the panel with options set to 'No printing'  (cannot be static) . Normally this code is required here but in this case it has already been executed in  'CreateGlobals()'  above
End

Function		InitPanelDebugPrintOptions(  sFolder, sPnOptions )
	string  	sFolder, sPnOptions
	string		sPanelWvNm = "root:uf:" + sFolder + sPnOptions
	variable	n = -1, nItems = 40
	make /O /T /N=(nItems)	   $sPanelWvNm
	wave  /T	tPn			= $sPanelWvNm	
	//						TYPE	;   FLEN	;FORM; LIM;PRC;  	NAM						; TXT				
	n = PnControl(	tPn, n, 1, ON, 	"PN_RADIO", 	 kVERT, " Depth (all): ",	"root:uf:dlg:gRadDebgGen",  csDEBUG_DEPTHALL ,	"Debug Depth all",  	"" , 	kWIDTH_NORMAL, sFolder ) 	
	n = PnControl(	tPn, n, 1, ON, 	"PN_RADIO", 	 kVERT, " Depth (select):",	"root:uf:dlg:gRadDebgSel",   csDEBUG_DEPTHSEL ,	"Debug Depth select",  "" , kWIDTH_NORMAL, sFolder ) 	
	n = PnControl(	tPn, n, 1, ON, 	"PN_CHKBOX", kVERT, "Selection:",	"root:uf:dlg:Debg",  		   csDEBUG_SECTIONS ,	"Debug Selection",  	"" , 	kWIDTH_NORMAL, sFolder ) 		
	n += 1;	tPn[ n ]	= 		"PN_BUTTON; 	buDebugSelectAll		; Select all"			
	n += 1;	tPn[ n ]	= 		"PN_BUTTON; 	buDebugDeselectAll		; Deselect all"			
	redimension   /N=(n+1)	tPn
End

Function		buDebugSelectAll( ctrlName ) : ButtonControl
	string 	ctrlName
	DebugPrintSelectAll()
End

Function		buDebugDeselectAll( ctrlName ) : ButtonControl
	string		ctrlName
	DebugPrintDeselectAll()
End

static Function	DebugPrintDeselectAll()
	//  we must turn EVERYTHING OFF (especially ..SelFunc,..SelLoop, ..SelAll) to gain the speed advantage
	RadioCheckUncheck( "root_uf_dlg_gRadDebgSel_0_5", 1 ) 		// Turn 'Nothing' sel radio button on, all others OFF	
	ChkboxSetAll(  "root:uf:dlg:Debg" , FALSE )						// = ShowIO, ShowEle, Expand, CFS...
End

static Function	DebugPrintSelectAll()
	RadioCheckUncheck( "root_uf_dlg_gRadDebgSel_2_5", 1 ) 		// Turn 'Loop' sel radio button on, all others OFF	(turning 'Everything' on would give too much information)
	ChkboxSetAll(  "root:uf:dlg:Debg" , TRUE )						// = ShowIO, ShowEle, Expand, CFS...
End
 
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function		CloseProcs( lstProcs )
	string  	lstProcs
	string  	sProc, sCmd
	variable	n, nProcs	= ItemsInList( lstprocs )
	for ( n = 0; n < nProcs; n += 1 )
		sProc	= StringFromList( n, lstProcs ) + ".ipf"
		sCmd	= "CloseProc /Name = \"" + sProc + "\""
		Execute /P /Q /Z	sCmd
	endfor
End
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function	/S	FormatVersion()	
// formats version string  e.g. '300'  -> '3.00'  or  '1302c'  ->  '13.02.c'
	string  	sVersion, sVersionOrg	 = ksVERSION				// e.g. '300'  or  '1302c'
	variable	nVersionNumber	= str2num( sVersionOrg )		// e.g. '300'  or  '1302'
	variable	len				= strlen( sVersionOrg )
	string  	sVersionLetter		= SelectString( len == strlen( num2str( nVersionNumber ) ) , "." + sVersionOrg[ len-1, len-1 ], "" )  
	sprintf  sVersion, " %.2lf%s %s" , nVersionNumber / 100 , sVersionLetter, SelectString( kbIS_RELEASE, "D", "" )	// D is reminder if we are still in the debug version
	return	sVersion
End
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------









