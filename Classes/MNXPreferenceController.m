#import "MNXPreferenceController.h"
#import "MNXAppConfig.h"

@implementation MNXPreferenceController

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[groupedTimeZones release];
	[super dealloc];
}

- (id)init
{
	self = [super init];
	if (self != nil) {
		groupedTimeZones = [[NSMutableArray alloc] init];
		for (NSString *timeZoneName in [NSTimeZone knownTimeZoneNames]) {
			NSArray *parts = [timeZoneName componentsSeparatedByString:@"/"];
			if ([parts count] < 2) {
				continue;
			}
			
			NSString *region = [parts objectAtIndex:0];
			parts = [parts subarrayWithRange:NSMakeRange(1, [parts count] - 1)];
			NSString *city = [parts componentsJoinedByString:@"/"];
			NSMutableArray *regionArray = nil;
			for (NSMutableArray *a in groupedTimeZones) {
				if ([[a objectAtIndex:0] isEqualToString:region]) {
					regionArray = a;
					break;
				}
			}
			if (!regionArray) {
				regionArray = [NSMutableArray array];
				[regionArray addObject:region];
				[regionArray addObject:[NSMutableArray array]];
				[groupedTimeZones addObject:regionArray];
			}
			if (regionArray) {
				NSMutableArray *cities = [regionArray objectAtIndex:1];
				city = [city stringByReplacingOccurrencesOfString:@"_" withString:@" "];
				[cities addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:city, @"city",
								   timeZoneName, @"timeZoneName",
								   [NSNumber numberWithBool:NO],  @"checked", nil]];
			}
		}
		[NSBundle loadNibNamed:NSStringFromClass([self class]) owner:self];
	}
	return self;
}

- (void)awakeFromNib
{
	[timeZoneOutlineView setDelegate:self];
	[timeZoneOutlineView setDataSource:self];
	[timeZoneOutlineView setOutlineTableColumn:[timeZoneOutlineView tableColumnWithIdentifier:@"name"]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(timeZoneDidChange:) name:NSSystemTimeZoneDidChangeNotification object:nil];
	[self refresh];
}

- (void)refresh
{
	NSCell *aCell = [timezoneMatrix cellWithTag:0];
	
	NSTimeZone *currentTimeZone = [NSTimeZone systemTimeZone];
	NSString *currentTimeZoneName = [currentTimeZone localizedName:NSTimeZoneNameStyleGeneric locale:[NSLocale currentLocale]];
	
	NSString *title = [NSString stringWithFormat:NSLocalizedString(@"As System Time Zone on My Mac (%@)", @""), currentTimeZoneName];
	[aCell setTitle:title];

	[self deselectAllTimeZone];
	
	NSTimeZone *aTimeZone = [NSTimeZone timeZoneWithName:AppConfig().deviceTimeZoneName];;
	if (![AppConfig().deviceTimeZoneName length] || !aTimeZone) {
		[timezoneMatrix selectCellWithTag:0];
		[timeZoneOutlineView reloadData];
		for (id group in groupedTimeZones) {
			[timeZoneOutlineView collapseItem:group];
		}
	}
	else {
		[timezoneMatrix selectCellWithTag:1];
		NSArray *currentRegion = nil;
		NSDictionary *item = nil;
		for (NSArray *region in groupedTimeZones) {
			for (NSMutableDictionary *tz in [region objectAtIndex:1]) {
				if ([[tz objectForKey:@"timeZoneName"] isEqualToString:[aTimeZone name]]) {
					[tz setObject:[NSNumber numberWithBool:YES] forKey:@"checked"];
					item = tz;
					currentRegion = region;
					break;
				}
			}
		}
		[timeZoneOutlineView reloadData];
		[timeZoneOutlineView expandItem:currentRegion expandChildren:YES];
		NSInteger row = [timeZoneOutlineView rowForItem:item];
		[timeZoneOutlineView scrollRowToVisible:row];
		[timeZoneOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];		
	}
}
- (void)setNewTimeZoneSettingWithName:(NSString *)newTimeZoneName
{
	[[self undoManager] setActionName:NSLocalizedString(@"Changing Time Zone Setting", @"Undo action")];
	[[[self undoManager] prepareWithInvocationTarget:self] setNewTimeZoneSettingWithName:AppConfig().deviceTimeZoneName];	
	AppConfig().deviceTimeZoneName = newTimeZoneName;
	[self refresh];
}

- (void)deselectAllTimeZone
{
	for (NSArray *region in groupedTimeZones) {
		for (NSMutableDictionary *tz in [region objectAtIndex:1]) {
			[tz setObject:[NSNumber numberWithBool:NO] forKey:@"checked"];
		}
	}
}

- (IBAction)changeTimezoneSettingAction:(id)sender
{
	if ([[sender selectedCell] tag]) {
		if (![AppConfig().deviceTimeZoneName length]) {
			NSTimeZone *currentTimeZone = [NSTimeZone systemTimeZone];
			[self setNewTimeZoneSettingWithName:[currentTimeZone name]];
		}		
	}
	else {
		if ([AppConfig().deviceTimeZoneName length]) {
			[self setNewTimeZoneSettingWithName:@""];
		}
	}
}

- (IBAction)showWindow:(id)sender
{
	if (![[self window] isVisible]) {
		[[self window] center];
	}
	[super showWindow:sender];
}

#pragma mark -


- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item 
{
	if (!item) {
		return [groupedTimeZones count];
	}
	if ([item isKindOfClass:[NSArray class]] && [[item objectAtIndex:0] isKindOfClass:[NSString class]]) {
		return [[item objectAtIndex:1] count];
	}	
	return 0;
}
- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item 
{	
	if (!item) {
		return [groupedTimeZones objectAtIndex:index];
	}
	else if ([item isKindOfClass:[NSArray class]] && [[item objectAtIndex:0] isKindOfClass:[NSString class]]) {
		return [[item objectAtIndex:1] objectAtIndex:index];
	}
	return nil;
}
- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item
{
	if ([item isKindOfClass:[NSArray class]] && [[item objectAtIndex:0] isKindOfClass:[NSString class]]) {
		return YES;
	}
	return NO;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item 
{
	if (!item) {
		return YES;
	}
	else if ([item isKindOfClass:[NSArray class]] && [[item objectAtIndex:0] isKindOfClass:[NSString class]]) {
		return YES;
	}
	return NO;
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	[cell setFont:[NSFont systemFontOfSize:11.0]];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item 
{
	if (!item) {
		return @"/";
	}
	else if ([item isKindOfClass:[NSArray class]] && [[item objectAtIndex:0] isKindOfClass:[NSString class]]) {
		if ([[tableColumn identifier] isEqualToString:@"name"]) {
			return [item objectAtIndex:0];
		}
	}
	else if ([item isKindOfClass:[NSDictionary class]]) {
		NSString *cityName = [item objectForKey:@"city"];
		NSString *timeZoneName = [item objectForKey:@"timeZoneName"];
		if ([[tableColumn identifier] isEqualToString:@"name"]) {
			return cityName;
		}
		if ([[tableColumn identifier] isEqualToString:@"localizedName"]) {
			NSTimeZone *tz = [NSTimeZone timeZoneWithName:timeZoneName];
			return [tz localizedName:NSTimeZoneNameStyleGeneric locale:[NSLocale currentLocale]];
		}
		if ([[tableColumn identifier] isEqualToString:@"checked"]) {
			return [item objectForKey:@"checked"];
		}		
	}
	return nil;
}
- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	if ([item isKindOfClass:[NSMutableDictionary class]] && [[tableColumn identifier] isEqualToString:@"checked"]) {
		[self deselectAllTimeZone];
		[(NSMutableDictionary *)item setObject:[NSNumber numberWithBool:[object boolValue]] forKey:@"checked"];
		NSString *timeZoneName = [item objectForKey:@"timeZoneName"];
		[self setNewTimeZoneSettingWithName:timeZoneName];
	}
}
- (NSCell *)outlineView:(NSOutlineView *)outlineView dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	if ([[tableColumn identifier] isEqualToString:@"checked"] && [item isKindOfClass:[NSArray class]]) {
		return [[[NSCell alloc] init] autorelease];
	}	
	return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
	if ([item isKindOfClass:[NSArray class]]) {
		return NO;
	}
	return YES;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectTableColumn:(NSTableColumn *)tableColumn
{
	return NO;
}
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldExpandItem:(id)item
{
	return YES;
}

#pragma mark -

- (void)timeZoneDidChange:(NSNotification *)n
{
	[self refresh];
}

#pragma mark -

- (NSUndoManager *)undoManager
{
	return [[self window] undoManager];
}

@synthesize timezoneMatrix;
@synthesize timeZoneOutlineView;

@end

