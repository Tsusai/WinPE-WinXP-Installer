unit Driveselect;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, RTTICtrls, SynEdit, Forms, Controls,
  Graphics, Dialogs, StdCtrls, ExtCtrls, ComCtrls, Windows, LMessages;

type

  { TSetupFrm }

  TSetupFrm = class(TForm)
    BackBtn: TButton;
    BackupBox: TCheckBox;
    DescLabel: TLabel;
    DriveList: TListView;
    Image1: TImage;
    Image2: TImage;
    Image3: TImage;
    InfoLabel: TLabel;
    InstallBtn: TButton;
    NextBtn1: TButton;
    Notebook1: TNotebook;
    DriveIconList: TImageList;
    OEMBox: TComboBox;
    OSBox: TListView;
    OutputBox: TMemo;
    Page1: TPage;
    Page2: TPage;
    Page3: TPage;
    PartLabel: TLabel;
    RebootBtn: TButton;
    RefreshClickBtn: TLabel;
    procedure BackBtnClick(Sender: TObject);
    procedure DriveListClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure InstallBtnClick(Sender: TObject);
    procedure NextBtn1Click(Sender: TObject);
    procedure OSBoxClick(Sender: TObject);
    procedure Page1BeforeShow(ASender: TObject; ANewPage: TPage;
      ANewIndex: Integer);
    procedure PartLabelClick(Sender: TObject);
    procedure RebootBtnClick(Sender: TObject);
    procedure RefreshClickBtnClick(Sender: TObject);
  private
    { private declarations }
    procedure LMSysCommand(var Msg: TLMSysCommand); message LM_SYSCOMMAND;
  public
    { public declarations }
    procedure RefreshDrives;
    procedure StartPartitionWizard;
    procedure InstallXP;
  end;

var
  SetupFrm: TSetupFrm;

implementation
uses
  Main,
  INIFiles,
  ShellAPI;

{$R *.lfm}

procedure RunAndWait(
  ExecuteFile : string;
  ParamString : string = '';
  StartInString : string = '');
var
  SEInfo: TShellExecuteInfoA;
  ExitCode: DWORD = 0;
//  StartInString: string;
begin
  FillChar(SEInfo, SizeOf(SEInfo), 0) ;
  SEInfo.cbSize := SizeOf(TShellExecuteInfo) ;
  with SEInfo do begin
    fMask := SEE_MASK_NOCLOSEPROCESS;
    Wnd := GetDesktopWindow;
    lpFile := PChar(ExecuteFile) ;

    {
    ParamString can contain the
    application parameters.
    }
    lpParameters := PChar(ParamString) ;
    {
    StartInString specifies the
    name of the working directory.
    If ommited, the current directory is used.
    }
    lpDirectory := PChar(StartInString) ;

    nShow := SW_SHOWNORMAL;
  end;
  if ShellExecuteExA(@SEInfo) then begin
    repeat
      Application.ProcessMessages;
      GetExitCodeProcess(SEInfo.hProcess, ExitCode) ;
    until (ExitCode <> STILL_ACTIVE) or Application.Terminated;
    //ShowMessage('Completed') ;
  end else ShowMessage('Error starting '+ ExecuteFile + ' ' + ParamString) ;
end;

function BytesToDisplay(A:int64): string;
var
  A1, A2, A3: double;
begin
  A1 := A / 1024;
  A2 := A1 / 1024;
  A3 := A2 / 1024;
  if A1 < 1 then Result := floattostrf(A, ffNumber, 15, 0) + ' bytes'
  else if A1 < 10 then Result := floattostrf(A1, ffNumber, 15, 2) + ' KB'
  else if A1 < 100 then Result := floattostrf(A1, ffNumber, 15, 1) + ' KB'
  else if A2 < 1 then Result := floattostrf(A1, ffNumber, 15, 0) + ' KB'
  else if A2 < 10 then Result := floattostrf(A2, ffNumber, 15, 2) + ' MB'
  else if A2 < 100 then Result := floattostrf(A2, ffNumber, 15, 1) + ' MB'
  else if A3 < 1 then Result := floattostrf(A2, ffNumber, 15, 0) + ' MB'
  else if A3 < 10 then Result := floattostrf(A3, ffNumber, 15, 2) + ' GB'
  else if A3 < 100 then Result := floattostrf(A3, ffNumber, 15, 1) + ' GB'
  else Result := floattostrf(A3, ffNumber, 15, 0) + ' GB';
  //Result := Result + ' (' + floattostrf(A, ffNumber, 15, 0) + ' bytes)';
end;

procedure Execute(
  Command : string;
  Params : string = '';
  StartFolder : string = '');
begin
  ShellExecute(
    Form1.Handle,
    'open',
    PChar(Command),
    PChar(Params),
    PChar(StartFolder),
    SW_SHOWNORMAL);
end;

procedure CaptureConsoleOutput(const ACommand, AParameters: String; AMemo: TMemo);
const
  CReadBuffer = 2400;
var
  saSecurity: TSecurityAttributes;
  hRead: THandle=0;
  hWrite: THandle=0;
  suiStartup: TStartupInfo;
  piProcess: TProcessInformation;
  pBuffer: array[0..CReadBuffer] of Char;
  dRead: DWord;
  dRunning: DWord;
  ReadPipeOK : boolean;
  BytesRead : DWORD;
begin
  saSecurity.nLength := SizeOf(TSecurityAttributes);
  saSecurity.bInheritHandle := True;
  saSecurity.lpSecurityDescriptor := nil;

  if CreatePipe(hRead, hWrite, @saSecurity, 0) then
  begin
    FillChar(suiStartup, SizeOf(TStartupInfo), #0);
    suiStartup.cb := SizeOf(TStartupInfo);
    suiStartup.hStdInput := hRead;
    suiStartup.hStdOutput := hWrite;
    suiStartup.hStdError := hWrite;
    suiStartup.dwFlags := STARTF_USESTDHANDLES or STARTF_USESHOWWINDOW;
    suiStartup.wShowWindow := SW_HIDE;

    if CreateProcess(nil, PChar(ACommand + ' ' + AParameters), @saSecurity,
      @saSecurity, True, NORMAL_PRIORITY_CLASS, nil, nil, suiStartup, piProcess)
    then
    begin
      repeat
        dRunning  := WaitForSingleObject(piProcess.hProcess, 100);
        Application.ProcessMessages();
        repeat
          dRead := 0;
          //MUST LOOK AT PIPE ELSE IT WILL HANG WITH SOME APPS
          ReadPipeOK := PeekNamedPipe(hRead,nil,CReadBuffer,nil,@BytesRead,nil);
          if (ReadPipeOK and (BytesRead>0)) then
          begin
            //We're good to read
            dRead := FileRead(hRead, pBuffer[0], CReadBuffer);
            pBuffer[dRead] := #0;
            OemToAnsi(pBuffer, pBuffer);
            AMemo.Lines.Add(String(pBuffer));
          end;
        until (dRead < CReadBuffer);
      until (dRunning <> WAIT_TIMEOUT);
      FileClose(piProcess.hProcess);
      FileClose(piProcess.hThread);
    end;

    FileClose(hRead);
    FileClose(hWrite);
  end;
end;


{ TSetupFrm }
//Stop moving the window
procedure TSetupFrm.LMSysCommand(var Msg: TLMSysCommand);
begin
  if ((Msg.CmdType and $FFF0) = SC_MOVE) or
    ((Msg.CmdType and $FFF0) = SC_SIZE) then
  begin
    Msg.Result := 0;
  end else;
  inherited;
end;

{-------------------------}
{-----------OS SELECT PAGE}
{-------------------------}

//Pick an OS
procedure TSetupFrm.OSBoxClick(Sender: TObject);
begin
  case OSBox.ItemIndex of
  0: InfoLabel.Caption := 'Windows XP Home OEM Edition';
  1: InfoLabel.Caption := 'Windows XP Home Retail Edition';
  2: InfoLabel.Caption := 'Windows XP Professional OEM Edition';
  3: InfoLabel.Caption := 'Windows XP Professional Retail Edition';
  end;
  if (OSBox.ItemIndex in [0..3]) then
  begin
    NextBtn1.Enabled := true;
  end else
  begin
    NextBtn1.Enabled := false;
    InfoLabel.Caption := 'No OS Selected';
  end;
end;

procedure TSetupFrm.Page1BeforeShow(ASender: TObject; ANewPage: TPage;
  ANewIndex: Integer);
begin

end;

//Going to the Drive Select Page
procedure TSetupFrm.NextBtn1Click(Sender: TObject);
begin
  RefreshDrives;
  Notebook1.PageIndex:=1;
  if DriveList.Items.Count = 0 then StartPartitionWizard;
  //If we have selected an OEM version of XP, Enable/Disable OEM Activation
  if not Odd(OSBox.ItemIndex) then OEMBox.Enabled := true
  else OEMBox.Enabled := false;
end;

{-------------------------}
{--------DRIVE SELECT PAGE}
{-------------------------}
//Refresh Drive List
procedure TSetupFrm.RefreshDrives;
var
  Drive: Char;
  DriveLetter: string;
  DriveNumber : byte;
  freespace : int64;
  space : int64;
  ListItem : TListItem;
begin
  DriveList.Items.Clear;
  for Drive := 'A' to 'Z' do
  begin
    if WinPE and (Drive = 'X') then continue;
    //Get the Drive # for whatever drive we're on
    //ie A=1 B=2 C=3
    //DriveSpace and DriveFree need these
    DriveNumber := 1 + Ord(Drive) - Ord('A');
    DriveLetter := Drive + ':\';
    //Ignoring non Fixed Drives
    if GetDriveType(PChar(DriveLetter)) = DRIVE_FIXED then
    begin
      freespace := DiskFree(DriveNumber);
      space := DiskSize(DriveNumber);
      ListItem := DriveList.Items.Add;
      ListItem.Caption := DriveLetter;
      ListItem.SubItems.Add(BytesToDisplay(space));
      ListItem.SubItems.Add(BytesToDisplay(freespace));
      ListItem.SubItems.Add('Fixed Disk');
      //Add the XP Drive Icon
      ListItem.ImageIndex:=0;
    end;
  end;
end;

{-------------------------}
{--------DRIVE SELECT PAGE}
{-------------------------}
procedure TSetupFrm.StartPartitionWizard;
begin
  InstallBtn.Enabled := false;
  DriveList.Enabled := false;
  try
    RunAndWait(SourcePath + 'PartitionWizard\PartitionWizard.exe');
  Finally
    DriveList.Enabled := true;
    RefreshDrives;
    InstallBtn.Enabled := true;
  end;
end;

//Picking a drive
procedure TSetupFrm.DriveListClick(Sender: TObject);
begin
  if DriveList.Itemindex > -1 then InstallBtn.Enabled := true else InstallBtn.Enabled := false;
end;

procedure TSetupFrm.InstallBtnClick(Sender: TObject);
begin
  if DriveList.ItemIndex > -1 then
  begin
    Notebook1.PageIndex:=2;
    InstallXP;
    RebootBtn.Enabled := true;
  end else InstallBtn.Enabled := false;
end;

procedure TSetupFrm.PartLabelClick(Sender: TObject);
begin
  StartPartitionWizard;
end;

procedure TSetupFrm.RefreshClickBtnClick(Sender: TObject);
begin
  RefreshDrives;
end;

procedure TSetupFrm.BackBtnClick(Sender: TObject);
begin
  Notebook1.PageIndex:=0;
end;

{-------------------------}
{---------------INSTALL XP}
{-------------------------}
procedure TSetupFrm.InstallXP;
const
  CParamStr = '/apply %s %d %s';
var
  ParamStr : string;
  Drv : string;

  //Backsup everything
  procedure FolderCalledBackup;
  var
    searchResult : TSearchRec;
    BkName, BkDir : string;
  begin
    SetCurrentDirUTF8(Drv); { *Converted from SetCurrentDir* }
    BkName := 'Backup' + FormatDateTime('_ddmmyy_hhnn',Now);
    BkDir := Drv + '\' + BkName;
    ForceDirectoriesUTF8(BkDir); { *Converted from ForceDirectories* }

    if FindFirstUTF8('*',faAnyFile or faDirectory,searchResult) { *Converted from FindFirst* } = 0 then
    begin
      repeat
        if searchResult.Name = BkName then continue; //skip new backup folder
        OutputBox.Lines.Add('Backing up: ' + searchResult.Name);
        try
          RenameFileUTF8(Drv + '\' + searchResult.Name,BkDir + '\' + searchResult.Name
          ); { *Converted from RenameFile* }
        except
          OutputBox.Lines.Add('ERROR: Could not backup ['+ searchResult.Name +']');
        end;
      until FindNextUTF8(searchResult) { *Converted from FindNext* } <> 0;
      // Must free up resources used by these successful finds
      FindCloseUTF8(searchResult); { *Converted from FindClose* }
    end;
  end;

  //OEM ACTIVATION
  procedure OEMActivate;
  const
    WinSetup = '\$WIN_NT$.~LS\I386';
    Keys : Array [1..4,1..2] of string = (
      //Home, Pro, OEM
      ('CXCY9-TTHBT-36J2P-HT3T3-QPMFB','BW2VG-XXDY6-VW3P7-YHQQ6-C7RYM'), //ACER
      ('RCBF6-6KDMK-GD6GR-K6DP3-4C8MT','XJM6Q-BQ8HW-T6DFB-Y934T-YD4YT'), //DELL
      ('MK48G-CG8VJ-BRVBB-38MQ9-3PMFT','DMQBW-V8D4K-9BJ82-4PCJX-2WPB6'), //HP
      ('WDHPC-6WQPF-W3R3K-J2VF4-JFP8W','WDWCD-QBBPF-YCFC7-4P6RP-H8YF8') //TOSHIBA
    );
  var
    OEM : String;
    HomePro : byte;
    WINNTSIF : TIniFile;
  begin
  (*NO OEM ACTIVATION
  ACER
  DELL
  HP/COMPAQ
  TOSHIBA*)
    if (OEMBox.Enabled) and (OEMBox.ItemIndex in [1..4]) then
    begin
      HomePro := 1;
      Case OEMBox.ItemIndex of
      1: OEM := 'ACER';
      2: OEM := 'DELL';
      3: OEM := 'HP';
      4: OEM := 'TOSHIBA';
      end;

      //Copy OEMBIOS.*** files
      OutputBox.Lines.Add('Copying ' + OEM + ' Files');
      CopyFile(
        PChar( SourcePath + 'OEMFiles\' + OEM + '\OEMBIOS.BI_'),
        PChar( Drv + WinSetup + '\OEMBIOS.BI_'), false
      );
      CopyFile(
        PChar( SourcePath + 'OEMFiles\' + OEM + '\OEMBIOS.CA_'),
        PChar( Drv + WinSetup + '\OEMBIOS.CA_'), false
      );
      CopyFile(
        PChar( SourcePath + 'OEMFiles\' + OEM + '\OEMBIOS.DA_'),
        PChar( Drv + WinSetup + '\OEMBIOS.DA_'), false
      );
      CopyFile(
        PChar( SourcePath + 'OEMFiles\' + OEM + '\OEMBIOS.SI_'),
        PChar( Drv + WinSetup + '\OEMBIOS.SI_'), false
      );

      //Putting in Product Key
      OutputBox.Lines.Add('Editing Product Key');
      //Home or Pro?
      if OSBox.ItemIndex = 0 then HomePro := 1;
      if OSBox.ItemIndex = 2 then HomePro := 2;
      //Grab the Key, write in the OEM key
      OEM := Keys[OEMBox.ItemIndex,HomePro];
      //Reading our install automatition file, adding a key
      WINNTSIF := TIniFile.Create(Drv + '\$WIN_NT$.~BT\winnt.sif');
      WINNTSIF.WriteString('UserData','productid','"'+OEM+'"');
      WINNTSIF.WriteString('UserData','productkey','"'+OEM+'"');
      WINNTSIF.Free;
    end;
  end;

begin
  //Need C: or S: no trailing \'s
  Drv := DriveList.Items.Item[DriveList.ItemIndex].Caption[1..2];
  ParamStr := Format(CParamStr,
    [
    SourcePath + 'Install.wim',
    OSBox.ItemIndex+1,
    Drv
    ]
  );
  if BackupBox.Checked then FolderCalledBackup;
  OutputBox.Lines.Add('Applying Image.');
  CaptureConsoleOutput(
    SourcePath + 'imagex.exe',
    ParamStr,
    OutputBox
  );
  OutputBox.Lines.Add('Fixing Bootsector.');
  CaptureConsoleOutput(
    SourcePath + 'bootsect.exe',
    '/nt52 '+ Drv + ' /force /mbr',
    OutputBox
  );

  OEMActivate;
  OutputBox.Lines.Add('Done.  You may reboot to continue.');
end;

procedure TSetupFrm.RebootBtnClick(Sender: TObject);
begin
  Execute('WPEUtil','reboot');
end;


{-------------------------}
{----------Base Form Stuff}
{-------------------------}

procedure TSetupFrm.FormCreate(Sender: TObject);
begin
  Notebook1.PageIndex:=0;
  Self.ClientHeight:=424;
  Self.ClientWidth:=620;
end;

procedure TSetupFrm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  if Not(ModalResult in [Byte('A')..Byte('Z')]) then ModalResult := Byte('0');
end;

procedure TSetupFrm.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  If (Notebook1.PageIndex = 2) and
    (RebootBtn.Enabled = false) then CanClose := false;
end;

procedure TSetupFrm.FormShow(Sender: TObject);
begin
  Left:=(Form1.Width-Width)  div 2;
  Left:=Left+Form1.Left;
  Top:=(Form1.Height-Height) div 2;
  Top:=Top+Form1.Top;
end;

end.

