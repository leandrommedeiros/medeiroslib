{===============================================================================

                         DI�LOGO - LISTA DE DIRET�RIOS

============================================| Leandro Medeiros (20/10/2011) |==}

unit Lib.Utils.BrowseFolder;

interface

function BrowseForFolder(const BrowseTitle: String;
  const InitialFolder: String = ''; ShowNewFolderBtn: Boolean = True): String;

implementation

uses
  Windows, Forms, shlobj;

// VARI�VEIS
var
  lg_StartFolder: String;

// CONSTANTES
const
  BIF_NEWDIALOGSTYLE    =$40;
  BIF_NONEWFOLDERBUTTON =$200;

function BrowseForFolderCallBack(Wnd: HWND; uMsg: UINT; lParam,
  lpData: LPARAM): Integer stdcall;
begin
  if uMsg = BFFM_INITIALIZED then
    SendMessage(Wnd,BFFM_SETSELECTION, 1, Integer(@lg_StartFolder[1]));
  result := 0;
end;

{==| Fun��o - Navegar Pelo Diret�rio |==========================================
  Esta fun��o exibe uma caixa de di�logo para escolha de um diret�rio.
  Par�metros de Entrada:
    1. T�tulo do Navegador      > String
    2. Diret�rio Inicial        > String (OPCIONAL)
    3. Bot�o "Criar Nova Pasta" > Boolean (OPCIONAL - Padr�o: Verdadeiro)
  Retorno:
    1. Diret�rio Selecionado    > String
============================================| Leandro Medeiros (22/05/2009) |==}
function BrowseForFolder(const BrowseTitle: String;
  const InitialFolder: String = ''; ShowNewFolderBtn: Boolean = True): String;
var
  browse_info  : TBrowseInfo;
  folder       : array[0..MAX_PATH] of char;
  find_context : PItemIDList;
begin
  FillChar(browse_info, SizeOf(browse_info), #0);
  lg_StartFolder             := initialFolder;
  browse_info.pszDisplayName := @folder[0];
  browse_info.lpszTitle      := PChar(browseTitle);
  browse_info.ulFlags        := BIF_RETURNONLYFSDIRS or BIF_NEWDIALOGSTYLE;

  if not ShowNewFolderBtn then
    browse_info.ulFlags := browse_info.ulFlags or BIF_NONEWFOLDERBUTTON;
  browse_info.hwndOwner := Application.Handle;

  if initialFolder <> '' then
    browse_info.lpfn := BrowseForFolderCallBack;
  find_context       := SHBrowseForFolder(browse_info);

  if Assigned(find_context) then
  begin
    if SHGetPathFromIDList(find_context, folder) then
      Result := Folder
    else
      Result := initialFolder;

    GlobalFreePtr(find_context);
  end
  else Result := initialFolder;
end;
//==============================================================================

end.
