{===============================================================================

                            COMPONENTE - TSTREAMFILE

============================================| Leandro Medeiros (11/12/2012) |==}

unit Lib.Utils.StreamFile;

interface

{ Bibliotecas para Interface }
uses
  SysUtils, Classes;

{ Classes }
type
  TStreamFile = class(TComponent)
  private
    //Campos
    FFileName : String;
    FRefresh  : Boolean;

    //Variáveis
    DataStream: TMemoryStream;
  protected
    //Métodos Protegidos
    procedure SetFileName(AFileName: String);
    procedure DefineProperties(Filer: TFiler); override;
    procedure LoadData(Reader: TStream);
    procedure StoreData(Writer: TStream);
    procedure RefreshStream(const AValue: Boolean);
  public
    //Métodos públicos
    Constructor Create (Owner: TComponent); override;
    Destructor  Destroy; override;

    //Propriedades públicas
    property Data     : TMemoryStream read DataStream;
  published
    //Propriedades publicadas
    property FileName : String  read FFileName write SetFileName;
    property Refresh  : Boolean read FRefresh  write RefreshStream;
  end;

implementation

{ Bibliotecas para Interface }
uses
  Lib.Files, Dialogs;

{*******************************************************************************

                        IMPLEMENTAÇÃO - TSTREAMFILE

*******************************************************************************}

//==| Construtor |==============================================================
constructor TStreamFile.Create(Owner: TComponent);
begin
  inherited;

  DataStream := TMemoryStream.Create;
  FFileName  := EmptyStr;
end;

//==| Destrutor |===============================================================
Destructor TStreamFile.Destroy;
begin
  DataStream.Destroy;
  inherited;
end;

//==| Procedimento - Atualizar Stream |=========================================
procedure TStreamFile.RefreshStream(const AValue: Boolean);
var
  sAux : string;
begin
  sAux           := Self.FileName;
  Self.FFileName := EmptyStr;
  Self.FileName  := sAux;
end;

//==| Procedimento - Define nome do arquivo |===================================
procedure TStreamFile.SetFileName(AFileName: String);
begin
  if Self.FileName = AFileName then Exit;

  FFileName := AFileName;

  Self.DataStream.Clear;

  if (SysUtils.FileExists(AFileName)) then
  begin
    Self.DataStream.LoadFromFile(AFileName);

    Dialogs.ShowMessage(Self.Name
                       + ': ' + Lib.Files.BytesToMega(Self.Data.Size)
                       + ' carregados');
  end;
end;

//==| Procedimento - Carrega Dados |============================================
procedure TStreamFile.LoadData(Reader: TStream);
var
  lSize : Int64;
begin
  Self.DataStream.Clear;
  Reader.Read(lSize, System.SizeOf(lSize));
  Self.DataStream.CopyFrom(Reader, lSize);
end;

//==| Procedimento - Armazena Dados |===========================================
procedure TStreamFile.StoreData(Writer: TStream);
var
  lSize : Int64;
begin
  Self.DataStream.Position := 0;
  lSize                    := DataStream.Size;
  Writer.Write(lSize, System.SizeOf(lSize));
  Writer.CopyFrom(Self.DataStream, Self.DataStream.Size);
end;

//==| Procedimento - Define Propriedades |======================================
procedure TStreamFile.DefineProperties(Filer: TFiler);
//-- Função Deve armazenar
  function ShouldStore: Boolean;
  begin
    Result := (Self.DataStream.Size > 0);
  end;
begin
  inherited;

  Filer.DefineBinaryProperty('Data', LoadData, StoreData, ShouldStore);
end;
//==============================================================================

end.
