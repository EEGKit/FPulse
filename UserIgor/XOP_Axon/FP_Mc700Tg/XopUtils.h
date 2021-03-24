//
// XopUtils.h


int		 ItemsInList(  char *sString, char *sSep );
void		 StringFromList(  int index, char *sString, char *sSep, char* sItem );
//char     *StringFromList(  int index, char *sString, char *sSep );
int       CountSepsInList( char *sString, char *sSep );
int       GetSepPosInList( int index, char *sString, char *sSep );


