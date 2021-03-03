// search for 0608
//
//  FP_FPulseConstants.ipf 
// 
// 040210	Generally useful constants must be included in multiple projects by '#include ThisFile'  to avoid  'Duplicate constant'  error

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
constant		kNOACQ 			= 0, 	kDOACQ 	= 1
constant		kNOINIT 			= 0, 	kDOINIT 	= 1
constant		kbOVERWRITE_WAVE=1

strconstant	ksACOld_			= "aco:"			// the subfolder for the  'acquisition'  variables. Do not change as action proc names (and globals in panels) depend on it.
strconstant	ksEVO_			= "evo:"			// the subfolder for the  'evaluation'  variables. Do not change as action proc names rely on it. At most 3 letters or else control action proc names will be too long)
strconstant	ksF_IO_			= "io:"

strconstant	ksACOld			= "aco"			// the subfolder for the  'acquisition'  variables. Do not change as action proc names (and globals in panels) depend on it.
strconstant	ksEVO			= "evo"			// the subfolder for the  'evaluation'  variables. Do not change as action proc names rely on it. At most 3 letters or else control action proc names will be too long)
strconstant	ksF_IO			= "io"

// 060127
strconstant	ksKEEP 			= "pul"			// DO NOT CAHANGE unless VERY MANY variables (and control names .._aco_pul_.. ) are also changed.  Valid for   Acq   and   Eva  .  Must be a  folder which is NOT cleared when a new script is loaded.
strconstant	ksKEEPwr 		= "Raw"			// for 'wRaw' .	Valid for   Acq   and   Eva  .  Must be a  folder which is NOT cleared when a new script is loaded 
strconstant	ksKEEPwl 		= "Lines"			// for 'wLines' .	Valid for   Acq   and   Eva  .  Must be a  folder which is NOT cleared when a new script is loaded 
strconstant	ksKPwg 			= "G"			// for 'wG' . 	Valid for   Acq   and   Eva  .  Must be a  folder which is NOT cleared when a new script is loaded 

// 2009-10-27 Coexistance of FPuls32x and FPulse611
// strconstant	ksF_ACQ_PUL		= "aco:pul"		// the main acquisition subfolder
  

strconstant	ksEVOCFG_DIR		= "C:Epc:Data:EvalCfg:"
strconstant	ksEVOMOVIE_DIR		= "C:Epc:Data:Movie:"
strconstant	ksNoGeneralComment	= "no general comment"	// 060505 BAD: do NOT change 'no general comment:'  as  EVAL depends on it
constant		ERRLINE				= 2					// DEBUG:    print the error in the command window
constant		MSGLINE				= 4					// DEBUG:    print the error in the command window and invoke error message box

strconstant	ksCFS_EXT			= ".dat"

constant		kMILLITOMICRO		= 1000

strconstant	ksXUNIT				=  "s"		// Use 'seconds'  to prevent Igor from labeling the axis e.g. 'kms'  (KiloMilliSeconds)	
constant		kXSCALE				= 1000000		// Convert sample interval given in microsecs to seconds

constant		kMAXCHANS			= 8			// contains AD,  DA and other channels... (max 1digit!)


// Script file separators.  Example for script line syntax (=separator usage):    Segment :	 Dur	=  1,2,3 ;	Amp	= 0
strconstant	sIOCHSEP		= "" 		// "_"	// separates Adc, Dac... and channel number ( only "_" or "", e.g. 'Dac_1' or 'Dac1' )
 
strconstant	sLISTSEP			= ";"				// separates different entries in script
strconstant	sVALSEP			= "="				// separates key from value in script
strconstant	sMAINKEYSEP		= ":"				// separates main key from subkeys and values
strconstant	sPSEP			= ","				// in program: separates list entries,  in script: separates multiple src channels

//strconstant 	ksF_SEP			= ":"				// Igors data folder separator  (this is incidentally the same as the directory separator in file paths)

strconstant	ksSCRIPTS_DRIVE	= "C:"			// Should be  C:   to ensure compatibility. Mainly needed in Release and FPulse, but also in ReadCfs for storing a script (extracted from Cfs file) and for storing cut-out segments 
strconstant	ksSCRIPTS_DIR	= "UserIgor:Scripts"	// Do not change to ensure compatibility. Mainly needed in Release and FPulse, but also in ReadCfs for storing a script (extracted from Cfs file) and for storing cut-out segments 
strconstant	ksTMP_DIR		= ":Tmp"			// Do not change to ensure compatibility. Only needed in FPulse.

//constant		cMAGICOFS = 4, cMAGICOFS_TASKBAR = 28	// for screen pixel computation. Is this valid for Win98 for other screen resolution   or when Windows task bar is hidden ?	

// Constants used when loading a script ( needed in Acq and Eval)
constant		cPROT_AWARE 		= 0			// 030926..031014	cPROT_AWARE=0 : Normal, memory saving mode.    cPROT_AWARE=1 : all Prots are stored during acq in BIG Adc Dac waves		
											// The 'protocol aware' mode is not fully implemented: at the moment it works in 'Quick check after TG, Acq' . This 'protocol aware' mode could and must be extended..
											// .. if the user wanted to access data of different protocols within the acquisition part. Right now only 'ReadCfs' allows to access data of different protocols.
											//   cPROT_AWARE	= 1   DOES PROBABLY NOT WORK WITH  cELIMINATE_BLANK = 1 
	
constant		cELIMINATE_BLANK 	= 1			// 031120  1 : do NOT transfer 'Blank' periods (which are not to be stored in the CFS file)  between computer and host. Improves loading time and acq data rates.  DOES PROBABLY NOT WORK WITH cPROT_AWARE = 1

constant		cADCGAIN_DEFAULT	= 1.0			// comes into effect (not without a warning being issued to alert the user !)  if neither 'Gain'  nor  'TGChan'  nor  'TGMCChan'  is specified in script.
constant		TESTCEDMEMSIZE		= 0x5000000	// This is the maximum value used for testing the memory partitioning if no Ced is present.  It can be decreased  with the SetVariable  'gnShrinkCedMemMB'
											// Decrease 1401 memory for testing arbitrarily. Normal setting: larger than actual memory (CED has typically 16 or 32 MB)

//
//strconstant	klstDIGITLETTER			= "0;1;2;3;4;5;6;7;8;9;a;b;c;d;e;f;g;h;i;j;k;l;m;n;o;p;q;r;s;t;u;v;w;x;y;z;"
//constant		kONELETTER			= 0			//
//constant		kDIGITLETTER			= 1			// automatic naming of result files (xxx.avg, xxx.fit) during the evaluation
//constant		kTWOLETTER			= 2			// automatic naming of CFS files 	(xxx.dat) 		during acquisition
//constant		kMAXINDEX_DIGITLETTER= 36			// 0,1...8,9,a,b,...x,y,z
//constant		kMAXINDEX_2LETTERS	= 676		// 26*26, 



// Constants  used  ONLY  in  AND  BOTH  in  CfsRead  and   Script
constant		cFRM	= 0,	cSWP	= 1,	cPON	= 2,	cCORA	= 3,	cMAXFrmSwpPon	= 4	// Indices into wFix (=Acq)   and  wBlkFrmSwp (=Eval)  . The number of frames, sweeps, PoN and CorrAmp  for each block.


// Constants  used  ONLY  in  AND  BOTH  in  CfsRead  and  CfsWrite  (could be static if it were just 1 file)
// 051124 obsolete und weg.....GN  Problem :   Colon is panel separator   AND   Mac path separator......
strconstant	ksDEF_DATAPATH	= "C:epc:data:"			// IGOR prefers MacIntosh style separator for file paths, to use the windows path convention a conversion is needed  

constant		kCFSMAXBYTE		= 64000				// at most 65534 bytes per block
constant		FILEVAR			= 0,  		DSVAR = 1	// same CONSTANTS  as in CFS.H : DO NOT CHANGE
constant		MAX_CFS_STRLEN	=  254				//! more than 254 gives errors in xCFSCreateFile(),  usable string length is one shorter

 	constant		kNOFLAGS		=  0				// same CONSTANTS  as in CFS.H : DO NOT CHANGE
 constant		kEQUALSPACED	=  0

	 constant		MAX_DSVAR		= 49   		 	// size of  DSArray similar as in PatPul ( CFS maximum is 100)
	 constant		MAX_FILEVAR		= 80				//! should be up to 100 but this gives errors in xCFSCreateFile(). Previously this was 10 for compatibility with Pascal Pulse, increased for storing the script 
 constant		kCFS_NOT_OPEN	=  -1

//			char		byte		short		word		long		float		double	char[ ]
constant		INT1 = 0,	WRD1 = 1,INT2 = 2,WRD2 = 3,	INT4 = 4,	RL4 = 5,	RL8 = 6,	LSTR = 7
strconstant 	klstCFS_DATATYPES	= "INT1;WRD1;INT2;WRD2;INT4;RL4;RL8;LSTR;"

constant		MBYTE			= 0x100000
constant		kMAXAMPL		= 32768				// CED steps  from 0..FullScl	( this constant is the _SAME_ for 12/16bit  and for +-5 and +-10V ADC range !)
constant		kFULLSCL_mV		= 10000				// CED full scale range  in mv	( this constant is the _SAME_ for 12/16bit  and for +-5 and +-10V ADC range !)

// indexing for datasection variables
constant		DS_SMPRATE = 0, DS_TIMEFRM1 = 1, DS_FRMDUR = 2, DS_BEG1 = 3, DS_DUR1 = 4, DS_PRE = 5, DS_COUNT = 6, DS_PROTO = 7, DS_BLOCK = 8, DS_FRAME = 9, DS_SWEEP = 10, DS_PON = 11, DS_MAXBLOCK = 12, DS_MAXFRAME = 13, DS_MAXSWEEP = 14, DS_HASPON = 15,  DS_MAX = 16
strconstant	lstDS_TEXT = "Sample rate,RL4,kHz,0;Time since first fr,RL4,sec,0;Frame duration,WRD2,msec,0;Sample 1 start,WRD2,msec,0;Sample 1 duration,WRD2,msec,0;prescaler value,WRD2,C,0;count value,WRD2,C,0;proto name  ,LSTR,,50;Block,WRD2,,0;Frame,WRD2,,0;Sweep,WRD2,,0;PoN,WRD2,,0;MaxBlock,WRD2,,0;MaxFrame,WRD2,,0;MaxSweep,WRD2,,0;HasPoN,WRD2,,0"


strconstant	ksW_WNM		= "W"		//  Implementation   of  the  Window name as W0, W1, W2..... Cave: Any window will be erased when a script is loaded or applied if its name starts with 'W'
strconstant	ksREADCFS_WNM	= "RdCfs"		// 040824  "ReadCfs"   ->>>>>>> readcfs
strconstant	ksEVO_WNM		= "Eval"		// 041215 

// 2009-10-27 Coexistance of FPuls32x and FPulse611
strconstant	ksAFTERACOldWNM	= "AfterAcq"	// 

constant			kSTIM = 0 ,  kSCRIPT = 1


