#import "MNXAppDelegate.h"

static NSString *const kPortPopUpButtonItem = @"kPortPopUpButtonItem";
static NSString *const kDownloadItem = @"kDownloadItem";

@implementation MNXAppDelegate

- (void)dealloc
{
	[currentTrack release];
	[dateFormatter release];
	[dataManager release];
	[super dealloc];
}

- (void)awakeFromNib
{
	NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier:@"toolbar"] autorelease];
	[toolbar setDelegate:self];
	[window setToolbar:toolbar];
	[window setExcludedFromWindowsMenu:YES];
	
	[tracksTableView setDataSource:self];
	[tracksTableView setDelegate:self];
	[pointsTableView setDataSource:self];
	[pointsTableView setDelegate:self];
	
	dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateStyle:NSDateFormatterShortStyle];
	[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
}

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
		
	NSMenu *menu = [[[NSMenu alloc] initWithTitle:@"Devices"] autorelease];
	NSUInteger tag = 0;
	for (AMSerialPort *p in a) {
		NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[p name] action:@selector(selectDevice:) keyEquivalent:@""];
		[menuItem setTarget:self];
		[menuItem setTag:tag++];
		[menu addItem:menuItem];
	}
	[deviceListMenuItem setSubmenu:menu];
	
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification 
{
	dataManager = [[MNXDataManager alloc] init];
	dataManager.delegate = self;
	[self updatePorts];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didAddPorts:) name:AMSerialPortListDidAddPortsNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRemovePorts:) name:AMSerialPortListDidRemovePortsNotification object:nil];
}

#pragma mark -

- (IBAction)download:(id)sender
{
	if (![[portListArrayController selectedObjects] count]) {
		return;
	}
	
	AMSerialPort *port = [[portListArrayController selectedObjects] lastObject];
	[dataManager downloadDataFromPort:port];
}
- (IBAction)cancelDownload:(id)sender
{
	[dataManager cancelDownload];
}
- (IBAction)selectDevice:(id)sender
{
	[portListArrayController setSelectionIndex:[sender tag]];
}
- (IBAction)exportGPX:(id)sender
{
	if ([tracksTableView selectedRow] < 0) {
		return;
	}
	if (![dataManager.tracks count]) {
		return;
	}	
	
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	[savePanel setAllowedFileTypes:[NSArray arrayWithObject:@"gpx"]];
	[savePanel setAllowsOtherFileTypes:NO];
	[savePanel beginWithCompletionHandler:^(NSInteger result) {
		if (result == NSOKButton) {
			NSURL *URL = [savePanel URL];
			MNXTrack *aTrack = [dataManager.tracks objectAtIndex:[tracksTableView selectedRow]];
			[[aTrack GPXData] writeToURL:URL atomically:YES];
		}
	}];
}
- (IBAction)showWindow:(id)sender
{
	[window makeKeyAndOrderFront:self];
}

#pragma mark -

- (void)didAddPorts:(NSNotification *)theNotification
{
	[self updatePorts];
}

- (void)didRemovePorts:(NSNotification *)theNotification
{
	[self updatePorts];
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
		MNXTrack *track = [dataManager.tracks objectAtIndex:inRow];
		return [track title];
	}
	else if (inTableView == pointsTableView) {
		NSString *ci = [inTableColumn identifier];
		MNXPoint *point = [currentTrack.points objectAtIndex:inRow];
		if ([ci isEqualToString:@"date"]) {
			return [dateFormatter stringFromDate:point.date];
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

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	[progressIndicator stopAnimation:self];
	[NSApp endSheet:sheetWindow];
	[sheetWindow orderOut:self];	
}

- (void)downloadManager:(MNXDataManager *)inManager didFailedWithMessage:(NSString *)message
{
	NSAlert *alert = [NSAlert alertWithMessageText:message defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@""];
	[alert beginSheetModalForWindow:sheetWindow modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}
- (void)downloadManagerDidStartDownloadingData:(MNXDataManager *)inManager
{
	NSLog(@"%s", __PRETTY_FUNCTION__);
	[NSApp beginSheet:sheetWindow modalForWindow:window modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
	[sheetWindow orderFront:self];
	[messageLabel setStringValue:@"Start downloading data..."];
	[progressIndicator setUsesThreadedAnimation:YES];
	[progressIndicator setIndeterminate:YES];
	[progressIndicator startAnimation:self];

}
- (void)downloadManager:(MNXDataManager *)inManager didDownloadData:(CGFloat)inProgress
{
	NSLog(@"%s %f", __PRETTY_FUNCTION__, inProgress);
	[messageLabel setStringValue:[NSString stringWithFormat:@"Downloading data, %d%% completed.", (NSInteger)(inProgress * 100)]];
	[progressIndicator setIndeterminate:NO];
	[progressIndicator setMaxValue:1.0];
	[progressIndicator setMinValue:0.0];
	[progressIndicator setDoubleValue:(double)inProgress];
	
}
- (void)downloadManagerDidFinishDownloadingData:(MNXDataManager *)inManager
{
	NSLog(@"%s", __PRETTY_FUNCTION__);
}
- (void)downloadManagerDidStartParsingData:(MNXDataManager *)inManager
{
	NSLog(@"%s", __PRETTY_FUNCTION__);
	[messageLabel setStringValue:@"Start parsing data..."];
	[progressIndicator setUsesThreadedAnimation:YES];
	[progressIndicator setIndeterminate:YES];	
}
- (void)downloadManager:(MNXDataManager *)inManager didFinishParsingData:(NSArray *)inTracks
{
	[tracksTableView reloadData];
	[pointsTableView reloadData];
	[progressIndicator stopAnimation:self];
	[NSApp endSheet:sheetWindow];
	[sheetWindow orderOut:self];	
}
- (void)downloadManagerCancelled:(MNXDataManager *)inManager
{
	if ([window attachedSheet]) {
		[progressIndicator stopAnimation:self];
		[NSApp endSheet:sheetWindow];
		[sheetWindow orderOut:self];		
	}
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
		[item setImage:[NSImage imageNamed:@"download"]];
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

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if ([menuItem action] == @selector(showWindow:)) {
		if ([window isMiniaturized]) {
			[menuItem setState:NSMixedState];
		}
		else if ([window isVisible]) {
			[menuItem setState:NSOnState];
		}
		else {
			[menuItem setState:NSOffState];
		}
		return YES;
	}
	if ([menuItem action] == @selector(selectDevice:)) {
		if ([menuItem tag] == [portListArrayController selectionIndex]) {
			[menuItem setState:NSOnState];
		}
		else {
			[menuItem setState:NSOffState];
		}		
	}
	if ([menuItem action] == @selector(download:)) {
		if (![[portListArrayController selectedObjects] count]) {
			return NO;
		}
	}
	if ([window attachedSheet]) {
		return NO;
	}
	if ([menuItem action] == @selector(exportGPX:)) {
		if ([tracksTableView selectedRow] < 0) {
			return;
		}
		if (![dataManager.tracks count]) {
			return;
		}		
	}
	return YES;
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
	if ([theItem action] == @selector(download:)) {
		if (![[portListArrayController selectedObjects] count]) {
			return NO;
		}
	}
	if ([window attachedSheet]) {
		return NO;
	}	
	return YES;
}

#pragma mark -

@synthesize currentTrack;
@synthesize window, tracksTableView, pointsTableView, webView;
@synthesize sheetWindow, messageLabel, progressIndicator;
@synthesize portListArrayController;
@synthesize portPopUpButton;
@synthesize deviceListMenuItem;

@end
