#import "NSColor+MNXExtension.h"

@implementation NSColor(MNXExtension)

+ (NSColor *)speedLineColor
{
	return [NSColor colorWithCalibratedHue:0.5 saturation:1.0 brightness:0.5 alpha:1.0];
}
+ (NSColor *)speedBackgroundColorColor
{
	return [NSColor colorWithCalibratedHue:0.5 saturation:1.0 brightness:0.5 alpha:0.6];
}
+ (NSColor *)elevationLineColor
{
	return [NSColor colorWithCalibratedHue:0.1 saturation:1.0 brightness:0.5 alpha:1.0];
}
+ (NSColor *)elevationBackgroundColorColor
{
	return [NSColor colorWithCalibratedHue:0.1 saturation:1.0 brightness:0.5 alpha:0.6];
}

@end
