@setLocal
@echo off
rem get vs tools
call ms\setVSVars.bat VS14VC
call "%_VS14VC%\vcvarsall" x86

rem create VS Project
if not exist vsout mkdir vsout

rem INITONCE common preprocessing across configurations
set INITONCE=YES

copy ms\vstemplates\vstemplates14.sln vsout\openSSL.sln
call:makeProject Universal 10.0 Static Unicode 5BAD3295-3CC2-4416-A65F-16B304654800 C4F0CF4C-F240-4E23-B520-026FFDDEB43A
call:makeProject Universal 10.0 Dll    Unicode 5C2E2BD9-44D0-411E-B46C-E9129B8F94187 EA1A3F14-D6FD-49CC-B0F1-416E60FA593A

goto :eof

:makeProject
	set PROJECTLOC=NT-%1-%2-%3-%4
	if not exist vsout\%PROJECTLOC% mkdir vsout\%PROJECTLOC%
	if not exist vsout\%PROJECTLOC%-testapp mkdir vsout\%PROJECTLOC%-testapp
	xcopy ms\vstemplates\OpenSSLTestApp%1%2 vsout\%PROJECTLOC%-testapp /h /k /r /e /i /y >nul
	xcopy ms\vstemplates\Makefile%1 vsout\%PROJECTLOC% /h /k /r /e /i /y >nul

	call:makeConfiguration %1 %2 %3 %4 Debug   Win32
	call:makeConfiguration %1 %2 %3 %4 Debug   arm
	call:makeConfiguration %1 %2 %3 %4 Debug   x64
	call:makeConfiguration %1 %2 %3 %4 Release Win32
	call:makeConfiguration %1 %2 %3 %4 Release arm
	call:makeConfiguration %1 %2 %3 %4 Release x64
	perl ms\do_vsproject.pl %1 %2 %3 %4 %5 %6
	goto :eof

:makeConfiguration
	set EXTRAFLAGS=
	set Dll=
	if "%1"=="Universal" set VC-CONFIGURATION=VC-WINUNIVERSAL
	if "%3"=="Dll" set Dll=dll
	if "%4"=="Unicode" set EXTRAFLAGS=%EXTRAFLAGS% -DUNICODE -D_UNICODE
	if "%5"=="Debug" set EXTRAFLAGS=%EXTRAFLAGS% -Zi -Od
	if not exist vsout\%PROJECTLOC%\%5\%6\tmp mkdir vsout\%PROJECTLOC%\%5\%6\tmp
	if not exist vsout\%PROJECTLOC%\%5\%6\bin mkdir vsout\%PROJECTLOC%\%5\%6\bin	
	echo creating project vsout\%PROJECTLOC%
	rem goto :doProject
	perl Configure no-asm no-hw no-dso %VC-CONFIGURATION% %EXTRAFLAGS%
	perl util\mkfiles.pl >MINFO
	perl util\mk1mf.pl no-asm %Dll% %VC-CONFIGURATION%>vsout\%PROJECTLOC%\nt-%5-%6.mak
	if "%INITONCE%"=="YES" call :initonce vsout\%PROJECTLOC%\nt-%5-%6.mak
goto :eof

:initonce
	rem common setup across configurations
	perl util\mkdef.pl crypto ssl update
	perl util\mkdef.pl 32 libeay > %TMP%\libeay32.def
	rem patch for building DLL build.
	perl -ne "print unless /ENGINE_load_rsax/" %TMP%\libeay32.def > ms\libeay32.def
	perl util\mkdef.pl 32 ssleay > ms\ssleay32.def
	nmake -f %1 init
	set INITONCE=
goto :eof
