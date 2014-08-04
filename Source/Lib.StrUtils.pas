{===============================================================================

                         BIBLIOTECA - STRING/UTILS

==========================================================| Vers�o 12.11.00 |==}

unit Lib.StrUtils;

interface

{ Bibliotecas para Interface }
uses
  Classes, SysUtils, Controls, Lib.Files;

const
{ Declara��es de Constantes - Agrupamento de tipos de caracteres }
  sNumbers      = '0123456789';                                                 //Somente n�meros
  sUpperCase    = 'ABCDEFGHIJKLMNOPQRSTUVXWYZ';                                 //Somente Letras Mai�sculas
  sLowerCase    = 'abcdefghijklmnopqrstuvxwyz';                                 //Somente Letras Min�sculas
  sUpperAccents = '�����������������������';                                    //Letras Mai�sculas Acentuadas
  sLowerAccents = '�����������������������';                                    //Letras Min�sculas Acentuadas
  sAllLetters   = sUpperCase + sLowerCase + sUpperAccents + sLowerAccents;      //Todas as Letras
  sSpecialChars = '!@#$%&*()_+������-=�[{�}]�/?�:;.,<>\|~^�`"' + Chr(39);       //Caracteres especiais

{ Prot�tipos }
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

{ Bibliotecas para Implementa��o }
uses
  IdHash, IdHashMessageDigest, // Para fun��o MD5 [2]
  Math, StrUtils;

{==| Fun��o - Extrair Letras Maiusculas |=======================================
    Varre a string de entrada e retorna uma segunda string com todas as letras
  ma�sculas que a primeira cont�m.
============================================| Leandro Medeiros (20/10/2011) |==}
function ExtractUpperCase(S: string): string;
begin
  S := Trim(S);                                                                 //Retiro os espa�os da string
  DelInvalidChars(S, sUpperCase + sUpperAccents);                               //Removo os caracteres que n�o forem Letras Mai�sculas
  result := S;                                                                  //retorno a vari�vel de entrada
end;

{==| Fun��o - Primeira Letra Mai�scula |========================================
    Retorna a string de entrada com a primeira letra de cada palavra em ma�sculo
  e as demais em min�sculo.
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

{==| Procedimento - Exclui Caracteres Inv�lidos |===============================
    Varre uma string em busca de caracteres que n�o estejam dentre os desejados
  e os exclui.
  Par�metros de entrada:
    1. Texto a ser avaliado             > String
    2. Constante com caracteres v�lidos > String
============================================| Leandro Medeiros (20/10/2011) |==}
procedure DelInvalidChars(var S: string; const sValidChars: string);
var
  idx : integer;
begin
  idx := Length(S);                                                             //O �ndice partir� do �ltimo caracter da string
  while idx > 0 do                                                              //enquanto o mesmo for maior que zero
  begin
    if Pos(S[idx], sValidChars) = 0 then                                        //caso o caracter correspondente ao �ndice do loop n�o esteja no meio dos caracteres v�lidos
      Delete(S, idx, 1);                                                        //excluo ele da string
    Inc(idx, - 1);                                                              //e sempre decremento o �ndice
  end;
end;

{==| Fun��o - Retorna Caracteres V�lidos |======================================
    Varre uma string em busca de caracteres que n�o estejam dentre os desejados
  e os exclui.
  Par�metros de entrada:
    1. Texto a ser avaliado             > String
    2. Constante com caracteres v�lidos > String
  Retorno: String
============================================| Leandro Medeiros (20/10/2011) |==}
function ReturnValidChars(S: string; const sValidChars: string): string;
var
  idx : integer;
begin
  idx := Length(S);                                                             //O �ndice partir� do �ltimo caracter da string
  while idx > 0 do                                                              //enquanto o mesmo for maior que zero
  begin
    if Pos(S[idx], sValidChars) = 0 then                                        //caso o caracter correspondente ao �ndice do loop n�o esteja no meio dos caracteres v�lidos
      Delete(S, idx, 1);                                                        //excluo ele da string
    Inc(idx, - 1);                                                              //e sempre decremento o �ndice
  end;
  Result := S;
end;

{==| Fun��o - Remove Caracteres Inv�lidos |=====================================
    Varre uma string em busca de caracteres de uma constante e os exclui.
  Par�metros de entrada:
    1. Texto a ser avaliado               > String
    2. Constante com caracteres inv�lidos > String
  Retorno: String
============================================| Leandro Medeiros (13/03/2012) |==}
function RemoveInvalidChars(S: string; const sInvalidChars: string): string;
var
  idx : integer;
begin
  idx := Length(S);                                                             //O �ndice partir� do �ltimo caracter da string
  while idx > 0 do                                                              //enquanto o mesmo for maior que zero
  begin
    if Pos(S[idx], sInvalidChars) > 0 then                                      //caso o caracter correspondente ao �ndice do loop esteja no meio dos caracteres v�lidos
      Delete(S, idx, 1);                                                        //excluo ele da string
    Inc(idx, - 1);                                                              //e sempre decremento o �ndice
  end;
  Result := S;
end;

{==| Fun��o - Cont�m Caracteres Inv�lidos |=====================================
    Varre uma String procurando por caracteres de uma constante, se encontrar
  algum retorna verdadeiro.
  Par�metros de Entrada:
    1. Texto � ser varrido              > String
    2. Constante com caracteres v�lidos > String
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

{==| Fun��o - Calcula Chassi |==================================================
    Fun��o constru�da a partir de rotina existente no ReqRis. Retorna uma string
  com 7 caracteres aleat�rios (baseados no hor�rio da m�quina).
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

{==| Fun��o - Encontrar String |================================================
    Busca um string dentro de uma lista e retorna o �ndice caso encontre, caso
  contr�rio retorna -1.
  Par�metros de Entrada:
    1. Lista onde a busca ser� efetuada > TStrings
    2. Valor procurado                  > String
  Retorno: �ndice da string na lista (Integer)
============================================| Leandro Medeiros (11/11/2011) |==}
function List_FindStr(sList: TStrings; S: string): integer;
var
  idx : integer;
begin
  for idx := 0 to sList.Count - 1 do                                            //Varro da primeira � �ltima linha da lista
    if sList.Strings[idx] = S then                                              //Se a linha atual do loop tiver o mesmo valor da vari�vel de entrada
    begin
      Result := idx;                                                            //Retorno o �ndice da linha
      Exit;                                                                     //e paro a execu��o
    end;
  Result := -1;                                                                 //Se chegar aqui � porque a string n�o est� na lista, ent�o retorno �ndice negativo
end;

{==| Fun��o - Seconds |=========================================================
    Converte um hor�rio em segundos.
  Par�metros de entrada:
    1. Hor�rio > TDateTime
  Retorno: Correspond�ncia em segundos (Integer)
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


{==| Fun��o - Formatar C�digo AMB |=============================================
    Recebe uma string e, se a mesma contiver 8 caracteres num�ricos a fun��o os
  formata no padr�o AMB (00.00.000-0).
  Par�metros de entrada:
    1. C�digo AMB(que esteja somente em n�meros) > String
  Retorno:
    C�digo AMB formatado (String)
============================================| Leandro Medeiros (02/12/2011) |==}
function FormatAMB(nAMB: string): string;
begin
  if (Length(nAMB) <> 8) or                                                     //Se a string de entrada n�o tiver 8 caracteres de largura
     (HasInvalidChars(nAMB, sNumbers)) then                                     //ou tiver caracteres diferentes dos n�meros
    Result := nAMB                                                              //retorno ela mesma
  else begin
    Result := Copy(nAMB, 1, 2) + '.'                                            //caso contr�rio formato de acordo com o padr�o AMB
            + Copy(nAMB, 3, 2) + '.'
            + Copy(nAMB, 5, 3) + '-'
            + Copy(nAMB, 8, 1);
  end;
end;

{==| Fun��o - Formatar C�digo TUSS |============================================
    Recebe uma string e, se a mesma contiver 8 caracteres num�ricos a fun��o os
  formata no padr�o TUSS (0.00.00.00-0).
  Par�metros de entrada:
    1. C�digo TUSS(que esteja somente em n�meros) > String
  Retorno:
    C�digo TUSS formatado (String)
============================================| Leandro Medeiros (02/12/2011) |==}
function FormatTUSS(nTUSS: string): string;
begin
  if (Length(nTUSS) <> 8) or                                                    //Se a string de entrada n�o tiver 8 caracteres de largura
     (HasInvalidChars(nTUSS, sNumbers)) then                                    //ou tiver caracteres diferentes dos n�meros
    Result := nTUSS                                                             //retorno ela mesma
  else begin
    Result := Copy(nTUSS, 1, 1) + '.'                                           //caso contr�rio formato de acordo com o padr�o AMB
            + Copy(nTUSS, 2, 2) + '.'
            + Copy(nTUSS, 4, 2) + '.'
            + Copy(nTUSS, 6, 2) + '-'
            + Copy(nTUSS, 8, 1);
  end;
end;

{==| Fun��o - Gera String Aleat�ria |===========================================
    Gera um c�digo �nico de 19 d�gitos formado � pelo par�metro PREFIXO
  concatenado � data/hora completas em formato num�rico.
  Par�metros de Entrada:
    1. Prefixo                    > String.
  Retorno:
    C�digo num�rico de 19 dig�tos > String.
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

{==| Fun��o - Gera Hash Aleat�rio |=============================================
    Gera um c�digo �nico de 32 caracteres formado � pelo par�metro PREFIXO
  concatenado � data/hora completas em formato num�rico.
  Par�metros de Entrada:
    1. Complemento                > String.
  Retorno:
    C�digo num�rico de 19 dig�tos > String.
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

{==| Fun��o - Para Data Americana (String) |====================================
    Recebe um TDate, inverte as posic�es do dia e m�s e devolve uma string
  formatada como data americana (mm/dd/aaaa).
============================================| Leandro Medeiros (20/10/2011) |==}
function ToAmericanDateS(D: TDate; Quoted: Boolean = True): string;
begin
  if Quoted then Result := QuotedStr(FormatDateTime('mm/dd/yyyy', D))
  else           Result := FormatDateTime('mm/dd/yyyy', D);
end;

//==| Fun��o - Para Ponto Flutuante |===========================================
function ToFloat(S: String): Real;
begin
  DelInvalidChars(S, sNumbers + ',');                                           //Removo os caracteres que n�o forem n�meros ou v�rgulas da string de entrada
  if S = '' then S := '0';                                                      //Se a string tiver sido esvaziada mudo para Zero
  Result := StrToFloat(S);                                                      //retorno a vari�vel como um n�mero decimal
end;

//==| Fun��o - Para Moeda (String) |============================================
function ToCurrencyS(rValue: Real; ThousandSeparator: Boolean = True): String;
begin
  if ThousandSeparator then Result := Format('%.2n', [rValue])                  //Formato com separador de milhares e duas casas decimais
  else Result := Format('%.2f', [rValue]);                                      //Formato sem separador de milhares e duas casas decimais
end;

//==| Fun��o - String para Stream |=============================================
function StrToStream(const AText: string): TStringStream;
begin
  Result := TStringStream.Create(AText);
end;

//==| Fun��o - String Para Hexadecimais |=======================================
function StrToHex(const ABuffer: Ansistring): string;
var
  idx : Integer;
begin
  Result := EmptyStr;

  for idx := 1 to Length(ABuffer) do
    Result := LowerCase(Result + IntToHex(Ord(ABuffer[idx]), 2));
end;

//==| Fun��o - Hexadecimais Para String |=======================================
function HexToStr(const ABuffer: string): Ansistring;
var
  idx : Integer;
begin
  Result := EmptyStr;

  for idx := 1 to Length(ABuffer) div 2 do
    Result:= Result + Char(StrToInt('$' + Copy(ABuffer,(idx - 1) * 2 + 1, 2)));
end;

//==| Fun��o - Hash MD5 (String) |==============================================
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

//==| Fun��o - Hash MD5 (TBytes) |==============================================
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

//==| Fun��o - Hash MD5 (Stream) |==============================================
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
