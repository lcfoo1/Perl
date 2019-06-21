SET FMDRIVE=M:
SET PGDRIVE=N:

IF EXIST %FMDRIVE%\NUL NET USE %FMDRIVE% /DELETE
IF EXIST %PGDRIVE%\NUL NET USE %PGDRIVE% /DELETE
NET USE %FMDRIVE% \\fmsamba12\root\nfs\fm\disks\fm_fdcpde_n19005\cmt_I_drive\cmtprogs\CWMA\staging /PERSISTENT:YES
REM NET USE %PGDRIVE% \\gar\ec\proj\my\deg\pde\wmtpe282\lfoo1\cmtprogs\cwa /PERSISTENT:YES
NET USE %PGDRIVE% \\gar\ec\proj\my\deg\pde\png_pdcpde_n16336\lfoo1\Win2k\cmtprogs\cwa /PERSISTENT:YES


