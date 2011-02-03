#import "MNXSourceListTableView.h"
#import "MNXAppDelegate.h"

@implementation MNXSourceListTableView

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

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if ([menuItem action] == @selector(delete:) || [menuItem action] == @selector(export:)) {
		if ([self selectedRow] < 0) {
			return NO;
		}
	}
	if ([menuItem action] == @selector(selectAll:)) {
		return NO;
	}
	
	return YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
	if (!noData) {
		return;
	}
	
	NSMutableDictionary *attr = [NSMutableDictionary dictionary];
	[attr setObject:[NSFont boldSystemFontOfSize:13.0] forKey:NSFontAttributeName];
	NSMutableParagraphStyle *p = [[[NSMutableParagraphStyle alloc] init] autorelease];
	[p setAlignment:NSCenterTextAlignment];
	[attr setObject:p forKey:NSParagraphStyleAttributeName];
	[attr setObject:[NSColor darkGrayColor] forKey:NSForegroundColorAttributeName];
	NSShadow *aShadow = [[NSShadow alloc] init];
	[aShadow setShadowBlurRadius:2.0];
	[aShadow setShadowOffset:NSMakeSize(0.0, -1.0)];
	[aShadow setShadowColor:[NSColor whiteColor]];
	[attr setObject:aShadow forKey:NSShadowAttributeName];
	
	
	NSString *text = NSLocalizedString(@"You do not have any activity yet, please download data from your GPS device.", @"");
	NSSize aSize = NSMakeSize([self bounds].size.width - 20.0, [self bounds].size.height);
	NSRect aFrame = [text boundingRectWithSize:aSize options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingTruncatesLastVisibleLine attributes:attr];
	
	aFrame.origin.y = 20.0; 
	aFrame.origin.x = 10.0;
	[text drawInRect:aFrame withAttributes:attr];
}
		
		
@synthesize noData;

@end
