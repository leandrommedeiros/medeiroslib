{===============================================================================

                       BIBLIOTECA - Amazon S3 Multipart (Thread)

==========================================================| Versão 14.08.00 |==}

unit Lib.AwsS3.Multipart.Thread;

interface

{ Bibliotecas para Interface }
uses
  Lib.Thread.Base;

{ Constantes }
const
  TEN_THOUSAND = 10000;

{ Classes }
type
  //Thread
  TS3MultipartUploadThread = class(TThreadBase)
  private
    FSourcePath,
    FTargetDir,
    FFileName         : String;
    FTries,
    FPackageSize,
    FTotalParts       : integer;
    FDelAfterTransfer : Boolean;

    procedure RecalculatePackageSize;
    procedure SetFileName(const AFileName: string);
    procedure SetPackageSize(const APackageSize: integer);
  public
    property SourcePath       : string  read FSourcePath       write FSourcePath;
    property TargetDir        : string  read FTargetDir        write FTargetDir;
    property FileName         : string  read FFileName         write SetFileName;
    property PackageSize      : integer read FPackageSize      write SetPackageSize;
    property UploadTries      : integer read FTries            write FTries;
    property DelAfterTransfer : Boolean read FDelAfterTransfer write FDelAfterTransfer;

    constructor Create(const ACreateSuspended: Boolean = False;
      const ASleepingTime: integer = 1); overload;
  protected
    function MainRoutine : Boolean; override;
  end;

implementation

{ Bibliotecas para Implementação }
uses
  Lib.Files, System.SysUtils, System.Classes, Data.Cloud.AmazonAPI,
  System.Generics.Collections, Winapi.ActiveX;


{*******************************************************************************

                              MÉTODOS PRIVADOS

*******************************************************************************}

//==| Procedimento - Calcular Tamanho dos Pacotes |=============================
procedure TS3MultipartUploadThread.RecalculatePackageSize;
var
  sSourceFile : string;
begin
  sSourceFile := Self.SourcePath + Self.FileName;

  if not System.SysUtils.FileExists(sSourceFile) then Exit;

  Self.FTotalParts := (Lib.Files.GetFileSizeB(sSourceFile)
                    div Self.FPackageSize) + 1;

  while (Self.FTotalParts >= TEN_THOUSAND) do
  begin
    Self.FPackageSize := Self.FPackageSize + FIVE_MEGABYTES;
    Self.FTotalParts  := (Lib.Files.GetFileSizeB(sSourceFile)
                       div Self.FPackageSize) + 1;
  end;
end;

//==| Setter - Nome do Arquivo |================================================
procedure TS3MultipartUploadThread.SetFileName(const AFileName: string);
begin
  Self.FFileName := AFileName;

  if Self.FFileName <> EmptyStr then
    Self.RecalculatePackageSize;
end;

//==| Setter - Tamanho dos Pacotes |============================================
procedure TS3MultipartUploadThread.SetPackageSize(const APackageSize: integer);
begin
  if APackageSize < FIVE_MEGABYTES then Self.FPackageSize := FIVE_MEGABYTES
  else                                  Self.FPackageSize := APackageSize;

  Self.RecalculatePackageSize;
end;


{*******************************************************************************

                              MÉTODOS PÚBLICOS

*******************************************************************************}

//==| Construtor |==============================================================
constructor TS3MultipartUploadThread.Create(const ACreateSuspended: Boolean = False;
  const ASleepingTime: integer = 1);
begin
  inherited Create(ACreateSuspended, ASleepingTime);

  //
end;

{*******************************************************************************

                              MÉTODOS PROTEGIDOS

*******************************************************************************}

//==| Rotina Principal |========================================================
function TS3MultipartUploadThread.MainRoutine: Boolean;
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
  UploadedPart  : TAmazonMultipartPart;
  PartsList     : System.Generics.Collections.TList<TAmazonMultipartPart>;

procedure FinishConnection;
begin
  Self.EventUploadWorkEnd;
  Buffer := nil;                                                                //Limpo a referência para o arquivo em Stream, permitindo que a memória seja liberada
  System.SysUtils.FreeAndNil(slMetadata);                                       //a List com os metadados
  System.SysUtils.FreeAndNil(slHeaders);                                        //e também a List com os cabeçalhos
end;

begin
  Result := False;                                                              //Assumo falha

  if (Self.FileName = EmptyStr) then Exit;                                      //Se não for informado o nome de arquivo, finalizo a rotina

  try                                                                           //Tento
    if not Lib.Files.ValidateDir(Self.SourcePath, False) or                     //Validar o diretório de origem
       not System.SysUtils.DirectoryExists(Self.SourcePath) then                //e se não existir
      raise Exception.Create('Diretório de origem ("' + Self.SourcePath + '") não existe ou está inacessível.'); //disparo um erro

    WinAPI.ActiveX.CoInitialize(nil);
    sUploadID := Self.StorageService.InitiateMultipartUpload(Self.FBucketName,
                                                             sTargetFile,
                                                             slMetadata,
                                                             slHeaders,
                                                             amzbaPublicRead,
                                                             CloudResponse);

    try                                                                         //Tento
      Self.EventUploadWorkBegin(iTotalParts);

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

                Self.EventUploadWork(iPartNo, APackageSize);
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
        Result := True;                                                         //Se a transferência foi bem sucedida, Retorno Verdadeiro

        if ADelAfterTransfer then                                               //então, se foi solicitado na chamada do método,
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
//==============================================================================

end.
