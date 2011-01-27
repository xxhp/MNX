#import <Cocoa/Cocoa.h>
#import "MNXTrack.h"
#import "MNXPoint.h"

@interface MNXSpeedView : NSView
{
	NSImage *image;
	MNXTrack *currentTrack;
}

@property (retain, nonatomic) NSImage *image;
@property (retain, nonatomic) MNXTrack *currentTrack;

@end
