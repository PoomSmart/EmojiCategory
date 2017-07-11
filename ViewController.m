//
//  ViewController.m
//  EmojiCategory
//
//  Created by Thatchapon Unprasert on 8/2/16.
//  Copyright © 2016 Thatchapon Unprasert. All rights reserved.
//

#import "ViewController.h"
#import <dlfcn.h>

@interface ViewController () {
    void *ct;
    void *gsFont;
#ifdef USE
    CFDataRef (*XTCopyUncompressedBitmapRepresentation)(const UInt8 *, CFIndex);
#endif
}
@end

@interface UIKeyboardEmoji : NSObject
@property() NSString *emojiString;
@end

@interface EMFEmojiCategory : NSObject
// iOS 10.2+
+ (NSArray *)PeopleEmoji;
+ (NSArray *)NatureEmoji;
+ (NSArray *)FoodAndDrinkEmoji;
+ (NSArray *)CelebrationEmoji;
+ (NSArray *)ActivityEmoji;
+ (NSArray *)TravelAndPlacesEmoji;
+ (NSArray *)ObjectsEmoji;
+ (NSArray *)SymbolsEmoji;
+ (NSArray *)DingbatsVariantEmoji;
+ (NSArray *)SkinToneEmoji;
+ (NSArray *)GenderEmoji;
+ (NSArray *)NoneVariantEmoji;
+ (NSArray *)ProfessionEmoji;
+ (NSArray *)flagEmojiCountryCodesCommon;
+ (NSArray *)computeEmojiFlagsSortedByLanguage; // blacklist check

// iOS < 10.2
+ (NSArray *)PrepopulatedEmoji;
@end

@interface UIKeyboardEmojiCategory : NSObject
+ (UIKeyboardEmojiCategory *)categoryForType:(NSInteger)type;
+ (NSUInteger)hasVariantsForEmoji:(NSString *)emoji;

// iOS < 10.2
+ (NSArray *)PeopleEmoji;
+ (NSArray *)NatureEmoji;
+ (NSArray *)FoodAndDrinkEmoji;
+ (NSArray *)CelebrationEmoji;
+ (NSArray *)ActivityEmoji;
+ (NSArray *)TravelAndPlacesEmoji;
+ (NSArray *)ObjectsAndSymbolsEmoji;
+ (NSArray *)ObjectsEmoji;
+ (NSArray *)SymbolsEmoji;
+ (NSArray *)flagEmojiCountryCodesCommon;
+ (NSArray *)flagEmojiCountryCodesReadyToUse; // blacklist check
+ (NSArray *)computeEmojiFlagsSortedByLanguage; // call -flagEmojiCountryCodesReadyToUse

+ (NSArray *)DingbatVariantsEmoji;
+ (NSArray *)SkinToneEmoji;
+ (NSArray *)GenderEmoji;
+ (NSArray *)NoneVariantEmoji;
+ (NSArray *)PrepopulatedEmoji;

+ (NSArray *)loadPrecomputedEmojiFlagCategory; // empty on iOS 10.2+

// iOS 10.2+
+ (NSArray *)ProfessionEmoji;
+ (NSString *)emojiCategoryStringForCategoryType:(NSInteger)type;
+ (NSInteger)emojiCategoryTypeForCategoryString:(NSString *)category;

@property(retain, nonatomic) NSArray <UIKeyboardEmoji *> *emoji;
@end

@implementation ViewController

- (CFDataRef)uncompressedBitmap:(CFDataRef)compressedData {
#ifdef USE
    if (XTCopyUncompressedBitmapRepresentation == NULL) {
        NSLog(@"Error: XTCopyUncompressedBitmapRepresentation not found");
        return compressedData;
    }
    CFDataRef uncompressedData = XTCopyUncompressedBitmapRepresentation(CFDataGetBytePtr(compressedData), CFDataGetLength(compressedData));
    CFRelease(compressedData);
    return uncompressedData;
#else
    return compressedData;
#endif
}

- (void)readFontCache:(BOOL)onlyCharset {
    NSDictionary *(*dict)() = (NSDictionary* (*)())dlsym(gsFont, "GSFontCacheGetDictionary");
    NSDictionary *emoji = dict()[@"CTFontInfo.plist"][@"Attrs"][@"AppleColorEmoji"];
    if (emoji) {
        if (onlyCharset) {
            NSLog(@"AppleColorEmoji CharacterSet:");
            CFDataRef compressedData = (__bridge CFDataRef)emoji[@"NSCTFontCharacterSetAttribute"];
            NSLog(@"Compressed: %@", compressedData);
#ifdef USE
            NSLog(@"Uncompressed: %@", [self uncompressedBitmap:compressedData]);
#endif
        } else
            NSLog(@"AppleColorEmoji:\n%@", emoji);
    }
    NSDictionary *emojiUI = dict()[@"CTFontInfo.plist"][@"Attrs"][@".AppleColorEmojiUI"];
    if (emojiUI) {
        if (onlyCharset) {
            NSLog(@".AppleColorEmojiUI CharacterSet:");
            CFDataRef compressedData = (__bridge CFDataRef)emojiUI[@"NSCTFontCharacterSetAttribute"];
            NSLog(@"Compressed: %@", compressedData);
#ifdef USE
            NSLog(@"Uncompressed: %@", [self uncompressedBitmap:compressedData]);
#endif
        } else
            NSLog(@".AppleColorEmojiUI:\n%@", emoji);
    }
}

- (NSArray *)emojiCategory:(NSInteger)type {
    NSArray <UIKeyboardEmoji *> *emojiArray = [NSClassFromString(@"UIKeyboardEmojiCategory") categoryForType:type].emoji;
    NSMutableArray <NSString *> *emojiArray_ = [NSMutableArray arrayWithCapacity:emojiArray.count];
    for (UIKeyboardEmoji *emoji in emojiArray)
        [emojiArray_ addObject:emoji.emojiString];
    return emojiArray_;
}

- (Class)categoryClass:(NSInteger)type {
    return kCFCoreFoundationVersionNumber >= 1348.22 || type == 14 ? NSClassFromString(@"EMFEmojiCategory") : NSClassFromString(@"UIKeyboardEmojiCategory");
}

- (NSArray *)emojiPreset:(NSInteger)type {
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
        if (++x % perLine == 0)
            [string appendString:@"\n"];
        else
            [string appendString:@" "];
    }
    NSLog(@"%@", string);
}

- (void)readEmojis:(BOOL)preset withVariant:(BOOL)withVariant pretty:(BOOL)pretty {
    if (preset) {
        for (NSInteger i = 0; i <= 14; i++) {
            NSLog(@"Preset %ld:", i);
            if (pretty)
                [self prettyPrint:[self emojiPreset:i]];
            else {
                for (NSString *emoji in [self emojiPreset:i]) {
                    if (withVariant)
                        NSLog(@"%@ %lu", emoji, [NSClassFromString(@"UIKeyboardEmojiCategory") hasVariantsForEmoji:emoji]);
                    else
                        NSLog(@"%@", emoji);
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

- (void)setup {
    ct = dlopen("/System/Library/Frameworks/CoreText.framework/CoreText", RTLD_LAZY);
    assert(ct != NULL);
    gsFont = dlopen("/System/Library/PrivateFrameworks/FontServices.framework/libGSFontCache.dylib", RTLD_LAZY);
    assert(gsFont != NULL);
    [[NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/EmojiFoundation.framework"] load];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
    [self readEmojis:NO withVariant:YES pretty:NO];
    //[self readFontCache:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
