{===============================================================================

                             BIBLIOTECA - JSON

============================================| Leandro Medeiros (19/12/2012) |==}

unit Lib.JSON;

interface

{ Bibliotecas para Interface }
uses
  Data.DB, DataSnap.DBClient, System.SysUtils, Lib.JSON.Extended, System.JSON;

{ Constantes }
const
  JSON_NULL_VALUE  = '0';
  JSON_FALSE       = '0';
  JSON_NIL_VALUE   = 'nil';
  JSON_ERROR_VALUE = '1';

{ Protótipos }
  function  StrToJSONString(const AValue: string): string;
  procedure RecordToJSON(var ACds: TClientDataSet; var AJSON: System.JSON.TJSONObject;
    const FlagReinstance: Boolean = True); overload;
  function  RecordToJSON(var ACds: TClientDataSet): System.JSON.TJSONObject; overload;
  function  CdsToJSONArray(var ACds: TClientDataSet): System.JSON.TJSONArray;
  procedure JSONToCds(AJSON: System.JSON.TJSONObject; var ACds: TClientDataSet);
  function  GetJSONValue(const AObj, APropertyName: string;
    const ADefaultValue: string = ''): string; overload;

  function  GetJSONIntValue(const AObj, APropertyName: string;
    const ADefaultValue: integer = 0): integer; overload;
  function  GetJSONFloatValue(const AObj, APropertyName: string;
    const ADefaultValue: real = 0): real; overload;
  function  GetJSONBoolValue(const AObj, APropertyName: string;
    const ADefaultValue: Boolean = false): Boolean; overload;
  function  GetJsonDtValue(const AObj, APropertyName: string;
    const ADefaultValue: TDateTime = 0): TDateTime; overload;
  function  SanitizeString(const AText: string): string;
  function NewJSONToCds(ArqJson : String; Campos : array of string;
                                          Tipos   : array of Data.DB.TFieldType;
                                          Tamanho : array of integer) : TClientDataSet;

  { Depreciadas }
  function  GetJSONValue(const AObj: System.JSON.TJSONObject; const APropertyName: string;
    const ADefaultValue: string = ''): string; overload; deprecated 'Utilize a classe TExtendJSON';
  function  GetJSONIntValue(const AObj: System.JSON.TJSONObject; const APropertyName: string;
    const ADefaultValue: integer = 0): integer; overload; deprecated 'Utilize a classe TExtendJSON';
  function  GetJSONBoolValue(const AObj: System.JSON.TJSONObject; const APropertyName: string;
    const ADefaultValue: Boolean = false): Boolean; overload; deprecated 'Utilize a classe TExtendJSON';
  function  GetJsonDtValue(const AObj: System.JSON.TJSONObject; const APropertyName: string;
    const ADefaultValue: TDateTime = 0): TDateTime; overload; deprecated 'Utilize a classe TExtendJSON';

{ Implementação }
implementation

{ Bibliotecas para Implementação }
uses
  System.StrUtils, IdGlobalProtocols, Lib.Files;

{*******************************************************************************

                        FUNÇÕES E PROCEDIMENTOS

*******************************************************************************}

//==| Função - JSON para ClientDataSet |========================================
function NewJSONToCds(ArqJson : String; Campos  : array of string;
                                        Tipos   : array of Data.DB.TFieldType;
                                        Tamanho : array of integer) : TClientDataSet;
var
  jsonObj,jSubObj: System.JSON.TJSONObject;
  jp,jSubPar: System.JSON.TJSONPair;
  ja : System.JSON.TJSONArray;
  cdsInfos : TClientDataSet;
  I, J : Integer;
begin
//     jsonObj := System.JSON.TJSONObject(System.JSON.TJSONObject.ParseJSONValue(ArqJson) as System.JSON.TJSONObject);
     jsonObj := System.JSON.TJSONObject.ParseJSONValue(TEncoding.ASCII.GetBytes(ArqJson),0) as System.JSON.TJSONObject;  // Transformo O Texto Recebido em um Objeto JSon

     jp := System.JSON.TJSONPair.Create;                                        // Crio o Objeto Json Par
     jp := jsonObj.Get(0);                                                      //pega o par zero (Primeiro Retorno da String)

     ja := System.JSON.TJSONArray.Create;                                       // Crio um Objeto Json Array
     ja := nil;                                                                 // Libero Objeto Json Array
     ja := (jp.JsonValue as System.JSON.TJSONArray);                            // Transformo os Valores do Par 0 em um Array

     jSubObj:= System.JSON.TJSONObject.Create;                                  // Crio um Novo Objeto JsonObject
     jSubPar := System.JSON.TJSONPair.Create;                                   // Crio um Novo Objeto JsonPar

     if not Assigned(cdsInfos) then
       cdsInfos := TClientDataSet.Create(nil);                                  // Crio o Client

     cdsInfos.FieldDefs.Clear;
     for I := 0 to Length(Campos) -1 do
      begin
       if Tipos[I] = ftString then
        cdsInfos.FieldDefs.Add(Campos[I],Tipos[I],Tamanho[I])
       else
        cdsInfos.FieldDefs.Add(Campos[I],Tipos[I]);
      end;

     cdsInfos.CreateDataSet;

      for I := 0 to ja.Size -1  do                                              // Loop para varrer todos os registros da array
      begin
        jSubObj := (ja.Get(i) as TJSONObject);                                  // Transformo o Registro I da Array em um Objeto

        cdsInfos.Append;
        if Assigned(cdsInfos.FindField('transfer')) then
          cdsInfos.FieldByName('transfer').Value := 1;

        for J := 0 to jSubObj.Size -1 do
        begin
         jSubPar := jSubObj.Get(J);

         if Assigned(cdsInfos.FindField(jSubPar.JsonString.Value)) then
                cdsInfos.FieldByName(jSubPar.JsonString.Value).Value := jSubPar.JsonValue.Value;
        end;

       cdsInfos.Post;
      end;
      Result := cdsInfos;
end;

//==| Função - String Para Valor JSON |=========================================
function StrToJSONString(const AValue: string): string;
begin
//  Result := TEncoding.UTF8.GetBytes('{"value":"' + AValue + '"}');
  Result := '{"value":"' + AValue + '"}';
end;

{==| Procedimento - DbXpress para Objeto JSON |=================================
    Rotina que possibilita a rápida transposição de dados provenientes de uma
  consulta efetuada via DBExpress para um Objeto JSON (DataSnap).
  Parâmetros de Entrada:
    1. Dados a serem tranpostos : TClientDataSet.
    2. Objeto JSON de destino   : System.JSON.TJSONObject (ponteiro).
    3. Flag - Reinstanciar      : Booleano (Padrão Verdadeiro).
============================================| Leandro Medeiros (19/12/2012) |==}
procedure RecordToJSON(var ACds: TClientDataSet; var AJSON: System.JSON.TJSONObject;
  const FlagReinstance: Boolean = True);
var
  idx  : integer;
  sAux : string;
begin
  if FlagReinstance then
    AJSON := RecordToJSON(ACds)

  else if ACds.IsEmpty then
  begin
    AJSON.AddPair('error', JSON_ERROR_VALUE);
    Exit;
  end

  else begin
    for idx := 0 to ACds.Fields.Count - 1 do
    begin
      try
        sAux := ifthen(ACds.Fields[idx].IsNull or (ACds.Fields[idx].AsString = EmptyStr),
                       JSON_NULL_VALUE,
                       ACds.Fields[idx].AsString);
      except
        sAux := JSON_NULL_VALUE;
      end;

      AJSON.AddPair(ACds.Fields[idx].FieldName, sAux);
    end;
  end;
end;

{==| Função - DbXpress para Objeto JSON |=======================================
    Rotina que possibilita a rápida transposição de dados provenientes de uma
  consulta efetuada via DBExpress para um Objeto JSON (DataSnap).
  Parâmetros de Entrada:
    1. Dados a serem tranpostos : TClientDataSet.
  Retorno: Dados transpostos (System.JSON.TJSONObject).
============================================| Leandro Medeiros (19/12/2012) |==}
function RecordToJSON(var ACds: TClientDataSet): System.JSON.TJSONObject;
var
  idx  : integer;
  sAux : string;
begin
  Result := System.JSON.TJSONObject.Create;

  if ACds.IsEmpty then
  begin
    Result.AddPair('error', JSON_ERROR_VALUE);
    Exit;
  end;

  for idx := 0 to ACds.Fields.Count - 1 do
  begin
    try
      sAux := ifthen(ACds.Fields[idx].IsNull,
                     JSON_NULL_VALUE,
                     ACds.Fields[idx].AsString);
    except
      sAux := JSON_NULL_VALUE;
    end;

    if sAux <> EmptyStr then Result.AddPair(ACds.Fields[idx].FieldName, sAux);
  end;
end;

{==| Função - DbXpress para Matriz JSON |=======================================
    Rotina que possibilita a rápida transposição de dados provenientes de uma
  consulta efetuada via DBExpress para um Objeto JSON (DataSnap).
  Parâmetros de Entrada:
    1. Dados a serem tranpostos : TClientDataSet.
============================================| Leandro Medeiros (19/12/2012) |==}
function CdsToJSONArray(var ACds: TClientDataSet): System.JSON.TJSONArray;
var
  pBookmark  : TBookmark;
begin
  pBookmark := ACds.GetBookmark;
  ACds.First;

  Result := System.JSON.TJSONArray.Create;
  while not ACds.EOF do
  begin
    Result.AddElement(RecordToJSON(ACds));
    ACds.Next;
  end;

  try
    ACds.GotoBookmark(pBookmark);
  except
  end;
end;

//==| Função - JSON para ClientDataSet |========================================
procedure JSONToCds(AJSON: System.JSON.TJSONObject; var ACds: TClientDataSet);
var
  JsonObject, JsonSubObj: System.JSON.TJSONObject;
  JsonPair, JsonSubPair: System.JSON.TJSONPair;
  JsonArray: System.JSON.TJSONArray;
  oidx, vidx: Integer;
  fField, fAux: TField;
begin
  JsonObject := System.JSON.TJSONObject.ParseJSONValue(TEncoding.ASCII.GetBytes(AJson.ToString), 0) as System.JSON.TJSONObject;
  JsonPair   := JsonObject.Get(0);
  JsonArray  := (JsonPair.JsonValue as System.JSON.TJSONArray);

  for vidx := 0 to JsonArray.Size - 1 do
  begin
    JsonSubObj := System.JSON.TJSONObject(JsonArray.Get(vidx));
    for oidx := 0 to JsonSubObj.Size - 1 do
    begin
      JsonSubPair := JsonSubObj.Get(oidx);
      fField := ACds.FindField(JsonSubPair.JsonString.Value);

      if Assigned(fField) then
        fField.Value := JsonSubPair.JsonValue.Value
      else begin
        fAux       := TField.Create(ACds);
        fAux.Name  := JsonSubPair.JsonString.Value;
        fAux.Value := JsonSubPair.JsonString.Value;
        ACds.Fields.Add(fAux);
      end;
    end;
  end;
end;

//==| Obter Valor JSON Filtrado |===============================================
function GetJSONValue(const AObj, APropertyName: string;
  const ADefaultValue: string = ''): string; overload;
var
  jObj: TJSONExtended;
begin
  try
    jObj   := TJSONExtended.Create(AObj);
    Result := jObj.GetStr(APropertyName, ADefaultValue);
  except
    on e: exception do
      Lib.Files.Log('Erro ao interpretar String como JSON: ' + e.Message);
  end;
end;

//==| Obter Valor JSON Filtrado |===============================================
function GetJSONIntValue(const AObj, APropertyName: string;
  const ADefaultValue: integer = 0): integer; overload;
var
  jObj: TJSONExtended;
begin
  Result := 0;

  try
    jObj   := TJSONExtended.Create(AObj);
    Result := jObj.GetInt(APropertyName, ADefaultValue);
  except
    on e: exception do
      Lib.Files.Log('Erro ao interpretar String como JSON: ' + e.Message);
  end;
end;

//==| Obter Valor JSON Filtrado |===============================================
function GetJSONFloatValue(const AObj, APropertyName: string;
  const ADefaultValue: real = 0): real; overload;
var
  jObj: TJSONExtended;
begin
  Result := 0;

  try
    jObj   := TJSONExtended.Create(AObj);
    Result := jObj.GetFloat(APropertyName, ADefaultValue);
  except
    on e: exception do
      Lib.Files.Log('Erro ao interpretar String como JSON: ' + e.Message);
  end;
end;

//==| Obter Valor JSON Filtrado |===============================================
function GetJSONBoolValue(const AObj, APropertyName: string;
  const ADefaultValue: Boolean = false): Boolean; overload;
var
  jObj: TJSONExtended;
begin
  Result := False;

  try
    jObj   := TJSONExtended.Create(AObj);
    Result := jObj.GetBool(APropertyName, ADefaultValue);
  except
    on e: exception do
      Lib.Files.Log('Erro ao interpretar String como JSON: ' + e.Message);
  end;
end;

//==| Obter Valor JSON Filtrado |===============================================
function GetJsonDtValue(const AObj, APropertyName: string;
  const ADefaultValue: TDateTime = 0): TDateTime; overload;
var
  jObj: TJSONExtended;
begin
  Result := 0;

  try
    jObj   := TJSONExtended.Create(AObj);
    Result := jObj.GetDtTime(APropertyName, ADefaultValue);
  except
    on e: exception do
      Lib.Files.Log('Erro ao interpretar String como JSON: ' + e.Message);
  end;
end;

//==| Função - Sanitizar String |===============================================
function SanitizeString(const AText: string): string;
begin
  Result := StringReplace(AText,  '/', '\u002F', [rfReplaceAll]);
  Result := StringReplace(Result, '#', '\u0023', [rfReplaceAll]);
  Result := StringReplace(Result, 'Ç', '\u00C7', [rfReplaceAll]);
  Result := StringReplace(Result, 'ç', '\u00E7', [rfReplaceAll]);
end;


{ Depreciados }


//==| Obter Valor JSON Filtrado |===============================================
function GetJSONValue(const AObj: System.JSON.TJSONObject; const APropertyName: string;
  const ADefaultValue: string = ''): string; overload; deprecated 'Utilize a classe TExtendJSON';
begin
  if Assigned(AObj.Get(APropertyName)) then
    Result := Trim(UnquotedStr(AObj.Get(APropertyName).JsonValue.ToString))
  else
    Result := ADefaultValue;
end;

//==| Obter Valor JSON Filtrado |===============================================
function GetJSONIntValue(const AObj: System.JSON.TJSONObject; const APropertyName: string;
  const ADefaultValue: integer = 0): integer; overload; deprecated 'Utilize a classe TExtendJSON';
begin
  if Assigned(AObj.Get(APropertyName)) then
    Result := StrToInt(UnquotedStr(AObj.Get(APropertyName).JsonValue.ToString))
  else
    Result := ADefaultValue;
end;

//==| Obter Valor JSON Filtrado |===============================================
function GetJSONBoolValue(const AObj: System.JSON.TJSONObject; const APropertyName: string;
  const ADefaultValue: Boolean = false): Boolean; overload; deprecated 'Utilize a classe TExtendJSON';
begin
  if Assigned(AObj.Get(APropertyName)) then
    Result := StrToBool(UnquotedStr(AObj.Get(APropertyName).JsonValue.ToString))
  else
    Result := ADefaultValue;
end;

//==| Obter Valor JSON Filtrado |===============================================
function GetJsonDtValue(const AObj: System.JSON.TJSONObject; const APropertyName: string;
  const ADefaultValue: TDateTime = 0): TDateTime; overload; deprecated 'Utilize a classe TExtendJSON';
begin
  if Assigned(AObj.Get(APropertyName)) then
    Result := StrToDateTime(UnquotedStr(AObj.Get(APropertyName).JsonValue.ToString))

  else if ADefaultValue <> 0 then
    Result := ADefaultValue
  else
    Result := Now;
end;
//==============================================================================

end.
