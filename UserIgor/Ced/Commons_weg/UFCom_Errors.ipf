//
//  UFCom_Errors.ipf 
// 
#pragma rtGlobals=1							// Use modern global access method.

#pragma IndependentModule=UFCom_
#include "UFCom_Constants"

//===============================================================================================================================
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//===============================================================================================================================
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//   !!!elsewhere also
strconstant		lstWARNING_LEVEL	= "fatal; severe; important; less important; message;"	//  Popmenus need semicolon separators
constant			kERR_FATAL = -1, kERR_SEVERE = 0, kERR_IMPORTANT = 1, kERR_LESS_IMPORTANT = 2, kERR_MESSAGE = 3//,  kERR_NONE = 4 


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  WARNINGS  AND  ERRORS

// The program defines 5 specific warning levels for every error, which are compared to the level set by the user 
//  prg level -1 :	Fatal error.			User must acknowledge an error message box before proceeding.					User  CANNOT turn beep off.  	e.g.	'script syntax error'
//  prg level 0 :	Severe warning.		User CANNOT turn off printing the warning in the history area.					User  CANNOT turn beep off.  	e.g.	'sampling too fast with probably corrupted data'
//  prg level 1 :	Important warning.	User can turn off printing the warning in the history area by setting the level to   1.		User  can turn the beep off.	e.g.	'sampling too fast with probably data OK  or  telegraph gain faulty'
//  prg level 2 :	Less important warn.	User can turn off printing the warning in the history area by setting the level to <= 2.	User  can turn the beep off.   	e.g.	'could not evaluate or fit..'
//  prg level 3 :	Message.			User can turn off printing the warning in the history area by setting the level to <= 3.	User  can turn the beep off.   	e.g.	'file not found'


Function	/S	UFCom_PrefPanelName( sFolder ) 
	string  	sFolder
	return	"prf" + sFolder[ 0, 0 ] 				// 'prfe'   in Eval    or  'prfa'  in  Acq   .  If this is changed all occurences of  'prfa'  and  'prfe'  must also be changed.
End


Function		UFCom_WarningLevel( sFolder )
	string  	sFolder
	nvar		nWarningLevel	= $"root:uf:" + sFolder + ":" + UFCom_PrefPanelName( sFolder ) + ":gnWarnLevl0000"
	return	nWarningLevel - 2					// popmenu items are 1-based : kSEVERE (=the first item)  has popup-internally the index 1 but in the program it is -1
End	

Function		UFCom_WarningBeep( sFolder )
	string  	sFolder
	nvar		bWarningBeep	= $"root:uf:" + sFolder + ":" + UFCom_PrefPanelName( sFolder ) + ":gbWarnBeep0000"
	return	bWarningBeep
End


// Simple version without  global 'gWarningLevel'
 Function		UFCom_Alert1( nPrgWarnLevel, sMessage )
	variable	nPrgWarnLevel
	string 	sMessage
	if ( nPrgWarnLevel == kERR_FATAL )				
		DoAlert	0, sMessage
		sMessage = "++++Error: " + sMessage
	else
		sMessage = "++Warning: " + sMessage
	endif
	printf "%s\r", sMessage
	Beep
End

Function		UFCom_Alert( nPrgWarnLevel, sMessage )
// Display warning message and possibly beep depending on importance of error but not on user level.. 
// This called from program parts which can be accessed from both  FPulse and  FEVAL  or  from  completely different programs which do not have a user setting for the warning level.
	variable	nPrgWarnLevel
	string 	sMessage
	if ( nPrgWarnLevel == kERR_FATAL )				
		DoAlert	0, sMessage
		sMessage = "++++Error: " + sMessage
		printf "%s\r", sMessage
		Beep
	else
	//	if ( nPrgWarnLevel <= kERR_MESSAGE )				// 060125  allow avoiding error message completely with kERR_NONE ( for BiggestContiguousMemory() )
			sMessage = "++Warning(" + num2str( nPrgWarnLevel + 1 ) + "): " + sMessage
			printf "%s\r", sMessage
			if ( nPrgWarnLevel >= kERR_IMPORTANT  )
				Beep
			endif
	//	endif
	endif
End

Function		UFCom_FoAlert( sFolder, nPrgWarnLevel, sMessage )
// Display warning message and possibly beep. The user may set the warning level separately in the program parts FPulse (sFolder='acq') and FEval (sFolder='eva') . 
	variable	nPrgWarnLevel
	string 	sFolder, sMessage
	variable   	nWarningLevel	= UFCom_WarningLevel( sFolder )
	variable   	bWarningBeep	= UFCom_WarningBeep( sFolder )
	if ( nPrgWarnLevel == kERR_FATAL )				
		DoAlert	0, sMessage
		sMessage = "++++Error: " + sMessage
		printf "%s\r", sMessage
		Beep
// 060526
//	elseif ( nWarningLevel > nPrgWarnLevel )			// 1:only severe warnings	2:many warnings	3:all warnings/messages
	elseif ( nWarningLevel >= nPrgWarnLevel )			// 1:only severe warnings	2:many warnings	3:all warnings/messages
		//sMessage = "++Warning: " + sMessage
		sMessage = "++Warning(" + num2str( nPrgWarnLevel + 1 ) + "): " + sMessage
		printf "%s\r", sMessage
		if ( bWarningBeep  ||  nPrgWarnLevel <= 0  )	// allow the user to run the program in quiet mode if it is a warning, but always beep on errors
			Beep
		endif
	endif
End

static strconstant	csReportError =	"PLEASE, PLEASE :   Report this warning/error to UF stating the exact conditions under which it occurred.\r\tNote Script file, data file, type of Patch Clamp Amplifier, type of CED1401, etc. so that the bug can be reproduced and fixed ! " 

Function 		UFCom_DeveloperError( sMessage )
// Catch fatal errors in the development phase e.g. automatic control names which are too long. A messagebox is opened to prevent overlooking the error. 
// This should NOT be used to detect unexpected errors occurring when the user is working with the program, use 'InternalError()'  for this case.
	string 	sMessage
	sMessage = "****Developer error: " + sMessage
	printf "\r%s\r", sMessage
	DoAlert 0, sMessage
	Beep						// do not let the user turn off the beep because this is a program error....
End

Function 		UFCom_InternalError( sMessage )
// Catch fatal unexpected programming errors in the user phase. 
// This should NOT be used to detect unexpected fatal conditions during the development phase, use 'DeveloperError()'  for this case.
	string 	sMessage
	sMessage = "****Internal error: " + sMessage
	printf "\r%s\r", sMessage
	printf "%s\r", csReportError
	Beep						// do not let the user turn off the beep because this is a program error....
End

Function		UFCom_InternalWarning( sMessage )
	string 	sMessage
	sMessage = "****Internal warning: " + sMessage
	printf "\r%s\r", sMessage
	printf "%s\r", csReportError
	Beep
End


Function 		UFCom_Beeper( cnt )
	variable	cnt
	variable	n
	for ( n = 0; n < cnt; n += 1 )
		Beep
 	endfor
End


Function		UFCom_PrintWave( sText, wNumbers )
// Prints the numbers contained in any 1dimensional wave and an informational text
	string 		sText
	wave	wNumbers
	variable	n
	printf "%s", sText
	for ( n = 0; n < numPnts( wNumbers ); n += 1 )
		printf "\t%7.2lf", wNumbers[ n ]
	endfor
	printf "\r"
End



