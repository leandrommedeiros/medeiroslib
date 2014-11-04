unit LockApplication;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, LockApplication.Vars, LockApplication.Interfaces,
  LockApplication.Func, inifiles, LockApplication.Controle, ExtCtrls,
  LockApplication.Email, Wininet, LockApplication.Cadastro.Unt;


type
  TLockApplication = class(TComponent)

  protected
    { Protected declarations }
{       VAut_SSL: Boolean;
       VServidor_SMTP: String;
       VUsuario_SMTP: String;
       VSenha_SMTP: String;
       VPorta_SMTP: integer;
       VEmail_Remetente: String;
       VEmail_destino: String;
       VEmail_assunto: String;
       VEmail_mensagen: TStrings;
       VDias_email: integer;
       VEnviar_Email: Boolean;}

             Mensagen: TStrings;
             Versao_do_Sistema: integer;
             Informacao_adc: boolean;
             nomeclientev: string;
             cpfclientev: string;
             enderecov: string;
             cidadev: string;
             telefonev: string;
             estadov: string;
             Versao_trialV: integer;

    function GetVAut_SSL: Boolean;
    procedure SetVAut_SSL( value: Boolean );
    function GetVEnviar_email: Boolean;
    procedure SetVEnviar_email( value: Boolean );
    function GetVServidor_email: String;
    procedure SetVServidor_email( value: String );
    function GetVUsuario_SMTP: String;
    procedure SetVUsuario_SMTP( value: String );
    function GetVSenha_SMTP: String;
    procedure SetVSenha_SMTP( value: String );
    function GetVEmail_remetente: String;
    procedure SetVEmail_remetente( value: String );
    function GetVPorta_SMTP: integer;
    procedure SetVPorta_SMTP( value: integer );
    function GetVEmail_destino: String;
    procedure SetVEmail_destino( value: String );
    function GetVEmail_assunto: String;
    procedure SetVEmail_assunto( value: String );
    procedure SetVEmail_mensagen( value: TStrings );
    function GetVDias_email: integer;
    procedure SetVDias_email( value: integer );


    function GetDias_restantes: int64;
    function GetData_vencimento: String;
    function GetEmail_Cliente: String;
    function GetChave_registrada: String;
    function GetSistema_Demo: Boolean;
    
    function GetEmpresa_email: String;
    procedure SetEmpresa_email( value: String );

    function GetEmpresa_site: String;
    procedure SetEmpresa_site( value: String );

    function GetEmpresa_telefones: String;
    procedure SetEmpresa_telefones( value: String );

    function GetChave_Crypt: String;
    procedure SetChave_Crypt( value: String );

    function GetID_Sistema: int64;
    procedure SetID_Sistema( value: int64 );

    function GetDias_Trial: int64;
    procedure SetDias_Trial( value: int64 );

    function GetTrial: Boolean;
    procedure SetTrial( value: Boolean );

    function GetMostrar_Tela: Boolean;
    procedure SetMostrar_Tela( value: Boolean );

    function GetTitulo_Janelas: String;
    procedure SetTitulo_Janelas( value: String );

    function GetLocal_Registro: String;
    procedure SetLocal_Registro( value: String );

    function GetIDInstalacao: Int64;

    procedure Nunca_Registrado();
    procedure Ja_Registrado();
    procedure registrar( ativar: boolean );

    // INFORMACOES
    procedure ler_dados;




  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    procedure executar;
    procedure renovar;
    property IDInstalacao: Int64 read GetIDInstalacao;
    property Versao_Sistema: Integer read Versao_do_sistema;
    property Dias_RestantesU: int64 read GetDias_restantes;
    property Data_VencimentoU: string read GetData_Vencimento;
    property Email_ClienteU: string read GetEmail_Cliente;
    property Chave_RegistradaU: String read GetChave_Registrada;
    property Sistema_DemoU: Boolean read GetSistema_demo;            
    function Gera_Chave_Dias( ID_Instalacao, ID_Sistema, Dias, Versao_Sistema: int64 ):String;
    function Gera_Chave_Data( ID_Instalacao, ID_Sistema: int64; data: String; Versao_Sistema: int64 ):String;
    property Cliente_Nome: string read NomeClientev;
    property Cliente_CPF: string read cpfclientev;
    property Cliente_Endereco: string read enderecov;
    property Cliente_Cidade: string read cidadev;
    property Cliente_Estado: string read Estadov;
    property Cliente_Telefone: string read telefonev;
    procedure Atualizar_Cadastro;

  published
    { Published declarations }
    property IDSistema: int64 read GetID_Sistema write SetID_Sistema;
    property Demostracao: Boolean read GetTrial write SetTrial;
    property Informacoes_adicionais: Boolean read informacao_adc write informacao_adc;
    property Mostrar_Tela_Primeira_Vez: Boolean read GetMostrar_Tela write
    SetMostrar_Tela;
    property Dias_Demostracao: int64 read GetDias_Trial write SetDias_Trial;
    property Local_Registro: String read GetLocal_registro write SetLocal_Registro;
    property Chave_Criptografia: String read GetChave_Crypt write SetChave_Crypt;
    property Titulo_das_janelas: String read GetTitulo_Janelas write SetTitulo_Janelas;
    property Email_de_contato: String read GetEmpresa_email write SetEmpresa_Email;
    property Site_da_Empresa: String read GetEmpresa_Site write SetEmpresa_Site;
    property Telefones_de_Contato: String read GetEmpresa_telefones write SetEmpresa_telefones;
    property  Versao_Trial: integer read Versao_trialV write Versao_trialV;

    // EMAIL

//    property SMTP_SSL: Boolean read GetVAut_SSL write SetVAut_SSL;
    property SMTP_Servidor: String read GetVServidor_email write SetVServidor_email;
    property SMTP_Usuario: String read GetVUsuario_SMTP write SetVUsuario_SMTP;
    property SMTP_Senha: String read GetVSenha_SMTP write SetVSenha_SMTP;
    property SMTP_Porta: integer read GetVPorta_SMTP write SetVPorta_SMTP;
    property EMAIL_Enviar: Boolean read GetVEnviar_email write SetVEnviar_email;
    property EMAIL_Remetente: String read GetVEmail_remetente write SetVEmail_Remetente;
    property EMAIL_Destino: String read GetVEmail_destino write SetVEmail_destino;
    property EMAIL_Assunto: String read GetVEmail_assunto write SetVEmail_assunto;
    property EMAIL_Mensagen: TStrings read Mensagen write SetVEmail_mensagen;
    property EMAIL_Dias_enviar: integer read GetVDias_email write SetVDias_email;
  end;

implementation


constructor TLockApplication.Create(AOwner: TComponent);
begin

  inherited create(AOwner);
   Func := TFunc.Create;
   Variaveis := TVariaveis.Create;
   Variaveis.ID_Sistema := 10;
   Variaveis.Dias_Trial := 30;
   Variaveis.Trial := True;
   informacao_adc := false;
   Versao_trialV := 1;
   Variaveis.Local_Registro := '\Software\Appro';
   Variaveis.Chave_Crypt := 'LockApplication';
   Variaveis.Titulo_Janelas := 'Seu título aqui';
   Variaveis.Mostrar_Tela := True;
   Variaveis.Empresa_Email := '';
   Variaveis.Empresa_Site := '';
   Variaveis.Empresa_Telefones := '';
   Variaveis.VEmail_mensagen := TStringList.Create;
   Mensagen := TStringList.Create;
   variaveis.VEmail_mensagen.Clear;
   Variaveis.VDias_email := 5;
   Variaveis.VAut_SSL := False;
   Variaveis.VEnviar_Email := false;
end;

procedure TLockApplication.executar;
begin
  Controle                := TControle.Create;
  Variaveis.ID_Instalacao := Func.GetID_Instalacao;

  if (Func.Protect_existe) and not (Func.Chave_Criada) then
  begin
    MessageDlg('Registro foi alterado pelo usuário e será recuperado!', mtError, [mbOK], 0);
    Func.Criar_Chave;
    Func.Protec_Recuperar;
  end;

  if Func.Chave_Criada then Ja_Registrado()
  else                      Nunca_Registrado();
end;

procedure TLockApplication.Renovar;
begin
  Controle.Relogio.Enabled := False;
  Registrar(True);
  Controle.Relogio.Enabled := True;
end;

procedure TLockApplication.Nunca_Registrado();
  label InicioTrue, Sem_Mostrar_Tela;
var
  Retorno_Processa: TStrings;
  erro_processa: Boolean;
  ChaveTemp : Int64;
  Conta_dias: double;
begin
   Retorno_Processa := TStringList.Create;
   case Variaveis.Mostrar_Tela of
       False:begin
                variaveis.CHAVE_TELA := 'DEMONSTRAÇÃO';
                variaveis.EMAIL_TELA := 'NÃO INFORMADO';
                goto Sem_Mostrar_Tela;
             end;
       True: begin
                Bloqueio := TBloqueio.Create( nil );
                if Variaveis.Trial then
                   Bloqueio.TELA_ContraChave := 'DEMONSTRAÇÃO';
                Bloqueio.Ativar := False;
                Variaveis.Ja_Foi_Trial := False;
                InicioTrue: Bloqueio.ShowModal;// INICIO CASO SEM SUCESSO NO REGISTRO
                if not Bloqueio.Fechado_Sem_Registro then
                   begin
                      variaveis.CHAVE_TELA := Bloqueio.TELA_ContraChave;
                      variaveis.EMAIL_TELA := Bloqueio.TELA_Email;
                      Sem_Mostrar_Tela: if (variaveis.CHAVE_TELA = 'DEMONSTRAÇÃO') and not (variaveis.Trial) then
                         begin
                            MessageDlg( 'Sistema não liberado para demonstração', mtWarning, [mbOK], 0 );
                            goto inicioTrue;
                         end;

                         if not ( Variaveis.CHAVE_TELA = 'DEMONSTRAÇÃO') then
                            begin   // INICIO CHAVE NORMAL

                               try       // MOMENDO DE PROCESSAMENTO DA CHAVE;
                                   erro_Processa := False;
                                   func.Processa_Chave( Variaveis.CHAVE_TELA, Retorno_Processa );
                                   if not ( pos( 'CHAVE_INVALIDA', Retorno_Processa[0] ) > 0 ) then // VER SE CHAVE É VALIDA
                                      begin
                                         variaveis.DIAS_SEPARADO := StrToInt64( Retorno_Processa[0] );
                                         Variaveis.CHAVE_SEPARADA := StrToInt64( Retorno_processa[1] );
                                         Variaveis.DATA_SEPARADA :=  Retorno_processa[2];
                                         StrToDate( Variaveis.DATA_SEPARADA );
                                         Versao_do_Sistema := StrToint( Retorno_Processa[3] ) - Variaveis.ID_Sistema;
                                      end
                                   else   // CHAVE INVáLIDA
                                      erro_processa := true;
                               except
                                  erro_processa := True;
                               end;      // FIM PROCESSAMENTO DA CHAVE;

                               if Erro_Processa then   // SE OUVER ERRO NA CHAVE VOLTA PARA A TELA
                                  begin
                                      MessageDlg( 'Chave informada é inválida!' + #13 +
                                      'Entre em contato com o administrador do sistema', mtError, [mbok],0);
                                      goto InicioTrue;
                                  end;

                               ChaveTemp := Func.FGerar_Chave( Variaveis.ID_Instalacao,
                               Variaveis.ID_Sistema, StrToDate( Variaveis.DATA_SEPARADA ) );
                               if not (Chavetemp = Variaveis.CHAVE_SEPARADA )then
                                  begin                                      // CHAVE NÃO CORRETA
                                      MessageDlg( 'Chave informada é inválida!' + #13 +
                                      'Entre em contato com o administrador do sistema', mtError, [mbok],0);
                                      goto InicioTrue;
                                  end;
                               Func.Criar_Chave;
                               if Func.ver_chave_lista( Variaveis.CHAVE_TELA ) then
                                   begin
                                      MessageDlg( 'Chave já utilizada antes!', mtError, [mbok],0);
                                      goto InicioTrue;
                                   end;
                               Func.Gravar_Valor( 'CHAVE', Variaveis.CHAVE_TELA );
                               if Variaveis.DIAS_SEPARADO = 0 then
                                  begin
                                     Variaveis.Dias_Restantes := -1;
                                     Variaveis.Data_Vencimento := '';
                                     Func.Gravar_Valor( 'DATA_VENCIMENTO', '');
                                     Func.Gravar_Valor( 'EMAIL', variaveis.EMAIL_TELA );
                                     MessageDlg( 'Licença sem prazo de expiração!', mtInformation, [mbok],0);
                                  end
                               else
                                  begin
                                     Conta_dias := Variaveis.DIAS_SEPARADO - ( date - StrtoDate( variaveis.DATA_SEPARADA) );
                                     Variaveis.Dias_Restantes := StrToInt64(FloatToStr( Conta_Dias));
                                     Variaveis.Data_Vencimento := DateToStr( date + Variaveis.Dias_Restantes );
                                     Func.Gravar_Valor( 'DATA_VENCIMENTO', variaveis.Data_Vencimento );
                                     Func.Gravar_Valor( 'EMAIL', variaveis.EMAIL_TELA );
                                     MessageDlg( 'Licença para ' + IntToStr( Variaveis.Dias_Restantes )
                                               + ' dia(s)!', mtInformation, [mbok],0);
                                  end;

                               Variaveis.Email_Cliente := func.Ler_Valor( 'EMAIL');
                               Variaveis.CHAVE_Registrada := func.Ler_Valor( 'CHAVE');
                               if Variaveis.CHAVE_Registrada = 'DEMONSTRAÇÃO' then
                                  begin
                                   Variaveis.SISTEMA_DEMO := true;
                                   Versao_do_sistema := Versao_trialV;
                                  end
                               else
                                  Variaveis.SISTEMA_DEMO := false;

                              try
                              if Variaveis.VEnviar_Email then

                              if ( Variaveis.Dias_Restantes <= Variaveis.VDias_email ) and ( Variaveis.Dias_Restantes > -1 ) then
                                 begin
                                    if InternetCheckConnection('http://www.google.com.br/', 1, 0) then
                                    if Func.Ler_Valor( 'DATA_EMAIL' ) <> '' then
                                       begin
                                          if date > StrToDate( func.Ler_Valor( 'DATA_EMAIL' ) ) then
                                             begin
                                                Func.Gravar_Valor( 'DATA_EMAIL', dateToStr( date ) );
                                                Variaveis.VEmail_mensagen := Mensagen;
                                                enviar_email;
                                             end;
                                       end
                                    else
                                       begin
                                          Func.Gravar_Valor( 'DATA_EMAIL', dateToStr( date ) );
                                                Variaveis.VEmail_mensagen := Mensagen;
                                          enviar_email;
                                       end;
                                 end;
                              except
                                  Func.Gravar_Valor( 'DATA_EMAIL', dateToStr( date ) );
                              end;
                               if Informacao_adc then
                               begin
                               cadastro := TCadastro.Create( nil );
                               Cadastro.Showmodal;
                               Func.Gravar_Valor( 'NOMECLIENTE', cadastro.Nome.Text );
                               Func.Gravar_Valor( 'CPF', cadastro.cpf.Text );
                               Func.Gravar_Valor( 'ENDERECO', cadastro.endereco.Text );
                               Func.Gravar_Valor( 'CIDADE', cadastro.cidade.Text );
                               Func.Gravar_Valor( 'ESTADO', cadastro.estado.Text );
                               Func.Gravar_Valor( 'TELEFONE', cadastro.telefone.Text );
                               cadastro.Free;

                               end;
                               if informacao_adc then
                                  ler_dados;
                               Func.Gravar_hora_data;
                               Func.Protec_Grava;
                               Func.Iniciar_Relogio;

                            end     // FIM CHAVE NORMAL
                         else


                            begin    // INICIO CHAVE DEMO


                               Func.Criar_Chave;
                               if Func.ver_chave_lista( Variaveis.CHAVE_TELA ) then
                                   begin
                                      MessageDlg( 'Chave já utilizada antes!', mtError, [mbok],0);
                                      goto InicioTrue;
                                   end;
                                     Func.Gravar_Valor( 'CHAVE', Variaveis.CHAVE_TELA );
                                     Variaveis.Dias_Restantes := Variaveis.Dias_Trial;
                                     Variaveis.Data_Vencimento := DateToStr( date + Variaveis.Dias_Restantes );
                                     Func.Gravar_Valor( 'DATA_VENCIMENTO', variaveis.Data_Vencimento );
                                     Func.Gravar_Valor( 'EMAIL', variaveis.EMAIL_TELA );
                                     //MessageDlg( 'Demonstração de ' + IntToStr( Variaveis.Dias_Restantes ) + ' dia(s)!', mtInformation, [mbok],0);

                               Variaveis.Email_Cliente := func.Ler_Valor( 'EMAIL');
                               Variaveis.CHAVE_Registrada := func.Ler_Valor( 'CHAVE');
                               if Variaveis.CHAVE_Registrada = 'DEMONSTRAÇÃO' then
                                  begin
                                  Variaveis.SISTEMA_DEMO := true;
                                  Versao_do_sistema := Versao_trialV;
                                  end
                               else
                                  Variaveis.SISTEMA_DEMO := false;

                              try
                              if Variaveis.VEnviar_Email then
                              if ( Variaveis.Dias_Restantes <= Variaveis.VDias_email ) and ( Variaveis.Dias_Restantes > -1 ) then
                                 begin
                                    if InternetCheckConnection('http://www.google.com.br/', 1, 0) then
                                    if Func.Ler_Valor( 'DATA_EMAIL' ) <> '' then
                                       begin
                                          if date > StrToDate( func.Ler_Valor( 'DATA_EMAIL' ) ) then
                                             begin
                                                Func.Gravar_Valor( 'DATA_EMAIL', dateToStr( date ) );
                                                Variaveis.VEmail_mensagen := Mensagen;
                                                enviar_email;
                                             end;
                                       end
                                    else
                                       begin
                                          Func.Gravar_Valor( 'DATA_EMAIL', dateToStr( date ) );
                                                Variaveis.VEmail_mensagen := Mensagen;
                                          enviar_email;
                                       end;
                                 end;
                              except
                                  Func.Gravar_Valor( 'DATA_EMAIL', dateToStr( date ) );
                              end;
                               if Informacao_adc then
                               begin
                               cadastro := TCadastro.Create( nil );
                               Cadastro.Showmodal;
                               Func.Gravar_Valor( 'NOMECLIENTE', cadastro.Nome.Text );
                               Func.Gravar_Valor( 'CPF', cadastro.cpf.Text );
                               Func.Gravar_Valor( 'ENDERECO', cadastro.endereco.Text );
                               Func.Gravar_Valor( 'CIDADE', cadastro.cidade.Text );
                               Func.Gravar_Valor( 'ESTADO', cadastro.estado.Text );
                               Func.Gravar_Valor( 'TELEFONE', cadastro.telefone.Text );

                               cadastro.Free;
                               end;

                               if informacao_adc then
                                  ler_dados;
                               func.Gravar_hora_data;
                               Func.Protec_Grava;
                               func.Iniciar_Relogio;


                            end;     // FIM CHAVE DEMO

                      Bloqueio.Free; // FINAL
                   end
                else
                   begin
                      Bloqueio.Free;

                      Func.fechar_sistema;
                   end;
             end;
   end;
    Retorno_Processa.Free;
end;

procedure TLockApplication.Ja_Registrado();
label inicio, inicioTRIAL;
var
  CHAVE_RETIRADA   : String;
  DATA_VENCIMENTO  : String;
  Erro_Processa    : Boolean;
  Retorno_Processa : TStrings;
  Chave_temp       : Int64;
  Conta            : Double;
begin
  Func.Protec;
  CHAVE_RETIRADA := Func.Ler_Valor( 'CHAVE' );

  if CHAVE_RETIRADA <> 'DEMONSTRAÇÃO' then
    inicio: begin       // INCIO CHAVE NORMAL
      CHAVE_RETIRADA := Func.Ler_Valor('CHAVE');
      if CHAVE_RETIRADA = 'DEMONSTRAÇÃO' then
      begin
        Variaveis.SISTEMA_DEMO := True;
        Versao_do_sistema      := Versao_trialV;
      end
      else Variaveis.SISTEMA_DEMO := False;

      Variaveis.CHAVE_Registrada := CHAVE_RETIRADA;
      Data_Vencimento            := Func.Ler_Valor('DATA_VENCIMENTO');
      Variaveis.Data_Vencimento  := Data_vencimento;
      Variaveis.Email_Cliente    := Func.Ler_Valor('EMAIL');
      Variaveis.Ja_Foi_Trial     := Func.ver_chave_lista('DESMOSTRAÇÃO');

      retorno_Processa := TStringList.Create;
      try       // MOMENDO DE PROCESSAMENTO DA CHAVE;
        erro_Processa := False;
        func.Processa_Chave(Chave_retirada, Retorno_Processa);
        if not (Pos('CHAVE_INVALIDA', Retorno_Processa[0]) > 0) then // VER SE CHAVE É VALIDA
        begin
          Variaveis.DIAS_SEPARADO  := StrToInt64(Retorno_Processa[0]);
          Variaveis.CHAVE_SEPARADA := StrToInt64(Retorno_processa[1]);
          Variaveis.DATA_SEPARADA  := Retorno_processa[2];
          StrTodate(Variaveis.DATA_SEPARADA);
          Versao_do_Sistema        := StrToint( Retorno_Processa[3] ) - Variaveis.ID_Sistema;
        end
        else erro_processa := true; // CHAVE INVáLIDA
      except
        erro_processa := True;
      end;      // FIM PROCESSAMENTO DA CHAVE;

      if erro_processa then
      begin
        messagedlg('Licença registra é inválida!', mtError, [mbOK], 0);
        registrar( false );
        goto inicio;
      end;

      Chave_temp := Func.FGerar_Chave(Variaveis.ID_Instalacao,
                                      Variaveis.ID_Sistema,
                                      StrToDate(Variaveis.DATA_SEPARADA));

      if not (Variaveis.CHAVE_SEPARADA = Chave_temp) then
      begin
        messagedlg('Licença registra é inválida!', mtError, [mbOK], 0);
        registrar(false);
        goto inicio;
      end;

      if Variaveis.Data_Vencimento = '' then
      begin   // CHAVE SEM PRAZO
        if Func.ver_chave_lista( Chave_Retirada ) then
        begin
          messagedlg( 'Licença registra já utilizada!', mtError, [mbOK], 0 );
          registrar( false );
          goto inicio;
        end;

        Variaveis.Dias_Restantes := -1;

        if informacao_adc then ler_dados;

        Controle.Gravar_Dados(Application);
        Func.Protec_Grava;
        Func.Iniciar_Relogio;
      end     // FIM CHAVE SEM PRAZO
      else begin   /// VER DIAS RESTANTES;
        Conta                    := (StrToDate(Func.Ler_Valor('DATA_VENCIMENTO')) - date);
        Variaveis.Dias_Restantes := StrToInt64(FloatToStr( Conta ));

        if Variaveis.Dias_Restantes <= 0 then
        begin
          if not Func.ver_chave_lista(chave_retirada) then Func.gravar_chave_lista(chave_retirada);

          messagedlg('Licença expirou!' + #13 + 'Entre em contato com o administrador do sistema!', mtError, [mbOK], 0);
          Registrar(False);
          goto inicio;
        end;

        if Func.ver_chave_lista(Chave_Retirada) then
        begin
          messagedlg('Licença registra já utilizada!', mtError, [mbOK], 0);
          registrar(false);
          goto inicio;
        end;

        try
          if Variaveis.VEnviar_Email then
            if (Variaveis.Dias_Restantes <= Variaveis.VDias_email) and
               (Variaveis.Dias_Restantes > -1) then
            begin
              if InternetCheckConnection('http://www.google.com.br/', 1, 0) then
                if Func.Ler_Valor('DATA_EMAIL') <> '' then
                begin
                  if date > StrToDate(Func.Ler_Valor('DATA_EMAIL')) then
                  begin
                    Func.Gravar_Valor('DATA_EMAIL', dateToStr(date));
                    Variaveis.VEmail_mensagen := Mensagen;
                    enviar_email;
                  end;
                end

                else begin
                  Func.Gravar_Valor('DATA_EMAIL', dateToStr(date));
                  Variaveis.VEmail_mensagen := Mensagen;
                  enviar_email;
                end;
            end;
        except
          Func.Gravar_Valor('DATA_EMAIL', dateToStr(date));
        end;

        if informacao_adc then ler_dados;

        Controle.Gravar_Dados(Application);
        Func.Protec_Grava;
        Func.Iniciar_Relogio;
      end;   // FIM VER DIAS
    end         // FIM CHAVE NORMAL

    else
      inicioTrial: begin      /// INICIO CHAVE DEMO
        CHAVE_RETIRADA := Func.Ler_Valor('CHAVE');
        if CHAVE_RETIRADA = 'DEMONSTRAÇÃO' then
        begin
          Variaveis.SISTEMA_DEMO := True;
          Versao_do_sistema      := Versao_trialV;
        end
        else Variaveis.SISTEMA_DEMO := False;

        Variaveis.CHAVE_Registrada := CHAVE_RETIRADA;
        Data_Vencimento            := Func.Ler_Valor('DATA_VENCIMENTO');
        Variaveis.Data_Vencimento  := Data_vencimento;
        Variaveis.Email_Cliente    := Func.Ler_Valor('EMAIL');
        Variaveis.Ja_Foi_Trial     := Func.ver_chave_lista('DESMOSTRAÇÃO');
        Conta                      := (StrToDate(Func.Ler_Valor('DATA_VENCIMENTO')) - date);
        Variaveis.Dias_Restantes   := StrToInt64(FloatToStr(Conta));

        if Variaveis.Dias_Restantes <= 0 then
        begin
          if not Func.ver_chave_lista(chave_retirada) then Func.gravar_chave_lista(chave_retirada);

          messagedlg('Prazo de demonstração expirou!' + #13 + 'Entre em contato com o administrador do sistema!', mtError, [mbOK], 0);
          Registrar(False);
          goto iniciotrial;
        end;

        if Func.ver_chave_lista( Chave_Retirada ) then
        begin
          messagedlg('Licença registra já utilizada!', mtError, [mbOK], 0);
          registrar(False);
          goto iniciotrial;
        end;

        try
          if Variaveis.VEnviar_Email then
            if (Variaveis.Dias_Restantes <= Variaveis.VDias_email) and
               (Variaveis.Dias_Restantes > -1) then
            begin
              if InternetCheckConnection('http://www.google.com.br/', 1, 0) then
                if Func.Ler_Valor('DATA_EMAIL') <> '' then
                begin
                  if date > StrToDate(Func.Ler_Valor('DATA_EMAIL')) then
                  begin
                    Func.Gravar_Valor('DATA_EMAIL', dateToStr(date));
                    Variaveis.VEmail_mensagen := Mensagen;
                    enviar_email;
                  end;
                end
                else begin
                  Func.Gravar_Valor('DATA_EMAIL', dateToStr(date));
                  Variaveis.VEmail_mensagen := Mensagen;
                  enviar_email;
                end;
            end;
        except
          Func.Gravar_Valor('DATA_EMAIL', dateToStr(date));
        end;

        if informacao_adc then ler_dados;

        Controle.Gravar_Dados(Application);
        Func.Protec_Grava;
        Func.Iniciar_Relogio;
      end;       // FIM CHAVE DEMO
end;

procedure TLockApplication.registrar( ativar: boolean);
label InicioTrue;
var
   Erro_Processa, fechar: Boolean;
   Retorno_Processa: TStrings;
   ChaveTemp: int64;
   Conta_dias: double;
begin

                Retorno_Processa := TStringList.create;
                Bloqueio := TBloqueio.Create( nil );
                Bloqueio.TELA_Email := Func.Ler_Valor( 'EMAIL');
                Bloqueio.Ativar := ativar;
                InicioTrue: Bloqueio.ShowModal;// INICIO CASO SEM SUCESSO NO REGISTRO
                if not Bloqueio.Fechado_Sem_Registro then
                   begin
                      variaveis.CHAVE_TELA := Bloqueio.TELA_ContraChave;
                      variaveis.EMAIL_TELA := Bloqueio.TELA_Email;
                      if (variaveis.CHAVE_TELA = 'DEMONSTRAÇÃO') then
                         begin
                            MessageDlg( 'Sistema não pode ser registrado como Demonstração', mtWarning, [mbOK], 0 );
                            goto inicioTrue;
                         end;

                            begin   // INICIO CHAVE NORMAL

                               try       // MOMENDO DE PROCESSAMENTO DA CHAVE;
                                   erro_Processa := False;
                                   func.Processa_Chave( Variaveis.CHAVE_TELA, Retorno_Processa );
                                   if not ( pos( 'CHAVE_INVALIDA', Retorno_Processa[0] ) > 0 ) then // VER SE CHAVE É VALIDA
                                      begin
                                         variaveis.DIAS_SEPARADO := StrToInt64( Retorno_Processa[0] );
                                         Variaveis.CHAVE_SEPARADA := StrToInt64( Retorno_processa[1] );
                                         Variaveis.DATA_SEPARADA :=  Retorno_processa[2];
                                         StrTodate( Variaveis.DATA_SEPARADA );
                                         Versao_do_Sistema := StrToint( Retorno_Processa[3] ) - Variaveis.ID_Sistema;
                                      end
                                   else   // CHAVE INVáLIDA
                                      erro_processa := true;
                               except
                                  erro_processa := True;
                               end;      // FIM PROCESSAMENTO DA CHAVE;

                               if Erro_Processa then   // SE OUVER ERRO NA CHAVE VOLTA PARA A TELA
                                  begin
                                      MessageDlg( 'Chave informada é inválida!' + #13 +
                                      'Entre em contato com o administrador do sistema', mtError, [mbok],0);
                                      goto InicioTrue;
                                  end;

                               ChaveTemp := Func.FGerar_Chave( Variaveis.ID_Instalacao,
                               Variaveis.ID_Sistema, StrToDate( Variaveis.DATA_SEPARADA ) );
                               if not (Chavetemp = Variaveis.CHAVE_SEPARADA )then
                                  begin                                      // CHAVE NÃO CORRETA
                                      MessageDlg( 'Chave informada é inválida!' + #13 +
                                      'Entre em contato com o administrador do sistema', mtError, [mbok],0);
                                      goto InicioTrue;
                                  end;

                               Func.Criar_Chave;
                               if Func.ver_chave_lista( Variaveis.CHAVE_TELA ) or (  Variaveis.CHAVE_TELA = Func.Ler_Valor( 'CHAVE' ) )then
                                   begin
                                      MessageDlg( 'Chave já utilizada antes!', mtError, [mbok],0);
                                      goto InicioTrue;
                                   end;
                               Func.gravar_chave_lista( Func.Ler_Valor( 'CHAVE' ));
                               Func.Gravar_Valor( 'CHAVE', Variaveis.CHAVE_TELA );
                               if Variaveis.DIAS_SEPARADO = 0 then
                                  begin
                                     Variaveis.Dias_Restantes := -1;
                                     Variaveis.Data_Vencimento := '';
                                     Func.Gravar_Valor( 'DATA_VENCIMENTO', '');
                                     Func.Gravar_Valor( 'EMAIL', variaveis.EMAIL_TELA );
                                     MessageDlg( 'Licença sem prazo de expiração!', mtInformation, [mbok],0);
                                  end
                               else
                                  begin
                                     Conta_dias := Variaveis.DIAS_SEPARADO - ( date - StrtoDate( variaveis.DATA_SEPARADA) );
                                     Variaveis.Dias_Restantes := StrToInt64(FloatToStr( Conta_Dias));
                                     Variaveis.Data_Vencimento := DateToStr( date + Variaveis.Dias_Restantes );
                                     Func.Gravar_Valor( 'DATA_VENCIMENTO', variaveis.Data_Vencimento );
                                     Func.Gravar_Valor( 'EMAIL', variaveis.EMAIL_TELA );
                                     MessageDlg( 'Licença para ' + IntToStr( Variaveis.Dias_Restantes ) + ' dia(s)!', mtInformation, [mbok],0);
                                  end;

                               Variaveis.Email_Cliente := func.Ler_Valor( 'EMAIL');
                               Variaveis.CHAVE_Registrada := func.Ler_Valor( 'CHAVE');
                               if Variaveis.CHAVE_Registrada = 'DEMONSTRAÇÃO' then
                                 begin
                                  Variaveis.SISTEMA_DEMO := true;
                                  versao_do_Sistema := Versao_trialV;
                                 end
                               else
                                  Variaveis.SISTEMA_DEMO := false;

                            end;     // FIM CHAVE NORMAL
                      Retorno_Processa.Free;
                      Bloqueio.Free; // FINAL
                   end
                else
                   begin
                      if ativar then
                         fechar := false
                      else
                         fechar := true;
                      Bloqueio.Free;
                      Retorno_processa.Free;
                      if fechar then
                         func.fechar_sistema;
                   end;

end;

function TLockApplication.Gera_Chave_Data( ID_Instalacao, ID_Sistema: int64;
   data: String; Versao_Sistema: int64 ):String;
var
   RetornoHex, S, ver: String;
   I, V, DataNumeros: int64;
   Dias: Double;
begin
   try
   Dias := (StrToDate( Data ) - date);
   S := '9' + FloatToStr( Dias ) + '9';
   I := Func.FGerar_Chave( ID_Instalacao, ID_Sistema, date );
   V := StrToInt64( S );
   DataNumeros := Func.Processa_Data( formatDateTime( 'dd/mm/yy', date ) );
   ver := '9' + IntToStr( Versao_Sistema + ID_Sistema ) + '9';
   RetornoHex := IntToHex( V, 8 ) + '-' +IntToHex( I, 8 ) + '-' + IntToHex( DataNumeros, 8 ) +
   '-' + inttoHex( StrToInt64( ver ), 8 );
   Result := RetornoHex;
   except
      raise Exception.Create('Erro ao gerar a chave');
   end;
end;

function TLockApplication.Gera_Chave_Dias( ID_Instalacao, ID_Sistema,
   Dias, Versao_Sistema: int64 ):String;
var
   RetornoHex, S, ver: String;
   V, I, DataNumeros: int64;
begin
   try
   S := '9' + IntToStr( Dias ) + '9';
   I := Func.FGerar_Chave( ID_Instalacao, ID_Sistema, date );
   V := StrToInt64( S );
   DataNumeros := Func.Processa_Data( formatDateTime( 'dd/mm/yy', date ) );
   ver := '9' + IntToStr( Versao_Sistema + ID_Sistema ) + '9';
   RetornoHex := IntToHex( V, 8 ) + '-' + IntToHex( I, 8 )+ '-' + IntToHex( DataNumeros, 8 )+
   '-' + inttoHex( StrToInt64( ver ), 8 );
   Result := RetornoHex;
   except
      raise Exception.Create('Erro ao gerar a chave');
   end;
end;


/// ==============================Funções de variaveis   ==================


function TLockApplication.GetDias_restantes : int64;
begin
   Result := Variaveis.Dias_Restantes;
end;
function TLockApplication.GetData_vencimento: String;
begin
   Result := variaveis.Data_Vencimento;
end;
function TLockApplication.GetEmail_Cliente: String;
begin
   Result := variaveis.Email_Cliente;
end;
function TLockApplication.GetChave_registrada: String;
begin
   Result := Variaveis.CHAVE_Registrada;
end;
function TLockApplication.GetSistema_Demo: Boolean;
begin
   Result := Variaveis.SISTEMA_DEMO;
end;

function TLockApplication.GetTitulo_Janelas: String;
var
  S: String;
begin
   S := Variaveis.Titulo_Janelas;
   result := S;
end;
procedure TLockApplication.SetTitulo_Janelas( value: String );
begin
   if Value <> '' then
      Variaveis.Titulo_Janelas := value
   else
      raise Exception.Create('Valor null é inválido!');
end;

function TLockApplication.GetEmpresa_site: String;
var
  S: String;
begin
   S := Variaveis.Empresa_Site;
   result := S;
end;
procedure TLockApplication.SetEmpresa_site( value: String );
begin
   if value = '' then
      Variaveis.Empresa_Site := value
   else
   begin
       if pos( 'http://', value ) > 0 then
          Variaveis.Empresa_Site := value
       else
          raise Exception.Create('Site inválido!' + #13 + 'Site deve ter "http://"' );
   end;
end;

function TLockApplication.GetEmpresa_telefones: String;
var
  S: String;
begin
   S := Variaveis.Empresa_Telefones;
   result := S;
end;
procedure TLockApplication.SetEmpresa_telefones( value: String );
begin
   Variaveis.Empresa_Telefones := value;
end;


function TLockApplication.GetEmpresa_email: String;
var
  S: String;
begin
   S := Variaveis.Empresa_Email;
   result := S;
end;
procedure TLockApplication.SetEmpresa_email( value: String );
begin
   if value = '' then
      Variaveis.Empresa_Email := value
   else
   begin
       if pos( '@', value ) > 0 then
          Variaveis.Empresa_Email := value
       else
          raise Exception.Create('E-Mail inválido!');
   end;
end;


function TLockApplication.GetChave_Crypt: String;
var
  S: String;
begin
   S := Variaveis.Chave_Crypt;
   Result := S;
end;

procedure TLockApplication.SetChave_Crypt( value: String );
begin
   if Value <> '' then
      Variaveis.Chave_Crypt := value
   else
      raise Exception.Create('Chave_Criptografia não pode ser null');
end;

function TLockApplication.GetIDInstalacao: int64;
var
   Value: int64;
begin
   Value := Variaveis.ID_Instalacao;
   Result := Value;
end;

function TLockApplication.GetLocal_Registro: String;
begin
   result := Variaveis.Local_Registro;
end;
procedure TLockApplication.SetLocal_Registro( value: String );
begin
   if value = '' then
      raise Exception.Create('Local_Registro não pode ser null')
   else
      Variaveis.Local_Registro := value;
end;

function TLockApplication.GetTrial: Boolean;
begin
   result := Variaveis.Trial;
end;

procedure TLockApplication.SetTrial( value: Boolean );
begin
   Variaveis.Trial := value;
end;

function TLockApplication.GetMostrar_Tela: Boolean;
begin
   result := Variaveis.Mostrar_Tela;
end;

procedure TLockApplication.SetMostrar_Tela( value: Boolean );
begin
   Variaveis.Mostrar_Tela := value;
end;


function TLockApplication.GetDias_Trial: int64;
begin
   result := Variaveis.Dias_Trial;
end;
procedure TLockApplication.SetDias_Trial( value: int64 );
begin
   if value < 1 then
      begin
         raise Exception.Create('Dias_Trial deve ser maior que 0!');
      end
   else
      Variaveis.Dias_Trial := value;
end;

function TLockApplication.GetID_Sistema: int64;
begin
   result := Variaveis.ID_Sistema;
end;

procedure TLockApplication.SetID_Sistema( value: int64 );
begin
   if value < 1 then
      begin
         raise Exception.Create('IDSistema não pode ser menor que 1!');
      end
   else
      Variaveis.ID_Sistema := Value;
end;



//    VARIAVEIS DE EMAIL
{       VAut_SSL: Boolean;
       VServidor_SMTP: String;
       VUsuario_SMTP: String;
       VSenha_SMTP: String;
       VPorta_SMTP: integer;
       VEmail_Remetente: String;
       VEmail_destino: String;
       VEmail_assunto: String;
       VEmail_mensagen: TStrings;
       VDias_email: integer;
       VEnviar_Email: Boolean;}

function TLockApplication.GetVAut_SSL: Boolean;
begin
   Result := Variaveis.VAut_SSL;
end;
procedure TLockApplication.SetVAut_SSL( value: Boolean );
begin
   Variaveis.VAut_SSL := value;
end;

function TLockApplication.GetVEnviar_email: Boolean;
begin
   Result := Variaveis.VEnviar_Email;
end;
procedure TLockApplication.SetVEnviar_email( value: Boolean );
begin
   Variaveis.VEnviar_Email := value;
end;

function TLockApplication.GetVServidor_email: String;
begin
   result := Variaveis.VServidor_SMTP;
end;
procedure TLockApplication.SetVServidor_email( value: String );
begin
   Variaveis.VServidor_SMTP := value;
end;

function TLockApplication.GetVusuario_SMTP: String;
begin
   result := Variaveis.VUsuario_SMTP;
end;
procedure TLockApplication.SetVUsuario_SMTP( value: String );
begin
   Variaveis.VUsuario_SMTP := value;
end;

function TLockApplication.GetVSenha_SMTP: String;
begin
   result := Variaveis.VSenha_SMTP;
end;
procedure TLockApplication.SetVSenha_SMTP( value: String );
begin
   Variaveis.VSenha_SMTP := value;
end;

function TLockApplication.GetVEmail_remetente: String;
begin
   result := Variaveis.VEmail_Remetente;
end;
procedure TLockApplication.SetVEmail_remetente( value: String );
begin
   Variaveis.VEmail_Remetente := value;
end;

function TLockApplication.GetVPorta_SMTP: integer;
begin
   result := Variaveis.VPorta_SMTP;
end;
procedure TLockApplication.SetVPorta_SMTP( value: integer );
begin
   Variaveis.VPorta_SMTP := value;
end;

function TLockApplication.GetVEmail_destino: String;
begin
   result := Variaveis.VEmail_destino;
end;
procedure TLockApplication.SetVEmail_destino( value: String );
begin
   Variaveis.VEmail_destino := value;
end;

function TLockApplication.GetVEmail_assunto: String;
begin
   result := Variaveis.VEmail_assunto;
end;
procedure TLockApplication.SetVEmail_assunto( value: String );
begin
   Variaveis.VEmail_assunto := value;
end;

procedure TLockApplication.SetVEmail_mensagen( value: TStrings );
begin
   Variaveis.VEmail_mensagen.Clear;
   Variaveis.VEmail_mensagen.Assign( value );
   Mensagen.Clear;
   Mensagen.Assign( Value );
end;

function TLockApplication.GetVDias_email: integer;
begin
   result := Variaveis.VDias_email;
end;
procedure TLockApplication.SetVDias_email( value: integer );
begin
   Variaveis.VDias_email := value;
end;

procedure TLockApplication.ler_dados;
begin
    nomeclientev := func.Ler_Valor( 'NOMECLIENTE' );
    cpfclientev := func.Ler_Valor( 'CPF' );
    enderecov := func.Ler_Valor( 'ENDERECO' );
    cidadev := func.Ler_Valor( 'CIDADE' );
    telefonev := func.Ler_Valor( 'TELEFONE' );
    estadov := func.Ler_Valor( 'ESTADO' );
end;

procedure TLockApplication.Atualizar_Cadastro;
begin
   Cadastro := TCadastro.Create( nil );
   Cadastro.Nome.Text := nomeclientev;
   Cadastro.cpf.Text := cpfclientev;
   Cadastro.endereco.Text := enderecov;
   Cadastro.cidade.Text := cidadev;
   Cadastro.telefone.Text := telefonev;
   Cadastro.estado.Text := estadov;

   Cadastro.Showmodal;
   Func.Gravar_Valor( 'NOMECLIENTE', cadastro.Nome.Text );
   Func.Gravar_Valor( 'CPF', cadastro.cpf.Text );
   Func.Gravar_Valor( 'ENDERECO', cadastro.endereco.Text );
   Func.Gravar_Valor( 'CIDADE', cadastro.cidade.Text );
   Func.Gravar_Valor( 'ESTADO', cadastro.estado.Text );
   Func.Gravar_Valor( 'TELEFONE', cadastro.telefone.Text );
   cadastro.Free;
   ler_dados;
end;

end.
