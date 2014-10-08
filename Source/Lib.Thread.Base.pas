{===============================================================================

                          THREAD Medeiros - Classe Base

=========================================================| Leandro Medeiros |==}

unit Lib.Thread.Base;

interface

uses
  Classes;

{ Constantes }
const
  SLEEP_TIME = 100; //(milisegundos)
  ONE_MINUTE = 600;

{ Classes }
type
  TThreadBase = class(TThread)
  { Declarações Privadas }
  private
    FLoopRepeat   : integer;
    FSleepingTime : real;
    FReturnValue  : Cardinal;

    procedure Execute; override;
    procedure SetSleepingTime(const ASleepingTime: Real);

    property SleepingTime : real read FSleepingTime write SetSleepingTime;

  { Declarações Públicas }
  public
    constructor Create(const ACreateSuspended: Boolean = False;
      const ASleepingTime: integer = 1); overload; virtual;
    function Finish: Boolean; virtual;

  { Declarações Protegidas (Acessíveis a partir de classes filhas) }
  protected
    function MainRoutine : Boolean; virtual; abstract;
  end;

implementation

{ Bibliotecas para implementação }
uses
  SysUtils;


{*******************************************************************************

                              MÉTODOS PRIVADOS

*******************************************************************************}

//==| Execute |=================================================================
procedure TThreadBase.Execute;
var
  iSleeps : integer;
begin
  while not Self.Terminated and Self.MainRoutine do                             //Enquanto a Thread não é finalizada externa/internamente
  begin
    iSleeps := 0;                                                               //zero o contador de tempo de espera
    While (iSleeps < Self.FLoopRepeat) and (not Terminated) do                  //e enquanto o tempo de espera não for igual ao intervalo configurado, e a Thread não for finalizada
    begin
      {$IFDEF VER150}                                                           //a Thread "dorme" por 1 segundo
      Sleep(SLEEP_TIME);
      {$ELSE}
      Self.Sleep(SLEEP_TIME);
      {$ENDIF}
      System.Inc(iSleeps);                                                      //e incremento o contador de tempo de espera
    end;
  end;

  Self.ReturnValue := Self.FReturnValue;                                        //quando a Thread é finalizada, retorno valor predefinido para saber que não houve erros
end;

//==| Setter - Tempo em Repouso |===============================================
procedure TThreadBase.SetSleepingTime(const ASleepingTime: Real);
begin
  if ASleepingTime <= 0 then Self.FSleepingTime := 1
  else                       Self.FSleepingTime := ASleepingTime;

  Self.FLoopRepeat := System.Round(ONE_MINUTE * Self.FSleepingTime);
end;


{*******************************************************************************

                              MÉTODOS PÚBLICOS

*******************************************************************************}

//==| Construtor |==============================================================
constructor TThreadBase.Create(const ACreateSuspended: Boolean = False;
  const ASleepingTime: integer = 1);
begin
  inherited Create(ACreateSuspended);

  Self.SleepingTime := ASleepingTime;
  Self.FReturnValue := System.Round(Now);
end;

//==| Método de Classe - Parar Thread |=========================================
function TThreadBase.Finish: Boolean;
begin
  Result := Assigned(Self);                                                     //Verifico se a Thread está mesmo rodando

  if Result then                                                                //Caso esteja
  begin
    Self.Terminate;                                                             //Finalizo-a

    while Self.WaitFor <> Self.FReturnValue do                                  //e enquanto a mesma não retornar o valor correto,
      SysUtils.Sleep(10);                                                       //fico 10ms em stand-by

    SysUtils.FreeAndNil(Self);                                                  //Ao final sempre limpo a referência para o objeto
  end;
end;
//==============================================================================

end.
