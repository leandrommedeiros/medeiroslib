{===============================================================================

                               REST CONNECTION

============================================| Leandro Medeiros (16/04/2014) |==}

unit Lib.REST;

interface

{ Bibliotecas para Interface }
uses
  System.Classes, IdHTTP, Lib.REST.Parameters, Lib.JSON.Extended;

{ Constantes }
const
  WS_EXEC_LOG = 'Requisição ao Web Service' + #13+#10
              + 'Host: "%s".'   + #13+#10
              + 'Porta: "%s".'  + #13+#10
              + 'Classe: "%s".' + #13+#10
              + 'Método: "%s".' + #13+#10
              + 'Parâmetros (JSON): %s.';

{ Classes }
type
  TONRADSession = record
    UserID      : integer;
    Token       : string;
    LastRequest : TDateTime;
  end;

  TRESTConnection = class(TIdCustomHTTP)
  private
    FDSContext    : string;
    FRESTContext  : string;
    FUser         : string;
    FPassword     : string;
    FSessionData  : TONRADSession;

    // Getters e Setters
    function  GetHost: string;
    procedure SetHost(const AHost: string);
    function  GetPort: string;
    procedure SetPort(const APort: string);
    function  GetDSContext: string;
    function  GetRESTContext: string;
  protected
    function GetPath: string;
    function GetFullPath(const AClass, AMethod: string): string;
    function HTTPGet(AURL: string): TJSONExtended; overload;
  public
    MethodResultStr : string;
    MethodResult    : TJSONExtended;
    MethodParams    : TRESTParameters;

    constructor Create(AOwner: TComponent); virtual;
    destructor  Destroy; override;
    function Login: Boolean;
    function Execute(const AClass, AMethod: string; ATries: integer = 3;
      const ExecutionLog: Boolean = True): Boolean;
    property SessionData : TONRADSession read FSessionData;
  published
    property AuthUser          : string read FUser          write FUser;
    property AuthPassword      : string read FPassword      write FPassword;
    property Path              : string read GetPath;
    property WSHost            : string read GetHost        write SetHost;
    property WSPort            : string read GetPort        write SetPort;
    property WSDataSnapContext : string read GetDSContext   write FDSContext;
    property WSRESTContext     : string read GetRESTContext write FRESTContext;
  end;

implementation

{ Bibliotecas para implementação }
uses
  Lib.JSON, Lib.REST.Constants, Lib.StrUtils, Lib.Files, WinAPI.Windows,
  System.SysUtils;


{*******************************************************************************

                            MÉTODOS PRIVADOS

*******************************************************************************}

//==| Host - Getter |===========================================================
function TRESTConnection.GetHost: string;
begin
  if Self.URL.Host = EmptyStr then
    Self.URL.Host := 'ws.onrad.com.br';

  Result := Self.URL.Host;
end;

//==| Host - Setter |===========================================================
procedure TRESTConnection.SetHost(const AHost: string);
begin
  Self.URL.Host := AHost;
end;

//==| Port - Getter |===========================================================
function TRESTConnection.GetPort: string;
begin
  if Self.URL.Port = EmptyStr then
    Self.URL.Port := '8080';

  Result := Self.URL.Port;
end;

//==| Port - Setter |===========================================================
procedure TRESTConnection.SetPort(const APort: string);
begin
  Self.URL.Port := APort;
end;

//==| DataSnap Context - Getter |===============================================
function TRESTConnection.GetDSContext: string;
begin
  if Self.FDSContext = EmptyStr then
    Self.FDSContext := 'onrad';

  Result := Self.FDSContext;
end;

//==| REST Context - Getter |===================================================
function TRESTConnection.GetRESTContext: string;
begin
  if Self.FRESTContext = EmptyStr then
    Self.FRESTContext := 'rest';

  Result := Self.FRESTContext;
end;


{*******************************************************************************

                            MÉTODOS PROTEGIDOS

*******************************************************************************}

//==| Função - Obter Path |=====================================================
function TRESTConnection.GetPath: string;
const
  REST_PATH = '%s/%s/';
begin
  Result := Format(REST_PATH, [Self.WSDataSnapContext, Self.WSRESTContext]);
end;

//==| Função - Obter Path Completo |============================================
function TRESTConnection.GetFullPath(const AClass, AMethod: string): string;
const
  FULL_PATH = '%s/%s/%s/%s/';
begin
  Result := Format(FULL_PATH, [Self.WSDataSnapContext,
                               Self.WSRESTContext,
                               AClass,
                               AMethod]);
end;

//==| Função - HTTP Get |=======================================================
function TRESTConnection.HTTPGet(AURL: string): TJSONExtended;
begin
  Self.MethodResultStr := inherited Get(Lib.StrUtils.StrToHex(AURL));
  Self.MethodResultStr := Copy(Self.MethodResultStr, 12, Length(Self.MethodResultStr) - 13);
  Result               := TJSONExtended.Create(Self.MethodResultStr);
end;


{*******************************************************************************

                            MÉTODOS PÚBLICOS

*******************************************************************************}

//==| Construtor |==============================================================
constructor TRESTConnection.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  Self.GetHost;
  Self.GetPort;
  Self.MethodParams := TRESTParameters.Create;
end;

//==| Destrutor |===============================================================
destructor TRESTConnection.Destroy;
begin
  System.SysUtils.FreeAndNil(Self.MethodResult);
  System.SysUtils.FreeAndNil(Self.MethodParams);

  inherited Destroy;
end;

//==| Função - Login |==========================================================
function TRESTConnection.Login: Boolean;
begin
  Result := False;

  try
    Self.MethodParams := TRESTParameters.Create;
    Self.MethodParams.Params['user']   := Self.AuthUser;
    Self.MethodParams.Params['passwd'] := Self.AuthPassword;

    if (Self.Execute(REST_CLASS_USER, 'Login')) and
       (Self.MethodResult.GetStr('loginStatus') = JSON_FALSE) then
    begin
      Self.FSessionData.UserID      := Self.MethodResult.GetInt('userId');
      Self.FSessionData.Token       := Self.MethodResult.GetStr('sessionToken');
      Self.FSessionData.LastRequest := System.SysUtils.Now();
      Result                        := True;
    end;
  except
    on e: Exception do
      Lib.Files.Log('Error ao autenticar usuário: ' + e.Message);
  end;
end;

//==| Função - Executar |=======================================================
function TRESTConnection.Execute(const AClass, AMethod: string;
  ATries: integer = 3; const ExecutionLog: Boolean = True): Boolean;
var
  sParams: string;
begin
  Result := False;

  try
    Self.URL.Path                             := Self.GetFullPath(AClass, AMethod);
    Self.MethodParams.Params['sessionUserId'] := IntToStr(Self.SessionData.UserID);
    Self.MethodParams.Params['sessionToken']  := Self.SessionData.Token;

    try
      sParams := Self.MethodParams.ToString;

      if ExecutionLog then
        Lib.Files.Log(System.SysUtils.Format(WS_EXEC_LOG, [Self.WSHost,
                                                           Self.WSPort,
                                                           AClass,
                                                           AMethod,
                                                           sParams]));

      Self.MethodResult := Self.HTTPGet(sParams);
    except
      on e: Exception do
      begin
        Lib.Files.Log(e.Message);

        Inc(ATries, - 1);

        if ATries > 0 then
        begin
          Sleep(3000);
          Result := Self.Execute(AClass, AMethod, ATries);
          Exit;
        end;
      end;
    end;

    if Self.MethodResult.GetStr('error') = JSON_FALSE then
    begin
      Result := True;

      if Bool(Self.SessionData.UserID) then
        Self.FSessionData.LastRequest := System.SysUtils.Now();
    end

    else begin
      Lib.Files.Log(Self.MethodResult.GetStr('error'));

      if (Self.MethodResult.GetInt('errorId') = REST_ERROR_INVALID_SESSION) and
         (Self.Login) then
      begin
        Result := Self.Execute(AClass, AMethod);
      end;
    end
  finally
    Self.MethodParams.Clear;
    Self.Disconnect;
  end;
end;
//==============================================================================

end.
