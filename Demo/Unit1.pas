unit Unit1;

{
  Requiriments:
  Project-Options-Entitlement List-Secure File Sharing = True

  For Delphi 10.4+ there is no need to exchange the provider_paths.xml, while
  checking TRUE "Secure File Sharing" Delphi will create its own provider_paths.xml,
  doesn't matter if you exchange it or not
  
  
  Tests on:
  Delphi 11 + 2 Patchs: Android 10, 12  
}

interface

uses
  System.Permissions,
  uPdfPrint,

  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts;

type
  TForm1 = class(TForm)
    btnPreview: TButton;
    Layout1: TLayout;
    btnShare: TButton;
    procedure btnPreviewTap(Sender: TObject; const Point: TPointF);
  private
    FIsToShare: Boolean;

    procedure PdfFunction;

    {
      This sample is not about Permissions, please, take a look at some other
      sample to learn more regarding this subject
    }
    procedure DisplayRationale(
      Sender: TObject;
      const APermissions: {$IF CompilerVersion >= 35.0}TClassicStringDynArray{$ELSE}TArray<string>{$ENDIF};
      const APostRationaleProc: TProc
      );
    procedure GetPermissionRequestResult(
      Sender: TObject;
      const APermissions: {$IF CompilerVersion >= 35.0}TClassicStringDynArray{$ELSE}TArray<string>{$ENDIF};
      const AGrantResults: {$IF CompilerVersion >= 35.0}TClassicPermissionStatusDynArray{$ELSE}TArray<TPermissionStatus>{$ENDIF}
      );
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

uses
{$IFDEF ANDROID}
  Androidapi.Helpers,
  Androidapi.JNI.JavaTypes,
  Androidapi.JNI.Os,
{$ENDIF}
  FMX.DialogService;

{$R *.fmx}


procedure TForm1.btnPreviewTap(Sender: TObject; const Point: TPointF);
var
  FPermissionReadExternalStorage,
    FPermissionWriteExternalStorage: string;
begin
  {
    Since Android10* (newer) the Android file manager was changed, so we are
    using now System.IOUtils.TPath.GetPublicPath instead the old version
    the path on your Cellphone is on /storage/emulated/0/Android/data/<Project PackageName>/files

    It is a public path which can be reached through APP File Manager OR your own PC
  }

  FIsToShare := Sender = btnShare;

  {
    This sample is not about Permissions, please, take a look at some other
    sample to learn more regarding this subject
  }
  FPermissionReadExternalStorage := JStringToString(TJManifest_permission.JavaClass.READ_EXTERNAL_STORAGE);
  FPermissionWriteExternalStorage := JStringToString(TJManifest_permission.JavaClass.WRITE_EXTERNAL_STORAGE);
  PermissionsService.RequestPermissions([
    FPermissionReadExternalStorage,
    FPermissionWriteExternalStorage],
    GetPermissionRequestResult,
    DisplayRationale);
end;

procedure TForm1.PdfFunction;
var
  lPdf: TPDFPrint;
  vSizeFont, vFormFont: Integer;
  pFase: String;
  I, Conta: Integer;
begin
  Conta := 0;
  vSizeFont := 10;
  vFormFont := 8;

  lPdf := TPDFPrint.Create('SoretoPdfPrint');
  try
    lPdf.Open;
    lPdf.FonteName := 'Arial';
    lPdf.BordaSupInf := 6;
    lPdf.BordaLefRig := 25;
    lPdf.ImpC(1, 1, 'Something here', Normal, TAlphaColors.Black, vSizeFont);
    lPdf.ImpLinhaH(Conta, 1, 52, TAlphaColors.Gray);
    lPdf.Close;

    if FIsToShare then
      lPdf.Share
    else
      lPdf.Preview;
  finally
    lPdf.Free;
  end;
end;

procedure TForm1.DisplayRationale(Sender: TObject;
  const APermissions: {$IF CompilerVersion >= 35.0}TClassicStringDynArray{$ELSE}TArray<string>{$ENDIF};
  const APostRationaleProc: TProc);
begin
  TDialogService.ShowMessage('The permissions are needed',
    procedure(const AResult: TModalResult)
    begin
      APostRationaleProc;
    end)
end;

procedure TForm1.GetPermissionRequestResult(Sender: TObject;
  const APermissions: {$IF CompilerVersion >= 35.0}TClassicStringDynArray{$ELSE}TArray<string>{$ENDIF};
  const AGrantResults: {$IF CompilerVersion >= 35.0}TClassicPermissionStatusDynArray{$ELSE}TArray<TPermissionStatus>{$ENDIF}
);
begin
  // 2 permissions involved: CAMERA, READ_EXTERNAL_STORAGE, WRITE_EXTERNAL_STORAGE
  if (Length(AGrantResults) = 2) and
    (AGrantResults[0] = TPermissionStatus.Granted) and
    (AGrantResults[1] = TPermissionStatus.Granted) then
    PdfFunction
  else
    TDialogService.ShowMessage('Rquired permissions are not granted');
end;

end.
