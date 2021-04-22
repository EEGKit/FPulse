//
// XopMain.h 

#pragma pack(2)				// All structures are 2-byte-aligned

typedef struct
{
	int    (*fnc)();
} FUNC;

FUNC sFunc[];

#pragma pack()				// All structures are default-aligned.

