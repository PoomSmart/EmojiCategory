//
//  ViewController.m
//  EmojiCategory
//
//  Created by PoomSmart on 8/2/16.
//  Copyright © 2016 - 2023 PoomSmart. All rights reserved.
//

#import "ViewController.h"
#import <CoreText/CoreText.h>
#import <CoreGraphics/CoreGraphics.h>
#import "Header.h"
#import <dlfcn.h>

@interface ViewController (){
    void *ct;
    void *cs;
    void *gsFont;
    CTFontRef emojiFont;
    CGFontRef emojiCGFont;
    CFDataRef (*XTCopyUncompressedBitmapRepresentation)(const UInt8 *, CFIndex);
    CFCharacterSetRef (*CreateCharacterSetWithCompressedBitmapRepresentation)(const CFDataRef characterSet);
}
@end

@implementation ViewController

- (CFDataRef)uncompressedBitmap:(CFDataRef)compressedData {
    if (XTCopyUncompressedBitmapRepresentation == NULL) {
        NSLog(@"Error: XTCopyUncompressedBitmapRepresentation not found");
        return compressedData;
    }
    CFDataRef uncompressedData = XTCopyUncompressedBitmapRepresentation(CFDataGetBytePtr(compressedData), CFDataGetLength(compressedData));
    CFRelease(compressedData);
    return uncompressedData;
}

- (CFCharacterSetRef)uncompressedCharacterSet:(CFDataRef)compressedData {
    if (CreateCharacterSetWithCompressedBitmapRepresentation == NULL) {
        return NULL;
    }
    return CreateCharacterSetWithCompressedBitmapRepresentation(compressedData);
}

- (NSString *)cfDataToString:(CFDataRef)data {
    const unsigned char *bytes = (const unsigned char *)CFDataGetBytePtr(data);
    NSMutableString *hex = [NSMutableString new];
    for (NSInteger i = 0; i < CFDataGetLength(data); ++i) {
        [hex appendFormat:@"%02x", bytes[i]];
    }
    return hex.copy;
}

- (void)printNSData:(NSData *)uncompressedData {
    const UInt8 *bytes = uncompressedData.bytes;
    NSMutableArray *array = [NSMutableArray array];
    for (int i = 0; i < uncompressedData.length; ++i) {
        [array addObject:[NSString stringWithFormat:@"0x%x", bytes[i]]];
    }
    [self prettyPrint:array withQuotes:NO];
}

- (void)readFontCache:(BOOL)onlyCharset {
    NSDictionary *(*dict)(void) = (NSDictionary* (*)(void))dlsym(gsFont, "GSFontCacheGetDictionary");
    NSDictionary *theDict = dict();
    if (kCFCoreFoundationVersionNumber > 1575.17 && kCFCoreFoundationVersionNumber < 1700.00) {
        NSData *emoji = theDict[@"CharacterSets.plist"][@".AppleColorEmojiUI"];
        NSLog(@"Compressed:");
        [self printNSData:emoji];
        NSData *uncompressedData = [NSCharacterSet _emojiCharacterSet].bitmapRepresentation;
        NSLog(@"Uncompressed:");
        [self printNSData:uncompressedData];
    } else {
        NSDictionary *emoji = theDict[@"CTFontInfo.plist"][@"Attrs"][@"AppleColorEmoji"];
        if (emoji == nil)
            emoji = theDict[@"Attrs"][@"AppleColorEmoji"];
        if (emoji) {
            if (onlyCharset) {
                NSLog(@"AppleColorEmoji CharacterSet:");
                NSData *compressedData = emoji[@"NSCTFontCharacterSetAttribute"];
                NSLog(@"Compressed:");
                [self printNSData:compressedData];
                NSLog(@"Uncompressed:");
                if (kCFCoreFoundationVersionNumber >= 1700.00) {
                    NSCharacterSet *nsCharacterSet = (__bridge NSCharacterSet *)[self uncompressedCharacterSet:(__bridge CFDataRef)compressedData];
                    // [self prettyPrint:[self charsetToArray:nsCharacterSet]];
                    [self printNSData:nsCharacterSet.bitmapRepresentation];
                }
                else
                    [self printNSData:(__bridge NSData *)[self uncompressedBitmap:(__bridge CFDataRef)compressedData]];
            } else
                NSLog(@"AppleColorEmoji:\n%@", emoji);
        }
        NSDictionary *emojiUI = theDict[@"CTFontInfo.plist"][@"Attrs"][@".AppleColorEmojiUI"];
        if (emojiUI) {
            if (onlyCharset) {
                NSLog(@".AppleColorEmojiUI CharacterSet:");
                NSData *compressedData = emojiUI[@"NSCTFontCharacterSetAttribute"];
                NSLog(@"Compressed:");
                [self printNSData:compressedData];
                NSLog(@"Uncompressed:");
                [self printNSData:(__bridge NSData *)[self uncompressedBitmap:(__bridge CFDataRef)compressedData]];
            } else
                NSLog(@".AppleColorEmojiUI:\n%@", emoji);
        }
    }
}

- (NSMutableArray <NSString *> *)emojiCategory:(NSInteger)type {
    NSArray <UIKeyboardEmoji *> *emojiArray = [NSClassFromString(@"UIKeyboardEmojiCategory") categoryForType:type].emoji;
    NSMutableArray <NSString *> *emojiArray_ = [NSMutableArray arrayWithCapacity:emojiArray.count];
    for (UIKeyboardEmoji *emoji in emojiArray)
        [emojiArray_ addObject:emoji.emojiString];
    return emojiArray_;
}

- (Class)categoryClass:(NSInteger)type {
    return kCFCoreFoundationVersionNumber >= 1348.22 || type == 14 ? NSClassFromString(@"EMFEmojiCategory") : NSClassFromString(@"UIKeyboardEmojiCategory");
}

- (NSArray <NSString *> *)emojiPreset:(NSInteger)type {
    Class categoryClass = [self categoryClass:type];
    switch (type) {
        case 0:
            return [categoryClass PeopleEmoji];
        case 1:
            return [categoryClass NatureEmoji];
        case 2:
            return [categoryClass FoodAndDrinkEmoji];
        case 3:
            return [categoryClass CelebrationEmoji];
        case 4:
            return [categoryClass ActivityEmoji];
        case 5:
            return [categoryClass TravelAndPlacesEmoji];
        case 6:
            if ([categoryClass respondsToSelector:@selector(ObjectsAndSymbolsEmoji)])
                return [categoryClass ObjectsAndSymbolsEmoji];
            break;
        case 7:
            return [categoryClass ObjectsEmoji];
        case 8:
            return [categoryClass SymbolsEmoji];
        case 9: {
            if ([categoryClass respondsToSelector:@selector(DingbatVariantsEmoji)])
                return [categoryClass DingbatVariantsEmoji];
            if ([categoryClass respondsToSelector:@selector(DingbatsVariantEmoji)])
                return [categoryClass DingbatsVariantEmoji];
            break;
        }
        case 10:
            return [categoryClass SkinToneEmoji];
        case 11:
            return [categoryClass GenderEmoji];
        case 12:
            return [categoryClass NoneVariantEmoji];
        case 13:
            if ([categoryClass respondsToSelector:@selector(ProfessionEmoji)])
                return [categoryClass ProfessionEmoji];
            break;
        case 14:
            if ([categoryClass respondsToSelector:@selector(computeEmojiFlagsSortedByLanguage)])
                return [categoryClass computeEmojiFlagsSortedByLanguage];
            if ([categoryClass respondsToSelector:@selector(loadPrecomputedEmojiFlagCategory)])
                return [categoryClass loadPrecomputedEmojiFlagCategory];
            break;
        case 15:
            if ([categoryClass respondsToSelector:@selector(FlagsEmoji)])
                return [categoryClass FlagsEmoji];
            break;
        case 16:
            return [categoryClass PrepopulatedEmoji];
        case 17:
            if ([categoryClass respondsToSelector:@selector(ProfessionWithoutSkinToneEmoji)])
                return [categoryClass ProfessionWithoutSkinToneEmoji];
            break;
        case 18:
            if ([categoryClass respondsToSelector:@selector(CoupleMultiSkinToneEmoji)])
                return [categoryClass CoupleMultiSkinToneEmoji];
            break;
        case 19:
            if ([categoryClass respondsToSelector:@selector(MultiPersonFamilySkinToneEmoji)])
                return [categoryClass MultiPersonFamilySkinToneEmoji];
            break;
        case 20:
            if ([categoryClass respondsToSelector:@selector(ExtendedCoupleMultiSkinToneEmoji)])
                return [categoryClass ExtendedCoupleMultiSkinToneEmoji];
    }
    NSLog(@"%@ has no relevant methods", categoryClass);
    return nil;
}

- (void)prettyPrint:(NSArray <NSString *> *)array withQuotes:(BOOL)wq asCodepoints:(BOOL)cp perLine:(int)perLine {
    int x = 1;
    NSMutableString *string = [NSMutableString string];
    NSLog(@"Total: %lu", (unsigned long)array.count);
    for (NSString *substring in array) {
        if (wq)
            [string appendString:@"@\""];
        if (cp)
            [string appendFormat:@"0x%x", [substring _firstLongCharacter]];
        else
            [string appendString:substring];
        if (wq)
            [string appendString:@"\","];
        else
            [string appendString:@","];
        if (x++ % perLine == 0) {
            NSLog(@"%@", string);
            string.string = @"";
        }
        else
            [string appendString:@" "];
    }
    NSLog(@"%@", string);
}

- (void)prettyPrint:(NSArray <NSString *> *)array withQuotes:(BOOL)wq asCodepoints:(BOOL)cp {
    [self prettyPrint:array withQuotes:wq asCodepoints:cp perLine:10];
}

- (void)prettyPrint:(NSArray <NSString *> *)array withQuotes:(BOOL)wq perLine:(int)perLine {
    [self prettyPrint:array withQuotes:wq asCodepoints:NO perLine:perLine];
}

- (void)prettyPrint:(NSArray <NSString *> *)array withQuotes:(BOOL)wq {
    [self prettyPrint:array withQuotes:wq asCodepoints:NO];
}

- (void)prettyPrint:(NSArray <NSString *> *)array {
    [self prettyPrint:array withQuotes:YES asCodepoints:NO];
}

- (void)readEmojis:(BOOL)preset withVariant:(BOOL)withVariant pretty:(BOOL)pretty {
    if (preset) {
        for (NSInteger i = 0; i <= 20; ++i) {
            NSLog(@"Preset %ld:", (long)i);
            if (pretty)
                [self prettyPrint:[self emojiPreset:i]];
            else {
                for (NSString *emoji in [self emojiPreset:i]) {
                    if (withVariant)
                        NSLog(@"%@ %lu", emoji, (unsigned long)[NSClassFromString(@"UIKeyboardEmojiCategory") hasVariantsForEmoji:emoji]);
                    else
                        NSLog(@"%@: %u", emoji, [self glyphForEmojiString:emoji]);
                }
            }
        }
    } else {
        for (NSInteger i = 0; i <= 9; ++i) {
            NSLog(@"Category %ld:", (long)i);
            if (pretty)
                [self prettyPrint:[self emojiCategory:i]];
            else {
                for (NSString *emoji in [self emojiCategory:i]) {
                    if (withVariant)
                        NSLog(@"%@ %lu", emoji, (unsigned long)[NSClassFromString(@"UIKeyboardEmojiCategory") hasVariantsForEmoji:emoji]);
                    else
                        NSLog(@"%@", emoji);
                }
            }
        }
    }
}

- (void)readMultiSkinEmojis {
    static int modifiers[] = { 1, 3, 4, 5, 6, -1, 0 }; // -1 None, 0 silhouette
    Class EMFEmojiCategory = NSClassFromString(@"EMFEmojiCategory");
    Class EMFStringUtilities = NSClassFromString(@"EMFStringUtilities");
    for (NSString *emoji in [self emojiPreset:0]) {
        if ([EMFEmojiCategory _isCoupleMultiSkinToneEmoji:emoji]) {
            NSMutableArray *variants = [NSMutableArray array];
            for (int i = 0; i < 7; ++i) {
                NSString *specifier1 = modifiers[i] == 0 ? @"EMFSkinToneSpecifierTypeFitzpatrickSilhouette" : [EMFStringUtilities skinToneSpecifierTypeFromEmojiFitzpatrickModifier:modifiers[i]];
                for (int j = 0; j < 7; ++j) {
                    NSString *specifier2 = modifiers[j] == 0 ? @"EMFSkinToneSpecifierTypeFitzpatrickSilhouette" : [EMFStringUtilities skinToneSpecifierTypeFromEmojiFitzpatrickModifier:modifiers[j]];
                    NSString *skinned = [EMFStringUtilities _multiPersonStringForString:emoji skinToneVariantSpecifier:@[specifier1, specifier2]];
                    [variants addObject:skinned];
                }
            }
            NSLog(@"Base %@", emoji);
            [self prettyPrint:variants withQuotes:YES perLine:7];
        }
    }
}

- (CGGlyph)glyphForEmojiString:(NSString *)emojiString {
    unichar characters[16] = {0};
    [emojiString getCharacters:characters range:NSMakeRange(0, emojiString.length)];
    int length = 0;
    while (characters[length])
        ++length;
    for (int i = 0; i < length; ++i)
        printf("%x ", characters[i]);
    printf("\n");
    CGGlyph glyphs[length];
    if (CTFontGetGlyphsForCharacters(emojiFont, characters, glyphs, length)) {
        NSLog(@"%@ -> %u %u %@", emojiString, glyphs[0], glyphs[length - 1], CGFontCopyGlyphNameForGlyph(emojiCGFont, glyphs[0]));
        return glyphs[0];
    }
    return 0;
}

+ (CFCharacterSetRef)emojiCharacterSet {
    static CFCharacterSetRef set = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        set = CTFontCopyCharacterSet(CTFontCreateWithName(CFSTR("AppleColorEmoji"), 0.0, NULL));
    });
    return set;
}

+ (BOOL)containsEmoji:(NSString *)emoji {
    return CFStringFindCharacterFromSet((CFStringRef)emoji, [self emojiCharacterSet], CFRangeMake(0, emoji.length), 0, NULL);
}

- (void)setup {
    ct = dlopen("/System/Library/Frameworks/CoreText.framework/CoreText", RTLD_NOW);
    assert(ct != NULL);
    cs = dlopen("/Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate", RTLD_NOW);
    if (cs) {
        MSGetImageByName = dlsym(cs, "MSGetImageByName");
        assert(MSGetImageByName != NULL);
        MSFindSymbol = dlsym(cs, "MSFindSymbol");
        assert(MSFindSymbol != NULL);
        MSImageRef ref = MSGetImageByName("/System/Library/Frameworks/CoreText.framework/CoreText");
        XTCopyUncompressedBitmapRepresentation = MSFindSymbol(ref, "__Z38XTCopyUncompressedBitmapRepresentationPKhm");
        CreateCharacterSetWithCompressedBitmapRepresentation = MSFindSymbol(ref, "__Z52CreateCharacterSetWithCompressedBitmapRepresentationPK8__CFData");
    }
    gsFont = dlopen("/System/Library/PrivateFrameworks/FontServices.framework/libGSFontCache.dylib", RTLD_NOW);
    assert(gsFont != NULL);
    dlopen("/System/Library/PrivateFrameworks/EmojiFoundation.framework/EmojiFoundation", RTLD_NOW);
    emojiFont = CTFontCreateWithName(CFSTR("AppleColorEmoji"), 0.0, NULL);
    emojiCGFont = CTFontCopyGraphicsFont(emojiFont, NULL);
}

- (void)extractSkins {
    if (NSClassFromString(@"EMFStringUtilities")) {
        NSArray <NSString *> *skins = [self emojiPreset:10];
        for (NSString *skin in skins)
            [self prettyPrint:[NSClassFromString(@"EMFStringUtilities") _skinToneVariantsForString:skin]];
    } else
        NSLog(@"EMFStringUtilities does not exist");
}

- (NSArray <NSString *> *)charsetToArray:(NSCharacterSet *)charset {
    NSMutableArray *array = [NSMutableArray array];
    for (int plane = 0; plane <= 16; ++plane) {
        if ([charset hasMemberInPlane:plane]) {
            for (UTF32Char c = plane << 16; c < (plane + 1) << 16; ++c) {
                if ([charset longCharacterIsMember:c]) {
                    UTF32Char c1 = OSSwapHostToLittleInt32(c);
                    NSString *s = [[NSString alloc] initWithBytes:&c1 length:4 encoding:NSUTF32LittleEndianStringEncoding];
                    [array addObject:s];
                }
            }
        }
    }
    return array;
}

- (void)printEmojiUset:(UProperty)property {
    UErrorCode error = U_ZERO_ERROR;
    USet *set = uset_openEmpty();
    uset_applyIntPropertyValue(set, property, 1, &error);
    uset_freeze(set);
    CFCharacterSetRef cfSet = _CFCreateCharacterSetFromUSet(set);
    [self prettyPrint:[self charsetToArray:(__bridge NSCharacterSet *)cfSet]];
    uset_close(set);
    CFRelease(cfSet);
}

- (int32_t)printEmojiUsetCodepoints:(UProperty)property {
    NSMutableArray <NSString *> *codepoints = [NSMutableArray array];
    UErrorCode error = U_ZERO_ERROR;
    USet *set = uset_openEmpty();
    uset_applyIntPropertyValue(set, property, 1, &error);
    uset_freeze(set);
    
    error = U_ZERO_ERROR;
    UChar buffer[2048];
    int32_t stringLen;

    int32_t itemCount = uset_getItemCount(set);
    int32_t codepointCount = 0;
    for (int32_t i = 0; i < itemCount; ++i) {
        UChar32 start, end;
        UChar *string;
        string = buffer;
        stringLen = uset_getItem(set, i, &start, &end, buffer, sizeof(buffer) / sizeof(UChar), &error);
        if (error == U_BUFFER_OVERFLOW_ERROR) {
            string = (UChar *)malloc(sizeof(UChar) * (stringLen + 1));
            if (!string)
                return -1;
            error = U_ZERO_ERROR;
            uset_getItem(set, i, &start, &end, string, stringLen + 1, &error);
        }
        if (U_FAILURE(error)) {
            if (string != buffer)
                free(string);
            return -1;
        }
        if (stringLen <= 0) {
            for (UChar32 c = start; c <= end + 1; ++c) {
                [codepoints addObject:[NSString stringWithFormat:@"0x%x", c]];
            }
            codepointCount += end - start + 2;
        }
        if (string != buffer)
            free(string);
    }
    NSLog(@"Codepoints count: %d", codepointCount);
    [self prettyPrint:codepoints withQuotes:NO];
    uset_close(set);
    return codepointCount;
}

- (void)printCodepointsForPreset:(NSInteger)preset {
    [self prettyPrint:[self emojiPreset:preset] withQuotes:NO asCodepoints:YES];
}

- (void)printProfessionModifierCodepoints {
    NSArray <NSString *> *professions = [self emojiPreset:13];
    NSMutableArray *codepoints = [NSMutableArray array];
    for (NSString *profression in professions) {
        NSUInteger zwj = [profression rangeOfString:ZWJ options:NSLiteralSearch].location;
        if (zwj != NSNotFound) {
            NSString *modifier = [profression substringFromIndex:zwj + 1];
            if (![codepoints containsObject:modifier])
                [codepoints addObject:modifier];
        }
    }
    [self prettyPrint:codepoints withQuotes:NO asCodepoints:YES];
}

- (BOOL)isValidExtendCharacterForPictographicSequence:(UTF32Char)character {
    return u_hasBinaryProperty(character, UCHAR_GRAPHEME_EXTEND) || u_hasBinaryProperty(character, UCHAR_EMOJI_MODIFIER);
}

- (BOOL)isValidExtendedPictographicCharacterForPictographicSequence:(UTF32Char)character {
    return u_hasBinaryProperty(character, UCHAR_EXTENDED_PICTOGRAPHIC);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
    //[self printProfessionModifierCodepoints];
    //[self printCodepointsForPreset:10]; // skin tone emojis
    //[self printCodepointsForPreset:11]; // gender emojis
    //[self extractSkins];
    //[self readEmojis:YES withVariant:NO pretty:YES];
    //[self readFontCache:YES];
    //[self printEmojiUsetCodepoints:UCHAR_EMOJI_PRESENTATION];
    //[self printEmojiUsetCodepoints:UCHAR_EMOJI_MODIFIER];
    //[self printEmojiUsetCodepoints:UCHAR_EXTENDED_PICTOGRAPHIC];
    //[self printEmojiUsetCodepoints:UCHAR_GRAPHEME_EXTEND];
    //[self readMultiSkinEmojis];
}

@end
