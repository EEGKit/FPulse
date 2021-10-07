# Introduction

FPulse is a program for patch-clamp recordings. The experimental protocols can defined through its own scripting language. A number of example scripts are are available in [FPulse Example Scripts](https://git.ist.ac.at/jonasgroup/FPulse/-/tree/master/UserIgor/FPulse/SomeDemoScripts). FPulse uses MultiClamp amplifier(s), and CED1401 data acquistion systems, and is running in top of IgorPro from Wavemetrics.

If not stated otherwise, all copyrights are with:

```
  Copyright (C) 2001-2021 Ulrich Fröbe, University of Freiburg, Germany
  Copyright (C) 2001-2010 Peter Jonas, University of Freiburg, Germany
  Copyright (C) 2011-2021 Peter Jonas, Institute of Science and Technology, Austria
```

This code is provided under the GPLv3 license (see COPYING). The GPL license does not apply to these files:

```
	.\UserIgor\XOP_Axon\FP_Mc700Tg\MultiClampBroadcastMsg.hpp
	.\UserIgor\XOP_Axon\FP_Mc700Tg\MCTelegraphs.h
	.\UserIgor\XOP_Dll\AxMultiClampMsg.dll
```

These files can be also obtained by installing [Installer of MC700B](http://axograph.com/installers/MultiClamp_2_1_0_16.exe). These files are then located at (C:\Program Files (x86)\Molecular Devices\MultiClamp 700B Commander).

This repository is setup mainly for documentation purpose, no active development or support is provided.


## Installing FPulse
* Prerequisites are
	- MS Windows (7 or later)
	- IgorPro 6.20+
	- MultiClamp 700A or 700B  or  Axopatch 200A or 200B
	- CED 1401

* Download and unzip [FPulse v3.45 (stable)](https://git.ist.ac.at/jonasgroup/FPulse/-/archive/v3.45/FPulse-v3.45.zip). This is recommended for production use, i.e. when you want to use FPulse for your data recordings.

* If you want to test and tweak FPulse, use the latest development version which is available from here:
[FPulse (latest)](https://git.ist.ac.at/jonasgroup/FPulse/-/archive/master/FPulse-master.zip)

* or use git

```
   git clone https://git.ist.ac.at/jonasgroup/FPulse
```

If you have an old version of FPulse installed, it is strongly recommended to uninstall it. (e.g. the uninstaller of 3.3.3 can be found on C:\UserIgor\FPulse or C:\FPulse ).

* The recommended way to install FPulse is by opening a CMD prompt with admin permission ("Run as administrator) and running

```
   install.bat
```
FPulse will be installed in C:\UserIgor\FPulse, which contains also the ```uninstall.bat``` script (it needs also admin permissions).


* Fpulse example scripts for controlling the experiment will be available under

```
   C:\UserIgor\FPulse\SomeDemoScripts\
```


## Build requirements

### Igor XOP toolkit

[XOP toolkit 6](https://www.wavemetrics.com/products/xoptoolkit "XOP toolkit 6") has been used for the interface been C-code and IgorPro.

[1]: https://www.wavemetrics.com/products/xoptoolkit "XOP toolkit"


### Compiler
   MSVC2015 is known to work. Other compilers have not been tested.


Open these two sln files:

```
  ./UserIgor/XOP_Axon/FP_Mc700Tg/VC2015/FP_Mc700Tg.sln
  ./UserIgor/XOP_Ced/FPulseCed/VC2015/FPulseCed.sln
```

The solution file assumes that the directories are organized in the following way

```
   <mydir>/FPulse/...
   <mydir>/XOP Toolkit 6/IgorXOPs6/XOPSupport/
```

If that is not the case, you need adapt the include path such that it points to your

```
   <yourdir>/XOP Toolkit 6/IgorXOPs6/XOPSupport/
```


According to [this documentation](https://docs.microsoft.com/en-us/cpp/build/reference/i-additional-include-directories?view=msvc-160), you need to set this compiler option in the Visual Studio development environment:

- Open the project's Property Pages dialog box. For details, see Set C++ compiler and build properties in Visual Studio.

- Select the Configuration Properties > C/C++ > General property page.

- Modify the Additional Include Directories property and add 
```
   <yourdir>\XOP Toolkit 6\IgorXOPs6\XOPSupport\
```

You might also need to adapt the path in the "*.rc" files. (When you rebuild the project, the compiler will point you to the line). 


# Contact
In case of questions concerning FPulse, you can contact any of these: 

  Peter Jonas <peter.jonas@ist.ac.at>,
  Ulrich Fröbe <ulfroebe@gmail.com>,
  Alois Schlögl <alois.schloegl@ist.ac.at>


# Related tools:
* [Biosig](https://biosig.sourceforge.io/)
* [StimFit](http://stimfit.org)
* [SigViewer](https://github.com/cbrnr/sigviewer)



