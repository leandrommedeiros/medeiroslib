{===============================================================================

                        REGISTRADOR DE COMPONENTES

============================================| Leandro Medeiros (12/03/2013) |==}

unit ComponentsRegister;

interface

procedure Register;

implementation

{ Bibliotecas }
uses
  {$IFNDEF VER150}
  Lib.AwsS3, Lib.JSON.Doc, Lib.JSON.Parser, Lib.JSON.TreeView, Lib.REST,
  Lib.REST.Study,
  {$ENDIF}
  Classes, LockApplication, Lib.DB, Lib.FTP, Lib.Utils.StreamFile;

//==| Função Registradora |=====================================================
procedure Register;
begin
  RegisterComponents('MedeirosLib', [{$IFNDEF VER150}
                                     TJSONDocument,
                                     TJSONParser,
                                     TJSONTreeView,
                                     TS3Connection,
                                     TRESTConnection,
                                     TRESTStudy,
                                     {$ENDIF}
                                     TLockApplication,
                                     TSQLConnectionM,
                                     TFTPConnection,
                                     TStreamFile]);
end;
//==============================================================================

end.
