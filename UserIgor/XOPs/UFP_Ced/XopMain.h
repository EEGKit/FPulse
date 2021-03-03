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


/* 2010-01-04
//===============================================================================================================
//	TRIAL TIME CONSTANTS			MUST BE THE SAME IN  ProjectsFPulse.ipf  AND HERE IN  XopMain.h
#define	ksSOURCES_DRV_DIR		"C:\\UserIgor\\FPulse_" // same as SourcesDrvDir() (->ProjectsCommons.ipf)
#define	ksAPPNAME				"FPulse"
#define	ksVERSION_MARKER		"ksFP_VERSION"
#define	ksCRYPT_BASE			"cryptbd"			

//===============================================================================================================
*/

