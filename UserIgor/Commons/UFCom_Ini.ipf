//
// UFCom_Ini.ipf
//
// 2008-07-01
// 	Functions to save and restore settings  using the INI approach


//	OLD			//	General considerations: 
				//		What should be saved?
				//			All settings of the Main Panel
				//			All settings of all Sub Panels
				//			- the panel settings must include paths and files 
				//			Additional global variables and strings
				//			All window positions
				//			The traces in the window
				//			Cursor settings 
				//			The state of files (open, reading, writing, file pointer position....)
				//			The state of the CED (on / off)
				//		Additional requirements:
				//			The cursors can only be restored after the window configuration has been restored
				//				->	Restore  EVERYTHING right from the beginning		
				//						OR
				 //				->	Allow to restore the cursors separately (e.g. with an extra button) : This requires checking which cursors can be restored from the former into the current window/trace configuration
				//
				// Igors normal approach  to save and restore user settings is saving and loading the experiment
				//	Disadvantages:
				//		Will NOT work with FPulse (but perhaps with FEval)  as  1.)  CED status is not restored    2..) transfer area is not initialised correcty
				//	Advantages:
				//		If last script was on floppy and Igor is now restarted without floppy  the FileOpen Dialog box AUTOMATICALLY offers D: (where Igor and Windows are installed)  WITHOUT any errors or complaints
				//
				// Igors 'Preferences' approach (=this file) to save and restore user settings:
				//	The user settings are saved automatically when FPulse or Igor are quit.  The user does not have to press a button (or similar actions)  to store the settings.
				//	Variables or strings to be stored can be precisely selected  and do not have to belong to a panel,   
				//		but every variable or string which is to be stored must be added to the  FPulsePrefs structure below and a function call (copying to FPulsePrefs) is required at all places where the variable might be changed.
				
				// My former approach to save and restore user settings  [ e.g.  fSaveSets(), fRecallSets() and  fDeleteSets(),  UFCom_SaveAllFolderVars() ]  : 
				// 	The user settings are saved only when the user presses a button.  It is easy to store and retrieve multiple different configurations.
				//	All controls of a panel (=the whole panel) is saved.  If a control variable is added or removed no change in the user settings code is required.
				//	Additionally waves can be stored, but separate functions are necessary  [ e.g. SaveRegionsAndCursors() ]



#pragma rtGlobals=1		// Use modern global access method.

#pragma ModuleName = FPulse

#include "UFCom_DataFoldersAndGlobals"

// 2009-01-31 here
static strconstant	UFCom_ksINI_SUBDIR	= "Ini"	// Basename of subdirectory  within  directory scripts to which folder (e.g. '_Acq' or '_Eval' will be appended.  Contains stimulus and acquisition display configurations. 
static	 strconstant	UFCom_ksINI_EXT		= ".ini"	// Basename of subdirectory  within  directory scripts to which folder (e.g. '_Acq' or '_Eval' will be appended.  Contains stimulus and acquisition display configurations. 

static strconstant	UFCom_ksINI_KEYSEP	= "="
static strconstant	UFCom_ksINI_LISTSEP	= "\r"

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// IMPLEMENTATION of the DISPLAY CONFIGURATION l'lllstDiS'  containing all  display acquisition window / trace arrangement variables....??????...no
// lllstDiS is a quadruple list made of   windows (~),   types=locs or curves/channels (^),  curves/channels (;)   and items (,) .  Note: the window positions and scaling factors are stored only as a double list,  only the curves/channels are stored as a triple list
//
strconstant	ksDIS_ITEMSEP		= ","				

// These items are required once per window
// 2009-02-09
//constant		kDIS_WND_L = 0,   kDIS_WND_T = 1,   kDIS_WND_R = 2,   kDIS_WND_B = 3
constant		kDIS_WND_L = 0,   kDIS_WND_T = 1,   kDIS_WND_R = 2,   kDIS_WND_B = 3,  kDIS_WND_VIS= 4

//==========================================================================================================================================
//  THE  ONE-AND-ONLY   INI  FILE  for each application  containing  the  windows (panels, graphs, tables, notebooks) position and visibiliy, ...

Function	/S	UFCom_IniFile_Read( sFo, sSubFoIni, sIniBasePath )
// Try to read the huge one-and-only global INI list containing the entire information of all program settings from file and store it globally.  If the file does not exist or is empty then the global list is also created empty.
//...however, the list may also be empty if the file does not exist
	string  	sFo, sSubFoIni, sIniBasePath

	string    	sIniFile	= UFCom_IniFile_Path( sFo, sSubFoIni, sIniBasePath, UFCom_TRUE )	
	string  	lst	= ""
	if ( UFCom_FileExists( sIniFile ) )
		lst	= UFCom_ReadTxtFile( sIniFile )
	endif
	UFCom_Ini_CreateGlobal( sFo, sSubFoIni, lst )						// reads the file and sets huge global multi-line string list containing the entire settings
	return 	lst	// may be empty
End


Function	/S	UFCom_IniFile_Path( sFo, sSubFoIni, sIniBasePath, bCreateDir )
// Derives and returns path to INI file derived  from FPulse path  'sBasePath'  by assuming a subdirectory 'sSubFoIni_sFo' containing the 'sBasePath' file name but with extension 'sExt' (e.g. 'ini')
// If the subdirectory does not yet exist, it will be created if  'bCreateDir'  is ON.
// The existence of the derived and returned file  'sIniPath'  is  NOT  checked here.
	string  	sFo
	string  	sSubFoIni		// may not be the usual subfolder but just 'Ini' .  Is used to construct the path to the Ini file
	variable	bCreateDir
	string  	sIniBasePath										// e.g.  'D:UserIgor:FPulse_:UF_PulseMain.ipf'    'D:UserIgor:FPulse_:Scripts:MyScript.txt'  or  'D:UserIgor:Recipes_:UF_RecipesMain.ipf'   or 
	string  	sBaseDir	= UFCom_FilePathOnly( sIniBasePath )			// remove file name to keep directory where  INI subdirectory will be installed
	// 4 Versions  for naming the Ini sub-directory:
	// string  	sIniDir	= sBaseDir + UFCom_ksINI_SUBDIR	+ "_" + sFo	// ass name : creates subdir  'Ini_Acq'   FPulse and Scripts,   'Ini_Rec'  for  Recipes...)
	 string  	sIniDir	= sBaseDir + UFCom_ksINI_SUBDIR 				// ass name : creates subdir  'Ini'
	// string  	sIniDir	= sBaseDir + 	sSubFoIni 			+ "_" + sFo	// ass name : creates subdir  e.g. 'FPuls_Acq',  'Scrip_Acq', 'Recipes_Rec'
	// string  	sIniDir	= sBaseDir + 	sSubFoIni 						// ass name : creates subdir  e.g. 'FPuls' ,  'Scrip',  'Recipes'
	
	if ( bCreateDir )
		UFCom_PossiblyCreatePath( sIniDir )		// todo_c: handle Disk full error
	endif
	string  	sIniPath	= sIniDir + ":" + UFCom_FileNameOnly( sIniBasePath ) + UFCom_ksINI_EXT
	// print "\t\tUFCom_IniFile_Path() ", sFo, sSubFoIni, UFCom_ksINI_EXT, sIniBasePath, bCreateDir, " -> ",  sBaseDir, sIniDir, "returning:", sIniPath
	return	sIniPath
End


Function	/S	UFCom_Ini_CreateGlobal( sFo, sSubFoIni, lst )
// Store  'lst' (=the entire  INI file contents)  in 1 huge global multi-line string list
	string  	sFo, sSubFoIni, lst
	string  	sPathFolder = "root:uf:" + sFo + ":" + sSubFoIni
	UFCom_PossiblyCreateFolder( sPathFolder )
	string 	/G	   	   $"root:uf:" + sFo + ":" + sSubFoIni + ":" + "llllstIni" = lst
	// printf "\t\t\tUFCom_Ini_CreateGlobal \t'%s'\t'%s'   setting  : %s...\r",  sFo, sSubFoIni, ReplaceString( "\r", lst,  "<CR>  " )[0,300]
	return	lst
End


Function	/S	UFCom_Ini_Global( sFo, sSubFoIni )
// Returns the huge one-and-only global INI list containing the entire information of all program settings.
	string  	sFo, sSubFoIni	
	svar  /Z	lst	= $"root:uf:" + sFo + ":" + sSubFoIni + ":" + "llllstIni"
	if ( ! svar_exists( lst ) )																			// todo_c remove this checking once the code is stable
		string /G	   $"root:uf:" + sFo + ":" + sSubFoIni + ":" + "llllstIni" = ""
		svar  lst	= $"root:uf:" + sFo + ":" + sSubFoIni + ":" + "llllstIni"
		printf "Internal error: UFCom_Ini_Section()  'root:uf:%s:%s:llllstIni'  should  exist   but does not.  Is now created as an empty string...[missing UFCom_IniFile_Read???]\r" sFo , sSubFoIni 	//  remove this checking once the code is stable
	endif
	return	lst
End

Function	/S	UFCom_Ini_Section( sFo, sSubFoIni, sSection, sKey )
// Returns substring or sublist from the huge one-and-only global INI list containing the entire information of all program settings.
// The returned substring or sublist contains the entire information about 1 key in 1 section e.g.  'Sti'  'Trc' (=traces in stimulus window)   or  'AW1'  'Wnd' (=window location and time scale settings of acq window 1)
	string  	sFo, sSubFoIni, sSection, sKey		
	string  	lst		= UFCom_Ini_Global( sFo, sSubFoIni )
	string  	sKey_	= sSection + "_" + sKey				// ass name
	string  	sSubString	= StringByKey( sKey_, lst, UFCom_ksINI_KEYSEP, UFCom_ksINI_LISTSEP, 0 )
	return	sSubString
End


Function	/S	UFCom_Ini_SectionSet( sFo, sSubFoIni, sSection, sKey, sSubString )
// Update the huge global string with 1 substring.  Return the entire list
	string  	sFo, sSubFoIni, sSection, sKey, sSubString
	svar  /Z	lst	= $"root:uf:" + sFo + ":" + sSubFoIni + ":" + "llllstIni"
	if ( ! svar_exists( lst ) )
		string /G	   $"root:uf:" + sFo + ":" + sSubFoIni + ":" + "llllstIni" = ""
		svar  lst	= $"root:uf:" + sFo + ":" + sSubFoIni + ":" + "llllstIni"
		printf "Internal error: UFCom_Ini_SectionSet()  'root:uf:%s:%s:llllstIni'  should  exist   but does not.  Is now created as an empty string.....[missing UFCom_IniFile_Read???]\r" sFo , sSubFoIni 
	endif
	// Update the huge global string
	string  	sKey_	= sSection + "_" + sKey				// ass name
	lst		= ReplaceStringByKey( sKey_, lst, sSubString, UFCom_ksINI_KEYSEP, UFCom_ksINI_LISTSEP, 0 )
	return	lst
End


Function	/S	UFCom_IniFile_SectionSetWrite( sFo, sSubFoIni, sSection, sKey, sSubString, sIniBasePath )
// Sets substring or sublist in the  huge  one-and-only  global  INI  list  containing the entire information of all program settings.
// The substring or sublist contains the entire information about 1 key in 1 section e.g.  'Sti'  'Trc' (=traces in stimulus window)   or  'AW1'  'Wnd' (=window location and time scale settings of acq window 1)
//  Also stores the entire string list in file : do not call multiple times in a loop even though 'UFCom_WriteTxtFileDelayed()' prevents the worst.  If calling in a loop is required the file write should be placed outside this function.
	string  	sFo, sSubFoIni, sSection, sKey, sSubString, sIniBasePath		

	// Update the huge global string
	string  	lst		= UFCom_Ini_SectionSet( sFo, sSubFoIni, sSection, sKey, sSubString )

	// Update the file containing the huge global string.  This slows down the machine  so it  should not be used on every 'Window moved' event (better on window deactivate)
	string	  	sPathFile	=  UFCom_IniFile_Path( sFo, sSubFoIni, sIniBasePath, UFCom_TRUE )	// last param: Create file if required
	UFCom_WriteTxtFile( sPathFile, lst )
	// printf "\t\t\tUFCom_IniFile_SectionSetWrite_( storing\t\t'%s' \t%s\t%s\t%s\t%s\t ) storing: \t'%s' \r",  sPathFile, UFCom_pd(sFo,6), sSubFoIni,  UFCom_pd( sSection,7 ), UFCom_pd( sKey,7 ), sSubString[0,200]
	return	sSubString		// this just simplifies debugging
End


//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function	/S	UFCom_Ini_SectionDelete( sFo, sSubFoIni, sSection, sKey )
// Update the huge global string by deleting  1 entire substring including the key.  Return the entire list
	string  	sFo, sSubFoIni, sSection, sKey
	svar  /Z	lst	= $"root:uf:" + sFo + ":" + sSubFoIni + ":" + "llllstIni"
	if ( ! svar_exists( lst ) )
		string /G	   $"root:uf:" + sFo + ":" + sSubFoIni + ":" + "llllstIni" = ""
		svar  lst	= $"root:uf:" + sFo + ":" + sSubFoIni + ":" + "llllstIni"
		printf "Internal error: UFCom_Ini_SectionDelete()  'root:uf:%s:%s:llllstIni'  should  exist   but does not.  Is now created as an empty string.....[missing UFCom_IniFile_Read???]\r" sFo , sSubFoIni 
	endif
	// Update the huge global string
	string  	sKey_	= sSection + "_" + sKey				// ass name
	// printf "\t\t\tUFCom_Ini_SectionDelete    sFo:\t%s\tsSubFoIni:\t%s\t    key:\t%s\t'       list has %d items\r", UFCom_pd(sFo,8), UFCom_pd(sSubFoIni,8),  UFCom_pd(sKey_,33) , ItemsInList( lst, UFCom_ksINI_LISTSEP )    
	lst		= RemoveByKey( sKey_, lst, UFCom_ksINI_KEYSEP, UFCom_ksINI_LISTSEP )
	// printf "\t\t\tUFCom_Ini_SectionDelete .  sFo:\t%s\tsSubFoIni:\t%s\t    key:\t%s\t'       list has %d items\r", UFCom_pd(sFo,8), UFCom_pd(sSubFoIni,8),  UFCom_pd(sKey_,33) , ItemsInList( lst, UFCom_ksINI_LISTSEP )    
	return	lst
End



Function	/S	UFCom_IniFile_SectionDeletWrite( sFo, sSubFoIni, sSection, sKey, sIniBasePath )
// Deletes substring or sublist in the  huge  one-and-only  global  INI  list  containing the entire information of all program settings.
//  Also stores the entire string list in file.
	string  	sFo, sSubFoIni, sSection, sKey, sIniBasePath		

	// Update the huge global string
	string  	lst		= UFCom_Ini_SectionDelete( sFo, sSubFoIni, sSection, sKey )

	// Update the file containing the huge global string.  This slows down the machine  so it  should not be used on every 'Window moved' event (better on window deactivate)
	string	  	sPathFile	=  UFCom_IniFile_Path( sFo, sSubFoIni, sIniBasePath, UFCom_TRUE )	// last param: Create file if required
	UFCom_WriteTxtFile( sPathFile, lst )
	// printf "\t\t\tUFCom_IniFile_SectionDeleteWrite_( storing\t\t'%s' \t%s\t%s\t%s\t%s\t )  \r",  sPathFile, UFCom_pd(sFo,6), sSubFoIni,  UFCom_pd( sSection,7 ), UFCom_pd( sKey,7 )
	return	lst		// this just simplifies debugging
End

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function	/S	UFCom_Ini_EntriesWithMatchngKey( sFo, sSubFoIni, sKey, sSepOut )
// Returns  'sSepOut'-separated  sublist  from the huge one-and-only global INI list containing  all  entries with matching  'sKey'  e.g.  all  line with   '_wnd'  or  '_csr'
	string  	sFo, sSubFoIni, sKey, sSepOut	
	string  	lst			= UFCom_Ini_Global( sFo, sSubFoIni )
	variable	nPos, n, nItems	= ItemsInList( lst, UFCom_ksINI_LISTSEP )			// all  entries (=lines) in INI file 
	string  	sItem = "",  lstMatching = ""
	string  	sKey_		= "_" + sKey								// ass name
	for ( n = 0; n < nItems; n += 1 )
		sItem		= StringFromList( n, lst, UFCom_ksINI_LISTSEP )			// loop through all  entries (=lines) in INI file 
		nPos		= strsearch( sItem, sKey_+ UFCom_ksINI_KEYSEP, 0 )		// serarch for  '_wnd='  or  '_csr='
		if ( nPos > UFCom_kNOTFOUND )
			lstMatching += sItem + sSepOut 
		endif
	endfor
	//printf "\t\tUFCom_Ini_EntriesWithMatchngKey( sFo:'%s', sSubFoIni:'%s', sKey:'%s', sSepOut:'%s' )  returns '%s...'\r",  sFo, sSubFoIni, sKey, sSepOut, lstMatching[0,200]
	return	lstMatching
End


Function		UFCom_Ini_ExtractLine( sLine, rsSection, sKey, rValue )
// Extract channel, region, phase (=cursor type and index), BegEnd  and  cursor Xposition from an INI entry e.g. 'wCsrX0_r0_p0_n1_Csr=1.23'
	string  	sLine, sKey
	string  	&rsSection
	variable	&rValue
	variable	len
	rValue	= str2num( StringFromList( 1, sLine, UFCom_ksINI_KEYSEP ) )	// e.g.  'wCsrX0_r0_p0_n1_Csr=1.23'	->	1.23  
	rsSection	= StringFromList( 0, sLine, UFCom_ksINI_KEYSEP ) 			// e.g.  'wCsrX0_r0_p0_n1_Csr=1.23'	->	'wCsrX0_r0_p0_n1_Csr'  [ still includes trailing  '_key'  ]
	len		= strlen( rsSection )
	rsSection	= rsSection[ 0, len - 2 - strlen( sKey ) ]						// e.g.  'wCsrX0_r0_p0_n1_Csr'		->	'wCsrX0_r0_p0_n1'	remove sKey and the separator
End	




//=====================================================================================================================================
// INTERFACE = ACCESS FUNCTIONS to the DISPLAY CONFIGURATION 'lllstDiS'  containing all  display acquisition window / trace arrangement variables

Function	/S	UFCom_WndParam( lllst, item )
// elementary retrieving function for any  window item ( location and  X display mode e.g. blocks, laps, nostore)
	string  	lllst		
	variable	item
	string  	sValue	= StringFromList(  item, lllst, ksDIS_ITEMSEP )
	return	sValue
End


Function	/S	UFCom_WndPosition_( sFo, lst, left, top, right, bot )
// Extract acquisition window position from sublist 'lst'  and pass back individual positions.  If  'lst'  is empty then simply pass back again the passed default positions.
// !!! When calling this function for different windows then also use different default parameters so that when the multiple windows are created they will cover each other. 
	string  	sFo, lst
	variable	&left, &top, &right, &bot
	variable	leftDefault = left,   topDefault = top,   rightDefault = right,   botDefault = bot
	left	= str2num( UFCom_WndParam( lst, kDIS_WND_L ) )	;     left  	=  numType( left ) 	!=  UFCom_kNUMTYPE_NAN ?  left	:  leftDefault
	top	= str2num( UFCom_WndParam( lst, kDIS_WND_T ) )	;     top	=  numType( top ) 	!=  UFCom_kNUMTYPE_NAN ?  top	:  topDefault		
	right	= str2num( UFCom_WndParam( lst, kDIS_WND_R ) )	;     right	=  numType( right ) 	!=  UFCom_kNUMTYPE_NAN ?  right	:  rightDefault		
	bot	= str2num( UFCom_WndParam( lst, kDIS_WND_B ) );      bot	=  numType( bot ) 	!=  UFCom_kNUMTYPE_NAN ?  bot	:  botDefault
	// Handle invalid positions (happen when INI file is missing and  lst  is empty))			
	// todo_c : handle also other error cases:  top < bottom + minsz, right < left + minsize,  bottom < 0, left < 0, top >maxy, right > maxX 
	return	lst
End


//=====================================================================================================================================
// INTERFACE = ACCESS FUNCTIONS to the window variables

Function  	/S	UFCom_WndParamSet_( sFo, sSubFoIni, sSection, sKey, item, sValue )
// elementary storing function for any DiS  item ( window location and  traces )
	string  	sFo, sSubFoIni, sSection, sKey, sValue				
	variable	item
	string  	lst	= UFCom_Ini_Section( sFo, sSubFoIni, sSection, sKey )		
			lst	= UFCom_WndParamSet( sFo, sSubFoIni, sSection, sKey, lst, item, sValue )
	return	lst									// returning the string just set simplifies debugging
End


Function  	/S	UFCom_WndParamSetWrite_( sFo, sSubFoIni, sSection, sKey, item, sValue, sIniBasePath )
// elementary storing function for any DiS  item ( window location and  traces )  and  write to file
	string  	sFo, sSubFoIni, sSection, sKey, sIniBasePath, sValue				
	variable	item
	string  	lst	= UFCom_Ini_Section( sFo, sSubFoIni, sSection, sKey )		
			lst	= UFCom_WndParamSetWrite( sFo, sSubFoIni, sSection, sKey, lst, item, sValue, sIniBasePath )
	return	lst									// returning the string just set simplifies debugging
End


Function  	/S	UFCom_WndParamSet( sFo, sSubFoIni, sSection, sKey, lst, item, sValue )
// elementary storing function for any DiS  item ( window location and  traces )
	string  	sFo, sSubFoIni, sSection, sKey, lst, sValue				
	variable	item
	string  	sSubLst	= ""
	sSubLst	= UFCom_ReplaceListItem1( sValue, lst, ksDIS_ITEMSEP, item ) 
	UFCom_Ini_SectionSet( sFo, sSubFoIni, sSection, sKey, sSubLst )							// set the global string list
	return	sSubLst															// returning the string just set simplifies debugging
End

Function  	/S	UFCom_WndParamSetWrite( sFo, sSubFoIni, sSection, sKey, lst, item, sValue, sIniBasePath )
// elementary storing function for any DiS  item ( window location and  traces )  and  write to file
	string  	sFo, sSubFoIni, sSection, sKey, lst, sIniBasePath, sValue				
	variable	item
	string  	sSubLst	= ""
	sSubLst	= UFCom_ReplaceListItem1( sValue, lst, ksDIS_ITEMSEP, item ) 
	lst		= UFCom_IniFile_SectionSetWrite( sFo, sSubFoIni, sSection, sKey, sSubLst, sIniBasePath )
	return	lst																// returning the string just set simplifies debugging
End


//=====================================================================================================================================
// ------------  Applicable to all kinds of windows (panels, notebooks, ...)  :  position

Function	/S	UFCom_WndPositionSetWrite_( sFo, sSubFoIni, sSection, sKey, left, top, right, bot, sIniBasePath )
	string  	sFo, sSubFoIni, sSection, sKey
	string  	sIniBasePath				// e.g.  'FPulse'  or  'Recipes'
	variable	left, top, right, bot 
	string  	lst	= UFCom_Ini_Section( sFo, sSubFoIni, sSection, sKey )		
	return	UFCom_WndPositionSetWrite( sFo, sSubFoIni, sSection, sKey, lst, left, top, right, bot, sIniBasePath )
End

Function	/S	UFCom_WndPositionSetWrite( sFo, sSubFoIni, sSection, sKey, lst, left, top, right, bot, sIniBasePath )
	string  	sFo, sSubFoIni, sSection, sKey, lst
	string  	sIniBasePath				// e.g.  'FPulse'  or  'Recipes'
	variable	left, top, right, bot 
	lst	= UFCom_WndParamSet( sFo, sSubFoIni, sSection, sKey, lst, kDIS_WND_L, num2str( round( left  ) ) )	//  Rounding is only cosmetics
	lst	= UFCom_WndParamSet( sFo, sSubFoIni, sSection, sKey, lst, kDIS_WND_T, num2str( round( top  ) ) )	//  set string only ...
	lst	= UFCom_WndParamSet( sFo, sSubFoIni, sSection, sKey, lst, kDIS_WND_R, num2str( round( right) ) )	//...but do not  write to file
	lst	= UFCom_WndParamSetWrite( sFo, sSubFoIni, sSection, sKey, lst, kDIS_WND_B, num2str( round( bot  ) ), sIniBasePath )	//   last param : 1 means write to file
	return	lst
End

// 2009-01-27	Separate the 2 processes : setting the global and writing to file.  This avoids writing the file much too often when the window is resized or  moved.  It is not of great use (but does not hurt)  if only a boolean value (e.g visibility) is changed.
Function	/S	UFCom_WndPositionSet_( sFo, sSubFoIni, sSection, sKey, left, top, right, bot )
	string  	sFo, sSubFoIni, sSection, sKey
	variable	left, top, right, bot 
	string  	lst	= UFCom_Ini_Section( sFo, sSubFoIni, sSection, sKey )		
	return	UFCom_WndPositionSet( sFo, sSubFoIni, sSection, sKey, lst, left, top, right, bot )
End

Function	/S	UFCom_WndPositionSet( sFo, sSubFoIni, sSection, sKey, lst, left, top, right, bot )
	string  	sFo, sSubFoIni, sSection, sKey, lst
	variable	left, top, right, bot 
	lst	= UFCom_WndParamSet( sFo, sSubFoIni, sSection, sKey, lst, kDIS_WND_L, num2str( round( left  ) ) )	//  Rounding is only cosmetics
	lst	= UFCom_WndParamSet( sFo, sSubFoIni, sSection, sKey, lst, kDIS_WND_T, num2str( round( top  ) ) )	//   set string only ...
	lst	= UFCom_WndParamSet( sFo, sSubFoIni, sSection, sKey, lst, kDIS_WND_R, num2str( round( right) ) )	//...but do not  write to file
	lst	= UFCom_WndParamSet( sFo, sSubFoIni, sSection, sKey, lst, kDIS_WND_B, num2str( round( bot  ) ) )	//   
	return	lst
End

// ------------  Applicable to all kinds of windows (panels, notebooks, ...)  :  visibility

Function	/S	UFCom_WndVisibilitySetWrite_( sFo, sSubFoIni, sSection, sKey, bValue, sIniBasePath )
	string  	sFo, sSubFoIni, sSection, sKey
	string  	sIniBasePath				// e.g.  'FPulse'  or  'Recipes'
	variable	bValue
	return	UFCom_WndParamSetWrite_( sFo, sSubFoIni, sSection, sKey, kDIS_WND_VIS, num2str( bValue ), sIniBasePath )		// last param : 1 means write to file
End

Function	/S	UFCom_WndVisibilitySet_( sFo, sSubFoIni, sSection, sKey, bValue )
	string  	sFo, sSubFoIni, sSection, sKey
	variable	bValue
	return	UFCom_WndParamSet_( sFo, sSubFoIni, sSection, sKey, kDIS_WND_VIS, num2str( bValue ) ) 		
End


Function		UFCom_WndVisibility( sFo, sSubFoIni, sSection, sKey )
	string  	sFo, sSubFoIni, sSection, sKey
	string  	sWndInfo	= UFCom_Ini_Section( sFo, sSubFoIni, sSection, sKey )
	return	UFCom_WndVisibility_( sWndInfo )
End

Function		UFCom_WndVisibility_( lst )
	string  	lst
	variable	value	= str2num( UFCom_WndParam( lst, kDIS_WND_VIS ) );		value	 =  numType( value ) 	!= UFCom_kNUMTYPE_NAN ?  value  :  1	// is default
	return	value
End

//=========================================================================================================================
// STORING  AND  RETRIEVING  PANEL VARIABLES

Function		UFCom_IniFile_PnEntrySetWrite( sFo, sSubFoIni, sAppName, sPanel, sContrlBs, ch, i1, i2, i3,  sValue )	
	string  	sFo, sSubFoIni		// determines folder location of INI list containing ALL stored settings
	string  	sAppName		// determines location of INI file containing ALL stored settings
	string  	sPanel, sContrlBs	// the panel and the variable base name (to which the channel, row, column  etc. postfixes below will be appended)...
	variable	ch, i1, i2, i3		// ... in INI list and file  which is required when restoring the panel variable
	string  	sValue

	string  	sIniBasePath	= FunctionPath( sAppName )				// the Ini file containing the window position will be written in a subdirectory parallel to UF_PulseMain.ipf 
	string  	sItemPart1		= sFo + "_" + sSubFoIni +"_" + sPanel
	string  	sItemPart2		= sContrlBs + num2str( ch ) + num2str( i1 ) + num2str( i2 ) + num2str( i3 ) 
	UFCom_IniFile_SectionSetWrite( sFo, sSubFoIni, sItemPart1 , sItemPart2,  sValue, sIniBasePath )	
End
	

Function		UFCom_Ini_PnEntryRestore( sIniLine )
	string  	sIniLine			// includes subfolder=panel, variable name, channel, row, column and the value to be restored
	
	string  	sTxt			= " ->  restoring  "
	string  	sFo			= StringFromList( 0, sIniLine, "_" )
	string  	sSubFoIni		= StringFromList( 1, sIniLine, "_" )
	string  	sPanel		= StringFromList( 2, sIniLine, "_" )
	string  	sVarNm_Value	= StringFromList( 3, sIniLine, "_" ) 
	string  	sVarNm		= StringFromList( 0, sVarNm_Value, "=" ) 
	string  	sValue		= StringFromList( 1, sVarNm_Value, "=" ) 
	string  	sFoVarNm		= UFCom_ksROOT_UF_ + sFo + ":" + sPanel + ":" + sVarNm

	// Checkbox and Setvariable settings are restored simply by setting the underlying global control variable.  OK
	// String input fields should work the same,  still untested----------------
	nvar /Z   gNvar	= $sFoVarNm
	svar /Z   gSvar	= $sFoVarNm
	if ( nvar_exists( gNvar ) )
		gNvar	= str2num( sValue )
	elseif ( svar_exists( gSvar ) )
		gSvar	= sValue
	else
		sTxt		= "cannot restore"
	endif
	
	// Popupmenus are more complicated.  Besisdes restoring the underlying global control variable we must also explicitly update the popupmenu control.
	string  	sCntrlNm	= ReplaceString( ":", sFoVarNm, "_" )
	string  	sWin		= StringfromList( 3, sCntrlNm, "_" ) 
	ControlInfo /W=$sWin  $sCntrlNm
	if ( V_Flag == 3 ) 		// popupmenu = 3
		Popupmenu  $sCntrlNm, win=$sWin, mode = str2num( sValue )
	endif

	// printf "\t\tUFCom_Ini_PnEntryRestore( \t%s\t ) \t%s\t%s\t = \t%s\t%s\t%s\t \r", UFCom_pd(sIniLine,33), sTxt, UFCom_pd(sFoVarNm,33),   UFCom_pd(sValue,9), sWin, UFCom_pd(sCntrlNm,33)
End


Function		UFCom_Ini_PnEntryRestoreAll( sFo, sSubFoIni, sAppName )
	string  	sFo, sSubFoIni, sAppName
	string  	sIniBasePath	= FunctionPath( sAppName )				// the Ini file containing the window position will be written in a subdirectory parallel to UF_PulsMain.ipf 
// or  just retrieve list   as the file has been read already
	string  	lst			= UFCom_IniFile_Read( sFo, sSubFoIni, sIniBasePath )
	variable	n, nItems	= ItemsInList( lst, UFCom_ksINI_LISTSEP )			// all  entries (=lines) in INI file 
	string  	sItem = ""
	for ( n = 0; n < nItems; n += 1 )
		sItem		= StringFromList( n, lst, UFCom_ksINI_LISTSEP )			// loop through all  entries (=lines) in INI file 
		UFCom_Ini_PnEntryRestore( sItem )
		// printf "\t\tUFCom_Ini_PnEntryRestoreAll( sFo:'%s', sSubFoIni:'%s'  )  returns '%s...'\r",  sFo, sSubFoIni, sItem
	endfor
End
	
