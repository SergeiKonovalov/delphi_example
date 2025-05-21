unit uLocalizableStringsFileParser;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Generics.Collections;

type
  TLocalizableStringsFileParserDTO = class
    constructor Create(AKey, AValue: string);
  private
    FKey: string;
    FValue: string;
  public
    property Key: string read FKey;
    property Value: string read FValue;
  end;

  TLocalizableStringsFileParserDTOList = TObjectList<TLocalizableStringsFileParserDTO>;

  TLocalizableStringsFileParser = class
  private
    class procedure ParseText(AList: TLocalizableStringsFileParserDTOList; AText: string);
  public
    class function Parse(AFileName: string): TLocalizableStringsFileParserDTOList;
  end;

implementation

{ TLocalizableStringsFileParserDTO }

constructor TLocalizableStringsFileParserDTO.Create(AKey, AValue: string);
begin
  FKey := AKey;
  FValue := AValue;
end;

{ TLocalizableStringsFileParser }

class function TLocalizableStringsFileParser.Parse(AFileName: string): TLocalizableStringsFileParserDTOList;
var
  StringList: TStringList;
begin
  try
    Result := TLocalizableStringsFileParserDTOList.Create;
    StringList := TStringList.Create;
    StringList.LoadFromFile(AFileName, TEncoding.UTF8);
    ParseText(Result, StringList.Text);
  finally
    StringList.Free;
  end;
end;

class procedure TLocalizableStringsFileParser.ParseText(AList: TLocalizableStringsFileParserDTOList; AText: string);
const
  StateInit = 0;
  StateOpen = 1;
  StateOpenSlash = 2;
  StateClose = 3;
var
  i: integer;
  State: integer;
  Str: string;
  Chr: Char;
  IsKeyParse: boolean;
  Key: string;
begin
  State := StateInit;
  Str := '';
  IsKeyParse := true;
  for i := 1 to Length(AText) do
  begin
    Chr := AText[i];
    case State of
      StateInit:
      begin
        if Chr = '"' then
        begin
          State := StateOpen;
          Str := '';
        end;
      end;
      StateOpen:
      begin
        if Chr = '\' then
        begin
          Str := Str + Chr;
          State := StateOpenSlash;
        end
        else if Chr <> '"' then
          Str := Str + Chr
        else
        begin
          if IsKeyParse then
            Key := Str
          else
            AList.Add(TLocalizableStringsFileParserDTO.Create(Key, Str));
          State := StateInit;
          IsKeyParse := not IsKeyParse;
        end;
      end;
      StateOpenSlash:
      begin
        Str := Str + Chr;
        State := StateOpen;
      end;
    end;
  end;
end;

end.
