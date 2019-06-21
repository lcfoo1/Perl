::--------------------------------------------------------------------------------------::
::	File Name	: PG_LRB_CorTeX_compile.bat					::
::	Written By	: Foo Lye Cheung						::
::	Revision	: 1.3								::
::	Usage		: Apply only for PG LRB and .NET 2005 				::
::--------------------------------------------------------------------------------------::
::  	Changes:									::
::  	09/08/2007 - Added NHM-UF and HWI-EXT devenv compilation			::
::  		   - Fix typo for CKTM UF devenv compilation				::
::  	10/28/2007 - Added clean project before build for UFs for proper build		::
::  		   - Added build for CKTM instead of rebuild				::
::  	10/29/2007 - Centralize the build logfile					::
::  	11/16/2007 - Added the supercede compilation GEN, OASIS, UFs for Greenlane	::
::  		   									::
::--------------------------------------------------------------------------------------::

SET CORTEXDRIVE=P:
IF EXIST %CORTEXDRIVE%\NUL NET USE %CORTEXDRIVE% /DELETE
NET USE %CORTEXDRIVE% %4 /PERSISTENT:YES

@echo off
cls

Rem Setup VS .NET env-vars to call devenv for .NET 2005
if not defined VCINSTALLDIR (
    call %VS80COMNTOOLS%vsvars32.bat
)

rem revision must be provided
if s%1==s goto error

echo Setting CorTeX directories to %1
echo.

set CORTEX_GEN_DIR=P:\tpapps\CorTeX\GEN\%1
echo Setting GEN to %CORTEX_GEN_DIR%
set CORTEX_OS_DIR=P:\tpapps\CorTeX\OASIS\%1
echo Setting OASIS to %CORTEX_OS_DIR%
set CORTEX_UF_DIR=P:\tpapps\CorTeX\UFs\%1
echo Setting UFs to %CORTEX_UF_DIR%
set GREENLANE_DIR=P:\tpapps\CorTeX\GEN\%1\Greenlane_Details
echo Setting build log to %GREENLANE_DIR%
echo.

rem change to P: drive before compile
P:

rem set the compile level
if s==s%2 set COMPILE_LEVEL=rebuild
if sR==s%2 set COMPILE_LEVEL=rebuild
if sB==s%2 set COMPILE_LEVEL=build

echo compile level = %COMPILE_LEVEL%

rem set debug/release
set DEBUGRELEASE=both
if sRel==s%3 goto release_compile
if sDeb==s%3 goto debug_compile

:release_compile
echo compile type = Release
echo.

cd %CORTEX_GEN_DIR%\code
echo compiling GEN_code Release ...
devenv GEN_code.sln /%COMPILE_LEVEL% Release > %GREENLANE_DIR%\GEN_code_release_result.txt
if EXIST GEN_code.ncb del GEN_code.ncb > NUL

cd %CORTEX_GEN_DIR%\nhm\src\code
echo compiling Evergreen_GEN_Code Release ...
devenv Evergreen_GEN_Code.sln /%COMPILE_LEVEL% Release > %GREENLANE_DIR%\Evergreen_GEN_code_release_result.txt
if EXIST Evergreen_GEN_Code.ncb del Evergreen_GEN_Code.ncb > NUL

cd %CORTEX_GEN_DIR%\Supercede_code
echo compiling Greenlane_GEN_code Release ...
devenv Greenlane_GEN_code.sln /%COMPILE_LEVEL% Release > %GREENLANE_DIR%\Greenlane_GEN_code_release_result.txt
if EXIST Greenlane_GEN_code.ncb del Greenlane_GEN_code.ncb > NUL

cd %CORTEX_OS_DIR%\bin\OASIS_BaseTest
echo compiling BaseTest Release ...
devenv BaseTest.sln /%COMPILE_LEVEL% Release > %GREENLANE_DIR%\BaseTest_code_release_result.txt
if EXIST BaseTest.ncb del BaseTest.ncb > NUL

cd %CORTEX_OS_DIR%\bin\DUTModel
echo compiling iAppDUTModel Release ...
devenv iAppDUTModel.sln /%COMPILE_LEVEL% Release > %GREENLANE_DIR%\iAppDUTModel_code_release_result.txt
if EXIST iAppDUTModel.ncb del iAppDUTModel.ncb > NUL

cd %CORTEX_OS_DIR%\code
echo compiling OASIS_code Release ...
devenv OASIS_code.sln /build Release > %GREENLANE_DIR%\OASIS_code_release_result.txt
if EXIST OASIS_code.ncb del OASIS_code.ncb > NUL

cd %CORTEX_OS_DIR%\nhm\src\code
echo compiling Evergreen_OASIS_code Release ...
devenv Evergreen_OASIS_Code.sln /%COMPILE_LEVEL% Release > %GREENLANE_DIR%\Evergreen_OASIS_code_release_result.txt
if EXIST Evergreen_OASIS_Code.ncb del Evergreen_OASIS_Code.ncb > NUL

cd %CORTEX_OS_DIR%\Supercede_code
echo compiling Greenlane_OASIS_code Release ...
devenv Greenlane_OASIS_code.sln /%COMPILE_LEVEL% Release > %GREENLANE_DIR%\Greenlane_OASIS_code_release_result.txt
if EXIST Greenlane_OASIS_code.ncb del Greenlane_OASIS_code.ncb > NUL

cd %CORTEX_GEN_DIR%\templates
echo compiling GEN_tt templates Release ...
devenv GEN_tt.sln /%COMPILE_LEVEL% Release > %GREENLANE_DIR%\GEN_tt_templates_release_result.txt
if EXIST GEN_tt.ncb del GEN_tt.ncb > NUL

cd %CORTEX_GEN_DIR%\nhm\src\templates
echo compiling Evergreen_GEN_tt templates Release ...
devenv Evergreen_GEN_tt.sln /%COMPILE_LEVEL% Release > %GREENLANE_DIR%\Evergreen_GEN_tt_templates_release_result.txt
if EXIST Evergreen_GEN_tt.ncb del Evergreen_GEN_tt.ncb > NUL

cd %CORTEX_GEN_DIR%\Supercede_templates
echo compiling Greenlane_GEN_tt templates Release ...
devenv Greenlane_GEN_tt.sln /%COMPILE_LEVEL% Release > %GREENLANE_DIR%\Greenlane_GEN_tt_templates_release_result.txt
if EXIST Greenlane_GEN_tt.ncb del Greenlane_GEN_tt.ncb > NUL

cd %CORTEX_OS_DIR%\templates
echo compiling OASIS_tt templates Release ...
devenv OASIS_tt.sln /%COMPILE_LEVEL% Release > %GREENLANE_DIR%\OASIS_tt_templates_release_result.txt
if EXIST OASIS_tt.ncb del OASIS_tt.ncb > NUL

cd %CORTEX_OS_DIR%\nhm\src\templates
echo compiling Evergreen_OASIS_tt templates Release ...
devenv Evergreen_OASIS_tt.sln /%COMPILE_LEVEL% Release > %GREENLANE_DIR%\Evergreen_OASIS_tt_templates_release_result.txt
if EXIST Evergreen_OASIS_tt.ncb del Evergreen_OASIS_tt.ncb > NUL

cd %CORTEX_OS_DIR%\Supercede_templates
echo compiling Greenlane_OASIS_tt templates Release ...
devenv Greenlane_OASIS_tt.sln /%COMPILE_LEVEL% Release > %GREENLANE_DIR%\Greenlane_OASIS_tt_templates_release_result.txt
if EXIST Greenlane_OASIS_tt.ncb del Greenlane_OASIS_tt.ncb > NUL

cd %CORTEX_UF_DIR%\nhm\CPD-UF
echo compiling Evergreen CPD UFs Release ...
devenv CPD_UF.sln /clean
devenv CPD_UF.sln /%COMPILE_LEVEL% Release > %GREENLANE_DIR%\Evergreen_CPD_UFs_release_result.txt
if EXIST CPD_UF.ncb del CPD_UF.ncb > NUL

cd %CORTEX_UF_DIR%\nhm\nhm-uf
echo compiling Evergreen NHM UFs Release ...
devenv NHM_UF.sln /clean
devenv NHM_UF.sln /%COMPILE_LEVEL% Release > %GREENLANE_DIR%\Evergreen_NHM_UFs_release_result.txt
if EXIST NHM_UF.ncb del NHM_UF.ncb > NUL

cd %CORTEX_UF_DIR%\nhm\hwi-ext
echo compiling Evergreen HWI EXT UFs Release ...
devenv HWI_UF.sln /%COMPILE_LEVEL% Release > %GREENLANE_DIR%\Evergreen_HWI_UFs_release_result.txt
if EXIST HWI_UF.ncb del HWI_UF.ncb > NUL

cd %CORTEX_UF_DIR%\cktm\src
echo compiling CKTM UFs Release ...
devenv CKTM_UFs.sln /clean
devenv CKTM_UFs.sln /build Release > %GREENLANE_DIR%\CKTM_UFs_release_result.txt
if EXIST CKTM_UFs.ncb del CKTM_UFs.ncb > NUL

cd %CORTEX_UF_DIR%\src
echo compiling Greenlane_UFs Release ...
devenv Greenlane_UFs.sln /clean
devenv Greenlane_UFs.sln /build Release > %GREENLANE_DIR%\Greenlane_UFs_release_result.txt
if EXIST Greenlane_UFs.ncb del Greenlane_UFs.ncb > NUL

if sRel==s%3 goto end

:debug_compile
echo compile type = Debug
echo.

cd %CORTEX_GEN_DIR%\code
echo compiling GEN_code Debug ...
devenv GEN_code.sln /%COMPILE_LEVEL% Debug > %GREENLANE_DIR%\GEN_code_debug_result.txt
if EXIST GEN_code.ncb del GEN_code.ncb > NUL

cd %CORTEX_GEN_DIR%\nhm\src\code
echo compiling Evergreen_GEN_Code Debug ...
devenv Evergreen_GEN_Code.sln /%COMPILE_LEVEL% Debug > %GREENLANE_DIR%\Evergreen_GEN_code_debug_result.txt
if EXIST Evergreen_GEN_Code.ncb del Evergreen_GEN_Code.ncb > NUL

cd %CORTEX_GEN_DIR%\Supercede_code
echo compiling Greenlane_GEN_code Debug ...
devenv Greenlane_GEN_code.sln /%COMPILE_LEVEL% Debug > %GREENLANE_DIR%\Greenlane_GEN_code_debug_result.txt
if EXIST Greenlane_GEN_code.ncb del Greenlane_GEN_code.ncb > NUL

cd %CORTEX_OS_DIR%\bin\OASIS_BaseTest
echo compiling BaseTest Debug ...
devenv BaseTest.sln /%COMPILE_LEVEL% Debug > %GREENLANE_DIR%\BaseTest_code_debug_result.txt
if EXIST BaseTest.ncb del BaseTest.ncb > NUL

cd %CORTEX_OS_DIR%\bin\DUTModel
echo compiling iAppDUTModel Debug ...
devenv iAppDUTModel.sln /%COMPILE_LEVEL% Debug > %GREENLANE_DIR%\iAppDUTModel_code_debug_result.txt
if EXIST iAppDUTModel.ncb del iAppDUTModel.ncb > NUL

cd %CORTEX_OS_DIR%\code
echo compiling OASIS_code Debug ...
devenv OASIS_code.sln /%COMPILE_LEVEL% Debug > %GREENLANE_DIR%\OASIS_code_debug_result.txt
if EXIST OASIS_code.ncb del OASIS_code.ncb > NUL

cd %CORTEX_OS_DIR%\nhm\src\code
echo compiling Evergreen_OASIS_code Debug ...
devenv Evergreen_OASIS_Code.sln /%COMPILE_LEVEL% Debug > %GREENLANE_DIR%\Evergreen_OASIS_code_debug_result.txt
if EXIST Evergreen_OASIS_Code.ncb del Evergreen_OASIS_Code.ncb > NUL

cd %CORTEX_OS_DIR%\Supercede_code
echo compiling Greenlane_OASIS_code Debug ...
devenv Greenlane_OASIS_code.sln /%COMPILE_LEVEL% Debug > %GREENLANE_DIR%\Greenlane_OASIS_code_debug_result.txt
if EXIST Greenlane_OASIS_code.ncb del Greenlane_OASIS_code.ncb > NUL

cd %CORTEX_GEN_DIR%\templates
echo compiling GEN_tt templates Debug ...
devenv GEN_tt.sln /%COMPILE_LEVEL% Debug > %GREENLANE_DIR%\GEN_tt_templates_debug_result.txt
if EXIST GEN_tt.ncb del GEN_tt.ncb > NUL

cd %CORTEX_GEN_DIR%\nhm\src\templates
echo compiling Evergreen_GEN_tt templates Debug ...
devenv Evergreen_GEN_tt.sln /%COMPILE_LEVEL% Debug > %GREENLANE_DIR%\Evergreen_GEN_tt_templates_debug_result.txt
if EXIST Evergreen_GEN_tt.ncb del Evergreen_GEN_tt.ncb > NUL

cd %CORTEX_GEN_DIR%\Supercede_templates
echo compiling Greenlane_GEN_tt templates Debug ...
devenv Greenlane_GEN_tt.sln /%COMPILE_LEVEL% Debug > %GREENLANE_DIR%\Greenlane_GEN_tt_templates_debug_result.txt
if EXIST Greenlane_GEN_tt.ncb del Greenlane_GEN_tt.ncb > NUL

cd %CORTEX_OS_DIR%\templates
echo compiling OASIS_tt templates Debug ...
devenv OASIS_tt.sln /%COMPILE_LEVEL% Debug > %GREENLANE_DIR%\OASIS_tt_templates_debug_result.txt
if EXIST OASIS_tt.ncb del OASIS_tt.ncb > NUL

cd %CORTEX_OS_DIR%\nhm\src\templates
echo compiling Evergreen_OASIS_tt templates Debug ...
devenv Evergreen_OASIS_tt.sln /%COMPILE_LEVEL% Debug > %GREENLANE_DIR%\Evergreen_OASIS_tt_templates_debug_result.txt
if EXIST Evergreen_OASIS_tt.ncb del Evergreen_OASIS_tt.ncb > NUL

cd %CORTEX_OS_DIR%\Supercede_templates
echo compiling Greenlane_OASIS_tt templates Debug ...
devenv Greenlane_OASIS_tt.sln /%COMPILE_LEVEL% Debug > %GREENLANE_DIR%\Greenlane_OASIS_tt_templates_debug_result.txt
if EXIST Greenlane_OASIS_tt.ncb del Greenlane_OASIS_tt.ncb > NUL

cd %CORTEX_UF_DIR%\nhm\CPD-UF
echo compiling Evergreen CPD UFs Debug ...
devenv CPD_UF.sln /clean
devenv CPD_UF.sln /%COMPILE_LEVEL% Debug > %GREENLANE_DIR%\Evergreen_CPD_UFs_debug_result.txt
if EXIST CPD_UF.ncb del CPD_UF.ncb > NUL

cd %CORTEX_UF_DIR%\nhm\nhm-uf
echo compiling Evergreen NHM UFs Debug ...
devenv NHM_UF.sln /clean
devenv NHM_UF.sln /%COMPILE_LEVEL% Debug > %GREENLANE_DIR%\Evergreen_NHM_UFs_debug_result.txt
if EXIST NHM_UF.ncb del NHM_UF.ncb > NUL

cd %CORTEX_UF_DIR%\nhm\hwi-ext
echo compiling Evergreen HWI EXT UFs Debug ...
devenv HWI_UF.sln /clean
devenv HWI_UF.sln /%COMPILE_LEVEL% Debug > %GREENLANE_DIR%\Evergreen_HWI_UFs_debug_result.txt
if EXIST HWI_UF.ncb del HWI_UF.ncb > NUL

cd %CORTEX_UF_DIR%\cktm\src
echo compiling CKTM UFs Debug ...
devenv CKTM_UFs.sln /clean
devenv CKTM_UFs.sln /build Debug > %GREENLANE_DIR%\CKTM_UFs_debug_result.txt
if EXIST CKTM_UFs.ncb del CKTM_UFs.ncb > NUL

cd %CORTEX_UF_DIR%\src
echo compiling Greenlane_UFs Debug ...
devenv Greenlane_UFs.sln /clean
devenv Greenlane_UFs.sln /build Debug > %GREENLANE_DIR%\Greenlane_UFs_debug_result.txt
if EXIST Greenlane_UFs.ncb del Greenlane_UFs.ncb > NUL

goto end


:error
C:
echo *******************************************************
echo ** ERROR - Cortex revision to compile must be provided
echo *******************************************************


:end
C:
echo.




