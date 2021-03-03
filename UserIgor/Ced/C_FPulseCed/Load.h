/*********************************************************************
** Include file to define LOAD interface to CED 1401
**
** Copyright Cambridge Electronic Design 1987
**
** Revision History
** 13-Feb-87 GPS  This is the first version
** 08-Apr-87 GPS  Lattice C version added
** 15-Nov-90 JCN  1)get1401info added
**                2)open1401 returns error codes (true and false reversed)
**                3)ld       ditto
**                4)function declarations brought up to modern standards.
**                  They are now the same in load.h, load.c and the doc.
** 02/Dec/92 GPS  Lattice C special code all removed.
**
** 13/Jan/97 KJ   Addition of the following routines:
**                  1. int  send1401Str(char* pstr)
**                  2. int  get1401Str(char* pstr, int imax)
**                  3. void unSetseg()
**                  4. void kill1401()
** 04/Jun/97 GPS  Now works under Windows NT
**
**********************************************************************
*/
#ifndef __LOAD__
#define __LOAD__

//#include <winioctl.h>

#include <stdio.h>


int  open1401(void);
void close1401(void);
int  wait1401(unsigned short wTimeout);
int  stat1401(void);
void setseg(char *);
void unSetseg();
int  ldcmd(char *command);
int  ld(char *vl,char *str);
int  tohost(char *  object,unsigned long size,unsigned long addr1401);
int  to1401(char * object,unsigned long size,unsigned long addr1401);
int  send1401Str(char* pstr);
int  get1401Str (char* pstr, int imax);
void reset1401(void);
void flush1401(void);
void stopCircular();
void kill1401();
unsigned int dumpXfer(unsigned short dump);
void get1401info(int *rev, int *bus, int *type1401, int *state);

#endif
