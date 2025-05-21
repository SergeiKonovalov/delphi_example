unit uAppLocalizedStrings;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Generics.Collections, uSourceString;

type
  // Язык
  TLanguage = class
    constructor Create;
  private
    FUID: string;                                                               // внутренний идентификатор
    FCode: string;
    FName: string;
    FEnglishName: string;
    FPrimary: Boolean;
  public
    procedure Add(AKey, AValue: string);
  public
    property UID: string read FUID;
    property Code: string read FCode write FCode;
    property Name: string read FName write FName;
    property EnglishName: string read FEnglishName write FEnglishName;
    property Primary: Boolean read FPrimary write FPrimary;
  end;

  TLanguages = class
    constructor Create;
  private
    FItems: TObjectList<TLanguage>;
  public
    procedure Add(ALanguage: TLanguage);
    function FindWithCode(ACode: string): TLanguage;
    function FindWithUID(AUID: string): TLanguage;
    function Primary: TLanguage;
  public
    property Items: TObjectList<TLanguage> read FItems;
  end;

  // Строка
  TAppLocalizedString = class
    constructor Create(AKey: string);
    destructor Destroy; override;
  private
    FUID: string;                                                               // внутренний идентификатор
    FKey: string;                                                               // ключ
    FOldKey: string;                                                            // предыдущее наименование ключа (если он был переименован)
    FDictionary: TDictionary<string,string>;                                    // <language code, string value>
    FSourceString: TSourceString;                                               // связь со объектом исходного кода
  public
    procedure Add(ALanguageCode, AString: string);
    procedure RenameKey(AKey: string);
    function IsKeyRenamed: Boolean;
  public
    property UID: string read FUID;
    property Key: string read FKey;
    property OldKey: string read FOldKey;
    property LocalizedStrings: TDictionary<string,string> read FDictionary;
    property SourceString: TSourceString read FSourceString write FSourceString;
  end;

  // Все, что касается локализации: языки, строки и т.д.
  TAppLocalizedStrings = class
    constructor Create;
    destructor Destroy; override;
  private
    FLanguages: TLanguages;
    FItems: TObjectList<TAppLocalizedString>;
    FName: string;                                                              // имя класса
  public
    function FindWithUID(AUID: string): TAppLocalizedString;
    function FindWithKey(AKey: string): TAppLocalizedString;
    function CheckKey(AKey: string; ASourceUID: string): Boolean;               // проверка наличия строки с ключем (за исключением строки с ASourceUID)
    function AddSourceString(ASourceString: TSourceString): TAppLocalizedString; // для добавления ASourceString в локализацию
    procedure RemoveItemWithSourceString(ASourceString: TSourceString);         // для удаления ASourceString из локализации
  public
    property Languages: TLanguages read FLanguages;
    property Items: TObjectList<TAppLocalizedString> read FItems;
    property Name: string read FName write FName;
  end;

  // Парсер файла AppLocalizedStrings
  TAppLocalizedStringsFileParser = class
  private
    class procedure ParseClassName(AAppLocalizedStrings: TAppLocalizedStrings; AText: string);
    class procedure ParseSupportedLanguages(AAppLocalizedStrings: TAppLocalizedStrings; AText: string);
    class procedure ParseDefaultLanguage(AAppLocalizedStrings: TAppLocalizedStrings; AText: string);
    class procedure ParseLocalizedStrings(AAppLocalizedStrings: TAppLocalizedStrings; AText: string);
  public
    class function Parse(AFileName: string): TAppLocalizedStrings;
  end;

implementation

{ TLanguage }

constructor TLanguage.Create;
var
  GUID : TGUID;
begin
  CreateGUID(GUID);
  FUID := GUID.ToString;
end;

procedure TLanguage.Add(AKey, AValue: string);
begin
  if AKey = 'code' then
    Code := AValue
  else if AKey = 'name' then
    Name := AValue
  else if AKey = 'englishName' then
    EnglishName := AValue
end;

{ TLanguages }

constructor TLanguages.Create;
begin
  FItems := TObjectList<TLanguage>.Create;
end;

procedure TLanguages.Add(ALanguage: TLanguage);
var
  Item: TLanguage;
begin
  if ALanguage.Primary then
  begin
    for Item in FItems do
      Item.Primary := False;
  end;
  FItems.Add(ALanguage);
end;

function TLanguages.FindWithCode(ACode: string): TLanguage;
var
  Item: TLanguage;
begin
  Result := nil;
  for Item in FItems do
    if (Item.Code = ACode) then
      Exit(Item);
end;

function TLanguages.FindWithUID(AUID: string): TLanguage;
var
  Item: TLanguage;
begin
  Result := nil;
  for Item in FItems do
    if (Item.UID = AUID) then
      Exit(Item);
end;

function TLanguages.Primary: TLanguage;
var
  Item: TLanguage;
begin
  Result := nil;
  for Item in FItems do
    if (Item.Primary) then
      Exit(Item);
end;

{ TAppLocalizedString }

constructor TAppLocalizedString.Create(AKey: string);
var
  GUID : TGUID;
begin
  CreateGUID(GUID);
  FUID := GUID.ToString;
  FDictionary := TDictionary<string,string>.Create;
  FKey := AKey;
  FOldKey := '';
end;

destructor TAppLocalizedString.Destroy;
begin
  FDictionary.Free;
  inherited;
end;

function TAppLocalizedString.IsKeyRenamed: Boolean;
begin
  Result := (OldKey <> '') and (OldKey <> Key)
end;

procedure TAppLocalizedString.RenameKey(AKey: string);
begin
  FOldKey := FKey;
  FKey := AKey;
end;

procedure TAppLocalizedString.Add(ALanguageCode, AString: string);
begin
  if not FDictionary.ContainsKey(ALanguageCode) then
    FDictionary.Add(ALanguageCode, AString);
end;

{ TAppLocalizedStrings }

constructor TAppLocalizedStrings.Create;
begin
  FLanguages := TLanguages.Create;
  FItems := TObjectList<TAppLocalizedString>.Create;
end;

destructor TAppLocalizedStrings.Destroy;
begin
//  FLanguages.Free;  // почему-то вызывается exception!
  FItems.Free;
  inherited;
end;

function TAppLocalizedStrings.FindWithUID(AUID: string): TAppLocalizedString;
var
  Item: TAppLocalizedString;
begin
  Result := nil;
  for Item in Items do
    if (Item.UID = AUID) then
      Exit(Item);
end;

function TAppLocalizedStrings.FindWithKey(AKey: string): TAppLocalizedString;
var
  Item: TAppLocalizedString;
begin
  Result := nil;
  for Item in Items do
    if (Item.Key = AKey) then
      Exit(Item);
end;

function TAppLocalizedStrings.AddSourceString(ASourceString: TSourceString): TAppLocalizedString;
begin
  Result := FindWithKey(ASourceString.Text); // Text для каждого ASourceString уникален, поэтому используется в качестве ключа
  if Result = nil then
  begin
    Result := TAppLocalizedString.Create(ASourceString.Text);
    Items.Add(Result);
  end;
  Result.SourceString := ASourceString; // связь между TAppLocalizedString и TAppLocalizedString всегда 1 к 1
end;

procedure TAppLocalizedStrings.RemoveItemWithSourceString(ASourceString: TSourceString);
var
  Item: TAppLocalizedString;
begin
  Item := nil;
  for Item in Items do
    if Item.SourceString = ASourceString then
      Break;
  if Assigned(Item) then
    Items.Remove(Item);
end;

function TAppLocalizedStrings.CheckKey(AKey, ASourceUID: string): Boolean;
var
  Item: TAppLocalizedString;
begin
  Result := False;
  for Item in Items do
    if (Item.UID <> ASourceUID) and (Item.Key = AKey) then
      Exit(True);
end;

{ TThesaurusFileParser }

class function TAppLocalizedStringsFileParser.Parse(AFileName: string): TAppLocalizedStrings;
var
  StringList: TStringList;
begin
  try
    Result := TAppLocalizedStrings.Create;
    StringList := TStringList.Create;
    StringList.LoadFromFile(AFileName, TEncoding.UTF8);
    ParseClassName(Result, StringList.Text);
    ParseSupportedLanguages(Result, StringList.Text);
    ParseDefaultLanguage(Result, StringList.Text);
    ParseLocalizedStrings(Result, StringList.Text);
  finally
    StringList.Free;
  end;
end;

function ExtractObjcString(AText: string; var APosition: integer): string;
const
  StateNone = 0;
  StateString = 1;
  StateSlash = 2;
var
  state: integer;
  str: string;
begin
  str := '';
  state := StateNone;
  while APosition <= Length(AText) do
  begin
    case state of
      StateNone:
      begin
        if (AText[APosition] = '"') then
        begin
          state := StateString;
        end;
      end;
      StateString:
      begin
        if AText[APosition] = '"' then
        begin
          Exit(str);
        end
        else if AText[APosition] = '\' then
        begin
          str := str + AText[APosition];
          state := StateSlash;
        end else
        begin
          str := str + AText[APosition];
        end;
      end;
      StateSlash:
      begin
        str := str + AText[APosition];
        state := StateString
      end;
    end;
    inc(APosition);
  end;
end;

class procedure TAppLocalizedStringsFileParser.ParseSupportedLanguages(AAppLocalizedStrings: TAppLocalizedStrings; AText: string);
const
  Template = '_supportedLanguages';
  StateNone = 0;
  StateArray = 1;
  StateObject = 2;
  StateDictionary = 3;
  StateDictionaryKey = 4;
  StateDictionaryValue = 5;
var
  c: Integer;
  State: Byte;
  Language: TLanguage;
  Key, Value: string;
begin
  c := Pos(Template, AText);
  if (c < 1) then Exit;

  State := StateNone;
  while c <= Length(AText) do
  begin
    inc(c);
    case State of
      StateNone:
      begin
        if (AText[c] = '@') and (AText[c+1] = '[') then
        begin
          State := StateArray;
          inc(c);
        end;
      end;
      StateArray:
      begin
        if (AText[c] = '[') then
        begin
          State := StateObject;
        end
        else if (AText[c]) = ']' then
        begin
          State := StateNone;
          Exit;  // конец массива _supportedLanguages
        end;
      end;
      StateObject:
      begin
        if (AText[c] = '@') and (AText[c+1] = '{') then
        begin
          State := StateDictionary;
          Language := TLanguage.Create;
          inc(c);
        end
        else if (AText[c]) = ']' then
        begin
          State := StateArray;
        end;
      end;
      StateDictionary:
      begin
        if (AText[c] = '@') and (AText[c+1] = '"') then
        begin
          State := StateDictionaryKey
        end else if (AText[c]) = '}' then
        begin
          AAppLocalizedStrings.Languages.Add(Language);
          State := StateObject;
        end;
      end;
      StateDictionaryKey:
      begin
        Key := ExtractObjcString(AText, c);
        State := StateDictionaryValue;
      end;
      StateDictionaryValue:
      begin
        Value := ExtractObjcString(AText, c);
        Language.Add(Key, Value);
        State := StateDictionary;
      end;
    end;
  end;
end;

class procedure TAppLocalizedStringsFileParser.ParseClassName(AAppLocalizedStrings: TAppLocalizedStrings; AText: string);
const
  kTemplate = '@implementation';
  kStateNone = 0;
  kStateText = 1;
var
  s: string;
  Cursor: Integer;
  State: Integer;
begin
  Cursor := Pos(kTemplate, AText);
  if Cursor < 1 then
    Exit;

  State := kStateNone;
  Cursor := Cursor + Length(kTemplate);
  while Cursor <= Length(AText)  do
  begin
    case State of
      kStateNone:
      begin
        if AText[Cursor] in ['A'..'Z', 'a'..'z', '0'..'9', '_'] then
        begin
          State := kStateText;
          s := AText[Cursor];
        end;
      end;
      kStateText:
      begin
        if AText[Cursor] in ['A'..'Z', 'a'..'z', '0'..'9', '_'] then
        begin
          s := s + AText[Cursor];
        end else
        begin
          AAppLocalizedStrings.Name := s;
          Exit;
        end;
      end;
    end;
    Inc(Cursor);
  end;
end;

class procedure TAppLocalizedStringsFileParser.ParseDefaultLanguage(
  AAppLocalizedStrings: TAppLocalizedStrings; AText: string);
const
  Template = 'self.languageCode';
var
  c: Integer;
  Code: string;
  Language: TLanguage;
begin
  c := Pos(Template, AText);
  if (c < 1) then
    Exit;

  Code := ExtractObjcString(AText, c);
  if (Code = '') then
    Exit;

  Language := AAppLocalizedStrings.Languages.FindWithCode(Code);
  if Language <> nil then
    Language.Primary := True;
end;

class procedure TAppLocalizedStringsFileParser.ParseLocalizedStrings(AAppLocalizedStrings: TAppLocalizedStrings; AText: string);
const
  Template = 'self.strings[@"';
  StateNone = 0;
  StateKey = 1;
  StateDictionary = 2;
  StateDictionaryKey = 3;
  StateDictionaryValue = 4;
var
  c: Integer;
  State: Byte;
  Key, Value: string;
  AppLocalizedString: TAppLocalizedString;
begin
  c := Pos(Template, AText);
  if (c < 1) then Exit;

  State := StateNone;
  while c <= Length(AText) do
  begin
    inc(c);
    case State of
      StateNone:
      begin
        if (AText[c] = '@') and (AText[c+1] = '"') then
        begin
          State := StateKey;
          Key := ExtractObjcString(AText, c);
          AppLocalizedString := TAppLocalizedString.Create(Key);
        end else if (AText[c] = '}') then
        begin
          break;
        end;
      end;
      StateKey:
      begin
        if (AText[c] = '@') and (AText[c+1] = '{') then
        begin
          State := StateDictionary;
          inc(c);
        end
      end;
      StateDictionary:
      begin
        if (AText[c] = '@') and (AText[c+1] = '"') then
        begin
          State := StateDictionaryKey
        end else if (AText[c]) = '}' then
        begin
          AAppLocalizedStrings.Items.Add(AppLocalizedString);
          State := StateNone;
        end;
      end;
      StateDictionaryKey:
      begin
        Key := ExtractObjcString(AText, c);
        State := StateDictionaryValue;
      end;
      StateDictionaryValue:
      begin
        Value := ExtractObjcString(AText, c);
        AppLocalizedString.Add(Key, Value);
        State := StateDictionary;
      end;
    end;
  end;
end;

end.
