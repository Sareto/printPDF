unit uPDFPrint;

/// <author>Mauricio Sareto</author>
/// <e-mail>mauricio_sareto@hotmail.com</e-mail>

///  Esta unit tem por finalidade gerar relatorios para FMX Mobile, ela por ser
///  editada e alterada, nao compartilhe esse arquivo sem a autorizaçao do autor.
///  O autor se reserva ao direito de receber todos os creditos pela sua criação.

interface

uses
  {$IFDEF ANDROID}
  Androidapi.JNI.GraphicsContentViewText, Androidapi.JNI.JavaTypes,
  Androidapi.JNI.Net, Androidapi.Helpers, Androidapi.JNI.Os, Androidapi.JNI.Support,
  FMX.Helpers.android,
  {$ENDIF}
  System.UIConsts, System.IOUtils, FMX.Dialogs, System.SysUtils,
  FMX.Graphics, FMX.Surfaces, System.UITypes;

type
  TTipoFonte = (Normal, Negrito, Italico);
  TTipoDirecao = (tpLef, tpRight, tpCenter);

type
  TPDFPrint = class
  private
    FNomeArq    : string;
    FPagina     : integer;
    FFonteName  : String;
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
  public
    constructor Create(pNomeDocumentoPDF: String);
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
    procedure ImpVal(ALinha, AColuna: Integer; AMascara: String; AValor: Double;
                     ATipoFonte: TTipoFonte;
                     AColor: TAlphaColor;
                     ATamFonte: Integer);
    procedure ImpLinhaH(ALinha, AColuna, ATamanho: Integer; Color: TAlphaColor);
    procedure ImpLinhaV(ALinha, AColuna, ATamanho: Integer; Color: TAlphaColor);
    procedure ImpBox(ATop, ABottom, ALeft, ARight, ATamBorda: Integer;
                     AColor: TAlphaColor);
    procedure ImpImage(Image: TBitmap; ATop, ALeft: Single);
    procedure VisualizarPDF();
    procedure CompartilharPDF();
    procedure NovaPagina();
    procedure Abrir;
    Procedure Fechar;

    function FileNameToUri(const AFileName: string): {$IFDEF ANDROID}Jnet_Uri{$ELSE}string{$ENDIF};
    function MilimeterToPixel(const AMilimeter:double):double;

  published
    property BordaSupInf : double read FBordaSupInf write SetBordaSupInf;
    property BordaLefRig : double read FBordaLefRig write SetBordaLefRig;
  end;

	//Essas contantes vao definir o espaçamento entre as linha e entre cada palavra;
	//Por exemplo:
	//TamLinha é o espaçamento de uma linha para outra
	//TamColuna é o espaçamento entre cada letra
	//BordaSupInf é o tamanho da borda superior e da borda inferior
	//BordaLefRig é o tamanho das bordas laterais
//const
  //TamLinha    : Integer = 15;
  //TamColuna   : Integer = 7;

  //BordaSupInf : Integer = 25;
  //BordaLefRig : Integer = 15;

implementation

uses FMX.Types;

{ tPdfPrint }

constructor tPdfPrint.Create(pNomeDocumentoPDF: String);
var sArq : string;
begin
  {$IFDEF ANDROID}
  FDocument  := TJPdfDocument.JavaClass.init;
  FNomeArq   := pNomeDocumentoPDF;
  FPagina    := 0;
  FFonteName := 'Segoe UI';

  //Seta valores padrões na "Property" para a mesma acionar o Methodo de Atribuição
  //O usuario poderá fazer o mesmo por fora da Classe
  Self.BordaSupInf:= 6.5;
  Self.BordaLefRig:= 4.5;

  sArq:= TPath.Combine(TPath.GetSharedDocumentsPath, FNomeArq + '.pdf');
  if TFile.Exists(sArq) then TFile.Delete(sArq);
  {$ENDIF}
end;

destructor tPdfPrint.Destroy;
begin
  //Metodo destrutor da classe
end;


procedure tPdfPrint.Abrir;
begin
  NovaPagina;
end;

function tPdfPrint.FileNameToUri(const AFileName: string): {$IFDEF ANDROID}Jnet_Uri{$ELSE}string{$ENDIF};
{$IFDEF ANDROID}
var JavaFile: JFile;
{$ENDIF}
begin
  {$IFDEF ANDROID}
  JavaFile := TJFile.JavaClass.init(StringToJString(AFileName));
  Result := TJnet_Uri.JavaClass.fromFile(JavaFile);
  {$ENDIF}
end;

procedure tPdfPrint.CompartilharPDF;
{$IFDEF ANDROID}
Var
   IntentShare : JIntent;
   Uri         : Jnet_Uri;
   Uris        : JArrayList;
   AttFile     : JFile;
   Path        : String;
{$ENDIF}
Begin
  {$IFDEF ANDROID}
  IntentShare := TJIntent.JavaClass.init(TJIntent.JavaClass.ACTION_SEND);
  Uris        := TJArrayList.Create;
  Path:=TPath.Combine(TPath.GetSharedDocumentsPath, FNomeArq+'.pdf');
  AttFile := TJFile.JavaClass.init(StringToJString(Path));
  Uri     := TJnet_Uri.JavaClass.fromFile(AttFile);
  Uris.add(0,Uri);
  IntentShare.putExtra(TJIntent.JavaClass.EXTRA_TEXT, StringToJString(''));
  IntentShare.setType(StringToJString('Application/pdf'));
  IntentShare.putParcelableArrayListExtra(TJIntent.JavaClass.EXTRA_STREAM, Uris);
  TAndroidHelper.Activity.StartActivity(TJIntent.JavaClass.createChooser(IntentShare,StrToJCharSequence('Compartilhar com:')));
  {$ENDIF}
end;

procedure tPdfPrint.Fechar;
begin
  {$IFDEF ANDROID}
  FDocument.finishPage(FPage);
  GravarPDF;
  FDocument.close;
  {$ENDIF}
end;

procedure tPdfPrint.GravarPDF;
{$IFDEF ANDROID}
var sFileName: String;
    OutputStream: JFileOutputStream;
{$ENDIF}
begin
  {$IFDEF ANDROID}
  sFileName:= TPath.Combine(TPath.GetSharedDocumentsPath, FNomeArq + '.pdf');
  if TFile.Exists(sFileName) then TFile.Delete(sFileName);
  OutputStream:= TJFileOutputStream.JavaClass.init(StringToJString(sFileName));
  try
    FDocument.writeTo(OutputStream);
  finally
    OutputStream.close;
  end;
  {$ENDIF}
end;

procedure tPdfPrint.ImpBox(ATop, ABottom, ALeft, ARight, ATamBorda: Integer;
                           AColor: TAlphaColor);
{$IFDEF ANDROID}
var Rect: JRectF;
{$ENDIF}
begin
  {$IFDEF ANDROID}
  FPaint.setColor(AColor);
  FPaint.setStyle(TJPaint_Style.JavaClass.STROKE);
  FPaint.setStrokeWidth(ATamBorda);

  Rect       := TJRectF.Create;
  Rect.top   := MilimeterToPixel( ATop ) + FBordaSupInf ;
  Rect.bottom:= MilimeterToPixel( ABottom ) + FBordaSupInf;
  Rect.left  := MilimeterToPixel( ALeft ) + FBordaLefRig;
  Rect.right := MilimeterToPixel( ARight ) + FBordaLefRig;

  FCanvas.drawRect(Rect,FPaint);

  //CRS - Volta o Stylo para Fill para não afetar os demais obejtos a serem inseridos
  FPaint.setStyle(TJPaint_Style.JavaClass.FILL);
  {$ENDIF}
end;

procedure tPdfPrint.ImpC(Linha, Coluna: Integer; Texto: String;
  TipoFonte: TTipoFonte; Color: TAlphaColor; TamFonte: Integer);
begin
  ImpTexto(Linha, coluna, Texto, TipoFonte, Color, TamFonte, tpCenter);
end;

procedure tPdfPrint.ImpImage(Image: TBitmap; ATop, ALeft: Single);
{$IFDEF ANDROID}
var NativeBitmap: JBitmap;
    sBitMap: TBitmapSurface;
{$ENDIF}
begin
  {$IFDEF ANDROID}
  NativeBitmap:= TJBitmap.JavaClass.createBitmap(Image.Width,
                                                 Image.Height,
                                                 TJBitmap_Config.JavaClass.ARGB_8888);
  sBitMap:= TBitmapSurface.create;
  sBitMap.Assign(Image);
  SurfaceToJBitmap(sBitMap, NativeBitmap);

  FCanvas.drawBitmap(NativeBitmap,
                     MilimeterToPixel(ALeft),
                     MilimeterToPixel(ATop),
                     FPaint);
  {$ENDIF}
end;

procedure tPdfPrint.ImpL(Linha, Coluna: Integer; Texto: String;
  TipoFonte: TTipoFonte; Color: TAlphaColor; TamFonte: Integer);
begin
  ImpTexto(Linha, coluna, Texto, TipoFonte, Color, TamFonte, tpLef);
end;

procedure tPdfPrint.ImpLinhaH(ALinha, AColuna, ATamanho: Integer; Color: TAlphaColor);
var AColor: TAlphaColorRec;
begin
  AColor:= TAlphaColorRec(Color);
  {$IFDEF ANDROID}
  FPaint.setARGB(AColor.A, AColor.R, AColor.G, AColor.B);
  FPaint.setStrokeWidth(1);
  FCanvas.drawLine(MilimeterToPixel(AColuna) + FBordaLefRig,            //(Coluna*TamColuna)+BordaLefRig,
                   MilimeterToPixel(ALinha) + FBordaSupInf,             //(Linha*TamLinha)+BordaSupInf,
                   MilimeterToPixel(AColuna + ATamanho) + FBordaLefRig, //Tamanho*TamColuna,
                   MilimeterToPixel(ALinha) + FBordaSupInf,             //(Linha*TamLinha)+BordaSupInf,
                   FPaint);
  {$ENDIF}
end;

procedure tPdfPrint.ImpLinhaV(ALinha, AColuna, ATamanho: Integer; Color: TAlphaColor);
var AColor: TAlphaColorRec;
begin
  AColor:= TAlphaColorRec(Color);
  {$IFDEF ANDROID}
  FPaint.setARGB(AColor.A, AColor.R, AColor.G, AColor.B);
  FPaint.setStrokeWidth(1);
  FCanvas.drawLine(MilimeterToPixel(AColuna) + FBordaLefRig,          //(Coluna*TamColuna)+BordaLefRig,
                   MilimeterToPixel(ALinha) + FBordaSupInf,           //(Linha*TamLinha)+BordaSupInf,
                   MilimeterToPixel(AColuna) + FBordaLefRig,          //(Coluna*TamColuna)+BordaLefRig,
                   MilimeterToPixel(ALinha + ATamanho) + FBordaSupInf,//Tamanho*TamLinha,
                   FPaint);
  {$ENDIF}
end;

procedure tPdfPrint.ImpR(Linha, Coluna: Integer; Texto: String;
  TipoFonte: TTipoFonte; Color: TAlphaColor; TamFonte: Integer);
begin
  ImpTexto(Linha, coluna, Texto, TipoFonte, Color, TamFonte, tpRight);
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
procedure tPdfPrint.ImpTexto(ALinha, AColuna: Integer; ATexto: String;
                             ATipoFonte: TTipoFonte;
                             AColor: TAlphaColor;
                             ATamFonte: Integer;
                             ATpDirecao: TTipoDirecao);
var iColor: TAlphaColorRec;
begin
  iColor:= TAlphaColorRec(AColor);
  {$IFDEF ANDROID}
  FPaint.setARGB(iColor.A, iColor.R, iColor.G, iColor.B);

  case ATpDirecao of
    tpLef     : Fpaint.setTextAlign(TJPaint_Align.JavaClass.LEFT);
    tpRight   : Fpaint.setTextAlign(TJPaint_Align.JavaClass.RIGHT);
    tpCenter  : Fpaint.setTextAlign(TJPaint_Align.JavaClass.Center);
  end;

  Fpaint.setTextSize(ATamFonte);

  case ATipoFonte of
    Negrito: FPaint.setTypeface(TJTypeface.JavaClass.create(StringToJString(FFonteName),TJTypeface.JavaClass.BOLD));
    Italico: FPaint.setTypeface(TJTypeface.JavaClass.create(StringToJString(FFonteName),TJTypeface.JavaClass.ITALIC));
    Normal: FPaint.setTypeface(TJTypeface.JavaClass.create(StringToJString(FFonteName),TJTypeface.JavaClass.NORMAL));
  end;

  FCanvas.drawText(StringToJString(ATexto),
                   MilimeterToPixel(AColuna) + FBordaLefRig, //original -->    (Coluna*TamColuna)+BordaLefRig,
                   MilimeterToPixel(ALinha) + FBordaSupInf,  //original -->    (Linha*TamLinha)+BordaSupInf,
                   FPaint);
  {$ENDIF}
end;

procedure tPdfPrint.ImpVal(ALinha, AColuna: Integer; AMascara: String;
                           AValor: Double;
                           ATipoFonte: TTipoFonte;
                           AColor: TAlphaColor;
                           ATamFonte: Integer);
//var iColor: TAlphaColorRec;
begin
  (*
  iColor := TAlphaColorRec(AColor);

  FPaint.setARGB(iColor.A, iColor.R, iColor.G, iColor.B);
  Fpaint.setTextAlign(TJPaint_Align.JavaClass.RIGHT);
  Fpaint.setTextSize(ATamFonte);

  case ATipoFonte of
    Negrito: FPaint.setTypeface(TJTypeface.JavaClass.create(StringToJString(FFonteName),TJTypeface.JavaClass.BOLD));
    Italico: FPaint.setTypeface(TJTypeface.JavaClass.create(StringToJString(FFonteName),TJTypeface.JavaClass.ITALIC));
    Normal: FPaint.setTypeface(TJTypeface.JavaClass.create(StringToJString(FFonteName),TJTypeface.JavaClass.NORMAL));
  end;

  FCanvas.drawText(StringToJString(FormatFloat(AMascara, AValor)),
                   (AColuna*TamColuna)+BordaLefRig,
                   (ALinha*TamLinha)+BordaSupInf,
                   FPaint);
  *)

  Self.ImpTexto(ALinha,
                AColuna,
                formatFloat(AMascara,AValor),
                ATipoFonte,
                AColor,
                ATamFonte,
                tpRight);
end;

procedure tPdfPrint.NovaPagina;
begin
  Inc(FPagina);
  {$IFDEF ANDROID}
  if (FPagina > 1) then FDocument.finishPage(FPage);

	//Define o tamanho da pagina Largura x comprimento, altere esses valores para criar um documento maior ou menor
	//Voce pode definir uma variavel publica que guarda o tamanho, para personalizar a cada impressao
  //https://www.tamanhosdepapel.com/a-tamanhos-em-pixels.htm
  FPageInfo:= TJPageInfo_Builder.JavaClass.init(595, 842, FPagina).create;
  FPage    := FDocument.startPage(FPageInfo);
  FCanvas  := FPage.getCanvas;
  FPaint   := TJPaint.JavaClass.init;
  {$ENDIF}
end;

procedure tPdfPrint.VisualizarPDF();
{$IFDEF ANDROID}
var Intent    : JIntent;
    sArq      : string;
    //Uri       : Jnet_Uri;
    LAutority : JString;
{$ENDIF}
begin
  {$IFDEF ANDROID}
  sArq:= TPath.Combine(TPath.GetSharedDocumentsPath, FNomeArq + '.pdf');
  if TFile.Exists(sArq) then begin

    if (StrToInt(Copy(trim(JStringToString(TJBuild_VERSION.JavaClass.RELEASE)),0,2)) >= 8) then
    begin
      LAutority:= StringToJString(
                    JStringToString(
                      TAndroidHelper.Context.getApplicationContext.getPackageName
                                   ) + '.fileprovider');

      //Uri:= TJFileProvider.JavaClass.getUriForFile(TAndroidHelper.Context,
      //                                             LAutority,
      //                                             TJFile.JavaClass.init(StringToJString(Path)));

      intent:= TJIntent.JavaClass.init(TJIntent.JavaClass.ACTION_VIEW);
      intent.setDataAndType(FilenameToURI(sArq),
                            StringToJString('application/pdf'));
      Intent.setFlags(TJIntent.JavaClass.FLAG_GRANT_READ_URI_PERMISSION);
      TAndroidHelper.Activity.startActivity(Intent);
    end
    else
      OpenPDF(FNomeArq + '.pdf');
  end
  else
    raise Exception.Create('Nenhum arquivo ou diretório encontrado');
  {$ENDIF}
end;

procedure tPdfPrint.OpenPDF(const APDFFileName: string; AExternalURL: Boolean);
{$IFDEF ANDROID}
var
  Intent         : JIntent;
  Filepath       : String;
  SharedFilePath : string;
  tmpFile        : String;
{$ENDIF}
begin
  {$IFDEF ANDROID}
  if not AExternalURL then begin
    Filepath      := TPath.Combine(TPath.GetDocumentsPath      , APDFFileName);
    SharedFilePath:= TPath.Combine(TPath.GetSharedDocumentsPath, APDFFileName);
    if TFile.Exists(SharedFilePath) then TFile.Delete(SharedFilePath);
    TFile.Copy(Filepath, SharedFilePath);
  end;

  Intent := TJIntent.Create;
  Intent.setAction(TJIntent.JavaClass.ACTION_VIEW);
  tmpFile := StringReplace(APDFFileName, ' ', '%20', [rfReplaceAll]);
  if AExternalURL then
    Intent.setData(StrToJURI(tmpFile))
  else
    Intent.setDataAndType(StrToJURI('file://' + SharedFilePath), StringToJString('application/pdf'));

  SharedActivity.startActivity(Intent);
  {$ENDIF}
end;

procedure TPDFPrint.SetBordaLefRig(const Value: double);
begin
  FBordaLefRig:= MilimeterToPixel(Value);
end;

procedure TPDFPrint.SetBordaSupInf(const Value: double);
begin
  FBordaSupInf:= MilimeterToPixel(Value);
end;

function tPdfPrint.MilimeterToPixel(const AMilimeter:double):double;
begin
  result:= (TDeviceDisplayMetrics.Default.PixelsPerInch / 25.4) * AMilimeter;
end;

end.
