//
// XopUtils.c

#include "XOPStandardHeaders.h" 
#include "XopUtils.h" 

#define	kMAXSTRING	2000// 1000


/////////////////////////////////////////////////////////////////////////////

int	ItemsInList( char *sString, char *sSep )
{
// Returns number of items in list, last separator may be missing or not
	BOOL	bLastSepIsMissing = 0;
	int	len = strlen( sString ), nItems;
   if ( len == 0 || len > kMAXSTRING - 3 || strlen( sSep ) != 1 ) 
      return -1;		// error

	if ( sString[ len - 1 ] != sSep[ 0 ] )
		bLastSepIsMissing	= 1;

   nItems	= CountSepsInList( sString, sSep ) + bLastSepIsMissing;
	//{ char buf[4000]; sprintf( buf, "ItemsInList() string:'%s'  sep:'%s' nItems = CountSepsInList: %d + bLastSepIsMissing: %d \r", sString, sSep, CountSepsInList( sString, sSep ) , bLastSepIsMissing );   XOPNotice( buf ); }
   return	nItems;
}


void	StringFromList( int index, char *sString, char *sSep, char *sItem )
{
// Extracts sItem  and  returns number of items in list
// STRING LENGTH is LIMITED TO 'kMAXSTRING'
   char  sStringCopy[ kMAXSTRING ] = "";
   int   posBeg=-1, posEnd=-1, nSeps=-1, len;
   // char buf[100];

	strcpy( sItem, "" );
   
	len = strlen( sString );
   if ( len == 0 || len > kMAXSTRING - 3 || strlen( sSep ) != 1 ) 
      return;
	if ( len > kMAXSTRING - 3 )
	{ 
		XOPNotice( "++++ERROR: string too long (StringFromList) \r" );
		return;
	}
   strcpy( sStringCopy+1, sString );					// make room for leading separator
   sStringCopy[0] = sSep[0];								// append leading separator
	if ( sStringCopy[ len ] != sSep[ 0 ] )				// if there was no trailing separator..
	{
		sStringCopy[ len+1 ] = sSep[0];					// ..append trailing separator and
		sStringCopy[ len+2 ] = '\0';						// ..append string end
	}
   nSeps =  CountSepsInList( sStringCopy, sSep );	// now we have a leading and a trailing separator
   index = min( max( 0, index ), nSeps-2 );			// 2 separators: only index 0

   posBeg = GetSepPosInList( index  , sStringCopy, sSep );
   posEnd = GetSepPosInList( index+1, sStringCopy, sSep ) - 1;

   strncpy( sItem, sStringCopy+posBeg+1, posEnd-posBeg );
   sItem[ posEnd-posBeg ] = '\0';    // append string end
	//{ char buf[4000]; sprintf( buf, "StringFromList() string:'%s' ITEMS: %d seps:%d  beg:%d  end:%d  sStringcopy:'%s' index:%d ->'%s' \r", sString, nSeps - 1, nSeps, posBeg,  posEnd, sStringCopy, index, sItem );   XOPNotice( buf ); }
   return;
}

/* 
char *StringFromList( int index, char *sString, char *sSep )
{
//? NOT GOOD....because of static can not use nested calls....... 
   static char  sExtracted[  kMAXSTRING ] = "";
   static char  sStringCopy[ kMAXSTRING ] = "";
   int   posBeg=-1, posEnd=-1, nSeps=-1;
   // char buf[100];

   int   len = strlen( sString );
   if ( len == 0 || len > kMAXSTRING - 3 ||strlen( sSep ) == 0 )
      return sExtracted;

   strcpy( sStringCopy+1, sString );
   sStringCopy[0] = sSep[0];       // append leading separator
   sStringCopy[ len+1 ] = sSep[0]; // append trailing separator
   sStringCopy[ len+2 ] = '\0';    // append string end

   nSeps =  CountSepsInList( sStringCopy, sSep );
   index = min( max( 0, index ), nSeps-2 ); // 2 separators: only index 0

   posBeg = GetSepPosInList( index  , sStringCopy, sSep );
   posEnd = GetSepPosInList( index+1, sStringCopy, sSep ) - 1;

   strncpy( sExtracted, sStringCopy+posBeg+1, posEnd-posBeg );
   sExtracted[ posEnd-posBeg ] = '\0';    // append string end
   // sprintf( buf, "StringFromList() seps:%d  beg:%d  end:%d  sStringcopy:'%s' ->'%s' \r", nSeps, posBeg,  posEnd, sStringCopy, sExtracted );   XOPNotice( buf );  
   return sExtracted;
}
*/ 
 
int CountSepsInList( char *sString, char *sSep )
{
   int cnt = 0, i, len = strlen( sString );
   for ( i = 0; i < len; i += 1 )
      if ( sString[ i ] == sSep[ 0 ] )
         cnt += 1;
   return cnt;
}    

int GetSepPosInList( int index, char *sString, char *sSep )
{
   int cnt = 0, i, len = strlen( sString );
   for ( i = 0; i < len; i += 1 ) {
      if ( sString[ i ] == sSep[ 0 ] ) {
         if ( cnt == index )
            return i;
         cnt += 1;
      }
   }
   return 0;
}

/////////////////////////////////////////////////////////////////////////////

