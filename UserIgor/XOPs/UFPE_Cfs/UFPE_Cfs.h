//
// UFPE_Cfs.H 
//

#define	ERRNONE	0					// show no error box and no error in command window

// UFP_Cfs.H  AND  FPULSExxx.IPF : Error handling: where and how are error messages displayed
//#define  CED_NOT_OPEN	((short)-510)	// using the CED error code (instead of -1) simplifies the code // 120602      -1
#define  CED_NOT_OPEN	-1			// using the CED error code (instead of -1) simplifies the code // 120602      -1
#define	ERRBOX			1			// RELEASE : show an error box
#define	ERRLINE			2			// DEBUG:    print the error in the command window
#define	MSGLINE			4			// DEBUG:    print process messages in the command window 
#define	ERR_AUTO_IGOR	8			// IGORs automatic error box :lookup CED error string in xxxWinCustom.RC
#define	ERR_FROM_IGOR	16			// custom error box: lookup CED error string in xxxWinCustom.RC
#define	ERR_FROM_CED	32			// custom error box: get CED error string from U14GetString() 

// XFUNC2 custom error codes
// make the corresponding text entry in UFP_CfsWinCustom.RC 
// CED error codes from -500..-611 (s. prog int lib dec 1999, p34)
// ..are renumbered into the range 100..211   (see XOPEntry() in XopMain.C)

#define REQUIRES_IGOR_200          1 + FIRST_XOP_ERR
#define UNKNOWN_XFUNC              2 + FIRST_XOP_ERR
#define NO_INPUT_STRING            3 + FIRST_XOP_ERR

#define NON_EXISTENT_WAVE          4 + FIRST_XOP_ERR
#define REQUIRES_SP_OR_DP_WAVE     5 + FIRST_XOP_ERR
#define ILLEGAL_LEGENDRE_INPUTS    6 + FIRST_XOP_ERR
#define LOGFIT_REQUIRES_FPU        7 + FIRST_XOP_ERR
#define PLGNDR_REQUIRES_FPU        8 + FIRST_XOP_ERR

#define INPUT_MUST_BE_POSITIVE     9 + FIRST_XOP_ERR
#define IS_NOT_2BYTE_INT_WAVE     10 + FIRST_XOP_ERR
#define IS_NOT_4BYTE_FLOAT_WAVE   11 + FIRST_XOP_ERR
#define IS_NOT_TEXT_WAVE          12 + FIRST_XOP_ERR
#define WAVES_HAVE_DIFFER_LENGTHS 13 + FIRST_XOP_ERR
#define OUT_OF_MEMORY             14 + FIRST_XOP_ERR
#define IS_NOT_2_NOT_4BYTE_WAVE   15 + FIRST_XOP_ERR
//#define TRIAL_TIME_EXPIRED			 16 + FIRST_XOP_ERR

