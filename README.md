# Introduction

FPulse is a program for patch-clamp recordings. This version FPulse (3.3.3) was build successfully in 2010 for IgorPro 6.x.

If not stated otherwise, all copyrights are with:

```
  Copyright (C) 2001-2021 Ulrich Fröbe, University of Freiburg, Germany
  Copyright (C) 2001-2010 Peter Jonas, University of Freiburg, Germany
  Copyright (C) 2011-2021 Peter Jonas, Institute of Science and Technology, Austria
```

This code is provided under the GPLv3 (see COPYING).

Dependencies on 3rd party tools are listed. This repository is setup mainly for documentation purpose, no active development or support is provided.


### Files from Axon Instruments

Copyright (c) 1999-2004 Axon Instruments.

```
	UserIgor\XOP_Axon\FP_Mc700Tg\MultiClampBroadcastMsg.hpp
	UserIgor\XOP_Axon\FP_Mc700Tg\MCTelegraphs.h
	UserIgor\XOP_Dll\AxMultiClampMsg.dll

```

[Axon MultiClamp commander ](https://axograph.com/download/multi-clamp-commander "Axon MultiClamp Commander")

[Installer of MC700B](http://axograph.com/installers/MultiClamp_2_1_0_16.exe "MC installer for MS-Windows")

* Download and install [MultiClamp Commander 700a]), in the default location, and extract this dll from

```
 c:\Program Files (x86)\Molecular Devices\MultiClamp 700B Commander\3rd Party Support\AxMultiClampMsg\AxMultiClampMsg.dll

```

### Files from Cambridge Electronic Devices (CED)

```

	UserIgor\XOP_Dll\Use1432.dll
	UserIgor\XOP_Dll\CFS32.dll

	UserIgor\XOP_Ced\FPulseCed\Cfs.h
	UserIgor\XOP_Ced\FPulseCed\Cfs.c
	UserIgor\XOP_Ced\FPulseCed\Use1401.h
	UserIgor\XOP_Ced\FPulseCed\MACHINE.H

```
These can be obtained from here:

* Download, and install [1401 Windows Installer](http://ced.co.uk/files/winsupp.exe) in the default location, and extract these files

* Download, and install  [CFS library](http://ced.co.uk/files/MS54.exe) in the default location, and extract these dll

```
   C:\1401\utils\Use1432.dll
   C:\1401\windrv\1432ui.dll
   C:\CFS library\CPP\CFS32.dll
```


# Download:
* sources:

   https://git.ist.ac.at/jonasgroup/FPulse/-/archive/master/FPulse-master.zip

or through git

```
   git clone https://git.ist.ac.at/jonasgroup/FPulse
```


## Installer
	the binaries can be deployed with
```
   install.bat
```


# Build requirements

### Igor XOP toolkit

[XOP toolkit 6](http://www.wavemetrics.net/ecomm/xop/XOPToolkit6.exe "XOP toolkit 6") has been used for the interface been C-code and IgorPro.

[1]: https://www.wavemetrics.com/products/xoptoolkit "XOP toolkit"


### Compiler
   MSVC2015 is known to work. Other compilers are not tested.



# Runtime requirements

- IgorPro 6.x
- MultiClamp 700A or 700B
- CED 1401


