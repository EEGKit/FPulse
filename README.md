# Introduction

FPulse is a program for patch-clamp recordings. This version FPulse 3.x  was build successfully for IgorPro 6.x.

If not stated otherwise, all copyrights are with:

```
  Copyright (C) 2001-2021 Ulrich Fröbe, University of Freiburg, Germany
  Copyright (C) 2001-2010 Peter Jonas, University of Freiburg, Germany
  Copyright (C) 2011-2021 Peter Jonas, Institute of Science and Technology, Austria
```

This code is provided under the GPLv3 (see COPYING).

The Copyright does not apply to these files (instructions for downloading these from the vendor are shown further):

```
	.\UserIgor\XOP_Axon\FP_Mc700Tg\MultiClampBroadcastMsg.hpp
	.\UserIgor\XOP_Axon\FP_Mc700Tg\MCTelegraphs.h

	.\UserIgor\XOP_Dll\AxMultiClampMsg.dll
	.\UserIgor\XOP_Dll\Use1432.dll
	.\UserIgor\XOP_Dll\CFS32.dll

	.\UserIgor\XOP_Ced\FPulseCed\CFS32.lib
	.\UserIgor\XOP_Ced\FPulseCed\Use1432.lib
	.\UserIgor\XOP_Ced\FPulseCed\Cfs.h
	.\UserIgor\XOP_Ced\FPulseCed\Cfs.c
	.\UserIgor\XOP_Ced\FPulseCed\Use1401.h
	.\UserIgor\XOP_Ced\FPulseCed\MACHINE.H
```

This repository is setup mainly for documentation purpose, no active development or support is provided.


# Installing FPulse
* Prerequisites are
    - MS Windows (XP or later)
	- IgorPro 6.x
	- MultiClamp 700A or 700B
	- CED 1401

* Download and unzip

   https://git.ist.ac.at/jonasgroup/FPulse/-/archive/master/FPulse-master.zip

or use git

```
   git clone https://git.ist.ac.at/jonasgroup/FPulse
```

* The binaries can be deployed by running
```
   install.bat
```
in a "cmd" shell with administrative permissions.



# Build requirements

### Igor XOP toolkit

[XOP toolkit 6](http://www.wavemetrics.net/ecomm/xop/XOPToolkit6.exe "XOP toolkit 6") has been used for the interface been C-code and IgorPro.

[1]: https://www.wavemetrics.com/products/xoptoolkit "XOP toolkit"


### Compiler
   MSVC2015 is known to work. Other compilers are not tested.


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


https://docs.microsoft.com/en-us/cpp/build/reference/i-additional-include-directories?view=msvc-160
To set this compiler option in the Visual Studio development environment

- Open the project's Property Pages dialog box. For details, see Set C++ compiler and build properties in Visual Studio.

- Select the Configuration Properties > C/C++ > General property page.

- Modify the Additional Include Directories property and add 
```
   <yourdir>\XOP Toolkit 6\IgorXOPs6\XOPSupport\
```

You might also need to adapt the path in the "*.rc" files. (When you rebuild the project, the compiler will point you to the line). 

### Files from _Axon Instruments_ and _Cambridge Electronic Devices (CED)_

These the files are currently also in the [repository]
[2]:

```
	.\UserIgor\XOP_Axon\FP_Mc700Tg\MultiClampBroadcastMsg.hpp
	.\UserIgor\XOP_Axon\FP_Mc700Tg\MCTelegraphs.h

	.\UserIgor\XOP_Dll\AxMultiClampMsg.dll
	.\UserIgor\XOP_Dll\Use1432.dll
	.\UserIgor\XOP_Dll\CFS32.dll

	.\UserIgor\XOP_Ced\FPulseCed\CFS32.lib
	.\UserIgor\XOP_Ced\FPulseCed\Use1432.lib
	.\UserIgor\XOP_Ced\FPulseCed\Cfs.h
	.\UserIgor\XOP_Ced\FPulseCed\Cfs.c
	.\UserIgor\XOP_Ced\FPulseCed\Use1401.h
	.\UserIgor\XOP_Ced\FPulseCed\MACHINE.H
```

So from a technical reason you might not need them. But you might want to use them legal reasons, or in case we are now allowed to redistribute them. 

* Download, and install [1401 Windows Installer](http://ced.co.uk/files/winsupp.exe) in the default location (C:\1401\), and extract C:\1401\utils\Use1432.dll these files

* Download, and install  [CFS library](http://ced.co.uk/files/MS54.exe) in the default location (C:\CFS library\), and extract C:\CFS Library\CPP\CFS32.dll

* xDownload and install [Installer of MC700B](http://axograph.com/installers/MultiClamp_2_1_0_16.exe), in the default location (C:\Program Files (x86)\Molecular Devices\MultiClamp 700B Commander), and extract AxMultiClampMsg.dll from




# Contact
In case of questions concerning FPulse, you can contact any of these: 

  Peter Jonas <peter.jonas@ist.ac.at>,
  Ulrich Fröbe <ulfroebe@gmail.com>,
  Alois Schlögl <alois.schloegl@ist.ac.at>




