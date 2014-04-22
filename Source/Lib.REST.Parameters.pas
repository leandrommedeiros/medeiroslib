{===============================================================================

                               REST PARAMETERS

============================================| Leandro Medeiros (16/04/2014) |==}

unit Lib.REST.Parameters;

interface

{ Bibliotecas para Interface }
uses
  System.Classes;

{ Classes }
type
  TRESTParameters = class(TObject)
  private
    function  GetParam(const AParamName: string): string;
    procedure SetParam(const AParamName, AValue: string); overload;
    function  GetValue(AIndex: Integer): string;
    procedure PutValue(AIndex: Integer; const AValue: string);
  public
    constructor Create;
    destructor Destroy;
    function Count: Integer;
    function ToString: string;
    procedure Clear;

    property Params[const AParamName: string]: string read GetParam write SetParam;
    property Strings[Index: Integer]: string read GetValue write PutValue; default;
  protected
    FParameters: TStringList;
  end;

implementation

{ Bibliotecas para implementação }
uses
  System.SysUtils;

{*******************************************************************************

                            MÉTODOS PRIVADOS

*******************************************************************************}

//==| Obter Parâmetro (Por Nome) |==============================================
function TRESTParameters.GetParam(const AParamName: string): string;
begin
  Result := Self.FParameters.Values['"' + AParamName + '"'];
end;

//==| Definir Parâmetro (Por Nome) |============================================
procedure TRESTParameters.SetParam(const AParamName, AValue: string);
begin
  Self.FParameters.Values['"' + AParamName + '"'] := '"' + AValue + '"';
end;

//==| Obter Parâmetro (Por Índice) |============================================
procedure TRESTParameters.PutValue(AIndex: Integer; const AValue: string);
begin
  Self.FParameters[AIndex] := AValue;
end;

//==| Definir Parâmetro (Por Índice) |==========================================
function TRESTParameters.GetValue(AIndex: Integer): string;
begin
  Result := Self.FParameters[AIndex];
end;


{*******************************************************************************

                            MÉTODOS PÚBLICOS

*******************************************************************************}

//==| Construtor |==============================================================
constructor TRESTParameters.Create;
begin
  inherited Create;

  Self.FParameters := TStringList.Create;
  Self.FParameters.NameValueSeparator := ':';
end;

//==| Destrutor |===============================================================
destructor TRESTParameters.Destroy;
begin
  System.SysUtils.FreeAndNil(Self.FParameters);

  inherited Destroy;
end;

//==| Função - Contar |=========================================================
function TRESTParameters.Count: Integer;
begin
  Result := Self.FParameters.Count;
end;

//==| Função - Para String |====================================================
function TRESTParameters.ToString: string;
var
  idx : integer;
begin
  Result := '';

  for idx := 0 to Self.FParameters.Count - 1 do
    Result := Result + ',' + Self[idx];

  System.Delete(Result, 1, 1);
  Result := '{' + Result + '}';
end;

//==| Procedimento - Limpar |===================================================
procedure TRESTParameters.Clear;
begin
  Self.FParameters.Clear;
end;
//==============================================================================

end.
