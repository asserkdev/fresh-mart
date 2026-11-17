; Fresh Mart v7 — Inno Setup Installer Script
; Installs: Godot 4 runtime + Fresh Mart project, creates desktop shortcut,
;           creates launcher .bat, downloads Godot if not found.

#define AppName "Fresh Mart"
#define AppVersion "7.0.0"
#define AppPublisher "Fresh Mart Project"
#define AppURL "https://asserkdev.github.io/fresh-mart/"
#define AppExeName "FreshMart.bat"
#define GodotURL "https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_win64.exe.zip"

[Setup]
AppId={{B8F3E42A-1C9D-4F7A-B2E6-9A3D8C5F0E71}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppURL}
AppSupportURL={#AppURL}
AppUpdatesURL=https://github.com/asserkdev/fresh-mart/releases
DefaultDirName={autopf}\FreshMart
DefaultGroupName={#AppName}
AllowNoIcons=no
LicenseFile=..\LICENSE
OutputDir=..\build\installer
OutputBaseFilename=FreshMart_v7_Setup
SetupIconFile=..\assets\icons\icon.ico
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
WizardImageFile=wizard_assets\wizard_banner.bmp
WizardSmallImageFile=wizard_assets\wizard_small.bmp
DisableWelcomePage=no
DisableDirPage=no
DisableReadyPage=no
ShowLanguageDialog=no
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
UninstallDisplayIcon={app}\assets\icons\icon.ico
UninstallDisplayName={#AppName} {#AppVersion}
VersionInfoVersion={#AppVersion}
VersionInfoCompany={#AppPublisher}
VersionInfoDescription={#AppName} - Supermarket Simulator

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[CustomMessages]
english.WelcomeLabel2=This will install [name/ver] on your computer.%n%nFresh Mart is a supermarket simulator, city builder, and RPG built with Godot 4.%n%nClick Next to continue.
english.FinishedLabel=Fresh Mart has been installed on your computer.%n%nClick Finish to launch the game.

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut"; GroupDescription: "Additional icons:"
Name: "startmenuicon"; Description: "Create a Start Menu shortcut"; GroupDescription: "Additional icons:"

[Files]
; Game project files
Source: "..\project.godot"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\scenes\*"; DestDir: "{app}\scenes"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\scripts\*"; DestDir: "{app}\scripts"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\assets\*"; DestDir: "{app}\assets"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\ui\*"; DestDir: "{app}\ui"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\resources\*"; DestDir: "{app}\resources"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\README.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\CHANGELOG.md"; DestDir: "{app}"; Flags: ignoreversion
; Launcher scripts
Source: "launcher\FreshMart.bat"; DestDir: "{app}"; Flags: ignoreversion
Source: "launcher\FreshMart.vbs"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\FreshMart.vbs"; IconFilename: "{app}\assets\icons\icon.ico"; Comment: "Play Fresh Mart"
Name: "{group}\Uninstall {#AppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\FreshMart.vbs"; IconFilename: "{app}\assets\icons\icon.ico"; Comment: "Play Fresh Mart - Supermarket Simulator"; Tasks: desktopicon

[Run]
Filename: "{app}\FreshMart.vbs"; Description: "Launch {#AppName}"; Flags: nowait postinstall skipifsilent shellexec; Check: GodotInstalled

[Code]
var
  GodotPage: TInputQueryWizardPage;
  GodotPathLabel: TLabel;
  GodotFoundLabel: TLabel;
  GodotExePath: String;
  DownloadPage: TDownloadWizardPage;

function GodotInstalled(): Boolean;
var
  WinGetPath: String;
  ProgramFiles: String;
begin
  Result := False;
  
  // Check WinGet install path
  WinGetPath := ExpandConstant('{localappdata}') + '\Microsoft\WinGet\Links\godot.exe';
  if FileExists(WinGetPath) then begin
    GodotExePath := WinGetPath;
    Result := True;
    Exit;
  end;
  
  // Search common install paths
  ProgramFiles := ExpandConstant('{pf}');
  if FileExists(ProgramFiles + '\Godot\Godot_v4.3-stable_win64.exe') then begin
    GodotExePath := ProgramFiles + '\Godot\Godot_v4.3-stable_win64.exe';
    Result := True;
    Exit;
  end;
  
  // Search AppData WinGet packages
  WinGetPath := ExpandConstant('{localappdata}') + '\Microsoft\WinGet\Packages';
  // We'll check if any godot exe exists via the VBS launcher
end;

procedure InitializeWizard();
begin
  DownloadPage := CreateDownloadPage(SetupMessage(msgWizardPreparing), SetupMessage(msgPreparingDesc), nil);
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;
  
  if CurPageID = wpReady then begin
    if not GodotInstalled() then begin
      // We'll install Godot via winget in the launcher
      MsgBox('Godot 4 was not found. The launcher will install it automatically on first run using Windows Package Manager (winget).', mbInformation, MB_OK);
    end;
  end;
end;

function GetGodotPath(Param: String): String;
begin
  Result := GodotExePath;
end;
