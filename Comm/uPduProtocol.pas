unit uPduProtocol;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Registry;

  function GetCommNames(): string;
  function ExchangeCode(AStr:string): string;
  function Encode7bit(AStr: string): string;
  function Decode7bit(AStr: string): string;
  function EncodeUCS2(AStr: string): string;
  function DecodeUCS2(AStr: string): string;
  function Unicode2Ansi(AStr: string): string;
  function Ansi2Unicode(AStr: string): string;
  function PhoneNumber2PDU(AStr: string): string;
  function PDU2PhoneNumber(AStr: string): string;
  function Date2PDU(ADate: TDateTime): string;
  function PDU2Date(ADate: string): TDateTime;
  function PDU2DateStr(ADate: string): string;
  
  
implementation

function GetCommNames(): string;
var
  reg: TRegistry;
  lst,lst2: TStrings;
  i: integer;
begin
  lst:=TStringList.Create;
  lst2:=TStringList.Create;
  reg:=TRegistry.Create;
  try
    reg.RootKey :=HKEY_LOCAL_MACHINE;
    reg.OpenKey('HARDWARE\DEVICEMAP\SERIALCOMM',true);
    reg.GetValueNames(lst);
    for i := 0  to lst.Count -1 do
      lst2.Add(reg.ReadString(lst[i]));
    Result := lst2.CommaText;
  finally
    reg.CloseKey;
    reg.Free;
    lst.Free;
    lst2.Free;
  end;
end;

function Encode7bit(AStr: string): string;
var
  i,j,len: Integer;
  cur: Integer;
  s: string;
begin
  Result := '';
  len := Length(AStr);
  //j ������λ����
  i := 1;
  j := 0;
  while i <= len do
  begin
    if i < len then
    begin
       //���ݱ任
      cur := (Ord(AStr[i]) shr j) or ((Ord(AStr[i+1]) shl (7-j)) and $ff);
    end
    else
    begin
      cur := (Ord(AStr[i]) shr j) and $7f;
    end;
    FmtStr(s, '%2.2X', [cur]);
    Result := Result+s;
    inc(i);
    //��λ�����ﵽ7λ���ر���
    j := (j+1) mod 7;
    if j = 0 then inc(i);
  end;
end;

function Decode7bit(AStr: string): string;
var
  nSrcLength:Integer;
  nSrc:Integer; // Դ�ַ����ļ���ֵ
  nByte:Integer; // ��ǰ���ڴ���������ֽڵ���ţ���Χ��0-6
  nLeft:Byte; // ��һ�ֽڲ��������
  tmpChar:Byte;
  pDst:string;
begin
  // ����ֵ��ʼ��
  nSrc := 1;
  nSrcLength:=Length(AStr);
  // �����ֽ���źͲ������ݳ�ʼ��
  nByte := 0;
  nLeft := 0;
  pdst := '';
    // ��Դ����ÿ7���ֽڷ�Ϊһ�飬��ѹ����8���ֽ�
    // ѭ���ô�����̣�ֱ��Դ���ݱ�������
    // ������鲻��7�ֽڣ�Ҳ����ȷ����
  while (nSrc < nSrcLength) do
  begin
      tmpChar := byte(StrToInt('$' + AStr[nsrc] + AStr[nsrc + 1]));
      // ��Դ�ֽ��ұ߲��������������ӣ�ȥ�����λ���õ�һ��Ŀ������ֽ�
      pDst := pDst + Char(((tmpchar shl nByte) or nLeft) and $7F);
      // �����ֽ�ʣ�µ���߲��֣���Ϊ�������ݱ�������
      nLeft := tmpChar shr (7 - nByte);

      // �޸��ֽڼ���ֵ
      Inc(nByte);

      // ����һ������һ���ֽ�
      if (nByte = 7) then
      begin
          // ����õ�һ��Ŀ������ֽ�
          pdst := pDst + Char(nLeft);

          // �����ֽ���źͲ������ݳ�ʼ��
          nByte := 0;
          nLeft := 0;
      end; //end if

      // �޸�Դ����ָ��ͼ���ֵ

      nSrc:= nSrc + 2;
  end;
  // ����Ŀ�괮����
  Result:= pdst;
end;

function EncodeUCS2(AStr: string): string;
var
  ws: WideString;
  i,len: Integer;
  cur: Integer;
  s: string;
begin
 Result:='';
 ws := AStr;
 len:= Length(ws);
 i:=1;
 while i <= len do
 begin
    cur:= ord(ws[i]);
    FmtStr(s, '%4.4X', [cur]); //BCDת��
    Result:= Result+s;
    inc(i);
 end;
end;

function DecodeUCS2(AStr: string): string;
var
   i:Integer;
   S:String;
   D:WideChar;
   ResultW: WideString;
begin
   for i:=1 to Round(Length(AStr)/4) do
   begin
       S:= Copy(AStr, (i - 1) * 4 + 1, 4);
       D:= WideChar(StrToInt('$' + S));
       ResultW:= ResultW + D;
   end;
   Result:= ResultW;
end;

function Ansi2Unicode(AStr: string): string;
var
  s: string;
  i: Integer;
  j,k: string[2];
  a: array[1..1000] of Char;
begin
  s := '';
  StringToWideChar(AStr, @(a[1]), 500);
  i := 1;
  while ((a[i] <> #0) or (a[i + 1] <> #0)) do
  begin
    j := IntToHex(Integer(a[i]), 2);
    k := IntToHex(Integer(a[i + 1]), 2);
    s := s + k + j;
    i := i + 2;
  end;
  Result := s;
end;

function Unicode2Ansi(AStr: string): string;
var
  s:string;
  i:integer;
  j, k:string[2];
  function ReadHex(AStr: string):integer;
  begin
    Result := StrToInt('$' + AStr)
  end;
begin
  i := 1;
  s := '';
  while i < Length(AStr) do
  begin
    j := Copy(AStr, i + 2, 2);
    k := Copy(AStr, i, 2);
    i := i + 4;
    s := s + Char(readhex(j)) + Char(ReadHex(k));
  end;
  if s <> '' then
    s := WideCharToString(PWideChar(s + #0#0#0#0))
  else
    s := '';
  Result := s;
end;


function PhoneNumber2PDU(AStr: string): string;
begin
  AStr:=  StringReplace(AStr, '+', '', [rfReplaceAll]);
//  if Copy(AStr, 1 , 2) <> '86' then
//    AStr := '86' + AStr;

  if ((length(AStr) mod 2) = 1) then
  begin
    AStr:= AStr + 'F';
  end;
  Result:= ExchangeCode(AStr);
end;

function PDU2PhoneNumber(AStr: string): string;
begin
  Result:= ExchangeCode(AStr);
  Result:= StringReplace(Result, 'F', '', [rfReplaceAll]);
end;

function ExchangeCode(AStr: string): string;
var
  I: Integer;
begin
  Result:= '';
  for i:=1 to (Length(AStr) Div 2) do
  begin
    Result:= Result+AStr[I*2]+AStr[I*2-1];
  end;
end;

function Date2PDU(ADate: TDateTime): string;
var
  str:  String;
begin
  DateTimeToString(str,'YYMMDDHHMMSS', ADate);
  Result := ExchangeCode(str);
end;

function PDU2Date(ADate: string): TDateTime;
var
  tem:String;
begin
  tem := PDU2DateStr(ADate);
  Result:= StrToDateTimeDef(tem, 0);
end;

function PDU2DateStr(ADate: string): string;
var
  str:String;
begin
  str := ExchangeCode(ADate);//���𣬽��Ϊ081129105833
  Result := copy(str,1,2)+'-'+  //��ʽ�������Ϊ08-11-29 10:58:33
            copy(str,3,2)+'-'+
            copy(str,5,2)+' '+
            copy(str,7,2)+':'+
            copy(str,9,2)+':'+
            copy(str,11,2);
end;

end.
