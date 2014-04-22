unit LockApplication.Controle;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Registry;

type
   TControle = class
       public
          Relogio: TTimer;
          procedure Gravar_Dados(Sender: TObject);
   end;

var
   Controle: TControle;
implementation

uses
   LockApplication, LockApplication.Func,
   LockApplication.Vars;

procedure TControle.Gravar_Dados(Sender: TObject);
{$IFNDEF VER150}
var
  Formats : TFormatSettings;
{$ENDIF}
begin
  {$IFDEF VER150}
   ShortDateFormat := 'dd/mm/yyyy';
  {$ELSE}
   Formats := TFormatSettings.Create;
   Formats.ShortDateFormat := 'dd/mm/yyyy';
  {$ENDIF}

   func.Protec;
   if date < StrTodate( Func.Ler_Valor( 'ULTIMA_DATA' ) ) then
      begin
         if Relogio <> nil then
            Relogio.Enabled := False;
         Messagedlg( 'Data foi modificada retorne para'
         +#13+'data igual ou superior a ' + Func.Ler_Valor( 'ULTIMA_DATA' ), mtError, [mbOK], 0 );
         Halt;
      end
   else
       begin
          if date = StrTodate( Func.Ler_Valor( 'ULTIMA_DATA' ) ) then
          if time < StrToTime( func.Ler_Valor('ULTIMA_HORA') ) then
             begin
                if relogio <> nil then
                   Relogio.Enabled := False;
                 Messagedlg( 'Hora foi modificada retorne para'
                 +#13+'hora maior que ' + Func.Ler_Valor( 'ULTIMA_HORA' ), mtError, [mbOK], 0 );
                 halt;
             end
          else
              begin
                 if Variaveis.Data_Vencimento <> '' then
                 if date >= StrtoDate(variaveis.Data_Vencimento) then
                    begin
                       Func.Gravar_hora_data;
                       if Relogio <> nil then
                          Relogio.Enabled := False;
                       Messagedlg( 'Prazo da licen�a expirou!' + #13 +
                       'entre em contato com o administrador!', mtWarning, [mbOK], 0 );
                       Halt;
                    end;
                 Func.Gravar_hora_data;
                 Func.Protec_Grava;
              end
          else
             begin
                 if Variaveis.Data_Vencimento <> '' then
                 if date >= StrtoDate(variaveis.Data_Vencimento) then
                    begin
                       Func.Gravar_hora_data;
                       if Relogio <> nil then
                          Relogio.Enabled := False;
                       Messagedlg( 'Prazo da licen�a expirou!' + #13 +
                       'entre em contato com o administrador!', mtWarning, [mbOK], 0 );
                       Halt;
                    end;
                 Func.Gravar_hora_data;
                 Func.Protec_Grava;

             end;
       end;
end;

end.
