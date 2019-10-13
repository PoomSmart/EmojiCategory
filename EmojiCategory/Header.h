//
//  Header.h
//  EmojiCategory
//
//  Created by Thatchapon Unprasert on 11/10/2561 BE.
//  Copyright © 2561 Thatchapon Unprasert. All rights reserved.
//

#include <unicode/utf8.h>
#include <unicode/utypes.h>

#ifndef Header_h
#define Header_h

typedef struct USet USet;

extern USet *uset_openEmpty(void);
extern CFCharacterSetRef _CFCreateCharacterSetFromUSet(USet *);
extern void uset_applyIntPropertyValue(USet *, long long, int32_t, UErrorCode *);
extern void uset_close(USet *);
extern void uset_freeze(USet *);
extern int32_t uset_getItemCount(USet *);
extern int32_t uset_getItem(const USet *, int32_t, UChar32 *, UChar32 *, UChar *, int32_t, UErrorCode *);

@interface NSCharacterSet (EmojiFoundation)
+ (NSCharacterSet *)_emojiCharacterSet;
@end

@interface NSString (Private)
- (UChar32)_firstLongCharacter;
@end

@interface UIKeyboardEmoji : NSObject
@property() NSString *emojiString;
@end

@interface EMFEmojiCategory : NSObject
// iOS 10.2+
+ (NSArray <NSString *> *)PeopleEmoji;
+ (NSArray <NSString *> *)NatureEmoji;
+ (NSArray <NSString *> *)FoodAndDrinkEmoji;
+ (NSArray <NSString *> *)CelebrationEmoji;
+ (NSArray <NSString *> *)ActivityEmoji;
+ (NSArray <NSString *> *)TravelAndPlacesEmoji;
+ (NSArray <NSString *> *)ObjectsEmoji;
+ (NSArray <NSString *> *)SymbolsEmoji;
+ (NSArray <NSString *> *)DingbatsVariantEmoji;
+ (NSArray <NSString *> *)SkinToneEmoji;
+ (NSArray <NSString *> *)GenderEmoji;
+ (NSArray <NSString *> *)NoneVariantEmoji;
+ (NSArray <NSString *> *)ProfessionEmoji;
+ (NSArray <NSString *> *)flagEmojiCountryCodesCommon;
+ (NSArray <NSString *> *)computeEmojiFlagsSortedByLanguage; // blacklist check

// iOS < 10.2
+ (NSArray <NSString *> *)PrepopulatedEmoji;

// iOS 12+
+ (NSArray <NSString *> *)FlagsEmoji; // Non-nation flags
// iOS 13
+ (NSArray <NSString *> *)ProfessionWithoutSkinToneEmoji;
+ (NSArray <NSString *> *)CoupleMultiSkinToneEmoji;
+ (NSArray <NSString *> *)MultiPersonFamilySkinToneEmoji;
@end

@interface UIKeyboardEmojiCategory : NSObject
+ (UIKeyboardEmojiCategory *)categoryForType:(NSInteger)type;
+ (NSUInteger)hasVariantsForEmoji:(NSString *)emoji;

// iOS < 10.2
+ (NSArray <NSString *> *)PeopleEmoji;
+ (NSArray <NSString *> *)NatureEmoji;
+ (NSArray <NSString *> *)FoodAndDrinkEmoji;
+ (NSArray <NSString *> *)CelebrationEmoji;
+ (NSArray <NSString *> *)ActivityEmoji;
+ (NSArray <NSString *> *)TravelAndPlacesEmoji;
+ (NSArray <NSString *> *)ObjectsAndSymbolsEmoji;
+ (NSArray <NSString *> *)ObjectsEmoji;
+ (NSArray <NSString *> *)SymbolsEmoji;
+ (NSArray <NSString *> *)flagEmojiCountryCodesCommon;
+ (NSArray <NSString *> *)flagEmojiCountryCodesReadyToUse; // blacklist check
+ (NSArray <NSString *> *)computeEmojiFlagsSortedByLanguage; // call -flagEmojiCountryCodesReadyToUse

+ (NSArray <NSString *> *)DingbatVariantsEmoji;
+ (NSArray <NSString *> *)SkinToneEmoji;
+ (NSArray <NSString *> *)GenderEmoji;
+ (NSArray <NSString *> *)NoneVariantEmoji;
+ (NSArray <NSString *> *)PrepopulatedEmoji;

+ (NSArray <NSString *> *)loadPrecomputedEmojiFlagCategory; // empty on iOS 10.2+

// iOS 10.2+
+ (NSArray <NSString *> *)ProfessionEmoji;
+ (NSString *)emojiCategoryStringForCategoryType:(NSInteger)type;
+ (NSInteger)emojiCategoryTypeForCategoryString:(NSString *)category;

@property(retain, nonatomic) NSArray <UIKeyboardEmoji *> *emoji;
@end

@interface EmojiStringUtilities : NSObject
+ (NSString *)_stringWithUnichar:(UChar32)unichar;
+ (NSString *)_baseFirstCharacterString:(NSString *)string;
+ (NSString *)_baseStringForEmojiString:(NSString *)emojiString;
+ (NSString *)professionSkinToneEmojiBaseKey:(NSString *)emojiString;
+ (NSMutableArray <NSString *> *)_skinToneVariantsForString:(NSString *)emojiString;
+ (UChar32)_firstLongCharacterOfString:(NSString *)string;
+ (int)_skinToneForString:(NSString *)emojiString;
+ (BOOL)_emojiString:(NSString *)emojiString containsSubstring:(NSString *)substring;
+ (BOOL)_genderEmojiBaseStringNeedVariantSelector:(NSString *)emojiBaseString;
+ (BOOL)_hasSkinToneVariantsForString:(NSString *)emojiString;
@end

typedef const void *MSImageRef;
MSImageRef (*MSGetImageByName)(const char *file);
void *(*MSFindSymbol)(MSImageRef image, const char *name);

#endif /* Header_h */
