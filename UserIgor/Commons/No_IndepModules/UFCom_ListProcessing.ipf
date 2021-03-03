//
//  UFCom_ListProcessing.ipf 
// 
#pragma rtGlobals=1							// Use modern global access method.

//===============================================================================================================================
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//#pragma IndependentModule=UFCom_
#include "UFCom_Constants"


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  ADVANCED  LIST  FUNCTIONS

Function	/S	UFCom_RemoveLastListItems( cnt, sList, sSep ) 
// removes  'cnt'  trailing items from list 
	variable	cnt
	string 	sList, sSep 
	variable	n, nItems
	for ( n = 0; n < cnt; n += 1 )
		nItems	= ItemsInList( sList, sSep ) 				// while the list is getting shorter....
		sList		= RemoveListItem( nItems-1, sList, sSep )	//..always remove the last item
	endfor
	return	sList
End


Function  /S	UFCom_ReplaceListItem( sItem, sList, sListSep, nItem )
// Replaces the list item at position 'nItem' .  'sListSep'  may be or may be missing at the end of the list. 
// Possibly fills in just 1 missing separator........ No separator is added at the end of the list.
	string 	sItem, sList, sListSep
	variable	nItem 
	// print "ReplaceListItem(1)",  ItemsInList( sList, sListSep) ,  sList
	if ( cmpstr( sList[ strlen( sList ) - 1 ], sListSep ) )			// possibly append a trailing separator
		sList 	+= 	sListSep 							// possibly append a trailing separator
	endif
	sList	= AddListItem( sItem, RemoveListItem( nItem, sList, sListSep ) , sListSep, nItem )	
	return	sList
End

Function  /S	UFCom_ReplaceListItem1( sItem, sList, sListSep, nItem )
// Replaces the list item at position 'nItem' .  'sListSep'  may be or may be missing at the end of the list. 
// If  'nItem'  is behind the last list entry, the needed empty entries (=the separators) are filled in. No separator is added at the end of the list.
// ????? empty list and nItem=0???
	string 	sItem, sList, sListSep
	variable	nItem
	variable	nOldItems	= ItemsInList( sList, sListSep )
	//string  	sOldList	= sList
	if ( nOldItems  && cmpstr( sList[ strlen( sList ) - 1 ], sListSep ) )	// If the list contains at least 1 element then ensure that there is a trailing separator...  
		sList 	+= 	sListSep 							// ..behind the last element. If the trailing separator is missing then append it.
	endif
	if ( nItem < nOldItems )
		sList	= RemoveListItem( nItem, sList, sListSep )		// RemoveListItem()  has an unexpected (though documented behavior)...
	endif											// ...it returns an empty string when only separators are left over.... 
	if ( ItemsInList( sList, sListSep )	== 0 )				// ...As we need the separators we reconstruct them...
		sList	= PadString( sList, nOldItems-1, char2num( sListSep ) )	//..so that we can fill in the replacing item at the correct position
	endif												// see BuTest11
	if ( nItem > nOldItems ) 
		variable	nSep
		for ( nSep = nOldItems; nSep < nItem; nSep += 1 )
			sList	= AddListItem( "", sList, sListSep, inf )		// just fill up with empty entries = add separators
		endfor		 
	endif
	sList	= AddListItem( sItem, sList, sListSep, nItem )			
	// printf "\t\tReplaceListItem1()\tListitems: %d \t ->\t%d .\tReplacing item %d  \tby %s\t : \t%s\t ->\t%s \r",  nOldItems, ItemsInList( sList, sListSep), nItem, UFCom_pd(sItem,9), sOldList, sList
	return	sList
End

Function	/S	UFCom_PossiblyAddListItem( sItem, sList )
// Adds item to end of list, but only if item is not already in the list
	string  	sItem, sList
	sItem		= RemoveEnding( sItem, ";" )			// without this sList would be returned with 2 separators at the end  if  sItem  already had a trailing  ';' 
	// printf "\t\t\t\tPossiblyAddListItem( \tadding \t\t'%s'  \tto \t'%s' )   1  \r", sItem, sList
	if ( WhichListItem( sItem, sList )  ==  UFCom_kNOTFOUND )
		sList = AddListItem( sItem, sList, ";", Inf )
	endif
	// printf "\t\t\t\tPossiblyAddListItem( \thas added\t'%s'  \t ->\t'%s' )   2  \r", sItem, sList
	return	sList
End


Function	/S	UFCom_AppendListItem( sItem, sList, sSep )
// adds an item at the end of a list  but not expecting a separator at the end  like  AddListItem(sItem, sList, sSep, Inf)  does
	string  	sList, sItem, sSep
//	return	SelectString( strlen( sList ), sItem, sList + sSep + sItem )
	variable	len =  strlen( sList )
	if( len == 0 )								
		return	sItem						// list was empty, add the element 
	elseif ( cmpstr( sList[ len-1, len-1] , sSep ) )
		return	sList + sSep + sItem			// list had elements but had no already trailing separator: add separator and element
	else
		return	sList + sItem				// list had elements and had already trailing separator: add the element
	endif	
End



Function	/S	UFCom_LastListItem( sList, sSep )
// returns the last item in list
	string 	sList, sSep 
	variable	nItems	= ItemsInList( sList, sSep )
	return	StringFromList( nItems-1, sList, sSep )	
End


Function		UFCom_WhichListItemNoCase( sItem, sList )
// Case-insensitive version of WhichListItem()
	string  	sItem, sList

	if ( strlen( sItem ) == 0  ||  strlen( sList ) == 0 )
		return	UFCom_kNOTFOUND
	endif
	
	variable	n, nItems	= ItemsInList( sList )
	for ( n = 0; n < nItems; n += 1 )
		if ( cmpstr( sItem, StringFromList( n, sList ) ) == 0 )
			return	n
		endif
	endfor
	return	UFCom_kNOTFOUND
End
	
Function		UFCom_ItemsInList2( str, sSep1, sSep2 )	
// Like ItemsInList() but accepts 2 separators e.g  ','  and  ' and '  to  extract enumerations like 'apples, bananas and oranges' 
// 'sSep1' must be a single character, 'sSep2' may be a string
	string  	str, sSep1, sSep2
	str	= ReplaceString( sSep2, str, sSep1 )	// convert string to contain only the single character separator  'sSep1' which can be processed easily
	return	ItemsInList( str, sSep1)		// Cave : will convert 'apples, bananas, and oranges'  to  'apples, bananas,,oranges'  	-> 4 ( the 3. being empty '' )
End									// Cave : will convert 'apples, bananas,and oranges'   to  'apples, bananas,and oranges' -> 3 ( the 3. being 'and oranges' )
	
Function	/S	UFCom_StringFromList2( n, str, sSep1, sSep2 )	
// Like StringFromList() but accepts 2 separators e.g  ','  and  ' and '  to  extract enumerations like 'apples, bananas and oranges' 
// 'sSep1' must be a single character, 'sSep2' may be a string
	variable	n
	string  	str, sSep1, sSep2
	str	= ReplaceString( sSep2, str, sSep1 )	// convert string to contain only the single character separator  'sSep1' which can be processed easily
	return	StringFromList( n, str, sSep1)	// Cave : will convert 'apples, bananas, and oranges'  to  'apples, bananas,,oranges'  	-> 4 ( the 3. being empty '' )
End									// Cave : will convert 'apples, bananas,and oranges'   to  'apples, bananas,and oranges' -> 3 ( the 3. being 'and oranges' )


Function	/S	UFCom_SortListExt( lstListToSort, sSkipLeading, nSortOrder )	
// Sorts  list entries after skipping  a string  e.g. if  'sSkipLeading'  is  'W'  then W0,W2,W1 ist sorted  W0,W1,W2  (or reversed) 
// The order of list entries not starting  with  'sSkipLeading' is undefined  but all are together at the end (or beginning) of the list
	string 	lstListToSort, sSkipLeading
	variable	nSortOrder 	
	string 	sItem, lstSorted = "", lstOther = ""
	variable	len, n, nItems
	// separate the acquisition windows (which must be sorted and which start with 'W' )  from all other windows
	nItems	=  ItemsInList( lstListToSort )
	for ( n = 0; n < nItems; n += 1 )
		sItem = StringFromList( n, lstListToSort )
		len	= strlen( sSkipLeading )										// Example: Sort acquisition windows W0,W1,W2.....
		if ( cmpstr( sItem[0, len - 1 ] , sSkipLeading ) == 0 )  						// if  the wnd name starts with 'W' it is probably an acq window...
			lstSorted = AddListItem( StringFromList( n, lstListToSort )[len,Inf] , lstSorted )	//..which we add to our acq wnd list after the 'W' has been removed.
	 	else															// (processing e.g. 'W_other' the same way is OK as we reconstitute the name again later) 
			lstOther = AddListItem( StringFromList( n, lstListToSort ), lstOther )
		endif
	 endfor	
	// print  "\tSortListExt1before sort  \t", nItems, lstListToSort
	// print  "\tSortListExt2 after split and strip \t", lstOther , lstSorted
	lstSorted = SortList( lstSorted, ";",   nSortOrder )		// sort the acquisition windows 
	lstListToSort  = ""
	for ( n = 0; n < ItemsInList( lstSorted ); n += 1 )		// reconstitute the stripped 'W' at the beginning
		lstListToSort = AddListItem( sSkipLeading + StringFromList( n,  lstSorted ), lstListToSort , ";", Inf ) //
	endfor	
	// print  "\tSortListExt3 after  sort  \t", lstListToSort
	lstListToSort	=  lstListToSort + lstOther				// combine the 2 lists again (order is arbitrary)
	//lstListToSort	=  lstOther	+ lstListToSort				// combine the 2 lists again (order is arbitrary)
	// print  "\tSortListExt4 after combine \t" , lstListToSort
	return	lstListToSort
End


