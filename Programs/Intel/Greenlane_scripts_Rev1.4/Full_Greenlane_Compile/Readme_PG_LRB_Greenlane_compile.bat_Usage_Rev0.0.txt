Developer: Foo Lye Cheung			
Groups: PG PDE CPU (TMM)	
Date release: 30 June 2007				
Inet: 604-2536452
Revision: Rev0.0


PG_LRB_Greenlane_compile.bat usage:
=============================
The batch file will compile do full Greenlane compilation.



Usage:
=====
PG_LRB_Greenlane_compile.bat <Greenlane Revision> <Mode R/B> <Dll generated in Rel/Deb> <Greenlane path to map drive to P: drive>

Explanations:
---------------
<Greenlane Revision>
	- Revision of the Greenlane to build
<Mode R or B>
- R – rebuild
- B - build

<Dll generated in Rel/Deb>
- Rel – Release
- Deb – Debug

<Greenlane path to map drive to P: drive>
- Greenlane path where P: drive will map and CorTeX will compile



Example of the usage in Window:
========================
PG_LRB_Greenlane_compile.bat GLN_Rev4.12.0_PG1.0 R Rel \\lfoo1-MOBL\c$\Development\intel
