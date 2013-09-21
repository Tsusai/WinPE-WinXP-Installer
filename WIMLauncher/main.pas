unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls;

type

  { TForm1 }

  TForm1 = class(TForm)
    Timer1: TTimer;
    procedure Timer1Timer(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  Form1: TForm1;

implementation
uses
  Windows,
  LCLType,
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

{ TForm1 }

procedure TForm1.Timer1Timer(Sender: TObject);
var
  Drive : Char;
  Found : boolean = false;
  DriveLetter : string = '';
begin
  Timer1.Enabled:=false;
  RunAndWait('wpeinit.exe');
  Sleep(2000);
  for Drive := 'A' to 'Z' do
  begin
    if FileExists(Drive+':\AutoUnattend.xml') then
    begin
      RunAndWait('wpeinit.exe','/unattend='+Drive+':\Autounattend.xml');
      break;
    end;
  end;
  while not Found do
  begin
    for Drive := 'A' to 'Z' do
    begin
      DriveLetter := Drive + ':\';
      //Ignoring non Fixed Drives
      if GetDriveType(PChar(DriveLetter)) = DRIVE_CDROM then
      begin
        if (FileExists(DriveLetter + 'sources\Setup.exe')  and FileExists(DriveLetter + 'sources\install.wim')) then
        begin
          Found := true;
          RunAndWait(DriveLetter + 'sources\Setup.exe');
        end;
      end
    end;
    If not Found then
    begin
      Case MessageDlg('Could not find Sources\Install.wim and Sources\Setup.exe.  Try again?', mtError, mbOkCancel, 0) of
      mrYes: Continue;
      else
        begin
          Found := true;
        end;
      end;
    end;
  end;
  if Found then Halt;
end;



end.

