{===============================================================================

                          THREAD Medeiros - Classe Base

=========================================================| Leandro Medeiros |==}

unit Lib.Thread.Base;

interface

uses
  Classes;

{ Constantes }
const
  SLEEP_TIME             = 100; //(milisegundos)
  ONE_MINUTE             = 600;
  LOG_THREAD_START       = 'Thread "%s" - Inst�nciada.';
  LOG_THREAD_END         = 'Thread "%s" - Finalizando.';
  LOG_MAIN_ROUTINE_START = 'Thread "%s" - In�cio da Rotina Principal.';
  LOG_MAIN_ROUTINE_END   = 'Thread "%s" - Fim da Rotina Principal, entrando em descan�o.';

{ Classes }
type
  TThreadBase = class(TThread)
  { Declara��es Privadas }
  private
    FLoopRepeat   : integer;
    FSleepingTime : real;
    FReturnValue  : Cardinal;
    FName         : String;

    procedure Execute; override;
    procedure SetSleepingTime(const ASleepingTime: Real);

  { Declara��es P�blicas }
  public
    constructor Create(const ACreateSuspended: Boolean = False;
      const ASleepingTime: integer = 1); overload; virtual;
    function Finish: Boolean; virtual;

  { Declara��es Protegidas (Acess�veis a partir de classes filhas) }
  protected
    function MainRoutine : Boolean; virtual; abstract;

    property SleepingTime : real   read FSleepingTime write SetSleepingTime;
    property Name         : String read FName         write FName;
  end;

implementation

{ Bibliotecas para implementa��o }
uses
  SysUtils, Lib.Files;


{*******************************************************************************

                              M�TODOS PRIVADOS

*******************************************************************************}

//==| Execute |=================================================================
procedure TThreadBase.Execute;
var
  iSleeps : integer;
begin
  while not Self.Terminated and Self.MainRoutine do                             //Enquanto a Thread n�o � finalizada externa/internamente
  begin
    Lib.Files.Log(LOG_MAIN_ROUTINE_END, [Self.Name]);

    iSleeps := 0;                                                               //zero o contador de tempo de espera
    While (iSleeps < Self.FLoopRepeat) and (not Terminated) do                  //e enquanto o tempo de espera n�o for igual ao intervalo configurado, e a Thread n�o for finalizada
    begin
      {$IFDEF VER150}                                                           //a Thread "dorme" por 1 segundo
      Sleep(SLEEP_TIME);
      {$ELSE}
      Self.Sleep(SLEEP_TIME);
      {$ENDIF}
      System.Inc(iSleeps);                                                      //e incremento o contador de tempo de espera
    end;

    Lib.Files.Log(LOG_MAIN_ROUTINE_START, [Self.Name]);
  end;

  Self.ReturnValue := Self.FReturnValue;                                        //quando a Thread � finalizada, retorno valor predefinido para saber que n�o houve erros
end;

//==| Setter - Tempo em Repouso |===============================================
procedure TThreadBase.SetSleepingTime(const ASleepingTime: Real);
begin
  if ASleepingTime <= 0 then Self.FSleepingTime := 1
  else                       Self.FSleepingTime := ASleepingTime;

  Self.FLoopRepeat := System.Round(ONE_MINUTE * Self.FSleepingTime);
end;


{*******************************************************************************

                              M�TODOS P�BLICOS

*******************************************************************************}

//==| Construtor |==============================================================
constructor TThreadBase.Create(const ACreateSuspended: Boolean = False;
  const ASleepingTime: integer = 1);
begin
  inherited Create(ACreateSuspended);

  Self.SleepingTime := ASleepingTime;
  Self.FReturnValue := System.Round(Now);

  Self.NameThreadForDebugging(Self.Name);
  Lib.Files.Log(LOG_THREAD_START, [Self.Name]);
end;

//==| M�todo de Classe - Parar Thread |=========================================
function TThreadBase.Finish: Boolean;
begin
  Lib.Files.Log(LOG_THREAD_END, [Self.Name]);

  Result := Assigned(Self);                                                     //Verifico se a Thread est� mesmo rodando

  if Result then                                                                //Caso esteja
  begin
    Self.Terminate;                                                             //Finalizo-a

    while Self.WaitFor <> Self.FReturnValue do                                  //e enquanto a mesma n�o retornar o valor correto,
      SysUtils.Sleep(10);                                                       //fico 10ms em stand-by

    SysUtils.FreeAndNil(Self);                                                  //Ao final sempre limpo a refer�ncia para o objeto
  end;
end;
//==============================================================================

end.
