unit uTokenThread;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, Winapi.ActiveX,
  Winapi.WinInet, Winapi.ShellAPI,
  Winapi.Messages,
  ManSoy.Encode,
  uData,
  IdTCPClient,
  IdHTTP;

type

  PQQTokensData = ^TQQTokensData;
  TQQTokensData = packed record
      szEvent:string[50];
      szQQUin:string[50];
      szInitCode:string[100];
      szOriginalSn:string[50];
      szSerialNumber:string[200];
      szDnyPsw:string[50];
      szDnyPswTime:string[100];
  end;

  TTokenThread = class(TThread)
  private
    FAccount          : string;
    FMBType           : Integer;
    FKey              : string;
    FTokenServerIp        : string;
    FTokenServerPort      : WORD;

    function DownloadKMFiles(AFileName: string): Boolean;
    function InitTokenFiles: boolean;
    function GetToken(AMBType: Integer): string;
  protected
    procedure Execute; override;
  public
    constructor Create(AAccount: string; AMBType: Integer);
    destructor Destroy; override;
    property Account    : string  read FAccount     write FAccount;
    property MBType     : Integer read FMBType      write FMBType;
    property Key        : string  read FKey         write FKey;
    property TokenServerIp  : string  read FTokenServerIp   write FTokenServerIp;
    property TokenServerPort: WORD    read FTokenServerPort write FTokenServerPort;
  end;

var
  URL_Download_KM_File : string = '';
  TokenPackData : TQQTokensData;
  IdTCPClient: TIdTcpClient;

implementation

uses System.IniFiles, System.StrUtils, System.Win.ComObj, ManSoy.MsgBox, ManSoy.Global,
     uFun, DmUtils;

{ TDispatchThread }

constructor TTokenThread.Create(AAccount: string; AMBType: Integer);
begin
  FAccount    := AAccount;
  FMBType     := AMBType;
  FKey        := '';
  with TIniFile.Create(ExtractFilePath(ParamStr(0))+'QuitSafeConfig\Cfg.ini') do
  try
    FTokenServerIp   := ReadString('TokenSvr', 'Host', '113.140.30.46'); //192.168.192.252
    FTokenServerPort := ReadInteger('TokenSvr', 'Port', 59998);          //8899
    URL_Download_KM_File := ReadString('KEmulator', 'url', '');
  finally
    Free;
  end;

  InitTokenFiles;

  FreeOnTerminate := True;
  inherited Create(false);
end;

destructor TTokenThread.Destroy;
begin

  inherited;
end;

function TTokenThread.InitTokenFiles: Boolean;
var
  tokenSrc_dir,tokenSrcZip_file,
  tokenDir_old,kemulatorDir_old,
  tokenDir_new,kemulatorDir_new: string;
begin
  result := false;
  tokenSrc_dir     := Format(TOKEN_SRC_DIR,  [ExtractFileDir(ParamStr(0)), FAccount]);
  tokenSrcZip_file := Format(TOKEN_SRC_ZIP_FILE,  [ExtractFileDir(ParamStr(0)), FAccount]);

  tokenDir_old     := Format(TOKEN_DIR_OLD,     [ExtractFileDir(ParamStr(0))]);
  kemulatorDir_old := Format(KEMULATOR_DIR_OLD, [ExtractFileDir(ParamStr(0))]);

  tokenDir_new     := Format(TOKEN_DIR_NEW,     [ExtractFileDir(ParamStr(0))]);
  kemulatorDir_new := Format(KEMULATOR_DIR_NEW, [ExtractFileDir(ParamStr(0))]);
  case FMBType of
    40: //KM(new)
    begin
      DeleteFile(tokenSrcZip_file); //ɾ������ѹ���ļ�
      DelDir(tokenSrc_dir);         //ɾ�����ƽ�ѹ����ļ���

      LogOut('���������ļ�(new)...', []);
      if not DownloadKMFiles(tokenSrcZip_file) then Exit; //���������ļ�

      LogOut('��ѹ�����ļ�...', []);
      Unzip(tokenSrcZip_file, tokenSrc_dir); //��ѹ�����ļ�
      LogOut('����.token_configĿ¼...', []);
      ClearDir(tokenDir_new);
      LogOut('���������ļ���.token_configĿ¼...', []);
      CopyDir(tokenSrc_dir, tokenDir_new, false);
    end;
    50: //KM(old)
    begin
      DeleteFile(tokenSrcZip_file); //ɾ������ѹ���ļ�
      DelDir(tokenSrc_dir);         //ɾ�����ƽ�ѹ����ļ���

      LogOut('���������ļ�(old)...', []);
      if not DownloadKMFiles(tokenSrcZip_file) then Exit; //���������ļ�
      LogOut('��ѹ�����ļ�...', []);
      Unzip(tokenSrcZip_file, tokenSrc_dir); //��ѹ�����ļ�
      LogOut('����.token_configĿ¼...', []);
      ClearDir(tokenDir_new);
      LogOut('���������ļ���.token_configĿ¼...', []);
      CopyDir(tokenSrc_dir, tokenDir_old, false);
    end;
  end;
  result:= true;
end;


function TTokenThread.DownloadKMFiles(AFileName: string): Boolean;
var
  vResponseContent: TMemoryStream;
  vParam: TStrings;
  hFile: HWND;
  http: TIdHTTP;
  dir: string;
begin
  Result := False;
  DeleteFile(AFileName);
  vResponseContent := TMemoryStream.Create;
  vParam := TStringList.Create;
  http := TIdHTTP.Create(nil);
  try
    vParam.Add('GAME_ACCOUNT_NAME='+FAccount);
    vParam.Add('SAFE_CODE='+SAFE_CODE);
    http.Post(URL_Download_KM_File, vParam, vResponseContent);

    dir := ExtractFileDir(AFileName);
    if not DirectoryExists(dir) then
      ForceDirectories(dir);

    vResponseContent.SaveToFile(AFileName);
    hFile := FileOpen(AFileName, 0);
    Result := GetFileSize(hFile, nil) > 0;
    FileClose(hFile);
  finally
    vResponseContent.Free;
    vParam.Free;
    http.Disconnect;
    FreeAndNil(http);
  end;
end;

procedure TTokenThread.Execute;
var
  sToken:string;
begin
  try
    ManSoy.Global.DebugInf('MS - ��ʼ�˺ŵ�¼...', []);
    sToken := GetToken(FMBType);
    if sToken <> '' then
    begin
      ManSoy.MsgBox.InfoMsg(0, '�������֡�%s��'#13'�Ѿ����Ƶ����а�', [sToken]);
      WriteClipboard(sToken);
    end else
    begin
      ManSoy.MsgBox.WarnMsg(0, '��ȡ����ʧ��', []);
    end;
  except on E: Exception do
    begin
      ManSoy.MsgBox.WarnMsg(0, '��ȡ��̬�����쳣'#13'%s', [E.Message]);
      Exit;
    end;
  end;
end;

function TTokenThread.GetToken(AMBType: Integer): string;
var
  hKEmulator,dwDealyTimes: HWND;
  tokenSrc_dir,tokenSrcZip_file,
  tokenDir_old,kemulatorDir_old,
  tokenDir_new,kemulatorDir_new: string;
  I: Integer;
  pt: TPoint;
  s, subPic: string;
begin
  Result := '';
  tokenSrc_dir     := Format(TOKEN_SRC_DIR,  [ExtractFileDir(ParamStr(0)), FAccount]);
  tokenSrcZip_file := Format(TOKEN_SRC_ZIP_FILE,  [ExtractFileDir(ParamStr(0)), FAccount]);

  tokenDir_old     := Format(TOKEN_DIR_OLD,     [ExtractFileDir(ParamStr(0))]);
  kemulatorDir_old := Format(KEMULATOR_DIR_OLD, [ExtractFileDir(ParamStr(0))]);

  tokenDir_new     := Format(TOKEN_DIR_NEW,     [ExtractFileDir(ParamStr(0))]);
  kemulatorDir_new := Format(KEMULATOR_DIR_NEW, [ExtractFileDir(ParamStr(0))]);
  try
  try
    case AMBType of
      40: //KM(new)
      begin
        LogOut('���ֻ�����ģ����...', []);
        ShellExecute(0, nil, PChar(KEMULATOR_BAT), nil, PChar(kemulatorDir_new), SW_HIDE);
        dwDealyTimes := GetTickCount;
        while GetTickCount - dwDealyTimes < 1 * 60 * 1000 do
        begin
          hKEmulator := FindWindow(nil, 'KEmulator Lite v0.9.8');
          if not IsWindow(hKEmulator) then continue;
          pt := DmUtils.fnFindWordOnWindow(hKEmulator, '��̬����', 'ffffff-000000', SYS_DICT);
          if (pt.X <> -1) and (pt.Y <> -1) then Break;
        end;
        if (pt.X = -1) or (pt.Y = -1) then
        begin
          LogOut('���ֻ�����ģ������ʱ���˳�...', []);
          Exit;
        end;
        LogOut('��ȡ�ֻ�����...', []);
        s := '';
        subPic := ExtractFilePath(ParamStr(0)) + 'Bmp\%d.bmp';
        //��1λ
        for I := 0 to 9 do
        begin
          if DmUtils.fnPicExistOnWindowArea(hKEmulator, 49,128,75,177, Format(subPic, [I])) then
          //if DmUtils.fnPicExistOnWindowArea(hKEmulator, 46,87,72,126,ExtractFilePath(ParamStr(0))+Format('Bmp\%d.bmp', [I])) then
          begin  s := s + IntToStr(I); Break; end;
        end;
        //��2λ
        for I := 0 to 9 do
        begin
          if DmUtils.fnPicExistOnWindowArea(hKEmulator, 74,128,100,177,Format(subPic, [I])) then
          //if DmUtils.fnPicExistOnWindowArea(hKEmulator, 71,87,97,126,ExtractFilePath(ParamStr(0))+Format('Bmp\%d.bmp', [I])) then
          begin  s := s + IntToStr(I); Break; end;
        end;
        //��3λ
        for I := 0 to 9 do
        begin
          if DmUtils.fnPicExistOnWindowArea(hKEmulator, 99,128,125,177,Format(subPic, [I])) then
          //if DmUtils.fnPicExistOnWindowArea(hKEmulator, 96,87,122,126,ExtractFilePath(ParamStr(0))+Format('Bmp\%d.bmp', [I])) then
          begin  s := s + IntToStr(I); Break; end;
        end;
        //��4λ
        for I := 0 to 9 do
        begin
          if DmUtils.fnPicExistOnWindowArea(hKEmulator, 124,128,150,177,Format(subPic, [I])) then
          //if DmUtils.fnPicExistOnWindowArea(hKEmulator, 121,87,147,126,ExtractFilePath(ParamStr(0))+Format('Bmp\%d.bmp', [I])) then
          begin  s := s + IntToStr(I); Break; end;
        end;
        //��5λ
        for I := 0 to 9 do
        begin
          if DmUtils.fnPicExistOnWindowArea(hKEmulator, 149,128,175,177,Format(subPic, [I])) then
          //if DmUtils.fnPicExistOnWindowArea(hKEmulator, 146,87,172,126,ExtractFilePath(ParamStr(0))+Format('Bmp\%d.bmp', [I])) then
          begin  s := s + IntToStr(I); Break; end;
        end;
        //��6λ
        for I := 0 to 9 do
        begin
          if DmUtils.fnPicExistOnWindowArea(hKEmulator, 174,128,200,177,Format(subPic, [I])) then
          //if DmUtils.fnPicExistOnWindowArea(hKEmulator, 171,87,197,126,ExtractFilePath(ParamStr(0))+Format('Bmp\%d.bmp', [I])) then
          begin  s := s + IntToStr(I); Break; end;
        end;
        SendMessage(hKEmulator, WM_CLOSE, 0, 0);
        LogOut('�õ����ƣ�%s', [s]);
        if Length(s) <> 6 then
        begin
          LogOut('�ֻ����ƴ����˳�...', []);
          Exit;
        end;
        TokenPackData.szDnyPsw := s;
        LogOut('ɾ�������ļ�...', []);
      end;
      50: //KM(old)
      begin
        LogOut('���ֻ�����ģ����...', []);
        ShellExecute(0, nil, PChar(KEMULATOR_BAT), nil, PChar(kemulatorDir_old), SW_HIDE);
        dwDealyTimes := GetTickCount;
        while GetTickCount - dwDealyTimes < 1 * 60 * 1000 do
        begin
          hKEmulator := FindWindow(nil, 'KEmulator Lite v0.9.8');
          if IsWindow(hKEmulator) then Break;
        end;
        if not IsWindow(hKEmulator) then
        begin
          LogOut('���ֻ�����ģ������ʱ���˳�...', []);
          Exit;
        end;
        LogOut('��ȡ�ֻ�����...', []);
        TokenPackData.szDnyPsw := DmUtils.fnFindWordByColor(hKEmulator, 50, 60, 200, 110, 'ffffff-000000', DIGIT_DICT, 1, 10);
        LogOut('�õ����ƣ�%s', [TokenPackData.szDnyPsw]);
        SendMessage(hKEmulator, WM_CLOSE, 0, 0);
        if StrToIntDef(TokenPackData.szDnyPsw, -1) = -1 then
        begin
          LogOut('�ֻ����ƴ����˳�...', []);
          Exit;
        end;
        LogOut('ɾ�������ļ�...', []);
      end;
    else //9891 KJava
      begin
        try
          IdTCPClient := TIdTCPClient.Create(nil);

          IdTCPClient.Host := FTokenServerIp;        //113.140.30.46
          IdTCPClient.Port := FTokenServerPort;      //59998
          IdTCPClient.Connect;   //�����м��
          if IdTCPClient.Connected then
          begin
            try
              s := Base64ToStr(IdTCPClient.IOHandler.ReadLn());  //�����м����������Ϣ
              logout(s, []);
              try
                s := 'DATA:' + FAccount+'|'+FKey;
                IdTCPClient.IOHandler.WriteLn(s);  //��������
                s := Base64ToStr(IdTCPClient.IOHandler.ReadLn());   //����token
                logout(s, []);
                if Pos('token:', s) > 0 then
                begin
                  s := copy(s, 7, length(s) - 6);
                  TokenPackData.szDnyPsw := s;
                end;
              except
                logout('Reauest Middle-Server failed!', []);
                IdTCPClient.Disconnect();
                logout('Disconnect with Middle-Server!', []);
              end;
            except
              logout('Middle-Server no response!', []);
              IdTCPClient.Disconnect();
            end;
          end;
        except
          logout('Connect Middle-Server failed!', []);
        end;
      end;
    end;
    Result := TokenPackData.szDnyPsw;
  except on e:Exception do
    LogOut('��ȡ�����쳣[%s]', [e.message]);
  end;
  finally
    if IdTCPClient <> nil then
      FreeAndNil(IdTCPClient);
  end;
end;

end.
