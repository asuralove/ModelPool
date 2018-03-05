unit uSms;

interface

uses
  Winapi.Windows, System.SysUtils, Generics.Collections, QJson, QWorker,
  uSimpleCom, uData, SPComm, uPduProtocol;

type
  TModelCom = class(TSimpleCom)
  private
    FTargetPhone: string;
    function SendAndWaitPack(ACmd: DString; var ABuf: AnsiString; ATimeOut: DWORD = 3000): string;
    function SendCommand(ACmd: AnsiString; ATimes: Integer = 1): string;
  public
    constructor Create(ComPort, PhoneNum: string; BaudRate: DWORD = 9600);
    function InitCom(): string;
    function Open(): string;
    function Close(): Boolean;
    function SendSms(AMsgContent: string): string;
  end;

var
  GComList: TDictionary<string, TModelCom>;

implementation

{ TModelCom }

constructor TModelCom.Create(ComPort, PhoneNum: string; BaudRate: DWORD = 9600);
begin
  inherited Create(ComPort, BaudRate, 8, 0, 0);
  Self.FTargetPhone := PhoneNum;
end;

function TModelCom.InitCom: string;
var
  sCmd: string;
begin
  Result := Format('��ʼ���˿�[%s-%s]�Ƿ���δ֪����', [GConfig.GroupName, ComParam.ComPort]);
  sCmd := 'AT+CMGF=0'+#13;    //0-PDU  1-TEXT
  Result := SendCommand(AnsiString(sCmd));
end;

function TModelCom.Open: string;
begin
  Result := Format('�򿪶˿�[%s-%s]����δ֪����',[GConfig.GroupName, ComParam.ComPort]);
  Self.CloseCom;
  Result := Self.OpenCom;
  if Result <> 'OK' then
  begin
    Result := Format('�򿪶˿�[%s-%s]ʧ��[%s]', [GConfig.GroupName,Self.ComParam.ComPort, Result]);
    Exit;
  end;
  Result := InitCom();
  if Result <> 'OK' then
  begin
    Result := Format('[%s-%s]��ʼ���˿�ʧ��', [GConfig.GroupName,Self.ComParam.ComPort]);
    Exit;
  end;
end;

function TModelCom.Close: Boolean;
begin
   Self.CloseCom();
   Result := True;
end;

function TModelCom.SendAndWaitPack(ACmd: DString; var ABuf: AnsiString; ATimeOut: DWORD): string;
var
  sRet: string;
  d1, d2: DWORD;
  ��ʱ���� : integer;
  IsFirst : Boolean;
  iDataLen: Integer;
label ��ʱ�ط�;
begin
  ��ʱ���� := 0;
��ʱ�ط�:
  SetLength(ABuf, 0);
  if Length(ACmd) <= 0 then Exit;
  AddLogMsg('��ʼִ������: %s', [ACmd], True);
  Self.WriteStrData(ACmd);
  IsFirst := True;
  d1 := GetTickCount;
  Sleep(500);
  while True do begin
    sRet := Self.ReadData;
    iDataLen := Length(sRet);

    if (not IsFirst) and (iDataLen = 0) then begin
      Break;
    end;

    if IsFirst and (iDataLen > 0) then IsFirst := False;
    if iDataLen > 0 then begin
      ABuf := ABuf + sRet; d1 := GetTickCount;
    end;

    d2 := GetTickCount;
    if (d2 - d1 > ATimeOut) and IsFirst then begin
      if ��ʱ���� < 5 then begin
        Inc(��ʱ����);goto ��ʱ�ط�;
      end;
      Result := '��ʱ����';
      Exit;
    end;
    Sleep(100);
  end;
  Result := 'OK';
end;

function TModelCom.SendCommand(ACmd: AnsiString; ATimes: Integer): string;
var
  sRet: string;
  sBuf: AnsiString;
  sTmp: string;
  nPos: Integer;
begin
  Result := 'δ֪����';
  sRet := SendAndWaitPack(ACmd, sBuf);
  sTmp := sBuf;
  sTmp := StringReplace(sTmp, chr($0A), '', [rfReplaceAll]);
  sTmp := StringReplace(sTmp, chr($0D), '', [rfReplaceAll]);
  AddLogMsg('SendAndWaitPack:%s, %s', [sRet, sTmp]);
  if sRet <> 'OK' then
  begin
    Result := Format('[%s-%s]ִ������[%s]����ԭ��[%s]', [GConfig.GroupName, ComParam.ComPort, string(ACmd), string(sRet)]);;
    Exit;
  end;
  //sTmp := StringReplace(str, #13, '', [rfReplaceAll]);
  //sTmp := StringReplace(str, #10, '', [rfReplaceAll]);
  //AddLogMsg(sTmp,[]);
  if Pos('ERROR', sTmp) > 0 then
  begin
    Result := Format('[%s-%s]ִ������[%s]����ԭ��[%s]', [GConfig.GroupName, ComParam.ComPort, string(ACmd), string(sTmp)]);;
    Exit;
  end;
  Result := 'OK';
end;

function TModelCom.SendSms(AMsgContent: string): string;
var
  {center,}cmd,sLen, pdu_midx, sPhoneNum: string;
  len: Integer;
begin
  {$IFDEF DEBUG}
  Self.HasLog := True;
  {$ENDIF}
  Result := 'δ֪����';
  //���ĺ���
//  center := uModel.PhoneNumber2PDU(uData.SMS_CENTER);
//  center := GetSmsCenterNumber;
//  center := uModel.PhoneNumber2PDU(center);

  //�Է��ֻ���������
  pdu_midx := StringReplace(FTargetPhone, 'F', '', [rfReplaceAll]);
  sLen := IntToHex(Length(pdu_midx), 2);
  pdu_midx := '1100'+sLen + '81';

  //�Է��ֻ�����
  sPhoneNum := uPduProtocol.PhoneNumber2PDU(FTargetPhone);

  //��������
  AMsgContent := uPduProtocol.EncodeUCS2(AMsgContent);
  sLen := IntToHex(Trunc(Length(AMsgContent) / 2), 2);
  AMsgContent := sLen + AMsgContent;

  //�������ݳ���
  len := Trunc(Length(pdu_midx+sPhoneNum+PDU_SUFX+AMsgContent) / 2);
  sLen := IntToStr(len);
  if len < 10 then
    sLen := '0'+ sLen;

  //
  cmd := 'AT+CMGS='+sLen+#13;
  Result := SendCommand(AnsiString(cmd));
  if Result <> 'OK' then
  begin
    Exit;
  end;

  cmd := PDU_PREX + {center +} pdu_midx + sPhoneNum + PDU_SUFX + AMsgContent+#26+#13#10;
  Result := SendCommand(AnsiString(cmd));
  {$IFDEF DEBUG}
  AddLogMsg(Self.Log.Text, []);
  {$ENDIF}
end;

end.
