unit uPublic;

interface

uses Windows, Messages;

type
  TCommType = (
    ctNone,             //--������
    ctResult,           //--���ؽ��
    ctGroupName,        //--�豸�˸����м���Լ������ʶ
    ctSendMsg,          //--���Ͷ���
    ctRecvMsg           //--���ն��ţ��豸���յ����ź󷵻ظ������
    );

  //--������
  TResultState = (
    rsSuccess,          //--�ɹ�
    rsFail              //--ʧ��
  );

  //--��¼�豸������Ϣ
  PDeviceInfo = ^TDeviceInfo;
  TDeviceInfo = record
    IsDevice: Boolean;      //--��ʶ���豸�ˣ� ���ǿͻ��ˣ�
    ConnectID: DWORD;       //--Socket
    GroupName: string[50];
    IP: string[20];
    Port: Word;
  end;

//  //--���÷����ʶ
//  PGroupData = ^TGroupData;
//  TGroupData = packed record
//    CommType : TCommType;
//    GroupName: TGroupName;
//  end;

var
  GFrmMainHwnd: HWND;

const
  WM_ADD_LOG    = WM_USER + 1001;
  WM_ADD_DEVICE = WM_USER + 1002;

implementation

end.
