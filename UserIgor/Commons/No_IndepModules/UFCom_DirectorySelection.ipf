//
//  UFCom_DirectorySelection.ipf 
// 
#pragma rtGlobals=1							// Use modern global access method.

//#pragma IndependentModule=UFCom_
#include "UFCom_Constants"


//===============================================================================================================================
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  DIRECTORY SELECTION  DIALOG  BOX

static	  strconstant	csDIRPROMPT		= "Select directory"
static	  strconstant	csDIRFILTER		= "Directories; ;;"
static	  strconstant	csDIRDUMMY		= "_"		// "'" or "_"	// Should be  1 character  for directory selection as xUtilFileDialog() requires a dummy file name even for directory selection. 
static	  constant		cDIRINDEX		= 1					// the one-based index of the initial selection in the file type listbox 

Function	/S	UFCom_DirectoryDialog( sPath )				
// Allows selection of a directory with a generic file open dialogbox which gives a better user interface than standard dialog box because only dirs are shown, files are hidden.
// always returns a valid path: If the user CANCELS the initially passed path is returned unchanged
	string 	sPath									// path  to start from (e.g. which the user entered in the Setvariable control). This path may be valid  or  not, or even empty.  
	string 	sSelectedPath	= xUtilFileDialog( csDIRPROMPT, csDIRFILTER, cDIRINDEX, sPath, "", csDIRDUMMY )	// sample for  directory selection dialog
 printf "xUtilxUtil\t\tDirectoryDialog(4) \txUtilFileDialog(  %d,  '%s',  '' ,  '%s' )  returns  sSelectedPath: '%s' \t \r",  cDIRINDEX, sPath,  csDIRDUMMY , sSelectedPath	
	variable	bSelectionOK	= cmpstr( sSelectedPath, csDIRDUMMY )	// if CANCELLED the  Open file dialog returns the initially received string  :  FALSE,  we then revert to the last valid path...
	sPath = SelectString( bSelectionOK, sPath, UFCom_StripFileAndExtension( sSelectedPath )	)// only if  NOT CANCELLED we overwrite the selected path  (after removing the dummy file '_' )  for returning it
	// printf "\t\tDirectoryDialog() \tDialog box returned: %s  \t-> we return: %s\t%s \r",  UFCom_pd(sSelectedPath,24),   UFCom_pd( sPath,24), SelectString( bSelectionOK, "User cancelled", "Selection OK" )
	return	sPath
End

Function	/S	UFCom_DirCheckAndPossiblyDialog( sPath )					
// Allows selection of a directory with an text input field. If the text input is not a valid directory then a generic file open dialogbox pops up.
// This generic file open dialogbox gives a better user interface than standard dialog box because only dirs are shown, files are hidden.
// Returns an empty path  if the user makes nonsense input or cancels
	string 	sPath								// path  to start from (e.g. which the user entered in the Setvariable control). This path may be valid  or  not, or even empty.  
	string 	sSelectedPath	= ""						// temporary storage for  parentPath  and  dialog selection
	variable	bDirExists		= UFCom_FPDirectoryExists( sPath )	// Check if the passed  'sPath'  is already a  valid directory....
	// printf "\t\tDirectoryCheckAnd...1() \tsPath: %s\t-> Dir exists:%d   -> %s \r",  UFCom_pd( sPath,30 ), bDirExists, SelectString( bDirExists, "search parent dir and  display dialog", "return this dir" )
	if ( ! bDirExists ) 									// .. if it is then use it directly without  displaying the dialog box
		do										// walk back in the directory hierarchy level for level towards the root...
			sSelectedPath	= ParentFolder( sPath ) 		
			if ( cmpstr( upperstr( sPath ) , upperstr( sSelectedPath ) ) )	// if they differ...
				sPath	= sSelectedPath					// ..try again
			else 											// if they are the same..
				sPath	= "C:"							// ..we can't go further because we are at the end  (=in the root)
			endif
			bDirExists	= UFCom_FPDirectoryExists( sPath )
			// printf "\t\tDirectoryCheckAnd...2() \tsPath: %s\t-> Dir exists:%d\tSelectP: %s \t \r",  UFCom_pd( sPath,30 ), bDirExists,  UFCom_pd( sSelectedPath,30)	
		while ( ! bDirExists )							// ...until a valid directory is found : Use this as a starting directory for the dialog box below

 printf "\t\txUtilxUtilDirectoryCheckAnd...2() \tsPath: %s\t-> Dir exists:%d\tSelectP: %s \t \r",  UFCom_pd( sPath,30 ), bDirExists,  UFCom_pd( sSelectedPath,30)	
		sPath	= xUtilFileDialog( csDIRPROMPT, csDIRFILTER, cDIRINDEX, sPath, "", csDIRDUMMY )	// sample for  directory selection dialog
		sPath	= UFCom_StripFileAndExtension( sPath )
	endif
	// printf "\t\tDirectoryCheckAnd...3()   returns    '%s' \t \r",  sPath	
	return	sPath
End


strconstant	csREADMODE			= "cREADMODE"	// must be the same in XOP  and in IGOR

Function	/S	UFCom_FileDialog( sPath, sFilter )				
	string 	sPath, sFilter							// path  to start from (e.g. which the user entered in the Setvariable control). This path may be valid  or  not, or even empty.  
	string 	sDefExtOrReadMode	= csREADMODE		// must be 'cREADMODE' to trigger file open dialog, else file save dialog is triggered and this is the ext appended to file ( e.g. "" or "FIT" )
	string 	sPrompt			= "Select file"
	string 	sFilePath			= ""					// not used in Open file dialog. Should be  '_'  for directory selection.
	string 	sSelectedPath		= ""					// temporary storage for  dialog selection, will be empty  string  if user cancelled

	 printf "\t\xUtilxUtilFileDialog(1) receives\tsPath: '%s'      sFilter: '%s'  \r",  UFCom_pd( sPath,30 ), sFilter
	sSelectedPath	= xUtilFileDialog( sPrompt, sFilter, 1, sPath,  sDefExtOrReadMode, sFilePath )	// works with  sPath = "C:\\Epc\\data\\"  or  "C:Epc:"   or  "C:"  but instead of empty path the last valid path is taken
	if ( strlen( sSelectedPath ) )
		sPath	= sSelectedPath
	endif
	 printf "\t\tFileDialog(2) returns\tsPath: %s\tThe dialog box returned   sSelectedPath: '%s' \t \r",  UFCom_pd( sPath,30 ), sSelectedPath	
	return	sPath 
End

