unit Lib.MLLabel;

interface

uses
  SysUtils, Classes, Controls, StdCtrls;

type
  TLabelMOnCaptionChange = procedure(Sender: TObject; var ANewCaption: TCaption) of object;

  TMLLabel = class(TLabel)
  private
    { Private declarations }
    FLinkStyle : Boolean;

    procedure SetLinkStyle(const ALinkStyle: Boolean);
    procedure MLLabelMouseEnter(Sender: TObject);
    procedure MLLabelMouseLeave(Sender: TObject);
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
    property LinkStyle       : Boolean                read FLinkStyle       write SetLinkStyle default False;
  end;

implementation

uses
  Graphics;

function TMLLabel.GetCaption: TCaption;
begin
  Result := inherited Caption;
end;

procedure TMLLabel.SetCaption(ANewCaption: TCaption);
begin
  if Assigned(Self.FOnCaptionChange) then
    Self.FOnCaptionChange(Self, ANewCaption);

  inherited Caption := ANewCaption;
end;

procedure TMLLabel.SetLinkStyle(const ALinkStyle: Boolean);
begin
  Self.FLinkStyle := ALinkStyle;

  if Self.FLinkStyle then
  begin
    Self.Font.Color   := clBlue;
    Self.OnMouseEnter := MLLabelMouseEnter;
    Self.OnMouseLeave := MLLabelMouseLeave;
    Self.Cursor       := crHandPoint;
  end

  else begin
    Self.Font.Color   := clBlack;
    Self.OnMouseEnter := nil;
    Self.OnMouseLeave := nil;
    Self.Cursor       := crDefault;
  end;
end;

procedure TMLLabel.MLLabelMouseEnter(Sender: TObject);
begin
  with TMLLabel(Sender) do
  begin
    Font.Size  := Font.Size + 1;
    Font.Style := [fsUnderline];
    Left       := Left - 4;
    Top        := Top - 2;
  end;
end;

procedure TMLLabel.MLLabelMouseLeave(Sender: TObject);
begin
  with TMLLabel(Sender) do
  begin
    Font.Size  := Font.Size - 1;
    Font.Style := [];
    Left       := Left + 4;
    Top        := Top + 2;
  end;
end;

end.
