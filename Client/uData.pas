unit uData;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes;

type
  TCmdType = (ctNone, ctInit, ctOpen, ctClose, ctSend, ctRead);
  TCmdRet = (crNone, crError, crTimeout, crOK, crSuccess);
  TConfig = record
    Host: string;
    Port: Integer;
    GroupName: string;
    SyncSocket: Boolean;
    BaudRate: DWORD;
  end;
const
  WM_ADD_LOG = WM_USER + 1001;
  WM_ADD_LOG2 = WM_USER + 1002;

  SMS_CENTER ='8613800913500';

  //PDU_PREX = '0891';
  PDU_PREX = '00';
  //PDU_MIDX = '31000D91';
  PDU_SUFX = '000800';

  CODE_7BIT = '0000';
  CODE_8BIT = '0004';
  CODE_UCS2 = '0008';

  procedure AddLogMsg(AMsg: string; Args: array of const; ADebug: Boolean = False);
  procedure LogToFile(AText: string); overload;
  procedure SaveCfg(AFileName: string; AText: string); overload;

var
  hLog: HWND;
  GConfig: TConfig;

implementation

procedure AddLogMsg(AMsg: string; Args: array of const; ADebug: Boolean = False);
var
  sMsg: string;
begin
  sMsg := Format(AMsg, Args, FormatSettings);
  sMsg := Format('[%s]%s', [FormatDateTime('yyyy-MM-dd hh:mm:ss', Now), sMsg]);
  if ADebug then
  begin
{$IFDEF DEBUG}
    SendMessage(hLog, WM_ADD_LOG, 0, LPARAM(sMsg));
    Exit;
{$ENDIF}
  end else
  begin
    SendMessage(hLog, WM_ADD_LOG, 0, LPARAM(sMsg));
  end;
{$IFNDEF DEBUG}
  LogToFile(sMsg);
{$ENDIF}
end;

procedure LogToFile(AText: string);
var
  f: TextFile;
  dir, fileName: string;
begin
  try
    dir := ExtractFilePath(ParamStr(0)) + 'log\';
    if not DirectoryExists(dir) then
      ForceDirectories(dir);
    fileName := dir + FormatDateTime('yyyyMMdd', Now) + '.log';
    try
      AssignFile(f, fileName); {���ļ�������� F ����}
      if FileExists(fileName) then
        Append(f) //�ļ����ڣ�����׷�ӷ�ʽ��
      else
        Rewrite(f); //�ļ������ڣ��򴴽�����

      Writeln(f, AText); //���ļ�ĩβ�������
      //Flush(f); //��ջ�������ȷ���ַ����Ѿ�д���ļ�֮��
    finally
      CloseFile(f);
    end;
  except
  end;
end;

procedure SaveCfg(AFileName: string; AText: string); overload;
var
  f: TextFile;
  dir, fileName: string;
begin
  try
    dir := ExtractFileDir(AFileName);
    fileName := ExtractFileName(AFileName);
    //dir := ExtractFilePath(ParamStr(0)) + 'config\';
    if not DirectoryExists(dir) then
      ForceDirectories(dir);
    fileName := dir + fileName;
    try
      AssignFile(f, fileName); {���ļ�������� F ����}
      if FileExists(fileName) then
        Append(f) //�ļ����ڣ�����׷�ӷ�ʽ��
      else
        Rewrite(f); //�ļ������ڣ��򴴽�����

      Writeln(f, AText); //���ļ�ĩβ�������
      //Flush(f); //��ջ�������ȷ���ַ����Ѿ�д���ļ�֮��
    finally
      CloseFile(f);
    end;
  except
  end;
end;

end.
