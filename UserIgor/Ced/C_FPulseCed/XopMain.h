// XopMain.h 

#pragma pack(4)				// All structures are 4-byte-aligned

typedef struct
{
	int    (*fnc)();
} FUNC;

FUNC sFunc[];


#pragma pack()					// All structures were 4-byte-aligned.

Handle	IHC( Handle sIgorString );
int		DisposeHandleIHC( Handle sCopy );
int		ErrorNrCEDtoIGOR( int code );
void		DebugPrintWaveProperties( char *sText, waveHndl wWave ); 
