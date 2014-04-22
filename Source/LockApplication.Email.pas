unit LockApplication.Email;

interface
uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls,  IdSMTP,
  LockApplication.Vars,IdMessage, LockApplication.Email.Status;



   procedure Enviar_email;



implementation

uses
   LockApplication;


procedure Enviar_email;
var
    email: TIdmessage;
    Serv: TIdSmtp;
    I: integer;
begin
{ *** CRIA OS COMPONENTES PARA ENVIO DO EMAIL *** }
    email := TIdMessage.Create(nil);
    serV := TIdSMTP.Create(nil);

        serV.Port := Variaveis.VPorta_SMTP;

    {$IFDEF VER150}
    Serv.AuthenticationType := atLogin;
    {$ELSE}
    Serv.AuthType := satDefault;
    {$ENDIF}
    Serv.Username := Variaveis.VUsuario_SMTP;
    Serv.Password := Variaveis.VSenha_SMTP;

    serV.Host := Variaveis.VServidor_SMTP;
    { Seta as propriedades do componente IdMessage }
    email.From.Address := Variaveis.VEmail_Remetente;
    email.From.Name := Variaveis.Email_Cliente;
    email.Recipients.EMailAddresses := Variaveis.VEmail_destino;
    email.Subject := Variaveis.VEmail_assunto;
//    email.Body.Text := Mensagem;
    email.ContentType := 'text/html';
    email.Body.Add( '<HTML> <head><title></title></head><body>');
    email.Body.Add('<P><STRONG><FONT color=#00008b>Licença do cliente abaixo está prestes a vencer!</FONT></STRONG></P>');
    email.Body.Add('<P><STRONG>E-Mail do cliente : </STRONG><A href="mailto:'+ Variaveis.Email_Cliente+'">'+ Variaveis.Email_Cliente+'</A></P>');
    email.Body.Add('<P><STRONG>ID da instalação&nbsp;: </STRONG>'+ IntToStr( Variaveis.ID_Instalacao ) +'</P>');
    email.Body.Add('<P><STRONG>Chave registrada&nbsp;: </STRONG>'+  variaveis.CHAVE_Registrada+'</P>');
    email.Body.Add('<P><STRONG>Data de vencimento&nbsp;: </STRONG>'+ Variaveis.Data_Vencimento+'</P>');
    email.Body.Add('<P><TABLE border=1 cellSpacing=0 cellPadding=0 width="50%"><TBODY><TR><TD>');
    email.Body.Add('<P align=center><FONT color=#00008b><STRONG>Mensagem personalizada</STRONG></FONT></P></TD></TR>');
    email.Body.Add('<TR><TD><P align=center>');

    for I := 0 to Variaveis.VEmail_mensagen.Count - 1 do
      begin
         email.Body.Add( Variaveis.VEmail_mensagen[I] + '<BR>');
      end;

    email.Body.Add('</P></TD></TR></TBODY></TABLE></P></body></html>');
    try
        try
            StatusEmail := TStatusEmail.Create( nil );
            StatusEmail.Show;
            Application.ProcessMessages;
            serV.Connect;
            serv.Authenticate;
            serV.Send(email);
        except
            raise Exception.Create('Erro ao enviar e-mail com informações de licença!');
        end;
    finally
        if serV.Connected then
          serV.Disconnect;
         StatusEmail.Close;
         StatusEmail.Free;
    end;
    email.Free;
    serV.Free;

end;


end.
