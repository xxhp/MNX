#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "MNXDataManager.h"
#import "AMSerialPort.h"
#import "AMSerialPortList.h"

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
	
	NSWindow *sheetWindow;
	NSTextField *messageLabel;
	NSProgressIndicator *progressIndicator;
	
	NSArrayController *portListArrayController;
	NSPopUpButton *portPopUpButton;
}

- (IBAction)download:(id)sender;

@property (retain, nonatomic) MNXTrack *currentTrack;

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSTableView *tracksTableView;
@property (assign) IBOutlet NSTableView *pointsTableView;
@property (assign) IBOutlet WebView *webView;

@property (assign) IBOutlet NSWindow *sheetWindow;
@property (assign) IBOutlet NSTextField *messageLabel;
@property (assign) IBOutlet NSProgressIndicator *progressIndicator;

@property (assign) IBOutlet NSArrayController *portListArrayController;
@property (assign) IBOutlet NSPopUpButton *portPopUpButton;


@end
