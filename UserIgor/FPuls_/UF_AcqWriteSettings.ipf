//  UF_AcqWriteSettings.ipf
// 

#pragma  rtGlobals 	= 1					// Use modern global access method. 	Do not use a tab after #pragma. Doing so will give compilation error in Igor 4.

// General  'Includes'
#include "UFCom_Constants"
#include "UFCom_DirectorySelection"
#include "UFCom_DirsAndFiles"
//#include "UFPE_Constants3"


static strconstant	ksDEF_DATAPATH	= "D:Data:Epc:"					// IGOR prefers MacIntosh style separator for file paths, to use the windows path convention a conversion is needed  


//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function		fStart( s ) 
	struct	WMButtonAction	&s
	string  	sFo		= ksACQ
//	string  	sSubFoC	= SelectString( NewStyle( sFo) , "co" , UFPE_ksCOns )
//	string  	sSubFoW	= SelectString( NewStyle( sFo) , UFPE_ksKPwg , UFPE_ksKPwgns )
	 printf "\tButtonProc \t%s\t%s \r",  s.ctrlname, sFo
	StartActionProc_ns( sFo, UFPE_ksCOns )
End


Function		fStopFinish( s ) 
	struct	WMButtonAction	&s
	string  	sFo		= ksACQ
//	string  	sSubFoC	= SelectString(   sFo) , "co" , UFPE_ksCOns )
//	string  	sSubFoW	= SelectString( NewStyle( sFo) , UFPE_ksKPwg , UFPE_ksKPwgns )
	 printf "\t\tButtonProc \t%s\t%s \r",  s.ctrlname, sFo
	FinishActionProc_ns( sFo, UFPE_ksCOns )
End

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -	

Function		fWatchWrite( s ) 
	struct	WMButtonAction	&s
	nvar		state			= $ReplaceString( "_", s.ctrlname, ":" )		// Actually not required: The underlying button variable name can be derived from the control name. Version2 : Call access function 'WriteMode()'
	 printf "\t\t\t\t%s\tvalue:%2d =?=%2d  \t \r",  s.ctrlname, state, WriteMode()	
End
Function		WriteMode()
	nvar		bWriteMode	= root:uf:acq:pul:gbWriteMode0000
	return	bWriteMode
End

Function	/S	fWatchWriteColLst()
	return	"48000,0,0~0,40000,0"
End


//Function		fAcqStatus( s ) 					// not needed
//	struct	WMCustomControlAction	&s
//	printf "\t\tCustomCProc \t%s\t \r",  s.ctrlname
//End
Function	/S	fAcqTitleColorLst()
// The titles and colors of a color field are combined and stored in 'FormatEntry'  as the RowTitle and ColumnTitle  columns do not handle the lists with color field items correctly, e.g. the instead of the length of the longest item the length of the whole list is returned...
	return  "wait Start?~wait Trig?~reloading~acquiring" + "|" + "35000,35000,65535 ~ 60000,0,65000 ~ 60000,60000,0 ~ 0,60000,0"
End

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -	

// Version 1 : TrigMode  implemented as popupmenu
Function		fTrigMode( s ) 
	struct	WMPopupAction	&s
	 printf "\t\tfTrigMode( Popup ) \t\tbTrigMode : %d  %s  (%s) \r", TrigMode(), SelectString( TrigMode(), " Start", "Bnc E3E4" ), s.ctrlname
	string  	sSubFoC	= UFPE_ksCOns
	string  	sSubFoW	= UFPE_ksKPwgns 

	SwitchTriggerMode( sSubFoC, sSubFoW )
End
Function		fTrigModePops( sControlNm, sFo, sWin )
	string		sControlNm, sFo, sWin
	PopupMenu	$sControlNm, win = $sWin,	 value = "[ Start ];BNC E3-4;"	//lstTRIGMODE	// e.g. "'Start'; E3E4;" 	Popmenus need semicolon separators
End
Function		TrigMode()
	nvar		bTrigMode		= $"root:uf:acq:pul:pmTrigMode0000"			// implemented as popupmenu
	return	bTrigMode - 1										// items are one-based
End


// // Version 2 : TrigMode  implemented as  radio button (can be horizontal or vertical) 
//Function		fTrigMode( s )
//	struct	WMCheckboxAction	&s
//	 printf "\t\tfTrigMode( Radio ) \t\tbTrigMode : %d  %s  (%s) \r", TrigMode(), SelectString( TrigMode(), " Start", "Bnc E3E4" ), s.ctrlname
//	SwitchTriggerMode()
//End
//Function		TrigMode()
//	nvar		bTrigMode		= $"root:uf:acq:pul:raTrigMode00"			// implemented as radio button
//	return	bTrigMode
//End


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -	

Function		fAutoBackup( s ) 
	struct	WMCheckboxAction	&s
	// printf "\t\tCheckboxProc\t\t%s\tvalue:%2d   \t \r",  s.ctrlname, s.checked	
	Ini_AutoBackupSet( s.checked )
End

Function		AutoBackup()
	nvar		bAutoBckup	= root:uf:acq:pul:cbAutoBckup0000
	// printf "\t\tAutoBackup   : %d \r", bAutoBckup
	return	bAutoBckup
End

Function		SetAutoBackup( bValue )
	variable	bValue
	nvar		bAutoBckup	= root:uf:acq:pul:cbAutoBckup0000
	bAutoBckup	= bValue
	// printf "\t\tSetAutoBackup : %d \r", bValue
End

Function		Ini_AutoBackup()
	variable	bValue	= str2num( UFCom_Ini_Section( ksACQ, "FPuls", "Set", "Autobackup" ) ); 	bValue  = ( numtype( bValue )	!= UFCom_kNUMTYPE_NAN )	?    bValue	   :   0	// default value should match panel initialisation entry
	return	bValue
End

Function		Ini_AutoBackupSet( bValue )
	variable	bValue
	string  	sIniBasePath	= FunctionPath( ksFP_APP_NAME )					// the Ini file containing the window position will be written in a subdirectory parallel to UF_PulseMain.ipf 
	UFCom_IniFile_SectionSetWrite( ksACQ, "FPuls", "Set", "Autobackup", num2str( bValue), sIniBasePath ) 
End

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -	

Function		fAppendData( s ) 
// The usage of the  'Load Script' button   and the  'Append data' checkbox  sometimes leads to user complaints and confusion but the implementation should actually be that way.
// If the 'Append data' mode  is ON  and the user then loads a new script  the new data will be appended to the old data file (file name will NOT increment).  This is a special but desired behaviour of FPulse as it allows to continue the data file even if the script changed!
// If the 'Append data' mode  is ON  and the user then loads a new script  AND wants to start a new file witththe incremented file name he/she has to  click the 'Append data' checkbox  TWICE.
	struct	WMCheckboxAction	&s
 	string  	sFo	 			= StringFromList( 2, s.ctrlName, "_" )		// e.g. 'acq'			
	// printf "\t\tCheckboxProc\t\t%s\tvalue:%2d  [sFo:'%s'] \t \r",  s.ctrlname, s.checked, sFo	
	Ini_AppendDataSet( s.checked )
	
// 2008-04-22  Append only in _ns new style
	FinishActionProc_ns( sFo, UFPE_ksCOns )				// Most probably the user wants to start a new  file after he/she has switched this basic mode. Includes Button update.
End

Function		AppendData()
	nvar		bAppndData	= root:uf:acq:pul:cbAppndData0000
	// printf "\t\tAppendData() : %d \r", bAppndData
	return	bAppndData
End

Function		SetAppendData( bAppendData )
	variable	bAppendData
	nvar		bAppndData	= root:uf:acq:pul:cbAppndData0000
	bAppndData	= bAppendData
	// printf "\t\tSetAppendData() : %d \r", bAppendData
End

Function		Ini_AppendData()
	variable	bValue	= str2num( UFCom_Ini_Section( ksACQ, "FPuls", "Set", "AppendData" ) ); 	bValue  = ( numtype( bValue )	!= UFCom_kNUMTYPE_NAN )	?    bValue	   :   0	// default value should match panel initialisation entry
	return	bValue
End

Function		Ini_AppendDataSet( bValue )
	variable	bValue
	string  	sIniBasePath	= FunctionPath( ksFP_APP_NAME )					// the Ini file containing the window position will be written in a subdirectory parallel to UF_PulseMain.ipf 
	UFCom_IniFile_SectionSetWrite( ksACQ, "FPuls", "Set", "AppendData", num2str( bValue), sIniBasePath ) 		// last parameter 1 : write INI file immediately
End

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -	

Function		fProts( s )
	struct	WMSetVariableAction  &s
	ApplyScript()
End

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -	

Function		fDataPath( s ) 
// Action proc  for the  'Data'  button  which when pressed will open the  'Directory Open dialog Box' 
// If the user entered an invalid path or cancelled the initial valid directory is used.
	struct	WMButtonAction	&s
	string		sDataDir	= DataDir() 						// Get contents of the  Setvariable 'DataDir' Text Input Field  and use it ... 
	sDataDir			= UFCom_DirectoryDialog( sDataDir ) 		// ...as a starting dir for the File open dialog box containing only directories. If the user cancels, the passed string is returned unchanged.
	DataDirSet( sDataDir ) 								// The text input field should always reflect the currently active directory (the dialog box may have changed it after the input field has been left)
	Ini_DataDirSet( sDataDir )								// store the content of the 'DataDir'  Setvariable string input field  in the INI file
	SearchAndSetLastUsedFile()							//  if the  directory  changes we must again discriminate between used and unused files (update also 'gsDataFileW' )
	printf "\t\t%s\t\tfDataPath   \t\thas set global sDataDir: '%s' \t  \r",  s.ctrlname, sDataDir
End

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -	

Function		fDataDir( s ) 
// Action proc  for the  Setvariable 'DataDir' Text Input Field   which displays the  Data Directory   and which also allows to type in a new directory 
// Called  AFTER  the user has entered  a string into the text input field of the temporary global  'gsDataDir' . 
// This string may or may not be a valid directory. 
//  User typed in a valid directory :  This directory is used.    User typed in invalid directory : The directory is created and used.
//  Note:  There is also different version  where the next valid directory up in the hierachy will be used if the user typed in an invalid path and then cancelled.  This is not used but can be found  in  'UFCom_DirCheckAndPossiblyDialog() 
	struct	WMSetVariableAction	&s
	 printf "\t\tfDataDir  \t%s\t'%s'  \t \r",  s.ctrlname, s.sval
	variable	varNum
	svar		sDataDir	= root:uf:acq:pul:gsDataDir0000
	// printf "\t\tfDataDir1( cNm: '%s'  vNm: '%s'  num:%2d  vStr:%s )  \r", ctrlName, varName,  varNum, varStr

	// Version1:  061113	User typed in  a  valid   directory :		This directory is used
	//				User typed in an invalid directory :		The directory is created and used.
	sDataDir	= RemoveEnding( sDataDir, ":" ) + ":"				// path must end with exactly 1 colon (flaw: multiple colons are not caught)
	if ( ! UFCom_DirectoryExists( sDataDir ) )								// Check if the directory returned by the 'STR' text input field is valid...
		if ( UFCom_PossiblyCreatePath( sDataDir )  == UFCom_kOK )			// ...and build it if it did not exist
			Ini_DataDirSet( sDataDir )									// store the content of the 'DataDir'  Setvariable string input field  in the INI file
			SearchAndSetLastUsedFile()								// if the  directory  changes we must again discriminate between used and unused files (updates also 'gsDataFileW' )
			// printf "\t\tfDataDir2a() \thas set global sDataDir: '%s' \t \r",   sDataDir	
		endif
	endif
End


Function	/S	DataDir() 
	svar		sDataDir	= root:uf:acq:pul:gsDataDir0000
	return	sDataDir
End

Function		DataDirSet( sDataDir_ ) 
	string  	sDataDir_
	svar		sDataDir	= root:uf:acq:pul:gsDataDir0000
	sDataDir			= sDataDir_
End

Function	/S	Ini_DataDir()
	string  	sDataDir	= UFCom_Ini_Section( ksACQ, "FPuls", "Set", "DataDir" ) ); 	sDataDir  = SelectString( strlen(sDataDir) == 0 , sDataDir,  ksDEF_DATAPATH ) //"D:User:Epcc:" ) // default value (must have trailing colon)
	return	sDataDir
End

Function		Ini_DataDirSet( sDataDir )
	string  	sDataDir
	string  	sIniBasePath	= FunctionPath( ksFP_APP_NAME )					// the Ini file containing the window position will be written in a subdirectory parallel to UF_PulseMain.ipf 
	UFCom_IniFile_SectionSetWrite( ksACQ, "FPuls", "Set", "DataDir", sDataDir, sIniBasePath ) 	// last parameter 1 : write INI file immediately
End

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -	
// Access functions for  gsDataFileW

Function	/S	DataFileW() 
	svar		sDataFileW	= root:uf:acq:pul:gsDataFileW0000
	return	sDataFileW
End
Function		DataFileWSet( sDataFileW_ ) 
	string  	sDataFileW_
	svar		sDataFileW	= root:uf:acq:pul:gsDataFileW0000
	sDataFileW			= sDataFileW_
End

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -	

Function		fFileBase( s ) 
	struct	WMSetVariableAction	&s
	 printf "\t\tSetVariableProc\t\t%s\t  \t \r",  s.ctrlname
	svar		sFileBase	= root:uf:acq:pul:gsFileBase0000
	Ini_FileBaseSet( sFileBase ) 
	SearchAndSetLastUsedFile()		// if the filebase changes we must again discriminate between used and unused files (update also 'gsDataFileW') 
End

Function	/S	FileBase()
	svar		sFileBase	= root:uf:acq:pul:gsFileBase0000
	return	sFileBase
End

Function		SetFileBase( sFilebase_ )
	string  	sFilebase_
	svar		sFileBase	= root:uf:acq:pul:gsFileBase0000
	sFileBase			= sFilebase_
	// printf "\t\tSetFileBase   : %s \r", sFileBase
End

Function	/S	Ini_FileBase()
	string  	sFileBase	= UFCom_Ini_Section( ksACQ, "FPuls", "Set", "FileBase" ) ); 	sFileBase  = SelectString( strlen(sFileBase) == 0 , sFileBase,  "NoName" ) // default value 
	return	sFileBase
End

Function		Ini_FileBaseSet( sFileBase )
	string  	sFileBase
	string  	sIniBasePath	= FunctionPath( ksFP_APP_NAME )					// the Ini file containing the window position will be written in a subdirectory parallel to UF_PulseMain.ipf 
	UFCom_IniFile_SectionSetWrite( ksACQ, "FPuls", "Set", "FileBase", sFileBase, sIniBasePath ) 	// last parameter 1 : write INI file immediately
End

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -	

Function		fCell( s ) 
	struct	WMSetVariableAction	&s
	 printf "\t\tSetVariableProc\t\t%s\t  \t \r",  s.ctrlname
	SearchAndSetLastUsedFile()		// if the   cell   changes we must again discriminate between used and unused files (update also 'gsDataFileW')
End
Function		Cell()
	nvar		gCell			= root:uf:acq:pul:gCell0000
	return	gCell
End

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -	

Function		fDelete( s ) 
//? todo  : only allowed when  WriteMode is on,  or is off,  or MessageBox "About to delete...."....
	struct	WMButtonAction	&s
	// printf "\t\tButtonProc \t%s\t \r",  s.ctrlname
	variable	nCell		 = Cell()
	nvar		gFileIndex	 = root:uf:acq:cfsw:gFileIndex
	string		sDataFileW= DataFileW()
	// 	Actually do delete the file. Necessary because now existing files are NOT overwritten, previously  they were  if  gFileIndex  pointed to them
	string		sDataDir	 = DataDir()

	DeleteFile  /Z=1 sDataDir + sDataFileW						// erase the current data file, do not complain if it is missing
	
	gFileIndex	= max( -1, gFileIndex - 1 )							// go back one fileindex (can be -1=__=no file yet)
	DataFileWSet( GetFileName() + UFPE_ksCFS_EXT )				// autoupdates the SetVariable control	
End

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -	

