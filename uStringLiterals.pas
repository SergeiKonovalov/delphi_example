unit uStringLiterals;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Generics.Collections, comObj;

type
  TStringLiteral = class
    constructor Create(AValue: string);
  private
    FUID: string;
    FValue: string;
  public
    property UID: string read FUID;
    property Value: string read FValue write FValue;
  end;

  TStringLiterals = class
    constructor Create;
    destructor Destroy; override;
  private
    FItems: TObjectList<TStringLiteral>;
    function Find(AString: string): TStringLiteral;
  public
    procedure Add(AString: string);
    property Items: TObjectList<TStringLiteral> read FItems;
  end;

implementation

{ TStringLiterals }

constructor TStringLiterals.Create;
begin
  FItems := TObjectList<TStringLiteral>.Create;
end;

destructor TStringLiterals.Destroy;
begin
  FItems.Free;
  inherited;
end;

function TStringLiterals.Find(AString: string): TStringLiteral;
var
  StringLiteral: TStringLiteral;
begin
  Result := nil;
  for StringLiteral in FItems do
    if (StringLiteral.Value = AString) then
      Exit(StringLiteral);
end;

procedure TStringLiterals.Add(AString: string);
begin
  if Find(AString) = nil then
    FItems.Add(TStringLiteral.Create(AString));
end;

{ TStringLiteral }

constructor TStringLiteral.Create(AValue: string);
var
  GUID: TGUID;
begin
  CreateGUID(GUID);
  FUID := GUIDToString(GUID);
  FValue := AValue;
end;

end.
