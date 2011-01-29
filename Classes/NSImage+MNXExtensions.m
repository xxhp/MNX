#import "NSImage+MNXExtensions.h"

@implementation NSImage(MNXExtensions)

+ (NSImage *)calendarImageWithDate:(NSDate *)inDate
{
	NSImage *backgroundImage = [NSImage imageNamed:@"calendar"];
	if (!inDate) {
		return backgroundImage;
	}
	
	NSString *day = nil;
	NSString *month = nil;
	
	
	NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
	[formatter setDateFormat:@"d"];
	day = [formatter stringFromDate:inDate];
	[formatter setDateFormat:@"MMM"];
	month = [[formatter stringFromDate:inDate] uppercaseString];
	
	NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(487.0, 500.0)];
	NSRect imageBounds = NSMakeRect(0.0, 0.0, 487.0, 500.0);
	[image lockFocus];
	
	[[NSColor whiteColor] set];
	[NSBezierPath fillRect:imageBounds];

	[backgroundImage drawInRect:imageBounds fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
	
	NSMutableDictionary *attr = [NSMutableDictionary dictionary];
	[attr setObject:[NSFont boldSystemFontOfSize:180.0] forKey:NSFontAttributeName];
	[attr setObject:[NSColor colorWithCalibratedHue:0.0 saturation:0.0 brightness:0.0 alpha:0.9] forKey:NSForegroundColorAttributeName];
	NSMutableParagraphStyle *p = [[[NSMutableParagraphStyle alloc] init] autorelease];
	[p setAlignment:NSCenterTextAlignment];
	[attr setObject:p forKey:NSParagraphStyleAttributeName];
	
	NSMutableDictionary *monthAttr = [NSMutableDictionary dictionary];
	[monthAttr setObject:[NSFont boldSystemFontOfSize:55.0] forKey:NSFontAttributeName];
	[monthAttr setObject:[NSColor colorWithCalibratedHue:0.0 saturation:0.0 brightness:1.0 alpha:0.9] forKey:NSForegroundColorAttributeName];
	[monthAttr setObject:p forKey:NSParagraphStyleAttributeName];
	
	NSRect dayFrame = NSMakeRect(90.0, 80.0, imageBounds.size.width - 90.0, 200.0);
	NSRect monthFrame = NSMakeRect(120.0, 255.0, 150.0, 90.0);	
	
	NSAffineTransform *transform = [NSAffineTransform transform];
	[transform rotateByDegrees:10.0];
	[transform concat];
	[day drawInRect:dayFrame withAttributes:attr];
	[month drawInRect:monthFrame withAttributes:monthAttr];	
	[transform invert];	
	[image unlockFocus];
	return [image autorelease];
}

@end
