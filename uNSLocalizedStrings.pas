unit uNSLocalizedStrings;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Generics.Collections, comObj;

type
  TNSLocalizedString = class
    constructor Create(AKey: string);
    destructor Destroy; override;
  private
    FUID: string;
    FKey: string;
    FValues: TDictionary<string,string>; // language code, value
    FHasDublicatedValues: boolean;
  public
    property UID: string read FUID;
    property Key: string read FKey;
    property Values: TDictionary<string,string> read FValues;
    property HasDublicatedValues: boolean read FHasDublicatedValues write FHasDublicatedValues;
  end;

  TNSLocalizedStrings = class
    constructor Create;
    destructor Destroy; override;
  private
    FItems: TObjectList<TNSLocalizedString>;
    FLanguages: TStringList;
  public
    procedure Add(AKey, AValue, ALanguage: string); overload;
    function FindWithKey(AKey: string): TNSLocalizedString;
    function FindWithUID(AUID: string): TNSLocalizedString;
    property Items: TObjectList<TNSLocalizedString> read FItems;
    property Languages: TStringList read FLanguages;
  end;

implementation

{ TNSLocalizedString }

constructor TNSLocalizedString.Create(AKey: string);
var
  GUID: TGUID;
begin
  CreateGUID(GUID);
  FUID := GUIDToString(GUID);
  FValues := TDictionary<string,string>.Create;
  FKey := AKey;
  FHasDublicatedValues := false;
end;

destructor TNSLocalizedString.Destroy;
begin
  FValues.Free;
  inherited;
end;

{ TNSLocalizedStrings }

constructor TNSLocalizedStrings.Create;
begin
  FItems := TObjectList<TNSLocalizedString>.Create;
end;

destructor TNSLocalizedStrings.Destroy;
begin
  FItems.Free;
  inherited;
end;

function TNSLocalizedStrings.FindWithKey(AKey: string): TNSLocalizedString;
var
  NSLocalizedString: TNSLocalizedString;
begin
  Result := nil;
  for NSLocalizedString in FItems do
    if NSLocalizedString.Key = AKey then
      Exit(NSLocalizedString);
end;

procedure TNSLocalizedStrings.Add(AKey, AValue, ALanguage: string);
var
  NSLocalizedString: TNSLocalizedString;
begin
  if AKey = '' then
    Exit;

  NSLocalizedString := FindWithKey(AKey);

  if (NSLocalizedString = nil) then
  begin
    NSLocalizedString := TNSLocalizedString.Create(AKey);
    FItems.Add(NSLocalizedString);
  end;

  if not NSLocalizedString.Values.ContainsKey(ALanguage) then
    NSLocalizedString.Values.Add(ALanguage, AValue)
  else
    NSLocalizedString.HasDublicatedValues := true;
end;

function TNSLocalizedStrings.FindWithUID(AUID: string): TNSLocalizedString;
var
  NSLocalizedString: TNSLocalizedString;
begin
  Result := nil;
  for NSLocalizedString in FItems do
    if NSLocalizedString.UID = AUID then
      Exit(NSLocalizedString);
end;

end.
