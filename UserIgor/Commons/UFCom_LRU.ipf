//
// UFCom_LRU.ipf
//
// 2009-06-18
// 	Performs  Last Recently Used  file list funtionality

#pragma rtGlobals=1		// Use modern global access method.

#pragma ModuleName = FPulse

//#include "UFCom_DataFoldersAndGlobals"

static constant		kLRU_MAX		= 20
static strconstant	ksLRU_BasePrefix	= "lstLRU"

//=====================================================================================================================================

Function	/S	UFCom_LRUSet( sFo, sBaseNmOfList, lstLRU )
	string  	sFo, sBaseNmOfList		// e.g.  'Datapath'	-> 	'lstLRUDatapath' 
	string  	lstLRU
	string    	/G		  $"root:uf:" + sFo + ":" + ksLRU_BasePrefix + sBaseNmOfList	= lstLRU
	return	lstLRU
End	

Function	/S	UFCom_LRU( sFo, sBaseNmOfList )
	string  	sFo, sBaseNmOfList
	svar   /Z	lstLRU	= $"root:uf:" + sFo + ":" + ksLRU_BasePrefix + sBaseNmOfList
	if ( ! svar_exists( lstLRU ) )
		string 	/G	   $"root:uf:" + sFo + ":" + ksLRU_BasePrefix + sBaseNmOfList	= ""
		svar  lstLRU	= $"root:uf:" + sFo + ":" + ksLRU_BasePrefix + sBaseNmOfList
	endif
	return	lstLRU
End	


Function	/S	UFCom_LRUAdd( sFo, sBaseNmOfList, sItem )	
// Moves  'sItem' to top position in the global LRU list  or creates it there.  If necessary the LRU list is truncated so that there are no more than  kLRU_MAX entries.
	string  	sFo, sBaseNmOfList, sItem
	string  	lstLRU
	lstLRU	= UFCom_LRU( sFo, sBaseNmOfList ) 
	// printf "\t\tUFCom_LRUAdd(  init  \t%s\t) :  had %d,  was\t '%s'  \r", UFCom_pd( sItem,49),  ItemsInList( UFCom_LRU( sFo, sBaseNmOfList )  ), UFCom_LRU( sFo, sBaseNmOfList )[0,200] 
	lstLRU	= RemoveFromList( sItem, lstLRU )
	lstLRU	= AddListItem( 	sItem, lstLRU )			// adds at the begiining
	lstLRU	= RemoveListItem( kLRU_MAX, lstLRU )
	UFCom_LRUSet( sFo, sBaseNmOfList, lstLRU )
	// printf "\t\tUFCom_LRUAdd( exit \t%s\t) :  has %d,    is  \t '%s'  \r", UFCom_pd( sItem,49),  ItemsInList( UFCom_LRU( sFo, sBaseNmOfList )  ), UFCom_LRU( sFo, sBaseNmOfList )[0,200]  
	return	lstLRU
End

Function	/S	UFCom_LRURemove( sFo, sBaseNmOfList, sItem )	
// Removes  'sItem' from global LRU list.
	string  	sFo, sBaseNmOfList, sItem
	string  	lstLRU
	lstLRU	= UFCom_LRU( sFo, sBaseNmOfList ) 
	// printf "\t\tUFCom_LRURemove( init \t%s\t) :  had %d,  was\t '%s'  \r", UFCom_pd( sItem,49),  ItemsInList( UFCom_LRU( sFo, sBaseNmOfList )  ), UFCom_LRU( sFo, sBaseNmOfList )[0,200] 
	lstLRU	= RemoveFromList( sItem, lstLRU )
	UFCom_LRUSet( sFo, sBaseNmOfList, lstLRU )
	// printf "\t\tUFCom_LRURemove( exit \t%s\t) :  has %d,    is  \t '%s'  \r", UFCom_pd( sItem,49),  ItemsInList( UFCom_LRU( sFo, sBaseNmOfList )  ), UFCom_LRU( sFo, sBaseNmOfList )[0,200]  
	return	lstLRU
End

Function	/S	UFCom_LRUTop( sFo, sBaseNmOfList )	
// Returns  top entry  from the global LRU list.
	string  	sFo, sBaseNmOfList
	return	StringFromList( 0, UFCom_LRU( sFo, sBaseNmOfList ) )
End
Function	/S	UFCom_LRUTop_( lstLRU )	
// Returns  top entry  from the global LRU list.
	string  	lstLRU
	return	StringFromList( 0, lstLRU )
End

