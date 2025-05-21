unit uobjcLocalizedStringsFileParser;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Generics.Collections;

type
  TobjcLocalizedString = class
    constructor Create;
    destructor Destroy; override;
  private
    FName: string;
    FNSLocalizedStringKey: string;
    FDictionary: TDictionary<string,string>; // language code, string value
  public
    procedure Add(AKey, AValue: string);
    property Name: string read FName;
    property NSLocalizedStringKey: string read FNSLocalizedStringKey;
    property LocalizedStrings: TDictionary<string,string> read FDictionary;
  end;

  TobjcLocalizedStrings = TObjectList<TobjcLocalizedString>;

  TobjLocalizedStringsFileParser = class
  private
    class procedure ParseText(AList: TobjcLocalizedStrings; AText: string);
  public
    class function Parse(AFileName: string): TobjcLocalizedStrings;
  end;

implementation

{ TDTO }

constructor TobjcLocalizedString.Create;
begin
  FDictionary := TDictionary<string,string>.Create;
  FName := '';
end;

destructor TobjcLocalizedString.Destroy;
begin
  FDictionary.Free;
  inherited;
end;

procedure TobjcLocalizedString.Add(AKey, AValue: string);
begin
  if AKey = 'name' then
    FName := AValue
  else if AKey = 'NSLocalizedStringKey' then
    FNSLocalizedStringKey := AValue
  else if not FDictionary.ContainsKey(AKey) then
    FDictionary.Add(AKey, AValue);
end;

{ TThesaurusFileParser }

class function TobjLocalizedStringsFileParser.Parse(AFileName: string): TobjcLocalizedStrings;
var
  StringList: TStringList;
begin
  try
    Result := TobjcLocalizedStrings.Create;
    StringList := TStringList.Create;
    StringList.LoadFromFile(AFileName, TEncoding.UTF8);
    ParseText(Result, StringList.Text);
  finally
    StringList.Free;
  end;
end;

function ExtractObjcString(AText: string; APosition: integer; var AOutput: string): integer;
const
  StateInit = 0;
  StateSobaka = 1;
  StateOpen = 2;
  StateOpenSlash = 3;
  StateClose = 4;
var
  Temp: TStringList;
  i: integer;
  str: string;
  state: integer;
begin
  AOutput := '';
  Result := 0;
  str := '';
  state := StateInit;
  for i := APosition to Length(AText) do
  begin
    case state of
      StateInit:
        begin
          if AText[i] = '@' then
            state := StateSobaka;
        end;
      StateSobaka:
        begin
          if (AText[i] in [#9,#10,#13,#32]) then
            continue;

          if AText[i] = '"' then
            state := StateOpen
          else
            state := StateInit;
        end;
      StateOpen:
        begin
          if AText[i] = '"' then
            state := StateClose
          else
            if AText[i] = '\' then
            begin
              str := str + AText[i];
              state := StateOpenSlash;
            end
          else
          begin
            str := str + AText[i];
          end;
        end;
      StateOpenSlash:
        begin
          str := str + AText[i];
          state := StateOpen
        end;
      StateClose:
        begin
          if str <> '' then
            AOutput := str;
          Result := i;
          break;
        end;
    end;
  end;
end;

class procedure TobjLocalizedStringsFileParser.ParseText(AList: TobjcLocalizedStrings; AText: string);
const
  OuterDictionary = 1;
  InDictionary = 2;
  InString = 3;
var
  c, tmp: integer;
  State: byte;
  Item: TobjcLocalizedString;
  FirstStringIsKey: boolean;
  Key, Str: string;
begin
  State := OuterDictionary;
  c := 0;
  while c <= Length(AText) do
  begin
    inc(c);
    case State of
      OuterDictionary:
      begin
        if (AText[c] = '@') and (AText[c+1] = '{') then
        begin
          State := InDictionary;
          FirstStringIsKey := true;
          Item := TobjcLocalizedString.Create;
        end;
      end;
      InDictionary:
      begin
        if (AText[c] = '@') and (AText[c+1] = '"') then
          State := InString
        else if (AText[c]) = '}' then
        begin
          State := OuterDictionary;
          // не добавляем с пустым Name (словарь, который парсим в исходном коде, обязательно должен содержать ключ "name", иначе этот словарь к нам не относится)
          if Item.Name <> '' then
            AList.Add(Item);
        end;
      end;
      InString:
      begin
        Str := '';
        tmp := ExtractObjcString(AText, c-1, Str);
        if tmp <> 0 then
        begin
          c := tmp;
          State := InDictionary;
          if FirstStringIsKey then
            Key := Str
          else
            Item.Add(Key, Str);
          FirstStringIsKey := not FirstStringIsKey;
        end;
        State := InDictionary;
      end;
    end;
  end;
end;

end.
