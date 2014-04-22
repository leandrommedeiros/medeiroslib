{===============================================================================

                              BIBLIOTECA - ZIP

==========================================================| Vers�o 13.02.00 |==}

unit Lib.ZIP;

interface

{ Bibliotecas para Interface }

const
{ Constantes }
  EXTENSION = '*.zip';

{ Classes }
type
  TCompressionProgress = record
    CurrentFile,
    FileCount : Integer;
  end;

{ Prot�tipos }
  function CompressDirectory(const ASourcePath, ADestFile: string;
    const KeepHierarchy: Boolean = True): Boolean;
  function UncompressImages(const ADir, AZipFile: string): Boolean;

implementation

{ Bibliotecas para Implementa��o }
uses
  Lib.Files, System.Zip, System.Classes, System.SysUtils;

//==| Fun��o - Comprimir Diret�rio |============================================
function CompressDirectory(const ASourcePath, ADestFile: string;
  const KeepHierarchy: Boolean = True): Boolean;
var
  Zip          : TZipFile;
  slFiles      : TStrings;
  sDestFile    : string;
  idx,
  iLengthStart : integer;
begin
  Result := False;

  try
    CreatePublicFile(ADestFile + EXTENSION);
    Zip := TZipFile.Create;
    Zip.Open(ADestFile + EXTENSION, zmReadWrite);

    slFiles := GetFileList(ASourcePath);

    iLengthStart := Length(ASourcePath);

    for idx := 0 to slFiles.Count - 1 do
    begin
      if KeepHierarchy then
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

//==| Fun��o - Descomprime Imagens |============================================
function UncompressImages(const ADir, AZipFile: string): Boolean;
 var
 UnZipper: TZipFile;
begin
 UnZipper:= TZipFile.Create();
 try
  try
   Unzipper.Open(ADir + AZipFile,zmRead);
   Unzipper.ExtractAll(ADir + Copy(AZipFile, 1, Length(AZipFile) - 4));
   Unzipper.Close;
   Result := True;
  except
   Result := False;
  end;
 finally
   DeleteFile(ADir + AZipFile);
   FreeAndNil(UnZipper);
 end;
end;
//==============================================================================

end.
