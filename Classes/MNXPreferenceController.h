#import <Cocoa/Cocoa.h>

@interface MNXPreferenceController : NSWindowController
	<NSOutlineViewDataSource, NSOutlineViewDelegate>
{
	NSMatrix *timezoneMatrix;
	NSOutlineView *timeZoneOutlineView;
	NSMutableArray *groupedTimeZones;
}

- (void)refresh;
- (void)deselectAllTimeZone;
- (void)setNewTimeZoneSettingWithName:(NSString *)newTimeZoneName;
- (IBAction)changeTimezoneSettingAction:(id)sender;


@property (assign) IBOutlet NSMatrix *timezoneMatrix;
@property (assign) IBOutlet NSOutlineView *timeZoneOutlineView;
@property (readonly) NSUndoManager *undoManager;


@end
