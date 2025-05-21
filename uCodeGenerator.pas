unit uCodeGenerator;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Generics.Collections, Generics.Defaults,
  uExportLink, uAppLocalizedStrings;

type
  TCodeGenerator = class
    class function CreateHFile(AName: string): string;
    class function CreateMFile(AName: string; AppLocalizedStrings: TAppLocalizedStrings): string;
  end;

implementation

{ TCodeGenerator }

uses uDuplicateChecker;

class function TCodeGenerator.CreateHFile(AName: string): string;
var
  Strings: TStringList;
begin
  Strings := TStringList.Create;
  Strings.Add('// Created by AppLocalizer');
  Strings.Add('');
  Strings.Add('#import <Foundation/Foundation.h>');
  Strings.Add('');
  Strings.Add('#define String(key) [' + AName + '.sharedInstance localizedStringForKey:key]');
  Strings.Add('');
  Strings.Add('@class ' + AName + 'Language;');
  Strings.Add('');
  Strings.Add('@interface ' + AName + ' : NSObject');
  Strings.Add('');
  Strings.Add('@property (nonatomic, strong, readonly) NSArray<' + AName + 'Language *> *supportedLanguages;');
  Strings.Add('@property (nonatomic, copy) NSString *languageCode;');
  Strings.Add('- (NSString *)localizedStringForKey:(NSString *)key;');
  Strings.Add('- (AppLocalizedStringsLanguage *)languageWithCode:(NSString *)code;');
  Strings.Add('+ (instancetype)sharedInstance;');
  Strings.Add('');
  Strings.Add('@end');
  Strings.Add('');
  Strings.Add('@interface ' + AName + 'Language : NSObject');
  Strings.Add('');
  Strings.Add('@property (nonatomic, strong, readonly) NSString *code;');
  Strings.Add('@property (nonatomic, strong, readonly) NSString *name;');
  Strings.Add('@property (nonatomic, strong, readonly) NSString *englishName;');
  Strings.Add('+ (instancetype)createWithDictionary:(NSDictionary *)dictionary;');
  Strings.Add('');
  Strings.Add('@end');
  Result := Strings.Text;
  Strings.Free;
end;

procedure AddLocalizedString(var AStrings: TStringList; AppLocalizedString: TAppLocalizedString);
const
  Ident = '    ';
var
  Key: string;
begin
  if AppLocalizedString.Key = '' then Exit;

  AStrings.Add(Ident + 'self.strings[@"' + AppLocalizedString.Key  + '"] = @{');

  for Key in AppLocalizedString.LocalizedStrings.Keys do
  begin
    if (AppLocalizedString.LocalizedStrings[Key] <> '') then
      AStrings.Add(Ident + Ident + '@"' + Key + '" : @"' + AppLocalizedString.LocalizedStrings[Key] + '",');
  end;

  AStrings.Add(Ident + '};');
end;

class function TCodeGenerator.CreateMFile(AName: string; AppLocalizedStrings: TAppLocalizedStrings): string;
var
  Strings: TStringList;
  Key: string;
  AppLocalizedString: TAppLocalizedString;
  Language: TLanguage;
  DefaultLanguage: string;
begin
  Strings := TStringList.Create;

  Strings.Add('#import "' + AName + '.h"');
  Strings.Add('');
  Strings.Add('@interface ' + AName + ' ()');
  Strings.Add('');
  Strings.Add('@property (nonatomic, strong) NSMutableDictionary *strings;');
  Strings.Add('@property (nonatomic, strong) NSMutableDictionary *ignored;');
  Strings.Add('');
  Strings.Add('@end');
  Strings.Add('');
  Strings.Add('@implementation ' + AName);
  Strings.Add('');
  Strings.Add('+ (instancetype)sharedInstance {');
  Strings.Add('    static id sharedInstance;');
  Strings.Add('    if (!sharedInstance) {');
  Strings.Add('        sharedInstance = [[[self class] alloc] init];');
  Strings.Add('    }');
  Strings.Add('    return sharedInstance;');
  Strings.Add('}');
  Strings.Add('');
  Strings.Add('- (instancetype)init {');
  Strings.Add('    self = [super init];');
  Strings.Add('    if (self) {');
  Strings.Add('        // Warning: Don''t rename _supportedLanguages');
  Strings.Add('        _supportedLanguages = @[');

  for Language in AppLocalizedStrings.Languages.Items do
  begin
   // Strings.Add('[[' + AName +'Language alloc] initWithCode:@"' + Language.Code + '" name:@"' + Language.Name + '" englishName:@"' + Language.EnglishName + '"],');
    Strings.Add('            [' + AName +'Language createWithDictionary:@{@"code" : @"' + Language.Code + '", @"name" : @"' + Language.Name + '", @"englishName" : @"' + Language.EnglishName + '"}],');
    if (Language.Primary) or (DefaultLanguage = '') then
      DefaultLanguage := Language.Code;
  end;

  Strings.Add('        ];');
  Strings.Add('        self.languageCode = @"' + DefaultLanguage + '"; // default locale');
  Strings.Add('        [self fillStrings];');
  Strings.Add('    }');
  Strings.Add('    return self;');
  Strings.Add('}');
  Strings.Add('');
  Strings.Add('- (NSString *)localizedStringForKey:(NSString *)key {');
  Strings.Add('    NSDictionary *dict = self.strings[key];');
  Strings.Add('    if (dict) {');
  Strings.Add('        NSString *result = dict[self.languageCode];');
  Strings.Add('        return result ? result : key;');
  Strings.Add('    } else {');
  Strings.Add('        NSLog(@"Warning: translation for key ''%@'' not found", key);');
  Strings.Add('        return key;');
  Strings.Add('    }');
  Strings.Add('}');
  Strings.Add('');
  Strings.Add('- (' + AName +'Language *)languageWithCode:(NSString *)code {');
  Strings.Add('    for (' + AName +'Language *obj in self.supportedLanguages) {');
  Strings.Add('        if ([obj.code isEqualToString:code]) return obj;');
  Strings.Add('    }');
  Strings.Add('    return nil;');
  Strings.Add('}');
  Strings.Add('');
  Strings.Add('// Warning: Don''t rename fillStrings');
  Strings.Add('- (void)fillStrings {');
  Strings.Add('    self.strings = [[NSMutableDictionary alloc] init];');
  // Strings.Add(''); - вернуть, если потребуется дополнительный перенос строки

  for AppLocalizedString in AppLocalizedStrings.Items do
  begin
    if (AppLocalizedString.Key <> '') then
    begin
      AddLocalizedString(Strings, AppLocalizedString);
      // Strings.Add(''); - вернуть, если потребуется дополнительный перенос строки
    end;
  end;
  Strings.Add('}');
  Strings.Add('');
  Strings.Add('- (void)fillIgnored {');
  Strings.Add('    self.ignored = [[NSMutableDictionary alloc] init];');
  Strings.Add('}');
  Strings.Add('');
  Strings.Add('@end');
  Strings.Add('');
  Strings.Add('@implementation ' + AName + 'Language');
  Strings.Add('');
  Strings.Add('+ (instancetype)createWithDictionary:(NSDictionary *)dictionary {');
  Strings.Add('    return [[' + AName + 'Language alloc] initWithDictionary:dictionary];');
  Strings.Add('}');
  Strings.Add('');
  Strings.Add('- (instancetype)initWithDictionary:(NSDictionary *)dictionary {');
  Strings.Add('    self = [super init];');
  Strings.Add('    if (self) {');
  Strings.Add('        _code = dictionary[@"code"];');
  Strings.Add('        _name = dictionary[@"name"];');
  Strings.Add('        _englishName = dictionary[@"englishName"];');
  Strings.Add('    }');
  Strings.Add('    return self;');
  Strings.Add('}');
  Strings.Add('');
  Strings.Add('@end');

  Result := Strings.Text;
  Strings.Free;
end;

end.



