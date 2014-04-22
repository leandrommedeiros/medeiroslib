{===============================================================================

                           BIBLIOTECA - DATABASE

==========================================================| Versão 13.01.00 |==}

unit Lib.DB;

interface

{ Bibliotecas para Interface }
uses
  DB, SqlExpr, DBClient, Provider, ExtCtrls, Lib.StrUtils;

{ Constantes }
const
  CONN_NAME_FB    = 'FirebirdConnection';
  CONN_NAME_MYSQL = 'MySQLConnection';
  DRV_FB          = 'Firebird';
  DRV_MYSQL       = 'MySQL';

{ Classes }
type
  TDBServerType = (stMySQL, stFirebird);

  TSQLConnectionM = class(TSQLConnection)
  private
    SQLDsDynamic : TSQLDataSet;
    DspDynamic   : TDataSetProvider;

    function ApplyParamValues(Args: Variant): Boolean;
  public
    CdsDynamic   : TClientDataSet;

    function ExecuteQuery(AQuery: string; const Args: array of Variant): Boolean; overload;
    function ExecuteQuery(AQuery: string): Boolean; overload;

    function ExecuteQuery(var ACds: TClientDataSet; AQuery: string): Boolean; overload;
    function ExecuteQuery(var ACds: TClientDataSet; AQuery: string;
      const Args: array of Variant): Boolean; overload;

    destructor Destroy; override;
  end;

{ Protótipos }
  function  QueryUpperCase(S: string): string; overload;
  function  sParam(S: String): string;

  function  BuildClause(var CDS_Origem: TClientDataSet; sFieldOri,
    sFieldClau: string): string; overload;
  function  BuildClause(AClauseField: string; const Args: array of string): string; overload;
  procedure AddWhere(var ADest: string; const ANewCondition: string;
    ALinker: string = 'AND'); overload;
  function  Booleano(S: String): Boolean; overload;
  function  Booleano(Flag: Boolean): string; overload;

  procedure FeedCdsTemp(ACdsSource: TClientDataSet; var ACdsTarget: TClientDataSet;
    AOverwrite: Boolean = False);
  procedure CopyToCdsTemp(CdsSource: TClientDataSet; var CdsTemp: TClientDataSet);
  procedure CloneCdsFields(CdsSource: TClientDataSet; var CdsTemp: TClientDataSet);
  procedure RecreateCDS(var CDS: TClientDataSet);
  function  FeedStoredProcParams(CdsSource: TClientDataSet;
    var SQLProc: TSQLStoredProc): Boolean;

  function  ClientHasRec(CDS: TClientDataSet; sField, sValue: string): Boolean;
  function  ClientFindRec(DataSet: TDataSet; sField: String; Value: Variant): Integer;
  function  GetMaxFieldValue(DataSet: TDataSet; sField: String): Variant;
  function  GetMinFieldValue(DataSet: TDataSet; sField: String): Variant;
  function  FieldSUM(DataSet: TDataSet; sField: String): Real;
  procedure ExtractDBFile(DataSet: TDataSet; sBlobField, sDestiny: string);
  procedure LoadDBPicture(DataSet: TDataSet; sBlobField: string;
    var ImgDestiny: TImage);
  function  GetFieldType(const S: string): TFieldType;
  function  NewMySQLConn(const AHost: string; const APort: integer;
    const ADBName, AUser, APasswd: string): TSQLConnectionM;

{ Protótipos - Delphi 7 }
  {$IFDEF VER150}
  function  ExecuteQuery(var AConnection: TSQLConnection; var ACds: TClientDataSet;
    AQuery: string): Boolean; overload; deprecated;
  function  ExecuteQuery(var AConnection: TSQLConnection; var ACds: TClientDataSet;
    AQuery: string; const Args: array of Variant): Boolean; overload;  deprecated;
  function  SetParamValues(var ASqlDs: TSQLDataSet; Args: Variant): Boolean; overload;
  function  SetParamValues(var ASqlDs: TSQLDataSet; Args: array of const): Boolean; overload;
  {$ENDIF}

implementation

{ Bibliotecas para Implementação }
uses
  Classes, SysUtils, StrUtils, Forms, Dialogs, Lib.Utils, Variants, Lib.Files;


{==| Função - Colocar Parâmetros |==============================================
    Itera um array de Variable, e coloca o valor de cada item em um parâmetro
  com o mesmo índice (se existir) no SQLDataSet.
  Parâmetros de entrada:
    1. Lista de valores dos parâmetros da query > Vetor de variáveis
  Retorno: Sucesso (Boolean)
============================================| Leandro Medeiros (28/11/2013) |==}
function TSQLConnectionM.ApplyParamValues(Args: Variant): Boolean;
var
  idx : integer;
begin
  Result := False;                                                              //Assumo Falha

  if not Assigned(Self.SQLDsDynamic) then Exit;                                 //Caso o TSQLDataSet dinâmico não esteja instanciado, abandono a rotina

  try                                                                           //Caso contrário tento
    for idx := 0 to VarArrayHighBound(Args, 1) do                               //iterar os itens do array
      Self.SQLDsDynamic.Params[idx].Value := Args[idx];                         //e copiar seus valores para os parâmetros do TSQLDataSet
    Result := True;                                                             //Se conseguir copiar todos, retorno verdadeiro
  except                                                                        //Em caso de erro
    on e: Exception do                                                          //gravo a mensagem no log em arquivo
      Lib.Files.Log('Falha ao setar parâmetros no SQLDataSet. Erro: ' + e.Message);
  end;
end;

{==| Função - Executa Query |===================================================
    Cria dinâmicamente todos os componentes necessários para executar uma query,
  e alimenta um TClientDataSet.
  Parâmetros de entrada:
    1. Query a ser executada > String¹²

  Retorno: Obteve registros na busca (Booleano).
============================================| Leandro Medeiros (20/10/2011) |==}
function TSQLConnectionM.ExecuteQuery(AQuery: string): Boolean;
begin
  Result := Self.ExecuteQuery(AQuery, []);
end;

{==| Função - Executa Query |===================================================
    Cria dinâmicamente todos os componentes necessários para executar uma query,
  e alimenta um TClientDataSet.
  Parâmetros de entrada:
    1. Query a ser executada               > String.
    2. Valores para os parâmetros da Query > Vetor de Variáveis.

  Retorno: Obteve registros ao executar a query (Booleano).
============================================| Leandro Medeiros (28/11/2013) |==}
function TSQLConnectionM.ExecuteQuery(AQuery: string;
  const Args: array of Variant): Boolean;
begin
  Result := Self.ExecuteQuery(Self.CdsDynamic, AQuery, Args);
end;

{==| Função - Executa Query |===================================================
    Cria dinâmicamente todos os componentes necessários para executar uma query,
  e alimenta um TClientDataSet.
  Parâmetros de entrada:
    1. Variável que receberá os resultados > TClientDataSet
    2. Query a ser executada               > String¹²
  Retorno: Obteve registros na busca (Booleano).
============================================| Leandro Medeiros (20/10/2011) |==}
function TSQLConnectionM.ExecuteQuery(var ACds: TClientDataSet; AQuery: string): Boolean;
begin
  Result := Self.ExecuteQuery(ACds, AQuery, []);
end;

{==| Função - Executa Query |===================================================
    Cria dinâmicamente todos os componentes necessários para executar uma query,
  e alimenta um TClientDataSet.
  Parâmetros de entrada:
    1. Variável que receberá os resultados > TClientDataSet.
    2. Query a ser executada               > String.
    3. Valores para os parâmetros da Query > Vetor de Variáveis.

  Retorno: Obteve registros ao executar a query (Booleano).
============================================| Leandro Medeiros (20/10/2011) |==}

function TSQLConnectionM.ExecuteQuery(var ACds: TClientDataSet; AQuery: string;
  const Args: array of Variant): Boolean;
const
  DSP_NAME = 'DataSetProviderDinamico';
var
  WasConnected : Boolean;
begin
  Result            := False;                                                   //Assumo falha
  WasConnected      := Self.Connected;                                          //Guardo o estado da conexão antes do processamento
  Self.SQLDsDynamic := nil;
  Self.DSPDynamic   := nil;

  if Self.DriverName = DRV_FB then                                              //Retiro os espaços e coloco todos
    AQuery := Lib.DB.QueryUpperCase(Trim(AQuery));                              //os caracteres da query em letras maiúsculas

  try                                                                           //Tento
    Self.SQLDsDynamic               := TSQLDataSet.Create(Self);                //instanciar o SQLDataSet,
    Self.SQLDsDynamic.SQLConnection := Self;                                    //amarro a conexão
    Self.SQLDsDynamic.CommandText   := AQuery;                                  //Copio a query para a propriedade "Linha de Comando" do SQLDataSet dinâmico
    Self.ApplyParamValues(VarArrayOf(Args));                                    //Defino os valores dos parâmetros da query

    if not (Copy(AQuery, 1, 6) = 'SELECT') then                                 //Se a query não iniciar com o comando SELECT
    begin
      Self.SQLDsDynamic.ExecSQL();                                              //devo apenas executar o SQL
      Result := True;                                                           //e retornar sucesso
    end

    else begin                                                                  //Caso contrário
      if not Assigned(ACds) then                                                //Se não houver um TClientDataSet criado
        ACds := TClientDataSet.Create(Self)                                     //o instancio
      else if ACds.Active then                                                  //senão, caso ele esteja ativo
        ACds.EmptyDataSet;                                                      //limpo os registros dele

      ACds.Active 			       := False;                                        //me certifico que o mesmo esteja desativado

      Self.DspDynamic          := TDataSetProvider.Create(ACds.Owner);          //tento instanciar o provedor de dados,
      Self.DspDynamic.Name     := DSP_NAME;                                		  //e nomeio o objeto
      Self.DspDynamic.DataSet  := Self.SQLDsDynamic;                       		  //amarro o TSQLDataSet

      ACds.ProviderName  	     := DSP_NAME;                                     //e amarro o Provedor de dados dinâmico.

      Self.SQLDsDynamic.Active := True;                                    		  //Finalmente ativo o SQLDataSet executando a busca

      ACds.PacketRecords := - 1;                                                //Me certifico que o Client está sem limitador de pacote de registros (caso contrário o client só receberá os primeiros X registros da busca e depois que o SQLDataSet for destruído não será possível movê-lo)
      ACds.Active        := True;                                               //Ativo o ClientDataSet
      ACds.ProviderName  := EmptyStr;                                           //Retiro seu Provedor de Dados

      Result := not ACds.IsEmpty;                                               //Retorno verdadeiro caso a busca tenha retornado ao menos um resultado
    end;
  finally                                                                       //Ao final sempre
    Self.Connected           := WasConnected;                                   //volto a conexão ao seu estado inicial
    Self.SQLDsDynamic.Active := False;                                          //Desativo o TSQLDataSet

    try                                                                         //Tento
      if Assigned(Self.SQLDsDynamic) then FreeAndNil(Self.SQLDsDynamic);        //Destruir o TSQLDataSet dinâmico
      if Assigned(Self.DspDynamic)   then FreeAndNil(Self.DspDynamic);          //e o TDataSetProvider também, se necessário
    except                                                                      //caso não consiga
      on e: Exception do                                                        //gero um log em arquivo com o erro
        Lib.Files.Log('ExecuteQuery: Falha ao destruir componentes dinâmicos: ' + e.Message);
    end;
  end;
end;

//==| Procedimento - Desconstrutor |============================================
destructor TSQLConnectionM.Destroy;
begin
  try                                                                           //Tento
    if Assigned(Self.CdsDynamic)   then FreeAndNil(Self.CdsDynamic);            //Destruir o TSQLDataSet dinâmico
    if Assigned(Self.SQLDsDynamic) then FreeAndNil(Self.SQLDsDynamic);          //Destruir o TSQLDataSet dinâmico
    if Assigned(Self.DspDynamic)   then FreeAndNil(Self.DspDynamic);            //e o TDataSetProvider também, se necessário
  except                                                                        //caso não consiga
    on e: Exception do                                                          //gero um log em arquivo com o erro
      Lib.Files.Log('ExecuteQuery: Falha ao destruir componentes dinâmicos: ' + e.Message);
  end;

  inherited Destroy;                                                            //Por fim executo o desconstrutor herdado
end;

{==| Função - Query Maiúscula |=================================================
    Muda todos os caracteres de uma string para maiúscula, exceto aqueles que
  estão entre apóstrofos (parâmetros).
============================================| Leandro Medeiros (20/10/2011) |==}
function QueryUpperCase(S: string): string; overload;
var
  idx     : integer;
  InParam : Boolean;
begin
  InParam := False;

  for idx := 1 to Length(S) do
    if S[idx] = Chr(39) then InParam := not InParam
    else if not InParam then S[idx]  := AnsiUpperCase(S[idx])[1];
  Result := S;
end;

{==| Função - Parâmetro String |================================================
    Valida um parâmetro do tipo string para ser utilizado na função ExecutaQuery.
  Recebe o valor do parâmetro em uma string e o retorna concatenado entre
  apóstrofos.
============================================| Leandro Medeiros (20/10/2011) |==}
function sParam(S: String): string;
begin
  if S <> EmptyStr then
    Result := ifthen(Pos('=', S) = 0, '=') + QuotedStr(S)
  else
    Result := ' IS NULL ';
end;

{==| Função - Constrói Cláusula |===============================================
    Monta uma cláusula para ser usada em um WHERE no lugar de um IN. Só pode ser
  usada para um único campo de uma única tabela.

  Parâmetros de entrada:
    1. Client de Origem                                       > TClientDataSet
    2. Campo da Origem (será copiado do client pro resultado) > String
    3. Campo Cláusula (será a cláusula no resultado)          > String
  Retorno: Cláusula com valores concatenados (string)
============================================| Leandro Medeiros (01/11/2011) |==}
function BuildClause(var CDS_Origem: TClientDataSet; sFieldOri,
  sFieldClau: string): string;
var
  sAux  : string;
  pBook : TBookmark;
begin
  if CDS_Origem.IsEmpty then Exit;                                              //Se o Client de origem estiver vazio aborto o processamento

  sFieldClau := Trim(sFieldClau) + ' = ';                                       //Tiro os espaços da variável que será a condição de retorno e adiciono o sinal de igualdade

  with CDS_Origem do
  begin
    pBook := GetBookmark;                                                       //Guardo o índice do registro atual do Client
    DisableControls;                                                            //Desativo seus controles
    First;                                                                      //Posiciono no primeiro registro
    while not EOF do                                                            //Faço um loop até o último registro
    begin                                                                       //onde
      if sAux = '' then                                                         //vefifico se a variável auxiliar está vazia e caso esteja
        sAux := sFieldClau + QuotedStr(FieldByName(sFieldOri).AsString)         //seu valor passará a ser o nome do campo cláusula mais o valor do campo do client configurado na chamada da função
      else                                                                      //caso contrário
        sAux := sAux + ' OR ' + sFieldClau + QuotedStr(FieldByName(sFieldOri).AsString); //concateno à ela um "OR" e depois o nome do campo cláusula mais o valor do campo do client configurado na chamada da função
       Next;                                                                    //Movo o client para o próximo registro
    end;
    if BookmarkValid(pBook) then GotoBookmark(pBook);                           //Se o Bookmark ainda for válido, reposiciono o Client a partir dele
    FreeBookmark(pBook);                                                        //libero o marca páginas
    EnableControls;                                                             //e reativo os controles
  end;

  if Length(sAux) > 0 then Result := '(' + sAux + ')';                          //Se a variável auxiliar não estiver vazia coloco parânteses no inicio e no fim da string e retorno ela como resultado da função
end;

{==| Função - Constrói Cláusula |===============================================
    Monta uma cláusula para ser usada em um WHERE no lugar de um IN. Só pode ser
  usada para um único campo de uma única tabela.

  Parâmetros de entrada:
    1. Campo Cláusula (será a cláusula no resultado) > String
    2. Array de Valores                              > String
  Retorno: Cláusula com valores concatenados (string)
============================================| Leandro Medeiros (01/11/2011) |==}
function BuildClause(AClauseField: string; const Args: array of string): string; overload;
var
  idx  : integer;
begin
  Result       := EmptyStr;
  AClauseField := Trim(AClauseField) + ' = ';                                   //Tiro os espaços da variável que será a condição de retorno e adiciono o sinal de igualdade

  for idx := 0 to (Length(Args) - 1) do
    if Result = EmptyStr then                                                   //vefifico se a variável auxiliar está vazia e caso esteja
      Result := AClauseField + QuotedStr(Args[idx])                             //seu valor passará a ser o nome do campo cláusula mais o valor do campo do client configurado na chamada da função
    else                                                                        //caso contrário
      Result := Result + ' OR ' + AClauseField + QuotedStr(Args[idx]);          //concateno à ela um "OR" e depois o nome do campo cláusula mais o valor do campo do client configurado na chamada da função

  if Length(Result) > 0 then Result := '(' + Result + ')';                      //Se a variável auxiliar não estiver vazia coloco parânteses no inicio e no fim da string e retorno ela como resultado da função
end;

{==| Função - Adiciona "Where" |================================================
    Concatena uma string à outra que será usada como cláusula "WHERE" em uma
  query. Caso a string de destino não esteja vazia então colocamos o "AND" ou
  "OR".
============================================| Leandro Medeiros (07/06/2013) |==}
procedure AddWhere(var ADest: string; const ANewCondition: string;
  ALinker: string = 'AND'); overload;
begin
  if Length(ANewCondition) <= 0 then Exit;                                      //Se a nova condição estiver vazia, não processo mais nada
  if Length(ADest) > 0 then                                                     //Se a variável de destino não estiver vazia
    ADest := ADest + #32 + ALinker + #32 + ANewCondition                        //concateno à ela um "AND" e a nova condição
  else ADest := ' WHERE ' + ANewCondition;                                      //Caso contrário inicio ela com "WHERE" concatenado à nova condição
end;

{==| Função - Booleano (Overload 01) |==========================================
  Facilita a interpretação de campos Flag que vem do banco de dados.
  Parâmetros de Entrada:
    1. Valor > String
  Retorno: Booleano;
============================================| Leandro Medeiros (18/01/2012) |==}
function Booleano(S: String): Boolean; overload;
begin
  S := AnsiUpperCase(S);
  Result := (S = 'S') or (S = 'Y');
end;

{==| Função - Booleano (Overload 02) |==========================================
  Facilita a conversão de campos Flag que vão para o banco de dados.
  Parâmetros de Entrada:
    1. Valor > Booleano
  Retorno: String;
============================================| Leandro Medeiros (18/01/2012) |==}
function Booleano(Flag: Boolean): string; overload;
begin
  Result := ifthen(Flag, 'S', 'N');
end;

{==| Procedimento - Alimenta Client Temporário |================================
    Copia todos os campos e registros de um ClientDataSet para outro (para
  alimentação de um Client temporário).
  Parâmetros de entrada:
    1. Origem               > TClientDataSet
    2. Destino (Temporário) > TClientDataSet
    3. Sobreescrever        > Boolean (Se verdadeiro, apaga os registros e
                              campos do destino e copia os da origem, caso
                              contrário apenas acrescenta os faltantes -
                              Padrão: Falso)
============================================| Leandro Medeiros (20/10/2011) |==}
procedure FeedCdsTemp(ACdsSource: TClientDataSet; var ACdsTarget: TClientDataSet;
  AOverwrite: Boolean = False);
var idx: integer;
begin
  if not AOverwrite then
  	AOverwrite := ACdsTarget.FieldCount <= 0;                                   //Se o Cliente de destino não conter nenhum campo configuro a função para o modo "Sobreescrever"

  if ACdsSource.FieldCount > ACdsTarget.FieldCount then                         //Se o número de campos do Client de Origem for maior que o de Destino
  begin                                                                         //então
    if AOverwrite then                                                          //Caso esteja no modo de sobre escrita
    begin
      RecreateCds(ACdsTarget);                                                  //Recrio o Client de destino
      ACdsTarget.FieldDefs.Assign(ACdsSource.FieldDefs);                        //e clono os campos do Cliente de Origem para ele
    end

    else begin                                                                  //Caso contrário
      for idx := 0 to ACdsSource.FieldCount - 1 do                              //Faço um loop com os campos do primeiro Client
      begin
        if ACdsTarget.FindField(ACdsSource.Fields[idx].FieldName) = nil then    //Verifico se o campo atual exite no Client de Destino
          ACdsTarget.Fields.Add(ACdsSource.Fields[idx]);                        //e se não exitir copio ele
      end;
    end;
  end;

  try
    if not Assigned(ACdsTarget) or (ACdsTarget.IsEmpty) then                    //Se o Client de destino ou sua variavél estiver vazio
      ACdsTarget.CreateDataSet;                                                 //crio o DataSet
  except
  end;

{  while not CdsSource.EOF do
  begin
    CdsTemp.CloneCursor(CdsSource, False);
    CdsSource.Next;
  end;}

  ACdsSource.First;                                                             //Posiciono o Cliente de Origem no primeiro registro
  while not ACdsSource.EOF do                                                   //Enquanto não chegar último dos registros
  begin
    Lib.DB.CopyToCdsTemp(ACdsSource, ACdsTarget);                               //posto um novo registro no Client de destino
    ACdsSource.Next;                                                            //e movo o Client de Origem para o próximo registro
  end;
  ACdsTarget.Active := True;                                                    //Ao final ativo o Client de Destino
end;

{==| Procedimento - Copia Para ClientDataSet Temporário |=======================
    Copia o registro atual de um ClientDataSet para outro (para alimentação de
  um Client temporário).
  Parâmetros de entrada:
    1. Fonte                > TClientDataSet
    2. Destino (Temporário) > TClientDataSet
============================================| Leandro Medeiros (20/10/2011) |==}
procedure CopyToCdsTemp(CdsSource: TClientDataSet; var CdsTemp: TClientDataSet);
var
  idx: integer;
begin
  CdsSource.Edit;                                                               //Mudo o Client de origem para o modo de Edição
  CdsTemp.Insert;                                                               //e o de Destino para o modo de inserção

  for idx := 0 to CdsTemp.FieldCount - 1 do                                     //Mais uma vez faço um loop com todos os campos
  begin
    CdsTemp.Fields[idx].Required := False;
    CdsTemp.Fields[idx].Value    := CdsSource.FindField(CdsTemp.Fields[idx].FieldName).Value; //E copio o valor de cada um deles para o campo correspondente no Client de Destino
  end;
  CdsTemp.Post;                                                                 //posto o novo registro no Client de destino
  CdsSource.Cancel;                                                             //e cancelo a edição do Client de origem
end;

//==| Procedimento - Clona Campos do ClientDataSet |============================
procedure CloneCdsFields(CdsSource: TClientDataSet; var CdsTemp: TClientDataSet);
begin
  CdsTemp.FieldDefs := nil;                                                     //removo possíveis campos do client de destino
  CdsTemp.FieldDefs.Assign(CdsSource.FieldDefs);                                //e clono os campos do Cliente de Origem para ele
end;

{==| Procedimento - Recriar ClientDataSet |=====================================
    Recebe um ClientDataSet como parâmetro, o destroi e logo depois cria novamente
  com o mesmo nome e dono.
============================================| Leandro Medeiros (20/10/2011) |==}
procedure RecreateCds(var CDS: TClientDataSet);
var
  cOwner : TComponent;
  sName  : string;
begin
  sName  := CDS.Name;                                                           //Guardo o antigo nome
  cOwner := CDS.Owner;                                                          //e o dono do ClientDataSet recebido como parâmetro

  FreeAndNil(CDS);                                                              //Destruo o componente e esvazio sua variável
  CDS      := TClientDataSet.Create(cOwner);                                    //Recrio usando o dono guardado
  CDS.Name := sName;                                                            //e nomeio com a string antiga
end;

{==| Função - Alimenta Parâmetros de Stored Procedure |=========================
    Varre os campos de uma SQLStoredProcedure em busca de parâmetros que possuam
  os mesmos nomes que os campos de um ClientDataSet, e copia os valores do segundo
  para o primeiro. Retorna verdadeiro se executar com sucesso.
===============================================================================}
function FeedStoredProcParams(CdsSource: TClientDataSet;
  var SQLProc: TSQLStoredProc): Boolean;
var
  idx : integer;
begin
  try
    for idx := 0 to (CdsSource.Fields.Count - 1) do
      if not CdsSource.Fields[idx].IsNull then
        SQLProc.Params.FindParam(CdsSource.Fields[idx].FieldName).Value := CdsSource.Fields[idx].Value;
    Result := True;
  except
    Result := False;
  end;
end;

{==| Função - Client Possui Registro |==========================================
    Varre um ClientDataSet em busca de determidado valor, e caso o encontre,
  retorna verdadeiro.
  Parâmentros de Entrada:
    1. DataSet que será varrido       > TClientDataSet
    2. Nome do campo a ser verificado > String
    3. Valor procurado                > String
  Retorno: Contém ou não (Booleano)
===============================================================================}
function ClientHasRec(CDS: TClientDataSet; sField, sValue: string): Boolean;
var
  pBook : TBookmark;
begin
  Result := False;                                                              //Pré-defino o retorno da função como falso
  Try
    pBook  := CDS.GetBookmark;                                                  //Guardo a posição (registro) atual do TClientDataSet
    CDS.DisableControls;                                                        //Desativo todos os controles relacionados ao client
    CDS.First;                                                                  //o posiciono no primeiro registro

    while not CDS.EOF do                                                        //Enquanto não atingir o final do arquivo
    begin
      if (CDS.FieldByName(sField).AsString = sValue) then                       //Verifico se o valor deste registro é igual ao do parâmetro de entrada da função
      begin                                                                     //e se for
        Result := True;                                                         //O retorno da função passa a ser verdadeiro
        CDS.EnableControls;                                                     //Reativo todos os controles relacionados ao client
        Exit;                                                                   //e a busca é finalizada
      end;
      CDS.Next;                                                                 //Se chegar aqui movo o ClientDataSet para próximo registro
    end;
    CDS.EnableControls;                                                         //Reativo todos os controles relacionados ao client
  finally                                                                       //Ao final, sempre
    try                                                                         //tento
      if CDS.BookmarkValid(pBook) then
        CDS.GotoBookmark(pBook);                                                //reposicionar o Client no registro que estava antes de iniciar a procedure
    except
    end;
  end;
end;

{==| Função - Encontrar Registro |==============================================
    Busca um registro dentro de um DataSet e retorna o índice caso encontre, caso
  contrário retorna -1.
  Parâmetros de Entrada:
    1. DataSet onde a busca será efetuada > TDataSet
    2. Nome do campo a ser verificado     > String
    3. Valor Procurado                    > Variant
  Retorno: Índice da string na lista (Integer)
============================================| Renan Vasconcelos(15/03/2012) |==}
function ClientFindRec(DataSet: TDataSet; sField: String; Value: Variant): Integer;
begin
  Result := - 1;

  DataSet.First;
  while not DataSet.EOF do
  begin
    if DataSet.FieldByName(sField).Value = Value then
    begin
      Result := DataSet.RecNo;
      Exit;
    end;
    DataSet.Next;
  end;
end;

{==| Função - Obter Valor Máximo do Campo |=====================================
    Varre um TDataSet e retorna o maior valor encontrado em determinado campo.
  Parâmentros de Entrada:
    1. DataSet que será varrido       > TDataSet ou herdeiros
    2. Nome do campo a ser verificado > String
  Retorno: Variante

  ATENÇÃO! Este método funciona somente com campos que contém valores que possam
  ser ordenados numéricamente de forma crescente. É mais recomendável utilizar
  com os tipos Integer e Float, porém também funcionará com TDateTime e strings
  que possuam unicamente números, como é o caso da maioria das chaves primárias
  e estrangeiras do sistema.
===============================================================================}
function GetMaxFieldValue(DataSet: TDataSet; sField: String): Variant;
var
  Value : Variant;
  pBook : TBookmark;
begin
  Value := 0;                                                                   //Inicializo a variável para garantir que nenhum lixo de memória será comparado
  with DataSet do                                                               //Amarro o DataSet e
  begin
    DisableControls;                                                            //desabilito os controles
    pBook := GetBookmark;                                                       //guardo a posição atual

    First;                                                                      //posiciono no primeiro registro
    while not EOF do                                                            //e enquanto não chegar ao último
    begin
      if FieldByName(sField).Value > Value then                                 //verifico se o valor do campo no registro atual é maior do que o que tenho guardado na variável de retorno (Value)
        Value := FieldByName(sField).Value;                                     //e se for, substituo ela
      Next;                                                                     //depois movo o DataSet para o próximo registro
    end;

    if BookmarkValid(pBook) then GotoBookmark(pBook);                           //Depois de varrer o DataSet, tento voltá-lo para o registro que estava antes da busca
    EnableControls;                                                             //reativo os controles
  end;
  Result := Value;                                                              //e retorno o maior valor encontrado
end;

{==| Função - Obter Valor Mínimo do Campo |=====================================
    Varre um TDataSet e retorna o menor valor encontrado em determinado campo.
  Parâmentros de Entrada:
    1. DataSet que será varrido       > TDataSet ou herdeiros
    2. Nome do campo a ser verificado > String
  Retorno: Variante

  ATENÇÃO! Este método funciona somente com campos que contém valores que possam
  ser ordenados numéricamente de forma decrescente. É mais recomendável utilizar
  com os tipos Integer e Float, porém também funcionará com TDateTime e strings
  que possuam unicamente números, como é o caso da maioria das chaves primárias
  e estrangeiras do sistema.
===============================================================================}
function GetMinFieldValue(DataSet: TDataSet; sField: String): Variant;
var
  Value : Variant;
  pBook : TBookmark;
begin
  Value := 0;                                                                   //Inicializo a variável para garantir que nenhum lixo de memória será comparado
  with DataSet do                                                               //Amarro o DataSet e
  begin
    DisableControls;                                                            //desabilito os controles
    pBook := GetBookmark;                                                       //guardo a posição atual

    First;                                                                      //posiciono no primeiro registro
    while not EOF do                                                            //e enquanto não chegar ao último
    begin
      if FieldByName(sField).Value < Value then                                 //verifico se o valor do campo no registro atual é menor do que o que tenho guardado na variável de retorno (Value)
        Value := FieldByName(sField).Value;                                     //e se for, substituo ela
      Next;                                                                     //depois movo o DataSet para o próximo registro
    end;

    if BookmarkValid(pBook) then GotoBookmark(pBook);                           //Depois de varrer o DataSet, tento voltá-lo para o registro que estava antes da busca
    EnableControls;                                                             //reativo os controles
  end;
  Result := Value;                                                              //e retorno o menor valor encontrado
end;

{==| Função - Somar Campo |=====================================================
    Varre um TDataSet somando os valores de um determinado campo.
  Parâmentros de Entrada:
    1. DataSet que será varrido   > TDataSet ou herdeiros
    2. Nome do campo a ser somado > String
  Retorno: Real
===============================================================================}
function FieldSUM(DataSet: TDataSet; sField: String): Real;
var
  pBookmark : TBookmark;
  rSum      : Real;
begin
  sField := AnsiUpperCase(sField);

  if not (DataSet.FieldByName(sField).ClassType = TFloatField) and
     not (DataSet.FieldByName(sField).ClassType = TIntegerField) then
  begin
    Result := 0;
    Exit;
  end;

  rSum := 0;

  with DataSet do
  begin
    DisableControls;
    pBookmark := GetBookmark;

    while not EOF do
    begin
      rSum := rSum + DataSet.FieldByName(sField).AsFloat;
      Next;
    end;

    GotoBookmark(pBookmark);
    EnableControls;

    Result := rSum;
  end;
end;

{==| Procedimento - Extrair Arquivo do Banco |==================================
    Varre um campo do tipo Blob binário e a partir dele "monta" um arquivo em
  disco.
  Parâmetros de Entrada:
    1. DataSet onde a busca foi feita     > Qualquer herdeiro da classe TDataSet
    2. Nome do campo de origem do arquivo > String
    3. Destino do arquivo                 > String
===============================================================================}
procedure ExtractDBFile(DataSet: TDataSet; sBlobField, sDestiny: string);
var
  Blob : TStream;
begin
  try
    sBlobField := AnsiUpperCase(sBlobField);
    Blob := DataSet.CreateBlobStream(TBlobField(DataSet.FieldByName(sBlobField)),
                                     bmRead);
    Blob.Seek(0, soFromBeginning);

    with TFileStream.Create(sDestiny, fmCreate) do
      try
        CopyFrom(Blob, Blob.Size);
      finally
        Free;
      end;
  finally
    Blob.Free;
  end;
end;

{==| Procedimento - Carregar Imagem do Banco |==================================
    Varre um campo do tipo Blob binário e a partir dele "monta" um arquivo de
  imagem em disco. Depois carrega esta imagem em um componente da classe TImage.
  Parâmetros de Entrada:
    1. DataSet onde a busca foi feita     > Qualquer herdeiro da classe TDataSet
    2. Nome do campo de origem do arquivo > String
    3. Destino do arquivo                 > TImage
===============================================================================}
procedure LoadDBPicture(DataSet: TDataSet; sBlobField: string; var ImgDestiny: TImage);
var
  sTempFile : string;
  Blob      : TStream;
begin
  try
    sBlobField := AnsiUpperCase(sBlobField);

    if (DataSet.FieldByName(sBlobField).IsNull) or
       (not DataSet.FieldByName(sBlobField).IsBlob) then
      Exit;

    Blob := DataSet.CreateBlobStream(TBlobField(DataSet.FieldByName(sBlobField)),
                                     bmRead);
    Blob.Seek(0, soFromBeginning);

    sTempFile := GetEnvironmentVariable('TEMP') + '\' + GenRandomStr() + '.png';

    with TFileStream.Create(sTempFile, fmCreate) do
      try
        CopyFrom(Blob, Blob.Size);
      finally
        Free;
      end;

    ImgDestiny.Picture.LoadFromFile(sTempFile);
  finally
    Blob.Free;
    if FileExists(sTempFile) then
      DeleteFile(sTempFile);
  end;
end;

{==| Função - Obter tipo de campo |=============================================
    A partir de uma string determino em que tipo de campo ela deverá ser salva
  no caso de um ClientDataSet temporário dinâmico.
  Parâmetros de entrada:
    1. Variável à ser avaliada > String
  Retorno:
    Tipo de campo que aceitará aquela variável (TFieldType)

  NOTA: Ao depurar a aplicação esta função poderá gerar diversos erros até que
  retorne um campo.
============================================| Leandro Medeiros (24/11/2011) |==}
function GetFieldType(const S: string): TFieldType;
var
  Aux : Variant;
begin
  try
    Aux    := StrToDate(S);                                                     //Tento converter a string em Data
    Result := ftDate;                                                           //se conseguir retorno tipo data
  except                                                                        //senão
    try
      Aux    := StrToInt(S);                                                    //Tento converter a string em Inteiro
      Result := ftInteger;                                                      //se conseguir retorno tipo inteiro
    except                                                                      //caso contrário
      try
        Aux    := StrToFloat(S);                                                //Tento converter a string em Float
        Result := ftFloat;                                                      //se conseguir retorno tipo float
      except                                                                    //senão
        Result := ftString;                                                     //retorno tipo string
      end;
    end;
  end;
end;

//==| Criar Nova Conexão com o MySQL |==========================================
function NewMySQLConn(const AHost: string; const APort: integer;
  const ADBName, AUser, APasswd: string): TSQLConnectionM;
const
  MYSQL_PARAMS = 'DriverName=MySQL' +#13+#10
               + 'HostName=%s' +#13+#10
               + 'Database=%s' +#13+#10
               + 'User_Name=%s' +#13+#10
               + 'Password=%s' +#13+#10
               + 'ServerCharSet=' +#13+#10
               + 'BlobSize=-1' +#13+#10
               + 'ErrorResourceFile=' +#13+#10
               + 'LocaleCode=0000' +#13+#10
               + 'Compressed=False' +#13+#10
               + 'Encrypted=False' +#13+#10
               + 'ConnectTimeout=60' +#13#10
               + 'Port=%d' ;
begin
  Result := TSQLConnectionM.Create(nil);

  with Result do
  begin
    Name            := 'MySQLCon';
    ConnectionName  := CONN_NAME_MYSQL;
    DriverName      := DRV_MYSQL;
    Connected       := False;
    KeepConnection  := False;
    LoginPrompt     := False;

    Params.Text     := Format(MYSQL_PARAMS, [AHost,
                                             ADBName,
                                             AUser,
                                             APasswd,
                                             APort]);
  end;
end;

{$IFDEF VER150}

{*******************************************************************************

                PROCEDIMENTOS E FUNÇÕES EXCLUSIVOS DELPHI 7

*******************************************************************************}

function ExecuteQuery(var AConnection: TSQLConnection; var ACds: TClientDataSet;
  AQuery: string): Boolean; overload;
var
  sSqlName,
  sDspName     : string;
  SqlDados     : TSQLDataSet;
  DspDados     : TDataSetProvider;
  WasConnected,
  lgDestroy    : Boolean;

  procedure CreateCds;
  begin
    try
      ACds := TClientDataSet.Create(Application);                               //tento criá-lo
    except
      Lib.Files.Log('Erro ao instanciar TClientDataSet');
    end;
  end;
begin
  Result       := False;                                                        //Assumo falha
  WasConnected := AConnection.Connected;                                        //Guardo o estado da conexão antes do processamento
  SqlDados     := nil;
  DspDados     := nil;

  if AConnection.DriverName = DRV_FB then                                       //Retiro os espaços e coloco todos
    AQuery := QueryUpperCase(Trim(AQuery));                                     //os caracteres da query em letras maiúsculas
  lgDestroy := (Copy(AQuery, 1, 6) = 'SELECT');

  try                                                                           //Tento
    sSqlName               := FindAvaliableName(Application, 'SqlDados');       //(Nomeação dos componentes dinâmicos tem de ser diferente)

    SqlDados               := TSQLDataSet.Create(Application);                  //instanciar o SQLDataSet pertencendo ao Dono recebido no parâmetro,
    SqlDados.SQLConnection := AConnection;                                      //amarro a conexão
    SqlDados.Name          := sSqlName;                                         //e nomeio o objeto
    SqlDados.CommandText   := AQuery;                                           //Copio a query para a propriedade "Linha de Comando" do SQLDataSet dinâmico

    if not lgDestroy then SqlDados.ExecSQL()                                    //Se a query não iniciar com o comando SELECT devo apenas executar o SQL

    else begin                                                                  //Caso contrário
      try
        if not Assigned(ACds) or (ACds.Name = EmptyStr) then CreateCds;
      except
        CreateCds;
      end;

      ACds.Active         := False;                                             //me certifico que o mesmo esteja desativado

      sDspName            := FindAvaliableName(ACds.Owner, 'DspDados');
      DspDados            := TDataSetProvider.Create(ACds.Owner);               //tento instanciar o provedor de dados pertencendo ao Dono recebido no parâmetro,
      DspDados.Name       := sDspName;                                          //e nomeio o objeto
      DspDados.DataSet    := SqlDados;                                          //amarro o SQLDataSet
      ACds.ProviderName   := sDspName;                                          //e amarro o Provedor de dados dinâmico.

      SqlDados.Active     := True;                                              //Finalmente ativo o SQLDataSet executando a busca

      ACds.PacketRecords  := - 1;                                               //Me certifico que o Client está sem limitador de pacote de registros (caso contrário o client só receberá os primeiros X registros da busca e depois que o SQLDataSet for destruído não será possível movê-lo)
      ACds.Active         := True;                                              //Ativo o ClientDataSet
      ACds.ProviderName   := '';                                                //Retiro seu Provedor de Dados
      Result              := not ACds.IsEmpty;                                  //Retorno verdadeiro caso a busca tenha retornado ao menos um resultado
    end;
  finally                                                                       //Ao final sempre
    AConnection.Connected := WasConnected;                                      //volto a conexão ao seu estado inicial
    SqlDados.Active       := False;

    if lgDestroy then
      try
        SqlDados.FreeOnRelease;
        SqlDados.Destroy;

        DspDados.FreeOnRelease;
        DspDados.Destroy;
      except
      end;
  end;
end;

{==| Função - Executa Query |===================================================
    Cria dinâmicamente todos os componentes necessários para executar uma query,
  e alimenta um TClientDataSet.
  Parâmetros de entrada:
    1. Conexão a ser utilizada             > TSQLConnection.
    2. Variável que receberá os resultados > TClientDataSet.
    3. Query a ser executada               > String.
    4. Valores para os parâmetros da Query > Vetor de Variáveis.

  Retorno: Obteve registros ao executar a query (Booleano).
============================================| Leandro Medeiros (20/10/2011) |==}
function ExecuteQuery(var AConnection: TSQLConnection; var ACds: TClientDataSet;
  AQuery: string; const Args: array of Variant): Boolean;
var
  WasConnected,
  lgDestroy    : Boolean;
  sSqlName,
  sDspName     : string;
  SqlDados     : TSQLDataSet;
  DspDados     : TDataSetProvider;

  procedure CreateCds;
  begin
    try
      ACds := TClientDataSet.Create(Application);                               //tento criá-lo
    except
      Lib.Files.Log('Erro ao instanciar TClientDataSet');
    end;
  end;
begin
  Result       := False;                                                        //Assumo falha
  WasConnected := AConnection.Connected;                                        //Guardo o estado da conexão antes do processamento
  SqlDados     := nil;
  DspDados     := nil;

  if AConnection.DriverName = DRV_FB then                                       //Retiro os espaços e coloco todos
    AQuery := QueryUpperCase(Trim(AQuery));                                     //os caracteres da query em letras maiúsculas
  lgDestroy := (Copy(AQuery, 1, 6) = 'SELECT');

  try                                                                           //Tento
    sSqlName               := FindAvaliableName(Application, 'SqlDados');       //(Nomeação dos componentes dinâmicos tem de ser diferente)

    SqlDados               := TSQLDataSet.Create(Application);                  //instanciar o SQLDataSet pertencendo ao Dono recebido no parâmetro,
    SqlDados.SQLConnection := AConnection;                                      //amarro a conexão
    SqlDados.Name          := sSqlName;                                         //e nomeio o objeto
    SqlDados.CommandText   := AQuery;                                           //Copio a query para a propriedade "Linha de Comando" do SQLDataSet dinâmico

    SetParamValues(SqlDados, VarArrayOf(Args));                                 //Defino os valores dos parâmetros da query

    if not lgDestroy then SqlDados.ExecSQL()                                    //Se a query não iniciar com o comando SELECT devo apenas executar o SQL

    else begin                                                                  //Caso contrário
      try
        if not Assigned(ACds) or (ACds.Name = EmptyStr) then CreateCds;
      except
        CreateCds;
      end;

      ACds.Active         := False;                                             //me certifico que o mesmo esteja desativado

      sDspName            := FindAvaliableName(ACds.Owner, 'DspDados');
      DspDados            := TDataSetProvider.Create(ACds.Owner);               //tento instanciar o provedor de dados pertencendo ao Dono recebido no parâmetro,
      DspDados.Name       := sDspName;                                          //e nomeio o objeto
      DspDados.DataSet    := SqlDados;                                          //amarro o SQLDataSet
      ACds.ProviderName   := sDspName;                                          //e amarro o Provedor de dados dinâmico.

      SqlDados.Active     := True;                                              //Finalmente ativo o SQLDataSet executando a busca

      ACds.PacketRecords  := - 1;                                               //Me certifico que o Client está sem limitador de pacote de registros (caso contrário o client só receberá os primeiros X registros da busca e depois que o SQLDataSet for destruído não será possível movê-lo)
      ACds.Active         := True;                                              //Ativo o ClientDataSet
      ACds.ProviderName   := '';                                                //Retiro seu Provedor de Dados
      Result              := not ACds.IsEmpty;                                  //Retorno verdadeiro caso a busca tenha retornado ao menos um resultado
    end;
  finally                                                                       //Ao final sempre
    AConnection.Connected := WasConnected;                                      //volto a conexão ao seu estado inicial
    SqlDados.Active       := False;

    if lgDestroy then
      try
        SqlDados.FreeOnRelease;
        SqlDados.Destroy;

        DspDados.FreeOnRelease;
        DspDados.Destroy;
      except
      end;
  end;
end;

//==| Função - Colocar Parâmetros |=============================================
function SetParamValues(var ASqlDs: TSQLDataSet; Args: Variant): Boolean; overload;
var
  idx : integer;
begin
  try
    for idx := 0 to VarArrayHighBound(Args, 1) do
      ASqlDs.Params[idx].Value := Args[idx];
    Result := True;
  except
    Result := False;
  end;
end;

//==| Função - Colocar Parâmetros |=============================================
function SetParamValues(var ASqlDs: TSQLDataSet; Args: array of const): Boolean; overload;
var
  idx : integer;
begin
  try
    for idx := 0 to High(Args) do
      case Args[idx].VType of
        { Numéricos }
        vtInteger:        ASqlDs.Params[idx].AsInteger  := Args[idx].VInteger;
        vtInt64:          ASqlDs.Params[idx].AsInteger  := Args[idx].VInt64^;
        vtExtended:       ASqlDs.Params[idx].AsFloat    := Args[idx].VExtended^;

        { Strings }
        vtChar:           ASqlDs.Params[idx].AsString   := Args[idx].VChar;
        vtString:         ASqlDs.Params[idx].AsString   := Args[idx].VString^;
        vtPChar:          ASqlDs.Params[idx].AsString   := Args[idx].VPChar;
        vtAnsiString:     ASqlDs.Params[idx].AsString   := string(Args[idx].VAnsiString);

        { Outros }
        vtObject:         ASqlDs.Params[idx].AsString   := Args[idx].VObject.ClassName;
        vtClass:          ASqlDs.Params[idx].AsString   := Args[idx].VClass.ClassName;
        vtBoolean:        ASqlDs.Params[idx].AsBoolean  := Args[idx].VBoolean;
        vtCurrency:       ASqlDs.Params[idx].AsCurrency := Args[idx].VCurrency^;
        vtVariant:        ASqlDs.Params[idx].Value      := Args[idx].VVariant^;
      end;
    Result := True;
  except
    Result := False;
  end;
end;
//==============================================================================

{$ENDIF}

end.

