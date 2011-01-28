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
- (void)_didFailedWithMessage:(NSString *)message
{
	[delegate downloadManager:self didFailedWithMessage:message];
}
- (void)downloadOperation:(MNXDownloadOperation *)inOperation didFailedWithMessage:(NSString *)message
{
	[self performSelectorOnMainThread:@selector(_didFailedWithMessage:) withObject:message waitUntilDone:NO];
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

@end
