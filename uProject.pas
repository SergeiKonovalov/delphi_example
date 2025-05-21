unit uProject;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Generics.Collections,
  uExportLink, uSourceString, uNSLocalizedStrings, uAppLocalizedStrings, StrUtils;

type
  TFileType = (ftUnknown, ftLocalizationFile, ftLocalizationFileV2, ftLocalizableStrings, ftMFile);

  // проект локализации
  TProject = class
    constructor Create(ADir: string); overload;
    destructor Destroy; override;
  private
    FDirectory: string;                                                         // директория проекта
    FobjcLocalizedStringsFileName: string;                                      // файл objcLocalizedStrings.m
    FAppLocalizedStringsFileName: string;                                       // файл AppLocalizedStringsV2.m  (второй версии, приходит на смену objcLocalizedStrings.m)
    FLocalizibleStringsFiles: TStringList;                                      // файлы локализации 'Localizable.strings'
    FSourceFiles: TStringList;                                                  // файлы *.m (кроме objcLocalizedStrings.m и AppLocalizedStringsV2.m)
    FSourceStrings: TSourceStrings;                                             // извлеченные строковые объекты из файлов
    FNSLocalizedStrings: TNSLocalizedStrings;                                   // строки из файлов Localizible.Strings
    FExportLinks: TExportLinks;                                                 // строки движка objcLocalizedStrings
    FAppLocalizedStrings: TAppLocalizedStrings;                                 // строки движка AppLocalizedStrings
  private
    procedure ScanDir(ADir: string);
    procedure ParseobjcLocalizedStringsFile;
    procedure ParseAppLocalizedStringsFile;
    procedure ParseLocalizibleStringsFiles;
    procedure ParseMFiles;
    procedure Fill;
  public
    procedure ReplaceStrings(AMacrosName: string);
  public
    property Directory: string read FDirectory;
    property objcLocalizedStringsFileName: string read FobjcLocalizedStringsFileName;
    property AppLocalizedStringsFileName: string read FAppLocalizedStringsFileName;
    property SourceStrings: TSourceStrings read FSourceStrings;
    property NSLocalizedStrings: TNSLocalizedStrings read FNSLocalizedStrings;
    property AppLocalizedStrings: TAppLocalizedStrings read FAppLocalizedStrings;
  end;

implementation

uses uobjcLocalizedStringsFileParser, uLocalizableStringsFileParser, uMFileParser,
  uDuplicateChecker;

{ TLocalizedProject }

constructor TProject.Create(ADir: string);
begin
  FDirectory := ADir;

  FobjcLocalizedStringsFileName := '';
  FAppLocalizedStringsFileName := '';

  FSourceFiles := TStringList.Create;
  FLocalizibleStringsFiles := TStringList.Create;
  FExportLinks := TExportLinks.Create;
  FNSLocalizedStrings := TNSLocalizedStrings.Create;
  FSourceStrings := TSourceStrings.Create;

  ScanDir(ADir);
  ParseAppLocalizedStringsFile;
  ParseobjcLocalizedStringsFile;
  ParseLocalizibleStringsFiles;
  ParseMFiles;

  Fill;
end;

destructor TProject.Destroy;
begin
  FSourceFiles.Free;
  FLocalizibleStringsFiles.Free;
  FExportLinks.Free;
  FNSLocalizedStrings.Free;
  FSourceStrings.Free;
  inherited;
end;

function GetFileType(AFileName: string): TFileType;
const
  objcLocalizationFile = 'objcLocalizedStrings.m';
  AppLocalizationFile = 'AppLocalizedStrings.m';
  LocalizableStrings = 'Localizable.strings';
  MFileExt = '.m';
begin
  if (AFileName = objcLocalizationFile) then
    Result := ftLocalizationFile
  else if (AFileName = AppLocalizationFile) then
    Result := ftLocalizationFileV2
  else if (AFileName = LocalizableStrings) then
    Result := ftLocalizableStrings
  else if (ExtractFileExt(AFileName) = MFileExt) then
    Result := ftMFile
  else
    Result := ftUnknown;
end;

procedure TProject.ScanDir(ADir: string);
var
  SearchRec : TSearchRec;
  FullFileName: string;
  FileType: TFileType;
begin
  if ADir[Length(ADir)] <> '\' then ADir := ADir + '\';
  if FindFirst(ADir + '*.*', faAnyFile, SearchRec) = 0 then
  begin
    repeat
      Application.ProcessMessages;
      if ((SearchRec.Attr and faDirectory) <> faDirectory) then
      begin
        FileType := GetFileType(SearchRec.Name);
        FullFileName := ADir + SearchRec.Name;
        case FileType of
          ftMFile: FSourceFiles.Add(FullFileName);
          ftLocalizationFile: FobjcLocalizedStringsFileName := FullFileName;
          ftLocalizationFileV2: FAppLocalizedStringsFileName := FullFileName;
          ftLocalizableStrings: FLocalizibleStringsFiles.Add(FullFileName);
        end;
      end
      else if (SearchRec.Name <> '..') and (SearchRec.Name <> '.') then
      begin
        ScanDir(ADir + SearchRec.Name + '\');
      end;
    until FindNext(SearchRec) <> 0;
    FindClose(SearchRec);
  end;
end;

procedure TProject.ParseobjcLocalizedStringsFile;
var
  List: TobjcLocalizedStrings;
  Dto: TobjcLocalizedString;
begin
  if FobjcLocalizedStringsFileName <> '' then
  begin
    List := TobjLocalizedStringsFileParser.Parse(FobjcLocalizedStringsFileName);
    for Dto in List do
    begin
      FExportLinks.ImportExportLink(dto.Name, dto.LocalizedStrings, Dto.NSLocalizedStringKey);
    end;
    List.Free;
  end;
end;

procedure TProject.ParseAppLocalizedStringsFile;
begin
  if FAppLocalizedStringsFileName <> '' then
  begin
    FAppLocalizedStrings := TAppLocalizedStringsFileParser.Parse(FAppLocalizedStringsFileName);
  end else
  begin
    FAppLocalizedStrings := TAppLocalizedStrings.Create;
    FAppLocalizedStrings.Name := 'AppLocalizedStrings';
  end;
end;

procedure TProject.ParseLocalizibleStringsFiles;

  function ExtractLanguageFromDir(AFileName: string): string;
  var
    p, i: integer;
  begin
    Result := '';
    p := Pos('.lproj', AFileName);
    if i > 0 then
      for i := p-1 downto 0 do
        if AFileName[i] <> '\' then
          Result := AFileName[i] + Result
        else
          break;
  end;

var
  FileName: string;
  Language: string;
  List: TLocalizableStringsFileParserDTOList;
  Dto: TLocalizableStringsFileParserDTO;
begin
  if FLocalizibleStringsFiles.Count > 0 then
    for FileName in FLocalizibleStringsFiles do
    begin
      Language := ExtractLanguageFromDir(FileName);
     // TODO: добавлять язык в коллекцию языков системы переводов NSLocalizedStrings
      List := TLocalizableStringsFileParser.Parse(FileName);
      for Dto in List do
      begin
        FNSLocalizedStrings.Add(Dto.Key, Dto.Value, Language);
      end;
      List.Free;
    end;
end;

procedure TProject.ParseMFiles;
var
  FileName: string;
  List: TMFileParsedStrings;
  Item: TMFileParsedString;
  ExportLink: TExportLink;
  SourceString: TSourceString;
  AppLocalizedString: TAppLocalizedString;
  Key, Value: string;
begin
  for FileName in FSourceFiles do
  begin
    List := TMFileParser.Parse(FileName);
    for Item in List do
    begin
      if Item.Text = '' then Continue;

      case Item.StringType of
        stLiteral:
        begin
          FSourceStrings.Add(FileName, 1, Item.Source, Item.Text);
        end;
        stNSLocalizedString:
        begin
          FSourceStrings.Add(FileName, 2, Item.Source, Item.Text);
        end;
        stMethod:
        begin
          // пропускаем обращения к методу languageCode и supportedLanguages, т.к. это другой по смыслу вызов
          if Item.Text = 'languageCode' then Continue;
          if Item.Text = 'supportedLanguages' then Continue;
          if Item.Text = 'supportedLanguages.allKeys' then Continue;

          ExportLink := FExportLinks.ImportExportedLink(Item.Text);
          SourceString := FSourceStrings.Add(FileName, 3, Item.Source, Item.Text);
          AppLocalizedString := FAppLocalizedStrings.AddSourceString(SourceString);
          for key in ExportLink.Values.Keys do
          begin
            Value := ExportLink.Values[Key];
            AppLocalizedString.Add(Key, Value);
          end;
        end;
        stAppLocalizedString:
        begin
          SourceString := FSourceStrings.Add(FileName, 4, Item.Source, Item.Text);
          FAppLocalizedStrings.AddSourceString(SourceString);
        end;
      end;
    end;
    List.Free;
  end;
end;

procedure TProject.Fill;
var
  ExportLink: TExportLink;
  NSLocalizedString: TNSLocalizedString;
  Key: string;
begin
  for ExportLink in FExportLinks.Items do
  begin
    if ExportLink.NSLocalizedStringKey <> '' then
    begin
      NSLocalizedString := FNSLocalizedStrings.FindWithKey(ExportLink.NSLocalizedStringKey);
      if NSLocalizedString <> nil then
      begin
        for Key in NSLocalizedString.Values.Keys do
        begin
          if not ExportLink.Values.ContainsKey(Key) then
            ExportLink.Values.Add(Key, NSLocalizedString.Values[Key]);
        end;
      end;
    end;
  end;
end;



procedure TProject.ReplaceStrings(AMacrosName: string);
var
  StringList: TStringList;
  AppLocalizedString: TAppLocalizedString;
  FileName: string;
  Text: string;
begin
  StringList := TStringList.Create;
  for AppLocalizedString in FAppLocalizedStrings.Items do
  begin
    if not Assigned(AppLocalizedString.SourceString) then Continue;

    // StringType = 4 - соответствует строке String(@"bla-bla"), в будущем поправть

    // обновление строк, если ключ был переименован
    if (AppLocalizedString.SourceString.StringType = 4) and (AppLocalizedString.IsKeyRenamed) then
    begin
      for FileName in AppLocalizedString.SourceString.Files do
      begin
        StringList.LoadFromFile(FileName, TEncoding.UTF8);
        Text := StringList.Text;
        Text := StringReplace(Text, AppLocalizedString.SourceString.RawText, AMacrosName + '(@"' + AppLocalizedString.Key + '")', [rfReplaceAll]);
        StringList.Text := Text;
        StringList.SaveToFile(FileName, TEncoding.UTF8);
      end;
    end;

    // заменяем обычные строки
    if (AppLocalizedString.SourceString.StringType <> 4) then
    begin
      for FileName in AppLocalizedString.SourceString.Files do
      begin
        StringList.LoadFromFile(FileName, TEncoding.UTF8);
        Text := StringList.Text;
        Text := StringReplace(Text, AppLocalizedString.SourceString.RawText, AMacrosName + '(@"' + AppLocalizedString.Key + '")', [rfReplaceAll]);
        StringList.Text := Text;
        StringList.SaveToFile(FileName, TEncoding.UTF8);
      end;
    end;

  end;
  StringList.Free;
end;

end.
