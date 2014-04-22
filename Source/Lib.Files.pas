{===============================================================================

                   BIBLIOTECA - ARQUIVOS E DIRETÓRIOS (Para XE3)

==========================================================| Versão 12.11.00 |==}

unit Lib.Files;

interface

{ Bibliotecas para Interface }
uses
  Classes, SysUtils, Forms;

{$IFDEF VER150}
{ Classes }
type
  TBytes = array of byte;
{$ENDIF}

{ Protótipos }
  function  BytesToMB(iBytes: integer): Real;
  procedure PriorFolder(var sDir: string; iRepeat: integer = 1);
  function  ParentFolder(sDir: string; iRepeat: integer = 1): string;
  function  ValidateDir(var ADir: string; ACreate: Boolean = True): Boolean;
  procedure ValidateFileName(var sArquivo: string);
  function  ClearDirectory(const ADir: string; const AFilter: string = '*.*'): Boolean;
  procedure GetFolderList(ARootPath: String; var AResult: TStringList;
    const ASub: Boolean = True); overload;
  function  GetFolderList(ARootPath: String; const ASub: Boolean = True): TStringList; overload;
  procedure GetFileList(ADirectory: string; var AResult: TStringList;
    AFilter: string = '*.*'; ASub: Boolean = True); overload;
  function GetFileList(ADirectory: string; const AFilter: string = '*.*';
    const ASub: Boolean = True): TStringList; overload;
  function  GetFileSize(sFileName: string; rMB: Boolean = True): Real;
  function  GetFileSizeB(sFileName: string): Integer;
  function  GetNextFileName(const AFullFileName: string): string; overload;
  procedure GetNextFileName(const ADir: string; var AFileName: string); overload;
  function  GetLargestFile(sFileList: TStringList): string;
  function  StrToFileStream(Str: String): TFileStream;
  procedure FileLog(const AText: string; const ANameByDate: Boolean = True);
  function  WorkingDir: string;
  function  CreatePublicFile(const AFileName: string): Boolean; overload;
  function  CreatePublicFile(const AFileName: string; var AStream: TFileStream): Boolean; overload;
  function  ForceDelete(const AFileName: string): Boolean;
  function  LoadFile(const AFileName: String; ARequiredSizeMod: Integer = 1): TBytes;

implementation

{ Bibliotecas para Implementação }
uses
  Windows;

{==| Função - Bytes Para MegaBytes |============================================
    Converte Bytes em MegaBytes.
  Parâmetros de entrada:
    1. Quantidade de Bytes > Integer

  Retorno: Correspondente em MegaBytes (Real)
============================================| Leandro Medeiros (20/10/2011) |==}
function BytesToMB(iBytes: integer): Real;
begin
  Result := iBytes / 1048576;
end;

{==| Procedimento - Pasta Anterior |============================================
    Recebe por parâmetro uma variável (string) de um diretório e apaga o nome
  da última pasta que está nela. Repete o procedimento de acordo com o parâmetro
  iRepeat.
============================================| Leandro Medeiros (20/10/2011) |==}
procedure PriorFolder(var sDir: string; iRepeat: integer = 1);
var
  idx: integer;
begin
  idx := (Length(sDir) - 1);                                                    //O índice é a equivalente à largura da string menos 1

  while (idx > 0) and (iRepeat > 0) do                                          //enquanto os índices não atingirem zero
  begin
    if sDir[idx] = '\' then                                                     //verifico se o caracter correspondente na string é "\"
    begin
      sDir := Copy(sDir, 1, idx);                                               //caso seja, sobreponho a string somente com o tamanho que ela tem até o atual indice
      Inc(iRepeat, - 1);                                                        //e decremento a repetição
    end;
    Inc(idx, - 1)                                                               //Se chegar aqui devo decrementar o índice
  end;
end;

{==| Procedimento - Pasta Anterior |============================================
    Recebe por parâmetro uma variável (string) de um diretório e apaga o nome
  da última pasta que está nela. Repete o procedimento de acordo com o parâmetro
  iRepeat.
============================================| Leandro Medeiros (20/10/2011) |==}
function ParentFolder(sDir: string; iRepeat: integer = 1): string;
var
  idx: integer;
begin
  sDir := ExtractFilePath(sDir);
  idx  := (Length(sDir) - 1);                                                   //O índice é a equivalente à largura da string menos 1

  while (idx > 0) and (iRepeat > 0) do                                          //enquanto os índices não atingirem zero
  begin
    if (sDir[idx] = '\') or (sDir[idx] = '/') then                              //verifico se o caracter correspondente na string é "\"
    begin
      sDir := Copy(sDir, 1, idx);                                               //caso seja, sobreponho a string somente com o tamanho que ela tem até o atual indice
      Inc(iRepeat, - 1);                                                        //e decremento a repetição
    end;
    Inc(idx, - 1)                                                               //Se chegar aqui devo decrementar o índice
  end;

  ValidateDir(sDir);
  Result := sDir;
end;

{==| Função - Valida Diretorio |================================================
    Recebe como primeiro parâmetro uma string contendo um diretório, verifica se
  o último caractere é "\" e, se não for, o concatena à string. Se o segundo
  parâmetro de entrada (booleano) for verdadeiro verifica se é um diretório
  existente e caso não seja tenta o criar (Retorna Verdadeiro se conseguir).
===============================================================================}
function ValidateDir(var ADir: string; ACreate: Boolean = True): Boolean;
begin
  Result := True;

  if Trim(ADir[Length(ADir)]) <> '\' then                                       //Se o último caracter da string não for uma barra
    ADir := Trim(ADir) + '\';                                                   //vou acrescentá-la
  if ACreate and not DirectoryExists(ADir) then                                 //Se o diretório não existir eu o crio
    try
      CreateDir(ADir);
    except
      Result := False;
    end;
end;

//==| Procedimento - Valida Nome de Arquivo |===================================
procedure ValidateFileName(var sArquivo: string);
var
  idx : integer;
begin
  sArquivo := Trim(sArquivo);
  idx      := 1;
  while idx <= Length(sArquivo) do                                              //Monto um loop do primeiro ao último caracter da string de entrada
  begin
    if Pos(sArquivo[idx], '\/:*?"<>|') <> 0 then                                //caso o caracter correspondente ao índice do loop seja um dos caracteres inválidos
      Delete(sArquivo, idx, 1)                                                  //excluo ele da string
    else Inc(idx);                                                              //caso contrário incremento o contador
  end;
end;

//==| Função - Remover Diretório |==============================================
function ClearDirectory(const ADir: string; const AFilter: string = '*.*'): Boolean;
var
  slFiles: TStringList;
  idx: integer;
begin
  Result := True;

  try
    slFiles := GetFileList(ADir, AFilter);

    for idx := 0 to slFiles.Count - 1 do SysUtils.DeleteFile(slFiles[idx]);
  except
    on E: Exception do
    begin
      FileLog('Erro ao excluir arquivo "' + slFiles[idx] + '". Mensagem: ' + E.Message);
      Result := False;
    end;
  end;
end;

{==| Procedimento - Obter Lista de SubDiretórios |==============================
  Responsável por listar todos as subpastas de determinado diretório.
  Parâmetros de entrada:
    1. Diretório inicial                       > String
    2. Variável que receberá a Lista subpastas > TStringList
    3. Listar ou não SubPastas                 > Boolean (Padrão = Verdadeiro)
============================================| Leandro Medeiros (20/10/2011) |==}
procedure GetFolderList(ARootPath: String; var AResult: TStringList;
  const ASub: Boolean = True);
var
  SR     : TSearchRec;
  iError : Integer;
begin
  Lib.Files.ValidateDir(ARootPath);                                             //Valido o diretório

  try
    iError := FindFirst(ARootPath + '*.*', faAnyFile, Sr);                      //Busco o primeiro arquivo no diretório que atenda ao filtro

    while not Bool(iError) do                                                   //Enquanto a busca encontrar arquivos
    begin
      if ((SR.Attr and faDirectory) = faDirectory) and
         (SR.Name <> '.') and (SR.Name <> '..') then
      begin
        AResult.Add(ARootPath + SR.Name);                                       //Adiciono o nome da pasta à lista de resultado

        if ASub then                                                            //cSe foi solicitado verificação de subpastas
          GetFileList(ARootPath + SR.Name, AResult, ARootPath);                 //re-executo a função de modo recursivo
      end;

      iError := FindNext(SR);                                                   //por fim procuro pelo próximo arquivo
    end;
  finally
    SysUtils.FindClose(SR);                                                     //Após a tentativa, bem sucedida ou não, finalizo a busca
  end;
end;

{==| Função - Obter Lista de SubDiretórios |====================================
  Responsável por listar todos as subpastas de determinado diretório.
  Parâmetros de entrada:
    1. Diretório inicial                       > String;
    2. Listar ou não SubPastas                 > Boolean (Padrão = Verdadeiro);
  Retorno: Lista subpastas (TStringList).
============================================| Leandro Medeiros (20/10/2011) |==}
function GetFolderList(ARootPath: String; const ASub: Boolean = True): TStringList; overload;
begin
  Result := TStringList.Create;
  Lib.Files.GetFolderList(ARootPath, Result, ASub);
end;

{==| Procedimento - Obter Lista de Arquivos |===================================
  Filtra arquivos em determinado diretório e gera uma lista.
  Parâmetros de entrada:
    1. Diretório inicial                      > String
    2. Variável que receberá a Lista arquivos > TStringList
    3. Filtro a ser aplicado no diretório     > String  (Padrão = "*.*")
    4. Listar ou não SubSubPastas             > Boolean (Padrão = Verdadeiro)
============================================| Leandro Medeiros (20/10/2011) |==}
procedure GetFileList(ADirectory: string; var AResult: TStringList;
  AFilter: string = '*.*'; ASub: Boolean = True); overload;
var
  SR     : TSearchRec;
  iError : Integer;
begin
  Lib.Files.ValidateDir(ADirectory);                                            //Valido o diretório

  try
    iError := FindFirst(ADirectory + AFilter, faAnyFile, Sr);                   //Busco o primeiro arquivo no diretório que atenda ao filtro

    while not Bool(iError) do                                                   //Enquanto a busca encontrar arquivos
    begin
      if (SR.Attr and faDirectory) <> faDirectory then                                            //caso o arquivo não seja um diretório
        AResult.Add(ADirectory + SR.Name)                                       //Adiciono o nome do arquivo à lista de resultado

      else if ASub and (SR.Name <> '.') and (SR.Name <> '..') then              //caso contrário, se foi solicitado verificação de subpastas, e o arquivo encontrado não for o próprio diretório ou o diretório pai
        GetFileList(ADirectory + SR.Name, AResult, AFilter);                    //re-executo a função de modo recursivo

      iError := FindNext(SR);                                                   //por fim procuro pelo próximo arquivo
    end;
  finally
    SysUtils.FindClose(SR);                                                     //Após a tentativa, bem sucedida ou não, finalizo a busca
  end;
end;

{==| Função - Obter Lista de Arquivos |=========================================
  Filtra arquivos em determinado diretório e gera uma lista.
  Parâmetros de entrada:
    1. Diretório inicial                      > String
    2. Filtro a ser aplicado no diretório     > String  (Padrão = "*.*")
    3. Listar ou não SubSubPastas             > Boolean (Padrão = Verdadeiro)
============================================| Leandro Medeiros (20/10/2011) |==}
function GetFileList(ADirectory: string; const AFilter: string = '*.*';
  const ASub: Boolean = True): TStringList; overload;
begin
  Result := TStringList.Create;
  GetFileList(ADirectory, Result, AFilter, ASub);
end;

{==| Função - Obter Tamanho de Arquivo (MB) |===================================
  Retorna o tamanho de um arquivo em MegaBytes.
  Parâmetros de entrada:
    1. Nome do arquivo        > String
    2. Resultado em MegaBytes > Booleano (Padrão - Verdadeiro)
  Retorno: Tamanho do arquivo (Real)
============================================| Leandro Medeiros (20/10/2011) |==}
function GetFileSize(sFileName: string; rMB: Boolean = True): Real;
var
  SR  : TSearchRec;
  idx : integer;
begin
  try
    idx := FindFirst(sFileName, faArchive, SR);                                 //Procuro o arquivo e tento abri-lo em memória
    if Bool(idx) then Result := -1                                              //Se ele não for localizado retorno tamanho negativo como sinal de erro
    else begin                                                                  //caso contrário
      if rMB then Result := BytesToMB(SR.Size)                                  //se o usuário desejar retorno seu tamanho em MegaBytes
      else        Result := SR.Size;                                            //senão retorno apenas em Bytes
    end;
  finally                                                                       //Ao final sempre
    SysUtils.FindClose(Sr);                                                     //fecho o arquivo de pesquisa
  end;
end;

{==| Função - Obter Tamanho de Arquivo |========================================
  Retorna o tamanho de um arquivo em Bytes.
  Parâmetros de entrada:
    1. Nome do arquivo        > String
    2. Resultado em MegaBytes > Booleano (Padrão - Verdadeiro)
  Retorno: Tamanho do arquivo (Integer)
============================================| Leandro Medeiros (20/10/2011) |==}
function GetFileSizeB(sFileName: string): Integer;
var
  Sr  : TSearchRec;
  idx : integer;
begin
  try
    idx := FindFirst(sFileName, faArchive, Sr);                                 //Procuro o arquivo e tento abri-lo em memória
    if Bool(idx) then Result := -1                                              //Se ele não for localizado retorno tamanho negativo como sinal de erro
    else Result := Sr.Size;                                                     //caso contrário senão retorno seu tamanho em Bytes
  finally                                                                       //Ao final sempre
    SysUtils.FindClose(Sr);                                                     //fecho o arquivo de pesquisa
  end;
end;

{==| Função - Obter Maior Arquivo |=============================================
  Retorna o tamanho de um arquivo em MegaBytes.
  Parâmetros de entrada:
    1. Lista de Arquivos > TStringList

  Retorno: Nome do maior arquvio (String)
============================================| Leandro Medeiros (20/10/2011) |==}
function GetLargestFile(sFileList: TStringList): string;
var
  idx    : integer;
  rMaior : real;
begin
  rMaior := 0;
  for idx := 0 to sFileList.Count - 1 do
    if GetFileSize(sFileList[idx]) > rMaior then
    begin
      rMaior := GetFileSize(sFileList[idx]);
      Result := sFileList[idx] + ' - '
              + Format('%.2f', [GetFileSize(sFileList[idx])]) + 'MB';
    end;
end;

{==| Função - String Para File Stream |=========================================
    Converte um texto de uma string em um Stream de arquivo. Esta rotina tem
  como principal finalidade ser usada para inserir cabeçalhos e rodapés em
  objetos TWPRichText. Basta chamar esta função de dentro dos procedimentos
  LoadHeaderFromStream e LoadFooterFromStream pertencentes à classe TWPRichText.

  Parâmetros de Entrada:
    1. Texto à ser inserido > String
  Retorno: Texto Convertido(TFileStream)
============================================| Leandro Medeiros (03/11/2011) |==}
function StrToFileStream(Str: String): TFileStream;
var
  tfArquivo : TextFile;
  sTempFile : string;
begin
  sTempFile := GetEnvironmentVariable('Temp') + '\TempStream.Rtf';              //O arquivo temporário será gerado na pasta temporária do sistema sob o nome de "TempStream" com formato RichText
  try
    SysUtils.DeleteFile(sTempFile);                                             //Caso o arquivo exista, o excluo
  except
  end;

  AssignFile(tfArquivo, sTempFile);                                             //Crio o arquivo
  Rewrite(tfArquivo);                                                           //Abro para escrita
  Writeln(tfArquivo, Str);                                                      //Copio o valor da variável de entrada (string) para ele
  CloseFile(tfArquivo);                                                         //Salvo o arquivo

  Result := TFileStream.Create(sTempFile, fmShareDenyNone);                     //Crio um arquivo dinâmico a partir do arquivo temporário com permissões totais de compartilhamento e passo como resultado da função
  SysUtils.DeleteFile(sTempFile);                                               //Excluo o arquivo temporário
end;

{==| Procedimento - Log em Arquivo |============================================
    Cria um arquivo de texto no diretório em que a aplicação está rodando com o
  nome do programa e extensão log (caso já exista, apenas escreve no final do
  mesmo). Sempre marca data e hora mais uma mensagem.
  Parâmetros de Entrada:
    1. Mensagem de Log à ser salvo > String
============================================| Leandro Medeiros (01/11/2012) |==}
procedure FileLog(const AText: string; const ANameByDate: Boolean = True);
var
   sFileName : string;
   ErrorFile : TextFile;
begin
  if not ANameByDate then
    sFileName := ChangeFileExt(Application.ExeName, '.log')
  else begin
    sFileName := ExtractFilePath(Application.ExeName)
               + '\Log\';
    Lib.Files.ValidateDir(sFileName);
    sFileName := sFileName + FormatDateTime('YYYY-MM-DD', Now) + '.log';
  end;

  AssignFile(ErrorFile, sFileName);

  if FileExists(sFileName) then Append(ErrorFile)
  else                          Rewrite(ErrorFile);

  try
    WriteLn(ErrorFile, ' ');
    WriteLn(ErrorFile, '===================');
    if ANameByDate then WriteLn(ErrorFile, Application.Title + ' - ' + TimeToStr(Now))
    else                WriteLn(ErrorFile, DateTimeToStr(Now));
    WriteLn(ErrorFile, '===================');
    WriteLn(ErrorFile, '-> ' + AText);
  finally
    CloseFile(ErrorFile)
  end;
end;

{==| Função - Diretório de Trabalho |===========================================
    Retorna uma string contendo o diretório em que a aplicação está. Concatena
  uma barra ('\') para garantir que possa ser usado para salvar um arquivo por
  exemplo.
============================================| Leandro Medeiros (01/11/2012) |==}
function WorkingDir: string;
var sDir : string;
begin
  sDir := ExtractFilePath(Application.ExeName);
  ValidateDir(sDir);
  Result := sDir;
end;

//==| Função - Criar Arquivo Público |==========================================
function CreatePublicFile(const AFileName: string): Boolean; overload;
var
  PublicFile : TFileStream;
begin
  Result := True;

  try
    Lib.Files.CreatePublicFile(AFileName, PublicFile);
  finally
    FreeAndNil(PublicFile);
  end;
end;

//==| Função - Criar Arquivo Público |==========================================
function CreatePublicFile(const AFileName: string; var AStream: TFileStream): Boolean; overload;
var
  sPath : string;
begin
  try
    sPath := SysUtils.ExtractFilePath(AFileName);

    if Lib.Files.ValidateDir(sPath) then
      if SysUtils.FileExists(AFileName) then
        AStream := TFileStream.Create(AFileName, fmOpenRead)
      else
        AStream := TFileStream.Create(AFileName, fmCreate);

    Result := True;
  except
    Result := False;
  end;
end;

//==| Função - Obtém Próximo nome de arquivo Disponível |=======================
function GetNextFileName(const AFullFileName: string): string;
var
  idx : integer;
  sDir,
  sFileName,
  sExtension : string;
begin
  idx        := 1;
  sDir       := ExtractFilePath(AFullFileName);
  sExtension := ExtractFileExt(AFullFileName);
  sFileName  := Copy(AFullFileName, 1, Length(AFullFileName) - Length(sExtension));

  while FileExists(sDir + sFileName + sExtension) do
  begin
    sFileName := sFileName + '(' + Format('%3.i', [idx]) + ')';
    Inc(idx);
  end;

  Result := sDir + sFileName + sExtension;
end;

//==| Procedimento - Obtém Próximo nome de arquivo Disponível |=================
procedure GetNextFileName(const ADir: string; var AFileName: string);
var
  idx : integer;
  sExtension : string;
begin
  idx        := 1;
  sExtension := ExtractFileExt(AFileName);
  AFileName  := Copy(AFileName, 1, Length(AFileName) - Length(sExtension));

  while FileExists(ADir + AFileName + sExtension) do
  begin
    AFileName := AFileName + '(' + Format('%3.i', [idx]) + ')';
    Inc(idx);
  end;

  AFileName := AFileName + sExtension;
end;

//==| Forçar Exclusão de Arquivo |==============================================
function ForceDelete(const AFileName: string): Boolean;
begin
  Result := False;

  SysUtils.FileSetAttr(AFileName, 0);

  if not SysUtils.DeleteFile(AFileName) then
  try
    SysUtils.RenameFile(AFileName, AFileName + '.old');
    Result := True;
  except
    on e: exception do Lib.Files.FileLog('Falha ao apagar arquivo: ' + e.Message);
  end;
end;

//==| Função - Carregar Arquivo em TBytes |=====================================
function LoadFile(const AFileName: String; ARequiredSizeMod: Integer = 1): TBytes;
var
  fsResult: TFileStream;
begin
  if AFileName = EmptyStr then
  begin
    SetLength(Result, 0);
    Exit;
  end;

  fsResult := TFileStream.Create(AFileName, fmOpenRead);
  try
    if ARequiredSizeMod < 1 then SetLength(Result, fsResult.Size)
    else                         SetLength(Result, ((fsResult.Size div ARequiredSizeMod) + 1) * ARequiredSizeMod);

    fsResult.ReadBuffer(Result[0], fsResult.Size);
  finally
    fsResult.Free;
  end;
end;
//==============================================================================

end.
