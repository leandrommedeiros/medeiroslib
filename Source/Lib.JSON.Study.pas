{===============================================================================

                      CLASSE ESTUDO EM JSON (TJSONStudy)

============================================| Leandro Medeiros (20/03/2012) |==}

unit Lib.JSON.Study;

interface

{ Bibliotecas para Interface }
uses
  System.Classes, Lib.JSON.Extended;

{ Classes }
type
  TJSONStudy = class abstract (TObject)
  private
    FID                 : integer;
    FOriginID           : integer;
    FOriginName         : string;
    FModalityID         : integer;
    FModality           : string;
    FModalityDesc       : string;
    FSituationID        : integer;
    FSituation          : string;
    FPatientID          : integer;
    FPatientPID         : string;
    FPatientName        : string;
    FExam               : string;
    FDicomSituationID   : integer;
    FDicomSituation     : string;
    FStudyDt            : TDateTime;
    FDeliveryDt         : TDateTime;
    FHasDictation       : Boolean;
    FPriorResults       : Boolean;
    FUrgent             : Boolean;
    FAccessionNumber    : string;
    FStudyUID           : string;
    FFileName           : integer;
    FFileSize           : integer;
    FUserLastModifiedID : integer;
    FDoctorSignID       : integer;
    FDoctorCheckID      : integer;
    procedure SetAccessionNumber(const AValue: string);
    procedure SetOriginName(const AValue: string);
    procedure SetDicomSituationID(const AValue: integer = 0);
    procedure SetExamDescription(const AValue: string);
    procedure SetModalityDescription(const AValue: string);
    procedure SetPatientName(const AValue: string);
    procedure SetPatientPID(const AValue: string);
    procedure SetSituationID(const AValue: integer = 0);
    procedure SetStudyUID(const AValue: string);
  public
    constructor Create(const ASerializedStudy: string = '');
    procedure SetInfo(const ASerializedStudy: string); overload;
    procedure SetInfo(const AStudy: TJSONExtended); overload;
    function  GetNativeJSON: TJSONExtended;
    function  ToString: string; virtual;
  published
    { Propriedades Publicadas }
    property ID               : Integer   read FID                 write FID;
    property OriginID         : Integer   read FOriginID           write FOriginID;
    property OriginName       : String    read FOriginName         write SetOriginName;
    property ModalityID       : Integer   read FModalityID         write FModalityID;
    property Modality         : String    read FModality           write FModality;
    property ModalityDesc     : String    read FModalityDesc       write SetModalityDescription;
    property SituationID      : Integer   read FSituationID        write SetSituationID;
    property Situation        : String    read FSituation          write FSituation;
    property PatientID        : Integer   read FPatientID          write FPatientID;
    property PatientPID       : String    read FPatientPID         write SetPatientPID;
    property PatientName      : String    read FPatientName        write SetPatientName;
    property ExamDescription  : String    read FExam               write SetExamDescription;
    property DicomSituationID : Integer   read FDicomSituationID   write SetDicomSituationID;
    property DicomSituation   : String    read FDicomSituation     write FDicomSituation;
    property StudyDate        : TDateTime read FStudyDt            write FStudyDt;
    property DeliveryDate     : TDateTime read FDeliveryDt         write FDeliveryDt;
    property HasDictation     : Boolean   read FHasDictation       write FHasDictation;
    property PriorResults     : Boolean   read FPriorResults       write FPriorResults;
    property Urgent           : Boolean   read FUrgent             write FUrgent;
    property AccessionNumber  : String    read FAccessionNumber    write SetAccessionNumber;
    property StudyUID         : String    read FStudyUID           write SetStudyUID;
    property FileName         : Integer   read FFileName           write FFileName;
    property FileSize         : Integer   read FFileSize           write FFileSize;
    property UserLastModified : Integer   read FUserLastModifiedID write FUserLastModifiedID;
    property DoctorSign       : Integer   read FDoctorSignID       write FDoctorSignID;
    property DoctorCheck      : Integer   read FDoctorCheckID      write FDoctorCheckID;
  end;

implementation

{ Bibliotecas para Implementação }
uses
  System.SysUtils, System.DateUtils, Lib.StrUtils;


{*******************************************************************************

                      TJSONSTUDY - MÉTODOS PRIVADOS

*******************************************************************************}

//==| "Seter" - Número de Acesso |==============================================
procedure TJSONStudy.SetAccessionNumber(const AValue: string);
begin
  Self.FAccessionNumber := System.SysUtils.Trim(AValue);
end;

//==| "Seter" - Nome do Origem |================================================
procedure TJSONStudy.SetOriginName(const AValue: string);
begin
  Self.FOriginName := Lib.StrUtils.UpperName(AValue);
end;

//==| "Seter" - ID da Situação DICOM |==========================================
procedure TJSONStudy.SetDicomSituationID(const AValue: integer = 0);
begin
  if AValue > 0 then Self.FDicomSituationID := AValue
  else               Self.FDicomSituationID := 1;
end;

//==| "Seter" - Descrição do Exame |============================================
procedure TJSONStudy.SetExamDescription(const AValue: string);
begin
  if AValue = '' then Self.FExam := 'Nao Informado'
  else                Self.FExam := Lib.StrUtils.UpperName(AValue);
end;

//==| "Seter" - Descrição de Modalidade |=======================================
procedure TJSONStudy.SetModalityDescription(const AValue: string);
begin
  Self.FModalityDesc := Lib.StrUtils.UpperName(AValue);
end;

//==| "Seter" - Nome do Paciente |==============================================
procedure TJSONStudy.SetPatientName(const AValue: string);
begin
  Self.FPatientName := Lib.StrUtils.UpperName(AValue);
end;

//==| "Seter" - P_PID |=========================================================
procedure TJSONStudy.SetPatientPID(const AValue: string);
begin
  Self.FPatientPID := System.SysUtils.Trim(AValue);
end;

//==| "Seter" - ID da Situação |================================================
procedure TJSONStudy.SetSituationID(const AValue: integer = 0);
begin
  if AValue > 0 then Self.FSituationID := AValue
  else               Self.FSituationID := 1;
end;

//==| "Seter" - STUDYUID |======================================================
procedure TJSONStudy.SetStudyUID(const AValue: string);
begin
  Self.FStudyUID := System.SysUtils.Trim(AValue);
end;


{*******************************************************************************

                      TJSONSTUDY - MÉTODOS PUBLICOS

*******************************************************************************}

//==| Construtor |==============================================================
constructor TJSONStudy.Create(const ASerializedStudy: string = '');
begin
  inherited Create();

  if ASerializedStudy <> EmptyStr then Self.SetInfo(ASerializedStudy);
end;

//==| Função - Definir Atributos |==============================================
procedure TJSONStudy.SetInfo(const ASerializedStudy: string);
var
  jStudy : TJSONExtended;
begin
  try
    jStudy  := TJSONExtended.Create(ASerializedStudy);
    Self.SetInfo(jStudy);
  finally
    FreeAndNil(jStudy);
  end;
end;

//==| Função - Definir Atributos |==============================================
procedure TJSONStudy.SetInfo(const AStudy: TJSONExtended);
begin
  Self.id               := AStudy.GetInt('id');
  Self.OriginID         := AStudy.GetInt('originId');
  Self.OriginName       := AStudy.GetStr('originName');
  Self.ModalityID       := AStudy.GetInt('modalityId');
  Self.Modality         := AStudy.GetStr('modality');
  Self.ModalityDesc     := AStudy.GetStr('modalityDescription');
  Self.SituationID      := AStudy.GetInt('situationId');
  Self.Situation        := AStudy.GetStr('situation', 'Sem Resultado');
  Self.PatientID        := AStudy.GetInt('patientId');
  Self.PatientPID       := AStudy.GetStr('pPID');
  Self.PatientName      := AStudy.GetStr('patientName');
  if Self.PatientName = EmptyStr then
    Self.PatientName := AStudy.GetStr('patient');
  Self.ExamDescription  := AStudy.GetStr('exam');
  Self.DicomSituationID := AStudy.GetInt('dicomSituationId');
  Self.DicomSituation   := AStudy.GetStr('dicomSituation', 'Sem Imagens');
  Self.StudyDate        := AStudy.GetDtTime('date');
  Self.DeliveryDate     := AStudy.GetDtTime('deliveryDate', System.DateUtils.IncDay(Now, 7));
  Self.HasDictation     := AStudy.GetBool('hasDictation');
  Self.PriorResults     := AStudy.GetBool('hasPreviousResults');
  Self.Urgent           := AStudy.GetBool('urgent');
  Self.AccessionNumber  := AStudy.GetStr('accessionNumber');
  Self.StudyUID         := AStudy.GetStr('studyUID');
  Self.FileName         := AStudy.GetInt('fileName');
  Self.FileSize         := AStudy.GetInt('fileSize');
  Self.DoctorSign       := AStudy.GetInt('doctorIdSign');
  Self.DoctorCheck      := AStudy.GetInt('doctorIdCheck');
  Self.UserLastModified := AStudy.GetInt('userTyper');
end;

//==| Obter JSON Nativo |=======================================================
function TJSONStudy.GetNativeJSON: TJSONExtended;
begin
  Result := TJSONExtended.Create;

  Result.AddPair('id',                  Self.ID);
  Result.AddPair('studyId',             Self.ID);
  Result.AddPair('originId',            Self.OriginID);
  Result.AddPair('originName',          Self.OriginName);
  Result.AddPair('hasDictation',        Self.HasDictation);
  Result.AddPair('modalityId',          Self.ModalityID);
  Result.AddPair('modality',            Self.Modality);
  Result.AddPair('modalityDescription', Self.ModalityDesc);
  Result.AddPair('situationId',         Self.SituationID);
  Result.AddPair('situation',           Self.Situation);
  Result.AddPair('patientId',           Self.PatientID);
  Result.AddPair('pPID',                Self.PatientPID);
  Result.AddPair('patientName',         Self.PatientName);
  Result.AddPair('exam',                Self.ExamDescription);
  Result.AddPair('dicomSituationId',    Self.DicomSituationID);
  Result.AddPair('dicomImg',            Self.DicomSituation);
  Result.AddPair('hasPreviousResults',  Self.PriorResults);
  Result.AddPair('urgent',              Self.Urgent);
  Result.AddPair('accessionNumber',     Self.AccessionNumber);
  Result.AddPair('studyUID',            Self.StudyUID);
  Result.AddPair('fileName',            Self.FileName);
  Result.AddPair('fileSize',            Self.FileSize);
  Result.AddPair('doctorIdSign',        Self.DoctorSign);
  Result.AddPair('doctorIdCheck',       Self.DoctorCheck);
  Result.AddPair('userIdLastModified',  Self.UserLastModified);

  if Self.StudyDate    <> 0 then Result.AddPair('date', Self.StudyDate);
  if Self.DeliveryDate <> 0 then Result.AddPair('deliveryDate', Self.DeliveryDate);
end;

//==| Para String |=============================================================
function TJSONStudy.ToString: string;
var
  jStudy : TJSONExtended;
begin
  Result := EmptyStr;

  try
    jStudy := Self.GetNativeJSON;

    Result := jStudy.ToString;
  finally
    FreeAndNil(jStudy);
  end;
end;
//==============================================================================

end.
