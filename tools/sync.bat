@echo off
rem ASTB toolchain: skill_src <-> skill_payload sync (JDK 21 single-file source launch)
setlocal
set "JDK=C:\Program Files\Amazon Corretto\jdk21.0.10_7\bin"
if not exist "%JDK%\java.exe" echo JDK missing: "%JDK%" & exit /b 1
"%JDK%\java.exe" "%~dp0SkillSrcSync.java" %*
