#import "NSString+Extension.h"

@implementation NSString(Extension)
@end

NSString *NSStringFromNSTimeInterval(NSTimeInterval interval)
{
	if (interval <= 0.0) {
		return @"--:--";
	}
	
	double seconds = fmod(interval, 60.0);
	double minutes = interval / 60.0;
	double hours = interval / (60.0 * 60.0);
	if (hours >= 1.0) {
		return [NSString stringWithFormat:@"%d:%02d:%02d", (NSInteger)hours, (NSInteger)minutes % 60, (NSInteger)seconds];
	}
	return [NSString stringWithFormat:@"%02d:%02d", (NSInteger)minutes, (NSInteger)seconds];
}
NSString *LocalizedStringFromNSTimeInterval(NSTimeInterval interval)
{
	if (interval <= 0.0) {
		return nil;
	}
	
	double seconds = fmod(interval, 60.0);
	double minutes = interval / 60.0;
	NSString *secondString = NSLocalizedString(@"sec", @"");
	NSString *minuteString = NSLocalizedString(@"min", @"");
	double hours = interval / (60.0 * 60.0);
	if (hours >= 1.0) {
		NSString *hourString = NSLocalizedString(@"hr", @"");
		return [NSString stringWithFormat:@"%d %@ %d %@ %d %@", (NSInteger)hours, hourString, (NSInteger)minutes % 60, minuteString, (NSInteger)seconds, secondString];
	}		
	return [NSString stringWithFormat:@"%d %@ %d %@", (NSInteger)minutes, minuteString, (NSInteger)seconds, secondString];
}
