#import "MNXAppDelegate.h"
#import "MNXTrackCell.h"
#import "NSString+Extension.h"
#import "NSLocale+MNXExtension.h"
#import "NSImage+MNXExtensions.h"

@implementation MNXAppDelegate

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[currentTrack release];
	[dateFormatter release];
	[dataManager release];
	[preferenceController release];
	[super dealloc];
}

- (void)awakeFromNib
{
	preferenceController = [[MNXPreferenceController alloc] init];
	
	NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier:@"toolbar"] autorelease];
	[toolbar setDelegate:self];
	[toolbar setAllowsUserCustomization:YES];
	[window setToolbar:toolbar];
	[window setExcludedFromWindowsMenu:YES];
	
	[webView setUIDelegate:self];

	MNXTrackCell *cell = [[[MNXTrackCell alloc] init] autorelease];
	NSTableColumn *tracksColumn = [tracksTableView tableColumnWithIdentifier:@"tracks"];
	[tracksColumn setDataCell:cell];
	
	[tracksTableView setDataSource:self];
	[tracksTableView setDelegate:self];
	
	[pointsTableView setDataSource:self];
	[pointsTableView setDelegate:self];
	
	[paceTableView setDataSource:self];
	[paceTableView setDelegate:self];
	
	dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateStyle:NSDateFormatterShortStyle];
	[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	
	[contentSplitView setDelegate:self];
	[mainSplitView setDelegate:self];
	
	[self refresh];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(systemTimeDidChange:) name:NSSystemClockDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(timeZoneDidChange:) name:NSSystemTimeZoneDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(localeDidChange:) name:NSCurrentLocaleDidChangeNotification object:nil];	
	
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
		
	NSMenu *menu = [[[NSMenu alloc] initWithTitle:NSLocalizedString(@"Devices", @"")] autorelease];
	NSUInteger tag = 0;
	for (AMSerialPort *p in a) {
		NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle:[p name] action:@selector(selectDevice:) keyEquivalent:@""] autorelease];
		[menuItem setTarget:self];
		[menuItem setTag:tag++];
		[menu addItem:menuItem];
	}
	if (![a count]) {
		NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"No Device", @"") action:NULL keyEquivalent:@""] autorelease];	
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
- (void)applicationDidBecomeActive:(NSNotification *)notification
{
	if (![window isVisible]) {
		[window makeKeyAndOrderFront:self];
	}
}
- (NSMenu *)applicationDockMenu:(NSApplication *)sender
{
	NSMenu *menu = [[[NSMenu alloc] initWithTitle:@"Dock Menu"] autorelease];
	NSMenuItem *mainItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"MNX", @"") action:@selector(showWindow:) keyEquivalent:@""] autorelease];
	[mainItem setTarget:self];
	[menu addItem:mainItem];
	return menu;
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
	MNXTrack *aTrack = [dataManager.tracks objectAtIndex:[tracksTableView selectedRow]];
	
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	[savePanel setAllowedFileTypes:[NSArray arrayWithObject:@"gpx"]];
	[savePanel setAllowsOtherFileTypes:NO];
	[savePanel setPrompt:NSLocalizedString(@"Export", @"")];
	[savePanel setNameFieldLabel:NSLocalizedString(@"Export As:", @"")];
	NSString *filename = [[aTrack title] stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
	filename = [filename stringByReplacingOccurrencesOfString:@":" withString:@"-"];
	[savePanel setNameFieldStringValue:filename];	
	[savePanel beginSheetModalForWindow:window completionHandler:^(NSInteger result) {
		if (result == NSOKButton) {
			NSURL *URL = [savePanel URL];
			[[aTrack GPXData] writeToURL:URL atomically:YES];
		}		
	}];
}
- (IBAction)exportKML:(id)sender
{
	if ([tracksTableView selectedRow] < 0) {
		return;
	}
	if (![dataManager.tracks count]) {
		return;
	}	
	MNXTrack *aTrack = [dataManager.tracks objectAtIndex:[tracksTableView selectedRow]];
	
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	[savePanel setAllowedFileTypes:[NSArray arrayWithObject:@"kml"]];
	[savePanel setAllowsOtherFileTypes:NO];
	[savePanel setPrompt:NSLocalizedString(@"Export", @"")];
	[savePanel setNameFieldLabel:NSLocalizedString(@"Export As:", @"")];
	NSString *filename = [[aTrack title] stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
	filename = [filename stringByReplacingOccurrencesOfString:@":" withString:@"-"];
	[savePanel setNameFieldStringValue:filename];
	[savePanel beginSheetModalForWindow:window completionHandler:^(NSInteger result) {
		if (result == NSOKButton) {
			NSURL *URL = [savePanel URL];
			[[aTrack KMLData] writeToURL:URL atomically:YES];
		}		
	}];	
}
- (IBAction)exportTCX:(id)sender
{
	if ([tracksTableView selectedRow] < 0) {
		return;
	}
	if (![dataManager.tracks count]) {
		return;
	}	
	MNXTrack *aTrack = [dataManager.tracks objectAtIndex:[tracksTableView selectedRow]];
	
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	[savePanel setAllowedFileTypes:[NSArray arrayWithObject:@"tcx"]];
	[savePanel setAllowsOtherFileTypes:NO];
	[savePanel setPrompt:NSLocalizedString(@"Export", @"")];
	[savePanel setNameFieldLabel:NSLocalizedString(@"Export As:", @"")];
	NSString *filename = [[aTrack title] stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
	filename = [filename stringByReplacingOccurrencesOfString:@":" withString:@"-"];
	[savePanel setNameFieldStringValue:filename];
	[savePanel beginSheetModalForWindow:window completionHandler:^(NSInteger result) {
		if (result == NSOKButton) {
			NSURL *URL = [savePanel URL];
			[[aTrack TCXData] writeToURL:URL atomically:YES];
		}
	}];	
}

- (IBAction)googleEarth:(id)sender
{
	NSWorkspace *space = [NSWorkspace sharedWorkspace];
	NSString *path = [space absolutePathForAppBundleWithIdentifier:@"com.Google.GoogleEarthPlus"];
	if (!path) {
		NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Google Earth is not installed.", @"") defaultButton:NSLocalizedString(@"OK", @"") alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"Please install Google Earth.", @"")];
		[alert beginSheetModalForWindow:window modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
		return;
	}
	
	if ([tracksTableView selectedRow] < 0) {
		return;
	}
	if (![dataManager.tracks count]) {
		return;
	}	
	MNXTrack *aTrack = [dataManager.tracks objectAtIndex:[tracksTableView selectedRow]];	
	
	NSString *filePath = [dataManager tempFilePathWithExtension:@"kml"];
	[[aTrack KMLData] writeToURL:[NSURL fileURLWithPath:filePath] atomically:YES];
	[space openFile:filePath withApplication:@"Google Earth"];
}
- (IBAction)showWindow:(id)sender
{
	[window makeKeyAndOrderFront:self];
}
- (IBAction)showPreference:(id)sender
{
	[preferenceController showWindow:sender];
}

- (void)refresh
{
	NSTableColumn *aColumn = [paceTableView tableColumnWithIdentifier:@"unit"];
	if ([NSLocale usingUSMeasurementUnit]) {
		[[aColumn headerCell] setStringValue:NSLocalizedString(@"Miles", @"")];
	}
	else {
		[[aColumn headerCell] setStringValue:NSLocalizedString(@"KM", @"")];
	}
	
	if (!self.currentTrack) {
		[pointsTableView reloadData];
		[paceTableView reloadData];
		speedView.currentTrack = nil;
		[infoImageView setImage:[NSImage calendarImageWithDate:nil]];
		
		[trackTotalDistanceLabel setStringValue:@"0"];
		[trackDurationLabel setStringValue:@"--:--"];
		[trackPaceLabel setStringValue:@"--:--"];
		[trackSpeedLabel setStringValue:@"0"];		
		
		[window setTitle:NSLocalizedString(@"MNX", @"")];
	}
	else {		
		[pointsTableView reloadData];
		[paceTableView reloadData];
		
		NSString *distance = @"";
		if ([NSLocale usingUSMeasurementUnit]) {
			distance = [NSString stringWithFormat:@"%.2f %@", self.currentTrack.totalDistanceMile, NSLocalizedString(@"ml", @"")];
		}
		else {
			distance = [NSString stringWithFormat:@"%.2f %@", self.currentTrack.totalDistanceKM, NSLocalizedString(@"km", @"")];
		}
		[trackTotalDistanceLabel setStringValue:distance];
		
		[trackDurationLabel setStringValue:NSStringFromNSTimeInterval(self.currentTrack.duration)];

		NSString *pace = @"";
		if ([NSLocale usingUSMeasurementUnit]) {
			pace = [NSString stringWithFormat:@"%@ %@", NSStringFromNSTimeInterval(self.currentTrack.averagePaceMile), NSLocalizedString(@"per mile", @"")];
		}
		else {
			pace = [NSString stringWithFormat:@"%@ %@", NSStringFromNSTimeInterval(self.currentTrack.averagePaceKM), NSLocalizedString(@"per kilometre", @"")];
		}
		[trackPaceLabel setStringValue:pace];

		NSString *speed = @"";
		if ([NSLocale usingUSMeasurementUnit]) {
			speed = [NSString stringWithFormat:@"%.2f %@", self.currentTrack.averageSpeedMile, @"ml/h"];
		}
		else {
			speed = [NSString stringWithFormat:@"%.2f %@", self.currentTrack.averageSpeedKM, @"km/h"];
		}		
		
		[trackSpeedLabel setStringValue:speed];		
		
		NSDate *date = nil;
		if ([self.currentTrack.points count]) {
			MNXPoint *aPoint = [self.currentTrack.points objectAtIndex:0];
			date = [aPoint date];
		}
		
		NSImage *image = [NSImage calendarImageWithDate:date];
		[infoImageView setImage:image];
		
		speedView.currentTrack = self.currentTrack;
		
		[window setTitle:[NSString stringWithFormat:NSLocalizedString(@"%@ - MNX", @""), self.currentTrack.title]];
	}
}


#pragma mark -
#pragma mark AMSerialPortListDidAddPortsNotification and AMSerialPortListDidRemovePortsNotification

- (void)didAddPorts:(NSNotification *)theNotification
{
	[self updatePorts];
}

- (void)didRemovePorts:(NSNotification *)theNotification
{
	[self updatePorts];
}


#pragma mark -

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	[progressIndicator stopAnimation:self];
	[NSApp endSheet:sheetWindow];
	[sheetWindow orderOut:self];	
}

- (void)downloadManager:(MNXDataManager *)inManager didFaileWithError:(NSError *)inError;
{
	NSAlert *alert = [NSAlert alertWithError:inError];
	[alert beginSheetModalForWindow:sheetWindow modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}
- (void)downloadManagerDidStartDownloadingData:(MNXDataManager *)inManager
{
	NSLog(@"%s", __PRETTY_FUNCTION__);
	[NSApp beginSheet:sheetWindow modalForWindow:window modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
	[sheetWindow orderFront:self];
	[messageLabel setStringValue:NSLocalizedString(@"Start downloading data...", @"")];
	[progressIndicator setUsesThreadedAnimation:YES];
	[progressIndicator setIndeterminate:YES];
	[progressIndicator startAnimation:self];

}
- (void)downloadManager:(MNXDataManager *)inManager didDownloadData:(CGFloat)inProgress
{
	NSLog(@"%s %f", __PRETTY_FUNCTION__, inProgress);
	[messageLabel setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Downloading data, %d%% completed...", @""), (NSInteger)(inProgress * 100)]];
	[progressIndicator setIndeterminate:NO];
	[progressIndicator setMaxValue:1.0];
	[progressIndicator setMinValue:0.0];
	[progressIndicator setDoubleValue:(double)inProgress];
	
}
- (void)downloadManagerDidFinishDownloadingData:(MNXDataManager *)inManager
{
}
- (void)downloadManagerDidStartParsingData:(MNXDataManager *)inManager
{
	[messageLabel setStringValue:NSLocalizedString(@"Start parsing data...", @"")];
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
	if ([menuItem action] == @selector(exportGPX:) ||
		[menuItem action] == @selector(exportKML:) ||
		[menuItem action] == @selector(exportTCX:) ||
		[menuItem action] == @selector(googleEarth:)
		) {
		if ([tracksTableView selectedRow] < 0) {
			return NO;
		}
		if (![dataManager.tracks count]) {
			return NO;
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
	if ([theItem action] == @selector(exportGPX:) ||
		[theItem action] == @selector(exportKML:) ||
		[theItem action] == @selector(exportTCX:) ||
		[theItem action] == @selector(googleEarth:)
		) {
		if ([tracksTableView selectedRow] < 0) {
			return NO;
		}
		if (![dataManager.tracks count]) {
			return NO;
		}		
	}
	return YES;
}

#pragma mark -
#pragma mark Notifications

- (void)systemTimeDidChange:(NSNotification *)n
{
	[self refresh];
}
- (void)timeZoneDidChange:(NSNotification *)n
{
	[self refresh];
}
- (void)localeDidChange:(NSNotification *)n
{
	[self refresh];
}

#pragma mark -
#pragma mark Properties

@synthesize currentTrack;
@synthesize mainSplitView, contentSplitView;
@synthesize window, tracksTableView, pointsTableView, paceTableView, speedView, webView;
@synthesize sheetWindow, messageLabel, progressIndicator;
@synthesize portListArrayController;
@synthesize portPopUpButton;
@synthesize deviceListMenuItem;
@synthesize infoImageView;
@synthesize trackTotalDistanceLabel, trackDurationLabel, trackPaceLabel, trackSpeedLabel;
//@synthesize trackInfoLabel;

@end
