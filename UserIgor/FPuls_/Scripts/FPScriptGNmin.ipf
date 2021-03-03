// FPScript.ipf 
// 
// General routines for loading and processing scripts used by FPulse  and by  FEVAL
//
// History: 
// 161001 
// Syntax convention: Sweep starts with  the 'Sweeps: N=n' line and ends at the first 'Blank'  or the 'SweepEnd', whichever comes first.
// Syntax convention: Loops are allowed only within sweeps, but sweeps not within loops 
// Consequences: No 'Blanks'  within or before the 'Segments, etc' within a Sweep. No 'Blanks'  within a loop, as this would break the Sweep.

// 090902		PULSE + PoN + 1Sweep
//	case1	Script does contain Pon line,	sweeps:n>1 : PoN is displayed,  		 1 PoN   sweep is written after n>1 Adc sweeps into CFS file (normal PULSE mode) 
//	case2	Script does contain Pon line,	sweeps:n=1 : PoN (fake) is displayed, no PoN sweep is written after n=1 Adc sweeps into CFS file (warning: illegal mode) 
//	case3	Scrpt does NOT contain Pon line,	sweeps:n>1 : PoN is not displayed,      1 (fake) sweep is written after n>1 Adc sweeps into CFS file (warning: illegal mode) 
//	case4	Scrpt does NOT contain Pon line,	sweeps:n=1 : PoN is not displayed,     no PoN  sweep is written after n=1 Adc sweeps into CFS file (normal SPIKE mode) 
// 	The  
 
#pragma rtGlobals=1						// Use modern global access method.
// Indices into wave  'wG'  holding all general numbers which define a script
constant	kSI = 0,  kCNTDA = 1,  kCNTAD = 2,  kCNTTG = 3,  kCNTPON = 4,  kCNTIO = 5,  kBLOCKS = 6,  kSWPS_WRITTEN = 7,  kPNTS = 8,  kTOTAL_US = 9,   kTOTAL_SWPS = 10
constant	kMAX = 11


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function		CreateGlobalsInFolder_Script()
// creates all folder-specific variables. To be used once from CreateGlobals() as the current data folder is changed and not restored
	NewDataFolder  /O  /S root:uf:script		// make a new data folder and use as CDF,  clear everything

	DefineScriptKeys()					// for data which are not cleared when a script is loaded e.g. 'wMK', 'wSK' , 'gsMainkey'  and 'gsScriptPath'   

	string		/G	gsScriptPath	= ksSCRIPTS_DRIVE + ksSCRIPTS_DIR + ksDIRSEP	
End

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//    SCRIPT  SYNTAX  DEFINITION

constant		cEXACTLY_ONCE = 1, cISIO = 2, cISCOMP = 4, cISSTIM = 8			// MainKey Param1, Bits can be combined

// 151002 sALLIODATA  is a complete list of all possible IO subkeys used as an index in the array wIO. 
// Not all combinations are valid e.g. it makes no sense to have a Dac have a TGChan, and although PoN has a SmpInt the user should not have access to it in the script.
// Only valid IO-IOSubkey -combinations are included in wSK, those missing there are invalid.
// Only Chan and SmpInt must be provided in the script, others can be missing. Checking those 2 entries is not coded in wSK but done automatically elsewhere.
//constant		cIONM = 0,  cIOCHAN = 1,  cIONAME = 2,  cIOGAIN = 3,  cIOTGCH = 4,  cIOTGMCCH = 5,  cIOSRC = 6,  cIOUNIT = 7,  cIOSMPI = 8,  cIORGB = 9,  cIOUSED = 10,  cIOLAST = 11
//strconstant	sALLIODATA 	= "Nm;Chan;Name;Gain;TGChan;TGMCChan;Src;Units;SmpInt;RGB;used;"
constant		cIONM = 0,  cIOCHAN = 1,  cIONAME = 2,  cIOGAIN = 3,  cIOGAINOLD = 4,  cIOTGCH = 5,  cIOTGMCCH = 6,  cIOSRC = 7,  cIOUNIT = 8,  cIOSMPI = 9,  cIORGB = 10,  cIOUSED = 11,  cIOLAST = 12
strconstant	sALLIODATA 	= "Nm;Chan;Name;Gain;GainOld;TGChan;TGMCChan;Src;Units;SmpInt;RGB;used;"

Function		DefineScriptKeys()
// This functions determines how the script is interpreted: which error or warnings are issued, which defaults are used,.. 
// ..which main and sub keys must appear exactly once, which may be missing, which can occur multiple times
// The entries here also determine how the the internal data structure  'wVal' is built
// Colors of appr. equal intensity: R=(57344,0,0)  G=(0,53248,0)  B=(0,0,65535)
// the Adc should have 'mV' and not 'pA' as default units to display TGChan correctly (they do not not have their own units) [or leave pA and give them selectively mV]   

	variable	n	= -1 
	make /O /T /N=( 30 )	   root:uf:script:wMK, root:uf:script:wSK
	wave  /T	wMK		= root:uf:script:wMK
	wave  /T	wSK		= root:uf:script:wSK

	n += 1; 	wMK[ n ]	= "PULSE;1";		wSK[ n ]	= ""	
	n += 1; 	wMK[ n ]	= "Protocol;1";		wSK[ n ]	= "Name;"	
	//n += 1; 	wMK[ n ]	= "DisplayCfg;0";	wSK[ n ]	= "Name;"	

// Only valid IO-IOSubkey -combinations are included in wSK, those missing there are invalid.
// 040119	We unfortunately must allow  RGB in the script (actually it belongs to the DCF file)  to be able to display multiple Dacs in different colors 
// 040123  do NOT change this order 'Dac,Adc,PoN,...'  as it must be the same order as the memory splitting in the Ced1401 
// 040127 Cave: Set default value of variables (not strings) to Nan here  SetDefaults() / wSK[]   AND  check for Nan  in  ExtractLinesIntoIO(step7)  to enable complaining about missing imandatory values.
//   		IO Subkey 	;        Param1  	is default   for number, string or list
	n += 1; 	wMK[ n ]	= "Dac;2"; 		wSK[ n ]	= "Chan;NaN|SmpInt;100|Name;|Units;mV|Gain;NaN|RGB;(40000,0,40000)" 	// user cannot access  Src, TGChan
	n += 1; 	wMK[ n ]	= "Adc;2"; 		wSK[ n ]	= "Chan;NaN|SmpInt;100|Name;|Units;mV|Gain;NaN|TGChan;NaN|TGMCChan;NaN|RGB;(0,53248,0);"

	n += 1; 	wMK[ n ]	= "PoN;4";		wSK[ n ]	= "Src;NaN|Name;|Units;|RGB;(57344,0,0)"							// user cannot access  Chan, TGChan, SmpInt or Gain 
	n += 1; 	wMK[ n ]	= "Sum;4";		wSK[ n ]	= "Src;NaN|Name;|Units;|RGB;(0,30000,30000)"						// user cannot access  Chan, TGChan, SmpInt or Gain 
	n += 1; 	wMK[ n ]	= "Aver;4";		wSK[ n ]	= "Src;NaN|Name;|Units;|RGB;(0,40000,40000)"						// user cannot access  Chan, TGChan, SmpInt or Gain 

//   		STIM  Subkey 	;     Param1  is default for number  ....todo as above for lists
	n += 1; 	wMK[ n ]	= "Frames;0";		wSK[ n ]	= "N;1"									
	n += 1; 	wMK[ n ]	= "Sweeps;0";		wSK[ n ]	= "N;1|PoN;0|CorrAmp;0"	// CorrAmp default is a forbidden value (e.g. 0,Nan,Inf..) to detect and correct a missing value								
	n += 1; 	wMK[ n ]	= "Loop;0";		wSK[ n ]	= "N;1"							
	n += 1; 	wMK[ n ]	= "EndLoop;0";		wSK[ n ]	= ";"								
	n += 1; 	wMK[ n ]	= "EndSweep;0";	wSK[ n ]	= ";"								
	n += 1; 	wMK[ n ]	= "EndFrame;0";	wSK[ n ]	= ";"								

	n += 1; 	wMK[ n ]	= "Blank;8";		wSK[ n ]	= "Dac;(Nan)|Amp;(Nan)|Dig;(Nan)"							// The  '(NaN)'  contains multiple entries...			
	n += 1; 	wMK[ n ]	= "Segment;8";		wSK[ n ]	= "Dac;(Nan)|Amp;(Nan)|Dig;(Nan)"							// ..which are defined and extracted in 'ExtractEValues()'				
	n += 1; 	wMK[ n ]	= "VarSegm;8";		wSK[ n ]	= "Dac;(Nan)|Amp;(Nan)|Dig;(Nan)"							
	n += 1; 	wMK[ n ]	= "Ramp;8";		wSK[ n ]	= "Dac;(Nan)|Amp;(Nan)|Dig;(Nan)"							
	n += 1; 	wMK[ n ]	= "StimWave;8";	wSK[ n ]	= "Dac;(Nan)|Wave;(Nan)|Dig;(Nan)"							
	n += 1; 	wMK[ n ]	= "Expo;8";		wSK[ n ]	= "Dac;(Nan)|AmpTau;(Nan)|Dig;(Nan)"	

	redimension	 /N=( n + 1 ) wMK, wSK 
	MakeTyp()
End

//strconstant	ksIOTYPES	= "Dac;Adc;PoN;Sum;Aver;"									// must be same order as in wMK[]
constant		kIO_DAC = 0, 	kIO_ADC = 1, 	kIO_PON = 2, kIO_SUM = 3, kIO_AVER = 4, kIO_MAX = 5	// must be same order as in wMK[]


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  INTERFACE  FOR  TEMPLATE  MAINKEYS  and SUBKEYS   wMK  and  wSK    
//  wMK and wSK are program supplied templates describing  the allowed properties of  script data..
//  .. (e.g. how many ADC channels are allowed in script file, must the SmpInt be given in script line ) )...

Function   /S	MKNm( nMK ) 
// returns  template mainkey name when mainkey index  is given, e.g. "Dac", "Adc",...   ???slow
	variable	nMK
	wave  /T	wMK	= root:uf:script:wMK
	return	StringFromList( 0, wMK[ nMK ] )
End


Function		MKTyp( nMK ) 
// returns template mainkey typ when mainkey index  is given..
// ...whether the mainkey  is an  IO channel (e.g.Adc,Dac), or a Computed channel (e.g.PoN,Aver,...), or  a STIMULUS  line, or General line (=Protocol, Pulse, Frames)..
	variable	nMK
	wave  /T	wMK	= root:uf:script:wMK
	return	str2num( StringFromList( 1, wMK[ nMK ] ) )
End

Function		MKMustOccurOnce( nMK ) 
// returns whether template mainkey  must occur exactly once in script
	variable	nMK
	return	MKTyp( nMK ) &  cEXACTLY_ONCE
End

Function		MKIsIO( nMK )
// ...returns TRUE when the mainkey ( given as index into template)  is an  IO channel (e.g.Adc,Dac)
	variable	nMK
	return	MKTyp( nMK ) & cISIO
End

Function		MKIsComp( nMK )
// ...returns TRUE when the mainkey ( given as index into template)  is a Computed channel (e.g.PoN,Aver,...)
	variable	nMK
	return	MKTyp( nMK ) & cISCOMP
End

Function		MKIsIOorComp( nMK )
// ...returns TRUE when the mainkey ( given as index into template)  is an  IO channel (e.g.Adc,Dac) or a Computed channel (e.g.PoN,Aver,...)
	variable	nMK
	return	MKIsIO( nMK )  ||  MKIsCOMP( nMK )
End

//Function		MKIsStim( nMK )
//	variable	nMK
//	return	MKTyp( nMK ) & cISSTIM
//End


Function	 /S	SKList( sMK, sSep )
// returns list of corresponding template subkeys (without defaults, etc.) when mainkey string is given
	string	 	sMK, sSep
	string	 	sSKList = ""
	variable	n, nMK = mI( sMK )
	for ( n = 0; n < SKCnt( nMK ); n += 1 )
		sSKList	+= SKNm( nMK, n ) + sSep
	endfor
	return	sSKList
End

Function	 	SkCnt( nMK )
// returns number of template subkeys when mainkey index is given
	variable	nMK
	string 	sSKs	= SKStr( nMK )
	return	ItemsInList( sSKs, "|" )
End

Function	 /S	SkNm( nMK, nSK )
// returns  template subkey name when mainkey index and subkey index  is given
	variable	nMK, nSK
	string 	sSKs	= SKStr( nMK )
	string 	sSKInfo	= StringFromList( nSK, sSKs, "|" )
	return	StringFromList( 0, sSKInfo )
End

Function	 /S	SkDef( nMK, nSK )
// returns  template subkey default when mainkey index and subkey index  is given
	variable	nMK, nSK
	string 	sSKs	= SKStr( nMK ), sSKInfo	= StringFromList( nSK, sSKs, "|" )
	return	StringFromList( 1, sSKInfo )
End

Function	 /S	SkDefS( nMK, sSK )
// returns  template subkey default when mainkey index and subkey string  is given
	variable	nMK
	string 	sSK
	string 	sSKnude	= mkS( nMK )
	variable	nSK		= WhichListItem( sSK, sSKnude, "," )
	string 	sSKs	= SKStr( nMK ), sSKInfo	= StringFromList( nSK, sSKs, "|" )
	//print "skdefs" , nMK, sSK, "->", sSKnude, nSK, sSks, "<<<", sSKInfo, ">>>", StringFromList( 1, sSKInfo )
	return	StringFromList( 1, sSKInfo )
End

Function	 /S	eaDef( sMK, sSK )
// returns  template subkey default   as  number  when mainkey string  and subkey string  is given
	string 	sMK, sSK
	return	SKDefS( mI( sMK ), sSK )
End


Function		mkI( nMK, sSK )
// returns  template subkey  index  when mainkey index  and subkey string  is given,  not found returns -1
// Design issue (currently first approach is used (in this case we  could use shorter function below) : 
// - either 	use this function liberally, allow invain search, don't print message,  but then check return code of -1
// - or	check that nMainIndex and sSubKey match before entry into this function, print error and  correct code to avoid it
	variable	nMK
	string 	sSK
	variable	nListIndex = WhichListItem( sSK, mkS( nMK ), sPSEP ) 
	// if ( nListIndex == -1 )
	// 	printf "\t\t\tmKI() could not find '%s' in '%s' (~%d) [containing:'%s'] \r", sSK, mS(nMK) , nMK , twSubKey[ nMK ]
	// endif
	return	nListIndex
End

Function	/S	SKStr( nMK ) 
// returns the complete subkey string for a given mainkey index
	variable	nMK
	wave  /T	wSK		= root:uf:script:wSK
	return	wSK[ nMK ]
End

Function		SKMax()
// returns maximum number of subkeys of all mainkeys (there is a different number of subkeys for each main key)
	variable	k, nMax = 0
	for ( k = 0; k <  MKCnt(); k += 1 )
		nMax = max( nMax,  SKCnt( k ) )
	endfor
	return	nMax + 1 	// all counted  PLUS ONE for  Type  (Sweeps, Segment, Ramp..)
End

Function		MKCnt()
// returns number of main keys  by counting  subkeys 
	wave  /T	wSK		= root:uf:script:wSK
	return	numPnts( wSK )
End

//Function		IsKey( nMK, nSK, sSubKeys )
//// returns TRUE if  template subkey  defined by  given mainkey index  and  subkey index is found in given 'sSubKeys' list 
//	variable	nMK, nSK
//	string	sSubKeys
//	return	WhichListItem( SKNm( nMK, nSK ), sSubKeys, "," ) == NOTFOUND ? FALSE : TRUE 
//End


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//    INTERFACE  FOR  TEMPLATE  DERIVED MAIN  KEY  =  STRING LIST  'sMainKey' 

Function   /S	ListAllPossibleIOTypes()
// For faster access to mainkey and subkey data:  Build list containing all IO and Comp mainkeys from program template supplied  'wMK'  ordered like in 'wMK'
	string  	lstIOTyp	= ""
	variable	n
	for ( n = 0; n < MKCnt(); n += 1)											// for all mainkeys found in template 
		if ( MKIsIOorComp( n ) )
			lstIOTyp	= AddListItem( MKNm( n ), lstIOTyp, ";" , Inf )				// build the IO mainkey list  e.g. 'Adc,Dac,PoN,Aver....'
		endif
	endfor
	//printf "\t\tListAllPossibleIOTypes()    [%d]  '%s'    \r",  ItemsInList( lstIOTyp), lstIOTyp
	return	lstIOTyp
End


Function   /S	MakeTyp()
// For faster access to mainkey and subkey data:  Build mainkey string  'sMainKey'  containing all mainkey  keywords from program template supplied  'wMK'  and  'wSK'
	string  /G	root:uf:script:gsMainKey	= ""
	svar		gsMainKey	= root:uf:script:gsMainKey
	variable	n
	for ( n = 0; n < MKCnt(); n += 1)											// for all mainkeys found in template 
		gsMainKey	= AddListItem( MKNm( n ), gsMainKey, ",", Inf )				// build the main key list  e.g. 'PULSE,Protocol,Adc,Dac,Sweeps,Segment...'
	endfor
	//printf "\t\tMakeTyp()    [%d]  '%s'    \r",  MKCnt(), gsMainKey
End

Function		mI( str )
//  Get index when MainKey string is given 
	string	str
	svar		gsMainKey	= root:uf:script:gsMainKey
	return	WhichListItem( str, gsMainKey, "," )
End

Function   /S	mS( nMK )
// returns  template mainkey name when mainkey index  is given, e.g. "Dac", "Adc",...  ?=??? fast
	variable	nMK
	svar		gsMainKey	= root:uf:script:gsMainKey
	return	StringFromList( nMK, gsMainKey, sPSEP )	
End

Function   /S	mkS( nMK )
// returns list of corresponding template subkeys (without defaults, etc.) when mainkey  index is given
	variable	nMK
	svar		gsMainKey	= root:uf:script:gsMainKey
	return 	SKList( StringFromList( nMK, gsMainKey, "," ) , "," )	//...???? 0204
End


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  IMPLEMENTATION   AND   ACCESS FUNCTIONS  FOR  THE   IO CHANNEL  'Dac0,Adc2,PoN2,Adc0..'  :  ' wIO'   
//  Properties 'wIO' : script IO (and COMP) data needed for window arrangement during acquisition, no block/frame/sweep expansion
//  only for IO script lines (= mainkeys  'Dac',  'Adc' , 'PoN'): store into  and retrieve the subkey values, e.g 'Chan', 'SmpInt'  from array

Function	  	ioSet( wIO, nIO, c, nData, sVal )
// stores string 'sVal'   in  3 dim. IO wave  at position given by script channel number  and   subkey index  nData  determining  the type of  sVal 
	wave  /T	wIO
	variable	nIO, c, nData
	string 	sVal
	wIO[ nIO ][ c ][ nData ]	= sVal
End

Function	/S	ios( wIO, nIO, c, nData )
// returns IO data as string from IO wave given the subkey index
	wave  /T	wIO
	variable	 nIO, c, nData
	return	wIO[ nIO ][ c ][ nData ]
End

Function		iov( wIO, nIO, c, nData )
// returns IO data as number  when  ioTyp, index into ioType  and  IO data type to be retrieved is given
	wave  /T	wIO
	variable	 nIO, c, nData
	return	str2num( wIO[ nIO ][ c ][ nData ] )
End

Function		ioUse( wIO, nIO )
// Returns  number of script channels of this ioType . Returns  0  when this IO type is not found in script.
// The (second) index 0 is used for storing the maximum number of script entries  for this ioType. 
// Cave: the value  nIO = NOTFOUND (=-1) is passed  e.g. in ComputeAver() when 'Aver' is not defined in script
	wave  /T	wIO
	variable	nIO
	variable	ioUse	= str2num( wIO[ nIO ][ 0 ][ cIOUSED ] )	
	return	( numtype( ioUse ) == cNUMTYPE_NAN )  ?  0  :  ioUse		// returns 0 rather than Nan
//	return	str2num( wIO[ nIO ][ 0 ][ cIOUSED ] )						// 041109 returned Nan
End

Function		ioCnt( wIO )
// returns number of  IO and COMP script entries
	wave  /T	wIO
	variable	nIO, c, cCnt, ioch = 0
	for ( nIO = 0; nIO < kIO_MAX; nIO += 1 )		
		cCnt	= ioUse( wIO, nIO )
		ioch += cCnt
	endfor
	return	ioch
End

Function	/S	IOList( wIO, nData )
	wave  /T	wIO
	variable	nData
	variable	nIO,c, cCnt
	string  	sList	= ""
	for ( nIO = 0; nIO < kIO_MAX; nIO += 1 )
		cCnt	= ioUse( wIO, nIO )
		for ( c = 0; c < cCnt; c += 1 )
//			sList	= AddListItem( wIO[ nIO ][ c ][ nData ], sList, ";", Inf )
			sList	= AddListItem( ios( wIO, nIO, c, nData ) , sList , ";" , Inf )
		endfor
	endfor
	return	sList
End

Function   /S	ioChanList( wIO )
// returns list of all channels contained in script  e.g.  'Dac0, Adc2,Adc0,Sum1'  
	wave  /T	wIO
	return	IOList( wIO, cIONM )
End


Function	/S	FldAcqioio( sFolder, wIO, nIO, c, nData )
// Returns  IO string   (including folder)    when  IO type , index into ioType  and  data type to be retrieved is given
	string  	sFolder
	wave  /T	wIO
	variable	nIO, c, nData
	return	"root:uf:" + sFolder + ksF_SEP + ksF_IO + ksF_SEP + ios( wIO, nIO, c, nData )
End

Function	/S	FldAcqioPoNio( sFolder, wIO, nIO, c, nData )	 
	string  	sFolder
	wave  /T	wIO
	variable	nIO, c, nData
	return	"root:uf:" + sFolder + ksF_SEP + ksF_IO + ksF_SEP +  "PoN" + sIOCHSEP + ios( wIO, nIO, c, nData )
End

Function		Nm2NioC( wIO, sTNm, nIO, c )
	wave  /T	wIO
	string 	sTNm
	variable	&nIO, &c						// parameters are changed
	variable	cCnt
	for ( nIO = 0; nIO < kIO_MAX; nIO += 1 )	
		cCnt	= ioUse( wIO, nIO )
		for ( c = 0; c < cCnt; c += 1 )
			if ( cmpstr( 	sTNm, ios( wIO, nIO, c, cIONM ) ) == 0 )
			//if ( cmpstr( 	sTNm, wIO[ nIO ][ c ][ cIONM ] ) == 0 )
				//print "\t\t\tNm2NioC() ", sTNm,  "->", nIO, c
				return 0
			endif
		endfor
	endfor
	return	cNOTFOUND
End

Function   /S	ioTNm( nIO )
// returns string when index is given, e.g  'Adc'
	variable	nIO
	return 	StringFromList( nIO, ksIOTYPES  )
End

Function		ioIsIO( nIO )
// returns TRUE for an IO channel (=Adc,Dac),  else FALSE
	variable	nIO
	return	nIO <= kIO_ADC
End

Function		ioIsCOMP( nIO )
// returns TRUE for a  COMP channel (=PoN,Sum,Aver),  else FALSE
	variable	nIO
	return	nIO >= kIO_PON
End

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	INTERFACE  FOR   wVal	to hide the implementation 
// 	Properties 'wVal' : data for stimulus construction, with frame expansion, (contains also IO and COMP information, which is not used because appears too late)
//	' wVal' : intermediary stage of data refinement, script line oriented
//	contains different frames (not error checked), but no Loop expansion, no PoverN, no Inc/Decrement
//	useful for all values which occur only once AND where only one frame is allowed: e.g. 'Protocol', 'Sweeps'...

// Implementation as StringList( maxFrm ) : saving 1 dimension : a lot better  (306: .55s  + 312: 1.7s)
// Much faster than the previous implementation which was using an (overdimensioned) 3dim text wave. The processing time for 1 element was ~ n leading overall to time ~ n*n. (Improvement in test case was 60s -> 1.3s)
// Cave: AddListItem()   in  vS()  works  only when building  wVal  the first time  and  only  when  adding the items in the right order.   'ReplaceListItem()'  would  be more general and universal...
Function		vMakeWVal( sFolder, nLines, nKeys, maxFrm )
	string	  	sFolder
	variable	nLines, nKeys, maxFrm
	make	/O /T /N	= ( nKeys, nLines ) $"root:uf:" + sFolder + ":ar:wVal"	
End

Function		vMaxLines( wVal )
	wave  /T	wVal
	return	dimSize( wVal, 1 )
End 

Function	/S 	vG( wVal, nLine, nSubKey, nFrm )
// retrieves string  from ' wVal' 
	wave  /T	wVal
	variable	nLine, nSubKey, nFrm
	return	StringFromList( nFrm, wVal[ nSubKey ][ nLine ] )
End 

Function		vS( wVal, nLine, nSubKey, nFrm, str )
// stores  string  'str'  in  ' wVal'
// Cave: AddListItem()  works  only when building  wVal  the first time  and  only  when  adding the items in the right order.   'ReplaceListItem()'  would  be more general and universal...
	wave  /T	wVal
	variable	nLine, nSubKey, nFrm
	string		str
	wVal[ nSubKey ][ nLine ] = AddListItem( str, wVal[ nSubKey ][ nLine ],  ";" , nFrm )
End 


// 1 Original version : too slow (306: 2.8s  + 312: 7.8s)
//Function		vMakeWVal( nLines, nKeys, maxFrm )
//	variable	nLines, nKeys, maxFrm
//	make	/O /T /N	= ( nLines, nKeys, maxFrm ) root:uf:stim:wVal	// include frame dimension to store  the lists of changing parameters
//End
//Function		vMaxLines()
//	wave  /T	wVal	= root:uf:stim:wVal	
//	return	dimSize( wVal, 0 )
//End 
//Function	/S 	vG( wVal, nLine, nSubKey, nFrm )
//// returns string  from ' wVal'[ nLine ][ nSubKey ][ nFrm ]
//	variable	nLine, nSubKey, nFrm
//	wave  /T	wVal	= root:uf:stim:wVal	
//	return	wVal[ nLine ][ nSubKey ][ nFrm ]
//End 
//Function		vS( wVal,nLine, nSubKey, nFrm, str )
//// sets string  ' wVal'[ nLine ][ nSubKey ][ nFrm ]
//	variable	nLine, nSubKey, nFrm
//	string		str
//	wave  /T	wVal	= root:uf:stim:wVal	
//	wVal[ nLine ][ nSubKey ][ nFrm ] = str
//End 


// Implementation as StringList( nKeys ) : saving 1 dimension : a lot better  (306: .6s  + 312: 1.8s)
//Function		vMakeWVal( nLines, nKeys, maxFrm )
//	variable	nLines, nKeys, maxFrm
//	make	/O /T /N	= ( maxFrm, nLines ) root:uf:stim:wVal	// include frame dimension to store  the lists of changing parameters
//End
//Function	/S 	vG( wVal, nLine, nSubKey, nFrm )
//// returns string  from ' wVal'[ nSubKey ][ nFrm ][ nLine ]
//	variable	nLine, nSubKey, nFrm
//	wave  /T	wVal	= root:uf:stim:wVal	
//	return	 StringFromList( nSubKey, wVal[ nFrm ][ nLine ] )
//End 
//Function		vS( wVal,nLine, nSubKey, nFrm, str )
//// sets string  ' wVal'[ nSubKey ][ nFrm ][ nLine ]
//	variable	nLine, nSubKey, nFrm
//	string		str
//	wave  /T	wVal	= root:uf:stim:wVal	
//	wVal[ nFrm ][ nLine ] = AddListItem( str, wVal[ nFrm ][ nLine ],  ";" , nSubKey )
//End 
//Function		vMaxLines()
//	wave  /T	wVal	= root:uf:stim:wVal	
//	return	dimSize( wVal, 1 )
//End 


//// 2 test : swapped lines  -  keys, frames : a bit better  (306: 2.2s  + 312: 6s)
//Function		vMakeWVal( nLines, nKeys, maxFrm )
//	variable	nLines, nKeys, maxFrm
//	make	/O /T /N	= ( nKeys, maxFrm, nLines ) root:uf:stim:wVal	// include frame dimension to store  the lists of changing parameters
//End
//Function	/S 	vG( wVal, nLine, nSubKey, nFrm )
//// returns string  from ' wVal'[ nSubKey ][ nFrm ][ nLine ]
//	variable	nLine, nSubKey, nFrm
//	wave  /T	wVal	= root:uf:stim:wVal	
//	return	wVal[ nSubKey ][ nFrm ][ nLine ]
//End 
//Function		vS( wVal,nLine, nSubKey, nFrm, str )
//// sets string  ' wVal'[ nSubKey ][ nFrm ][ nLine ]
//	variable	nLine, nSubKey, nFrm
//	string		str
//	wave  /T	wVal	= root:uf:stim:wVal	
//	wVal[ nSubKey ][ nFrm ][ nLine ] = str
//End 
//Function		vMaxLines()
//	wave  /T	wVal	= root:uf:stim:wVal	
//	return	dimSize( wVal, 2 )
//End 


//// 3 test : swapped lines  -  keys, frames : a bit better  (306: 2.3s  + 312: 6s)
//Function		vMakeWVal( nLines, nKeys, maxFrm )
//	variable	nLines, nKeys, maxFrm
//	make	/O /T /N	= ( maxFrm, nKeys, nLines ) root:uf:stim:wVal	// include frame dimension to store  the lists of changing parameters
//End
//Function	/S 	vG( wVal, nLine, nSubKey, nFrm )
//// returns string  from ' wVal'[ nFrm ][ nSubKey ][ nLine ]
//	variable	nLine, nSubKey, nFrm
//	wave  /T	wVal	= root:uf:stim:wVal	
//	return	wVal[ nFrm ][ nSubKey ][ nLine ]
//End 
//Function		vS( wVal,nLine, nSubKey, nFrm, str )
//// sets string  ' wVal'[ nFrm ][ nSubKey ][ nLine ]
//	variable	nLine, nSubKey, nFrm
//	string		str
//	wave  /T	wVal	= root:uf:stim:wVal	
//	wVal[ nFrm ][ nSubKey ][ nLine ] = str
//End 
//Function		vMaxLines()
//	wave  /T	wVal	= root:uf:stim:wVal	
//	return	dimSize( wVal, 2 )
//End 


//// 4 test : swapped lines  -  keys, frames : as original  (306: 2.8s  + 312: 7s)
//Function		vMakeWVal( nLines, nKeys, maxFrm )
//	variable	nLines, nKeys, maxFrm
//	make	/O /T /N	= ( nKeys, nLines, maxFrm ) root:uf:stim:wVal	// include frame dimension to store  the lists of changing parameters
//End
//Function	/S 	vG( wVal, nLine, nSubKey, nFrm )
//// returns string  from ' wVal'[ nSubKey ][ nLine ][ nFrm ]
//	variable	nLine, nSubKey, nFrm
//	wave  /T	wVal	= root:uf:stim:wVal	
//	return	wVal[ nSubkey ][ nLine ][ nFrm ]
//End 
//Function		vS( wVal,nLine, nSubKey, nFrm, str )
//// sets string  ' wVal'[ nSubKey ][ nLine ][ nFrm ]
//	variable	nLine, nSubKey, nFrm
//	string		str
//	wave  /T	wVal	= root:uf:stim:wVal	
//	wVal[ nSubkey ][ nLine ][ nFrm ] = str
//End 
//Function		vMaxLines()
//	wave  /T	wVal	= root:uf:stim:wVal	
//	return	dimSize( wVal, 1 )
//End 

//// 5 test : swapped keys, frames : even worse  (306: 7s  + 312: 11s)
//Function		vMakeWVal( nLines, nKeys, maxFrm )
//	variable	nLines, nKeys, maxFrm
//	make	/O /T /N	= ( nLines, maxFrm, nKeys ) root:uf:stim:wVal	// include frame dimension to store  the lists of changing parameters
//End
//Function	/S 	vG( wVal, nLine, nSubKey, nFrm )
//// returns string  from ' wVal'[ nLine ][ nFrm ][ nSubKey ]
//	variable	nLine, nSubKey, nFrm
//	wave  /T	wVal	= root:uf:stim:wVal	
//	return	wVal[ nLine ][ nFrm ][ nSubKey ]
//End 
//Function		vS( wVal,nLine, nSubKey, nFrm, str )
//// sets string  ' wVal'[ nLine ][ nFrm ][ nSubKey ]
//	variable	nLine, nSubKey, nFrm
//	string		str
//	wave  /T	wVal	= root:uf:stim:wVal	
//	wVal[ nLine ][ nFrm ][ nSubKey ] = str
//End 
//Function		vMaxLines()
//	wave  /T	wVal	= root:uf:stim:wVal	
//	return	dimSize( wVal, 0 )
//End 


//// 6 test : swapped lines  -  keys, frames : worse  (306: 7s  + 312: 11s)
//Function		vMakeWVal( nLines, nKeys, maxFrm )
//	variable	nLines, nKeys, maxFrm
//	make	/O /T /N	= ( maxFrm, nLines, nKeys ) root:uf:stim:wVal	// include frame dimension to store  the lists of changing parameters
//End
//Function		vMaxLines()
//	wave  /T	wVal	= root:uf:stim:wVal	
//	return	dimSize( wVal, 1 )
//End 
//Function	/S 	vG( wVal, nLine, nSubKey, nFrm )
//// returns string  from ' wVal'[ nFrm ][ nLine ][ nSubKey ]
//	variable	nLine, nSubKey, nFrm
//	wave  /T	wVal	= root:uf:stim:wVal	
//	return	wVal[ nFrm ][ nLine ][ nSubKey ]
//End 
//Function		vS( wVal,nLine, nSubKey, nFrm, str )
//// sets string  ' wVal'[ nFrm ][ nLine ][ nSubKey ]
//	variable	nLine, nSubKey, nFrm
//	string		str
//	wave  /T	wVal	= root:uf:stim:wVal	
//	wVal[ nFrm ][ nLine ][ nSubKey ] = str
//End 



static constant	cTY 				= 0 		// for  ' wVal' 

Function  		vTyp( wVal, nLine )
// returns value  from ' wVal'[ key=cTY=0 ][ frm=0 ][ nLine ] : the index of the mainkey of  line 'nLine'  
	wave  /T	wVal	
	variable	nLine
	return	str2num( vG( wVal, nLine, cTY, 0 ) ) 
End 

Static Function	WhichValScriptLine( wVal, nType )
// returns the index in wVal ( ~ the script line )  when the main index (into 'xTyp') is given
// returns the first occurrence ->  must not occur more than once (only for Protocol, Frames, Sweeps)
	wave  /T	wVal	
	variable	nType		// the main index into 'xTyp'
	variable	n
	for ( n = 0; n < vMaxLines( wVal ); n += 1 )
		if ( nType == vTyp( wVal, n ) )
			return n
		endif
	endfor
	return -1
End	
		
Function	/S	vGetS( wVal, sMainKey, sSubKey )
// returns corresponding  string   to sMainKey + sSubKey from ' wVal'
// applicable when 'sMainkey'  occurs only once in script (only for Protocol, DisplayCfg) 
// Example: vGetS( "Protocol", "Name" ) 
// computing with vGetS()  is very slow : takes 300 us
	wave  /T	wVal	
	string		sMainKey, sSubKey
	variable	nMain	= mI( sMainKey )
	variable	nLine	= WhichValScriptLine( wVal, nMain )
	string		sVal		= vG( wVal, nLine,  WhichListItem( sSubKey, mkS( nMain ), SPSEP ) + 1, 0 )	// indexing starts at 1
	return	sVal
End	

//Function  vGet( sMainKey, sSubKey )
//// returns corresponding  variable   to sMainKey + sSubKey from ' wVal'
//// applicable when 'sMainkey'  occurs only once in script (only for Protocol, DisplayCfg) 
//// Example: vGet( "Sweeps", "CorrAmp" )
//// computing with vGet()  is very slow :  takes 300 us
//	string	sMainKey, sSubKey
//	return	str2num( vGetS( sMainKey, sSubKey ) )
//End	

////////////////////////////////////////////////////////////////////////

Function	/S 	vGE( wVal, wELine, c, nBlk, nFrm, nEle, nKey )
// returns string value  from  wVal   from   given element  number   and key number
	wave  /T	wVal	
	wave	wELine				// contains wVal line number for  given frame and elememt
	variable	c, nBlk, nFrm, nEle, nKey 
	return	vG( wVal,  wELine[ c ][ nBlk ][ nEle ],  nKey, nFrm )
End 

Function /S	vGES( wVal, wELine, c, nBlk, nFrm, nEle, sKey )
// returns string value  from  wVal   from   given element  number   and key string
	wave  /T	wVal	
	wave	wELine				// contains wVal line number for  given frame and elememt
	variable	c, nBlk, nFrm, nEle
	string 	sKey 
	variable	nLine	= wELine[ c ][ nBlk ][ nEle ]
	variable	nKey		= mkI(  vTyp( wVal, nLine ), sKey )    +   1
	if  ( nKey == 0 )			// mkI() returned error (=-1) meaning the element given by eTyp() had no subkey 'sKey'
		printf "\tInfo: vGES() could not find  %s \tin  %s~:%d \t(c:%d  nBlk:%d  nFrm:%d, nEle:%d, nLine:%d)   \r", pd(sKey,8),  pd(mS( vTyp( wVal, nLine ) ),8)  , vTyp( wVal, nLine ), c, nBlk, nFrm, nEle, nLine
		return	""
	else
		return	vG( wVal, nLine, nKey, nFrm )
	endif
End 



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//    INTERPRET   SCRIPT

Function 	InterpretScript( sFolder, bDoAcq )
// reads script of type PULSE, extracts all data, builds all the necessary DAC, ADC, Dig waves..
// ..and extracts (and stores) supplementary data needed for display formating, for IO, etc.
// extracts the numbers  from ' wLines' and stores  them in ' wVal'
// fills in missing values, builds DAC wave from ' wVal'
// this routine is very slow when the script loaded contains MANY FRAMES and few sweeps/blocks (e.g 100 and  1/1)  compared to 10/10/1  or 10/1/10.  
	string		sFolder								// subfolder of root (root:'sF':...) used to discriminate between multiple instances of the InterpretScript()  e.g. from FPulse and from FEval
	variable	bDoAcq
	string		bf	
	variable	nPnts, maxDChs, nBlk, maxFrm, maxEle, nKeys, MainDac

	NewDataFolder  /O	$"root:uf:" + sFolder + ":ar"				// for the arrays  e.g.  wIO , wVal , wE
	NewDataFolder  /O	$"root:uf:" + sFolder + ":dig"			// for the digital IO strings and waves which control the Ced1401

// 041201b
	string	  /G					$"root:uf:" + sFolder + ":dig:gsDigOutChans"	= ""
	string   /G					$"root:uf:" + sFolder + ":dig:gsDigoutSlices"		= ""
	variable /G				$"root:uf:" + sFolder + ":dig:gnJumpBack"		= 0

	NewDataFolder  /O	$"root:uf:" + sFolder + ":stim"			// for the Save/NoSave and Digout display waves on screen
	NewDataFolder  /O	$"root:uf:" + sFolder + ":store"			// for the data controlling the storing of periods and the skipping of blanks 
	NewDataFolder  /O	$"root:uf:" + sFolder + ksF_SEP + ksF_IO	// for the large basic IO waves  e.g. 'Dac0'  ,  'Adc1' , 'PoN1'  and  for  'sDacUnits..'
// test 041028
if ( bDoAcq )
	CreateGlobalsInFolder_Co( sFolder )						// creates  'root:uf:acq:co'
	NewDataFolder	/O	$"root:uf:" + sFolder + ":dispFS"			// root:uf:acq:dispFS  (acquisition) : for the whole bunch of similar display waves Adc..., Dac... with different FrmSwp-suffices
endif

	ResetStartTimer( "OverAll" )

	// Step 1: Processing 'wLines' 
	ShowLines( sFolder, " original  ")

//keep:wG
	make /O/N = (kMAX)  $"root:uf:" + sFolder + ":keep:wG"  = 0	// for all general acquisition variables	e.g. SmpInt, CntAD, Pnts [must not be deleted on 'Apply' after 'Start' as used in XOP]
	wave  	wG	     = 	 $"root:uf:" + sFolder + ":keep:wG"  	// There are 2  instances of  'wG :  in FPulse  in folder  'Acq'   and in FEval  in folder  'eval' 

	if ( ExtractLinesIntoIO( sFolder, wG ) )					// Construct wIO
		return cERROR
	endif
	wave  /T	wIO	    = 	 $"root:uf:" + sFolder + ":ar:wIO"  	// There are 2  instances of  'wIO' :  in FPulse  in folder  'Acq'   and in FEval  in folder  'eval' 
	
	if ( CheckMandatorySubkeys( wIO ) )
		return cERROR
	endif

// test 041028
if ( bDoAcq )
	if ( TelegraphConnect( wG, wIO ) )					// set wG[ nCntxx,...] 
		return cERROR
	endif
endif

	if ( CheckPresenceOfRequiredSrcChans( wIO ) )			// step 7: check if the 'Src' channels required by the computed channels are present
		return	cERROR
	endif
	
	ShowIO( wIO ) 			   						// for Debugging, do not delete
	ShowKeys()

	if ( CheckScriptSetSI( sFolder, wG ) )
		return cERROR
	endif
	
 	nBlk		= Check_Frm_Swp_EndSwp_EndFrm( sFolder )	// preliminary block count (not used)...
	if ( nBlk == cERROR )						
		return cERROR							
	endif
	
 	ExpandLines( sFolder, "Loop", "EndLoop" )
	ShowLines( sFolder, " after loop expansion  ")

	// extract structure of text wave and set values in ' wVal'
	nKeys	= SKMax()								// counts only, does not set.(returns one more, for 'nType').
	maxDChs	= GetNumberOfDacChannels( sFolder )		//todo eliminate
	
	MainDac	= ExtractFixSweepData( sFolder, wG )			// Construct wFix for FixSweepData, sets eBlocks, eMaxFrames, eMaxSweeps 
	wave  	wFix	 = $"root:uf:" + sFolder + ":ar:wFix"  		// There are 2  instances of  'wFix' :  in FPulse  in folder  'Acq'   and in FEval  in folder  'eval' 
	if ( PossiblyInsertIntervals( sFolder, MainDac ) )
		return	cERROR
	endif 
	ShowLines( sFolder, "after inserting IFI / IBI ")	

	if ( CheckCombinationPoNSweeps( sFolder, wG, wFix ) )
		return	cERROR
	endif
	AdjustMissingCorrAmp( wG, wFix )
	maxFrm	= eMaxFrames( wG, wFix )
	maxEle	= SetNumberOfElemsInSweeps( sFolder, wG )	// Construct  wELine
	wave	wEinCB	= $"root:uf:" + sFolder + ":ar:wEinCB"	// There are 2  instances of  'wEinCB' :  in FPulse  in folder  'Acq'   and in FEval  in folder  'eval' 
	wave  	wELine	= $"root:uf:" + sFolder + ":ar:wELine"  	// There are 2  instances of  'wELine' :  in FPulse  in folder  'Acq'   and in FEval  in folder  'eval' 
	if ( maxEle == cERROR )
		return cERROR
	endif

	//printf "\t\tInterpretScript() \t DacChans:%d  nBlk:%d  maxFrm:%g  maxSwp:%g  nEle:%g nKeys:%g   MainDac:%d  \r", maxDChs, nBlk, eMaxFrames( wG, wFix ), eMaxSweeps( wG, wFix ), maxEle, nKeys, MainDac

	// Step 2: Processing 'wVal' 
	vMakeWVal( sFolder, nLines( sFolder ), nKeys, maxFrm )	// Construct wVal . Include frame dimension to store  the lists of changing parameters
	wave  /T	wVal	= $"root:uf:" + sFolder + ":ar:wVal"  		// There are 2  instances of  'wVal' :  in FPulse  in folder  'Acq'   and in FEval  in folder  'eval' 
	
	if ( ExtractLinesIntoVal( sFolder, wVal, maxFrm ) )
		return cERROR
	endif

	ShowVal( wVal, maxFrm )							// for Debugging, do not delete
	// ExtractValSetEle()  takes the biggest part of the time needed to load script if there are MANY FRAMES and few sweeps/blocks (e.g 100 and  1/1).  
	// If the same overall script data are split into 10 fr and 10 sw / 1 bl  OR  10 fr and 1 sw / 10 bl   ExtractValSetEle()  needs times comparable to other routines.    
	// This is due to the fact that frames must (in contrast to sweeps and blocks) process incrementing/decrementing and lists.
	ExtractValSetEle( sFolder, wG, wVal, wFix, wEinCB, wELine, maxDChs, maxEle ) 		// Construct  wE, wBFS, wLineRef
	wave  /T	wBFS 	= $"root:uf:" + sFolder + ":ar:wBFS"  	// There are 2  instances of  'wBFS' :	in FPulse  in folder  'Acq'   and in FEval  in folder  'eval' 
	wave  	wE	 	= $"root:uf:" + sFolder + ":ar:wE"  		// There are 2  instances of  'wE' :  	in FPulse  in folder  'Acq'   and in FEval  in folder  'eval' 
	wave  /T	wLineRef	= $"root:uf:" + sFolder + ":ar:wLineRef"

	// Step 3: Processing 'wEl' 
	ShowAmpTimes( wG, wFix, wEinCB, wE, wBFS, "--Raw       " )				// for Debugging, do not delete
	ShowEle(  wG, wFix, wEinCB, wE, wBFS, "--Raw     " )				//  nBlk/nFrm???for Debugging, do not delete

	AdjustInterFrameInterval( wG, wFix, wEinCB, wE, wBFS )
	AdjustInterBlockInterval( wG, wFix, wEinCB, wE, wBFS )

	ExpandFramesIncDec( wG, wFix, wEinCB, wE, wBFS )
	ShowAmpTimes( wG, wFix, wEinCB, wE, wBFS, "--After IncDec" )				// for Debugging, do not delete
	ShowEle( wG, wFix, wEinCB, wE, wBFS, "--After IncDec" )				// for Debugging, do not delete
	ExpandSweepsWithPoverN( wG, wFix, wEinCB, wE, wBFS )

	ShowAmpTimes( wG, wFix, wEinCB, wE, wBFS, "--After PoN" )				// for Debugging, do not delete
	ShowEle( wG, wFix, wEinCB, wE, wBFS, "--After PoN" )				// for Debugging, do not delete

	nPnts = ComputeTotalPoints( sFolder, wG, wIO, wFix, wEinCB, wELine, wE, wBFS, wLineRef )				// sets wG[ kPNTS ]

	if ( nPnts <= 0 )
		return cERROR						// no points  or  cERROR because  durations not consistent with sample interval
	endif	

	// Step 4: Processing 'wDGO' Digital outputs
//041202
	ProcessDigitalOutputs( sFolder, wG, wVal, wFix, wEinCB, wELine, wE, wBFS, maxEle )				// CED1401 dependent

	// Step 5: Converting 'wEl'  into the stimulus wave
	if ( OutElemsAllToWaves( sFolder, wG, wIO, wVal, wFix, wEinCB, wELine, wE, wBFS ) )			//  constructs  'DacN' waves
		return cERROR
	endif

//if ( bDoAcq )
//if ( bDoAcq )
if ( bDoAcq )
//	SupplyWavesCOMPChans( sFolder, wG, wIO )				// constructs 'PoNN' , 'PeakN' ....waves
endif
//endif
//endif
	// Step 6: Displaying the stimulus wave
//	DisplayStimulus( sFolder, wG, wIO, wFix, kDOINIT )			// displays partial waves with automatic names,  kDOINIT= -1 enforces initialization 

//041202
	if ( bDoAcq )						// not if called from FEval
//		if ( CEDInitialize( sFolder, wG, wIO ) )		
//			return cERROR 			// executing the Ced initialization already here (and not later when the acquistion is started)  saves valuable 'PreStart'-time 
//		endif
	endif
//print  "no  CEDInitialize"

	return	0		
End


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//   Advance from  wLines  to  wIO
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

static Function	ExtractLinesIntoIO( sFolder, wG )				
// Read script  wLines (again), get all values from IO section of  the script  and store them in  wIO
// wIO[ nData : Name, Units, YZoom, IsIO... ]  stores script data and computed data  as a strings  AND stores the number of used channels of the given IO type
	string		sFolder								// subfolder of root (root:'sF':...) used to discriminate between multiple instances of the InterpretScript()  e.g. from FPulse and from FEval
	wave	wG
	string		sIOMk
	variable	nMK
	string  	lstIOMks		= ListAllPossibleIOTypes()						// all possible mainkeys (including those not used in script)   of type IO or Comp e.g. 'Dac,Adc,PoN,Aver...'
	variable	nPossibleIOMks	= ItemsInList( lstIOMks )
	variable	nSortedIndex	= 0
	variable	nLastIOLine	= 0
	variable	nError		= 0
	make  /T /O	/N=(cMAXCHANS*3)	wSortedIOLines

	// Approach1 (not taken): loop only through  lines  between 'FPulse' / 'Protocol'  and 'Frames'  . The first entry in these lines is considered to be an ioType e.g. 'Adc' . This approach includes illegal / misspelled ioTypes.
	// Approach2 : loop through all lines, compare 1. entry with entries in list 'Adc,Dac,PoN...'. If it matches it is an IO-line which must be sorted.

	// Step1 : Sort the IO and Comp lines in the order determined by  'wMK'  into  'wSortedIOLines'  
	for ( nMK = 0; nMK < nPossibleIOMks; nMK += 1 )						// Loop through all allowed IO and Comp mainkeys as defined elsewhere
		sIOMk	= StringFromList( nMK, lstIOMks )
		variable	l, nLineCnt = nLines( sFolder )
		string		sLine
		for ( l = 0; l < nLineCnt; l += 1 )									// Loop through the whole script (comments and blank lines have already been removed)
			sLine		=  GetScrLine( sFolder, l )
			if ( cmpstr( StringFromList( 0, sLine, sMAINKEYSEP ), sIOMk ) == 0 )	// does Line contain the first expected key ?
				wSortedIOLines[ nSortedIndex ] = sLine
				nSortedIndex += 1
				nLastIOLine	= max( l, nLastIOLine )					// keep maximum as every new mainkey may set 'nLastLineSorted' back
			endif
		endfor
	endfor

	// Step2 : Copy the sorted IO and Comp lines from 'wSortedIOLines'  back into 'wLines' 
	// after this step 'wLines' contains all  IO and Comp lines in a sorted order between  nFirstLineSorted  and  nLastLineSorted . This simplifies access in the following steps.
	variable	nFirstIOLine = nLastIOLine - nSortedIndex + 1 
	for ( l = nFirstIOLine; l <= nLastIOLine ; l += 1 )	
		SetScrLine( sFolder, l, wSortedIOLines[ l - nFirstIOLine ] )
	endfor
	killwaves	wSortedIOLines
	//printf "\t\t\tExtractLinesIntoIO(2)  \tSorted %d lines in cleaned script ( from line %d to %d ) .\r", l - nFirstIOLine, nFirstIOLine, nLastIOLine 

	// Step 3: Construct the wave  'wIO' which holds the IO . Construct it large enough for any case and redimension it later to the needed size.
	variable	nIO, nMaxOf1Type
	variable	nIOLines	= nLastIOLine - nFirstIOLine + 1
	make   /O /T /N=( kIO_MAX, nIOLines, cIOLAST )  $"root:uf:" + sFolder + ":ar:wIO" = ""	// nIOLines are too many but will be redimensioned below
	wave	/T 		wIO					=  $"root:uf:" + sFolder + ":ar:wIO"		// "" sets the initial count of each IO type to Nan = 0 = missing
	//wIO	= ""

	// Step 4: Count and fill in the number of each IO type (Adc, Dac, PoN...) channels
	for ( l = nFirstIOLine; l <= nLastIOLine ; l += 1 )	
		sLine			=  GetScrLine( sFolder, l )
		sIOMk		= StringFromList( 0, sLine, sMAINKEYSEP )	
		nIO			= WhichListItem( sIOMK, ksIOTYPES  )
		if ( numType( iov( wIO, nIO, 0, cIOUSED ) ) == NUMTYPE_NAN )
			ioSet( wIO, nIO, 0, cIOUSED, num2str( 0 ) ) 							// initial  Nan  is	 converted to zero
		endif
		ioSet( wIO, nIO, 0, cIOUSED, num2str( iov( wIO, nIO, 0, cIOUSED ) + 1 ) )	
		nMaxOf1Type	= max( nMaxOf1Type, iov( wIO, nIO, 0, cIOUSED ) )				// get the most channels of any IO type
	endfor

	wG[ kCNTDA ]	= iov( wIO, kIO_DAC, 0, cIOUSED )
	wG[ kCNTAD ]	= iov( wIO, kIO_ADC, 0, cIOUSED )
	wG[ kCNTPON]	= iov( wIO, kIO_PON, 0, cIOUSED )

	//printf "\t\t\tExtractLinesIntoIO(4) \tFolder: .. :%s: ..\tIOLines:%d\tRedimension wIO to [ %d ][ nMaxOf1Type:%2d ][ %d ] \tCntDA:%d  CntAD:%d  CntPoN:%d \r ", sFolder, nIOLines, kIO_MAX, nMaxOf1Type, cIOLAST, wG[ kCNTDA ],  wG[ kCNTAD ], wG[ kCNTPON ]

	redimension	/N = ( -1, nMaxOf1Type, -1 ) 	wIO	

	// Step5: Fill  wIO - read the script data into linear  wIO [ Name,Units,YZoom,RGB...] , the channels are stored as string list
	variable	nKeys, k, nData
	string 	sEntries, sData, sFrom, sSKNm
	variable	nIOOld = -1 , c = -1
	for ( l = nFirstIOLine; l <= nLastIOLine ; l += 1 )	
		sLine		= GetScrLine( sFolder, l )
		sIOMk	= StringFromList( 0, sLine, sMAINKEYSEP )
		sLine		= RemoveListItem( 0, sLine, sMAINKEYSEP )				// remove main key and colon, leave sub keys
		nIO	= WhichListItem( sIOMk, ksIOTYPES )
		if ( nIO != nIOOld )
			c 		= -1
		endif	
		c 	+= 1
		nIOOld	= nIO
		nMK		= mI( sIOMk )
		nKeys	= SKCnt( nMK )										// for all keys found in template w_SK
		for ( k = 0; k < nKeys; k += 1 )
			sSKNm		= SKNm( nMK, k )
			sEntries	= StringByKey( sSKNm, sLine, sVALSEP, sLISTSEP ) 		// try to get all values/strings supplied in w_SK from this script line, some will be missing
			sData	= SelectString( strlen( sEntries ), SKDef( nMK, k ), sEntries)	// use default value if script entry is missing
			if ( strsearch( sData, sVALSEP, 0 ) != NOTFOUND )
				Alert( cFATAL,  "Could not interpret '" + sData + "' in line '" + sLine + "'. " )
				return	cERROR
			endif
			sFrom		= SelectString( strlen( sEntries ), "defaulted to", "read from script" )
			nData		= WhichListItem( sSKNm, sALLIODATA )
			ioSet( wIO, nIO, c, nData, sData )								// store general entries from script or defaults
			//printf "\t\t\t\tExtractLinesIntoIO(5) \tnIO:%2d   c:%2d\tnMK:% d\tsMK:\t%s\t(k:%2d)\t%s\t  %2d\t%s\t%s\t%s  \r", nIO, c, nMK, pd(sIOMk,6), k, pad( sFrom,13), nData, pd(sSKNm,8), pad(sData,8) ,  pad( ios( wIO, nIO, c, nData ), 8 ) 
		endfor	
	endfor	
	PrintIO( wIO, "ReadValuesAndDefaults()" )

	// Step 6 : Build  'Name' . This cannot be done  in step 1 as  'Nm'  and  'Chan'  (and also  'Gain'  and  'SmpInt' )  must have been extracted before.
	variable	cCnt
	for ( nIO = 0; nIO < kIO_MAX; nIO += 1 )
		cCnt	= ioUse( wIO, nIO )
		for ( c = 0; c < cCnt; c += 1 )
			sData	= BuildIONm( wIO, nIO, c )							// use script supplied  'Name'  if possible  or else build  from  Nm, Chan, Src
			ioSet( wIO, nIO, c, cIONM, sData )								// store  'Name'  general entries from script or defaults
		endfor
	endfor
	PrintIO( wIO, "BuildIONm()" )
	
	return	nError
End

static Function   /S	BuildIONm( wIO, nIO, c )
// returns the name of this IO channel e.g. 'Dac0'  or  'Adc2'    or    COMP  channel e.g. 'PoN1' (name with channel number)
// Remark: 050402  PoN  is  something  between  a true IO  and  a true COMP
//  is  COMP  because computations have to be done, but Src is number not string
	wave  /T	wIO
	variable	nIO, c
	string 	sFullName = "???", sSrc, sOneSrc, sSrcTNm
	variable	n, nSrcCnt, nSrcioch
	// construct  IO names  e.g. Adc2, Dac1...  by combining  ioTyp name   and  number from subkey 'Chan'
	if ( ioIsIO( nIO ) )
		sFullName	= ioTNm( nIO )  + sIOCHSEP + ios( wIO, nIO, c, cIOCHAN )
	endif
	// construct COMP names e.g. PoN0, Sum21... for computed channels  by combining  ioTyp name  and  entries read from subkey 'Src'  
	if ( ioIsComp( nIO ) ) 
		sFullName	= ioTNm( nIO )
		sSrc		= ios( wIO, nIO, c, cIOSRC ) 
		nSrcCnt	= ItemsInList( sSrc, sPSEP )
		for ( n = 0; n < nSrcCnt; n += 1 )
			sOneSrc	  =   StringFromList( n, sSrc, sPSEP )
			sFullName +=  sIOCHSEP + sOneSrc				

			// 040127  also supply  'Gain'  and  'SmpInt'  for computed channels.  This is more for completeness, this informaton is not used at the moment....
			// Assumption 1 : Use the one and only src entry for  'PoN'  and  'Aver' ,  for  'Sum'  having multiple sources use the first src to inherit  'Gain'  and  'SmpInt' 
			if ( n == 0 )	
				// Assumption 2 : The src type for  'PoN'  is always  'Adc' . It is NOT specified in script.   For  'Aver'  and  'Sum'  the src type  and channel must be specified in script.
				if ( strlen( LeadingName( sOneSrc ) ) == 0 )    // OR  NAN     AND REMOVE spaces.............    TODO
					sSrcTNm	= "Adc" + num2str( TrailingDigit( sOneSrc ) )
				else
					sSrcTNm	=  sOneSrc
				endif
				// Cave: this code works but is not very robust as it relies on the fact that computed channels are ordered behind Adc and Dac. It will break when nSrcioch is greater than ioch...
				// ...as  the cIONM list is built by / after leaving this function whereas we access the cIONM list already here in 'Nm2NioC'  at a time where it is still being built. 
				//nSrcioch	= Nm2NioC( wIO, sSrcTNm )
				variable	rSrcIO, rSrcC
				Nm2NioC( wIO, sSrcTNm, rSrcIO, rSrcC )
	
				ioSet( wIO, nIO, c, cIOGAIN, ios( wIO, rSrcIO, rSrcC, cIOGAIN ) ) 
				ioSet( wIO, nIO, c, cIOSMPI, ios( wIO, rSrcIO, rSrcC, cIOSMPI ) )	
	
	 			// printf "\t\t\tBuildIONm(ca=ioch: %d) \tsOneSrc: '%s'  \tsSrcTNm: '%s'  \tCopying Gain[nSrcioch: %d ] : %s  and SmpInt[..] : %s  into Computed channel ioch: %d  \r", ioch, sOneSrc, sSrcTNm, nSrcioch, ios( wIO, nSrcioch , cIOGAIN ), ios( wIO, nSrcioch, cIOSMPI ), ioch
			endif
 			//printf "\t\t\tBuildIONm( nIO:%d  c:%d )\tsrcCh:%d/%d   sSrc: '%s'   sOneSrc: '%s'   %s  \r", nIO, c, n, nSrcCnt, sSrc, sOneSrc, SelectString( n == nSrcCnt - 1, "", "returning sFullName:" + sFullName + "'" )
		endfor
	endif
	return	sFullName
End

static Function		CheckMandatorySubkeys( wIO )
	// Step 7 : Check that mandatory entries are not missing   and   use  Gain defaults for   'PoN' 
	// 040127 Cave: Set default value of variables (not strings) to Nan in  SetDefaults() / w_SK[]   AND  check Nan here   to enable complaining about missing imandatory values.
	wave  /T	wIO
	variable	nError		= 0

	variable	nIO, c, cCnt
	nIO	= kIO_DAC
	cCnt	= ioUse( wIO, nIO )
	for ( c = 0; c < cCnt; c += 1 )
		nError	+=	CheckMissing( wIO, nIO, c, cIOCHAN, cFATAL, "After  'Dac:'  the specification   'Chan = n'   is required. " )
		nError	+=	CheckMissing( wIO, nIO, c, cIOGAIN,  cFATAL, "After  'Dac:'  the specification   'Gain = n'   is required. " )
	endfor

	nIO	= kIO_ADC
	cCnt	= ioUse( wIO, nIO )
	for ( c = 0; c < cCnt; c += 1 )
		nError	+=	CheckMissing(   wIO, nIO, c, cIOCHAN, cFATAL, "After  'Adc:'  the specification   'Chan = n'   is required. " )
		// We just alert with a non-fatal  warning about missing Adc gain  as the user might prefer to set it later during the experiment in the AxoGain panel 
		if (   IsMissingVal( wIO, nIO, c, cIOGAIN )   &&   IsMissingVal( wIO, nIO, c, cIOTGCH )   &&   IsMissingVal( wIO, nIO, c, cIOTGMCCH ) )	
			Alert( cLESSIMPORTANT, "After  'Adc:'   the specification  'Gain = n'  or  'TGChan = n'  or  'TGMCChan = n'  is expected. Using Adc default gain = " + num2str(cADCGAIN_DEFAULT) )
			ioSet( wIO, nIO, c, cIOGAIN, num2str( cADCGAIN_DEFAULT ) )
		endif
		if ( (  ! IsMissingVal( wIO, nIO, c, cIOGAIN )   &&  ! IsMissingVal( wIO, nIO, c, cIOTGCH ) )  ||  (  ! IsMissingVal( wIO, nIO, c, cIOGAIN )   &&  ! IsMissingVal( wIO, nIO, c, cIOTGMCCH ) )  ||  (  ! IsMissingVal( wIO, nIO, c, cIOTGCH )   &&  ! IsMissingVal( wIO, nIO, c, cIOTGMCCH ) ) )
			Alert( cFATAL, "After  'Adc:'  only 1 of the specifications   'Gain = n'  or  'TGChan = n'  or  'TGMCChan = n'  is allowed. " )
			nError	+= 1
		endif
	endfor

	// This checks that there is a  'Src=AdcN'  entry at all.  That  'AdcN'   exists in the script is  NOT  checked  here but later in  'CheckPresenceOfRequiredSrcChans()'   
	for ( nIO = kIO_PON; nIO < kIO_MAX; nIO += 1 )
		cCnt	= ioUse( wIO, nIO )
		for ( c = 0; c < cCnt; c += 1 )
			if ( IsMissingStr( wIO, nIO, c, cIOSRC ) )
				Alert( cFATAL, "After  'PoN:'  or  'Aver:'  or  'Sum:'  the specification   'Src = n'  is required. " )
				nError	+= 1
			endif	
		endfor
	endfor
	PrintIO( wIO, "CheckMandatorySubkeys()" )
	return	nError
End


static Function		CheckMissing( wIO, nIO, c,  nData, nErrorLevel, sText )
	wave  /T	wIO
	variable	nIO, c,  nData, nErrorLevel
	string 	sText
	variable	nCode	= 0
	if ( IsMissingVal( wIO, nIO, c, nData ) )				
		Alert( nErrorLevel, sText )
		if ( nErrorLevel >= cFATAL )
			nCode	= 1
		endif
	endif
	return	nCode
End

static Function		IsMissingVal( wIO, nIO, c,  nData )
	wave  /T	wIO
	variable	 nIO, c,  nData
	return	numtype( iov( wIO, nIO, c, nData ) ) == NUMTYPE_NAN  
End

static Function		IsMissingStr( wIO, nIO, c,  nData )
	wave  /T	wIO
	variable	nIO, c,  nData
	//printf "\t\t\t\tIsMissingStr(  ioch,  nData )  len:%d  '%s'     compare to Nan : %d \r", strlen( ios( ioch, nData ) ) , ios( ioch, nData ) ,  cmpstr( ios( ioch, nData ) , "Nan" ) 	
	return	! cmpstr( ios( wIO, nIO, c, nData ) , "Nan" ) 		// if the Src entry is missing there will be the string 'NaN' as specified in w_SK[] 
End

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//   TELEGRAPH  CHANNELS  INITIALIZATION

static Function		TelegraphConnect( wG, wIO )
// Count the telegraph AD channels, not the MultiClamp channels. .....Old.....store the AD-Telegraph-connection information  contained in and extracted from  'wIO'  also  in  2  lists 
// We can  NOT at this early stage determine the telegraph gain because the Ced is not yet open (when 'Apply' is executed the first time after program start) . 
// The preliminary gain is set later in CedInitialize()
 
	wave	wG
	wave  /T	wIO	
	variable	bPrintIt		= 0 // 0 or 1 
	string		bf
	wG[ kCNTTG ]	= 0
	variable	nIO		= kIO_ADC
	variable	c, cCnt	= ioUse( wIO, nIO )
	for ( c = 0; c < cCnt; c += 1 )
		ioSet( wIO, nIO, c, cIOGAINOLD,  "0" )								// Initialise old gain with the illegal value 0 to trigger the updating when data are written
//		variable	Chan		= iov( wIO, nIO, c, cIOCHAN ) 
		if (  HasTG( wIO, nIO, c ) )
//			variable	TGChan	= iov( wIO, nIO, c, cIOTGCH ) 
//			sprintf bf, "\t\t\t\tTelegraphConnect() \tFound AD %d  with   \tTGChan %d.    \r",  Chan,  TGChan ; Out1( bf, bPrintIt )
			wG[ kCNTTG ]	+= 1											// Only telegraph channels which must be sampled are counted , MultiClamp TG channels are NOT counted
//		elseif (  HasTGMC( wIO, nIO, c ) )
//			variable	TGMCChan  = iov( wIO, nIO, c, cIOTGMCCH )
//			sprintf bf, "\t\t\t\tTelegraphConnect() \tFound AD %d  with   \tTGMCChan %d. \r",  Chan,  TGMCChan ; Out1( bf, bPrintIt )
//		else															// Found Adc  NOT controlled  any telegraph output : gain is fixed and set by user
//			//string 	sNm	= "Adc" + num2str( chan )
//  			//sprintf bf,  "\t\t\t\tTelegraphConnect() \tFound AD %d  without \tTGChan . \t\tUsing gain from script: %s  \r",  Chan,  ios( wIO, nm2NioC( sNm ),  cIOGAIN ) ; Out1( bf, bPrintIt )
		endif
	endfor

	sprintf  bf, "\t\t\t\tTelegraphConnect()     nCntAD:%2d  (%d)   nCntTG:%2d     \r",  wG[ kCNTAD ], cCnt, wG[ kCNTTG ]
	Out1( bf, bPrintIt )
End

Function		HasTG( wIO, nIO, c ) 
// Returns  TRUE = 1  or  FALSE = 0  depending on whether the Adc channel specified by linear index in script  'ioch'  is  telegraph controlled by AxoPatch 200 voltage signal
	wave  /T	wIO
	variable	nIO, c
	return   	numtype( iov( wIO, nIO, c, cIOTGCH ) )  !=  NUMTYPE_NAN  
End

Function		HasTGMC( wIO, nIO, c  ) 
// Returns  TRUE = 1  or  FALSE = 0  depending on whether the Adc channel specified by linear index in script  'ioch'  is  telegraph controlled by AxoPatch MultiClamp
	wave  /T	wIO
	variable	 nIO, c 
	return   	numtype( iov( wIO, nIO, c , cIOTGMCCH ) )  !=  NUMTYPE_NAN
End

Function		TGChan( wIO, nIO, c )
// returns telegraph channel number if linear index  'c'  has a corresponding telegraph channel, else 'NOTFOUND'
	wave  /T	wIO
	variable	nIO, c									// ioch is linear index in script     
	return	HasTG( wIO, nIO, c ) ? iov( wIO, nIO, c, cIOTGCH ) :  NOTFOUND
End

Function		TGMCChan( wIO, nIO, c )
// returns MC telegraph channel number if linear index  'c'  has a corresponding MC telegraph channel, else 'NOTFOUND'
	wave  /T	wIO
	variable	nIO, c									// ioch is linear index in script     
	return	HasTGMC( wIO, nIO, c ) ? iov( wIO, nIO, c, cIOTGMCCH ) :  NOTFOUND
End

Function	/S	TGMCChanS( wIO, nIO, c )
// returns MC telegraph 700AB-extended channel number if linear index  'c'  has a corresponding MC telegraph channel, else 'NOTFOUND'
	wave  /T	wIO
	variable	nIO, c									// ioch is linear index in script     
	// print "TGMCChanS( ioch )", ios( ioch, cIOTGMCCH )
	return	SelectString( HasTGMC( wIO, nIO, c ) , "",  ios( wIO, nIO, c, cIOTGMCCH ) )// returns complete string (must start with channel digit)  e.g.  1_700A_ Port_3_..  or   2_700B_SN_xyx
End

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

static Function		CheckPresenceOfRequiredSrcChans( wIO )
// Check if the 'Src' channels required by the computed channels are present
	wave  /T	wIO
	string 	sSrc, sOneSrc
	variable	n, nSrc
	variable	nIO, c, cCnt
	for ( nIO = kIO_PON; nIO < kIO_MAX; nIO += 1 )				// for all   Comp IO types  e.g. Pon, Sum, Aver
		cCnt	= ioUse( wIO, nIO )
		for ( c = 0; c < cCnt; c += 1 )
			sSrc	= ios( wIO, nIO, c, cIOSRC ) 					// e.g for Sum   'Adc0,Adc2' ,  for Aver  'Adc0'
			nSrc	= ItemsInList( sSrc, sPSEP )
			for ( n = 0; n < nSrc; n += 1 )
				sOneSrc		=   StringFromList( n, sSrc, sPSEP )
				//Assumption: Special script syntax for PoN sources implicitly assumes 'Adc' : e.g.  PoN:Src=0   but   Sum:Src=Adc0
				if ( cmpstr( "PoN", ioTNm( nIO ) )  == 0 )
					sOneSrc		= "Adc" + sOneSrc	// if it is 'PoN'  then supply the missing 'Adc' to complete the Src-channel specification
				endif
				if ( WhichListItem( sOneSrc, ioChanList( wIO ) ) == NOTFOUND )
		 			Alert( cFATAL,  "Source channel '" + sOneSrc + "' required by '" + ioTNm( nIO ) + "' not found. " )
					return	cERROR
				endif
			endfor
		endfor
	endfor
End


static Function		PrintIO( wIO, sText )
// Print all IO entries in history area in a compressed form to check IO processing results in intermediate  stages. Does not print defaults separately as ShowIO() does. 
	wave  /T	wIO
	string 	sText
	nvar		gRadDebgSel	= root:uf:dlg:gRadDebgSel
	nvar		PnDebgShowIO = root:uf:dlg:Debg:ShowIO
	variable	nData
	if ( gRadDebgSel  > 1 &&  PnDebgShowIO )	
		for ( nData = 0; nData	 < cIOLAST; nData += 1 )
			printf  "\t\t\t%s\tData:%2d\t%s\t", pad(sText,22),  nData, pd( StringFromList( nData, sALLIODATA ), 8 )
			variable	nIO, c, cCnt
			for ( nIO = 0; nIO < kIO_MAX; nIO += 1 )
				cCnt	= ioUse( wIO, nIO )
				for ( c = 0; c < cCnt; c += 1 )
					printf "%s\t", pad( wIO[ nIO ][ c ][ nData ], 8 )
				endfor
			endfor
			printf "\r"
		endfor
	endif
End

static Function		ShowIO( wIO )
// shows values of all used entries, skips unused entries, includes default values.
	wave  /T	wIO
	nvar		gRadDebgSel	= root:uf:dlg:gRadDebgSel
	nvar		PnDebgShowIO	= root:uf:dlg:Debg:ShowIO
	variable	ioch, nData 
	string 	bf, bfPart, sStrVal, sSK
	if ( gRadDebgSel  > 2 &&  PnDebgShowIO )	
		variable	nIO, c, cCnt
		for ( nIO = 0; nIO < kIO_MAX; nIO += 1 )	
			cCnt	= ioUse( wIO, nIO )
			for ( c = 0; c < cCnt; c += 1 )
	
				for ( nData  = 0; nData  < ItemsInList( sALLIODATA ); nData  += 1)// for all subkeys provided in sALLIODATA
	
					sSK		= StringFromList( nData, sALLIODATA )
					sStrVal	= ios( wIO, nIO, c, nData ) 
					if ( nData == 0 )
						 sprintf bfPart, "%s\tnIO:%d\t%d/%d\t%-6s", pd( ios( wIO, nIO, c, cIONM ),6), nIO, c, ioUse( wIO, nIO), pd( ioTNm( nIO ), 6)
					else
						 sprintf bfPart, "\t\t\t\t\t\t" 
					endif
					 printf  "\t\t\tShowIO() \t%s\t[ nI :%2d/%2d %s\t] = %s\tDf:\t%s\t%s\t \r", bfPart, nData, cIOLAST, pd(sSK,8), pd(sStrVal,16), pd( eaDef( ioTNm( nIO ) , sSK ) , 11), pd( ios( wIO, nIO, c, nData ),11 ) 
	
				endfor
			endfor
		endfor
	endif
End


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////	PROCESSING  SCRIPT ~ ' wLINES'
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

static Function		ShowKeys()
// prints mainkey and subkey data supplied by program in wMK and wSK
	nvar		gRadDebgSel		= root:uf:dlg:gRadDebgSel
	nvar		PnDebgShowKeys	= root:uf:dlg:Debg:ShowKeys
	variable	nMK, nSK, nSKs
	string	bf
	if ( gRadDebgSel > 1  &&  PnDebgShowKeys )	// we save time by skipping this function right here if it is turned off anyway
		for ( nMK = 0; nMK <MKCnt(); nMK += 1 )
			string	sSKs	= SKStr( nMK )
			printf  "\t\t\tShowKeys() \tnMK:%2d/%2d \tT:%2d  I:%2d \tNm:%12s\tSKs:%s \r", nMK, MKCnt(),  MkTyp( nMK ), MkMustOccurOnce( nMK ),  MkNm( nMK ), sSKs
			if ( gRadDebgSel > 2  &&  PnDebgShowKeys )	// we save time by skipping this function right here if it is turned off anyway
				nSKs = SKCnt( nMK )
				for ( nSK = 0; nSK < nSKs; nSK += 1 )
					printf  "\t\t\t\tShowKeys() \t\t\t\t\t\t\t\t\t\tnSK:%2d/%2d  %8s   \tDef:'%s' \r", nSK, nSKs, pd(SkNm( nMK, nSK ),8),  SkDef( nMK, nSK )
				endfor 	
			endif
		endfor 	
	endif
End

Function		ShowKeysForUser()
// prints mainkeys and subkeys  in a form to be read and understood by user
	variable	nMK, nSK, nSKs
	string 	sMkNm
	printf  "\r\tAllowed keywords in a script:  all  main keys  with their subkeys and default values "
	for ( nMK = 0; nMK <MKCnt(); nMK += 1 )
		printf  "\r\t\t%s :",  pad( MkNm( nMK ), 10 )
		nSKs = SKCnt( nMK )
		for ( nSK = 0; nSK < nSKs; nSK += 1 )
			// printf  "\t%s=%5s;", pad(SkNm( nMK, nSK ),7),  SkDef( nMK, nSK )	// empirically best adjustment but TGMCChan is truncated TGMCC
			printf  "\t%s=%5s;", pad(SkNm( nMK, nSK ),10),  SkDef( nMK, nSK )	// empirically best adjustment, does  not truncate 'TGMCChan' 
		endfor 	
	endfor 	
End

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
static Function 	CheckScriptSetSI( sFolder, wG )
// extract entries from script using  wMK  and  wSK  as template, complain about missing or unknown entries
// extensive script file error checking is possible
	string  	sFolder
	wave	wG
	string		sMK, sSubKey, sLine
	variable	nMK, l, n, nMatch
	
	// 1. Find missing mainkeys and multiple mainkey entries ( if forbidden )
	for ( nMK = 0; nMK < MKCnt(); nMK += 1 )				//  LOOP THROUGH ALL MAINKEYS supplied by programm...
		sMK =  MkNm( nMK )						
		nMatch = 0
		for ( l = 0; l < nLines( sFolder ); l += 1)						// Loop through all script lines, get mainkey from script line...
			sLine = GetScrLine( sFolder, l )						// ..compare it against above mainkey from  sMK
			if ( cmpstr( sMK, StringFromList( 0, sLine, sMAINKEYSEP ) ) == 0 )
				nMatch += 1							// count number of occurrences of this main key in script
			endif
		endfor
		if ( CheckNrOfIntendedMKOccur( nMatch, nMK ) )	// compare count against  intended number of...
			return cERROR
		endif										// .. occurrences for this main key ( none, once, multiple )
	endfor			
	
	// 2. Find unknown mainkeys
	for ( l = 0; l < nLines( sFolder ); l += 1)							// LOOP THROUGH ALL SCRIPT LINES  and get...
		sLine = GetScrLine( sFolder, l )							//...mainkey from script line..
		sMK = StringFromList( 0, sLine, sMAINKEYSEP )	// ...and compare it against entries
 		if ( CheckUnknownMainkeys( sMK ) )				// ...in 'sMainKey'   supplied by  program
 			return	cERROR
 		endif
 	endfor

	// 3. Mainkeys should be OK by now so proceed by checking the subkeys
	for ( l = 0; l < nLines( sFolder ); l += 1)							// LOOP THROUGH ALL SCRIPT LINES  and get...
		sLine = GetScrLine( sFolder, l )					
		if ( CheckUnknownSubkeys( sLine ) )				// Find and complain about unknown subkeys
			return	cERROR
 		endif
 	endfor 

	// 4. Check that all smpInt are equal
	variable	rnSmpIntMin	= Inf
	variable	rnSmpIntMax	= -Inf
	for ( l = 0; l < nLines( sFolder ); l += 1)							// LOOP THROUGH ALL SCRIPT LINES  and get...
		sLine = GetScrLine( sFolder, l )					
		CheckSmpIntsAreEqual( sLine, rnSmpIntMin, rnSmpIntMax )	// Find and complain about  differing  sample intervals
 	endfor 
	if ( rnSmpIntMin == rnSmpIntMax )
		wG[ kSI ]	= rnSmpIntMin
	else
		Alert( cFATAL, "All sample intervals must be equal. Found '" + num2str( rnSmpIntMin ) + "' and '" + num2str( rnSmpIntMax ) + "'" )
		return	cERROR
	endif

 	return 0
 End
 

static	Function	CheckNrOfIntendedMKOccur( nMatch, nMK ) 
	variable	nMatch, nMK
	// printf "\t\t\tCheckIntendedOccur():  mainkey '%s' found %d times \r", ioTNm( nIO ), nMatch 
	if ( nMatch != 1 &&  MKMustOccurOnce( nMK ) )
		Alert( cFATAL,  "Mainkey  '" +  MKNm( nMK ) + "'  must occur exactly once, found " + num2str( nMatch ) + " times." )
		return cERROR
	endif
	return 0
End

static Function	CheckUnknownMainkeys( sMK )
	string	 	sMK
	if ( mI( sMK ) != NOTFOUND )		
		// print "CheckUnknownMainkeys", sMK,  mI( sMK )
		return 0	
	else
		Alert( cFATAL,  "Could not interpret  main key  '"+ sMK + "'" )
		return cERROR
	endif
End

static Function CheckUnknownSubkeys( sLine )
	// loop  for given mainkey  through all subkeys provided in this script line 
	string 	sLine
	string 	sMK			= StringFromList( 0, sLine, sMAINKEYSEP )	// ...mainkey from script line
	string 	sSubKeys	= StringFromList( 1, sLine, sMAINKEYSEP )	// ...all the subkeys and values from script line
	variable	nS,nScriptSKs	= ItemsInList( sSubKeys, sLISTSEP )
	for ( nS = 0; nS < nScriptSKs; nS += 1 )
		string 	sScriptSKInfo	=  StringFromList( nS, sSubKeys, sLISTSEP )
		string 	sScriptSK	=  StringFromList( 0, sScriptSKInfo, sVALSEP )
		string 	sScriptSKData=  StringFromList( 1, sScriptSKInfo, sVALSEP )
		// printf "\t\tCheckUnknownSubkeys()  %8s   \t%2d/%2d  AccTyp:%1d   %8s \t'%s' \t\t\t\t%s \r", sMK, nS,nScriptSKs, skTyp( mI( sMK ), skIdx( sMK, sScriptSK ) ) , sScriptSK, sScriptSKData, SelectString( nS == 0, "", SKList( sMK, ";" ) )
		if ( WhichListItem( sScriptSk, SKList( sMK, ";" ), ";" ) == NOTFOUND  )
			Alert( cFATAL,  "Could not interpret  subkey '" + sScriptSKInfo + "' in line '" + sLine + "'" )

			if ( cmpstr( sScriptSKInfo[ 0, 4 ] , "YAxis" ) == 0 )			// as this used to be a valid keyword : just ignore it now and give the user a hint to remove it, but continue processing
				//Alert( cFATAL,  "From V2.24 on there is a change in script keyword and behaviour :\r\tReplace in your script all occurences of \r\t'YAxis = value'  by  'YZoom =  10000 / value'  " )
				Alert( cFATAL,  "From V2.24 the keyword 'YAxis' is obsolete and should be removed.\r\tYou can now store different YZoom values for each trace :\r\t'Preferences'  'Trace / window control bar'  , set Zoom\r\tthen  'Acquis window options'  'Save  display config'  " )
			elseif	 ( cmpstr( sScriptSKInfo[ 0, 4 ] , "YZoom" ) == 0 )		//as this used to be a valid keyword : just ignore it now and give the user a hint to remove it, but continue processing
				Alert( cFATAL,  "From V2.30 the keyword 'YZoom' is obsolete and should be removed.\r\tYou can now store different YZoom values for each trace :\r\t'Preferences'  'Trace / window control bar'  , set Zoom\r\tthen  'Acquis window options'  'Save  display config'  " )
			else
				return cERROR								// this was a typographical error or some other nonsense : do NOT let the user continue
			endif
		endif
	endfor
	return 0	
End

static Function CheckSmpIntsAreEqual( sLine, rnSmpIntMin, rnSmpIntMax )
// loop  for given mainkey  through all subkeys provided in this script line 
// check SmpInt for 'Adc' and 'Dac'   ('PoN'  has no user access to SmpInt -> SmpInt is missing in script -> value must be supplied ) 	
	string	  	sLine
	variable	&rnSmpIntMin, &rnSmpIntMax
	string  	sMK			= StringFromList( 0, sLine, sMAINKEYSEP )	// ...mainkey from script line
	string  	sSubKeys	= StringFromList( 1, sLine, sMAINKEYSEP )	// ...all the subkeys and values from script line
	variable	nS,nScriptSKs	= ItemsInList( sSubKeys, sLISTSEP )
	for ( nS = 0; nS < nScriptSKs; nS += 1 )
		string	 	sScriptSKInfo	=  StringFromList( nS, sSubKeys, sLISTSEP )
		string 	sScriptSK	=  StringFromList( 0, sScriptSKInfo, sVALSEP )
		string	 	sScriptSKData=  StringFromList( 1, sScriptSKInfo, sVALSEP )
		if ( cmpstr( sScriptSK, "SmpInt" ) == 0 )
			rnSmpIntMin	= min( rnSmpIntMin,  str2num( sScriptSKData ) )
			rnSmpIntMax	= max( rnSmpIntMax, str2num( sScriptSKData ) )
			// printf "\t\tCheckSmpIntsAreEqual()  %8s   \t%2d/%2d  %8s \t'%s'   min:%g  max:%g \r", sMK, nS,nScriptSKs, sScriptSK, sScriptSKData, rnSmpIntMin, rnSmpIntMax
		endif
	endfor
	return 0	
End

static Function	ShowLines( sFolder, sText )
	string 	sFolder, sText
	nvar		PnDebgShowLines = root:uf:dlg:Debg:ShowLines
	if ( PnDebgShowLines )	// we save (a little bit of) time by skipping this function right here if it is turned off anyway
		variable	l, LineCnt = nLines( sFolder )
		string	bf
		for ( l = 0; l < LineCnt; l += 1)
			string 	sLine	= GetScrLine( sFolder, l )
		//gn	string	sSepLine= SelectString( l==0 ||  !cmpstr( "Frames", StringFromList( 0, sLine, sMAINKEYSEP ) ) , "", "\r" )
		//gn	sprintf bf, "\t\t\tShowLines( %s ) %s", sText, sSepLine; Out( bf )
			sprintf bf, "\t\t\tShowLines( %s )  line:%d/%2d \t'%s' \r", sText,  l, LineCnt, sLine; Out( bf )
		endfor	
	endif	
End

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

static  constant	cINFRAME	= 1, cINSWEEP = 2

static Function	ExpectComplain( sExpectKey, sComplainKeys, nLine, sLine )
	string 	sExpectKey, sComplainKeys, sLine
	variable	nLine
	variable	k
	for ( k = 0; k < ItemsInList( sComplainKeys ); k += 1 )
		if ( cmpstr(  StringFromList( k, sComplainKeys ), StringFromList( 0, sLine, sMAINKEYSEP ) ) == 0 )
			Alert( cFATAL,  "Expecting keyword  '" + sExpectKey + "'  in line " + num2str( nLine ) + " : " + sLine )
			return cERROR
		endif
	endfor
	return	0
End 

static Function	Check_Frm_Swp_EndSwp_EndFrm( sFolder )
// Checks that Frame / Sweep / EndSweep / EndFrame keywords are correctly nested.
// Does not check and does not complain about other lines occuring at wrong places..
// .. e.g 'Segment' between Blocks or between Frames and Sweeps. This is checked later in PossiblyInsertIntervals()
	string  	sFolder
	variable	l, depth = 0 , bMovingIn = TRUE,	nPreliminaryBlocks = 0
	variable	LineCnt = nLines( sFolder )
	string  	sLine
	// make sure that  'EndSweep'  line exists
	for ( l = 0; l < LineCnt; l += 1)
		sLine	= GetScrLine( sFolder, l )
		//print "Check_Frm_Swp_EndSwp_EndFrm()",bMovingIn, l, depth, sLine
		if ( depth == 0 )
			if ( cmpstr( "Frames", StringFromList( 0, sLine , sMAINKEYSEP ) ) == 0 )
				depth	+= 1
				nPreliminaryBlocks += 1
				continue
			elseif ( ExpectComplain( "Frames", "Sweeps;EndSweep;EndFrame", l, sLine ) )
				return	cERROR
			endif
		endif
		if ( depth == cINFRAME  &&  bMovingIn )
			if ( cmpstr( "Sweeps", StringFromList( 0, sLine, sMAINKEYSEP ) ) == 0 )
				depth	+= 1
				bMovingIn = TRUE
				continue
			elseif ( ExpectComplain( "Sweeps", "Frames;EndSweep;EndFrame", l, sLine ) )
				return	cERROR
			endif
		endif
		if ( depth == cINFRAME  &&  ! bMovingIn )
			if ( cmpstr( "EndFrame", StringFromList( 0, sLine, sMAINKEYSEP ) ) == 0 )
				depth	-= 1
				bMovingIn = TRUE
				continue
			elseif ( ExpectComplain( "EndFrame", "Frames;Sweeps;EndSweep", l, sLine ) )
				return	cERROR
			endif
		endif
		if ( depth == cINSWEEP )
			if ( cmpstr( "EndSweep", StringFromList( 0, GetScrLine( sFolder, l ), sMAINKEYSEP ) ) == 0 )
				depth	-= 1
				bMovingIn = FALSE
				continue
			elseif ( ExpectComplain( "EndSweep", "Frames;Sweeps;EndFrame", l, sLine ) )
				return	cERROR
			endif
		endif
	endfor
	// Check the last lines
	if ( depth == cINSWEEP )
		Alert( cFATAL,  "Expecting terminating 'EndSweep'  and 'EndFrame'  lines following : " + sLine )
		return cERROR
	endif
	if ( depth == cINFRAME )
		Alert( cFATAL,  "Expecting keyword 'EndFrame'  after line " + num2str( l ) + " : " + sLine )
		return cERROR
	endif
	return	nPreliminaryBlocks
End


static Function	ExpandLines( sFolder, sLoopBegKey, sLoopEndKey )
// Step 1: read lines (again), expand 'Loop' - 'EndLoop' 
	string  	sFolder, sLoopBegKey,  sLoopEndKey
	nvar		gRadDebgSel	= root:uf:dlg:gRadDebgSel
	nvar		PnDebgExpand = root:uf:dlg:Debg:Expand
	variable	l, LineCnt = nLines( sFolder ), LinesExpanded = 0, nLoops = 1
	string  	sLine, bf

	// Pass1: Get number of additional lines for loop expansion
	for ( l = 0; l < LineCnt; l += 1)
		sLine = GetScrLine( sFolder, l )		
		if ( gRadDebgSel > 2  &&  PnDebgExpand )
			printf  "\t\t\t\tExpandLines()  original \t\t\tline:%2d/%2d \t'%s' \r", l, LineCnt, sLine
		endif
		if ( cmpstr( StringFromList( 0, sLine, sMAINKEYSEP ), sLoopBegKey ) == 0 )
			nLoops = GetScrValS( sFolder, sLine, "N" )				// we have found a loop, so we must add..
			LinesExpanded -= nLoops  // don´t count = remove 
		endif											// ..the following line multiple times...
		if ( cmpstr( StringFromList( 0, sLine, sMAINKEYSEP ), sLoopEndKey ) == 0 )
			nLoops  = 1									// ..until we leave the loop....
			LinesExpanded -= nLoops  // don´t count = remove 
		endif											// ..from then on each line  stays one line
		LinesExpanded += nLoops 
	endfor	
	if ( gRadDebgSel > 1  &&  PnDebgExpand )
		printf "\t\t\tExpandLines()  expanded loops. Old line cnt:%2d increased to %2d  \r", LineCnt, LinesExpanded
	endif

	// Supply a (bigger) temporary text wave to hold the loop expanded lines
	make /O /T /N=(LinesExpanded) 	twLinesExpanded
	make /O /T /N=(LinesExpanded) 	twOneLoop
	
	// Pass2: Expand  the  loops  into  the  temporary text wave 
	variable	ee = 0, lp = 0, nll = 0, nLinesInLoop = 0, bInLoop = FALSE
	for ( l = 0; l < LineCnt; l += 1)
		sLine = GetScrLine( sFolder, l )		

		if ( cmpstr( StringFromList( 0, sLine, sMAINKEYSEP ), sLoopBegKey ) == 0 )
 			// printf "\t\t\t\t\tLoop starts  l=%2d  ee=%2d   Loop \r", l, ee				
			bInLoop = TRUE
			nLoops = GetScrValS( sFolder, sLine, "N" )				// we have found a loop, so we extract the loop cnt
			nLinesInLoop	= 0
		endif											
		if ( cmpstr( StringFromList( 0, sLine, sMAINKEYSEP ), sLoopEndKey ) == 0 )
			// printf "\t\t\t\t\tLoop ends   l=%2d  ee=%2d -> Copy just after leaving the loop... \r", l, ee				
			for ( lp = 0; lp < nLoops; lp += 1 )
				for ( nll =1; nll < nLinesInLoop; nll += 1 )		// start at 1 to skip 'Loop:'  line
					twLinesExpanded[ ee ] = twOneLoop[ nll ]
					// printf "\t\t\t\t\t\tcopied LinExp[ ee:%d ]  <- twOneLoop[ nll:%d ]  :'%s' \r", ee, nll, twLinesExpanded[ ee ]
					ee += 1
				endfor
			endfor
			l += 1										//  skip 'EndLoop' line
			bInLoop = FALSE
			nLoops  = 1								
		endif											//
		if ( bInLoop )
			// still within loop: collect all lines between Loop and EndLoop and save temporarily
			// printf "\t\t\t\t\t  l=%2d  ee=%2d   Collecting within loop. bInLoop=1 \t'%s' \r", l, ee, sLine	
			twOneLoop[ nLinesInLoop ] =  sLine
			nLinesInLoop += 1
		else
			// bInLoop == 0: normal mode without any Loop/EndLoop: copy directly without tmp 
			// printf "\t\t\t\t\t  l=%2d  ee=%2d   Normal mode...Not InLoop,  =0 \t'%s' \r", l, ee, sLine				
			twLinesExpanded[ ee ] = GetScrLine( sFolder, l ) 		// access via l because sLine may have been 'EndLoop' which has been skipped
			ee += 1
		endif
	endfor
		
	// Copy   the  loop expanded temporary text wave into  the  original wave
//	duplicate /O 	twLinesExpanded	wLines
	duplicate /O 	twLinesExpanded	$"root:uf:" + sFolder + ":keep:wLines"
	killwaves		twLinesExpanded	twOneLoop
End

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

static Function	GetNumberOfDacChannels( sFolder )
// scans ' wLines'  to get count of the 'Dac' keywords. Todo: complain about doublettes
	string  	sFolder
	variable	l, 	DacChs	= 0			// the number of DacChans in script, used in conjunction with wFix
	for ( l = 0; l < nLines( sFolder ); l += 1)
		if ( cmpstr( StringFromList( 0, GetScrLine( sFolder, l ), sMAINKEYSEP ), "Dac" ) == 0 )// does Line contain the first expected key ?
			DacChs += 1
		endif												
	endfor
	return	DacChs
End


static Function	ExtractFixSweepData( sFolder, wG )
// assumes and relies on a syntactically correct Frames/Sweeps structure in the script (must be expanded and checked first...)
	string		sFolder								// subfolder of root (root:'sF':...) used to discriminate between multiple instances of the InterpretScript()  e.g. from FPulse and from FEval
	wave	wG
	// Step 1 : count blocks
	variable	l, b = 0
	for ( l = 0; l < nLines( sFolder ); l += 1)
		if ( cmpstr( StringFromList( 0, GetScrLine( sFolder, l ), sMAINKEYSEP ), "Frames" ) == 0 )// does Line contain the first expected key ?
			b += 1
		endif												
	endfor
	// Step 2 : construct  wave to hold the number of frames and sweeps in every block , index 0 holds frame cnt, index 1 holds swp cnt
	//printf "\t\tExtractFrmAndSwpForEachBlock(1) \tnBlk:%d \t    \r", nBlk
	make /O /N = ( b +1 , cMAXFrmSwpPon )	$"root:uf:" + sFolder + ":ar:wFix"	= 0	// one more (=the last index) is provided to hold the maximum value 
	wave  	wFix					 = 	$"root:uf:" + sFolder + ":ar:wFix"  			// There are 2  instances of  'wELine' :  in FPulse  in folder  'Acq'   and in FEval  in folder  'eval' 
	// Step 3 : extract the number of frames and sweeps from every block , index 0 holds frame cnt, index 1 holds swp cnt
	b	= -1	
	variable	maxFrm	= 0, maxSwp	= 0
	for ( l = 0; l < nLines( sFolder ); l += 1 )												// loop through all ' wLines' 
		if ( cmpstr( StringFromList( 0, GetScrLine( sFolder, l ), sMAINKEYSEP ), "Frames" ) == 0 )		// does Line start with 'Frames' ?
			b += 1
			wFix[ b ][ cFRM ]	= GetScrValDef( sFolder, l, "N" )						// store frame count ( to avoid erroneous program behavior...
			maxFrm	= max( wFix[ b ][ cFRM ], maxFrm ) 					// ..in case of missing values we supply defaults already here)
		endif												
		if ( cmpstr( StringFromList( 0, GetScrLine( sFolder, l ), sMAINKEYSEP ), "Sweeps" ) == 0 )		// does Line start with 'Sweeps' ?
			wFix[ b ][ cSWP ]	= GetScrValDef( sFolder, l, "N" )						// store sweep count
			wFix[ b ][ cPON ]	= GetScrValDef( sFolder, l, "PoN" )						// store 1 or 0 (user wants PoN or not)
			wFix[ b ][ cCORA ]= GetScrVal( sFolder, l, "CorrAmp" )						// if missing keep NaN to be corrected later
			maxSwp	= max( eSweeps( wFix, b ), maxSwp ) 
			// Assumption: the first line after the first 'Sweeps' keyword defines the main Dac (may not be the 1. in the IO section) on which all other Dacs depend
			if ( b == 0 )
				variable	nMainDac	= GetScrValDef( sFolder, l + 1, "Dac" )
				//printf "\t\t\tExtractFrmAndSwpForEachBlock() \tMainDac:%d  \r", nMainDac
			endif
			 //printf "\t\t\tExtractFrmAndSwpForEachBlock() \twFix[ nBlk:%d ][ Frames ] = %d  \t...[ Sweeps ]:%g \t...[ Pon ]:%g  \t...[ CorrAmp ]:%g \r",  b, eFrames( b ), eSweeps( wFix, b ), ePoN( wFix, b ), eCorrAmp( wFix, b )
		endif												
	endfor
	b += 1
	wFix[ b ][ cFRM ]		= maxFrm									// store the maximum frame count in the last array position
	wFix[ b ][ cSWP ]		= maxSwp									// store the maximum sweep count in the last array position
	wG[ kBLOCKS ] 	= b
	return	nMainDac
End


static Function	PossiblyInsertIntervals( sFolder, MainDac ) 
// we supply a 'Blank' line   (=InterBlockInterval)	with zero duration ans zero ampitude between the blocks if the script does...
// we supply a 'Blank' line  (=InterFrameInterval)	with zero duration ans zero ampitude between the frames if the script does...
// ..not yet contain this line  as the following functions can be greatly simplified  if  there is always an InterBlockInterval and an InterFrmInterval
//!  THIS  FUNCTION  DETERMINES  THE  ORDER  OF  THE  ENTRIES  IN  THE  SCRIPT  OR  DEPENDS ON  IT
	string  	sFolder
	variable	MainDac
	string		sInsertLine	= "Blank:Dac=" + num2str( MainDac ) + ",0;Amp=0"
	if ( PossiblyInsertBetween( sFolder,  "EndSweep" , "EndFrame" , sInsertLine ) ) 
		return	cERROR
	endif
	if ( PossiblyInsertBetween( sFolder,  "EndFrame" , "Frames" , sInsertLine ) )
		return	cERROR
	endif
End

static Function	PossiblyInsertBetween( sFolder, sThisKey, sKeyInNextLine, sInsertLine )
// 030324c  insert IBI  also after the last block. This simplifies (and corrected) the stimulus generation
// Flaw: no error checking ( 2 Blank lines or wrong keyword is not flagged as error), ' sKeyInNextLine' is ignored
	string		sFolder, sThisKey, sKeyInNextLine, sInsertLine
	variable	l, LineCnt = nLines( sFolder )
	for ( l = 0; l < LineCnt; l += 1)
		string		sLine	= GetScrLine( sFolder, l )
		if ( cmpstr( sThisKey, StringFromList( 0, sLine, sMAINKEYSEP ) ) == 0 )	
			string		sNextLine	= GetScrLine( sFolder, l + 1 )
			//printf "\t\tPossiblyInsertInterval()  reading '%s' , looking for following 'Blank'  line, found '%s'  \r  ",  sLine, sNextLine
			if ( cmpstr( "Blank" , StringFromList( 0, sNextLine, sMAINKEYSEP ) ) )					// keyword in next line is NOT 'Blank' ..(could be 'EndFrame or Frames'  or  wrong key  or  last line)
				//printf "\t\t\tPossiblyInsertInterval()  inserting  '%s'  between  '%s'  and  '%s'  [%s]\r", sInsertLine, sLine, sNextLine,StringFromList( 0, sNextLine, sMAINKEYSEP ) 
				l  += 1															// .. so we insert the blank line 
				LineCnt += 1
				InsertLines( sFolder, l, 1,   sInsertLine )
			endif
		endif
	endfor
	return	0
End


static Function	CheckCombinationPoNSweeps( sFolder, wG, wFix )
	string  	sFolder
	wave	wG, wFix
	variable	bFoundPoN	= FALSE, code = 0
	variable	l,   LineCnt	= nLines( sFolder )

	// check whether  'PoN'  line exists in IO section
	for ( l = 0; l < LineCnt; l += 1)
		if ( cmpstr( "PoN", StringFromList( 0, GetScrLine( sFolder, l ), sMAINKEYSEP ) ) == 0 )
			bFoundPoN = TRUE
			break;	//  'PoN' line does exist  (in line l < LineCnt)
		endif
	endfor
	//printf "\t\tCheckCombinationPoNSweeps()  did %s  find 'PoN' line in IO section. \r", SelectString( bFoundPoN, "not", "" ) 
	variable	b, bFoundPoNInStimPart = 0
	for ( b = 0; b < eBlocks( wG ); b += 1 )
		if ( ePoN( wFix, b ) )
			bFoundPoNInStimPart  += 1
			if ( eSweeps( wFix, b ) == 1 )
				Alert( cFATAL,  "P over N  correction requested which cannot be executed because number of sweeps = 1. " )
				code	= cERROR
			endif
		endif
	endfor
	if ( bFoundPoN  &&  ! bFoundPoNInStimPart )
		Alert( cLESSIMPORTANT,  "P over N  display  requested but no PoN correction specified in stimulus part. " )
	endif
	return	code
End

static Function	AdjustMissingCorrAmp( wG, wFix )
	wave	wG, wFix
	variable	code	= 0
	variable	b, Sweeps
	for ( b = 0; b < eBlocks( wG ); b += 1 )
		variable	CorrAmp, CorrAmpScr	= eCorrAmp( wFix, b )
		if ( numType( CorrAmpScr ) == NUMTYPE_NAN )		// CorrAmp is missing in script
			CorrAmp	= eSweeps( wFix, b ) > 1 ? 1 / ( eSweeps( wFix, b ) - 1 ) : 1 
			eCorrAmpSet( wFix, b, CorrAmp ) 
		endif
		//printf "\t\tAdjustMissingCorrAmp()  b:%2d/%2d \tSweeps:%d \tPoN:%d \tCorrAmp:%6.3g \t-> %6.3g \r", b, eBlocks( wG ), eSweeps( wFix, b ), ePoN( wFix, b ), CorrAmpScr, eCorrAmp( wFix, b )
	endfor
	return	code
End


constant	MAXDACS = 8

static Function	SetNumberOfElemsInSweeps( sFolder, wG ) 
// scans ' wLines'  to get count of  the lines of each sweep 
// extract the dac channel declarations from the IO part of the script and check against dac channels actually used in STIM part of the script, report inconsistencies  
// this extraction of  Dac channel information is preliminary  and  is done again more extensively  in .....????? ExtractIO() 
	string  	sFolder
	wave	wG
	variable	b, l, c, nElement, nMaxElems = 0, nChans 
	string		sLine, sDacChanList = "", sDacChanListInStim = ""
	variable	nIODacChan, nStimDacChan	

	// Step 1: Build list of Dac channel numbers from Dacs declared in the IO section 	
	for ( l = 0; l < nLines( sFolder ); l += 1)
		nIODacChan		= GetDacChannelFromIO( sFolder, l )
		if ( WhichListItem( num2str( nIODacChan ), sDacChanList ) != NOTFOUND )
			Alert( cFATAL,  "Dac channel " + num2str( nIODacChan ) + " declared multiple times." )
		endif 
		if ( nIODacChan < NOTFOUND )
			Alert( cFATAL,  "Illegal Dac channel " + num2str( nIODacChan ) + " in IO section." )
		endif
		if ( nIODacChan != NOTFOUND )									// skip non-'Dac'-lines
			sDacChanList	= AddListItem( num2str( nIODacChan ), sDacChanList,  ";" , Inf )
		endif
	endfor
	nChans =  ItemsInList( sDacChanList ) 
	
	// Step 2:  Build list of Dac channel numbers from Dacs used in the Stimulus IO section 
	for ( l = 0; l < nLines( sFolder ); l += 1 )														// loop through all ' wLines'
		nStimDacChan	= GetDacChannelFromStim( sFolder, l )						
		if ( nStimDacChan < NOTFOUND )
			Alert( cFATAL,  "***Illegal Dac channel " + num2str( nStimDacChan ) + " in STIM section." )
		endif
		if ( nStimDacChan != NOTFOUND )
			sDacChanListInStim = AddListItem( num2str( nStimDacChan ), sDacChanListInStim,  ";" , Inf )
		endif
	endfor
	// printf "\t\t\tSetNumber2..( f:%d, s:%d )  nChans:%d  sDacChanList:'%s'   sDacChanListInStim:'%s' \r",  nFrames, nSweeps, nChans, sDacChanList, sDacChanListInStim	

	// Step 3:   Check Dac channel  inconsistencies between  IO  and STIM  part of script   and  report errors
	string 	sStimTmp = sDacChanListInStim 
	for ( c = 0; c < nChans; c += 1 )	
		sStimTmp = RemoveFromList( StringFromList( c, sDacChanList ), sStimTmp )
	endfor
	if ( strlen( sStimTmp ) )	
		Alert( cFATAL,  "Dac channel(s) " + sStimTmp[ 0, strlen( sStimTmp ) - 2 ] + " used but not declared in IO section." )
		return	cERROR
	endif
	sStimTmp = sDacChanList 
	for ( c = 0; c < ItemsInList( sDacChanListInStim ); c += 1 )	
		sStimTmp = RemoveFromList( StringFromList( c, sDacChanListInStim ), sStimTmp )
	endfor
	if ( strlen( sStimTmp ) )	
		// Warning is not enough: must be an error because WaveStats in DisplayStimulus() will fail with an empty wave...
		//  (to do: catch error when wave is possibly empty (segment duration =0)  or catch error around wavestats
		Alert( cFATAL,   "Dac channel(s) " + sStimTmp[ 0, strlen( sStimTmp ) - 2 ] + "  declared in IO section but not used in any segment. " )
		return	cERROR
	endif


	// Step 4:  loop through all script lines taking into account  the frame structure given by 'Sweep-EndSweep' and...  
	// 		search the maximum number of elements occuring in any combination of  all frames and all dac channels detected
	variable	nBlk	= eBlocks( wG )
	make /O /N = ( MAXDACS, nBlk ) 	$"root:uf:" + sFolder + ":ar:wEinCB"	= 0	// wElements_In_Chans_And_Blocks : less channels might be sufficient ?...
	wave	wEinCB    			   = 	$"root:uf:" + sFolder + ":ar:wEinCB"
	b = 0
	for ( l = 0; l < nLines( sFolder ); l += 1 )
		if ( cmpstr( StringFromList( 0, GetScrLine( sFolder, l - 2 ), sMAINKEYSEP ), "EndFrame" ) == 0 )		// the IBI after EndFrame still belongs to the last block
			//printf "\t\tSetNumber4   OfElemsInSweeps1 nMaxElems:%d [sDacChs:%s]  \t\t\t\t\t\t\treading \tLine %2d :'%s' \r", nMaxElems, sDacChanList, l, GetScrLine( l ) 
			b	+= 1
		endif
		nStimDacChan	= GetDacChannelFromStim( sFolder, l )						
		if ( nStimDacChan != NOTFOUND )
			c = WhichListItem( num2str( nStimDacChan ), sDacChanList )
			wEinCB[ c ][ b ]	+= 1
			nMaxElems = max( wEinCB[ c ][ b ], nMaxElems )
			//printf "\t\t\tSetNumber4a \tnStimDacChan:%2d~c:%d  \tnwEinCB[ c:%d ][ b:%d ]:%2d /%2d   \tLine %2d    \t:'%s' \r", nStimDacChan, c, c, b, wEinCB[ c ][ b ], nMaxElems, l, GetScrLine( l )
		endif
	endfor

	// Step 5 : convert the number of elements per dac channel and frame from temporary storage into permanent wave 'wEinCB'
	//		store line number for  every   frame / channel / element   combination
	wEinCB = 	0			// 1 is for IBI waveform arithmetic
	make  /O /N = ( nChans, nBlk, nMaxElems )   $"root:uf:" + sFolder + ":ar:wELine" 	// stores original wVal line number for given frame and element
	wave  	wELine	 				= $"root:uf:" + sFolder + ":ar:wELine"  	// There are 2  instances of  'wELine' :  in FPulse  in folder  'Acq'   and in FEval  in folder  'eval' 
	b = 0
	//printf "\t\tSetNumber5a. OfElemsInSweeps1  nMaxElems:%d [sDacChs:%s] \r", nMaxElems, sDacChanList 
	for ( l = 0; l < nLines( sFolder ); l += 1 )												// loop through all ' wLines'
		if ( cmpstr( StringFromList( 0, GetScrLine( sFolder, l - 2 ), sMAINKEYSEP ), "EndFrame" ) == 0 )	// the IBI after EndFrame still belongs to the last block
			//rintf "\t\t\tSetNumber5c. blk:%d  \tl:%2d/%2d  \tnStimDacChan:%2d~c:%d  \tCurrElemCnt:%d  \tnMaxElems:%d  \tLine:'%s' \r", b, l, wELine[ c ][ b ][ nElement ], nStimDacChan, c, wEinCB[ c ][ b ], nMaxElems, GetScrLine( l )
			b += 1
		endif 
		nStimDacChan	= GetDacChannelFromStim( sFolder, l )			//??????????????			
		if ( nStimDacChan != NOTFOUND )
			c = WhichListItem( num2str( nStimDacChan ), sDacChanList )
			nElement	=  wEinCB[ c ][ b ] 
			wELine[ c ][ b ][   nElement   ] = l							// store the line number
			wEinCB[ c ][ b ] += 1
			//printf "\t\t\tSetNumber5b \tnStimDacChan:%2d~c:%d  \tnwEinCB[ c:%d ][ b:%d ]:%2d /%2d   \tLine %2d /%2d\t:'%s' \r", nStimDacChan, c, c, b, wEinCB[ c ][ b ], nMaxElems,  wELine[ c ][ b ][ nElement ], l, GetScrLine( l )
		endif
	endfor

	return 	nMaxElems 
End


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//   NEXT  STAGE  : Advance from wLines to  wVal  
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

static strconstant	sFRAMESEP	= "|"		// separates entries for consecutive frames in script

//Function	/S	MakeStimElementList()
//// builds string list containing those elements whose 2. entry in mainkey wMK is ISSTIM (=4),  e.g. "VarSegm,Segment,Ramp,StimWave,Blank,Expo"
//	string  	sStimElements = ""
//	variable	n
//	for ( n = 0; n < MKCnt(); n += 1)
//		if ( MKIsStim( n ) )
//			sStimElements = AddListItem( MKNm( n ), sStimElements, ",", Inf )						// Inf appends at the end
//		endif
//	endfor
//	return	sStimElements
//End


static Function	ExtractLinesIntoVal( sFolder, wVal, nFrm  )
// Step 2: read lines (again), get all values
	string  	sFolder
	wave	/T	wVal
	variable	nFrm
	variable	l, nMK, code = 0
	string		bf 

	for ( l = 0; l < nLines( sFolder ); l += 1)
		string	 sLine = GetScrLine( sFolder, l )
		nMK		= mI( StringFromList( 0, sLine, sMAINKEYSEP ) )
MarkPerfTestTime 200	// ExtractLinesIntoVal: mI
		// printf "\t\t\tExtractLinesIntoVal()  found in line %2d  nMk:%d  '%s' \r", l, nMK, mS( nMK )
		code += ExtractValue( wVal, nMk, sLine, l, nFrm )					// allow collection of multiple errors
MarkPerfTestTime 203	// ExtractLinesIntoVal: ExtractValue
	endfor	

	sprintf bf, "\t\tExtractLines( nFrm:%d  ) extracted %d lines into wVal \r",  nFrm,  l ; Out( bf )
	// code = code ? cERROR : 0									// return cERROR, no matter how many errors occured	
	return code												// anything != 0 is an error
End


static Function	ExtractValue( wVal, nType, sPulsLine, nEle, nFrm )
// Step 2a: read one line, break into subkeys and sort into fields of ' wVal'
// extract values (and strings) from one line, the values can be unsorted and/or  missing 
// an error free script is assumed -> error checking must have been done already ( CheckScriptSetSI() )
	wave	/T	wVal
	variable 	nType,	nEle, nFrm
	string		sPulsLine
	variable	f, n, k
	variable	nIO, c
MarkPerfTestTime 300	// ExtractValue: Begin
	string		sMainKey = StringFromList( 0, sPulsLine, sMAINKEYSEP )
	// printf "\t\t\t\tExtractValue( nType:%d, nEle:%d, nEle:%d, '%s' )   sMainKey:'%s' \r",  nType, nEle, nFrm, sPulsLine, sMainKey
	sPulsLine = RemoveListItem( 0, sPulsLine, sMAINKEYSEP )		// remove main key and colon, leave sub keys

	string		snType	= num2str( nType )
	for ( f = 0; f < nFrm; f += 1)
		// save the extracted mainkey  type as first item (=[0]) before subkey values
		vS( wVal,nEle,  0,  f, snType )				
	endfor
MarkPerfTestTime 306	// ExtractValue: Loop Frames vS

	// now all errors should have been removed, so every Nan (or string) error means that subkey is missing
	variable	nKeys	= SKCnt( nType )	
	// check every entry (=subkey) in the line
	variable	nMK		= nType 
MarkPerfTestTime 310	// ExtractValue: Init
	for ( k = 0; k < nKeys; k += 1 )
		string 	sEntries	= StringByKey( SKNm( nType, k ), sPulsLine, sVALSEP, sLISTSEP ) 	
		string 	sData	= SelectString( strlen( sEntries ), SKDef( nType, k ), sEntries)
		if ( strsearch( sData, sVALSEP, 0 ) != NOTFOUND )
			Alert( cFATAL,  "Could not interpret '" + sData + "' in line '" + sPulsLine + "'. " )
			return	cERROR
		endif
		string 	sFrom	= SelectString( strlen( sEntries ), "defaulted to", "read script" )
		CheckNumberOfFrames( sData, nMK, nFrm )	
		//printf "\t\tExtractValueIO()  sMK:%s\tk:%d  nTyp:%2d\t-> SKNm:%s  \t-> sEntr:%s\t-> sData:%s\t'%s' \r", pd(sMainkey,8), k, nType, pd(SKNm( nType, k ),7), pd(sEntries,12), pad(sData,8), sPulsLine 	
		// printf "\t\t\t\tExtractValue()     %2d \t%12s\t SkT:%2d \t%8s \t%12s \t'%s' \r", nMK, sMainkey, SKTyp( nMK, k ), sFrom,  SKNm( nType, k ), sData
MarkPerfTestTime 320	// ExtractValue Loop Keys : Init

		for ( f = 0; f < nFrm; f += 1 )					//  use number of frames from FRAMES: keyword, don't use the counted frames
			string  sData0	= StringFromList( f, sData, sFRAMESEP )
			if ( strlen( sData0 ) )						// if  data are not missing...
				vS( wVal,nEle, k+1, f, sData0 ) 
				//printf "\t\t\t\tExtractValue()     filling  nEle:%2d  frame:%d  k:%2d  with  existing  \tvalue '%s' \r", nEle, f, k+1,  sData0
			else									// if  data are missing ...
				if ( f == 0  )							//	..and it is the first frame data which are missing...
					vS( wVal,nEle, k+1, f, SKDef( nType, k ) )	//		..we use the default values
					//printf "\t\t\t\tExtractValue()     filling  nEle:%2d  frame:%d  k:%2d  with  default  \tvalue '%s' \r", nEle, f, k+1, SKDef( nType, k )
				else									// 	..and it is any following frame for which the data are missing...
					vS( wVal,nEle, k+1, f, vG( wVal, nEle, k+1, f -1 ) )	//		...we use the  values from the preceding frame
					//printf "\t\t\t\tExtractValue()     filling  nEle:%2d  frame:%d  k:%2d  with  previous  \tvalue '%s' \r", nEle, f, k+1, vG( wVal, nEle, k+1, f -1 ) 
				endif
			endif
		endfor
MarkPerfTestTime 330	// ExtractValue Loop Keys : Loop Frames
		//printf "\t\tExtractValue()   MK:%2d\t%s\t SkT:%2d \t%8s \t%s\tFrm0 %s \tFr1? %s\tFr2? %s \r", nMK, pad(sMainkey,6), SKTyp( nMK, k ), sFrom,  pad(SKNm( nType, k ),6),  pad(vG( wVal, nEle, k+1, 0 ),14), pad( vG( wVal, nEle, k+1, 1 ),14),  pad(vG( wVal, nEle, k+1, 2 ),14)
		//printf "\t\tExtractValue()   MK:%2d\t%s\t%8s \t%s\tFrm0 %s \tFr1? %s\tFr2? %s \r", nMK, pad(sMainkey,6), sFrom,  pad(SKNm( nType, k ),6),  pad(vG( wVal, nEle, k+1, 0 ),14), pad( vG( wVal, nEle, k+1, 1 ),14),  pad(vG( wVal, nEle, k+1, 2 ),14)
	endfor
MarkPerfTestTime 340	// ExtractValue: end
	return	0
End


static	Function	CheckNumberOfFrames( sData, nTyp, nFrm )	
// alert user that script contains errors
// return corrected frame number (but don't use it, use 'nFrm' for array size to keep array rectangular)
	string 	sData
	variable	nTyp, nFrm
	variable	nFrames	= ItemsInList( sData,  sFRAMESEP ) 
	if ( nFrames > nFrm )				// more entries in this line than determined by Frames key word
		Alert( cFATAL,  "'" + ms( nTyp ) + "' contains more frames (=" + num2str( nFrames ) + ") than determined by 'Frames' key word (=" + num2str( nFrm ) + "). " )
	endif
	return nFrm
End


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function   		ShowVal( wVal, nFrm )
// Check the intermediate data structure ' wVal' current variables on screen
	wave	/T	wVal
	variable	nFrm
	nvar		gRadDebgSel		= root:uf:dlg:gRadDebgSel
	nvar		PnDebgShowVal	= root:uf:dlg:Debg:ShowVal
	if ( gRadDebgSel > 1  &&  PnDebgShowVal )	// we save (a little bit of) time by skipping this function right here if it is turned off anyway
		variable	l
		for  ( l = 0; l < vMaxLines( wVal ); l += 1 )
			PrintValLine( wVal, l, nFrm )
		endfor
	endif
End

static Function  PrintValLine( wVal, nLine, nFrm )
	wave	/T	wVal
	variable	nLine, nFrm
	variable	k, f, nType = vTyp( wVal, nLine )
	string	bf  = ""
	printf  "\t\t\tShowVal(Frm:%d) l:%2d\tt:%2d\t%-12s\t", nFrm, nLine,  nType,  mS( nType )
	for ( k = 0; k < ItemsInList( mkS( nType ), sPSEP ); k += 1)
		bf += pad( StringFromList( k, mkS( nType ), sPSEP ),6 ) + "\t"
		for ( f = 0; f < nFrm; f += 1)
			bf += pad( vG( wVal, nLine, k+1, f ), 9 ) + "\t"					
		endfor
	endfor
	printf "%s\r", bf[0,200] 
End


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//   INTERFACE  FOR  SCRIPT LINES   = TEXT WAVE  ' wLines'
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function		DuplicateScript( sFolder )
	string  	sFolder
	wave  /T	wLines	= $"root:uf:" + sFolder + ":keep:wLines"
	duplicate /T /O wLines $"root:uf:" + sFolder + ":keep:wLinesCopy"
End

Function  		nLinesDuplicate( sFolder )
// Get number of  entries
	string  	sFolder
	wave  /T	wLinesCopy	= $"root:uf:" + sFolder + ":keep:wLinesCopy"
	return 	numpnts( wLinesCopy )
End

Function  /S	GetScrLineDuplicate(  sFolder, nLine )
// Get one script line
	string  	sFolder
	variable	nLine
	wave  /T	wLinesCopy	= $"root:uf:" + sFolder + ":keep:wLinesCopy"
	return	wLinesCopy[ nLine ]
End

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


Function  		bLinesOK( sFolder )
// Check if  wLines has  already been defined
	string  	sFolder
	wave /Z /T  wLines	= $"root:uf:" + sFolder + ":keep:wLines"
	return	waveExists( wLines )  
End

Function  		nLines( sFolder )
// Get number of  entries
	string  	sFolder
	wave  /T	wLines	= $"root:uf:" + sFolder + ":keep:wLines"
	return 	numpnts( wLines )
End

Function		DeleteLastScrLine( sFolder )
// Makes text wave one smaller, deletes last entry
	string  	sFolder
	wave  /T	wLines	= $"root:uf:" + sFolder + ":keep:wLines"
	redimension  /N = ( nLines( sFolder ) - 1 ) wLines
End

Function 		InsertScrLine( sFolder, nLine, sText )
// Make new line at  the end and fill it with 'sText' (wave size will increase)
	string  	sFolder
	variable	nLine
	string		sText
	variable	l
	wave  /T	wLines	= $"root:uf:" + sFolder + ":keep:wLines"
	redimension  /N = ( nLines( sFolder ) + 1)  wLines		// make space for additional line at the end
	for ( l = nLines( sFolder ) - 2; l >= nLine; l -= 1 )
		wLines[ l + 1 ]  = wLines[ l ]					// move all lines behind insertion point one line farther
	endfor
	wLines[ nLine ]  = sText						// copy line text into the desired line	
End

Function		InsertLines( sFolder, pos, cnt, sInsertLine )
// inserts 'cnt'  lines containing 'sInsertLine'  after line 'pos'  in 'wLines' , increases 'wLines' 
	string  	sFolder
	variable	pos, cnt
	string		sInsertLine
	variable	l, OldLineCnt = nLines( sFolder )
	wave  /T	wLines	= $"root:uf:" + sFolder + ":keep:wLines"
	redimension	/N=( OldLineCnt + cnt )	wLines
	for ( l = OldLineCnt; l >= pos; l -=1 )
		SetScrLine( sFolder, l + cnt, GetScrLine( sFolder, l ) )		
	endfor
	for ( l = pos + cnt - 1; l >= pos; l -=1 )
		SetScrLine( sFolder, l, sInsertLine )		
	endfor
End

Function 		AppendScrLineS( sFolder, sText )
// Make new line at  the end and fill it with 'sText' (wave size will increase)
	string  	sFolder
	string		sText
	wave  /T	wLines	= $"root:uf:" + sFolder + ":keep:wLines"
	redimension  /N = ( nLines( sFolder ) + 1)  wLines
	wLines[ nLines( sFolder ) - 1 ]  = sText	
End

Function 		AppendScrLine( sFolder, nLine )
// Make new line at index 'nLine'  (wave must be large enough)
	string  	sFolder
	variable	nLine
	wave  /T	wLines	= $"root:uf:" + sFolder + ":keep:wLines"
	wLines[ nLine ]  = { "" }	
End

Function  /S	GetScrLine( sFolder, nLine )
// Get one script line
	string  	sFolder
	variable	nLine
	wave  /T	wLines	= $"root:uf:" + sFolder + ":keep:wLines"
	return	wLines[ nLine ]
End

Function  		SetScrLine( sFolder, nLine, sLine )
// Set one script line
	string  	sFolder
	variable	nLine
	string		sLine
	wave  /T	wLines	= $"root:uf:" + sFolder + ":keep:wLines"
	wLines[ nLine ] = sLine
End

Function		GetScrValDef( sFolder, nLine, sSubKey )
//  extracts and returns subkey values from script file, when line number is given (or returns DEFAULT, when not found)
// 021125 could and should??? replace all occurrences of GetScrVal()
	variable	nLine
	string		sFolder, sSubKey
	return	GetScrValDefS( sFolder, GetScrLine( sFolder, nLine ), sSubKey )
End

Function		GetScrValDefS( sFolder, sLine, sSubKey )
////  extracts and returns subkey values from script file, when line is given as string (or returns  DEFAULT,  when not found)
// 021125 could and should??? replace all occurrences of GetScrValS()
	string 	sFolder, sLine, sSubkey
	string 	sMainKey	= StringFromList( 0, sLine, sMAINKEYSEP )
	variable	value		= GetScrValS( sFolder, sLine, sSubKey )
	if ( numType( value ) == NUMTYPE_NAN )					// subkey not found in this script line 
		value	= str2num( eaDef( sMainKey, sSubKey ) )
	endif
	//printf "\t\tGetScrValDefS()  \t%s  \t%s  \t%s  extracted %6g  \thas default  '%s'   \t-> returning %g \r " ,  pd(sLine, 18), pd(sMainKey,8), pd(sSubKey,8), GetScrValS( sLine, sSubKey ), eaDef( sMainKey, sSubKey ), value
	return	value
End

Function		GetScrVal( sFolder, nLine, sSubKey )
//  extracts and returns subkey values from script file, when line number is given (or returns NAN, when not found)
	variable	nLine
	string 	sFolder, sSubkey
	// print "GetScrVal() [not found returns Nan]     nLine:" , nLine, sSubKey
	return 	GetScrValS( sFolder, GetScrLine( sFolder, nLine ), sSubKey )
End

Function		GetScrValS( sFolder, sLine, sSubKey )
////  extracts and returns subkey values from script file, when line is given as string (or returns NAN, when not found)
	string 	sFolder, sLine, sSubkey
	sLine		= RemoveListItem( 0, sLine, sMAINKEYSEP )		// remove main key and colon, leave subkeys
	variable	value = NumberByKey( sSubKey, sLine, sVALSEP, sLISTSEP ) 
	//printf "\t\tGetScrValS() \t\t\t\t\t%s  \t%s  returns  \t%g  \r " , pd(sLine, 18), pd(sSubKey,8), value
	return	value
End

Function	/S	GetScrStrS( sLine, sSubKey )
////  extracts and returns subkey strings from script file, when line is given as string (or returns ................   empty string .......NAN, when not found)
	string 	sLine, sSubkey
	sLine		= RemoveListItem( 0, sLine, sMAINKEYSEP )		// remove main key and colon, leave subkeys
	string	 	str = StringByKey( sSubKey, sLine, sVALSEP, sLISTSEP ) 
	//printf "\t\tGetScrStrS() \t\t\t\t\t%s  \t%s  returns  \t%s  \r " , pd(sLine, 18), pd(sSubKey,8), str
	return	str
End

///////////////////////////////////////////////////////////////////////////////////////////////

static Function	GetDacChannelFromIO( sFolder, l )
	string  	sFolder
	variable	l
	variable	nIODacChan	= NOTFOUND
	string 	sDacOut	= GetScrLine( sFolder, l )
	if ( cmpstr( StringFromList( 0, sDacOut, sMAINKEYSEP ), "Dac" ) == 0 )// does Line contain the first expected key ?
		sDacOut = StringBykey( "Chan", StringFromList( 1, sDacOut, ":" ), "=" )
		nIODacChan = str2num( sDacOut )
	endif												
	return	nIODacChan
End

static Function	GetDacChannelFromStim( sFolder, l )
// //!  THIS  FUNCTION  DETERMINES  THE  ORDER  OF  THE  ENTRIES  IN  THE  SCRIPT  OR  DEPENDS ON  IT
	string  	sFolder
	variable	l
	string 	str	= StringFromList( 1, GetScrLine( sFolder, l ), ":" ) 			// remove main key and colon
	variable	Cha	= NumberByKey( "Dac", str, "=", "," )				// can only extract the first item this way, (Dacout=0,5,7;)
	//print	numType( Cha ) == NUMTYPE_NAN ? NOTFOUND : Cha	// was correct  line (= correct subkey)  but  channel entry was empty
	return	numType( Cha ) == NUMTYPE_NAN ? NOTFOUND : Cha	// was correct  line (= correct subkey)  but  channel entry was empty
End

strconstant	ksIOTYPES	= "Dac;Adc;PoN;Sum;Aver;"									// must be same order as in wMK[]
