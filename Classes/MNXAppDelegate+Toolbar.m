#import "MNXAppDelegate.h"

static NSString *const kPortPopUpButtonItem = @"kPortPopUpButtonItem";
static NSString *const kDownloadItem = @"kDownloadItem";
static NSString *const kGoogleEarthItem = @"kGoogleEarthItem";

@implementation MNXAppDelegate(Toolbar)

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
	if ([itemIdentifier isEqualToString:kGoogleEarthItem]) {
		NSToolbarItem *item = [[[NSToolbarItem alloc] initWithItemIdentifier:kGoogleEarthItem] autorelease];
		[item setImage:[NSImage imageNamed:@"googleearth"]];
		[item setLabel:@"Google Earth"];
		[item setToolTip:@"View in Google Earth"];
		[item setTarget:self];
		[item setAction:@selector(googleEarth:)];
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
	return [NSArray arrayWithObjects:kPortPopUpButtonItem, 
			kDownloadItem,
			NSToolbarSeparatorItemIdentifier,
			NSToolbarSpaceItemIdentifier,
			kGoogleEarthItem,
			NSToolbarFlexibleSpaceItemIdentifier,
			nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
	return [NSArray arrayWithObjects:kPortPopUpButtonItem,
			kDownloadItem,
			kGoogleEarthItem, 
			NSToolbarSeparatorItemIdentifier,
			NSToolbarSpaceItemIdentifier,
			NSToolbarFlexibleSpaceItemIdentifier, nil];
}

@end
