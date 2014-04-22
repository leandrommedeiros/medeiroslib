unit LockApplication.Interfaces;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Buttons, lockApplication.Vars, ExtCtrls, StdCtrls, ShellApi,
  LockApplication.Func;

type
  TBloqueio = class(TForm)
    SpeedButton1: TSpeedButton;
    Image1: TImage;
    TituloPanel: TPanel;
    Titulo: TLabel;
    SpeedButton2: TSpeedButton;
    Bevel1: TBevel;
    Label1: TLabel;
    Label2: TLabel;
    Site: TLabel;
    Label4: TLabel;
    Email: TLabel;
    Label6: TLabel;
    Telefones: TLabel;
    Label3: TLabel;
    EID_Instalacao: TEdit;
    Label5: TLabel;
    Eemail: TEdit;
    Label7: TLabel;
    Echave: TEdit;
    Image2: TImage;
    Timer1: TTimer;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure SpeedButton1Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure SiteClick(Sender: TObject);
    procedure EmailClick(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    TELA_ContraChave: String;
    TELA_Email: String;

    Ativar: Boolean;
    Fechado_Sem_Registro: Boolean;
    Pode_Sair: Boolean;
  end;

var
  Bloqueio: TBloqueio;

implementation

{$R *.dfm}

procedure TBloqueio.FormActivate(Sender: TObject);
begin
  Timer1.Enabled := True;
end;

procedure TBloqueio.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if not Pode_Sair then Action := caNone;
end;

procedure TBloqueio.FormShow(Sender: TObject);
begin
   Pode_Sair           := False;
   Bloqueio.Caption    := variaveis.Titulo_Janelas;
   Site.Caption        := Variaveis.Empresa_Site;
   Email.Caption       := Variaveis.Empresa_Email;
   Telefones.Caption   := Variaveis.Empresa_Telefones;
   EID_instalacao.Text := IntToStr(Variaveis.ID_Instalacao);

   if TELA_Email = '' then Eemail.Text := 'diretoria@tecnoliq.com.br'
   else                    Eemail.Text := TELA_Email;

   if TELA_ContraChave <> '' then Echave.Text := TELA_Contrachave
   else                           Echave.Clear;

   if Ativar then Titulo.Caption := 'Digite a chave pra renovar o sistema!' +#13
                                  + 'Obtenha a chave com o administrador do sistema.'
   else           Titulo.Caption := 'Sistema não está liberado para uso neste computador!' +#13
                                  + 'Entre em contato com o administrador do sistema.';
end;

procedure TBloqueio.SiteClick(Sender: TObject);
begin
   ShellExecute(handle, 'open', pchar(Variaveis.Empresa_Site), '', '', SW_SHOWNORMAL);
end;

procedure TBloqueio.EmailClick(Sender: TObject);
begin
   ShellExecute(handle, 'open', pchar('mailto:' + Variaveis.Empresa_Email), '','',SW_SHOWNORMAL);
end;

procedure TBloqueio.SpeedButton1Click(Sender: TObject);
begin
  Pode_sair := True;
  if Ativar then
  begin
    Fechado_sem_registro := True;
    Close;
  end
  else begin
    Fechado_sem_registro := True;
    Close;
  end;
end;

procedure TBloqueio.SpeedButton2Click(Sender: TObject);
begin
  if Echave.Text <> '' then
  begin
    if pos('@', Eemail.Text) > 0 then
    begin
      if Echave.Text = 'DEMONSTRAÇÃO' then
      begin
        if Variaveis.Ja_Foi_Trial then MessageDlg('Sistema já foi registrado como demonstraçao antes!', mtWarning, [mbOK], 0)
        else begin
          Fechado_sem_registro := False;
          Pode_Sair            := True;
          TELA_ContraChave     := echave.Text;
          TELA_Email           := Eemail.Text;
          Bloqueio.close;
        end;
      end
      else begin // ELSE do DEMOSTRAÇÃO
        Fechado_sem_registro := False;
        Pode_Sair            := True;
        TELA_ContraChave     := echave.Text;
        TELA_Email           := Eemail.Text;
        Bloqueio.close;
      end;
    end
    else MessageDlg('E-mail informado é inválido!', mtWarning, [mbOK], 0); // ELSE EMAIL
  end
  else MessageDlg('Chave não informada!', mtWarning, [mbOK], 0);           // ELSE DO CAMPO VAZIO
end;

procedure TBloqueio.Timer1Timer(Sender: TObject);
begin
  Timer1.Enabled := False;
  if Echave.Text = 'DEMONSTRAÇÃO' then SpeedButton2Click(SpeedButton2);
end;

end.
