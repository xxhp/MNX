#import "MNXAppDelegate.h"

static NSString *const kPortPopUpButtonItem = @"kPortPopUpButtonItem";
static NSString *const kDownloadItem = @"kDownloadItem";
static NSString *const kPurgeDataItem = @"kPurgeDataItem";
static NSString *const kExportItem = @"kExportItem";
static NSString *const kExportAllItem = @"kExportAllItem";
static NSString *const kGoogleEarthItem = @"kGoogleEarthItem";

@implementation MNXAppDelegate(Toolbar)

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag;
{
	if ([itemIdentifier isEqualToString:kPortPopUpButtonItem]) {
		NSToolbarItem *item = [[[NSToolbarItem alloc] initWithItemIdentifier:kPortPopUpButtonItem] autorelease];
		[item setLabel:NSLocalizedString(@"Device", @"")];
		[item setToolTip:NSLocalizedString(@"Select the desired device.", @"")];
		[item setPaletteLabel:NSLocalizedString(@"Device", @"")];
		[item setView:portPopUpButton];
		[item setMaxSize:NSMakeSize(200.0, 32.0)];
		[item setMinSize:NSMakeSize(120.0, 32.0)];
		return item;
	}
	if ([itemIdentifier isEqualToString:kExportItem]) {
		NSToolbarItem *item = [[[NSToolbarItem alloc] initWithItemIdentifier:kExportItem] autorelease];
		[item setImage:[NSImage imageNamed:@"export"]];
		[item setLabel:NSLocalizedString(@"Export", @"")];
		[item setToolTip:NSLocalizedString(@"Export selected activity.", @"")];
		[item setPaletteLabel:NSLocalizedString(@"Export", @"")];
		[item setTag:0];
		[item setTarget:self];
		[item setAction:@selector(export:)];
		return item;
	}	
	if ([itemIdentifier isEqualToString:kExportAllItem]) {
		NSToolbarItem *item = [[[NSToolbarItem alloc] initWithItemIdentifier:kExportItem] autorelease];
		[item setImage:[NSImage imageNamed:@"export"]];
		[item setLabel:NSLocalizedString(@"Export All", @"")];
		[item setToolTip:NSLocalizedString(@"Export all activities.", @"")];
		[item setPaletteLabel:NSLocalizedString(@"Export All", @"")];
		[item setTag:1];
		[item setTarget:self];
		[item setAction:@selector(export:)];
		return item;
	}		
	if ([itemIdentifier isEqualToString:kGoogleEarthItem]) {
		NSToolbarItem *item = [[[NSToolbarItem alloc] initWithItemIdentifier:kGoogleEarthItem] autorelease];
		[item setImage:[NSImage imageNamed:@"googleearth"]];
		[item setLabel:NSLocalizedString(@"Google Earth", @"")];
		[item setToolTip:NSLocalizedString(@"View in Google Earth.", @"")];
		[item setPaletteLabel:NSLocalizedString(@"Google Earth", @"")];
		[item setTarget:self];
		[item setAction:@selector(googleEarth:)];
		return item;
	}	
	if ([itemIdentifier isEqualToString:kDownloadItem]) {
		NSToolbarItem *item = [[[NSToolbarItem alloc] initWithItemIdentifier:kDownloadItem] autorelease];
		[item setImage:[NSImage imageNamed:@"download"]];
		[item setLabel:NSLocalizedString(@"Download", @"")];
		[item setToolTip:NSLocalizedString(@"Download data from your GPS device.", @"")];
		[item setPaletteLabel:NSLocalizedString(@"Download", @"")];
		[item setTarget:self];
		[item setAction:@selector(download:)];
		return item;
	}
	if ([itemIdentifier isEqualToString:kPurgeDataItem]) {
		NSToolbarItem *item = [[[NSToolbarItem alloc] initWithItemIdentifier:kPurgeDataItem] autorelease];
		[item setImage:[NSImage imageNamed:@"trash"]];
		[item setLabel:NSLocalizedString(@"Purge Data", @"")];
		[item setToolTip:NSLocalizedString(@"Purge data on your GPS device.", @"")];
		[item setPaletteLabel:NSLocalizedString(@"Purge Data", @"")];
		[item setTarget:self];
		[item setAction:@selector(purgeData:)];
		return item;
	}
	
	
	return nil;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
	return [NSArray arrayWithObjects:kPortPopUpButtonItem, 
			kDownloadItem,
			kPurgeDataItem,
			NSToolbarSpaceItemIdentifier,
			NSToolbarSpaceItemIdentifier,
			kExportItem,
			kExportAllItem,
			NSToolbarSeparatorItemIdentifier,
			kGoogleEarthItem,
			NSToolbarFlexibleSpaceItemIdentifier,
			nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
	return [NSArray arrayWithObjects:kPortPopUpButtonItem,
			kDownloadItem,
			kPurgeDataItem,
			kExportItem,
			kExportAllItem,
			kGoogleEarthItem, 
			NSToolbarSeparatorItemIdentifier,
			NSToolbarSpaceItemIdentifier,
			NSToolbarFlexibleSpaceItemIdentifier, nil];
}

@end
