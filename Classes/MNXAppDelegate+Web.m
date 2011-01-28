#import "MNXAppDelegate.h"

@implementation MNXAppDelegate(Web)

// Drop to our web view
- (NSUInteger)webView:(WebView *)sender dragDestinationActionMaskForDraggingInfo:(id <NSDraggingInfo>)draggingInfo
{
	return WebDragSourceActionNone;
}

// Drag from our web view
- (NSUInteger)webView:(WebView *)sender dragSourceActionMaskForPoint:(NSPoint)point
{
	return WebDragSourceActionNone;
}

- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems
{
	return nil;
}

@end
