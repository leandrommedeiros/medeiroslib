{===============================================================================

                           BIBLIOTECA - Utils

==========================================================| Vers�o 12.11.00 |==}

unit Lib.Utils;

interface

{ Bibliotecas para Interface }
uses
{ Para fun��o XlsToStringGrid }
  ComObj, Vcl.Grids,

{ Bibliotecas b�sicas }
  Vcl.Controls, Vcl.Dialogs, Classes, Vcl.StdCtrls, FMX.Forms, StrUtils, SysUtils, Vcl.ComCtrls,
  Types, Windows, Variants, Lib.StrUtils, Vcl.Forms;

{ Prot�tipos das Fun��es e Procedimentos }
  function  Mensagem(sMensagem: string; sTitulo: string = '';
    DialogType: TMsgDlgType = mtInformation; Buttons: TMsgDlgButtons = [mbOk];
    HelpContext: Integer = 0): TModalResult;
  function  InputBoxDate(const ACaption, AMessage: string; var AReturnDate: TDate;
    const AInitDate: TDate = 0): Boolean;
  function  FindAvaliableName(cOwner: TComponent; sPrefix: string): string;
  function  ValidateDecimal(S: string): Real;
  function  XlsToListBox(xListBox: TListBox; sFileName: string): Boolean;
  function  XlsToStringGrid(xStringGrid: TStringGrid; sFileName: string): Boolean;
  function  StringGridToXls(xStringGrid: TStringGrid; sSheetName,
    sFileName: string): Boolean;
  procedure AlignStrGrid(var xStringGrid: TStringGrid; iRowsHeight: Integer = 16);
  function  SecToMSec(Sec: integer): Integer;
  function  MinToMSec(Min: integer): Integer;
  function  MSecToMin(MSec: integer): Integer;
  function  ArrayToString(const AVector: array of Variant): string;

implementation

{==| Fun��o - Caixa de Mensagem em Portugu�s |==================================
    Instancia e exibe um modal de um MessageDialog comum mas com os bot�es em
  portugu�s.
  Par�metros de entrada:
    1. Mensagem a ser exibida > String
    2. T�tulo do di�logo      > String (Nome da aplica��o por padr�o)
    3. Tipo de mensagem       > TMsgDlgType (mtInformation por padr�o, aceita os
                                tipos mtWarning, mtError, mtConfirmation,
                                mtCustom)
    4. Bot�es do di�logo      > TMsgDlgButtons (mbOk por padr�o)
    5. �ndice na ajuda        > Integer (Zero por padr�o)
  Retorno:
    Bot�o clicado pelo usu�rio (TModalResult)
============================================| Leandro Medeiros (20/10/2011) |==}
function Mensagem(sMensagem: string; sTitulo: string = '';
  DialogType: TMsgDlgType = mtInformation; Buttons: TMsgDlgButtons = [mbOk];
  HelpContext: Integer = 0): TModalResult;
var
  MensagemD : TForm;
  idx       : Integer;
begin
  MensagemD         := CreateMessageDialog(sMensagem, DialogType, Buttons);     //Instancio um MessageDialog com a mensagem, o tipo de di�logo e os bot�es que entraram como par�metro
  MensagemD.Caption := ifthen(sTitulo <> '', sTitulo, Application.Title);       //Se o t�tulo estiver vazio coloco o nome da aplica��o na barra de t�tulo da mensagem

  With MensagemD Do                                                             //Com a mensagem
  begin
    For idx := 0 to ComponentCount - 1 do                                       //fa�o um loop do primeiro ao �ltimo componente
    begin
      if Components[idx] is TButton then                                        //Caso o componente seja um Bot�o
      begin
        with TButton(Components[idx]) do
        begin
          case ModalResult of                                                   //Modifico sua legenda de acordo com seu valor de retorno
            mrYes     : Caption := '&Sim';
            mrNo      : Caption := '&N�o';
            mrOK      : Caption := '&Ok';
            mrCancel  : Caption := '&Cancelar';
            mrAbort   : Caption := '&Abortar';
            mrRetry   : Caption := '&Repetir';
            mrIgnore  : Caption := '&Ignorar';
            mrAll     : Caption := '&Todos';
            mrNoToAll :
            begin
              Caption := 'N�o P/ Todos';
              Width   := 90;
            end;
            mrYesToAll :
            begin
              Caption := 'Sim P/ Todos';
              Width   := 90;
            end;
          end; //end case
        end; //end with
      end; //end if
    end; //end for
  end; //end with

  MensagemD.ShowModal;                                                          //Exibo o Di�logo

  Result := MensagemD.ModalResult;
  FreeAndNil(MensagemD);                                                        //Libero e esvazio a mem�ria outrora ocupada pelo Objeto
end;

{==| Fun��o - InputBoxData |====================================================
    Instancia e exibe um di�logo contendo um TDateTimePicker, um bot�o de
  cancelamento e um de confirma��o. Retorna a data escolhida pelo usu�rio.
  Par�metros de Entrada:
    1. T�tulo do di�logo   > string;
    2. Mensagem            > string;
    3. Vari�vel de Retorno > TDate
  Retorno: Sucesso(Boolean).
============================================| Leandro Medeiros (08/05/2012) |==}
function InputBoxDate(const ACaption, AMessage: string; var AReturnDate: TDate;
  const AInitDate: TDate = 0): Boolean;
var
  FrmBox       : TForm;
  LblMsg       : TLabel;
  DtPicker     : TDateTimePicker;
  DialogUnits  : TPoint;
  idx,
  ButtonTop,
  ButtonWidth,
  ButtonHeight : Integer;
  Buffer       : array[0..51] of Char;
begin
  Result := False;
  FrmBox := TForm.Create(Application);

  with FrmBox do
  try
    Canvas.Font := Font;

    for idx := 0 to 25 do Buffer[idx]      := Chr(idx + Ord('A'));
    for idx := 0 to 25 do Buffer[idx + 26] := Chr(idx + Ord('a'));

    GetTextExtentPoint(Canvas.Handle, Buffer, 52, TSize(DialogUnits));
    DialogUnits.X := DialogUnits.X div 52;
    BorderStyle   := bsDialog;
    Caption       := ACaption;
    ClientWidth   := MulDiv(180, DialogUnits.X, 4);
    ClientHeight  := MulDiv(63, DialogUnits.Y, 8);
    Position      := poScreenCenter;
    LblMsg        := TLabel.Create(FrmBox);

    with LblMsg do
    begin
      Parent   := FrmBox;
      AutoSize := True;
      Left     := MulDiv(8, DialogUnits.X, 4);
      Top      := MulDiv(8, DialogUnits.Y, 8);
      Caption  := AMessage;
    end;

    DtPicker := TDateTimePicker.Create(FrmBox);

    with DtPicker do
    begin
      Parent    := FrmBox;
      Left      := LblMsg.Left;
      Top       := MulDiv(19,  DialogUnits.Y, 8);
      Width     := MulDiv(164, DialogUnits.X, 4);
    end;

    if AInitDate = 0 then DtPicker.Date := Date
    else                  DtPicker.Date := AInitDate;

    ButtonTop    := MulDiv(41, DialogUnits.Y, 8);
    ButtonWidth  := MulDiv(50, DialogUnits.X, 4);
    ButtonHeight := MulDiv(14, DialogUnits.Y, 8);

    with TButton.Create(FrmBox) do
    begin
      Parent      := FrmBox;
      Caption     := '&OK';
      ModalResult := mrOk;
      Default     := True;
      SetBounds(MulDiv(38, DialogUnits.X, 4), ButtonTop, ButtonWidth, ButtonHeight);
    end;

    with TButton.Create(FrmBox) do
    begin
      Parent      := FrmBox;
      Caption     := '&Cancelar';
      ModalResult := mrCancel;
      Cancel      := True;
      SetBounds(MulDiv(92, DialogUnits.X, 4), ButtonTop, ButtonWidth, ButtonHeight);
    end;

    if ShowModal = mrOk then
    begin
      AReturnDate  := DtPicker.Date;
      Result       := True;
    end;
  finally
    FreeAndNil(FrmBox);
  end;
end;

{==| Fun��o - Encontra Nome Dispon�vel |========================================
    Varre um componente container em busca de um nome dispon�vel (utilizando o
  prefixo desejado) para que se crie um componente filho din�micamente.
============================================| Leandro Medeiros (01/07/2012) |==}
function FindAvaliableName(cOwner: TComponent; sPrefix: string): string;
var
  idx : integer;
begin
  idx := 1;
  While Assigned(cOwner.FindComponent(sPrefix + IntToStr(idx))) do
    Inc(idx);
  Result := sPrefix + IntToStr(idx);
end;

//==| Fun��o - Valida Decimal |=================================================
function ValidateDecimal(S: string): Real;
begin
  S[Pos('.', S)] := ',';                                                        //Procura pontos na string e os substitui por v�rgulas
  Result := StrToFloat(S);                                                      //depois retorna como n�mero de ponto flutuante
end;

{==| Fun��o - XLS Para ListBox |================================================
    Inicia uma inst�ncia do Microsoft Office Excel, carrega no mesmo um arquivo
  XLS e importa os dados para uma lista string.
  Par�metros de entrada:
    1. Lista de strings que receber� os dados > TListBox
    2. Nome do arquivo � ser lido             > String
  Retorno: Sucesso na leitura (Booleano)
============================================| Leandro Medeiros (17/11/2011) |==}
function XlsToListBox(xListBox: TListBox; sFileName: string): Boolean;
const
  xlCellTypeLastCell = $0000000B;
var
  XlsApplication,
  TabXls         : OLEVariant;
  RangeMatrix    : Variant;
  X, Y, iRow     : Integer;
begin
  Result         := False;                                                      //Assumo Falha
  XlsApplication := CreateOleObject('Excel.Application');                       //Crio uma inst�ncia do Excel

  try
    XlsApplication.Visible := False;                                            //N�o permito a exibi��o da aplica��o

    XlsApplication.Workbooks.Open(sFileName);                                   //Abro o arquivo que ser� importado
    TabXls := XlsApplication.Workbooks[ExtractFileName(sFileName)].WorkSheets[1]; //Mudo para a aba desejada

    TabXls.Cells.SpecialCells(xlCellTypeLastCell, EmptyParam).Activate;         //Posiciono o cursor na �ltima c�lula da planilha
    X := XlsApplication.ActiveCell.Row;                                         //Guardo a quantidade de linhas na vari�vel X
    Y := XlsApplication.ActiveCell.Column;                                      //e a quantidade de colunas na vari�vel Y

    RangeMatrix := XlsApplication.Range['A1', XlsApplication.Cells.Item[X, Y]].Value; //Associa a variant WorkSheet com a variant do Delphi

  //Monto um loop duplo para listar os registros no TStringGrid
    for iRow := 1 to X do                                                       //o segundo ir� da primeira � �ltima linha
      xListBox.Items.Add(Trim(RangeMatrix[iRow, 1]));                           //Copio a c�lula da planilha para o Grid

    RangeMatrix := Unassigned;                                                  //Limpo a Vari�vel
  finally                                                                       //Ao final sempre
    if not VarIsEmpty(XlsApplication) then                                      //verifico se a aplica��o (MS Excel) ainda est� instanciada
    begin                                                                       //e caso esteja
      XlsApplication.Quit;                                                      //a finalizo
      XlsApplication := Unassigned;                                             //Libero a mem�ria
      TabXls         := Unassigned;                                             //das vari�veis que utilizei para leitura
      Result         := True;                                                   //e retorno Verdadeiro
    end;
  end;
end;

{==| Fun��o - XLS Para Grid de Strings |========================================
    Inicia uma inst�ncia do Microsoft Office Excel, carrega no mesmo um arquivo
  XLS e importa os dados para uma lista string.
  Par�metros de entrada:
    1. Lista de strings que receber� os dados > TStringGrid
    2. Nome do arquivo � ser lido             > String
  Retorno: Sucesso na leitura (Booleano)
============================================| Leandro Medeiros (17/11/2011) |==}
function XlsToStringGrid(xStringGrid: TStringGrid; sFileName: string): Boolean;
const
  xlCellTypeLastCell = $0000000B;
var
  XlsApplication,
  TabXls           : OLEVariant;
  RangeMatrix      : Variant;
  X, Y, iCol, iRow : Integer;
begin
  Result         := False;                                                      //Assumo Falha
  XlsApplication := CreateOleObject('Excel.Application');                       //Crio uma inst�ncia do Excel

  try
    XlsApplication.Visible := False;                                            //N�o permito a exibi��o da aplica��o

    XlsApplication.Workbooks.Open(sFileName);                                   //Abro o arquivo que ser� importado
    TabXls := XlsApplication.Workbooks[ExtractFileName(sFileName)].WorkSheets[1]; //Mudo para a aba desejada

    TabXls.Cells.SpecialCells(xlCellTypeLastCell, EmptyParam).Activate;         //Posiciono o cursor na �ltima c�lula da planilha
    X := XlsApplication.ActiveCell.Row;                                         //Guardo a quantidade de linhas na vari�vel X
    Y := XlsApplication.ActiveCell.Column;                                      //e a quantidade de colunas na vari�vel Y

    xStringGrid.RowCount := X;                                                  //Agora utilizo os valores guardados para setar
    xStringGrid.ColCount := Y;                                                  //as dimens�es do Grid de Strings

    RangeMatrix := XlsApplication.Range['A1', XlsApplication.Cells.Item[X, Y]].Value; //Associa a variant WorkSheet com a variant do Delphi

  //Monto um loop duplo para listar os registros no TStringGrid
    for iCol := 1 to X do                                                       //o primeiro ir� da primeira � �ltima coluna
      for iRow := 1 to Y do                                                     //o segundo ir� da primeira � �ltima linha
        xStringGrid.Cells[(iRow - 1), (iCol - 1)] := Trim(RangeMatrix[iCol, iRow]); //Copio a c�lula da planilha para o Grid

    RangeMatrix := Unassigned;                                                  //Limpo a Vari�vel
  finally                                                                       //Ao final sempre
    if not VarIsEmpty(XlsApplication) then                                      //verifico se a aplica��o (MS Excel) ainda est� instanciada
    begin                                                                       //e caso esteja
      XlsApplication.Quit;                                                      //a finalizo
      XlsApplication := Unassigned;                                             //Libero a mem�ria
      TabXls         := Unassigned;                                             //das vari�veis que utilizei para leitura
      Result         := True;                                                   //e retorno Verdadeiro
    end;
  end;
end;

{==| Fun��o - Grid de Strings para XLS |========================================
    Inicia uma inst�ncia do Microsoft Office Excel, cria uma planilha em mem�ria
  (XLS) com os dados de um TStringGrid e salva o arquivo em disco.
  Par�metros de entrada:
    1. Lista de strings que fornecer� os dados > TStringGrid
    2. Nome do arquivo � ser Salvo             > String
  Retorno: Sucesso na leitura (Booleano)
============================================| Leandro Medeiros (17/11/2011) |==}
function StringGridToXls(xStringGrid: TStringGrid; sSheetName,
  sFileName: string): Boolean;
const
  xlWBATWorksheet = -4167;
var
  iX, iY        : Integer;
  XlsApp, Data,
  Sheet         : OLEVariant;
function RefToCell(iRow, iCol: Integer): string;                                //Fun��o interna merametente para
begin                                                                           //retornar o indice correto a ser
  Result := Chr(Ord('A') + iCol - 1) + IntToStr(iRow);                          //usado no MS Excel
end;
begin
  Result := False;                                                              //Assumo Falha

  Data := VarArrayCreate([1, xStringGrid.RowCount, 1, xStringGrid.ColCount], varVariant); //Instancio uma matriz din�mica do mesmo tamanho que o Grid
  for iY := 0 to xStringGrid.RowCount - 1 do                                    //e todas as linhas
    for iX := 0 to xStringGrid.ColCount - 1 do                                  //Monto um loop pegando todas as colunas
      Data[iY + 1, iX + 1] := xStringGrid.Cells[iX, iY];                        //para copiar o conte�do do Grid para a a matriz

  XlsApp := CreateOleObject('Excel.Application');                               //Instancio a aplica��o Excel
  try
    XlsApp.Visible := False;                                                    //N�o a deixo vis�vel
    XlsApp.Workbooks.Add(xlWBatWorkSheet);                                      //Adiciono uma pasta de trabalho
    Sheet          := XlsApp.Workbooks[1].WorkSheets[1];                        //e crio a planilha em cima de outra vari�vel OLE
    Sheet.Name     := sSheetName;                                               //Nomeio esta planilha de acordo com o par�metro
    Sheet.Range[RefToCell(1, 1), RefToCell(xStringGrid.RowCount,                //Clono o Range de dados do Grid para a planilha
      xStringGrid.ColCount)].Value := Data;
    Sheet.Columns.AutoFit;                                                      //Alinho o a planilha de acordo com a largura dos maiores textos
    try
      XlsApp.Workbooks[1].SaveAs(sFileName);                                    //Tento salvar a pasta de trabalho em disco, atrav�s do nome de arquivo recebido no par�mtro
      Result := True;                                                           //Se obtiver sucesso retorno verdadeiro
    except                                                                      //caso contr�rio
      Mensagem('N�o foi poss�vel salvar o arquivo no momento', '', mtError);    //exibo uma mensagem de erro
    end;
  finally                                                                       //Ao final sempre
    if not VarIsEmpty(XlsApp) then                                              //verifico se a variv�l da aplica��o ainda est� ativa
    begin                                                                       //e caso n�o esteja
      XlsApp.DisplayAlerts := False;                                            //N�o permito que a mesma exiba alertas
      XlsApp.Quit;                                                              //antes de fech�-la
      XlsApp := Unassigned;                                                     //depois esvazio as variaveis da aplica��o
      Sheet  := Unassigned;                                                     //e da planilha
    end;
  end;
end;

{==| Procedimento - Alinhar TStringGrid |=======================================
    Altera a largura das colunas de um TStringGrid para que a maior string de
  cada coluna seja totalmente exibida. Altera tamb�m a altura das linhas por
  quest�es meramente est�ticas.
  Par�metros de Entrada:
    1. O grid � ser alinhado (j� instanciado) > TStringGrid
    2. Altura desejada das linhas             > Integer (16 por padr�o)
============================================| Leandro Medeiros (18/11/2011) |==}
procedure AlignStrGrid(var xStringGrid: TStringGrid; iRowsHeight: Integer = 16);
var
  iRow, iCol : integer;
begin
  with xStringGrid do                                                           //Amarro o StringGrid
  begin
    for iCol := 0 to (ColCount - 1) do                                          //Primeiro inicio um loop com todas as colunas
      ColWidths[iCol] := 64;                                                    //para poder voltar sua largura � padr�o do Delphi

    for iRow := 0 to (RowCount - 1) do                                          //Agora sim inicio um loop com todas as linhas
    begin
      RowHeights[iRow] := iRowsHeight;                                          //Seto a altura de cada linha de acordo com o par�metro de entrada da procedure
      for iCol := 0 to ColCount do                                              //depois monto um loop nesta linha com todas as colunas
        if ColWidths[iCol] < Canvas.TextWidth(Cells[iCol, iRow] + ' ') then     //Se a largura da coluna atual for menor que a largura (em pixels) do texto das coordenadas
          ColWidths[iCol] := Canvas.TextWidth(Cells[iCol, iRow] + ' ');         //modifico a largura desta coluna de acordo
    end; //fim do for iRow                                                      //Obs.: Os espa�os concatenados s�o apenas por est�tica
  end; //fim do With StringGrid
end;

{==| Fun��o - Segundos Para Milissegundos |=====================================
    Convertor de unidades de medida, de segundo para milissegundo.
  Par�metros de Entrada:
    1. Segundos > Inteiro;
  Retorno: Correspond�ncia em mil�ssimos de segundo (Inteiro)
============================================| Leandro Medeiros (12/03/2012) |==}
function SecToMSec(Sec: integer): Integer;
begin
  Result := Sec * 1000;
end;

{==| Fun��o - Minutos Para Milissegundos |======================================
    Convertor de unidades de medida, de minuto para milissegundo.
  Par�metros de Entrada:
    1. Minutos > Inteiro;
  Retorno: Correspond�ncia em mil�ssimos de segundo (Inteiro)
============================================| Leandro Medeiros (12/03/2012) |==}
function MinToMSec(Min: integer): Integer;
begin
  Result := Min * 60000;
end;

{==| Fun��o - Milissegundos Para Minutos |======================================
    Convertor de unidades de medida, de milissegundo para minuto.
  Par�metros de Entrada:
    1. Milissegundos > Inteiro;
  Retorno: Correspond�ncia em minutos (Inteiro)
============================================| Leandro Medeiros (12/03/2012) |==}
function MSecToMin(MSec: integer): Integer;
begin
  Result := MSec div 60000;
end;

//==| Fun��o - Array de Inteiros Para String |==================================
function ArrayToString(const AVector: array of Variant): string;
var
  idx : integer;
begin
  Result := '';
  try
    for idx := 0 to Length(AVector) - 1 do
      Result := Result + #13#10 + '[' + IntToStr(idx) + ']' + string(AVector[idx]);
  except

  end;
end;
//==============================================================================

end.
