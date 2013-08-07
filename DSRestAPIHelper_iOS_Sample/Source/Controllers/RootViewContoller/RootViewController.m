//
//  RootViewController.m
//  DSRestAPIHelper_iOS_Sample
//
//  Created by nik on 05/08/13.
//  Copyright (c) 2013 CloudSpokes. All rights reserved.
//

#import "RootViewController.h"
#import "APIConfig.h"
#import "DSAPIHelper.h"
#import "DetailViewController.h"
#import "NDBrowserViewController.h"

@interface RootViewController (){
    DSAPIHelper* sharedHelper;
}

- (IBAction)requestSignatureViaTemplateBtnPressed:(UIButton *)sender;
- (IBAction)getEnvelopeInfoBtnPressed:(UIButton *)sender;
- (IBAction)getEnvelopeRecipientStatusBtnPressed:(UIButton *)sender;
- (IBAction)requestSignatureOnADocumentBtnPressed:(UIButton *)sender;
- (IBAction)getStatusOfEnvelopesBtnPressed:(UIButton *)sender;
- (IBAction)getDocListAndDownloadDocumentsBtnPressed:(UIButton *)sender;
- (IBAction)embededSendingBtnPressed:(UIButton *)sender;
- (IBAction)embededSigningBtnPressed:(UIButton *)sender;
- (IBAction)embededDocuSignConsoleBtnPressed:(UIButton *)sender;

@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end

@implementation RootViewController

- (void)viewDidLoad
{
    [self initialiseDSAPISharedHelper];
    [super viewDidLoad];
}

- (void)launchBrowserViewwithAddress:(NSString*)address {
    NDBrowserViewController* nDBrowserViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ndbrowser"];
    nDBrowserViewController.urlAddress =address;
    UINavigationController* navController = [[UINavigationController alloc] initWithRootViewController:nDBrowserViewController];
    [self presentViewController:navController animated:YES completion:nil];
}

#pragma mark - IBActions
//Sends an email to recipient for signing the doc represented by templateId.
- (IBAction)requestSignatureViaTemplateBtnPressed:(UIButton *)sender{
   // [self displayActivityIndicator];
    [sharedHelper requestSignatureFromTemplateWithID:kTemplateId forRecipient:self.dummyRecipient withEmailSubject:@"requestSignatureViaTemplate" emailBlurb:@"requestSignatureViaTemplate from iOS" completionBlock:self.requestSignatureViaTemplateCompletionBlock];

}

//Fetches the info related to envelope.
- (IBAction)getEnvelopeInfoBtnPressed:(UIButton *)sender{
    [self displayActivityIndicator];
    [sharedHelper envelopeInfoForEnvelopeId:self.envelopeId completionBlock:self.getEnvelopeInfoCompletionBlock];

}

- (IBAction)getEnvelopeRecipientStatusBtnPressed:(UIButton *)sender{
    [self displayActivityIndicator];
    [sharedHelper recipientInfoForEnvelopeId:self.envelopeId completionBlock:self.getEnvelopeRecipientStatusCompletionBlock];
}


- (IBAction)requestSignatureOnADocumentBtnPressed:(UIButton *)sender{
    [self displayActivityIndicator];
    [sharedHelper requestSignatureOnDocument:@"TestDocument.docx" toRecipient:self.dummyRecipient withEmailSubject:@"Signature Request on Document API call" emailBlurb:@"email body" completionBlock:self.requestSignatureOnADocumentCompletionBlock];

}

- (IBAction)getStatusOfEnvelopesBtnPressed:(UIButton *)sender{
    [self displayActivityIndicator];
    [sharedHelper statusOfEnvelopesWithcompletionBlock:self.getStatusOfEnvelopesCompletionBlock];

}

- (IBAction)getDocListAndDownloadDocumentsBtnPressed:(UIButton *)sender{
    [self displayActivityIndicator];
    [sharedHelper documentInfoAndDownloadDocumentsForEnvelopeId:self.envelopeId completionBlock:self.getDocListAndDownloadDocumentsCompletionBlock];

}

- (IBAction)embededSendingBtnPressed:(UIButton *)sender{
    [self displayActivityIndicator];
    [sharedHelper embededSendingTagAndSendWorkFlowForTemplateWithID:kTemplateId forRecipient:self.dummyRecipient withEmailSubject:@"embededSendingForTemplateWithID" emailBlurb:@"embededSendingForTemplateWithID From iOS" completionBlock:self.embededSendingCompletionBlock];

}

- (IBAction)embededSigningBtnPressed:(UIButton *)sender{
    [self displayActivityIndicator];
    [sharedHelper embededSigningForTemplateWithID:kTemplateId forRecipient:self.dummyRecipient withEmailSubject:@"embededSigningForTemplateWithID" emailBlurb:@"embededSigningForTemplateWithID From iOS" completionBlock:self.embededSigningCompletionBlock];

}

- (IBAction)embededDocuSignConsoleBtnPressed:(UIButton *)sender{
    [self displayActivityIndicator];
    [sharedHelper embeddedDocuSignConsoleWithCompletionBlock:self.embededDocuSignConsoleCompletionBlock];

}

#pragma mark - Completion Handler Blocks
- (DSAPICompletionBlock)requestSignatureViaTemplateCompletionBlock {
    DSAPICompletionBlock block = ^(NSDictionary* response,NSError* error) {
        [self hideActivityIndicator];
        if(!error){
            NSString* message = [NSString stringWithFormat:@"Response received for requestSignatureViaTemplate is \n\n%@ ",[response description]];
            [self presentDetailViewControllerWithText:message];
            NSLog(@"%@",message);
        }else {
            dispatch_sync(dispatch_get_main_queue(), ^(){            [self showMessage:[NSString stringWithFormat:@"requestSignatureViaTemplate failed \nDetails:-\n %@ ",error.userInfo.description] withDelegate:nil andButtonTitles:@[@"OK"]];
});
        }
        
    };
    return block;
}


- (DSAPICompletionBlock)getEnvelopeInfoCompletionBlock {
    DSAPICompletionBlock block = ^(NSDictionary* response,NSError* error) {
        [self hideActivityIndicator];
        if(!error){
            NSString* message = [NSString stringWithFormat:@"Response received for getEnvelopeInfo is \n\n%@ ",[response description]];
            [self presentDetailViewControllerWithText:message];
            NSLog(@"%@",message);
            
        }else {
            dispatch_sync(dispatch_get_main_queue(), ^(){ [self showMessage:[NSString stringWithFormat:@"getEnvelopeInfo failed \nDetails:-\n %@ ",error.userInfo.description] withDelegate:nil andButtonTitles:@[@"OK"]];
            });
        }
        
    };
    return block;

}

- (DSAPICompletionBlock)getEnvelopeRecipientStatusCompletionBlock {
    DSAPICompletionBlock block = ^(NSDictionary* response,NSError* error) {
        [self hideActivityIndicator];
        if(!error){
            NSString* message = [NSString stringWithFormat:@"Response received for getEnvelopeRecipientStatus is \n\n%@ ",[response description]];
            [self presentDetailViewControllerWithText:message];
            NSLog(@"%@",message);

        }else {
            dispatch_sync(dispatch_get_main_queue(), ^(){ [self showMessage:[NSString stringWithFormat:@"getEnvelopeRecipientStatus failed \nDetails:-\n %@ ",error.userInfo.description] withDelegate:nil andButtonTitles:@[@"OK"]];
            });

        }
        
    };
    return block;

}

- (DSAPICompletionBlock)requestSignatureOnADocumentCompletionBlock {
    DSAPICompletionBlock block = ^(NSDictionary* response,NSError* error) {
        [self hideActivityIndicator];
        if(!error){
            NSString* message = [NSString stringWithFormat:@"Response received for requestSignatureOnADocument is \n\n%@ ",[response description]];
            [self presentDetailViewControllerWithText:message];
            NSLog(@"%@",message);
            
        }else {
            dispatch_sync(dispatch_get_main_queue(), ^(){ [self showMessage:[NSString stringWithFormat:@"requestSignatureOnADocument failed \nDetails:-\n %@ ",error.userInfo.description] withDelegate:nil andButtonTitles:@[@"OK"]];
            });

        }
        
    };
    return block;

}

- (DSAPICompletionBlock)getStatusOfEnvelopesCompletionBlock {
    DSAPICompletionBlock block = ^(NSDictionary* response,NSError* error) {
        [self hideActivityIndicator];
        if(!error){
            NSString* message = [NSString stringWithFormat:@"Response received for getStatusOfEnvelopes is \n\n%@ ",[response description]];
            [self presentDetailViewControllerWithText:message];
            NSLog(@"%@",message);
            
        }else {
            dispatch_sync(dispatch_get_main_queue(), ^(){ [self showMessage:[NSString stringWithFormat:@"getStatusOfEnvelopes failed \nDetails:-\n %@ ",error.userInfo.description] withDelegate:nil andButtonTitles:@[@"OK"]];
            });

        }
        
    };
    return block;

}
- (DSAPICompletionBlock)getDocListAndDownloadDocumentsCompletionBlock {
    DSAPICompletionBlock block = ^(NSDictionary* response,NSError* error) {
        [self hideActivityIndicator];
        if(!error){
            NSString* message = [NSString stringWithFormat:@"Response received for getDocListAndDownloadDocuments is \n\n%@ ",[response description]];
            [self presentDetailViewControllerWithText:message];
            NSLog(@"%@",message);
            
        }else {
            dispatch_sync(dispatch_get_main_queue(), ^(){ [self showMessage:[NSString stringWithFormat:@"getDocListAndDownloadDocuments failed \nDetails:-\n %@ ",error.userInfo.description] withDelegate:nil andButtonTitles:@[@"OK"]];
            });

        }
        
    };
    return block;

}

- (DSAPICompletionBlock)embededSendingCompletionBlock {
    DSAPICompletionBlock block = ^(NSDictionary* response,NSError* error) {
        [self hideActivityIndicator];
        if(!error){
            NSString* message = [NSString stringWithFormat:@"Response received for embededSending is \n\n%@ ",[response description]];
            //[self presentDetailViewControllerWithText:message];
            NSLog(@"%@",message);
            
        }else {
            dispatch_sync(dispatch_get_main_queue(), ^(){ [self showMessage:[NSString stringWithFormat:@"embededSending failed \nDetails:-\n %@ ",error.userInfo.description] withDelegate:nil andButtonTitles:@[@"OK"]];
            });

        }
        
    };
    return block;

}

- (DSAPICompletionBlock)embededSigningCompletionBlock {
    DSAPICompletionBlock block = ^(NSDictionary* response,NSError* error) {
        [self hideActivityIndicator];
        if(!error){
            NSString* message = [NSString stringWithFormat:@"Response received for embededSigning is \n\n%@ ",[response description]];
            //[self presentDetailViewControllerWithText:message];
            NSLog(@"%@",message);
            
        }else {
            dispatch_sync(dispatch_get_main_queue(), ^(){ [self showMessage:[NSString stringWithFormat:@"embededSigning failed \nDetails:-\n %@ ",error.userInfo.description] withDelegate:nil andButtonTitles:@[@"OK"]];
            });

        }
        
    };
    return block;

}

- (DSAPICompletionBlock)embededDocuSignConsoleCompletionBlock {
    DSAPICompletionBlock block = ^(NSDictionary* response,NSError* error) {
        [self hideActivityIndicator];
        if(!error){
            NSString* message = [NSString stringWithFormat:@"Response received for requestSignatureViaTemplate is \n\n%@ ",[response description]];
            NSLog(@"%@",message);
            NSString* url =  response[@"url"];
            if(url.length) {
                [self launchBrowserViewwithAddress:url];
            }
            
        }else {
            dispatch_sync(dispatch_get_main_queue(), ^(){ [self showMessage:[NSString stringWithFormat:@"embededDocuSign failed \nDetails:-\n %@ ",error.userInfo.description] withDelegate:nil andButtonTitles:@[@"OK"]];
            });
        }
        
    };
    return block;

}



#pragma mark - Custom methods
- (void)showMessage:(NSString*)message withDelegate:(id)delegate andButtonTitles:(NSArray*)buttonTitles{
    UIAlertView* anAlert = [[UIAlertView alloc] initWithTitle:kAppName message:message delegate:delegate cancelButtonTitle:buttonTitles[0] otherButtonTitles:nil];
    [anAlert show];
}

- (void)displayActivityIndicator {
    [self.activityIndicator startAnimating];
    self.view.alpha = 0.7f;
    self.view.userInteractionEnabled = NO;
}

- (void)hideActivityIndicator {
    [self.activityIndicator stopAnimating];
    self.view.alpha = 1.0f;
    self.view.userInteractionEnabled = YES;
}

- (void)presentDetailViewControllerWithText:(NSString*)text {
    DetailViewController* detailViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"detailView"];
    detailViewController.text = text;
    UINavigationController* navController = [[UINavigationController alloc] initWithRootViewController:detailViewController];
    [self presentViewController:navController animated:YES completion:nil];
    
}

- (void)initialiseDSAPISharedHelper {
    sharedHelper = [DSAPIHelper sharedHelper];
    sharedHelper.userId = kUserId;
    sharedHelper.integratorKey = kIntegratorKey;
    sharedHelper.password = kPassword;
//    dispatch_async(dispatch_get_main_queue(), ^(){[sharedHelper fetchBaseURLAndAccountId];});
}

- (DSAPIRecipient*)dummyRecipient{
    DSAPIRecipient* recipient = Init(DSAPIRecipient);
    recipient.fullName = @"John Smith";
    recipient.email = @"testtryfoo@gmail.com";
    recipient.roleName = @"Signer";
    return recipient;
}


- (NSString*)envelopeId {
    return @"c94e6410-0bd0-4652-bef8-8e500e347e9b"; //This is a valid envelopeId for my account. Ideally you should choose one from the response of statusOfEnvelopesWithcompletionBlock.
    
}


@end
