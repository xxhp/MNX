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
- (void)saveData
{
	NSMutableArray *array = [NSMutableArray array];
	for (MNXTrack *aTrack in tracks) {
		NSMutableArray *a = [NSMutableArray array];
		for (MNXPoint *aPoint in aTrack.points) {
			[a addObject:[aPoint dictionary]];
		}
		[array addObject:a];
	}
	[array writeToURL:[NSURL fileURLWithPath:[self savedDataPath]] atomically:YES];
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
	[self performSelectorOnMainThread:@selector(_didFinishParsingData:) withObject:tracks waitUntilDone:NO];	
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
	[(id)delegate performSelectorOnMainThread:@selector(downloadManagerDidStartDownloadingData:) withObject:self waitUntilDone:NO];
}
- (void)_didDownloadData:(NSNumber *)inProgress
{
	[delegate downloadManager:self didDownloadData:[inProgress floatValue]];
}
- (void)downloadOperation:(MNXDownloadOperation *)inOperation didDownloadData:(CGFloat)inProgress
{
	[self performSelectorOnMainThread:@selector(_didDownloadData:) withObject:[NSNumber numberWithFloat:inProgress] waitUntilDone:NO];
}
- (void)downloadOperation:(MNXDownloadOperation *)inOperation didFinishDownloadingData:(NSData *)inData logSize:(NSUInteger)logSize
{
	[(id)delegate performSelectorOnMainThread:@selector(downloadManagerDidFinishDownloadingData:) withObject:self waitUntilDone:NO];
	[dataParser parseData:inData logSize:logSize];
}
- (void)downloadOperationCancelled:(MNXDownloadOperation *)inOperation
{
	[(id)delegate performSelectorOnMainThread:@selector(downloadManagerCancelled:) withObject:self waitUntilDone:NO];
}
- (void)_didFailWithError:(NSError *)inError
{
	[delegate downloadManager:self didFaileWithError:inError];
}
- (void)downloadOperation:(MNXDownloadOperation *)inOperation didFailWithError:(NSError *)inError;
{
	[self performSelectorOnMainThread:@selector(_didFailWithError:) withObject:inError waitUntilDone:NO];	
}

#pragma mark -

- (void)dataParserDidStartParsingData:(MNXDataParser *)inParser
{
	[(id)delegate performSelectorOnMainThread:@selector(downloadManagerDidStartParsingData:) withObject:self waitUntilDone:NO];
}
- (void)_didFinishParsingData:(NSArray *)inTracks
{
	[delegate downloadManager:self didFinishParsingData:inTracks];
}
- (void)dataParser:(MNXDataParser *)inParser didFinishParsingData:(NSArray *)inTracks
{
	[tracks setArray:inTracks];
	[self saveData];
	[self _updateInfo];
	[self performSelectorOnMainThread:@selector(_didFinishParsingData:) withObject:tracks waitUntilDone:NO];
}
- (void)dataParserCancelled:(MNXDataParser *)inParser
{
}

#pragma mark -

- (NSArray *)tracks
{
	return [NSArray arrayWithArray:tracks];
}

@synthesize delegate;
@synthesize totalDuration;
@synthesize totalDistanceKM;
@synthesize totalDistanceMile;
@synthesize averagePaceKM;
@synthesize averagePaceMile;
@synthesize averageSpeedKM;
@synthesize averageSpeedMile;

@end
