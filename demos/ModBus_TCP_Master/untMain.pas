unit untMain;

{$MODE objfpc}

interface

uses
  LCLIntf, LCLType, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  IdComponent, Grids, ExtCtrls, StdCtrls, Buttons, Menus, Spin,
  ModbusTypes, IdModBusClient, IPEdit, IniFiles;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    cbLogEnabled: TCheckBox;
    cbZeroBased: TCheckBox;
    IPEdit1: TIPEdit;
    Label5: TLabel;
    Label6: TLabel;
    mclPLC: TIdModBusClient;
    Label3: TLabel;
    Label4: TLabel;
    MainMenu1: TMainMenu;
    mniClearList: TMenuItem;
    Separator1: TMenuItem;
    mniDeleteRow: TMenuItem;
    mniAddRow: TMenuItem;
    mnuQuit: TMenuItem;
    mnuLine: TMenuItem;
    mnuSave: TMenuItem;
    mnuOpen: TMenuItem;
    mnuFile: TMenuItem;
    OpenDialog1: TOpenDialog;
    pnlInput: TPanel;
    btnStart: TBitBtn;
    pnlMain: TPanel;
    PopupMenu1: TPopupMenu;
    SaveDialog1: TSaveDialog;
    seCycle: TSpinEdit;
    sgdRegisters: TStringGrid;
    mmoErrorLog: TMemo;
    sePort: TSpinEdit;
    seUnitID: TSpinEdit;
    Splitter1: TSplitter;
    tmCycle: TTimer;
    procedure cbLogEnabledChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure mclPLCConnected(Sender: TObject);
    procedure mclPLCDisconnected(Sender: TObject);
    procedure mclPLCResponseError(const FunctionCode: byte;
      const ErrorCode: byte; const ResponseBuffer: TModBusResponseBuffer);
    procedure mclPLCResponseMismatch(const RequestFunctionCode: byte;
      const ResponseFunctionCode: byte; const ResponseBuffer: TModBusResponseBuffer);
    procedure mclPLCStatus(ASender: TObject; const AStatus: TIdStatus;
      const AStatusText: string);
    procedure mniAddRowClick(Sender: TObject);
    procedure mniClearListClick(Sender: TObject);
    procedure mniDeleteRowClick(Sender: TObject);
    procedure mnuOpenClick(Sender: TObject);
    procedure mnuQuitClick(Sender: TObject);
    procedure mnuSaveClick(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure tmCycleTimer(Sender: TObject);
  private
    LogEnabled: boolean;
    Connected: boolean;
    procedure ClearRegisters;
    function Sanitize: boolean;
    function TranslateEC(EC: byte): string;
    procedure Log(s: string);
  public
    { Public declarations }
  end;

const
  IdStati: array[TIdStatus] of string = (
    'Resolving hostname',
    'Connecting',
    'Connected.',
    'Disconnecting.',
    'Disconnected.',
    '%s',
    '%s',
    '%s',
    '%s');

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

procedure TfrmMain.btnStartClick(Sender: TObject);
begin
  if tmCycle.Enabled then
  begin
    tmCycle.Enabled := False;
    btnStart.Caption := 'Start';
    mclPLC.Disconnect(True);
  end
  else
  begin
    ClearRegisters;
    if Sanitize then
    begin
      mclPLC.Port := sePort.Value;
      mclPLC.UnitID := seUnitID.Value;
      mclPLC.Host := IPEdit1.Text;
      if cbZeroBased.Checked then
        mclPLC.BaseRegister := 0
      else
        mclPLC.BaseRegister := 1;
      btnStart.Caption := 'Stop';
      LogEnabled := cbLogEnabled.Checked;
      mmoErrorLog.Visible := LogEnabled;
      Log('Host: ' + mclPLC.Host + ';  Port: ' + IntToStr(mclPLC.Port) +
        ';  UnitID: ' + IntToStr(mclPLC.UnitID));
      tmCycle.Interval := seCycle.Value * 1000;
      tmCycle.Enabled := True;
      mclPLC.Connect;
    end;
  end;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  LogEnabled := False;
  Connected := False;
  sePort.Value := mclPLC.Port;
  seUnitID.Value := mclPLC.UnitID;
  if mclPLC.BaseRegister = 0 then
    cbZeroBased.Checked := True
  else
    cbZeroBased.Checked := False;
  mclPLC.Host := IPEdit1.TextTrimmed;
  tmCycle.Interval := seCycle.Value;
end;

procedure TfrmMain.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  if tmCycle.Enabled then
    btnStartClick(Sender);
end;

procedure TfrmMain.mclPLCConnected(Sender: TObject);
begin
  Connected := True;
end;

procedure TfrmMain.mclPLCDisconnected(Sender: TObject);
begin
  Connected := False;
end;

procedure TfrmMain.mclPLCResponseError(const FunctionCode: byte;
  const ErrorCode: byte; const ResponseBuffer: TModBusResponseBuffer);
begin
  Log('Error: Function: ' + IntToStr(FunctionCode) + ' - ' + TranslateEC(ErrorCode));
end;

procedure TfrmMain.mclPLCResponseMismatch(const RequestFunctionCode: byte;
  const ResponseFunctionCode: byte; const ResponseBuffer: TModBusResponseBuffer);
begin
  Log('Mismatch: Request: ' + IntToStr(RequestFunctionCode) +
    ' ; Response: ' + IntToStr(ResponseFunctionCode));
end;

procedure TfrmMain.mclPLCStatus(ASender: TObject; const AStatus: TIdStatus;
  const AStatusText: string);
begin
  Log('Status: ' + IdStati[AStatus]);
end;

procedure TfrmMain.mniAddRowClick(Sender: TObject);
var
  ControlCoord: TPoint;
  r: integer;
begin
  ControlCoord := sgdRegisters.ScreenToControl(PopupMenu1.PopupPoint);
  r := sgdRegisters.MouseToCell(ControlCoord).Y;
  sgdRegisters.InsertColRow(False, r);
end;

procedure TfrmMain.mniClearListClick(Sender: TObject);
begin
  sgdRegisters.RowCount := 1;
end;

procedure TfrmMain.mniDeleteRowClick(Sender: TObject);
var
  ControlCoord: TPoint;
  r: integer;
begin
  ControlCoord := sgdRegisters.ScreenToControl(PopupMenu1.PopupPoint);
  r := sgdRegisters.MouseToCell(ControlCoord).Y;
  if (r < sgdRegisters.RowCount) and (r > 0) then
    sgdRegisters.DeleteColRow(False, r);
end;


procedure TfrmMain.cbLogEnabledChange(Sender: TObject);
begin
  LogEnabled := cbLogEnabled.Checked;
  mmoErrorLog.Visible := LogEnabled;
end;

procedure TfrmMain.mnuOpenClick(Sender: TObject);
var
  ini: TIniFile;
begin
  sgdRegisters.SaveOptions := soAll;
  if OpenDialog1.Execute then
  begin
    sgdRegisters.LoadFromFile(OpenDialog1.FileName);
    if FileExists(OpenDialog1.FileName + '.set') then
    begin
      ini := TIniFile.Create(OpenDialog1.FileName + '.set');
      IPEdit1.Text := ini.ReadString('Set', 'IP', '192.168.001.100');
      sePort.Value := ini.ReadInteger('Set', 'Port', 502);
      seUnitID.Value := ini.ReadInteger('Set', 'UnitID', 1);
      seCycle.Value := ini.ReadInteger('Set', 'Cycle', 10);
      cbZeroBased.Checked := ini.ReadBool('Set', 'ZeroBased', True);
      ini.Free;
    end;
  end;
end;

procedure TfrmMain.mnuQuitClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmMain.mnuSaveClick(Sender: TObject);
var
  ini: TIniFile;
begin
  if Sanitize then
  begin
    sgdRegisters.SaveOptions := soAll;
    if SaveDialog1.Execute then
    begin
      sgdRegisters.SaveToFile(SaveDialog1.FileName);
      ini := TIniFile.Create(SaveDialog1.FileName + '.set');
      ini.WriteString('Set', 'IP', IPEdit1.Text);
      ini.WriteInteger('Set', 'Port', sePort.Value);
      ini.WriteInteger('Set', 'UnitID', seUnitID.Value);
      ini.WriteInteger('Set', 'Cycle', seCycle.Value);
      ini.WriteBool('Set', 'ZeroBased', cbZeroBased.Checked);
      ini.Free;
    end;
  end;
end;

procedure TfrmMain.ClearRegisters;
var
  i: integer;
begin
  for i := 1 to (sgdRegisters.RowCount - 1) do
  begin
    sgdRegisters.Cells[3, i] := '';
  end;
end;

function TfrmMain.Sanitize: boolean;
var
  i: integer;
  valueBool: boolean;
  valueWord: integer;
  FC: integer;
begin
  Result := True;
  for i := 1 to sgdRegisters.RowCount - 1 do
  begin
    sgdRegisters.Cells[0, i] := trim(sgdRegisters.Cells[0, i]);
    if not TryStrToInt(sgdRegisters.Cells[0, i], valueWord) then
    begin
      Result := False;
      ShowMessage('Illegal input data');
      sgdRegisters.SetFocus;
      sgdRegisters.Col := 0;
      sgdRegisters.Row := i;
      sgdRegisters.EditorMode := True;
      Break;
    end;
    if TryStrToInt(copy(sgdRegisters.Cells[1, i], 0, 2), FC) then
    begin
      sgdRegisters.Cells[2, i] := trim(sgdRegisters.Cells[2, i]);
      if sgdRegisters.Cells[2, i] <> '' then
      begin
        if FC = 5 then
          if not TryStrToBool(sgdRegisters.Cells[2, i], valueBool) then
          begin
            Result := False;
            ShowMessage('Illegal input data');
            sgdRegisters.SetFocus;
            sgdRegisters.Col := 2;
            sgdRegisters.Row := i;
            sgdRegisters.EditorMode := True;
            Break;
          end;
        if FC = 6 then
          if not TryStrToInt(sgdRegisters.Cells[2, i], valueWord) then
          begin
            Result := False;
            ShowMessage('Illegal input data');
            sgdRegisters.SetFocus;
            sgdRegisters.Col := 2;
            sgdRegisters.Row := i;
            sgdRegisters.EditorMode := True;
            Break;
          end;
      end;
    end;
    if not Result then
    begin
      Break;
    end;
  end;
end;

procedure TfrmMain.tmCycleTimer(Sender: TObject);
var
  i: integer;
  RegNo: integer;
  FC: integer;
  ValueW: word;
  ValueB: boolean;
  ValueBA: array of boolean;
  EC: boolean;
begin
  if Connected then
  begin
    Log('Polling...');
    SetLength(ValueBA, 1);
    EC := False;
    for i := 1 to sgdRegisters.RowCount - 1 do
    begin
      if TryStrToInt(sgdRegisters.Cells[0, i], RegNo) then
      begin
        FC := StrToInt(copy(sgdRegisters.Cells[1, i], 0, 2));
        case FC of
          1: begin
            EC := mclPLC.ReadCoil(RegNo, ValueB);
            if EC then sgdRegisters.Cells[2, i] := BoolToStr(ValueB);
          end;
          2: begin
            EC := mclPLC.ReadInputBits(RegNo, 1, ValueBA);
            if EC then sgdRegisters.Cells[2, i] := BoolToStr(ValueBA[0]);
          end;
          3: begin
            EC := mclPLC.ReadHoldingRegister(RegNo, ValueW);
            if EC then sgdRegisters.Cells[2, i] := IntToStr(ValueW);
          end;
          4: begin
            EC := mclPLC.ReadInputRegister(RegNo, ValueW);
            if EC then sgdRegisters.Cells[2, i] := IntToStr(ValueW);
          end;
          5: begin
            EC := mclPLC.WriteCoil(RegNo, StrToBool(sgdRegisters.Cells[2, i]));
          end;
          6: begin
            EC := mclPLC.WriteRegister(RegNo, StrToInt(sgdRegisters.Cells[2, i]));
          end;
        end;
        if EC then sgdRegisters.Cells[3, i] := 'OK'
        else
          sgdRegisters.Cells[3, i] := 'FAIL';
      end;
    end;
  end
  else
    Log('Polling: Not connected');
end;

function TfrmMain.TranslateEC(EC: byte): string;
begin
  case EC of
    0: Result := 'OK';
    1: Result := 'Illegal function';
    2: Result := 'Illegal register';
    3: Result := 'Illegal value';
    4: Result := 'Server failure';
    5: Result := 'Acknowledge';
    6: Result := 'Server busy';
    10: Result := 'Gateway path not available';
    11: Result := 'Gateway no response from target';
    else
      Result := 'Unknown';
  end;

end;

procedure TfrmMain.Log(s: string);
begin
  if LogEnabled then
    mmoErrorLog.Lines.Add(TimeToStr(Now) + ':    ' + s);
end;

end.
