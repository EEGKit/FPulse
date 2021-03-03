//
//  UFCom_DataFoldersAndGlobals.ipf 
// 
#pragma rtGlobals=1							// Use modern global access method.

//#pragma IndependentModule=UFCom_
#include "UFCom_Constants"

//===============================================================================================================================

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//    MANAGEMENT  OF  GLOBAL  VARIABLES   AND  STORING  OF  USER  SETTINGS

Function		UFCom_ConstructAndMakeCurFoldr( sFolderPath )
// Builds all  intermediate folders required  to obtain 'sFolderPath' .  All  folders (intermediate and final) are cleared.   Also works with empty folder or  'root' , both act on root
// The final folder is the current folder when the function is left, so  objects can be added conveniently, but the previous folder must be restored outside this function. 
	string  	sFolderPath
	variable	n , nFolders	= ItemsInList( sFolderPath, ":" )
	string  	sFolder	= StringFromList( 0, sFolderPath, ":" )
	// also works with empty folder or  'root' , both act on root
//	if ( cmpstr( sFolder, "ROOT" )   ||  nFolders <= 1 )
//		FoAlert( sFolder, kERR_FATAL, "Internal: Folder path " + sFolderPath  + " does not begin with  'root:'  or no folder specified. " )	// to remind the programmer, never seen by the user
//	endif
	for ( n = 1; n < nFolders; n += 1 )
	 	sFolder	+= 	":" + StringFromList( n, sFolderPath, ":" )
		NewDataFolder  /O  /S $sFolder						// folders are created one after the other starting below 'root' 
	endfor
End

constant	kDF_FOLDERS = 1,   kDF_WAVES = 2,   kDF_VARIABLES = 4,   kDF_STRINGS = 8

Function		UFCom_KillDataFoldUnconditionly( sFolderPath )
	string  	sFolderPath
	if ( DataFolderExists( sFolderPath ) )
		UFCom_ZapDataInFolderTree( sFolderPath )
		KillDataFolder   $sFolderPath
		if ( V_Flag )
			UFCom_Alert( kERR_IMPORTANT, "Could not kill data folder '" + sFolderPath + "' .  Objects left:\r" )
			string		sDFSave	= GetDataFolder( 1 )				// remember CDF in a string.
			print	DataFolderDir( kDF_FOLDERS |  kDF_WAVES |  kDF_VARIABLES |  kDF_STRINGS )
			SetDataFolder sDFSave							// restore CDF from the string value
		endif
	endif
End

Function 		UFCom_ZapDataInFolderTree( sFolderPath )
// Deletes recursively all  UNUSED  waves, variable and strings from  'sFolderPath'  and its subfolders. 
// Works only if the waves to be deleted are not used in any graphs, so 'KillAllGraphs()' should be called first.  Code taken from Igor manual.
	string 	sFolderPath
	string 	savDF  = GetDataFolder(1)

	SetDataFolder sFolderPath

//string lst	= WaveList("*",";","") 
// print "ZapDataInFolderTree",  sFolderPath, lst
//variable n
//for ( n =0; n < ItemsInList(lst); n += 1)
//string  swve= stringfromlist( n, lst)
// printf "'%s'  exists :%d \r", swve, waveExists( $swve)
//endfor
//
//for ( n =ItemsInList(lst)-1; n >=1; n -= 1)
//  swve= stringfromlist( n, lst)
//wave /Z wv	= $"root:uf:acq:ar:" + swve
// printf " rev  '%s'  exists :%d \r", swve, waveExists( wv)
//
//if ( cmpstr( swve, "wG" ) )// &&   cmpstr( swve, "wStoreChunkOrNot" ) )			// ???????????????????? why can't   wG   be killed ?
//killwaves  /Z $swve
//endif
// printf " rev  '%s'  exists :%d \r", swve, waveExists( $swve)
//
//endfor

	KillWaves		/A/Z
	KillVariables	/A/Z
	KillStrings		/A/Z
	variable 	i
	variable 	nDataFolderCnt = CountObjects( ":" , kIGOR_FOLDER )			// kill all subfolders (4 is data folder)
	for ( i = 0; i < nDataFolderCnt; i += 1 )
		string 	sNextPath = GetIndexedObjName( ":" , kIGOR_FOLDER , i )
		UFCom_ZapDataInFolderTree( sNextPath )
	endfor
	SetDataFolder savDF
End


// 060916 to test: does this work if there are still data in the folder
Function		UFCom_PossiblyKillDataFolder( sFolderPath )
	string 	sFolderPath
	if ( DatafolderExists( sFolderPath ) )
		KillDataFolder  $sFolderPath
	endif
End


//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

// currently (060328) not needed, see also 'DELETEINCLUDE'
//Function		CloseProcs( lstProcs )
//	string  	lstProcs				// e.g. "FPulseMain;FPAcqCed;"
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


