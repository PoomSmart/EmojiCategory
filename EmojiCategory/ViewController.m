//
//  ViewController.m
//  EmojiCategory
//
//  Created by Thatchapon Unprasert on 8/2/16.
//  Copyright © 2016 - 2018 Thatchapon Unprasert. All rights reserved.
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

- (NSString *)cfDataToString:(CFDataRef)data {
    const unsigned char *bytes = (const unsigned char *)CFDataGetBytePtr(data);
    NSMutableString *hex = [NSMutableString new];
    for (NSInteger i = 0; i < CFDataGetLength(data); ++i) {
        [hex appendFormat:@"%02x", bytes[i]];
    }
    return hex.copy;
}

static inline char itoh(int i) {
    if (i > 9) return 'A' + (i - 10);
    return '0' + i;
}

- (NSString *)NSDataToHex:(NSData *)data {
    NSUInteger len = data.length;
    unsigned char *bytes = (unsigned char *)data.bytes;
    unsigned char *buf = (unsigned char *)malloc(len * 2);
    for (NSUInteger i = 0; i < len; ++i) {
        buf[i * 2] = itoh((bytes[i] >> 4) & 0xF);
        buf[i * 2 + 1] = itoh(bytes[i] & 0xF);
    }
    return [[NSString alloc] initWithBytesNoCopy:buf length:len * 2 encoding:NSASCIIStringEncoding freeWhenDone:YES];
}

- (void)readFontCache:(BOOL)onlyCharset {
    NSDictionary *(*dict)(void) = (NSDictionary* (*)(void))dlsym(gsFont, "GSFontCacheGetDictionary");
    if (kCFCoreFoundationVersionNumber > 1575.17) {
        CFDataRef emoji = (__bridge CFDataRef)dict()[@"CharacterSets.plist"][@".AppleColorEmojiUI"];
        NSLog(@"Compressed: %@", [self cfDataToString:emoji]);
        NSLog(@"Uncompressed: %@", [self NSDataToHex:[NSCharacterSet _emojiCharacterSet].bitmapRepresentation]);
    } else {
        NSDictionary *emoji = dict()[@"CTFontInfo.plist"][@"Attrs"][@"AppleColorEmoji"];
        if (emoji) {
            if (onlyCharset) {
                NSLog(@"AppleColorEmoji CharacterSet:");
                CFDataRef compressedData = (__bridge CFDataRef)emoji[@"NSCTFontCharacterSetAttribute"];
                NSLog(@"Compressed: %@", compressedData);
                NSLog(@"Uncompressed: %@", [self uncompressedBitmap:compressedData]);
            } else
                NSLog(@"AppleColorEmoji:\n%@", emoji);
        }
        NSDictionary *emojiUI = dict()[@"CTFontInfo.plist"][@"Attrs"][@".AppleColorEmojiUI"];
        if (emojiUI) {
            if (onlyCharset) {
                NSLog(@".AppleColorEmojiUI CharacterSet:");
                CFDataRef compressedData = (__bridge CFDataRef)emojiUI[@"NSCTFontCharacterSetAttribute"];
                NSLog(@"Compressed: %@", compressedData);
                NSLog(@"Uncompressed: %@", [self uncompressedBitmap:compressedData]);
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
    }
    NSLog(@"%@ has no relevant methods", categoryClass);
    return nil;
}

- (void)prettyPrint:(NSArray <NSString *> *)array withQuotes:(BOOL)wq asCodepoints:(BOOL)cp {
    int x = 1, perLine = 10;
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

- (void)prettyPrint:(NSArray <NSString *> *)array withQuotes:(BOOL)wq {
    [self prettyPrint:array withQuotes:wq asCodepoints:NO];
}

- (void)prettyPrint:(NSArray <NSString *> *)array {
    [self prettyPrint:array withQuotes:YES asCodepoints:NO];
}

- (void)readEmojis:(BOOL)preset withVariant:(BOOL)withVariant pretty:(BOOL)pretty {
    if (preset) {
        for (NSInteger i = 0; i <= 19; ++i) {
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
    ct = dlopen("/System/Library/Frameworks/CoreText.framework/CoreText", RTLD_LAZY);
    assert(ct != NULL);
    cs = dlopen("/Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate", RTLD_LAZY);
    if (cs) {
        MSGetImageByName = dlsym(cs, "MSGetImageByName");
        assert(MSGetImageByName != NULL);
        MSFindSymbol = dlsym(cs, "MSFindSymbol");
        assert(MSFindSymbol != NULL);
        MSImageRef ref = MSGetImageByName("/System/Library/Frameworks/CoreText.framework/CoreText");
        XTCopyUncompressedBitmapRepresentation = MSFindSymbol(ref, "__Z38XTCopyUncompressedBitmapRepresentationPKhm");
    }
    gsFont = dlopen("/System/Library/PrivateFrameworks/FontServices.framework/libGSFontCache.dylib", RTLD_LAZY);
    assert(gsFont != NULL);
    [[NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/EmojiFoundation.framework"] load];
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

- (NSArray *)charsetToArray:(NSCharacterSet *)charset {
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

- (void)printEmojiUsetCodepoints:(UProperty)property {
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
        stringLen = uset_getItem(set, i, &start, &end, buffer, sizeof(buffer)/sizeof(UChar), &error);
        if (error == U_BUFFER_OVERFLOW_ERROR) {
            string = (UChar *)malloc(sizeof(UChar) * (stringLen + 1));
            if (!string)
                return;
            error = U_ZERO_ERROR;
            uset_getItem(set, i, &start, &end, string, stringLen + 1, &error);
        }
        if (U_FAILURE(error)) {
            if (string != buffer)
                free(string);
            return;
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

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
    //[self printProfessionModifierCodepoints];
    //[self printCodepointsForPreset:10]; // skin tone emojis
    //[self printCodepointsForPreset:11]; // gender emojis
    //[self extractSkins];
    //[self readEmojis:YES withVariant:NO pretty:YES];
    //[self readFontCache:NO];
    //[self printEmojiUsetCodepoints:UCHAR_EMOJI_PRESENTATION];
    //[self printEmojiUsetCodepoints:UCHAR_EMOJI_MODIFIER];
    //[self printEmojiUsetCodepoints:UCHAR_EXTENDED_PICTOGRAPHIC];
}

@end
