#import "MNXSelectionController.h"
#import "MNXTrack.h"

@implementation MNXSelectionController

- (void)dealloc
{
	delegate = nil;
	[tracks release];
	[selectedRows release];
	[super dealloc];
}


- (id)init
{
	self = [super init];
	if (self != nil) {
		[NSBundle loadNibNamed:NSStringFromClass([self class]) owner:self];
		tracks = [[NSMutableArray alloc] init];
		selectedRows = [[NSMutableIndexSet alloc] init];
	}
	return self;
}

- (void)awakeFromNib
{
	[tableView setDelegate:self];
	[tableView setDataSource:self];
}

- (IBAction)cancel:(id)sender
{
	[delegate selectionControllerCancelled:self];
}
- (IBAction)done:(id)sender
{
	[delegate selectionController:self didSelectTracks:self.selectedTracks];
}

#pragma mark -

- (NSInteger)numberOfRowsInTableView:(NSTableView *)inTableView
{
	return [tracks count];
}
- (id)tableView:(NSTableView *)inTableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	if ([[tableColumn identifier] isEqualToString:@"name"]) {
		MNXTrack *track = [tracks objectAtIndex:row];
		return track.title;
	}
	else if ([[tableColumn identifier] isEqualToString:@"checked"]) {
		return [NSNumber numberWithBool:[selectedRows containsIndex:row]];
	}														 	
	return nil;
}
- (void)tableView:(NSTableView *)inTableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row;
{
	if ([object boolValue]) {
		[selectedRows addIndex:row];
	}
	else {
		[selectedRows removeIndex:row];
	}
	
	[inTableView reloadData];
}

#pragma mark -

- (void)setTracks:(NSArray *)inTracks
{
	[tracks setArray:inTracks];
	[selectedRows removeAllIndexes];
	[selectedRows addIndexesInRange:NSMakeRange(0, [tracks count])];
	[tableView reloadData];
}

- (NSArray *)tracks
{
	return tracks;
}

- (NSArray *)selectedTracks
{
	NSMutableArray *a = [NSMutableArray array];
	[selectedRows enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
		[a addObject:[tracks objectAtIndex:idx]];
	}];
	return a;
}

@synthesize delegate;
@synthesize tableView;

@end
