#import "MNXAppDelegate.h"
#import "MNXTrackCell.h"
#import "MNXSourceListTableView.h"
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
	[selectionController release];
	[super dealloc];
}

- (void)awakeFromNib
{
	preferenceController = [[MNXPreferenceController alloc] init];
	selectionController = [[MNXSelectionController alloc] init];
	[selectionController setDelegate:(id)self];
	
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
	[tracksTableView setRowHeight:20.0];
	
	[pointsTableView setDataSource:self];
	[pointsTableView setDelegate:self];
	
	[paceTableView setDataSource:self];
	[paceTableView setDelegate:self];
	
	dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateStyle:NSDateFormatterShortStyle];
	[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	
	[contentSplitView setDelegate:self];
	[mainSplitView setDelegate:self];
	[sourceListSplitView setDelegate:self];
	
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
	[cancelButton setHidden:YES];
	[messageLabel setStringValue:NSLocalizedString(@"Loading saved data...", @"")];
	[progressIndicator setUsesThreadedAnimation:YES];
	[progressIndicator startAnimation:self];
	[NSApp beginSheet:sheetWindow modalForWindow:window modalDelegate:nil didEndSelector:NULL contextInfo:NULL];	
	[sheetWindow orderFront:self];
	dataManager = [[MNXDataManager alloc] init];
	dataManager.delegate = self;
	dataManager.undoManager = [[self window] undoManager];
	[self updatePorts];
	[NSApp endSheet:sheetWindow];
	[sheetWindow orderOut:self];
	[progressIndicator stopAnimation:self];
	
	[tracksTableView reloadData];	
	
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
- (IBAction)purgeData:(id)sender
{
	if (![[portListArrayController selectedObjects] count]) {
		return;
	}
	
	AMSerialPort *port = [[portListArrayController selectedObjects] lastObject];	
	[dataManager purgeDataWithPort:port];
}
- (IBAction)selectDevice:(id)sender
{
	[portListArrayController setSelectionIndex:[sender tag]];
}

- (void)deleteAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSOKButton) {
		MNXTrack *aTrack = (MNXTrack *)contextInfo;
		[dataManager deleteTrack:aTrack];
	}
}

- (IBAction)deleteTrack:(id)sender
{
	if ([tracksTableView selectedRow] < 0) {
		return;
	}
	if (![dataManager.tracks count]) {
		return;
	}

	MNXTrack *aTrack = [dataManager.tracks objectAtIndex:[tracksTableView selectedRow]];	
	NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Do you really want to delete this activity?", @"") defaultButton:NSLocalizedString(@"Delete", @"") alternateButton:NSLocalizedString(@"Cancel", @"") otherButton:nil informativeTextWithFormat:@""];
	
	[alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(deleteAlertDidEnd:returnCode:contextInfo:) contextInfo:aTrack];
}

- (NSString *)allowedFileExtensionWithTag:(NSInteger)tag
{
	switch (tag) {
		case 0:
			return @"gpx";
			break;
		case 1:
			return @"kml";
			break;
		case 2:
			return @"tcx";
			break;						
		default:
			break;
	}	
	return @"gpx";
}


- (IBAction)export:(id)sender
{
	if (![sender tag]) {
		if ([tracksTableView selectedRow] < 0) {
			return;
		}
		if (![dataManager.tracks count]) {
			return;
		}	
	}
	MNXTrack *aTrack = [dataManager.tracks objectAtIndex:[tracksTableView selectedRow]];
	
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	[filetypePopUpButton selectItemWithTag:0];
	[savePanel setDelegate:(id)self];
	[savePanel setAllowedFileTypes:[NSArray arrayWithObject:@"gpx"]];
	[savePanel setAccessoryView:filetypeView];
	[savePanel setAllowsOtherFileTypes:NO];
	[savePanel setPrompt:NSLocalizedString(@"Export", @"")];	
	[savePanel setNameFieldLabel:NSLocalizedString(@"Export As:", @"")];
	
	if (![sender tag]) {
		[savePanel setTitle:NSLocalizedString(@"Export...", @"")];
		NSString *filename = [[aTrack title] stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
		filename = [filename stringByReplacingOccurrencesOfString:@":" withString:@"-"];
		filename = [filename stringByAppendingPathExtension:@"gpx"];
		[savePanel setNameFieldStringValue:filename];		
	}
	else {
		[savePanel setTitle:NSLocalizedString(@"Export All...", @"")];
		[savePanel setNameFieldStringValue:NSLocalizedString(@"MNX Activities", @"")];		
	}
	
	__block BOOL success = NO;
	__block NSError *error = nil;
	
	[savePanel beginSheetModalForWindow:window completionHandler:^(NSInteger result) {
		if (result == NSOKButton) {
			NSData *data = nil;
			if (![sender tag]) {
				switch ([filetypePopUpButton selectedTag]) {
					case 0:
						data = [aTrack GPXData];
						break;
					case 1:
						data = [aTrack KMLData];
						break;
					case 2:
						data = [aTrack TCXData];
						break;
					default:
						break;
				}
			}
			else {
				switch ([filetypePopUpButton selectedTag]) {
					case 0:
						data = [dataManager GPXData];
						break;
					case 1:
						data = [dataManager KMLData];
						break;
					case 2:
						data = [dataManager TCXData];
						break;
					default:
						break;
				}				
			}
			
			NSURL *URL = [savePanel URL];
			success = [data writeToURL:URL options:NSDataWritingAtomic error:&error];
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
- (IBAction)viewHTML:(id)sender
{
	if ([tracksTableView selectedRow] < 0) {
		return;
	}
	if (![dataManager.tracks count]) {
		return;
	}
	MNXTrack *aTrack = [dataManager.tracks objectAtIndex:[tracksTableView selectedRow]];	
	NSString *filePath = [dataManager tempFilePathWithExtension:@"html"];
	[[aTrack HTML] writeToURL:[NSURL fileURLWithPath:filePath] atomically:YES encoding:NSUTF8StringEncoding error:nil];
	[[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:filePath]];
}
- (IBAction)showWindow:(id)sender
{
	[window makeKeyAndOrderFront:self];
}
- (IBAction)showPreference:(id)sender
{
	[preferenceController showWindow:sender];
}
- (IBAction)changeExportFileType:(id)sender
{
	NSSavePanel *savePanel = (NSSavePanel *)[(NSView *)sender window];
	NSString *allowedExtension = [self allowedFileExtensionWithTag:[filetypePopUpButton selectedTag]];
	[savePanel setAllowedFileTypes:[NSArray arrayWithObject:allowedExtension]];
	NSString *filename = [savePanel nameFieldStringValue];
	NSString *currentExtension = [filename pathExtension];
	if (![currentExtension isEqualToString:allowedExtension]) {
		filename = [[filename stringByDeletingPathExtension] stringByAppendingPathExtension:allowedExtension];
	}
	[savePanel setNameFieldStringValue:filename];
}
- (IBAction)openHomepage:(id)sender
{
	NSURL *URL = [NSURL URLWithString:@"https://github.com/zonble/MNX"];
	[[NSWorkspace sharedWorkspace] openURL:URL];
}
- (IBAction)feedback:(id)sender
{
	NSURL *URL = [NSURL URLWithString:@"https://github.com/zonble/MNX/issues"];
	[[NSWorkspace sharedWorkspace] openURL:URL];
}

#pragma mark -

- (void)refresh
{
	NSTableColumn *aColumn = [paceTableView tableColumnWithIdentifier:@"unit"];
	
	[(MNXSourceListTableView *)tracksTableView setNoData:([dataManager.tracks count] < 1)];

	if ([NSLocale usingUSMeasurementUnit]) {
		[[aColumn headerCell] setStringValue:NSLocalizedString(@"Miles", @"")];
	}
	else {
		[[aColumn headerCell] setStringValue:NSLocalizedString(@"KM", @"")];
	}
	
	if (1) {
		NSString *distance = @"";
		if ([NSLocale usingUSMeasurementUnit]) {
			distance = [NSString stringWithFormat:@"%.2f %@", dataManager.totalDistanceMile, NSLocalizedString(@"ml", @"")];
		}
		else {
			distance = [NSString stringWithFormat:@"%.2f %@", dataManager.totalDistanceKM, NSLocalizedString(@"km", @"")];
		}
		[totalDistanceLabel setStringValue:distance];
		
		[totalDurationLabel setStringValue:NSStringFromNSTimeInterval(dataManager.totalDuration)];
		
		NSString *pace = @"";
		if ([NSLocale usingUSMeasurementUnit]) {
			pace = [NSString stringWithFormat:@"%@ %@", NSStringFromNSTimeInterval(dataManager.averagePaceMile), NSLocalizedString(@"per mile", @"")];
		}
		else {
			pace = [NSString stringWithFormat:@"%@ %@", NSStringFromNSTimeInterval(dataManager.averagePaceKM), NSLocalizedString(@"per kilometre", @"")];
		}
		[totalPaceLabel setStringValue:pace];
		
		NSString *speed = @"";
		if ([NSLocale usingUSMeasurementUnit]) {
			speed = [NSString stringWithFormat:@"%.2f %@", dataManager.averageSpeedMile, NSLocalizedString(@"ml/h", @"")];
		}
		else {
			speed = [NSString stringWithFormat:@"%.2f %@", dataManager.averageSpeedKM, NSLocalizedString(@"km/h", @"")];
		}		
		
		[totalSpeedLabel setStringValue:speed];	
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
			speed = [NSString stringWithFormat:@"%.2f %@", self.currentTrack.averageSpeedMile, NSLocalizedString(@"ml/h", @"")];
		}
		else {
			speed = [NSString stringWithFormat:@"%.2f %@", self.currentTrack.averageSpeedKM, NSLocalizedString(@"km/h", @"")];
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

- (void)downloadErrorAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	[progressIndicator stopAnimation:self];
	[NSApp endSheet:sheetWindow];
	[sheetWindow orderOut:self];	
}
- (void)dataManager:(MNXDataManager *)inManager didFaileWithError:(NSError *)inError;
{
	NSWindow *aWindow = window;
	if ([sheetWindow isVisible]) {
		aWindow = sheetWindow;
	}
	NSAlert *alert = [NSAlert alertWithError:inError];
	[alert beginSheetModalForWindow:aWindow modalDelegate:self didEndSelector:@selector(downloadErrorAlertDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}
- (void)dataManagerDidStartDownloadingData:(MNXDataManager *)inManager
{
	[cancelButton setHidden:NO];
	
	[NSApp beginSheet:sheetWindow modalForWindow:window modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
	[sheetWindow orderFront:self];
	[messageLabel setStringValue:NSLocalizedString(@"Start downloading data...", @"")];
	[progressIndicator setUsesThreadedAnimation:YES];
	[progressIndicator setIndeterminate:YES];
	[progressIndicator startAnimation:self];
}
- (void)dataManager:(MNXDataManager *)inManager didDownloadData:(CGFloat)inProgress
{
	[messageLabel setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Downloading data, %d%% completed...", @""), (NSInteger)(inProgress * 100)]];
	[progressIndicator setIndeterminate:NO];
	[progressIndicator setMaxValue:1.0];
	[progressIndicator setMinValue:0.0];
	[progressIndicator setDoubleValue:(double)inProgress];
	
}
- (void)dataManagerDidFinishDownloadingData:(MNXDataManager *)inManager
{
}
- (void)dataManagerDidStartParsingData:(MNXDataManager *)inManager
{
	[messageLabel setStringValue:NSLocalizedString(@"Start parsing data...", @"")];
	[progressIndicator setUsesThreadedAnimation:YES];
	[progressIndicator setIndeterminate:YES];	
	[progressIndicator startAnimation:self];
}
- (void)_delayedShowSelectionWindow:(NSArray *)tracks
{
	selectionController.tracks = tracks;
	[NSApp beginSheet:[selectionController window] modalForWindow:window modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
	[[selectionController window] orderFront:self];
}

- (void)dataManager:(MNXDataManager *)inManager didFinishParsingData:(NSArray *)inTracks
{
	[progressIndicator stopAnimation:self];

	[NSApp endSheet:sheetWindow];
	[sheetWindow orderOut:self];
	[self performSelector:@selector(_delayedShowSelectionWindow:) withObject:inTracks afterDelay:0.3];
}
- (void)dataManagerCancelled:(MNXDataManager *)inManager
{
	if ([window attachedSheet]) {
		[progressIndicator stopAnimation:self];
		[NSApp endSheet:sheetWindow];
		[sheetWindow orderOut:self];		
	}
}
- (void)dataManagerUpdated:(MNXDataManager *)inManager
{
	[tracksTableView reloadData];
	[self refresh];
}
- (void)dataManagerDidStartPurgineData:(MNXDataManager *)inManager
{
	[NSApp beginSheet:sheetWindow modalForWindow:window modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
	[sheetWindow orderFront:self];
	[messageLabel setStringValue:NSLocalizedString(@"Purging data...", @"")];
	[progressIndicator setUsesThreadedAnimation:YES];
	[progressIndicator setIndeterminate:YES];
	[progressIndicator startAnimation:self];
	[cancelButton setHidden:YES];
}
- (void)dataManagerDidFinishPurgineData:(MNXDataManager *)inManager
{
	[progressIndicator stopAnimation:self];
	
	[NSApp endSheet:sheetWindow];
	[sheetWindow orderOut:self];	
}


#pragma mark -

- (void)selectionController:(MNXSelectionController *)inController didSelectTracks:(NSArray *)inTracks
{
	[dataManager appendTracks:inTracks];
	[tracksTableView reloadData];
	[NSApp endSheet:[selectionController window]];
	[[selectionController window] orderOut:self];
	[self refresh];
}
- (void)selectionControllerCancelled:(MNXSelectionController *)inController
{
	[NSApp endSheet:[selectionController window]];
	[[selectionController window] orderOut:self];
}

#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if ([menuItem action] == @selector(changeExportFileType:)) {
		return YES;
	}	
	if ([menuItem action] == @selector(openHomepage:)) {
		return YES;
	}	
	if ([menuItem action] == @selector(feedback:)) {
		return YES;
	}	
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
	if ([menuItem action] == @selector(download:) ||
		[menuItem action] == @selector(purgeData:)) {
		if (![[portListArrayController selectedObjects] count]) {
			return NO;
		}
	}
	if ([window attachedSheet]) {
		return NO;
	}
	if ([menuItem action] == @selector(export:) && [menuItem tag]) {
		if (![dataManager.tracks count]) {
			return NO;
		}
	}		
	if (([menuItem action] == @selector(export:) && ![menuItem tag]) ||
		[menuItem action] == @selector(googleEarth:) ||
		[menuItem action] == @selector(deleteTrack:) ||
		[menuItem action] == @selector(viewHTML:)
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
	if ([theItem action] == @selector(download:) ||
		[theItem action] == @selector(purgeData:)) {
		if (![[portListArrayController selectedObjects] count]) {
			return NO;
		}
	}
	if ([window attachedSheet]) {
		return NO;
	}
	if ([theItem action] == @selector(export:) && [theItem tag]) {
		if (![dataManager.tracks count]) {
			return NO;
		}
	}	
	if (([theItem action] == @selector(export:) && ![theItem tag]) ||
		[theItem action] == @selector(googleEarth:) ||
		[theItem action] == @selector(deleteTrack:) ||
		[theItem action] == @selector(viewHTML:)
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
	if (self.currentTrack) {
		[[webView mainFrame] loadHTMLString:[self.currentTrack HTML] baseURL:nil];
	}
}

#pragma mark -
#pragma mark Properties

@synthesize currentTrack;
@synthesize mainSplitView, contentSplitView, sourceListSplitView;
@synthesize window, tracksTableView, pointsTableView, paceTableView, speedView, webView;
@synthesize sheetWindow, messageLabel, progressIndicator;
@synthesize portListArrayController;
@synthesize portPopUpButton;
@synthesize deviceListMenuItem;
@synthesize infoImageView;
@synthesize trackTotalDistanceLabel, trackDurationLabel, trackPaceLabel, trackSpeedLabel;
@synthesize totalDistanceLabel, totalDurationLabel, totalPaceLabel, totalSpeedLabel;
@synthesize cancelButton;
@synthesize filetypeView, filetypePopUpButton;

@end

