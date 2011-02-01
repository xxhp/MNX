#import <Cocoa/Cocoa.h>
#import "MNXTrack.h"
#import "MNXPoint.h"
#import "MNXTransparentWindow.h"

@interface MNXSpeedView : NSView
{
	MNXTrack *currentTrack;
	
	CFMachPortRef eventTapPortRef;
	CFRunLoopSourceRef source;
	
	MNXTransparentWindow *infoWindow;
	CGFloat currentMaxSpeedMile;
	CGFloat currentMaxSpeedKM;
	
	NSArray *reducedPointsArray;
}

- (void)startTracking;
- (void)endTracking;
- (void)showInfoWindowWithEvent:(CGEventRef)inEvent;

@property (retain, nonatomic) MNXTrack *currentTrack;

@end
