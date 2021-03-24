//
// XopMain.h 

#pragma pack(4)				// All structures are 4-byte-aligned

typedef struct
{
	int    (*fnc)();
} FUNC;

FUNC sFunc[];


#pragma pack()					// All structures were 4-byte-aligned.

// 2012-03-13 test
#define UINT  unsigned short
#define Handle Ptr*
//typedef Ptr* Handle;