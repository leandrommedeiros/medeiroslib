{===============================================================================

                           BIBLIOTECA - Utils

==========================================================| Versão 12.11.00 |==}

unit Lib.Utils;

interface

{ Bibliotecas para Interface }
uses
{ Para função XlsToStringGrid }
  ComObj, Vcl.Grids,

{ Bibliotecas básicas }
  Vcl.Controls, Vcl.Dialogs, Classes, Vcl.StdCtrls, FMX.Forms, StrUtils, SysUtils, Vcl.ComCtrls,
  Types, Windows, Variants, Lib.StrUtils, Vcl.Forms;

{ Protótipos das Funções e Procedimentos }
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

{==| Função - Caixa de Mensagem em Português |==================================
    Instancia e exibe um modal de um MessageDialog comum mas com os botões em
  português.
  Parâmetros de entrada:
    1. Mensagem a ser exibida > String
    2. Título do diálogo      > String (Nome da aplicação por padrão)
    3. Tipo de mensagem       > TMsgDlgType (mtInformation por padrão, aceita os
                                tipos mtWarning, mtError, mtConfirmation,
                                mtCustom)
    4. Botões do diálogo      > TMsgDlgButtons (mbOk por padrão)
    5. Índice na ajuda        > Integer (Zero por padrão)
  Retorno:
    Botão clicado pelo usuário (TModalResult)
============================================| Leandro Medeiros (20/10/2011) |==}
function Mensagem(sMensagem: string; sTitulo: string = '';
  DialogType: TMsgDlgType = mtInformation; Buttons: TMsgDlgButtons = [mbOk];
  HelpContext: Integer = 0): TModalResult;
var
  MensagemD : TForm;
  idx       : Integer;
begin
  MensagemD         := CreateMessageDialog(sMensagem, DialogType, Buttons);     //Instancio um MessageDialog com a mensagem, o tipo de diálogo e os botões que entraram como parâmetro
  MensagemD.Caption := ifthen(sTitulo <> '', sTitulo, Application.Title);       //Se o título estiver vazio coloco o nome da aplicação na barra de título da mensagem

  With MensagemD Do                                                             //Com a mensagem
  begin
    For idx := 0 to ComponentCount - 1 do                                       //faço um loop do primeiro ao último componente
    begin
      if Components[idx] is TButton then                                        //Caso o componente seja um Botão
      begin
        with TButton(Components[idx]) do
        begin
          case ModalResult of                                                   //Modifico sua legenda de acordo com seu valor de retorno
            mrYes     : Caption := '&Sim';
            mrNo      : Caption := '&Não';
            mrOK      : Caption := '&Ok';
            mrCancel  : Caption := '&Cancelar';
            mrAbort   : Caption := '&Abortar';
            mrRetry   : Caption := '&Repetir';
            mrIgnore  : Caption := '&Ignorar';
            mrAll     : Caption := '&Todos';
            mrNoToAll :
            begin
              Caption := 'Não P/ Todos';
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

  MensagemD.ShowModal;                                                          //Exibo o Diálogo

  Result := MensagemD.ModalResult;
  FreeAndNil(MensagemD);                                                        //Libero e esvazio a memória outrora ocupada pelo Objeto
end;

{==| Função - InputBoxData |====================================================
    Instancia e exibe um diálogo contendo um TDateTimePicker, um botão de
  cancelamento e um de confirmação. Retorna a data escolhida pelo usuário.
  Parâmetros de Entrada:
    1. Título do diálogo   > string;
    2. Mensagem            > string;
    3. Variável de Retorno > TDate
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

{==| Função - Encontra Nome Disponível |========================================
    Varre um componente container em busca de um nome disponível (utilizando o
  prefixo desejado) para que se crie um componente filho dinâmicamente.
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

//==| Função - Valida Decimal |=================================================
function ValidateDecimal(S: string): Real;
begin
  S[Pos('.', S)] := ',';                                                        //Procura pontos na string e os substitui por vírgulas
  Result := StrToFloat(S);                                                      //depois retorna como número de ponto flutuante
end;

{==| Função - XLS Para ListBox |================================================
    Inicia uma instância do Microsoft Office Excel, carrega no mesmo um arquivo
  XLS e importa os dados para uma lista string.
  Parâmetros de entrada:
    1. Lista de strings que receberá os dados > TListBox
    2. Nome do arquivo à ser lido             > String
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
  XlsApplication := CreateOleObject('Excel.Application');                       //Crio uma instância do Excel

  try
    XlsApplication.Visible := False;                                            //Não permito a exibição da aplicação

    XlsApplication.Workbooks.Open(sFileName);                                   //Abro o arquivo que será importado
    TabXls := XlsApplication.Workbooks[ExtractFileName(sFileName)].WorkSheets[1]; //Mudo para a aba desejada

    TabXls.Cells.SpecialCells(xlCellTypeLastCell, EmptyParam).Activate;         //Posiciono o cursor na última célula da planilha
    X := XlsApplication.ActiveCell.Row;                                         //Guardo a quantidade de linhas na variável X
    Y := XlsApplication.ActiveCell.Column;                                      //e a quantidade de colunas na variável Y

    RangeMatrix := XlsApplication.Range['A1', XlsApplication.Cells.Item[X, Y]].Value; //Associa a variant WorkSheet com a variant do Delphi

  //Monto um loop duplo para listar os registros no TStringGrid
    for iRow := 1 to X do                                                       //o segundo irá da primeira à última linha
      xListBox.Items.Add(Trim(RangeMatrix[iRow, 1]));                           //Copio a célula da planilha para o Grid

    RangeMatrix := Unassigned;                                                  //Limpo a Variável
  finally                                                                       //Ao final sempre
    if not VarIsEmpty(XlsApplication) then                                      //verifico se a aplicação (MS Excel) ainda está instanciada
    begin                                                                       //e caso esteja
      XlsApplication.Quit;                                                      //a finalizo
      XlsApplication := Unassigned;                                             //Libero a memória
      TabXls         := Unassigned;                                             //das variáveis que utilizei para leitura
      Result         := True;                                                   //e retorno Verdadeiro
    end;
  end;
end;

{==| Função - XLS Para Grid de Strings |========================================
    Inicia uma instância do Microsoft Office Excel, carrega no mesmo um arquivo
  XLS e importa os dados para uma lista string.
  Parâmetros de entrada:
    1. Lista de strings que receberá os dados > TStringGrid
    2. Nome do arquivo à ser lido             > String
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
  XlsApplication := CreateOleObject('Excel.Application');                       //Crio uma instância do Excel

  try
    XlsApplication.Visible := False;                                            //Não permito a exibição da aplicação

    XlsApplication.Workbooks.Open(sFileName);                                   //Abro o arquivo que será importado
    TabXls := XlsApplication.Workbooks[ExtractFileName(sFileName)].WorkSheets[1]; //Mudo para a aba desejada

    TabXls.Cells.SpecialCells(xlCellTypeLastCell, EmptyParam).Activate;         //Posiciono o cursor na última célula da planilha
    X := XlsApplication.ActiveCell.Row;                                         //Guardo a quantidade de linhas na variável X
    Y := XlsApplication.ActiveCell.Column;                                      //e a quantidade de colunas na variável Y

    xStringGrid.RowCount := X;                                                  //Agora utilizo os valores guardados para setar
    xStringGrid.ColCount := Y;                                                  //as dimensões do Grid de Strings

    RangeMatrix := XlsApplication.Range['A1', XlsApplication.Cells.Item[X, Y]].Value; //Associa a variant WorkSheet com a variant do Delphi

  //Monto um loop duplo para listar os registros no TStringGrid
    for iCol := 1 to X do                                                       //o primeiro irá da primeira à última coluna
      for iRow := 1 to Y do                                                     //o segundo irá da primeira à última linha
        xStringGrid.Cells[(iRow - 1), (iCol - 1)] := Trim(RangeMatrix[iCol, iRow]); //Copio a célula da planilha para o Grid

    RangeMatrix := Unassigned;                                                  //Limpo a Variável
  finally                                                                       //Ao final sempre
    if not VarIsEmpty(XlsApplication) then                                      //verifico se a aplicação (MS Excel) ainda está instanciada
    begin                                                                       //e caso esteja
      XlsApplication.Quit;                                                      //a finalizo
      XlsApplication := Unassigned;                                             //Libero a memória
      TabXls         := Unassigned;                                             //das variáveis que utilizei para leitura
      Result         := True;                                                   //e retorno Verdadeiro
    end;
  end;
end;

{==| Função - Grid de Strings para XLS |========================================
    Inicia uma instância do Microsoft Office Excel, cria uma planilha em memória
  (XLS) com os dados de um TStringGrid e salva o arquivo em disco.
  Parâmetros de entrada:
    1. Lista de strings que fornecerá os dados > TStringGrid
    2. Nome do arquivo à ser Salvo             > String
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
function RefToCell(iRow, iCol: Integer): string;                                //Função interna merametente para
begin                                                                           //retornar o indice correto a ser
  Result := Chr(Ord('A') + iCol - 1) + IntToStr(iRow);                          //usado no MS Excel
end;
begin
  Result := False;                                                              //Assumo Falha

  Data := VarArrayCreate([1, xStringGrid.RowCount, 1, xStringGrid.ColCount], varVariant); //Instancio uma matriz dinâmica do mesmo tamanho que o Grid
  for iY := 0 to xStringGrid.RowCount - 1 do                                    //e todas as linhas
    for iX := 0 to xStringGrid.ColCount - 1 do                                  //Monto um loop pegando todas as colunas
      Data[iY + 1, iX + 1] := xStringGrid.Cells[iX, iY];                        //para copiar o conteúdo do Grid para a a matriz

  XlsApp := CreateOleObject('Excel.Application');                               //Instancio a aplicação Excel
  try
    XlsApp.Visible := False;                                                    //Não a deixo visível
    XlsApp.Workbooks.Add(xlWBatWorkSheet);                                      //Adiciono uma pasta de trabalho
    Sheet          := XlsApp.Workbooks[1].WorkSheets[1];                        //e crio a planilha em cima de outra variável OLE
    Sheet.Name     := sSheetName;                                               //Nomeio esta planilha de acordo com o parâmetro
    Sheet.Range[RefToCell(1, 1), RefToCell(xStringGrid.RowCount,                //Clono o Range de dados do Grid para a planilha
      xStringGrid.ColCount)].Value := Data;
    Sheet.Columns.AutoFit;                                                      //Alinho o a planilha de acordo com a largura dos maiores textos
    try
      XlsApp.Workbooks[1].SaveAs(sFileName);                                    //Tento salvar a pasta de trabalho em disco, através do nome de arquivo recebido no parâmtro
      Result := True;                                                           //Se obtiver sucesso retorno verdadeiro
    except                                                                      //caso contrário
      Mensagem('Não foi possível salvar o arquivo no momento', '', mtError);    //exibo uma mensagem de erro
    end;
  finally                                                                       //Ao final sempre
    if not VarIsEmpty(XlsApp) then                                              //verifico se a varivél da aplicação ainda está ativa
    begin                                                                       //e caso não esteja
      XlsApp.DisplayAlerts := False;                                            //Não permito que a mesma exiba alertas
      XlsApp.Quit;                                                              //antes de fechá-la
      XlsApp := Unassigned;                                                     //depois esvazio as variaveis da aplicação
      Sheet  := Unassigned;                                                     //e da planilha
    end;
  end;
end;

{==| Procedimento - Alinhar TStringGrid |=======================================
    Altera a largura das colunas de um TStringGrid para que a maior string de
  cada coluna seja totalmente exibida. Altera também a altura das linhas por
  questões meramente estéticas.
  Parâmetros de Entrada:
    1. O grid à ser alinhado (já instanciado) > TStringGrid
    2. Altura desejada das linhas             > Integer (16 por padrão)
============================================| Leandro Medeiros (18/11/2011) |==}
procedure AlignStrGrid(var xStringGrid: TStringGrid; iRowsHeight: Integer = 16);
var
  iRow, iCol : integer;
begin
  with xStringGrid do                                                           //Amarro o StringGrid
  begin
    for iCol := 0 to (ColCount - 1) do                                          //Primeiro inicio um loop com todas as colunas
      ColWidths[iCol] := 64;                                                    //para poder voltar sua largura à padrão do Delphi

    for iRow := 0 to (RowCount - 1) do                                          //Agora sim inicio um loop com todas as linhas
    begin
      RowHeights[iRow] := iRowsHeight;                                          //Seto a altura de cada linha de acordo com o parâmetro de entrada da procedure
      for iCol := 0 to ColCount do                                              //depois monto um loop nesta linha com todas as colunas
        if ColWidths[iCol] < Canvas.TextWidth(Cells[iCol, iRow] + ' ') then     //Se a largura da coluna atual for menor que a largura (em pixels) do texto das coordenadas
          ColWidths[iCol] := Canvas.TextWidth(Cells[iCol, iRow] + ' ');         //modifico a largura desta coluna de acordo
    end; //fim do for iRow                                                      //Obs.: Os espaços concatenados são apenas por estética
  end; //fim do With StringGrid
end;

{==| Função - Segundos Para Milissegundos |=====================================
    Convertor de unidades de medida, de segundo para milissegundo.
  Parâmetros de Entrada:
    1. Segundos > Inteiro;
  Retorno: Correspondência em miléssimos de segundo (Inteiro)
============================================| Leandro Medeiros (12/03/2012) |==}
function SecToMSec(Sec: integer): Integer;
begin
  Result := Sec * 1000;
end;

{==| Função - Minutos Para Milissegundos |======================================
    Convertor de unidades de medida, de minuto para milissegundo.
  Parâmetros de Entrada:
    1. Minutos > Inteiro;
  Retorno: Correspondência em miléssimos de segundo (Inteiro)
============================================| Leandro Medeiros (12/03/2012) |==}
function MinToMSec(Min: integer): Integer;
begin
  Result := Min * 60000;
end;

{==| Função - Milissegundos Para Minutos |======================================
    Convertor de unidades de medida, de milissegundo para minuto.
  Parâmetros de Entrada:
    1. Milissegundos > Inteiro;
  Retorno: Correspondência em minutos (Inteiro)
============================================| Leandro Medeiros (12/03/2012) |==}
function MSecToMin(MSec: integer): Integer;
begin
  Result := MSec div 60000;
end;

//==| Função - Array de Inteiros Para String |==================================
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
