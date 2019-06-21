SET JFDRIVE=Z:
Rem SET PGDRIVE=N:

IF EXIST %JFDRIVE%\NUL NET USE %JFDRIVE% /DELETE
Rem IF EXIST %PGDRIVE%\NUL NET USE %PGDRIVE% /DELETE
NET USE %JFDRIVE% \\pdxsmb.pdx.intel.com\samba\pdx\pdel\intel\d01\tpapps\CorTeX\TMM_Local\nhm\gns\evg /PERSISTENT:YES
REM NET USE %PGDRIVE% \\gar\ec\proj\my\deg\pde\wmtpe282\lfoo1\cmtprogs\cwa /PERSISTENT:YES
Rem NET USE %PGDRIVE% \\pdxsmb.pdx.intel.com\samba\pdx\pdel\intel\d01\tpapps\CorTeX\TMM_Local\nhm\gns\evg /PERSISTENT:YES


