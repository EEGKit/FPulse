//
// UFe1_Utils.h 
//

// XFUNC2 custom error codes
// make the corresponding text entry in UFe1_UtilsWinCustom.RC 


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

