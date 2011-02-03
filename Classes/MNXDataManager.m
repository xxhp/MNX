#import "MNXDataManager.h"

@interface MNXDataManager (Private)
- (void)_updateInfo;
@end

@implementation MNXDataManager (Private)

- (void)_updateInfo
{
	totalDuration = 0.0;
	totalDistanceKM = 0.0;
	totalDistanceMile = 0.0;
	averagePaceKM = 0.0;
	averagePaceMile = 0.0;
	averageSpeedKM = 0.0;
	averageSpeedMile= 0.0;
	
	if (![tracks count]) {
		[delegate dataManagerUpdated:self];
		return;
	}
	
	CGFloat newDuration = 0.0;
	CGFloat newDistanceKM = 0.0;
	CGFloat newDistanceMile = 0.0;
	
	for (MNXTrack *track in tracks) {
		newDuration += track.duration;
		newDistanceKM += track.totalDistanceKM;
		newDistanceMile += track.totalDistanceMile;
	}
	
	if (newDuration > 0.0) {
		averageSpeedKM = newDistanceKM / newDuration * 60.0 * 60.0;
		averageSpeedMile = newDistanceMile / newDuration * 60.0 * 60.0;
	}
	if (newDistanceKM) {
		averagePaceKM = newDuration / newDistanceKM;
	}
	if (newDistanceMile) {
		averagePaceMile = newDuration / newDistanceMile;
	}	
	
	totalDistanceKM = newDistanceKM;
	totalDistanceMile = newDistanceMile;
	totalDuration = newDuration;
	
	[delegate dataManagerUpdated:self];
}
@end

@implementation MNXDataManager

- (void)dealloc
{
	[operationQueue release];
	[dataParser release];
	[tracks release];
	[super dealloc];
}

- (id)init
{
	self = [super init];
	if (self != nil) {
		tracks = [[NSMutableArray alloc] init];
		operationQueue = [[NSOperationQueue alloc] init];
		[operationQueue setName:@"Download Operation"];
		[operationQueue setMaxConcurrentOperationCount:1];
		dataParser = [[MNXDataParser alloc] init];
		dataParser.delegate = self;
		[self loadSavedData];
		
//		NSString *path = [[NSBundle mainBundle] pathForResource:@"data" ofType:@"dat"];
//		NSData *data = [NSData dataWithContentsOfFile:path];
//		[dataParser parseData:data logSize:354608];
	}
	return self;
}

- (void)downloadDataFromPort:(AMSerialPort *)inPort
{
	if ([[operationQueue operations] count]) {
		return;
	}	
	MNXDownloadOperation *o = [[[MNXDownloadOperation alloc] init] autorelease];
	o.action = MNXDownloadOperationActionDownload;
	o.port = inPort;
	o.delegate = self;
	[operationQueue addOperation:o];
}
- (void)cancelDownload
{
	if ([[operationQueue operations] count]) {
		NSOperation *o = [[operationQueue operations] lastObject];
		[o cancel];
	}
}
- (void)purgeDataWithPort:(AMSerialPort *)inPort
{
	if ([[operationQueue operations] count]) {
		return;
	}	
	MNXDownloadOperation *o = [[[MNXDownloadOperation alloc] init] autorelease];
	o.action = MNXDownloadOperationActionPurge;
	o.port = inPort;
	o.delegate = self;
	[operationQueue addOperation:o];	
}
- (NSString *)tempFilePathWithExtension:(NSString *)ext
{
	CFUUIDRef uuid = CFUUIDCreate(NULL);
	CFStringRef uuidString = CFUUIDCreateString(NULL, uuid);
	NSString *filename = [NSString stringWithString:(NSString *)uuidString];
	CFRelease(uuidString);
	if ([ext length]) {
		filename = [filename stringByAppendingPathExtension:ext];
	}
	NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:filename];
	return tempPath;
}
- (NSString *)savedDataPath
{
	NSArray *supportDirs = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
	if (![supportDirs count]) {
		return nil;
	}
	NSString *path = [[supportDirs objectAtIndex:0] stringByAppendingPathComponent:@"MNX"];
	BOOL isDir = NO;
	if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir]) {
		if (!isDir) {
			[[NSFileManager defaultManager] removeItemAtURL:[NSURL fileURLWithPath:path] error:nil];
		}
		NSError *e = nil;
		[[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&e];
	}
	path = [path stringByAppendingPathComponent:@"SavedActivities.plist"];
	return path;
}
- (void)_saveData
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	@synchronized(self) {
		NSMutableArray *array = [NSMutableArray array];
		for (MNXTrack *aTrack in [[tracks copy] autorelease]) {
			NSMutableArray *a = [NSMutableArray array];
			for (MNXPoint *aPoint in aTrack.points) {
				[a addObject:[aPoint dictionary]];
			}
			[array addObject:a];
		}
		[array writeToURL:[NSURL fileURLWithPath:[self savedDataPath]] atomically:YES];	
	}
	[pool drain];
}
- (void)saveData
{
	[self performSelectorInBackground:@selector(_saveData) withObject:nil];
}
- (void)loadSavedData
{
	NSArray *array = [NSArray arrayWithContentsOfURL:[NSURL fileURLWithPath:[self savedDataPath]]];
	NSMutableArray *newTracks = [NSMutableArray array];
	
	for (NSArray *a in array) {
		if (![a isKindOfClass:[NSArray class]]) {
			continue;
		}
		NSMutableArray *newPoints = [NSMutableArray array];
		for (NSDictionary *d in a) {
			MNXPoint *aPoint = [MNXPoint pointWithDictionary:d];
			[newPoints addObject:aPoint];
		}
		MNXTrack *aTrack = [[[MNXTrack alloc] init] autorelease];
		aTrack.points = newPoints;
		[newTracks addObject:aTrack];
	}
	[tracks setArray:newTracks];
	[self _updateInfo];
}
- (void)_undoAppendingTracks:(NSArray *)inTracks
{
	[undoManager beginUndoGrouping];
	[[undoManager prepareWithInvocationTarget:self] appendTracks:inTracks];
	[tracks removeObjectsInArray:inTracks];
	[self _updateInfo];
	[self performSelector:@selector(saveData) withObject:nil afterDelay:0.5];
	[undoManager endUndoGrouping];	
}
- (void)appendTracks:(NSArray *)inTracks
{
	[undoManager beginUndoGrouping];
	[[undoManager prepareWithInvocationTarget:self] _undoAppendingTracks:inTracks];
	[undoManager setActionName:NSLocalizedString(@"Adding Activites", @"")];
	[tracks addObjectsFromArray:inTracks];
	[self _updateInfo];
	[undoManager endUndoGrouping];
	[self performSelector:@selector(saveData) withObject:nil afterDelay:0.5];
}
- (void)_undoDeletingTrack:(MNXTrack *)inTrack atIndex:(NSInteger)inIndex
{
	[undoManager beginUndoGrouping];
	[[undoManager prepareWithInvocationTarget:self] deleteTrack:inTrack];
	[tracks insertObject:inTrack atIndex:inIndex];
	[self _updateInfo];
	[undoManager endUndoGrouping];	
	[self performSelector:@selector(saveData) withObject:nil afterDelay:0.5];
}
- (void)deleteTrack:(MNXTrack *)inTrack
{
	NSInteger index = [tracks indexOfObject:inTrack];
	if (index == NSNotFound) {
		return;
	}	
	[undoManager beginUndoGrouping];
	[[undoManager prepareWithInvocationTarget:self] _undoDeletingTrack:inTrack atIndex:index];
	[undoManager setActionName:NSLocalizedString(@"Deleting Activity", @"")];	
	[tracks removeObject:inTrack];
	[self _updateInfo];
	[undoManager endUndoGrouping];
	[self performSelector:@selector(saveData) withObject:nil afterDelay:0.5];	
}

- (NSData *)GPXData
{
	NSXMLElement *container = nil;
	NSXMLElement *root = (NSXMLElement *)[MNXTrack GPXRootNode:&container];
	NSXMLDocument *xml = [[[NSXMLDocument alloc] initWithRootElement:root] autorelease];
	[xml setVersion:@"1.0"];
	[xml setCharacterEncoding:@"UTF-8"];
	for (MNXTrack *aTrack in tracks) {
		[root addChild:[aTrack GPXNode]];
	}
	NSData *data = [xml XMLData];
	return data;	
}
- (NSData *)KMLData
{
	NSXMLElement *document = nil;
	NSXMLElement *root = (NSXMLElement *)[MNXTrack KMLRootNode:&document];
	NSXMLDocument *xml = [[[NSXMLDocument alloc] initWithRootElement:root] autorelease];
	[xml setVersion:@"1.0"];
	[xml setCharacterEncoding:@"UTF-8"];
	for (MNXTrack *aTrack in tracks) {
		[document addChild:[aTrack KMLNode]];
	}	
	NSData *data = [xml XMLData];
	return data;
}
- (NSData *)TCXData
{
	NSXMLElement *activities = nil;
	NSXMLElement *root = (NSXMLElement *)[MNXTrack TCXRootNode:&activities];
	
	NSXMLDocument *xml = [[[NSXMLDocument alloc] initWithRootElement:root] autorelease];
	[xml setVersion:@"1.0"];
	[xml setCharacterEncoding:@"UTF-8"];	
	
	for (MNXTrack *aTrack in tracks) {
		[activities addChild:[aTrack TCXNode]];
	}
	NSData *data = [xml XMLData];
	return data;
}

#pragma mark -

- (void)downloadOperationDidStartDownloadingData:(MNXDownloadOperation *)inOperation
{
	[(id)delegate performSelectorOnMainThread:@selector(dataManagerDidStartDownloadingData:) withObject:self waitUntilDone:NO];
}
- (void)_didDownloadData:(NSNumber *)inProgress
{
	[delegate dataManager:self didDownloadData:[inProgress floatValue]];
}
- (void)downloadOperation:(MNXDownloadOperation *)inOperation didDownloadData:(CGFloat)inProgress
{
	[self performSelectorOnMainThread:@selector(_didDownloadData:) withObject:[NSNumber numberWithFloat:inProgress] waitUntilDone:NO];
}
- (void)downloadOperation:(MNXDownloadOperation *)inOperation didFinishDownloadingData:(NSData *)inData logSize:(NSUInteger)logSize
{
	[(id)delegate performSelectorOnMainThread:@selector(dataManagerDidFinishDownloadingData:) withObject:self waitUntilDone:NO];
	[dataParser parseData:inData logSize:logSize];
}
- (void)downloadOperationDidStartPurgingData:(MNXDownloadOperation *)inOperation
{
	[(id)delegate performSelectorOnMainThread:@selector(dataManagerDidStartPurgineData:) withObject:self waitUntilDone:NO];
}
- (void)downloadOperationDidFinishPurgingData:(MNXDownloadOperation *)inOperation
{
	[(id)delegate performSelectorOnMainThread:@selector(dataManagerDidFinishPurgineData:) withObject:self waitUntilDone:NO];
}
- (void)downloadOperationCancelled:(MNXDownloadOperation *)inOperation
{
	[(id)delegate performSelectorOnMainThread:@selector(dataManagerCancelled:) withObject:self waitUntilDone:NO];
}
- (void)_didFailWithError:(NSError *)inError
{
	[delegate dataManager:self didFaileWithError:inError];
}
- (void)downloadOperation:(MNXDownloadOperation *)inOperation didFailWithError:(NSError *)inError;
{
	[self performSelectorOnMainThread:@selector(_didFailWithError:) withObject:inError waitUntilDone:NO];	
}

#pragma mark -

- (void)dataParserDidStartParsingData:(MNXDataParser *)inParser
{
	[(id)delegate performSelectorOnMainThread:@selector(dataManagerDidStartParsingData:) withObject:self waitUntilDone:NO];
}
- (void)_didFinishParsingData:(NSArray *)inTracks
{
	[delegate dataManager:self didFinishParsingData:inTracks];
}
- (void)dataParser:(MNXDataParser *)inParser didFinishParsingData:(NSArray *)inTracks
{
	[self performSelectorOnMainThread:@selector(_didFinishParsingData:) withObject:inTracks waitUntilDone:NO];
}
- (void)dataParserCancelled:(MNXDataParser *)inParser
{
}

#pragma mark -

- (NSArray *)tracks
{
	return tracks;
}

@synthesize delegate;
@synthesize totalDuration;
@synthesize totalDistanceKM;
@synthesize totalDistanceMile;
@synthesize averagePaceKM;
@synthesize averagePaceMile;
@synthesize averageSpeedKM;
@synthesize averageSpeedMile;
@synthesize undoManager;

@end
