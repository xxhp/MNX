#import <Cocoa/Cocoa.h>
#import "MNXTrack.h"
#import "MNXPoint.h"

@interface MNXSpeedView : NSView
{
	MNXTrack *currentTrack;
}

@property (retain, nonatomic) MNXTrack *currentTrack;

@end
