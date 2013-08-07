
@interface NDBrowserViewController : UIViewController<UIWebViewDelegate>

@property(nonatomic,retain) IBOutlet UIView* toolBarView;
@property(nonatomic,retain) IBOutlet UIWebView *webView;
@property(nonatomic,retain) IBOutlet UITextField *addressBar;
@property(nonatomic,retain) IBOutlet UINavigationBar* navBar;
@property(nonatomic,retain) IBOutlet UIActivityIndicatorView *activityIndicator;
@property(nonatomic,retain) NSString * urlAddress;

-(IBAction) gotoAddress:(id)sender;
-(IBAction) deleteAddressBarText:(id)sender;
-(IBAction) goBack:(id)sender;
-(IBAction) goForward:(id)sender;
-(void)loadRequest:(NSString *)url;

@end
