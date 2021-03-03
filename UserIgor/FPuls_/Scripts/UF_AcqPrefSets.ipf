//
// UF_AcqPrefSets.ipf
// 	Functions implementing  Igors 'Preferences' approach to save settings
//
//
//	General considerations: 
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


// NOTE: The name you choose must be distinctive!
static strconstant	kPackageName 	= "UFPulse"
static strconstant	kPreferencesFileNm	= "UFPulsePreferences.bin"
static constant		kPrefsRecordID		= 0				// The recordID is a unique number identifying a record within the preference file.
												// In this example we store only one record in the preference file.

structure 		FPulsePrefs
	uint32	version								// Preferences structure version number. 100 means 1.00.
	double	panelCoords[ 4 ]							// left, top, right, bottom

	char  	sScriptPath[ 100 ]						// 061107 FPPrefs
	char  	sInDataDir[ 100 ]						// 061109 FPPrefs
	char  	sFilebase[ 100 ]
	uint32	nProtocols
	uchar	bAppendData
	uchar	bAutoBackup
	uchar	bRequireCed
//	uchar	phaseLock
//	uchar	triggerMode
//	double	ampGain
	uint32	reserved[ 80 ]							// Reserved for future use
endstructure


Function		FPulseLoadPackagePrefs( FPPrefs )
	struct	FPulsePrefs &FPPrefs

	variable currentPrefsVersion = 107

	// This loads preferences from disk if they exist on disk.
	LoadPackagePreferences kPackageName, kPreferencesFileNm, kPrefsRecordID, FPPrefs
	// print "\r\rFPulseLoadPackagePrefs()  attempting to load...", FPPrefs
	// printf "\t\tFPulseLoadPackagePrefs() %d byte loaded\r", V_bytesRead

	// If error or FPPrefs not found or not valid, initialize them.  Any intialisations specified in the panel text wave are overwritten here.
	if ( V_flag != 0  ||  V_bytesRead == 0  ||  FPPrefs.version != currentPrefsVersion )
		FPPrefs.version 		= currentPrefsVersion

		FPPrefs.panelCoords[0]	= 5					// Left
		FPPrefs.panelCoords[1]	= 40					// Top
		FPPrefs.panelCoords[2] 	= 5+190				// Right
		FPPrefs.panelCoords[3]	= 40+125				// Bottom

		FPPrefs.sScriptPath		= ksSCRIPTS_DRIVE + ksSCRIPTS_DIR + ":"	// 061107 FPPrefs
		FPPrefs.sInDataDir		= ksDEF_DATAPATH									// 061109 FPPrefs		only used for text input directory selection	
		FPPrefs.sFilebase		= "No_Nm"			// should match panel initialisation entry

//		FPPrefs.nProtocols		=
		FPPrefs.bAppendData	= 0					// should match panel initialisation entry
		FPPrefs.bAutoBackup	= 0					// should match panel initialisation entry

//		FPPrefs.bRequireCed	= 1

//		FPPrefs.phaseLock = 1
//		FPPrefs.triggerMode = 1
//		FPPrefs.ampGain = 1.0

		variable	i
		for ( i = 0;  i < 80;  i += 1 )
			FPPrefs.reserved[ i ]	= 0
		endfor
		 print "\rFPulseLoadPackagePrefs()  loading failed, initalising....", FPPrefs

		FPulseSavePackagePrefs( FPPrefs )				// Create default FPPrefs file.
	endif
End


Function 		FPulseSavePackagePrefs( FPPrefs )
	struct	FPulsePrefs &FPPrefs
	// print "\rFPulseSavePackagePrefs()  saving... ", FPPrefs
	SavePackagePreferences kPackageName, kPreferencesFileNm, kPrefsRecordID, FPPrefs
End


//static Function AcmePanelCheckProc(ctrlName,checked) : CheckBoxControl
//	String ctrlName
//	Variable checked
//
//	struct FPulsePrefs FPPrefs
//	FPulseLoadPackagePrefs(FPPrefs)
//	
//	strswitch(ctrlName)
//		case "PhaseLock":
//			FPPrefs.phaseLock = checked
//			break
//	endswitch
//
//	FPulseSavePackagePrefs(FPPrefs)
//End
//
//
//static Function AcmePanelPopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
//	String ctrlName
//	Variable popNum
//	String popStr
//
//	struct  	FPulsePrefs	FPPrefs
//	FPulseLoadPackagePrefs( FPPrefs )
//	
//	strswitch(ctrlName)
//		case "TriggerMode":
//			FPPrefs.triggerMode = popNum
//			break
//		
//		case "AmpGain":
//			FPPrefs.ampGain = str2num(popStr)
//			break
//	endswitch
//			
//	FPulseSavePackagePrefs(FPPrefs)
//End


//static Function FPulsePanelHook(infoStr)
//	string 	infoStr
//
//	struct	FPulsePrefs FPPrefs
//	
//	String event= StringByKey("EVENT",infoStr)
//	strswitch(event)
//		case "activate":				// We do not get this on Windows when the panel is first created.
//			break
//
//		case "moved":				// This message was added in Igor Pro 5.04B07.
//		case "resize":
//			FPulseLoadPackagePrefs(FPPrefs)
//			GetWindow FPulsePanel wsize
//			// NewPanel uses device coordinates. We therefore need to scale from
//			// points (returned by GetWindow) to device units for windows created
//			// by NewPanel.
//			Variable scale = ScreenResolution / 72
//			FPPrefs.panelCoords[0] = V_left * scale
//			FPPrefs.panelCoords[1] = V_top * scale
//			FPPrefs.panelCoords[2] = V_right * scale
//			FPPrefs.panelCoords[3] = V_bottom * scale
//			FPulseSavePackagePrefs(FPPrefs)
//			break
//	endswitch
//	
//	return 0
//End


//Function 	ShowFPulsePanel()
//	DoWindow/F FPulsePanel
//	if (V_flag != 0)
//		return 0
//	endif
//
//	struct	FPulsePrefs FPPrefs
//	FPulseLoadPackagePrefs(FPPrefs)
//
//	Variable left = FPPrefs.panelCoords[0]
//	Variable top = FPPrefs.panelCoords[1]
//	Variable right = FPPrefs.panelCoords[2]
//	Variable bottom = FPPrefs.panelCoords[3]
//	NewPanel/W=(left, top, right, bottom) /K=1
//
//	DoWindow/C FPulsePanel
//
//	CheckBox PhaseLock, pos={31,24}, size={67,14}, proc=FPulse#AcmePanelCheckProc, title="Phase Lock", value=FPPrefs.phaseLock
//
//	Variable triggerMode = FPPrefs.triggerMode
//	PopupMenu TriggerMode,pos={31,50}, size={119,20}, proc=FPulse#AcmePanelPopMenuProc, title="Trigger Mode"
//	PopupMenu TriggerMode,  mode=triggerMode, value= #"\"Auto;Manual\""
//
//	Variable ampGainMode = 1
//	switch(FPPrefs.ampGain)
//		case 1:
//			ampGainMode = 1
//			break
//		case 2:
//			ampGainMode = 2
//			break
//		case 5:
//			ampGainMode = 3
//			break
//		case 10:
//			ampGainMode = 4
//			break
//	endswitch
//	PopupMenu AmpGain, pos={31,81}, size={119,20}, proc=FPulse#AcmePanelPopMenuProc, title="Amp Gain"
//	PopupMenu AmpGain, mode=ampGainMode, value= #"\"1;2;5;10\""
//
//	SetWindow kwTopWin,hook=FPulse#FPulsePanelHook
//End


