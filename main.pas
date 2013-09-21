unit Main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls;

type

  { TForm1 }

  TForm1 = class(TForm)
    Image1: TImage;
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  Form1: TForm1;
  AppDrv : Char;
  SourcePath : String;
  WinPE : boolean=false;

implementation
uses
  Windows,
  DriveSelect;

{$R *.lfm}

{ TForm1 }
function ExpandEnvVars(const Str: string): string;
var
  BufSize: Integer; // size of expanded string
begin
  // Get required buffer size
  BufSize := ExpandEnvironmentStrings(
    PChar(Str), nil, 0);
  if BufSize > 0 then
  begin
    // Read expanded string into result string
    SetLength(Result, BufSize - 1);
    ExpandEnvironmentStrings(PChar(Str),
      PChar(Result), BufSize);
  end
  else
    // Trying to expand empty string
    Result := '';
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  Timer1.Enabled:=false;
  if SourcePath = '' then
    ShowMessage('Sources\Install.wim or Install.wim not found.  Exiting')
  else SetupFrm.ShowModal;
  Form1.Close;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  AppPath : String;
begin
  AppDrv := ExtractFileDrive(ParamStr(0))[1];
  AppPath :=ExtractFilePath(ParamStr(0)); //Has Trailing slash

  SourcePath := '';
  if FileExistsUTF8(AppPath + 'Sources\Install.wim') then
    SourcePath := AppPath + 'Sources\';
  if FileExistsUTF8(AppPath + 'Install.wim') then
    SourcePath := AppPath;


  if FileExistsUTF8(ExpandEnvVars('%SystemRoot%\system32\wpeutil.exe')) then
  begin
    //Self.WindowState := wsMaximized;
    Left := 0;
    Top := 0;
    WinPE := true;
  end
  else
  begin
    BorderStyle := bsSingle;//ToolWindow;
    ClientWidth := 800;
    ClientHeight := 600;
    Left:=(Screen.Width-Width)  div 2;
    Top:=(Screen.Height-Height) div 2;
    WinPE := false;
  end;

end;


end.

