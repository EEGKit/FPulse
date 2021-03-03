# Microsoft Developer Studio Generated NMAKE File, Based on FP_Mc700.dsp
!IF "$(CFG)" == ""
CFG=FP_Mc700 - Win32 Debug
!MESSAGE No configuration specified. Defaulting to FP_Mc700 - Win32 Debug.
!ENDIF 

!IF "$(CFG)" != "FP_Mc700 - Win32 Release" && "$(CFG)" != "FP_Mc700 - Win32 Debug"
!MESSAGE Invalid configuration "$(CFG)" specified.
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "FP_Mc700.mak" CFG="FP_Mc700 - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "FP_Mc700 - Win32 Release" (based on "Win32 (x86) Dynamic-Link Library")
!MESSAGE "FP_Mc700 - Win32 Debug" (based on "Win32 (x86) Dynamic-Link Library")
!MESSAGE 
!ERROR An invalid configuration is specified.
!ENDIF 

!IF "$(OS)" == "Windows_NT"
NULL=
!ELSE 
NULL=nul
!ENDIF 

CPP=cl.exe
MTL=midl.exe
RSC=rc.exe

!IF  "$(CFG)" == "FP_Mc700 - Win32 Release"

OUTDIR=.\Release
INTDIR=.\Release

ALL : ".\FP_Mc700.xop"


CLEAN :
	-@erase "$(INTDIR)\FP_Mc700.obj"
	-@erase "$(INTDIR)\FP_Mc700.res"
	-@erase "$(INTDIR)\vc60.idb"
	-@erase "$(INTDIR)\XopMain.obj"
	-@erase "$(OUTDIR)\FP_Mc700.exp"
	-@erase "$(OUTDIR)\FP_Mc700.lib"
	-@erase ".\FP_Mc700.ilk"
	-@erase ".\FP_Mc700.xop"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

CPP_PROJ=/nologo /Zp2 /ML /W3 /GX /O2 /I "..\XOPSupport" /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /D "_MBCS" /D "_USRDLL" /D "FP_Mc700_EXPORTS" /Fp"$(INTDIR)\FP_Mc700.pch" /YX /Fo"$(INTDIR)\\" /Fd"$(INTDIR)\\" /FD /c 
MTL_PROJ=/nologo /D "NDEBUG" /mktyplib203 /win32 
RSC_PROJ=/l 0x409 /fo"$(INTDIR)\FP_Mc700.res" /i "..\XOPSupport" /d "NDEBUG" 
BSC32=bscmake.exe
BSC32_FLAGS=/nologo /o"$(OUTDIR)\FP_Mc700.bsc" 
BSC32_SBRS= \
	
LINK32=link.exe
LINK32_FLAGS=kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib version.lib /nologo /dll /incremental:yes /pdb:"$(OUTDIR)\FP_Mc700.pdb" /machine:I386 /nodefaultlib:"libcd.lib" /out:"FP_Mc700.xop" /implib:"$(OUTDIR)\FP_Mc700.lib" 
LINK32_OBJS= \
	"$(INTDIR)\FP_Mc700.obj" \
	"$(INTDIR)\XopMain.obj" \
	"$(INTDIR)\FP_Mc700.res" \
	"..\..\..\programme\wavemetrics\igorxops\XOPSupport\XOPSupport x86.lib" \
	".\AxMultiClampMsg.lib" \
	"..\..\..\programme\wavemetrics\igorxops\XOPSupport\IGOR.lib"

".\FP_Mc700.xop" : "$(OUTDIR)" $(DEF_FILE) $(LINK32_OBJS)
    $(LINK32) @<<
  $(LINK32_FLAGS) $(LINK32_OBJS)
<<

!ELSEIF  "$(CFG)" == "FP_Mc700 - Win32 Debug"

OUTDIR=.\Debug
INTDIR=.\Debug

ALL : "..\FP_Mc700.xop"


CLEAN :
	-@erase "$(INTDIR)\FP_Mc700.obj"
	-@erase "$(INTDIR)\FP_Mc700.res"
	-@erase "$(INTDIR)\vc60.idb"
	-@erase "$(INTDIR)\vc60.pdb"
	-@erase "$(INTDIR)\XopMain.obj"
	-@erase "$(OUTDIR)\FP_Mc700.exp"
	-@erase "$(OUTDIR)\FP_Mc700.lib"
	-@erase "$(OUTDIR)\FP_Mc700.pdb"
	-@erase "..\FP_Mc700.xop"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

CPP_PROJ=/nologo /Zp4 /ML /W3 /Gm /GX /ZI /Od /I "..\XOPSupport" /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /D "_MBCS" /D "_USRDLL" /D "FP_Mc700_EXPORTS" /Fp"$(INTDIR)\FP_Mc700.pch" /YX /Fo"$(INTDIR)\\" /Fd"$(INTDIR)\\" /FD /GZ /c 
MTL_PROJ=/nologo /D "_DEBUG" /mktyplib203 /win32 
RSC_PROJ=/l 0x409 /fo"$(INTDIR)\FP_Mc700.res" /i "..\XOPSupport" /d "_DEBUG" 
BSC32=bscmake.exe
BSC32_FLAGS=/nologo /o"$(OUTDIR)\FP_Mc700.bsc" 
BSC32_SBRS= \
	
LINK32=link.exe
LINK32_FLAGS=kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib version.lib /nologo /dll /incremental:no /pdb:"$(OUTDIR)\FP_Mc700.pdb" /debug /machine:I386 /nodefaultlib:"libcd.lib" /out:"..\FP_Mc700.xop" /implib:"$(OUTDIR)\FP_Mc700.lib" /pdbtype:sept 
LINK32_OBJS= \
	"$(INTDIR)\FP_Mc700.obj" \
	"$(INTDIR)\XopMain.obj" \
	"$(INTDIR)\FP_Mc700.res" \
	"..\..\..\programme\wavemetrics\igorxops\XOPSupport\XOPSupport x86.lib" \
	".\AxMultiClampMsg.lib" \
	"..\..\..\programme\wavemetrics\igorxops\XOPSupport\IGOR.lib"

"..\FP_Mc700.xop" : "$(OUTDIR)" $(DEF_FILE) $(LINK32_OBJS)
    $(LINK32) @<<
  $(LINK32_FLAGS) $(LINK32_OBJS)
<<

!ENDIF 

.c{$(INTDIR)}.obj::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cpp{$(INTDIR)}.obj::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cxx{$(INTDIR)}.obj::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.c{$(INTDIR)}.sbr::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cpp{$(INTDIR)}.sbr::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cxx{$(INTDIR)}.sbr::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<


!IF "$(NO_EXTERNAL_DEPS)" != "1"
!IF EXISTS("FP_Mc700.dep")
!INCLUDE "FP_Mc700.dep"
!ELSE 
!MESSAGE Warning: cannot find "FP_Mc700.dep"
!ENDIF 
!ENDIF 


!IF "$(CFG)" == "FP_Mc700 - Win32 Release" || "$(CFG)" == "FP_Mc700 - Win32 Debug"
SOURCE=.\FP_Mc700.c

"$(INTDIR)\FP_Mc700.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\FP_Mc700.rc

"$(INTDIR)\FP_Mc700.res" : $(SOURCE) "$(INTDIR)"
	$(RSC) $(RSC_PROJ) $(SOURCE)


SOURCE=.\FP_Mc700WinCustom.rc
SOURCE=.\XopMain.c

"$(INTDIR)\XopMain.obj" : $(SOURCE) "$(INTDIR)"



!ENDIF 

