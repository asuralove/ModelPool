unit uData;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.ShellAPI, Vcl.FileCtrl, System.SysUtils;

const
  WM_ADD_LOG  = WM_USER + 1001;
  WM_SEND_RET = WM_USER + 1002;
  //
  DIGIT_DICT = 'QuitSafeConfig\DigitDict.txt';
  SYS_DICT   = 'QuitSafeConfig\SysDict.txt';
  SAFE_CODE  = 'sTnItrFttpcWUASfy0x1Vy94obcrWqJe';
  KEMULATOR_DIR_OLD = '%s\�ֻ�ģ����';
  KEMULATOR_CFG_OLD = '%s\�ֻ�ģ����\property.txt';
  TOKEN_DIR_OLD     = '%s\�ֻ�ģ����\rms\SonyEricssonK800_240x320\.token_config';

  KEMULATOR_DIR_NEW = '%s\�ֻ�ģ����-New';
  KEMULATOR_CFG_NEW = '%s\�ֻ�ģ����-New\property.txt';
  TOKEN_DIR_NEW     = '%s\�ֻ�ģ����-New\rms\SonyEricssonK800_240x320\.token_config';

  TOKEN_SRC_ZIP_FILE  = '%s\�����ļ�\%s.zip';
  TOKEN_SRC_DIR       = '%s\�����ļ�\%s';
  KEMULATOR_BAT = 'KEmulator.bat';
  //
  FLAG_NONE = 0;
  FLAG_SEND = 1; //'���ڷ�����';
  FLAG_RECV = 2; //'�����ն���';

type
  Tdm2 = record
    account : string;
    password: string;
    use     : Boolean;
  end;
  TDama2Ret = record
    text: string;
    code: Integer;
  end;

var
  GMainHandle: Hwnd;
  dm2: Tdm2;
  GAppPath: string;

implementation

end.
