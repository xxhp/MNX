#import "NSLocale+MNXExtension.h"

@implementation NSLocale(MNXExtension)

+ (BOOL)usingUSMeasurementUnit
{
	NSLocale *currentLocale = [NSLocale currentLocale];
	NSString *measureUnit = [currentLocale objectForKey:NSLocaleMeasurementSystem];
	if ([measureUnit isEqualToString:@"U.S."]) {
		return YES;
	}
	return NO;	
}

@end
