#import "MNXWhiteBackgroundView.h"

@implementation MNXWhiteBackgroundView

- (void)drawRect:(NSRect)dirtyRect 
{
	[[NSColor whiteColor] set];
	[NSBezierPath fillRect:[self bounds]];
}

@end
