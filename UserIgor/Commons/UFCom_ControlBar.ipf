//  UFCom_ControlBar.ipf 

// History: 
// 2009-05-07	start


#pragma rtGlobals=1							// Use modern global access method.
	
#include "UFCom_ListProcessing" 

static strconstant	UFCOM_ksCB_SEP				= "~"

//================================================================================================================================
//	CONTROLBAR  GENERIC  FUNCTIONS

Function		UFCom_ControlbarHt( lstHeight )
	string  	lstHeight
	variable	ht = 0,  n,  nItems = ItemsInList( lstHeight )
	for ( n = 0; n < nItems; n += 1 )
		ht 	+= str2num( StringFromList( n, lstHeight ) )
	endfor	
	return	ht
End

Function		UFCom_ControlbarItems( llstControls )
	string  	llstControls
	return	ItemsInList( llstControls, UFCOM_ksCB_SEP )
End

Function	/S	UFCom_ControlbarTyp( i, llstControls)
	variable	i
	string  	llstControls
	return	UFCom_StringFromDoubleList( i, 0, llstControls, UFCOM_ksCB_SEP, "," )
End

Function	/S	UFCom_ControlbarTitle( i, llstControls )
	variable	i
	string  	llstControls
	return	UFCom_StringFromDoubleList( i, 1, llstControls, UFCOM_ksCB_SEP, "," )
End

Function	/S	UFCom_ControlbarName( sFo, sWNm, i, llstControls )
	string  	 sFo, sWNm, llstControls
	variable	i
	return	"root_uf_" + sFo + "_" + sWNm + "_" + UFCom_ControlbarTyp( i, llstControls ) + CleanUpName( UFCom_ControlbarTitle( i, llstControls ), 0 )	// ass name
End

Function		UFCom_ControlbarWidth( i, llstControls)
	variable	i
	string  	llstControls
	return	str2num( UFCom_StringFromDoubleList( i, 2, llstControls, UFCOM_ksCB_SEP, "," ) )
End

Function		UFCom_ControlbarMarginR( i, llstControls)
	variable	i
	string  	llstControls
	return	str2num( UFCom_StringFromDoubleList( i, 3, llstControls, UFCOM_ksCB_SEP, "," ) )
End

Function		UFCom_ControlbarPos( i, llstControls )
	variable	i
	string  	llstControls
	variable	j, pos = 0
	for ( j = 0; j < i; j += 1 )
		pos += UFCom_ControlbarWidth( j, llstControls )
		pos += UFCom_ControlbarMarginR( j, llstControls )  
	endfor
	return	pos
End



