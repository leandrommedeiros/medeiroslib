{===============================================================================

                            COMPONENTE - TSTREAMFILE

============================================| Leandro Medeiros (11/12/2012) |==}

unit Lib.Utils.StreamFile;

interface

uses
  SysUtils, Classes;

//==| Classe - Arquivo Embutido |===============================================
type
  TStreamFile = class(TComponent)
  private
    //Campos
    FFileName: String;

    //Variáveis
    DataStream: TMemoryStream;
  protected
    //Métodos Protegidos
    procedure   SetFileName(AFileName: String);
    procedure   DefineProperties(Filer: TFiler); override;
    procedure   LoadData(Reader: TStream);
    procedure   StoreData(Writer: TStream);
  public
    //Métodos públicos
    Constructor Create (Owner: TComponent); override;
    Destructor  Destroy; override;

    //Propriedades públicas
    property    Data: TMemoryStream read DataStream;
  published
    //Propriedades publicadas
    property    FileName: String read FFileName write SetFileName;
  end;

implementation

{*******************************************************************************

                          IMPLEMENTAÇÃO - TTELERAD

*******************************************************************************}

//==| Construtor |==============================================================
Constructor TStreamFile.Create(Owner: TComponent);
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

//==| Procedimento - Define nome do arquivo |===================================
procedure TStreamFile.SetFileName(AFileName: String);
begin
  if FileName = AFileName then Exit;

  FFileName := AFileName;
  DataStream.Clear;
  if (FileExists(AFileName)) then DataStream.LoadFromFile(AFileName);
end;

//==| Procedimento - Carrega Dados |============================================
procedure TStreamFile.LoadData(Reader: TStream);
var
  lSize : Int64;
begin
  DataStream.Clear;
  Reader.Read(lSize, SizeOf(lSize));
  DataStream.CopyFrom(Reader, lSize);
end;

//==| Procedimento - Armazena Dados |===========================================
procedure TStreamFile.StoreData(Writer: TStream);
var
  lSize : Int64;
begin
  DataStream.Position := 0;
  lSize               := DataStream.Size;
  Writer.Write(lSize, SizeOf(lSize));
  Writer.CopyFrom(DataStream, DataStream.Size);
end;

//==| Procedimento - Define Propriedades |======================================
procedure TStreamFile.DefineProperties(Filer: TFiler);
//-- Função Deve armazenar
  function ShouldStore: Boolean;
  begin
    Result := (DataStream.Size > 0);
  end;
begin
  inherited;
  Filer.DefineBinaryProperty('Data', LoadData, StoreData, ShouldStore);
end;
//==============================================================================

end.
