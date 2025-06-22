unit untMain;

{$MODE objfpc}

interface

uses
  LCLIntf, LCLType, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  IdComponent, IdModbusServer, Grids, ExtCtrls, StdCtrls, Buttons, Menus, Spin,
  IdContext, ModbusTypes, ModbusConsts, IniFiles;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    cbLearn: TCheckBox;
    cbLogEnabled: TCheckBox;
    cbZeroBased: TCheckBox;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    MainMenu1: TMainMenu;
    mniAddRow: TMenuItem;
    mniClearList: TMenuItem;
    Separator1: TMenuItem;
    mniDeleteRow: TMenuItem;
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
    seMinReg: TSpinEdit;
    seMaxReg: TSpinEdit;
    sgdRegisters: TStringGrid;
    mmoErrorLog: TMemo;
    sePort: TSpinEdit;
    seUnitID: TSpinEdit;
    Splitter1: TSplitter;
    msrPLC: TIdModBusServer;
    procedure cbLogEnabledChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure mniAddRowClick(Sender: TObject);
    procedure mniClearListClick(Sender: TObject);
    procedure mniDeleteRowClick(Sender: TObject);
    procedure mnuOpenClick(Sender: TObject);
    procedure mnuQuitClick(Sender: TObject);
    procedure mnuSaveClick(Sender: TObject);
    procedure msrPLCConnect(AContext: TIdContext);
    procedure msrPLCDisconnect(AContext: TIdContext);
    procedure msrPLCError(const Sender: TIdContext; const FunctionCode: byte;
      const ErrorCode: byte; const RequestBuffer: TModBusRequestBuffer);
    procedure msrPLCException(AContext: TIdContext; AException: Exception);
    procedure msrPLCReadCoils(const Sender: TIdContext; const RegNr, Count: integer;
      var Data: TModCoilData; const RequestBuffer: TModBusRequestBuffer;
      var ErrorCode: byte);
    procedure msrPLCReadHoldingRegisters(const Sender: TIdContext;
      const RegNr, Count: integer; var Data: TModRegisterData;
      const RequestBuffer: TModBusRequestBuffer; var ErrorCode: byte);
    procedure msrPLCReadInputBits(const Sender: TIdContext;
      const RegNr, Count: integer; var Data: TModCoilData;
      const RequestBuffer: TModBusRequestBuffer; var ErrorCode: byte);
    procedure msrPLCReadInputRegisters(const Sender: TIdContext;
      const RegNr, Count: integer; var Data: TModRegisterData;
      const RequestBuffer: TModBusRequestBuffer; var ErrorCode: byte);
    procedure msrPLCStatus(ASender: TObject; const AStatus: TIdStatus;
      const AStatusText: string);
    procedure msrPLCWriteCoils(const Sender: TIdContext;
      const RegNr, Count: integer; const Data: TModCoilData;
      const RequestBuffer: TModBusRequestBuffer; var ErrorCode: byte);
    procedure msrPLCWriteRegisters(const Sender: TIdContext;
      const RegNr, Count: integer; const Data: TModRegisterData;
      const RequestBuffer: TModBusRequestBuffer; var ErrorCode: byte);
    procedure btnStartClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    LogEnabled: boolean;
    procedure ClearRegisters;
    function SetHoldingRegValue(const RegNo: integer; const Value: word): byte;
    function SetCoilValue(const RegNo: integer; const Value: bytebool): byte;
    function GetCoilValue(const RegNo: integer; var Value: bytebool): byte;
    function GetDiscrInputValue(const RegNo: integer; var Value: bytebool): byte;
    function GetHoldingRegValue(const RegNo: integer; var Value: word): byte;
    function GetInputRegValue(const RegNo: integer; var Value: word): byte;
    procedure Learn(RegNo, Col, ValueWord: integer; ValueBool: bytebool);
    function Sanitize: boolean;
    procedure Log(s: string);
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

procedure TfrmMain.msrPLCConnect(AContext: TIdContext);
begin
  Log('Connected');
end;

procedure TfrmMain.msrPLCDisconnect(AContext: TIdContext);
begin
  Log('Disconnected');
end;

procedure TfrmMain.msrPLCError(const Sender: TIdContext; const FunctionCode: byte;
  const ErrorCode: byte; const RequestBuffer: TModBusRequestBuffer);
begin
  Log('Error. Function: ' + IntToStr(FunctionCode) + ' ; Code: ' + IntToStr(ErrorCode));
end;

procedure TfrmMain.msrPLCException(AContext: TIdContext; AException: Exception);
begin
  Log('Exception ' + AException.Message);
end;

procedure TfrmMain.msrPLCReadCoils(const Sender: TIdContext;
  const RegNr, Count: integer; var Data: TModCoilData;
  const RequestBuffer: TModBusRequestBuffer; var ErrorCode: byte);
var
  i: integer;
begin
  Log('===================================================');
  Log(IntToStr(RegNr) + ' ReadCoil[' + IntToStr(Count) + ']');
  for i := 0 to (Count - 1) do
  begin
    ErrorCode := GetCoilValue(RegNr + i, Data[i]);
    Log('     Value[' + IntToStr(i) + '] = ' + BoolToStr(Data[i]) +
      ';  EC: ' + IntToStr(ErrorCode));
  end;
end;

procedure TfrmMain.msrPLCReadHoldingRegisters(const Sender: TIdContext;
  const RegNr, Count: integer; var Data: TModRegisterData;
  const RequestBuffer: TModBusRequestBuffer; var ErrorCode: byte);
var
  i: integer;
begin
  Log('===================================================');
  Log(IntToStr(RegNr) + ' ReadHoldingRegister[' + IntToStr(Count) + ']');
  for i := 0 to (Count - 1) do
  begin
    ErrorCode := GetHoldingRegValue(RegNr + i, Data[i]);
    Log('     Value[' + IntToStr(i) + '] = ' + IntToStr(Data[i]) +
      ';  EC: ' + IntToStr(ErrorCode));
  end;
end;

procedure TfrmMain.msrPLCReadInputBits(const Sender: TIdContext;
  const RegNr, Count: integer; var Data: TModCoilData;
  const RequestBuffer: TModBusRequestBuffer; var ErrorCode: byte);
var
  i: integer;
begin
  Log('===================================================');
  Log(IntToStr(RegNr) + ' ReadDiscreteInputs[' + IntToStr(Count) + ']');
  for i := 0 to (Count - 1) do
  begin
    ErrorCode := GetDiscrInputValue(RegNr + i, Data[i]);
    Log('     Value[' + IntToStr(i) + '] = ' + BoolToStr(Data[i]) +
      ';  EC: ' + IntToStr(ErrorCode));
  end;
end;

procedure TfrmMain.msrPLCReadInputRegisters(const Sender: TIdContext;
  const RegNr, Count: integer; var Data: TModRegisterData;
  const RequestBuffer: TModBusRequestBuffer; var ErrorCode: byte);
var
  i: integer;
begin
  Log('===================================================');
  Log(IntToStr(RegNr) + ' ReadInputRegister[' + IntToStr(Count) + ']');
  for i := 0 to (Count - 1) do
  begin
    ErrorCode := GetInputRegValue(RegNr + i, Data[i]);
    Log('     Value[' + IntToStr(i) + '] = ' + IntToStr(Data[i]) +
      ';  EC: ' + IntToStr(ErrorCode));
  end;
end;

procedure TfrmMain.msrPLCStatus(ASender: TObject; const AStatus: TIdStatus;
  const AStatusText: string);
begin
  Log('Status: ' + AStatusText);
end;

procedure TfrmMain.msrPLCWriteCoils(const Sender: TIdContext;
  const RegNr, Count: integer; const Data: TModCoilData;
  const RequestBuffer: TModBusRequestBuffer; var ErrorCode: byte);
var
  i: integer;
begin
  Log('===================================================');
  Log(IntToStr(RegNr) + ' WriteCoil[' + IntToStr(Count) + ']');
  for i := 0 to (Count - 1) do
  begin
    ErrorCode := SetCoilValue(RegNr + i, Data[i]);
    Log('     Value[' + IntToStr(i) + '] = ' + BoolToStr(Data[i]) +
      ';  EC: ' + IntToStr(ErrorCode));
  end;
end;

procedure TfrmMain.msrPLCWriteRegisters(const Sender: TIdContext;
  const RegNr, Count: integer; const Data: TModRegisterData;
  const RequestBuffer: TModBusRequestBuffer; var ErrorCode: byte);
var
  i: integer;
begin
  Log('===================================================');
  Log(IntToStr(RegNr) + ' WriteHoldingRegister[' + IntToStr(Count) + ']');
  for i := 0 to (Count - 1) do
  begin
    ErrorCode := SetHoldingRegValue(RegNr + i, Data[i]);
    Log('     Value[' + IntToStr(i) + '] = ' + IntToStr(Data[i]) +
      ';  EC: ' + IntToStr(ErrorCode));
  end;
end;

procedure TfrmMain.btnStartClick(Sender: TObject);
begin
  if msrPLC.Active then
  begin
    msrPLC.Active := False;
    btnStart.Caption := 'Start listening';
  end
  else
  begin
    ClearRegisters;
    if Sanitize then
    begin
      msrPLC.DefaultPort := sePort.Value;
      msrPLC.UnitID := seUnitID.Value;
      if cbZeroBased.Checked then
        msrPLC.BaseRegister := 0
      else
        msrPLC.BaseRegister := 1;
      msrPLC.MinRegister := seMinReg.Value;
      msrPLC.MaxRegister := seMaxReg.Value;
      btnStart.Caption := 'Stop';
      msrPLC.Active := True;
    end;
  end;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  LogEnabled := True;
  cbLogEnabled.Checked := True;
  cbZeroBased.Checked := True;
end;

procedure TfrmMain.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  msrPLC.Pause := True;
  if msrPLC.Active then
    btnStartClick(Sender);
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
      sePort.Value := ini.ReadInteger('Set', 'Port', 502);
      seUnitID.Value := ini.ReadInteger('Set', 'UnitID', 1);
      seMinReg.Value := ini.ReadInteger('Set', 'MinRegister', 0);
      seMaxReg.Value := ini.ReadInteger('Set', 'MaxRegister', 65535);
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
      ini.WriteInteger('Set', 'Port', sePort.Value);
      ini.WriteInteger('Set', 'UnitID', seUnitID.Value);
      ini.WriteInteger('Set', 'MinRegister', seMinReg.Value);
      ini.WriteInteger('Set', 'MaxRegister', seMaxReg.Value);
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
    sgdRegisters.Cells[5, i] := '';
    sgdRegisters.Cells[6, i] := '';
  end;
end;

function TfrmMain.GetCoilValue(const RegNo: integer; var Value: bytebool): byte;
var
  i: integer;
begin
  Result := mbeIllegalRegister;

  for i := 1 to sgdRegisters.RowCount - 1 do
  begin
    if StrToIntDef(sgdRegisters.Cells[0, i], -1) = RegNo then
    begin
      if TryStrToBool(Trim(sgdRegisters.Cells[1, i]), boolean(Value)) then
        Result := mbeOk
      else
      begin
        Log('Illegal Value in Register ' + IntToStr(RegNo));
        Result := mbeIllegalDataValue;
      end;
    end;
  end;
  if (Result <> mbeOK) and cbLearn.Checked then
  begin
    Learn(RegNo, 1, 0, False);
    Result := mbeOK;
  end;
end;

function TfrmMain.GetDiscrInputValue(const RegNo: integer; var Value: bytebool): byte;
var
  i: integer;
begin
  Result := mbeIllegalRegister;

  for i := 1 to sgdRegisters.RowCount - 1 do
  begin
    if StrToIntDef(sgdRegisters.Cells[0, i], -1) = RegNo then
    begin
      if TryStrToBool(Trim(sgdRegisters.Cells[2, i]), boolean(Value)) then
        Result := mbeOk
      else
      begin
        Log('Illegal Value in Register ' + IntToStr(RegNo));
        Result := mbeIllegalDataValue;
      end;
    end;
  end;
  if (Result <> mbeOK) and cbLearn.Checked then
  begin
    Learn(RegNo, 2, 0, False);
    Result := mbeOK;
  end;
end;

function TfrmMain.GetHoldingRegValue(const RegNo: integer; var Value: word): byte;
var
  i: integer;
  v: integer;
begin
  Result := mbeIllegalRegister;

  for i := 1 to sgdRegisters.RowCount - 1 do
  begin
    if StrToIntDef(sgdRegisters.Cells[0, i], -1) = RegNo then
    begin
      if TryStrToInt(Trim(sgdRegisters.Cells[3, i]), v) then
      begin
        Value := Lo(v);
        Result := mbeOk;
      end
      else
      begin
        Log('Illegal Value in Register ' + IntToStr(RegNo));
        Result := mbeIllegalDataValue;
      end;
    end;
  end;
  if (Result <> mbeOK) and cbLearn.Checked then
  begin
    Learn(RegNo, 3, -1, False);
    Result := mbeOK;
  end;
end;

function TfrmMain.GetInputRegValue(const RegNo: integer; var Value: word): byte;
var
  i: integer;
  v: integer;
begin
  Result := mbeIllegalRegister;

  for i := 1 to sgdRegisters.RowCount - 1 do
  begin
    if StrToIntDef(sgdRegisters.Cells[0, i], -1) = RegNo then
    begin
      if TryStrToInt(Trim(sgdRegisters.Cells[4, i]), v) then
      begin
        Value := Lo(v);
        Result := mbeOk;
      end
      else
      begin
        Log('Illegal Value in Register ' + IntToStr(RegNo));
        Result := mbeIllegalDataValue;
      end;
    end;
  end;
  if (Result <> mbeOK) and cbLearn.Checked then
  begin
    Learn(RegNo, 4, -1, False);
    Result := mbeOK;
  end;
end;

function TfrmMain.SetHoldingRegValue(const RegNo: integer; const Value: word): byte;
var
  i: integer;
  found: boolean;
begin
  found := False;
  Result := mbeIllegalRegister;
  for i := 1 to sgdRegisters.RowCount - 1 do
  begin
    if StrToIntDef(sgdRegisters.Cells[0, i], -1) = RegNo then
    begin
      sgdRegisters.Cells[6, i] := IntToStr(Value);
      found := True;
      Result := mbeOK;
    end;
  end;
  if not found and cbLearn.Checked then
  begin
    Learn(RegNo, 6, Value, False);
    Result := mbeOK;
  end;
end;

function TfrmMain.SetCoilValue(const RegNo: integer; const Value: bytebool): byte;
var
  i: integer;
  found: boolean;
begin
  found := False;
  Result := mbeIllegalRegister;
  for i := 1 to sgdRegisters.RowCount - 1 do
  begin
    if StrToIntDef(sgdRegisters.Cells[0, i], -1) = RegNo then
    begin
      sgdRegisters.Cells[5, i] := UpperCase(BoolToStr(Value, True));
      found := True;
      Result := mbeOK;
    end;
  end;
  if not found and cbLearn.Checked then
  begin
    Learn(RegNo, 5, 0, Value);
    Result := mbeOK;
  end;
end;

procedure TfrmMain.Learn(RegNo, Col, ValueWord: integer; ValueBool: bytebool);
var
  i, j: integer;
  found: boolean;
begin
  found := False;
  if RegNo = 0 then Log('Zero incomming');
  for j := 1 to sgdRegisters.RowCount - 1 do
  begin
    if sgdRegisters.Cells[0, j] = IntToStr(RegNo) then
    begin
      found := True;
      if Col in [1, 2, 5] then
        sgdRegisters.Cells[Col, j] := BoolToStr(ValueBool, True);
      if Col in [3, 4, 6] then
        sgdRegisters.Cells[Col, j] := IntToStr(ValueWord);
    end;
  end;
  if not found then
  begin
    i := sgdRegisters.RowCount;
    sgdRegisters.InsertColRow(False, i);
    if RegNo = 0 then Log('Zero in not found');
    sgdRegisters.Cells[0, i] := IntToStr(RegNo);
    if Col in [1, 2, 5] then
      sgdRegisters.Cells[Col, i] := BoolToStr(ValueBool, True);
    if Col in [3, 4, 6] then
      sgdRegisters.Cells[Col, i] := IntToStr(ValueWord);
  end;
end;

function TfrmMain.Sanitize: boolean;
var
  i, j: integer;
  valueBool: boolean;
  valueWord: integer;
begin
  Result := True;
  for i := 1 to sgdRegisters.RowCount - 1 do
  begin
    for j := 0 to sgdRegisters.ColCount - 1 do
    begin
      sgdRegisters.Cells[j, i] := UpperCase(Trim(sgdRegisters.Cells[j, i]));
      if sgdRegisters.Cells[j, i] <> '' then
      begin
        if j in [1, 2, 5] then
          if not TryStrToBool(sgdRegisters.Cells[j, i], valueBool) then
          begin
            Result := False;
            ShowMessage('Illegal input data');
            sgdRegisters.SetFocus;
            sgdRegisters.Col := j;
            sgdRegisters.Row := i;
            sgdRegisters.EditorMode := True;
            Break;
          end;
        if j in [0, 3, 4, 6] then
          if not TryStrToInt(sgdRegisters.Cells[j, i], valueWord) then
          begin
            Result := False;
            ShowMessage('Illegal input data');
            sgdRegisters.SetFocus;
            sgdRegisters.Col := j;
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

procedure TfrmMain.Log(s: string);
begin
  if LogEnabled then
    mmoErrorLog.Lines.Add(TimeToStr(Now) + ':    ' + s);
end;

end.
