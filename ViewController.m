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
+ (NSArray *)DingbatVariantsEmoji; // iOS < 11.0
+ (NSArray *)DingbatsVariantEmoji; // iOS 11.0+
+ (NSArray *)SkinToneEmoji;
+ (NSArray *)GenderEmoji;
+ (NSArray *)NoneVariantEmoji;

// iOS < 10.2
+ (NSArray *)PrepopulatedEmoji;
@end

@interface UIKeyboardEmojiCategory : NSObject
+ (UIKeyboardEmojiCategory *)categoryForType:(NSInteger)type;

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
+ (NSArray *)DingbatVariantsEmoji;
+ (NSArray *)SkinToneEmoji;
+ (NSArray *)GenderEmoji;
+ (NSArray *)NoneVariantEmoji;
+ (NSArray *)PrepopulatedEmoji;

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
            if (![categoryClass instancesRespondToSelector:@selector(ObjectsAndSymbolsEmoji)]) {
                NSLog(@"%@ does not provide ObjectsAndSymbols", categoryClass);
                return nil;
            }
            return [categoryClass ObjectsAndSymbolsEmoji];
        case 7:
            return [categoryClass ObjectsEmoji];
        case 8:
            return [categoryClass SymbolsEmoji];
        case 9: {
            if ([categoryClass instancesRespondToSelector:@selector(DingbatVariantsEmoji)])
                return [categoryClass DingbatVariantsEmoji];
            if ([categoryClass instancesRespondToSelector:@selector(DingbatsVariantEmoji)])
                return [categoryClass DingbatsVariantEmoji];
            NSLog(@"%@ completely changed Dingbat(s)Variant(s) selector", categoryClass);
            return nil;
        }
        case 10:
            return [categoryClass SkinToneEmoji];
        case 11:
            return [categoryClass GenderEmoji];
        case 12:
            return [categoryClass NoneVariantEmoji];
        case 13:
            if (![categoryClass instancesRespondToSelector:@selector(ProfessionEmoji)]) {
                NSLog(@"%@ does not provide ProfessionEmoji", categoryClass);
                return nil;
            }
            return [categoryClass ProfessionEmoji];
        case 14:
            return [categoryClass PrepopulatedEmoji];
    }
    return nil;
}

- (void)readEmojis:(BOOL)preset {
    if (preset) {
        for (NSInteger i = 0; i <= 14; i++) {
            NSLog(@"Preset %ld:", i);
            for (NSString *emoji in [self emojiPreset:i])
                NSLog(@"%@", emoji);
        }
    } else {
        for (NSInteger i = 0; i <= 9; i++) {
            NSLog(@"Category %ld:", i);
            for (NSString *emoji in [self emojiCategory:i])
                NSLog(@"%@", emoji);
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
    [self readEmojis:YES];
    //[self readFontCache:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
