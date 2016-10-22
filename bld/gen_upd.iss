; Script generated by the Inno Script Studio Wizard.
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

#define MyAppName "TweetDuck"
#define MyAppPublisher "chylex"
#define MyAppURL "https://tweetduck.chylex.com"
#define MyAppExeName "TweetDuck.exe"

#define MyAppID "8C25A716-7E11-4AAD-9992-8B5D0C78AE06"
#define MyAppVersion GetFileVersion("..\bin\x86\Release\TweetDuck.exe")
#define CefVersion "3.2785.1478.0"

[Setup]
AppId={{{#MyAppID}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={pf}\{#MyAppName}
DefaultGroupName={#MyAppName}
OutputBaseFilename={#MyAppName}.Update
VersionInfoVersion={#MyAppVersion}
LicenseFile=.\Resources\LICENSE
SetupIconFile=.\Resources\icon.ico
Uninstallable=TDIsUninstallable
UninstallDisplayName={#MyAppName}
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma
SolidCompression=yes
InternalCompressLevel=max
MinVersion=0,6.1

#include <idp.iss>

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
Source: "..\bin\x86\Release\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\bin\x86\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: "*.xml,*.dll,*.pak,*.bin,*.dat"

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Check: TDIsUninstallable

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall shellexec

[InstallDelete]
Type: files; Name: "{app}\*.xml"
Type: files; Name: "{app}\*.js"
Type: files; Name: "{app}\d3dcompiler_43.dll"
Type: files; Name: "{app}\devtools_resources.pak"
Type: files; Name: "{app}\CefSharp.BrowserSubprocess.exe"
Type: files; Name: "{app}\td-log.txt"
Type: files; Name: "{app}\debug.log"
Type: files; Name: "{localappdata}\{#MyAppName}\ChromeDWriteFontCache"

[UninstallDelete]
Type: files; Name: "{app}\*.*"
Type: filesandordirs; Name: "{app}\locales"
Type: filesandordirs; Name: "{app}\scripts"
Type: filesandordirs; Name: "{localappdata}\{#MyAppName}\Cache"
Type: filesandordirs; Name: "{localappdata}\{#MyAppName}\GPUCache"

[Code]
function TDIsUninstallable: Boolean; forward;
function TDFindUpdatePath: String; forward;
function TDGetNetFrameworkVersion: Cardinal; forward;
function TDGetAppVersionClean: String; forward;
function TDIsMatchingCEFVersion: Boolean; forward;
procedure TDExecuteFullDownload; forward;

var IsPortable: Boolean;
var UpdatePath: String;

{ Check .NET Framework version on startup, ask user if they want to proceed if older than 4.5.2. Prepare full download package if required. }
function InitializeSetup: Boolean;
begin
  IsPortable := ExpandConstant('{param:PORTABLE}') = '1'
  UpdatePath := TDFindUpdatePath()
  
  if UpdatePath = '' then
  begin
    MsgBox('{#MyAppName} installation could not be found on your system.', mbCriticalError, MB_OK);
    Result := False;
    Exit;
  end;
  
  if not TDIsMatchingCEFVersion() then
  begin
    idpAddFile('https://github.com/{#MyAppPublisher}/{#MyAppName}/releases/download/'+TDGetAppVersionClean()+'/{#MyAppName}.exe', ExpandConstant('{tmp}\{#MyAppName}.Full.exe'));
  end;
  
  if TDGetNetFrameworkVersion() >= 379893 then
  begin
    Result := True;
    Exit;
  end;
  
  if (MsgBox('{#MyAppName} requires .NET Framework 4.5.2 or newer,'+#13+#10+'please download it from {#MyAppURL}'+#13+#10+#13+#10'Do you want to proceed with the setup anyway?', mbCriticalError, MB_YESNO or MB_DEFBUTTON2) = IDNO) then
  begin
    Result := False;
    Exit;
  end;
  
  Result := True;
end;

{ Prepare download plugin if there are any files to download, and set the installation path. }
procedure InitializeWizard();
begin
  WizardForm.DirEdit.Text := UpdatePath;
  
  if idpFilesCount <> 0 then
  begin
    idpDownloadAfter(wpReady);
  end;
end;

{ Ask user if they want to delete 'AppData\TweetDuck' and 'plugins' folders after uninstallation. }
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var ProfileDataFolder: String;
var PluginDataFolder: String;

begin
  if CurUninstallStep = usPostUninstall then
  begin
    ProfileDataFolder := ExpandConstant('{localappdata}\{#MyAppName}');
    PluginDataFolder := ExpandConstant('{app}\plugins');
    
    if (DirExists(ProfileDataFolder) or DirExists(PluginDataFolder)) and (MsgBox('Do you also want to delete your {#MyAppName} profile and plugins?', mbConfirmation, MB_YESNO or MB_DEFBUTTON2) = IDYES) then
    begin
      DelTree(ProfileDataFolder, True, True, True);
      DelTree(PluginDataFolder, True, True, True);
      DelTree(ExpandConstant('{app}'), True, False, False);
    end;
  end;
end;

{ Remove uninstallation data and application to force them to be replaced with updated ones. }
procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssInstall then
  begin
    TDExecuteFullDownload();
    
    if TDIsUninstallable() then
    begin
      DeleteFile(ExpandConstant('{app}\unins000.dat'));
      DeleteFile(ExpandConstant('{app}\unins000.exe'));
    end;
  end;
end;

{ Returns true if the installer should create uninstallation entries (i.e. not running in portable mode). }
function TDIsUninstallable: Boolean;
begin
  Result := not IsPortable
end;

{ Returns a validated installation path (including trailing backslash) using the /UPDATEPATH parameter or installation info in registry. Returns empty string on failure. }
function TDFindUpdatePath: String;
var Path: String;

begin
  Path := ExpandConstant('{param:UPDATEPATH}')
  
  if (Path = '') and not IsPortable and not RegQueryStringValue(HKEY_LOCAL_MACHINE, 'Software\Microsoft\Windows\CurrentVersion\Uninstall\{{#MyAppID}}_is1', 'InstallLocation', Path) then
  begin
    Result := ''
    Exit
  end;
  
  if not FileExists(Path+'{#MyAppExeName}') then
  begin
    Result := ''
    Exit
  end;
  
  Result := Path
end;

{ Return DWORD value containing the build version of .NET Framework. }
function TDGetNetFrameworkVersion: Cardinal;
var FrameworkVersion: Cardinal;

begin
  if RegQueryDWordValue(HKEY_LOCAL_MACHINE, 'Software\Microsoft\NET Framework Setup\NDP\v4\Full', 'Release', FrameworkVersion) then
  begin
    Result := FrameworkVersion;
    Exit;
  end;
  
  Result := 0;
end;

{ Return whether the version of the installed libcef.dll library matches internal one. }
function TDIsMatchingCEFVersion: Boolean;
var CEFVersion: String;

begin
  Result := (GetVersionNumbersString(UpdatePath+'libcef.dll', CEFVersion) and (CompareStr(CEFVersion, '{#CefVersion}') = 0))
end;

{ Return a cleaned up form of the app version string (removes all .0 suffixes). }
function TDGetAppVersionClean: String;
var Substr: String;
var CleanVersion: String;

begin
  CleanVersion := '{#MyAppVersion}'
  
  while True do
  begin
    Substr := Copy(CleanVersion, Length(CleanVersion)-1, 2);
    
    if (CompareStr(Substr, '.0') <> 0) then
    begin
      break;
    end;
    
    CleanVersion := Copy(CleanVersion, 1, Length(CleanVersion)-2);
  end;
  
  Result := CleanVersion;
end;

{ Run the full package installer if downloaded. }
procedure TDExecuteFullDownload;
var InstallFile: String;
var ResultCode: Integer;

begin
  InstallFile := ExpandConstant('{tmp}\{#MyAppName}.Full.exe')
  
  if FileExists(InstallFile) then
  begin
    WizardForm.ProgressGauge.Style := npbstMarquee;
    
    try
      if Exec(InstallFile, '/SP- /SILENT /MERGETASKS="!desktopicon" /UPDATEPATH="'+UpdatePath+'"', '', SW_SHOW, ewWaitUntilTerminated, ResultCode) then begin
        if ResultCode <> 0 then
        begin
          DeleteFile(InstallFile);
          Abort();
          Exit;
        end;
      end else
      begin
        MsgBox('Could not run the full installer, please visit {#MyAppURL} and download the latest version manually. Error: '+SysErrorMessage(ResultCode), mbCriticalError, MB_OK);
        
        DeleteFile(InstallFile);
        Abort();
        Exit;
      end;
    finally
      WizardForm.ProgressGauge.Style := npbstNormal;
      DeleteFile(InstallFile);
    end;
  end;
end;
