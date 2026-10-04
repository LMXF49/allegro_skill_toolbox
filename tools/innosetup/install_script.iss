; Created by "innounp" version 2.71.0
; Setup file: innosetup-6.7.3.exe
; Inno Setup Version: 6.7.0 (Unicode)

[Setup]
AppName=Inno Setup
AppId=Inno Setup 6
AppVersion=6.7.3
AppPublisher=jrsoftware.org
AppPublisherURL=https://www.innosetup.com/
AppSupportURL=https://www.innosetup.com/
AppUpdatesURL=https://www.innosetup.com/
AppMutex=InnoSetupCompilerAppMutex,Global\InnoSetupCompilerAppMutex
DefaultDirName={code:GetDefaultDirName|Inno Setup 6}
DefaultGroupName=Inno Setup 6
OutputBaseFilename=innosetup-6.7.3
UninstallDisplayIcon={app}\Compil32.exe
Compression=lzma2
Uninstallable=not PortableCheck
PrivilegesRequiredOverridesAllowed=dialog
DisableDirPage=auto
DisableProgramGroupPage=auto
ChangesAssociations=no
ShowLanguageDialog=yes
AllowNoIcons=yes
LicenseFile=embedded\License.txt
WizardStyle=modern dynamic
WizardImageFile=embedded\WizardImage0.png
WizardSmallImageFile=embedded\WizardSmallImage0.png
;TimeStampsInUTC=yes

[Files]
Source: "{tmp}\isdonate.bmp"; DestDir: "{tmp}"; Flags: deleteafterinstall dontcopy 
Source: "{tmp}\isdonate_dark.bmp"; DestDir: "{tmp}"; Flags: deleteafterinstall dontcopy 
Source: "{tmp}\ismail.bmp"; DestDir: "{tmp}"; Flags: deleteafterinstall dontcopy 
Source: "{tmp}\ismail_dark.bmp"; DestDir: "{tmp}"; Flags: deleteafterinstall dontcopy 
Source: "{app}\license.txt"; DestDir: "{app}"; Flags: ignoreversion 
Source: "{app}\ISetup.chm"; DestDir: "{app}"; Flags: ignoreversion 
Source: "{app}\ISetup-dark.chm"; DestDir: "{app}"; Flags: ignoreversion 
Source: "{app}\Compil32.exe"; DestDir: "{app}"; Flags: ignoreversion 
Source: "{app}\isscint.dll"; DestDir: "{app}"; Flags: ignoreversion 
Source: "{app}\isscint.dll.issig"; DestDir: "{app}"; Flags: ignoreversion 
Source: "{app}\ISCC.exe"; DestDir: "{app}"; Flags: ignoreversion 
Source: "{app}\ISCmplr.dll"; DestDir: "{app}"; Flags: ignoreversion 
Source: "{app}\ISCmplr.dll.issig"; DestDir: "{app}"; Flags: ignoreversion 
Source: "{app}\Setup.e32"; DestDir: "{app}"; Flags: ignoreversion 
Source: "{app}\Setup.e32.issig"; DestDir: "{app}"; Flags: ignoreversion 
Source: "{app}\SetupCustomStyle.e32"; DestDir: "{app}"; Flags: ignoreversion 
Source: "{app}\SetupCustomStyle.e32.issig"; DestDir: "{app}"; Flags: ignoreversion 
Source: "{app}\SetupLdr.e32"; DestDir: "{app}"; Flags: ignoreversion 
Source: "{app}\SetupLdr.e32.issig"; DestDir: "{app}"; Flags: ignoreversion 
Source: "{app}\SetupLdr.e64"; DestDir: "{app}"; Flags: ignoreversion 
Source: "{app}\SetupLdr.e64.issig"; DestDir: "{app}"; Flags: ignoreversion 
Source: "{app}\Default.isl"; DestDir: "{app}"; Flags: ignoreversion 
Source: "{app}\Languages\Arabic.isl"; DestDir: "{app}\Languages"; Flags: ignoreversion 
Source: "{app}\Languages\Armenian.isl"; DestDir: "{app}\Languages"; Flags: ignoreversion 
Source: "{app}\Languages\BrazilianPortuguese.isl"; DestDir: "{app}\Languages"; Flags: ignoreversion 
Source: "{app}\Languages\Bulgarian.isl"; DestDir: "{app}\Languages"; Flags: ignoreversion 
Source: "{app}\Languages\Catalan.isl"; DestDir: "{app}\Languages"; Flags: ignoreversion 
Source: "{app}\Languages\Corsican.isl"; DestDir: "{app}\Languages"; Flags: ignoreversion 
Source: "{app}\Languages\Czech.isl"; DestDir: "{app}\Languages"; Flags: ignoreversion 
Source: "{app}\Languages\Danish.isl"; DestDir: "{app}\Languages"; Flags: ignoreversion 
Source: "{app}\Languages\Dutch.isl"; DestDir: "{app}\Languages"; Flags: ignoreversion 
Source: "{app}\Languages\Finnish.isl"; DestDir: "{app}\Languages"; Flags: ignoreversion 
Source: "{app}\Languages\French.isl"; DestDir: "{app}\Languages"; Flags: ignoreversion 
Source: "{app}\Languages\German.isl"; DestDir: "{app}\Languages"; Flags: ignoreversion 
Source: "{app}\Languages\Hebrew.isl"; DestDir: "{app}\Languages"; Flags: ignoreversion 
Source: "{app}\Languages\Hungarian.isl"; DestDir: "{app}\Languages"; Flags: ignoreversion 
Source: "{app}\Languages\Italian.isl"; DestDir: "{app}\Languages"; Flags: ignoreversion 
Source: "{app}\Languages\Japanese.isl"; DestDir: "{app}\Languages"; Flags: ignoreversion 
Source: "{app}\Languages\Korean.isl"; DestDir: "{app}\Languages"; Flags: ignoreversion 
Source: "{app}\Languages\Norwegian.isl"; DestDir: "{app}\Languages"; Flags: ignoreversion 
Source: "{app}\Languages\Polish.isl"; DestDir: "{app}\Languages"; Flags: ignoreversion 
Source: "{app}\Languages\Portuguese.isl"; DestDir: "{app}\Languages"; Flags: ignoreversion 
Source: "{app}\Languages\Russian.isl"; DestDir: "{app}\Languages"; Flags: ignoreversion 
Source: "{app}\Languages\Slovak.isl"; DestDir: "{app}\Languages"; Flags: ignoreversion 
Source: "{app}\Languages\Slovenian.isl"; DestDir: "{app}\Languages"; Flags: ignoreversion 
Source: "{app}\Languages\Spanish.isl"; DestDir: "{app}\Languages"; Flags: ignoreversion 
Source: "{app}\Languages\Swedish.isl"; DestDir: "{app}\Languages"; Flags: ignoreversion 
Source: "{app}\Languages\Tamil.isl"; DestDir: "{app}\Languages"; Flags: ignoreversion 
Source: "{app}\Languages\Thai.isl"; DestDir: "{app}\Languages"; Flags: ignoreversion 
Source: "{app}\Languages\Turkish.isl"; DestDir: "{app}\Languages"; Flags: ignoreversion 
Source: "{app}\Languages\Ukrainian.isl"; DestDir: "{app}\Languages"; Flags: ignoreversion 
Source: "{app}\SetupClassicIcon.ico"; DestDir: "{app}"; Flags: ignoreversion 
Source: "{app}\WizClassicImage.bmp"; DestDir: "{app}"; Flags: ignoreversion 
Source: "{app}\WizClassicImage-IS.bmp"; DestDir: "{app}"; Flags: ignoreversion 
Source: "{app}\WizClassicSmallImage.bmp"; DestDir: "{app}"; Flags: ignoreversion 
Source: "{app}\WizClassicSmallImage-IS.bmp"; DestDir: "{app}"; Flags: ignoreversion 
Source: "{app}\is7z.dll"; DestDir: "{app}"; Flags: ignoreversion 
Source: "{app}\is7z.dll.issig"; DestDir: "{app}"; Flags: ignoreversion 
Source: "{app}\is7zxa.dll"; DestDir: "{app}"; Flags: ignoreversion 
Source: "{app}\is7zxa.dll.issig"; DestDir: "{app}"; Flags: ignoreversion 
Source: "{app}\is7zxr.dll"; DestDir: "{app}"; Flags: ignoreversion 
Source: "{app}\is7zxr.dll.issig"; DestDir: "{app}"; Flags: ignoreversion 
Source: "{app}\iszlib.dll"; DestDir: "{app}"; Flags: ignoreversion 
Source: "{app}\iszlib.dll.issig"; DestDir: "{app}"; Flags: ignoreversion 
Source: "{app}\isunzlib.dll"; DestDir: "{app}"; Flags: ignoreversion 
Source: "{app}\isunzlib.dll.issig"; DestDir: "{app}"; Flags: ignoreversion 
Source: "{app}\isbzip.dll"; DestDir: "{app}"; Flags: ignoreversion 
Source: "{app}\isbzip.dll.issig"; DestDir: "{app}"; Flags: ignoreversion 
Source: "{app}\isbunzip.dll"; DestDir: "{app}"; Flags: ignoreversion 
Source: "{app}\isbunzip.dll.issig"; DestDir: "{app}"; Flags: ignoreversion 
Source: "{app}\islzma.dll"; DestDir: "{app}"; Flags: ignoreversion 
Source: "{app}\islzma.dll.issig"; DestDir: "{app}"; Flags: ignoreversion 
Source: "{app}\islzma32.exe"; DestDir: "{app}"; Flags: ignoreversion 
Source: "{app}\islzma32.exe.issig"; DestDir: "{app}"; Flags: ignoreversion 
Source: "{app}\islzma64.exe"; DestDir: "{app}"; Flags: ignoreversion 
Source: "{app}\islzma64.exe.issig"; DestDir: "{app}"; Flags: ignoreversion 
Source: "{app}\ISPP.dll"; DestDir: "{app}"; Flags: ignoreversion 
Source: "{app}\ISPP.dll.issig"; DestDir: "{app}"; Flags: ignoreversion 
Source: "{app}\ISPPBuiltins.iss"; DestDir: "{app}"; Flags: ignoreversion 
Source: "{app}\ISSigTool.exe"; DestDir: "{app}"; Flags: ignoreversion 
Source: "{app}\whatsnew.htm"; DestDir: "{app}"; Flags: ignoreversion 
Source: "{app}\Examples\64Bit.iss"; DestDir: "{app}\Examples"; Flags: ignoreversion 
Source: "{app}\Examples\64BitTwoArch.iss"; DestDir: "{app}\Examples"; Flags: ignoreversion 
Source: "{app}\Examples\64BitThreeArch.iss"; DestDir: "{app}\Examples"; Flags: ignoreversion 
Source: "{app}\Examples\AllPagesExample.iss"; DestDir: "{app}\Examples"; Flags: ignoreversion 
Source: "{app}\Examples\CodeAutomation.iss"; DestDir: "{app}\Examples"; Flags: ignoreversion 
Source: "{app}\Examples\CodeAutomation2.iss"; DestDir: "{app}\Examples"; Flags: ignoreversion 
Source: "{app}\Examples\CodeClasses.iss"; DestDir: "{app}\Examples"; Flags: ignoreversion 
Source: "{app}\Examples\CodeDlg.iss"; DestDir: "{app}\Examples"; Flags: ignoreversion 
Source: "{app}\Examples\CodeDll.iss"; DestDir: "{app}\Examples"; Flags: ignoreversion 
Source: "{app}\Examples\CodeDownloadFiles.iss"; DestDir: "{app}\Examples"; Flags: ignoreversion 
Source: "{app}\Examples\CodeExample1.iss"; DestDir: "{app}\Examples"; Flags: ignoreversion 
Source: "{app}\Examples\CodePrepareToInstall.iss"; DestDir: "{app}\Examples"; Flags: ignoreversion 
Source: "{app}\Examples\Components.iss"; DestDir: "{app}\Examples"; Flags: ignoreversion 
Source: "{app}\Examples\DownloadFiles.iss"; DestDir: "{app}\Examples"; Flags: ignoreversion 
Source: "{app}\Examples\Example1.iss"; DestDir: "{app}\Examples"; Flags: ignoreversion 
Source: "{app}\Examples\Example2.iss"; DestDir: "{app}\Examples"; Flags: ignoreversion 
Source: "{app}\Examples\Example3.iss"; DestDir: "{app}\Examples"; Flags: ignoreversion 
Source: "{app}\Examples\ISPPExample1.iss"; DestDir: "{app}\Examples"; Flags: ignoreversion 
Source: "{app}\Examples\ISPPExample1License.txt"; DestDir: "{app}\Examples"; Flags: ignoreversion 
Source: "{app}\Examples\License.txt"; DestDir: "{app}\Examples"; Flags: ignoreversion 
Source: "{app}\Examples\Languages.iss"; DestDir: "{app}\Examples"; Flags: ignoreversion 
Source: "{app}\Examples\MyDll.dll"; DestDir: "{app}\Examples"; Flags: ignoreversion 
Source: "{app}\Examples\MyProg.chm"; DestDir: "{app}\Examples"; Flags: ignoreversion 
Source: "{app}\Examples\MyProg.exe"; DestDir: "{app}\Examples"; Flags: ignoreversion 
Source: "{app}\Examples\MyProg-Arm64.exe"; DestDir: "{app}\Examples"; Flags: ignoreversion 
Source: "{app}\Examples\MyProg-x64.exe"; DestDir: "{app}\Examples"; Flags: ignoreversion 
Source: "{app}\Examples\PowerShell.iss"; DestDir: "{app}\Examples"; Flags: ignoreversion 
Source: "{app}\Examples\Readme.txt"; DestDir: "{app}\Examples"; Flags: ignoreversion 
Source: "{app}\Examples\Readme-Dutch.txt"; DestDir: "{app}\Examples"; Flags: ignoreversion 
Source: "{app}\Examples\Readme-German.txt"; DestDir: "{app}\Examples"; Flags: ignoreversion 
Source: "{app}\Examples\UnicodeExample1.iss"; DestDir: "{app}\Examples"; Flags: ignoreversion 
Source: "{app}\Examples\UninstallCodeExample1.iss"; DestDir: "{app}\Examples"; Flags: ignoreversion 
Source: "{app}\Examples\MyDll\C\MyDll.c"; DestDir: "{app}\Examples\MyDll\C"; Flags: ignoreversion 
Source: "{app}\Examples\MyDll\C\MyDll.def"; DestDir: "{app}\Examples\MyDll\C"; Flags: ignoreversion 
Source: "{app}\Examples\MyDll\C\MyDll.dsp"; DestDir: "{app}\Examples\MyDll\C"; Flags: ignoreversion 
Source: "{app}\Examples\MyDll\C#\MyDll.cs"; DestDir: "{app}\Examples\MyDll\C#"; Flags: ignoreversion 
Source: "{app}\Examples\MyDll\C#\MyDll.csproj"; DestDir: "{app}\Examples\MyDll\C#"; Flags: ignoreversion 
Source: "{app}\Examples\MyDll\C#\MyDll.sln"; DestDir: "{app}\Examples\MyDll\C#"; Flags: ignoreversion 
Source: "{app}\Examples\MyDll\C#\packages.config"; DestDir: "{app}\Examples\MyDll\C#"; Flags: ignoreversion 
Source: "{app}\Examples\MyDll\C#\Properties\AssemblyInfo.cs"; DestDir: "{app}\Examples\MyDll\C#\Properties"; Flags: ignoreversion 
Source: "{app}\Examples\MyDll\Delphi\MyDll.dpr"; DestDir: "{app}\Examples\MyDll\Delphi"; Flags: ignoreversion 

[INI]
FileName: "{app}\isfaq.url"; Section: "InternetShortcut"; Key: "URL"; String: "https://jrsoftware.org/isfaq.php"; 

[Run]
Filename: "{app}\Compil32.exe"; Parameters: "/ASSOC"; StatusMsg: "{cm:AssocingFileExtension,Inno Setup,.iss}"; Tasks: fileassoc; 
Filename: "{app}\Compil32.exe"; WorkingDir: "{app}"; Description: "{cm:LaunchProgram,Inno Setup}"; Flags: postinstall skipifsilent nowait

[UninstallRun]
Filename: "{app}\Compil32.exe"; Parameters: "/UNASSOC"; RunOnceId: "RemoveISSAssoc"; 

[Icons]
Name: "{group}\Inno Setup Compiler"; Filename: "{app}\Compil32.exe"; WorkingDir: "{app}"; 
Name: "{group}\Inno Setup Documentation"; Filename: "{app}\ISetup.chm"; 
Name: "{group}\Inno Setup Documentation (Dark)"; Filename: "{app}\ISetup-dark.chm"; 
Name: "{group}\Inno Setup Example Scripts"; Filename: "{app}\Examples\"; 
Name: "{group}\Inno Setup FAQ"; Filename: "{app}\isfaq.url"; 
Name: "{group}\Inno Setup Revision History"; Filename: "{app}\whatsnew.htm"; 
Name: "{autodesktop}\Inno Setup Compiler"; Filename: "{app}\Compil32.exe"; WorkingDir: "{app}"; Tasks: desktopicon; 

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; Check: "not PortableCheck"; 
Name: "fileassoc"; Description: "{cm:AssocFileExtension,Inno Setup,.iss}"; Check: "not PortableCheck"; 

[InstallDelete]
Type: files; Name: "{app}\ISCmplr.dls"; 
Type: files; Name: "{app}\Builtins.iss"; 
Type: files; Name: "{app}\ISPP.chm"; 
Type: files; Name: "{autodesktop}\Inno Setup Compiler.lnk"; Tasks: not desktopicon; Check: not PortableCheck; 
Type: files; Name: "{app}\isfaq.htm"; 
Type: files; Name: "{app}\Languages\*.islu"; 
Type: files; Name: "{app}\Languages\*.isl"; 
Type: files; Name: "{app}\Ispack-setup.exe"; 
Type: files; Name: "{app}\Examples\Setup.iss"; 
Type: files; Name: "{app}\Examples\Setup.ico"; 
Type: files; Name: "{app}\Examples\IsDonateAndMail.iss"; 
Type: files; Name: "{app}\Examples\IsDonate.bmp"; 
Type: files; Name: "{app}\Examples\IsMail.bmp"; 
Type: files; Name: "{app}\Examples\IsPortable.iss"; 
Type: files; Name: "{app}\WizModernImage.bmp"; 
Type: files; Name: "{app}\WizModernImage-IS.bmp"; 
Type: files; Name: "{app}\WizModernSmallImage.bmp"; 
Type: files; Name: "{app}\WizModernSmallImage-IS.bmp"; 
Type: files; Name: "{app}\ISCrypt.dll"; 

[UninstallDelete]
Type: files; Name: "{app}\isfaq.url"; 

[CustomMessages]
english.NameAndVersion=%1 version %2
english.AdditionalIcons=Additional shortcuts:
english.CreateDesktopIcon=Create a &desktop shortcut
english.CreateQuickLaunchIcon=Create a &Quick Launch shortcut
english.ProgramOnTheWeb=%1 on the Web
english.UninstallProgram=Uninstall %1
english.LaunchProgram=Launch %1
english.AssocFileExtension=&Associate %1 with the %2 file extension
english.AssocingFileExtension=Associating %1 with the %2 file extension...
english.AutoStartProgramGroupDescription=Startup:
english.AutoStartProgram=Automatically start %1
english.AddonHostProgramNotFound=%1 could not be located in the folder you selected.%n%nDo you want to continue anyway?
arabic.NameAndVersion=%1 الإصدار %2
arabic.AdditionalIcons=اختصارات إضافية:
arabic.CreateDesktopIcon=إنشاء اختصار في سطح المكتب
arabic.CreateQuickLaunchIcon=إنشاء اختصار "التشغيل السريع"
arabic.ProgramOnTheWeb=%1 على الأنترنت
arabic.UninstallProgram=إزالة تثبيت %1
arabic.LaunchProgram=تشغيل %1
arabic.AssocFileExtension=ربط %1 مع صيغة ملف %2
arabic.AssocingFileExtension=جاري ربط %1 مع صيغة ملف %2
arabic.AutoStartProgramGroupDescription=بدأ التشغيل:
arabic.AutoStartProgram=تشغيل %1 تلقائيا
arabic.AddonHostProgramNotFound= تعذر العثور على %1 في الموقع الذي إخترته.%n%nهل تريد المتابعة على أية حال؟
armenian.NameAndVersion=%1 տարբերակ՝ %2
armenian.AdditionalIcons=Լրացուցիչ դյուրանցումներ
armenian.CreateDesktopIcon=Ստեղծել դյուրանցում &Աշխատասեղանին
armenian.CreateQuickLaunchIcon=Ստեղծել դյուրանցում &Արագ թողարկման գոտում
armenian.ProgramOnTheWeb=%1-ի վեբ կայքը
armenian.UninstallProgram=%1-ի ապատեղադրում
armenian.LaunchProgram=Բացել %1-ը
armenian.AssocFileExtension=Հա&մակցել %1-ը %2 ֆայլերի հետ։
armenian.AssocingFileExtension=%1-ը համակցվում է %2 ընդլայնումով ֆայլերի հետ...
armenian.AutoStartProgramGroupDescription=Ինքնամեկնարկ.
armenian.AutoStartProgram=Ինքնաբար մեկնարկել %1-ը
armenian.AddonHostProgramNotFound=%1 չի կարող տեղադրվել Ձեր ընտրած պանակում։%n%nՇարունակե՞լ։
brazilianportuguese.NameAndVersion=%1 versão %2
brazilianportuguese.AdditionalIcons=Atalhos adicionais:
brazilianportuguese.CreateDesktopIcon=Criar um atalho &na área de trabalho
brazilianportuguese.CreateQuickLaunchIcon=Criar um atalho na &barra de inicialização rápida
brazilianportuguese.ProgramOnTheWeb=%1 na Web
brazilianportuguese.UninstallProgram=Desinstalar o %1
brazilianportuguese.LaunchProgram=Iniciar o %1
brazilianportuguese.AssocFileExtension=&Associar o %1 com a extensão do arquivo %2
brazilianportuguese.AssocingFileExtension=Associando o %1 com a extensão do arquivo %2...
brazilianportuguese.AutoStartProgramGroupDescription=Inicialização:
brazilianportuguese.AutoStartProgram=Iniciar o %1 automaticamente
brazilianportuguese.AddonHostProgramNotFound=O %1 não pôde ser localizado na pasta que você selecionou.%n%nVocê quer continuar de qualquer maneira?
bulgarian.NameAndVersion=%1, версия %2
bulgarian.AdditionalIcons=Допълнителни икони:
bulgarian.CreateDesktopIcon=Икона на &работния плот
bulgarian.CreateQuickLaunchIcon=Икона в лентата "&Бързо стартиране"
bulgarian.ProgramOnTheWeb=%1 в Интернет
bulgarian.UninstallProgram=Деинсталиране на %1
bulgarian.LaunchProgram=Стартиране на %1
bulgarian.AssocFileExtension=&Свързване на %1 с файловото разширение %2
bulgarian.AssocingFileExtension=%1 се свързва с файловото разширение %2...
bulgarian.AutoStartProgramGroupDescription=Стартиране:
bulgarian.AutoStartProgram=Автоматично стартиране на %1
bulgarian.AddonHostProgramNotFound=%1 не бе намерена в избраната от вас папка.%n%nЖелаете ли все пак да продължите?
catalan.NameAndVersion=%1 versió %2
catalan.AdditionalIcons=Icones addicionals:
catalan.CreateDesktopIcon=Crea una icona a l'&Escriptori
catalan.CreateQuickLaunchIcon=Crea una icona a la &Barra de tasques
catalan.ProgramOnTheWeb=%1 a Internet
catalan.UninstallProgram=Desinstal·la %1
catalan.LaunchProgram=Obre %1
catalan.AssocFileExtension=&Associa %1 amb l'extensió de fitxer %2
catalan.AssocingFileExtension=Associant %1 amb l'extensió de fitxer %2...
catalan.AutoStartProgramGroupDescription=Inici:
catalan.AutoStartProgram=Inicia automàticament %1
catalan.AddonHostProgramNotFound=%1 no ha pogut ser trobat a la carpeta seleccionada.%n%nVoleu continuar igualment?
corsican.NameAndVersion=%1 versione %2
corsican.AdditionalIcons=Accurtatoghji addizziunali :
corsican.CreateDesktopIcon=Creà un accurtatoghju nant’à u &scagnu
corsican.CreateQuickLaunchIcon=Creà un accurtatoghju nant’à a barra di &lanciu prontu
corsican.ProgramOnTheWeb=%1 nant’à u Web
corsican.UninstallProgram=Disinstallà %1
corsican.LaunchProgram=Lancià %1
corsican.AssocFileExtension=&Assucià %1 cù l’estensione di schedariu %2
corsican.AssocingFileExtension=Associu di %1 cù l’estensione di schedariu %2…
corsican.AutoStartProgramGroupDescription=Lanciu autumaticu :
corsican.AutoStartProgram=Lanciu autumaticu di %1
corsican.AddonHostProgramNotFound=Impussibule di truvà %1 in u cartulare selezziunatu.%n%nVulete cuntinuà l’installazione quantunque ?
czech.NameAndVersion=%1 verze %2
czech.AdditionalIcons=Další zástupci:
czech.CreateDesktopIcon=Vytvořit zástupce na &ploše
czech.CreateQuickLaunchIcon=Vytvořit zástupce na panelu &Snadné spuštění
czech.ProgramOnTheWeb=Aplikace %1 na internetu
czech.UninstallProgram=Odinstalovat aplikaci %1
czech.LaunchProgram=Spustit aplikaci %1
czech.AssocFileExtension=Vytvořit &asociaci mezi soubory typu %2 a aplikací %1
czech.AssocingFileExtension=Vytváří se asociace mezi soubory typu %2 a aplikací %1...
czech.AutoStartProgramGroupDescription=Po spuštění:
czech.AutoStartProgram=Spouštět aplikaci %1 automaticky
czech.AddonHostProgramNotFound=Aplikace %1 nebyla ve Vámi zvolené složce nalezena.%n%nChcete přesto pokračovat?
danish.NameAndVersion=%1 version %2
danish.AdditionalIcons=Supplerende ikoner:
danish.CreateDesktopIcon=Opret ikon på skrive&bordet
danish.CreateQuickLaunchIcon=Opret &hurtigstart-ikon
danish.ProgramOnTheWeb=%1 på internettet
danish.UninstallProgram=Afinstaller (fjern) %1
danish.LaunchProgram=&Start %1
danish.AssocFileExtension=Sammen&kæd %1 med filtypen %2
danish.AssocingFileExtension=Sammenkæder %1 med filtypen %2...
danish.AutoStartProgramGroupDescription=Start:
danish.AutoStartProgram=Start automatisk %1
danish.AddonHostProgramNotFound=%1 blev ikke fundet i den valgte mappe.%n%nVil du alligevel fortsætte?
dutch.NameAndVersion=%1 versie %2
dutch.AdditionalIcons=Extra snelkoppelingen:
dutch.CreateDesktopIcon=Maak een snelkoppeling op het &bureaublad
dutch.CreateQuickLaunchIcon=Maak een snelkoppeling op de &Snel starten werkbalk
dutch.ProgramOnTheWeb=%1 op het Web
dutch.UninstallProgram=Verwijder %1
dutch.LaunchProgram=&Start %1
dutch.AssocFileExtension=&Koppel %1 aan de %2 bestandsextensie
dutch.AssocingFileExtension=Bezig met koppelen van %1 aan de %2 bestandsextensie...
dutch.AutoStartProgramGroupDescription=Opstarten:
dutch.AutoStartProgram=%1 automatisch starten
dutch.AddonHostProgramNotFound=%1 kon niet worden gevonden in de geselecteerde map.%n%nWilt u toch doorgaan?
finnish.NameAndVersion=%1 versio %2
finnish.AdditionalIcons=Lisäkuvakkeet:
finnish.CreateDesktopIcon=Lu&o kuvake työpöydälle
finnish.CreateQuickLaunchIcon=Luo kuvake &pikakäynnistyspalkkiin
finnish.ProgramOnTheWeb=%1 Internetissä
finnish.UninstallProgram=Poista %1
finnish.LaunchProgram=&Käynnistä %1
finnish.AssocFileExtension=&Yhdistä %1 tiedostopäätteeseen %2
finnish.AssocingFileExtension=Yhdistetään %1 tiedostopäätteeseen %2 ...
finnish.AutoStartProgramGroupDescription=Käynnistys:
finnish.AutoStartProgram=Käynnistä %1 automaattisesti
finnish.AddonHostProgramNotFound=%1 ei ole valitsemassasi kansiossa.%n%nHaluatko jatkaa tästä huolimatta?
french.NameAndVersion=%1 version %2
french.AdditionalIcons=Icônes supplémentaires :
french.CreateDesktopIcon=Créer une icône sur le &Bureau
french.CreateQuickLaunchIcon=Créer une icône dans la barre de &Lancement rapide
french.ProgramOnTheWeb=Page d'accueil de %1
french.UninstallProgram=Désinstaller %1
french.LaunchProgram=Exécuter %1
french.AssocFileExtension=&Associer %1 avec l'extension de fichier %2
french.AssocingFileExtension=Associe %1 avec l'extension de fichier %2...
french.AutoStartProgramGroupDescription=Démarrage :
french.AutoStartProgram=Démarrer automatiquement %1
french.AddonHostProgramNotFound=%1 n'a pas été trouvé dans le dossier que vous avez choisi.%n%nVoulez-vous continuer malgré tout ?
german.NameAndVersion=%1 Version %2
german.AdditionalIcons=Zusätzliche Symbole:
german.CreateDesktopIcon=&Desktop-Symbol erstellen
german.CreateQuickLaunchIcon=Symbol in der Schnellstartleiste erstellen
german.ProgramOnTheWeb=%1 im Internet
german.UninstallProgram=%1 entfernen
german.LaunchProgram=%1 starten
german.AssocFileExtension=&Registriere %1 mit der %2-Dateierweiterung
german.AssocingFileExtension=%1 wird mit der %2-Dateierweiterung registriert...
german.AutoStartProgramGroupDescription=Beginn des Setups:
german.AutoStartProgram=Starte automatisch %1
german.AddonHostProgramNotFound=%1 konnte im ausgewählten Ordner nicht gefunden werden.%n%nMöchten Sie dennoch fortfahren?
hebrew.NameAndVersion=%1 גירסה %2
hebrew.AdditionalIcons=סימלונים נוספים:
hebrew.CreateDesktopIcon=צור קיצור דרך על &שולחן העבודה
hebrew.CreateQuickLaunchIcon=צור סימלון בשורת ההרצה המהירה
hebrew.ProgramOnTheWeb=%1 ברשת
hebrew.UninstallProgram=הסר את %1
hebrew.LaunchProgram=הפעל %1
hebrew.AssocFileExtension=&קשר את %1 עם סיומת הקובץ %2
hebrew.AssocingFileExtension=מקשר את %1 עם סיומת הקובץ %2
hebrew.AutoStartProgramGroupDescription=הפעלה אוטומטית:
hebrew.AutoStartProgram=הפעל אוטומטית %1
hebrew.AddonHostProgramNotFound=%1 לא נמצא בתיקיה שבחרת.%n%nאתה רוצה להמשיך בכל זאת?
hungarian.NameAndVersion=%1, verzió: %2
hungarian.AdditionalIcons=További parancsikonok:
hungarian.CreateDesktopIcon=&Asztali parancsikon létrehozása
hungarian.CreateQuickLaunchIcon=&Gyorsindító-parancsikon létrehozása
hungarian.ProgramOnTheWeb=%1 az interneten
hungarian.UninstallProgram=Eltávolítás - %1
hungarian.LaunchProgram=Indítás %1
hungarian.AssocFileExtension=A(z) %1 &társítása a(z) %2 fájlkiterjesztéssel
hungarian.AssocingFileExtension=A(z) %1 társítása a(z) %2 fájlkiterjesztéssel...
hungarian.AutoStartProgramGroupDescription=Indítópult:
hungarian.AutoStartProgram=%1 automatikus indítása
hungarian.AddonHostProgramNotFound=A(z) %1 nem található a kiválasztott könyvtárban.%n%nMindenképpen folytatja?
italian.NameAndVersion=%1 versione %2
italian.AdditionalIcons=Icone aggiuntive:
italian.CreateDesktopIcon=Crea un'icona sul &desktop
italian.CreateQuickLaunchIcon=Crea un'icona nella &barra 'Avvio veloce'
italian.ProgramOnTheWeb=Sito web di %1
italian.UninstallProgram=Disinstalla %1
italian.LaunchProgram=Esegui %1
italian.AssocFileExtension=&Associa i file con estensione %2 a %1
italian.AssocingFileExtension=Associazione dei file con estensione %2 a %1...
italian.AutoStartProgramGroupDescription=Esecuzione automatica:
italian.AutoStartProgram=Esegui automaticamente %1
italian.AddonHostProgramNotFound=Impossibile individuare %1 nella cartella selezionata.%n%nVuoi continuare ugualmente?
japanese.NameAndVersion=%1 バージョン %2
japanese.AdditionalIcons=アイコンを追加する:
japanese.CreateDesktopIcon=デスクトップ上にアイコンを作成する(&D)
japanese.CreateQuickLaunchIcon=クイック起動アイコンを作成する(&Q)
japanese.ProgramOnTheWeb=%1 on the Web
japanese.UninstallProgram=%1 をアンインストールする
japanese.LaunchProgram=%1 を実行する
japanese.AssocFileExtension=ファイル拡張子 %2 に %1 を関連付けます。
japanese.AssocingFileExtension=ファイル拡張子 %2 に %1 を関連付けています...
japanese.AutoStartProgramGroupDescription=スタートアップ:
japanese.AutoStartProgram=%1 を自動的に開始する
japanese.AddonHostProgramNotFound=選択されたフォルダーに %1 が見つかりませんでした。%n%nこのまま続行しますか？
korean.NameAndVersion=%1 버전 %2
korean.AdditionalIcons=바로 가기 추가:
korean.CreateDesktopIcon=바탕 화면에 바로 가기 만들기(&D)
korean.CreateQuickLaunchIcon=빠른 실행 아이콘 만들기(&Q)
korean.ProgramOnTheWeb=%1 웹페이지
korean.UninstallProgram=%1 제거
korean.LaunchProgram=%1 실행
korean.AssocFileExtension=%1을(를) %2 파일 확장자에 연결
korean.AssocingFileExtension=%1을(를) %2 파일 확장자와 연결하는 중...
korean.AutoStartProgramGroupDescription=시작:
korean.AutoStartProgram=%1 자동 시작
korean.AddonHostProgramNotFound=%1을(를) 선택한 폴더에서 찾을 수 없습니다.%n%n계속하시겠습니까?
norwegian.NameAndVersion=%1 versjon %2
norwegian.AdditionalIcons=Ekstra-ikoner:
norwegian.CreateDesktopIcon=Lag ikon på &skrivebordet
norwegian.CreateQuickLaunchIcon=Lag et &Hurtigstarts-ikon
norwegian.ProgramOnTheWeb=%1 på nettet
norwegian.UninstallProgram=Avinstaller %1
norwegian.LaunchProgram=Kjør %1
norwegian.AssocFileExtension=&Koble %1 med filetternavnet %2
norwegian.AssocingFileExtension=Kobler %1 med filetternavnet %2...
norwegian.AutoStartProgramGroupDescription=Oppstart:
norwegian.AutoStartProgram=Start %1 automatisk
norwegian.AddonHostProgramNotFound=%1 ble ikke funnet i katalogen du valgte.%n%nVil du fortsette likevel?
polish.NameAndVersion=%1 (wersja %2)
polish.AdditionalIcons=Dodatkowe skróty:
polish.CreateDesktopIcon=Utwórz skrót na &pulpicie
polish.CreateQuickLaunchIcon=Utwórz skrót na pasku &szybkiego uruchamiania
polish.ProgramOnTheWeb=Strona internetowa aplikacji %1
polish.UninstallProgram=Dezinstalacja aplikacji %1
polish.LaunchProgram=Uruchom aplikację %1
polish.AssocFileExtension=&Przypisz aplikację %1 do rozszerzenia pliku %2
polish.AssocingFileExtension=Przypisywanie aplikacji %1 do rozszerzenia pliku %2...
polish.AutoStartProgramGroupDescription=Autostart:
polish.AutoStartProgram=Automatycznie uruchamiaj aplikację %1
polish.AddonHostProgramNotFound=Aplikacja %1 nie została znaleziona we wskazanym przez Ciebie folderze.%n%nCzy pomimo tego chcesz kontynuować?
portuguese.NameAndVersion=%1 versão %2
portuguese.AdditionalIcons=Atalhos adicionais:
portuguese.CreateDesktopIcon=Criar atalho no Ambiente de &Trabalho
portuguese.CreateQuickLaunchIcon=&Criar atalho na barra de Iniciação Rápida
portuguese.ProgramOnTheWeb=%1 na Web
portuguese.UninstallProgram=Desinstalar o %1
portuguese.LaunchProgram=Executar o %1
portuguese.AssocFileExtension=Associa&r o %1 aos ficheiros com a extensão %2
portuguese.AssocingFileExtension=A associar o %1 aos ficheiros com a extensão %2...
portuguese.AutoStartProgramGroupDescription=Inicialização Automática:
portuguese.AutoStartProgram=Iniciar %1 automaticamente
portuguese.AddonHostProgramNotFound=Não foi possível localizar %1 na pasta selecionada.%n%nDeseja continuar de qualquer forma?
russian.NameAndVersion=%1, версия %2
russian.AdditionalIcons=Дополнительные значки:
russian.CreateDesktopIcon=Создать значок на &Рабочем столе
russian.CreateQuickLaunchIcon=Создать значок в &Панели быстрого запуска
russian.ProgramOnTheWeb=Сайт %1 в Интернете
russian.UninstallProgram=Деинсталлировать %1
russian.LaunchProgram=Запустить %1
russian.AssocFileExtension=Св&язать %1 с файлами, имеющими расширение %2
russian.AssocingFileExtension=Связывание %1 с файлами %2...
russian.AutoStartProgramGroupDescription=Автозапуск:
russian.AutoStartProgram=Автоматически запускать %1
russian.AddonHostProgramNotFound=%1 не найден в указанной вами папке.%n%nВы всё равно хотите продолжить?
slovak.NameAndVersion=%1 verzia %2
slovak.AdditionalIcons=Ďalší zástupcovia:
slovak.CreateDesktopIcon=Vytvoriť zástupcu na &ploche
slovak.CreateQuickLaunchIcon=Vytvoriť zástupcu na paneli &Rýchle spustenie
slovak.ProgramOnTheWeb=Aplikácia %1 na internete
slovak.UninstallProgram=Odinštalovať aplikáciu %1 
slovak.LaunchProgram=Spustiť aplikáciu %1
slovak.AssocFileExtension=Vytvoriť &asociáciu medzi súbormi typu %2 a aplikáciou %1
slovak.AssocingFileExtension=Vytvára sa asociácia medzi súbormi typu %2 a aplikáciou %1...
slovak.AutoStartProgramGroupDescription=Pri spustení:
slovak.AutoStartProgram=Automaticky spustiť %1
slovak.AddonHostProgramNotFound=Nepodarilo sa nájsť %1 v adresári, ktorý ste zvolili.%n%nChcete napriek tomu pokračovať?
slovenian.NameAndVersion=%1 različica %2
slovenian.AdditionalIcons=Dodatne ikone:
slovenian.CreateDesktopIcon=Ustvari ikono na &namizju
slovenian.CreateQuickLaunchIcon=Ustvari ikono za &hitri zagon
slovenian.ProgramOnTheWeb=%1 na spletu
slovenian.UninstallProgram=Odstrani %1
slovenian.LaunchProgram=Odpri %1
slovenian.AssocFileExtension=&Poveži %1 s pripono %2
slovenian.AssocingFileExtension=Povezujem %1 s pripono %2...
slovenian.AutoStartProgramGroupDescription=Zagon:
slovenian.AutoStartProgram=Samodejno zaženi %1
slovenian.AddonHostProgramNotFound=Programa %1 ni bilo mogoče najti v izbrani mapi.%n%nAli želite vseeno nadaljevati?
spanish.NameAndVersion=%1 versión %2
spanish.AdditionalIcons=Accesos directos adicionales:
spanish.CreateDesktopIcon=Crear un acceso directo en el &escritorio
spanish.CreateQuickLaunchIcon=Crear un acceso directo en &Inicio Rápido
spanish.ProgramOnTheWeb=%1 en la Web
spanish.UninstallProgram=Desinstalar %1
spanish.LaunchProgram=Ejecutar %1
spanish.AssocFileExtension=&Asociar %1 con la extensión de archivo %2
spanish.AssocingFileExtension=Asociando %1 con la extensión de archivo %2...
spanish.AutoStartProgramGroupDescription=Inicio:
spanish.AutoStartProgram=Iniciar automáticamente %1
spanish.AddonHostProgramNotFound=%1 no pudo ser localizado en la carpeta seleccionada.%n%n¿Desea continuar de todas formas?
swedish.NameAndVersion=%1 version %2
swedish.AdditionalIcons=Ytterligare genvägar:
swedish.CreateDesktopIcon=Skapa en &genväg på skrivbordet
swedish.CreateQuickLaunchIcon=Skapa &en genväg i snabbstartfältet
swedish.ProgramOnTheWeb=%1 på webben
swedish.UninstallProgram=Avinstallera %1
swedish.LaunchProgram=Starta %1
swedish.AssocFileExtension=Associera %1 med filnamnstillägget %2
swedish.AssocingFileExtension=Associerar %1 med filnamnstillägget %2...
swedish.AutoStartProgramGroupDescription=Autostart:
swedish.AutoStartProgram=Starta automatiskt %1
swedish.AddonHostProgramNotFound=%1 kunde inte hittas i katalogen du valde.%n%nVill du fortsätta ändå?
tamil.NameAndVersion=%1 பதிப்பு %2
tamil.AdditionalIcons=கூடுதல் குறுக்குவழிகள்:
tamil.CreateDesktopIcon=ஒரு திரைப்பலக குறுக்குவழியை உருவாக்கவும்
tamil.CreateQuickLaunchIcon=ஒரு விரைவான தொடக்க குறுக்குவழியை உருவாக்கவும்
tamil.ProgramOnTheWeb=வலையில் %1
tamil.UninstallProgram=%1 நிறுவல் நீக்குதல்
tamil.LaunchProgram=%1 ஐத் தொடங்கவும்
tamil.AssocFileExtension=%1 ஐ %2 கோப்பு நீட்டிப்புடன் இணைக்கவும்
tamil.AssocingFileExtension=%1 ஐ %2 கோப்பு நீட்டிப்புடன் இணைத்தல்...
tamil.AutoStartProgramGroupDescription=தொடக்கம்:
tamil.AutoStartProgram=தானாகவே %1 ஐத் தொடங்கவும்
tamil.AddonHostProgramNotFound=நீங்கள் தேர்ந்தெடுத்த கோப்புறையில் %1 இருக்க முடியாது.%n%nநீங்கள் எப்படியும் தொடர விரும்புகிறீர்களா?
thai.NameAndVersion=%1 เวอร์ชั่น %2
thai.AdditionalIcons=ทางลัดเพิ่มเติม:
thai.CreateDesktopIcon=สร้างทางลัด&เดสก์ท็อป
thai.CreateQuickLaunchIcon=สร้างทางลัด &Quick Launch
thai.ProgramOnTheWeb=%1 บนเว็บ
thai.UninstallProgram=ถอนการติดตั้ง %1
thai.LaunchProgram=เปิด %1
thai.AssocFileExtension=&เชื่อมโยง %1 กับนามสกุลไฟล์ %2
thai.AssocingFileExtension=กำลังเชื่อมโยง %1 กับนามสกุลไฟล์ %2...
thai.AutoStartProgramGroupDescription=สตาร์ทอัพ:
thai.AutoStartProgram=เริ่ม %1 โดยอัตโนมัติ
thai.AddonHostProgramNotFound=%1 ไม่สามารถพบได้ในโฟลเดอร์ที่คุณเลือก%n%nคุณต้องการดำเนินการต่ออยู่หรือไม่
turkish.NameAndVersion=%1 %2 sürümü
turkish.AdditionalIcons=Ek simgeler:
turkish.CreateDesktopIcon=Masaüstü simg&esi oluşturulsun
turkish.CreateQuickLaunchIcon=Hızlı başlat simgesi &oluşturulsun
turkish.ProgramOnTheWeb=%1 sitesi
turkish.UninstallProgram=%1 uygulamasını kaldır
turkish.LaunchProgram=%1 uygulamasını çalıştır
turkish.AssocFileExtension=%1 &uygulaması ile %2 dosya uzantısı ilişkilendirilsin
turkish.AssocingFileExtension=%1 uygulaması ile %2 dosya uzantısı ilişkilendiriliyor...
turkish.AutoStartProgramGroupDescription=Başlangıç:
turkish.AutoStartProgram=%1 otomatik olarak başlatılsın
turkish.AddonHostProgramNotFound=%1 seçtiğiniz klasörde bulunamadı.%n%nYine de ilerlemek istiyor musunuz?
ukrainian.NameAndVersion=%1, версія %2
ukrainian.AdditionalIcons=Додаткові ярлики:
ukrainian.CreateDesktopIcon=Створити ярлики на &Робочому столі
ukrainian.CreateQuickLaunchIcon=Створити ярлики на &Панелі швидкого запуску
ukrainian.ProgramOnTheWeb=Сайт %1 в Інтернеті
ukrainian.UninstallProgram=Видалити %1
ukrainian.LaunchProgram=Відкрити %1
ukrainian.AssocFileExtension=&Асоціювати %1 з розширенням файлу %2
ukrainian.AssocingFileExtension=Асоціювання %1 з розширенням файлу %2...
ukrainian.AutoStartProgramGroupDescription=Автозавантаження:
ukrainian.AutoStartProgram=Автоматично завантажувати %1
ukrainian.AddonHostProgramNotFound=%1 не знайдений у вказаній вами теці%n%nВи все одно бажаєте продовжити?
IsDonateAndMailDonateCaption=Donate
IsDonateAndMailDonateHint=Support Inno Setup - Thank you!
IsDonateAndMailMailCaption=Subscribe
IsDonateAndMailMailHint=Be notified by e-mail of new Inno Setup releases

[Languages]
; These files are stubs
; To achieve better results after recompilation, use the real language files
Name: "english"; MessagesFile: "embedded\english.isl"; 
Name: "arabic"; MessagesFile: "embedded\arabic.isl"; 
Name: "armenian"; MessagesFile: "embedded\armenian.isl"; 
Name: "brazilianportuguese"; MessagesFile: "embedded\brazilianportuguese.isl"; 
Name: "bulgarian"; MessagesFile: "embedded\bulgarian.isl"; 
Name: "catalan"; MessagesFile: "embedded\catalan.isl"; 
Name: "corsican"; MessagesFile: "embedded\corsican.isl"; 
Name: "czech"; MessagesFile: "embedded\czech.isl"; 
Name: "danish"; MessagesFile: "embedded\danish.isl"; 
Name: "dutch"; MessagesFile: "embedded\dutch.isl"; 
Name: "finnish"; MessagesFile: "embedded\finnish.isl"; 
Name: "french"; MessagesFile: "embedded\french.isl"; 
Name: "german"; MessagesFile: "embedded\german.isl"; 
Name: "hebrew"; MessagesFile: "embedded\hebrew.isl"; 
Name: "hungarian"; MessagesFile: "embedded\hungarian.isl"; 
Name: "italian"; MessagesFile: "embedded\italian.isl"; 
Name: "japanese"; MessagesFile: "embedded\japanese.isl"; 
Name: "korean"; MessagesFile: "embedded\korean.isl"; 
Name: "norwegian"; MessagesFile: "embedded\norwegian.isl"; 
Name: "polish"; MessagesFile: "embedded\polish.isl"; 
Name: "portuguese"; MessagesFile: "embedded\portuguese.isl"; 
Name: "russian"; MessagesFile: "embedded\russian.isl"; 
Name: "slovak"; MessagesFile: "embedded\slovak.isl"; 
Name: "slovenian"; MessagesFile: "embedded\slovenian.isl"; 
Name: "spanish"; MessagesFile: "embedded\spanish.isl"; 
Name: "swedish"; MessagesFile: "embedded\swedish.isl"; 
Name: "tamil"; MessagesFile: "embedded\tamil.isl"; 
Name: "thai"; MessagesFile: "embedded\thai.isl"; 
Name: "turkish"; MessagesFile: "embedded\turkish.isl"; 
Name: "ukrainian"; MessagesFile: "embedded\ukrainian.isl"; 
