{===============================================================================

                              ARRAY ASSOCIATIVO

============================================| Leandro Medeiros (16/04/2014) |==}

unit Lib.Utils.AssociativeArray;

interface

{ Bibliotecas para Interface }
uses
  System.Classes;

{ Classes }
type
  TAssociativeArray = class(TObject)
  private
    function  GetValue(const AFieldName: string): string;
    procedure SetValue(const AFieldName, AValue: string); overload;
    function  GetString(AIndex: Integer): string;
    procedure PutString(AIndex: Integer; const AValue: string);
  public
    constructor Create;
    destructor  Destroy;
    function  Count: Integer;
    procedure Clear;

    property Values[const AParamName: string]: string read GetValue write SetValue;
//    property Strings[Index: Integer]: string read GetString write PutString; default;
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

//==| Obter String (Por Nome) |=================================================
function TAssociativeArray.GetValue(const AFieldName: string): string;
begin
  Result := Self.FParameters.Values[AFieldName];
end;

//==| Definir String (Por Nome) |===============================================
procedure TAssociativeArray.SetValue(const AFieldName, AValue: string);
begin
  Self.FParameters.Values[AFieldName] := AValue;
end;

//==| Obter String (Por Índice) |===============================================
procedure TAssociativeArray.PutString(AIndex: Integer; const AValue: string);
begin
  Self.FParameters[AIndex] := AValue;
end;

//==| Definir String (Por Índice) |=============================================
function TAssociativeArray.GetString(AIndex: Integer): string;
begin
  Result := Self.FParameters[AIndex];
end;


{*******************************************************************************

                            MÉTODOS PÚBLICOS

*******************************************************************************}

//==| Construtor |==============================================================
constructor TAssociativeArray.Create;
begin
  inherited Create;

  Self.FParameters := TStringList.Create;
end;

//==| Destrutor |===============================================================
destructor TAssociativeArray.Destroy;
begin
  System.SysUtils.FreeAndNil(Self.FParameters);

  inherited Destroy;
end;

//==| Função - Contar |=========================================================
function TAssociativeArray.Count: Integer;
begin
  Result := Self.FParameters.Count;
end;

//==| Procedimento - Limpar |===================================================
procedure TAssociativeArray.Clear;
begin
  Self.FParameters.Clear;
end;
//==============================================================================

end.
