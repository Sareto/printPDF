unit uPdfPrint;

/// <author>Mauricio Sareto</author>
/// <e-mail>mauricio_sareto@hotmail.com</e-mail>

///  Esta unit tem por finalidade gerar relatorios para FMX Mobile, ela por ser
///  editada e alterada, nao compartilhe esse arquivo sem a autorizaçao do autor.
///  O autor se reserva ao direito de receber todos os creditos pela sua criação.

interface

Uses
  Androidapi.JNI.GraphicsContentViewText, Androidapi.JNI.JavaTypes,
  Androidapi.JNI.Net, Androidapi.Helpers, FMX.Helpers.android, System.UITypes,
  System.UIConsts, System.IOUtils, FMX.Dialogs, System.SysUtils,
  Androidapi.JNI.Os;

type
  TTipoFonte = (Normal, Negrito, Italico);
  TTipoDirecao = (tpLef, tpRight, tpCenter);

type
  tPdfPrint = class
  private
    FNomeArq: String;
    FPagina: Integer;
    FFonteName: String;
    FDocument: JPdfDocument;
    FPageInfo: JPdfDocument_PageInfo;
    FPage: JPdfDocument_Page;
    FCanvas: JCanvas;
    FPaint: JPaint;
    Procedure GravarPDF();
    Procedure ImpTexto(Linha, Coluna: Integer; Texto: String; TipoFonte: TTipoFonte;
      Color: TAlphaColor; TamFonte: Integer; TpDirecao: TTipoDirecao);
    procedure OpenPDF(const APDFFileName: string; AExternalURL: Boolean = False);
  public
    property NomeArq: String read FNomeArq write FNomeArq;
    property Pagina: Integer read FPagina write FPagina;
    property FonteName: String read FFonteName write FFonteName;
    constructor Create(pNomeDocumentoPDF: String);
    destructor Destroy;
    procedure ImpL(Linha, Coluna: Integer; Texto: String; TipoFonte: TTipoFonte;
      Color: TAlphaColor; TamFonte: Integer);
    procedure ImpR(Linha, Coluna: Integer; Texto: String; TipoFonte: TTipoFonte;
      Color: TAlphaColor; TamFonte: Integer);
    procedure ImpC(Linha, Coluna: Integer; Texto: String; TipoFonte: TTipoFonte;
      Color: TAlphaColor; TamFonte: Integer);
    procedure ImpVal(Linha, Coluna: Integer; Mascara: String; Valor: Double;
      TipoFonte: TTipoFonte; Color: TAlphaColor; TamFonte: Integer);
    procedure ImpLinhaH(Linha, Coluna, Tamanho: Integer; Color: TAlphaColor);
    procedure ImpLinhaV(Linha, Coluna, Tamanho: Integer; Color: TAlphaColor);
    procedure ImpBox(Top, Bottom, Left, Right, TamBorda: Integer;
      Color: TAlphaColor);
    procedure VisualizarPDF();
    procedure CompartilharPDF();
    procedure NovaPagina();
    procedure Abrir;
    Procedure Fechar;
  end;

	//Essas contantes vao definir o espaçamento entre as linha e entre cada palavra;
	//Por exemplo:
	//TamLinha é o espaçamento de uma linha para outra
	//TamColuna é o espaçamento entre cada letra
	//BordaSupInf é o tamanho da borda superior e da borda inferior
	//BordaLefRig é o tamanho das bordas laterais
const
  TamLinha    : Integer = 15;
  TamColuna   : Integer = 7;
  BordaSupInf : Integer = 25;
  BordaLefRig : Integer = 15;

implementation

{ tPdfPrint }

procedure tPdfPrint.Abrir;
begin
  NovaPagina;
end;

function FileNameToUri(const FileName: string): Jnet_Uri;
var
  JavaFile: JFile;
begin
  JavaFile := TJFile.JavaClass.init(StringToJString(FileName));
  Result := TJnet_Uri.JavaClass.fromFile(JavaFile);
end;
procedure tPdfPrint.CompartilharPDF;
Var
   IntentShare : JIntent;
   Uri         : Jnet_Uri;
   Uris        : JArrayList;
   AttFile     : JFile;
   Path        : String;
Begin
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
end;

constructor tPdfPrint.Create(pNomeDocumentoPDF: String);
begin
  FDocument  := TJPdfDocument.JavaClass.init;
  FNomeArq   := pNomeDocumentoPDF;
  FPagina    := 0;
  FFonteName := 'Segoe UI';
end;

destructor tPdfPrint.Destroy;
begin
  //Metodo destrutor da classe
end;

procedure tPdfPrint.Fechar;
begin
  FDocument.finishPage(FPage);
  GravarPDF;
  FDocument.close;
end;

procedure tPdfPrint.GravarPDF;
var
  FileName: String;
  OutputStream: JFileOutputStream;
begin
  FileName := TPath.Combine(TPath.GetSharedDocumentsPath, FNomeArq+'.pdf');
  if(TFile.Exists(FileName))Then
    TFile.Delete(FileName);
  OutputStream := TJFileOutputStream.JavaClass.init
    (StringToJString(FileName));
  try
    FDocument.writeTo(OutputStream);
  finally
    OutputStream.close;
  end;
end;

procedure tPdfPrint.ImpBox(Top, Bottom, Left, Right, TamBorda: Integer;
  Color: TAlphaColor);
var
  ARect: JRectF;
begin
  FPaint.setColor(Color);
  FPaint.setStyle(TJPaint_Style.JavaClass.STROKE);
  FPaint.setStrokeWidth(TamBorda);
  ARect := TJRectF.Create;
  ARect.top := Top;
  ARect.bottom := Bottom;
  ARect.left := Left;
  ARect.right := Right;
  FCanvas.drawRect(ARect,FPaint);
end;

procedure tPdfPrint.ImpC(Linha, Coluna: Integer; Texto: String;
  TipoFonte: TTipoFonte; Color: TAlphaColor; TamFonte: Integer);
begin
  ImpTexto(Linha, coluna, Texto, TipoFonte, Color, TamFonte, tpCenter);
end;

procedure tPdfPrint.ImpL(Linha, Coluna: Integer; Texto: String;
  TipoFonte: TTipoFonte; Color: TAlphaColor; TamFonte: Integer);
begin
  ImpTexto(Linha, coluna, Texto, TipoFonte, Color, TamFonte, tpLef);
end;

procedure tPdfPrint.ImpLinhaH(Linha, Coluna, Tamanho: Integer; Color: TAlphaColor);
var
  AColor: TAlphaColorRec;
begin
  AColor := TAlphaColorRec(Color);
  FPaint.setARGB(AColor.A, AColor.R, AColor.G, AColor.B);
  FPaint.setStrokeWidth(1);
  FCanvas.drawLine((Coluna*TamColuna)+BordaLefRig, (Linha*TamLinha)+BordaSupInf, Tamanho*TamColuna, (Linha*TamLinha)+BordaSupInf, FPaint);
end;

procedure tPdfPrint.ImpLinhaV(Linha, Coluna, Tamanho: Integer; Color: TAlphaColor);
var
  AColor: TAlphaColorRec;
begin
  AColor := TAlphaColorRec(Color);
  FPaint.setARGB(AColor.A, AColor.R, AColor.G, AColor.B);
  FPaint.setStrokeWidth(1);
  FCanvas.drawLine((Coluna*TamColuna)+BordaLefRig, (Linha*TamLinha)+BordaSupInf, (Coluna*TamColuna)+BordaLefRig, Tamanho*TamLinha, FPaint);
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
procedure tPdfPrint.ImpTexto(Linha, Coluna: Integer; Texto: String;
  TipoFonte: TTipoFonte; Color: TAlphaColor; TamFonte: Integer;
  TpDirecao: TTipoDirecao);
var
  AColor: TAlphaColorRec;
begin
  AColor := TAlphaColorRec(Color);
  FPaint.setARGB(AColor.A, AColor.R, AColor.G, AColor.B);
  case TpDirecao of
    tpLef     : Fpaint.setTextAlign(TJPaint_Align.JavaClass.LEFT);
    tpRight   : Fpaint.setTextAlign(TJPaint_Align.JavaClass.RIGHT);
    tpCenter  : Fpaint.setTextAlign(TJPaint_Align.JavaClass.Center);
  end;
  Fpaint.setTextSize(TamFonte);
  case TipoFonte of
    Negrito: FPaint.setTypeface(TJTypeface.JavaClass.create(StringToJString(FFonteName),TJTypeface.JavaClass.BOLD));
    Italico: FPaint.setTypeface(TJTypeface.JavaClass.create(StringToJString(FFonteName),TJTypeface.JavaClass.ITALIC));
    Normal: FPaint.setTypeface(TJTypeface.JavaClass.create(StringToJString(FFonteName),TJTypeface.JavaClass.NORMAL));
  end;
  FCanvas.drawText(StringToJString(Texto),(Coluna*TamColuna)+BordaLefRig,(Linha*TamLinha)+BordaSupInf,FPaint);
end;

procedure tPdfPrint.ImpVal(Linha, Coluna: Integer; Mascara: String; Valor: Double;
  TipoFonte: TTipoFonte; Color: TAlphaColor; TamFonte: Integer);
var
  AColor: TAlphaColorRec;
begin
  AColor := TAlphaColorRec(Color);
  FPaint.setARGB(AColor.A, AColor.R, AColor.G, AColor.B);
  Fpaint.setTextAlign(TJPaint_Align.JavaClass.RIGHT);
  Fpaint.setTextSize(TamFonte);
  case TipoFonte of
    Negrito: FPaint.setTypeface(TJTypeface.JavaClass.create(StringToJString(FFonteName),TJTypeface.JavaClass.BOLD));
    Italico: FPaint.setTypeface(TJTypeface.JavaClass.create(StringToJString(FFonteName),TJTypeface.JavaClass.ITALIC));
    Normal: FPaint.setTypeface(TJTypeface.JavaClass.create(StringToJString(FFonteName),TJTypeface.JavaClass.NORMAL));
  end;
  FCanvas.drawText(StringToJString(FormatFloat(Mascara, Valor)),(Coluna*TamColuna)+BordaLefRig,(Linha*TamLinha)+BordaSupInf,FPaint);
end;

procedure tPdfPrint.NovaPagina;
begin
  Inc(FPagina);
  if(FPagina > 1)Then
    FDocument.finishPage(FPage);
	//Define o tamanho da pagina Largura x comprimento, altere esses valores para criar um documento maior ou menor
	//Voce pode definir uma variavel publica que guarda o tamanho, para personalizar a cada impressao
  FPageInfo := TJPageInfo_Builder.JavaClass.init(595, 842, FPagina).create;
  FPage     := FDocument.startPage(FPageInfo);
  FCanvas   := FPage.getCanvas;
  FPaint    := TJPaint.JavaClass.init;
end;


procedure tPdfPrint.VisualizarPDF();
var
  Intent  : JIntent;
  Uri     : Jnet_Uri;
  Path   : string;
begin
  if(TFile.Exists(TPath.Combine(TPath.GetSharedDocumentsPath, FNomeArq+'.pdf')))Then
  begin
    Path:=TPath.Combine(TPath.GetSharedDocumentsPath, FNomeArq+'.pdf');
    if(StrToInt(Copy(trim(JStringToString(TJBuild_VERSION.JavaClass.RELEASE)),0,2)) > 5) then
    begin
      intent := TJIntent.Create;
      intent.setAction(TJIntent.JavaClass.ACTION_VIEW);
      URI := StrToJURI('content://' +Path);
      intent.setDataAndType(URI,StringToJString('application/pdf'));
      Intent.setFlags(TJIntent.JavaClass.FLAG_GRANT_PERSISTABLE_URI_PERMISSION);
      TAndroidHelper.Activity.startActivity(Intent);
    end
    else
      OpenPDF(FNomeArq+'.pdf');
  end
  else
    raise Exception.Create('Nenhum arquivo ou diretório encontrado');
end;


procedure tPdfPrint.OpenPDF(const APDFFileName: string; AExternalURL: Boolean);
var
  Intent         : JIntent;
  Filepath       : String;
  SharedFilePath : string;
  tmpFile        : String;
begin
  if not AExternalURL then
  begin
    Filepath       := TPath.Combine(TPath.GetDocumentsPath      , APDFFileName);
    SharedFilePath := TPath.Combine(TPath.GetSharedDocumentsPath, APDFFileName);
    if TFile.Exists(SharedFilePath) then
      TFile.Delete(SharedFilePath);
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
end;


end.
