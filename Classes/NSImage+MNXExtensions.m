#import "NSImage+MNXExtensions.h"
#import "NSData+MBBase64.h"

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

+ (NSImage *)imageWithText:(NSString *)inText additionalText:(NSString *)inAdditionalText color:(NSColor *)inColor
{
	CGFloat width = 20.0;
	CGFloat height= 20.0;
	
	NSMutableDictionary *attr = [NSMutableDictionary dictionary];
	[attr setObject:[NSFont boldSystemFontOfSize:11.0] forKey:NSFontAttributeName];
	[attr setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
	NSMutableParagraphStyle *style = [[[NSMutableParagraphStyle alloc] init] autorelease];
	[style setAlignment:NSCenterTextAlignment];
	[attr setObject:style forKey:NSParagraphStyleAttributeName];

	NSMutableDictionary *additionalAttr = [NSMutableDictionary dictionaryWithDictionary:attr];
	[additionalAttr setObject:[NSFont systemFontOfSize:9.0] forKey:NSFontAttributeName];
	
	NSRect textBounds = [inText boundingRectWithSize:NSMakeSize(400.0, 400.0) options:NSStringDrawingTruncatesLastVisibleLine attributes:attr];
	NSRect additionalBounds = NSZeroRect;

	if (width < textBounds.size.width + 10.0) {
		width = textBounds.size.width + 10.0;
	}
	if (height < textBounds.size.height + 20.0) {
		height = textBounds.size.height + 20.0;
	}
	
	if ([inAdditionalText length]) {
		additionalBounds = [inText boundingRectWithSize:NSMakeSize(400.0, 400.0) options:NSStringDrawingTruncatesLastVisibleLine attributes:attr];
		if (width < additionalBounds.size.height + 10.0) {
			width = textBounds.size.width + 10.0;
		}		
		height = height + textBounds.size.height + 10.0;
	}
	
	NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(width, height)];
	
	[image lockFocus];
	[NSGraphicsContext saveGraphicsState];
	[[NSGraphicsContext currentContext] setShouldAntialias:YES];
	[inColor setFill];
	[[NSColor blackColor] setStroke];
	
	NSBezierPath *path = [NSBezierPath bezierPath];
	[path moveToPoint:NSMakePoint(0.0, 15.0)];
	[path lineToPoint:NSMakePoint(width / 2.0 - 2.0, 15.0)];
	[path lineToPoint:NSMakePoint(width / 2.0, 0.0)];
	[path lineToPoint:NSMakePoint(width / 2.0 + 2.0, 15.0)];
	[path lineToPoint:NSMakePoint(width, 15.0)];
	[path lineToPoint:NSMakePoint(width, height)];
	[path lineToPoint:NSMakePoint(0.0, height)];
	[path closePath];
	[path fill];
	[path setLineWidth:2.0];
	[path stroke];
	
	textBounds.origin.y = height - textBounds.size.height - 2.0;
	textBounds.size.width = width;
	
	[inText drawInRect:textBounds withAttributes:attr];
	
	if ([inAdditionalText length]) {
		additionalBounds.origin.y = NSMinY(textBounds) - additionalBounds.size.height;
		additionalBounds.size.width = width;
		[inAdditionalText drawInRect:additionalBounds withAttributes:additionalAttr];
	}
	[NSGraphicsContext restoreGraphicsState];
	
	[image unlockFocus];
	
	[image autorelease];
	return image;
}

+ (NSString *)base64ImageWithText:(NSString *)inText additionalText:(NSString *)inAdditionalText color:(NSColor *)inColor;
{
	NSImage *image = [NSImage imageWithText:inText additionalText:inAdditionalText color:inColor];
	return [[image TIFFRepresentation] base64Encoding];
}

@end
