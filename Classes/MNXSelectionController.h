#import <Cocoa/Cocoa.h>

@class MNXSelectionController;

@protocol MNXSelectionControllerDelegate
- (void)selectionController:(MNXSelectionController *)inController didSelectTracks:(NSArray *)inTracks;
- (void)selectionControllerCancelled:(MNXSelectionController *)inController;
@end


@interface MNXSelectionController : NSWindowController <NSTableViewDelegate, NSTableViewDataSource>
{
	id <MNXSelectionControllerDelegate> delegate;
	NSTableView *tableView;

	NSMutableArray *tracks;
	NSMutableIndexSet *selectedRows;
}

//- (IBAction)selectAll:(id)sender;
//- (IBAction)selectNone:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)done:(id)sender;

@property (assign, nonatomic) id <MNXSelectionControllerDelegate> delegate;
@property (assign) IBOutlet NSTableView *tableView;
@property (retain, nonatomic) NSArray *tracks;
@property (readonly) NSArray *selectedTracks;

@end
