{===============================================================================

                           BIBLIOTECA - Amazon S3

==========================================================| Versão 14.04.00 |==}

unit Lib.AwsS3;

interface

{ Bibliotecas para Interface }
uses
  System.SysUtils, Data.Cloud.AmazonAPI, Data.Cloud.CloudAPI, System.Classes;

{ Constantes }
const
  SMD_PATH       = 'originalfilepath';
  SMD_FROM       = 'uploadfrom';
  SMD_SIZE       = 'Content-Length';
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
    function GetFileSize(const ATargetDir, AFileName: string): Integer;
    function Upload(ASourcePath: string; const ATargetDir, AFileName: String;
      ADelAfterTransfer: Boolean = False; ATries: integer = 3): Boolean;
    function MultipartUpload(ASourcePath: string; const ATargetDir, AFileName: String;
      ADelAfterTransfer: Boolean = False): Boolean;
    function Download(ASourcePath, ATargetPath, AFileName: String): Boolean;

    constructor Create(const AccountName, AccountKey, ABucketName: string); overload;
    destructor  Destroy; override;
  published
    property BucketName: string read FBucketName write FBucketName;
  end;

{ Protótipos - Procedimentos e Funções }
  function NewS3Connection(const AccountName, AccountKey, ABucketName: string;
    out ASuccess: Boolean): TS3Connection;


implementation

{ Bibliotecas para Implementação }
uses
  Lib.StrUtils, Lib.Files, Lib.Win, Lib.Utils, Vcl.Dialogs, IPPeerClient;


{*******************************************************************************

                          PROCEDIMENTOS E FUNÇÕES

*******************************************************************************}

//==| Nova Conexão S3 |=========================================================
function NewS3Connection(const AccountName, AccountKey, ABucketName: string;
  out ASuccess: Boolean): TS3Connection;
begin
  try
    Result   := TS3Connection.Create(nil);
    ASuccess := Result.EstablishConnection(AccountName,
                                           AccountKey,
                                           ABucketName);
  except
    ASuccess := False;
  end;
end;


{*******************************************************************************

                              MÉTODOS PRIVADOS

*******************************************************************************}

//==| Função - Validar nome de arquivo |========================================
function TS3Connection.ValidateFileName(const AFileName: string): string;
begin
  Result := StringReplace(AFileName, ' ', '%20', [rfReplaceAll, rfIgnoreCase]);
end;

//==| Função - Validar Diretório S3 |===========================================
function TS3Connection.ValidateS3Path(const APath: string): string;
begin
  Result := StringReplace(APath, ' ', '%20', [rfReplaceAll, rfIgnoreCase]);     //Substituo todos os espaços pelo código HTTP
  Result := StringReplace(Result, '\', '/', [rfReplaceAll, rfIgnoreCase]);      //e todas a barras invertidas por barras normais

  if Trim(APath[Length(Result)]) <> '/' then                                    //Se o último caractere da string não for uma barra
    Result := Trim(Result) + '/';                                               //vou acrescentá-la
end;


{*******************************************************************************

                              MÉTODOS PÚBLICOS

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

//==| Função - Estabelecer Conexão |============================================
function TS3Connection.EstablishConnection: Boolean;
begin
  Result := False;

  try
    Self.StorageService := TAmazonStorageService.Create(Self);
    Result              := True;
  except
    on e: Exception do
      Lib.Files.Log('Falha ao estabelecer conexão com o S3: ' + e.Message);
  end;
end;

//==| Função - Estabelecer Conexão |============================================
function TS3Connection.EstablishConnection(const AccountName, AccountKey,
  ABucketName: string): Boolean;
begin
  Self.Protocol    := 'https';
  Self.AccountName := AccountName;
  Self.AccountKey  := AccountKey;
  Self.FBucketName := ABucketName;

  Result           := Self.EstablishConnection;
end;

//==| Função - Obter tamanho do Arquivo |=======================================
function TS3Connection.GetFileSize(const ATargetDir, AFileName: string): Integer;
var
  sMetadata,
  sProperties   : TStrings;
  sFileName     : string;
  CloudResponse : TCloudResponseInfo;
begin
  Result := 0;

  CloudResponse := TCloudResponseInfo.Create;                                   //instancio a classe responsável por receber o resultado de uma transferência

  try
    sFileName := Self.ValidateS3Path(ATargetDir)                                //Valido o nome de arquivo de destino segundo regras do S3
               + Self.ValidateFileName(AFileName);

    Self.StorageService.GetObjectProperties(Self.FBucketName,
                                            sFileName,
                                            sProperties,
                                            sMetadata,
                                            CloudResponse);

    case CloudResponse.StatusCode of                                            //Se o código de situação
      200, 201: begin                                                           //for 200 ou 201
         TryStrToInt(Lib.StrUtils.ReturnValidChars(sProperties[7], sNumbers), Result);
      end;
    end;
  except                                                                        //Se ocorrer um erro inesperado no processo
    on e: Exception do
      Lib.Files.Log(Format(ERROR_UPLOADING_FILE,                                //gravo um log tentando obter a mensagem do erro
                          [AFileName, Self.FBucketName, e.Message]));
  end;
end;

//==| Função - Upload |=========================================================
function TS3Connection.Upload(ASourcePath: string; const ATargetDir,
  AFileName: String; ADelAfterTransfer: Boolean = False;
  ATries: integer = 3): Boolean;

{ Variáveis }
var
  sTargetFile   : string;
  slMetadata    : TStrings;
  FileContent   : TBytes;
  CloudResponse : TCloudResponseInfo;

{ Finalizar Conexões }
procedure FinishConnection;
begin
  FileContent := nil;                                                           //Limpo a referência para o arquivo em Stream, permitindo que a memória seja liberada
  FreeAndNil(CloudResponse);                                                    //Destruo o objeto com o retorno da Cloud
  FreeAndNil(slMetadata);                                                       //e também a List com os metadados
end;

{ Início de Rotina }
begin
  Result := False;                                                              //Assumo falha

  if (AFileName = EmptyStr) then Exit;                                          //Se não for informado o nome de arquivo, finalizo a rotina

  try                                                                           //Tento
    if not Lib.Files.ValidateDir(ASourcePath, False) or                           //Validar o diretório de origem
       not System.SysUtils.DirectoryExists(ASourcePath) then                    //e se não existir
      raise Exception.Create('Diretório de origem ("' + ASourcePath + '") não existe ou está inacessível.'); //disparo um erro

                                                                                //Se chegar aqui
    CloudResponse               := TCloudResponseInfo.Create;                   //instancio a classe responsável por receber o resultado de uma transferência
    slMetadata                  := TStringList.Create;                          //crio também um TStringList para guardar os metadados do arquivo
    slMetadata.Values[SMD_PATH] := ASourcePath;                                 //e atribuo à ele a origem,
    slMetadata.Values[SMD_FROM] := GetComputerandUserName;                      //o nome do computador e o nome de usuário
    slMetadata.Values[SMD_SIZE] := IntToStr(Lib.Files.GetFileSizeB(ASourcePath + AFileName)); //e o tamanho
    FileContent                 := Lib.Files.LoadFile(ASourcePath + AFileName); //Então carrego o arquivo à ser enviado na RAM
    sTargetFile                 := Self.ValidateS3Path(ATargetDir)              //Valido o nome de arquivo de destino segundo regras do S3
                                 + Self.ValidateFileName(AFileName);

    try                                                                         //Tento
      Self.StorageService.UploadObject(Self.FBucketName,                        //Enviar o arquivo para a Bucket configurada na instância
                                       sTargetFile,                             //no destino validado
                                       FileContent,                             //a partir do Stream que montei em memória
                                       False,
                                       slMetadata,
                                       nil,
                                       amzbaPublicRead,
                                       CloudResponse);                          //e fornecendo um objeto para ser alimentado com a situação da transferência

      case CloudResponse.StatusCode of                                          //Se o código de situação
        200, 201, 304: begin                                                    //for de sucesso
          Result := True;                                                       //retorno verdadeiro

          if ADelAfterTransfer then                                             //então, se foi solicitado na chamada do método,
            Lib.Files.ForceDelete(ASourcePath + AFileName);                     //apago o arquivo do disco de origem
        end

        else begin                                                              //Senão
          Lib.Files.Log(Format(ERROR_UPLOADING_FILE,                            //gravo um log em disco com a mensagem de erro retornada pelo host
                               [AFileName, Self.FBucketName, CloudResponse.StatusMessage]));

          Inc(ATries, - 1);                                                     //decremento o número de tentativas

          if ATries > 0 then                                                    //e se ainda não tiver feito todas as tentativas
          begin
            Sleep(3000);                                                        //aguardo 3 segundos
            Result := Self.Upload(ASourcePath, ATargetDir, AFileName, ADelAfterTransfer, ATries); //executo o método recursivamente
            FinishConnection;                                                   //finalizo as conexões
            Exit;                                                               //e então saio do método
          end;
        end;
      end;
    except                                                                      //Se ocorrer um erro inesperado no processo
      on e: Exception do
      begin
        Lib.Files.Log(Format(ERROR_UPLOADING_FILE,                              //gravo um log tentando obter a mensagem do erro
                            [AFileName, Self.FBucketName, e.Message]));

        Inc(ATries, - 1);                                                       //decremento o número de tentativas

        if ATries > 0 then                                                      //e se ainda não tiver feito todas as tentativas
        begin
          Sleep(3000);                                                          //aguardo 3 segundos
          Result := Self.Upload(ASourcePath, ATargetDir, AFileName, ADelAfterTransfer, ATries); //executo o método recursivamente
          FinishConnection;                                                     //finalizo as conexões
          Exit;                                                                 //e então saio do método
        end;
      end;
    end;
  finally
    FinishConnection;
  end;
end;

//==| Função - Upload Particionado |============================================
function TS3Connection.MultipartUpload(ASourcePath: string; const ATargetDir,
  AFileName: String; ADelAfterTransfer: Boolean = False): Boolean;
var
  sTargetFile   : string;
  slMetadata    : TStrings;
  FileContent   : TBytes;
  CloudResponse : TCloudResponseInfo;
begin
  Result := False;                                                              //Assumo falha

  if (AFileName = EmptyStr) then Exit;                                          //Se não for informado o nome de arquivo, finalizo a rotina

  try                                                                           //Tento
    if not Lib.Files.ValidateDir(ASourcePath, False) or                           //Validar o diretório de origem
       not System.SysUtils.DirectoryExists(ASourcePath) then                    //e se não existir
      raise Exception.Create('Diretório de origem ("' + ASourcePath + '") não existe ou está inacessível.'); //disparo um erro

                                                                                //Se chegar aqui
    CloudResponse               := TCloudResponseInfo.Create;                   //instancio a classe responsável por receber o resultado de uma transferência
    slMetadata                  := TStringList.Create;                          //crio também um TStringList para guardar os metadados do arquivo
    slMetadata.Values[SMD_PATH] := ASourcePath;                                 //e atribuo à ele a origem,
    slMetadata.Values[SMD_FROM] := GetComputerandUserName;                      //o nome do computador e o nome de usuário
    FileContent                 := Lib.Files.LoadFile(ASourcePath + AFileName); //Carrego o arquivo à ser enviado na RAM
    sTargetFile                 := Self.ValidateS3Path(ATargetDir)              //Valido o nome de arquivo de destino segundo regras do S3
                                 + Self.ValidateFileName(AFileName);

    try                                                                         //Tento
      Self.StorageService.UploadObject(Self.FBucketName,                        //Enviar o arquivo para a Bucket configurada na instância
                                       sTargetFile,                             //no destino validado
                                       FileContent,                             //a partir do Stream que montei em memória
                                       False,
                                       slMetadata,
                                       nil,
                                       amzbaPublicRead,
                                       CloudResponse);                          //e fornecendo um objeto para ser alimentado com a situação da transferência

      case CloudResponse.StatusCode of                                          //Se o código de situação
        200, 201: begin                                                         //for 200 ou 201
          Result := True;                                                       //é porque a transferência foi bem sucedida

          if ADelAfterTransfer then                                             //então, se foi solicitado na chamada do método,
            Lib.Files.ForceDelete(ASourcePath + AFileName);                     //apago o arquivo do disco de origem
        end

        else                                                                    //Senão
          Lib.Files.Log(Format(ERROR_UPLOADING_FILE,                            //gravo um log em disco com a mensagem retornada pela Amazon
                               [AFileName, Self.FBucketName, CloudResponse.StatusMessage]));
      end;
    except                                                                      //Se ocorrer um erro inesperado no processo
      on e: Exception do
        Lib.Files.Log(Format(ERROR_UPLOADING_FILE,                              //gravo um log tentando obter a mensagem do erro
                            [AFileName, Self.FBucketName, e.Message]));
    end;
  finally                                                                       //Ao final sempre
    FileContent := nil;                                                         //Limpo a referência para o arquivo em Stream, permitindo que a memória seja liberada
    FreeAndNil(CloudResponse);                                                  //Destruo o objeto com o retorno da Cloud
    FreeAndNil(slMetadata);                                                     //e também a List com os metadados
  end;
end;

//==| Função Download |=========================================================
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
