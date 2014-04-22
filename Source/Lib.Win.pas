{===============================================================================

                           BIBLIOTECA - WINDOWS

==========================================================| Vers�o 12.11.00 |==}

unit Lib.Win;

interface

{ Bibliotecas para Interface }
uses
  WinSvc, Windows;

{ Constantes }
const
  //Retorno da fun��o GetWindowsVersion
  WIN_UNKNOWN          = -1;
  WIN_95               = 8795;
  WIN_98SE             = 879883;
  WIN_98               = 8798;
  WIN_MILLENUM         = 8777;
  WIN_NT3              = 87783;
  WIN_NT4              = 87784;
  WIN_2000             = 872000;
  WIN_XP               = 878880;
  WIN_SERVER2003       = 872003; //ou Windows XP x64
  WIN_VISTA_SERVER2008 = 872008;
  WIN_7_SERVER2008R2   = 877;
  WIN_8                = 878;

  //Log dos Servi�os
  LOG_SERVICE_ERROR    = 'Erro ao tentar manipular servi�o. Mensagem: ';

{ Fun��es externas - DLL dwm manager }
  procedure EnableAero; external 'dwmman.dll' name 'EnableAero';
  procedure DisableAero; external 'dwmman.dll' name 'DisableAero';
  function  AeroIsEnabled: boolean; external 'dwmman.dll' name 'AeroIsEnabled';

{ Prot�tipos das Fun��es e Procedimentos }
  // Fun��es para Controle de Servi�os
  function  ServiceGetHandle(const AService: string;
    const AMachine : string = '';
    const AFlags: DWord = SERVICE_QUERY_STATUS): SC_Handle;
  function  ServiceGetStrStatus(const ASituation: integer): string; overload;
  function  ServiceGetStrStatus(const AService: string;
    const AMachine : string = '') : string; overload;
  function ServiceGetStatus(const AService: string;
    const AMachine : string = ''): DWord; overload;
  function  ServiceRunning(const AService: string;
    const AMachine : string = '') : Boolean;
  function  ServiceStart(const AService: string;
    const AMachine : string = '') : Boolean;
  function  ServiceStop(const AService: string;
    const AMachine : string = '') : Boolean;

  // Fun��es Comuns
  function  GetEnvVarValue(const VarName: string): string;
  function  GetWindowsVersion: integer;
  function  GetComputerAndUserName: string;
  function  GetMacAddress: string;
  function  GetComputerNetName: string;
  function  GetLocalIP: string;
  function  NetworkIsFine: Boolean;
  function  WinExecAndWait(FileName:String; Visibility : integer = SW_SHOW): Variant;
  function  WinExecAndWait32(FileName: string; Visibility: integer): boolean;
  function  GetTaskBarHeight: integer;
  function  IsTaskbarAutoHideOn: Boolean;

implementation

{ Bibliotecas para Implementa��o }
uses
  Winsock, ShellAPI, SysUtils, Lib.Files;

{*******************************************************************************

              ROTINAS PARA CONTROLE DE SERVI�OS WINDOWS

*******************************************************************************}

//==| Fun��o - Obter Handle do Servi�o |========================================
function ServiceGetHandle(const AService: string;
  const AMachine : string = '';
  const AFlags: DWord = SERVICE_QUERY_STATUS): SC_Handle;
var
  SvcMgr : SC_Handle; //Handle do "Gerenciador de Servi�os do Windows"
begin
  Result := 0;

  try
    SvcMgr := OpenSCManager(PChar(AMachine), nil, SC_MANAGER_ALL_ACCESS);

    if not Bool(SvcMgr) then FileLog(SysErrorMessage(GetLastError))
    else                     Result := OpenService(SvcMgr, PChar(AService), AFlags);
  finally
    CloseServiceHandle(SvcMgr);
  end;
end;

//==| Fun��o - Obter Situa��o (String) |========================================
function ServiceGetStrStatus(const AService: string;
  const AMachine : string = ''): string; overload;
begin
  ServiceGetStrStatus(ServiceGetStatus(AService, AMachine));
end;

//==| Fun��o - Obter Situa��o (String) |========================================
function ServiceGetStrStatus(const ASituation: integer): string; overload;
begin
  case ASituation of
    SERVICE_STOPPED          : Result := 'Parado';
    SERVICE_RUNNING          : Result := 'Em Execu��o';
    SERVICE_PAUSED           : Result := 'Pausado';
    SERVICE_START_PENDING    : Result := 'Iniciando';
    SERVICE_STOP_PENDING     : Result := 'Parando';
    SERVICE_CONTINUE_PENDING : Result := 'Reiniciando';
    SERVICE_PAUSE_PENDING    : Result := 'Pausando';
  else
    Result := 'Desconhecido';
  end;
end;
//==| Fun��o - Obter Situa��o (C�digo) |========================================
function ServiceGetStatus(const AService: string;
  const AMachine : string = ''): DWord; overload;
var
  schs   : SC_Handle;      //Handle do Servi�o
  ss     : TServiceStatus; //Situa��o do Servi�o
  dwStat : DWord;
begin
  dwStat := 0;

  try
    schs := Lib.Win.ServiceGetHandle(AService, AMachine, SERVICE_QUERY_STATUS);

    if (schs > 0) and (QueryServiceStatus(schs, ss)) then
    begin
      dwStat := ss.dwCurrentState;
      CloseServiceHandle(schs);
    end;
  except
    on E: Exception do FileLog(LOG_SERVICE_ERROR + E.Message);
  end;

  Result := dwStat;
end;

//==| Fun��o - Servi�o Rodando |================================================
function ServiceRunning(const AService: string; const AMachine : string = ''): Boolean;
begin
  Result := Lib.Win.ServiceGetStatus(AMachine, AService) = SERVICE_RUNNING;
end;

//==| Fun��o - Servi�o Parado |=================================================
function ServiceStopped(const AService: string; const AMachine : string = ''): Boolean;
begin
  Result := Lib.Win.ServiceGetStatus(AMachine, AService) = SERVICE_STOPPED;
end;

//==| Fun��o - Parar Servi�o |==================================================
function ServiceStop(const AService: string; const AMachine : string = ''): Boolean;
var
  schs   : SC_Handle;
  ss     : TServiceStatus;
  psTemp : PChar;
  dwChkP : DWord;
begin
  ss.dwCurrentState := 0;
  psTemp            := nil;

  try
    schs := Lib.Win.ServiceGetHandle(AService, AMachine, SERVICE_STOP or SERVICE_QUERY_STATUS);

    if (schs > 0) and
       ControlService(schs, SERVICE_CONTROL_STOP, ss) and
       QueryServiceStatus(schs, ss) then
    begin
      while ss.dwCurrentState <> SERVICE_STOPPED do
      begin
        dwChkP := ss.dwCheckPoint;
        Sleep(ss.dwWaitHint);

        if (not QueryServiceStatus(schs, ss)) or (ss.dwCheckPoint < dwChkP) then Break;
      end;

      CloseServiceHandle(schs);
    end;
  except
    on E: Exception do FileLog(LOG_SERVICE_ERROR + E.Message);
  end;

  Result := ss.dwCurrentState = SERVICE_STOPPED;
end;

//==| Fun��o - Parar Servi�o |==================================================
function ServiceStart(const AService: string; const AMachine : string = ''): Boolean;
var
  schs   : SC_Handle;
  ss     : TServiceStatus;
  psTemp : PChar;
  dwChkP : DWord;
begin
  ss.dwCurrentState := 0;
  psTemp            := nil;

  try
    schs := Lib.Win.ServiceGetHandle(AService, AMachine, SERVICE_START or SERVICE_QUERY_STATUS);

    if (schs > 0) and
       StartService(schs, 0, psTemp) and
       QueryServiceStatus(schs, ss) then
    begin
      while ss.dwCurrentState <> SERVICE_RUNNING do
      begin
        dwChkP := ss.dwCheckPoint;
        Sleep(ss.dwWaitHint);

        if (not QueryServiceStatus(schs, ss)) or (ss.dwCheckPoint < dwChkP) then Break;
      end;

      CloseServiceHandle(schs);
    end;
  except
    on E: Exception do FileLog(LOG_SERVICE_ERROR + E.Message);
  end;

  Result := ss.dwCurrentState = SERVICE_RUNNING;
end;


{*******************************************************************************

                              ROTINAS COMUNS

*******************************************************************************}

{==| Fun��o - Obter Valor de Vari�vel de Ambiente |=============================
  Retorna o valor de uma vari�vel de ambiante espec�fica
  Par�metro de entrada:
    Nome da vari�vel buscada > String
  Retorno: Valor da vari�vel(string)
============================================| Leandro Medeiros (20/10/2011) |==}
function GetEnvVarValue(const VarName: string): string;
var
  BufSize : Integer;
begin
  Result  := '';                                                                //Assumo falha e retorno uma string em branco
  BufSize := GetEnvironmentVariable(PChar(VarName), nil, 0);                    //Busco a vari�vel de ambiente e salvo seu tamanho

  if BufSize <= 0 then Exit;                                                    //Se a vari�vel de ambiente n�o existe ou n�o tem valor aborto o processamento

  SetLength(Result, BufSize - 1);                                               //Defino o tamanho do retorno da fun��o com o mesmo tamanho do buffer calculado
  GetEnvironmentVariable(PChar(VarName), PChar(Result), BufSize);               //Retorno o valor da vari�vel de ambiente
end;

{==| Fun��o - Obter Vers�o do OS |==============================================
    Retorna uma constante que identifica o sistema operacional onde a aplica��o
  est� rodando atualmente.
============================================| Leandro Medeiros (17/11/2011) |==}
function GetWindowsVersion: integer;
var
  VersionInfo : TOSVersionInfo;                                                 //Estrutura da API do Windows
begin
  VersionInfo.dwOSVersionInfoSize := SizeOf(VersionInfo);                       //Obtenho o tamanho da estrutura
  GetVersionEx(VersionInfo);                                                    //Alimento esta estrutura utilizando uma chamada da API
  Result := WIN_UNKNOWN;

  with VersionInfo do                                                           //Amarro a estrutura
  begin
    case dwPlatformid of                                                        //ID da plataforma (Gera��o)
      1 : case dwMinorVersion of                                                //Plataforma 1 > Windows 9X - Vers�o Minorit�ria Define
            0  : Result := WIN_95;
            10 : if (szCSDVersion[1] = 'A') then Result := WIN_98SE             //Se for Windows 98 Verifico a Edi��o
                 else                            Result := WIN_98;
            90 : Result := WIN_MILLENUM;
          end;

      2 : case dwMajorVersion of                                                //Plataforma 2 > Segunda Gera��o - Vers�o Majorit�ria (Kernel)
            3 : Result := WIN_NT3;
            4 : Result := WIN_NT4;
            5 : case dwMinorVersion of                                          //Kernel 5 pode ser 2000 ou XP, a vers�o minorit�ria � que define
                  0 : Result := WIN_2000;
                  1 : Result := WIN_XP;
                  2 : Result := WIN_SERVER2003; //ou Windows XP x64
                end;
            6 : case dwMinorVersion of                                           //Kernel 6 pode ser Vista, 7 ou 8. A vers�o minorit�ria � que define
                  0 : Result := WIN_VISTA_SERVER2008;
                  1 : Result := WIN_7_SERVER2008R2;
                  2 : Result := WIN_8;
                end;
          end;
    end;
  end;                                                                          //Final do With VersionInfo
end;

{==| Fun��o - Obter Nome do Computador e Nome do usu�rio |======================
    Retorna uma string concatenando o nome do computador com o nome do usu�rio
  que est� rodando a aplica��o. Fun��o utilizada para definir Metadados de um
  arquivo.
============================================| Leandro Medeiros (10/04/2014) |==}
function GetComputerAndUserName: string;
var
  sComputerName,
  sUserName : array [0 .. 255] of char;
  dwSize    : DWORD;
begin
  dwSize := SizeOf(sComputerName);

  GetComputerName(sComputerName, dwSize);
  GetUserName(sUserName, dwSize);

  Result := StrPas(sComputerName) + '\' + StrPas(sUserName);
end;

{==| Fun��o - Obter MAC Address |===============================================
    Faz a leitura dos dados de rede atrav�s da rpcrt4.dll (nativa do windows) e
  retorna o MAC Address da m�quina.
============================================| Leandro Medeiros (23/11/2011) |==}
function GetMacAddress: string;
var
  Lib  : Cardinal;
  Func : function(GUID: PGUID): Longint; stdcall;
  GUID1, GUID2 : TGUID;
begin
  Result := EmptyStr;                                                           //Assumo falha setando o resultado como string vazia

  Lib := LoadLibrary('rpcrt4.dll');                                             //Tento carregar a DLL do windows
  if Lib = 0 then Exit;                                                         //se n�o conseguir aborto o processamento

  @Func := GetProcAddress(Lib, 'UuidCreateSequential');                         //Tento chamar a fun��o respons�vel por obter as informa��es do adaptador de rede
  if not Assigned(Func) then Exit;                                              //e se n�o conseguir aborto o processamento

  if (Func(@GUID1) = 0) and                                                     //Se eu conseguir fazer a leitura de todos os dados
     (Func(@GUID2) = 0) and
     (GUID1.D4[2] = GUID2.D4[2]) and
     (GUID1.D4[3] = GUID2.D4[3]) and
     (GUID1.D4[4] = GUID2.D4[4]) and
     (GUID1.D4[5] = GUID2.D4[5]) and
     (GUID1.D4[6] = GUID2.D4[6]) and
     (GUID1.D4[7] = GUID2.D4[7]) then
  begin
    Result := IntToHex(GUID1.D4[2], 2) + '-'                                    //Retorno todos eles em uma string
            + IntToHex(GUID1.D4[3], 2) + '-'                                    //formatados como um MAC Address
            + IntToHex(GUID1.D4[4], 2) + '-'                                    //(elementos em Hexadecimal separados por tra�os)
            + IntToHex(GUID1.D4[5], 2) + '-'
            + IntToHex(GUID1.D4[6], 2) + '-'
            + IntToHex(GUID1.D4[7], 2);
  end;
end;

{==| Fun��o - Obter Nome do Computador |========================================
    Retorna o nome de rede do computador em que a aplica��o est� rodando
  (Formato: string).
============================================| Leandro Medeiros (24/05/2012) |==}
function GetComputerNetName: string;
var
  {$IFDEF VER150}
  Buffer: PAnsiChar;
  {$ELSE}
  Buffer: PWideChar;
  {$ENDIF}
  Size: dword;
begin
  Size   := 256;
  Result := 'Desconhecido';
  if GetComputerName(Buffer, Size) then Result := Buffer;
end;

{==| Fun��o - Obter IP na Rede |================================================
    Retorna o endere�o de IP do computador em que a aplica��o est� rodando
  (Formato: string).
============================================| Leandro Medeiros (24/05/2012) |==}
function GetLocalIP: string;
type
  pu_long = ^u_long;
var
  varTWSAData : TWSAData;
  varPHostEnt : PHostEnt;
  varTInAddr  : TInAddr;
  Buffer      : Array[0..255] of AnsiChar;
begin
  Result := 'Desconhecido';
  if WSAStartup($101, varTWSAData) <> 0 then Exit;

  GetHostName(Buffer, SizeOf(Buffer));
  varPHostEnt       := GetHostByName(Buffer);
  varTInAddr.S_addr := u_long(pu_long(varPHostEnt^.h_addr_list^)^);
  Result            := inet_ntoa(varTInAddr);
  WSACleanup;
end;

//==| Fun��o - Rede est� Conectada |============================================
function NetworkIsFine: Boolean;
begin
  Result := (GetSystemMetrics(SM_NETWORK) and $01) = $01;
end;

{==| Fun��o - Executa e Aguarda |===============================================
    Esta fun��o tem como objetivo executar uma aplica��o externa e aguardar que
  ela seja finalizada.
  Par�metros de Entrada:
    1. Nome do arquivo � ser rodado
      (pode conter par�metros concatenados)   > String.
    2. Modo em que a aplica��o ser� executada > Inteiro (Padr�o: Exibir).
  Retorno: Valor retornado pela aplica��o que foi executada.
============================================| Leandro Medeiros (01/11/2012) |==}
function WinExecAndWait(FileName:String; Visibility : integer = SW_SHOW): Variant;
var
  zAppName:array[0..512] of char;
  zCurDir:array[0..255] of char;
  WorkDir:String;
  StartupInfo:TStartupInfo;
  ProcessInfo:TProcessInformation;
  ExtCd: Cardinal;
begin
  StrPCopy(zAppName,FileName);
  GetDir(0,WorkDir);
  StrPCopy(zCurDir,WorkDir);
  FillChar(StartupInfo,Sizeof(StartupInfo),#0);
  StartupInfo.cb := Sizeof(StartupInfo);

  StartupInfo.dwFlags := STARTF_USESHOWWINDOW;
  StartupInfo.wShowWindow := Visibility;

  if not CreateProcess(nil,
                       zAppName, // pointer to command line string
                       nil, // pointer to process security attributes
                       nil, // pointer to thread security attributes
                       false, // handle inheritance flag
                       CREATE_NEW_CONSOLE or NORMAL_PRIORITY_CLASS,// creation flags
                       nil, // pointer to new environment block
                       nil, // pointer to current directory name
                       StartupInfo, // pointer to STARTUPINFO
                       ProcessInfo) then
    Result := -1 // pointer to PROCESS_INF

  else begin
    WaitforSingleObject(ProcessInfo.hProcess,INFINITE) ;
    GetExitCodeProcess(ProcessInfo.hProcess, ExtCd);
    Result := ExtCd;
  end;
end;

//==| Executa e Aguarda (Servi�o) |=============================================
function WinExecAndWait32(FileName: string; Visibility: integer): boolean;
var
  StartupInfo : TStartupInfo;
  ProcessInfo : TProcessInformation;
  fResult     : dword;
begin
  Result := False;
  FillChar(StartupInfo, Sizeof(StartupInfo), #0);
  StartupInfo.cb          := Sizeof(StartupInfo);
  StartupInfo.dwFlags     := STARTF_USESHOWWINDOW or STARTF_FORCEONFEEDBACK ;
  StartupInfo.wShowWindow := Visibility;

  if CreateProcess(nil,
                   PChar(Filename),
                   nil,
                   nil,
                   false,
                   CREATE_NEW_CONSOLE or NORMAL_PRIORITY_CLASS,
                   nil,
                   nil,
                   StartupInfo,
                   ProcessInfo) then
  begin
    WaitforSingleObject(ProcessInfo.hProcess, INFINITE);
    GetExitCodeProcess(ProcessInfo.hProcess, fResult);
    CloseHandle(ProcessInfo.hProcess);
    CloseHandle(ProcessInfo.hThread);
    Result := true;
  end;
end;

//==| Fun��o - Auto-ocultar da Barra de Tarefas Est� ligado? |==================
function IsTaskbarAutoHideOn: Boolean;
var
  ABData: TAppBarData;
begin
  ABData.cbSize := SizeOf(ABData);
   Result := (SHAppBarMessage(ABM_GETSTATE, ABData) and ABS_AUTOHIDE) > 0;
end;

//==| Fun��o - Obter Largura da Barra de Tarefas |==============================
function GetTaskBarHeight: integer;
var
  hTB: HWND; // taskbar handle
  TBRect: TRect; // taskbar rectangle
begin
  hTB:= FindWindow('Shell_TrayWnd', '');
  if hTB = 0 then
    Result := 0
  else begin
    GetWindowRect(hTB, TBRect);
    Result := TBRect.Bottom - TBRect.Top;
  end;
end;
//==============================================================================

end.
