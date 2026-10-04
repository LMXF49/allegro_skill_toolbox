@echo off
rem ASTB toolchain: static smoke checks; default root = parent of this file
rem (works in skill_src\tools\ and in the deployed skill_payload\tools\ copy)
setlocal
set "JDK=C:\Program Files\Amazon Corretto\jdk21.0.10_7\bin"
if not exist "%JDK%\java.exe" echo JDK missing: "%JDK%" & exit /b 1
"%JDK%\java.exe" "%~dp0AstbSmoke.java" "%~dp0.." %*
