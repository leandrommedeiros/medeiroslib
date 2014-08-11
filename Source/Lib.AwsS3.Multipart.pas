{===============================================================================

                       BIBLIOTECA - Amazon S3 Multipart

==========================================================| Versão 14.08.00 |==}

unit Lib.AwsS3.Multipart;

interface

{ Bibliotecas para Interface }
uses
  Lib.AwsS3, Lib.Files, Lib.AwsS3.Multipart.Thread;

{ Classes }
type
  //Eventos
  TS3MultipartOnWorkBegin = procedure(const APartsCount: integer) of object;
  TS3MultipartOnWork      = procedure(const ACurrentPart, APackageSize: integer) of object;
  TS3MultipartOnWorkEnd   = procedure of object;

  //Componente
  TS3ConnectionMultipart = class(TS3Connection)
  private
    //Eventos
    FOnUploadWorkBegin : TS3MultipartOnWorkBegin;
    FOnUploadWork      : TS3MultipartOnWork;
    FOnUploadWorkEnd   : TS3MultipartOnWorkEnd;
  protected
    ThreadUpload : TS3MultipartUploadThread;

    //Eventos
    procedure EventUploadWorkBegin(const APartsCount: integer);
    procedure EventUploadWork(const ACurrentPart, APackageSize: integer);
    procedure EventUploadWorkEnd;
  public
    function Upload(ASourcePath: string; const ATargetDir, AFileName: String;
      APackageSize: integer = FIVE_MEGABYTES; const ADelAfterTransfer: Boolean = False;
      const ATries: integer = 3): Boolean; override;
  published
    property OnWorkBegin : TS3MultipartOnWorkBegin read FOnUploadWorkBegin write FOnUploadWorkBegin;
    property OnWork      : TS3MultipartOnWork      read FOnUploadWork      write FOnUploadWork;
    property OnWorkEnd   : TS3MultipartOnWorkEnd   read FOnUploadWorkEnd   write FOnUploadWorkEnd;
  end;

implementation

{ Bibliotecas para Implementação }
uses
  Lib.Win, Lib.StrUtils, System.SysUtils, System.Generics.Collections,
  Data.Cloud.AmazonAPI, Data.Cloud.CloudAPI, Winapi.Windows, Winapi.ActiveX,
  System.Classes;


{*******************************************************************************

                              MÉTODOS PROTEGIDOS

*******************************************************************************}

//==| Evento - Ao Iniciar Trabalho |============================================
procedure TS3ConnectionMultipart.EventUploadWorkBegin(const APartsCount: integer);
begin
  if Assigned(Self.FOnUploadWorkBegin) then
    Self.FOnUploadWorkBegin(APartsCount);
end;

//==| Evento - Ao Trabalhar |===================================================
procedure TS3ConnectionMultipart.EventUploadWork(const ACurrentPart,
  APackageSize: integer);
begin
  if Assigned(Self.FOnUploadWork) then
    Self.FOnUploadWork(ACurrentPart, APackageSize);
end;

//==| Evento - Ao Finalizar Trabalho |==========================================
procedure TS3ConnectionMultipart.EventUploadWorkEnd;
begin
  if Assigned(Self.FOnUploadWorkEnd) then
    Self.FOnUploadWorkEnd;
end;

{*******************************************************************************

                              MÉTODOS PÚBLICOS

*******************************************************************************}

//==| Função - Upload Particionado |============================================
function TS3ConnectionMultipart.Upload(ASourcePath: string; const ATargetDir,
  AFileName: String; APackageSize: integer = FIVE_MEGABYTES;
  const ADelAfterTransfer: Boolean = False; const ATries: integer = 3): Boolean;
begin

end;
//==============================================================================

end.
