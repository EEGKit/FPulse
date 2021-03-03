//
//  UFCom_ListProcessing.ipf 
// 
#pragma rtGlobals=1							// Use modern global access method.

//===============================================================================================================================
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
// 2009-04-08   If it is missing it is added at the end (no change, has always been so)
// 2009-04-08    wrong... Possibly fills in just 1 missing separator........ No separator is added at the end of the list.
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
// Replaces the list item at position 'nItem' .  'sListSep'  may initially be there or may be missing at the end of the list. 
// 2009-04-08
// If  'nItem'  is behind the last list entry, the needed empty entries (=the separators) are filled in. ????  No separator is added at the end of the list.
// If  'nItem'  is within the list,  A  SEPARATOR  IS  ADDED  at the end of the list, which is undesired.... 2010-02-21.
// ????? empty list and nItem=0???
	string 	sItem, sList, sListSep
	variable	nItem
	variable	nOldItems	= ItemsInList( sList, sListSep )
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

Function  /S	UFCom_ReplaceListItem_( sItem, sList, sListSep, nItem )
// Replaces the list item at position 'nItem' .  'sListSep'  may initially be there or missing at the end of the list.  In any case  'sList'  is returned  without trailing separator.
	string 	sItem, sList, sListSep
	variable	nItem
	return	RemoveEnding( UFCom_ReplaceListItem1( sItem, sList, sListSep, nItem ), sListSep )
End


Function	/S	UFCom_PossiblyAddListItem( sItem, sList )
// Adds item to end of list, but only if item is not already in the list
	string  	sItem, sList
	sItem		= RemoveEnding( sItem, ";" )			// without this sList would be returned with 2 separators at the end  if  sItem  already had a trailing  ';' 
	// printf "\t\t\t\tPossiblyAddListItem( \tadding \t\t'%s'  \tto \t'%s' )   1  \r", sItem, sList
	if ( WhichListItem( sItem, sList )  == UFCom_kNOTFOUND )
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


Function	/S	UFCom_LastListItems( cnt, sList, sSep )
// returns the last 'cnt' items in list
	variable	cnt
	string 	sList, sSep 
	variable	pos	= strlen( UFCom_RemoveLastListItems( cnt, sList, sSep ) )
	return	sList[ pos, inf ]
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


Function	/S	UFCom_RemoveDoubleEntries( lstList, sSep )	
// Loops through list from the start and removes entries which are already contained in list. Thus trailing doubles are removed and the original list order is preserved.
// To remove leading entries reverse the list before removing doubles and afterwards reverse again.
	string  	lstList, sSep
	variable	n, nItems	= ItemsInList(  lstList, sSep )	
	string  	sItem, lstOut	= ""
	for ( n = 0; n < nItems; n += 1 )
		sItem	  = StringFromList( n, lstList, sSep )
		if ( WhichListItem( sItem, lstOut, sSep ) == UFCom_kNOTFOUND )
			lstOut	= AddListItem( sItem, lstOut, sSep, inf )
		endif	
	endfor
	// printf "\t\tUFCom_RemoveDoubleEntries() '%s'  -> '%s' \r", lstList[0,150], lstOut[0,150]
	return	lstOut
End


Function	/S	UFCom_ReverseList( lst, sSep )	
// Loops through list from the start and removes entries which are already contained in list. Thus trailing doubles are removed and the original list order is preserved.
// To remove leading entries reverse the list before removing doubles and afterwards reverse again.
	string  	lst, sSep
	variable	n, nItems	= ItemsInList(  lst, sSep )	
	string  	sItem, lstOut	= ""
	for ( n = 0; n < nItems; n += 1 )
		sItem	  	= StringFromList( n, lst, sSep )
		lstOut	= AddListItem( sItem, lstOut, sSep, 0 )
	endfor
	// printf "\t\tUFCom_ReverseList() '%s'  -> '%s' \r", lstList[0,150], lstOut[0,150]
	return	lstOut
End



//===============================================================================================================================
// General  DOUBLE LIST functions   (initially developed for  Display/Hide Stimulus Traces in FPULSE)

Function	/S	UFCom_StringFromDoubleList( nMain, nSub, llst, sSepMain, sSepSub )
	variable	nMain, nSub
	string  	 llst, sSepMain, sSepSub
	return	StringFromList( nSub, StringFromList( nMain, llst, sSepMain ), sSepSub ) 
End



Function	/S	UFCom_SubtractDoubleList( llst, llstSubtract, sSepMain, sSepSub, bMatchCase )
	string  	 llst, llstSubtract, sSepMain, sSepSub
	variable	bMatchCase
	variable	rMain = -1, rSub = -1
	string  	sMainItem	= ""
	variable	m, nMainItems	= ItemsInList( llstSubtract, sSepMain )
	variable	s, nSubItems
	for ( m = 0; m < nMainItems; m += 1 )
		sMainItem	= StringFromList( m, llstSubtract, sSepMain )
		nSubItems	= ItemsInList( sMainItem, sSepSub )
		for ( s = 0; s < nSubItems; s += 1 )
			if ( strlen( StringFromList( s, sMainItem, sSepSub ) ) )		// there is an item to subtract
				llst	= UFCom_ClearDoubleListItem( m, s, llst, sSepMain, sSepSub )
			endif
		endfor
	endfor
	return	llst
End

// 2008-06-15  TOTHINK   Replace should keep separator structure  ( also replace with "" ) , but remove should  remove item and separator and thus effectively shrink the separator structure

Function	/S	UFCom_RemoveFromDoubleList( sItem, llst, sSepMain, sSepSub, bMatchCase )
	string  	sItem, llst, sSepMain, sSepSub
	variable	bMatchCase
	variable	rMain = -1, rSub = -1

	return	UFCom_RemoveFromDoubleList_( sItem, llst, sSepMain, sSepSub, bMatchCase, rMain, rSub  )
End

Function	/S	UFCom_RemoveFromDoubleList_( sItem, llst, sSepMain, sSepSub, bMatchCase, m, nSub  )
	string  	sItem, llst, sSepMain, sSepSub
	variable	bMatchCase
	variable	&m, &nSub
	string  	sMainItem	= ""
	variable	nMainItems	= ItemsInList( llst, sSepMain )
	for ( m = 0; m < nMainItems; m += 1 )
		sMainItem	= StringFromList( m, llst, sSepMain )
		nSub		= WhichListItem( sItem, sMainItem, sSepSub, 0, bMatchCase )
		if ( nSub != UFCom_kNOTFOUND )
			llst	= UFCom_ClearDoubleListItem( m, nSub, llst, sSepMain, sSepSub )
			break
		endif
	endfor	
	// printf "\t\tUFCom_RemoveFromDoubleList( sItem: \t%s\t  llst, sSepMain, sSepSub, bMatchCase )   passes back \tnMain:%2d\tnSub:\t%2d\tllst:'%s'    \r", sItem, m, nSub, llst
	return	llst
End

Function	/S	UFCom_ClearDoubleListItem( nMain, nSub, llst, sSepMain, sSepSub )
// overwrite entry with empty string but keep separator structure  
	variable	nMain, nSub
	string  	llst, sSepMain, sSepSub
	llst	= 	UFCom_ReplaceDoubleListItem( "", nMain, nSub, llst, sSepMain, sSepSub )
	return	llst
End

Function	/S	UFCom_RemoveDoubleListItem( nMain, nSub, llst, sSepMain, sSepSub )
// remove item and separator and thus effectively shrink the separator structure
	variable	nMain, nSub
	string  	llst, sSepMain, sSepSub
	llst	=	UFCom_ReplaceListItem1( RemoveListItem( nSub, StringFromList( nMain, llst, sSepMain ), sSepSub ), llst, sSepMain, nMain )
	return	llst
End

Function	/S	UFCom_ReplaceDoubleListItem( sReplItem, nMain, nSub, llst, sSepMain, sSepSub )
// Replaces the list item at position 'nMain,nSub' .  'sSepMain,sSepSub'  may be or may not be missing at the end of the list. 
// If  ''nMain,nSub''  is behind the last list entry, the needed empty entries (=the separators) are filled in. No separator is added at the end of the list.
	variable	nMain, nSub
	string  	sReplItem, llst, sSepMain, sSepSub
	llst		= UFCom_ReplaceListItem1( UFCom_ReplaceListItem1( sReplItem, StringFromList( nMain, llst, sSepMain ), sSepSub, nSub ), llst, sSepMain, nMain )
	return	llst
End


Function	/S	UFCom_FlattenDoubleList( llst, sMainSep, sSubSep, sFinalSep )
	string  	llst, sMainSep, sSubSep, sFinalSep
	string  	sMainItem	= "", lstOut = ""
	variable	m, nMainItems	= ItemsInList( llst, sMainSep )
	variable	s, nSubItems
	for ( m = 0; m < nMainItems; m += 1 )
		sMainItem	= StringFromList( m, llst, sMainSep )
		nSubItems	= ItemsInList( sMainItem, sSubSep )
		for ( s = 0; s < nSubItems; s += 1 )
			lstOut	+= StringFromList( s, sMainItem, sSubSep ) + sFinalSep
		endfor
	endfor
	return	lstOut
End	


//===============================================================================================================================
// General  TRIPLE LIST functions   (initially developed for  FPuls4  lllstIO )

Function  /S	UFCom_StringFromTripleList( nItem0, nItem1, nItem2, lllst, sSep0, sSep1, sSep2 )
	string 	lllst, sSep0, sSep1, sSep2
	variable	nItem0, nItem1, nItem2
	return	StringFromList( nItem2, StringFromList( nItem1, StringFromList( nItem0, lllst, sSep0 ), sSep1 ), sSep2 )
End

Function  /S	UFCom_ReplaceTripleListItem( sRepl, nItem0, nItem1, nItem2, lllst, sSep0, sSep1, sSep2 )
// Replaces the list item at position 'nItem' .  'sSep'  may be or may not be missing at the end of the list. 
// If  'nItem'  is behind the last list entry, the needed empty entries (=the separators) are filled in. No separator is added at the end of the list.
	string 	sRepl, lllst, sSep0, sSep1, sSep2
	variable	nItem0, nItem1, nItem2
	string  	llst		= StringFromList( nItem0, lllst, sSep0 )
	lllst		= UFCom_ReplaceListItem1( UFCom_ReplaceListItem1( UFCom_ReplaceListItem1( sRepl, StringFromList( nItem1, llst, sSep1 ), sSep2 ,  nItem2 ), llst, sSep1,  nItem1 ),  lllst, sSep0,  nItem0 )
	return	lllst
End

Function  /S	UFCom_ClearTripleListItem( nItem0, nItem1, nItem2, lllst, sSep0, sSep1, sSep2 )
// Replaces the list item at position 'nItem'  by an empty string but keep separator structure .    'sSep'  may be or may not be missing at the end of the list. 
// If  'nItem'  is behind the last list entry, the needed empty entries (=the separators) are filled in. No separator is added at the end of the list.
	string 	lllst, sSep0, sSep1, sSep2
	variable	nItem0, nItem1, nItem2
	return	UFCom_ReplaceTripleListItem( "", nItem0, nItem1, nItem2, lllst, sSep0, sSep1, sSep2 )
End


Function  /S	UFCom_RemoveTripleListItem( nItem0, nItem1, nItem2, lllst, sSep0, sSep1, sSep2 )
// Remove the list item and its separator at position 'nItem' and thus effectively shrink the separator structure .  'sSep'  may be or may not be missing at the end of the list. 
// If  'nItem'  is behind the last list entry, the needed empty entries (=the separators) are filled in. No separator is added at the end of the list.
	string 	lllst, sSep0, sSep1, sSep2
	variable	nItem0, nItem1, nItem2
	string  	lst	=	RemoveListItem( nItem2, StringFromList( nItem1, StringFromList( nItem0, lllst, sSep0 ), sSep1 ), sSep2 )
	lllst	=	UFCom_ReplaceDoubleListItem( lst, nItem0, nItem1, lllst, sSep0, sSep1 )
	return	lllst
End


//===============================================================================================================================
// General  QUADRUPLE LIST functions   (initially developed for  FPuls4  llllstDia )

Function  /S	UFCom_StringFromQuadList( nItem0, nItem1, nItem2, nItem3, llllst, sSep0, sSep1, sSep2, sSep3 )
	string 	llllst, sSep0, sSep1, sSep2, sSep3
	variable	nItem0, nItem1, nItem2, nItem3
	return	StringFromList( nItem3, StringFromList( nItem2, StringFromList( nItem1, StringFromList( nItem0, llllst, sSep0 ), sSep1 ), sSep2 ), sSep3 )
End

Function  /S	UFCom_ReplaceQuadListItem( sRepl, nItem0, nItem1, nItem2, nItem3, llllst, sSep0, sSep1, sSep2, sSep3 )
// Replaces the list item at position 'nItem' .  'sSep'  may be or may not be missing at the end of the list. 
// If  'nItem'  is behind the last list entry, the needed empty entries (=the separators) are filled in. No separator is added at the end of the list.
	string 	sRepl, llllst, sSep0, sSep1, sSep2, sSep3
	variable	nItem0, nItem1, nItem2, nItem3
	string  	lllst		= StringFromList( nItem0, llllst, sSep0 )
	lllst		= UFCom_ReplaceTripleListItem( sRepl, nItem1, nItem2, nItem3, lllst, sSep1, sSep2, sSep3 )
	llllst		= UFCom_ReplaceListItem1( lllst, llllst, sSep0, nItem0 )
	return	llllst
End


//===============================================================================================================================
// Display  double or triple lists

Function		UFCom_DisplayMultipleList( sName, lst, sSeps, nWidth )
// Displays double and triple list 'lst'  in an orderly manner.  
	string  	sName				// name of the list
	string  	lst					// double or tripe list
	string  	sSeps				// the list separators, typically for a triple list  '~;,'  or  ';,'  for a double list.  Main separator is first.
	variable	nWidth				// approximate number of characters for displaying each entry
	return	UFCom_DisplayMultipleList_( sName, lst, sSeps, nWidth, "" )
End

Function		UFCom_DisplayMultipleList_( sName, lst, sSeps, nWidth, sTitles )
// Displays double and triple list 'lst'  in an orderly manner.  
	string  	sName				// name of the list
	string  	lst					// double or tripe list
	string  	sSeps				// the list separators, typically for a triple list  '~;,'  or  ';,'  for a double list.  Main separator is first.
	variable	nWidth				// approximate number of characters for displaying each entry
	string  	sTitles
	variable	order		= strlen( sSeps )

//	printf "\t\tUFCom_DisplayMultipleList(  '%s'  ,  '%s'  ,  %d  )    order:%2d   len:%3d   [%s...] \r", sName, sSeps, nWidth, order, strlen( lst ), lst[0,250]
	printf "\t\t%s    '%s'    ->   order:%2d   len:%3d   [%s...] \r", sName, sSeps, order, strlen( lst ), lst[0,300]
	variable	i, ii	= ItemsInList( sTitles, sSeps[ order-1, order-1 ] )
	if ( ii > 0 )
		printf "\t\t\t\t"	
		for ( i = 0; i < ii; i += 1 )
			printf "\t%s", UFCom_pad( StringFromList( i, sTitles, sSeps[ order-1, order-1 ] ), nWidth )
		endfor
		printf "\r"	
	endif
	ii = ItemsInList( lst, sSeps[0,0] )
	for ( i = 0; i < ii; i += 1 )
		string  	lst0	= StringFromList( i, lst, sSeps[0,0] )
		variable	j, jj 	= ItemsInList( lst0, sSeps[1,1] )
		for ( j = 0; j < jj; j += 1 )
			string  	lst1	= StringFromList( j, lst0, sSeps[1,1] )
			if ( order > 2 )
				string  	sLine	 = "\t\t\t"
				variable	k, kk 	= ItemsInList( lst1, sSeps[2,2] )
				for ( k = 0; k < kk; k += 1 )
					string	   sItem	= StringFromList( k, lst1, sSeps[2,2] )
					sLine += SelectString( j == 0  &&  k == 0, "", num2str( i ) + "\t" )	// sLine += SelectString( j == 0  &&  k == 0, ".\t", num2str( i ) + "\t" )  // note the dot which is useful for debugging
					sLine += SelectString( j  >  0  &&  k == 0, "", ".\t" )			// sLine += SelectString(  j  >  0  &&  k == 0, "", ".\t" )	 // note the dot which is useful for debugging
					sLine += SelectString( k == 0, "", num2str( j ) + "\t" )
					sLine += UFCom_pd( sItem, nWidth ) + "\t"
				endfor
				string  	sTabs	= Padstring( "",  20 - ceil( nWidth/4 ) * kk, char2num( "\t" ) )	// empirical: append  so many tabs that lst0 is adjusted on screen
				printf "%s%s%s\r", sLine, sTabs, lst0[0,250]  
				
			endif
		endfor
	endfor
	printf "\r"		
	return	0
End

	
