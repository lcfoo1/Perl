::--------------------------------------------------------------------------------------::
::	File Name	: SetupGreenlaneEnv.bat.bat					::
::	Written By	: Foo Lye Cheung						::
::	Revision	: 1.4								::
::	Usage		: Setup Greenlane code suite environment for C++ compilation	::
::	Date		: 3 January 2008						::
::--------------------------------------------------------------------------------------::
::  	Descriptions									::
::  	Consists of 4 Perl scripts and execute in sequence as below:			::
::  	1. PG_CorTeX_Rev_Rev1.2.pl							::
::  	2. Evergreen_PG_CorTeX_Rev1.4.pl						::
::  	3. Greenlane_PG_CorTeX_Rev_Rev1.4.pl						::
::  	Require to configure input file configuration.txt for Revision			::
::  		   									::
::--------------------------------------------------------------------------------------::
@echo off

echo Setting up VTS base CorTeX in Greenlane environment
chdir src
PG_CorTeX_Rev_Rev1.2.pl
chdir ..\src
echo Setting up Evergreen code in Greenlane environment
Evergreen_PG_CorTeX_Rev1.4.pl
chdir ..\src
echo Setting up Greenlane code in Greenlane environment
Greenlane_PG_CorTeX_Rev_Rev1.4.pl
chdir ..
echo Done...

PAUSE

