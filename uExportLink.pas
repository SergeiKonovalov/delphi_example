unit uExportLink;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Generics.Collections, comObj;

type
  TKeyValuePair = TDictionary<string, string>;

  TExportLink = class
    constructor Create;
    destructor Destroy; override;
  private
    FUID: string;                                                               // GUID
    FName: string;                                                              // unique method name
    FValues: TKeyValuePair;                                                     // language, string value
    FNSLocalizedStringKey: string;                                              //
    FIsImported: Boolean;                                                       //
  public
    property UID: string read FUID;
    property Name: string read FName write FName;
    property NSLocalizedStringKey: string read FNSLocalizedStringKey write FNSLocalizedStringKey;
    property Values: TKeyValuePair read FValues;
    property IsImported: boolean read FIsImported write FIsImported;
  end;

  TExportLinks = class
    constructor Create;
    destructor Destroy; override;
  private
    FExportLinks: TObjectList<TExportLink>;
  private
    function FindExportLinkWithStringLiteral(ALanguage, AString: string): TExportLink;
    function FindExportLinkWithNSLocalizedStringKey(AKey: string): TExportLink;
    function FindExportLinkWithLinkName(AName: string): TExportLink;
  public
    function AddStringLiteral(ALanguage, ALiteral: string): TExportLink;
    function AddNSLocalizedString(AKey, AComment: string): TExportLink;
    function AddAppLocalizedString(AKey: string): TExportLink;

    procedure ImportExportLink(AName: string; AValues: TKeyValuePair; ANSLocalizedStringKey: string);
    function ImportExportedLink(AName: string): TExportLink;
    function FindWithUID(AUID: string): TExportLink;
    function CheckName(ANewName, ACurrentName: string): boolean;
    property Items: TObjectList<TExportLink> read FExportLinks;
  end;

implementation

{ TThesaurusString }

constructor TExportLink.Create;
var
  Guid: TGUID;
begin
  FValues := TKeyValuePair.Create;
  CreateGUID(Guid);
  FUID := Guid.ToString;
  FIsImported := false;
end;

destructor TExportLink.Destroy;
begin
  FValues.Free;
  inherited;
end;

{ TThesaurus }

constructor TExportLinks.Create;
begin
  FExportLinks := TObjectList<TExportLink>.Create;
end;

destructor TExportLinks.Destroy;
begin
  FExportLinks.Free;
  inherited;
end;

function TExportLinks.FindExportLinkWithNSLocalizedStringKey(AKey: string): TExportLink;
var
  ThesaurusString: TExportLink;
begin
  Result := nil;
  for ThesaurusString in FExportLinks do
    if ThesaurusString.NSLocalizedStringKey = AKey then
      Exit(ThesaurusString)
end;

function TExportLinks.FindExportLinkWithLinkName(AName: string): TExportLink;
var
  ThesaurusString: TExportLink;
begin
  Result := nil;
  for ThesaurusString in FExportLinks do
    if ThesaurusString.Name = AName then
      Exit(ThesaurusString)
end;

function TExportLinks.FindExportLinkWithStringLiteral(ALanguage, AString: string): TExportLink;
var
  ExportLink: TExportLink;
begin
  if AString = '' then Exit(Nil);

  Result := nil;
  for ExportLink in FExportLinks do
    if ExportLink.Values.ContainsKey(ALanguage) then
      if ExportLink.Values[ALanguage] = AString then
        Exit(ExportLink);
end;

// Добавление строки из файла *.m
// Эта же строка уже может быть добавлена ранее (например, в другом исходном файла)
function TExportLinks.AddStringLiteral(ALanguage, ALiteral: string): TExportLink;
begin
  Result := FindExportLinkWithStringLiteral(ALanguage, ALiteral);

  if (Result = nil) then
  begin
    Result := TExportLink.Create;
    FExportLinks.Add(Result);
    if (ALanguage <> '') then
      Result.Values.Add(ALanguage, ALiteral);
  end;
end;

// Добавление NSLocalizedString() из файла *.m
function TExportLinks.AddNSLocalizedString(AKey, AComment: string): TExportLink;
begin
  Result := FindExportLinkWithNSLocalizedStringKey(AKey);
  if (Result = nil) then
  begin
    Result := TExportLink.Create;
    Result.NSLocalizedStringKey := AKey;
    FExportLinks.Add(Result);
  end;
end;

function TExportLinks.AddAppLocalizedString(AKey: string): TExportLink;
begin
  Result := FindExportLinkWithNSLocalizedStringKey(AKey);
  if (Result = nil) then
  begin
    Result := TExportLink.Create;
    Result.NSLocalizedStringKey := AKey;
    FExportLinks.Add(Result);
  end;
end;

// Добавление вызова метода файла *.m (уже обработанного локалайзером ранее)
function TExportLinks.ImportExportedLink(AName: string): TExportLink;
begin
  Result := FindExportLinkWithLinkName(AName);
  if (Result = nil) then
  begin
    Result := TExportLink.Create;
    FExportLinks.Add(Result);
  end;
  Result.Name := AName;
  Result.IsImported := true;
end;

procedure TExportLinks.ImportExportLink(AName: string; AValues: TKeyValuePair;
  ANSLocalizedStringKey: string);
var
  NewLink: TExportLink;
  Key: string;
begin
  NewLink := TExportLink.Create;
  FExportLinks.Add(NewLink);
  NewLink.Name := AName;
  NewLink.NSLocalizedStringKey := ANSLocalizedStringKey;
  for Key in AValues.Keys do
    NewLink.Values.Add(Key, AValues[Key]);
  NewLink.IsImported := true;
end;

function TExportLinks.FindWithUID(AUID: string): TExportLink;
var
  ThesaurusString: TExportLink;
begin
  Result := nil;
  for ThesaurusString in FExportLinks do
      if ThesaurusString.UID = AUID then
        Exit(ThesaurusString);
end;

function TExportLinks.CheckName(ANewName, ACurrentName: string): boolean;
const
  ReservedSize = 4;
  Reserved: array[1..ReservedSize] of string = ('continue', 'delete', 'languageCode', 'supportedLanguages');
var
  i, j: integer;
  a: TExportLink;
begin
  Result := true;
  if (FExportLinks.Count < 2) or (ANewName = '') then
    Exit;

  // проверка на зарезервированные слова
  for i := 1 to ReservedSize do
    if ANewName = Reserved[i] then
      Exit(false);

  for i := 0 to FExportLinks.Count - 1 do
  begin
    a := FExportLinks[i];
    if a.Name = ACurrentName then continue;

    if a.Name = '' then continue;
      if LowerCase(a.Name) = LowerCase(ANewName) then
        Exit(false);
  end;
end;

end.
