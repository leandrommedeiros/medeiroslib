{===============================================================================

                           BIBLIOTECA - Amazon S3

==========================================================| Vers�o 14.04.00 |==}

unit Lib.AwsS3;

interface

{ Bibliotecas para Interface }
uses
  System.SysUtils, Data.Cloud.AmazonAPI, Data.Cloud.CloudAPI, System.Classes;

{ Constantes }
const
  SMD_PATH       = 'originalfilepath';
  SMD_FROM       = 'uploadfrom';
  SMD_CREATED_BY = 'createdby';
  AMAZON_INDEX   = 0;
  BUCKET_PREFIX  = 'origem-%d';
  ERROR_UPLOADING_FILE    = 'Ocorreu um erro ao enviar arquivo "%s" para bucket "%s": "%s"';
  ERROR_DOWNLOADING_FILE  = 'Ocorreu um erro ao baixar arquivo "%s" para bucket "%s": "%s"';
{ Classes }
type
  TS3Connection = class(TAmazonConnectionInfo)
  private
    FBucketName    : string;
    StorageService : TAmazonStorageService;

    function ValidateFileName(const AFileName: string): string;
    function ValidateS3Path(const APath: string): string;
  public
    function EstablishConnection: Boolean; overload;
    function EstablishConnection(const AccountName, AccountKey,
      ABucketName: string): Boolean; overload;
    function Upload(ASourcePath: string; const ATargetDir, AFileName: String;
      ADelAfterTransfer: Boolean = False): Boolean;
    function Download(ASourcePath, ATargetPath, AFileName: String): Boolean;
    constructor Create(const AccountName, AccountKey, ABucketName: string); overload;
    destructor  Destroy; override;
  published
    property BucketName: string read FBucketName write FBucketName;
  end;

{ Prot�tipos - Procedimentos e Fun��es }
  function NewS3Connection(const AccountName, AccountKey, ABucketName: string;
    var bSuccess: Boolean): TS3Connection;


implementation

{ Bibliotecas para Implementa��o }
uses
  Lib.Files, Lib.Win, Lib.Utils, Vcl.Dialogs;


{*******************************************************************************

                          PROCEDIMENTOS E FUN��ES

*******************************************************************************}

//==| Nova Conex�o S3 |=========================================================
function NewS3Connection(const AccountName, AccountKey, ABucketName: string;
  var bSuccess: Boolean): TS3Connection;
begin
  try
    Result   := TS3Connection.Create(nil);
    bSuccess := Result.EstablishConnection(AccountName,
                                           AccountKey,
                                           ABucketName);
  except
    bSuccess := False;
  end;
end;


{*******************************************************************************

                              M�TODOS PRIVADOS

*******************************************************************************}

//==| Fun��o - Validar nome de arquivo |========================================
function TS3Connection.ValidateFileName(const AFileName: string): string;
begin
  Result := StringReplace(AFileName, ' ', '%20', [rfReplaceAll, rfIgnoreCase]);
end;

//==| Fun��o - Validar Diret�rio S3 |===========================================
function TS3Connection.ValidateS3Path(const APath: string): string;
begin
  Result := StringReplace(APath, ' ', '%20', [rfReplaceAll, rfIgnoreCase]);     //Substituo todos os espa�os pelo c�digo HTTP
  Result := StringReplace(Result, '\', '/', [rfReplaceAll, rfIgnoreCase]);      //e todas a barras invertidas por barras normais

  if Trim(APath[Length(Result)]) <> '/' then                                    //Se o �ltimo caractere da string n�o for uma barra
    Result := Trim(Result) + '/';                                               //vou acrescent�-la
end;


{*******************************************************************************

                              M�TODOS P�BLICOS

*******************************************************************************}

//==| Construtor |==============================================================
constructor TS3Connection.Create(const AccountName, AccountKey, ABucketName: string);
begin
  inherited Create(nil);

  Self.EstablishConnection(AccountName, AccountKey, ABucketName);
end;

//==| Destrutor |===============================================================
destructor TS3Connection.Destroy;
begin
  FreeAndNil(Self.StorageService);

  inherited Destroy;
end;

//==| Fun��o - Estabelecer Conex�o |============================================
function TS3Connection.EstablishConnection: Boolean;
begin
  try
    StorageService := TAmazonStorageService.Create(Self);
    Result         := True;
  except
    on e: Exception do
      Lib.Files.Log('Falha ao estabelecer conex�o com o S3: ' + e.Message);
  end;
end;

//==| Fun��o - Estabelecer Conex�o |============================================
function TS3Connection.EstablishConnection(const AccountName, AccountKey,
  ABucketName: string): Boolean;
begin
  Self.Protocol    := 'https';
  Self.AccountName := AccountName;
  Self.AccountKey  := AccountKey;
  Self.FBucketName := ABucketName;

  Result           := Self.EstablishConnection;
end;

//==| Fun��o - Upload |=========================================================
function TS3Connection.Upload(ASourcePath: string; const ATargetDir,
  AFileName: String; ADelAfterTransfer: Boolean = False): Boolean;
var
  sTargetFile   : string;
  slMetadata    : TStrings;
  FileContent   : TBytes;
  CloudResponse : TCloudResponseInfo;
begin
  Result := False;                                                              //Assumo falha

  if (AFileName = EmptyStr) then Exit;                                          //Se n�o for informado o nome de arquivo, finalizo a rotina

  try                                                                           //Tento
    if not Lib.Files.ValidateDir(ASourcePath, False) or                           //Validar o diret�rio de origem
       not System.SysUtils.DirectoryExists(ASourcePath) then                    //e se n�o existir
      raise Exception.Create('Diret�rio de origem ("' + ASourcePath + '") n�o existe ou est� inacess�vel.'); //disparo um erro

                                                                                //Se chegar aqui
    CloudResponse               := TCloudResponseInfo.Create;                   //instancio a classe respons�vel por receber o resultado de uma transfer�ncia
    slMetadata                  := TStringList.Create;                          //crio tamb�m um TStringList para guardar os metadados do arquivo
    slMetadata.Values[SMD_PATH] := ASourcePath;                                 //e atribuo � ele a origem,
    slMetadata.Values[SMD_FROM] := GetComputerandUserName;                      //o nome do computador e o nome de usu�rio
    FileContent                 := Lib.Files.LoadFile(ASourcePath + AFileName);   //Carrego o arquivo � ser enviado na RAM
    sTargetFile                 := Self.ValidateS3Path(ATargetDir)              //Valido o nome de arquivo de destino segundo regras do S3
                                 + Self.ValidateFileName(AFileName);

    try                                                                         //Tento
      Self.StorageService.UploadObject(Self.FBucketName,                        //Enviar o arquivo para a Bucket configurada na inst�ncia
                                       sTargetFile,                             //no destino validado
                                       FileContent,                             //a partir do Stream que montei em mem�ria
                                       False,
                                       slMetadata,
                                       nil,
                                       amzbaPublicRead,
                                       CloudResponse);                          //e fornecendo um objeto para ser alimentado com a situa��o da transfer�ncia

      case CloudResponse.StatusCode of                                          //Se o c�digo de situa��o
        200, 201: begin                                                         //for 200 ou 201
          Result := True;                                                       //� porque a transfer�ncia foi bem sucedida

          if ADelAfterTransfer then                                             //ent�o, se foi solicitado na chamada do m�todo,
            Lib.Files.ForceDelete(ASourcePath + AFileName);                     //apago o arquivo do disco de origem
        end

        else                                                                    //Sen�o
          Lib.Files.Log(Format(ERROR_UPLOADING_FILE,                            //gravo um log em disco com a mensagem retornada pela Amazon
                               [AFileName, Self.FBucketName, CloudResponse.StatusMessage]));
      end;
    except                                                                      //Se ocorrer um erro inesperado no processo
      on e: Exception do
        Lib.Files.Log(Format(ERROR_UPLOADING_FILE,                              //gravo um log tentando obter a mensagem do erro
                            [AFileName, Self.FBucketName, e.Message]));
    end;
  finally                                                                       //Ao final sempre
    FileContent := nil;                                                         //Limpo a refer�ncia para o arquivo em Stream, permitindo que a mem�ria seja liberada
    FreeAndNil(CloudResponse);                                                  //Destruo o objeto com o retorno da Cloud
    FreeAndNil(slMetadata);                                                     //e tamb�m a List com os metadados
  end;
end;

//==| Fun��o Download |=========================================================
function TS3Connection.Download(ASourcePath, ATargetPath, AFileName: String): Boolean;
var
  sSourceFile   : string;
  FileContent   : TFileStream;
  CloudResponse : TCloudResponseInfo;
begin
  Result := False;

  try
    Lib.Files.ValidateDir(ATargetPath);
    CloudResponse := TCloudResponseInfo.Create;
    sSourceFile   := Self.ValidateS3Path(ASourcePath)
                   + Self.ValidateFileName(AFileName);

    if not Lib.Files.CreatePublicFile(ATargetPath + AFileName, FileContent) then
    begin
      Lib.Files.Log('Falha ao gerar arquivo local');
      Exit;
    end;

    try
      StorageService.GetObject(Self.FBucketName,
                               sSourceFile,
                               FileContent,
                               CloudResponse);

      case CloudResponse.StatusCode of
        200, 201:
          Result := True;
        else
          Lib.Files.Log(Format(ERROR_DOWNLOADING_FILE,
                              [AFileName, Self.FBucketName, CloudResponse.StatusMessage]));
      end;
    except
      on e: Exception do
        Lib.Files.Log(Format(ERROR_DOWNLOADING_FILE,
                            [AFileName, Self.FBucketName, e.Message]));
    end;
  finally
    FreeAndNil(FileContent);
    FreeAndNil(CloudResponse);
  end;
end;
//==============================================================================

end.
