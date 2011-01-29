#import "MNXAdditionalSplitDeviderView.h"

@implementation MNXAdditionalSplitDeviderView

- (void)drawRect:(NSRect)dirtyRect 
{
	[[NSColor whiteColor] set];
	[NSBezierPath fillRect:[self bounds]];
	NSImage *backgroundImage = [NSImage imageNamed:@"sidebarStatusAreaBackground"];
	[backgroundImage drawInRect:[self bounds] fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
	NSImage *image = [NSImage imageNamed:@"sidebarResizeWidget"];
	NSRect imageFrame = NSMakeRect([self bounds].size.width - 15.0, 0.0, 15.0, 23.0);
	[image drawInRect:imageFrame fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
	
}

@end
