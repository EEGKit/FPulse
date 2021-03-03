
//   080717   OBSOLETE,   NO  LONGER  USEFUL    

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

//==========================================================================================================================================

// NOTE: The name you choose must be distinctive!
static strconstant	kPackageName 	= "UFPulse"
static strconstant	kPreferencesFileNm	= "UFPulsePrefSets.bin"
static constant		kPrefsRecordID		= 0				// The recordID is a unique number identifying a record within the preference file.
												// In this example we store only one record in the preference file.

structure 		FPulsePrefs
	uint32	version								// Preferences structure version number. 100 means 1.00.

	double	Sda[ 6 ]								// !!! 'sda' / ksACQ_SD 	panel coordinates left, top, right, bottom, visible, unused  OLD
	double	Uta[ 6 ]								// !!! 'uta'  / ksACQ_UTIL	panel coordinates left, top, right, bottom, visible, unused
	double	Prfa[ 6 ]								// !!! 'prfa' / ksACQ_PRF	panel coordinates left, top, right, bottom, visible, unused
	double	Mis[ 6 ]								// !!! 'mis' / ksF_MIS		panel coordinates left, top, right, bottom, visible, unused
	double	Cmt[ 6 ]								// !!! 'cmt' / ksF_CMT		panel coordinates left, top, right, bottom, visible, unused

	double	Dbg[ 6 ]								// !!! 'cmt' / ksF_CMT		panel coordinates left, top, right, bottom, visible, unused
	double	T1401[ 6 ]								// !!! 'cmt' / ksF_CMT		panel coordinates left, top, right, bottom, visible, unused

	double	Ola[ 6 ]								// !!! 'ola' / ksF_CMT		panel coordinates left, top, right, bottom, visible, unused

	char  	sScriptPath[ 100 ]						// 
	char  	sDataDir[ 100 ]						// 061109 FPPrefs
	char  	sFilebase[ 100 ]
	uint32	nProtocols
	uchar	bAppendData
	uchar	bAutoBackup
	uchar	bRequireCed
//	uchar	phaseLock
//	uchar	triggerMode
//	double	ampGain

// 080704  stdg kann weg....
	double	stdg[ 6 ]								// 108 !!! 'ola' / ksF_CMT		stimulus display graph	 coordinates left, top, right, bottom, visible, unused	
	double	script[ 6 ]			//FREE				//	 !!! ksSCRIPT_NBNM 	script notebook window  coordinates left, top, right, bottom, visible, unused  OLD

	uint32	reserved[ 56 ]//	reserved[ 80 ]							// Reserved for future use
endstructure



strconstant	ksDEF_DATAPATH	= "C:epc:data:"			// IGOR prefers MacIntosh style separator for file paths, to use the windows path convention a conversion is needed  


Function		FPulseLoadPackagePrefs( FPPrefs )
	struct	FPulsePrefs &FPPrefs

	variable currentPrefsVersion = 108

	// This loads preferences from disk if they exist on disk.
	LoadPackagePreferences kPackageName, kPreferencesFileNm, kPrefsRecordID, FPPrefs
	// print "\r\rFPulseLoadPackagePrefs()  attempting to load...", FPPrefs
	// printf "\t\tFPulseLoadPackagePrefs() %d byte loaded\r", V_bytesRead

	// If error or FPPrefs not found or not valid, initialize them.  Any initialisations specified in the panel text wave are overwritten here.
	if ( V_flag != 0  ||  V_bytesRead == 0  ||  FPPrefs.version != currentPrefsVersion )
		FPPrefs.version 		= currentPrefsVersion

//		FPPrefs.Prfa[UFCom_WLF]		= 500;	FPPrefs.Prfa[UFCom_WTP]	= 100;   	FPPrefs.Prfa[UFCom_WVI]		= 0
//		FPPrefs.Mis[UFCom_WLF]		= 540;	FPPrefs.Mis[UFCom_WTP] 	= 140;	FPPrefs.Mis[UFCom_WVI]		= 0
//		FPPrefs.Uta[UFCom_WLF]		= 660;	FPPrefs.Uta[UFCom_WTP]	 	= 360;   	FPPrefs.Uta[UFCom_WVI]		= 0
//		FPPrefs.stdg[UFCom_WLF]	= 800;	FPPrefs.stdg[UFCom_WTP]	= 500;   	FPPrefs.stdg[UFCom_WVI]		= 0		// 108 stimulus display graph	coordinates left, top, right, bottom, visible, unused	
//		FPPrefs.script[UFCom_WLF]	= 820;	FPPrefs.script[UFCom_WTP]	= 520;   	FPPrefs.script[UFCom_WRI]	= 1020;	FPPrefs.script[UFCom_WBO]	= 720;   	FPPrefs.script[UFCom_WVI]	= 0	// 108 script notebook window 	coordinates left, top, right, bottom, visible, unused	
//		FPPrefs.Sda[UFCom_WLF]		= 580;	FPPrefs.Sda[UFCom_WTP]	= 180;	FPPrefs.Sda[UFCom_WVI]		= 0
//		FPPrefs.Cmt[UFCom_WLF]		= 620;	FPPrefs.Cmt[UFCom_WTP]	= 320;   	FPPrefs.Cmt[UFCom_WVI]		= 0
//		FPPrefs.Dbg[UFCom_WLF]	= 700;	FPPrefs.Dbg[UFCom_WTP]	= 400;   	FPPrefs.Dbg[UFCom_WVI]		= 0
//		FPPrefs.T1401[UFCom_WLF]	= 740;	FPPrefs.T1401[UFCom_WTP]	= 440;   	FPPrefs.T1401[UFCom_WVI]	= 0
//		FPPrefs.Ola[UFCom_WLF]		= 780;	FPPrefs.Ola[UFCom_WTP]		= 480;   	FPPrefs.Ola[UFCom_WVI]		= 0


//		FPPrefs.sScriptPath		= UFPE_ksSCRIPTS_DRIVE + UFPE_ksSCRIPTS_DIR + ":"		// 
//		FPPrefs.sDataDir		= ksDEF_DATAPATH									// 061109 FPPrefs		only used for text input directory selection	
//		FPPrefs.sFilebase		= "No_Nm"			// should match panel initialisation entry

//		FPPrefs.nProtocols		=
//		FPPrefs.bAppendData	= 0					// should match panel initialisation entry
//		FPPrefs.bAutoBackup	= 0					// should match panel initialisation entry

//		FPPrefs.bRequireCed	= 1

//		FPPrefs.phaseLock = 1
//		FPPrefs.triggerMode = 1
//		FPPrefs.ampGain = 1.0



		variable	i
		for ( i = 0;  i < 68;  i += 1 )						// reduce MaxIndex by 12 when introducing a new window (6 doubles = 48 byte)
			FPPrefs.reserved[ i ]	= 0
		endfor
		 print "\rFPulseLoadPackagePrefs()  loading failed, initialising....", FPPrefs

		FPulseSavePackagePrefs( FPPrefs )				// Create default FPPrefs file.
	endif
End


Function 		FPulseSavePackagePrefs( FPPrefs )
	struct	FPulsePrefs &FPPrefs
	// print "\rFPulseSavePackagePrefs()  saving... ", FPPrefs
	SavePackagePreferences 		kPackageName, kPreferencesFileNm, kPrefsRecordID, FPPrefs		// writes to disk delayed (e.g. on Save Experiment) which is preferable when window is moved or resized
//	SavePackagePreferences /FLSH=1 kPackageName, kPreferencesFileNm, kPrefsRecordID, FPPrefs	// writes to disk immediately: writes much too often  when window is moved or resized
End


