#import <Cocoa/Cocoa.h>

@interface NSImage(MNXExtensions)
+ (NSImage *)calendarImageWithDate:(NSDate *)inDate;
+ (NSImage *)imageWithText:(NSString *)inText additionalText:(NSString *)inAdditionalText color:(NSColor *)inColor;
+ (NSString *)base64ImageWithText:(NSString *)inText additionalText:(NSString *)inAdditionalText color:(NSColor *)inColor;
@end
