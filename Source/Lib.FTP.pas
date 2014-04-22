{===============================================================================

                                BIBLIOTECA FTP

==========================================================| Versão 12.12.00 |==}

unit Lib.FTP;

interface

{ Bibliotecas para Interface }
uses IdFTP, Classes;

{ Constantes }
const
  FTP_DIR_SEPARATOR = '/';

{ Protótipos - Procedimentos e Funções }
  function NewFTPConnection(var FTP: TIdFTP; const sHost, sUser,
    sPasswd: string): Boolean;
  function FTPParentFolder(ADir: string; ARepeat: integer = 1): string;
  function FTPDirExists(AFTPCon: TIdFTP; const ADir: string): Boolean;
  function FTPForceDirectory(var AFTPCon: TIdFTP; const ANewDir: string): Boolean;
  function FTPUpload(var AFTPCon: TIdFTP; const ASourceDir, ATargetDir,
    AFile: string; const Append: Boolean = false; const
    ADelAfterUpload: Boolean = false): Boolean; overload;
  function FTPUpload(var FTPCon: TIdFTP; FMemoryStream: TMemoryStream;
    const ADestDir, AFile: string): Boolean; overload;
  function FTPDeleteFiles(var FTPCon: TIdFTP; const ATargetDir: string;
    slFiles: TStringList): Boolean;
  function FTPFilterFiles(var FTPCon: TIdFTP; const ARootDir, AFilter: string;
    var AFileList: TStringList): Boolean;

{ Classes }
type
  TFTPConnection = class(TIdFTP)
  public
    constructor Create(const AHost, AUser, APassword: string;
      out ASuccess: Boolean); overload;
    constructor Create(const AHost, AUser, APassword: string); overload;
    function ValidateConnectionParams: Boolean;
    function GetDirUp(ADir: string; ARepeat: integer = 1): string;
    function DirExists(const ADir: string): Boolean;
    function ForceDirectory(const ANewDir: string): Boolean;
    function Upload(const ASourceDir, ATargetDir, AFile: string;
      const Append: Boolean = false;
      const ADelAfterUpload: Boolean = false): Boolean; overload;
    function Upload(AMemoryStream: TMemoryStream; const ATargetDir,
      AFile: string; const Append: Boolean): Boolean; overload;
    function Download(ASourceDir, ATargetDir, AFile: string;
      Append: Boolean = false): Boolean; overload;
    function Download(const ASourceDir, AFile: string; var AMemoryStream: TMemoryStream;
      Append: Boolean = false): Boolean; overload;
    function DeleteFiles(const ATargetDir: string; slFiles: TStringList): Boolean;
    function FilterFiles(const ARootDir, AFilter: string;
      var AFileList: TStringList): Boolean;
  end;

implementation

{ Bibliotecas para Implementação }
uses
  SysUtils, IdFTPCommon, Lib.Files, Windows;

{==| Função - Nova Conexão FTP |================================================
    Instancia um componente IdFTP dinâmicamente e tenta conectar segundo os
  parâmetros de conexão recebidos.
  Parâmetros de Entrada:
    1. Variável para instanciar o componente > Classe TIdFTP
    2. Host FTP > String
    3. Usuário  > String
    4. Senha    > String
  Retorno: Sucesso na conexão (Booleano).
============================================| Leandro Medeiros (28/11/2012) |==}
function NewFTPConnection(var FTP: TIdFTP; const sHost, sUser,
  sPasswd: string): Boolean;
begin
  try
    if not Assigned(FTP) then FTP := TIdFTP.Create(nil);

    FTP.Host         := sHost;
    FTP.Username     := sUser;
    FTP.Password     := sPasswd;
    FTP.Passive      := True;
    FTP.TransferType := ftBinary;

    FTP.Connect;
    Result := FTP.Connected;
  except
    Result := False;
  end;
end;

{==| Procedimento - Pasta Anterior |============================================
    Recebe por parâmetro uma variável (string) de um diretório e apaga o nome
  da última pasta que está nela. Repete o procedimento de acordo com o parâmetro
  iRepeat.
============================================| Leandro Medeiros (20/10/2011) |==}
function FTPParentFolder(ADir: string; ARepeat: integer = 1): string;
var
  idx: integer;
begin
  idx  := (Length(ADir) - 1);                                                   //O índice é a equivalente à largura da string menos 1

  while (idx > 0) and (ARepeat > 0) do                                          //enquanto os índices não atingirem zero
  begin
    if ADir[idx] = FTP_DIR_SEPARATOR then                                       //verifico se o caracter correspondente na string é "/"
    begin
      ADir := Copy(ADir, 1, idx);                                               //caso seja, sobreponho a string somente com o tamanho que ela tem até o atual indice
      Inc(ARepeat, - 1);                                                        //e decremento a repetição
    end;

    Inc(idx, - 1)                                                               //Se chegar aqui devo decrementar o índice
  end;

  Result := ADir;
end;

function FTPDirExists(AFTPCon: TIdFTP; const ADir: string): Boolean;
begin
  try
    AFTPCon.ChangeDir(ADir);
    Result := True;
  except
    Result := False;
  end;
end;

//==| Função - Força Diretório |================================================
function FTPForceDirectory(var AFTPCon: TIdFTP; const ANewDir: string): Boolean;
var
  sAux : string;
begin
  if FTPDirExists(AFTPCon, ANewDir) then
  begin
    Result := True;
    Exit;
  end;

  Result := False;
  sAux   := ANewDir;

  while sAux <> FTP_DIR_SEPARATOR do                                            //Enquanto não chegar ao root
  begin
    try
      if not FTPDirExists(AFTPCon, sAux) then
      begin
        AFTPCon.MakeDir(sAux);

        if sAux = ANewDir then
        begin
          Result := True;
          Break;
        end;
      end;

      sAux := ANewDir;
    except
      sAux := FTPParentFolder(sAux);
    end;
  end;
end;

{==| Função - Upload via FTP |==================================================
    Copia um arquivo para uma host FTP através de uma conexão já estabelecida.
  Parâmetros de Entrada:
    1. Conexão com FTP             > TIdFTP
    2. Diretório de Origem         > String
    3. Diretório de Destino        > String
    4. Arquivo à ser copiado       > String
    5. Excluir arquivo após upload > Booleano (Padrão Falso)
  Retorno: Sucesso no upload (Booleano).
============================================| Leandro Medeiros (29/11/2012) |==}
function FTPUpload(var AFTPCon: TIdFTP; const ASourceDir, ATargetDir,
  AFile: string; const Append: Boolean = false; const
  ADelAfterUpload: Boolean = false): Boolean; overload;
var
  iFileSize,
  iSentSize : integer;
begin
  Result := False;

  if not FileExists(ASourceDir + AFile) then Exit;

  if not AFTPCon.Connected then
    if (AFTPCon.Host = EmptyStr) or
       (AFTPCon.Username = EmptyStr) or
       (AFTPCon.Password = EmptyStr) then Exit

    else begin
      try
        AFTPCon.Connect;
        if not AFTPCon.Connected then Exit;
      except
        on e: Exception do
        begin
          Lib.Files.FileLog('Falha de conexão FTP, Mensagem: ' + e.Message);
          Exit;
        end;
      end;
    end;

  try
    iFileSize := Lib.Files.GetFileSizeB(ASourceDir + AFile);

    if not Lib.FTP.FTPForceDirectory(AFTPCon, ATargetDir) then
      Lib.Files.FileLog('Falha ao gerar diretório de destino: ' + ATargetDir)

    else begin
      AFTPCon.ChangeDir(ATargetDir);
      AFTPCon.Put(ASourceDir + AFile, AFile, Append);
      iSentSize := AFTPCon.Size(AFile);

      Result := iFileSize = iSentSize;

      if Result and ADelAfterUpload then Lib.Files.ForceDelete(ASourceDir + AFile);
    end;
  finally
    AFTPCon.Disconnect;
  end;
end;

{==| Função - Upload via FTP (Overload) |=======================================
    Salva um arquivo em memória em um host FTP através de uma conexão já
  estabelecida.
  Parâmetros de Entrada:
    1. Conexão com FTP      > TIdFTP.
    2. Stream de origem     > TMemoryStream.
    3. Diretório de Destino > String.
    4. Arquivo à ser criado > String.
  Retorno: Sucesso no upload (Booleano).
============================================| Leandro Medeiros (29/11/2012) |==}
function FTPUpload(var FTPCon: TIdFTP; FMemoryStream: TMemoryStream; const ADestDir,
  AFile: string): Boolean; overload;
begin
  Result := False;

  if not FTPCon.Connected then
    if (FTPCon.Host = EmptyStr) or
       (FTPCon.Username = EmptyStr) or
       (FTPCon.Password = EmptyStr) then Exit

    else begin
      try
        FTPCon.Connect;
        if not FTPCon.Connected then Exit;
      except
        Exit;
      end;
    end;

  try
    Lib.FTP.FTPForceDirectory(FTPCon, ADestDir);
    FTPCon.ChangeDir(ADestDir);
    FTPCon.Put(FMemoryStream, AFile);
    Result := True;
  except
  end;
end;

{==| Função - Remoção de arquivos FTP |=========================================
    Excluí arquivos em um diretório FTP através de uma conexão já estabelecida.
  Parâmetros de Entrada:
    1. Conexão com FTP                               > TIdFTP
    2. Diretório de onde os arquivos serão excluídos > String
    3. Lista de arquivos a serem excluídos           > TStringList
  Retorno: Sucesso na exclusão (Booleano).
============================================| Leandro Medeiros (03/12/2012) |==}
function FTPDeleteFiles(var FTPCon: TIdFTP; const ATargetDir: string;
  slFiles: TStringList): Boolean;
var
  idx : integer;
begin
  Result := False;

  if not FTPCon.Connected then
    if (FTPCon.Host = EmptyStr) or
       (FTPCon.Username = EmptyStr) or
       (FTPCon.Password = EmptyStr) then Exit

    else begin
      try
        FTPCon.Connect;
        if not FTPCon.Connected then Exit;
      except
        Exit;
      end;
    end;

  try
    FTPCon.ChangeDir(ATargetDir);
    for idx := 0 to (slFiles.Count - 1) do FTPCon.Delete(slFiles[idx]);
    Result := True;
  except
  end;
end;

{==| Função - Listagem via FTP |================================================
    Filtra arquivos em um diretório FTP através de uma conexão já estabelecida.
  Parâmetros de Entrada:
    1. Conexão com FTP             > TIdFTP
    2. Diretório Raíz da Busca     > String
    3. Condição de filtragem       > String
    4. Lista de arquivos filtrados > TStringList
  Retorno: Sucesso na listagem (Booleano).
============================================| Leandro Medeiros (03/12/2012) |==}
function FTPFilterFiles(var FTPCon: TIdFTP; const ARootDir, AFilter: string;
  var AFileList: TStringList): Boolean;
begin
  Result := False;

  if not FTPCon.Connected then
    if (FTPCon.Host = EmptyStr) or
       (FTPCon.Username = EmptyStr) or
       (FTPCon.Password = EmptyStr) then Exit

    else begin
      try
        FTPCon.Connect;
        if not FTPCon.Connected then Exit;
      except
        Exit;
      end;
    end;

  try
    FTPCon.ChangeDir(ARootDir);
    FTPCon.List(AFileList, AFilter, False);
    Result := AFileList.Count > 0;
  except
  end;
end;
//==============================================================================

{ TFTPConnection }


{==| Construtor FTP |===========================================================
    Instancia um componente IdFTP dinâmicamente e tenta conectar segundo os
  parâmetros de conexão recebidos.
  Parâmetros de Entrada:
    1. Host FTP > String
    2. Usuário  > String
    3. Senha    > String
    4. Sucesso  > Booleano (Variável externa).
============================================| Leandro Medeiros (26/11/2013) |==}
constructor TFTPConnection.Create(const AHost, AUser, APassword: string;
  out ASuccess: Boolean);
begin
  try
    inherited Create(nil);

    Self.Host         := AHost;
    Self.Username     := AUser;
    Self.Password     := APassword;
    Self.Passive      := True;
    Self.TransferType := ftBinary;

    Self.Connect;
    ASuccess := Self.Connected;
  except
    ASuccess := False;
  end;
end;

{==| Construtor FTP |===========================================================
    Instancia um componente IdFTP dinâmicamente e tenta conectar segundo os
  parâmetros de conexão recebidos.
  Parâmetros de Entrada:
    1. Host FTP > String
    2. Usuário  > String
    3. Senha    > String
============================================| Leandro Medeiros (26/11/2013) |==}
constructor TFTPConnection.Create(const AHost, AUser, APassword: string);
var
  bResult : Boolean;
begin
  Self.Create(AHost, AUser, APassword, bResult);
end;

{==| Função - Remoção de arquivos FTP |=========================================
    Excluí arquivos em um diretório FTP através de uma conexão já estabelecida.
  Parâmetros de Entrada:
    1. Diretório de onde os arquivos serão excluídos > String
    2. Lista de arquivos a serem excluídos           > TStringList
  Retorno: Sucesso na exclusão (Booleano).
============================================| Leandro Medeiros (03/12/2012) |==}
function TFTPConnection.DeleteFiles(const ATargetDir: string;
  slFiles: TStringList): Boolean;
var
  idx : integer;
begin
  Result := False;

  if Self.ValidateConnectionParams then
    try
      Self.ChangeDir(ATargetDir);
      for idx := 0 to (slFiles.Count - 1) do Self.Delete(slFiles[idx]);
      Result := True;
    except
    end;
end;

{==| Função - Validação de Diretório |==========================================
    Excluí arquivos em um diretório FTP através de uma conexão já estabelecida.
  Parâmetros de Entrada:
    1. Diretório a ser verificado > string
  Retorno: Diretório válido (Booleano).
============================================| Leandro Medeiros (03/12/2012) |==}
function TFTPConnection.DirExists(const ADir: string): Boolean;
var
  sCurrentDir : string;
begin
  try
    sCurrentDir := Self.RetrieveCurrentDir;
    Self.ChangeDir(ADir);
    Result := True;
    Self.ChangeDir(sCurrentDir);
  except
    Result := False;
  end;
end;

{==| Função - Listagem via FTP |================================================
    Filtra arquivos em um diretório FTP através de uma conexão já estabelecida.
  Parâmetros de Entrada:
    1. Diretório Raíz da Busca     > String
    2. Condição de filtragem       > String
    3. Lista de arquivos filtrados > TStringList
  Retorno: Sucesso na listagem (Booleano).
============================================| Leandro Medeiros (03/12/2012) |==}
function TFTPConnection.FilterFiles(const ARootDir, AFilter: string;
  var AFileList: TStringList): Boolean;
begin
  Result := False;

  if Self.ValidateConnectionParams then
    try
      Self.ChangeDir(ARootDir);
      Self.List(AFileList, AFilter, False);
      Result := AFileList.Count > 0;
    except
      Lib.Files.FileLog('Falha ao listar arquivos do diretório "' + ARootDir + '"');
    end;
end;

{==| Função - Forçar Diretório |================================================
    Filtra arquivos em um diretório FTP através de uma conexão já estabelecida.
  Parâmetros de Entrada:
    1. Diretório a ser criado > String
  Retorno: Sucesso na criação (Booleano).
============================================| Leandro Medeiros (03/12/2012) |==}
function TFTPConnection.ForceDirectory(const ANewDir: string): Boolean;
var
  sAux : string;
begin
  if Self.DirExists(ANewDir) then
  begin
    Result := True;
    Exit;
  end;

  Result := False;
  sAux   := ANewDir;

  while sAux <> FTP_DIR_SEPARATOR do                                            //Enquanto não chegar ao root
  begin
    try
      if not Self.DirExists(sAux) then
      begin
        Self.MakeDir(sAux);

        if sAux = ANewDir then
        begin
          Result := True;
          Break;
        end;
      end;

      sAux := ANewDir;
    except
      sAux := Self.GetDirUp(sAux);
    end;
  end;
end;

{==| Procedimento - Pasta Anterior |============================================
    Recebe por parâmetro uma variável (string) de um diretório e apaga o nome
  da última pasta que está nela. Repete o procedimento de acordo com o parâmetro
  iRepeat.
============================================| Leandro Medeiros (26/11/2013) |==}
function TFTPConnection.GetDirUp(ADir: string; ARepeat: integer): string;
var
  idx: integer;
begin
  idx  := (Length(ADir) - 1);                                                   //O índice é a equivalente à largura da string menos 1

  while (idx > 0) and (ARepeat > 0) do                                          //enquanto os índices não atingirem zero
  begin
    if ADir[idx] = FTP_DIR_SEPARATOR then                                       //verifico se o caracter correspondente na string é "/"
    begin
      ADir := Copy(ADir, 1, idx);                                               //caso seja, sobreponho a string somente com o tamanho que ela tem até o atual indice
      Inc(ARepeat, - 1);                                                        //e decremento a repetição
    end;

    Inc(idx, - 1)                                                               //Se chegar aqui devo decrementar o índice
  end;

  Result := ADir;
end;

{==| Função - Upload via FTP |==================================================
    Copia um arquivo para uma host FTP através de uma conexão já estabelecida.
  Parâmetros de Entrada:
    1. Diretório de Origem         > String
    2. Diretório de Destino        > String
    3. Arquivo à ser copiado       > String
    4. Excluir arquivo após upload > Booleano (Padrão Falso)
  Retorno: Sucesso no upload (Booleano).
============================================| Leandro Medeiros (29/11/2012) |==}
function TFTPConnection.Upload(const ASourceDir, ATargetDir, AFile: string;
  const Append, ADelAfterUpload: Boolean): Boolean;
var
  iFileSize,
  iSentSize : integer;
begin
  Result := False;

  if not FileExists(ASourceDir + AFile) then Exit;

  if Self.ValidateConnectionParams then
    try
      iFileSize := Lib.Files.GetFileSizeB(ASourceDir + AFile);

      if not Self.ForceDirectory(ATargetDir) then
        Lib.Files.FileLog('Falha ao gerar diretório de destino: ' + ATargetDir)

      else begin
        Self.ChangeDir(ATargetDir);
        Self.Put(ASourceDir + AFile, AFile, Append);
        iSentSize := Self.Size(AFile);

        Result := iFileSize = iSentSize;

        if Result and ADelAfterUpload then
          Lib.Files.ForceDelete(ASourceDir + AFile);
      end;
    finally
      Self.Disconnect;
    end;
end;

{==| Função - Upload via FTP (Overload) |=======================================
    Salva um arquivo em memória em um host FTP através de uma conexão já
  estabelecida.
  Parâmetros de Entrada:
    1. Stream de origem     > TMemoryStream.
    2. Diretório de Destino > String.
    3. Arquivo à ser criado > String.
  Retorno: Sucesso no upload (Booleano).
============================================| Leandro Medeiros (29/11/2012) |==}
function TFTPConnection.Upload(AMemoryStream: TMemoryStream; const ATargetDir,
  AFile: string; const Append: Boolean): Boolean;
var
  iFileSize,
  iSentSize : integer;
begin
  Result := False;

  if Self.ValidateConnectionParams then
    try
      iFileSize := AMemoryStream.Size;

      if not Self.ForceDirectory(ATargetDir) then
        Lib.Files.FileLog('Falha ao gerar diretório de destino: ' + ATargetDir)

      else begin
        Self.ChangeDir(ATargetDir);
        Self.Put(AMemoryStream, AFile, Append);
        iSentSize := Self.Size(AFile);

        Result := iFileSize = iSentSize;
      end;
    finally
      Self.Disconnect;
    end;
end;

{==| Função - Download via FTP |================================================
    Copia um arquivo de um host FTP através de uma conexão já estabelecida.
  Parâmetros de Entrada:
    1. Diretório de Origem (FTP) > String;
    2. Diretório de Destino (PC) > String;
    3. Arquivo à ser copiado     > String;
    4. Resumir Download          > Booleano;
  Retorno: Sucesso no download (Booleano).
============================================| Leandro Medeiros (12/04/2014) |==}
function TFTPConnection.Download(ASourceDir, ATargetDir,
  AFile: string; Append: Boolean = false): Boolean;
var
  iFileSize,
  iGotSize : integer;
begin
  Result := False;

  if Bool(Self.Size(ASourceDir + AFile)) and
    Self.ValidateConnectionParams then
  begin
    try
      Self.ChangeDir(ASourceDir);
      iFileSize := Self.Size(AFile);

      if not Lib.Files.ValidateDir(ATargetDir) then
        Lib.Files.FileLog('Falha ao gerar diretório de destino: ' + ATargetDir)

      else begin
        Self.Get(AFile, ATargetDir + AFile, True, Append);

        iGotSize := Lib.Files.GetFileSizeB(ATargetDir + AFile);
        Result   := iFileSize = iGotSize;
      end;
    finally
      Self.Disconnect;
    end;
  end;
end;

{==| Função - Download via FTP |================================================
    Copia um arquivo de um host FTP através de uma conexão já estabelecida.
  Parâmetros de Entrada:
    1. Diretório de Origem (FTP) > String;
    2. Arquivo à ser copiado     > String;
    3. Stream de destino         > TMemoryStream;
    4. Resumir Download          > Booleano;
  Retorno: Sucesso no download (Booleano).
============================================| Leandro Medeiros (12/04/2014) |==}
function TFTPConnection.Download(const ASourceDir, AFile: string;
  var AMemoryStream: TMemoryStream; Append: Boolean = false): Boolean;
var
  iFileSize : integer;
begin
  Result := False;

  if Bool(Self.Size(ASourceDir + AFile)) and
    Self.ValidateConnectionParams then
  begin
    try
      Self.ChangeDir(ASourceDir);
      iFileSize := Self.Size(AFile);

      Self.Get(AFile, AMemoryStream, Append);

      Result := (iFileSize = AMemoryStream.Size);
    finally
      Self.Disconnect;
    end;
  end;
end;

{==| Função - Validar Parâmetros de Conexão |===================================
    Salva um arquivo em memória em um host FTP através de uma conexão já
  estabelecida.
  Retorno: Parâmetros válidos (Booleano).
============================================| Leandro Medeiros (29/11/2012) |==}
function TFTPConnection.ValidateConnectionParams: Boolean;
begin
  if Self.Connected then
    Result := True

  else if (Self.Host = EmptyStr) or
          (Self.Username = EmptyStr) or
          (Self.Password = EmptyStr) then
    Result := False

  else begin
    try
      Self.Connect;
      Result := Self.Connected;
    except
      on e: Exception do
      begin
        Lib.Files.FileLog('Falha de conexão FTP, Mensagem: ' + e.Message);
        Result := False;
      end;
    end;
  end;
end;
//==============================================================================

end.
