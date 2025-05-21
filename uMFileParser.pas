unit uMFileParser;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Generics.Collections;

type
  TStringType = (stNSLog, stLiteral, stNSLocalizedString, stMethod, stAppLocalizedString);

  TMFileParsedString = class
    constructor Create(AStringType: TStringType; ASource: string);
  private
    FStringType: TStringType;
    FSource: string;
    FText: string;        // stLiteral, stNSLocalizedString, ssAppLocalizedString
    FComment: string;     // stNSLocalizedString
    FMethodName: string;  // stThesaurusMethod
  public
    property StringType: TStringType read FStringType;
    property Source: string read FSource;
    property Text: string read FText;
    property Comment: string read FComment;
    property MethodName: string read FMethodName;
  end;

  TMFileParsedStrings = TObjectList<TMFileParsedString>;

  TMFileParser = class
  public
    class function Parse(AFileName: string): TMFileParsedStrings;
  end;

implementation

{ TMFileParsedString }

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

constructor TMFileParsedString.Create(AStringType: TStringType; ASource: string);
var
  p: integer;
  s: string;
begin
  FStringType := AStringType;
  FSource := ASource;

  case AStringType of
    stLiteral:
    begin
      FSource := '@"' + ASource + '"';
      FText := ASource;
    end;
    stNSLocalizedString:
    begin
      p := 1;
      FText := ExtractObjcString(ASource, p);
      inc(p);
      FComment := ExtractObjcString(ASource, p);
    end;
    stAppLocalizedString:
    begin
      FSource := '@"' + ASource + '"';
      FText := ASource;
    end;
    stMethod:
    begin
      FSource := 'LocalizedStrings.' + ASource;
      FText := ASource;
    end;
  end;
end;

function GetStringType(AText: string; var Cursor: integer): TStringType;
const
  Token0 = 'NSLog(';
  Token1 = 'NSLocalizedString(';
  Token2 = 'String(';
  Token3 = 'LocalizedStrings.';
var
  s: string;
begin
  s := '';
  while Cursor <= Length(AText)  do
  begin
    if (AText[Cursor] = '@') and (AText[Cursor+1] = '"') then
    begin
      Exit(stLiteral);
    end;
    if AText[Cursor] in ['A'..'Z', 'a'..'z', '0'..'9', '.'] then
    begin
      s := s + AText[Cursor];
      if (s = Token0) then
      begin
        Inc(Cursor); // обязательно увеличиваем курсор на 1
        Exit(stNSLog);
      end else
      if (s = Token1) then
      begin
        Cursor := Cursor - Length(Token1);
        Inc(Cursor); // обязательно увеличиваем курсор на 1
        Exit(stNSLocalizedString);
      end else
      if s = Token2 then
      begin
        Cursor := Cursor - Length(Token2);
        Inc(Cursor); // обязательно увеличиваем курсор на 1
        Exit(stAppLocalizedString);
      end
      else
      if s = Token3 then
      begin
        Inc(Cursor); // обязательно увеличиваем курсор на 1
        Exit(stMethod)
      end;
    end
    else if AText[Cursor] = '(' then
    begin
      s := s + AText[Cursor];
      if (s = Token0) then
      begin
        Inc(Cursor); // обязательно увеличиваем курсор на 1
        Exit(stNSLog);
      end else if (s = Token1) then
      begin
        Cursor := Cursor - Length(Token1);
        Inc(Cursor); // обязательно увеличиваем курсор на 1
        Exit(stNSLocalizedString);
      end else if s = Token2 then
      begin
        Cursor := Cursor - Length(Token2);
        Inc(Cursor); // обязательно увеличиваем курсор на 1
        Exit(stAppLocalizedString);
      end;
      s := ''; // после скобки ( обнуляем строку
    end else
    begin
      s := '';
    end;

    Inc(Cursor);
  end;
end;

function ParseLiteral(AText: string; var Cursor: integer): string;
const
  StateNone = 0;
  StateString = 1;
  StateOpenSlash = 2;
var
  i: integer;
  str: string;
  state: integer;
begin
  Result := '';
  str := '';
  state := StateNone;
  for i := Cursor to Length(AText) do
  begin
    Cursor := i;
    case state of
      StateNone:
      begin
        if AText[i] = '"' then
          state := StateString
      end;
      StateString:
      begin
        if AText[i] = '"' then
          Exit(Str)
        else if AText[i] = '\' then
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
        state := StateString
      end;
    end;
  end;
end;

function ParseDKLocalizer(AText: string; var Cursor: integer): string;
var
  i: integer;
  s: string;
begin
  s := '';
  for i := Cursor to Length(AText) do
  begin
    Cursor := i + 1;
    if AText[i] in ['A'..'Z', 'a'..'z', '0'..'9', '_', '.'] then
      s := s + AText[i]
    else
      Exit(s);
  end;
end;

function ParseNSLocalizedString(AText: string; var Cursor: integer): string;
var
  i: integer;
begin
  Result := '';
  for i := Cursor to Length(AText) do
  begin
    Cursor := i + 1;
    if AText[i] = ')' then
    begin
      Result := Result + AText[i];
      Exit;
    end
    else
      Result := Result + AText[i]
  end;
end;

class function TMFileParser.Parse(AFileName: string): TMFileParsedStrings;
var
  StringList: TStringList;
  Text: string;
  Cursor: integer;
  st: TStringType;
  s: string;
begin
  Result := TMFileParsedStrings.Create;
  StringList := TStringList.Create;
  StringList.LoadFromFile(AFileName, TEncoding.UTF8);
  Text := StringList.Text;
  StringList.Free;
  Cursor := 1;
  st := GetStringType(Text, Cursor);
  while Cursor < Length(Text) do
  begin
    case st of
      stNSLog:
      begin
        // для NSLog просто парсим следующую строку и ничего с ней не делаем
        s := ParseLiteral(Text, Cursor);
      end;
      stLiteral:
      begin
        s := ParseLiteral(Text, Cursor);
        if s <> '' then
          Result.Add(TMFileParsedString.Create(st, s));
      end;
      stNSLocalizedString:
      begin
        s := ParseNSLocalizedString(Text, Cursor);
        if s <> '' then
          Result.Add(TMFileParsedString.Create(st, s));
      end;
      stMethod:
      begin
        s := ParseDKLocalizer(Text, Cursor);
        if s <> '' then
          Result.Add(TMFileParsedString.Create(st, s));
      end;
      stAppLocalizedString:
      begin
        s := ParseLiteral(Text, Cursor);
        if s <> '' then
          Result.Add(TMFileParsedString.Create(st, s));
      end;
    end;
    st := GetStringType(Text, Cursor);
  end;
end;

end.
