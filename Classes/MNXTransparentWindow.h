#import <Cocoa/Cocoa.h>
#import "MNXPoint.h"

@interface MNXInfoBackgroundView: NSView
{
}
@end

@interface MNXTransparentWindow : NSWindow
{
	NSTextField *textField;	
	NSDateFormatter *formatter;
}

- (void)setPoint:(MNXPoint *)inPoint;
- (void)setText:(NSString *)inText;

@end
