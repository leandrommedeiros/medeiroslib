unit Lib.LabelM;

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.StdCtrls;

type
  TLabelMOnCaptionChange = procedure(ASender: TObject; var ANewCaption: TCaption) of object;

  TLabelM = class(TLabel)
  private
    { Private declarations }
  protected
    { Protected declarations }
    FOnCaptionChange: TLabelMOnCaptionChange;
    procedure SetCaption(ANewCaption: TCaption);
    function  GetCaption: TCaption;
  public
    { Public declarations }
  published
    { Published declarations }
    property Caption         : TCaption               read GetCaption       write SetCaption;
    property OnCaptionChange : TLabelMOnCaptionChange read FOnCaptionChange write FOnCaptionChange;
  end;

implementation

function TLabelM.GetCaption: TCaption;
begin
  Result := inherited Caption;
end;

procedure TLabelM.SetCaption(ANewCaption: TCaption);
begin
  if Assigned(Self.FOnCaptionChange) then
    Self.FOnCaptionChange(Self, ANewCaption);

  inherited Caption := ANewCaption;
end;

end.
