// search for 0608
//
//  UFCom_Constants.ipf 
// 
// 040210	Generally useful constants must be included in multiple projects by '#include ThisFile'  to avoid  'Duplicate constant'  error

//#pragma IndependentModule=UFCom_

//=============================================================================================================================================================

strconstant	ksSRC_DIR_COM		= "UserIgor:Commons"	// where InnoSetup will  get the source files common to  FPulse, SecuTest, Recipes.. on the user's hard disk
//strconstant	ksINSTALL_DIR_COM	= "IgorProcs:Commons"	// where InnoSetup will  unpack and install  the files common to  FPulse, SecuTest, Recipes.. on the user's hard disk
strconstant	ksCOMMONS_DIR		= "Commons"			// subdirectory of  'UserIgor' on my hard disk and  of  'IgorProcs'  on the users HD where the common procedure files are located...

strconstant	ksROOTUF_			= "root:uf:"			// the base folder for everything

constant		FALSE  				= 0,	TRUE 	= 1
constant		OFF					= 0 ,	ON		= 1
constant		kERROR				= -1, 	kOK		= 0
constant		kBACK  				= 0 , 	kFRONT 	= 1
constant		kDOWN  				= -1, 	kUP	 	= 1		// search direction when searching the next free or used file

strconstant	ksDIRSEP 			= ":"					// IGOR prefers MacIntosh style separator for file paths. To use the windows path convention a conversion is needed .  ( Igors data folder separator ksF_SEP is a different thing but happens to be the same )

// Graphics
constant		UFCom_kIGOR_POINTS72		= 72	// needed to convert from screen pixels to points
constant		UFCom_kIGOR_YMIN_WNDLOC	= 37	// needed to convert from screen pixels to points (=GetIgorAppPoints( ->YMinPoints ) )

// 060911
// should be moved, concerns only listboxes
// FOR THE  SELECT RESULTS   LISTBOX  PANELS			
strconstant	ksCOL_SEP	= "~"	
strconstant	UFCom_ksSEP_UNIT1	= "/" , UFCom_ksSEP_UNIT2 = ""   	// e.g. can be    '/' and ''  =  Peak/mV      or   '['  and  ']'   = Peak[mV]
constant		kLB_ADDY		= 18							// additional y pixel for window title, listbox column titles and 2 margins


// Keycodes
strconstant	klstKEYCODES			= ";Pos1;;;End;;;;;Tab;;PgUp;PgDn;Enter;;;;;;;;;;;;;;;Left;Right;Up;Down;"
constant		kPOS1				=  1
constant		kEND				=  4
constant		kTAB				=  9
constant		kPAGEUP				= 11
constant		kPAGEDOWN			= 12
constant		kENTER				= 13
constant		kARROWLEFT			= 28
constant		kARROWRIGHT		= 29
constant		kARROWUP			= 30
constant		kARROWDOWN		= 31



//  AUTOMATIC  NAMING  MODES
constant		kONELETTER = 0,  kDIGITLETTER = 1,  kTWOLETTER = 2				// automatic naming of  files   !!!elsewhere also
constant		kMAXINDEX_DIGITLETTER= 36			// 0,1...8,9,a,b,...x,y,z
constant		kMAXINDEX_2LETTERS	= 676		// 26*26, 

// Fonts
constant			kFONTSIZE 		= 12	 			// determines only the separator font size and the width of text space (inversely?) in panels, not the button or checkbox text...?
strconstant		ksFONT			= "MS Sans Serif" 	// the panels are designed for  "MS Sans Serif" 
strconstant		ksFONT_			= "\"MS Sans Serif\""// special syntax needed for   'DrawText , SetDrawEnv..'
// strconstant		ksFONT			= "Arial"			//  to use "Arial"  make all controls 1 pixel higher  (UFCom_kPANEL_kYHEIGHT=16)  or  set FONTSIZE=11. Unfortunately controls using pictures are not scaled as easily.
// strconstant		ksFONT_			= "\"Arial\""		//  special syntax needed for   'DrawText , SetDrawEnv..'
// strconstant		ksFONT			= "Courier" 		// for extreme testing
// strconstant		ksFONT_			= "\"Courier\""		//  special syntax needed for   'DrawText , SetDrawEnv..'


// Panels
constant			UFCom_kPANEL_kXMARGIN		= 2 				// horizontal margin between panel border and control ( 0..8 )
constant			UFCom_kPANEL_kYHEIGHT		= 15				// vertical size of element (button) , useful range is 15..18
constant			UFCom_kPANEL_kYLINEHEIGHT	= 20				// vertical distance between controls in a panel

strconstant		UFCom_ksSEP_TILDE		= "~"	// ","

constant			UFCom_kY_MISSING_PIXEL_TOP	= 18	// 18 is the height of  the Igor title line and menu bar	(appr.)
constant			UFCom_kY_MISSING_PIXEL_BOT	= 32	// 32 is the height of  status bar + windows 2 lines


strconstant		UFCom_ksSEP_TBCO		= "$"				// Separates tabcontrols in panels
strconstant		UFCom_ksSEP_TAB		= "°"				// Separates the tabs in a tabcontrol e.g. 'Adc0°Adc2'.  Using ^ is allowed. Do NOT use characters used in titles e.g. , .  ( ) [ ] =  .  Neither use Tilde '~' (is main sep) , colon ':' (is path sep)   or   '|'  (also used elsewhere) .
strconstant		UFCom_ksSEP_CTRL		= "|"				// Separates controls in tabcontrols in panels
strconstant		UFCom_ksSEP_STD		= ","				// standard separator e.g. for  row and column title lists
strconstant		UFCom_ksSEP_WPN		= ":"				// Separator the specifying items of a control in a 'wPn' line 
strconstant		UFCom_ksSEP_COMMONINIT= "~"			// Separates specific initialisation values from the common value which is applicable for the rest e.g. "0000_7;0001_1.5;~2.3"	


constant		kTYPE=0, kNXLN=1, kXPOS=2, kMXPO=3, kOVS=4, kTABS=5, kBLKS=6, 	kMODE=7,  kNAME=8,  kROWTI=9,   kCOLTI=10,  kACTPROC=11,  kXBODYSZ=12, kFORMENTRY=13, kINITVAL=14, kVISIB=15,  kHELPTOPIC=16

constant		kSEP = 0,  kCB = 1,  kRAD = 2,  kSV = 3,  kPM = 4,  kBU = 5,  kSTR = 6,  kBUP = 7,  kSTC = 8,  kVD = 9 
strconstant	lstTYPE ="SEP;CB;RAD;SV;PM;BU;STR;BUP;STC;VD;"

constant		UFCom_kPANEL_INIT	= 1 ,  UFCom_kPANEL_DRAW = 2

// Colors
constant			cBRed=0, cRed=1, cDRed=2, cYellow=3, cBOrange=4, cOrange=5, cBrown=6, cBGreen=7, cGreen=8, cDGreen=9, cBCyan=10, cCyan=11, cDCyan=12, cBBlue=13, cBlue=14, cDBlue=15, cBMag=16, cMag=17, cDMag=18, cBGrey=19, cGrey=20, cBlack=21
strconstant		klstCOLORS = "BRed;Red;DRed;cYellow;BOrange;Orange;Brown;BGreen;Green;DGreen;BCyan;Cyan;DCyan;BBlue;Blue;DBlue;BMag;Mag;DMag;BGrey;Grey;Black"


//=============================================================================================================================================================
// Never change the following constants which are defined by Igor 
// General
constant		UFCom_kNOTFOUND		=  -1					
constant		UFCom_kNUMTYPE_NAN	=  2					
// Objects
constant		UFCom_kIGOR_WAVE	= 0,  UFCom_kIGOR_VARIABLE 	= 2, 	UFCom_kIGOR_string  = 3, UFCom_kIGOR_FOLDER = 4	
// Window types
constant		kWN_GRAPH	= 1,  kWN_TABLE = 2,  kWN_LAYOUT = 4,  kWN_NOTEBOOK = 16,  kWN_PANEL = 64	// IGOR defined  for WinName()
constant		kNOWINDOW	= 0,	kGRAPH = 1,	kTABLE = 2,	kLAYOUT = 3,	kNOTEBOOK = 5,	kPANEL = 7	// IGOR defined  for WinType()
// Controls
constant		kCI_BUTTON	= 1,  kCI_CHECKBOX = 2, kCI_POPUPMENU = 3,  kCI_VALDISPLAY = 4, kCI_SETVARIABLE = 5,  kCI_CHART = 6,  kCI_SLIDER = 7,  kCI_TABCONTROL = 8,  kCI_GROUPBOX = 9,  kCI_TITLEBOX = 10,  kCI_LISTBOX = 11,  kCI_CUSTOMCONTROL = 12
strconstant	klstCI_CONTROLTYPES	= " ? ;bu;cb;pm;vd;sv;ch;sl;tc;gb;tb;lb;cc;"
constant		kENABLE 			= 0,	kHIDE  			= 1,	kDISABLE	= 2								// IGOR defined (except kNOEDIT_SV=3)  .  In  Button  and  SetVariable  the constants have slightly different meanings...
constant		kDISABLE_SV		= 0,	kENABLE_SV		= 1,	kNOEDIT_SV	= 3							// IGOR defined (except kNOEDIT_SV=3)  .  In  Button  and  SetVariable  the constants have slightly different meanings...
// Listbox
constant		kBIT_SEL			= 0x01							// Bit 0x01 means listbox cell is selected.  Turning off this will prevent Igor will to display the cell in 'selected' (=black) state except for a short flash. 
constant		kLB_CELLY		= 16						// empirical listbox cell height
// Table
constant		kTBL_MINCOLWIDTH = 20					// Igor cannot handle columns smaller than that
// Sorting
constant		UFCom_kSORTNORMAL 	= 0, UFCom_kSORTDESCENDING = 1, 	UFCom_kSORTNUMERICAL 		= 2
constant		UFCom_kSORT_ALPHA_NUM_CASE_S	= 8, UFCom_kSORT_ALPHA_NUM_CASE_I = 16			// parameters are actually for 'SortList' , not for 'MakeIndex' .  Move to Constants.ipf.................................
constant		kMOUSE			= 1,  	kSHIFT			= 2, 	kALT		= 4, 	kCTRL	= 8, kRIGHTCLICK = 16, kNONE = 0	// modifier values in the info string of a window hook function
constant		kTICKS_PER_SEC	= 60 						
// Colors
constant		kCOLMX			= 0xffff											// Igor specific, color maximum for RedGreenBlue
constant		kRED = 0,   kGREEN = 1,   kBLUE=2




// Generic control event
constant 		kEV_ABOUT_TO_BE_KILLED = -1		// Eventcode valid for all controls (popupmemu, checkbox, slider, setvariable

// Listbox control events
strconstant	lstLB_EVENTS	=	"(0);mouseDn;mouseUp;DblClick;CellSel;CellSelShft;EditBeg;EditEnd;VScroll;HScroll;TopRowSet;ColDivRes;"
constant 		kLBE_mousedown		= 1
constant 		kLBE_mouseup			= 2
constant 		kLBE_DoubleClick		= 3
constant 		kLBE_CellSelect		= 4
constant 		kLBE_CellSelectShift		= 5
constant 		kLBE_EditBegin			= 6
constant 		kLBE_EditEnd			= 7
constant 		kLBE_VScroll			= 8
constant 		kLBE_HScroll			= 9
constant 		kLBE_TopRowSet		= 10
constant 		kLBE_ColDivResize		= 11


// Custom control events
strconstant	lstEVENTCODES		= "( 0 );mouseDn;mouseUp;mouseUpOut;mouseMv;enter;leave;( 7 );( 8 );( 9 );draw;mode;frame;dispose;modernize;tab;char;drawOSBM;idle;"
constant 		kCCE_mousedown		= 1
constant 		kCCE_mouseup			= 2
constant 		kCCE_mouseup_out		= 3
constant 		kCCE_mousemoved		= 4
constant 		kCCE_enter			= 5
constant 		kCCE_leave			= 6
constant 		kCCE_draw			= 10
constant 		kCCE_mode			= 11
constant 		kCCE_frame			= 12
constant 		kCCE_dispose			= 13
constant 		kCCE_modernize		= 14
constant 		kCCE_tab				= 15
constant 		kCCE_char			= 16
constant	 	kCCE_drawOSBM		= 17
constant 		kCCE_idle				= 18

// Window Hooks
strconstant	lstWINHOOKCODES		= "activate;deactivate;kill;mouseDn;mouseMv;mouseUp;resize;cursorMv;modified;enableMenu;menu;keyboard;move;"
constant		kWHK_activate			= 0
constant		kWHK_deactivate		= 1
constant		kWHK_kill				= 2	
constant		kWHK_mousedown		= 3
constant		kWHK_mousemoved		= 4
constant		kWHK_mouseup		= 5
constant		kWHK_resize			= 6
constant		kWHK_cursormoved		= 7	// See Cursors - Moving Cursor Calls Function.
constant		kWHK_modified			= 8
constant		kWHK_enablemenu		= 9
constant		kWHK_menu			= 10
constant		kWHK_keyboard		= 11
constant		kWHK_move			= 12


