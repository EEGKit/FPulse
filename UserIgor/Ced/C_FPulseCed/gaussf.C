//-------------------------------------------------------------------------
//
//  GaussF.C     Gauss-Filter-Routine  for  Mathematica  
//
//  after Sigworth & Colquhoun, Single Channel Recording, App.3
//
//  Compile this file and 'GaussF.TM'  with  'GaussFil.BAT' (Microsoft C)
//
//  To launch this program from within Mathematica Notebook use:
//
//    addlink = Install["C:\\MATH3PRG\\GAUSSFIL\\GaussF"]
//    outReal = GaussFilterReal[ inReal, outReal, .015, 1 ]; 
//    Uninstall[addlink]
//
//  See "GAUSSF.NB" for a sample Mathematica Notebook 
//
//  U Froebe, 1097
//
//  0899  umgebaut fÅr Mathematica/Mathlink Version3+4    
//
//-------------------------------------------------------------------------

//#include "mathlink.h"                                       // V223
#include "\MATHLINK\WINDOWS\COMPILERADDITIONS\MLDEV32\INCLUDE\MATHLINK.H" // V3


#include <stdio.h>
#include <stdlib.h>
#include <math.h>


#define MAXFILTERCOEFFS  220


int setGaussFilter( double frequency, double *coeffs )

// Load the filter coefficient values according to the cutoff
// frequency (in units of the sample frequency) given
{
   double b, sum, sigma = 0.132505 / frequency;
   int    i, numCoeffs;

   if ( sigma < 0.62 ) {                // light filtering
      coeffs[1] = 0.5 * sigma * sigma;
      coeffs[0] =  1. - sigma * sigma;
      numCoeffs = 1;
   }
   else {                               // normal filtering
      numCoeffs = (int)( 4. * sigma );
      if ( numCoeffs > MAXFILTERCOEFFS ) {
         fprintf( stderr, "SetGaussFilter: Too many coefficients: %d (max %d) ",
                           numCoeffs , MAXFILTERCOEFFS );  
         numCoeffs = MAXFILTERCOEFFS;
      }

      b = -1. / ( 2. * sigma * sigma );

      // First make the sum for normalization..
      sum = .5;
      for ( i = 1; i <= numCoeffs; i++ ) 
         sum += exp( b * i * i );
      sum *= 2.;
   
      // Now compute the actual coefficients
      coeffs[0] = 1. / sum;
      for ( i = 1; i <= numCoeffs; i++ ) 
         coeffs[i] = exp( b * i * i ) / sum;
   }
   return( numCoeffs );
}


//void  gaussFilterReal( ml_doublep pin, long nin, ml_doublep pout, long nout,
void  gaussFilterReal( double* pin, long nin, double* pout, long nout,
                       double frequency, int compression )

// From in-array create filtered out-array
// Real 'freq' is corner frequency in units of the sample frequency. 
// Integer 'compression' shrinks 'out' array size. 
// Number of 'out' points is number of 'in' points divided by compression. 
{
   long    i0, i, j, jmax, jmin;
   double  sum;
   double  coeffs[MAXFILTERCOEFFS+1];  

   int     numCoeffs =   setGaussFilter( frequency, coeffs );

   compression = max( 1, compression );

   for ( i0 = 0; i0 < nin / compression; i0++ ) {
    
      i = i0 * compression;

      jmax = jmin = numCoeffs;
      
      // Make sure we stay within bounds of the input array
      jmin = ( i < jmin ) ? i : jmin;

      jmax = ( jmax >= nin - i ) ? nin - i - 1 : jmax;

      sum  = coeffs[0] * pin[i];        // central point

      for ( j = 1; j <= jmin; j++ ) 
         sum += coeffs[j] * pin[i-j];   // early points

      for ( j = 1; j <= jmax; j++ ) 
         sum += coeffs[j] * pin[i+j];   // late  points

      pout[i0] = sum;                   // Assign the output value
   }
   MLPutRealList( stdlink, pout, nout);
}


//void  gaussFilterInt( ml_intp pin, long nin, ml_intp pout, long nout,
void  gaussFilterInt( int* pin, long nin, int* pout, long nout,
                      double frequency, int compression )

// From in-array create filtered out-array
// Real 'freq' is corner frequency in units of the sample frequency. 
// Integer 'compression' shrinks 'out' array size. 
// Number of 'out' points is number of 'in' points divided by compression. 
{
   long    i0, i, j, jmax, jmin;
   double  sum;
   double  coeffs[MAXFILTERCOEFFS+1];  

   int     numCoeffs =   setGaussFilter( frequency, coeffs );

   compression = max( 1, compression );

   for ( i0 = 0; i0 < nin / compression; i0++ ) {
    
      i = i0 * compression;

      jmax = jmin = numCoeffs;
      
      // Make sure we stay within bounds of the input array
      jmin = ( i < jmin ) ? i : jmin;

      jmax = ( jmax >= nin - i ) ? nin - i - 1 : jmax;

      sum  = coeffs[0] * pin[i];        // central point

      for ( j = 1; j <= jmin; j++ ) 
         sum += coeffs[j] * pin[i-j];   // early points

      for ( j = 1; j <= jmax; j++ ) 
         sum += coeffs[j] * pin[i+j];   // late  points

      pout[i0] = (int)( sum > 0 ? sum+.5 : sum-.5 ) ;// Assign the output value
   }
   MLPutIntegerList( stdlink, pout, nout);
}



#if !WINDOWS_MATHLINK

int main( int argc, char* argv[] )
{
   return MLMain(argc, argv);
}

#else

int PASCAL WinMain( HINSTANCE hinstCurrent, HINSTANCE hinstPrevious, LPSTR lpszCmdLine, int nCmdShow)
{
   char  buff[512];
   char FAR * argv[32];
   int argc;

   if( !MLInitializeIcon( hinstCurrent, nCmdShow)) 
      return 1;
   argc = MLStringToArgv( lpszCmdLine, buff, argv, 32);
   return MLMain( argc, argv);
}
#endif

