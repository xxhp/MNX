#import "MNXTransparentWindow.h"
#import "NSLocale+MNXExtension.h"
#import "MNXPoint.h"

@implementation MNXInfoBackgroundView

- (void)drawRect:(NSRect)dirtyRect
{
	NSBezierPath *path = [NSBezierPath bezierPath];
	[path moveToPoint:NSMakePoint(0.0, 10.0)];
	[path lineToPoint:NSMakePoint(([self bounds].size.width / 2.0) - 5.0, 10.0)];
	[path lineToPoint:NSMakePoint([self bounds].size.width / 2.0, 0.0)];
	[path lineToPoint:NSMakePoint(([self bounds].size.width / 2.0) + 5.0, 10.0)];
	[path lineToPoint:NSMakePoint(NSMaxX([self bounds]), 10.0)];
	[path lineToPoint:NSMakePoint(NSMaxX([self bounds]), NSMaxY([self bounds]))];
	[path lineToPoint:NSMakePoint(NSMinX([self bounds]), NSMaxY([self bounds]))];
	[path closePath];
	[[NSColor whiteColor] set];
	[path fill];
//	[[NSColor blackColor] setStroke];
//	[path stroke];
}

@end


@implementation MNXTransparentWindow

- (void)dealloc
{
	[formatter release];
	[textField release];
	[super dealloc];
}


- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)windowStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)deferCreation
{
	self = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:bufferingType defer:deferCreation];
	if (self != nil) {
		MNXInfoBackgroundView *aView = [[[MNXInfoBackgroundView alloc] initWithFrame:NSZeroRect] autorelease];
		[self setContentView:aView];
		[self setBackgroundColor:[NSColor clearColor]];
		[self setAlphaValue:1.0];
		[self setHasShadow:YES];
		[self setOpaque:NO];
		textField = [[NSTextField alloc] initWithFrame:NSMakeRect(10.0, 20.0, [self frame].size.width - 20.0, [self frame].size.height - 30.0)];
		[textField setEditable:NO];
		[textField setSelectable:NO];
		[textField setBezeled:NO];
		[textField setBackgroundColor:[NSColor clearColor]];
		[textField setFont:[NSFont systemFontOfSize:11.0]];
		[[self contentView] addSubview:textField];
		
		formatter = [[NSDateFormatter alloc] init];
		[formatter setDateStyle:NSDateFormatterShortStyle];
		[formatter setTimeStyle:NSDateFormatterShortStyle];
	}
	return self;
}

- (BOOL)canBecomeKeyWindow
{
	return NO;
}

- (BOOL)canBecomeMainWindow
{
	return NO;
}

- (void)setPoint:(MNXPoint *)inPoint
{
	NSMutableString *s = [NSMutableString string];
	[s appendString:[formatter stringFromDate:inPoint.date]];
	[s appendString:@"\n"];
	CGFloat speed = 0.0;
	NSString *unit = @"";
	if ([NSLocale usingUSMeasurementUnit]) {
		speed = inPoint.speedMile;
		unit = NSLocalizedString(@"ml/h", @"");
	}
	else {
		speed = inPoint.speedKM;
		unit = NSLocalizedString(@"km/h", @"");
	}
												
	[s appendFormat:@"%@ %.1f %@", NSLocalizedString(@"Speed:", @""), speed, unit];
//	[s appendString:@"\n"];
//	CGFloat elevation = inPoint.elevation;
//	if ([NSLocale usingUSMeasurementUnit]) {
//		[s appendFormat:@"%@ %d %@", NSLocalizedString(@"Elevation:", @""), (NSInteger)(elevation * 3.2808399), NSLocalizedString(@"ft", @"")];
//	}
//	else {
//		[s appendFormat:@"%@ %d %@", NSLocalizedString(@"Elevation:", @""), (NSInteger)elevation, NSLocalizedString(@"m", @"")];
//	}
	[self setText:s];
}

- (void)setText:(NSString *)inText
{
	[textField setStringValue:inText];
	[textField sizeToFit];
	NSRect textFrame = [textField frame];
	textFrame.origin.x = 5.0;
	textFrame.origin.y = 15.0;
	
	NSSize textSize = textFrame.size;
	NSRect winFrame = [self frame];
	winFrame.size = NSMakeSize(textSize.width + 10.0, textSize.height + 20.0);
	[self setFrame:winFrame display:NO];
	[textField setFrame:textFrame];
	
}

@end
