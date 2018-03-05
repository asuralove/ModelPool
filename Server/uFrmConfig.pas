unit uFrmConfig;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Samples.Spin, Vcl.StdCtrls, Vcl.ExtCtrls,
  Data.DB, Data.Win.ADODB, uServerPublic;

type
  TFrmConfig = class(TForm)
    GroupBox1: TGroupBox;
    Label1: TLabel;
    edtIpAddress: TEdit;
    Label2: TLabel;
    edtPort: TSpinEdit;
    GroupBox2: TGroupBox;
    edtDataBaseHost: TEdit;
    Label3: TLabel;
    Label4: TLabel;
    edtDataBaseName: TEdit;
    Label5: TLabel;
    edtAccount: TEdit;
    Label6: TLabel;
    edtPassWord: TEdit;
    RadioGroup1: TRadioGroup;
    btnSave: TButton;
    Button3: TButton;
    btnTestConn: TButton;
    procedure btnSaveClick(Sender: TObject);
    procedure btnTestConnClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FrmConfig: TFrmConfig;

implementation

{$R *.dfm}

procedure TFrmConfig.btnSaveClick(Sender: TObject);
begin
  if Trim(edtIpAddress.Text) = '' then begin
    MessageBox(Self.Handle, '����IP����Ϊ�գ�', '����', MB_ICONWARNING);
    Exit;
  end;

  if edtPort.Value = 0 then begin
    MessageBox(Self.Handle, '����˿ڲ���Ϊ0��', '����', MB_ICONWARNING);
    Exit;
  end;

  if Trim(edtDataBaseHost.Text) = '' then begin
    MessageBox(Self.Handle, '���ݿ�IP����Ϊ�գ�', '����', MB_ICONWARNING);
    Exit;
  end;

  if Trim(edtDataBaseName.Text) = '' then begin
    MessageBox(Self.Handle, '���ݿ����Ʋ���Ϊ�գ�', '����', MB_ICONWARNING);
    Exit;
  end;

  if Trim(edtAccount.Text) = '' then begin
    MessageBox(Self.Handle, '���ݿ��˺Ų���Ϊ�գ�', '����', MB_ICONWARNING);
    Exit;
  end;
  Self.ModalResult := mrOk;
end;

procedure TFrmConfig.btnTestConnClick(Sender: TObject);
begin
  TButton(Sender).Enabled := False;
  try
    if ConnDataBase then
      MessageBox(Self.Handle, '���ӳɹ�', '��ʾ', MB_ICONINFORmATION)
    else
      MessageBox(Self.Handle, '����ʧ��', '����', MB_ICONWARNING);
  finally
    TButton(Sender).Enabled := True;
  end;
end;

end.
