; ============================================================================
; ASTB Toolbox installer (Allegro SKILL toolbox + ASTB Studio)
; Build: tools/innosetup/ISCC.exe tools/installer/astb_setup.iss
; Layout after install:
;   <dir>\skill\    allegro_skill tree (main.il, core/, modules/, forms/ ...)
;   <dir>\studio\   ASTBStudio.exe (Java jpackage app-image, 自带 runtime)
; The installer also:
;   - detects Allegro versions by scanning <drive>:\Cadence\SPB_*
;   - lets the user pick which versions to hook (checkbox page)
;   - merges a marker-delimited load block into each version's
;     allegro.ilinit (pcbenv + site skill dir, both best-effort)
;   - seeds %USERPROFILE%\.astb_studio\config.json when missing
; ============================================================================

#define AppName "ASTB Toolbox"
#define AppVersion "1.1.0"
#define AppPublisher "ASTB Team"

; Skill payload source dir. Override from BuildAll.java / command line:
;   ISCC /DSkillSrc=D:\path\to\allegro_skill astb_setup.iss
; Default keeps the historical D: deploy copy so old build commands still work.
#ifndef SkillSrc
  #define SkillSrc "D:\Cadence\allegro_skill"
#endif

[Setup]
AppId={{A57B1D3E-8F4A-4E2A-9C3B-A57B70018001}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
DefaultDirName={autopf}\ASTB
DefaultGroupName=ASTB Toolbox
PrivilegesRequired=admin
DisableProgramGroupPage=yes
OutputDir=Output
OutputBaseFilename=ASTB_Setup_{#AppVersion}
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
SetupIconFile=astb.ico
UninstallDisplayName={#AppName}
UninstallDisplayIcon={app}\studio\ASTBStudio.exe

[Languages]
Name: "chs"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"

[Files]
; --- SKILL tree: pack the D: deploy copy (universal for 16.6/17.4/24.1+,
;     GBK-octal-escaped and machine-verified), NOT the G: repo ---
Source: "{#SkillSrc}\main.il"; DestDir: "{app}\skill"; Flags: ignoreversion
Source: "{#SkillSrc}\allegro.ilinit"; DestDir: "{app}\skill"; Flags: ignoreversion skipifsourcedoesntexist
Source: "{#SkillSrc}\core\*"; DestDir: "{app}\skill\core"; Flags: ignoreversion recursesubdirs
Source: "{#SkillSrc}\modules\*"; DestDir: "{app}\skill\modules"; Flags: ignoreversion recursesubdirs
Source: "{#SkillSrc}\forms\*"; DestDir: "{app}\skill\forms"; Flags: ignoreversion recursesubdirs
Source: "{#SkillSrc}\config\*"; DestDir: "{app}\skill\config"; Excludes: "hotkeys_user.dat,hotkeys_factory.dat,*.log"; Flags: ignoreversion recursesubdirs
; default keymap: deploy only on first install, never clobber the user's dat
Source: "{#SkillSrc}\config\hotkeys_user.dat"; DestDir: "{app}\skill\config"; Flags: ignoreversion onlyifdoesntexist skipifsourcedoesntexist
; factory initial-value snapshot: also first-install-only, so "restore
; defaults" always returns to the as-shipped keymap, not a user's edit
Source: "{#SkillSrc}\config\hotkeys_factory.dat"; DestDir: "{app}\skill\config"; Flags: ignoreversion onlyifdoesntexist skipifsourcedoesntexist
Source: "{#SkillSrc}\python\*"; DestDir: "{app}\skill\python"; Excludes: "*\__pycache__\*"; Flags: ignoreversion recursesubdirs
Source: "{#SkillSrc}\tools\*.java"; DestDir: "{app}\skill\tools"; Flags: ignoreversion skipifsourcedoesntexist
Source: "{#SkillSrc}\tools\*.bat"; DestDir: "{app}\skill\tools"; Flags: ignoreversion skipifsourcedoesntexist
Source: "{#SkillSrc}\tools\downrev166_rt\*"; DestDir: "{app}\skill\tools\downrev166_rt"; Flags: ignoreversion recursesubdirs skipifsourcedoesntexist
Source: "{#SkillSrc}\tools\adl_patched.exe"; DestDir: "{app}\skill\tools"; Flags: ignoreversion skipifsourcedoesntexist
Source: "{#SkillSrc}\AGENTS.md"; DestDir: "{app}\skill"; Flags: ignoreversion skipifsourcedoesntexist
; canonical ilinit block template (studio migration wizard reads this at runtime)
Source: "{#SkillSrc}\core\ilinit_block.il"; DestDir: "{app}\skill\core"; Flags: ignoreversion skipifsourcedoesntexist
; --- ASTB Studio (Java jpackage app-image: exe + jar + embedded JRE) ---
Source: "..\dist\ASTBStudio\*"; DestDir: "{app}\studio"; Flags: ignoreversion recursesubdirs

[Icons]
Name: "{group}\ASTB Studio"; Filename: "{app}\studio\ASTBStudio.exe"
Name: "{autodesktop}\ASTB Studio"; Filename: "{app}\studio\ASTBStudio.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "创建桌面快捷方式"; GroupDescription: "附加任务:"

[Run]
Filename: "{app}\studio\ASTBStudio.exe"; Description: "启动 ASTB Studio"; Flags: postinstall nowait skipifsilent unchecked

[Code]
var
  VerPage: TWizardPage;
  VerList: TNewCheckListBox;
  DetectedVers, DetectedExes, DetectedRoots: TStringList;

const
  MARK_BEGIN = ';; >>> ASTB TOOLBOX BEGIN >>>';
  MARK_END   = ';; <<< ASTB TOOLBOX END <<<';

function Slash(const S: String): String;
begin
  Result := S;
  StringChangeEx(Result, '\', '/', True);
end;

procedure TryAddVersion(const Root: String);
var
  exe1, exe2, exe, ver, dirName: String;
begin
  exe1 := Root + '\tools\bin\allegro.exe';
  exe2 := Root + '\tools\pcb\bin\allegro.exe';
  exe := '';
  if FileExists(exe1) then exe := exe1
  else if FileExists(exe2) then exe := exe2;
  if exe = '' then Exit;
  exe := Slash(exe);
  if DetectedExes.IndexOf(exe) >= 0 then Exit;  { dedupe by exe path }
  dirName := ExtractFileName(Root);
  ver := dirName;
  if Copy(ver, 1, 4) = 'SPB_' then
  begin
    ver := Copy(ver, 5, Length(ver));
    StringChangeEx(ver, '_', '.', True);
  end;
  DetectedVers.Add(ver);
  DetectedExes.Add(exe);
  DetectedRoots.Add(Root);
end;

procedure ScanAllegroVersions();
var
  di: Integer;
  base, dirName, exe1, exe2, ver: String;
  FR: TFindRec;
begin
  DetectedVers := TStringList.Create;
  DetectedExes := TStringList.Create;
  DetectedRoots := TStringList.Create;
  for di := Ord('C') to Ord('Z') do
  begin
    base := Chr(di) + ':\Cadence';
    if not DirExists(base) then Continue;
    if FindFirst(base + '\SPB_*', FR) then
    begin
      try
        repeat
          if (FR.Attributes and $10) = 0 then Continue;
          dirName := FR.Name;
          if (dirName = '.') or (dirName = '..') then Continue;
          TryAddVersion(base + '\' + dirName);
        until not FindNext(FR);
      finally
        FindClose(FR);
      end;
    end;
  end;
  { %CDSROOT% env var (non-standard install layouts); dedupe inside }
  base := GetEnv('CDSROOT');
  if (base <> '') and DirExists(base) then
    TryAddVersion(base);
end;

procedure InitializeWizard();
var
  i: Integer;
begin
  ScanAllegroVersions();
  VerPage := CreateCustomPage(wpSelectDir,
    '选择要挂接的 Allegro 版本',
    '安装程序会把工具箱加载块写入所选版本的 allegro.ilinit');
  VerList := TNewCheckListBox.Create(VerPage);
  VerList.Parent := VerPage.Surface;
  VerList.Align := alClient;
  if DetectedVers.Count = 0 then
    VerList.AddCheckBox('（未检测到 Cadence SPB 安装，可安装后手工挂接）', '', 0,
      False, True, False, True, nil)
  else
    for i := 0 to DetectedVers.Count - 1 do
      VerList.AddCheckBox('Allegro ' + DetectedVers[i] + '    (' + DetectedExes[i] + ')',
        '', 0, True, True, False, True, nil);
end;

{ Canonical block lives in skill/core/ilinit_block.il (single source of
  truth, also read by the Studio migration wizard at runtime). The
  constant below is kept byte-identical with that file - the
  install-time source may be stripped by 'skipifsourcedoesntexist', so
  the installer cannot rely on reading it back. }
function BuildIlinitBlock(const InstallDir: String): String;
begin
  Result :=
    MARK_BEGIN + #13#10 +
    ';; allegro_skill auto-load entry (written by ASTB installer)' + #13#10 +
    ';; Encoding: ASCII' + #13#10 +
    'ASTB_INSTALL_DIR = "' + Slash(InstallDir) + '/skill"' + #13#10 +
    'errset(' + #13#10 +
    '  prog((cur v)' + #13#10 +
    '    foreach( v list("FORMPATH" "BITMAPPATH" "BMPPATH")' + #13#10 +
    '      cur = axlGetVariableList(v)' + #13#10 +
    '      when( stringp(cur) cur = list(cur) )' + #13#10 +
    '      unless( and(cur member(strcat(ASTB_INSTALL_DIR "/forms") cur))' + #13#10 +
    '        axlSetVariable(v cons(strcat(ASTB_INSTALL_DIR "/forms") cur))' + #13#10 +
    '      )' + #13#10 +
    '    )' + #13#10 +
    '  )' + #13#10 +
    '  t' + #13#10 +
    ')' + #13#10 +
    'setSkillPath(cons(ASTB_INSTALL_DIR getSkillPath()))' + #13#10 +
    'load(strcat(ASTB_INSTALL_DIR "/main.il"))' + #13#10 +
    MARK_END + #13#10;
end;

{ Merge marker block into one ilinit file. Returns: 1=merged, 0=created,
  -1=skipped (legacy unmanaged ASTB block found) }
function MergeIlinitEx(const FileName, InstallDir: String;
  StripOnly: Boolean): Integer;
var
  Lines: TStringList;
  i, b, e: Integer;
  legacy: Boolean;
  content, block: String;
begin
  Result := 0;
  Lines := TStringList.Create;
  try
    legacy := False;
    if FileExists(FileName) then
    begin
      Lines.LoadFromFile(FileName);
      { drop existing marker block }
      b := -1; e := -1;
      for i := 0 to Lines.Count - 1 do
      begin
        if Pos(MARK_BEGIN, Lines[i]) > 0 then b := i;
        if Pos(MARK_END, Lines[i]) > 0 then begin e := i; Break; end;
      end;
      if (b >= 0) and (e >= b) then
        for i := e downto b do Lines.Delete(i);
      { legacy unmanaged block? leave the file alone }
      for i := 0 to Lines.Count - 1 do
        if Pos('ASTB_INSTALL_DIR', Lines[i]) > 0 then begin legacy := True; Break; end;
      if legacy then
      begin
        Log('legacy ASTB block found in ' + FileName + ', skipped (merge manually)');
        Result := -1;
        Exit;
      end;
      Result := 1;
    end
    else if StripOnly then
      Exit;  { nothing to strip }
    if StripOnly then
      block := ''
    else
      block := BuildIlinitBlock(InstallDir);
    if Lines.Count > 0 then
    begin
      content := Lines.Text;
      if block <> '' then
        content := content + #13#10 + block;
    end
    else
      content := block;
    ForceDirectories(ExtractFileDir(FileName));
    Lines.Clear;
    Lines.Text := content;
    Lines.SaveToFile(FileName);
  finally
    Lines.Free;
  end;
end;

function MergeIlinit(const FileName, InstallDir: String): Integer;
begin
  Result := MergeIlinitEx(FileName, InstallDir, False);
end;

procedure StripIlinit(const FileName: String);
begin
  if FileExists(FileName) then
    MergeIlinitEx(FileName, '', True);
end;

procedure HookVersion(const Root, InstallDir: String);
var
  home, pcbenv, siteSkill: String;
begin
  home := GetEnv('HOME');
  if home = '' then home := GetEnv('USERPROFILE');
  pcbenv := home + '\pcbenv\allegro.ilinit';
  MergeIlinit(pcbenv, InstallDir);
  siteSkill := Root + '\share\local\pcb\skill\allegro.ilinit';
  MergeIlinit(siteSkill, InstallDir);
end;

{ Extract the current toolbox_root value from an existing config.json.
  Simple single-line scan (the file is written by us / Studio with one
  key per line); returns '' when the key is absent. }
{ Find the Nth double-quote (1-based) in S from position From. }
function FindQuote(const S: String; From: Integer): Integer;
var
  k: Integer;
begin
  for k := From to Length(S) do
    if S[k] = '"' then
    begin
      Result := k;
      Exit;
    end;
  Result := 0;
end;

function ReadToolboxRoot(const FileName: String): String;
var
  Lines: TStringList;
  i, p, q1, q2: Integer;
  ln, key: String;
begin
  Result := '';
  if not FileExists(FileName) then Exit;
  Lines := TStringList.Create;
  try
    Lines.LoadFromFile(FileName);
    key := '"toolbox_root"';
    for i := 0 to Lines.Count - 1 do
    begin
      ln := Lines[i];
      p := Pos(key, ln);
      if p = 0 then Continue;
      p := Pos(':', ln);
      if p = 0 then Continue;
      q1 := FindQuote(ln, p + 1);
      if q1 = 0 then Continue;
      q2 := FindQuote(ln, q1 + 1);
      if q2 = 0 then Continue;
      Result := Copy(ln, q1 + 1, q2 - q1 - 1);
      Exit;
    end;
  finally
    Lines.Free;
  end;
end;

{ Rewrite only the toolbox_root line inside an existing config.json,
  leaving every other user field (versions, scan_dirs, mru, ...)
  untouched. }
procedure PatchToolboxRoot(const FileName, NewRoot: String);
var
  Lines: TStringList;
  i: Integer;
  replaced: Boolean;
begin
  Lines := TStringList.Create;
  try
    Lines.LoadFromFile(FileName);
    replaced := False;
    for i := 0 to Lines.Count - 1 do
      if Pos('"toolbox_root"', Lines[i]) > 0 then
      begin
        Lines[i] := '  "toolbox_root": "' + NewRoot + '",';
        replaced := True;
        Break;
      end;
    if not replaced then
    begin
      { key missing: insert after the opening brace }
      if Lines.Count > 0 then
        Lines.Insert(1, '  "toolbox_root": "' + NewRoot + '",')
      else
        Lines.Add('  "toolbox_root": "' + NewRoot + '",');
    end;
    Lines.SaveToFile(FileName);
  finally
    Lines.Free;
  end;
end;

procedure SeedStudioConfig(const InstallDir: String);
var
  dir, fn, json, vers, curRoot, wantRoot: String;
  i: Integer;
begin
  dir := GetEnv('USERPROFILE') + '\.astb_studio';
  fn := dir + '\config.json';
  wantRoot := Slash(InstallDir) + '/skill';

  { toolbox_root is an install fact (points at the files THIS setup just
    laid down), not a user preference: a stale value silently blanks the
    hotkey/help/command panels. So even when config.json already exists
    (user data to preserve), realign toolbox_root whenever it is missing
    or no longer names a live toolbox, while leaving all other fields
    untouched. }
  if FileExists(fn) then
  begin
    curRoot := ReadToolboxRoot(fn);
    if (curRoot <> '') and FileExists(curRoot + '\main.il') then
    begin
      Log('studio config toolbox_root valid, kept: ' + curRoot);
      Exit;
    end;
    PatchToolboxRoot(fn, wantRoot);
    Log('studio config toolbox_root realigned: "' + curRoot +
        '" -> "' + wantRoot + '" (other fields preserved)');
    Exit;
  end;

  vers := '';
  for i := 0 to DetectedVers.Count - 1 do
  begin
    if vers <> '' then vers := vers + ','#13#10;
    vers := vers + '    "' + DetectedVers[i] + '": "' + DetectedExes[i] + '"';
  end;
  json := '{'#13#10 +
    '  "versions": {'#13#10 + vers + #13#10'  },'#13#10;
  if DetectedVers.Count > 0 then
    json := json + '  "default_version": "' + DetectedVers[0] + '",'#13#10;
  json := json +
    '  "toolbox_root": "' + wantRoot + '",'#13#10 +
    '  "mru": [],'#13#10 +
    '  "scan_dirs": [],'#13#10 +
    '  "health_auto": true'#13#10 +
    '}'#13#10;
  ForceDirectories(dir);
  SaveStringToFile(fn, json, False);
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  i: Integer;
begin
  if CurStep <> ssPostInstall then Exit;
  if DetectedVers.Count > 0 then
    for i := 0 to DetectedVers.Count - 1 do
      if VerList.Checked[i] then
        HookVersion(DetectedRoots[i], WizardDirValue);
  SeedStudioConfig(WizardDirValue);
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  i: Integer;
  home: String;
begin
  if CurUninstallStep <> usPostUninstall then Exit;
  { best effort: strip our marker blocks from pcbenv + site ilinit }
  ScanAllegroVersions();
  home := GetEnv('HOME');
  if home = '' then home := GetEnv('USERPROFILE');
  StripIlinit(home + '\pcbenv\allegro.ilinit');
  for i := 0 to DetectedRoots.Count - 1 do
    StripIlinit(DetectedRoots[i] + '\share\local\pcb\skill\allegro.ilinit');
end;
