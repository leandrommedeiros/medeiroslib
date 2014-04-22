unit Lib.Crypto;

interface

const
  DEFAULT_CRYPTO_KEY = '2mitsolutions_encryptation_key';

//  function Encrypt(const AValue: string; APassphrase: String = '') : String;
//  function Decrypt(const AValue: string; APassphrase: String = '') : String;

implementation

//uses
//  DCPcrypt2, DCPblockciphers, DCPblowfish, DCPsha512, Math, SysUtils, Classes;
//
//function Encrypt(const AValue: string; APassphrase: String = '') : String;
//var
//  Salt       : array[0..7] of byte;
//  CipherIV   : array of byte;
//  HashDigest : array of byte;
//  Hash       : TDCP_sha512;
//  Cipher     : TDCP_blowfish;
//  idx        : Integer;
//  Input,
//  Output     : TStringStream;
//begin
//  Result := EmptyStr;
//
//  if APassphrase = EmptyStr then APassphrase := DEFAULT_CRYPTO_KEY;
//
//  try
//    Input  := TStringStream.Create(AValue);
//    Output := TStringStream.Create;
//
//    Hash   := TDCP_sha512.Create(nil);
//    Hash.Algorithm := 'SHA512';
//    Hash.Id        := 30;
//    Hash.HashSize  := 512;
//
//    Cipher := TDCP_blowfish.Create(nil);
//    Cipher.BlockSize  := 64;
//    Cipher.CipherMode := cmCBC;
//    Cipher.Id         := 5;
//    Cipher.MaxKeySize := 448;
//
//    SetLength(HashDigest, Hash.HashSize div 8);
//
//    for idx := 0 to 7 do Salt[idx] := Random(256);
//
//    Output.WriteBuffer(Salt, Sizeof(Salt));
//
//    Hash.Init;
//    Hash.Update(Salt[0], Sizeof(Salt));
//    Hash.UpdateStr(APassphrase);
//    Hash.Final(HashDigest[0]);
//    SetLength(CipherIV, Cipher.BlockSize div 8);
//
//    for idx := 0 to (Length(CipherIV) - 1) do CipherIV[idx] := Random(256);
//
//    Output.WriteBuffer(CipherIV[0], Length(CipherIV));
//    Cipher.Init(HashDigest[0], Min(Cipher.MaxKeySize, Hash.HashSize), CipherIV);
//    Cipher.EncryptStream(Input, Output, Input.Size);
//    Cipher.Burn;
//
//    Result := Output.DataString;
//  finally
//    FreeAndNil(Hash);
//    FreeAndNil(Cipher);
//    FreeAndNil(Input);
//    FreeAndNil(Output);
//  end;
//end;
//
//function Decrypt(const AValue: string; APassphrase: String = ''): String;
//var
//  Cipher     : TDCP_blowfish;
//  CipherIV   : array of byte;
//  Hash       : TDCP_sha512;
//  HashDigest : array of byte;
//  Salt       : array[0..7] of byte;
//  Input,
//  Output     : TStringStream;
//begin
//  Result := EmptyStr;
//
//  if APassphrase = EmptyStr then APassphrase := DEFAULT_CRYPTO_KEY;
//
//  try
//    Input          := TStringStream.Create(AValue);
//    Input.Position := 0;
//    Output         := TStringStream.Create;
//
//    Hash           := TDCP_sha512.Create(nil);
//    Hash.Algorithm := 'SHA512';
//    Hash.Id        := 30;
//    Hash.HashSize  := 512;
//
//    Cipher            := TDCP_blowfish.Create(nil);
//    Cipher.BlockSize  := 64;
//    Cipher.CipherMode := cmCBC;
//    Cipher.Id         := 5;
//    Cipher.MaxKeySize := 448;
//
//    SetLength(HashDigest, Hash.HashSize div 8);
//
//    Input.ReadBuffer(Salt[0], Sizeof(Salt));
//    Hash.Init;
//    Hash.Update(Salt[0], Sizeof(Salt));
//    Hash.UpdateStr(APassphrase);
//    Hash.Final(HashDigest[0]);
//
//    SetLength(CipherIV, TDCP_blockcipher(Cipher).BlockSize div 8);
//    Input.ReadBuffer(CipherIV[0], Length(CipherIV));
//    Cipher.Init(HashDigest[0], Min(Cipher.MaxKeySize, Hash.HashSize), CipherIV);
//    Cipher.DecryptStream(Input, Output, Input.Size - Input.Position);
//    Cipher.Burn;
//
//    Result := Output.DataString;
//  finally
//    FreeAndNil(Hash);
//    FreeAndNil(Cipher);
//    FreeAndNil(Input);
//    FreeAndNil(Output);
//  end;
//end;

end.

//interface
//
//// ---------------------------------------------------
//// CryptoUnit
//// Version 1.1
////
//// Copywrite CairnsGames S.A.
////
//// This unit is free for use (for anything)
//// Let me know if you sell it though :)
////
//// ---------------------------------------------------
//// Requires the DCP Components to be installed and in the search path
//// of the application
//// DCP Components are available from :
//// http://www.cityinthesky.co.uk/cryptography.html
//
//uses
//  SysUtils, Classes, DCPcrypt2, DCPsha512, DCPblockciphers, DCPcast256, JPEG;
//
//type
//  CryptoException = Class(Exception);
//  TCrypto = class
//  private
//    Cipher: TDCP_cast256;
//    FPassword: String;
//    procedure SetPassword(const Value: String);
//  { Private declarations }
//  public
//  { Public declarations }
//    Constructor Create;
//    Destructor Destroy;
//    Property Password : String read FPassword write SetPassword;
//    Procedure Encrypt(Stream: TStream; OutFile : String);
//    Procedure Decrypt(Stream : TStream; InFile : String);
//  end;
//
//var
//  Crypto: TCrypto;
//
//// Quick Functions to load specific format data
//Function LoadJPGImage(FileName : String) : TJPEGImage;
//
//implementation
//
//{ TCrypto }
//
//procedure TCrypto.Decrypt(Stream: TStream; InFile: String);
//Var
//Source : TFileStream;
//begin
//// This is the key to decrypting the data stream
//// We load the encrypted data from a file and pass it through the
//// Decrypt function placing the data into an output stream
//// which would typically be a MemoryStream passed to the Procedure
//// that then passes it into a 'LoadFromStream' method of another
//// object.
//try
//Source := TFileStream.Create(InFile,fmOpenRead);
//Source.Seek(0,soFromBeginning);
//Cipher.InitStr(Password,TDCP_sha512); // initialize the cipher with a hash of the passphrase
//Cipher.DecryptStream(Source,Stream,Source.Size); // encrypt the contents of the file
//Stream.Seek(0,soFromBeginning);
//Cipher.Burn;
//Source.Free;
//except
//Raise CryptoException.CreateFmt('File ''%s'' not opened.',[InFile] );
//end;
//end;
//
//procedure TCrypto.Encrypt(Stream: TStream; OutFile: String);
//Var
//Dest : TFileStream;
//begin
//// The Encrypt function takes a stream, typically a MemoryStream that is
//// populated by a 'SaveToStream' method call of an object, and then
//// encrypted into a file on the disk.
//try
//Stream.Seek(0,soFromBeginning);
//Dest := TFileStream.Create(OutFile,fmCreate);
//Cipher.InitStr(Password,TDCP_sha512); // initialize the cipher with a hash of the passphrase
//Cipher.EncryptStream(Stream,Dest,Stream.Size); // encrypt the contents of the file
//Stream.Seek(0,soFromBeginning);
//Cipher.Burn;
//Dest.Free;
//except
//Raise CryptoException.CreateFmt('Cannot create file ''%s''.',[OutFile] );
//end;
//end;
//
//Constructor TCrypto.Create;
//begin
//// Initialize the objects
//// and set up the ultra secret password
//Inherited;
//Password := 'CairnsGames S.A. ultra secret image encrypting Password for GLXTreem.';
//Cipher:= TDCP_cast256.Create(Nil);
//end;
//
//procedure TCrypto.SetPassword(const Value: String);
//begin
//FPassword := Trim(Value);
//end;
//
//Function LoadJPGImage(FileName : String) : TJPEGImage;
//Var
//J : TJPEGImage;
//Stream : TMemoryStream;
//Begin
//Stream := TMemoryStream.Create;
//Crypto.Decrypt(Stream,FileName);
//Stream.Seek(0,soFromBeginning);
//J := TJPEGImage.Create;
//J.LoadFromStream(Stream);
//J.DIBNeeded;
//Result := J;
//Stream.Free;
//End;
//
//destructor TCrypto.Destroy;
//begin
//Cipher.Free;
//
//Inherited;
//end;
//
//Initialization
//Crypto := TCrypto.Create;
//
//Finalization
//Crypto.Free;
//
//end.
