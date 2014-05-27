{===============================================================================

                      CLASSE ESTUDO REST (TRESTStudy)

============================================| Leandro Medeiros (20/03/2012) |==}

unit Lib.REST.Study;

interface

{ Bibliotecas para Interface }
uses
  Lib.JSON.Study, Lib.REST, DataSnap.DBClient, System.Classes;

{ Classes }
type
  TRESTStudy = class (TRESTConnection)
  protected
    procedure FeedParameters;
  public
    jStudy : TJSONStudy;

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function GetInfo: Boolean; overload;
    function GetInfo(const AID: integer): Boolean; overload;
    function GetInfo(const AStudyUID: string;
      const AOriginID: integer): Boolean; overload;
    function GetList(const AOriginID: Integer; const AInitialDate,
      AFinalDate: TDateTime): TClientDataSet;
    function UpdateDicomInformation: Boolean; overload;
    function UpdateDicomInformation(const ANewDcmSituation: integer): Boolean; overload;
    function GetDicomRepositorySettings(const AOriginID: integer): Boolean;
    function Insert: Boolean; overload;
    function Insert(ACds: TClientDataSet): String; overload;
  end;

implementation

{ Bibliotecas para Implementação }
uses
  Lib.REST.Constants, Lib.JSON, Lib.JSON.Extended, Lib.Files, System.SysUtils,
  DBXJSON;


{*******************************************************************************

                            MÉTODOS PRIVADOS

*******************************************************************************}

//==| Procedimentos - Alimentar Parâmetros |====================================
procedure TRESTStudy.FeedParameters;
begin
  Self.MethodParams.Params['studyId']             := IntToStr(Self.jStudy.ID);
  Self.MethodParams.Params['originId']            := IntToStr(Self.jStudy.OriginID);
  Self.MethodParams.Params['originName']          := Self.jStudy.OriginName;
  Self.MethodParams.Params['hasDictation']        := BoolToStr(Self.jStudy.HasDictation);
  Self.MethodParams.Params['modalityId']          := IntToStr(Self.jStudy.ModalityID);
  Self.MethodParams.Params['modality']            := Self.jStudy.Modality;
  Self.MethodParams.Params['modalityDescription'] := Self.jStudy.ModalityDesc;
  Self.MethodParams.Params['situationId']         := IntToStr(Self.jStudy.SituationID);
  Self.MethodParams.Params['situation']           := Self.jStudy.Situation;
  Self.MethodParams.Params['patientId']           := IntToStr(Self.jStudy.PatientID);
  Self.MethodParams.Params['pPID']                := Self.jStudy.PatientPID;
  Self.MethodParams.Params['patientName']         := Self.jStudy.PatientName;
  Self.MethodParams.Params['exam']                := Self.jStudy.ExamDescription;
  Self.MethodParams.Params['dicomSituationId']    := IntToStr(Self.jStudy.DicomSituationID);
  Self.MethodParams.Params['dicomImg']            := Self.jStudy.DicomSituation;
  Self.MethodParams.Params['hasPreviousResults']  := BoolToStr(Self.jStudy.PriorResults);
  Self.MethodParams.Params['urgent']              := BoolToStr(Self.jStudy.Urgent);
  Self.MethodParams.Params['accessionNumber']     := Self.jStudy.AccessionNumber;
  Self.MethodParams.Params['studyUID']            := Self.jStudy.StudyUID;
  Self.MethodParams.Params['fileName']            := Self.jStudy.FileName;
  Self.MethodParams.Params['fileSize']            := IntToStr(Self.jStudy.FileSize);

  if Self.jStudy.StudyDate <> 0 then
    Self.MethodParams.Params['date'] := DateTimeToStr(Self.jStudy.StudyDate);

  if Self.jStudy.DeliveryDate <> 0 then
    Self.MethodParams.Params['deliveryDate'] := DateTimeToStr(Self.jStudy.DeliveryDate);
end;


{*******************************************************************************

                            MÉTODOS PÚBLICOS

*******************************************************************************}

//==| Construtor |==============================================================
constructor TRESTStudy.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  Self.jStudy := TJSONStudy.Create();
end;

//==| Destrutor |===============================================================
destructor TRESTStudy.Destroy;
begin
  System.SysUtils.FreeAndNil(Self.jStudy);

  inherited Destroy;
end;

//==| Função - Obter Dados |====================================================
function TRESTStudy.GetInfo(const AID: integer): Boolean;
begin
  Self.jStudy.ID := AID;
  Result         := Self.GetInfo;
end;

//==| Função - Obter Dados |====================================================
function TRESTStudy.GetInfo(const AStudyUID: string;
  const AOriginID: integer): Boolean;
begin
  Self.jStudy.StudyUID := AStudyUID;
  Self.jStudy.OriginID := AOriginID;
  Result               := Self.GetInfo;
end;

//==| Função - Obter Dados |====================================================
function TRESTStudy.GetInfo: Boolean;
begin
  Result := False;

  try
    Self.FeedParameters;

    if Self.Execute(REST_CLASS_STUDY, 'GetInfo') then
    begin
      Self.jStudy.SetInfo(Self.MethodResultStr);
      Result := True;
    end;
  except
    on E: exception do
      Lib.Files.Log('Erro ao obter dados do estudo via WebService: ' + E.Message);
  end;
end;

//==| Função - Obter Lista de Estudos |=========================================
function TRESTStudy.GetList(const AOriginID: Integer; const AInitialDate,
  AFinalDate: TDateTime): TClientDataSet;
begin
  Result := TClientDataSet.Create(nil);

  try
    Self.MethodParams.Params['originId'] := IntToStr(AOriginID);
    Self.MethodParams.Params['dtStart']  := DateTimeToStr(AInitialDate);
    Self.MethodParams.Params['dtEnd']    := DateTimeToStr(AFinalDate);

    if Self.Execute(REST_CLASS_STUDY, 'GetList') then
      Lib.JSON.JSONToCds(TJSONObject(Self.MethodResult), Result);
  except
    on E: exception do Lib.Files.Log('Erro ao obter dados do origem '
                                    +IntToStr(AOriginID)
                                    +' via WebService: ' + E.Message);
  end;
end;

//==| Definir Situação DICOM |==================================================
function TRESTStudy.UpdateDicomInformation(const ANewDcmSituation: integer): Boolean;
begin
  Self.jStudy.DicomSituationID := ANewDcmSituation;
  Result                       := Self.UpdateDicomInformation;
end;

//==| Definir Situação DICOM |==================================================
function TRESTStudy.UpdateDicomInformation: Boolean;
begin
  Result := False;

  try
    Self.FeedParameters;
    Result := Self.Execute(REST_CLASS_STUDY, 'SetDicomSituation');
  except
    on e: exception do
      Lib.Files.Log('Erro ao atualizar situação das imagens via Webservice: ' + E.Message);
  end;
end;

//==| Obter Configurações do Repositório |======================================
function TRESTStudy.GetDicomRepositorySettings(const AOriginID: integer): Boolean;
begin
  Self.MethodParams.Params['originId'] := IntToStr(AOriginID);

  Result := Self.Execute(REST_CLASS_ORIGIN, 'GetInfo');
end;

{==| Função - Inserir |=========================================================                                                                                                                        |==================================================
    Cria um registro no banco oficial do ONRAD através de uma função SQL. Se
  tudo correr bem, retorna o ID do estudo criado.
  Retorno: Sucesso(Booleano).
============================================| Leandro Medeiros (21/12/2012) |==}
function TRESTStudy.Insert: Boolean;
begin
  Result := False;

  try
    Self.FeedParameters;

    if not Self.Execute(REST_CLASS_STUDY, 'Insert') then
      Lib.Files.Log(Format(LOG_ONRAD_INSERT_WEB_FAIL, [Self.jStudy.PatientName,
                                                       Self.jStudy.StudyUID,
                                                       Self.MethodResult.GetStr('error')]))
    else if Self.MethodResult.GetBool('studyId') then
    begin
      Result      := True;
      Self.jStudy := TJSONStudy.Create(Self.MethodResultStr);
      Lib.Files.Log(Format(LOG_ONRAD_INSERT_WEB_OK, [Self.jStudy.PatientName,
                                                     Self.jStudy.StudyUID,
                                                     Self.jStudy.ID]));
    end;
  except
    on e: exception do
      Lib.Files.Log('Erro ao gerar estudo via Webservice: ' + e.Message);
  end;
end;

{==| Função - Inserir |=========================================================                                                                                                                        |==================================================
    Cria um registro no banco oficial do ONRAD através de uma função SQL. Se
  tudo correr bem, retorna o ID do estudo criado.
  Parâmetros de Entrada:
    01. Dados do estudo > TClientDataSet.
  Retorno: Novo ID do estudo no Sistema(String).
============================================| Leandro Medeiros (21/12/2012) |==}
function TRESTStudy.Insert(ACds: TClientDataSet): String;
begin
  Result := 'Retorno inválido';

  try
    ACds.Edit;
    ACds.FieldByName('STUDYUID').AsString        := Trim(ACds.FieldByName('STUDYUID').AsString);
    ACds.FieldByName('ACCESSIONNUMBER').AsString := Trim(ACds.FieldByName('ACCESSIONNUMBER').AsString);
  finally
    ACds.Post;
  end;

  try
    Self.jStudy.Modality         := ACds.FieldByName('MODALITY').AsString;
    Self.jStudy.PatientPID       := ACds.FieldByName('P_PID').AsString;
    Self.jStudy.ExamDescription  := ACds.FieldByName('EXAM').AsString;
    Self.jStudy.StudyDate        := ACds.FieldByName('LDATE').AsDateTime;
    Self.jStudy.StudyUID         := ACds.FieldByName('STUDYUID').AsString;
    Self.jStudy.AccessionNumber  := ACds.FieldByName('ACCESSIONNUMBER').AsString;
    Self.jStudy.PatientName      := ACds.FieldByName('PACIENTE').AsString;
    Self.jStudy.DicomSituationID := 2;

    if Self.Insert then Result := IntToStr(Self.jStudy.ID);
  except
    on e: exception do
      Lib.Files.Log('Erro ao gerar estudo via Webservice: ' + e.Message);
  end;
end;
//==============================================================================

end.
