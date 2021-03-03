PULSE	
Protocol:	Name	= "AAManyChans"
//PoN:		Src = 3;		
Dac:		Chan = 0;		SmpInt = 50; Gain=.5; Units=mv; Name=Da0//; Src=0
Adc:		Chan = 0;		SmpInt = 50; Units=pA;TGChan=5; Name = isTG5
Adc:		Chan = 1;		SmpInt = 50;	Name=RS;  TGChan=6
Dac:		Chan = 1;		SmpInt = 50; Gain=2; RGB=( 63000,35000,10000)
//Sum:		Src=Dac1,Adc3;
PoN:		Src = 0;		
Aver:		Src = Dac0;		Name=SumOfD0
//Adc:		Chan = 3;		SmpInt = 50; TGMCChan=1

Adc:		Chan = 2;		SmpInt = 50; Gain=10
//Adc:		Chan = 3;		SmpInt = 50;				// chan 3 defined twice should trigger warning

Frames:	N	=2////11// 1 prot x 6 frames  WORKS,   6 prot x 1 frame FAILS   031006
Sweeps:	N	=2; PoN=1         
Ramp:	Dac	= 0, 1100;	Amp	=    -5200,1,400 
Segment:Dac= 1, 1100;	Amp	=    -5000,1,400 
Ramp:	Dac	= 0, 1100;	Amp	=    0
Segment:Dac= 1, 3300;	Amp	=    0 
EndSweep
Blank:	Dac=0, 2200
EndFrame 
Blank:	Dac=0, 11000
