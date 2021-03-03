//
//  UFCom_DataFoldersAndGlobals.ipf 
// 
#pragma rtGlobals=1							// Use modern global access method.

//#pragma IndependentModule=UFCom_
#include "UFCom_Constants"
#include "UFCom_Errors"
#include "UFCom_ColorsAndGraphs"			// UFCom_AllWindowsContainingWave()
//===============================================================================================================================

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//    MANAGEMENT  OF  GLOBAL  VARIABLES   AND  STORING  OF  USER  SETTINGS

Function		UFCom_PossiblyCreateFolder_R( sNestedFolder )
// If necessary build all  intermediate folders up to  'sF', which must be a full path starting with 'root' . If an empty folder is specified nothing is done.
// -> RESTORES the previous folder
// Returns 0 if the folder already existed ,  returns 1 if the folder has been created
	string  	sNestedFolder
	string		sDFSave	= GetDataFolder( 1 )						// The following function does NOT restore the CDF so we remember the CDF in a string .
	variable	code		= UFCom_PossiblyCreateFolder( sNestedFolder )
	SetDataFolder sDFSave									// Restore CDF from the string  value
	return	code
End

Function		UFCom_PossiblyCreateFolder( sNestedFolder )
// If necessary build all  intermediate folders up to  'sF', which must be a full path starting with 'root' . If an empty folder is specified nothing is done.
// -> The final folder will be the current folder after the function is left  ONLY IF IT HAS BEEN CREATED, so  objects can be added conveniently, but the previous folder must be restored outside this function. 
//  IF the folder (or some subfolder) existed already the current folder will be UNDETERMINED or a subfolder so one can not rely on the folder
// Returns 0 if the folder already existed ,  returns 1 if the folder has been created
	string  	sNestedFolder
	variable	n, nFolders = ItemsInList( sNestedFolder, ":" )
	variable	code		 = 0 				// assume that the desired folder already exists
	string  	sF
	if ( nFolders )
		sF	 = StringFromList( 0, sNestedFolder, ":" )
		if ( cmpstr( sF, "root" ) )
			UFCom_DeveloperError( "Folder must start 'root' " )
		else
			for ( n = 1; n < nFolders; n += 1 )
				sF	+= 	":" + StringFromList( n, sNestedFolder, ":" )
				if ( ! DataFolderExists( sF ) )
					NewDataFolder  /S $sF				// folders are created one after the other starting below 'root' 
					code	 = 1							// the desired folder did not exist and has been created
				endif
			endfor
		endif
	endif
	// printf "\t\t\tUFCom_PossiblyCreateFolder( %s ) returns %d ( the folder %s ) \r", sNestedFolder, code, SelectString( code, "already existed", "has been created" )
	return code
End


Function	/S	UFCom_FolderFromWave( sFoWave )
// Truncates  wave name from  'sFoWave'  and creates folder (or entire folder path) 
	string  	sFoWave
	return	UFCom_RemoveLastListItems( 1, sFoWave, ":" )
End

Function	/S	UFCom_PossiblyCreateFoldForWave( sFoWave )
// Truncates  wave name from  'sFoWave'  and creates folder (or entire folder path)  so that 'sFoWave' can be created afterwards.    RESTORES the previous folder.
	string  	sFoWave
	string  	sFolder	= UFCom_RemoveLastListItems( 1, sFoWave, ":" )
	UFCom_PossiblyCreateFolder_R( sFolder )
	return	sFolder
End

//Function	/S	UFCom_PossiblyCreateFoldForWv( sFoWave )
//// Truncates  wave name from  'sFoWave'  and creates folder (or entire folder path)  so that 'sFoWave' can be created afterwards.   STAY in newly created folder.
//	string  	sFoWave
//	string  	sFolder	= UFCom_RemoveLastListItems( 1, sFoWave, ":" )
//	UFCom_PossiblyCreateFolder( sFolder )
//	return	sFolder
//End


Function		UFCom_ConstructAndMakeCurFoldr( sFolderPath )
// Builds all  intermediate folders required  to obtain 'sFolderPath' .  All  folders (intermediate and final) are cleared.   Also works with empty folder or  'root' , both act on root
// The final folder is the current folder when the function is left, so  objects can be added conveniently, but the previous folder must be restored outside this function. 
	string  	sFolderPath
	variable	n , nFolders	= ItemsInList( sFolderPath, ":" )
	string  	sFolder	= StringFromList( 0, sFolderPath, ":" )
	// also works with empty folder or  'root' , both act on root
//	if ( cmpstr( sFolder, "ROOT" )   ||  nFolders <= 1 )
//		FoAlert( sFolder, UFCom_kERR_FATAL, "Internal: Folder path " + sFolderPath  + " does not begin with  'root:'  or no folder specified. " )	// to remind the programmer, never seen by the user
//	endif
	for ( n = 1; n < nFolders; n += 1 )
	 	sFolder	+= 	":" + StringFromList( n, sFolderPath, ":" )
		NewDataFolder  /O  /S $sFolder						// folders are created one after the other starting below 'root' 
	endfor
End


// Todo: Combine    kKILL_UNUSED = 0,  kKILL_ALL=1

constant	UFCom_kDF_FOLDERS = 1,   UFCom_kDF_WAVES = 2,   UFCom_kDF_VARIABLES = 4,   UFCom_kDF_STRINGS = 8

Function		UFCom_KillDataFoldUnconditionly( sFolderPath )
	string  	sFolderPath
	if ( DataFolderExists( sFolderPath ) )
		UFCom_ZapAllDataInFolderTree( sFolderPath )	// 2006-1120
		//UFCom_ZapDataInFolderTree( sFolderPath )
		KillDataFolder   /Z		$sFolderPath					// This should work now
		if ( V_Flag )
			UFCom_Alert( UFCom_kERR_IMPORTANT, "Could not kill data folder '" + sFolderPath + "' .  Objects left:\r" )
			string		sDFSave	= GetDataFolder( 1 )				// remember CDF in a string.
			print	DataFolderDir( UFCom_kDF_FOLDERS |  UFCom_kDF_WAVES |  UFCom_kDF_VARIABLES |  UFCom_kDF_STRINGS )
			SetDataFolder sDFSave							// restore CDF from the string value
		endif
	endif
End


Function 		UFCom_ZapAllDataInFolderTree( sFolderPath )
// Deletes recursively ALL variables, strings and waves from  'sFolderPath'  and its subfolders. 
// Deletes  waves even if they are used in a graph or table by first killing  tables and graphs
// Todo/ToCheck: text waves, panels,   waves used in XOPs,  locked waves ?
	string 	sFolderPath

	if ( DataFolderExists( sFolderPath ) )

// 2009-07-13  wrong as savDF may have been removed 
string 	savDF  = GetDataFolder(1)
		// printf "\t\tUFCom_ZapAllDataInFolderTree   \tsavDf:\t%s\tFolderPath to delete:\t%s\t \r", UFCom_pd(savDF,35), UFCom_pd(sFolderPath,35)
		SetDataFolder sFolderPath
	
		KillVariables	/A/Z
		KillStrings		/A/Z
	
		// First kill all windows which contain waves, so that afterwards the waves can be killed.
		KillWaves		/A/Z										// try to kill as many waves as possible, those used in graphs, tables or XOPs can not and will not be killed
		string  	lstWaves		= WaveList( "*" , ";" , "" ) 				// these waves could not be killed as they are in use
		variable	wv, nWaves	= ItemsInList( lstWaves )
		// if ( nWaves )
		//	 printf "\t\tUFCom_ZapAllDataInFolderTree( init  '%s' ) : %4d waves could INITIALLY not be killed because of open windows: '%s...'  \r", sFolderPath, nWaves, lstWaves[0,200]
		// endif
		for ( wv = 0; wv < nWaves; wv += 1 )
			string  	sWave	= RemoveEnding( sFolderPath, ":" ) + ":" + StringFromList( wv, lstWaves )
			string  	lstWins	= UFCom_AllWindowsContainingWave( sWave )
			variable	wnd, nWins	= ItemsInList( lstWins )
			for ( wnd = 0; wnd < nWins; wnd += 1 )
				KillWindow $StringFromList( wnd, lstWins )				// kill the window which contains 'sWave'
			endfor
		endfor
		KillWaves		/A/Z										// now it should be possible to also kill the remaining waves 
		lstWaves		= WaveList( "*" , ";" , "" ) 						// these waves could not be killed as they are in use
		if ( ItemsInList( lstWaves ) )
			printf "+++Error : UFCom_ZapAllDataInFolderTree( exit '%s' ) : %4d waves could FINALLY not be killed after deletion of windows: '%s...'  \r", sFolderPath, ItemsInList( lstWaves ), lstWaves[0,200]
		endif
	
		variable 	i
		variable 	nDataFolderCnt = CountObjects( ":" , UFCom_kIGOR_FOLDER )			// count subfolders (4 is data folder)
		for ( i = 0; i < nDataFolderCnt; i += 1 )
// 2008-07-25
//			string 	sNextPath = GetIndexedObjName( ":" , UFCom_kIGOR_FOLDER , i )

// 2009-07-14
			string 	sNextPath = sFolderPath + ":" + GetIndexedObjName( ":" , UFCom_kIGOR_FOLDER , i )
//			string 	sNextPath = RemoveEnding( sFolderPath, ":" ) + ":" + GetIndexedObjName( ":" , UFCom_kIGOR_FOLDER , i )

			// printf "\t\tUFCom_ZapAllDataInFolderTree . \tsavDf:\t%s\tFolderPath to delete:\t%s\tdf:%2d\t/%2d\tZapping\t%s\t%s\t \r", UFCom_pd(savDF,35), UFCom_pd(sFolderPath,35),  i , nDataFolderCnt, UFCom_pd(sNextPath,49),  GetIndexedObjName( ":" , UFCom_kIGOR_FOLDER , i )
			UFCom_ZapAllDataInFolderTree( sNextPath )
		endfor
// 2009-07-13  wrong IF savDF has been removed .  MUST  PREVENT
//printf "\t\tUFCom_ZapAllDataInFolderTree  \tsavDF:\t%s\tsFolderPath to be deleted:\t%s  \r", UFCom_pd(savDF,31),  sFolderPath
SetDataFolder savDF
	endif
End


//Function 		UFCom_ZapDataInFolderTree( sFolderPath )
//// Deletes recursively all  UNUSED  waves, variable and strings from  'sFolderPath'  and its subfolders. 
//// Works only if the waves to be deleted are not used in any graphs, so 'KillAllGraphs()' should be called first.  Code taken from Igor manual.
//	string 	sFolderPath
//	string 	savDF  = GetDataFolder(1)
//
//	SetDataFolder sFolderPath
// 
//	KillWaves		/A/Z
//	KillVariables	/A/Z
//	KillStrings		/A/Z
//	variable 	i
//	variable 	nDataFolderCnt = CountObjects( ":" , UFCom_kIGOR_FOLDER )			// kill all subfolders (4 is data folder)
//	for ( i = 0; i < nDataFolderCnt; i += 1 )
//		string 	sNextPath = GetIndexedObjName( ":" , UFCom_kIGOR_FOLDER , i )
//		UFCom_ZapDataInFolderTree( sNextPath )
//	endfor
//	SetDataFolder savDF
//End

//// 2006-0916 to test: does this work if there are still data in the folder
//Function		UFCom_PossiblyKillDataFolder( sFolderPath )
//	string 	sFolderPath
//	if ( DatafolderExists( sFolderPath ) )
//		KillDataFolder  $sFolderPath
//	endif
//End

//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

// currently (060328) not needed, see also 'DELETEINCLUDE'
//Function		UFPE_CloseProcs( lstProcs )
//	string  	lstProcs				// e.g. "UF_PulsMain;UF_AcqCed;"
//	string  	sProc, sCmd
//	variable	n, nProcs	= ItemsInList( lstprocs )
//	for ( n = 0; n < nProcs; n += 1 )
//		sProc	= StringFromList( n, lstProcs ) + ".ipf"
//		sCmd	= "CloseProc /Name = \"" + sProc + "\""
//		Execute /P /Q /Z	sCmd
//	endfor
//End

//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function		UFCom_GVarCE( sFolderVarNm, DefaultValue )
// Returns	  value of global variable.  If the variable does not yet exist it is constructed with the  default value, but the folder must exist already. 
// The folder is assumed to exist already (checking the existence and possibly building the folder could easily be done but would slow down the code...)
	string  	sFolderVarNm
	variable	DefaultValue
	nvar	/Z	gValue	= $sFolderVarNm
	if ( ! nvar_exists( gValue ) )
		variable	/G	$sFolderVarNm	= DefaultValue
		return	DefaultValue
	endif		
	return	gValue
End

Function		UFCom_GVar( sFolderVarNm )
// Returns	  value of global variable.  The variable and the folder must exist already. 
	string  	sFolderVarNm
	nvar		gValue	= $sFolderVarNm
	return	gValue
End

Function		UFCom_GVarExists( sFolderVarNm )
// Returns	  whether global variable exists or not.
	string  	sFolderVarNm
	nvar		/Z gValue	= $sFolderVarNm
	return	nvar_exists( gValue )
End

Function		UFCom_SetGVar( sFolderVarNm, Value )
// Constructs and sets a  global variable.  The variable may exist or not, but the folder must exist already.
// The folder is assumed to exist already (checking the existence and possibly building the folder could easily be done but would slow down the code...)
	string  	sFolderVarNm
	variable	Value
	variable	/G	$sFolderVarNm	= Value
	return	Value					// returning the value (though initially already known) simplifies code when using this function
End

Function	/S	UFCom_GStringCE( sFolderStringNm, sDefaultString )
// Returns	  value of global string.  If the string does not yet exist it is constructed with the  default string, but the folder must exist already. 
// The folder is assumed to exist already (checking the existence and possibly building the folder could easily be done but would slow down the code...)
	string  	sFolderStringNm
	string		sDefaultString
	svar	/Z	sString	= $sFolderStringNm
	if ( ! svar_exists( sString ) )
		string	/G	$sFolderStringNm	= sDefaultString
		return	sDefaultString
	endif		
	return	sString
End

Function	/S	UFCom_GString( sFolderStringNm )
// Returns	  value of global string.  The string  and the folder must exist already. 
// The folder is assumed to exist already (checking the existence and possibly building the folder could easily be done but would slow down the code...)
	string  	sFolderStringNm
	svar		sString	= $sFolderStringNm
	return	sString
End

Function	/S	UFCom_SetGString( sFolderStringNm, sString )
// Constructs and sets a  global string.  The string may exist or not, but the folder must exist already..
// The folder is assumed to exist already (checking the existence and possibly building the folder could easily be done but would slow down the code...)
	string  	sFolderStringNm
	string	  	sString
	string  	/G	$sFolderStringNm	= sString
	return	sString
End


Function  		UFCom_FolderSetV( sF, sNameofGlobalNumber, Value )
// constructs global variable with name 'sNameofGlobalNumber'  in folder 'sF' , sets it to Value, returns value
	string 		sF, sNameofGlobalNumber
	variable		Value							 
	variable	/G	$( sF + sNameofGlobalNumber ) = Value	 
	return		Value								// this redundant line makes the corresponding FolderGetV() function shorter
End

//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function		UFCom_SafeGVar( sFolderVarNm, DefaultValue )
// Returns	  value of global variable.  If the variable does not yet exist it is constructed with the  default value. 
//  If the folder does not exist already  it is created.   This may not be fast and effective in loops, but using it in user interaction code is OK.
	string  	sFolderVarNm
	variable	DefaultValue
	string  	sFolderPath	= RemoveEnding( UFCom_RemoveLastListItems( 1, sFolderVarNm, ":" ) , ":" )	// e.g.  'root:uf:subfolder:varname'   ->    'root:uf:subfolder' 
	if ( ! DataFolderExists( sFolderPath ) )
		string 	sDFSave	= GetDataFolder( 1 )		// Remember CDF in a string.
		UFCom_PossiblyCreateFolder( sFolderPath )
		SetDataFolder sDFSave 	
	endif
	nvar	/Z	gValue	= $sFolderVarNm
	if ( ! nvar_exists( gValue ) )
		variable	/G	$sFolderVarNm	= DefaultValue
		return	DefaultValue
	endif		
	return	gValue
End

Function		UFCom_SafeGVarSet( sFolderVarNm, Value )
// Constructs and sets a  global variable.  The variable may exist or not.
//  If the folder does not exist already  it is created.   This may not be fast and effective in loops, but using it in user interaction code is OK.
	string  	sFolderVarNm
	variable	Value
	string  	sFolderPath	= RemoveEnding( UFCom_RemoveLastListItems( 1, sFolderVarNm, ":" ) , ":" )	// e.g.  'root:uf:subfolder:varname'   ->    'root:uf:subfolder' 
	if ( ! DataFolderExists( sFolderPath ) )
		string 	sDFSave	= GetDataFolder( 1 )		// Remember CDF in a string.
		UFCom_PossiblyCreateFolder( sFolderPath )
		SetDataFolder sDFSave 	
	endif
	variable	/G	$sFolderVarNm	= Value
	return	Value							// returning the value (though initially already known) simplifies code when using this function
End



//=========================================================================================================================
// 2010-01-13

Function 	/S	UFCom_AllObjectsIn( sFolder, sSep, nType )
// returns list of Igor objects founf in sFolder
	string  	sFolder, sSep
	variable	nType			//1: waves,  2: variables,  4: folders
	string  	sObjNm = "",  lst = ""
	variable	n, nObjects	= CountObjects( sFolder, nType )
	for ( n = 0; n < nObjects; n += 1 )
		sObjNm  =  GetIndexedObjName( sFolder, nType, n )	
		lst	    +=  sObjNm + sSep
	endfor
	return	lst
End


Function 	/S	UFCom_AllWavesIn( sFolder )
	string  	sFolder
	return	UFCom_AllObjectsIn( sFolder, ";" , 1 )		// 1 is waves
//	string 	sObjName
//	string  	lstWaves	= ""
//	variable 	index 	= 0
//	do
//		sObjName	= GetIndexedObjName( sFolder, 1, index )	// 1 is waves
//		if ( strlen( sObjName ) == 0 )
//			break
//		endif
//		lstWaves += sObjName + ";"
//		index += 1
//	while( 1 )
//	return  lstWaves
End

Function 	/S	UFCom_AllFoldersIn( sFolder )
	string  	sFolder
	return	UFCom_AllObjectsIn( sFolder, ";" , 4 )		// 4 is folders
//	string 	sObjName
//	string  	lstWaves	= ""
//	variable 	index 	= 0
//	do
//		sObjName	= GetIndexedObjName( sFolder,  4, index )	// 4 is folders
//		if ( strlen( sObjName ) == 0 )
//			break
//		endif
//		lstWaves += sObjName + ";"
//		index += 1
//	while( 1 )
//	return  lstWaves
End

Function 	/S	UFCom_AllVariablesIn( sFolder )
	string  	sFolder
	return	UFCom_AllObjectsIn( sFolder, ";" , 2 )		// 2 is variables
End

Function 	/S	UFCom_AllVariablesIn_( sFolder, sSep )
	string  	sFolder, sSep
	return	UFCom_AllObjectsIn( sFolder, sSep , 2 )	// 2 is variables
End



Function	UFCom_WhichFolderItem( sItem, sFoPath, nType )
// Returns index of any object in a data folder. Similar to  'WhichListItem'  but scans data folder and allows to select wave-, variable-,  string-,  folder-objects.
// Is only useful when the order of the objects in the data folder does not change.  Is this always true????
	string  	sItem, sFoPath
	variable	nType		// 1:waves,  2:variables,  3:strings,  4:folders
	variable	n, nObjs	= CountObjects( sFoPath, nType )
	for ( n = 0; n < nObjs; n += 1 )
		if ( cmpstr( sItem, GetIndexedObjName( sFoPath, nType, n ) ) == 0 )
			return	n
		endif
	endfor
	return	UFCom_kNOTFOUND
End

