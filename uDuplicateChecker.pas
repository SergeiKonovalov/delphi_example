unit uDuplicateChecker;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Generics.Collections,
  uExportLink, uSourceString;

type
  TDuplicateStrings = TDictionary<string,TExportLink>;

  TDuplicateChecker = class
  public
    class function CheckThesaurus(AThesaurus: TObjectList<TExportLink>): TDuplicateStrings;
    class function CheckString(AThesaurusString: TExportLink; AThesaurus: TObjectList<TExportLink>): boolean;
  end;

implementation

{ TDuplicateChecker }

class function TDuplicateChecker.CheckString(AThesaurusString: TExportLink;
  AThesaurus: TObjectList<TExportLink>): boolean;
const
  ReservedSize = 2;
  Reserved: array[1..ReservedSize] of string = ('continue', 'delete');
var
  i, j: integer;
  a: TExportLink;
begin
  Result := true;
  if (AThesaurus.Count < 2) or (AThesaurusString.Name = '') then
    Exit;

  // проверка на зарезервированные слова
  for i := 1 to ReservedSize do
    if AThesaurusString.Name = Reserved[i] then
      Exit(false);

  for i := 0 to AThesaurus.Count - 2 do
  begin
    a := AThesaurus[i];
    if a = AThesaurusString then continue;

    if a.Name = '' then continue;
      if LowerCase(a.Name) = LowerCase(AThesaurusString.Name) then
        Exit(false);
  end;
end;

class function TDuplicateChecker.CheckThesaurus(AThesaurus: TObjectList<TExportLink>): TDuplicateStrings;
var
  i, j: integer;
  a, b: TExportLink;
begin
  if AThesaurus.Count < 2 then
    Exit(nil);

  Result := TDuplicateStrings.Create;

  for i := 0 to AThesaurus.Count - 2 do
  begin
    a := AThesaurus[i];
    if a.Name = '' then continue;

    for j := i+1 to AThesaurus.Count - 1 do
    begin
      b := AThesaurus[j];
      if b.Name = '' then continue;

      if LowerCase(a.Name) = LowerCase(b.Name) then
      begin
        if not Result.ContainsKey(LowerCase(a.Name)) then
          Result.Add(LowerCase(a.Name), a);
        if not Result.ContainsKey(LowerCase(b.Name)) then
          Result.Add(LowerCase(b.Name), b);
        break;
      end;
    end;
  end;
end;

end.
