

#import "NDBrowserViewController.h"

@implementation NDBrowserViewController


- (void)viewDidLoad {
	_webView.scalesPageToFit = YES;
	_addressBar.clearsOnBeginEditing = NO;
    [self.navigationController.navigationBar addSubview:_toolBarView];
    
    CGRect frame = _toolBarView.frame;
    frame.origin.y = (_toolBarView.frame.size.height - 44)/2;
    _toolBarView.frame = frame;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(donePressed:)];
    [self loadRequest:_urlAddress];

    [super viewDidLoad];
}

-(void)loadRequest:(NSString *)url_{
	
	NSURL *url;
	NSRange aRange = NSMakeRange(0,4);
	
	if([url_ isEqualToString:@""]){
		return;
	}
	
	if([url_ compare:@"http" options:NSCaseInsensitiveSearch range:aRange]){
		if([url_ compare:@"www" options:NSCaseInsensitiveSearch range:NSMakeRange(0,3)]){
		url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.%@",url_]];
			[_addressBar setText:[NSString stringWithFormat:@"http://www.%@",url_]]	;
		}
		else{
		url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@",url_]];
			
			[_addressBar setText:[NSString stringWithFormat:@"http://%@",url_]]	;
		}
	}
	else{
			url = [NSURL URLWithString:url_];
		    [_addressBar setText:url_];
		
	}
	NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
	_webView.delegate = self;
	[_webView loadRequest:requestObj];
    
}

#pragma mark 
#pragma mark IBAction Methods--
#pragma mark 

-(IBAction)gotoAddress:(id) sender {
	[self loadRequest:[_addressBar text]];
	[_addressBar resignFirstResponder];
}

-(IBAction) deleteAddressBarText:(id)sender{
	if(_addressBar.text != NULL){
		_addressBar.text = @"";
	}
}

-(IBAction)donePressed:(id) sender {
	
	[_webView stopLoading];
	_webView.delegate =nil;
	[self dismissViewControllerAnimated:YES completion:nil];
}


-(IBAction) goBack:(id)sender {
	[_webView goBack];
}

-(IBAction) goForward:(id)sender {
	[_webView goForward];
}


#pragma mark 
#pragma mark webView delegate Methods--
#pragma mark 

- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
	//CAPTURE USER LINK-CLICK.
	if (navigationType == UIWebViewNavigationTypeLinkClicked) {
		NSURL *URL = [request URL];	
		if ([[URL scheme] isEqualToString:@"http"]) {
			[_addressBar setText:[URL absoluteString]];
			[self gotoAddress:nil];
		}	 
		return NO;
	}	
	return YES;   
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
	[_activityIndicator startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
	[_activityIndicator stopAnimating];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{

}



@end
