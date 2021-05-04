// XopMain.h 

#pragma pack(2)

typedef struct
{
	int    (*fnc)();
} FUNC;

FUNC sFunc[];

#pragma pack()

Handle	IHC( Handle sIgorString );
int		DisposeHandleIHC( Handle sCopy );
int		ErrorNrCEDtoIGOR( int code );
void	DebugPrintWaveProperties( char *sText, waveHndl wWave ); 
