// UF_FbResultAvgTbl.ipf   =  RAT
//
// 2010-02-18	Common functions for creating a Result-Average-Table 
//			These kind of table is used in FBrain 3 times:  Stats, MinMax, CoherenceShuffled.  It could also be used in Nesting.
//			The advantage of these common functions is that code repetition is avoided, the drawback are the longer parameter lists wich are required.
//			There is a slightly different set of functions for 0 channels (e.g. FBrainNesting.ipf) ,  1 channel (e.g. FBrainMinMax.ipf)  and multiple channels (e.g. FBrain_Stats).
//
// History: 

#pragma  rtGlobals 	= 1					// Use modern global access method. 	Do not use a tab after #pragma. Doing so will give compilation error in Igor 4.
#pragma  IgorVersion = 6.02				// Prevents the attempt to run this procedure under a lower Igor Version.  Do not use a tab after #pragma. Doing so will make the version check ineffective in Igor 4.

// General  'Includes'
//#include "UFCom_Constants"
//#include "UFCom_Database"
//#include "UFCom_ListProcessing"


//--------------------------------------------------------------------------------------------------------------------------------------------

Function	/S	UFCom_RAT_Items( lstItems0, lstBaseItems, lstAvgNames )
	string  	lstItems0, lstBaseItems, lstAvgNames 
	string  	lst	= lstItems0
	variable	b, bItems	= ItemsInList( lstBaseItems )
	variable	a, aItems	= ItemsInList( lstAvgNames )
	for ( b = 0; b < bItems; b += 1 )
		for ( a = 0; a < aItems; a += 1 )
			lst	+= UFCom_RAT_Item_Nm( a, b, lstBaseItems, lstAvgNames ) + ";"
		endfor
	endfor
	// printf "\t\tUFCom_RAT_Items \t\titems:%2d\tlst:'%s' \r", ItemsInList( lst ),  lst[0,300]
	return	lst
End

Function	/S	UFCom_RAT_Widths( lstWidth, lstBaseItems, lstAvgWidth )
	string  	lstWidth, lstBaseItems, lstAvgWidth 
	string  	lst	= lstWidth
	variable	b, bItems	= ItemsInList( lstBaseItems )
	variable	a, aItems	= ItemsInList( lstAvgWidth )
	for ( b = 0; b < bItems; b += 1 )
		for ( a = 0; a < aItems; a += 1 )
			lst	+= StringFromList( a, lstAvgWidth ) + ";"
		endfor
	endfor
	// printf "\t\tUFCom_RAT_Widths \t\titems:%2d\tlst:'%s' \r", ItemsInList( lst ),  lst[0,300]
	return	lst
End

Function	/S	UFCom_RAT_Item_Nm( a, b, lstBaseItems, lstAvgNames )
// name for the column title contains spaces
	variable	a, b
	string  	lstBaseItems, lstAvgNames 
	return	StringFromList( b, lstBaseItems ) + " " + StringFromList( a, lstAvgNames )
End
	

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Functions for  0  channels  (e.g. FBrainNesting)

// in contrast to the functions for 1 or 2 channels below there is (currently) no 'sType'  parameter as this is not required in FBrainNesting.  Must/Could be introduced easily at some time ....

Function	/S	UFCom_RAT_ItemNm0( sSubFoPath, a, b, lstBaseItems, lstAvgNames )
// name for the variable with folder but without spaces
	string  	sSubFoPath, lstBaseItems, lstAvgNames 
	variable	a, b
	return	UFCom_RAT_Folder0( sSubFoPath ) + ":" + StringFromList( b, lstBaseItems ) + StringFromList( a, lstAvgNames )
End

Function	/S	UFCom_RAT_Folder0( sSubFoPath )
	string  	sSubFoPath 
	return	sSubFoPath 		
End

Function	/S	UFCom_RAT_DbNm0(  sTblNm )
// return the tables wave name   (the table normally is a 2 dim text wave)
	string  	sTblNm
	return	sTblNm 
End

Function	/S	UFCom_RAT_Nm0()
	return  	""
End

Function	/S	UFCom_RAT_FoDbNm0( sSubFoPath, sTblNm )
// return the full folder path table wave name  (the table normally is a 2 dim text wave)
	string  	sSubFoPath, sTblNm
	return	UFCom_RAT_Folder0( sSubFoPath ) + ":" + UFCom_RAT_DbNm0( sTblNm )
End


//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Functions for 1 channel  (e.g. FBrainMinMax  or  FBrainCoherenceShuffle)

Function	/S	UFCom_RAT_ItemNm( sSubFoPath, sType, ch, a, b, lstBaseItems, lstAvgNames )
// name for the variable with folder but without spaces
	string  	sSubFoPath, sType, lstBaseItems, lstAvgNames 
	variable	ch, a, b
	return	UFCom_RAT_Folder( sSubFoPath, sType, ch ) + ":" + StringFromList( b, lstBaseItems ) + StringFromList( a, lstAvgNames )
End

Function	/S	UFCom_RAT_Folder( sSubFoPath, sType, ch )
	string  	sSubFoPath, sType 
	variable	ch
	return	sSubFoPath + ":" + sType + ":" + ChNm1_fb( ch )		
End

Function	/S	UFCom_RAT_DbNm(  sTblNm, sType, ch )
// return the tables wave name   (the table normally is a 2 dim text wave)
	string  	sTblNm, sType 
	variable	ch
	return	sTblNm + "_" + ChNm1_fb( ch )
End

Function	/S	UFCom_RAT_Nm( sType, ch )
	string  	sType
	variable	ch
	string  	ShortNm	= sType + "_" + ChNm1_fb( ch ) 
	return	ShortNm
End

Function	/S	UFCom_RAT_NmA( sType, ch )
	string  	sType
	variable	ch
	string  	ShortNm	= sType + "_" + ChNmA_fb( ch ) 
	return	ShortNm
End

Function	/S	UFCom_RAT_NmA_( sType, sA )
	string  	sType, sA
	string  	ShortNm	= sType + "_" + ChNmS_fb( sA ) 
	return	ShortNm
End

Function	/S	UFCom_RAT_FoDbNm( sSubFoPath, sTblNm, sType, ch )
// return the full folder path table wave name  (the table normally is a 2 dim text wave)
	string  	sSubFoPath, sTblNm, sType
	variable	ch
	return	UFCom_RAT_Folder( sSubFoPath, sType, ch ) + ":" + UFCom_RAT_DbNm( sTblNm, sType, ch ) 
End

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Functions for 2 channels (e.g. FBrainStats)

Function	/S	UFCom_RAT_ItemNm2( sSubFoPath, sType, ch, cc, a, b, lstBaseItems, lstAvgNames )
// name for the variable with folder but without spaces
	string  	sSubFoPath, sType, lstBaseItems, lstAvgNames 
	variable	ch, cc, a, b
	return	UFCom_RAT_Folder2( sSubFoPath, sType, ch, cc ) + ":" + StringFromList( b, lstBaseItems ) + StringFromList( a, lstAvgNames )
End

Function	/S	UFCom_RAT_Folder2( sSubFoPath, sType, ch, cc )
	string  	sSubFoPath, sType 
	variable	ch, cc
	return	sSubFoPath + ":" + sType + ":" + ChNm12_fb( ch, cc )
End

Function	/S	UFCom_RAT_DbNm2( sTblNm, sType, ch, cc )
// return the table wave name   (the table normally is a 2 dim text wave)
	string  	sTblNm, sType 
	variable	ch, cc
	return	sTblNm + "_" + ChNm12_fb( ch, cc )
End

Function	/S	UFCom_RAT_Nm2( sType, ch, cc )
// returns e.g. 'NE_ch12'
	string  	sType
	variable	ch, cc
	string  	ShortNm	= sType + "_" + ChNm12_fb( ch, cc )
	return	ShortNm
End

Function	/S	UFCom_RAT_NmAB( sType, ch, cc )
// returns e.g. 'NE_chAB'
	string  	sType
	variable	ch, cc
	string  	ShortNm	= sType + "_" + ChNmAB_fb( ch, cc )
	return	ShortNm
End

Function	/S	UFCom_RAT_NmAB_( sType, sA, sB )
// returns e.g. 'NE_chAB'
	string  	sType, sA, sB
	string  	ShortNm	= sType + "_" + ChNmSS_fb( sA, sB )
	return	ShortNm
End

Function	/S	UFCom_RAT_FoDbNm2( sSubFoPath, sTblNm, sType, ch, cc )
// return the full folder path table wave name  (the table normally is a 2 dim text wave)
	string  	sSubFoPath, sTblNm, sType 
	variable	ch, cc
	return	UFCom_RAT_Folder2( sSubFoPath, sType, ch, cc ) + ":" + UFCom_RAT_DbNm2( sTblNm, sType, ch, cc )
End


