#import "MNXDataManager.h"

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
		
		NSString *path = [[NSBundle mainBundle] pathForResource:@"data" ofType:@"dat"];
		NSData *data = [NSData dataWithContentsOfFile:path];
		[dataParser parseData:data logSize:354608];
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
	NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:(NSString *)uuidString];
	return tempPath;
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

- (void)dataParser:(MNXDataParser *)inParser didFinishParsingData:(NSArray *)inTracks
{
	[tracks setArray:inTracks];
	[self _updateInfo];
	[self performSelectorOnMainThread:@selector(_didFinishParsingData:) withObject:inTracks waitUntilDone:NO];
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
