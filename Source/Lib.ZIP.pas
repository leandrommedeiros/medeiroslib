{===============================================================================

                              BIBLIOTECA - ZIP

==========================================================| Versão 13.02.00 |==}

unit Lib.ZIP;

interface

{ Bibliotecas para Interface }

const
{ Constantes }
  DEFAULT_EXTENSION = '.zip';

{ Classes }
type
  TCompressionProgress = record
    CurrentFile,
    FileCount : Integer;
  end;

{ Protótipos }
  function CompressDirectory(const ASourcePath: string; ATargetFile: string;
    const AKeepHierarchy: Boolean = True; const Append: Boolean = False): Boolean;
  function UncompressFile(const APath, AZipFile: string;
    const ADelAfterUnzip: Boolean = False): Boolean;

implementation

{ Bibliotecas para Implementação }
uses
  Lib.Files, System.Zip, System.Classes, SysUtils;

//==| Função - Comprimir Diretório |============================================
function CompressDirectory(const ASourcePath: string; ATargetFile: string;
  const AKeepHierarchy: Boolean = True; const Append: Boolean = False): Boolean;
var
  Zip          : TZipFile;
  slFiles      : TStrings;
  sDestFile    : string;
  idx,
  iLengthStart : integer;
begin
  Result := False;

  try
    if SysUtils.ExtractFileExt(ATargetFile) = EmptyStr then
      ATargetFile := ATargetFile + DEFAULT_EXTENSION;

    if not Append and SysUtils.FileExists(ATargetFile) then
      Lib.Files.ForceDelete(ATargetFile);

    Lib.Files.CreatePublicFile(ATargetFile);
    Zip := TZipFile.Create;
    Zip.Open(ATargetFile, zmReadWrite);

    slFiles := Lib.Files.GetFileList(ASourcePath);

    iLengthStart := Length(ASourcePath);

    for idx := 0 to slFiles.Count - 1 do
    begin
      if AKeepHierarchy then
        sDestFile := Copy(slFiles[idx], iLengthStart, Length(slFiles[idx]) - 1)
      else
        sDestFile := ExtractFileName(slFiles[idx]);

      Zip.Add(slFiles[idx], sDestFile);
    end;

    Zip.Close;
    Result := True;
  except
    on E: Exception do Lib.Files.Log(E.ClassName + ' raised error: ' + E.Message);
  end;
end;

//==| Função - Descomprimir Arquivo |===========================================
function UncompressFile(const APath, AZipFile: string;
  const ADelAfterUnzip: Boolean = False): Boolean;
var
  UnZipper: TZipFile;
begin
  Result   := False;
  UnZipper := TZipFile.Create;

  try
   Unzipper.Open(APath + AZipFile, zmRead);
   Unzipper.ExtractAll(APath + Copy(AZipFile, 1, Length(AZipFile) - 4));
   Unzipper.Close;
   Result := True;

   if ADelAfterUnzip then Lib.Files.ForceDelete(APath + AZipFile);
 finally
   FreeAndNil(UnZipper);
 end;
end;
//==============================================================================

end.
