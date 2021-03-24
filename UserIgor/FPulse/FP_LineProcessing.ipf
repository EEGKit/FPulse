//
//  FP_LineProcessing.ipf 
// 
#pragma rtGlobals=1							// Use modern global access method.

//===============================================================================================================================
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//===============================================================================================================================
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  PROCESSING  LINES :  REMOVING  AND  REPLACING  BLANKS,  TABS  AND  CR  

Function  /S 	RemoveComment( sLine, sComment )
//  deletes everything (including sComment) till end of line
	string 	sLine, sComment
	variable	nCommentPosition = strsearch( sLine, sComment, 0 )
	if ( nCommentPosition != kNOTFOUND )
		sLine = sLine[ 0, nCommentPosition - 1 ]
	endif
	return sLine
End


Function  /S 	RemoveWhiteSpace( sLine )
//? should replace 0x09-0x0d and 0x20  ( to be same as C compiler isspace() )
	string 	sLine
	sLine = ReplaceString( " ", sLine, "" )
	sLine = ReplaceString( "\r", sLine, "" )
	sLine = ReplaceString( "\n", sLine, "" )
	sLine = ReplaceString( "\t", sLine, "" )
	return sLine
End


Function  /S 	RemoveWhiteSpace1( sLine )
//? should replace 0x09-0x0d and 0x20  ( to be same as C compiler isspace() )
	string 	sLine
//string slin = RemoveWhiteSpace( sLine ) 

	sLine = ReplaceString( " ",  sLine, "" )
	sLine = ReplaceString( "\r", sLine, "" )
	sLine = ReplaceString( "\n", sLine, "" )
	sLine = ReplaceString( "\t", sLine, "" )


// 051006  The following is wrong, as it introduces additional  underscores which is forbidden as the underscore is used as separator in radio button groups...
//...and in the  (old?)  'recipes panel'   -> fPrintMode()  ->  klstAUTOPRINT_TM   ->  SetInitialCheckboxes()
// It works if the auto-built control name is long enough that the added  underscores are truncated again,  it will fail  when the title is short (as it finally did...)
// So: do NOT replace illegal characters by the underscore '_',  instead replace illegal characters by empty string. 
// Cave: do NOT remove any character used as a separator e.g. TILDE_SEP~ , ksTAB_SEP ^ or °  ,  do NOT remove  ':'  or  '|' 
	string  sReplace = ""

// 050201  WRONG     do NOT remove any character used as a separator e.g. TILDE_SEP~ , ksTAB_SEP ^ or °  ,  do NOT remove  ':'  or  '|' 
//	string  sReplace = "_"

	sLine = ReplaceString( "[",  sLine, sReplace )		// also eliminate braces... 	
	sLine = ReplaceString( "]",  sLine, sReplace )		// ..and other characters...
	sLine = ReplaceString( "(",  sLine, sReplace )		// ..which are useful in control titles...		
	sLine = ReplaceString(  ")", sLine, sReplace )		// ..but not allowed in the..  
	sLine = ReplaceString( "/",  sLine, sReplace )		// ..automatically constructed control names
	sLine = ReplaceString( "=",  sLine, sReplace )	
	sLine = ReplaceString( ",",  sLine, sReplace )		// eliminating the comma might interfere with  color and limit lists e.g. (65535,0,0)  


//if ( cmpstr( sline, sLin ) )
//	print "RemoveWhiteSpace() differs: " , sline, slin 
//endif
	return sLine
End


constant  kASCIITab		= 0x09	//  9	
constant  kASCII_r		= 0x0d	// 13		// '\r'
constant  kASCII_n		= 0x0a	// 10		// '\n'
constant  kASCIISpace	= 0x20	// 32	


Function  /S 	RemoveLeadingCR( sLine )
	string 	sLine
	variable	nPos	= 0, len 	=  strlen( sLine )
	for ( nPos = 0; nPos < len; nPos += 1 )
		string 	sChar  = sLine[ nPos, nPos ]
		if ( char2num( sChar ) != kASCII_r )  
			break
		endif
	endfor
	return sLine[ nPos, inf ]
End

Function  /S 	RemoveLeadingWhiteSpaceAndCR( sLine )
	string 	sLine
	variable	nPos	= 0, len 	=  strlen( sLine )
	for ( nPos = 0; nPos < len; nPos += 1 )
		string 	sChar  = sLine[ nPos, nPos ]
		if ( char2num( sChar ) != kASCIISpace  && char2num( sChar ) !=  kASCIITab  &&  char2num( sChar ) != kASCII_r )  
			break
		endif
	endfor
	return sLine[ nPos, inf ]
End

Function  /S 	RemoveLeadingWhiteSpace( sLine )
//? should replace 0x09-0x0d and 0x20  ( to be same as C compiler isspace() )
	string 	sLine

// Slower code??	40 secs
//	variable	nPos	= 0
//	for ( nPos = 0; nPos < strlen( sLine ); nPos += 1 )
//		string 	sChar  = sLine[ nPos, nPos ]
//		if ( char2num( sChar ) != kASCIISpace  && char2num( sChar ) !=  kASCIITab )  
//			break
//		endif
//	endfor
//	return sLine[ nPos, inf ]
	
// 	27 secs
	variable	nPos	= 0, len 	=  strlen( sLine )
	for ( nPos = 0; nPos < len; nPos += 1 )
		string 	sChar  = sLine[ nPos, nPos ]
		if ( char2num( sChar ) != kASCIISpace  && char2num( sChar ) !=  kASCIITab )  
			break
		endif
	endfor
	return sLine[ nPos, inf ]
	

//   30 secs
//	do
//		string 	sChar  = sLine[ 0, 0 ]
//		if ( ( !cmpstr( sChar,  " " )  ||  !cmpstr( sChar,  "\t" ) )  &&  strlen( sLine ) >= 1 )
//			sLine = sLine[ 1, inf ]
//			continue
//		endif
//		break
//	while ( TRUE )
//	return sLine
End


Function  /S 	RemoveTrailingWhiteSpace( sLine )
//? should replace 0x09-0x0d and 0x20  ( to be same as C compiler isspace() )
	string 	sLine

//	variable	nPos								// 27 sec
//	for ( nPos = strlen( sLine ) - 1; nPos >= 0; nPos -= 1 )
//		string 	sChar  = sLine[ nPos, nPos ]
//		if ( char2num( sChar ) != kASCIISpace  &&  char2num( sChar ) !=  kASCIITab  &&  char2num( sChar ) != kASCII_n  &&  char2num( sChar ) !=  kASCII_r )  
//			break
//		endif
//	endfor
//	return sLine[ 0, nPos ]

	do										// 27 sec
		variable	nLast = strlen( sLine ) -1 
		string 	sLast	= sLine[ nLast, nLast ]
		if ( !cmpstr( sLast,  " " )  ||  !cmpstr( sLast,  "\t" )  ||  !cmpstr( sLast,  "\r" )  ||  !cmpstr( sLast,  "\n" ) )
			sLine = sLine[ 0, nLast - 1 ]
			continue
		endif
		break
	while ( TRUE )
	return sLine
End


Function	/S	ReplaceBlanksTabsCRBy1Blank( sLine )
	string  	sLine
	string  	sWord, sCompactedLine = ""
	sLine		= ReplaceString( "\n", sLine, " " )
	sLine		= ReplaceString( "\r", sLine, " " )
	sLine		= ReplaceString( "\t", sLine, " " )
	sLine		= RemoveLeadingWhiteSpace( sLine )
	variable	n, nWords	= ItemsInList( sLine, " " )		// successive blanks will give empty entries
	for ( n = 0; n < nWords; n += 1 )
		sWord	= StringFromList( n, sLine, " " )
		if ( strlen( sWord ) )
			sCompactedLine += sWord + " "
		endif
	endfor
	return	RemoveEnding( sCompactedLine, " " )
End	


Function	/S	ReplaceBlanksTabsBy1Blank( sLine )
	string  	sLine
	string  	sWord, sCompactedLine = ""
	sLine		= ReplaceString( "\t", sLine, " " )
	sLine		= RemoveLeadingWhiteSpace( sLine )
	variable	n, nWords	= ItemsInList( sLine, " " )		// successive blanks will give empty entries
	for ( n = 0; n < nWords; n += 1 )
		sWord	= StringFromList( n, sLine, " " )
		if ( strlen( sWord ) )
			sCompactedLine += sWord + " "
		endif
	endfor
	return	RemoveEnding( sCompactedLine, " " )
End	


//Function  /S  	ReplaceCharWithString( sString, sChar, sRep )
//// Igor 5 made this obsolete						
//	string 	sString, sChar, sRep 
//	return	ReplaceString( sChar, sString, sRep)			
//End

Function		LineEndsWith( sLine, sChar )
	string  	sLine, sChar
	variable	len	= strlen( sLine )
	return	char2num( sLine[ len-1, inf ] ) == char2num( sChar )
End
	

Function    	CountLeadingTabs( sString )
	string 	sString
	variable	pos = 0, len	= strlen( sString )
	do 
		if ( char2num( sString[ pos, pos ] ) != kASCIITab   ||   pos >= len - 1 )  
		 	return pos
		endif
	 	pos += 1
	while ( TRUE )
End


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  PROCESSING  LINES :  EXTRACTING  TRAILING NUMBERS

Function	/S	LeadingName( sText )
// Returns the name part  in front of the trailing digit. Counterpart to TrailingNumber()
// Works only for 1 digit but could be extended to any number
	string  	sText
	variable	len		= strlen( sText )
	return	sText[ 0, len-2 ]
End

Function		TrailingDigit( sText )
// Returns the trailing digit of 'sText' as a number. Returns  Nan   if there is no digit at the end. 
// Works only for 1 digit but could be extended to any number
	string  	sText
	variable	len		= strlen( sText )
	variable	number	= str2num( sText[ len-1, len-1 ] )		// works for lists where the last character is the index, e.g. '5;0;2..' or  'Adc5;Adc0;PoN2'
	return	number
End

Function		PreTrailingDigit( sText )
// Returns the digit before the trailing character of 'sText' as a number. Returns  Nan   if there is no digit at the second to last position. 
// Works only for 1 digit but could be extended to any number
	string  	sText
	variable	len		= strlen( sText )
	variable	number	= str2num( sText[ len-2, len-2 ] )		// 'xyz123' will return  '2'
	return	number
End


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  PADDING  WITH  SPACES 

constant  cSPACEPIXEL = 3,  cTYPICALCHARPIXEL = 6

Function  /S  pad( str, len )
// returns string  padded with spaces or truncated so that 'len' (in chars) is approximately achieved
// Cave: Tabs are counted  8 pixels by IGOR which is obviously NOT what the user expects -> 'str' must NOT contain tabs  or  formatting will fail...
// empirical: a space is 2 pixels wide for font size 8, 3 pixels wide  for font size 9..12, 4 pixels wide for font size 13
	string 	str
	variable	len
	str		= ReplaceString( "\t", str, "" )		// !!! 060106
	variable	nFontSize			= 10
	string  	sFont			= "default"		// GetDefaultFont( "" )
	// print str, FontSizeStringWidth( "default", 10, 0, str ), FontSizeStringWidth( "default", 10, 0, "0123456789" ), FontSizeStringWidth( "default", 10, 0, "abcdefghij" ), FontSizeStringWidth( "default", 10, 0, "ABCDEFGHIJ" )
	variable	nStringPixel		= FontSizeStringWidth( sFont, nFontSize, 0, str )
	variable	nRequestedPixel	= len * cTYPICALCHARPIXEL
	variable	nDiffPixel			= nRequestedPixel - nStringPixel
	variable	OldLen 			= strlen( str )
	if ( nDiffPixel >= 0 )						// string is too short and must be padded
		// printf  "pad [pad] ( %2d\t) has pixel:%3d \trequest px:%2d \tnDiffPixel:%4d\tpad space to len:%3d\t-> '%s'\tOrg:\t'%s' \r", len, nStringPixel, nRequestedPixel,nDiffPixel, oldLen+nDiffPixel / cSPACEPIXEL, PadString( str, oldlen + nDiffPixel / cSPACEPIXEL,  0x20 ), str
		return	PadString( str, OldLen + nDiffPixel / cSPACEPIXEL,  0x20 ) 	
	endif	
	if ( nDiffPixel < 0 )						// string is too long and must be truncated
		string  	strTrunc 
		variable	nTrunc	= min( OldLen, ceil( len*1.3 ) ) + 1	// empirical: start truncation at a string length 30% longer than expected...
		do
			nTrunc	-= 1
			strTrunc	 = str[ 0, nTrunc ]
			// printf  "pad [trunc]( %2d\t) has pixel:%3d \trequest px:%2d \tnDiffPixel:%4d\tstart truncation at:%3d\t-> '%s'\tOrg:\t'%s' \r", len, nStringPixel, nRequestedPixel,nDiffPixel,   nTrunc, strTrunc, str
		while (  nTrunc > 0  &&  FontSizeStringWidth( sFont, nFontSize, 0, strTrunc ) > nRequestedPixel ) 	
		return	strTrunc	
	endif
End

Function  /S  pd( str, len )
// returns string  padded with spaces or truncated so that 'len' (in chars) is approximately achieved. Automatically encloses str  ->  'str'
// Cave: Tabs are counted  8 pixels by IGOR which is obviously NOT what the user expects -> 'str' must NOT contain tabs  or  formatting will fail...
// empirical: a space is 2 pixels wide for font size 8, 3 pixels wide  for font size 9..12, 4 pixels wide for font size 13
//  Tabs:			1		2		3		4			5		6		7
//  len working:		2 3		6 7		10 11	14 15 16		19 20	23 24	27 28
//  len to be avoided:		4 5		8 9		12 13		17 18	21 22	25 26	29 30
//	printf "\r\tTest21 does not work as Igor's   'FontSizeStringWidth()'   does not return correct values -> pd()  ands pad()  cannot work either... \r"

	string 	str
	variable	len

	str		= ReplaceString( "\t", str, "" )		// !!! 060106
	variable	nFontSize			= 10
	string  	sFont			= "default"		// GetDefaultFont( "" )
	// print str, FontSizeStringWidth( "default", 10, 0, str ), FontSizeStringWidth( "default", 10, 0, "0123456789" ), FontSizeStringWidth( "default", 10, 0, "abcdefghij" ), FontSizeStringWidth( "default", 10, 0, "ABCDEFGHIJ" )
	variable	nStringPixel		= FontSizeStringWidth( sFont, nFontSize, 0, str )
	variable	nRequestedPixel	= len * cTYPICALCHARPIXEL
	variable	nDiffPixel			= nRequestedPixel - nStringPixel
	variable	OldLen 			= strlen( str )
	
	if ( nDiffPixel >= 0 )						// string is too short and must be padded
		// printf  "pd [pad]   ( %2d\t) has pixel:%3d \trequest px:%2d \tnDiffPixel:%4d\tpad space to len:%3d\t-> '%s'\tOrg:\t'%s' \r", len, nStringPixel, nRequestedPixel,nDiffPixel, oldLen+nDiffPixel / cSPACEPIXEL, PadString( str, oldlen + nDiffPixel / cSPACEPIXEL,  0x20 ), str
		return	"'" + str + "'" + PadString( str, OldLen + nDiffPixel / cSPACEPIXEL,  0x20 )[ OldLen, Inf ]
	endif	

	if ( nDiffPixel < 0 )						// string is too long and must be truncated
		
		// BAD: Truncating very long strings to short strings in one step by computing the truncation from the strlen/pixel computation of the (long) truncated part  is BAD as the errors can be too large (larger than 1 tab)
		// BAD: variable  nTruncatedLen	= OldLen - 1 +  nDiffPixel / cTYPICALCHARPIXEL		// +2...-2  is not better  than -1
		// BAD: printf  "pd [truncA]( %2d\t) has pixel:%3d \trequest px:%2d \tnDiffPixel:%4d\ttruncating chars:%4d\t->'%s'\tOrg:\t'%s' \r", len, nStringPixel, nRequestedPixel,nDiffPixel,   ceil( nDiffPixel / cTYPICALCHARPIXEL ),str[ 0,OldLen - 1 + ceil( nDiffPixel / cTYPICALCHARPIXEL ) ], str
		// BAD: return	"'" + str[ 0, nTruncatedLen ] + "'"
		// BAD: return	"'" + str[ 0, len ] + "'"					// is not better

		// GOOD: The following loop is necessary although it may be a bit time consuming.
		string  	strTrunc 
		variable	nTrunc	= min( OldLen, ceil( len*1.3 ) ) + 1	// empirical: start truncation at a string length 30% longer than expected...
		do
			nTrunc	-= 1
			strTrunc	 = str[ 0, nTrunc ]
			// printf  "pd [trunc]( %2d\t) has pixel:%3d \trequest px:%2d \tnDiffPixel:%4d\tstart truncation at:%3d\t-> '%s'\tOrg:\t'%s' \r", len, nStringPixel, nRequestedPixel,nDiffPixel,   nTrunc, strTrunc, str
		while (  nTrunc > 0  &&  FontSizeStringWidth( sFont, nFontSize, 0, strTrunc ) > nRequestedPixel ) 	
		return	"'" + strTrunc + "'"	
	endif
End


