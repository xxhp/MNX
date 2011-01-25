#import "MNXTrackCell.h"

@implementation MNXTrackCell

- (id)init
{
	self = [super init];
	if (self != nil) {
		[self setFont:[NSFont boldSystemFontOfSize:12.0]];
	}
	return self;
}


- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSImage *image = [NSImage imageNamed:@"pin"];
	if ([self isHighlighted]) {
		image = [NSImage imageNamed:@"pinHighlight"];
	}
	
	NSRect imageFeame = NSMakeRect(NSMinX(cellFrame) + 10.0, NSMinY(cellFrame) + (cellFrame.size.height - 16.0) / 2.0, 9.0, 16.0);
	[image drawInRect:imageFeame fromRect:NSMakeRect(0.0, 0.0, [image size].width, [image size].height) operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];
	NSRect newFrame = NSMakeRect(NSMinX(cellFrame) + 25.0, NSMinY(cellFrame), cellFrame.size.width - 25.0, cellFrame.size.height);
	[super drawWithFrame:newFrame inView:controlView];
}

@end
