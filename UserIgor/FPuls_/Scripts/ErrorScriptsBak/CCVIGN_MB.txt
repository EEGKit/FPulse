// C:UserIgor:Scripts:IVCC.txt   18.10.02

// Syntax:  [ Dig =  Ch, Dur, Del, DDur, DDel ]
// Syntax: Segment/Blank..  :	Dac =  Ch, Dur, A/R,Del ;  Amp	= 	Amp, Scl, DAmp, DDur	

// current clamp VI relation 

PULSE	
Protocol:	Name	= "IVCC"
Adc:		Chan = 0;		SmpInt = 25; TGChan=5; RGB=(50000,0,0); Units =mV
//Adc:		Chan = 7;		SmpInt = 25; TGChan=6; RGB=(50000,0,0); Units =mV
Dac:		Chan = 0;		SmpInt = 25; Gain = 0.5; RGB=(0,50000,0); Units =mV// postsynaptic cell
//PoN:         	Src = 0; Units =mV

Frames:	N	=27
Sweeps: N = 1        
Segment:	Dac	= 0, 200	
Segment:	Dac = 0, 1000;	Amp	=1000,1,-50;            Dig= 1, 1.5, -1     // in pA -20,1,-2 default
Segment:	Dac	= 0, 700;	Amp	=    0
EndSweep
Blank:	Dac	= 0, 15000			  // IFI
EndFrame 

//I-clamp:  2nA/V, das ergibt bei einer gain = 0.5 und Amplitude von 10 mV einen Strom von 20 pA.