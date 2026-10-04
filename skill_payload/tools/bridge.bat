@echo off
rem ASTB toolchain: bridge debug client for a running Allegro session
setlocal
set "JDK=C:\Program Files\Amazon Corretto\jdk21.0.10_7\bin"
if not exist "%JDK%\java.exe" echo JDK missing: "%JDK%" & exit /b 1
"%JDK%\java.exe" "%~dp0AstbBridgeClient.java" %*
