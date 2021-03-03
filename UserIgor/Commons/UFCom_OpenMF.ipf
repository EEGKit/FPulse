//
// UFCom_OpenMF.ipf		
//			wrapper for  and requiring  the  OpenMF XOP  (from Mamoru Yamanishi)  which allows to select multiple files
//			this XOP requires  #pragma rtGlobals=0   for both correctly working AND for handling the ESC case gracefully.
//			Otherwise we get NULL pointer troubles if  the dialog box is left with 'ESC'

#pragma rtGlobals=0						// the  OpenMF  XOP  requires to use the obsolete  global access method.


Function 	/S	UFCom_MultipleFileSelection_( sDirectory )	
// Allows selection of multiple files from given directory which are returned as a list.  
// Requires  'OpenMF-win-1.4.xop' 
// Returns the list of files which the user has selected.  PASSES BACK the MAC-STYLE directory  (without colon) to which the user has navigated.
	string  	&sDirectory	
	string  	sWinPath		= UFCom_Path2Win( sDirectory )
	// print "UFCom_MultipleFileSelection _ a  ", sDirectory, s_Path
	string		sDFSave		= GetDataFolder( 1 )			// The following function does NOT restore the CDF so we remember the CDF in a string .

	NewDataFolder 	/O /S root:uf						// assumption:  root:uf exists  (neither  root   nor    _OpenMF   works)
//	SetDataFolder 		root:uf						// assumption:  root:uf exists  (neither  root   nor    _OpenMF   works)
		
	OpenMF 	/X=-1 sWinPath							// Allow picking multiple files, requires  'OpenMF-win-1.4.xop'
//	string 	lstFiles	= root:uf:s_FileName
//	string  /G	lstFiles	= root:uf:s_FileName

	svar		lstFiles	= root:uf:s_FileName
	svar		sPath	= root:uf:s_Path

	sDirectory	= RemoveEnding( UFCom_Path2Mac( sPath ), ":" )
	 printf "\t\tUFCom_MultipleFileSelection_  b   sDirectory:%s,  s_Path:%s,  lstFiles:%s\r", sDirectory, sPath, lstFiles
	SetDataFolder sDFSave
	return	lstFiles
End

		

// convert also to root:uf.....like above

Function 	/S	UFCom_MultipleFileSelection( sDirectory )			
// Allows selection of multiple files from given directory which are returned as a list.  
// Requires  'OpenMF-win-1.4.xop' 
	string		sDirectory
	string  	sWinPath		= UFCom_Path2Win( sDirectory )
	// print "UFCom_MultipleFileSelection  a  ", sDirectory, s_Path
//	svar 		gs_FileName	=  root:s_FileName			// Introducing  'gs_FileName'  avoids NULL pointer troubles if  the dialog box is left with 'ESC'
//	svar 		gs_FileName	=  root:uf:s_FileName			// Introducing  'gs_FileName'  avoids NULL pointer troubles if  the dialog box is left with 'ESC'
//	svar 		s_FileName//	=  root:uf:s_FileName			// Introducing  'gs_FileName'  avoids NULL pointer troubles if  the dialog box is left with 'ESC'
//	string /G	root:s_FileName = ""
//	svar 		gs_FileName	= root:s_FileName			// Introducing  'gs_FileName'  avoids NULL pointer troubles if  the dialog box is left with 'ESC'

// 2009-04-29
//	string		sDFSave		= GetDataFolder( 1 )			// The following function does NOT restore the CDF so we remember the CDF in a string .
//	NewDataFolder	root:uf
//	SetDataFolder 	root:uf
//	
//	OpenMF 	/X=-1 sWinPath							// Allow picking multiple files, requires  'OpenMF-win-1.4.xop'
//	string 	lstFiles	= root:uf:s_FileName
//	SetDataFolder sDFSave
//	return	lstFiles
	
	string		sDFSave		= GetDataFolder( 1 )			// The following function does NOT restore the CDF so we remember the CDF in a string .
//	SetDataFolder 	root
	
	OpenMF 	/X=-1 sWinPath							// Allow picking multiple files, requires  'OpenMF-win-1.4.xop'
	string 	lstFiles	= root:s_FileName
	// print "UFCom_MultipleFileSelection  b  ", sDirectory, s_Path
	SetDataFolder sDFSave
	return	lstFiles
	
//	string 	lstFiles		= gs_FileName
//	string 	lstFiles		= gs_FileName
//	return	lstFiles
End

