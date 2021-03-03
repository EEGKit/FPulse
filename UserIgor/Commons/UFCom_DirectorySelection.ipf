//
//  UFCom_DirectorySelection.ipf 
// 
#pragma rtGlobals=1							// Use modern global access method.

//#pragma IndependentModule=UFCom_
#include "UFCom_Constants"


//===============================================================================================================================

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//  DIRECTORY SELECTION  DIALOG  BOX

static	  strconstant	csDIRPROMPT		= "Select directory"
static	  strconstant	csDIRFILTER		= "Directories; ;;"
static	  strconstant	csDIRDUMMY		= "_"		// "'" or "_"	// Should be  1 character  for directory selection as UFCom_UtilFileDialog() requires a dummy file name even if no file but a directory is selected. 
static	  constant		cDIRINDEX		= 1					// the one-based index of the initial selection in the file type listbox 

Function	/S	UFCom_DirectoryDialog( sPath )				
// Allows selection of a directory with a generic file open dialogbox which gives a better user interface than standard dialog box because only dirs are shown, files are hidden.
// always returns a valid path: If the user CANCELS the initially passed path is returned unchanged
	string 	sPath									// path  to start from (e.g. which the user entered in the Setvariable control). This path may be valid  or  not, or even empty.  
	string 	sSelectedPath	= UFCom_UtilFileDialog( csDIRPROMPT, csDIRFILTER, cDIRINDEX, sPath, "", csDIRDUMMY )	// sample for  directory selection dialog
	// printf "UFCom_Util\t\tDirectoryDialog(4) \tUFCom_UtilFileDialog(  %d,  '%s',  '' ,  '%s' )  returns  sSelectedPath: '%s' \t \r",  cDIRINDEX, sPath,  csDIRDUMMY , sSelectedPath	
	variable	bSelectionOK	= cmpstr( sSelectedPath, csDIRDUMMY )	// if CANCELLED the  Open file dialog returns the initially received string  :  UFCom_FALSE,  we then revert to the last valid path...
	sPath = SelectString( bSelectionOK, sPath, UFCom_StripFileAndExtension( sSelectedPath )	)// only if  NOT CANCELLED we overwrite the selected path  (after removing the dummy file '_' )  for returning it
	// printf "\t\tDirectoryDialog() \tDialog box returned: %s  \t-> we return: %s\t%s \r",  UFCom_pd(sSelectedPath,24),   UFCom_pd( sPath,24), SelectString( bSelectionOK, "User cancelled", "Selection OK" )
	return	sPath
End

// 2006-1113    Version2  Data path selection in FPulsMain    is not used now (061113 In Version1 a new directory is created rather than searching the hierarchy)...

//Function		fDataDir( s ) 
//// Action proc  for the  Text Input Field   which displays the  Data Directory   and which also allows to type in a new directory 
//// Called  AFTER  the user has entered  a string into the text input field of the temporary global  'gsDataDir' . 
//// This string may or may not be a valid directory. 
//   Version 2 : 
//	struct	WMSetVariableAction	&s
//	 printf "\t\tfDataDir()\t%s\t'%s'  \t \r",  s.ctrlname, s.sval
//	variable	varNum
//	svar		sDataDir	= root:uf:acq:pul:gsDataDir0000
//	// printf "\t\tfDataDir1( cNm: '%s'  vNm: '%s'  num:%2d  vStr:%s )  \r", ctrlName, varName,  varNum, varStr
//
// The string is passed to the 'UFCom_DirCheckAndPossiblyDialog()'.  
// 'UFCom_DirCheckAndPossiblyDialog()' opens a generic dialog box  for selecting (and returning) a valid directory if the string was initially invalid but if the user cancelled an empty (invalid) directory is returned.
// 'UFCom_DirCheckAndPossiblyDialog()' does nothing with the string and returns it unchanged  if it was initially already a valid directory.
// The real global  'sDataDir'  is updated only if the path returned by  ' UFCom_DirCheckAndPossiblyDialog()'  is valid.
// We must use a temporary global to be able to restore the old directory if the user entered an invalid path or cancelled...

//	// Version2:  061113	User typed in a valid directory:							 This directory is used
//	// 		 	 	User typed in invalid directory and cancelled: 				 The recently stored valid directory  'sDataDirTmp'  is restored and used
//	//				User typed in invalid directory and continued (pressed 'Speichern'): The next valid directory up in the hierachy will be used
//	string		sNewDir	= UFCom_DirCheckAndPossiblyDialog( s.sval ) 	// will be empty string if user cancelled  or else valid directory (but possibly up in the hierachy and NOT the directory which the user had typed in the 'STR' control input field)
//	if ( strlen( sNewDir ) == 0 )									// Check if the directory returned by the dialog box is valid (user did not cancel)....
//		svar /Z	sDataDirTmp =	root:uf:acq:pul:gsDataDirTmp
//		if ( !svar_exists( sDataDirTmp ) )
//			string 	/G		root:uf:acq:pul:gsDataDirTmp	= "C:"
//			svar	sDataDirTmp =	root:uf:acq:pul:gsDataDirTmp
//		endif
//		sDataDir	= sDataDirTmp
//	else
//		sDataDir	= sNewDir
//	endif
//	Ini_DataDirSet( sDataDir )									// store the content of the 'DataDir'  Setvariable string input field  in the INI file
//	SearchAndSetLastUsedFile()							// if the  directory  changes we must again discriminate between used and unused files (update also 'gsDataFileW' )
//	string /G	root:uf:acq:pul:gsDataDirTmp	= sDataDir
//	 printf "\t\tfDataDir2b() \thas set global sDataDir: '%s' \t \r",   sDataDir	
// End


// 2006-1113  Has been used for  Version2  Data path selection in FPulsMain  but is not used now (061113 In Version1 a new directory is created rather than searching the hierarchy)...

//Function	/S	UFCom_DirCheckAndPossiblyDialog( sPath )					
//// Allows selection of a directory with an text input field. If the text input is not a valid directory then a generic file open dialog box pops up.
//// This generic file open dialog box gives a better user interface than standard dialog box because only directories are shown, files are hidden.
//// Returns an empty string if user cancelled  or else valid directory (but possibly up in the hierachy and NOT the directory which the user had typed in the 'STR' control input field)
//	string 	sPath										// path  to start from (e.g. which the user entered in the Setvariable control). This path may be valid  or  not, or even empty.  
//	string 	sSelectedPath	= ""								// temporary storage for  parentPath  and  dialog selection
//	variable	bDirExists		= UFCom_DirectoryExists( sPath )		// Check if the passed  'sPath'  is already a  valid directory....
//	// printf "\t\tUFCom_DirCheckAndPossiblyDialog...1() \tsPath: %s\t-> Dir exists:%d   -> %s \r",  UFCom_pd( sPath,30 ), bDirExists, SelectString( bDirExists, "search parent dir and  display dialog", "return this dir" )
//	if ( ! bDirExists ) 											// .. if it is then use it directly without  displaying the dialog box
//		do												// walk back in the directory hierarchy level for level towards the root...
//			sSelectedPath	= UFCom_ParentFolder( sPath ) 		
//			if ( cmpstr( upperstr( sPath ) , upperstr( sSelectedPath ) ) )	// if they differ...
//				sPath	= sSelectedPath					// ..try again
//			else 											// if they are the same..
//				sPath	= "C:"							// ..we can't go further because we are at the end  (=in the root)		// !!! BAD  could be D: ...
//			endif
//			bDirExists	= UFCom_DirectoryExists( sPath )
//			// printf "\t\tUFCom_DirCheckAndPossiblyDialog...2() \tsPath: %s\t-> Dir exists:%d\tSelectP: %s \t \r",  UFCom_pd( sPath,30 ), bDirExists,  UFCom_pd( sSelectedPath,30)	
//		while ( ! bDirExists )							// ...until a valid directory is found : Use this as a starting directory for the dialog box below
//
// printf "\t\tUFCom_UtilDirectoryCheckAnd...2() \tsPath: %s\t-> Dir exists:%d\tSelectP: %s \t \r",  UFCom_pd( sPath,30 ), bDirExists,  UFCom_pd( sSelectedPath,30)	
//		sPath	= UFCom_UtilFileDialog( csDIRPROMPT, csDIRFILTER, cDIRINDEX, sPath, "", csDIRDUMMY )	// sample for  directory selection dialog
//		sPath	= UFCom_StripFileAndExtension( sPath )			// will be empty string if user cancelled  or else valid directory (but possibly up in the hierachy and NOT the directory which the user had typed in the 'STR' control input field)
//	endif
//	 printf "\t\tUFCom_DirCheckAndPossiblyDialog...3()   returns    '%s' \t \r",  sPath	
//	return	sPath
//End


static strconstant	csREADMODE			= "cREADMODE"	// must be the same in XOP  and in IGOR

Function	/S	UFCom_FileDialog( sPath, sFilter )				
// Offers file open dialog starting with 'sPath' .  Returns the selected path  or the original  'sPath'  if the user cancelled .
	string 	sPath, sFilter								// path  to start from (e.g. which the user entered in the Setvariable control). This path may be valid  or  not, or even empty.  
	string 	sDefExtOrReadMode	= csREADMODE			// must be 'cREADMODE' to trigger file open dialog, else file save dialog is triggered and this is the ext appended to file ( e.g. "" or "FIT" )
	string 	sPrompt			= "Select file"
	string 	sFilePath			= ""						// not used in Open file dialog. Should be  '_'  for directory selection.
	string 	sSelectedPath		= ""						// temporary storage for  dialog selection, will be empty  string  if user cancelled

	// printf "\t\tUFCom_UtilFileDialog(1)  \t\treceives sPath:\t%s\tsFilter: '%s'  \r",  UFCom_pd( sPath,35 ), sFilter
	sSelectedPath	= UFCom_UtilFileDialog( sPrompt, sFilter, 1, sPath,  sDefExtOrReadMode, sFilePath )	// works with  sPath = "C:\\Epc\\data\\"  or  "C:Epc:"   or  "C:"  but instead of empty path the last valid path is taken
	if ( strlen( sSelectedPath ) )
		sPath	= sSelectedPath
	endif
	// printf "\t\tUFCom_UtilFileDialog(2)  \t\treturns   sPath:\t%s\tThe dialog box returned   sSelectedPath: '%s' \t \r",  UFCom_pd( sPath,35 ), sSelectedPath	
	return	sPath 
End


// 2008-02-27 not needed, use Open /D refnum as  pathfile, see UFCom_SaveAsPanelVars()
//Function	/S	UFCom_FileSaveDialog( sPath, sFilter, sDefExt )				
//// Offers file open dialog starting with 'sPath' .  Returns the selected path  or the original  'sPath'  if the user cancelled .
//	string 	sPath, sFilter, sDefExt								// path  to start from (e.g. which the user entered in the Setvariable control). This path may be valid  or  not, or even empty.  
////	string 	sDefExtOrReadMode	= csREADMODE			// must be 'cREADMODE' to trigger file open dialog, else file save dialog is triggered and this is the ext appended to file ( e.g. "" or "FIT" )
//	string 	sPrompt			= "Select file"
//	string 	sFilePath			= ""						// not used in Open file dialog. Should be  '_'  for directory selection.
//	string 	sSelectedPath		= ""						// temporary storage for  dialog selection, will be empty  string  if user cancelled
//
//	 printf "\t\tUFCom_UtilFileSaveDialog(1)  \t\treceives sPath:\t%s\tsFilter: '%s'  \r",  UFCom_pd( sPath,26 ), sFilter
//	sSelectedPath	= UFCom_UtilFileDialog( sPrompt, sFilter, 1, sPath,  sDefExt, sFilePath )	// works with  sPath = "C:\\Epc\\data\\"  or  "C:Epc:"   or  "C:"  but instead of empty path the last valid path is taken
//	if ( strlen( sSelectedPath ) )
//		sPath	= sSelectedPath
//	endif
//	 printf "\t\tFileSaveDialog(2)   returns\t\t\tsPath:\t\t%s\tThe dialog box returned   sSelectedPath: '%s' \t \r",  UFCom_pd( sPath,26 ), sSelectedPath	
//	return	sPath 
//End
