#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "MNXDataManager.h"

@interface MNXAppDelegate : NSObject
	<NSApplicationDelegate,
	MNXDataManagerDelegate,
	NSTableViewDataSource,
	NSTableViewDelegate> 
{
	MNXDataManager *dataManager;
	MNXTrack *currentTrack;
    
	NSWindow *window;
	NSTableView *tracksTableView;
	NSTableView *pointsTableView;
	WebView *webView;
}

@property (retain, nonatomic) MNXTrack *currentTrack;

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSTableView *tracksTableView;
@property (assign) IBOutlet NSTableView *pointsTableView;
@property (assign) IBOutlet WebView *webView;

@end
