// search for 0608
//
//  FP_Constants.ipf 
// 
// 040210	Generally useful constants must be included in multiple projects by '#include ThisFile'  to avoid  'Duplicate constant'  error

//=============================================================================================================================================================

strconstant	ksROOTUF_		= "root:uf:"		// the base folder for everything

constant		FALSE  			= 0,	TRUE 	= 1
constant		OFF				= 0 ,	ON		= 1
constant		kERROR			= -1, 	kOK		= 0
constant		kBACK  			= 0 , 	kFRONT 	= 1
constant		kDOWN  			= -1, 	kUP	 	= 1	// search direction when searching the next free or used file

strconstant	ksDIRSEP 		= ":"				// IGOR prefers MacIntosh style separator for file paths. To use the windows path convention a conversion is needed .  ( Igors data folder separator ksF_SEP is a different thing but happens to be the same )

// 060911
// should be moved, concerns only listboxes
// FOR THE  SELECT RESULTS   LISTBOX  PANELS			
strconstant	ksCOL_SEP	= "~"	
strconstant	ksSEP_UNIT1	= "/" , ksSEP_UNIT2 = ""   	// e.g. can be    '/' and ''  =  Peak/mV      or   '['  and  ']'   = Peak[mV]
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

//=============================================================================================================================================================
// Never change the following constants which are defined by Igor 
// General
constant		kNOTFOUND		=  -1					
constant		kNUMTYPE_NAN	=  2					
// Objects
constant		kIGOR_WAVE	= 0,  kIGOR_VARIABLE 	= 2, 	kIGOR_string  = 3, kIGOR_FOLDER = 4	
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
constant		kSORTNORMAL 	= 0, kSORTDESCENDING = 1, 	kSORTNUMERICAL 		= 2
constant		kSORT_ALPHA_NUM_CASE_S	= 8, kSORT_ALPHA_NUM_CASE_I = 16			// parameters are actually for 'SortList' , not for 'MakeIndex' .  Move to Constants.ipf.................................
constant		kMOUSE			= 1,  	kSHIFT			= 2, 	kALT		= 4, 	kCTRL	= 8, kRIGHTCLICK = 16, kNONE = 0	// modifier values in the info string of a window hook function
constant		kTICKS_PER_SEC	= 60 						
// Colors
constant		kCOLMX			= 0xffff											// Igor specific, color maximum for RedGreenBlue
constant		kRED = 0,   kGREEN = 1,   kBLUE=2




// Generic control event
constant 		kEV_ABOUT_TO_BE_KILLED = -1		// Eventcode valid for all controls (popupmemu, checkbox, slider, setvariable


strconstant	lstCBE_EVENTS	=	"(0); ? ;mouseUp;"
constant 		kCBE_MouseUp		 = 2		

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


