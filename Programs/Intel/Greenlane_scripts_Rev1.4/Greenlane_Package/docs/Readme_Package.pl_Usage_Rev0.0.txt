Developer: Foo Lye Cheung			
Groups: PG PDE CPU (TMM)	
Date release: 30 June 2007				
Inet: 604-2536452
Revision: Rev0.0
												
														
How to use the script:
======================

Help:
-----
Usage: C:\intel\tpapps\Greenlane_scripts_Rev1.3\Greenlane_Package\Package.pl [-h] [-s <Source Dir>] [-f <Zipfile Dir/Filename>] [-r <Greenlane Rev>]
-h                      : This (help) message
-s <Source Dir>         : Source directory of files to zipped
-f <Zipfile>            : zip filename
-r <Greenlane Rev>      : Greenlane revision


Example: C:\intel\tpapps\Greenlane_scripts_Rev1.3\Greenlane_Package\Package.pl [-h] [-s <Source Dir>] [-f <Zipfile Dir/Filename>] [-r <Greenlane Rev>]


Example of the usage in Window:
-------------------------------
Package.pl  -s C:\Development\intel\tpapps\CorTeX -f C:\intel\Perl\Programs\Greenlane_scripts_Rev1.3\Greenlane_Package\Release\GLN_Rev4.12.0_PG1.0.zip -r GLN_Rev4.12.0_PG1.0


Example of the usage in UNIX:
-------------------------------
perl Package.pl -s /nfs/png/disks/wmtpe282/intel/tpapps/Release/IDC_CorTeX -f /nfs/png/disks/png_pdcpde_n16336/lfoo1/work/test/zip/Rev3.7.0v11p0e3p1.zip -r Rev3.7.0v11p0e3p1


Explanation:
=========
-s : where the main Greenlane directory
-f : the zip file that you want to create, eg. /nfs/png/disks/png_pdcpde_n16336/lfoo1/work/test/zip/Rev3.7.0v11p0e3p1.zip
-r : Revision, where it will be a search key that will search all files/directory structure which has the revision defined

 