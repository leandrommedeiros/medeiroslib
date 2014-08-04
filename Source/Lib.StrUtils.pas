{===============================================================================

                         BIBLIOTECA - STRING/UTILS

==========================================================| Versão 12.11.00 |==}

unit Lib.StrUtils;

interface

{ Bibliotecas para Interface }
uses
  Classes, SysUtils, Controls, Lib.Files;

const
{ Declarações de Constantes - Agrupamento de tipos de caracteres }
  sNumbers      = '0123456789';                                                 //Somente números
  sUpperCase    = 'ABCDEFGHIJKLMNOPQRSTUVXWYZ';                                 //Somente Letras Maiúsculas
  sLowerCase    = 'abcdefghijklmnopqrstuvxwyz';                                 //Somente Letras Minúsculas
  sUpperAccents = 'ÁÉÍÓÚÇÀÈÌÒÙÂÊÎÔÛÄËÏÖÜÃÕ';                                    //Letras Maiúsculas Acentuadas
  sLowerAccents = 'áéíóúçàèìòùâêîôûäëïöüãõ';                                    //Letras Minúsculas Acentuadas
  sAllLetters   = sUpperCase + sLowerCase + sUpperAccents + sLowerAccents;      //Todas as Letras
  sSpecialChars = '!@#$%&*()_+¹²³£¢¬-=§[{ª}]º/?°:;.,<>\|~^´`"' + Chr(39);       //Caracteres especiais

{ Protótipos }
  function  ExtractUpperCase(S: string): string;
  function  UpperName(S:string): string;
  procedure DelInvalidChars(var S: string; const sValidChars: string);
  function  ReturnValidChars(S: string; const sValidChars: string): string;
  function  RemoveInvalidChars(S: string; const sInvalidChars: string): string;
  function  HasInvalidChars(const S, sValidChars: string): Boolean;
  function  CalcChassi: string;
  function  List_FindStr(sList: TStrings; S: string): integer;
  function  Seconds(Time: TDateTime): integer;
  function  FormatAMB(nAMB: string): string;
  function  FormatTUSS(nTUSS: string): string;
  function  GenRandomStr(const APrefix: string = ''): string;
  function  GenRandomHash(const AComplement: string = ''): string;
  function  ToAmericanDateS(D: TDate; Quoted: Boolean = True): string;
  function  ToFloat(S: String): Real;
  function  ToCurrencyS(rValue: Real; ThousandSeparator: Boolean = True): String;
  function  StrToStream(const AText: string): TStringStream;
  function  StrToHex(const ABuffer: Ansistring): string;
  function  HexToStr(const ABuffer: string): Ansistring;
  function  MD5(const AContent: string): string; overload;
  function  MD5(const AContent: TBytes): string; overload;
  function  MD5(const AContent: TStream): string; overload;

implementation

{ Bibliotecas para Implementação }
uses
  IdHash, IdHashMessageDigest, // Para função MD5 [2]
  Math, StrUtils;

{==| Função - Extrair Letras Maiusculas |=======================================
    Varre a string de entrada e retorna uma segunda string com todas as letras
  maúsculas que a primeira contém.
============================================| Leandro Medeiros (20/10/2011) |==}
function ExtractUpperCase(S: string): string;
begin
  S := Trim(S);                                                                 //Retiro os espaços da string
  DelInvalidChars(S, sUpperCase + sUpperAccents);                               //Removo os caracteres que não forem Letras Maiúsculas
  result := S;                                                                  //retorno a variável de entrada
end;

{==| Função - Primeira Letra Maiúscula |========================================
    Retorna a string de entrada com a primeira letra de cada palavra em maúsculo
  e as demais em minúsculo.
============================================| Leandro Medeiros (25/05/2012) |==}
function UpperName(S: string): string;
  function IsNameConnector(S: string): boolean;
  const
    sNameConnectors = 'da,de,do,das,dos,e';
  begin
    S      := AnsiLowerCase(Trim(S));
    Result := AnsiPos(S, sNameConnectors) > 0;
  end;
var
  idx       : integer;
  UpperNext : Boolean;
begin
  S         := Trim(AnsiLowerCase(S));
  UpperNext := True;

  for idx := 1 to Length(S) do
  begin
    if (UpperNext) and not (IsNameConnector(Copy(S, idx, 3))) then
      S[idx] := AnsiUpperCase(S[idx])[1];
    UpperNext := S[idx] = Chr(32);
  end;

  Result := S;
end;

{==| Procedimento - Exclui Caracteres Inválidos |===============================
    Varre uma string em busca de caracteres que não estejam dentre os desejados
  e os exclui.
  Parâmetros de entrada:
    1. Texto a ser avaliado             > String
    2. Constante com caracteres válidos > String
============================================| Leandro Medeiros (20/10/2011) |==}
procedure DelInvalidChars(var S: string; const sValidChars: string);
var
  idx : integer;
begin
  idx := Length(S);                                                             //O índice partirá do último caracter da string
  while idx > 0 do                                                              //enquanto o mesmo for maior que zero
  begin
    if Pos(S[idx], sValidChars) = 0 then                                        //caso o caracter correspondente ao índice do loop não esteja no meio dos caracteres válidos
      Delete(S, idx, 1);                                                        //excluo ele da string
    Inc(idx, - 1);                                                              //e sempre decremento o índice
  end;
end;

{==| Função - Retorna Caracteres Válidos |======================================
    Varre uma string em busca de caracteres que não estejam dentre os desejados
  e os exclui.
  Parâmetros de entrada:
    1. Texto a ser avaliado             > String
    2. Constante com caracteres válidos > String
  Retorno: String
============================================| Leandro Medeiros (20/10/2011) |==}
function ReturnValidChars(S: string; const sValidChars: string): string;
var
  idx : integer;
begin
  idx := Length(S);                                                             //O índice partirá do último caracter da string
  while idx > 0 do                                                              //enquanto o mesmo for maior que zero
  begin
    if Pos(S[idx], sValidChars) = 0 then                                        //caso o caracter correspondente ao índice do loop não esteja no meio dos caracteres válidos
      Delete(S, idx, 1);                                                        //excluo ele da string
    Inc(idx, - 1);                                                              //e sempre decremento o índice
  end;
  Result := S;
end;

{==| Função - Remove Caracteres Inválidos |=====================================
    Varre uma string em busca de caracteres de uma constante e os exclui.
  Parâmetros de entrada:
    1. Texto a ser avaliado               > String
    2. Constante com caracteres inválidos > String
  Retorno: String
============================================| Leandro Medeiros (13/03/2012) |==}
function RemoveInvalidChars(S: string; const sInvalidChars: string): string;
var
  idx : integer;
begin
  idx := Length(S);                                                             //O índice partirá do último caracter da string
  while idx > 0 do                                                              //enquanto o mesmo for maior que zero
  begin
    if Pos(S[idx], sInvalidChars) > 0 then                                      //caso o caracter correspondente ao índice do loop esteja no meio dos caracteres válidos
      Delete(S, idx, 1);                                                        //excluo ele da string
    Inc(idx, - 1);                                                              //e sempre decremento o índice
  end;
  Result := S;
end;

{==| Função - Contém Caracteres Inválidos |=====================================
    Varre uma String procurando por caracteres de uma constante, se encontrar
  algum retorna verdadeiro.
  Parâmetros de Entrada:
    1. Texto à ser varrido              > String
    2. Constante com caracteres válidos > String
  Retorno: Booleano
============================================| Leandro Medeiros (10/02/2012) |==}
function HasInvalidChars(const S, sValidChars: string): Boolean;
var
  idx : integer;
begin
  Result := False;

  for idx := 1 to Length(S) do
    if Pos(S[idx], sValidChars) = 0 then
    begin
      Result := True;
      Break;
    end;
end;

{==| Função - Calcula Chassi |==================================================
    Função construída a partir de rotina existente no ReqRis. Retorna uma string
  com 7 caracteres aleatórios (baseados no horário da máquina).
============================================| Leandro Medeiros (11/11/2011) |==}
function CalcChassi: string;
var
  sAux1, sAux2, sSegundo, sChassi: String;
  iSoma : Integer;
begin
  try
    sSegundo := IntToStr(Seconds(Time));
    sChassi  := sSegundo;
    sAux1    := Copy(sSegundo, 3, 1);
    sAux2    := Copy(sSegundo, 5, 1);
    iSoma    := StrToInt(sAux1) + StrToInt(sAux2);
    sChassi  := StuffString(sChassi, 2, 0, Copy(sUpperCase, iSoma, 1));

    sAux1    := Copy(sSegundo, 2, 1);
    sAux2    := Copy(sSegundo, 4, 1);
    iSoma    := StrToInt(sAux1) + StrToInt(sAux2);
    sChassi  := StuffString(sChassi, 4, 0, Copy(sUpperCase, iSoma, 1));

    sAux1    := Copy(sSegundo, 4, 1);
    sAux2    := Copy(sSegundo, 1, 1);
    iSoma    := StrToInt(sAux1) + StrToInt(sAux2);
    Result   := StuffString(sChassi, 6, 1, Copy(sUpperCase, iSoma, 1));
  except
    Result   := '';
  end;
end;

{==| Função - Encontrar String |================================================
    Busca um string dentro de uma lista e retorna o índice caso encontre, caso
  contrário retorna -1.
  Parâmetros de Entrada:
    1. Lista onde a busca será efetuada > TStrings
    2. Valor procurado                  > String
  Retorno: Índice da string na lista (Integer)
============================================| Leandro Medeiros (11/11/2011) |==}
function List_FindStr(sList: TStrings; S: string): integer;
var
  idx : integer;
begin
  for idx := 0 to sList.Count - 1 do                                            //Varro da primeira à última linha da lista
    if sList.Strings[idx] = S then                                              //Se a linha atual do loop tiver o mesmo valor da variável de entrada
    begin
      Result := idx;                                                            //Retorno o índice da linha
      Exit;                                                                     //e paro a execução
    end;
  Result := -1;                                                                 //Se chegar aqui é porque a string não está na lista, então retorno índice negativo
end;

{==| Função - Seconds |=========================================================
    Converte um horário em segundos.
  Parâmetros de entrada:
    1. Horário > TDateTime
  Retorno: Correspondência em segundos (Integer)
============================================| Leandro Medeiros (22/05/2012) |==}
function Seconds(Time: TDateTime): integer;
var
   wHour, wMin, wSec, wMSec : word;
begin
  DecodeTime(Time, wHour, wMin, wSec, wMSec);
  Result := (wHour * 3600)
          + (wMin  *   60)
          + (wSec)
          + (wMSec div 1000);
end;


{==| Função - Formatar Código AMB |=============================================
    Recebe uma string e, se a mesma contiver 8 caracteres numéricos a função os
  formata no padrão AMB (00.00.000-0).
  Parâmetros de entrada:
    1. Código AMB(que esteja somente em números) > String
  Retorno:
    Código AMB formatado (String)
============================================| Leandro Medeiros (02/12/2011) |==}
function FormatAMB(nAMB: string): string;
begin
  if (Length(nAMB) <> 8) or                                                     //Se a string de entrada não tiver 8 caracteres de largura
     (HasInvalidChars(nAMB, sNumbers)) then                                     //ou tiver caracteres diferentes dos números
    Result := nAMB                                                              //retorno ela mesma
  else begin
    Result := Copy(nAMB, 1, 2) + '.'                                            //caso contrário formato de acordo com o padrão AMB
            + Copy(nAMB, 3, 2) + '.'
            + Copy(nAMB, 5, 3) + '-'
            + Copy(nAMB, 8, 1);
  end;
end;

{==| Função - Formatar Código TUSS |============================================
    Recebe uma string e, se a mesma contiver 8 caracteres numéricos a função os
  formata no padrão TUSS (0.00.00.00-0).
  Parâmetros de entrada:
    1. Código TUSS(que esteja somente em números) > String
  Retorno:
    Código TUSS formatado (String)
============================================| Leandro Medeiros (02/12/2011) |==}
function FormatTUSS(nTUSS: string): string;
begin
  if (Length(nTUSS) <> 8) or                                                    //Se a string de entrada não tiver 8 caracteres de largura
     (HasInvalidChars(nTUSS, sNumbers)) then                                    //ou tiver caracteres diferentes dos números
    Result := nTUSS                                                             //retorno ela mesma
  else begin
    Result := Copy(nTUSS, 1, 1) + '.'                                           //caso contrário formato de acordo com o padrão AMB
            + Copy(nTUSS, 2, 2) + '.'
            + Copy(nTUSS, 4, 2) + '.'
            + Copy(nTUSS, 6, 2) + '-'
            + Copy(nTUSS, 8, 1);
  end;
end;

{==| Função - Gera String Aleatória |===========================================
    Gera um código único de 19 dígitos formado à pelo parâmetro PREFIXO
  concatenado à data/hora completas em formato numérico.
  Parâmetros de Entrada:
    1. Prefixo                    > String.
  Retorno:
    Código numérico de 19 digítos > String.
============================================| Leandro Medeiros (05/06/2011) |==}
function GenRandomStr(const APrefix: string = ''): string;
var S : String;
begin
  S := FloatToStr(Now);

  DelInvalidChars(S, sNumbers);

  while Length(S) < 16 do
  begin
    Randomize;
    S := S + IntToStr(RandomRange(0,9));
  end;

  S      := APrefix + S;
  Result := S;
end;

{==| Função - Gera Hash Aleatório |=============================================
    Gera um código único de 32 caracteres formado à pelo parâmetro PREFIXO
  concatenado à data/hora completas em formato numérico.
  Parâmetros de Entrada:
    1. Complemento                > String.
  Retorno:
    Código numérico de 19 digítos > String.
============================================| Leandro Medeiros (02/04/2012) |==}
function GenRandomHash(const AComplement: string = ''): string;
var
  S : string;
begin
  S := FloatToStr(Now) + AComplement;

  Randomize;
  S := S + IntToStr(RandomRange(1000, 9999));

  Result := Lib.StrUtils.MD5(S);
end;

{==| Função - Para Data Americana (String) |====================================
    Recebe um TDate, inverte as posicões do dia e mês e devolve uma string
  formatada como data americana (mm/dd/aaaa).
============================================| Leandro Medeiros (20/10/2011) |==}
function ToAmericanDateS(D: TDate; Quoted: Boolean = True): string;
begin
  if Quoted then Result := QuotedStr(FormatDateTime('mm/dd/yyyy', D))
  else           Result := FormatDateTime('mm/dd/yyyy', D);
end;

//==| Função - Para Ponto Flutuante |===========================================
function ToFloat(S: String): Real;
begin
  DelInvalidChars(S, sNumbers + ',');                                           //Removo os caracteres que não forem números ou vírgulas da string de entrada
  if S = '' then S := '0';                                                      //Se a string tiver sido esvaziada mudo para Zero
  Result := StrToFloat(S);                                                      //retorno a variável como um número decimal
end;

//==| Função - Para Moeda (String) |============================================
function ToCurrencyS(rValue: Real; ThousandSeparator: Boolean = True): String;
begin
  if ThousandSeparator then Result := Format('%.2n', [rValue])                  //Formato com separador de milhares e duas casas decimais
  else Result := Format('%.2f', [rValue]);                                      //Formato sem separador de milhares e duas casas decimais
end;

//==| Função - String para Stream |=============================================
function StrToStream(const AText: string): TStringStream;
begin
  Result := TStringStream.Create(AText);
end;

//==| Função - String Para Hexadecimais |=======================================
function StrToHex(const ABuffer: Ansistring): string;
var
  idx : Integer;
begin
  Result := EmptyStr;

  for idx := 1 to Length(ABuffer) do
    Result := LowerCase(Result + IntToHex(Ord(ABuffer[idx]), 2));
end;

//==| Função - Hexadecimais Para String |=======================================
function HexToStr(const ABuffer: string): Ansistring;
var
  idx : Integer;
begin
  Result := EmptyStr;

  for idx := 1 to Length(ABuffer) div 2 do
    Result:= Result + Char(StrToInt('$' + Copy(ABuffer,(idx - 1) * 2 + 1, 2)));
end;

//==| Função - Hash MD5 (String) |==============================================
function MD5(const AContent: string): string;
begin
  Result := EmptyStr;

  with TIdHashMessageDigest5.Create do
    try
      {$IFDEF VER150}
      Result := AnsiLowerCase(AsHex(HashValue(AContent)));
      {$ELSE}
      Result := AnsiLowerCase(HashStringAsHex(AContent));
      {$ENDIF}
    finally
      Free;
    end;
end;

//==| Função - Hash MD5 (TBytes) |==============================================
function MD5(const AContent: TBytes): string;
var
  vStream : TMemoryStream;
begin
  Result := EmptyStr;

  if Length(AContent) > 0 then
    try
      vStream := TMemoryStream.Create;
      vStream.WriteBuffer(AContent[0], Length(AContent));
      vStream.Position := 0;

      Result := MD5(vStream);
    finally
      vStream.Free;
    end;
end;

//==| Função - Hash MD5 (Stream) |==============================================
function MD5(const AContent: TStream): string;
begin
  Result := EmptyStr;

  with TIdHashMessageDigest5.Create do
    try
      {$IFDEF VER150}
      Result := AnsiLowerCase(AsHex(HashValue(AContent)));
      {$ELSE}
      Result := AnsiLowerCase(HashStreamAsHex(AContent));
      {$ENDIF}
    finally
      Free;
    end;
end;
//==============================================================================

end.
