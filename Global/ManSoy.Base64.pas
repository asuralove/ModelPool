unit ManSoy.Base64;

//delphi7��EncdDecd��ԪEncodeString��������Ҳ��base64���뺯��

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  EncdDecd;
  //IdGlobal,Dialogs, StdCtrls;


function StrToBase64(const str: string): string;
function Base64ToStr(const Base64: AnsiString): AnsiString;


implementation

function StrToBase64(const str: string): string;
var
  s:AnsiString;
begin
  s := AnsiString(str);
  Result := string(EncdDecd.EncodeBase64(PAnsiChar(s), Length(s)));
  Result := StringReplace(Result, #13#10, '', [rfReplaceAll]);//ȥ���س�����,��Ϊ��Щϵͳ��֧��
end;

function Base64ToStr(const Base64: AnsiString): AnsiString;
var
  vBuf:TBytes;
begin
  vBuf := EncdDecd.DecodeBase64(Base64);
  SetLength(Result, Length(vBuf));
  CopyMemory(PAnsiChar(Result), @vBuf[0], Length(vBuf));
end;

end.
