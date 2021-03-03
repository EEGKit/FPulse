//
//  UFCom_LineProcessing.ipf 
// 
#pragma rtGlobals=1							// Use modern global access method.

//#pragma IndependentModule=UFCom_

#include "UFCom_Constants"

//==========================================================================================================================
//  PROCESSING  LINES :  REMOVING  AND  REPLACING  BLANKS,  TABS  AND  CR  


Function  /S 	UFCom_RemoveComment( sLine, sComment )
//  deletes everything (including sComment) till end of line
	string 	sLine, sComment
	variable	nCommentPosition = strsearch( sLine, sComment, 0 )
	if ( nCommentPosition != UFCom_kNOTFOUND )
		sLine = sLine[ 0, nCommentPosition - 1 ]
	endif
	return sLine
End


Function  /S 	UFCom_RemoveWhiteSpaceBeforeSep( sLine, sSepString )
// Compacts  'sLine'   before the first occurrence of 'sSepString' .  Used for compacting script files but lcomments (after //) are untouched.
	string 	sLine, sSepString
	variable 	pos	= strsearch( sLine, sSepString, 0 )
	if ( pos < 0 )
		return 	UFCom_RemoveWhiteSpace( sLine )
	elseif ( pos == 0 )
		return	sLine
	else	// ( pos > 0 )
		return 	UFCom_RemoveWhiteSpace( sLine[ 0, pos-1 ] ) + sLine[ pos, inf ] 
	endif
End


Function  /S 	UFCom_RemoveWhiteSpace( sLine )
//? should replace 0x09-0x0d and 0x20  ( to be same as C compiler isspace() )
	string 	sLine
	sLine = ReplaceString( " ", sLine, "" )
	sLine = ReplaceString( "\r", sLine, "" )
	sLine = ReplaceString( "\n", sLine, "" )
	sLine = ReplaceString( "\t", sLine, "" )
	return sLine
End


Function  /S 	UFCom_RemoveWhiteSpace1( sLine )
//? should replace 0x09-0x0d and 0x20  ( to be same as C compiler isspace() )
	string 	sLine
//string slin = UFCom_RemoveWhiteSpace( sLine ) 

	sLine = ReplaceString( " ",  sLine, "" )
	sLine = ReplaceString( "\r", sLine, "" )
	sLine = ReplaceString( "\n", sLine, "" )
	sLine = ReplaceString( "\t", sLine, "" )


// 2005-1006  The following is wrong, as it introduces additional  underscores which is forbidden as the underscore is used as separator in radio button groups...
//...and in the  (old?)  'recipes panel'   -> fPrintMode()  ->  klstAUTOPRINT_TM   ->  SetInitialCheckboxes()
// It works if the auto-built control name is long enough that the added  underscores are truncated again,  it will fail  when the title is short (as it finally did...)
// So: do NOT replace illegal characters by the underscore '_',  instead replace illegal characters by empty string. 
// Cave: do NOT remove any character used as a separator e.g. TILDE_SEP~ , ksTAB_SEP ^ or °  ,  do NOT remove  ':'  or  '|' 
	string  sReplace = ""

// 2005-0201  WRONG     do NOT remove any character used as a separator e.g. TILDE_SEP~ , ksTAB_SEP ^ or °  ,  do NOT remove  ':'  or  '|' 
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


static constant  kASCIITab		= 0x09	//  9	
static constant  kASCII_r		= 0x0d	// 13		// '\r'
static constant  kASCII_n		= 0x0a	// 10		// '\n'
static constant  kASCIISpace	= 0x20	// 32	


Function  /S 	UFCom_RemoveLeadingCR( sLine )
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

Function  /S 	UFCom_RemoveLeadingWhiteSpAndCR( sLine )
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

Function  /S 	UFCom_RemoveLeadingWhiteSpace( sLine )
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
//	while ( UFCom_TRUE )
//	return sLine
End


Function  /S 	UFCom_RemoveTrailingWhiteSpace( sLine )
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
	while ( UFCom_TRUE )
	return sLine
End



Function  /S 	UFCom_RemoveOuterWhiteSpace( sLine )
	string 	sLine
	return	UFCom_RemoveLeadingWhiteSpace( UFCom_RemoveTrailingWhiteSpace( sLine ) )
End


Function	/S	UFCom_ReplaceBlankTabCRBy1Blank( sLine )
	string  	sLine
	string  	sWord, sCompactedLine = ""
	sLine		= ReplaceString( "\n", sLine, " " )
	sLine		= ReplaceString( "\r", sLine, " " )
	sLine		= ReplaceString( "\t", sLine, " " )
	sLine		= UFCom_RemoveLeadingWhiteSpace( sLine )
	variable	n, nWords	= ItemsInList( sLine, " " )		// successive blanks will give empty entries
	for ( n = 0; n < nWords; n += 1 )
		sWord	= StringFromList( n, sLine, " " )
		if ( strlen( sWord ) )
			sCompactedLine += sWord + " "
		endif
	endfor
	return	RemoveEnding( sCompactedLine, " " )
End	


Function	/S	UFCom_ReplaceBlanksTabsBy1Blank( sLine )
	string  	sLine
	string  	sWord, sCompactedLine = ""
	sLine		= ReplaceString( "\t", sLine, " " )
	sLine		= UFCom_RemoveLeadingWhiteSpace( sLine )
	variable	n, nWords	= ItemsInList( sLine, " " )		// successive blanks will give empty entries
	for ( n = 0; n < nWords; n += 1 )
		sWord	= StringFromList( n, sLine, " " )
		if ( strlen( sWord ) )
			sCompactedLine += sWord + " "
		endif
	endfor
	return	RemoveEnding( sCompactedLine, " " )
End	


Function		UFCom_LineEndsWith( sLine, sChar )
	string  	sLine, sChar
	variable	len	= strlen( sLine )
	return	char2num( sLine[ len-1, inf ] ) == char2num( sChar )
End
	

Function    	UFCom_CountLeadingTabs( sString )
	string 	sString
	variable	pos = 0, len	= strlen( sString )
	do 
		if ( char2num( sString[ pos, pos ] ) != kASCIITab   ||   pos >= len - 1 )  
		 	return pos
		endif
	 	pos += 1
	while ( UFCom_TRUE )
End


Function    /S	UFCom_PrependOnce( sPrefix, sString )
	string 	sPrefix, sString
	variable	len	= strlen( sPrefix ) 
	if ( cmpstr( sString[ 0, len - 1 ] , sPrefix ) == 0 )			// sString starts already with sPrefix...
		return   sString								//...so we do  NOT  prepend the prefix a second time
	else
		return   sPrefix + sString
	endif
End


Function    /S	UFCom_RemoveBeginning( sPrefix, sString )
	string 	sPrefix, sString
	variable	len	= strlen( sPrefix ) 
	if ( cmpstr( sString[ 0, len - 1 ] , sPrefix ) == 0 )			// sString starts with sPrefix...
		return   sString[ len, inf ]						//...so we remove sPrefix
	else
		return   sString
	endif
End


Function	/S	UFCom_ReplaceMultipleStrings( lstRepl, sString, sByThis, sReplSep )
// will replace each item of  'lstRepl'   occurring in  'sString'   by   'sByThis'
	string  	lstRepl	// list of strings to be replaced (separated by 'sReplSep')
	string  	sString	// the target
	string  	sByThis, sReplSep 
	variable	n, nItems	= ItemsInList( lstRepl, sReplSep )
	for ( n = 0; n < nItems; n += 1 )
		sString		= ReplaceString( StringFromList( n, lstRepl, sReplSep ), sString, sByThis )
	endfor
	return sString
End

//==========================================================================================================================
//  PROCESSING  LINES :  EXTRACTING  TRAILING CHARACTERS

Function	/S	UFCom_TrailingChar( sText )
// Returns the last character of 'sText' 
	string  	sText
	variable	len		= strlen( sText )
	return	sText[ len-1, len-1 ]
End

Function	/S	UFCom_PreTrailingChar( sText )
// Returns the one-before-last character of 'sText' 
	string  	sText
	variable	len		= strlen( sText )
	return	sText[ len-2, len-2 ]		// 'chanXYZ' will return  'Y'
End

//==========================================================================================================================
//  PROCESSING  LINES :  EXTRACTING  TRAILING NUMBERS

Function	/S	UFCom_LeadingName( sText )
// Returns the name part  in front of the trailing digit. Counterpart to TrailingNumber()
// Works only for 1 digit but could be extended to any number
	string  	sText
	variable	len		= strlen( sText )
	return	sText[ 0, len-2 ]
End

Function		UFCom_TrailingDigit( sText )
// Returns the trailing digit of 'sText' as a number. Returns  Nan   if there is no digit at the end. 
// Returns only the last digit regardless if there are preceding digits or not
	string  	sText
	variable	len		= strlen( sText )
	variable	number	= str2num( sText[ len-1, len-1 ] )		// works for strings where the last character is the index, e.g. '5' or  'Adc5'
	return	number
End

Function		UFCom_TrailingDigits( sText )
// Returns all trailing digits of 'sText' as a number. Returns  Nan   if there are no digits at the end. 
	string  	sText
	variable	l	= strlen( sText )
	do
		l -= 1
		if ( char2num( sText[ l ] ) < char2num( "0" )  ||  char2num( "9" ) < char2num( sText[ l ] ) )
			l += 1
			break			// character at position l is not a digit
		endif
	while	 ( l > 0 )		
	return	 str2num( sText[ l , inf ] )	  
End

Function		UFCom_PreTrailingDigit( sText )
// Returns the digit before the trailing character of 'sText' as a number. Returns  Nan   if there is no digit at the second to last position. 
// Works only for 1 digit but could be extended to any number
	string  	sText
	variable	len		= strlen( sText )
	variable	number	= str2num( sText[ len-2, len-2 ] )		// 'xyz123' will return  '2'
	return	number
End

Function		UFCom_IsTrailingDigit( sText )
// Returns whether  'sText' ends with a trailing digit.
	string  	sText
	variable	len		= strlen( sText )
	variable	number	= str2num( sText[ len-1, len-1 ] )		
	return	numtype( number ) != UFCom_kNUMTYPE_NAN
End

Function	/S	UFCom_RemoveTrailingDigits( sText )
// Truncates trailing digits of 'sText' .
	string  	sText
	if ( UFCom_IsTrailingDigit( sText ) )
		do
			sText = RemoveEnding( sText )
		while ( UFCom_IsTrailingDigit( sText ) )
	endif
	return	sText
End


//==========================================================================================================================
//  PADDING  WITH  SPACES 

static constant  cSPACEPIXEL = 3,  cTYPICALCHARPIXEL = 6

Function  /S  UFCom_pad( str, len )
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

Function  /S  UFCom_pd( str, len )
// returns string  padded with spaces or truncated so that 'len' (in chars) is approximately achieved. Automatically encloses str  ->  'str'
// Cave: Tabs are counted  8 pixels by IGOR which is obviously NOT what the user expects -> 'str' must NOT contain tabs  or  formatting will fail...
// empirical: a space is 2 pixels wide for font size 8, 3 pixels wide  for font size 9..12, 4 pixels wide for font size 13
//  Tabs:			1		2		3		4			5		6		7
//  len working:		2 3		6 7		10 11	14 15 16		19 20	23 24	27 28
//  len to be avoided:		4 5		8 9		12 13		17 18	21 22	25 26	29 30
//	printf "\r\tTest21 does not work as Igor's   'FontSizeStringWidth()'   does not return correct values -> UFCom_pd()  and UFCom_pad()  cannot work either... \r"

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


Function	/S	UFCom_BegEnd( sText, nChars )
// Returns the starting and the ending 'nChars' characters of 'sText'.  Used to  'printf'  string lists longer than Igors limit (250... 400 characters)
	string  	sText
	variable	nChars
	nChars	= min ( nChars,  400/2 )		// Igors limit for  'printf'  is (according to the documentation)  400 characters
	variable	len	= strlen( sText )
	string  	sReturnText	= SelectString( len > 2 * nChars,  sText,  sText[ 0, nChars ] + "' ... '" +  sText[  len - nChars, inf ]  )
	return	sReturnText
End


// unused.......cannot be called from FEval  or  FPuls  
//Function	/S	UFCom_FormatVersion( sVersion, bIsRelease )	  
//// formats version string  e.g. '300'  -> '3.00 D'  or  '1302c'  ->  '13.02.c'
//	string  	sVersion
//	variable	bIsRelease
//	string  	sFormatedVersion						// e.g. '300'  or  '1302c'
//	variable	nVersionNumber	= str2num( sVersion )		// e.g. '300'  or  '1302'
//	variable	len				= strlen( sVersion )
//	string  	sVersionLetter		= SelectString( len == strlen( num2str( nVersionNumber ) ) , "." + sVersion[ len-1, len-1 ], "" )  
//	sprintf  	sFormatedVersion, " %.2lf%s %s" , nVersionNumber / 100 , sVersionLetter, SelectString( bIsRelease, "D", "" )	// D is reminder if we are still in the debug version
//	return	sFormatedVersion
//End


//==========================================================================================================================
//  AUTOMATIC LINE BREAKS

// 2007-0311 todo 
// keep the orininal separators  
Function	/S	UFCom_SeparateString( sText, sFont, nFontSize, nMaxWidth, sDetectSep, sFinalSep, lstLineBreakExceptions )
// Format 'sText'  by inserting line breaks  either after a certain length  or  at the dot which normally finishes a sentence.
	string  	sText, sFont
	variable	nFontSize
	variable  	nMaxWidth		// Insert a line break after this number of points. If set to 'inf'  if no line break is inserted after a certain width. 
	string  	sDetectSep		// e.g  '. '  .  Insert a line break when this separator occurs .  May consist of multiple characters or may be empty.
	string  	sFinalSep			// Usually a line break '\r'  .  Must be just 1 character so that 'ItemsInList()  and 'StringFromList()' will later work.
	string  	lstLineBreakExceptions	// e.g.  'ca. Min. etc. gfs. 

	string  	sSentence	= "", sItem = ""
	// Select temporary separator automatically from a list of unusual characters e.g. # | ^ ° ~ §.   We can use any character as long as it is NOT contained in sText. 
	string  	lstPossibleTempSeps	= "^;#;|;°;~;§;/;"
	variable	nPT, nPTSeps	= ItemsInList( lstPossibleTempSeps ) 
	for ( nPT = 0; nPT < nPTSeps;  nPT += 1 ) 	
		string  	sTempSep	= StringFromList( nPT, lstPossibleTempSeps )	// e.g  '|'   :  Separator which is inserted temporarily at the computed line break positions. String must not and does not contain it.
		if ( strsearch( sText, sTempSep, 0 ) == UFCom_kNOTFOUND )
			break											// this TempSep  is not contained in the string so we may use it
		endif					
		if ( nPT == nPTSeps - 1 )
			DoAlert 0, "Error: " + sText + "  contains all characters of '" + lstPossibleTempSeps + "'  . Cannot insert line breaks.  [UFCom_SeparateString() "
		endif
	endfor
	
	variable	nFSSW	= FontSizeStringWidth(  sFont, nFontSize, 0, sText )
	if ( UFCom_DebugVar( "com", "LineBreak" ) )
		 printf "\t\tUFCom_SeparateString( a)\tDetectSep: '%s'\tMaxWid: %d\tFontSizeStringWidth:%3d\t'%s' \r", sDetectSep, nMaxWidth, nFSSW,  sText
	endif
	if ( strlen( sDetectSep ) ) 
		sText	= UFCom_FormatLineBreaks( sText, sDetectSep, sTempSep, lstLineBreakExceptions )	// keep 'sDetectSep' (e.g.  '.' ) and insert the temporary separator behind e.g. 'Bla bla end. New bla bla..' -> 'Bla bla end. ^New bla bla..'
		if ( UFCom_DebugVar( "com", "LineBreak" ) )
			 printf "\t\tUFCom_SeparateString( b)\tDetectSep: '%s'\tMaxWid: %d\tFontSizeStringWidth:%3d\t'%s' \r", sDetectSep, nMaxWidth, nFSSW,  sText
		endif
	endif

	variable	p, pOld, s, nSentences	= ItemsInList( sText, sTempSep )
	string  	sWord, sLine = "", sTextOut = "", sPossibleDivider	= " "
	for ( s = 0; s < nSentences; s += 1 )

		sSentence	= StringFromList( s,  sText, sTempSep )

		do 
			sWord	= StringFromList( 0, sSentence, sPossibleDivider )
			nFSSW	= FontSizeStringWidth( sFont, nFontSize, 0, sLine + sPossibleDivider + sWord )
			if ( nFSSW < nMaxWidth  ||  strlen( sLine ) == 0  )
				sLine 	+= sWord + sPossibleDivider	// 'sWord' still fits so we add it to the line (only for measuring the length)
				sTextOut 	+= sWord + sPossibleDivider	// 'sWord' still fits so we add it to the output text
				sSentence	= RemoveListItem( 0, sSentence, sPossibleDivider )
				// printf "\t\tUFCom_SeparateString( Added word...       ) \ts :%2d/%2d\tFSSW:%6d\t/%5d\tWord:\t%s\tLine:\t%s\t%s \r", s, nSentences,  nFSSW, nMaxWidth, UFCom_pd(sWord, 19),  UFCom_pd(sLine, 19), sTextOut[0,200]   
			else
				sLine 	 = ""						// appending 'sWord' would make the line too long so start a new 'measuring' line
				sTextOut 	+= sTempSep				// appending 'sWord' would make the line too long so we add a line break to the output text
				// printf "\t\tUFCom_SeparateString( Couldn't add word ) \ts :%2d/%2d\tFSSW:%6d\t/%5d\tWord:\t%s\tLine:\t%s\t%s \r", s, nSentences,  nFSSW, nMaxWidth, UFCom_pd(sWord, 19),  UFCom_pd(sLine, 19), sTextOut[0,200]   
			endif
			
		while	( ItemsInList( sSentence, sPossibleDivider ) )

		sLine 	 = ""					
		sTextOut	+= sTempSep 

	endfor
	
	if ( UFCom_DebugVar( "com", "LineBreak" ) )
		 printf "\t\tUFCom_SeparateString( f )\tDetectSep: '%s'\tMaxWid: %d\tFontSizeStringWidth:%3d  \t'%s' \r", sDetectSep, nMaxWidth, nFSSW,  sTextOut
	endif
	sTextOut	= ReplaceString( sTempSep, sTextOut, sFinalSep )	
	if ( UFCom_DebugVar( "com", "LineBreak" ) )
		 printf "\t\tUFCom_SeparateString( g)\tDetectSep: '%s'\tMaxWid: %d\tFontSizeStringWidth:%3d  \r'%s' \r", sDetectSep, nMaxWidth, nFSSW,  sTextOut
	endif
	return	sTextOut
End


Function	/S	UFCom_FormatLineBreaks( sText, sDetectChar, sReplaceChar, lstLinebreakExceptions )
// Introduces CR after each period but recognises exceptions e.g. 'ca;z.B;etc'
// 2007-0313 simplified and improved code (but does not yet handle the \t case and the parenthesis as below....)
	string  	sText, sDetectChar				// usually  '.'
	string  	sReplaceChar					// usually '\r'
	string  	lstLinebreakExceptions

	// todo  Define a temporary  separator which must not occur within  'sText' 
	string  	sTempSep = "§"
	string  	lstLinebreakExceptionsNew= ReplaceString( sDetectChar, lstLinebreakExceptions, sTempSep )	// 'ca;z.B;etc' -> 'ca;z§B;etc'

	variable	n, nExceptions	= ItemsInList( lstLinebreakExceptions )
	for ( n = 0; n < nExceptions; n += 1 )
		sText	= ReplaceString( StringFromList( n, lstLinebreakExceptions ) + sDetectChar, sText, StringFromList( n, lstLinebreakExceptionsNew ) + sTempSep, 1 )	// case-sensitive replace
	endfor

	sText	= ReplaceString( sDetectChar, sText, sDetectChar + sReplaceChar )		// 'z$B$ Zander, Dorade, etc§ .  Oder'    	->  'z$B$ Zander, Dorade, etc§ .CR  Oder'

	sText	= ReplaceString( sTempSep, sText, sDetectChar )					// 'z$B$ Zander, Dorade, etc§ .CR  Oder' 	->  'z.B. Zander, Dorade, etc. .CR  Oder'  	

	return	sText
End


//Function	/S	UFCom_FormatLineBreaks( sText, sDetectChar, sReplaceChar, lstLinebreakExceptions )
// Introduces CR after each period but recognises exceptions e.g. 'ca;z.B;etc'
//	string  	sText, sDetectChar				// usually  '.'
//	string  	sReplaceChar					// usually '\r'
//	string  	lstLinebreakExceptions
//	variable	s, nSentences = ItemsInList( sText, sDetectChar )				// this is preliminarily considered to be a sentence but later it can also turn out that it is an exception 
//	string  	sSentence, sCRText = ""
//	
//	for ( s = 0; s < nSentences; s += 1 )
//		sSentence	 	= StringFromList( s, sText, sDetectChar )
//		if ( WhichListItem( sSentence, lstLinebreakExceptions ) != UFCom_kNOTFOUND )	//   e.g.  'z.B.'  or  'd.h.' 
//			sCRText	= sCRText + sSentence + sDetectChar
//			continue													// line break has been inserted as no exception has been found
//		endif 
//
//		variable	w, nWords
//		string  	sWord
//		nWords = ItemsInList( sSentence, " " )
//		if ( nWords )
//			sWord	= StringFromList( nWords - 1, sSentence, " " )
//			if ( WhichListItem( sWord, lstLinebreakExceptions ) != UFCom_kNOTFOUND )
//				sCRText	= sCRText + sSentence + sDetectChar
//				continue
//			endif 
//		endif		
//		nWords = ItemsInList( sSentence, "\t" )
//		if ( nWords )
//			sWord	= StringFromList( nWords - 1, sSentence, "\t" )
//			if ( WhichListItem( sWord, lstLinebreakExceptions ) != UFCom_kNOTFOUND )
//				sCRText	= sCRText + sSentence + sDetectChar
//				continue
//			endif 
//		endif		
//		nWords = ItemsInList( sSentence, "(" )					//  (ca   or  (z.B.    are exceptions which will  NOT be line-broken
//		if ( nWords )
//			sWord	= StringFromList( nWords - 1, sSentence, "(" )
//			if ( WhichListItem( sWord, lstLinebreakExceptions ) != UFCom_kNOTFOUND )
//				sCRText	= sCRText + sSentence + sDetectChar
//				continue
//			endif 
//		endif		
//
//// 2007-0311 temporarily changed for  JL  ( was WITH sDetectChar for all other program parts....................!!!!!!)
////		sCRText	= sCRText + sSentence + sDetectChar + " " + sReplaceChar								// Append  'sDetectChar'  (usually '.' ) + ' '  to 'sSentence' .  
//		sCRText	= sCRText + sSentence + sReplaceChar								// Append  'sDetectChar'  (usually '.' ) + ' '  to 'sSentence' .  
//
//	endfor
//	sCRText	= ReplaceString( sDetectChar + " " + sReplaceChar + " " , sCRText, sDetectChar + " " + sReplaceChar )	// Remove the leading blank in each newly formed line
//	return	sCRText
//End


Function	/S	UFCom_GermanUmlaute( sLine )
	string  	sLine
	sLine	  = ReplaceString( "„", sLine, "ä" )
	sLine	  = ReplaceString( "", sLine, "ü" )
	sLine	  = ReplaceString( "”", sLine, "ö" )
	sLine	  = ReplaceString( "Ž", sLine, "Ä" )
	sLine	  = ReplaceString( "™", sLine, "Ö" )
	sLine	  = ReplaceString( "š", sLine, "Ü" )
	sLine	  = ReplaceString( "á", sLine, "ß" )
	sLine	  = ReplaceString( "ø", sLine, "°" )
	sLine	  = ReplaceString( "…", sLine, "à" )  
	sLine	  = ReplaceString( "‚", sLine, "é" ) 
	sLine	  = ReplaceString( "Š", sLine, "è" )  
	sLine	  = ReplaceString( "ˆ", sLine, "ê" )  
	sLine	  = ReplaceString( "Œ", sLine, "î" )   
	sLine	  = ReplaceString( "Ã", sLine, "-" )   
	sLine	  = ReplaceString( "–", sLine, "û" )   
	sLine	  = ReplaceString( "", sLine, "Ø" )   
	sLine	  = ReplaceString( "ï", sLine, "'" )   
	sLine	  = ReplaceString( "Ú", sLine, "'" )   
	sLine	  = ReplaceString( "‡", sLine, "c" )   	// todo: proven‡ale #eéc´c`c#c'   ‡  ccC (Word says  ctrl comma c)  c,c  c
//	sLine	  = ReplaceString( "a", sLine, "Æ" )   
	return	sLine
End


//==========================================================================================================================
//  GREPPING

Function		UFCom_GrepString( sLine, sSearch, bCaseSensitive, bWholeWord )
	string  	sLine, sSearch
	variable	bCaseSensitive, bWholeWord
	string 	sCaseSensitive		= SelectString( bCaseSensitive, "(?i)" , "" )
	string  	sWholeWordPreRX	= SelectString( bWholeWord, "", SelectString( UFCom_StartsWithDigit( sSearch ), "[[:^alpha:]]" , "[[:^digit:]]" ) )
	string  	sWholeWordPostRX	= SelectString( bWholeWord, "", SelectString( UFCom_EndsWithDigit(  sSearch ), "[[:^alpha:]]" , "[[:^digit:]]" ) )
	string  	sRegularExpression	= sCaseSensitive + sWholeWordPreRX + sSearch + sWholeWordPostRX   +  "|"  + "^" + sSearch + "$"
	variable	bFound			= GrepString( sLine, sRegularExpression )
	// printf "\t\tUFCom_GrepString( \tCaseSens:%2d\tWholeWord:%2d\t%s\t%s\t%s\t ) ->\t%s\t \r",  bCaseSensitive, bWholeWord, UFCom_pd( sSearch, 15), SelectString( bFound, "\t", "found in" ), UFCom_pd( sLine, 44),  sRegularExpression
	return 	bFound		
End

Function		UFCom_StartsWithDigit( sString )
	string  	sString
	return 	numType( str2num( sString[ 0 ] ) )  != UFCom_kNUMTYPE_NAN
End

Function		UFCom_EndsWithDigit( sString )
	string  	sString
	//print "\t\t\t\t\t\t\t\t\t\tUFCom_EndsWithDigit( sString ) ", sString, numType( str2num( sString[ strlen( sString ) - 1 ] )  ) != UFCom_kNUMTYPE_NAN
	return 	numType( str2num( sString[ strlen( sString ) - 1 ] ) )  != UFCom_kNUMTYPE_NAN
End

Function 	tstgrep()
	string  	lstStrings	= "cakes and brownies;the quick brown fox;burr_brown_Comp;123brown007678;123brown007-678;.brown,;brown;cakes and Brownies;the quick Brown fox;Burr_Brown_Comp;123Brown007678;123Brown007-678;.Brown,;Brown;"
	variable	n, nItems	= ItemsInList( lstStrings )

	variable	bCaseSensitive	= 0 
	variable	bWholeWord	= 0	
	string  	sLine, sSearch
	variable	bFound

	sSearch	= "brown"
	for ( n = 0; n < nItems; n += 1 )
		sLine		= StringFromList( n, lstStrings )
		bFound	= UFCom_GrepString( sLine, sSearch, bCaseSensitive, bWholeWord )
	endfor

	sSearch	= "brown007"
	for ( n = 0; n < nItems; n += 1 )
		sLine		= StringFromList( n, lstStrings )
		bFound	= UFCom_GrepString( sLine, sSearch, bCaseSensitive, bWholeWord )
	endfor

	sSearch	= "007"
	for ( n = 0; n < nItems; n += 1 )
		sLine		= StringFromList( n, lstStrings )
		bFound	= UFCom_GrepString( sLine, sSearch, bCaseSensitive, bWholeWord )
	endfor

	sSearch	= "00"
	for ( n = 0; n < nItems; n += 1 )
		sLine		= StringFromList( n, lstStrings )
		bFound	= UFCom_GrepString( sLine, sSearch, bCaseSensitive, bWholeWord )
	endfor

	sSearch	= "0"
	for ( n = 0; n < nItems; n += 1 )
		sLine		= StringFromList( n, lstStrings )
		bFound	= UFCom_GrepString( sLine, sSearch, bCaseSensitive, bWholeWord )
	endfor

End


