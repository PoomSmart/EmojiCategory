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

- (void)readFontCache:(BOOL)onlyCharset {
    NSDictionary *(*dict)(void) = (NSDictionary* (*)(void))dlsym(gsFont, "GSFontCacheGetDictionary");
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
            NSLog(@"%@ has no relevant methods", categoryClass);
            return nil;
        case 7:
            return [categoryClass ObjectsEmoji];
        case 8:
            return [categoryClass SymbolsEmoji];
        case 9: {
            if ([categoryClass respondsToSelector:@selector(DingbatVariantsEmoji)])
                return [categoryClass DingbatVariantsEmoji];
            if ([categoryClass respondsToSelector:@selector(DingbatsVariantEmoji)])
                return [categoryClass DingbatsVariantEmoji];
            NSLog(@"%@ has no relevant methods", categoryClass);
            return nil;
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
            NSLog(@"%@ has no relevant methods", categoryClass);
            return nil;
        case 14:
            if ([categoryClass respondsToSelector:@selector(computeEmojiFlagsSortedByLanguage)])
                return [categoryClass computeEmojiFlagsSortedByLanguage];
            if ([categoryClass respondsToSelector:@selector(loadPrecomputedEmojiFlagCategory)])
                return [categoryClass loadPrecomputedEmojiFlagCategory];
            NSLog(@"%@ has no relevant methods", categoryClass);
            return nil;
        case 15:
            if ([categoryClass respondsToSelector:@selector(FlagsEmoji)])
                return [categoryClass FlagsEmoji];
            NSLog(@"%@ has no relevant methods", categoryClass);
            return nil;
        case 16:
            return [categoryClass PrepopulatedEmoji];
    }
    return nil;
}

- (void)prettyPrint:(NSArray <NSString *> *)array {
    int x = 1, perLine = 10;
    NSMutableString *string = [NSMutableString string];
    for (NSString *substring in array) {
        [string appendString:@"@\""];
        [string appendString:substring];
        [string appendString:@"\","];
        if (x++ % perLine == 0) {
            NSLog(@"%@", string);
            string.string = @"";
        }
        else
            [string appendString:@" "];
    }
    NSLog(@"%@", string);
}

- (void)readEmojis:(BOOL)preset withVariant:(BOOL)withVariant pretty:(BOOL)pretty {
    if (preset) {
        for (NSInteger i = 0; i <= 15; i++) {
            NSLog(@"Preset %ld:", i);
            if (pretty)
                [self prettyPrint:[self emojiPreset:i]];
            else {
                for (NSString *emoji in [self emojiPreset:i]) {
                    if (withVariant)
                        NSLog(@"%@ %lu", emoji, [NSClassFromString(@"UIKeyboardEmojiCategory") hasVariantsForEmoji:emoji]);
                    else
                        NSLog(@"%@: %u", emoji, [self glyphForEmojiString:emoji]);
                }
            }
        }
    } else {
        for (NSInteger i = 0; i <= 9; i++) {
            NSLog(@"Category %ld:", i);
            if (pretty)
                [self prettyPrint:[self emojiCategory:i]];
            else {
                for (NSString *emoji in [self emojiCategory:i]) {
                    if (withVariant)
                        NSLog(@"%@ %lu", emoji, [NSClassFromString(@"UIKeyboardEmojiCategory") hasVariantsForEmoji:emoji]);
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
        length++;
    for (int i = 0; i < length; i++)
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
    assert(cs != NULL);
    MSGetImageByName = dlsym(cs, "MSGetImageByName");
    assert(MSGetImageByName != NULL);
    MSFindSymbol = dlsym(cs, "MSFindSymbol");
    assert(MSFindSymbol != NULL);
    MSImageRef ref = MSGetImageByName("/System/Library/Frameworks/CoreText.framework/CoreText");
    XTCopyUncompressedBitmapRepresentation = MSFindSymbol(ref, "__Z38XTCopyUncompressedBitmapRepresentationPKhm");
    assert(XTCopyUncompressedBitmapRepresentation != NULL);
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
    for (int plane = 0; plane <= 16; plane++) {
        if ([charset hasMemberInPlane:plane]) {
            UTF32Char c;
            for (c = plane << 16; c < (plane+1) << 16; c++) {
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

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
    //[self extractSkins];
    //[self readEmojis:YES withVariant:NO pretty:YES];
    //[self readFontCache:NO];
    //[self printEmojiUset:UCHAR_EMOJI_PRESENTATION];
    //[self printEmojiUset:UCHAR_EXTENDED_PICTOGRAPHIC];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
