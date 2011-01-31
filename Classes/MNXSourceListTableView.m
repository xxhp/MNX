#import "MNXSourceListTableView.h"
#import "MNXAppDelegate.h"

@implementation MNXSourceListTableView

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
}

- (IBAction)delete:(id)sender
{
	[(MNXAppDelegate *)[NSApp delegate] deleteTrack:sender];	
}
- (IBAction)export:(id)sender
{
	[(MNXAppDelegate *)[NSApp delegate] export:sender];
}

- (NSMenu *)menuForEvent:(NSEvent *)event
{
	NSPoint pointInView = [self convertPoint:[event locationInWindow] fromView:nil];
	NSInteger row = [self rowAtPoint:pointInView];
	if (row < 0) {
		return nil;
	}
	[self selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
	
	NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Context Menu"];

	NSMenuItem *exportItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Export", @"") action:@selector(export:) keyEquivalent:@""];
	[exportItem setTarget:self];
	[exportItem setTag:0];
	[menu addItem:[exportItem autorelease]];	
	
	NSMenuItem *exportAllItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Export All", @"") action:@selector(export:) keyEquivalent:@""];
	[exportAllItem setTarget:self];
	[exportAllItem setTag:1];
	[menu addItem:[exportAllItem autorelease]];	

	[menu addItem:[NSMenuItem separatorItem]];
	
	NSMenuItem *deleteItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Delete", @"") action:@selector(delete:) keyEquivalent:@""];
	[deleteItem setTarget:self];
	[menu addItem:[deleteItem autorelease]];
	
	return [menu autorelease];
}

@end
