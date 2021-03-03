//
// XopUtils.h


int		 ItemsInList(  char *sString, char *sSep );
void		 StringFromList(  int index, char *sString, char *sSep, char* sItem );
//char     *StringFromList(  int index, char *sString, char *sSep );
int       CountSepsInList( char *sString, char *sSep );
int       GetSepPosInList( int index, char *sString, char *sSep );

//Handle    IHC( Handle sIgor );
Handle    IHC2( Handle sIgor, int *pHState );
int       IHCDisposeHandle2( Handle sCopy, int *pHState );

