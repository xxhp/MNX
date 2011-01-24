#import "MNXAppDelegate.h"

static NSString *const kPortPopUpButtonItem = @"kPortPopUpButtonItem";
static NSString *const kDownloadItem = @"kDownloadItem";

@implementation MNXAppDelegate

- (void)dealloc
{
	[currentTrack release];
	[dataManager release];
	[super dealloc];
}

- (void)awakeFromNib
{
	NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier:@"toolbar"] autorelease];
	[toolbar setDelegate:self];
	[window setToolbar:toolbar];	
	
	[tracksTableView setDataSource:self];
	[tracksTableView setDelegate:self];
	[pointsTableView setDataSource:self];
	[pointsTableView setDelegate:self];
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification 
{
	dataManager = [[MNXDataManager alloc] init];
	dataManager.delegate = self;
	[self updatePorts];
}

#pragma mark -

- (void)updatePorts
{
	NSArray *ports = [[AMSerialPortList sharedPortList] serialPorts];
	NSMutableArray *a = [NSMutableArray array];
	for (AMSerialPort *p in ports) {
		if ([[p type] isEqualToString:[NSString stringWithUTF8String:kIOSerialBSDModemType]]) {
			[a addObject:p];
		}
	}
	
	[portListArrayController setContent:[NSMutableArray arrayWithArray:a]];	
}

- (IBAction)download:(id)sender
{
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

#pragma mark -

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag;
{
	if ([itemIdentifier isEqualToString:kPortPopUpButtonItem]) {
		NSToolbarItem *item = [[[NSToolbarItem alloc] initWithItemIdentifier:kPortPopUpButtonItem] autorelease];
		[item setLabel:@"Device"];
		[item setToolTip:@"Device"];
		[item setView:portPopUpButton];
		[item setMaxSize:NSMakeSize(200.0, 32.0)];
		[item setMinSize:NSMakeSize(120.0, 32.0)];
		return item;
	}
	if ([itemIdentifier isEqualToString:kDownloadItem]) {
		NSToolbarItem *item = [[[NSToolbarItem alloc] initWithItemIdentifier:kDownloadItem] autorelease];
		[item setLabel:@"Download"];
		[item setToolTip:@"Download"];
		[item setTarget:self];
		[item setAction:@selector(download:)];
		return item;
	}
	
	return nil;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
	return [NSArray arrayWithObjects:kPortPopUpButtonItem, kDownloadItem, nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
	return [NSArray arrayWithObjects:kPortPopUpButtonItem, kDownloadItem, nil];
}


#pragma mark -

@synthesize currentTrack;
@synthesize window, tracksTableView, pointsTableView, webView;
@synthesize sheetWindow, messageLabel, progressIndicator;
@synthesize portListArrayController;
@synthesize portPopUpButton;

@end
