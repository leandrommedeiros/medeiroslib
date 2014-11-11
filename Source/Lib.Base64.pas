{*******************************************************************************

                            BIBLIOTECA - BASE 64

*******************************************************************************}

unit Lib.Base64;

interface

{ Protótipos }
  function Encode(const AContent: string): string;
  function Decode(const AContent: string): string;

implementation

{ Bibliotecas para Implementação }
uses
  IdCoderMIME, System.SysUtils;

//==| Codificar |===============================================================
function Encode(const AContent: string): string;
begin
  try
    with TIdEncoderMIME.Create(nil) do
      Result := EncodeString(AContent);
  except
    on e: Exception do
      raise Exception.Create('Erro ao criptografar: ' + e.Message);
  end;
end;

//==| Decodificar |=============================================================
function Decode(const AContent: string): string;
begin
  try
    with TIdDecoderMIME.Create(nil) do
      Result := DecodeString(AContent);
  except
    on e: Exception do
      raise Exception.Create('Erro ao descriptografar: ' + e.Message);
  end;
end;
//==============================================================================

end.
