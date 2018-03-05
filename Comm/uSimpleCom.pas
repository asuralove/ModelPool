unit uSimpleCom;

interface
uses
  Windows, SysUtils, Classes;
type
  BString = string; //OK ����ɹ� ����Ϊ����ԭ��
  DString = AnsiString; //�ڴ�Bin
  TComParam = record
    ComPort: string;
    BaudRate: DWORD;
    ByteSize: Byte;
    StopBits: Byte;
    Parity: Byte;
  end;

  TSimpleCOM = class
  private
    FComHandle: THandle;
    FComParam: TComParam;
    FLog: TStrings;
    FLogMaxCount: Integer;
    FHasLog: Boolean;
    procedure WriteLog(const s: string);
    procedure WriteHexLog(const Data: DString);
  public
    constructor Create; overload;
    constructor Create(ComPort: string; BaudRate: DWORD; ByteSize: Byte; StopBits: Byte; Parity: Byte); overload;
    destructor Destroy; override;
    property ComParam: TComParam read FComParam;
    property ComHandle: THandle read FComHandle;
    property HasLog: Boolean read FHasLog write fHasLog;
    property Log: TStrings read FLog;
    property LogMaxCount: Integer read FLogMaxCount write FLogMaxCount;
    function CloseCom: BString;
    function OpenCom: BString;
    function ReadData: string;
    function WriteData(num: integer; var buf): integer;
    function WriteStrData(const s: DString): BString;
  end;

implementation

uses
  uData;

constructor TSimpleCOM.Create;
begin
  inherited Create;
  FComHandle := INVALID_HANDLE_VALUE;
  FComParam.BaudRate := 19200;
  FComParam.ByteSize := 8;
  FComParam.StopBits := 0;    //0 1λ 1 1.5λ 2 2λ
  FComParam.Parity := 0;
  FComParam.ComPort := 'COM1'; //COM1
  HasLog := False;
  FLogMaxCount := 1000;
  FLog := nil;
end;

constructor TSimpleCOM.Create(ComPort: string; BaudRate: DWORD; ByteSize, StopBits, Parity: Byte);
begin
  Create;
  FComParam.BaudRate := BaudRate;
  FComParam.ByteSize := ByteSize;
  FComParam.StopBits := StopBits;
  FComParam.Parity := Parity;
  FComParam.ComPort := ComPort;
end;

destructor TSimpleCOM.Destroy;
begin
  CloseCom;
  if FLog <> nil then FreeAndNil(FLog);
  inherited;
end;

procedure TSimpleCOM.WriteHexLog(const Data: DString);
var
  i: Integer;
  s1, s2: string;
begin
  if FLog = nil then FLog := TStringList.Create;
  s1 := ''; s2 := '';
  for I := 1 to Length(Data) do begin
    s1 := s1 + IntToHex(Byte(Data[i]), 2) + ' ';
    if (Byte(Data[i]) >= 32) and (Byte(Data[i]) <= 127) then
      s2 := s2 + Data[i]
    else
      s2 := s2 + '.';
    if i mod 16 = 0 then begin
      FLog.Add(s1 + '; ' + s2);
      s1 := ''; s2 := '';
    end;
  end;
  if s1 <> '' then FLog.Add(s1 + '; ' + s2);
  while FLog.Count > FLogMaxCount do FLog.Delete(0);
end;

procedure TSimpleCOM.WriteLog(const s: string);
begin
  if FLog = nil then FLog := TStringList.Create;
  FLog.Add(TimeToStr(Time) + '  ' + s);
  while FLog.Count > FLogMaxCount do FLog.Delete(0);
end;

function TSimpleCOM.OpenCom: BString;
var
  commDCB: DCB;
  commTMO: TCOMMTIMEOUTS;
begin
  try
    try
      if FComHandle <> INVALID_HANDLE_VALUE then begin
        Result := 'ͨѶ�˿��Ѿ�����';
        Exit;
      end;

      FComHandle := CreateFile(pchar('\\.\' + FComParam.ComPort), GENERIC_READ or GENERIC_WRITE, 0, nil, OPEN_EXISTING, 0, 0);;

      if FComHandle = INVALID_HANDLE_VALUE then begin
        Result := '��ERROR,ErrorNum=' + IntToStr(GetLastError);
        Exit;
      end;

      if not GetCommState(FComHandle, CommDCB) then begin // can't get port state
        Result := 'GetState����';
        CloseHandle(FComHandle);
        FComHandle := INVALID_HANDLE_VALUE;
        exit;
      end;

  //���ò�����
      commDCB.BaudRate := FComParam.BaudRate; // setup port device control block
      commDCB.ByteSize := FComParam.ByteSize;
      commDCB.StopBits := FComParam.StopBits;
      commDCB.Parity := FComParam.Parity;
      commDCB.Flags := $1013;
      commDCB.XonLim := 500;
      commDCB.XoffLim := 500;
      commDCB.XonChar := chr($11);
      commDCB.XoffChar := chr($13);;
      commDCB.ErrorChar := chr(0);

      if not SetCommState(FComHandle, commDCB) then begin // can't set port state
        Result := 'SetState����';
        CloseHandle(FComHandle);
        FComHandle := INVALID_HANDLE_VALUE;
        Exit;
      end;

      if not GetCommTimeOuts(FComHandle, commTMO) then begin // can't get port time outs
        Result := 'GetCommTimeOuts����';
        CloseHandle(FComHandle);
        FComHandle := INVALID_HANDLE_VALUE;
        exit;
      end;
  //���ó�ʱ
      commTMO.ReadIntervalTimeOut := MAXDWORD;
      commTMO.ReadTotalTimeOutMultiplier := 0;
      commTMO.ReadTotalTimeOutConstant := 0;
      if not SetCommTimeOuts(FComHandle, commTMO) then begin
        Result := '���ó�ʱ����';
        CloseHandle(FComHandle);
        FComHandle := INVALID_HANDLE_VALUE;
        Exit;
      end;
      PurgeComm(FComHandle, PURGE_TXABORT + PURGE_RXABORT + PURGE_TXCLEAR + PURGE_RXCLEAR);
      Result := 'OK';
    finally
      if HasLog then WriteLog('�򿪴��� ���:' + Result);
    end;
  except on E: Exception do
    begin
      Result := Format('Error: %s', [E.Message]);
    end;
  end;
end;

function TSimpleCOM.CloseCom: BString;
begin
  if FComHandle <> INVALID_HANDLE_VALUE then begin
    PurgeComm(FComHandle, PURGE_TXABORT + PURGE_RXABORT + PURGE_TXCLEAR + PURGE_RXCLEAR);
    CloseHandle(FComHandle);
    FComHandle := INVALID_HANDLE_VALUE;
    if HasLog then WriteLog('�رմ���');
  end;
  Result := 'OK';
end;

function TSimpleCOM.WriteData(num: integer; var buf): integer;
var
  eCode: DWORD;
  cStat: COMSTAT;
  sData: AnsiString;
  i: Integer;
  p: PByte;
begin
  if HasLog then begin
    WriteLog('Ҫ���������ֽ���:' + IntToStr(num));
    SetLength(sData, num);
    p := @buf;
    for i := 0 to num - 1 do begin
      sData[i + 1] := AnsiChar(p^);
      Inc(p);
    end;
    WriteHexLog(sData);
  end;

  eCode := 0;
  ClearCommError(FComHandle, eCode, @cStat);
  result := 0;
  if not WriteFile(FComHandle, buf, num, dword(result), nil) then begin
    if HasLog then WriteLog('���ͳ���');
  end
  else
    if HasLog then WriteLog('������' + IntToStr(result) + '�ֽ�');
end;

function TSimpleCOM.WriteStrData(const s: DString): bString;
var
  eCode, Len: DWORD;
  cStat: COMSTAT;
begin
  try
    eCode := 0;
    Len := Length(s);
    ClearCommError(FComHandle, eCode, @cStat);
    if not WriteFile(FComHandle, s[1], Len, eCode, nil) then begin
      Result := '���ʹ���';
      Exit;
    end;
    if eCode <> Len then begin
      Result := '�����ֽڲ���';
      Exit;
    end;
    Result := 'OK';
  finally
    if HasLog then begin
      WriteLog('��������');
      WriteHexLog(s);
      WriteLog('���ͽ��:' + Result);
    end;
  end;
end;

function TSimpleCOM.ReadData: string;
var
  eCode: dword;
  cStat: COMSTAT;
  numRead: dword;
  Buf: array[0..2047] of byte;
  i: Integer;
  sRet: AnsiString;
begin
  Result := '';
  eCode := 0;
  ClearCommError(FComHandle, eCode, @cStat);
  numRead := 0;
  if ReadFile(FComHandle, Buf, sizeof(Buf), numRead, nil) then begin
    SetLength(sRet, numRead);
    for i := 1 to numRead do sRet[i] := AnsiChar(Buf[i - 1]);
    if  numRead = 0 then Exit;
    if HasLog then begin
      WriteLog('�յ�����');
      WriteHexLog(sRet);
    end;
  end
  else begin
    //������
  end;
  Result := sRet;
end;

end.

