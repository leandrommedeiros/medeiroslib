{===============================================================================

                           BIBLIOTECA - Amazon S3

==========================================================| Vers�o 14.04.00 |==}

unit Lib.AwsS3;

interface

{ Bibliotecas para Interface }
uses
  Lib.Files, System.SysUtils, Data.Cloud.AmazonAPI, Data.Cloud.CloudAPI,
  System.Classes;

{ Constantes }
const
  SMD_PATH       = 'originalfilepath';
  SMD_FROM       = 'uploadfrom';
  SMD_SIZE       = 'Content-Length';
  SMD_CHECKSUM   = 'Content-MD5';
  SMD_CREATED_BY = 'createdby';
  AMAZON_INDEX   = 0;
  ERROR_UPLOADING_FILE    = 'Ocorreu um erro ao enviar arquivo "%s" para bucket "%s": "%s"';
  ERROR_DOWNLOADING_FILE  = 'Ocorreu um erro ao baixar arquivo "%s" para bucket "%s": "%s"';


{ Classes }
type
  //Eventos
  TS3MultipartOnWorkBegin = procedure(const APartsCount: integer) of Object;
  TS3MultipartOnWork      = procedure(const ACurrentPart, APackageSize: integer) of Object;
  TS3MultipartOnWorkEnd   = procedure of Object;

  //Conex�o S3
  TS3Connection = class(TAmazonConnectionInfo)
  private
    //Eventos
    FOnMultipartWorkBegin : TS3MultipartOnWorkBegin;
    FOnMultipartWork      : TS3MultipartOnWork;
    FOnMultipartWorkEnd   : TS3MultipartOnWorkEnd;

    //Campos
    FBucketName    : string;

    //Vari�veis
    StorageService : TAmazonStorageService;

    function ValidateFileName(const AFileName: string): string;
    function ValidateS3Path(const APath: string): string;
  public
    function EstablishConnection: Boolean; overload;
    function EstablishConnection(const AccountName, AccountKey,
      ABucketName: string): Boolean; overload;
    function GetFileSize(const ATargetDir, AFileName: string): Integer;
    function Upload(ASourcePath: string; const ATargetDir, AFileName: String;
      const ADelAfterTransfer: Boolean = False; ATries: integer = 3): Boolean;
    function MultipartUpload(ASourcePath: string; const ATargetDir, AFileName: String;
      APackageSize: integer = FIVE_MEGABYTES; const ADelAfterTransfer: Boolean = False;
      const ATries: integer = 3): Boolean;
    function Download(ASourcePath, ATargetPath, AFileName: String): Boolean;
    function ListBuckets: TStrings;

    constructor Create(const AccountName, AccountKey, ABucketName: string); overload;
    destructor  Destroy; override;
  published
    property BucketName           : string                  read FBucketName           write FBucketName;
    property OnMultipartWorkBegin : TS3MultipartOnWorkBegin read FOnMultipartWorkBegin write FOnMultipartWorkBegin;
    property OnMultipartWork      : TS3MultipartOnWork      read FOnMultipartWork      write FOnMultipartWork;
    property OnMultipartWorkEnd   : TS3MultipartOnWorkEnd   read FOnMultipartWorkEnd   write FOnMultipartWorkEnd;
  end;

{ Prot�tipos - Procedimentos e Fun��es }
  function NewS3Connection(const AccountName, AccountKey, ABucketName: string;
    out ASuccess: Boolean): TS3Connection;


implementation

{ Bibliotecas para Implementa��o }
uses
  Lib.StrUtils, Lib.Win, Lib.Utils, Vcl.Dialogs, IPPeerClient,
  Datasnap.DBClient, System.Generics.Collections, Xml.XMLIntf, Xml.XMLDoc,
  Winapi.Windows, Winapi.ActiveX;


{*******************************************************************************

                          PROCEDIMENTOS E FUN��ES

*******************************************************************************}

//==| Nova Conex�o S3 |=========================================================
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
  if APath = EmptyStr then Exit;
  
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
  Result := False;

  try
    Self.StorageService := TAmazonStorageService.Create(Self);
    Result              := True;
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

//==| Fun��o - Obter tamanho do Arquivo |=======================================
function TS3Connection.GetFileSize(const ATargetDir, AFileName: string): Integer;
var
  sMetadata,
  sProperties   : TStrings;
  sFileName     : string;
  CloudResponse : TCloudResponseInfo;
begin
  Result := 0;

  try
    CloudResponse := TCloudResponseInfo.Create;                                 //instancio a classe respons�vel por receber o resultado de uma transfer�ncia
    sMetadata     := TStringList.Create;
    sProperties   := TStringList.Create;
    sFileName     := Self.ValidateS3Path(ATargetDir)                            //Valido o nome de arquivo de destino segundo regras do S3
                   + Self.ValidateFileName(AFileName);

    Self.StorageService.GetObjectProperties(Self.FBucketName,
                                            sFileName,
                                            sProperties,
                                            sMetadata,
                                            CloudResponse);

    case CloudResponse.StatusCode of                                            //Se o c�digo de situa��o
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

//==| Listar Buckets |==========================================================
function TS3Connection.ListBuckets: TStrings;
var
  XML    : string;
  XMLDoc : IXMLDocument;
  ResultNode,
  BucketNode,
  Aux    : IXMLNode;
begin
  Result := nil;
  XML    := Self.StorageService.ListBucketsXML(nil);

  if XML <> EmptyStr then
  begin
    XMLDoc := TXMLDocument.Create(nil);

    try
      XMLDoc.LoadFromXML(XML);
    except
      Exit(Result);
    end;

    ResultNode := XMLDoc.DocumentElement.ChildNodes.FindNode('Buckets');

    if ResultNode <> nil then
    begin
      Result := TStringList.Create;

      if not ResultNode.HasChildNodes then
        Exit(Result);

      BucketNode := ResultNode.ChildNodes.First;

      while BucketNode <> nil do
      begin
        if AnsiSameText(BucketNode.NodeName, 'Bucket') and BucketNode.HasChildNodes then
        begin
          Aux := BucketNode.ChildNodes.FindNode('Name');

          if (Aux <> nil) and Aux.IsTextElement then Result.Add(Aux.Text);
        end;

        BucketNode := BucketNode.NextSibling;
      end;
    end;
  end;end;

//==| Fun��o - Upload |=========================================================
function TS3Connection.Upload(ASourcePath: string; const ATargetDir,
  AFileName: String; const ADelAfterTransfer: Boolean = False;
  ATries: integer = 3): Boolean;

{ Vari�veis }
var
  sTargetFile   : string;
  slMetadata    : TStringList;
  FileContent   : TBytes;
  CloudResponse : TCloudResponseInfo;

{ Finalizar Conex�es }
procedure FinishConnection;
begin
  FileContent := nil;                                                           //Limpo a refer�ncia para o arquivo em Stream, permitindo que a mem�ria seja liberada
  FreeAndNil(CloudResponse);                                                    //Destruo o objeto com o retorno da Cloud
  FreeAndNil(slMetadata);                                                       //e tamb�m a List com os metadados
end;

{ In�cio de Rotina }
begin
  Result := False;                                                              //Assumo falha

  if (AFileName = EmptyStr) then Exit;                                          //Se n�o for informado o nome de arquivo, finalizo a rotina

  try                                                                           //Tento
    if not Lib.Files.ValidateDir(ASourcePath, False) or                         //Validar o diret�rio de origem
       not System.SysUtils.DirectoryExists(ASourcePath) then                    //e se n�o existir
      raise Exception.Create('Diret�rio de origem ("' + ASourcePath + '") n�o existe ou est� inacess�vel.'); //disparo um erro

                                                                                //Se chegar aqui
    CloudResponse               := TCloudResponseInfo.Create;                   //instancio a classe respons�vel por receber o resultado de uma transfer�ncia
    slMetadata                  := TStringList.Create;                          //crio tamb�m um TStringList para guardar os metadados do arquivo
    slMetadata.Values[SMD_PATH] := ASourcePath;                                 //e atribuo � ele a origem,
    slMetadata.Values[SMD_FROM] := GetComputerandUserName;                      //o nome do computador e o nome de usu�rio
    slMetadata.Values[SMD_SIZE] := IntToStr(Lib.Files.GetFileSizeB(ASourcePath + AFileName)); //e o tamanho
    FileContent                 := Lib.Files.LoadFile(ASourcePath + AFileName); //Ent�o carrego o arquivo � ser enviado na RAM
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
        200, 201, 304: begin                                                    //for de sucesso
          Result := True;                                                       //retorno verdadeiro

          if ADelAfterTransfer then                                             //ent�o, se foi solicitado na chamada do m�todo,
            Lib.Files.ForceDelete(ASourcePath + AFileName);                     //apago o arquivo do disco de origem
        end

        else begin                                                              //Sen�o
          Lib.Files.Log(Format(ERROR_UPLOADING_FILE,                            //gravo um log em disco com a mensagem de erro retornada pelo host
                               [AFileName, Self.FBucketName, CloudResponse.StatusMessage]));

          Inc(ATries, - 1);                                                     //decremento o n�mero de tentativas

          if ATries > 0 then                                                    //e se ainda n�o tiver feito todas as tentativas
          begin
            Sleep(3000);                                                        //aguardo 3 segundos
            Result := Self.Upload(ASourcePath, ATargetDir, AFileName, ADelAfterTransfer, ATries); //executo o m�todo recursivamente
            FinishConnection;                                                   //finalizo as conex�es
            Exit;                                                               //e ent�o saio do m�todo
          end;
        end;
      end;
    except                                                                      //Se ocorrer um erro inesperado no processo
      on e: Exception do
      begin
        Lib.Files.Log(Format(ERROR_UPLOADING_FILE,                              //gravo um log tentando obter a mensagem do erro
                            [AFileName, Self.FBucketName, e.Message]));

        Inc(ATries, - 1);                                                       //decremento o n�mero de tentativas

        if ATries > 0 then                                                      //e se ainda n�o tiver feito todas as tentativas
        begin
          Sleep(3000);                                                          //aguardo 3 segundos
          Result := Self.Upload(ASourcePath, ATargetDir, AFileName, ADelAfterTransfer, ATries); //executo o m�todo recursivamente
          FinishConnection;                                                     //finalizo as conex�es
          Exit;                                                                 //e ent�o saio do m�todo
        end;
      end;
    end;
  finally
    FinishConnection;
  end;
end;

//==| Fun��o - Upload Particionado |============================================
function TS3Connection.MultipartUpload(ASourcePath: string; const ATargetDir,
  AFileName: String; APackageSize: integer = FIVE_MEGABYTES;
  const ADelAfterTransfer: Boolean = False; const ATries: integer = 3): Boolean;
var
  slMetadata,
  slHeaders     : TStrings;
  iTries,
  iPartNo,
  iTotalParts   : integer;
  sUploadID,
  sBufferMD5,
  sTargetFile   : string;
  lgUploaded    : Boolean;
  Buffer        : TBytes;
  CloudResponse : TCloudResponseInfo;
  UploadedPart  : TAmazonMultipartPart;
  PartsList     : System.Generics.Collections.TList<TAmazonMultipartPart>;

procedure FinishConnection;
begin
  if Assigned(Self.OnMultipartWorkEnd) then Self.OnMultipartWorkEnd;
  Buffer := nil;                                                                //Limpo a refer�ncia para o arquivo em Stream, permitindo que a mem�ria seja liberada
  FreeAndNil(CloudResponse);                                                    //Destruo o objeto com o retorno da Cloud,
  FreeAndNil(slMetadata);                                                       //a List com os metadados
  FreeAndNil(slHeaders);                                                        //e tamb�m a List com os cabe�alhos
end;

begin
  Result := False;                                                              //Assumo falha

  if (AFileName = EmptyStr) then Exit;                                          //Se n�o for informado o nome de arquivo, finalizo a rotina

  try                                                                           //Tento
    if not Lib.Files.ValidateDir(ASourcePath, False) or                         //Validar o diret�rio de origem
       not System.SysUtils.DirectoryExists(ASourcePath) then                    //e se n�o existir
      raise Exception.Create('Diret�rio de origem ("' + ASourcePath + '") n�o existe ou est� inacess�vel.'); //disparo um erro

                                                                                //Se chegar aqui
    CloudResponse               := TCloudResponseInfo.Create;                   //instancio a classe respons�vel por receber o resultado de uma transfer�ncia
    slMetadata                  := TStringList.Create;                          //crio tamb�m um TStringList para guardar os metadados do arquivo
    slMetadata.Values[SMD_PATH] := ASourcePath;                                 //e atribuo � ele a origem,
    slMetadata.Values[SMD_FROM] := GetComputerandUserName;                      //o nome do computador e o nome de usu�rio
    slHeaders                   := TStringList.Create;
    sTargetFile                 := Self.ValidateS3Path(ATargetDir)              //Valido o nome de arquivo de destino segundo regras do S3
                                 + Self.ValidateFileName(AFileName);
    PartsList                   := TList<TAmazonMultipartPart>.Create;

    if APackageSize < FIVE_MEGABYTES then
      APackageSize := FIVE_MEGABYTES;

    iTotalParts := (Lib.Files.GetFileSizeB(ASourcePath + AFileName)
                    div APackageSize) + 1;

    while (iTotalParts >= 10000) do
    begin
      APackageSize := APackageSize + FIVE_MEGABYTES;
      iTotalParts  := (Lib.Files.GetFileSizeB(ASourcePath + AFileName)
                       div APackageSize) + 1;
    end;

    CoInitialize(nil);

    sUploadID := Self.StorageService.InitiateMultipartUpload(Self.FBucketName,
                                                             sTargetFile,
                                                             slMetadata,
                                                             slHeaders,
                                                             amzbaPublicRead,
                                                             CloudResponse);

    try                                                                         //Tento
      if Assigned(Self.OnMultipartWorkBegin) then
        Self.OnMultipartWorkBegin(iTotalParts);

      for iPartNo := 1 to iTotalParts do
      begin
        if LoadFilePart(Buffer, ASourcePath + AFileName, ((iPartNo - 1) * APackageSize), APackageSize) then
        begin
          if Length(Buffer) > 0 then
          begin
            lgUploaded := False;
            iTries     := ATries;
            sBufferMD5 := '"' + Lib.StrUtils.MD5(Buffer) + '"';

            while not lgUploaded and Bool(iTries) do
            begin
              if Self.StorageService.UploadPart(Self.FBucketName,
                                                sTargetFile,
                                                sUploadID,
                                                iPartNo,
                                                Buffer,
                                                UploadedPart) and
                (UploadedPart.ETag = sBufferMD5) then
              begin
                Buffer     := nil;
                lgUploaded := True;
                PartsList.Add(UploadedPart);
                if Assigned(Self.OnMultipartWork) then
                  Self.OnMultipartWork(iPartNo, APackageSize);
              end

              else if Bool(iTries) then
              begin
                Dec(iTries, 1);
                Sleep(1000);
              end

              else begin
                Self.StorageService.AbortMultipartUpload(Self.FBucketName, sTargetFile, sUploadID);
                FinishConnection;
              end;
            end;
          end;
        end;
      end;

      if Self.StorageService.CompleteMultipartUpload(Self.FBucketName,
                                                     sTargetFile,
                                                     sUploadID,
                                                     PartsList,
                                                     CloudResponse) then
      begin
        Result := True;                                                         //Se a transfer�ncia foi bem sucedida, Retorno Verdadeiro

        if ADelAfterTransfer then                                               //ent�o, se foi solicitado na chamada do m�todo,
          Lib.Files.ForceDelete(ASourcePath + AFileName);                       //apago o arquivo do disco de origem
      end;
    except                                                                      //Se ocorrer um erro inesperado no processo
      on e: Exception do
      begin
        Lib.Files.Log(Format(ERROR_UPLOADING_FILE,                              //gravo um log tentando obter a mensagem do erro
                            [AFileName, Self.FBucketName, e.Message]));
        Self.StorageService.AbortMultipartUpload(Self.FBucketName, sTargetFile, sUploadID);
        FinishConnection;
      end;
    end;
  finally                                                                       //Ao final sempre
    FinishConnection;
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
