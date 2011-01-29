#import "MNXAppDelegate.h"

@implementation MNXAppDelegate(SplitView)

- (NSRect)splitView:(NSSplitView *)splitView additionalEffectiveRectOfDividerAtIndex:(NSInteger)dividerIndex
{
	if (splitView == mainSplitView && dividerIndex == 0) {
		NSView *aView = [[splitView subviews] objectAtIndex:0];
		NSRect aFrame = NSMakeRect(NSMaxX([aView frame]) - 15.0, NSMaxY([aView frame]) -23.0, 15.0, 23.0);
		return aFrame;
	}
	return NSZeroRect;
}

- (BOOL)splitView:(NSSplitView *)splitView shouldCollapseSubview:(NSView *)subview forDoubleClickOnDividerAtIndex:(NSInteger)dividerIndex
{
	return NO;
}

- (BOOL)splitView:(NSSplitView *)splitView shouldHideDividerAtIndex:(NSInteger)dividerIndex
{
	return YES;
}

- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)subview
{
	if (splitView == mainSplitView) {
		if (subview == [[mainSplitView subviews] objectAtIndex:0]) {
			return NO;
		}
						
	}
	return YES;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)dividerIndex
{
	if (splitView == mainSplitView) {
		if (proposedMax > 300.0 && dividerIndex == 0) {
			return 300.0;
		}
	}	
	else if (splitView == contentSplitView) {
		if (proposedMax > ([splitView bounds].size.height / 3.0 * 2.0) && dividerIndex == 0) {
			return ([splitView bounds].size.height / 3.0 * 2.0);
		}
	}
	
	
	return proposedMax;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)dividerIndex
{
	if (splitView == mainSplitView) {
		if (proposedMin < 150.0 && dividerIndex == 0) {
			return 150.0;
		}
	}
	else if (splitView == contentSplitView) {
		if (proposedMin < ([splitView bounds].size.height / 3.0)  && dividerIndex == 0) {
			return ([splitView bounds].size.height / 3.0);
		}
	}
	
	
	return proposedMin;
}

@end
