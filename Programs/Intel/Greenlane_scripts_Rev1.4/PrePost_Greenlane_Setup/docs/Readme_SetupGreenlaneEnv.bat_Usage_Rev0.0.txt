Developer: Foo Lye Cheung			
Groups: PG PDE CPU (TMM)	
Date release: 30 June 2007				
Inet: 604-2536452
Revision: Rev0.0


SetupGreenlaneEnv.bat usage:
=============================
The script will change the revision .vcproj for Greenlane directory structure. The script need to run before compiling Greenlane suite


Steps to change CorTeX revision for release purpose:
====================================================
1. Download the Greenlane from release area.
2. Unzip the Greenlane and rename the directory to new Greenlane revision
3. Edit the configuration.txt for Greenlane root directory and new Greenlane revision
4. Run script - SetupGreenlaneEnv.bat
5. All Greenlane .vcproj file are changed to new revision and ready for Greenlane compilation

SetupGreenlaneEnv.bat will call 3 scripts:
==========================================
1. src\PG_CorTeX_Rev_Rev1.2.pl - change/upgrade VTS CorTeX environment to Greenlane environment
2. src\Evergreen_PG_CorTeX_Rev1.3.pl - change/upgrade Evergreen environment to Greenlane environment
3. src\Greenlane_PG_CorTeX_Rev_Rev1.2.pl - change/upgrade Greenlane environment to Greenlane environment


Content in configuration.txt (see example in the directory)
===========================================================
1. Greenlane root directory (eg. Root=C:\intel\tpapps\CorTeX whereby keyword is Root=)
2. Greenlane new revision (eg. Revision=GLN_Rev4.12.0_PG1.0 whereby keyword is Revision=)


Example of the usage in Window:
===============================
SetupGreenlaneEnv.bat






