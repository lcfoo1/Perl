
::--------------------------------------------------------------------------------------::
::	File Name	: SetupGreenlaneEnv.bat.bat					::
::	Written By	: Foo Lye Cheung						::
::	Revision	: 1.0								::
::	Usage		: Setup Greenlane directory					::
::	Date		: 3 January 2008						::
::--------------------------------------------------------------------------------------::
::  	Descriptions									::
::  	Setup default Greenlane directory structure					::
::  		   									::
::--------------------------------------------------------------------------------------::
@echo off

echo Setting up default Greenlane directory structure
chdir src
GreenlaneDir_Rev1.0.pl
chdir ..
echo Done...

PAUSE

