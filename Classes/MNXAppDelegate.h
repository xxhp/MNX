#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "MNXDataManager.h"
#import "AMSerialPort.h"
#import "AMSerialPortList.h"
#import "MNXSpeedView.h"

@interface MNXAppDelegate : NSObject
	<NSApplicationDelegate,
	MNXDataManagerDelegate> 
{
	MNXDataManager *dataManager;
	MNXTrack *currentTrack;
	
	NSDateFormatter *dateFormatter;
    
	NSWindow *window;
	NSTableView *tracksTableView;
	NSTableView *pointsTableView;
	NSTableView *paceTableView;
	MNXSpeedView *speedView;
	WebView *webView;
	NSTextField *trackInfoLabel;
	
	NSWindow *sheetWindow;
	NSTextField *messageLabel;
	NSProgressIndicator *progressIndicator;
	
	NSArrayController *portListArrayController;
	NSPopUpButton *portPopUpButton;
	
	NSMenuItem *deviceListMenuItem;
}

- (IBAction)download:(id)sender;
- (IBAction)cancelDownload:(id)sener;
- (IBAction)selectDevice:(id)sender;
- (IBAction)exportGPX:(id)sender;
- (IBAction)exportKML:(id)sender;
- (IBAction)exportTCX:(id)sender;
- (IBAction)googleEarth:(id)sender;
- (IBAction)showWindow:(id)sender;

@property (retain, nonatomic) MNXTrack *currentTrack;

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSTableView *tracksTableView;
@property (assign) IBOutlet NSTableView *pointsTableView;
@property (assign) IBOutlet NSTableView *paceTableView;
@property (assign) IBOutlet MNXSpeedView *speedView;
@property (assign) IBOutlet WebView *webView;
@property (assign) IBOutlet NSTextField *trackInfoLabel;

@property (assign) IBOutlet NSWindow *sheetWindow;
@property (assign) IBOutlet NSTextField *messageLabel;
@property (assign) IBOutlet NSProgressIndicator *progressIndicator;

@property (assign) IBOutlet NSArrayController *portListArrayController;
@property (assign) IBOutlet NSPopUpButton *portPopUpButton;
@property (assign) IBOutlet NSMenuItem *deviceListMenuItem;

@end

@interface MNXAppDelegate(TableView) <NSTableViewDataSource, NSTableViewDelegate>
@end

@interface MNXAppDelegate(Toolbar) <NSToolbarDelegate>
@end