@echo off
rem ==========================================================================
rem  ASTB Studio (Java) build: plain javac + jar, no third-party libs.
rem  Product: dist\ASTBStudio.jar (runnable, Main-Class in manifest)
rem ==========================================================================
setlocal
set "JDK=C:\Program Files\Amazon Corretto\jdk21.0.10_7\bin"
cd /d %~dp0

if exist build rmdir /s /q build
if exist dist rmdir /s /q dist
mkdir build dist

dir /s /b src\*.java > sources.txt
"%JDK%\javac.exe" -encoding UTF-8 -d build @sources.txt
if errorlevel 1 (
    echo BUILD FAILED
    exit /b 1
)

rem bundle resources (app icon etc.) into the jar
if exist src\astb\studio\resources xcopy /e /i /y /q src\astb\studio\resources build\astb\studio\resources >nul

> manifest.mf echo Main-Class: astb.studio.Main
"%JDK%\jar.exe" cfm dist\ASTBStudio.jar manifest.mf -C build .
if errorlevel 1 (
    echo JAR FAILED
    exit /b 1
)

echo OK: dist\ASTBStudio.jar
endlocal
