//
// XopMain.h 

#pragma pack(4)				// All structures are 4-byte-aligned

typedef struct
{
	int    (*fnc)();
} FUNC;

FUNC sFunc[];


#pragma pack()					// All structures were 4-byte-aligned.

//Handle    IHC2( Handle sIgor, int *pHState );
//int       IHCDisposeHandle2( Handle sCopy, int *pHState );
