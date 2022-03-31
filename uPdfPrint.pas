unit uPDFPrint;

/// <author>Mauricio Sareto</author>
/// <e-mail>mauricio_sareto@hotmail.com</e-mail>
///
/// Contribua com o desenvolvimento da classe. Use a chave pix acima para contribuir.

/// Esta unit tem por finalidade gerar relatorios para FMX Mobile, ela por ser
/// editada e alterada, nao compartilhe esse arquivo sem a autorizaçao do autor.
/// O autor se reserva ao direito de receber todos os creditos pela sua criação.

interface

uses
{$IFDEF ANDROID}
  IdUri,
  FMX.Platform.Android,
  FMX.Helpers.Android,
{$IF CompilerVersion >= 34.0}Androidapi.JNI.Support, {$ENDIF}
  Androidapi.JNI.GraphicsContentViewText,
  Androidapi.JNI.JavaTypes,
  Androidapi.JNI.Net,
  Androidapi.Helpers,
  Androidapi.JNI.Os,
  Androidapi.JNI.provider,
  Androidapi.JNI.App,
  Androidapi.JNIBridge,
{$ENDIF}
  System.UIConsts, System.IOUtils, FMX.Dialogs, System.SysUtils,
  FMX.Graphics, FMX.Surfaces, System.UITypes;

type
  TTipoFonte = (Normal, Negrito, Italico);
  TTipoDirecao = (tpLef, tpRight, tpCenter);

type
{$IF CompilerVersion <= 33.0} // Delphi 10.3 or lesser
  JFileProvider = interface;

  JFileProviderClass = interface(JContentProviderClass)
    ['{33A87969-5731-4791-90F6-3AD22F2BB822}']
    { class } function getUriForFile(context: JContext; authority: JString; _file: JFile): Jnet_Uri; cdecl;
    { class } function init: JFileProvider; cdecl;
  end;

  [JavaSignature('android/support/v4/content/FileProvider')]
  JFileProvider = interface(JContentProvider)
    ['{12F5DD38-A3CE-4D2E-9F68-24933C9D221B}']
    procedure attachInfo(context: JContext; info: JProviderInfo); cdecl;
    function delete(uri: Jnet_Uri; selection: JString; selectionArgs: TJavaObjectArray<JString>): Integer; cdecl;
    function getType(uri: Jnet_Uri): JString; cdecl;
    function insert(uri: Jnet_Uri; values: JContentValues): Jnet_Uri; cdecl;
    function onCreate: Boolean; cdecl;
    function openFile(uri: Jnet_Uri; mode: JString): JParcelFileDescriptor; cdecl;
    function query(uri: Jnet_Uri; projection: TJavaObjectArray<JString>; selection: JString; selectionArgs: TJavaObjectArray<JString>;
      sortOrder: JString): JCursor; cdecl;
    function update(uri: Jnet_Uri; values: JContentValues; selection: JString; selectionArgs: TJavaObjectArray<JString>): Integer; cdecl;
  end;

  TJFileProvider = class(TJavaGenericImport<JFileProviderClass, JFileProvider>)
  end;
{$ENDIF}

  TPDFPrint = class
  private
    FNomeArq: string;
    FPagina: Integer;
    FFonteName: String;
    FBordaSupInf: double;
    FBordaLefRig: double;

{$IFDEF ANDROID}
    FDocument: JPdfDocument;
    FPageInfo: JPdfDocument_PageInfo;
    FPage: JPdfDocument_Page;
    FCanvas: JCanvas;
    FPaint: JPaint;
{$ENDIF}
    Procedure GravarPDF();
    Procedure ImpTexto(ALinha, AColuna: Integer; ATexto: String;
      ATipoFonte: TTipoFonte;
      AColor: TAlphaColor;
      ATamFonte: Integer;
      ATpDirecao: TTipoDirecao);
    procedure OpenPDF(const APDFFileName: string; AExternalURL: Boolean = False);
    procedure SetBordaSupInf(const Value: double);
    procedure SetBordaLefRig(const Value: double);
    function GetFileUri(aFile: String): Jnet_Uri;
  public
    constructor Create(pDocumentName: String);
    destructor Destroy;

    property NomeArq: String read FNomeArq write FNomeArq;
    property Pagina: Integer read FPagina write FPagina;
    property FonteName: String read FFonteName write FFonteName;

    procedure ImpL(Linha, Coluna: Integer; Texto: String; TipoFonte: TTipoFonte;
      Color: TAlphaColor; TamFonte: Integer);
    procedure ImpR(Linha, Coluna: Integer; Texto: String; TipoFonte: TTipoFonte;
      Color: TAlphaColor; TamFonte: Integer);
    procedure ImpC(Linha, Coluna: Integer; Texto: String; TipoFonte: TTipoFonte;
      Color: TAlphaColor; TamFonte: Integer);
    procedure ImpVal(ALinha, AColuna: Integer; AMascara: String; AValor: double;
      ATipoFonte: TTipoFonte;
      AColor: TAlphaColor;
      ATamFonte: Integer);
    procedure ImpLinhaH(ALinha, AColuna, ATamanho: Integer; Color: TAlphaColor);
    procedure ImpLinhaV(ALinha, AColuna, ATamanho: Integer; Color: TAlphaColor);
    procedure ImpBox(ATop, ABottom, ALeft, ARight, ATamBorda: Integer;
      AColor: TAlphaColor);
    procedure ImpImage(Image: TBitmap; ATop, ALeft: Single);

    procedure VisualizarPDF; deprecated 'Use Preview instead';
    procedure Preview;

    procedure CompartilharPDF; deprecated 'Use Share instead';
    procedure Share;

    procedure NovaPagina; deprecated 'Use NewPage instead';
    procedure NewPage;

    procedure Abrir; deprecated 'Use Open instead';
    procedure Open;

    procedure Fechar; deprecated 'Use Close instead';
    procedure Close;

    function FileNameToUri(const AFileName: string): {$IFDEF ANDROID}Jnet_Uri{$ELSE}string{$ENDIF};
    function MilimeterToPixel(const AMilimeter: double): double;

  published
    property BordaSupInf: double read FBordaSupInf write SetBordaSupInf;
    property BordaLefRig: double read FBordaLefRig write SetBordaLefRig;
  end;

  // Essas contantes vao definir o espaçamento entre as linha e entre cada palavra;
  // Por exemplo:
  // TamLinha é o espaçamento de uma linha para outra
  // TamColuna é o espaçamento entre cada letra
  // BordaSupInf é o tamanho da borda superior e da borda inferior
  // BordaLefRig é o tamanho das bordas laterais
  // const
  // TamLinha    : Integer = 15;
  // TamColuna   : Integer = 7;

  // BordaSupInf : Integer = 25;
  // BordaLefRig : Integer = 15;

implementation

uses FMX.Types;

{ tPdfPrint }

constructor TPDFPrint.Create(pDocumentName: String);
var
  sArq: string;
begin
{$IFDEF ANDROID}
  FDocument := TJPdfDocument.JavaClass.init;
  FNomeArq := pDocumentName;
  FPagina := 0;
  FFonteName := 'Segoe UI';

  // Seta valores padrões na "Property" para a mesma acionar o Methodo de Atribuição
  // O usuario poderá fazer o mesmo por fora da Classe
  Self.BordaSupInf := 6.5;
  Self.BordaLefRig := 4.5;

  sArq := TPath.Combine(TPath.GetPublicPath, FNomeArq + '.pdf');
  if TFile.Exists(sArq) then
    TFile.delete(sArq);
{$ENDIF}
end;

destructor TPDFPrint.Destroy;
begin
  // Metodo destrutor da classe
end;

procedure TPDFPrint.Abrir;
begin
  Open;
end;

function TPDFPrint.FileNameToUri(const AFileName: string): {$IFDEF ANDROID}Jnet_Uri{$ELSE}string{$ENDIF};
{$IFDEF ANDROID}
var
  JavaFile: JFile;
{$ENDIF}
begin
{$IFDEF ANDROID}
  JavaFile := TJFile.JavaClass.init(StringToJString(AFileName));
  Result := TJnet_Uri.JavaClass.fromFile(JavaFile);
{$ENDIF}
end;

procedure TPDFPrint.Close;
begin
{$IFDEF ANDROID}
  FDocument.finishPage(FPage);
  GravarPDF;
  FDocument.Close;
{$ENDIF}
end;

procedure TPDFPrint.CompartilharPDF;
begin
  Share;
end;

procedure TPDFPrint.Fechar;
begin
  Close;
end;

function TPDFPrint.GetFileUri(aFile: String): Jnet_Uri;
var
  LStrFileProvider: string;
begin
  try
    LStrFileProvider := JStringToString
      (TAndroidHelper.context.getApplicationContext.getPackageName) +
      '.fileprovider';
    Result := {$IF CompilerVersion >= 35.0}TJcontent_FileProvider{$ELSE}TJFileProvider{$ENDIF}.JavaClass.getUriForFile(
      TAndroidHelper.context,
      Androidapi.Helpers.StringToJString(LStrFileProvider),
      TJFile.JavaClass.init(StringToJString(aFile))
      );
  except
    on E: Exception do
      raise Exception.Create('uPDFPrint.TPDFPrint.GetFileUri ' + E.Message);
    {
      If something goes wrong here, the reason might be the Android version
      The Android7 or Lesser works with different stuff
    }
  end;
end;

procedure TPDFPrint.GravarPDF;
{$IFDEF ANDROID}
var
  sFileName: String;
  OutputStream: JFileOutputStream;
{$ENDIF}
begin
{$IFDEF ANDROID}
  sFileName := TPath.Combine(TPath.GetPublicPath, FNomeArq + '.pdf');
  if TFile.Exists(sFileName) then
    TFile.delete(sFileName);
  OutputStream := TJFileOutputStream.JavaClass.init(StringToJString(sFileName));
  try
    FDocument.writeTo(OutputStream);
  finally
    OutputStream.Close;
  end;
{$ENDIF}
end;

procedure TPDFPrint.ImpBox(ATop, ABottom, ALeft, ARight, ATamBorda: Integer;
  AColor: TAlphaColor);
{$IFDEF ANDROID}
var
  Rect: JRectF;
{$ENDIF}
begin
{$IFDEF ANDROID}
  FPaint.setColor(AColor);
  FPaint.setStyle(TJPaint_Style.JavaClass.STROKE);
  FPaint.setStrokeWidth(ATamBorda);

  Rect := TJRectF.Create;
  Rect.top := MilimeterToPixel(ATop) + FBordaSupInf;
  Rect.bottom := MilimeterToPixel(ABottom) + FBordaSupInf;
  Rect.left := MilimeterToPixel(ALeft) + FBordaLefRig;
  Rect.right := MilimeterToPixel(ARight) + FBordaLefRig;

  FCanvas.drawRect(Rect, FPaint);

  // CRS - Volta o Stylo para Fill para não afetar os demais obejtos a serem inseridos
  FPaint.setStyle(TJPaint_Style.JavaClass.FILL);
{$ENDIF}
end;

procedure TPDFPrint.ImpC(Linha, Coluna: Integer; Texto: String;
  TipoFonte: TTipoFonte; Color: TAlphaColor; TamFonte: Integer);
begin
  ImpTexto(Linha, Coluna, Texto, TipoFonte, Color, TamFonte, tpCenter);
end;

procedure TPDFPrint.ImpImage(Image: TBitmap; ATop, ALeft: Single);
{$IFDEF ANDROID}
var
  NativeBitmap: JBitmap;
  sBitMap: TBitmapSurface;
{$ENDIF}
begin
{$IFDEF ANDROID}
  NativeBitmap := TJBitmap.JavaClass.createBitmap(Image.Width,
    Image.Height,
    TJBitmap_Config.JavaClass.ARGB_8888);
  sBitMap := TBitmapSurface.Create;
  sBitMap.Assign(Image);
  SurfaceToJBitmap(sBitMap, NativeBitmap);

  FCanvas.drawBitmap(NativeBitmap,
    MilimeterToPixel(ALeft),
    MilimeterToPixel(ATop),
    FPaint);
{$ENDIF}
end;

procedure TPDFPrint.ImpL(Linha, Coluna: Integer; Texto: String;
  TipoFonte: TTipoFonte; Color: TAlphaColor; TamFonte: Integer);
begin
  ImpTexto(Linha, Coluna, Texto, TipoFonte, Color, TamFonte, tpLef);
end;

procedure TPDFPrint.ImpLinhaH(ALinha, AColuna, ATamanho: Integer; Color: TAlphaColor);
var
  AColor: TAlphaColorRec;
begin
  AColor := TAlphaColorRec(Color);
{$IFDEF ANDROID}
  FPaint.setARGB(AColor.A, AColor.R, AColor.G, AColor.B);
  FPaint.setStrokeWidth(1);
  FCanvas.drawLine(MilimeterToPixel(AColuna) + FBordaLefRig, // (Coluna*TamColuna)+BordaLefRig,
    MilimeterToPixel(ALinha) + FBordaSupInf, // (Linha*TamLinha)+BordaSupInf,
    MilimeterToPixel(AColuna + ATamanho) + FBordaLefRig, // Tamanho*TamColuna,
    MilimeterToPixel(ALinha) + FBordaSupInf, // (Linha*TamLinha)+BordaSupInf,
    FPaint);
{$ENDIF}
end;

procedure TPDFPrint.ImpLinhaV(ALinha, AColuna, ATamanho: Integer; Color: TAlphaColor);
var
  AColor: TAlphaColorRec;
begin
  AColor := TAlphaColorRec(Color);
{$IFDEF ANDROID}
  FPaint.setARGB(AColor.A, AColor.R, AColor.G, AColor.B);
  FPaint.setStrokeWidth(1);
  FCanvas.drawLine(MilimeterToPixel(AColuna) + FBordaLefRig, // (Coluna*TamColuna)+BordaLefRig,
    MilimeterToPixel(ALinha) + FBordaSupInf, // (Linha*TamLinha)+BordaSupInf,
    MilimeterToPixel(AColuna) + FBordaLefRig, // (Coluna*TamColuna)+BordaLefRig,
    MilimeterToPixel(ALinha + ATamanho) + FBordaSupInf, // Tamanho*TamLinha,
    FPaint);
{$ENDIF}
end;

procedure TPDFPrint.ImpR(Linha, Coluna: Integer; Texto: String;
  TipoFonte: TTipoFonte; Color: TAlphaColor; TamFonte: Integer);
begin
  ImpTexto(Linha, Coluna, Texto, TipoFonte, Color, TamFonte, tpRight);
end;

/// <summary>
/// Função responsável por imprimir o texto
/// </summary>
/// <param name="Linha">Informa qual linha o texto passado deverá ser impresso</param>
/// <param name="Coluna">Informa qual a coluna o texto passado deverá ser impresso</param>
/// <param name="Texto">Texto a ser impresso</param>
/// <param name="TipoFonte">Estilo que deve ser usado para impressao do texto</param>
/// <param name="Color">Cor da fonte a ser usada</param>
/// <param name="TamFonte">Tamanho da fonte a ser usada</param>
/// <param name="TpDirecao">Parametro para indicar a direçao que o texto deve seguir</param>
procedure TPDFPrint.ImpTexto(ALinha, AColuna: Integer; ATexto: String;
  ATipoFonte: TTipoFonte;
  AColor: TAlphaColor;
  ATamFonte: Integer;
  ATpDirecao: TTipoDirecao);
var
  iColor: TAlphaColorRec;
begin
  iColor := TAlphaColorRec(AColor);
{$IFDEF ANDROID}
  FPaint.setARGB(iColor.A, iColor.R, iColor.G, iColor.B);

  case ATpDirecao of
    tpLef:
      FPaint.setTextAlign(TJPaint_Align.JavaClass.left);
    tpRight:
      FPaint.setTextAlign(TJPaint_Align.JavaClass.right);
    tpCenter:
      FPaint.setTextAlign(TJPaint_Align.JavaClass.Center);
  end;

  FPaint.setTextSize(ATamFonte);

  case ATipoFonte of
    Negrito:
      FPaint.setTypeface(TJTypeface.JavaClass.Create(StringToJString(FFonteName), TJTypeface.JavaClass.BOLD));
    Italico:
      FPaint.setTypeface(TJTypeface.JavaClass.Create(StringToJString(FFonteName), TJTypeface.JavaClass.ITALIC));
    Normal:
      FPaint.setTypeface(TJTypeface.JavaClass.Create(StringToJString(FFonteName), TJTypeface.JavaClass.Normal));
  end;

  FCanvas.drawText(StringToJString(ATexto),
    MilimeterToPixel(AColuna) + FBordaLefRig, // original -->    (Coluna*TamColuna)+BordaLefRig,
    MilimeterToPixel(ALinha) + FBordaSupInf, // original -->    (Linha*TamLinha)+BordaSupInf,
    FPaint);
{$ENDIF}
end;

procedure TPDFPrint.ImpVal(ALinha, AColuna: Integer; AMascara: String;
  AValor: double;
  ATipoFonte: TTipoFonte;
  AColor: TAlphaColor;
  ATamFonte: Integer);
begin
  Self.ImpTexto(ALinha,
    AColuna,
    formatFloat(AMascara, AValor),
    ATipoFonte,
    AColor,
    ATamFonte,
    tpRight);
end;

procedure TPDFPrint.NewPage;
begin
  Inc(FPagina);
{$IFDEF ANDROID}
  if (FPagina > 1) then
    FDocument.finishPage(FPage);

  // Define o tamanho da pagina Largura x comprimento, altere esses valores para criar um documento maior ou menor
  // Voce pode definir uma variavel publica que guarda o tamanho, para personalizar a cada impressao
  // https://www.tamanhosdepapel.com/a-tamanhos-em-pixels.htm
  FPageInfo := TJPageInfo_Builder.JavaClass.init(595, 842, FPagina).Create;
  FPage := FDocument.startPage(FPageInfo);
  FCanvas := FPage.getCanvas;
  FPaint := TJPaint.JavaClass.init;
{$ENDIF}
end;

procedure TPDFPrint.NovaPagina;
begin
  NewPage;
end;

procedure TPDFPrint.VisualizarPDF;
begin
  Preview;
end;

procedure TPDFPrint.Open;
begin
  NewPage;
end;

procedure TPDFPrint.OpenPDF(const APDFFileName: string; AExternalURL: Boolean);
{$IFDEF ANDROID}
var
  Intent: JIntent;
  Filepath: String;
  SharedFilePath: string;
  tmpFile: String;
{$ENDIF}
begin
{$IFDEF ANDROID}
  if not AExternalURL then
  begin
    Filepath := TPath.Combine(TPath.GetDocumentsPath, APDFFileName);
    SharedFilePath := TPath.Combine(TPath.GetPublicPath, APDFFileName);
    if TFile.Exists(SharedFilePath) then
      TFile.delete(SharedFilePath);
    TFile.Copy(Filepath, SharedFilePath);
  end;

  Intent := TJIntent.Create;
  Intent.setAction(TJIntent.JavaClass.ACTION_VIEW);
  tmpFile := StringReplace(APDFFileName, ' ', '%20', [rfReplaceAll]);
  if AExternalURL then
    Intent.setData(StrToJURI(tmpFile))
  else
    Intent.setDataAndType(StrToJURI('file://' + SharedFilePath), StringToJString('application/pdf'));

  SharedActivity.StartActivity(Intent);
{$ENDIF}
end;

procedure TPDFPrint.Preview;
{$IFDEF ANDROID}
var
  Intent: JIntent;
  sArq: string;
  uri: Jnet_Uri;
  // LAutority : JString;
{$ENDIF}
begin
{$IFDEF ANDROID}
  sArq := TPath.Combine(TPath.GetPublicPath, FNomeArq + '.pdf');
  if TFile.Exists(sArq) then
  begin
    if ((TOSVersion.Major) >= 8) then
    begin
      Intent := TJIntent.JavaClass.init(TJIntent.JavaClass.ACTION_VIEW);
      uri := GetFileUri(sArq);
      Intent.setDataAndType(uri, StringToJString('application/pdf'));
      Intent.setFlags(TJIntent.JavaClass.FLAG_GRANT_READ_URI_PERMISSION);
      TAndroidHelper.Activity.StartActivity(Intent);
    end
    else
      OpenPDF(FNomeArq + '.pdf');
  end
  else
    raise Exception.Create('Nenhum arquivo ou diretório encontrado');
{$ENDIF}
end;

procedure TPDFPrint.SetBordaLefRig(const Value: double);
begin
  FBordaLefRig := MilimeterToPixel(Value);
end;

procedure TPDFPrint.SetBordaSupInf(const Value: double);
begin
  FBordaSupInf := MilimeterToPixel(Value);
end;

procedure TPDFPrint.Share;
{$IFDEF ANDROID}
Var
  IntentShare: JIntent;
  uri: Jnet_Uri;
  Uris: JArrayList;
  AttFile: JFile;
  Path: String;
{$ENDIF}
Begin
{$IFDEF ANDROID}
  IntentShare := TJIntent.JavaClass.init(TJIntent.JavaClass.ACTION_SEND);
  Uris := TJArrayList.Create;
  Path := TPath.Combine(TPath.GetPublicPath, FNomeArq + '.pdf');
  AttFile := TJFile.JavaClass.init(StringToJString(Path));
  uri := TJnet_Uri.JavaClass.fromFile(AttFile);
  Uris.add(0, uri);
  IntentShare.putExtra(TJIntent.JavaClass.EXTRA_TEXT, StringToJString(''));
  IntentShare.setType(StringToJString('Application/pdf'));
  IntentShare.putParcelableArrayListExtra(TJIntent.JavaClass.EXTRA_STREAM, Uris);
  TAndroidHelper.Activity.StartActivity(TJIntent.JavaClass.createChooser(IntentShare, StrToJCharSequence('Compartilhar com:')));
{$ENDIF}
end;

function TPDFPrint.MilimeterToPixel(const AMilimeter: double): double;
begin
  Result := (TDeviceDisplayMetrics.Default.PixelsPerInch / 25.4) * AMilimeter;
end;

end.
