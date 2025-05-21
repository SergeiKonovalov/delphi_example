unit uSourceString;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Generics.Collections,
  uExportLink;

type
  // Объект строки в исходном коде
  TSourceString = class
    constructor Create(AStringType: Integer; ARawText, AText: string);
    destructor Destroy; override;
  private
    FUID: string;                                                               // идентификатор
    FStringType: Integer;                                                       // тип
    FRawText: string;                                                           // строка в исходном виде как она есть в файле: @"bla-bla", NSLocalizedString(@"bla-bla", nil), Thesaurus.blabla, String(@"bla-bla")
    FText: string;                                                              // строка в "чистом" виде:                        bla-bla,                      bla-bla,                  blabla           bla-bla
    FFiles: TStringList;                                                        // список файлов, в котором встречается строка
  public
    procedure AddFileName(AFileName: string);
  public
    property UID: string read FUID;
    property StringType: Integer read FStringType;
    property RawText: string read FRawText;
    property Text: string read FText;
    property Files: TStringList read FFiles;
  end;

  // Строки
  TSourceStrings = class
    constructor Create;
    destructor Destroy; override;
  private
    FItems: TObjectList<TSourceString>;
  private
    function Find(ASourceStringType: Integer; ARawText, AText: string): TSourceString;
  public
    function Add(AFileName: string; ASourceStringType: Integer; ARawText, AText: string): TSourceString;
    function FindWithUID(AUID: string): TSourceString;
  public
    property Items: TObjectList<TSourceString> read FItems;
  end;

implementation

{ TSourceString }

constructor TSourceString.Create(AStringType: Integer; ARawText, AText: string);
var
  GUID: TGUID;
begin
  CreateGUID(GUID);
  FUID := GUID.ToString;
  FStringType := AStringType;
  FRawText := ARawText;
  FText := AText;
  FFiles := TStringList.Create;
end;

destructor TSourceString.Destroy;
begin
  FFiles.Free;
  inherited;
end;

procedure TSourceString.AddFileName(AFileName: string);
var
  s: string;
begin
  for s in FFiles do
    if s = AFileName then
      Exit;

  FFiles.Add(AFileName);
end;

{ TSourceStrings }

constructor TSourceStrings.Create;
begin
  FItems := TObjectList<TSourceString>.Create;
end;

destructor TSourceStrings.Destroy;
begin
  FItems.Free;
  inherited;
end;

function TSourceStrings.Find(ASourceStringType: Integer; ARawText, AText: string): TSourceString;
var
  Item: TSourceString;
begin
  Result := nil;
  for Item in FItems do
  begin
    if (Item.StringType = ASourceStringType) and (Item.RawText = ARawText)
      and (Item.Text = AText)
    then
      Exit(Item);
  end;
end;

function TSourceStrings.FindWithUID(AUID: string): TSourceString;
var
  Item: TSourceString;
begin
  Result := nil;
  for Item in FItems do
    if Item.UID = AUID then
      Exit(Item);
end;

function TSourceStrings.Add(AFileName: string; ASourceStringType: Integer;
  ARawText, AText: string): TSourceString;
begin
  Result := Find(ASourceStringType, ARawText, AText);
  if Result = nil then
  begin
    Result := TSourceString.Create(ASourceStringType, ARawText, AText);
    FItems.Add(Result);
  end;
  Result.AddFileName(AFileName);
end;



end.
