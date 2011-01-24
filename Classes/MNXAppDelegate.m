#import "MNXAppDelegate.h"

@implementation MNXAppDelegate

- (void)dealloc
{
	[currentTrack release];
	[dataManager release];
	[super dealloc];
}

- (void)awakeFromNib
{
	[tracksTableView setDataSource:self];
	[tracksTableView setDelegate:self];
	[pointsTableView setDataSource:self];
	[pointsTableView setDelegate:self];
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification 
{
	// Insert code here to initialize your application 
	dataManager = [[MNXDataManager alloc] init];
	dataManager.delegate = self;
	[dataManager downloadDataFromDevice];
}

#pragma mark -

- (NSInteger)numberOfRowsInTableView:(NSTableView *)inTableView
{
	if (inTableView == tracksTableView) {
		return [dataManager.tracks count];
	}
	else if (inTableView == pointsTableView) {
		return [currentTrack.points count];
	}
	return 0;
}
- (id)tableView:(NSTableView *)inTableView objectValueForTableColumn:(NSTableColumn *)inTableColumn row:(NSInteger)inRow
{
	if (inTableView == tracksTableView) {
		return @"Track";
	}
	else if (inTableView == pointsTableView) {
		NSString *ci = [inTableColumn identifier];
		MNXPoint *point = [currentTrack.points objectAtIndex:inRow];
		if ([ci isEqualToString:@"date"]) {
			return point.date;
		}
		if ([ci isEqualToString:@"longitude"]) {
			return [NSNumber numberWithFloat:point.longitude];
		}
		if ([ci isEqualToString:@"latitude"]) {
			return [NSNumber numberWithFloat:point.latitude];
		}
		if ([ci isEqualToString:@"speed"]) {
			return [NSNumber numberWithFloat:point.speed];
		}
		if ([ci isEqualToString:@"elevation"]) {
			return [NSNumber numberWithFloat:point.elevation];
		}
	}
	return nil;
}
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	NSTableView *inTableView = [aNotification object];
	if (inTableView == tracksTableView) {
		NSInteger selectedRow = [inTableView selectedRow];
		if (selectedRow < 0) {
			self.currentTrack = nil;
			[pointsTableView reloadData];
			[[webView mainFrame] loadHTMLString:@"" baseURL:nil];
		}
		else {		
			MNXTrack *aTrack = [dataManager.tracks objectAtIndex:selectedRow];
			self.currentTrack = aTrack;
			[pointsTableView reloadData];
			NSLog(@"%@", [self.currentTrack HTML]);
			[[webView mainFrame] loadHTMLString:[self.currentTrack HTML] baseURL:nil];
		}
	}
}

#pragma mark -

- (void)downloadManagerDidStartDownloadingData:(MNXDataManager *)inManager
{
}
- (void)downloadManager:(MNXDataManager *)inManager didDownloadData:(CGFloat)inProgress
{
}
- (void)downloadManagerDidFinishDownloadingData:(MNXDataManager *)inManager
{
}
- (void)downloadManagerDidStartParsingData:(MNXDataManager *)inManager
{
}
- (void)downloadManager:(MNXDataManager *)inManager didFinishParsingData:(NSArray *)inTracks
{
	[tracksTableView reloadData];
	[pointsTableView reloadData];
}
- (void)downloadManagerCanceled:(MNXDataManager *)inManager
{
}

#pragma mark -

@synthesize currentTrack;
@synthesize window, tracksTableView, pointsTableView, webView;

@end
