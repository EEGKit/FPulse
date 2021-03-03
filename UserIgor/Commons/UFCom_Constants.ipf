// search 0608 for changes which must be transfered to any newer version
//
//  UFCom_Constants.ipf 
// 
// 2004-0210	Generally useful constants must be included in multiple projects by '#include ThisFile'  to avoid  'Duplicate constant'  error

//#pragma IndependentModule=UFCom_

//=============================================================================================================================================================

strconstant	UFCom_ksUSERIGOR_DIR		= "UserIgor"		// base directory for all  (e.g. for FPuls_, FEval_, SecuCheck_...)

// 2009-05-06	moved all archive and setup files  fron UserIgor to UserIgorArchive  to keep  UserIgor (=the working directory)  small  (which speeds up the daily backup process) 
strconstant	UFCom_ksUSERIGOR_ARCHIV_DIR	= "UserIgorArchive"	// base directory for all  (e.g. for FPuls_Archive, FPuls_SetupExe, FPuls_Out, FEval_Archive,  FEval_SetupExe, FEval_Out, SecuCheck_Archive...)

strconstant	UFCom_ksDIR_COMMONS	= "Commons"			// subdirectory of  'UserIgor' on my hard disk where InnoSetup will  get the source files common to  FPuls, SecuCheck, Recipes.. 

strconstant	UFCom_ksROOT_UF_		= "root:uf:"			// the base folder for everything

constant		UFCom_FALSE 			= 0,	UFCom_TRUE 	= 1
constant		UFCom_kOFF			= 0 ,	UFCom_kON	= 1
constant		UFCom_kERROR		= -1, 	UFCom_kOK	= 0
constant		UFCom_kDOWN  		= -1, 	UFCom_kUP 	= 1		// search direction when searching the next free or used file

// Numbers
//strconstant	ksBIG_INTEGER		= "999999999999"	// 1e12-1 . This is a workaround used  because 'inf'  is sorted before numbers in text format 
constant  		UFCom_MEGABYTE		= 0x100000

// Graphics
constant		UFCom_kIGOR_POINTS72		= 72	// needed to convert from screen pixels to points
constant		UFCom_kIGOR_YMIN_WNDLOC	= 37	// needed to convert from screen pixels to points (=GetIgorAppPoints( ->YMinPoints ) )

// 2006-0911
// should be moved, concerns only listboxes
// FOR THE  SELECT RESULTS   LISTBOX  PANELS			
strconstant	UFCom_ksSEP_UNIT1	= "/" , UFCom_ksSEP_UNIT2 = ""   	// e.g. can be    '/' and ''  =  Peak/mV      or   '['  and  ']'   = Peak[mV]
constant		UFCom_kLB_ADDY		= 18							// additional y pixel for window title, listbox column titles and 2 margins


// Keycodes
strconstant	UFCom_COD_lstKEYS		= ";Pos1;;;End;;;;;Tab;;PgUp;PgDn;Enter;;;;;;;;;;;;;;;Left;Right;Up;Down;"
constant		UFCom_COD_POS1			=  1
constant		UFCom_COD_END			=  4
constant		UFCom_COD_TAB			=  9
constant		UFCom_COD_PAGEUP		= 11
constant		UFCom_COD_PAGEDOWN	= 12
constant		UFCom_COD_ENTER		= 13
constant		UFCom_COD_ARRLEFT		= 28
constant		UFCom_COD_ARRRIGHT		= 29
constant		UFCom_COD_ARRUP		= 30
constant		UFCom_COD_ARRDOWN		= 31


// Searching and sorting
constant		UFCom_kSORTACTION_TOGGLE = 0,   UFCom_kSORTACTION_UP = 1,	UFCom_kSORTACTION_DOWN = -1


//  AUTOMATIC  NAMING  MODES
constant		UFCom_kANM_ONELETTER = 0,  UFCom_kANM_DIGITLETTER = 1,  UFCom_kANM_TWOLETTER = 2				// automatic naming of  files   !!!elsewhere also
constant		UFCom_kANM_MAX_2LETTERS	= 676	// 26*26, 
//constant		UFCom_kANM_MAX_DIGITLETTER= 36		// 0,1...8,9,a,b,...x,y,z

// Fonts
constant		UFCom_kFONTSIZE 		= 12	 			// determines only the separator font size and the width of text space (inversely?) in panels, not the button or checkbox text...?
strconstant	UFCom_ksFONT		= "MS Sans Serif" 	// the panels are designed for  "MS Sans Serif" 
strconstant	UFCom_ksFONT_		= "\"MS Sans Serif\""// special syntax needed for   'DrawText , SetDrawEnv..'
// strconstant	UFCom_ksFONT		= "Arial"			//  to use "Arial"  make all controls 1 pixel higher  (UFCom_kPANEL_kYHEIGHT=16)  or  set FONTSIZE=11. Unfortunately controls using pictures are not scaled as easily.
// strconstant	UFCom_ksFONT_		= "\"Arial\""		//  special syntax needed for   'DrawText , SetDrawEnv..'
// strconstant	UFCom_ksFONT		= "Courier" 		// for extreme testing
// strconstant	UFCom_ksFONT_		= "\"Courier\""		//  special syntax needed for   'DrawText , SetDrawEnv..'


// Panels
// 2007-0927 obsolete, used only in V319
constant		UFCom_kPANEL_kXMARGIN		= 2 		// horizontal margin between panel border and control ( 0..8 )

constant		UFCom_kPANEL_kYHEIGHT		= 15		// vertical size of element (button) , useful range is 15..18
constant		UFCom_kPANEL_kYLINEHEIGHT	= 20		// vertical distance between controls in a panel
// only V4xx
constant		UFCom_kMAGIC_Y_MISSING_PIXEL = 26		// only V4xx	// on 1600x1200 screen that many y pixel are not available compared to what  'GetWindow kFrameInner' claims. ??? Is it the status line which must be taken into account???
constant		UFCom_kKILL_ALLOW			= 1,	UFCom_kKILL_DISABLE = 2	// only V4xx	
strconstant	UFCom_ksCOL_SEP				= "~"			// only V4xx	

strconstant	UFCom_ksSEP_TILDE			= "~"	

constant		UFCom_kY_MISSING_PIXEL_TOP	= 18		// 18 is the height of  the Igor title line and menu bar	(appr.)
constant		UFCom_kY_MISSING_PIXEL_BOT	= 32		// 32 is the height of  status bar + windows 2 lines


strconstant	UFCom_ksSEP_TBCO		= "$"			// Separates tabcontrols in panels
strconstant	UFCom_ksSEP_TAB			= "°"			// Separates the tabs in a tabcontrol e.g. 'Adc0°Adc2'.  Using ^ is allowed. Do NOT use characters used in titles e.g. , .  ( ) [ ] =  .  Neither use Tilde '~' (is main sep) , colon ':' (is path sep)   or   '|'  (also used elsewhere) .
strconstant	UFCom_ksSEP_CTRL		= "|"			// Separates controls in tabcontrols in panels
strconstant	UFCom_ksSEP_STD			= ","			// standard separator e.g. for  row and column title lists
strconstant	UFCom_ksSEP_WPN		= ":"			// Separator the specifying items of a control in a 'wPn' line 
strconstant	UFCom_ksSEP_COMMONINIT	= "~"		// Separates specific initialisation values from the common value which is applicable for the rest e.g. "0000_7;0001_1.5;~2.3"	


constant		UFCom_kPANEL_INIT	= 1 ,   UFCom_kPANEL_DRAW = 2
constant		UFCom_kRESIZE_TBL	= 0 ,   UFCom_kKILL_TBL = 1

// Colors
// 2009-07-01 removed during the great cleanup
//constant		UFCom_cBRed=0, 	UFCom_cRed=1, 	UFCom_cDRed=2, 	UFCom_cYellow=3, 	UFCom_cBOrange=4, UFCom_cOrange=5,	UFCom_cBrown=6,	UFCom_cBGreen=7, 	UFCom_cGreen=8,	UFCom_cDGreen=9,	UFCom_cBCyan=10
//constant		UFCom_cCyan=11, 	UFCom_cDCyan=12, UFCom_cBBlue=13, 	UFCom_cBlue=14, 	UFCom_cDBlue=15, 	 UFCom_cBMag=16, 	UFCom_cMag=17,	UFCom_cDMag=18,	UFCom_cBGrey=19,	UFCom_cGrey=20,	UFCom_cBlack=21
//strconstant	UFCom_lstCOLORS	= "BRed;Red;DRed;cYellow;BOrange;Orange;Brown;BGreen;Green;DGreen;BCyan;Cyan;DCyan;BBlue;Blue;DBlue;BMag;Mag;DMag;BGrey;Grey;Black"

strconstant	UFCom_lstCOLORS	= "BRed;				Red;		DRed;		cYellow;		BOrange;			Orange;			Brown;		BGreen;			Green;	DGreen;		BCyan;		Cyan;		DCyan;		BBlue;			Blue;			DBlue;	BMag;			Mag;			DMag;		BGrey;			Grey;				Black"
strconstant	UFCom_COLORS	= "65535,42000,42000;  65535,0,0;  46000,0,0;   65535,65535,0;   65535,57000,42000;   65535,44000,2000;  44000,34000,0;  42000,65535,42000;  0,56000,0;  0,36000,0;  50000,65535,65535;  0,60000,60000;  0,40000,40000;  41000,56000,65535;  0,0,65535;  0,0,50000;  60000,47000,60000;  60000,0,56000;   48000,0,38000;  56000,56000,56000;  41000,41000,41000;  0,0,0;"		

	


// Sroring and retrieving window positions and sizes in Preferences
constant		UFCom_WLF = 0,   UFCom_WTP = 1,  UFCom_WRI = 2,   UFCom_WBO = 3,  UFCom_WVI = 4 	// top, left, right, bottom, visible, unused


//=============================================================================================================================================================
// Never change the following constants which are defined by Igor 
// General
constant		UFCom_kNOTFOUND		=  -1					
constant		UFCom_kNUMTYPE_NAN	=  2					
// Objects
constant		UFCom_kIGOR_WAVE	= 1,  UFCom_kIGOR_VARIABLE = 2, 	UFCom_kIGOR_string  = 3, UFCom_kIGOR_FOLDER = 4	
// Window types
constant		UFCom_WN_GRAPH	= 1,  UFCom_WN_TABLE = 2,  		UFCom_WN_LAYOUT = 4,  UFCom_WN_NOTEBOOK=16, UFCom_WN_PANEL = 64	, UFCom_WN_GIZMO = 4096	// IGOR defined  for WinName()
constant		UFCom_WT_NOWINDOW= 0,	UFCom_WT_GRAPH = 1,		UFCom_WT_TABLE = 2,	  UFCom_WT_LAYOUT = 3,	UFCom_WT_NOTEBOOK = 5,	UFCom_WT_PANEL = 7	// IGOR defined  for WinType()
// Controls
constant		UFCom_kCI_BUTTON	= 1,  UFCom_kCI_CHECKBOX = 2, UFCom_kCI_POPUPMENU = 3,  UFCom_kCI_VALDISPLAY = 4,  UFCom_kCI_SETVARIABLE = 5,  UFCom_kCI_CHART = 6,  UFCom_kCI_SLIDER = 7,  UFCom_kCI_TABCONTROL = 8,  UFCom_kCI_GROUPBOX = 9,  UFCom_kCI_TITLEBOX = 10,  UFCom_kCI_LISTBOX = 11,  UFCom_kCI_CUSTOMCONTROL = 12
strconstant	UFCom_kCI_lstCONTROLTYPES	= " ? ;bu;cb;pm;vd;sv;ch;sl;tc;gb;tb;lb;cc;"
constant		UFCom_kCo_ENABLE 			= 0,	UFCom_kCo_HIDE  			= 1,	UFCom_kCo_DISABLE	= 2								// IGOR defined (except UFCom_kCo_NOEDIT_SV=3)  .  In  Button  and  SetVariable  the constants have slightly different meanings...
constant		UFCom_kCo_DISABLE_SV		= 0,	UFCom_kCo_ENABLE_SV		= 1,	UFCom_kCo_NOEDIT_SV	= 3							// IGOR defined (except UFCom_kCo_NOEDIT_SV=3)  .  In  Button  and  SetVariable  the constants have slightly different meanings...
// Listbox
constant		UFCom_kLB_BIT_SEL	= 0x01					// Bit 0x01 means listbox cell is selected.  Turning off this will prevent Igor will to display the cell in 'selected' (=black) state except for a short flash. 
constant		UFCom_kLB_CELLY		= 16						// empirical listbox cell height
constant		UFCom_kBITSELECTED	= 0x01						// Igor-defined. The bit which controls the selection state of a listbox cell
// Table
constant		UFCom_kTBL_MINCOLWIDTH = 20					// Igor cannot handle columns smaller than that
// Sorting
constant		UFCom_kSORTNORMAL 	= 0, 				UFCom_kSORTDESCENDING = 1, 	UFCom_kSORTNUMERICAL 		= 2
constant		UFCom_kSORT_ALPHA_NUM_CASE_S	= 8, 	UFCom_kSORT_ALPHA_NUM_CASE_I = 16			// parameters are actually for 'SortList' , not for 'MakeIndex'
constant		UFCom_kMD_MOUSE = 1,  UFCom_kMD_SHIFT = 2,  UFCom_kMD_ALT = 4,  UFCom_kMD_CTRL = 8,  UFCom_kMD_RIGHTCLICK = 16,  UFCom_kMD_NONE = 0	// modifier values in the info string of a window hook function
constant		UFCom_kTICKS_PER_SEC	= 60 						
// Colors
constant		UFCom_kCOLMX			= 0xffff											// Igor specific, color maximum for RedGreenBlue
constant		UFCom_kRED = 0,   UFCom_kGREEN = 1,   UFCom_kBLUE=2




// Generic control event
constant 		UFCom_kEV_ABOUT_TO_BE_KILLED = -1		// Eventcode valid for all controls (popupmemu, checkbox, slider, setvariable

// Checkbox control events
constant 		UFCom_CBE_ABOUT_TO_BE_KILLED = -1		
constant 		UFCom_CBE_MouseUp		 = 2		

// Button control events
constant 		UFCom_BUE_ABOUT_TO_BE_KILLED = -1		
constant 		UFCom_BUE_MouseDown		 = 1		
constant 		UFCom_BUE_MouseUp		 = 2		

// Popupmenu control events
constant 		UFCom_PME_ABOUT_TO_BE_KILLED = -1		
constant 		UFCom_PME_MouseUp		 = 2		

// SetVariable control events
strconstant	UFCom_SVE_lstEVENTS		=  "(0);mouseUp;Enter key;Live update;"
constant 		UFCom_SVE_mouseup		= 1
constant 		UFCom_SVE_EnterKey		= 2
constant 		UFCom_SVE_LiveUpdate		= 3

// Listbox control events
strconstant	UFCom_LBE_lstEVENTS		=  "(0);mouseDn;mouseUp;DblClick;CellSel;CellSelShft;EditBeg;EditEnd;VScroll;HScroll;TopRowSet;ColDivRes;"
constant 		UFCom_LBE_mousedown		= 1
constant 		UFCom_LBE_mouseup		= 2
constant 		UFCom_LBE_DoubleClick		= 3
constant 		UFCom_LBE_CellSelect		= 4
constant 		UFCom_LBE_CellSelectShift	= 5
constant 		UFCom_LBE_EditBegin		= 6
constant 		UFCom_LBE_EditEnd		= 7
constant 		UFCom_LBE_VScroll			= 8
constant 		UFCom_LBE_HScroll			= 9
constant 		UFCom_LBE_TopRowSet		= 10
constant 		UFCom_LBE_ColDivResize	= 11

// Custom control events
strconstant	UFCom_CCE_lstEVENTCODES	= "( 0 );mouseDn;mouseUp;mouseUpOut;mouseMv;enter;leave;( 7 );( 8 );( 9 );draw;mode;frame;dispose;modernize;tab;char;drawOSBM;idle;"
constant 		UFCom_CCE_mousedown		= 1
constant 		UFCom_CCE_mouseup		= 2
constant 		UFCom_CCE_mouseup_out	= 3
constant 		UFCom_CCE_mousemoved	= 4
constant 		UFCom_CCE_enter			= 5
constant 		UFCom_CCE_leave			= 6
constant 		UFCom_CCE_draw			= 10
constant 		UFCom_CCE_mode			= 11
constant 		UFCom_CCE_frame			= 12
constant 		UFCom_CCE_dispose		= 13
constant 		UFCom_CCE_modernize		= 14
constant 		UFCom_CCE_tab			= 15
constant 		UFCom_CCE_char			= 16
constant	 	UFCom_CCE_drawOSBM		= 17
constant 		UFCom_CCE_idle			= 18

// Window Hooks (at least partially obsolete as Igor now supplies s.eventname)
//strconstant	UFCom_WHK_lstWINHOOKCODES	= "activate;deactivate;kill;mouseDn;mouseMv;mouseUp;resize;cursorMv;modified;enableMenu;menu;keyboard;move;"	// unfinished
constant		UFCom_WHK_activate		= 0
constant		UFCom_WHK_deactivate		= 1
constant		UFCom_WHK_kill			= 2	
constant		UFCom_WHK_mousedown	= 3
constant		UFCom_WHK_mousemoved	= 4
constant		UFCom_WHK_mouseup		= 5
constant		UFCom_WHK_resize			= 6
constant		UFCom_WHK_cursormoved	= 7	// See Cursors - Moving Cursor Calls Function.
constant		UFCom_WHK_modified		= 8
constant		UFCom_WHK_enablemenu	= 9
constant		UFCom_WHK_menu			= 10
constant		UFCom_WHK_keyboard		= 11
constant		UFCom_WHK_move			= 12
constant		UFCom_WHK_renamed		= 13
constant		UFCom_WHK_subwindowkill	= 14
constant		UFCom_WHK_hide			= 15
constant		UFCom_WHK_show			= 16
constant		UFCom_WHK_killVote		= 17
constant		UFCom_WHK_showTools		= 18
constant		UFCom_WHK_hideTools		= 19
constant		UFCom_WHK_showInfo		= 20
constant		UFCom_WHK_hideInfo		= 21
constant		UFCom_WHK_mouseWheel	= 22
constant		UFCom_WHK_spinUpdate		= 23


